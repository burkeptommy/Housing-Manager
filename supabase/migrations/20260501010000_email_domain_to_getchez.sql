-- Phase 71: cut household email forwarding addresses over from
-- @alfred.havenhome.dev to @alfred.getchez.com.
--
-- Two parts:
--   1. Update generate_household_email() so new households get the new domain.
--   2. Rewrite every existing household_email_addresses row in place so
--      legacy users land on the new domain without re-issuing addresses.
--
-- Local parts are unchanged. The (UNIQUE) household_id mapping is preserved
-- and the (UNIQUE) unique_address column stays unique because every row
-- swaps the same suffix.
--
-- Edge functions are tolerant of inbound mail to either the old or new
-- domain during the transition (see receive-email/index.ts), so this is a
-- one-way write that doesn't require choreographed deploy ordering.

-- 1. Update the trigger function
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
    candidate := base_name || '@alfred.getchez.com';
    WHILE EXISTS (SELECT 1 FROM household_email_addresses WHERE unique_address = candidate) LOOP
        suffix := suffix + 1;
        candidate := base_name || suffix::text || '@alfred.getchez.com';
    END LOOP;

    INSERT INTO household_email_addresses (household_id, unique_address)
    VALUES (NEW.id, candidate)
    ON CONFLICT (household_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Rewrite existing rows in place
UPDATE household_email_addresses
SET unique_address = REPLACE(unique_address, '@alfred.havenhome.dev', '@alfred.getchez.com')
WHERE unique_address LIKE '%@alfred.havenhome.dev';

-- 3. Catch any (legacy) projects.havenhome.dev rows too — same canonical domain
UPDATE household_email_addresses
SET unique_address = REPLACE(unique_address, '@projects.havenhome.dev', '@alfred.getchez.com')
WHERE unique_address LIKE '%@projects.havenhome.dev';
