-- Phase 80.2: Per-task Chez delegation. Routines + contractors got
-- ownership in 20261202; tasks need it too because the most common
-- "I want help with this" moment is a single specific task without a
-- vendor on file (or with a vendor the homeowner doesn't want to chase
-- themselves). Without this, the homeowner can only delegate at the
-- routine / contractor level, which forces them to think structurally
-- about something they want to hand off in one tap.
--
-- New shape:
--   • maintenance_tasks.chez_owned          — boolean flag
--   • maintenance_tasks.chez_owned_at       — timestamp of delegation
--   • maintenance_tasks.chez_request_id     — FK to the parent
--                                             chez_request that owns
--                                             coordination for this
--                                             task. Lets Chez update the
--                                             task (mark complete,
--                                             reschedule, link a vendor)
--                                             from inside the request
--                                             thread.

ALTER TABLE public.maintenance_tasks
    ADD COLUMN IF NOT EXISTS chez_owned BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE public.maintenance_tasks
    ADD COLUMN IF NOT EXISTS chez_owned_at TIMESTAMPTZ;

ALTER TABLE public.maintenance_tasks
    ADD COLUMN IF NOT EXISTS chez_request_id UUID
    REFERENCES public.chez_requests(id) ON DELETE SET NULL;

-- Partial index for the admin portal's standing-engagements filter
-- (we only ever query the "delegated" subset, never the full table on
-- this column).
CREATE INDEX IF NOT EXISTS idx_maintenance_tasks_chez_owned
    ON public.maintenance_tasks(household_id, chez_owned)
    WHERE chez_owned = true;

CREATE INDEX IF NOT EXISTS idx_maintenance_tasks_chez_request
    ON public.maintenance_tasks(chez_request_id)
    WHERE chez_request_id IS NOT NULL;
