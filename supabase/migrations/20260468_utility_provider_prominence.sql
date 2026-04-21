-- Phase 50 (advisor picker fix): Add `prominence_rank` to `utility_providers`
-- so the Life tab advisor picker (estate attorneys, CPAs, financial advisors,
-- life insurance carriers) can surface the biggest national brands first
-- before falling back to proximity / alphabetical ordering.
--
-- Smaller rank = more prominent. NULL = no explicit ranking, lands in the
-- alphabetical bucket. The advisor picker reads these in three buckets of 10:
--   1. Top 10 by prominence_rank ascending (1..10)
--   2. Top 10 by region proximity to the user's primary property
--   3. Top 10 alphabetical
-- Total cap: 30 rows for advisor types. Utility types keep their existing
-- Phase 19h region-aware sort and 20-row cap.

ALTER TABLE public.utility_providers
    ADD COLUMN IF NOT EXISTS prominence_rank INTEGER;

COMMENT ON COLUMN public.utility_providers.prominence_rank IS
    'Phase 50 advisor picker: smaller = more prominent. The picker uses 1..10 to surface the biggest national brands first. NULL = no explicit ranking, falls into the alphabetical bucket.';

-- Partial index on (provider_type, prominence_rank) for the picker query.
CREATE INDEX IF NOT EXISTS idx_utility_providers_prominence
    ON public.utility_providers (provider_type, prominence_rank)
    WHERE prominence_rank IS NOT NULL;

-- ============================================================================
-- LIFE INSURANCE — top 10 by direct premium written / brand recognition
-- ============================================================================
-- Source: NAIC 2024 direct premium rankings + brand recognition for HNW
-- consumers. Order reflects sales volume / household name strength.

UPDATE public.utility_providers SET prominence_rank = 1
    WHERE slug = 'northwestern-mutual' AND provider_type = 'life_insurance';
UPDATE public.utility_providers SET prominence_rank = 2
    WHERE slug = 'new-york-life' AND provider_type = 'life_insurance';
UPDATE public.utility_providers SET prominence_rank = 3
    WHERE slug = 'metlife' AND provider_type = 'life_insurance';
UPDATE public.utility_providers SET prominence_rank = 4
    WHERE slug = 'prudential' AND provider_type = 'life_insurance';
UPDATE public.utility_providers SET prominence_rank = 5
    WHERE slug = 'massmutual' AND provider_type = 'life_insurance';
UPDATE public.utility_providers SET prominence_rank = 6
    WHERE slug = 'lincoln-financial' AND provider_type = 'life_insurance';
UPDATE public.utility_providers SET prominence_rank = 7
    WHERE slug = 'state-farm-life' AND provider_type = 'life_insurance';
UPDATE public.utility_providers SET prominence_rank = 8
    WHERE slug = 'pacific-life' AND provider_type = 'life_insurance';
UPDATE public.utility_providers SET prominence_rank = 9
    WHERE slug = 'aig' AND provider_type = 'life_insurance';
UPDATE public.utility_providers SET prominence_rank = 10
    WHERE slug = 'transamerica' AND provider_type = 'life_insurance';

-- ============================================================================
-- FINANCIAL ADVISORS — top 10 wirehouses / RIAs by AUM and brand reach
-- ============================================================================
-- Source: Cerulli Associates AUM rankings + advisor headcount.

UPDATE public.utility_providers SET prominence_rank = 1
    WHERE slug = 'morgan-stanley' AND provider_type = 'financial_advisor';
UPDATE public.utility_providers SET prominence_rank = 2
    WHERE slug = 'merrill-lynch' AND provider_type = 'financial_advisor';
UPDATE public.utility_providers SET prominence_rank = 3
    WHERE slug = 'ubs-financial-services' AND provider_type = 'financial_advisor';
UPDATE public.utility_providers SET prominence_rank = 4
    WHERE slug = 'wells-fargo-advisors' AND provider_type = 'financial_advisor';
UPDATE public.utility_providers SET prominence_rank = 5
    WHERE slug = 'edward-jones' AND provider_type = 'financial_advisor';
UPDATE public.utility_providers SET prominence_rank = 6
    WHERE slug = 'charles-schwab' AND provider_type = 'financial_advisor';
UPDATE public.utility_providers SET prominence_rank = 7
    WHERE slug = 'fidelity-investments' AND provider_type = 'financial_advisor';
