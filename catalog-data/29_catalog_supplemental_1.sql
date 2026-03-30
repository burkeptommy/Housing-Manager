SET ROLE postgres;
-- ============================================================================
-- Equipment Catalog Supplemental #1
-- Fills in brands with 0 catalog entries
-- SUMP PUMPS: 15 brands (~100 models)
-- GENERATORS: 6 brands (~40 models)
-- WATER HEATERS: 5 brands (~25 models)
-- LAUNDRY (Magic Chef): 1 brand (~8 models)
-- IRRIGATION (Netafim): 1 brand (~8 models)
-- BATHROOM (Rohl): 1 brand (~10 models)
-- WATER TREATMENT (Viqua): 1 brand (~8 models)
-- Total: ~200+ models
-- ============================================================================


-- ############################################################################
-- SUMP PUMPS
-- ############################################################################

-- ======================== UTILITECH ========================

-- Utilitech Submersible
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('UT-0033', '1/3 HP Submersible Sump Pump', 'Utilitech', 2160, 8, false, 110, ARRAY['Thermoplastic construction','Vertical float switch','10 ft cord','Lowes exclusive'], '{"hp": 0.33, "gph_at_10ft": 2160, "head_ft": 19, "switch_type": "vertical_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "thermoplastic", "phase": "single", "voltage": 115}', 'https://www.lowes.com/pd/Utilitech-0-33-HP-Submersible'),
  ('UT-0050', '1/2 HP Submersible Sump Pump', 'Utilitech', 3000, 8, false, 140, ARRAY['Thermoplastic housing','Tethered float switch','12 ft cord','Screened intake'], '{"hp": 0.5, "gph_at_10ft": 3000, "head_ft": 25, "switch_type": "tethered_float", "discharge": "1.5_inch", "cord_ft": 12, "material": "thermoplastic", "phase": "single", "voltage": 115}', 'https://www.lowes.com/pd/Utilitech-0-5-HP-Submersible'),
  ('UT-CI033', '1/3 HP Cast Iron Submersible', 'Utilitech Pro', 2580, 10, false, 170, ARRAY['Cast iron construction','Vertical float switch','Thermal overload protection'], '{"hp": 0.33, "gph_at_10ft": 2580, "head_ft": 21, "switch_type": "vertical_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.lowes.com/pd/Utilitech-Pro-Cast-Iron-033'),
  ('UT-CI050', '1/2 HP Cast Iron Submersible', 'Utilitech Pro', 3600, 10, false, 200, ARRAY['Cast iron housing','Tethered float switch','Oil-filled motor','Thermal protection'], '{"hp": 0.5, "gph_at_10ft": 3600, "head_ft": 25, "switch_type": "tethered_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.lowes.com/pd/Utilitech-Pro-Cast-Iron-050'),
  ('UT-0025', '1/4 HP Submersible Sump Pump', 'Utilitech', 1800, 7, false, 85, ARRAY['Budget-friendly','Thermoplastic','Vertical float switch','Compact design'], '{"hp": 0.25, "gph_at_10ft": 1800, "head_ft": 15, "switch_type": "vertical_float", "discharge": "1.5_inch", "cord_ft": 8, "material": "thermoplastic", "phase": "single", "voltage": 115}', 'https://www.lowes.com/pd/Utilitech-0-25-HP-Submersible')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'utilitech' AND c.slug = 'sump-pump-submersible';

-- Utilitech Battery Backup
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('UT-BBU033', '1/3 HP Battery Backup Sump Pump', 'Utilitech', 1500, 5, false, 280, ARRAY['12V DC battery backup','Audible alarm','Automatic switchover','Trickle charger included'], '{"hp": 0.33, "gph_at_10ft": 1500, "head_ft": 15, "switch_type": "float", "discharge": "1.5_inch", "battery_type": "12V_DC", "material": "thermoplastic", "voltage": 12}', 'https://www.lowes.com/pd/Utilitech-Battery-Backup-Sump'),
  ('UT-BBU050', '1/2 HP Battery Backup Sump Pump', 'Utilitech Pro', 2200, 5, false, 350, ARRAY['12V DC battery backup','Audible/visual alarm','Auto test cycle','Heavy-duty charger'], '{"hp": 0.5, "gph_at_10ft": 2200, "head_ft": 20, "switch_type": "float", "discharge": "1.5_inch", "battery_type": "12V_DC", "material": "thermoplastic", "voltage": 12}', 'https://www.lowes.com/pd/Utilitech-Pro-Battery-Backup')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'utilitech' AND c.slug = 'sump-pump-battery-backup';


-- ======================== DRUMMOND ========================

-- Drummond Submersible
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('63322', '1/4 HP Submersible Sump Pump', 'Drummond', 2000, 6, false, 50, ARRAY['Ultra-budget','Thermoplastic construction','Tethered float switch','Harbor Freight exclusive'], '{"hp": 0.25, "gph_at_10ft": 2000, "head_ft": 18, "switch_type": "tethered_float", "discharge": "1.5_inch", "cord_ft": 8, "material": "thermoplastic", "phase": "single", "voltage": 115}', 'https://www.harborfreight.com/drummond-1-4-hp-submersible-sump-pump-63322'),
  ('63314', '1/3 HP Submersible Sump Pump', 'Drummond', 2500, 6, false, 65, ARRAY['Budget sump pump','Thermoplastic','Vertical float switch','Screened intake'], '{"hp": 0.33, "gph_at_10ft": 2500, "head_ft": 20, "switch_type": "vertical_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "thermoplastic", "phase": "single", "voltage": 115}', 'https://www.harborfreight.com/drummond-1-3-hp-submersible-sump-pump-63314'),
  ('63316', '1/2 HP Submersible Sump Pump', 'Drummond', 3000, 7, false, 80, ARRAY['Mid-range','Thermoplastic','Tethered float switch','10 ft cord'], '{"hp": 0.5, "gph_at_10ft": 3000, "head_ft": 25, "switch_type": "tethered_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "thermoplastic", "phase": "single", "voltage": 115}', 'https://www.harborfreight.com/drummond-1-2-hp-submersible-sump-pump-63316'),
  ('63318', '3/4 HP Submersible Sump Pump', 'Drummond', 4200, 7, false, 110, ARRAY['High capacity','Thermoplastic housing','Tethered float','Wide intake'], '{"hp": 0.75, "gph_at_10ft": 4200, "head_ft": 28, "switch_type": "tethered_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "thermoplastic", "phase": "single", "voltage": 115}', 'https://www.harborfreight.com/drummond-3-4-hp-submersible-sump-pump-63318'),
  ('56604', '1/6 HP Submersible Utility Pump', 'Drummond', 1350, 5, false, 40, ARRAY['Compact utility pump','Flat suction','Garden hose adapter','Portable'], '{"hp": 0.16, "gph_at_10ft": 1350, "head_ft": 15, "switch_type": "manual", "discharge": "1.25_inch", "cord_ft": 8, "material": "thermoplastic", "phase": "single", "voltage": 115}', 'https://www.harborfreight.com/drummond-1-6-hp-utility-pump-56604')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'drummond' AND c.slug = 'sump-pump-submersible';


-- ======================== SIMER ========================

-- Simer Submersible
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('2905', '1/4 HP Submersible Sump Pump', 'Geyser', 1680, 7, false, 95, ARRAY['Thermoplastic construction','Tethered float switch','8 ft cord','Pentair brand'], '{"hp": 0.25, "gph_at_10ft": 1680, "head_ft": 17, "switch_type": "tethered_float", "discharge": "1.25_inch", "cord_ft": 8, "material": "thermoplastic", "phase": "single", "voltage": 115}', 'https://www.simerpumps.com/products/2905'),
  ('2945', '1/3 HP Submersible Sump Pump', 'Geyser', 2520, 8, false, 120, ARRAY['Thermoplastic housing','Vertical float switch','Screened intake','Pentair brand'], '{"hp": 0.33, "gph_at_10ft": 2520, "head_ft": 20, "switch_type": "vertical_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "thermoplastic", "phase": "single", "voltage": 115}', 'https://www.simerpumps.com/products/2945'),
  ('2957', '1/2 HP Submersible Sump Pump', 'Geyser', 3480, 8, false, 150, ARRAY['Thermoplastic construction','Tethered float switch','High capacity','Thermal protection'], '{"hp": 0.5, "gph_at_10ft": 3480, "head_ft": 25, "switch_type": "tethered_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "thermoplastic", "phase": "single", "voltage": 115}', 'https://www.simerpumps.com/products/2957'),
  ('3986', '1/2 HP Cast Iron Submersible', 'Geyser Pro', 4100, 10, false, 200, ARRAY['Cast iron housing','Vertical float switch','Oil-filled motor','Heavy-duty'], '{"hp": 0.5, "gph_at_10ft": 4100, "head_ft": 25, "switch_type": "vertical_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.simerpumps.com/products/3986')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'simer' AND c.slug = 'sump-pump-submersible';

-- Simer Sewage Ejector
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('2961', '1/2 HP Sewage Ejector Pump', 'Geyser', 4800, 8, false, 250, ARRAY['2-inch solids handling','Cast iron/thermoplastic','Automatic float switch','Pentair brand'], '{"hp": 0.5, "gph_at_10ft": 4800, "head_ft": 20, "switch_type": "tethered_float", "discharge": "2_inch", "solids_handling": "2_inch", "cord_ft": 10, "material": "thermoplastic", "phase": "single", "voltage": 115}', 'https://www.simerpumps.com/products/2961'),
  ('3988', '3/4 HP Sewage Ejector Pump', 'Geyser Pro', 6000, 10, false, 350, ARRAY['2-inch solids handling','Cast iron construction','Heavy-duty motor','Automatic operation'], '{"hp": 0.75, "gph_at_10ft": 6000, "head_ft": 25, "switch_type": "tethered_float", "discharge": "2_inch", "solids_handling": "2_inch", "cord_ft": 12, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.simerpumps.com/products/3988'),
  ('2165', '1/2 HP Sewage Ejector w/ Tether', 'Geyser', 4500, 8, false, 280, ARRAY['2-inch solids handling','Tethered float switch','Thermoplastic/cast iron hybrid','Economy sewage pump'], '{"hp": 0.5, "gph_at_10ft": 4500, "head_ft": 20, "switch_type": "tethered_float", "discharge": "2_inch", "solids_handling": "2_inch", "cord_ft": 10, "material": "thermoplastic", "phase": "single", "voltage": 115}', 'https://www.simerpumps.com/products/2165')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'simer' AND c.slug = 'sump-pump-sewage-ejector';


-- ======================== RIDGID ========================

-- Ridgid Submersible
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('500RSU', '1/2 HP Cast Iron Submersible', 'Ridgid', 4200, 10, false, 200, ARRAY['Cast iron construction','Dual float switch','Stainless steel fasteners','Home Depot exclusive'], '{"hp": 0.5, "gph_at_10ft": 4200, "head_ft": 25, "switch_type": "dual_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.homedepot.com/p/RIDGID-1-2-HP-Cast-Iron-Submersible/'),
  ('330RSU', '1/3 HP Cast Iron Submersible', 'Ridgid', 2760, 10, false, 170, ARRAY['Cast iron housing','Tethered float switch','Thermal overload protection','10 ft cord'], '{"hp": 0.33, "gph_at_10ft": 2760, "head_ft": 20, "switch_type": "tethered_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.homedepot.com/p/RIDGID-1-3-HP-Cast-Iron-Submersible/'),
  ('250RSU', '1/4 HP Submersible Sump Pump', 'Ridgid', 2100, 8, false, 130, ARRAY['Cast iron construction','Vertical float switch','Oil-filled motor','Compact design'], '{"hp": 0.25, "gph_at_10ft": 2100, "head_ft": 18, "switch_type": "vertical_float", "discharge": "1.5_inch", "cord_ft": 8, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.homedepot.com/p/RIDGID-1-4-HP-Submersible/'),
  ('750RSU', '3/4 HP Cast Iron Submersible', 'Ridgid', 5100, 12, false, 260, ARRAY['Cast iron construction','Heavy-duty motor','Dual float switch','Wide base'], '{"hp": 0.75, "gph_at_10ft": 5100, "head_ft": 30, "switch_type": "dual_float", "discharge": "1.5_inch", "cord_ft": 12, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.homedepot.com/p/RIDGID-3-4-HP-Cast-Iron-Submersible/')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'ridgid' AND c.slug = 'sump-pump-submersible';

