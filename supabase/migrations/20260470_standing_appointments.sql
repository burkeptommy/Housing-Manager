-- ============================================================================
-- Phase 51: Standing Appointments (Recurring Vendor Visits)
--
-- Introduces standing appointments as a first-class concept for recurring
-- vendor service relationships. Instead of generating N duplicate task cards
-- per year, the vendor relationship owns the cadence, the schedule surfaces
-- only the next upcoming visit, and the model supports confirm/skip/pause.
-- ============================================================================

-- ============================================================================
-- 1. standing_appointments — relationship-level data
-- ============================================================================
CREATE TABLE IF NOT EXISTS standing_appointments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
    vendor_id UUID REFERENCES contractors(id),
    system_id UUID NOT NULL REFERENCES home_systems(id) ON DELETE CASCADE,

    -- Cadence
    cadence_type TEXT NOT NULL CHECK (cadence_type IN (
        'weekly', 'biweekly', 'triweekly', 'monthly', 'bimonthly',
        'quarterly', 'semiannual', 'annual', 'custom_days'
    )),
    cadence_interval_days INTEGER,  -- only required when cadence_type = 'custom_days'

    -- Schedule anchors
    start_date DATE NOT NULL,
    next_expected_date DATE NOT NULL,
    last_confirmed_date DATE,
    last_assumed_date DATE,

    -- Seasonal pause
    is_paused BOOLEAN NOT NULL DEFAULT false,
    paused_at TIMESTAMPTZ,
    pause_reason TEXT,
    auto_resume_date DATE,

    -- Source tracking
    cadence_source TEXT NOT NULL CHECK (cadence_source IN ('ai_inferred', 'category_default', 'user_set')),
    confidence_score NUMERIC,  -- 0.0-1.0 for ai_inferred cadence

    -- Meta
    service_description TEXT,
    notes TEXT,
    archived_at TIMESTAMPTZ,  -- soft-delete for ended relationships
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_standing_appointments_household ON standing_appointments(household_id);
CREATE INDEX idx_standing_appointments_vendor ON standing_appointments(vendor_id);
CREATE INDEX idx_standing_appointments_system ON standing_appointments(system_id);
CREATE INDEX idx_standing_appointments_next_date ON standing_appointments(next_expected_date)
    WHERE is_paused = false AND archived_at IS NULL;

-- ============================================================================
-- 2. standing_appointment_visits — per-visit instances
-- ============================================================================
CREATE TABLE IF NOT EXISTS standing_appointment_visits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    standing_appointment_id UUID NOT NULL REFERENCES standing_appointments(id) ON DELETE CASCADE,
    scheduled_date DATE NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('upcoming', 'confirmed', 'assumed', 'skipped', 'missed')),
    confirmed_at TIMESTAMPTZ,
    confirmed_by TEXT,  -- user_id, 'invoice_auto', or 'assumed_rollforward'
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_visits_appointment ON standing_appointment_visits(standing_appointment_id);
CREATE INDEX idx_visits_scheduled_date ON standing_appointment_visits(scheduled_date);
CREATE INDEX idx_visits_upcoming ON standing_appointment_visits(standing_appointment_id, scheduled_date)
    WHERE status = 'upcoming';

-- ============================================================================
-- 3. category_cadence_defaults — cold-start seed for new vendor relationships
-- ============================================================================
CREATE TABLE IF NOT EXISTS category_cadence_defaults (
    category_key TEXT PRIMARY KEY,
    default_cadence_type TEXT NOT NULL,
    default_interval_days INTEGER,
    seasonal_pause_months INTEGER[],  -- e.g. {12,1,2,3} for landscaping in northeast
    service_description_template TEXT
);

INSERT INTO category_cadence_defaults VALUES
    ('landscaping',    'biweekly',   14,   ARRAY[12,1,2,3],          'Biweekly lawn and property care'),
    ('pool_service',   'weekly',     7,    ARRAY[11,12,1,2,3],       'Weekly pool maintenance'),
    ('pest_control',   'quarterly',  90,   NULL,                      'Quarterly pest treatment'),
    ('cleaning',       'biweekly',   14,   NULL,                      'Biweekly house cleaning'),
    ('hvac',           'semiannual', 180,  NULL,                      'Seasonal HVAC inspection'),
    ('septic',         'annual',     365,  NULL,                      'Annual septic service'),
    ('snow_removal',   'custom_days', NULL, ARRAY[4,5,6,7,8,9,10],   'Snow removal on storm events'),
    ('chimney',        'annual',     365,  NULL,                      'Annual chimney cleaning'),
    ('gutter_cleaning','semiannual', 180,  NULL,                      'Spring and fall gutter cleaning'),
    ('trash_pickup',   'weekly',     7,    NULL,                      'Weekly trash pickup')
