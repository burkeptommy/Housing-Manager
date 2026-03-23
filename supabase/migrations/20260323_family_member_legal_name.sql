-- Add legal_name field for document matching (e.g. "Thomas Patrick Burke" vs display name "Tom Burke")
ALTER TABLE family_members ADD COLUMN IF NOT EXISTS legal_name TEXT;
