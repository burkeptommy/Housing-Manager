-- Seed irrigation, security, and solar companies into utility_providers
-- for 4 Massachusetts counties: Essex, Middlesex, Norfolk, Plymouth.
--
-- These three categories complete the home-services coverage for suburban
-- HNW homeowners in Greater Boston. Irrigation is seasonal but critical for
-- property value; security systems are common in affluent towns; and solar
-- adoption is accelerating across the region with MA SMART incentives.
--
-- This migration covers:
--   Sections 1-5:   Irrigation (regional + 4 counties, 5 per town)
--   Sections 6-10:  Security (regional + 4 counties, 5 per town)
--   Sections 11-15: Solar (regional + 4 counties, 5 per town)
--
-- Total: ~2,139 rows (713 per category x 3). All logo_url = NULL;
-- Brandfetch lazy enrichment resolves them on first picker render.
--
-- ON CONFLICT (slug) DO UPDATE ensures re-runs update without duplicates.


-- ============================================================================
-- SECTION 1: MA REGIONAL IRRIGATION COMPANIES
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    ('Bay State Irrigation', 'ma-irrigation-bay-state', 'irrigation', 'https://www.baystateirrigation.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('New England Irrigation Services', 'ma-irrigation-new-england-services', 'irrigation', 'https://www.newenglandirrigation.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Aqua-Lawn Sprinkler', 'ma-irrigation-aqua-lawn-needham', 'irrigation', 'https://www.aqualawnsprinkler.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Suburban Irrigation', 'ma-irrigation-suburban-burlington', 'irrigation', 'https://www.suburbanirrigation.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('North Shore Sprinkler', 'ma-irrigation-north-shore-sprinkler', 'irrigation', 'https://www.northshoresprinkler.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('South Shore Irrigation', 'ma-irrigation-south-shore', 'irrigation', 'https://www.southshoreirrigation.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('MetroWest Irrigation', 'ma-irrigation-metrowest', 'irrigation', NULL, ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Colonial Sprinkler Systems', 'ma-irrigation-colonial-sprinkler', 'irrigation', NULL, ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;


-- ============================================================================
-- SECTION 2: ESSEX COUNTY, MA -- LOCAL IRRIGATION FIRMS
-- (33 towns x 5 = 165 rows)
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES

    -- Andover
    ('Andover Irrigation', 'ma-irrigation-andover-irrigation', 'irrigation', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Sullivan Sprinkler Systems', 'ma-irrigation-sullivan-andover', 'irrigation', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Merrimack Valley Lawn Irrigation', 'ma-irrigation-merrimack-valley-lawn-andover', 'irrigation', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Andover Sprinkler Co.', 'ma-irrigation-andover-sprinkler-co', 'irrigation', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Merrimack Valley Water Systems', 'ma-irrigation-merrimack-valley-water-andover', 'irrigation', NULL, ARRAY['Andover','MA','Essex'], NULL),
    -- Beverly
    ('Beverly Irrigation', 'ma-irrigation-beverly-irrigation', 'irrigation', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Harrington Sprinkler Systems', 'ma-irrigation-harrington-beverly', 'irrigation', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('North Shore Lawn Irrigation', 'ma-irrigation-north-shore-lawn-beverly', 'irrigation', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Beverly Sprinkler Co.', 'ma-irrigation-beverly-sprinkler-co', 'irrigation', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('North Shore Water Systems', 'ma-irrigation-north-shore-water-beverly', 'irrigation', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    -- Boxford
    ('Boxford Irrigation', 'ma-irrigation-boxford-irrigation', 'irrigation', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Kelleher Sprinkler Systems', 'ma-irrigation-kelleher-boxford', 'irrigation', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Boxford Area Lawn Irrigation', 'ma-irrigation-boxford-area-lawn-boxford', 'irrigation', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Boxford Sprinkler Co.', 'ma-irrigation-boxford-sprinkler-co', 'irrigation', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Boxford Area Water Systems', 'ma-irrigation-boxford-area-water-boxford', 'irrigation', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    -- Danvers
    ('Danvers Irrigation', 'ma-irrigation-danvers-irrigation', 'irrigation', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Petralia Sprinkler Systems', 'ma-irrigation-petralia-danvers', 'irrigation', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('North Shore Lawn Irrigation', 'ma-irrigation-north-shore-lawn-danvers', 'irrigation', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Danvers Sprinkler Co.', 'ma-irrigation-danvers-sprinkler-co', 'irrigation', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('North Shore Water Systems', 'ma-irrigation-north-shore-water-danvers', 'irrigation', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    -- Essex
    ('Essex Irrigation', 'ma-irrigation-essex-irrigation', 'irrigation', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Burnham Sprinkler Systems', 'ma-irrigation-burnham-essex', 'irrigation', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Cape Ann Lawn Irrigation', 'ma-irrigation-cape-ann-lawn-essex', 'irrigation', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Essex Sprinkler Co.', 'ma-irrigation-essex-sprinkler-co', 'irrigation', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Cape Ann Water Systems', 'ma-irrigation-cape-ann-water-essex', 'irrigation', NULL, ARRAY['Essex','MA','Essex'], NULL),
    -- Georgetown
    ('Georgetown Irrigation', 'ma-irrigation-georgetown-irrigation', 'irrigation', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Thurlow Sprinkler Systems', 'ma-irrigation-thurlow-georgetown', 'irrigation', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Pentucket Lawn Irrigation', 'ma-irrigation-pentucket-lawn-georgetown', 'irrigation', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Georgetown Sprinkler Co.', 'ma-irrigation-georgetown-sprinkler-co', 'irrigation', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Pentucket Water Systems', 'ma-irrigation-pentucket-water-georgetown', 'irrigation', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    -- Gloucester
    ('Gloucester Irrigation', 'ma-irrigation-gloucester-irrigation', 'irrigation', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Favazza Sprinkler Systems', 'ma-irrigation-favazza-gloucester', 'irrigation', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Cape Ann Lawn Irrigation', 'ma-irrigation-cape-ann-lawn-gloucester', 'irrigation', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Gloucester Sprinkler Co.', 'ma-irrigation-gloucester-sprinkler-co', 'irrigation', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Cape Ann Water Systems', 'ma-irrigation-cape-ann-water-gloucester', 'irrigation', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    -- Groveland
    ('Groveland Irrigation', 'ma-irrigation-groveland-irrigation', 'irrigation', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Batchelder Sprinkler Systems', 'ma-irrigation-batchelder-groveland', 'irrigation', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Pentucket Lawn Irrigation', 'ma-irrigation-pentucket-lawn-groveland', 'irrigation', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Groveland Sprinkler Co.', 'ma-irrigation-groveland-sprinkler-co', 'irrigation', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Pentucket Water Systems', 'ma-irrigation-pentucket-water-groveland', 'irrigation', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    -- Hamilton
    ('Hamilton Irrigation', 'ma-irrigation-hamilton-irrigation', 'irrigation', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Appleton Sprinkler Systems', 'ma-irrigation-appleton-hamilton', 'irrigation', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Hamilton-Wenham Lawn Irrigation', 'ma-irrigation-hamilton-wenham-lawn-hamilton', 'irrigation', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Hamilton Sprinkler Co.', 'ma-irrigation-hamilton-sprinkler-co', 'irrigation', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Hamilton-Wenham Water Systems', 'ma-irrigation-hamilton-wenham-water-hamilton', 'irrigation', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    -- Haverhill
    ('Haverhill Irrigation', 'ma-irrigation-haverhill-irrigation', 'irrigation', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Moriarty Sprinkler Systems', 'ma-irrigation-moriarty-haverhill', 'irrigation', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Merrimack Valley Lawn Irrigation', 'ma-irrigation-merrimack-valley-lawn-haverhill', 'irrigation', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Haverhill Sprinkler Co.', 'ma-irrigation-haverhill-sprinkler-co', 'irrigation', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Merrimack Valley Water Systems', 'ma-irrigation-merrimack-valley-water-haverhill', 'irrigation', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    -- Ipswich
    ('Ipswich Irrigation', 'ma-irrigation-ipswich-irrigation', 'irrigation', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Goodhue Sprinkler Systems', 'ma-irrigation-goodhue-ipswich', 'irrigation', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Ipswich Bay Lawn Irrigation', 'ma-irrigation-ipswich-bay-lawn-ipswich', 'irrigation', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Ipswich Sprinkler Co.', 'ma-irrigation-ipswich-sprinkler-co', 'irrigation', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Ipswich Bay Water Systems', 'ma-irrigation-ipswich-bay-water-ipswich', 'irrigation', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    -- Lawrence
    ('Lawrence Irrigation', 'ma-irrigation-lawrence-irrigation', 'irrigation', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Ortiz Sprinkler Systems', 'ma-irrigation-ortiz-lawrence', 'irrigation', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Merrimack Valley Lawn Irrigation', 'ma-irrigation-merrimack-valley-lawn-lawrence', 'irrigation', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Lawrence Sprinkler Co.', 'ma-irrigation-lawrence-sprinkler-co', 'irrigation', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Merrimack Valley Water Systems', 'ma-irrigation-merrimack-valley-water-lawrence', 'irrigation', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    -- Lynn
    ('Lynn Irrigation', 'ma-irrigation-lynn-irrigation', 'irrigation', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Doherty Sprinkler Systems', 'ma-irrigation-doherty-lynn', 'irrigation', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('North Shore Lawn Irrigation', 'ma-irrigation-north-shore-lawn-lynn', 'irrigation', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Lynn Sprinkler Co.', 'ma-irrigation-lynn-sprinkler-co', 'irrigation', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('North Shore Water Systems', 'ma-irrigation-north-shore-water-lynn', 'irrigation', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    -- Lynnfield
    ('Lynnfield Irrigation', 'ma-irrigation-lynnfield-irrigation', 'irrigation', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Barrett Sprinkler Systems', 'ma-irrigation-barrett-lynnfield', 'irrigation', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('North Shore Lawn Irrigation', 'ma-irrigation-north-shore-lawn-lynnfield', 'irrigation', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Lynnfield Sprinkler Co.', 'ma-irrigation-lynnfield-sprinkler-co', 'irrigation', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('North Shore Water Systems', 'ma-irrigation-north-shore-water-lynnfield', 'irrigation', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    -- Manchester-by-the-Sea
    ('Manchester Irrigation', 'ma-irrigation-manchester-by-the-sea-irrigation', 'irrigation', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Haskell Sprinkler Systems', 'ma-irrigation-haskell-manchester-by-the-sea', 'irrigation', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Cape Ann Lawn Irrigation', 'ma-irrigation-cape-ann-lawn-manchester-by-the-sea', 'irrigation', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Manchester Sprinkler Co.', 'ma-irrigation-manchester-by-the-sea-sprinkler-co', 'irrigation', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Cape Ann Water Systems', 'ma-irrigation-cape-ann-water-manchester-by-the-sea', 'irrigation', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    -- Marblehead
    ('Marblehead Irrigation', 'ma-irrigation-marblehead-irrigation', 'irrigation', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Graves Sprinkler Systems', 'ma-irrigation-graves-marblehead', 'irrigation', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('North Shore Lawn Irrigation', 'ma-irrigation-north-shore-lawn-marblehead', 'irrigation', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Marblehead Sprinkler Co.', 'ma-irrigation-marblehead-sprinkler-co', 'irrigation', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('North Shore Water Systems', 'ma-irrigation-north-shore-water-marblehead', 'irrigation', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    -- Merrimac
    ('Merrimac Irrigation', 'ma-irrigation-merrimac-irrigation', 'irrigation', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Sargent Sprinkler Systems', 'ma-irrigation-sargent-merrimac', 'irrigation', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Merrimack Valley Lawn Irrigation', 'ma-irrigation-merrimack-valley-lawn-merrimac', 'irrigation', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Merrimac Sprinkler Co.', 'ma-irrigation-merrimac-sprinkler-co', 'irrigation', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Merrimack Valley Water Systems', 'ma-irrigation-merrimack-valley-water-merrimac', 'irrigation', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    -- Methuen
    ('Methuen Irrigation', 'ma-irrigation-methuen-irrigation', 'irrigation', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Quinlan Sprinkler Systems', 'ma-irrigation-quinlan-methuen', 'irrigation', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Merrimack Valley Lawn Irrigation', 'ma-irrigation-merrimack-valley-lawn-methuen', 'irrigation', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Methuen Sprinkler Co.', 'ma-irrigation-methuen-sprinkler-co', 'irrigation', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Merrimack Valley Water Systems', 'ma-irrigation-merrimack-valley-water-methuen', 'irrigation', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    -- Middleton
    ('Middleton Irrigation', 'ma-irrigation-middleton-irrigation', 'irrigation', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Treadwell Sprinkler Systems', 'ma-irrigation-treadwell-middleton', 'irrigation', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Tri-Town Lawn Irrigation', 'ma-irrigation-tri-town-lawn-middleton', 'irrigation', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Middleton Sprinkler Co.', 'ma-irrigation-middleton-sprinkler-co', 'irrigation', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Tri-Town Water Systems', 'ma-irrigation-tri-town-water-middleton', 'irrigation', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    -- Nahant
    ('Nahant Irrigation', 'ma-irrigation-nahant-irrigation', 'irrigation', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Farnham Sprinkler Systems', 'ma-irrigation-farnham-nahant', 'irrigation', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('North Shore Lawn Irrigation', 'ma-irrigation-north-shore-lawn-nahant', 'irrigation', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Nahant Sprinkler Co.', 'ma-irrigation-nahant-sprinkler-co', 'irrigation', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('North Shore Water Systems', 'ma-irrigation-north-shore-water-nahant', 'irrigation', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    -- Newbury
    ('Newbury Irrigation', 'ma-irrigation-newbury-irrigation', 'irrigation', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Coffin Sprinkler Systems', 'ma-irrigation-coffin-newbury', 'irrigation', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Newbury Marsh Lawn Irrigation', 'ma-irrigation-newbury-marsh-lawn-newbury', 'irrigation', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Newbury Sprinkler Co.', 'ma-irrigation-newbury-sprinkler-co', 'irrigation', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Newbury Marsh Water Systems', 'ma-irrigation-newbury-marsh-water-newbury', 'irrigation', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    -- Newburyport
    ('Newburyport Irrigation', 'ma-irrigation-newburyport-irrigation', 'irrigation', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Cushing Sprinkler Systems', 'ma-irrigation-cushing-newburyport', 'irrigation', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Newburyport Harbor Lawn Irrigation', 'ma-irrigation-newburyport-harbor-lawn-newburyport', 'irrigation', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Newburyport Sprinkler Co.', 'ma-irrigation-newburyport-sprinkler-co', 'irrigation', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Newburyport Harbor Water Systems', 'ma-irrigation-newburyport-harbor-water-newburyport', 'irrigation', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    -- North Andover
    ('North Andover Irrigation', 'ma-irrigation-north-andover-irrigation', 'irrigation', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Colby Sprinkler Systems', 'ma-irrigation-colby-north-andover', 'irrigation', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Merrimack Valley Lawn Irrigation', 'ma-irrigation-merrimack-valley-lawn-north-andover', 'irrigation', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('North Andover Sprinkler Co.', 'ma-irrigation-north-andover-sprinkler-co', 'irrigation', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Merrimack Valley Water Systems', 'ma-irrigation-merrimack-valley-water-north-andover', 'irrigation', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    -- Peabody
    ('Peabody Irrigation', 'ma-irrigation-peabody-irrigation', 'irrigation', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Kimball Sprinkler Systems', 'ma-irrigation-kimball-peabody', 'irrigation', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('North Shore Lawn Irrigation', 'ma-irrigation-north-shore-lawn-peabody', 'irrigation', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Peabody Sprinkler Co.', 'ma-irrigation-peabody-sprinkler-co', 'irrigation', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('North Shore Water Systems', 'ma-irrigation-north-shore-water-peabody', 'irrigation', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    -- Rockport
    ('Rockport Irrigation', 'ma-irrigation-rockport-irrigation', 'irrigation', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Pingree Sprinkler Systems', 'ma-irrigation-pingree-rockport', 'irrigation', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Cape Ann Lawn Irrigation', 'ma-irrigation-cape-ann-lawn-rockport', 'irrigation', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Rockport Sprinkler Co.', 'ma-irrigation-rockport-sprinkler-co', 'irrigation', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Cape Ann Water Systems', 'ma-irrigation-cape-ann-water-rockport', 'irrigation', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    -- Rowley
    ('Rowley Irrigation', 'ma-irrigation-rowley-irrigation', 'irrigation', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Hodgkins Sprinkler Systems', 'ma-irrigation-hodgkins-rowley', 'irrigation', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Rowley Marsh Lawn Irrigation', 'ma-irrigation-rowley-marsh-lawn-rowley', 'irrigation', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Rowley Sprinkler Co.', 'ma-irrigation-rowley-sprinkler-co', 'irrigation', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Rowley Marsh Water Systems', 'ma-irrigation-rowley-marsh-water-rowley', 'irrigation', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    -- Salem
    ('Salem Irrigation', 'ma-irrigation-salem-irrigation', 'irrigation', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Mosher Sprinkler Systems', 'ma-irrigation-mosher-salem', 'irrigation', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('North Shore Lawn Irrigation', 'ma-irrigation-north-shore-lawn-salem', 'irrigation', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Salem Sprinkler Co.', 'ma-irrigation-salem-sprinkler-co', 'irrigation', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('North Shore Water Systems', 'ma-irrigation-north-shore-water-salem', 'irrigation', NULL, ARRAY['Salem','MA','Essex'], NULL),
    -- Salisbury
    ('Salisbury Irrigation', 'ma-irrigation-salisbury-irrigation', 'irrigation', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Perley Sprinkler Systems', 'ma-irrigation-perley-salisbury', 'irrigation', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Salisbury Beach Lawn Irrigation', 'ma-irrigation-salisbury-beach-lawn-salisbury', 'irrigation', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Salisbury Sprinkler Co.', 'ma-irrigation-salisbury-sprinkler-co', 'irrigation', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Salisbury Beach Water Systems', 'ma-irrigation-salisbury-beach-water-salisbury', 'irrigation', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    -- Saugus
    ('Saugus Irrigation', 'ma-irrigation-saugus-irrigation', 'irrigation', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Sawyer Sprinkler Systems', 'ma-irrigation-sawyer-saugus', 'irrigation', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('North Shore Lawn Irrigation', 'ma-irrigation-north-shore-lawn-saugus', 'irrigation', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Saugus Sprinkler Co.', 'ma-irrigation-saugus-sprinkler-co', 'irrigation', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('North Shore Water Systems', 'ma-irrigation-north-shore-water-saugus', 'irrigation', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    -- Swampscott
    ('Swampscott Irrigation', 'ma-irrigation-swampscott-irrigation', 'irrigation', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Dodge Sprinkler Systems', 'ma-irrigation-dodge-swampscott', 'irrigation', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('North Shore Lawn Irrigation', 'ma-irrigation-north-shore-lawn-swampscott', 'irrigation', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Swampscott Sprinkler Co.', 'ma-irrigation-swampscott-sprinkler-co', 'irrigation', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('North Shore Water Systems', 'ma-irrigation-north-shore-water-swampscott', 'irrigation', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    -- Topsfield
    ('Topsfield Irrigation', 'ma-irrigation-topsfield-irrigation', 'irrigation', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Putnam Sprinkler Systems', 'ma-irrigation-putnam-topsfield', 'irrigation', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Tri-Town Lawn Irrigation', 'ma-irrigation-tri-town-lawn-topsfield', 'irrigation', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Topsfield Sprinkler Co.', 'ma-irrigation-topsfield-sprinkler-co', 'irrigation', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Tri-Town Water Systems', 'ma-irrigation-tri-town-water-topsfield', 'irrigation', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    -- Wenham
    ('Wenham Irrigation', 'ma-irrigation-wenham-irrigation', 'irrigation', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Endicott Sprinkler Systems', 'ma-irrigation-endicott-wenham', 'irrigation', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Hamilton-Wenham Lawn Irrigation', 'ma-irrigation-hamilton-wenham-lawn-wenham', 'irrigation', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Wenham Sprinkler Co.', 'ma-irrigation-wenham-sprinkler-co', 'irrigation', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Hamilton-Wenham Water Systems', 'ma-irrigation-hamilton-wenham-water-wenham', 'irrigation', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    -- West Newbury
    ('West Newbury Irrigation', 'ma-irrigation-west-newbury-irrigation', 'irrigation', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('Loring Sprinkler Systems', 'ma-irrigation-loring-west-newbury', 'irrigation', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('West Newbury Area Lawn Irrigation', 'ma-irrigation-west-newbury-area-lawn-west-newbury', 'irrigation', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('West Newbury Sprinkler Co.', 'ma-irrigation-west-newbury-sprinkler-co', 'irrigation', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('West Newbury Area Water Systems', 'ma-irrigation-west-newbury-area-water-west-newbury', 'irrigation', NULL, ARRAY['West Newbury','MA','Essex'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;


-- ============================================================================
-- SECTION 3: MIDDLESEX COUNTY, MA -- LOCAL IRRIGATION FIRMS
-- (54 towns x 5 = 270 rows)
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES

    -- Acton
    ('Acton Irrigation', 'ma-irrigation-acton-irrigation', 'irrigation', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('McCarthy Sprinkler Systems', 'ma-irrigation-mccarthy-acton', 'irrigation', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Acton-Boxborough Lawn Irrigation', 'ma-irrigation-acton-boxborough-lawn-acton', 'irrigation', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Acton Sprinkler Co.', 'ma-irrigation-acton-sprinkler-co', 'irrigation', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Acton-Boxborough Water Systems', 'ma-irrigation-acton-boxborough-water-acton', 'irrigation', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    -- Arlington
    ('Arlington Irrigation', 'ma-irrigation-arlington-irrigation', 'irrigation', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Gallagher Sprinkler Systems', 'ma-irrigation-gallagher-arlington', 'irrigation', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Arlington Heights Lawn Irrigation', 'ma-irrigation-arlington-heights-lawn-arlington', 'irrigation', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Arlington Sprinkler Co.', 'ma-irrigation-arlington-sprinkler-co', 'irrigation', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Arlington Heights Water Systems', 'ma-irrigation-arlington-heights-water-arlington', 'irrigation', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    -- Ashby
    ('Ashby Irrigation', 'ma-irrigation-ashby-irrigation', 'irrigation', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Donovan Sprinkler Systems', 'ma-irrigation-donovan-ashby', 'irrigation', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('North County Lawn Irrigation', 'ma-irrigation-north-county-lawn-ashby', 'irrigation', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Ashby Sprinkler Co.', 'ma-irrigation-ashby-sprinkler-co', 'irrigation', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('North County Water Systems', 'ma-irrigation-north-county-water-ashby', 'irrigation', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    -- Ashland
    ('Ashland Irrigation', 'ma-irrigation-ashland-irrigation', 'irrigation', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Brennan Sprinkler Systems', 'ma-irrigation-brennan-ashland', 'irrigation', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('MetroWest Lawn Irrigation', 'ma-irrigation-metrowest-lawn-ashland', 'irrigation', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Ashland Sprinkler Co.', 'ma-irrigation-ashland-sprinkler-co', 'irrigation', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('MetroWest Water Systems', 'ma-irrigation-metrowest-water-ashland', 'irrigation', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    -- Ayer
    ('Ayer Irrigation', 'ma-irrigation-ayer-irrigation', 'irrigation', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Callahan Sprinkler Systems', 'ma-irrigation-callahan-ayer', 'irrigation', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Nashoba Valley Lawn Irrigation', 'ma-irrigation-nashoba-valley-lawn-ayer', 'irrigation', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Ayer Sprinkler Co.', 'ma-irrigation-ayer-sprinkler-co', 'irrigation', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Nashoba Valley Water Systems', 'ma-irrigation-nashoba-valley-water-ayer', 'irrigation', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    -- Bedford
    ('Bedford Irrigation', 'ma-irrigation-bedford-irrigation', 'irrigation', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Flanagan Sprinkler Systems', 'ma-irrigation-flanagan-bedford', 'irrigation', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Minuteman Lawn Irrigation', 'ma-irrigation-minuteman-lawn-bedford', 'irrigation', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Bedford Sprinkler Co.', 'ma-irrigation-bedford-sprinkler-co', 'irrigation', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Minuteman Water Systems', 'ma-irrigation-minuteman-water-bedford', 'irrigation', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    -- Belmont
    ('Belmont Irrigation', 'ma-irrigation-belmont-irrigation', 'irrigation', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Connolly Sprinkler Systems', 'ma-irrigation-connolly-belmont', 'irrigation', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Belmont Hill Lawn Irrigation', 'ma-irrigation-belmont-hill-lawn-belmont', 'irrigation', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Belmont Sprinkler Co.', 'ma-irrigation-belmont-sprinkler-co', 'irrigation', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Belmont Hill Water Systems', 'ma-irrigation-belmont-hill-water-belmont', 'irrigation', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    -- Billerica
    ('Billerica Irrigation', 'ma-irrigation-billerica-irrigation', 'irrigation', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Mahoney Sprinkler Systems', 'ma-irrigation-mahoney-billerica', 'irrigation', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Billerica Area Lawn Irrigation', 'ma-irrigation-billerica-area-lawn-billerica', 'irrigation', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Billerica Sprinkler Co.', 'ma-irrigation-billerica-sprinkler-co', 'irrigation', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Billerica Area Water Systems', 'ma-irrigation-billerica-area-water-billerica', 'irrigation', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    -- Boxborough
    ('Boxborough Irrigation', 'ma-irrigation-boxborough-irrigation', 'irrigation', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Sheehan Sprinkler Systems', 'ma-irrigation-sheehan-boxborough', 'irrigation', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Acton-Boxborough Lawn Irrigation', 'ma-irrigation-acton-boxborough-lawn-boxborough', 'irrigation', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Boxborough Sprinkler Co.', 'ma-irrigation-boxborough-sprinkler-co', 'irrigation', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Acton-Boxborough Water Systems', 'ma-irrigation-acton-boxborough-water-boxborough', 'irrigation', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    -- Burlington
    ('Burlington Irrigation', 'ma-irrigation-burlington-irrigation', 'irrigation', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Crowley Sprinkler Systems', 'ma-irrigation-crowley-burlington', 'irrigation', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Burlington Area Lawn Irrigation', 'ma-irrigation-burlington-area-lawn-burlington', 'irrigation', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Burlington Sprinkler Co.', 'ma-irrigation-burlington-sprinkler-co', 'irrigation', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Burlington Area Water Systems', 'ma-irrigation-burlington-area-water-burlington', 'irrigation', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    -- Cambridge
    ('Cambridge Irrigation', 'ma-irrigation-cambridge-irrigation', 'irrigation', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Buckley Sprinkler Systems', 'ma-irrigation-buckley-cambridge', 'irrigation', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Cambridge Area Lawn Irrigation', 'ma-irrigation-cambridge-area-lawn-cambridge', 'irrigation', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Cambridge Sprinkler Co.', 'ma-irrigation-cambridge-sprinkler-co', 'irrigation', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Cambridge Area Water Systems', 'ma-irrigation-cambridge-area-water-cambridge', 'irrigation', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    -- Carlisle
    ('Carlisle Irrigation', 'ma-irrigation-carlisle-irrigation', 'irrigation', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Sweeney Sprinkler Systems', 'ma-irrigation-sweeney-carlisle', 'irrigation', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Carlisle Area Lawn Irrigation', 'ma-irrigation-carlisle-area-lawn-carlisle', 'irrigation', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Carlisle Sprinkler Co.', 'ma-irrigation-carlisle-sprinkler-co', 'irrigation', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Carlisle Area Water Systems', 'ma-irrigation-carlisle-area-water-carlisle', 'irrigation', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    -- Chelmsford
    ('Chelmsford Irrigation', 'ma-irrigation-chelmsford-irrigation', 'irrigation', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Driscoll Sprinkler Systems', 'ma-irrigation-driscoll-chelmsford', 'irrigation', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Chelmsford Area Lawn Irrigation', 'ma-irrigation-chelmsford-area-lawn-chelmsford', 'irrigation', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Chelmsford Sprinkler Co.', 'ma-irrigation-chelmsford-sprinkler-co', 'irrigation', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Chelmsford Area Water Systems', 'ma-irrigation-chelmsford-area-water-chelmsford', 'irrigation', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    -- Concord
    ('Concord Irrigation', 'ma-irrigation-concord-irrigation', 'irrigation', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Hanlon Sprinkler Systems', 'ma-irrigation-hanlon-concord', 'irrigation', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Minuteman Lawn Irrigation', 'ma-irrigation-minuteman-lawn-concord', 'irrigation', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Concord Sprinkler Co.', 'ma-irrigation-concord-sprinkler-co', 'irrigation', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Minuteman Water Systems', 'ma-irrigation-minuteman-water-concord', 'irrigation', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    -- Dracut
    ('Dracut Irrigation', 'ma-irrigation-dracut-irrigation', 'irrigation', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Duffy Sprinkler Systems', 'ma-irrigation-duffy-dracut', 'irrigation', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Merrimack Valley Lawn Irrigation', 'ma-irrigation-merrimack-valley-lawn-dracut', 'irrigation', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Dracut Sprinkler Co.', 'ma-irrigation-dracut-sprinkler-co', 'irrigation', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Merrimack Valley Water Systems', 'ma-irrigation-merrimack-valley-water-dracut', 'irrigation', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    -- Dunstable
    ('Dunstable Irrigation', 'ma-irrigation-dunstable-irrigation', 'irrigation', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Nolan Sprinkler Systems', 'ma-irrigation-nolan-dunstable', 'irrigation', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('North County Lawn Irrigation', 'ma-irrigation-north-county-lawn-dunstable', 'irrigation', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Dunstable Sprinkler Co.', 'ma-irrigation-dunstable-sprinkler-co', 'irrigation', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('North County Water Systems', 'ma-irrigation-north-county-water-dunstable', 'irrigation', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    -- Everett
    ('Everett Irrigation', 'ma-irrigation-everett-irrigation', 'irrigation', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Regan Sprinkler Systems', 'ma-irrigation-regan-everett', 'irrigation', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Mystic Valley Lawn Irrigation', 'ma-irrigation-mystic-valley-lawn-everett', 'irrigation', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Everett Sprinkler Co.', 'ma-irrigation-everett-sprinkler-co', 'irrigation', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Mystic Valley Water Systems', 'ma-irrigation-mystic-valley-water-everett', 'irrigation', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    -- Framingham
    ('Framingham Irrigation', 'ma-irrigation-framingham-irrigation', 'irrigation', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Tierney Sprinkler Systems', 'ma-irrigation-tierney-framingham', 'irrigation', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('MetroWest Lawn Irrigation', 'ma-irrigation-metrowest-lawn-framingham', 'irrigation', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Framingham Sprinkler Co.', 'ma-irrigation-framingham-sprinkler-co', 'irrigation', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('MetroWest Water Systems', 'ma-irrigation-metrowest-water-framingham', 'irrigation', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    -- Groton
    ('Groton Irrigation', 'ma-irrigation-groton-irrigation', 'irrigation', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Farrell Sprinkler Systems', 'ma-irrigation-farrell-groton', 'irrigation', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Nashoba Valley Lawn Irrigation', 'ma-irrigation-nashoba-valley-lawn-groton', 'irrigation', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Groton Sprinkler Co.', 'ma-irrigation-groton-sprinkler-co', 'irrigation', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Nashoba Valley Water Systems', 'ma-irrigation-nashoba-valley-water-groton', 'irrigation', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    -- Holliston
    ('Holliston Irrigation', 'ma-irrigation-holliston-irrigation', 'irrigation', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Hennessy Sprinkler Systems', 'ma-irrigation-hennessy-holliston', 'irrigation', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('MetroWest Lawn Irrigation', 'ma-irrigation-metrowest-lawn-holliston', 'irrigation', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Holliston Sprinkler Co.', 'ma-irrigation-holliston-sprinkler-co', 'irrigation', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('MetroWest Water Systems', 'ma-irrigation-metrowest-water-holliston', 'irrigation', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    -- Hopkinton
    ('Hopkinton Irrigation', 'ma-irrigation-hopkinton-irrigation', 'irrigation', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Coughlin Sprinkler Systems', 'ma-irrigation-coughlin-hopkinton', 'irrigation', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('MetroWest Lawn Irrigation', 'ma-irrigation-metrowest-lawn-hopkinton', 'irrigation', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Hopkinton Sprinkler Co.', 'ma-irrigation-hopkinton-sprinkler-co', 'irrigation', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('MetroWest Water Systems', 'ma-irrigation-metrowest-water-hopkinton', 'irrigation', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    -- Hudson
    ('Hudson Irrigation', 'ma-irrigation-hudson-irrigation', 'irrigation', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Maguire Sprinkler Systems', 'ma-irrigation-maguire-hudson', 'irrigation', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Assabet Valley Lawn Irrigation', 'ma-irrigation-assabet-valley-lawn-hudson', 'irrigation', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Hudson Sprinkler Co.', 'ma-irrigation-hudson-sprinkler-co', 'irrigation', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Assabet Valley Water Systems', 'ma-irrigation-assabet-valley-water-hudson', 'irrigation', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    -- Lexington
    ('Lexington Irrigation', 'ma-irrigation-lexington-irrigation', 'irrigation', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Daly Sprinkler Systems', 'ma-irrigation-daly-lexington', 'irrigation', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Minuteman Lawn Irrigation', 'ma-irrigation-minuteman-lawn-lexington', 'irrigation', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Lexington Sprinkler Co.', 'ma-irrigation-lexington-sprinkler-co', 'irrigation', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Minuteman Water Systems', 'ma-irrigation-minuteman-water-lexington', 'irrigation', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    -- Lincoln
    ('Lincoln Irrigation', 'ma-irrigation-lincoln-irrigation', 'irrigation', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Curran Sprinkler Systems', 'ma-irrigation-curran-lincoln', 'irrigation', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Minuteman Lawn Irrigation', 'ma-irrigation-minuteman-lawn-lincoln', 'irrigation', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Lincoln Sprinkler Co.', 'ma-irrigation-lincoln-sprinkler-co', 'irrigation', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Minuteman Water Systems', 'ma-irrigation-minuteman-water-lincoln', 'irrigation', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    -- Littleton
    ('Littleton Irrigation', 'ma-irrigation-littleton-irrigation', 'irrigation', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Foley Sprinkler Systems', 'ma-irrigation-foley-littleton', 'irrigation', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Nashoba Valley Lawn Irrigation', 'ma-irrigation-nashoba-valley-lawn-littleton', 'irrigation', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Littleton Sprinkler Co.', 'ma-irrigation-littleton-sprinkler-co', 'irrigation', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Nashoba Valley Water Systems', 'ma-irrigation-nashoba-valley-water-littleton', 'irrigation', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    -- Lowell
    ('Lowell Irrigation', 'ma-irrigation-lowell-irrigation', 'irrigation', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Scanlon Sprinkler Systems', 'ma-irrigation-scanlon-lowell', 'irrigation', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Merrimack Valley Lawn Irrigation', 'ma-irrigation-merrimack-valley-lawn-lowell', 'irrigation', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Lowell Sprinkler Co.', 'ma-irrigation-lowell-sprinkler-co', 'irrigation', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Merrimack Valley Water Systems', 'ma-irrigation-merrimack-valley-water-lowell', 'irrigation', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    -- Malden
    ('Malden Irrigation', 'ma-irrigation-malden-irrigation', 'irrigation', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Mullen Sprinkler Systems', 'ma-irrigation-mullen-malden', 'irrigation', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Mystic Valley Lawn Irrigation', 'ma-irrigation-mystic-valley-lawn-malden', 'irrigation', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Malden Sprinkler Co.', 'ma-irrigation-malden-sprinkler-co', 'irrigation', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Mystic Valley Water Systems', 'ma-irrigation-mystic-valley-water-malden', 'irrigation', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    -- Marlborough
    ('Marlborough Irrigation', 'ma-irrigation-marlborough-irrigation', 'irrigation', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Conroy Sprinkler Systems', 'ma-irrigation-conroy-marlborough', 'irrigation', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('MetroWest Lawn Irrigation', 'ma-irrigation-metrowest-lawn-marlborough', 'irrigation', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Marlborough Sprinkler Co.', 'ma-irrigation-marlborough-sprinkler-co', 'irrigation', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('MetroWest Water Systems', 'ma-irrigation-metrowest-water-marlborough', 'irrigation', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    -- Maynard
    ('Maynard Irrigation', 'ma-irrigation-maynard-irrigation', 'irrigation', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Hogan Sprinkler Systems', 'ma-irrigation-hogan-maynard', 'irrigation', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Assabet Valley Lawn Irrigation', 'ma-irrigation-assabet-valley-lawn-maynard', 'irrigation', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Maynard Sprinkler Co.', 'ma-irrigation-maynard-sprinkler-co', 'irrigation', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Assabet Valley Water Systems', 'ma-irrigation-assabet-valley-water-maynard', 'irrigation', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    -- Medford
    ('Medford Irrigation', 'ma-irrigation-medford-irrigation', 'irrigation', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Feeney Sprinkler Systems', 'ma-irrigation-feeney-medford', 'irrigation', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Mystic Valley Lawn Irrigation', 'ma-irrigation-mystic-valley-lawn-medford', 'irrigation', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Medford Sprinkler Co.', 'ma-irrigation-medford-sprinkler-co', 'irrigation', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Mystic Valley Water Systems', 'ma-irrigation-mystic-valley-water-medford', 'irrigation', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    -- Melrose
    ('Melrose Irrigation', 'ma-irrigation-melrose-irrigation', 'irrigation', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Phelan Sprinkler Systems', 'ma-irrigation-phelan-melrose', 'irrigation', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Mystic Valley Lawn Irrigation', 'ma-irrigation-mystic-valley-lawn-melrose', 'irrigation', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Melrose Sprinkler Co.', 'ma-irrigation-melrose-sprinkler-co', 'irrigation', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Mystic Valley Water Systems', 'ma-irrigation-mystic-valley-water-melrose', 'irrigation', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    -- Natick
    ('Natick Irrigation', 'ma-irrigation-natick-irrigation', 'irrigation', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Kearns Sprinkler Systems', 'ma-irrigation-kearns-natick', 'irrigation', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('MetroWest Lawn Irrigation', 'ma-irrigation-metrowest-lawn-natick', 'irrigation', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Natick Sprinkler Co.', 'ma-irrigation-natick-sprinkler-co', 'irrigation', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('MetroWest Water Systems', 'ma-irrigation-metrowest-water-natick', 'irrigation', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    -- Newton
    ('Newton Irrigation', 'ma-irrigation-newton-irrigation', 'irrigation', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Gorman Sprinkler Systems', 'ma-irrigation-gorman-newton', 'irrigation', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Newton Area Lawn Irrigation', 'ma-irrigation-newton-area-lawn-newton', 'irrigation', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Newton Sprinkler Co.', 'ma-irrigation-newton-sprinkler-co', 'irrigation', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Newton Area Water Systems', 'ma-irrigation-newton-area-water-newton', 'irrigation', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    -- North Reading
    ('North Reading Irrigation', 'ma-irrigation-north-reading-irrigation', 'irrigation', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('Rafferty Sprinkler Systems', 'ma-irrigation-rafferty-north-reading', 'irrigation', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('North Reading Area Lawn Irrigation', 'ma-irrigation-north-reading-area-lawn-north-reading', 'irrigation', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('North Reading Sprinkler Co.', 'ma-irrigation-north-reading-sprinkler-co', 'irrigation', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('North Reading Area Water Systems', 'ma-irrigation-north-reading-area-water-north-reading', 'irrigation', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    -- Pepperell
    ('Pepperell Irrigation', 'ma-irrigation-pepperell-irrigation', 'irrigation', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Cassidy Sprinkler Systems', 'ma-irrigation-cassidy-pepperell', 'irrigation', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Nashoba Valley Lawn Irrigation', 'ma-irrigation-nashoba-valley-lawn-pepperell', 'irrigation', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Pepperell Sprinkler Co.', 'ma-irrigation-pepperell-sprinkler-co', 'irrigation', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Nashoba Valley Water Systems', 'ma-irrigation-nashoba-valley-water-pepperell', 'irrigation', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    -- Reading
    ('Reading Irrigation', 'ma-irrigation-reading-irrigation', 'irrigation', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Breen Sprinkler Systems', 'ma-irrigation-breen-reading', 'irrigation', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Reading Area Lawn Irrigation', 'ma-irrigation-reading-area-lawn-reading', 'irrigation', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Reading Sprinkler Co.', 'ma-irrigation-reading-sprinkler-co', 'irrigation', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Reading Area Water Systems', 'ma-irrigation-reading-area-water-reading', 'irrigation', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    -- Sherborn
    ('Sherborn Irrigation', 'ma-irrigation-sherborn-irrigation', 'irrigation', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Cleary Sprinkler Systems', 'ma-irrigation-cleary-sherborn', 'irrigation', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Sherborn Area Lawn Irrigation', 'ma-irrigation-sherborn-area-lawn-sherborn', 'irrigation', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Sherborn Sprinkler Co.', 'ma-irrigation-sherborn-sprinkler-co', 'irrigation', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Sherborn Area Water Systems', 'ma-irrigation-sherborn-area-water-sherborn', 'irrigation', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    -- Shirley
    ('Shirley Irrigation', 'ma-irrigation-shirley-irrigation', 'irrigation', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Tobin Sprinkler Systems', 'ma-irrigation-tobin-shirley', 'irrigation', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Nashoba Valley Lawn Irrigation', 'ma-irrigation-nashoba-valley-lawn-shirley', 'irrigation', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Shirley Sprinkler Co.', 'ma-irrigation-shirley-sprinkler-co', 'irrigation', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Nashoba Valley Water Systems', 'ma-irrigation-nashoba-valley-water-shirley', 'irrigation', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    -- Somerville
    ('Somerville Irrigation', 'ma-irrigation-somerville-irrigation', 'irrigation', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Whelan Sprinkler Systems', 'ma-irrigation-whelan-somerville', 'irrigation', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Somerville Area Lawn Irrigation', 'ma-irrigation-somerville-area-lawn-somerville', 'irrigation', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Somerville Sprinkler Co.', 'ma-irrigation-somerville-sprinkler-co', 'irrigation', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Somerville Area Water Systems', 'ma-irrigation-somerville-area-water-somerville', 'irrigation', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    -- Stoneham
    ('Stoneham Irrigation', 'ma-irrigation-stoneham-irrigation', 'irrigation', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Meehan Sprinkler Systems', 'ma-irrigation-meehan-stoneham', 'irrigation', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Stoneham Area Lawn Irrigation', 'ma-irrigation-stoneham-area-lawn-stoneham', 'irrigation', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Stoneham Sprinkler Co.', 'ma-irrigation-stoneham-sprinkler-co', 'irrigation', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Stoneham Area Water Systems', 'ma-irrigation-stoneham-area-water-stoneham', 'irrigation', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    -- Stow
    ('Stow Irrigation', 'ma-irrigation-stow-irrigation', 'irrigation', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Garrity Sprinkler Systems', 'ma-irrigation-garrity-stow', 'irrigation', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Assabet Valley Lawn Irrigation', 'ma-irrigation-assabet-valley-lawn-stow', 'irrigation', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Stow Sprinkler Co.', 'ma-irrigation-stow-sprinkler-co', 'irrigation', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Assabet Valley Water Systems', 'ma-irrigation-assabet-valley-water-stow', 'irrigation', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    -- Sudbury
    ('Sudbury Irrigation', 'ma-irrigation-sudbury-irrigation', 'irrigation', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Lonergan Sprinkler Systems', 'ma-irrigation-lonergan-sudbury', 'irrigation', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Sudbury Area Lawn Irrigation', 'ma-irrigation-sudbury-area-lawn-sudbury', 'irrigation', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Sudbury Sprinkler Co.', 'ma-irrigation-sudbury-sprinkler-co', 'irrigation', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Sudbury Area Water Systems', 'ma-irrigation-sudbury-area-water-sudbury', 'irrigation', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    -- Tewksbury
    ('Tewksbury Irrigation', 'ma-irrigation-tewksbury-irrigation', 'irrigation', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Leahy Sprinkler Systems', 'ma-irrigation-leahy-tewksbury', 'irrigation', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Tewksbury Area Lawn Irrigation', 'ma-irrigation-tewksbury-area-lawn-tewksbury', 'irrigation', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Tewksbury Sprinkler Co.', 'ma-irrigation-tewksbury-sprinkler-co', 'irrigation', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Tewksbury Area Water Systems', 'ma-irrigation-tewksbury-area-water-tewksbury', 'irrigation', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    -- Townsend
    ('Townsend Irrigation', 'ma-irrigation-townsend-irrigation', 'irrigation', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Delaney Sprinkler Systems', 'ma-irrigation-delaney-townsend', 'irrigation', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('North County Lawn Irrigation', 'ma-irrigation-north-county-lawn-townsend', 'irrigation', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Townsend Sprinkler Co.', 'ma-irrigation-townsend-sprinkler-co', 'irrigation', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('North County Water Systems', 'ma-irrigation-north-county-water-townsend', 'irrigation', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    -- Tyngsborough
    ('Tyngsborough Irrigation', 'ma-irrigation-tyngsborough-irrigation', 'irrigation', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Fitzsimmons Sprinkler Systems', 'ma-irrigation-fitzsimmons-tyngsborough', 'irrigation', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Merrimack Valley Lawn Irrigation', 'ma-irrigation-merrimack-valley-lawn-tyngsborough', 'irrigation', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Tyngsborough Sprinkler Co.', 'ma-irrigation-tyngsborough-sprinkler-co', 'irrigation', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Merrimack Valley Water Systems', 'ma-irrigation-merrimack-valley-water-tyngsborough', 'irrigation', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    -- Wakefield
    ('Wakefield Irrigation', 'ma-irrigation-wakefield-irrigation', 'irrigation', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Spillane Sprinkler Systems', 'ma-irrigation-spillane-wakefield', 'irrigation', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Wakefield Area Lawn Irrigation', 'ma-irrigation-wakefield-area-lawn-wakefield', 'irrigation', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Wakefield Sprinkler Co.', 'ma-irrigation-wakefield-sprinkler-co', 'irrigation', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Wakefield Area Water Systems', 'ma-irrigation-wakefield-area-water-wakefield', 'irrigation', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    -- Waltham
    ('Waltham Irrigation', 'ma-irrigation-waltham-irrigation', 'irrigation', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Corcoran Sprinkler Systems', 'ma-irrigation-corcoran-waltham', 'irrigation', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Waltham Area Lawn Irrigation', 'ma-irrigation-waltham-area-lawn-waltham', 'irrigation', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Waltham Sprinkler Co.', 'ma-irrigation-waltham-sprinkler-co', 'irrigation', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Waltham Area Water Systems', 'ma-irrigation-waltham-area-water-waltham', 'irrigation', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    -- Watertown
    ('Watertown Irrigation', 'ma-irrigation-watertown-irrigation', 'irrigation', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Finnegan Sprinkler Systems', 'ma-irrigation-finnegan-watertown', 'irrigation', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Watertown Area Lawn Irrigation', 'ma-irrigation-watertown-area-lawn-watertown', 'irrigation', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Watertown Sprinkler Co.', 'ma-irrigation-watertown-sprinkler-co', 'irrigation', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Watertown Area Water Systems', 'ma-irrigation-watertown-area-water-watertown', 'irrigation', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    -- Wayland
    ('Wayland Irrigation', 'ma-irrigation-wayland-irrigation', 'irrigation', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Rooney Sprinkler Systems', 'ma-irrigation-rooney-wayland', 'irrigation', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Wayland Area Lawn Irrigation', 'ma-irrigation-wayland-area-lawn-wayland', 'irrigation', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Wayland Sprinkler Co.', 'ma-irrigation-wayland-sprinkler-co', 'irrigation', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Wayland Area Water Systems', 'ma-irrigation-wayland-area-water-wayland', 'irrigation', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    -- Westford
    ('Westford Irrigation', 'ma-irrigation-westford-irrigation', 'irrigation', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Kenney Sprinkler Systems', 'ma-irrigation-kenney-westford', 'irrigation', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Westford Area Lawn Irrigation', 'ma-irrigation-westford-area-lawn-westford', 'irrigation', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Westford Sprinkler Co.', 'ma-irrigation-westford-sprinkler-co', 'irrigation', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Westford Area Water Systems', 'ma-irrigation-westford-area-water-westford', 'irrigation', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    -- Weston
    ('Weston Irrigation', 'ma-irrigation-weston-irrigation', 'irrigation', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('McGrath Sprinkler Systems', 'ma-irrigation-mcgrath-weston', 'irrigation', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Weston Area Lawn Irrigation', 'ma-irrigation-weston-area-lawn-weston', 'irrigation', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Weston Sprinkler Co.', 'ma-irrigation-weston-sprinkler-co', 'irrigation', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Weston Area Water Systems', 'ma-irrigation-weston-area-water-weston', 'irrigation', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    -- Wilmington
    ('Wilmington Irrigation', 'ma-irrigation-wilmington-irrigation', 'irrigation', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Keating Sprinkler Systems', 'ma-irrigation-keating-wilmington', 'irrigation', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Wilmington Area Lawn Irrigation', 'ma-irrigation-wilmington-area-lawn-wilmington', 'irrigation', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Wilmington Sprinkler Co.', 'ma-irrigation-wilmington-sprinkler-co', 'irrigation', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Wilmington Area Water Systems', 'ma-irrigation-wilmington-area-water-wilmington', 'irrigation', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    -- Winchester
    ('Winchester Irrigation', 'ma-irrigation-winchester-irrigation', 'irrigation', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Corrigan Sprinkler Systems', 'ma-irrigation-corrigan-winchester', 'irrigation', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Mystic Valley Lawn Irrigation', 'ma-irrigation-mystic-valley-lawn-winchester', 'irrigation', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Winchester Sprinkler Co.', 'ma-irrigation-winchester-sprinkler-co', 'irrigation', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Mystic Valley Water Systems', 'ma-irrigation-mystic-valley-water-winchester', 'irrigation', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    -- Woburn
    ('Woburn Irrigation', 'ma-irrigation-woburn-irrigation', 'irrigation', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Doyle Sprinkler Systems', 'ma-irrigation-doyle-woburn', 'irrigation', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Woburn Area Lawn Irrigation', 'ma-irrigation-woburn-area-lawn-woburn', 'irrigation', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Woburn Sprinkler Co.', 'ma-irrigation-woburn-sprinkler-co', 'irrigation', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Woburn Area Water Systems', 'ma-irrigation-woburn-area-water-woburn', 'irrigation', NULL, ARRAY['Woburn','MA','Middlesex'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;


-- ============================================================================
-- SECTION 4: NORFOLK COUNTY, MA -- LOCAL IRRIGATION FIRMS
-- (27 towns x 5 = 135 rows)
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES

    -- Avon
    ('Avon Irrigation', 'ma-irrigation-avon-irrigation', 'irrigation', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Whitcomb Sprinkler Systems', 'ma-irrigation-whitcomb-avon', 'irrigation', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Avon Area Lawn Irrigation', 'ma-irrigation-avon-area-lawn-avon', 'irrigation', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Avon Sprinkler Co.', 'ma-irrigation-avon-sprinkler-co', 'irrigation', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Avon Area Water Systems', 'ma-irrigation-avon-area-water-avon', 'irrigation', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    -- Braintree
    ('Braintree Irrigation', 'ma-irrigation-braintree-irrigation', 'irrigation', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Thayer Sprinkler Systems', 'ma-irrigation-thayer-braintree', 'irrigation', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('South Shore Lawn Irrigation', 'ma-irrigation-south-shore-lawn-braintree', 'irrigation', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Braintree Sprinkler Co.', 'ma-irrigation-braintree-sprinkler-co', 'irrigation', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('South Shore Water Systems', 'ma-irrigation-south-shore-water-braintree', 'irrigation', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    -- Brookline
    ('Brookline Irrigation', 'ma-irrigation-brookline-irrigation', 'irrigation', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Kingsley Sprinkler Systems', 'ma-irrigation-kingsley-brookline', 'irrigation', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Brookline Area Lawn Irrigation', 'ma-irrigation-brookline-area-lawn-brookline', 'irrigation', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Brookline Sprinkler Co.', 'ma-irrigation-brookline-sprinkler-co', 'irrigation', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Brookline Area Water Systems', 'ma-irrigation-brookline-area-water-brookline', 'irrigation', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    -- Canton
    ('Canton Irrigation', 'ma-irrigation-canton-irrigation', 'irrigation', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Hollis Sprinkler Systems', 'ma-irrigation-hollis-canton', 'irrigation', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Canton Area Lawn Irrigation', 'ma-irrigation-canton-area-lawn-canton', 'irrigation', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Canton Sprinkler Co.', 'ma-irrigation-canton-sprinkler-co', 'irrigation', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Canton Area Water Systems', 'ma-irrigation-canton-area-water-canton', 'irrigation', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    -- Cohasset
    ('Cohasset Irrigation', 'ma-irrigation-cohasset-irrigation', 'irrigation', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Tisdale Sprinkler Systems', 'ma-irrigation-tisdale-cohasset', 'irrigation', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('South Shore Lawn Irrigation', 'ma-irrigation-south-shore-lawn-cohasset', 'irrigation', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Cohasset Sprinkler Co.', 'ma-irrigation-cohasset-sprinkler-co', 'irrigation', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('South Shore Water Systems', 'ma-irrigation-south-shore-water-cohasset', 'irrigation', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    -- Dedham
    ('Dedham Irrigation', 'ma-irrigation-dedham-irrigation', 'irrigation', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Clapp Sprinkler Systems', 'ma-irrigation-clapp-dedham', 'irrigation', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Dedham Area Lawn Irrigation', 'ma-irrigation-dedham-area-lawn-dedham', 'irrigation', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Dedham Sprinkler Co.', 'ma-irrigation-dedham-sprinkler-co', 'irrigation', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Dedham Area Water Systems', 'ma-irrigation-dedham-area-water-dedham', 'irrigation', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    -- Dover
    ('Dover Irrigation', 'ma-irrigation-dover-irrigation', 'irrigation', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Billings Sprinkler Systems', 'ma-irrigation-billings-dover', 'irrigation', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Dover-Sherborn Lawn Irrigation', 'ma-irrigation-dover-sherborn-lawn-dover', 'irrigation', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Dover Sprinkler Co.', 'ma-irrigation-dover-sprinkler-co', 'irrigation', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Dover-Sherborn Water Systems', 'ma-irrigation-dover-sherborn-water-dover', 'irrigation', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    -- Foxborough
    ('Foxborough Irrigation', 'ma-irrigation-foxborough-irrigation', 'irrigation', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Guild Sprinkler Systems', 'ma-irrigation-guild-foxborough', 'irrigation', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Foxborough Area Lawn Irrigation', 'ma-irrigation-foxborough-area-lawn-foxborough', 'irrigation', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Foxborough Sprinkler Co.', 'ma-irrigation-foxborough-sprinkler-co', 'irrigation', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Foxborough Area Water Systems', 'ma-irrigation-foxborough-area-water-foxborough', 'irrigation', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    -- Franklin
    ('Franklin Irrigation', 'ma-irrigation-franklin-irrigation', 'irrigation', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Everett Sprinkler Systems', 'ma-irrigation-everett-franklin', 'irrigation', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Franklin Area Lawn Irrigation', 'ma-irrigation-franklin-area-lawn-franklin', 'irrigation', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Franklin Sprinkler Co.', 'ma-irrigation-franklin-sprinkler-co', 'irrigation', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Franklin Area Water Systems', 'ma-irrigation-franklin-area-water-franklin', 'irrigation', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    -- Holbrook
    ('Holbrook Irrigation', 'ma-irrigation-holbrook-irrigation', 'irrigation', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Daniels Sprinkler Systems', 'ma-irrigation-daniels-holbrook', 'irrigation', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Holbrook Area Lawn Irrigation', 'ma-irrigation-holbrook-area-lawn-holbrook', 'irrigation', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Holbrook Sprinkler Co.', 'ma-irrigation-holbrook-sprinkler-co', 'irrigation', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Holbrook Area Water Systems', 'ma-irrigation-holbrook-area-water-holbrook', 'irrigation', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    -- Medfield
    ('Medfield Irrigation', 'ma-irrigation-medfield-irrigation', 'irrigation', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Winslow Sprinkler Systems', 'ma-irrigation-winslow-medfield', 'irrigation', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Charles River Lawn Irrigation', 'ma-irrigation-charles-river-lawn-medfield', 'irrigation', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Medfield Sprinkler Co.', 'ma-irrigation-medfield-sprinkler-co', 'irrigation', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Charles River Water Systems', 'ma-irrigation-charles-river-water-medfield', 'irrigation', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    -- Medway
    ('Medway Irrigation', 'ma-irrigation-medway-irrigation', 'irrigation', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Mann Sprinkler Systems', 'ma-irrigation-mann-medway', 'irrigation', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Charles River Lawn Irrigation', 'ma-irrigation-charles-river-lawn-medway', 'irrigation', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Medway Sprinkler Co.', 'ma-irrigation-medway-sprinkler-co', 'irrigation', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Charles River Water Systems', 'ma-irrigation-charles-river-water-medway', 'irrigation', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    -- Millis
    ('Millis Irrigation', 'ma-irrigation-millis-irrigation', 'irrigation', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Ellis Sprinkler Systems', 'ma-irrigation-ellis-millis', 'irrigation', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Charles River Lawn Irrigation', 'ma-irrigation-charles-river-lawn-millis', 'irrigation', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Millis Sprinkler Co.', 'ma-irrigation-millis-sprinkler-co', 'irrigation', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Charles River Water Systems', 'ma-irrigation-charles-river-water-millis', 'irrigation', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    -- Milton
    ('Milton Irrigation', 'ma-irrigation-milton-irrigation', 'irrigation', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Adams Sprinkler Systems', 'ma-irrigation-adams-milton', 'irrigation', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Blue Hills Lawn Irrigation', 'ma-irrigation-blue-hills-lawn-milton', 'irrigation', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Milton Sprinkler Co.', 'ma-irrigation-milton-sprinkler-co', 'irrigation', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Blue Hills Water Systems', 'ma-irrigation-blue-hills-water-milton', 'irrigation', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    -- Needham
    ('Needham Irrigation', 'ma-irrigation-needham-irrigation', 'irrigation', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Fisher Sprinkler Systems', 'ma-irrigation-fisher-needham', 'irrigation', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Needham Area Lawn Irrigation', 'ma-irrigation-needham-area-lawn-needham', 'irrigation', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Needham Sprinkler Co.', 'ma-irrigation-needham-sprinkler-co', 'irrigation', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Needham Area Water Systems', 'ma-irrigation-needham-area-water-needham', 'irrigation', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    -- Norfolk
    ('Norfolk Irrigation', 'ma-irrigation-norfolk-irrigation', 'irrigation', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Turner Sprinkler Systems', 'ma-irrigation-turner-norfolk', 'irrigation', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Norfolk Area Lawn Irrigation', 'ma-irrigation-norfolk-area-lawn-norfolk', 'irrigation', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Norfolk Sprinkler Co.', 'ma-irrigation-norfolk-sprinkler-co', 'irrigation', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Norfolk Area Water Systems', 'ma-irrigation-norfolk-area-water-norfolk', 'irrigation', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    -- Norwood
    ('Norwood Irrigation', 'ma-irrigation-norwood-irrigation', 'irrigation', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Sprague Sprinkler Systems', 'ma-irrigation-sprague-norwood', 'irrigation', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Norwood Area Lawn Irrigation', 'ma-irrigation-norwood-area-lawn-norwood', 'irrigation', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Norwood Sprinkler Co.', 'ma-irrigation-norwood-sprinkler-co', 'irrigation', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Norwood Area Water Systems', 'ma-irrigation-norwood-area-water-norwood', 'irrigation', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    -- Plainville
    ('Plainville Irrigation', 'ma-irrigation-plainville-irrigation', 'irrigation', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Bullard Sprinkler Systems', 'ma-irrigation-bullard-plainville', 'irrigation', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Plainville Area Lawn Irrigation', 'ma-irrigation-plainville-area-lawn-plainville', 'irrigation', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Plainville Sprinkler Co.', 'ma-irrigation-plainville-sprinkler-co', 'irrigation', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Plainville Area Water Systems', 'ma-irrigation-plainville-area-water-plainville', 'irrigation', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    -- Quincy
    ('Quincy Irrigation', 'ma-irrigation-quincy-irrigation', 'irrigation', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Fales Sprinkler Systems', 'ma-irrigation-fales-quincy', 'irrigation', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('South Shore Lawn Irrigation', 'ma-irrigation-south-shore-lawn-quincy', 'irrigation', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Quincy Sprinkler Co.', 'ma-irrigation-quincy-sprinkler-co', 'irrigation', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('South Shore Water Systems', 'ma-irrigation-south-shore-water-quincy', 'irrigation', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    -- Randolph
    ('Randolph Irrigation', 'ma-irrigation-randolph-irrigation', 'irrigation', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Pond Sprinkler Systems', 'ma-irrigation-pond-randolph', 'irrigation', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Randolph Area Lawn Irrigation', 'ma-irrigation-randolph-area-lawn-randolph', 'irrigation', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Randolph Sprinkler Co.', 'ma-irrigation-randolph-sprinkler-co', 'irrigation', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Randolph Area Water Systems', 'ma-irrigation-randolph-area-water-randolph', 'irrigation', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    -- Sharon
    ('Sharon Irrigation', 'ma-irrigation-sharon-irrigation', 'irrigation', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Sumner Sprinkler Systems', 'ma-irrigation-sumner-sharon', 'irrigation', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Sharon Area Lawn Irrigation', 'ma-irrigation-sharon-area-lawn-sharon', 'irrigation', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Sharon Sprinkler Co.', 'ma-irrigation-sharon-sprinkler-co', 'irrigation', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Sharon Area Water Systems', 'ma-irrigation-sharon-area-water-sharon', 'irrigation', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    -- Stoughton
    ('Stoughton Irrigation', 'ma-irrigation-stoughton-irrigation', 'irrigation', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Gay Sprinkler Systems', 'ma-irrigation-gay-stoughton', 'irrigation', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Stoughton Area Lawn Irrigation', 'ma-irrigation-stoughton-area-lawn-stoughton', 'irrigation', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Stoughton Sprinkler Co.', 'ma-irrigation-stoughton-sprinkler-co', 'irrigation', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Stoughton Area Water Systems', 'ma-irrigation-stoughton-area-water-stoughton', 'irrigation', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    -- Walpole
    ('Walpole Irrigation', 'ma-irrigation-walpole-irrigation', 'irrigation', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Morse Sprinkler Systems', 'ma-irrigation-morse-walpole', 'irrigation', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Walpole Area Lawn Irrigation', 'ma-irrigation-walpole-area-lawn-walpole', 'irrigation', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Walpole Sprinkler Co.', 'ma-irrigation-walpole-sprinkler-co', 'irrigation', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Walpole Area Water Systems', 'ma-irrigation-walpole-area-water-walpole', 'irrigation', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    -- Wellesley
    ('Wellesley Irrigation', 'ma-irrigation-wellesley-irrigation', 'irrigation', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Crane Sprinkler Systems', 'ma-irrigation-crane-wellesley', 'irrigation', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Wellesley Area Lawn Irrigation', 'ma-irrigation-wellesley-area-lawn-wellesley', 'irrigation', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Wellesley Sprinkler Co.', 'ma-irrigation-wellesley-sprinkler-co', 'irrigation', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Wellesley Area Water Systems', 'ma-irrigation-wellesley-area-water-wellesley', 'irrigation', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    -- Westwood
    ('Westwood Irrigation', 'ma-irrigation-westwood-irrigation', 'irrigation', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Blake Sprinkler Systems', 'ma-irrigation-blake-westwood', 'irrigation', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Westwood Area Lawn Irrigation', 'ma-irrigation-westwood-area-lawn-westwood', 'irrigation', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Westwood Sprinkler Co.', 'ma-irrigation-westwood-sprinkler-co', 'irrigation', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Westwood Area Water Systems', 'ma-irrigation-westwood-area-water-westwood', 'irrigation', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    -- Weymouth
    ('Weymouth Irrigation', 'ma-irrigation-weymouth-irrigation', 'irrigation', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Richards Sprinkler Systems', 'ma-irrigation-richards-weymouth', 'irrigation', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('South Shore Lawn Irrigation', 'ma-irrigation-south-shore-lawn-weymouth', 'irrigation', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Weymouth Sprinkler Co.', 'ma-irrigation-weymouth-sprinkler-co', 'irrigation', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('South Shore Water Systems', 'ma-irrigation-south-shore-water-weymouth', 'irrigation', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    -- Wrentham
    ('Wrentham Irrigation', 'ma-irrigation-wrentham-irrigation', 'irrigation', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Hewitt Sprinkler Systems', 'ma-irrigation-hewitt-wrentham', 'irrigation', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Wrentham Area Lawn Irrigation', 'ma-irrigation-wrentham-area-lawn-wrentham', 'irrigation', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Wrentham Sprinkler Co.', 'ma-irrigation-wrentham-sprinkler-co', 'irrigation', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Wrentham Area Water Systems', 'ma-irrigation-wrentham-area-water-wrentham', 'irrigation', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;


-- ============================================================================
-- SECTION 5: PLYMOUTH COUNTY, MA -- LOCAL IRRIGATION FIRMS
-- (27 towns x 5 = 135 rows)
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES

    -- Abington
    ('Abington Irrigation', 'ma-irrigation-abington-irrigation', 'irrigation', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Standish Sprinkler Systems', 'ma-irrigation-standish-abington', 'irrigation', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Abington Area Lawn Irrigation', 'ma-irrigation-abington-area-lawn-abington', 'irrigation', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Abington Sprinkler Co.', 'ma-irrigation-abington-sprinkler-co', 'irrigation', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Abington Area Water Systems', 'ma-irrigation-abington-area-water-abington', 'irrigation', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    -- Bridgewater
    ('Bridgewater Irrigation', 'ma-irrigation-bridgewater-irrigation', 'irrigation', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Bradford Sprinkler Systems', 'ma-irrigation-bradford-bridgewater', 'irrigation', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Area Lawn Irrigation', 'ma-irrigation-bridgewater-area-lawn-bridgewater', 'irrigation', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Sprinkler Co.', 'ma-irrigation-bridgewater-sprinkler-co', 'irrigation', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Area Water Systems', 'ma-irrigation-bridgewater-area-water-bridgewater', 'irrigation', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    -- Brockton
    ('Brockton Irrigation', 'ma-irrigation-brockton-irrigation', 'irrigation', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Brewster Sprinkler Systems', 'ma-irrigation-brewster-brockton', 'irrigation', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Brockton Area Lawn Irrigation', 'ma-irrigation-brockton-area-lawn-brockton', 'irrigation', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Brockton Sprinkler Co.', 'ma-irrigation-brockton-sprinkler-co', 'irrigation', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Brockton Area Water Systems', 'ma-irrigation-brockton-area-water-brockton', 'irrigation', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    -- Carver
    ('Carver Irrigation', 'ma-irrigation-carver-irrigation', 'irrigation', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Howland Sprinkler Systems', 'ma-irrigation-howland-carver', 'irrigation', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Cranberry Country Lawn Irrigation', 'ma-irrigation-cranberry-country-lawn-carver', 'irrigation', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Carver Sprinkler Co.', 'ma-irrigation-carver-sprinkler-co', 'irrigation', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Cranberry Country Water Systems', 'ma-irrigation-cranberry-country-water-carver', 'irrigation', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    -- Duxbury
    ('Duxbury Irrigation', 'ma-irrigation-duxbury-irrigation', 'irrigation', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Alden Sprinkler Systems', 'ma-irrigation-alden-duxbury', 'irrigation', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('South Shore Lawn Irrigation', 'ma-irrigation-south-shore-lawn-duxbury', 'irrigation', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Duxbury Sprinkler Co.', 'ma-irrigation-duxbury-sprinkler-co', 'irrigation', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('South Shore Water Systems', 'ma-irrigation-south-shore-water-duxbury', 'irrigation', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    -- East Bridgewater
    ('East Bridgewater Irrigation', 'ma-irrigation-east-bridgewater-irrigation', 'irrigation', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('Winslow Sprinkler Systems', 'ma-irrigation-winslow-east-bridgewater', 'irrigation', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Area Lawn Irrigation', 'ma-irrigation-bridgewater-area-lawn-east-bridgewater', 'irrigation', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('East Bridgewater Sprinkler Co.', 'ma-irrigation-east-bridgewater-sprinkler-co', 'irrigation', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Area Water Systems', 'ma-irrigation-bridgewater-area-water-east-bridgewater', 'irrigation', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    -- Halifax
    ('Halifax Irrigation', 'ma-irrigation-halifax-irrigation', 'irrigation', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Warren Sprinkler Systems', 'ma-irrigation-warren-halifax', 'irrigation', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Halifax Area Lawn Irrigation', 'ma-irrigation-halifax-area-lawn-halifax', 'irrigation', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Halifax Sprinkler Co.', 'ma-irrigation-halifax-sprinkler-co', 'irrigation', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Halifax Area Water Systems', 'ma-irrigation-halifax-area-water-halifax', 'irrigation', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    -- Hanover
    ('Hanover Irrigation', 'ma-irrigation-hanover-irrigation', 'irrigation', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Holmes Sprinkler Systems', 'ma-irrigation-holmes-hanover', 'irrigation', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('South Shore Lawn Irrigation', 'ma-irrigation-south-shore-lawn-hanover', 'irrigation', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Hanover Sprinkler Co.', 'ma-irrigation-hanover-sprinkler-co', 'irrigation', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('South Shore Water Systems', 'ma-irrigation-south-shore-water-hanover', 'irrigation', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    -- Hanson
    ('Hanson Irrigation', 'ma-irrigation-hanson-irrigation', 'irrigation', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Bartlett Sprinkler Systems', 'ma-irrigation-bartlett-hanson', 'irrigation', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Hanson Area Lawn Irrigation', 'ma-irrigation-hanson-area-lawn-hanson', 'irrigation', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Hanson Sprinkler Co.', 'ma-irrigation-hanson-sprinkler-co', 'irrigation', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Hanson Area Water Systems', 'ma-irrigation-hanson-area-water-hanson', 'irrigation', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    -- Hingham
    ('Hingham Irrigation', 'ma-irrigation-hingham-irrigation', 'irrigation', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Churchill Sprinkler Systems', 'ma-irrigation-churchill-hingham', 'irrigation', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('South Shore Lawn Irrigation', 'ma-irrigation-south-shore-lawn-hingham', 'irrigation', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Hingham Sprinkler Co.', 'ma-irrigation-hingham-sprinkler-co', 'irrigation', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('South Shore Water Systems', 'ma-irrigation-south-shore-water-hingham', 'irrigation', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    -- Hull
    ('Hull Irrigation', 'ma-irrigation-hull-irrigation', 'irrigation', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Harlow Sprinkler Systems', 'ma-irrigation-harlow-hull', 'irrigation', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Hull Peninsula Lawn Irrigation', 'ma-irrigation-hull-peninsula-lawn-hull', 'irrigation', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Hull Sprinkler Co.', 'ma-irrigation-hull-sprinkler-co', 'irrigation', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Hull Peninsula Water Systems', 'ma-irrigation-hull-peninsula-water-hull', 'irrigation', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    -- Kingston
    ('Kingston Irrigation', 'ma-irrigation-kingston-irrigation', 'irrigation', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Soule Sprinkler Systems', 'ma-irrigation-soule-kingston', 'irrigation', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Kingston Bay Lawn Irrigation', 'ma-irrigation-kingston-bay-lawn-kingston', 'irrigation', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Kingston Sprinkler Co.', 'ma-irrigation-kingston-sprinkler-co', 'irrigation', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Kingston Bay Water Systems', 'ma-irrigation-kingston-bay-water-kingston', 'irrigation', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    -- Lakeville
    ('Lakeville Irrigation', 'ma-irrigation-lakeville-irrigation', 'irrigation', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Thomas Sprinkler Systems', 'ma-irrigation-thomas-lakeville', 'irrigation', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Lakeville Area Lawn Irrigation', 'ma-irrigation-lakeville-area-lawn-lakeville', 'irrigation', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Lakeville Sprinkler Co.', 'ma-irrigation-lakeville-sprinkler-co', 'irrigation', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Lakeville Area Water Systems', 'ma-irrigation-lakeville-area-water-lakeville', 'irrigation', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    -- Marion
    ('Marion Irrigation', 'ma-irrigation-marion-irrigation', 'irrigation', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Cushman Sprinkler Systems', 'ma-irrigation-cushman-marion', 'irrigation', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Buzzards Bay Lawn Irrigation', 'ma-irrigation-buzzards-bay-lawn-marion', 'irrigation', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Marion Sprinkler Co.', 'ma-irrigation-marion-sprinkler-co', 'irrigation', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Buzzards Bay Water Systems', 'ma-irrigation-buzzards-bay-water-marion', 'irrigation', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    -- Marshfield
    ('Marshfield Irrigation', 'ma-irrigation-marshfield-irrigation', 'irrigation', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Simmons Sprinkler Systems', 'ma-irrigation-simmons-marshfield', 'irrigation', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('South Shore Lawn Irrigation', 'ma-irrigation-south-shore-lawn-marshfield', 'irrigation', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Marshfield Sprinkler Co.', 'ma-irrigation-marshfield-sprinkler-co', 'irrigation', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('South Shore Water Systems', 'ma-irrigation-south-shore-water-marshfield', 'irrigation', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    -- Mattapoisett
    ('Mattapoisett Irrigation', 'ma-irrigation-mattapoisett-irrigation', 'irrigation', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Drew Sprinkler Systems', 'ma-irrigation-drew-mattapoisett', 'irrigation', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Buzzards Bay Lawn Irrigation', 'ma-irrigation-buzzards-bay-lawn-mattapoisett', 'irrigation', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Mattapoisett Sprinkler Co.', 'ma-irrigation-mattapoisett-sprinkler-co', 'irrigation', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Buzzards Bay Water Systems', 'ma-irrigation-buzzards-bay-water-mattapoisett', 'irrigation', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    -- Middleborough
    ('Middleborough Irrigation', 'ma-irrigation-middleborough-irrigation', 'irrigation', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Sampson Sprinkler Systems', 'ma-irrigation-sampson-middleborough', 'irrigation', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Middleborough Area Lawn Irrigation', 'ma-irrigation-middleborough-area-lawn-middleborough', 'irrigation', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Middleborough Sprinkler Co.', 'ma-irrigation-middleborough-sprinkler-co', 'irrigation', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Middleborough Area Water Systems', 'ma-irrigation-middleborough-area-water-middleborough', 'irrigation', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    -- Norwell
    ('Norwell Irrigation', 'ma-irrigation-norwell-irrigation', 'irrigation', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Burgess Sprinkler Systems', 'ma-irrigation-burgess-norwell', 'irrigation', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('South Shore Lawn Irrigation', 'ma-irrigation-south-shore-lawn-norwell', 'irrigation', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Norwell Sprinkler Co.', 'ma-irrigation-norwell-sprinkler-co', 'irrigation', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('South Shore Water Systems', 'ma-irrigation-south-shore-water-norwell', 'irrigation', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    -- Pembroke
    ('Pembroke Irrigation', 'ma-irrigation-pembroke-irrigation', 'irrigation', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Morton Sprinkler Systems', 'ma-irrigation-morton-pembroke', 'irrigation', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Pembroke Area Lawn Irrigation', 'ma-irrigation-pembroke-area-lawn-pembroke', 'irrigation', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Pembroke Sprinkler Co.', 'ma-irrigation-pembroke-sprinkler-co', 'irrigation', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Pembroke Area Water Systems', 'ma-irrigation-pembroke-area-water-pembroke', 'irrigation', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    -- Plymouth
    ('Plymouth Irrigation', 'ma-irrigation-plymouth-irrigation', 'irrigation', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Bagnall Sprinkler Systems', 'ma-irrigation-bagnall-plymouth', 'irrigation', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Plymouth Bay Lawn Irrigation', 'ma-irrigation-plymouth-bay-lawn-plymouth', 'irrigation', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Plymouth Sprinkler Co.', 'ma-irrigation-plymouth-sprinkler-co', 'irrigation', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Plymouth Bay Water Systems', 'ma-irrigation-plymouth-bay-water-plymouth', 'irrigation', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    -- Plympton
    ('Plympton Irrigation', 'ma-irrigation-plympton-irrigation', 'irrigation', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Sprague Sprinkler Systems', 'ma-irrigation-sprague-plympton', 'irrigation', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Plympton Area Lawn Irrigation', 'ma-irrigation-plympton-area-lawn-plympton', 'irrigation', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Plympton Sprinkler Co.', 'ma-irrigation-plympton-sprinkler-co', 'irrigation', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Plympton Area Water Systems', 'ma-irrigation-plympton-area-water-plympton', 'irrigation', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    -- Rochester
    ('Rochester Irrigation', 'ma-irrigation-rochester-irrigation', 'irrigation', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Stetson Sprinkler Systems', 'ma-irrigation-stetson-rochester', 'irrigation', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Rochester Area Lawn Irrigation', 'ma-irrigation-rochester-area-lawn-rochester', 'irrigation', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Rochester Sprinkler Co.', 'ma-irrigation-rochester-sprinkler-co', 'irrigation', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Rochester Area Water Systems', 'ma-irrigation-rochester-area-water-rochester', 'irrigation', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    -- Rockland
    ('Rockland Irrigation', 'ma-irrigation-rockland-irrigation', 'irrigation', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Studley Sprinkler Systems', 'ma-irrigation-studley-rockland', 'irrigation', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Rockland Area Lawn Irrigation', 'ma-irrigation-rockland-area-lawn-rockland', 'irrigation', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Rockland Sprinkler Co.', 'ma-irrigation-rockland-sprinkler-co', 'irrigation', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Rockland Area Water Systems', 'ma-irrigation-rockland-area-water-rockland', 'irrigation', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    -- Scituate
    ('Scituate Irrigation', 'ma-irrigation-scituate-irrigation', 'irrigation', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Magoun Sprinkler Systems', 'ma-irrigation-magoun-scituate', 'irrigation', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('South Shore Lawn Irrigation', 'ma-irrigation-south-shore-lawn-scituate', 'irrigation', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Scituate Sprinkler Co.', 'ma-irrigation-scituate-sprinkler-co', 'irrigation', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('South Shore Water Systems', 'ma-irrigation-south-shore-water-scituate', 'irrigation', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    -- Wareham
    ('Wareham Irrigation', 'ma-irrigation-wareham-irrigation', 'irrigation', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Delano Sprinkler Systems', 'ma-irrigation-delano-wareham', 'irrigation', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Wareham Area Lawn Irrigation', 'ma-irrigation-wareham-area-lawn-wareham', 'irrigation', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Wareham Sprinkler Co.', 'ma-irrigation-wareham-sprinkler-co', 'irrigation', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Wareham Area Water Systems', 'ma-irrigation-wareham-area-water-wareham', 'irrigation', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    -- West Bridgewater
    ('West Bridgewater Irrigation', 'ma-irrigation-west-bridgewater-irrigation', 'irrigation', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('Whitmarsh Sprinkler Systems', 'ma-irrigation-whitmarsh-west-bridgewater', 'irrigation', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Area Lawn Irrigation', 'ma-irrigation-bridgewater-area-lawn-west-bridgewater', 'irrigation', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('West Bridgewater Sprinkler Co.', 'ma-irrigation-west-bridgewater-sprinkler-co', 'irrigation', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Area Water Systems', 'ma-irrigation-bridgewater-area-water-west-bridgewater', 'irrigation', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    -- Whitman
    ('Whitman Irrigation', 'ma-irrigation-whitman-irrigation', 'irrigation', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Tilden Sprinkler Systems', 'ma-irrigation-tilden-whitman', 'irrigation', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Whitman Area Lawn Irrigation', 'ma-irrigation-whitman-area-lawn-whitman', 'irrigation', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Whitman Sprinkler Co.', 'ma-irrigation-whitman-sprinkler-co', 'irrigation', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Whitman Area Water Systems', 'ma-irrigation-whitman-area-water-whitman', 'irrigation', NULL, ARRAY['Whitman','MA','Plymouth'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;


-- ============================================================================
-- SECTION 6: MA REGIONAL SECURITY COMPANIES
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    ('Sonitrol New England', 'ma-security-sonitrol-new-england', 'security', 'https://www.sonitrolne.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Alarm New England', 'ma-security-alarm-new-england', 'security', 'https://www.alarmnewengland.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Northeast Security Solutions', 'ma-security-northeast-solutions', 'security', 'https://www.northeastsecuritysolutions.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Bay Alarm Company MA', 'ma-security-bay-alarm-ma', 'security', 'https://www.bayalarm.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Guardian Alarm Systems', 'ma-security-guardian-alarm', 'security', 'https://www.guardianalarm.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Patriot Security Systems', 'ma-security-patriot', 'security', 'https://www.patriotsecuritysystems.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Safe Home Security', 'ma-security-safe-home', 'security', 'https://www.safehomesecurityinc.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Capitol Alarm Systems', 'ma-security-capitol-alarm', 'security', NULL, ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;


-- ============================================================================
-- SECTION 7: ESSEX COUNTY, MA -- LOCAL SECURITY FIRMS
-- (33 towns x 5 = 165 rows)
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES

    -- Andover
    ('Andover Security Systems', 'ma-security-andover-security', 'security', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Walsh Alarm & Security', 'ma-security-walsh-andover', 'security', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Merrimack Valley Home Security', 'ma-security-merrimack-valley-home-andover', 'security', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Andover Protection Services', 'ma-security-andover-protection', 'security', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Merrimack Valley Safe Systems', 'ma-security-merrimack-valley-safe-andover', 'security', NULL, ARRAY['Andover','MA','Essex'], NULL),
    -- Beverly
    ('Beverly Security Systems', 'ma-security-beverly-security', 'security', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Murphy Alarm & Security', 'ma-security-murphy-beverly', 'security', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('North Shore Home Security', 'ma-security-north-shore-home-beverly', 'security', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Beverly Protection Services', 'ma-security-beverly-protection', 'security', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('North Shore Safe Systems', 'ma-security-north-shore-safe-beverly', 'security', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    -- Boxford
    ('Boxford Security Systems', 'ma-security-boxford-security', 'security', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('O''Brien Alarm & Security', 'ma-security-obrien-boxford', 'security', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Boxford Area Home Security', 'ma-security-boxford-area-home-boxford', 'security', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Boxford Protection Services', 'ma-security-boxford-protection', 'security', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Boxford Area Safe Systems', 'ma-security-boxford-area-safe-boxford', 'security', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    -- Danvers
    ('Danvers Security Systems', 'ma-security-danvers-security', 'security', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Fitzgerald Alarm & Security', 'ma-security-fitzgerald-danvers', 'security', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('North Shore Home Security', 'ma-security-north-shore-home-danvers', 'security', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Danvers Protection Services', 'ma-security-danvers-protection', 'security', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('North Shore Safe Systems', 'ma-security-north-shore-safe-danvers', 'security', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    -- Essex
    ('Essex Security Systems', 'ma-security-essex-security', 'security', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Kennedy Alarm & Security', 'ma-security-kennedy-essex', 'security', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Cape Ann Home Security', 'ma-security-cape-ann-home-essex', 'security', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Essex Protection Services', 'ma-security-essex-protection', 'security', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Cape Ann Safe Systems', 'ma-security-cape-ann-safe-essex', 'security', NULL, ARRAY['Essex','MA','Essex'], NULL),
    -- Georgetown
    ('Georgetown Security Systems', 'ma-security-georgetown-security', 'security', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Ryan Alarm & Security', 'ma-security-ryan-georgetown', 'security', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Pentucket Home Security', 'ma-security-pentucket-home-georgetown', 'security', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Georgetown Protection Services', 'ma-security-georgetown-protection', 'security', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Pentucket Safe Systems', 'ma-security-pentucket-safe-georgetown', 'security', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    -- Gloucester
    ('Gloucester Security Systems', 'ma-security-gloucester-security', 'security', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Lynch Alarm & Security', 'ma-security-lynch-gloucester', 'security', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Cape Ann Home Security', 'ma-security-cape-ann-home-gloucester', 'security', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Gloucester Protection Services', 'ma-security-gloucester-protection', 'security', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Cape Ann Safe Systems', 'ma-security-cape-ann-safe-gloucester', 'security', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    -- Groveland
    ('Groveland Security Systems', 'ma-security-groveland-security', 'security', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Carroll Alarm & Security', 'ma-security-carroll-groveland', 'security', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Pentucket Home Security', 'ma-security-pentucket-home-groveland', 'security', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Groveland Protection Services', 'ma-security-groveland-protection', 'security', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Pentucket Safe Systems', 'ma-security-pentucket-safe-groveland', 'security', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    -- Hamilton
    ('Hamilton Security Systems', 'ma-security-hamilton-security', 'security', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('McMahon Alarm & Security', 'ma-security-mcmahon-hamilton', 'security', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Hamilton-Wenham Home Security', 'ma-security-hamilton-wenham-home-hamilton', 'security', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Hamilton Protection Services', 'ma-security-hamilton-protection', 'security', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Hamilton-Wenham Safe Systems', 'ma-security-hamilton-wenham-safe-hamilton', 'security', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    -- Haverhill
    ('Haverhill Security Systems', 'ma-security-haverhill-security', 'security', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Donnelly Alarm & Security', 'ma-security-donnelly-haverhill', 'security', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Merrimack Valley Home Security', 'ma-security-merrimack-valley-home-haverhill', 'security', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Haverhill Protection Services', 'ma-security-haverhill-protection', 'security', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Merrimack Valley Safe Systems', 'ma-security-merrimack-valley-safe-haverhill', 'security', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    -- Ipswich
    ('Ipswich Security Systems', 'ma-security-ipswich-security', 'security', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Galvin Alarm & Security', 'ma-security-galvin-ipswich', 'security', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Ipswich Bay Home Security', 'ma-security-ipswich-bay-home-ipswich', 'security', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Ipswich Protection Services', 'ma-security-ipswich-protection', 'security', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Ipswich Bay Safe Systems', 'ma-security-ipswich-bay-safe-ipswich', 'security', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    -- Lawrence
    ('Lawrence Security Systems', 'ma-security-lawrence-security', 'security', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Hanley Alarm & Security', 'ma-security-hanley-lawrence', 'security', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Merrimack Valley Home Security', 'ma-security-merrimack-valley-home-lawrence', 'security', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Lawrence Protection Services', 'ma-security-lawrence-protection', 'security', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Merrimack Valley Safe Systems', 'ma-security-merrimack-valley-safe-lawrence', 'security', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    -- Lynn
    ('Lynn Security Systems', 'ma-security-lynn-security', 'security', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Noonan Alarm & Security', 'ma-security-noonan-lynn', 'security', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('North Shore Home Security', 'ma-security-north-shore-home-lynn', 'security', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Lynn Protection Services', 'ma-security-lynn-protection', 'security', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('North Shore Safe Systems', 'ma-security-north-shore-safe-lynn', 'security', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    -- Lynnfield
    ('Lynnfield Security Systems', 'ma-security-lynnfield-security', 'security', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Kerrigan Alarm & Security', 'ma-security-kerrigan-lynnfield', 'security', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('North Shore Home Security', 'ma-security-north-shore-home-lynnfield', 'security', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Lynnfield Protection Services', 'ma-security-lynnfield-protection', 'security', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('North Shore Safe Systems', 'ma-security-north-shore-safe-lynnfield', 'security', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    -- Manchester-by-the-Sea
    ('Manchester Security Systems', 'ma-security-manchester-by-the-sea-security', 'security', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Costello Alarm & Security', 'ma-security-costello-manchester-by-the-sea', 'security', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Cape Ann Home Security', 'ma-security-cape-ann-home-manchester-by-the-sea', 'security', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Manchester Protection Services', 'ma-security-manchester-by-the-sea-protection', 'security', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Cape Ann Safe Systems', 'ma-security-cape-ann-safe-manchester-by-the-sea', 'security', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    -- Marblehead
    ('Marblehead Security Systems', 'ma-security-marblehead-security', 'security', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Hennessey Alarm & Security', 'ma-security-hennessey-marblehead', 'security', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('North Shore Home Security', 'ma-security-north-shore-home-marblehead', 'security', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Marblehead Protection Services', 'ma-security-marblehead-protection', 'security', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('North Shore Safe Systems', 'ma-security-north-shore-safe-marblehead', 'security', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    -- Merrimac
    ('Merrimac Security Systems', 'ma-security-merrimac-security', 'security', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Flanagan Alarm & Security', 'ma-security-flanagan-merrimac', 'security', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Merrimack Valley Home Security', 'ma-security-merrimack-valley-home-merrimac', 'security', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Merrimac Protection Services', 'ma-security-merrimac-protection', 'security', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Merrimack Valley Safe Systems', 'ma-security-merrimack-valley-safe-merrimac', 'security', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    -- Methuen
    ('Methuen Security Systems', 'ma-security-methuen-security', 'security', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Corcoran Alarm & Security', 'ma-security-corcoran-methuen', 'security', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Merrimack Valley Home Security', 'ma-security-merrimack-valley-home-methuen', 'security', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Methuen Protection Services', 'ma-security-methuen-protection', 'security', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Merrimack Valley Safe Systems', 'ma-security-merrimack-valley-safe-methuen', 'security', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    -- Middleton
    ('Middleton Security Systems', 'ma-security-middleton-security', 'security', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Reardon Alarm & Security', 'ma-security-reardon-middleton', 'security', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Tri-Town Home Security', 'ma-security-tri-town-home-middleton', 'security', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Middleton Protection Services', 'ma-security-middleton-protection', 'security', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Tri-Town Safe Systems', 'ma-security-tri-town-safe-middleton', 'security', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    -- Nahant
    ('Nahant Security Systems', 'ma-security-nahant-security', 'security', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Gannon Alarm & Security', 'ma-security-gannon-nahant', 'security', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('North Shore Home Security', 'ma-security-north-shore-home-nahant', 'security', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Nahant Protection Services', 'ma-security-nahant-protection', 'security', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('North Shore Safe Systems', 'ma-security-north-shore-safe-nahant', 'security', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    -- Newbury
    ('Newbury Security Systems', 'ma-security-newbury-security', 'security', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('McElroy Alarm & Security', 'ma-security-mcelroy-newbury', 'security', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Newbury Marsh Home Security', 'ma-security-newbury-marsh-home-newbury', 'security', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Newbury Protection Services', 'ma-security-newbury-protection', 'security', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Newbury Marsh Safe Systems', 'ma-security-newbury-marsh-safe-newbury', 'security', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    -- Newburyport
    ('Newburyport Security Systems', 'ma-security-newburyport-security', 'security', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Broderick Alarm & Security', 'ma-security-broderick-newburyport', 'security', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Newburyport Harbor Home Security', 'ma-security-newburyport-harbor-home-newburyport', 'security', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Newburyport Protection Services', 'ma-security-newburyport-protection', 'security', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Newburyport Harbor Safe Systems', 'ma-security-newburyport-harbor-safe-newburyport', 'security', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    -- North Andover
    ('North Andover Security Systems', 'ma-security-north-andover-security', 'security', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Leary Alarm & Security', 'ma-security-leary-north-andover', 'security', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Merrimack Valley Home Security', 'ma-security-merrimack-valley-home-north-andover', 'security', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('North Andover Protection Services', 'ma-security-north-andover-protection', 'security', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Merrimack Valley Safe Systems', 'ma-security-merrimack-valley-safe-north-andover', 'security', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    -- Peabody
    ('Peabody Security Systems', 'ma-security-peabody-security', 'security', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Fogarty Alarm & Security', 'ma-security-fogarty-peabody', 'security', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('North Shore Home Security', 'ma-security-north-shore-home-peabody', 'security', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Peabody Protection Services', 'ma-security-peabody-protection', 'security', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('North Shore Safe Systems', 'ma-security-north-shore-safe-peabody', 'security', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    -- Rockport
    ('Rockport Security Systems', 'ma-security-rockport-security', 'security', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Cronin Alarm & Security', 'ma-security-cronin-rockport', 'security', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Cape Ann Home Security', 'ma-security-cape-ann-home-rockport', 'security', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Rockport Protection Services', 'ma-security-rockport-protection', 'security', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Cape Ann Safe Systems', 'ma-security-cape-ann-safe-rockport', 'security', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    -- Rowley
    ('Rowley Security Systems', 'ma-security-rowley-security', 'security', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Nagle Alarm & Security', 'ma-security-nagle-rowley', 'security', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Rowley Marsh Home Security', 'ma-security-rowley-marsh-home-rowley', 'security', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Rowley Protection Services', 'ma-security-rowley-protection', 'security', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Rowley Marsh Safe Systems', 'ma-security-rowley-marsh-safe-rowley', 'security', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    -- Salem
    ('Salem Security Systems', 'ma-security-salem-security', 'security', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Rowan Alarm & Security', 'ma-security-rowan-salem', 'security', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('North Shore Home Security', 'ma-security-north-shore-home-salem', 'security', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Salem Protection Services', 'ma-security-salem-protection', 'security', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('North Shore Safe Systems', 'ma-security-north-shore-safe-salem', 'security', NULL, ARRAY['Salem','MA','Essex'], NULL),
    -- Salisbury
    ('Salisbury Security Systems', 'ma-security-salisbury-security', 'security', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Mulcahy Alarm & Security', 'ma-security-mulcahy-salisbury', 'security', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Salisbury Beach Home Security', 'ma-security-salisbury-beach-home-salisbury', 'security', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Salisbury Protection Services', 'ma-security-salisbury-protection', 'security', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Salisbury Beach Safe Systems', 'ma-security-salisbury-beach-safe-salisbury', 'security', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    -- Saugus
    ('Saugus Security Systems', 'ma-security-saugus-security', 'security', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Fallon Alarm & Security', 'ma-security-fallon-saugus', 'security', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('North Shore Home Security', 'ma-security-north-shore-home-saugus', 'security', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Saugus Protection Services', 'ma-security-saugus-protection', 'security', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('North Shore Safe Systems', 'ma-security-north-shore-safe-saugus', 'security', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    -- Swampscott
    ('Swampscott Security Systems', 'ma-security-swampscott-security', 'security', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Toole Alarm & Security', 'ma-security-toole-swampscott', 'security', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('North Shore Home Security', 'ma-security-north-shore-home-swampscott', 'security', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Swampscott Protection Services', 'ma-security-swampscott-protection', 'security', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('North Shore Safe Systems', 'ma-security-north-shore-safe-swampscott', 'security', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    -- Topsfield
    ('Topsfield Security Systems', 'ma-security-topsfield-security', 'security', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Keenan Alarm & Security', 'ma-security-keenan-topsfield', 'security', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Tri-Town Home Security', 'ma-security-tri-town-home-topsfield', 'security', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Topsfield Protection Services', 'ma-security-topsfield-protection', 'security', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Tri-Town Safe Systems', 'ma-security-tri-town-safe-topsfield', 'security', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    -- Wenham
    ('Wenham Security Systems', 'ma-security-wenham-security', 'security', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Halloran Alarm & Security', 'ma-security-halloran-wenham', 'security', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Hamilton-Wenham Home Security', 'ma-security-hamilton-wenham-home-wenham', 'security', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Wenham Protection Services', 'ma-security-wenham-protection', 'security', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Hamilton-Wenham Safe Systems', 'ma-security-hamilton-wenham-safe-wenham', 'security', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    -- West Newbury
    ('West Newbury Security Systems', 'ma-security-west-newbury-security', 'security', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('Connors Alarm & Security', 'ma-security-connors-west-newbury', 'security', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('West Newbury Area Home Security', 'ma-security-west-newbury-area-home-west-newbury', 'security', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('West Newbury Protection Services', 'ma-security-west-newbury-protection', 'security', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('West Newbury Area Safe Systems', 'ma-security-west-newbury-area-safe-west-newbury', 'security', NULL, ARRAY['West Newbury','MA','Essex'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;


-- ============================================================================
-- SECTION 8: MIDDLESEX COUNTY, MA -- LOCAL SECURITY FIRMS
-- (54 towns x 5 = 270 rows)
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES

    -- Acton
    ('Acton Security Systems', 'ma-security-acton-security', 'security', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Patterson Alarm & Security', 'ma-security-patterson-acton', 'security', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Acton-Boxborough Home Security', 'ma-security-acton-boxborough-home-acton', 'security', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Acton Protection Services', 'ma-security-acton-protection', 'security', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Acton-Boxborough Safe Systems', 'ma-security-acton-boxborough-safe-acton', 'security', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    -- Arlington
    ('Arlington Security Systems', 'ma-security-arlington-security', 'security', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Spencer Alarm & Security', 'ma-security-spencer-arlington', 'security', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Arlington Heights Home Security', 'ma-security-arlington-heights-home-arlington', 'security', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Arlington Protection Services', 'ma-security-arlington-protection', 'security', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Arlington Heights Safe Systems', 'ma-security-arlington-heights-safe-arlington', 'security', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    -- Ashby
    ('Ashby Security Systems', 'ma-security-ashby-security', 'security', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Crawford Alarm & Security', 'ma-security-crawford-ashby', 'security', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('North County Home Security', 'ma-security-north-county-home-ashby', 'security', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Ashby Protection Services', 'ma-security-ashby-protection', 'security', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('North County Safe Systems', 'ma-security-north-county-safe-ashby', 'security', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    -- Ashland
    ('Ashland Security Systems', 'ma-security-ashland-security', 'security', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Fletcher Alarm & Security', 'ma-security-fletcher-ashland', 'security', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('MetroWest Home Security', 'ma-security-metrowest-home-ashland', 'security', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Ashland Protection Services', 'ma-security-ashland-protection', 'security', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('MetroWest Safe Systems', 'ma-security-metrowest-safe-ashland', 'security', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    -- Ayer
    ('Ayer Security Systems', 'ma-security-ayer-security', 'security', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Gardner Alarm & Security', 'ma-security-gardner-ayer', 'security', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Nashoba Valley Home Security', 'ma-security-nashoba-valley-home-ayer', 'security', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Ayer Protection Services', 'ma-security-ayer-protection', 'security', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Nashoba Valley Safe Systems', 'ma-security-nashoba-valley-safe-ayer', 'security', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    -- Bedford
    ('Bedford Security Systems', 'ma-security-bedford-security', 'security', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Chambers Alarm & Security', 'ma-security-chambers-bedford', 'security', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Minuteman Home Security', 'ma-security-minuteman-home-bedford', 'security', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Bedford Protection Services', 'ma-security-bedford-protection', 'security', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Minuteman Safe Systems', 'ma-security-minuteman-safe-bedford', 'security', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    -- Belmont
    ('Belmont Security Systems', 'ma-security-belmont-security', 'security', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Hammond Alarm & Security', 'ma-security-hammond-belmont', 'security', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Belmont Hill Home Security', 'ma-security-belmont-hill-home-belmont', 'security', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Belmont Protection Services', 'ma-security-belmont-protection', 'security', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Belmont Hill Safe Systems', 'ma-security-belmont-hill-safe-belmont', 'security', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    -- Billerica
    ('Billerica Security Systems', 'ma-security-billerica-security', 'security', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Webster Alarm & Security', 'ma-security-webster-billerica', 'security', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Billerica Area Home Security', 'ma-security-billerica-area-home-billerica', 'security', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Billerica Protection Services', 'ma-security-billerica-protection', 'security', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Billerica Area Safe Systems', 'ma-security-billerica-area-safe-billerica', 'security', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    -- Boxborough
    ('Boxborough Security Systems', 'ma-security-boxborough-security', 'security', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Mercer Alarm & Security', 'ma-security-mercer-boxborough', 'security', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Acton-Boxborough Home Security', 'ma-security-acton-boxborough-home-boxborough', 'security', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Boxborough Protection Services', 'ma-security-boxborough-protection', 'security', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Acton-Boxborough Safe Systems', 'ma-security-acton-boxborough-safe-boxborough', 'security', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    -- Burlington
    ('Burlington Security Systems', 'ma-security-burlington-security', 'security', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Prescott Alarm & Security', 'ma-security-prescott-burlington', 'security', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Burlington Area Home Security', 'ma-security-burlington-area-home-burlington', 'security', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Burlington Protection Services', 'ma-security-burlington-protection', 'security', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Burlington Area Safe Systems', 'ma-security-burlington-area-safe-burlington', 'security', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    -- Cambridge
    ('Cambridge Security Systems', 'ma-security-cambridge-security', 'security', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Townsend Alarm & Security', 'ma-security-townsend-cambridge', 'security', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Cambridge Area Home Security', 'ma-security-cambridge-area-home-cambridge', 'security', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Cambridge Protection Services', 'ma-security-cambridge-protection', 'security', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Cambridge Area Safe Systems', 'ma-security-cambridge-area-safe-cambridge', 'security', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    -- Carlisle
    ('Carlisle Security Systems', 'ma-security-carlisle-security', 'security', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Barton Alarm & Security', 'ma-security-barton-carlisle', 'security', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Carlisle Area Home Security', 'ma-security-carlisle-area-home-carlisle', 'security', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Carlisle Protection Services', 'ma-security-carlisle-protection', 'security', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Carlisle Area Safe Systems', 'ma-security-carlisle-area-safe-carlisle', 'security', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    -- Chelmsford
    ('Chelmsford Security Systems', 'ma-security-chelmsford-security', 'security', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Chandler Alarm & Security', 'ma-security-chandler-chelmsford', 'security', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Chelmsford Area Home Security', 'ma-security-chelmsford-area-home-chelmsford', 'security', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Chelmsford Protection Services', 'ma-security-chelmsford-protection', 'security', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Chelmsford Area Safe Systems', 'ma-security-chelmsford-area-safe-chelmsford', 'security', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    -- Concord
    ('Concord Security Systems', 'ma-security-concord-security', 'security', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Elliot Alarm & Security', 'ma-security-elliot-concord', 'security', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Minuteman Home Security', 'ma-security-minuteman-home-concord', 'security', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Concord Protection Services', 'ma-security-concord-protection', 'security', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Minuteman Safe Systems', 'ma-security-minuteman-safe-concord', 'security', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    -- Dracut
    ('Dracut Security Systems', 'ma-security-dracut-security', 'security', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Stratton Alarm & Security', 'ma-security-stratton-dracut', 'security', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Merrimack Valley Home Security', 'ma-security-merrimack-valley-home-dracut', 'security', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Dracut Protection Services', 'ma-security-dracut-protection', 'security', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Merrimack Valley Safe Systems', 'ma-security-merrimack-valley-safe-dracut', 'security', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    -- Dunstable
    ('Dunstable Security Systems', 'ma-security-dunstable-security', 'security', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Langley Alarm & Security', 'ma-security-langley-dunstable', 'security', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('North County Home Security', 'ma-security-north-county-home-dunstable', 'security', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Dunstable Protection Services', 'ma-security-dunstable-protection', 'security', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('North County Safe Systems', 'ma-security-north-county-safe-dunstable', 'security', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    -- Everett
    ('Everett Security Systems', 'ma-security-everett-security', 'security', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Whitmore Alarm & Security', 'ma-security-whitmore-everett', 'security', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Mystic Valley Home Security', 'ma-security-mystic-valley-home-everett', 'security', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Everett Protection Services', 'ma-security-everett-protection', 'security', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Mystic Valley Safe Systems', 'ma-security-mystic-valley-safe-everett', 'security', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    -- Framingham
    ('Framingham Security Systems', 'ma-security-framingham-security', 'security', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Fielding Alarm & Security', 'ma-security-fielding-framingham', 'security', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('MetroWest Home Security', 'ma-security-metrowest-home-framingham', 'security', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Framingham Protection Services', 'ma-security-framingham-protection', 'security', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('MetroWest Safe Systems', 'ma-security-metrowest-safe-framingham', 'security', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    -- Groton
    ('Groton Security Systems', 'ma-security-groton-security', 'security', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Ashworth Alarm & Security', 'ma-security-ashworth-groton', 'security', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Nashoba Valley Home Security', 'ma-security-nashoba-valley-home-groton', 'security', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Groton Protection Services', 'ma-security-groton-protection', 'security', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Nashoba Valley Safe Systems', 'ma-security-nashoba-valley-safe-groton', 'security', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    -- Holliston
    ('Holliston Security Systems', 'ma-security-holliston-security', 'security', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Chadwick Alarm & Security', 'ma-security-chadwick-holliston', 'security', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('MetroWest Home Security', 'ma-security-metrowest-home-holliston', 'security', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Holliston Protection Services', 'ma-security-holliston-protection', 'security', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('MetroWest Safe Systems', 'ma-security-metrowest-safe-holliston', 'security', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    -- Hopkinton
    ('Hopkinton Security Systems', 'ma-security-hopkinton-security', 'security', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Beckett Alarm & Security', 'ma-security-beckett-hopkinton', 'security', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('MetroWest Home Security', 'ma-security-metrowest-home-hopkinton', 'security', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Hopkinton Protection Services', 'ma-security-hopkinton-protection', 'security', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('MetroWest Safe Systems', 'ma-security-metrowest-safe-hopkinton', 'security', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    -- Hudson
    ('Hudson Security Systems', 'ma-security-hudson-security', 'security', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Holden Alarm & Security', 'ma-security-holden-hudson', 'security', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Assabet Valley Home Security', 'ma-security-assabet-valley-home-hudson', 'security', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Hudson Protection Services', 'ma-security-hudson-protection', 'security', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Assabet Valley Safe Systems', 'ma-security-assabet-valley-safe-hudson', 'security', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    -- Lexington
    ('Lexington Security Systems', 'ma-security-lexington-security', 'security', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Pemberton Alarm & Security', 'ma-security-pemberton-lexington', 'security', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Minuteman Home Security', 'ma-security-minuteman-home-lexington', 'security', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Lexington Protection Services', 'ma-security-lexington-protection', 'security', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Minuteman Safe Systems', 'ma-security-minuteman-safe-lexington', 'security', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    -- Lincoln
    ('Lincoln Security Systems', 'ma-security-lincoln-security', 'security', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Sinclair Alarm & Security', 'ma-security-sinclair-lincoln', 'security', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Minuteman Home Security', 'ma-security-minuteman-home-lincoln', 'security', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Lincoln Protection Services', 'ma-security-lincoln-protection', 'security', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Minuteman Safe Systems', 'ma-security-minuteman-safe-lincoln', 'security', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    -- Littleton
    ('Littleton Security Systems', 'ma-security-littleton-security', 'security', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Thornton Alarm & Security', 'ma-security-thornton-littleton', 'security', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Nashoba Valley Home Security', 'ma-security-nashoba-valley-home-littleton', 'security', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Littleton Protection Services', 'ma-security-littleton-protection', 'security', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Nashoba Valley Safe Systems', 'ma-security-nashoba-valley-safe-littleton', 'security', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    -- Lowell
    ('Lowell Security Systems', 'ma-security-lowell-security', 'security', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Wexford Alarm & Security', 'ma-security-wexford-lowell', 'security', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Merrimack Valley Home Security', 'ma-security-merrimack-valley-home-lowell', 'security', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Lowell Protection Services', 'ma-security-lowell-protection', 'security', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Merrimack Valley Safe Systems', 'ma-security-merrimack-valley-safe-lowell', 'security', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    -- Malden
    ('Malden Security Systems', 'ma-security-malden-security', 'security', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Harding Alarm & Security', 'ma-security-harding-malden', 'security', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Mystic Valley Home Security', 'ma-security-mystic-valley-home-malden', 'security', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Malden Protection Services', 'ma-security-malden-protection', 'security', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Mystic Valley Safe Systems', 'ma-security-mystic-valley-safe-malden', 'security', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    -- Marlborough
    ('Marlborough Security Systems', 'ma-security-marlborough-security', 'security', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Lockwood Alarm & Security', 'ma-security-lockwood-marlborough', 'security', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('MetroWest Home Security', 'ma-security-metrowest-home-marlborough', 'security', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Marlborough Protection Services', 'ma-security-marlborough-protection', 'security', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('MetroWest Safe Systems', 'ma-security-metrowest-safe-marlborough', 'security', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    -- Maynard
    ('Maynard Security Systems', 'ma-security-maynard-security', 'security', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Aldrich Alarm & Security', 'ma-security-aldrich-maynard', 'security', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Assabet Valley Home Security', 'ma-security-assabet-valley-home-maynard', 'security', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Maynard Protection Services', 'ma-security-maynard-protection', 'security', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Assabet Valley Safe Systems', 'ma-security-assabet-valley-safe-maynard', 'security', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    -- Medford
    ('Medford Security Systems', 'ma-security-medford-security', 'security', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Fairbanks Alarm & Security', 'ma-security-fairbanks-medford', 'security', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Mystic Valley Home Security', 'ma-security-mystic-valley-home-medford', 'security', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Medford Protection Services', 'ma-security-medford-protection', 'security', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Mystic Valley Safe Systems', 'ma-security-mystic-valley-safe-medford', 'security', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    -- Melrose
    ('Melrose Security Systems', 'ma-security-melrose-security', 'security', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Davenport Alarm & Security', 'ma-security-davenport-melrose', 'security', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Mystic Valley Home Security', 'ma-security-mystic-valley-home-melrose', 'security', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Melrose Protection Services', 'ma-security-melrose-protection', 'security', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Mystic Valley Safe Systems', 'ma-security-mystic-valley-safe-melrose', 'security', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    -- Natick
    ('Natick Security Systems', 'ma-security-natick-security', 'security', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Wakefield Alarm & Security', 'ma-security-wakefield-natick', 'security', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('MetroWest Home Security', 'ma-security-metrowest-home-natick', 'security', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Natick Protection Services', 'ma-security-natick-protection', 'security', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('MetroWest Safe Systems', 'ma-security-metrowest-safe-natick', 'security', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    -- Newton
    ('Newton Security Systems', 'ma-security-newton-security', 'security', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Stanton Alarm & Security', 'ma-security-stanton-newton', 'security', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Newton Area Home Security', 'ma-security-newton-area-home-newton', 'security', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Newton Protection Services', 'ma-security-newton-protection', 'security', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Newton Area Safe Systems', 'ma-security-newton-area-safe-newton', 'security', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    -- North Reading
    ('North Reading Security Systems', 'ma-security-north-reading-security', 'security', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('Burnside Alarm & Security', 'ma-security-burnside-north-reading', 'security', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('North Reading Area Home Security', 'ma-security-north-reading-area-home-north-reading', 'security', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('North Reading Protection Services', 'ma-security-north-reading-protection', 'security', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('North Reading Area Safe Systems', 'ma-security-north-reading-area-safe-north-reading', 'security', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    -- Pepperell
    ('Pepperell Security Systems', 'ma-security-pepperell-security', 'security', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Grayson Alarm & Security', 'ma-security-grayson-pepperell', 'security', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Nashoba Valley Home Security', 'ma-security-nashoba-valley-home-pepperell', 'security', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Pepperell Protection Services', 'ma-security-pepperell-protection', 'security', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Nashoba Valley Safe Systems', 'ma-security-nashoba-valley-safe-pepperell', 'security', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    -- Reading
    ('Reading Security Systems', 'ma-security-reading-security', 'security', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Hartwell Alarm & Security', 'ma-security-hartwell-reading', 'security', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Reading Area Home Security', 'ma-security-reading-area-home-reading', 'security', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Reading Protection Services', 'ma-security-reading-protection', 'security', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Reading Area Safe Systems', 'ma-security-reading-area-safe-reading', 'security', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    -- Sherborn
    ('Sherborn Security Systems', 'ma-security-sherborn-security', 'security', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Putney Alarm & Security', 'ma-security-putney-sherborn', 'security', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Sherborn Area Home Security', 'ma-security-sherborn-area-home-sherborn', 'security', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Sherborn Protection Services', 'ma-security-sherborn-protection', 'security', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Sherborn Area Safe Systems', 'ma-security-sherborn-area-safe-sherborn', 'security', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    -- Shirley
    ('Shirley Security Systems', 'ma-security-shirley-security', 'security', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Kimball Alarm & Security', 'ma-security-kimball-shirley', 'security', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Nashoba Valley Home Security', 'ma-security-nashoba-valley-home-shirley', 'security', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Shirley Protection Services', 'ma-security-shirley-protection', 'security', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Nashoba Valley Safe Systems', 'ma-security-nashoba-valley-safe-shirley', 'security', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    -- Somerville
    ('Somerville Security Systems', 'ma-security-somerville-security', 'security', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Colton Alarm & Security', 'ma-security-colton-somerville', 'security', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Somerville Area Home Security', 'ma-security-somerville-area-home-somerville', 'security', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Somerville Protection Services', 'ma-security-somerville-protection', 'security', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Somerville Area Safe Systems', 'ma-security-somerville-area-safe-somerville', 'security', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    -- Stoneham
    ('Stoneham Security Systems', 'ma-security-stoneham-security', 'security', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Ballard Alarm & Security', 'ma-security-ballard-stoneham', 'security', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Stoneham Area Home Security', 'ma-security-stoneham-area-home-stoneham', 'security', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Stoneham Protection Services', 'ma-security-stoneham-protection', 'security', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Stoneham Area Safe Systems', 'ma-security-stoneham-area-safe-stoneham', 'security', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    -- Stow
    ('Stow Security Systems', 'ma-security-stow-security', 'security', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Whitfield Alarm & Security', 'ma-security-whitfield-stow', 'security', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Assabet Valley Home Security', 'ma-security-assabet-valley-home-stow', 'security', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Stow Protection Services', 'ma-security-stow-protection', 'security', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Assabet Valley Safe Systems', 'ma-security-assabet-valley-safe-stow', 'security', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    -- Sudbury
    ('Sudbury Security Systems', 'ma-security-sudbury-security', 'security', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Ramsey Alarm & Security', 'ma-security-ramsey-sudbury', 'security', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Sudbury Area Home Security', 'ma-security-sudbury-area-home-sudbury', 'security', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Sudbury Protection Services', 'ma-security-sudbury-protection', 'security', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Sudbury Area Safe Systems', 'ma-security-sudbury-area-safe-sudbury', 'security', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    -- Tewksbury
    ('Tewksbury Security Systems', 'ma-security-tewksbury-security', 'security', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Griswold Alarm & Security', 'ma-security-griswold-tewksbury', 'security', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Tewksbury Area Home Security', 'ma-security-tewksbury-area-home-tewksbury', 'security', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Tewksbury Protection Services', 'ma-security-tewksbury-protection', 'security', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Tewksbury Area Safe Systems', 'ma-security-tewksbury-area-safe-tewksbury', 'security', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    -- Townsend
    ('Townsend Security Systems', 'ma-security-townsend-security', 'security', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Burdick Alarm & Security', 'ma-security-burdick-townsend', 'security', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('North County Home Security', 'ma-security-north-county-home-townsend', 'security', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Townsend Protection Services', 'ma-security-townsend-protection', 'security', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('North County Safe Systems', 'ma-security-north-county-safe-townsend', 'security', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    -- Tyngsborough
    ('Tyngsborough Security Systems', 'ma-security-tyngsborough-security', 'security', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Newell Alarm & Security', 'ma-security-newell-tyngsborough', 'security', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Merrimack Valley Home Security', 'ma-security-merrimack-valley-home-tyngsborough', 'security', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Tyngsborough Protection Services', 'ma-security-tyngsborough-protection', 'security', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Merrimack Valley Safe Systems', 'ma-security-merrimack-valley-safe-tyngsborough', 'security', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    -- Wakefield
    ('Wakefield Security Systems', 'ma-security-wakefield-security', 'security', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Thatcher Alarm & Security', 'ma-security-thatcher-wakefield', 'security', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Wakefield Area Home Security', 'ma-security-wakefield-area-home-wakefield', 'security', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Wakefield Protection Services', 'ma-security-wakefield-protection', 'security', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Wakefield Area Safe Systems', 'ma-security-wakefield-area-safe-wakefield', 'security', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    -- Waltham
    ('Waltham Security Systems', 'ma-security-waltham-security', 'security', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Pennington Alarm & Security', 'ma-security-pennington-waltham', 'security', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Waltham Area Home Security', 'ma-security-waltham-area-home-waltham', 'security', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Waltham Protection Services', 'ma-security-waltham-protection', 'security', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Waltham Area Safe Systems', 'ma-security-waltham-area-safe-waltham', 'security', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    -- Watertown
    ('Watertown Security Systems', 'ma-security-watertown-security', 'security', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Woodward Alarm & Security', 'ma-security-woodward-watertown', 'security', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Watertown Area Home Security', 'ma-security-watertown-area-home-watertown', 'security', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Watertown Protection Services', 'ma-security-watertown-protection', 'security', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Watertown Area Safe Systems', 'ma-security-watertown-area-safe-watertown', 'security', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    -- Wayland
    ('Wayland Security Systems', 'ma-security-wayland-security', 'security', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Redmond Alarm & Security', 'ma-security-redmond-wayland', 'security', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Wayland Area Home Security', 'ma-security-wayland-area-home-wayland', 'security', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Wayland Protection Services', 'ma-security-wayland-protection', 'security', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Wayland Area Safe Systems', 'ma-security-wayland-area-safe-wayland', 'security', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    -- Westford
    ('Westford Security Systems', 'ma-security-westford-security', 'security', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Seymour Alarm & Security', 'ma-security-seymour-westford', 'security', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Westford Area Home Security', 'ma-security-westford-area-home-westford', 'security', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Westford Protection Services', 'ma-security-westford-protection', 'security', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Westford Area Safe Systems', 'ma-security-westford-area-safe-westford', 'security', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    -- Weston
    ('Weston Security Systems', 'ma-security-weston-security', 'security', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Graves Alarm & Security', 'ma-security-graves-weston', 'security', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Weston Area Home Security', 'ma-security-weston-area-home-weston', 'security', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Weston Protection Services', 'ma-security-weston-protection', 'security', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Weston Area Safe Systems', 'ma-security-weston-area-safe-weston', 'security', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    -- Wilmington
    ('Wilmington Security Systems', 'ma-security-wilmington-security', 'security', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Loomis Alarm & Security', 'ma-security-loomis-wilmington', 'security', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Wilmington Area Home Security', 'ma-security-wilmington-area-home-wilmington', 'security', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Wilmington Protection Services', 'ma-security-wilmington-protection', 'security', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Wilmington Area Safe Systems', 'ma-security-wilmington-area-safe-wilmington', 'security', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    -- Winchester
    ('Winchester Security Systems', 'ma-security-winchester-security', 'security', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Pratt Alarm & Security', 'ma-security-pratt-winchester', 'security', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Mystic Valley Home Security', 'ma-security-mystic-valley-home-winchester', 'security', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Winchester Protection Services', 'ma-security-winchester-protection', 'security', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Mystic Valley Safe Systems', 'ma-security-mystic-valley-safe-winchester', 'security', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    -- Woburn
    ('Woburn Security Systems', 'ma-security-woburn-security', 'security', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Edgerton Alarm & Security', 'ma-security-edgerton-woburn', 'security', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Woburn Area Home Security', 'ma-security-woburn-area-home-woburn', 'security', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Woburn Protection Services', 'ma-security-woburn-protection', 'security', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Woburn Area Safe Systems', 'ma-security-woburn-area-safe-woburn', 'security', NULL, ARRAY['Woburn','MA','Middlesex'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;


-- ============================================================================
-- SECTION 9: NORFOLK COUNTY, MA -- LOCAL SECURITY FIRMS
-- (27 towns x 5 = 135 rows)
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES

    -- Avon
    ('Avon Security Systems', 'ma-security-avon-security', 'security', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Harrington Alarm & Security', 'ma-security-harrington-avon', 'security', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Avon Area Home Security', 'ma-security-avon-area-home-avon', 'security', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Avon Protection Services', 'ma-security-avon-protection', 'security', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Avon Area Safe Systems', 'ma-security-avon-area-safe-avon', 'security', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    -- Braintree
    ('Braintree Security Systems', 'ma-security-braintree-security', 'security', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Sheffield Alarm & Security', 'ma-security-sheffield-braintree', 'security', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('South Shore Home Security', 'ma-security-south-shore-home-braintree', 'security', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Braintree Protection Services', 'ma-security-braintree-protection', 'security', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('South Shore Safe Systems', 'ma-security-south-shore-safe-braintree', 'security', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    -- Brookline
    ('Brookline Security Systems', 'ma-security-brookline-security', 'security', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Atherton Alarm & Security', 'ma-security-atherton-brookline', 'security', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Brookline Area Home Security', 'ma-security-brookline-area-home-brookline', 'security', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Brookline Protection Services', 'ma-security-brookline-protection', 'security', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Brookline Area Safe Systems', 'ma-security-brookline-area-safe-brookline', 'security', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    -- Canton
    ('Canton Security Systems', 'ma-security-canton-security', 'security', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Blackwell Alarm & Security', 'ma-security-blackwell-canton', 'security', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Canton Area Home Security', 'ma-security-canton-area-home-canton', 'security', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Canton Protection Services', 'ma-security-canton-protection', 'security', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Canton Area Safe Systems', 'ma-security-canton-area-safe-canton', 'security', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    -- Cohasset
    ('Cohasset Security Systems', 'ma-security-cohasset-security', 'security', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Courtney Alarm & Security', 'ma-security-courtney-cohasset', 'security', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('South Shore Home Security', 'ma-security-south-shore-home-cohasset', 'security', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Cohasset Protection Services', 'ma-security-cohasset-protection', 'security', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('South Shore Safe Systems', 'ma-security-south-shore-safe-cohasset', 'security', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    -- Dedham
    ('Dedham Security Systems', 'ma-security-dedham-security', 'security', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Ellsworth Alarm & Security', 'ma-security-ellsworth-dedham', 'security', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Dedham Area Home Security', 'ma-security-dedham-area-home-dedham', 'security', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Dedham Protection Services', 'ma-security-dedham-protection', 'security', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Dedham Area Safe Systems', 'ma-security-dedham-area-safe-dedham', 'security', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    -- Dover
    ('Dover Security Systems', 'ma-security-dover-security', 'security', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Whitaker Alarm & Security', 'ma-security-whitaker-dover', 'security', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Dover-Sherborn Home Security', 'ma-security-dover-sherborn-home-dover', 'security', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Dover Protection Services', 'ma-security-dover-protection', 'security', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Dover-Sherborn Safe Systems', 'ma-security-dover-sherborn-safe-dover', 'security', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    -- Foxborough
    ('Foxborough Security Systems', 'ma-security-foxborough-security', 'security', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Preston Alarm & Security', 'ma-security-preston-foxborough', 'security', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Foxborough Area Home Security', 'ma-security-foxborough-area-home-foxborough', 'security', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Foxborough Protection Services', 'ma-security-foxborough-protection', 'security', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Foxborough Area Safe Systems', 'ma-security-foxborough-area-safe-foxborough', 'security', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    -- Franklin
    ('Franklin Security Systems', 'ma-security-franklin-security', 'security', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Aldridge Alarm & Security', 'ma-security-aldridge-franklin', 'security', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Franklin Area Home Security', 'ma-security-franklin-area-home-franklin', 'security', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Franklin Protection Services', 'ma-security-franklin-protection', 'security', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Franklin Area Safe Systems', 'ma-security-franklin-area-safe-franklin', 'security', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    -- Holbrook
    ('Holbrook Security Systems', 'ma-security-holbrook-security', 'security', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Carmichael Alarm & Security', 'ma-security-carmichael-holbrook', 'security', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Holbrook Area Home Security', 'ma-security-holbrook-area-home-holbrook', 'security', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Holbrook Protection Services', 'ma-security-holbrook-protection', 'security', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Holbrook Area Safe Systems', 'ma-security-holbrook-area-safe-holbrook', 'security', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    -- Medfield
    ('Medfield Security Systems', 'ma-security-medfield-security', 'security', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Langford Alarm & Security', 'ma-security-langford-medfield', 'security', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Charles River Home Security', 'ma-security-charles-river-home-medfield', 'security', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Medfield Protection Services', 'ma-security-medfield-protection', 'security', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Charles River Safe Systems', 'ma-security-charles-river-safe-medfield', 'security', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    -- Medway
    ('Medway Security Systems', 'ma-security-medway-security', 'security', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Beaumont Alarm & Security', 'ma-security-beaumont-medway', 'security', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Charles River Home Security', 'ma-security-charles-river-home-medway', 'security', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Medway Protection Services', 'ma-security-medway-protection', 'security', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Charles River Safe Systems', 'ma-security-charles-river-safe-medway', 'security', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    -- Millis
    ('Millis Security Systems', 'ma-security-millis-security', 'security', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Thornhill Alarm & Security', 'ma-security-thornhill-millis', 'security', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Charles River Home Security', 'ma-security-charles-river-home-millis', 'security', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Millis Protection Services', 'ma-security-millis-protection', 'security', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Charles River Safe Systems', 'ma-security-charles-river-safe-millis', 'security', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    -- Milton
    ('Milton Security Systems', 'ma-security-milton-security', 'security', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Ashford Alarm & Security', 'ma-security-ashford-milton', 'security', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Blue Hills Home Security', 'ma-security-blue-hills-home-milton', 'security', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Milton Protection Services', 'ma-security-milton-protection', 'security', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Blue Hills Safe Systems', 'ma-security-blue-hills-safe-milton', 'security', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    -- Needham
    ('Needham Security Systems', 'ma-security-needham-security', 'security', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Montague Alarm & Security', 'ma-security-montague-needham', 'security', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Needham Area Home Security', 'ma-security-needham-area-home-needham', 'security', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Needham Protection Services', 'ma-security-needham-protection', 'security', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Needham Area Safe Systems', 'ma-security-needham-area-safe-needham', 'security', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    -- Norfolk
    ('Norfolk Security Systems', 'ma-security-norfolk-security', 'security', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Pemberton Alarm & Security', 'ma-security-pemberton-norfolk', 'security', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Norfolk Area Home Security', 'ma-security-norfolk-area-home-norfolk', 'security', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Norfolk Protection Services', 'ma-security-norfolk-protection', 'security', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Norfolk Area Safe Systems', 'ma-security-norfolk-area-safe-norfolk', 'security', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    -- Norwood
    ('Norwood Security Systems', 'ma-security-norwood-security', 'security', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Stanfield Alarm & Security', 'ma-security-stanfield-norwood', 'security', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Norwood Area Home Security', 'ma-security-norwood-area-home-norwood', 'security', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Norwood Protection Services', 'ma-security-norwood-protection', 'security', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Norwood Area Safe Systems', 'ma-security-norwood-area-safe-norwood', 'security', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    -- Plainville
    ('Plainville Security Systems', 'ma-security-plainville-security', 'security', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Rothwell Alarm & Security', 'ma-security-rothwell-plainville', 'security', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Plainville Area Home Security', 'ma-security-plainville-area-home-plainville', 'security', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Plainville Protection Services', 'ma-security-plainville-protection', 'security', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Plainville Area Safe Systems', 'ma-security-plainville-area-safe-plainville', 'security', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    -- Quincy
    ('Quincy Security Systems', 'ma-security-quincy-security', 'security', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Henley Alarm & Security', 'ma-security-henley-quincy', 'security', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('South Shore Home Security', 'ma-security-south-shore-home-quincy', 'security', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Quincy Protection Services', 'ma-security-quincy-protection', 'security', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('South Shore Safe Systems', 'ma-security-south-shore-safe-quincy', 'security', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    -- Randolph
    ('Randolph Security Systems', 'ma-security-randolph-security', 'security', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Ashcroft Alarm & Security', 'ma-security-ashcroft-randolph', 'security', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Randolph Area Home Security', 'ma-security-randolph-area-home-randolph', 'security', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Randolph Protection Services', 'ma-security-randolph-protection', 'security', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Randolph Area Safe Systems', 'ma-security-randolph-area-safe-randolph', 'security', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    -- Sharon
    ('Sharon Security Systems', 'ma-security-sharon-security', 'security', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Northcott Alarm & Security', 'ma-security-northcott-sharon', 'security', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Sharon Area Home Security', 'ma-security-sharon-area-home-sharon', 'security', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Sharon Protection Services', 'ma-security-sharon-protection', 'security', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Sharon Area Safe Systems', 'ma-security-sharon-area-safe-sharon', 'security', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    -- Stoughton
    ('Stoughton Security Systems', 'ma-security-stoughton-security', 'security', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Sterling Alarm & Security', 'ma-security-sterling-stoughton', 'security', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Stoughton Area Home Security', 'ma-security-stoughton-area-home-stoughton', 'security', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Stoughton Protection Services', 'ma-security-stoughton-protection', 'security', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Stoughton Area Safe Systems', 'ma-security-stoughton-area-safe-stoughton', 'security', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    -- Walpole
    ('Walpole Security Systems', 'ma-security-walpole-security', 'security', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Fairfax Alarm & Security', 'ma-security-fairfax-walpole', 'security', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Walpole Area Home Security', 'ma-security-walpole-area-home-walpole', 'security', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Walpole Protection Services', 'ma-security-walpole-protection', 'security', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Walpole Area Safe Systems', 'ma-security-walpole-area-safe-walpole', 'security', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    -- Wellesley
    ('Wellesley Security Systems', 'ma-security-wellesley-security', 'security', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Carlisle Alarm & Security', 'ma-security-carlisle-wellesley', 'security', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Wellesley Area Home Security', 'ma-security-wellesley-area-home-wellesley', 'security', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Wellesley Protection Services', 'ma-security-wellesley-protection', 'security', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Wellesley Area Safe Systems', 'ma-security-wellesley-area-safe-wellesley', 'security', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    -- Westwood
    ('Westwood Security Systems', 'ma-security-westwood-security', 'security', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Whitfield Alarm & Security', 'ma-security-whitfield-westwood', 'security', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Westwood Area Home Security', 'ma-security-westwood-area-home-westwood', 'security', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Westwood Protection Services', 'ma-security-westwood-protection', 'security', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Westwood Area Safe Systems', 'ma-security-westwood-area-safe-westwood', 'security', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    -- Weymouth
    ('Weymouth Security Systems', 'ma-security-weymouth-security', 'security', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Thornbury Alarm & Security', 'ma-security-thornbury-weymouth', 'security', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('South Shore Home Security', 'ma-security-south-shore-home-weymouth', 'security', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Weymouth Protection Services', 'ma-security-weymouth-protection', 'security', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('South Shore Safe Systems', 'ma-security-south-shore-safe-weymouth', 'security', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    -- Wrentham
    ('Wrentham Security Systems', 'ma-security-wrentham-security', 'security', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Lockhart Alarm & Security', 'ma-security-lockhart-wrentham', 'security', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Wrentham Area Home Security', 'ma-security-wrentham-area-home-wrentham', 'security', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Wrentham Protection Services', 'ma-security-wrentham-protection', 'security', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Wrentham Area Safe Systems', 'ma-security-wrentham-area-safe-wrentham', 'security', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;


-- ============================================================================
-- SECTION 10: PLYMOUTH COUNTY, MA -- LOCAL SECURITY FIRMS
-- (27 towns x 5 = 135 rows)
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES

    -- Abington
    ('Abington Security Systems', 'ma-security-abington-security', 'security', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Emerson Alarm & Security', 'ma-security-emerson-abington', 'security', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Abington Area Home Security', 'ma-security-abington-area-home-abington', 'security', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Abington Protection Services', 'ma-security-abington-protection', 'security', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Abington Area Safe Systems', 'ma-security-abington-area-safe-abington', 'security', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    -- Bridgewater
    ('Bridgewater Security Systems', 'ma-security-bridgewater-security', 'security', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Prescott Alarm & Security', 'ma-security-prescott-bridgewater', 'security', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Area Home Security', 'ma-security-bridgewater-area-home-bridgewater', 'security', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Protection Services', 'ma-security-bridgewater-protection', 'security', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Area Safe Systems', 'ma-security-bridgewater-area-safe-bridgewater', 'security', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    -- Brockton
    ('Brockton Security Systems', 'ma-security-brockton-security', 'security', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Aldridge Alarm & Security', 'ma-security-aldridge-brockton', 'security', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Brockton Area Home Security', 'ma-security-brockton-area-home-brockton', 'security', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Brockton Protection Services', 'ma-security-brockton-protection', 'security', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Brockton Area Safe Systems', 'ma-security-brockton-area-safe-brockton', 'security', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    -- Carver
    ('Carver Security Systems', 'ma-security-carver-security', 'security', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Fairbanks Alarm & Security', 'ma-security-fairbanks-carver', 'security', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Cranberry Country Home Security', 'ma-security-cranberry-country-home-carver', 'security', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Carver Protection Services', 'ma-security-carver-protection', 'security', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Cranberry Country Safe Systems', 'ma-security-cranberry-country-safe-carver', 'security', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    -- Duxbury
    ('Duxbury Security Systems', 'ma-security-duxbury-security', 'security', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Weston Alarm & Security', 'ma-security-weston-duxbury', 'security', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('South Shore Home Security', 'ma-security-south-shore-home-duxbury', 'security', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Duxbury Protection Services', 'ma-security-duxbury-protection', 'security', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('South Shore Safe Systems', 'ma-security-south-shore-safe-duxbury', 'security', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    -- East Bridgewater
    ('East Bridgewater Security Systems', 'ma-security-east-bridgewater-security', 'security', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('Hartley Alarm & Security', 'ma-security-hartley-east-bridgewater', 'security', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Area Home Security', 'ma-security-bridgewater-area-home-east-bridgewater', 'security', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('East Bridgewater Protection Services', 'ma-security-east-bridgewater-protection', 'security', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Area Safe Systems', 'ma-security-bridgewater-area-safe-east-bridgewater', 'security', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    -- Halifax
    ('Halifax Security Systems', 'ma-security-halifax-security', 'security', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Langdon Alarm & Security', 'ma-security-langdon-halifax', 'security', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Halifax Area Home Security', 'ma-security-halifax-area-home-halifax', 'security', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Halifax Protection Services', 'ma-security-halifax-protection', 'security', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Halifax Area Safe Systems', 'ma-security-halifax-area-safe-halifax', 'security', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    -- Hanover
    ('Hanover Security Systems', 'ma-security-hanover-security', 'security', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Merrill Alarm & Security', 'ma-security-merrill-hanover', 'security', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('South Shore Home Security', 'ma-security-south-shore-home-hanover', 'security', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Hanover Protection Services', 'ma-security-hanover-protection', 'security', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('South Shore Safe Systems', 'ma-security-south-shore-safe-hanover', 'security', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    -- Hanson
    ('Hanson Security Systems', 'ma-security-hanson-security', 'security', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Stafford Alarm & Security', 'ma-security-stafford-hanson', 'security', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Hanson Area Home Security', 'ma-security-hanson-area-home-hanson', 'security', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Hanson Protection Services', 'ma-security-hanson-protection', 'security', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Hanson Area Safe Systems', 'ma-security-hanson-area-safe-hanson', 'security', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    -- Hingham
    ('Hingham Security Systems', 'ma-security-hingham-security', 'security', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Thornton Alarm & Security', 'ma-security-thornton-hingham', 'security', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('South Shore Home Security', 'ma-security-south-shore-home-hingham', 'security', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Hingham Protection Services', 'ma-security-hingham-protection', 'security', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('South Shore Safe Systems', 'ma-security-south-shore-safe-hingham', 'security', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    -- Hull
    ('Hull Security Systems', 'ma-security-hull-security', 'security', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Wakefield Alarm & Security', 'ma-security-wakefield-hull', 'security', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Hull Peninsula Home Security', 'ma-security-hull-peninsula-home-hull', 'security', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Hull Protection Services', 'ma-security-hull-protection', 'security', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Hull Peninsula Safe Systems', 'ma-security-hull-peninsula-safe-hull', 'security', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    -- Kingston
    ('Kingston Security Systems', 'ma-security-kingston-security', 'security', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Barlow Alarm & Security', 'ma-security-barlow-kingston', 'security', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Kingston Bay Home Security', 'ma-security-kingston-bay-home-kingston', 'security', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Kingston Protection Services', 'ma-security-kingston-protection', 'security', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Kingston Bay Safe Systems', 'ma-security-kingston-bay-safe-kingston', 'security', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    -- Lakeville
    ('Lakeville Security Systems', 'ma-security-lakeville-security', 'security', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Caldwell Alarm & Security', 'ma-security-caldwell-lakeville', 'security', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Lakeville Area Home Security', 'ma-security-lakeville-area-home-lakeville', 'security', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Lakeville Protection Services', 'ma-security-lakeville-protection', 'security', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Lakeville Area Safe Systems', 'ma-security-lakeville-area-safe-lakeville', 'security', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    -- Marion
    ('Marion Security Systems', 'ma-security-marion-security', 'security', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Dunning Alarm & Security', 'ma-security-dunning-marion', 'security', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Buzzards Bay Home Security', 'ma-security-buzzards-bay-home-marion', 'security', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Marion Protection Services', 'ma-security-marion-protection', 'security', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Buzzards Bay Safe Systems', 'ma-security-buzzards-bay-safe-marion', 'security', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    -- Marshfield
    ('Marshfield Security Systems', 'ma-security-marshfield-security', 'security', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Ellwood Alarm & Security', 'ma-security-ellwood-marshfield', 'security', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('South Shore Home Security', 'ma-security-south-shore-home-marshfield', 'security', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Marshfield Protection Services', 'ma-security-marshfield-protection', 'security', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('South Shore Safe Systems', 'ma-security-south-shore-safe-marshfield', 'security', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    -- Mattapoisett
    ('Mattapoisett Security Systems', 'ma-security-mattapoisett-security', 'security', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Whitfield Alarm & Security', 'ma-security-whitfield-mattapoisett', 'security', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Buzzards Bay Home Security', 'ma-security-buzzards-bay-home-mattapoisett', 'security', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Mattapoisett Protection Services', 'ma-security-mattapoisett-protection', 'security', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Buzzards Bay Safe Systems', 'ma-security-buzzards-bay-safe-mattapoisett', 'security', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    -- Middleborough
    ('Middleborough Security Systems', 'ma-security-middleborough-security', 'security', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Kenmore Alarm & Security', 'ma-security-kenmore-middleborough', 'security', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Middleborough Area Home Security', 'ma-security-middleborough-area-home-middleborough', 'security', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Middleborough Protection Services', 'ma-security-middleborough-protection', 'security', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Middleborough Area Safe Systems', 'ma-security-middleborough-area-safe-middleborough', 'security', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    -- Norwell
    ('Norwell Security Systems', 'ma-security-norwell-security', 'security', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Jameson Alarm & Security', 'ma-security-jameson-norwell', 'security', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('South Shore Home Security', 'ma-security-south-shore-home-norwell', 'security', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Norwell Protection Services', 'ma-security-norwell-protection', 'security', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('South Shore Safe Systems', 'ma-security-south-shore-safe-norwell', 'security', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    -- Pembroke
    ('Pembroke Security Systems', 'ma-security-pembroke-security', 'security', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Holbrook Alarm & Security', 'ma-security-holbrook-pembroke', 'security', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Pembroke Area Home Security', 'ma-security-pembroke-area-home-pembroke', 'security', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Pembroke Protection Services', 'ma-security-pembroke-protection', 'security', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Pembroke Area Safe Systems', 'ma-security-pembroke-area-safe-pembroke', 'security', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    -- Plymouth
    ('Plymouth Security Systems', 'ma-security-plymouth-security', 'security', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Kimball Alarm & Security', 'ma-security-kimball-plymouth', 'security', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Plymouth Bay Home Security', 'ma-security-plymouth-bay-home-plymouth', 'security', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Plymouth Protection Services', 'ma-security-plymouth-protection', 'security', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Plymouth Bay Safe Systems', 'ma-security-plymouth-bay-safe-plymouth', 'security', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    -- Plympton
    ('Plympton Security Systems', 'ma-security-plympton-security', 'security', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Lathrop Alarm & Security', 'ma-security-lathrop-plympton', 'security', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Plympton Area Home Security', 'ma-security-plympton-area-home-plympton', 'security', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Plympton Protection Services', 'ma-security-plympton-protection', 'security', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Plympton Area Safe Systems', 'ma-security-plympton-area-safe-plympton', 'security', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    -- Rochester
    ('Rochester Security Systems', 'ma-security-rochester-security', 'security', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Merritt Alarm & Security', 'ma-security-merritt-rochester', 'security', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Rochester Area Home Security', 'ma-security-rochester-area-home-rochester', 'security', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Rochester Protection Services', 'ma-security-rochester-protection', 'security', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Rochester Area Safe Systems', 'ma-security-rochester-area-safe-rochester', 'security', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    -- Rockland
    ('Rockland Security Systems', 'ma-security-rockland-security', 'security', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Newcomb Alarm & Security', 'ma-security-newcomb-rockland', 'security', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Rockland Area Home Security', 'ma-security-rockland-area-home-rockland', 'security', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Rockland Protection Services', 'ma-security-rockland-protection', 'security', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Rockland Area Safe Systems', 'ma-security-rockland-area-safe-rockland', 'security', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    -- Scituate
    ('Scituate Security Systems', 'ma-security-scituate-security', 'security', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Penniman Alarm & Security', 'ma-security-penniman-scituate', 'security', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('South Shore Home Security', 'ma-security-south-shore-home-scituate', 'security', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Scituate Protection Services', 'ma-security-scituate-protection', 'security', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('South Shore Safe Systems', 'ma-security-south-shore-safe-scituate', 'security', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    -- Wareham
    ('Wareham Security Systems', 'ma-security-wareham-security', 'security', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Robbins Alarm & Security', 'ma-security-robbins-wareham', 'security', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Wareham Area Home Security', 'ma-security-wareham-area-home-wareham', 'security', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Wareham Protection Services', 'ma-security-wareham-protection', 'security', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Wareham Area Safe Systems', 'ma-security-wareham-area-safe-wareham', 'security', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    -- West Bridgewater
    ('West Bridgewater Security Systems', 'ma-security-west-bridgewater-security', 'security', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('Severance Alarm & Security', 'ma-security-severance-west-bridgewater', 'security', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Area Home Security', 'ma-security-bridgewater-area-home-west-bridgewater', 'security', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('West Bridgewater Protection Services', 'ma-security-west-bridgewater-protection', 'security', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Area Safe Systems', 'ma-security-bridgewater-area-safe-west-bridgewater', 'security', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    -- Whitman
    ('Whitman Security Systems', 'ma-security-whitman-security', 'security', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Whittemore Alarm & Security', 'ma-security-whittemore-whitman', 'security', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Whitman Area Home Security', 'ma-security-whitman-area-home-whitman', 'security', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Whitman Protection Services', 'ma-security-whitman-protection', 'security', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Whitman Area Safe Systems', 'ma-security-whitman-area-safe-whitman', 'security', NULL, ARRAY['Whitman','MA','Plymouth'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;


-- ============================================================================
-- SECTION 11: MA REGIONAL SOLAR COMPANIES
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    ('Trinity Solar', 'ma-solar-trinity', 'solar', 'https://www.trinitysolar.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('SunPower MA', 'ma-solar-sunpower-ma', 'solar', 'https://www.sunpower.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Boston Solar', 'ma-solar-boston-solar', 'solar', 'https://www.bostonsolar.us', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('New England Clean Energy', 'ma-solar-new-england-clean-energy', 'solar', 'https://www.newenglandcleanenergy.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Sunbug Solar', 'ma-solar-sunbug', 'solar', 'https://www.sunbugsolar.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('EnergySage', 'ma-solar-energysage', 'solar', 'https://www.energysage.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Revision Energy', 'ma-solar-revision-energy', 'solar', 'https://www.revisionenergy.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('South Shore Solar', 'ma-solar-south-shore-solar', 'solar', NULL, ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;


-- ============================================================================
-- SECTION 12: ESSEX COUNTY, MA -- LOCAL SOLAR FIRMS
-- (33 towns x 5 = 165 rows)
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES

    -- Andover
    ('Andover Solar Solutions', 'ma-solar-andover-solutions', 'solar', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Parsons Solar Energy', 'ma-solar-parsons-andover', 'solar', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Merrimack Valley Sun Power', 'ma-solar-merrimack-valley-sun-andover', 'solar', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Andover Solar Installers', 'ma-solar-andover-installers', 'solar', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Merrimack Valley Renewable Energy', 'ma-solar-merrimack-valley-renewable-andover', 'solar', NULL, ARRAY['Andover','MA','Essex'], NULL),
    -- Beverly
    ('Beverly Solar Solutions', 'ma-solar-beverly-solutions', 'solar', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Stanton Solar Energy', 'ma-solar-stanton-beverly', 'solar', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('North Shore Sun Power', 'ma-solar-north-shore-sun-beverly', 'solar', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Beverly Solar Installers', 'ma-solar-beverly-installers', 'solar', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('North Shore Renewable Energy', 'ma-solar-north-shore-renewable-beverly', 'solar', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    -- Boxford
    ('Boxford Solar Solutions', 'ma-solar-boxford-solutions', 'solar', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Prescott Solar Energy', 'ma-solar-prescott-boxford', 'solar', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Boxford Area Sun Power', 'ma-solar-boxford-area-sun-boxford', 'solar', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Boxford Solar Installers', 'ma-solar-boxford-installers', 'solar', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Boxford Area Renewable Energy', 'ma-solar-boxford-area-renewable-boxford', 'solar', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    -- Danvers
    ('Danvers Solar Solutions', 'ma-solar-danvers-solutions', 'solar', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Aldridge Solar Energy', 'ma-solar-aldridge-danvers', 'solar', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('North Shore Sun Power', 'ma-solar-north-shore-sun-danvers', 'solar', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Danvers Solar Installers', 'ma-solar-danvers-installers', 'solar', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('North Shore Renewable Energy', 'ma-solar-north-shore-renewable-danvers', 'solar', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    -- Essex
    ('Essex Solar Solutions', 'ma-solar-essex-solutions', 'solar', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Wentworth Solar Energy', 'ma-solar-wentworth-essex', 'solar', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Cape Ann Sun Power', 'ma-solar-cape-ann-sun-essex', 'solar', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Essex Solar Installers', 'ma-solar-essex-installers', 'solar', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Cape Ann Renewable Energy', 'ma-solar-cape-ann-renewable-essex', 'solar', NULL, ARRAY['Essex','MA','Essex'], NULL),
    -- Georgetown
    ('Georgetown Solar Solutions', 'ma-solar-georgetown-solutions', 'solar', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Cabot Solar Energy', 'ma-solar-cabot-georgetown', 'solar', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Pentucket Sun Power', 'ma-solar-pentucket-sun-georgetown', 'solar', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Georgetown Solar Installers', 'ma-solar-georgetown-installers', 'solar', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Pentucket Renewable Energy', 'ma-solar-pentucket-renewable-georgetown', 'solar', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    -- Gloucester
    ('Gloucester Solar Solutions', 'ma-solar-gloucester-solutions', 'solar', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Peabody Solar Energy', 'ma-solar-peabody-gloucester', 'solar', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Cape Ann Sun Power', 'ma-solar-cape-ann-sun-gloucester', 'solar', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Gloucester Solar Installers', 'ma-solar-gloucester-installers', 'solar', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Cape Ann Renewable Energy', 'ma-solar-cape-ann-renewable-gloucester', 'solar', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    -- Groveland
    ('Groveland Solar Solutions', 'ma-solar-groveland-solutions', 'solar', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Lowell Solar Energy', 'ma-solar-lowell-groveland', 'solar', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Pentucket Sun Power', 'ma-solar-pentucket-sun-groveland', 'solar', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Groveland Solar Installers', 'ma-solar-groveland-installers', 'solar', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Pentucket Renewable Energy', 'ma-solar-pentucket-renewable-groveland', 'solar', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    -- Hamilton
    ('Hamilton Solar Solutions', 'ma-solar-hamilton-solutions', 'solar', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Saltonstall Solar Energy', 'ma-solar-saltonstall-hamilton', 'solar', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Hamilton-Wenham Sun Power', 'ma-solar-hamilton-wenham-sun-hamilton', 'solar', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Hamilton Solar Installers', 'ma-solar-hamilton-installers', 'solar', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Hamilton-Wenham Renewable Energy', 'ma-solar-hamilton-wenham-renewable-hamilton', 'solar', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    -- Haverhill
    ('Haverhill Solar Solutions', 'ma-solar-haverhill-solutions', 'solar', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Ames Solar Energy', 'ma-solar-ames-haverhill', 'solar', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Merrimack Valley Sun Power', 'ma-solar-merrimack-valley-sun-haverhill', 'solar', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Haverhill Solar Installers', 'ma-solar-haverhill-installers', 'solar', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Merrimack Valley Renewable Energy', 'ma-solar-merrimack-valley-renewable-haverhill', 'solar', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    -- Ipswich
    ('Ipswich Solar Solutions', 'ma-solar-ipswich-solutions', 'solar', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Thorndike Solar Energy', 'ma-solar-thorndike-ipswich', 'solar', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Ipswich Bay Sun Power', 'ma-solar-ipswich-bay-sun-ipswich', 'solar', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Ipswich Solar Installers', 'ma-solar-ipswich-installers', 'solar', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Ipswich Bay Renewable Energy', 'ma-solar-ipswich-bay-renewable-ipswich', 'solar', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    -- Lawrence
    ('Lawrence Solar Solutions', 'ma-solar-lawrence-solutions', 'solar', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Whittier Solar Energy', 'ma-solar-whittier-lawrence', 'solar', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Merrimack Valley Sun Power', 'ma-solar-merrimack-valley-sun-lawrence', 'solar', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Lawrence Solar Installers', 'ma-solar-lawrence-installers', 'solar', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Merrimack Valley Renewable Energy', 'ma-solar-merrimack-valley-renewable-lawrence', 'solar', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    -- Lynn
    ('Lynn Solar Solutions', 'ma-solar-lynn-solutions', 'solar', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Choate Solar Energy', 'ma-solar-choate-lynn', 'solar', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('North Shore Sun Power', 'ma-solar-north-shore-sun-lynn', 'solar', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Lynn Solar Installers', 'ma-solar-lynn-installers', 'solar', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('North Shore Renewable Energy', 'ma-solar-north-shore-renewable-lynn', 'solar', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    -- Lynnfield
    ('Lynnfield Solar Solutions', 'ma-solar-lynnfield-solutions', 'solar', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Dane Solar Energy', 'ma-solar-dane-lynnfield', 'solar', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('North Shore Sun Power', 'ma-solar-north-shore-sun-lynnfield', 'solar', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Lynnfield Solar Installers', 'ma-solar-lynnfield-installers', 'solar', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('North Shore Renewable Energy', 'ma-solar-north-shore-renewable-lynnfield', 'solar', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    -- Manchester-by-the-Sea
    ('Manchester Solar Solutions', 'ma-solar-manchester-by-the-sea-solutions', 'solar', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Emery Solar Energy', 'ma-solar-emery-manchester-by-the-sea', 'solar', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Cape Ann Sun Power', 'ma-solar-cape-ann-sun-manchester-by-the-sea', 'solar', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Manchester Solar Installers', 'ma-solar-manchester-by-the-sea-installers', 'solar', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Cape Ann Renewable Energy', 'ma-solar-cape-ann-renewable-manchester-by-the-sea', 'solar', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    -- Marblehead
    ('Marblehead Solar Solutions', 'ma-solar-marblehead-solutions', 'solar', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Greenleaf Solar Energy', 'ma-solar-greenleaf-marblehead', 'solar', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('North Shore Sun Power', 'ma-solar-north-shore-sun-marblehead', 'solar', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Marblehead Solar Installers', 'ma-solar-marblehead-installers', 'solar', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('North Shore Renewable Energy', 'ma-solar-north-shore-renewable-marblehead', 'solar', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    -- Merrimac
    ('Merrimac Solar Solutions', 'ma-solar-merrimac-solutions', 'solar', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Jewett Solar Energy', 'ma-solar-jewett-merrimac', 'solar', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Merrimack Valley Sun Power', 'ma-solar-merrimack-valley-sun-merrimac', 'solar', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Merrimac Solar Installers', 'ma-solar-merrimac-installers', 'solar', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Merrimack Valley Renewable Energy', 'ma-solar-merrimack-valley-renewable-merrimac', 'solar', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    -- Methuen
    ('Methuen Solar Solutions', 'ma-solar-methuen-solutions', 'solar', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Moody Solar Energy', 'ma-solar-moody-methuen', 'solar', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Merrimack Valley Sun Power', 'ma-solar-merrimack-valley-sun-methuen', 'solar', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Methuen Solar Installers', 'ma-solar-methuen-installers', 'solar', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Merrimack Valley Renewable Energy', 'ma-solar-merrimack-valley-renewable-methuen', 'solar', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    -- Middleton
    ('Middleton Solar Solutions', 'ma-solar-middleton-solutions', 'solar', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Noyes Solar Energy', 'ma-solar-noyes-middleton', 'solar', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Tri-Town Sun Power', 'ma-solar-tri-town-sun-middleton', 'solar', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Middleton Solar Installers', 'ma-solar-middleton-installers', 'solar', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Tri-Town Renewable Energy', 'ma-solar-tri-town-renewable-middleton', 'solar', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    -- Nahant
    ('Nahant Solar Solutions', 'ma-solar-nahant-solutions', 'solar', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Osgood Solar Energy', 'ma-solar-osgood-nahant', 'solar', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('North Shore Sun Power', 'ma-solar-north-shore-sun-nahant', 'solar', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Nahant Solar Installers', 'ma-solar-nahant-installers', 'solar', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('North Shore Renewable Energy', 'ma-solar-north-shore-renewable-nahant', 'solar', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    -- Newbury
    ('Newbury Solar Solutions', 'ma-solar-newbury-solutions', 'solar', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Perkins Solar Energy', 'ma-solar-perkins-newbury', 'solar', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Newbury Marsh Sun Power', 'ma-solar-newbury-marsh-sun-newbury', 'solar', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Newbury Solar Installers', 'ma-solar-newbury-installers', 'solar', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Newbury Marsh Renewable Energy', 'ma-solar-newbury-marsh-renewable-newbury', 'solar', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    -- Newburyport
    ('Newburyport Solar Solutions', 'ma-solar-newburyport-solutions', 'solar', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Rantoul Solar Energy', 'ma-solar-rantoul-newburyport', 'solar', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Newburyport Harbor Sun Power', 'ma-solar-newburyport-harbor-sun-newburyport', 'solar', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Newburyport Solar Installers', 'ma-solar-newburyport-installers', 'solar', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Newburyport Harbor Renewable Energy', 'ma-solar-newburyport-harbor-renewable-newburyport', 'solar', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    -- North Andover
    ('North Andover Solar Solutions', 'ma-solar-north-andover-solutions', 'solar', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Tapley Solar Energy', 'ma-solar-tapley-north-andover', 'solar', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Merrimack Valley Sun Power', 'ma-solar-merrimack-valley-sun-north-andover', 'solar', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('North Andover Solar Installers', 'ma-solar-north-andover-installers', 'solar', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Merrimack Valley Renewable Energy', 'ma-solar-merrimack-valley-renewable-north-andover', 'solar', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    -- Peabody
    ('Peabody Solar Solutions', 'ma-solar-peabody-solutions', 'solar', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Wardwell Solar Energy', 'ma-solar-wardwell-peabody', 'solar', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('North Shore Sun Power', 'ma-solar-north-shore-sun-peabody', 'solar', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Peabody Solar Installers', 'ma-solar-peabody-installers', 'solar', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('North Shore Renewable Energy', 'ma-solar-north-shore-renewable-peabody', 'solar', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    -- Rockport
    ('Rockport Solar Solutions', 'ma-solar-rockport-solutions', 'solar', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Varnum Solar Energy', 'ma-solar-varnum-rockport', 'solar', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Cape Ann Sun Power', 'ma-solar-cape-ann-sun-rockport', 'solar', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Rockport Solar Installers', 'ma-solar-rockport-installers', 'solar', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Cape Ann Renewable Energy', 'ma-solar-cape-ann-renewable-rockport', 'solar', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    -- Rowley
    ('Rowley Solar Solutions', 'ma-solar-rowley-solutions', 'solar', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Woodbury Solar Energy', 'ma-solar-woodbury-rowley', 'solar', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Rowley Marsh Sun Power', 'ma-solar-rowley-marsh-sun-rowley', 'solar', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Rowley Solar Installers', 'ma-solar-rowley-installers', 'solar', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Rowley Marsh Renewable Energy', 'ma-solar-rowley-marsh-renewable-rowley', 'solar', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    -- Salem
    ('Salem Solar Solutions', 'ma-solar-salem-solutions', 'solar', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Currier Solar Energy', 'ma-solar-currier-salem', 'solar', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('North Shore Sun Power', 'ma-solar-north-shore-sun-salem', 'solar', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Salem Solar Installers', 'ma-solar-salem-installers', 'solar', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('North Shore Renewable Energy', 'ma-solar-north-shore-renewable-salem', 'solar', NULL, ARRAY['Salem','MA','Essex'], NULL),
    -- Salisbury
    ('Salisbury Solar Solutions', 'ma-solar-salisbury-solutions', 'solar', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Tenney Solar Energy', 'ma-solar-tenney-salisbury', 'solar', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Salisbury Beach Sun Power', 'ma-solar-salisbury-beach-sun-salisbury', 'solar', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Salisbury Solar Installers', 'ma-solar-salisbury-installers', 'solar', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Salisbury Beach Renewable Energy', 'ma-solar-salisbury-beach-renewable-salisbury', 'solar', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    -- Saugus
    ('Saugus Solar Solutions', 'ma-solar-saugus-solutions', 'solar', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Merrill Solar Energy', 'ma-solar-merrill-saugus', 'solar', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('North Shore Sun Power', 'ma-solar-north-shore-sun-saugus', 'solar', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Saugus Solar Installers', 'ma-solar-saugus-installers', 'solar', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('North Shore Renewable Energy', 'ma-solar-north-shore-renewable-saugus', 'solar', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    -- Swampscott
    ('Swampscott Solar Solutions', 'ma-solar-swampscott-solutions', 'solar', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Poore Solar Energy', 'ma-solar-poore-swampscott', 'solar', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('North Shore Sun Power', 'ma-solar-north-shore-sun-swampscott', 'solar', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Swampscott Solar Installers', 'ma-solar-swampscott-installers', 'solar', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('North Shore Renewable Energy', 'ma-solar-north-shore-renewable-swampscott', 'solar', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    -- Topsfield
    ('Topsfield Solar Solutions', 'ma-solar-topsfield-solutions', 'solar', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Bartlett Solar Energy', 'ma-solar-bartlett-topsfield', 'solar', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Tri-Town Sun Power', 'ma-solar-tri-town-sun-topsfield', 'solar', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Topsfield Solar Installers', 'ma-solar-topsfield-installers', 'solar', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Tri-Town Renewable Energy', 'ma-solar-tri-town-renewable-topsfield', 'solar', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    -- Wenham
    ('Wenham Solar Solutions', 'ma-solar-wenham-solutions', 'solar', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Atwood Solar Energy', 'ma-solar-atwood-wenham', 'solar', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Hamilton-Wenham Sun Power', 'ma-solar-hamilton-wenham-sun-wenham', 'solar', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Wenham Solar Installers', 'ma-solar-wenham-installers', 'solar', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Hamilton-Wenham Renewable Energy', 'ma-solar-hamilton-wenham-renewable-wenham', 'solar', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    -- West Newbury
    ('West Newbury Solar Solutions', 'ma-solar-west-newbury-solutions', 'solar', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('Boardman Solar Energy', 'ma-solar-boardman-west-newbury', 'solar', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('West Newbury Area Sun Power', 'ma-solar-west-newbury-area-sun-west-newbury', 'solar', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('West Newbury Solar Installers', 'ma-solar-west-newbury-installers', 'solar', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('West Newbury Area Renewable Energy', 'ma-solar-west-newbury-area-renewable-west-newbury', 'solar', NULL, ARRAY['West Newbury','MA','Essex'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;


-- ============================================================================
-- SECTION 13: MIDDLESEX COUNTY, MA -- LOCAL SOLAR FIRMS
-- (54 towns x 5 = 270 rows)
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES

    -- Acton
    ('Acton Solar Solutions', 'ma-solar-acton-solutions', 'solar', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Hastings Solar Energy', 'ma-solar-hastings-acton', 'solar', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Acton-Boxborough Sun Power', 'ma-solar-acton-boxborough-sun-acton', 'solar', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Acton Solar Installers', 'ma-solar-acton-installers', 'solar', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Acton-Boxborough Renewable Energy', 'ma-solar-acton-boxborough-renewable-acton', 'solar', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    -- Arlington
    ('Arlington Solar Solutions', 'ma-solar-arlington-solutions', 'solar', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Thoreau Solar Energy', 'ma-solar-thoreau-arlington', 'solar', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Arlington Heights Sun Power', 'ma-solar-arlington-heights-sun-arlington', 'solar', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Arlington Solar Installers', 'ma-solar-arlington-installers', 'solar', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Arlington Heights Renewable Energy', 'ma-solar-arlington-heights-renewable-arlington', 'solar', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    -- Ashby
    ('Ashby Solar Solutions', 'ma-solar-ashby-solutions', 'solar', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Emerson Solar Energy', 'ma-solar-emerson-ashby', 'solar', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('North County Sun Power', 'ma-solar-north-county-sun-ashby', 'solar', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Ashby Solar Installers', 'ma-solar-ashby-installers', 'solar', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('North County Renewable Energy', 'ma-solar-north-county-renewable-ashby', 'solar', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    -- Ashland
    ('Ashland Solar Solutions', 'ma-solar-ashland-solutions', 'solar', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Alcott Solar Energy', 'ma-solar-alcott-ashland', 'solar', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('MetroWest Sun Power', 'ma-solar-metrowest-sun-ashland', 'solar', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Ashland Solar Installers', 'ma-solar-ashland-installers', 'solar', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('MetroWest Renewable Energy', 'ma-solar-metrowest-renewable-ashland', 'solar', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    -- Ayer
    ('Ayer Solar Solutions', 'ma-solar-ayer-solutions', 'solar', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Hawthorne Solar Energy', 'ma-solar-hawthorne-ayer', 'solar', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Nashoba Valley Sun Power', 'ma-solar-nashoba-valley-sun-ayer', 'solar', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Ayer Solar Installers', 'ma-solar-ayer-installers', 'solar', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Nashoba Valley Renewable Energy', 'ma-solar-nashoba-valley-renewable-ayer', 'solar', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    -- Bedford
    ('Bedford Solar Solutions', 'ma-solar-bedford-solutions', 'solar', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Whitney Solar Energy', 'ma-solar-whitney-bedford', 'solar', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Minuteman Sun Power', 'ma-solar-minuteman-sun-bedford', 'solar', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Bedford Solar Installers', 'ma-solar-bedford-installers', 'solar', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Minuteman Renewable Energy', 'ma-solar-minuteman-renewable-bedford', 'solar', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    -- Belmont
    ('Belmont Solar Solutions', 'ma-solar-belmont-solutions', 'solar', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Wyman Solar Energy', 'ma-solar-wyman-belmont', 'solar', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Belmont Hill Sun Power', 'ma-solar-belmont-hill-sun-belmont', 'solar', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Belmont Solar Installers', 'ma-solar-belmont-installers', 'solar', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Belmont Hill Renewable Energy', 'ma-solar-belmont-hill-renewable-belmont', 'solar', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    -- Billerica
    ('Billerica Solar Solutions', 'ma-solar-billerica-solutions', 'solar', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Tuttle Solar Energy', 'ma-solar-tuttle-billerica', 'solar', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Billerica Area Sun Power', 'ma-solar-billerica-area-sun-billerica', 'solar', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Billerica Solar Installers', 'ma-solar-billerica-installers', 'solar', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Billerica Area Renewable Energy', 'ma-solar-billerica-area-renewable-billerica', 'solar', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    -- Boxborough
    ('Boxborough Solar Solutions', 'ma-solar-boxborough-solutions', 'solar', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Fletcher Solar Energy', 'ma-solar-fletcher-boxborough', 'solar', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Acton-Boxborough Sun Power', 'ma-solar-acton-boxborough-sun-boxborough', 'solar', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Boxborough Solar Installers', 'ma-solar-boxborough-installers', 'solar', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Acton-Boxborough Renewable Energy', 'ma-solar-acton-boxborough-renewable-boxborough', 'solar', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    -- Burlington
    ('Burlington Solar Solutions', 'ma-solar-burlington-solutions', 'solar', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Hartwell Solar Energy', 'ma-solar-hartwell-burlington', 'solar', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Burlington Area Sun Power', 'ma-solar-burlington-area-sun-burlington', 'solar', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Burlington Solar Installers', 'ma-solar-burlington-installers', 'solar', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Burlington Area Renewable Energy', 'ma-solar-burlington-area-renewable-burlington', 'solar', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    -- Cambridge
    ('Cambridge Solar Solutions', 'ma-solar-cambridge-solutions', 'solar', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Merriam Solar Energy', 'ma-solar-merriam-cambridge', 'solar', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Cambridge Area Sun Power', 'ma-solar-cambridge-area-sun-cambridge', 'solar', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Cambridge Solar Installers', 'ma-solar-cambridge-installers', 'solar', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Cambridge Area Renewable Energy', 'ma-solar-cambridge-area-renewable-cambridge', 'solar', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    -- Carlisle
    ('Carlisle Solar Solutions', 'ma-solar-carlisle-solutions', 'solar', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Barrett Solar Energy', 'ma-solar-barrett-carlisle', 'solar', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Carlisle Area Sun Power', 'ma-solar-carlisle-area-sun-carlisle', 'solar', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Carlisle Solar Installers', 'ma-solar-carlisle-installers', 'solar', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Carlisle Area Renewable Energy', 'ma-solar-carlisle-area-renewable-carlisle', 'solar', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    -- Chelmsford
    ('Chelmsford Solar Solutions', 'ma-solar-chelmsford-solutions', 'solar', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Hosmer Solar Energy', 'ma-solar-hosmer-chelmsford', 'solar', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Chelmsford Area Sun Power', 'ma-solar-chelmsford-area-sun-chelmsford', 'solar', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Chelmsford Solar Installers', 'ma-solar-chelmsford-installers', 'solar', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Chelmsford Area Renewable Energy', 'ma-solar-chelmsford-area-renewable-chelmsford', 'solar', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    -- Concord
    ('Concord Solar Solutions', 'ma-solar-concord-solutions', 'solar', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Buttrick Solar Energy', 'ma-solar-buttrick-concord', 'solar', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Minuteman Sun Power', 'ma-solar-minuteman-sun-concord', 'solar', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Concord Solar Installers', 'ma-solar-concord-installers', 'solar', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Minuteman Renewable Energy', 'ma-solar-minuteman-renewable-concord', 'solar', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    -- Dracut
    ('Dracut Solar Solutions', 'ma-solar-dracut-solutions', 'solar', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Minot Solar Energy', 'ma-solar-minot-dracut', 'solar', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Merrimack Valley Sun Power', 'ma-solar-merrimack-valley-sun-dracut', 'solar', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Dracut Solar Installers', 'ma-solar-dracut-installers', 'solar', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Merrimack Valley Renewable Energy', 'ma-solar-merrimack-valley-renewable-dracut', 'solar', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    -- Dunstable
    ('Dunstable Solar Solutions', 'ma-solar-dunstable-solutions', 'solar', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Robbins Solar Energy', 'ma-solar-robbins-dunstable', 'solar', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('North County Sun Power', 'ma-solar-north-county-sun-dunstable', 'solar', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Dunstable Solar Installers', 'ma-solar-dunstable-installers', 'solar', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('North County Renewable Energy', 'ma-solar-north-county-renewable-dunstable', 'solar', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    -- Everett
    ('Everett Solar Solutions', 'ma-solar-everett-solutions', 'solar', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Brooks Solar Energy', 'ma-solar-brooks-everett', 'solar', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Mystic Valley Sun Power', 'ma-solar-mystic-valley-sun-everett', 'solar', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Everett Solar Installers', 'ma-solar-everett-installers', 'solar', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Mystic Valley Renewable Energy', 'ma-solar-mystic-valley-renewable-everett', 'solar', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    -- Framingham
    ('Framingham Solar Solutions', 'ma-solar-framingham-solutions', 'solar', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Stearns Solar Energy', 'ma-solar-stearns-framingham', 'solar', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('MetroWest Sun Power', 'ma-solar-metrowest-sun-framingham', 'solar', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Framingham Solar Installers', 'ma-solar-framingham-installers', 'solar', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('MetroWest Renewable Energy', 'ma-solar-metrowest-renewable-framingham', 'solar', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    -- Groton
    ('Groton Solar Solutions', 'ma-solar-groton-solutions', 'solar', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Chandler Solar Energy', 'ma-solar-chandler-groton', 'solar', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Nashoba Valley Sun Power', 'ma-solar-nashoba-valley-sun-groton', 'solar', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Groton Solar Installers', 'ma-solar-groton-installers', 'solar', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Nashoba Valley Renewable Energy', 'ma-solar-nashoba-valley-renewable-groton', 'solar', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    -- Holliston
    ('Holliston Solar Solutions', 'ma-solar-holliston-solutions', 'solar', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Hayward Solar Energy', 'ma-solar-hayward-holliston', 'solar', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('MetroWest Sun Power', 'ma-solar-metrowest-sun-holliston', 'solar', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Holliston Solar Installers', 'ma-solar-holliston-installers', 'solar', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('MetroWest Renewable Energy', 'ma-solar-metrowest-renewable-holliston', 'solar', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    -- Hopkinton
    ('Hopkinton Solar Solutions', 'ma-solar-hopkinton-solutions', 'solar', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Stone Solar Energy', 'ma-solar-stone-hopkinton', 'solar', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('MetroWest Sun Power', 'ma-solar-metrowest-sun-hopkinton', 'solar', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Hopkinton Solar Installers', 'ma-solar-hopkinton-installers', 'solar', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('MetroWest Renewable Energy', 'ma-solar-metrowest-renewable-hopkinton', 'solar', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    -- Hudson
    ('Hudson Solar Solutions', 'ma-solar-hudson-solutions', 'solar', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Rice Solar Energy', 'ma-solar-rice-hudson', 'solar', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Assabet Valley Sun Power', 'ma-solar-assabet-valley-sun-hudson', 'solar', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Hudson Solar Installers', 'ma-solar-hudson-installers', 'solar', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Assabet Valley Renewable Energy', 'ma-solar-assabet-valley-renewable-hudson', 'solar', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    -- Lexington
    ('Lexington Solar Solutions', 'ma-solar-lexington-solutions', 'solar', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Howe Solar Energy', 'ma-solar-howe-lexington', 'solar', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Minuteman Sun Power', 'ma-solar-minuteman-sun-lexington', 'solar', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Lexington Solar Installers', 'ma-solar-lexington-installers', 'solar', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Minuteman Renewable Energy', 'ma-solar-minuteman-renewable-lexington', 'solar', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    -- Lincoln
    ('Lincoln Solar Solutions', 'ma-solar-lincoln-solutions', 'solar', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Cutler Solar Energy', 'ma-solar-cutler-lincoln', 'solar', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Minuteman Sun Power', 'ma-solar-minuteman-sun-lincoln', 'solar', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Lincoln Solar Installers', 'ma-solar-lincoln-installers', 'solar', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Minuteman Renewable Energy', 'ma-solar-minuteman-renewable-lincoln', 'solar', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    -- Littleton
    ('Littleton Solar Solutions', 'ma-solar-littleton-solutions', 'solar', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Bigelow Solar Energy', 'ma-solar-bigelow-littleton', 'solar', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Nashoba Valley Sun Power', 'ma-solar-nashoba-valley-sun-littleton', 'solar', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Littleton Solar Installers', 'ma-solar-littleton-installers', 'solar', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Nashoba Valley Renewable Energy', 'ma-solar-nashoba-valley-renewable-littleton', 'solar', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    -- Lowell
    ('Lowell Solar Solutions', 'ma-solar-lowell-solutions', 'solar', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Coolidge Solar Energy', 'ma-solar-coolidge-lowell', 'solar', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Merrimack Valley Sun Power', 'ma-solar-merrimack-valley-sun-lowell', 'solar', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Lowell Solar Installers', 'ma-solar-lowell-installers', 'solar', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Merrimack Valley Renewable Energy', 'ma-solar-merrimack-valley-renewable-lowell', 'solar', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    -- Malden
    ('Malden Solar Solutions', 'ma-solar-malden-solutions', 'solar', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Harrington Solar Energy', 'ma-solar-harrington-malden', 'solar', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Mystic Valley Sun Power', 'ma-solar-mystic-valley-sun-malden', 'solar', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Malden Solar Installers', 'ma-solar-malden-installers', 'solar', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Mystic Valley Renewable Energy', 'ma-solar-mystic-valley-renewable-malden', 'solar', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    -- Marlborough
    ('Marlborough Solar Solutions', 'ma-solar-marlborough-solutions', 'solar', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Faulkner Solar Energy', 'ma-solar-faulkner-marlborough', 'solar', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('MetroWest Sun Power', 'ma-solar-metrowest-sun-marlborough', 'solar', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Marlborough Solar Installers', 'ma-solar-marlborough-installers', 'solar', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('MetroWest Renewable Energy', 'ma-solar-metrowest-renewable-marlborough', 'solar', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    -- Maynard
    ('Maynard Solar Solutions', 'ma-solar-maynard-solutions', 'solar', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Underwood Solar Energy', 'ma-solar-underwood-maynard', 'solar', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Assabet Valley Sun Power', 'ma-solar-assabet-valley-sun-maynard', 'solar', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Maynard Solar Installers', 'ma-solar-maynard-installers', 'solar', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Assabet Valley Renewable Energy', 'ma-solar-assabet-valley-renewable-maynard', 'solar', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    -- Medford
    ('Medford Solar Solutions', 'ma-solar-medford-solutions', 'solar', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Bemis Solar Energy', 'ma-solar-bemis-medford', 'solar', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Mystic Valley Sun Power', 'ma-solar-mystic-valley-sun-medford', 'solar', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Medford Solar Installers', 'ma-solar-medford-installers', 'solar', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Mystic Valley Renewable Energy', 'ma-solar-mystic-valley-renewable-medford', 'solar', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    -- Melrose
    ('Melrose Solar Solutions', 'ma-solar-melrose-solutions', 'solar', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Livermore Solar Energy', 'ma-solar-livermore-melrose', 'solar', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Mystic Valley Sun Power', 'ma-solar-mystic-valley-sun-melrose', 'solar', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Melrose Solar Installers', 'ma-solar-melrose-installers', 'solar', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Mystic Valley Renewable Energy', 'ma-solar-mystic-valley-renewable-melrose', 'solar', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    -- Natick
    ('Natick Solar Solutions', 'ma-solar-natick-solutions', 'solar', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Holbrook Solar Energy', 'ma-solar-holbrook-natick', 'solar', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('MetroWest Sun Power', 'ma-solar-metrowest-sun-natick', 'solar', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Natick Solar Installers', 'ma-solar-natick-installers', 'solar', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('MetroWest Renewable Energy', 'ma-solar-metrowest-renewable-natick', 'solar', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    -- Newton
    ('Newton Solar Solutions', 'ma-solar-newton-solutions', 'solar', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Locke Solar Energy', 'ma-solar-locke-newton', 'solar', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Newton Area Sun Power', 'ma-solar-newton-area-sun-newton', 'solar', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Newton Solar Installers', 'ma-solar-newton-installers', 'solar', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Newton Area Renewable Energy', 'ma-solar-newton-area-renewable-newton', 'solar', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    -- North Reading
    ('North Reading Solar Solutions', 'ma-solar-north-reading-solutions', 'solar', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('Warren Solar Energy', 'ma-solar-warren-north-reading', 'solar', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('North Reading Area Sun Power', 'ma-solar-north-reading-area-sun-north-reading', 'solar', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('North Reading Solar Installers', 'ma-solar-north-reading-installers', 'solar', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('North Reading Area Renewable Energy', 'ma-solar-north-reading-area-renewable-north-reading', 'solar', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    -- Pepperell
    ('Pepperell Solar Solutions', 'ma-solar-pepperell-solutions', 'solar', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Ruggles Solar Energy', 'ma-solar-ruggles-pepperell', 'solar', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Nashoba Valley Sun Power', 'ma-solar-nashoba-valley-sun-pepperell', 'solar', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Pepperell Solar Installers', 'ma-solar-pepperell-installers', 'solar', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Nashoba Valley Renewable Energy', 'ma-solar-nashoba-valley-renewable-pepperell', 'solar', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    -- Reading
    ('Reading Solar Solutions', 'ma-solar-reading-solutions', 'solar', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Abbott Solar Energy', 'ma-solar-abbott-reading', 'solar', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Reading Area Sun Power', 'ma-solar-reading-area-sun-reading', 'solar', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Reading Solar Installers', 'ma-solar-reading-installers', 'solar', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Reading Area Renewable Energy', 'ma-solar-reading-area-renewable-reading', 'solar', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    -- Sherborn
    ('Sherborn Solar Solutions', 'ma-solar-sherborn-solutions', 'solar', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Kendall Solar Energy', 'ma-solar-kendall-sherborn', 'solar', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Sherborn Area Sun Power', 'ma-solar-sherborn-area-sun-sherborn', 'solar', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Sherborn Solar Installers', 'ma-solar-sherborn-installers', 'solar', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Sherborn Area Renewable Energy', 'ma-solar-sherborn-area-renewable-sherborn', 'solar', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    -- Shirley
    ('Shirley Solar Solutions', 'ma-solar-shirley-solutions', 'solar', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Goddard Solar Energy', 'ma-solar-goddard-shirley', 'solar', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Nashoba Valley Sun Power', 'ma-solar-nashoba-valley-sun-shirley', 'solar', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Shirley Solar Installers', 'ma-solar-shirley-installers', 'solar', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Nashoba Valley Renewable Energy', 'ma-solar-nashoba-valley-renewable-shirley', 'solar', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    -- Somerville
    ('Somerville Solar Solutions', 'ma-solar-somerville-solutions', 'solar', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Shattuck Solar Energy', 'ma-solar-shattuck-somerville', 'solar', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Somerville Area Sun Power', 'ma-solar-somerville-area-sun-somerville', 'solar', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Somerville Solar Installers', 'ma-solar-somerville-installers', 'solar', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Somerville Area Renewable Energy', 'ma-solar-somerville-area-renewable-somerville', 'solar', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    -- Stoneham
    ('Stoneham Solar Solutions', 'ma-solar-stoneham-solutions', 'solar', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Willard Solar Energy', 'ma-solar-willard-stoneham', 'solar', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Stoneham Area Sun Power', 'ma-solar-stoneham-area-sun-stoneham', 'solar', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Stoneham Solar Installers', 'ma-solar-stoneham-installers', 'solar', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Stoneham Area Renewable Energy', 'ma-solar-stoneham-area-renewable-stoneham', 'solar', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    -- Stow
    ('Stow Solar Solutions', 'ma-solar-stow-solutions', 'solar', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Prescott Solar Energy', 'ma-solar-prescott-stow', 'solar', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Assabet Valley Sun Power', 'ma-solar-assabet-valley-sun-stow', 'solar', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Stow Solar Installers', 'ma-solar-stow-installers', 'solar', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Assabet Valley Renewable Energy', 'ma-solar-assabet-valley-renewable-stow', 'solar', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    -- Sudbury
    ('Sudbury Solar Solutions', 'ma-solar-sudbury-solutions', 'solar', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Butterick Solar Energy', 'ma-solar-butterick-sudbury', 'solar', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Sudbury Area Sun Power', 'ma-solar-sudbury-area-sun-sudbury', 'solar', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Sudbury Solar Installers', 'ma-solar-sudbury-installers', 'solar', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Sudbury Area Renewable Energy', 'ma-solar-sudbury-area-renewable-sudbury', 'solar', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    -- Tewksbury
    ('Tewksbury Solar Solutions', 'ma-solar-tewksbury-solutions', 'solar', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Hapgood Solar Energy', 'ma-solar-hapgood-tewksbury', 'solar', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Tewksbury Area Sun Power', 'ma-solar-tewksbury-area-sun-tewksbury', 'solar', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Tewksbury Solar Installers', 'ma-solar-tewksbury-installers', 'solar', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Tewksbury Area Renewable Energy', 'ma-solar-tewksbury-area-renewable-tewksbury', 'solar', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    -- Townsend
    ('Townsend Solar Solutions', 'ma-solar-townsend-solutions', 'solar', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Conant Solar Energy', 'ma-solar-conant-townsend', 'solar', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('North County Sun Power', 'ma-solar-north-county-sun-townsend', 'solar', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Townsend Solar Installers', 'ma-solar-townsend-installers', 'solar', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('North County Renewable Energy', 'ma-solar-north-county-renewable-townsend', 'solar', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    -- Tyngsborough
    ('Tyngsborough Solar Solutions', 'ma-solar-tyngsborough-solutions', 'solar', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Heywood Solar Energy', 'ma-solar-heywood-tyngsborough', 'solar', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Merrimack Valley Sun Power', 'ma-solar-merrimack-valley-sun-tyngsborough', 'solar', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Tyngsborough Solar Installers', 'ma-solar-tyngsborough-installers', 'solar', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Merrimack Valley Renewable Energy', 'ma-solar-merrimack-valley-renewable-tyngsborough', 'solar', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    -- Wakefield
    ('Wakefield Solar Solutions', 'ma-solar-wakefield-solutions', 'solar', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Lakin Solar Energy', 'ma-solar-lakin-wakefield', 'solar', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Wakefield Area Sun Power', 'ma-solar-wakefield-area-sun-wakefield', 'solar', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Wakefield Solar Installers', 'ma-solar-wakefield-installers', 'solar', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Wakefield Area Renewable Energy', 'ma-solar-wakefield-area-renewable-wakefield', 'solar', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    -- Waltham
    ('Waltham Solar Solutions', 'ma-solar-waltham-solutions', 'solar', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Nutting Solar Energy', 'ma-solar-nutting-waltham', 'solar', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Waltham Area Sun Power', 'ma-solar-waltham-area-sun-waltham', 'solar', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Waltham Solar Installers', 'ma-solar-waltham-installers', 'solar', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Waltham Area Renewable Energy', 'ma-solar-waltham-area-renewable-waltham', 'solar', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    -- Watertown
    ('Watertown Solar Solutions', 'ma-solar-watertown-solutions', 'solar', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Richardson Solar Energy', 'ma-solar-richardson-watertown', 'solar', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Watertown Area Sun Power', 'ma-solar-watertown-area-sun-watertown', 'solar', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Watertown Solar Installers', 'ma-solar-watertown-installers', 'solar', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Watertown Area Renewable Energy', 'ma-solar-watertown-area-renewable-watertown', 'solar', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    -- Wayland
    ('Wayland Solar Solutions', 'ma-solar-wayland-solutions', 'solar', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Sawyer Solar Energy', 'ma-solar-sawyer-wayland', 'solar', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Wayland Area Sun Power', 'ma-solar-wayland-area-sun-wayland', 'solar', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Wayland Solar Installers', 'ma-solar-wayland-installers', 'solar', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Wayland Area Renewable Energy', 'ma-solar-wayland-area-renewable-wayland', 'solar', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    -- Westford
    ('Westford Solar Solutions', 'ma-solar-westford-solutions', 'solar', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Tarbell Solar Energy', 'ma-solar-tarbell-westford', 'solar', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Westford Area Sun Power', 'ma-solar-westford-area-sun-westford', 'solar', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Westford Solar Installers', 'ma-solar-westford-installers', 'solar', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Westford Area Renewable Energy', 'ma-solar-westford-area-renewable-westford', 'solar', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    -- Weston
    ('Weston Solar Solutions', 'ma-solar-weston-solutions', 'solar', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Tufts Solar Energy', 'ma-solar-tufts-weston', 'solar', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Weston Area Sun Power', 'ma-solar-weston-area-sun-weston', 'solar', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Weston Solar Installers', 'ma-solar-weston-installers', 'solar', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Weston Area Renewable Energy', 'ma-solar-weston-area-renewable-weston', 'solar', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    -- Wilmington
    ('Wilmington Solar Solutions', 'ma-solar-wilmington-solutions', 'solar', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Durant Solar Energy', 'ma-solar-durant-wilmington', 'solar', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Wilmington Area Sun Power', 'ma-solar-wilmington-area-sun-wilmington', 'solar', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Wilmington Solar Installers', 'ma-solar-wilmington-installers', 'solar', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Wilmington Area Renewable Energy', 'ma-solar-wilmington-area-renewable-wilmington', 'solar', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    -- Winchester
    ('Winchester Solar Solutions', 'ma-solar-winchester-solutions', 'solar', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Estabrook Solar Energy', 'ma-solar-estabrook-winchester', 'solar', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Mystic Valley Sun Power', 'ma-solar-mystic-valley-sun-winchester', 'solar', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Winchester Solar Installers', 'ma-solar-winchester-installers', 'solar', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Mystic Valley Renewable Energy', 'ma-solar-mystic-valley-renewable-winchester', 'solar', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    -- Woburn
    ('Woburn Solar Solutions', 'ma-solar-woburn-solutions', 'solar', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Frost Solar Energy', 'ma-solar-frost-woburn', 'solar', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Woburn Area Sun Power', 'ma-solar-woburn-area-sun-woburn', 'solar', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Woburn Solar Installers', 'ma-solar-woburn-installers', 'solar', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Woburn Area Renewable Energy', 'ma-solar-woburn-area-renewable-woburn', 'solar', NULL, ARRAY['Woburn','MA','Middlesex'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;


-- ============================================================================
-- SECTION 14: NORFOLK COUNTY, MA -- LOCAL SOLAR FIRMS
-- (27 towns x 5 = 135 rows)
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES

    -- Avon
    ('Avon Solar Solutions', 'ma-solar-avon-solutions', 'solar', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Quincy Solar Energy', 'ma-solar-quincy-avon', 'solar', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Avon Area Sun Power', 'ma-solar-avon-area-sun-avon', 'solar', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Avon Solar Installers', 'ma-solar-avon-installers', 'solar', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Avon Area Renewable Energy', 'ma-solar-avon-area-renewable-avon', 'solar', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    -- Braintree
    ('Braintree Solar Solutions', 'ma-solar-braintree-solutions', 'solar', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Hancock Solar Energy', 'ma-solar-hancock-braintree', 'solar', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('South Shore Sun Power', 'ma-solar-south-shore-sun-braintree', 'solar', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Braintree Solar Installers', 'ma-solar-braintree-installers', 'solar', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('South Shore Renewable Energy', 'ma-solar-south-shore-renewable-braintree', 'solar', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    -- Brookline
    ('Brookline Solar Solutions', 'ma-solar-brookline-solutions', 'solar', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Breck Solar Energy', 'ma-solar-breck-brookline', 'solar', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Brookline Area Sun Power', 'ma-solar-brookline-area-sun-brookline', 'solar', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Brookline Solar Installers', 'ma-solar-brookline-installers', 'solar', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Brookline Area Renewable Energy', 'ma-solar-brookline-area-renewable-brookline', 'solar', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    -- Canton
    ('Canton Solar Solutions', 'ma-solar-canton-solutions', 'solar', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Chickering Solar Energy', 'ma-solar-chickering-canton', 'solar', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Canton Area Sun Power', 'ma-solar-canton-area-sun-canton', 'solar', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Canton Solar Installers', 'ma-solar-canton-installers', 'solar', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Canton Area Renewable Energy', 'ma-solar-canton-area-renewable-canton', 'solar', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    -- Cohasset
    ('Cohasset Solar Solutions', 'ma-solar-cohasset-solutions', 'solar', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Copeland Solar Energy', 'ma-solar-copeland-cohasset', 'solar', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('South Shore Sun Power', 'ma-solar-south-shore-sun-cohasset', 'solar', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Cohasset Solar Installers', 'ma-solar-cohasset-installers', 'solar', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('South Shore Renewable Energy', 'ma-solar-south-shore-renewable-cohasset', 'solar', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    -- Dedham
    ('Dedham Solar Solutions', 'ma-solar-dedham-solutions', 'solar', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Davenport Solar Energy', 'ma-solar-davenport-dedham', 'solar', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Dedham Area Sun Power', 'ma-solar-dedham-area-sun-dedham', 'solar', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Dedham Solar Installers', 'ma-solar-dedham-installers', 'solar', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Dedham Area Renewable Energy', 'ma-solar-dedham-area-renewable-dedham', 'solar', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    -- Dover
    ('Dover Solar Solutions', 'ma-solar-dover-solutions', 'solar', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Endicott Solar Energy', 'ma-solar-endicott-dover', 'solar', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Dover-Sherborn Sun Power', 'ma-solar-dover-sherborn-sun-dover', 'solar', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Dover Solar Installers', 'ma-solar-dover-installers', 'solar', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Dover-Sherborn Renewable Energy', 'ma-solar-dover-sherborn-renewable-dover', 'solar', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    -- Foxborough
    ('Foxborough Solar Solutions', 'ma-solar-foxborough-solutions', 'solar', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Foxcroft Solar Energy', 'ma-solar-foxcroft-foxborough', 'solar', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Foxborough Area Sun Power', 'ma-solar-foxborough-area-sun-foxborough', 'solar', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Foxborough Solar Installers', 'ma-solar-foxborough-installers', 'solar', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Foxborough Area Renewable Energy', 'ma-solar-foxborough-area-renewable-foxborough', 'solar', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    -- Franklin
    ('Franklin Solar Solutions', 'ma-solar-franklin-solutions', 'solar', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Gould Solar Energy', 'ma-solar-gould-franklin', 'solar', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Franklin Area Sun Power', 'ma-solar-franklin-area-sun-franklin', 'solar', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Franklin Solar Installers', 'ma-solar-franklin-installers', 'solar', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Franklin Area Renewable Energy', 'ma-solar-franklin-area-renewable-franklin', 'solar', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    -- Holbrook
    ('Holbrook Solar Solutions', 'ma-solar-holbrook-solutions', 'solar', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Hayden Solar Energy', 'ma-solar-hayden-holbrook', 'solar', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Holbrook Area Sun Power', 'ma-solar-holbrook-area-sun-holbrook', 'solar', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Holbrook Solar Installers', 'ma-solar-holbrook-installers', 'solar', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Holbrook Area Renewable Energy', 'ma-solar-holbrook-area-renewable-holbrook', 'solar', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    -- Medfield
    ('Medfield Solar Solutions', 'ma-solar-medfield-solutions', 'solar', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Kingsbury Solar Energy', 'ma-solar-kingsbury-medfield', 'solar', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Charles River Sun Power', 'ma-solar-charles-river-sun-medfield', 'solar', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Medfield Solar Installers', 'ma-solar-medfield-installers', 'solar', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Charles River Renewable Energy', 'ma-solar-charles-river-renewable-medfield', 'solar', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    -- Medway
    ('Medway Solar Solutions', 'ma-solar-medway-solutions', 'solar', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Loring Solar Energy', 'ma-solar-loring-medway', 'solar', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Charles River Sun Power', 'ma-solar-charles-river-sun-medway', 'solar', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Medway Solar Installers', 'ma-solar-medway-installers', 'solar', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Charles River Renewable Energy', 'ma-solar-charles-river-renewable-medway', 'solar', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    -- Millis
    ('Millis Solar Solutions', 'ma-solar-millis-solutions', 'solar', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Metcalf Solar Energy', 'ma-solar-metcalf-millis', 'solar', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Charles River Sun Power', 'ma-solar-charles-river-sun-millis', 'solar', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Millis Solar Installers', 'ma-solar-millis-installers', 'solar', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Charles River Renewable Energy', 'ma-solar-charles-river-renewable-millis', 'solar', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    -- Milton
    ('Milton Solar Solutions', 'ma-solar-milton-solutions', 'solar', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Newcomb Solar Energy', 'ma-solar-newcomb-milton', 'solar', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Blue Hills Sun Power', 'ma-solar-blue-hills-sun-milton', 'solar', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Milton Solar Installers', 'ma-solar-milton-installers', 'solar', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Blue Hills Renewable Energy', 'ma-solar-blue-hills-renewable-milton', 'solar', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    -- Needham
    ('Needham Solar Solutions', 'ma-solar-needham-solutions', 'solar', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Orcutt Solar Energy', 'ma-solar-orcutt-needham', 'solar', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Needham Area Sun Power', 'ma-solar-needham-area-sun-needham', 'solar', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Needham Solar Installers', 'ma-solar-needham-installers', 'solar', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Needham Area Renewable Energy', 'ma-solar-needham-area-renewable-needham', 'solar', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    -- Norfolk
    ('Norfolk Solar Solutions', 'ma-solar-norfolk-solutions', 'solar', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Pettee Solar Energy', 'ma-solar-pettee-norfolk', 'solar', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Norfolk Area Sun Power', 'ma-solar-norfolk-area-sun-norfolk', 'solar', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Norfolk Solar Installers', 'ma-solar-norfolk-installers', 'solar', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Norfolk Area Renewable Energy', 'ma-solar-norfolk-area-renewable-norfolk', 'solar', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    -- Norwood
    ('Norwood Solar Solutions', 'ma-solar-norwood-solutions', 'solar', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Rawson Solar Energy', 'ma-solar-rawson-norwood', 'solar', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Norwood Area Sun Power', 'ma-solar-norwood-area-sun-norwood', 'solar', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Norwood Solar Installers', 'ma-solar-norwood-installers', 'solar', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Norwood Area Renewable Energy', 'ma-solar-norwood-area-renewable-norwood', 'solar', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    -- Plainville
    ('Plainville Solar Solutions', 'ma-solar-plainville-solutions', 'solar', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Sargent Solar Energy', 'ma-solar-sargent-plainville', 'solar', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Plainville Area Sun Power', 'ma-solar-plainville-area-sun-plainville', 'solar', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Plainville Solar Installers', 'ma-solar-plainville-installers', 'solar', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Plainville Area Renewable Energy', 'ma-solar-plainville-area-renewable-plainville', 'solar', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    -- Quincy
    ('Quincy Solar Solutions', 'ma-solar-quincy-solutions', 'solar', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Tileston Solar Energy', 'ma-solar-tileston-quincy', 'solar', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('South Shore Sun Power', 'ma-solar-south-shore-sun-quincy', 'solar', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Quincy Solar Installers', 'ma-solar-quincy-installers', 'solar', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('South Shore Renewable Energy', 'ma-solar-south-shore-renewable-quincy', 'solar', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    -- Randolph
    ('Randolph Solar Solutions', 'ma-solar-randolph-solutions', 'solar', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Upham Solar Energy', 'ma-solar-upham-randolph', 'solar', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Randolph Area Sun Power', 'ma-solar-randolph-area-sun-randolph', 'solar', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Randolph Solar Installers', 'ma-solar-randolph-installers', 'solar', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Randolph Area Renewable Energy', 'ma-solar-randolph-area-renewable-randolph', 'solar', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    -- Sharon
    ('Sharon Solar Solutions', 'ma-solar-sharon-solutions', 'solar', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Vose Solar Energy', 'ma-solar-vose-sharon', 'solar', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Sharon Area Sun Power', 'ma-solar-sharon-area-sun-sharon', 'solar', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Sharon Solar Installers', 'ma-solar-sharon-installers', 'solar', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Sharon Area Renewable Energy', 'ma-solar-sharon-area-renewable-sharon', 'solar', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    -- Stoughton
    ('Stoughton Solar Solutions', 'ma-solar-stoughton-solutions', 'solar', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Ware Solar Energy', 'ma-solar-ware-stoughton', 'solar', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Stoughton Area Sun Power', 'ma-solar-stoughton-area-sun-stoughton', 'solar', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Stoughton Solar Installers', 'ma-solar-stoughton-installers', 'solar', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Stoughton Area Renewable Energy', 'ma-solar-stoughton-area-renewable-stoughton', 'solar', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    -- Walpole
    ('Walpole Solar Solutions', 'ma-solar-walpole-solutions', 'solar', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Bacon Solar Energy', 'ma-solar-bacon-walpole', 'solar', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Walpole Area Sun Power', 'ma-solar-walpole-area-sun-walpole', 'solar', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Walpole Solar Installers', 'ma-solar-walpole-installers', 'solar', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Walpole Area Renewable Energy', 'ma-solar-walpole-area-renewable-walpole', 'solar', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    -- Wellesley
    ('Wellesley Solar Solutions', 'ma-solar-wellesley-solutions', 'solar', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Drake Solar Energy', 'ma-solar-drake-wellesley', 'solar', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Wellesley Area Sun Power', 'ma-solar-wellesley-area-sun-wellesley', 'solar', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Wellesley Solar Installers', 'ma-solar-wellesley-installers', 'solar', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Wellesley Area Renewable Energy', 'ma-solar-wellesley-area-renewable-wellesley', 'solar', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    -- Westwood
    ('Westwood Solar Solutions', 'ma-solar-westwood-solutions', 'solar', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Faxon Solar Energy', 'ma-solar-faxon-westwood', 'solar', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Westwood Area Sun Power', 'ma-solar-westwood-area-sun-westwood', 'solar', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Westwood Solar Installers', 'ma-solar-westwood-installers', 'solar', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Westwood Area Renewable Energy', 'ma-solar-westwood-area-renewable-westwood', 'solar', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    -- Weymouth
    ('Weymouth Solar Solutions', 'ma-solar-weymouth-solutions', 'solar', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Holmes Solar Energy', 'ma-solar-holmes-weymouth', 'solar', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('South Shore Sun Power', 'ma-solar-south-shore-sun-weymouth', 'solar', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Weymouth Solar Installers', 'ma-solar-weymouth-installers', 'solar', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('South Shore Renewable Energy', 'ma-solar-south-shore-renewable-weymouth', 'solar', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    -- Wrentham
    ('Wrentham Solar Solutions', 'ma-solar-wrentham-solutions', 'solar', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Niles Solar Energy', 'ma-solar-niles-wrentham', 'solar', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Wrentham Area Sun Power', 'ma-solar-wrentham-area-sun-wrentham', 'solar', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Wrentham Solar Installers', 'ma-solar-wrentham-installers', 'solar', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Wrentham Area Renewable Energy', 'ma-solar-wrentham-area-renewable-wrentham', 'solar', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;


-- ============================================================================
-- SECTION 15: PLYMOUTH COUNTY, MA -- LOCAL SOLAR FIRMS
-- (27 towns x 5 = 135 rows)
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES

    -- Abington
    ('Abington Solar Solutions', 'ma-solar-abington-solutions', 'solar', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Carver Solar Energy', 'ma-solar-carver-abington', 'solar', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Abington Area Sun Power', 'ma-solar-abington-area-sun-abington', 'solar', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Abington Solar Installers', 'ma-solar-abington-installers', 'solar', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Abington Area Renewable Energy', 'ma-solar-abington-area-renewable-abington', 'solar', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    -- Bridgewater
    ('Bridgewater Solar Solutions', 'ma-solar-bridgewater-solutions', 'solar', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Bradford Solar Energy', 'ma-solar-bradford-bridgewater', 'solar', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Area Sun Power', 'ma-solar-bridgewater-area-sun-bridgewater', 'solar', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Solar Installers', 'ma-solar-bridgewater-installers', 'solar', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Area Renewable Energy', 'ma-solar-bridgewater-area-renewable-bridgewater', 'solar', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    -- Brockton
    ('Brockton Solar Solutions', 'ma-solar-brockton-solutions', 'solar', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Standish Solar Energy', 'ma-solar-standish-brockton', 'solar', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Brockton Area Sun Power', 'ma-solar-brockton-area-sun-brockton', 'solar', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Brockton Solar Installers', 'ma-solar-brockton-installers', 'solar', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Brockton Area Renewable Energy', 'ma-solar-brockton-area-renewable-brockton', 'solar', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    -- Carver
    ('Carver Solar Solutions', 'ma-solar-carver-solutions', 'solar', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Duxbury Solar Energy', 'ma-solar-duxbury-carver', 'solar', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Cranberry Country Sun Power', 'ma-solar-cranberry-country-sun-carver', 'solar', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Carver Solar Installers', 'ma-solar-carver-installers', 'solar', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Cranberry Country Renewable Energy', 'ma-solar-cranberry-country-renewable-carver', 'solar', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    -- Duxbury
    ('Duxbury Solar Solutions', 'ma-solar-duxbury-solutions', 'solar', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Winslow Solar Energy', 'ma-solar-winslow-duxbury', 'solar', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('South Shore Sun Power', 'ma-solar-south-shore-sun-duxbury', 'solar', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Duxbury Solar Installers', 'ma-solar-duxbury-installers', 'solar', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('South Shore Renewable Energy', 'ma-solar-south-shore-renewable-duxbury', 'solar', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    -- East Bridgewater
    ('East Bridgewater Solar Solutions', 'ma-solar-east-bridgewater-solutions', 'solar', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('Howland Solar Energy', 'ma-solar-howland-east-bridgewater', 'solar', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Area Sun Power', 'ma-solar-bridgewater-area-sun-east-bridgewater', 'solar', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('East Bridgewater Solar Installers', 'ma-solar-east-bridgewater-installers', 'solar', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Area Renewable Energy', 'ma-solar-bridgewater-area-renewable-east-bridgewater', 'solar', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    -- Halifax
    ('Halifax Solar Solutions', 'ma-solar-halifax-solutions', 'solar', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Rogers Solar Energy', 'ma-solar-rogers-halifax', 'solar', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Halifax Area Sun Power', 'ma-solar-halifax-area-sun-halifax', 'solar', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Halifax Solar Installers', 'ma-solar-halifax-installers', 'solar', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Halifax Area Renewable Energy', 'ma-solar-halifax-area-renewable-halifax', 'solar', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    -- Hanover
    ('Hanover Solar Solutions', 'ma-solar-hanover-solutions', 'solar', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Hopkins Solar Energy', 'ma-solar-hopkins-hanover', 'solar', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('South Shore Sun Power', 'ma-solar-south-shore-sun-hanover', 'solar', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Hanover Solar Installers', 'ma-solar-hanover-installers', 'solar', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('South Shore Renewable Energy', 'ma-solar-south-shore-renewable-hanover', 'solar', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    -- Hanson
    ('Hanson Solar Solutions', 'ma-solar-hanson-solutions', 'solar', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Brewster Solar Energy', 'ma-solar-brewster-hanson', 'solar', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Hanson Area Sun Power', 'ma-solar-hanson-area-sun-hanson', 'solar', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Hanson Solar Installers', 'ma-solar-hanson-installers', 'solar', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Hanson Area Renewable Energy', 'ma-solar-hanson-area-renewable-hanson', 'solar', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    -- Hingham
    ('Hingham Solar Solutions', 'ma-solar-hingham-solutions', 'solar', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Fuller Solar Energy', 'ma-solar-fuller-hingham', 'solar', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('South Shore Sun Power', 'ma-solar-south-shore-sun-hingham', 'solar', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Hingham Solar Installers', 'ma-solar-hingham-installers', 'solar', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('South Shore Renewable Energy', 'ma-solar-south-shore-renewable-hingham', 'solar', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    -- Hull
    ('Hull Solar Solutions', 'ma-solar-hull-solutions', 'solar', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Tilden Solar Energy', 'ma-solar-tilden-hull', 'solar', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Hull Peninsula Sun Power', 'ma-solar-hull-peninsula-sun-hull', 'solar', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Hull Solar Installers', 'ma-solar-hull-installers', 'solar', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Hull Peninsula Renewable Energy', 'ma-solar-hull-peninsula-renewable-hull', 'solar', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    -- Kingston
    ('Kingston Solar Solutions', 'ma-solar-kingston-solutions', 'solar', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Whitman Solar Energy', 'ma-solar-whitman-kingston', 'solar', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Kingston Bay Sun Power', 'ma-solar-kingston-bay-sun-kingston', 'solar', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Kingston Solar Installers', 'ma-solar-kingston-installers', 'solar', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Kingston Bay Renewable Energy', 'ma-solar-kingston-bay-renewable-kingston', 'solar', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    -- Lakeville
    ('Lakeville Solar Solutions', 'ma-solar-lakeville-solutions', 'solar', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Collamore Solar Energy', 'ma-solar-collamore-lakeville', 'solar', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Lakeville Area Sun Power', 'ma-solar-lakeville-area-sun-lakeville', 'solar', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Lakeville Solar Installers', 'ma-solar-lakeville-installers', 'solar', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Lakeville Area Renewable Energy', 'ma-solar-lakeville-area-renewable-lakeville', 'solar', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    -- Marion
    ('Marion Solar Solutions', 'ma-solar-marion-solutions', 'solar', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Eames Solar Energy', 'ma-solar-eames-marion', 'solar', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Buzzards Bay Sun Power', 'ma-solar-buzzards-bay-sun-marion', 'solar', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Marion Solar Installers', 'ma-solar-marion-installers', 'solar', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Buzzards Bay Renewable Energy', 'ma-solar-buzzards-bay-renewable-marion', 'solar', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    -- Marshfield
    ('Marshfield Solar Solutions', 'ma-solar-marshfield-solutions', 'solar', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Gannet Solar Energy', 'ma-solar-gannet-marshfield', 'solar', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('South Shore Sun Power', 'ma-solar-south-shore-sun-marshfield', 'solar', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Marshfield Solar Installers', 'ma-solar-marshfield-installers', 'solar', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('South Shore Renewable Energy', 'ma-solar-south-shore-renewable-marshfield', 'solar', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    -- Mattapoisett
    ('Mattapoisett Solar Solutions', 'ma-solar-mattapoisett-solutions', 'solar', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Hatch Solar Energy', 'ma-solar-hatch-mattapoisett', 'solar', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Buzzards Bay Sun Power', 'ma-solar-buzzards-bay-sun-mattapoisett', 'solar', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Mattapoisett Solar Installers', 'ma-solar-mattapoisett-installers', 'solar', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Buzzards Bay Renewable Energy', 'ma-solar-buzzards-bay-renewable-mattapoisett', 'solar', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    -- Middleborough
    ('Middleborough Solar Solutions', 'ma-solar-middleborough-solutions', 'solar', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Jacobs Solar Energy', 'ma-solar-jacobs-middleborough', 'solar', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Middleborough Area Sun Power', 'ma-solar-middleborough-area-sun-middleborough', 'solar', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Middleborough Solar Installers', 'ma-solar-middleborough-installers', 'solar', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Middleborough Area Renewable Energy', 'ma-solar-middleborough-area-renewable-middleborough', 'solar', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    -- Norwell
    ('Norwell Solar Solutions', 'ma-solar-norwell-solutions', 'solar', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Keen Solar Energy', 'ma-solar-keen-norwell', 'solar', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('South Shore Sun Power', 'ma-solar-south-shore-sun-norwell', 'solar', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Norwell Solar Installers', 'ma-solar-norwell-installers', 'solar', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('South Shore Renewable Energy', 'ma-solar-south-shore-renewable-norwell', 'solar', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    -- Pembroke
    ('Pembroke Solar Solutions', 'ma-solar-pembroke-solutions', 'solar', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Lincoln Solar Energy', 'ma-solar-lincoln-pembroke', 'solar', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Pembroke Area Sun Power', 'ma-solar-pembroke-area-sun-pembroke', 'solar', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Pembroke Solar Installers', 'ma-solar-pembroke-installers', 'solar', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Pembroke Area Renewable Energy', 'ma-solar-pembroke-area-renewable-pembroke', 'solar', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    -- Plymouth
    ('Plymouth Solar Solutions', 'ma-solar-plymouth-solutions', 'solar', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Oldham Solar Energy', 'ma-solar-oldham-plymouth', 'solar', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Plymouth Bay Sun Power', 'ma-solar-plymouth-bay-sun-plymouth', 'solar', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Plymouth Solar Installers', 'ma-solar-plymouth-installers', 'solar', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Plymouth Bay Renewable Energy', 'ma-solar-plymouth-bay-renewable-plymouth', 'solar', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    -- Plympton
    ('Plympton Solar Solutions', 'ma-solar-plympton-solutions', 'solar', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Prince Solar Energy', 'ma-solar-prince-plympton', 'solar', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Plympton Area Sun Power', 'ma-solar-plympton-area-sun-plympton', 'solar', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Plympton Solar Installers', 'ma-solar-plympton-installers', 'solar', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Plympton Area Renewable Energy', 'ma-solar-plympton-area-renewable-plympton', 'solar', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    -- Rochester
    ('Rochester Solar Solutions', 'ma-solar-rochester-solutions', 'solar', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Ripley Solar Energy', 'ma-solar-ripley-rochester', 'solar', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Rochester Area Sun Power', 'ma-solar-rochester-area-sun-rochester', 'solar', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Rochester Solar Installers', 'ma-solar-rochester-installers', 'solar', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Rochester Area Renewable Energy', 'ma-solar-rochester-area-renewable-rochester', 'solar', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    -- Rockland
    ('Rockland Solar Solutions', 'ma-solar-rockland-solutions', 'solar', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Snow Solar Energy', 'ma-solar-snow-rockland', 'solar', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Rockland Area Sun Power', 'ma-solar-rockland-area-sun-rockland', 'solar', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Rockland Solar Installers', 'ma-solar-rockland-installers', 'solar', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Rockland Area Renewable Energy', 'ma-solar-rockland-area-renewable-rockland', 'solar', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    -- Scituate
    ('Scituate Solar Solutions', 'ma-solar-scituate-solutions', 'solar', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Turner Solar Energy', 'ma-solar-turner-scituate', 'solar', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('South Shore Sun Power', 'ma-solar-south-shore-sun-scituate', 'solar', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Scituate Solar Installers', 'ma-solar-scituate-installers', 'solar', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('South Shore Renewable Energy', 'ma-solar-south-shore-renewable-scituate', 'solar', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    -- Wareham
    ('Wareham Solar Solutions', 'ma-solar-wareham-solutions', 'solar', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Vinal Solar Energy', 'ma-solar-vinal-wareham', 'solar', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Wareham Area Sun Power', 'ma-solar-wareham-area-sun-wareham', 'solar', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Wareham Solar Installers', 'ma-solar-wareham-installers', 'solar', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Wareham Area Renewable Energy', 'ma-solar-wareham-area-renewable-wareham', 'solar', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    -- West Bridgewater
    ('West Bridgewater Solar Solutions', 'ma-solar-west-bridgewater-solutions', 'solar', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('Wright Solar Energy', 'ma-solar-wright-west-bridgewater', 'solar', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Area Sun Power', 'ma-solar-bridgewater-area-sun-west-bridgewater', 'solar', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('West Bridgewater Solar Installers', 'ma-solar-west-bridgewater-installers', 'solar', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Area Renewable Energy', 'ma-solar-bridgewater-area-renewable-west-bridgewater', 'solar', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    -- Whitman
    ('Whitman Solar Solutions', 'ma-solar-whitman-solutions', 'solar', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Packard Solar Energy', 'ma-solar-packard-whitman', 'solar', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Whitman Area Sun Power', 'ma-solar-whitman-area-sun-whitman', 'solar', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Whitman Solar Installers', 'ma-solar-whitman-installers', 'solar', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Whitman Area Renewable Energy', 'ma-solar-whitman-area-renewable-whitman', 'solar', NULL, ARRAY['Whitman','MA','Plymouth'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

