-- Phase 67 (reconciler v2 — C1): home_systems.needs_vendor_coverage
--
-- Set by `MaintenanceTaskReconciler` when a vendor-required template
-- targets a system but no matching contractor exists in the household.
-- Replaces the old behavior of seeding a "Find a contractor for X"
-- maintenance_tasks row per gap. `VendorCoverageSheet` reads this flag
-- to surface the consolidated gap card on the dashboard.
--
-- Default false. Cleared back to false when:
--   * a contractor in the matching category is added (handled in
--     ContractorService.create + the household-wide refresh after
--     vendor delegation flows complete)
--   * the homeowner dismisses the gap via the existing
--     `dismissed_categories` table (consumed at read time, not write)

alter table public.home_systems
  add column if not exists needs_vendor_coverage boolean not null default false;

-- Lookup index for the dashboard's gap-count read in VendorCoverageSheet.
create index if not exists idx_home_systems_needs_vendor_coverage
  on public.home_systems(household_id, property_id)
  where needs_vendor_coverage = true and archived_at is null;
