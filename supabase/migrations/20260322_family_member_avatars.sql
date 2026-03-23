-- Add gender, avatar color, and expected date to family_members
ALTER TABLE family_members ADD COLUMN IF NOT EXISTS gender TEXT;
ALTER TABLE family_members ADD COLUMN IF NOT EXISTS avatar_color TEXT DEFAULT 'navy';
ALTER TABLE family_members ADD COLUMN IF NOT EXISTS expected_date DATE;
ALTER TABLE family_members ADD COLUMN IF NOT EXISTS is_expecting BOOLEAN DEFAULT false;
ALTER TABLE family_members ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
