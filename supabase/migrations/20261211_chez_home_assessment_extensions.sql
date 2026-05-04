-- Phase 84.5 — Free Handyman Assessment extensions (round 2)
-- =============================================================
-- Layered on top of 20261210_chez_home_assessment.sql. Adds the
-- gap-closure pieces from the latest plan revision:
--
--   • G18 — condition rating + observation columns on home_systems
--   • G44 — system decommissioning (is_active + decommissioned_at)
--   • G15 — onboarded_via attribution on entity tables
--   • G19 — assessment_recommended_tasks (the work-backlog table)
--   • G47 — home_assessment_members (multi-handyman junction)
--   • G37 — assessment-exports storage bucket
--   • G32/G34/G31/G24/G16/G3 — additional home_assessments columns
--   • install_date_source CHECK constraint (was added without one)
--
-- Idempotent — every ALTER uses IF NOT EXISTS / DO blocks. Safe to
-- re-apply over the existing 20261210 migration.

-- ============================================================================
-- 1. Condition + observation on home_systems (G18, G26, G44)
-- ============================================================================

ALTER TABLE public.home_systems
    ADD COLUMN IF NOT EXISTS condition_rating TEXT
        CHECK (condition_rating IS NULL OR condition_rating IN
            ('good', 'fair', 'needs_attention', 'urgent')),
    ADD COLUMN IF NOT EXISTS condition_notes TEXT,
    ADD COLUMN IF NOT EXISTS condition_photos JSONB NOT NULL DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS last_assessed_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT true,
    ADD COLUMN IF NOT EXISTS decommissioned_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS decommissioned_reason TEXT;

-- Tighten install_date_source to the canonical enum — column exists
-- since 20260903, never had a CHECK. Use DO block since CHECK ADD has
-- no IF NOT EXISTS.
--
-- Phase 85: legacy rows used uncanonical values ('estimated' / 'unknown' /
-- 'exact'). There's also a pre-existing CHECK constraint
-- `home_systems_install_date_source_valid` that allows only the legacy
-- enum. Drop the old constraint, remap the values, then add the new
-- canonical CHECK in one transaction.
ALTER TABLE public.home_systems
    DROP CONSTRAINT IF EXISTS home_systems_install_date_source_valid;

UPDATE public.home_systems
SET install_date_source = CASE install_date_source
    WHEN 'estimated' THEN 'attom_estimate'
    WHEN 'unknown' THEN NULL
    WHEN 'exact' THEN 'homeowner_confirmed'
    ELSE install_date_source
END
WHERE install_date_source IS NOT NULL
  AND install_date_source NOT IN ('attom_estimate', 'homeowner_confirmed', 'handyman_observed', 'vendor_invoice');

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'home_systems_install_date_source_check'
    ) THEN
        ALTER TABLE public.home_systems
            ADD CONSTRAINT home_systems_install_date_source_check
            CHECK (install_date_source IS NULL OR install_date_source IN
                ('attom_estimate', 'homeowner_confirmed',
                 'handyman_observed', 'vendor_invoice'));
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_home_systems_active
    ON public.home_systems(property_id) WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_home_systems_condition_urgent
    ON public.home_systems(property_id, condition_rating)
    WHERE condition_rating = 'urgent';

COMMENT ON COLUMN public.home_systems.condition_rating IS
    'Phase 84.5 G18 — handyman-rated condition at last assessment';
COMMENT ON COLUMN public.home_systems.is_active IS
    'Phase 84.5 G44 — false for decommissioned systems (e.g. old well after city water hookup). Reconciler skips inactive systems.';

-- ============================================================================
-- 2. Source attribution on entity tables (G15)
-- ============================================================================
-- Display-only "where did this row come from" tag. Never gates logic.

ALTER TABLE public.home_systems        ADD COLUMN IF NOT EXISTS onboarded_via TEXT;
ALTER TABLE public.contractors         ADD COLUMN IF NOT EXISTS onboarded_via TEXT;
ALTER TABLE public.routines            ADD COLUMN IF NOT EXISTS onboarded_via TEXT;
ALTER TABLE public.vehicles            ADD COLUMN IF NOT EXISTS onboarded_via TEXT;
ALTER TABLE public.utility_accounts    ADD COLUMN IF NOT EXISTS onboarded_via TEXT;
ALTER TABLE public.documents           ADD COLUMN IF NOT EXISTS uploaded_via TEXT;

