-- ============================================================================
-- Grant table-level permissions to authenticated and anon roles
-- Without these, RLS policies have no effect because the roles lack
-- base table access. "permission denied for table X" errors result.
-- ============================================================================

-- Core tables
GRANT SELECT, INSERT, UPDATE ON public.users TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.households TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.family_members TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.documents TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.document_family_members TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.document_content TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.properties TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.home_systems TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.warranties TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.contractors TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.maintenance_tasks TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.service_records TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.chat_messages TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.completion_scores TO authenticated;
GRANT SELECT, INSERT ON public.access_log TO authenticated;

-- Invitation tables
GRANT SELECT, INSERT, UPDATE ON public.household_invitations TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.household_merge_requests TO authenticated;

-- Allow anon role to look up invitations (for pre-signup code entry)
GRANT SELECT ON public.household_invitations TO anon;

-- Service contracts (if exists)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'service_contracts' AND table_schema = 'public') THEN
        EXECUTE 'GRANT SELECT, INSERT, UPDATE, DELETE ON public.service_contracts TO authenticated';
    END IF;
END $$;

-- Savings opportunities (if exists)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'savings_opportunities' AND table_schema = 'public') THEN
        EXECUTE 'GRANT SELECT, INSERT, UPDATE, DELETE ON public.savings_opportunities TO authenticated';
    END IF;
END $$;
