-- Sprint #4 R5-E-10 fix: hard dedup for rapid-fire follow-up suggestion
-- creates. The edge function uses a SELECT-then-INSERT dedup gate, which
-- collapses sequential double-taps but loses to truly-concurrent calls
-- (both SELECTs read NULL before either INSERT lands). A partial unique
-- index makes the second INSERT fail at the database level — the second
-- caller's INSERT errors out and the function falls back to returning the
-- first row's id idempotently.
--
-- Scope: only constrain rows where suggested_by_request_id is not null
-- AND status is "open" (i.e. the contractor-suggested follow-up rows
-- this dedup gate cares about). User-edited or system-flipped tasks
-- can have duplicate titles within the same household.

-- maintenance_tasks: (suggested_by_request_id, title) is unique among
-- contractor-suggested rows that haven't been completed/cancelled yet.
do $$
begin
  if exists (select 1 from information_schema.columns
             where table_name = 'maintenance_tasks'
               and column_name = 'suggested_by_request_id') then
    create unique index if not exists uq_maintenance_tasks_suggestion_dedup
      on public.maintenance_tasks (suggested_by_request_id, title)
      where suggested_by_request_id is not null
        and source = 'contractor_suggestion'
        and (last_completed_date is null);
  end if;
end$$;

-- provider_quotes: (suggested_by_request_id, title) is unique among
-- draft suggestion rows. Sent / approved / signed quotes can have
-- legitimately-duplicate titles within the same workspace.
do $$
begin
  if exists (select 1 from information_schema.columns
             where table_name = 'provider_quotes'
               and column_name = 'suggested_by_request_id') then
    create unique index if not exists uq_provider_quotes_suggestion_dedup
      on public.provider_quotes (suggested_by_request_id, title)
      where suggested_by_request_id is not null
        and status = 'draft';
  end if;
end$$;

-- handyman_requests follow-ups: (parent_request_id, title, proposed_visit_at)
-- unique among non-cancelled descendants. The edge function's dedup gate
-- uses the same triple.
do $$
begin
  if exists (select 1 from information_schema.columns
             where table_name = 'handyman_requests'
               and column_name = 'parent_request_id') then
    create unique index if not exists uq_handyman_requests_followup_dedup
      on public.handyman_requests (parent_request_id, title, proposed_visit_at)
      where parent_request_id is not null
        and status not in ('cancelled', 'declined');
  end if;
end$$;
