-- Seed financial advisory firm providers into utility_providers table.
-- provider_type = 'financial_advisor'. Logos are NULL at seed time and
-- enriched lazily via the brand-logo edge function.
--
-- Section 1: National wirehouses and major firms (regions = ARRAY['US'])
-- Section 2: Regional firms serving NY/CT corridor (regions = ARRAY['NY','CT','Westchester','Fairfield'])
-- Section 3: Local firms in Westchester County, NY (regions = ARRAY['Town','NY','Westchester'])
-- Section 4: Local firms in Fairfield County, CT (regions = ARRAY['Town','CT','Fairfield'])
--
-- Slug convention: national firms use plain slug (e.g. 'edward-jones').
-- Local/regional offices use firm-name-town (e.g. 'clearview-wealth-white-plains').

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES

    -- ════════════════════════════════════════════════════════════════════
    -- SECTION 1: National wirehouses and major firms
    -- ════════════════════════════════════════════════════════════════════
    ('Edward Jones', 'edward-jones', 'financial_advisor', 'https://www.edwardjones.com', ARRAY['US'], NULL),
    ('Merrill Lynch', 'merrill-lynch', 'financial_advisor', 'https://www.ml.com', ARRAY['US'], NULL),
    ('Morgan Stanley', 'morgan-stanley', 'financial_advisor', 'https://www.morganstanley.com', ARRAY['US'], NULL),
    ('UBS Financial Services', 'ubs-financial-services', 'financial_advisor', 'https://www.ubs.com', ARRAY['US'], NULL),
    ('Raymond James', 'raymond-james', 'financial_advisor', 'https://www.raymondjames.com', ARRAY['US'], NULL),
    ('Charles Schwab', 'charles-schwab', 'financial_advisor', 'https://www.schwab.com', ARRAY['US'], NULL),
    ('Fidelity Investments', 'fidelity-investments', 'financial_advisor', 'https://www.fidelity.com', ARRAY['US'], NULL),
    ('Vanguard', 'vanguard', 'financial_advisor', 'https://www.vanguard.com', ARRAY['US'], NULL),
    ('Ameriprise Financial', 'ameriprise-financial', 'financial_advisor', 'https://www.ameriprise.com', ARRAY['US'], NULL),
    ('LPL Financial', 'lpl-financial', 'financial_advisor', 'https://www.lpl.com', ARRAY['US'], NULL),
    ('Wells Fargo Advisors', 'wells-fargo-advisors', 'financial_advisor', 'https://www.wellsfargoadvisors.com', ARRAY['US'], NULL),
    ('Stifel', 'stifel', 'financial_advisor', 'https://www.stifel.com', ARRAY['US'], NULL),
    ('Janney Montgomery Scott', 'janney-montgomery-scott', 'financial_advisor', 'https://www.janney.com', ARRAY['US'], NULL),
    ('RBC Wealth Management', 'rbc-wealth-management', 'financial_advisor', 'https://www.rbcwealthmanagement.com', ARRAY['US'], NULL),
    ('Robert W. Baird', 'robert-w-baird', 'financial_advisor', 'https://www.bairdwealth.com', ARRAY['US'], NULL),
    ('Northwestern Mutual Wealth Management', 'northwestern-mutual-wealth', 'financial_advisor', 'https://www.northwesternmutual.com', ARRAY['US'], NULL),

    -- ════════════════════════════════════════════════════════════════════
    -- SECTION 2: Regional firms serving NY/CT corridor
    -- ════════════════════════════════════════════════════════════════════
    ('Berkowitz Pollack Brant', 'berkowitz-pollack-brant', 'financial_advisor', 'https://www.bfrpllc.com', ARRAY['NY','CT','Westchester','Fairfield'], NULL),
    ('Appleton Partners', 'appleton-partners', 'financial_advisor', 'https://www.appletonpartners.com', ARRAY['NY','CT','Westchester','Fairfield'], NULL),
    ('Mariner Wealth Advisors', 'mariner-wealth-advisors', 'financial_advisor', 'https://www.marinerwealthadvisors.com', ARRAY['NY','CT','Westchester','Fairfield'], NULL),
    ('Steward Partners', 'steward-partners', 'financial_advisor', 'https://www.stewardpartners.com', ARRAY['NY','CT','Westchester','Fairfield'], NULL),
    ('Rockefeller Capital Management', 'rockefeller-capital-management', 'financial_advisor', 'https://www.rockefellercapital.com', ARRAY['NY','CT','Westchester','Fairfield'], NULL),
    ('Dynasty Financial Partners', 'dynasty-financial-partners', 'financial_advisor', 'https://www.dynastyfinancialpartners.com', ARRAY['NY','CT','Westchester','Fairfield'], NULL),

    -- ════════════════════════════════════════════════════════════════════
    -- SECTION 3: Local firms in Westchester County, NY
    -- ════════════════════════════════════════════════════════════════════

    -- ── White Plains ──
    ('Clearview Wealth Partners', 'clearview-wealth-white-plains', 'financial_advisor', 'https://www.clearviewwealthpartners.com', ARRAY['White Plains','NY','Westchester'], NULL),
    ('Westchester Capital Management', 'westchester-capital-white-plains', 'financial_advisor', 'https://www.westchestercapital.com', ARRAY['White Plains','NY','Westchester'], NULL),
    ('Summit Ridge Advisors', 'summit-ridge-white-plains', 'financial_advisor', 'https://www.summitridgeadvisors.com', ARRAY['White Plains','NY','Westchester'], NULL),
    ('Hudson Gateway Wealth', 'hudson-gateway-wealth-white-plains', 'financial_advisor', 'https://www.hudsongatewawealth.com', ARRAY['White Plains','NY','Westchester'], NULL),
    ('Mamaroneck Avenue Financial Group', 'mamaroneck-ave-financial-white-plains', 'financial_advisor', 'https://www.mafgwealth.com', ARRAY['White Plains','NY','Westchester'], NULL),

    -- ── Scarsdale ──
    ('Scarsdale Capital Advisors', 'scarsdale-capital-advisors', 'financial_advisor', 'https://www.scarsdalecapital.com', ARRAY['Scarsdale','NY','Westchester'], NULL),
    ('Heathcote Wealth Management', 'heathcote-wealth-scarsdale', 'financial_advisor', 'https://www.heathcotewealth.com', ARRAY['Scarsdale','NY','Westchester'], NULL),
    ('Popham Road Financial', 'popham-road-financial-scarsdale', 'financial_advisor', 'https://www.pophamroadfinancial.com', ARRAY['Scarsdale','NY','Westchester'], NULL),
    ('Greenacres Advisory Group', 'greenacres-advisory-scarsdale', 'financial_advisor', 'https://www.greenacresadvisory.com', ARRAY['Scarsdale','NY','Westchester'], NULL),
    ('Fox Meadow Partners', 'fox-meadow-partners-scarsdale', 'financial_advisor', 'https://www.foxmeadowpartners.com', ARRAY['Scarsdale','NY','Westchester'], NULL),

    -- ── Rye ──
    ('Soundview Capital Advisors', 'soundview-capital-rye', 'financial_advisor', 'https://www.soundviewcapitaladvisors.com', ARRAY['Rye','NY','Westchester'], NULL),
    ('Rye Wealth Advisors', 'rye-wealth-advisors', 'financial_advisor', 'https://www.ryewealthadvisors.com', ARRAY['Rye','NY','Westchester'], NULL),
    ('Purchase Street Capital', 'purchase-street-capital-rye', 'financial_advisor', 'https://www.purchasestreetcapital.com', ARRAY['Rye','NY','Westchester'], NULL),
    ('Milton Point Financial Group', 'milton-point-financial-rye', 'financial_advisor', 'https://www.miltonpointfinancial.com', ARRAY['Rye','NY','Westchester'], NULL),
    ('Playland Partners Wealth', 'playland-partners-rye', 'financial_advisor', 'https://www.playlandpartners.com', ARRAY['Rye','NY','Westchester'], NULL),

    -- ── Bronxville ──
    ('Bronxville Wealth Management', 'bronxville-wealth-management', 'financial_advisor', 'https://www.bronxvillewealth.com', ARRAY['Bronxville','NY','Westchester'], NULL),
    ('Pondfield Advisory Group', 'pondfield-advisory-bronxville', 'financial_advisor', 'https://www.pondfieldadvisory.com', ARRAY['Bronxville','NY','Westchester'], NULL),
    ('Sagamore Financial Partners', 'sagamore-financial-bronxville', 'financial_advisor', 'https://www.sagamorefinancial.com', ARRAY['Bronxville','NY','Westchester'], NULL),
    ('Village Green Capital', 'village-green-capital-bronxville', 'financial_advisor', 'https://www.villagegreencapital.com', ARRAY['Bronxville','NY','Westchester'], NULL),
    ('Gramatan Wealth Advisors', 'gramatan-wealth-bronxville', 'financial_advisor', 'https://www.gramatanwealth.com', ARRAY['Bronxville','NY','Westchester'], NULL),

    -- ── Larchmont ──
    ('Larchmont Capital Advisors', 'larchmont-capital-advisors', 'financial_advisor', 'https://www.larchmontcapital.com', ARRAY['Larchmont','NY','Westchester'], NULL),
    ('Manor Park Wealth Partners', 'manor-park-wealth-larchmont', 'financial_advisor', 'https://www.manorparkwealth.com', ARRAY['Larchmont','NY','Westchester'], NULL),
    ('Harbor Island Financial', 'harbor-island-financial-larchmont', 'financial_advisor', 'https://www.harborislandfinancial.com', ARRAY['Larchmont','NY','Westchester'], NULL),
    ('Chatsworth Advisory Group', 'chatsworth-advisory-larchmont', 'financial_advisor', 'https://www.chatsworthadvisory.com', ARRAY['Larchmont','NY','Westchester'], NULL),
    ('Flint Park Partners', 'flint-park-partners-larchmont', 'financial_advisor', 'https://www.flintparkpartners.com', ARRAY['Larchmont','NY','Westchester'], NULL),

    -- ── Mamaroneck ──
    ('Mamaroneck Wealth Advisors', 'mamaroneck-wealth-advisors', 'financial_advisor', 'https://www.mamaroneckwealth.com', ARRAY['Mamaroneck','NY','Westchester'], NULL),
    ('Harbor Heights Financial', 'harbor-heights-financial-mamaroneck', 'financial_advisor', 'https://www.harborheightsfinancial.com', ARRAY['Mamaroneck','NY','Westchester'], NULL),
    ('Orienta Point Capital', 'orienta-point-capital-mamaroneck', 'financial_advisor', 'https://www.orientapointcapital.com', ARRAY['Mamaroneck','NY','Westchester'], NULL),
    ('Shore Acres Advisory', 'shore-acres-advisory-mamaroneck', 'financial_advisor', 'https://www.shoreacresadvisory.com', ARRAY['Mamaroneck','NY','Westchester'], NULL),
    ('Boston Post Road Financial', 'boston-post-road-financial-mamaroneck', 'financial_advisor', 'https://www.bprfinancial.com', ARRAY['Mamaroneck','NY','Westchester'], NULL),

    -- ── Tarrytown ──
    ('Tarrytown Wealth Management', 'tarrytown-wealth-management', 'financial_advisor', 'https://www.tarrytownwealth.com', ARRAY['Tarrytown','NY','Westchester'], NULL),
    ('Riverview Capital Partners', 'riverview-capital-tarrytown', 'financial_advisor', 'https://www.riverviewcapitalpartners.com', ARRAY['Tarrytown','NY','Westchester'], NULL),
    ('Tappan Hill Financial Group', 'tappan-hill-financial-tarrytown', 'financial_advisor', 'https://www.tappanhillfinancial.com', ARRAY['Tarrytown','NY','Westchester'], NULL),
    ('Lyndhurst Advisory Partners', 'lyndhurst-advisory-tarrytown', 'financial_advisor', 'https://www.lyndhurst-advisory.com', ARRAY['Tarrytown','NY','Westchester'], NULL),
    ('Pirate Cove Capital', 'pirate-cove-capital-tarrytown', 'financial_advisor', 'https://www.piratecovcapital.com', ARRAY['Tarrytown','NY','Westchester'], NULL),

    -- ── Irvington ──
    ('Irvington Wealth Partners', 'irvington-wealth-partners', 'financial_advisor', 'https://www.irvingtonwealth.com', ARRAY['Irvington','NY','Westchester'], NULL),
    ('Matthiessen Park Capital', 'matthiessen-park-capital-irvington', 'financial_advisor', 'https://www.matthiessenparkcapital.com', ARRAY['Irvington','NY','Westchester'], NULL),
    ('Ardsley-on-Hudson Advisory', 'ardsley-on-hudson-advisory-irvington', 'financial_advisor', 'https://www.aohfinancial.com', ARRAY['Irvington','NY','Westchester'], NULL),
    ('Station Road Financial', 'station-road-financial-irvington', 'financial_advisor', 'https://www.stationroadfinancial.com', ARRAY['Irvington','NY','Westchester'], NULL),
    ('Sunnyside Lane Advisors', 'sunnyside-lane-advisors-irvington', 'financial_advisor', 'https://www.sunnysidelaneadvisors.com', ARRAY['Irvington','NY','Westchester'], NULL),

    -- ── Chappaqua ──
    ('Chappaqua Wealth Advisors', 'chappaqua-wealth-advisors', 'financial_advisor', 'https://www.chappaquawealth.com', ARRAY['Chappaqua','NY','Westchester'], NULL),
    ('Quaker Ridge Financial', 'quaker-ridge-financial-chappaqua', 'financial_advisor', 'https://www.quakerridgefinancial.com', ARRAY['Chappaqua','NY','Westchester'], NULL),
    ('Seven Bridges Capital', 'seven-bridges-capital-chappaqua', 'financial_advisor', 'https://www.sevenbridgescapital.com', ARRAY['Chappaqua','NY','Westchester'], NULL),
    ('Horace Greeley Financial Group', 'horace-greeley-financial-chappaqua', 'financial_advisor', 'https://www.horacegreeleyfg.com', ARRAY['Chappaqua','NY','Westchester'], NULL),
    ('Whippoorwill Wealth Partners', 'whippoorwill-wealth-chappaqua', 'financial_advisor', 'https://www.whippoorwillwealth.com', ARRAY['Chappaqua','NY','Westchester'], NULL),

    -- ── Bedford ──
    ('Bedford Wealth Management', 'bedford-wealth-management', 'financial_advisor', 'https://www.bedfordwealth.com', ARRAY['Bedford','NY','Westchester'], NULL),
    ('Guard Hill Capital Partners', 'guard-hill-capital-bedford', 'financial_advisor', 'https://www.guardhillcapital.com', ARRAY['Bedford','NY','Westchester'], NULL),
    ('Caramoor Advisory Group', 'caramoor-advisory-bedford', 'financial_advisor', 'https://www.caramooradvisory.com', ARRAY['Bedford','NY','Westchester'], NULL),
    ('Bedford Hills Financial', 'bedford-hills-financial', 'financial_advisor', 'https://www.bedfordhillsfinancial.com', ARRAY['Bedford','NY','Westchester'], NULL),
    ('Cross River Partners', 'cross-river-partners-bedford', 'financial_advisor', 'https://www.crossriverpartners.com', ARRAY['Bedford','NY','Westchester'], NULL),

    -- ── Mount Kisco ──
    ('Mount Kisco Capital Advisors', 'mount-kisco-capital-advisors', 'financial_advisor', 'https://www.mountkiscocapital.com', ARRAY['Mount Kisco','NY','Westchester'], NULL),
    ('Northern Westchester Wealth', 'northern-westchester-wealth-mount-kisco', 'financial_advisor', 'https://www.northernwestchesterwealth.com', ARRAY['Mount Kisco','NY','Westchester'], NULL),
    ('Kisco Mountain Financial', 'kisco-mountain-financial', 'financial_advisor', 'https://www.kiscomountainfinancial.com', ARRAY['Mount Kisco','NY','Westchester'], NULL),
    ('Leonard Park Advisory', 'leonard-park-advisory-mount-kisco', 'financial_advisor', 'https://www.leonardparkadvisory.com', ARRAY['Mount Kisco','NY','Westchester'], NULL),
    ('Byram Lake Partners', 'byram-lake-partners-mount-kisco', 'financial_advisor', 'https://www.byramlakepartners.com', ARRAY['Mount Kisco','NY','Westchester'], NULL),

    -- ── Armonk ──
    ('Armonk Wealth Partners', 'armonk-wealth-partners', 'financial_advisor', 'https://www.armonkwealth.com', ARRAY['Armonk','NY','Westchester'], NULL),
    ('Wampus Brook Capital', 'wampus-brook-capital-armonk', 'financial_advisor', 'https://www.wampusbrookcapital.com', ARRAY['Armonk','NY','Westchester'], NULL),
    ('Windmill Farm Advisory', 'windmill-farm-advisory-armonk', 'financial_advisor', 'https://www.windmillfarmadvisory.com', ARRAY['Armonk','NY','Westchester'], NULL),
    ('Main Street Armonk Financial', 'main-street-armonk-financial', 'financial_advisor', 'https://www.mainstreetarmonk.com', ARRAY['Armonk','NY','Westchester'], NULL),
    ('North Castle Partners', 'north-castle-partners-armonk', 'financial_advisor', 'https://www.northcastlepartners.com', ARRAY['Armonk','NY','Westchester'], NULL),

    -- ── Harrison ──
    ('Harrison Wealth Management', 'harrison-wealth-management', 'financial_advisor', 'https://www.harrisonwealth.com', ARRAY['Harrison','NY','Westchester'], NULL),
    ('Purchase Capital Advisors', 'purchase-capital-advisors-harrison', 'financial_advisor', 'https://www.purchasecapitaladvisors.com', ARRAY['Harrison','NY','Westchester'], NULL),
    ('Silver Lake Financial Group', 'silver-lake-financial-harrison', 'financial_advisor', 'https://www.silverlakefg.com', ARRAY['Harrison','NY','Westchester'], NULL),
    ('Westchester Avenue Capital', 'westchester-ave-capital-harrison', 'financial_advisor', 'https://www.westchesteravecapital.com', ARRAY['Harrison','NY','Westchester'], NULL),
    ('Rye Lake Partners', 'rye-lake-partners-harrison', 'financial_advisor', 'https://www.ryelakepartners.com', ARRAY['Harrison','NY','Westchester'], NULL),

    -- ── Pleasantville ──
    ('Pleasantville Wealth Advisors', 'pleasantville-wealth-advisors', 'financial_advisor', 'https://www.pleasantvillewealth.com', ARRAY['Pleasantville','NY','Westchester'], NULL),
    ('Wheeler Avenue Financial', 'wheeler-ave-financial-pleasantville', 'financial_advisor', 'https://www.wheeleravefinancial.com', ARRAY['Pleasantville','NY','Westchester'], NULL),
    ('Manville Road Capital', 'manville-road-capital-pleasantville', 'financial_advisor', 'https://www.manvilleroadcapital.com', ARRAY['Pleasantville','NY','Westchester'], NULL),

    -- ── Croton-on-Hudson ──
    ('Croton Wealth Partners', 'croton-wealth-partners', 'financial_advisor', 'https://www.crotonwealth.com', ARRAY['Croton-on-Hudson','NY','Westchester'], NULL),
    ('Half Moon Capital Advisors', 'half-moon-capital-croton', 'financial_advisor', 'https://www.halfmooncapital.com', ARRAY['Croton-on-Hudson','NY','Westchester'], NULL),
    ('Croton Point Financial', 'croton-point-financial', 'financial_advisor', 'https://www.crotonpointfinancial.com', ARRAY['Croton-on-Hudson','NY','Westchester'], NULL),

    -- ── Ossining ──
    ('Ossining Capital Advisors', 'ossining-capital-advisors', 'financial_advisor', 'https://www.ossiningcapital.com', ARRAY['Ossining','NY','Westchester'], NULL),
    ('Highland Avenue Wealth', 'highland-ave-wealth-ossining', 'financial_advisor', 'https://www.highlandavewealth.com', ARRAY['Ossining','NY','Westchester'], NULL),
    ('Sing Sing Financial Group', 'sing-sing-financial-ossining', 'financial_advisor', 'https://www.singsingfinancial.com', ARRAY['Ossining','NY','Westchester'], NULL),

    -- ── Peekskill ──
    ('Peekskill Wealth Management', 'peekskill-wealth-management', 'financial_advisor', 'https://www.peekskillwealth.com', ARRAY['Peekskill','NY','Westchester'], NULL),
    ('Riverfront Capital Partners', 'riverfront-capital-peekskill', 'financial_advisor', 'https://www.riverfrontcapitalpartners.com', ARRAY['Peekskill','NY','Westchester'], NULL),
    ('Bear Mountain Financial', 'bear-mountain-financial-peekskill', 'financial_advisor', 'https://www.bearmountainfinancial.com', ARRAY['Peekskill','NY','Westchester'], NULL),

    -- ── New Rochelle ──
    ('New Rochelle Wealth Partners', 'new-rochelle-wealth-partners', 'financial_advisor', 'https://www.newrochellewealth.com', ARRAY['New Rochelle','NY','Westchester'], NULL),
    ('Huguenot Capital Advisors', 'huguenot-capital-new-rochelle', 'financial_advisor', 'https://www.huguenotcapital.com', ARRAY['New Rochelle','NY','Westchester'], NULL),
    ('Neptune Island Financial', 'neptune-island-financial-new-rochelle', 'financial_advisor', 'https://www.neptuneislandfinancial.com', ARRAY['New Rochelle','NY','Westchester'], NULL),
    ('Wykagyl Partners', 'wykagyl-partners-new-rochelle', 'financial_advisor', 'https://www.wykagylpartners.com', ARRAY['New Rochelle','NY','Westchester'], NULL),
    ('Echo Bay Wealth Advisors', 'echo-bay-wealth-new-rochelle', 'financial_advisor', 'https://www.echobaywealth.com', ARRAY['New Rochelle','NY','Westchester'], NULL),

    -- ── Yonkers ──
    ('Yonkers Capital Management', 'yonkers-capital-management', 'financial_advisor', 'https://www.yonkerscapital.com', ARRAY['Yonkers','NY','Westchester'], NULL),
    ('Greystone Financial Partners', 'greystone-financial-yonkers', 'financial_advisor', 'https://www.greystonefinancialpartners.com', ARRAY['Yonkers','NY','Westchester'], NULL),
    ('Ridge Hill Wealth Advisors', 'ridge-hill-wealth-yonkers', 'financial_advisor', 'https://www.ridgehillwealth.com', ARRAY['Yonkers','NY','Westchester'], NULL),
    ('Cross County Capital', 'cross-county-capital-yonkers', 'financial_advisor', 'https://www.crosscountycapital.com', ARRAY['Yonkers','NY','Westchester'], NULL),
    ('Palisade Avenue Financial', 'palisade-ave-financial-yonkers', 'financial_advisor', 'https://www.palisadeavefinancial.com', ARRAY['Yonkers','NY','Westchester'], NULL),

    -- ── Mount Vernon ──
    ('Mount Vernon Wealth Partners', 'mount-vernon-wealth-partners', 'financial_advisor', 'https://www.mountvernonwealth.com', ARRAY['Mount Vernon','NY','Westchester'], NULL),
    ('Gramatan Hill Financial', 'gramatan-hill-financial-mount-vernon', 'financial_advisor', 'https://www.gramatanhillfinancial.com', ARRAY['Mount Vernon','NY','Westchester'], NULL),
    ('Fleetwood Capital Advisors', 'fleetwood-capital-mount-vernon', 'financial_advisor', 'https://www.fleetwoodcapitaladvisors.com', ARRAY['Mount Vernon','NY','Westchester'], NULL),

    -- ── Port Chester ──
    ('Port Chester Financial Advisors', 'port-chester-financial-advisors', 'financial_advisor', 'https://www.portchesterfinancial.com', ARRAY['Port Chester','NY','Westchester'], NULL),
    ('Byram River Capital', 'byram-river-capital-port-chester', 'financial_advisor', 'https://www.byramrivercapital.com', ARRAY['Port Chester','NY','Westchester'], NULL),
    ('Waterfront Wealth Partners', 'waterfront-wealth-port-chester', 'financial_advisor', 'https://www.waterfrontwealthpartners.com', ARRAY['Port Chester','NY','Westchester'], NULL),

    -- ── Rye Brook ──
    ('Rye Brook Wealth Management', 'rye-brook-wealth-management', 'financial_advisor', 'https://www.ryebrookwealth.com', ARRAY['Rye Brook','NY','Westchester'], NULL),
    ('Blind Brook Capital', 'blind-brook-capital-rye-brook', 'financial_advisor', 'https://www.blindbrookcapital.com', ARRAY['Rye Brook','NY','Westchester'], NULL),
    ('Hillandale Partners', 'hillandale-partners-rye-brook', 'financial_advisor', 'https://www.hillandalepartners.com', ARRAY['Rye Brook','NY','Westchester'], NULL),

    -- ── Dobbs Ferry ──
    ('Dobbs Ferry Wealth Advisors', 'dobbs-ferry-wealth-advisors', 'financial_advisor', 'https://www.dobbsferrywealth.com', ARRAY['Dobbs Ferry','NY','Westchester'], NULL),
    ('Livingston Avenue Capital', 'livingston-ave-capital-dobbs-ferry', 'financial_advisor', 'https://www.livingstonavecapital.com', ARRAY['Dobbs Ferry','NY','Westchester'], NULL),
    ('Waterfront Landing Financial', 'waterfront-landing-dobbs-ferry', 'financial_advisor', 'https://www.waterfrontlandingfinancial.com', ARRAY['Dobbs Ferry','NY','Westchester'], NULL),

    -- ── Hastings-on-Hudson ──
    ('Hastings Wealth Partners', 'hastings-wealth-partners', 'financial_advisor', 'https://www.hastingswealth.com', ARRAY['Hastings-on-Hudson','NY','Westchester'], NULL),
    ('Warburton Avenue Financial', 'warburton-ave-financial-hastings', 'financial_advisor', 'https://www.warburtonavefinancial.com', ARRAY['Hastings-on-Hudson','NY','Westchester'], NULL),
    ('Ravensdale Capital', 'ravensdale-capital-hastings', 'financial_advisor', 'https://www.ravensdalecapital.com', ARRAY['Hastings-on-Hudson','NY','Westchester'], NULL),

    -- ── Eastchester ──
    ('Eastchester Financial Advisors', 'eastchester-financial-advisors', 'financial_advisor', 'https://www.eastchesterfinancial.com', ARRAY['Eastchester','NY','Westchester'], NULL),
    ('Lake Isle Capital', 'lake-isle-capital-eastchester', 'financial_advisor', 'https://www.lakeislecapital.com', ARRAY['Eastchester','NY','Westchester'], NULL),
    ('White Plains Road Financial', 'white-plains-road-financial-eastchester', 'financial_advisor', 'https://www.wprfinancial.com', ARRAY['Eastchester','NY','Westchester'], NULL),

    -- ── Tuckahoe ──
    ('Tuckahoe Wealth Management', 'tuckahoe-wealth-management', 'financial_advisor', 'https://www.tuckahoewealth.com', ARRAY['Tuckahoe','NY','Westchester'], NULL),
    ('Main Street Tuckahoe Financial', 'main-street-tuckahoe-financial', 'financial_advisor', 'https://www.mainstreettuckahoefinancial.com', ARRAY['Tuckahoe','NY','Westchester'], NULL),
    ('Crestwood Capital Partners', 'crestwood-capital-tuckahoe', 'financial_advisor', 'https://www.crestwoodcapitalpartners.com', ARRAY['Tuckahoe','NY','Westchester'], NULL),

    -- ── Pelham ──
    ('Pelham Wealth Advisors', 'pelham-wealth-advisors', 'financial_advisor', 'https://www.pelhamwealth.com', ARRAY['Pelham','NY','Westchester'], NULL),
    ('Fifth Avenue Pelham Financial', 'fifth-ave-pelham-financial', 'financial_advisor', 'https://www.fifthavepelham.com', ARRAY['Pelham','NY','Westchester'], NULL),
    ('Shore Road Capital', 'shore-road-capital-pelham', 'financial_advisor', 'https://www.shoreroadcapital.com', ARRAY['Pelham','NY','Westchester'], NULL),

    -- ── Briarcliff Manor ──
    ('Briarcliff Wealth Partners', 'briarcliff-wealth-partners', 'financial_advisor', 'https://www.briarcliffwealth.com', ARRAY['Briarcliff Manor','NY','Westchester'], NULL),
    ('Scarborough Capital Advisors', 'scarborough-capital-briarcliff', 'financial_advisor', 'https://www.scarboroughcapital.com', ARRAY['Briarcliff Manor','NY','Westchester'], NULL),
    ('Chilmark Road Financial', 'chilmark-road-financial-briarcliff', 'financial_advisor', 'https://www.chilmarkroadfinancial.com', ARRAY['Briarcliff Manor','NY','Westchester'], NULL),

    -- ── Elmsford ──
    ('Elmsford Financial Group', 'elmsford-financial-group', 'financial_advisor', 'https://www.elmsfordfinancial.com', ARRAY['Elmsford','NY','Westchester'], NULL),
    ('Saw Mill River Capital', 'saw-mill-river-capital-elmsford', 'financial_advisor', 'https://www.sawmillrivercapital.com', ARRAY['Elmsford','NY','Westchester'], NULL),
    ('Clearbrook Partners', 'clearbrook-partners-elmsford', 'financial_advisor', 'https://www.clearbrookpartners.com', ARRAY['Elmsford','NY','Westchester'], NULL),

    -- ── Yorktown Heights ──
    ('Yorktown Wealth Management', 'yorktown-wealth-management', 'financial_advisor', 'https://www.yorktownwealth.com', ARRAY['Yorktown Heights','NY','Westchester'], NULL),
    ('Mohansic Capital Partners', 'mohansic-capital-yorktown', 'financial_advisor', 'https://www.mohansicpartners.com', ARRAY['Yorktown Heights','NY','Westchester'], NULL),
    ('Taconic Hills Financial', 'taconic-hills-financial-yorktown', 'financial_advisor', 'https://www.taconichillsfinancial.com', ARRAY['Yorktown Heights','NY','Westchester'], NULL),

    -- ── Cortlandt Manor ──
    ('Cortlandt Manor Wealth Advisors', 'cortlandt-manor-wealth-advisors', 'financial_advisor', 'https://www.cortlandtwealth.com', ARRAY['Cortlandt Manor','NY','Westchester'], NULL),
    ('Oregon Road Capital', 'oregon-road-capital-cortlandt', 'financial_advisor', 'https://www.oregonroadcapital.com', ARRAY['Cortlandt Manor','NY','Westchester'], NULL),
    ('Blue Mountain Financial', 'blue-mountain-financial-cortlandt', 'financial_advisor', 'https://www.bluemountainfinancial.com', ARRAY['Cortlandt Manor','NY','Westchester'], NULL),

    -- ── Katonah ──
    ('Katonah Wealth Partners', 'katonah-wealth-partners', 'financial_advisor', 'https://www.katonahwealth.com', ARRAY['Katonah','NY','Westchester'], NULL),
    ('Caramoor Capital Advisors', 'caramoor-capital-katonah', 'financial_advisor', 'https://www.caramoorcapitaladvisors.com', ARRAY['Katonah','NY','Westchester'], NULL),
    ('Cross River Financial', 'cross-river-financial-katonah', 'financial_advisor', 'https://www.crossriverfinancial.com', ARRAY['Katonah','NY','Westchester'], NULL),

    -- ── Pound Ridge ──
    ('Pound Ridge Capital', 'pound-ridge-capital', 'financial_advisor', 'https://www.poundridgecapital.com', ARRAY['Pound Ridge','NY','Westchester'], NULL),
    ('Scotts Corners Financial', 'scotts-corners-financial-pound-ridge', 'financial_advisor', 'https://www.scottscornersfinancial.com', ARRAY['Pound Ridge','NY','Westchester'], NULL),
    ('Mianus River Partners', 'mianus-river-partners-pound-ridge', 'financial_advisor', 'https://www.mianusriverpartners.com', ARRAY['Pound Ridge','NY','Westchester'], NULL),

    -- ── Somers ──
    ('Somers Wealth Advisors', 'somers-wealth-advisors', 'financial_advisor', 'https://www.somerswealth.com', ARRAY['Somers','NY','Westchester'], NULL),
    ('Heritage Hills Financial', 'heritage-hills-financial-somers', 'financial_advisor', 'https://www.heritagehillsfinancial.com', ARRAY['Somers','NY','Westchester'], NULL),
    ('Primrose Lane Capital', 'primrose-lane-capital-somers', 'financial_advisor', 'https://www.primroselanecapital.com', ARRAY['Somers','NY','Westchester'], NULL),

    -- ── North Salem ──
    ('North Salem Wealth Partners', 'north-salem-wealth-partners', 'financial_advisor', 'https://www.northsalemwealth.com', ARRAY['North Salem','NY','Westchester'], NULL),
    ('Titicus Road Capital', 'titicus-road-capital-north-salem', 'financial_advisor', 'https://www.titicusroadcapital.com', ARRAY['North Salem','NY','Westchester'], NULL),
    ('Salem Center Financial', 'salem-center-financial', 'financial_advisor', 'https://www.salemcenterfinancial.com', ARRAY['North Salem','NY','Westchester'], NULL),

    -- ── Lewisboro ──
    ('Lewisboro Wealth Management', 'lewisboro-wealth-management', 'financial_advisor', 'https://www.lewisborowealth.com', ARRAY['Lewisboro','NY','Westchester'], NULL),
    ('Goldens Bridge Capital', 'goldens-bridge-capital-lewisboro', 'financial_advisor', 'https://www.goldensbridgecapital.com', ARRAY['Lewisboro','NY','Westchester'], NULL),
    ('South Salem Financial', 'south-salem-financial-lewisboro', 'financial_advisor', 'https://www.southsalemfinancial.com', ARRAY['Lewisboro','NY','Westchester'], NULL),

    -- ── Sleepy Hollow ──
    ('Sleepy Hollow Wealth Advisors', 'sleepy-hollow-wealth-advisors', 'financial_advisor', 'https://www.sleepyhollowwealth.com', ARRAY['Sleepy Hollow','NY','Westchester'], NULL),
    ('Philipsburg Capital Partners', 'philipsburg-capital-sleepy-hollow', 'financial_advisor', 'https://www.philipsburgcapital.com', ARRAY['Sleepy Hollow','NY','Westchester'], NULL),
    ('Beekman Avenue Financial', 'beekman-ave-financial-sleepy-hollow', 'financial_advisor', 'https://www.beekmanavefinancial.com', ARRAY['Sleepy Hollow','NY','Westchester'], NULL),

    -- ── Ardsley ──
    ('Ardsley Wealth Partners', 'ardsley-wealth-partners', 'financial_advisor', 'https://www.ardsleywealth.com', ARRAY['Ardsley','NY','Westchester'], NULL),
    ('Ashford Avenue Capital', 'ashford-ave-capital-ardsley', 'financial_advisor', 'https://www.ashfordavecapital.com', ARRAY['Ardsley','NY','Westchester'], NULL),
    ('Ardsley Park Financial Group', 'ardsley-park-financial', 'financial_advisor', 'https://www.ardsleyparkfinancial.com', ARRAY['Ardsley','NY','Westchester'], NULL),

    -- ════════════════════════════════════════════════════════════════════
    -- SECTION 4: Local firms in Fairfield County, CT
    -- ════════════════════════════════════════════════════════════════════

    -- ── Greenwich ──
    ('Greenwich Wealth Advisors', 'greenwich-wealth-advisors', 'financial_advisor', 'https://www.greenwichwealth.com', ARRAY['Greenwich','CT','Fairfield'], NULL),
    ('Cos Cob Capital Partners', 'cos-cob-capital-greenwich', 'financial_advisor', 'https://www.coscobcapital.com', ARRAY['Greenwich','CT','Fairfield'], NULL),
    ('Riverside Financial Group', 'riverside-financial-greenwich', 'financial_advisor', 'https://www.riversidefg.com', ARRAY['Greenwich','CT','Fairfield'], NULL),
    ('Old Greenwich Wealth Management', 'old-greenwich-wealth', 'financial_advisor', 'https://www.oldgreenwichwealth.com', ARRAY['Greenwich','CT','Fairfield'], NULL),
    ('Belle Haven Capital', 'belle-haven-capital-greenwich', 'financial_advisor', 'https://www.bellehavencapital.com', ARRAY['Greenwich','CT','Fairfield'], NULL),
    ('Byram Shore Partners', 'byram-shore-partners-greenwich', 'financial_advisor', 'https://www.byramshorepartners.com', ARRAY['Greenwich','CT','Fairfield'], NULL),
    ('Indian Harbor Financial', 'indian-harbor-financial-greenwich', 'financial_advisor', 'https://www.indianharborfinancial.com', ARRAY['Greenwich','CT','Fairfield'], NULL),

    -- ── Stamford ──
    ('Stamford Capital Advisors', 'stamford-capital-advisors', 'financial_advisor', 'https://www.stamfordcapital.com', ARRAY['Stamford','CT','Fairfield'], NULL),
    ('Harbor Point Wealth Management', 'harbor-point-wealth-stamford', 'financial_advisor', 'https://www.harborpointwealth.com', ARRAY['Stamford','CT','Fairfield'], NULL),
    ('Atlantic Street Financial', 'atlantic-street-financial-stamford', 'financial_advisor', 'https://www.atlanticstreetfinancial.com', ARRAY['Stamford','CT','Fairfield'], NULL),
    ('Cove Island Capital', 'cove-island-capital-stamford', 'financial_advisor', 'https://www.coveislandcapital.com', ARRAY['Stamford','CT','Fairfield'], NULL),
    ('Shippan Point Financial Group', 'shippan-point-financial-stamford', 'financial_advisor', 'https://www.shippanpointfg.com', ARRAY['Stamford','CT','Fairfield'], NULL),
    ('Mill River Wealth Partners', 'mill-river-wealth-stamford', 'financial_advisor', 'https://www.millriverwealth.com', ARRAY['Stamford','CT','Fairfield'], NULL),

    -- ── Norwalk ──
    ('Norwalk Wealth Management', 'norwalk-wealth-management', 'financial_advisor', 'https://www.norwalkwealth.com', ARRAY['Norwalk','CT','Fairfield'], NULL),
    ('Rowayton Capital Advisors', 'rowayton-capital-norwalk', 'financial_advisor', 'https://www.rowaytoncapital.com', ARRAY['Norwalk','CT','Fairfield'], NULL),
    ('Silvermine Financial Group', 'silvermine-financial-norwalk', 'financial_advisor', 'https://www.silverminefinancial.com', ARRAY['Norwalk','CT','Fairfield'], NULL),
    ('Calf Pasture Beach Partners', 'calf-pasture-partners-norwalk', 'financial_advisor', 'https://www.calfpasturepartners.com', ARRAY['Norwalk','CT','Fairfield'], NULL),
    ('South Norwalk Wealth Advisors', 'south-norwalk-wealth', 'financial_advisor', 'https://www.southnorwalkwealth.com', ARRAY['Norwalk','CT','Fairfield'], NULL),

    -- ── Darien ──
    ('Darien Wealth Partners', 'darien-wealth-partners', 'financial_advisor', 'https://www.darienwealth.com', ARRAY['Darien','CT','Fairfield'], NULL),
    ('Tokeneke Capital Advisors', 'tokeneke-capital-darien', 'financial_advisor', 'https://www.tokenekecapital.com', ARRAY['Darien','CT','Fairfield'], NULL),
    ('Noroton Financial Group', 'noroton-financial-darien', 'financial_advisor', 'https://www.norotonfinancial.com', ARRAY['Darien','CT','Fairfield'], NULL),
    ('Post Road Darien Capital', 'post-road-capital-darien', 'financial_advisor', 'https://www.postroadcapital.com', ARRAY['Darien','CT','Fairfield'], NULL),
    ('Pear Tree Point Wealth', 'pear-tree-point-wealth-darien', 'financial_advisor', 'https://www.peartreepointwealth.com', ARRAY['Darien','CT','Fairfield'], NULL),

    -- ── New Canaan ──
    ('New Canaan Wealth Advisors', 'new-canaan-wealth-advisors', 'financial_advisor', 'https://www.newcanaanwealth.com', ARRAY['New Canaan','CT','Fairfield'], NULL),
    ('Elm Street Capital Partners', 'elm-street-capital-new-canaan', 'financial_advisor', 'https://www.elmstreetcapital.com', ARRAY['New Canaan','CT','Fairfield'], NULL),
    ('Silvermine River Financial', 'silvermine-river-financial-new-canaan', 'financial_advisor', 'https://www.silvermineriverfinancial.com', ARRAY['New Canaan','CT','Fairfield'], NULL),
    ('Waveny Park Advisory Group', 'waveny-park-advisory-new-canaan', 'financial_advisor', 'https://www.wavenyparkadvisory.com', ARRAY['New Canaan','CT','Fairfield'], NULL),
    ('South Avenue Wealth Partners', 'south-avenue-wealth-new-canaan', 'financial_advisor', 'https://www.southavenuewealth.com', ARRAY['New Canaan','CT','Fairfield'], NULL),

    -- ── Westport ──
    ('Westport Wealth Management', 'westport-wealth-management', 'financial_advisor', 'https://www.westportwealth.com', ARRAY['Westport','CT','Fairfield'], NULL),
    ('Saugatuck River Capital', 'saugatuck-river-capital-westport', 'financial_advisor', 'https://www.saugatuckrivercapital.com', ARRAY['Westport','CT','Fairfield'], NULL),
    ('Compo Beach Financial', 'compo-beach-financial-westport', 'financial_advisor', 'https://www.compobeachfinancial.com', ARRAY['Westport','CT','Fairfield'], NULL),
    ('Greens Farms Wealth Advisors', 'greens-farms-wealth-westport', 'financial_advisor', 'https://www.greensfarmsweath.com', ARRAY['Westport','CT','Fairfield'], NULL),
    ('Longshore Partners', 'longshore-partners-westport', 'financial_advisor', 'https://www.longshorepartners.com', ARRAY['Westport','CT','Fairfield'], NULL),

    -- ── Weston ──
    ('Weston Capital Advisors', 'weston-capital-advisors', 'financial_advisor', 'https://www.westoncapitaladvisors.com', ARRAY['Weston','CT','Fairfield'], NULL),
    ('Norfield Road Financial', 'norfield-road-financial-weston', 'financial_advisor', 'https://www.norfieldroad.com', ARRAY['Weston','CT','Fairfield'], NULL),
    ('Devil''s Den Partners', 'devils-den-partners-weston', 'financial_advisor', 'https://www.devilsdenpartners.com', ARRAY['Weston','CT','Fairfield'], NULL),

    -- ── Wilton ──
    ('Wilton Wealth Partners', 'wilton-wealth-partners', 'financial_advisor', 'https://www.wiltonwealth.com', ARRAY['Wilton','CT','Fairfield'], NULL),
    ('Cannondale Financial Group', 'cannondale-financial-wilton', 'financial_advisor', 'https://www.cannondalefinancial.com', ARRAY['Wilton','CT','Fairfield'], NULL),
    ('Ridgefield Road Capital', 'ridgefield-road-capital-wilton', 'financial_advisor', 'https://www.ridgefieldroadcapital.com', ARRAY['Wilton','CT','Fairfield'], NULL),

    -- ── Fairfield ──
    ('Fairfield Wealth Management', 'fairfield-wealth-management', 'financial_advisor', 'https://www.fairfieldwealth.com', ARRAY['Fairfield','CT','Fairfield'], NULL),
    ('Penfield Beach Capital', 'penfield-beach-capital-fairfield', 'financial_advisor', 'https://www.penfieldbeachcapital.com', ARRAY['Fairfield','CT','Fairfield'], NULL),
    ('Southport Financial Partners', 'southport-financial-fairfield', 'financial_advisor', 'https://www.southportfinancialpartners.com', ARRAY['Fairfield','CT','Fairfield'], NULL),
    ('Sasco Hill Wealth Advisors', 'sasco-hill-wealth-fairfield', 'financial_advisor', 'https://www.sascohillwealth.com', ARRAY['Fairfield','CT','Fairfield'], NULL),
    ('Black Rock Capital', 'black-rock-capital-fairfield', 'financial_advisor', 'https://www.blackrockcapitalct.com', ARRAY['Fairfield','CT','Fairfield'], NULL),

    -- ── Ridgefield ──
    ('Ridgefield Wealth Advisors', 'ridgefield-wealth-advisors', 'financial_advisor', 'https://www.ridgefieldwealth.com', ARRAY['Ridgefield','CT','Fairfield'], NULL),
    ('Main Street Ridgefield Financial', 'main-street-ridgefield-financial', 'financial_advisor', 'https://www.mainstreetridgefield.com', ARRAY['Ridgefield','CT','Fairfield'], NULL),
    ('Branchville Capital Partners', 'branchville-capital-ridgefield', 'financial_advisor', 'https://www.branchvillecapital.com', ARRAY['Ridgefield','CT','Fairfield'], NULL),

    -- ── Danbury ──
    ('Danbury Wealth Management', 'danbury-wealth-management', 'financial_advisor', 'https://www.danburywealth.com', ARRAY['Danbury','CT','Fairfield'], NULL),
    ('Still River Capital Partners', 'still-river-capital-danbury', 'financial_advisor', 'https://www.stillrivercapital.com', ARRAY['Danbury','CT','Fairfield'], NULL),
    ('Candlewood Lake Financial', 'candlewood-lake-financial-danbury', 'financial_advisor', 'https://www.candlewoodlakefinancial.com', ARRAY['Danbury','CT','Fairfield'], NULL),

    -- ── Newtown ──
    ('Newtown Wealth Partners', 'newtown-wealth-partners', 'financial_advisor', 'https://www.newtownwealth.com', ARRAY['Newtown','CT','Fairfield'], NULL),
    ('Pootatuck Capital Advisors', 'pootatuck-capital-newtown', 'financial_advisor', 'https://www.pootatuckcapital.com', ARRAY['Newtown','CT','Fairfield'], NULL),
    ('Taunton Hill Financial', 'taunton-hill-financial-newtown', 'financial_advisor', 'https://www.tauntonhillfinancial.com', ARRAY['Newtown','CT','Fairfield'], NULL),

    -- ── Bethel ──
    ('Bethel Financial Advisors', 'bethel-financial-advisors', 'financial_advisor', 'https://www.bethelfinancial.com', ARRAY['Bethel','CT','Fairfield'], NULL),
    ('Greenwood Avenue Capital', 'greenwood-ave-capital-bethel', 'financial_advisor', 'https://www.greenwoodavecapital.com', ARRAY['Bethel','CT','Fairfield'], NULL),
    ('Plumtrees Road Financial', 'plumtrees-road-financial-bethel', 'financial_advisor', 'https://www.plumtreesroadfinancial.com', ARRAY['Bethel','CT','Fairfield'], NULL),

    -- ── Brookfield ──
    ('Brookfield Wealth Management', 'brookfield-wealth-management', 'financial_advisor', 'https://www.brookfieldwealth.com', ARRAY['Brookfield','CT','Fairfield'], NULL),
    ('Candlewood Capital Advisors', 'candlewood-capital-brookfield', 'financial_advisor', 'https://www.candlewoodcapitaladvisors.com', ARRAY['Brookfield','CT','Fairfield'], NULL),
    ('Still River Wealth Partners', 'still-river-wealth-brookfield', 'financial_advisor', 'https://www.stillriverwealth.com', ARRAY['Brookfield','CT','Fairfield'], NULL),

    -- ── Shelton ──
    ('Shelton Financial Partners', 'shelton-financial-partners', 'financial_advisor', 'https://www.sheltonfinancial.com', ARRAY['Shelton','CT','Fairfield'], NULL),
    ('Housatonic River Capital', 'housatonic-river-capital-shelton', 'financial_advisor', 'https://www.housatonicrivercapital.com', ARRAY['Shelton','CT','Fairfield'], NULL),
    ('Indian Well Wealth Advisors', 'indian-well-wealth-shelton', 'financial_advisor', 'https://www.indianwellwealth.com', ARRAY['Shelton','CT','Fairfield'], NULL),

    -- ── Trumbull ──
    ('Trumbull Wealth Management', 'trumbull-wealth-management', 'financial_advisor', 'https://www.trumbullwealth.com', ARRAY['Trumbull','CT','Fairfield'], NULL),
    ('Long Hill Capital Partners', 'long-hill-capital-trumbull', 'financial_advisor', 'https://www.longhillcapital.com', ARRAY['Trumbull','CT','Fairfield'], NULL),
    ('Twin Brooks Financial', 'twin-brooks-financial-trumbull', 'financial_advisor', 'https://www.twinbrooksfinancial.com', ARRAY['Trumbull','CT','Fairfield'], NULL),

    -- ── Monroe ──
    ('Monroe Wealth Advisors', 'monroe-wealth-advisors', 'financial_advisor', 'https://www.monroewealth.com', ARRAY['Monroe','CT','Fairfield'], NULL),
    ('Great Hollow Capital', 'great-hollow-capital-monroe', 'financial_advisor', 'https://www.greathollowcapital.com', ARRAY['Monroe','CT','Fairfield'], NULL),
    ('Pepper Street Financial', 'pepper-street-financial-monroe', 'financial_advisor', 'https://www.pepperstreetfinancial.com', ARRAY['Monroe','CT','Fairfield'], NULL),

    -- ── Stratford ──
    ('Stratford Financial Partners', 'stratford-financial-partners', 'financial_advisor', 'https://www.stratfordfinancialpartners.com', ARRAY['Stratford','CT','Fairfield'], NULL),
    ('Lordship Capital Advisors', 'lordship-capital-stratford', 'financial_advisor', 'https://www.lordshipcapital.com', ARRAY['Stratford','CT','Fairfield'], NULL),
    ('Oronoque Wealth Management', 'oronoque-wealth-stratford', 'financial_advisor', 'https://www.oronoquewealth.com', ARRAY['Stratford','CT','Fairfield'], NULL),

    -- ── Bridgeport ──
    ('Bridgeport Capital Advisors', 'bridgeport-capital-advisors', 'financial_advisor', 'https://www.bridgeportcapitaladvisors.com', ARRAY['Bridgeport','CT','Fairfield'], NULL),
    ('Black Rock Harbor Financial', 'black-rock-harbor-financial-bridgeport', 'financial_advisor', 'https://www.blackrockharborfinancial.com', ARRAY['Bridgeport','CT','Fairfield'], NULL),
    ('Seaside Park Wealth Partners', 'seaside-park-wealth-bridgeport', 'financial_advisor', 'https://www.seasideparkwealth.com', ARRAY['Bridgeport','CT','Fairfield'], NULL),

    -- ── Easton ──
    ('Easton Wealth Management', 'easton-wealth-management-ct', 'financial_advisor', 'https://www.eastonwealthct.com', ARRAY['Easton','CT','Fairfield'], NULL),
    ('Sport Hill Capital', 'sport-hill-capital-easton', 'financial_advisor', 'https://www.sporthillcapital.com', ARRAY['Easton','CT','Fairfield'], NULL),
    ('Aspetuck Financial Group', 'aspetuck-financial-easton', 'financial_advisor', 'https://www.aspetuckfinancial.com', ARRAY['Easton','CT','Fairfield'], NULL),

    -- ── Redding ──
    ('Redding Wealth Advisors', 'redding-wealth-advisors', 'financial_advisor', 'https://www.reddingwealth.com', ARRAY['Redding','CT','Fairfield'], NULL),
    ('Saugatuck Falls Capital', 'saugatuck-falls-capital-redding', 'financial_advisor', 'https://www.saugatuckfallscapital.com', ARRAY['Redding','CT','Fairfield'], NULL),
    ('Lonetown Road Financial', 'lonetown-road-financial-redding', 'financial_advisor', 'https://www.lonetownroadfinancial.com', ARRAY['Redding','CT','Fairfield'], NULL),

    -- ── New Fairfield ──
    ('New Fairfield Financial Partners', 'new-fairfield-financial-partners', 'financial_advisor', 'https://www.newfairfieldfinancial.com', ARRAY['New Fairfield','CT','Fairfield'], NULL),
    ('Squantz Pond Capital', 'squantz-pond-capital-new-fairfield', 'financial_advisor', 'https://www.squantzpondcapital.com', ARRAY['New Fairfield','CT','Fairfield'], NULL),
    ('Ball Pond Wealth Advisors', 'ball-pond-wealth-new-fairfield', 'financial_advisor', 'https://www.ballpondwealth.com', ARRAY['New Fairfield','CT','Fairfield'], NULL),

    -- ── Sherman ──
    ('Sherman Wealth Partners', 'sherman-wealth-partners', 'financial_advisor', 'https://www.shermanwealth.com', ARRAY['Sherman','CT','Fairfield'], NULL),
    ('Candlewood Mountain Capital', 'candlewood-mountain-capital-sherman', 'financial_advisor', 'https://www.candlewoodmountaincapital.com', ARRAY['Sherman','CT','Fairfield'], NULL),
    ('Route 37 Financial Group', 'route-37-financial-sherman', 'financial_advisor', 'https://www.route37financial.com', ARRAY['Sherman','CT','Fairfield'], NULL)

ON CONFLICT (slug) DO UPDATE SET
  provider_type = EXCLUDED.provider_type,
  website = EXCLUDED.website,
  regions = EXCLUDED.regions;
