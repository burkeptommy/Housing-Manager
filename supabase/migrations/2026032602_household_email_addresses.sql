-- Household email addresses for Alfred forwarding (quotes, documents, vendor info, etc.)
CREATE TABLE IF NOT EXISTS household_email_addresses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    unique_address TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT one_email_per_household UNIQUE (household_id)
);

-- Enable RLS
ALTER TABLE household_email_addresses ENABLE ROW LEVEL SECURITY;

-- Household members can read their own email address
CREATE POLICY "Members can view household email"
    ON household_email_addresses FOR SELECT
    USING (
        household_id IN (
            SELECT household_id FROM users WHERE id = auth.uid()
        )
    );

-- Generate lastname@alfred.havenhome.dev with collision handling
CREATE OR REPLACE FUNCTION generate_household_email()
RETURNS TRIGGER AS $$
DECLARE
    base_name TEXT;
    candidate TEXT;
    suffix INT := 0;
BEGIN
    -- Extract last name from household name (e.g., 'The Burke Family' -> 'burke')
    base_name := LOWER(TRIM(
        REPLACE(REPLACE(NEW.name, 'The ', ''), ' Family', '')
    ));
    -- Remove non-alphanumeric characters
    base_name := REGEXP_REPLACE(base_name, '[^a-z0-9]', '', 'g');
    -- Fallback to household ID prefix if name is empty
    IF base_name = '' OR base_name IS NULL THEN
        base_name := LOWER(SUBSTRING(NEW.id::text, 1, 8));
    END IF;

    -- Try base name first, then add suffix for collisions
    candidate := base_name || '@alfred.havenhome.dev';
    WHILE EXISTS (SELECT 1 FROM household_email_addresses WHERE unique_address = candidate) LOOP
        suffix := suffix + 1;
        candidate := base_name || suffix::text || '@alfred.havenhome.dev';
    END LOOP;

    INSERT INTO household_email_addresses (household_id, unique_address)
    VALUES (NEW.id, candidate)
    ON CONFLICT (household_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS auto_generate_household_email ON households;
CREATE TRIGGER auto_generate_household_email
    AFTER INSERT ON households
    FOR EACH ROW
    EXECUTE FUNCTION generate_household_email();

-- Auto-generate for existing households
INSERT INTO household_email_addresses (household_id, unique_address)
SELECT id, LOWER(REGEXP_REPLACE(REPLACE(REPLACE(name, 'The ', ''), ' Family', ''), '[^a-z0-9]', '', 'g')) || '@alfred.havenhome.dev'
FROM households
ON CONFLICT (household_id) DO NOTHING;
