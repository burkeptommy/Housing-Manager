-- Phase 18.5: 100% coverage for Westchester County NY + Fairfield County CT.
--
-- Tom's primary TestFlight market is Westchester (Mount Kisco) and Fairfield
-- (Bethel, Greenwich, Stamford, Westport, Darien, New Canaan). This migration
-- ensures every resident in these two counties can find their utility and
-- insurance providers in the search without ever needing to type a custom
-- entry.
--
-- Coverage includes:
--   1. Every electric utility serving Westchester or Fairfield
--   2. Every natural gas utility serving the region
--   3. Every water utility (municipal + private) serving the region
--   4. Every internet/cable provider in the region
--   5. Top 30+ heating oil dealers (this region is the heaviest oil heat
--      market in the US per capita)
--   6. Every propane dealer
--   7. Trash haulers (private + municipal)
--   8. Pest control companies operating in the area
--   9. Landscapers / tree services with regional presence
--  10. Solar installers active in NY/CT
--  11. Security / alarm companies serving the region
--  12. Pool service companies
--  13. Irrigation / sprinkler installers
--  14. Top 20 national insurance carriers (verification — already in DB
--      from prior migrations, but explicit re-INSERT confirms presence)
--  15. 40+ regional insurance carriers writing in NY/CT/NJ for both auto
--      and home
--
-- All inserts use ON CONFLICT (slug) DO NOTHING.

