-- Private admin catalog for homeowner onboarding, quiz, routines, vendors,
-- tasks, and Codex-facing product notes.
--
-- Access is intentionally narrow: only the allowlisted Tom account can read
-- or write through the public client. Service-role clients bypass RLS as
-- usual for migrations/backfills.

create or replace function public.is_tom_admin()
returns boolean
language sql
stable
as $$
  select lower(coalesce(auth.jwt() ->> 'email', '')) = 'tom@getchez.com';
$$;

create table if not exists public.admin_content_items (
  id uuid primary key default gen_random_uuid(),
  item_type text not null check (
    item_type in ('question', 'search', 'routine', 'vendor', 'task', 'system', 'category')
  ),
  title text not null,
  status text not null default 'draft' check (
    status in ('active', 'draft', 'cut', 'defer', 'reshape')
  ),
  category text,
  description text,
  sort_order integer not null default 0,
  payload jsonb not null default '{}'::jsonb,
  created_by uuid default auth.uid(),
  updated_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.admin_codex_notes (
  id uuid primary key default gen_random_uuid(),
  scope_type text not null default 'general',
  scope_id text,
  scope_title text,
  body text not null,
  snapshot jsonb not null default '{}'::jsonb,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now()
);

create index if not exists idx_admin_content_items_type
  on public.admin_content_items(item_type, status, sort_order);

create index if not exists idx_admin_content_items_payload
  on public.admin_content_items using gin(payload);

create index if not exists idx_admin_codex_notes_created
  on public.admin_codex_notes(created_at desc);

alter table public.admin_content_items enable row level security;
alter table public.admin_codex_notes enable row level security;

drop policy if exists "tom admin content select" on public.admin_content_items;
drop policy if exists "published admin content select" on public.admin_content_items;
drop policy if exists "tom admin content insert" on public.admin_content_items;
drop policy if exists "tom admin content update" on public.admin_content_items;
drop policy if exists "tom admin content delete" on public.admin_content_items;

create policy "tom admin content select"
  on public.admin_content_items
  for select
  to authenticated
  using (public.is_tom_admin());

create policy "published admin content select"
  on public.admin_content_items
  for select
  to anon, authenticated
  using (
    status in ('active', 'cut')
    and item_type in ('question', 'search', 'routine', 'vendor', 'task', 'system', 'category')
  );

create policy "tom admin content insert"
  on public.admin_content_items
  for insert
  to authenticated
  with check (public.is_tom_admin());

create policy "tom admin content update"
  on public.admin_content_items
  for update
  to authenticated
  using (public.is_tom_admin())
  with check (public.is_tom_admin());

create policy "tom admin content delete"
  on public.admin_content_items
  for delete
  to authenticated
  using (public.is_tom_admin());

drop policy if exists "tom admin notes select" on public.admin_codex_notes;
drop policy if exists "tom admin notes insert" on public.admin_codex_notes;
drop policy if exists "tom admin notes update" on public.admin_codex_notes;
drop policy if exists "tom admin notes delete" on public.admin_codex_notes;

create policy "tom admin notes select"
  on public.admin_codex_notes
  for select
  to authenticated
  using (public.is_tom_admin());

create policy "tom admin notes insert"
  on public.admin_codex_notes
  for insert
  to authenticated
  with check (public.is_tom_admin());

create policy "tom admin notes update"
  on public.admin_codex_notes
  for update
  to authenticated
  using (public.is_tom_admin())
  with check (public.is_tom_admin());

create policy "tom admin notes delete"
  on public.admin_codex_notes
  for delete
  to authenticated
  using (public.is_tom_admin());

create or replace function public.set_admin_content_items_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  new.updated_by = auth.uid();
  return new;
end;
$$;

drop trigger if exists set_admin_content_items_updated_at
  on public.admin_content_items;

create trigger set_admin_content_items_updated_at
  before update on public.admin_content_items
  for each row
  execute function public.set_admin_content_items_updated_at();
