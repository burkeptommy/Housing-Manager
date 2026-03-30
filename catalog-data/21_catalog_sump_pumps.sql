SET ROLE postgres;
-- ============================================================================
-- Equipment Catalog: Sump Pumps
-- Brands: Zoeller, Liberty Pumps, Wayne, Little Giant, Everbilt,
--         Superior Pump, Flotec, Basement Watchdog, PumpSpy
-- Categories: submersible, pedestal, battery-backup, combination, sewage-ejector
-- ============================================================================


-- ======================== ZOELLER (Premium) ========================

-- Zoeller Submersible
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('M53', 'Mighty-Mate 1/3 HP Submersible', 'Mighty-Mate', 2580, 10, false, 200, ARRAY['Cast iron construction','Automatic float switch','Oil-filled motor','Non-clogging vortex impeller'], '{"hp": 0.33, "gph_at_10ft": 2580, "head_ft": 19.5, "switch_type": "float", "discharge": "1.5_inch", "cord_ft": 9, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.zoeller.com/products/m53'),
  ('M57', 'Mighty-Mate 1/3 HP Submersible', 'Mighty-Mate', 2580, 10, false, 220, ARRAY['Cast iron construction','Auto/manual switch','Oil-filled motor','Non-clogging vortex impeller'], '{"hp": 0.33, "gph_at_10ft": 2580, "head_ft": 19.5, "switch_type": "variable_level", "discharge": "1.5_inch", "cord_ft": 9, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.zoeller.com/products/m57'),
  ('M63', 'Premium 1/3 HP Submersible', 'Premium', 2400, 10, false, 250, ARRAY['Cast iron construction','Stainless steel guard','Thermal overload protection','Engineered resin base'], '{"hp": 0.33, "gph_at_10ft": 2400, "head_ft": 19, "switch_type": "float", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.zoeller.com/products/m63'),
  ('M73', 'Pro 1/3 HP Submersible', 'Pro', 2580, 12, false, 275, ARRAY['Cast iron construction','Polypropylene base','Oil-filled motor','Automatic float'], '{"hp": 0.33, "gph_at_10ft": 2580, "head_ft": 19.5, "switch_type": "float", "discharge": "1.5_inch", "cord_ft": 15, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.zoeller.com/products/m73'),
  ('M84', 'HT 1/2 HP Submersible', 'HT', 3420, 10, false, 300, ARRAY['Cast iron construction','High-temp motor winding','Automatic float switch','Non-clogging impeller'], '{"hp": 0.5, "gph_at_10ft": 3420, "head_ft": 24, "switch_type": "float", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.zoeller.com/products/m84'),
  ('M95', 'Premium 1/2 HP Submersible', 'Premium', 3420, 12, false, 325, ARRAY['Cast iron construction','Premium float switch','Thermal overload protection','High capacity'], '{"hp": 0.5, "gph_at_10ft": 3420, "head_ft": 24, "switch_type": "float", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.zoeller.com/products/m95'),
  ('M98', 'Flow-Mate 1/2 HP Submersible', 'Flow-Mate', 4320, 10, false, 280, ARRAY['Cast iron construction','Automatic float switch','High-capacity impeller','Oil-filled motor'], '{"hp": 0.5, "gph_at_10ft": 4320, "head_ft": 25, "switch_type": "float", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.zoeller.com/products/m98'),
  ('M264', 'Waste-Mate 3/4 HP Submersible', 'Waste-Mate', 5400, 12, false, 420, ARRAY['Cast iron construction','Non-clogging vortex impeller','Heavy-duty motor','Auto float switch'], '{"hp": 0.75, "gph_at_10ft": 5400, "head_ft": 29, "switch_type": "float", "discharge": "2_inch", "cord_ft": 15, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.zoeller.com/products/m264'),
  ('M267', 'Waste-Mate 1/2 HP Submersible', 'Waste-Mate', 4200, 10, false, 350, ARRAY['Cast iron construction','2-inch solids handling','Non-clogging vortex impeller','Auto float switch'], '{"hp": 0.5, "gph_at_10ft": 4200, "head_ft": 21, "switch_type": "float", "discharge": "2_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.zoeller.com/products/m267')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'zoeller' AND c.slug = 'sump-pump-submersible';

-- Zoeller Sewage Ejector
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('M264', 'Waste-Mate 3/4 HP Sewage Ejector', 'Waste-Mate', 5400, 10, false, 450, ARRAY['Cast iron construction','2-inch solids handling','Non-clogging vortex impeller','Auto float switch'], '{"hp": 0.75, "gph_at_10ft": 5400, "head_ft": 29, "switch_type": "float", "discharge": "2_inch", "solids_handling": "2_inch", "cord_ft": 15, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.zoeller.com/products/m264'),
  ('M266', 'Waste-Mate 1/2 HP Sewage Ejector', 'Waste-Mate', 4200, 10, false, 400, ARRAY['Cast iron construction','2-inch solids handling','Non-clogging vortex impeller','Auto float switch'], '{"hp": 0.5, "gph_at_10ft": 4200, "head_ft": 21, "switch_type": "float", "discharge": "2_inch", "solids_handling": "2_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.zoeller.com/products/m266'),
  ('M292', 'Waste-Mate 1/2 HP Sewage Pump', 'Waste-Mate', 3780, 10, false, 420, ARRAY['Cast iron construction','2-inch solids handling','Automatic operation','Heavy-duty motor'], '{"hp": 0.5, "gph_at_10ft": 3780, "head_ft": 21, "switch_type": "float", "discharge": "2_inch", "solids_handling": "2_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.zoeller.com/products/m292')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'zoeller' AND c.slug = 'sump-pump-sewage-ejector';


-- ======================== LIBERTY PUMPS (Premium) ========================

-- Liberty Submersible
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('237', '1/3 HP Submersible Sump Pump', 'Sump', 3000, 10, false, 220, ARRAY['Cast iron construction','Quick-disconnect power cord','VMF switch','Powder coat finish'], '{"hp": 0.33, "gph_at_10ft": 3000, "head_ft": 22, "switch_type": "vmf_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.libertypumps.com/product/237'),
  ('240', '1/4 HP Submersible Sump Pump', 'Sump', 2160, 10, false, 170, ARRAY['Cast iron housing','Automatic float switch','Oil-filled motor','Compact design'], '{"hp": 0.25, "gph_at_10ft": 2160, "head_ft": 19, "switch_type": "float", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.libertypumps.com/product/240'),
  ('257', '1/3 HP Submersible Sump Pump', 'Sump', 3060, 10, false, 230, ARRAY['Cast iron construction','VMF switch technology','Quick-disconnect cord','25 ft shut-off head'], '{"hp": 0.33, "gph_at_10ft": 3060, "head_ft": 25, "switch_type": "vmf_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.libertypumps.com/product/257'),
  ('283', '1/2 HP Submersible Sump Pump', 'Sump', 3720, 12, false, 295, ARRAY['Cast iron construction','VMF switch','Quick-disconnect cord','High-capacity motor'], '{"hp": 0.5, "gph_at_10ft": 3720, "head_ft": 30, "switch_type": "vmf_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.libertypumps.com/product/283'),
  ('287', '3/4 HP Submersible Sump Pump', 'Sump', 4500, 12, false, 370, ARRAY['Cast iron construction','VMF switch','Heavy-duty motor','Quick-disconnect cord'], '{"hp": 0.75, "gph_at_10ft": 4500, "head_ft": 35, "switch_type": "vmf_float", "discharge": "1.5_inch", "cord_ft": 15, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.libertypumps.com/product/287'),
  ('S37', 'SumpJet 1/3 HP Water-Powered Backup', 'SumpJet', 1320, 15, false, 320, ARRAY['No battery needed','Water-powered backup','Automatic activation','Alarm included'], '{"hp": 0, "gph_at_10ft": 1320, "head_ft": 20, "switch_type": "float", "discharge": "1.5_inch", "cord_ft": 0, "material": "thermoplastic", "phase": "none", "voltage": 0, "power_source": "water_pressure"}', 'https://www.libertypumps.com/product/sumpjet')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'liberty-pumps' AND c.slug = 'sump-pump-submersible';

