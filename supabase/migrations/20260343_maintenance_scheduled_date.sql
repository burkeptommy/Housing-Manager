-- Add scheduled_date column to maintenance_tasks for recording when a task has been scheduled
ALTER TABLE maintenance_tasks ADD COLUMN IF NOT EXISTS scheduled_date DATE;
