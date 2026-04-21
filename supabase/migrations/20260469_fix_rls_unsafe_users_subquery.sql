-- ============================================================================
-- Fix "permission denied for table users" on household invitations and 12+
-- other tables.
--
-- Root cause: RLS policies on these tables contain inline subqueries that
-- SELECT from the `users` table. PostgreSQL evaluates these subqueries in the
-- caller's security context, and the `users` table's own RLS blocks the
-- nested access, cascading the failure.
--
-- Fix: Replace all `household_id IN (SELECT household_id FROM users WHERE
-- id = auth.uid())` patterns with `household_id = public.get_my_household_id()`.
-- The function is SECURITY DEFINER (created in migration 20260304) and
-- bypasses RLS on the users table.
--
-- Every section uses DROP POLICY IF EXISTS + CREATE POLICY, making this
-- migration fully idempotent.
-- ============================================================================

-- Safety: ensure the helper function exists (no-op if it already does)
CREATE OR REPLACE FUNCTION public.get_my_household_id()
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT household_id FROM public.users WHERE id = auth.uid()
$$;

-- ============================================================================
-- 1. household_invitations (the direct bug trigger)
--    Policies were created via Supabase dashboard, not in any migration.
-- ============================================================================
ALTER TABLE IF EXISTS household_invitations ENABLE ROW LEVEL SECURITY;

-- Drop any existing policies (covers dashboard-created and default names)
DO $$
DECLARE
    pol record;
BEGIN
    FOR pol IN
        SELECT policyname FROM pg_policies
        WHERE schemaname = 'public' AND tablename = 'household_invitations'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON household_invitations', pol.policyname);
    END LOOP;
END $$;

CREATE POLICY "household_invitations_select"
    ON household_invitations FOR SELECT TO authenticated
    USING (household_id = public.get_my_household_id());

CREATE POLICY "household_invitations_insert"
    ON household_invitations FOR INSERT TO authenticated
    WITH CHECK (household_id = public.get_my_household_id());

CREATE POLICY "household_invitations_update"
    ON household_invitations FOR UPDATE TO authenticated
    USING (household_id = public.get_my_household_id());

-- Anon can look up invitations by code during pre-signup
CREATE POLICY "household_invitations_select_anon"
    ON household_invitations FOR SELECT TO anon
    USING (status = 'pending');

-- ============================================================================
-- 2. family_events
-- ============================================================================
DROP POLICY IF EXISTS "Users can view their household events" ON family_events;
DROP POLICY IF EXISTS "Users can insert events for their household" ON family_events;
DROP POLICY IF EXISTS "Users can update their household events" ON family_events;
DROP POLICY IF EXISTS "Users can delete their household events" ON family_events;

CREATE POLICY "Users can view their household events"
    ON family_events FOR SELECT
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can insert events for their household"
    ON family_events FOR INSERT
    WITH CHECK (household_id = public.get_my_household_id());

CREATE POLICY "Users can update their household events"
    ON family_events FOR UPDATE
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can delete their household events"
    ON family_events FOR DELETE
    USING (household_id = public.get_my_household_id());

-- ============================================================================
-- 3. scenario_history
-- ============================================================================
DROP POLICY IF EXISTS "Users can view own scenarios" ON scenario_history;
DROP POLICY IF EXISTS "Users can insert own scenarios" ON scenario_history;

CREATE POLICY "Users can view own scenarios"
    ON scenario_history FOR SELECT
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can insert own scenarios"
    ON scenario_history FOR INSERT
    WITH CHECK (household_id = public.get_my_household_id());

-- ============================================================================
-- 4. concierge_messages (INSERT keeps user_id = auth.uid() constraint)
-- ============================================================================
DROP POLICY IF EXISTS "Users can read own household concierge messages" ON concierge_messages;
DROP POLICY IF EXISTS "Users can insert concierge messages" ON concierge_messages;

CREATE POLICY "Users can read own household concierge messages"
    ON concierge_messages FOR SELECT
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can insert concierge messages"
    ON concierge_messages FOR INSERT
    WITH CHECK (user_id = auth.uid() AND household_id = public.get_my_household_id());

