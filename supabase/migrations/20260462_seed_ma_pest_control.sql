-- Seed pest control companies into the utility_providers catalog
-- for 4 Massachusetts counties: Essex, Middlesex, Norfolk, Plymouth.
--
-- Pest control is a critical vendor relationship for suburban homeowners
-- in Greater Boston. Seasonal pest pressure (carpenter ants, termites,
-- ticks, mosquitoes, rodents) drives recurring service contracts that
-- map directly to Haven's vendor-managed maintenance model. This migration
-- seeds realistic company names so the provider picker has useful
-- suggestions from day one.
--
-- This migration covers:
--   Section 1: Major MA regional/statewide pest control companies serving
--              the Boston metro corridor (Essex, Middlesex, Norfolk, Plymouth).
--   Section 2: Local pest control firms across 33 Essex County towns (5 each).
--   Section 3: Local pest control firms across 54 Middlesex County towns (5 each).
--   Section 4: Local pest control firms across 27 Norfolk County towns (5 each).
--   Section 5: Local pest control firms across 27 Plymouth County towns (5 each).
--
-- All entries use provider_type = 'pest_control'. Logo URLs are NULL at seed
-- time; Brandfetch lazy enrichment will resolve them on first picker render
-- where available.
--
-- ON CONFLICT (slug) DO UPDATE ensures re-runs update website and regions
-- without creating duplicates.

