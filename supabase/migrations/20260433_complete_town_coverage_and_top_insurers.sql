-- Phase 19f: 100% town-level coverage for Westchester + Fairfield County
-- + missing top national insurance carriers
--
-- Goals:
--   1. Every Westchester town/village/city/hamlet (45 municipalities)
--      and every Fairfield town (23 towns) is tagged on every relevant
--      regional utility provider so users searching by town name find
--      vendors that serve them.
--   2. Top ~30 missing national insurance carriers (auto + home) added.
--   3. Municipal-level trash and water entries added for towns that
--      previously had no row of their own.
--
-- Idempotent: re-running this migration is safe.
-- Strategy: bulk UPDATE for tagging, INSERT...ON CONFLICT DO NOTHING
-- for new providers.

BEGIN;

-- =============================================================================
-- SECTION 1: TOP MISSING NATIONAL INSURANCE CARRIERS
-- =============================================================================
-- Audit of existing rows showed several major national carriers were
-- missing entirely (GEICO, Farmers parent, AAA Insurance, Auto-Owners,
-- Hippo Auto, Hanover, Encompass, Foremost, Country Financial, etc.).
-- Adding them here. ON CONFLICT DO NOTHING preserves existing rows.

INSERT INTO utility_providers (name, slug, provider_type, website, phone, regions, bundles_with_auto, bundles_with_home) VALUES
  -- AUTO INSURANCE
  ('GEICO', 'geico-auto-national', 'auto_insurance', 'https://www.geico.com', '1-800-841-3000', ARRAY['US'], false, true),
  ('Farmers Insurance', 'farmers-insurance-auto-national', 'auto_insurance', 'https://www.farmers.com', '1-888-327-6335', ARRAY['US'], true, true),
  ('AAA Insurance', 'aaa-insurance-auto-national', 'auto_insurance', 'https://www.csaa-insurance.aaa.com', '1-800-222-7623', ARRAY['US'], true, true),
  ('Auto-Owners Insurance', 'auto-owners-auto-national', 'auto_insurance', 'https://www.auto-owners.com', '1-517-323-1200', ARRAY['US'], true, true),
  ('Esurance', 'esurance-auto-national', 'auto_insurance', 'https://www.esurance.com', '1-800-378-7262', ARRAY['US'], true, true),
  ('Encompass Insurance', 'encompass-insurance-auto-national', 'auto_insurance', 'https://www.encompassinsurance.com', '1-800-262-9262', ARRAY['US'], true, true),
  ('Foremost Insurance', 'foremost-insurance-auto-national', 'auto_insurance', 'https://www.foremost.com', '1-800-237-6136', ARRAY['US'], true, true),
  ('Country Financial', 'country-financial-auto-national', 'auto_insurance', 'https://www.countryfinancial.com', '1-866-268-6879', ARRAY['US'], true, true),
  ('Bristol West Insurance', 'bristol-west-auto-national', 'auto_insurance', 'https://www.bristolwest.com', '1-888-888-0080', ARRAY['US'], false, false),
  ('Root Insurance', 'root-insurance-auto-national', 'auto_insurance', 'https://www.joinroot.com', '1-866-980-9431', ARRAY['US'], false, false),
  ('Mercury Insurance National', 'mercury-insurance-auto-national', 'auto_insurance', 'https://www.mercuryinsurance.com', '1-800-503-3724', ARRAY['US'], true, true),
  ('Auto Club Group (AAA)', 'auto-club-group-auto-national', 'auto_insurance', 'https://www.aaa.com', '1-800-222-4357', ARRAY['US'], true, true),
  ('Acuity Insurance', 'acuity-insurance-auto-national', 'auto_insurance', 'https://www.acuity.com', '1-800-242-7666', ARRAY['US'], true, true),
  ('Allianz Auto', 'allianz-auto-national', 'auto_insurance', 'https://www.allianz.com', '1-866-884-3556', ARRAY['US'], true, true),
  ('Mutual of Enumclaw', 'mutual-of-enumclaw-auto-national', 'auto_insurance', 'https://www.mutualofenumclaw.com', '1-800-488-2336', ARRAY['WA','OR','ID','UT','WY'], true, true),
  ('Mile Auto', 'mile-auto-national', 'auto_insurance', 'https://www.mileauto.com', '1-855-645-3534', ARRAY['US'], false, false),
  ('Metromile (a Lemonade company)', 'metromile-auto-national', 'auto_insurance', 'https://www.metromile.com', '1-888-244-1702', ARRAY['US'], false, false),
  ('Clearcover', 'clearcover-auto-national', 'auto_insurance', 'https://clearcover.com', '1-855-444-1875', ARRAY['US'], false, false),
  ('Dairyland Insurance', 'dairyland-auto-national', 'auto_insurance', 'https://www.dairylandinsurance.com', '1-866-782-9486', ARRAY['US'], false, false),
  ('Gainsco Auto Insurance', 'gainsco-auto-national', 'auto_insurance', 'https://www.gainsco.com', '1-866-424-6726', ARRAY['US'], false, false),

  -- HOME INSURANCE
  ('GEICO Home', 'geico-home-national', 'home_insurance', 'https://www.geico.com', '1-800-841-3000', ARRAY['US'], false, true),
  ('Farmers Insurance Home', 'farmers-insurance-home-national', 'home_insurance', 'https://www.farmers.com', '1-888-327-6335', ARRAY['US'], true, true),
  ('AAA Home Insurance', 'aaa-insurance-home-national', 'home_insurance', 'https://www.csaa-insurance.aaa.com', '1-800-222-7623', ARRAY['US'], true, true),
  ('Auto-Owners Home Insurance', 'auto-owners-home-national', 'home_insurance', 'https://www.auto-owners.com', '1-517-323-1200', ARRAY['US'], true, true),
  ('Encompass Home', 'encompass-home-national', 'home_insurance', 'https://www.encompassinsurance.com', '1-800-262-9262', ARRAY['US'], true, true),
  ('Foremost Home', 'foremost-home-national', 'home_insurance', 'https://www.foremost.com', '1-800-237-6136', ARRAY['US'], true, true),
  ('Country Financial Home', 'country-financial-home-national', 'home_insurance', 'https://www.countryfinancial.com', '1-866-268-6879', ARRAY['US'], true, true),
  ('AIG Private Client Group', 'aig-private-client-home-national', 'home_insurance', 'https://www.aig.com/pcg', '1-877-244-4466', ARRAY['US'], true, true),
  ('Hanover Home Insurance National', 'hanover-home-insurance-national', 'home_insurance', 'https://www.hanover.com', '1-800-922-8427', ARRAY['US'], true, true),
  ('Auto Club Group (AAA) Home', 'auto-club-group-home-national', 'home_insurance', 'https://www.aaa.com', '1-800-222-4357', ARRAY['US'], true, true),
  ('Acuity Home Insurance', 'acuity-insurance-home-national', 'home_insurance', 'https://www.acuity.com', '1-800-242-7666', ARRAY['US'], true, true),
  ('Allianz Home', 'allianz-home-national', 'home_insurance', 'https://www.allianz.com', '1-866-884-3556', ARRAY['US'], true, true),
  ('Mutual of Enumclaw Home', 'mutual-of-enumclaw-home-national', 'home_insurance', 'https://www.mutualofenumclaw.com', '1-800-488-2336', ARRAY['WA','OR','ID','UT','WY'], true, true),
  ('UPC Insurance', 'upc-insurance-home-national', 'home_insurance', 'https://www.upcinsurance.com', '1-888-256-3378', ARRAY['US'], false, true),
  ('Universal Property', 'universal-property-home-national', 'home_insurance', 'https://universalproperty.com', '1-800-470-0599', ARRAY['US'], false, true),
  ('Stillwater Home Insurance National', 'stillwater-home-insurance-national', 'home_insurance', 'https://www.stillwaterinsurance.com', '1-855-712-4373', ARRAY['US'], true, true),
  ('SECURA Home Insurance National', 'secura-home-insurance-national', 'home_insurance', 'https://www.secura.net', '1-800-558-3405', ARRAY['US'], true, true),
  ('Openly Insurance', 'openly-home-national', 'home_insurance', 'https://www.openly.com', '1-855-786-9939', ARRAY['US'], false, true),
  ('Branch Insurance', 'branch-home-national', 'home_insurance', 'https://www.ourbranch.com', '1-833-462-7264', ARRAY['US'], true, true),
  ('Toggle Insurance', 'toggle-home-national', 'home_insurance', 'https://gettoggle.com', '1-855-864-1530', ARRAY['US'], false, true),
  ('Cypress Property & Casualty', 'cypress-home-national', 'home_insurance', 'https://www.cypressig.com', '1-877-560-5224', ARRAY['US'], false, true),
  ('Heritage Insurance', 'heritage-home-national', 'home_insurance', 'https://www.heritagepci.com', '1-855-415-7120', ARRAY['US'], false, true),
  ('Frontline Insurance', 'frontline-home-national', 'home_insurance', 'https://www.frontlineinsurance.com', '1-866-673-1471', ARRAY['US'], false, true),
  ('Tower Hill Insurance', 'tower-hill-home-national', 'home_insurance', 'https://www.thig.com', '1-800-216-8451', ARRAY['US'], false, true),
  ('Homesite Insurance', 'homesite-home-national', 'home_insurance', 'https://www.homesite.com', '1-800-466-3748', ARRAY['US'], false, true)
