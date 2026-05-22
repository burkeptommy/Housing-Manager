-- Phase X feedback: consolidate national brand shards in utility_providers.
--
-- BACKGROUND
-- The seed had multiple rows per single brand split by region — pattern Tom
-- called out with "ADT, ADT Fairfield, ADT Westchester" where one ADT row
-- with comprehensive regions is the right model. Same pattern existed for
-- Optimum, SavATree, Verizon Fios, Con Edison boroughs, and Aquarion town
-- shards. All shards point to the same root_domain in `website`, so they
-- are unambiguously the same brand.
--
-- LEFT INTACT (legitimately distinct operating companies):
--   - FirstEnergy subsidiaries (Ohio Edison, Mon Power, Penn Power, etc.):
--     separate rate-regulated utilities, distinct legal entities.
--   - Duke Energy state subsidiaries (Carolinas, Florida, Indiana, etc.).
--   - AAA clubs (Northeast, Mid-Atlantic, Northern California, etc.).
--   - National Grid (Long Island, Massachusetts, RI, NY Upstate) —
--     distinct rate-regulated subsidiaries.
--   - Chubb / Federal Insurance Co / Great Northern Insurance — distinct
--     legal entities under the Chubb umbrella with different policy
--     products and underwriters.
--   - PURE Insurance / Privilege Underwriters — same brand but distinct
--     product lines kept separate intentionally.
--   - Aquarion Massachusetts (`aquarion-ma`) and Aquarion New Hampshire
--     (`aquarion-nh`) — separate state-level operating entities under
--     different state PUC regulation. Kept distinct from `aquarion-ct`.
--
-- IDEMPOTENT: the DELETEs use slug filters, so re-running on a fresh DB
-- (where the shards may not exist) is a no-op.

-- Helper: each block follows the same pattern:
--   1. UPDATE utility_accounts.provider_id → canonical
--   2. UPDATE contractors.utility_provider_id → canonical
--   3. UPDATE canonical.regions = union of all shard regions
--   4. DELETE shards

-- ===== ADT (security) — fold fairfield + westchester into national =====
UPDATE utility_accounts SET provider_id = (SELECT id FROM utility_providers WHERE slug = 'adt')
  WHERE provider_id IN (SELECT id FROM utility_providers WHERE slug IN ('adt-fairfield','adt-westchester'));
UPDATE contractors SET utility_provider_id = (SELECT id FROM utility_providers WHERE slug = 'adt')
  WHERE utility_provider_id IN (SELECT id FROM utility_providers WHERE slug IN ('adt-fairfield','adt-westchester'));
UPDATE utility_providers SET regions = (
  SELECT ARRAY(SELECT DISTINCT r FROM unnest(
    coalesce((SELECT regions FROM utility_providers WHERE slug = 'adt'), '{}'::text[])
    || coalesce((SELECT regions FROM utility_providers WHERE slug = 'adt-fairfield'), '{}'::text[])
    || coalesce((SELECT regions FROM utility_providers WHERE slug = 'adt-westchester'), '{}'::text[])
  ) r)
) WHERE slug = 'adt';
DELETE FROM utility_providers WHERE slug IN ('adt-fairfield','adt-westchester');

-- ===== Optimum (internet_cable) =====
UPDATE utility_accounts SET provider_id = (SELECT id FROM utility_providers WHERE slug = 'optimum')
  WHERE provider_id IN (SELECT id FROM utility_providers WHERE slug IN ('optimum-altice','optimum-fairfield','optimum-westchester'));
UPDATE contractors SET utility_provider_id = (SELECT id FROM utility_providers WHERE slug = 'optimum')
  WHERE utility_provider_id IN (SELECT id FROM utility_providers WHERE slug IN ('optimum-altice','optimum-fairfield','optimum-westchester'));
UPDATE utility_providers SET regions = (
  SELECT ARRAY(SELECT DISTINCT r FROM unnest(
    coalesce((SELECT regions FROM utility_providers WHERE slug = 'optimum'), '{}'::text[])
    || coalesce((SELECT regions FROM utility_providers WHERE slug = 'optimum-altice'), '{}'::text[])
    || coalesce((SELECT regions FROM utility_providers WHERE slug = 'optimum-fairfield'), '{}'::text[])
    || coalesce((SELECT regions FROM utility_providers WHERE slug = 'optimum-westchester'), '{}'::text[])
  ) r)
) WHERE slug = 'optimum';
DELETE FROM utility_providers WHERE slug IN ('optimum-altice','optimum-fairfield','optimum-westchester');

