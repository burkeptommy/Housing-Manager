-- Phase 85 PR 3 — Trust display.
--
-- HNW homeowners need to know who's coming to their house before the
-- handyman arrives: name, photo, license, insurance, years in business,
-- specialties, prior ratings. The Phase 84.5 HomeAssessmentPendingCard
-- already has slots for these fields wired as nil placeholders; this
-- migration adds the underlying columns + a handyman_reviews table so
-- the iOS PreVisitTrustCard + post-visit RateHandymanSheet have real
-- data to read/write.
--
-- All credential-verification timestamps are admin-set (Tom in the
-- admin portal), never self-set by the handyman. Profile content
-- fields (bio, photo, specialties) ARE self-editable via the
-- operations SPA's HandymanProfile screen.

-- ===========================================================================
-- 1. Profile fields on provider_workspace_members
-- ===========================================================================

ALTER TABLE public.provider_workspace_members
    ADD COLUMN IF NOT EXISTS display_name TEXT
        CHECK (display_name IS NULL OR length(display_name) BETWEEN 1 AND 100),
    ADD COLUMN IF NOT EXISTS bio TEXT
        CHECK (bio IS NULL OR length(bio) <= 500),
    ADD COLUMN IF NOT EXISTS photo_url TEXT
        CHECK (photo_url IS NULL OR length(photo_url) <= 1000),
    ADD COLUMN IF NOT EXISTS years_in_business INTEGER
        CHECK (years_in_business IS NULL OR years_in_business BETWEEN 0 AND 100),
    ADD COLUMN IF NOT EXISTS specialties TEXT[] NOT NULL DEFAULT '{}'::TEXT[],
    ADD COLUMN IF NOT EXISTS license_number TEXT
        CHECK (license_number IS NULL OR length(license_number) BETWEEN 1 AND 100),
    ADD COLUMN IF NOT EXISTS license_state TEXT
        CHECK (license_state IS NULL OR license_state ~ '^[A-Z]{2}$'),
    ADD COLUMN IF NOT EXISTS license_verified_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS insurance_carrier TEXT
        CHECK (insurance_carrier IS NULL OR length(insurance_carrier) BETWEEN 1 AND 200),
    ADD COLUMN IF NOT EXISTS insurance_policy_number TEXT
        CHECK (insurance_policy_number IS NULL OR length(insurance_policy_number) BETWEEN 1 AND 100),
    ADD COLUMN IF NOT EXISTS insurance_expiry DATE,
    ADD COLUMN IF NOT EXISTS insurance_verified_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS background_check_completed_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS background_check_provider TEXT
        CHECK (background_check_provider IS NULL OR length(background_check_provider) <= 100),
    ADD COLUMN IF NOT EXISTS vehicle_photo_url TEXT
        CHECK (vehicle_photo_url IS NULL OR length(vehicle_photo_url) <= 1000),
    -- Phase 85 dispatch: default-assignee flag for the workspace.
    -- Sole-prop workspaces get this set on the signup user automatically;
    -- adding a second member triggers the operations SPA's
    -- "Should this user be the default assignee?" prompt.
    ADD COLUMN IF NOT EXISTS is_default_assignee BOOLEAN NOT NULL DEFAULT false;

-- One default assignee per workspace
CREATE UNIQUE INDEX IF NOT EXISTS provider_workspace_members_one_default
    ON public.provider_workspace_members (workspace_id)
    WHERE is_default_assignee = true;

COMMENT ON COLUMN public.provider_workspace_members.display_name IS
    'Phase 85: full name as homeowner sees it on the iOS PreVisitTrustCard. Defaults nil; user fills via the operations SPA HandymanProfile screen.';
COMMENT ON COLUMN public.provider_workspace_members.license_verified_at IS
    'Phase 85: admin-set only. Tom verifies in the admin portal Handyman Profiles surface; the handyman cannot self-verify their own license.';
COMMENT ON COLUMN public.provider_workspace_members.insurance_verified_at IS
    'Phase 85: admin-set only. Same pattern as license_verified_at.';
COMMENT ON COLUMN public.provider_workspace_members.background_check_completed_at IS
    'Phase 85: admin-set only. Tom records the check completion + provider name (Checkr / Sterling / etc.) after running it.';
COMMENT ON COLUMN public.provider_workspace_members.is_default_assignee IS
    'Phase 85 dispatch: when true, this member is auto-assigned to new home_assessments dispatched to this workspace. One per workspace, enforced by partial unique index.';

-- ===========================================================================
-- 2. handyman_reviews
-- ===========================================================================
--
-- Homeowner-submitted rating + review after a completed home_assessment
-- visit. Aggregated to the handyman's profile (avg rating + review
-- count) for future homeowners' trust display.