-- Ridgid Sewage Ejector
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('500RSEJ', '1/2 HP Sewage Ejector Pump', 'Ridgid', 5000, 10, false, 300, ARRAY['Cast iron construction','2-inch solids handling','Automatic float switch','Heavy-duty vortex impeller'], '{"hp": 0.5, "gph_at_10ft": 5000, "head_ft": 22, "switch_type": "tethered_float", "discharge": "2_inch", "solids_handling": "2_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.homedepot.com/p/RIDGID-1-2-HP-Sewage-Ejector/'),
  ('750RSEJ', '3/4 HP Sewage Ejector Pump', 'Ridgid', 6300, 10, false, 380, ARRAY['Cast iron construction','2-inch solids handling','Heavy-duty motor','Non-clogging impeller'], '{"hp": 0.75, "gph_at_10ft": 6300, "head_ft": 28, "switch_type": "tethered_float", "discharge": "2_inch", "solids_handling": "2_inch", "cord_ft": 12, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.homedepot.com/p/RIDGID-3-4-HP-Sewage-Ejector/'),
  ('1000RSEJ', '1 HP Sewage Ejector Pump', 'Ridgid', 7500, 12, false, 450, ARRAY['Cast iron construction','2-inch solids handling','High-capacity motor','Heavy-duty impeller'], '{"hp": 1.0, "gph_at_10ft": 7500, "head_ft": 35, "switch_type": "tethered_float", "discharge": "2_inch", "solids_handling": "2_inch", "cord_ft": 15, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.homedepot.com/p/RIDGID-1-HP-Sewage-Ejector/')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'ridgid' AND c.slug = 'sump-pump-sewage-ejector';


-- ======================== ECO-FLO ========================

-- ECO-FLO Submersible
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('ECD33V', '1/3 HP Submersible Sump Pump', 'ECO-FLO', 3300, 8, false, 100, ARRAY['Vertical float switch','Thermoplastic construction','Screened intake','Energy efficient'], '{"hp": 0.33, "gph_at_10ft": 3300, "head_ft": 22, "switch_type": "vertical_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "thermoplastic", "phase": "single", "voltage": 115}', 'https://www.ecoflopumps.com/products/ecd33v'),
  ('ECD50V', '1/2 HP Submersible Sump Pump', 'ECO-FLO', 4400, 8, false, 130, ARRAY['Vertical float switch','Thermoplastic housing','High capacity','Energy efficient'], '{"hp": 0.5, "gph_at_10ft": 4400, "head_ft": 26, "switch_type": "vertical_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "thermoplastic", "phase": "single", "voltage": 115}', 'https://www.ecoflopumps.com/products/ecd50v'),
  ('ECD33W', '1/3 HP Cast Iron Submersible', 'ECO-FLO Pro', 3300, 10, false, 150, ARRAY['Cast iron construction','Wide-angle float switch','Oil-filled motor','Thermal protection'], '{"hp": 0.33, "gph_at_10ft": 3300, "head_ft": 22, "switch_type": "wide_angle_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.ecoflopumps.com/products/ecd33w'),
  ('ECD50W', '1/2 HP Cast Iron Submersible', 'ECO-FLO Pro', 4400, 10, false, 180, ARRAY['Cast iron housing','Wide-angle float switch','Oil-filled motor','Heavy-duty'], '{"hp": 0.5, "gph_at_10ft": 4400, "head_ft": 26, "switch_type": "wide_angle_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.ecoflopumps.com/products/ecd50w'),
  ('ECD75V', '3/4 HP Submersible Sump Pump', 'ECO-FLO', 5500, 8, false, 160, ARRAY['High capacity','Thermoplastic housing','Tethered float switch','Wide base'], '{"hp": 0.75, "gph_at_10ft": 5500, "head_ft": 30, "switch_type": "tethered_float", "discharge": "1.5_inch", "cord_ft": 12, "material": "thermoplastic", "phase": "single", "voltage": 115}', 'https://www.ecoflopumps.com/products/ecd75v')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'eco-flo' AND c.slug = 'sump-pump-submersible';

-- ECO-FLO Battery Backup
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('EBBS', 'Battery Backup Sump Pump System', 'ECO-FLO', 1800, 5, false, 250, ARRAY['12V DC battery backup','Audible alarm','Automatic switchover','Float switch included'], '{"hp": 0.25, "gph_at_10ft": 1800, "head_ft": 18, "switch_type": "float", "discharge": "1.5_inch", "battery_type": "12V_DC", "material": "thermoplastic", "voltage": 12}', 'https://www.ecoflopumps.com/products/ebbs'),
  ('EBBS-AUX', 'Auxiliary Battery Backup Pump', 'ECO-FLO', 2400, 5, false, 300, ARRAY['12V DC backup','High-output pump','LED indicator','Quick-connect fittings'], '{"hp": 0.33, "gph_at_10ft": 2400, "head_ft": 20, "switch_type": "float", "discharge": "1.5_inch", "battery_type": "12V_DC", "material": "thermoplastic", "voltage": 12}', 'https://www.ecoflopumps.com/products/ebbs-aux'),
  ('EBBS-PRO', 'Pro Battery Backup Sump Pump', 'ECO-FLO Pro', 3000, 5, false, 380, ARRAY['12V DC battery backup','High-output motor','Audible/visual alarm','Heavy-duty charger','Auto test'], '{"hp": 0.5, "gph_at_10ft": 3000, "head_ft": 22, "switch_type": "float", "discharge": "1.5_inch", "battery_type": "12V_DC", "material": "thermoplastic", "voltage": 12}', 'https://www.ecoflopumps.com/products/ebbs-pro')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'eco-flo' AND c.slug = 'sump-pump-battery-backup';


-- ======================== STAR WATER SYSTEMS ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('3SEH', '1/3 HP Submersible Sump Pump', 'Star', 2400, 8, false, 100, ARRAY['Thermoplastic housing','Tethered float switch','10 ft power cord','Screened intake'], '{"hp": 0.33, "gph_at_10ft": 2400, "head_ft": 19, "switch_type": "tethered_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "thermoplastic", "phase": "single", "voltage": 115}', 'https://www.starwatersystems.com/products/sump/3SEH'),
  ('4SEH', '1/2 HP Submersible Sump Pump', 'Star', 3300, 8, false, 130, ARRAY['Thermoplastic construction','Tethered float switch','High capacity','Thermal protection'], '{"hp": 0.5, "gph_at_10ft": 3300, "head_ft": 24, "switch_type": "tethered_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "thermoplastic", "phase": "single", "voltage": 115}', 'https://www.starwatersystems.com/products/sump/4SEH'),
  ('3SCIA', '1/3 HP Cast Iron Submersible', 'Star Pro', 2520, 10, false, 160, ARRAY['Cast iron construction','Automatic float switch','Oil-filled motor','Heavy-duty base'], '{"hp": 0.33, "gph_at_10ft": 2520, "head_ft": 20, "switch_type": "float", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.starwatersystems.com/products/sump/3SCIA'),
  ('4SCIA', '1/2 HP Cast Iron Submersible', 'Star Pro', 3600, 10, false, 190, ARRAY['Cast iron housing','Automatic float switch','Oil-filled motor','Thermal overload'], '{"hp": 0.5, "gph_at_10ft": 3600, "head_ft": 25, "switch_type": "float", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.starwatersystems.com/products/sump/4SCIA'),
  ('6SCIA', '3/4 HP Cast Iron Submersible', 'Star Pro', 4800, 10, false, 230, ARRAY['Cast iron construction','Heavy-duty motor','Automatic float switch','High capacity'], '{"hp": 0.75, "gph_at_10ft": 4800, "head_ft": 30, "switch_type": "float", "discharge": "1.5_inch", "cord_ft": 12, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.starwatersystems.com/products/sump/6SCIA')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'star-water-systems' AND c.slug = 'sump-pump-submersible';


-- ======================== BURCAM ========================

-- BurCam Submersible
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('300608Z', '1/3 HP Submersible Sump Pump', 'BurCam', 2400, 8, false, 110, ARRAY['Zinc alloy housing','Tethered float switch','Screened intake','Canadian made'], '{"hp": 0.33, "gph_at_10ft": 2400, "head_ft": 20, "switch_type": "tethered_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "zinc_alloy", "phase": "single", "voltage": 115}', 'https://www.burcam.com/products/300608Z'),
  ('300610Z', '1/2 HP Submersible Sump Pump', 'BurCam', 3300, 8, false, 140, ARRAY['Zinc alloy construction','Tethered float switch','High capacity','Thermal protection'], '{"hp": 0.5, "gph_at_10ft": 3300, "head_ft": 25, "switch_type": "tethered_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "zinc_alloy", "phase": "single", "voltage": 115}', 'https://www.burcam.com/products/300610Z'),
  ('300614Z', '3/4 HP Submersible Sump Pump', 'BurCam', 4500, 10, false, 190, ARRAY['Zinc alloy housing','Heavy-duty motor','Tethered float switch','Wide base'], '{"hp": 0.75, "gph_at_10ft": 4500, "head_ft": 30, "switch_type": "tethered_float", "discharge": "1.5_inch", "cord_ft": 12, "material": "zinc_alloy", "phase": "single", "voltage": 115}', 'https://www.burcam.com/products/300614Z'),
  ('300508', '1/3 HP Cast Iron Submersible', 'BurCam Pro', 2580, 10, false, 160, ARRAY['Cast iron construction','Vertical float switch','Oil-filled motor','Heavy-duty'], '{"hp": 0.33, "gph_at_10ft": 2580, "head_ft": 21, "switch_type": "vertical_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.burcam.com/products/300508'),
  ('300510', '1/2 HP Cast Iron Submersible', 'BurCam Pro', 3600, 10, false, 195, ARRAY['Cast iron housing','Vertical float switch','Oil-filled motor','Thermal overload'], '{"hp": 0.5, "gph_at_10ft": 3600, "head_ft": 25, "switch_type": "vertical_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.burcam.com/products/300510')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'burcam' AND c.slug = 'sump-pump-submersible';

-- BurCam Sewage Ejector
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('400418T', '1/2 HP Sewage Ejector Pump', 'BurCam', 4800, 8, false, 280, ARRAY['2-inch solids handling','Thermoplastic construction','Automatic float switch','Vortex impeller'], '{"hp": 0.5, "gph_at_10ft": 4800, "head_ft": 22, "switch_type": "tethered_float", "discharge": "2_inch", "solids_handling": "2_inch", "cord_ft": 10, "material": "thermoplastic", "phase": "single", "voltage": 115}', 'https://www.burcam.com/products/400418T'),
  ('400504Z', '3/4 HP Cast Iron Sewage Ejector', 'BurCam Pro', 6000, 10, false, 380, ARRAY['2-inch solids handling','Cast iron construction','Heavy-duty motor','Non-clogging impeller'], '{"hp": 0.75, "gph_at_10ft": 6000, "head_ft": 28, "switch_type": "tethered_float", "discharge": "2_inch", "solids_handling": "2_inch", "cord_ft": 12, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.burcam.com/products/400504Z')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'burcam' AND c.slug = 'sump-pump-sewage-ejector';


-- ======================== MYERS ========================

-- Myers Submersible
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('S33-20', '1/3 HP Submersible Sump Pump', 'S Series', 2400, 12, false, 230, ARRAY['Cast iron construction','Oil-filled motor','Snap-action float switch','Pentair premium brand'], '{"hp": 0.33, "gph_at_10ft": 2400, "head_ft": 20, "switch_type": "snap_action_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.femyers.com/products/sump/S33-20'),
  ('S50-20', '1/2 HP Submersible Sump Pump', 'S Series', 3600, 12, false, 280, ARRAY['Cast iron housing','Oil-filled motor','Snap-action float switch','High capacity'], '{"hp": 0.5, "gph_at_10ft": 3600, "head_ft": 25, "switch_type": "snap_action_float", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.femyers.com/products/sump/S50-20'),
  ('S75-20', '3/4 HP Submersible Sump Pump', 'S Series', 4800, 12, false, 340, ARRAY['Cast iron construction','Heavy-duty motor','Oil-filled motor','Wide base'], '{"hp": 0.75, "gph_at_10ft": 4800, "head_ft": 30, "switch_type": "snap_action_float", "discharge": "1.5_inch", "cord_ft": 12, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.femyers.com/products/sump/S75-20'),
  ('S33PC', '1/3 HP Submersible w/ Piggyback Switch', 'S Series', 2400, 12, false, 250, ARRAY['Cast iron construction','Piggyback plug switch','Manual or auto operation','Versatile'], '{"hp": 0.33, "gph_at_10ft": 2400, "head_ft": 20, "switch_type": "piggyback", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.femyers.com/products/sump/S33PC')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'myers' AND c.slug = 'sump-pump-submersible';

