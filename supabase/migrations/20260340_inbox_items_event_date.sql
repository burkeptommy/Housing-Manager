-- Add event_date for family events (the actual date of the event, not when forwarded)
-- Add tagged_member_ids for associating family members with events

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='inbox_items' AND column_name='event_date') THEN
    ALTER TABLE inbox_items ADD COLUMN event_date TIMESTAMPTZ;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='inbox_items' AND column_name='tagged_member_ids') THEN
    ALTER TABLE inbox_items ADD COLUMN tagged_member_ids UUID[] DEFAULT '{}';
  END IF;
END $$;

-- Index for querying upcoming family events
CREATE INDEX IF NOT EXISTS idx_inbox_items_family_events
  ON inbox_items(household_id, event_date)
  WHERE type = 'family' AND event_date IS NOT NULL;
