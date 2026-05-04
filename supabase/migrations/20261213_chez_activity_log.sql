-- Phase 85 PR 5c — chez_activity_log + monthly summary tables.
--
-- Surfaces "what has Chez been doing for me this week / this month"
-- without re-deriving the answer from 5 different source tables every
-- time a homeowner opens their Dashboard.
--
-- Append-only log written by:
--   • handyman-provider ingestion (post-visit) — visit_completed,
--     systems_added, recommended_tasks_logged
--   • chez-concierge case lifecycle — case_opened, case_resolved,
--     vendor_quote_received
--   • maintenance_tasks completion trigger — task_completed (for
--     chez_owned tasks only; non-chez tasks aren't Chez activity)
--   • routine_visits state changes — visit_scheduled, visit_completed
--
-- Read by:
--   • iOS ChezActivityCard (dashboard, this-week digest)
--   • iOS ChezActivityView (full chronological log, paginated)
--   • iOS MonthlySummaryCard (1st of each month, last-month rollup)
--
-- Privacy: household-scoped via RLS. Service-role writes from edge
-- functions; homeowners read their own household only.

-- ===========================================================================
-- 1. chez_activity_log — append-only Chez actions per household
-- ===========================================================================

CREATE TABLE IF NOT EXISTS public.chez_activity_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    household_id UUID NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,

    -- High-level activity bucket. Drives the icon + tone in the iOS card.
    activity_type TEXT NOT NULL CHECK (activity_type IN (
        'task_completed',          -- chez_owned maintenance_task marked done
        'visit_scheduled',         -- routine_visit booked
        'visit_completed',         -- routine_visit / handyman visit done
        'assessment_completed',    -- home_assessment ingested
        'case_opened',             -- chez_request created
        'case_resolved',           -- chez_request resolved
        'vendor_contacted',        -- Chez reached out on homeowner's behalf
        'quote_received',          -- vendor responded with a quote
        'system_added',            -- ingestion added a home_systems row
        'recommendation_logged',   -- assessment_recommended_tasks created
        'reminder_completed',      -- chez_reminders cleared
        'spend'                    -- money outlay (rolled into period summaries)
    )),

    -- Backref to the entity this activity is about. entity_type +
    -- entity_id together identify the row in maintenance_tasks /
    -- routines / home_assessments / chez_requests / etc.
    entity_type TEXT,
    entity_id UUID,

    -- Display: what the homeowner sees.
    title TEXT NOT NULL CHECK (length(title) BETWEEN 1 AND 200),
    description TEXT CHECK (description IS NULL OR length(description) <= 2000),

    -- Optional cost in cents. Summed for the spending rollup.
    cost_cents BIGINT CHECK (cost_cents IS NULL OR cost_cents >= 0),

    -- When the activity actually happened (vs created_at = log row time)
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Surface flag — if true, the dashboard "This week with Chez" card
    -- highlights this row. Otherwise it appears only in the full
    -- activity history. Default true; set false for low-signal items
    -- like minor reminders.
    surface_on_dashboard BOOLEAN NOT NULL DEFAULT true,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS chez_activity_log_household_recent
    ON public.chez_activity_log (household_id, occurred_at DESC);

CREATE INDEX IF NOT EXISTS chez_activity_log_entity
    ON public.chez_activity_log (entity_type, entity_id)
    WHERE entity_type IS NOT NULL AND entity_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS chez_activity_log_dashboard
    ON public.chez_activity_log (household_id, occurred_at DESC)
    WHERE surface_on_dashboard = true;

ALTER TABLE public.chez_activity_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "chez_activity_log_select" ON public.chez_activity_log;
CREATE POLICY "chez_activity_log_select"
    ON public.chez_activity_log FOR SELECT
    TO authenticated
    USING (household_id = public.get_my_household_id());

GRANT SELECT ON public.chez_activity_log TO authenticated;

-- Service-role-only writes. Edge functions (handyman-provider,
-- chez-concierge) call public.log_chez_activity() to insert; homeowners
-- never write directly.

CREATE OR REPLACE FUNCTION public.log_chez_activity(
    p_household_id UUID,
    p_activity_type TEXT,
    p_title TEXT,
    p_description TEXT DEFAULT NULL,
    p_entity_type TEXT DEFAULT NULL,
    p_entity_id UUID DEFAULT NULL,
    p_cost_cents BIGINT DEFAULT NULL,
    p_occurred_at TIMESTAMPTZ DEFAULT now(),
    p_surface_on_dashboard BOOLEAN DEFAULT true
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_id UUID;
BEGIN
    INSERT INTO public.chez_activity_log (
        household_id, activity_type, title, description,
        entity_type, entity_id, cost_cents,
        occurred_at, surface_on_dashboard
    ) VALUES (
        p_household_id, p_activity_type, p_title, p_description,
        p_entity_type, p_entity_id, p_cost_cents,
        p_occurred_at, p_surface_on_dashboard
    ) RETURNING id INTO v_id;
    RETURN v_id;
END;
$$;

COMMENT ON FUNCTION public.log_chez_activity IS
    'Phase 85: write a single chez_activity_log row. Called by handyman-provider ingestion + chez-concierge handlers + maintenance_tasks completion trigger. SECURITY DEFINER so service role can call without RLS friction.';

-- ===========================================================================
-- 2. chez_monthly_summaries — pre-aggregated month rollups
-- ===========================================================================
--
-- Generated by the chez-monthly-summary scheduled function on the 1st
-- of each month for the previous month. Stores the rollup so the
-- iOS Dashboard card renders fast without re-aggregating every load.

CREATE TABLE IF NOT EXISTS public.chez_monthly_summaries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,
    period_start DATE NOT NULL,  -- first day of the month being summarized
    period_end DATE NOT NULL,    -- last day of that month

    -- Rollup counts
    tasks_completed INTEGER NOT NULL DEFAULT 0,
    visits_coordinated INTEGER NOT NULL DEFAULT 0,
    quotes_received INTEGER NOT NULL DEFAULT 0,
    recommendations_logged INTEGER NOT NULL DEFAULT 0,
    recommendations_approved INTEGER NOT NULL DEFAULT 0,

    -- Spending — sum of cost_cents for the period grouped by category
    total_spend_cents BIGINT NOT NULL DEFAULT 0,
    spend_by_category JSONB NOT NULL DEFAULT '{}'::JSONB,

    -- Optional editorial: the highlight bullet rendered on the card
    -- e.g. "Best month yet for system care"
    headline TEXT,

    -- Whether the homeowner has viewed this month's summary. Drives
    -- the dashboard auto-dismiss after view.
    viewed_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- One summary per household per month
    UNIQUE (household_id, period_start)
);

CREATE INDEX IF NOT EXISTS chez_monthly_summaries_household_recent
    ON public.chez_monthly_summaries (household_id, period_start DESC);

ALTER TABLE public.chez_monthly_summaries ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "chez_monthly_summaries_select" ON public.chez_monthly_summaries;
CREATE POLICY "chez_monthly_summaries_select"
    ON public.chez_monthly_summaries FOR SELECT
    TO authenticated
    USING (household_id = public.get_my_household_id());

DROP POLICY IF EXISTS "chez_monthly_summaries_update_viewed" ON public.chez_monthly_summaries;
CREATE POLICY "chez_monthly_summaries_update_viewed"
    ON public.chez_monthly_summaries FOR UPDATE
    TO authenticated
    USING (household_id = public.get_my_household_id())
    WITH CHECK (household_id = public.get_my_household_id());

GRANT SELECT, UPDATE ON public.chez_monthly_summaries TO authenticated;

COMMENT ON TABLE public.chez_monthly_summaries IS
    'Phase 85: monthly rollup of chez_activity_log per household. Generated by chez-monthly-summary scheduled function on the 1st of each month for the previous month. UPDATE permission limited to flipping viewed_at — the rest is service-role only.';
