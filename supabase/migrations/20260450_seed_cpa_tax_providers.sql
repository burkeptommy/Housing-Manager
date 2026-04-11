-- Seed CPA and tax advisory firms into utility_providers table.
-- Section 1: National chains, Big 4, and top-25 firms (US-wide)
-- Section 2: Regional firms serving the NY/CT metro area
-- Section 3: Local CPA firms in Westchester County, NY (by town)
-- Section 4: Local CPA firms in Fairfield County, CT (by town)
-- provider_type = 'cpa_tax', logo_url = NULL (resolved at runtime via Brandfetch).

-- ============================================================
-- SECTION 1: National chains, Big 4, and top-25 US firms
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Big 4
    ('EY (Ernst & Young)', 'ey', 'cpa_tax', 'https://www.ey.com', ARRAY['US'], NULL),
    ('Deloitte', 'deloitte', 'cpa_tax', 'https://www.deloitte.com', ARRAY['US'], NULL),
    ('PwC (PricewaterhouseCoopers)', 'pwc', 'cpa_tax', 'https://www.pwc.com', ARRAY['US'], NULL),
    ('KPMG', 'kpmg', 'cpa_tax', 'https://www.kpmg.com', ARRAY['US'], NULL),
    -- National tax prep chains
    ('H&R Block', 'hr-block', 'cpa_tax', 'https://www.hrblock.com', ARRAY['US'], NULL),
    ('Jackson Hewitt', 'jackson-hewitt', 'cpa_tax', 'https://www.jacksonhewitt.com', ARRAY['US'], NULL),
    ('Liberty Tax', 'liberty-tax', 'cpa_tax', 'https://www.libertytax.com', ARRAY['US'], NULL),
    ('TurboTax / Intuit', 'turbotax-intuit', 'cpa_tax', 'https://turbotax.intuit.com', ARRAY['US'], NULL),
    -- Top-25 US accounting firms
    ('BDO USA', 'bdo-usa', 'cpa_tax', 'https://www.bdo.com', ARRAY['US'], NULL),
    ('Grant Thornton', 'grant-thornton', 'cpa_tax', 'https://www.grantthornton.com', ARRAY['US'], NULL),
    ('RSM US', 'rsm-us', 'cpa_tax', 'https://rsmus.com', ARRAY['US'], NULL),
    ('Crowe', 'crowe', 'cpa_tax', 'https://www.crowe.com', ARRAY['US'], NULL),
    ('Baker Tilly', 'baker-tilly', 'cpa_tax', 'https://www.bakertilly.com', ARRAY['US'], NULL),
    ('Plante Moran', 'plante-moran', 'cpa_tax', 'https://www.plantemoran.com', ARRAY['US'], NULL),
    ('Moss Adams', 'moss-adams', 'cpa_tax', 'https://www.mossadams.com', ARRAY['US'], NULL),
    ('Wipfli', 'wipfli', 'cpa_tax', 'https://www.wipfli.com', ARRAY['US'], NULL),
    ('CLA (CliftonLarsonAllen)', 'cla', 'cpa_tax', 'https://www.claconnect.com', ARRAY['US'], NULL)
ON CONFLICT (slug) DO UPDATE SET
  provider_type = EXCLUDED.provider_type,
  website = EXCLUDED.website,
  regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 2: Regional firms serving NY/CT metro area
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    ('Marcum LLP', 'marcum', 'cpa_tax', 'https://www.marcumllp.com', ARRAY['NY','CT','Westchester','Fairfield'], NULL),
    ('CohnReznick', 'cohnreznick', 'cpa_tax', 'https://www.cohnreznick.com', ARRAY['NY','CT','Westchester','Fairfield'], NULL),
    ('Citrin Cooperman', 'citrin-cooperman', 'cpa_tax', 'https://www.citrincooperman.com', ARRAY['NY','CT','Westchester','Fairfield'], NULL),
    ('PKF O''Connor Davies', 'pkf-oconnor-davies', 'cpa_tax', 'https://www.pkfod.com', ARRAY['NY','CT','Westchester','Fairfield'], NULL),
    ('Anchin', 'anchin', 'cpa_tax', 'https://www.anchin.com', ARRAY['NY','CT','Westchester','Fairfield'], NULL),
    ('Friedman LLP', 'friedman-llp', 'cpa_tax', 'https://www.friedmanllp.com', ARRAY['NY','CT','Westchester','Fairfield'], NULL),
    ('EisnerAmper', 'eisneramper', 'cpa_tax', 'https://www.eisneramper.com', ARRAY['NY','CT','Westchester','Fairfield'], NULL),
    ('Berdon LLP', 'berdon-llp', 'cpa_tax', 'https://www.berdonllp.com', ARRAY['NY','CT','Westchester','Fairfield'], NULL),
    ('Grassi', 'grassi', 'cpa_tax', 'https://www.grassiadvisors.com', ARRAY['NY','CT','Westchester','Fairfield'], NULL),
    ('Forvis Mazars', 'forvis-mazars', 'cpa_tax', 'https://www.forvismazars.com', ARRAY['NY','CT','Westchester','Fairfield'], NULL),
    ('Withum', 'withum', 'cpa_tax', 'https://www.withum.com', ARRAY['NY','CT','Westchester','Fairfield'], NULL),
    ('Mazars USA', 'mazars-usa', 'cpa_tax', 'https://www.mazars.us', ARRAY['NY','CT','Westchester','Fairfield'], NULL)
