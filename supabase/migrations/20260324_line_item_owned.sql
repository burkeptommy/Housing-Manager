-- Add is_owned column to project_line_items
-- Additive migration — no existing columns modified.
ALTER TABLE project_line_items ADD COLUMN IF NOT EXISTS is_owned BOOLEAN DEFAULT false;
