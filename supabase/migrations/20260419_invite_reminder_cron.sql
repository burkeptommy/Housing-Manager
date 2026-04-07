-- Phase 10 (Onboarding Revamp): schedule the daily household-invite reminder
-- batch via pg_cron. Fires every day at 10:00 UTC and POSTs to the
-- send-reminder-batch Edge Function with the project's anon key.
--
-- Idempotency:
--   - CREATE EXTENSION IF NOT EXISTS handles re-runs.
--   - cron.schedule() upserts by jobname; we unschedule first to avoid
--     stacking duplicate jobs if the URL or schedule changes.
--
-- The function URL pattern matches every other Haven edge function:
--   https://<project>.supabase.co/functions/v1/send-reminder-batch
--
-- The cron payload only contains a marker so the edge function can log a
-- breadcrumb if it ever needs to differentiate cron-triggered runs from
-- manual ones.

-- 1. Make sure pg_cron is installed (Supabase ships it on Pro/Team but it
-- still needs to be enabled per project).
CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

-- 2. Allow the postgres role to call the cron functions.
GRANT USAGE ON SCHEMA cron TO postgres;

-- 3. Unschedule any prior version of this job, then re-schedule. cron.schedule
-- accepts a textual job name as the first argument.
DO $$
DECLARE
    existing_job RECORD;
BEGIN
    FOR existing_job IN
        SELECT jobid FROM cron.job WHERE jobname = 'haven_send_invite_reminders_daily'
    LOOP
        PERFORM cron.unschedule(existing_job.jobid);
    END LOOP;
END $$;

SELECT cron.schedule(
    'haven_send_invite_reminders_daily',
    '0 10 * * *',
    $cron$
    SELECT
      net.http_post(
        url := 'https://jsucwnkntdrxhysojgri.supabase.co/functions/v1/send-reminder-batch',
        headers := '{"Content-Type": "application/json"}'::jsonb,
        body := '{"trigger": "cron"}'::jsonb
      ) AS request_id;
    $cron$
);

COMMENT ON EXTENSION pg_cron IS
    'Scheduled jobs. haven_send_invite_reminders_daily fires send-reminder-batch every day at 10:00 UTC.';
