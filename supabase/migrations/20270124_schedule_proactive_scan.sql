-- 20270124_schedule_proactive_scan.sql
--
-- July 2026 hardening plan, Phase 4: proactive-scan — the advertised
-- "background intelligence" moat (document-expiry flags, new-issue
-- detection, vehicle recall checks) — was NEVER scheduled and never called
-- (no cron, no client caller). It now runs weekly.
--
-- The function was hardened this phase: the manual (user-JWT) path is
-- scoped to the caller's OWN household (no body household_id trust); the
-- header-less cron path scans ALL households only (a body household_id is
-- ignored, so an unauthenticated caller can't target one arbitrary
-- household); no household data is returned to the caller; and its Claude
-- call routes through the cost-discipline helper (daily budget cap +
-- kill-switch), so a stray trigger can't run up unbounded spend. This is
-- the same header-less posture as the other working crons (chez-sla-watch,
-- cadence-notifications, cleanup). To lock it fully later, set the
-- INTERNAL_FN_SECRET-derived x-internal-secret header (the function already
-- accepts it via requireInternal) once a secret-delivery path from pg_cron
-- is in place.
--
-- Sunday 06:30 UTC (~1:30am ET) — off-peak, once weekly over the whole base.

SELECT cron.unschedule('proactive_scan_weekly')
    WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'proactive_scan_weekly');

SELECT cron.schedule(
    'proactive_scan_weekly',
    '30 6 * * 0',
    $cron$
    SELECT net.http_post(
        url := 'https://jsucwnkntdrxhysojgri.supabase.co/functions/v1/proactive-scan',
        headers := '{"Content-Type": "application/json"}'::jsonb,
        body := '{"trigger": "cron"}'::jsonb
    );
    $cron$
);
