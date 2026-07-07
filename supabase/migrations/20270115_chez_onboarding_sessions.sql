-- Wave 2 (Chez service rebuild) — white-glove onboarding visit sessions.
--
-- A tokenized temporary web page (website/onboard.html) lets the operator
-- (Tom first, a handyman later) set up a customer's entire home on-site.
-- The capture store is the EXISTING home_assessments row (captured_*
-- JSONB, Phase 84.5) — this table only carries the scoped access token
-- and session lifecycle. No dispatch machinery: the operator creates the
-- session from the service portal and is the visitor.
CREATE TABLE public.onboarding_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assessment_id UUID NOT NULL REFERENCES public.home_assessments(id) ON DELETE CASCADE,
    household_id UUID NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,
    property_id UUID NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
    token TEXT NOT NULL UNIQUE,
    onboarder_type TEXT NOT NULL DEFAULT 'founder'
        CHECK (onboarder_type IN ('founder', 'handyman')),
    -- Display label for the page header ("Chez home setup"). Homeowner-
    -- facing copy always says Chez; this is operator-side context only.
    onboarder_label TEXT,
    status TEXT NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'completed', 'expired', 'revoked')),
    -- Founder sessions auto-ingest on submit (the operator is both
    -- visitor and reviewer). Handyman sessions park at 'submitted' until
    -- the operator runs ingestion from the portal.
    require_operator_review BOOLEAN NOT NULL DEFAULT false,
    expires_at TIMESTAMPTZ NOT NULL DEFAULT now() + interval '24 hours',
    last_opened_at TIMESTAMPTZ,
    opened_count INT NOT NULL DEFAULT 0,
    -- Per-session cap for the identify-equipment AI proxy.
    identify_call_count INT NOT NULL DEFAULT 0,
    created_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- One live link per assessment. Revoke-then-recreate is the rotation path.
CREATE UNIQUE INDEX idx_onboarding_sessions_active_assessment
    ON public.onboarding_sessions(assessment_id)
    WHERE status = 'active';

CREATE INDEX idx_onboarding_sessions_household
    ON public.onboarding_sessions(household_id);

ALTER TABLE public.onboarding_sessions ENABLE ROW LEVEL SECURITY;

-- Admin-only via the service portal. Token access NEVER goes through
-- client RLS — the chez-onboard edge function validates the token and
-- reads with the service role, scoped to the session's single assessment.
CREATE POLICY onboarding_sessions_admin_all ON public.onboarding_sessions
    FOR ALL
    USING (public.is_tom_admin())
    WITH CHECK (public.is_tom_admin());

COMMENT ON TABLE public.onboarding_sessions IS
    'Tokenized access sessions for the white-glove onboarding web capture page (website/onboard.html). Capture data lives on home_assessments.captured_*; this row only scopes the link.';
