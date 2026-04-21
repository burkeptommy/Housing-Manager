-- Phase 54E.4: Defensive unique index so concurrent reconciler runs
-- can't re-introduce the template-keyed duplicates that 20260607 just
-- cleaned up.
--
-- Scope: one active (non-archived) task per (property_id, template_id).
-- Recurring tasks are updated in place (last_completed_date +
-- next_due_date bump) rather than cycled into new rows, so this
-- invariant matches the Phase 19k / 54A reconciler design.
--
-- template_id is null for custom user tasks and for vehicle tasks
-- created ad hoc; those are excluded from the guard via the WHERE
-- clause. Archived rows are also excluded so a completed-and-archived
-- task doesn't block its successor from re-seeding.
--
-- Future reconciler inserts that would collide on this key fail with
-- a unique violation instead of silently creating duplicates. Callers
-- already wrap inserts in `try?` or catch blocks, so the collision
-- surfaces as a no-op rather than a crash — matching the home_systems
-- uniqueness-guard pattern (20260606).
create unique index if not exists uniq_maintenance_tasks_property_template
    on public.maintenance_tasks (property_id, template_id)
    where template_id is not null
      and is_archived = false
      and property_id is not null;
