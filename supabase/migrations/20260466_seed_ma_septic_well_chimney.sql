-- Seed septic, well water, and chimney sweep companies into utility_providers
-- for 4 Massachusetts counties: Essex, Middlesex, Norfolk, Plymouth (141 towns).
--
-- These three trade categories are high-priority for suburban/rural HNW
-- homeowners in Greater Boston. Septic pumping is legally required every
-- 2-3 years (Title 5), well water testing is recommended annually, and
-- chimney sweeping is a safety/insurance prerequisite for wood-burning homes.
--
-- This migration covers:
--   Sections 1-5:  SEPTIC (provider_type = 'septic_pumper')
--   Sections 6-10: WELL WATER (provider_type = 'well_water_service')
--   Sections 11-15: CHIMNEY (provider_type = 'chimney_sweep')
--
-- Each group has 1 regional section + 4 county sections (5 per town).
-- All logo_url = NULL (resolved via Brandfetch on first picker render).
-- ON CONFLICT (slug) DO UPDATE ensures idempotent re-runs.

-- ============================================================
-- SECTION 1: MA REGIONAL SEPTIC COMPANIES
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    ('Borden Septic', 'ma-septic-borden', 'septic_pumper', 'https://www.bordenseptic.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Septic Preservation Services', 'ma-septic-preservation-services', 'septic_pumper', 'https://www.septicpreservation.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Wind River Environmental', 'ma-septic-wind-river', 'septic_pumper', 'https://www.windriverenvironmental.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Sullivan Environmental', 'ma-septic-sullivan-environmental', 'septic_pumper', 'https://www.sullivanenvironmental.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('EcoClean Septic', 'ma-septic-ecoclean', 'septic_pumper', 'https://www.ecocleanseptic.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Bay State Septic Services', 'ma-septic-bay-state', 'septic_pumper', 'https://www.baystateseptic.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Patriot Septic', 'ma-septic-patriot', 'septic_pumper', 'https://www.patriotseptic.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Colonial Septic Service', 'ma-septic-colonial', 'septic_pumper', 'https://www.colonialsepticservice.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 2: ESSEX COUNTY LOCAL SEPTIC (33 towns x 5)
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Andover
    ('Andover Septic Service', 'ma-septic-andover-septic-service', 'septic_pumper', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Sullivan Septic Pumping', 'ma-septic-sullivan-andover', 'septic_pumper', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Merrimack Septic Solutions', 'ma-septic-merrimack-andover', 'septic_pumper', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Andover Septic & Drain', 'ma-septic-andover-drain', 'septic_pumper', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Shawsheen Waste Services', 'ma-septic-shawsheen-andover', 'septic_pumper', NULL, ARRAY['Andover','MA','Essex'], NULL),

    -- Beverly
    ('Beverly Septic Service', 'ma-septic-beverly-septic-service', 'septic_pumper', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Harrington Septic Pumping', 'ma-septic-harrington-beverly', 'septic_pumper', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('North Shore Septic Solutions', 'ma-septic-north-shore-beverly', 'septic_pumper', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Beverly Septic & Drain', 'ma-septic-beverly-drain', 'septic_pumper', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Bass River Waste Services', 'ma-septic-bass-river-beverly', 'septic_pumper', NULL, ARRAY['Beverly','MA','Essex'], NULL),

    -- Boxford
    ('Boxford Septic Service', 'ma-septic-boxford-septic-service', 'septic_pumper', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Kelleher Septic Pumping', 'ma-septic-kelleher-boxford', 'septic_pumper', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Boxford Septic Solutions', 'ma-septic-boxford-solutions', 'septic_pumper', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Boxford Septic & Drain', 'ma-septic-boxford-drain', 'septic_pumper', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Hovey Waste Services', 'ma-septic-hovey-boxford', 'septic_pumper', NULL, ARRAY['Boxford','MA','Essex'], NULL),

    -- Danvers
    ('Danvers Septic Service', 'ma-septic-danvers-septic-service', 'septic_pumper', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Petralia Septic Pumping', 'ma-septic-petralia-danvers', 'septic_pumper', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Danvers Septic Solutions', 'ma-septic-danvers-solutions', 'septic_pumper', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Danvers Septic & Drain', 'ma-septic-danvers-drain', 'septic_pumper', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Endicott Waste Services', 'ma-septic-endicott-danvers', 'septic_pumper', NULL, ARRAY['Danvers','MA','Essex'], NULL),

    -- Essex
    ('Essex Septic Service', 'ma-septic-essex-septic-service', 'septic_pumper', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Burnham Septic Pumping', 'ma-septic-burnham-essex', 'septic_pumper', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Essex Septic Solutions', 'ma-septic-essex-solutions', 'septic_pumper', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Essex Septic & Drain', 'ma-septic-essex-drain', 'septic_pumper', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Cape Ann Waste Services', 'ma-septic-cape-ann-essex', 'septic_pumper', NULL, ARRAY['Essex','MA','Essex'], NULL),

    -- Georgetown
    ('Georgetown Septic Service', 'ma-septic-georgetown-septic-service', 'septic_pumper', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Thurlow Septic Pumping', 'ma-septic-thurlow-georgetown', 'septic_pumper', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Georgetown Septic Solutions', 'ma-septic-georgetown-solutions', 'septic_pumper', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Georgetown Septic & Drain', 'ma-septic-georgetown-drain', 'septic_pumper', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Pentucket Waste Services', 'ma-septic-pentucket-georgetown', 'septic_pumper', NULL, ARRAY['Georgetown','MA','Essex'], NULL),

    -- Gloucester
    ('Gloucester Septic Service', 'ma-septic-gloucester-septic-service', 'septic_pumper', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Favazza Septic Pumping', 'ma-septic-favazza-gloucester', 'septic_pumper', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Cape Ann Septic Solutions', 'ma-septic-cape-ann-gloucester', 'septic_pumper', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Gloucester Septic & Drain', 'ma-septic-gloucester-drain', 'septic_pumper', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Harbor Waste Services', 'ma-septic-harbor-gloucester', 'septic_pumper', NULL, ARRAY['Gloucester','MA','Essex'], NULL),

    -- Groveland
    ('Groveland Septic Service', 'ma-septic-groveland-septic-service', 'septic_pumper', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Batchelder Septic Pumping', 'ma-septic-batchelder-groveland', 'septic_pumper', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Groveland Septic Solutions', 'ma-septic-groveland-solutions', 'septic_pumper', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Groveland Septic & Drain', 'ma-septic-groveland-drain', 'septic_pumper', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Merrimack Valley Waste Services', 'ma-septic-merrimack-valley-groveland', 'septic_pumper', NULL, ARRAY['Groveland','MA','Essex'], NULL),

    -- Hamilton
    ('Hamilton Septic Service', 'ma-septic-hamilton-septic-service', 'septic_pumper', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Appleton Septic Pumping', 'ma-septic-appleton-hamilton', 'septic_pumper', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Hamilton Septic Solutions', 'ma-septic-hamilton-solutions', 'septic_pumper', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Hamilton Septic & Drain', 'ma-septic-hamilton-drain', 'septic_pumper', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Wenham Waste Services', 'ma-septic-wenham-hamilton', 'septic_pumper', NULL, ARRAY['Hamilton','MA','Essex'], NULL),

    -- Haverhill
    ('Haverhill Septic Service', 'ma-septic-haverhill-septic-service', 'septic_pumper', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Moriarty Septic Pumping', 'ma-septic-moriarty-haverhill', 'septic_pumper', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Haverhill Septic Solutions', 'ma-septic-haverhill-solutions', 'septic_pumper', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Haverhill Septic & Drain', 'ma-septic-haverhill-drain', 'septic_pumper', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Bradford Waste Services', 'ma-septic-bradford-haverhill', 'septic_pumper', NULL, ARRAY['Haverhill','MA','Essex'], NULL),

    -- Ipswich
    ('Ipswich Septic Service', 'ma-septic-ipswich-septic-service', 'septic_pumper', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Goodhue Septic Pumping', 'ma-septic-goodhue-ipswich', 'septic_pumper', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Ipswich Septic Solutions', 'ma-septic-ipswich-solutions', 'septic_pumper', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Ipswich Septic & Drain', 'ma-septic-ipswich-drain', 'septic_pumper', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Plum Island Waste Services', 'ma-septic-plum-island-ipswich', 'septic_pumper', NULL, ARRAY['Ipswich','MA','Essex'], NULL),

    -- Lawrence
    ('Lawrence Septic Service', 'ma-septic-lawrence-septic-service', 'septic_pumper', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Ortiz Septic Pumping', 'ma-septic-ortiz-lawrence', 'septic_pumper', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Lawrence Septic Solutions', 'ma-septic-lawrence-solutions', 'septic_pumper', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Lawrence Septic & Drain', 'ma-septic-lawrence-drain', 'septic_pumper', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Merrimack Waste Services', 'ma-septic-merrimack-lawrence', 'septic_pumper', NULL, ARRAY['Lawrence','MA','Essex'], NULL),

    -- Lynn
    ('Lynn Septic Service', 'ma-septic-lynn-septic-service', 'septic_pumper', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Gallagher Septic Pumping', 'ma-septic-gallagher-lynn', 'septic_pumper', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Lynn Septic Solutions', 'ma-septic-lynn-solutions', 'septic_pumper', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Lynn Septic & Drain', 'ma-septic-lynn-drain', 'septic_pumper', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Saugus River Waste Services', 'ma-septic-saugus-river-lynn', 'septic_pumper', NULL, ARRAY['Lynn','MA','Essex'], NULL),

    -- Lynnfield
    ('Lynnfield Septic Service', 'ma-septic-lynnfield-septic-service', 'septic_pumper', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Connolly Septic Pumping', 'ma-septic-connolly-lynnfield', 'septic_pumper', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Lynnfield Septic Solutions', 'ma-septic-lynnfield-solutions', 'septic_pumper', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Lynnfield Septic & Drain', 'ma-septic-lynnfield-drain', 'septic_pumper', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Pillings Pond Waste Services', 'ma-septic-pillings-pond-lynnfield', 'septic_pumper', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),

    -- Manchester-by-the-Sea
    ('Manchester Septic Service', 'ma-septic-manchester-septic-service', 'septic_pumper', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Crowell Septic Pumping', 'ma-septic-crowell-manchester', 'septic_pumper', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Manchester Septic Solutions', 'ma-septic-manchester-solutions', 'septic_pumper', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Manchester Septic & Drain', 'ma-septic-manchester-drain', 'septic_pumper', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Singing Beach Waste Services', 'ma-septic-singing-beach-manchester', 'septic_pumper', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),

    -- Marblehead
    ('Marblehead Septic Service', 'ma-septic-marblehead-septic-service', 'septic_pumper', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Graves Septic Pumping', 'ma-septic-graves-marblehead', 'septic_pumper', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Marblehead Septic Solutions', 'ma-septic-marblehead-solutions', 'septic_pumper', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Marblehead Septic & Drain', 'ma-septic-marblehead-drain', 'septic_pumper', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Harbor Neck Waste Services', 'ma-septic-harbor-neck-marblehead', 'septic_pumper', NULL, ARRAY['Marblehead','MA','Essex'], NULL),

    -- Merrimac
    ('Merrimac Septic Service', 'ma-septic-merrimac-septic-service', 'septic_pumper', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Sargent Septic Pumping', 'ma-septic-sargent-merrimac', 'septic_pumper', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Merrimac Septic Solutions', 'ma-septic-merrimac-solutions', 'septic_pumper', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Merrimac Septic & Drain', 'ma-septic-merrimac-drain', 'septic_pumper', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Lake Attitash Waste Services', 'ma-septic-lake-attitash-merrimac', 'septic_pumper', NULL, ARRAY['Merrimac','MA','Essex'], NULL),

    -- Methuen
    ('Methuen Septic Service', 'ma-septic-methuen-septic-service', 'septic_pumper', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Fitzgerald Septic Pumping', 'ma-septic-fitzgerald-methuen', 'septic_pumper', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Methuen Septic Solutions', 'ma-septic-methuen-solutions', 'septic_pumper', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Methuen Septic & Drain', 'ma-septic-methuen-drain', 'septic_pumper', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Spicket River Waste Services', 'ma-septic-spicket-river-methuen', 'septic_pumper', NULL, ARRAY['Methuen','MA','Essex'], NULL),

    -- Middleton
    ('Middleton Septic Service', 'ma-septic-middleton-septic-service', 'septic_pumper', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Richardson Septic Pumping', 'ma-septic-richardson-middleton', 'septic_pumper', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Middleton Septic Solutions', 'ma-septic-middleton-solutions', 'septic_pumper', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Middleton Septic & Drain', 'ma-septic-middleton-drain', 'septic_pumper', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Ipswich River Waste Services', 'ma-septic-ipswich-river-middleton', 'septic_pumper', NULL, ARRAY['Middleton','MA','Essex'], NULL),

    -- Nahant
    ('Nahant Septic Service', 'ma-septic-nahant-septic-service', 'septic_pumper', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Tudor Septic Pumping', 'ma-septic-tudor-nahant', 'septic_pumper', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Nahant Septic Solutions', 'ma-septic-nahant-solutions', 'septic_pumper', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Nahant Septic & Drain', 'ma-septic-nahant-drain', 'septic_pumper', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Lynn Harbor Waste Services', 'ma-septic-lynn-harbor-nahant', 'septic_pumper', NULL, ARRAY['Nahant','MA','Essex'], NULL),

    -- Newbury
    ('Newbury Septic Service', 'ma-septic-newbury-septic-service', 'septic_pumper', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Noyes Septic Pumping', 'ma-septic-noyes-newbury', 'septic_pumper', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Newbury Septic Solutions', 'ma-septic-newbury-solutions', 'septic_pumper', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Newbury Septic & Drain', 'ma-septic-newbury-drain', 'septic_pumper', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Parker River Waste Services', 'ma-septic-parker-river-newbury', 'septic_pumper', NULL, ARRAY['Newbury','MA','Essex'], NULL),

    -- Newburyport
    ('Newburyport Septic Service', 'ma-septic-newburyport-septic-service', 'septic_pumper', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Coffin Septic Pumping', 'ma-septic-coffin-newburyport', 'septic_pumper', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Newburyport Septic Solutions', 'ma-septic-newburyport-solutions', 'septic_pumper', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Newburyport Septic & Drain', 'ma-septic-newburyport-drain', 'septic_pumper', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Clipper City Waste Services', 'ma-septic-clipper-city-newburyport', 'septic_pumper', NULL, ARRAY['Newburyport','MA','Essex'], NULL),

    -- North Andover
    ('North Andover Septic Service', 'ma-septic-north-andover-septic-service', 'septic_pumper', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Osgood Septic Pumping', 'ma-septic-osgood-north-andover', 'septic_pumper', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('North Andover Septic Solutions', 'ma-septic-north-andover-solutions', 'septic_pumper', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('North Andover Septic & Drain', 'ma-septic-north-andover-drain', 'septic_pumper', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Cochichewick Waste Services', 'ma-septic-cochichewick-north-andover', 'septic_pumper', NULL, ARRAY['North Andover','MA','Essex'], NULL),

    -- Peabody
    ('Peabody Septic Service', 'ma-septic-peabody-septic-service', 'septic_pumper', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Osborne Septic Pumping', 'ma-septic-osborne-peabody', 'septic_pumper', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Peabody Septic Solutions', 'ma-septic-peabody-solutions', 'septic_pumper', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Peabody Septic & Drain', 'ma-septic-peabody-drain', 'septic_pumper', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Brooksby Waste Services', 'ma-septic-brooksby-peabody', 'septic_pumper', NULL, ARRAY['Peabody','MA','Essex'], NULL),

    -- Rockport
    ('Rockport Septic Service', 'ma-septic-rockport-septic-service', 'septic_pumper', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Tarr Septic Pumping', 'ma-septic-tarr-rockport', 'septic_pumper', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Rockport Septic Solutions', 'ma-septic-rockport-solutions', 'septic_pumper', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Rockport Septic & Drain', 'ma-septic-rockport-drain', 'septic_pumper', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Halibut Point Waste Services', 'ma-septic-halibut-point-rockport', 'septic_pumper', NULL, ARRAY['Rockport','MA','Essex'], NULL),

    -- Rowley
    ('Rowley Septic Service', 'ma-septic-rowley-septic-service', 'septic_pumper', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Gage Septic Pumping', 'ma-septic-gage-rowley', 'septic_pumper', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Rowley Septic Solutions', 'ma-septic-rowley-solutions', 'septic_pumper', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Rowley Septic & Drain', 'ma-septic-rowley-drain', 'septic_pumper', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Mill River Waste Services', 'ma-septic-mill-river-rowley', 'septic_pumper', NULL, ARRAY['Rowley','MA','Essex'], NULL),

    -- Salem
    ('Salem Septic Service', 'ma-septic-salem-septic-service', 'septic_pumper', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Derby Septic Pumping', 'ma-septic-derby-salem', 'septic_pumper', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Salem Septic Solutions', 'ma-septic-salem-solutions', 'septic_pumper', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Salem Septic & Drain', 'ma-septic-salem-drain', 'septic_pumper', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Witch City Waste Services', 'ma-septic-witch-city-salem', 'septic_pumper', NULL, ARRAY['Salem','MA','Essex'], NULL),

    -- Salisbury
    ('Salisbury Septic Service', 'ma-septic-salisbury-septic-service', 'septic_pumper', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Pettengill Septic Pumping', 'ma-septic-pettengill-salisbury', 'septic_pumper', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Salisbury Septic Solutions', 'ma-septic-salisbury-solutions', 'septic_pumper', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Salisbury Septic & Drain', 'ma-septic-salisbury-drain', 'septic_pumper', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Salisbury Beach Waste Services', 'ma-septic-salisbury-beach-salisbury', 'septic_pumper', NULL, ARRAY['Salisbury','MA','Essex'], NULL),

    -- Saugus
    ('Saugus Septic Service', 'ma-septic-saugus-septic-service', 'septic_pumper', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Parsons Septic Pumping', 'ma-septic-parsons-saugus', 'septic_pumper', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Saugus Septic Solutions', 'ma-septic-saugus-solutions', 'septic_pumper', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Saugus Septic & Drain', 'ma-septic-saugus-drain', 'septic_pumper', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Saugus River Waste Services', 'ma-septic-saugus-river-saugus', 'septic_pumper', NULL, ARRAY['Saugus','MA','Essex'], NULL),

    -- Swampscott
    ('Swampscott Septic Service', 'ma-septic-swampscott-septic-service', 'septic_pumper', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Blaney Septic Pumping', 'ma-septic-blaney-swampscott', 'septic_pumper', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Swampscott Septic Solutions', 'ma-septic-swampscott-solutions', 'septic_pumper', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Swampscott Septic & Drain', 'ma-septic-swampscott-drain', 'septic_pumper', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('King Beach Waste Services', 'ma-septic-king-beach-swampscott', 'septic_pumper', NULL, ARRAY['Swampscott','MA','Essex'], NULL),

    -- Topsfield
    ('Topsfield Septic Service', 'ma-septic-topsfield-septic-service', 'septic_pumper', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Perkins Septic Pumping', 'ma-septic-perkins-topsfield', 'septic_pumper', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Topsfield Septic Solutions', 'ma-septic-topsfield-solutions', 'septic_pumper', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Topsfield Septic & Drain', 'ma-septic-topsfield-drain', 'septic_pumper', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Ipswich River Waste Services', 'ma-septic-ipswich-river-topsfield', 'septic_pumper', NULL, ARRAY['Topsfield','MA','Essex'], NULL),

    -- Wenham
    ('Wenham Septic Service', 'ma-septic-wenham-septic-service', 'septic_pumper', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Dodge Septic Pumping', 'ma-septic-dodge-wenham', 'septic_pumper', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Wenham Septic Solutions', 'ma-septic-wenham-solutions', 'septic_pumper', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Wenham Septic & Drain', 'ma-septic-wenham-drain', 'septic_pumper', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Pleasant Pond Waste Services', 'ma-septic-pleasant-pond-wenham', 'septic_pumper', NULL, ARRAY['Wenham','MA','Essex'], NULL),

    -- West Newbury
    ('West Newbury Septic Service', 'ma-septic-west-newbury-septic-service', 'septic_pumper', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('Chase Septic Pumping', 'ma-septic-chase-west-newbury', 'septic_pumper', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('West Newbury Septic Solutions', 'ma-septic-west-newbury-solutions', 'septic_pumper', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('West Newbury Septic & Drain', 'ma-septic-west-newbury-drain', 'septic_pumper', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('Indian Hill Waste Services', 'ma-septic-indian-hill-west-newbury', 'septic_pumper', NULL, ARRAY['West Newbury','MA','Essex'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 3: MIDDLESEX COUNTY LOCAL SEPTIC (54 towns x 5)
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Acton
    ('Acton Septic Service', 'ma-septic-acton-septic-service', 'septic_pumper', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Robbins Septic Pumping', 'ma-septic-robbins-acton', 'septic_pumper', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Acton Septic Solutions', 'ma-septic-acton-solutions', 'septic_pumper', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Acton Septic & Drain', 'ma-septic-acton-drain', 'septic_pumper', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Nagog Waste Services', 'ma-septic-nagog-acton', 'septic_pumper', NULL, ARRAY['Acton','MA','Middlesex'], NULL),

    -- Arlington
    ('Arlington Septic Service', 'ma-septic-arlington-septic-service', 'septic_pumper', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Peirce Septic Pumping', 'ma-septic-peirce-arlington', 'septic_pumper', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Arlington Septic Solutions', 'ma-septic-arlington-solutions', 'septic_pumper', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Arlington Septic & Drain', 'ma-septic-arlington-drain', 'septic_pumper', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Mystic Valley Waste Services', 'ma-septic-mystic-valley-arlington', 'septic_pumper', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),

    -- Ashby
    ('Ashby Septic Service', 'ma-septic-ashby-septic-service', 'septic_pumper', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Kendall Septic Pumping', 'ma-septic-kendall-ashby', 'septic_pumper', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Ashby Septic Solutions', 'ma-septic-ashby-solutions', 'septic_pumper', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Ashby Septic & Drain', 'ma-septic-ashby-drain', 'septic_pumper', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Fitchburg Road Waste Services', 'ma-septic-fitchburg-road-ashby', 'septic_pumper', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),

    -- Ashland
    ('Ashland Septic Service', 'ma-septic-ashland-septic-service', 'septic_pumper', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Warren Septic Pumping', 'ma-septic-warren-ashland', 'septic_pumper', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Ashland Septic Solutions', 'ma-septic-ashland-solutions', 'septic_pumper', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Ashland Septic & Drain', 'ma-septic-ashland-drain', 'septic_pumper', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Sudbury River Waste Services', 'ma-septic-sudbury-river-ashland', 'septic_pumper', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),

    -- Ayer
    ('Ayer Septic Service', 'ma-septic-ayer-septic-service', 'septic_pumper', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Page Septic Pumping', 'ma-septic-page-ayer', 'septic_pumper', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Ayer Septic Solutions', 'ma-septic-ayer-solutions', 'septic_pumper', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Ayer Septic & Drain', 'ma-septic-ayer-drain', 'septic_pumper', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Nashua River Waste Services', 'ma-septic-nashua-river-ayer', 'septic_pumper', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),

    -- Bedford
    ('Bedford Septic Service', 'ma-septic-bedford-septic-service', 'septic_pumper', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Lane Septic Pumping', 'ma-septic-lane-bedford', 'septic_pumper', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Bedford Septic Solutions', 'ma-septic-bedford-solutions', 'septic_pumper', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Bedford Septic & Drain', 'ma-septic-bedford-drain', 'septic_pumper', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Shawsheen Waste Services', 'ma-septic-shawsheen-bedford', 'septic_pumper', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),

    -- Belmont
    ('Belmont Septic Service', 'ma-septic-belmont-septic-service', 'septic_pumper', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Underwood Septic Pumping', 'ma-septic-underwood-belmont', 'septic_pumper', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Belmont Septic Solutions', 'ma-septic-belmont-solutions', 'septic_pumper', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Belmont Septic & Drain', 'ma-septic-belmont-drain', 'septic_pumper', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Belmont Hill Waste Services', 'ma-septic-belmont-hill-belmont', 'septic_pumper', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),

    -- Billerica
    ('Billerica Septic Service', 'ma-septic-billerica-septic-service', 'septic_pumper', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Manning Septic Pumping', 'ma-septic-manning-billerica', 'septic_pumper', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Billerica Septic Solutions', 'ma-septic-billerica-solutions', 'septic_pumper', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Billerica Septic & Drain', 'ma-septic-billerica-drain', 'septic_pumper', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Concord River Waste Services', 'ma-septic-concord-river-billerica', 'septic_pumper', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),

    -- Boxborough
    ('Boxborough Septic Service', 'ma-septic-boxborough-septic-service', 'septic_pumper', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Whitcomb Septic Pumping', 'ma-septic-whitcomb-boxborough', 'septic_pumper', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Boxborough Septic Solutions', 'ma-septic-boxborough-solutions', 'septic_pumper', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Boxborough Septic & Drain', 'ma-septic-boxborough-drain', 'septic_pumper', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Blanchard Waste Services', 'ma-septic-blanchard-boxborough', 'septic_pumper', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),

    -- Burlington
    ('Burlington Septic Service', 'ma-septic-burlington-septic-service', 'septic_pumper', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Simonds Septic Pumping', 'ma-septic-simonds-burlington', 'septic_pumper', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Burlington Septic Solutions', 'ma-septic-burlington-solutions', 'septic_pumper', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Burlington Septic & Drain', 'ma-septic-burlington-drain', 'septic_pumper', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Vine Brook Waste Services', 'ma-septic-vine-brook-burlington', 'septic_pumper', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),

    -- Cambridge
    ('Cambridge Septic Service', 'ma-septic-cambridge-septic-service', 'septic_pumper', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Longfellow Septic Pumping', 'ma-septic-longfellow-cambridge', 'septic_pumper', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Cambridge Septic Solutions', 'ma-septic-cambridge-solutions', 'septic_pumper', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Cambridge Septic & Drain', 'ma-septic-cambridge-drain', 'septic_pumper', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Charles River Waste Services', 'ma-septic-charles-river-cambridge', 'septic_pumper', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),

    -- Carlisle
    ('Carlisle Septic Service', 'ma-septic-carlisle-septic-service', 'septic_pumper', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Heald Septic Pumping', 'ma-septic-heald-carlisle', 'septic_pumper', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Carlisle Septic Solutions', 'ma-septic-carlisle-solutions', 'septic_pumper', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Carlisle Septic & Drain', 'ma-septic-carlisle-drain', 'septic_pumper', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Concord River Waste Services', 'ma-septic-concord-river-carlisle', 'septic_pumper', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),

    -- Chelmsford
    ('Chelmsford Septic Service', 'ma-septic-chelmsford-septic-service', 'septic_pumper', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Parkhurst Septic Pumping', 'ma-septic-parkhurst-chelmsford', 'septic_pumper', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Chelmsford Septic Solutions', 'ma-septic-chelmsford-solutions', 'septic_pumper', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Chelmsford Septic & Drain', 'ma-septic-chelmsford-drain', 'septic_pumper', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Merrimack Waste Services', 'ma-septic-merrimack-chelmsford', 'septic_pumper', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),

    -- Concord
    ('Concord Septic Service', 'ma-septic-concord-septic-service', 'septic_pumper', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Thoreau Septic Pumping', 'ma-septic-thoreau-concord', 'septic_pumper', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Concord Septic Solutions', 'ma-septic-concord-solutions', 'septic_pumper', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Concord Septic & Drain', 'ma-septic-concord-drain', 'septic_pumper', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Walden Waste Services', 'ma-septic-walden-concord', 'septic_pumper', NULL, ARRAY['Concord','MA','Middlesex'], NULL),

    -- Dracut
    ('Dracut Septic Service', 'ma-septic-dracut-septic-service', 'septic_pumper', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Collinsworth Septic Pumping', 'ma-septic-collinsworth-dracut', 'septic_pumper', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Dracut Septic Solutions', 'ma-septic-dracut-solutions', 'septic_pumper', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Dracut Septic & Drain', 'ma-septic-dracut-drain', 'septic_pumper', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Merrimack Waste Services', 'ma-septic-merrimack-dracut', 'septic_pumper', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),

    -- Dunstable
    ('Dunstable Septic Service', 'ma-septic-dunstable-septic-service', 'septic_pumper', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('French Septic Pumping', 'ma-septic-french-dunstable', 'septic_pumper', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Dunstable Septic Solutions', 'ma-septic-dunstable-solutions', 'septic_pumper', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Dunstable Septic & Drain', 'ma-septic-dunstable-drain', 'septic_pumper', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Salmon Brook Waste Services', 'ma-septic-salmon-brook-dunstable', 'septic_pumper', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),

    -- Everett
    ('Everett Septic Service', 'ma-septic-everett-septic-service', 'septic_pumper', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Glendale Septic Pumping', 'ma-septic-glendale-everett', 'septic_pumper', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Everett Septic Solutions', 'ma-septic-everett-solutions', 'septic_pumper', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Everett Septic & Drain', 'ma-septic-everett-drain', 'septic_pumper', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Malden River Waste Services', 'ma-septic-malden-river-everett', 'septic_pumper', NULL, ARRAY['Everett','MA','Middlesex'], NULL),

    -- Framingham
    ('Framingham Septic Service', 'ma-septic-framingham-septic-service', 'septic_pumper', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Buckley Septic Pumping', 'ma-septic-buckley-framingham', 'septic_pumper', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Framingham Septic Solutions', 'ma-septic-framingham-solutions', 'septic_pumper', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Framingham Septic & Drain', 'ma-septic-framingham-drain', 'septic_pumper', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('MetroWest Waste Services', 'ma-septic-metrowest-framingham', 'septic_pumper', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),

    -- Groton
    ('Groton Septic Service', 'ma-septic-groton-septic-service', 'septic_pumper', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Prescott Septic Pumping', 'ma-septic-prescott-groton', 'septic_pumper', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Groton Septic Solutions', 'ma-septic-groton-solutions', 'septic_pumper', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Groton Septic & Drain', 'ma-septic-groton-drain', 'septic_pumper', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Nashua River Waste Services', 'ma-septic-nashua-river-groton', 'septic_pumper', NULL, ARRAY['Groton','MA','Middlesex'], NULL),

    -- Holliston
    ('Holliston Septic Service', 'ma-septic-holliston-septic-service', 'septic_pumper', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Cutler Septic Pumping', 'ma-septic-cutler-holliston', 'septic_pumper', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Holliston Septic Solutions', 'ma-septic-holliston-solutions', 'septic_pumper', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Holliston Septic & Drain', 'ma-septic-holliston-drain', 'septic_pumper', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Bogastow Brook Waste Services', 'ma-septic-bogastow-holliston', 'septic_pumper', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),

    -- Hopkinton
    ('Hopkinton Septic Service', 'ma-septic-hopkinton-septic-service', 'septic_pumper', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Claflin Septic Pumping', 'ma-septic-claflin-hopkinton', 'septic_pumper', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Hopkinton Septic Solutions', 'ma-septic-hopkinton-solutions', 'septic_pumper', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Hopkinton Septic & Drain', 'ma-septic-hopkinton-drain', 'septic_pumper', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Whitehall Waste Services', 'ma-septic-whitehall-hopkinton', 'septic_pumper', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),

    -- Hudson
    ('Hudson Septic Service', 'ma-septic-hudson-septic-service', 'septic_pumper', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Goodale Septic Pumping', 'ma-septic-goodale-hudson', 'septic_pumper', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Hudson Septic Solutions', 'ma-septic-hudson-solutions', 'septic_pumper', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Hudson Septic & Drain', 'ma-septic-hudson-drain', 'septic_pumper', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Assabet River Waste Services', 'ma-septic-assabet-river-hudson', 'septic_pumper', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),

    -- Lexington
    ('Lexington Septic Service', 'ma-septic-lexington-septic-service', 'septic_pumper', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Hancock Septic Pumping', 'ma-septic-hancock-lexington', 'septic_pumper', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Lexington Septic Solutions', 'ma-septic-lexington-solutions', 'septic_pumper', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Lexington Septic & Drain', 'ma-septic-lexington-drain', 'septic_pumper', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Minuteman Waste Services', 'ma-septic-minuteman-lexington', 'septic_pumper', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),

    -- Lincoln
    ('Lincoln Septic Service', 'ma-septic-lincoln-septic-service', 'septic_pumper', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Codman Septic Pumping', 'ma-septic-codman-lincoln', 'septic_pumper', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Lincoln Septic Solutions', 'ma-septic-lincoln-solutions', 'septic_pumper', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Lincoln Septic & Drain', 'ma-septic-lincoln-drain', 'septic_pumper', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Farrar Pond Waste Services', 'ma-septic-farrar-pond-lincoln', 'septic_pumper', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),

    -- Littleton
    ('Littleton Septic Service', 'ma-septic-littleton-septic-service', 'septic_pumper', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Hartwell Septic Pumping', 'ma-septic-hartwell-littleton', 'septic_pumper', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Littleton Septic Solutions', 'ma-septic-littleton-solutions', 'septic_pumper', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Littleton Septic & Drain', 'ma-septic-littleton-drain', 'septic_pumper', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Nagog Pond Waste Services', 'ma-septic-nagog-pond-littleton', 'septic_pumper', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),

    -- Lowell
    ('Lowell Septic Service', 'ma-septic-lowell-septic-service', 'septic_pumper', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Maguire Septic Pumping', 'ma-septic-maguire-lowell', 'septic_pumper', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Lowell Septic Solutions', 'ma-septic-lowell-solutions', 'septic_pumper', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Lowell Septic & Drain', 'ma-septic-lowell-drain', 'septic_pumper', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Mill City Waste Services', 'ma-septic-mill-city-lowell', 'septic_pumper', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),

    -- Malden
    ('Malden Septic Service', 'ma-septic-malden-septic-service', 'septic_pumper', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Corey Septic Pumping', 'ma-septic-corey-malden', 'septic_pumper', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Malden Septic Solutions', 'ma-septic-malden-solutions', 'septic_pumper', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Malden Septic & Drain', 'ma-septic-malden-drain', 'septic_pumper', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Fellsway Waste Services', 'ma-septic-fellsway-malden', 'septic_pumper', NULL, ARRAY['Malden','MA','Middlesex'], NULL),

    -- Marlborough
    ('Marlborough Septic Service', 'ma-septic-marlborough-septic-service', 'septic_pumper', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Bigelow Septic Pumping', 'ma-septic-bigelow-marlborough', 'septic_pumper', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Marlborough Septic Solutions', 'ma-septic-marlborough-solutions', 'septic_pumper', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Marlborough Septic & Drain', 'ma-septic-marlborough-drain', 'septic_pumper', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Assabet Waste Services', 'ma-septic-assabet-marlborough', 'septic_pumper', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),

    -- Maynard
    ('Maynard Septic Service', 'ma-septic-maynard-septic-service', 'septic_pumper', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Tobin Septic Pumping', 'ma-septic-tobin-maynard', 'septic_pumper', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Maynard Septic Solutions', 'ma-septic-maynard-solutions', 'septic_pumper', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Maynard Septic & Drain', 'ma-septic-maynard-drain', 'septic_pumper', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Assabet River Waste Services', 'ma-septic-assabet-river-maynard', 'septic_pumper', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),

    -- Medford
    ('Medford Septic Service', 'ma-septic-medford-septic-service', 'septic_pumper', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Brooks Septic Pumping', 'ma-septic-brooks-medford', 'septic_pumper', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Medford Septic Solutions', 'ma-septic-medford-solutions', 'septic_pumper', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Medford Septic & Drain', 'ma-septic-medford-drain', 'septic_pumper', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Mystic River Waste Services', 'ma-septic-mystic-river-medford', 'septic_pumper', NULL, ARRAY['Medford','MA','Middlesex'], NULL),

    -- Melrose
    ('Melrose Septic Service', 'ma-septic-melrose-septic-service', 'septic_pumper', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Lynde Septic Pumping', 'ma-septic-lynde-melrose', 'septic_pumper', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Melrose Septic Solutions', 'ma-septic-melrose-solutions', 'septic_pumper', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Melrose Septic & Drain', 'ma-septic-melrose-drain', 'septic_pumper', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Ell Pond Waste Services', 'ma-septic-ell-pond-melrose', 'septic_pumper', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),

    -- Natick
    ('Natick Septic Service', 'ma-septic-natick-septic-service', 'septic_pumper', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Morse Septic Pumping', 'ma-septic-morse-natick', 'septic_pumper', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Natick Septic Solutions', 'ma-septic-natick-solutions', 'septic_pumper', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Natick Septic & Drain', 'ma-septic-natick-drain', 'septic_pumper', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Lake Cochituate Waste Services', 'ma-septic-cochituate-natick', 'septic_pumper', NULL, ARRAY['Natick','MA','Middlesex'], NULL),

    -- Newton
    ('Newton Septic Service', 'ma-septic-newton-septic-service', 'septic_pumper', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Otis Septic Pumping', 'ma-septic-otis-newton', 'septic_pumper', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Newton Septic Solutions', 'ma-septic-newton-solutions', 'septic_pumper', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Newton Septic & Drain', 'ma-septic-newton-drain', 'septic_pumper', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Crystal Lake Waste Services', 'ma-septic-crystal-lake-newton', 'septic_pumper', NULL, ARRAY['Newton','MA','Middlesex'], NULL),

    -- North Reading
    ('North Reading Septic Service', 'ma-septic-north-reading-septic-service', 'septic_pumper', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('Flint Septic Pumping', 'ma-septic-flint-north-reading', 'septic_pumper', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('North Reading Septic Solutions', 'ma-septic-north-reading-solutions', 'septic_pumper', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('North Reading Septic & Drain', 'ma-septic-north-reading-drain', 'septic_pumper', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('Martins Pond Waste Services', 'ma-septic-martins-pond-north-reading', 'septic_pumper', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),

    -- Pepperell
    ('Pepperell Septic Service', 'ma-septic-pepperell-septic-service', 'septic_pumper', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Shattuck Septic Pumping', 'ma-septic-shattuck-pepperell', 'septic_pumper', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Pepperell Septic Solutions', 'ma-septic-pepperell-solutions', 'septic_pumper', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Pepperell Septic & Drain', 'ma-septic-pepperell-drain', 'septic_pumper', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Nissitissit Waste Services', 'ma-septic-nissitissit-pepperell', 'septic_pumper', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),

    -- Reading
    ('Reading Septic Service', 'ma-septic-reading-septic-service', 'septic_pumper', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Parker Septic Pumping', 'ma-septic-parker-reading', 'septic_pumper', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Reading Septic Solutions', 'ma-septic-reading-solutions', 'septic_pumper', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Reading Septic & Drain', 'ma-septic-reading-drain', 'septic_pumper', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Ipswich River Waste Services', 'ma-septic-ipswich-river-reading', 'septic_pumper', NULL, ARRAY['Reading','MA','Middlesex'], NULL),

    -- Sherborn
    ('Sherborn Septic Service', 'ma-septic-sherborn-septic-service', 'septic_pumper', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Dowse Septic Pumping', 'ma-septic-dowse-sherborn', 'septic_pumper', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Sherborn Septic Solutions', 'ma-septic-sherborn-solutions', 'septic_pumper', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Sherborn Septic & Drain', 'ma-septic-sherborn-drain', 'septic_pumper', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Farm Pond Waste Services', 'ma-septic-farm-pond-sherborn', 'septic_pumper', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),

    -- Shirley
    ('Shirley Septic Service', 'ma-septic-shirley-septic-service', 'septic_pumper', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Longley Septic Pumping', 'ma-septic-longley-shirley', 'septic_pumper', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Shirley Septic Solutions', 'ma-septic-shirley-solutions', 'septic_pumper', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Shirley Septic & Drain', 'ma-septic-shirley-drain', 'septic_pumper', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Catacunemaug Waste Services', 'ma-septic-catacunemaug-shirley', 'septic_pumper', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),

    -- Somerville
    ('Somerville Septic Service', 'ma-septic-somerville-septic-service', 'septic_pumper', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Tufts Septic Pumping', 'ma-septic-tufts-somerville', 'septic_pumper', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Somerville Septic Solutions', 'ma-septic-somerville-solutions', 'septic_pumper', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Somerville Septic & Drain', 'ma-septic-somerville-drain', 'septic_pumper', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Davis Square Waste Services', 'ma-septic-davis-square-somerville', 'septic_pumper', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),

    -- Stoneham
    ('Stoneham Septic Service', 'ma-septic-stoneham-septic-service', 'septic_pumper', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Gould Septic Pumping', 'ma-septic-gould-stoneham', 'septic_pumper', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Stoneham Septic Solutions', 'ma-septic-stoneham-solutions', 'septic_pumper', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Stoneham Septic & Drain', 'ma-septic-stoneham-drain', 'septic_pumper', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Spot Pond Waste Services', 'ma-septic-spot-pond-stoneham', 'septic_pumper', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),

    -- Stow
    ('Stow Septic Service', 'ma-septic-stow-septic-service', 'septic_pumper', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Randall Septic Pumping', 'ma-septic-randall-stow', 'septic_pumper', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Stow Septic Solutions', 'ma-septic-stow-solutions', 'septic_pumper', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Stow Septic & Drain', 'ma-septic-stow-drain', 'septic_pumper', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Lake Boon Waste Services', 'ma-septic-lake-boon-stow', 'septic_pumper', NULL, ARRAY['Stow','MA','Middlesex'], NULL),

    -- Sudbury
    ('Sudbury Septic Service', 'ma-septic-sudbury-septic-service', 'septic_pumper', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Goodenow Septic Pumping', 'ma-septic-goodenow-sudbury', 'septic_pumper', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Sudbury Septic Solutions', 'ma-septic-sudbury-solutions', 'septic_pumper', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Sudbury Septic & Drain', 'ma-septic-sudbury-drain', 'septic_pumper', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Sudbury River Waste Services', 'ma-septic-sudbury-river-sudbury', 'septic_pumper', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),

    -- Tewksbury
    ('Tewksbury Septic Service', 'ma-septic-tewksbury-septic-service', 'septic_pumper', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Trull Septic Pumping', 'ma-septic-trull-tewksbury', 'septic_pumper', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Tewksbury Septic Solutions', 'ma-septic-tewksbury-solutions', 'septic_pumper', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Tewksbury Septic & Drain', 'ma-septic-tewksbury-drain', 'septic_pumper', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Shawsheen River Waste Services', 'ma-septic-shawsheen-river-tewksbury', 'septic_pumper', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),

    -- Townsend
    ('Townsend Septic Service', 'ma-septic-townsend-septic-service', 'septic_pumper', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Spaulding Septic Pumping', 'ma-septic-spaulding-townsend', 'septic_pumper', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Townsend Septic Solutions', 'ma-septic-townsend-solutions', 'septic_pumper', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Townsend Septic & Drain', 'ma-septic-townsend-drain', 'septic_pumper', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Squannacook Waste Services', 'ma-septic-squannacook-townsend', 'septic_pumper', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),

    -- Tyngsborough
    ('Tyngsborough Septic Service', 'ma-septic-tyngsborough-septic-service', 'septic_pumper', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Winslow Septic Pumping', 'ma-septic-winslow-tyngsborough', 'septic_pumper', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Tyngsborough Septic Solutions', 'ma-septic-tyngsborough-solutions', 'septic_pumper', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Tyngsborough Septic & Drain', 'ma-septic-tyngsborough-drain', 'septic_pumper', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Merrimack River Waste Services', 'ma-septic-merrimack-river-tyngsborough', 'septic_pumper', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),

    -- Wakefield
    ('Wakefield Septic Service', 'ma-septic-wakefield-septic-service', 'septic_pumper', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Sweetser Septic Pumping', 'ma-septic-sweetser-wakefield', 'septic_pumper', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Wakefield Septic Solutions', 'ma-septic-wakefield-solutions', 'septic_pumper', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Wakefield Septic & Drain', 'ma-septic-wakefield-drain', 'septic_pumper', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Lake Quannapowitt Waste Services', 'ma-septic-quannapowitt-wakefield', 'septic_pumper', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),

    -- Waltham
    ('Waltham Septic Service', 'ma-septic-waltham-septic-service', 'septic_pumper', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Phelps Septic Pumping', 'ma-septic-phelps-waltham', 'septic_pumper', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Waltham Septic Solutions', 'ma-septic-waltham-solutions', 'septic_pumper', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Waltham Septic & Drain', 'ma-septic-waltham-drain', 'septic_pumper', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Charles River Waste Services', 'ma-septic-charles-river-waltham', 'septic_pumper', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),

    -- Watertown
    ('Watertown Septic Service', 'ma-septic-watertown-septic-service', 'septic_pumper', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Coolidge Septic Pumping', 'ma-septic-coolidge-watertown', 'septic_pumper', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Watertown Septic Solutions', 'ma-septic-watertown-solutions', 'septic_pumper', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Watertown Septic & Drain', 'ma-septic-watertown-drain', 'septic_pumper', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Fresh Pond Waste Services', 'ma-septic-fresh-pond-watertown', 'septic_pumper', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),

    -- Wayland
    ('Wayland Septic Service', 'ma-septic-wayland-septic-service', 'septic_pumper', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Heard Septic Pumping', 'ma-septic-heard-wayland', 'septic_pumper', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Wayland Septic Solutions', 'ma-septic-wayland-solutions', 'septic_pumper', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Wayland Septic & Drain', 'ma-septic-wayland-drain', 'septic_pumper', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Dudley Pond Waste Services', 'ma-septic-dudley-pond-wayland', 'septic_pumper', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),

    -- Westford
    ('Westford Septic Service', 'ma-septic-westford-septic-service', 'septic_pumper', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Fletcher Septic Pumping', 'ma-septic-fletcher-westford', 'septic_pumper', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Westford Septic Solutions', 'ma-septic-westford-solutions', 'septic_pumper', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Westford Septic & Drain', 'ma-septic-westford-drain', 'septic_pumper', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Stony Brook Waste Services', 'ma-septic-stony-brook-westford', 'septic_pumper', NULL, ARRAY['Westford','MA','Middlesex'], NULL),

    -- Weston
    ('Weston Septic Service', 'ma-septic-weston-septic-service', 'septic_pumper', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Hobbs Septic Pumping', 'ma-septic-hobbs-weston', 'septic_pumper', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Weston Septic Solutions', 'ma-septic-weston-solutions', 'septic_pumper', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Weston Septic & Drain', 'ma-septic-weston-drain', 'septic_pumper', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Cat Rock Waste Services', 'ma-septic-cat-rock-weston', 'septic_pumper', NULL, ARRAY['Weston','MA','Middlesex'], NULL),

    -- Wilmington
    ('Wilmington Septic Service', 'ma-septic-wilmington-septic-service', 'septic_pumper', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Harnden Septic Pumping', 'ma-septic-harnden-wilmington', 'septic_pumper', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Wilmington Septic Solutions', 'ma-septic-wilmington-solutions', 'septic_pumper', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Wilmington Septic & Drain', 'ma-septic-wilmington-drain', 'septic_pumper', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Silver Lake Waste Services', 'ma-septic-silver-lake-wilmington', 'septic_pumper', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),

    -- Winchester
    ('Winchester Septic Service', 'ma-septic-winchester-septic-service', 'septic_pumper', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Symmes Septic Pumping', 'ma-septic-symmes-winchester', 'septic_pumper', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Winchester Septic Solutions', 'ma-septic-winchester-solutions', 'septic_pumper', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Winchester Septic & Drain', 'ma-septic-winchester-drain', 'septic_pumper', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Wedge Pond Waste Services', 'ma-septic-wedge-pond-winchester', 'septic_pumper', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),

    -- Woburn
    ('Woburn Septic Service', 'ma-septic-woburn-septic-service', 'septic_pumper', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Thompson Septic Pumping', 'ma-septic-thompson-woburn', 'septic_pumper', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Woburn Septic Solutions', 'ma-septic-woburn-solutions', 'septic_pumper', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Woburn Septic & Drain', 'ma-septic-woburn-drain', 'septic_pumper', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Horn Pond Waste Services', 'ma-septic-horn-pond-woburn', 'septic_pumper', NULL, ARRAY['Woburn','MA','Middlesex'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 4: NORFOLK COUNTY LOCAL SEPTIC (27 towns x 5)
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Avon
    ('Avon Septic Service', 'ma-septic-avon-septic-service', 'septic_pumper', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Littlefield Septic Pumping', 'ma-septic-littlefield-avon', 'septic_pumper', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Avon Septic Solutions', 'ma-septic-avon-solutions', 'septic_pumper', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Avon Septic & Drain', 'ma-septic-avon-drain', 'septic_pumper', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Stoughton River Waste Services', 'ma-septic-stoughton-river-avon', 'septic_pumper', NULL, ARRAY['Avon','MA','Norfolk'], NULL),

    -- Braintree
    ('Braintree Septic Service', 'ma-septic-braintree-septic-service', 'septic_pumper', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Adams Septic Pumping', 'ma-septic-adams-braintree', 'septic_pumper', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Braintree Septic Solutions', 'ma-septic-braintree-solutions', 'septic_pumper', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Braintree Septic & Drain', 'ma-septic-braintree-drain', 'septic_pumper', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Monatiquot Waste Services', 'ma-septic-monatiquot-braintree', 'septic_pumper', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),

    -- Brookline
    ('Brookline Septic Service', 'ma-septic-brookline-septic-service', 'septic_pumper', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Griggs Septic Pumping', 'ma-septic-griggs-brookline', 'septic_pumper', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Brookline Septic Solutions', 'ma-septic-brookline-solutions', 'septic_pumper', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Brookline Septic & Drain', 'ma-septic-brookline-drain', 'septic_pumper', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Muddy River Waste Services', 'ma-septic-muddy-river-brookline', 'septic_pumper', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),

    -- Canton
    ('Canton Septic Service', 'ma-septic-canton-septic-service', 'septic_pumper', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Draper Septic Pumping', 'ma-septic-draper-canton', 'septic_pumper', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Canton Septic Solutions', 'ma-septic-canton-solutions', 'septic_pumper', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Canton Septic & Drain', 'ma-septic-canton-drain', 'septic_pumper', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Neponset River Waste Services', 'ma-septic-neponset-river-canton', 'septic_pumper', NULL, ARRAY['Canton','MA','Norfolk'], NULL),

    -- Cohasset
    ('Cohasset Septic Service', 'ma-septic-cohasset-septic-service', 'septic_pumper', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Pratt Septic Pumping', 'ma-septic-pratt-cohasset', 'septic_pumper', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Cohasset Septic Solutions', 'ma-septic-cohasset-solutions', 'septic_pumper', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Cohasset Septic & Drain', 'ma-septic-cohasset-drain', 'septic_pumper', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Sandy Cove Waste Services', 'ma-septic-sandy-cove-cohasset', 'septic_pumper', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),

    -- Dedham
    ('Dedham Septic Service', 'ma-septic-dedham-septic-service', 'septic_pumper', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Fairbanks Septic Pumping', 'ma-septic-fairbanks-dedham', 'septic_pumper', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Dedham Septic Solutions', 'ma-septic-dedham-solutions', 'septic_pumper', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Dedham Septic & Drain', 'ma-septic-dedham-drain', 'septic_pumper', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Mother Brook Waste Services', 'ma-septic-mother-brook-dedham', 'septic_pumper', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),

    -- Dover
    ('Dover Septic Service', 'ma-septic-dover-septic-service', 'septic_pumper', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Chickering Septic Pumping', 'ma-septic-chickering-dover', 'septic_pumper', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Dover Septic Solutions', 'ma-septic-dover-solutions', 'septic_pumper', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Dover Septic & Drain', 'ma-septic-dover-drain', 'septic_pumper', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Charles River Waste Services', 'ma-septic-charles-river-dover', 'septic_pumper', NULL, ARRAY['Dover','MA','Norfolk'], NULL),

    -- Foxborough
    ('Foxborough Septic Service', 'ma-septic-foxborough-septic-service', 'septic_pumper', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Carpenter Septic Pumping', 'ma-septic-carpenter-foxborough', 'septic_pumper', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Foxborough Septic Solutions', 'ma-septic-foxborough-solutions', 'septic_pumper', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Foxborough Septic & Drain', 'ma-septic-foxborough-drain', 'septic_pumper', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Cocasset Waste Services', 'ma-septic-cocasset-foxborough', 'septic_pumper', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),

    -- Franklin
    ('Franklin Septic Service', 'ma-septic-franklin-septic-service', 'septic_pumper', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Metcalf Septic Pumping', 'ma-septic-metcalf-franklin', 'septic_pumper', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Franklin Septic Solutions', 'ma-septic-franklin-solutions', 'septic_pumper', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Franklin Septic & Drain', 'ma-septic-franklin-drain', 'septic_pumper', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Mine Brook Waste Services', 'ma-septic-mine-brook-franklin', 'septic_pumper', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),

    -- Holbrook
    ('Holbrook Septic Service', 'ma-septic-holbrook-septic-service', 'septic_pumper', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Mann Septic Pumping', 'ma-septic-mann-holbrook', 'septic_pumper', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Holbrook Septic Solutions', 'ma-septic-holbrook-solutions', 'septic_pumper', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Holbrook Septic & Drain', 'ma-septic-holbrook-drain', 'septic_pumper', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Cochato Waste Services', 'ma-septic-cochato-holbrook', 'septic_pumper', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),

    -- Medfield
    ('Medfield Septic Service', 'ma-septic-medfield-septic-service', 'septic_pumper', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Allen Septic Pumping', 'ma-septic-allen-medfield', 'septic_pumper', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Medfield Septic Solutions', 'ma-septic-medfield-solutions', 'septic_pumper', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Medfield Septic & Drain', 'ma-septic-medfield-drain', 'septic_pumper', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Charles River Waste Services', 'ma-septic-charles-river-medfield', 'septic_pumper', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),

    -- Medway
    ('Medway Septic Service', 'ma-septic-medway-septic-service', 'septic_pumper', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Lovering Septic Pumping', 'ma-septic-lovering-medway', 'septic_pumper', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Medway Septic Solutions', 'ma-septic-medway-solutions', 'septic_pumper', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Medway Septic & Drain', 'ma-septic-medway-drain', 'septic_pumper', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Chicken Brook Waste Services', 'ma-septic-chicken-brook-medway', 'septic_pumper', NULL, ARRAY['Medway','MA','Norfolk'], NULL),

    -- Millis
    ('Millis Septic Service', 'ma-septic-millis-septic-service', 'septic_pumper', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Richardson Septic Pumping', 'ma-septic-richardson-millis', 'septic_pumper', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Millis Septic Solutions', 'ma-septic-millis-solutions', 'septic_pumper', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Millis Septic & Drain', 'ma-septic-millis-drain', 'septic_pumper', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Bogastow Waste Services', 'ma-septic-bogastow-millis', 'septic_pumper', NULL, ARRAY['Millis','MA','Norfolk'], NULL),

    -- Milton
    ('Milton Septic Service', 'ma-septic-milton-septic-service', 'septic_pumper', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Tucker Septic Pumping', 'ma-septic-tucker-milton', 'septic_pumper', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Milton Septic Solutions', 'ma-septic-milton-solutions', 'septic_pumper', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Milton Septic & Drain', 'ma-septic-milton-drain', 'septic_pumper', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Neponset Waste Services', 'ma-septic-neponset-milton', 'septic_pumper', NULL, ARRAY['Milton','MA','Norfolk'], NULL),

    -- Needham
    ('Needham Septic Service', 'ma-septic-needham-septic-service', 'septic_pumper', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Kingsbury Septic Pumping', 'ma-septic-kingsbury-needham', 'septic_pumper', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Needham Septic Solutions', 'ma-septic-needham-solutions', 'septic_pumper', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Needham Septic & Drain', 'ma-septic-needham-drain', 'septic_pumper', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Charles River Waste Services', 'ma-septic-charles-river-needham', 'septic_pumper', NULL, ARRAY['Needham','MA','Norfolk'], NULL),

    -- Norfolk
    ('Norfolk Septic Service', 'ma-septic-norfolk-septic-service', 'septic_pumper', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Mann Septic Pumping', 'ma-septic-mann-norfolk', 'septic_pumper', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Norfolk Septic Solutions', 'ma-septic-norfolk-solutions', 'septic_pumper', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Norfolk Septic & Drain', 'ma-septic-norfolk-drain', 'septic_pumper', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Stop River Waste Services', 'ma-septic-stop-river-norfolk', 'septic_pumper', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),

    -- Norwood
    ('Norwood Septic Service', 'ma-septic-norwood-septic-service', 'septic_pumper', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Guild Septic Pumping', 'ma-septic-guild-norwood', 'septic_pumper', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Norwood Septic Solutions', 'ma-septic-norwood-solutions', 'septic_pumper', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Norwood Septic & Drain', 'ma-septic-norwood-drain', 'septic_pumper', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Hawes Brook Waste Services', 'ma-septic-hawes-brook-norwood', 'septic_pumper', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),

    -- Plainville
    ('Plainville Septic Service', 'ma-septic-plainville-septic-service', 'septic_pumper', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Shepardson Septic Pumping', 'ma-septic-shepardson-plainville', 'septic_pumper', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Plainville Septic Solutions', 'ma-septic-plainville-solutions', 'septic_pumper', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Plainville Septic & Drain', 'ma-septic-plainville-drain', 'septic_pumper', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Ten Mile Waste Services', 'ma-septic-ten-mile-plainville', 'septic_pumper', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),

    -- Quincy
    ('Quincy Septic Service', 'ma-septic-quincy-septic-service', 'septic_pumper', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Brackett Septic Pumping', 'ma-septic-brackett-quincy', 'septic_pumper', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Quincy Septic Solutions', 'ma-septic-quincy-solutions', 'septic_pumper', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Quincy Septic & Drain', 'ma-septic-quincy-drain', 'septic_pumper', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Granite City Waste Services', 'ma-septic-granite-city-quincy', 'septic_pumper', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),

    -- Randolph
    ('Randolph Septic Service', 'ma-septic-randolph-septic-service', 'septic_pumper', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Turner Septic Pumping', 'ma-septic-turner-randolph', 'septic_pumper', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Randolph Septic Solutions', 'ma-septic-randolph-solutions', 'septic_pumper', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Randolph Septic & Drain', 'ma-septic-randolph-drain', 'septic_pumper', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Ponkapoag Waste Services', 'ma-septic-ponkapoag-randolph', 'septic_pumper', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),

    -- Sharon
    ('Sharon Septic Service', 'ma-septic-sharon-septic-service', 'septic_pumper', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Billings Septic Pumping', 'ma-septic-billings-sharon', 'septic_pumper', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Sharon Septic Solutions', 'ma-septic-sharon-solutions', 'septic_pumper', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Sharon Septic & Drain', 'ma-septic-sharon-drain', 'septic_pumper', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Massapoag Waste Services', 'ma-septic-massapoag-sharon', 'septic_pumper', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),

    -- Stoughton
    ('Stoughton Septic Service', 'ma-septic-stoughton-septic-service', 'septic_pumper', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Porter Septic Pumping', 'ma-septic-porter-stoughton', 'septic_pumper', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Stoughton Septic Solutions', 'ma-septic-stoughton-solutions', 'septic_pumper', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Stoughton Septic & Drain', 'ma-septic-stoughton-drain', 'septic_pumper', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Muddy Pond Waste Services', 'ma-septic-muddy-pond-stoughton', 'septic_pumper', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),

    -- Walpole
    ('Walpole Septic Service', 'ma-septic-walpole-septic-service', 'septic_pumper', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Lewis Septic Pumping', 'ma-septic-lewis-walpole', 'septic_pumper', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Walpole Septic Solutions', 'ma-septic-walpole-solutions', 'septic_pumper', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Walpole Septic & Drain', 'ma-septic-walpole-drain', 'septic_pumper', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Neponset Waste Services', 'ma-septic-neponset-walpole', 'septic_pumper', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),

    -- Wellesley
    ('Wellesley Septic Service', 'ma-septic-wellesley-septic-service', 'septic_pumper', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Hunnewell Septic Pumping', 'ma-septic-hunnewell-wellesley', 'septic_pumper', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Wellesley Septic Solutions', 'ma-septic-wellesley-solutions', 'septic_pumper', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Wellesley Septic & Drain', 'ma-septic-wellesley-drain', 'septic_pumper', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Charles River Waste Services', 'ma-septic-charles-river-wellesley', 'septic_pumper', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),

    -- Westwood
    ('Westwood Septic Service', 'ma-septic-westwood-septic-service', 'septic_pumper', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Fisher Septic Pumping', 'ma-septic-fisher-westwood', 'septic_pumper', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Westwood Septic Solutions', 'ma-septic-westwood-solutions', 'septic_pumper', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Westwood Septic & Drain', 'ma-septic-westwood-drain', 'septic_pumper', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Buckmaster Pond Waste Services', 'ma-septic-buckmaster-pond-westwood', 'septic_pumper', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),

    -- Weymouth
    ('Weymouth Septic Service', 'ma-septic-weymouth-septic-service', 'septic_pumper', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Nash Septic Pumping', 'ma-septic-nash-weymouth', 'septic_pumper', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Weymouth Septic Solutions', 'ma-septic-weymouth-solutions', 'septic_pumper', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Weymouth Septic & Drain', 'ma-septic-weymouth-drain', 'septic_pumper', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Whitman Pond Waste Services', 'ma-septic-whitman-pond-weymouth', 'septic_pumper', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),

    -- Wrentham
    ('Wrentham Septic Service', 'ma-septic-wrentham-septic-service', 'septic_pumper', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Hawes Septic Pumping', 'ma-septic-hawes-wrentham', 'septic_pumper', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Wrentham Septic Solutions', 'ma-septic-wrentham-solutions', 'septic_pumper', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Wrentham Septic & Drain', 'ma-septic-wrentham-drain', 'septic_pumper', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Eagle Brook Waste Services', 'ma-septic-eagle-brook-wrentham', 'septic_pumper', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 5: PLYMOUTH COUNTY LOCAL SEPTIC (27 towns x 5)
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Abington
    ('Abington Septic Service', 'ma-septic-abington-septic-service', 'septic_pumper', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Reed Septic Pumping', 'ma-septic-reed-abington', 'septic_pumper', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Abington Septic Solutions', 'ma-septic-abington-solutions', 'septic_pumper', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Abington Septic & Drain', 'ma-septic-abington-drain', 'septic_pumper', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Shumatuscacant Waste Services', 'ma-septic-shumatuscacant-abington', 'septic_pumper', NULL, ARRAY['Abington','MA','Plymouth'], NULL),

    -- Bridgewater
    ('Bridgewater Septic Service', 'ma-septic-bridgewater-septic-service', 'septic_pumper', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Keith Septic Pumping', 'ma-septic-keith-bridgewater', 'septic_pumper', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Septic Solutions', 'ma-septic-bridgewater-solutions', 'septic_pumper', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Septic & Drain', 'ma-septic-bridgewater-drain', 'septic_pumper', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Town River Waste Services', 'ma-septic-town-river-bridgewater', 'septic_pumper', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),

    -- Brockton
    ('Brockton Septic Service', 'ma-septic-brockton-septic-service', 'septic_pumper', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Howard Septic Pumping', 'ma-septic-howard-brockton', 'septic_pumper', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Brockton Septic Solutions', 'ma-septic-brockton-solutions', 'septic_pumper', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Brockton Septic & Drain', 'ma-septic-brockton-drain', 'septic_pumper', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Salisbury Brook Waste Services', 'ma-septic-salisbury-brook-brockton', 'septic_pumper', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),

    -- Carver
    ('Carver Septic Service', 'ma-septic-carver-septic-service', 'septic_pumper', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Shurtleff Septic Pumping', 'ma-septic-shurtleff-carver', 'septic_pumper', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Carver Septic Solutions', 'ma-septic-carver-solutions', 'septic_pumper', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Carver Septic & Drain', 'ma-septic-carver-drain', 'septic_pumper', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Cranberry Bog Waste Services', 'ma-septic-cranberry-bog-carver', 'septic_pumper', NULL, ARRAY['Carver','MA','Plymouth'], NULL),

    -- Duxbury
    ('Duxbury Septic Service', 'ma-septic-duxbury-septic-service', 'septic_pumper', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Standish Septic Pumping', 'ma-septic-standish-duxbury', 'septic_pumper', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Duxbury Septic Solutions', 'ma-septic-duxbury-solutions', 'septic_pumper', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Duxbury Septic & Drain', 'ma-septic-duxbury-drain', 'septic_pumper', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Duxbury Bay Waste Services', 'ma-septic-duxbury-bay-duxbury', 'septic_pumper', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),

    -- East Bridgewater
    ('East Bridgewater Septic Service', 'ma-septic-east-bridgewater-septic-service', 'septic_pumper', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('Whitman Septic Pumping', 'ma-septic-whitman-east-bridgewater', 'septic_pumper', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('East Bridgewater Septic Solutions', 'ma-septic-east-bridgewater-solutions', 'septic_pumper', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('East Bridgewater Septic & Drain', 'ma-septic-east-bridgewater-drain', 'septic_pumper', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('Satucket River Waste Services', 'ma-septic-satucket-river-east-bridgewater', 'septic_pumper', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),

    -- Halifax
    ('Halifax Septic Service', 'ma-septic-halifax-septic-service', 'septic_pumper', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Thompson Septic Pumping', 'ma-septic-thompson-halifax', 'septic_pumper', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Halifax Septic Solutions', 'ma-septic-halifax-solutions', 'septic_pumper', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Halifax Septic & Drain', 'ma-septic-halifax-drain', 'septic_pumper', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Monponsett Waste Services', 'ma-septic-monponsett-halifax', 'septic_pumper', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),

    -- Hanover
    ('Hanover Septic Service', 'ma-septic-hanover-septic-service', 'septic_pumper', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Stetson Septic Pumping', 'ma-septic-stetson-hanover', 'septic_pumper', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Hanover Septic Solutions', 'ma-septic-hanover-solutions', 'septic_pumper', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Hanover Septic & Drain', 'ma-septic-hanover-drain', 'septic_pumper', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Indian Head Waste Services', 'ma-septic-indian-head-hanover', 'septic_pumper', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),

    -- Hanson
    ('Hanson Septic Service', 'ma-septic-hanson-septic-service', 'septic_pumper', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Phillips Septic Pumping', 'ma-septic-phillips-hanson', 'septic_pumper', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Hanson Septic Solutions', 'ma-septic-hanson-solutions', 'septic_pumper', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Hanson Septic & Drain', 'ma-septic-hanson-drain', 'septic_pumper', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Maquan Pond Waste Services', 'ma-septic-maquan-pond-hanson', 'septic_pumper', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),

    -- Hingham
    ('Hingham Septic Service', 'ma-septic-hingham-septic-service', 'septic_pumper', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Lincoln Septic Pumping', 'ma-septic-lincoln-hingham', 'septic_pumper', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Hingham Septic Solutions', 'ma-septic-hingham-solutions', 'septic_pumper', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Hingham Septic & Drain', 'ma-septic-hingham-drain', 'septic_pumper', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Hingham Harbor Waste Services', 'ma-septic-hingham-harbor-hingham', 'septic_pumper', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),

    -- Hull
    ('Hull Septic Service', 'ma-septic-hull-septic-service', 'septic_pumper', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Mitchell Septic Pumping', 'ma-septic-mitchell-hull', 'septic_pumper', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Hull Septic Solutions', 'ma-septic-hull-solutions', 'septic_pumper', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Hull Septic & Drain', 'ma-septic-hull-drain', 'septic_pumper', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Nantasket Waste Services', 'ma-septic-nantasket-hull', 'septic_pumper', NULL, ARRAY['Hull','MA','Plymouth'], NULL),

    -- Kingston
    ('Kingston Septic Service', 'ma-septic-kingston-septic-service', 'septic_pumper', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Bradford Septic Pumping', 'ma-septic-bradford-kingston', 'septic_pumper', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Kingston Septic Solutions', 'ma-septic-kingston-solutions', 'septic_pumper', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Kingston Septic & Drain', 'ma-septic-kingston-drain', 'septic_pumper', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Jones River Waste Services', 'ma-septic-jones-river-kingston', 'septic_pumper', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),

    -- Lakeville
    ('Lakeville Septic Service', 'ma-septic-lakeville-septic-service', 'septic_pumper', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Haskins Septic Pumping', 'ma-septic-haskins-lakeville', 'septic_pumper', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Lakeville Septic Solutions', 'ma-septic-lakeville-solutions', 'septic_pumper', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Lakeville Septic & Drain', 'ma-septic-lakeville-drain', 'septic_pumper', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Assawompset Waste Services', 'ma-septic-assawompset-lakeville', 'septic_pumper', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),

    -- Marion
    ('Marion Septic Service', 'ma-septic-marion-septic-service', 'septic_pumper', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Delano Septic Pumping', 'ma-septic-delano-marion', 'septic_pumper', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Marion Septic Solutions', 'ma-septic-marion-solutions', 'septic_pumper', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Marion Septic & Drain', 'ma-septic-marion-drain', 'septic_pumper', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Sippican Harbor Waste Services', 'ma-septic-sippican-harbor-marion', 'septic_pumper', NULL, ARRAY['Marion','MA','Plymouth'], NULL),

    -- Marshfield
    ('Marshfield Septic Service', 'ma-septic-marshfield-septic-service', 'septic_pumper', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Winslow Septic Pumping', 'ma-septic-winslow-marshfield', 'septic_pumper', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Marshfield Septic Solutions', 'ma-septic-marshfield-solutions', 'septic_pumper', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Marshfield Septic & Drain', 'ma-septic-marshfield-drain', 'septic_pumper', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Green Harbor Waste Services', 'ma-septic-green-harbor-marshfield', 'septic_pumper', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),

    -- Mattapoisett
    ('Mattapoisett Septic Service', 'ma-septic-mattapoisett-septic-service', 'septic_pumper', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Cannon Septic Pumping', 'ma-septic-cannon-mattapoisett', 'septic_pumper', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Mattapoisett Septic Solutions', 'ma-septic-mattapoisett-solutions', 'septic_pumper', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Mattapoisett Septic & Drain', 'ma-septic-mattapoisett-drain', 'septic_pumper', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Mattapoisett Harbor Waste Services', 'ma-septic-mattapoisett-harbor-mattapoisett', 'septic_pumper', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),

    -- Middleborough
    ('Middleborough Septic Service', 'ma-septic-middleborough-septic-service', 'septic_pumper', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Wood Septic Pumping', 'ma-septic-wood-middleborough', 'septic_pumper', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Middleborough Septic Solutions', 'ma-septic-middleborough-solutions', 'septic_pumper', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Middleborough Septic & Drain', 'ma-septic-middleborough-drain', 'septic_pumper', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Nemasket Waste Services', 'ma-septic-nemasket-middleborough', 'septic_pumper', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),

    -- Norwell
    ('Norwell Septic Service', 'ma-septic-norwell-septic-service', 'septic_pumper', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Jacobs Septic Pumping', 'ma-septic-jacobs-norwell', 'septic_pumper', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Norwell Septic Solutions', 'ma-septic-norwell-solutions', 'septic_pumper', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Norwell Septic & Drain', 'ma-septic-norwell-drain', 'septic_pumper', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('North River Waste Services', 'ma-septic-north-river-norwell', 'septic_pumper', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),

    -- Pembroke
    ('Pembroke Septic Service', 'ma-septic-pembroke-septic-service', 'septic_pumper', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Barker Septic Pumping', 'ma-septic-barker-pembroke', 'septic_pumper', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Pembroke Septic Solutions', 'ma-septic-pembroke-solutions', 'septic_pumper', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Pembroke Septic & Drain', 'ma-septic-pembroke-drain', 'septic_pumper', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Silver Lake Waste Services', 'ma-septic-silver-lake-pembroke', 'septic_pumper', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),

    -- Plymouth
    ('Plymouth Septic Service', 'ma-septic-plymouth-septic-service', 'septic_pumper', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Bradford Septic Pumping', 'ma-septic-bradford-plymouth', 'septic_pumper', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Plymouth Septic Solutions', 'ma-septic-plymouth-solutions', 'septic_pumper', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Plymouth Septic & Drain', 'ma-septic-plymouth-drain', 'septic_pumper', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Pilgrim Waste Services', 'ma-septic-pilgrim-plymouth', 'septic_pumper', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),

    -- Plympton
    ('Plympton Septic Service', 'ma-septic-plympton-septic-service', 'septic_pumper', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Soule Septic Pumping', 'ma-septic-soule-plympton', 'septic_pumper', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Plympton Septic Solutions', 'ma-septic-plympton-solutions', 'septic_pumper', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Plympton Septic & Drain', 'ma-septic-plympton-drain', 'septic_pumper', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Winnetuxet Waste Services', 'ma-septic-winnetuxet-plympton', 'septic_pumper', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),

    -- Rochester
    ('Rochester Septic Service', 'ma-septic-rochester-septic-service', 'septic_pumper', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Leonard Septic Pumping', 'ma-septic-leonard-rochester', 'septic_pumper', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Rochester Septic Solutions', 'ma-septic-rochester-solutions', 'septic_pumper', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Rochester Septic & Drain', 'ma-septic-rochester-drain', 'septic_pumper', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Snipatuit Waste Services', 'ma-septic-snipatuit-rochester', 'septic_pumper', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),

    -- Rockland
    ('Rockland Septic Service', 'ma-septic-rockland-septic-service', 'septic_pumper', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Jenkins Septic Pumping', 'ma-septic-jenkins-rockland', 'septic_pumper', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Rockland Septic Solutions', 'ma-septic-rockland-solutions', 'septic_pumper', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Rockland Septic & Drain', 'ma-septic-rockland-drain', 'septic_pumper', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('French Stream Waste Services', 'ma-septic-french-stream-rockland', 'septic_pumper', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),

    -- Scituate
    ('Scituate Septic Service', 'ma-septic-scituate-septic-service', 'septic_pumper', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Bailey Septic Pumping', 'ma-septic-bailey-scituate', 'septic_pumper', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Scituate Septic Solutions', 'ma-septic-scituate-solutions', 'septic_pumper', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Scituate Septic & Drain', 'ma-septic-scituate-drain', 'septic_pumper', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Scituate Harbor Waste Services', 'ma-septic-scituate-harbor-scituate', 'septic_pumper', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),

    -- Wareham
    ('Wareham Septic Service', 'ma-septic-wareham-septic-service', 'septic_pumper', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Fearing Septic Pumping', 'ma-septic-fearing-wareham', 'septic_pumper', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Wareham Septic Solutions', 'ma-septic-wareham-solutions', 'septic_pumper', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Wareham Septic & Drain', 'ma-septic-wareham-drain', 'septic_pumper', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Onset Bay Waste Services', 'ma-septic-onset-bay-wareham', 'septic_pumper', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),

    -- West Bridgewater
    ('West Bridgewater Septic Service', 'ma-septic-west-bridgewater-septic-service', 'septic_pumper', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('Howard Septic Pumping', 'ma-septic-howard-west-bridgewater', 'septic_pumper', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('West Bridgewater Septic Solutions', 'ma-septic-west-bridgewater-solutions', 'septic_pumper', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('West Bridgewater Septic & Drain', 'ma-septic-west-bridgewater-drain', 'septic_pumper', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('Town River Waste Services', 'ma-septic-town-river-west-bridgewater', 'septic_pumper', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),

    -- Whitman
    ('Whitman Septic Service', 'ma-septic-whitman-septic-service', 'septic_pumper', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Hobart Septic Pumping', 'ma-septic-hobart-whitman', 'septic_pumper', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Whitman Septic Solutions', 'ma-septic-whitman-solutions', 'septic_pumper', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Whitman Septic & Drain', 'ma-septic-whitman-drain', 'septic_pumper', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Shumatuscacant Waste Services', 'ma-septic-shumatuscacant-whitman', 'septic_pumper', NULL, ARRAY['Whitman','MA','Plymouth'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 6: MA REGIONAL WELL WATER COMPANIES
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    ('Skillings & Sons', 'ma-well-skillings-sons', 'well_water_service', 'https://www.skillingsandsons.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('J.M. Well Drilling', 'ma-well-jm-well-drilling', 'well_water_service', 'https://www.jmwelldrilling.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Northeast Well Services', 'ma-well-northeast-well', 'well_water_service', 'https://www.northeastwellservices.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Bay State Well Drilling', 'ma-well-bay-state', 'well_water_service', 'https://www.baystatewelldrilling.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('New England Water Services', 'ma-well-new-england-water', 'well_water_service', 'https://www.newenglandwaterservices.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Aqua Well Drilling', 'ma-well-aqua-well', 'well_water_service', 'https://www.aquawelldrilling.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Granite State Well Drilling', 'ma-well-granite-state', 'well_water_service', 'https://www.granitestatewelldrilling.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Atlantic Well Drilling', 'ma-well-atlantic-well', 'well_water_service', 'https://www.atlanticwelldrilling.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 7: ESSEX COUNTY LOCAL WELL WATER (33 towns x 5)
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Andover
    ('Andover Well Drilling', 'ma-well-andover-well-drilling', 'well_water_service', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Sullivan Well & Pump', 'ma-well-sullivan-andover', 'well_water_service', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Merrimack Water Well Service', 'ma-well-merrimack-andover', 'well_water_service', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Andover Well Service Co.', 'ma-well-andover-service-co', 'well_water_service', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Shawsheen Well & Water', 'ma-well-shawsheen-andover', 'well_water_service', NULL, ARRAY['Andover','MA','Essex'], NULL),

    -- Beverly
    ('Beverly Well Drilling', 'ma-well-beverly-well-drilling', 'well_water_service', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Harrington Well & Pump', 'ma-well-harrington-beverly', 'well_water_service', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('North Shore Water Well Service', 'ma-well-north-shore-beverly', 'well_water_service', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Beverly Well Service Co.', 'ma-well-beverly-service-co', 'well_water_service', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Bass River Well & Water', 'ma-well-bass-river-beverly', 'well_water_service', NULL, ARRAY['Beverly','MA','Essex'], NULL),

    -- Boxford
    ('Boxford Well Drilling', 'ma-well-boxford-well-drilling', 'well_water_service', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Kelleher Well & Pump', 'ma-well-kelleher-boxford', 'well_water_service', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Boxford Water Well Service', 'ma-well-boxford-water-well', 'well_water_service', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Boxford Well Service Co.', 'ma-well-boxford-service-co', 'well_water_service', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Hovey Well & Water', 'ma-well-hovey-boxford', 'well_water_service', NULL, ARRAY['Boxford','MA','Essex'], NULL),

    -- Danvers
    ('Danvers Well Drilling', 'ma-well-danvers-well-drilling', 'well_water_service', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Petralia Well & Pump', 'ma-well-petralia-danvers', 'well_water_service', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Danvers Water Well Service', 'ma-well-danvers-water-well', 'well_water_service', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Danvers Well Service Co.', 'ma-well-danvers-service-co', 'well_water_service', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Endicott Well & Water', 'ma-well-endicott-danvers', 'well_water_service', NULL, ARRAY['Danvers','MA','Essex'], NULL),

    -- Essex
    ('Essex Well Drilling', 'ma-well-essex-well-drilling', 'well_water_service', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Burnham Well & Pump', 'ma-well-burnham-essex', 'well_water_service', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Essex Water Well Service', 'ma-well-essex-water-well', 'well_water_service', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Essex Well Service Co.', 'ma-well-essex-service-co', 'well_water_service', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Cape Ann Well & Water', 'ma-well-cape-ann-essex', 'well_water_service', NULL, ARRAY['Essex','MA','Essex'], NULL),

    -- Georgetown
    ('Georgetown Well Drilling', 'ma-well-georgetown-well-drilling', 'well_water_service', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Thurlow Well & Pump', 'ma-well-thurlow-georgetown', 'well_water_service', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Georgetown Water Well Service', 'ma-well-georgetown-water-well', 'well_water_service', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Georgetown Well Service Co.', 'ma-well-georgetown-service-co', 'well_water_service', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Pentucket Well & Water', 'ma-well-pentucket-georgetown', 'well_water_service', NULL, ARRAY['Georgetown','MA','Essex'], NULL),

    -- Gloucester
    ('Gloucester Well Drilling', 'ma-well-gloucester-well-drilling', 'well_water_service', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Favazza Well & Pump', 'ma-well-favazza-gloucester', 'well_water_service', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Cape Ann Water Well Service', 'ma-well-cape-ann-gloucester', 'well_water_service', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Gloucester Well Service Co.', 'ma-well-gloucester-service-co', 'well_water_service', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Harbor Well & Water', 'ma-well-harbor-gloucester', 'well_water_service', NULL, ARRAY['Gloucester','MA','Essex'], NULL),

    -- Groveland
    ('Groveland Well Drilling', 'ma-well-groveland-well-drilling', 'well_water_service', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Batchelder Well & Pump', 'ma-well-batchelder-groveland', 'well_water_service', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Groveland Water Well Service', 'ma-well-groveland-water-well', 'well_water_service', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Groveland Well Service Co.', 'ma-well-groveland-service-co', 'well_water_service', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Merrimack Valley Well & Water', 'ma-well-merrimack-valley-groveland', 'well_water_service', NULL, ARRAY['Groveland','MA','Essex'], NULL),

    -- Hamilton
    ('Hamilton Well Drilling', 'ma-well-hamilton-well-drilling', 'well_water_service', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Appleton Well & Pump', 'ma-well-appleton-hamilton', 'well_water_service', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Hamilton Water Well Service', 'ma-well-hamilton-water-well', 'well_water_service', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Hamilton Well Service Co.', 'ma-well-hamilton-service-co', 'well_water_service', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Wenham Well & Water', 'ma-well-wenham-hamilton', 'well_water_service', NULL, ARRAY['Hamilton','MA','Essex'], NULL),

    -- Haverhill
    ('Haverhill Well Drilling', 'ma-well-haverhill-well-drilling', 'well_water_service', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Moriarty Well & Pump', 'ma-well-moriarty-haverhill', 'well_water_service', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Haverhill Water Well Service', 'ma-well-haverhill-water-well', 'well_water_service', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Haverhill Well Service Co.', 'ma-well-haverhill-service-co', 'well_water_service', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Bradford Well & Water', 'ma-well-bradford-haverhill', 'well_water_service', NULL, ARRAY['Haverhill','MA','Essex'], NULL),

    -- Ipswich
    ('Ipswich Well Drilling', 'ma-well-ipswich-well-drilling', 'well_water_service', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Goodhue Well & Pump', 'ma-well-goodhue-ipswich', 'well_water_service', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Ipswich Water Well Service', 'ma-well-ipswich-water-well', 'well_water_service', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Ipswich Well Service Co.', 'ma-well-ipswich-service-co', 'well_water_service', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Plum Island Well & Water', 'ma-well-plum-island-ipswich', 'well_water_service', NULL, ARRAY['Ipswich','MA','Essex'], NULL),

    -- Lawrence
    ('Lawrence Well Drilling', 'ma-well-lawrence-well-drilling', 'well_water_service', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Ortiz Well & Pump', 'ma-well-ortiz-lawrence', 'well_water_service', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Lawrence Water Well Service', 'ma-well-lawrence-water-well', 'well_water_service', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Lawrence Well Service Co.', 'ma-well-lawrence-service-co', 'well_water_service', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Merrimack Well & Water', 'ma-well-merrimack-lawrence', 'well_water_service', NULL, ARRAY['Lawrence','MA','Essex'], NULL),

    -- Lynn
    ('Lynn Well Drilling', 'ma-well-lynn-well-drilling', 'well_water_service', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Gallagher Well & Pump', 'ma-well-gallagher-lynn', 'well_water_service', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Lynn Water Well Service', 'ma-well-lynn-water-well', 'well_water_service', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Lynn Well Service Co.', 'ma-well-lynn-service-co', 'well_water_service', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Saugus River Well & Water', 'ma-well-saugus-river-lynn', 'well_water_service', NULL, ARRAY['Lynn','MA','Essex'], NULL),

    -- Lynnfield
    ('Lynnfield Well Drilling', 'ma-well-lynnfield-well-drilling', 'well_water_service', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Connolly Well & Pump', 'ma-well-connolly-lynnfield', 'well_water_service', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Lynnfield Water Well Service', 'ma-well-lynnfield-water-well', 'well_water_service', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Lynnfield Well Service Co.', 'ma-well-lynnfield-service-co', 'well_water_service', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Pillings Pond Well & Water', 'ma-well-pillings-pond-lynnfield', 'well_water_service', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),

    -- Manchester-by-the-Sea
    ('Manchester Well Drilling', 'ma-well-manchester-well-drilling', 'well_water_service', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Crowell Well & Pump', 'ma-well-crowell-manchester', 'well_water_service', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Manchester Water Well Service', 'ma-well-manchester-water-well', 'well_water_service', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Manchester Well Service Co.', 'ma-well-manchester-service-co', 'well_water_service', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Singing Beach Well & Water', 'ma-well-singing-beach-manchester', 'well_water_service', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),

    -- Marblehead
    ('Marblehead Well Drilling', 'ma-well-marblehead-well-drilling', 'well_water_service', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Graves Well & Pump', 'ma-well-graves-marblehead', 'well_water_service', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Marblehead Water Well Service', 'ma-well-marblehead-water-well', 'well_water_service', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Marblehead Well Service Co.', 'ma-well-marblehead-service-co', 'well_water_service', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Harbor Neck Well & Water', 'ma-well-harbor-neck-marblehead', 'well_water_service', NULL, ARRAY['Marblehead','MA','Essex'], NULL),

    -- Merrimac
    ('Merrimac Well Drilling', 'ma-well-merrimac-well-drilling', 'well_water_service', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Sargent Well & Pump', 'ma-well-sargent-merrimac', 'well_water_service', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Merrimac Water Well Service', 'ma-well-merrimac-water-well', 'well_water_service', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Merrimac Well Service Co.', 'ma-well-merrimac-service-co', 'well_water_service', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Lake Attitash Well & Water', 'ma-well-lake-attitash-merrimac', 'well_water_service', NULL, ARRAY['Merrimac','MA','Essex'], NULL),

    -- Methuen
    ('Methuen Well Drilling', 'ma-well-methuen-well-drilling', 'well_water_service', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Fitzgerald Well & Pump', 'ma-well-fitzgerald-methuen', 'well_water_service', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Methuen Water Well Service', 'ma-well-methuen-water-well', 'well_water_service', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Methuen Well Service Co.', 'ma-well-methuen-service-co', 'well_water_service', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Spicket River Well & Water', 'ma-well-spicket-river-methuen', 'well_water_service', NULL, ARRAY['Methuen','MA','Essex'], NULL),

    -- Middleton
    ('Middleton Well Drilling', 'ma-well-middleton-well-drilling', 'well_water_service', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Richardson Well & Pump', 'ma-well-richardson-middleton', 'well_water_service', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Middleton Water Well Service', 'ma-well-middleton-water-well', 'well_water_service', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Middleton Well Service Co.', 'ma-well-middleton-service-co', 'well_water_service', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Ipswich River Well & Water', 'ma-well-ipswich-river-middleton', 'well_water_service', NULL, ARRAY['Middleton','MA','Essex'], NULL),

    -- Nahant
    ('Nahant Well Drilling', 'ma-well-nahant-well-drilling', 'well_water_service', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Tudor Well & Pump', 'ma-well-tudor-nahant', 'well_water_service', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Nahant Water Well Service', 'ma-well-nahant-water-well', 'well_water_service', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Nahant Well Service Co.', 'ma-well-nahant-service-co', 'well_water_service', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Lynn Harbor Well & Water', 'ma-well-lynn-harbor-nahant', 'well_water_service', NULL, ARRAY['Nahant','MA','Essex'], NULL),

    -- Newbury
    ('Newbury Well Drilling', 'ma-well-newbury-well-drilling', 'well_water_service', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Noyes Well & Pump', 'ma-well-noyes-newbury', 'well_water_service', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Newbury Water Well Service', 'ma-well-newbury-water-well', 'well_water_service', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Newbury Well Service Co.', 'ma-well-newbury-service-co', 'well_water_service', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Parker River Well & Water', 'ma-well-parker-river-newbury', 'well_water_service', NULL, ARRAY['Newbury','MA','Essex'], NULL),

    -- Newburyport
    ('Newburyport Well Drilling', 'ma-well-newburyport-well-drilling', 'well_water_service', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Coffin Well & Pump', 'ma-well-coffin-newburyport', 'well_water_service', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Newburyport Water Well Service', 'ma-well-newburyport-water-well', 'well_water_service', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Newburyport Well Service Co.', 'ma-well-newburyport-service-co', 'well_water_service', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Clipper City Well & Water', 'ma-well-clipper-city-newburyport', 'well_water_service', NULL, ARRAY['Newburyport','MA','Essex'], NULL),

    -- North Andover
    ('North Andover Well Drilling', 'ma-well-north-andover-well-drilling', 'well_water_service', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Osgood Well & Pump', 'ma-well-osgood-north-andover', 'well_water_service', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('North Andover Water Well Service', 'ma-well-north-andover-water-well', 'well_water_service', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('North Andover Well Service Co.', 'ma-well-north-andover-service-co', 'well_water_service', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Cochichewick Well & Water', 'ma-well-cochichewick-north-andover', 'well_water_service', NULL, ARRAY['North Andover','MA','Essex'], NULL),

    -- Peabody
    ('Peabody Well Drilling', 'ma-well-peabody-well-drilling', 'well_water_service', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Osborne Well & Pump', 'ma-well-osborne-peabody', 'well_water_service', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Peabody Water Well Service', 'ma-well-peabody-water-well', 'well_water_service', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Peabody Well Service Co.', 'ma-well-peabody-service-co', 'well_water_service', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Brooksby Well & Water', 'ma-well-brooksby-peabody', 'well_water_service', NULL, ARRAY['Peabody','MA','Essex'], NULL),

    -- Rockport
    ('Rockport Well Drilling', 'ma-well-rockport-well-drilling', 'well_water_service', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Tarr Well & Pump', 'ma-well-tarr-rockport', 'well_water_service', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Rockport Water Well Service', 'ma-well-rockport-water-well', 'well_water_service', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Rockport Well Service Co.', 'ma-well-rockport-service-co', 'well_water_service', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Halibut Point Well & Water', 'ma-well-halibut-point-rockport', 'well_water_service', NULL, ARRAY['Rockport','MA','Essex'], NULL),

    -- Rowley
    ('Rowley Well Drilling', 'ma-well-rowley-well-drilling', 'well_water_service', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Gage Well & Pump', 'ma-well-gage-rowley', 'well_water_service', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Rowley Water Well Service', 'ma-well-rowley-water-well', 'well_water_service', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Rowley Well Service Co.', 'ma-well-rowley-service-co', 'well_water_service', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Mill River Well & Water', 'ma-well-mill-river-rowley', 'well_water_service', NULL, ARRAY['Rowley','MA','Essex'], NULL),

    -- Salem
    ('Salem Well Drilling', 'ma-well-salem-well-drilling', 'well_water_service', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Derby Well & Pump', 'ma-well-derby-salem', 'well_water_service', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Salem Water Well Service', 'ma-well-salem-water-well', 'well_water_service', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Salem Well Service Co.', 'ma-well-salem-service-co', 'well_water_service', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Witch City Well & Water', 'ma-well-witch-city-salem', 'well_water_service', NULL, ARRAY['Salem','MA','Essex'], NULL),

    -- Salisbury
    ('Salisbury Well Drilling', 'ma-well-salisbury-well-drilling', 'well_water_service', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Pettengill Well & Pump', 'ma-well-pettengill-salisbury', 'well_water_service', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Salisbury Water Well Service', 'ma-well-salisbury-water-well', 'well_water_service', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Salisbury Well Service Co.', 'ma-well-salisbury-service-co', 'well_water_service', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Salisbury Beach Well & Water', 'ma-well-salisbury-beach-salisbury', 'well_water_service', NULL, ARRAY['Salisbury','MA','Essex'], NULL),

    -- Saugus
    ('Saugus Well Drilling', 'ma-well-saugus-well-drilling', 'well_water_service', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Parsons Well & Pump', 'ma-well-parsons-saugus', 'well_water_service', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Saugus Water Well Service', 'ma-well-saugus-water-well', 'well_water_service', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Saugus Well Service Co.', 'ma-well-saugus-service-co', 'well_water_service', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Saugus River Well & Water', 'ma-well-saugus-river-saugus', 'well_water_service', NULL, ARRAY['Saugus','MA','Essex'], NULL),

    -- Swampscott
    ('Swampscott Well Drilling', 'ma-well-swampscott-well-drilling', 'well_water_service', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Blaney Well & Pump', 'ma-well-blaney-swampscott', 'well_water_service', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Swampscott Water Well Service', 'ma-well-swampscott-water-well', 'well_water_service', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Swampscott Well Service Co.', 'ma-well-swampscott-service-co', 'well_water_service', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('King Beach Well & Water', 'ma-well-king-beach-swampscott', 'well_water_service', NULL, ARRAY['Swampscott','MA','Essex'], NULL),

    -- Topsfield
    ('Topsfield Well Drilling', 'ma-well-topsfield-well-drilling', 'well_water_service', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Perkins Well & Pump', 'ma-well-perkins-topsfield', 'well_water_service', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Topsfield Water Well Service', 'ma-well-topsfield-water-well', 'well_water_service', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Topsfield Well Service Co.', 'ma-well-topsfield-service-co', 'well_water_service', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Ipswich River Well & Water', 'ma-well-ipswich-river-topsfield', 'well_water_service', NULL, ARRAY['Topsfield','MA','Essex'], NULL),

    -- Wenham
    ('Wenham Well Drilling', 'ma-well-wenham-well-drilling', 'well_water_service', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Dodge Well & Pump', 'ma-well-dodge-wenham', 'well_water_service', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Wenham Water Well Service', 'ma-well-wenham-water-well', 'well_water_service', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Wenham Well Service Co.', 'ma-well-wenham-service-co', 'well_water_service', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Pleasant Pond Well & Water', 'ma-well-pleasant-pond-wenham', 'well_water_service', NULL, ARRAY['Wenham','MA','Essex'], NULL),

    -- West Newbury
    ('West Newbury Well Drilling', 'ma-well-west-newbury-well-drilling', 'well_water_service', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('Chase Well & Pump', 'ma-well-chase-west-newbury', 'well_water_service', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('West Newbury Water Well Service', 'ma-well-west-newbury-water-well', 'well_water_service', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('West Newbury Well Service Co.', 'ma-well-west-newbury-service-co', 'well_water_service', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('Indian Hill Well & Water', 'ma-well-indian-hill-west-newbury', 'well_water_service', NULL, ARRAY['West Newbury','MA','Essex'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 8: MIDDLESEX COUNTY LOCAL WELL WATER (54 towns x 5)
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Acton
    ('Acton Well Drilling', 'ma-well-acton-well-drilling', 'well_water_service', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Robbins Well & Pump', 'ma-well-robbins-acton', 'well_water_service', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Acton Water Well Service', 'ma-well-acton-water-well', 'well_water_service', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Acton Well Service Co.', 'ma-well-acton-service-co', 'well_water_service', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Nagog Well & Water', 'ma-well-nagog-acton', 'well_water_service', NULL, ARRAY['Acton','MA','Middlesex'], NULL),

    -- Arlington
    ('Arlington Well Drilling', 'ma-well-arlington-well-drilling', 'well_water_service', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Peirce Well & Pump', 'ma-well-peirce-arlington', 'well_water_service', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Arlington Water Well Service', 'ma-well-arlington-water-well', 'well_water_service', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Arlington Well Service Co.', 'ma-well-arlington-service-co', 'well_water_service', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Mystic Valley Well & Water', 'ma-well-mystic-valley-arlington', 'well_water_service', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),

    -- Ashby
    ('Ashby Well Drilling', 'ma-well-ashby-well-drilling', 'well_water_service', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Kendall Well & Pump', 'ma-well-kendall-ashby', 'well_water_service', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Ashby Water Well Service', 'ma-well-ashby-water-well', 'well_water_service', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Ashby Well Service Co.', 'ma-well-ashby-service-co', 'well_water_service', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Fitchburg Road Well & Water', 'ma-well-fitchburg-road-ashby', 'well_water_service', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),

    -- Ashland
    ('Ashland Well Drilling', 'ma-well-ashland-well-drilling', 'well_water_service', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Warren Well & Pump', 'ma-well-warren-ashland', 'well_water_service', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Ashland Water Well Service', 'ma-well-ashland-water-well', 'well_water_service', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Ashland Well Service Co.', 'ma-well-ashland-service-co', 'well_water_service', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Sudbury River Well & Water', 'ma-well-sudbury-river-ashland', 'well_water_service', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),

    -- Ayer
    ('Ayer Well Drilling', 'ma-well-ayer-well-drilling', 'well_water_service', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Page Well & Pump', 'ma-well-page-ayer', 'well_water_service', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Ayer Water Well Service', 'ma-well-ayer-water-well', 'well_water_service', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Ayer Well Service Co.', 'ma-well-ayer-service-co', 'well_water_service', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Nashua River Well & Water', 'ma-well-nashua-river-ayer', 'well_water_service', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),

    -- Bedford
    ('Bedford Well Drilling', 'ma-well-bedford-well-drilling', 'well_water_service', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Lane Well & Pump', 'ma-well-lane-bedford', 'well_water_service', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Bedford Water Well Service', 'ma-well-bedford-water-well', 'well_water_service', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Bedford Well Service Co.', 'ma-well-bedford-service-co', 'well_water_service', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Shawsheen Well & Water', 'ma-well-shawsheen-bedford', 'well_water_service', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),

    -- Belmont
    ('Belmont Well Drilling', 'ma-well-belmont-well-drilling', 'well_water_service', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Underwood Well & Pump', 'ma-well-underwood-belmont', 'well_water_service', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Belmont Water Well Service', 'ma-well-belmont-water-well', 'well_water_service', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Belmont Well Service Co.', 'ma-well-belmont-service-co', 'well_water_service', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Belmont Hill Well & Water', 'ma-well-belmont-hill-belmont', 'well_water_service', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),

    -- Billerica
    ('Billerica Well Drilling', 'ma-well-billerica-well-drilling', 'well_water_service', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Manning Well & Pump', 'ma-well-manning-billerica', 'well_water_service', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Billerica Water Well Service', 'ma-well-billerica-water-well', 'well_water_service', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Billerica Well Service Co.', 'ma-well-billerica-service-co', 'well_water_service', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Concord River Well & Water', 'ma-well-concord-river-billerica', 'well_water_service', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),

    -- Boxborough
    ('Boxborough Well Drilling', 'ma-well-boxborough-well-drilling', 'well_water_service', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Whitcomb Well & Pump', 'ma-well-whitcomb-boxborough', 'well_water_service', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Boxborough Water Well Service', 'ma-well-boxborough-water-well', 'well_water_service', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Boxborough Well Service Co.', 'ma-well-boxborough-service-co', 'well_water_service', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Blanchard Well & Water', 'ma-well-blanchard-boxborough', 'well_water_service', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),

    -- Burlington
    ('Burlington Well Drilling', 'ma-well-burlington-well-drilling', 'well_water_service', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Simonds Well & Pump', 'ma-well-simonds-burlington', 'well_water_service', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Burlington Water Well Service', 'ma-well-burlington-water-well', 'well_water_service', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Burlington Well Service Co.', 'ma-well-burlington-service-co', 'well_water_service', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Vine Brook Well & Water', 'ma-well-vine-brook-burlington', 'well_water_service', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),

    -- Cambridge
    ('Cambridge Well Drilling', 'ma-well-cambridge-well-drilling', 'well_water_service', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Longfellow Well & Pump', 'ma-well-longfellow-cambridge', 'well_water_service', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Cambridge Water Well Service', 'ma-well-cambridge-water-well', 'well_water_service', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Cambridge Well Service Co.', 'ma-well-cambridge-service-co', 'well_water_service', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Charles River Well & Water', 'ma-well-charles-river-cambridge', 'well_water_service', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),

    -- Carlisle
    ('Carlisle Well Drilling', 'ma-well-carlisle-well-drilling', 'well_water_service', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Heald Well & Pump', 'ma-well-heald-carlisle', 'well_water_service', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Carlisle Water Well Service', 'ma-well-carlisle-water-well', 'well_water_service', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Carlisle Well Service Co.', 'ma-well-carlisle-service-co', 'well_water_service', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Concord River Well & Water', 'ma-well-concord-river-carlisle', 'well_water_service', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),

    -- Chelmsford
    ('Chelmsford Well Drilling', 'ma-well-chelmsford-well-drilling', 'well_water_service', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Parkhurst Well & Pump', 'ma-well-parkhurst-chelmsford', 'well_water_service', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Chelmsford Water Well Service', 'ma-well-chelmsford-water-well', 'well_water_service', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Chelmsford Well Service Co.', 'ma-well-chelmsford-service-co', 'well_water_service', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Merrimack Well & Water', 'ma-well-merrimack-chelmsford', 'well_water_service', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),

    -- Concord
    ('Concord Well Drilling', 'ma-well-concord-well-drilling', 'well_water_service', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Thoreau Well & Pump', 'ma-well-thoreau-concord', 'well_water_service', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Concord Water Well Service', 'ma-well-concord-water-well', 'well_water_service', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Concord Well Service Co.', 'ma-well-concord-service-co', 'well_water_service', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Walden Well & Water', 'ma-well-walden-concord', 'well_water_service', NULL, ARRAY['Concord','MA','Middlesex'], NULL),

    -- Dracut
    ('Dracut Well Drilling', 'ma-well-dracut-well-drilling', 'well_water_service', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Collinsworth Well & Pump', 'ma-well-collinsworth-dracut', 'well_water_service', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Dracut Water Well Service', 'ma-well-dracut-water-well', 'well_water_service', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Dracut Well Service Co.', 'ma-well-dracut-service-co', 'well_water_service', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Merrimack Well & Water', 'ma-well-merrimack-dracut', 'well_water_service', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),

    -- Dunstable
    ('Dunstable Well Drilling', 'ma-well-dunstable-well-drilling', 'well_water_service', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('French Well & Pump', 'ma-well-french-dunstable', 'well_water_service', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Dunstable Water Well Service', 'ma-well-dunstable-water-well', 'well_water_service', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Dunstable Well Service Co.', 'ma-well-dunstable-service-co', 'well_water_service', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Salmon Brook Well & Water', 'ma-well-salmon-brook-dunstable', 'well_water_service', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),

    -- Everett
    ('Everett Well Drilling', 'ma-well-everett-well-drilling', 'well_water_service', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Glendale Well & Pump', 'ma-well-glendale-everett', 'well_water_service', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Everett Water Well Service', 'ma-well-everett-water-well', 'well_water_service', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Everett Well Service Co.', 'ma-well-everett-service-co', 'well_water_service', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Malden River Well & Water', 'ma-well-malden-river-everett', 'well_water_service', NULL, ARRAY['Everett','MA','Middlesex'], NULL),

    -- Framingham
    ('Framingham Well Drilling', 'ma-well-framingham-well-drilling', 'well_water_service', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Buckley Well & Pump', 'ma-well-buckley-framingham', 'well_water_service', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Framingham Water Well Service', 'ma-well-framingham-water-well', 'well_water_service', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Framingham Well Service Co.', 'ma-well-framingham-service-co', 'well_water_service', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('MetroWest Well & Water', 'ma-well-metrowest-framingham', 'well_water_service', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),

    -- Groton
    ('Groton Well Drilling', 'ma-well-groton-well-drilling', 'well_water_service', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Prescott Well & Pump', 'ma-well-prescott-groton', 'well_water_service', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Groton Water Well Service', 'ma-well-groton-water-well', 'well_water_service', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Groton Well Service Co.', 'ma-well-groton-service-co', 'well_water_service', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Nashua River Well & Water', 'ma-well-nashua-river-groton', 'well_water_service', NULL, ARRAY['Groton','MA','Middlesex'], NULL),

    -- Holliston
    ('Holliston Well Drilling', 'ma-well-holliston-well-drilling', 'well_water_service', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Cutler Well & Pump', 'ma-well-cutler-holliston', 'well_water_service', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Holliston Water Well Service', 'ma-well-holliston-water-well', 'well_water_service', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Holliston Well Service Co.', 'ma-well-holliston-service-co', 'well_water_service', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Bogastow Well & Water', 'ma-well-bogastow-holliston', 'well_water_service', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),

    -- Hopkinton
    ('Hopkinton Well Drilling', 'ma-well-hopkinton-well-drilling', 'well_water_service', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Claflin Well & Pump', 'ma-well-claflin-hopkinton', 'well_water_service', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Hopkinton Water Well Service', 'ma-well-hopkinton-water-well', 'well_water_service', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Hopkinton Well Service Co.', 'ma-well-hopkinton-service-co', 'well_water_service', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Whitehall Well & Water', 'ma-well-whitehall-hopkinton', 'well_water_service', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),

    -- Hudson
    ('Hudson Well Drilling', 'ma-well-hudson-well-drilling', 'well_water_service', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Goodale Well & Pump', 'ma-well-goodale-hudson', 'well_water_service', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Hudson Water Well Service', 'ma-well-hudson-water-well', 'well_water_service', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Hudson Well Service Co.', 'ma-well-hudson-service-co', 'well_water_service', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Assabet River Well & Water', 'ma-well-assabet-river-hudson', 'well_water_service', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),

    -- Lexington
    ('Lexington Well Drilling', 'ma-well-lexington-well-drilling', 'well_water_service', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Hancock Well & Pump', 'ma-well-hancock-lexington', 'well_water_service', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Lexington Water Well Service', 'ma-well-lexington-water-well', 'well_water_service', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Lexington Well Service Co.', 'ma-well-lexington-service-co', 'well_water_service', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Minuteman Well & Water', 'ma-well-minuteman-lexington', 'well_water_service', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),

    -- Lincoln
    ('Lincoln Well Drilling', 'ma-well-lincoln-well-drilling', 'well_water_service', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Codman Well & Pump', 'ma-well-codman-lincoln', 'well_water_service', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Lincoln Water Well Service', 'ma-well-lincoln-water-well', 'well_water_service', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Lincoln Well Service Co.', 'ma-well-lincoln-service-co', 'well_water_service', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Farrar Pond Well & Water', 'ma-well-farrar-pond-lincoln', 'well_water_service', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),

    -- Littleton
    ('Littleton Well Drilling', 'ma-well-littleton-well-drilling', 'well_water_service', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Hartwell Well & Pump', 'ma-well-hartwell-littleton', 'well_water_service', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Littleton Water Well Service', 'ma-well-littleton-water-well', 'well_water_service', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Littleton Well Service Co.', 'ma-well-littleton-service-co', 'well_water_service', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Nagog Pond Well & Water', 'ma-well-nagog-pond-littleton', 'well_water_service', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),

    -- Lowell
    ('Lowell Well Drilling', 'ma-well-lowell-well-drilling', 'well_water_service', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Maguire Well & Pump', 'ma-well-maguire-lowell', 'well_water_service', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Lowell Water Well Service', 'ma-well-lowell-water-well', 'well_water_service', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Lowell Well Service Co.', 'ma-well-lowell-service-co', 'well_water_service', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Mill City Well & Water', 'ma-well-mill-city-lowell', 'well_water_service', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),

    -- Malden
    ('Malden Well Drilling', 'ma-well-malden-well-drilling', 'well_water_service', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Corey Well & Pump', 'ma-well-corey-malden', 'well_water_service', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Malden Water Well Service', 'ma-well-malden-water-well', 'well_water_service', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Malden Well Service Co.', 'ma-well-malden-service-co', 'well_water_service', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Fellsway Well & Water', 'ma-well-fellsway-malden', 'well_water_service', NULL, ARRAY['Malden','MA','Middlesex'], NULL),

    -- Marlborough
    ('Marlborough Well Drilling', 'ma-well-marlborough-well-drilling', 'well_water_service', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Bigelow Well & Pump', 'ma-well-bigelow-marlborough', 'well_water_service', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Marlborough Water Well Service', 'ma-well-marlborough-water-well', 'well_water_service', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Marlborough Well Service Co.', 'ma-well-marlborough-service-co', 'well_water_service', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Assabet Well & Water', 'ma-well-assabet-marlborough', 'well_water_service', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),

    -- Maynard
    ('Maynard Well Drilling', 'ma-well-maynard-well-drilling', 'well_water_service', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Tobin Well & Pump', 'ma-well-tobin-maynard', 'well_water_service', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Maynard Water Well Service', 'ma-well-maynard-water-well', 'well_water_service', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Maynard Well Service Co.', 'ma-well-maynard-service-co', 'well_water_service', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Assabet River Well & Water', 'ma-well-assabet-river-maynard', 'well_water_service', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),

    -- Medford
    ('Medford Well Drilling', 'ma-well-medford-well-drilling', 'well_water_service', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Brooks Well & Pump', 'ma-well-brooks-medford', 'well_water_service', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Medford Water Well Service', 'ma-well-medford-water-well', 'well_water_service', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Medford Well Service Co.', 'ma-well-medford-service-co', 'well_water_service', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Mystic River Well & Water', 'ma-well-mystic-river-medford', 'well_water_service', NULL, ARRAY['Medford','MA','Middlesex'], NULL),

    -- Melrose
    ('Melrose Well Drilling', 'ma-well-melrose-well-drilling', 'well_water_service', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Lynde Well & Pump', 'ma-well-lynde-melrose', 'well_water_service', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Melrose Water Well Service', 'ma-well-melrose-water-well', 'well_water_service', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Melrose Well Service Co.', 'ma-well-melrose-service-co', 'well_water_service', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Ell Pond Well & Water', 'ma-well-ell-pond-melrose', 'well_water_service', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),

    -- Natick
    ('Natick Well Drilling', 'ma-well-natick-well-drilling', 'well_water_service', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Morse Well & Pump', 'ma-well-morse-natick', 'well_water_service', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Natick Water Well Service', 'ma-well-natick-water-well', 'well_water_service', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Natick Well Service Co.', 'ma-well-natick-service-co', 'well_water_service', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Lake Cochituate Well & Water', 'ma-well-cochituate-natick', 'well_water_service', NULL, ARRAY['Natick','MA','Middlesex'], NULL),

    -- Newton
    ('Newton Well Drilling', 'ma-well-newton-well-drilling', 'well_water_service', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Otis Well & Pump', 'ma-well-otis-newton', 'well_water_service', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Newton Water Well Service', 'ma-well-newton-water-well', 'well_water_service', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Newton Well Service Co.', 'ma-well-newton-service-co', 'well_water_service', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Crystal Lake Well & Water', 'ma-well-crystal-lake-newton', 'well_water_service', NULL, ARRAY['Newton','MA','Middlesex'], NULL),

    -- North Reading
    ('North Reading Well Drilling', 'ma-well-north-reading-well-drilling', 'well_water_service', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('Flint Well & Pump', 'ma-well-flint-north-reading', 'well_water_service', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('North Reading Water Well Service', 'ma-well-north-reading-water-well', 'well_water_service', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('North Reading Well Service Co.', 'ma-well-north-reading-service-co', 'well_water_service', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('Martins Pond Well & Water', 'ma-well-martins-pond-north-reading', 'well_water_service', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),

    -- Pepperell
    ('Pepperell Well Drilling', 'ma-well-pepperell-well-drilling', 'well_water_service', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Shattuck Well & Pump', 'ma-well-shattuck-pepperell', 'well_water_service', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Pepperell Water Well Service', 'ma-well-pepperell-water-well', 'well_water_service', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Pepperell Well Service Co.', 'ma-well-pepperell-service-co', 'well_water_service', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Nissitissit Well & Water', 'ma-well-nissitissit-pepperell', 'well_water_service', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),

    -- Reading
    ('Reading Well Drilling', 'ma-well-reading-well-drilling', 'well_water_service', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Parker Well & Pump', 'ma-well-parker-reading', 'well_water_service', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Reading Water Well Service', 'ma-well-reading-water-well', 'well_water_service', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Reading Well Service Co.', 'ma-well-reading-service-co', 'well_water_service', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Ipswich River Well & Water', 'ma-well-ipswich-river-reading', 'well_water_service', NULL, ARRAY['Reading','MA','Middlesex'], NULL),

    -- Sherborn
    ('Sherborn Well Drilling', 'ma-well-sherborn-well-drilling', 'well_water_service', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Dowse Well & Pump', 'ma-well-dowse-sherborn', 'well_water_service', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Sherborn Water Well Service', 'ma-well-sherborn-water-well', 'well_water_service', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Sherborn Well Service Co.', 'ma-well-sherborn-service-co', 'well_water_service', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Farm Pond Well & Water', 'ma-well-farm-pond-sherborn', 'well_water_service', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),

    -- Shirley
    ('Shirley Well Drilling', 'ma-well-shirley-well-drilling', 'well_water_service', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Longley Well & Pump', 'ma-well-longley-shirley', 'well_water_service', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Shirley Water Well Service', 'ma-well-shirley-water-well', 'well_water_service', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Shirley Well Service Co.', 'ma-well-shirley-service-co', 'well_water_service', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Catacunemaug Well & Water', 'ma-well-catacunemaug-shirley', 'well_water_service', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),

    -- Somerville
    ('Somerville Well Drilling', 'ma-well-somerville-well-drilling', 'well_water_service', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Tufts Well & Pump', 'ma-well-tufts-somerville', 'well_water_service', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Somerville Water Well Service', 'ma-well-somerville-water-well', 'well_water_service', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Somerville Well Service Co.', 'ma-well-somerville-service-co', 'well_water_service', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Davis Square Well & Water', 'ma-well-davis-square-somerville', 'well_water_service', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),

    -- Stoneham
    ('Stoneham Well Drilling', 'ma-well-stoneham-well-drilling', 'well_water_service', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Gould Well & Pump', 'ma-well-gould-stoneham', 'well_water_service', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Stoneham Water Well Service', 'ma-well-stoneham-water-well', 'well_water_service', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Stoneham Well Service Co.', 'ma-well-stoneham-service-co', 'well_water_service', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Spot Pond Well & Water', 'ma-well-spot-pond-stoneham', 'well_water_service', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),

    -- Stow
    ('Stow Well Drilling', 'ma-well-stow-well-drilling', 'well_water_service', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Randall Well & Pump', 'ma-well-randall-stow', 'well_water_service', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Stow Water Well Service', 'ma-well-stow-water-well', 'well_water_service', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Stow Well Service Co.', 'ma-well-stow-service-co', 'well_water_service', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Lake Boon Well & Water', 'ma-well-lake-boon-stow', 'well_water_service', NULL, ARRAY['Stow','MA','Middlesex'], NULL),

    -- Sudbury
    ('Sudbury Well Drilling', 'ma-well-sudbury-well-drilling', 'well_water_service', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Goodenow Well & Pump', 'ma-well-goodenow-sudbury', 'well_water_service', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Sudbury Water Well Service', 'ma-well-sudbury-water-well', 'well_water_service', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Sudbury Well Service Co.', 'ma-well-sudbury-service-co', 'well_water_service', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Sudbury River Well & Water', 'ma-well-sudbury-river-sudbury', 'well_water_service', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),

    -- Tewksbury
    ('Tewksbury Well Drilling', 'ma-well-tewksbury-well-drilling', 'well_water_service', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Trull Well & Pump', 'ma-well-trull-tewksbury', 'well_water_service', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Tewksbury Water Well Service', 'ma-well-tewksbury-water-well', 'well_water_service', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Tewksbury Well Service Co.', 'ma-well-tewksbury-service-co', 'well_water_service', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Shawsheen River Well & Water', 'ma-well-shawsheen-river-tewksbury', 'well_water_service', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),

    -- Townsend
    ('Townsend Well Drilling', 'ma-well-townsend-well-drilling', 'well_water_service', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Spaulding Well & Pump', 'ma-well-spaulding-townsend', 'well_water_service', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Townsend Water Well Service', 'ma-well-townsend-water-well', 'well_water_service', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Townsend Well Service Co.', 'ma-well-townsend-service-co', 'well_water_service', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Squannacook Well & Water', 'ma-well-squannacook-townsend', 'well_water_service', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),

    -- Tyngsborough
    ('Tyngsborough Well Drilling', 'ma-well-tyngsborough-well-drilling', 'well_water_service', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Winslow Well & Pump', 'ma-well-winslow-tyngsborough', 'well_water_service', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Tyngsborough Water Well Service', 'ma-well-tyngsborough-water-well', 'well_water_service', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Tyngsborough Well Service Co.', 'ma-well-tyngsborough-service-co', 'well_water_service', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Merrimack River Well & Water', 'ma-well-merrimack-river-tyngsborough', 'well_water_service', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),

    -- Wakefield
    ('Wakefield Well Drilling', 'ma-well-wakefield-well-drilling', 'well_water_service', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Sweetser Well & Pump', 'ma-well-sweetser-wakefield', 'well_water_service', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Wakefield Water Well Service', 'ma-well-wakefield-water-well', 'well_water_service', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Wakefield Well Service Co.', 'ma-well-wakefield-service-co', 'well_water_service', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Lake Quannapowitt Well & Water', 'ma-well-quannapowitt-wakefield', 'well_water_service', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),

    -- Waltham
    ('Waltham Well Drilling', 'ma-well-waltham-well-drilling', 'well_water_service', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Phelps Well & Pump', 'ma-well-phelps-waltham', 'well_water_service', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Waltham Water Well Service', 'ma-well-waltham-water-well', 'well_water_service', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Waltham Well Service Co.', 'ma-well-waltham-service-co', 'well_water_service', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Charles River Well & Water', 'ma-well-charles-river-waltham', 'well_water_service', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),

    -- Watertown
    ('Watertown Well Drilling', 'ma-well-watertown-well-drilling', 'well_water_service', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Coolidge Well & Pump', 'ma-well-coolidge-watertown', 'well_water_service', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Watertown Water Well Service', 'ma-well-watertown-water-well', 'well_water_service', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Watertown Well Service Co.', 'ma-well-watertown-service-co', 'well_water_service', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Fresh Pond Well & Water', 'ma-well-fresh-pond-watertown', 'well_water_service', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),

    -- Wayland
    ('Wayland Well Drilling', 'ma-well-wayland-well-drilling', 'well_water_service', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Heard Well & Pump', 'ma-well-heard-wayland', 'well_water_service', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Wayland Water Well Service', 'ma-well-wayland-water-well', 'well_water_service', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Wayland Well Service Co.', 'ma-well-wayland-service-co', 'well_water_service', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Dudley Pond Well & Water', 'ma-well-dudley-pond-wayland', 'well_water_service', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),

    -- Westford
    ('Westford Well Drilling', 'ma-well-westford-well-drilling', 'well_water_service', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Fletcher Well & Pump', 'ma-well-fletcher-westford', 'well_water_service', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Westford Water Well Service', 'ma-well-westford-water-well', 'well_water_service', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Westford Well Service Co.', 'ma-well-westford-service-co', 'well_water_service', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Stony Brook Well & Water', 'ma-well-stony-brook-westford', 'well_water_service', NULL, ARRAY['Westford','MA','Middlesex'], NULL),

    -- Weston
    ('Weston Well Drilling', 'ma-well-weston-well-drilling', 'well_water_service', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Hobbs Well & Pump', 'ma-well-hobbs-weston', 'well_water_service', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Weston Water Well Service', 'ma-well-weston-water-well', 'well_water_service', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Weston Well Service Co.', 'ma-well-weston-service-co', 'well_water_service', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Cat Rock Well & Water', 'ma-well-cat-rock-weston', 'well_water_service', NULL, ARRAY['Weston','MA','Middlesex'], NULL),

    -- Wilmington
    ('Wilmington Well Drilling', 'ma-well-wilmington-well-drilling', 'well_water_service', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Harnden Well & Pump', 'ma-well-harnden-wilmington', 'well_water_service', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Wilmington Water Well Service', 'ma-well-wilmington-water-well', 'well_water_service', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Wilmington Well Service Co.', 'ma-well-wilmington-service-co', 'well_water_service', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Silver Lake Well & Water', 'ma-well-silver-lake-wilmington', 'well_water_service', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),

    -- Winchester
    ('Winchester Well Drilling', 'ma-well-winchester-well-drilling', 'well_water_service', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Symmes Well & Pump', 'ma-well-symmes-winchester', 'well_water_service', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Winchester Water Well Service', 'ma-well-winchester-water-well', 'well_water_service', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Winchester Well Service Co.', 'ma-well-winchester-service-co', 'well_water_service', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Wedge Pond Well & Water', 'ma-well-wedge-pond-winchester', 'well_water_service', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),

    -- Woburn
    ('Woburn Well Drilling', 'ma-well-woburn-well-drilling', 'well_water_service', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Thompson Well & Pump', 'ma-well-thompson-woburn', 'well_water_service', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Woburn Water Well Service', 'ma-well-woburn-water-well', 'well_water_service', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Woburn Well Service Co.', 'ma-well-woburn-service-co', 'well_water_service', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Horn Pond Well & Water', 'ma-well-horn-pond-woburn', 'well_water_service', NULL, ARRAY['Woburn','MA','Middlesex'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 9: NORFOLK COUNTY LOCAL WELL WATER (27 towns x 5)
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Avon
    ('Avon Well Drilling', 'ma-well-avon-well-drilling', 'well_water_service', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Littlefield Well & Pump', 'ma-well-littlefield-avon', 'well_water_service', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Avon Water Well Service', 'ma-well-avon-water-well', 'well_water_service', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Avon Well Service Co.', 'ma-well-avon-service-co', 'well_water_service', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Stoughton River Well & Water', 'ma-well-stoughton-river-avon', 'well_water_service', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    -- Braintree
    ('Braintree Well Drilling', 'ma-well-braintree-well-drilling', 'well_water_service', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Adams Well & Pump', 'ma-well-adams-braintree', 'well_water_service', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Braintree Water Well Service', 'ma-well-braintree-water-well', 'well_water_service', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Braintree Well Service Co.', 'ma-well-braintree-service-co', 'well_water_service', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Monatiquot Well & Water', 'ma-well-monatiquot-braintree', 'well_water_service', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    -- Brookline
    ('Brookline Well Drilling', 'ma-well-brookline-well-drilling', 'well_water_service', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Griggs Well & Pump', 'ma-well-griggs-brookline', 'well_water_service', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Brookline Water Well Service', 'ma-well-brookline-water-well', 'well_water_service', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Brookline Well Service Co.', 'ma-well-brookline-service-co', 'well_water_service', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Muddy River Well & Water', 'ma-well-muddy-river-brookline', 'well_water_service', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    -- Canton
    ('Canton Well Drilling', 'ma-well-canton-well-drilling', 'well_water_service', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Draper Well & Pump', 'ma-well-draper-canton', 'well_water_service', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Canton Water Well Service', 'ma-well-canton-water-well', 'well_water_service', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Canton Well Service Co.', 'ma-well-canton-service-co', 'well_water_service', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Neponset River Well & Water', 'ma-well-neponset-river-canton', 'well_water_service', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    -- Cohasset
    ('Cohasset Well Drilling', 'ma-well-cohasset-well-drilling', 'well_water_service', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Pratt Well & Pump', 'ma-well-pratt-cohasset', 'well_water_service', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Cohasset Water Well Service', 'ma-well-cohasset-water-well', 'well_water_service', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Cohasset Well Service Co.', 'ma-well-cohasset-service-co', 'well_water_service', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Sandy Cove Well & Water', 'ma-well-sandy-cove-cohasset', 'well_water_service', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    -- Dedham
    ('Dedham Well Drilling', 'ma-well-dedham-well-drilling', 'well_water_service', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Fairbanks Well & Pump', 'ma-well-fairbanks-dedham', 'well_water_service', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Dedham Water Well Service', 'ma-well-dedham-water-well', 'well_water_service', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Dedham Well Service Co.', 'ma-well-dedham-service-co', 'well_water_service', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Mother Brook Well & Water', 'ma-well-mother-brook-dedham', 'well_water_service', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    -- Dover
    ('Dover Well Drilling', 'ma-well-dover-well-drilling', 'well_water_service', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Chickering Well & Pump', 'ma-well-chickering-dover', 'well_water_service', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Dover Water Well Service', 'ma-well-dover-water-well', 'well_water_service', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Dover Well Service Co.', 'ma-well-dover-service-co', 'well_water_service', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Charles River Well & Water', 'ma-well-charles-river-dover', 'well_water_service', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    -- Foxborough
    ('Foxborough Well Drilling', 'ma-well-foxborough-well-drilling', 'well_water_service', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Carpenter Well & Pump', 'ma-well-carpenter-foxborough', 'well_water_service', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Foxborough Water Well Service', 'ma-well-foxborough-water-well', 'well_water_service', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Foxborough Well Service Co.', 'ma-well-foxborough-service-co', 'well_water_service', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Cocasset Well & Water', 'ma-well-cocasset-foxborough', 'well_water_service', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    -- Franklin
    ('Franklin Well Drilling', 'ma-well-franklin-well-drilling', 'well_water_service', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Metcalf Well & Pump', 'ma-well-metcalf-franklin', 'well_water_service', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Franklin Water Well Service', 'ma-well-franklin-water-well', 'well_water_service', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Franklin Well Service Co.', 'ma-well-franklin-service-co', 'well_water_service', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Mine Brook Well & Water', 'ma-well-mine-brook-franklin', 'well_water_service', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    -- Holbrook
    ('Holbrook Well Drilling', 'ma-well-holbrook-well-drilling', 'well_water_service', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Mann Well & Pump', 'ma-well-mann-holbrook', 'well_water_service', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Holbrook Water Well Service', 'ma-well-holbrook-water-well', 'well_water_service', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Holbrook Well Service Co.', 'ma-well-holbrook-service-co', 'well_water_service', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Cochato Well & Water', 'ma-well-cochato-holbrook', 'well_water_service', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    -- Medfield
    ('Medfield Well Drilling', 'ma-well-medfield-well-drilling', 'well_water_service', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Allen Well & Pump', 'ma-well-allen-medfield', 'well_water_service', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Medfield Water Well Service', 'ma-well-medfield-water-well', 'well_water_service', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Medfield Well Service Co.', 'ma-well-medfield-service-co', 'well_water_service', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Charles River Well & Water', 'ma-well-charles-river-medfield', 'well_water_service', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    -- Medway
    ('Medway Well Drilling', 'ma-well-medway-well-drilling', 'well_water_service', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Lovering Well & Pump', 'ma-well-lovering-medway', 'well_water_service', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Medway Water Well Service', 'ma-well-medway-water-well', 'well_water_service', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Medway Well Service Co.', 'ma-well-medway-service-co', 'well_water_service', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Chicken Brook Well & Water', 'ma-well-chicken-brook-medway', 'well_water_service', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    -- Millis
    ('Millis Well Drilling', 'ma-well-millis-well-drilling', 'well_water_service', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Richardson Well & Pump', 'ma-well-richardson-millis', 'well_water_service', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Millis Water Well Service', 'ma-well-millis-water-well', 'well_water_service', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Millis Well Service Co.', 'ma-well-millis-service-co', 'well_water_service', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Bogastow Well & Water', 'ma-well-bogastow-millis', 'well_water_service', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    -- Milton
    ('Milton Well Drilling', 'ma-well-milton-well-drilling', 'well_water_service', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Tucker Well & Pump', 'ma-well-tucker-milton', 'well_water_service', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Milton Water Well Service', 'ma-well-milton-water-well', 'well_water_service', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Milton Well Service Co.', 'ma-well-milton-service-co', 'well_water_service', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Neponset Well & Water', 'ma-well-neponset-milton', 'well_water_service', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    -- Needham
    ('Needham Well Drilling', 'ma-well-needham-well-drilling', 'well_water_service', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Kingsbury Well & Pump', 'ma-well-kingsbury-needham', 'well_water_service', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Needham Water Well Service', 'ma-well-needham-water-well', 'well_water_service', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Needham Well Service Co.', 'ma-well-needham-service-co', 'well_water_service', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Charles River Well & Water', 'ma-well-charles-river-needham', 'well_water_service', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    -- Norfolk
    ('Norfolk Well Drilling', 'ma-well-norfolk-well-drilling', 'well_water_service', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Mann Well & Pump', 'ma-well-mann-norfolk', 'well_water_service', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Norfolk Water Well Service', 'ma-well-norfolk-water-well', 'well_water_service', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Norfolk Well Service Co.', 'ma-well-norfolk-service-co', 'well_water_service', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Stop River Well & Water', 'ma-well-stop-river-norfolk', 'well_water_service', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    -- Norwood
    ('Norwood Well Drilling', 'ma-well-norwood-well-drilling', 'well_water_service', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Guild Well & Pump', 'ma-well-guild-norwood', 'well_water_service', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Norwood Water Well Service', 'ma-well-norwood-water-well', 'well_water_service', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Norwood Well Service Co.', 'ma-well-norwood-service-co', 'well_water_service', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Hawes Brook Well & Water', 'ma-well-hawes-brook-norwood', 'well_water_service', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    -- Plainville
    ('Plainville Well Drilling', 'ma-well-plainville-well-drilling', 'well_water_service', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Shepardson Well & Pump', 'ma-well-shepardson-plainville', 'well_water_service', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Plainville Water Well Service', 'ma-well-plainville-water-well', 'well_water_service', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Plainville Well Service Co.', 'ma-well-plainville-service-co', 'well_water_service', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Ten Mile Well & Water', 'ma-well-ten-mile-plainville', 'well_water_service', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    -- Quincy
    ('Quincy Well Drilling', 'ma-well-quincy-well-drilling', 'well_water_service', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Brackett Well & Pump', 'ma-well-brackett-quincy', 'well_water_service', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Quincy Water Well Service', 'ma-well-quincy-water-well', 'well_water_service', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Quincy Well Service Co.', 'ma-well-quincy-service-co', 'well_water_service', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Granite City Well & Water', 'ma-well-granite-city-quincy', 'well_water_service', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    -- Randolph
    ('Randolph Well Drilling', 'ma-well-randolph-well-drilling', 'well_water_service', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Turner Well & Pump', 'ma-well-turner-randolph', 'well_water_service', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Randolph Water Well Service', 'ma-well-randolph-water-well', 'well_water_service', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Randolph Well Service Co.', 'ma-well-randolph-service-co', 'well_water_service', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Ponkapoag Well & Water', 'ma-well-ponkapoag-randolph', 'well_water_service', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    -- Sharon
    ('Sharon Well Drilling', 'ma-well-sharon-well-drilling', 'well_water_service', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Billings Well & Pump', 'ma-well-billings-sharon', 'well_water_service', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Sharon Water Well Service', 'ma-well-sharon-water-well', 'well_water_service', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Sharon Well Service Co.', 'ma-well-sharon-service-co', 'well_water_service', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Massapoag Well & Water', 'ma-well-massapoag-sharon', 'well_water_service', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    -- Stoughton
    ('Stoughton Well Drilling', 'ma-well-stoughton-well-drilling', 'well_water_service', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Porter Well & Pump', 'ma-well-porter-stoughton', 'well_water_service', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Stoughton Water Well Service', 'ma-well-stoughton-water-well', 'well_water_service', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Stoughton Well Service Co.', 'ma-well-stoughton-service-co', 'well_water_service', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Muddy Pond Well & Water', 'ma-well-muddy-pond-stoughton', 'well_water_service', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    -- Walpole
    ('Walpole Well Drilling', 'ma-well-walpole-well-drilling', 'well_water_service', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Lewis Well & Pump', 'ma-well-lewis-walpole', 'well_water_service', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Walpole Water Well Service', 'ma-well-walpole-water-well', 'well_water_service', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Walpole Well Service Co.', 'ma-well-walpole-service-co', 'well_water_service', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Neponset Well & Water', 'ma-well-neponset-walpole', 'well_water_service', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    -- Wellesley
    ('Wellesley Well Drilling', 'ma-well-wellesley-well-drilling', 'well_water_service', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Hunnewell Well & Pump', 'ma-well-hunnewell-wellesley', 'well_water_service', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Wellesley Water Well Service', 'ma-well-wellesley-water-well', 'well_water_service', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Wellesley Well Service Co.', 'ma-well-wellesley-service-co', 'well_water_service', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Charles River Well & Water', 'ma-well-charles-river-wellesley', 'well_water_service', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    -- Westwood
    ('Westwood Well Drilling', 'ma-well-westwood-well-drilling', 'well_water_service', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Fisher Well & Pump', 'ma-well-fisher-westwood', 'well_water_service', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Westwood Water Well Service', 'ma-well-westwood-water-well', 'well_water_service', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Westwood Well Service Co.', 'ma-well-westwood-service-co', 'well_water_service', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Buckmaster Pond Well & Water', 'ma-well-buckmaster-pond-westwood', 'well_water_service', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    -- Weymouth
    ('Weymouth Well Drilling', 'ma-well-weymouth-well-drilling', 'well_water_service', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Nash Well & Pump', 'ma-well-nash-weymouth', 'well_water_service', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Weymouth Water Well Service', 'ma-well-weymouth-water-well', 'well_water_service', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Weymouth Well Service Co.', 'ma-well-weymouth-service-co', 'well_water_service', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Whitman Pond Well & Water', 'ma-well-whitman-pond-weymouth', 'well_water_service', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    -- Wrentham
    ('Wrentham Well Drilling', 'ma-well-wrentham-well-drilling', 'well_water_service', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Hawes Well & Pump', 'ma-well-hawes-wrentham', 'well_water_service', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Wrentham Water Well Service', 'ma-well-wrentham-water-well', 'well_water_service', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Wrentham Well Service Co.', 'ma-well-wrentham-service-co', 'well_water_service', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Eagle Brook Well & Water', 'ma-well-eagle-brook-wrentham', 'well_water_service', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 10: PLYMOUTH COUNTY LOCAL WELL WATER (27 towns x 5)
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Abington
    ('Abington Well Drilling', 'ma-well-abington-well-drilling', 'well_water_service', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Reed Well & Pump', 'ma-well-reed-abington', 'well_water_service', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Abington Water Well Service', 'ma-well-abington-water-well', 'well_water_service', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Abington Well Service Co.', 'ma-well-abington-service-co', 'well_water_service', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Shumatuscacant Well & Water', 'ma-well-shumatuscacant-abington', 'well_water_service', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    -- Bridgewater
    ('Bridgewater Well Drilling', 'ma-well-bridgewater-well-drilling', 'well_water_service', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Keith Well & Pump', 'ma-well-keith-bridgewater', 'well_water_service', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Water Well Service', 'ma-well-bridgewater-water-well', 'well_water_service', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Well Service Co.', 'ma-well-bridgewater-service-co', 'well_water_service', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Town River Well & Water', 'ma-well-town-river-bridgewater', 'well_water_service', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    -- Brockton
    ('Brockton Well Drilling', 'ma-well-brockton-well-drilling', 'well_water_service', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Howard Well & Pump', 'ma-well-howard-brockton', 'well_water_service', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Brockton Water Well Service', 'ma-well-brockton-water-well', 'well_water_service', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Brockton Well Service Co.', 'ma-well-brockton-service-co', 'well_water_service', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Salisbury Brook Well & Water', 'ma-well-salisbury-brook-brockton', 'well_water_service', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    -- Carver
    ('Carver Well Drilling', 'ma-well-carver-well-drilling', 'well_water_service', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Shurtleff Well & Pump', 'ma-well-shurtleff-carver', 'well_water_service', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Carver Water Well Service', 'ma-well-carver-water-well', 'well_water_service', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Carver Well Service Co.', 'ma-well-carver-service-co', 'well_water_service', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Cranberry Bog Well & Water', 'ma-well-cranberry-bog-carver', 'well_water_service', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    -- Duxbury
    ('Duxbury Well Drilling', 'ma-well-duxbury-well-drilling', 'well_water_service', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Standish Well & Pump', 'ma-well-standish-duxbury', 'well_water_service', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Duxbury Water Well Service', 'ma-well-duxbury-water-well', 'well_water_service', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Duxbury Well Service Co.', 'ma-well-duxbury-service-co', 'well_water_service', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Duxbury Bay Well & Water', 'ma-well-duxbury-bay-duxbury', 'well_water_service', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    -- East Bridgewater
    ('East Bridgewater Well Drilling', 'ma-well-east-bridgewater-well-drilling', 'well_water_service', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('Whitman Well & Pump', 'ma-well-whitman-east-bridgewater', 'well_water_service', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('East Bridgewater Water Well Service', 'ma-well-east-bridgewater-water-well', 'well_water_service', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('East Bridgewater Well Service Co.', 'ma-well-east-bridgewater-service-co', 'well_water_service', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('Satucket River Well & Water', 'ma-well-satucket-river-east-bridgewater', 'well_water_service', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    -- Halifax
    ('Halifax Well Drilling', 'ma-well-halifax-well-drilling', 'well_water_service', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Thompson Well & Pump', 'ma-well-thompson-halifax', 'well_water_service', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Halifax Water Well Service', 'ma-well-halifax-water-well', 'well_water_service', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Halifax Well Service Co.', 'ma-well-halifax-service-co', 'well_water_service', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Monponsett Well & Water', 'ma-well-monponsett-halifax', 'well_water_service', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    -- Hanover
    ('Hanover Well Drilling', 'ma-well-hanover-well-drilling', 'well_water_service', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Stetson Well & Pump', 'ma-well-stetson-hanover', 'well_water_service', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Hanover Water Well Service', 'ma-well-hanover-water-well', 'well_water_service', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Hanover Well Service Co.', 'ma-well-hanover-service-co', 'well_water_service', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Indian Head Well & Water', 'ma-well-indian-head-hanover', 'well_water_service', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    -- Hanson
    ('Hanson Well Drilling', 'ma-well-hanson-well-drilling', 'well_water_service', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Phillips Well & Pump', 'ma-well-phillips-hanson', 'well_water_service', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Hanson Water Well Service', 'ma-well-hanson-water-well', 'well_water_service', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Hanson Well Service Co.', 'ma-well-hanson-service-co', 'well_water_service', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Maquan Pond Well & Water', 'ma-well-maquan-pond-hanson', 'well_water_service', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    -- Hingham
    ('Hingham Well Drilling', 'ma-well-hingham-well-drilling', 'well_water_service', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Lincoln Well & Pump', 'ma-well-lincoln-hingham', 'well_water_service', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Hingham Water Well Service', 'ma-well-hingham-water-well', 'well_water_service', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Hingham Well Service Co.', 'ma-well-hingham-service-co', 'well_water_service', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Hingham Harbor Well & Water', 'ma-well-hingham-harbor-hingham', 'well_water_service', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    -- Hull
    ('Hull Well Drilling', 'ma-well-hull-well-drilling', 'well_water_service', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Mitchell Well & Pump', 'ma-well-mitchell-hull', 'well_water_service', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Hull Water Well Service', 'ma-well-hull-water-well', 'well_water_service', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Hull Well Service Co.', 'ma-well-hull-service-co', 'well_water_service', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Nantasket Well & Water', 'ma-well-nantasket-hull', 'well_water_service', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    -- Kingston
    ('Kingston Well Drilling', 'ma-well-kingston-well-drilling', 'well_water_service', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Bradford Well & Pump', 'ma-well-bradford-kingston', 'well_water_service', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Kingston Water Well Service', 'ma-well-kingston-water-well', 'well_water_service', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Kingston Well Service Co.', 'ma-well-kingston-service-co', 'well_water_service', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Jones River Well & Water', 'ma-well-jones-river-kingston', 'well_water_service', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    -- Lakeville
    ('Lakeville Well Drilling', 'ma-well-lakeville-well-drilling', 'well_water_service', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Haskins Well & Pump', 'ma-well-haskins-lakeville', 'well_water_service', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Lakeville Water Well Service', 'ma-well-lakeville-water-well', 'well_water_service', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Lakeville Well Service Co.', 'ma-well-lakeville-service-co', 'well_water_service', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Assawompset Well & Water', 'ma-well-assawompset-lakeville', 'well_water_service', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    -- Marion
    ('Marion Well Drilling', 'ma-well-marion-well-drilling', 'well_water_service', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Delano Well & Pump', 'ma-well-delano-marion', 'well_water_service', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Marion Water Well Service', 'ma-well-marion-water-well', 'well_water_service', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Marion Well Service Co.', 'ma-well-marion-service-co', 'well_water_service', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Sippican Harbor Well & Water', 'ma-well-sippican-harbor-marion', 'well_water_service', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    -- Marshfield
    ('Marshfield Well Drilling', 'ma-well-marshfield-well-drilling', 'well_water_service', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Winslow Well & Pump', 'ma-well-winslow-marshfield', 'well_water_service', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Marshfield Water Well Service', 'ma-well-marshfield-water-well', 'well_water_service', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Marshfield Well Service Co.', 'ma-well-marshfield-service-co', 'well_water_service', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Green Harbor Well & Water', 'ma-well-green-harbor-marshfield', 'well_water_service', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    -- Mattapoisett
    ('Mattapoisett Well Drilling', 'ma-well-mattapoisett-well-drilling', 'well_water_service', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Cannon Well & Pump', 'ma-well-cannon-mattapoisett', 'well_water_service', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Mattapoisett Water Well Service', 'ma-well-mattapoisett-water-well', 'well_water_service', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Mattapoisett Well Service Co.', 'ma-well-mattapoisett-service-co', 'well_water_service', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Mattapoisett Harbor Well & Water', 'ma-well-mattapoisett-harbor-mattapoisett', 'well_water_service', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    -- Middleborough
    ('Middleborough Well Drilling', 'ma-well-middleborough-well-drilling', 'well_water_service', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Wood Well & Pump', 'ma-well-wood-middleborough', 'well_water_service', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Middleborough Water Well Service', 'ma-well-middleborough-water-well', 'well_water_service', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Middleborough Well Service Co.', 'ma-well-middleborough-service-co', 'well_water_service', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Nemasket Well & Water', 'ma-well-nemasket-middleborough', 'well_water_service', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    -- Norwell
    ('Norwell Well Drilling', 'ma-well-norwell-well-drilling', 'well_water_service', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Jacobs Well & Pump', 'ma-well-jacobs-norwell', 'well_water_service', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Norwell Water Well Service', 'ma-well-norwell-water-well', 'well_water_service', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Norwell Well Service Co.', 'ma-well-norwell-service-co', 'well_water_service', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('North River Well & Water', 'ma-well-north-river-norwell', 'well_water_service', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    -- Pembroke
    ('Pembroke Well Drilling', 'ma-well-pembroke-well-drilling', 'well_water_service', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Barker Well & Pump', 'ma-well-barker-pembroke', 'well_water_service', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Pembroke Water Well Service', 'ma-well-pembroke-water-well', 'well_water_service', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Pembroke Well Service Co.', 'ma-well-pembroke-service-co', 'well_water_service', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Silver Lake Well & Water', 'ma-well-silver-lake-pembroke', 'well_water_service', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    -- Plymouth
    ('Plymouth Well Drilling', 'ma-well-plymouth-well-drilling', 'well_water_service', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Bradford Well & Pump', 'ma-well-bradford-plymouth', 'well_water_service', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Plymouth Water Well Service', 'ma-well-plymouth-water-well', 'well_water_service', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Plymouth Well Service Co.', 'ma-well-plymouth-service-co', 'well_water_service', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Pilgrim Well & Water', 'ma-well-pilgrim-plymouth', 'well_water_service', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    -- Plympton
    ('Plympton Well Drilling', 'ma-well-plympton-well-drilling', 'well_water_service', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Soule Well & Pump', 'ma-well-soule-plympton', 'well_water_service', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Plympton Water Well Service', 'ma-well-plympton-water-well', 'well_water_service', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Plympton Well Service Co.', 'ma-well-plympton-service-co', 'well_water_service', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Winnetuxet Well & Water', 'ma-well-winnetuxet-plympton', 'well_water_service', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    -- Rochester
    ('Rochester Well Drilling', 'ma-well-rochester-well-drilling', 'well_water_service', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Leonard Well & Pump', 'ma-well-leonard-rochester', 'well_water_service', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Rochester Water Well Service', 'ma-well-rochester-water-well', 'well_water_service', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Rochester Well Service Co.', 'ma-well-rochester-service-co', 'well_water_service', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Snipatuit Well & Water', 'ma-well-snipatuit-rochester', 'well_water_service', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    -- Rockland
    ('Rockland Well Drilling', 'ma-well-rockland-well-drilling', 'well_water_service', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Jenkins Well & Pump', 'ma-well-jenkins-rockland', 'well_water_service', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Rockland Water Well Service', 'ma-well-rockland-water-well', 'well_water_service', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Rockland Well Service Co.', 'ma-well-rockland-service-co', 'well_water_service', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('French Stream Well & Water', 'ma-well-french-stream-rockland', 'well_water_service', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    -- Scituate
    ('Scituate Well Drilling', 'ma-well-scituate-well-drilling', 'well_water_service', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Bailey Well & Pump', 'ma-well-bailey-scituate', 'well_water_service', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Scituate Water Well Service', 'ma-well-scituate-water-well', 'well_water_service', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Scituate Well Service Co.', 'ma-well-scituate-service-co', 'well_water_service', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Scituate Harbor Well & Water', 'ma-well-scituate-harbor-scituate', 'well_water_service', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    -- Wareham
    ('Wareham Well Drilling', 'ma-well-wareham-well-drilling', 'well_water_service', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Fearing Well & Pump', 'ma-well-fearing-wareham', 'well_water_service', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Wareham Water Well Service', 'ma-well-wareham-water-well', 'well_water_service', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Wareham Well Service Co.', 'ma-well-wareham-service-co', 'well_water_service', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Onset Bay Well & Water', 'ma-well-onset-bay-wareham', 'well_water_service', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    -- West Bridgewater
    ('West Bridgewater Well Drilling', 'ma-well-west-bridgewater-well-drilling', 'well_water_service', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('Howard Well & Pump', 'ma-well-howard-west-bridgewater', 'well_water_service', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('West Bridgewater Water Well Service', 'ma-well-west-bridgewater-water-well', 'well_water_service', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('West Bridgewater Well Service Co.', 'ma-well-west-bridgewater-service-co', 'well_water_service', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('Town River Well & Water', 'ma-well-town-river-west-bridgewater', 'well_water_service', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    -- Whitman
    ('Whitman Well Drilling', 'ma-well-whitman-well-drilling', 'well_water_service', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Hobart Well & Pump', 'ma-well-hobart-whitman', 'well_water_service', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Whitman Water Well Service', 'ma-well-whitman-water-well', 'well_water_service', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Whitman Well Service Co.', 'ma-well-whitman-service-co', 'well_water_service', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Shumatuscacant Well & Water', 'ma-well-shumatuscacant-whitman', 'well_water_service', NULL, ARRAY['Whitman','MA','Plymouth'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 11: MA REGIONAL CHIMNEY COMPANIES
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    ('Boston''s Best Chimney', 'ma-chimney-bostons-best', 'chimney_sweep', 'https://www.bostonsbestchimney.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Clean Sweep Chimney', 'ma-chimney-clean-sweep', 'chimney_sweep', 'https://www.cleansweepchimney.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Admiralty Chimney', 'ma-chimney-admiralty', 'chimney_sweep', 'https://www.admiraltychimney.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Doctor Flue', 'ma-chimney-doctor-flue', 'chimney_sweep', 'https://www.doctorflue.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('New England Chimney Supply', 'ma-chimney-ne-chimney-supply', 'chimney_sweep', 'https://www.newenglandchimneysupply.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Patriot Chimney Services', 'ma-chimney-patriot', 'chimney_sweep', 'https://www.patriotchimneyservices.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Colonial Chimney Sweep', 'ma-chimney-colonial', 'chimney_sweep', 'https://www.colonialchimneysweep.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Bay State Chimney', 'ma-chimney-bay-state', 'chimney_sweep', 'https://www.baystatechimney.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 12: ESSEX COUNTY LOCAL CHIMNEY (33 towns x 5)
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Andover
    ('Andover Chimney Sweep', 'ma-chimney-andover-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Sullivan Chimney & Fireplace', 'ma-chimney-sullivan-andover', 'chimney_sweep', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Andover Chimney Services', 'ma-chimney-andover-services', 'chimney_sweep', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Andover Flue & Hearth', 'ma-chimney-andover-flue-hearth', 'chimney_sweep', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Shawsheen Chimney Care', 'ma-chimney-shawsheen-andover', 'chimney_sweep', NULL, ARRAY['Andover','MA','Essex'], NULL),
    -- Beverly
    ('Beverly Chimney Sweep', 'ma-chimney-beverly-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Harrington Chimney & Fireplace', 'ma-chimney-harrington-beverly', 'chimney_sweep', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Beverly Chimney Services', 'ma-chimney-beverly-services', 'chimney_sweep', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Beverly Flue & Hearth', 'ma-chimney-beverly-flue-hearth', 'chimney_sweep', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Bass River Chimney Care', 'ma-chimney-bass-river-beverly', 'chimney_sweep', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    -- Boxford
    ('Boxford Chimney Sweep', 'ma-chimney-boxford-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Kelleher Chimney & Fireplace', 'ma-chimney-kelleher-boxford', 'chimney_sweep', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Boxford Chimney Services', 'ma-chimney-boxford-services', 'chimney_sweep', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Boxford Flue & Hearth', 'ma-chimney-boxford-flue-hearth', 'chimney_sweep', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Hovey Chimney Care', 'ma-chimney-hovey-boxford', 'chimney_sweep', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    -- Danvers
    ('Danvers Chimney Sweep', 'ma-chimney-danvers-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Petralia Chimney & Fireplace', 'ma-chimney-petralia-danvers', 'chimney_sweep', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Danvers Chimney Services', 'ma-chimney-danvers-services', 'chimney_sweep', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Danvers Flue & Hearth', 'ma-chimney-danvers-flue-hearth', 'chimney_sweep', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Endicott Chimney Care', 'ma-chimney-endicott-danvers', 'chimney_sweep', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    -- Essex
    ('Essex Chimney Sweep', 'ma-chimney-essex-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Burnham Chimney & Fireplace', 'ma-chimney-burnham-essex', 'chimney_sweep', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Essex Chimney Services', 'ma-chimney-essex-services', 'chimney_sweep', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Essex Flue & Hearth', 'ma-chimney-essex-flue-hearth', 'chimney_sweep', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Cape Ann Chimney Care', 'ma-chimney-cape-ann-essex', 'chimney_sweep', NULL, ARRAY['Essex','MA','Essex'], NULL),
    -- Georgetown
    ('Georgetown Chimney Sweep', 'ma-chimney-georgetown-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Thurlow Chimney & Fireplace', 'ma-chimney-thurlow-georgetown', 'chimney_sweep', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Georgetown Chimney Services', 'ma-chimney-georgetown-services', 'chimney_sweep', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Georgetown Flue & Hearth', 'ma-chimney-georgetown-flue-hearth', 'chimney_sweep', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Pentucket Chimney Care', 'ma-chimney-pentucket-georgetown', 'chimney_sweep', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    -- Gloucester
    ('Gloucester Chimney Sweep', 'ma-chimney-gloucester-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Favazza Chimney & Fireplace', 'ma-chimney-favazza-gloucester', 'chimney_sweep', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Gloucester Chimney Services', 'ma-chimney-gloucester-services', 'chimney_sweep', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Gloucester Flue & Hearth', 'ma-chimney-gloucester-flue-hearth', 'chimney_sweep', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Harbor Chimney Care', 'ma-chimney-harbor-gloucester', 'chimney_sweep', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    -- Groveland
    ('Groveland Chimney Sweep', 'ma-chimney-groveland-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Batchelder Chimney & Fireplace', 'ma-chimney-batchelder-groveland', 'chimney_sweep', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Groveland Chimney Services', 'ma-chimney-groveland-services', 'chimney_sweep', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Groveland Flue & Hearth', 'ma-chimney-groveland-flue-hearth', 'chimney_sweep', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Merrimack Valley Chimney Care', 'ma-chimney-merrimack-valley-groveland', 'chimney_sweep', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    -- Hamilton
    ('Hamilton Chimney Sweep', 'ma-chimney-hamilton-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Appleton Chimney & Fireplace', 'ma-chimney-appleton-hamilton', 'chimney_sweep', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Hamilton Chimney Services', 'ma-chimney-hamilton-services', 'chimney_sweep', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Hamilton Flue & Hearth', 'ma-chimney-hamilton-flue-hearth', 'chimney_sweep', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Wenham Chimney Care', 'ma-chimney-wenham-hamilton', 'chimney_sweep', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    -- Haverhill
    ('Haverhill Chimney Sweep', 'ma-chimney-haverhill-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Moriarty Chimney & Fireplace', 'ma-chimney-moriarty-haverhill', 'chimney_sweep', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Haverhill Chimney Services', 'ma-chimney-haverhill-services', 'chimney_sweep', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Haverhill Flue & Hearth', 'ma-chimney-haverhill-flue-hearth', 'chimney_sweep', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Bradford Chimney Care', 'ma-chimney-bradford-haverhill', 'chimney_sweep', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    -- Ipswich
    ('Ipswich Chimney Sweep', 'ma-chimney-ipswich-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Goodhue Chimney & Fireplace', 'ma-chimney-goodhue-ipswich', 'chimney_sweep', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Ipswich Chimney Services', 'ma-chimney-ipswich-services', 'chimney_sweep', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Ipswich Flue & Hearth', 'ma-chimney-ipswich-flue-hearth', 'chimney_sweep', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Plum Island Chimney Care', 'ma-chimney-plum-island-ipswich', 'chimney_sweep', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    -- Lawrence
    ('Lawrence Chimney Sweep', 'ma-chimney-lawrence-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Ortiz Chimney & Fireplace', 'ma-chimney-ortiz-lawrence', 'chimney_sweep', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Lawrence Chimney Services', 'ma-chimney-lawrence-services', 'chimney_sweep', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Lawrence Flue & Hearth', 'ma-chimney-lawrence-flue-hearth', 'chimney_sweep', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Merrimack Chimney Care', 'ma-chimney-merrimack-lawrence', 'chimney_sweep', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    -- Lynn
    ('Lynn Chimney Sweep', 'ma-chimney-lynn-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Gallagher Chimney & Fireplace', 'ma-chimney-gallagher-lynn', 'chimney_sweep', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Lynn Chimney Services', 'ma-chimney-lynn-services', 'chimney_sweep', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Lynn Flue & Hearth', 'ma-chimney-lynn-flue-hearth', 'chimney_sweep', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Saugus River Chimney Care', 'ma-chimney-saugus-river-lynn', 'chimney_sweep', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    -- Lynnfield
    ('Lynnfield Chimney Sweep', 'ma-chimney-lynnfield-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Connolly Chimney & Fireplace', 'ma-chimney-connolly-lynnfield', 'chimney_sweep', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Lynnfield Chimney Services', 'ma-chimney-lynnfield-services', 'chimney_sweep', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Lynnfield Flue & Hearth', 'ma-chimney-lynnfield-flue-hearth', 'chimney_sweep', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Pillings Pond Chimney Care', 'ma-chimney-pillings-pond-lynnfield', 'chimney_sweep', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    -- Manchester-by-the-Sea
    ('Manchester-by-the-Sea Chimney Sweep', 'ma-chimney-manchester-by-the-sea-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Crowell Chimney & Fireplace', 'ma-chimney-crowell-manchester-by-the-sea', 'chimney_sweep', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Manchester-by-the-Sea Chimney Services', 'ma-chimney-manchester-by-the-sea-services', 'chimney_sweep', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Manchester-by-the-Sea Flue & Hearth', 'ma-chimney-manchester-by-the-sea-flue-hearth', 'chimney_sweep', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Singing Beach Chimney Care', 'ma-chimney-singing-beach-manchester-by-the-sea', 'chimney_sweep', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    -- Marblehead
    ('Marblehead Chimney Sweep', 'ma-chimney-marblehead-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Graves Chimney & Fireplace', 'ma-chimney-graves-marblehead', 'chimney_sweep', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Marblehead Chimney Services', 'ma-chimney-marblehead-services', 'chimney_sweep', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Marblehead Flue & Hearth', 'ma-chimney-marblehead-flue-hearth', 'chimney_sweep', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Harbor Neck Chimney Care', 'ma-chimney-harbor-neck-marblehead', 'chimney_sweep', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    -- Merrimac
    ('Merrimac Chimney Sweep', 'ma-chimney-merrimac-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Sargent Chimney & Fireplace', 'ma-chimney-sargent-merrimac', 'chimney_sweep', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Merrimac Chimney Services', 'ma-chimney-merrimac-services', 'chimney_sweep', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Merrimac Flue & Hearth', 'ma-chimney-merrimac-flue-hearth', 'chimney_sweep', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Lake Attitash Chimney Care', 'ma-chimney-lake-attitash-merrimac', 'chimney_sweep', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    -- Methuen
    ('Methuen Chimney Sweep', 'ma-chimney-methuen-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Fitzgerald Chimney & Fireplace', 'ma-chimney-fitzgerald-methuen', 'chimney_sweep', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Methuen Chimney Services', 'ma-chimney-methuen-services', 'chimney_sweep', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Methuen Flue & Hearth', 'ma-chimney-methuen-flue-hearth', 'chimney_sweep', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Spicket River Chimney Care', 'ma-chimney-spicket-river-methuen', 'chimney_sweep', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    -- Middleton
    ('Middleton Chimney Sweep', 'ma-chimney-middleton-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Richardson Chimney & Fireplace', 'ma-chimney-richardson-middleton', 'chimney_sweep', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Middleton Chimney Services', 'ma-chimney-middleton-services', 'chimney_sweep', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Middleton Flue & Hearth', 'ma-chimney-middleton-flue-hearth', 'chimney_sweep', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Ipswich River Chimney Care', 'ma-chimney-ipswich-river-middleton', 'chimney_sweep', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    -- Nahant
    ('Nahant Chimney Sweep', 'ma-chimney-nahant-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Tudor Chimney & Fireplace', 'ma-chimney-tudor-nahant', 'chimney_sweep', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Nahant Chimney Services', 'ma-chimney-nahant-services', 'chimney_sweep', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Nahant Flue & Hearth', 'ma-chimney-nahant-flue-hearth', 'chimney_sweep', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Lynn Harbor Chimney Care', 'ma-chimney-lynn-harbor-nahant', 'chimney_sweep', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    -- Newbury
    ('Newbury Chimney Sweep', 'ma-chimney-newbury-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Noyes Chimney & Fireplace', 'ma-chimney-noyes-newbury', 'chimney_sweep', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Newbury Chimney Services', 'ma-chimney-newbury-services', 'chimney_sweep', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Newbury Flue & Hearth', 'ma-chimney-newbury-flue-hearth', 'chimney_sweep', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Parker River Chimney Care', 'ma-chimney-parker-river-newbury', 'chimney_sweep', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    -- Newburyport
    ('Newburyport Chimney Sweep', 'ma-chimney-newburyport-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Coffin Chimney & Fireplace', 'ma-chimney-coffin-newburyport', 'chimney_sweep', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Newburyport Chimney Services', 'ma-chimney-newburyport-services', 'chimney_sweep', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Newburyport Flue & Hearth', 'ma-chimney-newburyport-flue-hearth', 'chimney_sweep', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Clipper City Chimney Care', 'ma-chimney-clipper-city-newburyport', 'chimney_sweep', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    -- North Andover
    ('North Andover Chimney Sweep', 'ma-chimney-north-andover-chimney-sweep', 'chimney_sweep', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Osgood Chimney & Fireplace', 'ma-chimney-osgood-north-andover', 'chimney_sweep', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('North Andover Chimney Services', 'ma-chimney-north-andover-services', 'chimney_sweep', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('North Andover Flue & Hearth', 'ma-chimney-north-andover-flue-hearth', 'chimney_sweep', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Cochichewick Chimney Care', 'ma-chimney-cochichewick-north-andover', 'chimney_sweep', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    -- Peabody
    ('Peabody Chimney Sweep', 'ma-chimney-peabody-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Osborne Chimney & Fireplace', 'ma-chimney-osborne-peabody', 'chimney_sweep', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Peabody Chimney Services', 'ma-chimney-peabody-services', 'chimney_sweep', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Peabody Flue & Hearth', 'ma-chimney-peabody-flue-hearth', 'chimney_sweep', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Brooksby Chimney Care', 'ma-chimney-brooksby-peabody', 'chimney_sweep', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    -- Rockport
    ('Rockport Chimney Sweep', 'ma-chimney-rockport-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Tarr Chimney & Fireplace', 'ma-chimney-tarr-rockport', 'chimney_sweep', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Rockport Chimney Services', 'ma-chimney-rockport-services', 'chimney_sweep', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Rockport Flue & Hearth', 'ma-chimney-rockport-flue-hearth', 'chimney_sweep', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Halibut Point Chimney Care', 'ma-chimney-halibut-point-rockport', 'chimney_sweep', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    -- Rowley
    ('Rowley Chimney Sweep', 'ma-chimney-rowley-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Gage Chimney & Fireplace', 'ma-chimney-gage-rowley', 'chimney_sweep', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Rowley Chimney Services', 'ma-chimney-rowley-services', 'chimney_sweep', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Rowley Flue & Hearth', 'ma-chimney-rowley-flue-hearth', 'chimney_sweep', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Mill River Chimney Care', 'ma-chimney-mill-river-rowley', 'chimney_sweep', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    -- Salem
    ('Salem Chimney Sweep', 'ma-chimney-salem-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Derby Chimney & Fireplace', 'ma-chimney-derby-salem', 'chimney_sweep', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Salem Chimney Services', 'ma-chimney-salem-services', 'chimney_sweep', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Salem Flue & Hearth', 'ma-chimney-salem-flue-hearth', 'chimney_sweep', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Witch City Chimney Care', 'ma-chimney-witch-city-salem', 'chimney_sweep', NULL, ARRAY['Salem','MA','Essex'], NULL),
    -- Salisbury
    ('Salisbury Chimney Sweep', 'ma-chimney-salisbury-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Pettengill Chimney & Fireplace', 'ma-chimney-pettengill-salisbury', 'chimney_sweep', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Salisbury Chimney Services', 'ma-chimney-salisbury-services', 'chimney_sweep', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Salisbury Flue & Hearth', 'ma-chimney-salisbury-flue-hearth', 'chimney_sweep', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Salisbury Beach Chimney Care', 'ma-chimney-salisbury-beach-salisbury', 'chimney_sweep', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    -- Saugus
    ('Saugus Chimney Sweep', 'ma-chimney-saugus-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Parsons Chimney & Fireplace', 'ma-chimney-parsons-saugus', 'chimney_sweep', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Saugus Chimney Services', 'ma-chimney-saugus-services', 'chimney_sweep', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Saugus Flue & Hearth', 'ma-chimney-saugus-flue-hearth', 'chimney_sweep', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Saugus River Chimney Care', 'ma-chimney-saugus-river-saugus', 'chimney_sweep', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    -- Swampscott
    ('Swampscott Chimney Sweep', 'ma-chimney-swampscott-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Blaney Chimney & Fireplace', 'ma-chimney-blaney-swampscott', 'chimney_sweep', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Swampscott Chimney Services', 'ma-chimney-swampscott-services', 'chimney_sweep', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Swampscott Flue & Hearth', 'ma-chimney-swampscott-flue-hearth', 'chimney_sweep', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('King Beach Chimney Care', 'ma-chimney-king-beach-swampscott', 'chimney_sweep', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    -- Topsfield
    ('Topsfield Chimney Sweep', 'ma-chimney-topsfield-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Perkins Chimney & Fireplace', 'ma-chimney-perkins-topsfield', 'chimney_sweep', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Topsfield Chimney Services', 'ma-chimney-topsfield-services', 'chimney_sweep', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Topsfield Flue & Hearth', 'ma-chimney-topsfield-flue-hearth', 'chimney_sweep', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Ipswich River Chimney Care', 'ma-chimney-ipswich-river-topsfield', 'chimney_sweep', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    -- Wenham
    ('Wenham Chimney Sweep', 'ma-chimney-wenham-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Dodge Chimney & Fireplace', 'ma-chimney-dodge-wenham', 'chimney_sweep', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Wenham Chimney Services', 'ma-chimney-wenham-services', 'chimney_sweep', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Wenham Flue & Hearth', 'ma-chimney-wenham-flue-hearth', 'chimney_sweep', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Pleasant Pond Chimney Care', 'ma-chimney-pleasant-pond-wenham', 'chimney_sweep', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    -- West Newbury
    ('West Newbury Chimney Sweep', 'ma-chimney-west-newbury-chimney-sweep', 'chimney_sweep', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('Chase Chimney & Fireplace', 'ma-chimney-chase-west-newbury', 'chimney_sweep', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('West Newbury Chimney Services', 'ma-chimney-west-newbury-services', 'chimney_sweep', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('West Newbury Flue & Hearth', 'ma-chimney-west-newbury-flue-hearth', 'chimney_sweep', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('Indian Hill Chimney Care', 'ma-chimney-indian-hill-west-newbury', 'chimney_sweep', NULL, ARRAY['West Newbury','MA','Essex'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 13: MIDDLESEX COUNTY LOCAL CHIMNEY (54 towns x 5)
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Acton
    ('Acton Chimney Sweep', 'ma-chimney-acton-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Robbins Chimney & Fireplace', 'ma-chimney-robbins-acton', 'chimney_sweep', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Acton Chimney Services', 'ma-chimney-acton-services', 'chimney_sweep', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Acton Flue & Hearth', 'ma-chimney-acton-flue-hearth', 'chimney_sweep', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Nagog Chimney Care', 'ma-chimney-nagog-acton', 'chimney_sweep', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    -- Arlington
    ('Arlington Chimney Sweep', 'ma-chimney-arlington-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Peirce Chimney & Fireplace', 'ma-chimney-peirce-arlington', 'chimney_sweep', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Arlington Chimney Services', 'ma-chimney-arlington-services', 'chimney_sweep', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Arlington Flue & Hearth', 'ma-chimney-arlington-flue-hearth', 'chimney_sweep', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Mystic Valley Chimney Care', 'ma-chimney-mystic-valley-arlington', 'chimney_sweep', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    -- Ashby
    ('Ashby Chimney Sweep', 'ma-chimney-ashby-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Kendall Chimney & Fireplace', 'ma-chimney-kendall-ashby', 'chimney_sweep', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Ashby Chimney Services', 'ma-chimney-ashby-services', 'chimney_sweep', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Ashby Flue & Hearth', 'ma-chimney-ashby-flue-hearth', 'chimney_sweep', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Fitchburg Road Chimney Care', 'ma-chimney-fitchburg-road-ashby', 'chimney_sweep', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    -- Ashland
    ('Ashland Chimney Sweep', 'ma-chimney-ashland-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Warren Chimney & Fireplace', 'ma-chimney-warren-ashland', 'chimney_sweep', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Ashland Chimney Services', 'ma-chimney-ashland-services', 'chimney_sweep', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Ashland Flue & Hearth', 'ma-chimney-ashland-flue-hearth', 'chimney_sweep', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Sudbury River Chimney Care', 'ma-chimney-sudbury-river-ashland', 'chimney_sweep', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    -- Ayer
    ('Ayer Chimney Sweep', 'ma-chimney-ayer-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Page Chimney & Fireplace', 'ma-chimney-page-ayer', 'chimney_sweep', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Ayer Chimney Services', 'ma-chimney-ayer-services', 'chimney_sweep', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Ayer Flue & Hearth', 'ma-chimney-ayer-flue-hearth', 'chimney_sweep', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Nashua River Chimney Care', 'ma-chimney-nashua-river-ayer', 'chimney_sweep', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    -- Bedford
    ('Bedford Chimney Sweep', 'ma-chimney-bedford-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Lane Chimney & Fireplace', 'ma-chimney-lane-bedford', 'chimney_sweep', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Bedford Chimney Services', 'ma-chimney-bedford-services', 'chimney_sweep', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Bedford Flue & Hearth', 'ma-chimney-bedford-flue-hearth', 'chimney_sweep', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Shawsheen Chimney Care', 'ma-chimney-shawsheen-bedford', 'chimney_sweep', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    -- Belmont
    ('Belmont Chimney Sweep', 'ma-chimney-belmont-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Underwood Chimney & Fireplace', 'ma-chimney-underwood-belmont', 'chimney_sweep', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Belmont Chimney Services', 'ma-chimney-belmont-services', 'chimney_sweep', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Belmont Flue & Hearth', 'ma-chimney-belmont-flue-hearth', 'chimney_sweep', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Belmont Hill Chimney Care', 'ma-chimney-belmont-hill-belmont', 'chimney_sweep', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    -- Billerica
    ('Billerica Chimney Sweep', 'ma-chimney-billerica-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Manning Chimney & Fireplace', 'ma-chimney-manning-billerica', 'chimney_sweep', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Billerica Chimney Services', 'ma-chimney-billerica-services', 'chimney_sweep', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Billerica Flue & Hearth', 'ma-chimney-billerica-flue-hearth', 'chimney_sweep', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Concord River Chimney Care', 'ma-chimney-concord-river-billerica', 'chimney_sweep', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    -- Boxborough
    ('Boxborough Chimney Sweep', 'ma-chimney-boxborough-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Whitcomb Chimney & Fireplace', 'ma-chimney-whitcomb-boxborough', 'chimney_sweep', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Boxborough Chimney Services', 'ma-chimney-boxborough-services', 'chimney_sweep', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Boxborough Flue & Hearth', 'ma-chimney-boxborough-flue-hearth', 'chimney_sweep', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Blanchard Chimney Care', 'ma-chimney-blanchard-boxborough', 'chimney_sweep', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    -- Burlington
    ('Burlington Chimney Sweep', 'ma-chimney-burlington-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Simonds Chimney & Fireplace', 'ma-chimney-simonds-burlington', 'chimney_sweep', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Burlington Chimney Services', 'ma-chimney-burlington-services', 'chimney_sweep', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Burlington Flue & Hearth', 'ma-chimney-burlington-flue-hearth', 'chimney_sweep', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Vine Brook Chimney Care', 'ma-chimney-vine-brook-burlington', 'chimney_sweep', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    -- Cambridge
    ('Cambridge Chimney Sweep', 'ma-chimney-cambridge-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Longfellow Chimney & Fireplace', 'ma-chimney-longfellow-cambridge', 'chimney_sweep', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Cambridge Chimney Services', 'ma-chimney-cambridge-services', 'chimney_sweep', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Cambridge Flue & Hearth', 'ma-chimney-cambridge-flue-hearth', 'chimney_sweep', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Charles River Chimney Care', 'ma-chimney-charles-river-cambridge', 'chimney_sweep', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    -- Carlisle
    ('Carlisle Chimney Sweep', 'ma-chimney-carlisle-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Heald Chimney & Fireplace', 'ma-chimney-heald-carlisle', 'chimney_sweep', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Carlisle Chimney Services', 'ma-chimney-carlisle-services', 'chimney_sweep', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Carlisle Flue & Hearth', 'ma-chimney-carlisle-flue-hearth', 'chimney_sweep', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Concord River Chimney Care', 'ma-chimney-concord-river-carlisle', 'chimney_sweep', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    -- Chelmsford
    ('Chelmsford Chimney Sweep', 'ma-chimney-chelmsford-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Parkhurst Chimney & Fireplace', 'ma-chimney-parkhurst-chelmsford', 'chimney_sweep', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Chelmsford Chimney Services', 'ma-chimney-chelmsford-services', 'chimney_sweep', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Chelmsford Flue & Hearth', 'ma-chimney-chelmsford-flue-hearth', 'chimney_sweep', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Merrimack Chimney Care', 'ma-chimney-merrimack-chelmsford', 'chimney_sweep', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    -- Concord
    ('Concord Chimney Sweep', 'ma-chimney-concord-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Thoreau Chimney & Fireplace', 'ma-chimney-thoreau-concord', 'chimney_sweep', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Concord Chimney Services', 'ma-chimney-concord-services', 'chimney_sweep', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Concord Flue & Hearth', 'ma-chimney-concord-flue-hearth', 'chimney_sweep', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Walden Chimney Care', 'ma-chimney-walden-concord', 'chimney_sweep', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    -- Dracut
    ('Dracut Chimney Sweep', 'ma-chimney-dracut-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Collinsworth Chimney & Fireplace', 'ma-chimney-collinsworth-dracut', 'chimney_sweep', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Dracut Chimney Services', 'ma-chimney-dracut-services', 'chimney_sweep', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Dracut Flue & Hearth', 'ma-chimney-dracut-flue-hearth', 'chimney_sweep', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Merrimack Chimney Care', 'ma-chimney-merrimack-dracut', 'chimney_sweep', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    -- Dunstable
    ('Dunstable Chimney Sweep', 'ma-chimney-dunstable-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('French Chimney & Fireplace', 'ma-chimney-french-dunstable', 'chimney_sweep', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Dunstable Chimney Services', 'ma-chimney-dunstable-services', 'chimney_sweep', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Dunstable Flue & Hearth', 'ma-chimney-dunstable-flue-hearth', 'chimney_sweep', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Salmon Brook Chimney Care', 'ma-chimney-salmon-brook-dunstable', 'chimney_sweep', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    -- Everett
    ('Everett Chimney Sweep', 'ma-chimney-everett-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Glendale Chimney & Fireplace', 'ma-chimney-glendale-everett', 'chimney_sweep', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Everett Chimney Services', 'ma-chimney-everett-services', 'chimney_sweep', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Everett Flue & Hearth', 'ma-chimney-everett-flue-hearth', 'chimney_sweep', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Malden River Chimney Care', 'ma-chimney-malden-river-everett', 'chimney_sweep', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    -- Framingham
    ('Framingham Chimney Sweep', 'ma-chimney-framingham-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Buckley Chimney & Fireplace', 'ma-chimney-buckley-framingham', 'chimney_sweep', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Framingham Chimney Services', 'ma-chimney-framingham-services', 'chimney_sweep', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Framingham Flue & Hearth', 'ma-chimney-framingham-flue-hearth', 'chimney_sweep', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('MetroWest Chimney Care', 'ma-chimney-metrowest-framingham', 'chimney_sweep', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    -- Groton
    ('Groton Chimney Sweep', 'ma-chimney-groton-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Prescott Chimney & Fireplace', 'ma-chimney-prescott-groton', 'chimney_sweep', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Groton Chimney Services', 'ma-chimney-groton-services', 'chimney_sweep', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Groton Flue & Hearth', 'ma-chimney-groton-flue-hearth', 'chimney_sweep', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Nashua River Chimney Care', 'ma-chimney-nashua-river-groton', 'chimney_sweep', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    -- Holliston
    ('Holliston Chimney Sweep', 'ma-chimney-holliston-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Cutler Chimney & Fireplace', 'ma-chimney-cutler-holliston', 'chimney_sweep', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Holliston Chimney Services', 'ma-chimney-holliston-services', 'chimney_sweep', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Holliston Flue & Hearth', 'ma-chimney-holliston-flue-hearth', 'chimney_sweep', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Bogastow Chimney Care', 'ma-chimney-bogastow-holliston', 'chimney_sweep', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    -- Hopkinton
    ('Hopkinton Chimney Sweep', 'ma-chimney-hopkinton-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Claflin Chimney & Fireplace', 'ma-chimney-claflin-hopkinton', 'chimney_sweep', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Hopkinton Chimney Services', 'ma-chimney-hopkinton-services', 'chimney_sweep', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Hopkinton Flue & Hearth', 'ma-chimney-hopkinton-flue-hearth', 'chimney_sweep', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Whitehall Chimney Care', 'ma-chimney-whitehall-hopkinton', 'chimney_sweep', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    -- Hudson
    ('Hudson Chimney Sweep', 'ma-chimney-hudson-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Goodale Chimney & Fireplace', 'ma-chimney-goodale-hudson', 'chimney_sweep', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Hudson Chimney Services', 'ma-chimney-hudson-services', 'chimney_sweep', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Hudson Flue & Hearth', 'ma-chimney-hudson-flue-hearth', 'chimney_sweep', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Assabet River Chimney Care', 'ma-chimney-assabet-river-hudson', 'chimney_sweep', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    -- Lexington
    ('Lexington Chimney Sweep', 'ma-chimney-lexington-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Hancock Chimney & Fireplace', 'ma-chimney-hancock-lexington', 'chimney_sweep', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Lexington Chimney Services', 'ma-chimney-lexington-services', 'chimney_sweep', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Lexington Flue & Hearth', 'ma-chimney-lexington-flue-hearth', 'chimney_sweep', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Minuteman Chimney Care', 'ma-chimney-minuteman-lexington', 'chimney_sweep', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    -- Lincoln
    ('Lincoln Chimney Sweep', 'ma-chimney-lincoln-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Codman Chimney & Fireplace', 'ma-chimney-codman-lincoln', 'chimney_sweep', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Lincoln Chimney Services', 'ma-chimney-lincoln-services', 'chimney_sweep', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Lincoln Flue & Hearth', 'ma-chimney-lincoln-flue-hearth', 'chimney_sweep', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Farrar Pond Chimney Care', 'ma-chimney-farrar-pond-lincoln', 'chimney_sweep', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    -- Littleton
    ('Littleton Chimney Sweep', 'ma-chimney-littleton-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Hartwell Chimney & Fireplace', 'ma-chimney-hartwell-littleton', 'chimney_sweep', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Littleton Chimney Services', 'ma-chimney-littleton-services', 'chimney_sweep', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Littleton Flue & Hearth', 'ma-chimney-littleton-flue-hearth', 'chimney_sweep', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Nagog Pond Chimney Care', 'ma-chimney-nagog-pond-littleton', 'chimney_sweep', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    -- Lowell
    ('Lowell Chimney Sweep', 'ma-chimney-lowell-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Maguire Chimney & Fireplace', 'ma-chimney-maguire-lowell', 'chimney_sweep', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Lowell Chimney Services', 'ma-chimney-lowell-services', 'chimney_sweep', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Lowell Flue & Hearth', 'ma-chimney-lowell-flue-hearth', 'chimney_sweep', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Mill City Chimney Care', 'ma-chimney-mill-city-lowell', 'chimney_sweep', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    -- Malden
    ('Malden Chimney Sweep', 'ma-chimney-malden-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Corey Chimney & Fireplace', 'ma-chimney-corey-malden', 'chimney_sweep', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Malden Chimney Services', 'ma-chimney-malden-services', 'chimney_sweep', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Malden Flue & Hearth', 'ma-chimney-malden-flue-hearth', 'chimney_sweep', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Fellsway Chimney Care', 'ma-chimney-fellsway-malden', 'chimney_sweep', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    -- Marlborough
    ('Marlborough Chimney Sweep', 'ma-chimney-marlborough-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Bigelow Chimney & Fireplace', 'ma-chimney-bigelow-marlborough', 'chimney_sweep', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Marlborough Chimney Services', 'ma-chimney-marlborough-services', 'chimney_sweep', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Marlborough Flue & Hearth', 'ma-chimney-marlborough-flue-hearth', 'chimney_sweep', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Assabet Chimney Care', 'ma-chimney-assabet-marlborough', 'chimney_sweep', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    -- Maynard
    ('Maynard Chimney Sweep', 'ma-chimney-maynard-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Tobin Chimney & Fireplace', 'ma-chimney-tobin-maynard', 'chimney_sweep', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Maynard Chimney Services', 'ma-chimney-maynard-services', 'chimney_sweep', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Maynard Flue & Hearth', 'ma-chimney-maynard-flue-hearth', 'chimney_sweep', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Assabet River Chimney Care', 'ma-chimney-assabet-river-maynard', 'chimney_sweep', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    -- Medford
    ('Medford Chimney Sweep', 'ma-chimney-medford-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Brooks Chimney & Fireplace', 'ma-chimney-brooks-medford', 'chimney_sweep', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Medford Chimney Services', 'ma-chimney-medford-services', 'chimney_sweep', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Medford Flue & Hearth', 'ma-chimney-medford-flue-hearth', 'chimney_sweep', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Mystic River Chimney Care', 'ma-chimney-mystic-river-medford', 'chimney_sweep', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    -- Melrose
    ('Melrose Chimney Sweep', 'ma-chimney-melrose-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Lynde Chimney & Fireplace', 'ma-chimney-lynde-melrose', 'chimney_sweep', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Melrose Chimney Services', 'ma-chimney-melrose-services', 'chimney_sweep', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Melrose Flue & Hearth', 'ma-chimney-melrose-flue-hearth', 'chimney_sweep', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Ell Pond Chimney Care', 'ma-chimney-ell-pond-melrose', 'chimney_sweep', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    -- Natick
    ('Natick Chimney Sweep', 'ma-chimney-natick-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Morse Chimney & Fireplace', 'ma-chimney-morse-natick', 'chimney_sweep', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Natick Chimney Services', 'ma-chimney-natick-services', 'chimney_sweep', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Natick Flue & Hearth', 'ma-chimney-natick-flue-hearth', 'chimney_sweep', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Lake Cochituate Chimney Care', 'ma-chimney-lake-cochituate-natick', 'chimney_sweep', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    -- Newton
    ('Newton Chimney Sweep', 'ma-chimney-newton-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Otis Chimney & Fireplace', 'ma-chimney-otis-newton', 'chimney_sweep', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Newton Chimney Services', 'ma-chimney-newton-services', 'chimney_sweep', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Newton Flue & Hearth', 'ma-chimney-newton-flue-hearth', 'chimney_sweep', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Crystal Lake Chimney Care', 'ma-chimney-crystal-lake-newton', 'chimney_sweep', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    -- North Reading
    ('North Reading Chimney Sweep', 'ma-chimney-north-reading-chimney-sweep', 'chimney_sweep', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('Flint Chimney & Fireplace', 'ma-chimney-flint-north-reading', 'chimney_sweep', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('North Reading Chimney Services', 'ma-chimney-north-reading-services', 'chimney_sweep', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('North Reading Flue & Hearth', 'ma-chimney-north-reading-flue-hearth', 'chimney_sweep', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('Martins Pond Chimney Care', 'ma-chimney-martins-pond-north-reading', 'chimney_sweep', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    -- Pepperell
    ('Pepperell Chimney Sweep', 'ma-chimney-pepperell-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Shattuck Chimney & Fireplace', 'ma-chimney-shattuck-pepperell', 'chimney_sweep', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Pepperell Chimney Services', 'ma-chimney-pepperell-services', 'chimney_sweep', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Pepperell Flue & Hearth', 'ma-chimney-pepperell-flue-hearth', 'chimney_sweep', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Nissitissit Chimney Care', 'ma-chimney-nissitissit-pepperell', 'chimney_sweep', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    -- Reading
    ('Reading Chimney Sweep', 'ma-chimney-reading-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Parker Chimney & Fireplace', 'ma-chimney-parker-reading', 'chimney_sweep', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Reading Chimney Services', 'ma-chimney-reading-services', 'chimney_sweep', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Reading Flue & Hearth', 'ma-chimney-reading-flue-hearth', 'chimney_sweep', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Ipswich River Chimney Care', 'ma-chimney-ipswich-river-reading', 'chimney_sweep', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    -- Sherborn
    ('Sherborn Chimney Sweep', 'ma-chimney-sherborn-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Dowse Chimney & Fireplace', 'ma-chimney-dowse-sherborn', 'chimney_sweep', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Sherborn Chimney Services', 'ma-chimney-sherborn-services', 'chimney_sweep', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Sherborn Flue & Hearth', 'ma-chimney-sherborn-flue-hearth', 'chimney_sweep', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Farm Pond Chimney Care', 'ma-chimney-farm-pond-sherborn', 'chimney_sweep', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    -- Shirley
    ('Shirley Chimney Sweep', 'ma-chimney-shirley-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Longley Chimney & Fireplace', 'ma-chimney-longley-shirley', 'chimney_sweep', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Shirley Chimney Services', 'ma-chimney-shirley-services', 'chimney_sweep', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Shirley Flue & Hearth', 'ma-chimney-shirley-flue-hearth', 'chimney_sweep', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Catacunemaug Chimney Care', 'ma-chimney-catacunemaug-shirley', 'chimney_sweep', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    -- Somerville
    ('Somerville Chimney Sweep', 'ma-chimney-somerville-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Tufts Chimney & Fireplace', 'ma-chimney-tufts-somerville', 'chimney_sweep', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Somerville Chimney Services', 'ma-chimney-somerville-services', 'chimney_sweep', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Somerville Flue & Hearth', 'ma-chimney-somerville-flue-hearth', 'chimney_sweep', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Davis Square Chimney Care', 'ma-chimney-davis-square-somerville', 'chimney_sweep', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    -- Stoneham
    ('Stoneham Chimney Sweep', 'ma-chimney-stoneham-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Gould Chimney & Fireplace', 'ma-chimney-gould-stoneham', 'chimney_sweep', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Stoneham Chimney Services', 'ma-chimney-stoneham-services', 'chimney_sweep', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Stoneham Flue & Hearth', 'ma-chimney-stoneham-flue-hearth', 'chimney_sweep', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Spot Pond Chimney Care', 'ma-chimney-spot-pond-stoneham', 'chimney_sweep', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    -- Stow
    ('Stow Chimney Sweep', 'ma-chimney-stow-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Randall Chimney & Fireplace', 'ma-chimney-randall-stow', 'chimney_sweep', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Stow Chimney Services', 'ma-chimney-stow-services', 'chimney_sweep', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Stow Flue & Hearth', 'ma-chimney-stow-flue-hearth', 'chimney_sweep', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Lake Boon Chimney Care', 'ma-chimney-lake-boon-stow', 'chimney_sweep', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    -- Sudbury
    ('Sudbury Chimney Sweep', 'ma-chimney-sudbury-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Goodenow Chimney & Fireplace', 'ma-chimney-goodenow-sudbury', 'chimney_sweep', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Sudbury Chimney Services', 'ma-chimney-sudbury-services', 'chimney_sweep', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Sudbury Flue & Hearth', 'ma-chimney-sudbury-flue-hearth', 'chimney_sweep', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Sudbury River Chimney Care', 'ma-chimney-sudbury-river-sudbury', 'chimney_sweep', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    -- Tewksbury
    ('Tewksbury Chimney Sweep', 'ma-chimney-tewksbury-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Trull Chimney & Fireplace', 'ma-chimney-trull-tewksbury', 'chimney_sweep', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Tewksbury Chimney Services', 'ma-chimney-tewksbury-services', 'chimney_sweep', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Tewksbury Flue & Hearth', 'ma-chimney-tewksbury-flue-hearth', 'chimney_sweep', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Shawsheen River Chimney Care', 'ma-chimney-shawsheen-river-tewksbury', 'chimney_sweep', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    -- Townsend
    ('Townsend Chimney Sweep', 'ma-chimney-townsend-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Spaulding Chimney & Fireplace', 'ma-chimney-spaulding-townsend', 'chimney_sweep', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Townsend Chimney Services', 'ma-chimney-townsend-services', 'chimney_sweep', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Townsend Flue & Hearth', 'ma-chimney-townsend-flue-hearth', 'chimney_sweep', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Squannacook Chimney Care', 'ma-chimney-squannacook-townsend', 'chimney_sweep', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    -- Tyngsborough
    ('Tyngsborough Chimney Sweep', 'ma-chimney-tyngsborough-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Winslow Chimney & Fireplace', 'ma-chimney-winslow-tyngsborough', 'chimney_sweep', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Tyngsborough Chimney Services', 'ma-chimney-tyngsborough-services', 'chimney_sweep', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Tyngsborough Flue & Hearth', 'ma-chimney-tyngsborough-flue-hearth', 'chimney_sweep', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Merrimack River Chimney Care', 'ma-chimney-merrimack-river-tyngsborough', 'chimney_sweep', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    -- Wakefield
    ('Wakefield Chimney Sweep', 'ma-chimney-wakefield-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Sweetser Chimney & Fireplace', 'ma-chimney-sweetser-wakefield', 'chimney_sweep', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Wakefield Chimney Services', 'ma-chimney-wakefield-services', 'chimney_sweep', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Wakefield Flue & Hearth', 'ma-chimney-wakefield-flue-hearth', 'chimney_sweep', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Lake Quannapowitt Chimney Care', 'ma-chimney-lake-quannapowitt-wakefield', 'chimney_sweep', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    -- Waltham
    ('Waltham Chimney Sweep', 'ma-chimney-waltham-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Phelps Chimney & Fireplace', 'ma-chimney-phelps-waltham', 'chimney_sweep', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Waltham Chimney Services', 'ma-chimney-waltham-services', 'chimney_sweep', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Waltham Flue & Hearth', 'ma-chimney-waltham-flue-hearth', 'chimney_sweep', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Charles River Chimney Care', 'ma-chimney-charles-river-waltham', 'chimney_sweep', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    -- Watertown
    ('Watertown Chimney Sweep', 'ma-chimney-watertown-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Coolidge Chimney & Fireplace', 'ma-chimney-coolidge-watertown', 'chimney_sweep', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Watertown Chimney Services', 'ma-chimney-watertown-services', 'chimney_sweep', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Watertown Flue & Hearth', 'ma-chimney-watertown-flue-hearth', 'chimney_sweep', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Fresh Pond Chimney Care', 'ma-chimney-fresh-pond-watertown', 'chimney_sweep', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    -- Wayland
    ('Wayland Chimney Sweep', 'ma-chimney-wayland-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Heard Chimney & Fireplace', 'ma-chimney-heard-wayland', 'chimney_sweep', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Wayland Chimney Services', 'ma-chimney-wayland-services', 'chimney_sweep', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Wayland Flue & Hearth', 'ma-chimney-wayland-flue-hearth', 'chimney_sweep', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Dudley Pond Chimney Care', 'ma-chimney-dudley-pond-wayland', 'chimney_sweep', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    -- Westford
    ('Westford Chimney Sweep', 'ma-chimney-westford-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Fletcher Chimney & Fireplace', 'ma-chimney-fletcher-westford', 'chimney_sweep', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Westford Chimney Services', 'ma-chimney-westford-services', 'chimney_sweep', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Westford Flue & Hearth', 'ma-chimney-westford-flue-hearth', 'chimney_sweep', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Stony Brook Chimney Care', 'ma-chimney-stony-brook-westford', 'chimney_sweep', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    -- Weston
    ('Weston Chimney Sweep', 'ma-chimney-weston-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Hobbs Chimney & Fireplace', 'ma-chimney-hobbs-weston', 'chimney_sweep', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Weston Chimney Services', 'ma-chimney-weston-services', 'chimney_sweep', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Weston Flue & Hearth', 'ma-chimney-weston-flue-hearth', 'chimney_sweep', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Cat Rock Chimney Care', 'ma-chimney-cat-rock-weston', 'chimney_sweep', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    -- Wilmington
    ('Wilmington Chimney Sweep', 'ma-chimney-wilmington-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Harnden Chimney & Fireplace', 'ma-chimney-harnden-wilmington', 'chimney_sweep', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Wilmington Chimney Services', 'ma-chimney-wilmington-services', 'chimney_sweep', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Wilmington Flue & Hearth', 'ma-chimney-wilmington-flue-hearth', 'chimney_sweep', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Silver Lake Chimney Care', 'ma-chimney-silver-lake-wilmington', 'chimney_sweep', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    -- Winchester
    ('Winchester Chimney Sweep', 'ma-chimney-winchester-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Symmes Chimney & Fireplace', 'ma-chimney-symmes-winchester', 'chimney_sweep', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Winchester Chimney Services', 'ma-chimney-winchester-services', 'chimney_sweep', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Winchester Flue & Hearth', 'ma-chimney-winchester-flue-hearth', 'chimney_sweep', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Wedge Pond Chimney Care', 'ma-chimney-wedge-pond-winchester', 'chimney_sweep', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    -- Woburn
    ('Woburn Chimney Sweep', 'ma-chimney-woburn-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Thompson Chimney & Fireplace', 'ma-chimney-thompson-woburn', 'chimney_sweep', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Woburn Chimney Services', 'ma-chimney-woburn-services', 'chimney_sweep', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Woburn Flue & Hearth', 'ma-chimney-woburn-flue-hearth', 'chimney_sweep', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Horn Pond Chimney Care', 'ma-chimney-horn-pond-woburn', 'chimney_sweep', NULL, ARRAY['Woburn','MA','Middlesex'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 14: NORFOLK COUNTY LOCAL CHIMNEY (27 towns x 5)
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Avon
    ('Avon Chimney Sweep', 'ma-chimney-avon-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Littlefield Chimney & Fireplace', 'ma-chimney-littlefield-avon', 'chimney_sweep', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Avon Chimney Services', 'ma-chimney-avon-services', 'chimney_sweep', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Avon Flue & Hearth', 'ma-chimney-avon-flue-hearth', 'chimney_sweep', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Stoughton River Chimney Care', 'ma-chimney-stoughton-river-avon', 'chimney_sweep', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    -- Braintree
    ('Braintree Chimney Sweep', 'ma-chimney-braintree-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Adams Chimney & Fireplace', 'ma-chimney-adams-braintree', 'chimney_sweep', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Braintree Chimney Services', 'ma-chimney-braintree-services', 'chimney_sweep', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Braintree Flue & Hearth', 'ma-chimney-braintree-flue-hearth', 'chimney_sweep', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Monatiquot Chimney Care', 'ma-chimney-monatiquot-braintree', 'chimney_sweep', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    -- Brookline
    ('Brookline Chimney Sweep', 'ma-chimney-brookline-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Griggs Chimney & Fireplace', 'ma-chimney-griggs-brookline', 'chimney_sweep', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Brookline Chimney Services', 'ma-chimney-brookline-services', 'chimney_sweep', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Brookline Flue & Hearth', 'ma-chimney-brookline-flue-hearth', 'chimney_sweep', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Muddy River Chimney Care', 'ma-chimney-muddy-river-brookline', 'chimney_sweep', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    -- Canton
    ('Canton Chimney Sweep', 'ma-chimney-canton-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Draper Chimney & Fireplace', 'ma-chimney-draper-canton', 'chimney_sweep', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Canton Chimney Services', 'ma-chimney-canton-services', 'chimney_sweep', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Canton Flue & Hearth', 'ma-chimney-canton-flue-hearth', 'chimney_sweep', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Neponset River Chimney Care', 'ma-chimney-neponset-river-canton', 'chimney_sweep', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    -- Cohasset
    ('Cohasset Chimney Sweep', 'ma-chimney-cohasset-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Pratt Chimney & Fireplace', 'ma-chimney-pratt-cohasset', 'chimney_sweep', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Cohasset Chimney Services', 'ma-chimney-cohasset-services', 'chimney_sweep', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Cohasset Flue & Hearth', 'ma-chimney-cohasset-flue-hearth', 'chimney_sweep', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Sandy Cove Chimney Care', 'ma-chimney-sandy-cove-cohasset', 'chimney_sweep', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    -- Dedham
    ('Dedham Chimney Sweep', 'ma-chimney-dedham-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Fairbanks Chimney & Fireplace', 'ma-chimney-fairbanks-dedham', 'chimney_sweep', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Dedham Chimney Services', 'ma-chimney-dedham-services', 'chimney_sweep', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Dedham Flue & Hearth', 'ma-chimney-dedham-flue-hearth', 'chimney_sweep', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Mother Brook Chimney Care', 'ma-chimney-mother-brook-dedham', 'chimney_sweep', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    -- Dover
    ('Dover Chimney Sweep', 'ma-chimney-dover-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Chickering Chimney & Fireplace', 'ma-chimney-chickering-dover', 'chimney_sweep', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Dover Chimney Services', 'ma-chimney-dover-services', 'chimney_sweep', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Dover Flue & Hearth', 'ma-chimney-dover-flue-hearth', 'chimney_sweep', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Charles River Chimney Care', 'ma-chimney-charles-river-dover', 'chimney_sweep', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    -- Foxborough
    ('Foxborough Chimney Sweep', 'ma-chimney-foxborough-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Carpenter Chimney & Fireplace', 'ma-chimney-carpenter-foxborough', 'chimney_sweep', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Foxborough Chimney Services', 'ma-chimney-foxborough-services', 'chimney_sweep', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Foxborough Flue & Hearth', 'ma-chimney-foxborough-flue-hearth', 'chimney_sweep', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Cocasset Chimney Care', 'ma-chimney-cocasset-foxborough', 'chimney_sweep', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    -- Franklin
    ('Franklin Chimney Sweep', 'ma-chimney-franklin-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Metcalf Chimney & Fireplace', 'ma-chimney-metcalf-franklin', 'chimney_sweep', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Franklin Chimney Services', 'ma-chimney-franklin-services', 'chimney_sweep', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Franklin Flue & Hearth', 'ma-chimney-franklin-flue-hearth', 'chimney_sweep', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Mine Brook Chimney Care', 'ma-chimney-mine-brook-franklin', 'chimney_sweep', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    -- Holbrook
    ('Holbrook Chimney Sweep', 'ma-chimney-holbrook-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Mann Chimney & Fireplace', 'ma-chimney-mann-holbrook', 'chimney_sweep', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Holbrook Chimney Services', 'ma-chimney-holbrook-services', 'chimney_sweep', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Holbrook Flue & Hearth', 'ma-chimney-holbrook-flue-hearth', 'chimney_sweep', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Cochato Chimney Care', 'ma-chimney-cochato-holbrook', 'chimney_sweep', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    -- Medfield
    ('Medfield Chimney Sweep', 'ma-chimney-medfield-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Allen Chimney & Fireplace', 'ma-chimney-allen-medfield', 'chimney_sweep', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Medfield Chimney Services', 'ma-chimney-medfield-services', 'chimney_sweep', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Medfield Flue & Hearth', 'ma-chimney-medfield-flue-hearth', 'chimney_sweep', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Charles River Chimney Care', 'ma-chimney-charles-river-medfield', 'chimney_sweep', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    -- Medway
    ('Medway Chimney Sweep', 'ma-chimney-medway-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Lovering Chimney & Fireplace', 'ma-chimney-lovering-medway', 'chimney_sweep', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Medway Chimney Services', 'ma-chimney-medway-services', 'chimney_sweep', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Medway Flue & Hearth', 'ma-chimney-medway-flue-hearth', 'chimney_sweep', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Chicken Brook Chimney Care', 'ma-chimney-chicken-brook-medway', 'chimney_sweep', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    -- Millis
    ('Millis Chimney Sweep', 'ma-chimney-millis-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Richardson Chimney & Fireplace', 'ma-chimney-richardson-millis', 'chimney_sweep', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Millis Chimney Services', 'ma-chimney-millis-services', 'chimney_sweep', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Millis Flue & Hearth', 'ma-chimney-millis-flue-hearth', 'chimney_sweep', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Bogastow Chimney Care', 'ma-chimney-bogastow-millis', 'chimney_sweep', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    -- Milton
    ('Milton Chimney Sweep', 'ma-chimney-milton-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Tucker Chimney & Fireplace', 'ma-chimney-tucker-milton', 'chimney_sweep', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Milton Chimney Services', 'ma-chimney-milton-services', 'chimney_sweep', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Milton Flue & Hearth', 'ma-chimney-milton-flue-hearth', 'chimney_sweep', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Neponset Chimney Care', 'ma-chimney-neponset-milton', 'chimney_sweep', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    -- Needham
    ('Needham Chimney Sweep', 'ma-chimney-needham-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Kingsbury Chimney & Fireplace', 'ma-chimney-kingsbury-needham', 'chimney_sweep', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Needham Chimney Services', 'ma-chimney-needham-services', 'chimney_sweep', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Needham Flue & Hearth', 'ma-chimney-needham-flue-hearth', 'chimney_sweep', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Charles River Chimney Care', 'ma-chimney-charles-river-needham', 'chimney_sweep', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    -- Norfolk
    ('Norfolk Chimney Sweep', 'ma-chimney-norfolk-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Mann Chimney & Fireplace', 'ma-chimney-mann-norfolk', 'chimney_sweep', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Norfolk Chimney Services', 'ma-chimney-norfolk-services', 'chimney_sweep', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Norfolk Flue & Hearth', 'ma-chimney-norfolk-flue-hearth', 'chimney_sweep', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Stop River Chimney Care', 'ma-chimney-stop-river-norfolk', 'chimney_sweep', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    -- Norwood
    ('Norwood Chimney Sweep', 'ma-chimney-norwood-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Guild Chimney & Fireplace', 'ma-chimney-guild-norwood', 'chimney_sweep', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Norwood Chimney Services', 'ma-chimney-norwood-services', 'chimney_sweep', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Norwood Flue & Hearth', 'ma-chimney-norwood-flue-hearth', 'chimney_sweep', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Hawes Brook Chimney Care', 'ma-chimney-hawes-brook-norwood', 'chimney_sweep', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    -- Plainville
    ('Plainville Chimney Sweep', 'ma-chimney-plainville-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Shepardson Chimney & Fireplace', 'ma-chimney-shepardson-plainville', 'chimney_sweep', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Plainville Chimney Services', 'ma-chimney-plainville-services', 'chimney_sweep', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Plainville Flue & Hearth', 'ma-chimney-plainville-flue-hearth', 'chimney_sweep', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Ten Mile Chimney Care', 'ma-chimney-ten-mile-plainville', 'chimney_sweep', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    -- Quincy
    ('Quincy Chimney Sweep', 'ma-chimney-quincy-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Brackett Chimney & Fireplace', 'ma-chimney-brackett-quincy', 'chimney_sweep', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Quincy Chimney Services', 'ma-chimney-quincy-services', 'chimney_sweep', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Quincy Flue & Hearth', 'ma-chimney-quincy-flue-hearth', 'chimney_sweep', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Granite City Chimney Care', 'ma-chimney-granite-city-quincy', 'chimney_sweep', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    -- Randolph
    ('Randolph Chimney Sweep', 'ma-chimney-randolph-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Turner Chimney & Fireplace', 'ma-chimney-turner-randolph', 'chimney_sweep', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Randolph Chimney Services', 'ma-chimney-randolph-services', 'chimney_sweep', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Randolph Flue & Hearth', 'ma-chimney-randolph-flue-hearth', 'chimney_sweep', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Ponkapoag Chimney Care', 'ma-chimney-ponkapoag-randolph', 'chimney_sweep', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    -- Sharon
    ('Sharon Chimney Sweep', 'ma-chimney-sharon-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Billings Chimney & Fireplace', 'ma-chimney-billings-sharon', 'chimney_sweep', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Sharon Chimney Services', 'ma-chimney-sharon-services', 'chimney_sweep', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Sharon Flue & Hearth', 'ma-chimney-sharon-flue-hearth', 'chimney_sweep', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Massapoag Chimney Care', 'ma-chimney-massapoag-sharon', 'chimney_sweep', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    -- Stoughton
    ('Stoughton Chimney Sweep', 'ma-chimney-stoughton-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Porter Chimney & Fireplace', 'ma-chimney-porter-stoughton', 'chimney_sweep', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Stoughton Chimney Services', 'ma-chimney-stoughton-services', 'chimney_sweep', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Stoughton Flue & Hearth', 'ma-chimney-stoughton-flue-hearth', 'chimney_sweep', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Muddy Pond Chimney Care', 'ma-chimney-muddy-pond-stoughton', 'chimney_sweep', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    -- Walpole
    ('Walpole Chimney Sweep', 'ma-chimney-walpole-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Lewis Chimney & Fireplace', 'ma-chimney-lewis-walpole', 'chimney_sweep', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Walpole Chimney Services', 'ma-chimney-walpole-services', 'chimney_sweep', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Walpole Flue & Hearth', 'ma-chimney-walpole-flue-hearth', 'chimney_sweep', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Neponset Chimney Care', 'ma-chimney-neponset-walpole', 'chimney_sweep', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    -- Wellesley
    ('Wellesley Chimney Sweep', 'ma-chimney-wellesley-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Hunnewell Chimney & Fireplace', 'ma-chimney-hunnewell-wellesley', 'chimney_sweep', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Wellesley Chimney Services', 'ma-chimney-wellesley-services', 'chimney_sweep', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Wellesley Flue & Hearth', 'ma-chimney-wellesley-flue-hearth', 'chimney_sweep', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Charles River Chimney Care', 'ma-chimney-charles-river-wellesley', 'chimney_sweep', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    -- Westwood
    ('Westwood Chimney Sweep', 'ma-chimney-westwood-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Fisher Chimney & Fireplace', 'ma-chimney-fisher-westwood', 'chimney_sweep', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Westwood Chimney Services', 'ma-chimney-westwood-services', 'chimney_sweep', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Westwood Flue & Hearth', 'ma-chimney-westwood-flue-hearth', 'chimney_sweep', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Buckmaster Pond Chimney Care', 'ma-chimney-buckmaster-pond-westwood', 'chimney_sweep', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    -- Weymouth
    ('Weymouth Chimney Sweep', 'ma-chimney-weymouth-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Nash Chimney & Fireplace', 'ma-chimney-nash-weymouth', 'chimney_sweep', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Weymouth Chimney Services', 'ma-chimney-weymouth-services', 'chimney_sweep', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Weymouth Flue & Hearth', 'ma-chimney-weymouth-flue-hearth', 'chimney_sweep', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Whitman Pond Chimney Care', 'ma-chimney-whitman-pond-weymouth', 'chimney_sweep', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    -- Wrentham
    ('Wrentham Chimney Sweep', 'ma-chimney-wrentham-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Hawes Chimney & Fireplace', 'ma-chimney-hawes-wrentham', 'chimney_sweep', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Wrentham Chimney Services', 'ma-chimney-wrentham-services', 'chimney_sweep', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Wrentham Flue & Hearth', 'ma-chimney-wrentham-flue-hearth', 'chimney_sweep', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Eagle Brook Chimney Care', 'ma-chimney-eagle-brook-wrentham', 'chimney_sweep', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 15: PLYMOUTH COUNTY LOCAL CHIMNEY (27 towns x 5)
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Abington
    ('Abington Chimney Sweep', 'ma-chimney-abington-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Reed Chimney & Fireplace', 'ma-chimney-reed-abington', 'chimney_sweep', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Abington Chimney Services', 'ma-chimney-abington-services', 'chimney_sweep', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Abington Flue & Hearth', 'ma-chimney-abington-flue-hearth', 'chimney_sweep', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Shumatuscacant Chimney Care', 'ma-chimney-shumatuscacant-abington', 'chimney_sweep', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    -- Bridgewater
    ('Bridgewater Chimney Sweep', 'ma-chimney-bridgewater-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Keith Chimney & Fireplace', 'ma-chimney-keith-bridgewater', 'chimney_sweep', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Chimney Services', 'ma-chimney-bridgewater-services', 'chimney_sweep', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Flue & Hearth', 'ma-chimney-bridgewater-flue-hearth', 'chimney_sweep', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Town River Chimney Care', 'ma-chimney-town-river-bridgewater', 'chimney_sweep', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    -- Brockton
    ('Brockton Chimney Sweep', 'ma-chimney-brockton-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Howard Chimney & Fireplace', 'ma-chimney-howard-brockton', 'chimney_sweep', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Brockton Chimney Services', 'ma-chimney-brockton-services', 'chimney_sweep', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Brockton Flue & Hearth', 'ma-chimney-brockton-flue-hearth', 'chimney_sweep', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Salisbury Brook Chimney Care', 'ma-chimney-salisbury-brook-brockton', 'chimney_sweep', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    -- Carver
    ('Carver Chimney Sweep', 'ma-chimney-carver-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Shurtleff Chimney & Fireplace', 'ma-chimney-shurtleff-carver', 'chimney_sweep', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Carver Chimney Services', 'ma-chimney-carver-services', 'chimney_sweep', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Carver Flue & Hearth', 'ma-chimney-carver-flue-hearth', 'chimney_sweep', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Cranberry Bog Chimney Care', 'ma-chimney-cranberry-bog-carver', 'chimney_sweep', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    -- Duxbury
    ('Duxbury Chimney Sweep', 'ma-chimney-duxbury-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Standish Chimney & Fireplace', 'ma-chimney-standish-duxbury', 'chimney_sweep', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Duxbury Chimney Services', 'ma-chimney-duxbury-services', 'chimney_sweep', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Duxbury Flue & Hearth', 'ma-chimney-duxbury-flue-hearth', 'chimney_sweep', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Duxbury Bay Chimney Care', 'ma-chimney-duxbury-bay-duxbury', 'chimney_sweep', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    -- East Bridgewater
    ('East Bridgewater Chimney Sweep', 'ma-chimney-east-bridgewater-chimney-sweep', 'chimney_sweep', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('Whitman Chimney & Fireplace', 'ma-chimney-whitman-east-bridgewater', 'chimney_sweep', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('East Bridgewater Chimney Services', 'ma-chimney-east-bridgewater-services', 'chimney_sweep', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('East Bridgewater Flue & Hearth', 'ma-chimney-east-bridgewater-flue-hearth', 'chimney_sweep', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('Satucket River Chimney Care', 'ma-chimney-satucket-river-east-bridgewater', 'chimney_sweep', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    -- Halifax
    ('Halifax Chimney Sweep', 'ma-chimney-halifax-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Thompson Chimney & Fireplace', 'ma-chimney-thompson-halifax', 'chimney_sweep', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Halifax Chimney Services', 'ma-chimney-halifax-services', 'chimney_sweep', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Halifax Flue & Hearth', 'ma-chimney-halifax-flue-hearth', 'chimney_sweep', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Monponsett Chimney Care', 'ma-chimney-monponsett-halifax', 'chimney_sweep', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    -- Hanover
    ('Hanover Chimney Sweep', 'ma-chimney-hanover-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Stetson Chimney & Fireplace', 'ma-chimney-stetson-hanover', 'chimney_sweep', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Hanover Chimney Services', 'ma-chimney-hanover-services', 'chimney_sweep', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Hanover Flue & Hearth', 'ma-chimney-hanover-flue-hearth', 'chimney_sweep', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Indian Head Chimney Care', 'ma-chimney-indian-head-hanover', 'chimney_sweep', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    -- Hanson
    ('Hanson Chimney Sweep', 'ma-chimney-hanson-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Phillips Chimney & Fireplace', 'ma-chimney-phillips-hanson', 'chimney_sweep', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Hanson Chimney Services', 'ma-chimney-hanson-services', 'chimney_sweep', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Hanson Flue & Hearth', 'ma-chimney-hanson-flue-hearth', 'chimney_sweep', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Maquan Pond Chimney Care', 'ma-chimney-maquan-pond-hanson', 'chimney_sweep', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    -- Hingham
    ('Hingham Chimney Sweep', 'ma-chimney-hingham-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Lincoln Chimney & Fireplace', 'ma-chimney-lincoln-hingham', 'chimney_sweep', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Hingham Chimney Services', 'ma-chimney-hingham-services', 'chimney_sweep', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Hingham Flue & Hearth', 'ma-chimney-hingham-flue-hearth', 'chimney_sweep', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Hingham Harbor Chimney Care', 'ma-chimney-hingham-harbor-hingham', 'chimney_sweep', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    -- Hull
    ('Hull Chimney Sweep', 'ma-chimney-hull-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Mitchell Chimney & Fireplace', 'ma-chimney-mitchell-hull', 'chimney_sweep', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Hull Chimney Services', 'ma-chimney-hull-services', 'chimney_sweep', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Hull Flue & Hearth', 'ma-chimney-hull-flue-hearth', 'chimney_sweep', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Nantasket Chimney Care', 'ma-chimney-nantasket-hull', 'chimney_sweep', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    -- Kingston
    ('Kingston Chimney Sweep', 'ma-chimney-kingston-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Bradford Chimney & Fireplace', 'ma-chimney-bradford-kingston', 'chimney_sweep', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Kingston Chimney Services', 'ma-chimney-kingston-services', 'chimney_sweep', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Kingston Flue & Hearth', 'ma-chimney-kingston-flue-hearth', 'chimney_sweep', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Jones River Chimney Care', 'ma-chimney-jones-river-kingston', 'chimney_sweep', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    -- Lakeville
    ('Lakeville Chimney Sweep', 'ma-chimney-lakeville-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Haskins Chimney & Fireplace', 'ma-chimney-haskins-lakeville', 'chimney_sweep', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Lakeville Chimney Services', 'ma-chimney-lakeville-services', 'chimney_sweep', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Lakeville Flue & Hearth', 'ma-chimney-lakeville-flue-hearth', 'chimney_sweep', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Assawompset Chimney Care', 'ma-chimney-assawompset-lakeville', 'chimney_sweep', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    -- Marion
    ('Marion Chimney Sweep', 'ma-chimney-marion-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Delano Chimney & Fireplace', 'ma-chimney-delano-marion', 'chimney_sweep', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Marion Chimney Services', 'ma-chimney-marion-services', 'chimney_sweep', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Marion Flue & Hearth', 'ma-chimney-marion-flue-hearth', 'chimney_sweep', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Sippican Harbor Chimney Care', 'ma-chimney-sippican-harbor-marion', 'chimney_sweep', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    -- Marshfield
    ('Marshfield Chimney Sweep', 'ma-chimney-marshfield-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Winslow Chimney & Fireplace', 'ma-chimney-winslow-marshfield', 'chimney_sweep', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Marshfield Chimney Services', 'ma-chimney-marshfield-services', 'chimney_sweep', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Marshfield Flue & Hearth', 'ma-chimney-marshfield-flue-hearth', 'chimney_sweep', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Green Harbor Chimney Care', 'ma-chimney-green-harbor-marshfield', 'chimney_sweep', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    -- Mattapoisett
    ('Mattapoisett Chimney Sweep', 'ma-chimney-mattapoisett-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Cannon Chimney & Fireplace', 'ma-chimney-cannon-mattapoisett', 'chimney_sweep', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Mattapoisett Chimney Services', 'ma-chimney-mattapoisett-services', 'chimney_sweep', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Mattapoisett Flue & Hearth', 'ma-chimney-mattapoisett-flue-hearth', 'chimney_sweep', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Mattapoisett Harbor Chimney Care', 'ma-chimney-mattapoisett-harbor-mattapoisett', 'chimney_sweep', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    -- Middleborough
    ('Middleborough Chimney Sweep', 'ma-chimney-middleborough-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Wood Chimney & Fireplace', 'ma-chimney-wood-middleborough', 'chimney_sweep', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Middleborough Chimney Services', 'ma-chimney-middleborough-services', 'chimney_sweep', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Middleborough Flue & Hearth', 'ma-chimney-middleborough-flue-hearth', 'chimney_sweep', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Nemasket Chimney Care', 'ma-chimney-nemasket-middleborough', 'chimney_sweep', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    -- Norwell
    ('Norwell Chimney Sweep', 'ma-chimney-norwell-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Jacobs Chimney & Fireplace', 'ma-chimney-jacobs-norwell', 'chimney_sweep', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Norwell Chimney Services', 'ma-chimney-norwell-services', 'chimney_sweep', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Norwell Flue & Hearth', 'ma-chimney-norwell-flue-hearth', 'chimney_sweep', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('North River Chimney Care', 'ma-chimney-north-river-norwell', 'chimney_sweep', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    -- Pembroke
    ('Pembroke Chimney Sweep', 'ma-chimney-pembroke-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Barker Chimney & Fireplace', 'ma-chimney-barker-pembroke', 'chimney_sweep', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Pembroke Chimney Services', 'ma-chimney-pembroke-services', 'chimney_sweep', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Pembroke Flue & Hearth', 'ma-chimney-pembroke-flue-hearth', 'chimney_sweep', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Silver Lake Chimney Care', 'ma-chimney-silver-lake-pembroke', 'chimney_sweep', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    -- Plymouth
    ('Plymouth Chimney Sweep', 'ma-chimney-plymouth-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Bradford Chimney & Fireplace', 'ma-chimney-bradford-plymouth', 'chimney_sweep', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Plymouth Chimney Services', 'ma-chimney-plymouth-services', 'chimney_sweep', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Plymouth Flue & Hearth', 'ma-chimney-plymouth-flue-hearth', 'chimney_sweep', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Pilgrim Chimney Care', 'ma-chimney-pilgrim-plymouth', 'chimney_sweep', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    -- Plympton
    ('Plympton Chimney Sweep', 'ma-chimney-plympton-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Soule Chimney & Fireplace', 'ma-chimney-soule-plympton', 'chimney_sweep', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Plympton Chimney Services', 'ma-chimney-plympton-services', 'chimney_sweep', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Plympton Flue & Hearth', 'ma-chimney-plympton-flue-hearth', 'chimney_sweep', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Winnetuxet Chimney Care', 'ma-chimney-winnetuxet-plympton', 'chimney_sweep', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    -- Rochester
    ('Rochester Chimney Sweep', 'ma-chimney-rochester-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Leonard Chimney & Fireplace', 'ma-chimney-leonard-rochester', 'chimney_sweep', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Rochester Chimney Services', 'ma-chimney-rochester-services', 'chimney_sweep', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Rochester Flue & Hearth', 'ma-chimney-rochester-flue-hearth', 'chimney_sweep', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Snipatuit Chimney Care', 'ma-chimney-snipatuit-rochester', 'chimney_sweep', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    -- Rockland
    ('Rockland Chimney Sweep', 'ma-chimney-rockland-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Jenkins Chimney & Fireplace', 'ma-chimney-jenkins-rockland', 'chimney_sweep', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Rockland Chimney Services', 'ma-chimney-rockland-services', 'chimney_sweep', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Rockland Flue & Hearth', 'ma-chimney-rockland-flue-hearth', 'chimney_sweep', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('French Stream Chimney Care', 'ma-chimney-french-stream-rockland', 'chimney_sweep', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    -- Scituate
    ('Scituate Chimney Sweep', 'ma-chimney-scituate-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Bailey Chimney & Fireplace', 'ma-chimney-bailey-scituate', 'chimney_sweep', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Scituate Chimney Services', 'ma-chimney-scituate-services', 'chimney_sweep', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Scituate Flue & Hearth', 'ma-chimney-scituate-flue-hearth', 'chimney_sweep', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Scituate Harbor Chimney Care', 'ma-chimney-scituate-harbor-scituate', 'chimney_sweep', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    -- Wareham
    ('Wareham Chimney Sweep', 'ma-chimney-wareham-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Fearing Chimney & Fireplace', 'ma-chimney-fearing-wareham', 'chimney_sweep', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Wareham Chimney Services', 'ma-chimney-wareham-services', 'chimney_sweep', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Wareham Flue & Hearth', 'ma-chimney-wareham-flue-hearth', 'chimney_sweep', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Onset Bay Chimney Care', 'ma-chimney-onset-bay-wareham', 'chimney_sweep', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    -- West Bridgewater
    ('West Bridgewater Chimney Sweep', 'ma-chimney-west-bridgewater-chimney-sweep', 'chimney_sweep', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('Howard Chimney & Fireplace', 'ma-chimney-howard-west-bridgewater', 'chimney_sweep', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('West Bridgewater Chimney Services', 'ma-chimney-west-bridgewater-services', 'chimney_sweep', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('West Bridgewater Flue & Hearth', 'ma-chimney-west-bridgewater-flue-hearth', 'chimney_sweep', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('Town River Chimney Care', 'ma-chimney-town-river-west-bridgewater', 'chimney_sweep', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    -- Whitman
    ('Whitman Chimney Sweep', 'ma-chimney-whitman-chimney-sweep', 'chimney_sweep', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Hobart Chimney & Fireplace', 'ma-chimney-hobart-whitman', 'chimney_sweep', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Whitman Chimney Services', 'ma-chimney-whitman-services', 'chimney_sweep', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Whitman Flue & Hearth', 'ma-chimney-whitman-flue-hearth', 'chimney_sweep', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Shumatuscacant Chimney Care', 'ma-chimney-shumatuscacant-whitman', 'chimney_sweep', NULL, ARRAY['Whitman','MA','Plymouth'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;
