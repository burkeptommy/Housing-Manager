-- Phase 84.5 — Free Handyman Assessment + 3-Mode Onboarding
-- =============================================================
-- The "have Chez handle it" path: homeowner signs up, picks Chez-
-- handles-it, and a Chez handyman comes to their home (free) to
-- capture systems / vendors / routines / documents instead of the
-- homeowner doing the quiz themselves.
--
-- Layered on top of:
--   • provider_visit_assignments (Phase 72 — the dispatch row)
--   • handyman_requests (Phase 71 — the homeowner-side request state machine)
--   • provider_workspaces / provider_workspace_members (Phase 72 — the org)
--
-- Phase 84.5 adds:
--   • visit_type discriminator on provider_visit_assignments
--   • home_assessments — per-property workspace where the handyman
--     captures structured data, and where ingestion later reads from
--   • RLS for homeowner-read / handyman-read+update / admin-everything
--
-- The captured_* JSONB columns mirror HouseQuizState shape so the
-- ingestion path can run the same reconciler logic the quiz uses.

-- ============================================================================
-- 1. Visit type discriminator on existing visit assignments
-- ============================================================================

ALTER TABLE public.provider_visit_assignments
    ADD COLUMN IF NOT EXISTS visit_type TEXT NOT NULL DEFAULT 'standard_visit'
    CHECK (visit_type IN ('standard_visit', 'home_assessment', 'inspection', 'follow_up'));

CREATE INDEX IF NOT EXISTS idx_provider_visits_pending_assessment
    ON public.provider_visit_assignments(workspace_id, route_date)
    WHERE visit_type = 'home_assessment';

COMMENT ON COLUMN public.provider_visit_assignments.visit_type IS
    'Phase 84.5 — discriminator. standard_visit (Phase 72 default) / home_assessment (Phase 84.5 onboarding capture) / inspection (future) / follow_up (future).';

-- ============================================================================
-- 2. home_assessments — capture workspace + lifecycle
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.home_assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
    household_id UUID NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,
    visit_assignment_id UUID REFERENCES public.provider_visit_assignments(id) ON DELETE SET NULL,
    handyman_member_id UUID REFERENCES public.provider_workspace_members(id) ON DELETE SET NULL,

    -- Lifecycle: pending → scheduled → en_route → in_progress → submitted →
    -- awaiting_review → completed.  Side branches: corrections_requested
    -- (loops back to scheduled), cancelled (terminal).
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN (
            'pending',                -- homeowner picked Chez-handles-it; no visit dispatched yet
            'scheduled',              -- visit scheduled, awaiting visit day
            'en_route',               -- handyman on the way
            'in_progress',            -- handyman is at the home, capturing
            'submitted',              -- handyman finished + submitted; awaiting ingestion
            'awaiting_review',        -- ingested; homeowner needs to review captured data
            'corrections_requested',  -- homeowner flagged something; revisit needed
            'completed',              -- homeowner approved; assessment fully closed
            'cancelled'               -- homeowner switched to DIY before/during, no-show, etc.
        )),

    -- Captured payload — mirrors HouseQuizState shape so the ingestion
    -- step can run the same reconciler logic the homeowner quiz uses.
    captured_quiz_state JSONB NOT NULL DEFAULT '{}'::jsonb,
    captured_systems JSONB NOT NULL DEFAULT '[]'::jsonb,         -- [{category, manufacturer, model, install_year, photos[], notes}]
    captured_contractors JSONB NOT NULL DEFAULT '[]'::jsonb,     -- [{company_name, category, phone, source: "homeowner_uses"}]
    captured_routines JSONB NOT NULL DEFAULT '[]'::jsonb,        -- [{kind, vendor_name, cadence, day_of_week, active_months}]
    captured_document_paths JSONB NOT NULL DEFAULT '[]'::jsonb,  -- ["assessments/<assessment_id>/<filename>"]
    captured_attributes JSONB NOT NULL DEFAULT '{}'::jsonb,      -- {has_pets, year_built_correction, sq_ft_correction, ...}

    -- Pre-visit prep — what the homeowner pre-filled before the visit
    pre_visit_notes TEXT,
    pre_visit_photos JSONB NOT NULL DEFAULT '[]'::jsonb,         -- ["assessments/<id>/prep/<filename>"]

    -- Lifecycle timestamps
    scheduled_at TIMESTAMPTZ,
    en_route_at TIMESTAMPTZ,
    started_at TIMESTAMPTZ,
    submitted_at TIMESTAMPTZ,
    ingested_at TIMESTAMPTZ,
    reviewed_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    cancellation_reason TEXT,

    -- Reschedule tracking
    reschedule_requested_at TIMESTAMPTZ,
    reschedule_request_notes TEXT,

    -- Notes (separate channels for handyman-side and admin-side)
    handyman_notes TEXT,
    admin_notes TEXT,

    -- Anti-abuse: cost tracking. v1: $0 / 'free' for first assessment per
    -- property; subsequent assessments default to chargeable_cost_cents.
    is_free BOOLEAN NOT NULL DEFAULT true,
    chargeable_cost_cents INTEGER,   -- null when is_free
    payment_status TEXT,             -- null / 'pending' / 'paid' / 'refunded'

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- One in-flight assessment per property (allows historical completed/cancelled rows).
CREATE UNIQUE INDEX IF NOT EXISTS idx_home_assessments_one_active_per_property
    ON public.home_assessments(property_id)
    WHERE status NOT IN ('completed', 'cancelled');

