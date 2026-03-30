-- ============================================================================
-- Expanded Manufacturers: HVAC, Water Heaters, Laundry, Generators,
-- Sump Pumps, Well Water Systems, Bathroom Fixtures, Irrigation, Pool Systems
--
-- Uses ON CONFLICT to safely skip brands already in the kitchen catalog.
-- ============================================================================

SET ROLE postgres;

-- ======================== HVAC BRANDS ========================

INSERT INTO equipment_manufacturers (name, slug, parent_company, country_of_origin, website_url, support_url, support_phone, tier, description) VALUES

-- Budget / Builder Grade
('Goodman', 'goodman', 'Daikin Industries', 'US', 'https://www.goodmanmfg.com', 'https://www.goodmanmfg.com/support', '1-888-593-4822', 'budget',
 'Daikin-owned value brand. Extremely common in new construction and HVAC replacements. Builder-grade pricing with solid warranties.'),

('Payne', 'payne', 'Carrier Global', 'US', 'https://www.payne.com', 'https://www.payne.com/en/us/support/', '1-800-227-7437', 'budget',
 'Carrier budget line. Same factory builds, lower price point. Common in tract housing.'),

('RunTru', 'runtru', 'Trane Technologies', 'US', 'https://www.runtru.com', 'https://www.runtru.com/support', '1-855-254-4278', 'budget',
 'Trane value brand for cost-conscious installations. Launched 2018.'),

('Ameristar', 'ameristar', 'Trane Technologies', 'US', 'https://www.ameristar.us.com', 'https://www.ameristar.us.com/support', '1-855-254-4278', 'budget',
 'Trane budget tier distributed through independent dealers.'),

('Ducane', 'ducane', 'Lennox International', 'US', 'https://www.ducane.com', 'https://www.ducane.com/support', '1-800-953-6669', 'budget',
 'Lennox value brand. Reliable equipment at entry-level price points.')

ON CONFLICT (slug) DO NOTHING;

INSERT INTO equipment_manufacturers (name, slug, parent_company, country_of_origin, website_url, support_url, support_phone, tier, description) VALUES

-- Mainstream HVAC
('Rheem', 'rheem', 'Paloma Industries', 'US', 'https://www.rheem.com', 'https://www.rheem.com/support', '1-800-432-8373', 'mainstream',
 'Major HVAC and water heater manufacturer. Extensive product line from budget to premium.'),

('Ruud', 'ruud', 'Paloma Industries', 'US', 'https://www.ruud.com', 'https://www.ruud.com/support', '1-800-432-8373', 'mainstream',
 'Professional-channel twin of Rheem. Same equipment, sold through different dealer networks.'),

('York', 'york', 'Johnson Controls', 'US', 'https://www.york.com', 'https://www.york.com/residential-equipment/support', '1-800-910-9675', 'mainstream',
 'Johnson Controls residential brand. Strong in the Northeast and commercial crossover market.'),

('Heil', 'heil', 'ICP (Carrier)', 'US', 'https://www.heil-hvac.com', 'https://www.heil-hvac.com/support', '1-800-227-7437', 'mainstream',
 'ICP/Carrier brand sold through independent distributors.'),

('Coleman', 'coleman-hvac', 'Johnson Controls', 'US', 'https://www.colemanac.com', 'https://www.colemanac.com/support', '1-800-910-9675', 'mainstream',
 'Johnson Controls value-mainstream HVAC brand. Not related to Coleman outdoor products.')

ON CONFLICT (slug) DO NOTHING;

INSERT INTO equipment_manufacturers (name, slug, parent_company, country_of_origin, website_url, support_url, support_phone, tier, description) VALUES

-- Premium HVAC (The Big Three & Equivalents)
('Carrier', 'carrier', 'Carrier Global', 'US', 'https://www.carrier.com', 'https://www.carrier.com/residential/en/us/support/', '1-800-227-7437', 'premium',
 'The inventor of modern air conditioning. One of the Big Three. Extensive dealer network and strong brand recognition.'),

('Trane', 'trane', 'Trane Technologies', 'US', 'https://www.trane.com', 'https://www.trane.com/residential/en/support/', '1-855-254-4278', 'premium',
 'One of the Big Three HVAC brands. Known for durability — "It''s hard to stop a Trane." XV and XR series.'),

('American Standard', 'american-standard-hvac', 'Trane Technologies', 'US', 'https://www.americanstandardair.com', 'https://www.americanstandardair.com/support/', '1-855-254-4278', 'premium',
 'Trane twin for HVAC. Same internals, different branding. AccuComfort and Platinum series.'),

('Lennox', 'lennox', 'Lennox International', 'US', 'https://www.lennox.com', 'https://www.lennox.com/support', '1-800-953-6669', 'premium',
 'Premium HVAC manufacturer. Known for ultra-quiet operation and the SL28XCV variable-capacity AC.'),

