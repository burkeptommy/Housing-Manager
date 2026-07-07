-- Phase 80 (discovery study): per-template dismissal infrastructure.
--
-- Replaces the per-category `dismissed_categories` model with per-template
-- "Not for my home" dismissals. Lets users hide individual templates from
-- the show-everything-by-default model without losing the rest of the
-- category. Restore via Settings → Hidden Tasks.
--
-- Sister migration (20261335_migrate_dismissed_categories.sql) backfills
-- this table from any existing dismissed_categories rows so users who hid
-- categories pre-Phase-80 don't see those templates resurface.

create table if not exists public.dismissed_templates (
    id uuid primary key default gen_random_uuid(),
    property_id uuid not null references public.properties(id) on delete cascade,
    household_id uuid not null references public.households(id) on delete cascade,
    template_key text not null,
    reason text default 'not_applicable',
    dismissed_at timestamptz not null default now(),
    unique (property_id, template_key)
);

create index if not exists dismissed_templates_property_idx
    on public.dismissed_templates(property_id);
create index if not exists dismissed_templates_household_idx
    on public.dismissed_templates(household_id);

alter table public.dismissed_templates enable row level security;

drop policy if exists "household_dismissed_templates" on public.dismissed_templates;
create policy "household_dismissed_templates" on public.dismissed_templates
    for all
    using (household_id = public.get_my_household_id())
    with check (household_id = public.get_my_household_id());
