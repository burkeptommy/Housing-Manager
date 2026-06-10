-- Phase 100 — scheduled jobs wave.
--
-- 1. chez-sla-watch every 15 minutes (Phase 100 part F): warns the
--    operator when an open case is at risk of blowing its 24h
--    business-hours SLA, and again on breach. Idempotent via the
--    sla_warned_at / sla_breach_notified_at stamps.
-- 2. cadence-notifications: the function shipped in Phase 54D and was
--    never scheduled — pickup-day evening-before / morning-of pushes
--    have never fired. Times are fixed UTC chosen to land inside the
--    function's local-hour gates for Eastern households in both EDT and
--    EST (23:05 UTC = 19:05/18:05 ET evening; 12:05 UTC = 08:05/07:05
--    ET morning). The function itself filters by each household's local
--    hour, so off-window households are skipped, not double-sent.
-- 3. cleanup-stale-vendor-applications: shipped in Phase 72, never
--    scheduled; stale pending_email_confirm rows accumulated forever.
--
-- Pattern mirrors 20260419_invite_reminder_cron.sql (unschedule by
-- jobname, then cron.schedule + net.http_post). All three functions are
-- deployed with --no-verify-jwt.

CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

DO $$
DECLARE
    existing_job RECORD;
BEGIN
    FOR existing_job IN
        SELECT jobid FROM cron.job
        WHERE jobname IN (
            'chez_sla_watch_15m',
            'chez_cadence_evening_before',
            'chez_cadence_morning_of',
            'chez_cleanup_stale_vendor_apps'
        )
    LOOP
        PERFORM cron.unschedule(existing_job.jobid);
    END LOOP;
END $$;

SELECT cron.schedule(
    'chez_sla_watch_15m',
    '*/15 * * * *',
    $cron$
    SELECT net.http_post(
        url := 'https://jsucwnkntdrxhysojgri.supabase.co/functions/v1/chez-sla-watch',
        headers := '{"Content-Type": "application/json"}'::jsonb,
        body := '{"trigger": "cron"}'::jsonb
    ) AS request_id;
    $cron$
);

SELECT cron.schedule(
    'chez_cadence_evening_before',
    '5 23 * * *',
    $cron$
    SELECT net.http_post(
        url := 'https://jsucwnkntdrxhysojgri.supabase.co/functions/v1/cadence-notifications',
        headers := '{"Content-Type": "application/json"}'::jsonb,
        body := '{"window": "evening_before"}'::jsonb
    ) AS request_id;
    $cron$
);

SELECT cron.schedule(
    'chez_cadence_morning_of',
    '5 12 * * *',
    $cron$
    SELECT net.http_post(
        url := 'https://jsucwnkntdrxhysojgri.supabase.co/functions/v1/cadence-notifications',
        headers := '{"Content-Type": "application/json"}'::jsonb,
        body := '{"window": "morning_of"}'::jsonb
    ) AS request_id;
    $cron$
);

SELECT cron.schedule(
    'chez_cleanup_stale_vendor_apps',
    '17 9 * * *',
    $cron$
    SELECT net.http_post(
        url := 'https://jsucwnkntdrxhysojgri.supabase.co/functions/v1/cleanup-stale-vendor-applications',
        headers := '{"Content-Type": "application/json"}'::jsonb,
        body := '{"trigger": "cron"}'::jsonb
    ) AS request_id;
    $cron$
);
