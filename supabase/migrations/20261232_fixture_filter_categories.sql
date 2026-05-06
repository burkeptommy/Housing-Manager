-- Phase 7 of the equipment catalog expansion (plan: i-tried-to-add-reactive-boole.md).
--
-- Applies Tom's "stays with the house when sold" filter to the catalog.
-- A category belongs in the catalog only if the typical product in that
-- category is a fixture — physically integrated with the house's plumbing,
-- wiring, ducting, structure, or pool/yard infrastructure. Personal property
-- (lawn mowers, portable generators, snow blowers) is out of scope because
-- the homeowner takes it with them on sale.
--
-- Three changes:
--   1. New fixture_status column on equipment_categories
--   2. Mark 12 existing categories as 'portable' (excluded from priority queue)
--   3. Add 25 new fixture categories that were missing
--   4. Update catalog_expansion_priority view to filter out portable categories
--   5. Add the manufacturer brands needed for the new fixture categories

BEGIN;

-- ============================================================================
-- 1. fixture_status column
-- ============================================================================

ALTER TABLE equipment_categories
  ADD COLUMN IF NOT EXISTS fixture_status TEXT
  CHECK (fixture_status IN ('fixture', 'portable', 'mixed'))
  DEFAULT 'fixture';

CREATE INDEX IF NOT EXISTS idx_equipment_categories_fixture_status
  ON equipment_categories(fixture_status);

COMMENT ON COLUMN equipment_categories.fixture_status IS
  'Whether the typical product in this category stays with the house on sale. fixture=stays (HVAC, water heaters, built-in appliances). portable=takes (lawn mowers, snow blowers, portable generators). mixed=depends on installation (wine cooler under-counter vs free-standing). Catalog generation queue excludes portable categories.';

-- ============================================================================
-- 2. Mark portable categories
-- ============================================================================

UPDATE equipment_categories
SET fixture_status = 'portable'
WHERE slug IN (
  'generator-portable',
  'generator-inverter',
  'power-station',
  'lawn-mower',
  'mower-riding',
  'mower-zero-turn',
  'mower-robotic',
  'snow-blower',
  'string-trimmer',
  'leaf-blower',
  'chainsaw',
  'microwave-countertop'
);

-- A few categories are inherently mixed (built-in stays, free-standing takes).
-- Mark them so the catalog generation prompt can bias toward built-in models.
UPDATE equipment_categories
SET fixture_status = 'mixed'
WHERE slug IN (
  -- Wine + beverage: built-in/under-counter stays, free-standing takes
  'wine-cooler',
  'beverage-center',
  -- Pizza ovens: built-in into outdoor kitchen stays, Ooni takes
  'pizza-oven',
  -- Patio heater: hardwired or gas-line stays, propane portable takes
  'patio-heater',
  -- Hot tub: built-in spa stays, portable plug-and-play takes
  'hot-tub',
  -- Sauna: built-in walk-in stays, barrel sauna usually takes
  'sauna',
  -- Vacuum sealer: drawer model stays, countertop free-standing takes
  'vacuum-sealer',
  -- Ice maker: built-in stays, countertop takes
  'ice-maker',
  -- Trash compactor: built-in stays
  'trash-compactor',
  -- Coffee system: built-in plumbed stays, free-standing takes
  'coffee-system',
  -- Garment care (LG Styler etc): hardwired install stays, free-standing takes
  'garment-care'
);

-- ============================================================================
-- 3. Clear queued (brand, category) pairs for portable categories
-- ============================================================================
-- Existing equipment_catalog rows stay (real data, harmless). But we don't
-- want the cron to add MORE to portable categories. Removing the
-- equipment_brand_categories rows kills the queue entry.

DELETE FROM equipment_brand_categories
WHERE category_id IN (
  SELECT id FROM equipment_categories WHERE fixture_status = 'portable'
);

-- ============================================================================
-- 4. Add 25 new fixture categories
-- ============================================================================

