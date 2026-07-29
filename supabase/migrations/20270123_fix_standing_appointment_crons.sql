-- 20270123_fix_standing_appointment_crons.sql
--
-- July 2026 hardening plan, Phase 4: the two standing-appointment crons
-- from 20260471 built their URL + auth from current_setting(
-- 'app.settings.supabase_url' / 'service_role_key') — GUCs that hosted
-- Supabase does NOT set. They have therefore FAILED every single night
-- since Phase 51 with "unrecognized configuration parameter
-- app.settings.supabase_url" and zero visibility (confirmed via
-- cron.job_run_details). Re-author on the hardcoded-URL / Content-Type-only
-- pattern the working crons use (20270108, 20270122). The functions are
-- deployed --no-verify-jwt and do idempotent service-role maintenance, so
-- no auth header is needed (same posture as chez-sla-watch's cron).

SELECT cron.unschedule('auto-resume-standing-appointments')
    WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'auto-resume-standing-appointments');
SELECT cron.unschedule('roll-forward-standing-visits')
    WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'roll-forward-standing-visits');

SELECT cron.schedule(
    'auto-resume-standing-appointments',
    '0 7 * * *',
    $cron$
    SELECT net.http_post(
        url := 'https://jsucwnkntdrxhysojgri.supabase.co/functions/v1/auto-resume-standing-appointments',
        headers := '{"Content-Type": "application/json"}'::jsonb,
        body := '{"trigger": "cron"}'::jsonb
    );
    $cron$
);

SELECT cron.schedule(
    'roll-forward-standing-visits',
    '0 8 * * *',
    $cron$
    SELECT net.http_post(
        url := 'https://jsucwnkntdrxhysojgri.supabase.co/functions/v1/roll-forward-standing-visits',
        headers := '{"Content-Type": "application/json"}'::jsonb,
        body := '{"trigger": "cron"}'::jsonb
    );
    $cron$
);
