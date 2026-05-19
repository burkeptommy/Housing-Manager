-- ============================================================================
-- Phase 85.8 — Add archive flag to households + sweep empty test data
-- ============================================================================
--
-- 240 of 248 households in the production DB right now are fully empty
-- test rows from automated signup/quiz/onboarding tests that never
-- completed. They have zero users, zero family members, zero properties,
-- zero systems, zero routines, zero tasks, zero vendors, zero cases,
-- zero messages. They clutter the Households list and the queue rail
-- with duplicate "The Tester Family" rows.
--
-- Strategy:
--   1. Add an archived_at column (matches the pattern used on routines,
--      home_systems, maintenance_tasks, handyman_punch_items).
--   2. Soft-archive every fully-empty household. Reversible — set
--      archived_at = NULL if a test ever turns out to be real.
--   3. Admin queries (households list + workbench + concierge embed)
--      filter on archived_at IS NULL going forward.
-- ============================================================================

-- 1. Schema.
ALTER TABLE public.households
  ADD COLUMN IF NOT EXISTS archived_at TIMESTAMPTZ;
ALTER TABLE public.households
  ADD COLUMN IF NOT EXISTS archive_reason TEXT;

CREATE INDEX IF NOT EXISTS idx_households_active
  ON public.households(created_at DESC)
  WHERE archived_at IS NULL;

-- 2. Sweep. Every household with zero of every entity gets archived.
-- We're explicit about the conditions so a future audit can re-run this
-- query and see exactly what we collapsed.
UPDATE public.households h
SET archived_at = now(),
    archive_reason = 'empty_test_data_sweep_2026_05_18'
WHERE archived_at IS NULL
  AND (SELECT count(*) FROM public.users u            WHERE u.household_id = h.id) = 0
  AND (SELECT count(*) FROM public.family_members fm  WHERE fm.household_id = h.id) = 0
  AND (SELECT count(*) FROM public.properties p       WHERE p.household_id = h.id) = 0
  AND (SELECT count(*) FROM public.home_systems s     WHERE s.household_id = h.id) = 0
  AND (SELECT count(*) FROM public.routines r         WHERE r.household_id = h.id) = 0
  AND (SELECT count(*) FROM public.maintenance_tasks t WHERE t.household_id = h.id) = 0
  AND (SELECT count(*) FROM public.contractors c      WHERE c.household_id = h.id) = 0
  AND (SELECT count(*) FROM public.chez_requests cr   WHERE cr.household_id = h.id) = 0
  AND (SELECT count(*) FROM public.concierge_messages cm WHERE cm.household_id = h.id) = 0;

-- 3. Also archive partial-test rows: households with at most ONE family
-- member, no property, no users, no entities, no cases, no messages.
-- These are abandoned signups from early May that never made it past
-- the first quiz screen.
UPDATE public.households h
SET archived_at = now(),
    archive_reason = 'abandoned_signup_sweep_2026_05_18'
WHERE archived_at IS NULL
  AND (SELECT count(*) FROM public.users u            WHERE u.household_id = h.id) = 0
  AND (SELECT count(*) FROM public.properties p       WHERE p.household_id = h.id) = 0
  AND (SELECT count(*) FROM public.home_systems s     WHERE s.household_id = h.id) = 0
  AND (SELECT count(*) FROM public.routines r         WHERE r.household_id = h.id) = 0
  AND (SELECT count(*) FROM public.maintenance_tasks t WHERE t.household_id = h.id) = 0
  AND (SELECT count(*) FROM public.contractors c      WHERE c.household_id = h.id) = 0
  AND (SELECT count(*) FROM public.chez_requests cr   WHERE cr.household_id = h.id) = 0
  AND (SELECT count(*) FROM public.concierge_messages cm WHERE cm.household_id = h.id) = 0
  AND (SELECT count(*) FROM public.family_members fm  WHERE fm.household_id = h.id) <= 1;

COMMENT ON COLUMN public.households.archived_at IS
'Phase 85.8: soft-archive flag. Households filtered out of the admin
list + workbench when this is not null. Reversible: set to NULL to
restore.';
