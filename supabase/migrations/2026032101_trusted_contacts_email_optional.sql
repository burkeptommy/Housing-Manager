-- Make email optional for trusted contacts (e.g. when adding from iOS contacts without email)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'trusted_contacts') THEN
        ALTER TABLE trusted_contacts ALTER COLUMN email DROP NOT NULL;
        ALTER TABLE trusted_contacts ALTER COLUMN email SET DEFAULT '';
    END IF;
END $$;
