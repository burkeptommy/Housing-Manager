-- Phase 18e: Snapshot provider info on utility_accounts.
--
-- Before this migration, picking a provider in the quiz only stored the
-- provider name on the utility_account row. The link to the catalog row
-- (logo, brand color, slug) was lost on insert, so the Property → Overview
-- card showed Eversource with a generic plug icon instead of the brand logo.
--
-- Three new columns:
--   provider_id: nullable FK to utility_providers, ON DELETE SET NULL so
--                deleting a provider catalog row doesn't take the household
--                account row with it
--   logo_url:    snapshot of the provider's Brandfetch CDN URL at write time
--   brand_color: snapshot of the brand hex color
--
-- Snapshotting (vs JOIN at read time) is intentional: faster reads, resilient
-- to provider catalog edits, matches the existing slug-snapshot pattern.

ALTER TABLE public.utility_accounts
    ADD COLUMN IF NOT EXISTS provider_id UUID REFERENCES public.utility_providers(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS logo_url TEXT,
    ADD COLUMN IF NOT EXISTS brand_color TEXT;

CREATE INDEX IF NOT EXISTS idx_utility_accounts_provider
    ON public.utility_accounts (provider_id)
    WHERE provider_id IS NOT NULL;
