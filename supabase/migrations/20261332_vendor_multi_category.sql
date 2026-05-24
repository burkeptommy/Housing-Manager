-- Phase X+7: multi-category vendor support.
--
-- The UNIQUE constraint on utility_providers.google_place_id means each
-- vendor lives in exactly ONE provider_type slot. For genuinely
-- multi-service operators — T.Webber Plumbing/Heating/Air/Electric
-- (4.8★/6,998 reviews), 128 Plumbing/Heating/Cooling/Electric (4.9★),
-- MacFarlane Energy (electric+gas+oil+propane), Rick's Pump and Water
-- Service (well_water_service + plumbing) — whichever category the seed
-- hit first won, and the rest never saw them.
--
-- Symptom Tom caught: searching for Rick's Pump in well_water_service
-- returned nothing because Rick's is classified as plumbing.
--
-- Fix: add a `secondary_provider_types text[]` column. The primary
-- `provider_type` stays as-is (avoids breaking every existing query),
-- and secondary holds every OTHER category the cache observed the
-- vendor under. mergeUtilityProviders will match on `provider_type = X
-- OR X = ANY(secondary_provider_types)`.

BEGIN;

ALTER TABLE utility_providers
  ADD COLUMN IF NOT EXISTS secondary_provider_types text[];

COMMENT ON COLUMN utility_providers.secondary_provider_types IS 'Additional categories the vendor services beyond provider_type. Backfilled from local_vendor_results cache. Query: WHERE provider_type = X OR X = ANY(secondary_provider_types).';

CREATE INDEX IF NOT EXISTS utility_providers_secondary_types_idx
  ON utility_providers USING GIN (secondary_provider_types)
  WHERE secondary_provider_types IS NOT NULL;

-- Backfill: for every catalog row with a google_place_id, find all
-- DISTINCT categories the cache observed it under, minus the primary
-- (which stays in `provider_type`). Use the same cache→category map
-- the find-local-vendors edge function uses.
WITH cache_to_provider AS (
  -- The cache's `category` column matches our provider_type slug
  -- 1:1 for most categories, so a direct equality is fine. The
  -- few cases where the cache used a different label (e.g.
  -- "mosquito & tick") never make it to utility_providers anyway.
  SELECT DISTINCT
    google_place_id,
    category AS provider_type
  FROM local_vendor_results
  WHERE google_place_id IS NOT NULL
),
secondary_by_place AS (
  SELECT
    c2p.google_place_id,
    array_agg(DISTINCT c2p.provider_type ORDER BY c2p.provider_type) AS all_types
  FROM cache_to_provider c2p
  GROUP BY c2p.google_place_id
  HAVING count(DISTINCT c2p.provider_type) > 1
)
UPDATE utility_providers up
SET secondary_provider_types = (
  -- Filter out the primary so we don't double-list it
  SELECT array_agg(t ORDER BY t)
  FROM unnest(sbp.all_types) AS t
  WHERE t <> up.provider_type
)
FROM secondary_by_place sbp
WHERE up.google_place_id = sbp.google_place_id
  AND up.source = 'google_places';

-- Recreate the visibility view to include the new column.
DROP VIEW IF EXISTS utility_providers_visible;
CREATE VIEW utility_providers_visible AS
SELECT
  id, name, slug, provider_type,
  logo_url, brand_color, website, phone,
  regions, created_at,
  bundles_with_auto, bundles_with_home,
  prominence_rank, source, google_place_id, contribution_count,
  address, rating, review_count,
  secondary_provider_types
FROM utility_providers
WHERE source IN ('admin', 'google_places', 'vendor_application', 'user_verified')
   OR (source = 'user_pending' AND contribution_count >= 2);

DO $$
DECLARE
  multi_cat_count int;
  ricks_secondary text[];
BEGIN
  SELECT count(*) INTO multi_cat_count
  FROM utility_providers
  WHERE array_length(secondary_provider_types, 1) > 0;
  SELECT secondary_provider_types INTO ricks_secondary
  FROM utility_providers
  WHERE name ILIKE 'rick%pump%water%' LIMIT 1;
  RAISE NOTICE 'Multi-category vendors: %, Ricks Pump secondaries: %', multi_cat_count, ricks_secondary;
END $$;

COMMIT;
