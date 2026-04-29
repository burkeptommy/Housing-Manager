-- Phase 71: Premier handyman program infrastructure.
--
-- Adds:
-- 1. Homeowner -> handyman requests for quotes, installs, standard visits,
--    and "come look at this" coordination.
-- 2. Public-token portal sessions that power the field microsite.
-- 3. Field execution reports for offline-first technician visit checklists.
-- 4. Lightweight request-thread messages for homeowner/vendor coordination.

create table if not exists public.handyman_requests (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  property_id uuid references public.properties(id) on delete set null,
  contractor_id uuid references public.contractors(id) on delete set null,
  visit_task_id uuid references public.maintenance_tasks(id) on delete set null,
  created_by_user_id uuid references auth.users(id) on delete set null,
  request_type text not null check (
    request_type in (
      'standard_visit',
      'quote',
      'repair',
      'install',
      'assembly',
      'question',
      'setup'
    )
  ),
  source text not null default 'homeowner' check (
    source in ('homeowner', 'haven', 'vendor', 'field')
  ),
  title text not null,
  details text,
  preferred_timing text,
  urgency text not null default 'routine' check (
    urgency in ('urgent', 'soon', 'routine')
  ),
  status text not null default 'submitted' check (
    status in (
      'draft',
      'submitted',
      'quoted',
      'scheduled',
      'in_progress',
      'completed',
      'cancelled'
    )
  ),
  first_visit_setup_requested boolean not null default false,
  recommended_lane text,
  quick_upsell_titles text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_handyman_requests_household_created
  on public.handyman_requests(household_id, created_at desc);

create index if not exists idx_handyman_requests_property
  on public.handyman_requests(property_id, created_at desc);

create index if not exists idx_handyman_requests_contractor_status
  on public.handyman_requests(contractor_id, status);

create table if not exists public.handyman_request_messages (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.handyman_requests(id) on delete cascade,
  household_id uuid not null references public.households(id) on delete cascade,
  sender_role text not null check (
    sender_role in ('homeowner', 'haven', 'vendor')
  ),
  body text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_handyman_request_messages_request
  on public.handyman_request_messages(request_id, created_at asc);

create table if not exists public.handyman_portal_sessions (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  property_id uuid references public.properties(id) on delete set null,
  contractor_id uuid references public.contractors(id) on delete set null,
  visit_task_id uuid references public.maintenance_tasks(id) on delete set null,
  created_by_user_id uuid references auth.users(id) on delete set null,
  title text not null,
  portal_token text not null unique,
  status text not null default 'active' check (
    status in ('active', 'completed', 'expired', 'revoked')
  ),
  first_visit boolean not null default false,
  seed_payload jsonb not null default '{}'::jsonb,
  last_opened_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_handyman_portal_sessions_household
  on public.handyman_portal_sessions(household_id, created_at desc);

create index if not exists idx_handyman_portal_sessions_visit
  on public.handyman_portal_sessions(visit_task_id);

create index if not exists idx_handyman_portal_sessions_token
  on public.handyman_portal_sessions(portal_token);

create table if not exists public.handyman_visit_reports (
  id uuid primary key default gen_random_uuid(),
  portal_session_id uuid not null references public.handyman_portal_sessions(id) on delete cascade,
  household_id uuid not null references public.households(id) on delete cascade,
  property_id uuid references public.properties(id) on delete set null,
  contractor_id uuid references public.contractors(id) on delete set null,
  visit_task_id uuid references public.maintenance_tasks(id) on delete set null,
  request_id uuid references public.handyman_requests(id) on delete set null,
  report_status text not null default 'draft' check (
    report_status in ('draft', 'in_progress', 'completed')
  ),
  checklist jsonb not null default '[]'::jsonb,
  setup_prompts jsonb not null default '[]'::jsonb,
  quick_upsells jsonb not null default '[]'::jsonb,
  homeowner_notes text,
  field_notes text,
  started_at timestamptz,
  completed_at timestamptz,
  last_synced_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (portal_session_id)
);

create index if not exists idx_handyman_visit_reports_household
  on public.handyman_visit_reports(household_id, created_at desc);

create index if not exists idx_handyman_visit_reports_visit
  on public.handyman_visit_reports(visit_task_id);

alter table public.handyman_requests enable row level security;
alter table public.handyman_request_messages enable row level security;
alter table public.handyman_portal_sessions enable row level security;
alter table public.handyman_visit_reports enable row level security;

drop policy if exists "handyman_requests_all" on public.handyman_requests;
create policy "handyman_requests_all"
  on public.handyman_requests
  using (household_id = public.get_my_household_id())
  with check (household_id = public.get_my_household_id());

drop policy if exists "handyman_request_messages_all" on public.handyman_request_messages;
create policy "handyman_request_messages_all"
  on public.handyman_request_messages
  using (household_id = public.get_my_household_id())
  with check (household_id = public.get_my_household_id());

drop policy if exists "handyman_portal_sessions_all" on public.handyman_portal_sessions;
create policy "handyman_portal_sessions_all"
  on public.handyman_portal_sessions
  using (household_id = public.get_my_household_id())
  with check (household_id = public.get_my_household_id());

drop policy if exists "handyman_visit_reports_all" on public.handyman_visit_reports;
create policy "handyman_visit_reports_all"
  on public.handyman_visit_reports
  using (household_id = public.get_my_household_id())
  with check (household_id = public.get_my_household_id());
