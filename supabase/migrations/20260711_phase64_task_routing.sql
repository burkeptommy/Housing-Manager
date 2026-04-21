-- Phase 64: Three-option routing model.
--
-- Adds `assigned_route` TEXT to `maintenance_tasks` to persist the user's
-- routing choice per task. Values: 'vendor' | 'handyman' | 'diy' | NULL.
-- NULL means the picker should surface on the task because neither a
-- routing preference (Phase 65) nor a default rule has resolved it.
--
-- Also unifies Phase 54B's `handyman_punch_items` with tasks via a new
-- `maintenance_task_id` FK. When `assigned_route = 'handyman'`, the task
-- is the source of truth and a punch item row is the surface that the
-- HandymanPunchListView renders. On route change away from handyman the
-- punch item archives; on re-route back it rematerializes.
--
-- Backfill rules for existing rows:
--   assignment_type = 'personal'  → assigned_route = 'diy'
--   assignment_type = 'vendor'    → assigned_route = 'vendor'
--   assignment_type = 'either'    → NULL (let the app's defaulter pick)
--
-- Existing tasks with an assigned_contractor_id keep 'vendor' regardless.

ALTER TABLE maintenance_tasks
  ADD COLUMN IF NOT EXISTS assigned_route TEXT;

-- Backfill from assignment_type.
UPDATE maintenance_tasks
   SET assigned_route = CASE
       WHEN assigned_contractor_id IS NOT NULL THEN 'vendor'
       WHEN assignment_type = 'personal' THEN 'diy'
       WHEN assignment_type = 'vendor' THEN 'vendor'
       ELSE NULL
   END
 WHERE assigned_route IS NULL;

CREATE INDEX IF NOT EXISTS idx_maintenance_tasks_assigned_route
  ON maintenance_tasks (household_id, assigned_route)
  WHERE assigned_route IS NOT NULL;

-- Unify punch items with tasks. The existing source_task_id column
-- (Phase 54B's "optional FK" shape) carries most of the data already —
-- this adds the canonical FK name and backfills from source_task_id.
ALTER TABLE handyman_punch_items
  ADD COLUMN IF NOT EXISTS maintenance_task_id UUID REFERENCES maintenance_tasks(id) ON DELETE CASCADE;

UPDATE handyman_punch_items
   SET maintenance_task_id = source_task_id
 WHERE maintenance_task_id IS NULL AND source_task_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_handyman_punch_items_task
  ON handyman_punch_items (maintenance_task_id)
  WHERE maintenance_task_id IS NOT NULL;