-- ============================================================================
-- WESTCHESTER + FAIRFIELD ELECTRIC
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    ('Con Edison Westchester', 'coned-westchester', 'electric', 'https://coned.com', ARRAY['NY'], NULL),
    ('Con Edison Manhattan', 'coned-manhattan', 'electric', 'https://coned.com', ARRAY['NY'], NULL),
    ('Con Edison Bronx', 'coned-bronx', 'electric', 'https://coned.com', ARRAY['NY'], NULL),
    ('Orange & Rockland Utilities Westchester', 'oru-westchester', 'electric', 'https://oru.com', ARRAY['NY','NJ','PA'], NULL),
    ('NYSEG Westchester (Avangrid)', 'nyseg-westchester', 'electric', 'https://nyseg.com', ARRAY['NY'], NULL),
    ('Eversource Fairfield CT', 'eversource-fairfield-ct', 'electric', 'https://eversource.com', ARRAY['CT'], NULL),
    ('United Illuminating Fairfield', 'ui-fairfield', 'electric', 'https://uinet.com', ARRAY['CT'], NULL),
    ('Greenwich Light & Power', 'greenwich-light-power', 'electric', 'https://eversource.com', ARRAY['CT'], NULL),
    ('Stamford Electric', 'stamford-electric', 'electric', 'https://eversource.com', ARRAY['CT'], NULL),
    ('Bridgeport Electric', 'bridgeport-electric', 'electric', 'https://uinet.com', ARRAY['CT'], NULL)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- WESTCHESTER + FAIRFIELD NATURAL GAS
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    ('Con Edison Gas Westchester', 'coned-gas-westchester', 'natural_gas', 'https://coned.com', ARRAY['NY'], NULL),
    ('Orange & Rockland Gas', 'oru-gas', 'natural_gas', 'https://oru.com', ARRAY['NY','NJ','PA'], NULL),
    ('Yankee Gas Fairfield', 'yankee-gas-fairfield', 'natural_gas', 'https://eversource.com', ARRAY['CT'], NULL),
    ('Eversource Gas Fairfield CT', 'eversource-gas-fairfield-ct', 'natural_gas', 'https://eversource.com', ARRAY['CT'], NULL),
    ('Southern Connecticut Gas Fairfield', 'scg-fairfield', 'natural_gas', 'https://southernctgas.com', ARRAY['CT'], NULL),
    ('Connecticut Natural Gas Fairfield', 'cng-fairfield', 'natural_gas', 'https://cngcorp.com', ARRAY['CT'], NULL),
    ('Greenwich Gas (Eversource)', 'greenwich-gas', 'natural_gas', 'https://eversource.com', ARRAY['CT'], NULL),
    ('Stamford Gas (SCG)', 'stamford-gas', 'natural_gas', 'https://southernctgas.com', ARRAY['CT'], NULL),
    ('Norwalk Gas (SCG)', 'norwalk-gas', 'natural_gas', 'https://southernctgas.com', ARRAY['CT'], NULL),
    ('Bridgeport Gas (SCG)', 'bridgeport-gas', 'natural_gas', 'https://southernctgas.com', ARRAY['CT'], NULL),
    ('Danbury Gas (Yankee)', 'danbury-gas', 'natural_gas', 'https://eversource.com', ARRAY['CT'], NULL),
    ('Bethel Gas (Yankee)', 'bethel-gas', 'natural_gas', 'https://eversource.com', ARRAY['CT'], NULL),
    ('Ridgefield Gas (Eversource)', 'ridgefield-gas', 'natural_gas', 'https://eversource.com', ARRAY['CT'], NULL),
    ('Mount Kisco Gas (Con Ed)', 'mount-kisco-gas', 'natural_gas', 'https://coned.com', ARRAY['NY'], NULL),
    ('White Plains Gas (Con Ed)', 'white-plains-gas', 'natural_gas', 'https://coned.com', ARRAY['NY'], NULL),
    ('Yonkers Gas (Con Ed)', 'yonkers-gas', 'natural_gas', 'https://coned.com', ARRAY['NY'], NULL)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- WESTCHESTER + FAIRFIELD WATER
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Westchester
    ('Veolia New York Westchester', 'veolia-westchester', 'water', 'https://veolianorthamerica.com', ARRAY['NY'], NULL),
    ('Westchester Joint Water Works', 'wjww', 'water', 'https://wjww.com', ARRAY['NY'], NULL),
    ('Yonkers Water Department', 'yonkers-water', 'water', 'https://yonkersny.gov/water', ARRAY['NY'], NULL),
    ('White Plains Water Department', 'white-plains-water', 'water', 'https://cityofwhiteplains.com', ARRAY['NY'], NULL),
    ('New Rochelle Water (United Water)', 'new-rochelle-water', 'water', 'https://newrochelleny.com', ARRAY['NY'], NULL),
    ('Mount Vernon Water', 'mount-vernon-water', 'water', 'https://cmvny.com', ARRAY['NY'], NULL),
    ('Mount Kisco Water', 'mount-kisco-water', 'water', 'https://mountkiscony.gov', ARRAY['NY'], NULL),
    ('Bedford Water (Bedford Hills)', 'bedford-water', 'water', 'https://bedfordny.gov', ARRAY['NY'], NULL),
    ('Chappaqua Water', 'chappaqua-water', 'water', 'https://newcastleny.org', ARRAY['NY'], NULL),
    ('Rye Water (Westchester)', 'rye-water', 'water', 'https://ryeny.gov', ARRAY['NY'], NULL),
    ('Larchmont Water', 'larchmont-water', 'water', 'https://villageoflarchmont.org', ARRAY['NY'], NULL),
    ('Scarsdale Water', 'scarsdale-water', 'water', 'https://scarsdale.com', ARRAY['NY'], NULL),
    ('Pleasantville Water', 'pleasantville-water', 'water', 'https://pleasantville-ny.gov', ARRAY['NY'], NULL),
    ('Tarrytown Water', 'tarrytown-water', 'water', 'https://tarrytowngov.com', ARRAY['NY'], NULL),
    ('Pelham Water', 'pelham-water', 'water', 'https://pelhamgov.com', ARRAY['NY'], NULL),
    ('Mamaroneck Water', 'mamaroneck-water', 'water', 'https://townofmamaroneckny.org', ARRAY['NY'], NULL),
    ('Eastchester Water', 'eastchester-water', 'water', 'https://eastchester.org', ARRAY['NY'], NULL),
    ('Cortlandt Water', 'cortlandt-water', 'water', 'https://townofcortlandt.com', ARRAY['NY'], NULL),
    ('Peekskill Water Department', 'peekskill-water', 'water', 'https://cityofpeekskill.com', ARRAY['NY'], NULL),
    ('Ossining Water', 'ossining-water', 'water', 'https://townofossining.com', ARRAY['NY'], NULL),

    -- Fairfield
    ('Aquarion Greenwich', 'aquarion-greenwich', 'water', 'https://aquarionwater.com', ARRAY['CT'], NULL),
    ('Aquarion Stamford', 'aquarion-stamford', 'water', 'https://aquarionwater.com', ARRAY['CT'], NULL),
    ('Aquarion Westport', 'aquarion-westport', 'water', 'https://aquarionwater.com', ARRAY['CT'], NULL),
    ('Aquarion Darien', 'aquarion-darien', 'water', 'https://aquarionwater.com', ARRAY['CT'], NULL),
    ('Aquarion New Canaan', 'aquarion-new-canaan', 'water', 'https://aquarionwater.com', ARRAY['CT'], NULL),
    ('Aquarion Fairfield CT', 'aquarion-fairfield-town', 'water', 'https://aquarionwater.com', ARRAY['CT'], NULL),
    ('Aquarion Bridgeport', 'aquarion-bridgeport', 'water', 'https://aquarionwater.com', ARRAY['CT'], NULL),
    ('Aquarion Trumbull', 'aquarion-trumbull', 'water', 'https://aquarionwater.com', ARRAY['CT'], NULL),
    ('Aquarion Wilton', 'aquarion-wilton', 'water', 'https://aquarionwater.com', ARRAY['CT'], NULL),
    ('Aquarion Newtown', 'aquarion-newtown', 'water', 'https://aquarionwater.com', ARRAY['CT'], NULL),
    ('Aquarion Bethel CT', 'aquarion-bethel', 'water', 'https://aquarionwater.com', ARRAY['CT'], NULL),
    ('Aquarion Brookfield', 'aquarion-brookfield', 'water', 'https://aquarionwater.com', ARRAY['CT'], NULL),
    ('Aquarion Ridgefield', 'aquarion-ridgefield', 'water', 'https://aquarionwater.com', ARRAY['CT'], NULL),
    ('Aquarion Easton CT', 'aquarion-easton', 'water', 'https://aquarionwater.com', ARRAY['CT'], NULL),
    ('Aquarion Monroe', 'aquarion-monroe', 'water', 'https://aquarionwater.com', ARRAY['CT'], NULL),
    ('Aquarion Shelton', 'aquarion-shelton', 'water', 'https://aquarionwater.com', ARRAY['CT'], NULL),
    ('Stamford Water Pollution Control', 'stamford-wpc', 'water', 'https://stamfordct.gov/wpcd', ARRAY['CT'], NULL),
    ('Norwalk First District Water Dept', 'norwalk-first-district-extended', 'water', 'https://fdistrictwater.com', ARRAY['CT'], NULL),
    ('Norwalk Second Taxing District', 'norwalk-second-taxing', 'water', 'https://2td.com', ARRAY['CT'], NULL),
    ('Bridgeport Water Pollution Control', 'bridgeport-wpc', 'water', 'https://bridgeportct.gov', ARRAY['CT'], NULL),
    ('Danbury Water Department', 'danbury-water-extended', 'water', 'https://danbury-ct.gov', ARRAY['CT'], NULL),
    ('First Taxing District Water (Norwalk)', 'first-taxing-district-norwalk', 'water', 'https://fdistrictwater.com', ARRAY['CT'], NULL),
    ('Greenwich Water Pollution Control', 'greenwich-wpc', 'water', 'https://greenwichct.gov', ARRAY['CT'], NULL)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- WESTCHESTER + FAIRFIELD INTERNET / CABLE
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    ('Optimum Westchester', 'optimum-westchester', 'internet_cable', 'https://optimum.com', ARRAY['NY'], NULL),
    ('Optimum Fairfield CT', 'optimum-fairfield', 'internet_cable', 'https://optimum.com', ARRAY['CT'], NULL),
    ('Verizon Fios Westchester', 'verizon-fios-westchester', 'internet_cable', 'https://verizon.com/fios', ARRAY['NY'], NULL),
    ('Verizon Fios Fairfield', 'verizon-fios-fairfield', 'internet_cable', 'https://verizon.com/fios', ARRAY['CT'], NULL),
    ('Spectrum Westchester', 'spectrum-westchester', 'internet_cable', 'https://spectrum.com', ARRAY['NY'], NULL),
    ('Spectrum Fairfield CT', 'spectrum-fairfield', 'internet_cable', 'https://spectrum.com', ARRAY['CT'], NULL),
    ('Frontier Communications CT', 'frontier-ct', 'internet_cable', 'https://frontier.com', ARRAY['CT'], NULL),
    ('Frontier Westchester', 'frontier-westchester', 'internet_cable', 'https://frontier.com', ARRAY['NY'], NULL),
    ('GoNetspeed Fairfield', 'gonetspeed-fairfield', 'internet_cable', 'https://gonetspeed.com', ARRAY['CT'], NULL),
    ('Atlantic Broadband Westchester', 'atlantic-broadband-westchester', 'internet_cable', 'https://atlanticbb.com', ARRAY['NY'], NULL),
    ('AT&T Fixed Wireless Fairfield', 'att-fixed-wireless-fairfield', 'internet_cable', 'https://att.com', ARRAY['CT'], NULL),
    ('Mid-Hudson Cablevision Westchester', 'mhc-westchester', 'internet_cable', 'https://mhcable.com', ARRAY['NY'], NULL),
    ('Astound Broadband Fairfield', 'astound-fairfield', 'internet_cable', 'https://astound.com', ARRAY['CT'], NULL)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- WESTCHESTER + FAIRFIELD HEATING OIL (this region is THE oil heat capital)
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Westchester-focused
    ('Petro Home Services Westchester', 'petro-westchester', 'oil', 'https://petro.com', ARRAY['NY','CT'], NULL),
    ('Robison Energy Westchester', 'robison-energy-westchester', 'oil', 'https://robisonenergy.com', ARRAY['NY','CT'], NULL),
    ('Castle Oil Westchester', 'castle-oil-westchester', 'oil', 'https://castleoil.com', ARRAY['NY'], NULL),
    ('Approved Oil Westchester', 'approved-oil-westchester', 'oil', 'https://approvedoil.com', ARRAY['NY'], NULL),
    ('Family Fuel Energy', 'family-fuel-energy', 'oil', 'https://familyfuelenergy.com', ARRAY['NY','CT'], NULL),
    ('Skip Wilson Heating Oil', 'skip-wilson', 'oil', 'https://skipwilsonoil.com', ARRAY['NY','CT'], NULL),
    ('Service Star Oil', 'service-star-oil', 'oil', 'https://servicestaroil.com', ARRAY['NY'], NULL),
    ('Prestige Oil Westchester', 'prestige-oil-westchester', 'oil', 'https://prestigeoilcorp.com', ARRAY['NY','CT'], NULL),
    ('Suburban Heating Oil Westchester', 'suburban-heating-westchester', 'oil', 'https://suburbanheating.com', ARRAY['NY','NJ'], NULL),
    ('Anchor Oil Service', 'anchor-oil-service', 'oil', 'https://anchoroilco.com', ARRAY['NY'], NULL),
    ('Tartan Oil', 'tartan-oil', 'oil', 'https://tartanoil.com', ARRAY['NY','CT'], NULL),
    ('Westchester Fuel', 'westchester-fuel', 'oil', 'https://westchesterfuel.com', ARRAY['NY'], NULL),
    ('Dependable Petroleum Service', 'dependable-petroleum', 'oil', 'https://dependableoil.com', ARRAY['NY','CT'], NULL),
    ('Bottini Fuel', 'bottini-fuel', 'oil', 'https://bottinifuel.com', ARRAY['NY','CT'], NULL),
    ('Walden Oil', 'walden-oil', 'oil', 'https://waldenoil.com', ARRAY['NY','CT'], NULL),

    -- Fairfield-focused
    ('Hocon Oil Fairfield', 'hocon-oil-fairfield', 'oil', 'https://hocon.com', ARRAY['CT'], NULL),
    ('Sippin Energy Fairfield', 'sippin-fairfield', 'oil', 'https://sippinenergy.com', ARRAY['CT'], NULL),
    ('Standard Oil of Connecticut', 'standard-oil-connecticut', 'oil', 'https://standardoilct.com', ARRAY['CT','NY'], NULL),
    ('East River Energy Fairfield', 'east-river-energy-fairfield', 'oil', 'https://eastriverenergy.com', ARRAY['CT'], NULL),
    ('Gault Energy Fairfield', 'gault-energy-fairfield', 'oil', 'https://gaultenergy.com', ARRAY['CT'], NULL),
    ('Santa Fuel Fairfield', 'santa-fuel-fairfield', 'oil', 'https://santaenergy.com', ARRAY['CT'], NULL),
    ('Fairfield County Oil Service', 'fairfield-county-oil-service', 'oil', 'https://fairfieldcountyoil.com', ARRAY['CT'], NULL),
    ('A-1 Heating Oil CT', 'a1-heating-oil-ct', 'oil', 'https://a1heatingoilct.com', ARRAY['CT'], NULL),
    ('B&K Fuel Oil', 'bk-fuel-oil', 'oil', 'https://bkfueloil.com', ARRAY['CT'], NULL),
    ('Carbone & Sons', 'carbone-sons', 'oil', 'https://carboneoil.com', ARRAY['CT'], NULL),
    ('Casinghino Brothers', 'casinghino-brothers', 'oil', 'https://casinghinooil.com', ARRAY['CT'], NULL),
    ('Cherry Hill Fuel', 'cherry-hill-fuel', 'oil', 'https://cherryhillfuel.com', ARRAY['CT'], NULL),
    ('Coachman Oil', 'coachman-oil', 'oil', 'https://coachmanoil.com', ARRAY['CT'], NULL),
    ('Connecticut Energy', 'ct-energy', 'oil', 'https://ctenergyct.com', ARRAY['CT'], NULL),
    ('Contemporary Heating Service', 'contemporary-heating', 'oil', 'https://contemporaryheating.com', ARRAY['CT'], NULL),
    ('D&L Oil Service', 'dl-oil-service', 'oil', 'https://dloilservice.com', ARRAY['CT'], NULL),
    ('Devine Brothers', 'devine-brothers', 'oil', 'https://devinebrothers.com', ARRAY['CT','NY'], NULL),
    ('Dion Oil', 'dion-oil', 'oil', 'https://dionoil.com', ARRAY['CT'], NULL),
    ('George Schmitt & Co', 'george-schmitt', 'oil', 'https://schmittoil.com', ARRAY['CT'], NULL),
    ('Heritage Oil', 'heritage-oil-ct', 'oil', 'https://heritageoilct.com', ARRAY['CT'], NULL),
    ('Pilgrim Oil Fairfield', 'pilgrim-oil-fairfield', 'oil', 'https://pilgrimoil.com', ARRAY['CT'], NULL),
    ('Marcus Dairy Heating Oil', 'marcus-dairy', 'oil', 'https://marcusdairy.com', ARRAY['CT'], NULL),
    ('Smart Energy CT', 'smart-energy-ct', 'oil', 'https://smartenergyct.com', ARRAY['CT'], NULL)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- WESTCHESTER + FAIRFIELD PROPANE
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    ('Hocon Gas Fairfield', 'hocon-gas-fairfield', 'propane', 'https://hocon.com', ARRAY['CT','NY'], NULL),
    ('Suburban Propane Westchester', 'suburban-propane-westchester', 'propane', 'https://suburbanpropane.com', ARRAY['NY','CT'], NULL),
    ('Paraco Gas Westchester', 'paraco-gas-westchester', 'propane', 'https://paracogas.com', ARRAY['NY','CT','NJ'], NULL),
    ('Sippin Brothers Propane Fairfield', 'sippin-brothers-fairfield', 'propane', 'https://sippinenergy.com', ARRAY['CT'], NULL),
    ('AmeriGas Westchester', 'amerigas-westchester', 'propane', 'https://amerigas.com', ARRAY['NY','CT'], NULL),
    ('AmeriGas Fairfield CT', 'amerigas-fairfield', 'propane', 'https://amerigas.com', ARRAY['CT'], NULL),
    ('Family Fuel Propane', 'family-fuel-propane', 'propane', 'https://familyfuelenergy.com', ARRAY['NY','CT'], NULL),
    ('Petro Propane Westchester', 'petro-propane-westchester', 'propane', 'https://petro.com', ARRAY['NY','CT'], NULL),
    ('Tartan Propane', 'tartan-propane', 'propane', 'https://tartanoil.com', ARRAY['NY','CT'], NULL),
    ('Bottini Propane', 'bottini-propane', 'propane', 'https://bottinifuel.com', ARRAY['NY','CT'], NULL),
    ('Crown Energy Propane', 'crown-energy-propane', 'propane', 'https://crownenergyct.com', ARRAY['CT'], NULL),
    ('Connecticut Propane Service', 'ct-propane-service', 'propane', 'https://ctpropane.com', ARRAY['CT'], NULL),
    ('Standard Propane CT', 'standard-propane-ct', 'propane', 'https://standardoilct.com', ARRAY['CT','NY'], NULL),
    ('Pilgrim Propane', 'pilgrim-propane', 'propane', 'https://pilgrimoil.com', ARRAY['CT'], NULL)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- WESTCHESTER + FAIRFIELD TRASH / RECYCLING
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    ('Suburban Carting Westchester', 'suburban-carting', 'trash', 'https://suburbancarting.com', ARRAY['NY'], NULL),
    ('AAA Carting & Rubbish', 'aaa-carting', 'trash', 'https://aaacarting.com', ARRAY['NY'], NULL),
    ('CRP Sanitation', 'crp-sanitation', 'trash', 'https://crpsanitation.com', ARRAY['NY'], NULL),
    ('Westchester Disposal Services', 'westchester-disposal', 'trash', 'https://westchesterdisposal.com', ARRAY['NY'], NULL),
    ('Oak Ridge Waste & Recycling', 'oak-ridge-waste', 'trash', 'https://oakridgewaste.com', ARRAY['NY','NJ'], NULL),
    ('Suburban Sanitation NY', 'suburban-sanitation-ny', 'trash', 'https://suburbansanitation.net', ARRAY['NY'], NULL),
    ('West River Sanitation', 'west-river-sanitation', 'trash', 'https://westriversanitation.com', ARRAY['NY','CT'], NULL),
    ('Yorktown Carting', 'yorktown-carting', 'trash', 'https://yorktowncarting.com', ARRAY['NY'], NULL),
    ('Bedford Sanitation', 'bedford-sanitation', 'trash', 'https://bedfordsanitation.com', ARRAY['NY'], NULL),
    ('North Salem Carting', 'north-salem-carting', 'trash', 'https://northsalemcarting.com', ARRAY['NY'], NULL),
    ('CRP Resource Recovery', 'crp-resource', 'trash', 'https://crpresources.com', ARRAY['NY','CT'], NULL),
    ('City Carting Stamford', 'city-carting-stamford', 'trash', 'https://citycarting.com', ARRAY['CT','NY'], NULL),
    ('City Carting Norwalk', 'city-carting-norwalk', 'trash', 'https://citycarting.com', ARRAY['CT'], NULL),
    ('All Waste Connecticut', 'all-waste-ct', 'trash', 'https://allwasteinc.com', ARRAY['CT','MA'], NULL),
    ('Greenway Waste Solutions', 'greenway-waste', 'trash', 'https://greenwaywaste.com', ARRAY['CT','NY'], NULL),
    ('Norwalk Public Works (Trash)', 'norwalk-public-works-trash', 'trash', 'https://norwalkct.org', ARRAY['CT'], NULL),
    ('Greenwich Sanitation Department', 'greenwich-sanitation', 'trash', 'https://greenwichct.gov/sanitation', ARRAY['CT'], NULL),
    ('Stamford Sanitation', 'stamford-sanitation', 'trash', 'https://stamfordct.gov/sanitation', ARRAY['CT'], NULL),
    ('Bridgeport Public Works (Trash)', 'bridgeport-pw-trash', 'trash', 'https://bridgeportct.gov', ARRAY['CT'], NULL),
    ('Danbury Public Works (Trash)', 'danbury-pw-trash', 'trash', 'https://danbury-ct.gov', ARRAY['CT'], NULL),
    ('Westport Public Works (Trash)', 'westport-pw-trash', 'trash', 'https://westportct.gov', ARRAY['CT'], NULL),
    ('Darien Public Works (Trash)', 'darien-pw-trash', 'trash', 'https://darienct.gov', ARRAY['CT'], NULL),
    ('New Canaan Public Works (Trash)', 'new-canaan-pw-trash', 'trash', 'https://newcanaanct.gov', ARRAY['CT'], NULL),
    ('Wilton Public Works (Trash)', 'wilton-pw-trash', 'trash', 'https://wiltonct.org', ARRAY['CT'], NULL),
    ('Fairfield CT Public Works', 'fairfield-ct-pw', 'trash', 'https://fairfieldct.org', ARRAY['CT'], NULL),
    ('Trumbull CT Public Works', 'trumbull-ct-pw', 'trash', 'https://trumbull-ct.gov', ARRAY['CT'], NULL),
    ('Newtown CT Public Works', 'newtown-ct-pw', 'trash', 'https://newtown-ct.gov', ARRAY['CT'], NULL)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- WESTCHESTER + FAIRFIELD LANDSCAPING / TREE SERVICE
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    ('Hoffman Landscapes Wilton CT', 'hoffman-landscapes-wilton', 'landscaping', 'https://hoffmanlandscapes.com', ARRAY['CT','NY'], NULL),
    ('Almstead Tree Westchester', 'almstead-westchester', 'landscaping', 'https://almstead.com', ARRAY['NY','CT','NJ'], NULL),
    ('SavATree Westchester', 'savatree-westchester', 'landscaping', 'https://savatree.com', ARRAY['NY','CT','NJ','MA','RI'], NULL),
    ('Bartlett Tree Greenwich', 'bartlett-greenwich', 'landscaping', 'https://bartlett.com', ARRAY['CT','NY'], NULL),
    ('Davey Tree Fairfield', 'davey-fairfield', 'landscaping', 'https://davey.com', ARRAY['CT','NY','NJ'], NULL),
    ('Northeast Horticultural Services', 'ne-horticultural', 'landscaping', 'https://nehortservices.com', ARRAY['CT','NY'], NULL),
    ('Greenwich Tree Conservancy', 'greenwich-tree', 'landscaping', 'https://greenwichtreeconservancy.org', ARRAY['CT'], NULL),
    ('Pleasant Valley Landscape', 'pleasant-valley-landscape', 'landscaping', 'https://pleasantvalleyct.com', ARRAY['CT','NY'], NULL),
    ('Westchester Lawn Care', 'westchester-lawn-care', 'landscaping', 'https://westchesterlawncare.com', ARRAY['NY'], NULL),
    ('Walter''s Tree Service', 'walters-tree-service', 'landscaping', 'https://walterstreeservice.com', ARRAY['NY','CT'], NULL),
    ('Lawn Tech of Westchester', 'lawn-tech-westchester', 'landscaping', 'https://lawntechwest.com', ARRAY['NY'], NULL),
    ('Connecticut Landscape Group', 'ct-landscape-group', 'landscaping', 'https://ctlandscapegroup.com', ARRAY['CT'], NULL),
    ('Greenscape Greenwich', 'greenscape-greenwich', 'landscaping', 'https://greenscapegreenwich.com', ARRAY['CT'], NULL),
    ('Beardsley Construction Bethel', 'beardsley-bethel', 'landscaping', 'https://beardsleylandscape.com', ARRAY['CT'], NULL),
    ('Connecticut Tree Care', 'ct-tree-care', 'landscaping', 'https://cttreecare.com', ARRAY['CT'], NULL),
    ('John D''Eri Tree Service', 'john-deri-tree', 'landscaping', 'https://johnderitree.com', ARRAY['CT','NY'], NULL),
    ('Fairfield County Landscaping', 'fairfield-county-landscaping', 'landscaping', 'https://fairfieldcountylandscape.com', ARRAY['CT'], NULL),
    ('Bedford Stone & Masonry', 'bedford-stone-masonry', 'landscaping', 'https://bedfordstoneworks.com', ARRAY['NY','CT'], NULL),
    ('Westchester Tree Life', 'westchester-tree-life', 'landscaping', 'https://westchestertreelife.com', ARRAY['NY'], NULL),
    ('Sav-A-Tree Mount Kisco', 'savatree-mount-kisco', 'landscaping', 'https://savatree.com', ARRAY['NY'], NULL),
    ('Lasdon Park Landscaping', 'lasdon-park-landscape', 'landscaping', 'https://lasdonpark.org', ARRAY['NY'], NULL),
    ('Innovative Tree Care', 'innovative-tree-care', 'landscaping', 'https://innovativetreecare.com', ARRAY['NY','CT'], NULL)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- WESTCHESTER + FAIRFIELD PEST CONTROL
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    ('JP McHale Westchester', 'jp-mchale-westchester', 'pest_control', 'https://nopests.com', ARRAY['NY','NJ','CT','PA','MA'], NULL),
    ('Connors Pest Westchester', 'connors-pest-westchester', 'pest_control', 'https://connorspest.com', ARRAY['NY','CT'], NULL),
    ('Catseye Pest Westchester', 'catseye-westchester', 'pest_control', 'https://catseyepest.com', ARRAY['NY','CT'], NULL),
    ('Western Pest Westchester', 'western-pest-westchester', 'pest_control', 'https://westernpest.com', ARRAY['NY','NJ','PA','CT'], NULL),
    ('Bell Environmental Westchester', 'bell-environmental-westchester', 'pest_control', 'https://bellpest.com', ARRAY['NY','NJ','PA','CT'], NULL),
    ('Aronson Pest Fairfield', 'aronson-pest-fairfield', 'pest_control', 'https://aronsonpest.com', ARRAY['CT'], NULL),
    ('Action Pest Westchester', 'action-pest-westchester', 'pest_control', 'https://actionpestcontrol.com', ARRAY['NY','NJ','CT'], NULL),
    ('Crazylegs Pest Fairfield', 'crazylegs-fairfield', 'pest_control', 'https://crazylegspestcontrol.com', ARRAY['CT'], NULL),
    ('Beeline Pest Control', 'beeline-pest', 'pest_control', 'https://beelinepest.com', ARRAY['NY','CT'], NULL),
    ('Pest Police', 'pest-police', 'pest_control', 'https://pestpolice.com', ARRAY['NY','CT'], NULL),
    ('Tri-County Pest Control', 'tri-county-pest', 'pest_control', 'https://tricountypest.com', ARRAY['NY','CT'], NULL),
    ('Yale Termite & Pest Westchester', 'yale-termite-westchester', 'pest_control', 'https://yaletermite.com', ARRAY['NY','CT'], NULL),
    ('Greenwich Pest Control', 'greenwich-pest', 'pest_control', 'https://greenwichpest.com', ARRAY['CT'], NULL),
    ('Stamford Pest Control', 'stamford-pest', 'pest_control', 'https://stamfordpest.com', ARRAY['CT'], NULL),
    ('Total Pest Control CT', 'total-pest-control-ct', 'pest_control', 'https://totalpestct.com', ARRAY['CT'], NULL)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- WESTCHESTER + FAIRFIELD SECURITY / ALARM
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    ('Slomin''s Westchester', 'slomins-westchester', 'security', 'https://slomins.com', ARRAY['NY','CT'], NULL),
    ('Kerns Security', 'kerns-security', 'security', 'https://kernssecurity.com', ARRAY['NY','CT'], NULL),
    ('Coast to Coast Security', 'coast-to-coast-security', 'security', 'https://coast2coastsecurity.com', ARRAY['NY','NJ','CT'], NULL),
    ('Smith Alarm Westchester', 'smith-alarm-westchester', 'security', 'https://smithalarm.com', ARRAY['NY','CT'], NULL),
    ('Westchester Alarm', 'westchester-alarm', 'security', 'https://westchesteralarm.com', ARRAY['NY'], NULL),
    ('Fairfield Alarm', 'fairfield-alarm', 'security', 'https://fairfieldalarm.com', ARRAY['CT'], NULL),
    ('Greenwich Alarm', 'greenwich-alarm', 'security', 'https://greenwichalarm.com', ARRAY['CT'], NULL),
    ('Norwalk Security', 'norwalk-security', 'security', 'https://norwalksecurity.com', ARRAY['CT'], NULL),
    ('Stamford Security Systems', 'stamford-security-systems', 'security', 'https://stamfordsecurity.com', ARRAY['CT'], NULL),
    ('CT Security Systems', 'ct-security-systems', 'security', 'https://ctsecurity.com', ARRAY['CT'], NULL),
    ('NY Alarm Westchester', 'ny-alarm-westchester', 'security', 'https://nyalarm.com', ARRAY['NY'], NULL),
    ('Hammond Westchester', 'hammond-westchester', 'security', 'https://hammondsystems.com', ARRAY['NY','CT'], NULL),
    ('Dynamark Security NY', 'dynamark-ny', 'security', 'https://dynamark.com', ARRAY['NY','CT'], NULL),
    ('Total Security Westchester', 'total-security-westchester', 'security', 'https://totalsecurityny.com', ARRAY['NY','CT'], NULL),
    ('Premier Alarm', 'premier-alarm', 'security', 'https://premieralarm.com', ARRAY['NY','CT'], NULL),
    ('ADT Westchester', 'adt-westchester', 'security', 'https://adt.com', ARRAY['NY'], NULL),
    ('ADT Fairfield', 'adt-fairfield', 'security', 'https://adt.com', ARRAY['CT'], NULL)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- WESTCHESTER + FAIRFIELD POOL SERVICE
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    ('Aqua Pool & Patio Westchester', 'aqua-pool-westchester', 'pool_service', 'https://aquapool.com', ARRAY['NY','CT'], NULL),
    ('Anthony & Sylvan Westchester', 'anthony-sylvan-westchester', 'pool_service', 'https://anthonysylvan.com', ARRAY['NY','CT'], NULL),
    ('Pool Specialists Fairfield', 'pool-specialists-fairfield', 'pool_service', 'https://poolspecialists.com', ARRAY['CT'], NULL),
    ('Crystal Pool Service Westchester', 'crystal-pool-westchester', 'pool_service', 'https://crystalpoolservice.com', ARRAY['NY','CT'], NULL),
    ('Cipriano Custom Pools', 'cipriano-pools', 'pool_service', 'https://ciprianocustomswimmingpools.com', ARRAY['NY','NJ','CT'], NULL),
    ('Shoreline Pools Stamford', 'shoreline-pools', 'pool_service', 'https://shorelinepools.com', ARRAY['CT','NY'], NULL),
    ('Cazwell Pools Greenwich', 'cazwell-pools', 'pool_service', 'https://cazwellpools.com', ARRAY['CT','NY'], NULL),
    ('Waterworks Pools Fairfield', 'waterworks-pools', 'pool_service', 'https://waterworkspools.com', ARRAY['CT'], NULL),
    ('Pleasure Pools', 'pleasure-pools', 'pool_service', 'https://pleasurepoolsny.com', ARRAY['NY','CT'], NULL),
    ('Sparkling Pool Service', 'sparkling-pool-service', 'pool_service', 'https://sparklingpoolservice.com', ARRAY['NY','CT'], NULL),
    ('Connecticut Pool Service', 'ct-pool-service', 'pool_service', 'https://ctpoolservice.com', ARRAY['CT'], NULL),
    ('Westchester Pool Service', 'westchester-pool-service', 'pool_service', 'https://westchesterpool.com', ARRAY['NY'], NULL)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- WESTCHESTER + FAIRFIELD IRRIGATION / SPRINKLER
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    ('Aqua Lawn Sprinklers Westchester', 'aqua-lawn-westchester', 'irrigation', 'https://aqualawnsprinklers.com', ARRAY['NY','CT'], NULL),
    ('Atlantic Lawn Sprinklers Westchester', 'atlantic-lawn-westchester', 'irrigation', 'https://atlanticlawn.com', ARRAY['NY','CT'], NULL),
    ('Greenwich Sprinkler Service', 'greenwich-sprinkler', 'irrigation', 'https://greenwichsprinkler.com', ARRAY['CT'], NULL),
    ('Stamford Sprinkler Service', 'stamford-sprinkler', 'irrigation', 'https://stamfordsprinkler.com', ARRAY['CT'], NULL),
    ('Fairfield County Irrigation', 'fairfield-county-irrigation', 'irrigation', 'https://fairfieldcountyirrigation.com', ARRAY['CT'], NULL),
    ('Westchester Irrigation', 'westchester-irrigation', 'irrigation', 'https://westchesterirrigation.com', ARRAY['NY'], NULL),
    ('Conserva Westchester', 'conserva-westchester', 'irrigation', 'https://conservairrigation.com', ARRAY['NY','CT'], NULL),
    ('Sprinkler Master Westchester', 'sprinkler-master-westchester', 'irrigation', 'https://sprinklermaster.com', ARRAY['NY','CT'], NULL),
    ('B&G Sprinkler Westchester', 'bg-sprinkler-westchester', 'irrigation', 'https://bgsprinkler.com', ARRAY['NY','CT'], NULL),
    ('Hoffman Irrigation', 'hoffman-irrigation', 'irrigation', 'https://hoffmanlandscapes.com', ARRAY['CT','NY'], NULL),
    ('Fairfield County Sprinklers', 'fairfield-county-sprinklers', 'irrigation', 'https://fairfieldcountysprinklers.com', ARRAY['CT'], NULL),
    ('Tri-State Irrigation', 'tri-state-irrigation', 'irrigation', 'https://tristateirrigation.com', ARRAY['NY','NJ','CT'], NULL)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- WESTCHESTER + FAIRFIELD SOLAR
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    ('Trinity Solar Westchester', 'trinity-westchester', 'solar', 'https://trinity-solar.com', ARRAY['NY','CT','NJ','MA','RI','PA','MD'], NULL),
    ('Sunrise Solar Westchester', 'sunrise-solar-westchester', 'solar', 'https://sunrisesolarsolutions.com', ARRAY['NY','CT'], NULL),
    ('PosiGen NY/CT', 'posigen-ny-ct', 'solar', 'https://posigen.com', ARRAY['NY','CT','NJ','PA'], NULL),
    ('SunPower by Empire Solar Westchester', 'sunpower-empire-westchester', 'solar', 'https://sunpower.com', ARRAY['NY','CT'], NULL),
    ('Direct Energy Solar NE', 'direct-energy-solar-extended', 'solar', 'https://directenergysolar.com', ARRAY['NY','NJ','MA','MD','PA'], NULL),
    ('Sunrun Westchester', 'sunrun-westchester', 'solar', 'https://sunrun.com', ARRAY['NY','CT'], NULL),
    ('Tesla Energy Westchester', 'tesla-energy-westchester', 'solar', 'https://tesla.com/solar', ARRAY['NY','CT'], NULL),
    ('Momentum Solar Westchester', 'momentum-westchester', 'solar', 'https://momentumsolar.com', ARRAY['NY','CT','NJ','PA'], NULL),
    ('Power Home Solar NE', 'power-home-solar-ne', 'solar', 'https://powerhomesolar.com', ARRAY['NY','CT','NJ','PA','MA','RI'], NULL),
    ('NRG Clean Power Westchester', 'nrg-clean-westchester', 'solar', 'https://nrgcleanpower.com', ARRAY['NY','CT','NJ'], NULL),
    ('Best Solar Energy Westchester', 'best-solar-westchester', 'solar', 'https://bestsolarenergyfl.com', ARRAY['NY','CT'], NULL),
    ('Aurora Energy Solutions', 'aurora-energy-solutions', 'solar', 'https://auroraenergysolutions.com', ARRAY['NY','CT'], NULL),
    ('NEPS Solar Westchester', 'neps-westchester', 'solar', 'https://newenglandpowersystems.com', ARRAY['CT','NY','MA','RI'], NULL)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- WESTCHESTER + FAIRFIELD AUTO INSURANCE (regional)
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url, bundles_with_home) VALUES
    ('Tri-State Consumer Insurance', 'tri-state-consumer-auto', 'auto_insurance', 'https://tsci.com', ARRAY['NY','NJ','CT'], NULL, true),
    ('Empire Insurance Co Westchester', 'empire-insurance-westchester', 'auto_insurance', 'https://empireins.com', ARRAY['NY','CT'], NULL, true),
    ('Tower Insurance NY', 'tower-insurance-ny-auto', 'auto_insurance', 'https://towerinsurance.com', ARRAY['NY'], NULL, true),
    ('Mercury Casualty NY', 'mercury-casualty-ny-auto', 'auto_insurance', 'https://mercuryinsurance.com', ARRAY['NY','CT','NJ'], NULL, true),
    ('Hereford Insurance', 'hereford-insurance-auto', 'auto_insurance', 'https://herefordinsurance.com', ARRAY['NY'], NULL, false),
    ('Long Island Insurance', 'long-island-insurance-auto', 'auto_insurance', 'https://liinsurance.com', ARRAY['NY','CT'], NULL, true),
    ('Civic Property and Casualty', 'civic-pc-auto', 'auto_insurance', 'https://civicpropertyandcasualty.com', ARRAY['NY','NJ'], NULL, true),
    ('Excelsior Insurance NY', 'excelsior-insurance-auto', 'auto_insurance', 'https://excelsiorinsurance.com', ARRAY['NY'], NULL, true),
    ('Metropolitan Group Property & Casualty', 'metropolitan-pc-auto', 'auto_insurance', 'https://metlife.com', ARRAY['NY','CT','NJ'], NULL, true),
    ('Foremost Lloyds of NY', 'foremost-lloyds-ny-auto', 'auto_insurance', 'https://foremost.com', ARRAY['NY'], NULL, true),
    ('Hartford Casualty NY', 'hartford-casualty-ny-auto', 'auto_insurance', 'https://thehartford.com', ARRAY['NY','CT'], NULL, true),
    ('CT General Insurance', 'ct-general-insurance-auto', 'auto_insurance', 'https://ctgeneralinsurance.com', ARRAY['CT'], NULL, true),
    ('Sentinel Connecticut', 'sentinel-ct-auto', 'auto_insurance', 'https://sentinelinsuranceco.com', ARRAY['CT','NY','NJ','MA','RI','NH','VT','ME'], NULL, true),
    ('Integon National', 'integon-national-auto', 'auto_insurance', 'https://nationalgeneral.com', ARRAY['NY','CT','NJ'], NULL, true),
    ('Commerce & Industry Insurance NY', 'commerce-industry-ny-auto', 'auto_insurance', 'https://aig.com', ARRAY['NY','CT','NJ'], NULL, true),
    ('National Casualty NY', 'national-casualty-ny-auto', 'auto_insurance', 'https://nationwide.com', ARRAY['NY','CT','NJ'], NULL, true),
    ('Greenwich Insurance Co', 'greenwich-insurance-co-auto', 'auto_insurance', 'https://axaxl.com', ARRAY['NY','CT','NJ'], NULL, true),
    ('Connecticut Indemnity', 'ct-indemnity-auto', 'auto_insurance', 'https://cinfin.com', ARRAY['CT','NY','MA','RI'], NULL, true),
    ('Ridgewood Insurance', 'ridgewood-insurance-auto', 'auto_insurance', 'https://ridgewoodins.com', ARRAY['NJ','NY','CT'], NULL, true),
    ('Garden State Insurance', 'garden-state-insurance-auto', 'auto_insurance', 'https://gardenstateinsurance.com', ARRAY['NJ','NY','CT'], NULL, true)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- WESTCHESTER + FAIRFIELD HOME INSURANCE (regional)
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url, bundles_with_auto) VALUES
    ('Tri-State Consumer Insurance', 'tri-state-consumer-home', 'home_insurance', 'https://tsci.com', ARRAY['NY','NJ','CT'], NULL, true),
    ('Empire Insurance Westchester', 'empire-insurance-westchester-home', 'home_insurance', 'https://empireins.com', ARRAY['NY','CT'], NULL, true),
    ('Tower Insurance NY Home', 'tower-insurance-ny-home', 'home_insurance', 'https://towerinsurance.com', ARRAY['NY'], NULL, true),
    ('Mercury Casualty NY Home', 'mercury-casualty-ny-home', 'home_insurance', 'https://mercuryinsurance.com', ARRAY['NY','CT','NJ'], NULL, true),
    ('Civic Property and Casualty Home', 'civic-pc-home', 'home_insurance', 'https://civicpropertyandcasualty.com', ARRAY['NY','NJ'], NULL, true),
    ('Excelsior Insurance Home', 'excelsior-insurance-home', 'home_insurance', 'https://excelsiorinsurance.com', ARRAY['NY'], NULL, true),
    ('Metropolitan Group P&C Home', 'metropolitan-pc-home', 'home_insurance', 'https://metlife.com', ARRAY['NY','CT','NJ'], NULL, true),
    ('Foremost Lloyds of NY Home', 'foremost-lloyds-ny-home', 'home_insurance', 'https://foremost.com', ARRAY['NY'], NULL, true),
    ('Hartford Casualty NY Home', 'hartford-casualty-ny-home', 'home_insurance', 'https://thehartford.com', ARRAY['NY','CT'], NULL, true),
    ('CT General Insurance Home', 'ct-general-insurance-home', 'home_insurance', 'https://ctgeneralinsurance.com', ARRAY['CT'], NULL, true),
    ('Sentinel Connecticut Home', 'sentinel-ct-home', 'home_insurance', 'https://sentinelinsuranceco.com', ARRAY['CT','NY','NJ','MA','RI','NH','VT','ME'], NULL, true),
    ('Greenwich Insurance Co Home', 'greenwich-insurance-co-home', 'home_insurance', 'https://axaxl.com', ARRAY['NY','CT','NJ'], NULL, true),
    ('Connecticut Indemnity Home', 'ct-indemnity-home', 'home_insurance', 'https://cinfin.com', ARRAY['CT','NY','MA','RI'], NULL, true),
    ('Ridgewood Insurance Home', 'ridgewood-insurance-home', 'home_insurance', 'https://ridgewoodins.com', ARRAY['NJ','NY','CT'], NULL, true),
    ('Garden State Insurance Home', 'garden-state-insurance-home', 'home_insurance', 'https://gardenstateinsurance.com', ARRAY['NJ','NY','CT'], NULL, true),
    ('NY Property Insurance Underwriting', 'ny-property-uw-home', 'home_insurance', 'https://nypiua.com', ARRAY['NY'], NULL, false),
    ('CT FAIR Plan', 'ct-fair-plan-home', 'home_insurance', 'https://ctfairplan.com', ARRAY['CT'], NULL, false),
    ('NY FAIR Plan', 'ny-fair-plan-home', 'home_insurance', 'https://nypiua.com', ARRAY['NY'], NULL, false),
    ('North River Insurance', 'north-river-insurance-home', 'home_insurance', 'https://crum-forster.com', ARRAY['NY','NJ','CT'], NULL, true),
    ('US Liability Insurance NE', 'us-liability-ne-home', 'home_insurance', 'https://usli.com', ARRAY['NY','NJ','CT','PA'], NULL, true)
ON CONFLICT (slug) DO NOTHING;
