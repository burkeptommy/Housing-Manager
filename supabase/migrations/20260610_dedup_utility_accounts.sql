-- Phase 54E.4: Dedup utility_accounts rows.
--
-- Same provider added twice for the same property (e.g. user tapped
-- through AddUtilitySheet twice, or the custom-add flow created one
-- row and a later catalog-resolved flow created another). Grouping
-- key is (property_id, provider_type, LOWER(TRIM(provider_name))) —
-- provider_type is part of the key so a hauler that handles both
-- trash AND recycling stays as two rows even if the provider name is
-- identical. That matches Tom's real-world pattern where Redding
-- Sanitation shows up under both trash and recycling.
--
-- Keeper scoring prefers rows with the richest metadata (provider_id
-- from the catalog, logo, account number, phone, website, monthly
-- cost, plan name). Oldest created_at as tiebreak.

do $$
declare
    dup_record record;
    canonical_id uuid;
    loser_ids uuid[];
begin
    for dup_record in
        select property_id,
               provider_type,
               lower(trim(provider_name)) as normalized_name,
               array_agg(
                   id
                   order by
                       (case when provider_id    is not null then 4 else 0 end) +
                       (case when logo_url       is not null then 2 else 0 end) +
                       (case when account_number is not null then 2 else 0 end) +
                       (case when phone          is not null then 1 else 0 end) +
                       (case when website        is not null then 1 else 0 end) +
                       (case when monthly_cost   is not null then 1 else 0 end) +
                       (case when plan_name      is not null then 1 else 0 end)
                           desc,
                       created_at asc nulls last,
                       id asc
               ) as ids
        from public.utility_accounts
        group by property_id, provider_type, lower(trim(provider_name))
        having count(*) > 1
    loop
        canonical_id := dup_record.ids[1];
        loser_ids    := dup_record.ids[2:array_length(dup_record.ids, 1)];

        update public.utility_accounts keeper
        set
            provider_id    = coalesce(keeper.provider_id,    sub.provider_id),
            provider_slug  = coalesce(keeper.provider_slug,  sub.provider_slug),
            account_number = coalesce(keeper.account_number, sub.account_number),
            phone          = coalesce(keeper.phone,          sub.phone),
            website        = coalesce(keeper.website,        sub.website),
            monthly_cost   = coalesce(keeper.monthly_cost,   sub.monthly_cost),
            plan_name      = coalesce(keeper.plan_name,      sub.plan_name),
            notes          = coalesce(keeper.notes,          sub.notes),
            logo_url       = coalesce(keeper.logo_url,       sub.logo_url),
            brand_color    = coalesce(keeper.brand_color,    sub.brand_color)
        from (
            select
                (array_agg(provider_id)    filter (where provider_id    is not null))[1] as provider_id,
                (array_agg(provider_slug)  filter (where provider_slug  is not null))[1] as provider_slug,
                (array_agg(account_number) filter (where account_number is not null))[1] as account_number,
                (array_agg(phone)          filter (where phone          is not null))[1] as phone,
                (array_agg(website)        filter (where website        is not null))[1] as website,
                (array_agg(monthly_cost)   filter (where monthly_cost   is not null))[1] as monthly_cost,
                (array_agg(plan_name)      filter (where plan_name      is not null))[1] as plan_name,
                (array_agg(notes)          filter (where notes          is not null))[1] as notes,
                (array_agg(logo_url)       filter (where logo_url       is not null))[1] as logo_url,
                (array_agg(brand_color)    filter (where brand_color    is not null))[1] as brand_color
            from public.utility_accounts
            where id = any(loser_ids)
        ) sub
        where keeper.id = canonical_id;

        delete from public.utility_accounts where id = any(loser_ids);

        raise notice '[utility_accounts dedup] property %, type %, name "%": kept %, dropped % duplicate(s)',
            dup_record.property_id,
            dup_record.provider_type,
            dup_record.normalized_name,
            canonical_id,
            array_length(loser_ids, 1);
    end loop;
end $$;

-- Defensive unique index keyed on (property_id, provider_type,
-- normalized name). Matches the grouping key used by the dedup pass.
create unique index if not exists uniq_utility_accounts_property_type_name
    on public.utility_accounts (property_id, provider_type, lower(trim(provider_name)));
