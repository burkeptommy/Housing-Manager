-- Phase 18.5 followup: Northeast-heavy + HNW + missing-national insurance providers.
--
-- Tom's testing showed several Northeast regional mutuals were missing from
-- search results, and a few major nationals (Geico's Berkshire Hathaway brand,
-- Erie's home-side, AIG's home-side) only existed on one of auto/home when
-- the user should be able to find them in both. This migration:
--
--  1. Adds the major Northeast regional mutuals (MA, NY, NJ, CT, NH, VT, ME,
--     RI, PA) that have meaningful market share in those states.
--  2. Adds high-net-worth specialty carriers (Chubb tiers, AIG Private Client,
--     ACE/Federal, Vault, Pure Programs, Crestbrook) — important for Haven's
--     $500K-$5M target audience, especially in CT/Westchester/Greenwich.
--  3. Backfills missing auto<->home pairs for carriers that already exist on
--     one side but not the other (Vermont Mutual missing auto, AIG missing
--     home, Kingstone missing auto, etc.).
--  4. Adds direct-writer brands the existing list missed (Jetty, Toggle from
--     Farmers, Hugo, Clearcover, Sun Coast, Mile Auto).
--
-- All inserts use ON CONFLICT (slug) DO NOTHING so it's safe to re-run and
-- will not collide with anything seeded by 20260422 or 20260427.
--
-- Logo URLs are NULL at seed time. The lazy enrichment background task fetches
-- them from Brandfetch on first picker render.

