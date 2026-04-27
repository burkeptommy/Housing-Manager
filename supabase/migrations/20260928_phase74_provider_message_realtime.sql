-- Phase 74: Let providers subscribe to message Realtime.
--
-- Until now, `handyman_request_messages` had a single RLS policy
-- scoping reads to the homeowner via `get_my_household_id()`. The
-- Operations Desk only saw messages because the `handyman-provider`
-- Edge Function uses the service role to bypass RLS.
--
-- That works for reads through the function but blocks Realtime: the
-- Supabase Realtime engine evaluates RLS as the connected user when
-- deciding whether to push a row, and the provider has no household
-- match → no events delivered → chat felt one-way on the web side.
--
-- This migration adds a parallel SELECT policy so providers can read
-- messages for requests whose contractor belongs to their workspace.
-- Writes are unchanged: the existing homeowner policy stays intact;
-- provider writes still go through the Edge Function (service role).

drop policy if exists "handyman_request_messages_provider_select"
  on public.handyman_request_messages;

create policy "handyman_request_messages_provider_select"
  on public.handyman_request_messages
  for select
  using (
    request_id in (
      select req.id
      from public.handyman_requests req
      join public.provider_contractor_links link
        on link.contractor_id = req.contractor_id
      where link.workspace_id in (
        select public.get_my_provider_workspace_ids()
      )
    )
  );

-- Companion policy for the parallel handyman_requests table so
-- providers can also subscribe to new request inserts (e.g. a new
-- homeowner books a visit and we want it to pop into the Operations
-- Desk Unassigned column without a refresh).

drop policy if exists "handyman_requests_provider_select"
  on public.handyman_requests;

create policy "handyman_requests_provider_select"
  on public.handyman_requests
  for select
  using (
    contractor_id in (
      select link.contractor_id
      from public.provider_contractor_links link
      where link.workspace_id in (
        select public.get_my_provider_workspace_ids()
      )
    )
  );

-- Ensure both tables are in the supabase_realtime publication. Without
-- this the policies above are ignored — Postgres won't broadcast changes
-- on tables not in the publication. Wrapped in a DO block so re-running
-- the migration is idempotent.

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'handyman_request_messages'
  ) then
    alter publication supabase_realtime add table public.handyman_request_messages;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'handyman_requests'
  ) then
    alter publication supabase_realtime add table public.handyman_requests;
  end if;
end $$;
