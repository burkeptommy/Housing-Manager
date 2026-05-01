-- Phase 67H: bundle custom subitems.
--
-- Lets the homeowner add their own one-line additions to a bundle's
-- "What's included" list, scoped either to:
--   * 'always' — recur on every future fire of the bundle (the
--     reconciler reads + appends on each bundle parent creation)
--   * 'once' — attach to the next bundle fire only, archive after
--     that bundle parent completes
--
-- Reconciler integration (`MaintenanceTaskReconciler.reconcile`):
--   1. Building bundleNotes = "What's included:\n" + per-template
--      bullets — same as today.
--   2. Fetch this household's `recurrence='always'` rows for
--      (property, bundle_id), append titles as bullets.
--   3. Fetch this household's `recurrence='once' AND scope_task_id
--      IS NULL` queued rows, append + UPDATE rows with the new
--      bundle parent task id so they don't double-attach.
--
-- Completion lifecycle: when a bundle parent task is marked complete,
-- the iOS layer calls `markOnceSubitemsUsed(taskId:)` which stamps
-- `used_at = now()` and `archived_at = now()` on every row whose
-- scope_task_id matches. Future bundle fires won't see them.
--
-- bundle_id is the in-app `MaintenanceTemplate.bundleId` string
-- ("Chimney:fall", "HVAC:spring", "Pool/Spa:opening", etc.) — same
-- canonical key the reconciler uses. Stable across renames so we
-- never need migration for it.

create table if not exists public.bundle_custom_subitems (
    id uuid primary key default gen_random_uuid(),
    household_id uuid not null references public.households(id) on delete cascade,
    property_id uuid not null references public.properties(id) on delete cascade,
    bundle_id text not null,
    title text not null,
    recurrence text not null default 'always' check (recurrence in ('always', 'once')),
    scope_task_id uuid references public.maintenance_tasks(id) on delete set null,
    added_by_user_id uuid references auth.users(id) on delete set null,
    added_at timestamptz not null default now(),
    archived_at timestamptz,
    used_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- Lookup index: reconciler reads by household + bundle_id at every
-- bundle parent creation. Filter to active rows via partial index.
create index if not exists idx_bundle_custom_subitems_lookup
    on public.bundle_custom_subitems(household_id, property_id, bundle_id)
    where archived_at is null;

-- For markOnceSubitemsUsed — task-id reverse lookup when a bundle
-- parent completes.
create index if not exists idx_bundle_custom_subitems_scope_task
    on public.bundle_custom_subitems(scope_task_id)
    where scope_task_id is not null and archived_at is null;

-- updated_at auto-bump trigger.
create or replace function public.bundle_custom_subitems_set_updated_at()
returns trigger language plpgsql as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists trg_bundle_custom_subitems_updated_at on public.bundle_custom_subitems;
create trigger trg_bundle_custom_subitems_updated_at
    before update on public.bundle_custom_subitems
    for each row execute function public.bundle_custom_subitems_set_updated_at();

-- RLS: same household-scoping pattern as every other Haven table.
alter table public.bundle_custom_subitems enable row level security;

create policy bundle_custom_subitems_select on public.bundle_custom_subitems
    for select using (household_id = public.get_my_household_id());

create policy bundle_custom_subitems_insert on public.bundle_custom_subitems
    for insert with check (household_id = public.get_my_household_id());

create policy bundle_custom_subitems_update on public.bundle_custom_subitems
    for update using (household_id = public.get_my_household_id())
    with check (household_id = public.get_my_household_id());

create policy bundle_custom_subitems_delete on public.bundle_custom_subitems
    for delete using (household_id = public.get_my_household_id());
