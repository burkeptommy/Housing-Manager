-- Phase 8, Step 1: Create access_log and document_content tables
-- Zero-access security model — immutable audit log + extracted text for AI

-- ============================================================================
-- ACCESS LOG — Immutable, append-only audit trail
-- ============================================================================

CREATE TABLE access_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID REFERENCES households(id) NOT NULL,
    user_id UUID REFERENCES users(id),          -- NULL for system/AI actions
    action TEXT NOT NULL,                         -- e.g. document_uploaded, document_viewed
    resource_type TEXT NOT NULL,                  -- 'document', 'property', 'system', 'chat'
    resource_id UUID,                             -- ID of the accessed resource
    resource_name TEXT,                           -- Human-readable name for display
    actor_type TEXT NOT NULL DEFAULT 'user',      -- 'user', 'system', 'ai_analysis', 'admin'
    ip_address TEXT,
    device_info TEXT,                             -- iOS device model + OS version
    metadata JSONB DEFAULT '{}',                  -- Additional context
    created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE access_log ENABLE ROW LEVEL SECURITY;

-- Users can only READ their own household's logs. Nobody can UPDATE or DELETE.
CREATE POLICY "Users can view own household access logs"
    ON access_log FOR SELECT
    USING (household_id = public.get_my_household_id());

-- Edge Functions (and service role) can insert logs
CREATE POLICY "Edge functions can insert access logs"
    ON access_log FOR INSERT
    WITH CHECK (true);

-- NO update or delete policies. Logs are immutable.

CREATE INDEX idx_access_log_household_created ON access_log(household_id, created_at DESC);
CREATE INDEX idx_access_log_resource ON access_log(resource_type, resource_id);

-- ============================================================================
-- DOCUMENT CONTENT — Extracted text for AI queries
-- ============================================================================

CREATE TABLE document_content (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID REFERENCES documents(id) ON DELETE CASCADE NOT NULL,
    household_id UUID REFERENCES households(id) NOT NULL,
    extracted_text TEXT NOT NULL,              -- Full OCR/text extraction
    extraction_method TEXT DEFAULT 'ocr',     -- 'ocr', 'text_extraction', 'manual'
    extracted_at TIMESTAMPTZ DEFAULT now(),
    last_ai_analysis_at TIMESTAMPTZ,
    ai_model_version TEXT                     -- Track which Claude version analyzed it
);

ALTER TABLE document_content ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Household members can view own content"
    ON document_content FOR SELECT
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Edge functions can insert document content"
    ON document_content FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Edge functions can update document content"
    ON document_content FOR UPDATE
    USING (true);

CREATE INDEX idx_document_content_household ON document_content(household_id);
CREATE INDEX idx_document_content_document ON document_content(document_id);
