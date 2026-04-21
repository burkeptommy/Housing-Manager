-- ============================================================================
-- Phase 55: Backfill from household_cadences and standing_appointments
-- into the unified routines table.
--
-- Strategy: insert with ON CONFLICT DO NOTHING using migrated_from_*
-- columns as the dedup key, so re-running the migration is idempotent.
--
-- This backfill is 54E.2-aware: cadences with vendor links, biweekly+
-- frequency, or service-based cadence types (cleaning/landscaping/
-- pool_service/pest_control) are preserved with full fidelity.
-- ============================================================================

-- Add unique partial indexes so ON CONFLICT can target the migration columns
CREATE UNIQUE INDEX IF NOT EXISTS uniq_routines_migrated_cadence
    ON routines(migrated_from_cadence_id)
    WHERE migrated_from_cadence_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uniq_routines_migrated_appointment
    ON routines(migrated_from_standing_appointment_id)
    WHERE migrated_from_standing_appointment_id IS NOT NULL;

-- ============================================================================
-- Backfill from household_cadences
--
-- Phase 54E.2 added contractor_id, weeks_interval (1-12), anchor_date, plus
-- vendor cadence types (cleaning, lawn_care, pool_service, pest_control).
-- This block preserves all of those.
-- ============================================================================
INSERT INTO routines (
    household_id, property_id,
    label, routine_kind,
    vendor_id,
    cadence_type, cadence_interval_days, days_of_week, time_of_day,
    start_date, next_expected_date,
    active_months,
    evening_before_reminder, morning_of_reminder,
    notes,
    is_paused,
    archived_at,
    migrated_from_cadence_id,
    cadence_source,
    created_at, updated_at
)
SELECT
    c.household_id,
    c.property_id,
    c.label,
    -- Map legacy cadence_type to new routine_kind enum.
    -- 54E.2 service cadences collapse to their routine_kind equivalent.
    CASE c.cadence_type
        WHEN 'trash' THEN 'trash'
        WHEN 'recycling' THEN 'recycling'
        WHEN 'compost' THEN 'compost'
        WHEN 'yard_waste' THEN 'yard_waste'
        WHEN 'recurring_delivery' THEN 'recurring_delivery'
        WHEN 'school_dropoff' THEN 'school_dropoff'
        WHEN 'school_pickup' THEN 'school_pickup'
        WHEN 'cleaning' THEN 'cleaning'
        WHEN 'lawn_care' THEN 'landscaping'
        WHEN 'pool_service' THEN 'pool_service'
        WHEN 'pest_control' THEN 'pest_control'
        ELSE 'other_cadence'
    END as routine_kind,
    c.contractor_id as vendor_id,
    -- 54E.2 weeks_interval ↔ routines cadence_type:
    --   1 → weekly, 2 → biweekly, 3 → triweekly, 4+ → custom_days.
    -- weeks_interval defaults to 1 so legacy 54D rows stay weekly.
    CASE COALESCE(c.weeks_interval, 1)
        WHEN 1 THEN 'weekly'
        WHEN 2 THEN 'biweekly'
        WHEN 3 THEN 'triweekly'
        ELSE 'custom_days'
    END as cadence_type,
    -- custom_days needs an interval in days; weekly variants don't.
    CASE
        WHEN COALESCE(c.weeks_interval, 1) >= 4
            THEN COALESCE(c.weeks_interval, 1) * 7
        ELSE NULL
    END as cadence_interval_days,
    -- Weekly variants carry days_of_week; custom_days doesn't need it
    -- but harmless to keep so the user's original weekday choice
    -- survives in the data even if the expander ignores it.
    c.days_of_week,
    c.time_of_day,
    -- Prefer 54E.2 anchor_date (biweekly+ reference) when present,
    -- else the row's created_at date as a sensible start.
    COALESCE(c.anchor_date, DATE(c.created_at)) as start_date,
    -- Compute next_expected_date as today (the cron will refresh on next run).
    CURRENT_DATE as next_expected_date,
    -- Service-based cadence types pull seasonal_pause_months from the
    -- category_cadence_defaults catalog so Blue Fox landscaping doesn't
    -- render a "pickup" entry in January. Non-service cadences default
    -- to year-round.
    COALESCE(
        (SELECT ARRAY(
            SELECT m FROM generate_series(1, 12) m
            WHERE m != ALL(ccd.seasonal_pause_months)
        )
        FROM category_cadence_defaults ccd
        WHERE ccd.category_key = CASE c.cadence_type
                WHEN 'lawn_care' THEN 'landscaping'
                ELSE c.cadence_type
            END
          AND ccd.seasonal_pause_months IS NOT NULL),
        ARRAY[1,2,3,4,5,6,7,8,9,10,11,12]
    ) as active_months,
    c.evening_before_reminder,
    c.morning_of_reminder,
    c.notes,
    NOT c.is_active as is_paused,
    CASE WHEN c.is_active THEN NULL ELSE c.updated_at END as archived_at,
    c.id as migrated_from_cadence_id,
    'migrated_cadence' as cadence_source,
    c.created_at,
    c.updated_at
