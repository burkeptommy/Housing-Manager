-- Phase 72.5: vendor profile expansion.
--
-- Extends vendor_applications with the rich-listing fields that Phase 72
-- intentionally deferred so the public apply form could stay tight (7 fields
-- → high conversion). Vendors fill these in through the rebuilt
-- vendor-portal.html after they confirm their email; iOS find-local-vendors
-- starts surfacing them as the profile completes.
--
-- Three groups, all NULLABLE so the 13 existing live rows don't break:
--   1. Profile basics       (visible on the iOS card)
--   2. Trust + credentials  (drive Chez Certified verification)
--   3. Service area + ops   (refine matching + route leads)
--
-- A `profile_completion_pct` SQL function computes a 0-100 score so every
-- surface (vendor portal progress bar, iOS card-tier gate, admin sort) calls
-- the same definition. Server-side function, not a stored column — cheap to
-- recompute (~13 rows today, ≤1000 expected within 12 months) and avoids
-- trigger fan-out on every column update.

-- ===========================================================================
-- Group 1: profile basics (rich listing card)
-- ===========================================================================

alter table public.vendor_applications
    add column logo_url text check (logo_url is null or length(logo_url) <= 1000),
    add column brand_color text check (
        brand_color is null or brand_color ~ '^#[0-9A-Fa-f]{6}$'
    ),
    add column description text check (
        description is null or length(description) between 1 and 200
    ),
    add column about text check (about is null or length(about) <= 2000),
    add column years_in_business integer check (
        years_in_business is null or years_in_business between 0 and 200
    ),
    add column photo_urls text[] not null default '{}'::text[];

comment on column public.vendor_applications.description is
    'One-line tagline shown on the iOS find-vendor card. ≤200 chars.';
comment on column public.vendor_applications.about is
    'Long-form about copy shown when a homeowner taps into the vendor detail. ≤2000 chars.';
comment on column public.vendor_applications.photo_urls is
    'Supabase Storage URLs (vendor-assets bucket). Up to ~6 photos in v1; no DB cap, vendor portal enforces.';

-- ===========================================================================
-- Group 2: trust + credentials
-- ===========================================================================

alter table public.vendor_applications
    add column license_number text check (
        license_number is null or length(license_number) between 1 and 100
    ),
    add column license_state text check (
        license_state is null or license_state ~ '^[A-Z]{2}$'
    ),
    add column license_verified_at timestamptz,
    add column insurance_carrier text check (
        insurance_carrier is null or length(insurance_carrier) between 1 and 200
    ),
    add column insurance_policy_number text check (
        insurance_policy_number is null or length(insurance_policy_number) between 1 and 100
    ),
    add column insurance_expiry date,
    add column insurance_coverage_cents bigint check (
        insurance_coverage_cents is null or insurance_coverage_cents >= 0
    ),
    add column coi_document_url text check (
        coi_document_url is null or length(coi_document_url) <= 1000
    ),
    add column coi_verified_at timestamptz;

comment on column public.vendor_applications.license_verified_at is
    'Set by admin when they confirm the license number against the state license-search portal.';
comment on column public.vendor_applications.coi_verified_at is
    'Set by admin when they confirm the uploaded COI is real and current. Independent of insurance_expiry.';

-- ===========================================================================
-- Group 3: service area refinement + lead routing + ops
-- ===========================================================================

alter table public.vendor_applications
    add column service_area_towns text[] not null default '{}'::text[],
    add column service_radius_miles integer check (
        service_radius_miles is null or service_radius_miles between 1 and 500
    ),
    add column hours_json jsonb,
    add column emergency_available boolean not null default false,
    add column lead_email text check (
        lead_email is null
        or (
            length(lead_email) between 3 and 255
            and lead_email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'
        )
    ),
    add column lead_phone text check (
        lead_phone is null or length(lead_phone) between 7 and 30
    ),
    add column notify_on_lead boolean not null default true,
    add column accepted_terms_at timestamptz;

comment on column public.vendor_applications.service_area_towns is
    'Optional precise town list, e.g. {"Westport, CT","Greenwich, CT"}. service_area_states is the coarse fallback when this is empty.';
comment on column public.vendor_applications.hours_json is
    'Per-day hours, e.g. {"monday":{"open":"08:00","close":"17:00"}, "sunday":null}. Null = no public hours posted.';
comment on column public.vendor_applications.lead_email is
    'Where homeowner-quote-request emails get sent. Defaults to email at signup; vendor can route to a sales/dispatch address.';

-- ===========================================================================
-- Indexes for fast lookup
-- ===========================================================================

create index if not exists vendor_applications_service_area_towns
    on public.vendor_applications using gin (service_area_towns);

create index if not exists vendor_applications_insurance_expiry
    on public.vendor_applications (insurance_expiry)
    where insurance_expiry is not null;

-- ===========================================================================
-- profile_completion_pct(vendor_applications)
-- ===========================================================================
--
-- Single source of truth for "how complete is this profile" — used by:
--   • vendor portal: progress card / TODO list of missing fields
--   • iOS find-local-vendors: sort tiers (basic listing < 60 < rich listing)
--   • admin desk: sort + nudge low-completion vendors before certifying
--
-- Weighting (sum = 100):
--   - email_confirmed_at:    10  (the apply-form floor — required for live)
--   - description:           10
--   - about:                  8
--   - logo_url:              10
--   - photo_urls (≥1):       10
--   - years_in_business:      4
--   - license_number:         8
--   - insurance_policy_number: 8
--   - insurance_expiry (future date): 4
--   - coi_document_url:      10
--   - service_area_towns (≥1): 6
--   - hours_json:             4
--   - lead_email:             4 (defaults to apply-time email; counts when set)
--   - accepted_terms_at:      4
--
-- Adjust weights here when the field set evolves; do NOT inline copies of
-- this scoring elsewhere.