('Bryant', 'bryant', 'Carrier Global', 'US', 'https://www.bryant.com', 'https://www.bryant.com/en/us/support/', '1-800-227-7437', 'premium',
 'Carrier premium twin brand. Evolution series with smart connectivity.'),

('Daikin', 'daikin', 'Daikin Industries', 'Japan', 'https://www.daikincomfort.com', 'https://www.daikincomfort.com/support', '1-888-593-4822', 'premium',
 'World''s largest HVAC manufacturer. Parent of Goodman. Known for inverter-driven variable-speed systems.')

ON CONFLICT (slug) DO NOTHING;

INSERT INTO equipment_manufacturers (name, slug, parent_company, country_of_origin, website_url, support_url, support_phone, tier, description) VALUES

-- High-End Heat Pumps & Mini-Splits
('Mitsubishi Electric', 'mitsubishi-electric', 'Mitsubishi Electric', 'Japan', 'https://www.mitsubishicomfort.com', 'https://www.mitsubishicomfort.com/support', '1-800-433-4822', 'luxury',
 'The gold standard in ductless mini-split systems. Hyper-Heat technology works down to -13°F.'),

('Fujitsu', 'fujitsu', 'Fujitsu General', 'Japan', 'https://www.fujitsugeneral.com', 'https://www.fujitsugeneral.com/us/support', '1-888-888-3424', 'premium',
 'Premium mini-split and ducted systems. Known for Halcyon series quiet operation.'),

-- Ultra-Luxury Boilers
('Viessmann', 'viessmann', 'Carrier Global', 'Germany', 'https://www.viessmann.us', 'https://www.viessmann.us/support', '1-800-288-0667', 'ultra-luxury',
 'German-engineered premium boilers and radiant heating. Stainless steel heat exchangers.'),

('Buderus', 'buderus', 'Robert Bosch GmbH', 'Germany', 'https://www.buderus.us', 'https://www.buderus.us/support', '1-800-283-3787', 'premium',
 'Bosch boiler brand. Cast iron and condensing boilers for hydronic heating.'),

('Weil-McLain', 'weil-mclain', 'Marley Industries', 'US', 'https://www.weil-mclain.com', 'https://www.weil-mclain.com/support', '1-800-753-7775', 'premium',
 'Leading cast iron boiler manufacturer. ECO, Ultra, and GV series.'),

('Navien', 'navien', 'KD Navien', 'South Korea', 'https://www.navien.com', 'https://www.navien.com/support', '1-800-519-8794', 'premium',
 'Leading tankless water heater and condensing boiler manufacturer. NPE and NCB series.'),

('Peerless Boiler', 'peerless-boiler', 'PB Heat (Bock Water Heaters)', 'US', 'https://www.peerlessboilers.com', 'https://www.peerlessboilers.com/support', '1-800-468-2770', 'premium',
 'Residential and light commercial cast iron boilers. PureFire and Pinnacle series.')

ON CONFLICT (slug) DO NOTHING;

-- ======================== WATER HEATER BRANDS ========================

INSERT INTO equipment_manufacturers (name, slug, parent_company, country_of_origin, website_url, support_url, support_phone, tier, description) VALUES

('A.O. Smith', 'ao-smith', 'A.O. Smith Corporation', 'US', 'https://www.aosmith.com', 'https://www.aosmith.com/support', '1-800-527-1953', 'mainstream',
 'One of the two dominant water heater manufacturers (with Rheem). ProLine, Signature, and Voltex series.'),

('State Water Heaters', 'state-water-heaters', 'A.O. Smith Corporation', 'US', 'https://www.statewaterheaters.com', 'https://www.statewaterheaters.com/support', '1-800-365-0024', 'mainstream',
 'A.O. Smith professional-channel brand. Same tanks, sold through plumber networks.'),

('Reliance', 'reliance', 'A.O. Smith Corporation', 'US', 'https://www.reliancewaterheaters.com', 'https://www.reliancewaterheaters.com/support', '1-800-527-1953', 'budget',
 'A.O. Smith retail brand sold at Home Depot and other big box stores.'),

('Richmond', 'richmond', 'Rheem Manufacturing', 'US', 'https://www.richmondwaterheaters.com', 'https://www.richmondwaterheaters.com/support', '1-800-432-8373', 'budget',
 'Rheem retail brand sold at Menards.'),

('Bradford White', 'bradford-white', 'Bradford White Corporation', 'US', 'https://www.bradfordwhite.com', 'https://www.bradfordwhite.com/support', '1-800-523-2931', 'premium',
 'Premium water heaters sold exclusively through professional installers. Icon and Defender series.'),

('Rinnai', 'rinnai', 'Rinnai Corporation', 'Japan', 'https://www.rinnai.us', 'https://www.rinnai.us/support', '1-800-621-9419', 'premium',
 'Premium tankless water heater manufacturer. Sensei and RU series. Known for reliability and longevity.'),