FROM household_cadences c
ON CONFLICT (migrated_from_cadence_id) WHERE migrated_from_cadence_id IS NOT NULL
DO NOTHING;

-- ============================================================================
-- Backfill from standing_appointments
-- ============================================================================
INSERT INTO routines (
    household_id, property_id,
    label, routine_kind,
    vendor_id, system_id,
    cadence_type, cadence_interval_days, days_of_week,
    start_date, next_expected_date, last_confirmed_date, last_assumed_date,
    active_months,
    is_paused, paused_at, pause_reason, auto_resume_date,
    notes,
    archived_at,
    migrated_from_standing_appointment_id,
    cadence_source,
    confidence_score,
    created_at, updated_at
)
SELECT
    sa.household_id,
    sa.property_id,
    -- Compose a label from vendor name + service description, falling back
    -- to the system category if neither is set.
    COALESCE(
        NULLIF(TRIM(CONCAT(c.company_name, COALESCE(' · ' || sa.service_description, ''))), ''),
        sa.service_description,
        hs.name,
        hs.category,
        'Recurring service'
    ) as label,
    -- Map system category to routine_kind
    CASE LOWER(COALESCE(hs.category, ''))
        WHEN 'landscaping' THEN 'landscaping'
        WHEN 'pool/spa' THEN 'pool_service'
        WHEN 'pool' THEN 'pool_service'
        WHEN 'pest control' THEN 'pest_control'
        WHEN 'cleaning service' THEN 'cleaning'
        WHEN 'pet waste' THEN 'pet_waste'
        WHEN 'mosquito & tick' THEN 'mosquito_tick'
        WHEN 'snow removal' THEN 'snow_removal'
        WHEN 'gutter cleaning' THEN 'gutter_cleaning'
        WHEN 'window cleaning' THEN 'window_cleaning'
        WHEN 'tree service' THEN 'tree_service'
        WHEN 'handyman' THEN 'handyman_recurring'
        ELSE 'other_service'
    END as routine_kind,
    sa.vendor_id,
    sa.system_id,
    sa.cadence_type,
    sa.cadence_interval_days,
    -- Standing appointments don't carry days_of_week natively (they're
    -- anchored on start_date with an interval), but the routines CHECK
    -- requires weekly/biweekly/triweekly to have a non-null days_of_week.
    -- Synthesize one from start_date's weekday so the expander can match
    -- the correct day going forward. Postgres DOW (0=Sun..6=Sat) + 1
    -- yields the ISO 8601 weekday iOS uses (1=Sun..7=Sat). Non-weekly
    -- cadences leave days_of_week NULL — the constraint doesn't apply.
    CASE
        WHEN sa.cadence_type IN ('weekly', 'biweekly', 'triweekly')
            THEN ARRAY[(EXTRACT(DOW FROM sa.start_date)::INT + 1)]
        ELSE NULL
    END as days_of_week,
    sa.start_date,
    sa.next_expected_date,
    sa.last_confirmed_date,
    sa.last_assumed_date,
    -- Map seasonal_pause_months from category_cadence_defaults.
    -- If the category had pause months, active_months = inverse; otherwise year-round.
    COALESCE(
        (SELECT ARRAY(
            SELECT m FROM generate_series(1, 12) m
            WHERE m != ALL(ccd.seasonal_pause_months)
        ) FROM category_cadence_defaults ccd
        WHERE ccd.category_key = LOWER(REPLACE(hs.category, ' ', '_'))
          AND ccd.seasonal_pause_months IS NOT NULL),
        ARRAY[1,2,3,4,5,6,7,8,9,10,11,12]
    ) as active_months,
    sa.is_paused,
    sa.paused_at,
    sa.pause_reason,
    sa.auto_resume_date,
    sa.notes,
    sa.archived_at,
    sa.id as migrated_from_standing_appointment_id,
    'migrated_appointment' as cadence_source,
    sa.confidence_score,
    sa.created_at,
    sa.updated_at
