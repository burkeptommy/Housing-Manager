-- Phase X+3 final audit: per-(state, town, category) coverage matrix
-- + per-state totals + spot-check random rows.
--
-- USAGE
--   supabase db query --linked --file scripts/audit-vendor-coverage.sql
--
-- WHAT TO LOOK FOR
--   - Every town × every service trade should have ≥ 5 catalog rows.
--   - "FROM YOUR AREA" in find-a-pro caps display at 10, so 10+ per
--     cell is the target sweet spot.
--   - Source mix: admin (national/regional brands like Eversource),
--     google_places (real local businesses), vendor_application
--     (chez_certified after manual review), user_pending (one-shot
--     household adds — should not yet appear in cross-household
--     queries via the `utility_providers_visible` view).

-- 1. TOTALS by source
\echo '=== CATALOG TOTALS BY SOURCE ==='
SELECT source, count(*) AS rows
FROM utility_providers
GROUP BY source
ORDER BY rows DESC;

-- 2. Per-state coverage (target categories only)
\echo ''
\echo '=== PER-STATE COVERAGE BY CATEGORY ==='
WITH target_categories(cat) AS (
  VALUES
    ('hvac'),('plumbing'),('electrical'),('roofing'),('chimney_sweep'),
    ('tree_service'),('garage_door'),('septic_pumper'),('well_water_service'),
    ('landscaping'),('pest_control'),('pool_service'),('solar'),('security'),
    ('irrigation'),('waterproofing'),
    ('electric'),('natural_gas'),('oil'),('propane'),('water'),('trash'),
    ('internet_cable'),('home_insurance'),('auto_insurance')
),
states(code) AS (
  VALUES ('CT'),('NY'),('MA'),('RI'),('MI')
)
SELECT
  s.code AS state,
  tc.cat AS category,
  (SELECT count(*) FROM utility_providers up
    WHERE up.provider_type = tc.cat AND s.code = ANY(up.regions)) AS rows
FROM states s CROSS JOIN target_categories tc
ORDER BY s.code, tc.cat;

-- 3. Low-coverage cells: (town, category) with < 5 rows
\echo ''
\echo '=== LOW-COVERAGE CELLS (< 5 rows for a target town) ==='
WITH target_categories(cat) AS (
  VALUES
    ('hvac'),('plumbing'),('electrical'),('roofing'),('chimney_sweep'),
    ('tree_service'),('garage_door'),('septic_pumper'),('well_water_service'),
    ('landscaping'),('pest_control'),('pool_service'),('solar'),('security'),
    ('irrigation'),('waterproofing')
),
fairfield_towns(town) AS (
  VALUES ('Bethel'),('Bridgeport'),('Brookfield'),('Danbury'),('Darien'),('Easton'),
    ('Fairfield'),('Greenwich'),('Monroe'),('New Canaan'),('New Fairfield'),
    ('Newtown'),('Norwalk'),('Redding'),('Ridgefield'),('Shelton'),('Sherman'),
    ('Stamford'),('Stratford'),('Trumbull'),('Weston'),('Westport'),('Wilton')
)
SELECT
  ft.town,
  tc.cat AS category,
  (SELECT count(*) FROM utility_providers up
    WHERE up.provider_type = tc.cat AND ft.town = ANY(up.regions)) AS rows
FROM fairfield_towns ft CROSS JOIN target_categories tc
HAVING (SELECT count(*) FROM utility_providers up
  WHERE up.provider_type = tc.cat AND ft.town = ANY(up.regions)) < 5
ORDER BY rows ASC, ft.town, tc.cat;

-- 4. Spot-check: 20 random google_places rows. Open the websites
--    manually to verify they're real, active businesses.
\echo ''
\echo '=== SPOT-CHECK 20 RANDOM GOOGLE_PLACES ROWS ==='
SELECT name, provider_type, website, phone
FROM utility_providers
WHERE source = 'google_places'
ORDER BY random()
LIMIT 20;
