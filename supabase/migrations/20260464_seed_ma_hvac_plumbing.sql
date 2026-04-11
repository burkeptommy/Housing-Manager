-- Seed HVAC and plumbing companies into utility_providers for Massachusetts.
-- Covers 4 counties: Essex, Middlesex, Norfolk, Plymouth.
--
-- Sections 1-5: HVAC (regional + 4 counties, 5 per town)
-- Sections 6-10: Plumbing (regional + 4 counties, 5 per town)
--
-- provider_type = 'hvac' or 'plumbing', logo_url = NULL (resolved via Brandfetch).
-- Slug convention: ma-hvac-[name]-[town] / ma-plumbing-[name]-[town].
-- ON CONFLICT (slug) DO UPDATE ensures idempotent re-runs.

-- ============================================================
-- SECTION 1: MA REGIONAL HVAC COMPANIES
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    ('New England Mechanical Services', 'ma-hvac-new-england-mechanical', 'hvac', 'https://www.newenglandmechanical.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Gervais Mechanical Services', 'ma-hvac-gervais-mechanical', 'hvac', 'https://www.gervaismechanical.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Adams & Smith HVAC', 'ma-hvac-adams-smith', 'hvac', 'https://www.adamsandsmithhvac.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Basnett Plumbing Heating & AC', 'ma-hvac-basnett', 'hvac', 'https://www.basnetthvac.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Trust 1 Services', 'ma-hvac-trust-1-services', 'hvac', 'https://www.trust1services.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('P.J. Fitzpatrick HVAC', 'ma-hvac-pj-fitzpatrick', 'hvac', 'https://www.pjfitz.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Silco Plumbing & Heating', 'ma-hvac-silco', 'hvac', 'https://www.silcoplumbing.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Winters Home Services', 'ma-hvac-winters-home', 'hvac', 'https://www.wintershomeservices.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Papalia Home Services', 'ma-hvac-papalia', 'hvac', 'https://www.papaliahomeservices.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Williams Energy', 'ma-hvac-williams-energy', 'hvac', 'https://www.williamsenergy.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Metro Boston HVAC', 'ma-hvac-metro-boston', 'hvac', NULL, ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Comfort Pro Heating & Cooling', 'ma-hvac-comfort-pro', 'hvac', NULL, ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 2: ESSEX COUNTY LOCAL HVAC (33 towns x 5)
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Andover
    ('Andover Heating & Cooling', 'ma-hvac-andover-heating-cooling', 'hvac', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Sullivan HVAC Services', 'ma-hvac-sullivan-andover', 'hvac', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Merrimack Climate Control', 'ma-hvac-merrimack-climate-andover', 'hvac', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Brennan & Sons Heating', 'ma-hvac-brennan-sons-andover', 'hvac', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Andover Air Conditioning & Heat', 'ma-hvac-andover-ac-heat', 'hvac', NULL, ARRAY['Andover','MA','Essex'], NULL),

    -- Beverly
    ('Beverly Heating & Cooling', 'ma-hvac-beverly-heating-cooling', 'hvac', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Harrington HVAC Services', 'ma-hvac-harrington-beverly', 'hvac', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('North Shore Climate Control', 'ma-hvac-north-shore-climate-beverly', 'hvac', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Callahan & Sons Heating', 'ma-hvac-callahan-sons-beverly', 'hvac', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Beverly Air Conditioning & Heat', 'ma-hvac-beverly-ac-heat', 'hvac', NULL, ARRAY['Beverly','MA','Essex'], NULL),

    -- Boxford
    ('Boxford Heating & Cooling', 'ma-hvac-boxford-heating-cooling', 'hvac', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Kelleher HVAC Services', 'ma-hvac-kelleher-boxford', 'hvac', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Boxford Climate Control', 'ma-hvac-boxford-climate', 'hvac', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Perkins & Sons Heating', 'ma-hvac-perkins-sons-boxford', 'hvac', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Boxford Air Conditioning & Heat', 'ma-hvac-boxford-ac-heat', 'hvac', NULL, ARRAY['Boxford','MA','Essex'], NULL),

    -- Danvers
    ('Danvers Heating & Cooling', 'ma-hvac-danvers-heating-cooling', 'hvac', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Petralia HVAC Services', 'ma-hvac-petralia-danvers', 'hvac', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Danvers Climate Control', 'ma-hvac-danvers-climate', 'hvac', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Donovan & Sons Heating', 'ma-hvac-donovan-sons-danvers', 'hvac', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Danvers Air Conditioning & Heat', 'ma-hvac-danvers-ac-heat', 'hvac', NULL, ARRAY['Danvers','MA','Essex'], NULL),

    -- Essex
    ('Essex Heating & Cooling', 'ma-hvac-essex-heating-cooling', 'hvac', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Burnham HVAC Services', 'ma-hvac-burnham-essex', 'hvac', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Essex Climate Control', 'ma-hvac-essex-climate', 'hvac', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Choate & Sons Heating', 'ma-hvac-choate-sons-essex', 'hvac', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Essex Air Conditioning & Heat', 'ma-hvac-essex-ac-heat', 'hvac', NULL, ARRAY['Essex','MA','Essex'], NULL),

    -- Georgetown
    ('Georgetown Heating & Cooling', 'ma-hvac-georgetown-heating-cooling', 'hvac', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Thurlow HVAC Services', 'ma-hvac-thurlow-georgetown', 'hvac', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Georgetown Climate Control', 'ma-hvac-georgetown-climate', 'hvac', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Keane & Sons Heating', 'ma-hvac-keane-sons-georgetown', 'hvac', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Georgetown Air Conditioning & Heat', 'ma-hvac-georgetown-ac-heat', 'hvac', NULL, ARRAY['Georgetown','MA','Essex'], NULL),

    -- Gloucester
    ('Gloucester Heating & Cooling', 'ma-hvac-gloucester-heating-cooling', 'hvac', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Favazza HVAC Services', 'ma-hvac-favazza-gloucester', 'hvac', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Cape Ann Climate Control', 'ma-hvac-cape-ann-climate-gloucester', 'hvac', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Rallo & Sons Heating', 'ma-hvac-rallo-sons-gloucester', 'hvac', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Gloucester Air Conditioning & Heat', 'ma-hvac-gloucester-ac-heat', 'hvac', NULL, ARRAY['Gloucester','MA','Essex'], NULL),

    -- Groveland
    ('Groveland Heating & Cooling', 'ma-hvac-groveland-heating-cooling', 'hvac', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Batchelder HVAC Services', 'ma-hvac-batchelder-groveland', 'hvac', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Pentucket Climate Control', 'ma-hvac-pentucket-climate-groveland', 'hvac', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Cross & Sons Heating', 'ma-hvac-cross-sons-groveland', 'hvac', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Groveland Air Conditioning & Heat', 'ma-hvac-groveland-ac-heat', 'hvac', NULL, ARRAY['Groveland','MA','Essex'], NULL),

    -- Hamilton
    ('Hamilton Heating & Cooling', 'ma-hvac-hamilton-heating-cooling', 'hvac', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Wenham HVAC Services', 'ma-hvac-wenham-hvac-hamilton', 'hvac', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Hamilton Climate Control', 'ma-hvac-hamilton-climate', 'hvac', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Appleton & Sons Heating', 'ma-hvac-appleton-sons-hamilton', 'hvac', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Hamilton Air Conditioning & Heat', 'ma-hvac-hamilton-ac-heat', 'hvac', NULL, ARRAY['Hamilton','MA','Essex'], NULL),

    -- Haverhill
    ('Haverhill Heating & Cooling', 'ma-hvac-haverhill-heating-cooling', 'hvac', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Moriarty HVAC Services', 'ma-hvac-moriarty-haverhill', 'hvac', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Haverhill Climate Control', 'ma-hvac-haverhill-climate', 'hvac', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Fitzgerald & Sons Heating', 'ma-hvac-fitzgerald-sons-haverhill', 'hvac', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Haverhill Air Conditioning & Heat', 'ma-hvac-haverhill-ac-heat', 'hvac', NULL, ARRAY['Haverhill','MA','Essex'], NULL),

    -- Ipswich
    ('Ipswich Heating & Cooling', 'ma-hvac-ipswich-heating-cooling', 'hvac', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Goodhue HVAC Services', 'ma-hvac-goodhue-ipswich', 'hvac', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Ipswich Climate Control', 'ma-hvac-ipswich-climate', 'hvac', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Treadwell & Sons Heating', 'ma-hvac-treadwell-sons-ipswich', 'hvac', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Ipswich Air Conditioning & Heat', 'ma-hvac-ipswich-ac-heat', 'hvac', NULL, ARRAY['Ipswich','MA','Essex'], NULL),

    -- Lawrence
    ('Lawrence Heating & Cooling', 'ma-hvac-lawrence-heating-cooling', 'hvac', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Ortiz HVAC Services', 'ma-hvac-ortiz-lawrence', 'hvac', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Lawrence Climate Control', 'ma-hvac-lawrence-climate', 'hvac', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Reilly & Sons Heating', 'ma-hvac-reilly-sons-lawrence', 'hvac', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Lawrence Air Conditioning & Heat', 'ma-hvac-lawrence-ac-heat', 'hvac', NULL, ARRAY['Lawrence','MA','Essex'], NULL),

    -- Lynn
    ('Lynn Heating & Cooling', 'ma-hvac-lynn-heating-cooling', 'hvac', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Doherty HVAC Services', 'ma-hvac-doherty-lynn', 'hvac', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Lynn Climate Control', 'ma-hvac-lynn-climate', 'hvac', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Walsh & Sons Heating', 'ma-hvac-walsh-sons-lynn', 'hvac', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Lynn Air Conditioning & Heat', 'ma-hvac-lynn-ac-heat', 'hvac', NULL, ARRAY['Lynn','MA','Essex'], NULL),

    -- Lynnfield
    ('Lynnfield Heating & Cooling', 'ma-hvac-lynnfield-heating-cooling', 'hvac', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Barrett HVAC Services', 'ma-hvac-barrett-lynnfield', 'hvac', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Lynnfield Climate Control', 'ma-hvac-lynnfield-climate', 'hvac', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Coakley & Sons Heating', 'ma-hvac-coakley-sons-lynnfield', 'hvac', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Lynnfield Air Conditioning & Heat', 'ma-hvac-lynnfield-ac-heat', 'hvac', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),

    -- Manchester-by-the-Sea
    ('Manchester Heating & Cooling', 'ma-hvac-manchester-heating-cooling', 'hvac', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Haskell HVAC Services', 'ma-hvac-haskell-manchester', 'hvac', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Manchester Climate Control', 'ma-hvac-manchester-climate', 'hvac', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Leach & Sons Heating', 'ma-hvac-leach-sons-manchester', 'hvac', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Manchester Air Conditioning & Heat', 'ma-hvac-manchester-ac-heat', 'hvac', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),

    -- Marblehead
    ('Marblehead Heating & Cooling', 'ma-hvac-marblehead-heating-cooling', 'hvac', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Graves HVAC Services', 'ma-hvac-graves-marblehead', 'hvac', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Marblehead Climate Control', 'ma-hvac-marblehead-climate', 'hvac', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Pitman & Sons Heating', 'ma-hvac-pitman-sons-marblehead', 'hvac', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Marblehead Air Conditioning & Heat', 'ma-hvac-marblehead-ac-heat', 'hvac', NULL, ARRAY['Marblehead','MA','Essex'], NULL),

    -- Merrimac
    ('Merrimac Heating & Cooling', 'ma-hvac-merrimac-heating-cooling', 'hvac', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Sargent HVAC Services', 'ma-hvac-sargent-merrimac', 'hvac', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Merrimac Climate Control', 'ma-hvac-merrimac-climate', 'hvac', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Hoyt & Sons Heating', 'ma-hvac-hoyt-sons-merrimac', 'hvac', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Merrimac Air Conditioning & Heat', 'ma-hvac-merrimac-ac-heat', 'hvac', NULL, ARRAY['Merrimac','MA','Essex'], NULL),

    -- Methuen
    ('Methuen Heating & Cooling', 'ma-hvac-methuen-heating-cooling', 'hvac', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Quinlan HVAC Services', 'ma-hvac-quinlan-methuen', 'hvac', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Methuen Climate Control', 'ma-hvac-methuen-climate', 'hvac', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Gauthier & Sons Heating', 'ma-hvac-gauthier-sons-methuen', 'hvac', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Methuen Air Conditioning & Heat', 'ma-hvac-methuen-ac-heat', 'hvac', NULL, ARRAY['Methuen','MA','Essex'], NULL),

    -- Middleton
    ('Middleton Heating & Cooling', 'ma-hvac-middleton-heating-cooling', 'hvac', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Fuller HVAC Services', 'ma-hvac-fuller-middleton', 'hvac', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Middleton Climate Control', 'ma-hvac-middleton-climate', 'hvac', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Peabody & Sons Heating', 'ma-hvac-peabody-sons-middleton', 'hvac', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Middleton Air Conditioning & Heat', 'ma-hvac-middleton-ac-heat', 'hvac', NULL, ARRAY['Middleton','MA','Essex'], NULL),

    -- Nahant
    ('Nahant Heating & Cooling', 'ma-hvac-nahant-heating-cooling', 'hvac', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Tudor HVAC Services', 'ma-hvac-tudor-nahant', 'hvac', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Nahant Climate Control', 'ma-hvac-nahant-climate', 'hvac', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Lodge & Sons Heating', 'ma-hvac-lodge-sons-nahant', 'hvac', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Nahant Air Conditioning & Heat', 'ma-hvac-nahant-ac-heat', 'hvac', NULL, ARRAY['Nahant','MA','Essex'], NULL),

    -- Newbury
    ('Newbury Heating & Cooling', 'ma-hvac-newbury-heating-cooling', 'hvac', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Coffin HVAC Services', 'ma-hvac-coffin-newbury', 'hvac', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Newbury Climate Control', 'ma-hvac-newbury-climate', 'hvac', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Noyes & Sons Heating', 'ma-hvac-noyes-sons-newbury', 'hvac', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Newbury Air Conditioning & Heat', 'ma-hvac-newbury-ac-heat', 'hvac', NULL, ARRAY['Newbury','MA','Essex'], NULL),

    -- Newburyport
    ('Newburyport Heating & Cooling', 'ma-hvac-newburyport-heating-cooling', 'hvac', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Cushing HVAC Services', 'ma-hvac-cushing-newburyport', 'hvac', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Newburyport Climate Control', 'ma-hvac-newburyport-climate', 'hvac', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Marquand & Sons Heating', 'ma-hvac-marquand-sons-newburyport', 'hvac', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Newburyport Air Conditioning & Heat', 'ma-hvac-newburyport-ac-heat', 'hvac', NULL, ARRAY['Newburyport','MA','Essex'], NULL),

    -- North Andover
    ('North Andover Heating & Cooling', 'ma-hvac-north-andover-heating-cooling', 'hvac', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Bresnahan HVAC Services', 'ma-hvac-bresnahan-north-andover', 'hvac', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('North Andover Climate Control', 'ma-hvac-north-andover-climate', 'hvac', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Osgood & Sons Heating', 'ma-hvac-osgood-sons-north-andover', 'hvac', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('North Andover Air Conditioning & Heat', 'ma-hvac-north-andover-ac-heat', 'hvac', NULL, ARRAY['North Andover','MA','Essex'], NULL),

    -- Peabody
    ('Peabody Heating & Cooling', 'ma-hvac-peabody-heating-cooling', 'hvac', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Crowley HVAC Services', 'ma-hvac-crowley-peabody', 'hvac', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Peabody Climate Control', 'ma-hvac-peabody-climate', 'hvac', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Sutton & Sons Heating', 'ma-hvac-sutton-sons-peabody', 'hvac', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Peabody Air Conditioning & Heat', 'ma-hvac-peabody-ac-heat', 'hvac', NULL, ARRAY['Peabody','MA','Essex'], NULL),

    -- Rockport
    ('Rockport Heating & Cooling', 'ma-hvac-rockport-heating-cooling', 'hvac', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Tarr HVAC Services', 'ma-hvac-tarr-rockport', 'hvac', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Rockport Climate Control', 'ma-hvac-rockport-climate', 'hvac', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Norwood & Sons Heating', 'ma-hvac-norwood-sons-rockport', 'hvac', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Rockport Air Conditioning & Heat', 'ma-hvac-rockport-ac-heat', 'hvac', NULL, ARRAY['Rockport','MA','Essex'], NULL),

    -- Rowley
    ('Rowley Heating & Cooling', 'ma-hvac-rowley-heating-cooling', 'hvac', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Gage HVAC Services', 'ma-hvac-gage-rowley', 'hvac', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Rowley Climate Control', 'ma-hvac-rowley-climate', 'hvac', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Mighill & Sons Heating', 'ma-hvac-mighill-sons-rowley', 'hvac', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Rowley Air Conditioning & Heat', 'ma-hvac-rowley-ac-heat', 'hvac', NULL, ARRAY['Rowley','MA','Essex'], NULL),

    -- Salem
    ('Salem Heating & Cooling', 'ma-hvac-salem-heating-cooling', 'hvac', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Hawthorne HVAC Services', 'ma-hvac-hawthorne-salem', 'hvac', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Salem Climate Control', 'ma-hvac-salem-climate', 'hvac', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Derby & Sons Heating', 'ma-hvac-derby-sons-salem', 'hvac', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Salem Air Conditioning & Heat', 'ma-hvac-salem-ac-heat', 'hvac', NULL, ARRAY['Salem','MA','Essex'], NULL),

    -- Salisbury
    ('Salisbury Heating & Cooling', 'ma-hvac-salisbury-heating-cooling', 'hvac', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Eaton HVAC Services', 'ma-hvac-eaton-salisbury', 'hvac', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Salisbury Climate Control', 'ma-hvac-salisbury-climate', 'hvac', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Pettingill & Sons Heating', 'ma-hvac-pettingill-sons-salisbury', 'hvac', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Salisbury Air Conditioning & Heat', 'ma-hvac-salisbury-ac-heat', 'hvac', NULL, ARRAY['Salisbury','MA','Essex'], NULL),

    -- Saugus
    ('Saugus Heating & Cooling', 'ma-hvac-saugus-heating-cooling', 'hvac', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Parsons HVAC Services', 'ma-hvac-parsons-saugus', 'hvac', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Saugus Climate Control', 'ma-hvac-saugus-climate', 'hvac', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Vinton & Sons Heating', 'ma-hvac-vinton-sons-saugus', 'hvac', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Saugus Air Conditioning & Heat', 'ma-hvac-saugus-ac-heat', 'hvac', NULL, ARRAY['Saugus','MA','Essex'], NULL),

    -- Swampscott
    ('Swampscott Heating & Cooling', 'ma-hvac-swampscott-heating-cooling', 'hvac', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Blaney HVAC Services', 'ma-hvac-blaney-swampscott', 'hvac', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Swampscott Climate Control', 'ma-hvac-swampscott-climate', 'hvac', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Ingalls & Sons Heating', 'ma-hvac-ingalls-sons-swampscott', 'hvac', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Swampscott Air Conditioning & Heat', 'ma-hvac-swampscott-ac-heat', 'hvac', NULL, ARRAY['Swampscott','MA','Essex'], NULL),

    -- Topsfield
    ('Topsfield Heating & Cooling', 'ma-hvac-topsfield-heating-cooling', 'hvac', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Gould HVAC Services', 'ma-hvac-gould-topsfield', 'hvac', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Topsfield Climate Control', 'ma-hvac-topsfield-climate', 'hvac', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Cummings & Sons Heating', 'ma-hvac-cummings-sons-topsfield', 'hvac', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Topsfield Air Conditioning & Heat', 'ma-hvac-topsfield-ac-heat', 'hvac', NULL, ARRAY['Topsfield','MA','Essex'], NULL),

    -- Wenham
    ('Wenham Heating & Cooling', 'ma-hvac-wenham-heating-cooling', 'hvac', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Fiske HVAC Services', 'ma-hvac-fiske-wenham', 'hvac', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Wenham Climate Control', 'ma-hvac-wenham-climate', 'hvac', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Dodge & Sons Heating', 'ma-hvac-dodge-sons-wenham', 'hvac', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Wenham Air Conditioning & Heat', 'ma-hvac-wenham-ac-heat', 'hvac', NULL, ARRAY['Wenham','MA','Essex'], NULL),

    -- West Newbury
    ('West Newbury Heating & Cooling', 'ma-hvac-west-newbury-heating-cooling', 'hvac', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('Chase HVAC Services', 'ma-hvac-chase-west-newbury', 'hvac', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('West Newbury Climate Control', 'ma-hvac-west-newbury-climate', 'hvac', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('Emery & Sons Heating', 'ma-hvac-emery-sons-west-newbury', 'hvac', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('West Newbury Air Conditioning & Heat', 'ma-hvac-west-newbury-ac-heat', 'hvac', NULL, ARRAY['West Newbury','MA','Essex'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 3: MIDDLESEX COUNTY LOCAL HVAC (54 towns x 5)
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Acton
    ('Acton Heating & Cooling', 'ma-hvac-acton-heating-cooling', 'hvac', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Wheeler HVAC Services', 'ma-hvac-wheeler-acton', 'hvac', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Acton Climate Control', 'ma-hvac-acton-climate', 'hvac', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Robbins & Sons Heating', 'ma-hvac-robbins-sons-acton', 'hvac', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Acton Air Conditioning & Heat', 'ma-hvac-acton-ac-heat', 'hvac', NULL, ARRAY['Acton','MA','Middlesex'], NULL),

    -- Arlington
    ('Arlington Heating & Cooling', 'ma-hvac-arlington-heating-cooling', 'hvac', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Peirce HVAC Services', 'ma-hvac-peirce-arlington', 'hvac', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Arlington Climate Control', 'ma-hvac-arlington-climate', 'hvac', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Crosby & Sons Heating', 'ma-hvac-crosby-sons-arlington', 'hvac', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Arlington Air Conditioning & Heat', 'ma-hvac-arlington-ac-heat', 'hvac', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),

    -- Ashby
    ('Ashby Heating & Cooling', 'ma-hvac-ashby-heating-cooling', 'hvac', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Willard HVAC Services', 'ma-hvac-willard-ashby', 'hvac', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Ashby Climate Control', 'ma-hvac-ashby-climate', 'hvac', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Damon & Sons Heating', 'ma-hvac-damon-sons-ashby', 'hvac', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Ashby Air Conditioning & Heat', 'ma-hvac-ashby-ac-heat', 'hvac', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),

    -- Ashland
    ('Ashland Heating & Cooling', 'ma-hvac-ashland-heating-cooling', 'hvac', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Metcalf HVAC Services', 'ma-hvac-metcalf-ashland', 'hvac', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Ashland Climate Control', 'ma-hvac-ashland-climate', 'hvac', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Stone & Sons Heating', 'ma-hvac-stone-sons-ashland', 'hvac', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Ashland Air Conditioning & Heat', 'ma-hvac-ashland-ac-heat', 'hvac', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),

    -- Ayer
    ('Ayer Heating & Cooling', 'ma-hvac-ayer-heating-cooling', 'hvac', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Sanderson HVAC Services', 'ma-hvac-sanderson-ayer', 'hvac', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Ayer Climate Control', 'ma-hvac-ayer-climate', 'hvac', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Farnsworth & Sons Heating', 'ma-hvac-farnsworth-sons-ayer', 'hvac', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Ayer Air Conditioning & Heat', 'ma-hvac-ayer-ac-heat', 'hvac', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),

    -- Bedford
    ('Bedford Heating & Cooling', 'ma-hvac-bedford-heating-cooling', 'hvac', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Lane HVAC Services', 'ma-hvac-lane-bedford', 'hvac', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Bedford Climate Control', 'ma-hvac-bedford-climate', 'hvac', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Fitch & Sons Heating', 'ma-hvac-fitch-sons-bedford', 'hvac', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Bedford Air Conditioning & Heat', 'ma-hvac-bedford-ac-heat', 'hvac', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),

    -- Belmont
    ('Belmont Heating & Cooling', 'ma-hvac-belmont-heating-cooling', 'hvac', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Underwood HVAC Services', 'ma-hvac-underwood-belmont', 'hvac', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Belmont Climate Control', 'ma-hvac-belmont-climate', 'hvac', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Wellington & Sons Heating', 'ma-hvac-wellington-sons-belmont', 'hvac', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Belmont Air Conditioning & Heat', 'ma-hvac-belmont-ac-heat', 'hvac', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),

    -- Billerica
    ('Billerica Heating & Cooling', 'ma-hvac-billerica-heating-cooling', 'hvac', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Manning HVAC Services', 'ma-hvac-manning-billerica', 'hvac', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Billerica Climate Control', 'ma-hvac-billerica-climate', 'hvac', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Pollard & Sons Heating', 'ma-hvac-pollard-sons-billerica', 'hvac', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Billerica Air Conditioning & Heat', 'ma-hvac-billerica-ac-heat', 'hvac', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),

    -- Boxborough
    ('Boxborough Heating & Cooling', 'ma-hvac-boxborough-heating-cooling', 'hvac', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Hager HVAC Services', 'ma-hvac-hager-boxborough', 'hvac', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Boxborough Climate Control', 'ma-hvac-boxborough-climate', 'hvac', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Blanchard & Sons Heating', 'ma-hvac-blanchard-sons-boxborough', 'hvac', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Boxborough Air Conditioning & Heat', 'ma-hvac-boxborough-ac-heat', 'hvac', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),

    -- Burlington
    ('Burlington Heating & Cooling', 'ma-hvac-burlington-heating-cooling', 'hvac', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Simonds HVAC Services', 'ma-hvac-simonds-burlington', 'hvac', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Burlington Climate Control', 'ma-hvac-burlington-climate', 'hvac', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Winn & Sons Heating', 'ma-hvac-winn-sons-burlington', 'hvac', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Burlington Air Conditioning & Heat', 'ma-hvac-burlington-ac-heat', 'hvac', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),

    -- Cambridge
    ('Cambridge Heating & Cooling', 'ma-hvac-cambridge-heating-cooling', 'hvac', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Hastings HVAC Services', 'ma-hvac-hastings-cambridge', 'hvac', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Cambridge Climate Control', 'ma-hvac-cambridge-climate', 'hvac', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Brattle & Sons Heating', 'ma-hvac-brattle-sons-cambridge', 'hvac', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Cambridge Air Conditioning & Heat', 'ma-hvac-cambridge-ac-heat', 'hvac', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),

    -- Carlisle
    ('Carlisle Heating & Cooling', 'ma-hvac-carlisle-heating-cooling', 'hvac', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Heald HVAC Services', 'ma-hvac-heald-carlisle', 'hvac', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Carlisle Climate Control', 'ma-hvac-carlisle-climate', 'hvac', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Spaulding & Sons Heating', 'ma-hvac-spaulding-sons-carlisle', 'hvac', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Carlisle Air Conditioning & Heat', 'ma-hvac-carlisle-ac-heat', 'hvac', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),

    -- Chelmsford
    ('Chelmsford Heating & Cooling', 'ma-hvac-chelmsford-heating-cooling', 'hvac', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Richardson HVAC Services', 'ma-hvac-richardson-chelmsford', 'hvac', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Chelmsford Climate Control', 'ma-hvac-chelmsford-climate', 'hvac', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Parkhurst & Sons Heating', 'ma-hvac-parkhurst-sons-chelmsford', 'hvac', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Chelmsford Air Conditioning & Heat', 'ma-hvac-chelmsford-ac-heat', 'hvac', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),

    -- Concord
    ('Concord Heating & Cooling', 'ma-hvac-concord-heating-cooling', 'hvac', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Thoreau HVAC Services', 'ma-hvac-thoreau-concord', 'hvac', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Concord Climate Control', 'ma-hvac-concord-climate', 'hvac', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Barrett & Sons Heating', 'ma-hvac-barrett-sons-concord', 'hvac', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Concord Air Conditioning & Heat', 'ma-hvac-concord-ac-heat', 'hvac', NULL, ARRAY['Concord','MA','Middlesex'], NULL),

    -- Dracut
    ('Dracut Heating & Cooling', 'ma-hvac-dracut-heating-cooling', 'hvac', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Collinsworth HVAC Services', 'ma-hvac-collinsworth-dracut', 'hvac', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Dracut Climate Control', 'ma-hvac-dracut-climate', 'hvac', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Coburn & Sons Heating', 'ma-hvac-coburn-sons-dracut', 'hvac', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Dracut Air Conditioning & Heat', 'ma-hvac-dracut-ac-heat', 'hvac', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),

    -- Dunstable
    ('Dunstable Heating & Cooling', 'ma-hvac-dunstable-heating-cooling', 'hvac', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Swallow HVAC Services', 'ma-hvac-swallow-dunstable', 'hvac', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Dunstable Climate Control', 'ma-hvac-dunstable-climate', 'hvac', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('French & Sons Heating', 'ma-hvac-french-sons-dunstable', 'hvac', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Dunstable Air Conditioning & Heat', 'ma-hvac-dunstable-ac-heat', 'hvac', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),

    -- Everett
    ('Everett Heating & Cooling', 'ma-hvac-everett-heating-cooling', 'hvac', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Glendale HVAC Services', 'ma-hvac-glendale-everett', 'hvac', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Everett Climate Control', 'ma-hvac-everett-climate', 'hvac', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Parlin & Sons Heating', 'ma-hvac-parlin-sons-everett', 'hvac', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Everett Air Conditioning & Heat', 'ma-hvac-everett-ac-heat', 'hvac', NULL, ARRAY['Everett','MA','Middlesex'], NULL),

    -- Framingham
    ('Framingham Heating & Cooling', 'ma-hvac-framingham-heating-cooling', 'hvac', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Buckminster HVAC Services', 'ma-hvac-buckminster-framingham', 'hvac', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Framingham Climate Control', 'ma-hvac-framingham-climate', 'hvac', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Danforth & Sons Heating', 'ma-hvac-danforth-sons-framingham', 'hvac', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Framingham Air Conditioning & Heat', 'ma-hvac-framingham-ac-heat', 'hvac', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),

    -- Groton
    ('Groton Heating & Cooling', 'ma-hvac-groton-heating-cooling', 'hvac', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Prescott HVAC Services', 'ma-hvac-prescott-groton', 'hvac', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Groton Climate Control', 'ma-hvac-groton-climate', 'hvac', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Lawrence & Sons Heating', 'ma-hvac-lawrence-sons-groton', 'hvac', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Groton Air Conditioning & Heat', 'ma-hvac-groton-ac-heat', 'hvac', NULL, ARRAY['Groton','MA','Middlesex'], NULL),

    -- Holliston
    ('Holliston Heating & Cooling', 'ma-hvac-holliston-heating-cooling', 'hvac', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Cutler HVAC Services', 'ma-hvac-cutler-holliston', 'hvac', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Holliston Climate Control', 'ma-hvac-holliston-climate', 'hvac', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Phipps & Sons Heating', 'ma-hvac-phipps-sons-holliston', 'hvac', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Holliston Air Conditioning & Heat', 'ma-hvac-holliston-ac-heat', 'hvac', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),

    -- Hopkinton
    ('Hopkinton Heating & Cooling', 'ma-hvac-hopkinton-heating-cooling', 'hvac', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Claflin HVAC Services', 'ma-hvac-claflin-hopkinton', 'hvac', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Hopkinton Climate Control', 'ma-hvac-hopkinton-climate', 'hvac', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Hayden & Sons Heating', 'ma-hvac-hayden-sons-hopkinton', 'hvac', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Hopkinton Air Conditioning & Heat', 'ma-hvac-hopkinton-ac-heat', 'hvac', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),

    -- Hudson
    ('Hudson Heating & Cooling', 'ma-hvac-hudson-heating-cooling', 'hvac', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Goodale HVAC Services', 'ma-hvac-goodale-hudson', 'hvac', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Hudson Climate Control', 'ma-hvac-hudson-climate', 'hvac', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Felton & Sons Heating', 'ma-hvac-felton-sons-hudson', 'hvac', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Hudson Air Conditioning & Heat', 'ma-hvac-hudson-ac-heat', 'hvac', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),

    -- Lexington
    ('Lexington Heating & Cooling', 'ma-hvac-lexington-heating-cooling', 'hvac', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Hancock HVAC Services', 'ma-hvac-hancock-lexington', 'hvac', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Lexington Climate Control', 'ma-hvac-lexington-climate', 'hvac', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Munroe & Sons Heating', 'ma-hvac-munroe-sons-lexington', 'hvac', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Lexington Air Conditioning & Heat', 'ma-hvac-lexington-ac-heat', 'hvac', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),

    -- Lincoln
    ('Lincoln Heating & Cooling', 'ma-hvac-lincoln-heating-cooling', 'hvac', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Codman HVAC Services', 'ma-hvac-codman-lincoln', 'hvac', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Lincoln Climate Control', 'ma-hvac-lincoln-climate', 'hvac', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Flint & Sons Heating', 'ma-hvac-flint-sons-lincoln', 'hvac', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Lincoln Air Conditioning & Heat', 'ma-hvac-lincoln-ac-heat', 'hvac', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),

    -- Littleton
    ('Littleton Heating & Cooling', 'ma-hvac-littleton-heating-cooling', 'hvac', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Hartwell HVAC Services', 'ma-hvac-hartwell-littleton', 'hvac', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Littleton Climate Control', 'ma-hvac-littleton-climate', 'hvac', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Shattuck & Sons Heating', 'ma-hvac-shattuck-sons-littleton', 'hvac', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Littleton Air Conditioning & Heat', 'ma-hvac-littleton-ac-heat', 'hvac', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),

    -- Lowell
    ('Lowell Heating & Cooling', 'ma-hvac-lowell-heating-cooling', 'hvac', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Mack HVAC Services', 'ma-hvac-mack-lowell', 'hvac', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Lowell Climate Control', 'ma-hvac-lowell-climate', 'hvac', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Merrimack & Sons Heating', 'ma-hvac-merrimack-sons-lowell', 'hvac', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Lowell Air Conditioning & Heat', 'ma-hvac-lowell-ac-heat', 'hvac', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),

    -- Malden
    ('Malden Heating & Cooling', 'ma-hvac-malden-heating-cooling', 'hvac', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Converse HVAC Services', 'ma-hvac-converse-malden', 'hvac', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Malden Climate Control', 'ma-hvac-malden-climate', 'hvac', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Devir & Sons Heating', 'ma-hvac-devir-sons-malden', 'hvac', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Malden Air Conditioning & Heat', 'ma-hvac-malden-ac-heat', 'hvac', NULL, ARRAY['Malden','MA','Middlesex'], NULL),

    -- Marlborough
    ('Marlborough Heating & Cooling', 'ma-hvac-marlborough-heating-cooling', 'hvac', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Bigelow HVAC Services', 'ma-hvac-bigelow-marlborough', 'hvac', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Marlborough Climate Control', 'ma-hvac-marlborough-climate', 'hvac', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Howe & Sons Heating', 'ma-hvac-howe-sons-marlborough', 'hvac', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Marlborough Air Conditioning & Heat', 'ma-hvac-marlborough-ac-heat', 'hvac', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),

    -- Maynard
    ('Maynard Heating & Cooling', 'ma-hvac-maynard-heating-cooling', 'hvac', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Nason HVAC Services', 'ma-hvac-nason-maynard', 'hvac', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Maynard Climate Control', 'ma-hvac-maynard-climate', 'hvac', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Fowler & Sons Heating', 'ma-hvac-fowler-sons-maynard', 'hvac', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Maynard Air Conditioning & Heat', 'ma-hvac-maynard-ac-heat', 'hvac', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),

    -- Medford
    ('Medford Heating & Cooling', 'ma-hvac-medford-heating-cooling', 'hvac', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Cradock HVAC Services', 'ma-hvac-cradock-medford', 'hvac', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Medford Climate Control', 'ma-hvac-medford-climate', 'hvac', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Brooks & Sons Heating', 'ma-hvac-brooks-sons-medford', 'hvac', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Medford Air Conditioning & Heat', 'ma-hvac-medford-ac-heat', 'hvac', NULL, ARRAY['Medford','MA','Middlesex'], NULL),

    -- Melrose
    ('Melrose Heating & Cooling', 'ma-hvac-melrose-heating-cooling', 'hvac', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Lynde HVAC Services', 'ma-hvac-lynde-melrose', 'hvac', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Melrose Climate Control', 'ma-hvac-melrose-climate', 'hvac', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Upham & Sons Heating', 'ma-hvac-upham-sons-melrose', 'hvac', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Melrose Air Conditioning & Heat', 'ma-hvac-melrose-ac-heat', 'hvac', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),

    -- Natick
    ('Natick Heating & Cooling', 'ma-hvac-natick-heating-cooling', 'hvac', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Walcott HVAC Services', 'ma-hvac-walcott-natick', 'hvac', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Natick Climate Control', 'ma-hvac-natick-climate', 'hvac', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Morse & Sons Heating', 'ma-hvac-morse-sons-natick', 'hvac', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Natick Air Conditioning & Heat', 'ma-hvac-natick-ac-heat', 'hvac', NULL, ARRAY['Natick','MA','Middlesex'], NULL),

    -- Newton
    ('Newton Heating & Cooling', 'ma-hvac-newton-heating-cooling', 'hvac', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Eliot HVAC Services', 'ma-hvac-eliot-newton', 'hvac', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Newton Climate Control', 'ma-hvac-newton-climate', 'hvac', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Otis & Sons Heating', 'ma-hvac-otis-sons-newton', 'hvac', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Newton Air Conditioning & Heat', 'ma-hvac-newton-ac-heat', 'hvac', NULL, ARRAY['Newton','MA','Middlesex'], NULL),

    -- North Reading
    ('North Reading Heating & Cooling', 'ma-hvac-north-reading-heating-cooling', 'hvac', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('Flint HVAC Services', 'ma-hvac-flint-north-reading', 'hvac', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('North Reading Climate Control', 'ma-hvac-north-reading-climate', 'hvac', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('Upton & Sons Heating', 'ma-hvac-upton-sons-north-reading', 'hvac', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('North Reading Air Conditioning & Heat', 'ma-hvac-north-reading-ac-heat', 'hvac', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),

    -- Pepperell
    ('Pepperell Heating & Cooling', 'ma-hvac-pepperell-heating-cooling', 'hvac', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Tarbell HVAC Services', 'ma-hvac-tarbell-pepperell', 'hvac', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Pepperell Climate Control', 'ma-hvac-pepperell-climate', 'hvac', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Jewett & Sons Heating', 'ma-hvac-jewett-sons-pepperell', 'hvac', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Pepperell Air Conditioning & Heat', 'ma-hvac-pepperell-ac-heat', 'hvac', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),

    -- Reading
    ('Reading Heating & Cooling', 'ma-hvac-reading-heating-cooling', 'hvac', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Parker HVAC Services', 'ma-hvac-parker-reading', 'hvac', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Reading Climate Control', 'ma-hvac-reading-climate', 'hvac', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Bancroft & Sons Heating', 'ma-hvac-bancroft-sons-reading', 'hvac', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Reading Air Conditioning & Heat', 'ma-hvac-reading-ac-heat', 'hvac', NULL, ARRAY['Reading','MA','Middlesex'], NULL),

    -- Sherborn
    ('Sherborn Heating & Cooling', 'ma-hvac-sherborn-heating-cooling', 'hvac', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Dowse HVAC Services', 'ma-hvac-dowse-sherborn', 'hvac', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Sherborn Climate Control', 'ma-hvac-sherborn-climate', 'hvac', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Holbrook & Sons Heating', 'ma-hvac-holbrook-sons-sherborn', 'hvac', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Sherborn Air Conditioning & Heat', 'ma-hvac-sherborn-ac-heat', 'hvac', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),

    -- Shirley
    ('Shirley Heating & Cooling', 'ma-hvac-shirley-heating-cooling', 'hvac', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Longley HVAC Services', 'ma-hvac-longley-shirley', 'hvac', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Shirley Climate Control', 'ma-hvac-shirley-climate', 'hvac', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Hazen & Sons Heating', 'ma-hvac-hazen-sons-shirley', 'hvac', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Shirley Air Conditioning & Heat', 'ma-hvac-shirley-ac-heat', 'hvac', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),

    -- Somerville
    ('Somerville Heating & Cooling', 'ma-hvac-somerville-heating-cooling', 'hvac', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Tufts HVAC Services', 'ma-hvac-tufts-somerville', 'hvac', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Somerville Climate Control', 'ma-hvac-somerville-climate', 'hvac', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Magoun & Sons Heating', 'ma-hvac-magoun-sons-somerville', 'hvac', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Somerville Air Conditioning & Heat', 'ma-hvac-somerville-ac-heat', 'hvac', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),

    -- Stoneham
    ('Stoneham Heating & Cooling', 'ma-hvac-stoneham-heating-cooling', 'hvac', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Goss HVAC Services', 'ma-hvac-goss-stoneham', 'hvac', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Stoneham Climate Control', 'ma-hvac-stoneham-climate', 'hvac', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Hill & Sons Heating', 'ma-hvac-hill-sons-stoneham', 'hvac', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Stoneham Air Conditioning & Heat', 'ma-hvac-stoneham-ac-heat', 'hvac', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),

    -- Stow
    ('Stow Heating & Cooling', 'ma-hvac-stow-heating-cooling', 'hvac', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Randall HVAC Services', 'ma-hvac-randall-stow', 'hvac', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Stow Climate Control', 'ma-hvac-stow-climate', 'hvac', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Gates & Sons Heating', 'ma-hvac-gates-sons-stow', 'hvac', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Stow Air Conditioning & Heat', 'ma-hvac-stow-ac-heat', 'hvac', NULL, ARRAY['Stow','MA','Middlesex'], NULL),

    -- Sudbury
    ('Sudbury Heating & Cooling', 'ma-hvac-sudbury-heating-cooling', 'hvac', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Goodenow HVAC Services', 'ma-hvac-goodenow-sudbury', 'hvac', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Sudbury Climate Control', 'ma-hvac-sudbury-climate', 'hvac', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Haynes & Sons Heating', 'ma-hvac-haynes-sons-sudbury', 'hvac', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Sudbury Air Conditioning & Heat', 'ma-hvac-sudbury-ac-heat', 'hvac', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),

    -- Tewksbury
    ('Tewksbury Heating & Cooling', 'ma-hvac-tewksbury-heating-cooling', 'hvac', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Trull HVAC Services', 'ma-hvac-trull-tewksbury', 'hvac', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Tewksbury Climate Control', 'ma-hvac-tewksbury-climate', 'hvac', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Foster & Sons Heating', 'ma-hvac-foster-sons-tewksbury', 'hvac', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Tewksbury Air Conditioning & Heat', 'ma-hvac-tewksbury-ac-heat', 'hvac', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),

    -- Townsend
    ('Townsend Heating & Cooling', 'ma-hvac-townsend-heating-cooling', 'hvac', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Reed HVAC Services', 'ma-hvac-reed-townsend', 'hvac', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Townsend Climate Control', 'ma-hvac-townsend-climate', 'hvac', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Conant & Sons Heating', 'ma-hvac-conant-sons-townsend', 'hvac', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Townsend Air Conditioning & Heat', 'ma-hvac-townsend-ac-heat', 'hvac', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),

    -- Tyngsborough
    ('Tyngsborough Heating & Cooling', 'ma-hvac-tyngsborough-heating-cooling', 'hvac', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Winslow HVAC Services', 'ma-hvac-winslow-tyngsborough', 'hvac', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Tyngsborough Climate Control', 'ma-hvac-tyngsborough-climate', 'hvac', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Brinley & Sons Heating', 'ma-hvac-brinley-sons-tyngsborough', 'hvac', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Tyngsborough Air Conditioning & Heat', 'ma-hvac-tyngsborough-ac-heat', 'hvac', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),

    -- Wakefield
    ('Wakefield Heating & Cooling', 'ma-hvac-wakefield-heating-cooling', 'hvac', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Eaton HVAC Services', 'ma-hvac-eaton-wakefield', 'hvac', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Wakefield Climate Control', 'ma-hvac-wakefield-climate', 'hvac', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Sweetser & Sons Heating', 'ma-hvac-sweetser-sons-wakefield', 'hvac', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Wakefield Air Conditioning & Heat', 'ma-hvac-wakefield-ac-heat', 'hvac', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),

    -- Waltham
    ('Waltham Heating & Cooling', 'ma-hvac-waltham-heating-cooling', 'hvac', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Lyman HVAC Services', 'ma-hvac-lyman-waltham', 'hvac', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Waltham Climate Control', 'ma-hvac-waltham-climate', 'hvac', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Moody & Sons Heating', 'ma-hvac-moody-sons-waltham', 'hvac', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Waltham Air Conditioning & Heat', 'ma-hvac-waltham-ac-heat', 'hvac', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),

    -- Watertown
    ('Watertown Heating & Cooling', 'ma-hvac-watertown-heating-cooling', 'hvac', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Coolidge HVAC Services', 'ma-hvac-coolidge-watertown', 'hvac', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Watertown Climate Control', 'ma-hvac-watertown-climate', 'hvac', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Whitney & Sons Heating', 'ma-hvac-whitney-sons-watertown', 'hvac', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Watertown Air Conditioning & Heat', 'ma-hvac-watertown-ac-heat', 'hvac', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),

    -- Wayland
    ('Wayland Heating & Cooling', 'ma-hvac-wayland-heating-cooling', 'hvac', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Heard HVAC Services', 'ma-hvac-heard-wayland', 'hvac', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Wayland Climate Control', 'ma-hvac-wayland-climate', 'hvac', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Draper & Sons Heating', 'ma-hvac-draper-sons-wayland', 'hvac', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Wayland Air Conditioning & Heat', 'ma-hvac-wayland-ac-heat', 'hvac', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),

    -- Westford
    ('Westford Heating & Cooling', 'ma-hvac-westford-heating-cooling', 'hvac', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Fletcher HVAC Services', 'ma-hvac-fletcher-westford', 'hvac', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Westford Climate Control', 'ma-hvac-westford-climate', 'hvac', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Hildreth & Sons Heating', 'ma-hvac-hildreth-sons-westford', 'hvac', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Westford Air Conditioning & Heat', 'ma-hvac-westford-ac-heat', 'hvac', NULL, ARRAY['Westford','MA','Middlesex'], NULL),

    -- Weston
    ('Weston Heating & Cooling', 'ma-hvac-weston-heating-cooling', 'hvac', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Coburn HVAC Services', 'ma-hvac-coburn-weston', 'hvac', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Weston Climate Control', 'ma-hvac-weston-climate', 'hvac', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Hobbs & Sons Heating', 'ma-hvac-hobbs-sons-weston', 'hvac', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Weston Air Conditioning & Heat', 'ma-hvac-weston-ac-heat', 'hvac', NULL, ARRAY['Weston','MA','Middlesex'], NULL),

    -- Wilmington
    ('Wilmington Heating & Cooling', 'ma-hvac-wilmington-heating-cooling', 'hvac', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Jaquith HVAC Services', 'ma-hvac-jaquith-wilmington', 'hvac', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Wilmington Climate Control', 'ma-hvac-wilmington-climate', 'hvac', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Harnden & Sons Heating', 'ma-hvac-harnden-sons-wilmington', 'hvac', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Wilmington Air Conditioning & Heat', 'ma-hvac-wilmington-ac-heat', 'hvac', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),

    -- Winchester
    ('Winchester Heating & Cooling', 'ma-hvac-winchester-heating-cooling', 'hvac', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Symmes HVAC Services', 'ma-hvac-symmes-winchester', 'hvac', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Winchester Climate Control', 'ma-hvac-winchester-climate', 'hvac', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Bacon & Sons Heating', 'ma-hvac-bacon-sons-winchester', 'hvac', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Winchester Air Conditioning & Heat', 'ma-hvac-winchester-ac-heat', 'hvac', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),

    -- Woburn
    ('Woburn Heating & Cooling', 'ma-hvac-woburn-heating-cooling', 'hvac', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Thompson HVAC Services', 'ma-hvac-thompson-woburn', 'hvac', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Woburn Climate Control', 'ma-hvac-woburn-climate', 'hvac', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Tidd & Sons Heating', 'ma-hvac-tidd-sons-woburn', 'hvac', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Woburn Air Conditioning & Heat', 'ma-hvac-woburn-ac-heat', 'hvac', NULL, ARRAY['Woburn','MA','Middlesex'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 4: NORFOLK COUNTY LOCAL HVAC (27 towns x 5)
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Avon
    ('Avon Heating & Cooling', 'ma-hvac-avon-heating-cooling', 'hvac', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Littlefield HVAC Services', 'ma-hvac-littlefield-avon', 'hvac', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Avon Climate Control', 'ma-hvac-avon-climate', 'hvac', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Packard & Sons Heating', 'ma-hvac-packard-sons-avon', 'hvac', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Avon Air Conditioning & Heat', 'ma-hvac-avon-ac-heat', 'hvac', NULL, ARRAY['Avon','MA','Norfolk'], NULL),

    -- Braintree
    ('Braintree Heating & Cooling', 'ma-hvac-braintree-heating-cooling', 'hvac', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Thayer HVAC Services', 'ma-hvac-thayer-braintree', 'hvac', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Braintree Climate Control', 'ma-hvac-braintree-climate', 'hvac', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Penniman & Sons Heating', 'ma-hvac-penniman-sons-braintree', 'hvac', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Braintree Air Conditioning & Heat', 'ma-hvac-braintree-ac-heat', 'hvac', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),

    -- Brookline
    ('Brookline Heating & Cooling', 'ma-hvac-brookline-heating-cooling', 'hvac', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Aspinwall HVAC Services', 'ma-hvac-aspinwall-brookline', 'hvac', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Brookline Climate Control', 'ma-hvac-brookline-climate', 'hvac', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Devotion & Sons Heating', 'ma-hvac-devotion-sons-brookline', 'hvac', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Brookline Air Conditioning & Heat', 'ma-hvac-brookline-ac-heat', 'hvac', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),

    -- Canton
    ('Canton Heating & Cooling', 'ma-hvac-canton-heating-cooling', 'hvac', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Revere HVAC Services', 'ma-hvac-revere-canton', 'hvac', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Canton Climate Control', 'ma-hvac-canton-climate', 'hvac', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Dunbar & Sons Heating', 'ma-hvac-dunbar-sons-canton', 'hvac', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Canton Air Conditioning & Heat', 'ma-hvac-canton-ac-heat', 'hvac', NULL, ARRAY['Canton','MA','Norfolk'], NULL),

    -- Cohasset
    ('Cohasset Heating & Cooling', 'ma-hvac-cohasset-heating-cooling', 'hvac', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Bates HVAC Services', 'ma-hvac-bates-cohasset', 'hvac', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Cohasset Climate Control', 'ma-hvac-cohasset-climate', 'hvac', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Pratt & Sons Heating', 'ma-hvac-pratt-sons-cohasset', 'hvac', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Cohasset Air Conditioning & Heat', 'ma-hvac-cohasset-ac-heat', 'hvac', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),

    -- Dedham
    ('Dedham Heating & Cooling', 'ma-hvac-dedham-heating-cooling', 'hvac', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Avery HVAC Services', 'ma-hvac-avery-dedham', 'hvac', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Dedham Climate Control', 'ma-hvac-dedham-climate', 'hvac', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Fairbanks & Sons Heating', 'ma-hvac-fairbanks-sons-dedham', 'hvac', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Dedham Air Conditioning & Heat', 'ma-hvac-dedham-ac-heat', 'hvac', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),

    -- Dover
    ('Dover Heating & Cooling', 'ma-hvac-dover-heating-cooling', 'hvac', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Battelle HVAC Services', 'ma-hvac-battelle-dover', 'hvac', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Dover Climate Control', 'ma-hvac-dover-climate', 'hvac', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Chickering & Sons Heating', 'ma-hvac-chickering-sons-dover', 'hvac', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Dover Air Conditioning & Heat', 'ma-hvac-dover-ac-heat', 'hvac', NULL, ARRAY['Dover','MA','Norfolk'], NULL),

    -- Foxborough
    ('Foxborough Heating & Cooling', 'ma-hvac-foxborough-heating-cooling', 'hvac', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Carpenter HVAC Services', 'ma-hvac-carpenter-foxborough', 'hvac', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Foxborough Climate Control', 'ma-hvac-foxborough-climate', 'hvac', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Boyden & Sons Heating', 'ma-hvac-boyden-sons-foxborough', 'hvac', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Foxborough Air Conditioning & Heat', 'ma-hvac-foxborough-ac-heat', 'hvac', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),

    -- Franklin
    ('Franklin Heating & Cooling', 'ma-hvac-franklin-heating-cooling', 'hvac', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Metcalf HVAC Services', 'ma-hvac-metcalf-franklin', 'hvac', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Franklin Climate Control', 'ma-hvac-franklin-climate', 'hvac', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Ray & Sons Heating', 'ma-hvac-ray-sons-franklin', 'hvac', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Franklin Air Conditioning & Heat', 'ma-hvac-franklin-ac-heat', 'hvac', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),

    -- Holbrook
    ('Holbrook Heating & Cooling', 'ma-hvac-holbrook-heating-cooling', 'hvac', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Niles HVAC Services', 'ma-hvac-niles-holbrook', 'hvac', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Holbrook Climate Control', 'ma-hvac-holbrook-climate', 'hvac', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Thayer & Sons Heating', 'ma-hvac-thayer-sons-holbrook', 'hvac', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Holbrook Air Conditioning & Heat', 'ma-hvac-holbrook-ac-heat', 'hvac', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),

    -- Medfield
    ('Medfield Heating & Cooling', 'ma-hvac-medfield-heating-cooling', 'hvac', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Chenery HVAC Services', 'ma-hvac-chenery-medfield', 'hvac', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Medfield Climate Control', 'ma-hvac-medfield-climate', 'hvac', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Plimpton & Sons Heating', 'ma-hvac-plimpton-sons-medfield', 'hvac', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Medfield Air Conditioning & Heat', 'ma-hvac-medfield-ac-heat', 'hvac', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),

    -- Medway
    ('Medway Heating & Cooling', 'ma-hvac-medway-heating-cooling', 'hvac', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Lovering HVAC Services', 'ma-hvac-lovering-medway', 'hvac', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Medway Climate Control', 'ma-hvac-medway-climate', 'hvac', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Sanford & Sons Heating', 'ma-hvac-sanford-sons-medway', 'hvac', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Medway Air Conditioning & Heat', 'ma-hvac-medway-ac-heat', 'hvac', NULL, ARRAY['Medway','MA','Norfolk'], NULL),

    -- Millis
    ('Millis Heating & Cooling', 'ma-hvac-millis-heating-cooling', 'hvac', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Rockwell HVAC Services', 'ma-hvac-rockwell-millis', 'hvac', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Millis Climate Control', 'ma-hvac-millis-climate', 'hvac', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Richardson & Sons Heating', 'ma-hvac-richardson-sons-millis', 'hvac', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Millis Air Conditioning & Heat', 'ma-hvac-millis-ac-heat', 'hvac', NULL, ARRAY['Millis','MA','Norfolk'], NULL),

    -- Milton
    ('Milton Heating & Cooling', 'ma-hvac-milton-heating-cooling', 'hvac', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Tucker HVAC Services', 'ma-hvac-tucker-milton', 'hvac', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Milton Climate Control', 'ma-hvac-milton-climate', 'hvac', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Vose & Sons Heating', 'ma-hvac-vose-sons-milton', 'hvac', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Milton Air Conditioning & Heat', 'ma-hvac-milton-ac-heat', 'hvac', NULL, ARRAY['Milton','MA','Norfolk'], NULL),

    -- Needham
    ('Needham Heating & Cooling', 'ma-hvac-needham-heating-cooling', 'hvac', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Kingsbury HVAC Services', 'ma-hvac-kingsbury-needham', 'hvac', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Needham Climate Control', 'ma-hvac-needham-climate', 'hvac', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Eaton & Sons Heating', 'ma-hvac-eaton-sons-needham', 'hvac', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Needham Air Conditioning & Heat', 'ma-hvac-needham-ac-heat', 'hvac', NULL, ARRAY['Needham','MA','Norfolk'], NULL),

    -- Norfolk
    ('Norfolk Heating & Cooling', 'ma-hvac-norfolk-heating-cooling', 'hvac', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Pond HVAC Services', 'ma-hvac-pond-norfolk', 'hvac', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Norfolk Climate Control', 'ma-hvac-norfolk-climate', 'hvac', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Mann & Sons Heating', 'ma-hvac-mann-sons-norfolk', 'hvac', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Norfolk Air Conditioning & Heat', 'ma-hvac-norfolk-ac-heat', 'hvac', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),

    -- Norwood
    ('Norwood Heating & Cooling', 'ma-hvac-norwood-heating-cooling', 'hvac', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Guild HVAC Services', 'ma-hvac-guild-norwood', 'hvac', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Norwood Climate Control', 'ma-hvac-norwood-climate', 'hvac', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Morse & Sons Heating', 'ma-hvac-morse-sons-norwood', 'hvac', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Norwood Air Conditioning & Heat', 'ma-hvac-norwood-ac-heat', 'hvac', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),

    -- Plainville
    ('Plainville Heating & Cooling', 'ma-hvac-plainville-heating-cooling', 'hvac', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Fuller HVAC Services', 'ma-hvac-fuller-plainville', 'hvac', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Plainville Climate Control', 'ma-hvac-plainville-climate', 'hvac', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Shepard & Sons Heating', 'ma-hvac-shepard-sons-plainville', 'hvac', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Plainville Air Conditioning & Heat', 'ma-hvac-plainville-ac-heat', 'hvac', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),

    -- Quincy
    ('Quincy Heating & Cooling', 'ma-hvac-quincy-heating-cooling', 'hvac', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Adams HVAC Services', 'ma-hvac-adams-quincy', 'hvac', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Quincy Climate Control', 'ma-hvac-quincy-climate', 'hvac', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Hancock & Sons Heating', 'ma-hvac-hancock-sons-quincy', 'hvac', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Quincy Air Conditioning & Heat', 'ma-hvac-quincy-ac-heat', 'hvac', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),

    -- Randolph
    ('Randolph Heating & Cooling', 'ma-hvac-randolph-heating-cooling', 'hvac', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Stetson HVAC Services', 'ma-hvac-stetson-randolph', 'hvac', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Randolph Climate Control', 'ma-hvac-randolph-climate', 'hvac', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Tower & Sons Heating', 'ma-hvac-tower-sons-randolph', 'hvac', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Randolph Air Conditioning & Heat', 'ma-hvac-randolph-ac-heat', 'hvac', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),

    -- Sharon
    ('Sharon Heating & Cooling', 'ma-hvac-sharon-heating-cooling', 'hvac', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Billings HVAC Services', 'ma-hvac-billings-sharon', 'hvac', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Sharon Climate Control', 'ma-hvac-sharon-climate', 'hvac', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Massapoag & Sons Heating', 'ma-hvac-massapoag-sons-sharon', 'hvac', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Sharon Air Conditioning & Heat', 'ma-hvac-sharon-ac-heat', 'hvac', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),

    -- Stoughton
    ('Stoughton Heating & Cooling', 'ma-hvac-stoughton-heating-cooling', 'hvac', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Drake HVAC Services', 'ma-hvac-drake-stoughton', 'hvac', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Stoughton Climate Control', 'ma-hvac-stoughton-climate', 'hvac', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Curtis & Sons Heating', 'ma-hvac-curtis-sons-stoughton', 'hvac', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Stoughton Air Conditioning & Heat', 'ma-hvac-stoughton-ac-heat', 'hvac', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),

    -- Walpole
    ('Walpole Heating & Cooling', 'ma-hvac-walpole-heating-cooling', 'hvac', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Lewis HVAC Services', 'ma-hvac-lewis-walpole', 'hvac', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Walpole Climate Control', 'ma-hvac-walpole-climate', 'hvac', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Fisher & Sons Heating', 'ma-hvac-fisher-sons-walpole', 'hvac', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Walpole Air Conditioning & Heat', 'ma-hvac-walpole-ac-heat', 'hvac', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),

    -- Wellesley
    ('Wellesley Heating & Cooling', 'ma-hvac-wellesley-heating-cooling', 'hvac', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Hunnewell HVAC Services', 'ma-hvac-hunnewell-wellesley', 'hvac', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Wellesley Climate Control', 'ma-hvac-wellesley-climate', 'hvac', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Durant & Sons Heating', 'ma-hvac-durant-sons-wellesley', 'hvac', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Wellesley Air Conditioning & Heat', 'ma-hvac-wellesley-ac-heat', 'hvac', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),

    -- Westwood
    ('Westwood Heating & Cooling', 'ma-hvac-westwood-heating-cooling', 'hvac', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Colburn HVAC Services', 'ma-hvac-colburn-westwood', 'hvac', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Westwood Climate Control', 'ma-hvac-westwood-climate', 'hvac', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Baker & Sons Heating', 'ma-hvac-baker-sons-westwood', 'hvac', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Westwood Air Conditioning & Heat', 'ma-hvac-westwood-ac-heat', 'hvac', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),

    -- Weymouth
    ('Weymouth Heating & Cooling', 'ma-hvac-weymouth-heating-cooling', 'hvac', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Torrey HVAC Services', 'ma-hvac-torrey-weymouth', 'hvac', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Weymouth Climate Control', 'ma-hvac-weymouth-climate', 'hvac', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Beal & Sons Heating', 'ma-hvac-beal-sons-weymouth', 'hvac', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Weymouth Air Conditioning & Heat', 'ma-hvac-weymouth-ac-heat', 'hvac', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),

    -- Wrentham
    ('Wrentham Heating & Cooling', 'ma-hvac-wrentham-heating-cooling', 'hvac', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Hawes HVAC Services', 'ma-hvac-hawes-wrentham', 'hvac', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Wrentham Climate Control', 'ma-hvac-wrentham-climate', 'hvac', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Sheldon & Sons Heating', 'ma-hvac-sheldon-sons-wrentham', 'hvac', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Wrentham Air Conditioning & Heat', 'ma-hvac-wrentham-ac-heat', 'hvac', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 5: PLYMOUTH COUNTY LOCAL HVAC (27 towns x 5)
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Abington
    ('Abington Heating & Cooling', 'ma-hvac-abington-heating-cooling', 'hvac', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Nash HVAC Services', 'ma-hvac-nash-abington', 'hvac', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Abington Climate Control', 'ma-hvac-abington-climate', 'hvac', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Shaw & Sons Heating', 'ma-hvac-shaw-sons-abington', 'hvac', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Abington Air Conditioning & Heat', 'ma-hvac-abington-ac-heat', 'hvac', NULL, ARRAY['Abington','MA','Plymouth'], NULL),

    -- Bridgewater
    ('Bridgewater Heating & Cooling', 'ma-hvac-bridgewater-heating-cooling', 'hvac', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Keith HVAC Services', 'ma-hvac-keith-bridgewater', 'hvac', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Climate Control', 'ma-hvac-bridgewater-climate', 'hvac', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Mitchell & Sons Heating', 'ma-hvac-mitchell-sons-bridgewater', 'hvac', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Air Conditioning & Heat', 'ma-hvac-bridgewater-ac-heat', 'hvac', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),

    -- Brockton
    ('Brockton Heating & Cooling', 'ma-hvac-brockton-heating-cooling', 'hvac', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Montello HVAC Services', 'ma-hvac-montello-brockton', 'hvac', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Brockton Climate Control', 'ma-hvac-brockton-climate', 'hvac', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Perkins & Sons Heating', 'ma-hvac-perkins-sons-brockton', 'hvac', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Brockton Air Conditioning & Heat', 'ma-hvac-brockton-ac-heat', 'hvac', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),

    -- Carver
    ('Carver Heating & Cooling', 'ma-hvac-carver-heating-cooling', 'hvac', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Savery HVAC Services', 'ma-hvac-savery-carver', 'hvac', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Carver Climate Control', 'ma-hvac-carver-climate', 'hvac', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Atwood & Sons Heating', 'ma-hvac-atwood-sons-carver', 'hvac', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Carver Air Conditioning & Heat', 'ma-hvac-carver-ac-heat', 'hvac', NULL, ARRAY['Carver','MA','Plymouth'], NULL),

    -- Duxbury
    ('Duxbury Heating & Cooling', 'ma-hvac-duxbury-heating-cooling', 'hvac', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Standish HVAC Services', 'ma-hvac-standish-duxbury', 'hvac', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Duxbury Climate Control', 'ma-hvac-duxbury-climate', 'hvac', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Alden & Sons Heating', 'ma-hvac-alden-sons-duxbury', 'hvac', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Duxbury Air Conditioning & Heat', 'ma-hvac-duxbury-ac-heat', 'hvac', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),

    -- East Bridgewater
    ('East Bridgewater Heating & Cooling', 'ma-hvac-east-bridgewater-heating-cooling', 'hvac', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('Whitman HVAC Services', 'ma-hvac-whitman-east-bridgewater', 'hvac', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('East Bridgewater Climate Control', 'ma-hvac-east-bridgewater-climate', 'hvac', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('Hooper & Sons Heating', 'ma-hvac-hooper-sons-east-bridgewater', 'hvac', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('East Bridgewater Air Conditioning & Heat', 'ma-hvac-east-bridgewater-ac-heat', 'hvac', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),

    -- Halifax
    ('Halifax Heating & Cooling', 'ma-hvac-halifax-heating-cooling', 'hvac', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Thomson HVAC Services', 'ma-hvac-thomson-halifax', 'hvac', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Halifax Climate Control', 'ma-hvac-halifax-climate', 'hvac', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Sturtevant & Sons Heating', 'ma-hvac-sturtevant-sons-halifax', 'hvac', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Halifax Air Conditioning & Heat', 'ma-hvac-halifax-ac-heat', 'hvac', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),

    -- Hanover
    ('Hanover Heating & Cooling', 'ma-hvac-hanover-heating-cooling', 'hvac', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Stetson HVAC Services', 'ma-hvac-stetson-hanover', 'hvac', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Hanover Climate Control', 'ma-hvac-hanover-climate', 'hvac', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Salmond & Sons Heating', 'ma-hvac-salmond-sons-hanover', 'hvac', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Hanover Air Conditioning & Heat', 'ma-hvac-hanover-ac-heat', 'hvac', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),

    -- Hanson
    ('Hanson Heating & Cooling', 'ma-hvac-hanson-heating-cooling', 'hvac', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Phillips HVAC Services', 'ma-hvac-phillips-hanson', 'hvac', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Hanson Climate Control', 'ma-hvac-hanson-climate', 'hvac', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Waterman & Sons Heating', 'ma-hvac-waterman-sons-hanson', 'hvac', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Hanson Air Conditioning & Heat', 'ma-hvac-hanson-ac-heat', 'hvac', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),

    -- Hingham
    ('Hingham Heating & Cooling', 'ma-hvac-hingham-heating-cooling', 'hvac', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Cushing HVAC Services', 'ma-hvac-cushing-hingham', 'hvac', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Hingham Climate Control', 'ma-hvac-hingham-climate', 'hvac', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Lincoln & Sons Heating', 'ma-hvac-lincoln-sons-hingham', 'hvac', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Hingham Air Conditioning & Heat', 'ma-hvac-hingham-ac-heat', 'hvac', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),

    -- Hull
    ('Hull Heating & Cooling', 'ma-hvac-hull-heating-cooling', 'hvac', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Nantasket HVAC Services', 'ma-hvac-nantasket-hull', 'hvac', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Hull Climate Control', 'ma-hvac-hull-climate', 'hvac', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Loring & Sons Heating', 'ma-hvac-loring-sons-hull', 'hvac', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Hull Air Conditioning & Heat', 'ma-hvac-hull-ac-heat', 'hvac', NULL, ARRAY['Hull','MA','Plymouth'], NULL),

    -- Kingston
    ('Kingston Heating & Cooling', 'ma-hvac-kingston-heating-cooling', 'hvac', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Bradford HVAC Services', 'ma-hvac-bradford-kingston', 'hvac', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Kingston Climate Control', 'ma-hvac-kingston-climate', 'hvac', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Holmes & Sons Heating', 'ma-hvac-holmes-sons-kingston', 'hvac', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Kingston Air Conditioning & Heat', 'ma-hvac-kingston-ac-heat', 'hvac', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),

    -- Lakeville
    ('Lakeville Heating & Cooling', 'ma-hvac-lakeville-heating-cooling', 'hvac', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Precinct HVAC Services', 'ma-hvac-precinct-lakeville', 'hvac', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Lakeville Climate Control', 'ma-hvac-lakeville-climate', 'hvac', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Haskins & Sons Heating', 'ma-hvac-haskins-sons-lakeville', 'hvac', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Lakeville Air Conditioning & Heat', 'ma-hvac-lakeville-ac-heat', 'hvac', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),

    -- Marion
    ('Marion Heating & Cooling', 'ma-hvac-marion-heating-cooling', 'hvac', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Tabor HVAC Services', 'ma-hvac-tabor-marion', 'hvac', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Marion Climate Control', 'ma-hvac-marion-climate', 'hvac', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Delano & Sons Heating', 'ma-hvac-delano-sons-marion', 'hvac', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Marion Air Conditioning & Heat', 'ma-hvac-marion-ac-heat', 'hvac', NULL, ARRAY['Marion','MA','Plymouth'], NULL),

    -- Marshfield
    ('Marshfield Heating & Cooling', 'ma-hvac-marshfield-heating-cooling', 'hvac', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Winslow HVAC Services', 'ma-hvac-winslow-marshfield', 'hvac', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Marshfield Climate Control', 'ma-hvac-marshfield-climate', 'hvac', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Thomas & Sons Heating', 'ma-hvac-thomas-sons-marshfield', 'hvac', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Marshfield Air Conditioning & Heat', 'ma-hvac-marshfield-ac-heat', 'hvac', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),

    -- Mattapoisett
    ('Mattapoisett Heating & Cooling', 'ma-hvac-mattapoisett-heating-cooling', 'hvac', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Barstow HVAC Services', 'ma-hvac-barstow-mattapoisett', 'hvac', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Mattapoisett Climate Control', 'ma-hvac-mattapoisett-climate', 'hvac', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Cannon & Sons Heating', 'ma-hvac-cannon-sons-mattapoisett', 'hvac', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Mattapoisett Air Conditioning & Heat', 'ma-hvac-mattapoisett-ac-heat', 'hvac', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),

    -- Middleborough
    ('Middleborough Heating & Cooling', 'ma-hvac-middleborough-heating-cooling', 'hvac', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Tinkham HVAC Services', 'ma-hvac-tinkham-middleborough', 'hvac', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Middleborough Climate Control', 'ma-hvac-middleborough-climate', 'hvac', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Wood & Sons Heating', 'ma-hvac-wood-sons-middleborough', 'hvac', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Middleborough Air Conditioning & Heat', 'ma-hvac-middleborough-ac-heat', 'hvac', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),

    -- Norwell
    ('Norwell Heating & Cooling', 'ma-hvac-norwell-heating-cooling', 'hvac', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Jacobs HVAC Services', 'ma-hvac-jacobs-norwell', 'hvac', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Norwell Climate Control', 'ma-hvac-norwell-climate', 'hvac', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Damon & Sons Heating', 'ma-hvac-damon-sons-norwell', 'hvac', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Norwell Air Conditioning & Heat', 'ma-hvac-norwell-ac-heat', 'hvac', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),

    -- Pembroke
    ('Pembroke Heating & Cooling', 'ma-hvac-pembroke-heating-cooling', 'hvac', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Barker HVAC Services', 'ma-hvac-barker-pembroke', 'hvac', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Pembroke Climate Control', 'ma-hvac-pembroke-climate', 'hvac', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Turner & Sons Heating', 'ma-hvac-turner-sons-pembroke', 'hvac', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Pembroke Air Conditioning & Heat', 'ma-hvac-pembroke-ac-heat', 'hvac', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),

    -- Plymouth
    ('Plymouth Heating & Cooling', 'ma-hvac-plymouth-heating-cooling', 'hvac', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Bradford HVAC Services', 'ma-hvac-bradford-plymouth', 'hvac', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Plymouth Climate Control', 'ma-hvac-plymouth-climate', 'hvac', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Brewster & Sons Heating', 'ma-hvac-brewster-sons-plymouth', 'hvac', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Plymouth Air Conditioning & Heat', 'ma-hvac-plymouth-ac-heat', 'hvac', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),

    -- Plympton
    ('Plympton Heating & Cooling', 'ma-hvac-plympton-heating-cooling', 'hvac', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Soule HVAC Services', 'ma-hvac-soule-plympton', 'hvac', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Plympton Climate Control', 'ma-hvac-plympton-climate', 'hvac', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Harlow & Sons Heating', 'ma-hvac-harlow-sons-plympton', 'hvac', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Plympton Air Conditioning & Heat', 'ma-hvac-plympton-ac-heat', 'hvac', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),

    -- Rochester
    ('Rochester Heating & Cooling', 'ma-hvac-rochester-heating-cooling', 'hvac', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Hartley HVAC Services', 'ma-hvac-hartley-rochester', 'hvac', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Rochester Climate Control', 'ma-hvac-rochester-climate', 'hvac', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Leonard & Sons Heating', 'ma-hvac-leonard-sons-rochester', 'hvac', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Rochester Air Conditioning & Heat', 'ma-hvac-rochester-ac-heat', 'hvac', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),

    -- Rockland
    ('Rockland Heating & Cooling', 'ma-hvac-rockland-heating-cooling', 'hvac', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Reed HVAC Services', 'ma-hvac-reed-rockland', 'hvac', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Rockland Climate Control', 'ma-hvac-rockland-climate', 'hvac', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Jenkins & Sons Heating', 'ma-hvac-jenkins-sons-rockland', 'hvac', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Rockland Air Conditioning & Heat', 'ma-hvac-rockland-ac-heat', 'hvac', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),

    -- Scituate
    ('Scituate Heating & Cooling', 'ma-hvac-scituate-heating-cooling', 'hvac', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Lawson HVAC Services', 'ma-hvac-lawson-scituate', 'hvac', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Scituate Climate Control', 'ma-hvac-scituate-climate', 'hvac', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Bailey & Sons Heating', 'ma-hvac-bailey-sons-scituate', 'hvac', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Scituate Air Conditioning & Heat', 'ma-hvac-scituate-ac-heat', 'hvac', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),

    -- Wareham
    ('Wareham Heating & Cooling', 'ma-hvac-wareham-heating-cooling', 'hvac', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Fearing HVAC Services', 'ma-hvac-fearing-wareham', 'hvac', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Wareham Climate Control', 'ma-hvac-wareham-climate', 'hvac', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Besse & Sons Heating', 'ma-hvac-besse-sons-wareham', 'hvac', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Wareham Air Conditioning & Heat', 'ma-hvac-wareham-ac-heat', 'hvac', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),

    -- West Bridgewater
    ('West Bridgewater Heating & Cooling', 'ma-hvac-west-bridgewater-heating-cooling', 'hvac', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('Howard HVAC Services', 'ma-hvac-howard-west-bridgewater', 'hvac', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('West Bridgewater Climate Control', 'ma-hvac-west-bridgewater-climate', 'hvac', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('Packard & Sons Heating', 'ma-hvac-packard-sons-west-bridgewater', 'hvac', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('West Bridgewater Air Conditioning & Heat', 'ma-hvac-west-bridgewater-ac-heat', 'hvac', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),

    -- Whitman
    ('Whitman Heating & Cooling', 'ma-hvac-whitman-heating-cooling', 'hvac', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Corthell HVAC Services', 'ma-hvac-corthell-whitman', 'hvac', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Whitman Climate Control', 'ma-hvac-whitman-climate', 'hvac', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Hobart & Sons Heating', 'ma-hvac-hobart-sons-whitman', 'hvac', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Whitman Air Conditioning & Heat', 'ma-hvac-whitman-ac-heat', 'hvac', NULL, ARRAY['Whitman','MA','Plymouth'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 6: MA REGIONAL PLUMBING COMPANIES
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    ('Silco Plumbing', 'ma-plumbing-silco', 'plumbing', 'https://www.silcoplumbing.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('RH Blanchard Plumbing', 'ma-plumbing-rh-blanchard', 'plumbing', 'https://www.rhblanchardplumbing.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Deer Hill Plumbing & Heating', 'ma-plumbing-deer-hill', 'plumbing', 'https://www.deerhillplumbing.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('James Beshara Plumbing', 'ma-plumbing-beshara', 'plumbing', 'https://www.besharaplumbing.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Blanchards Plumbing', 'ma-plumbing-blanchards', 'plumbing', 'https://www.blanchardsplumbing.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Paul Revere Plumbing', 'ma-plumbing-paul-revere', 'plumbing', 'https://www.paulrevereplumbing.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Pilgrim Plumbing & Heating', 'ma-plumbing-pilgrim', 'plumbing', 'https://www.pilgrimplumbing.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Metro West Plumbing', 'ma-plumbing-metro-west', 'plumbing', 'https://www.metrowestplumbing.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Bay Colony Plumbing', 'ma-plumbing-bay-colony', 'plumbing', 'https://www.baycolonyplumbing.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Norwood Plumbing & Heating', 'ma-plumbing-norwood-regional', 'plumbing', 'https://www.norwoodplumbing.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Commonwealth Plumbing Group', 'ma-plumbing-commonwealth', 'plumbing', NULL, ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Boston Metro Plumbing', 'ma-plumbing-boston-metro', 'plumbing', NULL, ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 7: ESSEX COUNTY LOCAL PLUMBING (33 towns x 5)
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Andover
    ('Andover Plumbing & Heating', 'ma-plumbing-andover-plumbing-heating', 'plumbing', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Sullivan Plumbing Services', 'ma-plumbing-sullivan-andover', 'plumbing', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Merrimack Plumbing Co.', 'ma-plumbing-merrimack-co-andover', 'plumbing', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Brennan & Son Plumbing', 'ma-plumbing-brennan-son-andover', 'plumbing', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Andover Drain & Pipe', 'ma-plumbing-andover-drain-pipe', 'plumbing', NULL, ARRAY['Andover','MA','Essex'], NULL),

    -- Beverly
    ('Beverly Plumbing & Heating', 'ma-plumbing-beverly-plumbing-heating', 'plumbing', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Harrington Plumbing Services', 'ma-plumbing-harrington-beverly', 'plumbing', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('North Shore Plumbing Co.', 'ma-plumbing-north-shore-co-beverly', 'plumbing', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Callahan & Son Plumbing', 'ma-plumbing-callahan-son-beverly', 'plumbing', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Beverly Drain & Pipe', 'ma-plumbing-beverly-drain-pipe', 'plumbing', NULL, ARRAY['Beverly','MA','Essex'], NULL),

    -- Boxford
    ('Boxford Plumbing & Heating', 'ma-plumbing-boxford-plumbing-heating', 'plumbing', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Kelleher Plumbing Services', 'ma-plumbing-kelleher-boxford', 'plumbing', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Boxford Plumbing Co.', 'ma-plumbing-boxford-co', 'plumbing', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Perkins & Son Plumbing', 'ma-plumbing-perkins-son-boxford', 'plumbing', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Boxford Drain & Pipe', 'ma-plumbing-boxford-drain-pipe', 'plumbing', NULL, ARRAY['Boxford','MA','Essex'], NULL),

    -- Danvers
    ('Danvers Plumbing & Heating', 'ma-plumbing-danvers-plumbing-heating', 'plumbing', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Petralia Plumbing Services', 'ma-plumbing-petralia-danvers', 'plumbing', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Danvers Plumbing Co.', 'ma-plumbing-danvers-co', 'plumbing', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Donovan & Son Plumbing', 'ma-plumbing-donovan-son-danvers', 'plumbing', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Danvers Drain & Pipe', 'ma-plumbing-danvers-drain-pipe', 'plumbing', NULL, ARRAY['Danvers','MA','Essex'], NULL),

    -- Essex
    ('Essex Plumbing & Heating', 'ma-plumbing-essex-plumbing-heating', 'plumbing', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Burnham Plumbing Services', 'ma-plumbing-burnham-essex', 'plumbing', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Essex Plumbing Co.', 'ma-plumbing-essex-co', 'plumbing', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Choate & Son Plumbing', 'ma-plumbing-choate-son-essex', 'plumbing', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Essex Drain & Pipe', 'ma-plumbing-essex-drain-pipe', 'plumbing', NULL, ARRAY['Essex','MA','Essex'], NULL),

    -- Georgetown
    ('Georgetown Plumbing & Heating', 'ma-plumbing-georgetown-plumbing-heating', 'plumbing', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Thurlow Plumbing Services', 'ma-plumbing-thurlow-georgetown', 'plumbing', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Georgetown Plumbing Co.', 'ma-plumbing-georgetown-co', 'plumbing', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Keane & Son Plumbing', 'ma-plumbing-keane-son-georgetown', 'plumbing', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Georgetown Drain & Pipe', 'ma-plumbing-georgetown-drain-pipe', 'plumbing', NULL, ARRAY['Georgetown','MA','Essex'], NULL),

    -- Gloucester
    ('Gloucester Plumbing & Heating', 'ma-plumbing-gloucester-plumbing-heating', 'plumbing', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Favazza Plumbing Services', 'ma-plumbing-favazza-gloucester', 'plumbing', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Cape Ann Plumbing Co.', 'ma-plumbing-cape-ann-co-gloucester', 'plumbing', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Rallo & Son Plumbing', 'ma-plumbing-rallo-son-gloucester', 'plumbing', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Gloucester Drain & Pipe', 'ma-plumbing-gloucester-drain-pipe', 'plumbing', NULL, ARRAY['Gloucester','MA','Essex'], NULL),

    -- Groveland
    ('Groveland Plumbing & Heating', 'ma-plumbing-groveland-plumbing-heating', 'plumbing', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Batchelder Plumbing Services', 'ma-plumbing-batchelder-groveland', 'plumbing', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Pentucket Plumbing Co.', 'ma-plumbing-pentucket-co-groveland', 'plumbing', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Cross & Son Plumbing', 'ma-plumbing-cross-son-groveland', 'plumbing', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Groveland Drain & Pipe', 'ma-plumbing-groveland-drain-pipe', 'plumbing', NULL, ARRAY['Groveland','MA','Essex'], NULL),

    -- Hamilton
    ('Hamilton Plumbing & Heating', 'ma-plumbing-hamilton-plumbing-heating', 'plumbing', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Appleton Plumbing Services', 'ma-plumbing-appleton-hamilton', 'plumbing', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Hamilton Plumbing Co.', 'ma-plumbing-hamilton-co', 'plumbing', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Wenham & Son Plumbing', 'ma-plumbing-wenham-son-hamilton', 'plumbing', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Hamilton Drain & Pipe', 'ma-plumbing-hamilton-drain-pipe', 'plumbing', NULL, ARRAY['Hamilton','MA','Essex'], NULL),

    -- Haverhill
    ('Haverhill Plumbing & Heating', 'ma-plumbing-haverhill-plumbing-heating', 'plumbing', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Moriarty Plumbing Services', 'ma-plumbing-moriarty-haverhill', 'plumbing', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Haverhill Plumbing Co.', 'ma-plumbing-haverhill-co', 'plumbing', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Fitzgerald & Son Plumbing', 'ma-plumbing-fitzgerald-son-haverhill', 'plumbing', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Haverhill Drain & Pipe', 'ma-plumbing-haverhill-drain-pipe', 'plumbing', NULL, ARRAY['Haverhill','MA','Essex'], NULL),

    -- Ipswich
    ('Ipswich Plumbing & Heating', 'ma-plumbing-ipswich-plumbing-heating', 'plumbing', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Goodhue Plumbing Services', 'ma-plumbing-goodhue-ipswich', 'plumbing', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Ipswich Plumbing Co.', 'ma-plumbing-ipswich-co', 'plumbing', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Treadwell & Son Plumbing', 'ma-plumbing-treadwell-son-ipswich', 'plumbing', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Ipswich Drain & Pipe', 'ma-plumbing-ipswich-drain-pipe', 'plumbing', NULL, ARRAY['Ipswich','MA','Essex'], NULL),

    -- Lawrence
    ('Lawrence Plumbing & Heating', 'ma-plumbing-lawrence-plumbing-heating', 'plumbing', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Ortiz Plumbing Services', 'ma-plumbing-ortiz-lawrence', 'plumbing', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Lawrence Plumbing Co.', 'ma-plumbing-lawrence-co', 'plumbing', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Reilly & Son Plumbing', 'ma-plumbing-reilly-son-lawrence', 'plumbing', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Lawrence Drain & Pipe', 'ma-plumbing-lawrence-drain-pipe', 'plumbing', NULL, ARRAY['Lawrence','MA','Essex'], NULL),

    -- Lynn
    ('Lynn Plumbing & Heating', 'ma-plumbing-lynn-plumbing-heating', 'plumbing', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Doherty Plumbing Services', 'ma-plumbing-doherty-lynn', 'plumbing', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Lynn Plumbing Co.', 'ma-plumbing-lynn-co', 'plumbing', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Walsh & Son Plumbing', 'ma-plumbing-walsh-son-lynn', 'plumbing', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Lynn Drain & Pipe', 'ma-plumbing-lynn-drain-pipe', 'plumbing', NULL, ARRAY['Lynn','MA','Essex'], NULL),

    -- Lynnfield
    ('Lynnfield Plumbing & Heating', 'ma-plumbing-lynnfield-plumbing-heating', 'plumbing', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Barrett Plumbing Services', 'ma-plumbing-barrett-lynnfield', 'plumbing', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Lynnfield Plumbing Co.', 'ma-plumbing-lynnfield-co', 'plumbing', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Coakley & Son Plumbing', 'ma-plumbing-coakley-son-lynnfield', 'plumbing', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Lynnfield Drain & Pipe', 'ma-plumbing-lynnfield-drain-pipe', 'plumbing', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),

    -- Manchester-by-the-Sea
    ('Manchester Plumbing & Heating', 'ma-plumbing-manchester-plumbing-heating', 'plumbing', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Haskell Plumbing Services', 'ma-plumbing-haskell-manchester', 'plumbing', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Manchester Plumbing Co.', 'ma-plumbing-manchester-co', 'plumbing', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Leach & Son Plumbing', 'ma-plumbing-leach-son-manchester', 'plumbing', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Manchester Drain & Pipe', 'ma-plumbing-manchester-drain-pipe', 'plumbing', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),

    -- Marblehead
    ('Marblehead Plumbing & Heating', 'ma-plumbing-marblehead-plumbing-heating', 'plumbing', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Graves Plumbing Services', 'ma-plumbing-graves-marblehead', 'plumbing', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Marblehead Plumbing Co.', 'ma-plumbing-marblehead-co', 'plumbing', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Pitman & Son Plumbing', 'ma-plumbing-pitman-son-marblehead', 'plumbing', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Marblehead Drain & Pipe', 'ma-plumbing-marblehead-drain-pipe', 'plumbing', NULL, ARRAY['Marblehead','MA','Essex'], NULL),

    -- Merrimac
    ('Merrimac Plumbing & Heating', 'ma-plumbing-merrimac-plumbing-heating', 'plumbing', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Sargent Plumbing Services', 'ma-plumbing-sargent-merrimac', 'plumbing', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Merrimac Plumbing Co.', 'ma-plumbing-merrimac-co', 'plumbing', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Hoyt & Son Plumbing', 'ma-plumbing-hoyt-son-merrimac', 'plumbing', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Merrimac Drain & Pipe', 'ma-plumbing-merrimac-drain-pipe', 'plumbing', NULL, ARRAY['Merrimac','MA','Essex'], NULL),

    -- Methuen
    ('Methuen Plumbing & Heating', 'ma-plumbing-methuen-plumbing-heating', 'plumbing', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Quinlan Plumbing Services', 'ma-plumbing-quinlan-methuen', 'plumbing', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Methuen Plumbing Co.', 'ma-plumbing-methuen-co', 'plumbing', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Gauthier & Son Plumbing', 'ma-plumbing-gauthier-son-methuen', 'plumbing', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Methuen Drain & Pipe', 'ma-plumbing-methuen-drain-pipe', 'plumbing', NULL, ARRAY['Methuen','MA','Essex'], NULL),

    -- Middleton
    ('Middleton Plumbing & Heating', 'ma-plumbing-middleton-plumbing-heating', 'plumbing', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Fuller Plumbing Services', 'ma-plumbing-fuller-middleton', 'plumbing', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Middleton Plumbing Co.', 'ma-plumbing-middleton-co', 'plumbing', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Peabody & Son Plumbing', 'ma-plumbing-peabody-son-middleton', 'plumbing', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Middleton Drain & Pipe', 'ma-plumbing-middleton-drain-pipe', 'plumbing', NULL, ARRAY['Middleton','MA','Essex'], NULL),

    -- Nahant
    ('Nahant Plumbing & Heating', 'ma-plumbing-nahant-plumbing-heating', 'plumbing', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Tudor Plumbing Services', 'ma-plumbing-tudor-nahant', 'plumbing', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Nahant Plumbing Co.', 'ma-plumbing-nahant-co', 'plumbing', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Lodge & Son Plumbing', 'ma-plumbing-lodge-son-nahant', 'plumbing', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Nahant Drain & Pipe', 'ma-plumbing-nahant-drain-pipe', 'plumbing', NULL, ARRAY['Nahant','MA','Essex'], NULL),

    -- Newbury
    ('Newbury Plumbing & Heating', 'ma-plumbing-newbury-plumbing-heating', 'plumbing', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Coffin Plumbing Services', 'ma-plumbing-coffin-newbury', 'plumbing', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Newbury Plumbing Co.', 'ma-plumbing-newbury-co', 'plumbing', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Noyes & Son Plumbing', 'ma-plumbing-noyes-son-newbury', 'plumbing', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Newbury Drain & Pipe', 'ma-plumbing-newbury-drain-pipe', 'plumbing', NULL, ARRAY['Newbury','MA','Essex'], NULL),

    -- Newburyport
    ('Newburyport Plumbing & Heating', 'ma-plumbing-newburyport-plumbing-heating', 'plumbing', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Cushing Plumbing Services', 'ma-plumbing-cushing-newburyport', 'plumbing', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Newburyport Plumbing Co.', 'ma-plumbing-newburyport-co', 'plumbing', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Marquand & Son Plumbing', 'ma-plumbing-marquand-son-newburyport', 'plumbing', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Newburyport Drain & Pipe', 'ma-plumbing-newburyport-drain-pipe', 'plumbing', NULL, ARRAY['Newburyport','MA','Essex'], NULL),

    -- North Andover
    ('North Andover Plumbing & Heating', 'ma-plumbing-north-andover-plumbing-heating', 'plumbing', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Bresnahan Plumbing Services', 'ma-plumbing-bresnahan-north-andover', 'plumbing', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('North Andover Plumbing Co.', 'ma-plumbing-north-andover-co', 'plumbing', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Osgood & Son Plumbing', 'ma-plumbing-osgood-son-north-andover', 'plumbing', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('North Andover Drain & Pipe', 'ma-plumbing-north-andover-drain-pipe', 'plumbing', NULL, ARRAY['North Andover','MA','Essex'], NULL),

    -- Peabody
    ('Peabody Plumbing & Heating', 'ma-plumbing-peabody-plumbing-heating', 'plumbing', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Crowley Plumbing Services', 'ma-plumbing-crowley-peabody', 'plumbing', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Peabody Plumbing Co.', 'ma-plumbing-peabody-co', 'plumbing', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Sutton & Son Plumbing', 'ma-plumbing-sutton-son-peabody', 'plumbing', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Peabody Drain & Pipe', 'ma-plumbing-peabody-drain-pipe', 'plumbing', NULL, ARRAY['Peabody','MA','Essex'], NULL),

    -- Rockport
    ('Rockport Plumbing & Heating', 'ma-plumbing-rockport-plumbing-heating', 'plumbing', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Tarr Plumbing Services', 'ma-plumbing-tarr-rockport', 'plumbing', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Rockport Plumbing Co.', 'ma-plumbing-rockport-co', 'plumbing', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Norwood & Son Plumbing', 'ma-plumbing-norwood-son-rockport', 'plumbing', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Rockport Drain & Pipe', 'ma-plumbing-rockport-drain-pipe', 'plumbing', NULL, ARRAY['Rockport','MA','Essex'], NULL),

    -- Rowley
    ('Rowley Plumbing & Heating', 'ma-plumbing-rowley-plumbing-heating', 'plumbing', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Gage Plumbing Services', 'ma-plumbing-gage-rowley', 'plumbing', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Rowley Plumbing Co.', 'ma-plumbing-rowley-co', 'plumbing', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Mighill & Son Plumbing', 'ma-plumbing-mighill-son-rowley', 'plumbing', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Rowley Drain & Pipe', 'ma-plumbing-rowley-drain-pipe', 'plumbing', NULL, ARRAY['Rowley','MA','Essex'], NULL),

    -- Salem
    ('Salem Plumbing & Heating', 'ma-plumbing-salem-plumbing-heating', 'plumbing', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Hawthorne Plumbing Services', 'ma-plumbing-hawthorne-salem', 'plumbing', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Salem Plumbing Co.', 'ma-plumbing-salem-co', 'plumbing', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Derby & Son Plumbing', 'ma-plumbing-derby-son-salem', 'plumbing', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Salem Drain & Pipe', 'ma-plumbing-salem-drain-pipe', 'plumbing', NULL, ARRAY['Salem','MA','Essex'], NULL),

    -- Salisbury
    ('Salisbury Plumbing & Heating', 'ma-plumbing-salisbury-plumbing-heating', 'plumbing', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Eaton Plumbing Services', 'ma-plumbing-eaton-salisbury', 'plumbing', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Salisbury Plumbing Co.', 'ma-plumbing-salisbury-co', 'plumbing', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Pettingill & Son Plumbing', 'ma-plumbing-pettingill-son-salisbury', 'plumbing', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Salisbury Drain & Pipe', 'ma-plumbing-salisbury-drain-pipe', 'plumbing', NULL, ARRAY['Salisbury','MA','Essex'], NULL),

    -- Saugus
    ('Saugus Plumbing & Heating', 'ma-plumbing-saugus-plumbing-heating', 'plumbing', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Parsons Plumbing Services', 'ma-plumbing-parsons-saugus', 'plumbing', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Saugus Plumbing Co.', 'ma-plumbing-saugus-co', 'plumbing', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Vinton & Son Plumbing', 'ma-plumbing-vinton-son-saugus', 'plumbing', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Saugus Drain & Pipe', 'ma-plumbing-saugus-drain-pipe', 'plumbing', NULL, ARRAY['Saugus','MA','Essex'], NULL),

    -- Swampscott
    ('Swampscott Plumbing & Heating', 'ma-plumbing-swampscott-plumbing-heating', 'plumbing', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Blaney Plumbing Services', 'ma-plumbing-blaney-swampscott', 'plumbing', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Swampscott Plumbing Co.', 'ma-plumbing-swampscott-co', 'plumbing', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Ingalls & Son Plumbing', 'ma-plumbing-ingalls-son-swampscott', 'plumbing', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Swampscott Drain & Pipe', 'ma-plumbing-swampscott-drain-pipe', 'plumbing', NULL, ARRAY['Swampscott','MA','Essex'], NULL),

    -- Topsfield
    ('Topsfield Plumbing & Heating', 'ma-plumbing-topsfield-plumbing-heating', 'plumbing', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Gould Plumbing Services', 'ma-plumbing-gould-topsfield', 'plumbing', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Topsfield Plumbing Co.', 'ma-plumbing-topsfield-co', 'plumbing', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Cummings & Son Plumbing', 'ma-plumbing-cummings-son-topsfield', 'plumbing', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Topsfield Drain & Pipe', 'ma-plumbing-topsfield-drain-pipe', 'plumbing', NULL, ARRAY['Topsfield','MA','Essex'], NULL),

    -- Wenham
    ('Wenham Plumbing & Heating', 'ma-plumbing-wenham-plumbing-heating', 'plumbing', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Fiske Plumbing Services', 'ma-plumbing-fiske-wenham', 'plumbing', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Wenham Plumbing Co.', 'ma-plumbing-wenham-co', 'plumbing', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Dodge & Son Plumbing', 'ma-plumbing-dodge-son-wenham', 'plumbing', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Wenham Drain & Pipe', 'ma-plumbing-wenham-drain-pipe', 'plumbing', NULL, ARRAY['Wenham','MA','Essex'], NULL),

    -- West Newbury
    ('West Newbury Plumbing & Heating', 'ma-plumbing-west-newbury-plumbing-heating', 'plumbing', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('Chase Plumbing Services', 'ma-plumbing-chase-west-newbury', 'plumbing', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('West Newbury Plumbing Co.', 'ma-plumbing-west-newbury-co', 'plumbing', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('Emery & Son Plumbing', 'ma-plumbing-emery-son-west-newbury', 'plumbing', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('West Newbury Drain & Pipe', 'ma-plumbing-west-newbury-drain-pipe', 'plumbing', NULL, ARRAY['West Newbury','MA','Essex'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 8: MIDDLESEX COUNTY LOCAL PLUMBING (54 towns x 5)
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Acton
    ('Acton Plumbing & Heating', 'ma-plumbing-acton-plumbing-heating', 'plumbing', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Wheeler Plumbing Services', 'ma-plumbing-wheeler-acton', 'plumbing', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Acton Plumbing Co.', 'ma-plumbing-acton-co', 'plumbing', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Robbins & Son Plumbing', 'ma-plumbing-robbins-son-acton', 'plumbing', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Acton Drain & Pipe', 'ma-plumbing-acton-drain-pipe', 'plumbing', NULL, ARRAY['Acton','MA','Middlesex'], NULL),

    -- Arlington
    ('Arlington Plumbing & Heating', 'ma-plumbing-arlington-plumbing-heating', 'plumbing', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Peirce Plumbing Services', 'ma-plumbing-peirce-arlington', 'plumbing', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Arlington Plumbing Co.', 'ma-plumbing-arlington-co', 'plumbing', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Crosby & Son Plumbing', 'ma-plumbing-crosby-son-arlington', 'plumbing', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Arlington Drain & Pipe', 'ma-plumbing-arlington-drain-pipe', 'plumbing', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),

    -- Ashby
    ('Ashby Plumbing & Heating', 'ma-plumbing-ashby-plumbing-heating', 'plumbing', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Willard Plumbing Services', 'ma-plumbing-willard-ashby', 'plumbing', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Ashby Plumbing Co.', 'ma-plumbing-ashby-co', 'plumbing', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Damon & Son Plumbing', 'ma-plumbing-damon-son-ashby', 'plumbing', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Ashby Drain & Pipe', 'ma-plumbing-ashby-drain-pipe', 'plumbing', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),

    -- Ashland
    ('Ashland Plumbing & Heating', 'ma-plumbing-ashland-plumbing-heating', 'plumbing', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Metcalf Plumbing Services', 'ma-plumbing-metcalf-ashland', 'plumbing', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Ashland Plumbing Co.', 'ma-plumbing-ashland-co', 'plumbing', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Stone & Son Plumbing', 'ma-plumbing-stone-son-ashland', 'plumbing', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Ashland Drain & Pipe', 'ma-plumbing-ashland-drain-pipe', 'plumbing', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),

    -- Ayer
    ('Ayer Plumbing & Heating', 'ma-plumbing-ayer-plumbing-heating', 'plumbing', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Sanderson Plumbing Services', 'ma-plumbing-sanderson-ayer', 'plumbing', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Ayer Plumbing Co.', 'ma-plumbing-ayer-co', 'plumbing', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Farnsworth & Son Plumbing', 'ma-plumbing-farnsworth-son-ayer', 'plumbing', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Ayer Drain & Pipe', 'ma-plumbing-ayer-drain-pipe', 'plumbing', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),

    -- Bedford
    ('Bedford Plumbing & Heating', 'ma-plumbing-bedford-plumbing-heating', 'plumbing', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Lane Plumbing Services', 'ma-plumbing-lane-bedford', 'plumbing', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Bedford Plumbing Co.', 'ma-plumbing-bedford-co', 'plumbing', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Fitch & Son Plumbing', 'ma-plumbing-fitch-son-bedford', 'plumbing', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Bedford Drain & Pipe', 'ma-plumbing-bedford-drain-pipe', 'plumbing', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),

    -- Belmont
    ('Belmont Plumbing & Heating', 'ma-plumbing-belmont-plumbing-heating', 'plumbing', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Underwood Plumbing Services', 'ma-plumbing-underwood-belmont', 'plumbing', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Belmont Plumbing Co.', 'ma-plumbing-belmont-co', 'plumbing', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Wellington & Son Plumbing', 'ma-plumbing-wellington-son-belmont', 'plumbing', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Belmont Drain & Pipe', 'ma-plumbing-belmont-drain-pipe', 'plumbing', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),

    -- Billerica
    ('Billerica Plumbing & Heating', 'ma-plumbing-billerica-plumbing-heating', 'plumbing', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Manning Plumbing Services', 'ma-plumbing-manning-billerica', 'plumbing', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Billerica Plumbing Co.', 'ma-plumbing-billerica-co', 'plumbing', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Pollard & Son Plumbing', 'ma-plumbing-pollard-son-billerica', 'plumbing', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Billerica Drain & Pipe', 'ma-plumbing-billerica-drain-pipe', 'plumbing', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),

    -- Boxborough
    ('Boxborough Plumbing & Heating', 'ma-plumbing-boxborough-plumbing-heating', 'plumbing', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Hager Plumbing Services', 'ma-plumbing-hager-boxborough', 'plumbing', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Boxborough Plumbing Co.', 'ma-plumbing-boxborough-co', 'plumbing', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Blanchard & Son Plumbing', 'ma-plumbing-blanchard-son-boxborough', 'plumbing', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Boxborough Drain & Pipe', 'ma-plumbing-boxborough-drain-pipe', 'plumbing', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),

    -- Burlington
    ('Burlington Plumbing & Heating', 'ma-plumbing-burlington-plumbing-heating', 'plumbing', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Simonds Plumbing Services', 'ma-plumbing-simonds-burlington', 'plumbing', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Burlington Plumbing Co.', 'ma-plumbing-burlington-co', 'plumbing', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Winn & Son Plumbing', 'ma-plumbing-winn-son-burlington', 'plumbing', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Burlington Drain & Pipe', 'ma-plumbing-burlington-drain-pipe', 'plumbing', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),

    -- Cambridge
    ('Cambridge Plumbing & Heating', 'ma-plumbing-cambridge-plumbing-heating', 'plumbing', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Hastings Plumbing Services', 'ma-plumbing-hastings-cambridge', 'plumbing', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Cambridge Plumbing Co.', 'ma-plumbing-cambridge-co', 'plumbing', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Brattle & Son Plumbing', 'ma-plumbing-brattle-son-cambridge', 'plumbing', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Cambridge Drain & Pipe', 'ma-plumbing-cambridge-drain-pipe', 'plumbing', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),

    -- Carlisle
    ('Carlisle Plumbing & Heating', 'ma-plumbing-carlisle-plumbing-heating', 'plumbing', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Heald Plumbing Services', 'ma-plumbing-heald-carlisle', 'plumbing', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Carlisle Plumbing Co.', 'ma-plumbing-carlisle-co', 'plumbing', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Spaulding & Son Plumbing', 'ma-plumbing-spaulding-son-carlisle', 'plumbing', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Carlisle Drain & Pipe', 'ma-plumbing-carlisle-drain-pipe', 'plumbing', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),

    -- Chelmsford
    ('Chelmsford Plumbing & Heating', 'ma-plumbing-chelmsford-plumbing-heating', 'plumbing', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Richardson Plumbing Services', 'ma-plumbing-richardson-chelmsford', 'plumbing', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Chelmsford Plumbing Co.', 'ma-plumbing-chelmsford-co', 'plumbing', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Parkhurst & Son Plumbing', 'ma-plumbing-parkhurst-son-chelmsford', 'plumbing', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Chelmsford Drain & Pipe', 'ma-plumbing-chelmsford-drain-pipe', 'plumbing', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),

    -- Concord
    ('Concord Plumbing & Heating', 'ma-plumbing-concord-plumbing-heating', 'plumbing', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Thoreau Plumbing Services', 'ma-plumbing-thoreau-concord', 'plumbing', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Concord Plumbing Co.', 'ma-plumbing-concord-co', 'plumbing', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Barrett & Son Plumbing', 'ma-plumbing-barrett-son-concord', 'plumbing', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Concord Drain & Pipe', 'ma-plumbing-concord-drain-pipe', 'plumbing', NULL, ARRAY['Concord','MA','Middlesex'], NULL),

    -- Dracut
    ('Dracut Plumbing & Heating', 'ma-plumbing-dracut-plumbing-heating', 'plumbing', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Collinsworth Plumbing Services', 'ma-plumbing-collinsworth-dracut', 'plumbing', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Dracut Plumbing Co.', 'ma-plumbing-dracut-co', 'plumbing', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Coburn & Son Plumbing', 'ma-plumbing-coburn-son-dracut', 'plumbing', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Dracut Drain & Pipe', 'ma-plumbing-dracut-drain-pipe', 'plumbing', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),

    -- Dunstable
    ('Dunstable Plumbing & Heating', 'ma-plumbing-dunstable-plumbing-heating', 'plumbing', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Swallow Plumbing Services', 'ma-plumbing-swallow-dunstable', 'plumbing', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Dunstable Plumbing Co.', 'ma-plumbing-dunstable-co', 'plumbing', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('French & Son Plumbing', 'ma-plumbing-french-son-dunstable', 'plumbing', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Dunstable Drain & Pipe', 'ma-plumbing-dunstable-drain-pipe', 'plumbing', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),

    -- Everett
    ('Everett Plumbing & Heating', 'ma-plumbing-everett-plumbing-heating', 'plumbing', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Glendale Plumbing Services', 'ma-plumbing-glendale-everett', 'plumbing', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Everett Plumbing Co.', 'ma-plumbing-everett-co', 'plumbing', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Parlin & Son Plumbing', 'ma-plumbing-parlin-son-everett', 'plumbing', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Everett Drain & Pipe', 'ma-plumbing-everett-drain-pipe', 'plumbing', NULL, ARRAY['Everett','MA','Middlesex'], NULL),

    -- Framingham
    ('Framingham Plumbing & Heating', 'ma-plumbing-framingham-plumbing-heating', 'plumbing', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Buckminster Plumbing Services', 'ma-plumbing-buckminster-framingham', 'plumbing', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Framingham Plumbing Co.', 'ma-plumbing-framingham-co', 'plumbing', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Danforth & Son Plumbing', 'ma-plumbing-danforth-son-framingham', 'plumbing', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Framingham Drain & Pipe', 'ma-plumbing-framingham-drain-pipe', 'plumbing', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),

    -- Groton
    ('Groton Plumbing & Heating', 'ma-plumbing-groton-plumbing-heating', 'plumbing', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Prescott Plumbing Services', 'ma-plumbing-prescott-groton', 'plumbing', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Groton Plumbing Co.', 'ma-plumbing-groton-co', 'plumbing', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Lawrence & Son Plumbing', 'ma-plumbing-lawrence-son-groton', 'plumbing', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Groton Drain & Pipe', 'ma-plumbing-groton-drain-pipe', 'plumbing', NULL, ARRAY['Groton','MA','Middlesex'], NULL),

    -- Holliston
    ('Holliston Plumbing & Heating', 'ma-plumbing-holliston-plumbing-heating', 'plumbing', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Cutler Plumbing Services', 'ma-plumbing-cutler-holliston', 'plumbing', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Holliston Plumbing Co.', 'ma-plumbing-holliston-co', 'plumbing', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Phipps & Son Plumbing', 'ma-plumbing-phipps-son-holliston', 'plumbing', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Holliston Drain & Pipe', 'ma-plumbing-holliston-drain-pipe', 'plumbing', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),

    -- Hopkinton
    ('Hopkinton Plumbing & Heating', 'ma-plumbing-hopkinton-plumbing-heating', 'plumbing', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Claflin Plumbing Services', 'ma-plumbing-claflin-hopkinton', 'plumbing', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Hopkinton Plumbing Co.', 'ma-plumbing-hopkinton-co', 'plumbing', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Hayden & Son Plumbing', 'ma-plumbing-hayden-son-hopkinton', 'plumbing', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Hopkinton Drain & Pipe', 'ma-plumbing-hopkinton-drain-pipe', 'plumbing', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),

    -- Hudson
    ('Hudson Plumbing & Heating', 'ma-plumbing-hudson-plumbing-heating', 'plumbing', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Goodale Plumbing Services', 'ma-plumbing-goodale-hudson', 'plumbing', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Hudson Plumbing Co.', 'ma-plumbing-hudson-co', 'plumbing', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Felton & Son Plumbing', 'ma-plumbing-felton-son-hudson', 'plumbing', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Hudson Drain & Pipe', 'ma-plumbing-hudson-drain-pipe', 'plumbing', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),

    -- Lexington
    ('Lexington Plumbing & Heating', 'ma-plumbing-lexington-plumbing-heating', 'plumbing', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Hancock Plumbing Services', 'ma-plumbing-hancock-lexington', 'plumbing', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Lexington Plumbing Co.', 'ma-plumbing-lexington-co', 'plumbing', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Munroe & Son Plumbing', 'ma-plumbing-munroe-son-lexington', 'plumbing', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Lexington Drain & Pipe', 'ma-plumbing-lexington-drain-pipe', 'plumbing', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),

    -- Lincoln
    ('Lincoln Plumbing & Heating', 'ma-plumbing-lincoln-plumbing-heating', 'plumbing', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Codman Plumbing Services', 'ma-plumbing-codman-lincoln', 'plumbing', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Lincoln Plumbing Co.', 'ma-plumbing-lincoln-co', 'plumbing', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Flint & Son Plumbing', 'ma-plumbing-flint-son-lincoln', 'plumbing', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Lincoln Drain & Pipe', 'ma-plumbing-lincoln-drain-pipe', 'plumbing', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),

    -- Littleton
    ('Littleton Plumbing & Heating', 'ma-plumbing-littleton-plumbing-heating', 'plumbing', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Hartwell Plumbing Services', 'ma-plumbing-hartwell-littleton', 'plumbing', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Littleton Plumbing Co.', 'ma-plumbing-littleton-co', 'plumbing', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Shattuck & Son Plumbing', 'ma-plumbing-shattuck-son-littleton', 'plumbing', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Littleton Drain & Pipe', 'ma-plumbing-littleton-drain-pipe', 'plumbing', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),

    -- Lowell
    ('Lowell Plumbing & Heating', 'ma-plumbing-lowell-plumbing-heating', 'plumbing', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Mack Plumbing Services', 'ma-plumbing-mack-lowell', 'plumbing', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Lowell Plumbing Co.', 'ma-plumbing-lowell-co', 'plumbing', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Merrimack & Son Plumbing', 'ma-plumbing-merrimack-son-lowell', 'plumbing', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Lowell Drain & Pipe', 'ma-plumbing-lowell-drain-pipe', 'plumbing', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),

    -- Malden
    ('Malden Plumbing & Heating', 'ma-plumbing-malden-plumbing-heating', 'plumbing', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Converse Plumbing Services', 'ma-plumbing-converse-malden', 'plumbing', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Malden Plumbing Co.', 'ma-plumbing-malden-co', 'plumbing', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Devir & Son Plumbing', 'ma-plumbing-devir-son-malden', 'plumbing', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Malden Drain & Pipe', 'ma-plumbing-malden-drain-pipe', 'plumbing', NULL, ARRAY['Malden','MA','Middlesex'], NULL),

    -- Marlborough
    ('Marlborough Plumbing & Heating', 'ma-plumbing-marlborough-plumbing-heating', 'plumbing', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Bigelow Plumbing Services', 'ma-plumbing-bigelow-marlborough', 'plumbing', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Marlborough Plumbing Co.', 'ma-plumbing-marlborough-co', 'plumbing', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Howe & Son Plumbing', 'ma-plumbing-howe-son-marlborough', 'plumbing', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Marlborough Drain & Pipe', 'ma-plumbing-marlborough-drain-pipe', 'plumbing', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),

    -- Maynard
    ('Maynard Plumbing & Heating', 'ma-plumbing-maynard-plumbing-heating', 'plumbing', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Nason Plumbing Services', 'ma-plumbing-nason-maynard', 'plumbing', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Maynard Plumbing Co.', 'ma-plumbing-maynard-co', 'plumbing', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Fowler & Son Plumbing', 'ma-plumbing-fowler-son-maynard', 'plumbing', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Maynard Drain & Pipe', 'ma-plumbing-maynard-drain-pipe', 'plumbing', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),

    -- Medford
    ('Medford Plumbing & Heating', 'ma-plumbing-medford-plumbing-heating', 'plumbing', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Cradock Plumbing Services', 'ma-plumbing-cradock-medford', 'plumbing', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Medford Plumbing Co.', 'ma-plumbing-medford-co', 'plumbing', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Brooks & Son Plumbing', 'ma-plumbing-brooks-son-medford', 'plumbing', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Medford Drain & Pipe', 'ma-plumbing-medford-drain-pipe', 'plumbing', NULL, ARRAY['Medford','MA','Middlesex'], NULL),

    -- Melrose
    ('Melrose Plumbing & Heating', 'ma-plumbing-melrose-plumbing-heating', 'plumbing', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Lynde Plumbing Services', 'ma-plumbing-lynde-melrose', 'plumbing', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Melrose Plumbing Co.', 'ma-plumbing-melrose-co', 'plumbing', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Upham & Son Plumbing', 'ma-plumbing-upham-son-melrose', 'plumbing', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Melrose Drain & Pipe', 'ma-plumbing-melrose-drain-pipe', 'plumbing', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),

    -- Natick
    ('Natick Plumbing & Heating', 'ma-plumbing-natick-plumbing-heating', 'plumbing', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Walcott Plumbing Services', 'ma-plumbing-walcott-natick', 'plumbing', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Natick Plumbing Co.', 'ma-plumbing-natick-co', 'plumbing', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Morse & Son Plumbing', 'ma-plumbing-morse-son-natick', 'plumbing', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Natick Drain & Pipe', 'ma-plumbing-natick-drain-pipe', 'plumbing', NULL, ARRAY['Natick','MA','Middlesex'], NULL),

    -- Newton
    ('Newton Plumbing & Heating', 'ma-plumbing-newton-plumbing-heating', 'plumbing', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Eliot Plumbing Services', 'ma-plumbing-eliot-newton', 'plumbing', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Newton Plumbing Co.', 'ma-plumbing-newton-co', 'plumbing', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Otis & Son Plumbing', 'ma-plumbing-otis-son-newton', 'plumbing', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Newton Drain & Pipe', 'ma-plumbing-newton-drain-pipe', 'plumbing', NULL, ARRAY['Newton','MA','Middlesex'], NULL),

    -- North Reading
    ('North Reading Plumbing & Heating', 'ma-plumbing-north-reading-plumbing-heating', 'plumbing', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('Flint Plumbing Services', 'ma-plumbing-flint-north-reading', 'plumbing', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('North Reading Plumbing Co.', 'ma-plumbing-north-reading-co', 'plumbing', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('Upton & Son Plumbing', 'ma-plumbing-upton-son-north-reading', 'plumbing', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('North Reading Drain & Pipe', 'ma-plumbing-north-reading-drain-pipe', 'plumbing', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),

    -- Pepperell
    ('Pepperell Plumbing & Heating', 'ma-plumbing-pepperell-plumbing-heating', 'plumbing', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Tarbell Plumbing Services', 'ma-plumbing-tarbell-pepperell', 'plumbing', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Pepperell Plumbing Co.', 'ma-plumbing-pepperell-co', 'plumbing', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Jewett & Son Plumbing', 'ma-plumbing-jewett-son-pepperell', 'plumbing', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Pepperell Drain & Pipe', 'ma-plumbing-pepperell-drain-pipe', 'plumbing', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),

    -- Reading
    ('Reading Plumbing & Heating', 'ma-plumbing-reading-plumbing-heating', 'plumbing', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Parker Plumbing Services', 'ma-plumbing-parker-reading', 'plumbing', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Reading Plumbing Co.', 'ma-plumbing-reading-co', 'plumbing', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Bancroft & Son Plumbing', 'ma-plumbing-bancroft-son-reading', 'plumbing', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Reading Drain & Pipe', 'ma-plumbing-reading-drain-pipe', 'plumbing', NULL, ARRAY['Reading','MA','Middlesex'], NULL),

    -- Sherborn
    ('Sherborn Plumbing & Heating', 'ma-plumbing-sherborn-plumbing-heating', 'plumbing', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Dowse Plumbing Services', 'ma-plumbing-dowse-sherborn', 'plumbing', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Sherborn Plumbing Co.', 'ma-plumbing-sherborn-co', 'plumbing', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Holbrook & Son Plumbing', 'ma-plumbing-holbrook-son-sherborn', 'plumbing', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Sherborn Drain & Pipe', 'ma-plumbing-sherborn-drain-pipe', 'plumbing', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),

    -- Shirley
    ('Shirley Plumbing & Heating', 'ma-plumbing-shirley-plumbing-heating', 'plumbing', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Longley Plumbing Services', 'ma-plumbing-longley-shirley', 'plumbing', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Shirley Plumbing Co.', 'ma-plumbing-shirley-co', 'plumbing', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Hazen & Son Plumbing', 'ma-plumbing-hazen-son-shirley', 'plumbing', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Shirley Drain & Pipe', 'ma-plumbing-shirley-drain-pipe', 'plumbing', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),

    -- Somerville
    ('Somerville Plumbing & Heating', 'ma-plumbing-somerville-plumbing-heating', 'plumbing', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Tufts Plumbing Services', 'ma-plumbing-tufts-somerville', 'plumbing', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Somerville Plumbing Co.', 'ma-plumbing-somerville-co', 'plumbing', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Magoun & Son Plumbing', 'ma-plumbing-magoun-son-somerville', 'plumbing', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Somerville Drain & Pipe', 'ma-plumbing-somerville-drain-pipe', 'plumbing', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),

    -- Stoneham
    ('Stoneham Plumbing & Heating', 'ma-plumbing-stoneham-plumbing-heating', 'plumbing', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Goss Plumbing Services', 'ma-plumbing-goss-stoneham', 'plumbing', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Stoneham Plumbing Co.', 'ma-plumbing-stoneham-co', 'plumbing', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Hill & Son Plumbing', 'ma-plumbing-hill-son-stoneham', 'plumbing', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Stoneham Drain & Pipe', 'ma-plumbing-stoneham-drain-pipe', 'plumbing', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),

    -- Stow
    ('Stow Plumbing & Heating', 'ma-plumbing-stow-plumbing-heating', 'plumbing', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Randall Plumbing Services', 'ma-plumbing-randall-stow', 'plumbing', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Stow Plumbing Co.', 'ma-plumbing-stow-co', 'plumbing', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Gates & Son Plumbing', 'ma-plumbing-gates-son-stow', 'plumbing', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Stow Drain & Pipe', 'ma-plumbing-stow-drain-pipe', 'plumbing', NULL, ARRAY['Stow','MA','Middlesex'], NULL),

    -- Sudbury
    ('Sudbury Plumbing & Heating', 'ma-plumbing-sudbury-plumbing-heating', 'plumbing', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Goodenow Plumbing Services', 'ma-plumbing-goodenow-sudbury', 'plumbing', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Sudbury Plumbing Co.', 'ma-plumbing-sudbury-co', 'plumbing', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Haynes & Son Plumbing', 'ma-plumbing-haynes-son-sudbury', 'plumbing', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Sudbury Drain & Pipe', 'ma-plumbing-sudbury-drain-pipe', 'plumbing', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),

    -- Tewksbury
    ('Tewksbury Plumbing & Heating', 'ma-plumbing-tewksbury-plumbing-heating', 'plumbing', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Trull Plumbing Services', 'ma-plumbing-trull-tewksbury', 'plumbing', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Tewksbury Plumbing Co.', 'ma-plumbing-tewksbury-co', 'plumbing', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Foster & Son Plumbing', 'ma-plumbing-foster-son-tewksbury', 'plumbing', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Tewksbury Drain & Pipe', 'ma-plumbing-tewksbury-drain-pipe', 'plumbing', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),

    -- Townsend
    ('Townsend Plumbing & Heating', 'ma-plumbing-townsend-plumbing-heating', 'plumbing', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Reed Plumbing Services', 'ma-plumbing-reed-townsend', 'plumbing', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Townsend Plumbing Co.', 'ma-plumbing-townsend-co', 'plumbing', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Conant & Son Plumbing', 'ma-plumbing-conant-son-townsend', 'plumbing', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Townsend Drain & Pipe', 'ma-plumbing-townsend-drain-pipe', 'plumbing', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),

    -- Tyngsborough
    ('Tyngsborough Plumbing & Heating', 'ma-plumbing-tyngsborough-plumbing-heating', 'plumbing', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Winslow Plumbing Services', 'ma-plumbing-winslow-tyngsborough', 'plumbing', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Tyngsborough Plumbing Co.', 'ma-plumbing-tyngsborough-co', 'plumbing', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Brinley & Son Plumbing', 'ma-plumbing-brinley-son-tyngsborough', 'plumbing', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Tyngsborough Drain & Pipe', 'ma-plumbing-tyngsborough-drain-pipe', 'plumbing', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),

    -- Wakefield
    ('Wakefield Plumbing & Heating', 'ma-plumbing-wakefield-plumbing-heating', 'plumbing', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Eaton Plumbing Services', 'ma-plumbing-eaton-wakefield', 'plumbing', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Wakefield Plumbing Co.', 'ma-plumbing-wakefield-co', 'plumbing', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Sweetser & Son Plumbing', 'ma-plumbing-sweetser-son-wakefield', 'plumbing', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Wakefield Drain & Pipe', 'ma-plumbing-wakefield-drain-pipe', 'plumbing', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),

    -- Waltham
    ('Waltham Plumbing & Heating', 'ma-plumbing-waltham-plumbing-heating', 'plumbing', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Lyman Plumbing Services', 'ma-plumbing-lyman-waltham', 'plumbing', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Waltham Plumbing Co.', 'ma-plumbing-waltham-co', 'plumbing', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Moody & Son Plumbing', 'ma-plumbing-moody-son-waltham', 'plumbing', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Waltham Drain & Pipe', 'ma-plumbing-waltham-drain-pipe', 'plumbing', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),

    -- Watertown
    ('Watertown Plumbing & Heating', 'ma-plumbing-watertown-plumbing-heating', 'plumbing', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Coolidge Plumbing Services', 'ma-plumbing-coolidge-watertown', 'plumbing', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Watertown Plumbing Co.', 'ma-plumbing-watertown-co', 'plumbing', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Whitney & Son Plumbing', 'ma-plumbing-whitney-son-watertown', 'plumbing', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Watertown Drain & Pipe', 'ma-plumbing-watertown-drain-pipe', 'plumbing', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),

    -- Wayland
    ('Wayland Plumbing & Heating', 'ma-plumbing-wayland-plumbing-heating', 'plumbing', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Heard Plumbing Services', 'ma-plumbing-heard-wayland', 'plumbing', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Wayland Plumbing Co.', 'ma-plumbing-wayland-co', 'plumbing', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Draper & Son Plumbing', 'ma-plumbing-draper-son-wayland', 'plumbing', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Wayland Drain & Pipe', 'ma-plumbing-wayland-drain-pipe', 'plumbing', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),

    -- Westford
    ('Westford Plumbing & Heating', 'ma-plumbing-westford-plumbing-heating', 'plumbing', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Fletcher Plumbing Services', 'ma-plumbing-fletcher-westford', 'plumbing', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Westford Plumbing Co.', 'ma-plumbing-westford-co', 'plumbing', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Hildreth & Son Plumbing', 'ma-plumbing-hildreth-son-westford', 'plumbing', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Westford Drain & Pipe', 'ma-plumbing-westford-drain-pipe', 'plumbing', NULL, ARRAY['Westford','MA','Middlesex'], NULL),

    -- Weston
    ('Weston Plumbing & Heating', 'ma-plumbing-weston-plumbing-heating', 'plumbing', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Coburn Plumbing Services', 'ma-plumbing-coburn-weston', 'plumbing', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Weston Plumbing Co.', 'ma-plumbing-weston-co', 'plumbing', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Hobbs & Son Plumbing', 'ma-plumbing-hobbs-son-weston', 'plumbing', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Weston Drain & Pipe', 'ma-plumbing-weston-drain-pipe', 'plumbing', NULL, ARRAY['Weston','MA','Middlesex'], NULL),

    -- Wilmington
    ('Wilmington Plumbing & Heating', 'ma-plumbing-wilmington-plumbing-heating', 'plumbing', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Jaquith Plumbing Services', 'ma-plumbing-jaquith-wilmington', 'plumbing', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Wilmington Plumbing Co.', 'ma-plumbing-wilmington-co', 'plumbing', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Harnden & Son Plumbing', 'ma-plumbing-harnden-son-wilmington', 'plumbing', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Wilmington Drain & Pipe', 'ma-plumbing-wilmington-drain-pipe', 'plumbing', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),

    -- Winchester
    ('Winchester Plumbing & Heating', 'ma-plumbing-winchester-plumbing-heating', 'plumbing', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Symmes Plumbing Services', 'ma-plumbing-symmes-winchester', 'plumbing', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Winchester Plumbing Co.', 'ma-plumbing-winchester-co', 'plumbing', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Bacon & Son Plumbing', 'ma-plumbing-bacon-son-winchester', 'plumbing', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Winchester Drain & Pipe', 'ma-plumbing-winchester-drain-pipe', 'plumbing', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),

    -- Woburn
    ('Woburn Plumbing & Heating', 'ma-plumbing-woburn-plumbing-heating', 'plumbing', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Thompson Plumbing Services', 'ma-plumbing-thompson-woburn', 'plumbing', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Woburn Plumbing Co.', 'ma-plumbing-woburn-co', 'plumbing', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Tidd & Son Plumbing', 'ma-plumbing-tidd-son-woburn', 'plumbing', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Woburn Drain & Pipe', 'ma-plumbing-woburn-drain-pipe', 'plumbing', NULL, ARRAY['Woburn','MA','Middlesex'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 9: NORFOLK COUNTY LOCAL PLUMBING (27 towns x 5)
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Avon
    ('Avon Plumbing & Heating', 'ma-plumbing-avon-plumbing-heating', 'plumbing', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Littlefield Plumbing Services', 'ma-plumbing-littlefield-avon', 'plumbing', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Avon Plumbing Co.', 'ma-plumbing-avon-co', 'plumbing', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Packard & Son Plumbing', 'ma-plumbing-packard-son-avon', 'plumbing', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Avon Drain & Pipe', 'ma-plumbing-avon-drain-pipe', 'plumbing', NULL, ARRAY['Avon','MA','Norfolk'], NULL),

    -- Braintree
    ('Braintree Plumbing & Heating', 'ma-plumbing-braintree-plumbing-heating', 'plumbing', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Thayer Plumbing Services', 'ma-plumbing-thayer-braintree', 'plumbing', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Braintree Plumbing Co.', 'ma-plumbing-braintree-co', 'plumbing', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Penniman & Son Plumbing', 'ma-plumbing-penniman-son-braintree', 'plumbing', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Braintree Drain & Pipe', 'ma-plumbing-braintree-drain-pipe', 'plumbing', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),

    -- Brookline
    ('Brookline Plumbing & Heating', 'ma-plumbing-brookline-plumbing-heating', 'plumbing', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Aspinwall Plumbing Services', 'ma-plumbing-aspinwall-brookline', 'plumbing', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Brookline Plumbing Co.', 'ma-plumbing-brookline-co', 'plumbing', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Devotion & Son Plumbing', 'ma-plumbing-devotion-son-brookline', 'plumbing', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Brookline Drain & Pipe', 'ma-plumbing-brookline-drain-pipe', 'plumbing', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),

    -- Canton
    ('Canton Plumbing & Heating', 'ma-plumbing-canton-plumbing-heating', 'plumbing', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Revere Plumbing Services', 'ma-plumbing-revere-canton', 'plumbing', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Canton Plumbing Co.', 'ma-plumbing-canton-co', 'plumbing', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Dunbar & Son Plumbing', 'ma-plumbing-dunbar-son-canton', 'plumbing', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Canton Drain & Pipe', 'ma-plumbing-canton-drain-pipe', 'plumbing', NULL, ARRAY['Canton','MA','Norfolk'], NULL),

    -- Cohasset
    ('Cohasset Plumbing & Heating', 'ma-plumbing-cohasset-plumbing-heating', 'plumbing', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Bates Plumbing Services', 'ma-plumbing-bates-cohasset', 'plumbing', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Cohasset Plumbing Co.', 'ma-plumbing-cohasset-co', 'plumbing', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Pratt & Son Plumbing', 'ma-plumbing-pratt-son-cohasset', 'plumbing', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Cohasset Drain & Pipe', 'ma-plumbing-cohasset-drain-pipe', 'plumbing', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),

    -- Dedham
    ('Dedham Plumbing & Heating', 'ma-plumbing-dedham-plumbing-heating', 'plumbing', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Avery Plumbing Services', 'ma-plumbing-avery-dedham', 'plumbing', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Dedham Plumbing Co.', 'ma-plumbing-dedham-co', 'plumbing', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Fairbanks & Son Plumbing', 'ma-plumbing-fairbanks-son-dedham', 'plumbing', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Dedham Drain & Pipe', 'ma-plumbing-dedham-drain-pipe', 'plumbing', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),

    -- Dover
    ('Dover Plumbing & Heating', 'ma-plumbing-dover-plumbing-heating', 'plumbing', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Battelle Plumbing Services', 'ma-plumbing-battelle-dover', 'plumbing', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Dover Plumbing Co.', 'ma-plumbing-dover-co', 'plumbing', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Chickering & Son Plumbing', 'ma-plumbing-chickering-son-dover', 'plumbing', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Dover Drain & Pipe', 'ma-plumbing-dover-drain-pipe', 'plumbing', NULL, ARRAY['Dover','MA','Norfolk'], NULL),

    -- Foxborough
    ('Foxborough Plumbing & Heating', 'ma-plumbing-foxborough-plumbing-heating', 'plumbing', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Carpenter Plumbing Services', 'ma-plumbing-carpenter-foxborough', 'plumbing', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Foxborough Plumbing Co.', 'ma-plumbing-foxborough-co', 'plumbing', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Boyden & Son Plumbing', 'ma-plumbing-boyden-son-foxborough', 'plumbing', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Foxborough Drain & Pipe', 'ma-plumbing-foxborough-drain-pipe', 'plumbing', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),

    -- Franklin
    ('Franklin Plumbing & Heating', 'ma-plumbing-franklin-plumbing-heating', 'plumbing', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Metcalf Plumbing Services', 'ma-plumbing-metcalf-franklin', 'plumbing', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Franklin Plumbing Co.', 'ma-plumbing-franklin-co', 'plumbing', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Ray & Son Plumbing', 'ma-plumbing-ray-son-franklin', 'plumbing', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Franklin Drain & Pipe', 'ma-plumbing-franklin-drain-pipe', 'plumbing', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),

    -- Holbrook
    ('Holbrook Plumbing & Heating', 'ma-plumbing-holbrook-plumbing-heating', 'plumbing', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Niles Plumbing Services', 'ma-plumbing-niles-holbrook', 'plumbing', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Holbrook Plumbing Co.', 'ma-plumbing-holbrook-co', 'plumbing', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Thayer & Son Plumbing', 'ma-plumbing-thayer-son-holbrook', 'plumbing', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Holbrook Drain & Pipe', 'ma-plumbing-holbrook-drain-pipe', 'plumbing', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),

    -- Medfield
    ('Medfield Plumbing & Heating', 'ma-plumbing-medfield-plumbing-heating', 'plumbing', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Chenery Plumbing Services', 'ma-plumbing-chenery-medfield', 'plumbing', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Medfield Plumbing Co.', 'ma-plumbing-medfield-co', 'plumbing', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Plimpton & Son Plumbing', 'ma-plumbing-plimpton-son-medfield', 'plumbing', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Medfield Drain & Pipe', 'ma-plumbing-medfield-drain-pipe', 'plumbing', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),

    -- Medway
    ('Medway Plumbing & Heating', 'ma-plumbing-medway-plumbing-heating', 'plumbing', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Lovering Plumbing Services', 'ma-plumbing-lovering-medway', 'plumbing', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Medway Plumbing Co.', 'ma-plumbing-medway-co', 'plumbing', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Sanford & Son Plumbing', 'ma-plumbing-sanford-son-medway', 'plumbing', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Medway Drain & Pipe', 'ma-plumbing-medway-drain-pipe', 'plumbing', NULL, ARRAY['Medway','MA','Norfolk'], NULL),

    -- Millis
    ('Millis Plumbing & Heating', 'ma-plumbing-millis-plumbing-heating', 'plumbing', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Rockwell Plumbing Services', 'ma-plumbing-rockwell-millis', 'plumbing', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Millis Plumbing Co.', 'ma-plumbing-millis-co', 'plumbing', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Richardson & Son Plumbing', 'ma-plumbing-richardson-son-millis', 'plumbing', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Millis Drain & Pipe', 'ma-plumbing-millis-drain-pipe', 'plumbing', NULL, ARRAY['Millis','MA','Norfolk'], NULL),

    -- Milton
    ('Milton Plumbing & Heating', 'ma-plumbing-milton-plumbing-heating', 'plumbing', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Tucker Plumbing Services', 'ma-plumbing-tucker-milton', 'plumbing', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Milton Plumbing Co.', 'ma-plumbing-milton-co', 'plumbing', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Vose & Son Plumbing', 'ma-plumbing-vose-son-milton', 'plumbing', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Milton Drain & Pipe', 'ma-plumbing-milton-drain-pipe', 'plumbing', NULL, ARRAY['Milton','MA','Norfolk'], NULL),

    -- Needham
    ('Needham Plumbing & Heating', 'ma-plumbing-needham-plumbing-heating', 'plumbing', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Kingsbury Plumbing Services', 'ma-plumbing-kingsbury-needham', 'plumbing', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Needham Plumbing Co.', 'ma-plumbing-needham-co', 'plumbing', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Eaton & Son Plumbing', 'ma-plumbing-eaton-son-needham', 'plumbing', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Needham Drain & Pipe', 'ma-plumbing-needham-drain-pipe', 'plumbing', NULL, ARRAY['Needham','MA','Norfolk'], NULL),

    -- Norfolk
    ('Norfolk Plumbing & Heating', 'ma-plumbing-norfolk-plumbing-heating', 'plumbing', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Pond Plumbing Services', 'ma-plumbing-pond-norfolk', 'plumbing', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Norfolk Plumbing Co.', 'ma-plumbing-norfolk-co', 'plumbing', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Mann & Son Plumbing', 'ma-plumbing-mann-son-norfolk', 'plumbing', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Norfolk Drain & Pipe', 'ma-plumbing-norfolk-drain-pipe', 'plumbing', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),

    -- Norwood
    ('Norwood Plumbing & Heating', 'ma-plumbing-norwood-plumbing-heating', 'plumbing', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Guild Plumbing Services', 'ma-plumbing-guild-norwood', 'plumbing', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Norwood Plumbing Co.', 'ma-plumbing-norwood-co', 'plumbing', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Morse & Son Plumbing', 'ma-plumbing-morse-son-norwood', 'plumbing', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Norwood Drain & Pipe', 'ma-plumbing-norwood-drain-pipe', 'plumbing', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),

    -- Plainville
    ('Plainville Plumbing & Heating', 'ma-plumbing-plainville-plumbing-heating', 'plumbing', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Fuller Plumbing Services', 'ma-plumbing-fuller-plainville', 'plumbing', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Plainville Plumbing Co.', 'ma-plumbing-plainville-co', 'plumbing', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Shepard & Son Plumbing', 'ma-plumbing-shepard-son-plainville', 'plumbing', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Plainville Drain & Pipe', 'ma-plumbing-plainville-drain-pipe', 'plumbing', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),

    -- Quincy
    ('Quincy Plumbing & Heating', 'ma-plumbing-quincy-plumbing-heating', 'plumbing', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Adams Plumbing Services', 'ma-plumbing-adams-quincy', 'plumbing', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Quincy Plumbing Co.', 'ma-plumbing-quincy-co', 'plumbing', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Hancock & Son Plumbing', 'ma-plumbing-hancock-son-quincy', 'plumbing', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Quincy Drain & Pipe', 'ma-plumbing-quincy-drain-pipe', 'plumbing', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),

    -- Randolph
    ('Randolph Plumbing & Heating', 'ma-plumbing-randolph-plumbing-heating', 'plumbing', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Stetson Plumbing Services', 'ma-plumbing-stetson-randolph', 'plumbing', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Randolph Plumbing Co.', 'ma-plumbing-randolph-co', 'plumbing', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Tower & Son Plumbing', 'ma-plumbing-tower-son-randolph', 'plumbing', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Randolph Drain & Pipe', 'ma-plumbing-randolph-drain-pipe', 'plumbing', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),

    -- Sharon
    ('Sharon Plumbing & Heating', 'ma-plumbing-sharon-plumbing-heating', 'plumbing', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Billings Plumbing Services', 'ma-plumbing-billings-sharon', 'plumbing', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Sharon Plumbing Co.', 'ma-plumbing-sharon-co', 'plumbing', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Massapoag & Son Plumbing', 'ma-plumbing-massapoag-son-sharon', 'plumbing', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Sharon Drain & Pipe', 'ma-plumbing-sharon-drain-pipe', 'plumbing', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),

    -- Stoughton
    ('Stoughton Plumbing & Heating', 'ma-plumbing-stoughton-plumbing-heating', 'plumbing', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Drake Plumbing Services', 'ma-plumbing-drake-stoughton', 'plumbing', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Stoughton Plumbing Co.', 'ma-plumbing-stoughton-co', 'plumbing', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Curtis & Son Plumbing', 'ma-plumbing-curtis-son-stoughton', 'plumbing', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Stoughton Drain & Pipe', 'ma-plumbing-stoughton-drain-pipe', 'plumbing', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),

    -- Walpole
    ('Walpole Plumbing & Heating', 'ma-plumbing-walpole-plumbing-heating', 'plumbing', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Lewis Plumbing Services', 'ma-plumbing-lewis-walpole', 'plumbing', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Walpole Plumbing Co.', 'ma-plumbing-walpole-co', 'plumbing', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Fisher & Son Plumbing', 'ma-plumbing-fisher-son-walpole', 'plumbing', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Walpole Drain & Pipe', 'ma-plumbing-walpole-drain-pipe', 'plumbing', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),

    -- Wellesley
    ('Wellesley Plumbing & Heating', 'ma-plumbing-wellesley-plumbing-heating', 'plumbing', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Hunnewell Plumbing Services', 'ma-plumbing-hunnewell-wellesley', 'plumbing', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Wellesley Plumbing Co.', 'ma-plumbing-wellesley-co', 'plumbing', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Durant & Son Plumbing', 'ma-plumbing-durant-son-wellesley', 'plumbing', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Wellesley Drain & Pipe', 'ma-plumbing-wellesley-drain-pipe', 'plumbing', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),

    -- Westwood
    ('Westwood Plumbing & Heating', 'ma-plumbing-westwood-plumbing-heating', 'plumbing', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Colburn Plumbing Services', 'ma-plumbing-colburn-westwood', 'plumbing', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Westwood Plumbing Co.', 'ma-plumbing-westwood-co', 'plumbing', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Baker & Son Plumbing', 'ma-plumbing-baker-son-westwood', 'plumbing', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Westwood Drain & Pipe', 'ma-plumbing-westwood-drain-pipe', 'plumbing', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),

    -- Weymouth
    ('Weymouth Plumbing & Heating', 'ma-plumbing-weymouth-plumbing-heating', 'plumbing', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Torrey Plumbing Services', 'ma-plumbing-torrey-weymouth', 'plumbing', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Weymouth Plumbing Co.', 'ma-plumbing-weymouth-co', 'plumbing', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Beal & Son Plumbing', 'ma-plumbing-beal-son-weymouth', 'plumbing', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Weymouth Drain & Pipe', 'ma-plumbing-weymouth-drain-pipe', 'plumbing', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),

    -- Wrentham
    ('Wrentham Plumbing & Heating', 'ma-plumbing-wrentham-plumbing-heating', 'plumbing', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Hawes Plumbing Services', 'ma-plumbing-hawes-wrentham', 'plumbing', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Wrentham Plumbing Co.', 'ma-plumbing-wrentham-co', 'plumbing', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Sheldon & Son Plumbing', 'ma-plumbing-sheldon-son-wrentham', 'plumbing', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Wrentham Drain & Pipe', 'ma-plumbing-wrentham-drain-pipe', 'plumbing', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ============================================================
-- SECTION 10: PLYMOUTH COUNTY LOCAL PLUMBING (27 towns x 5)
-- ============================================================
INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- Abington
    ('Abington Plumbing & Heating', 'ma-plumbing-abington-plumbing-heating', 'plumbing', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Nash Plumbing Services', 'ma-plumbing-nash-abington', 'plumbing', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Abington Plumbing Co.', 'ma-plumbing-abington-co', 'plumbing', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Shaw & Son Plumbing', 'ma-plumbing-shaw-son-abington', 'plumbing', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Abington Drain & Pipe', 'ma-plumbing-abington-drain-pipe', 'plumbing', NULL, ARRAY['Abington','MA','Plymouth'], NULL),

    -- Bridgewater
    ('Bridgewater Plumbing & Heating', 'ma-plumbing-bridgewater-plumbing-heating', 'plumbing', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Keith Plumbing Services', 'ma-plumbing-keith-bridgewater', 'plumbing', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Plumbing Co.', 'ma-plumbing-bridgewater-co', 'plumbing', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Mitchell & Son Plumbing', 'ma-plumbing-mitchell-son-bridgewater', 'plumbing', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Drain & Pipe', 'ma-plumbing-bridgewater-drain-pipe', 'plumbing', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),

    -- Brockton
    ('Brockton Plumbing & Heating', 'ma-plumbing-brockton-plumbing-heating', 'plumbing', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Montello Plumbing Services', 'ma-plumbing-montello-brockton', 'plumbing', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Brockton Plumbing Co.', 'ma-plumbing-brockton-co', 'plumbing', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Perkins & Son Plumbing', 'ma-plumbing-perkins-son-brockton', 'plumbing', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Brockton Drain & Pipe', 'ma-plumbing-brockton-drain-pipe', 'plumbing', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),

    -- Carver
    ('Carver Plumbing & Heating', 'ma-plumbing-carver-plumbing-heating', 'plumbing', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Savery Plumbing Services', 'ma-plumbing-savery-carver', 'plumbing', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Carver Plumbing Co.', 'ma-plumbing-carver-co', 'plumbing', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Atwood & Son Plumbing', 'ma-plumbing-atwood-son-carver', 'plumbing', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Carver Drain & Pipe', 'ma-plumbing-carver-drain-pipe', 'plumbing', NULL, ARRAY['Carver','MA','Plymouth'], NULL),

    -- Duxbury
    ('Duxbury Plumbing & Heating', 'ma-plumbing-duxbury-plumbing-heating', 'plumbing', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Standish Plumbing Services', 'ma-plumbing-standish-duxbury', 'plumbing', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Duxbury Plumbing Co.', 'ma-plumbing-duxbury-co', 'plumbing', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Alden & Son Plumbing', 'ma-plumbing-alden-son-duxbury', 'plumbing', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Duxbury Drain & Pipe', 'ma-plumbing-duxbury-drain-pipe', 'plumbing', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),

    -- East Bridgewater
    ('East Bridgewater Plumbing & Heating', 'ma-plumbing-east-bridgewater-plumbing-heating', 'plumbing', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('Whitman Plumbing Services', 'ma-plumbing-whitman-east-bridgewater', 'plumbing', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('East Bridgewater Plumbing Co.', 'ma-plumbing-east-bridgewater-co', 'plumbing', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('Hooper & Son Plumbing', 'ma-plumbing-hooper-son-east-bridgewater', 'plumbing', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('East Bridgewater Drain & Pipe', 'ma-plumbing-east-bridgewater-drain-pipe', 'plumbing', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),

    -- Halifax
    ('Halifax Plumbing & Heating', 'ma-plumbing-halifax-plumbing-heating', 'plumbing', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Thomson Plumbing Services', 'ma-plumbing-thomson-halifax', 'plumbing', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Halifax Plumbing Co.', 'ma-plumbing-halifax-co', 'plumbing', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Sturtevant & Son Plumbing', 'ma-plumbing-sturtevant-son-halifax', 'plumbing', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Halifax Drain & Pipe', 'ma-plumbing-halifax-drain-pipe', 'plumbing', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),

    -- Hanover
    ('Hanover Plumbing & Heating', 'ma-plumbing-hanover-plumbing-heating', 'plumbing', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Stetson Plumbing Services', 'ma-plumbing-stetson-hanover', 'plumbing', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Hanover Plumbing Co.', 'ma-plumbing-hanover-co', 'plumbing', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Salmond & Son Plumbing', 'ma-plumbing-salmond-son-hanover', 'plumbing', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Hanover Drain & Pipe', 'ma-plumbing-hanover-drain-pipe', 'plumbing', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),

    -- Hanson
    ('Hanson Plumbing & Heating', 'ma-plumbing-hanson-plumbing-heating', 'plumbing', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Phillips Plumbing Services', 'ma-plumbing-phillips-hanson', 'plumbing', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Hanson Plumbing Co.', 'ma-plumbing-hanson-co', 'plumbing', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Waterman & Son Plumbing', 'ma-plumbing-waterman-son-hanson', 'plumbing', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Hanson Drain & Pipe', 'ma-plumbing-hanson-drain-pipe', 'plumbing', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),

    -- Hingham
    ('Hingham Plumbing & Heating', 'ma-plumbing-hingham-plumbing-heating', 'plumbing', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Cushing Plumbing Services', 'ma-plumbing-cushing-hingham', 'plumbing', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Hingham Plumbing Co.', 'ma-plumbing-hingham-co', 'plumbing', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Lincoln & Son Plumbing', 'ma-plumbing-lincoln-son-hingham', 'plumbing', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Hingham Drain & Pipe', 'ma-plumbing-hingham-drain-pipe', 'plumbing', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),

    -- Hull
    ('Hull Plumbing & Heating', 'ma-plumbing-hull-plumbing-heating', 'plumbing', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Nantasket Plumbing Services', 'ma-plumbing-nantasket-hull', 'plumbing', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Hull Plumbing Co.', 'ma-plumbing-hull-co', 'plumbing', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Loring & Son Plumbing', 'ma-plumbing-loring-son-hull', 'plumbing', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Hull Drain & Pipe', 'ma-plumbing-hull-drain-pipe', 'plumbing', NULL, ARRAY['Hull','MA','Plymouth'], NULL),

    -- Kingston
    ('Kingston Plumbing & Heating', 'ma-plumbing-kingston-plumbing-heating', 'plumbing', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Bradford Plumbing Services', 'ma-plumbing-bradford-kingston', 'plumbing', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Kingston Plumbing Co.', 'ma-plumbing-kingston-co', 'plumbing', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Holmes & Son Plumbing', 'ma-plumbing-holmes-son-kingston', 'plumbing', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Kingston Drain & Pipe', 'ma-plumbing-kingston-drain-pipe', 'plumbing', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),

    -- Lakeville
    ('Lakeville Plumbing & Heating', 'ma-plumbing-lakeville-plumbing-heating', 'plumbing', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Precinct Plumbing Services', 'ma-plumbing-precinct-lakeville', 'plumbing', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Lakeville Plumbing Co.', 'ma-plumbing-lakeville-co', 'plumbing', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Haskins & Son Plumbing', 'ma-plumbing-haskins-son-lakeville', 'plumbing', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Lakeville Drain & Pipe', 'ma-plumbing-lakeville-drain-pipe', 'plumbing', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),

    -- Marion
    ('Marion Plumbing & Heating', 'ma-plumbing-marion-plumbing-heating', 'plumbing', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Tabor Plumbing Services', 'ma-plumbing-tabor-marion', 'plumbing', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Marion Plumbing Co.', 'ma-plumbing-marion-co', 'plumbing', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Delano & Son Plumbing', 'ma-plumbing-delano-son-marion', 'plumbing', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Marion Drain & Pipe', 'ma-plumbing-marion-drain-pipe', 'plumbing', NULL, ARRAY['Marion','MA','Plymouth'], NULL),

    -- Marshfield
    ('Marshfield Plumbing & Heating', 'ma-plumbing-marshfield-plumbing-heating', 'plumbing', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Winslow Plumbing Services', 'ma-plumbing-winslow-marshfield', 'plumbing', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Marshfield Plumbing Co.', 'ma-plumbing-marshfield-co', 'plumbing', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Thomas & Son Plumbing', 'ma-plumbing-thomas-son-marshfield', 'plumbing', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Marshfield Drain & Pipe', 'ma-plumbing-marshfield-drain-pipe', 'plumbing', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),

    -- Mattapoisett
    ('Mattapoisett Plumbing & Heating', 'ma-plumbing-mattapoisett-plumbing-heating', 'plumbing', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Barstow Plumbing Services', 'ma-plumbing-barstow-mattapoisett', 'plumbing', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Mattapoisett Plumbing Co.', 'ma-plumbing-mattapoisett-co', 'plumbing', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Cannon & Son Plumbing', 'ma-plumbing-cannon-son-mattapoisett', 'plumbing', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Mattapoisett Drain & Pipe', 'ma-plumbing-mattapoisett-drain-pipe', 'plumbing', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),

    -- Middleborough
    ('Middleborough Plumbing & Heating', 'ma-plumbing-middleborough-plumbing-heating', 'plumbing', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Tinkham Plumbing Services', 'ma-plumbing-tinkham-middleborough', 'plumbing', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Middleborough Plumbing Co.', 'ma-plumbing-middleborough-co', 'plumbing', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Wood & Son Plumbing', 'ma-plumbing-wood-son-middleborough', 'plumbing', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Middleborough Drain & Pipe', 'ma-plumbing-middleborough-drain-pipe', 'plumbing', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),

    -- Norwell
    ('Norwell Plumbing & Heating', 'ma-plumbing-norwell-plumbing-heating', 'plumbing', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Jacobs Plumbing Services', 'ma-plumbing-jacobs-norwell', 'plumbing', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Norwell Plumbing Co.', 'ma-plumbing-norwell-co', 'plumbing', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Damon & Son Plumbing', 'ma-plumbing-damon-son-norwell', 'plumbing', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Norwell Drain & Pipe', 'ma-plumbing-norwell-drain-pipe', 'plumbing', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),

    -- Pembroke
    ('Pembroke Plumbing & Heating', 'ma-plumbing-pembroke-plumbing-heating', 'plumbing', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Barker Plumbing Services', 'ma-plumbing-barker-pembroke', 'plumbing', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Pembroke Plumbing Co.', 'ma-plumbing-pembroke-co', 'plumbing', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Turner & Son Plumbing', 'ma-plumbing-turner-son-pembroke', 'plumbing', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Pembroke Drain & Pipe', 'ma-plumbing-pembroke-drain-pipe', 'plumbing', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),

    -- Plymouth
    ('Plymouth Plumbing & Heating', 'ma-plumbing-plymouth-plumbing-heating', 'plumbing', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Bradford Plumbing Services', 'ma-plumbing-bradford-plymouth', 'plumbing', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Plymouth Plumbing Co.', 'ma-plumbing-plymouth-co', 'plumbing', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Brewster & Son Plumbing', 'ma-plumbing-brewster-son-plymouth', 'plumbing', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Plymouth Drain & Pipe', 'ma-plumbing-plymouth-drain-pipe', 'plumbing', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),

    -- Plympton
    ('Plympton Plumbing & Heating', 'ma-plumbing-plympton-plumbing-heating', 'plumbing', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Soule Plumbing Services', 'ma-plumbing-soule-plympton', 'plumbing', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Plympton Plumbing Co.', 'ma-plumbing-plympton-co', 'plumbing', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Harlow & Son Plumbing', 'ma-plumbing-harlow-son-plympton', 'plumbing', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Plympton Drain & Pipe', 'ma-plumbing-plympton-drain-pipe', 'plumbing', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),

    -- Rochester
    ('Rochester Plumbing & Heating', 'ma-plumbing-rochester-plumbing-heating', 'plumbing', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Hartley Plumbing Services', 'ma-plumbing-hartley-rochester', 'plumbing', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Rochester Plumbing Co.', 'ma-plumbing-rochester-co', 'plumbing', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Leonard & Son Plumbing', 'ma-plumbing-leonard-son-rochester', 'plumbing', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Rochester Drain & Pipe', 'ma-plumbing-rochester-drain-pipe', 'plumbing', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),

    -- Rockland
    ('Rockland Plumbing & Heating', 'ma-plumbing-rockland-plumbing-heating', 'plumbing', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Reed Plumbing Services', 'ma-plumbing-reed-rockland', 'plumbing', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Rockland Plumbing Co.', 'ma-plumbing-rockland-co', 'plumbing', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Jenkins & Son Plumbing', 'ma-plumbing-jenkins-son-rockland', 'plumbing', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Rockland Drain & Pipe', 'ma-plumbing-rockland-drain-pipe', 'plumbing', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),

    -- Scituate
    ('Scituate Plumbing & Heating', 'ma-plumbing-scituate-plumbing-heating', 'plumbing', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Lawson Plumbing Services', 'ma-plumbing-lawson-scituate', 'plumbing', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Scituate Plumbing Co.', 'ma-plumbing-scituate-co', 'plumbing', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Bailey & Son Plumbing', 'ma-plumbing-bailey-son-scituate', 'plumbing', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Scituate Drain & Pipe', 'ma-plumbing-scituate-drain-pipe', 'plumbing', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),

    -- Wareham
    ('Wareham Plumbing & Heating', 'ma-plumbing-wareham-plumbing-heating', 'plumbing', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Fearing Plumbing Services', 'ma-plumbing-fearing-wareham', 'plumbing', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Wareham Plumbing Co.', 'ma-plumbing-wareham-co', 'plumbing', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Besse & Son Plumbing', 'ma-plumbing-besse-son-wareham', 'plumbing', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Wareham Drain & Pipe', 'ma-plumbing-wareham-drain-pipe', 'plumbing', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),

    -- West Bridgewater
    ('West Bridgewater Plumbing & Heating', 'ma-plumbing-west-bridgewater-plumbing-heating', 'plumbing', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('Howard Plumbing Services', 'ma-plumbing-howard-west-bridgewater', 'plumbing', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('West Bridgewater Plumbing Co.', 'ma-plumbing-west-bridgewater-co', 'plumbing', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('Packard & Son Plumbing', 'ma-plumbing-packard-son-west-bridgewater', 'plumbing', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('West Bridgewater Drain & Pipe', 'ma-plumbing-west-bridgewater-drain-pipe', 'plumbing', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),

    -- Whitman
    ('Whitman Plumbing & Heating', 'ma-plumbing-whitman-plumbing-heating', 'plumbing', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Corthell Plumbing Services', 'ma-plumbing-corthell-whitman', 'plumbing', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Whitman Plumbing Co.', 'ma-plumbing-whitman-co', 'plumbing', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Hobart & Son Plumbing', 'ma-plumbing-hobart-son-whitman', 'plumbing', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Whitman Drain & Pipe', 'ma-plumbing-whitman-drain-pipe', 'plumbing', NULL, ARRAY['Whitman','MA','Plymouth'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;
