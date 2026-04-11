-- Phase 48: Estate PDF export tracking.
-- Each row represents a generated PDF sent (or ready to send) to an attorney.
-- Verification tokens allow public link validation without authentication.
-- Access is capped at max_access_count with full IP-hashed audit logging.

CREATE TABLE IF NOT EXISTS estate_pdf_exports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  generated_by UUID REFERENCES auth.users(id),
  storage_path TEXT NOT NULL,
  verification_token UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
  template_used TEXT NOT NULL, -- 'pre_meeting' | 'annual_review' | 'hybrid'
  max_access_count INTEGER NOT NULL DEFAULT 3,
  access_count INTEGER NOT NULL DEFAULT 0,
  access_log JSONB NOT NULL DEFAULT '[]'::jsonb,
  recipient_email TEXT,
  recipient_name TEXT,
  linked_attorney_contact_id UUID REFERENCES trusted_contacts(id) ON DELETE SET NULL,
  estate_readiness_score INTEGER,
  pdf_content_hash TEXT, -- SHA-256 for verification page
  pdf_sections JSONB,
  expires_at TIMESTAMPTZ NOT NULL,
  revoked_at TIMESTAMPTZ,
  mail_compose_presented_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_estate_pdf_exports_household ON estate_pdf_exports(household_id);
CREATE INDEX idx_estate_pdf_exports_token ON estate_pdf_exports(verification_token);

ALTER TABLE estate_pdf_exports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own household exports"
  ON estate_pdf_exports FOR SELECT
  USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can insert own household exports"
  ON estate_pdf_exports FOR INSERT
  WITH CHECK (household_id = public.get_my_household_id());

CREATE POLICY "Users can update own household exports"
  ON estate_pdf_exports FOR UPDATE
  USING (household_id = public.get_my_household_id());

CREATE POLICY "Service role full access to estate exports"
  ON estate_pdf_exports FOR ALL
  USING (auth.role() = 'service_role');