-- Myers Sewage Ejector
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('ME45S-11', '1/2 HP Sewage Ejector Pump', 'ME Series', 5400, 10, false, 420, ARRAY['2-inch solids handling','Cast iron construction','Oil-filled motor','Non-clogging vortex impeller'], '{"hp": 0.5, "gph_at_10ft": 5400, "head_ft": 22, "switch_type": "float", "discharge": "2_inch", "solids_handling": "2_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.femyers.com/products/sewage/ME45S-11'),
  ('ME75S-11', '3/4 HP Sewage Ejector Pump', 'ME Series', 6600, 10, false, 500, ARRAY['2-inch solids handling','Cast iron construction','Heavy-duty motor','Thermal overload'], '{"hp": 0.75, "gph_at_10ft": 6600, "head_ft": 28, "switch_type": "float", "discharge": "2_inch", "solids_handling": "2_inch", "cord_ft": 12, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.femyers.com/products/sewage/ME75S-11'),
  ('ME100S-21', '1 HP Sewage Ejector Pump', 'ME Series', 7800, 12, false, 600, ARRAY['2-inch solids handling','Cast iron construction','Premium motor','High capacity'], '{"hp": 1.0, "gph_at_10ft": 7800, "head_ft": 35, "switch_type": "float", "discharge": "2_inch", "solids_handling": "2_inch", "cord_ft": 15, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.femyers.com/products/sewage/ME100S-21')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'myers' AND c.slug = 'sump-pump-sewage-ejector';


-- ======================== HYDROMATIC ========================

-- Hydromatic Sewage Ejector
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('SKV50AW1', '1/2 HP Sewage Ejector', 'SKV', 5400, 12, false, 480, ARRAY['2-inch solids handling','Cast iron construction','Oil-filled motor','Automatic float switch','Pentair premium'], '{"hp": 0.5, "gph_at_10ft": 5400, "head_ft": 25, "switch_type": "float", "discharge": "2_inch", "solids_handling": "2_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.hydromatic.com/products/SKV50AW1'),
  ('SKV75AW1', '3/4 HP Sewage Ejector', 'SKV', 6600, 12, false, 560, ARRAY['2-inch solids handling','Cast iron construction','Heavy-duty motor','Automatic operation'], '{"hp": 0.75, "gph_at_10ft": 6600, "head_ft": 30, "switch_type": "float", "discharge": "2_inch", "solids_handling": "2_inch", "cord_ft": 12, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.hydromatic.com/products/SKV75AW1'),
  ('SK50A1', '1/2 HP Sewage Ejector', 'SK', 4800, 12, false, 440, ARRAY['2-inch solids handling','Cast iron housing','Oil-filled motor','Non-clogging impeller'], '{"hp": 0.5, "gph_at_10ft": 4800, "head_ft": 22, "switch_type": "float", "discharge": "2_inch", "solids_handling": "2_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.hydromatic.com/products/SK50A1'),
  ('SK100M4', '1 HP Sewage Ejector', 'SK', 8400, 15, false, 700, ARRAY['2-inch solids handling','Cast iron construction','High-capacity motor','Industrial grade'], '{"hp": 1.0, "gph_at_10ft": 8400, "head_ft": 38, "switch_type": "float", "discharge": "3_inch", "solids_handling": "2_inch", "cord_ft": 15, "material": "cast_iron", "phase": "single", "voltage": 230}', 'https://www.hydromatic.com/products/SK100M4'),
  ('DERA50M2', '1/2 HP Effluent Pump', 'DERA', 4200, 12, false, 400, ARRAY['Effluent rated','Cast iron construction','Oil-filled motor','Small solids handling'], '{"hp": 0.5, "gph_at_10ft": 4200, "head_ft": 25, "switch_type": "float", "discharge": "2_inch", "solids_handling": "0.75_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.hydromatic.com/products/DERA50M2'),
  ('SKV100AW1', '1 HP Sewage Ejector', 'SKV', 8000, 15, false, 650, ARRAY['2-inch solids handling','Cast iron construction','Premium motor','High head capacity'], '{"hp": 1.0, "gph_at_10ft": 8000, "head_ft": 36, "switch_type": "float", "discharge": "2_inch", "solids_handling": "2_inch", "cord_ft": 15, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.hydromatic.com/products/SKV100AW1')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'hydromatic' AND c.slug = 'sump-pump-sewage-ejector';


-- ======================== BARNES ========================

-- Barnes Sewage Ejector
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('SE411', '1/2 HP Sewage Ejector', 'SE', 5100, 10, false, 400, ARRAY['2-inch solids handling','Cast iron construction','Automatic float switch','Crane Pumps brand'], '{"hp": 0.5, "gph_at_10ft": 5100, "head_ft": 22, "switch_type": "float", "discharge": "2_inch", "solids_handling": "2_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.cranepumps.com/barnes/SE411'),
  ('SE521', '3/4 HP Sewage Ejector', 'SE', 6300, 10, false, 480, ARRAY['2-inch solids handling','Cast iron construction','Heavy-duty motor','Non-clogging impeller'], '{"hp": 0.75, "gph_at_10ft": 6300, "head_ft": 28, "switch_type": "float", "discharge": "2_inch", "solids_handling": "2_inch", "cord_ft": 12, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.cranepumps.com/barnes/SE521'),
  ('SGV2022L', '2 HP Grinder Pump', 'Ogre', 3000, 12, false, 1200, ARRAY['Grinder pump','1.25-inch discharge','Cast iron/steel','Ogre grinding system'], '{"hp": 2.0, "gph_at_10ft": 3000, "head_ft": 80, "switch_type": "float", "discharge": "1.25_inch", "solids_handling": "grinder", "cord_ft": 20, "material": "cast_iron", "phase": "single", "voltage": 230}', 'https://www.cranepumps.com/barnes/SGV2022L'),
  ('SE411HT', '1/2 HP High-Temp Sewage Ejector', 'SE HT', 5100, 10, false, 480, ARRAY['High-temp rated','2-inch solids handling','Cast iron construction','Laundry/dishwasher safe'], '{"hp": 0.5, "gph_at_10ft": 5100, "head_ft": 22, "switch_type": "float", "discharge": "2_inch", "solids_handling": "2_inch", "cord_ft": 10, "material": "cast_iron", "max_temp_f": 200, "phase": "single", "voltage": 115}', 'https://www.cranepumps.com/barnes/SE411HT'),
  ('SE1021', '1 HP Sewage Ejector', 'SE', 7800, 12, false, 580, ARRAY['2-inch solids handling','Cast iron construction','High-capacity motor','Heavy-duty float'], '{"hp": 1.0, "gph_at_10ft": 7800, "head_ft": 35, "switch_type": "float", "discharge": "2_inch", "solids_handling": "2_inch", "cord_ft": 15, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.cranepumps.com/barnes/SE1021')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'barnes' AND c.slug = 'sump-pump-sewage-ejector';


-- ======================== TSURUMI ========================

-- Tsurumi Submersible
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('LSC1.4S', '1/2 HP Submersible Sump Pump', 'LSC', 3300, 15, false, 320, ARRAY['Japanese engineering','Cast iron/stainless steel','Oil lifter seal','Anti-wicking cable'], '{"hp": 0.5, "gph_at_10ft": 3300, "head_ft": 23, "switch_type": "float", "discharge": "2_inch", "cord_ft": 16, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.tsurumipump.com/products/LSC1.4S'),
  ('LB-480A', '2/3 HP Submersible Dewatering Pump', 'LB', 3900, 15, false, 450, ARRAY['Japanese engineering','Cast iron construction','Oil lifter seal system','Heavy-duty motor'], '{"hp": 0.67, "gph_at_10ft": 3900, "head_ft": 32, "switch_type": "float", "discharge": "2_inch", "cord_ft": 32, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.tsurumipump.com/products/LB-480A'),
  ('LSC1.4S-61', '1/2 HP Sump Pump (60 Hz)', 'LSC', 3300, 15, false, 340, ARRAY['Dual mechanical seal','Cast iron volute','Silicon carbide seal faces','Long life'], '{"hp": 0.5, "gph_at_10ft": 3300, "head_ft": 23, "switch_type": "float", "discharge": "2_inch", "cord_ft": 16, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.tsurumipump.com/products/LSC1.4S-61'),
  ('HS2.4S', '1/2 HP Submersible Trash Pump', 'HS', 3000, 15, false, 380, ARRAY['Trash handling','Semi-vortex impeller','Cast iron construction','Agitator bottom'], '{"hp": 0.5, "gph_at_10ft": 3000, "head_ft": 26, "switch_type": "float", "discharge": "2_inch", "solids_handling": "1_inch", "cord_ft": 16, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.tsurumipump.com/products/HS2.4S'),
  ('LB-800', '1 HP Submersible Dewatering Pump', 'LB', 5400, 15, false, 550, ARRAY['Japanese engineering','Cast iron/stainless','High-capacity','Oil lifter seal system'], '{"hp": 1.0, "gph_at_10ft": 5400, "head_ft": 42, "switch_type": "float", "discharge": "3_inch", "cord_ft": 32, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.tsurumipump.com/products/LB-800')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'tsurumi' AND c.slug = 'sump-pump-submersible';


-- ======================== GLENTRONICS ========================

-- Glentronics Battery Backup (Pro Series / Basement Watchdog parent)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('PHCC-2400', 'Pro Series 2400 Battery Backup', 'Pro Series', 2400, 5, true, 450, ARRAY['Wi-Fi monitoring','2400 GPH','Dual float switch','Smart diagnostics','App alerts'], '{"hp": 0.33, "gph_at_10ft": 2400, "head_ft": 20, "switch_type": "dual_float", "discharge": "1.5_inch", "battery_type": "12V_DC", "material": "thermoplastic", "voltage": 12, "wifi": true}', 'https://www.glentronics.com/products/PHCC-2400'),
  ('PHCC-1850', 'Pro Series 1850 Battery Backup', 'Pro Series', 1850, 5, false, 350, ARRAY['Battery backup pump','1850 GPH','Audible alarm','Auto test cycle'], '{"hp": 0.25, "gph_at_10ft": 1850, "head_ft": 18, "switch_type": "float", "discharge": "1.5_inch", "battery_type": "12V_DC", "material": "thermoplastic", "voltage": 12}', 'https://www.glentronics.com/products/PHCC-1850'),
  ('PHCC-3000', 'Pro Series 3000 Battery Backup', 'Pro Series', 3000, 5, true, 550, ARRAY['Wi-Fi monitoring','3000 GPH high-output','Dual float switch','Smart diagnostics'], '{"hp": 0.5, "gph_at_10ft": 3000, "head_ft": 22, "switch_type": "dual_float", "discharge": "1.5_inch", "battery_type": "12V_DC", "material": "thermoplastic", "voltage": 12, "wifi": true}', 'https://www.glentronics.com/products/PHCC-3000')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'glentronics' AND c.slug = 'sump-pump-battery-backup';

-- Glentronics Combination (Primary + Backup)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('PS-C22', 'Pro Series Combo 1/3 HP + Battery Backup', 'Pro Series', 3000, 8, true, 750, ARRAY['1/3 HP primary pump','Battery backup included','Wi-Fi monitoring','Dual pump system','App alerts'], '{"hp_primary": 0.33, "gph_at_10ft": 3000, "head_ft": 22, "switch_type": "dual_float", "discharge": "1.5_inch", "battery_type": "12V_DC", "material": "cast_iron_primary", "voltage": 115}', 'https://www.glentronics.com/products/PS-C22'),
  ('PS-C33', 'Pro Series Combo 1/2 HP + Battery Backup', 'Pro Series', 4000, 8, true, 900, ARRAY['1/2 HP primary pump','Battery backup included','Wi-Fi monitoring','High-output dual system','Smart diagnostics'], '{"hp_primary": 0.5, "gph_at_10ft": 4000, "head_ft": 25, "switch_type": "dual_float", "discharge": "1.5_inch", "battery_type": "12V_DC", "material": "cast_iron_primary", "voltage": 115}', 'https://www.glentronics.com/products/PS-C33'),
  ('PS-C11', 'Pro Series Combo 1/4 HP + Battery Backup', 'Pro Series', 2400, 8, false, 600, ARRAY['1/4 HP primary pump','Battery backup included','Audible alarm','Dual float switch'], '{"hp_primary": 0.25, "gph_at_10ft": 2400, "head_ft": 18, "switch_type": "dual_float", "discharge": "1.5_inch", "battery_type": "12V_DC", "material": "thermoplastic_primary", "voltage": 115}', 'https://www.glentronics.com/products/PS-C11')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'glentronics' AND c.slug = 'sump-pump-combination';


