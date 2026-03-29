-- Add a dedicated email_hash column to inbox_items for reliable deduplication.
-- The previous approach relied on JSONB .contains() queries against metadata,
-- which was fragile and used a 10-minute window that was far too short to
-- prevent SendGrid retry duplicates.

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='inbox_items' AND column_name='email_hash') THEN
    ALTER TABLE inbox_items ADD COLUMN email_hash TEXT;
  END IF;
END $$;

-- Backfill email_hash from metadata for existing rows
UPDATE inbox_items
SET email_hash = metadata->>'email_hash'
WHERE email_hash IS NULL
  AND metadata->>'email_hash' IS NOT NULL;

-- Delete existing duplicates (keep only the oldest per household+email_hash)
DELETE FROM inbox_items
WHERE id IN (
  SELECT id FROM (
    SELECT id,
           ROW_NUMBER() OVER (PARTITION BY household_id, email_hash ORDER BY created_at ASC) AS rn
    FROM inbox_items
    WHERE email_hash IS NOT NULL AND status != 'processing'
  ) dupes
  WHERE rn > 1
);

-- Unique constraint: one email hash per household prevents duplicates at the DB level
CREATE UNIQUE INDEX IF NOT EXISTS idx_inbox_items_email_hash_household
  ON inbox_items(household_id, email_hash)
  WHERE email_hash IS NOT NULL AND status != 'processing';
