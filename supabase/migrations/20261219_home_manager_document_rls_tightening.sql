-- Phase 95 (audit gap #57) — tighten home-manager document RLS.
--
-- Audit finding: Build 87 added the `household_documents_select`
-- policy that hides private documents from home managers / staff,
-- but the INSERT / UPDATE / DELETE policies only check
-- `household_id = get_my_household_id()`. Postgres RLS doesn't
-- automatically apply the SELECT predicate to other commands — so a
-- home manager who knows (or guesses) a document's UUID could:
--
--   • UPDATE a private document directly, including flipping
--     `visible_to_home_managers = true` to grant themselves access.
--   • DELETE a private document they aren't allowed to read.
--   • INSERT a new document with `visible_to_home_managers = false`
--     to hide their upload from the homeowner — which would
--     contradict the privacy principle (homeowner is the principal,
--     staff shouldn't be able to hide work from them).
--
-- This migration replaces the three open policies with versions that
-- mirror the SELECT predicate's home-manager / staff branch, plus a
-- CHECK on INSERT that prevents staff from creating already-private
-- documents.

-- Helper expression duplicated across policies for readability.
-- Returns true when the calling auth.uid() is NOT a home_manager or
-- staff family member of this household. The homeowner, spouse, and
-- regular family members all return true and bypass the visibility
-- gate.
--
-- We could extract this into a SQL function, but inlining keeps the
-- migration self-contained and the predicate cheap (one indexed
-- lookup on `family_members(linked_user_id)`).

DROP POLICY IF EXISTS "Users can insert household documents" ON public.documents;
DROP POLICY IF EXISTS "Users can update household documents" ON public.documents;
DROP POLICY IF EXISTS "Users can delete household documents" ON public.documents;

CREATE POLICY "household_documents_insert"
    ON public.documents FOR INSERT
    WITH CHECK (
        household_id = public.get_my_household_id()
        AND (
            -- Non-staff callers can insert with any visibility flag.
            NOT EXISTS (
                SELECT 1 FROM public.family_members
                WHERE family_members.linked_user_id = auth.uid()
                  AND family_members.member_type IN ('home_manager', 'staff')
            )
            -- Staff callers must insert with visible_to_home_managers
            -- = true (or null, which the column default coerces to
            -- true). They can't hide work from the homeowner.
            OR COALESCE(visible_to_home_managers, true) = true
        )
    );

CREATE POLICY "household_documents_update"
    ON public.documents FOR UPDATE
    USING (
        household_id = public.get_my_household_id()
        AND (
            visible_to_home_managers = true
            OR NOT EXISTS (
                SELECT 1 FROM public.family_members
                WHERE family_members.linked_user_id = auth.uid()
                  AND family_members.member_type IN ('home_manager', 'staff')
            )
        )
    );

CREATE POLICY "household_documents_delete"
    ON public.documents FOR DELETE
    USING (
        household_id = public.get_my_household_id()
        AND (
            visible_to_home_managers = true
            OR NOT EXISTS (
                SELECT 1 FROM public.family_members
                WHERE family_members.linked_user_id = auth.uid()
                  AND family_members.member_type IN ('home_manager', 'staff')
            )
        )
    );

COMMENT ON POLICY "household_documents_insert" ON public.documents IS
    'Phase 95 / gap #57: lets home managers and staff upload, but forces visible_to_home_managers = true so the homeowner can never lose visibility into staff-uploaded documents. Other household members (homeowner, spouse, family) can insert with any visibility flag.';

COMMENT ON POLICY "household_documents_update" ON public.documents IS
    'Phase 95 / gap #57: home managers and staff can only update documents that are visible to them — mirrors the SELECT predicate so a private document cannot be modified via direct ID lookup. The homeowner / spouse / regular family members can update any household document.';

COMMENT ON POLICY "household_documents_delete" ON public.documents IS
    'Phase 95 / gap #57: home managers and staff can only delete documents that are visible to them. The homeowner / spouse / regular family members can delete any household document. Mirrors the SELECT and UPDATE predicates.';
