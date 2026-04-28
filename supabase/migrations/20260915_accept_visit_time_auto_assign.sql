-- Phase 75f: when the homeowner accepts a proposed time, auto-create
-- a provider_visit_assignment for the sole-proprietor workspace
-- serving this request. Tom flagged that he had to manually click
-- "Assign" on the operations desk every time he confirmed a visit
-- with himself — that step is meaningless when there's only one
-- person who could possibly do the work.
--
-- Logic: after we confirm the time, look up the contractor → linked
-- provider workspace. If the workspace has exactly one active
-- member AND no assignment exists yet for this request, create one
-- bound to that member at the confirmed date/time. For multi-member
-- workspaces nothing changes — the dispatcher still picks a tech.

create or replace function public.accept_visit_time(
    p_request_id uuid,
    p_accepted_by_role text,
    p_note text default null
)
returns public.handyman_requests
language plpgsql
security invoker
as $$
declare
    v_request public.handyman_requests;
    v_message_body text;
    v_metadata jsonb;
    v_confirmed_date date;
    v_confirmed_time time;
    v_workspace_id uuid;
    v_active_count int;
    v_sole_member_id uuid;
    v_existing_assignment_id uuid;
begin
    if p_accepted_by_role not in ('homeowner', 'handyman') then
        raise exception 'accept_visit_time: accepted_by_role must be homeowner or handyman';
    end if;

    select * into v_request
        from public.handyman_requests
        where id = p_request_id
        for update;

    if not found then
        raise exception 'accept_visit_time: request % not found', p_request_id;
    end if;

    if v_request.proposed_visit_at is null then
        raise exception 'accept_visit_time: request % has no proposed time to accept', p_request_id;
    end if;

    update public.handyman_requests
        set confirmed_visit_at = v_request.proposed_visit_at,
            status = 'confirmed',
            updated_at = now()
        where id = p_request_id
        returning * into v_request;

    v_confirmed_date := (v_request.confirmed_visit_at at time zone 'UTC')::date;
    v_confirmed_time := (v_request.confirmed_visit_at at time zone 'UTC')::time;

    -- Sync existing assignment (if any) so the date matches the
    -- confirmation. For multi-member workspaces this also keeps the
    -- previously-picked tech assignment in place.
    update public.provider_visit_assignments
        set route_date = v_confirmed_date,
            window_start_time = v_confirmed_time,
            window_end_time = coalesce(window_end_time, v_confirmed_time + interval '2 hours'),
            updated_at = now()
        where request_id = p_request_id;

    if v_request.visit_task_id is not null then
        update public.maintenance_tasks
            set scheduled_date = v_confirmed_date,
                next_due_date = v_confirmed_date
            where id = v_request.visit_task_id;
    end if;

    -- ─── Sole-proprietor auto-assign ───────────────────────────────
    -- Only kicks in when the request has a contractor + that contractor
    -- is linked to exactly one provider workspace + the workspace has
    -- exactly one active member + no assignment exists yet.
    if v_request.contractor_id is not null then
        select pcl.workspace_id into v_workspace_id
            from public.provider_contractor_links pcl
            where pcl.contractor_id = v_request.contractor_id
            limit 1;

        if v_workspace_id is not null then
            select count(*), max(id) into v_active_count, v_sole_member_id
                from public.provider_workspace_members
                where workspace_id = v_workspace_id
                  and status = 'active';

            select id into v_existing_assignment_id
                from public.provider_visit_assignments
                where request_id = p_request_id
                  and workspace_id = v_workspace_id
                limit 1;

            if v_active_count = 1
               and v_sole_member_id is not null
               and v_existing_assignment_id is null then
                insert into public.provider_visit_assignments (
                    workspace_id,
                    request_id,
                    visit_task_id,
                    assigned_member_id,
                    route_date,
                    window_start_time,
                    window_end_time
                ) values (
                    v_workspace_id,
                    p_request_id,
                    v_request.visit_task_id,
                    v_sole_member_id,
                    v_confirmed_date,
                    v_confirmed_time,
                    v_confirmed_time + interval '2 hours'
                )
                on conflict (workspace_id, request_id) do nothing;
            end if;
        end if;
    end if;

    v_message_body := coalesce(
        nullif(trim(p_note), ''),
        case when p_accepted_by_role = 'handyman'
             then 'Confirmed.'
             else 'Confirmed.' end
    );

    v_metadata := jsonb_build_object(
        'kind', 'accept_time',
        'confirmed_at', to_char(v_request.confirmed_visit_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
        'accepted_by_role', p_accepted_by_role
    );

    insert into public.handyman_request_messages (
        request_id,
        household_id,
        sender_role,
        body,
        metadata
    ) values (
        p_request_id,
        v_request.household_id,
        case when p_accepted_by_role = 'handyman' then 'vendor' else 'homeowner' end,
        v_message_body,
        v_metadata
    );

    return v_request;
end;
$$;

grant execute on function public.accept_visit_time(
    uuid, text, text
) to authenticated, service_role;

-- Belt-and-suspenders: backfill assignments for any already-confirmed
-- requests where a sole-prop workspace serves them but no assignment
-- exists. Idempotent.
insert into public.provider_visit_assignments (
    workspace_id,
    request_id,
    visit_task_id,
    assigned_member_id,
    route_date,
    window_start_time,
    window_end_time
)
select pcl.workspace_id,
       hr.id,
       hr.visit_task_id,
       (
           select pwm.id
             from public.provider_workspace_members pwm
            where pwm.workspace_id = pcl.workspace_id
              and pwm.status = 'active'
            limit 1
       ),
       (hr.confirmed_visit_at at time zone 'UTC')::date,
       (hr.confirmed_visit_at at time zone 'UTC')::time,
       (hr.confirmed_visit_at at time zone 'UTC')::time + interval '2 hours'
  from public.handyman_requests hr
  join public.provider_contractor_links pcl
    on pcl.contractor_id = hr.contractor_id
 where hr.confirmed_visit_at is not null
   and hr.contractor_id is not null
   and not exists (
       select 1 from public.provider_visit_assignments pva
        where pva.request_id = hr.id and pva.workspace_id = pcl.workspace_id
   )
   and (
       select count(*) from public.provider_workspace_members pwm
        where pwm.workspace_id = pcl.workspace_id and pwm.status = 'active'
   ) = 1
on conflict (workspace_id, request_id) do nothing;
