-- Add processing status to inbox_items so users see immediate feedback
-- when an email arrives (before AI classification completes).
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='inbox_items' AND column_name='status') THEN
    ALTER TABLE inbox_items ADD COLUMN status TEXT DEFAULT 'ready';
    -- Values: 'processing' (just received, AI working), 'ready' (fully processed)
  END IF;
END $$;
