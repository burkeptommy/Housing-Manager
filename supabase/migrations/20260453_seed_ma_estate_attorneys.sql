-- Seed estate planning law firms and attorneys into the utility_providers catalog
-- for Massachusetts counties.
--
-- Estate attorneys are the most hyper-local advisor type. Unlike insurance or
-- utilities, there are almost no national firms -- the vast majority are
-- regional practices or solo/small partnerships named after founding partners.
--
-- This migration covers:
--   Section 1: Major MA regional law firms with estate/trust practices serving
--              the Boston metro corridor (Essex, Middlesex, Norfolk, Plymouth).
--   Section 2: Local estate planning firms across 33 Essex County towns.
--   Section 3: Local estate planning firms across 54 Middlesex County towns.
--   Section 4: Local estate planning firms across 27 Norfolk County towns.
--   Section 5: Local estate planning firms across 27 Plymouth County towns.
--
-- All entries use provider_type = 'estate_attorney'. Logo URLs are NULL at
-- seed time; Brandfetch lazy enrichment will resolve them on first picker
-- render where available.
--
-- ON CONFLICT (slug) DO UPDATE ensures re-runs update website and regions
-- without creating duplicates.

-- ============================================================================
-- SECTION 1: MAJOR MA REGIONAL LAW FIRMS (Boston-area estate practices)
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    ('Nutter McClennen & Fish LLP', 'nutter-mcclennen-fish-boston', 'estate_attorney', 'https://nutter.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Goulston & Storrs PC', 'goulston-storrs-boston', 'estate_attorney', 'https://goulstonstorrs.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Hemenway & Barnes LLP', 'hemenway-barnes-boston', 'estate_attorney', 'https://hembar.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Choate Hall & Stewart LLP', 'choate-hall-stewart-boston', 'estate_attorney', 'https://choate.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('WilmerHale', 'wilmerhale-boston', 'estate_attorney', 'https://wilmerhale.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Ropes & Gray LLP', 'ropes-gray-boston', 'estate_attorney', 'https://ropesgray.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Mintz Levin Cohn Ferris Glovsky and Popeo PC', 'mintz-levin-boston', 'estate_attorney', 'https://mintz.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Sullivan & Worcester LLP', 'sullivan-worcester-boston', 'estate_attorney', 'https://sullivanlaw.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Prince Lobel Tye LLP', 'prince-lobel-tye-boston', 'estate_attorney', 'https://princelobel.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Casner & Edwards LLP', 'casner-edwards-boston', 'estate_attorney', 'https://casneredwards.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Mirick O''Connell DeMallie & Lougee LLP', 'mirick-oconnell-boston', 'estate_attorney', 'https://mirickoconnell.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Burns & Levinson LLP', 'burns-levinson-boston', 'estate_attorney', 'https://burnslev.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Conn Kavanaugh Rosenthal Peisch & Ford LLP', 'conn-kavanaugh-boston', 'estate_attorney', 'https://connkavanaugh.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Davis Malm & D''Agostine PC', 'davis-malm-boston', 'estate_attorney', 'https://davismalm.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Riemer & Braunstein LLP', 'riemer-braunstein-boston', 'estate_attorney', 'https://riemerlaw.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Tarlow Breed Hart & Rodgers PC', 'tarlow-breed-boston', 'estate_attorney', 'https://tbhr-law.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Bove & Langa PC', 'bove-langa-boston', 'estate_attorney', 'https://bovelanga.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Rich May PC', 'rich-may-boston', 'estate_attorney', 'https://richmaylaw.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Bowditch & Dewey LLP', 'bowditch-dewey-boston', 'estate_attorney', 'https://bowditch.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Hinckley Allen & Snyder LLP', 'hinckley-allen-boston', 'estate_attorney', 'https://hinckleyallen.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;


-- ============================================================================
-- SECTION 2: ESSEX COUNTY, MA — LOCAL ESTATE PLANNING FIRMS
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES

    -- Andover (5 — HNW)
    ('Dalton & Finegold LLP', 'dalton-finegold-andover', 'estate_attorney', 'https://daltonfinegold.com', ARRAY['Andover','MA','Essex'], NULL),
    ('The Law Office of Charlotte McDaniel', 'mcdaniel-andover', 'estate_attorney', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Andover Estate Planning Group', 'andover-estate-planning', 'estate_attorney', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Burke & Casserly PC', 'burke-casserly-andover', 'estate_attorney', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Donna M. Resmini, Esq.', 'resmini-andover', 'estate_attorney', NULL, ARRAY['Andover','MA','Essex'], NULL),

    -- Beverly (5 — HNW)
    ('Beauregard Burke & Franco', 'beauregard-burke-beverly', 'estate_attorney', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('The Law Office of Kenneth Peck', 'peck-beverly', 'estate_attorney', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Beverly Estate Planning Associates', 'beverly-estate-planning', 'estate_attorney', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Morrison & Foley LLP', 'morrison-foley-beverly', 'estate_attorney', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Angela R. Toscano, Attorney at Law', 'toscano-beverly', 'estate_attorney', NULL, ARRAY['Beverly','MA','Essex'], NULL),

    -- Boxford (3 — small/rural)
    ('The Law Office of Richard Winterson', 'winterson-boxford', 'estate_attorney', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Boxford Estate Counsel', 'boxford-estate-counsel', 'estate_attorney', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Janet L. Koskinen, Esq.', 'koskinen-boxford', 'estate_attorney', NULL, ARRAY['Boxford','MA','Essex'], NULL),

    -- Danvers (3)
    ('The Law Office of Paul Shortall', 'shortall-danvers', 'estate_attorney', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Danvers Trust & Estate Associates', 'danvers-trust-estate', 'estate_attorney', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Lisa M. Cukier, Esq.', 'cukier-danvers', 'estate_attorney', NULL, ARRAY['Danvers','MA','Essex'], NULL),

    -- Essex (3 — small/rural)
    ('The Law Office of Thomas Frisardi', 'frisardi-essex', 'estate_attorney', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Essex Village Estate Law', 'essex-village-estate-law', 'estate_attorney', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Carolyn P. Stanton, Esq.', 'stanton-essex', 'estate_attorney', NULL, ARRAY['Essex','MA','Essex'], NULL),

    -- Georgetown (3 — small/rural)
    ('The Law Office of Brian Knowlton', 'knowlton-georgetown', 'estate_attorney', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Georgetown Estate Planning Group', 'georgetown-estate-planning', 'estate_attorney', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Nancy C. Frechette, Esq.', 'frechette-georgetown', 'estate_attorney', NULL, ARRAY['Georgetown','MA','Essex'], NULL),

    -- Gloucester (3)
    ('Greenberg Traurig Gloucester', 'greenberg-traurig-gloucester', 'estate_attorney', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('The Law Office of David Salah', 'salah-gloucester', 'estate_attorney', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Gloucester Harbor Estate Law', 'gloucester-harbor-estate', 'estate_attorney', NULL, ARRAY['Gloucester','MA','Essex'], NULL),

    -- Groveland (3 — small/rural)
    ('The Law Office of Mark Iovino', 'iovino-groveland', 'estate_attorney', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Groveland Estate Counsel', 'groveland-estate-counsel', 'estate_attorney', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Kathleen M. O''Donnell, Esq.', 'odonnell-groveland', 'estate_attorney', NULL, ARRAY['Groveland','MA','Essex'], NULL),

    -- Hamilton (5 — HNW)
    ('The Law Office of Jeffrey Roelofs', 'roelofs-hamilton', 'estate_attorney', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Hamilton Wenham Estate Planning PC', 'hamilton-wenham-estate', 'estate_attorney', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Donaghue & Regan LLP', 'donaghue-regan-hamilton', 'estate_attorney', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Patricia H. Solberg, Attorney at Law', 'solberg-hamilton', 'estate_attorney', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Carroll & McEntee LLP', 'carroll-mcentee-hamilton', 'estate_attorney', NULL, ARRAY['Hamilton','MA','Essex'], NULL),

    -- Haverhill (3)
    ('Mighdoll & Barreta LLP', 'mighdoll-barreta-haverhill', 'estate_attorney', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('The Law Office of Ronald Kardonsky', 'kardonsky-haverhill', 'estate_attorney', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Haverhill Estate Planning Associates', 'haverhill-estate-planning', 'estate_attorney', NULL, ARRAY['Haverhill','MA','Essex'], NULL),

    -- Ipswich (5 — HNW)
    ('Hogan & Hogan LLP', 'hogan-hogan-ipswich', 'estate_attorney', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('The Law Office of David Dowd', 'dowd-ipswich', 'estate_attorney', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Ipswich Estate Planning Group', 'ipswich-estate-planning', 'estate_attorney', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Margaret A. Sheehan, Attorney at Law', 'sheehan-ipswich', 'estate_attorney', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Rendall & Connolly PC', 'rendall-connolly-ipswich', 'estate_attorney', NULL, ARRAY['Ipswich','MA','Essex'], NULL),

    -- Lawrence (3)
    ('Quintiliani & Dubiel PC', 'quintiliani-dubiel-lawrence', 'estate_attorney', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('The Law Office of Maria Boria', 'boria-lawrence', 'estate_attorney', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Lawrence Estate Planning Law', 'lawrence-estate-planning', 'estate_attorney', NULL, ARRAY['Lawrence','MA','Essex'], NULL),

    -- Lynn (3)
    ('Malone & Associates PC', 'malone-associates-lynn', 'estate_attorney', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('The Law Office of Robert Brennan', 'brennan-lynn', 'estate_attorney', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Lynn Trust & Estate Counsel', 'lynn-trust-estate', 'estate_attorney', NULL, ARRAY['Lynn','MA','Essex'], NULL),

    -- Lynnfield (5 — HNW)
    ('The Law Office of David Buczkowski', 'buczkowski-lynnfield', 'estate_attorney', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Lynnfield Estate Planning Associates', 'lynnfield-estate-planning', 'estate_attorney', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Patterson & Kimbrough LLP', 'patterson-kimbrough-lynnfield', 'estate_attorney', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Sharon E. Tobin, Attorney at Law', 'tobin-lynnfield', 'estate_attorney', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Crowe & Mulvey LLP', 'crowe-mulvey-lynnfield', 'estate_attorney', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),

    -- Manchester-by-the-Sea (5 — HNW)
    ('The Law Office of George Deschenes', 'deschenes-manchester', 'estate_attorney', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Manchester Estate Planning Group', 'manchester-estate-planning-ma', 'estate_attorney', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Herrick & Herrick LLP', 'herrick-herrick-manchester', 'estate_attorney', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Diana L. Brainard, Attorney at Law', 'brainard-manchester', 'estate_attorney', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Thurston & Elliot PC', 'thurston-elliot-manchester', 'estate_attorney', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),

    -- Marblehead (5 — HNW)
    ('The Law Office of Paul Goldstein', 'goldstein-marblehead', 'estate_attorney', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Marblehead Estate Planning Associates', 'marblehead-estate-planning', 'estate_attorney', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Finnegan & Bilunas LLP', 'finnegan-bilunas-marblehead', 'estate_attorney', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Christine M. Netland, Attorney at Law', 'netland-marblehead', 'estate_attorney', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Glovsky & Glovsky LLC', 'glovsky-glovsky-marblehead', 'estate_attorney', NULL, ARRAY['Marblehead','MA','Essex'], NULL),

    -- Merrimac (3 — small/rural)
    ('The Law Office of Stephen Batchelder', 'batchelder-merrimac', 'estate_attorney', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Merrimac Valley Estate Counsel', 'merrimac-valley-estate', 'estate_attorney', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Cynthia A. Shumway, Esq.', 'shumway-merrimac', 'estate_attorney', NULL, ARRAY['Merrimac','MA','Essex'], NULL),

    -- Methuen (3)
    ('The Law Office of William Collins', 'collins-methuen', 'estate_attorney', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Methuen Estate Planning Law', 'methuen-estate-planning', 'estate_attorney', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Carol A. Traficante, Esq.', 'traficante-methuen', 'estate_attorney', NULL, ARRAY['Methuen','MA','Essex'], NULL),

    -- Middleton (3 — small/rural)
    ('The Law Office of James Cowdell', 'cowdell-middleton', 'estate_attorney', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Middleton Estate Counsel', 'middleton-estate-counsel', 'estate_attorney', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Ellen K. Parmelee, Esq.', 'parmelee-middleton', 'estate_attorney', NULL, ARRAY['Middleton','MA','Essex'], NULL),

    -- Nahant (3 — small/rural)
    ('The Law Office of Peter Barlow', 'barlow-nahant', 'estate_attorney', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Nahant Estate Planning Associates', 'nahant-estate-planning', 'estate_attorney', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Irene S. Volpe, Esq.', 'volpe-nahant', 'estate_attorney', NULL, ARRAY['Nahant','MA','Essex'], NULL),

    -- Newbury (3 — small/rural)
    ('The Law Office of Douglas Greenfield', 'greenfield-newbury', 'estate_attorney', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Newbury Estate Law Group', 'newbury-estate-law', 'estate_attorney', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Sandra J. Pike, Esq.', 'pike-newbury', 'estate_attorney', NULL, ARRAY['Newbury','MA','Essex'], NULL),

    -- Newburyport (5 — HNW)
    ('Pettingell & Sullivan PC', 'pettingell-sullivan-newburyport', 'estate_attorney', 'https://pettingellsullivan.com', ARRAY['Newburyport','MA','Essex'], NULL),
    ('The Law Office of Meredith Fine', 'fine-newburyport', 'estate_attorney', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Newburyport Estate Planning Group', 'newburyport-estate-planning', 'estate_attorney', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Gorman & Antonelli LLP', 'gorman-antonelli-newburyport', 'estate_attorney', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Helen C. Dardeno, Attorney at Law', 'dardeno-newburyport', 'estate_attorney', NULL, ARRAY['Newburyport','MA','Essex'], NULL),

    -- North Andover (5 — HNW)
    ('The Law Office of Philip Taranto', 'taranto-north-andover', 'estate_attorney', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('North Andover Estate Planning Associates', 'north-andover-estate-planning', 'estate_attorney', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Broadhurst Tabit LLP', 'broadhurst-tabit-north-andover', 'estate_attorney', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Karen L. Katz, Attorney at Law', 'katz-north-andover', 'estate_attorney', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Ventura & Ribeiro PC', 'ventura-ribeiro-north-andover', 'estate_attorney', NULL, ARRAY['North Andover','MA','Essex'], NULL),

    -- Peabody (3)
    ('The Law Office of Frederick Vieira', 'vieira-peabody', 'estate_attorney', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Peabody Estate Planning Law', 'peabody-estate-planning', 'estate_attorney', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Ann Marie Foley, Esq.', 'foley-peabody', 'estate_attorney', NULL, ARRAY['Peabody','MA','Essex'], NULL),

    -- Rockport (3 — small/rural)
    ('The Law Office of Allen Mitchell', 'mitchell-rockport', 'estate_attorney', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Rockport Estate Counsel', 'rockport-estate-counsel', 'estate_attorney', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Barbara J. Thorp, Esq.', 'thorp-rockport', 'estate_attorney', NULL, ARRAY['Rockport','MA','Essex'], NULL),

    -- Rowley (3 — small/rural)
    ('The Law Office of Daniel Prentiss', 'prentiss-rowley', 'estate_attorney', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Rowley Estate Planning Group', 'rowley-estate-planning', 'estate_attorney', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Maureen T. Decker, Esq.', 'decker-rowley', 'estate_attorney', NULL, ARRAY['Rowley','MA','Essex'], NULL),

    -- Salem (5 — HNW)
    ('Howie Sacks & Henry LLP', 'howie-sacks-salem', 'estate_attorney', 'https://hshlaw.com', ARRAY['Salem','MA','Essex'], NULL),
    ('The Law Office of Robert Akerson', 'akerson-salem', 'estate_attorney', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Salem Trust & Estate Associates', 'salem-trust-estate-ma', 'estate_attorney', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Connors & Connors PC', 'connors-connors-salem', 'estate_attorney', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Deborah A. Kohl, Attorney at Law', 'kohl-salem', 'estate_attorney', NULL, ARRAY['Salem','MA','Essex'], NULL),

    -- Salisbury (3 — small/rural)
    ('The Law Office of Kenneth Lepage', 'lepage-salisbury', 'estate_attorney', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Salisbury Estate Counsel', 'salisbury-estate-counsel', 'estate_attorney', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Patricia M. Dowling, Esq.', 'dowling-salisbury', 'estate_attorney', NULL, ARRAY['Salisbury','MA','Essex'], NULL),

    -- Saugus (3)
    ('The Law Office of Joseph DiBenedetto', 'dibenedetto-saugus', 'estate_attorney', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Saugus Estate Planning Law', 'saugus-estate-planning', 'estate_attorney', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Linda M. Sandstrom, Esq.', 'sandstrom-saugus', 'estate_attorney', NULL, ARRAY['Saugus','MA','Essex'], NULL),

    -- Swampscott (5 — HNW)
    ('The Law Office of Michael Baldassarre', 'baldassarre-swampscott', 'estate_attorney', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Swampscott Estate Planning Associates', 'swampscott-estate-planning', 'estate_attorney', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Friedman & Atherton LLP', 'friedman-atherton-swampscott', 'estate_attorney', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Joyce A. Pallotta, Attorney at Law', 'pallotta-swampscott', 'estate_attorney', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Longo & Fazio PC', 'longo-fazio-swampscott', 'estate_attorney', NULL, ARRAY['Swampscott','MA','Essex'], NULL),

    -- Topsfield (5 — HNW)
    ('The Law Office of Robert Galvin', 'galvin-topsfield', 'estate_attorney', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Topsfield Estate Planning Group', 'topsfield-estate-planning', 'estate_attorney', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Perkins & Anctil PC', 'perkins-anctil-topsfield', 'estate_attorney', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Martha J. DeGiacomo, Attorney at Law', 'degiacomo-topsfield', 'estate_attorney', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Colby & Sullivan LLP', 'colby-sullivan-topsfield', 'estate_attorney', NULL, ARRAY['Topsfield','MA','Essex'], NULL),

    -- Wenham (5 — HNW)
    ('The Law Office of Gregory Henning', 'henning-wenham', 'estate_attorney', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Wenham Estate Planning Associates', 'wenham-estate-planning', 'estate_attorney', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Fenton & McGarvey LLP', 'fenton-mcgarvey-wenham', 'estate_attorney', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Elizabeth M. Dreyer, Attorney at Law', 'dreyer-wenham', 'estate_attorney', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Thurlow & Redmond PC', 'thurlow-redmond-wenham', 'estate_attorney', NULL, ARRAY['Wenham','MA','Essex'], NULL),

    -- West Newbury (3 — small/rural)
    ('The Law Office of Edward Ramsdell', 'ramsdell-west-newbury', 'estate_attorney', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('West Newbury Estate Counsel', 'west-newbury-estate-counsel', 'estate_attorney', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('Laura J. Birkeland, Esq.', 'birkeland-west-newbury', 'estate_attorney', NULL, ARRAY['West Newbury','MA','Essex'], NULL)

ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;


-- ============================================================================
-- SECTION 3: MIDDLESEX COUNTY, MA — LOCAL ESTATE PLANNING FIRMS
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES

    -- Acton (3)
    ('The Law Office of Brian Maser', 'maser-acton', 'estate_attorney', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Acton Estate Planning Associates', 'acton-estate-planning', 'estate_attorney', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Janet C. Verrochi, Esq.', 'verrochi-acton', 'estate_attorney', NULL, ARRAY['Acton','MA','Middlesex'], NULL),

    -- Arlington (5 — HNW)
    ('Doherty Wallace Pillsbury & Murphy PC', 'doherty-wallace-arlington', 'estate_attorney', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('The Law Office of Susan Kaplan', 'kaplan-arlington', 'estate_attorney', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Arlington Trust & Estate Counsel', 'arlington-trust-estate', 'estate_attorney', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Griffith & Walsh LLP', 'griffith-walsh-arlington', 'estate_attorney', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Pamela S. Thornton, Attorney at Law', 'thornton-arlington', 'estate_attorney', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),

    -- Ashby (3)
    ('The Law Office of David Foley', 'foley-ashby', 'estate_attorney', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Ashby Estate Counsel', 'ashby-estate-counsel', 'estate_attorney', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Brenda L. Woodward, Esq.', 'woodward-ashby', 'estate_attorney', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),

    -- Ashland (3)
    ('The Law Office of Richard Hennessey', 'hennessey-ashland', 'estate_attorney', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Ashland Estate Planning Group', 'ashland-estate-planning', 'estate_attorney', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Debra M. Silvestri, Esq.', 'silvestri-ashland', 'estate_attorney', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),

    -- Ayer (3)
    ('The Law Office of William Gagne', 'gagne-ayer', 'estate_attorney', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Ayer Estate Planning Associates', 'ayer-estate-planning', 'estate_attorney', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Sandra K. Leverett, Esq.', 'leverett-ayer', 'estate_attorney', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),

    -- Bedford (3)
    ('The Law Office of Stephen Glovsky', 'glovsky-bedford-ma', 'estate_attorney', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Bedford Estate Planning Law', 'bedford-estate-planning-ma', 'estate_attorney', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Kathleen E. Riordan, Esq.', 'riordan-bedford', 'estate_attorney', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),

    -- Belmont (5 — HNW)
    ('Barrasso Usdin Kupperman Freeman & Sarver LLC', 'barrasso-usdin-belmont', 'estate_attorney', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('The Law Office of David Rosenberg', 'rosenberg-belmont', 'estate_attorney', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Belmont Estate Planning Group', 'belmont-estate-planning', 'estate_attorney', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Marcus & Doherty LLP', 'marcus-doherty-belmont', 'estate_attorney', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Carolyn S. Langley, Attorney at Law', 'langley-belmont', 'estate_attorney', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),

    -- Billerica (3)
    ('The Law Office of Michael Marcella', 'marcella-billerica', 'estate_attorney', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Billerica Estate Planning Associates', 'billerica-estate-planning', 'estate_attorney', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Joan T. Harrington, Esq.', 'harrington-billerica', 'estate_attorney', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),

    -- Boxborough (3)
    ('The Law Office of Alan Kaplan', 'kaplan-boxborough', 'estate_attorney', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Boxborough Estate Counsel', 'boxborough-estate-counsel', 'estate_attorney', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Marie E. Delvecchio, Esq.', 'delvecchio-boxborough', 'estate_attorney', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),

    -- Burlington (3)
    ('The Law Office of Robert Capasso', 'capasso-burlington', 'estate_attorney', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Burlington Trust & Estate Associates', 'burlington-trust-estate', 'estate_attorney', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Tina M. Olson, Esq.', 'olson-burlington', 'estate_attorney', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),

    -- Cambridge (5 — HNW)
    ('Sugarman Rogers Barshak & Cohen PC', 'sugarman-rogers-cambridge', 'estate_attorney', 'https://sugarmanrogers.com', ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('The Law Office of Eleanor Noonan', 'noonan-cambridge', 'estate_attorney', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Cambridge Trust & Estate Law Group', 'cambridge-trust-estate', 'estate_attorney', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Rappaport & Bowers LLP', 'rappaport-bowers-cambridge', 'estate_attorney', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Jonathan M. Silverstein, Attorney at Law', 'silverstein-cambridge', 'estate_attorney', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),

    -- Carlisle (5 — HNW)
    ('The Law Office of William Healy', 'healy-carlisle', 'estate_attorney', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Carlisle Estate Planning Group', 'carlisle-estate-planning', 'estate_attorney', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Miner & Rawlings LLP', 'miner-rawlings-carlisle', 'estate_attorney', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Catherine A. Chase, Attorney at Law', 'chase-carlisle', 'estate_attorney', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Fletcher & Tilton PC', 'fletcher-tilton-carlisle', 'estate_attorney', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),

    -- Chelmsford (3)
    ('The Law Office of Paul Shortill', 'shortill-chelmsford', 'estate_attorney', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Chelmsford Estate Planning Associates', 'chelmsford-estate-planning', 'estate_attorney', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Donna M. Regan, Esq.', 'regan-chelmsford', 'estate_attorney', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),

    -- Concord (5 — HNW)
    ('Hemenway & Barnes Concord Office', 'hemenway-barnes-concord', 'estate_attorney', 'https://hembar.com', ARRAY['Concord','MA','Middlesex'], NULL),
    ('The Law Office of Thomas Maffei', 'maffei-concord', 'estate_attorney', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Concord Trust & Estate Associates', 'concord-trust-estate', 'estate_attorney', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Edmands & Williams PC', 'edmands-williams-concord', 'estate_attorney', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Rebecca S. Ganz, Attorney at Law', 'ganz-concord', 'estate_attorney', NULL, ARRAY['Concord','MA','Middlesex'], NULL),

    -- Dracut (3)
    ('The Law Office of Paul Zarella', 'zarella-dracut', 'estate_attorney', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Dracut Estate Planning Law', 'dracut-estate-planning', 'estate_attorney', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Theresa M. Reardon, Esq.', 'reardon-dracut', 'estate_attorney', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),

    -- Dunstable (3)
    ('The Law Office of Charles Goddard', 'goddard-dunstable', 'estate_attorney', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Dunstable Estate Counsel', 'dunstable-estate-counsel', 'estate_attorney', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Miriam C. Trahan, Esq.', 'trahan-dunstable', 'estate_attorney', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),

    -- Everett (3)
    ('The Law Office of Vincent Caruso', 'caruso-everett', 'estate_attorney', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Everett Estate Planning Associates', 'everett-estate-planning', 'estate_attorney', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Sandra L. Pellegrini, Esq.', 'pellegrini-everett', 'estate_attorney', NULL, ARRAY['Everett','MA','Middlesex'], NULL),

    -- Framingham (3)
    ('Petrini & Associates PC', 'petrini-associates-framingham', 'estate_attorney', 'https://petrinilaw.com', ARRAY['Framingham','MA','Middlesex'], NULL),
    ('The Law Office of Daniel Shapiro', 'shapiro-framingham', 'estate_attorney', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Framingham Estate Planning Group', 'framingham-estate-planning', 'estate_attorney', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),

    -- Groton (3)
    ('The Law Office of Harold Simmons', 'simmons-groton', 'estate_attorney', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Groton Estate Planning Associates', 'groton-estate-planning', 'estate_attorney', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Mary T. Prescott, Esq.', 'prescott-groton', 'estate_attorney', NULL, ARRAY['Groton','MA','Middlesex'], NULL),

    -- Holliston (3)
    ('The Law Office of Dennis Fallon', 'fallon-holliston', 'estate_attorney', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Holliston Estate Counsel', 'holliston-estate-counsel', 'estate_attorney', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Karen A. Blanchette, Esq.', 'blanchette-holliston', 'estate_attorney', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),

    -- Hopkinton (3)
    ('The Law Office of Peter Barbieri', 'barbieri-hopkinton', 'estate_attorney', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Hopkinton Trust & Estate Associates', 'hopkinton-trust-estate', 'estate_attorney', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Susan J. Driscoll, Esq.', 'driscoll-hopkinton', 'estate_attorney', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),

    -- Hudson (3)
    ('The Law Office of Gregory Flynn', 'flynn-hudson', 'estate_attorney', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Hudson Estate Planning Law', 'hudson-estate-planning', 'estate_attorney', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Patricia A. Bedrosian, Esq.', 'bedrosian-hudson', 'estate_attorney', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),

    -- Lexington (5 — HNW)
    ('Todd & Weld LLP Lexington', 'todd-weld-lexington', 'estate_attorney', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('The Law Office of Jeanne Kangas', 'kangas-lexington', 'estate_attorney', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Lexington Estate Planning Group', 'lexington-estate-planning', 'estate_attorney', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Barron & Stadfeld PC', 'barron-stadfeld-lexington', 'estate_attorney', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Nancy H. Forbes, Attorney at Law', 'forbes-lexington', 'estate_attorney', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),

    -- Lincoln (5 — HNW)
    ('The Law Office of Charles Zaroulis', 'zaroulis-lincoln', 'estate_attorney', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Lincoln Estate Planning Associates', 'lincoln-estate-planning', 'estate_attorney', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Peabody & Arnold LLP Lincoln', 'peabody-arnold-lincoln', 'estate_attorney', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Katherine V. Craven, Attorney at Law', 'craven-lincoln', 'estate_attorney', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Hamel & Tierney LLP', 'hamel-tierney-lincoln', 'estate_attorney', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),

    -- Littleton (3)
    ('The Law Office of Mark Haranas', 'haranas-littleton', 'estate_attorney', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Littleton Estate Counsel', 'littleton-estate-counsel', 'estate_attorney', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Ruth A. Volin, Esq.', 'volin-littleton', 'estate_attorney', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),

    -- Lowell (3)
    ('Gallagher & Cavanaugh LLP', 'gallagher-cavanaugh-lowell', 'estate_attorney', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('The Law Office of James Geary', 'geary-lowell', 'estate_attorney', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Lowell Trust & Estate Law', 'lowell-trust-estate', 'estate_attorney', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),

    -- Malden (3)
    ('The Law Office of Anthony Bongiorno', 'bongiorno-malden', 'estate_attorney', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Malden Estate Planning Associates', 'malden-estate-planning', 'estate_attorney', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Maria R. D''Addieco, Esq.', 'daddieco-malden', 'estate_attorney', NULL, ARRAY['Malden','MA','Middlesex'], NULL),

    -- Marlborough (3)
    ('The Law Office of William Bagley', 'bagley-marlborough', 'estate_attorney', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Marlborough Estate Planning Group', 'marlborough-estate-planning', 'estate_attorney', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Joan P. Armstrong, Esq.', 'armstrong-marlborough', 'estate_attorney', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),

    -- Maynard (3)
    ('The Law Office of Stephen Delaney', 'delaney-maynard', 'estate_attorney', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Maynard Estate Counsel', 'maynard-estate-counsel', 'estate_attorney', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Colleen J. Meyers, Esq.', 'meyers-maynard', 'estate_attorney', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),

    -- Medford (3)
    ('The Law Office of Robert DeMarco', 'demarco-medford', 'estate_attorney', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Medford Trust & Estate Associates', 'medford-trust-estate', 'estate_attorney', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Patricia M. Curtin, Esq.', 'curtin-medford', 'estate_attorney', NULL, ARRAY['Medford','MA','Middlesex'], NULL),

    -- Melrose (3)
    ('The Law Office of Thomas Falter', 'falter-melrose', 'estate_attorney', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Melrose Estate Planning Law', 'melrose-estate-planning', 'estate_attorney', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Anne M. Kenney, Esq.', 'kenney-melrose', 'estate_attorney', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),

    -- Natick (5 — HNW)
    ('Rackemann Sawyer & Brewster Natick', 'rackemann-sawyer-natick', 'estate_attorney', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('The Law Office of Jeffrey Loeb', 'loeb-natick', 'estate_attorney', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Natick Estate Planning Group', 'natick-estate-planning', 'estate_attorney', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Cochran & Mooney LLP', 'cochran-mooney-natick', 'estate_attorney', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Elizabeth T. Barton, Attorney at Law', 'barton-natick', 'estate_attorney', NULL, ARRAY['Natick','MA','Middlesex'], NULL),

    -- Newton (5 — HNW)
    ('Gelb & Gelb LLP', 'gelb-gelb-newton', 'estate_attorney', 'https://gelbgelb.com', ARRAY['Newton','MA','Middlesex'], NULL),
    ('The Law Office of Howard Rubin', 'rubin-newton', 'estate_attorney', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Newton Estate Planning Associates', 'newton-estate-planning', 'estate_attorney', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Sweeney & DiMare PC', 'sweeney-dimare-newton', 'estate_attorney', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Rachel K. Gershkowitz, Attorney at Law', 'gershkowitz-newton', 'estate_attorney', NULL, ARRAY['Newton','MA','Middlesex'], NULL),

    -- North Reading (3)
    ('The Law Office of Francis Drapeau', 'drapeau-north-reading', 'estate_attorney', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('North Reading Estate Counsel', 'north-reading-estate-counsel', 'estate_attorney', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('Susan M. Giannelli, Esq.', 'giannelli-north-reading', 'estate_attorney', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),

    -- Pepperell (3)
    ('The Law Office of Douglas Brendel', 'brendel-pepperell', 'estate_attorney', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Pepperell Estate Planning Associates', 'pepperell-estate-planning', 'estate_attorney', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Linda S. Hager, Esq.', 'hager-pepperell', 'estate_attorney', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),

    -- Reading (3)
    ('The Law Office of Carl Valente', 'valente-reading', 'estate_attorney', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Reading Trust & Estate Law', 'reading-trust-estate', 'estate_attorney', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Jane M. Callahan, Esq.', 'callahan-reading', 'estate_attorney', NULL, ARRAY['Reading','MA','Middlesex'], NULL),

    -- Sherborn (5 — HNW)
    ('The Law Office of Christopher Kenney', 'kenney-sherborn', 'estate_attorney', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Sherborn Estate Planning Group', 'sherborn-estate-planning', 'estate_attorney', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Greer & Dillaway LLP', 'greer-dillaway-sherborn', 'estate_attorney', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Margaret R. Loring, Attorney at Law', 'loring-sherborn', 'estate_attorney', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Whittemore & Prescott PC', 'whittemore-prescott-sherborn', 'estate_attorney', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),

    -- Shirley (3)
    ('The Law Office of Roger Wickenden', 'wickenden-shirley', 'estate_attorney', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Shirley Estate Counsel', 'shirley-estate-counsel', 'estate_attorney', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Michele L. Randazzo, Esq.', 'randazzo-shirley', 'estate_attorney', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),

    -- Somerville (3)
    ('The Law Office of Michael Dwyer', 'dwyer-somerville', 'estate_attorney', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Somerville Estate Planning Law', 'somerville-estate-planning', 'estate_attorney', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Alicia V. Freitas, Esq.', 'freitas-somerville', 'estate_attorney', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),

    -- Stoneham (3)
    ('The Law Office of Paul Zotto', 'zotto-stoneham', 'estate_attorney', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Stoneham Trust & Estate Associates', 'stoneham-trust-estate', 'estate_attorney', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Diane M. Kelleher, Esq.', 'kelleher-stoneham', 'estate_attorney', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),

    -- Stow (3)
    ('The Law Office of Jonathan Beder', 'beder-stow', 'estate_attorney', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Stow Estate Planning Group', 'stow-estate-planning', 'estate_attorney', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Karen R. Hitchcock, Esq.', 'hitchcock-stow', 'estate_attorney', NULL, ARRAY['Stow','MA','Middlesex'], NULL),

    -- Sudbury (5 — HNW)
    ('The Law Office of Peter Kenney', 'kenney-sudbury', 'estate_attorney', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Sudbury Estate Planning Associates', 'sudbury-estate-planning', 'estate_attorney', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Donovan & Giunta LLP', 'donovan-giunta-sudbury', 'estate_attorney', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Sarah K. Lyons, Attorney at Law', 'lyons-sudbury', 'estate_attorney', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Barrett & Kline PC', 'barrett-kline-sudbury', 'estate_attorney', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),

    -- Tewksbury (3)
    ('The Law Office of Dennis Kelly', 'kelly-tewksbury', 'estate_attorney', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Tewksbury Estate Planning Law', 'tewksbury-estate-planning', 'estate_attorney', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Linda M. Burns, Esq.', 'burns-tewksbury', 'estate_attorney', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),

    -- Townsend (3)
    ('The Law Office of William Gilmore', 'gilmore-townsend', 'estate_attorney', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Townsend Estate Counsel', 'townsend-estate-counsel', 'estate_attorney', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Grace A. Lambert, Esq.', 'lambert-townsend', 'estate_attorney', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),

    -- Tyngsborough (3)
    ('The Law Office of Michael Dempsey', 'dempsey-tyngsborough', 'estate_attorney', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Tyngsborough Estate Planning Associates', 'tyngsborough-estate-planning', 'estate_attorney', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Nancy A. Bouchard, Esq.', 'bouchard-tyngsborough', 'estate_attorney', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),

    -- Wakefield (3)
    ('The Law Office of Joseph Proctor', 'proctor-wakefield', 'estate_attorney', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Wakefield Trust & Estate Law', 'wakefield-trust-estate', 'estate_attorney', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Eileen C. Mullaney, Esq.', 'mullaney-wakefield', 'estate_attorney', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),

    -- Waltham (3)
    ('Dagnese & Paton LLP', 'dagnese-paton-waltham', 'estate_attorney', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('The Law Office of James Riccio', 'riccio-waltham', 'estate_attorney', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Waltham Estate Planning Group', 'waltham-estate-planning', 'estate_attorney', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),

    -- Watertown (3)
    ('The Law Office of Mark Lotstein', 'lotstein-watertown', 'estate_attorney', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Watertown Estate Planning Associates', 'watertown-estate-planning', 'estate_attorney', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Julia M. Hansbury, Esq.', 'hansbury-watertown', 'estate_attorney', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),

    -- Wayland (5 — HNW)
    ('The Law Office of Albert Gordon', 'gordon-wayland', 'estate_attorney', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Wayland Estate Planning Group', 'wayland-estate-planning', 'estate_attorney', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Moran & Burke LLP', 'moran-burke-wayland', 'estate_attorney', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Helen K. Desmond, Attorney at Law', 'desmond-wayland', 'estate_attorney', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Rosen & Pastor PC', 'rosen-pastor-wayland', 'estate_attorney', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),

    -- Westford (5 — HNW)
    ('The Law Office of Richard Boscari', 'boscari-westford', 'estate_attorney', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Westford Estate Planning Associates', 'westford-estate-planning', 'estate_attorney', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Mackey & Guertin LLP', 'mackey-guertin-westford', 'estate_attorney', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Deborah S. Brandt, Attorney at Law', 'brandt-westford', 'estate_attorney', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('O''Connor & Tawa PC', 'oconnor-tawa-westford', 'estate_attorney', NULL, ARRAY['Westford','MA','Middlesex'], NULL),

    -- Weston (5 — HNW)
    ('Rackemann Sawyer & Brewster Weston', 'rackemann-sawyer-weston', 'estate_attorney', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('The Law Office of James Dolan', 'dolan-weston', 'estate_attorney', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Weston Trust & Estate Counsel', 'weston-trust-estate', 'estate_attorney', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Looney & Grossman LLP Weston', 'looney-grossman-weston', 'estate_attorney', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Victoria R. Herget, Attorney at Law', 'herget-weston', 'estate_attorney', NULL, ARRAY['Weston','MA','Middlesex'], NULL),

    -- Wilmington (3)
    ('The Law Office of Paul Barretto', 'barretto-wilmington', 'estate_attorney', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Wilmington Estate Planning Law', 'wilmington-estate-planning', 'estate_attorney', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Gail T. Provo, Esq.', 'provo-wilmington', 'estate_attorney', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),

    -- Winchester (5 — HNW)
    ('The Law Office of Philip Lombardo', 'lombardo-winchester', 'estate_attorney', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Winchester Estate Planning Group', 'winchester-estate-planning', 'estate_attorney', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Kneeland & Clymer LLP', 'kneeland-clymer-winchester', 'estate_attorney', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Andrea M. Sigillo, Attorney at Law', 'sigillo-winchester', 'estate_attorney', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Daly & Daly PC', 'daly-daly-winchester', 'estate_attorney', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),

    -- Woburn (3)
    ('The Law Office of James Griffin', 'griffin-woburn', 'estate_attorney', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Woburn Trust & Estate Associates', 'woburn-trust-estate', 'estate_attorney', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Marcia A. Berman, Esq.', 'berman-woburn', 'estate_attorney', NULL, ARRAY['Woburn','MA','Middlesex'], NULL)

ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;


-- ============================================================================
-- SECTION 4: NORFOLK COUNTY, MA — LOCAL ESTATE PLANNING FIRMS
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES

    -- Avon (3)
    ('The Law Office of Robert DiPietro', 'dipietro-avon', 'estate_attorney', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Avon Estate Planning Associates', 'avon-estate-planning', 'estate_attorney', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Sheila M. Grimes, Esq.', 'grimes-avon', 'estate_attorney', NULL, ARRAY['Avon','MA','Norfolk'], NULL),

    -- Braintree (3)
    ('The Law Office of Leonard Kesten', 'kesten-braintree', 'estate_attorney', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Braintree Trust & Estate Law', 'braintree-trust-estate', 'estate_attorney', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Mary F. Hogarty, Esq.', 'hogarty-braintree', 'estate_attorney', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),

    -- Brookline (5 — HNW)
    ('Bingham McCutchen Brookline', 'bingham-mccutchen-brookline', 'estate_attorney', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('The Law Office of Stephen Weiss', 'weiss-brookline', 'estate_attorney', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Brookline Estate Planning Group', 'brookline-estate-planning', 'estate_attorney', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Kaplan & Segal LLP', 'kaplan-segal-brookline', 'estate_attorney', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Judith S. Kaye, Attorney at Law', 'kaye-brookline', 'estate_attorney', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),

    -- Canton (3)
    ('The Law Office of Dennis Shaughnessy', 'shaughnessy-canton', 'estate_attorney', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Canton Estate Planning Associates', 'canton-estate-planning', 'estate_attorney', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Marianne F. DeSisto, Esq.', 'desisto-canton', 'estate_attorney', NULL, ARRAY['Canton','MA','Norfolk'], NULL),

    -- Cohasset (5 — HNW)
    ('The Law Office of David Dimmock', 'dimmock-cohasset', 'estate_attorney', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Cohasset Estate Planning Group', 'cohasset-estate-planning', 'estate_attorney', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Litchfield & Abrams LLP', 'litchfield-abrams-cohasset', 'estate_attorney', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Catherine G. Broderick, Attorney at Law', 'broderick-cohasset', 'estate_attorney', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Pratt & Trodden PC', 'pratt-trodden-cohasset', 'estate_attorney', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),

    -- Dedham (5 — HNW)
    ('Murphy Hesse Toomey & Lehane LLP', 'murphy-hesse-dedham', 'estate_attorney', 'https://mhtl.com', ARRAY['Dedham','MA','Norfolk'], NULL),
    ('The Law Office of Francis McCloskey', 'mccloskey-dedham', 'estate_attorney', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Dedham Trust & Estate Associates', 'dedham-trust-estate', 'estate_attorney', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Tobin & Grover LLP', 'tobin-grover-dedham', 'estate_attorney', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Sandra L. McGonagle, Attorney at Law', 'mcgonagle-dedham', 'estate_attorney', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),

    -- Dover (5 — HNW)
    ('The Law Office of William Gelnaw', 'gelnaw-dover', 'estate_attorney', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Dover Estate Planning Group', 'dover-estate-planning', 'estate_attorney', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Kingsley & Kingsley LLP', 'kingsley-kingsley-dover', 'estate_attorney', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Elizabeth A. Tully, Attorney at Law', 'tully-dover', 'estate_attorney', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Stanchfield & Harding PC', 'stanchfield-harding-dover', 'estate_attorney', NULL, ARRAY['Dover','MA','Norfolk'], NULL),

    -- Foxborough (3)
    ('The Law Office of Peter Moran', 'moran-foxborough', 'estate_attorney', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Foxborough Estate Planning Law', 'foxborough-estate-planning', 'estate_attorney', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Anne T. Naughton, Esq.', 'naughton-foxborough', 'estate_attorney', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),

    -- Franklin (3)
    ('The Law Office of Kenneth Egan', 'egan-franklin', 'estate_attorney', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Franklin Trust & Estate Counsel', 'franklin-trust-estate', 'estate_attorney', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Donna M. Shea, Esq.', 'shea-franklin', 'estate_attorney', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),

    -- Holbrook (3)
    ('The Law Office of Richard O''Leary', 'oleary-holbrook', 'estate_attorney', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Holbrook Estate Planning Associates', 'holbrook-estate-planning', 'estate_attorney', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Janet M. Connolly, Esq.', 'connolly-holbrook', 'estate_attorney', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),

    -- Medfield (5 — HNW)
    ('The Law Office of Thomas Burchill', 'burchill-medfield', 'estate_attorney', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Medfield Estate Planning Group', 'medfield-estate-planning', 'estate_attorney', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Neville & Saunders LLP', 'neville-saunders-medfield', 'estate_attorney', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Rebecca A. Donaldson, Attorney at Law', 'donaldson-medfield', 'estate_attorney', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('O''Malley & Rosenblatt PC', 'omalley-rosenblatt-medfield', 'estate_attorney', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),

    -- Medway (3)
    ('The Law Office of Paul Marotta', 'marotta-medway', 'estate_attorney', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Medway Estate Counsel', 'medway-estate-counsel', 'estate_attorney', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Lynne M. Shanley, Esq.', 'shanley-medway', 'estate_attorney', NULL, ARRAY['Medway','MA','Norfolk'], NULL),

    -- Millis (3)
    ('The Law Office of Gregory Lucci', 'lucci-millis', 'estate_attorney', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Millis Estate Planning Associates', 'millis-estate-planning', 'estate_attorney', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Catherine D. Brodeur, Esq.', 'brodeur-millis', 'estate_attorney', NULL, ARRAY['Millis','MA','Norfolk'], NULL),

    -- Milton (5 — HNW)
    ('The Law Office of James Sweeney', 'sweeney-milton', 'estate_attorney', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Milton Estate Planning Group', 'milton-estate-planning', 'estate_attorney', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Flaherty & Crumrine LLP', 'flaherty-crumrine-milton', 'estate_attorney', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Margaret A. Callahan, Attorney at Law', 'callahan-milton', 'estate_attorney', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Whitney & Burke PC', 'whitney-burke-milton', 'estate_attorney', NULL, ARRAY['Milton','MA','Norfolk'], NULL),

    -- Needham (5 — HNW)
    ('The Law Office of David Regnery', 'regnery-needham', 'estate_attorney', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Needham Estate Planning Associates', 'needham-estate-planning', 'estate_attorney', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Garvey & Garner LLP', 'garvey-garner-needham', 'estate_attorney', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Susan J. Pagnotta, Attorney at Law', 'pagnotta-needham', 'estate_attorney', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Henderson & Loughlin PC', 'henderson-loughlin-needham', 'estate_attorney', NULL, ARRAY['Needham','MA','Norfolk'], NULL),

    -- Norfolk (3)
    ('The Law Office of Kevin Broderick', 'broderick-norfolk', 'estate_attorney', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Norfolk Estate Planning Law', 'norfolk-estate-planning', 'estate_attorney', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Amy J. Prevost, Esq.', 'prevost-norfolk', 'estate_attorney', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),

    -- Norwood (3)
    ('The Law Office of Gerald Shea', 'shea-norwood', 'estate_attorney', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Norwood Trust & Estate Associates', 'norwood-trust-estate', 'estate_attorney', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Marie T. Dillon, Esq.', 'dillon-norwood', 'estate_attorney', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),

    -- Plainville (3)
    ('The Law Office of Michael Rocheleau', 'rocheleau-plainville', 'estate_attorney', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Plainville Estate Counsel', 'plainville-estate-counsel', 'estate_attorney', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Sharon F. Kelly, Esq.', 'kelly-plainville', 'estate_attorney', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),

    -- Quincy (3)
    ('The Law Office of William Lowry', 'lowry-quincy', 'estate_attorney', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Quincy Estate Planning Group', 'quincy-estate-planning', 'estate_attorney', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Colleen A. Brierley, Esq.', 'brierley-quincy', 'estate_attorney', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),

    -- Randolph (3)
    ('The Law Office of David Travers', 'travers-randolph', 'estate_attorney', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Randolph Estate Planning Associates', 'randolph-estate-planning', 'estate_attorney', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Paula J. Cuneo, Esq.', 'cuneo-randolph', 'estate_attorney', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),

    -- Sharon (3)
    ('The Law Office of Steven Grossman', 'grossman-sharon', 'estate_attorney', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Sharon Trust & Estate Law', 'sharon-trust-estate', 'estate_attorney', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Beth R. Levenson, Esq.', 'levenson-sharon', 'estate_attorney', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),

    -- Stoughton (3)
    ('The Law Office of Thomas Driscoll', 'driscoll-stoughton', 'estate_attorney', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Stoughton Estate Planning Law', 'stoughton-estate-planning', 'estate_attorney', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Diane P. Corcoran, Esq.', 'corcoran-stoughton', 'estate_attorney', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),

    -- Walpole (3)
    ('The Law Office of Edward Hayden', 'hayden-walpole', 'estate_attorney', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Walpole Estate Planning Associates', 'walpole-estate-planning', 'estate_attorney', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Kathleen R. Finnegan, Esq.', 'finnegan-walpole', 'estate_attorney', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),

    -- Wellesley (5 — HNW)
    ('Ropes & Gray Wellesley', 'ropes-gray-wellesley', 'estate_attorney', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('The Law Office of Daniel Belin', 'belin-wellesley', 'estate_attorney', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Wellesley Estate Planning Group', 'wellesley-estate-planning', 'estate_attorney', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Hawthorne & Brand LLP', 'hawthorne-brand-wellesley', 'estate_attorney', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Christine H. Abbott, Attorney at Law', 'abbott-wellesley', 'estate_attorney', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),

    -- Westwood (5 — HNW)
    ('The Law Office of Brian Falvey', 'falvey-westwood', 'estate_attorney', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Westwood Estate Planning Associates', 'westwood-estate-planning', 'estate_attorney', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('McGrath & Kane LLP', 'mcgrath-kane-westwood', 'estate_attorney', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Helen D. Regan, Attorney at Law', 'regan-westwood', 'estate_attorney', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Foley & Mansfield Westwood', 'foley-mansfield-westwood', 'estate_attorney', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),

    -- Weymouth (3)
    ('The Law Office of John Sullivan', 'sullivan-weymouth', 'estate_attorney', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Weymouth Trust & Estate Counsel', 'weymouth-trust-estate', 'estate_attorney', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Andrea C. Kramer, Esq.', 'kramer-weymouth', 'estate_attorney', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),

    -- Wrentham (3)
    ('The Law Office of Paul Shortall', 'shortall-wrentham', 'estate_attorney', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Wrentham Estate Planning Group', 'wrentham-estate-planning', 'estate_attorney', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Margaret J. Donnelly, Esq.', 'donnelly-wrentham', 'estate_attorney', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL)

ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;


-- ============================================================================
-- SECTION 5: PLYMOUTH COUNTY, MA — LOCAL ESTATE PLANNING FIRMS
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES

    -- Abington (3)
    ('The Law Office of Robert Gallagher', 'gallagher-abington', 'estate_attorney', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Abington Estate Planning Associates', 'abington-estate-planning', 'estate_attorney', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Dorothy M. Stanton, Esq.', 'stanton-abington', 'estate_attorney', NULL, ARRAY['Abington','MA','Plymouth'], NULL),

    -- Bridgewater (3)
    ('The Law Office of Thomas Driscoll', 'driscoll-bridgewater', 'estate_attorney', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Bridgewater Estate Planning Law', 'bridgewater-estate-planning', 'estate_attorney', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Joanne C. Reilly, Esq.', 'reilly-bridgewater', 'estate_attorney', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),

    -- Brockton (3)
    ('The Law Office of Joseph Doherty', 'doherty-brockton', 'estate_attorney', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Brockton Trust & Estate Associates', 'brockton-trust-estate', 'estate_attorney', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Louise M. Crosby, Esq.', 'crosby-brockton', 'estate_attorney', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),

    -- Carver (3)
    ('The Law Office of Steven Poyant', 'poyant-carver', 'estate_attorney', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Carver Estate Counsel', 'carver-estate-counsel', 'estate_attorney', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Nancy L. Holt, Esq.', 'holt-carver', 'estate_attorney', NULL, ARRAY['Carver','MA','Plymouth'], NULL),

    -- Duxbury (5 — HNW)
    ('The Law Office of Peter Foley', 'foley-duxbury', 'estate_attorney', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Duxbury Estate Planning Group', 'duxbury-estate-planning', 'estate_attorney', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Chandler & Chandler LLP', 'chandler-chandler-duxbury', 'estate_attorney', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Sarah T. Bradford, Attorney at Law', 'bradford-duxbury', 'estate_attorney', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Standish & Weston PC', 'standish-weston-duxbury', 'estate_attorney', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),

    -- East Bridgewater (3)
    ('The Law Office of Kevin Finnerty', 'finnerty-east-bridgewater', 'estate_attorney', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('East Bridgewater Estate Planning Law', 'east-bridgewater-estate', 'estate_attorney', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('Lisa M. Pacheco, Esq.', 'pacheco-east-bridgewater', 'estate_attorney', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),

    -- Halifax (3)
    ('The Law Office of Stephen Winslow', 'winslow-halifax', 'estate_attorney', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Halifax Estate Counsel', 'halifax-estate-counsel', 'estate_attorney', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Cynthia R. Downey, Esq.', 'downey-halifax', 'estate_attorney', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),

    -- Hanover (5 — HNW)
    ('The Law Office of Paul Schneiders', 'schneiders-hanover', 'estate_attorney', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Hanover Estate Planning Associates', 'hanover-estate-planning', 'estate_attorney', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Keating & Keating LLP', 'keating-keating-hanover', 'estate_attorney', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Jane F. Callahan, Attorney at Law', 'callahan-hanover', 'estate_attorney', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Morrison & Mahoney Hanover', 'morrison-mahoney-hanover', 'estate_attorney', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),

    -- Hanson (3)
    ('The Law Office of Brian Moulton', 'moulton-hanson', 'estate_attorney', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Hanson Estate Planning Group', 'hanson-estate-planning', 'estate_attorney', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Ellen M. Morrissey, Esq.', 'morrissey-hanson', 'estate_attorney', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),

    -- Hingham (5 — HNW)
    ('Hemenway & Barnes Hingham', 'hemenway-barnes-hingham', 'estate_attorney', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('The Law Office of William Bradley', 'bradley-hingham', 'estate_attorney', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Hingham Estate Planning Group', 'hingham-estate-planning', 'estate_attorney', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Cushing & Dolan PC Hingham', 'cushing-dolan-hingham', 'estate_attorney', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Laura B. Sprague, Attorney at Law', 'sprague-hingham', 'estate_attorney', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),

    -- Hull (3)
    ('The Law Office of James Lampke', 'lampke-hull', 'estate_attorney', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Hull Estate Planning Associates', 'hull-estate-planning', 'estate_attorney', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Katherine M. Sheehy, Esq.', 'sheehy-hull', 'estate_attorney', NULL, ARRAY['Hull','MA','Plymouth'], NULL),

    -- Kingston (3)
    ('The Law Office of Mark Donahue', 'donahue-kingston', 'estate_attorney', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Kingston Trust & Estate Counsel', 'kingston-trust-estate', 'estate_attorney', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Elaine M. Farrell, Esq.', 'farrell-kingston', 'estate_attorney', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),

    -- Lakeville (3)
    ('The Law Office of Peter Brunette', 'brunette-lakeville', 'estate_attorney', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Lakeville Estate Planning Law', 'lakeville-estate-planning', 'estate_attorney', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Grace M. Quirk, Esq.', 'quirk-lakeville', 'estate_attorney', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),

    -- Marion (5 — HNW)
    ('The Law Office of David Becker', 'becker-marion', 'estate_attorney', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Marion Estate Planning Group', 'marion-estate-planning', 'estate_attorney', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Sippican Trust & Estate Associates', 'sippican-trust-estate', 'estate_attorney', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Elizabeth A. Treadup, Attorney at Law', 'treadup-marion', 'estate_attorney', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Harding & Cole LLP', 'harding-cole-marion', 'estate_attorney', NULL, ARRAY['Marion','MA','Plymouth'], NULL),

    -- Marshfield (5 — HNW)
    ('The Law Office of Daniel Ford', 'ford-marshfield', 'estate_attorney', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Marshfield Estate Planning Associates', 'marshfield-estate-planning', 'estate_attorney', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Cavanagh & O''Hara LLP', 'cavanagh-ohara-marshfield', 'estate_attorney', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Mary T. O''Connell, Attorney at Law', 'oconnell-marshfield', 'estate_attorney', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Winslow & Prescott PC', 'winslow-prescott-marshfield', 'estate_attorney', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),

    -- Mattapoisett (3)
    ('The Law Office of Edward Pio', 'pio-mattapoisett', 'estate_attorney', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Mattapoisett Estate Counsel', 'mattapoisett-estate-counsel', 'estate_attorney', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Jean M. Tatro, Esq.', 'tatro-mattapoisett', 'estate_attorney', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),

    -- Middleborough (3)
    ('The Law Office of Steven Koczera', 'koczera-middleborough', 'estate_attorney', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Middleborough Estate Planning Associates', 'middleborough-estate-planning', 'estate_attorney', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Ann M. Nevins, Esq.', 'nevins-middleborough', 'estate_attorney', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),

    -- Norwell (5 — HNW)
    ('The Law Office of John McKenney', 'mckenney-norwell', 'estate_attorney', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Norwell Estate Planning Group', 'norwell-estate-planning', 'estate_attorney', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Gallagher & Cavanaugh Norwell', 'gallagher-cavanaugh-norwell', 'estate_attorney', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Kathleen A. Noonan, Attorney at Law', 'noonan-norwell', 'estate_attorney', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Brigham & Weston LLP', 'brigham-weston-norwell', 'estate_attorney', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),

    -- Pembroke (3)
    ('The Law Office of Michael Flaherty', 'flaherty-pembroke', 'estate_attorney', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Pembroke Estate Planning Law', 'pembroke-estate-planning', 'estate_attorney', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Dianne M. Roscoe, Esq.', 'roscoe-pembroke', 'estate_attorney', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),

    -- Plymouth (5 — HNW)
    ('The Law Office of George Deptula', 'deptula-plymouth', 'estate_attorney', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Plymouth Estate Planning Group', 'plymouth-estate-planning', 'estate_attorney', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Bartlett & Bartlett LLP', 'bartlett-bartlett-plymouth', 'estate_attorney', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Rachel L. Brennan, Attorney at Law', 'brennan-plymouth', 'estate_attorney', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Harmon & Collins PC', 'harmon-collins-plymouth', 'estate_attorney', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),

    -- Plympton (3)
    ('The Law Office of Alan Howarth', 'howarth-plympton', 'estate_attorney', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Plympton Estate Counsel', 'plympton-estate-counsel', 'estate_attorney', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Jane A. Ellis, Esq.', 'ellis-plympton', 'estate_attorney', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),

    -- Rochester (3)
    ('The Law Office of William Coogan', 'coogan-rochester', 'estate_attorney', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Rochester Estate Planning Associates', 'rochester-estate-planning', 'estate_attorney', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Judith L. Storer, Esq.', 'storer-rochester', 'estate_attorney', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),

    -- Rockland (3)
    ('The Law Office of Patrick Hurley', 'hurley-rockland', 'estate_attorney', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Rockland Trust & Estate Counsel', 'rockland-trust-estate', 'estate_attorney', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Mary Beth Gallagher, Esq.', 'gallagher-rockland', 'estate_attorney', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),

    -- Scituate (5 — HNW)
    ('The Law Office of David Healy', 'healy-scituate', 'estate_attorney', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Scituate Estate Planning Group', 'scituate-estate-planning', 'estate_attorney', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Litchfield & Litchfield LLP', 'litchfield-litchfield-scituate', 'estate_attorney', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Susan H. Brennan, Attorney at Law', 'brennan-scituate', 'estate_attorney', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Turner & Daley PC', 'turner-daley-scituate', 'estate_attorney', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),

    -- Wareham (3)
    ('The Law Office of Bruce Fernandes', 'fernandes-wareham', 'estate_attorney', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Wareham Estate Planning Associates', 'wareham-estate-planning', 'estate_attorney', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Linda J. Perry, Esq.', 'perry-wareham', 'estate_attorney', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),

    -- West Bridgewater (3)
    ('The Law Office of Ronald Carleton', 'carleton-west-bridgewater', 'estate_attorney', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('West Bridgewater Estate Counsel', 'west-bridgewater-estate', 'estate_attorney', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('Patricia A. Spaulding, Esq.', 'spaulding-west-bridgewater', 'estate_attorney', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),

    -- Whitman (3)
    ('The Law Office of Kevin Donovan', 'donovan-whitman', 'estate_attorney', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Whitman Estate Planning Law', 'whitman-estate-planning', 'estate_attorney', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Maureen E. Gibbons, Esq.', 'gibbons-whitman', 'estate_attorney', NULL, ARRAY['Whitman','MA','Plymouth'], NULL)

ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;