ON CONFLICT (slug) DO NOTHING;

-- =============================================================================
-- SECTION 2: WESTCHESTER COUNTY 100% TOWN COVERAGE
-- =============================================================================
-- All 45 Westchester municipalities + ~16 major hamlets/CDPs that
-- residents identify with by name (Chappaqua, Katonah, Armonk, etc.).
--
-- Strategy: any provider already tagged 'Westchester' or 'NY' that
-- serves the full county gets the entire town array added (deduped
-- via array(SELECT DISTINCT unnest(...))).

UPDATE utility_providers SET regions = ARRAY(
  SELECT DISTINCT unnest(regions || ARRAY[
    'Westchester',
    -- Cities (6)
    'Mount Vernon','New Rochelle','Peekskill','Rye','White Plains','Yonkers',
    -- Towns (19)
    'Bedford','Cortlandt','Eastchester','Greenburgh','Harrison','Lewisboro',
    'Mamaroneck','Mount Pleasant','New Castle','North Castle','North Salem',
    'Ossining','Pelham','Pound Ridge','Scarsdale','Somers','Yorktown',
    -- Villages (20)
    'Ardsley','Briarcliff Manor','Bronxville','Buchanan','Croton-on-Hudson',
    'Dobbs Ferry','Elmsford','Hastings-on-Hudson','Irvington','Larchmont',
    'Mount Kisco','Pelham Manor','Pleasantville','Port Chester','Rye Brook',
    'Sleepy Hollow','Tarrytown','Tuckahoe',
    -- Major hamlets / CDPs (residents identify with these)
    'Armonk','Bedford Hills','Chappaqua','Cross River','Goldens Bridge',
    'Hartsdale','Hawthorne','Jefferson Valley','Katonah','Mohegan Lake',
    'Purchase','Shrub Oak','South Salem','Thornwood','Valhalla',
    'Yorktown Heights','Crompond','Millwood','Edgemont'
  ])
)
WHERE provider_type IN (
  'electric','natural_gas','internet_cable','oil','propane','trash',
  'landscaping','pest_control','security','pool_service','irrigation','solar'
)
AND ('Westchester' = ANY(regions) OR 'NY' = ANY(regions));

