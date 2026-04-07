-- Add school/institution field for children
ALTER TABLE family_members ADD COLUMN IF NOT EXISTS school TEXT;
