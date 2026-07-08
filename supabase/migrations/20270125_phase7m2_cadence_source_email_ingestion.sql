-- Phase 7 M2 (Ingestion Intelligence v2) — routines from ingestion.
--
-- Routines created by applying a "standing arrangement" row on the
-- suggested-actions review card (email forward or document upload) stamp
-- cadence_source = 'email_ingestion'. Supersedes the 20260803 CHECK by
-- re-creating it with the new value appended.

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
    'smart_setup',
    'email_ingestion'
  ));
