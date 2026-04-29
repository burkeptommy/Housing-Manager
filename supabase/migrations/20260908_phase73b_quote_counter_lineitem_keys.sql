-- Phase 73 sub-phase B fix: counter_provider_quote was reading the
-- wrong line-item keys. The JSONB shape stored by the provider PWA
-- and iOS uses `unitPrice` / `quantity` (camelCase, no `unit_amount`),
-- so the original total computation in 20260907 always evaluated to 0.
-- Re-replace the function with the correct keys, with a snake_case
-- fallback for forward-compat.

create or replace function public.counter_provider_quote(
  p_quote_id uuid,
  p_revised_line_items jsonb,
  p_scope_notes_override text default null,
  p_note text default null
)
returns public.provider_quotes
language plpgsql
security definer
set search_path = public
as $$
declare
  v_household_id uuid;
  v_parent public.provider_quotes%rowtype;
  v_subtotal numeric(12,2) := 0;
  v_tax_total numeric(12,2) := 0;
  v_total numeric(12,2) := 0;
  v_item jsonb;
  v_quantity numeric;
  v_unit_amount numeric;
  v_tax_amount numeric;
  v_new_quote public.provider_quotes%rowtype;
  v_message_body text;
  v_metadata jsonb;
begin
  if p_revised_line_items is null or jsonb_typeof(p_revised_line_items) <> 'array' then
    raise exception 'counter_provider_quote: revised_line_items must be a JSON array'
      using errcode = '22023';
  end if;

  v_household_id := public.get_my_household_id();
  if v_household_id is null then
    raise exception 'Household access required' using errcode = '42501';
  end if;

  select * into v_parent
  from public.provider_quotes
  where id = p_quote_id
    and household_id = v_household_id
  for update;

  if not found then
    raise exception 'Quote not found' using errcode = 'P0002';
  end if;

  if v_parent.status not in ('sent', 'viewed', 'approved') then
    raise exception 'Quote in status % cannot be countered', v_parent.status
      using errcode = '22023';
  end if;

  -- Read both `unitPrice` (PWA / iOS shape) and `unit_price` (snake
  -- variant) and fall back to `unit_amount` for any future migration
  -- that might choose that key. `quantity` is consistent across all
  -- shapes.
  for v_item in select * from jsonb_array_elements(p_revised_line_items) loop
    v_quantity := coalesce((v_item->>'quantity')::numeric, 0);
    v_unit_amount := coalesce(
      (v_item->>'unitPrice')::numeric,
      (v_item->>'unit_price')::numeric,
      (v_item->>'unit_amount')::numeric,
      0
    );
    v_tax_amount := coalesce(
      (v_item->>'taxAmount')::numeric,
      (v_item->>'tax_amount')::numeric,
      0
    );
    v_subtotal := v_subtotal + (v_quantity * v_unit_amount);
    v_tax_total := v_tax_total + v_tax_amount;
  end loop;
  v_total := v_subtotal + v_tax_total;

  insert into public.provider_quotes (
    workspace_id,
    contractor_id,
    household_id,
    property_id,
    request_id,
    visit_task_id,
    title,
    status,
    currency,
    line_items,
    scope_notes,
    homeowner_message,
    subtotal,
    tax_total,
    total,
    parent_quote_id,
    homeowner_revised_at,
    recipient_kind,
    prospect_name,
    prospect_email,
    prospect_phone,
    prospect_address
  ) values (
    v_parent.workspace_id,
    v_parent.contractor_id,
    v_parent.household_id,
    v_parent.property_id,
    v_parent.request_id,
    v_parent.visit_task_id,
    v_parent.title,
    'countered_by_homeowner',
    v_parent.currency,
    p_revised_line_items,
    coalesce(nullif(btrim(p_scope_notes_override), ''), v_parent.scope_notes),
    nullif(btrim(coalesce(p_note, '')), ''),
    v_subtotal,
    v_tax_total,
    v_total,
    v_parent.id,
    now(),
    v_parent.recipient_kind,
    v_parent.prospect_name,
    v_parent.prospect_email,
    v_parent.prospect_phone,
    v_parent.prospect_address
  )
  returning * into v_new_quote;

  update public.provider_quotes
  set status = 'superseded',
      updated_at = now()
  where id = v_parent.id;

  if v_parent.request_id is not null then
    v_message_body := coalesce(
      nullif(btrim(p_note), ''),
      'Counter offer: ' || to_char(v_total, 'FM999,999,990.00') || ' ' || v_parent.currency
    );
    v_metadata := jsonb_build_object(
      'kind', 'counter_offer',
      'quote_id', v_new_quote.id,
      'parent_quote_id', v_parent.id,
      'total', v_total
    );
    insert into public.handyman_request_messages (
      request_id,
      household_id,
      sender_role,
      body,
      metadata
    ) values (
      v_parent.request_id,
      v_parent.household_id,
      'homeowner',
      v_message_body,
      v_metadata
    );
  end if;

  return v_new_quote;
end;
$$;
