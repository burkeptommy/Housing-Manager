-- Add covered drivers array for insurance-based driver tracking
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS covered_driver_ids UUID[] DEFAULT '{}';
