-- Phase 84 — Universal entity-level delegation. The previous Chez
-- ownership flags landed on routines + contractors + maintenance_tasks
-- (Phase 80.1 / 80.2). This phase extends ownership to every entity
-- type a homeowner can hand off: home systems, projects, documents,
-- utility accounts, vehicles, plus insurance policies (which live as
-- columns on `properties`, so we use a JSONB key-per-policy).
--
-- Companion structures:
--   • households.chez_ownership_groups JSONB — group-level "Chez handles
--     all my X" flags (8 groups: routines, systems, vendors, projects,
--     bills, documents, insurance, vehicles). Flipping one of these to
--     `on` triggers a backfill that stamps every existing entity in
--     that category as owned, AND sets a "new entries inherit" flag so
--     newly-created entities auto-delegate.
--   • chez_workbench_actions — audit trail for everything Tom does on a
--     Chez-owned entity from the admin Households workbench (schedule a
--     visit on owned routine, log service on owned system, audit a bill
--     on owned utility, etc.). Drives the "Recent Chez activity" feed
--     on the iOS side too.
--   • chez_reminders — operator-set follow-ups that aren't tied to an
--     existing entity timeline ("call A&A Tuesday for their counter").
--     Drives the "Upcoming" cross-household priority queue.

-- ============================================================================
-- Per-entity chez_owned flags
-- ============================================================================

ALTER TABLE public.home_systems
    ADD COLUMN IF NOT EXISTS chez_owned BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.home_systems
    ADD COLUMN IF NOT EXISTS chez_owned_at TIMESTAMPTZ;

ALTER TABLE public.property_projects
    ADD COLUMN IF NOT EXISTS chez_owned BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.property_projects
    ADD COLUMN IF NOT EXISTS chez_owned_at TIMESTAMPTZ;

ALTER TABLE public.documents
    ADD COLUMN IF NOT EXISTS chez_owned BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.documents
    ADD COLUMN IF NOT EXISTS chez_owned_at TIMESTAMPTZ;

ALTER TABLE public.utility_accounts
    ADD COLUMN IF NOT EXISTS chez_owned BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.utility_accounts
    ADD COLUMN IF NOT EXISTS chez_owned_at TIMESTAMPTZ;

ALTER TABLE public.vehicles
    ADD COLUMN IF NOT EXISTS chez_owned BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.vehicles
    ADD COLUMN IF NOT EXISTS chez_owned_at TIMESTAMPTZ;

-- Insurance lives as fields on `properties` (homeowners insurance) and
-- on `vehicles` (auto insurance) without its own dedicated table. JSONB
-- on properties tracks per-policy ownership state. Shape:
--   {
--     "homeowners":         { "owned": true,  "owned_at": "2026-05-03T..." },
--     "auto_<vehicle_id>":  { "owned": false }
--   }
ALTER TABLE public.properties
    ADD COLUMN IF NOT EXISTS chez_owned_insurance JSONB
    NOT NULL DEFAULT '{}'::jsonb;

-- Partial indexes for "everything Chez owns for this household" queries.
-- Each is intentionally narrow (WHERE chez_owned = true) so it stays
-- tiny relative to the parent table.
CREATE INDEX IF NOT EXISTS idx_home_systems_chez_owned
    ON public.home_systems(household_id, chez_owned_at DESC)
    WHERE chez_owned = true;
CREATE INDEX IF NOT EXISTS idx_property_projects_chez_owned
    ON public.property_projects(household_id, chez_owned_at DESC)
    WHERE chez_owned = true;
CREATE INDEX IF NOT EXISTS idx_documents_chez_owned
    ON public.documents(household_id, chez_owned_at DESC)
    WHERE chez_owned = true;
CREATE INDEX IF NOT EXISTS idx_utility_accounts_chez_owned
    ON public.utility_accounts(household_id, chez_owned_at DESC)
    WHERE chez_owned = true;
CREATE INDEX IF NOT EXISTS idx_vehicles_chez_owned
    ON public.vehicles(household_id, chez_owned_at DESC)
    WHERE chez_owned = true;

-- ============================================================================
-- Group-level ownership flags + new-entity inheritance
-- ============================================================================
--
-- Eight group toggles. When `on=true`, two effects:
--   1. backfill: stamp every existing entity in that category as owned
--      (handled by the Edge Function's set_ownership_group action — not
--      the migration, since the backfill needs to write a single
--      summary system-message in the chez_request thread instead of
--      one per entity).
--   2. inheritance: newly-created entities in this household auto-set
--      `chez_owned = true` at insert time. The Edge Function checks
--      this flag on every relevant insert path.
--
-- Shape: { "all_routines": { "on": true, "set_at": "..." }, ... }

