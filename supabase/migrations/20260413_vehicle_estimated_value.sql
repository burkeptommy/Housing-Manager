-- Cached current-value estimate for vehicles. Initially populated by Claude
-- (see supabase/functions/vehicle-value), upgradable to VinAudit/MarketCheck
-- later without UI changes.

ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS estimated_value NUMERIC;
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS estimated_value_low NUMERIC;
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS estimated_value_high NUMERIC;
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS estimated_value_updated_at TIMESTAMPTZ;
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS estimated_value_source TEXT;