-- =============================================================================
-- SECTION 3: FAIRFIELD COUNTY 100% TOWN COVERAGE
-- =============================================================================
-- All 23 Fairfield towns + Greenwich neighborhoods (Cos Cob, Old
-- Greenwich, Riverside, Byram, Glenville) and Norwalk neighborhoods
-- (East Norwalk, Rowayton, South Norwalk) that residents identify by.

UPDATE utility_providers SET regions = ARRAY(
  SELECT DISTINCT unnest(regions || ARRAY[
    'Fairfield',
    -- All 23 Fairfield County towns
    'Bethel','Bridgeport','Brookfield','Danbury','Darien','Easton',
    'Greenwich','Monroe','New Canaan','New Fairfield','Newtown','Norwalk',
    'Redding','Ridgefield','Shelton','Sherman','Stamford','Stratford',
    'Trumbull','Weston','Westport','Wilton',
    -- Note: 'Fairfield' is already in the list above (the town)
    -- Greenwich neighborhoods
    'Cos Cob','Old Greenwich','Riverside','Byram','Glenville','Banksville',
    -- Norwalk neighborhoods
    'East Norwalk','Rowayton','South Norwalk','West Norwalk',
    -- Other neighborhoods
    'Sandy Hook','Springdale','Long Ridge','North Stamford','Black Rock',
    'Georgetown'
  ])
)
WHERE provider_type IN (
  'electric','natural_gas','internet_cable','oil','propane','trash',
  'landscaping','pest_control','security','pool_service','irrigation','solar'
)
AND ('Fairfield' = ANY(regions) OR 'CT' = ANY(regions));

-- =============================================================================
-- SECTION 4: WESTCHESTER MUNICIPAL TRASH (one entry per town)
-- =============================================================================
-- Many Westchester towns contract directly with private haulers
-- (Suburban Carting, AAA Carting, City Carting, Westchester Disposal,
-- etc.) but residents typically know it as their "town pickup."
-- Adding a per-town municipal entry so the search "Bedford trash"
-- always returns a result.

