-- Phase 54E.4: Second pass on maintenance_tasks dedup.
--
-- The Phase 54E.4 home_systems dedup (20260605) rewired
-- maintenance_tasks.system_id from losing duplicate systems to the
-- canonical keeper. If both the loser and the keeper had matching
-- tasks (e.g. both had "Weekly yard cleanup" pointing at Pet Waste
-- Removal), the rewire produced duplicate tasks on the same system.
-- This migration collapses those, preferring the row with the most
-- completion history.
--
-- Two passes:
--
-- 1. Template-keyed dedup — template_id is a stable
--    `"category:title"` identifier the reconciler uses. If two rows
--    share (property_id, template_id), one of them is a true
--    duplicate regardless of display title drift.
--
-- 2. Title-keyed dedup — (property_id, system_id, LOWER(title)).
--    Catches non-template tasks (custom user adds) and tasks whose
--    template_id is null but titles match after the 54A prefix
--    stripping.
--
-- "Best" row scoring: recent completion > prior completion > user
-- assignment > oldest created_at. Tiebreak by id for determinism.

-- Pass 1: template_id dedup per property.
do $$
declare
    dup_record record;
    canonical_id uuid;
    loser_ids uuid[];
begin
    for dup_record in
        select property_id,
               template_id,
               array_agg(
                   id
                   order by
                       (case when last_completed_date is not null then 8 else 0 end) +
                       (case when assigned_contractor_id is not null then 4 else 0 end) +
                       (case when scheduled_date is not null then 2 else 0 end)
                           desc,
                       created_at asc,
                       id asc
               ) as ids
        from public.maintenance_tasks
        where template_id is not null
          and property_id is not null
        group by property_id, template_id
        having count(*) > 1
    loop
        canonical_id := dup_record.ids[1];
        loser_ids    := dup_record.ids[2:array_length(dup_record.ids, 1)];

        -- Merge any loser's completion data that the keeper lacks.
        update public.maintenance_tasks keeper
        set
            last_completed_date = coalesce(keeper.last_completed_date, sub.last_completed_date),
            assigned_contractor_id = coalesce(keeper.assigned_contractor_id, sub.assigned_contractor_id),
            scheduled_date = coalesce(keeper.scheduled_date, sub.scheduled_date)
        from (
            select
                (array_agg(last_completed_date) filter (where last_completed_date is not null))[1] as last_completed_date,
                (array_agg(assigned_contractor_id) filter (where assigned_contractor_id is not null))[1] as assigned_contractor_id,
                (array_agg(scheduled_date) filter (where scheduled_date is not null))[1] as scheduled_date
            from public.maintenance_tasks
            where id = any(loser_ids)
        ) sub
        where keeper.id = canonical_id;

        delete from public.maintenance_tasks where id = any(loser_ids);

        raise notice '[maintenance_tasks dedup template] property %, template "%": kept %, dropped % duplicate(s)',
            dup_record.property_id,
            dup_record.template_id,
            canonical_id,
            array_length(loser_ids, 1);
    end loop;
end $$;

-- Pass 2: (property_id, system_id, lowercased title) dedup for rows
-- that didn't match on template_id.
do $$
declare
    dup_record record;
    canonical_id uuid;
    loser_ids uuid[];
begin
    for dup_record in
        select property_id,
               system_id,
               lower(trim(title)) as normalized_title,
               array_agg(
                   id
                   order by
                       (case when last_completed_date is not null then 8 else 0 end) +
                       (case when assigned_contractor_id is not null then 4 else 0 end) +
                       (case when scheduled_date is not null then 2 else 0 end)
                           desc,
                       created_at asc,
                       id asc
               ) as ids
        from public.maintenance_tasks
        where property_id is not null
          and system_id is not null
        group by property_id, system_id, lower(trim(title))
        having count(*) > 1
    loop
        canonical_id := dup_record.ids[1];
        loser_ids    := dup_record.ids[2:array_length(dup_record.ids, 1)];

        update public.maintenance_tasks keeper
        set
            last_completed_date = coalesce(keeper.last_completed_date, sub.last_completed_date),
            assigned_contractor_id = coalesce(keeper.assigned_contractor_id, sub.assigned_contractor_id),
            scheduled_date = coalesce(keeper.scheduled_date, sub.scheduled_date),
            template_id = coalesce(keeper.template_id, sub.template_id)
        from (
            select
                (array_agg(last_completed_date) filter (where last_completed_date is not null))[1] as last_completed_date,
                (array_agg(assigned_contractor_id) filter (where assigned_contractor_id is not null))[1] as assigned_contractor_id,
                (array_agg(scheduled_date) filter (where scheduled_date is not null))[1] as scheduled_date,
                (array_agg(template_id) filter (where template_id is not null))[1] as template_id
            from public.maintenance_tasks
            where id = any(loser_ids)
        ) sub
        where keeper.id = canonical_id;

        delete from public.maintenance_tasks where id = any(loser_ids);

        raise notice '[maintenance_tasks dedup title] property %, system %, title "%": kept %, dropped % duplicate(s)',
            dup_record.property_id,
            dup_record.system_id,
            dup_record.normalized_title,
            canonical_id,
            array_length(loser_ids, 1);
    end loop;
end $$;