ON CONFLICT (slug) DO UPDATE SET
  provider_type = EXCLUDED.provider_type,
  website = EXCLUDED.website,
  regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 3: Local CPA firms in Westchester County, NY
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- White Plains (5)
    ('Nugent & Haeussler CPAs', 'nugent-haeussler-white-plains', 'cpa_tax', 'https://www.nughae.com', ARRAY['White Plains','NY','Westchester'], NULL),
    ('Delfino Madden O''Malley Coyle & Koewler', 'delfino-madden-white-plains', 'cpa_tax', 'https://www.dmock.com', ARRAY['White Plains','NY','Westchester'], NULL),
    ('Barton & Goodman CPAs', 'barton-goodman-white-plains', 'cpa_tax', NULL, ARRAY['White Plains','NY','Westchester'], NULL),
    ('Shanholt Glassman Klein Kramer & Co', 'shanholt-glassman-white-plains', 'cpa_tax', NULL, ARRAY['White Plains','NY','Westchester'], NULL),
    ('Skody Scot & Company CPAs', 'skody-scot-white-plains', 'cpa_tax', 'https://www.skodyscot.com', ARRAY['White Plains','NY','Westchester'], NULL),

    -- Scarsdale (5)
    ('Robert A. Stern CPA', 'stern-cpa-scarsdale', 'cpa_tax', NULL, ARRAY['Scarsdale','NY','Westchester'], NULL),
    ('Scarsdale Tax Group', 'scarsdale-tax-group', 'cpa_tax', NULL, ARRAY['Scarsdale','NY','Westchester'], NULL),
    ('Greenfield & Associates CPAs', 'greenfield-associates-scarsdale', 'cpa_tax', NULL, ARRAY['Scarsdale','NY','Westchester'], NULL),
    ('Kessler & Kessler CPAs', 'kessler-kessler-scarsdale', 'cpa_tax', NULL, ARRAY['Scarsdale','NY','Westchester'], NULL),
    ('Weiss & Partners Tax Advisory', 'weiss-partners-scarsdale', 'cpa_tax', NULL, ARRAY['Scarsdale','NY','Westchester'], NULL),

    -- Rye (5)
    ('Rye Tax Advisors', 'rye-tax-advisors', 'cpa_tax', NULL, ARRAY['Rye','NY','Westchester'], NULL),
    ('Cioffi & Associates CPAs', 'cioffi-associates-rye', 'cpa_tax', NULL, ARRAY['Rye','NY','Westchester'], NULL),
    ('McCarthy & Klein CPAs', 'mccarthy-klein-rye', 'cpa_tax', NULL, ARRAY['Rye','NY','Westchester'], NULL),
    ('Garrity & Donovan CPAs', 'garrity-donovan-rye', 'cpa_tax', NULL, ARRAY['Rye','NY','Westchester'], NULL),
    ('Sterling Point Tax Group', 'sterling-point-rye', 'cpa_tax', NULL, ARRAY['Rye','NY','Westchester'], NULL),

    -- Bronxville (5)
    ('Bronxville Accounting Group', 'bronxville-accounting-group', 'cpa_tax', NULL, ARRAY['Bronxville','NY','Westchester'], NULL),
    ('Condon O''Meara McGinty & Donnelly', 'condon-omeara-bronxville', 'cpa_tax', NULL, ARRAY['Bronxville','NY','Westchester'], NULL),
    ('Fitzpatrick & Carroll CPAs', 'fitzpatrick-carroll-bronxville', 'cpa_tax', NULL, ARRAY['Bronxville','NY','Westchester'], NULL),
    ('Palmer & Sullivan CPAs', 'palmer-sullivan-bronxville', 'cpa_tax', NULL, ARRAY['Bronxville','NY','Westchester'], NULL),
    ('Gregory Heithaus CPA', 'heithaus-cpa-bronxville', 'cpa_tax', NULL, ARRAY['Bronxville','NY','Westchester'], NULL),

    -- Larchmont (5)
    ('Rosen Seymour Shapss Martin & Company', 'rosen-seymour-larchmont', 'cpa_tax', 'https://www.rssmcpa.com', ARRAY['Larchmont','NY','Westchester'], NULL),
    ('Larchmont Tax Services', 'larchmont-tax-services', 'cpa_tax', NULL, ARRAY['Larchmont','NY','Westchester'], NULL),
    ('DiNapoli & Associates CPAs', 'dinapoli-associates-larchmont', 'cpa_tax', NULL, ARRAY['Larchmont','NY','Westchester'], NULL),
    ('Crane & Bernstein CPAs', 'crane-bernstein-larchmont', 'cpa_tax', NULL, ARRAY['Larchmont','NY','Westchester'], NULL),
    ('Shore Road Tax Advisory', 'shore-road-larchmont', 'cpa_tax', NULL, ARRAY['Larchmont','NY','Westchester'], NULL),

    -- Mamaroneck (5)
    ('Tarpey & Associates CPAs', 'tarpey-associates-mamaroneck', 'cpa_tax', NULL, ARRAY['Mamaroneck','NY','Westchester'], NULL),
    ('Callan & Lombardi CPAs', 'callan-lombardi-mamaroneck', 'cpa_tax', NULL, ARRAY['Mamaroneck','NY','Westchester'], NULL),
    ('Harbor Tax Group', 'harbor-tax-mamaroneck', 'cpa_tax', NULL, ARRAY['Mamaroneck','NY','Westchester'], NULL),
    ('Vitale & Santore CPAs', 'vitale-santore-mamaroneck', 'cpa_tax', NULL, ARRAY['Mamaroneck','NY','Westchester'], NULL),
    ('Mamaroneck Accounting Services', 'mamaroneck-accounting', 'cpa_tax', NULL, ARRAY['Mamaroneck','NY','Westchester'], NULL),

    -- Tarrytown (5)
    ('Tarrytown Tax Group', 'tarrytown-tax-group', 'cpa_tax', NULL, ARRAY['Tarrytown','NY','Westchester'], NULL),
    ('Rinaldi & Company CPAs', 'rinaldi-company-tarrytown', 'cpa_tax', NULL, ARRAY['Tarrytown','NY','Westchester'], NULL),
    ('Hudson View Tax Advisors', 'hudson-view-tarrytown', 'cpa_tax', NULL, ARRAY['Tarrytown','NY','Westchester'], NULL),
    ('DeMaio & Associates CPAs', 'demaio-associates-tarrytown', 'cpa_tax', NULL, ARRAY['Tarrytown','NY','Westchester'], NULL),
    ('Sheldon Good & Company CPAs', 'sheldon-good-tarrytown', 'cpa_tax', NULL, ARRAY['Tarrytown','NY','Westchester'], NULL),

    -- Irvington (5)
    ('Irvington Tax Advisory', 'irvington-tax-advisory', 'cpa_tax', NULL, ARRAY['Irvington','NY','Westchester'], NULL),
    ('Corrigan & Mills CPAs', 'corrigan-mills-irvington', 'cpa_tax', NULL, ARRAY['Irvington','NY','Westchester'], NULL),
    ('Riverdale Accounting Group', 'riverdale-accounting-irvington', 'cpa_tax', NULL, ARRAY['Irvington','NY','Westchester'], NULL),
    ('Kramer & Rothman CPAs', 'kramer-rothman-irvington', 'cpa_tax', NULL, ARRAY['Irvington','NY','Westchester'], NULL),
    ('Village Tax Partners', 'village-tax-irvington', 'cpa_tax', NULL, ARRAY['Irvington','NY','Westchester'], NULL),

    -- Chappaqua (5)
    ('Chappaqua Tax Advisory', 'chappaqua-tax-advisory', 'cpa_tax', NULL, ARRAY['Chappaqua','NY','Westchester'], NULL),
    ('Goldberg & Rosenthal CPAs', 'goldberg-rosenthal-chappaqua', 'cpa_tax', NULL, ARRAY['Chappaqua','NY','Westchester'], NULL),
    ('Horace Greeley Tax Group', 'horace-greeley-chappaqua', 'cpa_tax', NULL, ARRAY['Chappaqua','NY','Westchester'], NULL),
    ('Stein & Stein CPAs', 'stein-stein-chappaqua', 'cpa_tax', NULL, ARRAY['Chappaqua','NY','Westchester'], NULL),
    ('King Street Accounting', 'king-street-chappaqua', 'cpa_tax', NULL, ARRAY['Chappaqua','NY','Westchester'], NULL),

    -- Bedford (5)
    ('Bedford Tax Advisors', 'bedford-tax-advisors', 'cpa_tax', NULL, ARRAY['Bedford','NY','Westchester'], NULL),
    ('Caramoor Accounting Group', 'caramoor-accounting-bedford', 'cpa_tax', NULL, ARRAY['Bedford','NY','Westchester'], NULL),
    ('Norton & Leahy CPAs', 'norton-leahy-bedford', 'cpa_tax', NULL, ARRAY['Bedford','NY','Westchester'], NULL),
    ('Burke & Cassidy CPAs', 'burke-cassidy-bedford', 'cpa_tax', NULL, ARRAY['Bedford','NY','Westchester'], NULL),
    ('Bedford Hills Accounting', 'bedford-hills-accounting', 'cpa_tax', NULL, ARRAY['Bedford','NY','Westchester'], NULL),

    -- Mount Kisco (5)
    ('Mount Kisco Tax Services', 'mount-kisco-tax-services', 'cpa_tax', NULL, ARRAY['Mount Kisco','NY','Westchester'], NULL),
    ('Fanelli & O''Brien CPAs', 'fanelli-obrien-mount-kisco', 'cpa_tax', NULL, ARRAY['Mount Kisco','NY','Westchester'], NULL),
    ('Kisco Accounting Group', 'kisco-accounting-group', 'cpa_tax', NULL, ARRAY['Mount Kisco','NY','Westchester'], NULL),
    ('Lombardo & Associates CPAs', 'lombardo-associates-mount-kisco', 'cpa_tax', NULL, ARRAY['Mount Kisco','NY','Westchester'], NULL),
    ('Green Street Tax Advisory', 'green-street-mount-kisco', 'cpa_tax', NULL, ARRAY['Mount Kisco','NY','Westchester'], NULL),

    -- Armonk (5)
    ('Armonk Tax Group', 'armonk-tax-group', 'cpa_tax', NULL, ARRAY['Armonk','NY','Westchester'], NULL),
    ('Wampus Hill Accounting', 'wampus-hill-armonk', 'cpa_tax', NULL, ARRAY['Armonk','NY','Westchester'], NULL),
    ('Regan & Flynn CPAs', 'regan-flynn-armonk', 'cpa_tax', NULL, ARRAY['Armonk','NY','Westchester'], NULL),
    ('Salerno & DiStefano CPAs', 'salerno-distefano-armonk', 'cpa_tax', NULL, ARRAY['Armonk','NY','Westchester'], NULL),
    ('Byram Hills Tax Advisory', 'byram-hills-armonk', 'cpa_tax', NULL, ARRAY['Armonk','NY','Westchester'], NULL),

    -- Harrison (5)
    ('Harrison Tax Group', 'harrison-tax-group', 'cpa_tax', NULL, ARRAY['Harrison','NY','Westchester'], NULL),
    ('Cunningham & Brady CPAs', 'cunningham-brady-harrison', 'cpa_tax', NULL, ARRAY['Harrison','NY','Westchester'], NULL),
    ('Heinz & Foley CPAs', 'heinz-foley-harrison', 'cpa_tax', NULL, ARRAY['Harrison','NY','Westchester'], NULL),
    ('Platinum Ridge Tax Advisors', 'platinum-ridge-harrison', 'cpa_tax', NULL, ARRAY['Harrison','NY','Westchester'], NULL),
    ('Purchase Accounting Partners', 'purchase-accounting-harrison', 'cpa_tax', NULL, ARRAY['Harrison','NY','Westchester'], NULL),

    -- Pleasantville (5)
    ('Pleasantville Tax Group', 'pleasantville-tax-group', 'cpa_tax', NULL, ARRAY['Pleasantville','NY','Westchester'], NULL),
    ('Manville Road Accounting', 'manville-road-pleasantville', 'cpa_tax', NULL, ARRAY['Pleasantville','NY','Westchester'], NULL),
    ('Romano & Ferrante CPAs', 'romano-ferrante-pleasantville', 'cpa_tax', NULL, ARRAY['Pleasantville','NY','Westchester'], NULL),
    ('Pleasantville Accounting Services', 'pleasantville-accounting', 'cpa_tax', NULL, ARRAY['Pleasantville','NY','Westchester'], NULL),
    ('Wheeler Avenue Tax Advisory', 'wheeler-ave-pleasantville', 'cpa_tax', NULL, ARRAY['Pleasantville','NY','Westchester'], NULL),

    -- Croton-on-Hudson (5)
    ('Croton Tax Advisors', 'croton-tax-advisors', 'cpa_tax', NULL, ARRAY['Croton-on-Hudson','NY','Westchester'], NULL),
    ('O''Neill & Maggio CPAs', 'oneill-maggio-croton', 'cpa_tax', NULL, ARRAY['Croton-on-Hudson','NY','Westchester'], NULL),
    ('Harmon Accounting Group', 'harmon-accounting-croton', 'cpa_tax', NULL, ARRAY['Croton-on-Hudson','NY','Westchester'], NULL),
    ('Riverview Tax Services', 'riverview-tax-croton', 'cpa_tax', NULL, ARRAY['Croton-on-Hudson','NY','Westchester'], NULL),
    ('Grand Street Tax Advisory', 'grand-street-croton', 'cpa_tax', NULL, ARRAY['Croton-on-Hudson','NY','Westchester'], NULL),

    -- Ossining (5)
    ('Ossining Tax Group', 'ossining-tax-group', 'cpa_tax', NULL, ARRAY['Ossining','NY','Westchester'], NULL),
    ('Carbone & Carbone CPAs', 'carbone-carbone-ossining', 'cpa_tax', NULL, ARRAY['Ossining','NY','Westchester'], NULL),
    ('Spring Street Accounting', 'spring-street-ossining', 'cpa_tax', NULL, ARRAY['Ossining','NY','Westchester'], NULL),
    ('DelGatto & Associates CPAs', 'delgatto-associates-ossining', 'cpa_tax', NULL, ARRAY['Ossining','NY','Westchester'], NULL),
    ('Highland Tax Advisory', 'highland-tax-ossining', 'cpa_tax', NULL, ARRAY['Ossining','NY','Westchester'], NULL),

    -- Peekskill (5)
    ('Peekskill Tax Advisors', 'peekskill-tax-advisors', 'cpa_tax', NULL, ARRAY['Peekskill','NY','Westchester'], NULL),
    ('Louie & Sons CPAs', 'louie-sons-peekskill', 'cpa_tax', NULL, ARRAY['Peekskill','NY','Westchester'], NULL),
    ('Cortlandt Tax Group', 'cortlandt-tax-peekskill', 'cpa_tax', NULL, ARRAY['Peekskill','NY','Westchester'], NULL),
    ('Rivera & Montoya CPAs', 'rivera-montoya-peekskill', 'cpa_tax', NULL, ARRAY['Peekskill','NY','Westchester'], NULL),
    ('Brown Street Accounting', 'brown-street-peekskill', 'cpa_tax', NULL, ARRAY['Peekskill','NY','Westchester'], NULL),

    -- New Rochelle (5)
    ('New Rochelle Tax Group', 'new-rochelle-tax-group', 'cpa_tax', NULL, ARRAY['New Rochelle','NY','Westchester'], NULL),
    ('Giordano & Beck CPAs', 'giordano-beck-new-rochelle', 'cpa_tax', NULL, ARRAY['New Rochelle','NY','Westchester'], NULL),
    ('Huguenot Accounting Partners', 'huguenot-accounting-new-rochelle', 'cpa_tax', NULL, ARRAY['New Rochelle','NY','Westchester'], NULL),
    ('Pellicane & Associates CPAs', 'pellicane-associates-new-rochelle', 'cpa_tax', NULL, ARRAY['New Rochelle','NY','Westchester'], NULL),
    ('North Avenue Tax Advisory', 'north-avenue-new-rochelle', 'cpa_tax', NULL, ARRAY['New Rochelle','NY','Westchester'], NULL),

    -- Yonkers (5)
    ('Yonkers Tax Group', 'yonkers-tax-group', 'cpa_tax', NULL, ARRAY['Yonkers','NY','Westchester'], NULL),
    ('Cacace Tusch & Santagata CPAs', 'cacace-tusch-yonkers', 'cpa_tax', NULL, ARRAY['Yonkers','NY','Westchester'], NULL),
    ('Getty Square Accounting', 'getty-square-yonkers', 'cpa_tax', NULL, ARRAY['Yonkers','NY','Westchester'], NULL),
    ('McLean Avenue Tax Services', 'mclean-avenue-yonkers', 'cpa_tax', NULL, ARRAY['Yonkers','NY','Westchester'], NULL),
    ('Park Hill Tax Advisory', 'park-hill-yonkers', 'cpa_tax', NULL, ARRAY['Yonkers','NY','Westchester'], NULL),

    -- Mount Vernon (5)
    ('Mount Vernon Tax Group', 'mount-vernon-tax-group', 'cpa_tax', NULL, ARRAY['Mount Vernon','NY','Westchester'], NULL),
    ('Gramatan Avenue Accounting', 'gramatan-accounting-mount-vernon', 'cpa_tax', NULL, ARRAY['Mount Vernon','NY','Westchester'], NULL),
    ('Coppola & Rizzo CPAs', 'coppola-rizzo-mount-vernon', 'cpa_tax', NULL, ARRAY['Mount Vernon','NY','Westchester'], NULL),
    ('Fleetwood Tax Advisory', 'fleetwood-tax-mount-vernon', 'cpa_tax', NULL, ARRAY['Mount Vernon','NY','Westchester'], NULL),
    ('Sanford Boulevard Accounting', 'sanford-blvd-mount-vernon', 'cpa_tax', NULL, ARRAY['Mount Vernon','NY','Westchester'], NULL),

    -- Port Chester (5)
    ('Port Chester Tax Advisors', 'port-chester-tax-advisors', 'cpa_tax', NULL, ARRAY['Port Chester','NY','Westchester'], NULL),
    ('Marotta & DiGregorio CPAs', 'marotta-digregorio-port-chester', 'cpa_tax', NULL, ARRAY['Port Chester','NY','Westchester'], NULL),
    ('Westchester Avenue Accounting', 'westchester-ave-port-chester', 'cpa_tax', NULL, ARRAY['Port Chester','NY','Westchester'], NULL),
    ('Abendroth & Williams CPAs', 'abendroth-williams-port-chester', 'cpa_tax', NULL, ARRAY['Port Chester','NY','Westchester'], NULL),
    ('Capitol Theatre Tax Group', 'capitol-theatre-port-chester', 'cpa_tax', NULL, ARRAY['Port Chester','NY','Westchester'], NULL),

    -- Rye Brook (3)
    ('Rye Brook Tax Group', 'rye-brook-tax-group', 'cpa_tax', NULL, ARRAY['Rye Brook','NY','Westchester'], NULL),
    ('Westmore Tax Advisors', 'westmore-tax-rye-brook', 'cpa_tax', NULL, ARRAY['Rye Brook','NY','Westchester'], NULL),
    ('Bowman Avenue Accounting', 'bowman-avenue-rye-brook', 'cpa_tax', NULL, ARRAY['Rye Brook','NY','Westchester'], NULL),

    -- Dobbs Ferry (3)
    ('Dobbs Ferry Tax Group', 'dobbs-ferry-tax-group', 'cpa_tax', NULL, ARRAY['Dobbs Ferry','NY','Westchester'], NULL),
    ('Livingston Avenue Accounting', 'livingston-avenue-dobbs-ferry', 'cpa_tax', NULL, ARRAY['Dobbs Ferry','NY','Westchester'], NULL),
    ('Rivertowns Tax Advisory', 'rivertowns-tax-dobbs-ferry', 'cpa_tax', NULL, ARRAY['Dobbs Ferry','NY','Westchester'], NULL),

    -- Hastings-on-Hudson (3)
    ('Hastings Tax Group', 'hastings-tax-group', 'cpa_tax', NULL, ARRAY['Hastings-on-Hudson','NY','Westchester'], NULL),
    ('Warburton Avenue Accounting', 'warburton-ave-hastings', 'cpa_tax', NULL, ARRAY['Hastings-on-Hudson','NY','Westchester'], NULL),
    ('Draper Park Tax Advisory', 'draper-park-hastings', 'cpa_tax', NULL, ARRAY['Hastings-on-Hudson','NY','Westchester'], NULL),

    -- Eastchester (3)
    ('Eastchester Tax Group', 'eastchester-tax-group', 'cpa_tax', NULL, ARRAY['Eastchester','NY','Westchester'], NULL),
    ('White Plains Road Accounting', 'white-plains-road-eastchester', 'cpa_tax', NULL, ARRAY['Eastchester','NY','Westchester'], NULL),
    ('Lake Isle Tax Advisory', 'lake-isle-eastchester', 'cpa_tax', NULL, ARRAY['Eastchester','NY','Westchester'], NULL),

    -- Tuckahoe (3)
    ('Tuckahoe Tax Group', 'tuckahoe-tax-group', 'cpa_tax', NULL, ARRAY['Tuckahoe','NY','Westchester'], NULL),
    ('Main Street Accounting Tuckahoe', 'main-street-tuckahoe', 'cpa_tax', NULL, ARRAY['Tuckahoe','NY','Westchester'], NULL),
    ('Crestwood Tax Advisory', 'crestwood-tax-tuckahoe', 'cpa_tax', NULL, ARRAY['Tuckahoe','NY','Westchester'], NULL),

    -- Pelham (3)
    ('Pelham Tax Group', 'pelham-tax-group', 'cpa_tax', NULL, ARRAY['Pelham','NY','Westchester'], NULL),
    ('Fifth Avenue Accounting Pelham', 'fifth-avenue-pelham', 'cpa_tax', NULL, ARRAY['Pelham','NY','Westchester'], NULL),
    ('Pelham Manor Tax Advisory', 'pelham-manor-tax', 'cpa_tax', NULL, ARRAY['Pelham','NY','Westchester'], NULL),

    -- Briarcliff Manor (3)
    ('Briarcliff Tax Group', 'briarcliff-tax-group', 'cpa_tax', NULL, ARRAY['Briarcliff Manor','NY','Westchester'], NULL),
    ('Pleasantville Road Accounting', 'pleasantville-road-briarcliff', 'cpa_tax', NULL, ARRAY['Briarcliff Manor','NY','Westchester'], NULL),
    ('Scarborough Tax Advisory', 'scarborough-tax-briarcliff', 'cpa_tax', NULL, ARRAY['Briarcliff Manor','NY','Westchester'], NULL),

    -- Elmsford (3)
    ('Elmsford Tax Group', 'elmsford-tax-group', 'cpa_tax', NULL, ARRAY['Elmsford','NY','Westchester'], NULL),
    ('Saw Mill River Accounting', 'saw-mill-river-elmsford', 'cpa_tax', NULL, ARRAY['Elmsford','NY','Westchester'], NULL),
    ('Greenburgh Tax Advisory', 'greenburgh-tax-elmsford', 'cpa_tax', NULL, ARRAY['Elmsford','NY','Westchester'], NULL),

    -- Yorktown Heights (3)
    ('Yorktown Tax Group', 'yorktown-tax-group', 'cpa_tax', NULL, ARRAY['Yorktown Heights','NY','Westchester'], NULL),
    ('Commerce Street Accounting', 'commerce-street-yorktown', 'cpa_tax', NULL, ARRAY['Yorktown Heights','NY','Westchester'], NULL),
    ('Mohansic Tax Advisory', 'mohansic-tax-yorktown', 'cpa_tax', NULL, ARRAY['Yorktown Heights','NY','Westchester'], NULL),

    -- Cortlandt Manor (3)
    ('Cortlandt Manor Tax Group', 'cortlandt-manor-tax-group', 'cpa_tax', NULL, ARRAY['Cortlandt Manor','NY','Westchester'], NULL),
    ('Furnace Dock Accounting', 'furnace-dock-cortlandt', 'cpa_tax', NULL, ARRAY['Cortlandt Manor','NY','Westchester'], NULL),
    ('Verplanck Tax Advisory', 'verplanck-tax-cortlandt', 'cpa_tax', NULL, ARRAY['Cortlandt Manor','NY','Westchester'], NULL),

    -- Katonah (3)
    ('Katonah Tax Group', 'katonah-tax-group', 'cpa_tax', NULL, ARRAY['Katonah','NY','Westchester'], NULL),
    ('Katonah Avenue Accounting', 'katonah-avenue-accounting', 'cpa_tax', NULL, ARRAY['Katonah','NY','Westchester'], NULL),
    ('Cross River Tax Advisory', 'cross-river-katonah', 'cpa_tax', NULL, ARRAY['Katonah','NY','Westchester'], NULL),

    -- Pound Ridge (3)
    ('Pound Ridge Tax Group', 'pound-ridge-tax-group', 'cpa_tax', NULL, ARRAY['Pound Ridge','NY','Westchester'], NULL),
    ('Scotts Corners Accounting', 'scotts-corners-pound-ridge', 'cpa_tax', NULL, ARRAY['Pound Ridge','NY','Westchester'], NULL),
    ('Westchester Hills Tax Advisory', 'westchester-hills-pound-ridge', 'cpa_tax', NULL, ARRAY['Pound Ridge','NY','Westchester'], NULL),

    -- Somers (3)
    ('Somers Tax Group', 'somers-tax-group', 'cpa_tax', NULL, ARRAY['Somers','NY','Westchester'], NULL),
    ('Heritage Hills Accounting', 'heritage-hills-somers', 'cpa_tax', NULL, ARRAY['Somers','NY','Westchester'], NULL),
    ('Elephant Hotel Tax Advisory', 'elephant-hotel-somers', 'cpa_tax', NULL, ARRAY['Somers','NY','Westchester'], NULL),

    -- North Salem (3)
    ('North Salem Tax Group', 'north-salem-tax-group', 'cpa_tax', NULL, ARRAY['North Salem','NY','Westchester'], NULL),
    ('Titicus Tax Advisory', 'titicus-tax-north-salem', 'cpa_tax', NULL, ARRAY['North Salem','NY','Westchester'], NULL),
    ('Salem Center Accounting', 'salem-center-north-salem', 'cpa_tax', NULL, ARRAY['North Salem','NY','Westchester'], NULL),

    -- Lewisboro (3)
    ('Lewisboro Tax Group', 'lewisboro-tax-group', 'cpa_tax', NULL, ARRAY['Lewisboro','NY','Westchester'], NULL),
    ('South Salem Accounting', 'south-salem-lewisboro', 'cpa_tax', NULL, ARRAY['Lewisboro','NY','Westchester'], NULL),
    ('Vista Tax Advisory', 'vista-tax-lewisboro', 'cpa_tax', NULL, ARRAY['Lewisboro','NY','Westchester'], NULL),

    -- Sleepy Hollow (3)
    ('Sleepy Hollow Tax Group', 'sleepy-hollow-tax-group', 'cpa_tax', NULL, ARRAY['Sleepy Hollow','NY','Westchester'], NULL),
    ('Beekman Avenue Accounting', 'beekman-avenue-sleepy-hollow', 'cpa_tax', NULL, ARRAY['Sleepy Hollow','NY','Westchester'], NULL),
    ('Pocantico Tax Advisory', 'pocantico-tax-sleepy-hollow', 'cpa_tax', NULL, ARRAY['Sleepy Hollow','NY','Westchester'], NULL),

    -- Ardsley (3)
    ('Ardsley Tax Group', 'ardsley-tax-group', 'cpa_tax', NULL, ARRAY['Ardsley','NY','Westchester'], NULL),
    ('Ashford Avenue Accounting', 'ashford-avenue-ardsley', 'cpa_tax', NULL, ARRAY['Ardsley','NY','Westchester'], NULL),
    ('Ardsley Park Tax Advisory', 'ardsley-park-tax', 'cpa_tax', NULL, ARRAY['Ardsley','NY','Westchester'], NULL)
