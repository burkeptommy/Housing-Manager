-- Phase 6 of the equipment catalog expansion (plan: i-tried-to-add-reactive-boole.md).
--
-- Replaces the one-shot tiered weekend blitz with a paced, priority-driven
-- nightly cron. Caps each night at ~4,000 rows (~100 pairs × 40 models).
-- Stops automatically when zero gaps remain.
--
-- Priority ordering (Tom's 9-tier rubric, collapsed to 8 buckets):
--   0  Customer-requested pair (equipment_catalog_requests w/ pending status)
--   1  Pair touched by an existing home_system (real usage data)
--   2  Brand has any home_system × any category (brand-level usage signal)
--   3  Premium/luxury brand × ESSENTIAL category, bare gap (<5 rows)
--   4  Mainstream brand × ESSENTIAL category, bare gap
--   5  Premium/luxury brand × any category, partial (5-19 rows)
--   6  Mainstream brand × any category, partial
--   7  Budget brand × any category OR low-confidence pairs, completionist
--
-- Within each bucket, sort by usage count DESC, confidence DESC, current_count ASC.
-- Excludes pairs that already have ≥30 catalog rows (saturation threshold).

BEGIN;

-- ============================================================================
-- Mark "essential" categories — the ones every $450K+ home likely has.
-- Used by priority buckets 3-4 (essential gaps jump the queue).
-- ============================================================================

CREATE TABLE IF NOT EXISTS catalog_priority_essential_categories (
    slug TEXT PRIMARY KEY REFERENCES equipment_categories(slug) DEFERRABLE INITIALLY DEFERRED
);

-- Wait — equipment_categories.slug is unique but probably not the FK reference target.
-- Use a softer reference to avoid migration breakage if a category slug changes.
DROP TABLE catalog_priority_essential_categories;

CREATE TABLE IF NOT EXISTS catalog_priority_essential_categories (
    slug TEXT PRIMARY KEY,
    note TEXT
);

INSERT INTO catalog_priority_essential_categories (slug, note) VALUES
  -- HVAC core
  ('hvac', 'whole HVAC umbrella'),
  ('hvac-furnace', 'every gas/oil home'),
  ('hvac-boiler', 'NE radiator/baseboard homes'),
  ('hvac-central-ac', 'most $450K+ homes'),
  ('hvac-heat-pump', 'growing fast in NE / west'),
  ('hvac-mini-split', 'addition / converted spaces'),
  ('hvac-air-handler', 'split-system pairings'),
  ('hvac-thermostat', 'every home'),
  -- Water heaters (every home)
  ('water-heater', 'every home'),
  ('water-heater-tank-gas', 'most homes'),
  ('water-heater-tank-electric', 'all-electric homes'),
  ('water-heater-tankless-gas', 'modern installs'),
  ('water-heater-tankless-electric', 'point-of-use + small homes'),
  ('water-heater-heat-pump', 'rebate-driven retrofits'),
  -- Kitchen essentials
  ('refrigerator', 'every home'),
  ('refrigerator-french-door', 'most popular fridge type'),
  ('refrigerator-side-by-side', 'common'),
  ('refrigerator-bottom-freezer', 'common'),
  ('refrigerator-top-freezer', 'budget homes'),
  ('range', 'every kitchen'),
  ('range-gas', 'gas-cooking homes'),
  ('range-electric', 'electric homes'),
  ('range-induction', 'modern remodels'),
  ('range-dual-fuel', 'high-end remodels'),
  ('cooktop', 'wall-oven kitchens'),
  ('wall-oven-single', 'wall-oven kitchens'),
  ('wall-oven-double', 'family kitchens'),
  ('dishwasher', 'every kitchen'),
  ('microwave', 'every kitchen'),
  ('microwave-otr', 'OTR installs'),
  ('range-hood', 'every kitchen'),
  ('garbage-disposal', 'most homes'),
  -- Laundry
  ('washer', 'every home'),
  ('washer-front-load', 'modern installs'),
  ('washer-top-load-impeller', 'mid-range homes'),
  ('washer-top-load-agitator', 'budget homes'),
  ('dryer', 'every home'),
  ('dryer-electric', 'most homes'),
  ('dryer-gas', 'gas-line homes'),
  ('dryer-heat-pump', 'modern eco homes'),
  -- Outdoor utility (common in $450K+ homes)
  ('generator', 'standby + portable'),
  ('generator-standby-gas', 'NE blackout-prone'),
  ('generator-portable', 'every home eventually'),
  ('sump-pump', 'basement homes'),
  ('sump-pump-submersible', 'most installs'),
  ('well-pump', 'rural / suburban'),
  -- Pool (when present)
  ('pool-pump', 'every pool'),
  ('pool-filter', 'every pool'),
  ('pool-heater', 'NE/MW pools'),
  -- Bath / kitchen plumbing
  ('toilet', 'every bath'),
  ('bathroom-faucet', 'every bath'),
  ('shower-system', 'remodel-heavy'),
  ('water-treatment-softener', 'hard-water regions'),
  ('water-treatment-whole-house', 'modern remodels'),
  -- Modern home essentials
  ('smoke-detector', 'every home'),
  ('co-detector', 'every home'),
  ('electrical-panel', 'every home'),
  ('garage-door', 'every garage'),
  ('garage-door-opener', 'every garage'),
  ('hvac-thermostat', 'every home')
ON CONFLICT (slug) DO NOTHING;


-- ============================================================================
-- catalog_expansion_priority view — the heart of the priority system.
--
-- Computes priority_bucket (0-7, lower = higher priority) per (brand, category)
-- pair using the rubric above. Materialized at query time so it picks up new
-- usage signals from home_systems and equipment_catalog_requests in real time.
-- ============================================================================

CREATE OR REPLACE VIEW catalog_expansion_priority AS
WITH usage_counts AS (
  -- How many home_systems rows reference each catalog_entry_id?
  SELECT
    catalog_entry_id,
    COUNT(*)::INT AS home_count
  FROM home_systems
  WHERE catalog_entry_id IS NOT NULL
  GROUP BY catalog_entry_id
),
brand_usage AS (
  -- Total homeowners with ANY system from each manufacturer.
  -- Bucket 1-2 priority signal.
  SELECT
    ec.manufacturer_id,
    COALESCE(SUM(uc.home_count), 0)::INT AS total_homes
  FROM equipment_catalog ec
  LEFT JOIN usage_counts uc ON uc.catalog_entry_id = ec.id
  GROUP BY ec.manufacturer_id
),
brand_category_usage AS (
  -- Total homeowners with a system from each (brand, category) pair.
  -- Bucket 1 priority signal.
  SELECT
    ec.manufacturer_id,
    ec.category_id,
    COALESCE(SUM(uc.home_count), 0)::INT AS pair_homes
  FROM equipment_catalog ec
  LEFT JOIN usage_counts uc ON uc.catalog_entry_id = ec.id
  GROUP BY ec.manufacturer_id, ec.category_id
),
customer_request_pairs AS (
  -- Pairs explicitly requested by a homeowner via send-catalog-request.
  -- Bucket 0 priority — highest possible.
  SELECT DISTINCT
    m.id AS manufacturer_id,
    c.id AS category_id
  FROM equipment_catalog_requests r
  LEFT JOIN equipment_manufacturers m
    ON LOWER(m.name) = LOWER(r.submitted_brand)
    OR LOWER(m.slug) = LOWER(REPLACE(REPLACE(r.submitted_brand, ' ', '-'), '.', ''))
  LEFT JOIN equipment_categories c
    ON LOWER(c.slug) = LOWER(REPLACE(r.submitted_product_type, ' ', '-'))
    OR LOWER(c.name) = LOWER(r.submitted_product_type)
  WHERE r.status IN ('pending', 'researching')
    AND m.id IS NOT NULL
    AND c.id IS NOT NULL
)
SELECT
  ebc.manufacturer_id,
  ebc.category_id,
  m.slug AS manufacturer_slug,
  m.name AS manufacturer_name,
  m.tier AS brand_tier,
  m.parent_brand_family,
  c.slug AS category_slug,
  c.name AS category_name,
  c.parent_category_id,
  ebc.confidence,
  -- How many catalog rows already exist for this pair
  (SELECT COUNT(*) FROM equipment_catalog ec
    WHERE ec.manufacturer_id = ebc.manufacturer_id
      AND ec.category_id = ebc.category_id)::INT AS current_count,
  COALESCE(bcu.pair_homes, 0)::INT AS pair_homes,
  COALESCE(bu.total_homes, 0)::INT AS brand_homes,
  -- Tom's 9-tier rubric collapsed to 8 buckets (0=highest, 7=lowest)
  CASE
    -- 0: Customer-requested pair (real homeowner asked for this brand/category)
    WHEN crp.manufacturer_id IS NOT NULL THEN 0
    -- 1: Pair has actual usage AND is under-served
    WHEN COALESCE(bcu.pair_homes, 0) > 0
      AND (SELECT COUNT(*) FROM equipment_catalog ec
           WHERE ec.manufacturer_id = ebc.manufacturer_id
             AND ec.category_id = ebc.category_id) < 30 THEN 1
    -- 2: Brand has any usage, this category not yet covered
    WHEN COALESCE(bu.total_homes, 0) > 0
      AND (SELECT COUNT(*) FROM equipment_catalog ec
           WHERE ec.manufacturer_id = ebc.manufacturer_id
             AND ec.category_id = ebc.category_id) < 30 THEN 2
    -- 3: Premium/luxury × essential category, bare gap (<5 rows)
    WHEN m.tier IN ('premium', 'luxury', 'ultra-luxury')
      AND EXISTS (SELECT 1 FROM catalog_priority_essential_categories pec WHERE pec.slug = c.slug)
      AND (SELECT COUNT(*) FROM equipment_catalog ec
           WHERE ec.manufacturer_id = ebc.manufacturer_id
             AND ec.category_id = ebc.category_id) < 5 THEN 3
    -- 4: Mainstream × essential category, bare gap
    WHEN m.tier = 'mainstream'
      AND EXISTS (SELECT 1 FROM catalog_priority_essential_categories pec WHERE pec.slug = c.slug)
      AND (SELECT COUNT(*) FROM equipment_catalog ec
           WHERE ec.manufacturer_id = ebc.manufacturer_id
             AND ec.category_id = ebc.category_id) < 5 THEN 4
    -- 5: Premium/luxury × any category, partial (5-19 rows)
    WHEN m.tier IN ('premium', 'luxury', 'ultra-luxury')
      AND (SELECT COUNT(*) FROM equipment_catalog ec
           WHERE ec.manufacturer_id = ebc.manufacturer_id
             AND ec.category_id = ebc.category_id) < 20 THEN 5
    -- 6: Mainstream × any category, partial
    WHEN m.tier = 'mainstream'
      AND (SELECT COUNT(*) FROM equipment_catalog ec
           WHERE ec.manufacturer_id = ebc.manufacturer_id
             AND ec.category_id = ebc.category_id) < 20 THEN 6
    -- 7: Everything else (budget tier, low confidence, niche categories)
    ELSE 7
  END AS priority_bucket,
  -- Tracking: when was this pair last expanded?
  (SELECT MAX(created_at) FROM equipment_catalog ec
    WHERE ec.manufacturer_id = ebc.manufacturer_id
      AND ec.category_id = ebc.category_id
      AND ec.verification_status = 'claude_generated') AS last_expanded_at
FROM equipment_brand_categories ebc
JOIN equipment_manufacturers m ON m.id = ebc.manufacturer_id
JOIN equipment_categories c ON c.id = ebc.category_id
LEFT JOIN brand_usage bu ON bu.manufacturer_id = ebc.manufacturer_id
LEFT JOIN brand_category_usage bcu
  ON bcu.manufacturer_id = ebc.manufacturer_id
  AND bcu.category_id = ebc.category_id
LEFT JOIN customer_request_pairs crp
  ON crp.manufacturer_id = ebc.manufacturer_id
  AND crp.category_id = ebc.category_id
WHERE ebc.confidence >= 70
  -- Only LEAF categories (no children) — avoids parent+child duplicate generation
  AND NOT EXISTS (
    SELECT 1 FROM equipment_categories child
    WHERE child.parent_category_id = c.id
  )
  -- Skip already-saturated pairs
  AND (SELECT COUNT(*) FROM equipment_catalog ec
        WHERE ec.manufacturer_id = ebc.manufacturer_id
          AND ec.category_id = ebc.category_id) < 30;

COMMENT ON VIEW catalog_expansion_priority IS
  'Phase 6 — paced nightly catalog expansion priority queue. Cron pulls top N rows ordered by priority_bucket ASC, pair_homes DESC, brand_homes DESC, confidence DESC, current_count ASC. Stops feeding when zero rows remain (catalog complete).';


-- ============================================================================
-- claim_next_priority_pairs(N) — atomic claim function.
--
-- Used by the cron edge function to fetch the next N pairs to expand AND
-- atomically reserve them so concurrent invocations (or retries) don't
-- double-process. Uses an advisory-lock-style INSERT into a claims table
-- with an expiring lease.
-- ============================================================================

CREATE TABLE IF NOT EXISTS catalog_expansion_claims (
    manufacturer_id UUID NOT NULL,
    category_id UUID NOT NULL,
    claimed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    -- Claims auto-expire after 10 min so failed runs don't block forever
    expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + INTERVAL '10 minutes'),
    completed_at TIMESTAMPTZ,
    PRIMARY KEY (manufacturer_id, category_id)
);

