-- Phase 72: Haven Handyman provider workspace.
--
-- Adds a secure account layer for handyman companies and technicians:
-- 1. Provider workspaces + memberships
-- 2. Claim links from a provider workspace to household-level contractor rows
-- 3. Saved quote line items per provider
-- 4. Provider-owned quotes that homeowners can read in Haven

create table if not exists public.provider_workspaces (
  id uuid primary key default gen_random_uuid(),
  company_name text not null,
  primary_email text,
  primary_phone text,
  website text,
  license_number text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_provider_workspaces_company_name
  on public.provider_workspaces (lower(company_name));

create table if not exists public.provider_workspace_members (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.provider_workspaces(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  full_name text,
  email text,
  role text not null default 'owner' check (
    role in ('owner', 'admin', 'dispatcher', 'technician')
  ),
  status text not null default 'active' check (
    status in ('invited', 'active', 'disabled')
  ),
  last_seen_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (workspace_id, user_id)
);

create index if not exists idx_provider_workspace_members_user
  on public.provider_workspace_members (user_id, status);

create table if not exists public.provider_contractor_links (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.provider_workspaces(id) on delete cascade,
  contractor_id uuid not null references public.contractors(id) on delete cascade,
  is_primary boolean not null default false,
  claim_source text not null default 'invite' check (
    claim_source in ('invite', 'manual', 'email_match', 'phone_match')
  ),
  created_at timestamptz not null default now(),
  unique (workspace_id, contractor_id)
);

create index if not exists idx_provider_contractor_links_workspace
  on public.provider_contractor_links (workspace_id, created_at desc);

create index if not exists idx_provider_contractor_links_contractor
  on public.provider_contractor_links (contractor_id);

create table if not exists public.provider_saved_quote_items (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.provider_workspaces(id) on delete cascade,
  created_by_user_id uuid references auth.users(id) on delete set null,
  name text not null,
  description text,
  unit text not null default 'ea',
  default_quantity numeric(12,2) not null default 1,
  default_unit_price numeric(12,2) not null default 0,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_provider_saved_quote_items_workspace
  on public.provider_saved_quote_items (workspace_id, sort_order, created_at desc);

create table if not exists public.provider_quotes (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.provider_workspaces(id) on delete cascade,
  contractor_id uuid references public.contractors(id) on delete set null,
  household_id uuid not null references public.households(id) on delete cascade,
  property_id uuid references public.properties(id) on delete set null,
  request_id uuid references public.handyman_requests(id) on delete set null,
  visit_task_id uuid references public.maintenance_tasks(id) on delete set null,
  title text not null,
  status text not null default 'draft' check (
    status in ('draft', 'sent', 'viewed', 'approved', 'declined', 'withdrawn')
  ),
  currency text not null default 'USD',
  line_items jsonb not null default '[]'::jsonb,
  scope_notes text,
  homeowner_message text,
  subtotal numeric(12,2) not null default 0,
  tax_total numeric(12,2) not null default 0,
  total numeric(12,2) not null default 0,
  created_by_user_id uuid references auth.users(id) on delete set null,
  updated_by_user_id uuid references auth.users(id) on delete set null,
  sent_at timestamptz,
  viewed_at timestamptz,
  approved_at timestamptz,
  declined_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_provider_quotes_workspace
  on public.provider_quotes (workspace_id, updated_at desc);

create index if not exists idx_provider_quotes_request
  on public.provider_quotes (request_id, updated_at desc)
  where request_id is not null;

create index if not exists idx_provider_quotes_household
  on public.provider_quotes (household_id, updated_at desc);

create or replace function public.get_my_provider_workspace_ids()
returns setof uuid
language sql
stable
security definer
set search_path = public
as $$
  select workspace_id
  from public.provider_workspace_members
  where user_id = auth.uid()
    and status = 'active'
$$;

grant execute on function public.get_my_provider_workspace_ids() to authenticated;

alter table public.provider_workspaces enable row level security;
alter table public.provider_workspace_members enable row level security;
alter table public.provider_contractor_links enable row level security;
alter table public.provider_saved_quote_items enable row level security;
alter table public.provider_quotes enable row level security;

drop policy if exists "provider_workspaces_select" on public.provider_workspaces;
create policy "provider_workspaces_select"
  on public.provider_workspaces
  for select
  using (id in (select public.get_my_provider_workspace_ids()));

drop policy if exists "provider_workspaces_update" on public.provider_workspaces;
create policy "provider_workspaces_update"
  on public.provider_workspaces
  for update
  using (id in (select public.get_my_provider_workspace_ids()));

drop policy if exists "provider_workspace_members_select" on public.provider_workspace_members;
create policy "provider_workspace_members_select"
  on public.provider_workspace_members
  for select
  using (workspace_id in (select public.get_my_provider_workspace_ids()));

drop policy if exists "provider_workspace_members_update" on public.provider_workspace_members;
create policy "provider_workspace_members_update"
  on public.provider_workspace_members
  for update
  using (workspace_id in (select public.get_my_provider_workspace_ids()));

drop policy if exists "provider_contractor_links_all" on public.provider_contractor_links;
create policy "provider_contractor_links_all"
  on public.provider_contractor_links
  using (workspace_id in (select public.get_my_provider_workspace_ids()))
  with check (workspace_id in (select public.get_my_provider_workspace_ids()));

drop policy if exists "provider_saved_quote_items_all" on public.provider_saved_quote_items;
create policy "provider_saved_quote_items_all"
  on public.provider_saved_quote_items
  using (workspace_id in (select public.get_my_provider_workspace_ids()))
  with check (workspace_id in (select public.get_my_provider_workspace_ids()));

drop policy if exists "provider_quotes_provider_all" on public.provider_quotes;
create policy "provider_quotes_provider_all"
  on public.provider_quotes
  using (workspace_id in (select public.get_my_provider_workspace_ids()))
  with check (workspace_id in (select public.get_my_provider_workspace_ids()));

drop policy if exists "provider_quotes_homeowner_select" on public.provider_quotes;
create policy "provider_quotes_homeowner_select"
  on public.provider_quotes
  for select
  using (household_id = public.get_my_household_id());
