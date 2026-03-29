-- Project files: photos, documents, and other attachments uploaded by users
-- to provide context for their projects (especially DIY projects).
CREATE TABLE IF NOT EXISTS project_files (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES property_projects(id) ON DELETE CASCADE,
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    file_path TEXT NOT NULL,
    filename TEXT NOT NULL,
    content_type TEXT,
    file_size INTEGER,
    thumbnail_path TEXT,
    notes TEXT,
    uploaded_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE project_files ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can view project files"
    ON project_files FOR SELECT
    USING (
        household_id IN (
            SELECT household_id FROM users WHERE id = auth.uid()
        )
    );

CREATE POLICY "Members can insert project files"
    ON project_files FOR INSERT
    WITH CHECK (
        household_id IN (
            SELECT household_id FROM users WHERE id = auth.uid()
        )
    );

CREATE POLICY "Members can delete project files"
    ON project_files FOR DELETE
    USING (
        household_id IN (
            SELECT household_id FROM users WHERE id = auth.uid()
        )
    );

CREATE INDEX idx_project_files_project ON project_files(project_id);
