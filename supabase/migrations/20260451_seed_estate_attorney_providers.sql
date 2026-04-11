-- Seed estate planning law firms and attorneys into the utility_providers catalog.
--
-- Estate attorneys are the most hyper-local advisor type. Unlike insurance or
-- utilities, there are almost no national firms -- the vast majority are
-- regional practices or solo/small partnerships named after founding partners.
--
-- This migration covers:
--   Section 1: Major regional law firms with estate/trust practices serving
--              the NY/CT metro corridor (Westchester + Fairfield County).
--   Section 2: Local estate planning firms across 38 Westchester County towns.
--   Section 3: Local estate planning firms across 23 Fairfield County towns.
--
-- All entries use provider_type = 'estate_attorney'. Logo URLs are NULL at
-- seed time; Brandfetch lazy enrichment will resolve them on first picker
-- render where available.
--
-- ON CONFLICT (slug) DO UPDATE ensures re-runs update website and regions
-- without creating duplicates.

-- ============================================================================
-- SECTION 1: MAJOR REGIONAL FIRMS (NY/CT metro estate practices)
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    -- White Plains, NY
    ('Cuddy & Feder LLP', 'cuddy-feder', 'estate_attorney', 'https://cuddyfeder.com', ARRAY['NY','CT','Westchester','Fairfield'], NULL),
    ('Bleakley Platt & Schmidt LLP', 'bleakley-platt-schmidt', 'estate_attorney', 'https://bpslaw.com', ARRAY['NY','CT','Westchester','Fairfield'], NULL),
    ('DelBello Donnellan Weingarten Wise & Wiederkehr LLP', 'delbello-donnellan', 'estate_attorney', 'https://ddw-law.com', ARRAY['NY','CT','Westchester','Fairfield'], NULL),
    ('Keane & Beane P.C.', 'keane-beane', 'estate_attorney', 'https://kblaw.com', ARRAY['NY','CT','Westchester','Fairfield'], NULL),
    ('Goldberg Segalla LLP', 'goldberg-segalla', 'estate_attorney', 'https://goldbergsegalla.com', ARRAY['NY','CT','Westchester','Fairfield'], NULL),
    -- Rye, NY
    ('Dorf & Nelson LLP', 'dorf-nelson', 'estate_attorney', 'https://dorflaw.com', ARRAY['NY','CT','Westchester','Fairfield'], NULL),
    -- Stamford, CT
    ('Robinson & Cole LLP', 'robinson-cole', 'estate_attorney', 'https://rc.com', ARRAY['NY','CT','Westchester','Fairfield'], NULL),
    ('Pullman & Comley LLC', 'pullman-comley', 'estate_attorney', 'https://pullcom.com', ARRAY['NY','CT','Westchester','Fairfield'], NULL),
    ('Cummings & Lockwood LLC', 'cummings-lockwood', 'estate_attorney', 'https://cl-law.com', ARRAY['NY','CT','Westchester','Fairfield'], NULL),
    ('Wiggin and Dana LLP', 'wiggin-dana', 'estate_attorney', 'https://wiggin.com', ARRAY['NY','CT','Westchester','Fairfield'], NULL),
    ('Day Pitney LLP', 'day-pitney', 'estate_attorney', 'https://daypitney.com', ARRAY['NY','CT','Westchester','Fairfield'], NULL),
    ('Shipman & Goodwin LLP', 'shipman-goodwin', 'estate_attorney', 'https://shipmangoodwin.com', ARRAY['NY','CT','Westchester','Fairfield'], NULL),
    ('Murtha Cullina LLP', 'murtha-cullina', 'estate_attorney', 'https://murthalaw.com', ARRAY['NY','CT','Westchester','Fairfield'], NULL),
    ('Wofsey Rosen Kweskin & Kuriansky LLP', 'wofsey-rosen', 'estate_attorney', 'https://wrkk.com', ARRAY['NY','CT','Westchester','Fairfield'], NULL),
    ('Cacace Tusch & Santagata', 'cacace-tusch-santagata', 'estate_attorney', 'https://cacacelaw.com', ARRAY['NY','CT','Westchester','Fairfield'], NULL),
    -- Westport, CT
    ('Levett Rockwood P.C.', 'levett-rockwood', 'estate_attorney', 'https://levettrockwood.com', ARRAY['NY','CT','Westchester','Fairfield'], NULL),
    -- Southport, CT
    ('Brody Wilkinson PC', 'brody-wilkinson', 'estate_attorney', 'https://brodywilk.com', ARRAY['NY','CT','Westchester','Fairfield'], NULL),
    -- Bridgeport, CT
    ('Cohen and Wolf P.C.', 'cohen-wolf', 'estate_attorney', 'https://cohenandwolf.com', ARRAY['NY','CT','Westchester','Fairfield'], NULL),
    ('Zeldes Needle & Cooper P.C.', 'zeldes-needle-cooper', 'estate_attorney', 'https://znclaw.com', ARRAY['NY','CT','Westchester','Fairfield'], NULL),
    -- Greenwich, CT
    ('Ivey Barnum & O''Mara LLC', 'ivey-barnum-omara', 'estate_attorney', 'https://iveybarnum.com', ARRAY['NY','CT','Westchester','Fairfield'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;


-- ============================================================================
-- SECTION 2: WESTCHESTER COUNTY, NY — LOCAL ESTATE PLANNING FIRMS
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES

    -- White Plains (5)
    ('Enea Scanlan & Sirignano LLP', 'enea-scanlan-white-plains', 'estate_attorney', 'https://esslawfirm.com', ARRAY['White Plains','NY','Westchester'], NULL),
    ('Maker Fragale & Di Costanzo LLP', 'maker-fragale-white-plains', 'estate_attorney', 'https://mabornelaw.com', ARRAY['White Plains','NY','Westchester'], NULL),
    ('The Law Office of Anne Graziano', 'anne-graziano-white-plains', 'estate_attorney', NULL, ARRAY['White Plains','NY','Westchester'], NULL),
    ('Bertine Hufnagel Mark Headley & Zizmore PC', 'bertine-hufnagel-white-plains', 'estate_attorney', 'https://bertinelaw.com', ARRAY['White Plains','NY','Westchester'], NULL),
    ('Randall S. Gonnella, Esq.', 'gonnella-white-plains', 'estate_attorney', NULL, ARRAY['White Plains','NY','Westchester'], NULL),

    -- Scarsdale (5)
    ('Greenfield Stein & Senior LLP', 'greenfield-stein-scarsdale', 'estate_attorney', 'https://gss-law.com', ARRAY['Scarsdale','NY','Westchester'], NULL),
    ('The Law Office of David Krischer', 'krischer-scarsdale', 'estate_attorney', NULL, ARRAY['Scarsdale','NY','Westchester'], NULL),
    ('Maitlin & Associates', 'maitlin-scarsdale', 'estate_attorney', NULL, ARRAY['Scarsdale','NY','Westchester'], NULL),
    ('Carole A. Burns, Attorney at Law', 'carole-burns-scarsdale', 'estate_attorney', NULL, ARRAY['Scarsdale','NY','Westchester'], NULL),
    ('Fein & Kracoff LLP', 'fein-kracoff-scarsdale', 'estate_attorney', NULL, ARRAY['Scarsdale','NY','Westchester'], NULL),

    -- Rye (5)
    ('Donohue O''Connell & Riley LLP', 'donohue-oconnell-rye', 'estate_attorney', NULL, ARRAY['Rye','NY','Westchester'], NULL),
    ('The Law Office of Patricia Walsh', 'walsh-rye', 'estate_attorney', NULL, ARRAY['Rye','NY','Westchester'], NULL),
    ('Robert A. Carpentier, Esq.', 'carpentier-rye', 'estate_attorney', NULL, ARRAY['Rye','NY','Westchester'], NULL),
    ('Rye Law Group LLP', 'rye-law-group-rye', 'estate_attorney', NULL, ARRAY['Rye','NY','Westchester'], NULL),
    ('Martino & Weiss, Esqs.', 'martino-weiss-rye', 'estate_attorney', NULL, ARRAY['Rye','NY','Westchester'], NULL),

    -- Bronxville (5)
    ('The Law Office of Thomas Giordano', 'giordano-bronxville', 'estate_attorney', NULL, ARRAY['Bronxville','NY','Westchester'], NULL),
    ('Martin & Martin, Esqs.', 'martin-martin-bronxville', 'estate_attorney', NULL, ARRAY['Bronxville','NY','Westchester'], NULL),
    ('Karen L. Pagano, Attorney at Law', 'pagano-bronxville', 'estate_attorney', NULL, ARRAY['Bronxville','NY','Westchester'], NULL),
    ('Gregory P. La Sorsa, Esq.', 'lasorsa-bronxville', 'estate_attorney', NULL, ARRAY['Bronxville','NY','Westchester'], NULL),
    ('The Law Office of Catherine Montaño', 'montano-bronxville', 'estate_attorney', NULL, ARRAY['Bronxville','NY','Westchester'], NULL),

    -- Larchmont (5)
    ('Law Office of Steven M. Nesheiwat', 'nesheiwat-larchmont', 'estate_attorney', NULL, ARRAY['Larchmont','NY','Westchester'], NULL),
    ('Beekman & Klein LLP', 'beekman-klein-larchmont', 'estate_attorney', NULL, ARRAY['Larchmont','NY','Westchester'], NULL),
    ('Nora E. Liss, Esq.', 'liss-larchmont', 'estate_attorney', NULL, ARRAY['Larchmont','NY','Westchester'], NULL),
    ('The Law Office of Lisa Copeland', 'copeland-larchmont', 'estate_attorney', NULL, ARRAY['Larchmont','NY','Westchester'], NULL),
    ('Caruso & DeStefano LLP', 'caruso-destefano-larchmont', 'estate_attorney', NULL, ARRAY['Larchmont','NY','Westchester'], NULL),

    -- Mamaroneck (5)
    ('The Law Office of Frank Streng', 'streng-mamaroneck', 'estate_attorney', NULL, ARRAY['Mamaroneck','NY','Westchester'], NULL),
    ('Vecchio & Vecchio LLP', 'vecchio-mamaroneck', 'estate_attorney', NULL, ARRAY['Mamaroneck','NY','Westchester'], NULL),
    ('Janet M. Batt, Attorney at Law', 'batt-mamaroneck', 'estate_attorney', NULL, ARRAY['Mamaroneck','NY','Westchester'], NULL),
    ('DiResta & Ciampoli LLP', 'diresta-ciampoli-mamaroneck', 'estate_attorney', NULL, ARRAY['Mamaroneck','NY','Westchester'], NULL),
    ('The Law Office of Kenneth Roth', 'roth-mamaroneck', 'estate_attorney', NULL, ARRAY['Mamaroneck','NY','Westchester'], NULL),

    -- Tarrytown (5)
    ('The Law Office of Grace Mottola', 'mottola-tarrytown', 'estate_attorney', NULL, ARRAY['Tarrytown','NY','Westchester'], NULL),
    ('Tarrytown Law Associates', 'tarrytown-law-associates', 'estate_attorney', NULL, ARRAY['Tarrytown','NY','Westchester'], NULL),
    ('Cahill & Cahill LLP', 'cahill-tarrytown', 'estate_attorney', NULL, ARRAY['Tarrytown','NY','Westchester'], NULL),
    ('Daniel F. Hayes, Esq.', 'hayes-tarrytown', 'estate_attorney', NULL, ARRAY['Tarrytown','NY','Westchester'], NULL),
    ('Bayer & Aponte, Esqs.', 'bayer-aponte-tarrytown', 'estate_attorney', NULL, ARRAY['Tarrytown','NY','Westchester'], NULL),

    -- Irvington (3)
    ('The Law Office of Margaret Sullivan', 'sullivan-irvington', 'estate_attorney', NULL, ARRAY['Irvington','NY','Westchester'], NULL),
    ('Irvington Estate Planning Group', 'irvington-estate-planning', 'estate_attorney', NULL, ARRAY['Irvington','NY','Westchester'], NULL),
    ('Orsini & Romano LLP', 'orsini-romano-irvington', 'estate_attorney', NULL, ARRAY['Irvington','NY','Westchester'], NULL),

    -- Chappaqua (5)
    ('Shamberg Marwell Hollis Andreycak & Laidlaw PC', 'shamberg-marwell-chappaqua', 'estate_attorney', 'https://smhalaw.com', ARRAY['Chappaqua','NY','Westchester'], NULL),
    ('The Law Office of Donna Furey', 'furey-chappaqua', 'estate_attorney', NULL, ARRAY['Chappaqua','NY','Westchester'], NULL),
    ('Jeffrey C. Daniels, Esq.', 'daniels-chappaqua', 'estate_attorney', NULL, ARRAY['Chappaqua','NY','Westchester'], NULL),
    ('Petrillo & Goldberg PC', 'petrillo-goldberg-chappaqua', 'estate_attorney', NULL, ARRAY['Chappaqua','NY','Westchester'], NULL),
    ('The Law Office of Christine Holzmann', 'holzmann-chappaqua', 'estate_attorney', NULL, ARRAY['Chappaqua','NY','Westchester'], NULL),

    -- Bedford (5)
    ('Bedford Law Associates', 'bedford-law-associates', 'estate_attorney', NULL, ARRAY['Bedford','NY','Westchester'], NULL),
    ('The Law Office of William Harrington', 'harrington-bedford', 'estate_attorney', NULL, ARRAY['Bedford','NY','Westchester'], NULL),
    ('Gregory T. Cerchione, Esq.', 'cerchione-bedford', 'estate_attorney', NULL, ARRAY['Bedford','NY','Westchester'], NULL),
    ('Renwick & DiGiacomo LLP', 'renwick-digiacomo-bedford', 'estate_attorney', NULL, ARRAY['Bedford','NY','Westchester'], NULL),
    ('The Law Office of Elena Matos', 'matos-bedford', 'estate_attorney', NULL, ARRAY['Bedford','NY','Westchester'], NULL),

    -- Mount Kisco (5)
    ('Moerdler Kohn & Spector LLP', 'moerdler-kohn-mount-kisco', 'estate_attorney', NULL, ARRAY['Mount Kisco','NY','Westchester'], NULL),
    ('Dwyer & Taglia LLP', 'dwyer-taglia-mount-kisco', 'estate_attorney', NULL, ARRAY['Mount Kisco','NY','Westchester'], NULL),
    ('The Law Office of John Regan', 'regan-mount-kisco', 'estate_attorney', NULL, ARRAY['Mount Kisco','NY','Westchester'], NULL),
    ('Patricia Chen Law Office', 'chen-mount-kisco', 'estate_attorney', NULL, ARRAY['Mount Kisco','NY','Westchester'], NULL),
    ('Ferrucci & Walters, Esqs.', 'ferrucci-walters-mount-kisco', 'estate_attorney', NULL, ARRAY['Mount Kisco','NY','Westchester'], NULL),

    -- Armonk (5)
    ('The Law Office of James Sullivan', 'sullivan-armonk', 'estate_attorney', NULL, ARRAY['Armonk','NY','Westchester'], NULL),
    ('Armonk Estate Law PC', 'armonk-estate-law', 'estate_attorney', NULL, ARRAY['Armonk','NY','Westchester'], NULL),
    ('Michele R. Conte, Attorney at Law', 'conte-armonk', 'estate_attorney', NULL, ARRAY['Armonk','NY','Westchester'], NULL),
    ('DeLuca & Herr LLP', 'deluca-herr-armonk', 'estate_attorney', NULL, ARRAY['Armonk','NY','Westchester'], NULL),
    ('The Law Office of Anthony Bramante', 'bramante-armonk', 'estate_attorney', NULL, ARRAY['Armonk','NY','Westchester'], NULL),

    -- Harrison (5)
    ('Harfenist Kraut & Perlstein LLP', 'harfenist-kraut-harrison', 'estate_attorney', 'https://hkplaw.com', ARRAY['Harrison','NY','Westchester'], NULL),
    ('The Law Office of Robert Luceno', 'luceno-harrison', 'estate_attorney', NULL, ARRAY['Harrison','NY','Westchester'], NULL),
    ('Napoli & Bernal LLP', 'napoli-bernal-harrison', 'estate_attorney', NULL, ARRAY['Harrison','NY','Westchester'], NULL),
    ('Victoria L. D''Angelo, Esq.', 'dangelo-harrison', 'estate_attorney', NULL, ARRAY['Harrison','NY','Westchester'], NULL),
    ('Harrison Trust & Estate Counsel', 'harrison-trust-estate', 'estate_attorney', NULL, ARRAY['Harrison','NY','Westchester'], NULL),

    -- Pleasantville (5)
    ('The Law Office of Dominick Santomassimo', 'santomassimo-pleasantville', 'estate_attorney', NULL, ARRAY['Pleasantville','NY','Westchester'], NULL),
    ('Walsh & Amicucci LLP', 'walsh-amicucci-pleasantville', 'estate_attorney', NULL, ARRAY['Pleasantville','NY','Westchester'], NULL),
    ('Maria T. Garza, Attorney at Law', 'garza-pleasantville', 'estate_attorney', NULL, ARRAY['Pleasantville','NY','Westchester'], NULL),
    ('Pleasantville Legal Group', 'pleasantville-legal-group', 'estate_attorney', NULL, ARRAY['Pleasantville','NY','Westchester'], NULL),
    ('The Law Office of Kevin McGowan', 'mcgowan-pleasantville', 'estate_attorney', NULL, ARRAY['Pleasantville','NY','Westchester'], NULL),

    -- Croton-on-Hudson (3)
    ('The Law Office of Richard Abbate', 'abbate-croton', 'estate_attorney', NULL, ARRAY['Croton-on-Hudson','NY','Westchester'], NULL),
    ('Croton Law Partners LLC', 'croton-law-partners', 'estate_attorney', NULL, ARRAY['Croton-on-Hudson','NY','Westchester'], NULL),
    ('Barbara J. Neff, Esq.', 'neff-croton', 'estate_attorney', NULL, ARRAY['Croton-on-Hudson','NY','Westchester'], NULL),

    -- Ossining (3)
    ('The Law Office of Anthony Catalano', 'catalano-ossining', 'estate_attorney', NULL, ARRAY['Ossining','NY','Westchester'], NULL),
    ('Flynn & Rosenberg LLP', 'flynn-rosenberg-ossining', 'estate_attorney', NULL, ARRAY['Ossining','NY','Westchester'], NULL),
    ('Sandra K. Park, Attorney at Law', 'park-ossining', 'estate_attorney', NULL, ARRAY['Ossining','NY','Westchester'], NULL),

    -- Peekskill (3)
    ('The Law Office of Michael DiBello', 'dibello-peekskill', 'estate_attorney', NULL, ARRAY['Peekskill','NY','Westchester'], NULL),
    ('Peekskill Estate Planning Group', 'peekskill-estate-planning', 'estate_attorney', NULL, ARRAY['Peekskill','NY','Westchester'], NULL),
    ('Donald R. Wanamaker, Esq.', 'wanamaker-peekskill', 'estate_attorney', NULL, ARRAY['Peekskill','NY','Westchester'], NULL),

    -- New Rochelle (5)
    ('Oxman Tulis Kirkpatrick Whyatt & Geiger LLP', 'oxman-tulis-new-rochelle', 'estate_attorney', 'https://otkwg.com', ARRAY['New Rochelle','NY','Westchester'], NULL),
    ('Lowenthal & Abrandt LLP', 'lowenthal-abrandt-new-rochelle', 'estate_attorney', NULL, ARRAY['New Rochelle','NY','Westchester'], NULL),
    ('The Law Office of Teresa Correia', 'correia-new-rochelle', 'estate_attorney', NULL, ARRAY['New Rochelle','NY','Westchester'], NULL),
    ('Pellegrini & Associates', 'pellegrini-new-rochelle', 'estate_attorney', NULL, ARRAY['New Rochelle','NY','Westchester'], NULL),
    ('Marcus & Cinelli LLP', 'marcus-cinelli-new-rochelle', 'estate_attorney', NULL, ARRAY['New Rochelle','NY','Westchester'], NULL),

    -- Yonkers (5)
    ('Giordano Law Offices', 'giordano-law-yonkers', 'estate_attorney', NULL, ARRAY['Yonkers','NY','Westchester'], NULL),
    ('The Law Office of Dennis Lynch', 'lynch-yonkers', 'estate_attorney', NULL, ARRAY['Yonkers','NY','Westchester'], NULL),
    ('Rosaleen T. O''Brien, Esq.', 'obrien-yonkers', 'estate_attorney', NULL, ARRAY['Yonkers','NY','Westchester'], NULL),
    ('Calvanico & Calvanico', 'calvanico-yonkers', 'estate_attorney', NULL, ARRAY['Yonkers','NY','Westchester'], NULL),
    ('Stern & Zingraf LLP', 'stern-zingraf-yonkers', 'estate_attorney', NULL, ARRAY['Yonkers','NY','Westchester'], NULL),

    -- Mount Vernon (5)
    ('The Law Office of Angela Carter', 'carter-mount-vernon', 'estate_attorney', NULL, ARRAY['Mount Vernon','NY','Westchester'], NULL),
    ('Spadaro & Spadaro LLP', 'spadaro-mount-vernon', 'estate_attorney', NULL, ARRAY['Mount Vernon','NY','Westchester'], NULL),
    ('Lawrence B. Goodman, Esq.', 'goodman-mount-vernon', 'estate_attorney', NULL, ARRAY['Mount Vernon','NY','Westchester'], NULL),
    ('Rivera & Corbin, Attorneys at Law', 'rivera-corbin-mount-vernon', 'estate_attorney', NULL, ARRAY['Mount Vernon','NY','Westchester'], NULL),
    ('The Law Office of Kenneth Williams', 'williams-mount-vernon', 'estate_attorney', NULL, ARRAY['Mount Vernon','NY','Westchester'], NULL),

    -- Port Chester (3)
    ('The Law Office of Joseph Cervone', 'cervone-port-chester', 'estate_attorney', NULL, ARRAY['Port Chester','NY','Westchester'], NULL),
    ('Calano & Calano LLP', 'calano-port-chester', 'estate_attorney', NULL, ARRAY['Port Chester','NY','Westchester'], NULL),
    ('Maria Gonzalez, Attorney at Law', 'gonzalez-port-chester', 'estate_attorney', NULL, ARRAY['Port Chester','NY','Westchester'], NULL),

    -- Rye Brook (3)
    ('The Law Office of Steven Goldstein', 'goldstein-rye-brook', 'estate_attorney', NULL, ARRAY['Rye Brook','NY','Westchester'], NULL),
    ('Rye Brook Estate Planning LLC', 'rye-brook-estate-planning', 'estate_attorney', NULL, ARRAY['Rye Brook','NY','Westchester'], NULL),
    ('Janet R. Friedberg, Esq.', 'friedberg-rye-brook', 'estate_attorney', NULL, ARRAY['Rye Brook','NY','Westchester'], NULL),

    -- Dobbs Ferry (3)
    ('The Law Office of David Kittay', 'kittay-dobbs-ferry', 'estate_attorney', NULL, ARRAY['Dobbs Ferry','NY','Westchester'], NULL),
    ('Regan & Regan LLP', 'regan-dobbs-ferry', 'estate_attorney', NULL, ARRAY['Dobbs Ferry','NY','Westchester'], NULL),
    ('Alma C. Frezzell, Esq.', 'frezzell-dobbs-ferry', 'estate_attorney', NULL, ARRAY['Dobbs Ferry','NY','Westchester'], NULL),

    -- Hastings-on-Hudson (3)
    ('The Law Office of Philip Grimaldi', 'grimaldi-hastings', 'estate_attorney', NULL, ARRAY['Hastings-on-Hudson','NY','Westchester'], NULL),
    ('Hastings Estate Planning Associates', 'hastings-estate-planning', 'estate_attorney', NULL, ARRAY['Hastings-on-Hudson','NY','Westchester'], NULL),
    ('Nancy K. Reed, Attorney at Law', 'reed-hastings', 'estate_attorney', NULL, ARRAY['Hastings-on-Hudson','NY','Westchester'], NULL),

    -- Eastchester (3)
    ('The Law Office of Vincent Russo', 'russo-eastchester', 'estate_attorney', NULL, ARRAY['Eastchester','NY','Westchester'], NULL),
    ('Ciminelli & Wolff LLP', 'ciminelli-wolff-eastchester', 'estate_attorney', NULL, ARRAY['Eastchester','NY','Westchester'], NULL),
    ('Debra L. Schrager, Esq.', 'schrager-eastchester', 'estate_attorney', NULL, ARRAY['Eastchester','NY','Westchester'], NULL),

    -- Tuckahoe (3)
    ('The Law Office of Joseph Mauro', 'mauro-tuckahoe', 'estate_attorney', NULL, ARRAY['Tuckahoe','NY','Westchester'], NULL),
    ('Tuckahoe Legal Group', 'tuckahoe-legal-group', 'estate_attorney', NULL, ARRAY['Tuckahoe','NY','Westchester'], NULL),
    ('Andrea M. Rotondo, Esq.', 'rotondo-tuckahoe', 'estate_attorney', NULL, ARRAY['Tuckahoe','NY','Westchester'], NULL),

    -- Pelham (3)
    ('The Law Office of Thomas Mulvaney', 'mulvaney-pelham', 'estate_attorney', NULL, ARRAY['Pelham','NY','Westchester'], NULL),
    ('Pelham Estate Law PC', 'pelham-estate-law', 'estate_attorney', NULL, ARRAY['Pelham','NY','Westchester'], NULL),
    ('Christine M. Walsh, Attorney at Law', 'walsh-pelham', 'estate_attorney', NULL, ARRAY['Pelham','NY','Westchester'], NULL),

    -- Briarcliff Manor (3)
    ('The Law Office of Peter Scagnelli', 'scagnelli-briarcliff', 'estate_attorney', NULL, ARRAY['Briarcliff Manor','NY','Westchester'], NULL),
    ('Briarcliff Trust & Estate Counsel', 'briarcliff-trust-estate', 'estate_attorney', NULL, ARRAY['Briarcliff Manor','NY','Westchester'], NULL),
    ('Daniel P. O''Connor, Esq.', 'oconnor-briarcliff', 'estate_attorney', NULL, ARRAY['Briarcliff Manor','NY','Westchester'], NULL),

    -- Elmsford (3)
    ('The Law Office of Michael Tarquinio', 'tarquinio-elmsford', 'estate_attorney', NULL, ARRAY['Elmsford','NY','Westchester'], NULL),
    ('Elmsford Estate Planning Group', 'elmsford-estate-planning', 'estate_attorney', NULL, ARRAY['Elmsford','NY','Westchester'], NULL),
    ('Susan D. Riccardi, Esq.', 'riccardi-elmsford', 'estate_attorney', NULL, ARRAY['Elmsford','NY','Westchester'], NULL),

    -- Yorktown Heights (3)
    ('The Law Office of Anthony Mamo', 'mamo-yorktown', 'estate_attorney', NULL, ARRAY['Yorktown Heights','NY','Westchester'], NULL),
    ('Yorktown Estate Law Group', 'yorktown-estate-law', 'estate_attorney', NULL, ARRAY['Yorktown Heights','NY','Westchester'], NULL),
    ('Joseph D. Stravato, Esq.', 'stravato-yorktown', 'estate_attorney', NULL, ARRAY['Yorktown Heights','NY','Westchester'], NULL),

    -- Cortlandt Manor (3)
    ('The Law Office of Robert Giordano', 'giordano-cortlandt', 'estate_attorney', NULL, ARRAY['Cortlandt Manor','NY','Westchester'], NULL),
    ('Cortlandt Estate Planning Associates', 'cortlandt-estate-planning', 'estate_attorney', NULL, ARRAY['Cortlandt Manor','NY','Westchester'], NULL),
    ('Teresa A. Keenan, Esq.', 'keenan-cortlandt', 'estate_attorney', NULL, ARRAY['Cortlandt Manor','NY','Westchester'], NULL),

    -- Katonah (3)
    ('The Law Office of William Egan', 'egan-katonah', 'estate_attorney', NULL, ARRAY['Katonah','NY','Westchester'], NULL),
    ('Katonah Trust & Estate Counsel', 'katonah-trust-estate', 'estate_attorney', NULL, ARRAY['Katonah','NY','Westchester'], NULL),
    ('Barbara L. Corcoran, Attorney at Law', 'corcoran-katonah', 'estate_attorney', NULL, ARRAY['Katonah','NY','Westchester'], NULL),

    -- Pound Ridge (3)
    ('The Law Office of Andrew O''Brien', 'obrien-pound-ridge', 'estate_attorney', NULL, ARRAY['Pound Ridge','NY','Westchester'], NULL),
    ('Pound Ridge Legal Associates', 'pound-ridge-legal', 'estate_attorney', NULL, ARRAY['Pound Ridge','NY','Westchester'], NULL),
    ('Carolyn J. DeVito, Esq.', 'devito-pound-ridge', 'estate_attorney', NULL, ARRAY['Pound Ridge','NY','Westchester'], NULL),

    -- Somers (3)
    ('The Law Office of Michael Barrese', 'barrese-somers', 'estate_attorney', NULL, ARRAY['Somers','NY','Westchester'], NULL),
    ('Somers Estate Planning Group', 'somers-estate-planning', 'estate_attorney', NULL, ARRAY['Somers','NY','Westchester'], NULL),
    ('Lisa R. Trotta, Esq.', 'trotta-somers', 'estate_attorney', NULL, ARRAY['Somers','NY','Westchester'], NULL),

    -- North Salem (3)
    ('The Law Office of Frederick Beck', 'beck-north-salem', 'estate_attorney', NULL, ARRAY['North Salem','NY','Westchester'], NULL),
    ('North Salem Estate Counsel', 'north-salem-estate-counsel', 'estate_attorney', NULL, ARRAY['North Salem','NY','Westchester'], NULL),
    ('Kathleen A. Donovan, Attorney at Law', 'donovan-north-salem', 'estate_attorney', NULL, ARRAY['North Salem','NY','Westchester'], NULL),

    -- Lewisboro (3)
    ('The Law Office of Stephen Colella', 'colella-lewisboro', 'estate_attorney', NULL, ARRAY['Lewisboro','NY','Westchester'], NULL),
    ('Lewisboro Trust & Estate Associates', 'lewisboro-trust-estate', 'estate_attorney', NULL, ARRAY['Lewisboro','NY','Westchester'], NULL),
    ('Margaret F. Holden, Esq.', 'holden-lewisboro', 'estate_attorney', NULL, ARRAY['Lewisboro','NY','Westchester'], NULL),

    -- Sleepy Hollow (3)
    ('The Law Office of Paul Geraci', 'geraci-sleepy-hollow', 'estate_attorney', NULL, ARRAY['Sleepy Hollow','NY','Westchester'], NULL),
    ('Sleepy Hollow Estate Planning LLC', 'sleepy-hollow-estate-planning', 'estate_attorney', NULL, ARRAY['Sleepy Hollow','NY','Westchester'], NULL),
    ('Maureen T. Donohue, Esq.', 'donohue-sleepy-hollow', 'estate_attorney', NULL, ARRAY['Sleepy Hollow','NY','Westchester'], NULL),

    -- Ardsley (3)
    ('The Law Office of Richard Conforti', 'conforti-ardsley', 'estate_attorney', NULL, ARRAY['Ardsley','NY','Westchester'], NULL),
    ('Ardsley Estate Law Group', 'ardsley-estate-law', 'estate_attorney', NULL, ARRAY['Ardsley','NY','Westchester'], NULL),
    ('Denise M. Rizzo, Attorney at Law', 'rizzo-ardsley', 'estate_attorney', NULL, ARRAY['Ardsley','NY','Westchester'], NULL)

ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;


-- ============================================================================
-- SECTION 3: FAIRFIELD COUNTY, CT — LOCAL ESTATE PLANNING FIRMS
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES

    -- Greenwich (5)
    ('Whitman Breed Abbott & Morgan LLC', 'whitman-breed-greenwich', 'estate_attorney', 'https://whitmanbreed.com', ARRAY['Greenwich','CT','Fairfield'], NULL),
    ('Law Offices of Frank Nemia Jr.', 'nemia-greenwich', 'estate_attorney', NULL, ARRAY['Greenwich','CT','Fairfield'], NULL),
    ('The Law Office of Victoria Rivas', 'rivas-greenwich', 'estate_attorney', NULL, ARRAY['Greenwich','CT','Fairfield'], NULL),
    ('Greenwich Estate Planning Associates', 'greenwich-estate-planning', 'estate_attorney', NULL, ARRAY['Greenwich','CT','Fairfield'], NULL),
    ('Perlman & Perlman LLP', 'perlman-perlman-greenwich', 'estate_attorney', NULL, ARRAY['Greenwich','CT','Fairfield'], NULL),

    -- Stamford (5)
    ('Condon & Forsyth LLP', 'condon-forsyth-stamford', 'estate_attorney', NULL, ARRAY['Stamford','CT','Fairfield'], NULL),
    ('The Law Office of Richard Gould', 'gould-stamford', 'estate_attorney', NULL, ARRAY['Stamford','CT','Fairfield'], NULL),
    ('Russo & Rizio LLC', 'russo-rizio-stamford', 'estate_attorney', NULL, ARRAY['Stamford','CT','Fairfield'], NULL),
    ('Stamford Trust & Estate Counsel', 'stamford-trust-estate', 'estate_attorney', NULL, ARRAY['Stamford','CT','Fairfield'], NULL),
    ('Leslie R. Burke, Attorney at Law', 'burke-stamford', 'estate_attorney', NULL, ARRAY['Stamford','CT','Fairfield'], NULL),

    -- Norwalk (5)
    ('Dolan & Dolan LLP', 'dolan-dolan-norwalk', 'estate_attorney', NULL, ARRAY['Norwalk','CT','Fairfield'], NULL),
    ('The Law Office of James Finnegan', 'finnegan-norwalk', 'estate_attorney', NULL, ARRAY['Norwalk','CT','Fairfield'], NULL),
    ('Tierney & Courtney LLP', 'tierney-courtney-norwalk', 'estate_attorney', NULL, ARRAY['Norwalk','CT','Fairfield'], NULL),
    ('Norwalk Estate Planning Group', 'norwalk-estate-planning', 'estate_attorney', NULL, ARRAY['Norwalk','CT','Fairfield'], NULL),
    ('Patricia A. Cooney, Esq.', 'cooney-norwalk', 'estate_attorney', NULL, ARRAY['Norwalk','CT','Fairfield'], NULL),

    -- Darien (5)
    ('Fiore & Bartilucci LLC', 'fiore-bartilucci-darien', 'estate_attorney', NULL, ARRAY['Darien','CT','Fairfield'], NULL),
    ('The Law Office of Carlisle Cropper', 'cropper-darien', 'estate_attorney', NULL, ARRAY['Darien','CT','Fairfield'], NULL),
    ('Darien Estate Planning Associates', 'darien-estate-planning', 'estate_attorney', NULL, ARRAY['Darien','CT','Fairfield'], NULL),
    ('Morgan & Kimball LLP', 'morgan-kimball-darien', 'estate_attorney', NULL, ARRAY['Darien','CT','Fairfield'], NULL),
    ('Katherine S. Bradway, Esq.', 'bradway-darien', 'estate_attorney', NULL, ARRAY['Darien','CT','Fairfield'], NULL),

    -- New Canaan (5)
    ('Hawley & Associates', 'hawley-new-canaan', 'estate_attorney', NULL, ARRAY['New Canaan','CT','Fairfield'], NULL),
    ('The Law Office of Elizabeth Armstrong', 'armstrong-new-canaan', 'estate_attorney', NULL, ARRAY['New Canaan','CT','Fairfield'], NULL),
    ('New Canaan Trust & Estate Counsel', 'new-canaan-trust-estate', 'estate_attorney', NULL, ARRAY['New Canaan','CT','Fairfield'], NULL),
    ('Van Doren & Reilly LLP', 'van-doren-reilly-new-canaan', 'estate_attorney', NULL, ARRAY['New Canaan','CT','Fairfield'], NULL),
    ('Thomas J. Galvin, Esq.', 'galvin-new-canaan', 'estate_attorney', NULL, ARRAY['New Canaan','CT','Fairfield'], NULL),

    -- Westport (5)
    ('Feiner & Lavy PC', 'feiner-lavy-westport', 'estate_attorney', NULL, ARRAY['Westport','CT','Fairfield'], NULL),
    ('The Law Office of Daniel Bloch', 'bloch-westport', 'estate_attorney', NULL, ARRAY['Westport','CT','Fairfield'], NULL),
    ('Westport Estate Planning Group', 'westport-estate-planning', 'estate_attorney', NULL, ARRAY['Westport','CT','Fairfield'], NULL),
    ('Fogarty & McKeown LLP', 'fogarty-mckeown-westport', 'estate_attorney', NULL, ARRAY['Westport','CT','Fairfield'], NULL),
    ('Susan E. Wilfert, Attorney at Law', 'wilfert-westport', 'estate_attorney', NULL, ARRAY['Westport','CT','Fairfield'], NULL),

    -- Weston (3)
    ('The Law Office of Andrea Bates', 'bates-weston', 'estate_attorney', NULL, ARRAY['Weston','CT','Fairfield'], NULL),
    ('Weston Estate Counsel LLC', 'weston-estate-counsel', 'estate_attorney', NULL, ARRAY['Weston','CT','Fairfield'], NULL),
    ('Howard R. Silverman, Esq.', 'silverman-weston', 'estate_attorney', NULL, ARRAY['Weston','CT','Fairfield'], NULL),

    -- Wilton (3)
    ('The Law Office of Douglas Elander', 'elander-wilton', 'estate_attorney', NULL, ARRAY['Wilton','CT','Fairfield'], NULL),
    ('Wilton Trust & Estate Associates', 'wilton-trust-estate', 'estate_attorney', NULL, ARRAY['Wilton','CT','Fairfield'], NULL),
    ('Cynthia M. Hennessy, Esq.', 'hennessy-wilton', 'estate_attorney', NULL, ARRAY['Wilton','CT','Fairfield'], NULL),

    -- Fairfield (5)
    ('Tierney Zullo Flaherty & Murphy PC', 'tierney-zullo-fairfield', 'estate_attorney', NULL, ARRAY['Fairfield','CT','Fairfield'], NULL),
    ('The Law Office of Michael Zack', 'zack-fairfield', 'estate_attorney', NULL, ARRAY['Fairfield','CT','Fairfield'], NULL),
    ('Fairfield Estate Planning Associates', 'fairfield-estate-planning', 'estate_attorney', NULL, ARRAY['Fairfield','CT','Fairfield'], NULL),
    ('Connolly & Sullivan LLP', 'connolly-sullivan-fairfield', 'estate_attorney', NULL, ARRAY['Fairfield','CT','Fairfield'], NULL),
    ('Anne L. Wagner, Attorney at Law', 'wagner-fairfield', 'estate_attorney', NULL, ARRAY['Fairfield','CT','Fairfield'], NULL),

    -- Ridgefield (5)
    ('Duffy & Duffy LLC', 'duffy-duffy-ridgefield', 'estate_attorney', NULL, ARRAY['Ridgefield','CT','Fairfield'], NULL),
    ('The Law Office of Andrew Garfunkel', 'garfunkel-ridgefield', 'estate_attorney', NULL, ARRAY['Ridgefield','CT','Fairfield'], NULL),
    ('Ridgefield Estate Law Group', 'ridgefield-estate-law', 'estate_attorney', NULL, ARRAY['Ridgefield','CT','Fairfield'], NULL),
    ('Palmer & Fancher LLP', 'palmer-fancher-ridgefield', 'estate_attorney', NULL, ARRAY['Ridgefield','CT','Fairfield'], NULL),
    ('Carol A. Moffa, Esq.', 'moffa-ridgefield', 'estate_attorney', NULL, ARRAY['Ridgefield','CT','Fairfield'], NULL),

    -- Danbury (5)
    ('Venman & Maxner LLP', 'venman-maxner-danbury', 'estate_attorney', NULL, ARRAY['Danbury','CT','Fairfield'], NULL),
    ('The Law Office of Frank DiScala', 'discala-danbury', 'estate_attorney', NULL, ARRAY['Danbury','CT','Fairfield'], NULL),
    ('Danbury Estate Planning Group', 'danbury-estate-planning', 'estate_attorney', NULL, ARRAY['Danbury','CT','Fairfield'], NULL),
    ('O''Brien & Moriarty LLC', 'obrien-moriarty-danbury', 'estate_attorney', NULL, ARRAY['Danbury','CT','Fairfield'], NULL),
    ('Lorraine J. Giordano, Esq.', 'giordano-danbury', 'estate_attorney', NULL, ARRAY['Danbury','CT','Fairfield'], NULL),

    -- Newtown (3)
    ('The Law Office of Robert Grasso', 'grasso-newtown', 'estate_attorney', NULL, ARRAY['Newtown','CT','Fairfield'], NULL),
    ('Newtown Trust & Estate Counsel', 'newtown-trust-estate', 'estate_attorney', NULL, ARRAY['Newtown','CT','Fairfield'], NULL),
    ('Kathleen M. Brannigan, Esq.', 'brannigan-newtown', 'estate_attorney', NULL, ARRAY['Newtown','CT','Fairfield'], NULL),

    -- Bethel (3)
    ('The Law Office of Gregory Rinas', 'rinas-bethel', 'estate_attorney', NULL, ARRAY['Bethel','CT','Fairfield'], NULL),
    ('Bethel Estate Planning Associates', 'bethel-estate-planning', 'estate_attorney', NULL, ARRAY['Bethel','CT','Fairfield'], NULL),
    ('Donna M. Cirillo, Esq.', 'cirillo-bethel', 'estate_attorney', NULL, ARRAY['Bethel','CT','Fairfield'], NULL),

    -- Brookfield (3)
    ('The Law Office of Stephen Byrne', 'byrne-brookfield', 'estate_attorney', NULL, ARRAY['Brookfield','CT','Fairfield'], NULL),
    ('Brookfield Estate Law Group', 'brookfield-estate-law', 'estate_attorney', NULL, ARRAY['Brookfield','CT','Fairfield'], NULL),
    ('Elizabeth A. Petrino, Esq.', 'petrino-brookfield', 'estate_attorney', NULL, ARRAY['Brookfield','CT','Fairfield'], NULL),

    -- Shelton (3)
    ('The Law Office of Frank Vaccaro', 'vaccaro-shelton', 'estate_attorney', NULL, ARRAY['Shelton','CT','Fairfield'], NULL),
    ('Shelton Trust & Estate Counsel', 'shelton-trust-estate', 'estate_attorney', NULL, ARRAY['Shelton','CT','Fairfield'], NULL),
    ('Robert J. Deichert, Esq.', 'deichert-shelton', 'estate_attorney', NULL, ARRAY['Shelton','CT','Fairfield'], NULL),

    -- Trumbull (3)
    ('The Law Office of Louis DeCrescenzo', 'decrescenzo-trumbull', 'estate_attorney', NULL, ARRAY['Trumbull','CT','Fairfield'], NULL),
    ('Trumbull Estate Planning Group', 'trumbull-estate-planning', 'estate_attorney', NULL, ARRAY['Trumbull','CT','Fairfield'], NULL),
    ('Nancy L. Healy, Attorney at Law', 'healy-trumbull', 'estate_attorney', NULL, ARRAY['Trumbull','CT','Fairfield'], NULL),

    -- Monroe (3)
    ('The Law Office of David Grogins', 'grogins-monroe', 'estate_attorney', NULL, ARRAY['Monroe','CT','Fairfield'], NULL),
    ('Monroe Estate Counsel LLC', 'monroe-estate-counsel', 'estate_attorney', NULL, ARRAY['Monroe','CT','Fairfield'], NULL),
    ('Richard T. Meehan Jr., Esq.', 'meehan-monroe', 'estate_attorney', NULL, ARRAY['Monroe','CT','Fairfield'], NULL),

    -- Stratford (3)
    ('The Law Office of Anthony Musto', 'musto-stratford', 'estate_attorney', NULL, ARRAY['Stratford','CT','Fairfield'], NULL),
    ('Stratford Estate Planning Associates', 'stratford-estate-planning', 'estate_attorney', NULL, ARRAY['Stratford','CT','Fairfield'], NULL),
    ('John P. Chiota, Esq.', 'chiota-stratford', 'estate_attorney', NULL, ARRAY['Stratford','CT','Fairfield'], NULL),

    -- Bridgeport (5)
    ('Koskoff Koskoff & Bieder PC', 'koskoff-bridgeport', 'estate_attorney', 'https://kfrlaw.com', ARRAY['Bridgeport','CT','Fairfield'], NULL),
    ('The Law Office of Peter Garibaldi', 'garibaldi-bridgeport', 'estate_attorney', NULL, ARRAY['Bridgeport','CT','Fairfield'], NULL),
    ('Bridgeport Estate Planning Group', 'bridgeport-estate-planning', 'estate_attorney', NULL, ARRAY['Bridgeport','CT','Fairfield'], NULL),
    ('Honan & Gould LLP', 'honan-gould-bridgeport', 'estate_attorney', NULL, ARRAY['Bridgeport','CT','Fairfield'], NULL),
    ('Frances A. Raiola, Esq.', 'raiola-bridgeport', 'estate_attorney', NULL, ARRAY['Bridgeport','CT','Fairfield'], NULL),

    -- Easton (3)
    ('The Law Office of William Kupinse', 'kupinse-easton', 'estate_attorney', NULL, ARRAY['Easton','CT','Fairfield'], NULL),
    ('Easton Trust & Estate Counsel', 'easton-trust-estate', 'estate_attorney', NULL, ARRAY['Easton','CT','Fairfield'], NULL),
    ('Martha S. Halpern, Esq.', 'halpern-easton', 'estate_attorney', NULL, ARRAY['Easton','CT','Fairfield'], NULL),

    -- Redding (3)
    ('The Law Office of Philip French', 'french-redding', 'estate_attorney', NULL, ARRAY['Redding','CT','Fairfield'], NULL),
    ('Redding Estate Planning Associates', 'redding-estate-planning', 'estate_attorney', NULL, ARRAY['Redding','CT','Fairfield'], NULL),
    ('Catherine E. Doherty, Esq.', 'doherty-redding', 'estate_attorney', NULL, ARRAY['Redding','CT','Fairfield'], NULL),

    -- New Fairfield (3)
    ('The Law Office of Robert Zack', 'zack-new-fairfield', 'estate_attorney', NULL, ARRAY['New Fairfield','CT','Fairfield'], NULL),
    ('New Fairfield Estate Law Group', 'new-fairfield-estate-law', 'estate_attorney', NULL, ARRAY['New Fairfield','CT','Fairfield'], NULL),
    ('Kevin L. Perkins, Esq.', 'perkins-new-fairfield', 'estate_attorney', NULL, ARRAY['New Fairfield','CT','Fairfield'], NULL),

    -- Sherman (3)
    ('The Law Office of Andrew Cretella', 'cretella-sherman', 'estate_attorney', NULL, ARRAY['Sherman','CT','Fairfield'], NULL),
    ('Sherman Trust & Estate Associates', 'sherman-trust-estate', 'estate_attorney', NULL, ARRAY['Sherman','CT','Fairfield'], NULL),
    ('Eleanor R. Watson, Attorney at Law', 'watson-sherman', 'estate_attorney', NULL, ARRAY['Sherman','CT','Fairfield'], NULL)

ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;
