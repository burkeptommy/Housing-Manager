-- Add user_preference column to track keep/remove decisions on design items
ALTER TABLE project_line_items
  ADD COLUMN IF NOT EXISTS user_preference TEXT CHECK (user_preference IN ('kept', 'removed', 'swapped'));

-- Index for filtering by preference
CREATE INDEX IF NOT EXISTS idx_line_items_user_preference ON project_line_items(project_id, user_preference) WHERE user_preference IS NOT NULL;
