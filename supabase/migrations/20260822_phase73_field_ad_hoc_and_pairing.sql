-- Phase 73: Chez Field ad hoc visits and homeowner pairing requests.
--
-- Adds:
-- 1. Provider-created pairing requests for homes that are not yet fully linked in Chez.
-- 2. A secure place to persist the launch-era "pair this home to my company" workflow.

create table if not exists public.provider_home_pairing_requests (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.provider_workspaces(id) on delete cascade,
  created_by_user_id uuid references auth.users(id) on delete set null,
  contractor_id uuid references public.contractors(id) on delete set null,
  household_id uuid references public.households(id) on delete set null,
  property_id uuid references public.properties(id) on delete set null,
  homeowner_name text,
  homeowner_email text,
  homeowner_phone text,
  home_name text not null,
  address_line text,
  city text,
  state text,
  postal_code text,
  notes text,
  access_code text not null,
  status text not null default 'pending_homeowner' check (
    status in ('pending_homeowner', 'linked', 'cancelled')
  ),
  linked_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (access_code)
);

create index if not exists idx_provider_home_pairing_requests_workspace
  on public.provider_home_pairing_requests (workspace_id, status, created_at desc);

create index if not exists idx_provider_home_pairing_requests_homeowner_email
  on public.provider_home_pairing_requests (lower(homeowner_email))
  where homeowner_email is not null;

create index if not exists idx_provider_home_pairing_requests_homeowner_phone
  on public.provider_home_pairing_requests (homeowner_phone)
  where homeowner_phone is not null;

alter table public.provider_home_pairing_requests enable row level security;

drop policy if exists "provider_home_pairing_requests_all" on public.provider_home_pairing_requests;
create policy "provider_home_pairing_requests_all"
  on public.provider_home_pairing_requests
  using (workspace_id in (select public.get_my_provider_workspace_ids()))
  with check (workspace_id in (select public.get_my_provider_workspace_ids()));
