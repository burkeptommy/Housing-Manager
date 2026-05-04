-- Haven Database Schema
-- Phase 3: Supabase Backend
-- Run this in the Supabase SQL Editor to set up the full schema.

-- ============================================================================
-- TABLES
-- ============================================================================

-- Households (a family unit — the top-level entity)
CREATE TABLE households (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    subscription_tier TEXT DEFAULT 'standard',
    subscription_expires_at TIMESTAMPTZ
);

-- Users (people who can log in and access a household)
CREATE TABLE users (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    household_id UUID REFERENCES households(id),
    email TEXT NOT NULL,
    full_name TEXT,
    role TEXT NOT NULL DEFAULT 'member',  -- 'admin' (service operator), 'member' (client family)
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Family Members (people in the household, not necessarily app users)
CREATE TABLE family_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID REFERENCES households(id) NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    relationship TEXT NOT NULL,
    date_of_birth DATE,
    email TEXT,
    phone TEXT,
    is_minor BOOLEAN DEFAULT false,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Properties
CREATE TABLE properties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID REFERENCES households(id) NOT NULL,
    name TEXT NOT NULL,
    property_type TEXT NOT NULL,
    street TEXT,
    unit TEXT,
    city TEXT,
    state TEXT,
    zip_code TEXT,
    country TEXT DEFAULT 'US',
    purchase_date DATE,
    purchase_price DECIMAL,
    current_estimated_value DECIMAL,
    square_footage INT,
    year_built INT,
    ownership_entity TEXT,
    notes TEXT,
    attributes JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Service Contracts (recurring services: pest control, landscaping, pool, cleaning)
CREATE TABLE service_contracts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID REFERENCES properties(id) ON DELETE CASCADE NOT NULL,
    household_id UUID REFERENCES households(id) NOT NULL,
    service_type TEXT NOT NULL,
    provider_name TEXT,
    contractor_id UUID REFERENCES contractors(id) ON DELETE SET NULL,
    frequency TEXT,
    details JSONB DEFAULT '{}',
    annual_cost DECIMAL,
    start_date DATE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Documents
CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID REFERENCES households(id) NOT NULL,
    title TEXT NOT NULL,
    category TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'active',
    file_path TEXT NOT NULL,
    thumbnail_path TEXT,
    expiration_date DATE,
    renewal_date DATE,
    effective_date DATE,
    issuing_institution TEXT,
    account_number_last4 TEXT,
    notes TEXT,
    tags TEXT[],
    ai_summary TEXT,
    ai_flags JSONB DEFAULT '[]',
    linked_document_ids UUID[],
    property_id UUID REFERENCES properties(id),
    uploaded_at TIMESTAMPTZ DEFAULT now(),
    last_reviewed_at TIMESTAMPTZ,
    metadata JSONB DEFAULT '{}',
    vault_locked BOOLEAN DEFAULT false,
    vault_lock_iv TEXT,
    content_hash TEXT,
    file_size BIGINT,
    visible_to_home_managers BOOLEAN NOT NULL DEFAULT true
);

-- Document-FamilyMember junction
CREATE TABLE document_family_members (
    document_id UUID REFERENCES documents(id) ON DELETE CASCADE,
    family_member_id UUID REFERENCES family_members(id) ON DELETE CASCADE,
    PRIMARY KEY (document_id, family_member_id)
);