-- Liberty Combination (primary + backup)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('PC257-441', '1/3 HP Combo w/ Battery Backup', 'ProVore', 3060, 10, false, 800, ARRAY['1/3 HP primary pump','Battery backup included','WiFi-ready','Audible alarm'], '{"hp_primary": 0.33, "gph_at_10ft": 3060, "head_ft": 25, "switch_type": "vmf_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "battery": "deep_cycle", "voltage": 115}', 'https://www.libertypumps.com/product/pc257-441'),
  ('PC370-441', '1/2 HP Combo w/ Battery Backup', 'ProVore', 3720, 10, false, 900, ARRAY['1/2 HP primary pump','Battery backup included','Audible alarm','Quick-disconnect cord'], '{"hp_primary": 0.5, "gph_at_10ft": 3720, "head_ft": 30, "switch_type": "vmf_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "battery": "deep_cycle", "voltage": 115}', 'https://www.libertypumps.com/product/pc370-441')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'liberty-pumps' AND c.slug = 'sump-pump-combination';

-- Liberty Sewage Ejector
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('456', 'ProVore 1/2 HP Sewage Grinder', 'ProVore', 2520, 10, false, 650, ARRAY['V-Slice cutter technology','2-inch solids handling','Cast iron construction','Quick-disconnect cord'], '{"hp": 0.5, "gph_at_10ft": 2520, "head_ft": 25, "switch_type": "float", "discharge": "2_inch", "solids_handling": "2_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.libertypumps.com/product/456'),
  ('LE41A', 'Omnivore 2/5 HP Sewage Ejector', 'Omnivore', 3600, 10, false, 500, ARRAY['2-inch solids handling','Automatic operation','Cast iron housing','Engineered plastic impeller'], '{"hp": 0.4, "gph_at_10ft": 3600, "head_ft": 22, "switch_type": "float", "discharge": "2_inch", "solids_handling": "2_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.libertypumps.com/product/le41a'),
  ('LE51A', 'Omnivore 1/2 HP Sewage Ejector', 'Omnivore', 4680, 10, false, 550, ARRAY['2-inch solids handling','Automatic operation','Cast iron housing','High-capacity'], '{"hp": 0.5, "gph_at_10ft": 4680, "head_ft": 25, "switch_type": "float", "discharge": "2_inch", "solids_handling": "2_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.libertypumps.com/product/le51a'),
  ('LE71A', 'Omnivore 3/4 HP Sewage Ejector', 'Omnivore', 5700, 12, false, 680, ARRAY['2-inch solids handling','Automatic operation','Cast iron housing','Heavy-duty motor'], '{"hp": 0.75, "gph_at_10ft": 5700, "head_ft": 32, "switch_type": "float", "discharge": "2_inch", "solids_handling": "2_inch", "cord_ft": 15, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.libertypumps.com/product/le71a')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'liberty-pumps' AND c.slug = 'sump-pump-sewage-ejector';


-- ======================== WAYNE (Mainstream) ========================

-- Wayne Submersible
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('CDU790', '1/3 HP Submersible Sump Pump', 'CDU', 2700, 8, false, 130, ARRAY['Glass-reinforced thermoplastic','Suction screen bottom','Top discharge','Float switch'], '{"hp": 0.33, "gph_at_10ft": 2700, "head_ft": 20, "switch_type": "vertical_float", "discharge": "1.5_inch", "cord_ft": 8, "material": "thermoplastic", "phase": "single", "voltage": 120}', 'https://www.waynepumps.com/product/cdu790'),
  ('CDU800', '1/2 HP Submersible Sump Pump', 'CDU', 3600, 8, false, 150, ARRAY['Glass-reinforced thermoplastic','Suction screen bottom','Top discharge','Float switch'], '{"hp": 0.5, "gph_at_10ft": 3600, "head_ft": 22, "switch_type": "vertical_float", "discharge": "1.5_inch", "cord_ft": 8, "material": "thermoplastic", "phase": "single", "voltage": 120}', 'https://www.waynepumps.com/product/cdu800'),
  ('CDU980E', '3/4 HP Submersible Sump Pump', 'CDU', 4600, 10, false, 200, ARRAY['Cast iron and steel construction','Suction strainer','Top discharge','Vertical float switch'], '{"hp": 0.75, "gph_at_10ft": 4600, "head_ft": 30, "switch_type": "vertical_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 120}', 'https://www.waynepumps.com/product/cdu980e'),
  ('CDU1000', '1 HP Submersible Sump Pump', 'CDU', 5100, 10, false, 260, ARRAY['Cast iron and steel construction','High-capacity motor','Top discharge','Vertical float switch'], '{"hp": 1.0, "gph_at_10ft": 5100, "head_ft": 34, "switch_type": "vertical_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 120}', 'https://www.waynepumps.com/product/cdu1000'),
  ('CDUCAP995', '3/4 HP iSwitch Submersible', 'iSwitch', 4600, 10, false, 230, ARRAY['Cap-style switch','No float to jam','Cast iron motor housing','Corrosion-resistant'], '{"hp": 0.75, "gph_at_10ft": 4600, "head_ft": 30, "switch_type": "cap_diaphragm", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 120}', 'https://www.waynepumps.com/product/cducap995'),
  ('WSS30VN', '1/2 HP Submersible Sump Pump', 'WSS', 3600, 8, false, 140, ARRAY['Thermoplastic construction','Vertical float switch','Suction screen','Compact design'], '{"hp": 0.5, "gph_at_10ft": 3600, "head_ft": 21, "switch_type": "vertical_float", "discharge": "1.5_inch", "cord_ft": 8, "material": "thermoplastic", "phase": "single", "voltage": 120}', 'https://www.waynepumps.com/product/wss30vn'),
  ('WaterBUG', 'WaterBUG 1/6 HP Multi-Use Pump', 'WaterBUG', 1350, 5, false, 100, ARRAY['Multi-use pump','Removes water to 1/16 inch','Auto or manual operation','Compact'], '{"hp": 0.167, "gph_at_10ft": 1350, "head_ft": 15, "switch_type": "auto_manual", "discharge": "0.75_inch", "cord_ft": 8, "material": "thermoplastic", "phase": "single", "voltage": 120}', 'https://www.waynepumps.com/product/waterbug')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'wayne' AND c.slug = 'sump-pump-submersible';

-- Wayne Battery Backup
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WSM3300', '1/3 HP Battery Backup', 'Battery Backup', 2200, 5, false, 350, ARRAY['12V DC battery backup','Audible alarm','LED status panel','Top discharge'], '{"hp": 0.33, "gph_at_10ft": 2200, "head_ft": 15, "switch_type": "float", "discharge": "1.5_inch", "cord_ft": 10, "material": "thermoplastic", "battery_type": "12v_dc", "voltage": 12}', 'https://www.waynepumps.com/product/wsm3300'),
  ('ESP25', 'Upgraded 12V Battery Backup', 'ESP', 2900, 5, false, 400, ARRAY['Pre-assembled system','Audible and visual alarms','Smart charger','12V battery backup'], '{"hp": 0.33, "gph_at_10ft": 2900, "head_ft": 18, "switch_type": "float", "discharge": "1.5_inch", "cord_ft": 10, "material": "thermoplastic", "battery_type": "12v_dc", "voltage": 12}', 'https://www.waynepumps.com/product/esp25')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'wayne' AND c.slug = 'sump-pump-battery-backup';

