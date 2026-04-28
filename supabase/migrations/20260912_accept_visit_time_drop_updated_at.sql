-- Phase 75c: maintenance_tasks doesn't have an updated_at column
-- (only created_at) — yesterday's accept_visit_time RPC update tried
-- to write updated_at = now() and Postgres rejected it. Drop the
-- offending column from the RPC's maintenance_tasks update.

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

    -- Sync any provider assignment for this request so the operations
    -- desk Calendar / Routes / Visits surfaces show the confirmed
    -- date.
    v_confirmed_date := (v_request.confirmed_visit_at at time zone 'UTC')::date;
    v_confirmed_time := (v_request.confirmed_visit_at at time zone 'UTC')::time;

    update public.provider_visit_assignments
        set route_date = v_confirmed_date,
            window_start_time = v_confirmed_time,
            window_end_time = coalesce(window_end_time, v_confirmed_time + interval '2 hours'),
            updated_at = now()
        where request_id = p_request_id;

    -- Also keep the linked maintenance_task aligned so iOS surfaces
    -- that read scheduled_date catch up. NOTE: maintenance_tasks has
    -- only created_at — no updated_at column.
    if v_request.visit_task_id is not null then
        update public.maintenance_tasks
            set scheduled_date = to_char(v_confirmed_date, 'YYYY-MM-DD'),
                next_due_date = to_char(v_confirmed_date, 'YYYY-MM-DD')
            where id = v_request.visit_task_id;
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