UPDATE public.utility_providers SET prominence_rank = 8
    WHERE slug = 'vanguard' AND provider_type = 'financial_advisor';
UPDATE public.utility_providers SET prominence_rank = 9
    WHERE slug = 'raymond-james' AND provider_type = 'financial_advisor';
UPDATE public.utility_providers SET prominence_rank = 10
    WHERE slug = 'ameriprise-financial' AND provider_type = 'financial_advisor';

-- ============================================================================
-- CPA / TAX — top 10 accounting firms by US revenue (Big 4 + top mid-market)
-- ============================================================================
-- Source: Inside Public Accounting top-100 firms ranked by US revenue.

UPDATE public.utility_providers SET prominence_rank = 1
    WHERE slug = 'deloitte' AND provider_type = 'cpa_tax';
UPDATE public.utility_providers SET prominence_rank = 2
    WHERE slug = 'pwc' AND provider_type = 'cpa_tax';
UPDATE public.utility_providers SET prominence_rank = 3
    WHERE slug = 'ey' AND provider_type = 'cpa_tax';
UPDATE public.utility_providers SET prominence_rank = 4
    WHERE slug = 'kpmg' AND provider_type = 'cpa_tax';
UPDATE public.utility_providers SET prominence_rank = 5
    WHERE slug = 'rsm-us' AND provider_type = 'cpa_tax';
UPDATE public.utility_providers SET prominence_rank = 6
    WHERE slug = 'bdo-usa' AND provider_type = 'cpa_tax';
UPDATE public.utility_providers SET prominence_rank = 7
    WHERE slug = 'grant-thornton' AND provider_type = 'cpa_tax';
UPDATE public.utility_providers SET prominence_rank = 8
    WHERE slug = 'cla' AND provider_type = 'cpa_tax';
UPDATE public.utility_providers SET prominence_rank = 9
    WHERE slug = 'baker-tilly' AND provider_type = 'cpa_tax';
UPDATE public.utility_providers SET prominence_rank = 10
    WHERE slug = 'crowe' AND provider_type = 'cpa_tax';

-- ============================================================================
-- ESTATE ATTORNEYS — top 10 regional firms (no true national brands exist)
-- ============================================================================
-- Estate attorneys are the most hyper-local advisor type. The Phase 50 seed
-- comment explicitly notes "Unlike insurance or utilities, there are almost
-- no national firms — the vast majority are regional practices." So the
-- "biggest" tier here is the major regional law firms with established
-- estate / trust practices serving the NY/CT/MA HNW corridor — these are
-- the firms HNW Westchester families recognize from their wealth-management
-- circles. They ship with `regions = ['NY','CT','Westchester','Fairfield']`
-- in 20260451_seed_estate_attorney_providers.sql so they're already
-- catalog-tagged; the prominence_rank just promotes them above the long
-- tail of solo and small partnerships in the same picker.

UPDATE public.utility_providers SET prominence_rank = 1
    WHERE slug = 'day-pitney' AND provider_type = 'estate_attorney';
UPDATE public.utility_providers SET prominence_rank = 2
    WHERE slug = 'cummings-lockwood' AND provider_type = 'estate_attorney';
UPDATE public.utility_providers SET prominence_rank = 3
    WHERE slug = 'wiggin-dana' AND provider_type = 'estate_attorney';
UPDATE public.utility_providers SET prominence_rank = 4
    WHERE slug = 'shipman-goodwin' AND provider_type = 'estate_attorney';
UPDATE public.utility_providers SET prominence_rank = 5
    WHERE slug = 'robinson-cole' AND provider_type = 'estate_attorney';
UPDATE public.utility_providers SET prominence_rank = 6
    WHERE slug = 'pullman-comley' AND provider_type = 'estate_attorney';
UPDATE public.utility_providers SET prominence_rank = 7
    WHERE slug = 'murtha-cullina' AND provider_type = 'estate_attorney';
UPDATE public.utility_providers SET prominence_rank = 8
    WHERE slug = 'cuddy-feder' AND provider_type = 'estate_attorney';
UPDATE public.utility_providers SET prominence_rank = 9
    WHERE slug = 'cohen-wolf' AND provider_type = 'estate_attorney';
UPDATE public.utility_providers SET prominence_rank = 10
    WHERE slug = 'ivey-barnum-omara' AND provider_type = 'estate_attorney';
