-- Migration: Add document_parties, trusted_contacts, trusted_contact_documents
-- Purpose: Store AI-identified people on documents + enable trusted contact sharing

-- ============================================================================
-- TABLES
-- ============================================================================

-- Trusted Contacts (external people the household trusts with document access)
CREATE TABLE trusted_contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    role TEXT NOT NULL DEFAULT 'other',  -- 'estate_attorney', 'executor', 'financial_advisor', 'trustee', 'family', 'accountant', 'insurance_agent', 'other'
    company TEXT,
    invite_status TEXT NOT NULL DEFAULT 'pending',  -- 'pending', 'sent', 'accepted', 'revoked'
    invite_token UUID DEFAULT gen_random_uuid(),
    invite_sent_at TIMESTAMPTZ,
    last_accessed_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Document Parties (people identified by AI in a document)
CREATE TABLE document_parties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    role TEXT NOT NULL,  -- 'executor', 'trustee', 'attorney', 'beneficiary', 'agent', 'witness', 'grantor', 'notary', etc.
    family_member_id UUID REFERENCES family_members(id) ON DELETE SET NULL,
    trusted_contact_id UUID REFERENCES trusted_contacts(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Junction: which documents each trusted contact can access
CREATE TABLE trusted_contact_documents (
    trusted_contact_id UUID NOT NULL REFERENCES trusted_contacts(id) ON DELETE CASCADE,
    document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    granted_at TIMESTAMPTZ DEFAULT now(),
    granted_by UUID REFERENCES auth.users(id),
    PRIMARY KEY (trusted_contact_id, document_id)
);

-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX idx_trusted_contacts_household ON trusted_contacts(household_id);
CREATE INDEX idx_trusted_contacts_invite_token ON trusted_contacts(invite_token);
CREATE INDEX idx_document_parties_document ON document_parties(document_id);
CREATE INDEX idx_document_parties_household ON document_parties(household_id);

-- ============================================================================
-- RLS
-- ============================================================================

ALTER TABLE trusted_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_parties ENABLE ROW LEVEL SECURITY;
ALTER TABLE trusted_contact_documents ENABLE ROW LEVEL SECURITY;

-- trusted_contacts
CREATE POLICY "Users can view household trusted contacts"
    ON trusted_contacts FOR SELECT
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can insert household trusted contacts"
    ON trusted_contacts FOR INSERT
    WITH CHECK (household_id = public.get_my_household_id());

CREATE POLICY "Users can update household trusted contacts"
    ON trusted_contacts FOR UPDATE
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can delete household trusted contacts"
    ON trusted_contacts FOR DELETE
    USING (household_id = public.get_my_household_id());

-- document_parties
CREATE POLICY "Users can view household document parties"
    ON document_parties FOR SELECT
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can insert household document parties"
    ON document_parties FOR INSERT
    WITH CHECK (household_id = public.get_my_household_id());

CREATE POLICY "Users can update household document parties"
    ON document_parties FOR UPDATE
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can delete household document parties"
    ON document_parties FOR DELETE
    USING (household_id = public.get_my_household_id());

-- trusted_contact_documents (junction — access via trusted_contact's household)
CREATE POLICY "Users can view trusted contact document links"
    ON trusted_contact_documents FOR SELECT
    USING (trusted_contact_id IN (
        SELECT id FROM trusted_contacts WHERE household_id = public.get_my_household_id()
    ));

CREATE POLICY "Users can insert trusted contact document links"
    ON trusted_contact_documents FOR INSERT
    WITH CHECK (trusted_contact_id IN (
        SELECT id FROM trusted_contacts WHERE household_id = public.get_my_household_id()
    ));

CREATE POLICY "Users can delete trusted contact document links"
    ON trusted_contact_documents FOR DELETE
    USING (trusted_contact_id IN (
        SELECT id FROM trusted_contacts WHERE household_id = public.get_my_household_id()
    ));