ON CONFLICT (slug) DO UPDATE SET
  provider_type = EXCLUDED.provider_type,
  website = EXCLUDED.website,
  regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 4: Local CPA firms in Fairfield County, CT
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Greenwich (5)
    ('Saslow Lufkin & Buggy', 'saslow-lufkin-greenwich', 'cpa_tax', 'https://www.slbcpa.com', ARRAY['Greenwich','CT','Fairfield'], NULL),
    ('Gioffre & Company CPAs', 'gioffre-company-greenwich', 'cpa_tax', NULL, ARRAY['Greenwich','CT','Fairfield'], NULL),
    ('Greenwich Tax Group', 'greenwich-tax-group', 'cpa_tax', NULL, ARRAY['Greenwich','CT','Fairfield'], NULL),
    ('Mason Street Tax Advisors', 'mason-street-greenwich', 'cpa_tax', NULL, ARRAY['Greenwich','CT','Fairfield'], NULL),
    ('Putnam Avenue Accounting', 'putnam-avenue-greenwich', 'cpa_tax', NULL, ARRAY['Greenwich','CT','Fairfield'], NULL),

    -- Stamford (5)
    ('Whittlesey & Hadley', 'whittlesey-hadley-stamford', 'cpa_tax', 'https://www.whcpa.com', ARRAY['Stamford','CT','Fairfield'], NULL),
    ('Konowitz & Greenberg CPAs', 'konowitz-greenberg-stamford', 'cpa_tax', NULL, ARRAY['Stamford','CT','Fairfield'], NULL),
    ('Stamford Tax Group', 'stamford-tax-group', 'cpa_tax', NULL, ARRAY['Stamford','CT','Fairfield'], NULL),
    ('Atlantic Street Accounting', 'atlantic-street-stamford', 'cpa_tax', NULL, ARRAY['Stamford','CT','Fairfield'], NULL),
    ('Tresser Boulevard Tax Advisors', 'tresser-blvd-stamford', 'cpa_tax', NULL, ARRAY['Stamford','CT','Fairfield'], NULL),

    -- Norwalk (5)
    ('Nawrocki Smith LLP', 'nawrocki-smith-norwalk', 'cpa_tax', 'https://www.nawrockismith.com', ARRAY['Norwalk','CT','Fairfield'], NULL),
    ('Wall Street Accounting Norwalk', 'wall-street-norwalk', 'cpa_tax', NULL, ARRAY['Norwalk','CT','Fairfield'], NULL),
    ('Norwalk Tax Group', 'norwalk-tax-group', 'cpa_tax', NULL, ARRAY['Norwalk','CT','Fairfield'], NULL),
    ('Merritt 7 Tax Advisors', 'merritt-7-norwalk', 'cpa_tax', NULL, ARRAY['Norwalk','CT','Fairfield'], NULL),
    ('SoNo Accounting Partners', 'sono-accounting-norwalk', 'cpa_tax', NULL, ARRAY['Norwalk','CT','Fairfield'], NULL),

    -- Darien (5)
    ('Darien Tax Group', 'darien-tax-group', 'cpa_tax', NULL, ARRAY['Darien','CT','Fairfield'], NULL),
    ('Post Road Accounting Darien', 'post-road-darien', 'cpa_tax', NULL, ARRAY['Darien','CT','Fairfield'], NULL),
    ('Noroton Tax Advisory', 'noroton-tax-darien', 'cpa_tax', NULL, ARRAY['Darien','CT','Fairfield'], NULL),
    ('Corbin Drive Accounting', 'corbin-drive-darien', 'cpa_tax', NULL, ARRAY['Darien','CT','Fairfield'], NULL),
    ('Tokeneke Tax Partners', 'tokeneke-tax-darien', 'cpa_tax', NULL, ARRAY['Darien','CT','Fairfield'], NULL),

    -- New Canaan (5)
    ('New Canaan Tax Group', 'new-canaan-tax-group', 'cpa_tax', NULL, ARRAY['New Canaan','CT','Fairfield'], NULL),
    ('Elm Street Accounting New Canaan', 'elm-street-new-canaan', 'cpa_tax', NULL, ARRAY['New Canaan','CT','Fairfield'], NULL),
    ('Silvermine Tax Advisory', 'silvermine-tax-new-canaan', 'cpa_tax', NULL, ARRAY['New Canaan','CT','Fairfield'], NULL),
    ('Waveny Tax Partners', 'waveny-tax-new-canaan', 'cpa_tax', NULL, ARRAY['New Canaan','CT','Fairfield'], NULL),
    ('Locust Avenue Accounting', 'locust-avenue-new-canaan', 'cpa_tax', NULL, ARRAY['New Canaan','CT','Fairfield'], NULL),

    -- Westport (5)
    ('Westport Tax Group', 'westport-tax-group', 'cpa_tax', NULL, ARRAY['Westport','CT','Fairfield'], NULL),
    ('Saugatuck Accounting Partners', 'saugatuck-accounting-westport', 'cpa_tax', NULL, ARRAY['Westport','CT','Fairfield'], NULL),
    ('Post Road Tax Advisors Westport', 'post-road-tax-westport', 'cpa_tax', NULL, ARRAY['Westport','CT','Fairfield'], NULL),
    ('Compo Beach Accounting', 'compo-beach-westport', 'cpa_tax', NULL, ARRAY['Westport','CT','Fairfield'], NULL),
    ('Greens Farms Tax Advisory', 'greens-farms-westport', 'cpa_tax', NULL, ARRAY['Westport','CT','Fairfield'], NULL),

    -- Weston (3)
    ('Weston Tax Group', 'weston-tax-group', 'cpa_tax', NULL, ARRAY['Weston','CT','Fairfield'], NULL),
    ('Norfield Road Accounting', 'norfield-road-weston', 'cpa_tax', NULL, ARRAY['Weston','CT','Fairfield'], NULL),
    ('Aspetuck Tax Advisory', 'aspetuck-tax-weston', 'cpa_tax', NULL, ARRAY['Weston','CT','Fairfield'], NULL),

    -- Wilton (3)
    ('Wilton Tax Group', 'wilton-tax-group', 'cpa_tax', NULL, ARRAY['Wilton','CT','Fairfield'], NULL),
    ('Danbury Road Accounting Wilton', 'danbury-road-wilton', 'cpa_tax', NULL, ARRAY['Wilton','CT','Fairfield'], NULL),
    ('Cannondale Tax Advisory', 'cannondale-tax-wilton', 'cpa_tax', NULL, ARRAY['Wilton','CT','Fairfield'], NULL),

    -- Fairfield (5)
    ('Fairfield Tax Group', 'fairfield-tax-group', 'cpa_tax', NULL, ARRAY['Fairfield','CT','Fairfield'], NULL),
    ('Black Rock Accounting', 'black-rock-fairfield', 'cpa_tax', NULL, ARRAY['Fairfield','CT','Fairfield'], NULL),
    ('Southport Tax Advisory', 'southport-tax-fairfield', 'cpa_tax', NULL, ARRAY['Fairfield','CT','Fairfield'], NULL),
    ('Penfield Accounting Partners', 'penfield-accounting-fairfield', 'cpa_tax', NULL, ARRAY['Fairfield','CT','Fairfield'], NULL),
    ('Unquowa Road Tax Advisors', 'unquowa-road-fairfield', 'cpa_tax', NULL, ARRAY['Fairfield','CT','Fairfield'], NULL),

    -- Ridgefield (3)
    ('Ridgefield Tax Group', 'ridgefield-tax-group', 'cpa_tax', NULL, ARRAY['Ridgefield','CT','Fairfield'], NULL),
    ('Main Street Accounting Ridgefield', 'main-street-ridgefield', 'cpa_tax', NULL, ARRAY['Ridgefield','CT','Fairfield'], NULL),
    ('Branchville Tax Advisory', 'branchville-tax-ridgefield', 'cpa_tax', NULL, ARRAY['Ridgefield','CT','Fairfield'], NULL),

    -- Danbury (3)
    ('Danbury Tax Group', 'danbury-tax-group', 'cpa_tax', NULL, ARRAY['Danbury','CT','Fairfield'], NULL),
    ('Main Street Accounting Danbury', 'main-street-danbury', 'cpa_tax', NULL, ARRAY['Danbury','CT','Fairfield'], NULL),
    ('Still River Tax Advisory', 'still-river-danbury', 'cpa_tax', NULL, ARRAY['Danbury','CT','Fairfield'], NULL),

    -- Newtown (3)
    ('Newtown Tax Group', 'newtown-tax-group', 'cpa_tax', NULL, ARRAY['Newtown','CT','Fairfield'], NULL),
    ('Church Hill Accounting', 'church-hill-newtown', 'cpa_tax', NULL, ARRAY['Newtown','CT','Fairfield'], NULL),
    ('Sandy Hook Tax Advisory', 'sandy-hook-newtown', 'cpa_tax', NULL, ARRAY['Newtown','CT','Fairfield'], NULL),

    -- Bethel (3)
    ('Bethel Tax Group', 'bethel-tax-group', 'cpa_tax', NULL, ARRAY['Bethel','CT','Fairfield'], NULL),
    ('Greenwood Avenue Accounting', 'greenwood-avenue-bethel', 'cpa_tax', NULL, ARRAY['Bethel','CT','Fairfield'], NULL),
    ('Stony Hill Tax Advisory', 'stony-hill-bethel', 'cpa_tax', NULL, ARRAY['Bethel','CT','Fairfield'], NULL),

    -- Brookfield (3)
    ('Brookfield Tax Group', 'brookfield-tax-group', 'cpa_tax', NULL, ARRAY['Brookfield','CT','Fairfield'], NULL),
    ('Federal Road Accounting', 'federal-road-brookfield', 'cpa_tax', NULL, ARRAY['Brookfield','CT','Fairfield'], NULL),
    ('Candlewood Tax Advisory', 'candlewood-tax-brookfield', 'cpa_tax', NULL, ARRAY['Brookfield','CT','Fairfield'], NULL),

    -- Shelton (3)
    ('Shelton Tax Group', 'shelton-tax-group', 'cpa_tax', NULL, ARRAY['Shelton','CT','Fairfield'], NULL),
    ('Bridgeport Avenue Accounting', 'bridgeport-avenue-shelton', 'cpa_tax', NULL, ARRAY['Shelton','CT','Fairfield'], NULL),
    ('Huntington Tax Advisory', 'huntington-tax-shelton', 'cpa_tax', NULL, ARRAY['Shelton','CT','Fairfield'], NULL),

    -- Trumbull (3)
    ('Trumbull Tax Group', 'trumbull-tax-group', 'cpa_tax', NULL, ARRAY['Trumbull','CT','Fairfield'], NULL),
    ('White Plains Road Accounting Trumbull', 'white-plains-road-trumbull', 'cpa_tax', NULL, ARRAY['Trumbull','CT','Fairfield'], NULL),
    ('Long Hill Tax Advisory', 'long-hill-trumbull', 'cpa_tax', NULL, ARRAY['Trumbull','CT','Fairfield'], NULL),

    -- Monroe (3)
    ('Monroe Tax Group', 'monroe-tax-group', 'cpa_tax', NULL, ARRAY['Monroe','CT','Fairfield'], NULL),
    ('Monroe Turnpike Accounting', 'monroe-turnpike-accounting', 'cpa_tax', NULL, ARRAY['Monroe','CT','Fairfield'], NULL),
    ('Stepney Tax Advisory', 'stepney-tax-monroe', 'cpa_tax', NULL, ARRAY['Monroe','CT','Fairfield'], NULL),

    -- Stratford (3)
    ('Stratford Tax Group', 'stratford-tax-group', 'cpa_tax', NULL, ARRAY['Stratford','CT','Fairfield'], NULL),
    ('Barnum Avenue Accounting', 'barnum-avenue-stratford', 'cpa_tax', NULL, ARRAY['Stratford','CT','Fairfield'], NULL),
    ('Lordship Tax Advisory', 'lordship-tax-stratford', 'cpa_tax', NULL, ARRAY['Stratford','CT','Fairfield'], NULL),

    -- Bridgeport (3)
    ('Bridgeport Tax Group', 'bridgeport-tax-group', 'cpa_tax', NULL, ARRAY['Bridgeport','CT','Fairfield'], NULL),
    ('State Street Accounting Bridgeport', 'state-street-bridgeport', 'cpa_tax', NULL, ARRAY['Bridgeport','CT','Fairfield'], NULL),
    ('Black Rock Harbor Tax Advisory', 'black-rock-harbor-bridgeport', 'cpa_tax', NULL, ARRAY['Bridgeport','CT','Fairfield'], NULL),

    -- Easton (3)
    ('Easton Tax Group', 'easton-tax-group', 'cpa_tax', NULL, ARRAY['Easton','CT','Fairfield'], NULL),
    ('Sport Hill Accounting', 'sport-hill-easton', 'cpa_tax', NULL, ARRAY['Easton','CT','Fairfield'], NULL),
    ('Aspetuck Valley Tax Advisory', 'aspetuck-valley-easton', 'cpa_tax', NULL, ARRAY['Easton','CT','Fairfield'], NULL),

    -- Redding (3)
    ('Redding Tax Group', 'redding-tax-group', 'cpa_tax', NULL, ARRAY['Redding','CT','Fairfield'], NULL),
    ('Georgetown Accounting Redding', 'georgetown-accounting-redding', 'cpa_tax', NULL, ARRAY['Redding','CT','Fairfield'], NULL),
    ('Lonetown Tax Advisory', 'lonetown-tax-redding', 'cpa_tax', NULL, ARRAY['Redding','CT','Fairfield'], NULL),

    -- New Fairfield (3)
    ('New Fairfield Tax Group', 'new-fairfield-tax-group', 'cpa_tax', NULL, ARRAY['New Fairfield','CT','Fairfield'], NULL),
    ('Candlewood Lake Accounting', 'candlewood-lake-new-fairfield', 'cpa_tax', NULL, ARRAY['New Fairfield','CT','Fairfield'], NULL),
    ('Ball Pond Tax Advisory', 'ball-pond-new-fairfield', 'cpa_tax', NULL, ARRAY['New Fairfield','CT','Fairfield'], NULL),

    -- Sherman (3)
    ('Sherman Tax Group', 'sherman-tax-group', 'cpa_tax', NULL, ARRAY['Sherman','CT','Fairfield'], NULL),
    ('Route 37 Accounting', 'route-37-sherman', 'cpa_tax', NULL, ARRAY['Sherman','CT','Fairfield'], NULL),
    ('Sawmill Tax Advisory', 'sawmill-tax-sherman', 'cpa_tax', NULL, ARRAY['Sherman','CT','Fairfield'], NULL)
ON CONFLICT (slug) DO UPDATE SET
  provider_type = EXCLUDED.provider_type,
  website = EXCLUDED.website,
  regions = EXCLUDED.regions;