CREATE INDEX IF NOT EXISTS idx_catalog_expansion_claims_expires
  ON catalog_expansion_claims(expires_at)
  WHERE completed_at IS NULL;

CREATE OR REPLACE FUNCTION claim_next_priority_pairs(p_limit INT)
RETURNS TABLE(
  manufacturer_id UUID,
  category_id UUID,
  manufacturer_slug TEXT,
  category_slug TEXT,
  priority_bucket INT,
  current_count INT
) AS $$
BEGIN
  -- Sweep expired or stale claims so they can be re-tried
  DELETE FROM catalog_expansion_claims
  WHERE expires_at < now() AND completed_at IS NULL;

  -- Pull the next N pairs ordered by priority, atomic-claim them
  RETURN QUERY
  WITH next_pairs AS (
    SELECT cep.manufacturer_id, cep.category_id, cep.manufacturer_slug,
           cep.category_slug, cep.priority_bucket, cep.current_count
    FROM catalog_expansion_priority cep
    WHERE NOT EXISTS (
      SELECT 1 FROM catalog_expansion_claims cec
      WHERE cec.manufacturer_id = cep.manufacturer_id
        AND cec.category_id = cep.category_id
        AND cec.completed_at IS NULL
    )
    ORDER BY
      cep.priority_bucket ASC,
      cep.pair_homes DESC,
      cep.brand_homes DESC,
      cep.confidence DESC,
      cep.current_count ASC,
      cep.manufacturer_slug, cep.category_slug
    LIMIT p_limit
  ),
  claimed AS (
    INSERT INTO catalog_expansion_claims (manufacturer_id, category_id)
    SELECT np.manufacturer_id, np.category_id FROM next_pairs np
    ON CONFLICT (manufacturer_id, category_id) DO UPDATE
      SET claimed_at = EXCLUDED.claimed_at,
          expires_at = now() + INTERVAL '10 minutes',
          completed_at = NULL
    RETURNING manufacturer_id, category_id
  )
  SELECT np.manufacturer_id, np.category_id, np.manufacturer_slug,
         np.category_slug, np.priority_bucket, np.current_count
  FROM next_pairs np
  WHERE EXISTS (
    SELECT 1 FROM claimed c
    WHERE c.manufacturer_id = np.manufacturer_id
      AND c.category_id = np.category_id
  );
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION mark_priority_pair_complete(
  p_manufacturer_id UUID,
  p_category_id UUID
) RETURNS VOID AS $$
BEGIN
  UPDATE catalog_expansion_claims
  SET completed_at = now()
  WHERE manufacturer_id = p_manufacturer_id
    AND category_id = p_category_id
    AND completed_at IS NULL;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION claim_next_priority_pairs IS
  'Atomic — fetches next N priority pairs and reserves them with a 10-min expiring lease. Concurrent cron invocations get disjoint sets. Failed runs auto-expire so the pair becomes claimable again.';

COMMIT;