ON CONFLICT (category_key) DO NOTHING;

-- ============================================================================
-- 4. Amend maintenance_tasks — link tasks to standing appointments
-- ============================================================================
ALTER TABLE maintenance_tasks
    ADD COLUMN IF NOT EXISTS standing_appointment_id UUID REFERENCES standing_appointments(id);

CREATE INDEX IF NOT EXISTS idx_tasks_standing_appointment
    ON maintenance_tasks(standing_appointment_id)
    WHERE standing_appointment_id IS NOT NULL;

-- ============================================================================
-- 5. RLS — household scoping via get_my_household_id()
-- ============================================================================
ALTER TABLE standing_appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE standing_appointment_visits ENABLE ROW LEVEL SECURITY;
ALTER TABLE category_cadence_defaults ENABLE ROW LEVEL SECURITY;

-- standing_appointments: full CRUD scoped to household
CREATE POLICY "standing_appointments_select"
    ON standing_appointments FOR SELECT TO authenticated
    USING (household_id = public.get_my_household_id());

CREATE POLICY "standing_appointments_insert"
    ON standing_appointments FOR INSERT TO authenticated
    WITH CHECK (household_id = public.get_my_household_id());

CREATE POLICY "standing_appointments_update"
    ON standing_appointments FOR UPDATE TO authenticated
    USING (household_id = public.get_my_household_id());

CREATE POLICY "standing_appointments_delete"
    ON standing_appointments FOR DELETE TO authenticated
    USING (household_id = public.get_my_household_id());

-- standing_appointment_visits: access through parent's household
CREATE POLICY "standing_appointment_visits_select"
    ON standing_appointment_visits FOR SELECT TO authenticated
    USING (
        standing_appointment_id IN (
            SELECT id FROM standing_appointments
            WHERE household_id = public.get_my_household_id()
        )
    );

CREATE POLICY "standing_appointment_visits_insert"
    ON standing_appointment_visits FOR INSERT TO authenticated
    WITH CHECK (
        standing_appointment_id IN (
            SELECT id FROM standing_appointments
            WHERE household_id = public.get_my_household_id()
        )
    );

CREATE POLICY "standing_appointment_visits_update"
    ON standing_appointment_visits FOR UPDATE TO authenticated
    USING (
        standing_appointment_id IN (
            SELECT id FROM standing_appointments
            WHERE household_id = public.get_my_household_id()
        )
    );

CREATE POLICY "standing_appointment_visits_delete"
    ON standing_appointment_visits FOR DELETE TO authenticated
    USING (
        standing_appointment_id IN (
            SELECT id FROM standing_appointments
            WHERE household_id = public.get_my_household_id()
        )
    );

-- category_cadence_defaults: read-only for all authenticated users
CREATE POLICY "category_cadence_defaults_select"
    ON category_cadence_defaults FOR SELECT TO authenticated
    USING (true);

-- Service role needs full access for cron functions
CREATE POLICY "standing_appointments_service"
    ON standing_appointments FOR ALL TO service_role
    USING (true) WITH CHECK (true);

CREATE POLICY "standing_appointment_visits_service"
    ON standing_appointment_visits FOR ALL TO service_role
    USING (true) WITH CHECK (true);

-- ============================================================================
-- 6. GRANTs
-- ============================================================================
GRANT SELECT, INSERT, UPDATE, DELETE ON public.standing_appointments TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.standing_appointment_visits TO authenticated;
GRANT SELECT ON public.category_cadence_defaults TO authenticated;
GRANT ALL ON public.standing_appointments TO service_role;
GRANT ALL ON public.standing_appointment_visits TO service_role;
GRANT ALL ON public.category_cadence_defaults TO service_role;
