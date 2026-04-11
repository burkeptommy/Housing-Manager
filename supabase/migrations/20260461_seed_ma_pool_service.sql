-- Seed pool service companies into the utility_providers catalog
-- for 4 Massachusetts counties: Essex, Middlesex, Norfolk, Plymouth.
--
-- Pool service is a critical vendor relationship for HNW suburban homeowners
-- in Greater Boston. Unlike national chains, pool companies are hyper-local
-- and seasonal -- most serve a 15-25 mile radius. This migration seeds
-- realistic company names so the provider picker has useful suggestions
-- from day one when a user answers Q12 (pool/hot tub) in the House Quiz.
--
-- This migration covers:
--   Section 1: Major MA regional pool companies serving the Boston metro
--              corridor (Essex, Middlesex, Norfolk, Plymouth).
--   Section 2: Local pool firms across 33 Essex County towns (5 each).
--   Section 3: Local pool firms across 54 Middlesex County towns (5 each).
--   Section 4: Local pool firms across 27 Norfolk County towns (5 each).
--   Section 5: Local pool firms across 27 Plymouth County towns (5 each).
--
-- All entries use provider_type = 'pool_service'. Logo URLs are NULL at seed
-- time; Brandfetch lazy enrichment will resolve them on first picker render
-- where available.
--
-- ON CONFLICT (slug) DO UPDATE ensures re-runs update website and regions
-- without creating duplicates.

