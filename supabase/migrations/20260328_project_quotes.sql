-- Project quotes: stores contractor quote analyses as children of projects.
-- A project can have multiple quotes from different contractors for comparison.
-- IDEMPOTENT: safe to re-run.

CREATE TABLE IF NOT EXISTS project_quotes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES property_projects(id) ON DELETE CASCADE,
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    contractor_id UUID REFERENCES contractors(id) ON DELETE SET NULL,

    quote_date DATE,
    quote_total DECIMAL(12,2),
    estimated_fair_total DECIMAL(12,2),
    overall_rating TEXT,
    analysis JSONB NOT NULL,
    file_path TEXT,
    notes TEXT,

    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_project_quotes_project ON project_quotes(project_id);
CREATE INDEX IF NOT EXISTS idx_project_quotes_household ON project_quotes(household_id);

ALTER TABLE project_quotes ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Members can view household quotes' AND tablename = 'project_quotes') THEN
        CREATE POLICY "Members can view household quotes" ON project_quotes FOR SELECT USING (household_id IN (SELECT household_id FROM users WHERE id = auth.uid()));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Members can insert household quotes' AND tablename = 'project_quotes') THEN
        CREATE POLICY "Members can insert household quotes" ON project_quotes FOR INSERT WITH CHECK (household_id IN (SELECT household_id FROM users WHERE id = auth.uid()));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Members can update household quotes' AND tablename = 'project_quotes') THEN
        CREATE POLICY "Members can update household quotes" ON project_quotes FOR UPDATE USING (household_id IN (SELECT household_id FROM users WHERE id = auth.uid()));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Members can delete household quotes' AND tablename = 'project_quotes') THEN
        CREATE POLICY "Members can delete household quotes" ON project_quotes FOR DELETE USING (household_id IN (SELECT household_id FROM users WHERE id = auth.uid()));
    END IF;
END $$;