-- Wayne Combination
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WSS30VN-ESP25', '1/2 HP Combo w/ Battery Backup', 'Combo', 3600, 8, false, 500, ARRAY['1/2 HP primary pump','12V battery backup','Audible alarm','Complete system'], '{"hp_primary": 0.5, "gph_at_10ft": 3600, "head_ft": 21, "switch_type": "vertical_float", "discharge": "1.5_inch", "cord_ft": 8, "material": "thermoplastic", "battery": "12v_dc", "voltage": 120}', 'https://www.waynepumps.com/product/combo-wss30vn')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'wayne' AND c.slug = 'sump-pump-combination';

-- Wayne Sewage Ejector
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('RPP50', '1/2 HP Cast Iron Sewage Pump', 'RPP', 4500, 10, false, 280, ARRAY['Cast iron construction','2-inch solids handling','Automatic float switch','Non-clogging impeller'], '{"hp": 0.5, "gph_at_10ft": 4500, "head_ft": 24, "switch_type": "float", "discharge": "2_inch", "solids_handling": "2_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 120}', 'https://www.waynepumps.com/product/rpp50'),
  ('SEL50', '1/2 HP Sewage Ejector System', 'SEL', 4200, 10, false, 350, ARRAY['Complete ejector system','24x24 basin included','Cast iron pump','Check valve included'], '{"hp": 0.5, "gph_at_10ft": 4200, "head_ft": 22, "switch_type": "float", "discharge": "2_inch", "solids_handling": "2_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 120}', 'https://www.waynepumps.com/product/sel50')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'wayne' AND c.slug = 'sump-pump-sewage-ejector';

-- Wayne Pedestal
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'pedestal', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('SPT33', '1/3 HP Pedestal Sump Pump', 'SPT', 3000, 12, false, 120, ARRAY['Motor above pit','Easy maintenance access','Vertical float switch','Cast iron base'], '{"hp": 0.33, "gph_at_10ft": 3000, "head_ft": 22, "switch_type": "vertical_float", "discharge": "1.5_inch", "cord_ft": 8, "material": "cast_iron_base", "phase": "single", "voltage": 120}', 'https://www.waynepumps.com/product/spt33')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'wayne' AND c.slug = 'sump-pump-pedestal';


-- ======================== LITTLE GIANT (Mainstream) ========================

-- Little Giant Submersible
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('506158', '6-CIA 1/3 HP Submersible', '6-CIA', 2880, 8, false, 180, ARRAY['Die-cast aluminum housing','Permanent split capacitor motor','Automatic float switch','Integral check valve'], '{"hp": 0.33, "gph_at_10ft": 2880, "head_ft": 22, "switch_type": "float", "discharge": "1.5_inch", "cord_ft": 10, "material": "aluminum", "phase": "single", "voltage": 115}', 'https://www.lg-outdoor.com/product/6-cia'),
  ('506160', '6-CIM(R) 1/3 HP Submersible', '6-CIM', 2880, 8, false, 170, ARRAY['Die-cast aluminum housing','Manual operation','Oil-filled motor','Compact design'], '{"hp": 0.33, "gph_at_10ft": 2880, "head_ft": 22, "switch_type": "manual", "discharge": "1.5_inch", "cord_ft": 10, "material": "aluminum", "phase": "single", "voltage": 115}', 'https://www.lg-outdoor.com/product/6-cim'),
  ('508158', '8-CIA 1/2 HP Submersible', '8-CIA', 3600, 10, false, 210, ARRAY['Die-cast aluminum housing','Auto float switch','Oil-filled motor','High capacity'], '{"hp": 0.5, "gph_at_10ft": 3600, "head_ft": 25, "switch_type": "float", "discharge": "1.5_inch", "cord_ft": 10, "material": "aluminum", "phase": "single", "voltage": 115}', 'https://www.lg-outdoor.com/product/8-cia'),
  ('510274', '10S-CIA-SFS 1/2 HP Cast Iron Sub.', '10S-CIA', 3960, 10, false, 250, ARRAY['Cast iron construction','Snap-action float switch','Oil-filled motor','Stainless steel fasteners'], '{"hp": 0.5, "gph_at_10ft": 3960, "head_ft": 28, "switch_type": "snap_action_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.lg-outdoor.com/product/10s-cia-sfs'),
  ('506271', '6-CIA-RFS 1/3 HP Submersible', '6-CIA-RFS', 2880, 10, false, 200, ARRAY['Cast iron construction','Piggyback float switch','Oil-filled motor','Removable suction screen'], '{"hp": 0.33, "gph_at_10ft": 2880, "head_ft": 22, "switch_type": "piggyback_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.lg-outdoor.com/product/6-cia-rfs'),
  ('14940754', '1 HP High-Flow Submersible', 'High Flow', 6000, 10, false, 350, ARRAY['Cast iron construction','High-flow impeller','Automatic float switch','Heavy-duty motor'], '{"hp": 1.0, "gph_at_10ft": 6000, "head_ft": 36, "switch_type": "float", "discharge": "1.5_inch", "cord_ft": 15, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.lg-outdoor.com/product/high-flow-1hp')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'little-giant' AND c.slug = 'sump-pump-submersible';

-- Little Giant Pedestal
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'pedestal', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('506325', 'SPDK-S 1/3 HP Pedestal', 'SPDK', 2580, 12, false, 140, ARRAY['Motor above pit for longevity','Adjustable float switch','Corrosion-resistant housing','Easy maintenance'], '{"hp": 0.33, "gph_at_10ft": 2580, "head_ft": 20, "switch_type": "adjustable_float", "discharge": "1.25_inch", "cord_ft": 8, "material": "zinc_plated_steel", "phase": "single", "voltage": 115}', 'https://www.lg-outdoor.com/product/spdk-s'),
  ('506600', 'SPDK 1/3 HP Pedestal Sump Pump', 'SPDK', 2700, 12, false, 150, ARRAY['Durable steel column','Vertical float switch','Motor above water line','Ball bearing motor'], '{"hp": 0.33, "gph_at_10ft": 2700, "head_ft": 22, "switch_type": "vertical_float", "discharge": "1.25_inch", "cord_ft": 8, "material": "steel", "phase": "single", "voltage": 115}', 'https://www.lg-outdoor.com/product/spdk')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'little-giant' AND c.slug = 'sump-pump-pedestal';

-- Little Giant Sewage Ejector
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('506610', '9S-CIA-SFS 1/2 HP Sewage Ejector', '9S-CIA', 3600, 10, false, 330, ARRAY['Cast iron construction','2-inch solids handling','Automatic float switch','Non-clogging impeller'], '{"hp": 0.5, "gph_at_10ft": 3600, "head_ft": 24, "switch_type": "snap_action_float", "discharge": "2_inch", "solids_handling": "2_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.lg-outdoor.com/product/9s-cia-sfs'),
  ('506700', '10S-CIA 1/2 HP Sewage Pump', '10S-CIA', 3960, 10, false, 350, ARRAY['Cast iron construction','2-inch solids handling','Oil-filled motor','Stainless fasteners'], '{"hp": 0.5, "gph_at_10ft": 3960, "head_ft": 28, "switch_type": "float", "discharge": "2_inch", "solids_handling": "2_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.lg-outdoor.com/product/10s-cia-sewage'),
  ('514320', '14S-CIM 1 HP Sewage Ejector', '14S-CIM', 5400, 12, false, 480, ARRAY['Cast iron construction','2-inch solids handling','Heavy-duty 1 HP motor','Manual operation'], '{"hp": 1.0, "gph_at_10ft": 5400, "head_ft": 35, "switch_type": "manual", "discharge": "2_inch", "solids_handling": "2_inch", "cord_ft": 15, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.lg-outdoor.com/product/14s-cim')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'little-giant' AND c.slug = 'sump-pump-sewage-ejector';


-- ======================== EVERBILT (Budget) ========================

