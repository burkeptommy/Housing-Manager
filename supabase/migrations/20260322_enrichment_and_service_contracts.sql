-- Phase 1: Home Profile Enrichment
-- Adds property attributes JSONB column and service_contracts table

-- A. Property attributes (roof material, siding material, water source, etc.)
ALTER TABLE properties ADD COLUMN IF NOT EXISTS attributes JSONB DEFAULT '{}';

-- B. Service contracts (pest control, landscaping, pool service, cleaning, etc.)
CREATE TABLE IF NOT EXISTS service_contracts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID REFERENCES properties(id) ON DELETE CASCADE NOT NULL,
    household_id UUID REFERENCES households(id) NOT NULL,
    service_type TEXT NOT NULL,
    provider_name TEXT,
    contractor_id UUID REFERENCES contractors(id) ON DELETE SET NULL,
    frequency TEXT,
    details JSONB DEFAULT '{}',
    annual_cost DECIMAL,
    start_date DATE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE service_contracts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view household service contracts"
    ON service_contracts FOR SELECT
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can insert household service contracts"
    ON service_contracts FOR INSERT
    WITH CHECK (household_id = public.get_my_household_id());

CREATE POLICY "Users can update household service contracts"
    ON service_contracts FOR UPDATE
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can delete household service contracts"
    ON service_contracts FOR DELETE
    USING (household_id = public.get_my_household_id());

CREATE INDEX IF NOT EXISTS idx_service_contracts_household ON service_contracts(household_id);
CREATE INDEX IF NOT EXISTS idx_service_contracts_property ON service_contracts(property_id);
