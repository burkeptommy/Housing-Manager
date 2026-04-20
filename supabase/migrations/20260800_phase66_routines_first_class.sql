-- ============================================================================
-- Phase 66: Routines as first-class Services primitive
--
-- This migration ships the "Services" and "Vehicle Programs" user-facing
-- concepts entirely on top of the existing `routines` (Phase 55.1) and
-- `routine_visits` tables. No new tables — the plan evaluation
-- (/Users/tomburke/.claude/plans/users-tomburke-downloads-files-2-phase-logical-robin.md)
-- documents why the proposed `household_services` + `service_visits` +
-- `vehicle_service_programs` tables would duplicate 85% of routines.
--
-- Adds:
--  1. Service lifecycle: setup_state (draft / pending_vendor / active / paused /
--     archived) + optional service_contract_id FK.
--  2. Vehicle scope: scope (property / vehicle) + vehicle_id + program_mode
--     (shop_managed / self_managed).
--  3. Visit state machine on routine_visits: visit_state + target window.
--  4. Task-to-routine link: maintenance_tasks.parent_routine_id +
--     bundle_parent_task_id (promotes Phase 54A bundleId pattern to runtime).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Routines gain service lifecycle
-- ----------------------------------------------------------------------------

ALTER TABLE routines
  ADD COLUMN IF NOT EXISTS setup_state TEXT NOT NULL DEFAULT 'active'
    CHECK (setup_state IN ('draft', 'pending_vendor', 'active', 'paused', 'archived'));

-- Existing rows auto-migrate to 'active' via DEFAULT. The Phase 55 is_paused
-- flag remains the primary "paused" signal; setup_state='paused' is
-- intentionally NOT mirrored from is_paused so the two columns can represent
-- different things in the future (e.g. a paused service vs a draft one).

ALTER TABLE routines
  ADD COLUMN IF NOT EXISTS service_contract_id UUID
    REFERENCES service_contracts(id) ON DELETE SET NULL;

-- ----------------------------------------------------------------------------
-- 2. Routines gain vehicle scope (Phase 67-equivalent)
-- ----------------------------------------------------------------------------

ALTER TABLE routines
  ADD COLUMN IF NOT EXISTS scope TEXT NOT NULL DEFAULT 'property'
    CHECK (scope IN ('property', 'vehicle'));

ALTER TABLE routines
  ADD COLUMN IF NOT EXISTS vehicle_id UUID
    REFERENCES vehicles(id) ON DELETE CASCADE;

-- program_mode is only meaningful for scope='vehicle' routines. For property
-- routines it stays NULL. No CHECK constraint tying it to scope because we
-- allow future extension (e.g. property routines getting their own mode
-- enum later).
ALTER TABLE routines
  ADD COLUMN IF NOT EXISTS program_mode TEXT
    CHECK (program_mode IS NULL OR program_mode IN ('shop_managed', 'self_managed'));

-- Scope integrity: vehicle-scoped routines MUST have vehicle_id; property-scoped
-- routines MUST NOT. Named constraint so it can be dropped / altered later
-- without guessing Postgres's auto-generated name.
ALTER TABLE routines
  ADD CONSTRAINT routines_vehicle_scope_valid
    CHECK (
      (scope = 'vehicle' AND vehicle_id IS NOT NULL)
      OR
      (scope = 'property' AND vehicle_id IS NULL)
    );

-- One active program per vehicle. Multiple archived rows are fine (history).
-- Uses the same pattern as the proposed household_services_active_unique
-- partial index — partial-unique on the live lifecycle states so a user can
-- archive a vehicle program and create a fresh one.
CREATE UNIQUE INDEX IF NOT EXISTS idx_routines_one_active_per_vehicle
  ON routines (vehicle_id)
  WHERE scope = 'vehicle'
    AND setup_state IN ('draft', 'pending_vendor', 'active', 'paused');

-- One active handyman routine per property. Similar shape to vehicle uniqueness
-- — prevents the curator from accidentally creating two handyman containers
-- for the same property.
CREATE UNIQUE INDEX IF NOT EXISTS idx_routines_one_active_handyman_per_property
  ON routines (property_id, routine_kind)
  WHERE routine_kind IN ('handyman_recurring')
    AND scope = 'property'
    AND setup_state IN ('draft', 'pending_vendor', 'active', 'paused');

-- ----------------------------------------------------------------------------
-- 3. Routine visits gain scheduling state
-- ----------------------------------------------------------------------------

ALTER TABLE routine_visits
  ADD COLUMN IF NOT EXISTS visit_state TEXT NOT NULL DEFAULT 'planned'
    CHECK (visit_state IN ('planned', 'scheduled', 'in_progress', 'completed', 'cancelled', 'skipped'));

ALTER TABLE routine_visits
  ADD COLUMN IF NOT EXISTS target_window_start DATE;

ALTER TABLE routine_visits
  ADD COLUMN IF NOT EXISTS target_window_end DATE;

-- ----------------------------------------------------------------------------
-- 4. Tasks gain routine parent + bundle parent
-- ----------------------------------------------------------------------------

ALTER TABLE maintenance_tasks
  ADD COLUMN IF NOT EXISTS parent_routine_id UUID
    REFERENCES routines(id) ON DELETE SET NULL;

-- Bundle parent link — lets a runtime-grouped bundle parent reference another
-- maintenance_tasks row. This promotes the Phase 54A bundleId pattern from
-- template-authoring time (where bundleId is a string matched at reconcile
-- time) to runtime (where the parent row's id is directly referenced).
ALTER TABLE maintenance_tasks
  ADD COLUMN IF NOT EXISTS bundle_parent_task_id UUID
    REFERENCES maintenance_tasks(id) ON DELETE SET NULL;

-- ----------------------------------------------------------------------------
-- 5. Indexes
-- ----------------------------------------------------------------------------

-- Primary list query: visible tasks on the Maintenance tab's "This Season"
-- section. Hiding rule is: hide vendor-routed tasks whose parent routine is
-- active. DIY-default tasks stay visible even if they have a parent_routine_id
-- (the Day1TaskCurator routes them to the handyman routine so they surface
-- under "Next Handyman Visit" — not in This Season).
CREATE INDEX IF NOT EXISTS idx_maintenance_tasks_visible_primary_list
  ON maintenance_tasks (household_id, property_id)
  WHERE (is_archived IS NULL OR is_archived = false);

CREATE INDEX IF NOT EXISTS idx_maintenance_tasks_parent_routine
  ON maintenance_tasks (parent_routine_id)
  WHERE parent_routine_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_maintenance_tasks_bundle_parent
  ON maintenance_tasks (bundle_parent_task_id)
  WHERE bundle_parent_task_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_routines_setup_state
  ON routines (household_id, setup_state)
  WHERE archived_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_routines_scope_vehicle
  ON routines (household_id, scope)
  WHERE scope = 'vehicle' AND archived_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_routine_visits_scheduled
  ON routine_visits (routine_id, visit_state)
  WHERE visit_state IN ('planned', 'scheduled', 'in_progress');
