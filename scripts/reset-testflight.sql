-- ============================================================================
-- Haven TestFlight Reset
-- ============================================================================
--
-- Wipes ALL user-generated data so every TestFlight user has to sign up
-- again, create a new household, add their property, etc. Keeps the schema,
-- migrations, edge function deploys, and ALL catalog/seed/system tables
-- intact.
--
-- HOW TO RUN
-- ----------
-- 1. Open the Supabase dashboard for project jsucwnkntdrxhysojgri
-- 2. Go to SQL Editor → New query
-- 3. Paste this entire file
-- 4. Click Run
-- 5. Read the verification output at the bottom — every "user data" row
--    should show 0, every "catalog" row should still show its previous count
--
-- The script runs inside a transaction (BEGIN/COMMIT) so if anything fails
-- mid-way the entire purge rolls back and nothing changes.
--
-- WHAT GETS WIPED
-- ---------------
-- • auth.users (cascades to identities, refresh_tokens, sessions, mfa_*)
-- • public.users
-- • households + every household-scoped table (properties, documents,
--   maintenance_tasks, vehicles, family_members, inbox_items, projects,
--   chat_messages, concierge_messages, scenario_history, analytics_events,
--   warranties, contractors, service_records, service_contracts,
--   completion_scores, utility_accounts, project_*, family_events,
--   synced_calendars, trusted_contacts, etc.)
-- • storage.objects rows for ALL user-content buckets:
--     documents, property-images, service-records, avatars,
--     room-visualizations, inbox-attachments
--
-- WHAT GETS KEPT (verified against every CREATE TABLE / from() / REFERENCES
--                 in supabase/, Haven/Core, and supabase/functions)
-- ---------------------------------------------------------------------------
-- • Schema, all 94 migrations, RLS policies, indexes, helper functions,
--   pg_cron jobs (send-reminder-batch keeps firing — no-op until users return)
-- • Edge function deploys + secrets
-- • equipment_manufacturers, equipment_categories, equipment_catalog,
--   equipment_manuals, equipment_common_issues, equipment_service_schedules,
--   equipment_scores  (the 219 brands / 2,818 models / 366 PDFs catalog)
-- • utility_providers (100+ insurance + utility seed rows from phases 16a,
--   18d, plus the pool/irrigation seed and the extended provider seed)
-- • app_config (the version-gate row read on every iOS launch)
-- • property_lookups (address-keyed ATTOM/RentCast cache, NOT user-scoped —
--   wiping it would burn API credits when new users add the same addresses)
-- • storage.objects rows for the `equipment-manuals` bucket (366 PDFs, 2.6 GB)
--
-- WHAT HAPPENS TO EXISTING TESTFLIGHT USERS
-- -----------------------------------------
-- The next time they open the app, the auth session restore in
-- AuthService.startListening() will try to refresh their token, the refresh
-- will fail (their auth.users row is gone), and the catch block will call
-- forceLocalSignOut() which clears the local Keychain session and routes
-- them back to AddressHookView. They sign up again, fresh slate.
--
-- ============================================================================

BEGIN;

-- Bypass Supabase's storage.protect_delete() trigger for this transaction
-- only. The trigger is intentional safety rail against accidental deletes;
-- we're explicitly opting in for this admin-level reset. SET LOCAL scopes
-- this setting to the current transaction only, so if the script rolls
-- back (or when COMMIT finishes), the setting is gone.
SET LOCAL storage.allow_delete_query = 'true';

-- ----------------------------------------------------------------------------
-- Step 1: storage objects for ALL user-content buckets
-- ----------------------------------------------------------------------------
-- Supabase's storage triggers handle the underlying file deletion when these
-- rows are removed. equipment-manuals is explicitly excluded so the cached
-- manufacturer PDFs (2.6+ GB) survive.
--
-- Bucket inventory verified against:
--   • supabase/storage.sql            → documents, property-images, service-records
--   • supabase/migrations/2026032604_inbox_items_enhanced.sql → inbox-attachments
--   • supabase/migrations/20260334_project_visualizations.sql → room-visualizations
--   • Haven/Core/Services/AvatarPhotoService.swift → avatars
--   • supabase/functions/download-manuals/index.ts → equipment-manuals (KEEP)
DELETE FROM storage.objects
 WHERE bucket_id IN (
    'documents',
    'property-images',
    'service-records',
    'avatars',
    'room-visualizations',
    'inbox-attachments'
 );

-- ----------------------------------------------------------------------------
-- Step 2: every household-scoped public.* table
-- ----------------------------------------------------------------------------
-- Tolerant DO block — TRUNCATE each table individually with CASCADE; if a
-- table doesn't exist (renamed, dropped, never created in this DB), it's
-- skipped with a NOTICE rather than aborting the whole script.
--
-- Tables INTENTIONALLY NOT in the array below (kept on purpose):
--   property_lookups       — address-keyed ATTOM/RentCast cache, no user FK,
--                            wiping it would burn API credits when new users
--                            re-add the same addresses
--   equipment_manufacturers, equipment_categories, equipment_catalog,
--   equipment_manuals, equipment_common_issues, equipment_service_schedules,
--   equipment_scores       — the equipment catalog (219 brands, 2,818 models)
--   utility_providers      — 100+ insurance + utility provider seed rows
--   app_config             — version gate the iOS client reads on launch
DO $$
DECLARE
    tbl text;
    purge_tables text[] := ARRAY[
        'users',
        'households',
        'household_invitations',
        'household_email_addresses',
        'household_allowed_senders',
        'household_merge_requests',
        'household_toolkit',
        'family_members',
        'family_events',
        'synced_calendars',
        'properties',
        'home_systems',
        'maintenance_tasks',
        'warranties',
        'contractors',
        'service_records',
        'service_contracts',
        'service_emails',
        'completion_scores',
        'dismissed_categories',
        'utility_accounts',
        'documents',
        'document_content',
        'document_family_members',
        'document_parties',
        'trusted_contacts',
        'trusted_contact_documents',
        'property_projects',
        'project_quotes',
        'project_line_items',
        'project_files',
        'project_contacts',
        'project_visualizations',
        'vehicles',
        'vehicle_service_records',
        'vehicle_recalls',
        'inbox_items',
        'inbox_attachments',
        'chat_messages',
        'concierge_messages',
        'task_reminders',
        'scenario_history',
        'access_log',
        'analytics_events',
        'device_tokens'
    ];
