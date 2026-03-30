SET ROLE postgres;
-- ============================================================================
-- Supplemental Manufacturers: Filling gaps from the research document
-- All brands listed in the doc but missing from the database
-- ============================================================================

-- ======================== WATER HEATER BRANDS (5 missing) ========================

INSERT INTO equipment_manufacturers (name, slug, parent_company, country_of_origin, website_url, support_url, support_phone, tier, description) VALUES
('American Water Heaters', 'american-water-heaters', 'A.O. Smith Corporation', 'US', 'https://www.americanwaterheater.com', 'https://www.americanwaterheater.com/support', '1-800-999-9515', 'budget',
 'A.O. Smith brand sold through wholesale distributors. Common in builder-grade installations.'),
('Kenmore', 'kenmore', 'Transformco (Sears)', 'US', 'https://www.kenmore.com', 'https://www.kenmore.com/support', '1-844-553-6667', 'mainstream',
 'Legacy Sears brand. Water heaters manufactured by A.O. Smith and Rheem. Still widely installed.'),
('SuperStor', 'superstor', 'Heat Transfer Products', 'US', 'https://www.htproducts.com/superstor', 'https://www.htproducts.com/support', '1-800-323-9651', 'premium',
 'Premium indirect water heaters heated by boiler. Contender and Ultra series stainless steel tanks.'),
('Vaughn', 'vaughn', 'Vaughn Thermal Corporation', 'US', 'https://www.vaughncorp.com', 'https://www.vaughncorp.com/support', '1-603-352-4411', 'premium',
 'Stone-lined indirect water heaters. Known for extreme longevity — some last 30+ years.'),
('SANCO2', 'sanco2', 'SANDEN Environmental Products', 'Japan', 'https://www.sancosystems.com', 'https://www.sancosystems.com/support', '1-503-564-6647', 'premium',
 'CO2 heat pump water heater. Uses natural R-744 refrigerant. Ultra-high efficiency in cold climates.')
ON CONFLICT (slug) DO NOTHING;

-- ======================== LAUNDRY BRANDS (2 missing — LG Styler/Samsung AirDresser are product lines, not brands) ========================

INSERT INTO equipment_manufacturers (name, slug, parent_company, country_of_origin, website_url, support_url, support_phone, tier, description) VALUES
('Magic Chef', 'magic-chef', 'MCA Corporation', 'US', 'https://www.magicchef.com', 'https://www.magicchef.com/support', '1-866-616-2664', 'budget',
 'Compact laundry and small kitchen appliances. Popular for apartments and RVs.')
ON CONFLICT (slug) DO NOTHING;

-- ======================== GENERATOR BRANDS (5 truly missing — Champion Home Standby = Champion Power, Caterpillar) ========================

INSERT INTO equipment_manufacturers (name, slug, parent_company, country_of_origin, website_url, support_url, support_phone, tier, description) VALUES
('Predator', 'predator', 'Harbor Freight Tools', 'US', 'https://www.harborfreight.com', 'https://www.harborfreight.com/support', '1-800-423-2567', 'budget',
 'Harbor Freight private label generators. Ultra-budget pricing. Widely used for jobsite power.'),
('Pulsar', 'pulsar', 'Pulsar Products', 'US', 'https://www.pulsarproducts.com', 'https://www.pulsarproducts.com/support', '1-888-550-2366', 'budget',
 'Budget dual-fuel portable generators. Popular entry-level option.'),
('Sportsman', 'sportsman', 'Buffalo Tools/Sportsman', 'US', 'https://www.sportsmanseries.com', 'https://www.sportsmanseries.com/support', '1-800-761-0486', 'budget',
 'Budget portable generators. Gasoline and dual-fuel models.'),
('Craftsman', 'craftsman', 'Stanley Black & Decker', 'US', 'https://www.craftsman.com', 'https://www.craftsman.com/support', '1-888-331-4569', 'mainstream',
 'Licensed brand for portable generators and outdoor power equipment.'),
('Ryobi', 'ryobi', 'Techtronic Industries (TTI)', 'Japan', 'https://www.ryobitools.com', 'https://www.ryobitools.com/support', '1-800-525-2579', 'mainstream',
 'Home Depot exclusive power tool brand. Portable and inverter generators. ONE+ battery platform.'),
('Caterpillar', 'caterpillar', 'Caterpillar Inc.', 'US', 'https://www.cat.com', 'https://www.cat.com/support', '1-888-228-4836', 'premium',
 'Industrial/commercial generator giant. CAT RP series portable generators for residential use.')
