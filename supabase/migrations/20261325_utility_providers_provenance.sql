-- Phase X feedback: provenance + network-effect gate for utility_providers.
--
-- BACKGROUND
-- The May 2026 fabrication purge cleaned out ~10,500 templated rows but left
-- the catalog with zero coverage in 11 service-trade categories across our
-- launch service area (Westchester + Fairfield). The new plan grows the
-- catalog from three sources: (1) bulk-seeded Google Places snapshots,
-- (2) organic growth on every find-a-pro query, (3) user contributions
-- from the manual / website / contacts add paths. We need provenance
-- tracking + a visibility gate so single-household contributions don't
-- pollute the shared catalog with PII or one-off vendors.
--
-- COLUMNS ADDED
--   source TEXT — provenance discriminator
--     'admin'              → manually seeded (existing rows, fully trusted)
--     'google_places'      → snapshot from Places API (real businesses)
--     'vendor_application' → vendor self-applied via getchez.com/vendor-apply
--     'user_pending'       → one household added it; private to that household
--     'user_verified'      → 2+ households independently added; visible to all
--   google_place_id TEXT — Google Places stable id, UNIQUE so the bulk seed
--                          and live-query upserts dedup cleanly.
--   contribution_count INTEGER — bumped each time a new household adds the
--                                same vendor (matched by phone/domain).
--                                Promotes user_pending → user_verified at 2.
--
-- VISIBILITY VIEW
-- `utility_providers_visible` filters to rows safe to show across households:
-- admin/google_places/vendor_application/user_verified always visible, plus
-- user_pending rows with contribution_count >= 2 (which would have been
-- promoted but we OR on both for belt-and-suspenders). The find-local-vendors
-- edge function reads from this view; user-contribution lookups (for the
-- catalog upsert path in VendorReviewForm) read the raw table via service role.

ALTER TABLE utility_providers
  ADD COLUMN IF NOT EXISTS source TEXT NOT NULL DEFAULT 'admin',
  ADD COLUMN IF NOT EXISTS google_place_id TEXT,
  ADD COLUMN IF NOT EXISTS contribution_count INTEGER NOT NULL DEFAULT 1;

-- CHECK constraint enumerates valid source values. Drop-and-add pattern so
-- the migration is idempotent if the constraint already exists with a
-- different name.
ALTER TABLE utility_providers DROP CONSTRAINT IF EXISTS utility_providers_source_valid;
ALTER TABLE utility_providers
  ADD CONSTRAINT utility_providers_source_valid
  CHECK (source IN ('admin', 'google_places', 'vendor_application', 'user_pending', 'user_verified'));

-- UNIQUE INDEX on google_place_id, partial because most rows are admin-seeded
-- without one. The bulk seed + live-query upserts use this for dedup.
CREATE UNIQUE INDEX IF NOT EXISTS utility_providers_google_place_id_uniq
  ON utility_providers (google_place_id)
  WHERE google_place_id IS NOT NULL;

-- Index on source for filtering by visibility (the view uses this) and
-- on provider_type already exists for category lookups.
CREATE INDEX IF NOT EXISTS utility_providers_source_idx
  ON utility_providers (source);

-- Visibility view consumed by find-local-vendors edge function. Keeps
-- household-private user_pending rows out of cross-household results
-- without requiring the function to maintain the filter logic in code.
CREATE OR REPLACE VIEW utility_providers_visible AS
  SELECT *
  FROM utility_providers
  WHERE source IN ('admin', 'google_places', 'vendor_application', 'user_verified')
     OR (source = 'user_pending' AND contribution_count >= 2);

COMMENT ON VIEW utility_providers_visible IS
  'Provenance-filtered view of utility_providers. Edge functions and other '
  'cross-household readers query this view; raw table access is reserved for '
  'service-role writes (catalog upserts) and admin tools.';

COMMENT ON COLUMN utility_providers.source IS
  'Provenance: admin (manual seed), google_places (Places API snapshot), '
  'vendor_application (self-applied at getchez.com), user_pending (1 household), '
  'user_verified (2+ households independently added — promoted from user_pending).';

COMMENT ON COLUMN utility_providers.contribution_count IS
  'Number of households that have added this vendor. Used to promote '
  'user_pending → user_verified at >= 2. Admin/Google/vendor_application '
  'rows are immutable at 1 and not gated by this counter.';
