-- Phase 54E.4: Dedup top-level home_systems rows.
--
-- Why: Tom's "Assign Systems" picker was surfacing "Pet Waste Removal"
-- and "Snow Removal" twice within the same property. Multiple code
-- paths (quiz completion, AppState backfill, older universal seed)
-- could each create rows when their dedup keys mismatched by category
-- string casing or when migrations ran out of order.
--
-- Strategy: group top-level rows (parent_system_id IS NULL) per
-- property by LOWER(TRIM(name)) + LOWER(COALESCE(subtype, '')) — same
-- visible name to the user AND same subtype are considered duplicates.
-- Keeping subtype in the key preserves legitimate wood-vs-gas chimney
-- differentiation. For each duplicate group we pick the "best" row
-- (most metadata populated, oldest as tiebreak) as the canonical
-- keeper, fill any null fields on the keeper from the losers, rewire
-- every FK reference (maintenance_tasks, service_records, warranties,
-- standing_appointments, child home_systems.parent_system_id) from
-- the losers to the keeper, then DELETE the losers. Without the
-- FK rewire, `ON DELETE CASCADE` would silently drop the user's
-- maintenance tasks and service history.
--
-- Sub-system rows (parent_system_id IS NOT NULL) are intentionally
-- excluded — children like "Well Pump" / "UV Filter" legitimately
-- have distinct names and live under their parent. A separate pass
-- can tackle sub-system dedup if that shows up in user reports.

do $$
declare
    dup_record record;
    canonical_id uuid;
    loser_ids uuid[];
begin
    for dup_record in
        select property_id,
               lower(trim(name))                     as normalized_name,
               lower(coalesce(subtype, ''))          as normalized_subtype,
               array_agg(
                   id
                   order by
                       -- Score: prefer rows with more user-enriched metadata.
                       (case when preferred_contractor_id is not null then 4 else 0 end) +
                       (case when last_service_date       is not null then 2 else 0 end) +
                       (case when manufacturer            is not null then 1 else 0 end) +
                       (case when model_number           is not null then 1 else 0 end)
                           desc,
                       created_at asc,
                       id asc  -- stable ordering tiebreak
               )                                     as ids,
               count(*)                              as dup_count
        from public.home_systems
        where parent_system_id is null
        group by property_id, lower(trim(name)), lower(coalesce(subtype, ''))
        having count(*) > 1
    loop
        canonical_id := dup_record.ids[1];
        loser_ids    := dup_record.ids[2:array_length(dup_record.ids, 1)];

        -- Merge nulls on the keeper from the first loser that has a
        -- non-null value. Preserves data that'd otherwise vanish when
        -- the scoring picked a different winner for a different reason.
        update public.home_systems keeper
        set
            preferred_contractor_id = coalesce(keeper.preferred_contractor_id, sub.preferred_contractor_id),
            last_service_date       = coalesce(keeper.last_service_date,       sub.last_service_date),
            next_service_due   = coalesce(keeper.next_service_due,   sub.next_service_due),
            manufacturer            = coalesce(keeper.manufacturer,            sub.manufacturer),
            model_number            = coalesce(keeper.model_number,            sub.model_number),
            serial_number           = coalesce(keeper.serial_number,           sub.serial_number),
            install_date            = coalesce(keeper.install_date,            sub.install_date),
            notes                   = coalesce(keeper.notes,                   sub.notes),
            subtype                 = coalesce(keeper.subtype,                 sub.subtype)
        from (
            select
                (array_agg(preferred_contractor_id) filter (where preferred_contractor_id is not null))[1] as preferred_contractor_id,
                (array_agg(last_service_date)       filter (where last_service_date       is not null))[1] as last_service_date,
                (array_agg(next_service_due)   filter (where next_service_due   is not null))[1] as next_service_due,
                (array_agg(manufacturer)            filter (where manufacturer            is not null))[1] as manufacturer,
                (array_agg(model_number)            filter (where model_number           is not null))[1] as model_number,
                (array_agg(serial_number)           filter (where serial_number           is not null))[1] as serial_number,
                (array_agg(install_date)            filter (where install_date            is not null))[1] as install_date,
                (array_agg(notes)                   filter (where notes                   is not null))[1] as notes,
                (array_agg(subtype)                 filter (where subtype                 is not null))[1] as subtype
            from public.home_systems
            where id = any(loser_ids)
        ) sub
        where keeper.id = canonical_id;

        -- Rewire children — losers that were parents of sub-systems
        -- transfer their children to the canonical row.
        update public.home_systems
        set parent_system_id = canonical_id
        where parent_system_id = any(loser_ids);

        -- Rewire FKs that have ON DELETE CASCADE. Without these UPDATEs
        -- the cascade on DELETE would drop user-owned tasks + history.
        update public.maintenance_tasks
        set system_id = canonical_id
        where system_id = any(loser_ids);

        update public.service_records
        set system_id = canonical_id
        where system_id = any(loser_ids);

        update public.warranties
        set system_id = canonical_id
        where system_id = any(loser_ids);

        -- standing_appointments may not exist on every install yet.
        if exists (
            select 1 from information_schema.tables
            where table_schema = 'public' and table_name = 'standing_appointments'
        ) then
            execute format(
                'update public.standing_appointments set system_id = %L where system_id = any(%L)',
                canonical_id, loser_ids
            );
        end if;

        -- Delete the losers. FKs are all rewired so no cascade loss.
        delete from public.home_systems where id = any(loser_ids);

        raise notice '[home_systems dedup] property %, key "%/%": kept %, dropped % duplicate(s)',
            dup_record.property_id,
            dup_record.normalized_name,
            dup_record.normalized_subtype,
            canonical_id,
            dup_record.dup_count - 1;
    end loop;
end $$;
