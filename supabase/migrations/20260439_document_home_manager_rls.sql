-- Build 87 (Home Manager expansion):
-- Replace the documents SELECT policy so that linked users whose
-- `family_members.member_type` is 'home_manager' or 'staff' only see
-- rows where `visible_to_home_managers = true`. The homeowner, spouse,
-- and any other 'family' member (or unlinked auth users on the same
-- household) continue to see every document.
--
-- INSERT, UPDATE, and DELETE policies are intentionally left untouched
-- — home managers CAN upload, edit, and delete documents. Only the
-- read surface is restricted.

drop policy if exists "Users can view household documents" on documents;

create policy "household_documents_select"
  on documents for select
  using (
    household_id = public.get_my_household_id()
    and (
      visible_to_home_managers = true
      or not exists (
        select 1 from family_members
        where family_members.linked_user_id = auth.uid()
          and family_members.member_type in ('home_manager', 'staff')
      )
    )
  );
