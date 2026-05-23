-- Phase X+5 — utility_providers gets rich display fields.
--
-- Before this migration, catalog rows stored only name + phone +
-- website + regions + brand metadata. Address, rating, and review
-- count lived ONLY in `local_vendor_results` (the 30-day Google
-- Places cache). The result: FROM YOUR AREA cards in find-a-pro
-- showed only phone + website with no rating or address, while
-- TOP-RATED and SUGGESTED cards (from the live Google call) showed
-- full rich data — visually inconsistent and operationally weaker.
--
-- This migration:
--   1. Adds `address`, `rating`, `review_count` columns to
--      `utility_providers`.
--   2. Backfills them from `local_vendor_results` where a cache row
--      with the same `google_place_id` carries the data.
--   3. The find-local-vendors edge function will be updated in lockstep
--      to stamp these fields on every new google_places upsert.

ALTER TABLE utility_providers
  ADD COLUMN IF NOT EXISTS address text,
  ADD COLUMN IF NOT EXISTS rating numeric(2,1),
  ADD COLUMN IF NOT EXISTS review_count integer;

COMMENT ON COLUMN utility_providers.address IS
  'Full street address. For google_places rows, populated from Places API formatted_address. For admin rows, often NULL (national brands).';
COMMENT ON COLUMN utility_providers.rating IS
  'Average rating 0.0-5.0. Populated for google_places rows from Places API; NULL for admin rows unless manually set.';
COMMENT ON COLUMN utility_providers.review_count IS
  'Total review count from source. Populated for google_places rows; NULL for admin rows.';

-- Backfill from local_vendor_results cache. For each catalog row with
-- a google_place_id, pick the most-recent matching cache row that has
-- rating data (different (town, state, category) cells may have
-- harvested the same place; the freshest one wins).
WITH best_cache AS (
  SELECT DISTINCT ON (google_place_id)
    google_place_id, address, rating, review_count
  FROM local_vendor_results
  WHERE google_place_id IS NOT NULL
    AND rating IS NOT NULL
  ORDER BY google_place_id, fetched_at DESC
)
UPDATE utility_providers up
SET
  address      = COALESCE(up.address, bc.address),
  rating       = COALESCE(up.rating,  bc.rating),
  review_count = COALESCE(up.review_count, bc.review_count)
FROM best_cache bc
WHERE up.google_place_id = bc.google_place_id;

-- Index by rating so find-a-pro filter chips (4+, 4.5+, 4.8+) can
-- short-circuit when scanning thousands of catalog rows.
CREATE INDEX IF NOT EXISTS utility_providers_rating_idx
  ON utility_providers (rating DESC NULLS LAST)
  WHERE rating IS NOT NULL;

-- Recreate the visibility view to include the new fields. The view
-- gates user_pending rows from cross-household exposure (Phase X+1).
DROP VIEW IF EXISTS utility_providers_visible;
CREATE VIEW utility_providers_visible AS
SELECT
  id, name, slug, provider_type,
  logo_url, brand_color, website, phone,
  regions, created_at,
  bundles_with_auto, bundles_with_home,
  prominence_rank, source, google_place_id, contribution_count,
  address, rating, review_count
FROM utility_providers
WHERE source IN ('admin', 'google_places', 'vendor_application', 'user_verified')
   OR (source = 'user_pending' AND contribution_count >= 2);

-- Sanity log
DO $$
DECLARE
  catalog_with_rating int;
  catalog_with_address int;
  total_google int;
BEGIN
  SELECT count(*) INTO total_google FROM utility_providers WHERE source = 'google_places';
  SELECT count(*) INTO catalog_with_rating FROM utility_providers WHERE rating IS NOT NULL;
  SELECT count(*) INTO catalog_with_address FROM utility_providers WHERE address IS NOT NULL;
  RAISE NOTICE 'utility_providers enriched: total_google=%, with_rating=%, with_address=%',
    total_google, catalog_with_rating, catalog_with_address;
END $$;
