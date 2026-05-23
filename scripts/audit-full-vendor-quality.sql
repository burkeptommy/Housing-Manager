-- Phase X+3 FINAL audit: full DB quality sweep post-seed.
-- All 13 checks run as discrete queries — call this file then read the result
-- arrays in order: each top-level WITH/SELECT is one check.
--
-- USAGE
--   supabase db query --linked --file scripts/audit-full-vendor-quality.sql > /tmp/audit.json
--   cat /tmp/audit.json | jq '.rows'

WITH
-- 1. CATALOG TOTALS BY SOURCE
totals_by_source AS (
  SELECT json_agg(t) AS data FROM (
    SELECT source, count(*) AS rows
    FROM utility_providers
    GROUP BY source
    ORDER BY count(*) DESC
  ) t
),

-- 2. PER-STATE COVERAGE
target_categories(cat) AS (
  VALUES
    ('hvac'),('plumbing'),('electrical'),('roofing'),('chimney_sweep'),
    ('tree_service'),('garage_door'),('septic_pumper'),('well_water_service'),
    ('landscaping'),('pest_control'),('pool_service'),('solar'),('security'),
    ('irrigation'),('waterproofing'),
    ('electric'),('natural_gas'),('oil'),('propane'),('water'),('trash'),
    ('internet_cable'),('home_insurance'),('auto_insurance')
),
target_states(code) AS (
  VALUES ('CT'),('NY'),('MA'),('RI'),('MI')
),
per_state_coverage AS (
  SELECT json_agg(t) AS data FROM (
    SELECT
      s.code AS state,
      tc.cat AS category,
      (SELECT count(*) FROM utility_providers up
        WHERE up.provider_type = tc.cat AND s.code = ANY(up.regions)) AS rows
    FROM target_states s CROSS JOIN target_categories tc
    ORDER BY s.code, tc.cat
  ) t
),

-- 3. LOW-COVERAGE FAIRFIELD CT CELLS (< 5 rows for trade categories)
fairfield_towns(town) AS (
  VALUES ('Bethel'),('Bridgeport'),('Brookfield'),('Danbury'),('Darien'),('Easton'),
    ('Fairfield'),('Greenwich'),('Monroe'),('New Canaan'),('New Fairfield'),
    ('Newtown'),('Norwalk'),('Redding'),('Ridgefield'),('Shelton'),('Sherman'),
    ('Stamford'),('Stratford'),('Trumbull'),('Weston'),('Westport'),('Wilton')
),
trade_categories(cat) AS (
  VALUES
    ('hvac'),('plumbing'),('electrical'),('roofing'),('chimney_sweep'),
    ('tree_service'),('garage_door'),('septic_pumper'),('well_water_service'),
    ('landscaping'),('pest_control'),('pool_service'),('solar'),('security'),
    ('irrigation'),('waterproofing')
),
low_coverage_cells AS (
  SELECT json_agg(t) AS data FROM (
    SELECT town, category, rows FROM (
      SELECT
        ft.town,
        tc.cat AS category,
        (SELECT count(*) FROM utility_providers up
          WHERE up.provider_type = tc.cat AND ft.town = ANY(up.regions)) AS rows
      FROM fairfield_towns ft CROSS JOIN trade_categories tc
    ) cells
    WHERE rows < 5
    ORDER BY rows ASC, town, category
  ) t
),

-- 4. BRAND SHARDS — root domain appearing multiple times in same category
root_domains AS (
  SELECT
    id, name, provider_type, source, regions,
    CASE
      WHEN website IS NULL OR website = '' THEN NULL
      ELSE regexp_replace(
        regexp_replace(lower(website), '^https?://', ''),
        '^www\.', ''
      )
    END AS website_norm
  FROM utility_providers
  WHERE website IS NOT NULL AND website <> ''
),
root_only AS (
  SELECT
    id, name, provider_type, source, regions,
    array_to_string(
      (string_to_array(split_part(website_norm, '/', 1), '.'))[
        greatest(1, array_length(string_to_array(split_part(website_norm, '/', 1), '.'), 1) - 1):
      ],
      '.'
    ) AS root_domain
  FROM root_domains
),
brand_shards AS (
  SELECT json_agg(t) AS data FROM (
    SELECT
      root_domain, provider_type,
      count(*) AS shard_count,
      array_agg(name ORDER BY name)::text[] AS shard_names,
      array_agg(distinct source) AS sources
    FROM root_only
    WHERE root_domain <> ''
    GROUP BY root_domain, provider_type
    HAVING count(*) > 1
    ORDER BY count(*) DESC, root_domain
    LIMIT 50
  ) t
),

-- 5. EXACT-NAME DUPLICATES within same provider_type
exact_name_dupes AS (
  SELECT json_agg(t) AS data FROM (
    SELECT
      lower(trim(name)) AS name_norm,
      provider_type,
      count(*) AS dupe_count,
      array_agg(name ORDER BY name)::text[] AS variants,
      array_agg(distinct source) AS sources
    FROM utility_providers
    GROUP BY lower(trim(name)), provider_type
    HAVING count(*) > 1
    ORDER BY count(*) DESC, name_norm
    LIMIT 50
  ) t
),