ALTER TABLE public.households
    ADD COLUMN IF NOT EXISTS chez_ownership_groups JSONB
    NOT NULL DEFAULT '{}'::jsonb;

-- ============================================================================
-- Workbench action audit trail
-- ============================================================================
--
-- Every action Tom takes on a Chez-owned entity from the admin
-- Households workbench writes a row here. Drives:
--   • "Recent workbench actions" strip in the per-household command
--     center
--   • "Recent Chez activity" feed on the homeowner's iOS Dashboard
--     (post-Phase 84.1)
--   • Cross-household activity audit + analytics

CREATE TABLE IF NOT EXISTS public.chez_workbench_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,
    entity_type TEXT NOT NULL CHECK (entity_type IN (
        'system', 'routine', 'contractor', 'task', 'project',
        'document', 'utility', 'insurance', 'vehicle'
    )),
    entity_id UUID NOT NULL,
    action_type TEXT NOT NULL,                  -- 'schedule_visit' / 'log_service' / 'audit_bill' / etc.
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    performed_by_user_id UUID REFERENCES auth.users(id),
    request_id UUID REFERENCES public.chez_requests(id),  -- nullable; non-null when action ties to a case
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_workbench_actions_household
    ON public.chez_workbench_actions(household_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_workbench_actions_entity
    ON public.chez_workbench_actions(entity_type, entity_id, created_at DESC);

-- RLS: household members can READ their own actions (for the iOS
-- Recent Chez activity feed); admin reads + writes everything.
ALTER TABLE public.chez_workbench_actions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members read own household workbench actions"
    ON public.chez_workbench_actions FOR SELECT
    USING (
        household_id IN (SELECT household_id FROM users WHERE id = auth.uid())
    );

CREATE POLICY "Admin reads all workbench actions"
    ON public.chez_workbench_actions FOR SELECT
    USING (public.is_tom_admin());

CREATE POLICY "Admin writes all workbench actions"
    ON public.chez_workbench_actions FOR INSERT
    WITH CHECK (public.is_tom_admin());

-- ============================================================================
-- Reminders for the cross-household Upcoming feed
-- ============================================================================
--
-- Operator-set follow-ups that don't fit an existing entity timeline.
-- "Remember to chase A&A Tuesday for their counter-offer." "Check the
-- warranty paperwork comes back from the homeowner this week." These
-- surface in the admin portal's Upcoming feed alongside computed-from-
-- entity items (routine visits, bill due dates, warranty expirations).

CREATE TABLE IF NOT EXISTS public.chez_reminders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,
    -- Optional links — when set, the reminder shows alongside the linked
    -- entity in the Upcoming feed and the Households workbench.
    request_id UUID REFERENCES public.chez_requests(id),
    entity_type TEXT,                             -- 'system' | 'routine' | 'project' | etc.
    entity_id UUID,
    due_at TIMESTAMPTZ NOT NULL,
    title TEXT NOT NULL,
    notes TEXT,
    created_by_user_id UUID REFERENCES auth.users(id),
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_chez_reminders_due
    ON public.chez_reminders(due_at)
    WHERE completed_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_chez_reminders_household_due
    ON public.chez_reminders(household_id, due_at)
    WHERE completed_at IS NULL;

ALTER TABLE public.chez_reminders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members read own household reminders"
    ON public.chez_reminders FOR SELECT
    USING (
        household_id IN (SELECT household_id FROM users WHERE id = auth.uid())
    );

CREATE POLICY "Admin manages all reminders"
    ON public.chez_reminders FOR ALL
    USING (public.is_tom_admin())
    WITH CHECK (public.is_tom_admin());

-- ============================================================================
-- Operator-initiated case marker
-- ============================================================================
--
-- Today every chez_request comes from the homeowner. Phase 84 adds a
-- "+ New case" button in the cockpit so Tom can spawn a case for any
-- household. Track these via a flag so we can distinguish operator-
-- initiated vs homeowner-initiated cases for analytics + the iOS thread
-- ("This case was started by Chez on your behalf").

ALTER TABLE public.chez_requests
    ADD COLUMN IF NOT EXISTS admin_initiated BOOLEAN NOT NULL DEFAULT false;
