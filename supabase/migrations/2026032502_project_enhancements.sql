-- Project Planning Enhancements: cost display, item categorization, user toolkit
-- Additive migration — no existing columns modified.

-- Cached sum of non-owned estimated line items (for summary card display)
ALTER TABLE property_projects ADD COLUMN IF NOT EXISTS estimated_total DECIMAL(12,2) DEFAULT 0;

-- Item necessity classification (required/optional/likely_owned)
ALTER TABLE project_line_items ADD COLUMN IF NOT EXISTS necessity TEXT DEFAULT 'required';

-- Flag for tools useful across multiple projects
ALTER TABLE project_line_items ADD COLUMN IF NOT EXISTS multi_project_useful BOOLEAN DEFAULT false;

-- Household toolkit: persistent tool inventory across projects
CREATE TABLE IF NOT EXISTS household_toolkit (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    tool_name TEXT NOT NULL,
    normalized_name TEXT NOT NULL,
    category TEXT DEFAULT 'tools',
    added_from_project_id UUID REFERENCES property_projects(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(household_id, normalized_name)
);

CREATE INDEX idx_household_toolkit_household ON household_toolkit(household_id);
CREATE INDEX idx_household_toolkit_normalized ON household_toolkit(normalized_name);

ALTER TABLE household_toolkit ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view toolkit in their household"
    ON household_toolkit FOR SELECT
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can insert toolkit in their household"
    ON household_toolkit FOR INSERT
    WITH CHECK (household_id = public.get_my_household_id());

CREATE POLICY "Users can update toolkit in their household"
    ON household_toolkit FOR UPDATE
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can delete toolkit in their household"
    ON household_toolkit FOR DELETE
    USING (household_id = public.get_my_household_id());