-- Home Systems
CREATE TABLE home_systems (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID REFERENCES properties(id) ON DELETE CASCADE NOT NULL,
    household_id UUID REFERENCES households(id) NOT NULL,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    manufacturer TEXT,
    model_number TEXT,
    serial_number TEXT,
    install_date DATE,
    expected_lifespan_years INT,
    status TEXT DEFAULT 'good',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Warranties
CREATE TABLE warranties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    system_id UUID REFERENCES home_systems(id) ON DELETE CASCADE,
    household_id UUID REFERENCES households(id) NOT NULL,
    provider TEXT NOT NULL,
    warranty_type TEXT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    coverage_details TEXT,
    claim_phone TEXT,
    policy_number TEXT,
    linked_document_id UUID REFERENCES documents(id),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Contractors
CREATE TABLE contractors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID REFERENCES households(id) NOT NULL,
    company_name TEXT NOT NULL,
    contact_name TEXT,
    phone TEXT NOT NULL,
    email TEXT,
    specialties TEXT[],
    address TEXT,
    license_number TEXT,
    insurance_verified BOOLEAN DEFAULT false,
    rating INT CHECK (rating >= 1 AND rating <= 5),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Maintenance Tasks
CREATE TABLE maintenance_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    system_id UUID REFERENCES home_systems(id) ON DELETE CASCADE,
    property_id UUID REFERENCES properties(id) NOT NULL,
    household_id UUID REFERENCES households(id) NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    frequency TEXT NOT NULL,
    last_completed_date DATE,
    next_due_date DATE NOT NULL,
    estimated_cost DECIMAL,
    priority TEXT DEFAULT 'medium',
    assigned_contractor_id UUID REFERENCES contractors(id),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Service Records
CREATE TABLE service_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    system_id UUID REFERENCES home_systems(id) ON DELETE CASCADE,
    property_id UUID REFERENCES properties(id) NOT NULL,
    household_id UUID REFERENCES households(id) NOT NULL,
    contractor_id UUID REFERENCES contractors(id),
    service_date DATE NOT NULL,
    service_type TEXT NOT NULL,
    description TEXT NOT NULL,
    cost DECIMAL,
    invoice_document_id UUID REFERENCES documents(id),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- AI Chat History
CREATE TABLE chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID REFERENCES households(id) NOT NULL,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    role TEXT NOT NULL,                   -- 'user' or 'assistant'
    content TEXT NOT NULL,
    context_type TEXT,                    -- 'general', 'document', 'property', 'maintenance'
    context_id UUID,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Access Log (immutable, append-only audit trail)
CREATE TABLE access_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID REFERENCES households(id) NOT NULL,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,  -- NULL for system/AI actions
    action TEXT NOT NULL,
    resource_type TEXT NOT NULL,                  -- 'document', 'property', 'system', 'chat'
    resource_id UUID,
    resource_name TEXT,
    actor_type TEXT NOT NULL DEFAULT 'user',      -- 'user', 'system', 'ai_analysis', 'admin'
    ip_address TEXT,
    device_info TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Document Content (extracted text for AI queries)
CREATE TABLE document_content (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID REFERENCES documents(id) ON DELETE CASCADE NOT NULL,
    household_id UUID REFERENCES households(id) NOT NULL,
    extracted_text TEXT NOT NULL,
    extraction_method TEXT DEFAULT 'ocr',
    extracted_at TIMESTAMPTZ DEFAULT now(),
    last_ai_analysis_at TIMESTAMPTZ,
    ai_model_version TEXT
);

-- Completion Scorecard
CREATE TABLE completion_scores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID REFERENCES households(id) NOT NULL,
    category TEXT NOT NULL,
    expected_count INT DEFAULT 0,
    actual_count INT DEFAULT 0,
    completion_percentage DECIMAL DEFAULT 0,
    last_calculated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(household_id, category)
);

-- Analytics Events (product analytics — all user interactions)
CREATE TABLE analytics_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    household_id UUID,
    event_name TEXT NOT NULL,
    screen_name TEXT,
    properties JSONB DEFAULT '{}',
    device_model TEXT,
    os_version TEXT,
    app_version TEXT,
    build_number TEXT,
    session_id TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- INDEXES (performance on household_id lookups)
-- ============================================================================

