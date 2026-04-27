-- Phase 74 follow-up: enable Realtime broadcasting for handyman tables.
--
-- The Phase 74 migration added provider-side SELECT policies but the
-- tables weren't in the supabase_realtime publication, so Postgres
-- never broadcast change events even though the policies allowed reads.

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
