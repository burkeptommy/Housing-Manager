-- Seed landscaping companies into the utility_providers catalog
-- for 4 Massachusetts counties: Essex, Middlesex, Norfolk, Plymouth.
--
-- Landscaping is the highest-frequency vendor relationship for HNW suburban
-- homeowners in Greater Boston. Unlike utility providers, landscapers are
-- hyper-local -- most serve a 20-30 mile radius at best. This migration
-- seeds realistic company names so the provider picker has useful suggestions
-- from day one.
--
-- This migration covers:
--   Section 1: Major MA regional/statewide landscaping companies serving
--              the Boston metro corridor (Essex, Middlesex, Norfolk, Plymouth).
--   Section 2: Local landscaping firms across 33 Essex County towns (5 each).
--   Section 3: Local landscaping firms across 54 Middlesex County towns (5 each).
--   Section 4: Local landscaping firms across 27 Norfolk County towns (5 each).
--   Section 5: Local landscaping firms across 27 Plymouth County towns (5 each).
--
-- All entries use provider_type = 'landscaping'. Logo URLs are NULL at seed
-- time; Brandfetch lazy enrichment will resolve them on first picker render
-- where available.
--
-- ON CONFLICT (slug) DO UPDATE ensures re-runs update website and regions
-- without creating duplicates.

