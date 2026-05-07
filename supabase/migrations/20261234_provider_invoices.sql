-- Wave Q (Section 8) — Provider invoices skeleton.
-- Closes 8.1 (list), 8.2 (detail), 8.3 (convert quote to invoice), 8.5
-- (itemized invoice), 8.6 (send to homeowner), 8.12 (per-customer invoice
-- history). Stripe integration (8.7-8.9) and full A/R aging (8.11) are
-- deferred to a future phase but the schema is shaped to support them.

CREATE TABLE IF NOT EXISTS public.provider_invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.provider_workspaces(id) ON DELETE CASCADE,
  contractor_id UUID REFERENCES public.contractors(id) ON DELETE SET NULL,
  household_id UUID REFERENCES public.households(id) ON DELETE SET NULL,
  property_id UUID REFERENCES public.properties(id) ON DELETE SET NULL,
  request_id UUID REFERENCES public.handyman_requests(id) ON DELETE SET NULL,
  visit_task_id UUID REFERENCES public.maintenance_tasks(id) ON DELETE SET NULL,
  source_quote_id UUID REFERENCES public.provider_quotes(id) ON DELETE SET NULL,
  invoice_number TEXT NOT NULL,
  title TEXT,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'viewed', 'paid', 'partial', 'overdue', 'void')),
  currency TEXT NOT NULL DEFAULT 'USD',
  line_items JSONB NOT NULL DEFAULT '[]'::jsonb,
  scope_notes TEXT,
  homeowner_message TEXT,
  subtotal NUMERIC(12,2) NOT NULL DEFAULT 0,
  tax_total NUMERIC(12,2) NOT NULL DEFAULT 0,
  total NUMERIC(12,2) NOT NULL DEFAULT 0,
  amount_paid NUMERIC(12,2) NOT NULL DEFAULT 0,
  due_date DATE,
  sent_at TIMESTAMPTZ,
  viewed_at TIMESTAMPTZ,
  paid_at TIMESTAMPTZ,
  voided_at TIMESTAMPTZ,
  created_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS provider_invoices_workspace_idx ON public.provider_invoices (workspace_id);
CREATE INDEX IF NOT EXISTS provider_invoices_household_idx ON public.provider_invoices (household_id);
CREATE INDEX IF NOT EXISTS provider_invoices_status_idx ON public.provider_invoices (status);
CREATE INDEX IF NOT EXISTS provider_invoices_request_idx ON public.provider_invoices (request_id);
CREATE INDEX IF NOT EXISTS provider_invoices_source_quote_idx ON public.provider_invoices (source_quote_id);

-- Workspace+invoice_number is unique so the same workspace can't mint two
-- invoices with the same INV-... number. Cross-workspace collisions are
-- fine because invoice numbers are scoped per provider on customer-facing
-- documents.
CREATE UNIQUE INDEX IF NOT EXISTS provider_invoices_workspace_number_uniq
  ON public.provider_invoices (workspace_id, invoice_number);

ALTER TABLE public.provider_invoices ENABLE ROW LEVEL SECURITY;

-- Workspace members can SELECT/INSERT/UPDATE invoices in their workspace.
DROP POLICY IF EXISTS "Workspace members can read invoices" ON public.provider_invoices;
CREATE POLICY "Workspace members can read invoices"
  ON public.provider_invoices FOR SELECT
  USING (
    workspace_id IN (
      SELECT workspace_id FROM public.provider_workspace_members
      WHERE user_id = auth.uid() AND status = 'active'
    )
  );

DROP POLICY IF EXISTS "Workspace members can insert invoices" ON public.provider_invoices;
CREATE POLICY "Workspace members can insert invoices"
  ON public.provider_invoices FOR INSERT
  WITH CHECK (
    workspace_id IN (
      SELECT workspace_id FROM public.provider_workspace_members
      WHERE user_id = auth.uid() AND status = 'active'
    )
  );

DROP POLICY IF EXISTS "Workspace members can update invoices" ON public.provider_invoices;
CREATE POLICY "Workspace members can update invoices"
  ON public.provider_invoices FOR UPDATE
  USING (
    workspace_id IN (
      SELECT workspace_id FROM public.provider_workspace_members
      WHERE user_id = auth.uid() AND status = 'active'
    )
  );

-- Homeowners can SELECT invoices for their household so the iOS app and
-- the public-share page can render them.
DROP POLICY IF EXISTS "Homeowners can read their invoices" ON public.provider_invoices;
CREATE POLICY "Homeowners can read their invoices"
  ON public.provider_invoices FOR SELECT
  USING (
    household_id IN (
      SELECT household_id FROM public.users WHERE id = auth.uid()
    )
  );