BEGIN
    FOREACH tbl IN ARRAY purge_tables LOOP
        BEGIN
            EXECUTE format('TRUNCATE TABLE public.%I CASCADE', tbl);
            RAISE NOTICE 'Purged: %', tbl;
        EXCEPTION
            WHEN undefined_table THEN
                RAISE NOTICE 'Skipped (does not exist): %', tbl;
        END;
    END LOOP;
END $$;

-- ----------------------------------------------------------------------------
-- Step 3: auth.users (and everything cascading from it)
-- ----------------------------------------------------------------------------
-- Has to come AFTER public.users is empty because public.users.id has a FK
-- to auth.users(id) without ON DELETE CASCADE, so any leftover public.users
-- row would block the delete. Step 2 already cleared it.
--
-- Cascades automatically to auth.identities, auth.refresh_tokens,
-- auth.sessions, auth.mfa_factors, auth.mfa_challenges, etc.
DELETE FROM auth.users;

-- ----------------------------------------------------------------------------
-- Step 4: verification — read this output before clicking Run twice
-- ----------------------------------------------------------------------------
-- All "user data" rows MUST be 0. All "catalog" rows MUST still be > 0.
SELECT '=== USER DATA (must be 0) ===' AS label, NULL::bigint AS row_count
UNION ALL SELECT 'auth.users',                  (SELECT count(*) FROM auth.users)
UNION ALL SELECT 'public.users',                (SELECT count(*) FROM public.users)
UNION ALL SELECT 'households',                  (SELECT count(*) FROM households)
UNION ALL SELECT 'properties',                  (SELECT count(*) FROM properties)
UNION ALL SELECT 'family_members',              (SELECT count(*) FROM family_members)
UNION ALL SELECT 'documents',                   (SELECT count(*) FROM documents)
UNION ALL SELECT 'home_systems',                (SELECT count(*) FROM home_systems)
UNION ALL SELECT 'maintenance_tasks',           (SELECT count(*) FROM maintenance_tasks)
UNION ALL SELECT 'vehicles',                    (SELECT count(*) FROM vehicles)
UNION ALL SELECT 'utility_accounts',            (SELECT count(*) FROM utility_accounts)
UNION ALL SELECT 'inbox_items',                 (SELECT count(*) FROM inbox_items)
UNION ALL SELECT 'chat_messages',               (SELECT count(*) FROM chat_messages)
UNION ALL SELECT 'concierge_messages',          (SELECT count(*) FROM concierge_messages)
UNION ALL SELECT 'analytics_events',            (SELECT count(*) FROM analytics_events)
UNION ALL SELECT 'storage.objects (documents)',
    (SELECT count(*) FROM storage.objects WHERE bucket_id = 'documents')
UNION ALL SELECT 'storage.objects (avatars)',
    (SELECT count(*) FROM storage.objects WHERE bucket_id = 'avatars')
UNION ALL SELECT 'storage.objects (property-images)',
    (SELECT count(*) FROM storage.objects WHERE bucket_id = 'property-images')
UNION ALL SELECT 'storage.objects (service-records)',
    (SELECT count(*) FROM storage.objects WHERE bucket_id = 'service-records')
UNION ALL SELECT 'storage.objects (room-visualizations)',
    (SELECT count(*) FROM storage.objects WHERE bucket_id = 'room-visualizations')
UNION ALL SELECT 'storage.objects (inbox-attachments)',
    (SELECT count(*) FROM storage.objects WHERE bucket_id = 'inbox-attachments')
UNION ALL SELECT '=== CATALOG / SEED (must stay > 0) ===', NULL
UNION ALL SELECT 'equipment_manufacturers',     (SELECT count(*) FROM equipment_manufacturers)
UNION ALL SELECT 'equipment_categories',        (SELECT count(*) FROM equipment_categories)
UNION ALL SELECT 'equipment_catalog',           (SELECT count(*) FROM equipment_catalog)
UNION ALL SELECT 'equipment_manuals',           (SELECT count(*) FROM equipment_manuals)
UNION ALL SELECT 'equipment_common_issues',     (SELECT count(*) FROM equipment_common_issues)
UNION ALL SELECT 'equipment_service_schedules', (SELECT count(*) FROM equipment_service_schedules)
UNION ALL SELECT 'equipment_scores',            (SELECT count(*) FROM equipment_scores)
UNION ALL SELECT 'utility_providers',           (SELECT count(*) FROM utility_providers)
UNION ALL SELECT 'app_config',                  (SELECT count(*) FROM app_config)
UNION ALL SELECT 'property_lookups (cache)',    (SELECT count(*) FROM property_lookups)
UNION ALL SELECT 'storage.objects (equipment-manuals, KEEP)',
    (SELECT count(*) FROM storage.objects WHERE bucket_id = 'equipment-manuals');

COMMIT;
