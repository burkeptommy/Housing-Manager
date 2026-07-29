-- 20270122_cadence_reminders_on_routines.sql
--
-- July 2026 hardening plan, Phase 3 (audit F1): the cadence-notifications
-- cron read the DEAD household_cadences table (Phase 55.3 removed every iOS
-- writer; all cadence data now lives in `routines`). Pickup-day pushes —
-- scheduled "for the first time" in Phase 100's 20270108 — therefore fired
-- against stale pre-Phase-55 rows, and routines created since NEVER notified.
-- The function is rewritten against `routines`; this migration adds the
-- send-dedup stamp and reschedules the cron.

-- Send-dedup stamp: one row per (household, window, local send-day). The
-- rewritten function CLAIMS this slot atomically (INSERT ... ON CONFLICT DO
-- NOTHING RETURNING) before pushing, so hourly cron runs + accidental
-- re-triggers can never double-push. This also neutralizes the "spammable
-- endpoint" risk the audit noted — a caller cannot cause more than one push
-- per household per window per local day.
CREATE TABLE IF NOT EXISTS public.routine_reminder_sends (
    household_id uuid NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,
    reminder_window text NOT NULL CHECK (reminder_window IN ('evening_before', 'morning_of')),
    sent_on date NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (household_id, reminder_window, sent_on)
);

-- Admin/service-role only — no client access.
ALTER TABLE public.routine_reminder_sends ENABLE ROW LEVEL SECURITY;

-- Reschedule the cron HOURLY. The function's per-household local-hour window
-- gating (18:00-23:59 evening / 00:00-09:59 morning) selects the right
-- households on each run; the dedup stamp guarantees one push each. This
-- fixes the Phase 100 timezone flaw where the single daily UTC fires
-- (23:05 / 12:05) meant Pacific households never got evening-before pushes
-- and got morning-of at ~4-5am local.
SELECT cron.unschedule('chez_cadence_evening_before')
    WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'chez_cadence_evening_before');
SELECT cron.unschedule('chez_cadence_morning_of')
    WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'chez_cadence_morning_of');
SELECT cron.unschedule('chez_cadence_reminders_hourly')
    WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'chez_cadence_reminders_hourly');

-- One hourly job that runs BOTH windows; the function evaluates each
-- window's local gate independently per household.
SELECT cron.schedule(
    'chez_cadence_reminders_hourly',
    '2 * * * *',
    $cron$
    SELECT
      net.http_post(
        url := 'https://jsucwnkntdrxhysojgri.supabase.co/functions/v1/cadence-notifications',
        headers := '{"Content-Type": "application/json"}'::jsonb,
        body := '{"window": "evening_before"}'::jsonb
      ),
      net.http_post(
        url := 'https://jsucwnkntdrxhysojgri.supabase.co/functions/v1/cadence-notifications',
        headers := '{"Content-Type": "application/json"}'::jsonb,
        body := '{"window": "morning_of"}'::jsonb
      );
    $cron$
);
