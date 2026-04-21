-- Phase 54C: Track templates the household tapped "Hide" on inside
-- "Recommended for your home" so we don't re-surface the same item
-- every launch. Keyed by (household_id, template_id) where
-- `template_id` is the MaintenanceTemplate.templateKey
-- ("{category}:{title}").
--
-- Reset affordance: the Recommended view's "Show all hidden
-- recommendations" link DELETEs every row for the household so users
-- who change their mind get a fresh list back.

create table if not exists public.dismissed_recommendations (
  household_id uuid not null references public.households(id) on delete cascade,
  template_id text not null,
  dismissed_at timestamptz not null default now(),
  dismissed_by_user_id uuid references public.users(id),
  primary key (household_id, template_id)
);

alter table public.dismissed_recommendations enable row level security;

create policy "dismissed_recommendations_all"
  on public.dismissed_recommendations
  for all
  to authenticated
  using (household_id = public.get_my_household_id())
  with check (household_id = public.get_my_household_id());
