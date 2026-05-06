-- ============================================================================
-- Haven E2E handyman test — per-run cleanup
-- ============================================================================
--
-- Wipes every row produced by a handyman E2E test run so the next iteration
-- starts against a clean slate. Patterns:
--   - e2e-handyman-%@havenhome.test           (provider workspace owners + crew)
--   - e2e-customer-of-handyman-%@havenhome.test (test customer households)
--
-- Wipes both halves (handyman side + customer side) so a single run can
-- exercise the on-behalf-of relationship end-to-end and the next run starts
-- clean.
--
-- Runs inside a transaction. Verification SELECTs at the bottom should all
-- show zero matching rows after the script finishes.
-- ============================================================================

BEGIN;

-- 1. Identify the e2e test users by email pattern (BOTH the handyman and the
--    customer side).
WITH e2e_handyman_users AS (
  SELECT id, email FROM auth.users
  WHERE email LIKE 'e2e-handyman-%@havenhome.test'
),
e2e_customer_users AS (
  SELECT id, email FROM auth.users
  WHERE email LIKE 'e2e-customer-of-handyman-%@havenhome.test'
),
e2e_all_users AS (
  SELECT id FROM e2e_handyman_users
  UNION ALL
  SELECT id FROM e2e_customer_users
),
-- 2. The provider workspaces those handyman users own / are members of.
e2e_workspaces AS (
  SELECT DISTINCT m.workspace_id AS id
  FROM public.provider_workspace_members m
  WHERE m.user_id IN (SELECT id FROM e2e_handyman_users)
),
-- 3. The customer households (transitive via public.users).
e2e_households AS (
  SELECT DISTINCT u.household_id AS id
  FROM public.users u
  WHERE u.id IN (SELECT id FROM e2e_customer_users)
    AND u.household_id IS NOT NULL
)
SELECT
  (SELECT count(*) FROM e2e_handyman_users)  AS handyman_users_to_delete,
  (SELECT count(*) FROM e2e_customer_users)  AS customer_users_to_delete,
  (SELECT count(*) FROM e2e_workspaces)      AS workspaces_to_delete,
  (SELECT count(*) FROM e2e_households)      AS customer_households_to_delete;

-- 4. Wipe handyman-side rows tied to the test workspaces (provider side).
DELETE FROM public.provider_visit_assignments
  WHERE workspace_id IN (
    SELECT m.workspace_id FROM public.provider_workspace_members m
    WHERE m.user_id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-handyman-%@havenhome.test')
  );

DELETE FROM public.provider_quotes
  WHERE workspace_id IN (
    SELECT m.workspace_id FROM public.provider_workspace_members m
    WHERE m.user_id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-handyman-%@havenhome.test')
  );

DELETE FROM public.provider_saved_quote_items
  WHERE workspace_id IN (
    SELECT m.workspace_id FROM public.provider_workspace_members m
    WHERE m.user_id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-handyman-%@havenhome.test')
  );

DELETE FROM public.provider_contractor_links
  WHERE workspace_id IN (
    SELECT m.workspace_id FROM public.provider_workspace_members m
    WHERE m.user_id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-handyman-%@havenhome.test')
  );

DELETE FROM public.provider_workspace_members
  WHERE workspace_id IN (
    SELECT m.workspace_id FROM public.provider_workspace_members m
    WHERE m.user_id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-handyman-%@havenhome.test')
  );

DELETE FROM public.provider_workspaces
  WHERE id IN (
    SELECT m.workspace_id FROM public.provider_workspace_members m
    WHERE m.user_id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-handyman-%@havenhome.test')
  )
  OR company_name LIKE 'E2E Handyman%'
  OR company_name LIKE 'E2E Probe%';

-- 5. Wipe customer-side household-scoped rows. These are the same patterns
--    as cleanup.sql (mirror that script for the customer households).
DELETE FROM public.maintenance_tasks
  WHERE household_id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-customer-of-handyman-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

DELETE FROM public.handyman_punch_items
  WHERE household_id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-customer-of-handyman-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

DELETE FROM public.handyman_request_messages
  WHERE household_id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-customer-of-handyman-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

DELETE FROM public.handyman_requests
  WHERE household_id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-customer-of-handyman-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

DELETE FROM public.routines
  WHERE household_id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-customer-of-handyman-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

DELETE FROM public.contractors
  WHERE household_id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-customer-of-handyman-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

DELETE FROM public.utility_accounts
  WHERE household_id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-customer-of-handyman-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

DELETE FROM public.home_systems
  WHERE household_id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-customer-of-handyman-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

DELETE FROM public.vehicles
  WHERE household_id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-customer-of-handyman-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

DELETE FROM public.family_members
  WHERE household_id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-customer-of-handyman-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

DELETE FROM public.concierge_messages
  WHERE household_id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-customer-of-handyman-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

DELETE FROM public.chez_requests
  WHERE household_id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-customer-of-handyman-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

DELETE FROM public.inbox_items
  WHERE household_id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-customer-of-handyman-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

DELETE FROM public.home_assessments
  WHERE household_id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-customer-of-handyman-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

DELETE FROM public.properties
  WHERE household_id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-customer-of-handyman-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

UPDATE public.users SET household_id = NULL
  WHERE id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-customer-of-handyman-%@havenhome.test');

DELETE FROM public.households
  WHERE id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-customer-of-handyman-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

-- 6. Drop the public.users rows (handyman + customer) and finally the auth rows.
DELETE FROM public.users
  WHERE id IN (
    SELECT id FROM auth.users
    WHERE email LIKE 'e2e-handyman-%@havenhome.test'
       OR email LIKE 'e2e-customer-of-handyman-%@havenhome.test'
  );

DELETE FROM auth.users
  WHERE email LIKE 'e2e-handyman-%@havenhome.test'
     OR email LIKE 'e2e-customer-of-handyman-%@havenhome.test';

COMMIT;

-- Post-cleanup verification — every row should be 0.
SELECT 'auth.users handyman remaining'   AS check, count(*) AS n FROM auth.users WHERE email LIKE 'e2e-handyman-%@havenhome.test'
UNION ALL SELECT 'auth.users customer remaining', count(*) FROM auth.users WHERE email LIKE 'e2e-customer-of-handyman-%@havenhome.test'
UNION ALL SELECT 'provider_workspaces orphaned', count(*) FROM public.provider_workspaces WHERE company_name LIKE 'E2E Handyman%' OR company_name LIKE 'E2E Probe%'
UNION ALL SELECT 'provider_workspace_members orphaned', count(*) FROM public.provider_workspace_members WHERE email LIKE 'e2e-handyman-%@havenhome.test';
