-- Phase 18.5 follow-followup: Massive insurance provider expansion.
-- Goal: every common US insurance carrier the user might search for is in
-- the database with no manual entry required. Targets ~200 additional rows
-- across regional, specialty, and HNW segments.
--
-- Categories included:
--   1. State Farm Bureau federations (35+ state Farm Bureau insurance arms)
--   2. Mid-Atlantic regional carriers (DE, MD, PA, VA, WV)
--   3. Southern regional carriers (FL, GA, NC, SC, AL, TN, KY)
--   4. Midwest regional carriers (OH, MI, IN, IL, WI, MN, IA, MO, KS, NE)
--   5. Western regional carriers (CA, CO, AZ, NV, UT, WA, OR, ID, WY, MT)
--   6. Specialty: mobile/manufactured home, condo, renters
--   7. Specialty: flood-only carriers (NFIP brokers + private flood)
--   8. Specialty: earthquake, wind-only, hurricane carriers
--   9. Specialty: collector vehicle, boat, motorcycle insurers
--  10. International insurers operating in US personal lines
--  11. Captive agency brand variants of existing nationals
--  12. More HNW / private client carriers
--
-- All inserts use ON CONFLICT (slug) DO NOTHING.

-- ============================================================================
-- AUTO INSURANCE — STATE FARM BUREAU FEDERATIONS
-- ============================================================================
-- Each state has its own Farm Bureau insurance arm. They're huge in rural
-- and small-town markets and many homeowners use them for both auto and home.

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url, bundles_with_home) VALUES
    ('Alabama Farm Bureau Insurance', 'al-farm-bureau-auto', 'auto_insurance', 'https://alfains.com', ARRAY['AL'], NULL, true),
    ('Arkansas Farm Bureau Insurance', 'ar-farm-bureau-auto', 'auto_insurance', 'https://afbic.com', ARRAY['AR'], NULL, true),
    ('Colorado Farm Bureau Insurance', 'co-farm-bureau-auto', 'auto_insurance', 'https://coloradofarmbureauinsurance.com', ARRAY['CO'], NULL, true),
    ('Florida Farm Bureau Insurance', 'fl-farm-bureau-auto', 'auto_insurance', 'https://floridafarmbureau.com', ARRAY['FL'], NULL, true),
    ('Georgia Farm Bureau Insurance', 'ga-farm-bureau-auto', 'auto_insurance', 'https://gfb.org', ARRAY['GA'], NULL, true),
    ('Idaho Farm Bureau Insurance', 'id-farm-bureau-auto', 'auto_insurance', 'https://idahofbins.com', ARRAY['ID'], NULL, true),
    ('Illinois Farm Bureau (COUNTRY Financial)', 'il-farm-bureau-auto', 'auto_insurance', 'https://countryfinancial.com', ARRAY['IL'], NULL, true),
    ('Iowa Farm Bureau Insurance', 'ia-farm-bureau-auto', 'auto_insurance', 'https://fbfs.com', ARRAY['IA'], NULL, true),
    ('Kansas Farm Bureau', 'ks-farm-bureau-auto', 'auto_insurance', 'https://kfb.org', ARRAY['KS'], NULL, true),
    ('Louisiana Farm Bureau Insurance', 'la-farm-bureau-auto', 'auto_insurance', 'https://lfbic.com', ARRAY['LA'], NULL, true),
    ('Michigan Farm Bureau Insurance', 'mi-farm-bureau-auto', 'auto_insurance', 'https://farmbureauinsurance-mi.com', ARRAY['MI'], NULL, true),
    ('Minnesota Farm Bureau (FBFS)', 'mn-farm-bureau-auto', 'auto_insurance', 'https://fbfs.com', ARRAY['MN'], NULL, true),
    ('Mississippi Farm Bureau Insurance', 'ms-farm-bureau-auto', 'auto_insurance', 'https://msfbins.com', ARRAY['MS'], NULL, true),
    ('Missouri Farm Bureau Insurance', 'mo-farm-bureau-auto', 'auto_insurance', 'https://mofbinsurance.com', ARRAY['MO'], NULL, true),
    ('Montana Farm Bureau (Mountain West)', 'mt-farm-bureau-auto', 'auto_insurance', 'https://mwfbi.com', ARRAY['MT','WY','ID','NV','UT'], NULL, true),
    ('Nebraska Farm Bureau (FBFS)', 'ne-farm-bureau-auto', 'auto_insurance', 'https://fbfs.com', ARRAY['NE'], NULL, true),
    ('Oklahoma Farm Bureau Insurance', 'ok-farm-bureau-auto', 'auto_insurance', 'https://okfbins.com', ARRAY['OK'], NULL, true),
    ('SC Farm Bureau Insurance', 'sc-farm-bureau-auto', 'auto_insurance', 'https://scfb.com', ARRAY['SC'], NULL, true),
    ('SD Farm Bureau (FBFS)', 'sd-farm-bureau-auto', 'auto_insurance', 'https://fbfs.com', ARRAY['SD'], NULL, true),
    ('Tennessee Farmers Insurance', 'tn-farmers-auto', 'auto_insurance', 'https://tnfarmers.com', ARRAY['TN'], NULL, true),
    ('Texas Farm Bureau Insurance', 'tx-farm-bureau-auto', 'auto_insurance', 'https://txfb-ins.com', ARRAY['TX'], NULL, true),
    ('Utah Farm Bureau Insurance', 'ut-farm-bureau-auto', 'auto_insurance', 'https://utahfarmbureau.org', ARRAY['UT'], NULL, true),
    ('Virginia Farm Bureau Insurance', 'va-farm-bureau-auto', 'auto_insurance', 'https://vafb.com', ARRAY['VA'], NULL, true),
    ('West Virginia Farm Bureau', 'wv-farm-bureau-auto', 'auto_insurance', 'https://wvfarm.org', ARRAY['WV'], NULL, true),
    ('Wisconsin Farm Bureau (Rural Mutual)', 'wi-farm-bureau-auto', 'auto_insurance', 'https://ruralmutual.com', ARRAY['WI'], NULL, true),
    ('Wyoming Farm Bureau (Mountain West)', 'wy-farm-bureau-auto', 'auto_insurance', 'https://mwfbi.com', ARRAY['WY'], NULL, true)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- AUTO INSURANCE — MID-ATLANTIC REGIONALS
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url, bundles_with_home) VALUES
    ('Erie Insurance Exchange', 'erie-exchange-auto', 'auto_insurance', 'https://erieinsurance.com', ARRAY['PA','NY','OH','MD','VA','WV','NC','TN','KY','IN','IL','WI','DC'], NULL, true),
    ('Goodville Mutual', 'goodville-mutual-auto', 'auto_insurance', 'https://goodville.com', ARRAY['PA','OH','VA','MD','DE','IN'], NULL, true),
    ('Mutual Benefit Group', 'mutual-benefit-auto', 'auto_insurance', 'https://mutualbenefitgroup.com', ARRAY['PA','MD','OH','VA','WV','NC','SC'], NULL, true),
    ('Brethren Mutual', 'brethren-mutual-auto', 'auto_insurance', 'https://brethrenmutual.com', ARRAY['MD','PA','VA','WV','DE'], NULL, true),
    ('Selective Auto Insurance', 'selective-auto-extended', 'auto_insurance', 'https://selective.com', ARRAY['NJ','NY','PA','MD','VA','DE','CT','MA','RI','NH','SC','GA','TN','OH','IN','KY','IL','MN','WI','MI','IA','MO','NE','OK','GA','NC'], NULL, true),
    ('Brotherhood Mutual', 'brotherhood-mutual-auto', 'auto_insurance', 'https://brotherhoodmutual.com', ARRAY['US'], NULL, true),
    ('Penn-America (Global Indemnity)', 'penn-america-extended-auto', 'auto_insurance', 'https://global-indemnity.com', ARRAY['PA','NJ','MD','DE','VA','OH'], NULL, false),
    ('West Bend Mutual Auto', 'west-bend-mutual-auto-extended', 'auto_insurance', 'https://thesilverlining.com', ARRAY['WI','MN','IL','IA','IN','MI','OH','PA','GA'], NULL, true),
    ('Society Insurance', 'society-insurance-auto', 'auto_insurance', 'https://societyinsurance.com', ARRAY['WI','IL','MN','IA','IN','TN','OH'], NULL, false),
    ('Harleysville Insurance', 'harleysville-auto', 'auto_insurance', 'https://nationwide.com', ARRAY['PA','NJ','OH','MD','DE','VA','NC','GA'], NULL, true)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- AUTO INSURANCE — SOUTHERN REGIONALS
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url, bundles_with_home) VALUES
    ('Florida Family Insurance', 'florida-family-auto', 'auto_insurance', 'https://floridafamily.com', ARRAY['FL'], NULL, true),
    ('Olympus Insurance Auto', 'olympus-insurance-auto', 'auto_insurance', 'https://olympusinsurance.com', ARRAY['FL'], NULL, true),
    ('Florida Peninsula Auto', 'florida-peninsula-auto', 'auto_insurance', 'https://floridapeninsula.com', ARRAY['FL'], NULL, true),
    ('UPCIC (Universal P&C)', 'upcic-auto', 'auto_insurance', 'https://universalproperty.com', ARRAY['FL','SC','NC','GA','MA','MN','MD','DE','VA','HI','PA','IL','MI','AL','IN'], NULL, true),
    ('Tower Hill Specialty', 'tower-hill-specialty-auto', 'auto_insurance', 'https://thig.com', ARRAY['FL'], NULL, true),
    ('Slide Insurance', 'slide-insurance-auto', 'auto_insurance', 'https://slideinsurance.com', ARRAY['FL'], NULL, true),
    ('Gulfstream Property & Casualty', 'gulfstream-pc-auto', 'auto_insurance', 'https://gulfstreamins.com', ARRAY['FL'], NULL, true),
    ('Edison Insurance', 'edison-insurance-auto', 'auto_insurance', 'https://edisoninsurance.com', ARRAY['FL'], NULL, true),
    ('SafePoint Insurance', 'safepoint-auto', 'auto_insurance', 'https://safepointins.com', ARRAY['FL','LA','TX'], NULL, false),
    ('National Lloyds Insurance', 'national-lloyds-auto', 'auto_insurance', 'https://nlasco.com', ARRAY['TX','OK','AR','LA','MS','AL','GA','SC','NC','TN'], NULL, false),
    ('GeoVera Auto', 'geovera-auto', 'auto_insurance', 'https://geovera.com', ARRAY['CA','HI','OR','WA','AL','MS','LA','TX'], NULL, false),
    ('SC Mutual Insurance', 'sc-mutual-auto', 'auto_insurance', 'https://scmins.com', ARRAY['SC'], NULL, true),
    ('Builders Mutual', 'builders-mutual-auto', 'auto_insurance', 'https://buildersmutual.com', ARRAY['NC','SC','VA','GA','TN'], NULL, false),
    ('NCFB Mutual Insurance', 'ncfb-mutual-auto', 'auto_insurance', 'https://ncfbins.com', ARRAY['NC'], NULL, true),
    ('Foundation Insurance Florida', 'foundation-insurance-fl-auto', 'auto_insurance', 'https://foundationins.com', ARRAY['FL'], NULL, true),
    ('Capital Preferred', 'capital-preferred-auto', 'auto_insurance', 'https://capitalpreferred.com', ARRAY['FL','SC','LA'], NULL, true),
    ('First Floridian Auto', 'first-floridian-auto', 'auto_insurance', 'https://firstfloridian.com', ARRAY['FL'], NULL, true),
    ('Olympus Specialty', 'olympus-specialty-auto', 'auto_insurance', 'https://olympusspecialty.com', ARRAY['FL'], NULL, false),
    ('Royal Palm Insurance', 'royal-palm-auto', 'auto_insurance', 'https://royalpalmcompanies.com', ARRAY['FL'], NULL, false),
    ('Southern Trust Insurance', 'southern-trust-auto', 'auto_insurance', 'https://southerntrust.com', ARRAY['GA','AL','SC','NC','FL','TN'], NULL, true),
    ('Auto-Owners (Mid-South)', 'auto-owners-mid-south-auto', 'auto_insurance', 'https://auto-owners.com', ARRAY['MI','OH','IN','IL','KY','TN','AL','GA','NC','SC','VA','WV','MO','IA','MN','WI','PA','UT','CO','AZ','FL','NE','KS','OK','TX','NM','NV','ID','WY','MT','SD','ND','AR','LA','MS'], NULL, true),
    ('National Western Agency', 'nwa-auto', 'auto_insurance', 'https://nwagy.com', ARRAY['LA','MS','AL','TX'], NULL, false),
    ('Spirit Insurance Group', 'spirit-insurance-auto', 'auto_insurance', 'https://spiritinsurance.com', ARRAY['LA','TX','MS','AL'], NULL, false),
    ('Bankers Insurance Group', 'bankers-insurance-auto', 'auto_insurance', 'https://bankersinsurance.com', ARRAY['FL','LA','TX','NJ','NY','PA','OH'], NULL, false)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- AUTO INSURANCE — MIDWEST REGIONALS
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url, bundles_with_home) VALUES
    ('Auto-Owners Insurance Group', 'auto-owners-group-auto', 'auto_insurance', 'https://auto-owners.com', ARRAY['MI','OH','IN','IL','WI','PA','MN','IA','MO','KY','TN'], NULL, true),
    ('Cincinnati Financial', 'cincinnati-financial-auto', 'auto_insurance', 'https://cinfin.com', ARRAY['US'], NULL, true),
    ('IMT Insurance', 'imt-insurance-auto', 'auto_insurance', 'https://imtins.com', ARRAY['IA','IL','MN','MO','NE','ND','SD','WI','AZ'], NULL, true),
    ('Pioneer State Mutual', 'pioneer-state-mutual-auto', 'auto_insurance', 'https://psmic.com', ARRAY['MI'], NULL, true),
    ('Wolverine Mutual', 'wolverine-mutual-auto', 'auto_insurance', 'https://wolverinemutual.com', ARRAY['MI','IN','OH'], NULL, true),
    ('Hanover Fire & Casualty', 'hanover-fc-auto', 'auto_insurance', 'https://hanover.com', ARRAY['US'], NULL, true),
    ('Citizens Insurance (Hanover)', 'citizens-hanover-auto', 'auto_insurance', 'https://hanover.com', ARRAY['MI','OH','IN','IL'], NULL, true),
    ('Erie & Niagara Insurance', 'erie-niagara-auto', 'auto_insurance', 'https://e-ngroup.com', ARRAY['NY','PA','OH'], NULL, true),
    ('Federated Mutual', 'federated-mutual-auto', 'auto_insurance', 'https://federatedinsurance.com', ARRAY['US'], NULL, false),
    ('Hagerty (Classic Cars)', 'hagerty-extended-auto', 'auto_insurance', 'https://hagerty.com', ARRAY['US'], NULL, false),
    ('Acuity A Mutual Insurance', 'acuity-mutual-auto-extended', 'auto_insurance', 'https://acuity.com', ARRAY['WI','IL','IN','IA','MI','MN','MO','OH','TN','WV','KY','KS','MS','TX','NV','AZ','UT','CO','NE','SD','ND','WY','MT','AR','OK','PA','GA','VA','NC'], NULL, true),
    ('Integrity Insurance', 'integrity-insurance-auto', 'auto_insurance', 'https://integrityinsurance.com', ARRAY['WI','MN','IA','IL','IN','OH','MI'], NULL, true),
    ('Pekin Insurance Group', 'pekin-group-auto', 'auto_insurance', 'https://pekininsurance.com', ARRAY['IL','IN','IA','OH','WI'], NULL, true),
    ('Continental Western Group', 'cwg-auto', 'auto_insurance', 'https://cwgins.com', ARRAY['IA','NE','MN','SD','ND','MO','KS','WI','IL','IN'], NULL, true),
    ('Employers Mutual Casualty (EMC)', 'emc-extended-auto', 'auto_insurance', 'https://emcins.com', ARRAY['US'], NULL, true)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- AUTO INSURANCE — WESTERN REGIONALS
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url, bundles_with_home) VALUES
    ('Mercury Casualty (CA)', 'mercury-casualty-auto', 'auto_insurance', 'https://mercuryinsurance.com', ARRAY['CA','TX','OK','VA','GA','NV','AZ','FL','IL','NY','NJ'], NULL, true),
    ('Wawanesa Mutual (CA Auto)', 'wawanesa-mutual-auto', 'auto_insurance', 'https://wawanesa.com', ARRAY['CA','OR'], NULL, true),
    ('Esurance (CA digital)', 'esurance-ca-auto', 'auto_insurance', 'https://esurance.com', ARRAY['US'], NULL, false),
    ('CSAA Insurance Exchange', 'csaa-exchange-auto', 'auto_insurance', 'https://csaa-insurance.aaa.com', ARRAY['CA','NV','UT','AZ','CO','WY','NM','MT','OK','KS','AR','OH','KY','PA','WV','VA','DE','NJ','NY','MD','MS','TN','IN','SD','ID'], NULL, true),
    ('Interinsurance Exchange (Auto Club)', 'interinsurance-exchange-auto', 'auto_insurance', 'https://aaa.com/socal', ARRAY['CA'], NULL, true),
    ('Pacific Insurance Co', 'pacific-insurance-auto', 'auto_insurance', 'https://pacins.com', ARRAY['CA','OR','WA','NV','AZ'], NULL, false),
    ('Stillwater Auto Insurance Plus', 'stillwater-plus-auto', 'auto_insurance', 'https://stillwater.com', ARRAY['US'], NULL, true),
    ('Topa Insurance Group', 'topa-insurance-auto', 'auto_insurance', 'https://topainsgroup.com', ARRAY['CA','TX','NV','AZ'], NULL, false),
    ('Workmen''s Auto (CA)', 'workmens-auto-ca-extended', 'auto_insurance', 'https://workmensauto.com', ARRAY['CA'], NULL, false),
    ('Bristol West (CA)', 'bristol-west-ca-auto', 'auto_insurance', 'https://bristolwest.com', ARRAY['CA','TX','FL','GA','OH','IL'], NULL, false),
    ('Mountain West Farm Bureau', 'mountain-west-fb-auto', 'auto_insurance', 'https://mwfbi.com', ARRAY['MT','WY','ID','UT','NV'], NULL, true),
    ('Empower Insurance', 'empower-insurance-auto', 'auto_insurance', 'https://empowerinsurance.com', ARRAY['TX'], NULL, false),
    ('Germania Insurance', 'germania-insurance-auto', 'auto_insurance', 'https://germaniainsurance.com', ARRAY['TX'], NULL, true),
    ('TexasSure (formerly Foremost TX)', 'texas-sure-auto', 'auto_insurance', 'https://texasure.com', ARRAY['TX'], NULL, false),
    ('Old American County Mutual', 'old-american-cm-auto', 'auto_insurance', 'https://oacmins.com', ARRAY['TX'], NULL, false),
    ('UICI United Equitable', 'uici-united-auto', 'auto_insurance', 'https://uicicompanies.com', ARRAY['IL','TX','OH','IN','MI','GA','SC','NC','VA','MD','PA'], NULL, false)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- AUTO INSURANCE — INTERNATIONAL + CAPTIVE BRANDS
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url, bundles_with_home) VALUES
    ('Munich Re (US Personal)', 'munich-re-us-auto', 'auto_insurance', 'https://munichre.com', ARRAY['US'], NULL, true),
    ('Swiss Re Personal Lines', 'swiss-re-personal-auto', 'auto_insurance', 'https://swissre.com', ARRAY['US'], NULL, true),
    ('Generali US', 'generali-us-auto', 'auto_insurance', 'https://generaliglobalassistance.com', ARRAY['US'], NULL, true),
    ('Tokio Marine America', 'tokio-marine-america-auto', 'auto_insurance', 'https://tmamerica.com', ARRAY['US'], NULL, true),
    ('Zurich North America Personal', 'zurich-na-personal-auto', 'auto_insurance', 'https://zurichna.com', ARRAY['US'], NULL, true),
    ('Aviva USA', 'aviva-usa-auto', 'auto_insurance', 'https://aviva.com', ARRAY['US'], NULL, true),
    ('AXA Affinity', 'axa-affinity-auto', 'auto_insurance', 'https://axa.com', ARRAY['US'], NULL, true)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- AUTO INSURANCE — SPECIALTY (collector vehicles, motorcycles, RVs, boats)
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url, bundles_with_home) VALUES
    ('American Modern Insurance Group', 'american-modern-auto', 'auto_insurance', 'https://amig.com', ARRAY['US'], NULL, false),
    ('Foremost Specialty (motor home)', 'foremost-specialty-auto', 'auto_insurance', 'https://foremost.com', ARRAY['US'], NULL, false),
    ('Progressive Boat & Yacht', 'progressive-boat-auto', 'auto_insurance', 'https://progressive.com/boat', ARRAY['US'], NULL, false),
    ('Markel Insurance', 'markel-auto', 'auto_insurance', 'https://markel.com', ARRAY['US'], NULL, false),
    ('Markel American', 'markel-american-auto', 'auto_insurance', 'https://markelamerican.com', ARRAY['US'], NULL, false),
    ('Grundy Insurance (Classic Cars)', 'grundy-classic-auto', 'auto_insurance', 'https://grundy.com', ARRAY['US'], NULL, false),
    ('JC Taylor Antique Auto', 'jc-taylor-antique-auto', 'auto_insurance', 'https://jctaylor.com', ARRAY['US'], NULL, false),
    ('American Collectors Insurance', 'american-collectors-auto', 'auto_insurance', 'https://americancollectors.com', ARRAY['US'], NULL, false),
    ('Heacock Classic', 'heacock-classic-auto', 'auto_insurance', 'https://heacockclassic.com', ARRAY['US'], NULL, false),
    ('Condon Skelly', 'condon-skelly-auto', 'auto_insurance', 'https://condonskelly.com', ARRAY['US'], NULL, false),
    ('Dairyland Cycle (Motorcycle)', 'dairyland-cycle-auto', 'auto_insurance', 'https://dairylandcycle.com', ARRAY['US'], NULL, false),
    ('Rider Insurance (Motorcycle)', 'rider-insurance-auto', 'auto_insurance', 'https://rider.com', ARRAY['NJ','NY','PA','CT'], NULL, false),
    ('Good Sam RV', 'good-sam-rv-auto', 'auto_insurance', 'https://goodsam.com', ARRAY['US'], NULL, false),
    ('National Interstate (RV/commercial)', 'national-interstate-auto', 'auto_insurance', 'https://natl.com', ARRAY['US'], NULL, false),
    ('Roamly RV Insurance', 'roamly-auto', 'auto_insurance', 'https://roamly.com', ARRAY['US'], NULL, false)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- HOME INSURANCE — STATE FARM BUREAU FEDERATIONS
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url, bundles_with_auto) VALUES
    ('Alabama Farm Bureau Insurance', 'al-farm-bureau-home', 'home_insurance', 'https://alfains.com', ARRAY['AL'], NULL, true),
    ('Arkansas Farm Bureau Insurance', 'ar-farm-bureau-home', 'home_insurance', 'https://afbic.com', ARRAY['AR'], NULL, true),
    ('Colorado Farm Bureau Insurance', 'co-farm-bureau-home', 'home_insurance', 'https://coloradofarmbureauinsurance.com', ARRAY['CO'], NULL, true),
    ('Florida Farm Bureau Insurance', 'fl-farm-bureau-home', 'home_insurance', 'https://floridafarmbureau.com', ARRAY['FL'], NULL, true),
    ('Georgia Farm Bureau Insurance', 'ga-farm-bureau-home', 'home_insurance', 'https://gfb.org', ARRAY['GA'], NULL, true),
    ('Idaho Farm Bureau Insurance', 'id-farm-bureau-home', 'home_insurance', 'https://idahofbins.com', ARRAY['ID'], NULL, true),
    ('Illinois Farm Bureau (COUNTRY)', 'il-farm-bureau-home', 'home_insurance', 'https://countryfinancial.com', ARRAY['IL'], NULL, true),
    ('Iowa Farm Bureau Insurance', 'ia-farm-bureau-home', 'home_insurance', 'https://fbfs.com', ARRAY['IA'], NULL, true),
    ('Kansas Farm Bureau', 'ks-farm-bureau-home', 'home_insurance', 'https://kfb.org', ARRAY['KS'], NULL, true),
    ('Louisiana Farm Bureau Insurance', 'la-farm-bureau-home', 'home_insurance', 'https://lfbic.com', ARRAY['LA'], NULL, true),
    ('Michigan Farm Bureau Insurance', 'mi-farm-bureau-home', 'home_insurance', 'https://farmbureauinsurance-mi.com', ARRAY['MI'], NULL, true),
    ('Minnesota Farm Bureau (FBFS)', 'mn-farm-bureau-home', 'home_insurance', 'https://fbfs.com', ARRAY['MN'], NULL, true),
    ('Mississippi Farm Bureau Insurance', 'ms-farm-bureau-home', 'home_insurance', 'https://msfbins.com', ARRAY['MS'], NULL, true),
    ('Missouri Farm Bureau Insurance', 'mo-farm-bureau-home', 'home_insurance', 'https://mofbinsurance.com', ARRAY['MO'], NULL, true),
    ('Mountain West Farm Bureau (MT/WY)', 'mt-farm-bureau-home', 'home_insurance', 'https://mwfbi.com', ARRAY['MT','WY','ID','NV','UT'], NULL, true),
    ('Nebraska Farm Bureau (FBFS)', 'ne-farm-bureau-home', 'home_insurance', 'https://fbfs.com', ARRAY['NE'], NULL, true),
    ('Oklahoma Farm Bureau Insurance', 'ok-farm-bureau-home', 'home_insurance', 'https://okfbins.com', ARRAY['OK'], NULL, true),
    ('SC Farm Bureau Insurance', 'sc-farm-bureau-home', 'home_insurance', 'https://scfb.com', ARRAY['SC'], NULL, true),
    ('SD Farm Bureau (FBFS)', 'sd-farm-bureau-home', 'home_insurance', 'https://fbfs.com', ARRAY['SD'], NULL, true),
    ('Tennessee Farmers Insurance', 'tn-farmers-home', 'home_insurance', 'https://tnfarmers.com', ARRAY['TN'], NULL, true),
    ('Texas Farm Bureau Insurance', 'tx-farm-bureau-home', 'home_insurance', 'https://txfb-ins.com', ARRAY['TX'], NULL, true),
    ('Utah Farm Bureau Insurance', 'ut-farm-bureau-home', 'home_insurance', 'https://utahfarmbureau.org', ARRAY['UT'], NULL, true),
    ('Virginia Farm Bureau Insurance', 'va-farm-bureau-home', 'home_insurance', 'https://vafb.com', ARRAY['VA'], NULL, true),
    ('West Virginia Farm Bureau', 'wv-farm-bureau-home', 'home_insurance', 'https://wvfarm.org', ARRAY['WV'], NULL, true),
    ('Wisconsin Farm Bureau (Rural Mutual)', 'wi-farm-bureau-home', 'home_insurance', 'https://ruralmutual.com', ARRAY['WI'], NULL, true),
    ('Wyoming Farm Bureau (Mountain West)', 'wy-farm-bureau-home', 'home_insurance', 'https://mwfbi.com', ARRAY['WY'], NULL, true)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- HOME INSURANCE — MID-ATLANTIC + SOUTHERN REGIONALS
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url, bundles_with_auto) VALUES
    ('Goodville Mutual', 'goodville-mutual-home', 'home_insurance', 'https://goodville.com', ARRAY['PA','OH','VA','MD','DE','IN'], NULL, true),
    ('Mutual Benefit Group', 'mutual-benefit-home', 'home_insurance', 'https://mutualbenefitgroup.com', ARRAY['PA','MD','OH','VA','WV','NC','SC'], NULL, true),
    ('Brethren Mutual', 'brethren-mutual-home', 'home_insurance', 'https://brethrenmutual.com', ARRAY['MD','PA','VA','WV','DE'], NULL, true),
    ('Brotherhood Mutual', 'brotherhood-mutual-home', 'home_insurance', 'https://brotherhoodmutual.com', ARRAY['US'], NULL, true),
    ('Donegal Insurance Group (extended)', 'donegal-extended-home', 'home_insurance', 'https://donegalgroup.com', ARRAY['PA','MD','VA','WV','OH','GA','SC','NC','TN','IA','NE','SD','WI','IL','IN','MI'], NULL, true),
    ('Slide Insurance', 'slide-insurance-home', 'home_insurance', 'https://slideinsurance.com', ARRAY['FL'], NULL, true),
    ('Florida Family Insurance', 'florida-family-home', 'home_insurance', 'https://floridafamily.com', ARRAY['FL'], NULL, true),
    ('Gulfstream Property & Casualty', 'gulfstream-pc-home', 'home_insurance', 'https://gulfstreamins.com', ARRAY['FL'], NULL, true),
    ('Edison Insurance', 'edison-insurance-home', 'home_insurance', 'https://edisoninsurance.com', ARRAY['FL'], NULL, true),
    ('SafePoint Insurance', 'safepoint-home', 'home_insurance', 'https://safepointins.com', ARRAY['FL','LA','TX'], NULL, false),
    ('Foundation Insurance Florida', 'foundation-insurance-fl-home', 'home_insurance', 'https://foundationins.com', ARRAY['FL'], NULL, true),
    ('Capital Preferred', 'capital-preferred-home', 'home_insurance', 'https://capitalpreferred.com', ARRAY['FL','SC','LA'], NULL, true),
    ('First Floridian Auto & Home', 'first-floridian-home', 'home_insurance', 'https://firstfloridian.com', ARRAY['FL'], NULL, true),
    ('Royal Palm Insurance', 'royal-palm-home', 'home_insurance', 'https://royalpalmcompanies.com', ARRAY['FL'], NULL, false),
    ('Olympus Specialty Home', 'olympus-specialty-home', 'home_insurance', 'https://olympusspecialty.com', ARRAY['FL'], NULL, false),
    ('Southern Trust Insurance', 'southern-trust-home', 'home_insurance', 'https://southerntrust.com', ARRAY['GA','AL','SC','NC','FL','TN'], NULL, true),
    ('Auto-Owners Home', 'auto-owners-home-extended', 'home_insurance', 'https://auto-owners.com', ARRAY['MI','OH','IN','IL','KY','TN','AL','GA','NC','SC','VA','WV','MO','IA','MN','WI','PA','UT','CO','AZ','FL','NE','KS','OK','TX','NM','NV','ID','WY','MT','SD','ND','AR','LA','MS'], NULL, true),
    ('Cincinnati Financial Home', 'cincinnati-financial-home', 'home_insurance', 'https://cinfin.com', ARRAY['US'], NULL, true),
    ('SC Mutual Insurance Home', 'sc-mutual-home', 'home_insurance', 'https://scmins.com', ARRAY['SC'], NULL, true),
    ('NCFB Mutual Home', 'ncfb-mutual-home', 'home_insurance', 'https://ncfbins.com', ARRAY['NC'], NULL, true),
    ('Bankers Insurance Group Home', 'bankers-insurance-home', 'home_insurance', 'https://bankersinsurance.com', ARRAY['FL','LA','TX','NJ','NY','PA','OH'], NULL, false),
    ('National Lloyds Home', 'national-lloyds-home', 'home_insurance', 'https://nlasco.com', ARRAY['TX','OK','AR','LA','MS','AL','GA','SC','NC','TN'], NULL, false)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- HOME INSURANCE — MIDWEST REGIONALS
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url, bundles_with_auto) VALUES
    ('IMT Insurance', 'imt-insurance-home', 'home_insurance', 'https://imtins.com', ARRAY['IA','IL','MN','MO','NE','ND','SD','WI','AZ'], NULL, true),
    ('Pioneer State Mutual', 'pioneer-state-mutual-home', 'home_insurance', 'https://psmic.com', ARRAY['MI'], NULL, true),
    ('Wolverine Mutual', 'wolverine-mutual-home', 'home_insurance', 'https://wolverinemutual.com', ARRAY['MI','IN','OH'], NULL, true),
    ('Erie & Niagara Insurance', 'erie-niagara-home', 'home_insurance', 'https://e-ngroup.com', ARRAY['NY','PA','OH'], NULL, true),
    ('Federated Mutual', 'federated-mutual-home', 'home_insurance', 'https://federatedinsurance.com', ARRAY['US'], NULL, false),
    ('Acuity Mutual Home', 'acuity-mutual-home-extended', 'home_insurance', 'https://acuity.com', ARRAY['WI','IL','IN','IA','MI','MN','MO','OH','TN','WV','KY','KS','MS','TX','NV','AZ','UT','CO','NE','SD','ND','WY','MT','AR','OK','PA','GA','VA','NC'], NULL, true),
    ('Integrity Insurance Home', 'integrity-insurance-home', 'home_insurance', 'https://integrityinsurance.com', ARRAY['WI','MN','IA','IL','IN','OH','MI'], NULL, true),
    ('Pekin Insurance Home', 'pekin-group-home', 'home_insurance', 'https://pekininsurance.com', ARRAY['IL','IN','IA','OH','WI'], NULL, true),
    ('Continental Western Group', 'cwg-home', 'home_insurance', 'https://cwgins.com', ARRAY['IA','NE','MN','SD','ND','MO','KS','WI','IL','IN'], NULL, true),
    ('EMC Insurance Home', 'emc-extended-home', 'home_insurance', 'https://emcins.com', ARRAY['US'], NULL, true),
    ('Hanover Citizens Home', 'citizens-hanover-home', 'home_insurance', 'https://hanover.com', ARRAY['MI','OH','IN','IL'], NULL, true),
    ('Society Insurance Home', 'society-insurance-home', 'home_insurance', 'https://societyinsurance.com', ARRAY['WI','IL','MN','IA','IN','TN','OH'], NULL, false)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- HOME INSURANCE — WESTERN REGIONALS
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url, bundles_with_auto) VALUES
    ('Mercury Casualty (CA)', 'mercury-casualty-home', 'home_insurance', 'https://mercuryinsurance.com', ARRAY['CA','TX','OK','VA','GA','NV','AZ','FL','IL','NY','NJ'], NULL, true),
    ('Wawanesa Mutual (CA Home)', 'wawanesa-mutual-home', 'home_insurance', 'https://wawanesa.com', ARRAY['CA','OR'], NULL, true),
    ('CSAA Insurance Exchange Home', 'csaa-exchange-home', 'home_insurance', 'https://csaa-insurance.aaa.com', ARRAY['CA','NV','UT','AZ','CO','WY','NM','MT','OK','KS','AR','OH','KY','PA','WV','VA','DE','NJ','NY','MD','MS','TN','IN','SD','ID'], NULL, true),
    ('Interinsurance Exchange (Auto Club CA)', 'interinsurance-exchange-home', 'home_insurance', 'https://aaa.com/socal', ARRAY['CA'], NULL, true),
    ('Pacific Insurance Co Home', 'pacific-insurance-home', 'home_insurance', 'https://pacins.com', ARRAY['CA','OR','WA','NV','AZ'], NULL, false),
    ('Topa Insurance Group', 'topa-insurance-home', 'home_insurance', 'https://topainsgroup.com', ARRAY['CA','TX','NV','AZ'], NULL, false),
    ('Germania Insurance Home', 'germania-insurance-home', 'home_insurance', 'https://germaniainsurance.com', ARRAY['TX'], NULL, true),
    ('California Fair Plan', 'california-fair-plan-home', 'home_insurance', 'https://cfpnet.com', ARRAY['CA'], NULL, false),
    ('Mountain West Farm Bureau Home', 'mountain-west-fb-home', 'home_insurance', 'https://mwfbi.com', ARRAY['MT','WY','ID','UT','NV'], NULL, true)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- HOME INSURANCE — SPECIALTY (mobile, condo, renters, manufactured)
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url, bundles_with_auto) VALUES
    ('American Modern Home', 'american-modern-home', 'home_insurance', 'https://amig.com', ARRAY['US'], NULL, false),
    ('Foremost Manufactured Home', 'foremost-manufactured-home', 'home_insurance', 'https://foremost.com', ARRAY['US'], NULL, false),
    ('Foremost Mobile Home', 'foremost-mobile-home', 'home_insurance', 'https://foremost.com', ARRAY['US'], NULL, false),
    ('Standard Casualty Mobile', 'standard-casualty-mobile-home', 'home_insurance', 'https://stdcas.com', ARRAY['US'], NULL, false),
    ('Assurant Renters', 'assurant-renters-home', 'home_insurance', 'https://assurant.com', ARRAY['US'], NULL, false),
    ('Assurant Manufactured Home', 'assurant-manufactured-home', 'home_insurance', 'https://assurant.com', ARRAY['US'], NULL, false),
    ('Effective Coverage Renters', 'effective-coverage-home', 'home_insurance', 'https://effectivecoverage.com', ARRAY['US'], NULL, false),
    ('eRenterPlan', 'erenterplan-home', 'home_insurance', 'https://erenterplan.com', ARRAY['US'], NULL, false),
    ('Lemonade Renters', 'lemonade-renters-home', 'home_insurance', 'https://lemonade.com/renters', ARRAY['US'], NULL, false),
    ('Toggle Renters', 'toggle-renters-home', 'home_insurance', 'https://gettoggle.com/renters', ARRAY['US'], NULL, false),
    ('Jetty Renters Insurance', 'jetty-renters-home', 'home_insurance', 'https://jetty.com', ARRAY['US'], NULL, false),
    ('Roost Renters', 'roost-renters-home', 'home_insurance', 'https://roostrenters.com', ARRAY['US'], NULL, false),
    ('Goodcover Renters', 'goodcover-renters-home', 'home_insurance', 'https://goodcover.com', ARRAY['US'], NULL, false),
    ('Sure Insurance', 'sure-insurance-home', 'home_insurance', 'https://sureapp.com', ARRAY['US'], NULL, false)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- HOME INSURANCE — FLOOD-ONLY CARRIERS
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url, bundles_with_auto) VALUES
    ('FloodFlash', 'floodflash-home', 'home_insurance', 'https://floodflash.co', ARRAY['US'], NULL, false),
    ('Aon Edge Flood', 'aon-edge-flood-home', 'home_insurance', 'https://aon.com', ARRAY['US'], NULL, false),
    ('Marsh McLennan Personal Flood', 'marsh-mclennan-flood-home', 'home_insurance', 'https://mmc.com', ARRAY['US'], NULL, false),
    ('TypTap Insurance', 'typtap-home', 'home_insurance', 'https://typtap.com', ARRAY['FL'], NULL, true),
    ('Beyond Floods', 'beyond-floods-home', 'home_insurance', 'https://beyondfloods.com', ARRAY['US'], NULL, false),
    ('Flow Flood', 'flow-flood-home', 'home_insurance', 'https://flow.insurance', ARRAY['US'], NULL, false),
    ('Hiscox Flood', 'hiscox-flood-home', 'home_insurance', 'https://hiscox.com', ARRAY['US'], NULL, false),
    ('Palomar Specialty Flood', 'palomar-specialty-home', 'home_insurance', 'https://palomarspecialty.com', ARRAY['US'], NULL, false)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- HOME INSURANCE — EARTHQUAKE + WIND-ONLY
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url, bundles_with_auto) VALUES
    ('California Earthquake Authority', 'cea-earthquake-home', 'home_insurance', 'https://earthquakeauthority.com', ARRAY['CA'], NULL, false),
    ('GeoVera Specialty (Earthquake)', 'geovera-specialty-home', 'home_insurance', 'https://geovera.com', ARRAY['CA','HI','OR','WA','AL','MS','LA','TX'], NULL, false),
    ('Palomar Earthquake', 'palomar-earthquake-home', 'home_insurance', 'https://palomarspecialty.com', ARRAY['CA','OR','WA','NV','AZ'], NULL, false),
    ('Arrowhead Earthquake', 'arrowhead-earthquake-home', 'home_insurance', 'https://arrowheadgrp.com', ARRAY['CA','OR','WA'], NULL, false),
    ('Texas Windstorm Insurance', 'twia-wind-home', 'home_insurance', 'https://twia.org', ARRAY['TX'], NULL, false),
    ('Louisiana Citizens', 'la-citizens-home', 'home_insurance', 'https://lacitizens.com', ARRAY['LA'], NULL, false),
    ('Mississippi Wind Pool', 'ms-wind-pool-home', 'home_insurance', 'https://msplans.com', ARRAY['MS'], NULL, false),
    ('NC Coastal Wind Pool', 'nc-coastal-wind-home', 'home_insurance', 'https://ncjua-nciua.org', ARRAY['NC'], NULL, false),
    ('SC Wind Pool', 'sc-wind-pool-home', 'home_insurance', 'https://scwindandhail.com', ARRAY['SC'], NULL, false),
    ('Alabama Wind Pool', 'al-wind-pool-home', 'home_insurance', 'https://aiua.org', ARRAY['AL'], NULL, false),
    ('Georgia FAIR Plan', 'ga-fair-plan-home', 'home_insurance', 'https://gufair.com', ARRAY['GA'], NULL, false),
    ('Florida Citizens Property', 'fl-citizens-extended-home', 'home_insurance', 'https://citizensfla.com', ARRAY['FL'], NULL, false)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- HOME INSURANCE — INTERNATIONAL + ADDITIONAL HNW
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url, bundles_with_auto) VALUES
    ('Munich Re US Personal', 'munich-re-us-home', 'home_insurance', 'https://munichre.com', ARRAY['US'], NULL, true),
    ('Swiss Re Personal Lines', 'swiss-re-personal-home', 'home_insurance', 'https://swissre.com', ARRAY['US'], NULL, true),
    ('Generali US', 'generali-us-home', 'home_insurance', 'https://generaliglobalassistance.com', ARRAY['US'], NULL, true),
    ('Tokio Marine America', 'tokio-marine-america-home', 'home_insurance', 'https://tmamerica.com', ARRAY['US'], NULL, true),
    ('Aviva USA Home', 'aviva-usa-home', 'home_insurance', 'https://aviva.com', ARRAY['US'], NULL, true),
    ('AXA XL Personal', 'axa-xl-personal-home', 'home_insurance', 'https://axaxl.com', ARRAY['US'], NULL, true),
    ('Privilege Underwriters', 'privilege-underwriters-extended-home', 'home_insurance', 'https://pureinsurance.com', ARRAY['US'], NULL, true),
    ('Lloyd''s of London Personal', 'lloyds-of-london-personal-home', 'home_insurance', 'https://lloyds.com', ARRAY['US'], NULL, false),
    ('PURE High Net Worth', 'pure-hnw-home', 'home_insurance', 'https://pureinsurance.com', ARRAY['US'], NULL, true),
    ('Kingstone HNW', 'kingstone-hnw-home', 'home_insurance', 'https://kingstonecompanies.com', ARRAY['NY','NJ','PA','MA','CT','RI','NH'], NULL, true),
    ('Argo Group US Personal', 'argo-group-personal-home', 'home_insurance', 'https://argogroup.com', ARRAY['US'], NULL, false),
    ('Beazley Personal Lines', 'beazley-personal-home', 'home_insurance', 'https://beazley.com', ARRAY['US'], NULL, false),
    ('XL Catlin Personal', 'xl-catlin-personal-home', 'home_insurance', 'https://axaxl.com', ARRAY['US'], NULL, false),
    ('Hiscox Home', 'hiscox-home-extended', 'home_insurance', 'https://hiscox.com', ARRAY['US'], NULL, false),
    ('Sompo International Personal', 'sompo-international-home', 'home_insurance', 'https://sompo-intl.com', ARRAY['US'], NULL, false)
ON CONFLICT (slug) DO NOTHING;