ON CONFLICT (slug) DO NOTHING;

-- ======================== SUMP PUMP BRANDS (15 missing) ========================

INSERT INTO equipment_manufacturers (name, slug, parent_company, country_of_origin, website_url, support_url, support_phone, tier, description) VALUES
('Utilitech', 'utilitech', 'Lowes (AO Smith/Pentair)', 'US', 'https://www.lowes.com', 'https://www.lowes.com/l/utilitech', '1-888-775-6937', 'budget',
 'Lowes private label pumps and plumbing products.'),
('Drummond', 'drummond', 'Harbor Freight Tools', 'US', 'https://www.harborfreight.com', 'https://www.harborfreight.com/support', '1-800-423-2567', 'budget',
 'Harbor Freight private label sump and utility pumps. Ultra-budget pricing.'),
('Simer', 'simer', 'Pentair', 'US', 'https://www.simerpumps.com', 'https://www.simerpumps.com/support', '1-800-468-7867', 'budget',
 'Pentair budget pump brand. Sump, utility, and sewage pumps.'),
('Ridgid', 'ridgid', 'Emerson Electric (Ridge Tool)', 'US', 'https://www.ridgid.com', 'https://www.ridgid.com/support', '1-800-474-3443', 'mainstream',
 'Professional-grade plumbing tools and pumps. Known for cast iron sump pumps.'),
('ECO-FLO', 'eco-flo', 'ECO-FLO Products', 'US', 'https://www.ecoflopumps.com', 'https://www.ecoflopumps.com/support', '1-800-226-4234', 'mainstream',
 'Affordable sump, well, and utility pumps. Wide retail availability.'),
('Star Water Systems', 'star-water-systems', 'Star Water Systems', 'US', 'https://www.starwatersystems.com', 'https://www.starwatersystems.com/support', '1-800-782-7529', 'mainstream',
 'Well and sump pump manufacturer. Formerly Star Pump.'),
('BurCam', 'burcam', 'BurCam Inc.', 'Canada', 'https://www.burcam.com', 'https://www.burcam.com/support', '1-877-228-7226', 'mainstream',
 'Canadian pump manufacturer. Sump, effluent, sewage, and well pumps.'),
('Myers', 'myers', 'Pentair', 'US', 'https://www.femyers.com', 'https://www.femyers.com/support', '1-888-987-8677', 'premium',
 'Pentair professional brand. Premium cast iron sump and sewage pumps.'),
('Goulds Pumps', 'goulds-pumps', 'Xylem Inc.', 'US', 'https://www.gouldspumps.com', 'https://www.gouldspumps.com/support', '1-866-325-4210', 'premium',
 'Xylem professional-grade sump and effluent pumps. J+ and SJ series.'),
('Hydromatic', 'hydromatic', 'Pentair', 'US', 'https://www.hydromatic.com', 'https://www.hydromatic.com/support', '1-888-987-8677', 'premium',
 'Pentair premium sewage and effluent pump brand. SKV and SK series.'),
('Barnes', 'barnes', 'Crane Pumps & Systems', 'US', 'https://www.cranepumps.com/barnes', 'https://www.cranepumps.com/support', '1-937-778-8947', 'premium',
 'Professional sewage and effluent pumps. Ogre series grinder pumps.'),
('Tsurumi', 'tsurumi', 'Tsurumi Manufacturing', 'Japan', 'https://www.tsurumipump.com', 'https://www.tsurumipump.com/support', '1-630-793-0127', 'premium',
 'Japanese industrial pump manufacturer. LSC and LB series residential sump pumps.'),
('Glentronics', 'glentronics', 'Glentronics Inc.', 'US', 'https://www.glentronics.com', 'https://www.glentronics.com/support', '1-800-991-0466', 'mainstream',
 'Parent company of Basement Watchdog. Pro Series battery backup and combination pumps.'),
('Ion Technologies', 'ion-technologies', 'Ion Technologies', 'US', 'https://www.iontechnologies.net', 'https://www.iontechnologies.net/support', '1-573-642-1758', 'premium',
 'Advanced digital float switch technology for sump pumps. ioSwitch and MightyFlex series.'),
('Water Commander', 'water-commander', 'Water Commander', 'US', 'https://www.watercommander.com', 'https://www.watercommander.com/support', '1-855-928-3726', 'mainstream',
 'Water-powered backup sump pump. No electricity or battery needed.')
ON CONFLICT (slug) DO NOTHING;

