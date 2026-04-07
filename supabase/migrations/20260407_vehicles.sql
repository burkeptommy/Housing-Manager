-- Phase 41a: Vehicle Management
-- Additive migration — no existing tables modified except documents (nullable FK added).

-- ============================================================================
-- Vehicles (household-scoped, NOT property-scoped)
-- ============================================================================
CREATE TABLE IF NOT EXISTS vehicles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,

    -- Vehicle identity
    name TEXT NOT NULL,
    year INT,
    make TEXT,
    model TEXT,
    trim TEXT,
    color TEXT,
    vin TEXT,
    license_plate TEXT,

    -- Status
    current_mileage INT,
    ownership_type TEXT DEFAULT 'owned',
    purchase_date DATE,
    purchase_price DECIMAL(12,2),
    current_value DECIMAL(12,2),
    lease_end_date DATE,
    loan_payoff_date DATE,

    -- Key dates
    registration_expiry DATE,
    inspection_expiry DATE,

    -- Relationships
    primary_driver_id UUID REFERENCES family_members(id) ON DELETE SET NULL,
    preferred_mechanic_id UUID REFERENCES contractors(id) ON DELETE SET NULL,

    -- AI-generated maintenance schedule
    maintenance_schedule JSONB DEFAULT '[]',

    -- Photo
    photo_path TEXT,

    -- Meta
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- Vehicle Service Records
-- ============================================================================
CREATE TABLE IF NOT EXISTS vehicle_service_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,

    service_date DATE NOT NULL,
    service_type TEXT NOT NULL,
    description TEXT NOT NULL,
    cost DECIMAL(10,2),
    mileage_at_service INT,

    contractor_id UUID REFERENCES contractors(id) ON DELETE SET NULL,
    invoice_document_id UUID REFERENCES documents(id) ON DELETE SET NULL,

    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- Vehicle Recalls (cached from NHTSA)
-- ============================================================================
CREATE TABLE IF NOT EXISTS vehicle_recalls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,

    nhtsa_campaign_number TEXT,
    component TEXT,
    summary TEXT,
    consequence TEXT,
    remedy TEXT,
    recall_date DATE,

    is_resolved BOOLEAN DEFAULT false,
    resolved_date DATE,
    resolved_service_record_id UUID REFERENCES vehicle_service_records(id) ON DELETE SET NULL,

    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- Add vehicle_id to documents table
-- ============================================================================
ALTER TABLE documents ADD COLUMN IF NOT EXISTS vehicle_id UUID REFERENCES vehicles(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_documents_vehicle ON documents(vehicle_id);

-- ============================================================================
-- Indexes
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_vehicles_household ON vehicles(household_id);
CREATE INDEX IF NOT EXISTS idx_vehicles_vin ON vehicles(vin);
CREATE INDEX IF NOT EXISTS idx_vehicle_service_records_vehicle ON vehicle_service_records(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_vehicle_service_records_household ON vehicle_service_records(household_id);
CREATE INDEX IF NOT EXISTS idx_vehicle_recalls_vehicle ON vehicle_recalls(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_vehicle_recalls_household ON vehicle_recalls(household_id);

-- ============================================================================
-- RLS
-- ============================================================================
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicle_service_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicle_recalls ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view household vehicles"
    ON vehicles FOR SELECT USING (household_id = public.get_my_household_id());
CREATE POLICY "Users can insert household vehicles"
    ON vehicles FOR INSERT WITH CHECK (household_id = public.get_my_household_id());
CREATE POLICY "Users can update household vehicles"
    ON vehicles FOR UPDATE USING (household_id = public.get_my_household_id());
CREATE POLICY "Users can delete household vehicles"
    ON vehicles FOR DELETE USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can view household vehicle service records"
    ON vehicle_service_records FOR SELECT USING (household_id = public.get_my_household_id());
CREATE POLICY "Users can insert household vehicle service records"
    ON vehicle_service_records FOR INSERT WITH CHECK (household_id = public.get_my_household_id());
CREATE POLICY "Users can update household vehicle service records"
    ON vehicle_service_records FOR UPDATE USING (household_id = public.get_my_household_id());
CREATE POLICY "Users can delete household vehicle service records"
    ON vehicle_service_records FOR DELETE USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can view household vehicle recalls"
    ON vehicle_recalls FOR SELECT USING (household_id = public.get_my_household_id());
CREATE POLICY "Users can insert household vehicle recalls"
    ON vehicle_recalls FOR INSERT WITH CHECK (household_id = public.get_my_household_id());
CREATE POLICY "Users can update household vehicle recalls"
    ON vehicle_recalls FOR UPDATE USING (household_id = public.get_my_household_id());
CREATE POLICY "Users can delete household vehicle recalls"
    ON vehicle_recalls FOR DELETE USING (household_id = public.get_my_household_id());
