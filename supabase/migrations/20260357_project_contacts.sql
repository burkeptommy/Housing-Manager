-- Project contacts: links multiple contractors/contacts to a project.
-- Enables matching incoming emails to the right project by sender.
-- A contractor can be associated via quote (existing) OR via this table (general contact).
CREATE TABLE project_contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES property_projects(id) ON DELETE CASCADE,
  household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  contractor_id UUID REFERENCES contractors(id) ON DELETE SET NULL,
  -- Denormalized contact info for matching even without a contractor record
  contact_name TEXT,
  contact_email TEXT,
  contact_phone TEXT,
  role TEXT DEFAULT 'contractor', -- contractor, inspector, architect, adjuster, other
  added_from TEXT DEFAULT 'email', -- email, manual, quote
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(project_id, contractor_id)
);

CREATE INDEX idx_project_contacts_project ON project_contacts(project_id);
CREATE INDEX idx_project_contacts_household ON project_contacts(household_id);
CREATE INDEX idx_project_contacts_email ON project_contacts(household_id, contact_email)
  WHERE contact_email IS NOT NULL;
CREATE INDEX idx_project_contacts_contractor ON project_contacts(contractor_id)
  WHERE contractor_id IS NOT NULL;

ALTER TABLE project_contacts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their household project contacts"
  ON project_contacts FOR SELECT
  USING (household_id IN (SELECT household_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Users can manage their household project contacts"
  ON project_contacts FOR INSERT
  WITH CHECK (household_id IN (SELECT household_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Users can update their household project contacts"
  ON project_contacts FOR UPDATE
  USING (household_id IN (SELECT household_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Users can delete their household project contacts"
  ON project_contacts FOR DELETE
  USING (household_id IN (SELECT household_id FROM users WHERE id = auth.uid()));

-- Add email_summaries JSONB to property_projects for all project types (not just insurance claims).
-- This stores a log of all email correspondence related to the project.
ALTER TABLE property_projects ADD COLUMN IF NOT EXISTS email_summaries JSONB DEFAULT '[]';
