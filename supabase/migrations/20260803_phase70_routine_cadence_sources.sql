-- ============================================================================
-- Phase 70: Expand routine cadence_source provenance values.
--
-- The app now persists routines created from several newer entry points:
--   - auto_seeded   : seeded from provider / system defaults
--   - quiz          : collected during onboarding
--   - smart_setup   : completed from smart setup cards in Maintenance
--
-- The original routines schema only allowed the older provenance values,
-- so inserts from these newer flows fail against routines_cadence_source_check.
-- ============================================================================

ALTER TABLE public.routines
  DROP CONSTRAINT IF EXISTS routines_cadence_source_check;

ALTER TABLE public.routines
  ADD CONSTRAINT routines_cadence_source_check
  CHECK (cadence_source IS NULL OR cadence_source IN (
    'ai_inferred',
    'category_default',
    'user_set',
    'migrated_cadence',
    'migrated_appointment',
    'auto_seeded',
    'quiz',
    'smart_setup'
  ));
