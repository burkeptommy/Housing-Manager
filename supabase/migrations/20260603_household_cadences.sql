-- Phase 54D: Household weekly cadences. Rhythmic events that aren't
-- maintenance tasks — trash day, recycling, compost, yard waste,
-- recurring deliveries, school dropoff / pickup. These render as
-- dashboard banners on the right day and fire evening-before / morning-
-- of push notifications rather than living in the Maintenance tab
-- (Apple Reminders model, not Things 3 model).

create table if not exists public.household_cadences (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  property_id uuid references public.properties(id) on delete cascade,
  cadence_type text not null,
  label text not null,
  -- ISO 8601 weekday: 1 = Sunday ... 7 = Saturday. Matches
  -- `Calendar.current.component(.weekday, from:)` so iOS can read/write
  -- without translation.
  days_of_week int[] not null,
  time_of_day time,
  evening_before_reminder boolean not null default true,
  morning_of_reminder boolean not null default false,
  notes text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint cadence_type_valid check (cadence_type in (
    'trash', 'recycling', 'compost', 'yard_waste',
    'recurring_delivery', 'school_dropoff', 'school_pickup', 'other'
  )),
  constraint days_not_empty check (array_length(days_of_week, 1) > 0)
);

create index if not exists idx_household_cadences_household
  on public.household_cadences(household_id)
  where is_active = true;

create index if not exists idx_household_cadences_property
  on public.household_cadences(property_id)
  where is_active = true;

alter table public.household_cadences enable row level security;

create policy "household_cadences_all"
  on public.household_cadences
  for all
  to authenticated
  using (household_id = public.get_my_household_id())
  with check (household_id = public.get_my_household_id());
