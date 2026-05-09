-- Sprint #3 R3-E-2: RLS data leak fix on provider_visit_assignments.
--
-- Pre-fix policy "provider_visit_assignments_all" filtered by workspace_id only,
-- which meant any active workspace member (including the lowest-privilege
-- 'technician' role) could SELECT every row in their workspace via PostgREST —
-- exposing every coworker's route, schedule, customer addresses, and stop order.
-- Confirmed reproducible with the W2 crew2 JWT: 23 rows returned across all 4
-- members instead of 5 rows for crew2 alone.
--
-- The iOS app DOES filter client-side in `loadDashboard` for technicians
-- (see handyman-provider/index.ts circa "if (permissions.isFieldTechnician)"),
-- but that is a UI-side narrowing that any direct PostgREST consumer can bypass.
-- This migration moves the gate down to RLS so the database is the source of
-- truth.
--
-- New policy split:
--   * Owners / admins / dispatchers: full ALL on every assignment in their
--     active workspaces (existing behavior preserved).
--   * Technicians: SELECT only on assignments where they are the
--     assigned_member_id (or in co_tech_member_ids) — i.e. the rows they
--     personally need to do their job. They cannot INSERT/UPDATE/DELETE.
--
-- Note on column name: the schema uses `assigned_member_id` (and
-- `co_tech_member_ids` for ride-along techs), not `member_id` as the bug
-- list mentioned. The code paths in handyman-provider/index.ts already key
-- on assigned_member_id throughout.

drop policy if exists "provider_visit_assignments_all" on public.provider_visit_assignments;
drop policy if exists "owners_and_dispatchers_full_access"
  on public.provider_visit_assignments;
drop policy if exists "technicians_see_only_their_assignments"
  on public.provider_visit_assignments;

-- Owner / admin / dispatcher get full read+write on workspace assignments.
create policy "owners_and_dispatchers_full_access"
  on public.provider_visit_assignments
  for all
  using (
    workspace_id in (
      select workspace_id
      from public.provider_workspace_members
      where user_id = auth.uid()
        and status = 'active'
        and role in ('owner', 'admin', 'dispatcher')
    )
  )
  with check (
    workspace_id in (
      select workspace_id
      from public.provider_workspace_members
      where user_id = auth.uid()
        and status = 'active'
        and role in ('owner', 'admin', 'dispatcher')
    )
  );

-- Technicians can only SELECT assignments where they are the lead assignee
-- or a listed co-tech. No write access — write paths flow through the
-- handyman-provider edge function, which uses the service-role key and
-- enforces its own role/identity checks before mutating.
create policy "technicians_see_only_their_assignments"
  on public.provider_visit_assignments
  for select
  using (
    assigned_member_id in (
      select id
      from public.provider_workspace_members
      where user_id = auth.uid()
        and status = 'active'
        and role = 'technician'
    )
    or exists (
      select 1
      from public.provider_workspace_members m
      where m.user_id = auth.uid()
        and m.status = 'active'
        and m.role = 'technician'
        and provider_visit_assignments.co_tech_member_ids is not null
        and m.id = any(provider_visit_assignments.co_tech_member_ids)
    )
  );