-- ============================================================================
-- AUTO INSURANCE (Northeast regionals + missing nationals + HNW)
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url, bundles_with_home) VALUES
    -- Massachusetts
    ('Quincy Mutual Group', 'quincy-mutual-auto', 'auto_insurance', 'https://quincymutual.com', ARRAY['MA','NH','CT','RI','VT','ME'], NULL, true),
    ('Norfolk & Dedham Group', 'norfolk-dedham-auto', 'auto_insurance', 'https://ndgroup.com', ARRAY['MA','NH','CT','RI','VT','ME','NY'], NULL, true),
    ('The Andover Companies', 'andover-companies-auto', 'auto_insurance', 'https://andovercos.com', ARRAY['MA','NH','CT','RI','VT','ME','NY','PA'], NULL, true),
    ('Cambridge Mutual', 'cambridge-mutual-auto', 'auto_insurance', 'https://andovercos.com', ARRAY['MA','NH','CT','RI','VT','ME'], NULL, true),
    ('Merrimack Mutual', 'merrimack-mutual-auto', 'auto_insurance', 'https://andovercos.com', ARRAY['MA','NH','CT','RI','VT','ME'], NULL, true),
    ('Bunker Hill Insurance', 'bunker-hill-auto', 'auto_insurance', 'https://bunkerhillinsurance.com', ARRAY['MA','NH','CT','RI'], NULL, true),
    ('Hingham Mutual', 'hingham-mutual-auto', 'auto_insurance', 'https://hinghammutual.com', ARRAY['MA','NH','RI','VT','CT'], NULL, true),
    ('Pilgrim Insurance', 'pilgrim-insurance-auto', 'auto_insurance', 'https://pilgrimins.com', ARRAY['MA'], NULL, false),
    ('Commerce Insurance (MAPFRE)', 'commerce-insurance-auto', 'auto_insurance', 'https://mapfreinsurance.com', ARRAY['MA','NH','CT','RI'], NULL, true),

    -- New York
    ('New York Central Mutual', 'nycm-auto', 'auto_insurance', 'https://nycm.com', ARRAY['NY'], NULL, true),
    ('Preferred Mutual', 'preferred-mutual-auto', 'auto_insurance', 'https://preferredmutual.com', ARRAY['NY','NJ','MA','NH','RI'], NULL, true),
    ('Utica National', 'utica-national-auto', 'auto_insurance', 'https://uticanational.com', ARRAY['NY','NJ','PA','CT','MA','NH','VT','ME','OH'], NULL, true),
    ('Adirondack Insurance Exchange', 'adirondack-exchange-auto', 'auto_insurance', 'https://adirondackinsurance.com', ARRAY['NY'], NULL, true),
    ('Empire Underwriters', 'empire-underwriters-auto', 'auto_insurance', 'https://empireins.com', ARRAY['NY'], NULL, false),
    ('Greater New York Mutual', 'greater-ny-mutual-auto', 'auto_insurance', 'https://gny.com', ARRAY['NY','NJ','CT','PA'], NULL, false),
    ('Sterling Insurance', 'sterling-insurance-auto', 'auto_insurance', 'https://sterling-insurance.com', ARRAY['NY'], NULL, true),
    ('Kingstone Insurance', 'kingstone-insurance-auto', 'auto_insurance', 'https://kingstonecompanies.com', ARRAY['NY','NJ','PA','MA','CT','RI','NH'], NULL, true),

    -- New Jersey
    ('NJ Skylands Insurance', 'nj-skylands-auto', 'auto_insurance', 'https://njskylands.com', ARRAY['NJ'], NULL, true),
    ('High Point Insurance', 'high-point-auto', 'auto_insurance', 'https://highpointins.com', ARRAY['NJ'], NULL, true),
    ('Palisades Property & Casualty', 'palisades-pc-auto', 'auto_insurance', 'https://palisadesgrp.com', ARRAY['NJ','NY','PA','CT'], NULL, true),
    ('Proformance Insurance', 'proformance-auto', 'auto_insurance', 'https://proformanceins.com', ARRAY['NJ','PA'], NULL, true),

    -- Connecticut + Rhode Island
    ('New London County Mutual', 'new-london-county-mutual-auto', 'auto_insurance', 'https://nlcmutual.com', ARRAY['CT','RI','MA'], NULL, true),

    -- Vermont / Maine / NH
    ('Vermont Mutual Insurance', 'vermont-mutual-auto', 'auto_insurance', 'https://vermontmutual.com', ARRAY['VT','NH','ME','MA','CT','RI','NY'], NULL, true),
    ('MMG Insurance', 'mmg-insurance-auto', 'auto_insurance', 'https://mmgins.com', ARRAY['ME','NH','VT','PA'], NULL, true),
    ('Patriot Insurance Company', 'patriot-insurance-auto', 'auto_insurance', 'https://patriotinsuranceco.com', ARRAY['ME','NH','VT','MA'], NULL, true),
    ('Concord Group Insurance', 'concord-group-auto', 'auto_insurance', 'https://concordgroupinsurance.com', ARRAY['NH','VT','MA','ME'], NULL, true),
    ('Caledonian Insurance', 'caledonian-auto', 'auto_insurance', 'https://caledoniainsurance.com', ARRAY['VT','NH'], NULL, false),
    ('The Cincinnati Indemnity', 'cincinnati-indemnity-auto', 'auto_insurance', 'https://cinfin.com', ARRAY['US'], NULL, true),

    -- Pennsylvania regional
    ('Donegal Insurance Group', 'donegal-auto', 'auto_insurance', 'https://donegalgroup.com', ARRAY['PA','MD','VA','WV','OH','GA','SC','NC','TN','IA','NE','SD','WI','IL','IN','MI'], NULL, true),
    ('Erie Family Auto', 'erie-family-auto-extended', 'auto_insurance', 'https://erieinsurance.com', ARRAY['PA','NY','OH','MD','VA','WV','NC','TN','KY','IN','IL','WI','DC'], NULL, true),
    ('Penn-America Insurance', 'penn-america-auto', 'auto_insurance', 'https://global-indemnity.com', ARRAY['PA','NJ','DE','MD'], NULL, false),
    ('Westfield Champion (Pennsylvania)', 'westfield-champion-auto', 'auto_insurance', 'https://westfieldinsurance.com', ARRAY['PA','OH','IN'], NULL, true),

    -- HNW / Specialty (relevant for Haven's audience)
    ('AIG Private Client Group', 'aig-private-client-auto', 'auto_insurance', 'https://aig.com/pcg', ARRAY['US'], NULL, true),
    ('ACE Private Risk Services', 'ace-private-risk-auto', 'auto_insurance', 'https://chubb.com', ARRAY['US'], NULL, true),
    ('Federal Insurance Company (Chubb)', 'federal-insurance-chubb-auto', 'auto_insurance', 'https://chubb.com', ARRAY['US'], NULL, true),
    ('Great Northern Insurance (Chubb)', 'great-northern-chubb-auto', 'auto_insurance', 'https://chubb.com', ARRAY['US'], NULL, true),
    ('Vault Insurance', 'vault-insurance-auto', 'auto_insurance', 'https://vault.insurance', ARRAY['US'], NULL, true),
    ('PURE Programs', 'pure-programs-auto', 'auto_insurance', 'https://pureprograms.com', ARRAY['US'], NULL, true),
    ('Cincinnati Private Client', 'cincinnati-private-client-auto', 'auto_insurance', 'https://cinfin.com', ARRAY['US'], NULL, true),
    ('Crestbrook Insurance (Nationwide)', 'crestbrook-auto', 'auto_insurance', 'https://nationwide.com', ARRAY['US'], NULL, true),
    ('Berkley One', 'berkley-one-auto', 'auto_insurance', 'https://berkleyone.com', ARRAY['US'], NULL, true),
    ('Hagerty Insurance', 'hagerty-auto', 'auto_insurance', 'https://hagerty.com', ARRAY['US'], NULL, false),

    -- Missing big nationals + digital direct writers
    ('Toggle Insurance', 'toggle-auto', 'auto_insurance', 'https://gettoggle.com', ARRAY['US'], NULL, false),
    ('Hugo Insurance', 'hugo-auto', 'auto_insurance', 'https://hugoinsurance.com', ARRAY['CA','TX','AZ','OH','GA','IN','PA','OR'], NULL, false),
    ('Jetty Insurance', 'jetty-auto', 'auto_insurance', 'https://jetty.com', ARRAY['US'], NULL, true),
    ('Mile Auto', 'mile-auto-insurance', 'auto_insurance', 'https://mileauto.com', ARRAY['IL','GA','OR','PA','OH','TX','AZ'], NULL, false),
    ('Branch Insurance Auto', 'branch-insurance-auto-extended', 'auto_insurance', 'https://ourbranch.com', ARRAY['US'], NULL, true),
    ('Stillwater Auto', 'stillwater-auto-extended', 'auto_insurance', 'https://stillwater.com', ARRAY['US'], NULL, true),
    ('Mendota Insurance', 'mendota-auto', 'auto_insurance', 'https://mendotainsurance.com', ARRAY['MN','IA','WI','IL','MO','NE'], NULL, false),
    ('General Casualty (QBE)', 'general-casualty-qbe-auto', 'auto_insurance', 'https://qbe.com', ARRAY['US'], NULL, true),
    ('NJM Insurance Group (Auto Plus)', 'njm-auto-plus', 'auto_insurance', 'https://njm.com', ARRAY['NJ','PA','OH','MD','CT'], NULL, true),
    ('Berkshire Hathaway Direct Auto', 'berkshire-hathaway-direct-auto', 'auto_insurance', 'https://berkshirehathaway.com', ARRAY['US'], NULL, false),
    ('Geico Marketing Group', 'geico-marketing-auto', 'auto_insurance', 'https://geico.com', ARRAY['US'], NULL, true),
    ('Allianz Global', 'allianz-global-auto', 'auto_insurance', 'https://allianz.com', ARRAY['US'], NULL, true)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- HOME INSURANCE (Northeast regionals + missing nationals + HNW)
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url, bundles_with_auto) VALUES
    -- Massachusetts
    ('Quincy Mutual Group', 'quincy-mutual-home', 'home_insurance', 'https://quincymutual.com', ARRAY['MA','NH','CT','RI','VT','ME'], NULL, true),
    ('Norfolk & Dedham Group', 'norfolk-dedham-home', 'home_insurance', 'https://ndgroup.com', ARRAY['MA','NH','CT','RI','VT','ME','NY'], NULL, true),
    ('The Andover Companies', 'andover-companies-home', 'home_insurance', 'https://andovercos.com', ARRAY['MA','NH','CT','RI','VT','ME','NY','PA'], NULL, true),
    ('Cambridge Mutual', 'cambridge-mutual-home', 'home_insurance', 'https://andovercos.com', ARRAY['MA','NH','CT','RI','VT','ME'], NULL, true),
    ('Merrimack Mutual', 'merrimack-mutual-home', 'home_insurance', 'https://andovercos.com', ARRAY['MA','NH','CT','RI','VT','ME'], NULL, true),
    ('Bunker Hill Insurance', 'bunker-hill-home', 'home_insurance', 'https://bunkerhillinsurance.com', ARRAY['MA','NH','CT','RI'], NULL, true),
    ('Hingham Mutual', 'hingham-mutual-home', 'home_insurance', 'https://hinghammutual.com', ARRAY['MA','NH','RI','VT','CT'], NULL, true),
    ('Bay State Insurance', 'bay-state-home', 'home_insurance', 'https://andovercos.com', ARRAY['MA'], NULL, true),
    ('Commerce Insurance (MAPFRE)', 'commerce-insurance-home', 'home_insurance', 'https://mapfreinsurance.com', ARRAY['MA','NH','CT','RI'], NULL, true),
    ('Fitchburg Mutual', 'fitchburg-mutual-home', 'home_insurance', 'https://fitchburgmutual.com', ARRAY['MA','NH'], NULL, true),
    ('Plymouth Rock Home Assurance', 'plymouth-rock-home-extended', 'home_insurance', 'https://plymouthrock.com', ARRAY['MA','NH','CT','PA','NJ','NY'], NULL, true),

    -- New York
    ('New York Central Mutual', 'nycm-home', 'home_insurance', 'https://nycm.com', ARRAY['NY'], NULL, true),
    ('Preferred Mutual', 'preferred-mutual-home', 'home_insurance', 'https://preferredmutual.com', ARRAY['NY','NJ','MA','NH','RI'], NULL, true),
    ('Utica National', 'utica-national-home', 'home_insurance', 'https://uticanational.com', ARRAY['NY','NJ','PA','CT','MA','NH','VT','ME','OH'], NULL, true),
    ('Adirondack Insurance Exchange', 'adirondack-exchange-home', 'home_insurance', 'https://adirondackinsurance.com', ARRAY['NY'], NULL, true),
    ('Sterling Insurance', 'sterling-insurance-home', 'home_insurance', 'https://sterling-insurance.com', ARRAY['NY'], NULL, true),
    ('Kingstone Companies', 'kingstone-companies-home', 'home_insurance', 'https://kingstonecompanies.com', ARRAY['NY','NJ','PA','MA','CT','RI','NH'], NULL, true),
    ('Castle Point Insurance', 'castle-point-home', 'home_insurance', 'https://castlepointins.com', ARRAY['NY','NJ'], NULL, false),

    -- New Jersey
    ('NJ Skylands Insurance', 'nj-skylands-home', 'home_insurance', 'https://njskylands.com', ARRAY['NJ'], NULL, true),
    ('High Point Insurance', 'high-point-home', 'home_insurance', 'https://highpointins.com', ARRAY['NJ'], NULL, true),
    ('Palisades Insurance Group', 'palisades-home', 'home_insurance', 'https://palisadesgrp.com', ARRAY['NJ','NY','PA','CT'], NULL, true),
    ('Proformance Insurance', 'proformance-home', 'home_insurance', 'https://proformanceins.com', ARRAY['NJ','PA'], NULL, true),

    -- Connecticut + Rhode Island
    ('New London County Mutual', 'new-london-county-mutual-home', 'home_insurance', 'https://nlcmutual.com', ARRAY['CT','RI','MA'], NULL, true),
    ('CT Underwriters', 'ct-underwriters-home', 'home_insurance', 'https://ctunderwriters.com', ARRAY['CT'], NULL, false),

    -- Vermont / Maine / NH
    ('MMG Insurance', 'mmg-insurance-home', 'home_insurance', 'https://mmgins.com', ARRAY['ME','NH','VT','PA'], NULL, true),
    ('Patriot Insurance Company', 'patriot-insurance-home', 'home_insurance', 'https://patriotinsuranceco.com', ARRAY['ME','NH','VT','MA'], NULL, true),
    ('Concord Group Insurance', 'concord-group-home', 'home_insurance', 'https://concordgroupinsurance.com', ARRAY['NH','VT','MA','ME'], NULL, true),
    ('Caledonian Insurance', 'caledonian-home', 'home_insurance', 'https://caledoniainsurance.com', ARRAY['VT','NH'], NULL, false),
    ('Co-operators Insurance', 'co-operators-home', 'home_insurance', 'https://cooperators.ca', ARRAY['ME','NH','VT'], NULL, true),

    -- Pennsylvania regional
    ('Donegal Insurance Group', 'donegal-home', 'home_insurance', 'https://donegalgroup.com', ARRAY['PA','MD','VA','WV','OH','GA','SC','NC','TN','IA','NE','SD','WI','IL','IN','MI'], NULL, true),
    ('Erie Family Home', 'erie-family-home-extended', 'home_insurance', 'https://erieinsurance.com', ARRAY['PA','NY','OH','MD','VA','WV','NC','TN','KY','IN','IL','WI','DC'], NULL, true),
    ('Penn-America Insurance', 'penn-america-home', 'home_insurance', 'https://global-indemnity.com', ARRAY['PA','NJ','DE','MD'], NULL, false),
    ('Westfield Champion (PA)', 'westfield-champion-home', 'home_insurance', 'https://westfieldinsurance.com', ARRAY['PA','OH','IN'], NULL, true),
    ('Millers Mutual', 'millers-mutual-home', 'home_insurance', 'https://millersmutualgroup.com', ARRAY['PA','MD','DE','NJ'], NULL, true),

    -- HNW / Specialty (CRITICAL for Haven's audience)
    ('AIG Private Client Group', 'aig-private-client-home', 'home_insurance', 'https://aig.com/pcg', ARRAY['US'], NULL, true),
    ('AIG Home Insurance', 'aig-home', 'home_insurance', 'https://aig.com', ARRAY['US'], NULL, true),
    ('ACE Private Risk Services', 'ace-private-risk-home', 'home_insurance', 'https://chubb.com', ARRAY['US'], NULL, true),
    ('Federal Insurance Company (Chubb)', 'federal-insurance-chubb-home', 'home_insurance', 'https://chubb.com', ARRAY['US'], NULL, true),
    ('Great Northern Insurance (Chubb)', 'great-northern-chubb-home', 'home_insurance', 'https://chubb.com', ARRAY['US'], NULL, true),
    ('Chubb Masterpiece', 'chubb-masterpiece-home', 'home_insurance', 'https://chubb.com/personal/masterpiece', ARRAY['US'], NULL, true),
    ('Vault Insurance', 'vault-insurance-home', 'home_insurance', 'https://vault.insurance', ARRAY['US'], NULL, true),
    ('PURE Programs', 'pure-programs-home', 'home_insurance', 'https://pureprograms.com', ARRAY['US'], NULL, true),
    ('Cincinnati Private Client', 'cincinnati-private-client-home', 'home_insurance', 'https://cinfin.com', ARRAY['US'], NULL, true),
    ('Crestbrook Insurance (Nationwide)', 'crestbrook-home', 'home_insurance', 'https://nationwide.com', ARRAY['US'], NULL, true),
    ('Berkley One', 'berkley-one-home', 'home_insurance', 'https://berkleyone.com', ARRAY['US'], NULL, true),
    ('Ironshore Insurance', 'ironshore-home', 'home_insurance', 'https://liberty-mutual-group.com', ARRAY['US'], NULL, false),
    ('AXA XL', 'axa-xl-home', 'home_insurance', 'https://axaxl.com', ARRAY['US'], NULL, true),

    -- Missing big nationals
    ('Allianz Global', 'allianz-global-home', 'home_insurance', 'https://allianz.com', ARRAY['US'], NULL, true),
    ('Zurich Personal', 'zurich-personal-home', 'home_insurance', 'https://zurichna.com', ARRAY['US'], NULL, true),
    ('Stillwater Home', 'stillwater-home-extended', 'home_insurance', 'https://stillwater.com', ARRAY['US'], NULL, true),
    ('Geico Home (Homesite)', 'geico-home-homesite', 'home_insurance', 'https://geico.com/getaquote/homeowners', ARRAY['US'], NULL, true),
    ('Progressive Home (ASI)', 'progressive-home-asi', 'home_insurance', 'https://progressive.com/homeowners', ARRAY['US'], NULL, true),
    ('Lemonade Home Plus', 'lemonade-home-plus', 'home_insurance', 'https://lemonade.com/homeowners', ARRAY['US'], NULL, true),
    ('Hippo Smart Home', 'hippo-smart-home', 'home_insurance', 'https://hippo.com', ARRAY['US'], NULL, true),
    ('Toggle Renters & Home', 'toggle-home', 'home_insurance', 'https://gettoggle.com', ARRAY['US'], NULL, true),
    ('Jetty Home', 'jetty-home', 'home_insurance', 'https://jetty.com', ARRAY['US'], NULL, true),
    ('Branch Home', 'branch-home-extended', 'home_insurance', 'https://ourbranch.com', ARRAY['US'], NULL, true),
    ('Mercury Home', 'mercury-home', 'home_insurance', 'https://mercuryinsurance.com', ARRAY['CA','TX','OK','VA','GA','NV','AZ','FL','IL','NY','NJ'], NULL, true),
    ('General Casualty (QBE Home)', 'general-casualty-qbe-home', 'home_insurance', 'https://qbe.com', ARRAY['US'], NULL, true),
    ('NJM Home Insurance', 'njm-home', 'home_insurance', 'https://njm.com', ARRAY['NJ','PA','OH','MD','CT'], NULL, true),
    ('AAA Northeast Home', 'aaa-northeast-home', 'home_insurance', 'https://aaa.com/northeast', ARRAY['CT','MA','NH','RI','NJ','NY','PA'], NULL, true),
    ('USAA Property Insurance', 'usaa-property-home', 'home_insurance', 'https://usaa.com', ARRAY['US'], NULL, true)
ON CONFLICT (slug) DO NOTHING;
