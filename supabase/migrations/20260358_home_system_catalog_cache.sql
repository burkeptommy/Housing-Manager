-- Cache catalog enrichment data directly on home_systems to avoid
-- calling the search-equipment edge function on every page load.
-- This data is populated when a system is linked to a catalog entry
-- and refreshed periodically in the background.

ALTER TABLE home_systems ADD COLUMN IF NOT EXISTS catalog_series TEXT;
ALTER TABLE home_systems ADD COLUMN IF NOT EXISTS catalog_model_name TEXT;
ALTER TABLE home_systems ADD COLUMN IF NOT EXISTS catalog_features TEXT[] DEFAULT '{}';
ALTER TABLE home_systems ADD COLUMN IF NOT EXISTS reliability_score INTEGER;
ALTER TABLE home_systems ADD COLUMN IF NOT EXISTS score_summary TEXT;
ALTER TABLE home_systems ADD COLUMN IF NOT EXISTS catalog_fuel_type TEXT;
ALTER TABLE home_systems ADD COLUMN IF NOT EXISTS catalog_enriched_at TIMESTAMPTZ;