INSERT INTO equipment_categories (name, slug, room, typical_lifespan_years, description, fixture_status) VALUES
  -- Ventilation (every $450K+ home, not yet in catalog)
  ('Bathroom Exhaust Fan', 'bathroom-exhaust-fan', 'bath', 15, 'Hardwired ducted bath exhaust fans (Panasonic WhisperFit, Broan, Delta Breez)', 'fixture'),
  ('Whole-Home Attic Fan', 'attic-fan-whole-home', 'hvac', 18, 'Whole-house ventilation fans (QuietCool, AirScape, CentricAir)', 'fixture'),
  ('Heat Recovery Ventilator (HRV)', 'hrv', 'hvac', 20, 'Air exchanger that recovers heat from outgoing stale air; cold-climate code in many states', 'fixture'),
  ('Energy Recovery Ventilator (ERV)', 'erv', 'hvac', 20, 'Air exchanger that recovers heat AND moisture; humid-climate code', 'fixture'),
  ('Make-Up Air Unit', 'make-up-air-unit', 'kitchen', 20, 'Replacement-air system paired with high-CFM range hoods (code-required >400 CFM)', 'fixture'),

  -- Whole-home water management
  ('Whole-Home Water Leak Detector', 'water-leak-detector-whole-home', 'plumbing', 12, 'Plumbed inline at main shutoff (Flo by Moen, Phyn, StreamLabs, LeakSmart)', 'fixture'),
  ('Smart Water Shutoff Valve', 'water-shutoff-valve-smart', 'plumbing', 12, 'Replaces the main shutoff with a smart auto-closing valve', 'fixture'),

  -- Radiant heating (increasingly common in $450K+ remodels and new builds)
  ('Hydronic Radiant Floor Heating', 'radiant-floor-heating-hydronic', 'hvac', 50, 'Tubing in slab/under floor; lifespan = the building (Uponor, Warmboard, Roth)', 'fixture'),
  ('Electric Heated Bathroom Floor', 'heated-bathroom-floor-electric', 'bath', 25, 'Element under tile (WarmlyYours, SunTouch, Schluter Ditra-Heat)', 'fixture'),
  ('Towel Warmer', 'towel-warmer', 'bath', 20, 'Hardwired or plumbed towel rail (Mr. Steam, Vogue UK, Tuzio, WarmlyYours)', 'fixture'),

  -- HVAC variants
  ('Geothermal Heat Pump', 'hvac-heat-pump-geothermal', 'hvac', 25, 'Ground-source heat pump with buried loop (WaterFurnace, ClimateMaster, Bosch GHP)', 'fixture'),
  ('High-Velocity HVAC System', 'hvac-high-velocity', 'hvac', 25, 'Small-duct high-velocity systems for retrofits (Spacepak, Unico)', 'fixture'),

  -- Bath fixtures (built-in)
  ('Pot Filler', 'pot-filler', 'kitchen', 20, 'Wall-mounted plumbed kitchen faucet behind range', 'fixture'),
  ('Whirlpool / Jetted Tub', 'tub-whirlpool', 'bath', 20, 'Plumbed and wired jetted bathtub (separate from regular bathtub)', 'fixture'),
  ('Walk-In Tub', 'tub-walk-in', 'bath', 20, 'Accessibility tub with door, plumbed and wired (Kohler, Safe Step)', 'fixture'),
  ('Steam Shower Enclosure', 'steam-shower-enclosure', 'bath', 25, 'Glass enclosure + integrated steam generator system', 'fixture'),

  -- Pool fixtures
  ('Pool Light', 'pool-light', 'outdoor', 8, 'Wall-niche or surface-mount pool lighting (Hayward, Pentair, J&J Electronics)', 'fixture'),
  ('Automatic Pool Cover', 'pool-cover-automatic', 'outdoor', 8, 'Track-mounted motorized safety cover (Coverstar, Cover-Pools, Aquamatic)', 'fixture'),

  -- Septic add-ons
  ('Septic Effluent Filter', 'septic-effluent-filter', 'wastewater', 8, 'Inline filter at tank outlet (Polylok, SimTech, Tuf-Tite)', 'fixture'),
  ('Septic Distribution Box', 'septic-distribution-box', 'wastewater', 30, 'Concrete or polymer D-box, buried', 'fixture'),

  -- Detection (smart combos)
  ('Smart Smoke / CO Combo Alarm', 'smoke-co-combo', 'safety', 10, 'Combination hardwired smoke + CO alarm (Nest Protect, First Alert Onelink)', 'fixture'),

  -- Specialty + emerging
  ('Smart Electrical Panel', 'electrical-smart-panel', 'electrical', 30, 'Replaces main panel with circuit-level monitoring (Span, Lumin, Schneider Square D Pulse)', 'fixture'),
  ('Mosquito Misting System', 'mosquito-misting-system', 'outdoor', 12, 'Built-in mosquito repellent system in eaves/landscaping (Mistaway, MosquitoNix)', 'fixture'),
  ('Built-In Pest Control System', 'pest-control-built-in', 'safety', 25, 'In-wall tubing + termite bait stations (Sentricon, Term-Pest)', 'fixture'),
  ('Outdoor TV', 'outdoor-tv', 'outdoor', 8, 'Weather-rated outdoor TVs designed for permanent install (Samsung Terrace, SunBriteTV, Furrion)', 'fixture')
