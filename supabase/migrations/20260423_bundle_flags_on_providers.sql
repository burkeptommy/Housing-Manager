-- Phase 16c: Bundled-insurance hint columns on utility_providers.
-- Indicates whether a carrier ALSO sells the partner line of business so the
-- House Quiz can pre-fill the home picker after the user picks an auto carrier
-- (and vice versa). Both columns default to FALSE — only the rows we backfill
-- below get a TRUE value.

ALTER TABLE public.utility_providers
    ADD COLUMN IF NOT EXISTS bundles_with_auto BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS bundles_with_home BOOLEAN NOT NULL DEFAULT FALSE;

-- ── Auto carriers that also offer home (bundles_with_home = TRUE) ──
UPDATE public.utility_providers SET bundles_with_home = TRUE
WHERE provider_type = 'auto_insurance' AND slug IN (
    'state-farm-auto',
    'geico-auto',
    'progressive-auto',
    'allstate-auto',
    'usaa-auto',
    'liberty-mutual-auto',
    'farmers-auto',
    'nationwide-auto',
    'american-family-auto',
    'travelers-auto',
    'erie-insurance-auto',
    'auto-owners-auto',
    'the-hartford-auto',
    'metlife-auto',
    'mercury-insurance-auto',
    'national-general-auto',
    'amica-auto',
    'chubb-auto',
    'aig-auto',
    'the-hanover-auto',
    'mapfre-auto',
    'safeco-auto',
    'aaa-auto-club-auto',
    'plymouth-rock-auto',
    'csaa-insurance-auto',
    'lemonade-auto',
    'acuity-insurance-auto',
    'pekin-insurance-auto',
    'shelter-insurance-auto',
    'western-national-auto',
    'cincinnati-insurance-auto',
    'westfield-insurance-auto',
    'country-financial-auto',
    'grange-insurance-auto',
    'sentry-insurance-auto',
    'zurich-north-america-auto',
    'njm-insurance-auto'
);

-- ── Home carriers that also offer auto (bundles_with_auto = TRUE) ──
UPDATE public.utility_providers SET bundles_with_auto = TRUE
WHERE provider_type = 'home_insurance' AND slug IN (
    'state-farm-home',
    'allstate-home',
    'usaa-home',
    'farmers-home',
    'liberty-mutual-home',
    'nationwide-home',
    'travelers-home',
    'american-family-home',
    'chubb-home',
    'progressive-home',
    'erie-insurance-home',
    'auto-owners-home',
    'the-hartford-home',
    'metlife-home',
    'amica-home',
    'safeco-home',
    'mapfre-home',
    'mercury-insurance-home',
    'lemonade-home',
    'country-financial-home',
    'cincinnati-insurance-home',
    'the-hanover-home',
    'westfield-insurance-home',
    'plymouth-rock-home',
    'njm-insurance-home',
    'grange-insurance-home',
    'pekin-insurance-home'
);