-- Basepump is water-powered, similar concept
INSERT INTO equipment_manufacturers (name, slug, parent_company, country_of_origin, website_url, support_url, support_phone, tier, description) VALUES
('Basepump', 'basepump', 'Basepump Inc.', 'US', 'https://www.basepump.com', 'https://www.basepump.com/support', '1-231-796-8088', 'mainstream',
 'Water-powered backup sump pump. Uses municipal water pressure — no battery needed.')
ON CONFLICT (slug) DO NOTHING;

-- ======================== WELL WATER BRANDS (9 missing) ========================

INSERT INTO equipment_manufacturers (name, slug, parent_company, country_of_origin, website_url, support_url, support_phone, tier, description) VALUES
('Berkeley', 'berkeley', 'Pentair', 'US', 'https://www.pentair.com/en-us/brands/berkeley.html', 'https://www.pentair.com/support', '1-800-831-7133', 'mainstream',
 'Pentair well pump brand. Deep well jet and submersible pumps.'),
('WaterWorker', 'waterworker', 'Amtrol Inc.', 'US', 'https://www.amtrol.com/waterworker', 'https://www.amtrol.com/support', '1-401-884-6300', 'budget',
 'Amtrol retail pressure tank brand. Available at Home Depot and hardware stores.'),
('Express Water', 'express-water', 'Express Water Inc.', 'US', 'https://www.expresswater.com', 'https://www.expresswater.com/support', '1-323-674-0678', 'budget',
 'Direct-to-consumer water filtration. Affordable RO and whole-house systems.'),
('Flexcon', 'flexcon', 'Flexcon Industries', 'US', 'https://www.flexconind.com', 'https://www.flexconind.com/support', '1-800-527-0030', 'mainstream',
 'Well pressure tanks and expansion tanks. FL and CAD series.'),
('EcoWater', 'ecowater', 'Marmon Group (Berkshire Hathaway)', 'US', 'https://www.ecowater.com', 'https://www.ecowater.com/support', '1-800-942-7873', 'premium',
 'Dealer-installed water softeners and treatment systems. HydroLink Plus smart monitoring.'),
('Water-Right', 'water-right', 'Water-Right Inc.', 'US', 'https://www.water-right.com', 'https://www.water-right.com/support', '1-800-777-1426', 'premium',
 'Dealer-installed water treatment. Sanitizer Plus and Impression series softeners.'),
('Clack', 'clack', 'Clack Corporation', 'US', 'https://www.clackcorp.com', 'https://www.clackcorp.com/support', '1-800-992-5225', 'mainstream',
 'Industry-standard water treatment control valves. WS1 series used in most custom-built softeners.'),
('Luminor', 'luminor', 'Luminor Environmental', 'Canada', 'https://www.luminoruv.com', 'https://www.luminoruv.com/support', '1-800-265-7246', 'premium',
 'UV water disinfection systems. Blackcomb and Hallett series.'),
('TrojanUV', 'trojanuv', 'Trojan Technologies (Danaher)', 'Canada', 'https://www.trojanuv.com', 'https://www.trojanuv.com/support', '1-888-220-6118', 'premium',
 'Commercial and residential UV disinfection. Parent company of Viqua brand.')
ON CONFLICT (slug) DO NOTHING;

-- ======================== BATHROOM FIXTURE BRANDS (11 missing) ========================

INSERT INTO equipment_manufacturers (name, slug, parent_company, country_of_origin, website_url, support_url, support_phone, tier, description) VALUES
('Project Source', 'project-source', 'Lowes (LG Sourcing)', 'US', 'https://www.lowes.com', 'https://www.lowes.com/l/project-source', '1-800-445-6937', 'budget',
 'Lowes private label budget bathroom fixtures. Faucets, toilets, and accessories.'),
('Gerber', 'gerber', 'Globe Union Group', 'US', 'https://www.gerberonline.com', 'https://www.gerberonline.com/support', '1-866-538-5536', 'budget',
 'Professional-grade toilets and faucets. Maxwell and Viper series. Sold through plumbing wholesalers.'),
('Vigo', 'vigo', 'Vigo Industries', 'US', 'https://www.vigoindustries.com', 'https://www.vigoindustries.com/support', '1-866-591-8446', 'mainstream',
 'Modern vessel sinks, frameless shower doors, and faucets. Direct-to-consumer premium.'),
