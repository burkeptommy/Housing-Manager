-- Phase X+5 follow-up: rescue rows the over-aggressive cross-state guard
-- silently dropped during the May 2026 enriched reseed.
--
-- The find-local-vendors edge function had a guardrail that prevented
-- region merge when an existing row's "home state" differed from the
-- current search's state. The intent was to stop CT-only LLCs from
-- getting MI tagged onto their regions via name-relevance bleed from
-- Google Places.
--
-- The bug: legitimately multi-state operators (e.g. Connecticut
-- Basement Systems, which serves CT + Westchester NY) got their FIRST
-- region locked in (whichever state's search hit them first), and
-- subsequent searches in adjacent states couldn't add to regions. The
-- alternative branch (INSERT a new row) then failed silently because
-- google_place_id has a UNIQUE constraint — so the row was dropped.
--
-- Visible symptom: CT waterproofing returned 0 rows for every Fairfield
-- town despite the local_vendor_results cache holding 15 high-quality
-- CT waterproofing vendors per town.
--
-- This migration:
--   1. Backfills regions from cache for every catalog row whose
--      google_place_id exists in local_vendor_results — unions every
--      (town, state) the cache has seen into the catalog row's regions.
--   2. INSERTs rows for cache entries that exist in local_vendor_results
--      but NOT in utility_providers (the silently-dropped cohort).
--   3. Edge function bug fixed in lockstep: the cross-state guard now
--      only applies to domain-only matches (different google_place_id,
--      same brand). Exact place-id matches ALWAYS merge regions.

BEGIN;

-- 1. REGION BACKFILL — union every cache appearance into existing rows
WITH cache_regions AS (
  SELECT
    lvr.google_place_id,
    array_agg(DISTINCT lvr.town ORDER BY lvr.town) ||
      array_agg(DISTINCT lvr.state ORDER BY lvr.state) AS new_regions
  FROM local_vendor_results lvr
  WHERE lvr.google_place_id IS NOT NULL
  GROUP BY lvr.google_place_id
)
UPDATE utility_providers up
SET regions = (
  SELECT array_agg(DISTINCT r ORDER BY r)
  FROM (
    SELECT unnest(coalesce(up.regions, ARRAY[]::text[])) AS r
    UNION
    SELECT unnest(cr.new_regions)
  ) sub
)
FROM cache_regions cr
WHERE up.google_place_id = cr.google_place_id
  AND up.source = 'google_places';

-- 2. INSERT MISSING ROWS — every cache entry with no catalog row yet
WITH category_map(cache_cat, provider_type) AS (
  VALUES
    ('hvac','hvac'),('plumbing','plumbing'),('electrical','electrical'),
    ('roofing','roofing'),('chimney_sweep','chimney_sweep'),
    ('tree_service','tree_service'),('garage_door','garage_door'),
    ('septic_pumper','septic_pumper'),('well_water_service','well_water_service'),
    ('landscaping','landscaping'),('pest_control','pest_control'),
    ('pool_service','pool_service'),('solar','solar'),('security','security'),
    ('irrigation','irrigation'),('waterproofing','waterproofing'),
    ('electric','electric'),('natural_gas','natural_gas'),('oil','oil'),
    ('propane','propane'),('water','water'),('trash','trash'),
    ('internet_cable','internet_cable'),
    ('home_insurance','home_insurance'),('auto_insurance','auto_insurance')
),
best_cache AS (
  SELECT DISTINCT ON (lvr.google_place_id)
    lvr.google_place_id, lvr.vendor_name AS name,
    lvr.phone, lvr.website, lvr.address, lvr.rating, lvr.review_count,
    cm.provider_type,
    lvr.fetched_at
  FROM local_vendor_results lvr
  JOIN category_map cm ON cm.cache_cat = lvr.category
  WHERE lvr.google_place_id IS NOT NULL AND lvr.vendor_name IS NOT NULL
  ORDER BY lvr.google_place_id, lvr.fetched_at DESC
),
place_regions AS (
  SELECT
    google_place_id,
    array_agg(DISTINCT town ORDER BY town) ||
      array_agg(DISTINCT state ORDER BY state) AS regions
  FROM local_vendor_results
  WHERE google_place_id IS NOT NULL
  GROUP BY google_place_id
)
INSERT INTO utility_providers (
  name, slug, provider_type, website, phone, address, rating, review_count,
  regions, source, google_place_id, contribution_count
)
SELECT
  bc.name,
  'gp-' || lower(bc.google_place_id),
  bc.provider_type,
  bc.website, bc.phone, bc.address, bc.rating, bc.review_count,
  pr.regions,
  'google_places', bc.google_place_id, 1
FROM best_cache bc
JOIN place_regions pr ON pr.google_place_id = bc.google_place_id
WHERE NOT EXISTS (
  SELECT 1 FROM utility_providers up WHERE up.google_place_id = bc.google_place_id
)
ON CONFLICT (google_place_id) DO NOTHING;

DO $$
DECLARE
  total int;
  ct_wp int;
BEGIN
  SELECT count(*) INTO total FROM utility_providers;
  SELECT count(*) INTO ct_wp FROM utility_providers
    WHERE provider_type = 'waterproofing' AND 'CT' = ANY(regions);
  RAISE NOTICE 'After rescue: total=%, CT waterproofing rows=%', total, ct_wp;
END $$;

COMMIT;
