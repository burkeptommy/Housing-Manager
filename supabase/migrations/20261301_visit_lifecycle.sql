-- Wave M1 — Visit lifecycle
--
-- Field tech accountability: clock-in / clock-out, GPS proof at clock-in,
-- and pause/resume so net time-on-site stays accurate when the tech
-- breaks for lunch, hits an issue, or steps off-site between systems.
-- Drives operator billing accuracy + dispute resolution ("I was on-site
-- for 90 min").
--
-- Operates on the existing provider_visit_assignments rows. One assignment
-- per (workspace, request); each lifecycle event lives on that row plus a
-- companion provider_visit_pauses row per pause window.

alter table public.provider_visit_assignments
  add column if not exists clock_in_at timestamptz,
  add column if not exists clock_out_at timestamptz,
  add column if not exists paused_seconds integer not null default 0,
  add column if not exists clock_in_lat numeric(9,6),
  add column if not exists clock_in_lng numeric(9,6),
  add column if not exists clock_in_accuracy_m integer;

create table if not exists public.provider_visit_pauses (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.provider_workspaces(id) on delete cascade,
  assignment_id uuid not null references public.provider_visit_assignments(id) on delete cascade,
  paused_at timestamptz not null default now(),
  resumed_at timestamptz,
  reason text,
  created_by_user_id uuid references auth.users(id) on delete set null
);

create index if not exists provider_visit_pauses_assignment_idx
  on public.provider_visit_pauses (assignment_id);

create index if not exists provider_visit_pauses_open_idx
  on public.provider_visit_pauses (assignment_id)
  where resumed_at is null;

alter table public.provider_visit_pauses enable row level security;

-- RLS mirrors provider_visit_assignments: any workspace member can
-- SELECT/INSERT/UPDATE rows belonging to a workspace they're a member of.
-- The PWA-side writes happen via the service-role key in the
-- handyman-portal edge function (bypasses RLS by design — portal_token is
-- the auth boundary there). Operations Desk reads via authenticated user
-- JWT and is gated by this policy.
drop policy if exists "provider_visit_pauses_all" on public.provider_visit_pauses;
create policy "provider_visit_pauses_all"
  on public.provider_visit_pauses
  using (workspace_id in (select public.get_my_provider_workspace_ids()))
  with check (workspace_id in (select public.get_my_provider_workspace_ids()));
