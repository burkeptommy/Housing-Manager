-- Phase 72b: Standalone prospect quotes and quote-level delivery/collaboration.
--
-- Extends provider quotes so a handyman company can:
-- 1. Build and send quotes for standalone prospects that are not attached to a
--    Haven household yet.
-- 2. Share every quote through a secure public token link.
-- 3. Keep a quote-level collaboration trail for both linked-home and prospect
--    quotes.

alter table public.provider_quotes
  alter column household_id drop not null;

alter table public.provider_quotes
  add column if not exists recipient_kind text,
  add column if not exists prospect_name text,
  add column if not exists prospect_email text,
  add column if not exists prospect_phone text,
  add column if not exists prospect_address text,
  add column if not exists public_share_token text,
  add column if not exists last_sent_at timestamptz,
  add column if not exists sent_via jsonb not null default '[]'::jsonb;

update public.provider_quotes
set recipient_kind = case
  when household_id is null then 'prospect'
  else 'linked_home'
end
where recipient_kind is null;

update public.provider_quotes
set public_share_token = gen_random_uuid()::text
where public_share_token is null or btrim(public_share_token) = '';

alter table public.provider_quotes
  alter column recipient_kind set default 'linked_home';

alter table public.provider_quotes
  alter column recipient_kind set not null;

alter table public.provider_quotes
  alter column public_share_token set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'provider_quotes_recipient_kind_check'
  ) then
    alter table public.provider_quotes
      add constraint provider_quotes_recipient_kind_check
      check (recipient_kind in ('linked_home', 'prospect'));
  end if;
end $$;

create unique index if not exists idx_provider_quotes_public_share_token
  on public.provider_quotes (public_share_token);

create index if not exists idx_provider_quotes_prospect_email
  on public.provider_quotes (prospect_email, updated_at desc)
  where prospect_email is not null;

create table if not exists public.provider_quote_messages (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.provider_workspaces(id) on delete cascade,
  quote_id uuid not null references public.provider_quotes(id) on delete cascade,
  request_id uuid references public.handyman_requests(id) on delete set null,
  household_id uuid references public.households(id) on delete set null,
  sender_role text not null check (
    sender_role in ('provider', 'homeowner', 'prospect', 'haven')
  ),
  sender_name text,
  sender_email text,
  delivery_channel text not null default 'system' check (
    delivery_channel in ('system', 'email', 'web', 'in_app')
  ),
  body text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_provider_quote_messages_workspace
  on public.provider_quote_messages (workspace_id, created_at desc);

create index if not exists idx_provider_quote_messages_quote
  on public.provider_quote_messages (quote_id, created_at asc);

create index if not exists idx_provider_quote_messages_request
  on public.provider_quote_messages (request_id, created_at asc)
  where request_id is not null;

alter table public.provider_quote_messages enable row level security;

drop policy if exists "provider_quote_messages_provider_all" on public.provider_quote_messages;
create policy "provider_quote_messages_provider_all"
  on public.provider_quote_messages
  using (workspace_id in (select public.get_my_provider_workspace_ids()))
  with check (workspace_id in (select public.get_my_provider_workspace_ids()));
