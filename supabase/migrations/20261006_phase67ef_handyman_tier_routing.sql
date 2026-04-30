-- Phase 67E/F: handyman single-rail routing.
--
-- Adds `source_template_key` to `handyman_punch_items` so the reconciler
-- can dedupe handyman-tier rows by templateKey ("Plumbing:Test sump pump
-- battery backup", etc.) without creating a corresponding `maintenance_
-- tasks` row. The existing `template_id` UUID column references
-- `task_proposals` (Phase 78) — `source_template_key` is a separate
-- string FK to the in-app template library, used only by the seeded /
-- migrated routing path.
--
-- Reconciler flow (in MaintenanceTaskReconciler.reconcile):
--   1. Load `existingPunchItemTemplateKeys` (Set<String>) from this
--      household's pending rows.
--   2. For each standalone template, if `isHandymanTier` (no safety
--      floor, no bundleId, routingOverride .diyDefault/.diyCapable,
--      diyEffortMinutes ≤ 60) AND its templateKey isn't already in the
--      set, INSERT a punch item with source = "auto_seed_handyman_tier"
--      and source_template_key = templateKey. Skip the maintenance_tasks
--      insert.
--
-- Migration paths that also write source_template_key:
--   - migrateHandymanTierTasksToPunchItemsOnceIfNeeded (commit B4)
--   - addToPunchListJustThisTime / addToPunchListReassignSeries
--     (commit B7)
--
-- The PERMITTED `source` values stamped post-67E/F:
--   manual | recommended | maintenance_task (legacy) |
--   auto_seed_handyman_tier (new) | promoted_from_task (new) |
--   migrated_from_task (new)

alter table public.handyman_punch_items
  add column if not exists source_template_key text;

create index if not exists idx_handyman_punch_items_source_template_key
  on public.handyman_punch_items(household_id, source_template_key)
  where source_template_key is not null and archived_at is null;