-- ============================================================================
-- 5. task_reminders
-- ============================================================================
DROP POLICY IF EXISTS "Users can manage own household task reminders" ON task_reminders;

CREATE POLICY "Users can manage own household task reminders"
    ON task_reminders FOR ALL
    USING (household_id = public.get_my_household_id());

-- ============================================================================
-- 6. utility_accounts
-- ============================================================================
DROP POLICY IF EXISTS "Users can view their household utility accounts" ON utility_accounts;
DROP POLICY IF EXISTS "Users can manage their household utility accounts" ON utility_accounts;
DROP POLICY IF EXISTS "Users can update their household utility accounts" ON utility_accounts;
DROP POLICY IF EXISTS "Users can delete their household utility accounts" ON utility_accounts;

CREATE POLICY "Users can view their household utility accounts"
    ON utility_accounts FOR SELECT
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can manage their household utility accounts"
    ON utility_accounts FOR INSERT
    WITH CHECK (household_id = public.get_my_household_id());

CREATE POLICY "Users can update their household utility accounts"
    ON utility_accounts FOR UPDATE
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can delete their household utility accounts"
    ON utility_accounts FOR DELETE
    USING (household_id = public.get_my_household_id());

-- ============================================================================
-- 7. project_quotes
-- ============================================================================
DROP POLICY IF EXISTS "Members can view household quotes" ON project_quotes;
DROP POLICY IF EXISTS "Members can insert household quotes" ON project_quotes;
DROP POLICY IF EXISTS "Members can update household quotes" ON project_quotes;
DROP POLICY IF EXISTS "Members can delete household quotes" ON project_quotes;

CREATE POLICY "Members can view household quotes"
    ON project_quotes FOR SELECT
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Members can insert household quotes"
    ON project_quotes FOR INSERT
    WITH CHECK (household_id = public.get_my_household_id());

CREATE POLICY "Members can update household quotes"
    ON project_quotes FOR UPDATE
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Members can delete household quotes"
    ON project_quotes FOR DELETE
    USING (household_id = public.get_my_household_id());

-- ============================================================================
-- 8. project_contacts
-- ============================================================================
DROP POLICY IF EXISTS "Users can view their household project contacts" ON project_contacts;
DROP POLICY IF EXISTS "Users can manage their household project contacts" ON project_contacts;
DROP POLICY IF EXISTS "Users can update their household project contacts" ON project_contacts;
DROP POLICY IF EXISTS "Users can delete their household project contacts" ON project_contacts;

CREATE POLICY "Users can view their household project contacts"
    ON project_contacts FOR SELECT
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can manage their household project contacts"
    ON project_contacts FOR INSERT
    WITH CHECK (household_id = public.get_my_household_id());

CREATE POLICY "Users can update their household project contacts"
    ON project_contacts FOR UPDATE
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can delete their household project contacts"
    ON project_contacts FOR DELETE
    USING (household_id = public.get_my_household_id());

-- ============================================================================
-- 9. inbox_items
-- ============================================================================
DROP POLICY IF EXISTS "Members can view household inbox" ON inbox_items;
DROP POLICY IF EXISTS "Members can update household inbox" ON inbox_items;
DROP POLICY IF EXISTS "Members can delete household inbox items" ON inbox_items;

CREATE POLICY "Members can view household inbox"
    ON inbox_items FOR SELECT
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Members can update household inbox"
    ON inbox_items FOR UPDATE
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Members can delete household inbox items"
    ON inbox_items FOR DELETE
    USING (household_id = public.get_my_household_id());

-- ============================================================================
-- 10. project_files
-- ============================================================================
DROP POLICY IF EXISTS "Members can view project files" ON project_files;
DROP POLICY IF EXISTS "Members can insert project files" ON project_files;
DROP POLICY IF EXISTS "Members can delete project files" ON project_files;

CREATE POLICY "Members can view project files"
    ON project_files FOR SELECT
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Members can insert project files"
    ON project_files FOR INSERT
    WITH CHECK (household_id = public.get_my_household_id());

CREATE POLICY "Members can delete project files"
    ON project_files FOR DELETE
    USING (household_id = public.get_my_household_id());

