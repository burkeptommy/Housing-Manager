-- Fix: household_email_addresses had RLS enabled but only a SELECT policy.
-- The trigger that auto-creates email addresses on household INSERT was failing
-- because it runs as the invoking user (no SECURITY DEFINER), and there was no
-- INSERT policy. This caused "new row violates row-level security policy" during onboarding.

-- 1. Make the trigger function SECURITY DEFINER so it bypasses RLS
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Add INSERT policy for the client-side fallback (generateHouseholdEmailAddress)
CREATE POLICY "Members can insert household email"
    ON household_email_addresses FOR INSERT
    WITH CHECK (
        household_id IN (
            SELECT household_id FROM users WHERE id = auth.uid()
        )
    );

-- 3. Also add a backfill for any households that were created after the trigger
-- started failing (they would be missing their email address row)
INSERT INTO household_email_addresses (household_id, unique_address)
SELECT h.id,
       LOWER(REGEXP_REPLACE(REPLACE(REPLACE(h.name, 'The ', ''), ' Family', ''), '[^a-z0-9]', '', 'g')) || '@alfred.havenhome.dev'
FROM households h
LEFT JOIN household_email_addresses hea ON hea.household_id = h.id
WHERE hea.id IS NULL
ON CONFLICT (household_id) DO NOTHING;
