-- Phase 73 sub-phase B: quote negotiation + signed agreement.
--
-- Today the homeowner can approve, decline, or view a provider quote.
-- That's the whole vocabulary. This migration adds:
--
--   1. parent_quote_id   FK chain so a counter-offer or a provider
--                        revision points back at the version it grew
--                        out of. Lets us render the history of a quote
--                        on both sides without losing prior versions.
--
--   2. signed_at,        Captured when a homeowner approves so we have
--      signed_name       a timestamp + the name they typed at sign
--                        time. Acts as the homeowner's signed agreement.
--
--   3. homeowner_revised_at   Stamped by counter_provider_quote so the
--                             provider can sort/filter by "countered
--                             quotes that need a re-quote".
--
--   4. New statuses:
--      `countered_by_homeowner` — the homeowner edited line items and
--        sent it back. Provider should re-quote (build a new revision
--        with parent_quote_id pointing at the countered version) or
--        accept the homeowner's revision as-is by approving it.
--      `superseded` — terminal state for any quote that has been
--        replaced by a child revision. Keeps the row for audit but
--        flips it out of "active" filters.
--
-- Backwards-compat: every column is nullable, every new status is an
-- additional CHECK option. Existing rows keep working unchanged.

alter table public.provider_quotes
  add column if not exists parent_quote_id uuid references public.provider_quotes(id) on delete set null,
  add column if not exists signed_at timestamptz,
  add column if not exists signed_name text,
  add column if not exists homeowner_revised_at timestamptz;

-- Drop the old CHECK and re-add with new statuses.
alter table public.provider_quotes
  drop constraint if exists provider_quotes_status_check;

alter table public.provider_quotes
  add constraint provider_quotes_status_check check (
    status in (
      'draft',
      'sent',
      'viewed',
      'approved',
      'declined',
      'withdrawn',
      'countered_by_homeowner',
      'superseded'
    )
  );

create index if not exists idx_provider_quotes_parent
  on public.provider_quotes(parent_quote_id)
  where parent_quote_id is not null;

create index if not exists idx_provider_quotes_homeowner_revised
  on public.provider_quotes(homeowner_revised_at desc)
  where homeowner_revised_at is not null;

-- ---------------------------------------------------------------
-- counter_provider_quote(quote_id, revised_line_items, scope_notes_override, note)
--
-- The homeowner has edited line items on a `sent`/`viewed` quote and
-- wants to send it back as a counter. We:
--   1. Validate household ownership via get_my_household_id().
--   2. Clone the quote into a new row, copying every shape-relevant
--      column from the parent (workspace, household, property, etc.),
--      stamping `parent_quote_id` to the parent, dropping in the
--      revised line items, recomputing the totals, and marking
--      `status = 'countered_by_homeowner'`, `homeowner_revised_at = now()`.
--   3. Mark the parent row `status = 'superseded'`.
--   4. Append a `kind = "counter_offer"` system event to the request
--      thread (handyman_request_messages) when the parent has a request_id.
--
-- The provider sees the new row in their dashboard with the
-- "countered" status and re-quotes by either inserting a fresh draft
-- with parent_quote_id pointing at the countered row, or by approving
-- the countered row as-is via their existing send-quote flow.
-- ---------------------------------------------------------------
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

  -- Recompute totals from the revised line items. Each item is
  -- expected to carry numeric `quantity`, `unit_amount`, optional
  -- `tax_amount`. Anything missing falls back to 0 so a malformed
  -- item only affects its own contribution to the total.
  for v_item in select * from jsonb_array_elements(p_revised_line_items) loop
    v_quantity := coalesce((v_item->>'quantity')::numeric, 0);
    v_unit_amount := coalesce((v_item->>'unit_amount')::numeric, 0);
    v_tax_amount := coalesce((v_item->>'tax_amount')::numeric, 0);
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

  -- Append a system event to the request thread so both sides see the
  -- counter on their conversation timelines. No-op when the parent
  -- isn't tied to a request (standalone prospect quotes).
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

grant execute on function public.counter_provider_quote(uuid, jsonb, text, text) to authenticated;

-- ---------------------------------------------------------------
-- sign_provider_quote(quote_id, signed_name)
--
-- Approves a quote and captures the homeowner's typed name as a
-- lightweight signature record. Walks status to 'approved', stamps
-- approved_at + signed_at + signed_name. Appends a
-- `kind = "quote_signed"` event to the request thread.
--
-- This is a thin wrapper over the existing approve path — callers
-- can still use respond_to_provider_quote(quote_id, 'approved', ...)
-- for the unsigned approval flow, but the iOS approve button now
-- routes through this so we always have a signed record.
-- ---------------------------------------------------------------
create or replace function public.sign_provider_quote(
  p_quote_id uuid,
  p_signed_name text,
  p_homeowner_note text default null
)
returns public.provider_quotes
language plpgsql
security definer
set search_path = public
as $$
declare
  v_household_id uuid;
  v_quote public.provider_quotes%rowtype;
  v_trimmed_name text;
  v_message_body text;
  v_metadata jsonb;
begin
  v_trimmed_name := nullif(btrim(coalesce(p_signed_name, '')), '');
  if v_trimmed_name is null then
    raise exception 'Signed name is required' using errcode = '22023';
  end if;

  v_household_id := public.get_my_household_id();
  if v_household_id is null then
    raise exception 'Household access required' using errcode = '42501';
  end if;

  select * into v_quote
  from public.provider_quotes
  where id = p_quote_id
    and household_id = v_household_id
  for update;

  if not found then
    raise exception 'Quote not found' using errcode = 'P0002';
  end if;

  if v_quote.status not in ('sent', 'viewed', 'countered_by_homeowner') then
    raise exception 'Quote in status % cannot be signed', v_quote.status
      using errcode = '22023';
  end if;

  update public.provider_quotes
  set status = 'approved',
      approved_at = coalesce(approved_at, now()),
      signed_at = now(),
      signed_name = v_trimmed_name,
      updated_at = now()
  where id = p_quote_id
  returning * into v_quote;

  if v_quote.request_id is not null then
    v_message_body := coalesce(
      nullif(btrim(p_homeowner_note), ''),
      v_trimmed_name || ' signed the quote.'
    );
    v_metadata := jsonb_build_object(
      'kind', 'quote_signed',
      'quote_id', v_quote.id,
      'signed_name', v_trimmed_name,
      'signed_at', to_char(v_quote.signed_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
      'total', v_quote.total
    );
    insert into public.handyman_request_messages (
      request_id,
      household_id,
      sender_role,
      body,
      metadata
    ) values (
      v_quote.request_id,
      v_quote.household_id,
      'homeowner',
      v_message_body,
      v_metadata
    );
  end if;

  return v_quote;
end;
$$;

grant execute on function public.sign_provider_quote(uuid, text, text) to authenticated;
