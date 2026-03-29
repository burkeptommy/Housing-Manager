-- Recreate all three tables from the original migration that failed silently

-- 1. Trusted Contacts (must come first - referenced by document_parties)
CREATE TABLE IF NOT EXISTS trusted_contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT DEFAULT '',
    phone TEXT,
    role TEXT NOT NULL DEFAULT 'other',
    company TEXT,
    invite_status TEXT NOT NULL DEFAULT 'pending',
    invite_token UUID DEFAULT gen_random_uuid(),
    invite_sent_at TIMESTAMPTZ,
    last_accessed_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Apply columns from later migrations
ALTER TABLE trusted_contacts ADD COLUMN IF NOT EXISTS gender TEXT;
ALTER TABLE trusted_contacts ADD COLUMN IF NOT EXISTS avatar_color TEXT DEFAULT 'navy';
ALTER TABLE trusted_contacts ADD COLUMN IF NOT EXISTS expected_date DATE;
ALTER TABLE trusted_contacts ADD COLUMN IF NOT EXISTS is_expecting BOOLEAN DEFAULT false;
ALTER TABLE trusted_contacts ADD COLUMN IF NOT EXISTS legal_name TEXT;

-- 2. Document Parties
CREATE TABLE IF NOT EXISTS document_parties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    role TEXT NOT NULL,
    family_member_id UUID REFERENCES family_members(id) ON DELETE SET NULL,
    trusted_contact_id UUID REFERENCES trusted_contacts(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Trusted Contact Documents junction
CREATE TABLE IF NOT EXISTS trusted_contact_documents (
    trusted_contact_id UUID NOT NULL REFERENCES trusted_contacts(id) ON DELETE CASCADE,
    document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    granted_at TIMESTAMPTZ DEFAULT now(),
    granted_by UUID REFERENCES auth.users(id),
    PRIMARY KEY (trusted_contact_id, document_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_trusted_contacts_household ON trusted_contacts(household_id);
CREATE INDEX IF NOT EXISTS idx_trusted_contacts_invite_token ON trusted_contacts(invite_token);
CREATE INDEX IF NOT EXISTS idx_document_parties_document ON document_parties(document_id);
CREATE INDEX IF NOT EXISTS idx_document_parties_household ON document_parties(household_id);

-- RLS
ALTER TABLE trusted_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_parties ENABLE ROW LEVEL SECURITY;
ALTER TABLE trusted_contact_documents ENABLE ROW LEVEL SECURITY;

-- trusted_contacts policies
DO $$ BEGIN
CREATE POLICY "Users can view household trusted contacts"
    ON trusted_contacts FOR SELECT USING (household_id = public.get_my_household_id());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
CREATE POLICY "Users can insert household trusted contacts"
    ON trusted_contacts FOR INSERT WITH CHECK (household_id = public.get_my_household_id());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
CREATE POLICY "Users can update household trusted contacts"
    ON trusted_contacts FOR UPDATE USING (household_id = public.get_my_household_id());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
CREATE POLICY "Users can delete household trusted contacts"
    ON trusted_contacts FOR DELETE USING (household_id = public.get_my_household_id());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- document_parties policies
DO $$ BEGIN
CREATE POLICY "Users can view household document parties"
    ON document_parties FOR SELECT USING (household_id = public.get_my_household_id());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
CREATE POLICY "Users can insert household document parties"
    ON document_parties FOR INSERT WITH CHECK (household_id = public.get_my_household_id());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
CREATE POLICY "Users can update household document parties"
    ON document_parties FOR UPDATE USING (household_id = public.get_my_household_id());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
CREATE POLICY "Users can delete household document parties"
    ON document_parties FOR DELETE USING (household_id = public.get_my_household_id());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- trusted_contact_documents policies
DO $$ BEGIN
CREATE POLICY "Users can view trusted contact document links"
    ON trusted_contact_documents FOR SELECT
    USING (trusted_contact_id IN (SELECT id FROM trusted_contacts WHERE household_id = public.get_my_household_id()));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
CREATE POLICY "Users can insert trusted contact document links"
    ON trusted_contact_documents FOR INSERT
    WITH CHECK (trusted_contact_id IN (SELECT id FROM trusted_contacts WHERE household_id = public.get_my_household_id()));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
CREATE POLICY "Users can delete trusted contact document links"
    ON trusted_contact_documents FOR DELETE
    USING (trusted_contact_id IN (SELECT id FROM trusted_contacts WHERE household_id = public.get_my_household_id()));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