-- ===== SavATree (landscaping) =====
UPDATE utility_accounts SET provider_id = (SELECT id FROM utility_providers WHERE slug = 'savatree')
  WHERE provider_id IN (SELECT id FROM utility_providers WHERE slug IN ('savatree-ne','savatree-ma','savatree-westchester','savatree-mount-kisco'));
UPDATE contractors SET utility_provider_id = (SELECT id FROM utility_providers WHERE slug = 'savatree')
  WHERE utility_provider_id IN (SELECT id FROM utility_providers WHERE slug IN ('savatree-ne','savatree-ma','savatree-westchester','savatree-mount-kisco'));
UPDATE utility_providers SET regions = (
  SELECT ARRAY(SELECT DISTINCT r FROM unnest(
    coalesce((SELECT regions FROM utility_providers WHERE slug = 'savatree'), '{}'::text[])
    || coalesce((SELECT regions FROM utility_providers WHERE slug = 'savatree-ne'), '{}'::text[])
    || coalesce((SELECT regions FROM utility_providers WHERE slug = 'savatree-ma'), '{}'::text[])
    || coalesce((SELECT regions FROM utility_providers WHERE slug = 'savatree-westchester'), '{}'::text[])
    || coalesce((SELECT regions FROM utility_providers WHERE slug = 'savatree-mount-kisco'), '{}'::text[])
  ) r)
) WHERE slug = 'savatree';
DELETE FROM utility_providers WHERE slug IN ('savatree-ne','savatree-ma','savatree-westchester','savatree-mount-kisco');

-- ===== Verizon Fios (internet_cable) — keep 5G Home Internet separate =====
UPDATE utility_accounts SET provider_id = (SELECT id FROM utility_providers WHERE slug = 'verizon-fios')
  WHERE provider_id IN (SELECT id FROM utility_providers WHERE slug IN ('verizon-fios-fairfield','verizon-fios-ne','verizon-fios-westchester'));
UPDATE contractors SET utility_provider_id = (SELECT id FROM utility_providers WHERE slug = 'verizon-fios')
  WHERE utility_provider_id IN (SELECT id FROM utility_providers WHERE slug IN ('verizon-fios-fairfield','verizon-fios-ne','verizon-fios-westchester'));
UPDATE utility_providers SET regions = (
  SELECT ARRAY(SELECT DISTINCT r FROM unnest(
    coalesce((SELECT regions FROM utility_providers WHERE slug = 'verizon-fios'), '{}'::text[])
    || coalesce((SELECT regions FROM utility_providers WHERE slug = 'verizon-fios-fairfield'), '{}'::text[])
    || coalesce((SELECT regions FROM utility_providers WHERE slug = 'verizon-fios-ne'), '{}'::text[])
    || coalesce((SELECT regions FROM utility_providers WHERE slug = 'verizon-fios-westchester'), '{}'::text[])
  ) r)
) WHERE slug = 'verizon-fios';
DELETE FROM utility_providers WHERE slug IN ('verizon-fios-fairfield','verizon-fios-ne','verizon-fios-westchester');

-- ===== Con Edison electric (borough shards) =====
UPDATE utility_accounts SET provider_id = (SELECT id FROM utility_providers WHERE slug = 'conedison' AND provider_type = 'electric')
  WHERE provider_id IN (SELECT id FROM utility_providers WHERE slug IN ('coned-bronx','coned-manhattan','coned-westchester') AND provider_type = 'electric');
UPDATE contractors SET utility_provider_id = (SELECT id FROM utility_providers WHERE slug = 'conedison' AND provider_type = 'electric')
  WHERE utility_provider_id IN (SELECT id FROM utility_providers WHERE slug IN ('coned-bronx','coned-manhattan','coned-westchester') AND provider_type = 'electric');
UPDATE utility_providers SET regions = (
  SELECT ARRAY(SELECT DISTINCT r FROM unnest(
    coalesce((SELECT regions FROM utility_providers WHERE slug = 'conedison' AND provider_type = 'electric'), '{}'::text[])
    || coalesce((SELECT regions FROM utility_providers WHERE slug = 'coned-bronx' AND provider_type = 'electric'), '{}'::text[])
    || coalesce((SELECT regions FROM utility_providers WHERE slug = 'coned-manhattan' AND provider_type = 'electric'), '{}'::text[])
    || coalesce((SELECT regions FROM utility_providers WHERE slug = 'coned-westchester' AND provider_type = 'electric'), '{}'::text[])
  ) r)
) WHERE slug = 'conedison' AND provider_type = 'electric';
DELETE FROM utility_providers WHERE slug IN ('coned-bronx','coned-manhattan','coned-westchester') AND provider_type = 'electric';

