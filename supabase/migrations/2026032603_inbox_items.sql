-- Inbox items: tracks everything auto-created from forwarded emails
-- The app polls this on foreground to show notifications
CREATE TABLE IF NOT EXISTS inbox_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    type TEXT NOT NULL, -- 'project_created', 'document_stored', 'vendor_added'
    title TEXT NOT NULL,
    summary TEXT,
    from_email TEXT,
    related_project_id UUID REFERENCES property_projects(id) ON DELETE SET NULL,
    related_document_id UUID REFERENCES documents(id) ON DELETE SET NULL,
    related_contractor_id UUID REFERENCES contractors(id) ON DELETE SET NULL,
    seen BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE inbox_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can view household inbox"
    ON inbox_items FOR SELECT
    USING (
        household_id IN (
            SELECT household_id FROM users WHERE id = auth.uid()
        )
    );

CREATE POLICY "Members can update household inbox"
    ON inbox_items FOR UPDATE
    USING (
        household_id IN (
            SELECT household_id FROM users WHERE id = auth.uid()
        )
    );

CREATE INDEX idx_inbox_items_household_unseen ON inbox_items(household_id, seen) WHERE seen = false;
