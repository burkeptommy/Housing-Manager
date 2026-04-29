-- Admin Lab v2 — extends the onboarding-lab schema (20261001) so the admin
-- can capture rich note context, threaded Claude replies, applied/reverted
-- lifecycle, image attachments, launch_status approvals, and aggregated
-- usage stats for the Usage tab on each detail panel.
--
-- All admin reads/writes stay gated by is_tom_admin() (defined in 20261001).

-- =========================================================================
-- 1. admin_codex_notes — note schema enrichment
-- =========================================================================

alter table public.admin_codex_notes
  add column if not exists target text not null default 'claude'
    check (target in ('claude', 'codex', 'both'));

alter table public.admin_codex_notes
  add column if not exists intent text not null default 'feedback'
    check (intent in (
      'feedback',
      'change_request',
      'proposal_add',
      'proposal_delete',
      'bug',
      'idea',
      'question_for_claude'
    ));

alter table public.admin_codex_notes
  add column if not exists author text not null default 'tom'
    check (author in ('tom', 'claude'));

alter table public.admin_codex_notes
  add column if not exists proposed_diff jsonb;

alter table public.admin_codex_notes
  add column if not exists applied_at timestamptz;

alter table public.admin_codex_notes
  add column if not exists applied_commit text;

alter table public.admin_codex_notes
  add column if not exists parent_note_id uuid references public.admin_codex_notes(id) on delete cascade;

alter table public.admin_codex_notes
  add column if not exists reverted_at timestamptz;

alter table public.admin_codex_notes
  add column if not exists superseded_by_note_id uuid references public.admin_codex_notes(id) on delete set null;

alter table public.admin_codex_notes
  add column if not exists attachment_urls jsonb not null default '[]'::jsonb;

alter table public.admin_codex_notes
  add column if not exists applied_validated_at timestamptz;

alter table public.admin_codex_notes
  add column if not exists apply_validation_status text
    check (apply_validation_status in ('pending', 'success', 'failed'));

alter table public.admin_codex_notes
  add column if not exists apply_validation_log text;

alter table public.admin_codex_notes
  add column if not exists bulk_op_id uuid;

create index if not exists idx_admin_codex_notes_parent
  on public.admin_codex_notes(parent_note_id);

create index if not exists idx_admin_codex_notes_pending
  on public.admin_codex_notes(applied_at, intent)
  where applied_at is null;

create index if not exists idx_admin_codex_notes_target_scope
  on public.admin_codex_notes(target, scope_type, scope_id)
  where applied_at is null;

create index if not exists idx_admin_codex_notes_bulk_op
  on public.admin_codex_notes(bulk_op_id)
  where bulk_op_id is not null;

-- =========================================================================
-- 2. admin_content_items — launch_status approval workflow
-- =========================================================================

alter table public.admin_content_items
  add column if not exists launch_status text not null default 'draft'
    check (launch_status in ('draft', 'staged', 'approved', 'shipped', 'sunset'));

alter table public.admin_content_items
  add column if not exists locked_at timestamptz;

alter table public.admin_content_items
  add column if not exists locked_by uuid;

alter table public.admin_content_items
  add column if not exists reviewed_at timestamptz;

create index if not exists idx_admin_content_items_launch_status
  on public.admin_content_items(item_type, launch_status, sort_order);

-- =========================================================================
-- 3. Storage bucket for note attachments (screenshots, PDFs)
-- =========================================================================

insert into storage.buckets (id, name, public)
values ('admin-attachments', 'admin-attachments', false)
on conflict (id) do nothing;

drop policy if exists "admin attachments tom select" on storage.objects;
drop policy if exists "admin attachments tom insert" on storage.objects;
drop policy if exists "admin attachments tom update" on storage.objects;
drop policy if exists "admin attachments tom delete" on storage.objects;

create policy "admin attachments tom select"
  on storage.objects for select
  to authenticated
  using (bucket_id = 'admin-attachments' and public.is_tom_admin());

create policy "admin attachments tom insert"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'admin-attachments' and public.is_tom_admin());

create policy "admin attachments tom update"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'admin-attachments' and public.is_tom_admin())
  with check (bucket_id = 'admin-attachments' and public.is_tom_admin());

create policy "admin attachments tom delete"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'admin-attachments' and public.is_tom_admin());

-- =========================================================================
-- 4. Stats RPCs — aggregated, RLS-safe usage data for the Usage tab
-- =========================================================================