('Signature Hardware', 'signature-hardware', 'Signature Hardware (Build.com)', 'US', 'https://www.signaturehardware.com', 'https://www.signaturehardware.com/support', '1-866-855-2284', 'premium',
 'Curated plumbing fixtures and bathroom hardware. Online-focused premium retailer.'),
('Villeroy & Boch', 'villeroy-boch', 'Villeroy & Boch AG', 'Germany', 'https://www.villeroy-boch.com', 'https://www.villeroy-boch.com/support', '1-877-505-5350', 'luxury',
 'German ceramics and bathroom fixtures since 1748. Subway and Artis series.'),
('Kallista', 'kallista', 'Kohler Co.', 'US', 'https://www.kallista.com', 'https://www.kallista.com/support', '1-888-452-5547', 'ultra-luxury',
 'Kohler ultra-luxury brand. One and Script collections. Hand-finished designer fixtures.'),
('Newport Brass', 'newport-brass', 'Brasstech Inc.', 'US', 'https://www.newportbrass.com', 'https://www.newportbrass.com/support', '1-949-417-5207', 'luxury',
 'American-made luxury faucets and bath accessories. 30+ finish options.'),
('DXV', 'dxv', 'LIXIL Group', 'US', 'https://www.dxv.com', 'https://www.dxv.com/support', '1-800-442-1902', 'luxury',
 'American Standard luxury brand. 3D-printed faucets and modern design collections.'),
('Watermark', 'watermark', 'Watermark Designs', 'US', 'https://www.watermark-designs.com', 'https://www.watermark-designs.com/support', '1-800-842-7277', 'ultra-luxury',
 'Brooklyn-based luxury faucets and shower systems. 70+ collections, 65+ finish options.'),
('Franz Viegener', 'franz-viegener', 'Franz Viegener', 'Argentina', 'https://www.franzviegener.com', 'https://www.franzviegener.com/support', NULL, 'ultra-luxury',
 'Argentine luxury faucets and fixtures. Smooth Lines, Edge, and Lollipop collections.')
ON CONFLICT (slug) DO NOTHING;

-- ======================== IRRIGATION BRANDS (12 missing — Hydrawise/B-hyve are product lines) ========================

INSERT INTO equipment_manufacturers (name, slug, parent_company, country_of_origin, website_url, support_url, support_phone, tier, description) VALUES
('Melnor', 'melnor', 'Melnor Inc.', 'US', 'https://www.melnor.com', 'https://www.melnor.com/support', '1-800-535-3426', 'budget',
 'Hose-end sprinklers, timers, and watering accessories. Retail-focused.'),
('Gilmour', 'gilmour', 'Fiskars Group', 'US', 'https://www.gilmour.com', 'https://www.gilmour.com/support', '1-800-458-6672', 'budget',
 'Garden hoses, nozzles, and sprinklers. Part of the Fiskars family.'),
('Raindrip', 'raindrip', 'NDS Inc.', 'US', 'https://www.raindrip.com', 'https://www.raindrip.com/support', '1-800-367-3747', 'budget',
 'DIY drip irrigation kits and components. Available at Home Depot and Lowes.'),
('DIG', 'dig', 'DIG Corporation', 'US', 'https://www.digcorp.com', 'https://www.digcorp.com/support', '1-800-344-2281', 'budget',
 'Drip irrigation and micro-sprinkler systems for residential and agricultural use.'),
('Netro', 'netro', 'Netro Inc.', 'US', 'https://www.netrohome.com', 'https://www.netrohome.com/support', NULL, 'mainstream',
 'Smart sprinkler controller with Whisperer soil sensor. AI-powered scheduling.'),
('Yardian', 'yardian', 'Aeon Matrix', 'US', 'https://www.yardian.com', 'https://www.yardian.com/support', NULL, 'mainstream',
 'Smart sprinkler controller with built-in HD camera for yard monitoring.'),
('Flume', 'flume', 'Flume Inc.', 'US', 'https://www.flumewater.com', 'https://www.flumewater.com/support', '1-844-258-3586', 'premium',
 'Smart water monitor that detects leaks and tracks usage. Clamps on to water meter.'),
('Antelco', 'antelco', 'Antelco Pty Ltd', 'Australia', 'https://www.antelco.com', 'https://www.antelco.com/support', NULL, 'mainstream',
 'Australian micro-irrigation manufacturer. Shrubbler, Rotor Spray, and cane emitters.'),
('Jain Irrigation', 'jain-irrigation', 'Jain Irrigation Systems', 'India', 'https://www.jains.com', 'https://www.jains.com/support', NULL, 'mainstream',
 'Global drip irrigation and micro-sprinkler manufacturer. Turbo Cascade and J-Turbo series.'),
