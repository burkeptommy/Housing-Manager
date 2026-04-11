-- Seed CPA and tax advisory firms into utility_providers table for Massachusetts.
-- Covers 4 counties: Essex, Middlesex, Norfolk, Plymouth.
-- Section 1: Major MA regional CPA/accounting firms (statewide)
-- Section 2: Local CPA firms in Essex County, MA (33 towns)
-- Section 3: Local CPA firms in Middlesex County, MA (54 towns)
-- Section 4: Local CPA firms in Norfolk County, MA (27 towns)
-- Section 5: Local CPA firms in Plymouth County, MA (27 towns)
-- provider_type = 'cpa_tax', logo_url = NULL (resolved at runtime via Brandfetch).
-- Slug convention: ma-[firm]-[town] for local firms to avoid collision with NY/CT seeds.

-- ============================================================
-- SECTION 1: Major MA regional CPA/accounting firms
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    ('Wolf & Company PC', 'wolf-company-ma', 'cpa_tax', 'https://www.wolfandco.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Marcum LLP (Boston)', 'marcum-ma', 'cpa_tax', 'https://www.marcumllp.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('CohnReznick LLP (Boston)', 'cohnreznick-ma', 'cpa_tax', 'https://www.cohnreznick.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Citrin Cooperman (Boston)', 'citrin-cooperman-ma', 'cpa_tax', 'https://www.citrincooperman.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Baker Newman Noyes', 'baker-newman-noyes', 'cpa_tax', 'https://www.bnncpa.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('AAFCPAs', 'aafcpas', 'cpa_tax', 'https://www.aafcpa.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('KPM Advisory', 'kpm-advisory-ma', 'cpa_tax', 'https://www.kpmadvisory.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Insero & Co.', 'insero-co-ma', 'cpa_tax', 'https://www.inserocpa.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Edelstein & Company LLP', 'edelstein-company', 'cpa_tax', 'https://www.edelsteincpa.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('BlumShapiro', 'blumshapiro-ma', 'cpa_tax', 'https://www.blumshapiro.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('O''Connor & Drew PC', 'oconnor-drew', 'cpa_tax', 'https://www.ocd.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Feeley & Driscoll PC', 'feeley-driscoll', 'cpa_tax', 'https://www.fdcpa.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Tonneson + Co', 'tonneson-co', 'cpa_tax', 'https://www.tonneson.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Sullivan Bille PC', 'sullivan-bille', 'cpa_tax', 'https://www.sullivanbille.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Parent McLaughlin & Nangle', 'parent-mclaughlin-nangle', 'cpa_tax', 'https://www.pmncpa.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Gray Gray & Gray LLP', 'gray-gray-gray', 'cpa_tax', 'https://www.ggg.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('DiCicco Gulman & Company LLP', 'dicicco-gulman', 'cpa_tax', 'https://www.dgccpa.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('PKF O''Connor Davies (Boston)', 'pkf-oconnor-davies-ma', 'cpa_tax', 'https://www.pkfod.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 2: Local CPA firms in Essex County, MA
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Andover (5 - HNW)
    ('Sullivan & Walsh CPAs', 'ma-sullivan-walsh-andover', 'cpa_tax', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Andover Tax Advisors', 'ma-andover-tax-advisors', 'cpa_tax', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Brennan & Cole CPA PC', 'ma-brennan-cole-andover', 'cpa_tax', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Merrimack Valley Accounting Group', 'ma-merrimack-valley-accounting-andover', 'cpa_tax', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Doherty & McKenzie CPAs', 'ma-doherty-mckenzie-andover', 'cpa_tax', NULL, ARRAY['Andover','MA','Essex'], NULL),

    -- Beverly (5 - HNW)
    ('Beverly Tax Group', 'ma-beverly-tax-group', 'cpa_tax', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Harrington & Sands CPAs', 'ma-harrington-sands-beverly', 'cpa_tax', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('North Shore Accounting Partners', 'ma-north-shore-accounting-beverly', 'cpa_tax', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Callahan & Reeves CPA PC', 'ma-callahan-reeves-beverly', 'cpa_tax', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Cabot Street Tax Advisors', 'ma-cabot-street-beverly', 'cpa_tax', NULL, ARRAY['Beverly','MA','Essex'], NULL),

    -- Boxford (5 - HNW)
    ('Boxford Tax Advisory', 'ma-boxford-tax-advisory', 'cpa_tax', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Kelleher & Fontaine CPAs', 'ma-kelleher-fontaine-boxford', 'cpa_tax', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Georgetown Road Accounting', 'ma-georgetown-rd-accounting-boxford', 'cpa_tax', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Perkins & Hale CPA PC', 'ma-perkins-hale-boxford', 'cpa_tax', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Boxford Financial Services', 'ma-boxford-financial-services', 'cpa_tax', NULL, ARRAY['Boxford','MA','Essex'], NULL),

    -- Danvers (3)
    ('Danvers Accounting Group', 'ma-danvers-accounting-group', 'cpa_tax', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Petralia & Son CPAs', 'ma-petralia-son-danvers', 'cpa_tax', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Putnam Lane Tax Services', 'ma-putnam-lane-danvers', 'cpa_tax', NULL, ARRAY['Danvers','MA','Essex'], NULL),

    -- Essex (3)
    ('Essex Tax Services', 'ma-essex-tax-services', 'cpa_tax', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Conomo Point Accounting', 'ma-conomo-point-essex', 'cpa_tax', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Burnham & Choate CPAs', 'ma-burnham-choate-essex', 'cpa_tax', NULL, ARRAY['Essex','MA','Essex'], NULL),

    -- Georgetown (3)
    ('Georgetown Tax Advisors', 'ma-georgetown-tax-advisors', 'cpa_tax', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Thurlow & Keane CPAs', 'ma-thurlow-keane-georgetown', 'cpa_tax', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Parker River Accounting', 'ma-parker-river-georgetown', 'cpa_tax', NULL, ARRAY['Georgetown','MA','Essex'], NULL),

    -- Gloucester (3)
    ('Gloucester Accounting Group', 'ma-gloucester-accounting-group', 'cpa_tax', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Cape Ann Tax Advisors', 'ma-cape-ann-tax-gloucester', 'cpa_tax', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Favazza & Rallo CPAs', 'ma-favazza-rallo-gloucester', 'cpa_tax', NULL, ARRAY['Gloucester','MA','Essex'], NULL),

    -- Groveland (3)
    ('Groveland Tax Services', 'ma-groveland-tax-services', 'cpa_tax', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Pentucket Accounting Group', 'ma-pentucket-accounting-groveland', 'cpa_tax', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Batchelder & Cross CPAs', 'ma-batchelder-cross-groveland', 'cpa_tax', NULL, ARRAY['Groveland','MA','Essex'], NULL),

    -- Hamilton (5 - HNW)
    ('Hamilton Tax Advisory', 'ma-hamilton-tax-advisory', 'cpa_tax', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Appleton & Dodge CPAs', 'ma-appleton-dodge-hamilton', 'cpa_tax', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Chebacco Accounting Group', 'ma-chebacco-accounting-hamilton', 'cpa_tax', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Patton & Cutler CPA PC', 'ma-patton-cutler-hamilton', 'cpa_tax', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Bay Road Financial Services', 'ma-bay-road-financial-hamilton', 'cpa_tax', NULL, ARRAY['Hamilton','MA','Essex'], NULL),

    -- Haverhill (3)
    ('Haverhill Tax Group', 'ma-haverhill-tax-group', 'cpa_tax', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Tattersall & Flynn CPAs', 'ma-tattersall-flynn-haverhill', 'cpa_tax', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Bradford Accounting Services', 'ma-bradford-accounting-haverhill', 'cpa_tax', NULL, ARRAY['Haverhill','MA','Essex'], NULL),

    -- Ipswich (5 - HNW)
    ('Ipswich Tax Advisors', 'ma-ipswich-tax-advisors', 'cpa_tax', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Heard & Farley CPAs', 'ma-heard-farley-ipswich', 'cpa_tax', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Crane Beach Accounting Group', 'ma-crane-beach-accounting-ipswich', 'cpa_tax', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Peatfield & Ross CPA PC', 'ma-peatfield-ross-ipswich', 'cpa_tax', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Argilla Road Tax Advisory', 'ma-argilla-road-ipswich', 'cpa_tax', NULL, ARRAY['Ipswich','MA','Essex'], NULL),

    -- Lawrence (3)
    ('Lawrence Tax Services', 'ma-lawrence-tax-services', 'cpa_tax', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Reilly & Marquez CPAs', 'ma-reilly-marquez-lawrence', 'cpa_tax', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Merrimack Accounting Group', 'ma-merrimack-accounting-lawrence', 'cpa_tax', NULL, ARRAY['Lawrence','MA','Essex'], NULL),

    -- Lynn (3)
    ('Lynn Accounting Group', 'ma-lynn-accounting-group', 'cpa_tax', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Sheehan & Driscoll CPAs', 'ma-sheehan-driscoll-lynn', 'cpa_tax', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Nahant Street Tax Services', 'ma-nahant-street-lynn', 'cpa_tax', NULL, ARRAY['Lynn','MA','Essex'], NULL),

    -- Lynnfield (5 - HNW)
    ('Lynnfield Tax Advisors', 'ma-lynnfield-tax-advisors', 'cpa_tax', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Saunders & Kimball CPAs', 'ma-saunders-kimball-lynnfield', 'cpa_tax', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Market Street Accounting Group', 'ma-market-street-accounting-lynnfield', 'cpa_tax', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Connolly & Pratt CPA PC', 'ma-connolly-pratt-lynnfield', 'cpa_tax', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Lynnfield Financial Services', 'ma-lynnfield-financial-services', 'cpa_tax', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),

    -- Manchester-by-the-Sea (5 - HNW)
    ('Manchester Tax Advisory', 'ma-manchester-tax-advisory', 'cpa_tax', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Tuck & Boardman CPAs', 'ma-tuck-boardman-manchester', 'cpa_tax', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Singing Beach Accounting', 'ma-singing-beach-accounting-manchester', 'cpa_tax', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Proctor & Hale CPA PC', 'ma-proctor-hale-manchester', 'cpa_tax', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Harbor View Tax Group', 'ma-harbor-view-manchester', 'cpa_tax', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),

    -- Marblehead (5 - HNW)
    ('Marblehead Tax Advisors', 'ma-marblehead-tax-advisors', 'cpa_tax', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Orne & Stacey CPAs', 'ma-orne-stacey-marblehead', 'cpa_tax', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Old Town Accounting Group', 'ma-old-town-accounting-marblehead', 'cpa_tax', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Peach & Devereaux CPA PC', 'ma-peach-devereaux-marblehead', 'cpa_tax', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Marblehead Neck Tax Advisory', 'ma-marblehead-neck-tax', 'cpa_tax', NULL, ARRAY['Marblehead','MA','Essex'], NULL),

    -- Merrimac (3)
    ('Merrimac Tax Services', 'ma-merrimac-tax-services', 'cpa_tax', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Sargent & Church CPAs', 'ma-sargent-church-merrimac', 'cpa_tax', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Lake Attitash Accounting', 'ma-lake-attitash-merrimac', 'cpa_tax', NULL, ARRAY['Merrimac','MA','Essex'], NULL),

    -- Methuen (3)
    ('Methuen Accounting Group', 'ma-methuen-accounting-group', 'cpa_tax', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Donovan & Pelletier CPAs', 'ma-donovan-pelletier-methuen', 'cpa_tax', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Pleasant Valley Tax Services', 'ma-pleasant-valley-methuen', 'cpa_tax', NULL, ARRAY['Methuen','MA','Essex'], NULL),

    -- Middleton (3)
    ('Middleton Tax Group', 'ma-middleton-tax-group', 'cpa_tax', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Ferncroft Accounting Services', 'ma-ferncroft-accounting-middleton', 'cpa_tax', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Fuller & Howe CPAs', 'ma-fuller-howe-middleton', 'cpa_tax', NULL, ARRAY['Middleton','MA','Essex'], NULL),

    -- Nahant (3)
    ('Nahant Tax Advisory', 'ma-nahant-tax-advisory', 'cpa_tax', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Lodge & Wharf Accounting', 'ma-lodge-wharf-nahant', 'cpa_tax', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Tudor & Breed CPAs', 'ma-tudor-breed-nahant', 'cpa_tax', NULL, ARRAY['Nahant','MA','Essex'], NULL),

    -- Newbury (3)
    ('Newbury Tax Services', 'ma-newbury-tax-services', 'cpa_tax', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Parker River Tax Advisors', 'ma-parker-river-tax-newbury', 'cpa_tax', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Coffin & Plummer CPAs', 'ma-coffin-plummer-newbury', 'cpa_tax', NULL, ARRAY['Newbury','MA','Essex'], NULL),

    -- Newburyport (5 - HNW)
    ('Newburyport Tax Advisors', 'ma-newburyport-tax-advisors', 'cpa_tax', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Hale & Noyes CPAs', 'ma-hale-noyes-newburyport', 'cpa_tax', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Clipper City Accounting Group', 'ma-clipper-city-accounting-newburyport', 'cpa_tax', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Cushing & Knapp CPA PC', 'ma-cushing-knapp-newburyport', 'cpa_tax', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Plum Island Tax Advisory', 'ma-plum-island-newburyport', 'cpa_tax', NULL, ARRAY['Newburyport','MA','Essex'], NULL),

    -- North Andover (5 - HNW)
    ('North Andover Tax Group', 'ma-north-andover-tax-group', 'cpa_tax', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Prescott & Osgood CPAs', 'ma-prescott-osgood-north-andover', 'cpa_tax', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Lake Cochichewick Accounting', 'ma-lake-cochichewick-north-andover', 'cpa_tax', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Farnum & Stevens CPA PC', 'ma-farnum-stevens-north-andover', 'cpa_tax', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('North Andover Financial Services', 'ma-north-andover-financial', 'cpa_tax', NULL, ARRAY['North Andover','MA','Essex'], NULL),

    -- Peabody (3)
    ('Peabody Accounting Group', 'ma-peabody-accounting-group', 'cpa_tax', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Osborne & Sutton CPAs', 'ma-osborne-sutton-peabody', 'cpa_tax', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Northshore Mall Tax Services', 'ma-northshore-tax-peabody', 'cpa_tax', NULL, ARRAY['Peabody','MA','Essex'], NULL),

    -- Rockport (3)
    ('Rockport Tax Services', 'ma-rockport-tax-services', 'cpa_tax', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Bearskin Neck Accounting', 'ma-bearskin-neck-rockport', 'cpa_tax', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Tarr & Poole CPAs', 'ma-tarr-poole-rockport', 'cpa_tax', NULL, ARRAY['Rockport','MA','Essex'], NULL),

    -- Rowley (3)
    ('Rowley Tax Advisors', 'ma-rowley-tax-advisors', 'cpa_tax', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Bradford & Gage CPAs', 'ma-bradford-gage-rowley', 'cpa_tax', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Glen Mills Accounting', 'ma-glen-mills-rowley', 'cpa_tax', NULL, ARRAY['Rowley','MA','Essex'], NULL),

    -- Salem (5 - HNW)
    ('Salem Tax Advisors', 'ma-salem-tax-advisors', 'cpa_tax', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Derby & Pickering CPAs', 'ma-derby-pickering-salem', 'cpa_tax', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Chestnut Street Accounting Group', 'ma-chestnut-street-accounting-salem', 'cpa_tax', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Hawthorne & Peabody CPA PC', 'ma-hawthorne-peabody-salem', 'cpa_tax', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('McIntire District Tax Advisory', 'ma-mcintire-district-salem', 'cpa_tax', NULL, ARRAY['Salem','MA','Essex'], NULL),

    -- Salisbury (3)
    ('Salisbury Tax Services', 'ma-salisbury-tax-services', 'cpa_tax', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Ring & Ferry CPAs', 'ma-ring-ferry-salisbury', 'cpa_tax', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Beach Road Accounting', 'ma-beach-road-salisbury', 'cpa_tax', NULL, ARRAY['Salisbury','MA','Essex'], NULL),

    -- Saugus (3)
    ('Saugus Accounting Group', 'ma-saugus-accounting-group', 'cpa_tax', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Fiske & Hawkes CPAs', 'ma-fiske-hawkes-saugus', 'cpa_tax', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Route One Tax Services', 'ma-route-one-saugus', 'cpa_tax', NULL, ARRAY['Saugus','MA','Essex'], NULL),

    -- Swampscott (5 - HNW)
    ('Swampscott Tax Advisors', 'ma-swampscott-tax-advisors', 'cpa_tax', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Blaney & Phillips CPAs', 'ma-blaney-phillips-swampscott', 'cpa_tax', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Monument Avenue Accounting', 'ma-monument-ave-accounting-swampscott', 'cpa_tax', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Ingalls & Humphrey CPA PC', 'ma-ingalls-humphrey-swampscott', 'cpa_tax', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Fishermans Beach Tax Group', 'ma-fishermans-beach-swampscott', 'cpa_tax', NULL, ARRAY['Swampscott','MA','Essex'], NULL),

    -- Topsfield (5 - HNW)
    ('Topsfield Tax Advisory', 'ma-topsfield-tax-advisory', 'cpa_tax', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Perkins & Emerson CPAs', 'ma-perkins-emerson-topsfield', 'cpa_tax', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Topsfield Common Accounting', 'ma-topsfield-common-accounting', 'cpa_tax', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Capen & Gould CPA PC', 'ma-capen-gould-topsfield', 'cpa_tax', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Rowley Bridge Tax Group', 'ma-rowley-bridge-topsfield', 'cpa_tax', NULL, ARRAY['Topsfield','MA','Essex'], NULL),

    -- Wenham (5 - HNW)
    ('Wenham Tax Advisory', 'ma-wenham-tax-advisory', 'cpa_tax', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Fiske & Endicott CPAs', 'ma-fiske-endicott-wenham', 'cpa_tax', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Gordon College Road Accounting', 'ma-gordon-college-rd-wenham', 'cpa_tax', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Pleasant Pond Tax Group', 'ma-pleasant-pond-wenham', 'cpa_tax', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Wenham Financial Services', 'ma-wenham-financial-services', 'cpa_tax', NULL, ARRAY['Wenham','MA','Essex'], NULL),

    -- West Newbury (3)
    ('West Newbury Tax Services', 'ma-west-newbury-tax-services', 'cpa_tax', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('Chase & Ilsley CPAs', 'ma-chase-ilsley-west-newbury', 'cpa_tax', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('Indian Hill Accounting', 'ma-indian-hill-west-newbury', 'cpa_tax', NULL, ARRAY['West Newbury','MA','Essex'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 3: Local CPA firms in Middlesex County, MA
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Acton (3)
    ('Acton Tax Advisors', 'ma-acton-tax-advisors', 'cpa_tax', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Nagog & Wheeler CPAs', 'ma-nagog-wheeler-acton', 'cpa_tax', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Great Road Accounting Group', 'ma-great-road-accounting-acton', 'cpa_tax', NULL, ARRAY['Acton','MA','Middlesex'], NULL),

    -- Arlington (5 - HNW)
    ('Arlington Tax Advisors', 'ma-arlington-tax-advisors', 'cpa_tax', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Crosby & Whittemore CPAs', 'ma-crosby-whittemore-arlington', 'cpa_tax', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Massachusetts Avenue Accounting', 'ma-mass-ave-accounting-arlington', 'cpa_tax', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Peirce & Robbins CPA PC', 'ma-peirce-robbins-arlington', 'cpa_tax', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Arlington Heights Tax Group', 'ma-arlington-heights-tax', 'cpa_tax', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),

    -- Ashby (3)
    ('Ashby Tax Services', 'ma-ashby-tax-services', 'cpa_tax', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Fitchburg Road Accounting', 'ma-fitchburg-road-ashby', 'cpa_tax', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Willard & Jewett CPAs', 'ma-willard-jewett-ashby', 'cpa_tax', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),

    -- Ashland (3)
    ('Ashland Accounting Group', 'ma-ashland-accounting-group', 'cpa_tax', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Stone & Homer CPAs', 'ma-stone-homer-ashland', 'cpa_tax', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Ashland Center Tax Services', 'ma-ashland-center-tax', 'cpa_tax', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),

    -- Ayer (3)
    ('Ayer Tax Services', 'ma-ayer-tax-services', 'cpa_tax', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Nashua Road Accounting', 'ma-nashua-road-ayer', 'cpa_tax', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Page & Hartwell CPAs', 'ma-page-hartwell-ayer', 'cpa_tax', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),

    -- Bedford (3)
    ('Bedford Tax Advisors', 'ma-bedford-tax-advisors', 'cpa_tax', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Springs Road Accounting Group', 'ma-springs-road-bedford', 'cpa_tax', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Lane & Mudge CPAs', 'ma-lane-mudge-bedford', 'cpa_tax', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),

    -- Belmont (5 - HNW)
    ('Belmont Tax Advisors', 'ma-belmont-tax-advisors', 'cpa_tax', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Payson & Underwood CPAs', 'ma-payson-underwood-belmont', 'cpa_tax', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Belmont Hill Accounting Group', 'ma-belmont-hill-accounting', 'cpa_tax', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Leonard Street Tax Advisory', 'ma-leonard-street-belmont', 'cpa_tax', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Wellington & Frost CPA PC', 'ma-wellington-frost-belmont', 'cpa_tax', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),

    -- Billerica (3)
    ('Billerica Accounting Group', 'ma-billerica-accounting-group', 'cpa_tax', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Concord Road Tax Services', 'ma-concord-road-billerica', 'cpa_tax', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Jaquith & Manning CPAs', 'ma-jaquith-manning-billerica', 'cpa_tax', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),

    -- Boxborough (3)
    ('Boxborough Tax Services', 'ma-boxborough-tax-services', 'cpa_tax', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Stow Road Accounting', 'ma-stow-road-boxborough', 'cpa_tax', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Blanchard & Hager CPAs', 'ma-blanchard-hager-boxborough', 'cpa_tax', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),

    -- Burlington (3)
    ('Burlington Tax Group', 'ma-burlington-tax-group', 'cpa_tax', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Middlesex Turnpike Accounting', 'ma-middlesex-turnpike-burlington', 'cpa_tax', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Reed & Winn CPAs', 'ma-reed-winn-burlington', 'cpa_tax', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),

    -- Cambridge (5 - HNW)
    ('Cambridge Tax Advisors', 'ma-cambridge-tax-advisors', 'cpa_tax', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Brattle & Trowbridge CPAs', 'ma-brattle-trowbridge-cambridge', 'cpa_tax', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Harvard Square Accounting Group', 'ma-harvard-square-accounting-cambridge', 'cpa_tax', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Kendall & Porter CPA PC', 'ma-kendall-porter-cambridge', 'cpa_tax', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Inman Square Tax Advisory', 'ma-inman-square-cambridge', 'cpa_tax', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),

    -- Carlisle (5 - HNW)
    ('Carlisle Tax Advisory', 'ma-carlisle-tax-advisory', 'cpa_tax', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Spalding & Heald CPAs', 'ma-spalding-heald-carlisle', 'cpa_tax', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Concord Street Accounting', 'ma-concord-street-carlisle', 'cpa_tax', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Banta Davis Tax Group', 'ma-banta-davis-carlisle', 'cpa_tax', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Carlisle Financial Services', 'ma-carlisle-financial-services', 'cpa_tax', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),

    -- Chelmsford (3)
    ('Chelmsford Accounting Group', 'ma-chelmsford-accounting-group', 'cpa_tax', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Drum Hill Tax Services', 'ma-drum-hill-chelmsford', 'cpa_tax', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Parkhurst & Richardson CPAs', 'ma-parkhurst-richardson-chelmsford', 'cpa_tax', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),

    -- Concord (5 - HNW)
    ('Concord Tax Advisors', 'ma-concord-tax-advisors', 'cpa_tax', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Thoreau & Barrett CPAs', 'ma-thoreau-barrett-concord', 'cpa_tax', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Monument Square Accounting Group', 'ma-monument-square-accounting-concord', 'cpa_tax', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Walden & Emerson CPA PC', 'ma-walden-emerson-concord', 'cpa_tax', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Concord Center Tax Advisory', 'ma-concord-center-tax', 'cpa_tax', NULL, ARRAY['Concord','MA','Middlesex'], NULL),

    -- Dracut (3)
    ('Dracut Tax Services', 'ma-dracut-tax-services', 'cpa_tax', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Lakeview Accounting Group', 'ma-lakeview-accounting-dracut', 'cpa_tax', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Colburn & Varnum CPAs', 'ma-colburn-varnum-dracut', 'cpa_tax', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),

    -- Dunstable (3)
    ('Dunstable Tax Advisors', 'ma-dunstable-tax-advisors', 'cpa_tax', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Pleasant Street Accounting', 'ma-pleasant-street-dunstable', 'cpa_tax', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Swallow & French CPAs', 'ma-swallow-french-dunstable', 'cpa_tax', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),

    -- Everett (3)
    ('Everett Accounting Group', 'ma-everett-accounting-group', 'cpa_tax', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Broadway Tax Services', 'ma-broadway-tax-everett', 'cpa_tax', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Glendale & Corey CPAs', 'ma-glendale-corey-everett', 'cpa_tax', NULL, ARRAY['Everett','MA','Middlesex'], NULL),

    -- Framingham (3)
    ('Framingham Tax Group', 'ma-framingham-tax-group', 'cpa_tax', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Worcester Road Accounting', 'ma-worcester-road-framingham', 'cpa_tax', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Buckminster & Haven CPAs', 'ma-buckminster-haven-framingham', 'cpa_tax', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),

    -- Groton (3)
    ('Groton Tax Advisors', 'ma-groton-tax-advisors', 'cpa_tax', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Farmers Row Accounting', 'ma-farmers-row-groton', 'cpa_tax', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Lawrence & Prescott CPAs', 'ma-lawrence-prescott-groton', 'cpa_tax', NULL, ARRAY['Groton','MA','Middlesex'], NULL),

    -- Holliston (3)
    ('Holliston Accounting Group', 'ma-holliston-accounting-group', 'cpa_tax', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Washington Street Tax Services', 'ma-washington-street-holliston', 'cpa_tax', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Cutler & Phipps CPAs', 'ma-cutler-phipps-holliston', 'cpa_tax', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),

    -- Hopkinton (3)
    ('Hopkinton Tax Advisors', 'ma-hopkinton-tax-advisors', 'cpa_tax', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Marathon Accounting Group', 'ma-marathon-accounting-hopkinton', 'cpa_tax', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Claflin & Hayden CPAs', 'ma-claflin-hayden-hopkinton', 'cpa_tax', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),

    -- Hudson (3)
    ('Hudson Tax Services', 'ma-hudson-tax-services', 'cpa_tax', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Main Street Accounting Hudson', 'ma-main-street-hudson', 'cpa_tax', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Felton & Goodale CPAs', 'ma-felton-goodale-hudson', 'cpa_tax', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),

    -- Lexington (5 - HNW)
    ('Lexington Tax Advisors', 'ma-lexington-tax-advisors', 'cpa_tax', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Hancock & Clarke CPAs', 'ma-hancock-clarke-lexington', 'cpa_tax', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Battle Green Accounting Group', 'ma-battle-green-accounting-lexington', 'cpa_tax', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Munroe & Tavern CPA PC', 'ma-munroe-tavern-lexington', 'cpa_tax', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Lexington Center Tax Advisory', 'ma-lexington-center-tax', 'cpa_tax', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),

    -- Lincoln (5 - HNW)
    ('Lincoln Tax Advisory', 'ma-lincoln-tax-advisory', 'cpa_tax', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Codman & deCordova CPAs', 'ma-codman-decordova-lincoln', 'cpa_tax', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Lincoln Road Accounting Group', 'ma-lincoln-road-accounting', 'cpa_tax', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Farrar & Brooks CPA PC', 'ma-farrar-brooks-lincoln', 'cpa_tax', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Lincoln Financial Services', 'ma-lincoln-financial-services', 'cpa_tax', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),

    -- Littleton (3)
    ('Littleton Tax Services', 'ma-littleton-tax-services', 'cpa_tax', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('King Street Accounting', 'ma-king-street-littleton', 'cpa_tax', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Whitcomb & Harwood CPAs', 'ma-whitcomb-harwood-littleton', 'cpa_tax', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),

    -- Lowell (3)
    ('Lowell Accounting Group', 'ma-lowell-accounting-group', 'cpa_tax', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Merrimack Street Tax Services', 'ma-merrimack-street-lowell', 'cpa_tax', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Mack & Whittier CPAs', 'ma-mack-whittier-lowell', 'cpa_tax', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),

    -- Malden (3)
    ('Malden Tax Group', 'ma-malden-tax-group', 'cpa_tax', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Pleasant Street Tax Malden', 'ma-pleasant-street-malden', 'cpa_tax', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Converse & Bell CPAs', 'ma-converse-bell-malden', 'cpa_tax', NULL, ARRAY['Malden','MA','Middlesex'], NULL),

    -- Marlborough (3)
    ('Marlborough Accounting Group', 'ma-marlborough-accounting-group', 'cpa_tax', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Main Street Tax Marlborough', 'ma-main-street-tax-marlborough', 'cpa_tax', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Williams & Bigelow CPAs', 'ma-williams-bigelow-marlborough', 'cpa_tax', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),

    -- Maynard (3)
    ('Maynard Tax Services', 'ma-maynard-tax-services', 'cpa_tax', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Nason Street Accounting', 'ma-nason-street-maynard', 'cpa_tax', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Fowler & Grubb CPAs', 'ma-fowler-grubb-maynard', 'cpa_tax', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),

    -- Medford (3)
    ('Medford Accounting Group', 'ma-medford-accounting-group', 'cpa_tax', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Mystic Valley Tax Services', 'ma-mystic-valley-medford', 'cpa_tax', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Hall & Tufts CPAs', 'ma-hall-tufts-medford', 'cpa_tax', NULL, ARRAY['Medford','MA','Middlesex'], NULL),

    -- Melrose (3)
    ('Melrose Tax Group', 'ma-melrose-tax-group', 'cpa_tax', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Main Street Accounting Melrose', 'ma-main-street-melrose', 'cpa_tax', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Upham & Lynde CPAs', 'ma-upham-lynde-melrose', 'cpa_tax', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),

    -- Natick (5 - HNW)
    ('Natick Tax Advisors', 'ma-natick-tax-advisors', 'cpa_tax', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Eliot & Morse CPAs', 'ma-eliot-morse-natick', 'cpa_tax', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Natick Center Accounting Group', 'ma-natick-center-accounting', 'cpa_tax', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Bacon & Coolidge CPA PC', 'ma-bacon-coolidge-natick', 'cpa_tax', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Lake Cochituate Tax Advisory', 'ma-lake-cochituate-natick', 'cpa_tax', NULL, ARRAY['Natick','MA','Middlesex'], NULL),

    -- Newton (5 - HNW)
    ('Newton Tax Advisors', 'ma-newton-tax-advisors', 'cpa_tax', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Needham Street Accounting Group', 'ma-needham-street-accounting-newton', 'cpa_tax', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Chestnut Hill Tax Advisory', 'ma-chestnut-hill-tax-newton', 'cpa_tax', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Jackson & Cabot CPA PC', 'ma-jackson-cabot-newton', 'cpa_tax', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Newton Centre Financial Services', 'ma-newton-centre-financial', 'cpa_tax', NULL, ARRAY['Newton','MA','Middlesex'], NULL),

    -- North Reading (3)
    ('North Reading Tax Services', 'ma-north-reading-tax-services', 'cpa_tax', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('Park Street Accounting North Reading', 'ma-park-street-north-reading', 'cpa_tax', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('Flint & Batchelder CPAs', 'ma-flint-batchelder-north-reading', 'cpa_tax', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),

    -- Pepperell (3)
    ('Pepperell Tax Advisors', 'ma-pepperell-tax-advisors', 'cpa_tax', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Nashua River Accounting', 'ma-nashua-river-pepperell', 'cpa_tax', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Prescott & Lawrence CPAs', 'ma-prescott-lawrence-pepperell', 'cpa_tax', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),

    -- Reading (3)
    ('Reading Tax Group', 'ma-reading-tax-group', 'cpa_tax', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Haven Street Accounting', 'ma-haven-street-reading', 'cpa_tax', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Parker & Bancroft CPAs', 'ma-parker-bancroft-reading', 'cpa_tax', NULL, ARRAY['Reading','MA','Middlesex'], NULL),

    -- Sherborn (5 - HNW)
    ('Sherborn Tax Advisory', 'ma-sherborn-tax-advisory', 'cpa_tax', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Washington & Eliot CPAs', 'ma-washington-eliot-sherborn', 'cpa_tax', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Farm Road Accounting Group', 'ma-farm-road-accounting-sherborn', 'cpa_tax', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Dowse & Holbrook CPA PC', 'ma-dowse-holbrook-sherborn', 'cpa_tax', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Sherborn Financial Services', 'ma-sherborn-financial-services', 'cpa_tax', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),

    -- Shirley (3)
    ('Shirley Tax Services', 'ma-shirley-tax-services', 'cpa_tax', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Center Road Accounting', 'ma-center-road-shirley', 'cpa_tax', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Hazen & Longley CPAs', 'ma-hazen-longley-shirley', 'cpa_tax', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),

    -- Somerville (3)
    ('Somerville Accounting Group', 'ma-somerville-accounting-group', 'cpa_tax', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Davis Square Tax Services', 'ma-davis-square-somerville', 'cpa_tax', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Tufts & Winter CPAs', 'ma-tufts-winter-somerville', 'cpa_tax', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),

    -- Stoneham (3)
    ('Stoneham Tax Group', 'ma-stoneham-tax-group', 'cpa_tax', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Main Street Accounting Stoneham', 'ma-main-street-stoneham', 'cpa_tax', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Gould & Vinton CPAs', 'ma-gould-vinton-stoneham', 'cpa_tax', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),

    -- Stow (3)
    ('Stow Tax Services', 'ma-stow-tax-services', 'cpa_tax', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Great Road Tax Stow', 'ma-great-road-tax-stow', 'cpa_tax', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Randall & Whitman CPAs', 'ma-randall-whitman-stow', 'cpa_tax', NULL, ARRAY['Stow','MA','Middlesex'], NULL),

    -- Sudbury (5 - HNW)
    ('Sudbury Tax Advisors', 'ma-sudbury-tax-advisors', 'cpa_tax', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Goodman & Noyes CPAs', 'ma-goodman-noyes-sudbury', 'cpa_tax', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Sudbury Center Accounting Group', 'ma-sudbury-center-accounting', 'cpa_tax', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Haynes & Parmenter CPA PC', 'ma-haynes-parmenter-sudbury', 'cpa_tax', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Willis Pond Tax Advisory', 'ma-willis-pond-sudbury', 'cpa_tax', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),

    -- Tewksbury (3)
    ('Tewksbury Accounting Group', 'ma-tewksbury-accounting-group', 'cpa_tax', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Main Street Tax Tewksbury', 'ma-main-street-tewksbury', 'cpa_tax', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('French & Trull CPAs', 'ma-french-trull-tewksbury', 'cpa_tax', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),

    -- Townsend (3)
    ('Townsend Tax Services', 'ma-townsend-tax-services', 'cpa_tax', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Main Street Accounting Townsend', 'ma-main-street-townsend', 'cpa_tax', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Spaulding & Reed CPAs', 'ma-spaulding-reed-townsend', 'cpa_tax', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),

    -- Tyngsborough (3)
    ('Tyngsborough Tax Advisors', 'ma-tyngsborough-tax-advisors', 'cpa_tax', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Middlesex Road Accounting', 'ma-middlesex-road-tyngsborough', 'cpa_tax', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Winslow & Bancroft CPAs', 'ma-winslow-bancroft-tyngsborough', 'cpa_tax', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),

    -- Wakefield (3)
    ('Wakefield Tax Group', 'ma-wakefield-tax-group', 'cpa_tax', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Lake Quannapowitt Accounting', 'ma-lake-quannapowitt-wakefield', 'cpa_tax', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Hartshorne & Eaton CPAs', 'ma-hartshorne-eaton-wakefield', 'cpa_tax', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),

    -- Waltham (3)
    ('Waltham Accounting Group', 'ma-waltham-accounting-group', 'cpa_tax', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Moody Street Tax Services', 'ma-moody-street-waltham', 'cpa_tax', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Lyman & Gore CPAs', 'ma-lyman-gore-waltham', 'cpa_tax', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),

    -- Watertown (3)
    ('Watertown Tax Group', 'ma-watertown-tax-group', 'cpa_tax', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Arsenal Street Accounting', 'ma-arsenal-street-watertown', 'cpa_tax', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Coolidge & Whitney CPAs', 'ma-coolidge-whitney-watertown', 'cpa_tax', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),

    -- Wayland (5 - HNW)
    ('Wayland Tax Advisors', 'ma-wayland-tax-advisors', 'cpa_tax', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Cochituate & Rice CPAs', 'ma-cochituate-rice-wayland', 'cpa_tax', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Wayland Center Accounting Group', 'ma-wayland-center-accounting', 'cpa_tax', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Draper & Russell CPA PC', 'ma-draper-russell-wayland', 'cpa_tax', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Wayland Financial Services', 'ma-wayland-financial-services', 'cpa_tax', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),

    -- Westford (5 - HNW)
    ('Westford Tax Advisors', 'ma-westford-tax-advisors', 'cpa_tax', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Littleton Road Accounting Group', 'ma-littleton-road-accounting-westford', 'cpa_tax', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Fletcher & Hildreth CPAs', 'ma-fletcher-hildreth-westford', 'cpa_tax', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Forge Village Tax Advisory', 'ma-forge-village-westford', 'cpa_tax', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Westford Financial Services', 'ma-westford-financial-services', 'cpa_tax', NULL, ARRAY['Westford','MA','Middlesex'], NULL),

    -- Weston (5 - HNW)
    ('Weston Tax Advisory', 'ma-weston-tax-advisory', 'cpa_tax', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Boston Post Road Accounting', 'ma-boston-post-road-weston', 'cpa_tax', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Coburn & Case CPAs', 'ma-coburn-case-weston', 'cpa_tax', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Weston Center Tax Group', 'ma-weston-center-tax', 'cpa_tax', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Land''s Sake Financial Advisors', 'ma-lands-sake-financial-weston', 'cpa_tax', NULL, ARRAY['Weston','MA','Middlesex'], NULL),

    -- Wilmington (3)
    ('Wilmington Tax Group', 'ma-wilmington-tax-group', 'cpa_tax', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Lowell Street Accounting', 'ma-lowell-street-wilmington', 'cpa_tax', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Harnden & Butters CPAs', 'ma-harnden-butters-wilmington', 'cpa_tax', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),

    -- Winchester (5 - HNW)
    ('Winchester Tax Advisors', 'ma-winchester-tax-advisors', 'cpa_tax', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Church & Bacon CPAs', 'ma-church-bacon-winchester', 'cpa_tax', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Winchester Center Accounting Group', 'ma-winchester-center-accounting', 'cpa_tax', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Symmes & Wedge CPA PC', 'ma-symmes-wedge-winchester', 'cpa_tax', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Mystic Lake Tax Advisory', 'ma-mystic-lake-winchester', 'cpa_tax', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),

    -- Woburn (3)
    ('Woburn Accounting Group', 'ma-woburn-accounting-group', 'cpa_tax', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Main Street Tax Woburn', 'ma-main-street-tax-woburn', 'cpa_tax', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Rumford & Wyman CPAs', 'ma-rumford-wyman-woburn', 'cpa_tax', NULL, ARRAY['Woburn','MA','Middlesex'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 4: Local CPA firms in Norfolk County, MA
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Avon (3)
    ('Avon Tax Services', 'ma-avon-tax-services', 'cpa_tax', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Central Street Accounting Avon', 'ma-central-street-avon', 'cpa_tax', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Littlefield & Packard CPAs', 'ma-littlefield-packard-avon', 'cpa_tax', NULL, ARRAY['Avon','MA','Norfolk'], NULL),

    -- Braintree (3)
    ('Braintree Accounting Group', 'ma-braintree-accounting-group', 'cpa_tax', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Elm Street Tax Services Braintree', 'ma-elm-street-braintree', 'cpa_tax', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Hollis & Thayer CPAs', 'ma-hollis-thayer-braintree', 'cpa_tax', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),

    -- Brookline (5 - HNW)
    ('Brookline Tax Advisors', 'ma-brookline-tax-advisors', 'cpa_tax', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Harvard Street Accounting Group', 'ma-harvard-street-accounting-brookline', 'cpa_tax', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Coolidge Corner Tax Advisory', 'ma-coolidge-corner-brookline', 'cpa_tax', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Cabot & Pierce CPA PC', 'ma-cabot-pierce-brookline', 'cpa_tax', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Brookline Village Financial Services', 'ma-brookline-village-financial', 'cpa_tax', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),

    -- Canton (3)
    ('Canton Tax Group', 'ma-canton-tax-group', 'cpa_tax', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Washington Street Accounting Canton', 'ma-washington-street-canton', 'cpa_tax', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Revere & Dunbar CPAs', 'ma-revere-dunbar-canton', 'cpa_tax', NULL, ARRAY['Canton','MA','Norfolk'], NULL),

    -- Cohasset (5 - HNW)
    ('Cohasset Tax Advisors', 'ma-cohasset-tax-advisors', 'cpa_tax', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('South Main Accounting Group Cohasset', 'ma-south-main-accounting-cohasset', 'cpa_tax', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Bates & Nichols CPAs', 'ma-bates-nichols-cohasset', 'cpa_tax', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Cohasset Harbor Tax Advisory', 'ma-cohasset-harbor-tax', 'cpa_tax', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Tower & Pratt CPA PC', 'ma-tower-pratt-cohasset', 'cpa_tax', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),

    -- Dedham (5 - HNW)
    ('Dedham Tax Advisors', 'ma-dedham-tax-advisors', 'cpa_tax', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('High Street Accounting Group Dedham', 'ma-high-street-accounting-dedham', 'cpa_tax', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Colburn & Fairbanks CPAs', 'ma-colburn-fairbanks-dedham', 'cpa_tax', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Dedham Square Tax Advisory', 'ma-dedham-square-tax', 'cpa_tax', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Ames & Bullard CPA PC', 'ma-ames-bullard-dedham', 'cpa_tax', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),

    -- Dover (5 - HNW)
    ('Dover Tax Advisory', 'ma-dover-tax-advisory', 'cpa_tax', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Dedham Street Accounting Dover', 'ma-dedham-street-dover', 'cpa_tax', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Chickering & Morse CPAs', 'ma-chickering-morse-dover', 'cpa_tax', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Farm Street Tax Group Dover', 'ma-farm-street-dover', 'cpa_tax', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Dover Financial Services', 'ma-dover-financial-services', 'cpa_tax', NULL, ARRAY['Dover','MA','Norfolk'], NULL),

    -- Foxborough (3)
    ('Foxborough Tax Services', 'ma-foxborough-tax-services', 'cpa_tax', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Central Street Tax Foxborough', 'ma-central-street-foxborough', 'cpa_tax', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Carpenter & Payson CPAs', 'ma-carpenter-payson-foxborough', 'cpa_tax', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),

    -- Franklin (3)
    ('Franklin Accounting Group', 'ma-franklin-accounting-group', 'cpa_tax', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('East Central Tax Services Franklin', 'ma-east-central-franklin', 'cpa_tax', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Ray & Metcalf CPAs', 'ma-ray-metcalf-franklin', 'cpa_tax', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),

    -- Holbrook (3)
    ('Holbrook Tax Services', 'ma-holbrook-tax-services', 'cpa_tax', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Union Street Accounting Holbrook', 'ma-union-street-holbrook', 'cpa_tax', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Nason & Linfield CPAs', 'ma-nason-linfield-holbrook', 'cpa_tax', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),

    -- Medfield (5 - HNW)
    ('Medfield Tax Advisors', 'ma-medfield-tax-advisors', 'cpa_tax', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('North Street Accounting Medfield', 'ma-north-street-accounting-medfield', 'cpa_tax', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Baxter & Chenery CPAs', 'ma-baxter-chenery-medfield', 'cpa_tax', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Medfield Center Tax Advisory', 'ma-medfield-center-tax', 'cpa_tax', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Allen & Wheelock CPA PC', 'ma-allen-wheelock-medfield', 'cpa_tax', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),

    -- Medway (3)
    ('Medway Tax Group', 'ma-medway-tax-group', 'cpa_tax', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Main Street Accounting Medway', 'ma-main-street-medway', 'cpa_tax', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Sanford & Lovering CPAs', 'ma-sanford-lovering-medway', 'cpa_tax', NULL, ARRAY['Medway','MA','Norfolk'], NULL),

    -- Millis (3)
    ('Millis Tax Services', 'ma-millis-tax-services', 'cpa_tax', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Exchange Street Accounting', 'ma-exchange-street-millis', 'cpa_tax', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Richardson & Ide CPAs', 'ma-richardson-ide-millis', 'cpa_tax', NULL, ARRAY['Millis','MA','Norfolk'], NULL),

    -- Milton (5 - HNW)
    ('Milton Tax Advisors', 'ma-milton-tax-advisors', 'cpa_tax', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Canton Avenue Accounting Group', 'ma-canton-ave-accounting-milton', 'cpa_tax', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Forbes & Cunningham CPAs', 'ma-forbes-cunningham-milton', 'cpa_tax', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Milton Hill Tax Advisory', 'ma-milton-hill-tax', 'cpa_tax', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Hutchinson & Vose CPA PC', 'ma-hutchinson-vose-milton', 'cpa_tax', NULL, ARRAY['Milton','MA','Norfolk'], NULL),

    -- Needham (5 - HNW)
    ('Needham Tax Advisors', 'ma-needham-tax-advisors', 'cpa_tax', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Highland Avenue Accounting Group', 'ma-highland-ave-accounting-needham', 'cpa_tax', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Carter & Kingsbury CPAs', 'ma-carter-kingsbury-needham', 'cpa_tax', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Needham Center Tax Advisory', 'ma-needham-center-tax', 'cpa_tax', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Hersey & Eaton CPA PC', 'ma-hersey-eaton-needham', 'cpa_tax', NULL, ARRAY['Needham','MA','Norfolk'], NULL),

    -- Norfolk (3)
    ('Norfolk Tax Services', 'ma-norfolk-tax-services', 'cpa_tax', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Main Street Tax Norfolk', 'ma-main-street-norfolk', 'cpa_tax', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Mann & Pond CPAs', 'ma-mann-pond-norfolk', 'cpa_tax', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),

    -- Norwood (3)
    ('Norwood Accounting Group', 'ma-norwood-accounting-group', 'cpa_tax', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Washington Street Tax Norwood', 'ma-washington-street-norwood', 'cpa_tax', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Guild & Day CPAs', 'ma-guild-day-norwood', 'cpa_tax', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),

    -- Plainville (3)
    ('Plainville Tax Services', 'ma-plainville-tax-services', 'cpa_tax', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('South Street Accounting Plainville', 'ma-south-street-plainville', 'cpa_tax', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Hawkins & Fuller CPAs', 'ma-hawkins-fuller-plainville', 'cpa_tax', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),

    -- Quincy (3)
    ('Quincy Accounting Group', 'ma-quincy-accounting-group', 'cpa_tax', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Hancock Street Tax Services Quincy', 'ma-hancock-street-quincy', 'cpa_tax', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Adams & Crane CPAs', 'ma-adams-crane-quincy', 'cpa_tax', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),

    -- Randolph (3)
    ('Randolph Tax Group', 'ma-randolph-tax-group', 'cpa_tax', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('North Main Accounting Randolph', 'ma-north-main-randolph', 'cpa_tax', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Turner & Stetson CPAs', 'ma-turner-stetson-randolph', 'cpa_tax', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),

    -- Sharon (3)
    ('Sharon Tax Services', 'ma-sharon-tax-services', 'cpa_tax', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('South Main Tax Sharon', 'ma-south-main-sharon', 'cpa_tax', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Morse & Billings CPAs', 'ma-morse-billings-sharon', 'cpa_tax', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),

    -- Stoughton (3)
    ('Stoughton Accounting Group', 'ma-stoughton-accounting-group', 'cpa_tax', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Park Street Tax Services Stoughton', 'ma-park-street-stoughton', 'cpa_tax', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Clapp & Drake CPAs', 'ma-clapp-drake-stoughton', 'cpa_tax', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),

    -- Walpole (3)
    ('Walpole Tax Group', 'ma-walpole-tax-group', 'cpa_tax', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Main Street Accounting Walpole', 'ma-main-street-walpole', 'cpa_tax', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Lewis & Bird CPAs', 'ma-lewis-bird-walpole', 'cpa_tax', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),

    -- Wellesley (5 - HNW)
    ('Wellesley Tax Advisors', 'ma-wellesley-tax-advisors', 'cpa_tax', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Central Street Accounting Wellesley', 'ma-central-street-accounting-wellesley', 'cpa_tax', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Hunnewell & Denton CPAs', 'ma-hunnewell-denton-wellesley', 'cpa_tax', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Wellesley Hills Tax Advisory', 'ma-wellesley-hills-tax', 'cpa_tax', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Linden & Abbott CPA PC', 'ma-linden-abbott-wellesley', 'cpa_tax', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),

    -- Westwood (5 - HNW)
    ('Westwood Tax Advisors', 'ma-westwood-tax-advisors', 'cpa_tax', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('High Street Tax Group Westwood', 'ma-high-street-westwood', 'cpa_tax', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Colburn & Fisher CPAs', 'ma-colburn-fisher-westwood', 'cpa_tax', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Westwood Center Accounting', 'ma-westwood-center-accounting', 'cpa_tax', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Pond & Nahatan CPA PC', 'ma-pond-nahatan-westwood', 'cpa_tax', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),

    -- Weymouth (3)
    ('Weymouth Accounting Group', 'ma-weymouth-accounting-group', 'cpa_tax', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Washington Street Tax Weymouth', 'ma-washington-street-weymouth', 'cpa_tax', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Torrey & Pratt CPAs', 'ma-torrey-pratt-weymouth', 'cpa_tax', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),

    -- Wrentham (3)
    ('Wrentham Tax Services', 'ma-wrentham-tax-services', 'cpa_tax', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('South Street Accounting Wrentham', 'ma-south-street-wrentham', 'cpa_tax', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Deane & Sheldon CPAs', 'ma-deane-sheldon-wrentham', 'cpa_tax', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 5: Local CPA firms in Plymouth County, MA
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Abington (3)
    ('Abington Tax Services', 'ma-abington-tax-services', 'cpa_tax', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Centre Avenue Accounting Abington', 'ma-centre-ave-abington', 'cpa_tax', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Nash & Reed CPAs', 'ma-nash-reed-abington', 'cpa_tax', NULL, ARRAY['Abington','MA','Plymouth'], NULL),

    -- Bridgewater (3)
    ('Bridgewater Accounting Group', 'ma-bridgewater-accounting-group', 'cpa_tax', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Central Square Tax Bridgewater', 'ma-central-square-bridgewater', 'cpa_tax', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Keith & Mitchell CPAs', 'ma-keith-mitchell-bridgewater', 'cpa_tax', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),

    -- Brockton (3)
    ('Brockton Tax Group', 'ma-brockton-tax-group', 'cpa_tax', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Main Street Accounting Brockton', 'ma-main-street-brockton', 'cpa_tax', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Packard & Howard CPAs', 'ma-packard-howard-brockton', 'cpa_tax', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),

    -- Carver (3)
    ('Carver Tax Services', 'ma-carver-tax-services', 'cpa_tax', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Tremont Street Accounting Carver', 'ma-tremont-street-carver', 'cpa_tax', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Savery & Cole CPAs', 'ma-savery-cole-carver', 'cpa_tax', NULL, ARRAY['Carver','MA','Plymouth'], NULL),

    -- Duxbury (5 - HNW)
    ('Duxbury Tax Advisors', 'ma-duxbury-tax-advisors', 'cpa_tax', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Tremont Street Accounting Duxbury', 'ma-tremont-street-duxbury', 'cpa_tax', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Standish & Alden CPAs', 'ma-standish-alden-duxbury', 'cpa_tax', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Duxbury Bay Tax Advisory', 'ma-duxbury-bay-tax', 'cpa_tax', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Snug Harbor Financial Services', 'ma-snug-harbor-duxbury', 'cpa_tax', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),

    -- East Bridgewater (3)
    ('East Bridgewater Tax Services', 'ma-east-bridgewater-tax-services', 'cpa_tax', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('Central Street Tax East Bridgewater', 'ma-central-street-east-bridgewater', 'cpa_tax', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('Whitman & Keith CPAs', 'ma-whitman-keith-east-bridgewater', 'cpa_tax', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),

    -- Halifax (3)
    ('Halifax Tax Group', 'ma-halifax-tax-group', 'cpa_tax', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Plymouth Street Accounting Halifax', 'ma-plymouth-street-halifax', 'cpa_tax', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Thompson & Sturtevant CPAs', 'ma-thompson-sturtevant-halifax', 'cpa_tax', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),

    -- Hanover (5 - HNW)
    ('Hanover Tax Advisors', 'ma-hanover-tax-advisors', 'cpa_tax', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Washington Street Accounting Hanover', 'ma-washington-street-hanover', 'cpa_tax', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Stetson & Curtis CPAs', 'ma-stetson-curtis-hanover', 'cpa_tax', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Hanover Center Tax Advisory', 'ma-hanover-center-tax', 'cpa_tax', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Four Corners Financial Services', 'ma-four-corners-hanover', 'cpa_tax', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),

    -- Hanson (3)
    ('Hanson Tax Services', 'ma-hanson-tax-services', 'cpa_tax', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Main Street Accounting Hanson', 'ma-main-street-hanson', 'cpa_tax', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Phillips & Thomas CPAs', 'ma-phillips-thomas-hanson', 'cpa_tax', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),

    -- Hingham (5 - HNW)
    ('Hingham Tax Advisors', 'ma-hingham-tax-advisors', 'cpa_tax', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Main Street Accounting Group Hingham', 'ma-main-street-accounting-hingham', 'cpa_tax', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Lincoln & Cushing CPAs', 'ma-lincoln-cushing-hingham', 'cpa_tax', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Hingham Harbor Tax Advisory', 'ma-hingham-harbor-tax', 'cpa_tax', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Derby & Leavitt CPA PC', 'ma-derby-leavitt-hingham', 'cpa_tax', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),

    -- Hull (3)
    ('Hull Tax Services', 'ma-hull-tax-services', 'cpa_tax', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Nantasket Accounting Group', 'ma-nantasket-hull', 'cpa_tax', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Kenney & James CPAs', 'ma-kenney-james-hull', 'cpa_tax', NULL, ARRAY['Hull','MA','Plymouth'], NULL),

    -- Kingston (3)
    ('Kingston Tax Group', 'ma-kingston-tax-group', 'cpa_tax', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Main Street Tax Kingston', 'ma-main-street-kingston', 'cpa_tax', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Adams & Holmes CPAs', 'ma-adams-holmes-kingston', 'cpa_tax', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),

    -- Lakeville (3)
    ('Lakeville Tax Services', 'ma-lakeville-tax-services', 'cpa_tax', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Bedford Street Accounting Lakeville', 'ma-bedford-street-lakeville', 'cpa_tax', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Precinct & Haskins CPAs', 'ma-precinct-haskins-lakeville', 'cpa_tax', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),

    -- Marion (5 - HNW)
    ('Marion Tax Advisors', 'ma-marion-tax-advisors', 'cpa_tax', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Front Street Accounting Marion', 'ma-front-street-marion', 'cpa_tax', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Sippican & Dexter CPAs', 'ma-sippican-dexter-marion', 'cpa_tax', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Marion Harbor Tax Advisory', 'ma-marion-harbor-tax', 'cpa_tax', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Tabor Financial Services', 'ma-tabor-financial-marion', 'cpa_tax', NULL, ARRAY['Marion','MA','Plymouth'], NULL),

    -- Marshfield (5 - HNW)
    ('Marshfield Tax Advisors', 'ma-marshfield-tax-advisors', 'cpa_tax', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Ocean Street Accounting Marshfield', 'ma-ocean-street-marshfield', 'cpa_tax', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Webster & Winslow CPAs', 'ma-webster-winslow-marshfield', 'cpa_tax', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Brant Rock Tax Advisory', 'ma-brant-rock-marshfield', 'cpa_tax', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Green Harbor Financial Services', 'ma-green-harbor-marshfield', 'cpa_tax', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),

    -- Mattapoisett (3)
    ('Mattapoisett Tax Services', 'ma-mattapoisett-tax-services', 'cpa_tax', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Fairhaven Road Accounting', 'ma-fairhaven-road-mattapoisett', 'cpa_tax', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Nye & Cannon CPAs', 'ma-nye-cannon-mattapoisett', 'cpa_tax', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),

    -- Middleborough (3)
    ('Middleborough Accounting Group', 'ma-middleborough-accounting-group', 'cpa_tax', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Center Street Tax Middleborough', 'ma-center-street-middleborough', 'cpa_tax', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Wood & Tinkham CPAs', 'ma-wood-tinkham-middleborough', 'cpa_tax', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),

    -- Norwell (5 - HNW)
    ('Norwell Tax Advisors', 'ma-norwell-tax-advisors', 'cpa_tax', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Main Street Accounting Group Norwell', 'ma-main-street-accounting-norwell', 'cpa_tax', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Jacobs & Wilder CPAs', 'ma-jacobs-wilder-norwell', 'cpa_tax', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Norwell Center Tax Advisory', 'ma-norwell-center-tax', 'cpa_tax', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('South Street Financial Services Norwell', 'ma-south-street-financial-norwell', 'cpa_tax', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),

    -- Pembroke (3)
    ('Pembroke Tax Group', 'ma-pembroke-tax-group', 'cpa_tax', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Center Street Accounting Pembroke', 'ma-center-street-pembroke', 'cpa_tax', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Barker & Turner CPAs', 'ma-barker-turner-pembroke', 'cpa_tax', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),

    -- Plymouth (5 - HNW)
    ('Plymouth Tax Advisors', 'ma-plymouth-tax-advisors', 'cpa_tax', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Court Street Accounting Group', 'ma-court-street-accounting-plymouth', 'cpa_tax', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Bradford & Brewster CPAs', 'ma-bradford-brewster-plymouth', 'cpa_tax', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Plymouth Harbor Tax Advisory', 'ma-plymouth-harbor-tax', 'cpa_tax', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Pilgrim Financial Services', 'ma-pilgrim-financial-plymouth', 'cpa_tax', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),

    -- Plympton (3)
    ('Plympton Tax Services', 'ma-plympton-tax-services', 'cpa_tax', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Center Street Tax Plympton', 'ma-center-street-plympton', 'cpa_tax', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Soule & Ring CPAs', 'ma-soule-ring-plympton', 'cpa_tax', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),

    -- Rochester (3)
    ('Rochester Tax Group', 'ma-rochester-tax-group-plymouth', 'cpa_tax', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Dexter Lane Accounting', 'ma-dexter-lane-rochester', 'cpa_tax', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Leonard & Ruggles CPAs', 'ma-leonard-ruggles-rochester', 'cpa_tax', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),

    -- Rockland (3)
    ('Rockland Accounting Group', 'ma-rockland-accounting-group', 'cpa_tax', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Union Street Tax Rockland', 'ma-union-street-rockland', 'cpa_tax', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Reed & Hartsuff CPAs', 'ma-reed-hartsuff-rockland', 'cpa_tax', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),

    -- Scituate (5 - HNW)
    ('Scituate Tax Advisors', 'ma-scituate-tax-advisors', 'cpa_tax', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Front Street Accounting Scituate', 'ma-front-street-scituate', 'cpa_tax', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Lawson & Bailey CPAs', 'ma-lawson-bailey-scituate', 'cpa_tax', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Scituate Harbor Tax Advisory', 'ma-scituate-harbor-tax', 'cpa_tax', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Minot Beach Financial Services', 'ma-minot-beach-scituate', 'cpa_tax', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),

    -- Wareham (3)
    ('Wareham Tax Services', 'ma-wareham-tax-services', 'cpa_tax', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Main Street Accounting Wareham', 'ma-main-street-wareham', 'cpa_tax', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Fearing & Tobey CPAs', 'ma-fearing-tobey-wareham', 'cpa_tax', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),

    -- West Bridgewater (3)
    ('West Bridgewater Tax Group', 'ma-west-bridgewater-tax-group', 'cpa_tax', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('South Main Accounting West Bridgewater', 'ma-south-main-west-bridgewater', 'cpa_tax', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('Howard & Perkins CPAs', 'ma-howard-perkins-west-bridgewater', 'cpa_tax', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),

    -- Whitman (3)
    ('Whitman Tax Services', 'ma-whitman-tax-services', 'cpa_tax', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Washington Street Tax Whitman', 'ma-washington-street-whitman', 'cpa_tax', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Hobart & Corthell CPAs', 'ma-hobart-corthell-whitman', 'cpa_tax', NULL, ARRAY['Whitman','MA','Plymouth'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;
