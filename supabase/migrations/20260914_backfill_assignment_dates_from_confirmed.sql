-- Phase 75e: backfill assignment + task dates from confirmed_visit_at.
--
-- The first version of accept_visit_time (Phase 73) only updated
-- handyman_requests.confirmed_visit_at. The Phase 75b/75c/75d
-- migrations extended it to also bump provider_visit_assignments.
-- route_date and maintenance_tasks.scheduled_date / next_due_date.
-- Any request that was confirmed before those migrations landed has
-- a stale assignment + task date, which is what's making Tom's
-- operations desk show the original date even though the homeowner
-- already accepted the new one.
--
-- One-shot UPDATE to sync everything. Idempotent — only writes when
-- the destination value actually differs from the confirmed date.

update public.provider_visit_assignments pva
set route_date = (hr.confirmed_visit_at at time zone 'UTC')::date,
    window_start_time = coalesce(
        pva.window_start_time,
        (hr.confirmed_visit_at at time zone 'UTC')::time
    ),
    window_end_time = coalesce(
        pva.window_end_time,
        (hr.confirmed_visit_at at time zone 'UTC')::time + interval '2 hours'
    ),
    updated_at = now()
from public.handyman_requests hr
where pva.request_id = hr.id
  and hr.confirmed_visit_at is not null
  and (
    pva.route_date is distinct from (hr.confirmed_visit_at at time zone 'UTC')::date
  );

update public.maintenance_tasks mt
set scheduled_date = (hr.confirmed_visit_at at time zone 'UTC')::date,
    next_due_date = (hr.confirmed_visit_at at time zone 'UTC')::date
from public.handyman_requests hr
where mt.id = hr.visit_task_id
  and hr.confirmed_visit_at is not null
  and (
    mt.scheduled_date is distinct from (hr.confirmed_visit_at at time zone 'UTC')::date
    or mt.next_due_date is distinct from (hr.confirmed_visit_at at time zone 'UTC')::date
  );
