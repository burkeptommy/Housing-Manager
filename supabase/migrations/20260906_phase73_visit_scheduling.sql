-- Phase 73 (sub-phase A): bidirectional visit-time proposals.
--
-- The handyman_requests table already carries enough status states to
-- model the round-trip (`alternate_dates_proposed`, `awaiting_homeowner`,
-- `confirmed`) but has no columns for the proposed time itself or the
-- side that proposed it. This migration adds those columns and wires a
-- `propose_visit_time` function that both sides call to walk the state
-- machine atomically (state update + audit message in one transaction).
--
-- Backwards-compat: every column is nullable. Existing rows continue to
-- work — `confirmed_visit_at IS NULL` simply means "no time confirmed
-- yet". The function is an additive RPC; nothing in older code paths
-- needs to call it.

alter table public.handyman_requests
    add column if not exists proposed_visit_at timestamptz,
    add column if not exists proposed_by_role text,
    add column if not exists proposed_at timestamptz,
    add column if not exists confirmed_visit_at timestamptz;

alter table public.handyman_requests
    drop constraint if exists handyman_requests_proposed_by_role_check;

alter table public.handyman_requests
    add constraint handyman_requests_proposed_by_role_check check (
        proposed_by_role is null
        or proposed_by_role in ('homeowner', 'handyman')
    );

create index if not exists idx_handyman_requests_confirmed_visit
    on public.handyman_requests(confirmed_visit_at)
    where confirmed_visit_at is not null;

-- The message metadata gets a `kind` discriminator so the iOS chat view
-- and provider dispatch board can render system events (proposals,
-- accepts, declines) differently from free-text replies. Older messages
-- with `metadata = '{}'` are treated as `kind = "text"` by both readers.
comment on column public.handyman_request_messages.metadata is
    'Optional JSON. Recognized keys: kind (text|propose_time|accept_time|decline_time), proposed_at (ISO timestamp), proposed_by_role (homeowner|handyman).';

-- propose_visit_time(request_id, proposed_at, proposed_by_role, note)
--
-- Single round-trip: writes the proposed time onto the request, walks
-- the status machine to the right "ball is in the other side's court"
-- state, and appends a system message to the thread. Returns the
-- updated request row.
--
-- Status transitions:
--   homeowner proposes  → status = 'awaiting_homeowner' if handyman
--                          previously proposed and we're countering;
--                         otherwise 'alternate_dates_proposed' (handyman
--                         needs to look at it).
--   handyman proposes   → 'alternate_dates_proposed' (homeowner needs
--                         to look at it).
--
-- We keep the rule simple: whoever just proposed leaves the ball in the
-- OTHER side's court. The iOS / dispatch UIs read the latest
-- `proposed_by_role` to decide which buttons to show.
create or replace function public.propose_visit_time(
    p_request_id uuid,
    p_proposed_at timestamptz,
    p_proposed_by_role text,
    p_note text default null
)
returns public.handyman_requests
language plpgsql
security invoker
as $$
declare
    v_request public.handyman_requests;
    v_household_id uuid;
    v_new_status text;
    v_message_body text;
    v_metadata jsonb;
begin
    if p_proposed_by_role not in ('homeowner', 'handyman') then
        raise exception 'propose_visit_time: proposed_by_role must be homeowner or handyman';
    end if;

    if p_proposed_at is null then
        raise exception 'propose_visit_time: proposed_at is required';
    end if;

    -- Lock the row so two concurrent proposals don't race.
    select * into v_request
        from public.handyman_requests
        where id = p_request_id
        for update;

    if not found then
        raise exception 'propose_visit_time: request % not found', p_request_id;
    end if;

    v_household_id := v_request.household_id;

    if p_proposed_by_role = 'handyman' then
        v_new_status := 'alternate_dates_proposed';
    else
        -- Homeowner side. If we're the first proposer the handyman
        -- still needs to react, so use the same alternate-dates state
        -- (it just means "someone proposed something, the other side
        -- needs to respond"). If the handyman previously proposed and
        -- the homeowner is countering, ball returns to handyman and
        -- the same state is correct.
        v_new_status := 'alternate_dates_proposed';
    end if;

    update public.handyman_requests
        set proposed_visit_at = p_proposed_at,
            proposed_by_role = p_proposed_by_role,
            proposed_at = now(),
            status = v_new_status,
            updated_at = now()
        where id = p_request_id
        returning * into v_request;

    v_message_body := coalesce(
        nullif(trim(p_note), ''),
        'Proposed ' ||
            to_char(p_proposed_at at time zone 'UTC', 'Mon DD, YYYY at HH24:MI') ||
            ' UTC.'
    );

    v_metadata := jsonb_build_object(
        'kind', 'propose_time',
        'proposed_at', to_char(p_proposed_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
        'proposed_by_role', p_proposed_by_role
    );

    insert into public.handyman_request_messages (
        request_id,
        household_id,
        sender_role,
        body,
        metadata
    ) values (
        p_request_id,
        v_household_id,
        case when p_proposed_by_role = 'handyman' then 'vendor' else 'homeowner' end,
        v_message_body,
        v_metadata
    );

    return v_request;
end;
$$;

grant execute on function public.propose_visit_time(
    uuid, timestamptz, text, text
) to authenticated, service_role;

-- accept_visit_time(request_id, accepted_by_role, note)
--
-- Locks in the most recent proposal. Sets `confirmed_visit_at = proposed_visit_at`
-- and walks status to 'confirmed'. The accepting side is RECORDED in the
-- system message, but only the side that DIDN'T propose can call this
-- (an actor accepting their own proposal is a no-op the UIs prevent).
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
