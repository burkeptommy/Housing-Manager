-- Add avatar photo URL to family_members
ALTER TABLE family_members ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- Add avatar photo URL to trusted_contacts (keep parity)
ALTER TABLE trusted_contacts ADD COLUMN IF NOT EXISTS avatar_url TEXT;
