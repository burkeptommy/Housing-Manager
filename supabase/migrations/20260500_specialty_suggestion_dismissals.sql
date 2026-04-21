-- Phase 52b: Track dismissed specialty system suggestions so we don't
-- re-suggest the same category after the user taps "Not mine".
-- Keyed by (household_id, category, evidence) so a household can
-- dismiss "Pool/Spa" via "pool heater" evidence without suppressing
-- a future suggestion triggered by a different keyword.

create table if not exists household_dismissed_suggestions (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references households(id) on delete cascade,
  category text not null,
  evidence text not null,
  dismissed_at timestamptz not null default now(),
  unique(household_id, category, evidence)
);

alter table household_dismissed_suggestions enable row level security;

create policy "household_dismissed_suggestions_all"
  on household_dismissed_suggestions
  for all
  using (household_id in (select household_id from users where id = auth.uid()));
