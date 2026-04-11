-- Phase 50: Add per-system service interval override.
--
-- The maintenance reconciler uses a template's `interval` to compute
-- next-due dates for every task on a system. That works for the
-- canonical case but breaks when a household's actual cadence differs
-- from the template default — e.g. weekly pool service, biweekly lawn
-- mowing, every-3-weeks pest control.
--
-- This migration adds a single integer override on `home_systems` so
-- one value can drive every task attached to the system. The companion
-- `service_interval_source` text column captures provenance so the UI
-- can show the user where the value came from ("Set from invoice on
-- April 15") and allow opting back to the template default.
--
-- Sources:
--   - "default"        : no override, fall back to template frequency
--   - "onboarding"     : captured by the post-quiz cadence sheet
--   - "vendor_invoice" : extracted by process-invoice cadence detection
--   - "manual"         : set by the system detail frequency editor
--
-- Both columns are nullable / defaultable so existing rows round-trip
-- through the build without any backfill.

ALTER TABLE home_systems
  ADD COLUMN IF NOT EXISTS service_interval_days integer,
  ADD COLUMN IF NOT EXISTS service_interval_source text DEFAULT 'default';

COMMENT ON COLUMN home_systems.service_interval_days IS
  'Phase 50: Override service interval in days. Nil means use the template default. Captured from onboarding, invoice cadence detection, or the system detail frequency editor.';

COMMENT ON COLUMN home_systems.service_interval_source IS
  'Phase 50: Provenance for service_interval_days. One of: default, onboarding, vendor_invoice, manual. Used to render the source caption in the system detail UI.';