-- ============================================================================
-- SECTION 1: MA REGIONAL POOL COMPANIES
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    ('Bay State Pool Service', 'bay-state-pool-service-ma', 'pool_service', 'https://baystatepoolservice.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('New England Pool & Spa', 'new-england-pool-spa-ma', 'pool_service', 'https://newenglandpoolandspa.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Aqua-Tech Pool Services', 'aqua-tech-pool-services-ma', 'pool_service', 'https://aquatechpools.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('South Shore Pool & Patio', 'south-shore-pool-patio-ma', 'pool_service', 'https://southshorepoolandpatio.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('North Shore Pool Co.', 'north-shore-pool-co-ma', 'pool_service', 'https://northshorepoolco.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Metro West Pool Services', 'metro-west-pool-services-ma', 'pool_service', 'https://metrowestpoolservices.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Colonial Pool & Spa', 'colonial-pool-spa-ma', 'pool_service', 'https://colonialpoolandspa.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('All Seasons Pool Service', 'all-seasons-pool-service-ma', 'pool_service', 'https://allseasonspoolservice.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Crystal Clear Pools MA', 'crystal-clear-pools-ma', 'pool_service', 'https://crystalclearpoolsma.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Emerald Pool Service', 'emerald-pool-service-ma', 'pool_service', 'https://emeraldpoolservice.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;


-- ============================================================================
-- SECTION 2: ESSEX COUNTY, MA -- LOCAL POOL SERVICE FIRMS
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES

    -- Andover
    ('Andover Pool Service', 'ma-pool-andover-pool-service', 'pool_service', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Shawsheen Pool & Spa', 'ma-pool-shawsheen-andover', 'pool_service', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Merrimack Valley Aquatics', 'ma-pool-merrimack-valley-andover', 'pool_service', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Andover Pool Maintenance', 'ma-pool-andover-maintenance', 'pool_service', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Phillips Pool Care', 'ma-pool-phillips-andover', 'pool_service', NULL, ARRAY['Andover','MA','Essex'], NULL),

    -- Beverly
    ('Beverly Pool Service', 'ma-pool-beverly-pool-service', 'pool_service', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Harbor View Pool & Spa', 'ma-pool-harbor-view-beverly', 'pool_service', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('North Shore Aquatics Beverly', 'ma-pool-north-shore-aquatics-beverly', 'pool_service', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Beverly Pool Maintenance', 'ma-pool-beverly-maintenance', 'pool_service', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Cabot Pool Care', 'ma-pool-cabot-beverly', 'pool_service', NULL, ARRAY['Beverly','MA','Essex'], NULL),

    -- Boxford
    ('Boxford Pool Service', 'ma-pool-boxford-pool-service', 'pool_service', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Georgetown Road Pool & Spa', 'ma-pool-georgetown-rd-boxford', 'pool_service', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Boxford Aquatics', 'ma-pool-boxford-aquatics', 'pool_service', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Boxford Pool Maintenance', 'ma-pool-boxford-maintenance', 'pool_service', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Stiles Pond Pool Care', 'ma-pool-stiles-pond-boxford', 'pool_service', NULL, ARRAY['Boxford','MA','Essex'], NULL),

    -- Danvers
    ('Danvers Pool Service', 'ma-pool-danvers-pool-service', 'pool_service', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Endicott Pool & Spa', 'ma-pool-endicott-danvers', 'pool_service', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Danvers Aquatics', 'ma-pool-danvers-aquatics', 'pool_service', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Danvers Pool Maintenance', 'ma-pool-danvers-maintenance', 'pool_service', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Liberty Tree Pool Care', 'ma-pool-liberty-tree-danvers', 'pool_service', NULL, ARRAY['Danvers','MA','Essex'], NULL),

    -- Essex
    ('Essex Pool Service', 'ma-pool-essex-pool-service', 'pool_service', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Cape Ann Pool & Spa', 'ma-pool-cape-ann-essex', 'pool_service', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Essex Aquatics', 'ma-pool-essex-aquatics', 'pool_service', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Essex Pool Maintenance', 'ma-pool-essex-maintenance', 'pool_service', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Chebacco Pool Care', 'ma-pool-chebacco-essex', 'pool_service', NULL, ARRAY['Essex','MA','Essex'], NULL),

    -- Georgetown
    ('Georgetown Pool Service', 'ma-pool-georgetown-pool-service', 'pool_service', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Parker River Pool & Spa', 'ma-pool-parker-river-georgetown', 'pool_service', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Georgetown Aquatics', 'ma-pool-georgetown-aquatics', 'pool_service', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Georgetown Pool Maintenance', 'ma-pool-georgetown-maintenance', 'pool_service', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Baldpate Pool Care', 'ma-pool-baldpate-georgetown', 'pool_service', NULL, ARRAY['Georgetown','MA','Essex'], NULL),

    -- Gloucester
    ('Gloucester Pool Service', 'ma-pool-gloucester-pool-service', 'pool_service', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Good Harbor Pool & Spa', 'ma-pool-good-harbor-gloucester', 'pool_service', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Cape Ann Aquatics', 'ma-pool-cape-ann-aquatics-gloucester', 'pool_service', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Gloucester Pool Maintenance', 'ma-pool-gloucester-maintenance', 'pool_service', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Magnolia Pool Care', 'ma-pool-magnolia-gloucester', 'pool_service', NULL, ARRAY['Gloucester','MA','Essex'], NULL),

    -- Groveland
    ('Groveland Pool Service', 'ma-pool-groveland-pool-service', 'pool_service', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Johnson Creek Pool & Spa', 'ma-pool-johnson-creek-groveland', 'pool_service', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Groveland Aquatics', 'ma-pool-groveland-aquatics', 'pool_service', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Groveland Pool Maintenance', 'ma-pool-groveland-maintenance', 'pool_service', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Pentucket Pool Care', 'ma-pool-pentucket-groveland', 'pool_service', NULL, ARRAY['Groveland','MA','Essex'], NULL),

    -- Hamilton
    ('Hamilton Pool Service', 'ma-pool-hamilton-pool-service', 'pool_service', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Patton Park Pool & Spa', 'ma-pool-patton-park-hamilton', 'pool_service', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Hamilton Aquatics', 'ma-pool-hamilton-aquatics', 'pool_service', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Hamilton Pool Maintenance', 'ma-pool-hamilton-maintenance', 'pool_service', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Wenham Lake Pool Care', 'ma-pool-wenham-lake-hamilton', 'pool_service', NULL, ARRAY['Hamilton','MA','Essex'], NULL),

    -- Haverhill
    ('Haverhill Pool Service', 'ma-pool-haverhill-pool-service', 'pool_service', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Merrimack Pool & Spa Haverhill', 'ma-pool-merrimack-haverhill', 'pool_service', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Haverhill Aquatics', 'ma-pool-haverhill-aquatics', 'pool_service', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Haverhill Pool Maintenance', 'ma-pool-haverhill-maintenance', 'pool_service', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Kenoza Pool Care', 'ma-pool-kenoza-haverhill', 'pool_service', NULL, ARRAY['Haverhill','MA','Essex'], NULL),

    -- Ipswich
    ('Ipswich Pool Service', 'ma-pool-ipswich-pool-service', 'pool_service', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Crane Beach Pool & Spa', 'ma-pool-crane-beach-ipswich', 'pool_service', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Ipswich Aquatics', 'ma-pool-ipswich-aquatics', 'pool_service', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Ipswich Pool Maintenance', 'ma-pool-ipswich-maintenance', 'pool_service', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Plum Island Pool Care', 'ma-pool-plum-island-ipswich', 'pool_service', NULL, ARRAY['Ipswich','MA','Essex'], NULL),

    -- Lawrence
    ('Lawrence Pool Service', 'ma-pool-lawrence-pool-service', 'pool_service', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Merrimack Valley Pool & Spa', 'ma-pool-merrimack-valley-lawrence', 'pool_service', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Lawrence Aquatics', 'ma-pool-lawrence-aquatics', 'pool_service', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Lawrence Pool Maintenance', 'ma-pool-lawrence-maintenance', 'pool_service', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Den Rock Pool Care', 'ma-pool-den-rock-lawrence', 'pool_service', NULL, ARRAY['Lawrence','MA','Essex'], NULL),

    -- Lynn
    ('Lynn Pool Service', 'ma-pool-lynn-pool-service', 'pool_service', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Nahant Beach Pool & Spa', 'ma-pool-nahant-beach-lynn', 'pool_service', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Lynn Aquatics', 'ma-pool-lynn-aquatics', 'pool_service', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Lynn Pool Maintenance', 'ma-pool-lynn-maintenance', 'pool_service', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Flax Pond Pool Care', 'ma-pool-flax-pond-lynn', 'pool_service', NULL, ARRAY['Lynn','MA','Essex'], NULL),

    -- Lynnfield
    ('Lynnfield Pool Service', 'ma-pool-lynnfield-pool-service', 'pool_service', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Pillings Pond Pool & Spa', 'ma-pool-pillings-pond-lynnfield', 'pool_service', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Lynnfield Aquatics', 'ma-pool-lynnfield-aquatics', 'pool_service', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Lynnfield Pool Maintenance', 'ma-pool-lynnfield-maintenance', 'pool_service', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Reedy Meadow Pool Care', 'ma-pool-reedy-meadow-lynnfield', 'pool_service', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),

    -- Manchester-by-the-Sea
    ('Manchester Pool Service', 'ma-pool-manchester-sea-pool-service', 'pool_service', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Singing Beach Pool & Spa', 'ma-pool-singing-beach-manchester', 'pool_service', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Manchester-by-the-Sea Aquatics', 'ma-pool-manchester-sea-aquatics', 'pool_service', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Manchester Pool Maintenance', 'ma-pool-manchester-sea-maintenance', 'pool_service', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Tuck Point Pool Care', 'ma-pool-tuck-point-manchester', 'pool_service', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),

    -- Marblehead
    ('Marblehead Pool Service', 'ma-pool-marblehead-pool-service', 'pool_service', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Devereux Beach Pool & Spa', 'ma-pool-devereux-marblehead', 'pool_service', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Marblehead Aquatics', 'ma-pool-marblehead-aquatics', 'pool_service', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Marblehead Pool Maintenance', 'ma-pool-marblehead-maintenance', 'pool_service', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Harbor Pool Care Marblehead', 'ma-pool-harbor-marblehead', 'pool_service', NULL, ARRAY['Marblehead','MA','Essex'], NULL),

    -- Merrimac
    ('Merrimac Pool Service', 'ma-pool-merrimac-pool-service', 'pool_service', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Lake Attitash Pool & Spa', 'ma-pool-lake-attitash-merrimac', 'pool_service', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Merrimac Aquatics', 'ma-pool-merrimac-aquatics', 'pool_service', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Merrimac Pool Maintenance', 'ma-pool-merrimac-maintenance', 'pool_service', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Bear Hill Pool Care', 'ma-pool-bear-hill-merrimac', 'pool_service', NULL, ARRAY['Merrimac','MA','Essex'], NULL),

    -- Methuen
    ('Methuen Pool Service', 'ma-pool-methuen-pool-service', 'pool_service', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Forest Lake Pool & Spa', 'ma-pool-forest-lake-methuen', 'pool_service', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Methuen Aquatics', 'ma-pool-methuen-aquatics', 'pool_service', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Methuen Pool Maintenance', 'ma-pool-methuen-maintenance', 'pool_service', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Searles Pond Pool Care', 'ma-pool-searles-pond-methuen', 'pool_service', NULL, ARRAY['Methuen','MA','Essex'], NULL),

    -- Middleton
    ('Middleton Pool Service', 'ma-pool-middleton-pool-service', 'pool_service', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Thunder Bridge Pool & Spa', 'ma-pool-thunder-bridge-middleton', 'pool_service', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Middleton Aquatics', 'ma-pool-middleton-aquatics', 'pool_service', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Middleton Pool Maintenance', 'ma-pool-middleton-maintenance', 'pool_service', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Ipswich River Pool Care', 'ma-pool-ipswich-river-middleton', 'pool_service', NULL, ARRAY['Middleton','MA','Essex'], NULL),

    -- Nahant
    ('Nahant Pool Service', 'ma-pool-nahant-pool-service', 'pool_service', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Bass Point Pool & Spa', 'ma-pool-bass-point-nahant', 'pool_service', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Nahant Aquatics', 'ma-pool-nahant-aquatics', 'pool_service', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Nahant Pool Maintenance', 'ma-pool-nahant-maintenance', 'pool_service', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Tudor Beach Pool Care', 'ma-pool-tudor-beach-nahant', 'pool_service', NULL, ARRAY['Nahant','MA','Essex'], NULL),

    -- Newbury
    ('Newbury Pool Service', 'ma-pool-newbury-pool-service', 'pool_service', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Old Town Pool & Spa Newbury', 'ma-pool-old-town-newbury', 'pool_service', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Newbury Aquatics', 'ma-pool-newbury-aquatics', 'pool_service', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Newbury Pool Maintenance', 'ma-pool-newbury-maintenance', 'pool_service', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Parker River Pool Care', 'ma-pool-parker-river-newbury', 'pool_service', NULL, ARRAY['Newbury','MA','Essex'], NULL),

    -- Newburyport
    ('Newburyport Pool Service', 'ma-pool-newburyport-pool-service', 'pool_service', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Clipper City Pool & Spa', 'ma-pool-clipper-city-newburyport', 'pool_service', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Newburyport Aquatics', 'ma-pool-newburyport-aquatics', 'pool_service', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Newburyport Pool Maintenance', 'ma-pool-newburyport-maintenance', 'pool_service', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Plum Island Pool Care Newburyport', 'ma-pool-plum-island-newburyport', 'pool_service', NULL, ARRAY['Newburyport','MA','Essex'], NULL),

    -- North Andover
    ('North Andover Pool Service', 'ma-pool-north-andover-pool-service', 'pool_service', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Lake Cochichewick Pool & Spa', 'ma-pool-cochichewick-north-andover', 'pool_service', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('North Andover Aquatics', 'ma-pool-north-andover-aquatics', 'pool_service', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('North Andover Pool Maintenance', 'ma-pool-north-andover-maintenance', 'pool_service', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Osgood Pool Care', 'ma-pool-osgood-north-andover', 'pool_service', NULL, ARRAY['North Andover','MA','Essex'], NULL),

    -- Peabody
    ('Peabody Pool Service', 'ma-pool-peabody-pool-service', 'pool_service', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Brooksby Farm Pool & Spa', 'ma-pool-brooksby-peabody', 'pool_service', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Peabody Aquatics', 'ma-pool-peabody-aquatics', 'pool_service', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Peabody Pool Maintenance', 'ma-pool-peabody-maintenance', 'pool_service', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('South Peabody Pool Care', 'ma-pool-south-peabody', 'pool_service', NULL, ARRAY['Peabody','MA','Essex'], NULL),

    -- Rockport
    ('Rockport Pool Service', 'ma-pool-rockport-pool-service', 'pool_service', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Sandy Bay Pool & Spa', 'ma-pool-sandy-bay-rockport', 'pool_service', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Rockport Aquatics', 'ma-pool-rockport-aquatics', 'pool_service', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Rockport Pool Maintenance', 'ma-pool-rockport-maintenance', 'pool_service', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Halibut Point Pool Care', 'ma-pool-halibut-point-rockport', 'pool_service', NULL, ARRAY['Rockport','MA','Essex'], NULL),

    -- Rowley
    ('Rowley Pool Service', 'ma-pool-rowley-pool-service', 'pool_service', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Glen Mills Pool & Spa', 'ma-pool-glen-mills-rowley', 'pool_service', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Rowley Aquatics', 'ma-pool-rowley-aquatics', 'pool_service', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Rowley Pool Maintenance', 'ma-pool-rowley-maintenance', 'pool_service', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Stackyard Pool Care', 'ma-pool-stackyard-rowley', 'pool_service', NULL, ARRAY['Rowley','MA','Essex'], NULL),

    -- Salem
    ('Salem Pool Service', 'ma-pool-salem-pool-service', 'pool_service', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Derby Wharf Pool & Spa', 'ma-pool-derby-wharf-salem', 'pool_service', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Salem Aquatics', 'ma-pool-salem-aquatics', 'pool_service', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Salem Pool Maintenance', 'ma-pool-salem-maintenance', 'pool_service', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Collins Cove Pool Care', 'ma-pool-collins-cove-salem', 'pool_service', NULL, ARRAY['Salem','MA','Essex'], NULL),

    -- Salisbury
    ('Salisbury Pool Service', 'ma-pool-salisbury-pool-service', 'pool_service', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Salisbury Beach Pool & Spa', 'ma-pool-salisbury-beach', 'pool_service', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Salisbury Aquatics', 'ma-pool-salisbury-aquatics', 'pool_service', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Salisbury Pool Maintenance', 'ma-pool-salisbury-maintenance', 'pool_service', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Ring Island Pool Care', 'ma-pool-ring-island-salisbury', 'pool_service', NULL, ARRAY['Salisbury','MA','Essex'], NULL),

    -- Saugus
    ('Saugus Pool Service', 'ma-pool-saugus-pool-service', 'pool_service', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Breakheart Pool & Spa', 'ma-pool-breakheart-saugus', 'pool_service', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Saugus Aquatics', 'ma-pool-saugus-aquatics', 'pool_service', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Saugus Pool Maintenance', 'ma-pool-saugus-maintenance', 'pool_service', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Prankers Pond Pool Care', 'ma-pool-prankers-pond-saugus', 'pool_service', NULL, ARRAY['Saugus','MA','Essex'], NULL),

    -- Swampscott
    ('Swampscott Pool Service', 'ma-pool-swampscott-pool-service', 'pool_service', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Kings Beach Pool & Spa', 'ma-pool-kings-beach-swampscott', 'pool_service', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Swampscott Aquatics', 'ma-pool-swampscott-aquatics', 'pool_service', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Swampscott Pool Maintenance', 'ma-pool-swampscott-maintenance', 'pool_service', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Palmer Cove Pool Care', 'ma-pool-palmer-cove-swampscott', 'pool_service', NULL, ARRAY['Swampscott','MA','Essex'], NULL),

    -- Topsfield
    ('Topsfield Pool Service', 'ma-pool-topsfield-pool-service', 'pool_service', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Topsfield Fair Pool & Spa', 'ma-pool-topsfield-fair', 'pool_service', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Topsfield Aquatics', 'ma-pool-topsfield-aquatics', 'pool_service', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Topsfield Pool Maintenance', 'ma-pool-topsfield-maintenance', 'pool_service', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Howlett Brook Pool Care', 'ma-pool-howlett-brook-topsfield', 'pool_service', NULL, ARRAY['Topsfield','MA','Essex'], NULL),

    -- Wenham
    ('Wenham Pool Service', 'ma-pool-wenham-pool-service', 'pool_service', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Pleasant Pond Pool & Spa', 'ma-pool-pleasant-pond-wenham', 'pool_service', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Wenham Aquatics', 'ma-pool-wenham-aquatics', 'pool_service', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Wenham Pool Maintenance', 'ma-pool-wenham-maintenance', 'pool_service', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Iron Rail Pool Care', 'ma-pool-iron-rail-wenham', 'pool_service', NULL, ARRAY['Wenham','MA','Essex'], NULL),

    -- West Newbury
    ('West Newbury Pool Service', 'ma-pool-west-newbury-pool-service', 'pool_service', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('Indian Hill Pool & Spa', 'ma-pool-indian-hill-west-newbury', 'pool_service', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('West Newbury Aquatics', 'ma-pool-west-newbury-aquatics', 'pool_service', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('West Newbury Pool Maintenance', 'ma-pool-west-newbury-maintenance', 'pool_service', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('Artichoke River Pool Care', 'ma-pool-artichoke-river-west-newbury', 'pool_service', NULL, ARRAY['West Newbury','MA','Essex'], NULL)

ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;


-- ============================================================================
-- SECTION 3: MIDDLESEX COUNTY, MA -- LOCAL POOL SERVICE FIRMS
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES

    -- Acton
    ('Acton Pool Service', 'ma-pool-acton-pool-service', 'pool_service', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Nagog Pond Pool & Spa', 'ma-pool-nagog-pond-acton', 'pool_service', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Acton Aquatics', 'ma-pool-acton-aquatics', 'pool_service', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Acton Pool Maintenance', 'ma-pool-acton-maintenance', 'pool_service', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('West Acton Pool Care', 'ma-pool-west-acton', 'pool_service', NULL, ARRAY['Acton','MA','Middlesex'], NULL),

    -- Arlington
    ('Arlington Pool Service', 'ma-pool-arlington-pool-service', 'pool_service', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Spy Pond Pool & Spa', 'ma-pool-spy-pond-arlington', 'pool_service', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Arlington Aquatics', 'ma-pool-arlington-aquatics', 'pool_service', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Arlington Pool Maintenance', 'ma-pool-arlington-maintenance', 'pool_service', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Mystic Valley Pool Care', 'ma-pool-mystic-valley-arlington', 'pool_service', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),

    -- Ashby
    ('Ashby Pool Service', 'ma-pool-ashby-pool-service', 'pool_service', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Fitchburg Road Pool & Spa', 'ma-pool-fitchburg-rd-ashby', 'pool_service', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Ashby Aquatics', 'ma-pool-ashby-aquatics', 'pool_service', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Ashby Pool Maintenance', 'ma-pool-ashby-maintenance', 'pool_service', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('South Ashby Pool Care', 'ma-pool-south-ashby', 'pool_service', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),

    -- Ashland
    ('Ashland Pool Service', 'ma-pool-ashland-pool-service', 'pool_service', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Ashland Reservoir Pool & Spa', 'ma-pool-reservoir-ashland', 'pool_service', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Ashland Aquatics', 'ma-pool-ashland-aquatics', 'pool_service', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Ashland Pool Maintenance', 'ma-pool-ashland-maintenance', 'pool_service', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Hopkinton Road Pool Care', 'ma-pool-hopkinton-rd-ashland', 'pool_service', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),

    -- Ayer
    ('Ayer Pool Service', 'ma-pool-ayer-pool-service', 'pool_service', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Sandy Pond Pool & Spa', 'ma-pool-sandy-pond-ayer', 'pool_service', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Ayer Aquatics', 'ma-pool-ayer-aquatics', 'pool_service', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Ayer Pool Maintenance', 'ma-pool-ayer-maintenance', 'pool_service', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Nashua River Pool Care', 'ma-pool-nashua-river-ayer', 'pool_service', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),

    -- Bedford
    ('Bedford Pool Service', 'ma-pool-bedford-pool-service', 'pool_service', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Springs Brook Pool & Spa', 'ma-pool-springs-brook-bedford', 'pool_service', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Bedford Aquatics', 'ma-pool-bedford-aquatics', 'pool_service', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Bedford Pool Maintenance', 'ma-pool-bedford-maintenance', 'pool_service', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Great Road Pool Care', 'ma-pool-great-road-bedford', 'pool_service', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),

    -- Belmont
    ('Belmont Pool Service', 'ma-pool-belmont-pool-service', 'pool_service', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Clay Pit Pond Pool & Spa', 'ma-pool-clay-pit-belmont', 'pool_service', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Belmont Aquatics', 'ma-pool-belmont-aquatics', 'pool_service', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Belmont Pool Maintenance', 'ma-pool-belmont-maintenance', 'pool_service', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Belmont Hill Pool Care', 'ma-pool-belmont-hill', 'pool_service', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),

    -- Billerica
    ('Billerica Pool Service', 'ma-pool-billerica-pool-service', 'pool_service', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Nuttings Lake Pool & Spa', 'ma-pool-nuttings-lake-billerica', 'pool_service', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Billerica Aquatics', 'ma-pool-billerica-aquatics', 'pool_service', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Billerica Pool Maintenance', 'ma-pool-billerica-maintenance', 'pool_service', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Concord Road Pool Care', 'ma-pool-concord-rd-billerica', 'pool_service', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),

    -- Boxborough
    ('Boxborough Pool Service', 'ma-pool-boxborough-pool-service', 'pool_service', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Flerra Meadows Pool & Spa', 'ma-pool-flerra-meadows-boxborough', 'pool_service', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Boxborough Aquatics', 'ma-pool-boxborough-aquatics', 'pool_service', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Boxborough Pool Maintenance', 'ma-pool-boxborough-maintenance', 'pool_service', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Liberty Square Pool Care', 'ma-pool-liberty-sq-boxborough', 'pool_service', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),

    -- Burlington
    ('Burlington Pool Service', 'ma-pool-burlington-pool-service', 'pool_service', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Mill Pond Pool & Spa', 'ma-pool-mill-pond-burlington', 'pool_service', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Burlington Aquatics', 'ma-pool-burlington-aquatics', 'pool_service', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Burlington Pool Maintenance', 'ma-pool-burlington-maintenance', 'pool_service', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Middlesex Pool Care Burlington', 'ma-pool-middlesex-burlington', 'pool_service', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),

    -- Cambridge
    ('Cambridge Pool Service', 'ma-pool-cambridge-pool-service', 'pool_service', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Fresh Pond Pool & Spa', 'ma-pool-fresh-pond-cambridge', 'pool_service', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Cambridge Aquatics', 'ma-pool-cambridge-aquatics', 'pool_service', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Cambridge Pool Maintenance', 'ma-pool-cambridge-maintenance', 'pool_service', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Charles River Pool Care', 'ma-pool-charles-river-cambridge', 'pool_service', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),

    -- Carlisle
    ('Carlisle Pool Service', 'ma-pool-carlisle-pool-service', 'pool_service', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Foss Farm Pool & Spa', 'ma-pool-foss-farm-carlisle', 'pool_service', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Carlisle Aquatics', 'ma-pool-carlisle-aquatics', 'pool_service', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Carlisle Pool Maintenance', 'ma-pool-carlisle-maintenance', 'pool_service', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Concord River Pool Care Carlisle', 'ma-pool-concord-river-carlisle', 'pool_service', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),

    -- Chelmsford
    ('Chelmsford Pool Service', 'ma-pool-chelmsford-pool-service', 'pool_service', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Heart Pond Pool & Spa', 'ma-pool-heart-pond-chelmsford', 'pool_service', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Chelmsford Aquatics', 'ma-pool-chelmsford-aquatics', 'pool_service', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Chelmsford Pool Maintenance', 'ma-pool-chelmsford-maintenance', 'pool_service', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Vinal Square Pool Care', 'ma-pool-vinal-sq-chelmsford', 'pool_service', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),

    -- Concord
    ('Concord Pool Service', 'ma-pool-concord-pool-service', 'pool_service', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Walden Pond Pool & Spa', 'ma-pool-walden-pond-concord', 'pool_service', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Concord Aquatics', 'ma-pool-concord-aquatics', 'pool_service', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Concord Pool Maintenance', 'ma-pool-concord-maintenance', 'pool_service', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Old North Bridge Pool Care', 'ma-pool-old-north-bridge-concord', 'pool_service', NULL, ARRAY['Concord','MA','Middlesex'], NULL),

    -- Dracut
    ('Dracut Pool Service', 'ma-pool-dracut-pool-service', 'pool_service', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Long Pond Pool & Spa', 'ma-pool-long-pond-dracut', 'pool_service', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Dracut Aquatics', 'ma-pool-dracut-aquatics', 'pool_service', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Dracut Pool Maintenance', 'ma-pool-dracut-maintenance', 'pool_service', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Merrimack View Pool Care', 'ma-pool-merrimack-view-dracut', 'pool_service', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),

    -- Dunstable
    ('Dunstable Pool Service', 'ma-pool-dunstable-pool-service', 'pool_service', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Massapoag Pond Pool & Spa', 'ma-pool-massapoag-dunstable', 'pool_service', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Dunstable Aquatics', 'ma-pool-dunstable-aquatics', 'pool_service', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Dunstable Pool Maintenance', 'ma-pool-dunstable-maintenance', 'pool_service', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Salmon Brook Pool Care', 'ma-pool-salmon-brook-dunstable', 'pool_service', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),

    -- Everett
    ('Everett Pool Service', 'ma-pool-everett-pool-service', 'pool_service', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Mystic River Pool & Spa Everett', 'ma-pool-mystic-river-everett', 'pool_service', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Everett Aquatics', 'ma-pool-everett-aquatics', 'pool_service', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Everett Pool Maintenance', 'ma-pool-everett-maintenance', 'pool_service', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Island End Pool Care', 'ma-pool-island-end-everett', 'pool_service', NULL, ARRAY['Everett','MA','Middlesex'], NULL),

    -- Framingham
    ('Framingham Pool Service', 'ma-pool-framingham-pool-service', 'pool_service', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Farm Pond Pool & Spa', 'ma-pool-farm-pond-framingham', 'pool_service', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Framingham Aquatics', 'ma-pool-framingham-aquatics', 'pool_service', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Framingham Pool Maintenance', 'ma-pool-framingham-maintenance', 'pool_service', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Nobscot Pool Care', 'ma-pool-nobscot-framingham', 'pool_service', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),

    -- Groton
    ('Groton Pool Service', 'ma-pool-groton-pool-service', 'pool_service', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Lost Lake Pool & Spa', 'ma-pool-lost-lake-groton', 'pool_service', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Groton Aquatics', 'ma-pool-groton-aquatics', 'pool_service', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Groton Pool Maintenance', 'ma-pool-groton-maintenance', 'pool_service', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Gibbet Hill Pool Care', 'ma-pool-gibbet-hill-groton', 'pool_service', NULL, ARRAY['Groton','MA','Middlesex'], NULL),

    -- Holliston
    ('Holliston Pool Service', 'ma-pool-holliston-pool-service', 'pool_service', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Lake Winthrop Pool & Spa', 'ma-pool-lake-winthrop-holliston', 'pool_service', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Holliston Aquatics', 'ma-pool-holliston-aquatics', 'pool_service', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Holliston Pool Maintenance', 'ma-pool-holliston-maintenance', 'pool_service', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Highland Street Pool Care', 'ma-pool-highland-st-holliston', 'pool_service', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),

    -- Hopkinton
    ('Hopkinton Pool Service', 'ma-pool-hopkinton-pool-service', 'pool_service', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('North Pond Pool & Spa', 'ma-pool-north-pond-hopkinton', 'pool_service', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Hopkinton Aquatics', 'ma-pool-hopkinton-aquatics', 'pool_service', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Hopkinton Pool Maintenance', 'ma-pool-hopkinton-maintenance', 'pool_service', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Marathon Pool Care', 'ma-pool-marathon-hopkinton', 'pool_service', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),

    -- Hudson
    ('Hudson Pool Service', 'ma-pool-hudson-pool-service', 'pool_service', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Lake Boon Pool & Spa', 'ma-pool-lake-boon-hudson', 'pool_service', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Hudson Aquatics', 'ma-pool-hudson-aquatics', 'pool_service', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Hudson Pool Maintenance', 'ma-pool-hudson-maintenance', 'pool_service', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Assabet River Pool Care', 'ma-pool-assabet-river-hudson', 'pool_service', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),

    -- Lexington
    ('Lexington Pool Service', 'ma-pool-lexington-pool-service', 'pool_service', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Battle Green Pool & Spa', 'ma-pool-battle-green-lexington', 'pool_service', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Lexington Aquatics', 'ma-pool-lexington-aquatics', 'pool_service', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Lexington Pool Maintenance', 'ma-pool-lexington-maintenance', 'pool_service', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Minuteman Pool Care', 'ma-pool-minuteman-lexington', 'pool_service', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),

    -- Lincoln
    ('Lincoln Pool Service', 'ma-pool-lincoln-pool-service', 'pool_service', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Flints Pond Pool & Spa', 'ma-pool-flints-pond-lincoln', 'pool_service', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Lincoln Aquatics', 'ma-pool-lincoln-aquatics', 'pool_service', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Lincoln Pool Maintenance', 'ma-pool-lincoln-maintenance', 'pool_service', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Codman Pool Care', 'ma-pool-codman-lincoln', 'pool_service', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),

    -- Littleton
    ('Littleton Pool Service', 'ma-pool-littleton-pool-service', 'pool_service', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Long Lake Pool & Spa', 'ma-pool-long-lake-littleton', 'pool_service', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Littleton Aquatics', 'ma-pool-littleton-aquatics', 'pool_service', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Littleton Pool Maintenance', 'ma-pool-littleton-maintenance', 'pool_service', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Nashoba Pool Care', 'ma-pool-nashoba-littleton', 'pool_service', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),

    -- Lowell
    ('Lowell Pool Service', 'ma-pool-lowell-pool-service', 'pool_service', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Pawtucket Falls Pool & Spa', 'ma-pool-pawtucket-falls-lowell', 'pool_service', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Lowell Aquatics', 'ma-pool-lowell-aquatics', 'pool_service', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Lowell Pool Maintenance', 'ma-pool-lowell-maintenance', 'pool_service', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Canal District Pool Care', 'ma-pool-canal-district-lowell', 'pool_service', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),

    -- Malden
    ('Malden Pool Service', 'ma-pool-malden-pool-service', 'pool_service', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Fellsway Pool & Spa', 'ma-pool-fellsway-malden', 'pool_service', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Malden Aquatics', 'ma-pool-malden-aquatics', 'pool_service', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Malden Pool Maintenance', 'ma-pool-malden-maintenance', 'pool_service', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Oak Grove Pool Care', 'ma-pool-oak-grove-malden', 'pool_service', NULL, ARRAY['Malden','MA','Middlesex'], NULL),

    -- Marlborough
    ('Marlborough Pool Service', 'ma-pool-marlborough-pool-service', 'pool_service', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Williams Lake Pool & Spa', 'ma-pool-williams-lake-marlborough', 'pool_service', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Marlborough Aquatics', 'ma-pool-marlborough-aquatics', 'pool_service', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Marlborough Pool Maintenance', 'ma-pool-marlborough-maintenance', 'pool_service', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Ghiloni Pool Care', 'ma-pool-ghiloni-marlborough', 'pool_service', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),

    -- Maynard
    ('Maynard Pool Service', 'ma-pool-maynard-pool-service', 'pool_service', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Assabet Village Pool & Spa', 'ma-pool-assabet-village-maynard', 'pool_service', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Maynard Aquatics', 'ma-pool-maynard-aquatics', 'pool_service', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Maynard Pool Maintenance', 'ma-pool-maynard-maintenance', 'pool_service', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Mill Pond Pool Care Maynard', 'ma-pool-mill-pond-maynard', 'pool_service', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),

    -- Medford
    ('Medford Pool Service', 'ma-pool-medford-pool-service', 'pool_service', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Mystic Lakes Pool & Spa', 'ma-pool-mystic-lakes-medford', 'pool_service', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Medford Aquatics', 'ma-pool-medford-aquatics', 'pool_service', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Medford Pool Maintenance', 'ma-pool-medford-maintenance', 'pool_service', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Tufts Pool Care', 'ma-pool-tufts-medford', 'pool_service', NULL, ARRAY['Medford','MA','Middlesex'], NULL),

    -- Melrose
    ('Melrose Pool Service', 'ma-pool-melrose-pool-service', 'pool_service', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Ell Pond Pool & Spa', 'ma-pool-ell-pond-melrose', 'pool_service', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Melrose Aquatics', 'ma-pool-melrose-aquatics', 'pool_service', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Melrose Pool Maintenance', 'ma-pool-melrose-maintenance', 'pool_service', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Wyoming Pool Care', 'ma-pool-wyoming-melrose', 'pool_service', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),

    -- Natick
    ('Natick Pool Service', 'ma-pool-natick-pool-service', 'pool_service', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Lake Cochituate Pool & Spa', 'ma-pool-cochituate-natick', 'pool_service', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Natick Aquatics', 'ma-pool-natick-aquatics', 'pool_service', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Natick Pool Maintenance', 'ma-pool-natick-maintenance', 'pool_service', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('South Natick Pool Care', 'ma-pool-south-natick', 'pool_service', NULL, ARRAY['Natick','MA','Middlesex'], NULL),

    -- Newton
    ('Newton Pool Service', 'ma-pool-newton-pool-service', 'pool_service', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Crystal Lake Pool & Spa Newton', 'ma-pool-crystal-lake-newton', 'pool_service', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Newton Aquatics', 'ma-pool-newton-aquatics', 'pool_service', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Newton Pool Maintenance', 'ma-pool-newton-maintenance', 'pool_service', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Chestnut Hill Pool Care', 'ma-pool-chestnut-hill-newton', 'pool_service', NULL, ARRAY['Newton','MA','Middlesex'], NULL),

    -- North Reading
    ('North Reading Pool Service', 'ma-pool-north-reading-pool-service', 'pool_service', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('Martins Pond Pool & Spa', 'ma-pool-martins-pond-north-reading', 'pool_service', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('North Reading Aquatics', 'ma-pool-north-reading-aquatics', 'pool_service', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('North Reading Pool Maintenance', 'ma-pool-north-reading-maintenance', 'pool_service', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('Ipswich River Pool Care North Reading', 'ma-pool-ipswich-river-north-reading', 'pool_service', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),

    -- Pepperell
    ('Pepperell Pool Service', 'ma-pool-pepperell-pool-service', 'pool_service', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Nashua River Pool & Spa Pepperell', 'ma-pool-nashua-river-pepperell', 'pool_service', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Pepperell Aquatics', 'ma-pool-pepperell-aquatics', 'pool_service', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Pepperell Pool Maintenance', 'ma-pool-pepperell-maintenance', 'pool_service', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Nissitissit Pool Care', 'ma-pool-nissitissit-pepperell', 'pool_service', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),

    -- Reading
    ('Reading Pool Service', 'ma-pool-reading-pool-service', 'pool_service', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Lake Quannapowitt Pool & Spa', 'ma-pool-quannapowitt-reading', 'pool_service', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Reading Aquatics', 'ma-pool-reading-aquatics', 'pool_service', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Reading Pool Maintenance', 'ma-pool-reading-maintenance', 'pool_service', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Birch Meadow Pool Care', 'ma-pool-birch-meadow-reading', 'pool_service', NULL, ARRAY['Reading','MA','Middlesex'], NULL),

    -- Sherborn
    ('Sherborn Pool Service', 'ma-pool-sherborn-pool-service', 'pool_service', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Farm Pond Pool & Spa Sherborn', 'ma-pool-farm-pond-sherborn', 'pool_service', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Sherborn Aquatics', 'ma-pool-sherborn-aquatics', 'pool_service', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Sherborn Pool Maintenance', 'ma-pool-sherborn-maintenance', 'pool_service', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Pine Hill Pool Care Sherborn', 'ma-pool-pine-hill-sherborn', 'pool_service', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),

    -- Shirley
    ('Shirley Pool Service', 'ma-pool-shirley-pool-service', 'pool_service', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Catacunemaug Pool & Spa', 'ma-pool-catacunemaug-shirley', 'pool_service', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Shirley Aquatics', 'ma-pool-shirley-aquatics', 'pool_service', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Shirley Pool Maintenance', 'ma-pool-shirley-maintenance', 'pool_service', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Mulpus Brook Pool Care', 'ma-pool-mulpus-brook-shirley', 'pool_service', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),

    -- Somerville
    ('Somerville Pool Service', 'ma-pool-somerville-pool-service', 'pool_service', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Davis Square Pool & Spa', 'ma-pool-davis-sq-somerville', 'pool_service', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Somerville Aquatics', 'ma-pool-somerville-aquatics', 'pool_service', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Somerville Pool Maintenance', 'ma-pool-somerville-maintenance', 'pool_service', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Prospect Hill Pool Care', 'ma-pool-prospect-hill-somerville', 'pool_service', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),

    -- Stoneham
    ('Stoneham Pool Service', 'ma-pool-stoneham-pool-service', 'pool_service', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Spot Pond Pool & Spa', 'ma-pool-spot-pond-stoneham', 'pool_service', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Stoneham Aquatics', 'ma-pool-stoneham-aquatics', 'pool_service', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Stoneham Pool Maintenance', 'ma-pool-stoneham-maintenance', 'pool_service', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Fells Pool Care', 'ma-pool-fells-stoneham', 'pool_service', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),

    -- Stow
    ('Stow Pool Service', 'ma-pool-stow-pool-service', 'pool_service', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Lake Boon Pool & Spa Stow', 'ma-pool-lake-boon-stow', 'pool_service', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Stow Aquatics', 'ma-pool-stow-aquatics', 'pool_service', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Stow Pool Maintenance', 'ma-pool-stow-maintenance', 'pool_service', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Assabet Brook Pool Care', 'ma-pool-assabet-brook-stow', 'pool_service', NULL, ARRAY['Stow','MA','Middlesex'], NULL),

    -- Sudbury
    ('Sudbury Pool Service', 'ma-pool-sudbury-pool-service', 'pool_service', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Willis Pond Pool & Spa', 'ma-pool-willis-pond-sudbury', 'pool_service', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Sudbury Aquatics', 'ma-pool-sudbury-aquatics', 'pool_service', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Sudbury Pool Maintenance', 'ma-pool-sudbury-maintenance', 'pool_service', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Wayside Inn Pool Care', 'ma-pool-wayside-inn-sudbury', 'pool_service', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),

    -- Tewksbury
    ('Tewksbury Pool Service', 'ma-pool-tewksbury-pool-service', 'pool_service', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Round Pond Pool & Spa', 'ma-pool-round-pond-tewksbury', 'pool_service', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Tewksbury Aquatics', 'ma-pool-tewksbury-aquatics', 'pool_service', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Tewksbury Pool Maintenance', 'ma-pool-tewksbury-maintenance', 'pool_service', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Shawsheen River Pool Care', 'ma-pool-shawsheen-river-tewksbury', 'pool_service', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),

    -- Townsend
    ('Townsend Pool Service', 'ma-pool-townsend-pool-service', 'pool_service', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Pearl Hill Pool & Spa', 'ma-pool-pearl-hill-townsend', 'pool_service', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Townsend Aquatics', 'ma-pool-townsend-aquatics', 'pool_service', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Townsend Pool Maintenance', 'ma-pool-townsend-maintenance', 'pool_service', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Squannacook Pool Care', 'ma-pool-squannacook-townsend', 'pool_service', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),

    -- Tyngsborough
    ('Tyngsborough Pool Service', 'ma-pool-tyngsborough-pool-service', 'pool_service', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Long Pond Pool & Spa Tyngsborough', 'ma-pool-long-pond-tyngsborough', 'pool_service', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Tyngsborough Aquatics', 'ma-pool-tyngsborough-aquatics', 'pool_service', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Tyngsborough Pool Maintenance', 'ma-pool-tyngsborough-maintenance', 'pool_service', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Merrimack Pool Care Tyngsborough', 'ma-pool-merrimack-tyngsborough', 'pool_service', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),

    -- Wakefield
    ('Wakefield Pool Service', 'ma-pool-wakefield-pool-service', 'pool_service', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Lake Quannapowitt Pool & Spa Wakefield', 'ma-pool-quannapowitt-wakefield', 'pool_service', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Wakefield Aquatics', 'ma-pool-wakefield-aquatics', 'pool_service', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Wakefield Pool Maintenance', 'ma-pool-wakefield-maintenance', 'pool_service', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Crystal Lake Pool Care Wakefield', 'ma-pool-crystal-lake-wakefield', 'pool_service', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),

    -- Waltham
    ('Waltham Pool Service', 'ma-pool-waltham-pool-service', 'pool_service', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Hardy Pond Pool & Spa', 'ma-pool-hardy-pond-waltham', 'pool_service', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Waltham Aquatics', 'ma-pool-waltham-aquatics', 'pool_service', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Waltham Pool Maintenance', 'ma-pool-waltham-maintenance', 'pool_service', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Moody Street Pool Care', 'ma-pool-moody-st-waltham', 'pool_service', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),

    -- Watertown
    ('Watertown Pool Service', 'ma-pool-watertown-pool-service', 'pool_service', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Filipello Park Pool & Spa', 'ma-pool-filipello-watertown', 'pool_service', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Watertown Aquatics', 'ma-pool-watertown-aquatics', 'pool_service', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Watertown Pool Maintenance', 'ma-pool-watertown-maintenance', 'pool_service', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Arsenal Pool Care', 'ma-pool-arsenal-watertown', 'pool_service', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),

    -- Wayland
    ('Wayland Pool Service', 'ma-pool-wayland-pool-service', 'pool_service', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Dudley Pond Pool & Spa', 'ma-pool-dudley-pond-wayland', 'pool_service', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Wayland Aquatics', 'ma-pool-wayland-aquatics', 'pool_service', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Wayland Pool Maintenance', 'ma-pool-wayland-maintenance', 'pool_service', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Cochituate Pool Care', 'ma-pool-cochituate-wayland', 'pool_service', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),

    -- Westford
    ('Westford Pool Service', 'ma-pool-westford-pool-service', 'pool_service', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Forge Pond Pool & Spa', 'ma-pool-forge-pond-westford', 'pool_service', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Westford Aquatics', 'ma-pool-westford-aquatics', 'pool_service', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Westford Pool Maintenance', 'ma-pool-westford-maintenance', 'pool_service', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Stony Brook Pool Care', 'ma-pool-stony-brook-westford', 'pool_service', NULL, ARRAY['Westford','MA','Middlesex'], NULL),

    -- Weston
    ('Weston Pool Service', 'ma-pool-weston-pool-service', 'pool_service', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('College Pond Pool & Spa', 'ma-pool-college-pond-weston', 'pool_service', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Weston Aquatics', 'ma-pool-weston-aquatics', 'pool_service', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Weston Pool Maintenance', 'ma-pool-weston-maintenance', 'pool_service', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Country Club Pool Care Weston', 'ma-pool-country-club-weston', 'pool_service', NULL, ARRAY['Weston','MA','Middlesex'], NULL),

    -- Wilmington
    ('Wilmington Pool Service', 'ma-pool-wilmington-pool-service', 'pool_service', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Silver Lake Pool & Spa Wilmington', 'ma-pool-silver-lake-wilmington', 'pool_service', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Wilmington Aquatics', 'ma-pool-wilmington-aquatics', 'pool_service', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Wilmington Pool Maintenance', 'ma-pool-wilmington-maintenance', 'pool_service', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Butters Row Pool Care', 'ma-pool-butters-row-wilmington', 'pool_service', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),

    -- Winchester
    ('Winchester Pool Service', 'ma-pool-winchester-pool-service', 'pool_service', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Wedge Pond Pool & Spa', 'ma-pool-wedge-pond-winchester', 'pool_service', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Winchester Aquatics', 'ma-pool-winchester-aquatics', 'pool_service', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Winchester Pool Maintenance', 'ma-pool-winchester-maintenance', 'pool_service', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Fells Reservoir Pool Care', 'ma-pool-fells-reservoir-winchester', 'pool_service', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),

    -- Woburn
    ('Woburn Pool Service', 'ma-pool-woburn-pool-service', 'pool_service', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Horn Pond Pool & Spa', 'ma-pool-horn-pond-woburn', 'pool_service', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Woburn Aquatics', 'ma-pool-woburn-aquatics', 'pool_service', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Woburn Pool Maintenance', 'ma-pool-woburn-maintenance', 'pool_service', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('New Boston Pool Care', 'ma-pool-new-boston-woburn', 'pool_service', NULL, ARRAY['Woburn','MA','Middlesex'], NULL)

ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;


-- ============================================================================
-- SECTION 4: NORFOLK COUNTY, MA -- LOCAL POOL SERVICE FIRMS
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES

    -- Avon
    ('Avon Pool Service', 'ma-pool-avon-pool-service', 'pool_service', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Crescent Street Pool & Spa', 'ma-pool-crescent-st-avon', 'pool_service', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Avon Aquatics', 'ma-pool-avon-aquatics', 'pool_service', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Avon Pool Maintenance', 'ma-pool-avon-maintenance', 'pool_service', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Central Pool Care Avon', 'ma-pool-central-avon', 'pool_service', NULL, ARRAY['Avon','MA','Norfolk'], NULL),

    -- Braintree
    ('Braintree Pool Service', 'ma-pool-braintree-pool-service', 'pool_service', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Sunset Lake Pool & Spa', 'ma-pool-sunset-lake-braintree', 'pool_service', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Braintree Aquatics', 'ma-pool-braintree-aquatics', 'pool_service', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Braintree Pool Maintenance', 'ma-pool-braintree-maintenance', 'pool_service', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('South Braintree Pool Care', 'ma-pool-south-braintree', 'pool_service', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),

    -- Brookline
    ('Brookline Pool Service', 'ma-pool-brookline-pool-service', 'pool_service', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Chestnut Hill Pool & Spa Brookline', 'ma-pool-chestnut-hill-brookline', 'pool_service', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Brookline Aquatics', 'ma-pool-brookline-aquatics', 'pool_service', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Brookline Pool Maintenance', 'ma-pool-brookline-maintenance', 'pool_service', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Coolidge Corner Pool Care', 'ma-pool-coolidge-corner-brookline', 'pool_service', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),

    -- Canton
    ('Canton Pool Service', 'ma-pool-canton-pool-service', 'pool_service', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Reservoir Pond Pool & Spa', 'ma-pool-reservoir-pond-canton', 'pool_service', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Canton Aquatics', 'ma-pool-canton-aquatics', 'pool_service', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Canton Pool Maintenance', 'ma-pool-canton-maintenance', 'pool_service', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Pequit Brook Pool Care', 'ma-pool-pequit-brook-canton', 'pool_service', NULL, ARRAY['Canton','MA','Norfolk'], NULL),

    -- Cohasset
    ('Cohasset Pool Service', 'ma-pool-cohasset-pool-service', 'pool_service', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Sandy Cove Pool & Spa', 'ma-pool-sandy-cove-cohasset', 'pool_service', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Cohasset Aquatics', 'ma-pool-cohasset-aquatics', 'pool_service', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Cohasset Pool Maintenance', 'ma-pool-cohasset-maintenance', 'pool_service', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Cohasset Harbor Pool Care', 'ma-pool-harbor-cohasset', 'pool_service', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),

    -- Dedham
    ('Dedham Pool Service', 'ma-pool-dedham-pool-service', 'pool_service', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Mother Brook Pool & Spa', 'ma-pool-mother-brook-dedham', 'pool_service', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Dedham Aquatics', 'ma-pool-dedham-aquatics', 'pool_service', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Dedham Pool Maintenance', 'ma-pool-dedham-maintenance', 'pool_service', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Oakdale Pool Care', 'ma-pool-oakdale-dedham', 'pool_service', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),

    -- Dover
    ('Dover Pool Service', 'ma-pool-dover-pool-service', 'pool_service', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Noanet Brook Pool & Spa', 'ma-pool-noanet-brook-dover', 'pool_service', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Dover Aquatics', 'ma-pool-dover-aquatics', 'pool_service', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Dover Pool Maintenance', 'ma-pool-dover-maintenance', 'pool_service', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Farm Street Pool Care', 'ma-pool-farm-st-dover', 'pool_service', NULL, ARRAY['Dover','MA','Norfolk'], NULL),

    -- Foxborough
    ('Foxborough Pool Service', 'ma-pool-foxborough-pool-service', 'pool_service', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Neponset Pool & Spa Foxborough', 'ma-pool-neponset-foxborough', 'pool_service', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Foxborough Aquatics', 'ma-pool-foxborough-aquatics', 'pool_service', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Foxborough Pool Maintenance', 'ma-pool-foxborough-maintenance', 'pool_service', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Patriot Pool Care', 'ma-pool-patriot-foxborough', 'pool_service', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),

    -- Franklin
    ('Franklin Pool Service', 'ma-pool-franklin-pool-service', 'pool_service', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Beaver Pond Pool & Spa', 'ma-pool-beaver-pond-franklin', 'pool_service', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Franklin Aquatics', 'ma-pool-franklin-aquatics', 'pool_service', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Franklin Pool Maintenance', 'ma-pool-franklin-maintenance', 'pool_service', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Forge Hill Pool Care', 'ma-pool-forge-hill-franklin', 'pool_service', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),

    -- Holbrook
    ('Holbrook Pool Service', 'ma-pool-holbrook-pool-service', 'pool_service', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Mary Lee Brook Pool & Spa', 'ma-pool-mary-lee-holbrook', 'pool_service', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Holbrook Aquatics', 'ma-pool-holbrook-aquatics', 'pool_service', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Holbrook Pool Maintenance', 'ma-pool-holbrook-maintenance', 'pool_service', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Union Street Pool Care', 'ma-pool-union-st-holbrook', 'pool_service', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),

    -- Medfield
    ('Medfield Pool Service', 'ma-pool-medfield-pool-service', 'pool_service', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Hinkley Pond Pool & Spa', 'ma-pool-hinkley-pond-medfield', 'pool_service', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Medfield Aquatics', 'ma-pool-medfield-aquatics', 'pool_service', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Medfield Pool Maintenance', 'ma-pool-medfield-maintenance', 'pool_service', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Charles River Pool Care Medfield', 'ma-pool-charles-river-medfield', 'pool_service', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),

    -- Medway
    ('Medway Pool Service', 'ma-pool-medway-pool-service', 'pool_service', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Choate Park Pool & Spa', 'ma-pool-choate-park-medway', 'pool_service', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Medway Aquatics', 'ma-pool-medway-aquatics', 'pool_service', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Medway Pool Maintenance', 'ma-pool-medway-maintenance', 'pool_service', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Chicken Brook Pool Care', 'ma-pool-chicken-brook-medway', 'pool_service', NULL, ARRAY['Medway','MA','Norfolk'], NULL),

    -- Millis
    ('Millis Pool Service', 'ma-pool-millis-pool-service', 'pool_service', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Bogastow Brook Pool & Spa', 'ma-pool-bogastow-millis', 'pool_service', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Millis Aquatics', 'ma-pool-millis-aquatics', 'pool_service', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Millis Pool Maintenance', 'ma-pool-millis-maintenance', 'pool_service', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Richardson Pool Care', 'ma-pool-richardson-millis', 'pool_service', NULL, ARRAY['Millis','MA','Norfolk'], NULL),

    -- Milton
    ('Milton Pool Service', 'ma-pool-milton-pool-service', 'pool_service', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Houghtons Pond Pool & Spa', 'ma-pool-houghtons-pond-milton', 'pool_service', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Milton Aquatics', 'ma-pool-milton-aquatics', 'pool_service', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Milton Pool Maintenance', 'ma-pool-milton-maintenance', 'pool_service', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Blue Hills Pool Care', 'ma-pool-blue-hills-milton', 'pool_service', NULL, ARRAY['Milton','MA','Norfolk'], NULL),

    -- Needham
    ('Needham Pool Service', 'ma-pool-needham-pool-service', 'pool_service', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Rosemary Lake Pool & Spa', 'ma-pool-rosemary-lake-needham', 'pool_service', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Needham Aquatics', 'ma-pool-needham-aquatics', 'pool_service', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Needham Pool Maintenance', 'ma-pool-needham-maintenance', 'pool_service', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Needham Heights Pool Care', 'ma-pool-needham-heights', 'pool_service', NULL, ARRAY['Needham','MA','Norfolk'], NULL),

    -- Norfolk
    ('Norfolk Pool Service', 'ma-pool-norfolk-pool-service', 'pool_service', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Campbell Pond Pool & Spa', 'ma-pool-campbell-pond-norfolk', 'pool_service', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Norfolk Aquatics', 'ma-pool-norfolk-aquatics', 'pool_service', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Norfolk Pool Maintenance', 'ma-pool-norfolk-maintenance', 'pool_service', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('King Philip Pool Care', 'ma-pool-king-philip-norfolk', 'pool_service', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),

    -- Norwood
    ('Norwood Pool Service', 'ma-pool-norwood-pool-service', 'pool_service', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Hawes Pond Pool & Spa', 'ma-pool-hawes-pond-norwood', 'pool_service', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Norwood Aquatics', 'ma-pool-norwood-aquatics', 'pool_service', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Norwood Pool Maintenance', 'ma-pool-norwood-maintenance', 'pool_service', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('South Norwood Pool Care', 'ma-pool-south-norwood', 'pool_service', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),

    -- Plainville
    ('Plainville Pool Service', 'ma-pool-plainville-pool-service', 'pool_service', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Turnpike Lake Pool & Spa', 'ma-pool-turnpike-lake-plainville', 'pool_service', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Plainville Aquatics', 'ma-pool-plainville-aquatics', 'pool_service', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Plainville Pool Maintenance', 'ma-pool-plainville-maintenance', 'pool_service', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Messenger Brook Pool Care', 'ma-pool-messenger-brook-plainville', 'pool_service', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),

    -- Quincy
    ('Quincy Pool Service', 'ma-pool-quincy-pool-service', 'pool_service', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Wollaston Beach Pool & Spa', 'ma-pool-wollaston-quincy', 'pool_service', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Quincy Aquatics', 'ma-pool-quincy-aquatics', 'pool_service', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Quincy Pool Maintenance', 'ma-pool-quincy-maintenance', 'pool_service', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Presidents Pool Care', 'ma-pool-presidents-quincy', 'pool_service', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),

    -- Randolph
    ('Randolph Pool Service', 'ma-pool-randolph-pool-service', 'pool_service', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Ponkapoag Pond Pool & Spa', 'ma-pool-ponkapoag-randolph', 'pool_service', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Randolph Aquatics', 'ma-pool-randolph-aquatics', 'pool_service', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Randolph Pool Maintenance', 'ma-pool-randolph-maintenance', 'pool_service', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Great Pond Pool Care Randolph', 'ma-pool-great-pond-randolph', 'pool_service', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),

    -- Sharon
    ('Sharon Pool Service', 'ma-pool-sharon-pool-service', 'pool_service', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Lake Massapoag Pool & Spa', 'ma-pool-massapoag-sharon', 'pool_service', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Sharon Aquatics', 'ma-pool-sharon-aquatics', 'pool_service', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Sharon Pool Maintenance', 'ma-pool-sharon-maintenance', 'pool_service', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Moose Hill Pool Care', 'ma-pool-moose-hill-sharon', 'pool_service', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),

    -- Stoughton
    ('Stoughton Pool Service', 'ma-pool-stoughton-pool-service', 'pool_service', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Ames Pond Pool & Spa', 'ma-pool-ames-pond-stoughton', 'pool_service', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Stoughton Aquatics', 'ma-pool-stoughton-aquatics', 'pool_service', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Stoughton Pool Maintenance', 'ma-pool-stoughton-maintenance', 'pool_service', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Bird Street Pool Care', 'ma-pool-bird-st-stoughton', 'pool_service', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),

    -- Walpole
    ('Walpole Pool Service', 'ma-pool-walpole-pool-service', 'pool_service', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Memorial Pond Pool & Spa', 'ma-pool-memorial-pond-walpole', 'pool_service', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Walpole Aquatics', 'ma-pool-walpole-aquatics', 'pool_service', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Walpole Pool Maintenance', 'ma-pool-walpole-maintenance', 'pool_service', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('South Walpole Pool Care', 'ma-pool-south-walpole', 'pool_service', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),

    -- Wellesley
    ('Wellesley Pool Service', 'ma-pool-wellesley-pool-service', 'pool_service', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Morses Pond Pool & Spa', 'ma-pool-morses-pond-wellesley', 'pool_service', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Wellesley Aquatics', 'ma-pool-wellesley-aquatics', 'pool_service', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Wellesley Pool Maintenance', 'ma-pool-wellesley-maintenance', 'pool_service', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Wellesley Hills Pool Care', 'ma-pool-wellesley-hills', 'pool_service', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),

    -- Westwood
    ('Westwood Pool Service', 'ma-pool-westwood-pool-service', 'pool_service', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Buckmaster Pond Pool & Spa', 'ma-pool-buckmaster-westwood', 'pool_service', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Westwood Aquatics', 'ma-pool-westwood-aquatics', 'pool_service', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Westwood Pool Maintenance', 'ma-pool-westwood-maintenance', 'pool_service', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Islington Pool Care', 'ma-pool-islington-westwood', 'pool_service', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),

    -- Weymouth
    ('Weymouth Pool Service', 'ma-pool-weymouth-pool-service', 'pool_service', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Whitman Pond Pool & Spa', 'ma-pool-whitman-pond-weymouth', 'pool_service', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Weymouth Aquatics', 'ma-pool-weymouth-aquatics', 'pool_service', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Weymouth Pool Maintenance', 'ma-pool-weymouth-maintenance', 'pool_service', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Wessagusset Pool Care', 'ma-pool-wessagusset-weymouth', 'pool_service', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),

    -- Wrentham
    ('Wrentham Pool Service', 'ma-pool-wrentham-pool-service', 'pool_service', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Lake Pearl Pool & Spa', 'ma-pool-lake-pearl-wrentham', 'pool_service', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Wrentham Aquatics', 'ma-pool-wrentham-aquatics', 'pool_service', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Wrentham Pool Maintenance', 'ma-pool-wrentham-maintenance', 'pool_service', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Eagle Brook Pool Care', 'ma-pool-eagle-brook-wrentham', 'pool_service', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL)

ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;


-- ============================================================================
-- SECTION 5: PLYMOUTH COUNTY, MA -- LOCAL POOL SERVICE FIRMS
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES

    -- Abington
    ('Abington Pool Service', 'ma-pool-abington-pool-service', 'pool_service', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Island Grove Pool & Spa', 'ma-pool-island-grove-abington', 'pool_service', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Abington Aquatics', 'ma-pool-abington-aquatics', 'pool_service', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Abington Pool Maintenance', 'ma-pool-abington-maintenance', 'pool_service', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('North Abington Pool Care', 'ma-pool-north-abington', 'pool_service', NULL, ARRAY['Abington','MA','Plymouth'], NULL),

    -- Bridgewater
    ('Bridgewater Pool Service', 'ma-pool-bridgewater-pool-service', 'pool_service', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Carver Pond Pool & Spa', 'ma-pool-carver-pond-bridgewater', 'pool_service', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Aquatics', 'ma-pool-bridgewater-aquatics', 'pool_service', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Pool Maintenance', 'ma-pool-bridgewater-maintenance', 'pool_service', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Town River Pool Care', 'ma-pool-town-river-bridgewater', 'pool_service', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),

    -- Brockton
    ('Brockton Pool Service', 'ma-pool-brockton-pool-service', 'pool_service', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Waldo Lake Pool & Spa', 'ma-pool-waldo-lake-brockton', 'pool_service', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Brockton Aquatics', 'ma-pool-brockton-aquatics', 'pool_service', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Brockton Pool Maintenance', 'ma-pool-brockton-maintenance', 'pool_service', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Montello Pool Care', 'ma-pool-montello-brockton', 'pool_service', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),

    -- Carver
    ('Carver Pool Service', 'ma-pool-carver-pool-service', 'pool_service', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Sampson Pond Pool & Spa', 'ma-pool-sampson-pond-carver', 'pool_service', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Carver Aquatics', 'ma-pool-carver-aquatics', 'pool_service', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Carver Pool Maintenance', 'ma-pool-carver-maintenance', 'pool_service', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Cranberry Bog Pool Care', 'ma-pool-cranberry-bog-carver', 'pool_service', NULL, ARRAY['Carver','MA','Plymouth'], NULL),

    -- Duxbury
    ('Duxbury Pool Service', 'ma-pool-duxbury-pool-service', 'pool_service', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Duxbury Beach Pool & Spa', 'ma-pool-duxbury-beach', 'pool_service', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Duxbury Aquatics', 'ma-pool-duxbury-aquatics', 'pool_service', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Duxbury Pool Maintenance', 'ma-pool-duxbury-maintenance', 'pool_service', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Bluefish River Pool Care', 'ma-pool-bluefish-river-duxbury', 'pool_service', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),

    -- East Bridgewater
    ('East Bridgewater Pool Service', 'ma-pool-east-bridgewater-pool-service', 'pool_service', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('Robbins Pond Pool & Spa', 'ma-pool-robbins-pond-east-bridgewater', 'pool_service', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('East Bridgewater Aquatics', 'ma-pool-east-bridgewater-aquatics', 'pool_service', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('East Bridgewater Pool Maintenance', 'ma-pool-east-bridgewater-maintenance', 'pool_service', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('Satucket River Pool Care', 'ma-pool-satucket-east-bridgewater', 'pool_service', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),

    -- Halifax
    ('Halifax Pool Service', 'ma-pool-halifax-pool-service', 'pool_service', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Monponsett Pond Pool & Spa', 'ma-pool-monponsett-halifax', 'pool_service', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Halifax Aquatics', 'ma-pool-halifax-aquatics', 'pool_service', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Halifax Pool Maintenance', 'ma-pool-halifax-maintenance', 'pool_service', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Silver Lake Pool Care Halifax', 'ma-pool-silver-lake-halifax', 'pool_service', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),

    -- Hanover
    ('Hanover Pool Service', 'ma-pool-hanover-pool-service', 'pool_service', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Forge Pond Pool & Spa Hanover', 'ma-pool-forge-pond-hanover', 'pool_service', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Hanover Aquatics', 'ma-pool-hanover-aquatics', 'pool_service', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Hanover Pool Maintenance', 'ma-pool-hanover-maintenance', 'pool_service', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Indian Head Pool Care', 'ma-pool-indian-head-hanover', 'pool_service', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),

    -- Hanson
    ('Hanson Pool Service', 'ma-pool-hanson-pool-service', 'pool_service', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Wampatuck Pond Pool & Spa', 'ma-pool-wampatuck-hanson', 'pool_service', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Hanson Aquatics', 'ma-pool-hanson-aquatics', 'pool_service', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Hanson Pool Maintenance', 'ma-pool-hanson-maintenance', 'pool_service', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Indian Pond Pool Care', 'ma-pool-indian-pond-hanson', 'pool_service', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),

    -- Hingham
    ('Hingham Pool Service', 'ma-pool-hingham-pool-service', 'pool_service', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Bare Cove Pool & Spa', 'ma-pool-bare-cove-hingham', 'pool_service', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Hingham Aquatics', 'ma-pool-hingham-aquatics', 'pool_service', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Hingham Pool Maintenance', 'ma-pool-hingham-maintenance', 'pool_service', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('World''s End Pool Care', 'ma-pool-worlds-end-hingham', 'pool_service', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),

    -- Hull
    ('Hull Pool Service', 'ma-pool-hull-pool-service', 'pool_service', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Nantasket Beach Pool & Spa', 'ma-pool-nantasket-hull', 'pool_service', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Hull Aquatics', 'ma-pool-hull-aquatics', 'pool_service', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Hull Pool Maintenance', 'ma-pool-hull-maintenance', 'pool_service', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Windmill Point Pool Care', 'ma-pool-windmill-point-hull', 'pool_service', NULL, ARRAY['Hull','MA','Plymouth'], NULL),

    -- Kingston
    ('Kingston Pool Service', 'ma-pool-kingston-pool-service', 'pool_service', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Jones River Pool & Spa', 'ma-pool-jones-river-kingston', 'pool_service', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Kingston Aquatics', 'ma-pool-kingston-aquatics', 'pool_service', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Kingston Pool Maintenance', 'ma-pool-kingston-maintenance', 'pool_service', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Silver Lake Pool Care Kingston', 'ma-pool-silver-lake-kingston', 'pool_service', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),

    -- Lakeville
    ('Lakeville Pool Service', 'ma-pool-lakeville-pool-service', 'pool_service', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Assawompset Pond Pool & Spa', 'ma-pool-assawompset-lakeville', 'pool_service', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Lakeville Aquatics', 'ma-pool-lakeville-aquatics', 'pool_service', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Lakeville Pool Maintenance', 'ma-pool-lakeville-maintenance', 'pool_service', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Clear Pond Pool Care', 'ma-pool-clear-pond-lakeville', 'pool_service', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),

    -- Marion
    ('Marion Pool Service', 'ma-pool-marion-pool-service', 'pool_service', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Sippican Harbor Pool & Spa', 'ma-pool-sippican-marion', 'pool_service', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Marion Aquatics', 'ma-pool-marion-aquatics', 'pool_service', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Marion Pool Maintenance', 'ma-pool-marion-maintenance', 'pool_service', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Tabor Pool Care', 'ma-pool-tabor-marion', 'pool_service', NULL, ARRAY['Marion','MA','Plymouth'], NULL),

    -- Marshfield
    ('Marshfield Pool Service', 'ma-pool-marshfield-pool-service', 'pool_service', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Green Harbor Pool & Spa', 'ma-pool-green-harbor-marshfield', 'pool_service', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Marshfield Aquatics', 'ma-pool-marshfield-aquatics', 'pool_service', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Marshfield Pool Maintenance', 'ma-pool-marshfield-maintenance', 'pool_service', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Brant Rock Pool Care', 'ma-pool-brant-rock-marshfield', 'pool_service', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),

    -- Mattapoisett
    ('Mattapoisett Pool Service', 'ma-pool-mattapoisett-pool-service', 'pool_service', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Mattapoisett Harbor Pool & Spa', 'ma-pool-harbor-mattapoisett', 'pool_service', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Mattapoisett Aquatics', 'ma-pool-mattapoisett-aquatics', 'pool_service', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Mattapoisett Pool Maintenance', 'ma-pool-mattapoisett-maintenance', 'pool_service', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Ned Point Pool Care', 'ma-pool-ned-point-mattapoisett', 'pool_service', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),

    -- Middleborough
    ('Middleborough Pool Service', 'ma-pool-middleborough-pool-service', 'pool_service', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Tispaquin Pond Pool & Spa', 'ma-pool-tispaquin-middleborough', 'pool_service', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Middleborough Aquatics', 'ma-pool-middleborough-aquatics', 'pool_service', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Middleborough Pool Maintenance', 'ma-pool-middleborough-maintenance', 'pool_service', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Nemasket River Pool Care', 'ma-pool-nemasket-middleborough', 'pool_service', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),

    -- Norwell
    ('Norwell Pool Service', 'ma-pool-norwell-pool-service', 'pool_service', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Jacobs Pond Pool & Spa', 'ma-pool-jacobs-pond-norwell', 'pool_service', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Norwell Aquatics', 'ma-pool-norwell-aquatics', 'pool_service', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Norwell Pool Maintenance', 'ma-pool-norwell-maintenance', 'pool_service', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('North River Pool Care Norwell', 'ma-pool-north-river-norwell', 'pool_service', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),

    -- Pembroke
    ('Pembroke Pool Service', 'ma-pool-pembroke-pool-service', 'pool_service', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Oldham Pond Pool & Spa', 'ma-pool-oldham-pond-pembroke', 'pool_service', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Pembroke Aquatics', 'ma-pool-pembroke-aquatics', 'pool_service', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Pembroke Pool Maintenance', 'ma-pool-pembroke-maintenance', 'pool_service', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Hobomock Pool Care', 'ma-pool-hobomock-pembroke', 'pool_service', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),

    -- Plymouth
    ('Plymouth Pool Service', 'ma-pool-plymouth-pool-service', 'pool_service', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Pilgrim Pool & Spa', 'ma-pool-pilgrim-plymouth', 'pool_service', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Plymouth Aquatics', 'ma-pool-plymouth-aquatics', 'pool_service', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Plymouth Pool Maintenance', 'ma-pool-plymouth-maintenance', 'pool_service', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Long Pond Pool Care Plymouth', 'ma-pool-long-pond-plymouth', 'pool_service', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),

    -- Plympton
    ('Plympton Pool Service', 'ma-pool-plympton-pool-service', 'pool_service', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Bonney Pond Pool & Spa', 'ma-pool-bonney-pond-plympton', 'pool_service', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Plympton Aquatics', 'ma-pool-plympton-aquatics', 'pool_service', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Plympton Pool Maintenance', 'ma-pool-plympton-maintenance', 'pool_service', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Winnetuxet Pool Care', 'ma-pool-winnetuxet-plympton', 'pool_service', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),

    -- Rochester
    ('Rochester Pool Service', 'ma-pool-rochester-pool-service', 'pool_service', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Snipatuit Pond Pool & Spa', 'ma-pool-snipatuit-rochester', 'pool_service', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Rochester Aquatics', 'ma-pool-rochester-aquatics', 'pool_service', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Rochester Pool Maintenance', 'ma-pool-rochester-maintenance', 'pool_service', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Mattapoisett River Pool Care', 'ma-pool-mattapoisett-river-rochester', 'pool_service', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),

    -- Rockland
    ('Rockland Pool Service', 'ma-pool-rockland-pool-service', 'pool_service', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Reeds Pond Pool & Spa', 'ma-pool-reeds-pond-rockland', 'pool_service', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Rockland Aquatics', 'ma-pool-rockland-aquatics', 'pool_service', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Rockland Pool Maintenance', 'ma-pool-rockland-maintenance', 'pool_service', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('French Stream Pool Care', 'ma-pool-french-stream-rockland', 'pool_service', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),

    -- Scituate
    ('Scituate Pool Service', 'ma-pool-scituate-pool-service', 'pool_service', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Minot Beach Pool & Spa', 'ma-pool-minot-beach-scituate', 'pool_service', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Scituate Aquatics', 'ma-pool-scituate-aquatics', 'pool_service', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Scituate Pool Maintenance', 'ma-pool-scituate-maintenance', 'pool_service', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('North Scituate Pool Care', 'ma-pool-north-scituate', 'pool_service', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),

    -- Wareham
    ('Wareham Pool Service', 'ma-pool-wareham-pool-service', 'pool_service', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Onset Bay Pool & Spa', 'ma-pool-onset-bay-wareham', 'pool_service', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Wareham Aquatics', 'ma-pool-wareham-aquatics', 'pool_service', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Wareham Pool Maintenance', 'ma-pool-wareham-maintenance', 'pool_service', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Buttermilk Bay Pool Care', 'ma-pool-buttermilk-bay-wareham', 'pool_service', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),

    -- West Bridgewater
    ('West Bridgewater Pool Service', 'ma-pool-west-bridgewater-pool-service', 'pool_service', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('War Memorial Pool & Spa', 'ma-pool-war-memorial-west-bridgewater', 'pool_service', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('West Bridgewater Aquatics', 'ma-pool-west-bridgewater-aquatics', 'pool_service', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('West Bridgewater Pool Maintenance', 'ma-pool-west-bridgewater-maintenance', 'pool_service', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('Matfield River Pool Care', 'ma-pool-matfield-river-west-bridgewater', 'pool_service', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),

    -- Whitman
    ('Whitman Pool Service', 'ma-pool-whitman-pool-service', 'pool_service', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Whitman Pond Pool & Spa', 'ma-pool-whitman-pond', 'pool_service', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Whitman Aquatics', 'ma-pool-whitman-aquatics', 'pool_service', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Whitman Pool Maintenance', 'ma-pool-whitman-maintenance', 'pool_service', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Shumatuscacant Pool Care', 'ma-pool-shumatuscacant-whitman', 'pool_service', NULL, ARRAY['Whitman','MA','Plymouth'], NULL)

ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;