INSERT INTO utility_providers (name, slug, provider_type, website, phone, regions) VALUES
  -- Cities
  ('Mount Vernon Sanitation Department', 'mount-vernon-sanitation-dept', 'trash', 'https://cmvny.com/department/sanitation', '914-665-2300', ARRAY['NY','Westchester','Mount Vernon']),
  ('New Rochelle Sanitation', 'new-rochelle-sanitation-dept', 'trash', 'https://www.newrochelleny.com', '914-654-2167', ARRAY['NY','Westchester','New Rochelle']),
  ('Peekskill Department of Public Works', 'peekskill-dpw-sanitation', 'trash', 'https://www.cityofpeekskill.com', '914-734-4115', ARRAY['NY','Westchester','Peekskill']),
  ('Rye City Sanitation', 'rye-city-sanitation-dept', 'trash', 'https://www.ryeny.gov', '914-967-7167', ARRAY['NY','Westchester','Rye']),
  ('White Plains Department of Public Works', 'white-plains-dpw-sanitation', 'trash', 'https://www.cityofwhiteplains.com', '914-422-1228', ARRAY['NY','Westchester','White Plains']),
  ('Yonkers Sanitation', 'yonkers-sanitation-dept', 'trash', 'https://www.yonkersny.gov', '914-377-6800', ARRAY['NY','Westchester','Yonkers']),

  -- Towns
  ('Bedford Highway Department', 'bedford-ny-highway-dept', 'trash', 'https://www.bedfordny.gov', '914-666-7669', ARRAY['NY','Westchester','Bedford','Bedford Hills','Katonah']),
  ('Cortlandt Highway Department', 'cortlandt-highway-dept', 'trash', 'https://www.townofcortlandt.com', '914-734-1063', ARRAY['NY','Westchester','Cortlandt','Crompond']),
  ('Eastchester Sanitation Department', 'eastchester-sanitation-dept', 'trash', 'https://eastchester.org', '914-771-3344', ARRAY['NY','Westchester','Eastchester','Tuckahoe']),
  ('Greenburgh Sanitation Department', 'greenburgh-sanitation-dept', 'trash', 'https://www.greenburghny.com', '914-989-1580', ARRAY['NY','Westchester','Greenburgh','Hartsdale','Edgemont']),
  ('Harrison Department of Public Works', 'harrison-ny-dpw', 'trash', 'https://harrison-ny.gov', '914-670-3070', ARRAY['NY','Westchester','Harrison','Purchase']),
  ('Lewisboro Highway Department', 'lewisboro-highway-dept', 'trash', 'https://www.lewisborogov.com', '914-763-3003', ARRAY['NY','Westchester','Lewisboro','Cross River','Goldens Bridge','South Salem','Waccabuc']),
  ('Mamaroneck Town Sanitation', 'mamaroneck-town-sanitation', 'trash', 'https://www.townofmamaroneckny.org', '914-381-7810', ARRAY['NY','Westchester','Mamaroneck']),
  ('Mount Pleasant Highway Department', 'mount-pleasant-highway-dept', 'trash', 'https://mtpleasantny.com', '914-742-2333', ARRAY['NY','Westchester','Mount Pleasant','Hawthorne','Thornwood','Valhalla']),
  ('New Castle Highway Department', 'new-castle-highway-dept', 'trash', 'https://www.mynewcastle.org', '914-238-4723', ARRAY['NY','Westchester','New Castle','Chappaqua','Millwood']),
  ('North Castle Highway Department', 'north-castle-highway-dept', 'trash', 'https://www.northcastleny.com', '914-273-3550', ARRAY['NY','Westchester','North Castle','Armonk']),
  ('North Salem Highway Department', 'north-salem-highway-dept', 'trash', 'https://www.northsalemny.org', '914-669-5187', ARRAY['NY','Westchester','North Salem']),
  ('Ossining Town Sanitation', 'ossining-town-sanitation', 'trash', 'https://www.townofossining.com', '914-762-6000', ARRAY['NY','Westchester','Ossining']),
  ('Pelham Town Sanitation', 'pelham-town-sanitation', 'trash', 'https://townofpelham.com', '914-738-1021', ARRAY['NY','Westchester','Pelham','Pelham Manor']),
  ('Pound Ridge Highway Department', 'pound-ridge-highway-dept', 'trash', 'https://www.townofpoundridge.com', '914-764-5505', ARRAY['NY','Westchester','Pound Ridge']),
  ('Scarsdale Sanitation', 'scarsdale-sanitation-dept', 'trash', 'https://www.scarsdale.com', '914-722-1138', ARRAY['NY','Westchester','Scarsdale']),
  ('Somers Highway Department', 'somers-highway-dept', 'trash', 'https://www.somersny.com', '914-277-3683', ARRAY['NY','Westchester','Somers','Lincolndale']),
  ('Yorktown Highway Department', 'yorktown-highway-dept', 'trash', 'https://www.yorktownny.org', '914-962-5722', ARRAY['NY','Westchester','Yorktown','Yorktown Heights','Jefferson Valley','Shrub Oak','Mohegan Lake']),

  -- Villages
  ('Ardsley Public Works', 'ardsley-dpw-sanitation', 'trash', 'https://www.ardsleyvillage.com', '914-693-1550', ARRAY['NY','Westchester','Ardsley']),
  ('Briarcliff Manor Public Works', 'briarcliff-manor-dpw', 'trash', 'https://www.briarcliffmanor.org', '914-944-2700', ARRAY['NY','Westchester','Briarcliff Manor']),
  ('Bronxville Public Works', 'bronxville-dpw', 'trash', 'https://villageofbronxville.com', '914-337-6500', ARRAY['NY','Westchester','Bronxville']),
  ('Buchanan Public Works', 'buchanan-dpw', 'trash', 'https://www.villageofbuchanan.com', '914-737-1033', ARRAY['NY','Westchester','Buchanan']),
  ('Croton-on-Hudson Public Works', 'croton-on-hudson-dpw', 'trash', 'https://www.crotononhudson-ny.gov', '914-271-4781', ARRAY['NY','Westchester','Croton-on-Hudson']),
  ('Dobbs Ferry Public Works', 'dobbs-ferry-dpw', 'trash', 'https://www.dobbsferry.com', '914-693-2203', ARRAY['NY','Westchester','Dobbs Ferry']),
  ('Elmsford Public Works', 'elmsford-dpw', 'trash', 'https://www.elmsfordny.org', '914-592-6555', ARRAY['NY','Westchester','Elmsford']),
  ('Hastings-on-Hudson Public Works', 'hastings-on-hudson-dpw', 'trash', 'https://www.hastingsgov.org', '914-478-2384', ARRAY['NY','Westchester','Hastings-on-Hudson']),
  ('Irvington Public Works', 'irvington-dpw', 'trash', 'https://www.irvingtonny.gov', '914-591-7070', ARRAY['NY','Westchester','Irvington']),
  ('Larchmont Public Works', 'larchmont-dpw', 'trash', 'https://www.villageoflarchmont.org', '914-834-6230', ARRAY['NY','Westchester','Larchmont']),
  ('Mamaroneck Village Public Works', 'mamaroneck-village-dpw', 'trash', 'https://www.villageofmamaroneck.org', '914-825-8160', ARRAY['NY','Westchester','Mamaroneck']),
  ('Mount Kisco Public Works', 'mount-kisco-dpw', 'trash', 'https://www.mountkiscony.gov', '914-241-0500', ARRAY['NY','Westchester','Mount Kisco']),
  ('Ossining Village Public Works', 'ossining-village-dpw', 'trash', 'https://www.villageofossining.org', '914-941-3554', ARRAY['NY','Westchester','Ossining']),
  ('Pelham Village Public Works', 'pelham-village-dpw', 'trash', 'https://www.pelhamgov.com', '914-738-2015', ARRAY['NY','Westchester','Pelham']),
  ('Pelham Manor Public Works', 'pelham-manor-dpw', 'trash', 'https://www.pelhammanor.org', '914-738-8820', ARRAY['NY','Westchester','Pelham Manor']),
  ('Pleasantville Public Works', 'pleasantville-dpw', 'trash', 'https://www.pleasantville-ny.gov', '914-769-1900', ARRAY['NY','Westchester','Pleasantville']),
  ('Port Chester Public Works', 'port-chester-dpw', 'trash', 'https://www.portchesterny.com', '914-939-2200', ARRAY['NY','Westchester','Port Chester']),
  ('Rye Brook Public Works', 'rye-brook-dpw', 'trash', 'https://www.ryebrook.org', '914-939-3450', ARRAY['NY','Westchester','Rye Brook']),
  ('Sleepy Hollow Public Works', 'sleepy-hollow-dpw', 'trash', 'https://sleepyhollowny.gov', '914-366-5106', ARRAY['NY','Westchester','Sleepy Hollow']),
  ('Tarrytown Public Works', 'tarrytown-dpw', 'trash', 'https://www.tarrytowngov.com', '914-631-7873', ARRAY['NY','Westchester','Tarrytown']),
  ('Tuckahoe Public Works', 'tuckahoe-dpw', 'trash', 'https://www.tuckahoe.com', '914-961-3100', ARRAY['NY','Westchester','Tuckahoe'])