CREATE TABLE IF NOT EXISTS public.handyman_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    handyman_member_id UUID NOT NULL REFERENCES public.provider_workspace_members(id) ON DELETE CASCADE,
    -- Optional FK to the assessment the review is about. Nullable so
    -- non-assessment reviews (e.g. follow-up visits) can also surface.
    assessment_id UUID REFERENCES public.home_assessments(id) ON DELETE SET NULL,
    homeowner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    household_id UUID NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,

    rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    review_text TEXT CHECK (review_text IS NULL OR length(review_text) <= 2000),

    -- Optional structured tags ("on time", "professional", "cleaned up",
    -- "found extra issues") — easier for homeowners than free text.
    tags TEXT[] NOT NULL DEFAULT '{}'::TEXT[],

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- One review per (assessment, homeowner) pair so a homeowner can't
    -- spam-review the same visit. Multiple reviews allowed across
    -- different assessments though.
    UNIQUE (assessment_id, homeowner_id)
);

CREATE INDEX IF NOT EXISTS handyman_reviews_member_recent
    ON public.handyman_reviews (handyman_member_id, created_at DESC);

CREATE INDEX IF NOT EXISTS handyman_reviews_household
    ON public.handyman_reviews (household_id, created_at DESC);

-- updated_at trigger
CREATE OR REPLACE FUNCTION public.touch_handyman_reviews_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS handyman_reviews_updated_at ON public.handyman_reviews;
CREATE TRIGGER handyman_reviews_updated_at
    BEFORE UPDATE ON public.handyman_reviews
    FOR EACH ROW EXECUTE FUNCTION public.touch_handyman_reviews_updated_at();

ALTER TABLE public.handyman_reviews ENABLE ROW LEVEL SECURITY;

-- Homeowners read their own household's reviews + read every review of
-- a handyman they're considering (the trust card needs aggregate rating
-- across ALL reviews, not just the homeowner's own).
DROP POLICY IF EXISTS "handyman_reviews_select" ON public.handyman_reviews;
CREATE POLICY "handyman_reviews_select"
    ON public.handyman_reviews FOR SELECT
    TO authenticated
    USING (true);  -- public read for trust display; reviews are first-class trust data

-- Homeowners insert reviews for their own household only.
DROP POLICY IF EXISTS "handyman_reviews_insert" ON public.handyman_reviews;
CREATE POLICY "handyman_reviews_insert"
    ON public.handyman_reviews FOR INSERT
    TO authenticated
    WITH CHECK (
        homeowner_id = auth.uid()
        AND household_id = public.get_my_household_id()
    );

-- Homeowners update their own reviews only (edit the rating/text after
-- the fact). Reviews can't be moved to a different household.
DROP POLICY IF EXISTS "handyman_reviews_update_own" ON public.handyman_reviews;
CREATE POLICY "handyman_reviews_update_own"
    ON public.handyman_reviews FOR UPDATE
    TO authenticated
    USING (homeowner_id = auth.uid())
    WITH CHECK (homeowner_id = auth.uid());

GRANT SELECT, INSERT, UPDATE ON public.handyman_reviews TO authenticated;

-- ===========================================================================
-- 3. Aggregate-rating view
-- ===========================================================================
--
-- Pre-computed avg rating + review count per handyman_member, exposed
-- as a view so iOS can fetch it in one query without joining manually.

CREATE OR REPLACE VIEW public.handyman_member_stats AS
SELECT
    pwm.id AS handyman_member_id,
    pwm.workspace_id,
    pwm.user_id,
    pwm.display_name,
    pwm.photo_url,
    pwm.bio,
    pwm.years_in_business,
    pwm.specialties,
    pwm.license_number,
    pwm.license_state,
    pwm.license_verified_at,
    pwm.insurance_carrier,
    pwm.insurance_expiry,
    pwm.insurance_verified_at,
    pwm.background_check_completed_at,
    pwm.background_check_provider,
    pwm.vehicle_photo_url,
    COALESCE(stats.review_count, 0) AS review_count,
    stats.avg_rating
FROM public.provider_workspace_members pwm
LEFT JOIN (
    SELECT
        handyman_member_id,
        COUNT(*) AS review_count,
        ROUND(AVG(rating)::NUMERIC, 1) AS avg_rating
    FROM public.handyman_reviews
    GROUP BY handyman_member_id
) stats ON stats.handyman_member_id = pwm.id;

GRANT SELECT ON public.handyman_member_stats TO authenticated;

COMMENT ON VIEW public.handyman_member_stats IS
    'Phase 85: handyman trust profile + aggregate rating in one row. Read by iOS PreVisitTrustCard.';
