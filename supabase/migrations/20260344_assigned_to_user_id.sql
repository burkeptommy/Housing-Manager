-- Add assigned_to_user_id column to maintenance_tasks for task assignment
-- References users(id) since household members assign tasks to each other
ALTER TABLE maintenance_tasks ADD COLUMN IF NOT EXISTS assigned_to_user_id UUID REFERENCES users(id);