-- Everbilt Submersible
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('SP03302VD', '1/3 HP Submersible Sump Pump', NULL, 3040, 7, false, 100, ARRAY['Thermoplastic construction','Vertical float switch','Top suction design','Corrosion-resistant'], '{"hp": 0.33, "gph_at_10ft": 3040, "head_ft": 19, "switch_type": "vertical_float", "discharge": "1.5_inch", "cord_ft": 8, "material": "thermoplastic", "phase": "single", "voltage": 120}', 'https://www.homedepot.com/p/Everbilt-1-3-HP-Submersible-Sump-Pump/SP03302VD'),
  ('SP05002VD', '1/2 HP Submersible Sump Pump', NULL, 3600, 7, false, 130, ARRAY['Thermoplastic construction','Vertical float switch','Top suction','High capacity'], '{"hp": 0.5, "gph_at_10ft": 3600, "head_ft": 22, "switch_type": "vertical_float", "discharge": "1.5_inch", "cord_ft": 8, "material": "thermoplastic", "phase": "single", "voltage": 120}', 'https://www.homedepot.com/p/Everbilt-1-2-HP-Submersible-Sump-Pump/SP05002VD'),
  ('SP03303VD', '1/3 HP Submersible w/ Tether Float', NULL, 2880, 7, false, 110, ARRAY['Thermoplastic construction','Tethered float switch','Side suction screen','Corrosion-resistant'], '{"hp": 0.33, "gph_at_10ft": 2880, "head_ft": 19, "switch_type": "tether_float", "discharge": "1.5_inch", "cord_ft": 8, "material": "thermoplastic", "phase": "single", "voltage": 120}', 'https://www.homedepot.com/p/Everbilt-1-3-HP-Tether-Submersible/SP03303VD'),
  ('SP05502VD', '1/2 HP Cast Iron Submersible', NULL, 3600, 8, false, 170, ARRAY['Cast iron construction','Vertical float switch','Top discharge','Thermal overload protection'], '{"hp": 0.5, "gph_at_10ft": 3600, "head_ft": 24, "switch_type": "vertical_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 120}', 'https://www.homedepot.com/p/Everbilt-1-2-HP-Cast-Iron-Submersible/SP05502VD'),
  ('SP07502VD', '3/4 HP Submersible Sump Pump', NULL, 4600, 8, false, 180, ARRAY['Thermoplastic construction','Vertical float switch','High capacity motor','Top discharge'], '{"hp": 0.75, "gph_at_10ft": 4600, "head_ft": 28, "switch_type": "vertical_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "thermoplastic", "phase": "single", "voltage": 120}', 'https://www.homedepot.com/p/Everbilt-3-4-HP-Submersible/SP07502VD'),
  ('SP02502VD', '1/4 HP Submersible Sump Pump', NULL, 2160, 7, false, 85, ARRAY['Compact thermoplastic design','Vertical float switch','Corrosion-resistant','Budget-friendly'], '{"hp": 0.25, "gph_at_10ft": 2160, "head_ft": 15, "switch_type": "vertical_float", "discharge": "1.5_inch", "cord_ft": 8, "material": "thermoplastic", "phase": "single", "voltage": 120}', 'https://www.homedepot.com/p/Everbilt-1-4-HP-Submersible/SP02502VD')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'everbilt' AND c.slug = 'sump-pump-submersible';

-- Everbilt Pedestal
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'pedestal', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('SP03302PD', '1/3 HP Pedestal Sump Pump', NULL, 3000, 10, false, 90, ARRAY['Motor above water level','Adjustable float switch','Easy serviceability','Budget-friendly'], '{"hp": 0.33, "gph_at_10ft": 3000, "head_ft": 20, "switch_type": "adjustable_float", "discharge": "1.25_inch", "cord_ft": 8, "material": "steel", "phase": "single", "voltage": 120}', 'https://www.homedepot.com/p/Everbilt-1-3-HP-Pedestal/SP03302PD'),
  ('SP05002PD', '1/2 HP Pedestal Sump Pump', NULL, 3600, 10, false, 110, ARRAY['Motor above water level','Adjustable float','Easy maintenance','Higher capacity'], '{"hp": 0.5, "gph_at_10ft": 3600, "head_ft": 24, "switch_type": "adjustable_float", "discharge": "1.25_inch", "cord_ft": 8, "material": "steel", "phase": "single", "voltage": 120}', 'https://www.homedepot.com/p/Everbilt-1-2-HP-Pedestal/SP05002PD')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'everbilt' AND c.slug = 'sump-pump-pedestal';

-- Everbilt Battery Backup
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('EBBU20', 'Battery Backup Sump Pump', NULL, 1500, 5, false, 250, ARRAY['12V battery backup','Audible alarm','LED status indicators','Easy installation'], '{"hp": 0.25, "gph_at_10ft": 1500, "head_ft": 12, "switch_type": "float", "discharge": "1.5_inch", "cord_ft": 8, "material": "thermoplastic", "battery_type": "12v_dc", "voltage": 12}', 'https://www.homedepot.com/p/Everbilt-Battery-Backup/EBBU20')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'everbilt' AND c.slug = 'sump-pump-battery-backup';

-- Everbilt Sewage Ejector
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('ESE50W-HD', '1/2 HP Sewage Ejector Pump', NULL, 3600, 7, false, 200, ARRAY['Thermoplastic construction','2-inch solids handling','Float switch','Top discharge'], '{"hp": 0.5, "gph_at_10ft": 3600, "head_ft": 20, "switch_type": "float", "discharge": "2_inch", "solids_handling": "2_inch", "cord_ft": 10, "material": "thermoplastic", "phase": "single", "voltage": 120}', 'https://www.homedepot.com/p/Everbilt-1-2-HP-Sewage-Ejector/ESE50W-HD'),
  ('ESE40W-HD', '2/5 HP Sewage Ejector Pump', NULL, 3000, 7, false, 170, ARRAY['Thermoplastic construction','2-inch solids handling','Float switch','Budget-friendly'], '{"hp": 0.4, "gph_at_10ft": 3000, "head_ft": 18, "switch_type": "float", "discharge": "2_inch", "solids_handling": "2_inch", "cord_ft": 10, "material": "thermoplastic", "phase": "single", "voltage": 120}', 'https://www.homedepot.com/p/Everbilt-2-5-HP-Sewage-Ejector/ESE40W-HD')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'everbilt' AND c.slug = 'sump-pump-sewage-ejector';


-- ======================== SUPERIOR PUMP (Budget) ========================

-- Superior Pump Submersible
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('91250', '1/4 HP Thermoplastic Submersible', NULL, 1800, 7, false, 70, ARRAY['Thermoplastic construction','Tethered float switch','Split capacitor motor','Top suction screen'], '{"hp": 0.25, "gph_at_10ft": 1800, "head_ft": 18, "switch_type": "tether_float", "discharge": "1.25_inch", "cord_ft": 8, "material": "thermoplastic", "phase": "single", "voltage": 120}', 'https://www.superiorpump.com/product/91250'),
  ('91330', '1/3 HP Thermoplastic Submersible', NULL, 2400, 7, false, 85, ARRAY['Thermoplastic construction','Tethered float switch','Split capacitor motor','Side suction screen'], '{"hp": 0.33, "gph_at_10ft": 2400, "head_ft": 22, "switch_type": "tether_float", "discharge": "1.5_inch", "cord_ft": 8, "material": "thermoplastic", "phase": "single", "voltage": 120}', 'https://www.superiorpump.com/product/91330'),
  ('91331', '1/3 HP Thermoplastic Submersible Vertical', NULL, 2400, 7, false, 90, ARRAY['Thermoplastic construction','Vertical float switch','Fits narrow pits','Side suction screen'], '{"hp": 0.33, "gph_at_10ft": 2400, "head_ft": 22, "switch_type": "vertical_float", "discharge": "1.5_inch", "cord_ft": 8, "material": "thermoplastic", "phase": "single", "voltage": 120}', 'https://www.superiorpump.com/product/91331'),
  ('91501', '1/2 HP Thermoplastic Submersible', NULL, 3000, 7, false, 105, ARRAY['Thermoplastic construction','Tethered float switch','High-capacity motor','Corrosion-resistant'], '{"hp": 0.5, "gph_at_10ft": 3000, "head_ft": 25, "switch_type": "tether_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "thermoplastic", "phase": "single", "voltage": 120}', 'https://www.superiorpump.com/product/91501'),
  ('92341', '1/3 HP Cast Iron Submersible', NULL, 2760, 8, false, 145, ARRAY['Cast iron construction','Tethered float switch','Oil-filled motor','Stainless steel hardware'], '{"hp": 0.33, "gph_at_10ft": 2760, "head_ft": 24, "switch_type": "tether_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 120}', 'https://www.superiorpump.com/product/92341'),
  ('92501', '1/2 HP Cast Iron Submersible', NULL, 3600, 8, false, 170, ARRAY['Cast iron construction','Tethered float switch','Oil-filled motor','Heavy-duty design'], '{"hp": 0.5, "gph_at_10ft": 3600, "head_ft": 28, "switch_type": "tether_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 120}', 'https://www.superiorpump.com/product/92501'),
  ('92751', '3/4 HP Cast Iron Submersible', NULL, 4500, 10, false, 210, ARRAY['Cast iron construction','Tethered float switch','High-capacity motor','Oil-filled motor'], '{"hp": 0.75, "gph_at_10ft": 4500, "head_ft": 32, "switch_type": "tether_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 120}', 'https://www.superiorpump.com/product/92751')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'superior-pump' AND c.slug = 'sump-pump-submersible';

