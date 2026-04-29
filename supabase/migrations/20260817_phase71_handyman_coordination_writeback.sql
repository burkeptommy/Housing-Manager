-- Phase 71.2: Richer handyman coordination states + structured visit writeback.
--
-- 1. Expands `handyman_requests.status` so a single visit can move through
--    request -> sent -> alternate dates -> confirmed -> on my way -> checked in
--    -> completed / follow-up.
-- 2. Stores structured systems + recommendation snapshots on the visit report
--    so the field app can write through to the house profile while preserving
--    an auditable summary of what changed during the visit.

alter table public.handyman_requests
    drop constraint if exists handyman_requests_status_check;

alter table public.handyman_requests
    add constraint handyman_requests_status_check check (
        status in (
            'draft',
            'submitted',
            'scheduled',
            'sent_to_handyman',
            'alternate_dates_proposed',
            'awaiting_homeowner',
            'confirmed',
            'on_my_way',
            'checked_in',
            'quoted',
            'in_progress',
            'completed',
            'follow_up_recommended',
            'cancelled',
            'declined'
        )
    );

alter table public.handyman_visit_reports
    add column if not exists systems_snapshot jsonb not null default '[]'::jsonb,
    add column if not exists recommendations jsonb not null default '[]'::jsonb,
    add column if not exists coordination_status text;
