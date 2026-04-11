-- Seed Massachusetts financial advisory firms into utility_providers table.
-- provider_type = 'financial_advisor'. Logos are NULL at seed time and
-- enriched lazily via the brand-logo edge function.
--
-- Section 1: Major MA regional wealth/financial advisory firms (regions = ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'])
-- Section 2: Local firms in Essex County, MA (regions = ARRAY['Town','MA','Essex'])
-- Section 3: Local firms in Middlesex County, MA (regions = ARRAY['Town','MA','Middlesex'])
-- Section 4: Local firms in Norfolk County, MA (regions = ARRAY['Town','MA','Norfolk'])
-- Section 5: Local firms in Plymouth County, MA (regions = ARRAY['Town','MA','Plymouth'])
--
-- National wirehouses (Edward Jones, Merrill Lynch, Morgan Stanley, etc.) are already
-- seeded with ARRAY['US'] in 20260449 and are NOT duplicated here.
--
-- Slug convention: regional firms use plain slug (e.g. 'boston-private-wealth').
-- Local offices use firm-name-town (e.g. 'andover-wealth-management').

-- ════════════════════════════════════════════════════════════════════════════════
-- SECTION 1: Major MA regional wealth/financial advisory firms
-- ════════════════════════════════════════════════════════════════════════════════

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    ('Boston Private (SVB Private)', 'boston-private-svb', 'financial_advisor', 'https://www.svb.com/private-bank', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Wellesley Investment Advisors', 'wellesley-investment-advisors', 'financial_advisor', 'https://www.wellesleyinvestment.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Congress Wealth Management', 'congress-wealth-management', 'financial_advisor', 'https://www.congresswealth.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Ballentine Partners', 'ballentine-partners', 'financial_advisor', 'https://www.ballentinepartners.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Athena Capital Advisors', 'athena-capital-advisors', 'financial_advisor', 'https://www.athenacapital.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Advisor Capital Management', 'advisor-capital-management', 'financial_advisor', 'https://www.advisorcapital.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Windward Wealth Strategies', 'windward-wealth-strategies', 'financial_advisor', 'https://www.windwardwealth.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Stonebridge Financial Group', 'stonebridge-financial-group-ma', 'financial_advisor', 'https://www.stonebridgefg.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Baystate Financial', 'baystate-financial', 'financial_advisor', 'https://www.baystatefinancial.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Kendall Capital Management', 'kendall-capital-management', 'financial_advisor', 'https://www.kendallcapital.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('New England Private Wealth Advisors', 'new-england-private-wealth', 'financial_advisor', 'https://www.nepwa.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Colony Group', 'colony-group-boston', 'financial_advisor', 'https://www.thecolonygroup.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Fiduciary Trust Company', 'fiduciary-trust-boston', 'financial_advisor', 'https://www.fiduciarytrust.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Eastern Bank Wealth Management', 'eastern-bank-wealth', 'financial_advisor', 'https://www.easternbank.com/wealth', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Rockland Trust Investment Management', 'rockland-trust-investment', 'financial_advisor', 'https://www.rocklandtrust.com/wealth', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Cape Ann Capital', 'cape-ann-capital', 'financial_advisor', 'https://www.capeanncapital.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL),
    ('Lexington Wealth Management', 'lexington-wealth-management-ma', 'financial_advisor', 'https://www.lexingtonwealth.com', ARRAY['MA','Essex','Middlesex','Norfolk','Plymouth'], NULL)
ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ════════════════════════════════════════════════════════════════════════════════
-- SECTION 2: Local firms in Essex County, MA
-- ════════════════════════════════════════════════════════════════════════════════

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES

    -- ── Andover (HNW) ──
    ('Andover Wealth Advisors', 'andover-wealth-advisors', 'financial_advisor', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Phillips Academy Capital Partners', 'phillips-academy-capital-andover', 'financial_advisor', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Shawsheen River Financial Group', 'shawsheen-river-financial-andover', 'financial_advisor', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Merrimack Valley Wealth Management', 'merrimack-valley-wealth-andover', 'financial_advisor', NULL, ARRAY['Andover','MA','Essex'], NULL),
    ('Garrison & Holt Financial Advisors', 'garrison-holt-andover', 'financial_advisor', NULL, ARRAY['Andover','MA','Essex'], NULL),

    -- ── Beverly (HNW) ──
    ('Beverly Wealth Management', 'beverly-wealth-management', 'financial_advisor', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Cabot Street Capital Partners', 'cabot-street-capital-beverly', 'financial_advisor', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('North Shore Wealth Advisors', 'north-shore-wealth-beverly', 'financial_advisor', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Prides Crossing Financial Group', 'prides-crossing-financial-beverly', 'financial_advisor', NULL, ARRAY['Beverly','MA','Essex'], NULL),
    ('Lynch Park Capital', 'lynch-park-capital-beverly', 'financial_advisor', NULL, ARRAY['Beverly','MA','Essex'], NULL),

    -- ── Boxford (HNW) ──
    ('Boxford Wealth Partners', 'boxford-wealth-partners', 'financial_advisor', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Georgetown Road Capital Advisors', 'georgetown-road-capital-boxford', 'financial_advisor', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Kelsey & Whitman Financial', 'kelsey-whitman-boxford', 'financial_advisor', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Stiles Pond Wealth Advisory', 'stiles-pond-wealth-boxford', 'financial_advisor', NULL, ARRAY['Boxford','MA','Essex'], NULL),
    ('Boxford Common Financial Group', 'boxford-common-financial', 'financial_advisor', NULL, ARRAY['Boxford','MA','Essex'], NULL),

    -- ── Danvers ──
    ('Danvers Wealth Advisors', 'danvers-wealth-advisors', 'financial_advisor', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Endicott Financial Group', 'endicott-financial-danvers', 'financial_advisor', NULL, ARRAY['Danvers','MA','Essex'], NULL),
    ('Porter River Capital', 'porter-river-capital-danvers', 'financial_advisor', NULL, ARRAY['Danvers','MA','Essex'], NULL),

    -- ── Essex ──
    ('Essex Village Wealth Partners', 'essex-village-wealth-partners', 'financial_advisor', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Conomo Point Capital', 'conomo-point-capital-essex', 'financial_advisor', NULL, ARRAY['Essex','MA','Essex'], NULL),
    ('Essex River Financial Advisors', 'essex-river-financial', 'financial_advisor', NULL, ARRAY['Essex','MA','Essex'], NULL),

    -- ── Georgetown ──
    ('Georgetown Financial Advisors', 'georgetown-financial-advisors-ma', 'financial_advisor', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Pentucket Wealth Partners', 'pentucket-wealth-georgetown', 'financial_advisor', NULL, ARRAY['Georgetown','MA','Essex'], NULL),
    ('Parker River Capital', 'parker-river-capital-georgetown', 'financial_advisor', NULL, ARRAY['Georgetown','MA','Essex'], NULL),

    -- ── Gloucester ──
    ('Gloucester Harbor Wealth Management', 'gloucester-harbor-wealth', 'financial_advisor', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Beauport Financial Advisors', 'beauport-financial-gloucester', 'financial_advisor', NULL, ARRAY['Gloucester','MA','Essex'], NULL),
    ('Bass Rocks Capital Partners', 'bass-rocks-capital-gloucester', 'financial_advisor', NULL, ARRAY['Gloucester','MA','Essex'], NULL),

    -- ── Groveland ──
    ('Groveland Wealth Advisors', 'groveland-wealth-advisors', 'financial_advisor', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Johnson Creek Financial', 'johnson-creek-financial-groveland', 'financial_advisor', NULL, ARRAY['Groveland','MA','Essex'], NULL),
    ('Merrimack Bluffs Capital', 'merrimack-bluffs-capital-groveland', 'financial_advisor', NULL, ARRAY['Groveland','MA','Essex'], NULL),

    -- ── Hamilton (HNW) ──
    ('Hamilton Wealth Management', 'hamilton-wealth-management-ma', 'financial_advisor', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Asbury Grove Capital Partners', 'asbury-grove-capital-hamilton', 'financial_advisor', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Chebacco Financial Advisors', 'chebacco-financial-hamilton', 'financial_advisor', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Myopia Hunt Financial Group', 'myopia-hunt-financial-hamilton', 'financial_advisor', NULL, ARRAY['Hamilton','MA','Essex'], NULL),
    ('Patton Park Wealth Advisory', 'patton-park-wealth-hamilton', 'financial_advisor', NULL, ARRAY['Hamilton','MA','Essex'], NULL),

    -- ── Haverhill ──
    ('Haverhill Capital Advisors', 'haverhill-capital-advisors', 'financial_advisor', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Bradford & Sawyer Financial', 'bradford-sawyer-haverhill', 'financial_advisor', NULL, ARRAY['Haverhill','MA','Essex'], NULL),
    ('Kenoza Lake Wealth Partners', 'kenoza-lake-wealth-haverhill', 'financial_advisor', NULL, ARRAY['Haverhill','MA','Essex'], NULL),

    -- ── Ipswich (HNW) ──
    ('Ipswich Wealth Advisors', 'ipswich-wealth-advisors', 'financial_advisor', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Crane Beach Capital Partners', 'crane-beach-capital-ipswich', 'financial_advisor', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Castle Hill Financial Group', 'castle-hill-financial-ipswich', 'financial_advisor', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Argilla Road Wealth Management', 'argilla-road-wealth-ipswich', 'financial_advisor', NULL, ARRAY['Ipswich','MA','Essex'], NULL),
    ('Plum Island Capital Advisors', 'plum-island-capital-ipswich', 'financial_advisor', NULL, ARRAY['Ipswich','MA','Essex'], NULL),

    -- ── Lawrence ──
    ('Lawrence Financial Partners', 'lawrence-financial-partners', 'financial_advisor', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Merrimack Gateway Capital', 'merrimack-gateway-capital-lawrence', 'financial_advisor', NULL, ARRAY['Lawrence','MA','Essex'], NULL),
    ('Canal Street Wealth Advisors', 'canal-street-wealth-lawrence', 'financial_advisor', NULL, ARRAY['Lawrence','MA','Essex'], NULL),

    -- ── Lynn ──
    ('Lynn Shore Wealth Management', 'lynn-shore-wealth', 'financial_advisor', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Nahant Bay Capital Partners', 'nahant-bay-capital-lynn', 'financial_advisor', NULL, ARRAY['Lynn','MA','Essex'], NULL),
    ('Diamond District Financial', 'diamond-district-financial-lynn', 'financial_advisor', NULL, ARRAY['Lynn','MA','Essex'], NULL),

    -- ── Lynnfield (HNW) ──
    ('Lynnfield Wealth Advisors', 'lynnfield-wealth-advisors', 'financial_advisor', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Reedy Meadow Financial Group', 'reedy-meadow-financial-lynnfield', 'financial_advisor', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Sagamore Spring Capital', 'sagamore-spring-capital-lynnfield', 'financial_advisor', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Lynnfield Commons Wealth Partners', 'lynnfield-commons-wealth', 'financial_advisor', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),
    ('Pillings Pond Financial Advisors', 'pillings-pond-financial-lynnfield', 'financial_advisor', NULL, ARRAY['Lynnfield','MA','Essex'], NULL),

    -- ── Manchester-by-the-Sea (HNW) ──
    ('Manchester-by-the-Sea Wealth Partners', 'manchester-by-the-sea-wealth', 'financial_advisor', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Singing Beach Capital Advisors', 'singing-beach-capital-manchester', 'financial_advisor', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Tuck Point Financial Group', 'tuck-point-financial-manchester', 'financial_advisor', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Coolidge Point Wealth Advisory', 'coolidge-point-wealth-manchester', 'financial_advisor', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),
    ('Harbor View Capital Partners', 'harbor-view-capital-manchester', 'financial_advisor', NULL, ARRAY['Manchester-by-the-Sea','MA','Essex'], NULL),

    -- ── Marblehead (HNW) ──
    ('Marblehead Wealth Management', 'marblehead-wealth-management', 'financial_advisor', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Marblehead Neck Capital Advisors', 'marblehead-neck-capital', 'financial_advisor', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Fort Sewall Financial Partners', 'fort-sewall-financial-marblehead', 'financial_advisor', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Crocker Park Wealth Group', 'crocker-park-wealth-marblehead', 'financial_advisor', NULL, ARRAY['Marblehead','MA','Essex'], NULL),
    ('Old Town Marblehead Financial', 'old-town-marblehead-financial', 'financial_advisor', NULL, ARRAY['Marblehead','MA','Essex'], NULL),

    -- ── Merrimac ──
    ('Merrimac Village Wealth Advisors', 'merrimac-village-wealth', 'financial_advisor', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Lake Attitash Capital', 'lake-attitash-capital-merrimac', 'financial_advisor', NULL, ARRAY['Merrimac','MA','Essex'], NULL),
    ('Merrimac Square Financial', 'merrimac-square-financial', 'financial_advisor', NULL, ARRAY['Merrimac','MA','Essex'], NULL),

    -- ── Methuen ──
    ('Methuen Financial Partners', 'methuen-financial-partners', 'financial_advisor', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Forest Lake Wealth Advisors', 'forest-lake-wealth-methuen', 'financial_advisor', NULL, ARRAY['Methuen','MA','Essex'], NULL),
    ('Spicket River Capital', 'spicket-river-capital-methuen', 'financial_advisor', NULL, ARRAY['Methuen','MA','Essex'], NULL),

    -- ── Middleton ──
    ('Middleton Wealth Partners', 'middleton-wealth-partners-ma', 'financial_advisor', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Ferncroft Capital Advisors', 'ferncroft-capital-middleton', 'financial_advisor', NULL, ARRAY['Middleton','MA','Essex'], NULL),
    ('Ipswich River Financial Group', 'ipswich-river-financial-middleton', 'financial_advisor', NULL, ARRAY['Middleton','MA','Essex'], NULL),

    -- ── Nahant ──
    ('Nahant Wealth Management', 'nahant-wealth-management', 'financial_advisor', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('Bass Point Capital Partners', 'bass-point-capital-nahant', 'financial_advisor', NULL, ARRAY['Nahant','MA','Essex'], NULL),
    ('East Point Financial Advisors', 'east-point-financial-nahant', 'financial_advisor', NULL, ARRAY['Nahant','MA','Essex'], NULL),

    -- ── Newbury ──
    ('Newbury Wealth Advisors', 'newbury-wealth-advisors-ma', 'financial_advisor', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Plum Island Sound Capital', 'plum-island-sound-capital-newbury', 'financial_advisor', NULL, ARRAY['Newbury','MA','Essex'], NULL),
    ('Parker River Refuge Financial', 'parker-river-refuge-financial-newbury', 'financial_advisor', NULL, ARRAY['Newbury','MA','Essex'], NULL),

    -- ── Newburyport (HNW) ──
    ('Newburyport Wealth Management', 'newburyport-wealth-management', 'financial_advisor', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Clipper City Capital Advisors', 'clipper-city-capital-newburyport', 'financial_advisor', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('High Street Financial Partners', 'high-street-financial-newburyport', 'financial_advisor', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Merrimack Harbor Wealth Group', 'merrimack-harbor-wealth-newburyport', 'financial_advisor', NULL, ARRAY['Newburyport','MA','Essex'], NULL),
    ('Cushing & Burke Financial Advisors', 'cushing-burke-newburyport', 'financial_advisor', NULL, ARRAY['Newburyport','MA','Essex'], NULL),

    -- ── North Andover (HNW) ──
    ('North Andover Wealth Partners', 'north-andover-wealth-partners', 'financial_advisor', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Lake Cochichewick Capital', 'lake-cochichewick-capital-north-andover', 'financial_advisor', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Stevens Estate Financial Group', 'stevens-estate-financial-north-andover', 'financial_advisor', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Osgood Hill Wealth Advisory', 'osgood-hill-wealth-north-andover', 'financial_advisor', NULL, ARRAY['North Andover','MA','Essex'], NULL),
    ('Weir Hill Capital Partners', 'weir-hill-capital-north-andover', 'financial_advisor', NULL, ARRAY['North Andover','MA','Essex'], NULL),

    -- ── Peabody ──
    ('Peabody Financial Advisors', 'peabody-financial-advisors', 'financial_advisor', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Brooksby Village Wealth Partners', 'brooksby-village-wealth-peabody', 'financial_advisor', NULL, ARRAY['Peabody','MA','Essex'], NULL),
    ('Centennial Park Capital', 'centennial-park-capital-peabody', 'financial_advisor', NULL, ARRAY['Peabody','MA','Essex'], NULL),

    -- ── Rockport ──
    ('Rockport Wealth Management', 'rockport-wealth-management', 'financial_advisor', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Bearskin Neck Capital Partners', 'bearskin-neck-capital-rockport', 'financial_advisor', NULL, ARRAY['Rockport','MA','Essex'], NULL),
    ('Halibut Point Financial Advisors', 'halibut-point-financial-rockport', 'financial_advisor', NULL, ARRAY['Rockport','MA','Essex'], NULL),

    -- ── Rowley ──
    ('Rowley Financial Partners', 'rowley-financial-partners', 'financial_advisor', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Glen Mills Capital', 'glen-mills-capital-rowley', 'financial_advisor', NULL, ARRAY['Rowley','MA','Essex'], NULL),
    ('Rowley Marshes Wealth Advisors', 'rowley-marshes-wealth', 'financial_advisor', NULL, ARRAY['Rowley','MA','Essex'], NULL),

    -- ── Salem (HNW) ──
    ('Salem Wealth Management', 'salem-wealth-management-ma', 'financial_advisor', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Derby Wharf Capital Partners', 'derby-wharf-capital-salem', 'financial_advisor', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Chestnut Street Financial Group', 'chestnut-street-financial-salem', 'financial_advisor', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('McIntire District Wealth Advisors', 'mcintire-district-wealth-salem', 'financial_advisor', NULL, ARRAY['Salem','MA','Essex'], NULL),
    ('Collins Cove Capital', 'collins-cove-capital-salem', 'financial_advisor', NULL, ARRAY['Salem','MA','Essex'], NULL),

    -- ── Salisbury ──
    ('Salisbury Beach Wealth Partners', 'salisbury-beach-wealth', 'financial_advisor', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Ring Island Capital Advisors', 'ring-island-capital-salisbury', 'financial_advisor', NULL, ARRAY['Salisbury','MA','Essex'], NULL),
    ('Salisbury Point Financial', 'salisbury-point-financial', 'financial_advisor', NULL, ARRAY['Salisbury','MA','Essex'], NULL),

    -- ── Saugus ──
    ('Saugus Financial Partners', 'saugus-financial-partners', 'financial_advisor', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Breakheart Wealth Advisors', 'breakheart-wealth-saugus', 'financial_advisor', NULL, ARRAY['Saugus','MA','Essex'], NULL),
    ('Saugus Iron Works Capital', 'saugus-iron-works-capital', 'financial_advisor', NULL, ARRAY['Saugus','MA','Essex'], NULL),

    -- ── Swampscott (HNW) ──
    ('Swampscott Wealth Management', 'swampscott-wealth-management', 'financial_advisor', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Fishermans Beach Capital Partners', 'fishermans-beach-capital-swampscott', 'financial_advisor', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Humphrey Street Financial Group', 'humphrey-street-financial-swampscott', 'financial_advisor', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Preston Beach Wealth Advisors', 'preston-beach-wealth-swampscott', 'financial_advisor', NULL, ARRAY['Swampscott','MA','Essex'], NULL),
    ('Olmsted Park Capital', 'olmsted-park-capital-swampscott', 'financial_advisor', NULL, ARRAY['Swampscott','MA','Essex'], NULL),

    -- ── Topsfield (HNW) ──
    ('Topsfield Wealth Advisors', 'topsfield-wealth-advisors', 'financial_advisor', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Topsfield Fair Capital Partners', 'topsfield-fair-capital', 'financial_advisor', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Howlett Brook Financial Group', 'howlett-brook-financial-topsfield', 'financial_advisor', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Bradley Palmer Wealth Advisory', 'bradley-palmer-wealth-topsfield', 'financial_advisor', NULL, ARRAY['Topsfield','MA','Essex'], NULL),
    ('Topsfield Common Financial', 'topsfield-common-financial', 'financial_advisor', NULL, ARRAY['Topsfield','MA','Essex'], NULL),

    -- ── Wenham (HNW) ──
    ('Wenham Wealth Partners', 'wenham-wealth-partners', 'financial_advisor', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Gordon College Capital Advisors', 'gordon-college-capital-wenham', 'financial_advisor', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Pleasant Pond Financial Group', 'pleasant-pond-financial-wenham', 'financial_advisor', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Wenham Lake Wealth Advisory', 'wenham-lake-wealth', 'financial_advisor', NULL, ARRAY['Wenham','MA','Essex'], NULL),
    ('Main Street Wenham Financial', 'main-street-wenham-financial', 'financial_advisor', NULL, ARRAY['Wenham','MA','Essex'], NULL),

    -- ── West Newbury ──
    ('West Newbury Wealth Management', 'west-newbury-wealth-management', 'financial_advisor', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('Indian Hill Capital Partners', 'indian-hill-capital-west-newbury', 'financial_advisor', NULL, ARRAY['West Newbury','MA','Essex'], NULL),
    ('Artichoke River Financial', 'artichoke-river-financial-west-newbury', 'financial_advisor', NULL, ARRAY['West Newbury','MA','Essex'], NULL)

ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ════════════════════════════════════════════════════════════════════════════════
-- SECTION 3: Local firms in Middlesex County, MA
-- ════════════════════════════════════════════════════════════════════════════════

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES

    -- ── Acton ──
    ('Acton Wealth Advisors', 'acton-wealth-advisors', 'financial_advisor', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Great Road Capital Partners', 'great-road-capital-acton', 'financial_advisor', NULL, ARRAY['Acton','MA','Middlesex'], NULL),
    ('Nagog Hill Financial Group', 'nagog-hill-financial-acton', 'financial_advisor', NULL, ARRAY['Acton','MA','Middlesex'], NULL),

    -- ── Arlington (HNW) ──
    ('Arlington Wealth Management', 'arlington-wealth-management-ma', 'financial_advisor', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Menotomy Financial Advisors', 'menotomy-financial-arlington', 'financial_advisor', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Spy Pond Capital Partners', 'spy-pond-capital-arlington', 'financial_advisor', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Massachusetts Avenue Wealth Group', 'mass-ave-wealth-arlington', 'financial_advisor', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),
    ('Arlington Heights Financial', 'arlington-heights-financial', 'financial_advisor', NULL, ARRAY['Arlington','MA','Middlesex'], NULL),

    -- ── Ashby ──
    ('Ashby Financial Partners', 'ashby-financial-partners', 'financial_advisor', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Watatic Mountain Capital', 'watatic-mountain-capital-ashby', 'financial_advisor', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),
    ('Ashby Common Wealth Advisors', 'ashby-common-wealth', 'financial_advisor', NULL, ARRAY['Ashby','MA','Middlesex'], NULL),

    -- ── Ashland ──
    ('Ashland Wealth Management', 'ashland-wealth-management', 'financial_advisor', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Hopkinton Road Capital Partners', 'hopkinton-road-capital-ashland', 'financial_advisor', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),
    ('Warren Conference Financial', 'warren-conference-financial-ashland', 'financial_advisor', NULL, ARRAY['Ashland','MA','Middlesex'], NULL),

    -- ── Ayer ──
    ('Ayer Capital Advisors', 'ayer-capital-advisors', 'financial_advisor', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Nashua River Financial Group', 'nashua-river-financial-ayer', 'financial_advisor', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),
    ('Sandy Pond Wealth Partners', 'sandy-pond-wealth-ayer', 'financial_advisor', NULL, ARRAY['Ayer','MA','Middlesex'], NULL),

    -- ── Bedford ──
    ('Bedford Wealth Partners', 'bedford-wealth-partners-ma', 'financial_advisor', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Great Meadows Financial Group', 'great-meadows-financial-bedford', 'financial_advisor', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),
    ('Springs Brook Capital', 'springs-brook-capital-bedford', 'financial_advisor', NULL, ARRAY['Bedford','MA','Middlesex'], NULL),

    -- ── Belmont (HNW) ──
    ('Belmont Wealth Advisors', 'belmont-wealth-advisors-ma', 'financial_advisor', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Belmont Hill Capital Partners', 'belmont-hill-capital', 'financial_advisor', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Payson Park Financial Group', 'payson-park-financial-belmont', 'financial_advisor', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Oakley Country Club Wealth', 'oakley-country-club-wealth-belmont', 'financial_advisor', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),
    ('Fresh Pond Parkway Capital', 'fresh-pond-parkway-capital-belmont', 'financial_advisor', NULL, ARRAY['Belmont','MA','Middlesex'], NULL),

    -- ── Billerica ──
    ('Billerica Wealth Management', 'billerica-wealth-management', 'financial_advisor', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Concord River Capital Partners', 'concord-river-capital-billerica', 'financial_advisor', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),
    ('Nuttings Lake Financial', 'nuttings-lake-financial-billerica', 'financial_advisor', NULL, ARRAY['Billerica','MA','Middlesex'], NULL),

    -- ── Boxborough ──
    ('Boxborough Wealth Partners', 'boxborough-wealth-partners', 'financial_advisor', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Flerra Meadows Capital', 'flerra-meadows-capital-boxborough', 'financial_advisor', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),
    ('Boxborough Common Financial', 'boxborough-common-financial', 'financial_advisor', NULL, ARRAY['Boxborough','MA','Middlesex'], NULL),

    -- ── Burlington ──
    ('Burlington Financial Advisors', 'burlington-financial-advisors-ma', 'financial_advisor', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Burlington Mall Capital', 'burlington-mall-capital', 'financial_advisor', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),
    ('Middlesex Turnpike Wealth Group', 'middlesex-turnpike-wealth-burlington', 'financial_advisor', NULL, ARRAY['Burlington','MA','Middlesex'], NULL),

    -- ── Cambridge (HNW) ──
    ('Cambridge Wealth Management', 'cambridge-wealth-management-ma', 'financial_advisor', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Harvard Square Capital Advisors', 'harvard-square-capital-cambridge', 'financial_advisor', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Brattle Street Financial Partners', 'brattle-street-financial-cambridge', 'financial_advisor', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Porter Square Wealth Group', 'porter-square-wealth-cambridge', 'financial_advisor', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),
    ('Kendall Square Capital', 'kendall-square-capital-cambridge', 'financial_advisor', NULL, ARRAY['Cambridge','MA','Middlesex'], NULL),

    -- ── Carlisle (HNW) ──
    ('Carlisle Wealth Partners', 'carlisle-wealth-partners', 'financial_advisor', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Cranberry Bog Capital Advisors', 'cranberry-bog-capital-carlisle', 'financial_advisor', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Great Brook Farm Financial', 'great-brook-farm-financial-carlisle', 'financial_advisor', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Bates & Pennington Wealth Advisory', 'bates-pennington-carlisle', 'financial_advisor', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),
    ('Bedford Road Capital', 'bedford-road-capital-carlisle', 'financial_advisor', NULL, ARRAY['Carlisle','MA','Middlesex'], NULL),

    -- ── Chelmsford ──
    ('Chelmsford Wealth Advisors', 'chelmsford-wealth-advisors', 'financial_advisor', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Drum Hill Capital Partners', 'drum-hill-capital-chelmsford', 'financial_advisor', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),
    ('Heart Pond Financial Group', 'heart-pond-financial-chelmsford', 'financial_advisor', NULL, ARRAY['Chelmsford','MA','Middlesex'], NULL),

    -- ── Concord (HNW) ──
    ('Concord Wealth Management', 'concord-wealth-management-ma', 'financial_advisor', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Walden Pond Capital Advisors', 'walden-pond-capital-concord', 'financial_advisor', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Old North Bridge Financial', 'old-north-bridge-financial-concord', 'financial_advisor', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Thoreau & Emerson Wealth Partners', 'thoreau-emerson-wealth-concord', 'financial_advisor', NULL, ARRAY['Concord','MA','Middlesex'], NULL),
    ('Monument Square Capital Group', 'monument-square-capital-concord', 'financial_advisor', NULL, ARRAY['Concord','MA','Middlesex'], NULL),

    -- ── Dracut ──
    ('Dracut Financial Partners', 'dracut-financial-partners', 'financial_advisor', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Collinsville Wealth Advisors', 'collinsville-wealth-dracut', 'financial_advisor', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),
    ('Richardson Road Capital', 'richardson-road-capital-dracut', 'financial_advisor', NULL, ARRAY['Dracut','MA','Middlesex'], NULL),

    -- ── Dunstable ──
    ('Dunstable Wealth Management', 'dunstable-wealth-management', 'financial_advisor', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Salmon Brook Capital', 'salmon-brook-capital-dunstable', 'financial_advisor', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),
    ('Dunstable Common Financial', 'dunstable-common-financial', 'financial_advisor', NULL, ARRAY['Dunstable','MA','Middlesex'], NULL),

    -- ── Everett ──
    ('Everett Capital Advisors', 'everett-capital-advisors', 'financial_advisor', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Mystic River Wealth Partners', 'mystic-river-wealth-everett', 'financial_advisor', NULL, ARRAY['Everett','MA','Middlesex'], NULL),
    ('Ferry Street Financial Group', 'ferry-street-financial-everett', 'financial_advisor', NULL, ARRAY['Everett','MA','Middlesex'], NULL),

    -- ── Framingham ──
    ('Framingham Wealth Management', 'framingham-wealth-management', 'financial_advisor', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Nobscot Capital Partners', 'nobscot-capital-framingham', 'financial_advisor', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),
    ('Cochituate Financial Advisors', 'cochituate-financial-framingham', 'financial_advisor', NULL, ARRAY['Framingham','MA','Middlesex'], NULL),

    -- ── Groton ──
    ('Groton Wealth Partners', 'groton-wealth-partners', 'financial_advisor', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Groton School Capital Advisors', 'groton-school-capital', 'financial_advisor', NULL, ARRAY['Groton','MA','Middlesex'], NULL),
    ('Gibbet Hill Financial Group', 'gibbet-hill-financial-groton', 'financial_advisor', NULL, ARRAY['Groton','MA','Middlesex'], NULL),

    -- ── Holliston ──
    ('Holliston Financial Advisors', 'holliston-financial-advisors', 'financial_advisor', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Lake Winthrop Capital', 'lake-winthrop-capital-holliston', 'financial_advisor', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),
    ('Holliston Center Wealth Partners', 'holliston-center-wealth', 'financial_advisor', NULL, ARRAY['Holliston','MA','Middlesex'], NULL),

    -- ── Hopkinton ──
    ('Hopkinton Wealth Management', 'hopkinton-wealth-management', 'financial_advisor', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Marathon Capital Partners', 'marathon-capital-hopkinton', 'financial_advisor', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),
    ('Whitehall Brook Financial', 'whitehall-brook-financial-hopkinton', 'financial_advisor', NULL, ARRAY['Hopkinton','MA','Middlesex'], NULL),

    -- ── Hudson ──
    ('Hudson Financial Partners', 'hudson-financial-partners-ma', 'financial_advisor', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Assabet River Capital Advisors', 'assabet-river-capital-hudson', 'financial_advisor', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),
    ('Wood Square Wealth Group', 'wood-square-wealth-hudson', 'financial_advisor', NULL, ARRAY['Hudson','MA','Middlesex'], NULL),

    -- ── Lexington (HNW) ──
    ('Lexington Capital Advisors', 'lexington-capital-advisors-ma', 'financial_advisor', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Battle Green Wealth Partners', 'battle-green-wealth-lexington', 'financial_advisor', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Minuteman Financial Group', 'minuteman-financial-lexington', 'financial_advisor', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Hancock Street Capital', 'hancock-street-capital-lexington', 'financial_advisor', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),
    ('Parker & Revere Wealth Advisors', 'parker-revere-wealth-lexington', 'financial_advisor', NULL, ARRAY['Lexington','MA','Middlesex'], NULL),

    -- ── Lincoln (HNW) ──
    ('Lincoln Wealth Management', 'lincoln-wealth-management-ma', 'financial_advisor', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('DeCordova Capital Advisors', 'decordova-capital-lincoln', 'financial_advisor', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Codman Farm Financial Group', 'codman-farm-financial-lincoln', 'financial_advisor', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Sandy Pond Wealth Management', 'sandy-pond-wealth-lincoln', 'financial_advisor', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),
    ('Lincoln Woods Capital Partners', 'lincoln-woods-capital', 'financial_advisor', NULL, ARRAY['Lincoln','MA','Middlesex'], NULL),

    -- ── Littleton ──
    ('Littleton Financial Partners', 'littleton-financial-partners', 'financial_advisor', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('Nagog Pond Capital', 'nagog-pond-capital-littleton', 'financial_advisor', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),
    ('King Street Wealth Advisors', 'king-street-wealth-littleton', 'financial_advisor', NULL, ARRAY['Littleton','MA','Middlesex'], NULL),

    -- ── Lowell ──
    ('Lowell Capital Management', 'lowell-capital-management', 'financial_advisor', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Merrimack Wealth Partners', 'merrimack-wealth-partners-lowell', 'financial_advisor', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),
    ('Pawtucket Falls Financial', 'pawtucket-falls-financial-lowell', 'financial_advisor', NULL, ARRAY['Lowell','MA','Middlesex'], NULL),

    -- ── Malden ──
    ('Malden Financial Advisors', 'malden-financial-advisors', 'financial_advisor', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Bell Rock Capital Partners', 'bell-rock-capital-malden', 'financial_advisor', NULL, ARRAY['Malden','MA','Middlesex'], NULL),
    ('Fellsway Wealth Management', 'fellsway-wealth-malden', 'financial_advisor', NULL, ARRAY['Malden','MA','Middlesex'], NULL),

    -- ── Marlborough ──
    ('Marlborough Wealth Partners', 'marlborough-wealth-partners', 'financial_advisor', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Williams Street Capital', 'williams-street-capital-marlborough', 'financial_advisor', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),
    ('Lake Williams Financial Group', 'lake-williams-financial-marlborough', 'financial_advisor', NULL, ARRAY['Marlborough','MA','Middlesex'], NULL),

    -- ── Maynard ──
    ('Maynard Capital Advisors', 'maynard-capital-advisors', 'financial_advisor', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Assabet Village Financial', 'assabet-village-financial-maynard', 'financial_advisor', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),
    ('Clocktower Wealth Partners', 'clocktower-wealth-maynard', 'financial_advisor', NULL, ARRAY['Maynard','MA','Middlesex'], NULL),

    -- ── Medford ──
    ('Medford Wealth Management', 'medford-wealth-management', 'financial_advisor', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Mystic Lakes Capital', 'mystic-lakes-capital-medford', 'financial_advisor', NULL, ARRAY['Medford','MA','Middlesex'], NULL),
    ('Tufts University Financial Group', 'tufts-financial-medford', 'financial_advisor', NULL, ARRAY['Medford','MA','Middlesex'], NULL),

    -- ── Melrose ──
    ('Melrose Financial Partners', 'melrose-financial-partners', 'financial_advisor', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Ell Pond Capital Advisors', 'ell-pond-capital-melrose', 'financial_advisor', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),
    ('Wyoming Hill Wealth Management', 'wyoming-hill-wealth-melrose', 'financial_advisor', NULL, ARRAY['Melrose','MA','Middlesex'], NULL),

    -- ── Natick (HNW) ──
    ('Natick Wealth Advisors', 'natick-wealth-advisors', 'financial_advisor', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Lake Cochituate Capital Partners', 'lake-cochituate-capital-natick', 'financial_advisor', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('South Natick Financial Group', 'south-natick-financial', 'financial_advisor', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Hunnewell & Chase Wealth Advisors', 'hunnewell-chase-natick', 'financial_advisor', NULL, ARRAY['Natick','MA','Middlesex'], NULL),
    ('Natick Common Capital', 'natick-common-capital', 'financial_advisor', NULL, ARRAY['Natick','MA','Middlesex'], NULL),

    -- ── Newton (HNW) ──
    ('Newton Wealth Management', 'newton-wealth-management-ma', 'financial_advisor', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Chestnut Hill Capital Advisors', 'chestnut-hill-capital-newton', 'financial_advisor', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Newton Centre Financial Partners', 'newton-centre-financial', 'financial_advisor', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Waban Hill Wealth Group', 'waban-hill-wealth-newton', 'financial_advisor', NULL, ARRAY['Newton','MA','Middlesex'], NULL),
    ('Crystal Lake Capital', 'crystal-lake-capital-newton', 'financial_advisor', NULL, ARRAY['Newton','MA','Middlesex'], NULL),

    -- ── North Reading ──
    ('North Reading Wealth Advisors', 'north-reading-wealth-advisors', 'financial_advisor', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('Martins Pond Capital', 'martins-pond-capital-north-reading', 'financial_advisor', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),
    ('Ipswich River Wealth Group', 'ipswich-river-wealth-north-reading', 'financial_advisor', NULL, ARRAY['North Reading','MA','Middlesex'], NULL),

    -- ── Pepperell ──
    ('Pepperell Financial Partners', 'pepperell-financial-partners', 'financial_advisor', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Nissitissit River Capital', 'nissitissit-river-capital-pepperell', 'financial_advisor', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),
    ('Pepperell Center Wealth Advisors', 'pepperell-center-wealth', 'financial_advisor', NULL, ARRAY['Pepperell','MA','Middlesex'], NULL),

    -- ── Reading ──
    ('Reading Wealth Management', 'reading-wealth-management-ma', 'financial_advisor', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Birch Meadow Capital Partners', 'birch-meadow-capital-reading', 'financial_advisor', NULL, ARRAY['Reading','MA','Middlesex'], NULL),
    ('Reading Common Financial', 'reading-common-financial', 'financial_advisor', NULL, ARRAY['Reading','MA','Middlesex'], NULL),

    -- ── Sherborn (HNW) ──
    ('Sherborn Wealth Partners', 'sherborn-wealth-partners', 'financial_advisor', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Farm Pond Capital Advisors', 'farm-pond-capital-sherborn', 'financial_advisor', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Brush Hill Financial Group', 'brush-hill-financial-sherborn', 'financial_advisor', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Whitney & Dowse Wealth Advisory', 'whitney-dowse-sherborn', 'financial_advisor', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),
    ('Pine Hill Capital Partners', 'pine-hill-capital-sherborn', 'financial_advisor', NULL, ARRAY['Sherborn','MA','Middlesex'], NULL),

    -- ── Shirley ──
    ('Shirley Financial Advisors', 'shirley-financial-advisors', 'financial_advisor', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Catacoonamug Capital', 'catacoonamug-capital-shirley', 'financial_advisor', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),
    ('Shirley Village Wealth Partners', 'shirley-village-wealth', 'financial_advisor', NULL, ARRAY['Shirley','MA','Middlesex'], NULL),

    -- ── Somerville ──
    ('Somerville Capital Management', 'somerville-capital-management', 'financial_advisor', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Davis Square Financial Partners', 'davis-square-financial-somerville', 'financial_advisor', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),
    ('Assembly Row Wealth Advisors', 'assembly-row-wealth-somerville', 'financial_advisor', NULL, ARRAY['Somerville','MA','Middlesex'], NULL),

    -- ── Stoneham ──
    ('Stoneham Wealth Management', 'stoneham-wealth-management', 'financial_advisor', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Spot Pond Capital Partners', 'spot-pond-capital-stoneham', 'financial_advisor', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),
    ('Fells Reservoir Financial', 'fells-reservoir-financial-stoneham', 'financial_advisor', NULL, ARRAY['Stoneham','MA','Middlesex'], NULL),

    -- ── Stow ──
    ('Stow Capital Advisors', 'stow-capital-advisors', 'financial_advisor', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Lake Boon Financial Partners', 'lake-boon-financial-stow', 'financial_advisor', NULL, ARRAY['Stow','MA','Middlesex'], NULL),
    ('Stow Acres Wealth Group', 'stow-acres-wealth', 'financial_advisor', NULL, ARRAY['Stow','MA','Middlesex'], NULL),

    -- ── Sudbury (HNW) ──
    ('Sudbury Wealth Advisors', 'sudbury-wealth-advisors', 'financial_advisor', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Longfellow Capital Partners', 'longfellow-capital-sudbury', 'financial_advisor', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Wayside Inn Financial Group', 'wayside-inn-financial-sudbury', 'financial_advisor', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Willis Hill Wealth Management', 'willis-hill-wealth-sudbury', 'financial_advisor', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),
    ('Nobscot Brook Capital', 'nobscot-brook-capital-sudbury', 'financial_advisor', NULL, ARRAY['Sudbury','MA','Middlesex'], NULL),

    -- ── Tewksbury ──
    ('Tewksbury Financial Partners', 'tewksbury-financial-partners', 'financial_advisor', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Long Pond Wealth Advisors', 'long-pond-wealth-tewksbury', 'financial_advisor', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),
    ('Shawsheen Valley Capital', 'shawsheen-valley-capital-tewksbury', 'financial_advisor', NULL, ARRAY['Tewksbury','MA','Middlesex'], NULL),

    -- ── Townsend ──
    ('Townsend Wealth Management', 'townsend-wealth-management', 'financial_advisor', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Squannacook River Capital', 'squannacook-river-capital-townsend', 'financial_advisor', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),
    ('Townsend Harbor Financial', 'townsend-harbor-financial', 'financial_advisor', NULL, ARRAY['Townsend','MA','Middlesex'], NULL),

    -- ── Tyngsborough ──
    ('Tyngsborough Capital Advisors', 'tyngsborough-capital-advisors', 'financial_advisor', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Vesper Country Club Wealth', 'vesper-country-club-wealth-tyngsborough', 'financial_advisor', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),
    ('Mascuppic Lake Financial', 'mascuppic-lake-financial-tyngsborough', 'financial_advisor', NULL, ARRAY['Tyngsborough','MA','Middlesex'], NULL),

    -- ── Wakefield ──
    ('Wakefield Wealth Advisors', 'wakefield-wealth-advisors-ma', 'financial_advisor', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Lake Quannapowitt Capital', 'lake-quannapowitt-capital-wakefield', 'financial_advisor', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),
    ('Main Street Wakefield Financial', 'main-street-wakefield-financial', 'financial_advisor', NULL, ARRAY['Wakefield','MA','Middlesex'], NULL),

    -- ── Waltham ──
    ('Waltham Financial Partners', 'waltham-financial-partners', 'financial_advisor', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Moody Street Capital Advisors', 'moody-street-capital-waltham', 'financial_advisor', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),
    ('Charles River Wealth Group', 'charles-river-wealth-waltham', 'financial_advisor', NULL, ARRAY['Waltham','MA','Middlesex'], NULL),

    -- ── Watertown ──
    ('Watertown Wealth Management', 'watertown-wealth-management', 'financial_advisor', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Arsenal Street Capital Partners', 'arsenal-street-capital-watertown', 'financial_advisor', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),
    ('Perkins School Financial Group', 'perkins-school-financial-watertown', 'financial_advisor', NULL, ARRAY['Watertown','MA','Middlesex'], NULL),

    -- ── Wayland (HNW) ──
    ('Wayland Wealth Partners', 'wayland-wealth-partners', 'financial_advisor', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Dudley Pond Capital Advisors', 'dudley-pond-capital-wayland', 'financial_advisor', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Cochituate Road Financial', 'cochituate-road-financial-wayland', 'financial_advisor', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Wayland Center Wealth Group', 'wayland-center-wealth', 'financial_advisor', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),
    ('Heard Farm Capital Partners', 'heard-farm-capital-wayland', 'financial_advisor', NULL, ARRAY['Wayland','MA','Middlesex'], NULL),

    -- ── Westford (HNW) ──
    ('Westford Wealth Advisors', 'westford-wealth-advisors', 'financial_advisor', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Forge Village Capital Partners', 'forge-village-capital-westford', 'financial_advisor', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Nashoba Valley Financial Group', 'nashoba-valley-financial-westford', 'financial_advisor', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Stony Brook Wealth Management', 'stony-brook-wealth-westford', 'financial_advisor', NULL, ARRAY['Westford','MA','Middlesex'], NULL),
    ('Westford Common Capital', 'westford-common-capital', 'financial_advisor', NULL, ARRAY['Westford','MA','Middlesex'], NULL),

    -- ── Weston (HNW) ──
    ('Weston Wealth Management', 'weston-wealth-management-ma', 'financial_advisor', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Weston Country Club Capital', 'weston-country-club-capital', 'financial_advisor', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Highland Street Wealth Partners', 'highland-street-wealth-weston', 'financial_advisor', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('Campion & Fields Financial Advisors', 'campion-fields-weston', 'financial_advisor', NULL, ARRAY['Weston','MA','Middlesex'], NULL),
    ('College Pond Capital Group', 'college-pond-capital-weston', 'financial_advisor', NULL, ARRAY['Weston','MA','Middlesex'], NULL),

    -- ── Wilmington ──
    ('Wilmington Financial Partners', 'wilmington-financial-partners-ma', 'financial_advisor', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Silver Lake Wealth Advisors', 'silver-lake-wealth-wilmington', 'financial_advisor', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),
    ('Harnden Tavern Capital', 'harnden-tavern-capital-wilmington', 'financial_advisor', NULL, ARRAY['Wilmington','MA','Middlesex'], NULL),

    -- ── Winchester (HNW) ──
    ('Winchester Wealth Advisors', 'winchester-wealth-advisors-ma', 'financial_advisor', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Fells Capital Partners', 'fells-capital-winchester', 'financial_advisor', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Aberjona River Financial Group', 'aberjona-river-financial-winchester', 'financial_advisor', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Winchester Center Wealth Management', 'winchester-center-wealth', 'financial_advisor', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),
    ('Wedge Pond Capital', 'wedge-pond-capital-winchester', 'financial_advisor', NULL, ARRAY['Winchester','MA','Middlesex'], NULL),

    -- ── Woburn ──
    ('Woburn Wealth Management', 'woburn-wealth-management', 'financial_advisor', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Horn Pond Capital Partners', 'horn-pond-capital-woburn', 'financial_advisor', NULL, ARRAY['Woburn','MA','Middlesex'], NULL),
    ('Commerce Way Financial Group', 'commerce-way-financial-woburn', 'financial_advisor', NULL, ARRAY['Woburn','MA','Middlesex'], NULL)

ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ════════════════════════════════════════════════════════════════════════════════
-- SECTION 4: Local firms in Norfolk County, MA
-- ════════════════════════════════════════════════════════════════════════════════

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES

    -- ── Avon ──
    ('Avon Financial Partners', 'avon-financial-partners-ma', 'financial_advisor', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Stockwell Drive Capital', 'stockwell-drive-capital-avon', 'financial_advisor', NULL, ARRAY['Avon','MA','Norfolk'], NULL),
    ('Blue Hill Wealth Advisors', 'blue-hill-wealth-avon', 'financial_advisor', NULL, ARRAY['Avon','MA','Norfolk'], NULL),

    -- ── Braintree ──
    ('Braintree Wealth Management', 'braintree-wealth-management', 'financial_advisor', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('Pond Meadow Capital Partners', 'pond-meadow-capital-braintree', 'financial_advisor', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),
    ('South Shore Financial Group', 'south-shore-financial-braintree', 'financial_advisor', NULL, ARRAY['Braintree','MA','Norfolk'], NULL),

    -- ── Brookline (HNW) ──
    ('Brookline Wealth Advisors', 'brookline-wealth-advisors', 'financial_advisor', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Coolidge Corner Capital Partners', 'coolidge-corner-capital-brookline', 'financial_advisor', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Beacon Street Financial Group', 'beacon-street-financial-brookline', 'financial_advisor', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Longwood Wealth Management', 'longwood-wealth-brookline', 'financial_advisor', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),
    ('Fisher Hill Capital', 'fisher-hill-capital-brookline', 'financial_advisor', NULL, ARRAY['Brookline','MA','Norfolk'], NULL),

    -- ── Canton ──
    ('Canton Wealth Management', 'canton-wealth-management-ma', 'financial_advisor', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Reservoir Pond Capital Partners', 'reservoir-pond-capital-canton', 'financial_advisor', NULL, ARRAY['Canton','MA','Norfolk'], NULL),
    ('Neponset Valley Financial', 'neponset-valley-financial-canton', 'financial_advisor', NULL, ARRAY['Canton','MA','Norfolk'], NULL),

    -- ── Cohasset (HNW) ──
    ('Cohasset Wealth Partners', 'cohasset-wealth-partners', 'financial_advisor', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Jerusalem Road Capital Advisors', 'jerusalem-road-capital-cohasset', 'financial_advisor', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Cohasset Harbor Financial Group', 'cohasset-harbor-financial', 'financial_advisor', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Sandy Cove Wealth Management', 'sandy-cove-wealth-cohasset', 'financial_advisor', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),
    ('Minot Light Capital', 'minot-light-capital-cohasset', 'financial_advisor', NULL, ARRAY['Cohasset','MA','Norfolk'], NULL),

    -- ── Dedham (HNW) ──
    ('Dedham Wealth Advisors', 'dedham-wealth-advisors', 'financial_advisor', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Endicott Estate Capital Partners', 'endicott-estate-capital-dedham', 'financial_advisor', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Mother Brook Financial Group', 'mother-brook-financial-dedham', 'financial_advisor', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Dedham Square Wealth Management', 'dedham-square-wealth', 'financial_advisor', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),
    ('Fairbanks Park Capital', 'fairbanks-park-capital-dedham', 'financial_advisor', NULL, ARRAY['Dedham','MA','Norfolk'], NULL),

    -- ── Dover (HNW) ──
    ('Dover Wealth Management', 'dover-wealth-management-ma', 'financial_advisor', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Farm Street Capital Advisors', 'farm-street-capital-dover', 'financial_advisor', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Noanet Brook Financial Partners', 'noanet-brook-financial-dover', 'financial_advisor', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Caryl Park Wealth Group', 'caryl-park-wealth-dover', 'financial_advisor', NULL, ARRAY['Dover','MA','Norfolk'], NULL),
    ('Charles River Meadows Capital', 'charles-river-meadows-capital-dover', 'financial_advisor', NULL, ARRAY['Dover','MA','Norfolk'], NULL),

    -- ── Foxborough ──
    ('Foxborough Financial Advisors', 'foxborough-financial-advisors', 'financial_advisor', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Patriot Place Wealth Partners', 'patriot-place-wealth-foxborough', 'financial_advisor', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),
    ('Cocasset River Capital', 'cocasset-river-capital-foxborough', 'financial_advisor', NULL, ARRAY['Foxborough','MA','Norfolk'], NULL),

    -- ── Franklin ──
    ('Franklin Wealth Management', 'franklin-wealth-management-ma', 'financial_advisor', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('DelCarte Pond Capital Partners', 'delcarte-pond-capital-franklin', 'financial_advisor', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),
    ('Franklin Crossing Financial', 'franklin-crossing-financial', 'financial_advisor', NULL, ARRAY['Franklin','MA','Norfolk'], NULL),

    -- ── Holbrook ──
    ('Holbrook Financial Partners', 'holbrook-financial-partners', 'financial_advisor', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Mary Lee Brook Capital', 'mary-lee-brook-capital-holbrook', 'financial_advisor', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),
    ('Holbrook Center Wealth Advisors', 'holbrook-center-wealth', 'financial_advisor', NULL, ARRAY['Holbrook','MA','Norfolk'], NULL),

    -- ── Medfield (HNW) ──
    ('Medfield Wealth Partners', 'medfield-wealth-partners', 'financial_advisor', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Noon Hill Capital Advisors', 'noon-hill-capital-medfield', 'financial_advisor', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Charles River Financial Group', 'charles-river-financial-medfield', 'financial_advisor', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Medfield Center Wealth Management', 'medfield-center-wealth', 'financial_advisor', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),
    ('Rocky Woods Capital', 'rocky-woods-capital-medfield', 'financial_advisor', NULL, ARRAY['Medfield','MA','Norfolk'], NULL),

    -- ── Medway ──
    ('Medway Wealth Advisors', 'medway-wealth-advisors', 'financial_advisor', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Choate Park Capital', 'choate-park-capital-medway', 'financial_advisor', NULL, ARRAY['Medway','MA','Norfolk'], NULL),
    ('Charles River Village Financial', 'charles-river-village-financial-medway', 'financial_advisor', NULL, ARRAY['Medway','MA','Norfolk'], NULL),

    -- ── Millis ──
    ('Millis Financial Partners', 'millis-financial-partners', 'financial_advisor', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Oak Grove Farm Capital', 'oak-grove-farm-capital-millis', 'financial_advisor', NULL, ARRAY['Millis','MA','Norfolk'], NULL),
    ('Richardson Wealth Advisors', 'richardson-wealth-millis', 'financial_advisor', NULL, ARRAY['Millis','MA','Norfolk'], NULL),

    -- ── Milton (HNW) ──
    ('Milton Wealth Management', 'milton-wealth-management-ma', 'financial_advisor', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Blue Hills Capital Advisors', 'blue-hills-capital-milton', 'financial_advisor', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Forbes Hill Financial Partners', 'forbes-hill-financial-milton', 'financial_advisor', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Houghtons Pond Wealth Group', 'houghtons-pond-wealth-milton', 'financial_advisor', NULL, ARRAY['Milton','MA','Norfolk'], NULL),
    ('Cunningham Park Capital', 'cunningham-park-capital-milton', 'financial_advisor', NULL, ARRAY['Milton','MA','Norfolk'], NULL),

    -- ── Needham (HNW) ──
    ('Needham Wealth Advisors', 'needham-wealth-advisors', 'financial_advisor', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Needham Heights Capital Partners', 'needham-heights-capital', 'financial_advisor', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Charles River Financial Partners', 'charles-river-financial-needham', 'financial_advisor', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Ridge Hill Wealth Management', 'ridge-hill-wealth-needham', 'financial_advisor', NULL, ARRAY['Needham','MA','Norfolk'], NULL),
    ('Cutler Park Capital Group', 'cutler-park-capital-needham', 'financial_advisor', NULL, ARRAY['Needham','MA','Norfolk'], NULL),

    -- ── Norfolk ──
    ('Norfolk Financial Advisors', 'norfolk-financial-advisors-ma', 'financial_advisor', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('Stony Brook Capital Partners', 'stony-brook-capital-norfolk', 'financial_advisor', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),
    ('King Philip Wealth Management', 'king-philip-wealth-norfolk', 'financial_advisor', NULL, ARRAY['Norfolk','MA','Norfolk'], NULL),

    -- ── Norwood ──
    ('Norwood Wealth Management', 'norwood-wealth-management', 'financial_advisor', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Hawes Brook Capital Partners', 'hawes-brook-capital-norwood', 'financial_advisor', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),
    ('Norwood Center Financial', 'norwood-center-financial', 'financial_advisor', NULL, ARRAY['Norwood','MA','Norfolk'], NULL),

    -- ── Plainville ──
    ('Plainville Financial Partners', 'plainville-financial-partners', 'financial_advisor', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Shepards Brook Capital', 'shepards-brook-capital-plainville', 'financial_advisor', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),
    ('Plainville Crossing Wealth Advisors', 'plainville-crossing-wealth', 'financial_advisor', NULL, ARRAY['Plainville','MA','Norfolk'], NULL),

    -- ── Quincy ──
    ('Quincy Capital Management', 'quincy-capital-management', 'financial_advisor', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Presidents City Wealth Partners', 'presidents-city-wealth-quincy', 'financial_advisor', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),
    ('Wollaston Beach Capital', 'wollaston-beach-capital-quincy', 'financial_advisor', NULL, ARRAY['Quincy','MA','Norfolk'], NULL),

    -- ── Randolph ──
    ('Randolph Wealth Advisors', 'randolph-wealth-advisors', 'financial_advisor', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('Ponkapoag Pond Capital', 'ponkapoag-pond-capital-randolph', 'financial_advisor', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),
    ('North Randolph Financial Partners', 'north-randolph-financial', 'financial_advisor', NULL, ARRAY['Randolph','MA','Norfolk'], NULL),

    -- ── Sharon ──
    ('Sharon Financial Management', 'sharon-financial-management-ma', 'financial_advisor', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Lake Massapoag Capital Partners', 'lake-massapoag-capital-sharon', 'financial_advisor', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),
    ('Moose Hill Wealth Advisors', 'moose-hill-wealth-sharon', 'financial_advisor', NULL, ARRAY['Sharon','MA','Norfolk'], NULL),

    -- ── Stoughton ──
    ('Stoughton Wealth Management', 'stoughton-wealth-management', 'financial_advisor', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Ames Estate Capital Partners', 'ames-estate-capital-stoughton', 'financial_advisor', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),
    ('Cedar Street Financial Group', 'cedar-street-financial-stoughton', 'financial_advisor', NULL, ARRAY['Stoughton','MA','Norfolk'], NULL),

    -- ── Walpole ──
    ('Walpole Financial Advisors', 'walpole-financial-advisors', 'financial_advisor', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Turners Pond Capital', 'turners-pond-capital-walpole', 'financial_advisor', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),
    ('Walpole Center Wealth Partners', 'walpole-center-wealth', 'financial_advisor', NULL, ARRAY['Walpole','MA','Norfolk'], NULL),

    -- ── Wellesley (HNW) ──
    ('Wellesley Wealth Partners', 'wellesley-wealth-partners', 'financial_advisor', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Wellesley Hills Capital Advisors', 'wellesley-hills-capital', 'financial_advisor', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Morses Pond Financial Group', 'morses-pond-financial-wellesley', 'financial_advisor', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('College Crossing Wealth Management', 'college-crossing-wealth-wellesley', 'financial_advisor', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),
    ('Babson Park Capital', 'babson-park-capital-wellesley', 'financial_advisor', NULL, ARRAY['Wellesley','MA','Norfolk'], NULL),

    -- ── Westwood (HNW) ──
    ('Westwood Wealth Management', 'westwood-wealth-management-ma', 'financial_advisor', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Buckmaster Pond Capital Partners', 'buckmaster-pond-capital-westwood', 'financial_advisor', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Hale Reservation Financial Group', 'hale-reservation-financial-westwood', 'financial_advisor', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Islington Village Wealth Advisors', 'islington-village-wealth-westwood', 'financial_advisor', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),
    ('Fox Hill Capital', 'fox-hill-capital-westwood', 'financial_advisor', NULL, ARRAY['Westwood','MA','Norfolk'], NULL),

    -- ── Weymouth ──
    ('Weymouth Wealth Management', 'weymouth-wealth-management', 'financial_advisor', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Great Pond Capital Partners', 'great-pond-capital-weymouth', 'financial_advisor', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),
    ('Wessagusset Beach Financial', 'wessagusset-beach-financial-weymouth', 'financial_advisor', NULL, ARRAY['Weymouth','MA','Norfolk'], NULL),

    -- ── Wrentham ──
    ('Wrentham Financial Partners', 'wrentham-financial-partners', 'financial_advisor', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Lake Pearl Capital Advisors', 'lake-pearl-capital-wrentham', 'financial_advisor', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL),
    ('Wrentham Common Wealth Group', 'wrentham-common-wealth', 'financial_advisor', NULL, ARRAY['Wrentham','MA','Norfolk'], NULL)

ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;

-- ════════════════════════════════════════════════════════════════════════════════
-- SECTION 5: Local firms in Plymouth County, MA
-- ════════════════════════════════════════════════════════════════════════════════

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES

    -- ── Abington ──
    ('Abington Financial Partners', 'abington-financial-partners', 'financial_advisor', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Island Grove Capital', 'island-grove-capital-abington', 'financial_advisor', NULL, ARRAY['Abington','MA','Plymouth'], NULL),
    ('Ames Nowell Wealth Advisors', 'ames-nowell-wealth-abington', 'financial_advisor', NULL, ARRAY['Abington','MA','Plymouth'], NULL),

    -- ── Bridgewater ──
    ('Bridgewater Wealth Management', 'bridgewater-wealth-management-ma', 'financial_advisor', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Carver Pond Capital Partners', 'carver-pond-capital-bridgewater', 'financial_advisor', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),
    ('Taunton River Financial Group', 'taunton-river-financial-bridgewater', 'financial_advisor', NULL, ARRAY['Bridgewater','MA','Plymouth'], NULL),

    -- ── Brockton ──
    ('Brockton Capital Advisors', 'brockton-capital-advisors', 'financial_advisor', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Waldo Lake Wealth Partners', 'waldo-lake-wealth-brockton', 'financial_advisor', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),
    ('Champion City Financial', 'champion-city-financial-brockton', 'financial_advisor', NULL, ARRAY['Brockton','MA','Plymouth'], NULL),

    -- ── Carver ──
    ('Carver Financial Partners', 'carver-financial-partners', 'financial_advisor', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Sampson Pond Capital', 'sampson-pond-capital-carver', 'financial_advisor', NULL, ARRAY['Carver','MA','Plymouth'], NULL),
    ('Cranberry Bog Wealth Advisors', 'cranberry-bog-wealth-carver', 'financial_advisor', NULL, ARRAY['Carver','MA','Plymouth'], NULL),

    -- ── Duxbury (HNW) ──
    ('Duxbury Wealth Management', 'duxbury-wealth-management', 'financial_advisor', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Duxbury Beach Capital Advisors', 'duxbury-beach-capital', 'financial_advisor', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Standish Shore Financial Group', 'standish-shore-financial-duxbury', 'financial_advisor', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Bluefish River Wealth Partners', 'bluefish-river-wealth-duxbury', 'financial_advisor', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),
    ('Snug Harbor Capital', 'snug-harbor-capital-duxbury', 'financial_advisor', NULL, ARRAY['Duxbury','MA','Plymouth'], NULL),

    -- ── East Bridgewater ──
    ('East Bridgewater Financial Advisors', 'east-bridgewater-financial', 'financial_advisor', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('Sachem Rock Capital', 'sachem-rock-capital-east-bridgewater', 'financial_advisor', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),
    ('Satucket River Wealth Partners', 'satucket-river-wealth-east-bridgewater', 'financial_advisor', NULL, ARRAY['East Bridgewater','MA','Plymouth'], NULL),

    -- ── Halifax ──
    ('Halifax Wealth Management', 'halifax-wealth-management-ma', 'financial_advisor', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Monponsett Pond Capital', 'monponsett-pond-capital-halifax', 'financial_advisor', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),
    ('Silver Lake Financial Advisors', 'silver-lake-financial-halifax', 'financial_advisor', NULL, ARRAY['Halifax','MA','Plymouth'], NULL),

    -- ── Hanover (HNW) ──
    ('Hanover Wealth Partners', 'hanover-wealth-partners-ma', 'financial_advisor', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Forge Pond Capital Advisors', 'forge-pond-capital-hanover', 'financial_advisor', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Hanover Crossing Financial Group', 'hanover-crossing-financial', 'financial_advisor', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Indian Head River Wealth Management', 'indian-head-river-wealth-hanover', 'financial_advisor', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),
    ('Assinippi Capital Partners', 'assinippi-capital-hanover', 'financial_advisor', NULL, ARRAY['Hanover','MA','Plymouth'], NULL),

    -- ── Hanson ──
    ('Hanson Financial Advisors', 'hanson-financial-advisors', 'financial_advisor', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Maquan Pond Capital', 'maquan-pond-capital-hanson', 'financial_advisor', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),
    ('Wampatuck Wealth Partners', 'wampatuck-wealth-hanson', 'financial_advisor', NULL, ARRAY['Hanson','MA','Plymouth'], NULL),

    -- ── Hingham (HNW) ──
    ('Hingham Wealth Management', 'hingham-wealth-management', 'financial_advisor', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Hingham Harbor Capital Advisors', 'hingham-harbor-capital', 'financial_advisor', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Worlds End Financial Partners', 'worlds-end-financial-hingham', 'financial_advisor', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Derby Academy Wealth Group', 'derby-academy-wealth-hingham', 'financial_advisor', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),
    ('Crow Point Capital', 'crow-point-capital-hingham', 'financial_advisor', NULL, ARRAY['Hingham','MA','Plymouth'], NULL),

    -- ── Hull ──
    ('Hull Wealth Advisors', 'hull-wealth-advisors', 'financial_advisor', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Nantasket Beach Capital', 'nantasket-beach-capital-hull', 'financial_advisor', NULL, ARRAY['Hull','MA','Plymouth'], NULL),
    ('Windmill Point Financial', 'windmill-point-financial-hull', 'financial_advisor', NULL, ARRAY['Hull','MA','Plymouth'], NULL),

    -- ── Kingston ──
    ('Kingston Financial Partners', 'kingston-financial-partners-ma', 'financial_advisor', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Jones River Capital Advisors', 'jones-river-capital-kingston', 'financial_advisor', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),
    ('Silver Lake Wealth Management', 'silver-lake-wealth-kingston', 'financial_advisor', NULL, ARRAY['Kingston','MA','Plymouth'], NULL),

    -- ── Lakeville ──
    ('Lakeville Wealth Advisors', 'lakeville-wealth-advisors', 'financial_advisor', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Assawompset Pond Capital', 'assawompset-pond-capital-lakeville', 'financial_advisor', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),
    ('Clear Pond Financial', 'clear-pond-financial-lakeville', 'financial_advisor', NULL, ARRAY['Lakeville','MA','Plymouth'], NULL),

    -- ── Marion (HNW) ──
    ('Marion Wealth Management', 'marion-wealth-management', 'financial_advisor', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Sippican Harbor Capital Advisors', 'sippican-harbor-capital-marion', 'financial_advisor', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Tabor Academy Financial Partners', 'tabor-academy-financial-marion', 'financial_advisor', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Bird Island Wealth Group', 'bird-island-wealth-marion', 'financial_advisor', NULL, ARRAY['Marion','MA','Plymouth'], NULL),
    ('Planting Island Capital', 'planting-island-capital-marion', 'financial_advisor', NULL, ARRAY['Marion','MA','Plymouth'], NULL),

    -- ── Marshfield (HNW) ──
    ('Marshfield Wealth Partners', 'marshfield-wealth-partners', 'financial_advisor', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Brant Rock Capital Advisors', 'brant-rock-capital-marshfield', 'financial_advisor', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Green Harbor Financial Group', 'green-harbor-financial-marshfield', 'financial_advisor', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('Daniel Webster Wealth Management', 'daniel-webster-wealth-marshfield', 'financial_advisor', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),
    ('North River Capital Partners', 'north-river-capital-marshfield', 'financial_advisor', NULL, ARRAY['Marshfield','MA','Plymouth'], NULL),

    -- ── Mattapoisett ──
    ('Mattapoisett Financial Advisors', 'mattapoisett-financial-advisors', 'financial_advisor', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Mattapoisett Harbor Capital', 'mattapoisett-harbor-capital', 'financial_advisor', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),
    ('Ned Point Wealth Partners', 'ned-point-wealth-mattapoisett', 'financial_advisor', NULL, ARRAY['Mattapoisett','MA','Plymouth'], NULL),

    -- ── Middleborough ──
    ('Middleborough Wealth Management', 'middleborough-wealth-management', 'financial_advisor', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Nemasket River Capital', 'nemasket-river-capital-middleborough', 'financial_advisor', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),
    ('Pratt Farm Financial Advisors', 'pratt-farm-financial-middleborough', 'financial_advisor', NULL, ARRAY['Middleborough','MA','Plymouth'], NULL),

    -- ── Norwell (HNW) ──
    ('Norwell Wealth Partners', 'norwell-wealth-partners', 'financial_advisor', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Jacobs Pond Capital Advisors', 'jacobs-pond-capital-norwell', 'financial_advisor', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Norwell Village Financial Group', 'norwell-village-financial', 'financial_advisor', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('North River Wealth Management', 'north-river-wealth-norwell', 'financial_advisor', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),
    ('Tiffany Road Capital', 'tiffany-road-capital-norwell', 'financial_advisor', NULL, ARRAY['Norwell','MA','Plymouth'], NULL),

    -- ── Pembroke ──
    ('Pembroke Financial Advisors', 'pembroke-financial-advisors', 'financial_advisor', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Hobomock Wealth Partners', 'hobomock-wealth-pembroke', 'financial_advisor', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),
    ('Furnace Pond Capital', 'furnace-pond-capital-pembroke', 'financial_advisor', NULL, ARRAY['Pembroke','MA','Plymouth'], NULL),

    -- ── Plymouth (HNW) ──
    ('Plymouth Wealth Management', 'plymouth-wealth-management', 'financial_advisor', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Plymouth Harbor Capital Advisors', 'plymouth-harbor-capital', 'financial_advisor', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Pilgrim Financial Partners', 'pilgrim-financial-plymouth', 'financial_advisor', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('Manomet Point Wealth Group', 'manomet-point-wealth-plymouth', 'financial_advisor', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),
    ('White Horse Beach Capital', 'white-horse-beach-capital-plymouth', 'financial_advisor', NULL, ARRAY['Plymouth','MA','Plymouth'], NULL),

    -- ── Plympton ──
    ('Plympton Wealth Advisors', 'plympton-wealth-advisors', 'financial_advisor', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Winnetuxet River Capital', 'winnetuxet-river-capital-plympton', 'financial_advisor', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),
    ('Plympton Center Financial', 'plympton-center-financial', 'financial_advisor', NULL, ARRAY['Plympton','MA','Plymouth'], NULL),

    -- ── Rochester ──
    ('Rochester Financial Partners', 'rochester-financial-partners-ma', 'financial_advisor', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Mattapoisett River Capital', 'mattapoisett-river-capital-rochester', 'financial_advisor', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),
    ('Snipatuit Pond Wealth Advisors', 'snipatuit-pond-wealth-rochester', 'financial_advisor', NULL, ARRAY['Rochester','MA','Plymouth'], NULL),

    -- ── Rockland ──
    ('Rockland Wealth Management', 'rockland-wealth-management-ma', 'financial_advisor', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Reed Pond Capital Partners', 'reed-pond-capital-rockland', 'financial_advisor', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),
    ('Union Street Financial Group', 'union-street-financial-rockland', 'financial_advisor', NULL, ARRAY['Rockland','MA','Plymouth'], NULL),

    -- ── Scituate (HNW) ──
    ('Scituate Wealth Partners', 'scituate-wealth-partners', 'financial_advisor', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Scituate Harbor Capital Advisors', 'scituate-harbor-capital', 'financial_advisor', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Minot Beach Financial Group', 'minot-beach-financial-scituate', 'financial_advisor', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('North Scituate Wealth Management', 'north-scituate-wealth', 'financial_advisor', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),
    ('Cohasset Narrows Capital', 'cohasset-narrows-capital-scituate', 'financial_advisor', NULL, ARRAY['Scituate','MA','Plymouth'], NULL),

    -- ── Wareham ──
    ('Wareham Financial Advisors', 'wareham-financial-advisors', 'financial_advisor', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Onset Bay Capital Partners', 'onset-bay-capital-wareham', 'financial_advisor', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),
    ('Tremont Nail Wealth Management', 'tremont-nail-wealth-wareham', 'financial_advisor', NULL, ARRAY['Wareham','MA','Plymouth'], NULL),

    -- ── West Bridgewater ──
    ('West Bridgewater Wealth Partners', 'west-bridgewater-wealth-partners', 'financial_advisor', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('Cochesett Capital Advisors', 'cochesett-capital-west-bridgewater', 'financial_advisor', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),
    ('War Memorial Park Financial', 'war-memorial-park-financial-west-bridgewater', 'financial_advisor', NULL, ARRAY['West Bridgewater','MA','Plymouth'], NULL),

    -- ── Whitman ──
    ('Whitman Financial Advisors', 'whitman-financial-advisors', 'financial_advisor', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Shumatuscacant Capital', 'shumatuscacant-capital-whitman', 'financial_advisor', NULL, ARRAY['Whitman','MA','Plymouth'], NULL),
    ('Whitman Center Wealth Partners', 'whitman-center-wealth', 'financial_advisor', NULL, ARRAY['Whitman','MA','Plymouth'], NULL)

ON CONFLICT (slug) DO UPDATE SET
    provider_type = EXCLUDED.provider_type,
    website = EXCLUDED.website,
    regions = EXCLUDED.regions;