-- Superior Pump Pedestal
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'pedestal', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('92333', '1/3 HP Pedestal Sump Pump', NULL, 2760, 10, false, 100, ARRAY['Motor above water level','Steel column','Adjustable float switch','Easy access for maintenance'], '{"hp": 0.33, "gph_at_10ft": 2760, "head_ft": 22, "switch_type": "adjustable_float", "discharge": "1.25_inch", "cord_ft": 8, "material": "steel", "phase": "single", "voltage": 120}', 'https://www.superiorpump.com/product/92333'),
  ('92553', '1/2 HP Pedestal Sump Pump', NULL, 3600, 10, false, 125, ARRAY['Motor above water level','Steel column','Adjustable float switch','High-capacity'], '{"hp": 0.5, "gph_at_10ft": 3600, "head_ft": 26, "switch_type": "adjustable_float", "discharge": "1.25_inch", "cord_ft": 8, "material": "steel", "phase": "single", "voltage": 120}', 'https://www.superiorpump.com/product/92553')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'superior-pump' AND c.slug = 'sump-pump-pedestal';

-- Superior Pump Sewage Ejector
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('93501', '1/2 HP Sewage Ejector Pump', NULL, 3600, 8, false, 170, ARRAY['Thermoplastic construction','2-inch solids handling','Tethered float switch','Top discharge'], '{"hp": 0.5, "gph_at_10ft": 3600, "head_ft": 22, "switch_type": "tether_float", "discharge": "2_inch", "solids_handling": "2_inch", "cord_ft": 10, "material": "thermoplastic", "phase": "single", "voltage": 120}', 'https://www.superiorpump.com/product/93501'),
  ('93020', '1/2 HP Cast Iron Sewage Pump', NULL, 4200, 10, false, 230, ARRAY['Cast iron construction','2-inch solids handling','Tethered float switch','Heavy-duty motor'], '{"hp": 0.5, "gph_at_10ft": 4200, "head_ft": 25, "switch_type": "tether_float", "discharge": "2_inch", "solids_handling": "2_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 120}', 'https://www.superiorpump.com/product/93020')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'superior-pump' AND c.slug = 'sump-pump-sewage-ejector';


-- ======================== FLOTEC (Budget) ========================

-- Flotec Submersible
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('FPZS33T', '1/3 HP Submersible Sump Pump', NULL, 3000, 7, false, 95, ARRAY['Thermoplastic construction','Tethered float switch','Corrosion-resistant','Side suction'], '{"hp": 0.33, "gph_at_10ft": 3000, "head_ft": 19, "switch_type": "tether_float", "discharge": "1.5_inch", "cord_ft": 8, "material": "thermoplastic", "phase": "single", "voltage": 115}', 'https://www.flotecwater.com/product/fpzs33t'),
  ('FPZS33V', '1/3 HP Submersible Vertical Float', NULL, 3000, 7, false, 100, ARRAY['Thermoplastic construction','Vertical float switch','Narrow pit compatible','Side suction'], '{"hp": 0.33, "gph_at_10ft": 3000, "head_ft": 19, "switch_type": "vertical_float", "discharge": "1.5_inch", "cord_ft": 8, "material": "thermoplastic", "phase": "single", "voltage": 115}', 'https://www.flotecwater.com/product/fpzs33v'),
  ('FPZS50T', '1/2 HP Submersible Sump Pump', NULL, 3600, 7, false, 120, ARRAY['Thermoplastic construction','Tethered float switch','High-capacity','Top discharge'], '{"hp": 0.5, "gph_at_10ft": 3600, "head_ft": 22, "switch_type": "tether_float", "discharge": "1.5_inch", "cord_ft": 8, "material": "thermoplastic", "phase": "single", "voltage": 115}', 'https://www.flotecwater.com/product/fpzs50t'),
  ('FPCI3350', '1/3 HP Cast Iron Submersible', NULL, 2700, 8, false, 140, ARRAY['Cast iron construction','Tethered float switch','Oil-filled motor','Heavy-duty design'], '{"hp": 0.33, "gph_at_10ft": 2700, "head_ft": 22, "switch_type": "tether_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.flotecwater.com/product/fpci3350'),
  ('FPCI5050', '1/2 HP Cast Iron Submersible', NULL, 3600, 8, false, 165, ARRAY['Cast iron construction','Tethered float switch','Oil-filled motor','Stainless hardware'], '{"hp": 0.5, "gph_at_10ft": 3600, "head_ft": 28, "switch_type": "tether_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.flotecwater.com/product/fpci5050'),
  ('FPZS75T', '3/4 HP Submersible Sump Pump', NULL, 4500, 8, false, 155, ARRAY['Thermoplastic construction','Tethered float switch','High-capacity motor','Corrosion-resistant'], '{"hp": 0.75, "gph_at_10ft": 4500, "head_ft": 30, "switch_type": "tether_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "thermoplastic", "phase": "single", "voltage": 115}', 'https://www.flotecwater.com/product/fpzs75t')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'flotec' AND c.slug = 'sump-pump-submersible';

-- Flotec Pedestal
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'pedestal', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('FPPSS3400A', '1/3 HP Pedestal Sump Pump', NULL, 3000, 10, false, 85, ARRAY['Motor above water level','Adjustable float switch','Steel column','Budget-friendly'], '{"hp": 0.33, "gph_at_10ft": 3000, "head_ft": 20, "switch_type": "adjustable_float", "discharge": "1.25_inch", "cord_ft": 8, "material": "steel", "phase": "single", "voltage": 115}', 'https://www.flotecwater.com/product/fppss3400a')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'flotec' AND c.slug = 'sump-pump-pedestal';

-- Flotec Sewage Ejector
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('FPSE3601A', '1/2 HP Sewage Ejector Pump', NULL, 3600, 7, false, 175, ARRAY['Thermoplastic construction','2-inch solids handling','Tethered float switch','Non-clogging impeller'], '{"hp": 0.5, "gph_at_10ft": 3600, "head_ft": 18, "switch_type": "tether_float", "discharge": "2_inch", "solids_handling": "2_inch", "cord_ft": 10, "material": "thermoplastic", "phase": "single", "voltage": 115}', 'https://www.flotecwater.com/product/fpse3601a'),
  ('FPSE3200A', '1/2 HP Cast Iron Sewage Pump', NULL, 4200, 8, false, 225, ARRAY['Cast iron construction','2-inch solids handling','Tethered float switch','Oil-filled motor'], '{"hp": 0.5, "gph_at_10ft": 4200, "head_ft": 22, "switch_type": "tether_float", "discharge": "2_inch", "solids_handling": "2_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.flotecwater.com/product/fpse3200a')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'flotec' AND c.slug = 'sump-pump-sewage-ejector';