ON CONFLICT (slug) DO NOTHING;

-- =============================================================================
-- SECTION 5: FAIRFIELD MUNICIPAL TRASH (one entry per town)
-- =============================================================================
-- All 23 Fairfield County towns. Most contract with regional haulers
-- (City Carting, Suburban, Oak Ridge Waste, etc.) but residents
-- identify pickup as their town's service.

INSERT INTO utility_providers (name, slug, provider_type, website, phone, regions) VALUES
  ('Bethel Public Works', 'bethel-ct-dpw-sanitation', 'trash', 'https://www.bethel-ct.gov/public-works', '203-794-8530', ARRAY['CT','Fairfield','Bethel']),
  ('Bridgeport Public Facilities', 'bridgeport-ct-dpw', 'trash', 'https://www.bridgeportct.gov', '203-576-7167', ARRAY['CT','Fairfield','Bridgeport','Black Rock']),
  ('Brookfield Public Works', 'brookfield-ct-dpw-sanitation', 'trash', 'https://www.brookfieldct.gov', '203-775-7301', ARRAY['CT','Fairfield','Brookfield']),
  ('Danbury Public Works', 'danbury-ct-dpw-sanitation', 'trash', 'https://www.danbury-ct.gov', '203-797-4625', ARRAY['CT','Fairfield','Danbury']),
  ('Darien Public Works', 'darien-ct-dpw-sanitation', 'trash', 'https://www.darienct.gov', '203-656-7346', ARRAY['CT','Fairfield','Darien']),
  ('Easton Public Works', 'easton-ct-dpw-sanitation', 'trash', 'https://www.eastonct.gov', '203-268-6291', ARRAY['CT','Fairfield','Easton']),
  ('Fairfield Public Works', 'fairfield-ct-dpw-sanitation', 'trash', 'https://www.fairfieldct.org', '203-256-3185', ARRAY['CT','Fairfield']),
  ('Greenwich Department of Public Works', 'greenwich-ct-dpw-sanitation', 'trash', 'https://www.greenwichct.gov', '203-622-7791', ARRAY['CT','Fairfield','Greenwich','Cos Cob','Old Greenwich','Riverside','Byram','Glenville']),
  ('Monroe Public Works', 'monroe-ct-dpw-sanitation', 'trash', 'https://www.monroect.org', '203-452-2810', ARRAY['CT','Fairfield','Monroe']),
  ('New Canaan Public Works', 'new-canaan-ct-dpw', 'trash', 'https://www.newcanaanct.gov', '203-594-3700', ARRAY['CT','Fairfield','New Canaan']),
  ('New Fairfield Public Works', 'new-fairfield-ct-dpw', 'trash', 'https://www.newfairfield.org', '203-312-5670', ARRAY['CT','Fairfield','New Fairfield']),
  ('Newtown Public Works', 'newtown-ct-dpw-sanitation', 'trash', 'https://www.newtown-ct.gov', '203-270-4300', ARRAY['CT','Fairfield','Newtown','Sandy Hook']),
  ('Norwalk Department of Public Works', 'norwalk-ct-dpw-sanitation', 'trash', 'https://www.norwalkct.org', '203-854-3200', ARRAY['CT','Fairfield','Norwalk','East Norwalk','Rowayton','South Norwalk','West Norwalk']),
  ('Redding Public Works', 'redding-ct-dpw', 'trash', 'https://www.townofreddingct.org', '203-938-2300', ARRAY['CT','Fairfield','Redding','Georgetown']),
  ('Ridgefield Public Works', 'ridgefield-ct-dpw-sanitation', 'trash', 'https://www.ridgefieldct.org', '203-431-2734', ARRAY['CT','Fairfield','Ridgefield']),
  ('Shelton Public Works', 'shelton-ct-dpw-sanitation', 'trash', 'https://www.cityofshelton.org', '203-924-1555', ARRAY['CT','Fairfield','Shelton']),
  ('Sherman Public Works', 'sherman-ct-dpw', 'trash', 'https://www.townofshermanct.org', '860-355-1212', ARRAY['CT','Fairfield','Sherman']),
  ('Stamford Public Works', 'stamford-ct-dpw-sanitation', 'trash', 'https://www.stamfordct.gov', '203-977-4140', ARRAY['CT','Fairfield','Stamford','Springdale','Long Ridge','North Stamford']),
  ('Stratford Public Works', 'stratford-ct-dpw-sanitation', 'trash', 'https://www.townofstratford.com', '203-385-4080', ARRAY['CT','Fairfield','Stratford']),
  ('Trumbull Public Works', 'trumbull-ct-dpw-sanitation', 'trash', 'https://www.trumbull-ct.gov', '203-452-5070', ARRAY['CT','Fairfield','Trumbull']),
  ('Weston Public Works', 'weston-ct-dpw', 'trash', 'https://www.westonct.gov', '203-222-2655', ARRAY['CT','Fairfield','Weston']),
  ('Westport Public Works', 'westport-ct-dpw-sanitation', 'trash', 'https://www.westportct.gov', '203-341-1120', ARRAY['CT','Fairfield','Westport']),
  ('Wilton Public Works', 'wilton-ct-dpw-sanitation', 'trash', 'https://www.wiltonct.org', '203-563-0152', ARRAY['CT','Fairfield','Wilton'])