create or replace function public.profile_completion_pct(app public.vendor_applications)
returns integer
language sql
-- STABLE (not IMMUTABLE) because the insurance_expiry weight depends on
-- current_date — same row, same column values can score differently across
-- day boundaries when an insurance policy lapses.
stable
as $$
    select greatest(0, least(100,
        (case when app.email_confirmed_at is not null then 10 else 0 end)
      + (case when app.description is not null and length(trim(app.description)) > 0 then 10 else 0 end)
      + (case when app.about is not null and length(trim(app.about)) > 0 then 8 else 0 end)
      + (case when app.logo_url is not null and length(trim(app.logo_url)) > 0 then 10 else 0 end)
      + (case when array_length(app.photo_urls, 1) >= 1 then 10 else 0 end)
      + (case when app.years_in_business is not null then 4 else 0 end)
      + (case when app.license_number is not null and length(trim(app.license_number)) > 0 then 8 else 0 end)
      + (case when app.insurance_policy_number is not null and length(trim(app.insurance_policy_number)) > 0 then 8 else 0 end)
      + (case when app.insurance_expiry is not null and app.insurance_expiry > current_date then 4 else 0 end)
      + (case when app.coi_document_url is not null and length(trim(app.coi_document_url)) > 0 then 10 else 0 end)
      + (case when array_length(app.service_area_towns, 1) >= 1 then 6 else 0 end)
      + (case when app.hours_json is not null then 4 else 0 end)
      + (case when app.lead_email is not null and length(trim(app.lead_email)) > 0 then 4 else 0 end)
      + (case when app.accepted_terms_at is not null then 4 else 0 end)
    ));
$$;

comment on function public.profile_completion_pct(public.vendor_applications) is
    'Phase 72.5: 0-100 profile completion score. Drives vendor portal progress bar, iOS rich-listing tier gate, and admin sort. Adjust weights here, never inline.';

-- ===========================================================================
-- Default lead_email + lead_phone for existing rows
-- ===========================================================================
--
-- Existing 13 live rows pre-date the lead-routing fields. Default them to
-- the apply-form email/phone so notify_on_lead actually has a destination
-- the moment Phase 2 (lead capture) ships. New apply-form submissions will
-- get this from a default in submit-vendor-application instead.

update public.vendor_applications
set lead_email = email
where lead_email is null;

update public.vendor_applications
set lead_phone = phone
where lead_phone is null;

-- ===========================================================================
-- Storage bucket for vendor-uploaded assets (logos, photos, COIs)
-- ===========================================================================
--
-- Created idempotently. Public-read so iOS can render logos/photos directly
-- from the URL without signed-URL round trips. COIs go in the SAME bucket
-- but under a path prefix that's enforced via RLS to require auth (private).

insert into storage.buckets (id, name, public)
values ('vendor-assets', 'vendor-assets', true)
on conflict (id) do nothing;

-- Path conventions (enforced by edge function, documented here):
--   logos/<application_id>/<filename>     — public
--   photos/<application_id>/<filename>    — public
--   coi/<application_id>/<filename>       — private (only owner + admin can read)
--
-- v1 RLS: bucket-wide read (public). Writes restricted to the application
-- owner via a Storage policy that matches the path's <application_id> prefix
-- to a vendor_applications row whose email matches auth.email().

drop policy if exists "vendor_assets_owner_write" on storage.objects;
create policy "vendor_assets_owner_write"
on storage.objects
for insert
to authenticated
with check (
    bucket_id = 'vendor-assets'
    and exists (
        select 1
        from public.vendor_applications va
        where va.id::text = split_part(storage.objects.name, '/', 2)
          and lower(va.email) = lower(coalesce(auth.email(), ''))
    )
);

drop policy if exists "vendor_assets_owner_update" on storage.objects;
create policy "vendor_assets_owner_update"
on storage.objects
for update
to authenticated
using (
    bucket_id = 'vendor-assets'
    and exists (
        select 1
        from public.vendor_applications va
        where va.id::text = split_part(storage.objects.name, '/', 2)
          and lower(va.email) = lower(coalesce(auth.email(), ''))
    )
);

drop policy if exists "vendor_assets_owner_delete" on storage.objects;
create policy "vendor_assets_owner_delete"
on storage.objects
for delete
to authenticated
using (
    bucket_id = 'vendor-assets'
    and exists (
        select 1
        from public.vendor_applications va
        where va.id::text = split_part(storage.objects.name, '/', 2)
          and lower(va.email) = lower(coalesce(auth.email(), ''))
    )
);

-- COI privacy: anyone can read logos/* and photos/* (default public bucket
-- behavior), but coi/* is gated to the application owner and admin emails.
-- This is enforced via a SELECT policy that filters non-owner reads of
-- the coi/ path prefix.

drop policy if exists "vendor_assets_coi_read_gate" on storage.objects;
create policy "vendor_assets_coi_read_gate"
on storage.objects
for select
to public
using (
    bucket_id <> 'vendor-assets'
    or storage.objects.name not like 'coi/%'
    or (
        auth.role() = 'authenticated'
        and exists (
            select 1
            from public.vendor_applications va
            where va.id::text = split_part(storage.objects.name, '/', 2)
              and lower(va.email) = lower(coalesce(auth.email(), ''))
        )
    )
);