-- ======================== ION TECHNOLOGIES ========================

-- Ion Technologies Submersible
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('MHP20816', '1/3 HP MightyFlex Submersible', 'MightyFlex', 2400, 12, false, 280, ARRAY['Digital float switch','No moving parts in switch','Cast iron construction','Narrow profile fits tight pits'], '{"hp": 0.33, "gph_at_10ft": 2400, "head_ft": 22, "switch_type": "digital_ioswitch", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.iontechnologies.net/products/MHP20816'),
  ('MHP25017', '1/2 HP MightyFlex Submersible', 'MightyFlex', 3600, 12, false, 340, ARRAY['Digital ioSwitch','No moving parts','Cast iron housing','High capacity'], '{"hp": 0.5, "gph_at_10ft": 3600, "head_ft": 26, "switch_type": "digital_ioswitch", "discharge": "1.5_inch", "cord_ft": 10, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.iontechnologies.net/products/MHP25017'),
  ('MHP30019', '3/4 HP MightyFlex Submersible', 'MightyFlex', 4800, 15, false, 420, ARRAY['Digital ioSwitch','Heavy-duty motor','Cast iron construction','Premium performance'], '{"hp": 0.75, "gph_at_10ft": 4800, "head_ft": 32, "switch_type": "digital_ioswitch", "discharge": "1.5_inch", "cord_ft": 12, "material": "cast_iron", "phase": "single", "voltage": 115}', 'https://www.iontechnologies.net/products/MHP30019'),
  ('BA33i', '1/3 HP Genesis Submersible', 'Genesis', 2580, 12, false, 260, ARRAY['Stainless steel construction','Digital switch','Compact design','Lifetime warranty on switch'], '{"hp": 0.33, "gph_at_10ft": 2580, "head_ft": 22, "switch_type": "digital_ioswitch", "discharge": "1.5_inch", "cord_ft": 10, "material": "stainless_steel", "phase": "single", "voltage": 115}', 'https://www.iontechnologies.net/products/BA33i'),
  ('BA50i', '1/2 HP Genesis Submersible', 'Genesis', 3720, 12, false, 320, ARRAY['Stainless steel housing','Digital ioSwitch','High capacity','Premium motor'], '{"hp": 0.5, "gph_at_10ft": 3720, "head_ft": 26, "switch_type": "digital_ioswitch", "discharge": "1.5_inch", "cord_ft": 10, "material": "stainless_steel", "phase": "single", "voltage": 115}', 'https://www.iontechnologies.net/products/BA50i')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'ion-technologies' AND c.slug = 'sump-pump-submersible';


-- ======================== WATER COMMANDER ========================

-- Water Commander Battery Backup (water-powered)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'water_pressure', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('iW33', 'Water Commander iW33 Water-Powered Backup', 'iW', 1450, 20, false, 350, ARRAY['No battery needed','Water-powered backup','Continuous run time','No maintenance','Uses municipal water'], '{"hp": 0, "gph_at_10ft": 1450, "head_ft": 15, "switch_type": "float", "discharge": "1.5_inch", "power_source": "water_pressure", "min_psi": 40, "material": "thermoplastic", "voltage": 0}', 'https://www.watercommander.com/products/iw33'),
  ('iW55', 'Water Commander iW55 High-Output Water-Powered', 'iW', 1650, 20, false, 420, ARRAY['No battery needed','High-output water-powered','Continuous run time','No maintenance','Best for high-flow wells'], '{"hp": 0, "gph_at_10ft": 1650, "head_ft": 18, "switch_type": "float", "discharge": "1.5_inch", "power_source": "water_pressure", "min_psi": 40, "material": "thermoplastic", "voltage": 0}', 'https://www.watercommander.com/products/iw55'),
  ('MG22', 'Water Commander MG22 Standard', 'MG', 1200, 20, false, 280, ARRAY['Water-powered backup','No electricity needed','Unlimited runtime','Low maintenance'], '{"hp": 0, "gph_at_10ft": 1200, "head_ft": 12, "switch_type": "float", "discharge": "1.5_inch", "power_source": "water_pressure", "min_psi": 30, "material": "thermoplastic", "voltage": 0}', 'https://www.watercommander.com/products/mg22'),
  ('iW77', 'Water Commander iW77 Premium Water-Powered', 'iW', 1800, 20, false, 500, ARRAY['Premium water-powered','Highest output model','No battery needed','Continuous backup','Stainless components'], '{"hp": 0, "gph_at_10ft": 1800, "head_ft": 20, "switch_type": "float", "discharge": "1.5_inch", "power_source": "water_pressure", "min_psi": 45, "material": "thermoplastic", "voltage": 0}', 'https://www.watercommander.com/products/iw77')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'water-commander' AND c.slug = 'sump-pump-battery-backup';


-- ======================== BASEPUMP ========================

-- Basepump Battery Backup (water-powered)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'water_pressure', 'submersible', NULL, v.cap, 'gph', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('RB750', 'Basepump RB750 Water-Powered Backup', 'RB', 1320, 25, false, 300, ARRAY['Water-powered backup','No battery or electricity','Continuous runtime','Ejector design','Low maintenance'], '{"hp": 0, "gph_at_10ft": 1320, "head_ft": 14, "switch_type": "float", "discharge": "1.5_inch", "power_source": "water_pressure", "min_psi": 40, "material": "cast_bronze", "voltage": 0}', 'https://www.basepump.com/products/rb750'),
  ('RB750-EZ', 'Basepump RB750-EZ Easy Install', 'RB EZ', 1320, 25, false, 350, ARRAY['Easy install design','Water-powered','No battery needed','Continuous runtime','Check valve included'], '{"hp": 0, "gph_at_10ft": 1320, "head_ft": 14, "switch_type": "float", "discharge": "1.5_inch", "power_source": "water_pressure", "min_psi": 40, "material": "cast_bronze", "voltage": 0}', 'https://www.basepump.com/products/rb750-ez'),
  ('RB750-AVB', 'Basepump RB750-AVB w/ Anti-Siphon', 'RB AVB', 1320, 25, false, 380, ARRAY['Anti-siphon valve included','Water-powered backup','Code-compliant','Continuous runtime'], '{"hp": 0, "gph_at_10ft": 1320, "head_ft": 14, "switch_type": "float", "discharge": "1.5_inch", "power_source": "water_pressure", "min_psi": 40, "material": "cast_bronze", "voltage": 0, "anti_siphon": true}', 'https://www.basepump.com/products/rb750-avb'),
  ('CB1500', 'Basepump CB1500 High Volume', 'CB', 1500, 25, false, 400, ARRAY['High-volume water-powered','No battery needed','Premium ejector design','Heavy-duty construction'], '{"hp": 0, "gph_at_10ft": 1500, "head_ft": 16, "switch_type": "float", "discharge": "1.5_inch", "power_source": "water_pressure", "min_psi": 45, "material": "cast_bronze", "voltage": 0}', 'https://www.basepump.com/products/cb1500'),
  ('HB1000', 'Basepump HB1000 High-Back Pressure', 'HB', 1100, 25, false, 350, ARRAY['High back-pressure design','Water-powered','For long discharge runs','Heavy-duty construction'], '{"hp": 0, "gph_at_10ft": 1100, "head_ft": 20, "switch_type": "float", "discharge": "1.5_inch", "power_source": "water_pressure", "min_psi": 45, "material": "cast_bronze", "voltage": 0}', 'https://www.basepump.com/products/hb1000')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'basepump' AND c.slug = 'sump-pump-battery-backup';


-- ############################################################################
-- GENERATORS
-- ############################################################################

-- ======================== PREDATOR (Harbor Freight) ========================

-- Predator Portable Generators
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'portable', NULL, v.cap, 'watts', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, 'https://www.harborfreight.com/generators'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('57080', '9000W Predator Generator', 'Predator', 'gas', 9000, 10, 750, ARRAY['Electric start','420cc engine','8-gallon tank','GFCI outlets','Never-Flat wheels'], '{"watts_starting": 11250, "runtime_hours_50pct": 13, "noise_dba": 76, "fuel_tank_gallons": 8, "outlets": "4x120V 1x120/240V", "parallel_capable": false, "co_shutoff": false, "engine_cc": 420}'),
  ('56720', '4375W Predator Generator', 'Predator', 'gas', 4375, 10, 400, ARRAY['Recoil start','212cc engine','4-gallon tank','Compact design'], '{"watts_starting": 5500, "runtime_hours_50pct": 10, "noise_dba": 74, "fuel_tank_gallons": 4, "outlets": "2x120V 1x120/240V", "parallel_capable": false, "co_shutoff": false, "engine_cc": 212}'),
  ('63079', '3500W Predator Generator', 'Predator', 'gas', 3500, 10, 350, ARRAY['Recoil start','212cc engine','3.6-gallon tank','Portable'], '{"watts_starting": 4375, "runtime_hours_50pct": 9, "noise_dba": 73, "fuel_tank_gallons": 3.6, "outlets": "2x120V 1x120V-RV", "parallel_capable": false, "co_shutoff": false, "engine_cc": 212}'),
  ('57109', '6500W Predator Generator', 'Predator', 'gas', 6500, 10, 600, ARRAY['Electric start','420cc engine','6.5-gallon tank','Hour meter','Wheel kit'], '{"watts_starting": 8125, "runtime_hours_50pct": 11, "noise_dba": 75, "fuel_tank_gallons": 6.5, "outlets": "4x120V 1x120/240V", "parallel_capable": false, "co_shutoff": false, "engine_cc": 420}'),
  ('63080', '8750W Predator Generator', 'Predator', 'gas', 8750, 10, 700, ARRAY['Electric start','420cc engine','6.6-gallon tank','Heavy-duty frame'], '{"watts_starting": 11000, "runtime_hours_50pct": 12, "noise_dba": 76, "fuel_tank_gallons": 6.6, "outlets": "4x120V 1x120/240V", "parallel_capable": false, "co_shutoff": false, "engine_cc": 420}')
) AS v(model_number, model_name, series, fuel, cap, lifespan, msrp, features, specs)
WHERE m.slug = 'predator' AND c.slug = 'generator-portable';

-- Predator Inverter Generators
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'portable', NULL, v.cap, 'watts', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, 'https://www.harborfreight.com/generators'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('59137', '3500W Predator Inverter', 'Predator', 'gas', 3500, 12, 800, ARRAY['Inverter technology','Quiet operation','Electric start','Parallel capable','CO Secure shutoff'], '{"watts_starting": 4375, "runtime_hours_50pct": 11, "noise_dba": 57, "fuel_tank_gallons": 2.3, "outlets": "2x120V 1xUSB", "parallel_capable": true, "co_shutoff": true, "engine_cc": 212}'),
  ('59188', '2000W Predator Inverter', 'Predator', 'gas', 2000, 12, 450, ARRAY['Ultra-quiet inverter','Lightweight','Parallel capable','Eco throttle'], '{"watts_starting": 2500, "runtime_hours_50pct": 9.5, "noise_dba": 53, "fuel_tank_gallons": 1.05, "outlets": "2x120V 1xUSB", "parallel_capable": true, "co_shutoff": false, "engine_cc": 79.7}'),
  ('57102', '4550W Predator Inverter', 'Predator', 'gas', 4550, 12, 1100, ARRAY['Open-frame inverter','Electric start','GFCI outlets','CO Secure'], '{"watts_starting": 5700, "runtime_hours_50pct": 16, "noise_dba": 63, "fuel_tank_gallons": 3.4, "outlets": "2x120V 1x120/240V 1xUSB", "parallel_capable": true, "co_shutoff": true, "engine_cc": 224}')
) AS v(model_number, model_name, series, fuel, cap, lifespan, msrp, features, specs)
WHERE m.slug = 'predator' AND c.slug = 'generator-inverter';


-- ======================== PULSAR ========================

