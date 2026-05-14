-- ============================================================================
-- Phase 85.6 — Ownership consent flow
-- ============================================================================
--
-- Chez can no longer unilaterally claim ownership of a homeowner's entity.
-- Every "Have Chez own this" must route through a propose/approve loop:
--
--   1. Admin operator clicks "Propose Chez ownership" on an entity
--   2. Server creates a chez_request with category = 'ownership_request',
--      attaches a structured proposal message listing the entities.
--   3. Homeowner sees an Approve/Decline card in their iOS inbox.
--   4. On approve → existing delegate_* flow fires per entity → chez_owned
--      flips to true.
--   5. On decline → the entity goes on a 60-day cooldown so the admin
--      portal can't keep re-asking. After 60 days the operator can propose
--      again if circumstances changed.
--
-- The whole point: Chez's "ownership" is delegated power. It has to be
-- granted by the homeowner explicitly, in writing, every time.
-- ============================================================================

-- 1. Add 'ownership_request' to the chez_requests.category enum.
ALTER TABLE public.chez_requests DROP CONSTRAINT IF EXISTS chez_requests_category_check;
ALTER TABLE public.chez_requests ADD CONSTRAINT chez_requests_category_check
    CHECK (category IN (
        'find_vendor',
        'get_quote',
        'schedule_visit',
        'coordinate_task',
        'find_handyman',
        'general',
        'ownership_request'    -- Phase 85.6 — see header comment.
    ));

-- 2. Cooldown table. When a homeowner declines an ownership proposal, we
-- record it here so the admin portal can show a "Homeowner declined on
-- May 14 — re-ask available Jul 13" pill instead of letting the operator
-- propose again immediately. Cooldown is 60 days by default; the admin
-- can override with a different `expires_at` if the homeowner says
-- something like "ask me again next quarter."
--
-- entity_id is TEXT (not UUID) because the insurance entity_type uses
-- string keys like "homeowners" or "auto_<vehicle_id>", not pure UUIDs.
CREATE TABLE IF NOT EXISTS public.chez_dismissed_ownership_proposals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,
    entity_type TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    -- The chez_requests.id this decline originated from, so we can audit
    -- "which proposal did the homeowner decline" later.
    proposal_request_id UUID REFERENCES public.chez_requests(id) ON DELETE SET NULL,
    -- Optional free-text reason captured at decline time. e.g. "I want to
    -- handle my own bills" or "Maybe next quarter."
    note TEXT,
    declined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    -- Default cooldown is 60 days. Admin can override with a custom value
    -- when they re-pitch ("ask me again in 6 months"); the operator's
    -- "Propose ownership" button respects this expires_at when deciding
    -- whether to render an enabled / disabled state.
    expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + INTERVAL '60 days'),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Lookup index: when the admin opens a focused panel, the server checks
-- "is this entity on cooldown?" with a single point read keyed on the
-- composite (household, type, id).
CREATE INDEX IF NOT EXISTS idx_ownership_cooldown_active
    ON public.chez_dismissed_ownership_proposals (household_id, entity_type, entity_id, expires_at);

-- RLS — household members read their own; admins read all.
ALTER TABLE public.chez_dismissed_ownership_proposals ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "household members see their dismissed proposals"
    ON public.chez_dismissed_ownership_proposals;
CREATE POLICY "household members see their dismissed proposals"
    ON public.chez_dismissed_ownership_proposals
    FOR SELECT
    USING (household_id = public.get_my_household_id());

-- The Edge Function writes via service role, so no INSERT policy needed
-- for end users. (Admins also write via service role.)

-- 3. Add a pointer column on the four entity tables that participate in
-- delegation so the admin portal can resolve "is there a pending proposal
-- on this entity?" in one query without scanning concierge_messages.
--
-- The pointer is to the chez_requests row that holds the open ownership
-- proposal. Cleared on approve (chez_owned flips true via the existing
-- delegate_* flow) or decline (cooldown row inserted + this column
-- cleared in the same transaction).
ALTER TABLE public.maintenance_tasks
    ADD COLUMN IF NOT EXISTS pending_ownership_request_id UUID
    REFERENCES public.chez_requests(id) ON DELETE SET NULL;
ALTER TABLE public.routines
    ADD COLUMN IF NOT EXISTS pending_ownership_request_id UUID
    REFERENCES public.chez_requests(id) ON DELETE SET NULL;
ALTER TABLE public.contractors
    ADD COLUMN IF NOT EXISTS pending_ownership_request_id UUID
    REFERENCES public.chez_requests(id) ON DELETE SET NULL;
ALTER TABLE public.home_systems
    ADD COLUMN IF NOT EXISTS pending_ownership_request_id UUID
    REFERENCES public.chez_requests(id) ON DELETE SET NULL;
ALTER TABLE public.property_projects
    ADD COLUMN IF NOT EXISTS pending_ownership_request_id UUID
    REFERENCES public.chez_requests(id) ON DELETE SET NULL;
ALTER TABLE public.documents
    ADD COLUMN IF NOT EXISTS pending_ownership_request_id UUID
    REFERENCES public.chez_requests(id) ON DELETE SET NULL;
ALTER TABLE public.utility_accounts
    ADD COLUMN IF NOT EXISTS pending_ownership_request_id UUID
    REFERENCES public.chez_requests(id) ON DELETE SET NULL;
ALTER TABLE public.vehicles
    ADD COLUMN IF NOT EXISTS pending_ownership_request_id UUID
    REFERENCES public.chez_requests(id) ON DELETE SET NULL;

-- Partial indexes — only index entities that actually have a pending
-- proposal, since 99% of rows will have NULL.
CREATE INDEX IF NOT EXISTS idx_maintenance_tasks_pending_ownership
    ON public.maintenance_tasks(pending_ownership_request_id)
    WHERE pending_ownership_request_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_routines_pending_ownership
    ON public.routines(pending_ownership_request_id)
    WHERE pending_ownership_request_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_contractors_pending_ownership
    ON public.contractors(pending_ownership_request_id)
    WHERE pending_ownership_request_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_home_systems_pending_ownership
    ON public.home_systems(pending_ownership_request_id)
    WHERE pending_ownership_request_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_property_projects_pending_ownership
    ON public.property_projects(pending_ownership_request_id)
    WHERE pending_ownership_request_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_documents_pending_ownership
    ON public.documents(pending_ownership_request_id)
    WHERE pending_ownership_request_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_utility_accounts_pending_ownership
    ON public.utility_accounts(pending_ownership_request_id)
    WHERE pending_ownership_request_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_vehicles_pending_ownership
    ON public.vehicles(pending_ownership_request_id)
    WHERE pending_ownership_request_id IS NOT NULL;

COMMENT ON TABLE public.chez_dismissed_ownership_proposals IS
'Phase 85.6: when a homeowner declines an ownership proposal, the
entity is locked on the admin side until expires_at. Prevents the
operator from re-asking the same week. Default cooldown is 60 days.';
