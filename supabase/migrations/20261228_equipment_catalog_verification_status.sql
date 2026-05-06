-- Phase 3 of the equipment catalog expansion (plan: i-tried-to-add-reactive-boole.md).
--
-- Adds a verification_status column to equipment_catalog so we can track
-- which rows are Claude-only (default for Phase 3 batch generation) vs
-- verified by Apify against a real manufacturer support page (future
-- background job) vs verified by a human admin via the catalog request
-- workflow (Phase 4).
--
-- The column is nullable for backward compat with the existing 3,537
-- legacy seed/scraped rows. Phase 3 inserts will stamp 'claude_generated';
-- Apify and admin paths will promote rows over time.

BEGIN;

-- Add the column (nullable so legacy rows aren't disturbed)
ALTER TABLE equipment_catalog
    ADD COLUMN IF NOT EXISTS verification_status TEXT
    CHECK (verification_status IN ('claude_generated', 'apify_verified', 'human_verified', 'flagged'));

CREATE INDEX IF NOT EXISTS idx_equipment_catalog_verification_status
    ON equipment_catalog(verification_status)
    WHERE verification_status IS NOT NULL;

COMMENT ON COLUMN equipment_catalog.verification_status IS
  'Provenance / confidence flag for the row. NULL = legacy seed (pre-Phase-3). claude_generated = Phase 3 batch insert (lower confidence, may have hallucinated model numbers). apify_verified = Apify scraper confirmed a real manufacturer support page exists for this model. human_verified = admin reviewed and added via catalog request flow (highest confidence). flagged = admin marked as suspect / pending re-verification.';

-- Add a popularity ordering hint (tracks position 1-80 within Phase 3 prompt
-- responses so search-equipment can rank by popularity within a brand,
-- category pair when no exact spec match wins).
ALTER TABLE equipment_catalog
    ADD COLUMN IF NOT EXISTS popularity_rank INT;

COMMENT ON COLUMN equipment_catalog.popularity_rank IS
  'Phase 3 stamps this 1-80 from Claude''s popularity-ordered response. Lower = more popular. NULL on legacy rows. search-equipment uses ASC NULLS LAST so popularity-ranked rows surface first.';

CREATE INDEX IF NOT EXISTS idx_equipment_catalog_popularity_rank
    ON equipment_catalog(category_id, manufacturer_id, popularity_rank ASC NULLS LAST)
    WHERE popularity_rank IS NOT NULL;

-- Track when the row was last verified (NULL = never). Lets us re-verify
-- claude_generated rows quarterly without disturbing legacy data.
ALTER TABLE equipment_catalog
    ADD COLUMN IF NOT EXISTS last_verified_at TIMESTAMPTZ;

COMMENT ON COLUMN equipment_catalog.last_verified_at IS
  'When the row''s verification_status was last refreshed. NULL = never verified.';

COMMIT;