FROM standing_appointments sa
LEFT JOIN contractors c ON c.id = sa.vendor_id
LEFT JOIN home_systems hs ON hs.id = sa.system_id
ON CONFLICT (migrated_from_standing_appointment_id) WHERE migrated_from_standing_appointment_id IS NOT NULL
DO NOTHING;

-- ============================================================================
-- Backfill routine_visits from standing_appointment_visits
-- ============================================================================
INSERT INTO routine_visits (
    id,
    routine_id,
    scheduled_date,
    status,
    confirmed_at,
    confirmed_by,
    notes,
    created_at
)
SELECT
    sav.id,
    r.id as routine_id,
    sav.scheduled_date,
    sav.status,
    sav.confirmed_at,
    sav.confirmed_by,
    sav.notes,
    sav.created_at
FROM standing_appointment_visits sav
JOIN routines r ON r.migrated_from_standing_appointment_id = sav.standing_appointment_id
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- Repoint maintenance_tasks.standing_appointment_id to routine_id (nullable
-- new column; old column kept for rollback)
-- ============================================================================
ALTER TABLE maintenance_tasks
    ADD COLUMN IF NOT EXISTS routine_id UUID REFERENCES routines(id);

CREATE INDEX IF NOT EXISTS idx_tasks_routine
    ON maintenance_tasks(routine_id) WHERE routine_id IS NOT NULL;

UPDATE maintenance_tasks t
SET routine_id = r.id
FROM routines r
WHERE r.migrated_from_standing_appointment_id = t.standing_appointment_id
  AND t.routine_id IS NULL;

-- ============================================================================
-- VERIFICATION — hard assertions that rollback on mismatch.
-- Claude Code MUST capture the NOTICE output and report the counts.
-- ============================================================================
DO $$
DECLARE
    cadence_count INT;
    appointment_count INT;
    visit_count INT;
    routine_from_cadence_count INT;
    routine_from_appointment_count INT;
    routine_visit_count INT;
    task_with_appointment_count INT;
    task_with_routine_count INT;
BEGIN
    SELECT COUNT(*) INTO cadence_count FROM household_cadences;
    SELECT COUNT(*) INTO appointment_count FROM standing_appointments;
    SELECT COUNT(*) INTO visit_count FROM standing_appointment_visits;
    SELECT COUNT(*) INTO routine_from_cadence_count FROM routines WHERE migrated_from_cadence_id IS NOT NULL;
    SELECT COUNT(*) INTO routine_from_appointment_count FROM routines WHERE migrated_from_standing_appointment_id IS NOT NULL;
    SELECT COUNT(*) INTO routine_visit_count FROM routine_visits;
    SELECT COUNT(*) INTO task_with_appointment_count FROM maintenance_tasks WHERE standing_appointment_id IS NOT NULL;
    SELECT COUNT(*) INTO task_with_routine_count FROM maintenance_tasks WHERE routine_id IS NOT NULL;

    RAISE NOTICE 'Phase 55 backfill verification:';
    RAISE NOTICE '  household_cadences: % rows -> routines(from cadence): %', cadence_count, routine_from_cadence_count;
    RAISE NOTICE '  standing_appointments: % rows -> routines(from appt): %', appointment_count, routine_from_appointment_count;
    RAISE NOTICE '  standing_appointment_visits: % rows -> routine_visits: %', visit_count, routine_visit_count;
    RAISE NOTICE '  maintenance_tasks(w/ standing_appt): % -> maintenance_tasks(w/ routine_id): %', task_with_appointment_count, task_with_routine_count;

    -- Hard assertions: counts MUST match
    IF cadence_count != routine_from_cadence_count THEN
        RAISE EXCEPTION 'BACKFILL MISMATCH: cadences(%) != routines from cadences(%)', cadence_count, routine_from_cadence_count;
    END IF;
    IF appointment_count != routine_from_appointment_count THEN
        RAISE EXCEPTION 'BACKFILL MISMATCH: appointments(%) != routines from appointments(%)', appointment_count, routine_from_appointment_count;
    END IF;
    IF visit_count != routine_visit_count THEN
        RAISE EXCEPTION 'BACKFILL MISMATCH: visits(%) != routine_visits(%)', visit_count, routine_visit_count;
    END IF;
    IF task_with_appointment_count != task_with_routine_count THEN
        RAISE EXCEPTION 'BACKFILL MISMATCH: tasks w/ appt(%) != tasks w/ routine(%)', task_with_appointment_count, task_with_routine_count;
    END IF;
END $$;
