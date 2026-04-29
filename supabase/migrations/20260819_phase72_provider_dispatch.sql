-- Phase 72.1: provider dispatch, crew invites, and assignment planning.
--
-- Extends Haven Handyman beyond a single-account workspace by adding:
-- 1. Inviteable provider team members with secure claim tokens
-- 2. Role-aware member metadata for desktop/mobile workflows
-- 3. Visit assignments and route planning per technician

alter table public.provider_workspace_members
  alter column user_id drop not null;

alter table public.provider_workspace_members
  add column if not exists phone text,
  add column if not exists title text,
  add column if not exists invite_token text,
  add column if not exists invite_sent_at timestamptz,
  add column if not exists invited_by_user_id uuid references auth.users(id) on delete set null;

create unique index if not exists idx_provider_workspace_members_invite_token
  on public.provider_workspace_members (invite_token)
  where invite_token is not null;

update public.provider_workspace_members
set title = case role
  when 'owner' then 'Owner'
  when 'admin' then 'Administrator'
  when 'dispatcher' then 'Dispatch lead'
  when 'technician' then 'Field technician'
  else 'Team member'
end
where title is null;

create table if not exists public.provider_visit_assignments (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.provider_workspaces(id) on delete cascade,
  request_id uuid not null references public.handyman_requests(id) on delete cascade,
  visit_task_id uuid references public.maintenance_tasks(id) on delete set null,
  assigned_member_id uuid references public.provider_workspace_members(id) on delete set null,
  assigned_by_user_id uuid references auth.users(id) on delete set null,
  route_date date,
  window_start_time time,
  window_end_time time,
  stop_order integer check (stop_order is null or stop_order > 0),
  route_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (workspace_id, request_id)
);

create index if not exists idx_provider_visit_assignments_workspace
  on public.provider_visit_assignments (workspace_id, route_date, stop_order);

create index if not exists idx_provider_visit_assignments_member
  on public.provider_visit_assignments (assigned_member_id, route_date);

alter table public.provider_visit_assignments enable row level security;

drop policy if exists "provider_visit_assignments_all" on public.provider_visit_assignments;
create policy "provider_visit_assignments_all"
  on public.provider_visit_assignments
  using (workspace_id in (select public.get_my_provider_workspace_ids()))
  with check (workspace_id in (select public.get_my_provider_workspace_ids()));
