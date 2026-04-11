-- Phase 48: Link estate documents to the attorney who prepared them.
-- Nullable FK to trusted_contacts so estate docs can reference the
-- preparing attorney for the attorney-handoff export flow.

ALTER TABLE documents
  ADD COLUMN IF NOT EXISTS linked_attorney_contact_id UUID
  REFERENCES trusted_contacts(id) ON DELETE SET NULL;

CREATE INDEX idx_documents_linked_attorney
  ON documents(linked_attorney_contact_id)
  WHERE linked_attorney_contact_id IS NOT NULL;