('Noritz', 'noritz', 'Noritz Corporation', 'Japan', 'https://www.noritz.com', 'https://www.noritz.com/support', '1-866-766-7489', 'premium',
 'Japanese tankless specialist. EZ series condensing units.'),

('Takagi', 'takagi', 'A.O. Smith Corporation', 'Japan', 'https://www.takagi.us.com', 'https://www.takagi.us.com/support', '1-866-882-5244', 'premium',
 'A.O. Smith-owned Japanese tankless brand. T-H3 and T-KJr series.'),

('EcoSmart', 'ecosmart', 'EcoSmart', 'US', 'https://www.ecosmart.com', 'https://www.ecosmart.com/support', '1-866-326-7627', 'budget',
 'Electric tankless specialist. Popular for point-of-use applications.'),

('Stiebel Eltron', 'stiebel-eltron', 'Stiebel Eltron GmbH', 'Germany', 'https://www.stiebel-eltron-usa.com', 'https://www.stiebel-eltron-usa.com/support', '1-800-582-8423', 'premium',
 'German-engineered electric tankless and heat pump water heaters. Tempra and Accelera series.'),

('Lochinvar', 'lochinvar', 'A.O. Smith Corporation', 'US', 'https://www.lochinvar.com', 'https://www.lochinvar.com/support', '1-615-889-8900', 'premium',
 'A.O. Smith commercial/premium brand. Knight and Armor series boilers and water heaters.'),

('HTP', 'htp', 'Heat Transfer Products', 'US', 'https://www.htproducts.com', 'https://www.htproducts.com/support', '1-800-323-9651', 'premium',
 'High-efficiency commercial and residential water heaters and boilers. Versa-Hydro and CrossOver series.'),

('Triangle Tube', 'triangle-tube', 'Triangle Tube (ACV)', 'US', 'https://www.triangletube.com', 'https://www.triangletube.com/support', '1-856-228-8881', 'premium',
 'Premium indirect water heaters and condensing boilers. Smart series.'),

('Eemax', 'eemax', 'Eemax Inc.', 'US', 'https://www.eemax.com', 'https://www.eemax.com/support', '1-800-543-6163', 'mainstream',
 'Electric tankless and point-of-use water heaters. Commercial and residential.')

ON CONFLICT (slug) DO NOTHING;

-- ======================== LAUNDRY BRANDS ========================

INSERT INTO equipment_manufacturers (name, slug, parent_company, country_of_origin, website_url, support_url, support_phone, tier, description) VALUES

('Speed Queen', 'speed-queen', 'Alliance Laundry Systems', 'US', 'https://www.speedqueen.com', 'https://www.speedqueen.com/support', '1-800-590-8872', 'premium',
 'Commercial-grade residential laundry. Built in Ripon, WI. Known for 25-year lifespan and metal construction.'),

('Haier', 'haier', 'Haier Group', 'China', 'https://www.haier.com/us/', 'https://www.haier.com/us/support', '1-877-337-3639', 'budget',
 'Parent company of GE Appliances. Budget compact laundry and small appliances.'),

('Blomberg', 'blomberg', 'Arcelik (Koc Holding)', 'Turkey', 'https://www.blombergappliances.com', 'https://www.blombergappliances.com/support', '1-800-459-7928', 'mainstream',
 'European compact laundry specialist. 24-inch ventless heat pump dryers. Sister brand to Beko.'),

('Asko', 'asko', 'Gorenje (Hisense)', 'Sweden', 'https://www.askona.com', 'https://www.askona.com/support', '1-800-898-1879', 'premium',
 'Scandinavian premium compact laundry. Known for durability and steel construction.'),

('Roper', 'roper', 'Whirlpool Corporation', 'US', 'https://www.roper-appliances.com', 'https://www.whirlpool.com/support', '1-800-447-6737', 'budget',
 'Whirlpool entry-level brand. Basic top-load washers and dryers.'),

('Crosley', 'crosley', 'Whirlpool Corporation', 'US', 'https://www.crosleyappliances.com', 'https://www.whirlpool.com/support', '1-800-944-2904', 'budget',
 'Whirlpool budget brand sold through independent dealers.'),

('Equator Advanced Appliances', 'equator', 'Equator Advanced Appliances', 'US', 'https://www.equatorappliances.com', 'https://www.equatorappliances.com/support', '1-800-935-1955', 'mainstream',
 'Compact all-in-one washer-dryer combos and ventless dryers.')

ON CONFLICT (slug) DO NOTHING;

-- ======================== GENERATOR BRANDS ========================

INSERT INTO equipment_manufacturers (name, slug, parent_company, country_of_origin, website_url, support_url, support_phone, tier, description) VALUES

('Generac', 'generac', 'Generac Holdings', 'US', 'https://www.generac.com', 'https://www.generac.com/support', '1-888-436-3722', 'premium',
 'Dominant standby generator manufacturer. Guardian and Protector series. ~75% US home standby market share.'),