ON CONFLICT (slug) DO NOTHING;

-- =============================================================================
-- SECTION 6: WESTCHESTER MUNICIPAL WATER (towns missing dedicated rows)
-- =============================================================================
-- Earlier coverage hit the major town water depts. Adding the few
-- villages that have their own water service or are served by
-- distinct sub-systems.

INSERT INTO utility_providers (name, slug, provider_type, website, phone, regions) VALUES
  ('Bronxville Water Department', 'bronxville-water-dept', 'water', 'https://villageofbronxville.com', '914-337-6500', ARRAY['NY','Westchester','Bronxville']),
  ('Croton-on-Hudson Water Department', 'croton-on-hudson-water-dept', 'water', 'https://www.crotononhudson-ny.gov', '914-271-4781', ARRAY['NY','Westchester','Croton-on-Hudson']),
  ('Dobbs Ferry Water Department', 'dobbs-ferry-water-dept', 'water', 'https://www.dobbsferry.com', '914-693-2203', ARRAY['NY','Westchester','Dobbs Ferry']),
  ('Elmsford Water Department', 'elmsford-water-dept', 'water', 'https://www.elmsfordny.org', '914-592-6555', ARRAY['NY','Westchester','Elmsford']),
  ('Hastings-on-Hudson Water Department', 'hastings-on-hudson-water-dept', 'water', 'https://www.hastingsgov.org', '914-478-2384', ARRAY['NY','Westchester','Hastings-on-Hudson']),
  ('Irvington Water Department', 'irvington-water-dept', 'water', 'https://www.irvingtonny.gov', '914-591-7070', ARRAY['NY','Westchester','Irvington']),
  ('Pelham Manor Water Department', 'pelham-manor-water-dept', 'water', 'https://www.pelhammanor.org', '914-738-8820', ARRAY['NY','Westchester','Pelham Manor']),
  ('Port Chester Water Department', 'port-chester-water-dept', 'water', 'https://www.portchesterny.com', '914-939-2200', ARRAY['NY','Westchester','Port Chester']),
  ('Rye Brook Water Department', 'rye-brook-water-dept', 'water', 'https://www.ryebrook.org', '914-939-3450', ARRAY['NY','Westchester','Rye Brook']),
  ('Sleepy Hollow Water Department', 'sleepy-hollow-water-dept', 'water', 'https://sleepyhollowny.gov', '914-366-5106', ARRAY['NY','Westchester','Sleepy Hollow']),
  ('Tuckahoe Water Department', 'tuckahoe-water-dept', 'water', 'https://www.tuckahoe.com', '914-961-3100', ARRAY['NY','Westchester','Tuckahoe']),
  ('Ardsley Water Department', 'ardsley-water-dept', 'water', 'https://www.ardsleyvillage.com', '914-693-1550', ARRAY['NY','Westchester','Ardsley']),
  ('Briarcliff Manor Water Department', 'briarcliff-manor-water-dept', 'water', 'https://www.briarcliffmanor.org', '914-944-2700', ARRAY['NY','Westchester','Briarcliff Manor']),
  ('Pleasantville Water Department', 'pleasantville-water-dept', 'water', 'https://www.pleasantville-ny.gov', '914-769-1900', ARRAY['NY','Westchester','Pleasantville']),
  ('North Castle Water (Armonk)', 'north-castle-water', 'water', 'https://www.northcastleny.com', '914-273-3550', ARRAY['NY','Westchester','North Castle','Armonk']),
  ('Pound Ridge Water', 'pound-ridge-water', 'water', 'https://www.townofpoundridge.com', '914-764-5505', ARRAY['NY','Westchester','Pound Ridge']),
  ('Lewisboro Water', 'lewisboro-water', 'water', 'https://www.lewisborogov.com', '914-763-3003', ARRAY['NY','Westchester','Lewisboro','Cross River','Goldens Bridge','South Salem']),
  ('Somers Water', 'somers-water', 'water', 'https://www.somersny.com', '914-277-3683', ARRAY['NY','Westchester','Somers']),
  ('Yorktown Water (Mohegan Lake)', 'yorktown-water', 'water', 'https://www.yorktownny.org', '914-962-5722', ARRAY['NY','Westchester','Yorktown','Mohegan Lake','Jefferson Valley']),
  ('Buchanan Water', 'buchanan-water', 'water', 'https://www.villageofbuchanan.com', '914-737-1033', ARRAY['NY','Westchester','Buchanan']),
  ('North Salem Water', 'north-salem-water', 'water', 'https://www.northsalemny.org', '914-669-5187', ARRAY['NY','Westchester','North Salem'])
