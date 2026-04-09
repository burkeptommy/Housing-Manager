-- Build 87: separate household staff (home_manager, staff) from family
-- members so the dashboard can render them in their own strip and the
-- existing family-facing queries don't accidentally surface a paid
-- contractor in the family card list.
--
-- The new column defaults to 'family' for every existing row so build 86
-- and earlier installs round-trip cleanly. The check constraint guards
-- against typos at the application layer (DatabaseService writes the
-- column from the AddPersonRequest.memberType param introduced in this
-- batch).

alter table family_members
  add column if not exists member_type text not null default 'family'
    check (member_type in ('family', 'home_manager', 'staff'));

create index if not exists idx_family_members_member_type
  on family_members (household_id, member_type);

comment on column family_members.member_type is
  'Distinguishes family members (default) from paid household staff (home_manager, staff). Build 87 added this so the dashboard HouseholdStaffStrip and Settings Household Staff list can scope queries without leaking family rows.';
