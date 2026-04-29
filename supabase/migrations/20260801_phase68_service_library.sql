-- ============================================================================
-- Phase 68: Canonical vendor-orchestration service identifiers.
--
-- Adds app-level stable keys for the new repo-managed service library:
--   - maintenance_tasks.service_key
--   - routines.service_key
--   - routine_visits.visit_type_key
--
-- Existing template_id / routine_kind remain in place for compatibility.
-- The application backfills and maintains these keys from the new
-- ServiceLibrary + ServiceOrchestrator.
-- ============================================================================

ALTER TABLE public.maintenance_tasks
  ADD COLUMN IF NOT EXISTS service_key TEXT;

ALTER TABLE public.routines
  ADD COLUMN IF NOT EXISTS service_key TEXT;

ALTER TABLE public.routine_visits
  ADD COLUMN IF NOT EXISTS visit_type_key TEXT;

CREATE INDEX IF NOT EXISTS idx_maintenance_tasks_service_key
  ON public.maintenance_tasks (household_id, service_key)
  WHERE service_key IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_routines_service_key
  ON public.routines (household_id, service_key)
  WHERE service_key IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_routine_visits_visit_type_key
  ON public.routine_visits (routine_id, visit_type_key)
  WHERE visit_type_key IS NOT NULL;
