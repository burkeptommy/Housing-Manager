-- ============================================================================
-- Phase 55: Routines — unified recurring-event primitive that replaces both
-- household_cadences (Phase 54D/54E) and standing_appointments (Phase 51).
--
-- A Routine is anything that happens on a fixed schedule. It may or may not
-- have a vendor attached. It may or may not have an active season. It may
-- or may not have an associated cost. The user configures it once and it
-- runs — they don't book each occurrence.
--
-- This is distinct from a maintenance Task, which represents per-instance
-- coordination work (annual roof inspection, septic pumping, etc.).
-- ============================================================================

CREATE TABLE IF NOT EXISTS routines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    property_id UUID REFERENCES properties(id) ON DELETE CASCADE,

    -- Identity
    label TEXT NOT NULL,
    routine_kind TEXT NOT NULL CHECK (routine_kind IN (
        -- Service-based (with vendor)
        'cleaning', 'landscaping', 'pool_service', 'pest_control',
        'pet_waste', 'mosquito_tick', 'snow_removal', 'gutter_cleaning',
        'window_cleaning', 'tree_service', 'handyman_recurring',
        -- Cadence-based (typically no vendor)
        'trash', 'recycling', 'compost', 'yard_waste',
        'recurring_delivery', 'school_dropoff', 'school_pickup',
        -- Catch-all
        'other_service', 'other_cadence'
    )),
    icon TEXT,  -- SF Symbol override; nil falls back to routine_kind default
    notes TEXT,

    -- Vendor link (optional — trash has no vendor; Renata's cleaning has Renata)
    vendor_id UUID REFERENCES contractors(id),
    system_id UUID REFERENCES home_systems(id) ON DELETE SET NULL,

    -- Cadence
    cadence_type TEXT NOT NULL CHECK (cadence_type IN (
        'weekly', 'biweekly', 'triweekly',
        'monthly', 'bimonthly',
        'quarterly', 'semiannual', 'annual',
        'custom_days'
    )),
    cadence_interval_days INTEGER,  -- only when cadence_type = 'custom_days'
    -- Days of week for weekly/biweekly cadences. ISO 8601: 1=Sunday..7=Saturday.
    -- Matches Calendar.current.component(.weekday, from:) so iOS reads natively.
    days_of_week INTEGER[],
    -- Time of day for cadences that have one (trash by 7am). NULL for any-time.
    time_of_day TIME,

    -- Schedule anchors
    start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    next_expected_date DATE NOT NULL DEFAULT CURRENT_DATE,
    last_confirmed_date DATE,
    last_assumed_date DATE,

    -- Active months (1=January..12=December). Default all 12 = year-round.
    -- Snow removal: {12,1,2,3}. Lawn care: {4,5,6,7,8,9,10,11}.
    -- Pool service: {5,6,7,8,9}. Trash: all 12.
    active_months INTEGER[] NOT NULL DEFAULT ARRAY[1,2,3,4,5,6,7,8,9,10,11,12],

    -- Reminders
    evening_before_reminder BOOLEAN NOT NULL DEFAULT false,
    morning_of_reminder BOOLEAN NOT NULL DEFAULT false,

    -- Cost (optional — trash is free; Renata charges $250/visit)
    estimated_cost_per_visit_cents INTEGER,
    cost_notes TEXT,

    -- Lifecycle
    is_paused BOOLEAN NOT NULL DEFAULT false,
    paused_at TIMESTAMPTZ,
    pause_reason TEXT,
    auto_resume_date DATE,
    archived_at TIMESTAMPTZ,

    -- Migration provenance — null for natively-created routines
    migrated_from_cadence_id UUID,
    migrated_from_standing_appointment_id UUID,
    cadence_source TEXT CHECK (cadence_source IN (
        'ai_inferred', 'category_default', 'user_set', 'migrated_cadence', 'migrated_appointment'
    )),
    confidence_score NUMERIC,  -- 0.0-1.0 for ai_inferred

    -- Meta
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Invariants
    CONSTRAINT active_months_not_empty CHECK (array_length(active_months, 1) > 0),
    CONSTRAINT active_months_in_range CHECK (
        active_months <@ ARRAY[1,2,3,4,5,6,7,8,9,10,11,12]
    ),
    CONSTRAINT custom_days_has_interval CHECK (
        cadence_type != 'custom_days' OR cadence_interval_days IS NOT NULL
    ),
    CONSTRAINT weekly_has_days_of_week CHECK (
        cadence_type NOT IN ('weekly', 'biweekly', 'triweekly')
        OR days_of_week IS NOT NULL
    )
);

CREATE INDEX IF NOT EXISTS idx_routines_household ON routines(household_id) WHERE archived_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_routines_property ON routines(property_id) WHERE archived_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_routines_vendor ON routines(vendor_id) WHERE archived_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_routines_system ON routines(system_id) WHERE archived_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_routines_next_date ON routines(next_expected_date)
    WHERE is_paused = false AND archived_at IS NULL;

-- ============================================================================
-- routine_visits — per-occurrence instances (mirrors standing_appointment_visits)
-- ============================================================================
CREATE TABLE IF NOT EXISTS routine_visits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    routine_id UUID NOT NULL REFERENCES routines(id) ON DELETE CASCADE,
    scheduled_date DATE NOT NULL,
    status TEXT NOT NULL CHECK (status IN (
        'upcoming', 'confirmed', 'assumed', 'skipped', 'missed'
    )),
    confirmed_at TIMESTAMPTZ,
    confirmed_by TEXT,  -- user_id, 'invoice_auto', 'assumed_rollforward', 'manual'
    actual_cost_cents INTEGER,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_routine_visits_routine ON routine_visits(routine_id);
CREATE INDEX IF NOT EXISTS idx_routine_visits_scheduled_date ON routine_visits(scheduled_date);
CREATE INDEX IF NOT EXISTS idx_routine_visits_upcoming ON routine_visits(routine_id, scheduled_date)
    WHERE status = 'upcoming';

-- ============================================================================
-- RLS — household scoping
-- ============================================================================
ALTER TABLE routines ENABLE ROW LEVEL SECURITY;
ALTER TABLE routine_visits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "routines_all"
    ON routines FOR ALL TO authenticated
    USING (household_id = public.get_my_household_id())
    WITH CHECK (household_id = public.get_my_household_id());

CREATE POLICY "routine_visits_all"
    ON routine_visits FOR ALL TO authenticated
    USING (routine_id IN (
        SELECT id FROM routines WHERE household_id = public.get_my_household_id()
    ))
    WITH CHECK (routine_id IN (
        SELECT id FROM routines WHERE household_id = public.get_my_household_id()
    ));

-- Service role for cron / edge functions
CREATE POLICY "routines_service" ON routines FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "routine_visits_service" ON routine_visits FOR ALL TO service_role USING (true) WITH CHECK (true);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.routines TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.routine_visits TO authenticated;
GRANT ALL ON public.routines TO service_role;
GRANT ALL ON public.routine_visits TO service_role;