('Kohler Power', 'kohler-generators', 'Kohler Co.', 'US', 'https://www.kohlerpower.com', 'https://www.kohlerpower.com/support', '1-800-544-2444', 'premium',
 'Premium standby and portable generators. OnCue Plus monitoring system.'),

('Cummins', 'cummins', 'Cummins Inc.', 'US', 'https://www.cummins.com/home-generators', 'https://www.cummins.com/support', '1-877-769-7669', 'premium',
 'QuietConnect series home standby generators. Formerly Onan residential brand.'),

('Honda', 'honda-power', 'Honda Motor Company', 'Japan', 'https://www.powerequipment.honda.com', 'https://www.powerequipment.honda.com/support', '1-770-497-6400', 'premium',
 'Gold standard in portable inverter generators. EU series known for legendary reliability and resale value.'),

('Yamaha', 'yamaha-power', 'Yamaha Motor Company', 'Japan', 'https://www.yamaha-motor.com/power-products', 'https://www.yamaha-motor.com/support', '1-866-894-1626', 'premium',
 'Premium portable inverter generators. EF series. Extremely quiet operation.'),

('Champion Power Equipment', 'champion-power', 'Champion Power Equipment', 'US', 'https://www.championpowerequipment.com', 'https://www.championpowerequipment.com/support', '1-877-338-0999', 'mainstream',
 'Popular dual-fuel portable and home standby generators. Strong value proposition.'),

('Westinghouse', 'westinghouse-power', 'Westinghouse Licensing', 'US', 'https://www.westinghouselighting.com', 'https://www.westinghouselighting.com/support', '1-855-944-3571', 'mainstream',
 'Licensed brand for portable generators. iGen and WGen series.'),

('Briggs & Stratton', 'briggs-stratton', 'Briggs & Stratton', 'US', 'https://www.briggsandstratton.com', 'https://www.briggsandstratton.com/support', '1-800-444-7774', 'mainstream',
 'Major small engine manufacturer. Portable and standby generators. PowerSmart and Fortress series.'),

('DuroMax', 'duromax', 'DuroMax Power Equipment', 'US', 'https://www.duromax.com', 'https://www.duromax.com/support', '1-909-915-2782', 'budget',
 'Value-priced dual-fuel portable generators.'),

('Firman', 'firman', 'Firman Power Equipment', 'US', 'https://www.firmanpowerequipment.com', 'https://www.firmanpowerequipment.com/support', '1-844-234-7626', 'budget',
 'Budget portable generators with dual-fuel and tri-fuel options.'),

('WEN', 'wen', 'WEN Products', 'US', 'https://www.wenproducts.com', 'https://www.wenproducts.com/support', '1-800-232-1195', 'budget',
 'Ultra-budget portable and inverter generators.'),

('Winco', 'winco', 'Winco Inc.', 'US', 'https://www.wincogen.com', 'https://www.wincogen.com/support', '1-507-831-1010', 'premium',
 'Commercial-grade home standby generators. Known for agricultural and critical power applications.')

ON CONFLICT (slug) DO NOTHING;

-- Power Stations
INSERT INTO equipment_manufacturers (name, slug, parent_company, country_of_origin, website_url, support_url, support_phone, tier, description) VALUES

('EcoFlow', 'ecoflow', 'EcoFlow Technology', 'China', 'https://www.ecoflow.com', 'https://www.ecoflow.com/support', '1-833-326-3569', 'premium',
 'Leading portable power station brand. DELTA and RIVER series. X-Stream fast charging technology.'),

('Jackery', 'jackery', 'Jackery Inc.', 'US', 'https://www.jackery.com', 'https://www.jackery.com/support', '1-888-672-0785', 'mainstream',
 'Pioneer in portable solar generators. Explorer series.'),

('Bluetti', 'bluetti', 'PowerOak (Shenzhen)', 'China', 'https://www.bluettipower.com', 'https://www.bluettipower.com/support', '1-888-780-0275', 'mainstream',
 'LiFePO4 power stations. AC200 and AC500 series. Known for battery longevity.'),

('Anker SOLIX', 'anker-solix', 'Anker Innovations', 'China', 'https://www.anker.com/solix', 'https://www.anker.com/support', '1-800-988-7973', 'mainstream',
 'Anker power station brand. SOLIX F-series with InfiniPower battery management.'),

('Goal Zero', 'goal-zero', 'NRG Energy (Goal Zero)', 'US', 'https://www.goalzero.com', 'https://www.goalzero.com/support', '1-888-794-6250', 'premium',
 'Premium portable power and solar panels. Yeti series. Popular for van life and emergency backup.'),

('EGO Power+', 'ego-power', 'Chervon Holdings', 'US', 'https://www.egopowerplus.com', 'https://www.egopowerplus.com/support', '1-855-346-5656', 'premium',
 'Battery-powered outdoor power equipment. Nexus power station for home backup.')

ON CONFLICT (slug) DO NOTHING;

-- ======================== SUMP PUMP BRANDS ========================

