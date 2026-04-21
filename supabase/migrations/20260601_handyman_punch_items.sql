-- Phase 54B: Handyman punch list. A persistent running list of small
-- items the homeowner wants their handyman to handle on the next visit.
-- Items accumulate indefinitely until the user schedules a visit — at
-- which point they're rolled into a Handyman:spring / Handyman:fall
-- bundle task and stamped completed_at + completed_visit_task_id.
--
-- `source`:
--   'manual'           — added directly from HandymanPunchListView
--   'recommended'      — added from "Recommended for your home" (Phase 54C)
--   'maintenance_task' — delegated from a maintenance task via the
--                        "Add to handyman list" action on the task card

create table if not exists public.handyman_punch_items (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  property_id uuid references public.properties(id) on delete cascade,
  title text not null,
  description text,
  source text not null default 'manual',
  source_task_id uuid references public.maintenance_tasks(id) on delete set null,
  added_by_user_id uuid references public.users(id),
  estimated_minutes int,
  estimated_cost_range text,
  notes text,
  created_at timestamptz not null default now(),
  completed_at timestamptz,
  completed_visit_task_id uuid references public.maintenance_tasks(id) on delete set null,
  archived_at timestamptz
);

create index if not exists idx_handyman_punch_items_household
  on public.handyman_punch_items(household_id)
  where archived_at is null;

create index if not exists idx_handyman_punch_items_pending
  on public.handyman_punch_items(household_id, created_at)
  where completed_at is null and archived_at is null;

alter table public.handyman_punch_items enable row level security;

-- SECURITY DEFINER helper (created in 20260469) bypasses the users-table
-- RLS that cascades when subqueries run in caller context.
create policy "handyman_punch_items_all"
  on public.handyman_punch_items
  for all
  to authenticated
  using (household_id = public.get_my_household_id())
  with check (household_id = public.get_my_household_id());