COMMENT ON COLUMN public.home_systems.onboarded_via IS
    'Phase 84.5 G15 — origin of the row: self_quiz / handyman_assessment / manual / attom / invoice_extraction / chez_admin. Display-only.';

-- ============================================================================
-- 3. home_assessments — additional gap-closure columns
-- ============================================================================

ALTER TABLE public.home_assessments
    -- G16: re-assessment round counter (UI deferred to 84.6)
    ADD COLUMN IF NOT EXISTS assessment_round INT NOT NULL DEFAULT 1,
    -- G32: multi-session assessment support
    ADD COLUMN IF NOT EXISTS session_count INT NOT NULL DEFAULT 1,
    -- G34: existing-user supplemental assessment marker (upsert ingestion)
    ADD COLUMN IF NOT EXISTS is_existing_user_supplement BOOLEAN NOT NULL DEFAULT false,
    -- G31: vacant home / homeowner-not-present flow
    ADD COLUMN IF NOT EXISTS homeowner_present BOOLEAN NOT NULL DEFAULT true,
    ADD COLUMN IF NOT EXISTS homeowner_access_notes TEXT,
    -- G24: bookend zones
    ADD COLUMN IF NOT EXISTS homeowner_concerns TEXT,
    ADD COLUMN IF NOT EXISTS homeowner_wrapup_notes TEXT,
    -- G37: PDF export
    ADD COLUMN IF NOT EXISTS pdf_export_path TEXT,
    -- G3: ingestion failure tracking
    ADD COLUMN IF NOT EXISTS ingestion_error TEXT,
    -- G18: vehicles + utility accounts captured payloads (not in original)
    ADD COLUMN IF NOT EXISTS captured_vehicles JSONB NOT NULL DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS captured_utility_accounts JSONB NOT NULL DEFAULT '[]'::jsonb,
    -- G21: quick-fixes log
    ADD COLUMN IF NOT EXISTS captured_quick_fixes JSONB NOT NULL DEFAULT '[]'::jsonb;

-- Add 'ingestion_failed' to status check (DROP+ADD since CHECK has no
-- IF NOT EXISTS modifier).
DO $$
BEGIN
    -- Find and drop the existing status check constraint
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'public.home_assessments'::regclass
          AND conname LIKE '%status%check'
    ) THEN
        EXECUTE (
            SELECT 'ALTER TABLE public.home_assessments DROP CONSTRAINT ' || conname
            FROM pg_constraint
            WHERE conrelid = 'public.home_assessments'::regclass
              AND conname LIKE '%status%check'
            LIMIT 1
        );
    END IF;

    -- Re-add with ingestion_failed included
    ALTER TABLE public.home_assessments
        ADD CONSTRAINT home_assessments_status_check
        CHECK (status IN (
            'pending', 'scheduled', 'en_route', 'in_progress',
            'submitted', 'awaiting_review', 'corrections_requested',
            'ingestion_failed',
            'completed', 'cancelled'
        ));
END $$;

-- ============================================================================
-- 4. home_assessment_members — multi-handyman support (G47)
-- ============================================================================
-- Replaces the single home_assessments.handyman_member_id with a
-- many-to-many shape. The legacy column stays for backward-compat;
-- new code reads through this junction table.

CREATE TABLE IF NOT EXISTS public.home_assessment_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assessment_id UUID NOT NULL REFERENCES public.home_assessments(id) ON DELETE CASCADE,
    member_id UUID NOT NULL REFERENCES public.provider_workspace_members(id) ON DELETE RESTRICT,
    is_primary BOOLEAN NOT NULL DEFAULT false,
    role TEXT,                                     -- 'lead', 'plumbing_specialist', etc.
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (assessment_id, member_id)
);

-- Exactly one primary member per assessment
CREATE UNIQUE INDEX IF NOT EXISTS idx_one_primary_per_assessment
    ON public.home_assessment_members(assessment_id)
    WHERE is_primary = true;

CREATE INDEX IF NOT EXISTS idx_assessment_members_member
    ON public.home_assessment_members(member_id);

ALTER TABLE public.home_assessment_members ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members read assessment_members for own household"
    ON public.home_assessment_members;
CREATE POLICY "Members read assessment_members for own household"
    ON public.home_assessment_members FOR SELECT
    USING (assessment_id IN (
        SELECT id FROM public.home_assessments
        WHERE household_id IN (SELECT household_id FROM public.users WHERE id = auth.uid())
    ));

DROP POLICY IF EXISTS "Handyman reads workspace assessment_members"
    ON public.home_assessment_members;