INSERT INTO equipment_manufacturers (name, slug, parent_company, country_of_origin, website_url, support_url, support_phone, tier, description) VALUES

('Zoeller', 'zoeller', 'Zoeller Company', 'US', 'https://www.zoeller.com', 'https://www.zoeller.com/support', '1-800-928-7867', 'premium',
 'The industry standard in residential sump pumps. Cast iron construction. M53, M98, and M267 series.'),

('Wayne', 'wayne', 'Scott Fetzer (Berkshire Hathaway)', 'US', 'https://www.waynepumps.com', 'https://www.waynepumps.com/support', '1-888-229-4957', 'mainstream',
 'Popular residential sump, well, and utility pumps. CDU series.'),

('Liberty Pumps', 'liberty-pumps', 'Liberty Pumps Inc.', 'US', 'https://www.libertypumps.com', 'https://www.libertypumps.com/support', '1-800-543-2550', 'premium',
 'Premium sump, sewage, and grinder pumps. SumpJet and StormCell backup systems.'),

('Little Giant', 'little-giant', 'Franklin Electric', 'US', 'https://www.lg-outdoor.com', 'https://www.lg-outdoor.com/support', '1-888-956-0000', 'mainstream',
 'Versatile pumps for sump, utility, and condensate applications.'),

('Everbilt', 'everbilt', 'Home Depot (HDX)', 'US', 'https://www.homedepot.com', 'https://www.homedepot.com/c/everbilt', '1-866-875-9663', 'budget',
 'Home Depot private label sump pumps and plumbing products.'),

('Superior Pump', 'superior-pump', 'Superior Pump (Pentair)', 'US', 'https://www.superiorpump.com', 'https://www.superiorpump.com/support', '1-800-738-5050', 'budget',
 'Budget sump and utility pumps available at big box retailers.'),

('Flotec', 'flotec', 'Pentair', 'US', 'https://www.flotecwater.com', 'https://www.flotecwater.com/support', '1-800-365-6832', 'budget',
 'Pentair budget brand for sump, well, and sprinkler pumps.'),

('Basement Watchdog', 'basement-watchdog', 'Glentronics Inc.', 'US', 'https://www.basementwatchdog.com', 'https://www.basementwatchdog.com/support', '1-800-991-0466', 'mainstream',
 'Dedicated battery backup sump pump systems. Big Dog and Special series.'),

('PumpSpy', 'pumpspy', 'PumpSpy Inc.', 'US', 'https://www.pumpspy.com', 'https://www.pumpspy.com/support', '1-855-438-4778', 'premium',
 'Smart sump pump monitoring system with WiFi alerts and battery backup.')

ON CONFLICT (slug) DO NOTHING;

-- ======================== WELL WATER & TREATMENT BRANDS ========================

INSERT INTO equipment_manufacturers (name, slug, parent_company, country_of_origin, website_url, support_url, support_phone, tier, description) VALUES

('Goulds Water Technology', 'goulds', 'Xylem Inc.', 'US', 'https://www.gouldswatertech.com', 'https://www.gouldswatertech.com/support', '1-866-325-4210', 'premium',
 'Premium submersible well pumps and jet pumps. J+ and GS series.'),

('Franklin Electric', 'franklin-electric', 'Franklin Electric Co.', 'US', 'https://www.franklin-electric.com', 'https://www.franklin-electric.com/support', '1-800-348-2420', 'premium',
 'Dominant submersible motor manufacturer. SubDrive and MonoDrive variable speed systems.'),

('Grundfos', 'grundfos', 'Grundfos Holding', 'Denmark', 'https://www.grundfos.com/us', 'https://www.grundfos.com/us/support', '1-800-921-7867', 'premium',
 'Danish pump manufacturer. SQE constant pressure systems. Known for energy efficiency.'),

('Amtrol', 'amtrol', 'Amtrol Inc.', 'US', 'https://www.amtrol.com', 'https://www.amtrol.com/support', '1-401-884-6300', 'premium',
 'Market leader in Well-X-Trol pressure tanks. Also Extrol expansion tanks.'),

('Sta-Rite', 'sta-rite', 'Pentair', 'US', 'https://www.pentair.com/en-us/brands/sta-rite.html', 'https://www.pentair.com/support', '1-800-831-7133', 'mainstream',
 'Pentair-owned well pump and pool equipment brand. Constant pressure and deep well systems.'),

('Culligan', 'culligan', 'Culligan International', 'US', 'https://www.culligan.com', 'https://www.culligan.com/support', '1-888-285-5442', 'premium',
 'Iconic water treatment dealer brand. Softeners, filters, and drinking water systems. Dealer-installed.'),

('Kinetico', 'kinetico', 'Kinetico Inc. (Axel Johnson)', 'US', 'https://www.kinetico.com', 'https://www.kinetico.com/support', '1-800-944-9283', 'premium',
 'Non-electric, demand-initiated water softeners and treatment. Known for twin-tank systems.'),

