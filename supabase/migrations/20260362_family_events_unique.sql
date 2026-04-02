-- Add unique constraint on external events to prevent duplicate calendar syncs.
-- Drop the existing non-unique index and replace with a unique one.
DROP INDEX IF EXISTS idx_family_events_external;
CREATE UNIQUE INDEX idx_family_events_external_unique
  ON family_events(household_id, external_calendar_id, external_event_id)
  WHERE external_calendar_id IS NOT NULL AND external_event_id IS NOT NULL;