CREATE INDEX idx_users_household ON users(household_id);
CREATE INDEX idx_family_members_household ON family_members(household_id);
CREATE INDEX idx_documents_household ON documents(household_id);
CREATE INDEX idx_documents_category ON documents(household_id, category);
CREATE INDEX idx_documents_status ON documents(household_id, status);
CREATE INDEX idx_properties_household ON properties(household_id);
CREATE INDEX idx_home_systems_household ON home_systems(household_id);
CREATE INDEX idx_home_systems_property ON home_systems(property_id);
CREATE INDEX idx_warranties_household ON warranties(household_id);
CREATE INDEX idx_warranties_system ON warranties(system_id);
CREATE INDEX idx_contractors_household ON contractors(household_id);
CREATE INDEX idx_maintenance_tasks_household ON maintenance_tasks(household_id);
CREATE INDEX idx_maintenance_tasks_property ON maintenance_tasks(property_id);
CREATE INDEX idx_maintenance_tasks_due ON maintenance_tasks(household_id, next_due_date);
CREATE INDEX idx_service_records_household ON service_records(household_id);
CREATE INDEX idx_service_records_system ON service_records(system_id);
CREATE INDEX idx_chat_messages_household ON chat_messages(household_id, user_id);
CREATE INDEX idx_chat_messages_created ON chat_messages(household_id, created_at DESC);
CREATE INDEX idx_access_log_household_created ON access_log(household_id, created_at DESC);
CREATE INDEX idx_access_log_resource ON access_log(resource_type, resource_id);
CREATE INDEX idx_document_content_household ON document_content(household_id);
CREATE INDEX idx_document_content_document ON document_content(document_id);
CREATE INDEX idx_completion_scores_household ON completion_scores(household_id);
CREATE INDEX idx_analytics_events_user ON analytics_events(user_id, created_at DESC);
CREATE INDEX idx_analytics_events_household ON analytics_events(household_id, created_at DESC);
CREATE INDEX idx_analytics_events_name ON analytics_events(event_name, created_at DESC);
CREATE INDEX idx_analytics_events_screen ON analytics_events(screen_name, created_at DESC);
CREATE INDEX idx_analytics_events_session ON analytics_events(session_id);
CREATE INDEX idx_analytics_events_created ON analytics_events(created_at DESC);

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE households ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_family_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE home_systems ENABLE ROW LEVEL SECURITY;
ALTER TABLE warranties ENABLE ROW LEVEL SECURITY;
ALTER TABLE contractors ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE completion_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE access_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_content ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- RLS HELPER FUNCTION
-- ============================================================================

-- SECURITY DEFINER function that bypasses RLS to look up the current user's
-- household_id.  This avoids infinite recursion when used in policies on the
-- users table itself, and is more efficient than a repeated sub-query.
CREATE OR REPLACE FUNCTION public.get_my_household_id()
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT household_id FROM public.users WHERE id = auth.uid()
$$;