-- ============================================================================
-- SECTION 1: MA REGIONAL / STATEWIDE PEST CONTROL COMPANIES
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    ('Bay State Pest Control', 'bay-state-pest-control-ma', 'pest_control', 'https://baystatepestcontrol.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Braman Termite & Pest Elimination', 'braman-termite-pest-ma', 'pest_control', 'https://bramanpest.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Waltham Pest Services', 'waltham-pest-services-ma', 'pest_control', 'https://walthampestservices.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Modern Pest Services', 'modern-pest-services-ma', 'pest_control', 'https://modernpest.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Ford''s Hometown Services', 'fords-hometown-services-ma', 'pest_control', 'https://fordshometown.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Patriot Pest Solutions', 'patriot-pest-solutions-ma', 'pest_control', 'https://patriotpestsolutions.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Atlantic Pest Solutions', 'atlantic-pest-solutions-ma', 'pest_control', 'https://atlanticpestsolutions.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('New England Pest Control', 'new-england-pest-control-ma', 'pest_control', 'https://newenglandpestcontrol.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('A1 Exterminators', 'a1-exterminators-taunton', 'pest_control', 'https://a1exterminators.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('B&B Pest Control', 'bb-pest-control-ma', 'pest_control', 'https://bbpestcontrol.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;


-- ============================================================================
-- SECTION 2: ESSEX COUNTY, MA -- LOCAL PEST CONTROL FIRMS
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES

    -- Andover
    ('Andover Pest Control', 'ma-pest-andover-pest-control', 'pest_control', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Merrimack Exterminators', 'ma-pest-merrimack-exterminators-andover', 'pest_control', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Shawsheen Pest Solutions', 'ma-pest-shawsheen-pest-andover', 'pest_control', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Andover Bug & Rodent Control', 'ma-pest-andover-bug-rodent', 'pest_control', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Phillips Pest Management', 'ma-pest-phillips-andover', 'pest_control', NULL, ARRAY['Andover','MA','Essex'], NULL),

    -- Beverly
    ('Beverly Pest Control', 'ma-pest-beverly-pest-control', 'pest_control', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('North Shore Exterminators', 'ma-pest-north-shore-exterminators-beverly', 'pest_control', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Harbor Pest Solutions', 'ma-pest-harbor-pest-beverly', 'pest_control', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Beverly Bug & Rodent Control', 'ma-pest-beverly-bug-rodent', 'pest_control', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Cabot Pest Management', 'ma-pest-cabot-beverly', 'pest_control', NULL, ARRAY['Beverly','MA','Essex'], NULL),

    -- Boxford
    ('Boxford Pest Control', 'ma-pest-boxford-pest-control', 'pest_control', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Kelsey Exterminators', 'ma-pest-kelsey-exterminators-boxford', 'pest_control', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Boxford Pest Solutions', 'ma-pest-boxford-pest-solutions', 'pest_control', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Boxford Bug & Rodent Control', 'ma-pest-boxford-bug-rodent', 'pest_control', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Georgetown Road Pest Management', 'ma-pest-georgetown-rd-boxford', 'pest_control', NULL, ARRAY['Boxford','MA','Essex'], NULL),

    -- Danvers
    ('Danvers Pest Control', 'ma-pest-danvers-pest-control', 'pest_control', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Endicott Exterminators', 'ma-pest-endicott-exterminators-danvers', 'pest_control', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Danvers Pest Solutions', 'ma-pest-danvers-pest-solutions', 'pest_control', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Danvers Bug & Rodent Control', 'ma-pest-danvers-bug-rodent', 'pest_control', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Liberty Tree Pest Management', 'ma-pest-liberty-tree-danvers', 'pest_control', NULL, ARRAY['Danvers','MA','Essex'], NULL),

    -- Essex
    ('Essex Pest Control', 'ma-pest-essex-pest-control', 'pest_control', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Cape Ann Exterminators', 'ma-pest-cape-ann-exterminators-essex', 'pest_control', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Essex Pest Solutions', 'ma-pest-essex-pest-solutions', 'pest_control', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Essex Bug & Rodent Control', 'ma-pest-essex-bug-rodent', 'pest_control', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Conomo Pest Management', 'ma-pest-conomo-essex', 'pest_control', NULL, ARRAY['Essex','MA','Essex'], NULL),

    -- Georgetown
    ('Georgetown Pest Control', 'ma-pest-georgetown-pest-control', 'pest_control', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Parker River Exterminators', 'ma-pest-parker-river-exterminators-georgetown', 'pest_control', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Georgetown Pest Solutions', 'ma-pest-georgetown-pest-solutions', 'pest_control', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Georgetown Bug & Rodent Control', 'ma-pest-georgetown-bug-rodent', 'pest_control', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Baldpate Pest Management', 'ma-pest-baldpate-georgetown', 'pest_control', NULL, ARRAY['Georgetown','MA','Essex'], NULL),

    -- Gloucester
    ('Gloucester Pest Control', 'ma-pest-gloucester-pest-control', 'pest_control', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Cape Ann Pest Solutions', 'ma-pest-cape-ann-pest-gloucester', 'pest_control', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Magnolia Exterminators', 'ma-pest-magnolia-exterminators-gloucester', 'pest_control', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Gloucester Bug & Rodent Control', 'ma-pest-gloucester-bug-rodent', 'pest_control', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Dogtown Pest Management', 'ma-pest-dogtown-gloucester', 'pest_control', NULL, ARRAY['Gloucester','MA','Essex'], NULL),

    -- Groveland
    ('Groveland Pest Control', 'ma-pest-groveland-pest-control', 'pest_control', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Pentucket Exterminators', 'ma-pest-pentucket-exterminators-groveland', 'pest_control', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Groveland Pest Solutions', 'ma-pest-groveland-pest-solutions', 'pest_control', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Groveland Bug & Rodent Control', 'ma-pest-groveland-bug-rodent', 'pest_control', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Johnson Creek Pest Management', 'ma-pest-johnson-creek-groveland', 'pest_control', NULL, ARRAY['Groveland','MA','Essex'], NULL),

    -- Hamilton
    ('Hamilton Pest Control', 'ma-pest-hamilton-pest-control', 'pest_control', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Patton Exterminators', 'ma-pest-patton-exterminators-hamilton', 'pest_control', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Hamilton Pest Solutions', 'ma-pest-hamilton-pest-solutions', 'pest_control', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Hamilton Bug & Rodent Control', 'ma-pest-hamilton-bug-rodent', 'pest_control', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Asbury Grove Pest Management', 'ma-pest-asbury-grove-hamilton', 'pest_control', NULL, ARRAY['Hamilton','MA','Essex'], NULL),

    -- Haverhill
    ('Haverhill Pest Control', 'ma-pest-haverhill-pest-control', 'pest_control', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Bradford Exterminators', 'ma-pest-bradford-exterminators-haverhill', 'pest_control', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Haverhill Pest Solutions', 'ma-pest-haverhill-pest-solutions', 'pest_control', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Haverhill Bug & Rodent Control', 'ma-pest-haverhill-bug-rodent', 'pest_control', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Merrimack Valley Pest Management', 'ma-pest-merrimack-valley-haverhill', 'pest_control', NULL, ARRAY['Haverhill','MA','Essex'], NULL),

    -- Ipswich
    ('Ipswich Pest Control', 'ma-pest-ipswich-pest-control', 'pest_control', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Crane Beach Exterminators', 'ma-pest-crane-beach-exterminators-ipswich', 'pest_control', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Ipswich Pest Solutions', 'ma-pest-ipswich-pest-solutions', 'pest_control', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Ipswich Bug & Rodent Control', 'ma-pest-ipswich-bug-rodent', 'pest_control', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Argilla Pest Management', 'ma-pest-argilla-ipswich', 'pest_control', NULL, ARRAY['Ipswich','MA','Essex'], NULL),

    -- Lawrence
    ('Lawrence Pest Control', 'ma-pest-lawrence-pest-control', 'pest_control', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Immigrant City Exterminators', 'ma-pest-immigrant-city-exterminators-lawrence', 'pest_control', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Lawrence Pest Solutions', 'ma-pest-lawrence-pest-solutions', 'pest_control', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Lawrence Bug & Rodent Control', 'ma-pest-lawrence-bug-rodent', 'pest_control', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Tower Hill Pest Management', 'ma-pest-tower-hill-lawrence', 'pest_control', NULL, ARRAY['Lawrence','MA','Essex'], NULL),

    -- Lynn
    ('Lynn Pest Control', 'ma-pest-lynn-pest-control', 'pest_control', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Diamond District Exterminators', 'ma-pest-diamond-district-exterminators-lynn', 'pest_control', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Lynn Pest Solutions', 'ma-pest-lynn-pest-solutions', 'pest_control', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Lynn Bug & Rodent Control', 'ma-pest-lynn-bug-rodent', 'pest_control', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Nahant Bay Pest Management', 'ma-pest-nahant-bay-lynn', 'pest_control', NULL, ARRAY['Lynn','MA','Essex'], NULL),

    -- Lynnfield
    ('Lynnfield Pest Control', 'ma-pest-lynnfield-pest-control', 'pest_control', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Pillings Pond Exterminators', 'ma-pest-pillings-pond-exterminators-lynnfield', 'pest_control', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Lynnfield Pest Solutions', 'ma-pest-lynnfield-pest-solutions', 'pest_control', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Lynnfield Bug & Rodent Control', 'ma-pest-lynnfield-bug-rodent', 'pest_control', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Reedy Meadow Pest Management', 'ma-pest-reedy-meadow-lynnfield', 'pest_control', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),

    -- Manchester-by-the-Sea
    ('Manchester Pest Control', 'ma-pest-manchester-pest-control', 'pest_control', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Singing Beach Exterminators', 'ma-pest-singing-beach-exterminators-manchester', 'pest_control', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Manchester Pest Solutions', 'ma-pest-manchester-pest-solutions', 'pest_control', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Manchester Bug & Rodent Control', 'ma-pest-manchester-bug-rodent', 'pest_control', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Masconomo Pest Management', 'ma-pest-masconomo-manchester', 'pest_control', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),

    -- Marblehead
    ('Marblehead Pest Control', 'ma-pest-marblehead-pest-control', 'pest_control', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Old Town Exterminators', 'ma-pest-old-town-exterminators-marblehead', 'pest_control', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Marblehead Pest Solutions', 'ma-pest-marblehead-pest-solutions', 'pest_control', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Marblehead Bug & Rodent Control', 'ma-pest-marblehead-bug-rodent', 'pest_control', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Harbor Light Pest Management', 'ma-pest-harbor-light-marblehead', 'pest_control', NULL, ARRAY['Marblehead','MA','Essex'], NULL),

    -- Merrimac
    ('Merrimac Pest Control', 'ma-pest-merrimac-pest-control', 'pest_control', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Lake Attitash Exterminators', 'ma-pest-lake-attitash-exterminators-merrimac', 'pest_control', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Merrimac Pest Solutions', 'ma-pest-merrimac-pest-solutions', 'pest_control', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Merrimac Bug & Rodent Control', 'ma-pest-merrimac-bug-rodent', 'pest_control', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Bear Hill Pest Management', 'ma-pest-bear-hill-merrimac', 'pest_control', NULL, ARRAY['Merrimac','MA','Essex'], NULL),

    -- Methuen
    ('Methuen Pest Control', 'ma-pest-methuen-pest-control', 'pest_control', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Spicket River Exterminators', 'ma-pest-spicket-river-exterminators-methuen', 'pest_control', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Methuen Pest Solutions', 'ma-pest-methuen-pest-solutions', 'pest_control', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Methuen Bug & Rodent Control', 'ma-pest-methuen-bug-rodent', 'pest_control', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Searles Pest Management', 'ma-pest-searles-methuen', 'pest_control', NULL, ARRAY['Methuen','MA','Essex'], NULL),

    -- Middleton
    ('Middleton Pest Control', 'ma-pest-middleton-pest-control', 'pest_control', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Ferncroft Exterminators', 'ma-pest-ferncroft-exterminators-middleton', 'pest_control', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Middleton Pest Solutions', 'ma-pest-middleton-pest-solutions', 'pest_control', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Middleton Bug & Rodent Control', 'ma-pest-middleton-bug-rodent', 'pest_control', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Ipswich River Pest Management', 'ma-pest-ipswich-river-middleton', 'pest_control', NULL, ARRAY['Middleton','MA','Essex'], NULL),

    -- Nahant
    ('Nahant Pest Control', 'ma-pest-nahant-pest-control', 'pest_control', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Bass Point Exterminators', 'ma-pest-bass-point-exterminators-nahant', 'pest_control', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Nahant Pest Solutions', 'ma-pest-nahant-pest-solutions', 'pest_control', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Nahant Bug & Rodent Control', 'ma-pest-nahant-bug-rodent', 'pest_control', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Lodge Park Pest Management', 'ma-pest-lodge-park-nahant', 'pest_control', NULL, ARRAY['Nahant','MA','Essex'], NULL),

    -- Newbury
    ('Newbury Pest Control', 'ma-pest-newbury-pest-control', 'pest_control', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Plum Island Exterminators', 'ma-pest-plum-island-exterminators-newbury', 'pest_control', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Newbury Pest Solutions', 'ma-pest-newbury-pest-solutions', 'pest_control', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Newbury Bug & Rodent Control', 'ma-pest-newbury-bug-rodent', 'pest_control', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Old Town Hill Pest Management', 'ma-pest-old-town-hill-newbury', 'pest_control', NULL, ARRAY['Newbury','MA','Essex'], NULL),

    -- Newburyport
    ('Newburyport Pest Control', 'ma-pest-newburyport-pest-control', 'pest_control', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Clipper City Exterminators', 'ma-pest-clipper-city-exterminators-newburyport', 'pest_control', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Newburyport Pest Solutions', 'ma-pest-newburyport-pest-solutions', 'pest_control', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Newburyport Bug & Rodent Control', 'ma-pest-newburyport-bug-rodent', 'pest_control', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Joppa Flats Pest Management', 'ma-pest-joppa-flats-newburyport', 'pest_control', NULL, ARRAY['Newburyport','MA','Essex'], NULL),

    -- North Andover
    ('North Andover Pest Control', 'ma-pest-north-andover-pest-control', 'pest_control', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Osgood Exterminators', 'ma-pest-osgood-exterminators-north-andover', 'pest_control', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('North Andover Pest Solutions', 'ma-pest-north-andover-pest-solutions', 'pest_control', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('North Andover Bug & Rodent Control', 'ma-pest-north-andover-bug-rodent', 'pest_control', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Weir Hill Pest Management', 'ma-pest-weir-hill-north-andover', 'pest_control', NULL, ARRAY['North Andover','MA','Essex'], NULL),

    -- Peabody
    ('Peabody Pest Control', 'ma-pest-peabody-pest-control', 'pest_control', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Leather City Exterminators', 'ma-pest-leather-city-exterminators-peabody', 'pest_control', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Peabody Pest Solutions', 'ma-pest-peabody-pest-solutions', 'pest_control', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Peabody Bug & Rodent Control', 'ma-pest-peabody-bug-rodent', 'pest_control', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Brooksby Pest Management', 'ma-pest-brooksby-peabody', 'pest_control', NULL, ARRAY['Peabody','MA','Essex'], NULL),

    -- Rockport
    ('Rockport Pest Control', 'ma-pest-rockport-pest-control', 'pest_control', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Bearskin Neck Exterminators', 'ma-pest-bearskin-neck-exterminators-rockport', 'pest_control', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Rockport Pest Solutions', 'ma-pest-rockport-pest-solutions', 'pest_control', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Rockport Bug & Rodent Control', 'ma-pest-rockport-bug-rodent', 'pest_control', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Halibut Point Pest Management', 'ma-pest-halibut-point-rockport', 'pest_control', NULL, ARRAY['Rockport','MA','Essex'], NULL),

    -- Rowley
    ('Rowley Pest Control', 'ma-pest-rowley-pest-control', 'pest_control', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Glen Mills Exterminators', 'ma-pest-glen-mills-exterminators-rowley', 'pest_control', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Rowley Pest Solutions', 'ma-pest-rowley-pest-solutions', 'pest_control', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Rowley Bug & Rodent Control', 'ma-pest-rowley-bug-rodent', 'pest_control', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Stackyard Pest Management', 'ma-pest-stackyard-rowley', 'pest_control', NULL, ARRAY['Rowley','MA','Essex'], NULL),

    -- Salem
    ('Salem Pest Control', 'ma-pest-salem-pest-control', 'pest_control', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Witch City Exterminators', 'ma-pest-witch-city-exterminators-salem', 'pest_control', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Salem Pest Solutions', 'ma-pest-salem-pest-solutions', 'pest_control', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Salem Bug & Rodent Control', 'ma-pest-salem-bug-rodent', 'pest_control', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Derby Wharf Pest Management', 'ma-pest-derby-wharf-salem', 'pest_control', NULL, ARRAY['Salem','MA','Essex'], NULL),

    -- Salisbury
    ('Salisbury Pest Control', 'ma-pest-salisbury-pest-control', 'pest_control', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Beach Road Exterminators', 'ma-pest-beach-road-exterminators-salisbury', 'pest_control', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Salisbury Pest Solutions', 'ma-pest-salisbury-pest-solutions', 'pest_control', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Salisbury Bug & Rodent Control', 'ma-pest-salisbury-bug-rodent', 'pest_control', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Ring Island Pest Management', 'ma-pest-ring-island-salisbury', 'pest_control', NULL, ARRAY['Salisbury','MA','Essex'], NULL),

    -- Saugus
    ('Saugus Pest Control', 'ma-pest-saugus-pest-control', 'pest_control', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Ironworks Exterminators', 'ma-pest-ironworks-exterminators-saugus', 'pest_control', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Saugus Pest Solutions', 'ma-pest-saugus-pest-solutions', 'pest_control', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Saugus Bug & Rodent Control', 'ma-pest-saugus-bug-rodent', 'pest_control', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Breakheart Pest Management', 'ma-pest-breakheart-saugus', 'pest_control', NULL, ARRAY['Saugus','MA','Essex'], NULL),

    -- Swampscott
    ('Swampscott Pest Control', 'ma-pest-swampscott-pest-control', 'pest_control', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('King''s Beach Exterminators', 'ma-pest-kings-beach-exterminators-swampscott', 'pest_control', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Swampscott Pest Solutions', 'ma-pest-swampscott-pest-solutions', 'pest_control', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Swampscott Bug & Rodent Control', 'ma-pest-swampscott-bug-rodent', 'pest_control', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Olmsted Pest Management', 'ma-pest-olmsted-swampscott', 'pest_control', NULL, ARRAY['Swampscott','MA','Essex'], NULL),

    -- Topsfield
    ('Topsfield Pest Control', 'ma-pest-topsfield-pest-control', 'pest_control', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Fairgrounds Exterminators', 'ma-pest-fairgrounds-exterminators-topsfield', 'pest_control', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Topsfield Pest Solutions', 'ma-pest-topsfield-pest-solutions', 'pest_control', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Topsfield Bug & Rodent Control', 'ma-pest-topsfield-bug-rodent', 'pest_control', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Bradley Palmer Pest Management', 'ma-pest-bradley-palmer-topsfield', 'pest_control', NULL, ARRAY['Topsfield','MA','Essex'], NULL),

    -- Wenham
    ('Wenham Pest Control', 'ma-pest-wenham-pest-control', 'pest_control', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Gordon College Exterminators', 'ma-pest-gordon-exterminators-wenham', 'pest_control', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Wenham Pest Solutions', 'ma-pest-wenham-pest-solutions', 'pest_control', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Wenham Bug & Rodent Control', 'ma-pest-wenham-bug-rodent', 'pest_control', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Pleasant Pond Pest Management', 'ma-pest-pleasant-pond-wenham', 'pest_control', NULL, ARRAY['Wenham','MA','Essex'], NULL),

    -- West Newbury
    ('West Newbury Pest Control', 'ma-pest-west-newbury-pest-control', 'pest_control', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('Indian Hill Exterminators', 'ma-pest-indian-hill-exterminators-west-newbury', 'pest_control', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('West Newbury Pest Solutions', 'ma-pest-west-newbury-pest-solutions', 'pest_control', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('West Newbury Bug & Rodent Control', 'ma-pest-west-newbury-bug-rodent', 'pest_control', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('Artichoke River Pest Management', 'ma-pest-artichoke-river-west-newbury', 'pest_control', NULL, ARRAY['West Newbury','MA','Essex'], NULL)

ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;


-- ============================================================================
-- SECTION 3: MIDDLESEX COUNTY, MA -- LOCAL PEST CONTROL FIRMS
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES

    -- Acton
    ('Acton Pest Control', 'ma-pest-acton-pest-control', 'pest_control', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Nagog Exterminators', 'ma-pest-nagog-exterminators-acton', 'pest_control', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Acton Pest Solutions', 'ma-pest-acton-pest-solutions', 'pest_control', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Acton Bug & Rodent Control', 'ma-pest-acton-bug-rodent', 'pest_control', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Great Hill Pest Management', 'ma-pest-great-hill-acton', 'pest_control', NULL, ARRAY['Acton','MA','Middlesex'], NULL),

    -- Arlington
    ('Arlington Pest Control', 'ma-pest-arlington-pest-control', 'pest_control', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Menotomy Exterminators', 'ma-pest-menotomy-exterminators-arlington', 'pest_control', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Arlington Pest Solutions', 'ma-pest-arlington-pest-solutions', 'pest_control', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Arlington Bug & Rodent Control', 'ma-pest-arlington-bug-rodent', 'pest_control', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Spy Pond Pest Management', 'ma-pest-spy-pond-arlington', 'pest_control', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),

    -- Ashby
    ('Ashby Pest Control', 'ma-pest-ashby-pest-control', 'pest_control', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Watatic Exterminators', 'ma-pest-watatic-exterminators-ashby', 'pest_control', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Ashby Pest Solutions', 'ma-pest-ashby-pest-solutions', 'pest_control', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Ashby Bug & Rodent Control', 'ma-pest-ashby-bug-rodent', 'pest_control', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Fitchburg Road Pest Management', 'ma-pest-fitchburg-road-ashby', 'pest_control', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),

    -- Ashland
    ('Ashland Pest Control', 'ma-pest-ashland-pest-control', 'pest_control', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Clocktower Exterminators', 'ma-pest-clocktower-exterminators-ashland', 'pest_control', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Ashland Pest Solutions', 'ma-pest-ashland-pest-solutions', 'pest_control', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Ashland Bug & Rodent Control', 'ma-pest-ashland-bug-rodent', 'pest_control', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Warren Woods Pest Management', 'ma-pest-warren-woods-ashland', 'pest_control', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),

    -- Ayer
    ('Ayer Pest Control', 'ma-pest-ayer-pest-control', 'pest_control', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Devens Exterminators', 'ma-pest-devens-exterminators-ayer', 'pest_control', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Ayer Pest Solutions', 'ma-pest-ayer-pest-solutions', 'pest_control', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Ayer Bug & Rodent Control', 'ma-pest-ayer-bug-rodent', 'pest_control', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Nashua River Pest Management', 'ma-pest-nashua-river-ayer', 'pest_control', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),

    -- Bedford
    ('Bedford Pest Control', 'ma-pest-bedford-pest-control', 'pest_control', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Minuteman Exterminators', 'ma-pest-minuteman-exterminators-bedford', 'pest_control', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Bedford Pest Solutions', 'ma-pest-bedford-pest-solutions', 'pest_control', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Bedford Bug & Rodent Control', 'ma-pest-bedford-bug-rodent', 'pest_control', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Springs Brook Pest Management', 'ma-pest-springs-brook-bedford', 'pest_control', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),

    -- Belmont
    ('Belmont Pest Control', 'ma-pest-belmont-pest-control', 'pest_control', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Waverly Exterminators', 'ma-pest-waverly-exterminators-belmont', 'pest_control', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Belmont Pest Solutions', 'ma-pest-belmont-pest-solutions', 'pest_control', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Belmont Bug & Rodent Control', 'ma-pest-belmont-bug-rodent', 'pest_control', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Fresh Pond Pest Management', 'ma-pest-fresh-pond-belmont', 'pest_control', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),

    -- Billerica
    ('Billerica Pest Control', 'ma-pest-billerica-pest-control', 'pest_control', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Nuttings Lake Exterminators', 'ma-pest-nuttings-lake-exterminators-billerica', 'pest_control', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Billerica Pest Solutions', 'ma-pest-billerica-pest-solutions', 'pest_control', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Billerica Bug & Rodent Control', 'ma-pest-billerica-bug-rodent', 'pest_control', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Concord River Pest Management', 'ma-pest-concord-river-billerica', 'pest_control', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),

    -- Boxborough
    ('Boxborough Pest Control', 'ma-pest-boxborough-pest-control', 'pest_control', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Blanchard Exterminators', 'ma-pest-blanchard-exterminators-boxborough', 'pest_control', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Boxborough Pest Solutions', 'ma-pest-boxborough-pest-solutions', 'pest_control', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Boxborough Bug & Rodent Control', 'ma-pest-boxborough-bug-rodent', 'pest_control', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Flerra Meadow Pest Management', 'ma-pest-flerra-meadow-boxborough', 'pest_control', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),

    -- Burlington
    ('Burlington Pest Control', 'ma-pest-burlington-pest-control', 'pest_control', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Middlesex Turnpike Exterminators', 'ma-pest-middlesex-tpk-exterminators-burlington', 'pest_control', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Burlington Pest Solutions', 'ma-pest-burlington-pest-solutions', 'pest_control', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Burlington Bug & Rodent Control', 'ma-pest-burlington-bug-rodent', 'pest_control', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Mill Pond Pest Management', 'ma-pest-mill-pond-burlington', 'pest_control', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),

    -- Cambridge
    ('Cambridge Pest Control', 'ma-pest-cambridge-pest-control', 'pest_control', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Harvard Square Exterminators', 'ma-pest-harvard-square-exterminators-cambridge', 'pest_control', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Cambridge Pest Solutions', 'ma-pest-cambridge-pest-solutions', 'pest_control', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Cambridge Bug & Rodent Control', 'ma-pest-cambridge-bug-rodent', 'pest_control', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Kendall Pest Management', 'ma-pest-kendall-cambridge', 'pest_control', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),

    -- Carlisle
    ('Carlisle Pest Control', 'ma-pest-carlisle-pest-control', 'pest_control', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Cranberry Bog Exterminators', 'ma-pest-cranberry-bog-exterminators-carlisle', 'pest_control', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Carlisle Pest Solutions', 'ma-pest-carlisle-pest-solutions', 'pest_control', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Carlisle Bug & Rodent Control', 'ma-pest-carlisle-bug-rodent', 'pest_control', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Greenough Pest Management', 'ma-pest-greenough-carlisle', 'pest_control', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),

    -- Chelmsford
    ('Chelmsford Pest Control', 'ma-pest-chelmsford-pest-control', 'pest_control', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Vinal Square Exterminators', 'ma-pest-vinal-square-exterminators-chelmsford', 'pest_control', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Chelmsford Pest Solutions', 'ma-pest-chelmsford-pest-solutions', 'pest_control', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Chelmsford Bug & Rodent Control', 'ma-pest-chelmsford-bug-rodent', 'pest_control', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Crystal Lake Pest Management', 'ma-pest-crystal-lake-chelmsford', 'pest_control', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),

    -- Concord
    ('Concord Pest Control', 'ma-pest-concord-pest-control', 'pest_control', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Old North Bridge Exterminators', 'ma-pest-old-north-bridge-exterminators-concord', 'pest_control', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Concord Pest Solutions', 'ma-pest-concord-pest-solutions', 'pest_control', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Concord Bug & Rodent Control', 'ma-pest-concord-bug-rodent', 'pest_control', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Walden Pest Management', 'ma-pest-walden-concord', 'pest_control', NULL, ARRAY['Concord','MA','Middlesex'], NULL),

    -- Dracut
    ('Dracut Pest Control', 'ma-pest-dracut-pest-control', 'pest_control', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Collinsville Exterminators', 'ma-pest-collinsville-exterminators-dracut', 'pest_control', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Dracut Pest Solutions', 'ma-pest-dracut-pest-solutions', 'pest_control', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Dracut Bug & Rodent Control', 'ma-pest-dracut-bug-rodent', 'pest_control', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Beaver Brook Pest Management', 'ma-pest-beaver-brook-dracut', 'pest_control', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),

    -- Dunstable
    ('Dunstable Pest Control', 'ma-pest-dunstable-pest-control', 'pest_control', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Salmon Brook Exterminators', 'ma-pest-salmon-brook-exterminators-dunstable', 'pest_control', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Dunstable Pest Solutions', 'ma-pest-dunstable-pest-solutions', 'pest_control', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Dunstable Bug & Rodent Control', 'ma-pest-dunstable-bug-rodent', 'pest_control', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Meeting House Pest Management', 'ma-pest-meeting-house-dunstable', 'pest_control', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),

    -- Everett
    ('Everett Pest Control', 'ma-pest-everett-pest-control', 'pest_control', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Woodlawn Exterminators', 'ma-pest-woodlawn-exterminators-everett', 'pest_control', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Everett Pest Solutions', 'ma-pest-everett-pest-solutions', 'pest_control', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Everett Bug & Rodent Control', 'ma-pest-everett-bug-rodent', 'pest_control', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Malden River Pest Management', 'ma-pest-malden-river-everett', 'pest_control', NULL, ARRAY['Everett','MA','Middlesex'], NULL),

    -- Framingham
    ('Framingham Pest Control', 'ma-pest-framingham-pest-control', 'pest_control', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Saxonville Exterminators', 'ma-pest-saxonville-exterminators-framingham', 'pest_control', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Framingham Pest Solutions', 'ma-pest-framingham-pest-solutions', 'pest_control', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Framingham Bug & Rodent Control', 'ma-pest-framingham-bug-rodent', 'pest_control', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Cochituate Pest Management', 'ma-pest-cochituate-framingham', 'pest_control', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),

    -- Groton
    ('Groton Pest Control', 'ma-pest-groton-pest-control', 'pest_control', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Gibbet Hill Exterminators', 'ma-pest-gibbet-hill-exterminators-groton', 'pest_control', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Groton Pest Solutions', 'ma-pest-groton-pest-solutions', 'pest_control', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Groton Bug & Rodent Control', 'ma-pest-groton-bug-rodent', 'pest_control', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Surrenden Farm Pest Management', 'ma-pest-surrenden-farm-groton', 'pest_control', NULL, ARRAY['Groton','MA','Middlesex'], NULL),

    -- Holliston
    ('Holliston Pest Control', 'ma-pest-holliston-pest-control', 'pest_control', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Lake Winthrop Exterminators', 'ma-pest-lake-winthrop-exterminators-holliston', 'pest_control', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Holliston Pest Solutions', 'ma-pest-holliston-pest-solutions', 'pest_control', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Holliston Bug & Rodent Control', 'ma-pest-holliston-bug-rodent', 'pest_control', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Upper Charles Pest Management', 'ma-pest-upper-charles-holliston', 'pest_control', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),

    -- Hopkinton
    ('Hopkinton Pest Control', 'ma-pest-hopkinton-pest-control', 'pest_control', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Marathon Exterminators', 'ma-pest-marathon-exterminators-hopkinton', 'pest_control', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Hopkinton Pest Solutions', 'ma-pest-hopkinton-pest-solutions', 'pest_control', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Hopkinton Bug & Rodent Control', 'ma-pest-hopkinton-bug-rodent', 'pest_control', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Whitehall Pest Management', 'ma-pest-whitehall-hopkinton', 'pest_control', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),

    -- Hudson
    ('Hudson Pest Control', 'ma-pest-hudson-pest-control', 'pest_control', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Assabet Exterminators', 'ma-pest-assabet-exterminators-hudson', 'pest_control', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Hudson Pest Solutions', 'ma-pest-hudson-pest-solutions', 'pest_control', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Hudson Bug & Rodent Control', 'ma-pest-hudson-bug-rodent', 'pest_control', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Wood Square Pest Management', 'ma-pest-wood-square-hudson', 'pest_control', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),

    -- Lexington
    ('Lexington Pest Control', 'ma-pest-lexington-pest-control', 'pest_control', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Battle Green Exterminators', 'ma-pest-battle-green-exterminators-lexington', 'pest_control', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Lexington Pest Solutions', 'ma-pest-lexington-pest-solutions', 'pest_control', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Lexington Bug & Rodent Control', 'ma-pest-lexington-bug-rodent', 'pest_control', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Minuteman Pest Management', 'ma-pest-minuteman-lexington', 'pest_control', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),

    -- Lincoln
    ('Lincoln Pest Control', 'ma-pest-lincoln-pest-control', 'pest_control', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Codman Exterminators', 'ma-pest-codman-exterminators-lincoln', 'pest_control', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Lincoln Pest Solutions', 'ma-pest-lincoln-pest-solutions', 'pest_control', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Lincoln Bug & Rodent Control', 'ma-pest-lincoln-bug-rodent', 'pest_control', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('DeCordova Pest Management', 'ma-pest-decordova-lincoln', 'pest_control', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),

    -- Littleton
    ('Littleton Pest Control', 'ma-pest-littleton-pest-control', 'pest_control', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Nagog Pond Exterminators', 'ma-pest-nagog-pond-exterminators-littleton', 'pest_control', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Littleton Pest Solutions', 'ma-pest-littleton-pest-solutions', 'pest_control', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Littleton Bug & Rodent Control', 'ma-pest-littleton-bug-rodent', 'pest_control', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Spectacle Pond Pest Management', 'ma-pest-spectacle-pond-littleton', 'pest_control', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),

    -- Lowell
    ('Lowell Pest Control', 'ma-pest-lowell-pest-control', 'pest_control', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Spindle City Exterminators', 'ma-pest-spindle-city-exterminators-lowell', 'pest_control', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Lowell Pest Solutions', 'ma-pest-lowell-pest-solutions', 'pest_control', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Lowell Bug & Rodent Control', 'ma-pest-lowell-bug-rodent', 'pest_control', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Pawtucket Falls Pest Management', 'ma-pest-pawtucket-falls-lowell', 'pest_control', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),

    -- Malden
    ('Malden Pest Control', 'ma-pest-malden-pest-control', 'pest_control', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Oak Grove Exterminators', 'ma-pest-oak-grove-exterminators-malden', 'pest_control', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Malden Pest Solutions', 'ma-pest-malden-pest-solutions', 'pest_control', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Malden Bug & Rodent Control', 'ma-pest-malden-bug-rodent', 'pest_control', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Fellsway Pest Management', 'ma-pest-fellsway-malden', 'pest_control', NULL, ARRAY['Malden','MA','Middlesex'], NULL),

    -- Marlborough
    ('Marlborough Pest Control', 'ma-pest-marlborough-pest-control', 'pest_control', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Williams Exterminators', 'ma-pest-williams-exterminators-marlborough', 'pest_control', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Marlborough Pest Solutions', 'ma-pest-marlborough-pest-solutions', 'pest_control', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Marlborough Bug & Rodent Control', 'ma-pest-marlborough-bug-rodent', 'pest_control', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Fort Meadow Pest Management', 'ma-pest-fort-meadow-marlborough', 'pest_control', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),

    -- Maynard
    ('Maynard Pest Control', 'ma-pest-maynard-pest-control', 'pest_control', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Assabet Village Exterminators', 'ma-pest-assabet-village-exterminators-maynard', 'pest_control', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Maynard Pest Solutions', 'ma-pest-maynard-pest-solutions', 'pest_control', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Maynard Bug & Rodent Control', 'ma-pest-maynard-bug-rodent', 'pest_control', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Mill Pond Pest Management Maynard', 'ma-pest-mill-pond-maynard', 'pest_control', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),

    -- Medford
    ('Medford Pest Control', 'ma-pest-medford-pest-control', 'pest_control', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Tufts Exterminators', 'ma-pest-tufts-exterminators-medford', 'pest_control', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Medford Pest Solutions', 'ma-pest-medford-pest-solutions', 'pest_control', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Medford Bug & Rodent Control', 'ma-pest-medford-bug-rodent', 'pest_control', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Mystic River Pest Management', 'ma-pest-mystic-river-medford', 'pest_control', NULL, ARRAY['Medford','MA','Middlesex'], NULL),

    -- Melrose
    ('Melrose Pest Control', 'ma-pest-melrose-pest-control', 'pest_control', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Ell Pond Exterminators', 'ma-pest-ell-pond-exterminators-melrose', 'pest_control', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Melrose Pest Solutions', 'ma-pest-melrose-pest-solutions', 'pest_control', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Melrose Bug & Rodent Control', 'ma-pest-melrose-bug-rodent', 'pest_control', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Pine Banks Pest Management', 'ma-pest-pine-banks-melrose', 'pest_control', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),

    -- Natick
    ('Natick Pest Control', 'ma-pest-natick-pest-control', 'pest_control', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Lake Cochituate Exterminators', 'ma-pest-lake-cochituate-exterminators-natick', 'pest_control', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Natick Pest Solutions', 'ma-pest-natick-pest-solutions', 'pest_control', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Natick Bug & Rodent Control', 'ma-pest-natick-bug-rodent', 'pest_control', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Hunnewell Pest Management', 'ma-pest-hunnewell-natick', 'pest_control', NULL, ARRAY['Natick','MA','Middlesex'], NULL),

    -- Newton
    ('Newton Pest Control', 'ma-pest-newton-pest-control', 'pest_control', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Crystal Lake Exterminators', 'ma-pest-crystal-lake-exterminators-newton', 'pest_control', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Newton Pest Solutions', 'ma-pest-newton-pest-solutions', 'pest_control', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Newton Bug & Rodent Control', 'ma-pest-newton-bug-rodent', 'pest_control', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Chestnut Hill Pest Management', 'ma-pest-chestnut-hill-newton', 'pest_control', NULL, ARRAY['Newton','MA','Middlesex'], NULL),

    -- North Reading
    ('North Reading Pest Control', 'ma-pest-north-reading-pest-control', 'pest_control', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('Martins Pond Exterminators', 'ma-pest-martins-pond-exterminators-north-reading', 'pest_control', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('North Reading Pest Solutions', 'ma-pest-north-reading-pest-solutions', 'pest_control', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('North Reading Bug & Rodent Control', 'ma-pest-north-reading-bug-rodent', 'pest_control', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('Ipswich River Pest Management North Reading', 'ma-pest-ipswich-river-north-reading', 'pest_control', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),

    -- Pepperell
    ('Pepperell Pest Control', 'ma-pest-pepperell-pest-control', 'pest_control', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Nissitissit Exterminators', 'ma-pest-nissitissit-exterminators-pepperell', 'pest_control', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Pepperell Pest Solutions', 'ma-pest-pepperell-pest-solutions', 'pest_control', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Pepperell Bug & Rodent Control', 'ma-pest-pepperell-bug-rodent', 'pest_control', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Covered Bridge Pest Management', 'ma-pest-covered-bridge-pepperell', 'pest_control', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),

    -- Reading
    ('Reading Pest Control', 'ma-pest-reading-pest-control', 'pest_control', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Birch Meadow Exterminators', 'ma-pest-birch-meadow-exterminators-reading', 'pest_control', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Reading Pest Solutions', 'ma-pest-reading-pest-solutions', 'pest_control', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Reading Bug & Rodent Control', 'ma-pest-reading-bug-rodent', 'pest_control', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Bare Meadow Pest Management', 'ma-pest-bare-meadow-reading', 'pest_control', NULL, ARRAY['Reading','MA','Middlesex'], NULL),

    -- Sherborn
    ('Sherborn Pest Control', 'ma-pest-sherborn-pest-control', 'pest_control', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Farm Pond Exterminators', 'ma-pest-farm-pond-exterminators-sherborn', 'pest_control', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Sherborn Pest Solutions', 'ma-pest-sherborn-pest-solutions', 'pest_control', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Sherborn Bug & Rodent Control', 'ma-pest-sherborn-bug-rodent', 'pest_control', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Rocky Narrows Pest Management', 'ma-pest-rocky-narrows-sherborn', 'pest_control', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),

    -- Shirley
    ('Shirley Pest Control', 'ma-pest-shirley-pest-control', 'pest_control', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Shirley Village Exterminators', 'ma-pest-shirley-village-exterminators', 'pest_control', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Shirley Pest Solutions', 'ma-pest-shirley-pest-solutions', 'pest_control', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Shirley Bug & Rodent Control', 'ma-pest-shirley-bug-rodent', 'pest_control', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Catacunemaug Pest Management', 'ma-pest-catacunemaug-shirley', 'pest_control', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),

    -- Somerville
    ('Somerville Pest Control', 'ma-pest-somerville-pest-control', 'pest_control', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Davis Square Exterminators', 'ma-pest-davis-square-exterminators-somerville', 'pest_control', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Somerville Pest Solutions', 'ma-pest-somerville-pest-solutions', 'pest_control', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Somerville Bug & Rodent Control', 'ma-pest-somerville-bug-rodent', 'pest_control', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Prospect Hill Pest Management', 'ma-pest-prospect-hill-somerville', 'pest_control', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),

    -- Stoneham
    ('Stoneham Pest Control', 'ma-pest-stoneham-pest-control', 'pest_control', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Spot Pond Exterminators', 'ma-pest-spot-pond-exterminators-stoneham', 'pest_control', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Stoneham Pest Solutions', 'ma-pest-stoneham-pest-solutions', 'pest_control', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Stoneham Bug & Rodent Control', 'ma-pest-stoneham-bug-rodent', 'pest_control', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Fells Pest Management', 'ma-pest-fells-stoneham', 'pest_control', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),

    -- Stow
    ('Stow Pest Control', 'ma-pest-stow-pest-control', 'pest_control', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Lake Boon Exterminators', 'ma-pest-lake-boon-exterminators-stow', 'pest_control', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Stow Pest Solutions', 'ma-pest-stow-pest-solutions', 'pest_control', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Stow Bug & Rodent Control', 'ma-pest-stow-bug-rodent', 'pest_control', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Assabet River Pest Management', 'ma-pest-assabet-river-stow', 'pest_control', NULL, ARRAY['Stow','MA','Middlesex'], NULL),

    -- Sudbury
    ('Sudbury Pest Control', 'ma-pest-sudbury-pest-control', 'pest_control', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Wayside Inn Exterminators', 'ma-pest-wayside-inn-exterminators-sudbury', 'pest_control', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Sudbury Pest Solutions', 'ma-pest-sudbury-pest-solutions', 'pest_control', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Sudbury Bug & Rodent Control', 'ma-pest-sudbury-bug-rodent', 'pest_control', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Nobscot Pest Management', 'ma-pest-nobscot-sudbury', 'pest_control', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),

    -- Tewksbury
    ('Tewksbury Pest Control', 'ma-pest-tewksbury-pest-control', 'pest_control', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Shawsheen River Exterminators', 'ma-pest-shawsheen-river-exterminators-tewksbury', 'pest_control', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Tewksbury Pest Solutions', 'ma-pest-tewksbury-pest-solutions', 'pest_control', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Tewksbury Bug & Rodent Control', 'ma-pest-tewksbury-bug-rodent', 'pest_control', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Long Pond Pest Management', 'ma-pest-long-pond-tewksbury', 'pest_control', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),

    -- Townsend
    ('Townsend Pest Control', 'ma-pest-townsend-pest-control', 'pest_control', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Squannacook Exterminators', 'ma-pest-squannacook-exterminators-townsend', 'pest_control', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Townsend Pest Solutions', 'ma-pest-townsend-pest-solutions', 'pest_control', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Townsend Bug & Rodent Control', 'ma-pest-townsend-bug-rodent', 'pest_control', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Willard Brook Pest Management', 'ma-pest-willard-brook-townsend', 'pest_control', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),

    -- Tyngsborough
    ('Tyngsborough Pest Control', 'ma-pest-tyngsborough-pest-control', 'pest_control', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Vesper Exterminators', 'ma-pest-vesper-exterminators-tyngsborough', 'pest_control', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Tyngsborough Pest Solutions', 'ma-pest-tyngsborough-pest-solutions', 'pest_control', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Tyngsborough Bug & Rodent Control', 'ma-pest-tyngsborough-bug-rodent', 'pest_control', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Mascuppic Pest Management', 'ma-pest-mascuppic-tyngsborough', 'pest_control', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),

    -- Wakefield
    ('Wakefield Pest Control', 'ma-pest-wakefield-pest-control', 'pest_control', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Lake Quannapowitt Exterminators', 'ma-pest-lake-quannapowitt-exterminators-wakefield', 'pest_control', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Wakefield Pest Solutions', 'ma-pest-wakefield-pest-solutions', 'pest_control', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Wakefield Bug & Rodent Control', 'ma-pest-wakefield-bug-rodent', 'pest_control', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Greenwood Pest Management', 'ma-pest-greenwood-wakefield', 'pest_control', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),

    -- Waltham
    ('Waltham Pest Control', 'ma-pest-waltham-pest-control', 'pest_control', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Watch City Exterminators', 'ma-pest-watch-city-exterminators-waltham', 'pest_control', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Waltham Pest Solutions', 'ma-pest-waltham-pest-solutions', 'pest_control', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Waltham Bug & Rodent Control', 'ma-pest-waltham-bug-rodent', 'pest_control', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Charles River Pest Management', 'ma-pest-charles-river-waltham', 'pest_control', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),

    -- Watertown
    ('Watertown Pest Control', 'ma-pest-watertown-pest-control', 'pest_control', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Arsenal Exterminators', 'ma-pest-arsenal-exterminators-watertown', 'pest_control', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Watertown Pest Solutions', 'ma-pest-watertown-pest-solutions', 'pest_control', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Watertown Bug & Rodent Control', 'ma-pest-watertown-bug-rodent', 'pest_control', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Mount Auburn Pest Management', 'ma-pest-mount-auburn-watertown', 'pest_control', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),

    -- Wayland
    ('Wayland Pest Control', 'ma-pest-wayland-pest-control', 'pest_control', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Dudley Pond Exterminators', 'ma-pest-dudley-pond-exterminators-wayland', 'pest_control', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Wayland Pest Solutions', 'ma-pest-wayland-pest-solutions', 'pest_control', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Wayland Bug & Rodent Control', 'ma-pest-wayland-bug-rodent', 'pest_control', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Heard Farm Pest Management', 'ma-pest-heard-farm-wayland', 'pest_control', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),

    -- Westford
    ('Westford Pest Control', 'ma-pest-westford-pest-control', 'pest_control', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Nashoba Exterminators', 'ma-pest-nashoba-exterminators-westford', 'pest_control', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Westford Pest Solutions', 'ma-pest-westford-pest-solutions', 'pest_control', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Westford Bug & Rodent Control', 'ma-pest-westford-bug-rodent', 'pest_control', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Forge Village Pest Management', 'ma-pest-forge-village-westford', 'pest_control', NULL, ARRAY['Westford','MA','Middlesex'], NULL),

    -- Weston
    ('Weston Pest Control', 'ma-pest-weston-pest-control', 'pest_control', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Cat Rock Exterminators', 'ma-pest-cat-rock-exterminators-weston', 'pest_control', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Weston Pest Solutions', 'ma-pest-weston-pest-solutions', 'pest_control', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Weston Bug & Rodent Control', 'ma-pest-weston-bug-rodent', 'pest_control', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Highland Forest Pest Management', 'ma-pest-highland-forest-weston', 'pest_control', NULL, ARRAY['Weston','MA','Middlesex'], NULL),

    -- Wilmington
    ('Wilmington Pest Control', 'ma-pest-wilmington-pest-control', 'pest_control', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Silver Lake Exterminators', 'ma-pest-silver-lake-exterminators-wilmington', 'pest_control', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Wilmington Pest Solutions', 'ma-pest-wilmington-pest-solutions', 'pest_control', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Wilmington Bug & Rodent Control', 'ma-pest-wilmington-bug-rodent', 'pest_control', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Butters Row Pest Management', 'ma-pest-butters-row-wilmington', 'pest_control', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),

    -- Winchester
    ('Winchester Pest Control', 'ma-pest-winchester-pest-control', 'pest_control', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Wedge Pond Exterminators', 'ma-pest-wedge-pond-exterminators-winchester', 'pest_control', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Winchester Pest Solutions', 'ma-pest-winchester-pest-solutions', 'pest_control', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Winchester Bug & Rodent Control', 'ma-pest-winchester-bug-rodent', 'pest_control', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Aberjona Pest Management', 'ma-pest-aberjona-winchester', 'pest_control', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),

    -- Woburn
    ('Woburn Pest Control', 'ma-pest-woburn-pest-control', 'pest_control', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Horn Pond Exterminators', 'ma-pest-horn-pond-exterminators-woburn', 'pest_control', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Woburn Pest Solutions', 'ma-pest-woburn-pest-solutions', 'pest_control', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Woburn Bug & Rodent Control', 'ma-pest-woburn-bug-rodent', 'pest_control', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Mishawum Pest Management', 'ma-pest-mishawum-woburn', 'pest_control', NULL, ARRAY['Woburn','MA','Middlesex'], NULL)

ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;


-- ============================================================================
-- SECTION 4: NORFOLK COUNTY, MA -- LOCAL PEST CONTROL FIRMS
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES

    -- Avon
    ('Avon Pest Control', 'ma-pest-avon-pest-control', 'pest_control', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Buckley Exterminators', 'ma-pest-buckley-exterminators-avon', 'pest_control', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Avon Pest Solutions', 'ma-pest-avon-pest-solutions', 'pest_control', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Avon Bug & Rodent Control', 'ma-pest-avon-bug-rodent', 'pest_control', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Central Street Pest Management', 'ma-pest-central-street-avon', 'pest_control', NULL, ARRAY['Avon','MA','Norfolk'], NULL),

    -- Braintree
    ('Braintree Pest Control', 'ma-pest-braintree-pest-control', 'pest_control', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('South Shore Exterminators', 'ma-pest-south-shore-exterminators-braintree', 'pest_control', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Braintree Pest Solutions', 'ma-pest-braintree-pest-solutions', 'pest_control', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Braintree Bug & Rodent Control', 'ma-pest-braintree-bug-rodent', 'pest_control', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Pond Meadow Pest Management', 'ma-pest-pond-meadow-braintree', 'pest_control', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),

    -- Brookline
    ('Brookline Pest Control', 'ma-pest-brookline-pest-control', 'pest_control', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Coolidge Corner Exterminators', 'ma-pest-coolidge-corner-exterminators-brookline', 'pest_control', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Brookline Pest Solutions', 'ma-pest-brookline-pest-solutions', 'pest_control', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Brookline Bug & Rodent Control', 'ma-pest-brookline-bug-rodent', 'pest_control', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Larz Anderson Pest Management', 'ma-pest-larz-anderson-brookline', 'pest_control', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),

    -- Canton
    ('Canton Pest Control', 'ma-pest-canton-pest-control', 'pest_control', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Ponkapoag Exterminators', 'ma-pest-ponkapoag-exterminators-canton', 'pest_control', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Canton Pest Solutions', 'ma-pest-canton-pest-solutions', 'pest_control', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Canton Bug & Rodent Control', 'ma-pest-canton-bug-rodent', 'pest_control', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Blue Hills Pest Management', 'ma-pest-blue-hills-canton', 'pest_control', NULL, ARRAY['Canton','MA','Norfolk'], NULL),

    -- Cohasset
    ('Cohasset Pest Control', 'ma-pest-cohasset-pest-control', 'pest_control', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Sandy Beach Exterminators', 'ma-pest-sandy-beach-exterminators-cohasset', 'pest_control', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Cohasset Pest Solutions', 'ma-pest-cohasset-pest-solutions', 'pest_control', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Cohasset Bug & Rodent Control', 'ma-pest-cohasset-bug-rodent', 'pest_control', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Minot Light Pest Management', 'ma-pest-minot-light-cohasset', 'pest_control', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),

    -- Dedham
    ('Dedham Pest Control', 'ma-pest-dedham-pest-control', 'pest_control', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Fairbanks Exterminators', 'ma-pest-fairbanks-exterminators-dedham', 'pest_control', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Dedham Pest Solutions', 'ma-pest-dedham-pest-solutions', 'pest_control', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Dedham Bug & Rodent Control', 'ma-pest-dedham-bug-rodent', 'pest_control', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Mother Brook Pest Management', 'ma-pest-mother-brook-dedham', 'pest_control', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),

    -- Dover
    ('Dover Pest Control', 'ma-pest-dover-pest-control', 'pest_control', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Noanet Exterminators', 'ma-pest-noanet-exterminators-dover', 'pest_control', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Dover Pest Solutions', 'ma-pest-dover-pest-solutions', 'pest_control', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Dover Bug & Rodent Control', 'ma-pest-dover-bug-rodent', 'pest_control', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Charles River Pest Management Dover', 'ma-pest-charles-river-dover', 'pest_control', NULL, ARRAY['Dover','MA','Norfolk'], NULL),

    -- Foxborough
    ('Foxborough Pest Control', 'ma-pest-foxborough-pest-control', 'pest_control', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Patriot Place Exterminators', 'ma-pest-patriot-place-exterminators-foxborough', 'pest_control', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Foxborough Pest Solutions', 'ma-pest-foxborough-pest-solutions', 'pest_control', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Foxborough Bug & Rodent Control', 'ma-pest-foxborough-bug-rodent', 'pest_control', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Cocasset River Pest Management', 'ma-pest-cocasset-river-foxborough', 'pest_control', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),

    -- Franklin
    ('Franklin Pest Control', 'ma-pest-franklin-pest-control', 'pest_control', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Dean College Exterminators', 'ma-pest-dean-college-exterminators-franklin', 'pest_control', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Franklin Pest Solutions', 'ma-pest-franklin-pest-solutions', 'pest_control', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Franklin Bug & Rodent Control', 'ma-pest-franklin-bug-rodent', 'pest_control', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Mine Brook Pest Management', 'ma-pest-mine-brook-franklin', 'pest_control', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),

    -- Holbrook
    ('Holbrook Pest Control', 'ma-pest-holbrook-pest-control', 'pest_control', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Cochato Exterminators', 'ma-pest-cochato-exterminators-holbrook', 'pest_control', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Holbrook Pest Solutions', 'ma-pest-holbrook-pest-solutions', 'pest_control', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Holbrook Bug & Rodent Control', 'ma-pest-holbrook-bug-rodent', 'pest_control', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Union Street Pest Management', 'ma-pest-union-street-holbrook', 'pest_control', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),

    -- Medfield
    ('Medfield Pest Control', 'ma-pest-medfield-pest-control', 'pest_control', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Rocky Woods Exterminators', 'ma-pest-rocky-woods-exterminators-medfield', 'pest_control', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Medfield Pest Solutions', 'ma-pest-medfield-pest-solutions', 'pest_control', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Medfield Bug & Rodent Control', 'ma-pest-medfield-bug-rodent', 'pest_control', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Noon Hill Pest Management', 'ma-pest-noon-hill-medfield', 'pest_control', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),

    -- Medway
    ('Medway Pest Control', 'ma-pest-medway-pest-control', 'pest_control', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Choate Park Exterminators', 'ma-pest-choate-park-exterminators-medway', 'pest_control', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Medway Pest Solutions', 'ma-pest-medway-pest-solutions', 'pest_control', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Medway Bug & Rodent Control', 'ma-pest-medway-bug-rodent', 'pest_control', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Chicken Brook Pest Management', 'ma-pest-chicken-brook-medway', 'pest_control', NULL, ARRAY['Medway','MA','Norfolk'], NULL),

    -- Millis
    ('Millis Pest Control', 'ma-pest-millis-pest-control', 'pest_control', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Bogastow Exterminators', 'ma-pest-bogastow-exterminators-millis', 'pest_control', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Millis Pest Solutions', 'ma-pest-millis-pest-solutions', 'pest_control', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Millis Bug & Rodent Control', 'ma-pest-millis-bug-rodent', 'pest_control', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Charles River Pest Management Millis', 'ma-pest-charles-river-millis', 'pest_control', NULL, ARRAY['Millis','MA','Norfolk'], NULL),

    -- Milton
    ('Milton Pest Control', 'ma-pest-milton-pest-control', 'pest_control', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Great Blue Hill Exterminators', 'ma-pest-great-blue-hill-exterminators-milton', 'pest_control', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Milton Pest Solutions', 'ma-pest-milton-pest-solutions', 'pest_control', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Milton Bug & Rodent Control', 'ma-pest-milton-bug-rodent', 'pest_control', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Cunningham Pest Management', 'ma-pest-cunningham-milton', 'pest_control', NULL, ARRAY['Milton','MA','Norfolk'], NULL),

    -- Needham
    ('Needham Pest Control', 'ma-pest-needham-pest-control', 'pest_control', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Ridge Hill Exterminators', 'ma-pest-ridge-hill-exterminators-needham', 'pest_control', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Needham Pest Solutions', 'ma-pest-needham-pest-solutions', 'pest_control', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Needham Bug & Rodent Control', 'ma-pest-needham-bug-rodent', 'pest_control', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Cutler Park Pest Management', 'ma-pest-cutler-park-needham', 'pest_control', NULL, ARRAY['Needham','MA','Norfolk'], NULL),

    -- Norfolk
    ('Norfolk Pest Control', 'ma-pest-norfolk-pest-control', 'pest_control', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('King Philip Exterminators', 'ma-pest-king-philip-exterminators-norfolk', 'pest_control', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Norfolk Pest Solutions', 'ma-pest-norfolk-pest-solutions', 'pest_control', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Norfolk Bug & Rodent Control', 'ma-pest-norfolk-bug-rodent', 'pest_control', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Stony Brook Pest Management', 'ma-pest-stony-brook-norfolk', 'pest_control', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),

    -- Norwood
    ('Norwood Pest Control', 'ma-pest-norwood-pest-control', 'pest_control', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Ellis Pond Exterminators', 'ma-pest-ellis-pond-exterminators-norwood', 'pest_control', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Norwood Pest Solutions', 'ma-pest-norwood-pest-solutions', 'pest_control', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Norwood Bug & Rodent Control', 'ma-pest-norwood-bug-rodent', 'pest_control', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Endean Pest Management', 'ma-pest-endean-norwood', 'pest_control', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),

    -- Plainville
    ('Plainville Pest Control', 'ma-pest-plainville-pest-control', 'pest_control', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Turnpike Exterminators', 'ma-pest-turnpike-exterminators-plainville', 'pest_control', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Plainville Pest Solutions', 'ma-pest-plainville-pest-solutions', 'pest_control', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Plainville Bug & Rodent Control', 'ma-pest-plainville-bug-rodent', 'pest_control', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Wampum Corner Pest Management', 'ma-pest-wampum-corner-plainville', 'pest_control', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),

    -- Quincy
    ('Quincy Pest Control', 'ma-pest-quincy-pest-control', 'pest_control', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Granite City Exterminators', 'ma-pest-granite-city-exterminators-quincy', 'pest_control', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Quincy Pest Solutions', 'ma-pest-quincy-pest-solutions', 'pest_control', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Quincy Bug & Rodent Control', 'ma-pest-quincy-bug-rodent', 'pest_control', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Wollaston Pest Management', 'ma-pest-wollaston-quincy', 'pest_control', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),

    -- Randolph
    ('Randolph Pest Control', 'ma-pest-randolph-pest-control', 'pest_control', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Stetson Exterminators', 'ma-pest-stetson-exterminators-randolph', 'pest_control', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Randolph Pest Solutions', 'ma-pest-randolph-pest-solutions', 'pest_control', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Randolph Bug & Rodent Control', 'ma-pest-randolph-bug-rodent', 'pest_control', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Great Pond Pest Management', 'ma-pest-great-pond-randolph', 'pest_control', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),

    -- Sharon
    ('Sharon Pest Control', 'ma-pest-sharon-pest-control', 'pest_control', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Lake Massapoag Exterminators', 'ma-pest-lake-massapoag-exterminators-sharon', 'pest_control', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Sharon Pest Solutions', 'ma-pest-sharon-pest-solutions', 'pest_control', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Sharon Bug & Rodent Control', 'ma-pest-sharon-bug-rodent', 'pest_control', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Moose Hill Pest Management', 'ma-pest-moose-hill-sharon', 'pest_control', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),

    -- Stoughton
    ('Stoughton Pest Control', 'ma-pest-stoughton-pest-control', 'pest_control', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Ames Exterminators', 'ma-pest-ames-exterminators-stoughton', 'pest_control', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Stoughton Pest Solutions', 'ma-pest-stoughton-pest-solutions', 'pest_control', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Stoughton Bug & Rodent Control', 'ma-pest-stoughton-bug-rodent', 'pest_control', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Cedar Swamp Pest Management', 'ma-pest-cedar-swamp-stoughton', 'pest_control', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),

    -- Walpole
    ('Walpole Pest Control', 'ma-pest-walpole-pest-control', 'pest_control', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Bird Park Exterminators', 'ma-pest-bird-park-exterminators-walpole', 'pest_control', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Walpole Pest Solutions', 'ma-pest-walpole-pest-solutions', 'pest_control', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Walpole Bug & Rodent Control', 'ma-pest-walpole-bug-rodent', 'pest_control', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Neponset Pest Management', 'ma-pest-neponset-walpole', 'pest_control', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),

    -- Wellesley
    ('Wellesley Pest Control', 'ma-pest-wellesley-pest-control', 'pest_control', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Lake Waban Exterminators', 'ma-pest-lake-waban-exterminators-wellesley', 'pest_control', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Wellesley Pest Solutions', 'ma-pest-wellesley-pest-solutions', 'pest_control', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Wellesley Bug & Rodent Control', 'ma-pest-wellesley-bug-rodent', 'pest_control', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Hunnewell Pest Management', 'ma-pest-hunnewell-wellesley', 'pest_control', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),

    -- Westwood
    ('Westwood Pest Control', 'ma-pest-westwood-pest-control', 'pest_control', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Hale Reservation Exterminators', 'ma-pest-hale-reservation-exterminators-westwood', 'pest_control', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Westwood Pest Solutions', 'ma-pest-westwood-pest-solutions', 'pest_control', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Westwood Bug & Rodent Control', 'ma-pest-westwood-bug-rodent', 'pest_control', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Buckmaster Pond Pest Management', 'ma-pest-buckmaster-pond-westwood', 'pest_control', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),

    -- Weymouth
    ('Weymouth Pest Control', 'ma-pest-weymouth-pest-control', 'pest_control', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Wessagusset Exterminators', 'ma-pest-wessagusset-exterminators-weymouth', 'pest_control', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Weymouth Pest Solutions', 'ma-pest-weymouth-pest-solutions', 'pest_control', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Weymouth Bug & Rodent Control', 'ma-pest-weymouth-bug-rodent', 'pest_control', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Great Esker Pest Management', 'ma-pest-great-esker-weymouth', 'pest_control', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),

    -- Wrentham
    ('Wrentham Pest Control', 'ma-pest-wrentham-pest-control', 'pest_control', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Sweatt Exterminators', 'ma-pest-sweatt-exterminators-wrentham', 'pest_control', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Wrentham Pest Solutions', 'ma-pest-wrentham-pest-solutions', 'pest_control', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Wrentham Bug & Rodent Control', 'ma-pest-wrentham-bug-rodent', 'pest_control', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Lake Pearl Pest Management', 'ma-pest-lake-pearl-wrentham', 'pest_control', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL)

ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;


-- ============================================================================
-- SECTION 5: PLYMOUTH COUNTY, MA -- LOCAL PEST CONTROL FIRMS
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES

    -- Abington
    ('Abington Pest Control', 'ma-pest-abington-pest-control', 'pest_control', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Island Grove Exterminators', 'ma-pest-island-grove-exterminators-abington', 'pest_control', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Abington Pest Solutions', 'ma-pest-abington-pest-solutions', 'pest_control', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Abington Bug & Rodent Control', 'ma-pest-abington-bug-rodent', 'pest_control', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Shumatuscacant Pest Management', 'ma-pest-shumatuscacant-abington', 'pest_control', NULL, ARRAY['Abington','MA','Plymouth'], NULL),

    -- Bridgewater
    ('Bridgewater Pest Control', 'ma-pest-bridgewater-pest-control', 'pest_control', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Town River Exterminators', 'ma-pest-town-river-exterminators-bridgewater', 'pest_control', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Pest Solutions', 'ma-pest-bridgewater-pest-solutions', 'pest_control', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Bug & Rodent Control', 'ma-pest-bridgewater-bug-rodent', 'pest_control', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Carver Pond Pest Management', 'ma-pest-carver-pond-bridgewater', 'pest_control', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),

    -- Brockton
    ('Brockton Pest Control', 'ma-pest-brockton-pest-control', 'pest_control', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Champion City Exterminators', 'ma-pest-champion-city-exterminators-brockton', 'pest_control', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Brockton Pest Solutions', 'ma-pest-brockton-pest-solutions', 'pest_control', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Brockton Bug & Rodent Control', 'ma-pest-brockton-bug-rodent', 'pest_control', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Salisbury Brook Pest Management', 'ma-pest-salisbury-brook-brockton', 'pest_control', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),

    -- Carver
    ('Carver Pest Control', 'ma-pest-carver-pest-control', 'pest_control', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Cranberry Bog Exterminators Carver', 'ma-pest-cranberry-bog-exterminators-carver', 'pest_control', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Carver Pest Solutions', 'ma-pest-carver-pest-solutions', 'pest_control', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Carver Bug & Rodent Control', 'ma-pest-carver-bug-rodent', 'pest_control', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('South Meadow Pest Management', 'ma-pest-south-meadow-carver', 'pest_control', NULL, ARRAY['Carver','MA','Plymouth'], NULL),

    -- Duxbury
    ('Duxbury Pest Control', 'ma-pest-duxbury-pest-control', 'pest_control', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Standish Exterminators', 'ma-pest-standish-exterminators-duxbury', 'pest_control', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Duxbury Pest Solutions', 'ma-pest-duxbury-pest-solutions', 'pest_control', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Duxbury Bug & Rodent Control', 'ma-pest-duxbury-bug-rodent', 'pest_control', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Bluefish River Pest Management', 'ma-pest-bluefish-river-duxbury', 'pest_control', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),

    -- East Bridgewater
    ('East Bridgewater Pest Control', 'ma-pest-east-bridgewater-pest-control', 'pest_control', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('Satucket Exterminators', 'ma-pest-satucket-exterminators-east-bridgewater', 'pest_control', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('East Bridgewater Pest Solutions', 'ma-pest-east-bridgewater-pest-solutions', 'pest_control', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('East Bridgewater Bug & Rodent Control', 'ma-pest-east-bridgewater-bug-rodent', 'pest_control', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('Robbins Pond Pest Management', 'ma-pest-robbins-pond-east-bridgewater', 'pest_control', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),

    -- Halifax
    ('Halifax Pest Control', 'ma-pest-halifax-pest-control', 'pest_control', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Monponsett Exterminators', 'ma-pest-monponsett-exterminators-halifax', 'pest_control', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Halifax Pest Solutions', 'ma-pest-halifax-pest-solutions', 'pest_control', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Halifax Bug & Rodent Control', 'ma-pest-halifax-bug-rodent', 'pest_control', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Thompson Street Pest Management', 'ma-pest-thompson-street-halifax', 'pest_control', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),

    -- Hanover
    ('Hanover Pest Control', 'ma-pest-hanover-pest-control', 'pest_control', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Drinkwater Exterminators', 'ma-pest-drinkwater-exterminators-hanover', 'pest_control', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Hanover Pest Solutions', 'ma-pest-hanover-pest-solutions', 'pest_control', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Hanover Bug & Rodent Control', 'ma-pest-hanover-bug-rodent', 'pest_control', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Indian Head Pest Management', 'ma-pest-indian-head-hanover', 'pest_control', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),

    -- Hanson
    ('Hanson Pest Control', 'ma-pest-hanson-pest-control', 'pest_control', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Wampatuck Exterminators', 'ma-pest-wampatuck-exterminators-hanson', 'pest_control', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Hanson Pest Solutions', 'ma-pest-hanson-pest-solutions', 'pest_control', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Hanson Bug & Rodent Control', 'ma-pest-hanson-bug-rodent', 'pest_control', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Indian Pond Pest Management', 'ma-pest-indian-pond-hanson', 'pest_control', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),

    -- Hingham
    ('Hingham Pest Control', 'ma-pest-hingham-pest-control', 'pest_control', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Old Colony Exterminators', 'ma-pest-old-colony-exterminators-hingham', 'pest_control', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Hingham Pest Solutions', 'ma-pest-hingham-pest-solutions', 'pest_control', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Hingham Bug & Rodent Control', 'ma-pest-hingham-bug-rodent', 'pest_control', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('World''s End Pest Management', 'ma-pest-worlds-end-hingham', 'pest_control', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),

    -- Hull
    ('Hull Pest Control', 'ma-pest-hull-pest-control', 'pest_control', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Nantasket Exterminators', 'ma-pest-nantasket-exterminators-hull', 'pest_control', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Hull Pest Solutions', 'ma-pest-hull-pest-solutions', 'pest_control', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Hull Bug & Rodent Control', 'ma-pest-hull-bug-rodent', 'pest_control', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Paragon Park Pest Management', 'ma-pest-paragon-park-hull', 'pest_control', NULL, ARRAY['Hull','MA','Plymouth'], NULL),

    -- Kingston
    ('Kingston Pest Control', 'ma-pest-kingston-pest-control', 'pest_control', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Jones River Exterminators', 'ma-pest-jones-river-exterminators-kingston', 'pest_control', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Kingston Pest Solutions', 'ma-pest-kingston-pest-solutions', 'pest_control', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Kingston Bug & Rodent Control', 'ma-pest-kingston-bug-rodent', 'pest_control', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Silver Lake Pest Management Kingston', 'ma-pest-silver-lake-kingston', 'pest_control', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),

    -- Lakeville
    ('Lakeville Pest Control', 'ma-pest-lakeville-pest-control', 'pest_control', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Assawompset Exterminators', 'ma-pest-assawompset-exterminators-lakeville', 'pest_control', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Lakeville Pest Solutions', 'ma-pest-lakeville-pest-solutions', 'pest_control', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Lakeville Bug & Rodent Control', 'ma-pest-lakeville-bug-rodent', 'pest_control', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Long Pond Pest Management Lakeville', 'ma-pest-long-pond-lakeville', 'pest_control', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),

    -- Marion
    ('Marion Pest Control', 'ma-pest-marion-pest-control', 'pest_control', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Sippican Exterminators', 'ma-pest-sippican-exterminators-marion', 'pest_control', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Marion Pest Solutions', 'ma-pest-marion-pest-solutions', 'pest_control', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Marion Bug & Rodent Control', 'ma-pest-marion-bug-rodent', 'pest_control', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Tabor Academy Pest Management', 'ma-pest-tabor-academy-marion', 'pest_control', NULL, ARRAY['Marion','MA','Plymouth'], NULL),

    -- Marshfield
    ('Marshfield Pest Control', 'ma-pest-marshfield-pest-control', 'pest_control', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Green Harbor Exterminators', 'ma-pest-green-harbor-exterminators-marshfield', 'pest_control', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Marshfield Pest Solutions', 'ma-pest-marshfield-pest-solutions', 'pest_control', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Marshfield Bug & Rodent Control', 'ma-pest-marshfield-bug-rodent', 'pest_control', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Rexhame Pest Management', 'ma-pest-rexhame-marshfield', 'pest_control', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),

    -- Mattapoisett
    ('Mattapoisett Pest Control', 'ma-pest-mattapoisett-pest-control', 'pest_control', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Ned''s Point Exterminators', 'ma-pest-neds-point-exterminators-mattapoisett', 'pest_control', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Mattapoisett Pest Solutions', 'ma-pest-mattapoisett-pest-solutions', 'pest_control', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Mattapoisett Bug & Rodent Control', 'ma-pest-mattapoisett-bug-rodent', 'pest_control', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Angelica Point Pest Management', 'ma-pest-angelica-point-mattapoisett', 'pest_control', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),

    -- Middleborough
    ('Middleborough Pest Control', 'ma-pest-middleborough-pest-control', 'pest_control', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Nemasket Exterminators', 'ma-pest-nemasket-exterminators-middleborough', 'pest_control', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Middleborough Pest Solutions', 'ma-pest-middleborough-pest-solutions', 'pest_control', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Middleborough Bug & Rodent Control', 'ma-pest-middleborough-bug-rodent', 'pest_control', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Tispaquin Pest Management', 'ma-pest-tispaquin-middleborough', 'pest_control', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),

    -- Norwell
    ('Norwell Pest Control', 'ma-pest-norwell-pest-control', 'pest_control', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Jacobs Pond Exterminators', 'ma-pest-jacobs-pond-exterminators-norwell', 'pest_control', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Norwell Pest Solutions', 'ma-pest-norwell-pest-solutions', 'pest_control', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Norwell Bug & Rodent Control', 'ma-pest-norwell-bug-rodent', 'pest_control', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('North River Pest Management', 'ma-pest-north-river-norwell', 'pest_control', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),

    -- Pembroke
    ('Pembroke Pest Control', 'ma-pest-pembroke-pest-control', 'pest_control', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Herring Brook Exterminators', 'ma-pest-herring-brook-exterminators-pembroke', 'pest_control', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Pembroke Pest Solutions', 'ma-pest-pembroke-pest-solutions', 'pest_control', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Pembroke Bug & Rodent Control', 'ma-pest-pembroke-bug-rodent', 'pest_control', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Hobomock Pest Management', 'ma-pest-hobomock-pembroke', 'pest_control', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),

    -- Plymouth
    ('Plymouth Pest Control', 'ma-pest-plymouth-pest-control', 'pest_control', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Pilgrim Exterminators', 'ma-pest-pilgrim-exterminators-plymouth', 'pest_control', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Plymouth Pest Solutions', 'ma-pest-plymouth-pest-solutions', 'pest_control', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Plymouth Bug & Rodent Control', 'ma-pest-plymouth-bug-rodent', 'pest_control', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Myles Standish Pest Management', 'ma-pest-myles-standish-plymouth', 'pest_control', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),

    -- Plympton
    ('Plympton Pest Control', 'ma-pest-plympton-pest-control', 'pest_control', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Winnetuxet Exterminators', 'ma-pest-winnetuxet-exterminators-plympton', 'pest_control', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Plympton Pest Solutions', 'ma-pest-plympton-pest-solutions', 'pest_control', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Plympton Bug & Rodent Control', 'ma-pest-plympton-bug-rodent', 'pest_control', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Colchester Brook Pest Management', 'ma-pest-colchester-brook-plympton', 'pest_control', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),

    -- Rochester
    ('Rochester Pest Control', 'ma-pest-rochester-pest-control', 'pest_control', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Mattapoisett River Exterminators', 'ma-pest-mattapoisett-river-exterminators-rochester', 'pest_control', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Rochester Pest Solutions', 'ma-pest-rochester-pest-solutions', 'pest_control', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Rochester Bug & Rodent Control', 'ma-pest-rochester-bug-rodent', 'pest_control', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Snipatuit Pest Management', 'ma-pest-snipatuit-rochester', 'pest_control', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),

    -- Rockland
    ('Rockland Pest Control', 'ma-pest-rockland-pest-control', 'pest_control', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Reed Pond Exterminators', 'ma-pest-reed-pond-exterminators-rockland', 'pest_control', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Rockland Pest Solutions', 'ma-pest-rockland-pest-solutions', 'pest_control', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Rockland Bug & Rodent Control', 'ma-pest-rockland-bug-rodent', 'pest_control', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('French Stream Pest Management', 'ma-pest-french-stream-rockland', 'pest_control', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),

    -- Scituate
    ('Scituate Pest Control', 'ma-pest-scituate-pest-control', 'pest_control', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Lighthouse Exterminators', 'ma-pest-lighthouse-exterminators-scituate', 'pest_control', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Scituate Pest Solutions', 'ma-pest-scituate-pest-solutions', 'pest_control', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Scituate Bug & Rodent Control', 'ma-pest-scituate-bug-rodent', 'pest_control', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Minot Beach Pest Management', 'ma-pest-minot-beach-scituate', 'pest_control', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),

    -- Wareham
    ('Wareham Pest Control', 'ma-pest-wareham-pest-control', 'pest_control', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Onset Exterminators', 'ma-pest-onset-exterminators-wareham', 'pest_control', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Wareham Pest Solutions', 'ma-pest-wareham-pest-solutions', 'pest_control', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Wareham Bug & Rodent Control', 'ma-pest-wareham-bug-rodent', 'pest_control', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Buzzards Bay Pest Management', 'ma-pest-buzzards-bay-wareham', 'pest_control', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),

    -- West Bridgewater
    ('West Bridgewater Pest Control', 'ma-pest-west-bridgewater-pest-control', 'pest_control', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('Cochesett Exterminators', 'ma-pest-cochesett-exterminators-west-bridgewater', 'pest_control', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('West Bridgewater Pest Solutions', 'ma-pest-west-bridgewater-pest-solutions', 'pest_control', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('West Bridgewater Bug & Rodent Control', 'ma-pest-west-bridgewater-bug-rodent', 'pest_control', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('Howard Street Pest Management', 'ma-pest-howard-street-west-bridgewater', 'pest_control', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),

    -- Whitman
    ('Whitman Pest Control', 'ma-pest-whitman-pest-control', 'pest_control', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Auburn Lake Exterminators', 'ma-pest-auburn-lake-exterminators-whitman', 'pest_control', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Whitman Pest Solutions', 'ma-pest-whitman-pest-solutions', 'pest_control', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Whitman Bug & Rodent Control', 'ma-pest-whitman-bug-rodent', 'pest_control', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Hobart Pond Pest Management', 'ma-pest-hobart-pond-whitman', 'pest_control', NULL, ARRAY['Whitman','MA','Plymouth'], NULL)

ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;