-- Pulsar Portable Generators (Dual-Fuel)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'portable', NULL, v.cap, 'watts', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, 'https://www.pulsarproducts.com/generators'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('PG12000B', '12000W Dual-Fuel Portable', 'PG', 'dual_fuel', 12000, 10, 1100, ARRAY['Dual-fuel gas/propane','Electric start','457cc engine','GFCI outlets','Wheel kit'], '{"watts_starting": 15000, "runtime_hours_50pct": 12, "noise_dba": 76, "fuel_tank_gallons": 8, "outlets": "4x120V 1x120/240V 1x30A-RV", "parallel_capable": false, "co_shutoff": false, "engine_cc": 457, "dual_fuel": true}'),
  ('PG10000B16', '10000W Dual-Fuel Portable', 'PG', 'dual_fuel', 10000, 10, 900, ARRAY['Dual-fuel gas/propane','Electric start','420cc engine','GFCI outlets'], '{"watts_starting": 12500, "runtime_hours_50pct": 11, "noise_dba": 75, "fuel_tank_gallons": 8, "outlets": "4x120V 1x120/240V", "parallel_capable": false, "co_shutoff": false, "engine_cc": 420, "dual_fuel": true}'),
  ('PG7750B', '7750W Dual-Fuel Portable', 'PG', 'dual_fuel', 7750, 10, 700, ARRAY['Dual-fuel gas/propane','Electric start','420cc engine','GFCI outlets'], '{"watts_starting": 9750, "runtime_hours_50pct": 10, "noise_dba": 74, "fuel_tank_gallons": 6.6, "outlets": "4x120V 1x120/240V", "parallel_capable": false, "co_shutoff": false, "engine_cc": 420, "dual_fuel": true}'),
  ('PG5250B', '5250W Dual-Fuel Portable', 'PG', 'dual_fuel', 5250, 10, 550, ARRAY['Dual-fuel gas/propane','Recoil start','224cc engine','Portable design'], '{"watts_starting": 6580, "runtime_hours_50pct": 9, "noise_dba": 73, "fuel_tank_gallons": 4, "outlets": "3x120V 1x120/240V", "parallel_capable": false, "co_shutoff": false, "engine_cc": 224, "dual_fuel": true}'),
  ('PG4000iSR', '4000W Dual-Fuel Inverter', 'PG Inverter', 'dual_fuel', 4000, 12, 650, ARRAY['Inverter technology','Dual-fuel','Remote start','Parallel capable','Quiet operation'], '{"watts_starting": 4500, "runtime_hours_50pct": 12, "noise_dba": 60, "fuel_tank_gallons": 2.2, "outlets": "2x120V 1xUSB", "parallel_capable": true, "co_shutoff": false, "engine_cc": 212, "dual_fuel": true}'),
  ('PG6580B', '6580W Dual-Fuel Portable', 'PG', 'dual_fuel', 6580, 10, 620, ARRAY['Dual-fuel gas/propane','Electric start','420cc engine','RV-ready'], '{"watts_starting": 8220, "runtime_hours_50pct": 10, "noise_dba": 74, "fuel_tank_gallons": 6, "outlets": "4x120V 1x120/240V 1x30A-RV", "parallel_capable": false, "co_shutoff": false, "engine_cc": 420, "dual_fuel": true}'),
  ('PG2300iS', '2300W Dual-Fuel Inverter', 'PG Inverter', 'dual_fuel', 2300, 12, 500, ARRAY['Compact inverter','Dual-fuel','Parallel capable','Super quiet','Economy mode'], '{"watts_starting": 2800, "runtime_hours_50pct": 10, "noise_dba": 55, "fuel_tank_gallons": 1.2, "outlets": "2x120V 1xUSB", "parallel_capable": true, "co_shutoff": false, "engine_cc": 113, "dual_fuel": true}')
) AS v(model_number, model_name, series, fuel, cap, lifespan, msrp, features, specs)
WHERE m.slug = 'pulsar' AND c.slug = 'generator-portable';


-- ======================== SPORTSMAN ========================

-- Sportsman Portable Generators
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'portable', NULL, v.cap, 'watts', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, 'https://www.sportsmanseries.com/generators'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('GEN9000DF', '9000W Dual-Fuel Generator', 'GEN', 'dual_fuel', 9000, 10, 750, ARRAY['Dual-fuel gas/propane','Electric start','457cc engine','Wheel kit','GFCI outlets'], '{"watts_starting": 11250, "runtime_hours_50pct": 12, "noise_dba": 75, "fuel_tank_gallons": 8, "outlets": "4x120V 1x120/240V", "parallel_capable": false, "co_shutoff": false, "engine_cc": 457, "dual_fuel": true}'),
  ('GEN7500DF', '7500W Dual-Fuel Generator', 'GEN', 'dual_fuel', 7500, 10, 650, ARRAY['Dual-fuel gas/propane','Electric start','420cc engine','Portable'], '{"watts_starting": 9375, "runtime_hours_50pct": 11, "noise_dba": 74, "fuel_tank_gallons": 6.6, "outlets": "4x120V 1x120/240V", "parallel_capable": false, "co_shutoff": false, "engine_cc": 420, "dual_fuel": true}'),
  ('GEN4000DF', '4000W Dual-Fuel Generator', 'GEN', 'dual_fuel', 4000, 10, 400, ARRAY['Dual-fuel gas/propane','Recoil start','210cc engine','Compact'], '{"watts_starting": 5000, "runtime_hours_50pct": 9, "noise_dba": 72, "fuel_tank_gallons": 3.6, "outlets": "3x120V", "parallel_capable": false, "co_shutoff": false, "engine_cc": 210, "dual_fuel": true}'),
  ('GEN2000I', '2000W Inverter Generator', 'GEN', 'gas', 2000, 12, 450, ARRAY['Inverter technology','Ultra-quiet','Parallel capable','Economy mode'], '{"watts_starting": 2500, "runtime_hours_50pct": 9, "noise_dba": 53, "fuel_tank_gallons": 1.1, "outlets": "2x120V 1xUSB", "parallel_capable": true, "co_shutoff": false, "engine_cc": 80}'),
  ('GEN1000I', '1000W Inverter Generator', 'GEN', 'gas', 1000, 12, 300, ARRAY['Super compact inverter','Ultra-quiet','Lightweight 29 lbs','Eco throttle'], '{"watts_starting": 1200, "runtime_hours_50pct": 7, "noise_dba": 50, "fuel_tank_gallons": 0.7, "outlets": "1x120V 1xUSB", "parallel_capable": true, "co_shutoff": false, "engine_cc": 40}'),
  ('GEN4000', '4000W Gasoline Generator', 'GEN', 'gas', 4000, 10, 350, ARRAY['Recoil start','212cc engine','3.6-gallon tank','EPA/CARB compliant'], '{"watts_starting": 5000, "runtime_hours_50pct": 9, "noise_dba": 72, "fuel_tank_gallons": 3.6, "outlets": "3x120V 1x120/240V", "parallel_capable": false, "co_shutoff": false, "engine_cc": 212}'),
  ('GEN10000DF', '10000W Dual-Fuel Generator', 'GEN', 'dual_fuel', 10000, 10, 900, ARRAY['Dual-fuel gas/propane','Electric start','457cc engine','Wheel kit','Hour meter'], '{"watts_starting": 12500, "runtime_hours_50pct": 12, "noise_dba": 76, "fuel_tank_gallons": 8, "outlets": "4x120V 1x120/240V 1x30A-RV", "parallel_capable": false, "co_shutoff": false, "engine_cc": 457, "dual_fuel": true}')
) AS v(model_number, model_name, series, fuel, cap, lifespan, msrp, features, specs)
WHERE m.slug = 'sportsman' AND c.slug = 'generator-portable';


-- ======================== CRAFTSMAN ========================

-- Craftsman Portable Generators
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'portable', NULL, v.cap, 'watts', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, 'https://www.craftsman.com/generators'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('CMXGGAS030791', '8000W Craftsman Portable', 'CMXG', 'gas', 8000, 10, 950, ARRAY['Electric start','420cc engine','7.5-gallon tank','GFCI outlets','CO Guard shutoff'], '{"watts_starting": 10000, "runtime_hours_50pct": 12, "noise_dba": 75, "fuel_tank_gallons": 7.5, "outlets": "4x120V GFCI 1x120/240V", "parallel_capable": false, "co_shutoff": true, "engine_cc": 420}'),
  ('CMXGGAS030733', '5700W Craftsman Portable', 'CMXG', 'gas', 5700, 10, 750, ARRAY['Electric start','306cc engine','5-gallon tank','GFCI outlets'], '{"watts_starting": 7200, "runtime_hours_50pct": 10, "noise_dba": 74, "fuel_tank_gallons": 5, "outlets": "4x120V 1x120/240V", "parallel_capable": false, "co_shutoff": true, "engine_cc": 306}'),
  ('CMXGGAS030729', '3500W Craftsman Portable', 'CMXG', 'gas', 3500, 10, 500, ARRAY['Recoil start','212cc engine','4-gallon tank','Portable design'], '{"watts_starting": 4375, "runtime_hours_50pct": 9, "noise_dba": 72, "fuel_tank_gallons": 4, "outlets": "3x120V", "parallel_capable": false, "co_shutoff": false, "engine_cc": 212}'),
  ('CMXGGAS030799', '6500W Craftsman Portable', 'CMXG', 'gas', 6500, 10, 850, ARRAY['Electric start','420cc engine','6.5-gallon tank','GFCI outlets','CO Guard'], '{"watts_starting": 8125, "runtime_hours_50pct": 11, "noise_dba": 74, "fuel_tank_gallons": 6.5, "outlets": "4x120V GFCI 1x120/240V", "parallel_capable": false, "co_shutoff": true, "engine_cc": 420}'),
  ('CMXGGAS030735', '4375W Craftsman Portable', 'CMXG', 'gas', 4375, 10, 600, ARRAY['Recoil start','224cc engine','4-gallon tank','GFCI outlets'], '{"watts_starting": 5500, "runtime_hours_50pct": 10, "noise_dba": 73, "fuel_tank_gallons": 4, "outlets": "3x120V GFCI", "parallel_capable": false, "co_shutoff": false, "engine_cc": 224}')
) AS v(model_number, model_name, series, fuel, cap, lifespan, msrp, features, specs)
WHERE m.slug = 'craftsman' AND c.slug = 'generator-portable';

-- Craftsman Inverter Generators
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'portable', NULL, v.cap, 'watts', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, 'https://www.craftsman.com/generators'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('CMXGIAC3000', '3000W Craftsman Inverter', 'CMXG', 'gas', 3000, 12, 800, ARRAY['Inverter technology','Electric start','Quiet operation','Parallel capable','CO Guard'], '{"watts_starting": 3500, "runtime_hours_50pct": 12, "noise_dba": 58, "fuel_tank_gallons": 1.8, "outlets": "2x120V 1xUSB", "parallel_capable": true, "co_shutoff": true, "engine_cc": 150}'),
  ('CMXGIAC2200', '2200W Craftsman Inverter', 'CMXG', 'gas', 2200, 12, 550, ARRAY['Compact inverter','Economy mode','Parallel capable','Clean power'], '{"watts_starting": 2500, "runtime_hours_50pct": 10, "noise_dba": 54, "fuel_tank_gallons": 1.2, "outlets": "2x120V 1xUSB", "parallel_capable": true, "co_shutoff": false, "engine_cc": 79.7}')
) AS v(model_number, model_name, series, fuel, cap, lifespan, msrp, features, specs)
WHERE m.slug = 'craftsman' AND c.slug = 'generator-inverter';


-- ======================== RYOBI ========================

-- Ryobi Inverter Generators
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'portable', NULL, v.cap, 'watts', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, 'https://www.ryobitools.com/generators'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('RYi4022X', '4000W Ryobi Inverter', 'RYi', 'gas', 4000, 12, 1100, ARRAY['Open-frame inverter','Electric start','CO Detect shutoff','Bluetooth monitoring','GFCI outlets'], '{"watts_starting": 4500, "runtime_hours_50pct": 14, "noise_dba": 62, "fuel_tank_gallons": 3.4, "outlets": "2x120V GFCI 1x120/240V 1xUSB", "parallel_capable": true, "co_shutoff": true, "engine_cc": 212}'),
  ('RYi2322VNM', '2300W Ryobi Inverter', 'RYi', 'gas', 2300, 12, 650, ARRAY['Inverter technology','Bluetooth','Recoil start','Parallel capable','Economy mode'], '{"watts_starting": 2900, "runtime_hours_50pct": 10.3, "noise_dba": 57, "fuel_tank_gallons": 1.2, "outlets": "2x120V 1xUSB", "parallel_capable": true, "co_shutoff": false, "engine_cc": 89}'),
  ('RYi1802BT', '1800W Ryobi Inverter', 'RYi', 'gas', 1800, 12, 450, ARRAY['Ultra-quiet inverter','Bluetooth monitoring','Parallel capable','Compact'], '{"watts_starting": 2200, "runtime_hours_50pct": 9, "noise_dba": 52, "fuel_tank_gallons": 0.95, "outlets": "2x120V 1xUSB", "parallel_capable": true, "co_shutoff": false, "engine_cc": 65}'),
  ('RYi6500VR', '6500W Ryobi Inverter', 'RYi', 'gas', 6500, 12, 1600, ARRAY['High-output inverter','Electric start','CO Detect shutoff','Bluetooth','Idle control'], '{"watts_starting": 8125, "runtime_hours_50pct": 12, "noise_dba": 66, "fuel_tank_gallons": 5, "outlets": "4x120V GFCI 1x120/240V 2xUSB", "parallel_capable": false, "co_shutoff": true, "engine_cc": 357}'),
  ('RYi300BG', '300W Ryobi Battery Inverter', 'RYi', 'battery', 300, 10, 200, ARRAY['40V battery powered','Zero emissions','Ultra-quiet','Pure sine wave','USB-C'], '{"watts_starting": 600, "runtime_hours_50pct": 2, "noise_dba": 40, "fuel_tank_gallons": 0, "outlets": "1x120V 2xUSB", "parallel_capable": false, "co_shutoff": false, "battery_platform": "40V"}')
) AS v(model_number, model_name, series, fuel, cap, lifespan, msrp, features, specs)
WHERE m.slug = 'ryobi' AND c.slug = 'generator-inverter';


