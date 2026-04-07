-- Phase 17b: soft-delete columns for maintenance_tasks so the post-quiz
-- reconciler can prune subtype-mismatched tasks without losing history.
-- Tasks the user has touched (completed, reassigned, annotated, etc.) are
-- still preserved in code; this gives the reconciler a safe deletion path
-- for the rest.

ALTER TABLE maintenance_tasks
    ADD COLUMN IF NOT EXISTS is_archived BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS archived_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS archived_reason TEXT;

-- Active task index — most reads filter by household + active so this is the
-- hot path. Existing idx_maintenance_tasks_household stays as a fallback.
CREATE INDEX IF NOT EXISTS idx_maintenance_tasks_active
    ON maintenance_tasks (household_id, is_archived)
    WHERE is_archived = false;