-- Quiz question stats: drop-off, distribution, completion. Reads
-- properties.house_quiz_state JSONB which holds {started_at, completed_at,
-- answers: { qX_id: { answerId, customText, ... } }}.
create or replace function public.admin_quiz_question_stats(p_question_id text)
returns jsonb
language plpgsql
security definer
stable
as $$
declare
  v_started_count int := 0;
  v_completed_count int := 0;
  v_answered_count int := 0;
  v_distribution jsonb := '{}'::jsonb;
begin
  if not public.is_tom_admin() then
    raise exception 'forbidden';
  end if;

  select count(*) into v_started_count
  from public.properties
  where house_quiz_state is not null
    and house_quiz_state ? 'started_at';

  select count(*) into v_completed_count
  from public.properties
  where house_quiz_state is not null
    and (house_quiz_state ->> 'completed_at') is not null;

  select count(*) into v_answered_count
  from public.properties
  where house_quiz_state -> 'answers' ? p_question_id;

  select coalesce(
    jsonb_object_agg(answer_id, n),
    '{}'::jsonb
  ) into v_distribution
  from (
    select
      coalesce(
        house_quiz_state -> 'answers' -> p_question_id ->> 'answerId',
        '_unanswered'
      ) as answer_id,
      count(*) as n
    from public.properties
    where house_quiz_state -> 'answers' ? p_question_id
    group by 1
  ) buckets;

  return jsonb_build_object(
    'question_id', p_question_id,
    'started_count', v_started_count,
    'completed_count', v_completed_count,
    'answered_count', v_answered_count,
    'drop_off_rate',
      case
        when v_started_count > 0
        then round(1 - (v_answered_count::numeric / v_started_count), 3)
        else null
      end,
    'distribution', v_distribution
  );
end;
$$;

revoke all on function public.admin_quiz_question_stats(text) from public, anon;
grant execute on function public.admin_quiz_question_stats(text) to authenticated;

-- Template stats: seeded / completed / archived counts + completion rate.
-- maintenance_tasks.template_id holds the template_key (category:title).
create or replace function public.admin_template_stats(p_template_key text)
returns jsonb
language plpgsql
security definer
stable
as $$
declare
  v_seeded int := 0;
  v_completed int := 0;
  v_archived int := 0;
  v_overdue int := 0;
  v_distinct_properties int := 0;
begin
  if not public.is_tom_admin() then
    raise exception 'forbidden';
  end if;

  select count(*) into v_seeded
  from public.maintenance_tasks
  where template_id = p_template_key;

  select count(*) into v_completed
  from public.maintenance_tasks
  where template_id = p_template_key
    and completed_at is not null;

  select count(*) into v_archived
  from public.maintenance_tasks
  where template_id = p_template_key
    and archived_at is not null;

  select count(*) into v_overdue
  from public.maintenance_tasks
  where template_id = p_template_key
    and completed_at is null
    and archived_at is null
    and scheduled_date is not null
    and scheduled_date < current_date;

  select count(distinct property_id) into v_distinct_properties
  from public.maintenance_tasks
  where template_id = p_template_key
    and property_id is not null;

  return jsonb_build_object(
    'template_key', p_template_key,
    'seeded_count', v_seeded,
    'completed_count', v_completed,
    'archived_count', v_archived,
    'overdue_count', v_overdue,
    'distinct_properties', v_distinct_properties,
    'completion_rate',
      case
        when v_seeded > 0
        then round(v_completed::numeric / v_seeded, 3)
        else null
      end,
    'archive_rate',
      case
        when v_seeded > 0
        then round(v_archived::numeric / v_seeded, 3)
        else null
      end
  );
end;
$$;

revoke all on function public.admin_template_stats(text) from public, anon;
grant execute on function public.admin_template_stats(text) to authenticated;

-- System category stats: how many properties carry this category.
create or replace function public.admin_system_category_stats(p_category_key text)
returns jsonb
language plpgsql
security definer
stable
as $$
declare
  v_property_count int := 0;
  v_with_vendor int := 0;
  v_with_open_task int := 0;
begin
  if not public.is_tom_admin() then
    raise exception 'forbidden';
  end if;

  select count(distinct property_id) into v_property_count
  from public.home_systems
  where lower(category) = lower(p_category_key);

  begin
    select count(distinct hs.property_id) into v_with_vendor
    from public.home_systems hs
    where lower(hs.category) = lower(p_category_key)
      and exists (
        select 1 from public.contractors c
        where lower(coalesce(c.category, '')) = lower(p_category_key)
          and c.household_id = (
            select household_id from public.properties
            where id = hs.property_id
          )
      );
  exception
    when others then v_with_vendor := 0;
  end;

  begin
    select count(distinct hs.property_id) into v_with_open_task
    from public.home_systems hs
    where lower(hs.category) = lower(p_category_key)
      and exists (
        select 1 from public.maintenance_tasks mt
        where mt.system_id = hs.id
          and mt.completed_at is null
          and mt.archived_at is null
      );
  exception
    when others then v_with_open_task := 0;
  end;

  return jsonb_build_object(
    'category_key', p_category_key,
    'property_count', v_property_count,
    'with_vendor_count', v_with_vendor,
    'with_open_task_count', v_with_open_task,
    'vendor_coverage_rate',
      case
        when v_property_count > 0
        then round(v_with_vendor::numeric / v_property_count, 3)
        else null
      end
  );
