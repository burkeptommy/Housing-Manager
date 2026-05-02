-- Phase 72: vendor application + Chez Certification pipeline.
--
-- Vendors apply via the public form on getchez.com → row created with
-- status='pending_email_confirm' → magic-link email → click flips to
-- 'live_unverified' (immediately visible in find-vendor results, no badge)
-- → admin call/review → 'chez_certified' (badge + top sort) OR 'rejected'.
--
-- Rejected apps can re-apply after 90 days (cooldown enforced in edge fn).
-- The phrase "Chez Certified" is reserved for status='chez_certified' only.

-- ===========================================================================
-- Main application table
-- ===========================================================================
create table public.vendor_applications (
    id uuid primary key default gen_random_uuid(),

    -- Submitted by vendor on the public form (basic 7 fields per Phase 71 scope)
    business_name text not null check (length(business_name) between 1 and 200),
    contact_name text not null check (length(contact_name) between 1 and 100),
    email text not null check (
        length(email) between 3 and 255
        and email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'
    ),
    phone text not null check (length(phone) between 7 and 30),
    website text check (website is null or length(website) <= 500),
    category text not null check (length(category) between 1 and 100),
    service_area_states text[] not null check (
        array_length(service_area_states, 1) between 1 and 50
    ),

    -- Lifecycle
    status text not null default 'pending_email_confirm'
        check (status in (
            'pending_email_confirm',
            'live_unverified',
            'chez_certified',
            'rejected'
        )),
    email_confirm_token uuid not null default gen_random_uuid(),
    email_confirmed_at timestamptz,
    email_confirm_sent_at timestamptz not null default now(),

    -- Verification metadata (set when admin marks chez_certified)
    verified_at timestamptz,
    verified_by uuid references auth.users(id) on delete set null,
    verified_notes text,

    -- Rejection metadata (set when admin marks rejected)
    rejected_at timestamptz,
    rejected_by uuid references auth.users(id) on delete set null,
    rejection_notes text,

    -- Dedup link to existing Google Places listing (set at confirm time)
    linked_google_place_id text,

    -- Audit
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    submission_ip inet
);

comment on table public.vendor_applications is
    'Phase 72: vendor self-signup applications. Sees three lifecycle states: '
    'pending_email_confirm (form submitted, awaiting magic-link click), '
    'live_unverified (visible in find-vendor results, no badge), '
    'chez_certified (badge + top sort), rejected.';

-- One active application per email; rejected ones unblock so vendor can re-apply
create unique index vendor_applications_email_active
    on public.vendor_applications (lower(email))
    where status != 'rejected';

create unique index vendor_applications_email_confirm_token
    on public.vendor_applications (email_confirm_token);

create index vendor_applications_status on public.vendor_applications (status);
create index vendor_applications_category on public.vendor_applications (category);
create index vendor_applications_service_area
    on public.vendor_applications using gin (service_area_states);
create index vendor_applications_phone_normalized
    on public.vendor_applications (regexp_replace(phone, '\D', '', 'g'));

-- ===========================================================================
-- Rate-limit table (per IP, per submit attempt)
-- ===========================================================================
create table public.vendor_application_attempts (
    id bigserial primary key,
    ip inet not null,
    attempted_at timestamptz not null default now()
);

create index vendor_application_attempts_ip_time
    on public.vendor_application_attempts (ip, attempted_at desc);

comment on table public.vendor_application_attempts is
    'Per-IP submission log for the vendor-application form. '
    'submit-vendor-application enforces 3 attempts per IP per hour.';

-- ===========================================================================
-- Updated-at trigger
-- ===========================================================================
create or replace function public.touch_vendor_applications_updated_at()
returns trigger as $$
begin
    new.updated_at := now();
    return new;
end;
$$ language plpgsql;

create trigger vendor_applications_updated_at
    before update on public.vendor_applications
    for each row execute function public.touch_vendor_applications_updated_at();

-- ===========================================================================
-- RLS: deny everything by default. Edge functions read/write via service role.
-- ===========================================================================
alter table public.vendor_applications enable row level security;
alter table public.vendor_application_attempts enable row level security;