-- ===== Aquarion (water) — town shards fold into aquarion-ct =====
-- aquarion-ma and aquarion-nh kept separate (state-level operating entities)
UPDATE utility_accounts SET provider_id = (SELECT id FROM utility_providers WHERE slug = 'aquarion-ct')
  WHERE provider_id IN (SELECT id FROM utility_providers WHERE slug IN (
    'aquarion-bethel','aquarion-bridgeport','aquarion-brookfield','aquarion-darien',
    'aquarion-easton','aquarion-fairfield-town','aquarion-greenwich','aquarion-monroe',
    'aquarion-new-canaan','aquarion-newtown','aquarion-ridgefield','aquarion-shelton',
    'aquarion-stamford','aquarion-stratford','aquarion-trumbull','aquarion-westport','aquarion-wilton'
  ));
UPDATE contractors SET utility_provider_id = (SELECT id FROM utility_providers WHERE slug = 'aquarion-ct')
  WHERE utility_provider_id IN (SELECT id FROM utility_providers WHERE slug IN (
    'aquarion-bethel','aquarion-bridgeport','aquarion-brookfield','aquarion-darien',
    'aquarion-easton','aquarion-fairfield-town','aquarion-greenwich','aquarion-monroe',
    'aquarion-new-canaan','aquarion-newtown','aquarion-ridgefield','aquarion-shelton',
    'aquarion-stamford','aquarion-stratford','aquarion-trumbull','aquarion-westport','aquarion-wilton'
  ));
UPDATE utility_providers SET regions = (
  SELECT ARRAY(SELECT DISTINCT r FROM unnest(
    coalesce((SELECT regions FROM utility_providers WHERE slug = 'aquarion-ct'), '{}'::text[])
    || coalesce((SELECT regions FROM utility_providers WHERE slug = 'aquarion-bethel'), '{}'::text[])
    || coalesce((SELECT regions FROM utility_providers WHERE slug = 'aquarion-bridgeport'), '{}'::text[])
    || coalesce((SELECT regions FROM utility_providers WHERE slug = 'aquarion-brookfield'), '{}'::text[])
    || coalesce((SELECT regions FROM utility_providers WHERE slug = 'aquarion-darien'), '{}'::text[])
    || coalesce((SELECT regions FROM utility_providers WHERE slug = 'aquarion-easton'), '{}'::text[])
    || coalesce((SELECT regions FROM utility_providers WHERE slug = 'aquarion-fairfield-town'), '{}'::text[])
    || coalesce((SELECT regions FROM utility_providers WHERE slug = 'aquarion-greenwich'), '{}'::text[])
    || coalesce((SELECT regions FROM utility_providers WHERE slug = 'aquarion-monroe'), '{}'::text[])
    || coalesce((SELECT regions FROM utility_providers WHERE slug = 'aquarion-new-canaan'), '{}'::text[])
    || coalesce((SELECT regions FROM utility_providers WHERE slug = 'aquarion-newtown'), '{}'::text[])
    || coalesce((SELECT regions FROM utility_providers WHERE slug = 'aquarion-ridgefield'), '{}'::text[])
    || coalesce((SELECT regions FROM utility_providers WHERE slug = 'aquarion-shelton'), '{}'::text[])
    || coalesce((SELECT regions FROM utility_providers WHERE slug = 'aquarion-stamford'), '{}'::text[])
    || coalesce((SELECT regions FROM utility_providers WHERE slug = 'aquarion-stratford'), '{}'::text[])
    || coalesce((SELECT regions FROM utility_providers WHERE slug = 'aquarion-trumbull'), '{}'::text[])
    || coalesce((SELECT regions FROM utility_providers WHERE slug = 'aquarion-westport'), '{}'::text[])
    || coalesce((SELECT regions FROM utility_providers WHERE slug = 'aquarion-wilton'), '{}'::text[])
  ) r)
) WHERE slug = 'aquarion-ct';
DELETE FROM utility_providers WHERE slug IN (
  'aquarion-bethel','aquarion-bridgeport','aquarion-brookfield','aquarion-darien',
  'aquarion-easton','aquarion-fairfield-town','aquarion-greenwich','aquarion-monroe',
  'aquarion-new-canaan','aquarion-newtown','aquarion-ridgefield','aquarion-shelton',
  'aquarion-stamford','aquarion-stratford','aquarion-trumbull','aquarion-westport','aquarion-wilton'
);
