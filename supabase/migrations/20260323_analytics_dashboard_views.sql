-- Analytics Dashboard Views
-- Query these from the Supabase SQL Editor (service role) to see product analytics.
-- Additive migration — no existing tables modified.

-- ============================================================================
-- VIEW: Top events in the last 7 days
-- ============================================================================
CREATE OR REPLACE VIEW analytics_top_events_7d AS
SELECT
    event_name,
    COUNT(*) as event_count,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT session_id) as unique_sessions
FROM analytics_events
WHERE created_at >= now() - interval '7 days'
GROUP BY event_name
ORDER BY event_count DESC;

-- ============================================================================
-- VIEW: Daily active users (last 30 days)
-- ============================================================================
CREATE OR REPLACE VIEW analytics_daily_active_users AS
SELECT
    DATE(created_at) as day,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT session_id) as unique_sessions,
    COUNT(*) as total_events
FROM analytics_events
WHERE created_at >= now() - interval '30 days'
  AND user_id IS NOT NULL
GROUP BY DATE(created_at)
ORDER BY day DESC;

-- ============================================================================
-- VIEW: Screen time ranking (which screens get the most views)
-- ============================================================================
CREATE OR REPLACE VIEW analytics_screen_views AS
SELECT
    screen_name,
    COUNT(*) as view_count,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT session_id) as unique_sessions
FROM analytics_events
WHERE event_name = 'screen_viewed'
  AND screen_name IS NOT NULL
  AND created_at >= now() - interval '30 days'
GROUP BY screen_name
ORDER BY view_count DESC;

-- ============================================================================
-- VIEW: Feature adoption (key features and how many users have tried them)
-- ============================================================================
CREATE OR REPLACE VIEW analytics_feature_adoption AS
SELECT
    event_name as feature,
    COUNT(DISTINCT user_id) as users_who_tried,
    COUNT(*) as total_uses,
    MIN(created_at) as first_use,
    MAX(created_at) as last_use
FROM analytics_events
WHERE event_name IN (
    'document_upload_completed',
    'scenario_submitted',
    'chat_message_sent',
    'property_created',
    'family_member_created',
    'gap_analysis_requested',
    'family_binder_exported',
    'household_invite_sent',
    'contractor_created',
    'maintenance_task_completed',
    'warranty_created',
    'document_ai_analysis_requested',
    'trusted_contact_created',
    'enrichment_card_completed',
    'appliance_setup_completed',
    'service_contract_created'
)
GROUP BY event_name
ORDER BY users_who_tried DESC;

-- ============================================================================
-- VIEW: Onboarding funnel
-- ============================================================================
CREATE OR REPLACE VIEW analytics_onboarding_funnel AS
SELECT
    event_name as step,
    COUNT(DISTINCT user_id) as users,
    properties->>'step' as step_name
FROM analytics_events
WHERE event_name IN (
    'onboarding_started',
    'onboarding_step_completed',
    'onboarding_completed',
    'onboarding_skipped'
)
GROUP BY event_name, properties->>'step'
ORDER BY
    CASE event_name
        WHEN 'onboarding_started' THEN 1
        WHEN 'onboarding_step_completed' THEN 2
        WHEN 'onboarding_completed' THEN 3
        WHEN 'onboarding_skipped' THEN 4
    END,
    step_name;

-- ============================================================================
-- VIEW: User activity summary (per-user metrics)
-- ============================================================================
CREATE OR REPLACE VIEW analytics_user_activity AS
SELECT
    ae.user_id,
    u.email,
    u.full_name,
    COUNT(*) as total_events,
    COUNT(DISTINCT DATE(ae.created_at)) as active_days,
    COUNT(DISTINCT ae.session_id) as total_sessions,
    MIN(ae.created_at) as first_seen,
    MAX(ae.created_at) as last_seen,
    COUNT(*) FILTER (WHERE ae.event_name = 'document_upload_completed') as documents_uploaded,
    COUNT(*) FILTER (WHERE ae.event_name = 'chat_message_sent') as chat_messages,
    COUNT(*) FILTER (WHERE ae.event_name = 'scenario_submitted') as scenarios_run
FROM analytics_events ae
LEFT JOIN users u ON ae.user_id = u.id
WHERE ae.user_id IS NOT NULL
GROUP BY ae.user_id, u.email, u.full_name
ORDER BY last_seen DESC;

-- ============================================================================
-- VIEW: Retention cohorts (day 1, 7, 30 return rates)
-- ============================================================================
CREATE OR REPLACE VIEW analytics_retention AS
WITH user_first_day AS (
    SELECT
        user_id,
        DATE(MIN(created_at)) as first_day
    FROM analytics_events
    WHERE user_id IS NOT NULL
    GROUP BY user_id
),
user_active_days AS (
    SELECT DISTINCT
        user_id,
        DATE(created_at) as active_day
    FROM analytics_events
    WHERE user_id IS NOT NULL
)
SELECT
    ufd.first_day as cohort_date,
    COUNT(DISTINCT ufd.user_id) as cohort_size,
    COUNT(DISTINCT CASE WHEN uad.active_day = ufd.first_day + 1 THEN ufd.user_id END) as day_1_retained,
    COUNT(DISTINCT CASE WHEN uad.active_day = ufd.first_day + 7 THEN ufd.user_id END) as day_7_retained,
    COUNT(DISTINCT CASE WHEN uad.active_day = ufd.first_day + 30 THEN ufd.user_id END) as day_30_retained,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN uad.active_day = ufd.first_day + 1 THEN ufd.user_id END) / NULLIF(COUNT(DISTINCT ufd.user_id), 0), 1) as day_1_pct,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN uad.active_day = ufd.first_day + 7 THEN ufd.user_id END) / NULLIF(COUNT(DISTINCT ufd.user_id), 0), 1) as day_7_pct,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN uad.active_day = ufd.first_day + 30 THEN ufd.user_id END) / NULLIF(COUNT(DISTINCT ufd.user_id), 0), 1) as day_30_pct
FROM user_first_day ufd
LEFT JOIN user_active_days uad ON ufd.user_id = uad.user_id
GROUP BY ufd.first_day
ORDER BY ufd.first_day DESC;

-- ============================================================================
-- VIEW: Hourly activity pattern (when do users use the app?)
-- ============================================================================
CREATE OR REPLACE VIEW analytics_hourly_pattern AS
SELECT
    EXTRACT(HOUR FROM created_at AT TIME ZONE 'America/New_York') as hour_et,
    EXTRACT(DOW FROM created_at AT TIME ZONE 'America/New_York') as day_of_week,
    COUNT(*) as event_count,
    COUNT(DISTINCT user_id) as unique_users
FROM analytics_events
WHERE created_at >= now() - interval '30 days'
GROUP BY
    EXTRACT(HOUR FROM created_at AT TIME ZONE 'America/New_York'),
    EXTRACT(DOW FROM created_at AT TIME ZONE 'America/New_York')
ORDER BY day_of_week, hour_et;

-- ============================================================================
-- VIEW: App version distribution
-- ============================================================================
CREATE OR REPLACE VIEW analytics_app_versions AS
SELECT
    app_version,
    build_number,
    device_model,
    os_version,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT session_id) as sessions,
    MAX(created_at) as last_seen
FROM analytics_events
WHERE created_at >= now() - interval '30 days'
GROUP BY app_version, build_number, device_model, os_version
ORDER BY unique_users DESC;