('SpringWell', 'springwell', 'SpringWell Water', 'US', 'https://www.springwellwater.com', 'https://www.springwellwater.com/support', '1-800-589-5592', 'mainstream',
 'Direct-to-consumer whole house water filtration and softening systems.'),

('Aquasana', 'aquasana', 'A.O. Smith Corporation', 'US', 'https://www.aquasana.com', 'https://www.aquasana.com/support', '1-866-662-6885', 'mainstream',
 'A.O. Smith-owned consumer water filtration. Rhino and OptimH2O series.'),

('Pelican', 'pelican', 'Pentair', 'US', 'https://www.pelicanwater.com', 'https://www.pelicanwater.com/support', '1-877-842-1635', 'mainstream',
 'Pentair consumer water treatment brand. NaturSoft salt-free softening.'),

('Viqua', 'viqua', 'Trojan Technologies (Danaher)', 'Canada', 'https://www.viqua.com', 'https://www.viqua.com/support', '1-800-265-7246', 'premium',
 'Residential UV water disinfection systems. IHS and D4 series. Annual lamp replacement.'),

('Fleck', 'fleck', 'Pentair', 'US', 'https://www.pentair.com/en-us/brands/fleck.html', 'https://www.pentair.com/support', '1-800-279-9404', 'mainstream',
 'Industry-standard water softener control valves. 5600SXT and 2510SXT series.')

ON CONFLICT (slug) DO NOTHING;

-- ======================== BATHROOM FIXTURE BRANDS ========================

INSERT INTO equipment_manufacturers (name, slug, parent_company, country_of_origin, website_url, support_url, support_phone, tier, description) VALUES

-- Mainstream
('Moen', 'moen', 'Fortune Brands Innovations', 'US', 'https://www.moen.com', 'https://www.moen.com/support', '1-800-289-6636', 'mainstream',
 'Most popular faucet brand in the US. Lifetime limited warranty. 1222 cartridge is industry-iconic.'),

('Delta Faucet', 'delta-faucet', 'Masco Corporation', 'US', 'https://www.deltafaucet.com', 'https://www.deltafaucet.com/support', '1-800-345-3358', 'mainstream',
 'Second-largest faucet brand. Touch2O and ShieldSpray technologies. MultiChoice universal valve.'),

('Kohler', 'kohler', 'Kohler Co.', 'US', 'https://www.us.kohler.com', 'https://www.us.kohler.com/support', '1-800-456-4537', 'premium',
 'Iconic American plumbing brand. Toilets, faucets, bathtubs, and shower systems. Cimarron and Memoirs series.'),

('American Standard', 'american-standard', 'LIXIL Group', 'US', 'https://www.americanstandard.com', 'https://www.americanstandard.com/support', '1-800-442-1902', 'mainstream',
 'Trusted plumbing brand since 1929. Champion flush, VorMax toilet. Studio and Town Square series.'),

('Pfister', 'pfister', 'Spectrum Brands', 'US', 'https://www.pfisterfaucets.com', 'https://www.pfisterfaucets.com/support', '1-800-732-8238', 'mainstream',
 'Value-forward faucet brand with solid finishes and Pforever warranty.'),

-- Premium
('TOTO', 'toto', 'TOTO Ltd.', 'Japan', 'https://www.totousa.com', 'https://www.totousa.com/support', '1-888-295-8134', 'premium',
 'World''s largest toilet manufacturer. Washlet bidet seats, Tornado Flush, CeFiONtect glaze.'),

('Brizo', 'brizo', 'Masco Corporation', 'US', 'https://www.brizo.com', 'https://www.brizo.com/support', '1-877-345-2749', 'luxury',
 'Delta luxury brand. Litze and Kintsu collections. SmartTouch technology.'),

('Hansgrohe', 'hansgrohe', 'Hansgrohe SE', 'Germany', 'https://www.hansgrohe-usa.com', 'https://www.hansgrohe-usa.com/support', '1-800-334-0455', 'premium',
 'German-engineered showers and faucets. Raindance and Croma showerheads. iBox universal installation.'),

('Grohe', 'grohe', 'LIXIL Group', 'Germany', 'https://www.grohe.com/us/', 'https://www.grohe.com/us/support', '1-800-444-7643', 'premium',
 'Premium German faucets and shower systems. Starlight chrome and SpeedClean anti-lime.'),

('Jacuzzi', 'jacuzzi', 'Jacuzzi Group (Apollo Management)', 'US', 'https://www.jacuzzi.com', 'https://www.jacuzzi.com/support', '1-800-288-4002', 'premium',
 'Iconic whirlpool and soaking tub brand. Also shower columns and walk-in tubs.'),

('Duravit', 'duravit', 'Duravit AG', 'Germany', 'https://www.duravit.us', 'https://www.duravit.us/support', '1-888-387-2848', 'luxury',
 'German premium bathroom ceramics. Philippe Starck design collaboration. SensoWash bidet seats.'),

