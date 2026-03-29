-- Whitelist of email addresses allowed to forward emails to a household's Alfred address.
-- Max 20 per household. Auto-seeded with household members' emails.

CREATE TABLE IF NOT EXISTS household_allowed_senders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    label TEXT,  -- e.g. "Tom Burke", "School", "Daycare"
    added_by UUID REFERENCES users(id),
    is_auto_added BOOLEAN DEFAULT false,  -- true for household members auto-added
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Each email unique per household
CREATE UNIQUE INDEX IF NOT EXISTS idx_allowed_senders_unique
    ON household_allowed_senders(household_id, lower(email));

-- Fast lookup during email ingestion
CREATE INDEX IF NOT EXISTS idx_allowed_senders_lookup
    ON household_allowed_senders(household_id, lower(email));

ALTER TABLE household_allowed_senders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can view allowed senders"
    ON household_allowed_senders FOR SELECT
    USING (
        household_id IN (
            SELECT household_id FROM users WHERE id = auth.uid()
        )
    );

CREATE POLICY "Members can insert allowed senders"
    ON household_allowed_senders FOR INSERT
    WITH CHECK (
        household_id IN (
            SELECT household_id FROM users WHERE id = auth.uid()
        )
    );

CREATE POLICY "Members can delete allowed senders"
    ON household_allowed_senders FOR DELETE
    USING (
        household_id IN (
            SELECT household_id FROM users WHERE id = auth.uid()
        )
    );

-- Auto-seed existing households with their members' emails
INSERT INTO household_allowed_senders (household_id, email, label, is_auto_added)
SELECT u.household_id, u.email, u.full_name, true
FROM users u
WHERE u.household_id IS NOT NULL
  AND u.email IS NOT NULL
ON CONFLICT DO NOTHING;