end;
$$;

revoke all on function public.admin_system_category_stats(text) from public, anon;
grant execute on function public.admin_system_category_stats(text) to authenticated;

-- Routine kind stats: active/paused/archived counts by routine_kind.
create or replace function public.admin_routine_kind_stats(p_kind text)
returns jsonb
language plpgsql
security definer
stable
as $$
declare
  v_active int := 0;
  v_paused int := 0;
  v_archived int := 0;
  v_avg_confidence numeric := null;
begin
  if not public.is_tom_admin() then
    raise exception 'forbidden';
  end if;

  begin
    select
      count(*) filter (where archived_at is null and is_paused = false),
      count(*) filter (where archived_at is null and is_paused = true),
      count(*) filter (where archived_at is not null),
      avg(confidence_score) filter (where confidence_score is not null)
    into v_active, v_paused, v_archived, v_avg_confidence
    from public.routines
    where routine_kind = p_kind;
  exception
    when others then
      v_active := 0;
      v_paused := 0;
      v_archived := 0;
  end;

  return jsonb_build_object(
    'kind', p_kind,
    'active_count', v_active,
    'paused_count', v_paused,
    'archived_count', v_archived,
    'avg_confidence_score',
      case when v_avg_confidence is not null then round(v_avg_confidence, 3) else null end
  );
end;
$$;

revoke all on function public.admin_routine_kind_stats(text) from public, anon;
grant execute on function public.admin_routine_kind_stats(text) to authenticated;

-- Surface-wide rollup: total counts across all properties for a launch dashboard.
create or replace function public.admin_lab_overview()
returns jsonb
language plpgsql
security definer
stable
as $$
declare
  v_quiz_starts int := 0;
  v_quiz_completes int := 0;
  v_total_tasks int := 0;
  v_active_routines int := 0;
  v_active_properties int := 0;
  v_open_notes int := 0;
  v_pending_proposals int := 0;
  v_approved_items int := 0;
  v_total_items int := 0;
begin
  if not public.is_tom_admin() then
    raise exception 'forbidden';
  end if;

  select
    count(*) filter (where house_quiz_state ? 'started_at'),
    count(*) filter (where (house_quiz_state ->> 'completed_at') is not null)
  into v_quiz_starts, v_quiz_completes
  from public.properties;

  select count(*) into v_active_properties
  from public.properties
  where archived_at is null;

  select count(*) into v_total_tasks
  from public.maintenance_tasks
  where archived_at is null;

  begin
    select count(*) into v_active_routines
    from public.routines
    where archived_at is null and is_paused = false;
  exception
    when others then v_active_routines := 0;
  end;

  select count(*) into v_open_notes
  from public.admin_codex_notes
  where applied_at is null and reverted_at is null;

  select count(*) into v_pending_proposals
  from public.admin_codex_notes
  where applied_at is null
    and reverted_at is null
    and intent in ('change_request', 'proposal_add', 'proposal_delete');

  select
    count(*) filter (where launch_status = 'approved'),
    count(*)
  into v_approved_items, v_total_items
  from public.admin_content_items;

  return jsonb_build_object(
    'quiz_starts', v_quiz_starts,
    'quiz_completes', v_quiz_completes,
    'quiz_completion_rate',
      case
        when v_quiz_starts > 0
        then round(v_quiz_completes::numeric / v_quiz_starts, 3)
        else null
      end,
    'active_properties', v_active_properties,
    'total_open_tasks', v_total_tasks,
    'active_routines', v_active_routines,
    'open_notes', v_open_notes,
    'pending_proposals', v_pending_proposals,
    'approved_items', v_approved_items,
    'total_items', v_total_items,
    'launch_readiness_pct',
      case
        when v_total_items > 0
        then round(v_approved_items::numeric / v_total_items, 3)
        else 0
      end
  );
end;
$$;

revoke all on function public.admin_lab_overview() from public, anon;
grant execute on function public.admin_lab_overview() to authenticated;