-- Ultra-Luxury
('Waterworks', 'waterworks', 'Waterworks Holdings', 'US', 'https://www.waterworks.com', 'https://www.waterworks.com/contact', '1-800-899-6757', 'ultra-luxury',
 'The pinnacle of luxury bath fittings. Showroom-only sales. Handcrafted fixtures.'),

('Rohl', 'rohl', 'Fortune Brands Innovations', 'US', 'https://www.rohlfaucets.com', 'https://www.rohlfaucets.com/support', '1-800-777-9762', 'luxury',
 'Italian-inspired luxury faucets and fixtures. Perrin & Rowe and Shaws fireclay sinks.'),

('Dornbracht', 'dornbracht', 'Dornbracht AG & Co. KG', 'Germany', 'https://www.dornbracht.com', 'https://www.dornbracht.com/support', '1-800-774-1181', 'ultra-luxury',
 'Architectural ultra-luxury German fittings. Tara and Meta series. Culturing Life philosophy.'),

('Victoria + Albert', 'victoria-albert', 'Victoria + Albert Baths (TheWingfield Group)', 'UK', 'https://www.vandabaths.com', 'https://www.vandabaths.com/support', '1-800-421-7189', 'ultra-luxury',
 'Premium freestanding tubs inEnglobe volcanic limestone composite.')

ON CONFLICT (slug) DO NOTHING;

-- Budget bathroom fixtures
INSERT INTO equipment_manufacturers (name, slug, parent_company, country_of_origin, website_url, support_url, support_phone, tier, description) VALUES

('Glacier Bay', 'glacier-bay', 'Home Depot (HDX)', 'US', 'https://www.homedepot.com', 'https://www.homedepot.com/c/glacier-bay', '1-866-508-2547', 'budget',
 'Home Depot exclusive budget bathroom fixtures. Faucets, toilets, and vanities.'),

('Peerless', 'peerless-faucet', 'Masco Corporation', 'US', 'https://www.peerlessfaucet.com', 'https://www.peerlessfaucet.com/support', '1-800-438-6673', 'budget',
 'Delta economy brand. Reliable budget faucets with same underlying valve technology.'),

('Sterling', 'sterling', 'Kohler Co.', 'US', 'https://www.sterlingplumbing.com', 'https://www.sterlingplumbing.com/support', '1-888-783-7546', 'budget',
 'Kohler value brand. Affordable tubs, showers, and sinks.'),

('Symmons', 'symmons', 'Symmons Industries', 'US', 'https://www.symmons.com', 'https://www.symmons.com/support', '1-800-796-6667', 'mainstream',
 'Commercial and residential shower valves and faucets. Temptrol pressure-balancing valves.'),

('Kraus', 'kraus', 'Kraus USA', 'US', 'https://www.kraususa.com', 'https://www.kraususa.com/support', '1-800-775-0703', 'mainstream',
 'Modern kitchen and bathroom sinks and faucets. Direct-to-consumer value premium.')

ON CONFLICT (slug) DO NOTHING;

-- ======================== IRRIGATION BRANDS ========================

INSERT INTO equipment_manufacturers (name, slug, parent_company, country_of_origin, website_url, support_url, support_phone, tier, description) VALUES

('Rain Bird', 'rain-bird', 'Rain Bird Corporation', 'US', 'https://www.rainbird.com', 'https://www.rainbird.com/support', '1-800-724-6247', 'premium',
 'Founded 1933. The professional standard in irrigation. Rotors, spray heads, controllers, and drip systems.'),

('Hunter Industries', 'hunter-industries', 'Hunter Industries', 'US', 'https://www.hunterindustries.com', 'https://www.hunterindustries.com/support', '1-760-591-7383', 'premium',
 'Professional irrigation manufacturer. PGP rotor, MP Rotator, Hydrawise smart controller.'),

('Rachio', 'rachio', 'Rachio Inc.', 'US', 'https://www.rachio.com', 'https://www.rachio.com/support', '1-844-472-2446', 'premium',
 'Leading smart sprinkler controller. Weather Intelligence Plus, EPA WaterSense certified.'),

('Toro', 'toro', 'The Toro Company', 'US', 'https://www.toro.com', 'https://www.toro.com/support', '1-888-384-9939', 'mainstream',
 'Major irrigation and outdoor equipment manufacturer. Precision and T5 series rotors.'),

('Orbit', 'orbit', 'Orbit Irrigation', 'US', 'https://www.orbitonline.com', 'https://www.orbitonline.com/support', '1-800-488-6156', 'budget',
 'Popular retail irrigation brand. B-hyve smart timer, drip systems, and hose-end sprinklers.'),

('Irritrol', 'irritrol', 'The Toro Company', 'US', 'https://www.irritrol.com', 'https://www.irritrol.com/support', '1-800-634-8873', 'mainstream',
 'Toro-owned professional irrigation valves and controllers.'),