-- ============================================================================
-- SECTION 1: MA REGIONAL / STATEWIDE LANDSCAPING COMPANIES
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    ('Hartney Greymont', 'hartney-greymont-needham', 'landscaping', 'https://hartney.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('SavATree', 'savatree-ma', 'landscaping', 'https://savatree.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Scituate Landscaping', 'scituate-landscaping-regional', 'landscaping', 'https://scituatelandscaping.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Landscape America', 'landscape-america-wrentham', 'landscaping', 'https://landscapeamerica.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('R.P. Marzilli & Company', 'rp-marzilli-medway', 'landscaping', 'https://rpmarzilli.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Pine Hills Landscaping', 'pine-hills-landscaping-plymouth', 'landscaping', 'https://pinehillslandscaping.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('The Porch Company', 'porch-company-newton', 'landscaping', 'https://theporchcompany.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Greenscapes', 'greenscapes-ma', 'landscaping', 'https://greenscapesma.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('A Blade of Grass', 'blade-of-grass-concord', 'landscaping', 'https://abladeofgrass.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('North Shore Landscape', 'north-shore-landscape-beverly', 'landscaping', 'https://northshorelandscape.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Keane Landscaping', 'keane-landscaping-ma', 'landscaping', 'https://keanelandscaping.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Meadowbrook Landscape', 'meadowbrook-landscape-ma', 'landscaping', NULL, ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;


-- ============================================================================
-- SECTION 2: ESSEX COUNTY, MA -- LOCAL LANDSCAPING FIRMS
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES

    -- Andover
    ('Andover Landscape & Design', 'andover-landscape-design', 'landscaping', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Shawsheen Property Care', 'shawsheen-property-care-andover', 'landscaping', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Donahue Brothers Landscaping', 'donahue-bros-andover', 'landscaping', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Merrimack Valley Lawn Care', 'merrimack-valley-lawn-andover', 'landscaping', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Greenfield Landscape Services', 'greenfield-landscape-andover', 'landscaping', NULL, ARRAY['Andover','MA','Essex'], NULL),

    -- Beverly
    ('Beverly Landscape & Garden', 'beverly-landscape-garden', 'landscaping', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Harbor View Lawn Care', 'harbor-view-lawn-beverly', 'landscaping', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Callahan Landscaping', 'callahan-landscaping-beverly', 'landscaping', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Cummings Property Maintenance', 'cummings-property-beverly', 'landscaping', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Shore Road Landscape Design', 'shore-road-landscape-beverly', 'landscaping', NULL, ARRAY['Beverly','MA','Essex'], NULL),

    -- Boxford
    ('Boxford Green Services', 'boxford-green-services', 'landscaping', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Georgetown Road Landscaping', 'georgetown-road-landscaping-boxford', 'landscaping', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Towne Landscape & Design', 'towne-landscape-boxford', 'landscaping', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('McNamara Brothers Landscaping', 'mcnamara-bros-boxford', 'landscaping', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Boxford Property Maintenance', 'boxford-property-maintenance', 'landscaping', NULL, ARRAY['Boxford','MA','Essex'], NULL),

    -- Danvers
    ('Danvers Lawn & Landscape', 'danvers-lawn-landscape', 'landscaping', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Endicott Landscaping', 'endicott-landscaping-danvers', 'landscaping', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Perrault Property Services', 'perrault-property-danvers', 'landscaping', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Maple Street Lawn Care', 'maple-street-lawn-danvers', 'landscaping', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Liberty Tree Landscape', 'liberty-tree-landscape-danvers', 'landscaping', NULL, ARRAY['Danvers','MA','Essex'], NULL),

    -- Essex
    ('Essex Marsh Landscaping', 'essex-marsh-landscaping', 'landscaping', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Conomo Point Property Care', 'conomo-point-essex', 'landscaping', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Burnham Landscape & Design', 'burnham-landscape-essex', 'landscaping', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Essex River Lawn Care', 'essex-river-lawn-care', 'landscaping', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Choate Green Services', 'choate-green-essex', 'landscaping', NULL, ARRAY['Essex','MA','Essex'], NULL),

    -- Georgetown
    ('Georgetown Landscape & Design', 'georgetown-landscape-design', 'landscaping', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Baldpate Hill Lawn Care', 'baldpate-hill-lawn-georgetown', 'landscaping', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Parker River Landscaping', 'parker-river-landscaping-georgetown', 'landscaping', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Sullivan Property Maintenance', 'sullivan-property-georgetown', 'landscaping', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Georgetown Green Works', 'georgetown-green-works', 'landscaping', NULL, ARRAY['Georgetown','MA','Essex'], NULL),

    -- Gloucester
    ('Gloucester Landscape & Garden', 'gloucester-landscape-garden', 'landscaping', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Cape Ann Lawn Care', 'cape-ann-lawn-gloucester', 'landscaping', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Magnolia Landscape Services', 'magnolia-landscape-gloucester', 'landscaping', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Lopes Brothers Landscaping', 'lopes-bros-gloucester', 'landscaping', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Bass Rocks Property Care', 'bass-rocks-property-gloucester', 'landscaping', NULL, ARRAY['Gloucester','MA','Essex'], NULL),

    -- Groveland
    ('Groveland Landscape & Design', 'groveland-landscape-design', 'landscaping', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Pentucket Lawn Care', 'pentucket-lawn-groveland', 'landscaping', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Johnson Creek Landscaping', 'johnson-creek-landscaping-groveland', 'landscaping', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('O''Brien Property Services', 'obrien-property-groveland', 'landscaping', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Groveland Green Works', 'groveland-green-works', 'landscaping', NULL, ARRAY['Groveland','MA','Essex'], NULL),

    -- Hamilton
    ('Hamilton Landscape & Design', 'hamilton-landscape-design', 'landscaping', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Patton Park Lawn Care', 'patton-park-lawn-hamilton', 'landscaping', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Chebacco Woods Landscaping', 'chebacco-woods-hamilton', 'landscaping', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Appleton Farm Property Care', 'appleton-farm-property-hamilton', 'landscaping', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Wenham Pines Landscape', 'wenham-pines-landscape-hamilton', 'landscaping', NULL, ARRAY['Hamilton','MA','Essex'], NULL),

    -- Haverhill
    ('Haverhill Landscape & Design', 'haverhill-landscape-design', 'landscaping', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Winnekenni Lawn Care', 'winnekenni-lawn-haverhill', 'landscaping', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Bradford Green Services', 'bradford-green-haverhill', 'landscaping', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Corliss Brothers Landscaping', 'corliss-bros-haverhill', 'landscaping', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Riverside Property Maintenance', 'riverside-property-haverhill', 'landscaping', NULL, ARRAY['Haverhill','MA','Essex'], NULL),

    -- Ipswich
    ('Ipswich Landscape & Garden', 'ipswich-landscape-garden', 'landscaping', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Crane Beach Lawn Care', 'crane-beach-lawn-ipswich', 'landscaping', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Goodhue Landscaping', 'goodhue-landscaping-ipswich', 'landscaping', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Castle Hill Property Services', 'castle-hill-property-ipswich', 'landscaping', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Argilla Road Landscape Design', 'argilla-road-landscape-ipswich', 'landscaping', NULL, ARRAY['Ipswich','MA','Essex'], NULL),

    -- Lawrence
    ('Lawrence Landscape & Design', 'lawrence-landscape-design', 'landscaping', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Merrimack Green Services', 'merrimack-green-lawrence', 'landscaping', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Garcia Brothers Landscaping', 'garcia-bros-lawrence', 'landscaping', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Tower Hill Lawn Care', 'tower-hill-lawn-lawrence', 'landscaping', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Prospect Hill Property Care', 'prospect-hill-property-lawrence', 'landscaping', NULL, ARRAY['Lawrence','MA','Essex'], NULL),

    -- Lynn
    ('Lynn Landscape & Garden', 'lynn-landscape-garden', 'landscaping', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Nahant Bay Lawn Care', 'nahant-bay-lawn-lynn', 'landscaping', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Diamond Property Services', 'diamond-property-lynn', 'landscaping', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Sargent Brothers Landscaping', 'sargent-bros-lynn', 'landscaping', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Pine Hill Green Services', 'pine-hill-green-lynn', 'landscaping', NULL, ARRAY['Lynn','MA','Essex'], NULL),

    -- Lynnfield
    ('Lynnfield Landscape & Design', 'lynnfield-landscape-design', 'landscaping', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Pillings Pond Lawn Care', 'pillings-pond-lawn-lynnfield', 'landscaping', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Reedy Meadow Landscaping', 'reedy-meadow-lynnfield', 'landscaping', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Kelleher Property Maintenance', 'kelleher-property-lynnfield', 'landscaping', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('MarketStreet Green Services', 'marketstreet-green-lynnfield', 'landscaping', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),

    -- Manchester-by-the-Sea
    ('Manchester Landscape & Garden', 'manchester-landscape-garden-essex', 'landscaping', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Singing Beach Lawn Care', 'singing-beach-lawn-manchester', 'landscaping', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Masconomo Property Services', 'masconomo-property-manchester', 'landscaping', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Tuck Point Landscape Design', 'tuck-point-landscape-manchester', 'landscaping', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Proctor Brothers Landscaping', 'proctor-bros-manchester', 'landscaping', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),

    -- Marblehead
    ('Marblehead Landscape & Garden', 'marblehead-landscape-garden', 'landscaping', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Harbor Light Lawn Care', 'harbor-light-lawn-marblehead', 'landscaping', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Old Town Property Services', 'old-town-property-marblehead', 'landscaping', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Devereux Beach Landscaping', 'devereux-beach-marblehead', 'landscaping', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Goldthwait Landscape Design', 'goldthwait-landscape-marblehead', 'landscaping', NULL, ARRAY['Marblehead','MA','Essex'], NULL),

    -- Merrimac
    ('Merrimac Landscape & Design', 'merrimac-landscape-design', 'landscaping', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Lake Attitash Lawn Care', 'lake-attitash-lawn-merrimac', 'landscaping', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Sargent Property Maintenance', 'sargent-property-merrimac', 'landscaping', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Bear Hill Green Services', 'bear-hill-green-merrimac', 'landscaping', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Merrimac Valley Landscaping', 'merrimac-valley-landscaping', 'landscaping', NULL, ARRAY['Merrimac','MA','Essex'], NULL),

    -- Methuen
    ('Methuen Landscape & Design', 'methuen-landscape-design', 'landscaping', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Searles Pond Lawn Care', 'searles-pond-lawn-methuen', 'landscaping', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Forest Lake Property Services', 'forest-lake-property-methuen', 'landscaping', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Pelletier Brothers Landscaping', 'pelletier-bros-methuen', 'landscaping', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Loop Green Services', 'loop-green-methuen', 'landscaping', NULL, ARRAY['Methuen','MA','Essex'], NULL),

    -- Middleton
    ('Middleton Landscape & Garden', 'middleton-landscape-garden', 'landscaping', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Ipswich River Lawn Care', 'ipswich-river-lawn-middleton', 'landscaping', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Fuller Meadow Landscaping', 'fuller-meadow-middleton', 'landscaping', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Richardson Property Maintenance', 'richardson-property-middleton', 'landscaping', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Middleton Green Works', 'middleton-green-works', 'landscaping', NULL, ARRAY['Middleton','MA','Essex'], NULL),

    -- Nahant
    ('Nahant Landscape & Garden', 'nahant-landscape-garden', 'landscaping', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('East Point Lawn Care', 'east-point-lawn-nahant', 'landscaping', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Bailey Hill Property Services', 'bailey-hill-property-nahant', 'landscaping', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Lodge Park Landscaping', 'lodge-park-nahant', 'landscaping', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Nahant Green Services', 'nahant-green-services', 'landscaping', NULL, ARRAY['Nahant','MA','Essex'], NULL),

    -- Newbury
    ('Newbury Landscape & Design', 'newbury-landscape-design', 'landscaping', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Parker River Lawn Care', 'parker-river-lawn-newbury', 'landscaping', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Plum Island Property Services', 'plum-island-property-newbury', 'landscaping', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Old Town Hill Landscaping', 'old-town-hill-newbury', 'landscaping', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Newbury Green Works', 'newbury-green-works', 'landscaping', NULL, ARRAY['Newbury','MA','Essex'], NULL),

    -- Newburyport
    ('Newburyport Landscape & Garden', 'newburyport-landscape-garden', 'landscaping', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Clipper City Lawn Care', 'clipper-city-lawn-newburyport', 'landscaping', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Moulton Landscape Design', 'moulton-landscape-newburyport', 'landscaping', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Joppa Flats Property Care', 'joppa-flats-property-newburyport', 'landscaping', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Waterfront Green Services', 'waterfront-green-newburyport', 'landscaping', NULL, ARRAY['Newburyport','MA','Essex'], NULL),

    -- North Andover
    ('North Andover Landscape & Design', 'north-andover-landscape-design', 'landscaping', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Lake Cochichewick Lawn Care', 'lake-cochichewick-lawn-nandover', 'landscaping', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Osgood Hill Landscaping', 'osgood-hill-nandover', 'landscaping', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Sutton Property Maintenance', 'sutton-property-nandover', 'landscaping', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Stevens Pond Green Services', 'stevens-pond-green-nandover', 'landscaping', NULL, ARRAY['North Andover','MA','Essex'], NULL),

    -- Peabody
    ('Peabody Landscape & Garden', 'peabody-landscape-garden', 'landscaping', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Brooksby Farm Lawn Care', 'brooksby-farm-lawn-peabody', 'landscaping', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Centennial Property Services', 'centennial-property-peabody', 'landscaping', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('South Peabody Landscaping', 'south-peabody-landscaping', 'landscaping', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Peabody Green Works', 'peabody-green-works', 'landscaping', NULL, ARRAY['Peabody','MA','Essex'], NULL),

    -- Rockport
    ('Rockport Landscape & Garden', 'rockport-landscape-garden', 'landscaping', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Halibut Point Lawn Care', 'halibut-point-lawn-rockport', 'landscaping', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Granite Shore Landscaping', 'granite-shore-rockport', 'landscaping', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Pigeon Cove Property Services', 'pigeon-cove-property-rockport', 'landscaping', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Rockport Green Works', 'rockport-green-works', 'landscaping', NULL, ARRAY['Rockport','MA','Essex'], NULL),

    -- Rowley
    ('Rowley Landscape & Design', 'rowley-landscape-design', 'landscaping', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Mill River Lawn Care', 'mill-river-lawn-rowley', 'landscaping', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Glen Mills Landscaping', 'glen-mills-rowley', 'landscaping', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Dodge Property Maintenance', 'dodge-property-rowley', 'landscaping', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Rowley Green Services', 'rowley-green-services', 'landscaping', NULL, ARRAY['Rowley','MA','Essex'], NULL),

    -- Salem
    ('Salem Landscape & Garden', 'salem-landscape-garden', 'landscaping', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Derby Wharf Lawn Care', 'derby-wharf-lawn-salem', 'landscaping', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('McIntire District Landscaping', 'mcintire-district-salem', 'landscaping', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Gallows Hill Property Services', 'gallows-hill-property-salem', 'landscaping', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Chestnut Street Green Services', 'chestnut-street-green-salem', 'landscaping', NULL, ARRAY['Salem','MA','Essex'], NULL),

    -- Salisbury
    ('Salisbury Landscape & Design', 'salisbury-landscape-design', 'landscaping', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Salisbury Beach Lawn Care', 'salisbury-beach-lawn', 'landscaping', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Ring Island Property Care', 'ring-island-property-salisbury', 'landscaping', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Mudnock Landscaping', 'mudnock-landscaping-salisbury', 'landscaping', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Salisbury Green Works', 'salisbury-green-works', 'landscaping', NULL, ARRAY['Salisbury','MA','Essex'], NULL),

    -- Saugus
    ('Saugus Landscape & Design', 'saugus-landscape-design', 'landscaping', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Breakheart Lawn Care', 'breakheart-lawn-saugus', 'landscaping', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Pranker Brothers Landscaping', 'pranker-bros-saugus', 'landscaping', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Saugus River Property Services', 'saugus-river-property', 'landscaping', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Cliftondale Green Services', 'cliftondale-green-saugus', 'landscaping', NULL, ARRAY['Saugus','MA','Essex'], NULL),

    -- Swampscott
    ('Swampscott Landscape & Garden', 'swampscott-landscape-garden', 'landscaping', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('King''s Beach Lawn Care', 'kings-beach-lawn-swampscott', 'landscaping', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Olmsted Property Services', 'olmsted-property-swampscott', 'landscaping', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Phillips Point Landscaping', 'phillips-point-swampscott', 'landscaping', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Swampscott Green Works', 'swampscott-green-works', 'landscaping', NULL, ARRAY['Swampscott','MA','Essex'], NULL),

    -- Topsfield
    ('Topsfield Landscape & Design', 'topsfield-landscape-design', 'landscaping', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Topsfield Fair Lawn Care', 'topsfield-fair-lawn', 'landscaping', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Howlett Brook Landscaping', 'howlett-brook-topsfield', 'landscaping', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Perkins Property Maintenance', 'perkins-property-topsfield', 'landscaping', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Topsfield Green Services', 'topsfield-green-services', 'landscaping', NULL, ARRAY['Topsfield','MA','Essex'], NULL),

    -- Wenham
    ('Wenham Landscape & Garden', 'wenham-landscape-garden', 'landscaping', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Pleasant Pond Lawn Care', 'pleasant-pond-lawn-wenham', 'landscaping', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Larch Row Landscaping', 'larch-row-wenham', 'landscaping', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Endicott Property Services', 'endicott-property-wenham', 'landscaping', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Wenham Green Works', 'wenham-green-works', 'landscaping', NULL, ARRAY['Wenham','MA','Essex'], NULL),

    -- West Newbury
    ('West Newbury Landscape & Design', 'west-newbury-landscape-design', 'landscaping', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('Indian Hill Lawn Care', 'indian-hill-lawn-wnewbury', 'landscaping', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('Artichoke River Landscaping', 'artichoke-river-wnewbury', 'landscaping', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('Coffin Property Maintenance', 'coffin-property-wnewbury', 'landscaping', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('West Newbury Green Services', 'west-newbury-green-services', 'landscaping', NULL, ARRAY['West Newbury','MA','Essex'], NULL)

ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;


-- ============================================================================
-- SECTION 3: MIDDLESEX COUNTY, MA -- LOCAL LANDSCAPING FIRMS
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES

    -- Acton
    ('Acton Landscape & Design', 'acton-landscape-design', 'landscaping', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Great Hill Lawn Care', 'great-hill-lawn-acton', 'landscaping', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Nashoba Brook Landscaping', 'nashoba-brook-acton', 'landscaping', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Flannery Property Services', 'flannery-property-acton', 'landscaping', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('West Acton Green Works', 'west-acton-green-works', 'landscaping', NULL, ARRAY['Acton','MA','Middlesex'], NULL),

    -- Arlington
    ('Arlington Landscape & Garden', 'arlington-landscape-garden', 'landscaping', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Spy Pond Lawn Care', 'spy-pond-lawn-arlington', 'landscaping', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Menotomy Landscaping', 'menotomy-landscaping-arlington', 'landscaping', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Heights Property Maintenance', 'heights-property-arlington', 'landscaping', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Arlington Green Services', 'arlington-green-services', 'landscaping', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),

    -- Ashby
    ('Ashby Landscape & Design', 'ashby-landscape-design', 'landscaping', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Watatic Mountain Lawn Care', 'watatic-mountain-lawn-ashby', 'landscaping', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('South Road Landscaping', 'south-road-ashby', 'landscaping', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Ashby Property Maintenance', 'ashby-property-maintenance', 'landscaping', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Fitchburg Road Green Services', 'fitchburg-road-green-ashby', 'landscaping', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),

    -- Ashland
    ('Ashland Landscape & Design', 'ashland-landscape-design', 'landscaping', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Reservoir Lawn Care', 'reservoir-lawn-ashland', 'landscaping', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Sudbury River Landscaping', 'sudbury-river-ashland', 'landscaping', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Warren Property Services', 'warren-property-ashland', 'landscaping', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Ashland Green Works', 'ashland-green-works', 'landscaping', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),

    -- Ayer
    ('Ayer Landscape & Design', 'ayer-landscape-design', 'landscaping', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Sandy Pond Lawn Care', 'sandy-pond-lawn-ayer', 'landscaping', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Nashua River Landscaping', 'nashua-river-ayer', 'landscaping', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Devens Property Maintenance', 'devens-property-ayer', 'landscaping', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Ayer Green Services', 'ayer-green-services', 'landscaping', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),

    -- Bedford
    ('Bedford Landscape & Design', 'bedford-landscape-design', 'landscaping', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Springs Brook Lawn Care', 'springs-brook-lawn-bedford', 'landscaping', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Fawn Lake Landscaping', 'fawn-lake-bedford', 'landscaping', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Page Property Services', 'page-property-bedford', 'landscaping', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Bedford Green Works', 'bedford-green-works', 'landscaping', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),

    -- Belmont
    ('Belmont Landscape & Garden', 'belmont-landscape-garden', 'landscaping', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Fresh Pond Lawn Care', 'fresh-pond-lawn-belmont', 'landscaping', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Belmont Hill Landscaping', 'belmont-hill-landscaping', 'landscaping', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Payson Park Property Services', 'payson-park-property-belmont', 'landscaping', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Belmont Green Services', 'belmont-green-services', 'landscaping', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),

    -- Billerica
    ('Billerica Landscape & Design', 'billerica-landscape-design', 'landscaping', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Nuttings Lake Lawn Care', 'nuttings-lake-lawn-billerica', 'landscaping', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Concord River Landscaping', 'concord-river-billerica', 'landscaping', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Manning Property Maintenance', 'manning-property-billerica', 'landscaping', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Billerica Green Works', 'billerica-green-works', 'landscaping', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),

    -- Boxborough
    ('Boxborough Landscape & Design', 'boxborough-landscape-design', 'landscaping', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Flerra Meadows Lawn Care', 'flerra-meadows-lawn-boxborough', 'landscaping', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Blanchard Landscaping', 'blanchard-landscaping-boxborough', 'landscaping', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Boxborough Property Care', 'boxborough-property-care', 'landscaping', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Codman Hill Green Services', 'codman-hill-green-boxborough', 'landscaping', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),

    -- Burlington
    ('Burlington Landscape & Design', 'burlington-landscape-design', 'landscaping', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Mill Pond Lawn Care', 'mill-pond-lawn-burlington', 'landscaping', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Simonds Park Landscaping', 'simonds-park-burlington', 'landscaping', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Murray Property Services', 'murray-property-burlington', 'landscaping', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Burlington Green Works', 'burlington-green-works', 'landscaping', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),

    -- Cambridge
    ('Cambridge Landscape & Garden', 'cambridge-landscape-garden', 'landscaping', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Fresh Pond Landscaping', 'fresh-pond-landscaping-cambridge', 'landscaping', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Porter Square Lawn Care', 'porter-square-lawn-cambridge', 'landscaping', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Brattle Street Property Services', 'brattle-street-property-cambridge', 'landscaping', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Cambridge Green Works', 'cambridge-green-works', 'landscaping', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),

    -- Carlisle
    ('Carlisle Landscape & Design', 'carlisle-landscape-design', 'landscaping', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Cranberry Bog Lawn Care', 'cranberry-bog-lawn-carlisle', 'landscaping', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Great Brook Landscaping', 'great-brook-carlisle', 'landscaping', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Banta-Davis Property Services', 'banta-davis-property-carlisle', 'landscaping', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Carlisle Green Works', 'carlisle-green-works', 'landscaping', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),

    -- Chelmsford
    ('Chelmsford Landscape & Design', 'chelmsford-landscape-design', 'landscaping', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Heart Pond Lawn Care', 'heart-pond-lawn-chelmsford', 'landscaping', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Vinal Square Landscaping', 'vinal-square-chelmsford', 'landscaping', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Barrett Property Maintenance', 'barrett-property-chelmsford', 'landscaping', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('North Chelmsford Green Services', 'north-chelmsford-green', 'landscaping', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),

    -- Concord
    ('Concord Landscape & Garden', 'concord-landscape-garden', 'landscaping', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Walden Pond Lawn Care', 'walden-pond-lawn-concord', 'landscaping', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Nine Acre Corner Landscaping', 'nine-acre-corner-concord', 'landscaping', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Barrett Farm Property Services', 'barrett-farm-property-concord', 'landscaping', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Concord Green Works', 'concord-green-works', 'landscaping', NULL, ARRAY['Concord','MA','Middlesex'], NULL),

    -- Dracut
    ('Dracut Landscape & Design', 'dracut-landscape-design', 'landscaping', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Long Pond Lawn Care', 'long-pond-lawn-dracut', 'landscaping', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Richardson Brothers Landscaping', 'richardson-bros-dracut', 'landscaping', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Collinsville Property Maintenance', 'collinsville-property-dracut', 'landscaping', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Dracut Green Services', 'dracut-green-services', 'landscaping', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),

    -- Dunstable
    ('Dunstable Landscape & Design', 'dunstable-landscape-design', 'landscaping', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Salmon Brook Lawn Care', 'salmon-brook-lawn-dunstable', 'landscaping', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Hollis Road Landscaping', 'hollis-road-dunstable', 'landscaping', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Dunstable Property Maintenance', 'dunstable-property-maintenance', 'landscaping', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Dunstable Green Works', 'dunstable-green-works', 'landscaping', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),

    -- Everett
    ('Everett Landscape & Design', 'everett-landscape-design', 'landscaping', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Malden River Lawn Care', 'malden-river-lawn-everett', 'landscaping', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Glendale Landscaping', 'glendale-landscaping-everett', 'landscaping', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Ferreira Property Services', 'ferreira-property-everett', 'landscaping', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Everett Green Works', 'everett-green-works', 'landscaping', NULL, ARRAY['Everett','MA','Middlesex'], NULL),

    -- Framingham
    ('Framingham Landscape & Design', 'framingham-landscape-design', 'landscaping', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Nobscot Lawn Care', 'nobscot-lawn-framingham', 'landscaping', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Farm Pond Landscaping', 'farm-pond-framingham', 'landscaping', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Saxonville Property Maintenance', 'saxonville-property-framingham', 'landscaping', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Framingham Green Services', 'framingham-green-services', 'landscaping', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),

    -- Groton
    ('Groton Landscape & Design', 'groton-landscape-design', 'landscaping', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Gibbet Hill Lawn Care', 'gibbet-hill-lawn-groton', 'landscaping', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Surrenden Farm Landscaping', 'surrenden-farm-groton', 'landscaping', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Prescott Property Services', 'prescott-property-groton', 'landscaping', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Groton Green Works', 'groton-green-works', 'landscaping', NULL, ARRAY['Groton','MA','Middlesex'], NULL),

    -- Holliston
    ('Holliston Landscape & Design', 'holliston-landscape-design', 'landscaping', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Lake Winthrop Lawn Care', 'lake-winthrop-lawn-holliston', 'landscaping', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Highland Street Landscaping', 'highland-street-holliston', 'landscaping', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Phipps Property Maintenance', 'phipps-property-holliston', 'landscaping', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Holliston Green Services', 'holliston-green-services', 'landscaping', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),

    -- Hopkinton
    ('Hopkinton Landscape & Design', 'hopkinton-landscape-design', 'landscaping', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Whitehall Lawn Care', 'whitehall-lawn-hopkinton', 'landscaping', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Marathon Landscaping', 'marathon-landscaping-hopkinton', 'landscaping', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Claflin Property Services', 'claflin-property-hopkinton', 'landscaping', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Hopkinton Green Works', 'hopkinton-green-works', 'landscaping', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),

    -- Hudson
    ('Hudson Landscape & Design', 'hudson-landscape-design', 'landscaping', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Centennial Beach Lawn Care', 'centennial-beach-lawn-hudson', 'landscaping', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Assabet River Landscaping', 'assabet-river-hudson', 'landscaping', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Brigham Property Maintenance', 'brigham-property-hudson', 'landscaping', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Hudson Green Services', 'hudson-green-services', 'landscaping', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),

    -- Lexington
    ('Lexington Landscape & Garden', 'lexington-landscape-garden', 'landscaping', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Battle Green Lawn Care', 'battle-green-lawn-lexington', 'landscaping', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Minuteman Landscaping', 'minuteman-landscaping-lexington', 'landscaping', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Hancock Property Services', 'hancock-property-lexington', 'landscaping', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Lexington Green Works', 'lexington-green-works', 'landscaping', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),

    -- Lincoln
    ('Lincoln Landscape & Design', 'lincoln-landscape-design', 'landscaping', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Codman Farm Lawn Care', 'codman-farm-lawn-lincoln', 'landscaping', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Sandy Pond Landscaping', 'sandy-pond-lincoln', 'landscaping', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('DeCordova Property Services', 'decordova-property-lincoln', 'landscaping', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Lincoln Green Works', 'lincoln-green-works', 'landscaping', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),

    -- Littleton
    ('Littleton Landscape & Design', 'littleton-landscape-design', 'landscaping', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Long Lake Lawn Care', 'long-lake-lawn-littleton', 'landscaping', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Whitcomb Avenue Landscaping', 'whitcomb-avenue-littleton', 'landscaping', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Shaker Property Maintenance', 'shaker-property-littleton', 'landscaping', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Littleton Green Services', 'littleton-green-services', 'landscaping', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),

    -- Lowell
    ('Lowell Landscape & Design', 'lowell-landscape-design', 'landscaping', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Pawtucketville Lawn Care', 'pawtucketville-lawn-lowell', 'landscaping', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Merrimack Brothers Landscaping', 'merrimack-bros-lowell', 'landscaping', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Centralville Property Services', 'centralville-property-lowell', 'landscaping', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Lowell Green Works', 'lowell-green-works', 'landscaping', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),

    -- Malden
    ('Malden Landscape & Design', 'malden-landscape-design', 'landscaping', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Fellsway Lawn Care', 'fellsway-lawn-malden', 'landscaping', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Maplewood Landscaping', 'maplewood-landscaping-malden', 'landscaping', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Bell Rock Property Services', 'bell-rock-property-malden', 'landscaping', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Malden Green Works', 'malden-green-works', 'landscaping', NULL, ARRAY['Malden','MA','Middlesex'], NULL),

    -- Marlborough
    ('Marlborough Landscape & Design', 'marlborough-landscape-design', 'landscaping', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Fort Meadow Lawn Care', 'fort-meadow-lawn-marlborough', 'landscaping', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Ghiloni Park Landscaping', 'ghiloni-park-marlborough', 'landscaping', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Ward Property Maintenance', 'ward-property-marlborough', 'landscaping', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Marlborough Green Services', 'marlborough-green-services', 'landscaping', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),

    -- Maynard
    ('Maynard Landscape & Design', 'maynard-landscape-design', 'landscaping', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Assabet Village Lawn Care', 'assabet-village-lawn-maynard', 'landscaping', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Maynard Brothers Landscaping', 'maynard-bros-landscaping', 'landscaping', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Summer Hill Property Services', 'summer-hill-property-maynard', 'landscaping', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Maynard Green Works', 'maynard-green-works', 'landscaping', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),

    -- Medford
    ('Medford Landscape & Garden', 'medford-landscape-garden', 'landscaping', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Mystic River Lawn Care', 'mystic-river-lawn-medford', 'landscaping', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Tufts Neighborhood Landscaping', 'tufts-neighborhood-medford', 'landscaping', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('West Medford Property Services', 'west-medford-property', 'landscaping', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Medford Green Works', 'medford-green-works', 'landscaping', NULL, ARRAY['Medford','MA','Middlesex'], NULL),

    -- Melrose
    ('Melrose Landscape & Design', 'melrose-landscape-design', 'landscaping', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Ell Pond Lawn Care', 'ell-pond-lawn-melrose', 'landscaping', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Wyoming Hill Landscaping', 'wyoming-hill-melrose', 'landscaping', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Fells Property Maintenance', 'fells-property-melrose', 'landscaping', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Melrose Green Services', 'melrose-green-services', 'landscaping', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),

    -- Natick
    ('Natick Landscape & Garden', 'natick-landscape-garden', 'landscaping', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Lake Cochituate Lawn Care', 'lake-cochituate-lawn-natick', 'landscaping', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('South Natick Landscaping', 'south-natick-landscaping', 'landscaping', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Casey Property Services', 'casey-property-natick', 'landscaping', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Natick Green Works', 'natick-green-works', 'landscaping', NULL, ARRAY['Natick','MA','Middlesex'], NULL),

    -- Newton
    ('Newton Landscape & Garden', 'newton-landscape-garden', 'landscaping', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Crystal Lake Lawn Care', 'crystal-lake-lawn-newton', 'landscaping', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Chestnut Hill Landscaping', 'chestnut-hill-landscaping-newton', 'landscaping', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Auburndale Property Services', 'auburndale-property-newton', 'landscaping', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Newton Highlands Green Works', 'newton-highlands-green-works', 'landscaping', NULL, ARRAY['Newton','MA','Middlesex'], NULL),

    -- North Reading
    ('North Reading Landscape & Design', 'north-reading-landscape-design', 'landscaping', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('Martin''s Pond Lawn Care', 'martins-pond-lawn-nreading', 'landscaping', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('Ipswich River Landscaping', 'ipswich-river-nreading', 'landscaping', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('Flint Property Maintenance', 'flint-property-nreading', 'landscaping', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('North Reading Green Services', 'north-reading-green-services', 'landscaping', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),

    -- Pepperell
    ('Pepperell Landscape & Design', 'pepperell-landscape-design', 'landscaping', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Nissitissit River Lawn Care', 'nissitissit-lawn-pepperell', 'landscaping', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Covered Bridge Landscaping', 'covered-bridge-pepperell', 'landscaping', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Heald Property Services', 'heald-property-pepperell', 'landscaping', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Pepperell Green Works', 'pepperell-green-works', 'landscaping', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),

    -- Reading
    ('Reading Landscape & Design', 'reading-landscape-design', 'landscaping', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Bare Meadow Lawn Care', 'bare-meadow-lawn-reading', 'landscaping', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Birch Meadow Landscaping', 'birch-meadow-reading', 'landscaping', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Parker Property Maintenance', 'parker-property-reading', 'landscaping', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Reading Green Services', 'reading-green-services', 'landscaping', NULL, ARRAY['Reading','MA','Middlesex'], NULL),

    -- Sherborn
    ('Sherborn Landscape & Design', 'sherborn-landscape-design', 'landscaping', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Farm Road Lawn Care', 'farm-road-lawn-sherborn', 'landscaping', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Pine Hill Landscaping', 'pine-hill-sherborn', 'landscaping', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Dowse Property Services', 'dowse-property-sherborn', 'landscaping', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Sherborn Green Works', 'sherborn-green-works', 'landscaping', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),

    -- Shirley
    ('Shirley Landscape & Design', 'shirley-landscape-design', 'landscaping', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Catacunemaug Lawn Care', 'catacunemaug-lawn-shirley', 'landscaping', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Shirley Village Landscaping', 'shirley-village-landscaping', 'landscaping', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Hazen Property Maintenance', 'hazen-property-shirley', 'landscaping', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Shirley Green Services', 'shirley-green-services', 'landscaping', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),

    -- Somerville
    ('Somerville Landscape & Design', 'somerville-landscape-design', 'landscaping', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Prospect Hill Lawn Care', 'prospect-hill-lawn-somerville', 'landscaping', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Davis Square Landscaping', 'davis-square-somerville', 'landscaping', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Winter Hill Property Services', 'winter-hill-property-somerville', 'landscaping', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Somerville Green Works', 'somerville-green-works', 'landscaping', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),

    -- Stoneham
    ('Stoneham Landscape & Design', 'stoneham-landscape-design', 'landscaping', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Spot Pond Lawn Care', 'spot-pond-lawn-stoneham', 'landscaping', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Unicorn Park Landscaping', 'unicorn-park-stoneham', 'landscaping', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Gould Property Maintenance', 'gould-property-stoneham', 'landscaping', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Stoneham Green Services', 'stoneham-green-services', 'landscaping', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),

    -- Stow
    ('Stow Landscape & Design', 'stow-landscape-design', 'landscaping', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Lake Boon Lawn Care', 'lake-boon-lawn-stow', 'landscaping', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Pilot Grove Landscaping', 'pilot-grove-stow', 'landscaping', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Croak Property Services', 'croak-property-stow', 'landscaping', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Stow Green Works', 'stow-green-works', 'landscaping', NULL, ARRAY['Stow','MA','Middlesex'], NULL),

    -- Sudbury
    ('Sudbury Landscape & Garden', 'sudbury-landscape-garden', 'landscaping', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Hop Brook Lawn Care', 'hop-brook-lawn-sudbury', 'landscaping', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Longfellow Landscaping', 'longfellow-landscaping-sudbury', 'landscaping', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Wayside Inn Property Services', 'wayside-inn-property-sudbury', 'landscaping', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Sudbury Green Works', 'sudbury-green-works', 'landscaping', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),

    -- Tewksbury
    ('Tewksbury Landscape & Design', 'tewksbury-landscape-design', 'landscaping', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Shawsheen River Lawn Care', 'shawsheen-river-lawn-tewksbury', 'landscaping', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Livingston Street Landscaping', 'livingston-street-tewksbury', 'landscaping', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Chandler Property Maintenance', 'chandler-property-tewksbury', 'landscaping', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Tewksbury Green Services', 'tewksbury-green-services', 'landscaping', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),

    -- Townsend
    ('Townsend Landscape & Design', 'townsend-landscape-design', 'landscaping', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Pearl Hill Lawn Care', 'pearl-hill-lawn-townsend', 'landscaping', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Mason Road Landscaping', 'mason-road-townsend', 'landscaping', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Spaulding Property Services', 'spaulding-property-townsend', 'landscaping', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Townsend Green Works', 'townsend-green-works', 'landscaping', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),

    -- Tyngsborough
    ('Tyngsborough Landscape & Design', 'tyngsborough-landscape-design', 'landscaping', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Mascuppic Lake Lawn Care', 'mascuppic-lake-lawn-tyngsborough', 'landscaping', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Sherburne Brothers Landscaping', 'sherburne-bros-tyngsborough', 'landscaping', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Tyng Property Maintenance', 'tyng-property-tyngsborough', 'landscaping', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Tyngsborough Green Services', 'tyngsborough-green-services', 'landscaping', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),

    -- Wakefield
    ('Wakefield Landscape & Design', 'wakefield-landscape-design', 'landscaping', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Lake Quannapowitt Lawn Care', 'lake-quannapowitt-lawn-wakefield', 'landscaping', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Greenwood Landscaping', 'greenwood-landscaping-wakefield', 'landscaping', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Crystal Property Services', 'crystal-property-wakefield', 'landscaping', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Wakefield Green Works', 'wakefield-green-works', 'landscaping', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),

    -- Waltham
    ('Waltham Landscape & Garden', 'waltham-landscape-garden', 'landscaping', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Hardy Pond Lawn Care', 'hardy-pond-lawn-waltham', 'landscaping', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Lyman Estate Landscaping', 'lyman-estate-waltham', 'landscaping', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Prospect Hill Property Services', 'prospect-hill-property-waltham', 'landscaping', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Waltham Green Works', 'waltham-green-works', 'landscaping', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),

    -- Watertown
    ('Watertown Landscape & Design', 'watertown-landscape-design', 'landscaping', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Arsenal Lawn Care', 'arsenal-lawn-watertown', 'landscaping', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Mount Auburn Landscaping', 'mount-auburn-watertown', 'landscaping', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Saltonstall Property Maintenance', 'saltonstall-property-watertown', 'landscaping', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Watertown Green Services', 'watertown-green-services', 'landscaping', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),

    -- Wayland
    ('Wayland Landscape & Garden', 'wayland-landscape-garden', 'landscaping', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Heard Pond Lawn Care', 'heard-pond-lawn-wayland', 'landscaping', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Old Sudbury Road Landscaping', 'old-sudbury-road-wayland', 'landscaping', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Paine Property Services', 'paine-property-wayland', 'landscaping', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Wayland Green Works', 'wayland-green-works', 'landscaping', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),

    -- Westford
    ('Westford Landscape & Design', 'westford-landscape-design', 'landscaping', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Forge Pond Lawn Care', 'forge-pond-lawn-westford', 'landscaping', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Stony Brook Landscaping', 'stony-brook-westford', 'landscaping', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Fletcher Property Maintenance', 'fletcher-property-westford', 'landscaping', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Westford Green Services', 'westford-green-services', 'landscaping', NULL, ARRAY['Westford','MA','Middlesex'], NULL),

    -- Weston
    ('Weston Landscape & Garden', 'weston-landscape-garden', 'landscaping', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Cat Rock Lawn Care', 'cat-rock-lawn-weston', 'landscaping', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Alphabet Lane Landscaping', 'alphabet-lane-weston', 'landscaping', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Coburn Property Services', 'coburn-property-weston', 'landscaping', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Weston Green Works', 'weston-green-works', 'landscaping', NULL, ARRAY['Weston','MA','Middlesex'], NULL),

    -- Wilmington
    ('Wilmington Landscape & Design', 'wilmington-landscape-design', 'landscaping', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Silver Lake Lawn Care', 'silver-lake-lawn-wilmington', 'landscaping', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Butters Row Landscaping', 'butters-row-wilmington', 'landscaping', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Carter Property Maintenance', 'carter-property-wilmington', 'landscaping', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Wilmington Green Services', 'wilmington-green-services', 'landscaping', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),

    -- Winchester
    ('Winchester Landscape & Garden', 'winchester-landscape-garden', 'landscaping', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Wedge Pond Lawn Care', 'wedge-pond-lawn-winchester', 'landscaping', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Fells Reservoir Landscaping', 'fells-reservoir-winchester', 'landscaping', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Sanborn Property Services', 'sanborn-property-winchester', 'landscaping', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Winchester Green Works', 'winchester-green-works', 'landscaping', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),

    -- Woburn
    ('Woburn Landscape & Design', 'woburn-landscape-design', 'landscaping', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Horn Pond Lawn Care', 'horn-pond-lawn-woburn', 'landscaping', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('North Woburn Landscaping', 'north-woburn-landscaping', 'landscaping', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Montvale Property Maintenance', 'montvale-property-woburn', 'landscaping', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Woburn Green Services', 'woburn-green-services', 'landscaping', NULL, ARRAY['Woburn','MA','Middlesex'], NULL)

ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;


-- ============================================================================
-- SECTION 4: NORFOLK COUNTY, MA -- LOCAL LANDSCAPING FIRMS
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES

    -- Avon
    ('Avon Landscape & Design', 'avon-landscape-design', 'landscaping', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Crescent Lawn Care', 'crescent-lawn-avon', 'landscaping', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Buckley Brothers Landscaping', 'buckley-bros-avon', 'landscaping', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Avon Industrial Property Services', 'avon-industrial-property', 'landscaping', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Avon Green Works', 'avon-green-works', 'landscaping', NULL, ARRAY['Avon','MA','Norfolk'], NULL),

    -- Braintree
    ('Braintree Landscape & Design', 'braintree-landscape-design', 'landscaping', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Sunset Lake Lawn Care', 'sunset-lake-lawn-braintree', 'landscaping', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Braintree Highlands Landscaping', 'braintree-highlands-landscaping', 'landscaping', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Watson Property Maintenance', 'watson-property-braintree', 'landscaping', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('South Braintree Green Services', 'south-braintree-green', 'landscaping', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),

    -- Brookline
    ('Brookline Landscape & Garden', 'brookline-landscape-garden', 'landscaping', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Larz Anderson Lawn Care', 'larz-anderson-lawn-brookline', 'landscaping', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Chestnut Hill Landscape Design', 'chestnut-hill-landscape-brookline', 'landscaping', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Coolidge Corner Property Services', 'coolidge-corner-property-brookline', 'landscaping', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Brookline Village Green Works', 'brookline-village-green-works', 'landscaping', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),

    -- Canton
    ('Canton Landscape & Design', 'canton-landscape-design', 'landscaping', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Ponkapoag Lawn Care', 'ponkapoag-lawn-canton', 'landscaping', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Blue Hills Landscaping', 'blue-hills-landscaping-canton', 'landscaping', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Draper Property Services', 'draper-property-canton', 'landscaping', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Canton Green Works', 'canton-green-works', 'landscaping', NULL, ARRAY['Canton','MA','Norfolk'], NULL),

    -- Cohasset
    ('Cohasset Landscape & Garden', 'cohasset-landscape-garden', 'landscaping', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Sandy Cove Lawn Care', 'sandy-cove-lawn-cohasset', 'landscaping', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Beechwood Landscaping', 'beechwood-landscaping-cohasset', 'landscaping', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Pratt Property Maintenance', 'pratt-property-cohasset', 'landscaping', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Cohasset Harbor Green Services', 'cohasset-harbor-green', 'landscaping', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),

    -- Dedham
    ('Dedham Landscape & Design', 'dedham-landscape-design', 'landscaping', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Mother Brook Lawn Care', 'mother-brook-lawn-dedham', 'landscaping', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Endicott Estate Landscaping', 'endicott-estate-dedham', 'landscaping', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Noble Property Services', 'noble-property-dedham', 'landscaping', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Dedham Green Works', 'dedham-green-works', 'landscaping', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),

    -- Dover
    ('Dover Landscape & Garden', 'dover-landscape-garden', 'landscaping', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Farm Street Lawn Care', 'farm-street-lawn-dover', 'landscaping', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Noanet Woodlands Landscaping', 'noanet-woodlands-dover', 'landscaping', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Springdale Property Services', 'springdale-property-dover', 'landscaping', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Dover Green Works', 'dover-green-works', 'landscaping', NULL, ARRAY['Dover','MA','Norfolk'], NULL),

    -- Foxborough
    ('Foxborough Landscape & Design', 'foxborough-landscape-design', 'landscaping', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Neponset Lawn Care', 'neponset-lawn-foxborough', 'landscaping', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Patriot Landscaping', 'patriot-landscaping-foxborough', 'landscaping', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Cocasset Property Maintenance', 'cocasset-property-foxborough', 'landscaping', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Foxborough Green Services', 'foxborough-green-services', 'landscaping', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),

    -- Franklin
    ('Franklin Landscape & Design', 'franklin-landscape-design', 'landscaping', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('DelCarte Lawn Care', 'delcarte-lawn-franklin', 'landscaping', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Mine Brook Landscaping', 'mine-brook-franklin', 'landscaping', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Ray Property Services', 'ray-property-franklin', 'landscaping', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Franklin Green Works', 'franklin-green-works', 'landscaping', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),

    -- Holbrook
    ('Holbrook Landscape & Design', 'holbrook-landscape-design', 'landscaping', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('South Brook Lawn Care', 'south-brook-lawn-holbrook', 'landscaping', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Cochato Landscaping', 'cochato-landscaping-holbrook', 'landscaping', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Holbrook Property Maintenance', 'holbrook-property-maintenance', 'landscaping', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Holbrook Green Services', 'holbrook-green-services', 'landscaping', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),

    -- Medfield
    ('Medfield Landscape & Garden', 'medfield-landscape-garden', 'landscaping', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Noon Hill Lawn Care', 'noon-hill-lawn-medfield', 'landscaping', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Rocky Woods Landscaping', 'rocky-woods-medfield', 'landscaping', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Dale Street Property Services', 'dale-street-property-medfield', 'landscaping', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Medfield Green Works', 'medfield-green-works', 'landscaping', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),

    -- Medway
    ('Medway Landscape & Design', 'medway-landscape-design', 'landscaping', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Choate Park Lawn Care', 'choate-park-lawn-medway', 'landscaping', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Charles River Landscaping', 'charles-river-medway', 'landscaping', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Lovering Property Maintenance', 'lovering-property-medway', 'landscaping', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Medway Green Services', 'medway-green-services', 'landscaping', NULL, ARRAY['Medway','MA','Norfolk'], NULL),

    -- Millis
    ('Millis Landscape & Design', 'millis-landscape-design', 'landscaping', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Bogastow Brook Lawn Care', 'bogastow-brook-lawn-millis', 'landscaping', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Oak Grove Landscaping', 'oak-grove-millis', 'landscaping', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Richardson Property Services', 'richardson-property-millis', 'landscaping', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Millis Green Works', 'millis-green-works', 'landscaping', NULL, ARRAY['Millis','MA','Norfolk'], NULL),

    -- Milton
    ('Milton Landscape & Garden', 'milton-landscape-garden', 'landscaping', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Houghton Pond Lawn Care', 'houghton-pond-lawn-milton', 'landscaping', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Blue Hills Parkway Landscaping', 'blue-hills-parkway-milton', 'landscaping', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Forbes Property Services', 'forbes-property-milton', 'landscaping', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Milton Village Green Works', 'milton-village-green-works', 'landscaping', NULL, ARRAY['Milton','MA','Norfolk'], NULL),

    -- Needham
    ('Needham Landscape & Garden', 'needham-landscape-garden', 'landscaping', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Ridge Hill Lawn Care', 'ridge-hill-lawn-needham', 'landscaping', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Cutler Park Landscaping', 'cutler-park-needham', 'landscaping', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Eaton Property Services', 'eaton-property-needham', 'landscaping', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Needham Green Works', 'needham-green-works', 'landscaping', NULL, ARRAY['Needham','MA','Norfolk'], NULL),

    -- Norfolk
    ('Norfolk Landscape & Design', 'norfolk-landscape-design', 'landscaping', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Stony Brook Lawn Care', 'stony-brook-lawn-norfolk', 'landscaping', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Campbell Landscaping', 'campbell-landscaping-norfolk', 'landscaping', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('King Street Property Maintenance', 'king-street-property-norfolk', 'landscaping', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Norfolk Green Services', 'norfolk-green-services', 'landscaping', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),

    -- Norwood
    ('Norwood Landscape & Design', 'norwood-landscape-design', 'landscaping', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Hawes Brook Lawn Care', 'hawes-brook-lawn-norwood', 'landscaping', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Guild Street Landscaping', 'guild-street-norwood', 'landscaping', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Morrill Property Services', 'morrill-property-norwood', 'landscaping', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Norwood Green Works', 'norwood-green-works', 'landscaping', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),

    -- Plainville
    ('Plainville Landscape & Design', 'plainville-landscape-design', 'landscaping', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Turnpike Lake Lawn Care', 'turnpike-lake-lawn-plainville', 'landscaping', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Shepard Landscaping', 'shepard-landscaping-plainville', 'landscaping', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Plainville Property Maintenance', 'plainville-property-maintenance', 'landscaping', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Plainville Green Services', 'plainville-green-services', 'landscaping', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),

    -- Quincy
    ('Quincy Landscape & Design', 'quincy-landscape-design', 'landscaping', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Wollaston Beach Lawn Care', 'wollaston-beach-lawn-quincy', 'landscaping', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Presidents City Landscaping', 'presidents-city-quincy', 'landscaping', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Merrymount Property Services', 'merrymount-property-quincy', 'landscaping', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Quincy Green Works', 'quincy-green-works', 'landscaping', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),

    -- Randolph
    ('Randolph Landscape & Design', 'randolph-landscape-design', 'landscaping', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Great Pond Lawn Care', 'great-pond-lawn-randolph', 'landscaping', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Belcher Landscaping', 'belcher-landscaping-randolph', 'landscaping', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Powers Property Maintenance', 'powers-property-randolph', 'landscaping', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Randolph Green Services', 'randolph-green-services', 'landscaping', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),

    -- Sharon
    ('Sharon Landscape & Garden', 'sharon-landscape-garden', 'landscaping', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Lake Massapoag Lawn Care', 'lake-massapoag-lawn-sharon', 'landscaping', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Moose Hill Landscaping', 'moose-hill-sharon', 'landscaping', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Billings Property Services', 'billings-property-sharon', 'landscaping', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Sharon Green Works', 'sharon-green-works', 'landscaping', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),

    -- Stoughton
    ('Stoughton Landscape & Design', 'stoughton-landscape-design', 'landscaping', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Ames Pond Lawn Care', 'ames-pond-lawn-stoughton', 'landscaping', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Faxon Brothers Landscaping', 'faxon-bros-stoughton', 'landscaping', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Bird Property Maintenance', 'bird-property-stoughton', 'landscaping', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Stoughton Green Services', 'stoughton-green-services', 'landscaping', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),

    -- Walpole
    ('Walpole Landscape & Design', 'walpole-landscape-design', 'landscaping', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Spring Brook Lawn Care', 'spring-brook-lawn-walpole', 'landscaping', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Bird Park Landscaping', 'bird-park-walpole', 'landscaping', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Boyden Property Services', 'boyden-property-walpole', 'landscaping', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Walpole Green Works', 'walpole-green-works', 'landscaping', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),

    -- Wellesley
    ('Wellesley Landscape & Garden', 'wellesley-landscape-garden', 'landscaping', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Lake Waban Lawn Care', 'lake-waban-lawn-wellesley', 'landscaping', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Hunnewell Landscaping', 'hunnewell-landscaping-wellesley', 'landscaping', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Dana Hall Property Services', 'dana-hall-property-wellesley', 'landscaping', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Wellesley Hills Green Works', 'wellesley-hills-green-works', 'landscaping', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),

    -- Westwood
    ('Westwood Landscape & Design', 'westwood-landscape-design', 'landscaping', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Buckmaster Pond Lawn Care', 'buckmaster-pond-lawn-westwood', 'landscaping', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Hale Reservation Landscaping', 'hale-reservation-westwood', 'landscaping', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Colburn Property Maintenance', 'colburn-property-westwood', 'landscaping', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Westwood Green Services', 'westwood-green-services', 'landscaping', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),

    -- Weymouth
    ('Weymouth Landscape & Design', 'weymouth-landscape-design', 'landscaping', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Great Esker Lawn Care', 'great-esker-lawn-weymouth', 'landscaping', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Whitman Pond Landscaping', 'whitman-pond-weymouth', 'landscaping', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Torrey Property Services', 'torrey-property-weymouth', 'landscaping', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Weymouth Green Works', 'weymouth-green-works', 'landscaping', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),

    -- Wrentham
    ('Wrentham Landscape & Design', 'wrentham-landscape-design', 'landscaping', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Lake Pearl Lawn Care', 'lake-pearl-lawn-wrentham', 'landscaping', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Sweatt Brothers Landscaping', 'sweatt-bros-wrentham', 'landscaping', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Wrentham Property Maintenance', 'wrentham-property-maintenance', 'landscaping', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Wrentham Green Services', 'wrentham-green-services', 'landscaping', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL)

ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;


-- ============================================================================
-- SECTION 5: PLYMOUTH COUNTY, MA -- LOCAL LANDSCAPING FIRMS
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES

    -- Abington
    ('Abington Landscape & Design', 'abington-landscape-design', 'landscaping', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Island Grove Lawn Care', 'island-grove-lawn-abington', 'landscaping', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Ames Brothers Landscaping', 'ames-bros-abington', 'landscaping', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('North Abington Property Services', 'north-abington-property', 'landscaping', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Abington Green Works', 'abington-green-works', 'landscaping', NULL, ARRAY['Abington','MA','Plymouth'], NULL),

    -- Bridgewater
    ('Bridgewater Landscape & Design', 'bridgewater-landscape-design', 'landscaping', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Carver Pond Lawn Care', 'carver-pond-lawn-bridgewater', 'landscaping', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Town River Landscaping', 'town-river-bridgewater', 'landscaping', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Mitchell Property Maintenance', 'mitchell-property-bridgewater', 'landscaping', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Green Services', 'bridgewater-green-services', 'landscaping', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),

    -- Brockton
    ('Brockton Landscape & Design', 'brockton-landscape-design', 'landscaping', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('D.W. Field Lawn Care', 'dw-field-lawn-brockton', 'landscaping', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Waldo Lake Landscaping', 'waldo-lake-brockton', 'landscaping', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Montello Property Services', 'montello-property-brockton', 'landscaping', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Brockton Green Works', 'brockton-green-works', 'landscaping', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),

    -- Carver
    ('Carver Landscape & Design', 'carver-landscape-design', 'landscaping', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Savery Pond Lawn Care', 'savery-pond-lawn-carver', 'landscaping', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Cranberry Bog Landscaping', 'cranberry-bog-carver', 'landscaping', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Wenham Property Services', 'wenham-property-carver', 'landscaping', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Carver Green Works', 'carver-green-works', 'landscaping', NULL, ARRAY['Carver','MA','Plymouth'], NULL),

    -- Duxbury
    ('Duxbury Landscape & Garden', 'duxbury-landscape-garden', 'landscaping', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Duxbury Bay Lawn Care', 'duxbury-bay-lawn', 'landscaping', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Standish Shore Landscaping', 'standish-shore-duxbury', 'landscaping', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Alden Property Services', 'alden-property-duxbury', 'landscaping', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Powder Point Green Works', 'powder-point-green-duxbury', 'landscaping', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),

    -- East Bridgewater
    ('East Bridgewater Landscape & Design', 'east-bridgewater-landscape-design', 'landscaping', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('Satucket River Lawn Care', 'satucket-river-lawn-ebridgewater', 'landscaping', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('Robbins Pond Landscaping', 'robbins-pond-ebridgewater', 'landscaping', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('Keith Property Maintenance', 'keith-property-ebridgewater', 'landscaping', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('East Bridgewater Green Services', 'east-bridgewater-green-services', 'landscaping', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),

    -- Halifax
    ('Halifax Landscape & Design', 'halifax-landscape-design', 'landscaping', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Monponsett Pond Lawn Care', 'monponsett-pond-lawn-halifax', 'landscaping', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Twin Lakes Landscaping', 'twin-lakes-halifax', 'landscaping', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Thompson Property Services', 'thompson-property-halifax', 'landscaping', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Halifax Green Works', 'halifax-green-works', 'landscaping', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),

    -- Hanover
    ('Hanover Landscape & Design', 'hanover-landscape-design', 'landscaping', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Forge Pond Lawn Care', 'forge-pond-lawn-hanover', 'landscaping', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Drinkwater Landscaping', 'drinkwater-landscaping-hanover', 'landscaping', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Stetson Property Maintenance', 'stetson-property-hanover', 'landscaping', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Hanover Green Services', 'hanover-green-services', 'landscaping', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),

    -- Hanson
    ('Hanson Landscape & Design', 'hanson-landscape-design', 'landscaping', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Wampatuck Lawn Care', 'wampatuck-lawn-hanson', 'landscaping', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Indian Head Landscaping', 'indian-head-hanson', 'landscaping', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Camp Kiwanee Property Services', 'camp-kiwanee-property-hanson', 'landscaping', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Hanson Green Works', 'hanson-green-works', 'landscaping', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),

    -- Hingham
    ('Hingham Landscape & Garden', 'hingham-landscape-garden', 'landscaping', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('World''s End Lawn Care', 'worlds-end-lawn-hingham', 'landscaping', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Bare Cove Park Landscaping', 'bare-cove-park-hingham', 'landscaping', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Cushing Property Services', 'cushing-property-hingham', 'landscaping', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Hingham Harbor Green Works', 'hingham-harbor-green-works', 'landscaping', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),

    -- Hull
    ('Hull Landscape & Design', 'hull-landscape-design', 'landscaping', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Nantasket Lawn Care', 'nantasket-lawn-hull', 'landscaping', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Windmill Point Landscaping', 'windmill-point-hull', 'landscaping', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Stony Beach Property Services', 'stony-beach-property-hull', 'landscaping', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Hull Green Works', 'hull-green-works', 'landscaping', NULL, ARRAY['Hull','MA','Plymouth'], NULL),

    -- Kingston
    ('Kingston Landscape & Design', 'kingston-landscape-design', 'landscaping', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Silver Lake Lawn Care', 'silver-lake-lawn-kingston', 'landscaping', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Jones River Landscaping', 'jones-river-kingston', 'landscaping', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Howland Property Maintenance', 'howland-property-kingston', 'landscaping', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Kingston Green Services', 'kingston-green-services', 'landscaping', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),

    -- Lakeville
    ('Lakeville Landscape & Design', 'lakeville-landscape-design', 'landscaping', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Assawompset Pond Lawn Care', 'assawompset-pond-lawn-lakeville', 'landscaping', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Long Point Landscaping', 'long-point-lakeville', 'landscaping', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Precinct Property Services', 'precinct-property-lakeville', 'landscaping', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Lakeville Green Works', 'lakeville-green-works', 'landscaping', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),

    -- Marion
    ('Marion Landscape & Garden', 'marion-landscape-garden', 'landscaping', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Sippican Harbor Lawn Care', 'sippican-harbor-lawn-marion', 'landscaping', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Tabor Academy Landscaping', 'tabor-academy-marion', 'landscaping', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Delano Property Services', 'delano-property-marion', 'landscaping', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Marion Green Works', 'marion-green-works', 'landscaping', NULL, ARRAY['Marion','MA','Plymouth'], NULL),

    -- Marshfield
    ('Marshfield Landscape & Design', 'marshfield-landscape-design', 'landscaping', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Green Harbor Lawn Care', 'green-harbor-lawn-marshfield', 'landscaping', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Daniel Webster Landscaping', 'daniel-webster-marshfield', 'landscaping', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Brant Rock Property Services', 'brant-rock-property-marshfield', 'landscaping', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Marshfield Green Works', 'marshfield-green-works', 'landscaping', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),

    -- Mattapoisett
    ('Mattapoisett Landscape & Garden', 'mattapoisett-landscape-garden', 'landscaping', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Ned Point Lawn Care', 'ned-point-lawn-mattapoisett', 'landscaping', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Mattapoisett Neck Landscaping', 'mattapoisett-neck-landscaping', 'landscaping', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Barstow Property Services', 'barstow-property-mattapoisett', 'landscaping', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Mattapoisett Green Works', 'mattapoisett-green-works', 'landscaping', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),

    -- Middleborough
    ('Middleborough Landscape & Design', 'middleborough-landscape-design', 'landscaping', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Tispaquin Pond Lawn Care', 'tispaquin-pond-lawn-middleborough', 'landscaping', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Nemasket River Landscaping', 'nemasket-river-middleborough', 'landscaping', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Soule Property Maintenance', 'soule-property-middleborough', 'landscaping', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Middleborough Green Services', 'middleborough-green-services', 'landscaping', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),

    -- Norwell
    ('Norwell Landscape & Garden', 'norwell-landscape-garden', 'landscaping', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Jacobs Pond Lawn Care', 'jacobs-pond-lawn-norwell', 'landscaping', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('South Shore Landscaping', 'south-shore-norwell', 'landscaping', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Stetson Meadows Property Services', 'stetson-meadows-property-norwell', 'landscaping', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Norwell Green Works', 'norwell-green-works', 'landscaping', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),

    -- Pembroke
    ('Pembroke Landscape & Design', 'pembroke-landscape-design', 'landscaping', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Furnace Pond Lawn Care', 'furnace-pond-lawn-pembroke', 'landscaping', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Herring Brook Landscaping', 'herring-brook-pembroke', 'landscaping', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Barker Property Maintenance', 'barker-property-pembroke', 'landscaping', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Pembroke Green Services', 'pembroke-green-services', 'landscaping', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),

    -- Plymouth
    ('Plymouth Landscape & Garden', 'plymouth-landscape-garden', 'landscaping', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Pilgrim Lawn Care', 'pilgrim-lawn-plymouth', 'landscaping', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Manomet Landscaping', 'manomet-landscaping-plymouth', 'landscaping', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Long Pond Property Services', 'long-pond-property-plymouth', 'landscaping', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Plymouth Colony Green Works', 'plymouth-colony-green-works', 'landscaping', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),

    -- Plympton
    ('Plympton Landscape & Design', 'plympton-landscape-design', 'landscaping', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Winnetuxet River Lawn Care', 'winnetuxet-river-lawn-plympton', 'landscaping', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Colchester Brook Landscaping', 'colchester-brook-plympton', 'landscaping', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Soule Property Services', 'soule-property-plympton', 'landscaping', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Plympton Green Works', 'plympton-green-works', 'landscaping', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),

    -- Rochester
    ('Rochester Landscape & Design', 'rochester-landscape-design', 'landscaping', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Snipatuit Pond Lawn Care', 'snipatuit-pond-lawn-rochester', 'landscaping', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Mary''s Pond Landscaping', 'marys-pond-rochester', 'landscaping', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Hartley Property Maintenance', 'hartley-property-rochester', 'landscaping', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Rochester Green Services', 'rochester-green-services', 'landscaping', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),

    -- Rockland
    ('Rockland Landscape & Design', 'rockland-landscape-design', 'landscaping', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Reed Pond Lawn Care', 'reed-pond-lawn-rockland', 'landscaping', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Hartsuff Park Landscaping', 'hartsuff-park-rockland', 'landscaping', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('French Property Services', 'french-property-rockland', 'landscaping', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Rockland Green Works', 'rockland-green-works', 'landscaping', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),

    -- Scituate
    ('Scituate Landscape & Garden', 'scituate-landscape-garden', 'landscaping', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Minot Beach Lawn Care', 'minot-beach-lawn-scituate', 'landscaping', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('North Scituate Landscaping', 'north-scituate-landscaping', 'landscaping', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Lawson Tower Property Services', 'lawson-tower-property-scituate', 'landscaping', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Scituate Harbor Green Works', 'scituate-harbor-green-works', 'landscaping', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),

    -- Wareham
    ('Wareham Landscape & Design', 'wareham-landscape-design', 'landscaping', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Onset Bay Lawn Care', 'onset-bay-lawn-wareham', 'landscaping', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Tremont Nail Landscaping', 'tremont-nail-wareham', 'landscaping', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Swift Property Maintenance', 'swift-property-wareham', 'landscaping', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Wareham Green Services', 'wareham-green-services', 'landscaping', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),

    -- West Bridgewater
    ('West Bridgewater Landscape & Design', 'west-bridgewater-landscape-design', 'landscaping', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('War Memorial Lawn Care', 'war-memorial-lawn-wbridgewater', 'landscaping', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('Howard Landscaping', 'howard-landscaping-wbridgewater', 'landscaping', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('Scotland Street Property Services', 'scotland-street-property-wbridgewater', 'landscaping', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('West Bridgewater Green Works', 'west-bridgewater-green-works', 'landscaping', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),

    -- Whitman
    ('Whitman Landscape & Design', 'whitman-landscape-design', 'landscaping', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Hobart Pond Lawn Care', 'hobart-pond-lawn-whitman', 'landscaping', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Auburn Street Landscaping', 'auburn-street-whitman', 'landscaping', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Beals Property Maintenance', 'beals-property-whitman', 'landscaping', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Whitman Green Services', 'whitman-green-services', 'landscaping', NULL, ARRAY['Whitman','MA','Plymouth'], NULL)

ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;
