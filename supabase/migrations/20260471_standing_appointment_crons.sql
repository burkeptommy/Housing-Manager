-- ============================================================================
-- Phase 51: pg_cron schedules for standing appointment daily jobs
-- ============================================================================

-- Auto-resume paused appointments at 07:00 UTC daily
SELECT cron.schedule(
    'auto-resume-standing-appointments',
    '0 7 * * *',
    $$
    SELECT net.http_post(
        url := current_setting('app.settings.supabase_url') || '/functions/v1/auto-resume-standing-appointments',
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
        ),
        body := '{}'::jsonb
    );
    $$
);

-- Roll forward assumed visits at 08:00 UTC daily
SELECT cron.schedule(
    'roll-forward-standing-visits',
    '0 8 * * *',
    $$
    SELECT net.http_post(
        url := current_setting('app.settings.supabase_url') || '/functions/v1/roll-forward-standing-visits',
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
        ),
        body := '{}'::jsonb
    );
    $$
);