-- ======================== BASEMENT WATCHDOG (Smart/Backup) ========================

-- Basement Watchdog Submersible (primary pumps)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('BW1033', '1/3 HP Submersible Sump Pump', 'Primary', 2200, 8, false, 130, ARRAY['Cast iron and thermoplastic construction','Automatic float switch','Top suction','Corrosion-resistant'], '{"hp": 0.33, "gph_at_10ft": 2200, "head_ft": 18, "switch_type": "float", "discharge": "1.5_inch", "cord_ft": 8, "material": "cast_iron_thermoplastic", "phase": "single", "voltage": 120}', 'https://www.basementwatchdog.com/product/bw1033'),
  ('BW1050', '1/2 HP Submersible Sump Pump', 'Primary', 3600, 8, false, 165, ARRAY['Cast iron and thermoplastic construction','Automatic float switch','High capacity','Top discharge'], '{"hp": 0.5, "gph_at_10ft": 3600, "head_ft": 22, "switch_type": "float", "discharge": "1.5_inch", "cord_ft": 8, "material": "cast_iron_thermoplastic", "phase": "single", "voltage": 120}', 'https://www.basementwatchdog.com/product/bw1050')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'basement-watchdog' AND c.slug = 'sump-pump-submersible';

-- Basement Watchdog Battery Backup
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('BWE', 'Emergency Battery Backup', 'Emergency', 1000, 5, false, 200, ARRAY['Battery-powered backup','Audible alarm','Auto activation on power loss','Dual float switch'], '{"hp": 0, "gph_at_10ft": 1000, "head_ft": 10, "switch_type": "dual_float", "discharge": "1.5_inch", "cord_ft": 8, "material": "thermoplastic", "battery_type": "12v_dc", "voltage": 12}', 'https://www.basementwatchdog.com/product/bwe'),
  ('BWSP', 'Special Battery Backup', 'Special', 2000, 5, false, 300, ARRAY['Battery-powered backup','Audible alarm','High-output pump','Dual float switch'], '{"hp": 0.25, "gph_at_10ft": 2000, "head_ft": 12, "switch_type": "dual_float", "discharge": "1.5_inch", "cord_ft": 8, "material": "thermoplastic", "battery_type": "12v_dc", "voltage": 12}', 'https://www.basementwatchdog.com/product/bwsp'),
  ('BW4000', 'Big Dog Battery Backup', 'Big Dog', 3500, 5, false, 400, ARRAY['High-output battery backup','Audible and visual alarm','Dual float switch','Longest run time in class'], '{"hp": 0.33, "gph_at_10ft": 3500, "head_ft": 18, "switch_type": "dual_float", "discharge": "1.5_inch", "cord_ft": 8, "material": "thermoplastic", "battery_type": "12v_dc", "voltage": 12}', 'https://www.basementwatchdog.com/product/bw4000'),
  ('DFK961', 'Battery Backup Sump Pump', 'Standard', 1500, 5, false, 250, ARRAY['12V DC battery backup','Audible alarm','Automatic activation','Easy installation kit'], '{"hp": 0.2, "gph_at_10ft": 1500, "head_ft": 10, "switch_type": "float", "discharge": "1.5_inch", "cord_ft": 8, "material": "thermoplastic", "battery_type": "12v_dc", "voltage": 12}', 'https://www.basementwatchdog.com/product/dfk961'),
  ('CITE-33', 'CITE 1/3 HP Battery Backup', 'CITE', 2200, 5, true, 350, ARRAY['WiFi-enabled monitoring','Smartphone alerts','Battery backup','Self-testing'], '{"hp": 0.33, "gph_at_10ft": 2200, "head_ft": 15, "switch_type": "dual_float", "discharge": "1.5_inch", "cord_ft": 8, "material": "thermoplastic", "battery_type": "12v_dc", "voltage": 12, "wifi": true}', 'https://www.basementwatchdog.com/product/cite-33')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'basement-watchdog' AND c.slug = 'sump-pump-battery-backup';

-- Basement Watchdog Combination
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('CITS-50', '1/2 HP Combo w/ WiFi Monitoring', 'CITE', 3600, 8, true, 550, ARRAY['1/2 HP primary pump','Battery backup included','WiFi monitoring','Smartphone alerts'], '{"hp_primary": 0.5, "gph_at_10ft": 3600, "head_ft": 22, "switch_type": "float", "discharge": "1.5_inch", "cord_ft": 8, "material": "cast_iron_thermoplastic", "battery": "12v_dc", "voltage": 120, "wifi": true}', 'https://www.basementwatchdog.com/product/cits-50'),
  ('CONNECT-33', '1/3 HP Combo w/ WiFi Monitoring', 'Connect', 2200, 8, true, 480, ARRAY['1/3 HP primary pump','Battery backup included','WiFi monitoring','Self-testing and alerts'], '{"hp_primary": 0.33, "gph_at_10ft": 2200, "head_ft": 18, "switch_type": "float", "discharge": "1.5_inch", "cord_ft": 8, "material": "thermoplastic", "battery": "12v_dc", "voltage": 120, "wifi": true}', 'https://www.basementwatchdog.com/product/connect-33'),
  ('BW1050C', '1/2 HP Combo Standard', 'Combo', 3600, 8, false, 420, ARRAY['1/2 HP primary pump','Battery backup included','Audible alarm','Dual float switches'], '{"hp_primary": 0.5, "gph_at_10ft": 3600, "head_ft": 22, "switch_type": "dual_float", "discharge": "1.5_inch", "cord_ft": 8, "material": "cast_iron_thermoplastic", "battery": "12v_dc", "voltage": 120}', 'https://www.basementwatchdog.com/product/bw1050c')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'basement-watchdog' AND c.slug = 'sump-pump-combination';


-- ======================== PUMPSPY (Smart/Backup) ========================

-- PumpSpy Submersible (Smart primary pumps)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('PS1033', '1/3 HP WiFi Submersible', 'Smart', 2400, 10, true, 250, ARRAY['WiFi-enabled monitoring','Smartphone alerts','Cast iron construction','Automatic float switch'], '{"hp": 0.33, "gph_at_10ft": 2400, "head_ft": 19, "switch_type": "float", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115, "wifi": true}', 'https://www.pumpspy.com/product/ps1033'),
  ('PS1050', '1/2 HP WiFi Submersible', 'Smart', 3600, 10, true, 300, ARRAY['WiFi-enabled monitoring','Smartphone alerts','Cast iron construction','High capacity'], '{"hp": 0.5, "gph_at_10ft": 3600, "head_ft": 24, "switch_type": "float", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115, "wifi": true}', 'https://www.pumpspy.com/product/ps1050'),
  ('PS1075', '3/4 HP WiFi Submersible', 'Smart', 4800, 12, true, 380, ARRAY['WiFi-enabled monitoring','Smartphone alerts','Cast iron construction','Heavy-duty motor'], '{"hp": 0.75, "gph_at_10ft": 4800, "head_ft": 30, "switch_type": "float", "discharge": "1.5_inch", "cord_ft": 15, "material": "cast_iron", "phase": "single", "voltage": 115, "wifi": true}', 'https://www.pumpspy.com/product/ps1075'),
  ('PS2033', '1/3 HP WiFi Submersible w/ Controller', 'Smart Pro', 2400, 10, true, 350, ARRAY['WiFi controller included','Real-time water level monitoring','Run-time tracking','Push notifications'], '{"hp": 0.33, "gph_at_10ft": 2400, "head_ft": 19, "switch_type": "electronic", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115, "wifi": true}', 'https://www.pumpspy.com/product/ps2033'),
  ('PS2050', '1/2 HP WiFi Submersible w/ Controller', 'Smart Pro', 3600, 10, true, 400, ARRAY['WiFi controller included','Real-time water level monitoring','Run-time tracking','Push notifications'], '{"hp": 0.5, "gph_at_10ft": 3600, "head_ft": 24, "switch_type": "electronic", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115, "wifi": true}', 'https://www.pumpspy.com/product/ps2050')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'pumpspy' AND c.slug = 'sump-pump-submersible';

