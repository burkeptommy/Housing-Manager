-- Phase X feedback: purge fabricated vendor seed data.
--
-- BACKGROUND
-- A May 2026 audit (after Tom flagged "Redding Sanitation" missing from
-- find-a-pro) discovered that ~12,500 of the 15,310 rows in
-- `utility_providers` were templated synthetic data, almost certainly
-- LLM-generated. The pattern was unmistakable on the MA service trades:
-- three generic rows per Massachusetts town with slugs like
-- `ma-hvac-abington-ac-heat`, `ma-hvac-abington-climate`,
-- `ma-hvac-abington-heating-cooling`, and identical structure across
-- ~700 categories × towns. All rows had `website IS NULL` AND
-- `phone IS NULL`. Independent web searches for sample row names
-- (e.g. "Morgan & Kimball Darien CT", "Paul Geraci Sleepy Hollow NY")
-- returned no matches — confirming these are LLM hallucinations.
--
-- BREAKDOWN by category group (pre-purge):
--   utility_account (electric, water, trash, gas, oil, internet):
--     1,036 rows, only 0.7% missing contact info → REAL, untouched
--   insurance (home, auto, life): 663 rows, 0% missing → REAL, untouched
--   advisor (attorney, CPA, financial): 2,374 rows, 84% fabricated
--   service_trade (HVAC, plumbing, etc.): 11,237 rows, 94% fabricated
--
-- PURGE CRITERIA
-- A row is treated as fabricated when ALL hold:
--   1. provider_type is a fabrication-heavy category (service trades or
--      advisors — utility accounts + insurance were untouched in the
--      original seed)
--   2. website IS NULL OR website = ''
--   3. phone IS NULL OR phone = ''
--   4. No utility_accounts row references this provider (FK-safe)
--   5. No contractors row references this provider (FK-safe)
--
-- PRESERVED EXCEPTIONS
--   - "Private Well Service" placeholders (Sherman, New Fairfield, Redding,
--     Weston, etc.) and "Private Well System" generic — intentional
--     non-vendor placeholders for homes off municipal water.
--   - "Other Municipal Water" generic — same role.
--   - Blue Fox Landscaping, Mitchel — real-but-bare rows that real
--     household utility_accounts / contractors point to. Will be enriched
--     with contact info later.
--
-- IDEMPOTENT — the DELETE matches no rows on a fresh DB that hasn't been
-- seeded with the fabrications. The original seed migrations
-- (20260427_seed_extended_provider_database.sql,
--  20260431_seed_massive_utility_expansion.sql,
--  20260456_seed_ma_utilities_essex.sql and the 20260456+ MA series)
-- are kept as historical record but their templated INSERTs are
-- neutralized by this purge running afterward.

-- Pass 1: definitively fabricated MA-templated rows (~10,393 deleted live)
DELETE FROM utility_providers
WHERE slug LIKE 'ma-%'
  AND (website IS NULL OR website = '')
  AND (phone IS NULL OR phone = '')
  AND NOT EXISTS (SELECT 1 FROM utility_accounts ua WHERE ua.provider_id = utility_providers.id)
  AND NOT EXISTS (SELECT 1 FROM contractors c WHERE c.utility_provider_id = utility_providers.id);

-- Pass 2: remaining templated advisor + landscaping rows that don't match
-- the MA slug prefix but follow LLM-generated naming patterns. All caught
-- by the same "no website AND no phone" signal; categories scoped to the
-- two big fabricated populations (advisor + landscaping). Service-trade
-- non-MA rows are already cleaned by Pass 1's slug filter where applicable;
-- any remaining service-trade no-contact rows are caught by Pass 3 below.
DELETE FROM utility_providers
WHERE provider_type IN ('estate_attorney', 'cpa_tax', 'financial_advisor', 'landscaping')
  AND (website IS NULL OR website = '')
  AND (phone IS NULL OR phone = '')
  AND NOT EXISTS (SELECT 1 FROM utility_accounts ua WHERE ua.provider_id = utility_providers.id)
  AND NOT EXISTS (SELECT 1 FROM contractors c WHERE c.utility_provider_id = utility_providers.id);

-- Pass 3: catch-all for any other service-trade rows missing both website
-- and phone, scoped to fabrication-prone categories. Spares utility-account
-- categories (electric, water, trash, etc.) and insurance, both of which
-- were carefully seeded with real entities.
DELETE FROM utility_providers
WHERE provider_type IN (
    'hvac', 'plumbing', 'electrical', 'roofing', 'chimney_sweep',
    'tree_service', 'garage_door', 'septic_pumper', 'well_water_service',
    'pest_control', 'pool_service', 'solar', 'security', 'irrigation'
  )
  AND (website IS NULL OR website = '')
  AND (phone IS NULL OR phone = '')
  AND NOT EXISTS (SELECT 1 FROM utility_accounts ua WHERE ua.provider_id = utility_providers.id)
  AND NOT EXISTS (SELECT 1 FROM contractors c WHERE c.utility_provider_id = utility_providers.id);
