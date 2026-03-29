-- Add family-related columns to inbox_items for family email classification.
-- family_category: school, events, medical, activities, travel, personal, other
-- family_member_name: AI-extracted name of the family member the email relates to

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='inbox_items' AND column_name='family_category') THEN
    ALTER TABLE inbox_items ADD COLUMN family_category TEXT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='inbox_items' AND column_name='family_member_name') THEN
    ALTER TABLE inbox_items ADD COLUMN family_member_name TEXT;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_inbox_items_family
  ON inbox_items(household_id, type)
  WHERE type = 'family';
