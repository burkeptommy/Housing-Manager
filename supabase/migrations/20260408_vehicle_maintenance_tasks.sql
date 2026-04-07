-- Phase 41c: Unified vehicle + home task system
-- Vehicle maintenance tasks stored in the same maintenance_tasks table

-- Add vehicle_id column
ALTER TABLE maintenance_tasks ADD COLUMN IF NOT EXISTS vehicle_id UUID REFERENCES vehicles(id) ON DELETE CASCADE;

-- Make property_id nullable (vehicle tasks don't have a property)
ALTER TABLE maintenance_tasks ALTER COLUMN property_id DROP NOT NULL;

-- Index for vehicle task lookups
CREATE INDEX IF NOT EXISTS idx_maintenance_tasks_vehicle ON maintenance_tasks(vehicle_id) WHERE vehicle_id IS NOT NULL;
