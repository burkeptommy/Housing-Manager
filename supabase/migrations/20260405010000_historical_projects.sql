-- Historical projects: allow logging past completed projects
-- and linking documents to specific projects.

-- Add project_id to documents for document-project linking
ALTER TABLE documents ADD COLUMN IF NOT EXISTS project_id UUID REFERENCES property_projects(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_documents_project ON documents(project_id);

-- Add entry_type to property_projects to distinguish planned vs historical
ALTER TABLE property_projects ADD COLUMN IF NOT EXISTS entry_type TEXT NOT NULL DEFAULT 'planned';