ON CONFLICT (slug) DO UPDATE SET fixture_status = EXCLUDED.fixture_status;

-- ============================================================================
-- 5. Add brands needed for the new fixture categories
-- ============================================================================

INSERT INTO equipment_manufacturers (name, slug, parent_company, country_of_origin, tier) VALUES
  -- Ventilation
  ('Lifebreath', 'lifebreath', 'Airia Brands', 'Canada', 'premium'),
  ('Venmar', 'venmar', 'Broan-NuTone', 'Canada', 'premium'),
  ('Renewaire', 'renewaire', 'Soler & Palau', 'United States', 'premium'),
  ('Panasonic Ventilation', 'panasonic-ventilation', 'Panasonic Corporation', 'Japan', 'premium'),
  ('Delta Breez', 'delta-breez', 'Delta Electronics', 'Taiwan', 'premium'),
  ('QuietCool', 'quietcool', 'QuietCool', 'United States', 'premium'),
  ('AirScape', 'airscape', 'AirScape Fans', 'United States', 'premium'),
  ('Centric Air', 'centric-air', 'CentricAir', 'United States', 'mainstream'),

  -- Water leak detection
  ('Flo by Moen', 'flo-by-moen', 'Moen / Fortune Brands', 'United States', 'premium'),
  ('Phyn', 'phyn', 'Belkin', 'United States', 'premium'),
  ('StreamLabs', 'streamlabs', 'Reliance Worldwide', 'United States', 'premium'),
  ('LeakSmart', 'leaksmart', 'LeakSmart', 'United States', 'premium'),
  ('Notion', 'notion-water', 'Comcast', 'United States', 'mainstream'),
  ('Moen Smart Water', 'moen-smart-water', 'Fortune Brands', 'United States', 'premium'),
  ('Aquanta', 'aquanta', 'Aquanta', 'United States', 'mainstream'),

  -- Hydronic radiant heating
  ('Uponor', 'uponor', 'Uponor Corporation', 'Finland', 'premium'),
  ('Warmboard', 'warmboard', 'Warmboard Inc.', 'United States', 'luxury'),
  ('Roth Industries', 'roth-industries', 'Roth Industries', 'Germany', 'premium'),
  ('REHAU', 'rehau', 'REHAU Group', 'Germany', 'premium'),
  ('Watts Radiant', 'watts-radiant', 'Watts Water Technologies', 'United States', 'premium'),
  ('Viega', 'viega', 'Viega Group', 'Germany', 'premium'),

  -- Electric heated floor
  ('WarmlyYours', 'warmlyyours', 'WarmlyYours', 'United States', 'premium'),
  ('SunTouch', 'suntouch', 'Watts Water Technologies', 'United States', 'premium'),
  ('Schluter Systems', 'schluter-systems', 'Schluter-Systems', 'Germany', 'premium'),
  ('Nuheat', 'nuheat', 'Pentair', 'Canada', 'premium'),

  -- Towel warmers
  ('Mister Towel', 'mister-towel', 'Mister Towel', 'United States', 'mainstream'),
  ('Vogue UK', 'vogue-uk', 'Vogue (UK)', 'United Kingdom', 'luxury'),
  ('Tuzio', 'tuzio', 'Tuzio', 'United Kingdom', 'luxury'),
  ('Amba', 'amba', 'Amba Products', 'United States', 'premium'),

  -- Geothermal heat pumps
  ('WaterFurnace', 'waterfurnace', 'WaterFurnace International', 'United States', 'premium'),
  ('ClimateMaster', 'climatemaster', 'LSB Industries', 'United States', 'premium'),
  ('Bosch GHP', 'bosch-ghp', 'BSH (Robert Bosch)', 'Germany', 'premium'),
  ('Enertech', 'enertech', 'Enertech Global', 'United States', 'premium'),
  ('Hydron Module', 'hydron-module', 'Enertech Global', 'United States', 'premium'),

  -- High-velocity HVAC (Spacepak/Unico already exist) — alt brands
  ('Hi-Velocity Systems', 'hi-velocity-systems', 'Hi-Velocity Systems', 'Canada', 'premium'),

  -- Whirlpool / walk-in tubs
  ('MAAX', 'maax', 'MAAX Bath', 'Canada', 'premium'),
  ('Safe Step Walk-In Tub', 'safe-step', 'Safe Step', 'United States', 'mainstream'),
  ('Bain Ultra', 'bain-ultra', 'Bain Ultra', 'Canada', 'luxury'),
  ('Aquatic', 'aquatic', 'Aquatic Industries', 'United States', 'premium'),

  -- Steam shower enclosures
  ('DreamLine', 'dreamline', 'DreamLine USA', 'United States', 'premium'),
  ('Coastal Industries', 'coastal-industries', 'Coastal Industries', 'United States', 'premium'),
  ('Steam Spa', 'steam-spa', 'Steam Spa', 'United States', 'mainstream'),

  -- Pool fixtures
  ('J&J Electronics', 'j-and-j-electronics', 'J&J Electronics', 'United States', 'premium'),
  ('Coverstar', 'coverstar', 'Latham Pool Products', 'United States', 'premium'),
  ('Cover-Pools', 'cover-pools', 'Cover-Pools', 'United States', 'premium'),
  ('Aquamatic Cover Systems', 'aquamatic', 'Aquamatic Cover Systems', 'United States', 'premium'),
  ('Auto Pool Reel', 'auto-pool-reel', 'Auto Pool Reel', 'United States', 'mainstream'),

  -- Septic add-ons
  ('Polylok', 'polylok', 'Polylok Inc.', 'United States', 'mainstream'),
  ('SimTech Filter', 'simtech-filter', 'SimTech Industries', 'United States', 'mainstream'),
  ('Tuf-Tite', 'tuf-tite', 'Tuf-Tite Inc.', 'United States', 'mainstream'),
  ('Zabel', 'zabel-filter', 'Polylok', 'United States', 'mainstream'),

  -- Smart electrical panels
  ('Span', 'span-panel', 'Span.IO', 'United States', 'luxury'),
  ('Lumin', 'lumin', 'Lumin', 'United States', 'premium'),
  ('Sense', 'sense-energy', 'Sense Labs', 'United States', 'premium'),
  ('Curb', 'curb-energy', 'Curb', 'United States', 'mainstream'),

  -- Mosquito misting
  ('Mistaway', 'mistaway', 'MistAway Systems', 'United States', 'premium'),
  ('MosquitoNix', 'mosquitonix', 'MosquitoNix', 'United States', 'premium'),

  -- Built-in pest control
  ('Sentricon', 'sentricon', 'Corteva Agriscience', 'United States', 'premium'),
  ('Term-Pest', 'term-pest', 'Term-Pest Tube Systems', 'United States', 'mainstream'),

  -- Outdoor TVs
  ('Samsung Terrace', 'samsung-terrace', 'Samsung', 'South Korea', 'premium'),
  ('SunBriteTV', 'sunbrite-tv', 'SunBriteTV', 'United States', 'premium'),
  ('Furrion', 'furrion', 'Furrion', 'United States', 'mainstream'),
  ('Peerless-AV', 'peerless-av', 'Peerless Industries', 'United States', 'premium'),
  ('Seura', 'seura', 'Seura', 'United States', 'luxury')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 6. Update catalog_expansion_priority view to filter out portable categories