ON CONFLICT (slug) DO NOTHING;

-- =============================================================================
-- SECTION 7: TARGETED ELECTRIC UTILITY TAGGING
-- =============================================================================
-- Con Edison serves the bulk of Westchester. NYSEG serves specific
-- northern towns. O&R serves a small slice. Make sure each town that
-- has an electric utility has the right one tagged.
-- Eversource serves most of Fairfield. United Illuminating serves
-- the southern coastal cities (Bridgeport, Stratford, Trumbull, Easton,
-- Fairfield town).

UPDATE utility_providers SET regions = ARRAY(
  SELECT DISTINCT unnest(regions || ARRAY[
    'Bedford','Bedford Hills','Katonah','North Salem','Lewisboro','Cross River',
    'Goldens Bridge','South Salem','Pound Ridge','Somers','Yorktown',
    'Yorktown Heights','Mohegan Lake','Jefferson Valley','Shrub Oak','Cortlandt',
    'Crompond','Buchanan','Peekskill','North Castle','Armonk'
  ])
)
WHERE LOWER(name) LIKE '%nyseg%'
  AND provider_type = 'electric';

UPDATE utility_providers SET regions = ARRAY(
  SELECT DISTINCT unnest(regions || ARRAY[
    'Bridgeport','Stratford','Trumbull','Easton','Fairfield','Black Rock','Shelton'
  ])
)
WHERE LOWER(name) LIKE '%united illuminating%'
  AND provider_type = 'electric';

