-- Phase 82: Chez visit tracking. Once a homeowner approves a vendor
-- proposal, the case shifts from "research and propose" to "coordinate
-- this visit through completion." Each approved vendor becomes a
-- visit row with its own state machine (awaiting_date → scheduled →
-- completed) so the admin portal has a structured way to track every
-- engagement that comes out of a Chez request.
--
-- Also enables the case stage tracker at the top of the admin panel
-- to compute progress without scanning every message.

CREATE TABLE IF NOT EXISTS public.chez_visits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,
    request_id UUID NOT NULL REFERENCES public.chez_requests(id) ON DELETE CASCADE,
    -- FK back to the proposal message that spawned this visit so the
    -- admin can navigate from a visit card back to the proposal in
    -- the conversation thread.
    proposal_message_id UUID REFERENCES public.concierge_messages(id) ON DELETE SET NULL,

    -- Frozen vendor identity at approval time — the proposal's vendor
    -- name + phone, plus a snapshotted JSONB blob of the full payload
    -- so future edits to the proposal don't drift this row.
    vendor_name TEXT NOT NULL,
    vendor_phone TEXT,
    vendor_payload JSONB NOT NULL DEFAULT '{}'::jsonb,

    -- Lifecycle state. Drives the visit card in the admin panel and
    -- the stage tracker computation.
    state TEXT NOT NULL DEFAULT 'awaiting_date' CHECK (state IN (
        'awaiting_date',  -- vendor approved, date not yet set
        'scheduled',      -- date confirmed, visit upcoming
        'completed',      -- visit happened
        'cancelled'       -- vendor pulled out / homeowner reconsidered
    )),

    -- The actual confirmed visit date + window. Set when state
    -- transitions to 'scheduled'.
    scheduled_for TIMESTAMPTZ,
    scheduled_window TEXT,  -- free-form e.g. "2pm-4pm" or "morning"

    -- Admin's running notes — what's been discussed, follow-ups, etc.
    notes TEXT,
    -- Visit outcome, set when state transitions to 'completed'.
    -- e.g. "completed cleanly", "needs follow-up", "didn't show".
    outcome TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_chez_visits_request
    ON public.chez_visits(request_id, created_at);
CREATE INDEX IF NOT EXISTS idx_chez_visits_household_active
    ON public.chez_visits(household_id, state)
    WHERE state IN ('awaiting_date', 'scheduled');

-- ============================================================================
-- RLS — same pattern as chez_requests
-- ============================================================================

ALTER TABLE public.chez_visits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members read own household chez visits"
    ON public.chez_visits FOR SELECT
    USING (
        household_id IN (
            SELECT household_id FROM users WHERE id = auth.uid()
        )
    );

CREATE POLICY "Admin reads all chez visits"
    ON public.chez_visits FOR SELECT
    USING ( public.is_tom_admin() );

CREATE POLICY "Admin updates all chez visits"
    ON public.chez_visits FOR UPDATE
    USING ( public.is_tom_admin() );

-- Reuse the chez_requests updated_at trigger function — sets updated_at
-- to now() on every UPDATE. Generic enough to share across tables.
DROP TRIGGER IF EXISTS chez_visits_updated_at ON public.chez_visits;
CREATE TRIGGER chez_visits_updated_at
    BEFORE UPDATE ON public.chez_visits
    FOR EACH ROW
    EXECUTE FUNCTION public.set_chez_requests_updated_at();
