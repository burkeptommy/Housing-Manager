-- Phase 85 PR 5E — workbench action side-effect surfaces.
--
-- The Phase 84 admin Households workbench shipped action buttons
-- (Schedule visit / Log service / Audit bill / etc.) that today only
-- write a `chez_workbench_actions` audit row. PR 5 wires real DB
-- side-effects — most land on existing tables (`routine_visits`,
-- `service_records`, `maintenance_tasks`), but three new surfaces are
-- needed:
--
-- 1. `contractor_engagement_log` — relationship timeline per vendor;
--    drives the vendor focused-detail panel + the future scorecard.
-- 2. `utility_bill_audits` — record of bills Chez audited, with the
--    variance/finding text the homeowner sees on their activity feed.
-- 3. `document_share_log` — when Chez shares a document with a vendor,
--    record the act so the audit trail shows who saw what.
--
-- Plus two new columns on `documents` so we can render "filed by Chez"
-- distinctly from "uploaded by homeowner."

-- =========================================================================
-- 1. Vendor engagement log
-- =========================================================================
CREATE TABLE IF NOT EXISTS public.contractor_engagement_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contractor_id UUID NOT NULL REFERENCES public.contractors(id) ON DELETE CASCADE,
  household_id UUID NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,
  -- Channel matches how Chez engaged: a phone call, an email, a text,
  -- a site visit they attended on the homeowner's behalf, or a
  -- free-form note (when they remembered something about the relationship).
  channel TEXT NOT NULL CHECK (channel IN ('call', 'email', 'text', 'visit', 'note')),
  direction TEXT NOT NULL CHECK (direction IN ('outbound', 'inbound')),
  subject TEXT,
  notes TEXT,
  duration_seconds INT CHECK (duration_seconds IS NULL OR duration_seconds >= 0),
  performed_by_user_id UUID REFERENCES public.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_engagement_contractor
  ON public.contractor_engagement_log(contractor_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_engagement_household
  ON public.contractor_engagement_log(household_id, created_at DESC);

ALTER TABLE public.contractor_engagement_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Members read own household engagement log"
  ON public.contractor_engagement_log FOR SELECT
  USING (household_id IN (SELECT household_id FROM users WHERE id = auth.uid()));
CREATE POLICY "Admin reads all engagement"
  ON public.contractor_engagement_log FOR SELECT
  USING (public.is_tom_admin());
CREATE POLICY "Admin writes engagement"
  ON public.contractor_engagement_log FOR INSERT
  WITH CHECK (public.is_tom_admin());

-- =========================================================================
-- 2. Utility bill audits
-- =========================================================================
CREATE TABLE IF NOT EXISTS public.utility_bill_audits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  utility_account_id UUID NOT NULL REFERENCES public.utility_accounts(id) ON DELETE CASCADE,
  household_id UUID NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,
  bill_period_start DATE,
  bill_period_end DATE,
  bill_amount_cents INT NOT NULL CHECK (bill_amount_cents >= 0),
  prior_amount_cents INT,
  variance_cents INT,
  -- Free-form finding text. Drives the iOS activity feed entry:
  -- "Chez audited your Eversource bill — found $34 overcharge."
  finding TEXT,
  notes TEXT,
  performed_by_user_id UUID REFERENCES public.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_bill_audits_account
  ON public.utility_bill_audits(utility_account_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_bill_audits_household
  ON public.utility_bill_audits(household_id, created_at DESC);

ALTER TABLE public.utility_bill_audits ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Members read own household bill audits"
  ON public.utility_bill_audits FOR SELECT
  USING (household_id IN (SELECT household_id FROM users WHERE id = auth.uid()));
CREATE POLICY "Admin reads all bill audits"
  ON public.utility_bill_audits FOR SELECT
  USING (public.is_tom_admin());
CREATE POLICY "Admin writes bill audits"
  ON public.utility_bill_audits FOR INSERT
  WITH CHECK (public.is_tom_admin());

-- =========================================================================
-- 3. Document filing + sharing
-- =========================================================================
ALTER TABLE public.documents
  ADD COLUMN IF NOT EXISTS chez_filed_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS chez_filed_by_user_id UUID REFERENCES public.users(id);

CREATE INDEX IF NOT EXISTS idx_documents_chez_unfiled
  ON public.documents(household_id, uploaded_at DESC)
  WHERE chez_owned = true AND chez_filed_at IS NULL;

CREATE TABLE IF NOT EXISTS public.document_share_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id UUID NOT NULL REFERENCES public.documents(id) ON DELETE CASCADE,
  household_id UUID NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,
  shared_with_contractor_id UUID REFERENCES public.contractors(id),
  shared_with_email TEXT,
  share_url TEXT,
  expires_at TIMESTAMPTZ,
  -- "filed", "shared", "unfiled" — keeps a single trail for both filing
  -- decisions and outbound shares so the document detail surface can
  -- render one timeline.
  action TEXT NOT NULL CHECK (action IN ('filed', 'shared', 'unfiled')),
  notes TEXT,
  performed_by_user_id UUID REFERENCES public.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_document_share_log_doc
  ON public.document_share_log(document_id, created_at DESC);

ALTER TABLE public.document_share_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Members read own household doc share log"
  ON public.document_share_log FOR SELECT
  USING (household_id IN (SELECT household_id FROM users WHERE id = auth.uid()));
CREATE POLICY "Admin reads all doc shares"
  ON public.document_share_log FOR SELECT
  USING (public.is_tom_admin());
CREATE POLICY "Admin writes doc shares"
  ON public.document_share_log FOR INSERT
  WITH CHECK (public.is_tom_admin());
