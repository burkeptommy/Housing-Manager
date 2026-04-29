-- Phase 72 directory: open `provider_workspaces` to homeowner-side
-- discovery in the find-a-handyman flow.
--
-- The original Phase 72 schema (20260818_phase72_handyman_provider_workspace)
-- supports provider workflows but never exposes providers to homeowners.
-- Today they only see Google Places results. This migration adds the
-- columns a new `find-network-handymen` Edge Function needs to surface
-- providers who explicitly opt into the directory, and one supporting
-- index per filter.
--
-- RLS stays locked down (workspace members only). The Edge Function uses
-- service-role for the directory query so we can sanitize what gets
-- returned to homeowners (no internal notes, no license number, no
-- email).

BEGIN;

ALTER TABLE public.provider_workspaces
    ADD COLUMN IF NOT EXISTS service_state text,
    ADD COLUMN IF NOT EXISTS service_city text,
    ADD COLUMN IF NOT EXISTS service_zip_codes text[] NOT NULL DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS categories text[] NOT NULL DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS is_listed_in_directory boolean NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS display_blurb text,
    ADD COLUMN IF NOT EXISTS headshot_url text,
    ADD COLUMN IF NOT EXISTS aggregate_rating numeric(3,2),
    ADD COLUMN IF NOT EXISTS review_count integer NOT NULL DEFAULT 0;

-- Partial index on the directory filter so the homeowner-side lookup
-- stays fast as the provider count grows.
CREATE INDEX IF NOT EXISTS idx_provider_workspaces_directory
    ON public.provider_workspaces (service_state, is_listed_in_directory)
    WHERE is_listed_in_directory = true;

-- GIN index for category array containment queries
-- (`.contains("categories", ["handyman"])` from the Edge Function).
CREATE INDEX IF NOT EXISTS idx_provider_workspaces_categories
    ON public.provider_workspaces USING gin (categories)
    WHERE is_listed_in_directory = true;

-- Aggregate rating sanity bounds. Ratings are 0.00–5.00; review_count
-- can never go negative.
ALTER TABLE public.provider_workspaces
    DROP CONSTRAINT IF EXISTS provider_workspaces_rating_range;
ALTER TABLE public.provider_workspaces
    ADD CONSTRAINT provider_workspaces_rating_range
    CHECK (aggregate_rating IS NULL OR (aggregate_rating >= 0 AND aggregate_rating <= 5));

ALTER TABLE public.provider_workspaces
    DROP CONSTRAINT IF EXISTS provider_workspaces_review_count_nonnegative;
ALTER TABLE public.provider_workspaces
    ADD CONSTRAINT provider_workspaces_review_count_nonnegative
    CHECK (review_count >= 0);

COMMIT;