CREATE POLICY "Handyman reads workspace assessment_members"
    ON public.home_assessment_members FOR SELECT
    USING (member_id IN (
        SELECT id FROM public.provider_workspace_members
        WHERE workspace_id IN (SELECT public.get_my_provider_workspace_ids())
    ));

DROP POLICY IF EXISTS "Admin manages assessment_members"
    ON public.home_assessment_members;
CREATE POLICY "Admin manages assessment_members"
    ON public.home_assessment_members FOR ALL
    USING (public.is_tom_admin())
    WITH CHECK (public.is_tom_admin());

-- ============================================================================
-- 5. assessment_recommended_tasks — the work backlog (G19, G20, G25, G28,
--    G36, G45, G46, G48, G50)
-- ============================================================================
-- Each row is a recommendation the handyman captured during the visit.
-- On submit_assessment_data, these fan out into chez_requests (default),
-- property_projects (when high-cost), or maintenance_tasks (when the
-- homeowner already has it handled). The reconciler is told to skip
-- templates whose templateKey appears in this table to avoid duplicates.

CREATE TABLE IF NOT EXISTS public.assessment_recommended_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assessment_id UUID NOT NULL REFERENCES public.home_assessments(id) ON DELETE CASCADE,
    system_id UUID REFERENCES public.home_systems(id) ON DELETE SET NULL,

    -- Which of the 11 walking-order zones (G22)
    zone TEXT,

    title TEXT NOT NULL,
    description TEXT,
    category TEXT,

    -- G25: forces tiering at capture time
    urgency TEXT NOT NULL CHECK (urgency IN
        ('urgent', 'soon', 'next_season', 'opportunistic')),

    recommended_owner TEXT NOT NULL CHECK (recommended_owner IN
        ('homeowner_diy', 'chez_handyman', 'chez_vendor')),

    -- G28: signals reconciler to skip the matching template
    recommended_template_key TEXT,

    -- G45: handyman observed vs homeowner reported
    observation_source TEXT NOT NULL DEFAULT 'handyman_observed'
        CHECK (observation_source IN
            ('handyman_observed', 'homeowner_reported', 'both')),
    needs_verification BOOLEAN NOT NULL DEFAULT false,

    estimated_cost_cents INT,

    -- G50: split notes into homeowner-visible and admin-only
    handyman_notes TEXT,                -- admin-only
    homeowner_visible_notes TEXT,       -- default visible to homeowner

    photos JSONB NOT NULL DEFAULT '[]'::jsonb,

    -- G24+G46+G48: homeowner wrap-up response
    homeowner_response TEXT CHECK (homeowner_response IN
        ('approved', 'declined', 'deferred', 'homeowner_handled')),
    homeowner_handled_scheduled_for DATE,
    homeowner_handled_vendor TEXT,

    -- G48: disputed observation flag
    disputed BOOLEAN NOT NULL DEFAULT false,

    -- G21: quick-fix during visit
    fixed_during_visit BOOLEAN NOT NULL DEFAULT false,

    -- Backlinks populated at ingestion time
    spawned_chez_request_id UUID REFERENCES public.chez_requests(id) ON DELETE SET NULL,
    spawned_project_id UUID REFERENCES public.property_projects(id) ON DELETE SET NULL,
    spawned_service_record_id UUID,
    spawned_maintenance_task_id UUID,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_recommended_tasks_assessment
    ON public.assessment_recommended_tasks(assessment_id);
CREATE INDEX IF NOT EXISTS idx_recommended_tasks_urgent
    ON public.assessment_recommended_tasks(assessment_id, urgency)
    WHERE urgency = 'urgent';
CREATE INDEX IF NOT EXISTS idx_recommended_tasks_disputed
    ON public.assessment_recommended_tasks(assessment_id)
    WHERE disputed = true;
CREATE INDEX IF NOT EXISTS idx_recommended_tasks_needs_verification
    ON public.assessment_recommended_tasks(assessment_id)
    WHERE needs_verification = true;
CREATE INDEX IF NOT EXISTS idx_recommended_tasks_template_key
    ON public.assessment_recommended_tasks(assessment_id, recommended_template_key)
    WHERE recommended_template_key IS NOT NULL;

ALTER TABLE public.assessment_recommended_tasks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members read recommended_tasks for own household"
    ON public.assessment_recommended_tasks;
