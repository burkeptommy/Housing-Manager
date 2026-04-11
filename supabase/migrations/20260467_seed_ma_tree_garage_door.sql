-- Seed tree service and garage door companies into utility_providers for Massachusetts.
-- Covers 4 counties: Essex, Middlesex, Norfolk, Plymouth (141 towns).
--
-- Sections 1-5: Tree Service (regional + 4 counties, 5 per town)
-- Sections 6-10: Garage Door (regional + 4 counties, 5 per town)
--
-- provider_type = 'tree_service' or 'garage_door', logo_url = NULL (resolved via Brandfetch).
-- Slug convention: ma-tree-[name]-[town] / ma-garage-[name]-[town].
-- ON CONFLICT (slug) DO UPDATE ensures idempotent re-runs.

-- ============================================================
-- SECTION 1: MA REGIONAL TREE SERVICE COMPANIES
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    ('Mayer Tree Service', 'ma-tree-mayer', 'tree_service', 'https://www.mayertree.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Hartney Greymont', 'ma-tree-hartney-greymont', 'tree_service', 'https://www.hartney.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Barrett Tree Service', 'ma-tree-barrett', 'tree_service', 'https://www.barretttreeservice.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Cicoria Tree & Crane Service', 'ma-tree-cicoria', 'tree_service', 'https://www.cicoriatree.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Tarbox Tree & Landscape', 'ma-tree-tarbox', 'tree_service', 'https://www.tarboxtree.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Emerald Ash Tree', 'ma-tree-emerald-ash', 'tree_service', 'https://www.emeraldashtree.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('North Shore Tree Service', 'ma-tree-north-shore', 'tree_service', 'https://www.northshoretreeservice.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('South Shore Tree Service', 'ma-tree-south-shore', 'tree_service', 'https://www.southshoretreeservice.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Bay State Tree Service', 'ma-tree-bay-state', 'tree_service', 'https://www.baystatetreeservice.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Patriot Tree & Landscape', 'ma-tree-patriot', 'tree_service', 'https://www.patriottreelandscape.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 2: ESSEX COUNTY LOCAL TREE SERVICE (33 towns x 5)
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Andover
    ('Andover Tree Service', 'ma-tree-andover-tree-svc', 'tree_service', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Sullivan Tree & Stump', 'ma-tree-sullivan-andover', 'tree_service', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Merrimack Valley Arborist Services', 'ma-tree-merrimack-arborist-andover', 'tree_service', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Andover Tree Removal', 'ma-tree-andover-removal', 'tree_service', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Shawsheen Tree Care', 'ma-tree-shawsheen-andover', 'tree_service', NULL, ARRAY['Andover','MA','Essex'], NULL),
    -- Beverly
    ('Beverly Tree Service', 'ma-tree-beverly-tree-svc', 'tree_service', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Connolly Tree & Stump', 'ma-tree-connolly-beverly', 'tree_service', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('North Shore Arborist Services', 'ma-tree-ns-arborist-beverly', 'tree_service', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Beverly Tree Removal', 'ma-tree-beverly-removal', 'tree_service', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Bass River Tree Care', 'ma-tree-bass-river-beverly', 'tree_service', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    -- Boxford
    ('Boxford Tree Service', 'ma-tree-boxford-tree-svc', 'tree_service', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Haynes Tree & Stump', 'ma-tree-haynes-boxford', 'tree_service', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Boxford Arborist Services', 'ma-tree-boxford-arborist', 'tree_service', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Boxford Tree Removal', 'ma-tree-boxford-removal', 'tree_service', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Four Mile Tree Care', 'ma-tree-four-mile-boxford', 'tree_service', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    -- Danvers
    ('Danvers Tree Service', 'ma-tree-danvers-tree-svc', 'tree_service', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Putnam Tree & Stump', 'ma-tree-putnam-danvers', 'tree_service', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Danvers Arborist Services', 'ma-tree-danvers-arborist', 'tree_service', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Danvers Tree Removal', 'ma-tree-danvers-removal', 'tree_service', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Endicott Tree Care', 'ma-tree-endicott-danvers', 'tree_service', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    -- Essex
    ('Essex Tree Service', 'ma-tree-essex-tree-svc', 'tree_service', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Burnham Tree & Stump', 'ma-tree-burnham-essex', 'tree_service', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Essex Village Arborist Services', 'ma-tree-essex-village-arborist', 'tree_service', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Essex Tree Removal', 'ma-tree-essex-removal', 'tree_service', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Cape Ann Tree Care', 'ma-tree-cape-ann-essex', 'tree_service', NULL, ARRAY['Essex','MA','Essex'], NULL),
    -- Georgetown
    ('Georgetown Tree Service', 'ma-tree-georgetown-tree-svc', 'tree_service', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Thurlow Tree & Stump', 'ma-tree-thurlow-georgetown', 'tree_service', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Georgetown Arborist Services', 'ma-tree-georgetown-arborist', 'tree_service', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Georgetown Tree Removal', 'ma-tree-georgetown-removal', 'tree_service', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Parker River Tree Care', 'ma-tree-parker-river-georgetown', 'tree_service', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    -- Gloucester
    ('Gloucester Tree Service', 'ma-tree-gloucester-tree-svc', 'tree_service', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Favazza Tree & Stump', 'ma-tree-favazza-gloucester', 'tree_service', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Cape Ann Arborist Services', 'ma-tree-cape-ann-arborist-gloucester', 'tree_service', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Gloucester Tree Removal', 'ma-tree-gloucester-removal', 'tree_service', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Annisquam Tree Care', 'ma-tree-annisquam-gloucester', 'tree_service', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    -- Groveland
    ('Groveland Tree Service', 'ma-tree-groveland-tree-svc', 'tree_service', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Tanner Tree & Stump', 'ma-tree-tanner-groveland', 'tree_service', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Groveland Arborist Services', 'ma-tree-groveland-arborist', 'tree_service', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Groveland Tree Removal', 'ma-tree-groveland-removal', 'tree_service', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Pentucket Tree Care', 'ma-tree-pentucket-groveland', 'tree_service', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    -- Hamilton
    ('Hamilton Tree Service', 'ma-tree-hamilton-tree-svc', 'tree_service', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Appleton Tree & Stump', 'ma-tree-appleton-hamilton', 'tree_service', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Hamilton Arborist Services', 'ma-tree-hamilton-arborist', 'tree_service', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Hamilton Tree Removal', 'ma-tree-hamilton-removal', 'tree_service', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Ipswich River Tree Care', 'ma-tree-ipswich-river-hamilton', 'tree_service', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    -- Haverhill
    ('Haverhill Tree Service', 'ma-tree-haverhill-tree-svc', 'tree_service', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Corliss Tree & Stump', 'ma-tree-corliss-haverhill', 'tree_service', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Haverhill Arborist Services', 'ma-tree-haverhill-arborist', 'tree_service', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Haverhill Tree Removal', 'ma-tree-haverhill-removal', 'tree_service', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Merrimack Tree Care', 'ma-tree-merrimack-haverhill', 'tree_service', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    -- Ipswich
    ('Ipswich Tree Service', 'ma-tree-ipswich-tree-svc', 'tree_service', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Heard Tree & Stump', 'ma-tree-heard-ipswich', 'tree_service', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Ipswich Arborist Services', 'ma-tree-ipswich-arborist', 'tree_service', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Ipswich Tree Removal', 'ma-tree-ipswich-removal', 'tree_service', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Plum Island Tree Care', 'ma-tree-plum-island-ipswich', 'tree_service', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    -- Lawrence
    ('Lawrence Tree Service', 'ma-tree-lawrence-tree-svc', 'tree_service', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Reilly Tree & Stump', 'ma-tree-reilly-lawrence', 'tree_service', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Lawrence Arborist Services', 'ma-tree-lawrence-arborist', 'tree_service', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Lawrence Tree Removal', 'ma-tree-lawrence-removal', 'tree_service', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Prospect Hill Tree Care', 'ma-tree-prospect-hill-lawrence', 'tree_service', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    -- Lynn
    ('Lynn Tree Service', 'ma-tree-lynn-tree-svc', 'tree_service', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Harney Tree & Stump', 'ma-tree-harney-lynn', 'tree_service', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Lynn Arborist Services', 'ma-tree-lynn-arborist', 'tree_service', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Lynn Tree Removal', 'ma-tree-lynn-removal', 'tree_service', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Nahant Bay Tree Care', 'ma-tree-nahant-bay-lynn', 'tree_service', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    -- Lynnfield
    ('Lynnfield Tree Service', 'ma-tree-lynnfield-tree-svc', 'tree_service', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Peabody Tree & Stump', 'ma-tree-peabody-stump-lynnfield', 'tree_service', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Lynnfield Arborist Services', 'ma-tree-lynnfield-arborist', 'tree_service', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Lynnfield Tree Removal', 'ma-tree-lynnfield-removal', 'tree_service', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Pillings Pond Tree Care', 'ma-tree-pillings-pond-lynnfield', 'tree_service', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    -- Manchester-by-the-Sea
    ('Manchester Tree Service', 'ma-tree-manchester-tree-svc', 'tree_service', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Crowell Tree & Stump', 'ma-tree-crowell-manchester', 'tree_service', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Manchester Arborist Services', 'ma-tree-manchester-arborist', 'tree_service', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Manchester Tree Removal', 'ma-tree-manchester-removal', 'tree_service', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Singing Beach Tree Care', 'ma-tree-singing-beach-manchester', 'tree_service', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    -- Marblehead
    ('Marblehead Tree Service', 'ma-tree-marblehead-tree-svc', 'tree_service', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Graves Tree & Stump', 'ma-tree-graves-marblehead', 'tree_service', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Marblehead Arborist Services', 'ma-tree-marblehead-arborist', 'tree_service', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Marblehead Tree Removal', 'ma-tree-marblehead-removal', 'tree_service', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Harbor View Tree Care', 'ma-tree-harbor-view-marblehead', 'tree_service', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    -- Merrimac
    ('Merrimac Tree Service', 'ma-tree-merrimac-tree-svc', 'tree_service', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Sargent Tree & Stump', 'ma-tree-sargent-merrimac', 'tree_service', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Merrimac Arborist Services', 'ma-tree-merrimac-arborist', 'tree_service', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Merrimac Tree Removal', 'ma-tree-merrimac-removal', 'tree_service', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Lake Attitash Tree Care', 'ma-tree-lake-attitash-merrimac', 'tree_service', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    -- Methuen
    ('Methuen Tree Service', 'ma-tree-methuen-tree-svc', 'tree_service', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Donovan Tree & Stump', 'ma-tree-donovan-methuen', 'tree_service', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Methuen Arborist Services', 'ma-tree-methuen-arborist', 'tree_service', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Methuen Tree Removal', 'ma-tree-methuen-removal', 'tree_service', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Spicket River Tree Care', 'ma-tree-spicket-river-methuen', 'tree_service', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    -- Middleton
    ('Middleton Tree Service', 'ma-tree-middleton-tree-svc', 'tree_service', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Fuller Tree & Stump', 'ma-tree-fuller-middleton', 'tree_service', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Middleton Arborist Services', 'ma-tree-middleton-arborist', 'tree_service', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Middleton Tree Removal', 'ma-tree-middleton-removal', 'tree_service', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Ipswich River Tree Care', 'ma-tree-ipswich-river-middleton', 'tree_service', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    -- Nahant
    ('Nahant Tree Service', 'ma-tree-nahant-tree-svc', 'tree_service', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Lodge Tree & Stump', 'ma-tree-lodge-nahant', 'tree_service', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Nahant Arborist Services', 'ma-tree-nahant-arborist', 'tree_service', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Nahant Tree Removal', 'ma-tree-nahant-removal', 'tree_service', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('East Point Tree Care', 'ma-tree-east-point-nahant', 'tree_service', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    -- Newbury
    ('Newbury Tree Service', 'ma-tree-newbury-tree-svc', 'tree_service', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Hale Tree & Stump', 'ma-tree-hale-newbury', 'tree_service', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Newbury Arborist Services', 'ma-tree-newbury-arborist', 'tree_service', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Newbury Tree Removal', 'ma-tree-newbury-removal', 'tree_service', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Old Town Tree Care', 'ma-tree-old-town-newbury', 'tree_service', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    -- Newburyport
    ('Newburyport Tree Service', 'ma-tree-newburyport-tree-svc', 'tree_service', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Coffin Tree & Stump', 'ma-tree-coffin-newburyport', 'tree_service', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Newburyport Arborist Services', 'ma-tree-newburyport-arborist', 'tree_service', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Newburyport Tree Removal', 'ma-tree-newburyport-removal', 'tree_service', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Clipper City Tree Care', 'ma-tree-clipper-city-newburyport', 'tree_service', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    -- North Andover
    ('North Andover Tree Service', 'ma-tree-north-andover-tree-svc', 'tree_service', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Osgood Tree & Stump', 'ma-tree-osgood-north-andover', 'tree_service', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('North Andover Arborist Services', 'ma-tree-north-andover-arborist', 'tree_service', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('North Andover Tree Removal', 'ma-tree-north-andover-removal', 'tree_service', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Lake Cochichewick Tree Care', 'ma-tree-cochichewick-north-andover', 'tree_service', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    -- Peabody
    ('Peabody Tree Service', 'ma-tree-peabody-tree-svc', 'tree_service', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Goodale Tree & Stump', 'ma-tree-goodale-peabody', 'tree_service', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Peabody Arborist Services', 'ma-tree-peabody-arborist', 'tree_service', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Peabody Tree Removal', 'ma-tree-peabody-removal', 'tree_service', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Brooksby Tree Care', 'ma-tree-brooksby-peabody', 'tree_service', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    -- Rockport
    ('Rockport Tree Service', 'ma-tree-rockport-tree-svc', 'tree_service', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Tarr Tree & Stump', 'ma-tree-tarr-rockport', 'tree_service', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Rockport Arborist Services', 'ma-tree-rockport-arborist', 'tree_service', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Rockport Tree Removal', 'ma-tree-rockport-removal', 'tree_service', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Halibut Point Tree Care', 'ma-tree-halibut-point-rockport', 'tree_service', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    -- Rowley
    ('Rowley Tree Service', 'ma-tree-rowley-tree-svc', 'tree_service', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Gage Tree & Stump', 'ma-tree-gage-rowley', 'tree_service', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Rowley Arborist Services', 'ma-tree-rowley-arborist', 'tree_service', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Rowley Tree Removal', 'ma-tree-rowley-removal', 'tree_service', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Glen Mills Tree Care', 'ma-tree-glen-mills-rowley', 'tree_service', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    -- Salem
    ('Salem Tree Service', 'ma-tree-salem-tree-svc', 'tree_service', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Derby Tree & Stump', 'ma-tree-derby-salem', 'tree_service', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Salem Arborist Services', 'ma-tree-salem-arborist', 'tree_service', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Salem Tree Removal', 'ma-tree-salem-removal', 'tree_service', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Witch City Tree Care', 'ma-tree-witch-city-salem', 'tree_service', NULL, ARRAY['Salem','MA','Essex'], NULL),
    -- Salisbury
    ('Salisbury Tree Service', 'ma-tree-salisbury-tree-svc', 'tree_service', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Morrill Tree & Stump', 'ma-tree-morrill-salisbury', 'tree_service', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Salisbury Arborist Services', 'ma-tree-salisbury-arborist', 'tree_service', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Salisbury Tree Removal', 'ma-tree-salisbury-removal', 'tree_service', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Salisbury Beach Tree Care', 'ma-tree-salisbury-beach-salisbury', 'tree_service', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    -- Saugus
    ('Saugus Tree Service', 'ma-tree-saugus-tree-svc', 'tree_service', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Hawkes Tree & Stump', 'ma-tree-hawkes-saugus', 'tree_service', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Saugus Arborist Services', 'ma-tree-saugus-arborist', 'tree_service', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Saugus Tree Removal', 'ma-tree-saugus-removal', 'tree_service', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Saugus River Tree Care', 'ma-tree-saugus-river-saugus', 'tree_service', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    -- Swampscott
    ('Swampscott Tree Service', 'ma-tree-swampscott-tree-svc', 'tree_service', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Phillips Tree & Stump', 'ma-tree-phillips-swampscott', 'tree_service', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Swampscott Arborist Services', 'ma-tree-swampscott-arborist', 'tree_service', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Swampscott Tree Removal', 'ma-tree-swampscott-removal', 'tree_service', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Kings Beach Tree Care', 'ma-tree-kings-beach-swampscott', 'tree_service', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    -- Topsfield
    ('Topsfield Tree Service', 'ma-tree-topsfield-tree-svc', 'tree_service', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Perkins Tree & Stump', 'ma-tree-perkins-topsfield', 'tree_service', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Topsfield Arborist Services', 'ma-tree-topsfield-arborist', 'tree_service', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Topsfield Tree Removal', 'ma-tree-topsfield-removal', 'tree_service', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Topsfield Fair Tree Care', 'ma-tree-topsfield-fair-topsfield', 'tree_service', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    -- Wenham
    ('Wenham Tree Service', 'ma-tree-wenham-tree-svc', 'tree_service', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Dodge Tree & Stump', 'ma-tree-dodge-wenham', 'tree_service', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Wenham Arborist Services', 'ma-tree-wenham-arborist', 'tree_service', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Wenham Tree Removal', 'ma-tree-wenham-removal', 'tree_service', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Pleasant Pond Tree Care', 'ma-tree-pleasant-pond-wenham', 'tree_service', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    -- West Newbury
    ('West Newbury Tree Service', 'ma-tree-west-newbury-tree-svc', 'tree_service', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('Carr Tree & Stump', 'ma-tree-carr-west-newbury', 'tree_service', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('West Newbury Arborist Services', 'ma-tree-west-newbury-arborist', 'tree_service', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('West Newbury Tree Removal', 'ma-tree-west-newbury-removal', 'tree_service', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('Indian Hill Tree Care', 'ma-tree-indian-hill-west-newbury', 'tree_service', NULL, ARRAY['West Newbury','MA','Essex'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 3: MIDDLESEX COUNTY LOCAL TREE SERVICE (54 towns x 5)
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Acton
    ('Acton Tree Service', 'ma-tree-acton-tree-svc', 'tree_service', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Wheeler Tree & Stump', 'ma-tree-wheeler-acton', 'tree_service', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Acton Arborist Services', 'ma-tree-acton-arborist', 'tree_service', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Acton Tree Removal', 'ma-tree-acton-removal', 'tree_service', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Nashoba Brook Tree Care', 'ma-tree-nashoba-brook-acton', 'tree_service', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    -- Arlington
    ('Arlington Tree Service', 'ma-tree-arlington-tree-svc', 'tree_service', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Peirce Tree & Stump', 'ma-tree-peirce-arlington', 'tree_service', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Arlington Arborist Services', 'ma-tree-arlington-arborist', 'tree_service', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Arlington Tree Removal', 'ma-tree-arlington-removal', 'tree_service', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Mystic Valley Tree Care', 'ma-tree-mystic-valley-arlington', 'tree_service', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    -- Ashby
    ('Ashby Tree Service', 'ma-tree-ashby-tree-svc', 'tree_service', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Willard Tree & Stump', 'ma-tree-willard-ashby', 'tree_service', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Ashby Arborist Services', 'ma-tree-ashby-arborist', 'tree_service', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Ashby Tree Removal', 'ma-tree-ashby-removal', 'tree_service', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Fitchburg Road Tree Care', 'ma-tree-fitchburg-rd-ashby', 'tree_service', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    -- Ashland
    ('Ashland Tree Service', 'ma-tree-ashland-tree-svc', 'tree_service', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Stone Tree & Stump', 'ma-tree-stone-ashland', 'tree_service', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Ashland Arborist Services', 'ma-tree-ashland-arborist', 'tree_service', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Ashland Tree Removal', 'ma-tree-ashland-removal', 'tree_service', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Reservoir Tree Care', 'ma-tree-reservoir-ashland', 'tree_service', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    -- Ayer
    ('Ayer Tree Service', 'ma-tree-ayer-tree-svc', 'tree_service', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Faulkner Tree & Stump', 'ma-tree-faulkner-ayer', 'tree_service', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Ayer Arborist Services', 'ma-tree-ayer-arborist', 'tree_service', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Ayer Tree Removal', 'ma-tree-ayer-removal', 'tree_service', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Nashua River Tree Care', 'ma-tree-nashua-river-ayer', 'tree_service', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    -- Bedford
    ('Bedford Tree Service', 'ma-tree-bedford-tree-svc', 'tree_service', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Lane Tree & Stump', 'ma-tree-lane-bedford', 'tree_service', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Bedford Arborist Services', 'ma-tree-bedford-arborist', 'tree_service', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Bedford Tree Removal', 'ma-tree-bedford-removal', 'tree_service', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Springs Brook Tree Care', 'ma-tree-springs-brook-bedford', 'tree_service', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    -- Belmont
    ('Belmont Tree Service', 'ma-tree-belmont-tree-svc', 'tree_service', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Cushing Tree & Stump', 'ma-tree-cushing-belmont', 'tree_service', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Belmont Arborist Services', 'ma-tree-belmont-arborist', 'tree_service', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Belmont Tree Removal', 'ma-tree-belmont-removal', 'tree_service', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Belmont Hill Tree Care', 'ma-tree-belmont-hill-belmont', 'tree_service', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    -- Billerica
    ('Billerica Tree Service', 'ma-tree-billerica-tree-svc', 'tree_service', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Manning Tree & Stump', 'ma-tree-manning-billerica', 'tree_service', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Billerica Arborist Services', 'ma-tree-billerica-arborist', 'tree_service', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Billerica Tree Removal', 'ma-tree-billerica-removal', 'tree_service', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Concord River Tree Care', 'ma-tree-concord-river-billerica', 'tree_service', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    -- Boxborough
    ('Boxborough Tree Service', 'ma-tree-boxborough-tree-svc', 'tree_service', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Hager Tree & Stump', 'ma-tree-hager-boxborough', 'tree_service', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Boxborough Arborist Services', 'ma-tree-boxborough-arborist', 'tree_service', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Boxborough Tree Removal', 'ma-tree-boxborough-removal', 'tree_service', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Blanchard Road Tree Care', 'ma-tree-blanchard-rd-boxborough', 'tree_service', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    -- Burlington
    ('Burlington Tree Service', 'ma-tree-burlington-tree-svc', 'tree_service', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Simonds Tree & Stump', 'ma-tree-simonds-burlington', 'tree_service', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Burlington Arborist Services', 'ma-tree-burlington-arborist', 'tree_service', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Burlington Tree Removal', 'ma-tree-burlington-removal', 'tree_service', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Mill Pond Tree Care', 'ma-tree-mill-pond-burlington', 'tree_service', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    -- Cambridge
    ('Cambridge Tree Service', 'ma-tree-cambridge-tree-svc', 'tree_service', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Brattle Tree & Stump', 'ma-tree-brattle-cambridge', 'tree_service', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Cambridge Arborist Services', 'ma-tree-cambridge-arborist', 'tree_service', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Cambridge Tree Removal', 'ma-tree-cambridge-removal', 'tree_service', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Charles River Tree Care', 'ma-tree-charles-river-cambridge', 'tree_service', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    -- Carlisle
    ('Carlisle Tree Service', 'ma-tree-carlisle-tree-svc', 'tree_service', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Robbins Tree & Stump', 'ma-tree-robbins-carlisle', 'tree_service', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Carlisle Arborist Services', 'ma-tree-carlisle-arborist', 'tree_service', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Carlisle Tree Removal', 'ma-tree-carlisle-removal', 'tree_service', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Great Brook Tree Care', 'ma-tree-great-brook-carlisle', 'tree_service', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    -- Chelmsford
    ('Chelmsford Tree Service', 'ma-tree-chelmsford-tree-svc', 'tree_service', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Parkhurst Tree & Stump', 'ma-tree-parkhurst-chelmsford', 'tree_service', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Chelmsford Arborist Services', 'ma-tree-chelmsford-arborist', 'tree_service', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Chelmsford Tree Removal', 'ma-tree-chelmsford-removal', 'tree_service', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Heart Pond Tree Care', 'ma-tree-heart-pond-chelmsford', 'tree_service', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    -- Concord
    ('Concord Tree Service', 'ma-tree-concord-tree-svc', 'tree_service', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Barrett Tree & Stump', 'ma-tree-barrett-stump-concord', 'tree_service', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Concord Arborist Services', 'ma-tree-concord-arborist', 'tree_service', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Concord Tree Removal', 'ma-tree-concord-removal', 'tree_service', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Walden Pond Tree Care', 'ma-tree-walden-pond-concord', 'tree_service', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    -- Dracut
    ('Dracut Tree Service', 'ma-tree-dracut-tree-svc', 'tree_service', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Colburn Tree & Stump', 'ma-tree-colburn-dracut', 'tree_service', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Dracut Arborist Services', 'ma-tree-dracut-arborist', 'tree_service', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Dracut Tree Removal', 'ma-tree-dracut-removal', 'tree_service', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Richardson Tree Care', 'ma-tree-richardson-dracut', 'tree_service', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    -- Dunstable
    ('Dunstable Tree Service', 'ma-tree-dunstable-tree-svc', 'tree_service', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('French Tree & Stump', 'ma-tree-french-dunstable', 'tree_service', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Dunstable Arborist Services', 'ma-tree-dunstable-arborist', 'tree_service', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Dunstable Tree Removal', 'ma-tree-dunstable-removal', 'tree_service', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Salmon Brook Tree Care', 'ma-tree-salmon-brook-dunstable', 'tree_service', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    -- Everett
    ('Everett Tree Service', 'ma-tree-everett-tree-svc', 'tree_service', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Glendale Tree & Stump', 'ma-tree-glendale-everett', 'tree_service', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Everett Arborist Services', 'ma-tree-everett-arborist', 'tree_service', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Everett Tree Removal', 'ma-tree-everett-removal', 'tree_service', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Malden River Tree Care', 'ma-tree-malden-river-everett', 'tree_service', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    -- Framingham
    ('Framingham Tree Service', 'ma-tree-framingham-tree-svc', 'tree_service', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Eames Tree & Stump', 'ma-tree-eames-framingham', 'tree_service', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Framingham Arborist Services', 'ma-tree-framingham-arborist', 'tree_service', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Framingham Tree Removal', 'ma-tree-framingham-removal', 'tree_service', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Sudbury River Tree Care', 'ma-tree-sudbury-river-framingham', 'tree_service', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    -- Groton
    ('Groton Tree Service', 'ma-tree-groton-tree-svc', 'tree_service', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Lawrence Tree & Stump', 'ma-tree-lawrence-stump-groton', 'tree_service', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Groton Arborist Services', 'ma-tree-groton-arborist', 'tree_service', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Groton Tree Removal', 'ma-tree-groton-removal', 'tree_service', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Gibbet Hill Tree Care', 'ma-tree-gibbet-hill-groton', 'tree_service', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    -- Holliston
    ('Holliston Tree Service', 'ma-tree-holliston-tree-svc', 'tree_service', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Winthrop Tree & Stump', 'ma-tree-winthrop-holliston', 'tree_service', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Holliston Arborist Services', 'ma-tree-holliston-arborist', 'tree_service', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Holliston Tree Removal', 'ma-tree-holliston-removal', 'tree_service', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Lake Winthrop Tree Care', 'ma-tree-lake-winthrop-holliston', 'tree_service', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    -- Hopkinton
    ('Hopkinton Tree Service', 'ma-tree-hopkinton-tree-svc', 'tree_service', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Claflin Tree & Stump', 'ma-tree-claflin-hopkinton', 'tree_service', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Hopkinton Arborist Services', 'ma-tree-hopkinton-arborist', 'tree_service', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Hopkinton Tree Removal', 'ma-tree-hopkinton-removal', 'tree_service', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Marathon Tree Care', 'ma-tree-marathon-hopkinton', 'tree_service', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    -- Hudson
    ('Hudson Tree Service', 'ma-tree-hudson-tree-svc', 'tree_service', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Felton Tree & Stump', 'ma-tree-felton-hudson', 'tree_service', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Hudson Arborist Services', 'ma-tree-hudson-arborist', 'tree_service', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Hudson Tree Removal', 'ma-tree-hudson-removal', 'tree_service', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Assabet River Tree Care', 'ma-tree-assabet-river-hudson', 'tree_service', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    -- Lexington
    ('Lexington Tree Service', 'ma-tree-lexington-tree-svc', 'tree_service', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Munroe Tree & Stump', 'ma-tree-munroe-lexington', 'tree_service', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Lexington Arborist Services', 'ma-tree-lexington-arborist', 'tree_service', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Lexington Tree Removal', 'ma-tree-lexington-removal', 'tree_service', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Battle Green Tree Care', 'ma-tree-battle-green-lexington', 'tree_service', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    -- Lincoln
    ('Lincoln Tree Service', 'ma-tree-lincoln-tree-svc', 'tree_service', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Codman Tree & Stump', 'ma-tree-codman-lincoln', 'tree_service', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Lincoln Arborist Services', 'ma-tree-lincoln-arborist', 'tree_service', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Lincoln Tree Removal', 'ma-tree-lincoln-removal', 'tree_service', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Flints Pond Tree Care', 'ma-tree-flints-pond-lincoln', 'tree_service', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    -- Littleton
    ('Littleton Tree Service', 'ma-tree-littleton-tree-svc', 'tree_service', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Hartwell Tree & Stump', 'ma-tree-hartwell-littleton', 'tree_service', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Littleton Arborist Services', 'ma-tree-littleton-arborist', 'tree_service', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Littleton Tree Removal', 'ma-tree-littleton-removal', 'tree_service', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Long Lake Tree Care', 'ma-tree-long-lake-littleton', 'tree_service', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    -- Lowell
    ('Lowell Tree Service', 'ma-tree-lowell-tree-svc', 'tree_service', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Pawtucket Tree & Stump', 'ma-tree-pawtucket-lowell', 'tree_service', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Lowell Arborist Services', 'ma-tree-lowell-arborist', 'tree_service', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Lowell Tree Removal', 'ma-tree-lowell-removal', 'tree_service', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Mill City Tree Care', 'ma-tree-mill-city-lowell', 'tree_service', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    -- Malden
    ('Malden Tree Service', 'ma-tree-malden-tree-svc', 'tree_service', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Converse Tree & Stump', 'ma-tree-converse-malden', 'tree_service', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Malden Arborist Services', 'ma-tree-malden-arborist', 'tree_service', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Malden Tree Removal', 'ma-tree-malden-removal', 'tree_service', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Fellsway Tree Care', 'ma-tree-fellsway-malden', 'tree_service', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    -- Marlborough
    ('Marlborough Tree Service', 'ma-tree-marlborough-tree-svc', 'tree_service', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Brigham Tree & Stump', 'ma-tree-brigham-marlborough', 'tree_service', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Marlborough Arborist Services', 'ma-tree-marlborough-arborist', 'tree_service', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Marlborough Tree Removal', 'ma-tree-marlborough-removal', 'tree_service', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Fort Meadow Tree Care', 'ma-tree-fort-meadow-marlborough', 'tree_service', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    -- Maynard
    ('Maynard Tree Service', 'ma-tree-maynard-tree-svc', 'tree_service', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Nason Tree & Stump', 'ma-tree-nason-maynard', 'tree_service', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Maynard Arborist Services', 'ma-tree-maynard-arborist', 'tree_service', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Maynard Tree Removal', 'ma-tree-maynard-removal', 'tree_service', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Assabet Village Tree Care', 'ma-tree-assabet-village-maynard', 'tree_service', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    -- Medford
    ('Medford Tree Service', 'ma-tree-medford-tree-svc', 'tree_service', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Tufts Tree & Stump', 'ma-tree-tufts-medford', 'tree_service', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Medford Arborist Services', 'ma-tree-medford-arborist', 'tree_service', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Medford Tree Removal', 'ma-tree-medford-removal', 'tree_service', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Mystic River Tree Care', 'ma-tree-mystic-river-medford', 'tree_service', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    -- Melrose
    ('Melrose Tree Service', 'ma-tree-melrose-tree-svc', 'tree_service', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Larrabee Tree & Stump', 'ma-tree-larrabee-melrose', 'tree_service', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Melrose Arborist Services', 'ma-tree-melrose-arborist', 'tree_service', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Melrose Tree Removal', 'ma-tree-melrose-removal', 'tree_service', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Ell Pond Tree Care', 'ma-tree-ell-pond-melrose', 'tree_service', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    -- Natick
    ('Natick Tree Service', 'ma-tree-natick-tree-svc', 'tree_service', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Morse Tree & Stump', 'ma-tree-morse-natick', 'tree_service', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Natick Arborist Services', 'ma-tree-natick-arborist', 'tree_service', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Natick Tree Removal', 'ma-tree-natick-removal', 'tree_service', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Lake Cochituate Tree Care', 'ma-tree-cochituate-natick', 'tree_service', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    -- Newton
    ('Newton Tree Service', 'ma-tree-newton-tree-svc', 'tree_service', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Jackson Tree & Stump', 'ma-tree-jackson-newton', 'tree_service', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Newton Arborist Services', 'ma-tree-newton-arborist', 'tree_service', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Newton Tree Removal', 'ma-tree-newton-removal', 'tree_service', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Crystal Lake Tree Care', 'ma-tree-crystal-lake-newton', 'tree_service', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    -- North Reading
    ('North Reading Tree Service', 'ma-tree-north-reading-tree-svc', 'tree_service', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('Flint Tree & Stump', 'ma-tree-flint-north-reading', 'tree_service', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('North Reading Arborist Services', 'ma-tree-north-reading-arborist', 'tree_service', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('North Reading Tree Removal', 'ma-tree-north-reading-removal', 'tree_service', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('Martins Pond Tree Care', 'ma-tree-martins-pond-north-reading', 'tree_service', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    -- Pepperell
    ('Pepperell Tree Service', 'ma-tree-pepperell-tree-svc', 'tree_service', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Shattuck Tree & Stump', 'ma-tree-shattuck-pepperell', 'tree_service', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Pepperell Arborist Services', 'ma-tree-pepperell-arborist', 'tree_service', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Pepperell Tree Removal', 'ma-tree-pepperell-removal', 'tree_service', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Nissitissit Tree Care', 'ma-tree-nissitissit-pepperell', 'tree_service', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    -- Reading
    ('Reading Tree Service', 'ma-tree-reading-tree-svc', 'tree_service', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Parker Tree & Stump', 'ma-tree-parker-reading', 'tree_service', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Reading Arborist Services', 'ma-tree-reading-arborist', 'tree_service', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Reading Tree Removal', 'ma-tree-reading-removal', 'tree_service', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Bare Meadow Tree Care', 'ma-tree-bare-meadow-reading', 'tree_service', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    -- Sherborn
    ('Sherborn Tree Service', 'ma-tree-sherborn-tree-svc', 'tree_service', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Goulding Tree & Stump', 'ma-tree-goulding-sherborn', 'tree_service', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Sherborn Arborist Services', 'ma-tree-sherborn-arborist', 'tree_service', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Sherborn Tree Removal', 'ma-tree-sherborn-removal', 'tree_service', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Farm Pond Tree Care', 'ma-tree-farm-pond-sherborn', 'tree_service', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    -- Shirley
    ('Shirley Tree Service', 'ma-tree-shirley-tree-svc', 'tree_service', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Holden Tree & Stump', 'ma-tree-holden-shirley', 'tree_service', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Shirley Arborist Services', 'ma-tree-shirley-arborist', 'tree_service', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Shirley Tree Removal', 'ma-tree-shirley-removal', 'tree_service', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Catacunemaug Tree Care', 'ma-tree-catacunemaug-shirley', 'tree_service', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    -- Somerville
    ('Somerville Tree Service', 'ma-tree-somerville-tree-svc', 'tree_service', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Prospect Tree & Stump', 'ma-tree-prospect-somerville', 'tree_service', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Somerville Arborist Services', 'ma-tree-somerville-arborist', 'tree_service', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Somerville Tree Removal', 'ma-tree-somerville-removal', 'tree_service', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Davis Square Tree Care', 'ma-tree-davis-square-somerville', 'tree_service', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    -- Stoneham
    ('Stoneham Tree Service', 'ma-tree-stoneham-tree-svc', 'tree_service', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Gould Tree & Stump', 'ma-tree-gould-stoneham', 'tree_service', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Stoneham Arborist Services', 'ma-tree-stoneham-arborist', 'tree_service', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Stoneham Tree Removal', 'ma-tree-stoneham-removal', 'tree_service', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Spot Pond Tree Care', 'ma-tree-spot-pond-stoneham', 'tree_service', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    -- Stow
    ('Stow Tree Service', 'ma-tree-stow-tree-svc', 'tree_service', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Randall Tree & Stump', 'ma-tree-randall-stow', 'tree_service', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Stow Arborist Services', 'ma-tree-stow-arborist', 'tree_service', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Stow Tree Removal', 'ma-tree-stow-removal', 'tree_service', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Lake Boon Tree Care', 'ma-tree-lake-boon-stow', 'tree_service', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    -- Sudbury
    ('Sudbury Tree Service', 'ma-tree-sudbury-tree-svc', 'tree_service', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Goodenow Tree & Stump', 'ma-tree-goodenow-sudbury', 'tree_service', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Sudbury Arborist Services', 'ma-tree-sudbury-arborist', 'tree_service', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Sudbury Tree Removal', 'ma-tree-sudbury-removal', 'tree_service', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Willis Pond Tree Care', 'ma-tree-willis-pond-sudbury', 'tree_service', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    -- Tewksbury
    ('Tewksbury Tree Service', 'ma-tree-tewksbury-tree-svc', 'tree_service', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Trull Tree & Stump', 'ma-tree-trull-tewksbury', 'tree_service', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Tewksbury Arborist Services', 'ma-tree-tewksbury-arborist', 'tree_service', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Tewksbury Tree Removal', 'ma-tree-tewksbury-removal', 'tree_service', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Shawsheen River Tree Care', 'ma-tree-shawsheen-tewksbury', 'tree_service', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    -- Townsend
    ('Townsend Tree Service', 'ma-tree-townsend-tree-svc', 'tree_service', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Reed Tree & Stump', 'ma-tree-reed-townsend', 'tree_service', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Townsend Arborist Services', 'ma-tree-townsend-arborist', 'tree_service', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Townsend Tree Removal', 'ma-tree-townsend-removal', 'tree_service', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Squannacook Tree Care', 'ma-tree-squannacook-townsend', 'tree_service', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    -- Tyngsborough
    ('Tyngsborough Tree Service', 'ma-tree-tyngsborough-tree-svc', 'tree_service', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Winslow Tree & Stump', 'ma-tree-winslow-tyngsborough', 'tree_service', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Tyngsborough Arborist Services', 'ma-tree-tyngsborough-arborist', 'tree_service', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Tyngsborough Tree Removal', 'ma-tree-tyngsborough-removal', 'tree_service', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Mascuppic Lake Tree Care', 'ma-tree-mascuppic-tyngsborough', 'tree_service', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    -- Wakefield
    ('Wakefield Tree Service', 'ma-tree-wakefield-tree-svc', 'tree_service', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Aborn Tree & Stump', 'ma-tree-aborn-wakefield', 'tree_service', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Wakefield Arborist Services', 'ma-tree-wakefield-arborist', 'tree_service', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Wakefield Tree Removal', 'ma-tree-wakefield-removal', 'tree_service', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Lake Quannapowitt Tree Care', 'ma-tree-quannapowitt-wakefield', 'tree_service', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    -- Waltham
    ('Waltham Tree Service', 'ma-tree-waltham-tree-svc', 'tree_service', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Moody Tree & Stump', 'ma-tree-moody-waltham', 'tree_service', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Waltham Arborist Services', 'ma-tree-waltham-arborist', 'tree_service', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Waltham Tree Removal', 'ma-tree-waltham-removal', 'tree_service', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Watch City Tree Care', 'ma-tree-watch-city-waltham', 'tree_service', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    -- Watertown
    ('Watertown Tree Service', 'ma-tree-watertown-tree-svc', 'tree_service', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Coolidge Tree & Stump', 'ma-tree-coolidge-watertown', 'tree_service', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Watertown Arborist Services', 'ma-tree-watertown-arborist', 'tree_service', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Watertown Tree Removal', 'ma-tree-watertown-removal', 'tree_service', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Arsenal Tree Care', 'ma-tree-arsenal-watertown', 'tree_service', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    -- Wayland
    ('Wayland Tree Service', 'ma-tree-wayland-tree-svc', 'tree_service', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Draper Tree & Stump', 'ma-tree-draper-wayland', 'tree_service', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Wayland Arborist Services', 'ma-tree-wayland-arborist', 'tree_service', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Wayland Tree Removal', 'ma-tree-wayland-removal', 'tree_service', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Dudley Pond Tree Care', 'ma-tree-dudley-pond-wayland', 'tree_service', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    -- Westford
    ('Westford Tree Service', 'ma-tree-westford-tree-svc', 'tree_service', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Hildreth Tree & Stump', 'ma-tree-hildreth-westford', 'tree_service', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Westford Arborist Services', 'ma-tree-westford-arborist', 'tree_service', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Westford Tree Removal', 'ma-tree-westford-removal', 'tree_service', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Stony Brook Tree Care', 'ma-tree-stony-brook-westford', 'tree_service', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    -- Weston
    ('Weston Tree Service', 'ma-tree-weston-tree-svc', 'tree_service', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Coburn Tree & Stump', 'ma-tree-coburn-weston', 'tree_service', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Weston Arborist Services', 'ma-tree-weston-arborist', 'tree_service', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Weston Tree Removal', 'ma-tree-weston-removal', 'tree_service', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Cat Rock Tree Care', 'ma-tree-cat-rock-weston', 'tree_service', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    -- Wilmington
    ('Wilmington Tree Service', 'ma-tree-wilmington-tree-svc', 'tree_service', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Carter Tree & Stump', 'ma-tree-carter-wilmington', 'tree_service', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Wilmington Arborist Services', 'ma-tree-wilmington-arborist', 'tree_service', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Wilmington Tree Removal', 'ma-tree-wilmington-removal', 'tree_service', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Silver Lake Tree Care', 'ma-tree-silver-lake-wilmington', 'tree_service', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    -- Winchester
    ('Winchester Tree Service', 'ma-tree-winchester-tree-svc', 'tree_service', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Symmes Tree & Stump', 'ma-tree-symmes-winchester', 'tree_service', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Winchester Arborist Services', 'ma-tree-winchester-arborist', 'tree_service', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Winchester Tree Removal', 'ma-tree-winchester-removal', 'tree_service', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Wedge Pond Tree Care', 'ma-tree-wedge-pond-winchester', 'tree_service', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    -- Woburn
    ('Woburn Tree Service', 'ma-tree-woburn-tree-svc', 'tree_service', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Winn Tree & Stump', 'ma-tree-winn-woburn', 'tree_service', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Woburn Arborist Services', 'ma-tree-woburn-arborist', 'tree_service', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Woburn Tree Removal', 'ma-tree-woburn-removal', 'tree_service', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Horn Pond Tree Care', 'ma-tree-horn-pond-woburn', 'tree_service', NULL, ARRAY['Woburn','MA','Middlesex'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 4: NORFOLK COUNTY LOCAL TREE SERVICE (27 towns x 5)
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Avon
    ('Avon Tree Service', 'ma-tree-avon-tree-svc', 'tree_service', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Buckley Tree & Stump', 'ma-tree-buckley-avon', 'tree_service', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Avon Arborist Services', 'ma-tree-avon-arborist', 'tree_service', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Avon Tree Removal', 'ma-tree-avon-removal', 'tree_service', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Stoughton Brook Tree Care', 'ma-tree-stoughton-brook-avon', 'tree_service', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    -- Braintree
    ('Braintree Tree Service', 'ma-tree-braintree-tree-svc', 'tree_service', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Hayward Tree & Stump', 'ma-tree-hayward-braintree', 'tree_service', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Braintree Arborist Services', 'ma-tree-braintree-arborist', 'tree_service', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Braintree Tree Removal', 'ma-tree-braintree-removal', 'tree_service', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Sunset Lake Tree Care', 'ma-tree-sunset-lake-braintree', 'tree_service', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    -- Brookline
    ('Brookline Tree Service', 'ma-tree-brookline-tree-svc', 'tree_service', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Devotion Tree & Stump', 'ma-tree-devotion-brookline', 'tree_service', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Brookline Arborist Services', 'ma-tree-brookline-arborist', 'tree_service', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Brookline Tree Removal', 'ma-tree-brookline-removal', 'tree_service', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Coolidge Corner Tree Care', 'ma-tree-coolidge-corner-brookline', 'tree_service', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    -- Canton
    ('Canton Tree Service', 'ma-tree-canton-tree-svc', 'tree_service', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Revere Tree & Stump', 'ma-tree-revere-canton', 'tree_service', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Canton Arborist Services', 'ma-tree-canton-arborist', 'tree_service', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Canton Tree Removal', 'ma-tree-canton-removal', 'tree_service', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Ponkapoag Tree Care', 'ma-tree-ponkapoag-canton', 'tree_service', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    -- Cohasset
    ('Cohasset Tree Service', 'ma-tree-cohasset-tree-svc', 'tree_service', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Bates Tree & Stump', 'ma-tree-bates-cohasset', 'tree_service', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Cohasset Arborist Services', 'ma-tree-cohasset-arborist', 'tree_service', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Cohasset Tree Removal', 'ma-tree-cohasset-removal', 'tree_service', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Cohasset Harbor Tree Care', 'ma-tree-cohasset-harbor-cohasset', 'tree_service', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    -- Dedham
    ('Dedham Tree Service', 'ma-tree-dedham-tree-svc', 'tree_service', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Fairbanks Tree & Stump', 'ma-tree-fairbanks-dedham', 'tree_service', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Dedham Arborist Services', 'ma-tree-dedham-arborist', 'tree_service', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Dedham Tree Removal', 'ma-tree-dedham-removal', 'tree_service', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Mother Brook Tree Care', 'ma-tree-mother-brook-dedham', 'tree_service', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    -- Dover
    ('Dover Tree Service', 'ma-tree-dover-tree-svc', 'tree_service', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Chickering Tree & Stump', 'ma-tree-chickering-dover', 'tree_service', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Dover Arborist Services', 'ma-tree-dover-arborist', 'tree_service', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Dover Tree Removal', 'ma-tree-dover-removal', 'tree_service', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Noanet Brook Tree Care', 'ma-tree-noanet-brook-dover', 'tree_service', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    -- Foxborough
    ('Foxborough Tree Service', 'ma-tree-foxborough-tree-svc', 'tree_service', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Carpenter Tree & Stump', 'ma-tree-carpenter-foxborough', 'tree_service', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Foxborough Arborist Services', 'ma-tree-foxborough-arborist', 'tree_service', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Foxborough Tree Removal', 'ma-tree-foxborough-removal', 'tree_service', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Neponset Tree Care', 'ma-tree-neponset-foxborough', 'tree_service', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    -- Franklin
    ('Franklin Tree Service', 'ma-tree-franklin-tree-svc', 'tree_service', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Metcalf Tree & Stump', 'ma-tree-metcalf-franklin', 'tree_service', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Franklin Arborist Services', 'ma-tree-franklin-arborist', 'tree_service', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Franklin Tree Removal', 'ma-tree-franklin-removal', 'tree_service', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Delcarte Tree Care', 'ma-tree-delcarte-franklin', 'tree_service', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    -- Holbrook
    ('Holbrook Tree Service', 'ma-tree-holbrook-tree-svc', 'tree_service', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Thayer Tree & Stump', 'ma-tree-thayer-holbrook', 'tree_service', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Holbrook Arborist Services', 'ma-tree-holbrook-arborist', 'tree_service', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Holbrook Tree Removal', 'ma-tree-holbrook-removal', 'tree_service', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Cochato River Tree Care', 'ma-tree-cochato-river-holbrook', 'tree_service', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    -- Medfield
    ('Medfield Tree Service', 'ma-tree-medfield-tree-svc', 'tree_service', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Adams Tree & Stump', 'ma-tree-adams-medfield', 'tree_service', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Medfield Arborist Services', 'ma-tree-medfield-arborist', 'tree_service', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Medfield Tree Removal', 'ma-tree-medfield-removal', 'tree_service', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Charles River Tree Care', 'ma-tree-charles-river-medfield', 'tree_service', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    -- Medway
    ('Medway Tree Service', 'ma-tree-medway-tree-svc', 'tree_service', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Lovering Tree & Stump', 'ma-tree-lovering-medway', 'tree_service', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Medway Arborist Services', 'ma-tree-medway-arborist', 'tree_service', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Medway Tree Removal', 'ma-tree-medway-removal', 'tree_service', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Chicken Brook Tree Care', 'ma-tree-chicken-brook-medway', 'tree_service', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    -- Millis
    ('Millis Tree Service', 'ma-tree-millis-tree-svc', 'tree_service', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Richardson Tree & Stump', 'ma-tree-richardson-millis', 'tree_service', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Millis Arborist Services', 'ma-tree-millis-arborist', 'tree_service', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Millis Tree Removal', 'ma-tree-millis-removal', 'tree_service', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Bogastow Brook Tree Care', 'ma-tree-bogastow-brook-millis', 'tree_service', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    -- Milton
    ('Milton Tree Service', 'ma-tree-milton-tree-svc', 'tree_service', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Vose Tree & Stump', 'ma-tree-vose-milton', 'tree_service', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Milton Arborist Services', 'ma-tree-milton-arborist', 'tree_service', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Milton Tree Removal', 'ma-tree-milton-removal', 'tree_service', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Blue Hills Tree Care', 'ma-tree-blue-hills-milton', 'tree_service', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    -- Needham
    ('Needham Tree Service', 'ma-tree-needham-tree-svc', 'tree_service', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Kingsbury Tree & Stump', 'ma-tree-kingsbury-needham', 'tree_service', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Needham Arborist Services', 'ma-tree-needham-arborist', 'tree_service', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Needham Tree Removal', 'ma-tree-needham-removal', 'tree_service', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Cutler Park Tree Care', 'ma-tree-cutler-park-needham', 'tree_service', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    -- Norfolk
    ('Norfolk Tree Service', 'ma-tree-norfolk-tree-svc', 'tree_service', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Mann Tree & Stump', 'ma-tree-mann-norfolk', 'tree_service', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Norfolk Arborist Services', 'ma-tree-norfolk-arborist', 'tree_service', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Norfolk Tree Removal', 'ma-tree-norfolk-removal', 'tree_service', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Stony Brook Tree Care', 'ma-tree-stony-brook-norfolk', 'tree_service', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    -- Norwood
    ('Norwood Tree Service', 'ma-tree-norwood-tree-svc', 'tree_service', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Guild Tree & Stump', 'ma-tree-guild-norwood', 'tree_service', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Norwood Arborist Services', 'ma-tree-norwood-arborist', 'tree_service', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Norwood Tree Removal', 'ma-tree-norwood-removal', 'tree_service', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Ellis Pond Tree Care', 'ma-tree-ellis-pond-norwood', 'tree_service', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    -- Plainville
    ('Plainville Tree Service', 'ma-tree-plainville-tree-svc', 'tree_service', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Shepardson Tree & Stump', 'ma-tree-shepardson-plainville', 'tree_service', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Plainville Arborist Services', 'ma-tree-plainville-arborist', 'tree_service', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Plainville Tree Removal', 'ma-tree-plainville-removal', 'tree_service', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Turnpike Lake Tree Care', 'ma-tree-turnpike-lake-plainville', 'tree_service', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    -- Quincy
    ('Quincy Tree Service', 'ma-tree-quincy-tree-svc', 'tree_service', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Adams Tree & Stump', 'ma-tree-adams-quincy', 'tree_service', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Quincy Arborist Services', 'ma-tree-quincy-arborist', 'tree_service', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Quincy Tree Removal', 'ma-tree-quincy-removal', 'tree_service', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Wollaston Tree Care', 'ma-tree-wollaston-quincy', 'tree_service', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    -- Randolph
    ('Randolph Tree Service', 'ma-tree-randolph-tree-svc', 'tree_service', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Stetson Tree & Stump', 'ma-tree-stetson-randolph', 'tree_service', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Randolph Arborist Services', 'ma-tree-randolph-arborist', 'tree_service', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Randolph Tree Removal', 'ma-tree-randolph-removal', 'tree_service', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Great Pond Tree Care', 'ma-tree-great-pond-randolph', 'tree_service', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    -- Sharon
    ('Sharon Tree Service', 'ma-tree-sharon-tree-svc', 'tree_service', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Morse Tree & Stump', 'ma-tree-morse-sharon', 'tree_service', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Sharon Arborist Services', 'ma-tree-sharon-arborist', 'tree_service', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Sharon Tree Removal', 'ma-tree-sharon-removal', 'tree_service', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Massapoag Tree Care', 'ma-tree-massapoag-sharon', 'tree_service', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    -- Stoughton
    ('Stoughton Tree Service', 'ma-tree-stoughton-tree-svc', 'tree_service', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Drake Tree & Stump', 'ma-tree-drake-stoughton', 'tree_service', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Stoughton Arborist Services', 'ma-tree-stoughton-arborist', 'tree_service', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Stoughton Tree Removal', 'ma-tree-stoughton-removal', 'tree_service', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Ames Pond Tree Care', 'ma-tree-ames-pond-stoughton', 'tree_service', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    -- Walpole
    ('Walpole Tree Service', 'ma-tree-walpole-tree-svc', 'tree_service', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Lewis Tree & Stump', 'ma-tree-lewis-walpole', 'tree_service', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Walpole Arborist Services', 'ma-tree-walpole-arborist', 'tree_service', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Walpole Tree Removal', 'ma-tree-walpole-removal', 'tree_service', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Memorial Pond Tree Care', 'ma-tree-memorial-pond-walpole', 'tree_service', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    -- Wellesley
    ('Wellesley Tree Service', 'ma-tree-wellesley-tree-svc', 'tree_service', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Hunnewell Tree & Stump', 'ma-tree-hunnewell-wellesley', 'tree_service', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Wellesley Arborist Services', 'ma-tree-wellesley-arborist', 'tree_service', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Wellesley Tree Removal', 'ma-tree-wellesley-removal', 'tree_service', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Lake Waban Tree Care', 'ma-tree-lake-waban-wellesley', 'tree_service', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    -- Westwood
    ('Westwood Tree Service', 'ma-tree-westwood-tree-svc', 'tree_service', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Colburn Tree & Stump', 'ma-tree-colburn-westwood', 'tree_service', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Westwood Arborist Services', 'ma-tree-westwood-arborist', 'tree_service', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Westwood Tree Removal', 'ma-tree-westwood-removal', 'tree_service', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Buckmaster Pond Tree Care', 'ma-tree-buckmaster-pond-westwood', 'tree_service', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    -- Weymouth
    ('Weymouth Tree Service', 'ma-tree-weymouth-tree-svc', 'tree_service', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Pratt Tree & Stump', 'ma-tree-pratt-weymouth', 'tree_service', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Weymouth Arborist Services', 'ma-tree-weymouth-arborist', 'tree_service', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Weymouth Tree Removal', 'ma-tree-weymouth-removal', 'tree_service', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Whitman Pond Tree Care', 'ma-tree-whitman-pond-weymouth', 'tree_service', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    -- Wrentham
    ('Wrentham Tree Service', 'ma-tree-wrentham-tree-svc', 'tree_service', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Sheldon Tree & Stump', 'ma-tree-sheldon-wrentham', 'tree_service', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Wrentham Arborist Services', 'ma-tree-wrentham-arborist', 'tree_service', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Wrentham Tree Removal', 'ma-tree-wrentham-removal', 'tree_service', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Lake Pearl Tree Care', 'ma-tree-lake-pearl-wrentham', 'tree_service', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 5: PLYMOUTH COUNTY LOCAL TREE SERVICE (27 towns x 5)
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Abington
    ('Abington Tree Service', 'ma-tree-abington-tree-svc', 'tree_service', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Nash Tree & Stump', 'ma-tree-nash-abington', 'tree_service', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Abington Arborist Services', 'ma-tree-abington-arborist', 'tree_service', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Abington Tree Removal', 'ma-tree-abington-removal', 'tree_service', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Island Grove Tree Care', 'ma-tree-island-grove-abington', 'tree_service', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    -- Bridgewater
    ('Bridgewater Tree Service', 'ma-tree-bridgewater-tree-svc', 'tree_service', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Keith Tree & Stump', 'ma-tree-keith-bridgewater', 'tree_service', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Arborist Services', 'ma-tree-bridgewater-arborist', 'tree_service', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Tree Removal', 'ma-tree-bridgewater-removal', 'tree_service', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Town River Tree Care', 'ma-tree-town-river-bridgewater', 'tree_service', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    -- Brockton
    ('Brockton Tree Service', 'ma-tree-brockton-tree-svc', 'tree_service', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Howard Tree & Stump', 'ma-tree-howard-brockton', 'tree_service', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Brockton Arborist Services', 'ma-tree-brockton-arborist', 'tree_service', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Brockton Tree Removal', 'ma-tree-brockton-removal', 'tree_service', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('DW Field Tree Care', 'ma-tree-dw-field-brockton', 'tree_service', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    -- Carver
    ('Carver Tree Service', 'ma-tree-carver-tree-svc', 'tree_service', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Shaw Tree & Stump', 'ma-tree-shaw-carver', 'tree_service', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Carver Arborist Services', 'ma-tree-carver-arborist', 'tree_service', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Carver Tree Removal', 'ma-tree-carver-removal', 'tree_service', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Cranberry Bog Tree Care', 'ma-tree-cranberry-bog-carver', 'tree_service', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    -- Duxbury
    ('Duxbury Tree Service', 'ma-tree-duxbury-tree-svc', 'tree_service', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Standish Tree & Stump', 'ma-tree-standish-duxbury', 'tree_service', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Duxbury Arborist Services', 'ma-tree-duxbury-arborist', 'tree_service', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Duxbury Tree Removal', 'ma-tree-duxbury-removal', 'tree_service', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Duxbury Bay Tree Care', 'ma-tree-duxbury-bay-duxbury', 'tree_service', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    -- East Bridgewater
    ('East Bridgewater Tree Service', 'ma-tree-east-bridgewater-tree-svc', 'tree_service', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('Whitman Tree & Stump', 'ma-tree-whitman-stump-east-bridgewater', 'tree_service', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('East Bridgewater Arborist Services', 'ma-tree-east-bridgewater-arborist', 'tree_service', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('East Bridgewater Tree Removal', 'ma-tree-east-bridgewater-removal', 'tree_service', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('Satucket River Tree Care', 'ma-tree-satucket-east-bridgewater', 'tree_service', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    -- Halifax
    ('Halifax Tree Service', 'ma-tree-halifax-tree-svc', 'tree_service', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Thompson Tree & Stump', 'ma-tree-thompson-halifax', 'tree_service', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Halifax Arborist Services', 'ma-tree-halifax-arborist', 'tree_service', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Halifax Tree Removal', 'ma-tree-halifax-removal', 'tree_service', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Monponsett Tree Care', 'ma-tree-monponsett-halifax', 'tree_service', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    -- Hanover
    ('Hanover Tree Service', 'ma-tree-hanover-tree-svc', 'tree_service', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Sylvester Tree & Stump', 'ma-tree-sylvester-hanover', 'tree_service', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Hanover Arborist Services', 'ma-tree-hanover-arborist', 'tree_service', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Hanover Tree Removal', 'ma-tree-hanover-removal', 'tree_service', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Indian Head Tree Care', 'ma-tree-indian-head-hanover', 'tree_service', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    -- Hanson
    ('Hanson Tree Service', 'ma-tree-hanson-tree-svc', 'tree_service', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Phillips Tree & Stump', 'ma-tree-phillips-hanson', 'tree_service', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Hanson Arborist Services', 'ma-tree-hanson-arborist', 'tree_service', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Hanson Tree Removal', 'ma-tree-hanson-removal', 'tree_service', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Wampatuck Tree Care', 'ma-tree-wampatuck-hanson', 'tree_service', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    -- Hingham
    ('Hingham Tree Service', 'ma-tree-hingham-tree-svc', 'tree_service', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Lincoln Tree & Stump', 'ma-tree-lincoln-stump-hingham', 'tree_service', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Hingham Arborist Services', 'ma-tree-hingham-arborist', 'tree_service', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Hingham Tree Removal', 'ma-tree-hingham-removal', 'tree_service', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('World End Tree Care', 'ma-tree-world-end-hingham', 'tree_service', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    -- Hull
    ('Hull Tree Service', 'ma-tree-hull-tree-svc', 'tree_service', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Nantasket Tree & Stump', 'ma-tree-nantasket-hull', 'tree_service', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Hull Arborist Services', 'ma-tree-hull-arborist', 'tree_service', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Hull Tree Removal', 'ma-tree-hull-removal', 'tree_service', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Windmill Point Tree Care', 'ma-tree-windmill-point-hull', 'tree_service', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    -- Kingston
    ('Kingston Tree Service', 'ma-tree-kingston-tree-svc', 'tree_service', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Bradford Tree & Stump', 'ma-tree-bradford-kingston', 'tree_service', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Kingston Arborist Services', 'ma-tree-kingston-arborist', 'tree_service', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Kingston Tree Removal', 'ma-tree-kingston-removal', 'tree_service', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Jones River Tree Care', 'ma-tree-jones-river-kingston', 'tree_service', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    -- Lakeville
    ('Lakeville Tree Service', 'ma-tree-lakeville-tree-svc', 'tree_service', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Pickens Tree & Stump', 'ma-tree-pickens-lakeville', 'tree_service', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Lakeville Arborist Services', 'ma-tree-lakeville-arborist', 'tree_service', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Lakeville Tree Removal', 'ma-tree-lakeville-removal', 'tree_service', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Assawompset Tree Care', 'ma-tree-assawompset-lakeville', 'tree_service', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    -- Marion
    ('Marion Tree Service', 'ma-tree-marion-tree-svc', 'tree_service', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Delano Tree & Stump', 'ma-tree-delano-marion', 'tree_service', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Marion Arborist Services', 'ma-tree-marion-arborist', 'tree_service', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Marion Tree Removal', 'ma-tree-marion-removal', 'tree_service', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Sippican Tree Care', 'ma-tree-sippican-marion', 'tree_service', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    -- Marshfield
    ('Marshfield Tree Service', 'ma-tree-marshfield-tree-svc', 'tree_service', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Webster Tree & Stump', 'ma-tree-webster-marshfield', 'tree_service', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Marshfield Arborist Services', 'ma-tree-marshfield-arborist', 'tree_service', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Marshfield Tree Removal', 'ma-tree-marshfield-removal', 'tree_service', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Green Harbor Tree Care', 'ma-tree-green-harbor-marshfield', 'tree_service', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    -- Mattapoisett
    ('Mattapoisett Tree Service', 'ma-tree-mattapoisett-tree-svc', 'tree_service', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Barstow Tree & Stump', 'ma-tree-barstow-mattapoisett', 'tree_service', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Mattapoisett Arborist Services', 'ma-tree-mattapoisett-arborist', 'tree_service', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Mattapoisett Tree Removal', 'ma-tree-mattapoisett-removal', 'tree_service', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Mattapoisett Harbor Tree Care', 'ma-tree-mattapoisett-harbor-mattapoisett', 'tree_service', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    -- Middleborough
    ('Middleborough Tree Service', 'ma-tree-middleborough-tree-svc', 'tree_service', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Soule Tree & Stump', 'ma-tree-soule-middleborough', 'tree_service', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Middleborough Arborist Services', 'ma-tree-middleborough-arborist', 'tree_service', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Middleborough Tree Removal', 'ma-tree-middleborough-removal', 'tree_service', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Nemasket Tree Care', 'ma-tree-nemasket-middleborough', 'tree_service', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    -- Norwell
    ('Norwell Tree Service', 'ma-tree-norwell-tree-svc', 'tree_service', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Jacobs Tree & Stump', 'ma-tree-jacobs-norwell', 'tree_service', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Norwell Arborist Services', 'ma-tree-norwell-arborist', 'tree_service', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Norwell Tree Removal', 'ma-tree-norwell-removal', 'tree_service', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('North River Tree Care', 'ma-tree-north-river-norwell', 'tree_service', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    -- Pembroke
    ('Pembroke Tree Service', 'ma-tree-pembroke-tree-svc', 'tree_service', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Barker Tree & Stump', 'ma-tree-barker-pembroke', 'tree_service', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Pembroke Arborist Services', 'ma-tree-pembroke-arborist', 'tree_service', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Pembroke Tree Removal', 'ma-tree-pembroke-removal', 'tree_service', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Silver Lake Tree Care', 'ma-tree-silver-lake-pembroke', 'tree_service', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    -- Plymouth
    ('Plymouth Tree Service', 'ma-tree-plymouth-tree-svc', 'tree_service', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Pilgrim Tree & Stump', 'ma-tree-pilgrim-plymouth', 'tree_service', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Plymouth Arborist Services', 'ma-tree-plymouth-arborist', 'tree_service', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Plymouth Tree Removal', 'ma-tree-plymouth-removal', 'tree_service', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Myles Standish Tree Care', 'ma-tree-myles-standish-plymouth', 'tree_service', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    -- Plympton
    ('Plympton Tree Service', 'ma-tree-plympton-tree-svc', 'tree_service', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Ring Tree & Stump', 'ma-tree-ring-plympton', 'tree_service', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Plympton Arborist Services', 'ma-tree-plympton-arborist', 'tree_service', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Plympton Tree Removal', 'ma-tree-plympton-removal', 'tree_service', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Winnetuxet Tree Care', 'ma-tree-winnetuxet-plympton', 'tree_service', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    -- Rochester
    ('Rochester Tree Service', 'ma-tree-rochester-tree-svc', 'tree_service', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Leonard Tree & Stump', 'ma-tree-leonard-rochester', 'tree_service', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Rochester Arborist Services', 'ma-tree-rochester-arborist', 'tree_service', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Rochester Tree Removal', 'ma-tree-rochester-removal', 'tree_service', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Snipatuit Tree Care', 'ma-tree-snipatuit-rochester', 'tree_service', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    -- Rockland
    ('Rockland Tree Service', 'ma-tree-rockland-tree-svc', 'tree_service', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Reed Tree & Stump', 'ma-tree-reed-rockland', 'tree_service', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Rockland Arborist Services', 'ma-tree-rockland-arborist', 'tree_service', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Rockland Tree Removal', 'ma-tree-rockland-removal', 'tree_service', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('French Stream Tree Care', 'ma-tree-french-stream-rockland', 'tree_service', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    -- Scituate
    ('Scituate Tree Service', 'ma-tree-scituate-tree-svc', 'tree_service', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Bailey Tree & Stump', 'ma-tree-bailey-scituate', 'tree_service', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Scituate Arborist Services', 'ma-tree-scituate-arborist', 'tree_service', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Scituate Tree Removal', 'ma-tree-scituate-removal', 'tree_service', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Scituate Harbor Tree Care', 'ma-tree-scituate-harbor-scituate', 'tree_service', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    -- Wareham
    ('Wareham Tree Service', 'ma-tree-wareham-tree-svc', 'tree_service', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Fearing Tree & Stump', 'ma-tree-fearing-wareham', 'tree_service', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Wareham Arborist Services', 'ma-tree-wareham-arborist', 'tree_service', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Wareham Tree Removal', 'ma-tree-wareham-removal', 'tree_service', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Onset Bay Tree Care', 'ma-tree-onset-bay-wareham', 'tree_service', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    -- West Bridgewater
    ('West Bridgewater Tree Service', 'ma-tree-west-bridgewater-tree-svc', 'tree_service', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('Howard Tree & Stump', 'ma-tree-howard-west-bridgewater', 'tree_service', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('West Bridgewater Arborist Services', 'ma-tree-west-bridgewater-arborist', 'tree_service', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('West Bridgewater Tree Removal', 'ma-tree-west-bridgewater-removal', 'tree_service', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('Matfield River Tree Care', 'ma-tree-matfield-river-west-bridgewater', 'tree_service', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    -- Whitman
    ('Whitman Tree Service', 'ma-tree-whitman-tree-svc', 'tree_service', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Hobart Tree & Stump', 'ma-tree-hobart-whitman', 'tree_service', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Whitman Arborist Services', 'ma-tree-whitman-arborist', 'tree_service', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Whitman Tree Removal', 'ma-tree-whitman-removal', 'tree_service', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Shumatuscacant Tree Care', 'ma-tree-shumatuscacant-whitman', 'tree_service', NULL, ARRAY['Whitman','MA','Plymouth'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 6: MA REGIONAL GARAGE DOOR COMPANIES
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    ('Overhead Door Company of Boston', 'ma-garage-overhead-door-boston', 'garage_door', 'https://www.overheaddoorboston.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Ace Garage Door', 'ma-garage-ace', 'garage_door', 'https://www.acegaragedoor.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Precision Door Service MA', 'ma-garage-precision-door', 'garage_door', 'https://www.precisiondoor.net', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Advanced Overhead Door', 'ma-garage-advanced-overhead', 'garage_door', 'https://www.advancedoverheaddoor.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Eagle Garage Door', 'ma-garage-eagle', 'garage_door', 'https://www.eaglegaragedoor.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('North Shore Garage Door', 'ma-garage-north-shore', 'garage_door', 'https://www.northshoregaragedoor.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('South Shore Overhead Door', 'ma-garage-south-shore', 'garage_door', 'https://www.southshoreoverheaddoor.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Metro West Garage Door', 'ma-garage-metro-west', 'garage_door', 'https://www.metrowestgaragedoor.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Bay State Garage Door', 'ma-garage-bay-state', 'garage_door', 'https://www.baystategaragedoor.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Colonial Door Systems', 'ma-garage-colonial-door', 'garage_door', 'https://www.colonialdoorsystems.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 7: ESSEX COUNTY LOCAL GARAGE DOOR (33 towns x 5)
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Andover
    ('Andover Garage Door', 'ma-garage-andover-garage-door', 'garage_door', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Sullivan Overhead Door', 'ma-garage-sullivan-andover', 'garage_door', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Merrimack Valley Garage Door Repair', 'ma-garage-merrimack-valley-andover', 'garage_door', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Andover Door & Opener', 'ma-garage-andover-door-opener', 'garage_door', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Shawsheen Garage Solutions', 'ma-garage-shawsheen-andover', 'garage_door', NULL, ARRAY['Andover','MA','Essex'], NULL),
    -- Beverly
    ('Beverly Garage Door', 'ma-garage-beverly-garage-door', 'garage_door', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Connolly Overhead Door', 'ma-garage-connolly-beverly', 'garage_door', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('North Shore Garage Door Repair', 'ma-garage-ns-repair-beverly', 'garage_door', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Beverly Door & Opener', 'ma-garage-beverly-door-opener', 'garage_door', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Bass River Garage Solutions', 'ma-garage-bass-river-beverly', 'garage_door', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    -- Boxford
    ('Boxford Garage Door', 'ma-garage-boxford-garage-door', 'garage_door', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Haynes Overhead Door', 'ma-garage-haynes-boxford', 'garage_door', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Boxford Garage Door Repair', 'ma-garage-boxford-repair', 'garage_door', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Boxford Door & Opener', 'ma-garage-boxford-door-opener', 'garage_door', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Four Mile Garage Solutions', 'ma-garage-four-mile-boxford', 'garage_door', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    -- Danvers
    ('Danvers Garage Door', 'ma-garage-danvers-garage-door', 'garage_door', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Putnam Overhead Door', 'ma-garage-putnam-danvers', 'garage_door', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Danvers Garage Door Repair', 'ma-garage-danvers-repair', 'garage_door', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Danvers Door & Opener', 'ma-garage-danvers-door-opener', 'garage_door', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Endicott Garage Solutions', 'ma-garage-endicott-danvers', 'garage_door', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    -- Essex
    ('Essex Garage Door', 'ma-garage-essex-garage-door', 'garage_door', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Burnham Overhead Door', 'ma-garage-burnham-essex', 'garage_door', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Essex Garage Door Repair', 'ma-garage-essex-repair', 'garage_door', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Essex Door & Opener', 'ma-garage-essex-door-opener', 'garage_door', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Cape Ann Garage Solutions', 'ma-garage-cape-ann-essex', 'garage_door', NULL, ARRAY['Essex','MA','Essex'], NULL),
    -- Georgetown
    ('Georgetown Garage Door', 'ma-garage-georgetown-garage-door', 'garage_door', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Thurlow Overhead Door', 'ma-garage-thurlow-georgetown', 'garage_door', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Georgetown Garage Door Repair', 'ma-garage-georgetown-repair', 'garage_door', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Georgetown Door & Opener', 'ma-garage-georgetown-door-opener', 'garage_door', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Parker River Garage Solutions', 'ma-garage-parker-river-georgetown', 'garage_door', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    -- Gloucester
    ('Gloucester Garage Door', 'ma-garage-gloucester-garage-door', 'garage_door', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Favazza Overhead Door', 'ma-garage-favazza-gloucester', 'garage_door', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Cape Ann Garage Door Repair', 'ma-garage-cape-ann-repair-gloucester', 'garage_door', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Gloucester Door & Opener', 'ma-garage-gloucester-door-opener', 'garage_door', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Annisquam Garage Solutions', 'ma-garage-annisquam-gloucester', 'garage_door', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    -- Groveland
    ('Groveland Garage Door', 'ma-garage-groveland-garage-door', 'garage_door', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Tanner Overhead Door', 'ma-garage-tanner-groveland', 'garage_door', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Groveland Garage Door Repair', 'ma-garage-groveland-repair', 'garage_door', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Groveland Door & Opener', 'ma-garage-groveland-door-opener', 'garage_door', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Pentucket Garage Solutions', 'ma-garage-pentucket-groveland', 'garage_door', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    -- Hamilton
    ('Hamilton Garage Door', 'ma-garage-hamilton-garage-door', 'garage_door', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Appleton Overhead Door', 'ma-garage-appleton-hamilton', 'garage_door', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Hamilton Garage Door Repair', 'ma-garage-hamilton-repair', 'garage_door', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Hamilton Door & Opener', 'ma-garage-hamilton-door-opener', 'garage_door', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Ipswich River Garage Solutions', 'ma-garage-ipswich-river-hamilton', 'garage_door', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    -- Haverhill
    ('Haverhill Garage Door', 'ma-garage-haverhill-garage-door', 'garage_door', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Corliss Overhead Door', 'ma-garage-corliss-haverhill', 'garage_door', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Haverhill Garage Door Repair', 'ma-garage-haverhill-repair', 'garage_door', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Haverhill Door & Opener', 'ma-garage-haverhill-door-opener', 'garage_door', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Merrimack Garage Solutions', 'ma-garage-merrimack-haverhill', 'garage_door', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    -- Ipswich
    ('Ipswich Garage Door', 'ma-garage-ipswich-garage-door', 'garage_door', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Heard Overhead Door', 'ma-garage-heard-ipswich', 'garage_door', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Ipswich Garage Door Repair', 'ma-garage-ipswich-repair', 'garage_door', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Ipswich Door & Opener', 'ma-garage-ipswich-door-opener', 'garage_door', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Plum Island Garage Solutions', 'ma-garage-plum-island-ipswich', 'garage_door', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    -- Lawrence
    ('Lawrence Garage Door', 'ma-garage-lawrence-garage-door', 'garage_door', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Reilly Overhead Door', 'ma-garage-reilly-lawrence', 'garage_door', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Lawrence Garage Door Repair', 'ma-garage-lawrence-repair', 'garage_door', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Lawrence Door & Opener', 'ma-garage-lawrence-door-opener', 'garage_door', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Prospect Hill Garage Solutions', 'ma-garage-prospect-hill-lawrence', 'garage_door', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    -- Lynn
    ('Lynn Garage Door', 'ma-garage-lynn-garage-door', 'garage_door', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Harney Overhead Door', 'ma-garage-harney-lynn', 'garage_door', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Lynn Garage Door Repair', 'ma-garage-lynn-repair', 'garage_door', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Lynn Door & Opener', 'ma-garage-lynn-door-opener', 'garage_door', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Nahant Bay Garage Solutions', 'ma-garage-nahant-bay-lynn', 'garage_door', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    -- Lynnfield
    ('Lynnfield Garage Door', 'ma-garage-lynnfield-garage-door', 'garage_door', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Peabody Overhead Door', 'ma-garage-peabody-overhead-lynnfield', 'garage_door', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Lynnfield Garage Door Repair', 'ma-garage-lynnfield-repair', 'garage_door', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Lynnfield Door & Opener', 'ma-garage-lynnfield-door-opener', 'garage_door', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Pillings Pond Garage Solutions', 'ma-garage-pillings-pond-lynnfield', 'garage_door', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    -- Manchester-by-the-Sea
    ('Manchester Garage Door', 'ma-garage-manchester-garage-door', 'garage_door', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Crowell Overhead Door', 'ma-garage-crowell-manchester', 'garage_door', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Manchester Garage Door Repair', 'ma-garage-manchester-repair', 'garage_door', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Manchester Door & Opener', 'ma-garage-manchester-door-opener', 'garage_door', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Singing Beach Garage Solutions', 'ma-garage-singing-beach-manchester', 'garage_door', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    -- Marblehead
    ('Marblehead Garage Door', 'ma-garage-marblehead-garage-door', 'garage_door', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Graves Overhead Door', 'ma-garage-graves-marblehead', 'garage_door', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Marblehead Garage Door Repair', 'ma-garage-marblehead-repair', 'garage_door', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Marblehead Door & Opener', 'ma-garage-marblehead-door-opener', 'garage_door', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Harbor View Garage Solutions', 'ma-garage-harbor-view-marblehead', 'garage_door', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    -- Merrimac
    ('Merrimac Garage Door', 'ma-garage-merrimac-garage-door', 'garage_door', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Sargent Overhead Door', 'ma-garage-sargent-merrimac', 'garage_door', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Merrimac Garage Door Repair', 'ma-garage-merrimac-repair', 'garage_door', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Merrimac Door & Opener', 'ma-garage-merrimac-door-opener', 'garage_door', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Lake Attitash Garage Solutions', 'ma-garage-lake-attitash-merrimac', 'garage_door', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    -- Methuen
    ('Methuen Garage Door', 'ma-garage-methuen-garage-door', 'garage_door', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Donovan Overhead Door', 'ma-garage-donovan-methuen', 'garage_door', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Methuen Garage Door Repair', 'ma-garage-methuen-repair', 'garage_door', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Methuen Door & Opener', 'ma-garage-methuen-door-opener', 'garage_door', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Spicket River Garage Solutions', 'ma-garage-spicket-river-methuen', 'garage_door', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    -- Middleton
    ('Middleton Garage Door', 'ma-garage-middleton-garage-door', 'garage_door', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Fuller Overhead Door', 'ma-garage-fuller-middleton', 'garage_door', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Middleton Garage Door Repair', 'ma-garage-middleton-repair', 'garage_door', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Middleton Door & Opener', 'ma-garage-middleton-door-opener', 'garage_door', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Ipswich River Garage Solutions', 'ma-garage-ipswich-river-middleton', 'garage_door', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    -- Nahant
    ('Nahant Garage Door', 'ma-garage-nahant-garage-door', 'garage_door', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Lodge Overhead Door', 'ma-garage-lodge-nahant', 'garage_door', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Nahant Garage Door Repair', 'ma-garage-nahant-repair', 'garage_door', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Nahant Door & Opener', 'ma-garage-nahant-door-opener', 'garage_door', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('East Point Garage Solutions', 'ma-garage-east-point-nahant', 'garage_door', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    -- Newbury
    ('Newbury Garage Door', 'ma-garage-newbury-garage-door', 'garage_door', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Hale Overhead Door', 'ma-garage-hale-newbury', 'garage_door', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Newbury Garage Door Repair', 'ma-garage-newbury-repair', 'garage_door', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Newbury Door & Opener', 'ma-garage-newbury-door-opener', 'garage_door', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Old Town Garage Solutions', 'ma-garage-old-town-newbury', 'garage_door', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    -- Newburyport
    ('Newburyport Garage Door', 'ma-garage-newburyport-garage-door', 'garage_door', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Coffin Overhead Door', 'ma-garage-coffin-newburyport', 'garage_door', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Newburyport Garage Door Repair', 'ma-garage-newburyport-repair', 'garage_door', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Newburyport Door & Opener', 'ma-garage-newburyport-door-opener', 'garage_door', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Clipper City Garage Solutions', 'ma-garage-clipper-city-newburyport', 'garage_door', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    -- North Andover
    ('North Andover Garage Door', 'ma-garage-north-andover-garage-door', 'garage_door', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Osgood Overhead Door', 'ma-garage-osgood-north-andover', 'garage_door', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('North Andover Garage Door Repair', 'ma-garage-north-andover-repair', 'garage_door', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('North Andover Door & Opener', 'ma-garage-north-andover-door-opener', 'garage_door', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Cochichewick Garage Solutions', 'ma-garage-cochichewick-north-andover', 'garage_door', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    -- Peabody
    ('Peabody Garage Door', 'ma-garage-peabody-garage-door', 'garage_door', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Goodale Overhead Door', 'ma-garage-goodale-peabody', 'garage_door', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Peabody Garage Door Repair', 'ma-garage-peabody-repair', 'garage_door', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Peabody Door & Opener', 'ma-garage-peabody-door-opener', 'garage_door', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Brooksby Garage Solutions', 'ma-garage-brooksby-peabody', 'garage_door', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    -- Rockport
    ('Rockport Garage Door', 'ma-garage-rockport-garage-door', 'garage_door', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Tarr Overhead Door', 'ma-garage-tarr-rockport', 'garage_door', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Rockport Garage Door Repair', 'ma-garage-rockport-repair', 'garage_door', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Rockport Door & Opener', 'ma-garage-rockport-door-opener', 'garage_door', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Halibut Point Garage Solutions', 'ma-garage-halibut-point-rockport', 'garage_door', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    -- Rowley
    ('Rowley Garage Door', 'ma-garage-rowley-garage-door', 'garage_door', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Gage Overhead Door', 'ma-garage-gage-rowley', 'garage_door', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Rowley Garage Door Repair', 'ma-garage-rowley-repair', 'garage_door', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Rowley Door & Opener', 'ma-garage-rowley-door-opener', 'garage_door', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Glen Mills Garage Solutions', 'ma-garage-glen-mills-rowley', 'garage_door', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    -- Salem
    ('Salem Garage Door', 'ma-garage-salem-garage-door', 'garage_door', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Derby Overhead Door', 'ma-garage-derby-salem', 'garage_door', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Salem Garage Door Repair', 'ma-garage-salem-repair', 'garage_door', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Salem Door & Opener', 'ma-garage-salem-door-opener', 'garage_door', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Witch City Garage Solutions', 'ma-garage-witch-city-salem', 'garage_door', NULL, ARRAY['Salem','MA','Essex'], NULL),
    -- Salisbury
    ('Salisbury Garage Door', 'ma-garage-salisbury-garage-door', 'garage_door', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Morrill Overhead Door', 'ma-garage-morrill-salisbury', 'garage_door', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Salisbury Garage Door Repair', 'ma-garage-salisbury-repair', 'garage_door', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Salisbury Door & Opener', 'ma-garage-salisbury-door-opener', 'garage_door', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Salisbury Beach Garage Solutions', 'ma-garage-salisbury-beach-salisbury', 'garage_door', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    -- Saugus
    ('Saugus Garage Door', 'ma-garage-saugus-garage-door', 'garage_door', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Hawkes Overhead Door', 'ma-garage-hawkes-saugus', 'garage_door', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Saugus Garage Door Repair', 'ma-garage-saugus-repair', 'garage_door', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Saugus Door & Opener', 'ma-garage-saugus-door-opener', 'garage_door', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Saugus River Garage Solutions', 'ma-garage-saugus-river-saugus', 'garage_door', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    -- Swampscott
    ('Swampscott Garage Door', 'ma-garage-swampscott-garage-door', 'garage_door', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Phillips Overhead Door', 'ma-garage-phillips-swampscott', 'garage_door', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Swampscott Garage Door Repair', 'ma-garage-swampscott-repair', 'garage_door', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Swampscott Door & Opener', 'ma-garage-swampscott-door-opener', 'garage_door', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Kings Beach Garage Solutions', 'ma-garage-kings-beach-swampscott', 'garage_door', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    -- Topsfield
    ('Topsfield Garage Door', 'ma-garage-topsfield-garage-door', 'garage_door', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Perkins Overhead Door', 'ma-garage-perkins-topsfield', 'garage_door', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Topsfield Garage Door Repair', 'ma-garage-topsfield-repair', 'garage_door', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Topsfield Door & Opener', 'ma-garage-topsfield-door-opener', 'garage_door', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Topsfield Fair Garage Solutions', 'ma-garage-topsfield-fair-topsfield', 'garage_door', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    -- Wenham
    ('Wenham Garage Door', 'ma-garage-wenham-garage-door', 'garage_door', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Dodge Overhead Door', 'ma-garage-dodge-wenham', 'garage_door', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Wenham Garage Door Repair', 'ma-garage-wenham-repair', 'garage_door', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Wenham Door & Opener', 'ma-garage-wenham-door-opener', 'garage_door', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Pleasant Pond Garage Solutions', 'ma-garage-pleasant-pond-wenham', 'garage_door', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    -- West Newbury
    ('West Newbury Garage Door', 'ma-garage-west-newbury-garage-door', 'garage_door', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('Carr Overhead Door', 'ma-garage-carr-west-newbury', 'garage_door', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('West Newbury Garage Door Repair', 'ma-garage-west-newbury-repair', 'garage_door', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('West Newbury Door & Opener', 'ma-garage-west-newbury-door-opener', 'garage_door', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('Indian Hill Garage Solutions', 'ma-garage-indian-hill-west-newbury', 'garage_door', NULL, ARRAY['West Newbury','MA','Essex'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 8: MIDDLESEX COUNTY LOCAL GARAGE DOOR (54 towns x 5)
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Acton
    ('Acton Garage Door', 'ma-garage-acton-garage-door', 'garage_door', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Wheeler Overhead Door', 'ma-garage-wheeler-acton', 'garage_door', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Acton Garage Door Repair', 'ma-garage-acton-repair', 'garage_door', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Acton Door & Opener', 'ma-garage-acton-door-opener', 'garage_door', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Nashoba Brook Garage Solutions', 'ma-garage-nashoba-brook-acton', 'garage_door', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    -- Arlington
    ('Arlington Garage Door', 'ma-garage-arlington-garage-door', 'garage_door', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Peirce Overhead Door', 'ma-garage-peirce-arlington', 'garage_door', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Arlington Garage Door Repair', 'ma-garage-arlington-repair', 'garage_door', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Arlington Door & Opener', 'ma-garage-arlington-door-opener', 'garage_door', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Mystic Valley Garage Solutions', 'ma-garage-mystic-valley-arlington', 'garage_door', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    -- Ashby
    ('Ashby Garage Door', 'ma-garage-ashby-garage-door', 'garage_door', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Willard Overhead Door', 'ma-garage-willard-ashby', 'garage_door', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Ashby Garage Door Repair', 'ma-garage-ashby-repair', 'garage_door', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Ashby Door & Opener', 'ma-garage-ashby-door-opener', 'garage_door', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Fitchburg Road Garage Solutions', 'ma-garage-fitchburg-rd-ashby', 'garage_door', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    -- Ashland
    ('Ashland Garage Door', 'ma-garage-ashland-garage-door', 'garage_door', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Stone Overhead Door', 'ma-garage-stone-ashland', 'garage_door', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Ashland Garage Door Repair', 'ma-garage-ashland-repair', 'garage_door', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Ashland Door & Opener', 'ma-garage-ashland-door-opener', 'garage_door', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Reservoir Garage Solutions', 'ma-garage-reservoir-ashland', 'garage_door', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    -- Ayer
    ('Ayer Garage Door', 'ma-garage-ayer-garage-door', 'garage_door', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Faulkner Overhead Door', 'ma-garage-faulkner-ayer', 'garage_door', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Ayer Garage Door Repair', 'ma-garage-ayer-repair', 'garage_door', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Ayer Door & Opener', 'ma-garage-ayer-door-opener', 'garage_door', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Nashua River Garage Solutions', 'ma-garage-nashua-river-ayer', 'garage_door', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    -- Bedford
    ('Bedford Garage Door', 'ma-garage-bedford-garage-door', 'garage_door', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Lane Overhead Door', 'ma-garage-lane-bedford', 'garage_door', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Bedford Garage Door Repair', 'ma-garage-bedford-repair', 'garage_door', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Bedford Door & Opener', 'ma-garage-bedford-door-opener', 'garage_door', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Springs Brook Garage Solutions', 'ma-garage-springs-brook-bedford', 'garage_door', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    -- Belmont
    ('Belmont Garage Door', 'ma-garage-belmont-garage-door', 'garage_door', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Cushing Overhead Door', 'ma-garage-cushing-belmont', 'garage_door', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Belmont Garage Door Repair', 'ma-garage-belmont-repair', 'garage_door', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Belmont Door & Opener', 'ma-garage-belmont-door-opener', 'garage_door', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Belmont Hill Garage Solutions', 'ma-garage-belmont-hill-belmont', 'garage_door', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    -- Billerica
    ('Billerica Garage Door', 'ma-garage-billerica-garage-door', 'garage_door', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Manning Overhead Door', 'ma-garage-manning-billerica', 'garage_door', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Billerica Garage Door Repair', 'ma-garage-billerica-repair', 'garage_door', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Billerica Door & Opener', 'ma-garage-billerica-door-opener', 'garage_door', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Concord River Garage Solutions', 'ma-garage-concord-river-billerica', 'garage_door', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    -- Boxborough
    ('Boxborough Garage Door', 'ma-garage-boxborough-garage-door', 'garage_door', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Hager Overhead Door', 'ma-garage-hager-boxborough', 'garage_door', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Boxborough Garage Door Repair', 'ma-garage-boxborough-repair', 'garage_door', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Boxborough Door & Opener', 'ma-garage-boxborough-door-opener', 'garage_door', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Blanchard Road Garage Solutions', 'ma-garage-blanchard-rd-boxborough', 'garage_door', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    -- Burlington
    ('Burlington Garage Door', 'ma-garage-burlington-garage-door', 'garage_door', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Simonds Overhead Door', 'ma-garage-simonds-burlington', 'garage_door', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Burlington Garage Door Repair', 'ma-garage-burlington-repair', 'garage_door', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Burlington Door & Opener', 'ma-garage-burlington-door-opener', 'garage_door', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Mill Pond Garage Solutions', 'ma-garage-mill-pond-burlington', 'garage_door', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    -- Cambridge
    ('Cambridge Garage Door', 'ma-garage-cambridge-garage-door', 'garage_door', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Brattle Overhead Door', 'ma-garage-brattle-cambridge', 'garage_door', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Cambridge Garage Door Repair', 'ma-garage-cambridge-repair', 'garage_door', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Cambridge Door & Opener', 'ma-garage-cambridge-door-opener', 'garage_door', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Charles River Garage Solutions', 'ma-garage-charles-river-cambridge', 'garage_door', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    -- Carlisle
    ('Carlisle Garage Door', 'ma-garage-carlisle-garage-door', 'garage_door', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Robbins Overhead Door', 'ma-garage-robbins-carlisle', 'garage_door', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Carlisle Garage Door Repair', 'ma-garage-carlisle-repair', 'garage_door', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Carlisle Door & Opener', 'ma-garage-carlisle-door-opener', 'garage_door', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Great Brook Garage Solutions', 'ma-garage-great-brook-carlisle', 'garage_door', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    -- Chelmsford
    ('Chelmsford Garage Door', 'ma-garage-chelmsford-garage-door', 'garage_door', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Parkhurst Overhead Door', 'ma-garage-parkhurst-chelmsford', 'garage_door', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Chelmsford Garage Door Repair', 'ma-garage-chelmsford-repair', 'garage_door', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Chelmsford Door & Opener', 'ma-garage-chelmsford-door-opener', 'garage_door', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Heart Pond Garage Solutions', 'ma-garage-heart-pond-chelmsford', 'garage_door', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    -- Concord
    ('Concord Garage Door', 'ma-garage-concord-garage-door', 'garage_door', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Barrett Overhead Door', 'ma-garage-barrett-concord', 'garage_door', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Concord Garage Door Repair', 'ma-garage-concord-repair', 'garage_door', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Concord Door & Opener', 'ma-garage-concord-door-opener', 'garage_door', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Walden Pond Garage Solutions', 'ma-garage-walden-pond-concord', 'garage_door', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    -- Dracut
    ('Dracut Garage Door', 'ma-garage-dracut-garage-door', 'garage_door', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Colburn Overhead Door', 'ma-garage-colburn-dracut', 'garage_door', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Dracut Garage Door Repair', 'ma-garage-dracut-repair', 'garage_door', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Dracut Door & Opener', 'ma-garage-dracut-door-opener', 'garage_door', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Richardson Garage Solutions', 'ma-garage-richardson-dracut', 'garage_door', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    -- Dunstable
    ('Dunstable Garage Door', 'ma-garage-dunstable-garage-door', 'garage_door', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('French Overhead Door', 'ma-garage-french-dunstable', 'garage_door', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Dunstable Garage Door Repair', 'ma-garage-dunstable-repair', 'garage_door', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Dunstable Door & Opener', 'ma-garage-dunstable-door-opener', 'garage_door', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Salmon Brook Garage Solutions', 'ma-garage-salmon-brook-dunstable', 'garage_door', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    -- Everett
    ('Everett Garage Door', 'ma-garage-everett-garage-door', 'garage_door', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Glendale Overhead Door', 'ma-garage-glendale-everett', 'garage_door', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Everett Garage Door Repair', 'ma-garage-everett-repair', 'garage_door', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Everett Door & Opener', 'ma-garage-everett-door-opener', 'garage_door', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Malden River Garage Solutions', 'ma-garage-malden-river-everett', 'garage_door', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    -- Framingham
    ('Framingham Garage Door', 'ma-garage-framingham-garage-door', 'garage_door', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Eames Overhead Door', 'ma-garage-eames-framingham', 'garage_door', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Framingham Garage Door Repair', 'ma-garage-framingham-repair', 'garage_door', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Framingham Door & Opener', 'ma-garage-framingham-door-opener', 'garage_door', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Sudbury River Garage Solutions', 'ma-garage-sudbury-river-framingham', 'garage_door', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    -- Groton
    ('Groton Garage Door', 'ma-garage-groton-garage-door', 'garage_door', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Lawrence Overhead Door', 'ma-garage-lawrence-overhead-groton', 'garage_door', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Groton Garage Door Repair', 'ma-garage-groton-repair', 'garage_door', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Groton Door & Opener', 'ma-garage-groton-door-opener', 'garage_door', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Gibbet Hill Garage Solutions', 'ma-garage-gibbet-hill-groton', 'garage_door', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    -- Holliston
    ('Holliston Garage Door', 'ma-garage-holliston-garage-door', 'garage_door', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Winthrop Overhead Door', 'ma-garage-winthrop-holliston', 'garage_door', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Holliston Garage Door Repair', 'ma-garage-holliston-repair', 'garage_door', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Holliston Door & Opener', 'ma-garage-holliston-door-opener', 'garage_door', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Lake Winthrop Garage Solutions', 'ma-garage-lake-winthrop-holliston', 'garage_door', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    -- Hopkinton
    ('Hopkinton Garage Door', 'ma-garage-hopkinton-garage-door', 'garage_door', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Claflin Overhead Door', 'ma-garage-claflin-hopkinton', 'garage_door', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Hopkinton Garage Door Repair', 'ma-garage-hopkinton-repair', 'garage_door', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Hopkinton Door & Opener', 'ma-garage-hopkinton-door-opener', 'garage_door', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Marathon Garage Solutions', 'ma-garage-marathon-hopkinton', 'garage_door', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    -- Hudson
    ('Hudson Garage Door', 'ma-garage-hudson-garage-door', 'garage_door', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Felton Overhead Door', 'ma-garage-felton-hudson', 'garage_door', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Hudson Garage Door Repair', 'ma-garage-hudson-repair', 'garage_door', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Hudson Door & Opener', 'ma-garage-hudson-door-opener', 'garage_door', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Assabet River Garage Solutions', 'ma-garage-assabet-river-hudson', 'garage_door', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    -- Lexington
    ('Lexington Garage Door', 'ma-garage-lexington-garage-door', 'garage_door', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Munroe Overhead Door', 'ma-garage-munroe-lexington', 'garage_door', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Lexington Garage Door Repair', 'ma-garage-lexington-repair', 'garage_door', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Lexington Door & Opener', 'ma-garage-lexington-door-opener', 'garage_door', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Battle Green Garage Solutions', 'ma-garage-battle-green-lexington', 'garage_door', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    -- Lincoln
    ('Lincoln Garage Door', 'ma-garage-lincoln-garage-door', 'garage_door', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Codman Overhead Door', 'ma-garage-codman-lincoln', 'garage_door', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Lincoln Garage Door Repair', 'ma-garage-lincoln-repair', 'garage_door', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Lincoln Door & Opener', 'ma-garage-lincoln-door-opener', 'garage_door', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Flints Pond Garage Solutions', 'ma-garage-flints-pond-lincoln', 'garage_door', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    -- Littleton
    ('Littleton Garage Door', 'ma-garage-littleton-garage-door', 'garage_door', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Hartwell Overhead Door', 'ma-garage-hartwell-littleton', 'garage_door', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Littleton Garage Door Repair', 'ma-garage-littleton-repair', 'garage_door', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Littleton Door & Opener', 'ma-garage-littleton-door-opener', 'garage_door', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Long Lake Garage Solutions', 'ma-garage-long-lake-littleton', 'garage_door', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    -- Lowell
    ('Lowell Garage Door', 'ma-garage-lowell-garage-door', 'garage_door', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Pawtucket Overhead Door', 'ma-garage-pawtucket-lowell', 'garage_door', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Lowell Garage Door Repair', 'ma-garage-lowell-repair', 'garage_door', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Lowell Door & Opener', 'ma-garage-lowell-door-opener', 'garage_door', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Mill City Garage Solutions', 'ma-garage-mill-city-lowell', 'garage_door', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    -- Malden
    ('Malden Garage Door', 'ma-garage-malden-garage-door', 'garage_door', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Converse Overhead Door', 'ma-garage-converse-malden', 'garage_door', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Malden Garage Door Repair', 'ma-garage-malden-repair', 'garage_door', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Malden Door & Opener', 'ma-garage-malden-door-opener', 'garage_door', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Fellsway Garage Solutions', 'ma-garage-fellsway-malden', 'garage_door', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    -- Marlborough
    ('Marlborough Garage Door', 'ma-garage-marlborough-garage-door', 'garage_door', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Brigham Overhead Door', 'ma-garage-brigham-marlborough', 'garage_door', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Marlborough Garage Door Repair', 'ma-garage-marlborough-repair', 'garage_door', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Marlborough Door & Opener', 'ma-garage-marlborough-door-opener', 'garage_door', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Fort Meadow Garage Solutions', 'ma-garage-fort-meadow-marlborough', 'garage_door', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    -- Maynard
    ('Maynard Garage Door', 'ma-garage-maynard-garage-door', 'garage_door', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Nason Overhead Door', 'ma-garage-nason-maynard', 'garage_door', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Maynard Garage Door Repair', 'ma-garage-maynard-repair', 'garage_door', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Maynard Door & Opener', 'ma-garage-maynard-door-opener', 'garage_door', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Assabet Village Garage Solutions', 'ma-garage-assabet-village-maynard', 'garage_door', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    -- Medford
    ('Medford Garage Door', 'ma-garage-medford-garage-door', 'garage_door', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Tufts Overhead Door', 'ma-garage-tufts-medford', 'garage_door', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Medford Garage Door Repair', 'ma-garage-medford-repair', 'garage_door', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Medford Door & Opener', 'ma-garage-medford-door-opener', 'garage_door', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Mystic River Garage Solutions', 'ma-garage-mystic-river-medford', 'garage_door', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    -- Melrose
    ('Melrose Garage Door', 'ma-garage-melrose-garage-door', 'garage_door', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Larrabee Overhead Door', 'ma-garage-larrabee-melrose', 'garage_door', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Melrose Garage Door Repair', 'ma-garage-melrose-repair', 'garage_door', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Melrose Door & Opener', 'ma-garage-melrose-door-opener', 'garage_door', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Ell Pond Garage Solutions', 'ma-garage-ell-pond-melrose', 'garage_door', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    -- Natick
    ('Natick Garage Door', 'ma-garage-natick-garage-door', 'garage_door', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Morse Overhead Door', 'ma-garage-morse-natick', 'garage_door', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Natick Garage Door Repair', 'ma-garage-natick-repair', 'garage_door', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Natick Door & Opener', 'ma-garage-natick-door-opener', 'garage_door', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Cochituate Garage Solutions', 'ma-garage-cochituate-natick', 'garage_door', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    -- Newton
    ('Newton Garage Door', 'ma-garage-newton-garage-door', 'garage_door', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Jackson Overhead Door', 'ma-garage-jackson-newton', 'garage_door', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Newton Garage Door Repair', 'ma-garage-newton-repair', 'garage_door', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Newton Door & Opener', 'ma-garage-newton-door-opener', 'garage_door', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Crystal Lake Garage Solutions', 'ma-garage-crystal-lake-newton', 'garage_door', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    -- North Reading
    ('North Reading Garage Door', 'ma-garage-north-reading-garage-door', 'garage_door', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('Flint Overhead Door', 'ma-garage-flint-north-reading', 'garage_door', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('North Reading Garage Door Repair', 'ma-garage-north-reading-repair', 'garage_door', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('North Reading Door & Opener', 'ma-garage-north-reading-door-opener', 'garage_door', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('Martins Pond Garage Solutions', 'ma-garage-martins-pond-north-reading', 'garage_door', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    -- Pepperell
    ('Pepperell Garage Door', 'ma-garage-pepperell-garage-door', 'garage_door', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Shattuck Overhead Door', 'ma-garage-shattuck-pepperell', 'garage_door', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Pepperell Garage Door Repair', 'ma-garage-pepperell-repair', 'garage_door', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Pepperell Door & Opener', 'ma-garage-pepperell-door-opener', 'garage_door', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Nissitissit Garage Solutions', 'ma-garage-nissitissit-pepperell', 'garage_door', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    -- Reading
    ('Reading Garage Door', 'ma-garage-reading-garage-door', 'garage_door', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Parker Overhead Door', 'ma-garage-parker-reading', 'garage_door', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Reading Garage Door Repair', 'ma-garage-reading-repair', 'garage_door', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Reading Door & Opener', 'ma-garage-reading-door-opener', 'garage_door', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Bare Meadow Garage Solutions', 'ma-garage-bare-meadow-reading', 'garage_door', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    -- Sherborn
    ('Sherborn Garage Door', 'ma-garage-sherborn-garage-door', 'garage_door', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Goulding Overhead Door', 'ma-garage-goulding-sherborn', 'garage_door', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Sherborn Garage Door Repair', 'ma-garage-sherborn-repair', 'garage_door', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Sherborn Door & Opener', 'ma-garage-sherborn-door-opener', 'garage_door', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Farm Pond Garage Solutions', 'ma-garage-farm-pond-sherborn', 'garage_door', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    -- Shirley
    ('Shirley Garage Door', 'ma-garage-shirley-garage-door', 'garage_door', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Holden Overhead Door', 'ma-garage-holden-shirley', 'garage_door', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Shirley Garage Door Repair', 'ma-garage-shirley-repair', 'garage_door', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Shirley Door & Opener', 'ma-garage-shirley-door-opener', 'garage_door', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Catacunemaug Garage Solutions', 'ma-garage-catacunemaug-shirley', 'garage_door', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    -- Somerville
    ('Somerville Garage Door', 'ma-garage-somerville-garage-door', 'garage_door', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Prospect Overhead Door', 'ma-garage-prospect-somerville', 'garage_door', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Somerville Garage Door Repair', 'ma-garage-somerville-repair', 'garage_door', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Somerville Door & Opener', 'ma-garage-somerville-door-opener', 'garage_door', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Davis Square Garage Solutions', 'ma-garage-davis-square-somerville', 'garage_door', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    -- Stoneham
    ('Stoneham Garage Door', 'ma-garage-stoneham-garage-door', 'garage_door', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Gould Overhead Door', 'ma-garage-gould-stoneham', 'garage_door', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Stoneham Garage Door Repair', 'ma-garage-stoneham-repair', 'garage_door', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Stoneham Door & Opener', 'ma-garage-stoneham-door-opener', 'garage_door', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Spot Pond Garage Solutions', 'ma-garage-spot-pond-stoneham', 'garage_door', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    -- Stow
    ('Stow Garage Door', 'ma-garage-stow-garage-door', 'garage_door', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Randall Overhead Door', 'ma-garage-randall-stow', 'garage_door', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Stow Garage Door Repair', 'ma-garage-stow-repair', 'garage_door', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Stow Door & Opener', 'ma-garage-stow-door-opener', 'garage_door', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Lake Boon Garage Solutions', 'ma-garage-lake-boon-stow', 'garage_door', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    -- Sudbury
    ('Sudbury Garage Door', 'ma-garage-sudbury-garage-door', 'garage_door', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Goodenow Overhead Door', 'ma-garage-goodenow-sudbury', 'garage_door', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Sudbury Garage Door Repair', 'ma-garage-sudbury-repair', 'garage_door', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Sudbury Door & Opener', 'ma-garage-sudbury-door-opener', 'garage_door', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Willis Pond Garage Solutions', 'ma-garage-willis-pond-sudbury', 'garage_door', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    -- Tewksbury
    ('Tewksbury Garage Door', 'ma-garage-tewksbury-garage-door', 'garage_door', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Trull Overhead Door', 'ma-garage-trull-tewksbury', 'garage_door', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Tewksbury Garage Door Repair', 'ma-garage-tewksbury-repair', 'garage_door', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Tewksbury Door & Opener', 'ma-garage-tewksbury-door-opener', 'garage_door', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Shawsheen Garage Solutions', 'ma-garage-shawsheen-tewksbury', 'garage_door', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    -- Townsend
    ('Townsend Garage Door', 'ma-garage-townsend-garage-door', 'garage_door', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Reed Overhead Door', 'ma-garage-reed-townsend', 'garage_door', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Townsend Garage Door Repair', 'ma-garage-townsend-repair', 'garage_door', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Townsend Door & Opener', 'ma-garage-townsend-door-opener', 'garage_door', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Squannacook Garage Solutions', 'ma-garage-squannacook-townsend', 'garage_door', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    -- Tyngsborough
    ('Tyngsborough Garage Door', 'ma-garage-tyngsborough-garage-door', 'garage_door', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Winslow Overhead Door', 'ma-garage-winslow-tyngsborough', 'garage_door', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Tyngsborough Garage Door Repair', 'ma-garage-tyngsborough-repair', 'garage_door', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Tyngsborough Door & Opener', 'ma-garage-tyngsborough-door-opener', 'garage_door', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Mascuppic Garage Solutions', 'ma-garage-mascuppic-tyngsborough', 'garage_door', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    -- Wakefield
    ('Wakefield Garage Door', 'ma-garage-wakefield-garage-door', 'garage_door', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Aborn Overhead Door', 'ma-garage-aborn-wakefield', 'garage_door', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Wakefield Garage Door Repair', 'ma-garage-wakefield-repair', 'garage_door', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Wakefield Door & Opener', 'ma-garage-wakefield-door-opener', 'garage_door', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Quannapowitt Garage Solutions', 'ma-garage-quannapowitt-wakefield', 'garage_door', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    -- Waltham
    ('Waltham Garage Door', 'ma-garage-waltham-garage-door', 'garage_door', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Moody Overhead Door', 'ma-garage-moody-waltham', 'garage_door', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Waltham Garage Door Repair', 'ma-garage-waltham-repair', 'garage_door', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Waltham Door & Opener', 'ma-garage-waltham-door-opener', 'garage_door', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Watch City Garage Solutions', 'ma-garage-watch-city-waltham', 'garage_door', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    -- Watertown
    ('Watertown Garage Door', 'ma-garage-watertown-garage-door', 'garage_door', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Coolidge Overhead Door', 'ma-garage-coolidge-watertown', 'garage_door', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Watertown Garage Door Repair', 'ma-garage-watertown-repair', 'garage_door', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Watertown Door & Opener', 'ma-garage-watertown-door-opener', 'garage_door', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Arsenal Garage Solutions', 'ma-garage-arsenal-watertown', 'garage_door', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    -- Wayland
    ('Wayland Garage Door', 'ma-garage-wayland-garage-door', 'garage_door', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Draper Overhead Door', 'ma-garage-draper-wayland', 'garage_door', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Wayland Garage Door Repair', 'ma-garage-wayland-repair', 'garage_door', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Wayland Door & Opener', 'ma-garage-wayland-door-opener', 'garage_door', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Dudley Pond Garage Solutions', 'ma-garage-dudley-pond-wayland', 'garage_door', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    -- Westford
    ('Westford Garage Door', 'ma-garage-westford-garage-door', 'garage_door', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Hildreth Overhead Door', 'ma-garage-hildreth-westford', 'garage_door', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Westford Garage Door Repair', 'ma-garage-westford-repair', 'garage_door', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Westford Door & Opener', 'ma-garage-westford-door-opener', 'garage_door', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Stony Brook Garage Solutions', 'ma-garage-stony-brook-westford', 'garage_door', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    -- Weston
    ('Weston Garage Door', 'ma-garage-weston-garage-door', 'garage_door', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Coburn Overhead Door', 'ma-garage-coburn-weston', 'garage_door', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Weston Garage Door Repair', 'ma-garage-weston-repair', 'garage_door', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Weston Door & Opener', 'ma-garage-weston-door-opener', 'garage_door', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Cat Rock Garage Solutions', 'ma-garage-cat-rock-weston', 'garage_door', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    -- Wilmington
    ('Wilmington Garage Door', 'ma-garage-wilmington-garage-door', 'garage_door', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Carter Overhead Door', 'ma-garage-carter-wilmington', 'garage_door', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Wilmington Garage Door Repair', 'ma-garage-wilmington-repair', 'garage_door', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Wilmington Door & Opener', 'ma-garage-wilmington-door-opener', 'garage_door', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Silver Lake Garage Solutions', 'ma-garage-silver-lake-wilmington', 'garage_door', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    -- Winchester
    ('Winchester Garage Door', 'ma-garage-winchester-garage-door', 'garage_door', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Symmes Overhead Door', 'ma-garage-symmes-winchester', 'garage_door', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Winchester Garage Door Repair', 'ma-garage-winchester-repair', 'garage_door', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Winchester Door & Opener', 'ma-garage-winchester-door-opener', 'garage_door', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Wedge Pond Garage Solutions', 'ma-garage-wedge-pond-winchester', 'garage_door', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    -- Woburn
    ('Woburn Garage Door', 'ma-garage-woburn-garage-door', 'garage_door', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Winn Overhead Door', 'ma-garage-winn-woburn', 'garage_door', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Woburn Garage Door Repair', 'ma-garage-woburn-repair', 'garage_door', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Woburn Door & Opener', 'ma-garage-woburn-door-opener', 'garage_door', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Horn Pond Garage Solutions', 'ma-garage-horn-pond-woburn', 'garage_door', NULL, ARRAY['Woburn','MA','Middlesex'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 9: NORFOLK COUNTY LOCAL GARAGE DOOR (27 towns x 5)
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Avon
    ('Avon Garage Door', 'ma-garage-avon-garage-door', 'garage_door', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Buckley Overhead Door', 'ma-garage-buckley-avon', 'garage_door', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Avon Garage Door Repair', 'ma-garage-avon-repair', 'garage_door', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Avon Door & Opener', 'ma-garage-avon-door-opener', 'garage_door', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Stoughton Brook Garage Solutions', 'ma-garage-stoughton-brook-avon', 'garage_door', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    -- Braintree
    ('Braintree Garage Door', 'ma-garage-braintree-garage-door', 'garage_door', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Hayward Overhead Door', 'ma-garage-hayward-braintree', 'garage_door', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Braintree Garage Door Repair', 'ma-garage-braintree-repair', 'garage_door', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Braintree Door & Opener', 'ma-garage-braintree-door-opener', 'garage_door', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Sunset Lake Garage Solutions', 'ma-garage-sunset-lake-braintree', 'garage_door', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    -- Brookline
    ('Brookline Garage Door', 'ma-garage-brookline-garage-door', 'garage_door', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Devotion Overhead Door', 'ma-garage-devotion-brookline', 'garage_door', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Brookline Garage Door Repair', 'ma-garage-brookline-repair', 'garage_door', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Brookline Door & Opener', 'ma-garage-brookline-door-opener', 'garage_door', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Coolidge Corner Garage Solutions', 'ma-garage-coolidge-corner-brookline', 'garage_door', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    -- Canton
    ('Canton Garage Door', 'ma-garage-canton-garage-door', 'garage_door', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Revere Overhead Door', 'ma-garage-revere-canton', 'garage_door', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Canton Garage Door Repair', 'ma-garage-canton-repair', 'garage_door', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Canton Door & Opener', 'ma-garage-canton-door-opener', 'garage_door', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Ponkapoag Garage Solutions', 'ma-garage-ponkapoag-canton', 'garage_door', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    -- Cohasset
    ('Cohasset Garage Door', 'ma-garage-cohasset-garage-door', 'garage_door', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Bates Overhead Door', 'ma-garage-bates-cohasset', 'garage_door', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Cohasset Garage Door Repair', 'ma-garage-cohasset-repair', 'garage_door', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Cohasset Door & Opener', 'ma-garage-cohasset-door-opener', 'garage_door', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Cohasset Harbor Garage Solutions', 'ma-garage-cohasset-harbor-cohasset', 'garage_door', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    -- Dedham
    ('Dedham Garage Door', 'ma-garage-dedham-garage-door', 'garage_door', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Fairbanks Overhead Door', 'ma-garage-fairbanks-dedham', 'garage_door', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Dedham Garage Door Repair', 'ma-garage-dedham-repair', 'garage_door', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Dedham Door & Opener', 'ma-garage-dedham-door-opener', 'garage_door', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Mother Brook Garage Solutions', 'ma-garage-mother-brook-dedham', 'garage_door', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    -- Dover
    ('Dover Garage Door', 'ma-garage-dover-garage-door', 'garage_door', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Chickering Overhead Door', 'ma-garage-chickering-dover', 'garage_door', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Dover Garage Door Repair', 'ma-garage-dover-repair', 'garage_door', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Dover Door & Opener', 'ma-garage-dover-door-opener', 'garage_door', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Noanet Brook Garage Solutions', 'ma-garage-noanet-brook-dover', 'garage_door', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    -- Foxborough
    ('Foxborough Garage Door', 'ma-garage-foxborough-garage-door', 'garage_door', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Carpenter Overhead Door', 'ma-garage-carpenter-foxborough', 'garage_door', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Foxborough Garage Door Repair', 'ma-garage-foxborough-repair', 'garage_door', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Foxborough Door & Opener', 'ma-garage-foxborough-door-opener', 'garage_door', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Neponset Garage Solutions', 'ma-garage-neponset-foxborough', 'garage_door', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    -- Franklin
    ('Franklin Garage Door', 'ma-garage-franklin-garage-door', 'garage_door', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Metcalf Overhead Door', 'ma-garage-metcalf-franklin', 'garage_door', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Franklin Garage Door Repair', 'ma-garage-franklin-repair', 'garage_door', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Franklin Door & Opener', 'ma-garage-franklin-door-opener', 'garage_door', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Delcarte Garage Solutions', 'ma-garage-delcarte-franklin', 'garage_door', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    -- Holbrook
    ('Holbrook Garage Door', 'ma-garage-holbrook-garage-door', 'garage_door', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Thayer Overhead Door', 'ma-garage-thayer-holbrook', 'garage_door', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Holbrook Garage Door Repair', 'ma-garage-holbrook-repair', 'garage_door', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Holbrook Door & Opener', 'ma-garage-holbrook-door-opener', 'garage_door', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Cochato Garage Solutions', 'ma-garage-cochato-holbrook', 'garage_door', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    -- Medfield
    ('Medfield Garage Door', 'ma-garage-medfield-garage-door', 'garage_door', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Adams Overhead Door', 'ma-garage-adams-medfield', 'garage_door', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Medfield Garage Door Repair', 'ma-garage-medfield-repair', 'garage_door', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Medfield Door & Opener', 'ma-garage-medfield-door-opener', 'garage_door', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Charles River Garage Solutions', 'ma-garage-charles-river-medfield', 'garage_door', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    -- Medway
    ('Medway Garage Door', 'ma-garage-medway-garage-door', 'garage_door', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Lovering Overhead Door', 'ma-garage-lovering-medway', 'garage_door', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Medway Garage Door Repair', 'ma-garage-medway-repair', 'garage_door', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Medway Door & Opener', 'ma-garage-medway-door-opener', 'garage_door', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Chicken Brook Garage Solutions', 'ma-garage-chicken-brook-medway', 'garage_door', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    -- Millis
    ('Millis Garage Door', 'ma-garage-millis-garage-door', 'garage_door', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Richardson Overhead Door', 'ma-garage-richardson-millis', 'garage_door', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Millis Garage Door Repair', 'ma-garage-millis-repair', 'garage_door', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Millis Door & Opener', 'ma-garage-millis-door-opener', 'garage_door', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Bogastow Garage Solutions', 'ma-garage-bogastow-millis', 'garage_door', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    -- Milton
    ('Milton Garage Door', 'ma-garage-milton-garage-door', 'garage_door', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Vose Overhead Door', 'ma-garage-vose-milton', 'garage_door', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Milton Garage Door Repair', 'ma-garage-milton-repair', 'garage_door', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Milton Door & Opener', 'ma-garage-milton-door-opener', 'garage_door', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Blue Hills Garage Solutions', 'ma-garage-blue-hills-milton', 'garage_door', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    -- Needham
    ('Needham Garage Door', 'ma-garage-needham-garage-door', 'garage_door', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Kingsbury Overhead Door', 'ma-garage-kingsbury-needham', 'garage_door', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Needham Garage Door Repair', 'ma-garage-needham-repair', 'garage_door', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Needham Door & Opener', 'ma-garage-needham-door-opener', 'garage_door', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Cutler Park Garage Solutions', 'ma-garage-cutler-park-needham', 'garage_door', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    -- Norfolk
    ('Norfolk Garage Door', 'ma-garage-norfolk-garage-door', 'garage_door', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Mann Overhead Door', 'ma-garage-mann-norfolk', 'garage_door', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Norfolk Garage Door Repair', 'ma-garage-norfolk-repair', 'garage_door', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Norfolk Door & Opener', 'ma-garage-norfolk-door-opener', 'garage_door', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Stony Brook Garage Solutions', 'ma-garage-stony-brook-norfolk', 'garage_door', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    -- Norwood
    ('Norwood Garage Door', 'ma-garage-norwood-garage-door', 'garage_door', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Guild Overhead Door', 'ma-garage-guild-norwood', 'garage_door', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Norwood Garage Door Repair', 'ma-garage-norwood-repair', 'garage_door', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Norwood Door & Opener', 'ma-garage-norwood-door-opener', 'garage_door', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Ellis Pond Garage Solutions', 'ma-garage-ellis-pond-norwood', 'garage_door', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    -- Plainville
    ('Plainville Garage Door', 'ma-garage-plainville-garage-door', 'garage_door', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Shepardson Overhead Door', 'ma-garage-shepardson-plainville', 'garage_door', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Plainville Garage Door Repair', 'ma-garage-plainville-repair', 'garage_door', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Plainville Door & Opener', 'ma-garage-plainville-door-opener', 'garage_door', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Turnpike Lake Garage Solutions', 'ma-garage-turnpike-lake-plainville', 'garage_door', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    -- Quincy
    ('Quincy Garage Door', 'ma-garage-quincy-garage-door', 'garage_door', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Adams Overhead Door', 'ma-garage-adams-quincy', 'garage_door', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Quincy Garage Door Repair', 'ma-garage-quincy-repair', 'garage_door', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Quincy Door & Opener', 'ma-garage-quincy-door-opener', 'garage_door', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Wollaston Garage Solutions', 'ma-garage-wollaston-quincy', 'garage_door', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    -- Randolph
    ('Randolph Garage Door', 'ma-garage-randolph-garage-door', 'garage_door', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Stetson Overhead Door', 'ma-garage-stetson-randolph', 'garage_door', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Randolph Garage Door Repair', 'ma-garage-randolph-repair', 'garage_door', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Randolph Door & Opener', 'ma-garage-randolph-door-opener', 'garage_door', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Great Pond Garage Solutions', 'ma-garage-great-pond-randolph', 'garage_door', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    -- Sharon
    ('Sharon Garage Door', 'ma-garage-sharon-garage-door', 'garage_door', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Morse Overhead Door', 'ma-garage-morse-sharon', 'garage_door', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Sharon Garage Door Repair', 'ma-garage-sharon-repair', 'garage_door', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Sharon Door & Opener', 'ma-garage-sharon-door-opener', 'garage_door', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Massapoag Garage Solutions', 'ma-garage-massapoag-sharon', 'garage_door', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    -- Stoughton
    ('Stoughton Garage Door', 'ma-garage-stoughton-garage-door', 'garage_door', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Drake Overhead Door', 'ma-garage-drake-stoughton', 'garage_door', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Stoughton Garage Door Repair', 'ma-garage-stoughton-repair', 'garage_door', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Stoughton Door & Opener', 'ma-garage-stoughton-door-opener', 'garage_door', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Ames Pond Garage Solutions', 'ma-garage-ames-pond-stoughton', 'garage_door', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    -- Walpole
    ('Walpole Garage Door', 'ma-garage-walpole-garage-door', 'garage_door', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Lewis Overhead Door', 'ma-garage-lewis-walpole', 'garage_door', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Walpole Garage Door Repair', 'ma-garage-walpole-repair', 'garage_door', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Walpole Door & Opener', 'ma-garage-walpole-door-opener', 'garage_door', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Memorial Pond Garage Solutions', 'ma-garage-memorial-pond-walpole', 'garage_door', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    -- Wellesley
    ('Wellesley Garage Door', 'ma-garage-wellesley-garage-door', 'garage_door', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Hunnewell Overhead Door', 'ma-garage-hunnewell-wellesley', 'garage_door', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Wellesley Garage Door Repair', 'ma-garage-wellesley-repair', 'garage_door', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Wellesley Door & Opener', 'ma-garage-wellesley-door-opener', 'garage_door', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Lake Waban Garage Solutions', 'ma-garage-lake-waban-wellesley', 'garage_door', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    -- Westwood
    ('Westwood Garage Door', 'ma-garage-westwood-garage-door', 'garage_door', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Colburn Overhead Door', 'ma-garage-colburn-westwood', 'garage_door', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Westwood Garage Door Repair', 'ma-garage-westwood-repair', 'garage_door', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Westwood Door & Opener', 'ma-garage-westwood-door-opener', 'garage_door', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Buckmaster Garage Solutions', 'ma-garage-buckmaster-westwood', 'garage_door', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    -- Weymouth
    ('Weymouth Garage Door', 'ma-garage-weymouth-garage-door', 'garage_door', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Pratt Overhead Door', 'ma-garage-pratt-weymouth', 'garage_door', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Weymouth Garage Door Repair', 'ma-garage-weymouth-repair', 'garage_door', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Weymouth Door & Opener', 'ma-garage-weymouth-door-opener', 'garage_door', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Whitman Pond Garage Solutions', 'ma-garage-whitman-pond-weymouth', 'garage_door', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    -- Wrentham
    ('Wrentham Garage Door', 'ma-garage-wrentham-garage-door', 'garage_door', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Sheldon Overhead Door', 'ma-garage-sheldon-wrentham', 'garage_door', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Wrentham Garage Door Repair', 'ma-garage-wrentham-repair', 'garage_door', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Wrentham Door & Opener', 'ma-garage-wrentham-door-opener', 'garage_door', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Lake Pearl Garage Solutions', 'ma-garage-lake-pearl-wrentham', 'garage_door', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 10: PLYMOUTH COUNTY LOCAL GARAGE DOOR (27 towns x 5)
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Abington
    ('Abington Garage Door', 'ma-garage-abington-garage-door', 'garage_door', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Nash Overhead Door', 'ma-garage-nash-abington', 'garage_door', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Abington Garage Door Repair', 'ma-garage-abington-repair', 'garage_door', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Abington Door & Opener', 'ma-garage-abington-door-opener', 'garage_door', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Island Grove Garage Solutions', 'ma-garage-island-grove-abington', 'garage_door', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    -- Bridgewater
    ('Bridgewater Garage Door', 'ma-garage-bridgewater-garage-door', 'garage_door', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Keith Overhead Door', 'ma-garage-keith-bridgewater', 'garage_door', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Garage Door Repair', 'ma-garage-bridgewater-repair', 'garage_door', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Door & Opener', 'ma-garage-bridgewater-door-opener', 'garage_door', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Town River Garage Solutions', 'ma-garage-town-river-bridgewater', 'garage_door', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    -- Brockton
    ('Brockton Garage Door', 'ma-garage-brockton-garage-door', 'garage_door', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Howard Overhead Door', 'ma-garage-howard-brockton', 'garage_door', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Brockton Garage Door Repair', 'ma-garage-brockton-repair', 'garage_door', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Brockton Door & Opener', 'ma-garage-brockton-door-opener', 'garage_door', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('DW Field Garage Solutions', 'ma-garage-dw-field-brockton', 'garage_door', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    -- Carver
    ('Carver Garage Door', 'ma-garage-carver-garage-door', 'garage_door', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Shaw Overhead Door', 'ma-garage-shaw-carver', 'garage_door', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Carver Garage Door Repair', 'ma-garage-carver-repair', 'garage_door', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Carver Door & Opener', 'ma-garage-carver-door-opener', 'garage_door', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Cranberry Bog Garage Solutions', 'ma-garage-cranberry-bog-carver', 'garage_door', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    -- Duxbury
    ('Duxbury Garage Door', 'ma-garage-duxbury-garage-door', 'garage_door', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Standish Overhead Door', 'ma-garage-standish-duxbury', 'garage_door', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Duxbury Garage Door Repair', 'ma-garage-duxbury-repair', 'garage_door', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Duxbury Door & Opener', 'ma-garage-duxbury-door-opener', 'garage_door', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Duxbury Bay Garage Solutions', 'ma-garage-duxbury-bay-duxbury', 'garage_door', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    -- East Bridgewater
    ('East Bridgewater Garage Door', 'ma-garage-east-bridgewater-garage-door', 'garage_door', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('Whitman Overhead Door', 'ma-garage-whitman-overhead-east-bridgewater', 'garage_door', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('East Bridgewater Garage Door Repair', 'ma-garage-east-bridgewater-repair', 'garage_door', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('East Bridgewater Door & Opener', 'ma-garage-east-bridgewater-door-opener', 'garage_door', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('Satucket Garage Solutions', 'ma-garage-satucket-east-bridgewater', 'garage_door', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    -- Halifax
    ('Halifax Garage Door', 'ma-garage-halifax-garage-door', 'garage_door', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Thompson Overhead Door', 'ma-garage-thompson-halifax', 'garage_door', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Halifax Garage Door Repair', 'ma-garage-halifax-repair', 'garage_door', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Halifax Door & Opener', 'ma-garage-halifax-door-opener', 'garage_door', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Monponsett Garage Solutions', 'ma-garage-monponsett-halifax', 'garage_door', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    -- Hanover
    ('Hanover Garage Door', 'ma-garage-hanover-garage-door', 'garage_door', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Sylvester Overhead Door', 'ma-garage-sylvester-hanover', 'garage_door', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Hanover Garage Door Repair', 'ma-garage-hanover-repair', 'garage_door', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Hanover Door & Opener', 'ma-garage-hanover-door-opener', 'garage_door', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Indian Head Garage Solutions', 'ma-garage-indian-head-hanover', 'garage_door', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    -- Hanson
    ('Hanson Garage Door', 'ma-garage-hanson-garage-door', 'garage_door', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Phillips Overhead Door', 'ma-garage-phillips-hanson', 'garage_door', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Hanson Garage Door Repair', 'ma-garage-hanson-repair', 'garage_door', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Hanson Door & Opener', 'ma-garage-hanson-door-opener', 'garage_door', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Wampatuck Garage Solutions', 'ma-garage-wampatuck-hanson', 'garage_door', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    -- Hingham
    ('Hingham Garage Door', 'ma-garage-hingham-garage-door', 'garage_door', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Lincoln Overhead Door', 'ma-garage-lincoln-overhead-hingham', 'garage_door', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Hingham Garage Door Repair', 'ma-garage-hingham-repair', 'garage_door', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Hingham Door & Opener', 'ma-garage-hingham-door-opener', 'garage_door', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('World End Garage Solutions', 'ma-garage-world-end-hingham', 'garage_door', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    -- Hull
    ('Hull Garage Door', 'ma-garage-hull-garage-door', 'garage_door', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Nantasket Overhead Door', 'ma-garage-nantasket-hull', 'garage_door', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Hull Garage Door Repair', 'ma-garage-hull-repair', 'garage_door', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Hull Door & Opener', 'ma-garage-hull-door-opener', 'garage_door', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Windmill Point Garage Solutions', 'ma-garage-windmill-point-hull', 'garage_door', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    -- Kingston
    ('Kingston Garage Door', 'ma-garage-kingston-garage-door', 'garage_door', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Bradford Overhead Door', 'ma-garage-bradford-kingston', 'garage_door', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Kingston Garage Door Repair', 'ma-garage-kingston-repair', 'garage_door', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Kingston Door & Opener', 'ma-garage-kingston-door-opener', 'garage_door', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Jones River Garage Solutions', 'ma-garage-jones-river-kingston', 'garage_door', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    -- Lakeville
    ('Lakeville Garage Door', 'ma-garage-lakeville-garage-door', 'garage_door', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Pickens Overhead Door', 'ma-garage-pickens-lakeville', 'garage_door', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Lakeville Garage Door Repair', 'ma-garage-lakeville-repair', 'garage_door', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Lakeville Door & Opener', 'ma-garage-lakeville-door-opener', 'garage_door', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Assawompset Garage Solutions', 'ma-garage-assawompset-lakeville', 'garage_door', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    -- Marion
    ('Marion Garage Door', 'ma-garage-marion-garage-door', 'garage_door', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Delano Overhead Door', 'ma-garage-delano-marion', 'garage_door', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Marion Garage Door Repair', 'ma-garage-marion-repair', 'garage_door', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Marion Door & Opener', 'ma-garage-marion-door-opener', 'garage_door', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Sippican Garage Solutions', 'ma-garage-sippican-marion', 'garage_door', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    -- Marshfield
    ('Marshfield Garage Door', 'ma-garage-marshfield-garage-door', 'garage_door', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Webster Overhead Door', 'ma-garage-webster-marshfield', 'garage_door', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Marshfield Garage Door Repair', 'ma-garage-marshfield-repair', 'garage_door', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Marshfield Door & Opener', 'ma-garage-marshfield-door-opener', 'garage_door', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Green Harbor Garage Solutions', 'ma-garage-green-harbor-marshfield', 'garage_door', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    -- Mattapoisett
    ('Mattapoisett Garage Door', 'ma-garage-mattapoisett-garage-door', 'garage_door', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Barstow Overhead Door', 'ma-garage-barstow-mattapoisett', 'garage_door', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Mattapoisett Garage Door Repair', 'ma-garage-mattapoisett-repair', 'garage_door', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Mattapoisett Door & Opener', 'ma-garage-mattapoisett-door-opener', 'garage_door', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Mattapoisett Harbor Garage Solutions', 'ma-garage-mattapoisett-harbor-mattapoisett', 'garage_door', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    -- Middleborough
    ('Middleborough Garage Door', 'ma-garage-middleborough-garage-door', 'garage_door', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Soule Overhead Door', 'ma-garage-soule-middleborough', 'garage_door', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Middleborough Garage Door Repair', 'ma-garage-middleborough-repair', 'garage_door', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Middleborough Door & Opener', 'ma-garage-middleborough-door-opener', 'garage_door', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Nemasket Garage Solutions', 'ma-garage-nemasket-middleborough', 'garage_door', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    -- Norwell
    ('Norwell Garage Door', 'ma-garage-norwell-garage-door', 'garage_door', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Jacobs Overhead Door', 'ma-garage-jacobs-norwell', 'garage_door', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Norwell Garage Door Repair', 'ma-garage-norwell-repair', 'garage_door', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Norwell Door & Opener', 'ma-garage-norwell-door-opener', 'garage_door', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('North River Garage Solutions', 'ma-garage-north-river-norwell', 'garage_door', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    -- Pembroke
    ('Pembroke Garage Door', 'ma-garage-pembroke-garage-door', 'garage_door', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Barker Overhead Door', 'ma-garage-barker-pembroke', 'garage_door', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Pembroke Garage Door Repair', 'ma-garage-pembroke-repair', 'garage_door', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Pembroke Door & Opener', 'ma-garage-pembroke-door-opener', 'garage_door', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Silver Lake Garage Solutions', 'ma-garage-silver-lake-pembroke', 'garage_door', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    -- Plymouth
    ('Plymouth Garage Door', 'ma-garage-plymouth-garage-door', 'garage_door', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Pilgrim Overhead Door', 'ma-garage-pilgrim-plymouth', 'garage_door', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Plymouth Garage Door Repair', 'ma-garage-plymouth-repair', 'garage_door', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Plymouth Door & Opener', 'ma-garage-plymouth-door-opener', 'garage_door', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Myles Standish Garage Solutions', 'ma-garage-myles-standish-plymouth', 'garage_door', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    -- Plympton
    ('Plympton Garage Door', 'ma-garage-plympton-garage-door', 'garage_door', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Ring Overhead Door', 'ma-garage-ring-plympton', 'garage_door', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Plympton Garage Door Repair', 'ma-garage-plympton-repair', 'garage_door', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Plympton Door & Opener', 'ma-garage-plympton-door-opener', 'garage_door', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Winnetuxet Garage Solutions', 'ma-garage-winnetuxet-plympton', 'garage_door', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    -- Rochester
    ('Rochester Garage Door', 'ma-garage-rochester-garage-door', 'garage_door', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Leonard Overhead Door', 'ma-garage-leonard-rochester', 'garage_door', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Rochester Garage Door Repair', 'ma-garage-rochester-repair', 'garage_door', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Rochester Door & Opener', 'ma-garage-rochester-door-opener', 'garage_door', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Snipatuit Garage Solutions', 'ma-garage-snipatuit-rochester', 'garage_door', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    -- Rockland
    ('Rockland Garage Door', 'ma-garage-rockland-garage-door', 'garage_door', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Reed Overhead Door', 'ma-garage-reed-rockland', 'garage_door', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Rockland Garage Door Repair', 'ma-garage-rockland-repair', 'garage_door', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Rockland Door & Opener', 'ma-garage-rockland-door-opener', 'garage_door', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('French Stream Garage Solutions', 'ma-garage-french-stream-rockland', 'garage_door', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    -- Scituate
    ('Scituate Garage Door', 'ma-garage-scituate-garage-door', 'garage_door', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Bailey Overhead Door', 'ma-garage-bailey-scituate', 'garage_door', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Scituate Garage Door Repair', 'ma-garage-scituate-repair', 'garage_door', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Scituate Door & Opener', 'ma-garage-scituate-door-opener', 'garage_door', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Scituate Harbor Garage Solutions', 'ma-garage-scituate-harbor-scituate', 'garage_door', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    -- Wareham
    ('Wareham Garage Door', 'ma-garage-wareham-garage-door', 'garage_door', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Fearing Overhead Door', 'ma-garage-fearing-wareham', 'garage_door', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Wareham Garage Door Repair', 'ma-garage-wareham-repair', 'garage_door', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Wareham Door & Opener', 'ma-garage-wareham-door-opener', 'garage_door', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Onset Bay Garage Solutions', 'ma-garage-onset-bay-wareham', 'garage_door', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    -- West Bridgewater
    ('West Bridgewater Garage Door', 'ma-garage-west-bridgewater-garage-door', 'garage_door', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('Howard Overhead Door', 'ma-garage-howard-overhead-west-bridgewater', 'garage_door', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('West Bridgewater Garage Door Repair', 'ma-garage-west-bridgewater-repair', 'garage_door', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('West Bridgewater Door & Opener', 'ma-garage-west-bridgewater-door-opener', 'garage_door', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('Matfield River Garage Solutions', 'ma-garage-matfield-river-west-bridgewater', 'garage_door', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    -- Whitman
    ('Whitman Garage Door', 'ma-garage-whitman-garage-door', 'garage_door', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Hobart Overhead Door', 'ma-garage-hobart-whitman', 'garage_door', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Whitman Garage Door Repair', 'ma-garage-whitman-repair', 'garage_door', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Whitman Door & Opener', 'ma-garage-whitman-door-opener', 'garage_door', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Shumatuscacant Garage Solutions', 'ma-garage-shumatuscacant-whitman', 'garage_door', NULL, ARRAY['Whitman','MA','Plymouth'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;
