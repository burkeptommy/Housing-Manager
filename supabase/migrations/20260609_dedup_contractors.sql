-- Phase 54E.4: Dedup contractors where the same company was created
-- more than once in a household. Common causes:
-- 1. User manually added a contractor, then the utility-to-contractor
--    mirror (Phase 54E.3) fired for the same provider and didn't
--    match because of casing / trim differences.
-- 2. Quiz + manual paths both captured the same vendor.
-- 3. Merged households brought overlapping contractor rows together.
--
-- Grouping key: (household_id, LOWER(TRIM(company_name))). Phone
-- number is intentionally NOT in the key — the same cleaning service
-- might have changed phone numbers between captures.
--
-- Scoring prefers rows with more metadata (logo, brand color,
-- category, website, phone, rating) and the oldest created_at as
-- tiebreak. FKs to maintenance_tasks.assigned_contractor_id,
-- service_records.contractor_id, household_cadences.contractor_id,
-- home_systems.preferred_contractor_id, service_contracts.vendor_id,
-- and project_contacts are all rewired before deletion so the dedup
-- doesn't orphan user-enriched links.

do $$
declare
    dup_record record;
    canonical_id uuid;
    loser_ids uuid[];
begin
    for dup_record in
        select household_id,
               lower(trim(company_name)) as normalized_name,
               array_agg(
                   id
                   order by
                       (case when logo_url      is not null then 4 else 0 end) +
                       (case when brand_color   is not null then 2 else 0 end) +
                       (case when category      is not null then 2 else 0 end) +
                       (case when website       is not null then 1 else 0 end) +
                       (case when rating        is not null then 1 else 0 end) +
                       (case when phone is not null and phone <> 'Not provided' then 1 else 0 end)
                           desc,
                       created_at asc nulls last,
                       id asc
               ) as ids
        from public.contractors
        group by household_id, lower(trim(company_name))
        having count(*) > 1
    loop
        canonical_id := dup_record.ids[1];
        loser_ids    := dup_record.ids[2:array_length(dup_record.ids, 1)];

        -- Merge data from losers when keeper has nulls.
        update public.contractors keeper
        set
            contact_name      = coalesce(keeper.contact_name,      sub.contact_name),
            email             = coalesce(keeper.email,             sub.email),
            specialties       = coalesce(keeper.specialties,       sub.specialties),
            address           = coalesce(keeper.address,           sub.address),
            license_number    = coalesce(keeper.license_number,    sub.license_number),
            rating            = coalesce(keeper.rating,            sub.rating),
            notes             = coalesce(keeper.notes,             sub.notes),
            category          = coalesce(keeper.category,          sub.category),
            utility_provider_id = coalesce(keeper.utility_provider_id, sub.utility_provider_id),
            logo_url          = coalesce(keeper.logo_url,          sub.logo_url),
            brand_color       = coalesce(keeper.brand_color,       sub.brand_color),
            website           = coalesce(keeper.website,           sub.website)
        from (
            select
                (array_agg(contact_name)        filter (where contact_name        is not null))[1] as contact_name,
                (array_agg(email)               filter (where email               is not null))[1] as email,
                (array_agg(specialties)         filter (where specialties         is not null))[1] as specialties,
                (array_agg(address)             filter (where address             is not null))[1] as address,
                (array_agg(license_number)      filter (where license_number      is not null))[1] as license_number,
                (array_agg(rating)              filter (where rating              is not null))[1] as rating,
                (array_agg(notes)               filter (where notes               is not null))[1] as notes,
                (array_agg(category)            filter (where category            is not null))[1] as category,
                (array_agg(utility_provider_id) filter (where utility_provider_id is not null))[1] as utility_provider_id,
                (array_agg(logo_url)            filter (where logo_url            is not null))[1] as logo_url,
                (array_agg(brand_color)         filter (where brand_color         is not null))[1] as brand_color,
                (array_agg(website)             filter (where website             is not null))[1] as website
            from public.contractors
            where id = any(loser_ids)
        ) sub
        where keeper.id = canonical_id;

        -- Rewire FKs across the known references.
        update public.maintenance_tasks
        set assigned_contractor_id = canonical_id
        where assigned_contractor_id = any(loser_ids);

        update public.home_systems
        set preferred_contractor_id = canonical_id
        where preferred_contractor_id = any(loser_ids);

        update public.service_records
        set contractor_id = canonical_id
        where contractor_id = any(loser_ids);

        -- Tables that may or may not exist on every install — guarded
        -- by information_schema lookups so this migration is safe to
        -- re-run on a partial environment.
        if exists (
            select 1 from information_schema.columns
            where table_schema = 'public'
              and table_name   = 'household_cadences'
              and column_name  = 'contractor_id'
        ) then
            execute format(
                'update public.household_cadences set contractor_id = %L where contractor_id = any(%L)',
                canonical_id, loser_ids
            );
        end if;

        if exists (
            select 1 from information_schema.columns
            where table_schema = 'public'
              and table_name   = 'service_contracts'
              and column_name  = 'vendor_id'
        ) then
            execute format(
                'update public.service_contracts set vendor_id = %L where vendor_id = any(%L)',
                canonical_id, loser_ids
            );
        end if;

        if exists (
            select 1 from information_schema.columns
            where table_schema = 'public'
              and table_name   = 'project_contacts'
              and column_name  = 'contractor_id'
        ) then
            execute format(
                'update public.project_contacts set contractor_id = %L where contractor_id = any(%L)',
                canonical_id, loser_ids
            );
        end if;

        if exists (
            select 1 from information_schema.columns
            where table_schema = 'public'
              and table_name   = 'standing_appointments'
              and column_name  = 'vendor_id'
        ) then
            execute format(
                'update public.standing_appointments set vendor_id = %L where vendor_id = any(%L)',
                canonical_id, loser_ids
            );
        end if;

        delete from public.contractors where id = any(loser_ids);

        raise notice '[contractors dedup] household %, name "%": kept %, dropped % duplicate(s)',
            dup_record.household_id,
            dup_record.normalized_name,
            canonical_id,
            array_length(loser_ids, 1);
    end loop;
end $$;

-- Defensive unique index for future writes. Same pattern as
-- 20260606 / 20260608.
create unique index if not exists uniq_contractors_household_name
    on public.contractors (household_id, lower(trim(company_name)));
