-- ============================================================================
-- Haven E2E onboarding test — per-run cleanup
-- ============================================================================
--
-- Wipes every row produced by an e2e test run so the next iteration starts
-- against a clean slate. Matches the same email pattern the runner uses when
-- creating its synthetic user (`e2e-test-<timestamp>@havenhome.test`) so we
-- never touch a real human's data even if the dev project has live records
-- alongside the test data.
--
-- Runs inside a transaction. Verification SELECTs at the bottom should all
-- show zero matching rows after the script finishes.
-- ============================================================================

BEGIN;

-- 1. Identify the e2e test users by email pattern.
WITH e2e_users AS (
  SELECT id, email FROM auth.users
  WHERE email LIKE 'e2e-%@havenhome.test'
),
-- 2. The households those users belong to (transitively, via public.users).
e2e_households AS (
  SELECT DISTINCT u.household_id AS id
  FROM public.users u
  WHERE u.id IN (SELECT id FROM e2e_users)
    AND u.household_id IS NOT NULL
)

-- Snapshot what's about to be deleted so the post-script verification can run.
SELECT
  (SELECT count(*) FROM e2e_users)        AS auth_users_to_delete,
  (SELECT count(*) FROM e2e_households)   AS households_to_delete;

-- 3. Wipe every household-scoped row first (FK cascades will catch most, but
--    being explicit is safer in case any FK is ON DELETE SET NULL).
DELETE FROM public.maintenance_tasks
  WHERE household_id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

DELETE FROM public.handyman_punch_items
  WHERE household_id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

DELETE FROM public.routines
  WHERE household_id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

-- Home systems and vehicles can point at contractors via preferred vendor
-- columns. Delete those owners before contractors so a full UI vendor
-- assignment run does not leave cleanup blocked on FK restrictions.
DELETE FROM public.home_systems
  WHERE household_id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

DELETE FROM public.vehicles
  WHERE household_id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

DELETE FROM public.contractors
  WHERE household_id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

DELETE FROM public.utility_accounts
  WHERE household_id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

DELETE FROM public.family_members
  WHERE household_id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

DELETE FROM public.concierge_messages
  WHERE household_id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

DELETE FROM public.chez_requests
  WHERE household_id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

DELETE FROM public.inbox_items
  WHERE household_id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

-- home_assessments references properties/households — wipe before properties.
DELETE FROM public.home_assessments
  WHERE household_id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

DELETE FROM public.properties
  WHERE household_id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

-- 4. Detach public.users from their households (don't delete the user yet —
--    we delete via auth.users which cascades).
UPDATE public.users SET household_id = NULL
  WHERE id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-%@havenhome.test');

-- 5. Delete the households (no rows reference them now).
DELETE FROM public.households
  WHERE id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

-- 6. Delete the public.users rows for the test users (auth.users delete will
--    cascade to identities/sessions/etc. but public.users is its own table
--    and may not cascade — wipe explicitly).
DELETE FROM public.users
  WHERE id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-%@havenhome.test');

-- 7. Finally drop the auth.users rows (cascades to identities, sessions,
--    refresh_tokens, mfa_*).
DELETE FROM auth.users
  WHERE email LIKE 'e2e-%@havenhome.test';

COMMIT;

-- Post-cleanup verification — every row should be 0.
SELECT 'auth.users remaining'   AS check, count(*) AS n FROM auth.users WHERE email LIKE 'e2e-%@havenhome.test'
UNION ALL SELECT 'public.users remaining', count(*) FROM public.users WHERE email LIKE 'e2e-%@havenhome.test'
UNION ALL SELECT 'households orphaned', count(*) FROM public.households WHERE name LIKE 'The E2E%' OR name LIKE 'The UI%';