('K-Rain', 'k-rain', 'K-Rain Manufacturing', 'US', 'https://www.k-rain.com', 'https://www.k-rain.com/support', '1-800-735-7246', 'mainstream',
 'Professional rotors and spray heads. RPS series rotors, Pro-S spray bodies.'),

('Weathermatic', 'weathermatic', 'Weathermatic (Telsco)', 'US', 'https://www.weathermatic.com', 'https://www.weathermatic.com/support', '1-888-484-3776', 'premium',
 'Commercial-grade smart irrigation controllers with SL series and SmartLink cloud platform.'),

('Watts', 'watts', 'Watts Water Technologies', 'US', 'https://www.watts.com', 'https://www.watts.com/support', '1-978-688-1811', 'premium',
 'Leading manufacturer of backflow preventers, pressure regulators, and water safety products.'),

('Netafim', 'netafim', 'Orbia (Netafim)', 'Israel', 'https://www.netafim.com', 'https://www.netafim.com/support', '1-888-638-2346', 'premium',
 'Pioneer and world leader in drip irrigation technology. TechLine and UniRam series.')

ON CONFLICT (slug) DO NOTHING;

-- ======================== POOL SYSTEM BRANDS ========================

INSERT INTO equipment_manufacturers (name, slug, parent_company, country_of_origin, website_url, support_url, support_phone, tier, description) VALUES

-- The Big Three
('Pentair', 'pentair', 'Pentair plc', 'US', 'https://www.pentair.com', 'https://www.pentair.com/support', '1-800-831-7133', 'premium',
 'Major pool equipment manufacturer. IntelliFlo pumps, IntelliChlor salt systems, MasterTemp heaters.'),

('Hayward', 'hayward', 'Hayward Holdings', 'US', 'https://www.hayward.com', 'https://www.hayward.com/support', '1-908-351-5400', 'premium',
 'Pool equipment manufacturer. TriStar and Super Pump, AquaRite salt systems, H-Series heaters.'),

('Jandy', 'jandy', 'Fluidra S.A.', 'US', 'https://www.jandy.com', 'https://www.jandy.com/support', '1-800-822-7933', 'premium',
 'Fluidra-owned pool brand. iAqualink automation, JXi heaters, VS FloPro pumps.'),

-- Heaters
('Raypak', 'raypak', 'Rheem Manufacturing', 'US', 'https://www.raypak.com', 'https://www.raypak.com/support', '1-805-278-5300', 'premium',
 'Rheem-owned pool and spa heater brand. Digital gas heaters and heat pumps.'),

('AquaCal', 'aquacal', 'AquaCal AutoPilot', 'US', 'https://www.aquacal.com', 'https://www.aquacal.com/support', '1-727-823-5642', 'premium',
 'Pool heat pump manufacturer. TropiCal and HeatWave series. Known for efficiency.'),

-- Robotic Cleaners
('Maytronics', 'maytronics', 'Maytronics Ltd.', 'Israel', 'https://www.maytronics.com', 'https://www.maytronics.com/support', '1-888-372-9630', 'premium',
 'Manufacturer of Dolphin robotic pool cleaners. Market leader in robotic pool cleaning.'),

('Polaris', 'polaris-pool', 'Zodiac/Fluidra', 'US', 'https://www.polaris.com', 'https://www.polaris.com/support', '1-800-822-7933', 'mainstream',
 'Pressure-side pool cleaners. P39 and P945 series. Part of Fluidra/Zodiac family.'),

('Zodiac', 'zodiac-pool', 'Fluidra S.A.', 'US', 'https://www.zodiacpoolsystems.com', 'https://www.zodiacpoolsystems.com/support', '1-800-822-7933', 'mainstream',
 'Pool cleaners, heaters, and automation. Baracuda suction cleaners, LM series salt systems.'),

-- Salt Chlorine Generators
('AutoPilot', 'autopilot', 'AquaCal AutoPilot', 'US', 'https://www.autopilot.com', 'https://www.autopilot.com/support', '1-727-823-5642', 'mainstream',
 'Salt chlorine generator manufacturer. Pool Pilot and Digital Nano series.'),

('CircuPool', 'circupool', 'CircuPool', 'US', 'https://www.circupool.com', 'https://www.circupool.com/support', '1-800-564-9854', 'mainstream',
 'Direct-to-consumer salt chlorine generators. RJ and EDGE series. Titanium cells.'),

-- Above Ground / Budget
('Intex', 'intex', 'Intex Recreation', 'US', 'https://www.intexcorp.com', 'https://www.intexcorp.com/support', '1-800-234-6839', 'budget',
 'World''s largest inflatable and above-ground pool manufacturer. Krystal Clear filter systems.'),

-- Automation & Accessories
('Intermatic', 'intermatic', 'Intermatic Inc.', 'US', 'https://www.intermatic.com', 'https://www.intermatic.com/support', '1-815-675-7000', 'mainstream',
 'Pool timers, freeze protection, and lighting controls. PE series mechanical timers.')

ON CONFLICT (slug) DO NOTHING;
