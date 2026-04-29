create or replace function public.respond_to_provider_quote(
  p_quote_id uuid,
  p_response_status text,
  p_homeowner_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_quote public.provider_quotes%rowtype;
  v_household_id uuid;
  v_note text;
  v_body text;
begin
  if p_response_status not in ('viewed', 'approved', 'declined') then
    raise exception 'Unsupported quote response: %', p_response_status
      using errcode = '22023';
  end if;

  v_household_id := public.get_my_household_id();
  if v_household_id is null then
    raise exception 'Household access required'
      using errcode = '42501';
  end if;

  select *
  into v_quote
  from public.provider_quotes
  where id = p_quote_id
    and household_id = v_household_id
  for update;

  if not found then
    raise exception 'Quote not found'
      using errcode = 'P0002';
  end if;

  v_note := nullif(btrim(coalesce(p_homeowner_note, '')), '');

  if p_response_status = 'viewed' then
    if v_quote.status = 'sent' then
      update public.provider_quotes
      set status = 'viewed',
          viewed_at = coalesce(viewed_at, now()),
          updated_at = now()
      where id = v_quote.id
      returning * into v_quote;
    elsif v_quote.viewed_at is null then
      update public.provider_quotes
      set viewed_at = now(),
          updated_at = now()
      where id = v_quote.id
      returning * into v_quote;
    end if;

    return to_jsonb(v_quote);
  end if;

  if p_response_status = 'approved' then
    if v_quote.status = 'approved' and v_note is null then
      return to_jsonb(v_quote);
    end if;

    update public.provider_quotes
    set status = 'approved',
        viewed_at = coalesce(viewed_at, now()),
        approved_at = coalesce(approved_at, now()),
        declined_at = null,
        updated_at = now()
    where id = v_quote.id
    returning * into v_quote;

    v_body := 'The homeowner approved the quote.';
  else
    if v_quote.status = 'declined' and v_note is null then
      return to_jsonb(v_quote);
    end if;

    update public.provider_quotes
    set status = 'declined',
        viewed_at = coalesce(viewed_at, now()),
        declined_at = coalesce(declined_at, now()),
        approved_at = null,
        updated_at = now()
    where id = v_quote.id
    returning * into v_quote;

    v_body := 'The homeowner declined the quote.';
  end if;

  if v_note is not null then
    v_body := v_body || ' Note: ' || v_note;
  end if;

  if v_quote.request_id is not null then
    insert into public.handyman_request_messages (
      request_id,
      household_id,
      sender_role,
      body,
      metadata
    )
    values (
      v_quote.request_id,
      v_quote.household_id,
      'homeowner',
      v_body,
      jsonb_build_object(
        'event',
        case
          when p_response_status = 'approved' then 'quote_approved'
          else 'quote_declined'
        end,
        'quote_id',
        v_quote.id
      )
    );

    update public.handyman_requests
    set updated_at = now()
    where id = v_quote.request_id;
  end if;

  return to_jsonb(v_quote);
end;
$$;

grant execute on function public.respond_to_provider_quote(uuid, text, text) to authenticated;
