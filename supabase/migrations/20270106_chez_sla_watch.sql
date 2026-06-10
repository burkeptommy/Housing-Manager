-- Phase 100 — Chez Intelligence Foundation, part F: SLA watcher stamps.
--
-- sla_due_at has been computed since Phase 80 but nothing ever watched
-- it: the operator only saw at-risk cases if the Today brief happened
-- to be open. The chez-sla-watch edge function (cron, every 15 min)
-- warns when an open case is inside the at-risk window and again on
-- breach. These columns make the notifications idempotent: the function
-- stamps FIRST with a concurrency-safe .is(col, null) guard, then
-- notifies, so a concurrent run can never double-send.
--
-- handleTransition clears both stamps whenever a case re-enters "open"
-- so a reopened case gets fresh SLA attention.

ALTER TABLE public.chez_requests
    ADD COLUMN IF NOT EXISTS sla_warned_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS sla_breach_notified_at TIMESTAMPTZ;

COMMENT ON COLUMN public.chez_requests.sla_warned_at IS
    'When the at-risk SLA warning push/email was sent for the current open cycle. Cleared on transition back to open.';
COMMENT ON COLUMN public.chez_requests.sla_breach_notified_at IS
    'When the SLA-breach push/email was sent for the current open cycle. Cleared on transition back to open.';

CREATE INDEX IF NOT EXISTS idx_chez_requests_sla_watch
    ON public.chez_requests(sla_due_at)
    WHERE status = 'open';