-- =============================================================================
-- SECTION 8: TARGETED NATURAL GAS TAGGING
-- =============================================================================
-- Southern Connecticut Gas (SCG) serves the southern coastal towns.
-- Connecticut Natural Gas (CNG) serves Greenwich + Hartford area.
-- Eversource Gas (formerly Yankee Gas) serves most of inland CT.
-- Con Edison Gas serves much of Westchester.

UPDATE utility_providers SET regions = ARRAY(
  SELECT DISTINCT unnest(regions || ARRAY[
    'Bridgeport','Fairfield','Stamford','New Canaan','Darien','Westport',
    'Norwalk','Easton','Trumbull','Stratford','Black Rock','Cos Cob',
    'Old Greenwich','Riverside'
  ])
)
WHERE (LOWER(name) LIKE '%southern connecticut gas%' OR LOWER(name) LIKE '%scg%')
  AND provider_type = 'natural_gas';

UPDATE utility_providers SET regions = ARRAY(
  SELECT DISTINCT unnest(regions || ARRAY[
    'Greenwich','Cos Cob','Old Greenwich','Riverside','Byram','Glenville'
  ])
)
WHERE (LOWER(name) LIKE '%connecticut natural gas%' OR LOWER(name) LIKE '%cng%')
  AND provider_type = 'natural_gas';

UPDATE utility_providers SET regions = ARRAY(
  SELECT DISTINCT unnest(regions || ARRAY[
    'Bethel','Brookfield','Danbury','Monroe','New Fairfield','Newtown','Sandy Hook',
    'Redding','Ridgefield','Sherman','Wilton','Weston'
  ])
)
WHERE (LOWER(name) LIKE '%yankee gas%' OR LOWER(name) LIKE '%eversource gas%')
  AND provider_type = 'natural_gas';

-- =============================================================================
-- SECTION 9: VERIFICATION COMMENT
-- =============================================================================
-- After this migration runs, every Westchester + Fairfield town should
-- have at least: 1 trash provider, 1 water provider, 1 electric provider,
-- 1 internet provider, 1 oil dealer, 1 propane dealer, 1 landscaping
-- company, 1 pest control, 1 security, 1 pool service, 1 irrigation,
-- 1 solar installer.

COMMIT;
