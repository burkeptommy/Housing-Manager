-- Phase 100 — Chez Intelligence Foundation, part A: persist the vendor
-- call ledger.
--
-- The cockpit's per-candidate call form (outcome / notes / availability
-- slots / cost / recommended flag) lived only in browser memory
-- (state.chezVendorCallsByRequest in admin.js). A refresh lost every
-- logged call, and losing candidates (vendors called who didn't fit)
-- never persisted anywhere. That data is the seed of the cross-household
-- vendor intelligence registry: who answers, what they quote, who fits.
--
-- One row per (request, candidate). candidate_key is the cockpit's
-- vendorCandidateKey(v) verbatim ("existing:<contractor uuid>" or
-- "places:<name>") so hydration is a trivial reduce back into UI state.
-- Identity columns (google_place_id, phone, name+town) are stamped
-- best-effort at save time so the registry view can aggregate across
-- households even for candidates that never became contractors.

CREATE TABLE IF NOT EXISTS public.chez_vendor_calls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id UUID NOT NULL REFERENCES public.chez_requests(id) ON DELETE CASCADE,
    household_id UUID NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,
    candidate_key TEXT NOT NULL,
    source TEXT NOT NULL DEFAULT 'places' CHECK (source IN ('existing', 'places', 'manual')),

    -- Identity for cross-household aggregation (best-effort at save time).
    contractor_id UUID REFERENCES public.contractors(id) ON DELETE SET NULL,
    google_place_id TEXT,
    vendor_name TEXT,
    vendor_phone TEXT,
    vendor_email TEXT,
    category TEXT,
    town TEXT,
    state TEXT,

    -- The editable call-form fields. Names match the cockpit state object
    -- 1:1 (admin.js [data-vendor-field] handlers) so hydration/persist is
    -- a straight copy.
    outcome TEXT CHECK (outcome IS NULL OR outcome IN ('answered', 'no_answer', 'not_a_fit')),
    notes TEXT,
    rationale TEXT,
    recommended BOOLEAN NOT NULL DEFAULT false,
    availability_slots JSONB NOT NULL DEFAULT '[]'::jsonb,
    cost_range TEXT,
    cost_custom TEXT,
    -- Server-parsed midpoint of cost_custom / cost_range when a number is
    -- recoverable. Powers avg_quoted_cost in the registry without making
    -- the operator do data entry twice.
    quoted_cost_cents BIGINT CHECK (quoted_cost_cents IS NULL OR quoted_cost_cents >= 0),

    first_called_at TIMESTAMPTZ,
    last_called_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (request_id, candidate_key)
);

CREATE INDEX IF NOT EXISTS idx_chez_vendor_calls_request
    ON public.chez_vendor_calls(request_id);
CREATE INDEX IF NOT EXISTS idx_chez_vendor_calls_household
    ON public.chez_vendor_calls(household_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_chez_vendor_calls_place
    ON public.chez_vendor_calls(google_place_id)
    WHERE google_place_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_chez_vendor_calls_phone
    ON public.chez_vendor_calls((regexp_replace(coalesce(vendor_phone, ''), '\D', '', 'g')))
    WHERE vendor_phone IS NOT NULL;

ALTER TABLE public.chez_vendor_calls ENABLE ROW LEVEL SECURITY;

-- Operator-only on purpose. Losing-candidate notes and quoted costs are
-- cross-household operational intelligence plus operator scratchpad,
-- never homeowner-visible. Homeowners see the polished proposal cards
-- in concierge_messages instead.
DROP POLICY IF EXISTS "Admin manages vendor calls" ON public.chez_vendor_calls;
CREATE POLICY "Admin manages vendor calls"
    ON public.chez_vendor_calls FOR ALL
    USING (public.is_tom_admin())
    WITH CHECK (public.is_tom_admin());

DROP TRIGGER IF EXISTS chez_vendor_calls_updated_at ON public.chez_vendor_calls;
CREATE TRIGGER chez_vendor_calls_updated_at
    BEFORE UPDATE ON public.chez_vendor_calls
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