-- ======================== CATERPILLAR ========================

-- CAT Portable Generators
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'portable', NULL, v.cap, 'watts', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, 'https://www.cat.com/en_US/products/new/power-systems/electric-power/portable-generator-sets.html'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('RP12000E', '12000W CAT Portable Generator', 'RP', 'gas', 12000, 15, 1900, ARRAY['Electric start','670cc engine','10-gallon tank','Fold-down handles','Heavy-duty frame'], '{"watts_starting": 15000, "runtime_hours_50pct": 13, "noise_dba": 76, "fuel_tank_gallons": 10, "outlets": "4x120V GFCI 1x120/240V 1x30A-RV", "parallel_capable": false, "co_shutoff": false, "engine_cc": 670}'),
  ('RP7500E', '7500W CAT Portable Generator', 'RP', 'gas', 7500, 15, 1200, ARRAY['Electric start','420cc engine','7.9-gallon tank','GFCI outlets','Hour meter'], '{"watts_starting": 9375, "runtime_hours_50pct": 12, "noise_dba": 74, "fuel_tank_gallons": 7.9, "outlets": "4x120V GFCI 1x120/240V", "parallel_capable": false, "co_shutoff": false, "engine_cc": 420}'),
  ('RP6500E', '6500W CAT Portable Generator', 'RP', 'gas', 6500, 15, 1000, ARRAY['Electric start','420cc engine','6.5-gallon tank','GFCI outlets'], '{"watts_starting": 8125, "runtime_hours_50pct": 11, "noise_dba": 74, "fuel_tank_gallons": 6.5, "outlets": "4x120V GFCI 1x120/240V", "parallel_capable": false, "co_shutoff": false, "engine_cc": 420}'),
  ('RP3600', '3600W CAT Portable Generator', 'RP', 'gas', 3600, 15, 600, ARRAY['Recoil start','208cc engine','3.4-gallon tank','Compact design'], '{"watts_starting": 4500, "runtime_hours_50pct": 9, "noise_dba": 72, "fuel_tank_gallons": 3.4, "outlets": "3x120V", "parallel_capable": false, "co_shutoff": false, "engine_cc": 208}')
) AS v(model_number, model_name, series, fuel, cap, lifespan, msrp, features, specs)
WHERE m.slug = 'caterpillar' AND c.slug = 'generator-portable';

-- CAT Inverter Generators
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'portable', NULL, v.cap, 'watts', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, 'https://www.cat.com/en_US/products/new/power-systems/electric-power/portable-generator-sets.html'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('INV4000E', '4000W CAT Inverter Generator', 'INV', 'gas', 4000, 15, 1400, ARRAY['Open-frame inverter','Electric start','CO Detect shutoff','Parallel capable','GFCI outlets'], '{"watts_starting": 5000, "runtime_hours_50pct": 14, "noise_dba": 64, "fuel_tank_gallons": 3.4, "outlets": "2x120V GFCI 1x120/240V 2xUSB", "parallel_capable": true, "co_shutoff": true, "engine_cc": 212}'),
  ('INV2250', '2250W CAT Inverter Generator', 'INV', 'gas', 2250, 15, 750, ARRAY['Quiet inverter','Recoil start','Parallel capable','Clean power','Economy mode'], '{"watts_starting": 2750, "runtime_hours_50pct": 10, "noise_dba": 56, "fuel_tank_gallons": 1.2, "outlets": "2x120V 1xUSB", "parallel_capable": true, "co_shutoff": false, "engine_cc": 79.7}'),
  ('INV1250', '1250W CAT Inverter Generator', 'INV', 'gas', 1250, 15, 500, ARRAY['Ultra-compact inverter','Super quiet','Lightweight','Pure sine wave'], '{"watts_starting": 1500, "runtime_hours_50pct": 8, "noise_dba": 51, "fuel_tank_gallons": 0.8, "outlets": "1x120V 1xUSB", "parallel_capable": true, "co_shutoff": false, "engine_cc": 53}')
) AS v(model_number, model_name, series, fuel, cap, lifespan, msrp, features, specs)
WHERE m.slug = 'caterpillar' AND c.slug = 'generator-inverter';


-- ############################################################################
-- WATER HEATERS
-- ############################################################################

-- ======================== AMERICAN WATER HEATERS ========================