-- 6. PHONE DUPLICATES within same provider_type
phone_norm AS (
  SELECT
    id, name, provider_type, source,
    regexp_replace(coalesce(phone, ''), '\D', '', 'g') AS digits
  FROM utility_providers
),
phone_dupes AS (
  SELECT json_agg(t) AS data FROM (
    SELECT
      digits AS phone_digits,
      provider_type,
      count(*) AS dupe_count,
      array_agg(name ORDER BY name)::text[] AS names
    FROM phone_norm
    WHERE length(digits) >= 10
    GROUP BY digits, provider_type
    HAVING count(*) > 1
    ORDER BY count(*) DESC
    LIMIT 30
  ) t
),

-- 7. SLUG UNIQUENESS (must be 0)
slug_dupes AS (
  SELECT json_agg(t) AS data FROM (
    SELECT slug, count(*) AS dupe_count
    FROM utility_providers
    WHERE slug IS NOT NULL
    GROUP BY slug
    HAVING count(*) > 1
  ) t
),

-- 8. QUALITY DREGS — no phone AND no website
quality_dregs AS (
  SELECT json_agg(t) AS data FROM (
    SELECT source, provider_type, count(*) AS rows
    FROM utility_providers
    WHERE (phone IS NULL OR phone = '')
      AND (website IS NULL OR website = '')
    GROUP BY source, provider_type
    ORDER BY count(*) DESC
    LIMIT 30
  ) t
),

-- 9. REGION INTEGRITY — empty/null regions
region_integrity AS (
  SELECT json_agg(t) AS data FROM (
    SELECT source, count(*) AS rows
    FROM utility_providers
    WHERE regions IS NULL OR array_length(regions, 1) IS NULL OR array_length(regions, 1) = 0
    GROUP BY source
    ORDER BY count(*) DESC
  ) t
),

-- 10. CROSS-STATE CONTAMINATION
state_tags AS (
  SELECT
    id, name, source,
    array(
      SELECT unnest(regions) INTERSECT
      SELECT unnest(ARRAY['CT','NY','MA','RI','MI','NH','VT','ME','NJ','PA'])
    ) AS state_codes
  FROM utility_providers
  WHERE source = 'google_places'
),
cross_state_contamination AS (
  SELECT json_agg(t) AS data FROM (
    SELECT id, name, state_codes
    FROM state_tags
    WHERE array_length(state_codes, 1) > 1
    ORDER BY array_length(state_codes, 1) DESC
    LIMIT 20
  ) t
),

-- 11. CONTRACTORS FK ORPHANS
contractor_orphans AS (
  SELECT json_build_object('orphan_count', count(*)) AS data
  FROM contractors c
  WHERE c.utility_provider_id IS NOT NULL
    AND NOT EXISTS (
      SELECT 1 FROM utility_providers up WHERE up.id = c.utility_provider_id
    )
),

-- 12. CACHE AGE
cache_age AS (
  SELECT json_agg(t) AS data FROM (
    SELECT
      CASE
        WHEN fetched_at > now() - interval '1 day'  THEN '1_fresh_under_1day'
        WHEN fetched_at > now() - interval '7 days' THEN '2_under_1week'
        WHEN fetched_at > now() - interval '30 days' THEN '3_under_30days'
        ELSE '4_stale_over_30days'
      END AS age_bucket,
      count(*) AS rows
    FROM local_vendor_results
    GROUP BY 1
    ORDER BY 1
  ) t
),

-- 13. SPOT-CHECK 20 RANDOM GOOGLE_PLACES ROWS
spot_check AS (
  SELECT json_agg(t) AS data FROM (
    SELECT name, provider_type, website, phone, regions[1:3] AS first_regions
    FROM utility_providers
    WHERE source = 'google_places'
    ORDER BY random()
    LIMIT 20
  ) t
)

SELECT json_build_object(
  '01_totals_by_source',            (SELECT data FROM totals_by_source),
  '02_per_state_coverage',          (SELECT data FROM per_state_coverage),
  '03_low_coverage_fairfield_cells',(SELECT data FROM low_coverage_cells),
  '04_brand_shards',                (SELECT data FROM brand_shards),
  '05_exact_name_dupes',            (SELECT data FROM exact_name_dupes),
  '06_phone_dupes',                 (SELECT data FROM phone_dupes),
  '07_slug_dupes',                  (SELECT data FROM slug_dupes),
  '08_quality_dregs',               (SELECT data FROM quality_dregs),
  '09_region_integrity',            (SELECT data FROM region_integrity),
  '10_cross_state_contamination',   (SELECT data FROM cross_state_contamination),
  '11_contractor_fk_orphans',       (SELECT data FROM contractor_orphans),
  '12_cache_age',                   (SELECT data FROM cache_age),
  '13_spot_check',                  (SELECT data FROM spot_check)
) AS audit_result;