-- PumpSpy Battery Backup
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('PSB1020', 'WiFi Battery Backup', 'Smart Backup', 2000, 5, true, 350, ARRAY['WiFi-enabled monitoring','Battery-powered backup','Smartphone push alerts','Battery health monitoring'], '{"hp": 0.25, "gph_at_10ft": 2000, "head_ft": 12, "switch_type": "float", "discharge": "1.5_inch", "cord_ft": 8, "material": "thermoplastic", "battery_type": "12v_dc", "voltage": 12, "wifi": true}', 'https://www.pumpspy.com/product/psb1020'),
  ('PSB2030', 'WiFi Battery Backup High Output', 'Smart Backup Pro', 3000, 5, true, 450, ARRAY['WiFi-enabled monitoring','High-output battery pump','Real-time alerts','Battery health tracking'], '{"hp": 0.33, "gph_at_10ft": 3000, "head_ft": 16, "switch_type": "electronic", "discharge": "1.5_inch", "cord_ft": 8, "material": "thermoplastic", "battery_type": "12v_dc", "voltage": 12, "wifi": true}', 'https://www.pumpspy.com/product/psb2030')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'pumpspy' AND c.slug = 'sump-pump-battery-backup';

-- PumpSpy Combination
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('PSC1050', '1/2 HP WiFi Combo System', 'Smart Combo', 3600, 10, true, 600, ARRAY['WiFi-enabled monitoring','1/2 HP primary pump','Battery backup included','Real-time alerts and diagnostics'], '{"hp_primary": 0.5, "gph_at_10ft": 3600, "head_ft": 24, "switch_type": "electronic", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "battery": "12v_dc", "voltage": 115, "wifi": true}', 'https://www.pumpspy.com/product/psc1050'),
  ('PSC1033', '1/3 HP WiFi Combo System', 'Smart Combo', 2400, 10, true, 500, ARRAY['WiFi-enabled monitoring','1/3 HP primary pump','Battery backup included','Push notifications'], '{"hp_primary": 0.33, "gph_at_10ft": 2400, "head_ft": 19, "switch_type": "electronic", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "battery": "12v_dc", "voltage": 115, "wifi": true}', 'https://www.pumpspy.com/product/psc1033'),
  ('PSC2075', '3/4 HP WiFi Combo Pro System', 'Smart Combo Pro', 4800, 12, true, 750, ARRAY['WiFi controller included','3/4 HP primary pump','High-output battery backup','Water level monitoring'], '{"hp_primary": 0.75, "gph_at_10ft": 4800, "head_ft": 30, "switch_type": "electronic", "discharge": "1.5_inch", "cord_ft": 15, "material": "cast_iron", "battery": "12v_dc", "voltage": 115, "wifi": true}', 'https://www.pumpspy.com/product/psc2075')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'pumpspy' AND c.slug = 'sump-pump-combination';


-- ======================== ADDITIONAL MODELS (to reach 120+) ========================

-- Zoeller Pedestal
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'pedestal', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('M84-PED', '1/2 HP Pedestal Sump Pump', 'Pedestal', 3420, 12, false, 260, ARRAY['Motor above water level','Cast iron base','Adjustable float switch','Long service life'], '{"hp": 0.5, "gph_at_10ft": 3420, "head_ft": 24, "switch_type": "adjustable_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron_base", "phase": "single", "voltage": 115}', 'https://www.zoeller.com/products/pedestal')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'zoeller' AND c.slug = 'sump-pump-pedestal';

-- Wayne Additional Submersible
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('CDU790-V', '1/3 HP Vertical Float Submersible', 'CDU', 2700, 8, false, 140, ARRAY['Thermoplastic construction','Vertical float switch','Narrow pit compatible','Top discharge'], '{"hp": 0.33, "gph_at_10ft": 2700, "head_ft": 20, "switch_type": "vertical_float", "discharge": "1.5_inch", "cord_ft": 8, "material": "thermoplastic", "phase": "single", "voltage": 120}', 'https://www.waynepumps.com/product/cdu790-v'),
  ('CDU1000E', '1 HP Cast Iron Submersible', 'CDU', 5400, 10, false, 290, ARRAY['Cast iron and steel construction','High-capacity 1 HP motor','Vertical float switch','Professional grade'], '{"hp": 1.0, "gph_at_10ft": 5400, "head_ft": 38, "switch_type": "vertical_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 120}', 'https://www.waynepumps.com/product/cdu1000e')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'wayne' AND c.slug = 'sump-pump-submersible';

-- Liberty Battery Backup
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('441', '12V Battery Backup Sump Pump', 'Battery Backup', 1800, 5, false, 380, ARRAY['12V DC battery-powered','Automatic activation','Audible alarm','Quick-disconnect cord'], '{"hp": 0.25, "gph_at_10ft": 1800, "head_ft": 12, "switch_type": "float", "discharge": "1.5_inch", "cord_ft": 8, "material": "thermoplastic", "battery_type": "12v_dc", "voltage": 12}', 'https://www.libertypumps.com/product/441'),
  ('442', '12V Battery Backup High Output', 'Battery Backup', 2700, 5, false, 450, ARRAY['High-output 12V DC backup','Automatic activation','Audible alarm','Extended run time'], '{"hp": 0.33, "gph_at_10ft": 2700, "head_ft": 15, "switch_type": "float", "discharge": "1.5_inch", "cord_ft": 8, "material": "thermoplastic", "battery_type": "12v_dc", "voltage": 12}', 'https://www.libertypumps.com/product/442')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'liberty-pumps' AND c.slug = 'sump-pump-battery-backup';

-- Liberty Pedestal
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'pedestal', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('P-370', '1/3 HP Pedestal Sump Pump', 'Pedestal', 2880, 15, false, 200, ARRAY['Motor above pit','Cast iron base','Adjustable float rod','Extended motor life'], '{"hp": 0.33, "gph_at_10ft": 2880, "head_ft": 22, "switch_type": "adjustable_float", "discharge": "1.25_inch", "cord_ft": 10, "material": "cast_iron_base", "phase": "single", "voltage": 115}', 'https://www.libertypumps.com/product/p-370')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'liberty-pumps' AND c.slug = 'sump-pump-pedestal';

-- Little Giant Battery Backup
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('SPB-33E', '1/3 HP Battery Backup', 'Battery Backup', 1800, 5, false, 280, ARRAY['12V DC battery-powered','Automatic activation','Audible alarm','Die-cast aluminum housing'], '{"hp": 0.33, "gph_at_10ft": 1800, "head_ft": 12, "switch_type": "float", "discharge": "1.5_inch", "cord_ft": 8, "material": "aluminum", "battery_type": "12v_dc", "voltage": 12}', 'https://www.lg-outdoor.com/product/spb-33e')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'little-giant' AND c.slug = 'sump-pump-battery-backup';

-- Everbilt Combination
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('ECBU33', '1/3 HP Combo w/ Battery Backup', NULL, 3040, 7, false, 350, ARRAY['1/3 HP primary pump','Battery backup included','Audible alarm','Easy installation'], '{"hp_primary": 0.33, "gph_at_10ft": 3040, "head_ft": 19, "switch_type": "vertical_float", "discharge": "1.5_inch", "cord_ft": 8, "material": "thermoplastic", "battery": "12v_dc", "voltage": 120}', 'https://www.homedepot.com/p/Everbilt-Combo-1-3-HP/ECBU33'),
  ('ECBU50', '1/2 HP Combo w/ Battery Backup', NULL, 3600, 7, false, 400, ARRAY['1/2 HP primary pump','Battery backup included','Audible alarm','Top discharge'], '{"hp_primary": 0.5, "gph_at_10ft": 3600, "head_ft": 22, "switch_type": "vertical_float", "discharge": "1.5_inch", "cord_ft": 8, "material": "thermoplastic", "battery": "12v_dc", "voltage": 120}', 'https://www.homedepot.com/p/Everbilt-Combo-1-2-HP/ECBU50')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'everbilt' AND c.slug = 'sump-pump-combination';

