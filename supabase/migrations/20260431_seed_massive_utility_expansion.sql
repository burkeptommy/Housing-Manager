-- Phase 18.5 utility expansion: comprehensive New England + national coverage
-- across every utility type. Goal: 100+ rows added across 13 categories with
-- emphasis on New England (Tom's primary market — CT/MA/NY/NJ/RI/NH/VT/ME).
--
-- Categories covered:
--   1. Electric utilities (NE-heavy, plus more national IOUs)
--   2. Natural gas (NE-heavy, plus more nationals)
--   3. Heating oil (NE is the heaviest oil heat market in US)
--   4. Propane (NE rural areas)
--   5. Water utilities (more municipal + private NE systems)
--   6. Internet / cable (more regional ISPs)
--   7. Trash & recycling (more NE haulers)
--   8. Landscaping (more NE companies)
--   9. Pest control (more NE companies)
--  10. Security (more NE alarm companies)
--  11. Solar (more NE installers)
--  12. Pool service (more NE pool companies)
--  13. Irrigation (more NE sprinkler companies)
--
-- All inserts use ON CONFLICT (slug) DO NOTHING.

-- ============================================================================
-- ELECTRIC UTILITIES (New England + more nationals)
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- NE-specific
    ('Eversource New Hampshire', 'eversource-nh', 'electric', 'https://eversource.com', ARRAY['NH'], NULL),
    ('Eversource Massachusetts', 'eversource-ma', 'electric', 'https://eversource.com', ARRAY['MA'], NULL),
    ('Eversource Connecticut', 'eversource-ct', 'electric', 'https://eversource.com', ARRAY['CT'], NULL),
    ('National Grid Massachusetts', 'national-grid-ma', 'electric', 'https://nationalgridus.com', ARRAY['MA'], NULL),
    ('National Grid Rhode Island', 'national-grid-ri', 'electric', 'https://nationalgridus.com', ARRAY['RI'], NULL),
    ('National Grid New York Upstate', 'national-grid-ny-upstate', 'electric', 'https://nationalgridus.com', ARRAY['NY'], NULL),
    ('National Grid Long Island', 'national-grid-li', 'electric', 'https://nationalgridus.com', ARRAY['NY'], NULL),
    ('Unitil New Hampshire', 'unitil-nh', 'electric', 'https://unitil.com', ARRAY['NH'], NULL),
    ('Unitil Massachusetts', 'unitil-ma', 'electric', 'https://unitil.com', ARRAY['MA'], NULL),
    ('Unitil Maine', 'unitil-me', 'electric', 'https://unitil.com', ARRAY['ME'], NULL),
    ('Liberty Utilities New Hampshire', 'liberty-utilities-nh', 'electric', 'https://liberty-energyutilities.com', ARRAY['NH'], NULL),
    ('Liberty Utilities Connecticut', 'liberty-utilities-ct', 'electric', 'https://liberty-energyutilities.com', ARRAY['CT'], NULL),
    ('Liberty Utilities Massachusetts', 'liberty-utilities-ma', 'electric', 'https://liberty-energyutilities.com', ARRAY['MA'], NULL),
    ('Versant Power (Maine)', 'versant-power', 'electric', 'https://versantpower.com', ARRAY['ME'], NULL),
    ('Bangor Hydro (Versant)', 'bangor-hydro', 'electric', 'https://versantpower.com', ARRAY['ME'], NULL),
    ('Maine Public Service', 'maine-public-service', 'electric', 'https://versantpower.com', ARRAY['ME'], NULL),
    ('Vermont Electric Cooperative', 'vermont-electric-coop', 'electric', 'https://vermontelectric.coop', ARRAY['VT'], NULL),
    ('Green Mountain Power', 'green-mountain-power', 'electric', 'https://greenmountainpower.com', ARRAY['VT'], NULL),
    ('Burlington Electric Department', 'burlington-electric', 'electric', 'https://burlingtonelectric.com', ARRAY['VT'], NULL),
    ('Block Island Power', 'block-island-power', 'electric', 'https://blockislandpower.com', ARRAY['RI'], NULL),
    ('Pascoag Utility District', 'pascoag-utility', 'electric', 'https://pud-ri.org', ARRAY['RI'], NULL),
    ('NSTAR Electric (Eversource)', 'nstar-electric', 'electric', 'https://eversource.com', ARRAY['MA'], NULL),
    ('Western Massachusetts Electric', 'wmeco', 'electric', 'https://eversource.com', ARRAY['MA'], NULL),
    ('Norwood Municipal Light', 'norwood-municipal-light', 'electric', 'https://norwoodlight.com', ARRAY['MA'], NULL),
    ('Concord Municipal Light Plant', 'concord-mlp', 'electric', 'https://concordma.gov/cmlp', ARRAY['MA'], NULL),
    ('Hingham Municipal Light', 'hingham-municipal-light', 'electric', 'https://hmlp.com', ARRAY['MA'], NULL),
    ('Wellesley Municipal Light Plant', 'wellesley-mlp', 'electric', 'https://wmlp.com', ARRAY['MA'], NULL),
    ('Belmont Municipal Light', 'belmont-municipal-light', 'electric', 'https://belmontlight.com', ARRAY['MA'], NULL),
    ('Reading Municipal Light Department', 'reading-mld', 'electric', 'https://rmld.com', ARRAY['MA'], NULL),
    ('Holyoke Gas & Electric', 'holyoke-ge', 'electric', 'https://hged.com', ARRAY['MA'], NULL),
    ('Taunton Municipal Lighting Plant', 'taunton-mlp', 'electric', 'https://tmlpnet.com', ARRAY['MA'], NULL),
    ('Braintree Electric Light Department', 'beld', 'electric', 'https://beld.com', ARRAY['MA'], NULL),
    ('CT Municipal Electric Energy Cooperative', 'cmeec', 'electric', 'https://cmeec.com', ARRAY['CT'], NULL),
    ('Norwich Public Utilities', 'norwich-public-utilities', 'electric', 'https://norwichpublicutilities.com', ARRAY['CT'], NULL),
    ('Wallingford Electric', 'wallingford-electric', 'electric', 'https://wallingfordelectric.com', ARRAY['CT'], NULL),
    ('Bozrah Light & Power', 'bozrah-light-power', 'electric', 'https://bozrah.org', ARRAY['CT'], NULL),
    ('Groton Utilities', 'groton-utilities', 'electric', 'https://grotonutilities.com', ARRAY['CT'], NULL),

    -- Northeast Mid-Atlantic
    ('Atlantic Electric (Atlantic City)', 'atlantic-electric', 'electric', 'https://atlanticcityelectric.com', ARRAY['NJ'], NULL),
    ('Rockland Electric (O&R)', 'rockland-electric', 'electric', 'https://oru.com', ARRAY['NJ','NY'], NULL),
    ('Roseland Power (PSEG)', 'roseland-power', 'electric', 'https://pseg.com', ARRAY['NJ'], NULL),
    ('Public Service Electric & Gas', 'pseg-electric-extended', 'electric', 'https://pseg.com', ARRAY['NJ'], NULL),
    ('Penn Power (FirstEnergy NJ)', 'penn-power-nj', 'electric', 'https://firstenergycorp.com', ARRAY['NJ','PA'], NULL),

    -- More National IOUs
    ('Duke Energy Florida', 'duke-energy-fl', 'electric', 'https://duke-energy.com', ARRAY['FL'], NULL),
    ('Duke Energy Indiana', 'duke-energy-in', 'electric', 'https://duke-energy.com', ARRAY['IN'], NULL),
    ('Duke Energy Kentucky', 'duke-energy-ky', 'electric', 'https://duke-energy.com', ARRAY['KY'], NULL),
    ('Duke Energy Ohio', 'duke-energy-oh', 'electric', 'https://duke-energy.com', ARRAY['OH'], NULL),
    ('Duke Energy Carolinas', 'duke-energy-carolinas', 'electric', 'https://duke-energy.com', ARRAY['NC','SC'], NULL),
    ('Duke Energy Progress', 'duke-energy-progress', 'electric', 'https://duke-energy.com', ARRAY['NC','SC'], NULL),
    ('Georgia Power (Southern)', 'georgia-power', 'electric', 'https://georgiapower.com', ARRAY['GA'], NULL),
    ('Alabama Power (Southern)', 'alabama-power', 'electric', 'https://alabamapower.com', ARRAY['AL'], NULL),
    ('Mississippi Power (Southern)', 'mississippi-power', 'electric', 'https://mississippipower.com', ARRAY['MS'], NULL),
    ('Gulf Power (NextEra)', 'gulf-power', 'electric', 'https://gulfpower.com', ARRAY['FL'], NULL),
    ('Entergy Arkansas', 'entergy-ar', 'electric', 'https://entergy-arkansas.com', ARRAY['AR'], NULL),
    ('Entergy Louisiana', 'entergy-la', 'electric', 'https://entergy-louisiana.com', ARRAY['LA'], NULL),
    ('Entergy Mississippi', 'entergy-ms', 'electric', 'https://entergy-mississippi.com', ARRAY['MS'], NULL),
    ('Entergy New Orleans', 'entergy-no', 'electric', 'https://entergy-neworleans.com', ARRAY['LA'], NULL),
    ('Entergy Texas', 'entergy-tx', 'electric', 'https://entergy-texas.com', ARRAY['TX'], NULL),
    ('Cleco Power', 'cleco-power', 'electric', 'https://cleco.com', ARRAY['LA'], NULL),
    ('SWEPCO (AEP)', 'swepco', 'electric', 'https://swepco.com', ARRAY['TX','LA','AR'], NULL),
    ('Indiana Michigan Power', 'indiana-michigan-power', 'electric', 'https://indianamichiganpower.com', ARRAY['IN','MI'], NULL),
    ('Appalachian Power', 'appalachian-power', 'electric', 'https://appalachianpower.com', ARRAY['VA','WV','TN'], NULL),
    ('Kentucky Power', 'kentucky-power', 'electric', 'https://kentuckypower.com', ARRAY['KY'], NULL),
    ('Public Service of Oklahoma', 'pso-oklahoma', 'electric', 'https://psoklahoma.com', ARRAY['OK'], NULL)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- NATURAL GAS (NE-heavy + more nationals)
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- New England gas
    ('Liberty Utilities Gas NH', 'liberty-utilities-gas-nh', 'natural_gas', 'https://liberty-energyutilities.com', ARRAY['NH'], NULL),
    ('Liberty Utilities Gas MA', 'liberty-utilities-gas-ma', 'natural_gas', 'https://liberty-energyutilities.com', ARRAY['MA'], NULL),
    ('Unitil Gas NH', 'unitil-gas-nh', 'natural_gas', 'https://unitil.com', ARRAY['NH'], NULL),
    ('Unitil Gas MA', 'unitil-gas-ma', 'natural_gas', 'https://unitil.com', ARRAY['MA'], NULL),
    ('Unitil Gas ME', 'unitil-gas-me', 'natural_gas', 'https://unitil.com', ARRAY['ME'], NULL),
    ('Vermont Gas Systems', 'vermont-gas-systems', 'natural_gas', 'https://vermontgas.com', ARRAY['VT'], NULL),
    ('Norwich Public Utilities Gas', 'norwich-pu-gas', 'natural_gas', 'https://norwichpublicutilities.com', ARRAY['CT'], NULL),
    ('Boston Gas Company', 'boston-gas', 'natural_gas', 'https://nationalgridus.com', ARRAY['MA'], NULL),
    ('Colonial Gas (National Grid)', 'colonial-gas', 'natural_gas', 'https://nationalgridus.com', ARRAY['MA'], NULL),
    ('Essex County Gas', 'essex-county-gas', 'natural_gas', 'https://nationalgridus.com', ARRAY['MA'], NULL),
    ('Holyoke Gas (HG&E)', 'holyoke-gas', 'natural_gas', 'https://hged.com', ARRAY['MA'], NULL),
    ('Middleborough Gas & Electric', 'middleborough-ge', 'natural_gas', 'https://mgeddept.com', ARRAY['MA'], NULL),
    ('Westfield Gas & Electric', 'westfield-ge', 'natural_gas', 'https://wgeld.org', ARRAY['MA'], NULL),
    ('Wakefield Municipal Gas & Light', 'wakefield-mgl', 'natural_gas', 'https://wmgld.com', ARRAY['MA'], NULL),
    ('Avangrid Berkshire Gas', 'avangrid-berkshire-gas', 'natural_gas', 'https://avangrid.com', ARRAY['MA'], NULL),

    -- Other US gas
    ('NW Natural Oregon', 'nw-natural-or', 'natural_gas', 'https://nwnatural.com', ARRAY['OR'], NULL),
    ('Energy West Wyoming', 'energy-west-wy', 'natural_gas', 'https://energywest.com', ARRAY['WY','MT'], NULL),
    ('Energy Trust', 'energy-trust', 'natural_gas', 'https://energytrust.org', ARRAY['OR','WA'], NULL),
    ('Avista Natural Gas', 'avista-gas', 'natural_gas', 'https://myavista.com', ARRAY['WA','ID','OR'], NULL),
    ('Black Hills Energy Gas', 'black-hills-gas', 'natural_gas', 'https://blackhillsenergy.com', ARRAY['SD','WY','MT','CO','NE','KS','IA','AR'], NULL),
    ('CMS Energy / Consumers Gas', 'consumers-energy-gas', 'natural_gas', 'https://consumersenergy.com', ARRAY['MI'], NULL),
    ('Delta Natural Gas', 'delta-natural-gas', 'natural_gas', 'https://deltagas.com', ARRAY['KY'], NULL),
    ('Enstar Natural Gas (Alaska)', 'enstar-gas', 'natural_gas', 'https://enstarnaturalgas.com', ARRAY['AK'], NULL),
    ('Hawaii Gas', 'hawaii-gas', 'natural_gas', 'https://hawaiigas.com', ARRAY['HI'], NULL),
    ('Mountaineer Gas', 'mountaineer-gas', 'natural_gas', 'https://mountaineergas.com', ARRAY['WV'], NULL),
    ('NJR Clean Energy Ventures', 'njr-clean', 'natural_gas', 'https://njresources.com', ARRAY['NJ'], NULL),
    ('Public Service of NC (Duke)', 'psnc-duke', 'natural_gas', 'https://duke-energy.com', ARRAY['NC'], NULL),
    ('UGI Penn Natural Gas', 'ugi-penn-natural-gas', 'natural_gas', 'https://ugi.com', ARRAY['PA'], NULL),
    ('UGI Central Penn Gas', 'ugi-central-penn-gas', 'natural_gas', 'https://ugi.com', ARRAY['PA'], NULL),
    ('Equitable Gas (EQT)', 'equitable-gas', 'natural_gas', 'https://eqt.com', ARRAY['PA','WV','OH'], NULL)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- HEATING OIL (heavy New England focus — biggest oil heat market in US)
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Connecticut
    ('Bantam Oil', 'bantam-oil', 'oil', 'https://bantamoil.com', ARRAY['CT'], NULL),
    ('B&K Energy', 'bk-energy', 'oil', 'https://bkenergy.com', ARRAY['CT'], NULL),
    ('CL&P Heating Oil', 'clp-heating-oil', 'oil', 'https://clpheating.com', ARRAY['CT'], NULL),
    ('East River Energy', 'east-river-energy', 'oil', 'https://eastriverenergy.com', ARRAY['CT'], NULL),
    ('Fairfield County Oil', 'fairfield-county-oil', 'oil', 'https://fairfieldcountyoil.com', ARRAY['CT'], NULL),
    ('Gault Energy', 'gault-energy', 'oil', 'https://gaultenergy.com', ARRAY['CT','NY'], NULL),
    ('Hartford Heating Oil', 'hartford-heating-oil', 'oil', 'https://hartfordheatingoil.com', ARRAY['CT'], NULL),
    ('Lessard Fuel', 'lessard-fuel', 'oil', 'https://lessardfuel.com', ARRAY['CT','MA','RI'], NULL),
    ('Mike''s Oil', 'mikes-oil', 'oil', 'https://mikesoilct.com', ARRAY['CT'], NULL),
    ('Mountain Energy', 'mountain-energy', 'oil', 'https://mountainenergyct.com', ARRAY['CT'], NULL),
    ('Newington Oil', 'newington-oil', 'oil', 'https://newingtonoil.com', ARRAY['CT'], NULL),
    ('Sun Oil Service', 'sun-oil-service', 'oil', 'https://sunoilservice.com', ARRAY['CT'], NULL),
    ('Suburban Energy', 'suburban-energy', 'oil', 'https://suburbanenergy.com', ARRAY['CT','NY'], NULL),

    -- Massachusetts
    ('Beacon Hill Oil', 'beacon-hill-oil', 'oil', 'https://beaconhilloil.com', ARRAY['MA'], NULL),
    ('Belko Heating Oil', 'belko-heating-oil', 'oil', 'https://belko.com', ARRAY['MA'], NULL),
    ('Burnoff Oil', 'burnoff-oil', 'oil', 'https://burnoffoil.com', ARRAY['MA','RI'], NULL),
    ('Cape Cod Energy', 'cape-cod-energy', 'oil', 'https://capecodenergy.com', ARRAY['MA'], NULL),
    ('Coan Inc.', 'coan-inc', 'oil', 'https://coaninc.com', ARRAY['MA'], NULL),
    ('Cubby Oil & Energy MA', 'cubby-oil-ma', 'oil', 'https://cubbyoil.com', ARRAY['MA'], NULL),
    ('Dennis K. Burke Inc.', 'dennis-k-burke', 'oil', 'https://dkburke.com', ARRAY['MA','NH','VT','ME','CT','RI','NY'], NULL),
    ('Energi Heating', 'energi-heating', 'oil', 'https://energiheating.com', ARRAY['MA','NH'], NULL),
    ('Greater Boston Oil', 'greater-boston-oil', 'oil', 'https://greaterbostonoil.com', ARRAY['MA'], NULL),
    ('Mahoney Oil', 'mahoney-oil', 'oil', 'https://mahoneyoil.com', ARRAY['MA','RI'], NULL),
    ('Merrimack Oil', 'merrimack-oil', 'oil', 'https://merrimackoil.com', ARRAY['MA','NH'], NULL),
    ('Needham Oil', 'needham-oil', 'oil', 'https://needhamoil.com', ARRAY['MA'], NULL),
    ('Robert B. Our Co.', 'robert-our', 'oil', 'https://ourcompany.com', ARRAY['MA'], NULL),
    ('Walpole Heating Oil', 'walpole-heating-oil', 'oil', 'https://walpoleheating.com', ARRAY['MA'], NULL),

    -- New Hampshire / Vermont / Maine
    ('Amerigas NH Heating Oil', 'amerigas-nh-oil', 'oil', 'https://amerigas.com', ARRAY['NH'], NULL),
    ('Bourne''s Energy', 'bournes-energy', 'oil', 'https://bournesenergy.com', ARRAY['VT','NH'], NULL),
    ('Cota & Cota', 'cota-cota', 'oil', 'https://cotaandcota.com', ARRAY['VT','NH'], NULL),
    ('Dead River Maine', 'dead-river-me', 'oil', 'https://deadriver.com', ARRAY['ME','NH','VT'], NULL),
    ('Downeast Energy', 'downeast-energy', 'oil', 'https://downeastenergy.com', ARRAY['ME','NH'], NULL),
    ('Fielder''s Choice Energy', 'fielders-choice', 'oil', 'https://fielderschoiceenergy.com', ARRAY['VT','NH','MA'], NULL),
    ('Foster Brothers Fuels', 'foster-brothers-fuels', 'oil', 'https://fosterbrothersfuels.com', ARRAY['VT','NH','MA','NY'], NULL),
    ('Frye''s Heating Oil', 'fryes-heating-oil', 'oil', 'https://fryesoil.com', ARRAY['NH'], NULL),
    ('H&S Energy', 'hs-energy', 'oil', 'https://hsenergyfuels.com', ARRAY['MA','NH','RI'], NULL),
    ('Irving Oil', 'irving-oil', 'oil', 'https://irvingoil.com', ARRAY['ME','NH','VT','MA'], NULL),
    ('Jackman & Sons Fuel', 'jackman-sons-fuel', 'oil', 'https://jackmanandsonsfuel.com', ARRAY['ME','NH'], NULL),
    ('Kennebec Valley Oil', 'kennebec-valley-oil', 'oil', 'https://kennebecvalleyoil.com', ARRAY['ME'], NULL),
    ('Lake Region Heating', 'lake-region-heating', 'oil', 'https://lakeregionheating.com', ARRAY['NH','VT'], NULL),
    ('Leighton Oil', 'leighton-oil', 'oil', 'https://leightonoil.com', ARRAY['NH'], NULL),
    ('Maine Energy', 'maine-energy', 'oil', 'https://maineenergy.com', ARRAY['ME'], NULL),
    ('Palmer Gas & Oil', 'palmer-gas-oil', 'oil', 'https://palmergas.com', ARRAY['NH','MA','ME'], NULL),
    ('R.H. Foster Energy', 'rh-foster', 'oil', 'https://rhfoster.com', ARRAY['ME'], NULL),
    ('Walden''s Fuel Oil', 'waldens-fuel-oil', 'oil', 'https://waldensfueloil.com', ARRAY['NH'], NULL),

    -- New York / NJ / PA / RI
    ('All Year Heating Oil NY', 'all-year-heating-oil-ny', 'oil', 'https://allyearheatingoilny.com', ARRAY['NY'], NULL),
    ('AmeriGas Heating Oil', 'amerigas-heating-oil', 'oil', 'https://amerigas.com', ARRAY['NY','NJ','PA','CT'], NULL),
    ('Burns & Wright Oil', 'burns-wright-oil', 'oil', 'https://burnsandwrightoil.com', ARRAY['NY'], NULL),
    ('Family Energy', 'family-energy-oil', 'oil', 'https://familyenergy.com', ARRAY['NY','NJ','CT'], NULL),
    ('Gold Heating Oil', 'gold-heating-oil', 'oil', 'https://goldheatingoil.com', ARRAY['NJ','NY'], NULL),
    ('Just Energy Heating Oil', 'just-energy-oil', 'oil', 'https://justenergy.com', ARRAY['NY','NJ','PA'], NULL),
    ('Long Island Heating Oil', 'long-island-heating-oil', 'oil', 'https://liheatingoil.com', ARRAY['NY'], NULL),
    ('Newman Oil', 'newman-oil', 'oil', 'https://newmanoil.com', ARRAY['NJ'], NULL),
    ('Peters Oil & Gas', 'peters-oil-gas', 'oil', 'https://petersoil.com', ARRAY['NY'], NULL),
    ('Quality Oil Long Island', 'quality-oil-li', 'oil', 'https://qualityoilli.com', ARRAY['NY'], NULL),
    ('Standard Oil of CT', 'standard-oil-ct', 'oil', 'https://standardoilct.com', ARRAY['CT','NY'], NULL),
    ('Wilson Oil & Propane', 'wilson-oil-propane', 'oil', 'https://wilsonoil.com', ARRAY['PA'], NULL),
    ('AAA Heating Oil RI', 'aaa-heating-oil-ri', 'oil', 'https://aaaheatingri.com', ARRAY['RI'], NULL),
    ('Conti Oil', 'conti-oil', 'oil', 'https://contioilri.com', ARRAY['RI'], NULL)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- PROPANE (NE rural + more nationals)
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- New England
    ('Anchor Gas (NH)', 'anchor-gas-nh', 'propane', 'https://anchorgas.com', ARRAY['NH','MA','VT','ME'], NULL),
    ('Athens Energy (CT)', 'athens-energy', 'propane', 'https://athensenergyct.com', ARRAY['CT'], NULL),
    ('Atlas Propane', 'atlas-propane', 'propane', 'https://atlaspropane.com', ARRAY['MA','RI','CT','NH'], NULL),
    ('Bancroft Energy', 'bancroft-energy', 'propane', 'https://bancroftenergy.com', ARRAY['MA','NH','VT','ME','CT'], NULL),
    ('Boyle Energy', 'boyle-energy', 'propane', 'https://boyleenergy.com', ARRAY['MA','NH','RI'], NULL),
    ('Butler Brothers Propane', 'butler-brothers-propane', 'propane', 'https://butlerbros.com', ARRAY['NH','MA','VT'], NULL),
    ('Cargas Propane', 'cargas-propane', 'propane', 'https://cargas.com', ARRAY['NJ','PA','NY'], NULL),
    ('Cubby Propane', 'cubby-propane', 'propane', 'https://cubbyoil.com', ARRAY['MA','NH'], NULL),
    ('Eastern Propane NH', 'eastern-propane-nh', 'propane', 'https://eastenergy.com', ARRAY['NH','ME','VT','MA'], NULL),
    ('Energy North (NH)', 'energy-north', 'propane', 'https://energynorthinc.com', ARRAY['NH','MA','ME','VT'], NULL),
    ('Fred''s Energy', 'freds-energy', 'propane', 'https://fredsenergy.com', ARRAY['VT','NH'], NULL),
    ('Hancock Propane', 'hancock-propane', 'propane', 'https://hancockpropane.com', ARRAY['ME','NH'], NULL),
    ('Maine Propane', 'maine-propane', 'propane', 'https://mainepropane.com', ARRAY['ME'], NULL),
    ('Northeast Propane Gas', 'northeast-propane', 'propane', 'https://northeastpropanegas.com', ARRAY['MA','NH','VT','ME'], NULL),
    ('Petro Home Services Propane', 'petro-home-propane', 'propane', 'https://petro.com', ARRAY['NY','NJ','CT','MA','RI'], NULL),
    ('Reading Energy Group Propane', 'reading-energy-propane', 'propane', 'https://readingenergy.com', ARRAY['PA','NJ'], NULL),
    ('Robison Propane', 'robison-propane', 'propane', 'https://robisonenergy.com', ARRAY['NY','CT'], NULL),
    ('Russell Energy', 'russell-energy', 'propane', 'https://russellenergyfuels.com', ARRAY['MA'], NULL),
    ('Sippin Brothers Propane', 'sippin-brothers', 'propane', 'https://sippinenergy.com', ARRAY['CT'], NULL),
    ('Smiths Gas', 'smiths-gas', 'propane', 'https://smithsgas.com', ARRAY['NH','VT','ME'], NULL),
    ('Tibbetts Propane', 'tibbetts-propane', 'propane', 'https://tibbettspropane.com', ARRAY['ME'], NULL),
    ('Twin State Sand & Gravel Propane', 'twin-state-propane', 'propane', 'https://twinstatesg.com', ARRAY['VT','NH'], NULL),

    -- Other US
    ('Liberty Propane', 'liberty-propane', 'propane', 'https://libertypropane.com', ARRAY['US'], NULL),
    ('Empiregas', 'empiregas', 'propane', 'https://empiregas.com', ARRAY['US'], NULL),
    ('Reeders Propane', 'reeders-propane', 'propane', 'https://reederspropane.com', ARRAY['US'], NULL),
    ('Rural Empire Propane', 'rural-empire-propane', 'propane', 'https://ruralempire.com', ARRAY['US'], NULL),
    ('Schmidts Wholesale Propane', 'schmidts-propane', 'propane', 'https://schmidtspropane.com', ARRAY['US'], NULL)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- WATER UTILITIES (NE municipal systems + more)
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    ('Aquarion Connecticut', 'aquarion-ct', 'water', 'https://aquarionwater.com', ARRAY['CT','NH','MA'], NULL),
    ('Aquarion Massachusetts', 'aquarion-ma', 'water', 'https://aquarionwater.com', ARRAY['MA'], NULL),
    ('Aquarion New Hampshire', 'aquarion-nh', 'water', 'https://aquarionwater.com', ARRAY['NH'], NULL),
    ('Connecticut Water Co', 'ct-water-co', 'water', 'https://ctwater.com', ARRAY['CT'], NULL),
    ('Avon Water Co', 'avon-water-ct', 'water', 'https://avonwaterct.com', ARRAY['CT'], NULL),
    ('Greenwich Water', 'greenwich-water', 'water', 'https://greenwichwater.com', ARRAY['CT'], NULL),
    ('Norwalk First District Water', 'norwalk-first-water', 'water', 'https://fdistrictwater.com', ARRAY['CT'], NULL),
    ('Bridgeport Hydraulic (Aquarion)', 'bridgeport-hydraulic', 'water', 'https://aquarionwater.com', ARRAY['CT'], NULL),
    ('Stamford Water Co', 'stamford-water', 'water', 'https://aquarionwater.com', ARRAY['CT'], NULL),
    ('Mass Water Resources Authority', 'mwra-extended', 'water', 'https://mwra.com', ARRAY['MA'], NULL),
    ('Boston Water & Sewer', 'boston-ws', 'water', 'https://bwsc.org', ARRAY['MA'], NULL),
    ('Cambridge Water Department', 'cambridge-water-dept', 'water', 'https://cambridgema.gov/water', ARRAY['MA'], NULL),
    ('Worcester Department of Public Works', 'worcester-dpw', 'water', 'https://worcesterma.gov/dpw', ARRAY['MA'], NULL),
    ('Springfield Water & Sewer', 'springfield-ws', 'water', 'https://waterandsewer.org', ARRAY['MA'], NULL),
    ('Lowell Regional Wastewater', 'lowell-rww', 'water', 'https://lowellma.gov', ARRAY['MA'], NULL),
    ('Providence Water', 'providence-water', 'water', 'https://provwater.com', ARRAY['RI'], NULL),
    ('Newport Water Department', 'newport-water-ri', 'water', 'https://cityofnewport.com/water', ARRAY['RI'], NULL),
    ('Pawtucket Water Supply Board', 'pawtucket-wsb', 'water', 'https://pawtucketwater.org', ARRAY['RI'], NULL),
    ('Manchester Water Works', 'manchester-water-nh', 'water', 'https://manchesternh.gov/water', ARRAY['NH'], NULL),
    ('Portsmouth Water (NH)', 'portsmouth-water-nh', 'water', 'https://cityofportsmouth.com/water', ARRAY['NH'], NULL),
    ('Pennichuck Water', 'pennichuck-water', 'water', 'https://pennichuck.com', ARRAY['NH','MA','ME'], NULL),
    ('Portland Water District (ME)', 'portland-water-me', 'water', 'https://pwd.org', ARRAY['ME'], NULL),
    ('Bangor Water District', 'bangor-water-me', 'water', 'https://bangorwater.org', ARRAY['ME'], NULL),
    ('Burlington Public Works (VT)', 'burlington-public-works-vt', 'water', 'https://burlingtonvt.gov/dpw', ARRAY['VT'], NULL),
    ('Champlain Water District', 'champlain-water', 'water', 'https://champlainwater.org', ARRAY['VT'], NULL),
    ('Hartford Metropolitan District', 'hartford-mdc', 'water', 'https://themdc.org', ARRAY['CT'], NULL),
    ('NJ American Water', 'nj-american-water-extended', 'water', 'https://amwater.com/njaw', ARRAY['NJ'], NULL),
    ('NYC DEP', 'nyc-dep-extended', 'water', 'https://nyc.gov/dep', ARRAY['NY'], NULL),
    ('Suffolk County Water Authority', 'scwa-suffolk', 'water', 'https://scwa.com', ARRAY['NY'], NULL),
    ('United Water', 'united-water', 'water', 'https://veolianorthamerica.com', ARRAY['US'], NULL),
    ('Pennsylvania American Water', 'pa-american-water-extended', 'water', 'https://amwater.com/paaw', ARRAY['PA'], NULL),
    ('Aqua PA (Essential)', 'aqua-pa', 'water', 'https://essential.co', ARRAY['PA'], NULL),
    ('Citizens Water DC', 'citizens-water-dc', 'water', 'https://dcwater.com', ARRAY['DC'], NULL)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- INTERNET / CABLE (more regional ISPs)
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    ('Spectrum (NE)', 'spectrum-ne', 'internet_cable', 'https://spectrum.com', ARRAY['CT','MA','NH','VT','ME','RI','NY'], NULL),
    ('Optimum (Altice)', 'optimum-altice', 'internet_cable', 'https://optimum.com', ARRAY['CT','NJ','NY','PA'], NULL),
    ('Verizon Fios NE', 'verizon-fios-ne', 'internet_cable', 'https://verizon.com/fios', ARRAY['CT','MA','NJ','NY','PA','RI'], NULL),
    ('Comcast Xfinity NE', 'comcast-xfinity-ne', 'internet_cable', 'https://xfinity.com', ARRAY['CT','MA','NH','VT','ME','RI'], NULL),
    ('Altice USA', 'altice-usa', 'internet_cable', 'https://alticeusa.com', ARRAY['NY','NJ','CT','PA'], NULL),
    ('Cox NE Customers', 'cox-ne', 'internet_cable', 'https://cox.com', ARRAY['CT','RI'], NULL),
    ('Atlantic Broadband NE', 'atlantic-broadband-ne', 'internet_cable', 'https://atlanticbb.com', ARRAY['ME','NH','PA'], NULL),
    ('Burlington Telecom (VT)', 'burlington-telecom', 'internet_cable', 'https://burlingtontelecom.com', ARRAY['VT'], NULL),
    ('OTT Communications (ME)', 'ott-communications', 'internet_cable', 'https://otttelephone.com', ARRAY['ME'], NULL),
    ('Pioneer Broadband (ME)', 'pioneer-broadband', 'internet_cable', 'https://pioneerbroadband.net', ARRAY['ME'], NULL),
    ('Premium Communications (NH)', 'premium-communications', 'internet_cable', 'https://premiumcommunications.com', ARRAY['NH'], NULL),
    ('Wave Wireless', 'wave-wireless', 'internet_cable', 'https://wavewireless.com', ARRAY['NH','MA','VT'], NULL),
    ('FirstLight Fiber', 'firstlight-fiber', 'internet_cable', 'https://firstlight.net', ARRAY['NY','VT','NH','MA','ME','CT','RI','PA','NJ'], NULL),
    ('Crown Castle Fiber', 'crown-castle-fiber', 'internet_cable', 'https://crowncastle.com', ARRAY['US'], NULL),
    ('Lit Communities', 'lit-communities', 'internet_cable', 'https://litcommunities.com', ARRAY['US'], NULL)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- TRASH / RECYCLING (more NE haulers)
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    ('CWPM (Connecticut Waste Processing)', 'cwpm-ct', 'trash', 'https://cwpm.com', ARRAY['CT'], NULL),
    ('Paine''s Inc.', 'paines-inc', 'trash', 'https://painesrecycling.com', ARRAY['CT','MA'], NULL),
    ('All Waste Inc.', 'all-waste-inc', 'trash', 'https://allwasteinc.com', ARRAY['CT','MA'], NULL),
    ('Sanitation District 1', 'sd1-ne', 'trash', 'https://sd1.org', ARRAY['CT'], NULL),
    ('USA Hauling (CT)', 'usa-hauling', 'trash', 'https://usahauling.com', ARRAY['CT','MA'], NULL),
    ('Anytime Removal', 'anytime-removal', 'trash', 'https://anytimeremoval.com', ARRAY['CT','MA'], NULL),
    ('Capitol Region Disposal', 'capitol-region-disposal', 'trash', 'https://capitalregiondisposal.com', ARRAY['CT'], NULL),
    ('Bay State Disposal', 'bay-state-disposal', 'trash', 'https://baystatedisposal.com', ARRAY['MA'], NULL),
    ('JRM Hauling & Recycling', 'jrm-hauling', 'trash', 'https://jrmhauling.com', ARRAY['MA','RI'], NULL),
    ('Russell Disposal', 'russell-disposal', 'trash', 'https://russelldisposal.com', ARRAY['MA'], NULL),
    ('E.L. Harvey & Sons', 'el-harvey', 'trash', 'https://elharvey.com', ARRAY['MA','NH','RI'], NULL),
    ('Mello Disposal', 'mello-disposal', 'trash', 'https://mellodisposal.com', ARRAY['MA'], NULL),
    ('North Shore Disposal', 'north-shore-disposal', 'trash', 'https://northshoredisposal.com', ARRAY['MA'], NULL),
    ('Coastal Carting', 'coastal-carting', 'trash', 'https://coastalcarting.com', ARRAY['MA','RI'], NULL),
    ('North Country Environmental Services', 'ncessites', 'trash', 'https://ncessites.com', ARRAY['NH','VT','MA'], NULL),
    ('Casella NH', 'casella-nh', 'trash', 'https://casella.com', ARRAY['NH','VT','ME'], NULL),
    ('Fox Disposal Service', 'fox-disposal', 'trash', 'https://foxdisposal.com', ARRAY['NH','VT'], NULL),
    ('Alpine Refuse', 'alpine-refuse', 'trash', 'https://alpinerefuse.com', ARRAY['NH','VT'], NULL),
    ('Waste Resources Vermont', 'waste-resources-vt', 'trash', 'https://wasteresourcesvt.com', ARRAY['VT'], NULL),
    ('Pine Tree Waste', 'pine-tree-waste', 'trash', 'https://pinetreewaste.com', ARRAY['ME','NH'], NULL),
    ('Pine Tree Disposal', 'pine-tree-disposal', 'trash', 'https://pinetreedisposal.com', ARRAY['ME'], NULL),
    ('Riverside Recycling', 'riverside-recycling-me', 'trash', 'https://riversiderecycling.com', ARRAY['ME','NH'], NULL),
    ('Waste Management Atlantic', 'wm-atlantic', 'trash', 'https://wm.com', ARRAY['CT','MA','NH','VT','ME','RI','NY','NJ','PA'], NULL),
    ('Republic Services Northeast', 'republic-northeast', 'trash', 'https://republicservices.com', ARRAY['CT','MA','NH','VT','ME','RI','NY','NJ','PA'], NULL),
    ('Casella Connecticut', 'casella-ct', 'trash', 'https://casella.com', ARRAY['CT','MA'], NULL)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- LANDSCAPING (more NE companies)
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    ('SavATree (NE)', 'savatree-ne', 'landscaping', 'https://savatree.com', ARRAY['CT','MA','NH','VT','ME','RI','NY','NJ','PA'], NULL),
    ('Bartlett Tree Experts NE', 'bartlett-tree-ne', 'landscaping', 'https://bartlett.com', ARRAY['CT','MA','NH','RI','NJ','NY','PA'], NULL),
    ('Davey Tree NE', 'davey-tree-ne', 'landscaping', 'https://davey.com', ARRAY['CT','MA','NH','VT','ME','RI','NY','NJ','PA'], NULL),
    ('Northeast Lawn & Landscape', 'ne-lawn-landscape', 'landscaping', 'https://nellc.com', ARRAY['CT','MA'], NULL),
    ('Hoffman Landscapes', 'hoffman-landscapes', 'landscaping', 'https://hoffmanlandscapes.com', ARRAY['CT','NY'], NULL),
    ('Hartney Greymont', 'hartney-greymont', 'landscaping', 'https://hartneygreymont.com', ARRAY['MA'], NULL),
    ('R.P. Marzilli', 'rp-marzilli', 'landscaping', 'https://rpmarzilli.com', ARRAY['MA','NH','RI','CT'], NULL),
    ('Munro Landscaping', 'munro-landscaping', 'landscaping', 'https://munrolandscaping.com', ARRAY['MA'], NULL),
    ('Ahern Landscape', 'ahern-landscape', 'landscaping', 'https://ahernlandscape.com', ARRAY['MA','NH'], NULL),
    ('Conservation Landscaping', 'conservation-landscaping', 'landscaping', 'https://conservationlandscape.com', ARRAY['CT'], NULL),
    ('Beardsley Construction & Landscape', 'beardsley-construction', 'landscaping', 'https://beardsleylandscape.com', ARRAY['CT'], NULL),
    ('Conte''s Landscape', 'contes-landscape', 'landscaping', 'https://conteslandscape.com', ARRAY['CT'], NULL),
    ('Alpine Tree Service', 'alpine-tree-service', 'landscaping', 'https://alpinetreect.com', ARRAY['CT'], NULL),
    ('Almstead Tree Service', 'almstead-tree', 'landscaping', 'https://almstead.com', ARRAY['NY','CT','NJ'], NULL),
    ('Champion Tree Care', 'champion-tree-care', 'landscaping', 'https://championtreecare.com', ARRAY['MA','NH','RI','CT'], NULL),
    ('Mahoney Tree Service', 'mahoney-tree-service', 'landscaping', 'https://mahoneytreeservice.com', ARRAY['MA','NH','RI'], NULL),
    ('Mayer Tree Service', 'mayer-tree-service', 'landscaping', 'https://mayertree.com', ARRAY['MA'], NULL),
    ('NaturaLawn of New England', 'naturalawn-ne', 'landscaping', 'https://nl-amer.com', ARRAY['MA','CT','RI','NH'], NULL),
    ('TruGreen New England', 'trugreen-ne', 'landscaping', 'https://trugreen.com', ARRAY['MA','CT','RI','NH','VT','ME','NY'], NULL),
    ('Lawn Care of New England', 'lawn-care-ne', 'landscaping', 'https://lawncarene.com', ARRAY['MA','CT','RI','NH'], NULL),
    ('Greener Horizons (CT)', 'greener-horizons-ct', 'landscaping', 'https://greenerhorizons.net', ARRAY['CT'], NULL),
    ('Eco-Tech Lawn Service', 'eco-tech-lawn', 'landscaping', 'https://ecotechlawnservice.com', ARRAY['CT','MA','NY'], NULL),
    ('Lawnscape Inc.', 'lawnscape-inc', 'landscaping', 'https://lawnscapeinc.com', ARRAY['MA','RI'], NULL)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- PEST CONTROL (more NE companies)
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    ('JP McHale Pest Management', 'jp-mchale', 'pest_control', 'https://nopests.com', ARRAY['NY','NJ','CT','PA','MA'], NULL),
    ('A1 Exterminators', 'a1-exterminators', 'pest_control', 'https://a1exterminators.com', ARRAY['MA','NH','RI','ME','VT'], NULL),
    ('Arrow Pest Control NJ', 'arrow-pest-nj', 'pest_control', 'https://arrowpestcontrol.com', ARRAY['NJ','NY','PA'], NULL),
    ('Pestmaster Services New England', 'pestmaster-ne', 'pest_control', 'https://pestmaster.com', ARRAY['MA','NH','VT'], NULL),
    ('Yankee Pest Control', 'yankee-pest', 'pest_control', 'https://yankeepest.com', ARRAY['MA','NH','RI'], NULL),
    ('Modern Pest Services', 'modern-pest', 'pest_control', 'https://modernpest.com', ARRAY['ME','NH','MA','VT'], NULL),
    ('Connors Pest Control', 'connors-pest', 'pest_control', 'https://connorspest.com', ARRAY['CT','MA','RI'], NULL),
    ('Quality Pest Control CT', 'quality-pest-ct', 'pest_control', 'https://qualitypestct.com', ARRAY['CT'], NULL),
    ('Bug Off Exterminators', 'bug-off-exterminators', 'pest_control', 'https://bugoffexterminators.com', ARRAY['NJ','NY','CT'], NULL),
    ('Cowley''s Pest Services', 'cowleys-pest', 'pest_control', 'https://cowleysprovidedge.com', ARRAY['NJ'], NULL),
    ('Eastern Pest Services', 'eastern-pest-services', 'pest_control', 'https://easternpest.com', ARRAY['NJ'], NULL),
    ('Cypress Pest Solutions', 'cypress-pest', 'pest_control', 'https://cypresspest.com', ARRAY['NJ','NY','PA'], NULL),
    ('Bell Environmental Services', 'bell-environmental', 'pest_control', 'https://bellpest.com', ARRAY['NJ','NY','PA','CT'], NULL),
    ('Catseye Pest Control', 'catseye-pest', 'pest_control', 'https://catseyepest.com', ARRAY['CT','MA','NY','RI','VT','NH'], NULL),
    ('Atlantic Pest Solutions NJ', 'atlantic-pest-nj', 'pest_control', 'https://atlanticpestcontrol.com', ARRAY['NJ'], NULL),
    ('Big Blue Bug Solutions', 'big-blue-bug', 'pest_control', 'https://bigbluebug.com', ARRAY['RI','MA','CT'], NULL),
    ('M&M Pest Control', 'mm-pest', 'pest_control', 'https://mandmpest.com', ARRAY['NY'], NULL),
    ('Action Pest Control', 'action-pest', 'pest_control', 'https://actionpestcontrol.com', ARRAY['NY','NJ','CT'], NULL),
    ('Crazylegs Pest Control', 'crazylegs-pest', 'pest_control', 'https://crazylegspestcontrol.com', ARRAY['CT','NY','NJ'], NULL)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- SECURITY (more NE alarm companies)
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    ('American Alarm & Communications', 'american-alarm-extended', 'security', 'https://americanalarm.com', ARRAY['MA','NH','RI','CT','VT','ME'], NULL),
    ('Hartford Alarm', 'hartford-alarm', 'security', 'https://hartfordalarm.com', ARRAY['CT'], NULL),
    ('Northeast Security Solutions', 'northeast-security-solutions', 'security', 'https://northeastsecuritysolutions.com', ARRAY['MA','NH','RI','CT'], NULL),
    ('Bay Alarm New England', 'bay-alarm-ne', 'security', 'https://bayalarm.com', ARRAY['MA','RI','CT'], NULL),
    ('Security Systems by Hammond', 'hammond-security', 'security', 'https://hammondsystems.com', ARRAY['CT','MA','NY'], NULL),
    ('Alarm Specialists', 'alarm-specialists', 'security', 'https://alarmspec.com', ARRAY['NJ','NY','CT'], NULL),
    ('Affiliated Steam Equipment / Alarm NE', 'affiliated-alarm-ne', 'security', 'https://affiliatedsteam.com', ARRAY['CT','MA','RI'], NULL),
    ('Alarm New England', 'alarm-new-england', 'security', 'https://alarmnewengland.com', ARRAY['CT','MA','RI','NY'], NULL),
    ('Securadyne New England', 'securadyne-ne', 'security', 'https://securadyne.com', ARRAY['MA','NH','RI','CT','VT','ME'], NULL),
    ('Smith Alarm', 'smith-alarm', 'security', 'https://smithalarm.com', ARRAY['NY','NJ','CT'], NULL),
    ('Custom Alarm', 'custom-alarm', 'security', 'https://customalarm.com', ARRAY['CT','MA'], NULL),
    ('Verified Alarms', 'verified-alarms', 'security', 'https://verifiedalarms.com', ARRAY['MA','NH','RI'], NULL),
    ('Boston Alarm', 'boston-alarm', 'security', 'https://bostonalarm.com', ARRAY['MA'], NULL),
    ('Total Security Inc.', 'total-security-inc', 'security', 'https://totalsecurityinc.com', ARRAY['NY','NJ','CT'], NULL),
    ('Sky Security', 'sky-security', 'security', 'https://skysecurityusa.com', ARRAY['MA','RI','CT'], NULL),
    ('Lyon''s Alarm', 'lyons-alarm', 'security', 'https://lyonsalarm.com', ARRAY['MA','NH','RI','CT'], NULL),
    ('Quincy Alarm', 'quincy-alarm', 'security', 'https://quincyalarm.com', ARRAY['MA'], NULL),
    ('Yale Smart Living', 'yale-smart-living', 'security', 'https://shopyalehome.com', ARRAY['US'], NULL),
    ('Honeywell Total Connect', 'honeywell-total-connect', 'security', 'https://totalconnect2.com', ARRAY['US'], NULL),
    ('FrontPoint NE', 'frontpoint-ne', 'security', 'https://frontpointsecurity.com', ARRAY['CT','MA','NH','RI','VT','ME','NY','NJ','PA'], NULL)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- SOLAR (more NE installers)
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    ('SunBug Solar', 'sunbug-solar', 'solar', 'https://sunbugsolar.com', ARRAY['MA','NH','RI'], NULL),
    ('NEPS (New England Power Systems)', 'neps', 'solar', 'https://newenglandpowersystems.com', ARRAY['MA','NH','RI','CT'], NULL),
    ('Boston Solar', 'boston-solar', 'solar', 'https://bostonsolar.us', ARRAY['MA','NH','RI'], NULL),
    ('Solaria Energy Solutions', 'solaria-energy', 'solar', 'https://solariaenergy.com', ARRAY['MA','CT','RI'], NULL),
    ('My Generation Energy', 'my-generation-energy', 'solar', 'https://mygenerationenergy.com', ARRAY['MA'], NULL),
    ('SunPower by Sea Bright', 'sunpower-sea-bright', 'solar', 'https://sunpower.com/dealers', ARRAY['NJ','NY','CT'], NULL),
    ('Direct Energy Solar (NE)', 'direct-energy-solar-ne', 'solar', 'https://directenergysolar.com', ARRAY['MA','NJ','NY','MD','PA'], NULL),
    ('SunCommon (VT/NY)', 'suncommon-extended', 'solar', 'https://suncommon.com', ARRAY['VT','NY'], NULL),
    ('Catamount Solar', 'catamount-solar', 'solar', 'https://catamountsolar.com', ARRAY['VT','NH','MA'], NULL),
    ('Green Lantern Solar', 'green-lantern-solar', 'solar', 'https://greenlanternsolar.com', ARRAY['VT','NH'], NULL),
    ('Aegis Renewable Energy', 'aegis-renewable', 'solar', 'https://aegisrenewable.com', ARRAY['VT','NH','MA','NY'], NULL),
    ('Sun Common', 'sun-common-vt', 'solar', 'https://suncommon.com', ARRAY['VT'], NULL),
    ('ReVision Energy', 'revision-energy', 'solar', 'https://revisionenergy.com', ARRAY['ME','NH','MA'], NULL),
    ('Sunlight Solar Energy', 'sunlight-solar-energy', 'solar', 'https://sunlightsolar.com', ARRAY['CT','MA','RI','OR','WA','CO'], NULL),
    ('Aurora Solar', 'aurora-solar-ne', 'solar', 'https://aurorasolar.com', ARRAY['MA','NH','VT','ME'], NULL),
    ('Wave Energy Solutions', 'wave-energy', 'solar', 'https://waveenergysolutions.com', ARRAY['CT','MA','RI','NY'], NULL),
    ('Sunrise Solar Connecticut', 'sunrise-solar-ct', 'solar', 'https://sunrisesolarct.com', ARRAY['CT'], NULL),
    ('Cooperative Energy Futures', 'cooperative-energy-futures', 'solar', 'https://cooperativeenergyfutures.com', ARRAY['MN','WI','IL'], NULL)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- POOL SERVICE (more NE companies)
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    ('Aqua Pool & Patio CT', 'aqua-pool-patio-ct', 'pool_service', 'https://aquapool.com', ARRAY['CT','MA'], NULL),
    ('Pool Specialists CT', 'pool-specialists-ct', 'pool_service', 'https://poolspecialists.com', ARRAY['CT'], NULL),
    ('SwimWorks Pool Service', 'swimworks', 'pool_service', 'https://swimworks.net', ARRAY['CT','MA'], NULL),
    ('Crystal Pools New England', 'crystal-pools-ne', 'pool_service', 'https://crystalpoolsne.com', ARRAY['MA','RI','CT'], NULL),
    ('Aqua-Tech Pools', 'aqua-tech-pools-ne', 'pool_service', 'https://aquatechpools.com', ARRAY['MA','RI','CT','NH'], NULL),
    ('New England Pools', 'new-england-pools', 'pool_service', 'https://newenglandpools.com', ARRAY['MA','NH','RI'], NULL),
    ('Boston Pools & Spas', 'boston-pools-spas', 'pool_service', 'https://bostonpools.com', ARRAY['MA'], NULL),
    ('Town & Country Pools', 'town-country-pools', 'pool_service', 'https://towncountrypools.com', ARRAY['MA','RI'], NULL),
    ('Cape Cod Pool & Spa', 'cape-cod-pool-spa', 'pool_service', 'https://capecodpool.com', ARRAY['MA'], NULL),
    ('Aqua-Bright Pools', 'aqua-bright-pools', 'pool_service', 'https://aquabrightpools.com', ARRAY['MA','NH'], NULL),
    ('Sparkling Pools', 'sparkling-pools', 'pool_service', 'https://sparklingpoolsct.com', ARRAY['CT'], NULL),
    ('Aqua Pool Service NJ', 'aqua-pool-service-nj', 'pool_service', 'https://aquapoolnj.com', ARRAY['NJ','NY'], NULL),
    ('Crystal Clear Pools NJ', 'crystal-clear-pools-nj', 'pool_service', 'https://crystalclearpoolsnj.com', ARRAY['NJ'], NULL),
    ('Goodall Pools & Spas', 'goodall-pools', 'pool_service', 'https://goodallpools.com', ARRAY['PA','MD','VA','DE','NJ'], NULL)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- IRRIGATION (more NE sprinkler companies)
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    ('Aqua Lawn Sprinklers CT', 'aqua-lawn-sprinklers-ct', 'irrigation', 'https://aqualawnsprinklers.com', ARRAY['CT'], NULL),
    ('Atlantic Lawn Sprinklers', 'atlantic-lawn-sprinklers', 'irrigation', 'https://atlanticlawn.com', ARRAY['CT','NY'], NULL),
    ('B&G Sprinkler Systems', 'bg-sprinkler', 'irrigation', 'https://bgsprinkler.com', ARRAY['CT','MA','NY'], NULL),
    ('Conservation Plus Irrigation', 'conservation-plus-extended', 'irrigation', 'https://conservationplus.com', ARRAY['CT','MA'], NULL),
    ('Greenlife Lawn Sprinklers', 'greenlife-lawn-sprinklers', 'irrigation', 'https://greenlifesprinklers.com', ARRAY['CT'], NULL),
    ('R&S Landscape Irrigation', 'rs-landscape-irrigation', 'irrigation', 'https://rslandscapeirrigation.com', ARRAY['NJ','PA'], NULL),
    ('Rainbird CT Installers', 'rainbird-ct-installers', 'irrigation', 'https://rainbird.com', ARRAY['CT','MA','RI'], NULL),
    ('Hunter Irrigation Pro NE', 'hunter-irrigation-ne', 'irrigation', 'https://hunterindustries.com', ARRAY['CT','MA','RI','NH','VT','ME'], NULL),
    ('Rain Master Lawn Sprinklers', 'rain-master-lawn', 'irrigation', 'https://rainmastersprinklers.com', ARRAY['NJ','PA'], NULL),
    ('Long Island Sprinklers', 'long-island-sprinklers', 'irrigation', 'https://longislandsprinklers.com', ARRAY['NY'], NULL),
    ('Sprinkler Systems by Sienkiewicz', 'sienkiewicz-sprinklers', 'irrigation', 'https://sprinklersystemsbys.com', ARRAY['CT','MA','RI'], NULL)
ON CONFLICT (slug) DO NOTHING;
