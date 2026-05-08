-- ============================================================================
-- Haven E2E contractor test — per-run cleanup
-- ============================================================================
--
-- Wipes every row produced by a contractor E2E test run so the next iteration
-- starts against a clean slate. Patterns:
--   - e2e-contractor-%@chezcontractor.test            (contractor workspace owners + crew)
--   - e2e-customer-of-contractor-%@havenhome.test     (test customer households)
--
-- Wipes both halves (contractor side + customer side).
-- Runs inside a transaction. Verification SELECTs at the bottom should all
-- show zero matching rows after the script finishes.
-- ============================================================================

BEGIN;

-- 1. Identify the e2e test users by email pattern.
WITH e2e_contractor_users AS (
  SELECT id, email FROM auth.users
  WHERE email LIKE 'e2e-contractor-%@chezcontractor.test'
),
e2e_customer_users AS (
  SELECT id, email FROM auth.users
  WHERE email LIKE 'e2e-customer-of-contractor-%@havenhome.test'
)
SELECT
  (SELECT count(*) FROM e2e_contractor_users) AS contractor_users_to_delete,
  (SELECT count(*) FROM e2e_customer_users)   AS customer_users_to_delete;

-- 2. Wipe contractor-side rows tied to test workspaces.
DELETE FROM public.provider_visit_assignments
  WHERE workspace_id IN (
    SELECT m.workspace_id FROM public.provider_workspace_members m
    WHERE m.user_id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-contractor-%@chezcontractor.test')
  );

DELETE FROM public.provider_quote_comments
  WHERE quote_id IN (
    SELECT q.id FROM public.provider_quotes q
    WHERE q.workspace_id IN (
      SELECT m.workspace_id FROM public.provider_workspace_members m
      WHERE m.user_id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-contractor-%@chezcontractor.test')
    )
  );

DELETE FROM public.provider_quotes
  WHERE workspace_id IN (
    SELECT m.workspace_id FROM public.provider_workspace_members m
    WHERE m.user_id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-contractor-%@chezcontractor.test')
  );

DELETE FROM public.provider_saved_quote_items
  WHERE workspace_id IN (
    SELECT m.workspace_id FROM public.provider_workspace_members m
    WHERE m.user_id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-contractor-%@chezcontractor.test')
  );

DELETE FROM public.provider_contractor_links
  WHERE workspace_id IN (
    SELECT m.workspace_id FROM public.provider_workspace_members m
    WHERE m.user_id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-contractor-%@chezcontractor.test')
  );

DELETE FROM public.provider_workspace_members
  WHERE workspace_id IN (
    SELECT m.workspace_id FROM public.provider_workspace_members m
    WHERE m.user_id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-contractor-%@chezcontractor.test')
  );

DELETE FROM public.provider_workspaces
  WHERE id IN (
    SELECT m.workspace_id FROM public.provider_workspace_members m
    WHERE m.user_id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-contractor-%@chezcontractor.test')
  )
  OR company_name LIKE 'E2E Contractor%';

-- 3. Wipe customer-side household-scoped rows.
DELETE FROM public.maintenance_tasks
  WHERE household_id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-customer-of-contractor-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

DELETE FROM public.handyman_punch_items
  WHERE household_id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-customer-of-contractor-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

DELETE FROM public.handyman_request_messages
  WHERE household_id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-customer-of-contractor-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

DELETE FROM public.handyman_requests
  WHERE household_id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-customer-of-contractor-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

DELETE FROM public.routines
  WHERE household_id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-customer-of-contractor-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

DELETE FROM public.contractors
  WHERE household_id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-customer-of-contractor-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

DELETE FROM public.utility_accounts
  WHERE household_id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-customer-of-contractor-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

DELETE FROM public.home_systems
  WHERE household_id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-customer-of-contractor-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

DELETE FROM public.vehicles
  WHERE household_id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-customer-of-contractor-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

DELETE FROM public.family_members
  WHERE household_id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-customer-of-contractor-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

DELETE FROM public.concierge_messages
  WHERE household_id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-customer-of-contractor-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

DELETE FROM public.chez_requests
  WHERE household_id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-customer-of-contractor-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

DELETE FROM public.inbox_items
  WHERE household_id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-customer-of-contractor-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

DELETE FROM public.home_assessments
  WHERE household_id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-customer-of-contractor-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

DELETE FROM public.properties
  WHERE household_id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-customer-of-contractor-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

UPDATE public.users SET household_id = NULL
  WHERE id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-customer-of-contractor-%@havenhome.test');

DELETE FROM public.households
  WHERE id IN (
    SELECT u.household_id FROM public.users u
    WHERE u.id IN (SELECT id FROM auth.users WHERE email LIKE 'e2e-customer-of-contractor-%@havenhome.test')
      AND u.household_id IS NOT NULL
  );

-- 4. Drop the public.users rows and finally the auth rows.
DELETE FROM public.users
  WHERE id IN (
    SELECT id FROM auth.users
    WHERE email LIKE 'e2e-contractor-%@chezcontractor.test'
       OR email LIKE 'e2e-customer-of-contractor-%@havenhome.test'
  );

DELETE FROM auth.users
  WHERE email LIKE 'e2e-contractor-%@chezcontractor.test'
     OR email LIKE 'e2e-customer-of-contractor-%@havenhome.test';

COMMIT;

-- Post-cleanup verification — every row should be 0.
SELECT 'auth.users contractor remaining' AS check, count(*) AS n FROM auth.users WHERE email LIKE 'e2e-contractor-%@chezcontractor.test'
UNION ALL SELECT 'auth.users customer remaining', count(*) FROM auth.users WHERE email LIKE 'e2e-customer-of-contractor-%@havenhome.test'
UNION ALL SELECT 'provider_workspaces orphaned', count(*) FROM public.provider_workspaces WHERE company_name LIKE 'E2E Contractor%'
UNION ALL SELECT 'provider_workspace_members orphaned', count(*) FROM public.provider_workspace_members WHERE email LIKE 'e2e-contractor-%@chezcontractor.test';
