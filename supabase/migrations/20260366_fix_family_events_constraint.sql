-- Fix: Replace partial unique index with a proper unique constraint
-- so ON CONFLICT works with Supabase upsert.
DROP INDEX IF EXISTS idx_family_events_external_unique;

-- Use COALESCE to handle NULLs — events without external IDs won't conflict
ALTER TABLE family_events ADD CONSTRAINT family_events_external_unique
  UNIQUE (household_id, external_calendar_id, external_event_id);
