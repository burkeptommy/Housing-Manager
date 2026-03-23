-- Phase 17: Add assigned_to column to maintenance_tasks
ALTER TABLE maintenance_tasks ADD COLUMN IF NOT EXISTS assigned_to UUID REFERENCES family_members(id);
