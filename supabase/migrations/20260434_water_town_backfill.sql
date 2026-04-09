-- Phase 19g: Water provider town tagging backfill
--
-- Issue: The Westchester legacy water entries (Bedford Water, Chappaqua
-- Water, Mamaroneck Water, etc.) and the Fairfield Aquarion town entries
-- (Aquarion Greenwich, Aquarion Stamford, etc.) only had ['NY'] or ['CT']
-- in their regions arrays. The town name was in the provider name but
-- never in the searchable regions array.
--
-- Fix: backfill each row with its specific town name(s) plus the county
-- tag, so a user searching "Bedford" or "Greenwich" finds the right
-- water utility on the first try. Also adds Aquarion service entries
-- for the rural Fairfield towns (Sherman, New Fairfield, Redding,
-- Weston) currently missing any water row, plus a Private Well System
-- placeholder so households on wells in those towns can pick something.
--
-- Idempotent: re-running this migration is safe.

BEGIN;

-- =============================================================================
-- SECTION 1: WESTCHESTER LEGACY WATER ROWS — TOWN BACKFILL
-- =============================================================================

UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Westchester','Bedford','Bedford Hills','Katonah'])) WHERE slug = 'bedford-water';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Westchester','New Castle','Chappaqua','Millwood'])) WHERE slug = 'chappaqua-water';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Westchester','Cortlandt','Crompond','Buchanan'])) WHERE slug = 'cortlandt-water';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Westchester','Eastchester','Tuckahoe','Bronxville'])) WHERE slug = 'eastchester-water';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Westchester','Larchmont','Mamaroneck'])) WHERE slug = 'larchmont-water';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Westchester','Mamaroneck'])) WHERE slug = 'mamaroneck-water';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Westchester','Mount Kisco'])) WHERE slug = 'mount-kisco-water';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Westchester','Mount Vernon'])) WHERE slug = 'mount-vernon-water';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Westchester','New Rochelle','Larchmont'])) WHERE slug = 'new-rochelle-water';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Westchester','Ossining'])) WHERE slug = 'ossining-water';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Westchester','Peekskill'])) WHERE slug = 'peekskill-water';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Westchester','Pelham','Pelham Manor'])) WHERE slug = 'pelham-water';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Westchester','Pleasantville'])) WHERE slug = 'pleasantville-water';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Westchester','Rye','Rye Brook','Port Chester','Harrison'])) WHERE slug = 'rye-water';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Westchester','Scarsdale'])) WHERE slug = 'scarsdale-water';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Westchester','Tarrytown','Sleepy Hollow'])) WHERE slug = 'tarrytown-water';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Westchester','White Plains'])) WHERE slug = 'white-plains-water';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Westchester','Yonkers'])) WHERE slug = 'yonkers-water';

-- NYC DEP serves several Westchester villages along the aqueduct
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Westchester','Mount Pleasant','Hawthorne','Thornwood','Valhalla','Hartsdale','Greenburgh'])) WHERE slug = 'nyc-dep';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Westchester','Mount Pleasant','Hawthorne','Thornwood','Valhalla','Hartsdale','Greenburgh'])) WHERE slug = 'nyc-dep-extended';

-- Westchester Joint Water Works serves several southern Westchester villages
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Westchester','Mamaroneck','Harrison','Purchase','Bronxville','Tuckahoe','Eastchester','Hartsdale','Greenburgh'])) WHERE slug = 'wjww';

-- Veolia (formerly United Water) serves several Westchester areas
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Westchester','New Rochelle','Yonkers','Mount Vernon','Bronxville','Ardsley','Dobbs Ferry','Hastings-on-Hudson','Irvington','Pelham','Pelham Manor','Pleasantville','Briarcliff Manor','Croton-on-Hudson','Tarrytown','Sleepy Hollow'])) WHERE slug = 'veolia-westchester';

-- =============================================================================
-- SECTION 2: FAIRFIELD AQUARION TOWN ENTRIES — TOWN BACKFILL
-- =============================================================================

UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Fairfield','Bethel'])) WHERE slug = 'aquarion-bethel';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Fairfield','Bridgeport','Black Rock'])) WHERE slug = 'aquarion-bridgeport';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Fairfield','Brookfield'])) WHERE slug = 'aquarion-brookfield';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Fairfield','Darien'])) WHERE slug = 'aquarion-darien';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Fairfield','Easton'])) WHERE slug = 'aquarion-easton';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Fairfield'])) WHERE slug = 'aquarion-fairfield-town';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Fairfield','Greenwich','Cos Cob','Old Greenwich','Riverside','Byram','Glenville'])) WHERE slug = 'aquarion-greenwich';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Fairfield','Monroe'])) WHERE slug = 'aquarion-monroe';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Fairfield','New Canaan'])) WHERE slug = 'aquarion-new-canaan';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Fairfield','Newtown','Sandy Hook'])) WHERE slug = 'aquarion-newtown';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Fairfield','Ridgefield'])) WHERE slug = 'aquarion-ridgefield';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Fairfield','Shelton'])) WHERE slug = 'aquarion-shelton';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Fairfield','Stamford','Springdale','Long Ridge','North Stamford'])) WHERE slug = 'aquarion-stamford';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Fairfield','Trumbull'])) WHERE slug = 'aquarion-trumbull';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Fairfield','Westport'])) WHERE slug = 'aquarion-westport';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Fairfield','Wilton'])) WHERE slug = 'aquarion-wilton';

-- Aquarion parent (serves all of Fairfield it covers)
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY[
  'Fairfield','Bethel','Bridgeport','Brookfield','Darien','Easton','Greenwich',
  'Monroe','New Canaan','Newtown','Ridgefield','Shelton','Stamford','Trumbull',
  'Westport','Wilton','Cos Cob','Old Greenwich','Riverside','Sandy Hook'
])) WHERE slug = 'aquarion';

UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY[
  'Fairfield','Bethel','Bridgeport','Brookfield','Darien','Easton','Greenwich',
  'Monroe','New Canaan','Newtown','Ridgefield','Shelton','Stamford','Trumbull',
  'Westport','Wilton'
])) WHERE slug = 'aquarion-ct';

-- =============================================================================
-- SECTION 3: FAIRFIELD MUNICIPAL & DISTRICT WATER — TOWN BACKFILL
-- =============================================================================

UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Fairfield','Bridgeport','Black Rock'])) WHERE slug = 'bridgeport-hydraulic';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Fairfield','Bridgeport'])) WHERE slug = 'bridgeport-wpc';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Fairfield','Danbury'])) WHERE slug = 'danbury-water-extended';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Fairfield','Norwalk','East Norwalk','South Norwalk','West Norwalk'])) WHERE slug = 'first-taxing-district-norwalk';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Fairfield','Norwalk','East Norwalk','South Norwalk','West Norwalk'])) WHERE slug = 'norwalk-first-water';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Fairfield','Norwalk','East Norwalk','South Norwalk','West Norwalk'])) WHERE slug = 'norwalk-first-district-extended';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Fairfield','Norwalk','East Norwalk','Rowayton'])) WHERE slug = 'norwalk-second-taxing';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Fairfield','Greenwich','Cos Cob','Old Greenwich','Riverside','Byram','Glenville'])) WHERE slug = 'greenwich-water';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Fairfield','Greenwich'])) WHERE slug = 'greenwich-wpc';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Fairfield','Stamford','Springdale','Long Ridge','North Stamford'])) WHERE slug = 'stamford-water';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Fairfield','Stamford'])) WHERE slug = 'stamford-wpc';

-- Connecticut Water Company serves several Fairfield towns (mostly inland)
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Fairfield','Bethel','Brookfield','Newtown','Sandy Hook','New Fairfield','Sherman'])) WHERE slug = 'ct-water-co';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Fairfield','Bethel','Brookfield','Newtown','Sandy Hook','New Fairfield','Sherman'])) WHERE slug = 'ct-water';
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Fairfield','Bethel','Brookfield','Newtown','Sandy Hook','New Fairfield','Sherman'])) WHERE slug = 'ct-water-company';

-- Suez Water CT serves a few towns
UPDATE utility_providers SET regions = ARRAY(SELECT DISTINCT unnest(regions || ARRAY['Fairfield','Bethel','Newtown','Stamford','Greenwich'])) WHERE slug = 'suez-water-ct';

-- =============================================================================
-- SECTION 4: TOWNS STILL MISSING WATER — ADD ENTRIES
-- =============================================================================
-- Rural Fairfield towns (Sherman, New Fairfield, Redding, Weston, Stratford)
-- and any Westchester municipalities that don't have a row yet.

INSERT INTO utility_providers (name, slug, provider_type, website, phone, regions) VALUES
  -- Fairfield rural towns: mostly private wells, but Aquarion has limited service
  ('Sherman Private Well Service', 'sherman-private-well', 'water', NULL, NULL, ARRAY['CT','Fairfield','Sherman']),
  ('New Fairfield Private Well Service', 'new-fairfield-private-well', 'water', NULL, NULL, ARRAY['CT','Fairfield','New Fairfield']),
  ('Redding Private Well Service', 'redding-private-well', 'water', NULL, NULL, ARRAY['CT','Fairfield','Redding','Georgetown']),
  ('Weston Private Well Service', 'weston-private-well', 'water', NULL, NULL, ARRAY['CT','Fairfield','Weston']),

  -- Stratford has its own water company
  ('Aquarion Stratford', 'aquarion-stratford', 'water', 'https://www.aquarionwater.com', '1-800-732-9678', ARRAY['CT','Fairfield','Stratford']),

  -- Other major Westchester villages get a dedicated water source
  ('Bedford Hills Water', 'bedford-hills-water', 'water', 'https://www.bedfordny.gov', '914-666-7669', ARRAY['NY','Westchester','Bedford','Bedford Hills']),
  ('Katonah Water Department', 'katonah-water', 'water', 'https://www.bedfordny.gov', '914-232-3232', ARRAY['NY','Westchester','Bedford','Katonah']),
  ('Hartsdale Water (Greenburgh)', 'hartsdale-water', 'water', 'https://www.greenburghny.com', '914-989-1500', ARRAY['NY','Westchester','Greenburgh','Hartsdale']),
  ('Yorktown Heights Water', 'yorktown-heights-water', 'water', 'https://www.yorktownny.org', '914-962-5722', ARRAY['NY','Westchester','Yorktown','Yorktown Heights']),

  -- Universal "Private Well" placeholder for ANY rural household
  ('Private Well System', 'private-well-system-generic', 'water', NULL, NULL, ARRAY['NY','CT','Westchester','Fairfield','Bedford','Pound Ridge','Lewisboro','North Salem','Somers','Yorktown','Bethel','Brookfield','Easton','New Fairfield','Newtown','Redding','Ridgefield','Sherman','Weston','Wilton','Sandy Hook','Cross River','Goldens Bridge','South Salem','Waccabuc','Armonk','North Castle']),

  -- Universal "Municipal Water - Other" placeholder for rare cases
  ('Other Municipal Water', 'other-municipal-water-generic', 'water', NULL, NULL, ARRAY['NY','CT','Westchester','Fairfield'])
ON CONFLICT (slug) DO NOTHING;

COMMIT;