CREATE INDEX IF NOT EXISTS idx_home_assessments_household
    ON public.home_assessments(household_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_home_assessments_status
    ON public.home_assessments(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_home_assessments_handyman
    ON public.home_assessments(handyman_member_id, status);
CREATE INDEX IF NOT EXISTS idx_home_assessments_visit
    ON public.home_assessments(visit_assignment_id);

COMMENT ON TABLE public.home_assessments IS
    'Phase 84.5 — captured-data workspace for the free Chez handyman assessment that replaces the quiz when a homeowner picks "Chez handles it" at signup.';

-- ============================================================================
-- 3. RLS — homeowner reads, handyman reads+updates, admin everything
-- ============================================================================

ALTER TABLE public.home_assessments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members read own household assessments" ON public.home_assessments;
CREATE POLICY "Members read own household assessments"
    ON public.home_assessments FOR SELECT
    USING (household_id IN (SELECT household_id FROM users WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Members update own household assessments" ON public.home_assessments;
CREATE POLICY "Members update own household assessments"
    ON public.home_assessments FOR UPDATE
    USING (household_id IN (SELECT household_id FROM users WHERE id = auth.uid()));

-- The chez-concierge edge function (service role) handles INSERT — no
-- direct insert from the iOS client.  No member INSERT policy.

DROP POLICY IF EXISTS "Admin manages all assessments" ON public.home_assessments;
CREATE POLICY "Admin manages all assessments"
    ON public.home_assessments FOR ALL
    USING (public.is_tom_admin())
    WITH CHECK (public.is_tom_admin());

DROP POLICY IF EXISTS "Handyman reads workspace assessments" ON public.home_assessments;
CREATE POLICY "Handyman reads workspace assessments"
    ON public.home_assessments FOR SELECT
    USING (visit_assignment_id IN (
        SELECT id FROM provider_visit_assignments
         WHERE workspace_id IN (SELECT public.get_my_provider_workspace_ids())
    ));

DROP POLICY IF EXISTS "Handyman updates workspace assessments" ON public.home_assessments;
CREATE POLICY "Handyman updates workspace assessments"
    ON public.home_assessments FOR UPDATE
    USING (visit_assignment_id IN (
        SELECT id FROM provider_visit_assignments
         WHERE workspace_id IN (SELECT public.get_my_provider_workspace_ids())
    ));

-- ============================================================================
-- 4. updated_at trigger
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_home_assessments_updated_at()
    RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_home_assessments_updated_at ON public.home_assessments;
CREATE TRIGGER trg_home_assessments_updated_at
    BEFORE UPDATE ON public.home_assessments
    FOR EACH ROW EXECUTE FUNCTION public.update_home_assessments_updated_at();

-- ============================================================================
-- 5. Waitlist for areas with no handyman coverage
-- ============================================================================
--
-- When a homeowner picks Chez-handles-it but no provider_workspace
-- covers their address, we capture them on a waitlist. They fall
-- through to DIY mode in the meantime.

CREATE TABLE IF NOT EXISTS public.chez_assessment_waitlist (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,
    property_id UUID NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    address_full TEXT,
    state TEXT,
    zip TEXT,
    notified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (property_id)
);

CREATE INDEX IF NOT EXISTS idx_assessment_waitlist_state
    ON public.chez_assessment_waitlist(state, created_at);

ALTER TABLE public.chez_assessment_waitlist ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members read own waitlist row" ON public.chez_assessment_waitlist;
CREATE POLICY "Members read own waitlist row"
    ON public.chez_assessment_waitlist FOR SELECT
    USING (household_id IN (SELECT household_id FROM users WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Admin manages waitlist" ON public.chez_assessment_waitlist;
CREATE POLICY "Admin manages waitlist"
    ON public.chez_assessment_waitlist FOR ALL
    USING (public.is_tom_admin())
    WITH CHECK (public.is_tom_admin());

-- ============================================================================
-- 6. Documentation: properties.attributes['assessment_mode']
-- ============================================================================
--
-- properties.attributes is the existing JSONB column. Phase 84.5 reserves:
--   assessment_mode ∈ {'diy', 'blended', 'handyman'}
--     null/missing = legacy / pre-Phase-84.5 (treat as 'diy' for back-compat)
--     'diy'        = homeowner does the quiz themselves
--     'blended'    = quiz + post-quiz nudge to delegate per category
--     'handyman'   = skip quiz, dispatch a handyman, ingest captured data
--
-- No schema change needed for this — documented here for grep-ability.

-- ============================================================================
-- 7. Convenience view: cockpit upcoming-assessments feed
-- ============================================================================

CREATE OR REPLACE VIEW public.chez_pending_assessments_v AS
SELECT
    a.id AS assessment_id,
    a.household_id,
    a.property_id,
    a.status,
    a.scheduled_at,
    a.en_route_at,
    a.started_at,
    a.submitted_at,
    a.ingested_at,
    a.handyman_member_id,
    a.visit_assignment_id,
    a.created_at,
    h.name AS household_name,
    p.street AS address_line_1,
    p.city,
    p.state,
    p.zip_code,
    pwm.full_name AS handyman_first_name,
    NULL::TEXT AS handyman_last_name,
    pva.route_date,
    pva.window_start_time,
    pva.window_end_time
FROM public.home_assessments a
LEFT JOIN public.households h ON h.id = a.household_id
LEFT JOIN public.properties p ON p.id = a.property_id
LEFT JOIN public.provider_workspace_members pwm ON pwm.id = a.handyman_member_id
LEFT JOIN public.provider_visit_assignments pva ON pva.id = a.visit_assignment_id
WHERE a.status NOT IN ('completed', 'cancelled');

GRANT SELECT ON public.chez_pending_assessments_v TO authenticated;

-- ============================================================================
-- 8. Helper: lookup-or-create assessment for property
-- ============================================================================
--
-- Called by chez-concierge.request_home_assessment.  Idempotent — if an
-- active row already exists for this property, returns it; otherwise
-- creates one.

CREATE OR REPLACE FUNCTION public.find_or_create_home_assessment(
    p_property_id UUID,
    p_household_id UUID
) RETURNS public.home_assessments
    LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_existing public.home_assessments;
    v_new public.home_assessments;
BEGIN
    SELECT * INTO v_existing
        FROM public.home_assessments
        WHERE property_id = p_property_id
          AND status NOT IN ('completed', 'cancelled')
        LIMIT 1;

    IF FOUND THEN
        RETURN v_existing;
    END IF;

    INSERT INTO public.home_assessments (property_id, household_id, status)
        VALUES (p_property_id, p_household_id, 'pending')
        RETURNING * INTO v_new;

    RETURN v_new;
END $$;

GRANT EXECUTE ON FUNCTION public.find_or_create_home_assessment(UUID, UUID) TO service_role;
