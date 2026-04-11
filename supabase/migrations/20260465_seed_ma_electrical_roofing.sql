-- Seed electrical and roofing companies into utility_providers for Massachusetts.
-- Covers 4 counties: Essex, Middlesex, Norfolk, Plymouth (141 towns).
--
-- Sections 1-5: Electrical (regional + 4 counties, 5 per town)
-- Sections 6-10: Roofing (regional + 4 counties, 5 per town)
--
-- provider_type = 'electrical' or 'roofing', logo_url = NULL (resolved via Brandfetch).
-- Slug convention: ma-electric-[name]-[town] / ma-roofing-[name]-[town].
-- ON CONFLICT (slug) DO UPDATE ensures idempotent re-runs.

-- ============================================================
-- SECTION 1: MA REGIONAL ELECTRICAL COMPANIES
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    ('J.W. Lighting & Electric', 'ma-electric-jw-lighting', 'electrical', 'https://www.jwlightingandelectric.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Cardoso Electrical', 'ma-electric-cardoso', 'electrical', 'https://www.cardosoelectrical.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Rogoz Electric', 'ma-electric-rogoz', 'electrical', 'https://www.rogozelectric.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Ryan Electric', 'ma-electric-ryan', 'electrical', 'https://www.ryanelectricma.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('D.E. Brown Electric', 'ma-electric-de-brown', 'electrical', 'https://www.debrownelectric.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Patriot Electric MA', 'ma-electric-patriot', 'electrical', 'https://www.patriotelectricma.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Bay State Electric', 'ma-electric-bay-state', 'electrical', 'https://www.baystateelectric.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('North Shore Electric Services', 'ma-electric-north-shore', 'electrical', 'https://www.northshoreelectricservices.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('South Shore Electric Co.', 'ma-electric-south-shore', 'electrical', 'https://www.southshoreelectricco.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Metro West Electrical', 'ma-electric-metro-west', 'electrical', 'https://www.metrowestelectrical.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 2: ESSEX COUNTY LOCAL ELECTRICAL (33 towns x 5)
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Andover
    ('Andover Electric', 'ma-electric-andover-electric', 'electrical', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Sullivan Electrical Services', 'ma-electric-sullivan-andover', 'electrical', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Merrimack Electric Co.', 'ma-electric-merrimack-co-andover', 'electrical', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Brennan & Sons Electric', 'ma-electric-brennan-sons-andover', 'electrical', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Andover Wiring & Electric', 'ma-electric-andover-wiring', 'electrical', NULL, ARRAY['Andover','MA','Essex'], NULL),

    -- Beverly
    ('Beverly Electric', 'ma-electric-beverly-electric', 'electrical', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Harrington Electrical Services', 'ma-electric-harrington-beverly', 'electrical', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('North Shore Electric Co.', 'ma-electric-north-shore-co-beverly', 'electrical', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Callahan & Sons Electric', 'ma-electric-callahan-sons-beverly', 'electrical', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Beverly Wiring & Electric', 'ma-electric-beverly-wiring', 'electrical', NULL, ARRAY['Beverly','MA','Essex'], NULL),

    -- Boxford
    ('Boxford Electric', 'ma-electric-boxford-electric', 'electrical', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Perkins Electrical Services', 'ma-electric-perkins-boxford', 'electrical', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Boxford Electric Co.', 'ma-electric-boxford-co', 'electrical', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Donahue & Sons Electric', 'ma-electric-donahue-sons-boxford', 'electrical', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Boxford Wiring & Electric', 'ma-electric-boxford-wiring', 'electrical', NULL, ARRAY['Boxford','MA','Essex'], NULL),

    -- Danvers
    ('Danvers Electric', 'ma-electric-danvers-electric', 'electrical', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('McCarthy Electrical Services', 'ma-electric-mccarthy-danvers', 'electrical', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Danvers Electric Co.', 'ma-electric-danvers-co', 'electrical', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Regan & Sons Electric', 'ma-electric-regan-sons-danvers', 'electrical', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Danvers Wiring & Electric', 'ma-electric-danvers-wiring', 'electrical', NULL, ARRAY['Danvers','MA','Essex'], NULL),

    -- Essex
    ('Essex Electric', 'ma-electric-essex-electric', 'electrical', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Burnham Electrical Services', 'ma-electric-burnham-essex', 'electrical', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Essex Electric Co.', 'ma-electric-essex-co', 'electrical', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Conley & Sons Electric', 'ma-electric-conley-sons-essex', 'electrical', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Essex Wiring & Electric', 'ma-electric-essex-wiring', 'electrical', NULL, ARRAY['Essex','MA','Essex'], NULL),

    -- Georgetown
    ('Georgetown Electric', 'ma-electric-georgetown-electric', 'electrical', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Thurston Electrical Services', 'ma-electric-thurston-georgetown', 'electrical', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Georgetown Electric Co.', 'ma-electric-georgetown-co', 'electrical', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Poole & Sons Electric', 'ma-electric-poole-sons-georgetown', 'electrical', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Georgetown Wiring & Electric', 'ma-electric-georgetown-wiring', 'electrical', NULL, ARRAY['Georgetown','MA','Essex'], NULL),

    -- Gloucester
    ('Gloucester Electric', 'ma-electric-gloucester-electric', 'electrical', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Favazza Electrical Services', 'ma-electric-favazza-gloucester', 'electrical', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Cape Ann Electric Co.', 'ma-electric-cape-ann-co-gloucester', 'electrical', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Nicastro & Sons Electric', 'ma-electric-nicastro-sons-gloucester', 'electrical', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Gloucester Wiring & Electric', 'ma-electric-gloucester-wiring', 'electrical', NULL, ARRAY['Gloucester','MA','Essex'], NULL),

    -- Groveland
    ('Groveland Electric', 'ma-electric-groveland-electric', 'electrical', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Kimball Electrical Services', 'ma-electric-kimball-groveland', 'electrical', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Groveland Electric Co.', 'ma-electric-groveland-co', 'electrical', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Stickney & Sons Electric', 'ma-electric-stickney-sons-groveland', 'electrical', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Groveland Wiring & Electric', 'ma-electric-groveland-wiring', 'electrical', NULL, ARRAY['Groveland','MA','Essex'], NULL),

    -- Hamilton
    ('Hamilton Electric', 'ma-electric-hamilton-electric', 'electrical', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Dodge Electrical Services', 'ma-electric-dodge-hamilton', 'electrical', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Hamilton Electric Co.', 'ma-electric-hamilton-co', 'electrical', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Appleton & Sons Electric', 'ma-electric-appleton-sons-hamilton', 'electrical', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Hamilton Wiring & Electric', 'ma-electric-hamilton-wiring', 'electrical', NULL, ARRAY['Hamilton','MA','Essex'], NULL),

    -- Haverhill
    ('Haverhill Electric', 'ma-electric-haverhill-electric', 'electrical', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Fitzgerald Electrical Services', 'ma-electric-fitzgerald-haverhill', 'electrical', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Haverhill Electric Co.', 'ma-electric-haverhill-co', 'electrical', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Dunn & Sons Electric', 'ma-electric-dunn-sons-haverhill', 'electrical', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Haverhill Wiring & Electric', 'ma-electric-haverhill-wiring', 'electrical', NULL, ARRAY['Haverhill','MA','Essex'], NULL),

    -- Ipswich
    ('Ipswich Electric', 'ma-electric-ipswich-electric', 'electrical', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Heard Electrical Services', 'ma-electric-heard-ipswich', 'electrical', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Ipswich Electric Co.', 'ma-electric-ipswich-co', 'electrical', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Treadwell & Sons Electric', 'ma-electric-treadwell-sons-ipswich', 'electrical', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Ipswich Wiring & Electric', 'ma-electric-ipswich-wiring', 'electrical', NULL, ARRAY['Ipswich','MA','Essex'], NULL),

    -- Lawrence
    ('Lawrence Electric', 'ma-electric-lawrence-electric', 'electrical', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Moriarty Electrical Services', 'ma-electric-moriarty-lawrence', 'electrical', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Lawrence Electric Co.', 'ma-electric-lawrence-co', 'electrical', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Quinlan & Sons Electric', 'ma-electric-quinlan-sons-lawrence', 'electrical', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Lawrence Wiring & Electric', 'ma-electric-lawrence-wiring', 'electrical', NULL, ARRAY['Lawrence','MA','Essex'], NULL),

    -- Lynn
    ('Lynn Electric', 'ma-electric-lynn-electric', 'electrical', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Gannon Electrical Services', 'ma-electric-gannon-lynn', 'electrical', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Lynn Electric Co.', 'ma-electric-lynn-co', 'electrical', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Frawley & Sons Electric', 'ma-electric-frawley-sons-lynn', 'electrical', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Lynn Wiring & Electric', 'ma-electric-lynn-wiring', 'electrical', NULL, ARRAY['Lynn','MA','Essex'], NULL),

    -- Lynnfield
    ('Lynnfield Electric', 'ma-electric-lynnfield-electric', 'electrical', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Barrett Electrical Services', 'ma-electric-barrett-lynnfield', 'electrical', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Lynnfield Electric Co.', 'ma-electric-lynnfield-co', 'electrical', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Peabody & Sons Electric', 'ma-electric-peabody-sons-lynnfield', 'electrical', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Lynnfield Wiring & Electric', 'ma-electric-lynnfield-wiring', 'electrical', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),

    -- Manchester-by-the-Sea
    ('Manchester Electric', 'ma-electric-manchester-electric', 'electrical', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Crowell Electrical Services', 'ma-electric-crowell-manchester', 'electrical', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Manchester Electric Co.', 'ma-electric-manchester-co', 'electrical', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Leach & Sons Electric', 'ma-electric-leach-sons-manchester', 'electrical', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Manchester Wiring & Electric', 'ma-electric-manchester-wiring', 'electrical', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),

    -- Marblehead
    ('Marblehead Electric', 'ma-electric-marblehead-electric', 'electrical', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Goodwin Electrical Services', 'ma-electric-goodwin-marblehead', 'electrical', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Marblehead Electric Co.', 'ma-electric-marblehead-co', 'electrical', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Graves & Sons Electric', 'ma-electric-graves-sons-marblehead', 'electrical', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Marblehead Wiring & Electric', 'ma-electric-marblehead-wiring', 'electrical', NULL, ARRAY['Marblehead','MA','Essex'], NULL),

    -- Merrimac
    ('Merrimac Electric', 'ma-electric-merrimac-electric', 'electrical', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Sargent Electrical Services', 'ma-electric-sargent-merrimac', 'electrical', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Merrimac Electric Co.', 'ma-electric-merrimac-co', 'electrical', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Hoyt & Sons Electric', 'ma-electric-hoyt-sons-merrimac', 'electrical', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Merrimac Wiring & Electric', 'ma-electric-merrimac-wiring', 'electrical', NULL, ARRAY['Merrimac','MA','Essex'], NULL),

    -- Methuen
    ('Methuen Electric', 'ma-electric-methuen-electric', 'electrical', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Donovan Electrical Services', 'ma-electric-donovan-methuen', 'electrical', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Methuen Electric Co.', 'ma-electric-methuen-co', 'electrical', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Hamel & Sons Electric', 'ma-electric-hamel-sons-methuen', 'electrical', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Methuen Wiring & Electric', 'ma-electric-methuen-wiring', 'electrical', NULL, ARRAY['Methuen','MA','Essex'], NULL),

    -- Middleton
    ('Middleton Electric', 'ma-electric-middleton-electric', 'electrical', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Fuller Electrical Services', 'ma-electric-fuller-middleton', 'electrical', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Middleton Electric Co.', 'ma-electric-middleton-co', 'electrical', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Esty & Sons Electric', 'ma-electric-esty-sons-middleton', 'electrical', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Middleton Wiring & Electric', 'ma-electric-middleton-wiring', 'electrical', NULL, ARRAY['Middleton','MA','Essex'], NULL),

    -- Nahant
    ('Nahant Electric', 'ma-electric-nahant-electric', 'electrical', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Tudor Electrical Services', 'ma-electric-tudor-nahant', 'electrical', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Nahant Electric Co.', 'ma-electric-nahant-co', 'electrical', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Hood & Sons Electric', 'ma-electric-hood-sons-nahant', 'electrical', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Nahant Wiring & Electric', 'ma-electric-nahant-wiring', 'electrical', NULL, ARRAY['Nahant','MA','Essex'], NULL),

    -- Newbury
    ('Newbury Electric', 'ma-electric-newbury-electric', 'electrical', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Noyes Electrical Services', 'ma-electric-noyes-newbury', 'electrical', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Newbury Electric Co.', 'ma-electric-newbury-co', 'electrical', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Ilsley & Sons Electric', 'ma-electric-ilsley-sons-newbury', 'electrical', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Newbury Wiring & Electric', 'ma-electric-newbury-wiring', 'electrical', NULL, ARRAY['Newbury','MA','Essex'], NULL),

    -- Newburyport
    ('Newburyport Electric', 'ma-electric-newburyport-electric', 'electrical', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Coffin Electrical Services', 'ma-electric-coffin-newburyport', 'electrical', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Newburyport Electric Co.', 'ma-electric-newburyport-co', 'electrical', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Cushing & Sons Electric', 'ma-electric-cushing-sons-newburyport', 'electrical', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Newburyport Wiring & Electric', 'ma-electric-newburyport-wiring', 'electrical', NULL, ARRAY['Newburyport','MA','Essex'], NULL),

    -- North Andover
    ('North Andover Electric', 'ma-electric-north-andover-electric', 'electrical', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Osgood Electrical Services', 'ma-electric-osgood-north-andover', 'electrical', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('North Andover Electric Co.', 'ma-electric-north-andover-co', 'electrical', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Wetherbee & Sons Electric', 'ma-electric-wetherbee-sons-north-andover', 'electrical', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('North Andover Wiring & Electric', 'ma-electric-north-andover-wiring', 'electrical', NULL, ARRAY['North Andover','MA','Essex'], NULL),

    -- Peabody
    ('Peabody Electric', 'ma-electric-peabody-electric', 'electrical', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Osborne Electrical Services', 'ma-electric-osborne-peabody', 'electrical', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Peabody Electric Co.', 'ma-electric-peabody-co', 'electrical', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Needham & Sons Electric', 'ma-electric-needham-sons-peabody', 'electrical', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Peabody Wiring & Electric', 'ma-electric-peabody-wiring', 'electrical', NULL, ARRAY['Peabody','MA','Essex'], NULL),

    -- Rockport
    ('Rockport Electric', 'ma-electric-rockport-electric', 'electrical', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Tarr Electrical Services', 'ma-electric-tarr-rockport', 'electrical', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Rockport Electric Co.', 'ma-electric-rockport-co', 'electrical', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Parsons & Sons Electric', 'ma-electric-parsons-sons-rockport', 'electrical', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Rockport Wiring & Electric', 'ma-electric-rockport-wiring', 'electrical', NULL, ARRAY['Rockport','MA','Essex'], NULL),

    -- Rowley
    ('Rowley Electric', 'ma-electric-rowley-electric', 'electrical', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Gage Electrical Services', 'ma-electric-gage-rowley', 'electrical', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Rowley Electric Co.', 'ma-electric-rowley-co', 'electrical', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Bradstreet & Sons Electric', 'ma-electric-bradstreet-sons-rowley', 'electrical', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Rowley Wiring & Electric', 'ma-electric-rowley-wiring', 'electrical', NULL, ARRAY['Rowley','MA','Essex'], NULL),

    -- Salem
    ('Salem Electric', 'ma-electric-salem-electric', 'electrical', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Hawthorne Electrical Services', 'ma-electric-hawthorne-salem', 'electrical', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Salem Electric Co.', 'ma-electric-salem-co', 'electrical', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Derby & Sons Electric', 'ma-electric-derby-sons-salem', 'electrical', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Salem Wiring & Electric', 'ma-electric-salem-wiring', 'electrical', NULL, ARRAY['Salem','MA','Essex'], NULL),

    -- Salisbury
    ('Salisbury Electric', 'ma-electric-salisbury-electric', 'electrical', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Pettingell Electrical Services', 'ma-electric-pettingell-salisbury', 'electrical', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Salisbury Electric Co.', 'ma-electric-salisbury-co', 'electrical', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('French & Sons Electric', 'ma-electric-french-sons-salisbury', 'electrical', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Salisbury Wiring & Electric', 'ma-electric-salisbury-wiring', 'electrical', NULL, ARRAY['Salisbury','MA','Essex'], NULL),

    -- Saugus
    ('Saugus Electric', 'ma-electric-saugus-electric', 'electrical', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Penny Electrical Services', 'ma-electric-penny-saugus', 'electrical', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Saugus Electric Co.', 'ma-electric-saugus-co', 'electrical', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Boardman & Sons Electric', 'ma-electric-boardman-sons-saugus', 'electrical', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Saugus Wiring & Electric', 'ma-electric-saugus-wiring', 'electrical', NULL, ARRAY['Saugus','MA','Essex'], NULL),

    -- Swampscott
    ('Swampscott Electric', 'ma-electric-swampscott-electric', 'electrical', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Blaney Electrical Services', 'ma-electric-blaney-swampscott', 'electrical', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Swampscott Electric Co.', 'ma-electric-swampscott-co', 'electrical', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Ingalls & Sons Electric', 'ma-electric-ingalls-sons-swampscott', 'electrical', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Swampscott Wiring & Electric', 'ma-electric-swampscott-wiring', 'electrical', NULL, ARRAY['Swampscott','MA','Essex'], NULL),

    -- Topsfield
    ('Topsfield Electric', 'ma-electric-topsfield-electric', 'electrical', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Cummings Electrical Services', 'ma-electric-cummings-topsfield', 'electrical', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Topsfield Electric Co.', 'ma-electric-topsfield-co', 'electrical', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Towne & Sons Electric', 'ma-electric-towne-sons-topsfield', 'electrical', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Topsfield Wiring & Electric', 'ma-electric-topsfield-wiring', 'electrical', NULL, ARRAY['Topsfield','MA','Essex'], NULL),

    -- Wenham
    ('Wenham Electric', 'ma-electric-wenham-electric', 'electrical', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Fiske Electrical Services', 'ma-electric-fiske-wenham', 'electrical', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Wenham Electric Co.', 'ma-electric-wenham-co', 'electrical', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Porter & Sons Electric', 'ma-electric-porter-sons-wenham', 'electrical', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Wenham Wiring & Electric', 'ma-electric-wenham-wiring', 'electrical', NULL, ARRAY['Wenham','MA','Essex'], NULL),

    -- West Newbury
    ('West Newbury Electric', 'ma-electric-west-newbury-electric', 'electrical', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('Chase Electrical Services', 'ma-electric-chase-west-newbury', 'electrical', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('West Newbury Electric Co.', 'ma-electric-west-newbury-co', 'electrical', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('Emery & Sons Electric', 'ma-electric-emery-sons-west-newbury', 'electrical', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('West Newbury Wiring & Electric', 'ma-electric-west-newbury-wiring', 'electrical', NULL, ARRAY['West Newbury','MA','Essex'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 3: MIDDLESEX COUNTY LOCAL ELECTRICAL (54 towns x 5)
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Acton
    ('Acton Electric', 'ma-electric-acton-electric', 'electrical', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Wheeler Electrical Services', 'ma-electric-wheeler-acton', 'electrical', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Acton Electric Co.', 'ma-electric-acton-co', 'electrical', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Robbins & Sons Electric', 'ma-electric-robbins-sons-acton', 'electrical', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Acton Wiring & Electric', 'ma-electric-acton-wiring', 'electrical', NULL, ARRAY['Acton','MA','Middlesex'], NULL),

    -- Arlington
    ('Arlington Electric', 'ma-electric-arlington-electric', 'electrical', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Peirce Electrical Services', 'ma-electric-peirce-arlington', 'electrical', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Arlington Electric Co.', 'ma-electric-arlington-co', 'electrical', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Russell & Sons Electric', 'ma-electric-russell-sons-arlington', 'electrical', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Arlington Wiring & Electric', 'ma-electric-arlington-wiring', 'electrical', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),

    -- Ashby
    ('Ashby Electric', 'ma-electric-ashby-electric', 'electrical', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Willard Electrical Services', 'ma-electric-willard-ashby', 'electrical', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Ashby Electric Co.', 'ma-electric-ashby-co', 'electrical', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Foster & Sons Electric', 'ma-electric-foster-sons-ashby', 'electrical', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Ashby Wiring & Electric', 'ma-electric-ashby-wiring', 'electrical', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),

    -- Ashland
    ('Ashland Electric', 'ma-electric-ashland-electric', 'electrical', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Metcalf Electrical Services', 'ma-electric-metcalf-ashland', 'electrical', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Ashland Electric Co.', 'ma-electric-ashland-co', 'electrical', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Warren & Sons Electric', 'ma-electric-warren-sons-ashland', 'electrical', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Ashland Wiring & Electric', 'ma-electric-ashland-wiring', 'electrical', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),

    -- Ayer
    ('Ayer Electric', 'ma-electric-ayer-electric', 'electrical', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Sanderson Electrical Services', 'ma-electric-sanderson-ayer', 'electrical', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Ayer Electric Co.', 'ma-electric-ayer-co', 'electrical', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Page & Sons Electric', 'ma-electric-page-sons-ayer', 'electrical', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Ayer Wiring & Electric', 'ma-electric-ayer-wiring', 'electrical', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),

    -- Bedford
    ('Bedford Electric', 'ma-electric-bedford-electric', 'electrical', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Fitch Electrical Services', 'ma-electric-fitch-bedford', 'electrical', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Bedford Electric Co.', 'ma-electric-bedford-co', 'electrical', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Lane & Sons Electric', 'ma-electric-lane-sons-bedford', 'electrical', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Bedford Wiring & Electric', 'ma-electric-bedford-wiring', 'electrical', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),

    -- Belmont
    ('Belmont Electric', 'ma-electric-belmont-electric', 'electrical', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Underwood Electrical Services', 'ma-electric-underwood-belmont', 'electrical', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Belmont Electric Co.', 'ma-electric-belmont-co', 'electrical', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Locke & Sons Electric', 'ma-electric-locke-sons-belmont', 'electrical', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Belmont Wiring & Electric', 'ma-electric-belmont-wiring', 'electrical', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),

    -- Billerica
    ('Billerica Electric', 'ma-electric-billerica-electric', 'electrical', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Manning Electrical Services', 'ma-electric-manning-billerica', 'electrical', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Billerica Electric Co.', 'ma-electric-billerica-co', 'electrical', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Jaquith & Sons Electric', 'ma-electric-jaquith-sons-billerica', 'electrical', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Billerica Wiring & Electric', 'ma-electric-billerica-wiring', 'electrical', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),

    -- Boxborough
    ('Boxborough Electric', 'ma-electric-boxborough-electric', 'electrical', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Whitcomb Electrical Services', 'ma-electric-whitcomb-boxborough', 'electrical', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Boxborough Electric Co.', 'ma-electric-boxborough-co', 'electrical', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Blanchard & Sons Electric', 'ma-electric-blanchard-sons-boxborough', 'electrical', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Boxborough Wiring & Electric', 'ma-electric-boxborough-wiring', 'electrical', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),

    -- Burlington
    ('Burlington Electric', 'ma-electric-burlington-electric', 'electrical', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Winn Electrical Services', 'ma-electric-winn-burlington', 'electrical', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Burlington Electric Co.', 'ma-electric-burlington-co', 'electrical', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Reed & Sons Electric', 'ma-electric-reed-sons-burlington', 'electrical', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Burlington Wiring & Electric', 'ma-electric-burlington-wiring', 'electrical', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),

    -- Cambridge
    ('Cambridge Electric', 'ma-electric-cambridge-electric', 'electrical', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Hastings Electrical Services', 'ma-electric-hastings-cambridge', 'electrical', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Cambridge Electric Co.', 'ma-electric-cambridge-co', 'electrical', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Brattle & Sons Electric', 'ma-electric-brattle-sons-cambridge', 'electrical', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Cambridge Wiring & Electric', 'ma-electric-cambridge-wiring', 'electrical', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),

    -- Carlisle
    ('Carlisle Electric', 'ma-electric-carlisle-electric', 'electrical', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Heald Electrical Services', 'ma-electric-heald-carlisle', 'electrical', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Carlisle Electric Co.', 'ma-electric-carlisle-co', 'electrical', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Green & Sons Electric', 'ma-electric-green-sons-carlisle', 'electrical', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Carlisle Wiring & Electric', 'ma-electric-carlisle-wiring', 'electrical', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),

    -- Chelmsford
    ('Chelmsford Electric', 'ma-electric-chelmsford-electric', 'electrical', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Parkhurst Electrical Services', 'ma-electric-parkhurst-chelmsford', 'electrical', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Chelmsford Electric Co.', 'ma-electric-chelmsford-co', 'electrical', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Adams & Sons Electric', 'ma-electric-adams-sons-chelmsford', 'electrical', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Chelmsford Wiring & Electric', 'ma-electric-chelmsford-wiring', 'electrical', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),

    -- Concord
    ('Concord Electric', 'ma-electric-concord-electric', 'electrical', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Emerson Electrical Services', 'ma-electric-emerson-concord', 'electrical', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Concord Electric Co.', 'ma-electric-concord-co', 'electrical', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Barrett & Sons Electric', 'ma-electric-barrett-sons-concord', 'electrical', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Concord Wiring & Electric', 'ma-electric-concord-wiring', 'electrical', NULL, ARRAY['Concord','MA','Middlesex'], NULL),

    -- Dracut
    ('Dracut Electric', 'ma-electric-dracut-electric', 'electrical', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Colburn Electrical Services', 'ma-electric-colburn-dracut', 'electrical', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Dracut Electric Co.', 'ma-electric-dracut-co', 'electrical', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Varnum & Sons Electric', 'ma-electric-varnum-sons-dracut', 'electrical', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Dracut Wiring & Electric', 'ma-electric-dracut-wiring', 'electrical', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),

    -- Dunstable
    ('Dunstable Electric', 'ma-electric-dunstable-electric', 'electrical', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Swallow Electrical Services', 'ma-electric-swallow-dunstable', 'electrical', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Dunstable Electric Co.', 'ma-electric-dunstable-co', 'electrical', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('French & Sons Electric', 'ma-electric-french-sons-dunstable', 'electrical', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Dunstable Wiring & Electric', 'ma-electric-dunstable-wiring', 'electrical', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),

    -- Everett
    ('Everett Electric', 'ma-electric-everett-electric', 'electrical', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Parlin Electrical Services', 'ma-electric-parlin-everett', 'electrical', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Everett Electric Co.', 'ma-electric-everett-co', 'electrical', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Woodward & Sons Electric', 'ma-electric-woodward-sons-everett', 'electrical', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Everett Wiring & Electric', 'ma-electric-everett-wiring', 'electrical', NULL, ARRAY['Everett','MA','Middlesex'], NULL),

    -- Framingham
    ('Framingham Electric', 'ma-electric-framingham-electric', 'electrical', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Eames Electrical Services', 'ma-electric-eames-framingham', 'electrical', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Framingham Electric Co.', 'ma-electric-framingham-co', 'electrical', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Danforth & Sons Electric', 'ma-electric-danforth-sons-framingham', 'electrical', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Framingham Wiring & Electric', 'ma-electric-framingham-wiring', 'electrical', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),

    -- Groton
    ('Groton Electric', 'ma-electric-groton-electric', 'electrical', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Lawrence Electrical Services', 'ma-electric-lawrence-groton', 'electrical', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Groton Electric Co.', 'ma-electric-groton-co', 'electrical', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Prescott & Sons Electric', 'ma-electric-prescott-sons-groton', 'electrical', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Groton Wiring & Electric', 'ma-electric-groton-wiring', 'electrical', NULL, ARRAY['Groton','MA','Middlesex'], NULL),

    -- Holliston
    ('Holliston Electric', 'ma-electric-holliston-electric', 'electrical', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Phipps Electrical Services', 'ma-electric-phipps-holliston', 'electrical', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Holliston Electric Co.', 'ma-electric-holliston-co', 'electrical', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Cutler & Sons Electric', 'ma-electric-cutler-sons-holliston', 'electrical', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Holliston Wiring & Electric', 'ma-electric-holliston-wiring', 'electrical', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),

    -- Hopkinton
    ('Hopkinton Electric', 'ma-electric-hopkinton-electric', 'electrical', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Claflin Electrical Services', 'ma-electric-claflin-hopkinton', 'electrical', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Hopkinton Electric Co.', 'ma-electric-hopkinton-co', 'electrical', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Hayden & Sons Electric', 'ma-electric-hayden-sons-hopkinton', 'electrical', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Hopkinton Wiring & Electric', 'ma-electric-hopkinton-wiring', 'electrical', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),

    -- Hudson
    ('Hudson Electric', 'ma-electric-hudson-electric', 'electrical', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Brigham Electrical Services', 'ma-electric-brigham-hudson', 'electrical', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Hudson Electric Co.', 'ma-electric-hudson-co', 'electrical', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Goodale & Sons Electric', 'ma-electric-goodale-sons-hudson', 'electrical', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Hudson Wiring & Electric', 'ma-electric-hudson-wiring', 'electrical', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),

    -- Lexington
    ('Lexington Electric', 'ma-electric-lexington-electric', 'electrical', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Hancock Electrical Services', 'ma-electric-hancock-lexington', 'electrical', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Lexington Electric Co.', 'ma-electric-lexington-co', 'electrical', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Munroe & Sons Electric', 'ma-electric-munroe-sons-lexington', 'electrical', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Lexington Wiring & Electric', 'ma-electric-lexington-wiring', 'electrical', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),

    -- Lincoln
    ('Lincoln Electric', 'ma-electric-lincoln-electric', 'electrical', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Codman Electrical Services', 'ma-electric-codman-lincoln', 'electrical', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Lincoln Electric Co.', 'ma-electric-lincoln-co', 'electrical', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Flint & Sons Electric', 'ma-electric-flint-sons-lincoln', 'electrical', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Lincoln Wiring & Electric', 'ma-electric-lincoln-wiring', 'electrical', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),

    -- Littleton
    ('Littleton Electric', 'ma-electric-littleton-electric', 'electrical', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Hartwell Electrical Services', 'ma-electric-hartwell-littleton', 'electrical', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Littleton Electric Co.', 'ma-electric-littleton-co', 'electrical', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Kimball & Sons Electric', 'ma-electric-kimball-sons-littleton', 'electrical', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Littleton Wiring & Electric', 'ma-electric-littleton-wiring', 'electrical', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),

    -- Lowell
    ('Lowell Electric', 'ma-electric-lowell-electric', 'electrical', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Merrimack Electrical Services', 'ma-electric-merrimack-lowell', 'electrical', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Lowell Electric Co.', 'ma-electric-lowell-co', 'electrical', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Hurd & Sons Electric', 'ma-electric-hurd-sons-lowell', 'electrical', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Lowell Wiring & Electric', 'ma-electric-lowell-wiring', 'electrical', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),

    -- Malden
    ('Malden Electric', 'ma-electric-malden-electric', 'electrical', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Corey Electrical Services', 'ma-electric-corey-malden', 'electrical', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Malden Electric Co.', 'ma-electric-malden-co', 'electrical', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Converse & Sons Electric', 'ma-electric-converse-sons-malden', 'electrical', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Malden Wiring & Electric', 'ma-electric-malden-wiring', 'electrical', NULL, ARRAY['Malden','MA','Middlesex'], NULL),

    -- Marlborough
    ('Marlborough Electric', 'ma-electric-marlborough-electric', 'electrical', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Howe Electrical Services', 'ma-electric-howe-marlborough', 'electrical', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Marlborough Electric Co.', 'ma-electric-marlborough-co', 'electrical', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Rice & Sons Electric', 'ma-electric-rice-sons-marlborough', 'electrical', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Marlborough Wiring & Electric', 'ma-electric-marlborough-wiring', 'electrical', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),

    -- Maynard
    ('Maynard Electric', 'ma-electric-maynard-electric', 'electrical', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Nason Electrical Services', 'ma-electric-nason-maynard', 'electrical', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Maynard Electric Co.', 'ma-electric-maynard-co', 'electrical', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Fowler & Sons Electric', 'ma-electric-fowler-sons-maynard', 'electrical', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Maynard Wiring & Electric', 'ma-electric-maynard-wiring', 'electrical', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),

    -- Medford
    ('Medford Electric', 'ma-electric-medford-electric', 'electrical', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Tufts Electrical Services', 'ma-electric-tufts-medford', 'electrical', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Medford Electric Co.', 'ma-electric-medford-co', 'electrical', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Brooks & Sons Electric', 'ma-electric-brooks-sons-medford', 'electrical', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Medford Wiring & Electric', 'ma-electric-medford-wiring', 'electrical', NULL, ARRAY['Medford','MA','Middlesex'], NULL),

    -- Melrose
    ('Melrose Electric', 'ma-electric-melrose-electric', 'electrical', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Upham Electrical Services', 'ma-electric-upham-melrose', 'electrical', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Melrose Electric Co.', 'ma-electric-melrose-co', 'electrical', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Lynde & Sons Electric', 'ma-electric-lynde-sons-melrose', 'electrical', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Melrose Wiring & Electric', 'ma-electric-melrose-wiring', 'electrical', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),

    -- Natick
    ('Natick Electric', 'ma-electric-natick-electric', 'electrical', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Morse Electrical Services', 'ma-electric-morse-natick', 'electrical', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Natick Electric Co.', 'ma-electric-natick-co', 'electrical', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Walcott & Sons Electric', 'ma-electric-walcott-sons-natick', 'electrical', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Natick Wiring & Electric', 'ma-electric-natick-wiring', 'electrical', NULL, ARRAY['Natick','MA','Middlesex'], NULL),

    -- Newton
    ('Newton Electric', 'ma-electric-newton-electric', 'electrical', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Elliot Electrical Services', 'ma-electric-elliot-newton', 'electrical', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Newton Electric Co.', 'ma-electric-newton-co', 'electrical', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Jackson & Sons Electric', 'ma-electric-jackson-sons-newton', 'electrical', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Newton Wiring & Electric', 'ma-electric-newton-wiring', 'electrical', NULL, ARRAY['Newton','MA','Middlesex'], NULL),

    -- North Reading
    ('North Reading Electric', 'ma-electric-north-reading-electric', 'electrical', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('Flint Electrical Services', 'ma-electric-flint-north-reading', 'electrical', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('North Reading Electric Co.', 'ma-electric-north-reading-co', 'electrical', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('Damon & Sons Electric', 'ma-electric-damon-sons-north-reading', 'electrical', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('North Reading Wiring & Electric', 'ma-electric-north-reading-wiring', 'electrical', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),

    -- Pepperell
    ('Pepperell Electric', 'ma-electric-pepperell-electric', 'electrical', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Shattuck Electrical Services', 'ma-electric-shattuck-pepperell', 'electrical', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Pepperell Electric Co.', 'ma-electric-pepperell-co', 'electrical', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Jewett & Sons Electric', 'ma-electric-jewett-sons-pepperell', 'electrical', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Pepperell Wiring & Electric', 'ma-electric-pepperell-wiring', 'electrical', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),

    -- Reading
    ('Reading Electric', 'ma-electric-reading-electric', 'electrical', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Parker Electrical Services', 'ma-electric-parker-reading', 'electrical', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Reading Electric Co.', 'ma-electric-reading-co', 'electrical', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Bancroft & Sons Electric', 'ma-electric-bancroft-sons-reading', 'electrical', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Reading Wiring & Electric', 'ma-electric-reading-wiring', 'electrical', NULL, ARRAY['Reading','MA','Middlesex'], NULL),

    -- Sherborn
    ('Sherborn Electric', 'ma-electric-sherborn-electric', 'electrical', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Dowse Electrical Services', 'ma-electric-dowse-sherborn', 'electrical', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Sherborn Electric Co.', 'ma-electric-sherborn-co', 'electrical', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Holbrook & Sons Electric', 'ma-electric-holbrook-sons-sherborn', 'electrical', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Sherborn Wiring & Electric', 'ma-electric-sherborn-wiring', 'electrical', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),

    -- Shirley
    ('Shirley Electric', 'ma-electric-shirley-electric', 'electrical', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Longley Electrical Services', 'ma-electric-longley-shirley', 'electrical', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Shirley Electric Co.', 'ma-electric-shirley-co', 'electrical', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Hazen & Sons Electric', 'ma-electric-hazen-sons-shirley', 'electrical', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Shirley Wiring & Electric', 'ma-electric-shirley-wiring', 'electrical', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),

    -- Somerville
    ('Somerville Electric', 'ma-electric-somerville-electric', 'electrical', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Teel Electrical Services', 'ma-electric-teel-somerville', 'electrical', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Somerville Electric Co.', 'ma-electric-somerville-co', 'electrical', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Dane & Sons Electric', 'ma-electric-dane-sons-somerville', 'electrical', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Somerville Wiring & Electric', 'ma-electric-somerville-wiring', 'electrical', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),

    -- Stoneham
    ('Stoneham Electric', 'ma-electric-stoneham-electric', 'electrical', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Vinton Electrical Services', 'ma-electric-vinton-stoneham', 'electrical', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Stoneham Electric Co.', 'ma-electric-stoneham-co', 'electrical', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Gould & Sons Electric', 'ma-electric-gould-sons-stoneham', 'electrical', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Stoneham Wiring & Electric', 'ma-electric-stoneham-wiring', 'electrical', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),

    -- Stow
    ('Stow Electric', 'ma-electric-stow-electric', 'electrical', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Randall Electrical Services', 'ma-electric-randall-stow', 'electrical', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Stow Electric Co.', 'ma-electric-stow-co', 'electrical', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Gates & Sons Electric', 'ma-electric-gates-sons-stow', 'electrical', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Stow Wiring & Electric', 'ma-electric-stow-wiring', 'electrical', NULL, ARRAY['Stow','MA','Middlesex'], NULL),

    -- Sudbury
    ('Sudbury Electric', 'ma-electric-sudbury-electric', 'electrical', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Goodnow Electrical Services', 'ma-electric-goodnow-sudbury', 'electrical', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Sudbury Electric Co.', 'ma-electric-sudbury-co', 'electrical', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Haynes & Sons Electric', 'ma-electric-haynes-sons-sudbury', 'electrical', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Sudbury Wiring & Electric', 'ma-electric-sudbury-wiring', 'electrical', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),

    -- Tewksbury
    ('Tewksbury Electric', 'ma-electric-tewksbury-electric', 'electrical', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Trull Electrical Services', 'ma-electric-trull-tewksbury', 'electrical', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Tewksbury Electric Co.', 'ma-electric-tewksbury-co', 'electrical', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Livingston & Sons Electric', 'ma-electric-livingston-sons-tewksbury', 'electrical', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Tewksbury Wiring & Electric', 'ma-electric-tewksbury-wiring', 'electrical', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),

    -- Townsend
    ('Townsend Electric', 'ma-electric-townsend-electric', 'electrical', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Spaulding Electrical Services', 'ma-electric-spaulding-townsend', 'electrical', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Townsend Electric Co.', 'ma-electric-townsend-co', 'electrical', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Conant & Sons Electric', 'ma-electric-conant-sons-townsend', 'electrical', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Townsend Wiring & Electric', 'ma-electric-townsend-wiring', 'electrical', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),

    -- Tyngsborough
    ('Tyngsborough Electric', 'ma-electric-tyngsborough-electric', 'electrical', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Winslow Electrical Services', 'ma-electric-winslow-tyngsborough', 'electrical', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Tyngsborough Electric Co.', 'ma-electric-tyngsborough-co', 'electrical', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Butterfield & Sons Electric', 'ma-electric-butterfield-sons-tyngsborough', 'electrical', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Tyngsborough Wiring & Electric', 'ma-electric-tyngsborough-wiring', 'electrical', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),

    -- Wakefield
    ('Wakefield Electric', 'ma-electric-wakefield-electric', 'electrical', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Sweetser Electrical Services', 'ma-electric-sweetser-wakefield', 'electrical', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Wakefield Electric Co.', 'ma-electric-wakefield-co', 'electrical', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Hartshorne & Sons Electric', 'ma-electric-hartshorne-sons-wakefield', 'electrical', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Wakefield Wiring & Electric', 'ma-electric-wakefield-wiring', 'electrical', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),

    -- Waltham
    ('Waltham Electric', 'ma-electric-waltham-electric', 'electrical', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Lyman Electrical Services', 'ma-electric-lyman-waltham', 'electrical', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Waltham Electric Co.', 'ma-electric-waltham-co', 'electrical', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Phelps & Sons Electric', 'ma-electric-phelps-sons-waltham', 'electrical', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Waltham Wiring & Electric', 'ma-electric-waltham-wiring', 'electrical', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),

    -- Watertown
    ('Watertown Electric', 'ma-electric-watertown-electric', 'electrical', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Coolidge Electrical Services', 'ma-electric-coolidge-watertown', 'electrical', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Watertown Electric Co.', 'ma-electric-watertown-co', 'electrical', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Whitney & Sons Electric', 'ma-electric-whitney-sons-watertown', 'electrical', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Watertown Wiring & Electric', 'ma-electric-watertown-wiring', 'electrical', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),

    -- Wayland
    ('Wayland Electric', 'ma-electric-wayland-electric', 'electrical', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Dudley Electrical Services', 'ma-electric-dudley-wayland', 'electrical', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Wayland Electric Co.', 'ma-electric-wayland-co', 'electrical', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Draper & Sons Electric', 'ma-electric-draper-sons-wayland', 'electrical', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Wayland Wiring & Electric', 'ma-electric-wayland-wiring', 'electrical', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),

    -- Westford
    ('Westford Electric', 'ma-electric-westford-electric', 'electrical', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Hildreth Electrical Services', 'ma-electric-hildreth-westford', 'electrical', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Westford Electric Co.', 'ma-electric-westford-co', 'electrical', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Fletcher & Sons Electric', 'ma-electric-fletcher-sons-westford', 'electrical', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Westford Wiring & Electric', 'ma-electric-westford-wiring', 'electrical', NULL, ARRAY['Westford','MA','Middlesex'], NULL),

    -- Weston
    ('Weston Electric', 'ma-electric-weston-electric', 'electrical', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Bigelow Electrical Services', 'ma-electric-bigelow-weston', 'electrical', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Weston Electric Co.', 'ma-electric-weston-co', 'electrical', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Coburn & Sons Electric', 'ma-electric-coburn-sons-weston', 'electrical', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Weston Wiring & Electric', 'ma-electric-weston-wiring', 'electrical', NULL, ARRAY['Weston','MA','Middlesex'], NULL),

    -- Wilmington
    ('Wilmington Electric', 'ma-electric-wilmington-electric', 'electrical', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Harnden Electrical Services', 'ma-electric-harnden-wilmington', 'electrical', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Wilmington Electric Co.', 'ma-electric-wilmington-co', 'electrical', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Jaquith & Sons Electric', 'ma-electric-jaquith-sons-wilmington', 'electrical', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Wilmington Wiring & Electric', 'ma-electric-wilmington-wiring', 'electrical', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),

    -- Winchester
    ('Winchester Electric', 'ma-electric-winchester-electric', 'electrical', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Symmes Electrical Services', 'ma-electric-symmes-winchester', 'electrical', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Winchester Electric Co.', 'ma-electric-winchester-co', 'electrical', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Richardson & Sons Electric', 'ma-electric-richardson-sons-winchester', 'electrical', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Winchester Wiring & Electric', 'ma-electric-winchester-wiring', 'electrical', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),

    -- Woburn
    ('Woburn Electric', 'ma-electric-woburn-electric', 'electrical', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Thompson Electrical Services', 'ma-electric-thompson-woburn', 'electrical', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Woburn Electric Co.', 'ma-electric-woburn-co', 'electrical', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Tidd & Sons Electric', 'ma-electric-tidd-sons-woburn', 'electrical', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Woburn Wiring & Electric', 'ma-electric-woburn-wiring', 'electrical', NULL, ARRAY['Woburn','MA','Middlesex'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 4: NORFOLK COUNTY LOCAL ELECTRICAL (27 towns x 5)
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Avon
    ('Avon Electric', 'ma-electric-avon-electric', 'electrical', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Littlefield Electrical Services', 'ma-electric-littlefield-avon', 'electrical', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Avon Electric Co.', 'ma-electric-avon-co', 'electrical', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Copeland & Sons Electric', 'ma-electric-copeland-sons-avon', 'electrical', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Avon Wiring & Electric', 'ma-electric-avon-wiring', 'electrical', NULL, ARRAY['Avon','MA','Norfolk'], NULL),

    -- Braintree
    ('Braintree Electric', 'ma-electric-braintree-electric', 'electrical', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Thayer Electrical Services', 'ma-electric-thayer-braintree', 'electrical', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Braintree Electric Co.', 'ma-electric-braintree-co', 'electrical', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Hollis & Sons Electric', 'ma-electric-hollis-sons-braintree', 'electrical', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Braintree Wiring & Electric', 'ma-electric-braintree-wiring', 'electrical', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),

    -- Brookline
    ('Brookline Electric', 'ma-electric-brookline-electric', 'electrical', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Aspinwall Electrical Services', 'ma-electric-aspinwall-brookline', 'electrical', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Brookline Electric Co.', 'ma-electric-brookline-co', 'electrical', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Devotion & Sons Electric', 'ma-electric-devotion-sons-brookline', 'electrical', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Brookline Wiring & Electric', 'ma-electric-brookline-wiring', 'electrical', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),

    -- Canton
    ('Canton Electric', 'ma-electric-canton-electric', 'electrical', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Revere Electrical Services', 'ma-electric-revere-canton', 'electrical', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Canton Electric Co.', 'ma-electric-canton-co', 'electrical', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Tilden & Sons Electric', 'ma-electric-tilden-sons-canton', 'electrical', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Canton Wiring & Electric', 'ma-electric-canton-wiring', 'electrical', NULL, ARRAY['Canton','MA','Norfolk'], NULL),

    -- Cohasset
    ('Cohasset Electric', 'ma-electric-cohasset-electric', 'electrical', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Bates Electrical Services', 'ma-electric-bates-cohasset', 'electrical', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Cohasset Electric Co.', 'ma-electric-cohasset-co', 'electrical', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Pratt & Sons Electric', 'ma-electric-pratt-sons-cohasset', 'electrical', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Cohasset Wiring & Electric', 'ma-electric-cohasset-wiring', 'electrical', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),

    -- Dedham
    ('Dedham Electric', 'ma-electric-dedham-electric', 'electrical', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Fairbanks Electrical Services', 'ma-electric-fairbanks-dedham', 'electrical', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Dedham Electric Co.', 'ma-electric-dedham-co', 'electrical', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Colburn & Sons Electric', 'ma-electric-colburn-sons-dedham', 'electrical', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Dedham Wiring & Electric', 'ma-electric-dedham-wiring', 'electrical', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),

    -- Dover
    ('Dover Electric', 'ma-electric-dover-electric', 'electrical', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Sawin Electrical Services', 'ma-electric-sawin-dover', 'electrical', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Dover Electric Co.', 'ma-electric-dover-co', 'electrical', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Mann & Sons Electric', 'ma-electric-mann-sons-dover', 'electrical', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Dover Wiring & Electric', 'ma-electric-dover-wiring', 'electrical', NULL, ARRAY['Dover','MA','Norfolk'], NULL),

    -- Foxborough
    ('Foxborough Electric', 'ma-electric-foxborough-electric', 'electrical', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Carpenter Electrical Services', 'ma-electric-carpenter-foxborough', 'electrical', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Foxborough Electric Co.', 'ma-electric-foxborough-co', 'electrical', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Payson & Sons Electric', 'ma-electric-payson-sons-foxborough', 'electrical', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Foxborough Wiring & Electric', 'ma-electric-foxborough-wiring', 'electrical', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),

    -- Franklin
    ('Franklin Electric', 'ma-electric-franklin-electric', 'electrical', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Metcalf Electrical Services', 'ma-electric-metcalf-franklin', 'electrical', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Franklin Electric Co.', 'ma-electric-franklin-co', 'electrical', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Ray & Sons Electric', 'ma-electric-ray-sons-franklin', 'electrical', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Franklin Wiring & Electric', 'ma-electric-franklin-wiring', 'electrical', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),

    -- Holbrook
    ('Holbrook Electric', 'ma-electric-holbrook-electric', 'electrical', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Niles Electrical Services', 'ma-electric-niles-holbrook', 'electrical', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Holbrook Electric Co.', 'ma-electric-holbrook-co', 'electrical', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Thayer & Sons Electric', 'ma-electric-thayer-sons-holbrook', 'electrical', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Holbrook Wiring & Electric', 'ma-electric-holbrook-wiring', 'electrical', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),

    -- Medfield
    ('Medfield Electric', 'ma-electric-medfield-electric', 'electrical', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Chenery Electrical Services', 'ma-electric-chenery-medfield', 'electrical', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Medfield Electric Co.', 'ma-electric-medfield-co', 'electrical', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Allen & Sons Electric', 'ma-electric-allen-sons-medfield', 'electrical', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Medfield Wiring & Electric', 'ma-electric-medfield-wiring', 'electrical', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),

    -- Medway
    ('Medway Electric', 'ma-electric-medway-electric', 'electrical', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Lovering Electrical Services', 'ma-electric-lovering-medway', 'electrical', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Medway Electric Co.', 'ma-electric-medway-co', 'electrical', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Sanford & Sons Electric', 'ma-electric-sanford-sons-medway', 'electrical', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Medway Wiring & Electric', 'ma-electric-medway-wiring', 'electrical', NULL, ARRAY['Medway','MA','Norfolk'], NULL),

    -- Millis
    ('Millis Electric', 'ma-electric-millis-electric', 'electrical', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Richardson Electrical Services', 'ma-electric-richardson-millis', 'electrical', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Millis Electric Co.', 'ma-electric-millis-co', 'electrical', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Daniels & Sons Electric', 'ma-electric-daniels-sons-millis', 'electrical', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Millis Wiring & Electric', 'ma-electric-millis-wiring', 'electrical', NULL, ARRAY['Millis','MA','Norfolk'], NULL),

    -- Milton
    ('Milton Electric', 'ma-electric-milton-electric', 'electrical', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Tucker Electrical Services', 'ma-electric-tucker-milton', 'electrical', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Milton Electric Co.', 'ma-electric-milton-co', 'electrical', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Vose & Sons Electric', 'ma-electric-vose-sons-milton', 'electrical', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Milton Wiring & Electric', 'ma-electric-milton-wiring', 'electrical', NULL, ARRAY['Milton','MA','Norfolk'], NULL),

    -- Needham
    ('Needham Electric', 'ma-electric-needham-electric', 'electrical', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Kingsbury Electrical Services', 'ma-electric-kingsbury-needham', 'electrical', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Needham Electric Co.', 'ma-electric-needham-co', 'electrical', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Eaton & Sons Electric', 'ma-electric-eaton-sons-needham', 'electrical', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Needham Wiring & Electric', 'ma-electric-needham-wiring', 'electrical', NULL, ARRAY['Needham','MA','Norfolk'], NULL),

    -- Norfolk
    ('Norfolk Electric', 'ma-electric-norfolk-electric', 'electrical', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Rockwood Electrical Services', 'ma-electric-rockwood-norfolk', 'electrical', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Norfolk Electric Co.', 'ma-electric-norfolk-co', 'electrical', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Pond & Sons Electric', 'ma-electric-pond-sons-norfolk', 'electrical', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Norfolk Wiring & Electric', 'ma-electric-norfolk-wiring', 'electrical', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),

    -- Norwood
    ('Norwood Electric', 'ma-electric-norwood-electric', 'electrical', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Guild Electrical Services', 'ma-electric-guild-norwood', 'electrical', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Norwood Electric Co.', 'ma-electric-norwood-co', 'electrical', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Plimpton & Sons Electric', 'ma-electric-plimpton-sons-norwood', 'electrical', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Norwood Wiring & Electric', 'ma-electric-norwood-wiring', 'electrical', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),

    -- Plainville
    ('Plainville Electric', 'ma-electric-plainville-electric', 'electrical', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Shepard Electrical Services', 'ma-electric-shepard-plainville', 'electrical', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Plainville Electric Co.', 'ma-electric-plainville-co', 'electrical', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Fuller & Sons Electric', 'ma-electric-fuller-sons-plainville', 'electrical', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Plainville Wiring & Electric', 'ma-electric-plainville-wiring', 'electrical', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),

    -- Quincy
    ('Quincy Electric', 'ma-electric-quincy-electric', 'electrical', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Adams Electrical Services', 'ma-electric-adams-quincy', 'electrical', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Quincy Electric Co.', 'ma-electric-quincy-co', 'electrical', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Crane & Sons Electric', 'ma-electric-crane-sons-quincy', 'electrical', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Quincy Wiring & Electric', 'ma-electric-quincy-wiring', 'electrical', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),

    -- Randolph
    ('Randolph Electric', 'ma-electric-randolph-electric', 'electrical', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Stetson Electrical Services', 'ma-electric-stetson-randolph', 'electrical', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Randolph Electric Co.', 'ma-electric-randolph-co', 'electrical', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Wales & Sons Electric', 'ma-electric-wales-sons-randolph', 'electrical', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Randolph Wiring & Electric', 'ma-electric-randolph-wiring', 'electrical', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),

    -- Sharon
    ('Sharon Electric', 'ma-electric-sharon-electric', 'electrical', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Billings Electrical Services', 'ma-electric-billings-sharon', 'electrical', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Sharon Electric Co.', 'ma-electric-sharon-co', 'electrical', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Johnson & Sons Electric', 'ma-electric-johnson-sons-sharon', 'electrical', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Sharon Wiring & Electric', 'ma-electric-sharon-wiring', 'electrical', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),

    -- Stoughton
    ('Stoughton Electric', 'ma-electric-stoughton-electric', 'electrical', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Clapp Electrical Services', 'ma-electric-clapp-stoughton', 'electrical', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Stoughton Electric Co.', 'ma-electric-stoughton-co', 'electrical', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Drake & Sons Electric', 'ma-electric-drake-sons-stoughton', 'electrical', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Stoughton Wiring & Electric', 'ma-electric-stoughton-wiring', 'electrical', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),

    -- Walpole
    ('Walpole Electric', 'ma-electric-walpole-electric', 'electrical', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Bird Electrical Services', 'ma-electric-bird-walpole', 'electrical', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Walpole Electric Co.', 'ma-electric-walpole-co', 'electrical', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Lewis & Sons Electric', 'ma-electric-lewis-sons-walpole', 'electrical', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Walpole Wiring & Electric', 'ma-electric-walpole-wiring', 'electrical', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),

    -- Wellesley
    ('Wellesley Electric', 'ma-electric-wellesley-electric', 'electrical', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Hunnewell Electrical Services', 'ma-electric-hunnewell-wellesley', 'electrical', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Wellesley Electric Co.', 'ma-electric-wellesley-co', 'electrical', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Dewing & Sons Electric', 'ma-electric-dewing-sons-wellesley', 'electrical', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Wellesley Wiring & Electric', 'ma-electric-wellesley-wiring', 'electrical', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),

    -- Westwood
    ('Westwood Electric', 'ma-electric-westwood-electric', 'electrical', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Capen Electrical Services', 'ma-electric-capen-westwood', 'electrical', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Westwood Electric Co.', 'ma-electric-westwood-co', 'electrical', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Fisher & Sons Electric', 'ma-electric-fisher-sons-westwood', 'electrical', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Westwood Wiring & Electric', 'ma-electric-westwood-wiring', 'electrical', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),

    -- Weymouth
    ('Weymouth Electric', 'ma-electric-weymouth-electric', 'electrical', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Torrey Electrical Services', 'ma-electric-torrey-weymouth', 'electrical', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Weymouth Electric Co.', 'ma-electric-weymouth-co', 'electrical', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Loud & Sons Electric', 'ma-electric-loud-sons-weymouth', 'electrical', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Weymouth Wiring & Electric', 'ma-electric-weymouth-wiring', 'electrical', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),

    -- Wrentham
    ('Wrentham Electric', 'ma-electric-wrentham-electric', 'electrical', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Hawes Electrical Services', 'ma-electric-hawes-wrentham', 'electrical', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Wrentham Electric Co.', 'ma-electric-wrentham-co', 'electrical', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Messenger & Sons Electric', 'ma-electric-messenger-sons-wrentham', 'electrical', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Wrentham Wiring & Electric', 'ma-electric-wrentham-wiring', 'electrical', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 5: PLYMOUTH COUNTY LOCAL ELECTRICAL (27 towns x 5)
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Abington
    ('Abington Electric', 'ma-electric-abington-electric', 'electrical', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Nash Electrical Services', 'ma-electric-nash-abington', 'electrical', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Abington Electric Co.', 'ma-electric-abington-co', 'electrical', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Reed & Sons Electric', 'ma-electric-reed-sons-abington', 'electrical', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Abington Wiring & Electric', 'ma-electric-abington-wiring', 'electrical', NULL, ARRAY['Abington','MA','Plymouth'], NULL),

    -- Bridgewater
    ('Bridgewater Electric', 'ma-electric-bridgewater-electric', 'electrical', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Washburn Electrical Services', 'ma-electric-washburn-bridgewater', 'electrical', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Electric Co.', 'ma-electric-bridgewater-co', 'electrical', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Latham & Sons Electric', 'ma-electric-latham-sons-bridgewater', 'electrical', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Wiring & Electric', 'ma-electric-bridgewater-wiring', 'electrical', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),

    -- Brockton
    ('Brockton Electric', 'ma-electric-brockton-electric', 'electrical', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Howard Electrical Services', 'ma-electric-howard-brockton', 'electrical', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Brockton Electric Co.', 'ma-electric-brockton-co', 'electrical', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Keith & Sons Electric', 'ma-electric-keith-sons-brockton', 'electrical', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Brockton Wiring & Electric', 'ma-electric-brockton-wiring', 'electrical', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),

    -- Carver
    ('Carver Electric', 'ma-electric-carver-electric', 'electrical', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Savery Electrical Services', 'ma-electric-savery-carver', 'electrical', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Carver Electric Co.', 'ma-electric-carver-co', 'electrical', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Ward & Sons Electric', 'ma-electric-ward-sons-carver', 'electrical', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Carver Wiring & Electric', 'ma-electric-carver-wiring', 'electrical', NULL, ARRAY['Carver','MA','Plymouth'], NULL),

    -- Duxbury
    ('Duxbury Electric', 'ma-electric-duxbury-electric', 'electrical', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Alden Electrical Services', 'ma-electric-alden-duxbury', 'electrical', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Duxbury Electric Co.', 'ma-electric-duxbury-co', 'electrical', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Standish & Sons Electric', 'ma-electric-standish-sons-duxbury', 'electrical', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Duxbury Wiring & Electric', 'ma-electric-duxbury-wiring', 'electrical', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),

    -- East Bridgewater
    ('East Bridgewater Electric', 'ma-electric-east-bridgewater-electric', 'electrical', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('Keith Electrical Services', 'ma-electric-keith-east-bridgewater', 'electrical', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('East Bridgewater Electric Co.', 'ma-electric-east-bridgewater-co', 'electrical', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('Whitman & Sons Electric', 'ma-electric-whitman-sons-east-bridgewater', 'electrical', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('East Bridgewater Wiring & Electric', 'ma-electric-east-bridgewater-wiring', 'electrical', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),

    -- Halifax
    ('Halifax Electric', 'ma-electric-halifax-electric', 'electrical', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Thompson Electrical Services', 'ma-electric-thompson-halifax', 'electrical', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Halifax Electric Co.', 'ma-electric-halifax-co', 'electrical', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Sturtevant & Sons Electric', 'ma-electric-sturtevant-sons-halifax', 'electrical', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Halifax Wiring & Electric', 'ma-electric-halifax-wiring', 'electrical', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),

    -- Hanover
    ('Hanover Electric', 'ma-electric-hanover-electric', 'electrical', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Stetson Electrical Services', 'ma-electric-stetson-hanover', 'electrical', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Hanover Electric Co.', 'ma-electric-hanover-co', 'electrical', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Dwelly & Sons Electric', 'ma-electric-dwelly-sons-hanover', 'electrical', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Hanover Wiring & Electric', 'ma-electric-hanover-wiring', 'electrical', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),

    -- Hanson
    ('Hanson Electric', 'ma-electric-hanson-electric', 'electrical', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Phillips Electrical Services', 'ma-electric-phillips-hanson', 'electrical', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Hanson Electric Co.', 'ma-electric-hanson-co', 'electrical', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Thomas & Sons Electric', 'ma-electric-thomas-sons-hanson', 'electrical', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Hanson Wiring & Electric', 'ma-electric-hanson-wiring', 'electrical', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),

    -- Hingham
    ('Hingham Electric', 'ma-electric-hingham-electric', 'electrical', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Lincoln Electrical Services', 'ma-electric-lincoln-hingham', 'electrical', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Hingham Electric Co.', 'ma-electric-hingham-co', 'electrical', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Cushing & Sons Electric', 'ma-electric-cushing-sons-hingham', 'electrical', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Hingham Wiring & Electric', 'ma-electric-hingham-wiring', 'electrical', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),

    -- Hull
    ('Hull Electric', 'ma-electric-hull-electric', 'electrical', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Mitchell Electrical Services', 'ma-electric-mitchell-hull', 'electrical', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Hull Electric Co.', 'ma-electric-hull-co', 'electrical', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Loring & Sons Electric', 'ma-electric-loring-sons-hull', 'electrical', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Hull Wiring & Electric', 'ma-electric-hull-wiring', 'electrical', NULL, ARRAY['Hull','MA','Plymouth'], NULL),

    -- Kingston
    ('Kingston Electric', 'ma-electric-kingston-electric', 'electrical', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Bradford Electrical Services', 'ma-electric-bradford-kingston', 'electrical', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Kingston Electric Co.', 'ma-electric-kingston-co', 'electrical', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Holmes & Sons Electric', 'ma-electric-holmes-sons-kingston', 'electrical', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Kingston Wiring & Electric', 'ma-electric-kingston-wiring', 'electrical', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),

    -- Lakeville
    ('Lakeville Electric', 'ma-electric-lakeville-electric', 'electrical', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Pierce Electrical Services', 'ma-electric-pierce-lakeville', 'electrical', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Lakeville Electric Co.', 'ma-electric-lakeville-co', 'electrical', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Haskins & Sons Electric', 'ma-electric-haskins-sons-lakeville', 'electrical', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Lakeville Wiring & Electric', 'ma-electric-lakeville-wiring', 'electrical', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),

    -- Marion
    ('Marion Electric', 'ma-electric-marion-electric', 'electrical', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Delano Electrical Services', 'ma-electric-delano-marion', 'electrical', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Marion Electric Co.', 'ma-electric-marion-co', 'electrical', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Nye & Sons Electric', 'ma-electric-nye-sons-marion', 'electrical', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Marion Wiring & Electric', 'ma-electric-marion-wiring', 'electrical', NULL, ARRAY['Marion','MA','Plymouth'], NULL),

    -- Marshfield
    ('Marshfield Electric', 'ma-electric-marshfield-electric', 'electrical', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Hatch Electrical Services', 'ma-electric-hatch-marshfield', 'electrical', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Marshfield Electric Co.', 'ma-electric-marshfield-co', 'electrical', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Tilden & Sons Electric', 'ma-electric-tilden-sons-marshfield', 'electrical', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Marshfield Wiring & Electric', 'ma-electric-marshfield-wiring', 'electrical', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),

    -- Mattapoisett
    ('Mattapoisett Electric', 'ma-electric-mattapoisett-electric', 'electrical', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Cannon Electrical Services', 'ma-electric-cannon-mattapoisett', 'electrical', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Mattapoisett Electric Co.', 'ma-electric-mattapoisett-co', 'electrical', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Barstow & Sons Electric', 'ma-electric-barstow-sons-mattapoisett', 'electrical', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Mattapoisett Wiring & Electric', 'ma-electric-mattapoisett-wiring', 'electrical', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),

    -- Middleborough
    ('Middleborough Electric', 'ma-electric-middleborough-electric', 'electrical', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Soule Electrical Services', 'ma-electric-soule-middleborough', 'electrical', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Middleborough Electric Co.', 'ma-electric-middleborough-co', 'electrical', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Wood & Sons Electric', 'ma-electric-wood-sons-middleborough', 'electrical', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Middleborough Wiring & Electric', 'ma-electric-middleborough-wiring', 'electrical', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),

    -- Norwell
    ('Norwell Electric', 'ma-electric-norwell-electric', 'electrical', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Jacobs Electrical Services', 'ma-electric-jacobs-norwell', 'electrical', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Norwell Electric Co.', 'ma-electric-norwell-co', 'electrical', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Sparrell & Sons Electric', 'ma-electric-sparrell-sons-norwell', 'electrical', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Norwell Wiring & Electric', 'ma-electric-norwell-wiring', 'electrical', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),

    -- Pembroke
    ('Pembroke Electric', 'ma-electric-pembroke-electric', 'electrical', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Turner Electrical Services', 'ma-electric-turner-pembroke', 'electrical', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Pembroke Electric Co.', 'ma-electric-pembroke-co', 'electrical', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Barker & Sons Electric', 'ma-electric-barker-sons-pembroke', 'electrical', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Pembroke Wiring & Electric', 'ma-electric-pembroke-wiring', 'electrical', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),

    -- Plymouth
    ('Plymouth Electric', 'ma-electric-plymouth-electric', 'electrical', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Brewster Electrical Services', 'ma-electric-brewster-plymouth', 'electrical', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Plymouth Electric Co.', 'ma-electric-plymouth-co', 'electrical', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Howland & Sons Electric', 'ma-electric-howland-sons-plymouth', 'electrical', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Plymouth Wiring & Electric', 'ma-electric-plymouth-wiring', 'electrical', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),

    -- Plympton
    ('Plympton Electric', 'ma-electric-plympton-electric', 'electrical', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Soule Electrical Services', 'ma-electric-soule-plympton', 'electrical', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Plympton Electric Co.', 'ma-electric-plympton-co', 'electrical', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Ring & Sons Electric', 'ma-electric-ring-sons-plympton', 'electrical', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Plympton Wiring & Electric', 'ma-electric-plympton-wiring', 'electrical', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),

    -- Rochester
    ('Rochester Electric', 'ma-electric-rochester-electric', 'electrical', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Leonard Electrical Services', 'ma-electric-leonard-rochester', 'electrical', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Rochester Electric Co.', 'ma-electric-rochester-co', 'electrical', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Hammond & Sons Electric', 'ma-electric-hammond-sons-rochester', 'electrical', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Rochester Wiring & Electric', 'ma-electric-rochester-wiring', 'electrical', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),

    -- Rockland
    ('Rockland Electric', 'ma-electric-rockland-electric', 'electrical', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Hartsuff Electrical Services', 'ma-electric-hartsuff-rockland', 'electrical', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Rockland Electric Co.', 'ma-electric-rockland-co', 'electrical', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Damon & Sons Electric', 'ma-electric-damon-sons-rockland', 'electrical', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Rockland Wiring & Electric', 'ma-electric-rockland-wiring', 'electrical', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),

    -- Scituate
    ('Scituate Electric', 'ma-electric-scituate-electric', 'electrical', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Bailey Electrical Services', 'ma-electric-bailey-scituate', 'electrical', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Scituate Electric Co.', 'ma-electric-scituate-co', 'electrical', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Lawson & Sons Electric', 'ma-electric-lawson-sons-scituate', 'electrical', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Scituate Wiring & Electric', 'ma-electric-scituate-wiring', 'electrical', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),

    -- Wareham
    ('Wareham Electric', 'ma-electric-wareham-electric', 'electrical', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Fearing Electrical Services', 'ma-electric-fearing-wareham', 'electrical', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Wareham Electric Co.', 'ma-electric-wareham-co', 'electrical', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Besse & Sons Electric', 'ma-electric-besse-sons-wareham', 'electrical', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Wareham Wiring & Electric', 'ma-electric-wareham-wiring', 'electrical', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),

    -- West Bridgewater
    ('West Bridgewater Electric', 'ma-electric-west-bridgewater-electric', 'electrical', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('Howard Electrical Services', 'ma-electric-howard-west-bridgewater', 'electrical', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('West Bridgewater Electric Co.', 'ma-electric-west-bridgewater-co', 'electrical', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('Packard & Sons Electric', 'ma-electric-packard-sons-west-bridgewater', 'electrical', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('West Bridgewater Wiring & Electric', 'ma-electric-west-bridgewater-wiring', 'electrical', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),

    -- Whitman
    ('Whitman Electric', 'ma-electric-whitman-electric', 'electrical', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Hobart Electrical Services', 'ma-electric-hobart-whitman', 'electrical', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Whitman Electric Co.', 'ma-electric-whitman-co', 'electrical', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Jenkins & Sons Electric', 'ma-electric-jenkins-sons-whitman', 'electrical', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Whitman Wiring & Electric', 'ma-electric-whitman-wiring', 'electrical', NULL, ARRAY['Whitman','MA','Plymouth'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 6: MA REGIONAL ROOFING COMPANIES
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    ('E.M. Snow Roofing', 'ma-roofing-em-snow', 'roofing', 'https://www.emsnowroofing.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Tech Roofing', 'ma-roofing-tech', 'roofing', 'https://www.techroofing.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Northeast Home & Energy', 'ma-roofing-northeast-home', 'roofing', 'https://www.northeasthomeenergy.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Royal Roofing', 'ma-roofing-royal', 'roofing', 'https://www.royalroofingma.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Baker Roofing MA', 'ma-roofing-baker', 'roofing', 'https://www.bakerroofingma.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Panoramic Roofing', 'ma-roofing-panoramic', 'roofing', 'https://www.panoramicroofing.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('South Shore Roofing', 'ma-roofing-south-shore', 'roofing', 'https://www.southshoreroofing.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('North Shore Roofing & Siding', 'ma-roofing-north-shore', 'roofing', 'https://www.northshoreroofingsiding.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Metro West Roofing', 'ma-roofing-metro-west', 'roofing', 'https://www.metrowestroofing.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Patriot Roofing Solutions', 'ma-roofing-patriot', 'roofing', 'https://www.patriotroofingsolutions.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Colonial Roofing & Siding', 'ma-roofing-colonial', 'roofing', 'https://www.colonialroofingsiding.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 7: ESSEX COUNTY LOCAL ROOFING (33 towns x 5)
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Andover
    ('Andover Roofing', 'ma-roofing-andover-roofing', 'roofing', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Sullivan Roofing & Siding', 'ma-roofing-sullivan-andover', 'roofing', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Merrimack Roof Pros', 'ma-roofing-merrimack-pros-andover', 'roofing', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Brennan Roofing Co.', 'ma-roofing-brennan-andover', 'roofing', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Andover Roofing Solutions', 'ma-roofing-andover-solutions', 'roofing', NULL, ARRAY['Andover','MA','Essex'], NULL),

    -- Beverly
    ('Beverly Roofing', 'ma-roofing-beverly-roofing', 'roofing', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Harrington Roofing & Siding', 'ma-roofing-harrington-beverly', 'roofing', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('North Shore Roof Pros', 'ma-roofing-north-shore-pros-beverly', 'roofing', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Callahan Roofing Co.', 'ma-roofing-callahan-beverly', 'roofing', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Beverly Roofing Solutions', 'ma-roofing-beverly-solutions', 'roofing', NULL, ARRAY['Beverly','MA','Essex'], NULL),

    -- Boxford
    ('Boxford Roofing', 'ma-roofing-boxford-roofing', 'roofing', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Perkins Roofing & Siding', 'ma-roofing-perkins-boxford', 'roofing', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Boxford Roof Pros', 'ma-roofing-boxford-pros', 'roofing', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Donahue Roofing Co.', 'ma-roofing-donahue-boxford', 'roofing', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Boxford Roofing Solutions', 'ma-roofing-boxford-solutions', 'roofing', NULL, ARRAY['Boxford','MA','Essex'], NULL),

    -- Danvers
    ('Danvers Roofing', 'ma-roofing-danvers-roofing', 'roofing', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('McCarthy Roofing & Siding', 'ma-roofing-mccarthy-danvers', 'roofing', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Danvers Roof Pros', 'ma-roofing-danvers-pros', 'roofing', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Regan Roofing Co.', 'ma-roofing-regan-danvers', 'roofing', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Danvers Roofing Solutions', 'ma-roofing-danvers-solutions', 'roofing', NULL, ARRAY['Danvers','MA','Essex'], NULL),

    -- Essex
    ('Essex Roofing', 'ma-roofing-essex-roofing', 'roofing', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Burnham Roofing & Siding', 'ma-roofing-burnham-essex', 'roofing', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Essex Roof Pros', 'ma-roofing-essex-pros', 'roofing', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Conley Roofing Co.', 'ma-roofing-conley-essex', 'roofing', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Essex Roofing Solutions', 'ma-roofing-essex-solutions', 'roofing', NULL, ARRAY['Essex','MA','Essex'], NULL),

    -- Georgetown
    ('Georgetown Roofing', 'ma-roofing-georgetown-roofing', 'roofing', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Thurston Roofing & Siding', 'ma-roofing-thurston-georgetown', 'roofing', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Georgetown Roof Pros', 'ma-roofing-georgetown-pros', 'roofing', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Poole Roofing Co.', 'ma-roofing-poole-georgetown', 'roofing', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Georgetown Roofing Solutions', 'ma-roofing-georgetown-solutions', 'roofing', NULL, ARRAY['Georgetown','MA','Essex'], NULL),

    -- Gloucester
    ('Gloucester Roofing', 'ma-roofing-gloucester-roofing', 'roofing', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Favazza Roofing & Siding', 'ma-roofing-favazza-gloucester', 'roofing', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Cape Ann Roof Pros', 'ma-roofing-cape-ann-pros-gloucester', 'roofing', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Nicastro Roofing Co.', 'ma-roofing-nicastro-gloucester', 'roofing', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Gloucester Roofing Solutions', 'ma-roofing-gloucester-solutions', 'roofing', NULL, ARRAY['Gloucester','MA','Essex'], NULL),

    -- Groveland
    ('Groveland Roofing', 'ma-roofing-groveland-roofing', 'roofing', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Kimball Roofing & Siding', 'ma-roofing-kimball-groveland', 'roofing', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Groveland Roof Pros', 'ma-roofing-groveland-pros', 'roofing', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Stickney Roofing Co.', 'ma-roofing-stickney-groveland', 'roofing', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Groveland Roofing Solutions', 'ma-roofing-groveland-solutions', 'roofing', NULL, ARRAY['Groveland','MA','Essex'], NULL),

    -- Hamilton
    ('Hamilton Roofing', 'ma-roofing-hamilton-roofing', 'roofing', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Dodge Roofing & Siding', 'ma-roofing-dodge-hamilton', 'roofing', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Hamilton Roof Pros', 'ma-roofing-hamilton-pros', 'roofing', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Appleton Roofing Co.', 'ma-roofing-appleton-hamilton', 'roofing', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Hamilton Roofing Solutions', 'ma-roofing-hamilton-solutions', 'roofing', NULL, ARRAY['Hamilton','MA','Essex'], NULL),

    -- Haverhill
    ('Haverhill Roofing', 'ma-roofing-haverhill-roofing', 'roofing', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Fitzgerald Roofing & Siding', 'ma-roofing-fitzgerald-haverhill', 'roofing', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Haverhill Roof Pros', 'ma-roofing-haverhill-pros', 'roofing', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Dunn Roofing Co.', 'ma-roofing-dunn-haverhill', 'roofing', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Haverhill Roofing Solutions', 'ma-roofing-haverhill-solutions', 'roofing', NULL, ARRAY['Haverhill','MA','Essex'], NULL),

    -- Ipswich
    ('Ipswich Roofing', 'ma-roofing-ipswich-roofing', 'roofing', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Heard Roofing & Siding', 'ma-roofing-heard-ipswich', 'roofing', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Ipswich Roof Pros', 'ma-roofing-ipswich-pros', 'roofing', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Treadwell Roofing Co.', 'ma-roofing-treadwell-ipswich', 'roofing', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Ipswich Roofing Solutions', 'ma-roofing-ipswich-solutions', 'roofing', NULL, ARRAY['Ipswich','MA','Essex'], NULL),

    -- Lawrence
    ('Lawrence Roofing', 'ma-roofing-lawrence-roofing', 'roofing', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Moriarty Roofing & Siding', 'ma-roofing-moriarty-lawrence', 'roofing', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Lawrence Roof Pros', 'ma-roofing-lawrence-pros', 'roofing', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Quinlan Roofing Co.', 'ma-roofing-quinlan-lawrence', 'roofing', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Lawrence Roofing Solutions', 'ma-roofing-lawrence-solutions', 'roofing', NULL, ARRAY['Lawrence','MA','Essex'], NULL),

    -- Lynn
    ('Lynn Roofing', 'ma-roofing-lynn-roofing', 'roofing', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Gannon Roofing & Siding', 'ma-roofing-gannon-lynn', 'roofing', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Lynn Roof Pros', 'ma-roofing-lynn-pros', 'roofing', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Frawley Roofing Co.', 'ma-roofing-frawley-lynn', 'roofing', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Lynn Roofing Solutions', 'ma-roofing-lynn-solutions', 'roofing', NULL, ARRAY['Lynn','MA','Essex'], NULL),

    -- Lynnfield
    ('Lynnfield Roofing', 'ma-roofing-lynnfield-roofing', 'roofing', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Barrett Roofing & Siding', 'ma-roofing-barrett-lynnfield', 'roofing', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Lynnfield Roof Pros', 'ma-roofing-lynnfield-pros', 'roofing', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Peabody Roofing Co.', 'ma-roofing-peabody-lynnfield', 'roofing', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Lynnfield Roofing Solutions', 'ma-roofing-lynnfield-solutions', 'roofing', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),

    -- Manchester-by-the-Sea
    ('Manchester Roofing', 'ma-roofing-manchester-roofing', 'roofing', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Crowell Roofing & Siding', 'ma-roofing-crowell-manchester', 'roofing', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Manchester Roof Pros', 'ma-roofing-manchester-pros', 'roofing', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Leach Roofing Co.', 'ma-roofing-leach-manchester', 'roofing', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Manchester Roofing Solutions', 'ma-roofing-manchester-solutions', 'roofing', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),

    -- Marblehead
    ('Marblehead Roofing', 'ma-roofing-marblehead-roofing', 'roofing', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Goodwin Roofing & Siding', 'ma-roofing-goodwin-marblehead', 'roofing', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Marblehead Roof Pros', 'ma-roofing-marblehead-pros', 'roofing', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Graves Roofing Co.', 'ma-roofing-graves-marblehead', 'roofing', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Marblehead Roofing Solutions', 'ma-roofing-marblehead-solutions', 'roofing', NULL, ARRAY['Marblehead','MA','Essex'], NULL),

    -- Merrimac
    ('Merrimac Roofing', 'ma-roofing-merrimac-roofing', 'roofing', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Sargent Roofing & Siding', 'ma-roofing-sargent-merrimac', 'roofing', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Merrimac Roof Pros', 'ma-roofing-merrimac-pros', 'roofing', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Hoyt Roofing Co.', 'ma-roofing-hoyt-merrimac', 'roofing', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Merrimac Roofing Solutions', 'ma-roofing-merrimac-solutions', 'roofing', NULL, ARRAY['Merrimac','MA','Essex'], NULL),

    -- Methuen
    ('Methuen Roofing', 'ma-roofing-methuen-roofing', 'roofing', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Donovan Roofing & Siding', 'ma-roofing-donovan-methuen', 'roofing', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Methuen Roof Pros', 'ma-roofing-methuen-pros', 'roofing', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Hamel Roofing Co.', 'ma-roofing-hamel-methuen', 'roofing', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Methuen Roofing Solutions', 'ma-roofing-methuen-solutions', 'roofing', NULL, ARRAY['Methuen','MA','Essex'], NULL),

    -- Middleton
    ('Middleton Roofing', 'ma-roofing-middleton-roofing', 'roofing', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Fuller Roofing & Siding', 'ma-roofing-fuller-middleton', 'roofing', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Middleton Roof Pros', 'ma-roofing-middleton-pros', 'roofing', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Esty Roofing Co.', 'ma-roofing-esty-middleton', 'roofing', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Middleton Roofing Solutions', 'ma-roofing-middleton-solutions', 'roofing', NULL, ARRAY['Middleton','MA','Essex'], NULL),

    -- Nahant
    ('Nahant Roofing', 'ma-roofing-nahant-roofing', 'roofing', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Tudor Roofing & Siding', 'ma-roofing-tudor-nahant', 'roofing', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Nahant Roof Pros', 'ma-roofing-nahant-pros', 'roofing', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Hood Roofing Co.', 'ma-roofing-hood-nahant', 'roofing', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Nahant Roofing Solutions', 'ma-roofing-nahant-solutions', 'roofing', NULL, ARRAY['Nahant','MA','Essex'], NULL),

    -- Newbury
    ('Newbury Roofing', 'ma-roofing-newbury-roofing', 'roofing', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Noyes Roofing & Siding', 'ma-roofing-noyes-newbury', 'roofing', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Newbury Roof Pros', 'ma-roofing-newbury-pros', 'roofing', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Ilsley Roofing Co.', 'ma-roofing-ilsley-newbury', 'roofing', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Newbury Roofing Solutions', 'ma-roofing-newbury-solutions', 'roofing', NULL, ARRAY['Newbury','MA','Essex'], NULL),

    -- Newburyport
    ('Newburyport Roofing', 'ma-roofing-newburyport-roofing', 'roofing', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Coffin Roofing & Siding', 'ma-roofing-coffin-newburyport', 'roofing', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Newburyport Roof Pros', 'ma-roofing-newburyport-pros', 'roofing', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Cushing Roofing Co.', 'ma-roofing-cushing-newburyport', 'roofing', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Newburyport Roofing Solutions', 'ma-roofing-newburyport-solutions', 'roofing', NULL, ARRAY['Newburyport','MA','Essex'], NULL),

    -- North Andover
    ('North Andover Roofing', 'ma-roofing-north-andover-roofing', 'roofing', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Osgood Roofing & Siding', 'ma-roofing-osgood-north-andover', 'roofing', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('North Andover Roof Pros', 'ma-roofing-north-andover-pros', 'roofing', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Wetherbee Roofing Co.', 'ma-roofing-wetherbee-north-andover', 'roofing', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('North Andover Roofing Solutions', 'ma-roofing-north-andover-solutions', 'roofing', NULL, ARRAY['North Andover','MA','Essex'], NULL),

    -- Peabody
    ('Peabody Roofing', 'ma-roofing-peabody-roofing', 'roofing', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Osborne Roofing & Siding', 'ma-roofing-osborne-peabody', 'roofing', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Peabody Roof Pros', 'ma-roofing-peabody-pros', 'roofing', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Needham Roofing Co.', 'ma-roofing-needham-peabody', 'roofing', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Peabody Roofing Solutions', 'ma-roofing-peabody-solutions', 'roofing', NULL, ARRAY['Peabody','MA','Essex'], NULL),

    -- Rockport
    ('Rockport Roofing', 'ma-roofing-rockport-roofing', 'roofing', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Tarr Roofing & Siding', 'ma-roofing-tarr-rockport', 'roofing', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Rockport Roof Pros', 'ma-roofing-rockport-pros', 'roofing', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Parsons Roofing Co.', 'ma-roofing-parsons-rockport', 'roofing', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Rockport Roofing Solutions', 'ma-roofing-rockport-solutions', 'roofing', NULL, ARRAY['Rockport','MA','Essex'], NULL),

    -- Rowley
    ('Rowley Roofing', 'ma-roofing-rowley-roofing', 'roofing', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Gage Roofing & Siding', 'ma-roofing-gage-rowley', 'roofing', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Rowley Roof Pros', 'ma-roofing-rowley-pros', 'roofing', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Bradstreet Roofing Co.', 'ma-roofing-bradstreet-rowley', 'roofing', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Rowley Roofing Solutions', 'ma-roofing-rowley-solutions', 'roofing', NULL, ARRAY['Rowley','MA','Essex'], NULL),

    -- Salem
    ('Salem Roofing', 'ma-roofing-salem-roofing', 'roofing', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Hawthorne Roofing & Siding', 'ma-roofing-hawthorne-salem', 'roofing', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Salem Roof Pros', 'ma-roofing-salem-pros', 'roofing', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Derby Roofing Co.', 'ma-roofing-derby-salem', 'roofing', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Salem Roofing Solutions', 'ma-roofing-salem-solutions', 'roofing', NULL, ARRAY['Salem','MA','Essex'], NULL),

    -- Salisbury
    ('Salisbury Roofing', 'ma-roofing-salisbury-roofing', 'roofing', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Pettingell Roofing & Siding', 'ma-roofing-pettingell-salisbury', 'roofing', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Salisbury Roof Pros', 'ma-roofing-salisbury-pros', 'roofing', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('French Roofing Co.', 'ma-roofing-french-salisbury', 'roofing', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Salisbury Roofing Solutions', 'ma-roofing-salisbury-solutions', 'roofing', NULL, ARRAY['Salisbury','MA','Essex'], NULL),

    -- Saugus
    ('Saugus Roofing', 'ma-roofing-saugus-roofing', 'roofing', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Penny Roofing & Siding', 'ma-roofing-penny-saugus', 'roofing', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Saugus Roof Pros', 'ma-roofing-saugus-pros', 'roofing', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Boardman Roofing Co.', 'ma-roofing-boardman-saugus', 'roofing', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Saugus Roofing Solutions', 'ma-roofing-saugus-solutions', 'roofing', NULL, ARRAY['Saugus','MA','Essex'], NULL),

    -- Swampscott
    ('Swampscott Roofing', 'ma-roofing-swampscott-roofing', 'roofing', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Blaney Roofing & Siding', 'ma-roofing-blaney-swampscott', 'roofing', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Swampscott Roof Pros', 'ma-roofing-swampscott-pros', 'roofing', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Ingalls Roofing Co.', 'ma-roofing-ingalls-swampscott', 'roofing', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Swampscott Roofing Solutions', 'ma-roofing-swampscott-solutions', 'roofing', NULL, ARRAY['Swampscott','MA','Essex'], NULL),

    -- Topsfield
    ('Topsfield Roofing', 'ma-roofing-topsfield-roofing', 'roofing', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Cummings Roofing & Siding', 'ma-roofing-cummings-topsfield', 'roofing', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Topsfield Roof Pros', 'ma-roofing-topsfield-pros', 'roofing', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Towne Roofing Co.', 'ma-roofing-towne-topsfield', 'roofing', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Topsfield Roofing Solutions', 'ma-roofing-topsfield-solutions', 'roofing', NULL, ARRAY['Topsfield','MA','Essex'], NULL),

    -- Wenham
    ('Wenham Roofing', 'ma-roofing-wenham-roofing', 'roofing', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Fiske Roofing & Siding', 'ma-roofing-fiske-wenham', 'roofing', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Wenham Roof Pros', 'ma-roofing-wenham-pros', 'roofing', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Porter Roofing Co.', 'ma-roofing-porter-wenham', 'roofing', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Wenham Roofing Solutions', 'ma-roofing-wenham-solutions', 'roofing', NULL, ARRAY['Wenham','MA','Essex'], NULL),

    -- West Newbury
    ('West Newbury Roofing', 'ma-roofing-west-newbury-roofing', 'roofing', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('Chase Roofing & Siding', 'ma-roofing-chase-west-newbury', 'roofing', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('West Newbury Roof Pros', 'ma-roofing-west-newbury-pros', 'roofing', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('Emery Roofing Co.', 'ma-roofing-emery-west-newbury', 'roofing', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('West Newbury Roofing Solutions', 'ma-roofing-west-newbury-solutions', 'roofing', NULL, ARRAY['West Newbury','MA','Essex'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 8: MIDDLESEX COUNTY LOCAL ROOFING (54 towns x 5)
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Acton
    ('Acton Roofing', 'ma-roofing-acton-roofing', 'roofing', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Wheeler Roofing & Siding', 'ma-roofing-wheeler-acton', 'roofing', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Acton Roof Pros', 'ma-roofing-acton-pros', 'roofing', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Robbins Roofing Co.', 'ma-roofing-robbins-acton', 'roofing', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Acton Roofing Solutions', 'ma-roofing-acton-solutions', 'roofing', NULL, ARRAY['Acton','MA','Middlesex'], NULL),

    -- Arlington
    ('Arlington Roofing', 'ma-roofing-arlington-roofing', 'roofing', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Peirce Roofing & Siding', 'ma-roofing-peirce-arlington', 'roofing', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Arlington Roof Pros', 'ma-roofing-arlington-pros', 'roofing', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Russell Roofing Co.', 'ma-roofing-russell-arlington', 'roofing', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Arlington Roofing Solutions', 'ma-roofing-arlington-solutions', 'roofing', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),

    -- Ashby
    ('Ashby Roofing', 'ma-roofing-ashby-roofing', 'roofing', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Willard Roofing & Siding', 'ma-roofing-willard-ashby', 'roofing', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Ashby Roof Pros', 'ma-roofing-ashby-pros', 'roofing', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Foster Roofing Co.', 'ma-roofing-foster-ashby', 'roofing', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Ashby Roofing Solutions', 'ma-roofing-ashby-solutions', 'roofing', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),

    -- Ashland
    ('Ashland Roofing', 'ma-roofing-ashland-roofing', 'roofing', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Metcalf Roofing & Siding', 'ma-roofing-metcalf-ashland', 'roofing', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Ashland Roof Pros', 'ma-roofing-ashland-pros', 'roofing', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Warren Roofing Co.', 'ma-roofing-warren-ashland', 'roofing', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Ashland Roofing Solutions', 'ma-roofing-ashland-solutions', 'roofing', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),

    -- Ayer
    ('Ayer Roofing', 'ma-roofing-ayer-roofing', 'roofing', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Sanderson Roofing & Siding', 'ma-roofing-sanderson-ayer', 'roofing', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Ayer Roof Pros', 'ma-roofing-ayer-pros', 'roofing', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Page Roofing Co.', 'ma-roofing-page-ayer', 'roofing', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Ayer Roofing Solutions', 'ma-roofing-ayer-solutions', 'roofing', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),

    -- Bedford
    ('Bedford Roofing', 'ma-roofing-bedford-roofing', 'roofing', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Fitch Roofing & Siding', 'ma-roofing-fitch-bedford', 'roofing', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Bedford Roof Pros', 'ma-roofing-bedford-pros', 'roofing', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Lane Roofing Co.', 'ma-roofing-lane-bedford', 'roofing', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Bedford Roofing Solutions', 'ma-roofing-bedford-solutions', 'roofing', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),

    -- Belmont
    ('Belmont Roofing', 'ma-roofing-belmont-roofing', 'roofing', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Underwood Roofing & Siding', 'ma-roofing-underwood-belmont', 'roofing', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Belmont Roof Pros', 'ma-roofing-belmont-pros', 'roofing', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Locke Roofing Co.', 'ma-roofing-locke-belmont', 'roofing', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Belmont Roofing Solutions', 'ma-roofing-belmont-solutions', 'roofing', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),

    -- Billerica
    ('Billerica Roofing', 'ma-roofing-billerica-roofing', 'roofing', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Manning Roofing & Siding', 'ma-roofing-manning-billerica', 'roofing', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Billerica Roof Pros', 'ma-roofing-billerica-pros', 'roofing', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Jaquith Roofing Co.', 'ma-roofing-jaquith-billerica', 'roofing', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Billerica Roofing Solutions', 'ma-roofing-billerica-solutions', 'roofing', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),

    -- Boxborough
    ('Boxborough Roofing', 'ma-roofing-boxborough-roofing', 'roofing', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Whitcomb Roofing & Siding', 'ma-roofing-whitcomb-boxborough', 'roofing', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Boxborough Roof Pros', 'ma-roofing-boxborough-pros', 'roofing', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Blanchard Roofing Co.', 'ma-roofing-blanchard-boxborough', 'roofing', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Boxborough Roofing Solutions', 'ma-roofing-boxborough-solutions', 'roofing', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),

    -- Burlington
    ('Burlington Roofing', 'ma-roofing-burlington-roofing', 'roofing', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Winn Roofing & Siding', 'ma-roofing-winn-burlington', 'roofing', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Burlington Roof Pros', 'ma-roofing-burlington-pros', 'roofing', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Reed Roofing Co.', 'ma-roofing-reed-burlington', 'roofing', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Burlington Roofing Solutions', 'ma-roofing-burlington-solutions', 'roofing', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),

    -- Cambridge
    ('Cambridge Roofing', 'ma-roofing-cambridge-roofing', 'roofing', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Hastings Roofing & Siding', 'ma-roofing-hastings-cambridge', 'roofing', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Cambridge Roof Pros', 'ma-roofing-cambridge-pros', 'roofing', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Brattle Roofing Co.', 'ma-roofing-brattle-cambridge', 'roofing', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Cambridge Roofing Solutions', 'ma-roofing-cambridge-solutions', 'roofing', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),

    -- Carlisle
    ('Carlisle Roofing', 'ma-roofing-carlisle-roofing', 'roofing', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Heald Roofing & Siding', 'ma-roofing-heald-carlisle', 'roofing', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Carlisle Roof Pros', 'ma-roofing-carlisle-pros', 'roofing', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Green Roofing Co.', 'ma-roofing-green-carlisle', 'roofing', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Carlisle Roofing Solutions', 'ma-roofing-carlisle-solutions', 'roofing', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),

    -- Chelmsford
    ('Chelmsford Roofing', 'ma-roofing-chelmsford-roofing', 'roofing', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Parkhurst Roofing & Siding', 'ma-roofing-parkhurst-chelmsford', 'roofing', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Chelmsford Roof Pros', 'ma-roofing-chelmsford-pros', 'roofing', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Adams Roofing Co.', 'ma-roofing-adams-chelmsford', 'roofing', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Chelmsford Roofing Solutions', 'ma-roofing-chelmsford-solutions', 'roofing', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),

    -- Concord
    ('Concord Roofing', 'ma-roofing-concord-roofing', 'roofing', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Emerson Roofing & Siding', 'ma-roofing-emerson-concord', 'roofing', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Concord Roof Pros', 'ma-roofing-concord-pros', 'roofing', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Barrett Roofing Co.', 'ma-roofing-barrett-concord', 'roofing', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Concord Roofing Solutions', 'ma-roofing-concord-solutions', 'roofing', NULL, ARRAY['Concord','MA','Middlesex'], NULL),

    -- Dracut
    ('Dracut Roofing', 'ma-roofing-dracut-roofing', 'roofing', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Colburn Roofing & Siding', 'ma-roofing-colburn-dracut', 'roofing', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Dracut Roof Pros', 'ma-roofing-dracut-pros', 'roofing', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Varnum Roofing Co.', 'ma-roofing-varnum-dracut', 'roofing', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Dracut Roofing Solutions', 'ma-roofing-dracut-solutions', 'roofing', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),

    -- Dunstable
    ('Dunstable Roofing', 'ma-roofing-dunstable-roofing', 'roofing', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Swallow Roofing & Siding', 'ma-roofing-swallow-dunstable', 'roofing', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Dunstable Roof Pros', 'ma-roofing-dunstable-pros', 'roofing', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('French Roofing Co.', 'ma-roofing-french-dunstable', 'roofing', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Dunstable Roofing Solutions', 'ma-roofing-dunstable-solutions', 'roofing', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),

    -- Everett
    ('Everett Roofing', 'ma-roofing-everett-roofing', 'roofing', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Parlin Roofing & Siding', 'ma-roofing-parlin-everett', 'roofing', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Everett Roof Pros', 'ma-roofing-everett-pros', 'roofing', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Woodward Roofing Co.', 'ma-roofing-woodward-everett', 'roofing', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Everett Roofing Solutions', 'ma-roofing-everett-solutions', 'roofing', NULL, ARRAY['Everett','MA','Middlesex'], NULL),

    -- Framingham
    ('Framingham Roofing', 'ma-roofing-framingham-roofing', 'roofing', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Eames Roofing & Siding', 'ma-roofing-eames-framingham', 'roofing', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Framingham Roof Pros', 'ma-roofing-framingham-pros', 'roofing', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Danforth Roofing Co.', 'ma-roofing-danforth-framingham', 'roofing', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Framingham Roofing Solutions', 'ma-roofing-framingham-solutions', 'roofing', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),

    -- Groton
    ('Groton Roofing', 'ma-roofing-groton-roofing', 'roofing', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Lawrence Roofing & Siding', 'ma-roofing-lawrence-groton', 'roofing', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Groton Roof Pros', 'ma-roofing-groton-pros', 'roofing', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Prescott Roofing Co.', 'ma-roofing-prescott-groton', 'roofing', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Groton Roofing Solutions', 'ma-roofing-groton-solutions', 'roofing', NULL, ARRAY['Groton','MA','Middlesex'], NULL),

    -- Holliston
    ('Holliston Roofing', 'ma-roofing-holliston-roofing', 'roofing', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Phipps Roofing & Siding', 'ma-roofing-phipps-holliston', 'roofing', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Holliston Roof Pros', 'ma-roofing-holliston-pros', 'roofing', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Cutler Roofing Co.', 'ma-roofing-cutler-holliston', 'roofing', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Holliston Roofing Solutions', 'ma-roofing-holliston-solutions', 'roofing', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),

    -- Hopkinton
    ('Hopkinton Roofing', 'ma-roofing-hopkinton-roofing', 'roofing', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Claflin Roofing & Siding', 'ma-roofing-claflin-hopkinton', 'roofing', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Hopkinton Roof Pros', 'ma-roofing-hopkinton-pros', 'roofing', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Hayden Roofing Co.', 'ma-roofing-hayden-hopkinton', 'roofing', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Hopkinton Roofing Solutions', 'ma-roofing-hopkinton-solutions', 'roofing', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),

    -- Hudson
    ('Hudson Roofing', 'ma-roofing-hudson-roofing', 'roofing', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Brigham Roofing & Siding', 'ma-roofing-brigham-hudson', 'roofing', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Hudson Roof Pros', 'ma-roofing-hudson-pros', 'roofing', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Goodale Roofing Co.', 'ma-roofing-goodale-hudson', 'roofing', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Hudson Roofing Solutions', 'ma-roofing-hudson-solutions', 'roofing', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),

    -- Lexington
    ('Lexington Roofing', 'ma-roofing-lexington-roofing', 'roofing', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Hancock Roofing & Siding', 'ma-roofing-hancock-lexington', 'roofing', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Lexington Roof Pros', 'ma-roofing-lexington-pros', 'roofing', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Munroe Roofing Co.', 'ma-roofing-munroe-lexington', 'roofing', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Lexington Roofing Solutions', 'ma-roofing-lexington-solutions', 'roofing', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),

    -- Lincoln
    ('Lincoln Roofing', 'ma-roofing-lincoln-roofing', 'roofing', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Codman Roofing & Siding', 'ma-roofing-codman-lincoln', 'roofing', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Lincoln Roof Pros', 'ma-roofing-lincoln-pros', 'roofing', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Flint Roofing Co.', 'ma-roofing-flint-lincoln', 'roofing', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Lincoln Roofing Solutions', 'ma-roofing-lincoln-solutions', 'roofing', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),

    -- Littleton
    ('Littleton Roofing', 'ma-roofing-littleton-roofing', 'roofing', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Hartwell Roofing & Siding', 'ma-roofing-hartwell-littleton', 'roofing', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Littleton Roof Pros', 'ma-roofing-littleton-pros', 'roofing', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Kimball Roofing Co.', 'ma-roofing-kimball-littleton', 'roofing', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Littleton Roofing Solutions', 'ma-roofing-littleton-solutions', 'roofing', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),

    -- Lowell
    ('Lowell Roofing', 'ma-roofing-lowell-roofing', 'roofing', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Merrimack Roofing & Siding', 'ma-roofing-merrimack-lowell', 'roofing', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Lowell Roof Pros', 'ma-roofing-lowell-pros', 'roofing', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Hurd Roofing Co.', 'ma-roofing-hurd-lowell', 'roofing', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Lowell Roofing Solutions', 'ma-roofing-lowell-solutions', 'roofing', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),

    -- Malden
    ('Malden Roofing', 'ma-roofing-malden-roofing', 'roofing', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Corey Roofing & Siding', 'ma-roofing-corey-malden', 'roofing', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Malden Roof Pros', 'ma-roofing-malden-pros', 'roofing', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Converse Roofing Co.', 'ma-roofing-converse-malden', 'roofing', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Malden Roofing Solutions', 'ma-roofing-malden-solutions', 'roofing', NULL, ARRAY['Malden','MA','Middlesex'], NULL),

    -- Marlborough
    ('Marlborough Roofing', 'ma-roofing-marlborough-roofing', 'roofing', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Howe Roofing & Siding', 'ma-roofing-howe-marlborough', 'roofing', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Marlborough Roof Pros', 'ma-roofing-marlborough-pros', 'roofing', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Rice Roofing Co.', 'ma-roofing-rice-marlborough', 'roofing', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Marlborough Roofing Solutions', 'ma-roofing-marlborough-solutions', 'roofing', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),

    -- Maynard
    ('Maynard Roofing', 'ma-roofing-maynard-roofing', 'roofing', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Nason Roofing & Siding', 'ma-roofing-nason-maynard', 'roofing', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Maynard Roof Pros', 'ma-roofing-maynard-pros', 'roofing', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Fowler Roofing Co.', 'ma-roofing-fowler-maynard', 'roofing', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Maynard Roofing Solutions', 'ma-roofing-maynard-solutions', 'roofing', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),

    -- Medford
    ('Medford Roofing', 'ma-roofing-medford-roofing', 'roofing', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Tufts Roofing & Siding', 'ma-roofing-tufts-medford', 'roofing', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Medford Roof Pros', 'ma-roofing-medford-pros', 'roofing', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Brooks Roofing Co.', 'ma-roofing-brooks-medford', 'roofing', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Medford Roofing Solutions', 'ma-roofing-medford-solutions', 'roofing', NULL, ARRAY['Medford','MA','Middlesex'], NULL),

    -- Melrose
    ('Melrose Roofing', 'ma-roofing-melrose-roofing', 'roofing', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Upham Roofing & Siding', 'ma-roofing-upham-melrose', 'roofing', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Melrose Roof Pros', 'ma-roofing-melrose-pros', 'roofing', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Lynde Roofing Co.', 'ma-roofing-lynde-melrose', 'roofing', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Melrose Roofing Solutions', 'ma-roofing-melrose-solutions', 'roofing', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),

    -- Natick
    ('Natick Roofing', 'ma-roofing-natick-roofing', 'roofing', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Morse Roofing & Siding', 'ma-roofing-morse-natick', 'roofing', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Natick Roof Pros', 'ma-roofing-natick-pros', 'roofing', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Walcott Roofing Co.', 'ma-roofing-walcott-natick', 'roofing', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Natick Roofing Solutions', 'ma-roofing-natick-solutions', 'roofing', NULL, ARRAY['Natick','MA','Middlesex'], NULL),

    -- Newton
    ('Newton Roofing', 'ma-roofing-newton-roofing', 'roofing', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Elliot Roofing & Siding', 'ma-roofing-elliot-newton', 'roofing', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Newton Roof Pros', 'ma-roofing-newton-pros', 'roofing', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Jackson Roofing Co.', 'ma-roofing-jackson-newton', 'roofing', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Newton Roofing Solutions', 'ma-roofing-newton-solutions', 'roofing', NULL, ARRAY['Newton','MA','Middlesex'], NULL),

    -- North Reading
    ('North Reading Roofing', 'ma-roofing-north-reading-roofing', 'roofing', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('Flint Roofing & Siding', 'ma-roofing-flint-north-reading', 'roofing', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('North Reading Roof Pros', 'ma-roofing-north-reading-pros', 'roofing', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('Damon Roofing Co.', 'ma-roofing-damon-north-reading', 'roofing', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('North Reading Roofing Solutions', 'ma-roofing-north-reading-solutions', 'roofing', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),

    -- Pepperell
    ('Pepperell Roofing', 'ma-roofing-pepperell-roofing', 'roofing', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Shattuck Roofing & Siding', 'ma-roofing-shattuck-pepperell', 'roofing', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Pepperell Roof Pros', 'ma-roofing-pepperell-pros', 'roofing', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Jewett Roofing Co.', 'ma-roofing-jewett-pepperell', 'roofing', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Pepperell Roofing Solutions', 'ma-roofing-pepperell-solutions', 'roofing', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),

    -- Reading
    ('Reading Roofing', 'ma-roofing-reading-roofing', 'roofing', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Parker Roofing & Siding', 'ma-roofing-parker-reading', 'roofing', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Reading Roof Pros', 'ma-roofing-reading-pros', 'roofing', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Bancroft Roofing Co.', 'ma-roofing-bancroft-reading', 'roofing', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Reading Roofing Solutions', 'ma-roofing-reading-solutions', 'roofing', NULL, ARRAY['Reading','MA','Middlesex'], NULL),

    -- Sherborn
    ('Sherborn Roofing', 'ma-roofing-sherborn-roofing', 'roofing', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Dowse Roofing & Siding', 'ma-roofing-dowse-sherborn', 'roofing', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Sherborn Roof Pros', 'ma-roofing-sherborn-pros', 'roofing', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Holbrook Roofing Co.', 'ma-roofing-holbrook-sherborn', 'roofing', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Sherborn Roofing Solutions', 'ma-roofing-sherborn-solutions', 'roofing', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),

    -- Shirley
    ('Shirley Roofing', 'ma-roofing-shirley-roofing', 'roofing', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Longley Roofing & Siding', 'ma-roofing-longley-shirley', 'roofing', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Shirley Roof Pros', 'ma-roofing-shirley-pros', 'roofing', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Hazen Roofing Co.', 'ma-roofing-hazen-shirley', 'roofing', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Shirley Roofing Solutions', 'ma-roofing-shirley-solutions', 'roofing', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),

    -- Somerville
    ('Somerville Roofing', 'ma-roofing-somerville-roofing', 'roofing', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Teel Roofing & Siding', 'ma-roofing-teel-somerville', 'roofing', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Somerville Roof Pros', 'ma-roofing-somerville-pros', 'roofing', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Dane Roofing Co.', 'ma-roofing-dane-somerville', 'roofing', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Somerville Roofing Solutions', 'ma-roofing-somerville-solutions', 'roofing', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),

    -- Stoneham
    ('Stoneham Roofing', 'ma-roofing-stoneham-roofing', 'roofing', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Vinton Roofing & Siding', 'ma-roofing-vinton-stoneham', 'roofing', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Stoneham Roof Pros', 'ma-roofing-stoneham-pros', 'roofing', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Gould Roofing Co.', 'ma-roofing-gould-stoneham', 'roofing', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Stoneham Roofing Solutions', 'ma-roofing-stoneham-solutions', 'roofing', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),

    -- Stow
    ('Stow Roofing', 'ma-roofing-stow-roofing', 'roofing', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Randall Roofing & Siding', 'ma-roofing-randall-stow', 'roofing', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Stow Roof Pros', 'ma-roofing-stow-pros', 'roofing', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Gates Roofing Co.', 'ma-roofing-gates-stow', 'roofing', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Stow Roofing Solutions', 'ma-roofing-stow-solutions', 'roofing', NULL, ARRAY['Stow','MA','Middlesex'], NULL),

    -- Sudbury
    ('Sudbury Roofing', 'ma-roofing-sudbury-roofing', 'roofing', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Goodnow Roofing & Siding', 'ma-roofing-goodnow-sudbury', 'roofing', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Sudbury Roof Pros', 'ma-roofing-sudbury-pros', 'roofing', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Haynes Roofing Co.', 'ma-roofing-haynes-sudbury', 'roofing', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Sudbury Roofing Solutions', 'ma-roofing-sudbury-solutions', 'roofing', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),

    -- Tewksbury
    ('Tewksbury Roofing', 'ma-roofing-tewksbury-roofing', 'roofing', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Trull Roofing & Siding', 'ma-roofing-trull-tewksbury', 'roofing', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Tewksbury Roof Pros', 'ma-roofing-tewksbury-pros', 'roofing', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Livingston Roofing Co.', 'ma-roofing-livingston-tewksbury', 'roofing', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Tewksbury Roofing Solutions', 'ma-roofing-tewksbury-solutions', 'roofing', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),

    -- Townsend
    ('Townsend Roofing', 'ma-roofing-townsend-roofing', 'roofing', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Spaulding Roofing & Siding', 'ma-roofing-spaulding-townsend', 'roofing', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Townsend Roof Pros', 'ma-roofing-townsend-pros', 'roofing', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Conant Roofing Co.', 'ma-roofing-conant-townsend', 'roofing', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Townsend Roofing Solutions', 'ma-roofing-townsend-solutions', 'roofing', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),

    -- Tyngsborough
    ('Tyngsborough Roofing', 'ma-roofing-tyngsborough-roofing', 'roofing', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Winslow Roofing & Siding', 'ma-roofing-winslow-tyngsborough', 'roofing', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Tyngsborough Roof Pros', 'ma-roofing-tyngsborough-pros', 'roofing', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Butterfield Roofing Co.', 'ma-roofing-butterfield-tyngsborough', 'roofing', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Tyngsborough Roofing Solutions', 'ma-roofing-tyngsborough-solutions', 'roofing', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),

    -- Wakefield
    ('Wakefield Roofing', 'ma-roofing-wakefield-roofing', 'roofing', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Sweetser Roofing & Siding', 'ma-roofing-sweetser-wakefield', 'roofing', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Wakefield Roof Pros', 'ma-roofing-wakefield-pros', 'roofing', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Hartshorne Roofing Co.', 'ma-roofing-hartshorne-wakefield', 'roofing', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Wakefield Roofing Solutions', 'ma-roofing-wakefield-solutions', 'roofing', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),

    -- Waltham
    ('Waltham Roofing', 'ma-roofing-waltham-roofing', 'roofing', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Lyman Roofing & Siding', 'ma-roofing-lyman-waltham', 'roofing', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Waltham Roof Pros', 'ma-roofing-waltham-pros', 'roofing', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Phelps Roofing Co.', 'ma-roofing-phelps-waltham', 'roofing', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Waltham Roofing Solutions', 'ma-roofing-waltham-solutions', 'roofing', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),

    -- Watertown
    ('Watertown Roofing', 'ma-roofing-watertown-roofing', 'roofing', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Coolidge Roofing & Siding', 'ma-roofing-coolidge-watertown', 'roofing', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Watertown Roof Pros', 'ma-roofing-watertown-pros', 'roofing', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Whitney Roofing Co.', 'ma-roofing-whitney-watertown', 'roofing', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Watertown Roofing Solutions', 'ma-roofing-watertown-solutions', 'roofing', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),

    -- Wayland
    ('Wayland Roofing', 'ma-roofing-wayland-roofing', 'roofing', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Dudley Roofing & Siding', 'ma-roofing-dudley-wayland', 'roofing', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Wayland Roof Pros', 'ma-roofing-wayland-pros', 'roofing', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Draper Roofing Co.', 'ma-roofing-draper-wayland', 'roofing', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Wayland Roofing Solutions', 'ma-roofing-wayland-solutions', 'roofing', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),

    -- Westford
    ('Westford Roofing', 'ma-roofing-westford-roofing', 'roofing', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Hildreth Roofing & Siding', 'ma-roofing-hildreth-westford', 'roofing', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Westford Roof Pros', 'ma-roofing-westford-pros', 'roofing', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Fletcher Roofing Co.', 'ma-roofing-fletcher-westford', 'roofing', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Westford Roofing Solutions', 'ma-roofing-westford-solutions', 'roofing', NULL, ARRAY['Westford','MA','Middlesex'], NULL),

    -- Weston
    ('Weston Roofing', 'ma-roofing-weston-roofing', 'roofing', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Bigelow Roofing & Siding', 'ma-roofing-bigelow-weston', 'roofing', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Weston Roof Pros', 'ma-roofing-weston-pros', 'roofing', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Coburn Roofing Co.', 'ma-roofing-coburn-weston', 'roofing', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Weston Roofing Solutions', 'ma-roofing-weston-solutions', 'roofing', NULL, ARRAY['Weston','MA','Middlesex'], NULL),

    -- Wilmington
    ('Wilmington Roofing', 'ma-roofing-wilmington-roofing', 'roofing', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Harnden Roofing & Siding', 'ma-roofing-harnden-wilmington', 'roofing', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Wilmington Roof Pros', 'ma-roofing-wilmington-pros', 'roofing', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Jaquith Roofing Co.', 'ma-roofing-jaquith-wilmington', 'roofing', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Wilmington Roofing Solutions', 'ma-roofing-wilmington-solutions', 'roofing', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),

    -- Winchester
    ('Winchester Roofing', 'ma-roofing-winchester-roofing', 'roofing', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Symmes Roofing & Siding', 'ma-roofing-symmes-winchester', 'roofing', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Winchester Roof Pros', 'ma-roofing-winchester-pros', 'roofing', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Richardson Roofing Co.', 'ma-roofing-richardson-winchester', 'roofing', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Winchester Roofing Solutions', 'ma-roofing-winchester-solutions', 'roofing', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),

    -- Woburn
    ('Woburn Roofing', 'ma-roofing-woburn-roofing', 'roofing', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Thompson Roofing & Siding', 'ma-roofing-thompson-woburn', 'roofing', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Woburn Roof Pros', 'ma-roofing-woburn-pros', 'roofing', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Tidd Roofing Co.', 'ma-roofing-tidd-woburn', 'roofing', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Woburn Roofing Solutions', 'ma-roofing-woburn-solutions', 'roofing', NULL, ARRAY['Woburn','MA','Middlesex'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 9: NORFOLK COUNTY LOCAL ROOFING (27 towns x 5)
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Avon
    ('Avon Roofing', 'ma-roofing-avon-roofing', 'roofing', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Littlefield Roofing & Siding', 'ma-roofing-littlefield-avon', 'roofing', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Avon Roof Pros', 'ma-roofing-avon-pros', 'roofing', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Copeland Roofing Co.', 'ma-roofing-copeland-avon', 'roofing', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Avon Roofing Solutions', 'ma-roofing-avon-solutions', 'roofing', NULL, ARRAY['Avon','MA','Norfolk'], NULL),

    -- Braintree
    ('Braintree Roofing', 'ma-roofing-braintree-roofing', 'roofing', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Thayer Roofing & Siding', 'ma-roofing-thayer-braintree', 'roofing', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Braintree Roof Pros', 'ma-roofing-braintree-pros', 'roofing', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Hollis Roofing Co.', 'ma-roofing-hollis-braintree', 'roofing', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Braintree Roofing Solutions', 'ma-roofing-braintree-solutions', 'roofing', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),

    -- Brookline
    ('Brookline Roofing', 'ma-roofing-brookline-roofing', 'roofing', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Aspinwall Roofing & Siding', 'ma-roofing-aspinwall-brookline', 'roofing', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Brookline Roof Pros', 'ma-roofing-brookline-pros', 'roofing', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Devotion Roofing Co.', 'ma-roofing-devotion-brookline', 'roofing', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Brookline Roofing Solutions', 'ma-roofing-brookline-solutions', 'roofing', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),

    -- Canton
    ('Canton Roofing', 'ma-roofing-canton-roofing', 'roofing', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Revere Roofing & Siding', 'ma-roofing-revere-canton', 'roofing', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Canton Roof Pros', 'ma-roofing-canton-pros', 'roofing', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Tilden Roofing Co.', 'ma-roofing-tilden-canton', 'roofing', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Canton Roofing Solutions', 'ma-roofing-canton-solutions', 'roofing', NULL, ARRAY['Canton','MA','Norfolk'], NULL),

    -- Cohasset
    ('Cohasset Roofing', 'ma-roofing-cohasset-roofing', 'roofing', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Bates Roofing & Siding', 'ma-roofing-bates-cohasset', 'roofing', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Cohasset Roof Pros', 'ma-roofing-cohasset-pros', 'roofing', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Pratt Roofing Co.', 'ma-roofing-pratt-cohasset', 'roofing', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Cohasset Roofing Solutions', 'ma-roofing-cohasset-solutions', 'roofing', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),

    -- Dedham
    ('Dedham Roofing', 'ma-roofing-dedham-roofing', 'roofing', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Fairbanks Roofing & Siding', 'ma-roofing-fairbanks-dedham', 'roofing', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Dedham Roof Pros', 'ma-roofing-dedham-pros', 'roofing', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Colburn Roofing Co.', 'ma-roofing-colburn-dedham', 'roofing', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Dedham Roofing Solutions', 'ma-roofing-dedham-solutions', 'roofing', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),

    -- Dover
    ('Dover Roofing', 'ma-roofing-dover-roofing', 'roofing', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Sawin Roofing & Siding', 'ma-roofing-sawin-dover', 'roofing', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Dover Roof Pros', 'ma-roofing-dover-pros', 'roofing', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Mann Roofing Co.', 'ma-roofing-mann-dover', 'roofing', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Dover Roofing Solutions', 'ma-roofing-dover-solutions', 'roofing', NULL, ARRAY['Dover','MA','Norfolk'], NULL),

    -- Foxborough
    ('Foxborough Roofing', 'ma-roofing-foxborough-roofing', 'roofing', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Carpenter Roofing & Siding', 'ma-roofing-carpenter-foxborough', 'roofing', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Foxborough Roof Pros', 'ma-roofing-foxborough-pros', 'roofing', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Payson Roofing Co.', 'ma-roofing-payson-foxborough', 'roofing', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Foxborough Roofing Solutions', 'ma-roofing-foxborough-solutions', 'roofing', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),

    -- Franklin
    ('Franklin Roofing', 'ma-roofing-franklin-roofing', 'roofing', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Metcalf Roofing & Siding', 'ma-roofing-metcalf-franklin', 'roofing', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Franklin Roof Pros', 'ma-roofing-franklin-pros', 'roofing', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Ray Roofing Co.', 'ma-roofing-ray-franklin', 'roofing', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Franklin Roofing Solutions', 'ma-roofing-franklin-solutions', 'roofing', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),

    -- Holbrook
    ('Holbrook Roofing', 'ma-roofing-holbrook-roofing', 'roofing', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Niles Roofing & Siding', 'ma-roofing-niles-holbrook', 'roofing', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Holbrook Roof Pros', 'ma-roofing-holbrook-pros', 'roofing', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Thayer Roofing Co.', 'ma-roofing-thayer-holbrook', 'roofing', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Holbrook Roofing Solutions', 'ma-roofing-holbrook-solutions', 'roofing', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),

    -- Medfield
    ('Medfield Roofing', 'ma-roofing-medfield-roofing', 'roofing', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Chenery Roofing & Siding', 'ma-roofing-chenery-medfield', 'roofing', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Medfield Roof Pros', 'ma-roofing-medfield-pros', 'roofing', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Allen Roofing Co.', 'ma-roofing-allen-medfield', 'roofing', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Medfield Roofing Solutions', 'ma-roofing-medfield-solutions', 'roofing', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),

    -- Medway
    ('Medway Roofing', 'ma-roofing-medway-roofing', 'roofing', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Lovering Roofing & Siding', 'ma-roofing-lovering-medway', 'roofing', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Medway Roof Pros', 'ma-roofing-medway-pros', 'roofing', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Sanford Roofing Co.', 'ma-roofing-sanford-medway', 'roofing', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Medway Roofing Solutions', 'ma-roofing-medway-solutions', 'roofing', NULL, ARRAY['Medway','MA','Norfolk'], NULL),

    -- Millis
    ('Millis Roofing', 'ma-roofing-millis-roofing', 'roofing', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Richardson Roofing & Siding', 'ma-roofing-richardson-millis', 'roofing', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Millis Roof Pros', 'ma-roofing-millis-pros', 'roofing', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Daniels Roofing Co.', 'ma-roofing-daniels-millis', 'roofing', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Millis Roofing Solutions', 'ma-roofing-millis-solutions', 'roofing', NULL, ARRAY['Millis','MA','Norfolk'], NULL),

    -- Milton
    ('Milton Roofing', 'ma-roofing-milton-roofing', 'roofing', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Tucker Roofing & Siding', 'ma-roofing-tucker-milton', 'roofing', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Milton Roof Pros', 'ma-roofing-milton-pros', 'roofing', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Vose Roofing Co.', 'ma-roofing-vose-milton', 'roofing', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Milton Roofing Solutions', 'ma-roofing-milton-solutions', 'roofing', NULL, ARRAY['Milton','MA','Norfolk'], NULL),

    -- Needham
    ('Needham Roofing', 'ma-roofing-needham-roofing', 'roofing', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Kingsbury Roofing & Siding', 'ma-roofing-kingsbury-needham', 'roofing', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Needham Roof Pros', 'ma-roofing-needham-pros', 'roofing', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Eaton Roofing Co.', 'ma-roofing-eaton-needham', 'roofing', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Needham Roofing Solutions', 'ma-roofing-needham-solutions', 'roofing', NULL, ARRAY['Needham','MA','Norfolk'], NULL),

    -- Norfolk
    ('Norfolk Roofing', 'ma-roofing-norfolk-roofing', 'roofing', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Rockwood Roofing & Siding', 'ma-roofing-rockwood-norfolk', 'roofing', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Norfolk Roof Pros', 'ma-roofing-norfolk-pros', 'roofing', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Pond Roofing Co.', 'ma-roofing-pond-norfolk', 'roofing', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Norfolk Roofing Solutions', 'ma-roofing-norfolk-solutions', 'roofing', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),

    -- Norwood
    ('Norwood Roofing', 'ma-roofing-norwood-roofing', 'roofing', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Guild Roofing & Siding', 'ma-roofing-guild-norwood', 'roofing', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Norwood Roof Pros', 'ma-roofing-norwood-pros', 'roofing', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Plimpton Roofing Co.', 'ma-roofing-plimpton-norwood', 'roofing', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Norwood Roofing Solutions', 'ma-roofing-norwood-solutions', 'roofing', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),

    -- Plainville
    ('Plainville Roofing', 'ma-roofing-plainville-roofing', 'roofing', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Shepard Roofing & Siding', 'ma-roofing-shepard-plainville', 'roofing', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Plainville Roof Pros', 'ma-roofing-plainville-pros', 'roofing', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Fuller Roofing Co.', 'ma-roofing-fuller-plainville', 'roofing', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Plainville Roofing Solutions', 'ma-roofing-plainville-solutions', 'roofing', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),

    -- Quincy
    ('Quincy Roofing', 'ma-roofing-quincy-roofing', 'roofing', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Adams Roofing & Siding', 'ma-roofing-adams-quincy', 'roofing', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Quincy Roof Pros', 'ma-roofing-quincy-pros', 'roofing', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Crane Roofing Co.', 'ma-roofing-crane-quincy', 'roofing', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Quincy Roofing Solutions', 'ma-roofing-quincy-solutions', 'roofing', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),

    -- Randolph
    ('Randolph Roofing', 'ma-roofing-randolph-roofing', 'roofing', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Stetson Roofing & Siding', 'ma-roofing-stetson-randolph', 'roofing', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Randolph Roof Pros', 'ma-roofing-randolph-pros', 'roofing', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Wales Roofing Co.', 'ma-roofing-wales-randolph', 'roofing', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Randolph Roofing Solutions', 'ma-roofing-randolph-solutions', 'roofing', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),

    -- Sharon
    ('Sharon Roofing', 'ma-roofing-sharon-roofing', 'roofing', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Billings Roofing & Siding', 'ma-roofing-billings-sharon', 'roofing', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Sharon Roof Pros', 'ma-roofing-sharon-pros', 'roofing', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Johnson Roofing Co.', 'ma-roofing-johnson-sharon', 'roofing', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Sharon Roofing Solutions', 'ma-roofing-sharon-solutions', 'roofing', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),

    -- Stoughton
    ('Stoughton Roofing', 'ma-roofing-stoughton-roofing', 'roofing', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Clapp Roofing & Siding', 'ma-roofing-clapp-stoughton', 'roofing', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Stoughton Roof Pros', 'ma-roofing-stoughton-pros', 'roofing', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Drake Roofing Co.', 'ma-roofing-drake-stoughton', 'roofing', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Stoughton Roofing Solutions', 'ma-roofing-stoughton-solutions', 'roofing', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),

    -- Walpole
    ('Walpole Roofing', 'ma-roofing-walpole-roofing', 'roofing', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Bird Roofing & Siding', 'ma-roofing-bird-walpole', 'roofing', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Walpole Roof Pros', 'ma-roofing-walpole-pros', 'roofing', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Lewis Roofing Co.', 'ma-roofing-lewis-walpole', 'roofing', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Walpole Roofing Solutions', 'ma-roofing-walpole-solutions', 'roofing', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),

    -- Wellesley
    ('Wellesley Roofing', 'ma-roofing-wellesley-roofing', 'roofing', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Hunnewell Roofing & Siding', 'ma-roofing-hunnewell-wellesley', 'roofing', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Wellesley Roof Pros', 'ma-roofing-wellesley-pros', 'roofing', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Dewing Roofing Co.', 'ma-roofing-dewing-wellesley', 'roofing', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Wellesley Roofing Solutions', 'ma-roofing-wellesley-solutions', 'roofing', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),

    -- Westwood
    ('Westwood Roofing', 'ma-roofing-westwood-roofing', 'roofing', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Capen Roofing & Siding', 'ma-roofing-capen-westwood', 'roofing', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Westwood Roof Pros', 'ma-roofing-westwood-pros', 'roofing', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Fisher Roofing Co.', 'ma-roofing-fisher-westwood', 'roofing', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Westwood Roofing Solutions', 'ma-roofing-westwood-solutions', 'roofing', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),

    -- Weymouth
    ('Weymouth Roofing', 'ma-roofing-weymouth-roofing', 'roofing', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Torrey Roofing & Siding', 'ma-roofing-torrey-weymouth', 'roofing', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Weymouth Roof Pros', 'ma-roofing-weymouth-pros', 'roofing', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Loud Roofing Co.', 'ma-roofing-loud-weymouth', 'roofing', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Weymouth Roofing Solutions', 'ma-roofing-weymouth-solutions', 'roofing', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),

    -- Wrentham
    ('Wrentham Roofing', 'ma-roofing-wrentham-roofing', 'roofing', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Hawes Roofing & Siding', 'ma-roofing-hawes-wrentham', 'roofing', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Wrentham Roof Pros', 'ma-roofing-wrentham-pros', 'roofing', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Messenger Roofing Co.', 'ma-roofing-messenger-wrentham', 'roofing', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Wrentham Roofing Solutions', 'ma-roofing-wrentham-solutions', 'roofing', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 10: PLYMOUTH COUNTY LOCAL ROOFING (27 towns x 5)
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Abington
    ('Abington Roofing', 'ma-roofing-abington-roofing', 'roofing', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Nash Roofing & Siding', 'ma-roofing-nash-abington', 'roofing', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Abington Roof Pros', 'ma-roofing-abington-pros', 'roofing', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Reed Roofing Co.', 'ma-roofing-reed-abington', 'roofing', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Abington Roofing Solutions', 'ma-roofing-abington-solutions', 'roofing', NULL, ARRAY['Abington','MA','Plymouth'], NULL),

    -- Bridgewater
    ('Bridgewater Roofing', 'ma-roofing-bridgewater-roofing', 'roofing', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Washburn Roofing & Siding', 'ma-roofing-washburn-bridgewater', 'roofing', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Roof Pros', 'ma-roofing-bridgewater-pros', 'roofing', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Latham Roofing Co.', 'ma-roofing-latham-bridgewater', 'roofing', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Roofing Solutions', 'ma-roofing-bridgewater-solutions', 'roofing', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),

    -- Brockton
    ('Brockton Roofing', 'ma-roofing-brockton-roofing', 'roofing', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Howard Roofing & Siding', 'ma-roofing-howard-brockton', 'roofing', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Brockton Roof Pros', 'ma-roofing-brockton-pros', 'roofing', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Keith Roofing Co.', 'ma-roofing-keith-brockton', 'roofing', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Brockton Roofing Solutions', 'ma-roofing-brockton-solutions', 'roofing', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),

    -- Carver
    ('Carver Roofing', 'ma-roofing-carver-roofing', 'roofing', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Savery Roofing & Siding', 'ma-roofing-savery-carver', 'roofing', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Carver Roof Pros', 'ma-roofing-carver-pros', 'roofing', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Ward Roofing Co.', 'ma-roofing-ward-carver', 'roofing', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Carver Roofing Solutions', 'ma-roofing-carver-solutions', 'roofing', NULL, ARRAY['Carver','MA','Plymouth'], NULL),

    -- Duxbury
    ('Duxbury Roofing', 'ma-roofing-duxbury-roofing', 'roofing', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Alden Roofing & Siding', 'ma-roofing-alden-duxbury', 'roofing', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Duxbury Roof Pros', 'ma-roofing-duxbury-pros', 'roofing', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Standish Roofing Co.', 'ma-roofing-standish-duxbury', 'roofing', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Duxbury Roofing Solutions', 'ma-roofing-duxbury-solutions', 'roofing', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),

    -- East Bridgewater
    ('East Bridgewater Roofing', 'ma-roofing-east-bridgewater-roofing', 'roofing', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('Keith Roofing & Siding', 'ma-roofing-keith-east-bridgewater', 'roofing', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('East Bridgewater Roof Pros', 'ma-roofing-east-bridgewater-pros', 'roofing', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('Whitman Roofing Co.', 'ma-roofing-whitman-east-bridgewater', 'roofing', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('East Bridgewater Roofing Solutions', 'ma-roofing-east-bridgewater-solutions', 'roofing', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),

    -- Halifax
    ('Halifax Roofing', 'ma-roofing-halifax-roofing', 'roofing', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Thompson Roofing & Siding', 'ma-roofing-thompson-halifax', 'roofing', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Halifax Roof Pros', 'ma-roofing-halifax-pros', 'roofing', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Sturtevant Roofing Co.', 'ma-roofing-sturtevant-halifax', 'roofing', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Halifax Roofing Solutions', 'ma-roofing-halifax-solutions', 'roofing', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),

    -- Hanover
    ('Hanover Roofing', 'ma-roofing-hanover-roofing', 'roofing', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Stetson Roofing & Siding', 'ma-roofing-stetson-hanover', 'roofing', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Hanover Roof Pros', 'ma-roofing-hanover-pros', 'roofing', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Dwelly Roofing Co.', 'ma-roofing-dwelly-hanover', 'roofing', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Hanover Roofing Solutions', 'ma-roofing-hanover-solutions', 'roofing', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),

    -- Hanson
    ('Hanson Roofing', 'ma-roofing-hanson-roofing', 'roofing', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Phillips Roofing & Siding', 'ma-roofing-phillips-hanson', 'roofing', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Hanson Roof Pros', 'ma-roofing-hanson-pros', 'roofing', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Thomas Roofing Co.', 'ma-roofing-thomas-hanson', 'roofing', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Hanson Roofing Solutions', 'ma-roofing-hanson-solutions', 'roofing', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),

    -- Hingham
    ('Hingham Roofing', 'ma-roofing-hingham-roofing', 'roofing', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Lincoln Roofing & Siding', 'ma-roofing-lincoln-hingham', 'roofing', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Hingham Roof Pros', 'ma-roofing-hingham-pros', 'roofing', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Cushing Roofing Co.', 'ma-roofing-cushing-hingham', 'roofing', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Hingham Roofing Solutions', 'ma-roofing-hingham-solutions', 'roofing', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),

    -- Hull
    ('Hull Roofing', 'ma-roofing-hull-roofing', 'roofing', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Mitchell Roofing & Siding', 'ma-roofing-mitchell-hull', 'roofing', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Hull Roof Pros', 'ma-roofing-hull-pros', 'roofing', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Loring Roofing Co.', 'ma-roofing-loring-hull', 'roofing', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Hull Roofing Solutions', 'ma-roofing-hull-solutions', 'roofing', NULL, ARRAY['Hull','MA','Plymouth'], NULL),

    -- Kingston
    ('Kingston Roofing', 'ma-roofing-kingston-roofing', 'roofing', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Bradford Roofing & Siding', 'ma-roofing-bradford-kingston', 'roofing', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Kingston Roof Pros', 'ma-roofing-kingston-pros', 'roofing', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Holmes Roofing Co.', 'ma-roofing-holmes-kingston', 'roofing', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Kingston Roofing Solutions', 'ma-roofing-kingston-solutions', 'roofing', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),

    -- Lakeville
    ('Lakeville Roofing', 'ma-roofing-lakeville-roofing', 'roofing', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Pierce Roofing & Siding', 'ma-roofing-pierce-lakeville', 'roofing', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Lakeville Roof Pros', 'ma-roofing-lakeville-pros', 'roofing', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Haskins Roofing Co.', 'ma-roofing-haskins-lakeville', 'roofing', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Lakeville Roofing Solutions', 'ma-roofing-lakeville-solutions', 'roofing', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),

    -- Marion
    ('Marion Roofing', 'ma-roofing-marion-roofing', 'roofing', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Delano Roofing & Siding', 'ma-roofing-delano-marion', 'roofing', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Marion Roof Pros', 'ma-roofing-marion-pros', 'roofing', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Nye Roofing Co.', 'ma-roofing-nye-marion', 'roofing', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Marion Roofing Solutions', 'ma-roofing-marion-solutions', 'roofing', NULL, ARRAY['Marion','MA','Plymouth'], NULL),

    -- Marshfield
    ('Marshfield Roofing', 'ma-roofing-marshfield-roofing', 'roofing', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Hatch Roofing & Siding', 'ma-roofing-hatch-marshfield', 'roofing', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Marshfield Roof Pros', 'ma-roofing-marshfield-pros', 'roofing', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Tilden Roofing Co.', 'ma-roofing-tilden-marshfield', 'roofing', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Marshfield Roofing Solutions', 'ma-roofing-marshfield-solutions', 'roofing', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),

    -- Mattapoisett
    ('Mattapoisett Roofing', 'ma-roofing-mattapoisett-roofing', 'roofing', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Cannon Roofing & Siding', 'ma-roofing-cannon-mattapoisett', 'roofing', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Mattapoisett Roof Pros', 'ma-roofing-mattapoisett-pros', 'roofing', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Barstow Roofing Co.', 'ma-roofing-barstow-mattapoisett', 'roofing', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Mattapoisett Roofing Solutions', 'ma-roofing-mattapoisett-solutions', 'roofing', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),

    -- Middleborough
    ('Middleborough Roofing', 'ma-roofing-middleborough-roofing', 'roofing', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Soule Roofing & Siding', 'ma-roofing-soule-middleborough', 'roofing', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Middleborough Roof Pros', 'ma-roofing-middleborough-pros', 'roofing', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Wood Roofing Co.', 'ma-roofing-wood-middleborough', 'roofing', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Middleborough Roofing Solutions', 'ma-roofing-middleborough-solutions', 'roofing', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),

    -- Norwell
    ('Norwell Roofing', 'ma-roofing-norwell-roofing', 'roofing', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Jacobs Roofing & Siding', 'ma-roofing-jacobs-norwell', 'roofing', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Norwell Roof Pros', 'ma-roofing-norwell-pros', 'roofing', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Sparrell Roofing Co.', 'ma-roofing-sparrell-norwell', 'roofing', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Norwell Roofing Solutions', 'ma-roofing-norwell-solutions', 'roofing', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),

    -- Pembroke
    ('Pembroke Roofing', 'ma-roofing-pembroke-roofing', 'roofing', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Turner Roofing & Siding', 'ma-roofing-turner-pembroke', 'roofing', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Pembroke Roof Pros', 'ma-roofing-pembroke-pros', 'roofing', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Barker Roofing Co.', 'ma-roofing-barker-pembroke', 'roofing', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Pembroke Roofing Solutions', 'ma-roofing-pembroke-solutions', 'roofing', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),

    -- Plymouth
    ('Plymouth Roofing', 'ma-roofing-plymouth-roofing', 'roofing', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Brewster Roofing & Siding', 'ma-roofing-brewster-plymouth', 'roofing', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Plymouth Roof Pros', 'ma-roofing-plymouth-pros', 'roofing', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Howland Roofing Co.', 'ma-roofing-howland-plymouth', 'roofing', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Plymouth Roofing Solutions', 'ma-roofing-plymouth-solutions', 'roofing', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),

    -- Plympton
    ('Plympton Roofing', 'ma-roofing-plympton-roofing', 'roofing', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Soule Roofing & Siding', 'ma-roofing-soule-plympton', 'roofing', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Plympton Roof Pros', 'ma-roofing-plympton-pros', 'roofing', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Ring Roofing Co.', 'ma-roofing-ring-plympton', 'roofing', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Plympton Roofing Solutions', 'ma-roofing-plympton-solutions', 'roofing', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),

    -- Rochester
    ('Rochester Roofing', 'ma-roofing-rochester-roofing', 'roofing', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Leonard Roofing & Siding', 'ma-roofing-leonard-rochester', 'roofing', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Rochester Roof Pros', 'ma-roofing-rochester-pros', 'roofing', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Hammond Roofing Co.', 'ma-roofing-hammond-rochester', 'roofing', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Rochester Roofing Solutions', 'ma-roofing-rochester-solutions', 'roofing', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),

    -- Rockland
    ('Rockland Roofing', 'ma-roofing-rockland-roofing', 'roofing', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Hartsuff Roofing & Siding', 'ma-roofing-hartsuff-rockland', 'roofing', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Rockland Roof Pros', 'ma-roofing-rockland-pros', 'roofing', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Damon Roofing Co.', 'ma-roofing-damon-rockland', 'roofing', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Rockland Roofing Solutions', 'ma-roofing-rockland-solutions', 'roofing', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),

    -- Scituate
    ('Scituate Roofing', 'ma-roofing-scituate-roofing', 'roofing', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Bailey Roofing & Siding', 'ma-roofing-bailey-scituate', 'roofing', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Scituate Roof Pros', 'ma-roofing-scituate-pros', 'roofing', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Lawson Roofing Co.', 'ma-roofing-lawson-scituate', 'roofing', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Scituate Roofing Solutions', 'ma-roofing-scituate-solutions', 'roofing', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),

    -- Wareham
    ('Wareham Roofing', 'ma-roofing-wareham-roofing', 'roofing', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Fearing Roofing & Siding', 'ma-roofing-fearing-wareham', 'roofing', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Wareham Roof Pros', 'ma-roofing-wareham-pros', 'roofing', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Besse Roofing Co.', 'ma-roofing-besse-wareham', 'roofing', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Wareham Roofing Solutions', 'ma-roofing-wareham-solutions', 'roofing', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),

    -- West Bridgewater
    ('West Bridgewater Roofing', 'ma-roofing-west-bridgewater-roofing', 'roofing', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('Howard Roofing & Siding', 'ma-roofing-howard-west-bridgewater', 'roofing', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('West Bridgewater Roof Pros', 'ma-roofing-west-bridgewater-pros', 'roofing', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('Packard Roofing Co.', 'ma-roofing-packard-west-bridgewater', 'roofing', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('West Bridgewater Roofing Solutions', 'ma-roofing-west-bridgewater-solutions', 'roofing', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),

    -- Whitman
    ('Whitman Roofing', 'ma-roofing-whitman-roofing', 'roofing', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Hobart Roofing & Siding', 'ma-roofing-hobart-whitman', 'roofing', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Whitman Roof Pros', 'ma-roofing-whitman-pros', 'roofing', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Jenkins Roofing Co.', 'ma-roofing-jenkins-whitman', 'roofing', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Whitman Roofing Solutions', 'ma-roofing-whitman-solutions', 'roofing', NULL, ARRAY['Whitman','MA','Plymouth'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;