-- ============================================================================

DROP VIEW IF EXISTS catalog_expansion_priority;

CREATE VIEW catalog_expansion_priority AS
WITH usage_counts AS (
  SELECT catalog_entry_id, COUNT(*)::INT AS home_count
  FROM home_systems
  WHERE catalog_entry_id IS NOT NULL
  GROUP BY catalog_entry_id
),
brand_usage AS (
  SELECT ec.manufacturer_id,
         COALESCE(SUM(uc.home_count), 0)::INT AS total_homes
  FROM equipment_catalog ec
  LEFT JOIN usage_counts uc ON uc.catalog_entry_id = ec.id
  GROUP BY ec.manufacturer_id
),
brand_category_usage AS (
  SELECT ec.manufacturer_id, ec.category_id,
         COALESCE(SUM(uc.home_count), 0)::INT AS pair_homes
  FROM equipment_catalog ec
  LEFT JOIN usage_counts uc ON uc.catalog_entry_id = ec.id
  GROUP BY ec.manufacturer_id, ec.category_id
),
customer_request_pairs AS (
  SELECT DISTINCT m.id AS manufacturer_id, c.id AS category_id
  FROM equipment_catalog_requests r
  LEFT JOIN equipment_manufacturers m
    ON LOWER(m.name) = LOWER(r.submitted_brand)
    OR LOWER(m.slug) = LOWER(REPLACE(REPLACE(r.submitted_brand, ' ', '-'), '.', ''))
  LEFT JOIN equipment_categories c
    ON LOWER(c.slug) = LOWER(REPLACE(r.submitted_product_type, ' ', '-'))
    OR LOWER(c.name) = LOWER(r.submitted_product_type)
  WHERE r.status IN ('pending', 'researching')
    AND m.id IS NOT NULL AND c.id IS NOT NULL
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
  c.fixture_status,
  ebc.confidence,
  (SELECT COUNT(*) FROM equipment_catalog ec
    WHERE ec.manufacturer_id = ebc.manufacturer_id
      AND ec.category_id = ebc.category_id)::INT AS current_count,
  COALESCE(bcu.pair_homes, 0)::INT AS pair_homes,
  COALESCE(bu.total_homes, 0)::INT AS brand_homes,
  CASE
    WHEN crp.manufacturer_id IS NOT NULL THEN 0
    WHEN COALESCE(bcu.pair_homes, 0) > 0
      AND (SELECT COUNT(*) FROM equipment_catalog ec
           WHERE ec.manufacturer_id = ebc.manufacturer_id
             AND ec.category_id = ebc.category_id) < 30 THEN 1
    WHEN COALESCE(bu.total_homes, 0) > 0
      AND (SELECT COUNT(*) FROM equipment_catalog ec
           WHERE ec.manufacturer_id = ebc.manufacturer_id
             AND ec.category_id = ebc.category_id) < 30 THEN 2
    WHEN m.tier IN ('premium', 'luxury', 'ultra-luxury')
      AND EXISTS (SELECT 1 FROM catalog_priority_essential_categories pec WHERE pec.slug = c.slug)
      AND (SELECT COUNT(*) FROM equipment_catalog ec
           WHERE ec.manufacturer_id = ebc.manufacturer_id
             AND ec.category_id = ebc.category_id) < 5 THEN 3
    WHEN m.tier = 'mainstream'
      AND EXISTS (SELECT 1 FROM catalog_priority_essential_categories pec WHERE pec.slug = c.slug)
      AND (SELECT COUNT(*) FROM equipment_catalog ec
           WHERE ec.manufacturer_id = ebc.manufacturer_id
             AND ec.category_id = ebc.category_id) < 5 THEN 4
    WHEN m.tier IN ('premium', 'luxury', 'ultra-luxury')
      AND (SELECT COUNT(*) FROM equipment_catalog ec
           WHERE ec.manufacturer_id = ebc.manufacturer_id
             AND ec.category_id = ebc.category_id) < 20 THEN 5
    WHEN m.tier = 'mainstream'
      AND (SELECT COUNT(*) FROM equipment_catalog ec
           WHERE ec.manufacturer_id = ebc.manufacturer_id
             AND ec.category_id = ebc.category_id) < 20 THEN 6
    ELSE 7
  END AS priority_bucket,
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
  AND NOT EXISTS (
    SELECT 1 FROM equipment_categories child
    WHERE child.parent_category_id = c.id
  )
  -- Phase 7 — exclude portable categories from the priority queue.
  -- Mixed (built-in vs free-standing) stays in the queue; the catalog
  -- prompt biases toward built-in models for mixed categories.
  AND c.fixture_status IN ('fixture', 'mixed')
  AND (SELECT COUNT(*) FROM equipment_catalog ec
        WHERE ec.manufacturer_id = ebc.manufacturer_id
          AND ec.category_id = ebc.category_id) < 30;

COMMENT ON VIEW catalog_expansion_priority IS
  'Phase 7 — paced nightly catalog expansion priority queue. Excludes portable categories per Tom''s "stays with the house" filter. Cron pulls top N rows ordered by priority_bucket ASC, pair_homes DESC, brand_homes DESC, confidence DESC.';

COMMIT;