-- SECURITY DEFINER function for cross-household email lookups. Used by the
-- invite flow to check whether an invitee already has a Haven account without
-- exposing the full users table to the caller's RLS scope.
CREATE OR REPLACE FUNCTION public.check_user_exists_by_email(target_email text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
DECLARE
    found_id uuid;
    found_household_id uuid;
BEGIN
    SELECT au.id INTO found_id
    FROM auth.users au
    WHERE au.email = lower(trim(target_email))
    LIMIT 1;

    IF found_id IS NOT NULL THEN
        SELECT u.household_id INTO found_household_id
        FROM public.users u
        WHERE u.id = found_id;
        RETURN jsonb_build_object(
            'exists', true,
            'user_id', found_id,
            'household_id', found_household_id
        );
    END IF;

    SELECT u.id, u.household_id INTO found_id, found_household_id
    FROM public.users u
    WHERE u.email = lower(trim(target_email))
    LIMIT 1;

    IF found_id IS NOT NULL THEN
        RETURN jsonb_build_object(
            'exists', true,
            'user_id', found_id,
            'household_id', found_household_id
        );
    END IF;

    RETURN jsonb_build_object('exists', false);
END;
$$;

GRANT EXECUTE ON FUNCTION public.check_user_exists_by_email(text) TO authenticated;

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- households
-- ----------------------------------------------------------------------------
CREATE POLICY "Users can view own household"
    ON households FOR SELECT
    USING (id = public.get_my_household_id());

CREATE POLICY "Users can update own household"
    ON households FOR UPDATE
    USING (id = public.get_my_household_id());

-- Allow insert during onboarding (user creates household before user row exists)
CREATE POLICY "Authenticated users can create households"
    ON households FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

-- ----------------------------------------------------------------------------
-- users
-- ----------------------------------------------------------------------------
CREATE POLICY "Users can view own profile"
    ON users FOR SELECT
    USING (id = auth.uid());

CREATE POLICY "Users can view household members"
    ON users FOR SELECT
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can insert own profile"
    ON users FOR INSERT
    WITH CHECK (id = auth.uid());

CREATE POLICY "Users can update own profile"
    ON users FOR UPDATE
    USING (id = auth.uid());

-- ----------------------------------------------------------------------------
-- family_members
-- ----------------------------------------------------------------------------
CREATE POLICY "Users can view household family members"
    ON family_members FOR SELECT
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can insert household family members"
    ON family_members FOR INSERT
    WITH CHECK (household_id = public.get_my_household_id());

CREATE POLICY "Users can update household family members"
    ON family_members FOR UPDATE
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can delete household family members"
    ON family_members FOR DELETE
    USING (household_id = public.get_my_household_id());

-- ----------------------------------------------------------------------------
-- documents
-- ----------------------------------------------------------------------------
CREATE POLICY "household_documents_select"
    ON documents FOR SELECT
    USING (
        household_id = public.get_my_household_id()
        AND (
            visible_to_home_managers = true
            OR NOT EXISTS (
                SELECT 1 FROM family_members
                WHERE family_members.linked_user_id = auth.uid()
                  AND family_members.member_type IN ('home_manager', 'staff')
            )
        )
    );

-- Phase 95 / gap #57: home-manager-aware INSERT/UPDATE/DELETE.
-- Staff (member_type IN ('home_manager', 'staff')) can only modify
-- or delete documents already visible to them, and cannot insert
-- new ones with visible_to_home_managers = false (hiding work from
-- the homeowner). Family members and unlinked users on the
-- household are unaffected.
CREATE POLICY "household_documents_insert"
    ON documents FOR INSERT
    WITH CHECK (
        household_id = public.get_my_household_id()
        AND (
            NOT EXISTS (
                SELECT 1 FROM family_members
                WHERE family_members.linked_user_id = auth.uid()
                  AND family_members.member_type IN ('home_manager', 'staff')
            )
            OR COALESCE(visible_to_home_managers, true) = true
        )
    );

CREATE POLICY "household_documents_update"
    ON documents FOR UPDATE
    USING (
        household_id = public.get_my_household_id()
        AND (
            visible_to_home_managers = true
            OR NOT EXISTS (
                SELECT 1 FROM family_members
                WHERE family_members.linked_user_id = auth.uid()
                  AND family_members.member_type IN ('home_manager', 'staff')
            )
        )
    );

CREATE POLICY "household_documents_delete"
    ON documents FOR DELETE
    USING (
        household_id = public.get_my_household_id()
        AND (
            visible_to_home_managers = true
            OR NOT EXISTS (
                SELECT 1 FROM family_members
                WHERE family_members.linked_user_id = auth.uid()
                  AND family_members.member_type IN ('home_manager', 'staff')
            )
        )
    );

-- ----------------------------------------------------------------------------
-- document_family_members (junction table — access via document's household)
-- ----------------------------------------------------------------------------
CREATE POLICY "Users can view document-member links"
    ON document_family_members FOR SELECT
    USING (document_id IN (
        SELECT id FROM documents WHERE household_id = public.get_my_household_id()
    ));

CREATE POLICY "Users can insert document-member links"
    ON document_family_members FOR INSERT
    WITH CHECK (document_id IN (
        SELECT id FROM documents WHERE household_id = public.get_my_household_id()
    ));

CREATE POLICY "Users can delete document-member links"
    ON document_family_members FOR DELETE
    USING (document_id IN (
        SELECT id FROM documents WHERE household_id = public.get_my_household_id()
    ));

-- ----------------------------------------------------------------------------
-- properties
-- ----------------------------------------------------------------------------
CREATE POLICY "Users can view household properties"
    ON properties FOR SELECT
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can insert household properties"
    ON properties FOR INSERT
    WITH CHECK (household_id = public.get_my_household_id());

CREATE POLICY "Users can update household properties"
    ON properties FOR UPDATE
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can delete household properties"
    ON properties FOR DELETE
    USING (household_id = public.get_my_household_id());

ALTER TABLE service_contracts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view household service contracts"
    ON service_contracts FOR SELECT
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can insert household service contracts"
    ON service_contracts FOR INSERT
    WITH CHECK (household_id = public.get_my_household_id());

CREATE POLICY "Users can update household service contracts"
    ON service_contracts FOR UPDATE
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can delete household service contracts"
    ON service_contracts FOR DELETE
    USING (household_id = public.get_my_household_id());

-- ----------------------------------------------------------------------------
-- home_systems
-- ----------------------------------------------------------------------------
CREATE POLICY "Users can view household systems"
    ON home_systems FOR SELECT
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can insert household systems"
    ON home_systems FOR INSERT
    WITH CHECK (household_id = public.get_my_household_id());

CREATE POLICY "Users can update household systems"
    ON home_systems FOR UPDATE
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can delete household systems"
    ON home_systems FOR DELETE
    USING (household_id = public.get_my_household_id());

-- ----------------------------------------------------------------------------
-- warranties
-- ----------------------------------------------------------------------------
CREATE POLICY "Users can view household warranties"
    ON warranties FOR SELECT
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can insert household warranties"
    ON warranties FOR INSERT
    WITH CHECK (household_id = public.get_my_household_id());

CREATE POLICY "Users can update household warranties"
    ON warranties FOR UPDATE
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can delete household warranties"
    ON warranties FOR DELETE
    USING (household_id = public.get_my_household_id());

-- ----------------------------------------------------------------------------
-- contractors
-- ----------------------------------------------------------------------------
CREATE POLICY "Users can view household contractors"
    ON contractors FOR SELECT
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can insert household contractors"
    ON contractors FOR INSERT
    WITH CHECK (household_id = public.get_my_household_id());

CREATE POLICY "Users can update household contractors"
    ON contractors FOR UPDATE
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can delete household contractors"
    ON contractors FOR DELETE
    USING (household_id = public.get_my_household_id());

-- ----------------------------------------------------------------------------
-- maintenance_tasks
-- ----------------------------------------------------------------------------
CREATE POLICY "Users can view household maintenance tasks"
    ON maintenance_tasks FOR SELECT
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can insert household maintenance tasks"
    ON maintenance_tasks FOR INSERT
    WITH CHECK (household_id = public.get_my_household_id());

CREATE POLICY "Users can update household maintenance tasks"
    ON maintenance_tasks FOR UPDATE
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can delete household maintenance tasks"
    ON maintenance_tasks FOR DELETE
    USING (household_id = public.get_my_household_id());

-- ----------------------------------------------------------------------------
-- service_records
-- ----------------------------------------------------------------------------
CREATE POLICY "Users can view household service records"
    ON service_records FOR SELECT
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can insert household service records"
    ON service_records FOR INSERT
    WITH CHECK (household_id = public.get_my_household_id());

CREATE POLICY "Users can update household service records"
    ON service_records FOR UPDATE
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can delete household service records"
    ON service_records FOR DELETE
    USING (household_id = public.get_my_household_id());

-- ----------------------------------------------------------------------------
-- chat_messages
-- ----------------------------------------------------------------------------
CREATE POLICY "Users can view own chat messages"
    ON chat_messages FOR SELECT
    USING (
        household_id = public.get_my_household_id()
        AND user_id = auth.uid()
    );

CREATE POLICY "Users can insert own chat messages"
    ON chat_messages FOR INSERT
    WITH CHECK (
        household_id = public.get_my_household_id()
        AND user_id = auth.uid()
    );

-- ----------------------------------------------------------------------------
-- completion_scores
-- ----------------------------------------------------------------------------
CREATE POLICY "Users can view household completion scores"
    ON completion_scores FOR SELECT
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can insert household completion scores"
    ON completion_scores FOR INSERT
    WITH CHECK (household_id = public.get_my_household_id());

CREATE POLICY "Users can update household completion scores"
    ON completion_scores FOR UPDATE
    USING (household_id = public.get_my_household_id());

-- ----------------------------------------------------------------------------
-- access_log (immutable — SELECT and INSERT only, no UPDATE or DELETE)
-- ----------------------------------------------------------------------------
CREATE POLICY "Users can view own household access logs"
    ON access_log FOR SELECT
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Edge functions can insert access logs"
    ON access_log FOR INSERT
    WITH CHECK (true);

-- ----------------------------------------------------------------------------
-- document_content
-- ----------------------------------------------------------------------------
CREATE POLICY "Household members can view own content"
    ON document_content FOR SELECT
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Edge functions can insert document content"
    ON document_content FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Edge functions can update document content"
    ON document_content FOR UPDATE
    USING (true);

-- ----------------------------------------------------------------------------
-- analytics_events (INSERT only for clients, SELECT for service role)
-- ----------------------------------------------------------------------------
CREATE POLICY "Users can insert own analytics events"
    ON analytics_events FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Service role can read all analytics"
    ON analytics_events FOR SELECT
    USING (auth.jwt() ->> 'role' = 'service_role');