-- Superior Pump Battery Backup
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('92900', '12V Battery Backup Sump Pump', NULL, 1500, 5, false, 220, ARRAY['12V DC battery-powered','Automatic activation','Audible alarm','Thermoplastic construction'], '{"hp": 0.2, "gph_at_10ft": 1500, "head_ft": 10, "switch_type": "float", "discharge": "1.5_inch", "cord_ft": 8, "material": "thermoplastic", "battery_type": "12v_dc", "voltage": 12}', 'https://www.superiorpump.com/product/92900')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'superior-pump' AND c.slug = 'sump-pump-battery-backup';

-- Flotec Battery Backup
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('FPDC20', '12V Battery Backup Sump Pump', NULL, 1200, 5, false, 190, ARRAY['12V DC battery-powered','Automatic activation','Audible alarm','Budget-friendly backup'], '{"hp": 0.17, "gph_at_10ft": 1200, "head_ft": 10, "switch_type": "float", "discharge": "1.5_inch", "cord_ft": 8, "material": "thermoplastic", "battery_type": "12v_dc", "voltage": 12}', 'https://www.flotecwater.com/product/fpdc20')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'flotec' AND c.slug = 'sump-pump-battery-backup';

-- Flotec Combination
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('FPCC3320', '1/3 HP Combo w/ Battery Backup', NULL, 3000, 7, false, 320, ARRAY['1/3 HP primary pump','Battery backup included','Audible alarm','Corrosion-resistant'], '{"hp_primary": 0.33, "gph_at_10ft": 3000, "head_ft": 19, "switch_type": "tether_float", "discharge": "1.5_inch", "cord_ft": 8, "material": "thermoplastic", "battery": "12v_dc", "voltage": 115}', 'https://www.flotecwater.com/product/fpcc3320')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'flotec' AND c.slug = 'sump-pump-combination';

-- Basement Watchdog Pedestal
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'pedestal', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('BW1033P', '1/3 HP Pedestal Sump Pump', 'Pedestal', 2400, 12, false, 110, ARRAY['Motor above water level','Adjustable float switch','Steel column','Long motor life'], '{"hp": 0.33, "gph_at_10ft": 2400, "head_ft": 18, "switch_type": "adjustable_float", "discharge": "1.25_inch", "cord_ft": 8, "material": "steel", "phase": "single", "voltage": 120}', 'https://www.basementwatchdog.com/product/bw1033p')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'basement-watchdog' AND c.slug = 'sump-pump-pedestal';

-- Superior Pump Combination
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('92910', '1/3 HP Combo w/ Battery Backup', NULL, 2400, 7, false, 300, ARRAY['1/3 HP primary pump','Battery backup included','Audible alarm','Thermoplastic construction'], '{"hp_primary": 0.33, "gph_at_10ft": 2400, "head_ft": 22, "switch_type": "tether_float", "discharge": "1.5_inch", "cord_ft": 8, "material": "thermoplastic", "battery": "12v_dc", "voltage": 120}', 'https://www.superiorpump.com/product/92910'),
  ('92920', '1/2 HP Combo w/ Battery Backup', NULL, 3600, 8, false, 370, ARRAY['1/2 HP primary pump','Battery backup included','Audible alarm','Cast iron construction'], '{"hp_primary": 0.5, "gph_at_10ft": 3600, "head_ft": 28, "switch_type": "tether_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "battery": "12v_dc", "voltage": 120}', 'https://www.superiorpump.com/product/92920')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'superior-pump' AND c.slug = 'sump-pump-combination';

-- Basement Watchdog Sewage Ejector
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('BWSE50', '1/2 HP Sewage Ejector Pump', 'Sewage', 3600, 8, false, 240, ARRAY['Thermoplastic construction','2-inch solids handling','Automatic float switch','Top discharge'], '{"hp": 0.5, "gph_at_10ft": 3600, "head_ft": 20, "switch_type": "float", "discharge": "2_inch", "solids_handling": "2_inch", "cord_ft": 10, "material": "thermoplastic", "phase": "single", "voltage": 120}', 'https://www.basementwatchdog.com/product/bwse50')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'basement-watchdog' AND c.slug = 'sump-pump-sewage-ejector';

-- Zoeller Combination
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('M53-508', '1/3 HP Combo Primary + Battery', 'Aquanot', 2580, 10, false, 750, ARRAY['Cast iron 1/3 HP primary','Battery backup included','Audible alarm','Non-clogging impeller'], '{"hp_primary": 0.33, "gph_at_10ft": 2580, "head_ft": 19.5, "switch_type": "float", "discharge": "1.5_inch", "cord_ft": 9, "material": "cast_iron", "battery": "12v_dc", "voltage": 115}', 'https://www.zoeller.com/products/m53-508'),
  ('M98-508', '1/2 HP Combo Primary + Battery', 'Aquanot', 4320, 10, false, 850, ARRAY['Cast iron 1/2 HP primary','Battery backup included','Audible alarm','High-capacity'], '{"hp_primary": 0.5, "gph_at_10ft": 4320, "head_ft": 25, "switch_type": "float", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "battery": "12v_dc", "voltage": 115}', 'https://www.zoeller.com/products/m98-508')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'zoeller' AND c.slug = 'sump-pump-combination';

-- Zoeller Battery Backup
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('508-0014', 'Aquanot Fit Battery Backup', 'Aquanot', 1800, 5, false, 400, ARRAY['12V DC battery-powered','Automatic activation','Audible alarm','Cast iron construction'], '{"hp": 0.25, "gph_at_10ft": 1800, "head_ft": 12, "switch_type": "float", "discharge": "1.5_inch", "cord_ft": 8, "material": "cast_iron", "battery_type": "12v_dc", "voltage": 12}', 'https://www.zoeller.com/products/508-0014'),
  ('508-0019', 'Aquanot Pro Battery Backup', 'Aquanot', 2700, 5, true, 550, ARRAY['WiFi-enabled monitoring','12V DC battery-powered','Smart alerts','Self-testing'], '{"hp": 0.33, "gph_at_10ft": 2700, "head_ft": 16, "switch_type": "float", "discharge": "1.5_inch", "cord_ft": 8, "material": "cast_iron", "battery_type": "12v_dc", "voltage": 12, "wifi": true}', 'https://www.zoeller.com/products/508-0019')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'zoeller' AND c.slug = 'sump-pump-battery-backup';

-- Little Giant Combination
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('507700', '1/3 HP Combo w/ Battery Backup', 'Combo', 2880, 8, false, 450, ARRAY['1/3 HP primary pump','Battery backup included','Die-cast aluminum housing','Audible alarm'], '{"hp_primary": 0.33, "gph_at_10ft": 2880, "head_ft": 22, "switch_type": "float", "discharge": "1.5_inch", "cord_ft": 10, "material": "aluminum", "battery": "12v_dc", "voltage": 115}', 'https://www.lg-outdoor.com/product/combo-1-3hp'),
  ('508700', '1/2 HP Combo w/ Battery Backup', 'Combo', 3600, 10, false, 520, ARRAY['1/2 HP primary pump','Battery backup included','Cast iron construction','Dual float switches'], '{"hp_primary": 0.5, "gph_at_10ft": 3600, "head_ft": 25, "switch_type": "dual_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "battery": "12v_dc", "voltage": 115}', 'https://www.lg-outdoor.com/product/combo-1-2hp')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'little-giant' AND c.slug = 'sump-pump-combination';