-- American Water Heaters - Tank Gas
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.americanwaterheater.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('G61-40T40-3NV', '40 Gal Tall Natural Gas', 'Standard', 'gas', 'tank', 40, 'gallons', 10, false, false, 479, ARRAY['40,000 BTU','Piezo ignition','Glass-lined tank','6-year warranty'], '{"gallons": 40, "uef": 0.59, "first_hour_rating": 60, "recovery_rate_gph": 40, "btu_input": 40000}'),
  ('G61-50T40-3NV', '50 Gal Tall Natural Gas', 'Standard', 'gas', 'tank', 50, 'gallons', 12, false, false, 529, ARRAY['40,000 BTU','Glass-lined tank','Magnesium anode rod','T&P valve'], '{"gallons": 50, "uef": 0.60, "first_hour_rating": 67, "recovery_rate_gph": 43, "btu_input": 40000}'),
  ('G62-75T75-4NV', '75 Gal Tall Natural Gas', 'Standard', 'gas', 'tank', 75, 'gallons', 12, false, false, 899, ARRAY['75,100 BTU','High capacity','Power vent ready','Heavy-duty anode'], '{"gallons": 75, "uef": 0.65, "first_hour_rating": 96, "recovery_rate_gph": 72, "btu_input": 75100}'),
  ('G62-40S40-3NV', '40 Gal Short Natural Gas', 'Standard', 'gas', 'tank', 40, 'gallons', 10, false, false, 469, ARRAY['40,000 BTU','Short/low-boy design','For tight spaces','Glass-lined'], '{"gallons": 40, "uef": 0.58, "first_hour_rating": 57, "recovery_rate_gph": 40, "btu_input": 40000}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'american-water-heaters' AND c.slug = 'water-heater-tank-gas';

-- American Water Heaters - Tank Electric
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.americanwaterheater.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('E61-40R-045DV', '40 Gal Tall Electric', 'Standard', 'electric', 'tank', 40, 'gallons', 10, false, false, 389, ARRAY['4,500W elements','Dual heating elements','Glass-lined tank','6-year warranty'], '{"gallons": 40, "uef": 0.93, "first_hour_rating": 55, "watts": 4500}'),
  ('E61-50R-045DV', '50 Gal Tall Electric', 'Standard', 'electric', 'tank', 50, 'gallons', 12, false, false, 419, ARRAY['4,500W elements','Self-cleaning dip tube','Magnesium anode rod'], '{"gallons": 50, "uef": 0.93, "first_hour_rating": 62, "watts": 4500}'),
  ('E62-80H-045DV', '80 Gal Tall Electric', 'Standard', 'electric', 'tank', 80, 'gallons', 12, false, false, 599, ARRAY['4,500W elements','Large capacity','Heavy-duty anode rod','Non-CFC foam'], '{"gallons": 80, "uef": 0.90, "first_hour_rating": 86, "watts": 4500}'),
  ('E61-30R-045DV', '30 Gal Tall Electric', 'Standard', 'electric', 'tank', 30, 'gallons', 10, false, false, 369, ARRAY['4,500W elements','Compact design','Glass-lined tank'], '{"gallons": 30, "uef": 0.93, "first_hour_rating": 46, "watts": 4500}'),
  ('E61-50H-045DV', '50 Gal Short Electric', 'Standard', 'electric', 'tank', 50, 'gallons', 12, false, false, 409, ARRAY['4,500W elements','Low-boy design','For tight spaces','Glass-lined'], '{"gallons": 50, "uef": 0.90, "first_hour_rating": 58, "watts": 4500}'),
  ('E62-40H-045DV', '40 Gal Lowboy Electric', 'Standard', 'electric', 'tank', 40, 'gallons', 10, false, false, 399, ARRAY['4,500W elements','Low-boy design','Under-counter install','Glass-lined tank'], '{"gallons": 40, "uef": 0.90, "first_hour_rating": 51, "watts": 4500}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'american-water-heaters' AND c.slug = 'water-heater-tank-electric';


-- ======================== KENMORE ========================

-- Kenmore Tank Gas
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.kenmore.com/water-heaters'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('33136', '40 Gal Tall Natural Gas 6-Year', 'Kenmore', 'gas', 'tank', 40, 'gallons', 10, false, false, 549, ARRAY['40,000 BTU','Self-cleaning dip tube','6-year warranty','Glass-lined tank'], '{"gallons": 40, "uef": 0.60, "first_hour_rating": 60, "recovery_rate_gph": 40, "btu_input": 40000}'),
  ('33156', '50 Gal Tall Natural Gas 6-Year', 'Kenmore', 'gas', 'tank', 50, 'gallons', 12, false, false, 599, ARRAY['40,000 BTU','Glass-lined tank','6-year warranty','Magnesium anode'], '{"gallons": 50, "uef": 0.60, "first_hour_rating": 67, "recovery_rate_gph": 43, "btu_input": 40000}'),
  ('33162', '50 Gal Tall Natural Gas 12-Year', 'Kenmore Elite', 'gas', 'tank', 50, 'gallons', 12, false, false, 799, ARRAY['40,000 BTU','Premium anode rod','12-year warranty','Non-CFC foam'], '{"gallons": 50, "uef": 0.62, "first_hour_rating": 70, "recovery_rate_gph": 43, "btu_input": 40000}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'kenmore' AND c.slug = 'water-heater-tank-gas';

-- Kenmore Tank Electric
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.kenmore.com/water-heaters'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('32646', '40 Gal Tall Electric 6-Year', 'Kenmore', 'electric', 'tank', 40, 'gallons', 10, false, false, 429, ARRAY['4,500W elements','Glass-lined tank','6-year warranty','Dual elements'], '{"gallons": 40, "uef": 0.93, "first_hour_rating": 55, "watts": 4500}'),
  ('32656', '50 Gal Tall Electric 6-Year', 'Kenmore', 'electric', 'tank', 50, 'gallons', 12, false, false, 459, ARRAY['4,500W elements','Self-cleaning dip tube','6-year warranty'], '{"gallons": 50, "uef": 0.93, "first_hour_rating": 62, "watts": 4500}'),
  ('32666', '50 Gal Tall Electric 12-Year', 'Kenmore Elite', 'electric', 'tank', 50, 'gallons', 12, false, false, 599, ARRAY['4,500W elements','12-year warranty','Premium anode rod','Brass drain valve'], '{"gallons": 50, "uef": 0.95, "first_hour_rating": 65, "watts": 4500}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'kenmore' AND c.slug = 'water-heater-tank-electric';

-- Kenmore Heat Pump
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.kenmore.com/water-heaters'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('32950', '50 Gal Heat Pump Water Heater', 'Kenmore Elite', 'electric', 'tank', 50, 'gallons', 15, true, true, 1299, ARRAY['Heat pump technology','UEF 3.35','Energy Star','4 operating modes','Built-in Wi-Fi'], '{"gallons": 50, "uef": 3.35, "first_hour_rating": 66, "watts": 4500, "heat_pump_btu": 4200, "modes": ["heat_pump_only", "hybrid", "electric_only", "vacation"]}'),
  ('32980', '80 Gal Heat Pump Water Heater', 'Kenmore Elite', 'electric', 'tank', 80, 'gallons', 15, true, true, 1599, ARRAY['Heat pump technology','UEF 3.35','Energy Star','Large capacity','Built-in Wi-Fi'], '{"gallons": 80, "uef": 3.35, "first_hour_rating": 87, "watts": 4500, "heat_pump_btu": 4200, "modes": ["heat_pump_only", "hybrid", "electric_only", "vacation"]}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'kenmore' AND c.slug = 'water-heater-heat-pump';


-- ======================== SUPERSTOR ========================

-- SuperStor Indirect Water Heaters (heated by boiler)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.htproducts.com/superstor'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('SSU-45', '45 Gal Contender Indirect', 'Contender', 'gas', 'indirect', 45, 'gallons', 25, false, false, 1200, ARRAY['Stainless steel tank','Heated by boiler','No flue needed','Long lasting','AquaLogic heat exchanger'], '{"gallons": 45, "recovery_rate_btu": 100000, "heat_exchanger_sqft": 6.5, "material": "stainless_steel", "connections": "1_inch_npt"}'),
  ('SSU-60', '60 Gal Contender Indirect', 'Contender', 'gas', 'indirect', 60, 'gallons', 25, false, false, 1400, ARRAY['Stainless steel tank','Heated by boiler','High recovery rate','AquaLogic heat exchanger'], '{"gallons": 60, "recovery_rate_btu": 120000, "heat_exchanger_sqft": 8, "material": "stainless_steel", "connections": "1_inch_npt"}'),
  ('SSU-80', '80 Gal Contender Indirect', 'Contender', 'gas', 'indirect', 80, 'gallons', 25, false, false, 1700, ARRAY['Stainless steel tank','Large capacity','Heated by boiler','Premium heat exchanger'], '{"gallons": 80, "recovery_rate_btu": 140000, "heat_exchanger_sqft": 9.5, "material": "stainless_steel", "connections": "1_inch_npt"}'),
  ('SSU-30', '30 Gal Contender Indirect', 'Contender', 'gas', 'indirect', 30, 'gallons', 25, false, false, 1000, ARRAY['Stainless steel tank','Compact design','Heated by boiler','For small homes'], '{"gallons": 30, "recovery_rate_btu": 80000, "heat_exchanger_sqft": 5, "material": "stainless_steel", "connections": "1_inch_npt"}'),
  ('SSC-45', '45 Gal Ultra Indirect', 'Ultra', 'gas', 'indirect', 45, 'gallons', 30, false, false, 1800, ARRAY['Super-insulated','Triple-wall tank','Lifetime warranty','Heated by boiler'], '{"gallons": 45, "recovery_rate_btu": 120000, "heat_exchanger_sqft": 8, "material": "stainless_steel", "insulation": "triple_wall", "connections": "1.25_inch_npt"}'),
  ('SSC-60', '60 Gal Ultra Indirect', 'Ultra', 'gas', 'indirect', 60, 'gallons', 30, false, false, 2100, ARRAY['Super-insulated','Triple-wall tank','Lifetime warranty','Premium recovery'], '{"gallons": 60, "recovery_rate_btu": 140000, "heat_exchanger_sqft": 9.5, "material": "stainless_steel", "insulation": "triple_wall", "connections": "1.25_inch_npt"}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'superstor' AND c.slug = 'water-heater-tank-gas';


-- ======================== VAUGHN ========================

-- Vaughn Indirect Water Heaters (stone-lined)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.vaughncorp.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('S-40', '40 Gal Stone-Lined Indirect', 'Hydrastone', 'gas', 'indirect', 40, 'gallons', 30, false, false, 1600, ARRAY['Stone-lined tank','30+ year lifespan','Heated by boiler','Anti-corrosion design','Copper coil heat exchanger'], '{"gallons": 40, "recovery_rate_btu": 100000, "heat_exchanger": "copper_coil", "material": "stone_lined_steel", "connections": "1_inch_npt"}'),
  ('S-60', '60 Gal Stone-Lined Indirect', 'Hydrastone', 'gas', 'indirect', 60, 'gallons', 30, false, false, 2000, ARRAY['Stone-lined tank','Extreme longevity','Heated by boiler','Copper coil heat exchanger','No anode rod needed'], '{"gallons": 60, "recovery_rate_btu": 120000, "heat_exchanger": "copper_coil", "material": "stone_lined_steel", "connections": "1_inch_npt"}'),
  ('S-80', '80 Gal Stone-Lined Indirect', 'Hydrastone', 'gas', 'indirect', 80, 'gallons', 30, false, false, 2500, ARRAY['Stone-lined tank','30+ year lifespan','High capacity','Copper coil heat exchanger','Premium insulation'], '{"gallons": 80, "recovery_rate_btu": 140000, "heat_exchanger": "copper_coil", "material": "stone_lined_steel", "connections": "1_inch_npt"}'),
  ('S-120', '120 Gal Stone-Lined Indirect', 'Hydrastone', 'gas', 'indirect', 120, 'gallons', 30, false, false, 3200, ARRAY['Stone-lined tank','Extra-large capacity','For large homes','Copper coil heat exchanger'], '{"gallons": 120, "recovery_rate_btu": 160000, "heat_exchanger": "copper_coil", "material": "stone_lined_steel", "connections": "1.25_inch_npt"}'),
  ('TOP-40', '40 Gal Top-Connect Indirect', 'Top-Connect', 'gas', 'indirect', 40, 'gallons', 30, false, false, 1800, ARRAY['Top connections only','Stone-lined tank','Easy installation','Heated by boiler'], '{"gallons": 40, "recovery_rate_btu": 100000, "heat_exchanger": "copper_coil", "material": "stone_lined_steel", "connections": "top_only"}'),
  ('TOP-60', '60 Gal Top-Connect Indirect', 'Top-Connect', 'gas', 'indirect', 60, 'gallons', 30, false, false, 2200, ARRAY['Top connections only','Stone-lined tank','Large capacity','Heated by boiler'], '{"gallons": 60, "recovery_rate_btu": 120000, "heat_exchanger": "copper_coil", "material": "stone_lined_steel", "connections": "top_only"}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'vaughn' AND c.slug = 'water-heater-tank-gas';


-- ======================== SANCO2 ========================

-- SANCO2 CO2 Heat Pump Water Heaters
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.sancosystems.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('GS3-45HPA-US', '43 Gal SANCO2 Heat Pump', 'SANCO2', 'electric', 'split_system', 43, 'gallons', 15, false, true, 3500, ARRAY['CO2 refrigerant (R-744)','COP up to 5.0','Works in -15F weather','Split system design','Natural refrigerant'], '{"gallons": 43, "uef": 3.84, "cop": 5.0, "refrigerant": "R-744_CO2", "outdoor_unit_btu": 4500, "min_ambient_f": -15, "max_water_temp_f": 175}'),
  ('GS3-83HPA-US', '83 Gal SANCO2 Heat Pump', 'SANCO2', 'electric', 'split_system', 83, 'gallons', 15, false, true, 4200, ARRAY['CO2 refrigerant (R-744)','COP up to 5.0','Works in -15F weather','Large capacity','No backup element needed'], '{"gallons": 83, "uef": 3.84, "cop": 5.0, "refrigerant": "R-744_CO2", "outdoor_unit_btu": 4500, "min_ambient_f": -15, "max_water_temp_f": 175}'),
  ('GS3-119HPA-US', '119 Gal SANCO2 Heat Pump', 'SANCO2', 'electric', 'split_system', 119, 'gallons', 15, false, true, 5000, ARRAY['CO2 refrigerant','Largest residential model','COP up to 5.0','Works in extreme cold','For large families'], '{"gallons": 119, "uef": 3.84, "cop": 5.0, "refrigerant": "R-744_CO2", "outdoor_unit_btu": 4500, "min_ambient_f": -15, "max_water_temp_f": 175}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'sanco2' AND c.slug = 'water-heater-heat-pump';


-- ############################################################################
-- LAUNDRY — MAGIC CHEF
-- ############################################################################

-- Magic Chef Front-Load Washers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.magicchef.com/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('MCSFLW27W', '2.7 cu ft Front-Load Washer', NULL, 'electric', 24, 2.7, 10, false, false, 750, ARRAY['Compact 24-inch','Ventless ready','Stackable','6 wash cycles','LED display'], '{"spin_speed_rpm": 1200, "cycles": 6, "steam": false, "load_type": "front", "noise_dba": 54}'),
  ('MCSCWD27W5', '2.7 cu ft Combo Washer-Dryer', NULL, 'electric', 24, 2.7, 10, false, false, 1100, ARRAY['Combo washer-dryer','Ventless condensing dryer','24-inch compact','Auto dry sensor'], '{"spin_speed_rpm": 1200, "cycles": 6, "steam": false, "load_type": "front", "noise_dba": 56, "dryer_type": "ventless_condenser"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'magic-chef' AND c.slug = 'washer-front-load';

-- Magic Chef Compact Washers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.magicchef.com/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('MCSTCW16S4', '1.6 cu ft Portable Top-Load Washer', NULL, 'electric', 18, 1.6, 8, false, false, 350, ARRAY['Portable design','No hookup needed','3 water levels','6 cycles','Apartment-friendly'], '{"spin_speed_rpm": 800, "cycles": 6, "steam": false, "load_type": "top", "noise_dba": 52, "portable": true}'),
  ('MCSTCW30W6', '3.0 cu ft Portable Top-Load Washer', NULL, 'electric', 20, 3.0, 8, false, false, 450, ARRAY['Portable top-load','Large for compact class','Stainless tub','6 wash cycles'], '{"spin_speed_rpm": 850, "cycles": 6, "steam": false, "load_type": "top", "noise_dba": 54, "portable": true}'),
  ('MCSTCW09W1', '0.9 cu ft Mini Portable Washer', NULL, 'electric', 15, 0.9, 7, false, false, 250, ARRAY['Ultra-compact','Ideal for dorms/RVs','Lightweight','5 wash cycles'], '{"spin_speed_rpm": 600, "cycles": 5, "steam": false, "load_type": "top", "noise_dba": 50, "portable": true}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'magic-chef' AND c.slug = 'washer-compact';

-- Magic Chef Compact Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.magicchef.com/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('MCSDRY35W', '3.5 cu ft Compact Electric Dryer', NULL, 'electric', 24, 3.5, 10, false, false, 550, ARRAY['Compact 24-inch','Stackable','Stainless drum','4 drying programs','Lint filter alert'], '{"cycles": 4, "steam": false, "moisture_sensor": true, "vent_type": "vented"}'),
  ('MCSDRY15W', '1.5 cu ft Portable Dryer', NULL, 'electric', 20, 1.5, 8, false, false, 350, ARRAY['Portable design','No permanent venting','3 heat settings','Lightweight'], '{"cycles": 3, "steam": false, "moisture_sensor": false, "vent_type": "portable_vent"}'),
  ('MCPMSD24WW', '2.6 cu ft Ventless Compact Dryer', NULL, 'electric', 24, 2.6, 10, false, false, 650, ARRAY['Ventless condenser','24-inch compact','Stackable','No external vent needed','7 drying programs'], '{"cycles": 7, "steam": false, "moisture_sensor": true, "vent_type": "ventless_condenser"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'magic-chef' AND c.slug = 'dryer-compact';


-- ############################################################################
-- IRRIGATION — NETAFIM (Drip Irrigation)
-- ############################################################################

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('TLDL-06-12', 'TechLine DL 0.6 GPH 12-inch', 'TechLine DL', 'subsurface', NULL, NULL, 10, 25, ARRAY['Pressure compensating','Anti-siphon','Self-flushing','Root intrusion barrier','Subsurface drip'], '{"flow_rate_gph": 0.6, "emitter_spacing_inches": 12, "pressure_range_psi": "10-50", "max_run_ft": 600, "tubing_od_inches": 0.63}', 'https://www.netafim.com/en/products/techline-dl/'),
  ('TLDL-04-18', 'TechLine DL 0.4 GPH 18-inch', 'TechLine DL', 'subsurface', NULL, NULL, 10, 22, ARRAY['Low-flow pressure compensating','Anti-siphon','Self-flushing','Root intrusion barrier'], '{"flow_rate_gph": 0.4, "emitter_spacing_inches": 18, "pressure_range_psi": "10-50", "max_run_ft": 900, "tubing_od_inches": 0.63}', 'https://www.netafim.com/en/products/techline-dl/'),
  ('TLCV-06-12', 'TechLine CV 0.6 GPH 12-inch', 'TechLine CV', 'subsurface', NULL, NULL, 10, 30, ARRAY['Check valve technology','Anti-drain','Pressure compensating','Prevents low-point drainage'], '{"flow_rate_gph": 0.6, "emitter_spacing_inches": 12, "pressure_range_psi": "7-60", "max_run_ft": 550, "tubing_od_inches": 0.63, "check_valve": true}', 'https://www.netafim.com/en/products/techline-cv/'),
  ('TLCV-09-12', 'TechLine CV 0.9 GPH 12-inch', 'TechLine CV', 'subsurface', NULL, NULL, 10, 30, ARRAY['Check valve technology','High flow rate','Pressure compensating','Anti-drain design'], '{"flow_rate_gph": 0.9, "emitter_spacing_inches": 12, "pressure_range_psi": "7-60", "max_run_ft": 400, "tubing_od_inches": 0.63, "check_valve": true}', 'https://www.netafim.com/en/products/techline-cv/'),
  ('UNIRAM-06-12', 'UniRam 0.6 GPH 12-inch', 'UniRam', 'subsurface', NULL, NULL, 12, 35, ARRAY['Heavy-wall dripper line','Pressure compensating','Anti-siphon','Commercial grade','Long run lengths'], '{"flow_rate_gph": 0.6, "emitter_spacing_inches": 12, "pressure_range_psi": "7-60", "max_run_ft": 750, "tubing_od_inches": 0.67, "wall_thickness_mil": 30}', 'https://www.netafim.com/en/products/uniram/'),
  ('UNIRAM-04-18', 'UniRam 0.4 GPH 18-inch', 'UniRam', 'subsurface', NULL, NULL, 12, 32, ARRAY['Heavy-wall dripper line','Low flow','Pressure compensating','Anti-siphon','Extra-long runs'], '{"flow_rate_gph": 0.4, "emitter_spacing_inches": 18, "pressure_range_psi": "7-60", "max_run_ft": 1100, "tubing_od_inches": 0.67, "wall_thickness_mil": 30}', 'https://www.netafim.com/en/products/uniram/'),
  ('PC-CNL-2', 'PC Dripper 0.5 GPH Button', 'PC Dripper', 'surface', NULL, NULL, 8, 3, ARRAY['Pressure compensating on-line dripper','Flag-type design','Easy installation','Removable for cleaning'], '{"flow_rate_gph": 0.5, "pressure_range_psi": "7-50", "dripper_type": "button_on_line", "color_coded": true}', 'https://www.netafim.com/en/products/pc-dripper/'),
  ('PC-CNL-8', 'PC Dripper 2.0 GPH Button', 'PC Dripper', 'surface', NULL, NULL, 8, 3, ARRAY['High-flow button dripper','Pressure compensating','Color coded','Easy maintenance'], '{"flow_rate_gph": 2.0, "pressure_range_psi": "7-50", "dripper_type": "button_on_line", "color_coded": true}', 'https://www.netafim.com/en/products/pc-dripper/')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'netafim' AND c.slug = 'sprinkler-head';


-- ############################################################################
-- BATHROOM — ROHL
-- ############################################################################

-- Rohl Bathroom Faucets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('A1408LMPN-2', 'Acqui Single-Hole Faucet Polished Nickel', 'Acqui', 'deck-mount', 1.2, 'gpm', 20, 550, ARRAY['Italian design','Porcelain lever handle','Polished nickel','WaterSense certified'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "polished_nickel", "pop_up_drain": true}', 'https://www.rohlhome.com/products/acqui-single-hole-lav-faucet'),
  ('A1409LMAPC-2', 'Acqui Widespread Faucet Polished Chrome', 'Acqui', 'deck-mount', 1.2, 'gpm', 20, 850, ARRAY['Italian design','Widespread 8-inch','Porcelain lever handles','Chrome finish'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "polished_chrome", "spread": "8_inch"}', 'https://www.rohlhome.com/products/acqui-widespread-lav-faucet'),
  ('U.3720L-STN-2', 'Perrin & Rowe Georgian Era Widespread', 'Perrin & Rowe', 'deck-mount', 1.2, 'gpm', 25, 1100, ARRAY['English heritage design','Lever handles','Satin nickel','Lifetime warranty'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "satin_nickel", "spread": "8_inch"}', 'https://www.rohlhome.com/products/perrin-rowe-georgian-era-widespread'),
  ('U.3713LSP-APC-2', 'Perrin & Rowe Edwardian Single-Hole', 'Perrin & Rowe', 'deck-mount', 1.2, 'gpm', 25, 750, ARRAY['Edwardian design','Single hole','Polished chrome','Pop-up drain included'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "polished_chrome", "pop_up_drain": true}', 'https://www.rohlhome.com/products/perrin-rowe-edwardian-single-hole'),
  ('A3160LMTCB-2', 'Country Bath Widespread', 'Country', 'deck-mount', 1.2, 'gpm', 20, 900, ARRAY['Tuscan brass finish','Country-style lever handles','Traditional design'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "tuscan_brass", "spread": "8_inch"}', 'https://www.rohlhome.com/products/country-bath-widespread'),
  ('LB4L-APC-2', 'Lombardia Single-Hole Faucet', 'Lombardia', 'deck-mount', 1.2, 'gpm', 20, 650, ARRAY['Modern Italian design','Single lever','Polished chrome','Clean lines'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "polished_chrome", "pop_up_drain": true}', 'https://www.rohlhome.com/products/lombardia-single-hole'),
  ('A2224LMPN-2', 'Country Plus Widespread Faucet', 'Country', 'deck-mount', 1.2, 'gpm', 20, 950, ARRAY['Country Plus design','Polished nickel','Cross handles','Traditional charm'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "polished_nickel", "spread": "8_inch"}', 'https://www.rohlhome.com/products/country-plus-widespread'),
  ('MB2019LMAPC-2', 'Michael Berman Widespread Faucet', 'Michael Berman', 'deck-mount', 1.2, 'gpm', 25, 1200, ARRAY['Designer collaboration','Polished chrome','Modern lever handles','Luxury finish'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "polished_chrome", "spread": "8_inch"}', 'https://www.rohlhome.com/products/michael-berman-widespread')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'rohl' AND c.slug = 'bathroom-faucet';

-- Rohl Shower Systems
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('TKIT600L-PN', 'Perrin & Rowe Georgian Era Shower System', 'Perrin & Rowe', 'wall-mount', 2.5, 'gpm', 25, 2800, ARRAY['Exposed thermostatic shower','Rain showerhead','Hand shower','Polished nickel','British design'], '{"gpm": 2.5, "shower_type": "exposed_thermostatic", "rain_head_inches": 8, "hand_shower": true, "finish": "polished_nickel"}', 'https://www.rohlhome.com/products/perrin-rowe-georgian-shower'),
  ('TKIT300L-APC', 'Perrin & Rowe Edwardian Pressure Balance Shower', 'Perrin & Rowe', 'wall-mount', 2.0, 'gpm', 25, 1800, ARRAY['Pressure balance valve','Rain showerhead','Polished chrome','Lever handle'], '{"gpm": 2.0, "shower_type": "pressure_balance", "rain_head_inches": 8, "hand_shower": false, "finish": "polished_chrome"}', 'https://www.rohlhome.com/products/perrin-rowe-edwardian-shower'),
  ('A2808LMSTN', 'Country Bath Exposed Shower', 'Country', 'wall-mount', 2.5, 'gpm', 20, 2200, ARRAY['Exposed shower system','Satin nickel','Hand shower included','Traditional design'], '{"gpm": 2.5, "shower_type": "exposed_thermostatic", "rain_head_inches": 6, "hand_shower": true, "finish": "satin_nickel"}', 'https://www.rohlhome.com/products/country-bath-exposed-shower'),
  ('LB-KIT300L-STN', 'Lombardia Pressure Balance Shower', 'Lombardia', 'wall-mount', 2.0, 'gpm', 20, 1500, ARRAY['Pressure balance valve','Modern design','Satin nickel','Lever handle'], '{"gpm": 2.0, "shower_type": "pressure_balance", "rain_head_inches": 8, "hand_shower": false, "finish": "satin_nickel"}', 'https://www.rohlhome.com/products/lombardia-shower')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'rohl' AND c.slug = 'shower-system';


-- ############################################################################
-- WATER TREATMENT — VIQUA (UV Disinfection)
-- ############################################################################

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('D4', 'D4 Home UV System 12 GPM', 'D Series', 'inline', 12, 'gpm', 10, false, 600, ARRAY['12 GPM flow rate','Whole-home UV','Audible lamp-life counter','1-2 bathroom homes','Easy lamp replacement'], '{"uv_dose_mj_cm2": 40, "flow_rate_gpm": 12, "lamp_watts": 39, "lamp_life_hours": 9000, "inlet_outlet": "3/4_inch", "chamber_material": "stainless_steel"}', 'https://www.viqua.com/products/d4'),
  ('D4-V', 'D4-V Home UV System 12 GPM w/ Sensor', 'D Series', 'inline', 12, 'gpm', 10, false, 900, ARRAY['UV sensor monitoring','12 GPM flow rate','Real-time dose verification','Audible alarm'], '{"uv_dose_mj_cm2": 40, "flow_rate_gpm": 12, "lamp_watts": 39, "lamp_life_hours": 9000, "inlet_outlet": "3/4_inch", "chamber_material": "stainless_steel", "uv_sensor": true}', 'https://www.viqua.com/products/d4-v'),
  ('E4', 'E4 Home UV System 15 GPM', 'E Series', 'inline', 15, 'gpm', 10, false, 750, ARRAY['15 GPM flow rate','2-3 bathroom homes','Audible lamp counter','Stainless steel chamber'], '{"uv_dose_mj_cm2": 40, "flow_rate_gpm": 15, "lamp_watts": 54, "lamp_life_hours": 9000, "inlet_outlet": "1_inch", "chamber_material": "stainless_steel"}', 'https://www.viqua.com/products/e4'),
  ('F4', 'F4 Home UV System 18 GPM', 'F Series', 'inline', 18, 'gpm', 10, false, 900, ARRAY['18 GPM flow rate','3-4 bathroom homes','High output lamp','Stainless steel chamber'], '{"uv_dose_mj_cm2": 40, "flow_rate_gpm": 18, "lamp_watts": 75, "lamp_life_hours": 9000, "inlet_outlet": "1_inch", "chamber_material": "stainless_steel"}', 'https://www.viqua.com/products/f4'),
  ('IHS12-D4', 'IHS12-D4 Integrated UV System', 'IHS', 'inline', 12, 'gpm', 10, false, 1100, ARRAY['Integrated UV + sediment filter','All-in-one system','Digital controller','Easy maintenance'], '{"uv_dose_mj_cm2": 40, "flow_rate_gpm": 12, "lamp_watts": 39, "lamp_life_hours": 9000, "inlet_outlet": "3/4_inch", "chamber_material": "stainless_steel", "sediment_filter": true}', 'https://www.viqua.com/products/ihs12-d4'),
  ('IHS22-E4', 'IHS22-E4 Integrated UV System', 'IHS', 'inline', 15, 'gpm', 10, false, 1300, ARRAY['Integrated UV + dual filtration','Sediment + carbon filters','Digital controller','Larger homes'], '{"uv_dose_mj_cm2": 40, "flow_rate_gpm": 15, "lamp_watts": 54, "lamp_life_hours": 9000, "inlet_outlet": "1_inch", "chamber_material": "stainless_steel", "sediment_filter": true, "carbon_filter": true}', 'https://www.viqua.com/products/ihs22-e4'),
  ('VH410', 'VH410 Home UV System 18 GPM', 'VH', 'inline', 18, 'gpm', 12, true, 1500, ARRAY['Wi-Fi enabled','Smart monitoring','18 GPM','UV sensor','App notifications'], '{"uv_dose_mj_cm2": 40, "flow_rate_gpm": 18, "lamp_watts": 75, "lamp_life_hours": 9000, "inlet_outlet": "1_inch", "chamber_material": "stainless_steel", "uv_sensor": true, "wifi": true}', 'https://www.viqua.com/products/vh410'),
  ('S2Q-OZ', 'S2Q-OZ Point-of-Use UV', 'S Series', 'inline', 6, 'gpm', 8, false, 400, ARRAY['Point-of-use UV','Compact design','Under-sink installation','Quick-connect fittings'], '{"uv_dose_mj_cm2": 40, "flow_rate_gpm": 6, "lamp_watts": 14, "lamp_life_hours": 9000, "inlet_outlet": "3/8_inch", "chamber_material": "stainless_steel"}', 'https://www.viqua.com/products/s2q-oz')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'viqua' AND c.slug = 'water-treatment-uv';
