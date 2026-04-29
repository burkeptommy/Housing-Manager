-- Phase 71.1: Every handyman field microsite should map to one canonical
-- scheduled visit. `visit_task_id` is the stable internal visit identity;
-- `portal_token` is the revocable access credential for that visit.
--
-- The app already keys portal lookups by visit_task_id, but until now the
-- database allowed multiple portal-session rows for the same visit. Clean up
-- any duplicates defensively, keep the freshest report, then enforce the
-- one-portal-per-visit invariant with a partial unique index.

do $$
declare
    dup_record record;
    canonical_session_id uuid;
    loser_session_ids uuid[];
    winning_report_id uuid;
begin
    for dup_record in
        select visit_task_id,
               array_agg(
                   id
                   order by
                       coalesce(last_opened_at, updated_at, created_at) desc,
                       created_at desc,
                       id asc
               ) as ids
        from public.handyman_portal_sessions
        where visit_task_id is not null
        group by visit_task_id
        having count(*) > 1
    loop
        canonical_session_id := dup_record.ids[1];
        loser_session_ids := dup_record.ids[2:array_length(dup_record.ids, 1)];

        select id
        into winning_report_id
        from public.handyman_visit_reports
        where portal_session_id = any(dup_record.ids)
        order by
            coalesce(last_synced_at, updated_at, created_at) desc,
            created_at desc,
            id asc
        limit 1;

        if winning_report_id is not null then
            delete from public.handyman_visit_reports
            where portal_session_id = any(dup_record.ids)
              and id <> winning_report_id;

            update public.handyman_visit_reports
            set portal_session_id = canonical_session_id,
                visit_task_id = coalesce(visit_task_id, dup_record.visit_task_id),
                updated_at = now()
            where id = winning_report_id;
        end if;

        update public.handyman_portal_sessions canonical
        set property_id = coalesce(canonical.property_id, merged.property_id),
            contractor_id = coalesce(canonical.contractor_id, merged.contractor_id),
            created_by_user_id = coalesce(canonical.created_by_user_id, merged.created_by_user_id),
            status = case
                when canonical.status = 'active' or merged.has_active then 'active'
                when canonical.status = 'completed' or merged.has_completed then 'completed'
                when canonical.status = 'expired' or merged.has_expired then 'expired'
                else canonical.status
            end,
            first_visit = canonical.first_visit or merged.first_visit,
            last_opened_at = greatest(canonical.last_opened_at, merged.last_opened_at),
            expires_at = greatest(canonical.expires_at, merged.expires_at),
            updated_at = now()
        from (
            select
                (array_agg(property_id) filter (where property_id is not null))[1] as property_id,
                (array_agg(contractor_id) filter (where contractor_id is not null))[1] as contractor_id,
                (array_agg(created_by_user_id) filter (where created_by_user_id is not null))[1] as created_by_user_id,
                bool_or(status = 'active') as has_active,
                bool_or(status = 'completed') as has_completed,
                bool_or(status = 'expired') as has_expired,
                bool_or(first_visit) as first_visit,
                max(last_opened_at) as last_opened_at,
                max(expires_at) as expires_at
            from public.handyman_portal_sessions
            where id = any(dup_record.ids)
        ) merged
        where canonical.id = canonical_session_id;

        delete from public.handyman_portal_sessions
        where id = any(loser_session_ids);

        raise notice '[handyman portal dedup] visit %: kept %, dropped % duplicate portal session(s)',
            dup_record.visit_task_id,
            canonical_session_id,
            coalesce(array_length(loser_session_ids, 1), 0);
    end loop;
end $$;

create unique index if not exists uniq_handyman_portal_sessions_visit
    on public.handyman_portal_sessions (visit_task_id)
    where visit_task_id is not null;
