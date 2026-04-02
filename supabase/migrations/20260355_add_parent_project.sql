-- Add parent_project_id for linking sub-projects to insurance claim projects
-- A claim project can have multiple child projects (roofing, electrical, plumbing, etc.)
-- Each child project retains full functionality (quotes, files, trades)
ALTER TABLE property_projects
ADD COLUMN IF NOT EXISTS parent_project_id UUID REFERENCES property_projects(id) ON DELETE SET NULL;

-- Index for efficient child project lookups
CREATE INDEX IF NOT EXISTS idx_projects_parent ON property_projects(parent_project_id) WHERE parent_project_id IS NOT NULL;
