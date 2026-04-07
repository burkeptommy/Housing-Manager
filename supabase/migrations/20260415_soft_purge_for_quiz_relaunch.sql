-- Soft purge: keep auth users + households, drop all owned data so testers
-- start fresh on the new schema/quiz. TestFlight only, testers were warned.
--
-- The plan keeps users, households, household_invitations, household_email_addresses,
-- equipment_catalog, equipment_scores, utility_providers, allowed_senders,
-- and property_lookups_cache.
--
-- Tables are truncated individually inside an exception-handling loop so
-- the migration is tolerant of any tables that have been renamed, dropped,
-- or never existed in this database. Non-existent tables are skipped with
-- a NOTICE so we can see what was actually purged.

DO $$
DECLARE
    tbl text;
    purge_tables text[] := ARRAY[
        'properties',
        'home_systems',
        'maintenance_tasks',
        'documents',
        'document_content',
        'document_parties',
        'document_family_members',
        'warranties',
        'contractors',
        'service_records',
        'service_contracts',
        'chat_messages',
        'concierge_messages',
        'scenario_history',
        'completion_scores',
        'access_logs',
        'dismissed_categories',
        'inbox_items',
        'inbox_attachments',
        'property_projects',
        'project_quotes',
        'project_line_items',
        'project_files',
        'project_contacts',
        'project_visualizations',
        'family_events',
        'synced_calendars',
        'utility_accounts',
        'analytics_events',
        'vehicles',
        'vehicle_service_records',
        'vehicle_recalls',
        'family_members'
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
