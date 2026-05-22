-- Phase X+2: PostgREST's upsert with `onConflict: "google_place_id"`
-- requires a UNIQUE constraint, not just a partial unique index. The
-- earlier migration (20261325) created a partial unique index, which
-- worked for direct SQL inserts but caused the find-local-vendors
-- edge function's catalog upsert to silently no-op. This migration
-- swaps to a proper UNIQUE constraint.
--
-- Multiple NULLs remain allowed (PostgreSQL treats NULLs as distinct
-- by default for UNIQUE constraints), so existing admin-seeded rows
-- with no `google_place_id` continue to coexist.

DROP INDEX IF EXISTS utility_providers_google_place_id_uniq;

ALTER TABLE utility_providers
  DROP CONSTRAINT IF EXISTS utility_providers_google_place_id_unique;

ALTER TABLE utility_providers
  ADD CONSTRAINT utility_providers_google_place_id_unique UNIQUE (google_place_id);