('Febco', 'febco', 'Watts Water Technologies', 'US', 'https://www.watts.com/brands/febco', 'https://www.watts.com/support', '1-978-688-1811', 'premium',
 'Watts-owned backflow preventer brand. 765 PVB and 825Y series.'),
('Wilkins', 'wilkins', 'Zurn Industries', 'US', 'https://www.zurn.com/brands/wilkins', 'https://www.zurn.com/support', '1-855-663-9876', 'premium',
 'Zurn-owned backflow preventer brand. 375 and 975XL series. Common in municipal-required installations.'),
('Champion Irrigation', 'champion-irrigation', 'Champion Irrigation Products', 'US', 'https://www.championirr.com', 'https://www.championirr.com/support', '1-800-456-4513', 'budget',
 'Budget sprinkler heads and impact sprinklers for residential use.')
ON CONFLICT (slug) DO NOTHING;

-- ======================== POOL BRANDS (12 truly missing — some are product lines) ========================

INSERT INTO equipment_manufacturers (name, slug, parent_company, country_of_origin, website_url, support_url, support_phone, tier, description) VALUES
('GulfStream', 'gulfstream', 'GulfStream Heat Pumps', 'US', 'https://www.gulfstreamheatpumps.com', 'https://www.gulfstreamheatpumps.com/support', '1-727-572-5900', 'mainstream',
 'Pool heat pump manufacturer. HE series and commercial units.'),
('Coates', 'coates', 'Coates Heaters', 'US', 'https://www.coatesheaters.com', 'https://www.coatesheaters.com/support', '1-805-654-4084', 'mainstream',
 'Electric pool and spa heaters. Industrial-style titanium heating elements.'),
('Aquabot', 'aquabot', 'Aquatron Robotic Technology', 'US', 'https://www.aquabot.com', 'https://www.aquabot.com/support', '1-800-845-8440', 'mainstream',
 'Robotic pool cleaner manufacturer. Breeze, Rapids, and X4 series.'),
('Bestway', 'bestway', 'Bestway Global', 'China', 'https://www.bestway.com', 'https://www.bestway.com/support', '1-855-838-5460', 'budget',
 'Above-ground pools, inflatable spas, and pool accessories. Coleman-branded pools.'),
('Waterway Plastics', 'waterway-plastics', 'Waterway Plastics', 'US', 'https://www.waterway.com', 'https://www.waterway.com/support', '1-805-981-0262', 'mainstream',
 'Pool and spa pump, fitting, and jet manufacturer. Champion and Executive series pumps.'),
('Harris', 'harris-pool', 'Harris Pool Products', 'US', 'https://www.harrispoolproducts.com', 'https://www.harrispoolproducts.com/support', '1-888-527-7665', 'budget',
 'Budget pool pumps and filters. ProForce and H1572730 series. Amazon best-seller.'),
('Loop-Loc', 'loop-loc', 'Loop-Loc Ltd.', 'US', 'https://www.looploc.com', 'https://www.looploc.com/support', '1-800-542-7489', 'premium',
 'Premium mesh and solid safety pool covers. Baby-Loc fence. Made on Long Island, NY.'),
('Latham', 'latham', 'Latham Pool Products', 'US', 'https://www.lathampool.com', 'https://www.lathampool.com/support', '1-800-533-3902', 'premium',
 'Largest in-ground pool manufacturer in North America. Fiberglass and vinyl liner pools.'),
('S.R. Smith', 'sr-smith', 'S.R. Smith LLC', 'US', 'https://www.srsmith.com', 'https://www.srsmith.com/support', '1-800-824-4387', 'mainstream',
 'Pool deck equipment: diving boards, slides, handrails, ladders, and LED pool lights.'),
('Paramount', 'paramount', 'Paramount Pool & Spa Systems', 'US', 'https://www.paramount.com', 'https://www.paramount.com/support', '1-800-621-5886', 'premium',
 'In-floor pool cleaning systems. PCC2000 and PV3 pop-up head systems.'),
('Waterco', 'waterco', 'Waterco Limited', 'Australia', 'https://www.waterco.com', 'https://www.waterco.com/support', '1-800-232-4044', 'mainstream',
 'Australian pool equipment manufacturer. Hydrostorm pumps, MultiCyclone filters, Electrochlor salt systems.')
ON CONFLICT (slug) DO NOTHING;