-- ============================================================================
-- 11. household_email_addresses
-- ============================================================================
DROP POLICY IF EXISTS "Members can view household email" ON household_email_addresses;
DROP POLICY IF EXISTS "Members can insert household email" ON household_email_addresses;

CREATE POLICY "Members can view household email"
    ON household_email_addresses FOR SELECT
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Members can insert household email"
    ON household_email_addresses FOR INSERT
    WITH CHECK (household_id = public.get_my_household_id());

-- ============================================================================
-- 12. household_allowed_senders
-- ============================================================================
DROP POLICY IF EXISTS "Members can view allowed senders" ON household_allowed_senders;
DROP POLICY IF EXISTS "Members can insert allowed senders" ON household_allowed_senders;
DROP POLICY IF EXISTS "Members can delete allowed senders" ON household_allowed_senders;

CREATE POLICY "Members can view allowed senders"
    ON household_allowed_senders FOR SELECT
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Members can insert allowed senders"
    ON household_allowed_senders FOR INSERT
    WITH CHECK (household_id = public.get_my_household_id());

CREATE POLICY "Members can delete allowed senders"
    ON household_allowed_senders FOR DELETE
    USING (household_id = public.get_my_household_id());

-- ============================================================================
-- 13. household_advisors
-- ============================================================================
DROP POLICY IF EXISTS "Users can view their household advisors" ON household_advisors;
DROP POLICY IF EXISTS "Users can insert household advisors" ON household_advisors;
DROP POLICY IF EXISTS "Users can update their household advisors" ON household_advisors;
DROP POLICY IF EXISTS "Users can delete their household advisors" ON household_advisors;

CREATE POLICY "Users can view their household advisors"
    ON household_advisors FOR SELECT
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can insert household advisors"
    ON household_advisors FOR INSERT
    WITH CHECK (household_id = public.get_my_household_id());

CREATE POLICY "Users can update their household advisors"
    ON household_advisors FOR UPDATE
    USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can delete their household advisors"
    ON household_advisors FOR DELETE
    USING (household_id = public.get_my_household_id());

-- ============================================================================
-- 14. service_emails
-- ============================================================================
DROP POLICY IF EXISTS "Users can manage their household service emails" ON service_emails;

CREATE POLICY "Users can manage their household service emails"
    ON service_emails FOR ALL
    USING (household_id = public.get_my_household_id());

-- ============================================================================
-- 15. inbox-attachments storage bucket policies
-- ============================================================================
DROP POLICY IF EXISTS "Users can view own household inbox attachments" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload to own household inbox attachments" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own household inbox attachments" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own household inbox attachments" ON storage.objects;

CREATE POLICY "Users can view own household inbox attachments"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'inbox-attachments'
        AND (storage.foldername(name))[1] = public.get_my_household_id()::text
    );

CREATE POLICY "Users can upload to own household inbox attachments"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'inbox-attachments'
        AND (storage.foldername(name))[1] = public.get_my_household_id()::text
    );

CREATE POLICY "Users can update own household inbox attachments"
    ON storage.objects FOR UPDATE
    USING (
        bucket_id = 'inbox-attachments'
        AND (storage.foldername(name))[1] = public.get_my_household_id()::text
    );

CREATE POLICY "Users can delete own household inbox attachments"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'inbox-attachments'
        AND (storage.foldername(name))[1] = public.get_my_household_id()::text
    );

-- ============================================================================
-- 16. Belt-and-suspenders GRANTs for all affected tables
--     (Idempotent: re-granting an existing privilege is a no-op)
-- ============================================================================
GRANT SELECT, INSERT, UPDATE ON public.household_invitations TO authenticated;
GRANT SELECT ON public.household_invitations TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.family_events TO authenticated;
GRANT SELECT, INSERT ON public.scenario_history TO authenticated;
GRANT SELECT, INSERT ON public.concierge_messages TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.task_reminders TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.utility_accounts TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.project_quotes TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.project_contacts TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.inbox_items TO authenticated;
GRANT SELECT, INSERT, DELETE ON public.project_files TO authenticated;
GRANT SELECT, INSERT ON public.household_email_addresses TO authenticated;
GRANT SELECT, INSERT, DELETE ON public.household_allowed_senders TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.household_advisors TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.service_emails TO authenticated;
