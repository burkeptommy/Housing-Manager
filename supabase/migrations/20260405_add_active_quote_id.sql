-- Add active_quote_id to projects for tracking which quote drives the project cost
ALTER TABLE property_projects ADD COLUMN IF NOT EXISTS active_quote_id UUID REFERENCES project_quotes(id) ON DELETE SET NULL;