CREATE POLICY "Members read recommended_tasks for own household"
    ON public.assessment_recommended_tasks FOR SELECT
    USING (assessment_id IN (
        SELECT id FROM public.home_assessments
        WHERE household_id IN (SELECT household_id FROM public.users WHERE id = auth.uid())
    ));

DROP POLICY IF EXISTS "Members update homeowner_response on recommended_tasks"
    ON public.assessment_recommended_tasks;
CREATE POLICY "Members update homeowner_response on recommended_tasks"
    ON public.assessment_recommended_tasks FOR UPDATE
    USING (assessment_id IN (
        SELECT id FROM public.home_assessments
        WHERE household_id IN (SELECT household_id FROM public.users WHERE id = auth.uid())
    ));

DROP POLICY IF EXISTS "Handyman reads recommended_tasks for own visits"
    ON public.assessment_recommended_tasks;
CREATE POLICY "Handyman reads recommended_tasks for own visits"
    ON public.assessment_recommended_tasks FOR SELECT
    USING (assessment_id IN (
        SELECT a.id FROM public.home_assessments a
        JOIN public.provider_visit_assignments pva ON pva.id = a.visit_assignment_id
        WHERE pva.workspace_id IN (SELECT public.get_my_provider_workspace_ids())
    ));

DROP POLICY IF EXISTS "Handyman manages recommended_tasks for own visits"
    ON public.assessment_recommended_tasks;
CREATE POLICY "Handyman manages recommended_tasks for own visits"
    ON public.assessment_recommended_tasks FOR ALL
    USING (assessment_id IN (
        SELECT a.id FROM public.home_assessments a
        JOIN public.provider_visit_assignments pva ON pva.id = a.visit_assignment_id
        WHERE pva.workspace_id IN (SELECT public.get_my_provider_workspace_ids())
    ))
    WITH CHECK (assessment_id IN (
        SELECT a.id FROM public.home_assessments a
        JOIN public.provider_visit_assignments pva ON pva.id = a.visit_assignment_id
        WHERE pva.workspace_id IN (SELECT public.get_my_provider_workspace_ids())
    ));

DROP POLICY IF EXISTS "Admin manages recommended_tasks"
    ON public.assessment_recommended_tasks;
CREATE POLICY "Admin manages recommended_tasks"
    ON public.assessment_recommended_tasks FOR ALL
    USING (public.is_tom_admin())
    WITH CHECK (public.is_tom_admin());

-- updated_at trigger
CREATE OR REPLACE FUNCTION public.update_recommended_tasks_updated_at()
    RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_recommended_tasks_updated_at
    ON public.assessment_recommended_tasks;
CREATE TRIGGER trg_recommended_tasks_updated_at
    BEFORE UPDATE ON public.assessment_recommended_tasks
    FOR EACH ROW EXECUTE FUNCTION public.update_recommended_tasks_updated_at();

COMMENT ON TABLE public.assessment_recommended_tasks IS
    'Phase 84.5 G19 — handyman-captured work recommendations. Fans out into chez_requests/property_projects/maintenance_tasks at submit_assessment_data ingestion time.';

-- ============================================================================
-- 6. assessment-exports storage bucket (G37)
-- ============================================================================
-- Encrypted PDF exports rendered post-ingestion. Private; signed-URL reads.

INSERT INTO storage.buckets (id, name, public)
    VALUES ('assessment-exports', 'assessment-exports', false)
    ON CONFLICT (id) DO NOTHING;

-- Storage RLS — homeowner reads own household's exports, admin reads all,
-- service role writes (PDF render job runs as service_role).
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'storage'
          AND tablename = 'objects'
          AND policyname = 'assessment_exports_household_read'
    ) THEN
        CREATE POLICY "assessment_exports_household_read"
            ON storage.objects FOR SELECT
            USING (
                bucket_id = 'assessment-exports'
                AND (storage.foldername(name))[1] IN (
                    SELECT id::text FROM public.home_assessments
                    WHERE household_id IN (
                        SELECT household_id FROM public.users WHERE id = auth.uid()
                    )
                )
            );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'storage'
          AND tablename = 'objects'
          AND policyname = 'assessment_exports_admin_all'
    ) THEN
        CREATE POLICY "assessment_exports_admin_all"
            ON storage.objects FOR ALL
            USING (
                bucket_id = 'assessment-exports'
                AND public.is_tom_admin()
            )
            WITH CHECK (
                bucket_id = 'assessment-exports'
                AND public.is_tom_admin()
            );
    END IF;
END $$;
