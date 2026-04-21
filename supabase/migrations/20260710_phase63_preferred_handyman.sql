-- Phase 63: Preferred handyman reference on households.
--
-- Captures the one "preferred" handyman per household so the UI can surface
-- their name in routing affordances ("Add to Mike's next visit"), Alfred
-- context ("Tom's preferred handyman is Mike at Mike's Fix-It"), and the
-- Settings → Handyman preference sheet.
--
-- The preference value itself (has_one / does_diy / needs_help) lives in
-- `properties.attributes.handyman_preference` — no new column needed because
-- the JSONB attributes bag already handles per-property preferences.
-- This migration is just the FK linking households to the preferred
-- contractor row (derived from the Q15b handyman chip when the user
-- captured a provider).

ALTER TABLE households
  ADD COLUMN IF NOT EXISTS preferred_handyman_contractor_id UUID REFERENCES contractors(id) ON DELETE SET NULL;

-- Optional index on the attribute for analytics. Extracts the preference
-- string from the JSONB bag for cheap filtering.
CREATE INDEX IF NOT EXISTS idx_properties_handyman_preference
  ON properties ((attributes->>'handyman_preference'));
