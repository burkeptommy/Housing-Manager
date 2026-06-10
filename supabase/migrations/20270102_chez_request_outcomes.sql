-- Phase 100 — Chez Intelligence Foundation, part B: structured case
-- outcomes.
--
-- Every resolved case should produce training data: how it resolved,
-- which vendor won, what it finally cost, how much operator effort it
-- took, and whether the case was automatable. The cockpit's resolve flow
-- prompts a required mini-form (prefilled from visits / proposals / the
-- call ledger) and lands it here via transition_status's new optional
-- outcome payload or the standalone record_outcome action.
--
-- Separate table instead of columns on chez_requests because:
--   - chez_requests is homeowner-readable; operator_minutes and
--     friction_tags are operator-only data
--   - keeps the hot queue table narrow
--   - UNIQUE(request_id) + upsert handles reopen-then-re-resolve cleanly

CREATE TABLE IF NOT EXISTS public.chez_request_outcomes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id UUID NOT NULL UNIQUE REFERENCES public.chez_requests(id) ON DELETE CASCADE,
    household_id UUID NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,
    resolution_type TEXT NOT NULL CHECK (resolution_type IN (
        'completed_via_vendor',   -- vendor sourced or coordinated; work done
        'completed_internal',     -- Chez or handyman handled directly
        'advice_only',            -- answered with information, nothing booked
        'converted_to_standing',  -- became a recurring routine / ownership
        'no_vendor_found',        -- sourcing failed
        'homeowner_cancelled',
        'duplicate_or_merged',
        'no_response',            -- homeowner went dark
        'other'
    )),
    winning_contractor_id UUID REFERENCES public.contractors(id) ON DELETE SET NULL,
    winning_vendor_name TEXT,
    winning_google_place_id TEXT,
    final_cost_cents BIGINT CHECK (final_cost_cents IS NULL OR final_cost_cents >= 0),
    -- Operator quick-pick on the resolve form (5/15/30/60/120). When set
    -- it is authoritative over the chez_case_effort derivation.
    operator_minutes SMALLINT CHECK (operator_minutes IS NULL OR operator_minutes BETWEEN 1 AND 600),
    summary TEXT,
    -- Operator's judgment: could software have closed this case without a
    -- human? The labeled set that decides what to automate first.
    automation_candidate BOOLEAN NOT NULL DEFAULT false,
    -- Quick-pick chips + free-form. Suggested vocabulary:
    -- vendor_no_answer, scheduling_churn, homeowner_slow_reply,
    -- price_pushback, scope_unclear, vendor_no_show, tooling_gap
    friction_tags TEXT[] NOT NULL DEFAULT '{}',
    created_by_user_id UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_chez_outcomes_household
    ON public.chez_request_outcomes(household_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_chez_outcomes_type
    ON public.chez_request_outcomes(resolution_type, created_at DESC);

ALTER TABLE public.chez_request_outcomes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admin manages outcomes" ON public.chez_request_outcomes;
CREATE POLICY "Admin manages outcomes"
    ON public.chez_request_outcomes FOR ALL
    USING (public.is_tom_admin())
    WITH CHECK (public.is_tom_admin());

DROP TRIGGER IF EXISTS chez_request_outcomes_updated_at ON public.chez_request_outcomes;
CREATE TRIGGER chez_request_outcomes_updated_at
    BEFORE UPDATE ON public.chez_request_outcomes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
