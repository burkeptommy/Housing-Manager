SET ROLE postgres;
-- ============================================================================
-- Equipment Catalog: Pool Systems
-- Covers: Pentair, Hayward, Jandy, Raypak, AquaCal, Maytronics, Polaris,
--         Zodiac, AutoPilot, CircuPool, Intex, Intermatic
-- Categories: pool-pump, pool-filter, pool-heater, salt-chlorine-generator,
--             pool-cleaner, pool-automation
-- ============================================================================

-- ============================================================================
-- PENTAIR (Big Three) - 20 models
-- ============================================================================

-- Pentair Pumps
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'in-ground', NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('011028', 'IntelliFlo VSF 3HP Variable Speed', 'IntelliFlo', 'electric', 3.0, 'hp', 10, true, true, 1800,
   ARRAY['Variable speed and flow','Built-in drive','Energy Star','Digital keypad','8 programmable speeds'],
   '{"hp": 3.0, "flow_gpm": 160, "voltage": 230, "variable_speed": true, "speed_settings": 8, "pool_size_max_gallons": 40000}',
   'https://www.pentair.com/en-us/products/residential/pool-spa-equipment/pool-pumps/intelliflo-vsf-variable-speed-pump.html'),
  ('011056', 'IntelliFlo3 VSF 3HP', 'IntelliFlo3', 'electric', 3.0, 'hp', 10, true, true, 2100,
   ARRAY['Variable speed and flow','Touch screen display','Built-in diagnostics','Energy Star','Drop-in replacement'],
   '{"hp": 3.0, "flow_gpm": 160, "voltage": 230, "variable_speed": true, "speed_settings": 8, "pool_size_max_gallons": 40000, "touchscreen": true}',
   'https://www.pentair.com/en-us/products/residential/pool-spa-equipment/pool-pumps/intelliflo3-vsf-variable-speed-pump.html'),
  ('011057', 'IntelliFlo3 VSF 1.5HP', 'IntelliFlo3', 'electric', 1.5, 'hp', 10, true, true, 1700,
   ARRAY['Variable speed and flow','Touch screen display','Energy Star','Compact design'],
   '{"hp": 1.5, "flow_gpm": 100, "voltage": 230, "variable_speed": true, "speed_settings": 8, "pool_size_max_gallons": 25000, "touchscreen": true}',
   'https://www.pentair.com/en-us/products/residential/pool-spa-equipment/pool-pumps/intelliflo3-vsf-variable-speed-pump.html'),
  ('011018', 'IntelliFlo VS+SVRS Variable Speed', 'IntelliFlo', 'electric', 3.0, 'hp', 10, true, true, 1900,
   ARRAY['Variable speed','Safety vacuum release system','Energy Star','Built-in SVRS safety'],
   '{"hp": 3.0, "flow_gpm": 160, "voltage": 230, "variable_speed": true, "speed_settings": 8, "pool_size_max_gallons": 40000, "svrs": true}',
   'https://www.pentair.com/en-us/products/residential/pool-spa-equipment/pool-pumps/intelliflo-vs-svrs-variable-speed-pump.html'),
  ('340039', 'SuperFlo VS Variable Speed', 'SuperFlo', 'electric', 1.5, 'hp', 8, true, true, 1100,
   ARRAY['Variable speed','Easy installation','Energy Star','Budget-friendly variable speed'],
   '{"hp": 1.5, "flow_gpm": 90, "voltage": 115, "variable_speed": true, "speed_settings": 3, "pool_size_max_gallons": 20000}',
   'https://www.pentair.com/en-us/products/residential/pool-spa-equipment/pool-pumps/superflo-vs-variable-speed-pump.html'),
  ('340038', 'SuperFlo VS 1HP', 'SuperFlo', 'electric', 1.0, 'hp', 8, false, true, 900,
   ARRAY['Variable speed','Compact design','Dual voltage','Easy retrofit'],
   '{"hp": 1.0, "flow_gpm": 70, "voltage": 115, "variable_speed": true, "speed_settings": 3, "pool_size_max_gallons": 15000}',
   'https://www.pentair.com/en-us/products/residential/pool-spa-equipment/pool-pumps/superflo-vs-variable-speed-pump.html')
) AS v(model_number, model_name, series, fuel, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs, url)
WHERE m.slug = 'pentair' AND c.slug = 'pool-pump';

-- Pentair Filters
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'in-ground', NULL, v.cap, 'sq_ft', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('160332', 'Clean & Clear Plus 420 Cartridge Filter', 'Clean & Clear Plus', 420, 8, 800,
   ARRAY['420 sq ft filtration area','Low maintenance','Easy cartridge removal','Continuous internal air relief'],
   '{"sq_ft": 420, "flow_rate_gpm": 150, "filter_type": "cartridge", "tank_diameter": 25, "pool_size_max_gallons": 42000}',
   'https://www.pentair.com/en-us/products/residential/pool-spa-equipment/pool-filters/clean-clear-plus-cartridge-filter.html'),
  ('160340', 'Clean & Clear Plus 520 Cartridge Filter', 'Clean & Clear Plus', 520, 8, 950,
   ARRAY['520 sq ft filtration area','High capacity','Easy cartridge changes','Internal air relief'],
   '{"sq_ft": 520, "flow_rate_gpm": 180, "filter_type": "cartridge", "tank_diameter": 28, "pool_size_max_gallons": 52000}',
   'https://www.pentair.com/en-us/products/residential/pool-spa-equipment/pool-filters/clean-clear-plus-cartridge-filter.html'),
  ('145240', 'Triton II TR100 Sand Filter', 'Triton II', 100, 10, 700,
   ARRAY['Fiberglass-reinforced tank','Top-mount valve','Corrosion resistant','High flow capacity'],
   '{"sq_ft": 100, "flow_rate_gpm": 100, "filter_type": "sand", "tank_diameter": 30, "pool_size_max_gallons": 50000}',
   'https://www.pentair.com/en-us/products/residential/pool-spa-equipment/pool-filters/triton-ii-sand-filter.html'),
  ('180009', 'FNS Plus 60 DE Filter', 'FNS Plus', 60, 8, 900,
   ARRAY['60 sq ft DE filtration','Superior water clarity','Flex-tube design','Easy cleaning'],
   '{"sq_ft": 60, "flow_rate_gpm": 120, "filter_type": "de", "tank_diameter": 24, "pool_size_max_gallons": 30000}',
   'https://www.pentair.com/en-us/products/residential/pool-spa-equipment/pool-filters/fns-plus-de-filter.html')
) AS v(model_number, model_name, series, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'pentair' AND c.slug = 'pool-filter';

-- Pentair Heaters
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'in-ground', NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('461021', 'MasterTemp 400 Gas Heater', 'MasterTemp', 'gas', 400000, 'btu', 10, false, 2800,
   ARRAY['400K BTU','Hot surface ignition','Compact design','Integrated bypass valve','Rust-free composite headers'],
   '{"btu": 400000, "efficiency_pct": 84, "pool_size_max_gallons": 40000, "ignition": "hot_surface", "low_nox": true}',
   'https://www.pentair.com/en-us/products/residential/pool-spa-equipment/pool-heaters/mastertemp-high-performance-heater.html'),
  ('461059', 'MasterTemp 250 Gas Heater', 'MasterTemp', 'gas', 250000, 'btu', 10, false, 2200,
   ARRAY['250K BTU','Compact footprint','Hot surface ignition','Corrosion-resistant'],
   '{"btu": 250000, "efficiency_pct": 84, "pool_size_max_gallons": 25000, "ignition": "hot_surface", "low_nox": true}',
   'https://www.pentair.com/en-us/products/residential/pool-spa-equipment/pool-heaters/mastertemp-high-performance-heater.html'),
  ('460737', 'MasterTemp 125 Gas Heater', 'MasterTemp', 'gas', 125000, 'btu', 10, false, 1800,
   ARRAY['125K BTU','Compact design','Above-ground or small pools','Hot surface ignition'],
   '{"btu": 125000, "efficiency_pct": 84, "pool_size_max_gallons": 15000, "ignition": "hot_surface", "low_nox": true}',
   'https://www.pentair.com/en-us/products/residential/pool-spa-equipment/pool-heaters/mastertemp-high-performance-heater.html'),
  ('460967', 'UltraTemp 140 Heat Pump', 'UltraTemp', 'electric', 140000, 'btu', 12, true, 4500,
   ARRAY['140K BTU heat pump','ThermaFlo titanium exchanger','Ultra-quiet fan','COP 6.2','Heating and cooling'],
   '{"btu": 140000, "efficiency_pct": 620, "pool_size_max_gallons": 40000, "type": "heat_pump", "cop": 6.2, "titanium_exchanger": true}',
   'https://www.pentair.com/en-us/products/residential/pool-spa-equipment/pool-heaters/ultratemp-heat-pump.html')
) AS v(model_number, model_name, series, fuel, cap, cap_unit, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'pentair' AND c.slug = 'pool-heater';

-- Pentair Salt Chlorine Generators
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'in-ground', NULL, v.cap, 'gallons', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('520555', 'IntelliChlor IC40 Salt Chlorinator', 'IntelliChlor', 40000, 5, false, 1400,
   ARRAY['40K gallon capacity','Self-cleaning cell','Flow sensor','Easy installation','Digital display'],
   '{"max_gallons": 40000, "cell_type": "titanium", "self_cleaning": true, "chlorine_output_lbs_day": 1.4, "flow_sensor": true}',
   'https://www.pentair.com/en-us/products/residential/pool-spa-equipment/pool-sanitizers/intellichlor-salt-chlorine-generator.html'),
  ('520556', 'IntelliChlor IC60 Salt Chlorinator', 'IntelliChlor', 60000, 5, false, 1700,
   ARRAY['60K gallon capacity','Self-cleaning cell','Flow sensor','High output','Digital readout'],
   '{"max_gallons": 60000, "cell_type": "titanium", "self_cleaning": true, "chlorine_output_lbs_day": 2.0, "flow_sensor": true}',
   'https://www.pentair.com/en-us/products/residential/pool-spa-equipment/pool-sanitizers/intellichlor-salt-chlorine-generator.html'),
  ('520557', 'IntelliChlor IC20 Salt Chlorinator', 'IntelliChlor', 20000, 5, false, 1100,
   ARRAY['20K gallon capacity','Self-cleaning cell','Compact design','Easy retrofit'],
   '{"max_gallons": 20000, "cell_type": "titanium", "self_cleaning": true, "chlorine_output_lbs_day": 0.7, "flow_sensor": true}',
   'https://www.pentair.com/en-us/products/residential/pool-spa-equipment/pool-sanitizers/intellichlor-salt-chlorine-generator.html')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'pentair' AND c.slug = 'salt-chlorine-generator';

-- Pentair Automation
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'in-ground', NULL, v.cap, 'zones', true, v.lifespan, true, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('522104', 'IntelliCenter i10PS Control System', 'IntelliCenter', 10, 12, 3500,
   ARRAY['10 auxiliary circuits','Full-color touchscreen','App control','Voice assistant compatible','Supports all Pentair equipment'],
   '{"zones": 10, "supports_salt": true, "supports_heater": true, "app_control": true, "voice_control": true, "touchscreen": true}',
   'https://www.pentair.com/en-us/products/residential/pool-spa-equipment/pool-automation/intellicenter-control-system.html'),
  ('521914', 'EasyTouch PSL4 Control System', 'EasyTouch', 4, 12, 1800,
   ARRAY['4 auxiliary circuits','ScreenLogic compatible','Wireless remote available','Salt system compatible'],
   '{"zones": 4, "supports_salt": true, "supports_heater": true, "app_control": true, "wireless_remote": true}',
   'https://www.pentair.com/en-us/products/residential/pool-spa-equipment/pool-automation/easytouch-control-system.html'),
  ('521915', 'EasyTouch PL4/PSL4 Pool/Spa', 'EasyTouch', 8, 12, 2400,
   ARRAY['8 auxiliary circuits','Pool/spa combo','ScreenLogic ready','Shared equipment support'],
   '{"zones": 8, "supports_salt": true, "supports_heater": true, "app_control": true, "pool_spa_combo": true}',
   'https://www.pentair.com/en-us/products/residential/pool-spa-equipment/pool-automation/easytouch-control-system.html')
) AS v(model_number, model_name, series, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'pentair' AND c.slug = 'pool-automation';


-- ============================================================================
-- HAYWARD (Big Three) - 20 models
-- ============================================================================

-- Hayward Pumps
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'in-ground', NULL, v.cap, 'hp', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('W3SP3400VSP', 'TriStar VS 950 Variable Speed', 'TriStar', 2.7, 10, true, true, 2000,
   ARRAY['Variable speed','950W max power','Digital control pad','Energy Star','Drop-in replacement'],
   '{"hp": 2.7, "flow_gpm": 148, "voltage": 230, "variable_speed": true, "speed_settings": 8, "pool_size_max_gallons": 40000}',
   'https://www.hayward.com/shop/products/pumps/tristar-vs-950-omni-variable-speed-pump'),
  ('W3SP2303VSP', 'MaxFlo VS 500 Variable Speed', 'MaxFlo', 1.65, 10, true, true, 1300,
   ARRAY['Variable speed','500W max power','Energy Star','Easy installation','Compact footprint'],
   '{"hp": 1.65, "flow_gpm": 90, "voltage": 115, "variable_speed": true, "speed_settings": 8, "pool_size_max_gallons": 20000}',
   'https://www.hayward.com/shop/products/pumps/maxflo-vs-500-omni-variable-speed-pump'),
  ('W3SP2315X20PE', 'MaxFlo XL 2HP Single Speed', 'MaxFlo XL', 2.0, 8, false, false, 600,
   ARRAY['Single speed','Heavy-duty motor','Durable construction','Cost-effective'],
   '{"hp": 2.0, "flow_gpm": 81, "voltage": 230, "variable_speed": false, "pool_size_max_gallons": 25000}',
   'https://www.hayward.com/shop/products/pumps/maxflo-xl-pump'),
  ('W3SP3206VSP', 'TriStar VS 900 Variable Speed', 'TriStar', 2.7, 10, true, true, 1800,
   ARRAY['Variable speed','900W max','Programmable timer','Energy Star','Quiet operation'],
   '{"hp": 2.7, "flow_gpm": 140, "voltage": 230, "variable_speed": true, "speed_settings": 8, "pool_size_max_gallons": 35000}',
   'https://www.hayward.com/shop/products/pumps/tristar-vs-900-omni-variable-speed-pump'),
  ('W3SP2610X15', 'Super Pump 1.5HP Single Speed', 'Super Pump', 1.5, 8, false, false, 500,
   ARRAY['Single speed','See-through strainer lid','Heavy-duty motor','Most popular pool pump'],
   '{"hp": 1.5, "flow_gpm": 80, "voltage": 115, "variable_speed": false, "pool_size_max_gallons": 20000}',
   'https://www.hayward.com/shop/products/pumps/super-pump'),
  ('W3SP26315VSP', 'Super Pump VS 700 Variable Speed', 'Super Pump VS', 1.65, 10, true, true, 1100,
   ARRAY['Variable speed','700W max','Energy Star','Drop-in for Super Pump','Hayward app compatible'],
   '{"hp": 1.65, "flow_gpm": 95, "voltage": 115, "variable_speed": true, "speed_settings": 8, "pool_size_max_gallons": 22000}',
   'https://www.hayward.com/shop/products/pumps/super-pump-vs-700-variable-speed-pump')
) AS v(model_number, model_name, series, cap, lifespan, wifi, estar, msrp, features, specs, url)
WHERE m.slug = 'hayward' AND c.slug = 'pool-pump';

-- Hayward Filters
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'in-ground', NULL, v.cap, 'sq_ft', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('C17502', 'SwimClear C175S Cartridge Filter', 'SwimClear', 175, 8, 700,
   ARRAY['175 sq ft','Single-element cartridge','Low-profile design','Easy cleaning'],
   '{"sq_ft": 175, "flow_rate_gpm": 75, "filter_type": "cartridge", "tank_diameter": 19, "pool_size_max_gallons": 17500}',
   'https://www.hayward.com/shop/products/filters/swimclear-cartridge-filters'),
  ('C32002', 'SwimClear C320S Cartridge Filter', 'SwimClear', 325, 8, 850,
   ARRAY['325 sq ft','Four-element cartridge','Extended cleaning cycles','Internal air relief'],
   '{"sq_ft": 325, "flow_rate_gpm": 120, "filter_type": "cartridge", "tank_diameter": 21, "pool_size_max_gallons": 32000}',
   'https://www.hayward.com/shop/products/filters/swimclear-cartridge-filters'),
  ('W3S310T2', 'Pro-Series S310T2 Sand Filter', 'Pro-Series', 100, 10, 650,
   ARRAY['Top-mount valve','Fiberglass tank','Corrosion proof','Self-cleaning laterals'],
   '{"sq_ft": 100, "flow_rate_gpm": 75, "filter_type": "sand", "tank_diameter": 30, "pool_size_max_gallons": 30000}',
   'https://www.hayward.com/shop/products/filters/pro-series-sand-filter'),
  ('W3DE4820', 'Pro-Grid DE4820 DE Filter', 'Pro-Grid', 48, 8, 900,
   ARRAY['48 sq ft DE filter','Patented grid design','Superior clarity','Easy disassembly'],
   '{"sq_ft": 48, "flow_rate_gpm": 96, "filter_type": "de", "tank_diameter": 22, "pool_size_max_gallons": 24000}',
   'https://www.hayward.com/shop/products/filters/pro-grid-de-filter')
) AS v(model_number, model_name, series, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'hayward' AND c.slug = 'pool-filter';

-- Hayward Heaters
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'in-ground', NULL, v.cap, 'btu', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('W3H400FDN', 'Universal H-Series H400FD Gas Heater', 'Universal H-Series', 'gas', 400000, 10, true, 2900,
   ARRAY['400K BTU','Low NOx emissions','Forced draft','Polymer headers','Cupro-nickel exchanger option'],
   '{"btu": 400000, "efficiency_pct": 83, "pool_size_max_gallons": 40000, "ignition": "hot_surface", "low_nox": true}',
   'https://www.hayward.com/shop/products/heating/universal-h-series-heater'),
  ('W3H250FDN', 'Universal H-Series H250FD Gas Heater', 'Universal H-Series', 'gas', 250000, 10, false, 2300,
   ARRAY['250K BTU','Low NOx','Forced draft','Compact design','Digital display'],
   '{"btu": 250000, "efficiency_pct": 83, "pool_size_max_gallons": 25000, "ignition": "hot_surface", "low_nox": true}',
   'https://www.hayward.com/shop/products/heating/universal-h-series-heater'),
  ('W3H150FDN', 'Universal H-Series H150FD Gas Heater', 'Universal H-Series', 'gas', 150000, 10, false, 1900,
   ARRAY['150K BTU','Low NOx','Compact footprint','For smaller pools and spas'],
   '{"btu": 150000, "efficiency_pct": 83, "pool_size_max_gallons": 15000, "ignition": "hot_surface", "low_nox": true}',
   'https://www.hayward.com/shop/products/heating/universal-h-series-heater'),
  ('W3HP21404T', 'HeatPro 140K BTU Heat Pump', 'HeatPro', 'electric', 140000, 12, true, 4200,
   ARRAY['140K BTU heat pump','Titanium heat exchanger','Ultra Gold corrosion resistance','Quiet operation'],
   '{"btu": 140000, "efficiency_pct": 600, "pool_size_max_gallons": 40000, "type": "heat_pump", "cop": 6.0, "titanium_exchanger": true}',
   'https://www.hayward.com/shop/products/heating/heatpro-heat-pump')
) AS v(model_number, model_name, series, fuel, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'hayward' AND c.slug = 'pool-heater';

-- Hayward Salt Chlorine Generators
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'in-ground', NULL, v.cap, 'gallons', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('W3AQR15', 'AquaRite S3 Salt System', 'AquaRite', 40000, 5, true, 1500,
   ARRAY['40K gallon capacity','TurboCell T-15','Self-cleaning cell','Digital display','Goldline compatible'],
   '{"max_gallons": 40000, "cell_type": "titanium", "self_cleaning": true, "chlorine_output_lbs_day": 1.47, "turbo_cell": "T-15"}',
   'https://www.hayward.com/shop/products/sanitization/aquarite-s3-salt-chlorination-system'),
  ('W3AQR9', 'AquaRite S3 25K Salt System', 'AquaRite', 25000, 5, true, 1200,
   ARRAY['25K gallon capacity','TurboCell T-9','Self-cleaning','Compact control box'],
   '{"max_gallons": 25000, "cell_type": "titanium", "self_cleaning": true, "chlorine_output_lbs_day": 0.98, "turbo_cell": "T-9"}',
   'https://www.hayward.com/shop/products/sanitization/aquarite-s3-salt-chlorination-system'),
  ('W3AQR3', 'AquaRite S3 15K Salt System', 'AquaRite', 15000, 5, true, 1000,
   ARRAY['15K gallon capacity','TurboCell T-3','Self-cleaning','For smaller pools'],
   '{"max_gallons": 15000, "cell_type": "titanium", "self_cleaning": true, "chlorine_output_lbs_day": 0.53, "turbo_cell": "T-3"}',
   'https://www.hayward.com/shop/products/sanitization/aquarite-s3-salt-chlorination-system')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'hayward' AND c.slug = 'salt-chlorine-generator';

-- Hayward Automation
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'in-ground', NULL, v.cap, 'zones', true, v.lifespan, true, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('HLX-PLUS', 'OmniLogic Smart Pool Control', 'OmniLogic', 16, 12, 4000,
   ARRAY['16 relay outputs','Full-color touchscreen','OmniDirect app','Voice control','Supports all Hayward equipment'],
   '{"zones": 16, "supports_salt": true, "supports_heater": true, "app_control": true, "voice_control": true, "touchscreen": true}',
   'https://www.hayward.com/shop/products/automation/omnilogic-smart-pool-and-spa-control'),
  ('PL-PS-8', 'ProLogic PS-8 Pool/Spa Automation', 'ProLogic', 8, 12, 2200,
   ARRAY['8 auxiliary relays','Wireless remote','Salt compatible','Pool/spa combo support'],
   '{"zones": 8, "supports_salt": true, "supports_heater": true, "app_control": true, "pool_spa_combo": true}',
   'https://www.hayward.com/shop/products/automation/prologic-pool-spa-automation'),
  ('AQL2-BASE-RF', 'AquaConnect 2.0 Web Interface', 'AquaConnect', 4, 12, 500,
   ARRAY['Web-based control','Works with existing Hayward automation','Remote monitoring','Email alerts'],
   '{"zones": 4, "supports_salt": true, "supports_heater": true, "app_control": true, "web_interface": true}',
   'https://www.hayward.com/shop/products/automation/aquaconnect')
) AS v(model_number, model_name, series, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'hayward' AND c.slug = 'pool-automation';


-- ============================================================================
-- JANDY (Big Three) - 18 models
-- ============================================================================

-- Jandy Pumps
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'in-ground', NULL, v.cap, 'hp', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('VS-FHP270AUT', 'VS FloPro 2.7HP Variable Speed', 'VS FloPro', 2.7, 10, true, true, 1900,
   ARRAY['Variable speed','2.7 THP','JEP-R interface','Energy Star','Programmable speeds'],
   '{"hp": 2.7, "flow_gpm": 148, "voltage": 230, "variable_speed": true, "speed_settings": 8, "pool_size_max_gallons": 40000}',
   'https://www.jandy.com/en/products/pumps/vs-flopro'),
  ('VS-FHP165AUT', 'VS FloPro 1.65HP Variable Speed', 'VS FloPro', 1.65, 10, true, true, 1400,
   ARRAY['Variable speed','1.65 THP','Compact design','Energy Star','Easy retrofit'],
   '{"hp": 1.65, "flow_gpm": 90, "voltage": 115, "variable_speed": true, "speed_settings": 8, "pool_size_max_gallons": 25000}',
   'https://www.jandy.com/en/products/pumps/vs-flopro'),
  ('VSSHP270AUT', 'ePump 2.7HP Variable Speed', 'ePump', 2.7, 10, true, true, 1700,
   ARRAY['Variable speed','2.7 THP','iAqualink compatible','Energy Star','Built-in time clock'],
   '{"hp": 2.7, "flow_gpm": 145, "voltage": 230, "variable_speed": true, "speed_settings": 8, "pool_size_max_gallons": 35000}',
   'https://www.jandy.com/en/products/pumps/epump'),
  ('FHPM15-2A', 'FloPro 1.5HP Single Speed', 'FloPro', 1.5, 8, false, false, 500,
   ARRAY['Single speed','1.5HP','Medium head','Quiet operation','Self-priming'],
   '{"hp": 1.5, "flow_gpm": 75, "voltage": 115, "variable_speed": false, "pool_size_max_gallons": 20000}',
   'https://www.jandy.com/en/products/pumps/flopro'),
  ('FHPM20-2A', 'FloPro 2.0HP Single Speed', 'FloPro', 2.0, 8, false, false, 600,
   ARRAY['Single speed','2.0HP','High head','Durable motor','Self-priming'],
   '{"hp": 2.0, "flow_gpm": 85, "voltage": 230, "variable_speed": false, "pool_size_max_gallons": 25000}',
   'https://www.jandy.com/en/products/pumps/flopro')
) AS v(model_number, model_name, series, cap, lifespan, wifi, estar, msrp, features, specs, url)
WHERE m.slug = 'jandy' AND c.slug = 'pool-pump';

-- Jandy Filters
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'in-ground', NULL, v.cap, 'sq_ft', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('CL460', 'CL 460 Cartridge Filter', 'CL Series', 460, 8, 850,
   ARRAY['460 sq ft filtration area','Rapid-release clamp','Easy-open design','PVC construction'],
   '{"sq_ft": 460, "flow_rate_gpm": 110, "filter_type": "cartridge", "tank_diameter": 25, "pool_size_max_gallons": 46000}',
   'https://www.jandy.com/en/products/filters/cl-cartridge-filter'),
  ('CL340', 'CL 340 Cartridge Filter', 'CL Series', 340, 8, 700,
   ARRAY['340 sq ft','Rapid-release clamp','Service-ease design','Corrosion-free'],
   '{"sq_ft": 340, "flow_rate_gpm": 85, "filter_type": "cartridge", "tank_diameter": 22, "pool_size_max_gallons": 34000}',
   'https://www.jandy.com/en/products/filters/cl-cartridge-filter'),
  ('DEV48', 'DEV48 DE Filter', 'DEV Series', 48, 8, 850,
   ARRAY['48 sq ft DE filter','PermaLast body','Top-access design','Precision manifold'],
   '{"sq_ft": 48, "flow_rate_gpm": 96, "filter_type": "de", "tank_diameter": 22, "pool_size_max_gallons": 24000}',
   'https://www.jandy.com/en/products/filters/dev-de-filter'),
  ('JS100-SM', 'JS100 Sand Filter', 'JS Series', 100, 10, 600,
   ARRAY['100 sq ft','Side-mount valve','Fiberglass body','Self-cleaning laterals'],
   '{"sq_ft": 100, "flow_rate_gpm": 75, "filter_type": "sand", "tank_diameter": 30, "pool_size_max_gallons": 30000}',
   'https://www.jandy.com/en/products/filters/js-series-sand-filter')
) AS v(model_number, model_name, series, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'jandy' AND c.slug = 'pool-filter';

-- Jandy Heaters
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'in-ground', NULL, v.cap, 'btu', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('JXI400N', 'JXi 400K BTU Gas Heater', 'JXi', 'gas', 400000, 10, true, 3200,
   ARRAY['400K BTU','Low NOx','iAqualink ready','Polymer headers','Compact design','Cupro-nickel exchanger'],
   '{"btu": 400000, "efficiency_pct": 85, "pool_size_max_gallons": 40000, "ignition": "hot_surface", "low_nox": true}',
   'https://www.jandy.com/en/products/heaters/jxi-gas-heater'),
  ('JXI260N', 'JXi 260K BTU Gas Heater', 'JXi', 'gas', 260000, 10, true, 2600,
   ARRAY['260K BTU','Low NOx','iAqualink ready','Compact footprint'],
   '{"btu": 260000, "efficiency_pct": 85, "pool_size_max_gallons": 26000, "ignition": "hot_surface", "low_nox": true}',
   'https://www.jandy.com/en/products/heaters/jxi-gas-heater'),
  ('LRZ400EN', 'LRZ 400K BTU Legacy Gas Heater', 'LRZ Legacy', 'gas', 400000, 10, false, 2500,
   ARRAY['400K BTU','Proven reliability','Polymer headers','Digital controls'],
   '{"btu": 400000, "efficiency_pct": 83, "pool_size_max_gallons": 40000, "ignition": "electronic", "low_nox": false}',
   'https://www.jandy.com/en/products/heaters/lrz-legacy-heater'),
  ('JE3000T', 'JE 3000 Heat Pump', 'JE Series', 'electric', 137000, 12, true, 4300,
   ARRAY['137K BTU heat pump','Titanium heat exchanger','TruHeat technology','iAqualink ready','Ultra quiet'],
   '{"btu": 137000, "efficiency_pct": 610, "pool_size_max_gallons": 35000, "type": "heat_pump", "cop": 6.1, "titanium_exchanger": true}',
   'https://www.jandy.com/en/products/heaters/je-heat-pump')
) AS v(model_number, model_name, series, fuel, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'jandy' AND c.slug = 'pool-heater';

-- Jandy Salt Chlorine Generator
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'in-ground', NULL, v.cap, 'gallons', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('AQR15', 'AquaPure Ei 35K Salt System', 'AquaPure', 35000, 5, true, 1300,
   ARRAY['35K gallon capacity','Self-cleaning cell','iAqualink compatible','Easy installation'],
   '{"max_gallons": 35000, "cell_type": "titanium", "self_cleaning": true, "chlorine_output_lbs_day": 1.2}',
   'https://www.jandy.com/en/products/sanitization/aquapure-ei-salt-system'),
  ('AQR25', 'AquaPure Ei 50K Salt System', 'AquaPure', 50000, 5, true, 1600,
   ARRAY['50K gallon capacity','Self-cleaning cell','High output','iAqualink ready'],
   '{"max_gallons": 50000, "cell_type": "titanium", "self_cleaning": true, "chlorine_output_lbs_day": 1.8}',
   'https://www.jandy.com/en/products/sanitization/aquapure-ei-salt-system')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'jandy' AND c.slug = 'salt-chlorine-generator';

-- Jandy Automation
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'in-ground', NULL, v.cap, 'zones', true, v.lifespan, true, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('IQ904-PS', 'iAqualink IQ904-PS Control', 'iAqualink', 4, 12, 2000,
   ARRAY['4 auxiliary outputs','iAqualink app control','Pool/spa support','Voice control','Web dashboard'],
   '{"zones": 4, "supports_salt": true, "supports_heater": true, "app_control": true, "voice_control": true}',
   'https://www.jandy.com/en/products/controls/iaqualink'),
  ('IQ920-RS', 'iAqualink IQ920-RS Pool Only', 'iAqualink', 8, 12, 2800,
   ARRAY['8 auxiliary outputs','RS bus communication','iAqualink app','Full equipment control'],
   '{"zones": 8, "supports_salt": true, "supports_heater": true, "app_control": true, "rs_bus": true}',
   'https://www.jandy.com/en/products/controls/iaqualink'),
  ('RS-PS8', 'AquaLink RS PS8 Control', 'AquaLink', 8, 12, 1600,
   ARRAY['8 auxiliary relays','Pool/spa combo','OneTouch controls','Time clock'],
   '{"zones": 8, "supports_salt": true, "supports_heater": true, "app_control": false, "pool_spa_combo": true}',
   'https://www.jandy.com/en/products/controls/aqualink-rs')
) AS v(model_number, model_name, series, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'jandy' AND c.slug = 'pool-automation';


-- ============================================================================
-- RAYPAK (Heater Specialist) - 10 models
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'in-ground', NULL, v.cap, 'btu', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('014941', 'Digital 406A Gas Heater', 'Digital', 'gas', 399000, 10, false, 2700,
   ARRAY['399K BTU','Digital controls','PolyTuf textured powder coat','Unitherm Governor','Cupro-nickel exchanger available'],
   '{"btu": 399000, "efficiency_pct": 83, "pool_size_max_gallons": 40000, "ignition": "electronic", "low_nox": true}',
   'https://www.raypak.com/products/pool-spa-heaters/digital-gas-heaters'),
  ('014939', 'Digital 336A Gas Heater', 'Digital', 'gas', 336000, 10, false, 2400,
   ARRAY['336K BTU','Digital controls','PolyTuf finish','Compact cabinet'],
   '{"btu": 336000, "efficiency_pct": 83, "pool_size_max_gallons": 33000, "ignition": "electronic", "low_nox": true}',
   'https://www.raypak.com/products/pool-spa-heaters/digital-gas-heaters'),
  ('014937', 'Digital 266A Gas Heater', 'Digital', 'gas', 266000, 10, false, 2100,
   ARRAY['266K BTU','Digital controls','Polymer headers','Wind-resistant design'],
   '{"btu": 266000, "efficiency_pct": 83, "pool_size_max_gallons": 26000, "ignition": "electronic", "low_nox": true}',
   'https://www.raypak.com/products/pool-spa-heaters/digital-gas-heaters'),
  ('014951', 'Digital 406A Propane Heater', 'Digital', 'propane', 399000, 10, false, 2800,
   ARRAY['399K BTU','Propane fuel','Digital controls','PolyTuf finish','Cupro-nickel option'],
   '{"btu": 399000, "efficiency_pct": 83, "pool_size_max_gallons": 40000, "ignition": "electronic", "low_nox": true, "fuel": "propane"}',
   'https://www.raypak.com/products/pool-spa-heaters/digital-gas-heaters'),
  ('017130', 'Crosswind 60K Heat Pump', 'Crosswind', 'electric', 60000, 12, true, 3200,
   ARRAY['60K BTU heat pump','Crosswind technology','Compact design','Titanium exchanger'],
   '{"btu": 60000, "efficiency_pct": 550, "pool_size_max_gallons": 15000, "type": "heat_pump", "cop": 5.5, "titanium_exchanger": true}',
   'https://www.raypak.com/products/pool-spa-heaters/heat-pumps'),
  ('017131', 'Crosswind 95K Heat Pump', 'Crosswind', 'electric', 95000, 12, true, 3800,
   ARRAY['95K BTU heat pump','Crosswind technology','Titanium exchanger','Full-color display'],
   '{"btu": 95000, "efficiency_pct": 580, "pool_size_max_gallons": 25000, "type": "heat_pump", "cop": 5.8, "titanium_exchanger": true}',
   'https://www.raypak.com/products/pool-spa-heaters/heat-pumps'),
  ('017132', 'Crosswind 140K Heat Pump', 'Crosswind', 'electric', 140000, 12, true, 4500,
   ARRAY['140K BTU heat pump','Crosswind technology','Titanium exchanger','Smart controls','Ultra quiet'],
   '{"btu": 140000, "efficiency_pct": 600, "pool_size_max_gallons": 40000, "type": "heat_pump", "cop": 6.0, "titanium_exchanger": true}',
   'https://www.raypak.com/products/pool-spa-heaters/heat-pumps'),
  ('009219', 'Analog 406A Gas Heater', 'Analog', 'gas', 399000, 10, false, 2200,
   ARRAY['399K BTU','Analog controls','Mechanical thermostat','PolyTuf finish','Proven reliability'],
   '{"btu": 399000, "efficiency_pct": 82, "pool_size_max_gallons": 40000, "ignition": "millivolt", "low_nox": false}',
   'https://www.raypak.com/products/pool-spa-heaters/analog-gas-heaters'),
  ('009217', 'Analog 336A Gas Heater', 'Analog', 'gas', 336000, 10, false, 1900,
   ARRAY['336K BTU','Analog controls','Mechanical thermostat','Durable construction'],
   '{"btu": 336000, "efficiency_pct": 82, "pool_size_max_gallons": 33000, "ignition": "millivolt", "low_nox": false}',
   'https://www.raypak.com/products/pool-spa-heaters/analog-gas-heaters'),
  ('009215', 'Analog 266A Gas Heater', 'Analog', 'gas', 266000, 10, false, 1600,
   ARRAY['266K BTU','Analog controls','Mechanical thermostat','Compact size'],
   '{"btu": 266000, "efficiency_pct": 82, "pool_size_max_gallons": 26000, "ignition": "millivolt", "low_nox": false}',
   'https://www.raypak.com/products/pool-spa-heaters/analog-gas-heaters')
) AS v(model_number, model_name, series, fuel, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'raypak' AND c.slug = 'pool-heater';


-- ============================================================================
-- AQUACAL (Heat Pump Specialist) - 8 models
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'in-ground', NULL, v.cap, 'btu', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('T135', 'TropiCal T135 Heat Pump', 'TropiCal', 132000, 12, true, 4200,
   ARRAY['132K BTU','Titanium heat exchanger','TropiCal technology','Ultra-quiet fan','Digital controls'],
   '{"btu": 132000, "efficiency_pct": 600, "pool_size_max_gallons": 35000, "type": "heat_pump", "cop": 6.0, "titanium_exchanger": true}',
   'https://www.aquacal.com/products/tropical-heat-pumps'),
  ('T115', 'TropiCal T115 Heat Pump', 'TropiCal', 112000, 12, true, 3600,
   ARRAY['112K BTU','Titanium exchanger','Digital LCD','Quiet operation','Auto defrost'],
   '{"btu": 112000, "efficiency_pct": 580, "pool_size_max_gallons": 28000, "type": "heat_pump", "cop": 5.8, "titanium_exchanger": true}',
   'https://www.aquacal.com/products/tropical-heat-pumps'),
  ('T75', 'TropiCal T75 Heat Pump', 'TropiCal', 75000, 12, false, 2800,
   ARRAY['75K BTU','Titanium exchanger','Compact design','For smaller pools'],
   '{"btu": 75000, "efficiency_pct": 560, "pool_size_max_gallons": 18000, "type": "heat_pump", "cop": 5.6, "titanium_exchanger": true}',
   'https://www.aquacal.com/products/tropical-heat-pumps'),
  ('SQ166R', 'HeatWave SuperQuiet SQ166R', 'HeatWave SuperQuiet', 126000, 12, true, 4800,
   ARRAY['126K BTU','Super-quiet operation','Scroll compressor','ThermoLink titanium','Digital display'],
   '{"btu": 126000, "efficiency_pct": 620, "pool_size_max_gallons": 32000, "type": "heat_pump", "cop": 6.2, "titanium_exchanger": true, "scroll_compressor": true}',
   'https://www.aquacal.com/products/heatwave-superquiet'),
  ('SQ125R', 'HeatWave SuperQuiet SQ125R', 'HeatWave SuperQuiet', 110000, 12, true, 4200,
   ARRAY['110K BTU','Super-quiet operation','Scroll compressor','ThermoLink titanium'],
   '{"btu": 110000, "efficiency_pct": 600, "pool_size_max_gallons": 28000, "type": "heat_pump", "cop": 6.0, "titanium_exchanger": true, "scroll_compressor": true}',
   'https://www.aquacal.com/products/heatwave-superquiet'),
  ('CD25', 'Chill & Heat CD25 Chiller/Heater', 'Chill & Heat', 55000, 12, true, 5200,
   ARRAY['Heats and cools','55K BTU','Titanium exchanger','Year-round temperature control'],
   '{"btu": 55000, "efficiency_pct": 580, "pool_size_max_gallons": 15000, "type": "heat_pump", "cop": 5.8, "heats_and_cools": true, "titanium_exchanger": true}',
   'https://www.aquacal.com/products/chill-and-heat'),
  ('CD55', 'Chill & Heat CD55 Chiller/Heater', 'Chill & Heat', 110000, 12, true, 6000,
   ARRAY['Heats and cools','110K BTU','Titanium exchanger','Dual-mode operation','Digital display'],
   '{"btu": 110000, "efficiency_pct": 600, "pool_size_max_gallons": 28000, "type": "heat_pump", "cop": 6.0, "heats_and_cools": true, "titanium_exchanger": true}',
   'https://www.aquacal.com/products/chill-and-heat'),
  ('WS10', 'Water Source WS10 Geothermal', 'Water Source', 120000, 15, false, 7500,
   ARRAY['120K BTU geothermal','Water source heat pump','Highest efficiency','Titanium exchanger','Long lifespan'],
   '{"btu": 120000, "efficiency_pct": 700, "pool_size_max_gallons": 30000, "type": "geothermal_heat_pump", "cop": 7.0, "titanium_exchanger": true}',
   'https://www.aquacal.com/products/water-source')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'aquacal' AND c.slug = 'pool-heater';


-- ============================================================================
-- MAYTRONICS (Robotic Cleaner Specialist) - 10 models
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'in-ground', NULL, NULL, NULL, true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('99996141-USF', 'Dolphin Nautilus CC Plus', 'Dolphin Nautilus', 5, false, 800,
   ARRAY['CleverClean navigation','Wall climbing','Top-loading filter basket','Lightweight','Weekly timer'],
   '{"pool_size_max_ft": 50, "cable_length_ft": 60, "filtration_microns": 2, "cycle_time_hours": 2.5, "wall_climbing": true, "waterline_scrubbing": true}',
   'https://www.maytronics.com/us/dolphin-nautilus-cc-plus'),
  ('99996133-USF', 'Dolphin Nautilus CC', 'Dolphin Nautilus', 5, false, 650,
   ARRAY['CleverClean navigation','Floor and wall cleaning','Top-loading filter','Budget-friendly robotic'],
   '{"pool_size_max_ft": 33, "cable_length_ft": 50, "filtration_microns": 2, "cycle_time_hours": 2, "wall_climbing": true, "waterline_scrubbing": false}',
   'https://www.maytronics.com/us/dolphin-nautilus-cc'),
  ('99996610-US', 'Dolphin Premier', 'Dolphin Premier', 5, true, 1400,
   ARRAY['Multi-media filtration','SmartNav 2.0','4 filtration options','App control','Oversized cartridge'],
   '{"pool_size_max_ft": 50, "cable_length_ft": 60, "filtration_microns": 2, "cycle_time_hours": 3, "wall_climbing": true, "waterline_scrubbing": true, "app_control": true}',
   'https://www.maytronics.com/us/dolphin-premier'),
  ('99996170-USF', 'Dolphin M600', 'Dolphin M-Series', 5, true, 1800,
   ARRAY['WiFi app control','PowerStream mobility','Multi-layer filtration','SmartNav 3.0','Voice control'],
   '{"pool_size_max_ft": 50, "cable_length_ft": 60, "filtration_microns": 2, "cycle_time_hours": 3, "wall_climbing": true, "waterline_scrubbing": true, "app_control": true, "voice_control": true}',
   'https://www.maytronics.com/us/dolphin-m600'),
  ('99996180-USF', 'Dolphin M700', 'Dolphin M-Series', 5, true, 2200,
   ARRAY['WiFi app control','PowerStream mobility','Multi-layer filtration','SmartNav 3.0','Caddy included','Voice control'],
   '{"pool_size_max_ft": 60, "cable_length_ft": 70, "filtration_microns": 2, "cycle_time_hours": 3, "wall_climbing": true, "waterline_scrubbing": true, "app_control": true, "voice_control": true}',
   'https://www.maytronics.com/us/dolphin-m700'),
  ('99996113-US', 'Dolphin Triton PS Plus', 'Dolphin Triton', 5, true, 1200,
   ARRAY['PowerStream mobility','SmartNav scanning','Tangle-free swivel','Top-loading filter','Waterline scrubbing'],
   '{"pool_size_max_ft": 50, "cable_length_ft": 60, "filtration_microns": 2, "cycle_time_hours": 2, "wall_climbing": true, "waterline_scrubbing": true}',
   'https://www.maytronics.com/us/dolphin-triton-ps-plus'),
  ('99996148-XP', 'Dolphin Sigma', 'Dolphin Sigma', 5, true, 1500,
   ARRAY['WiFi app control','Gyroscope navigation','Triple motors','Extra-large filtration basket','Weekly scheduler'],
   '{"pool_size_max_ft": 50, "cable_length_ft": 60, "filtration_microns": 2, "cycle_time_hours": 3, "wall_climbing": true, "waterline_scrubbing": true, "app_control": true, "triple_motor": true}',
   'https://www.maytronics.com/us/dolphin-sigma'),
  ('99996280-USF', 'Dolphin Explorer E70', 'Dolphin Explorer', 5, true, 1100,
   ARRAY['WiFi app control','CleverClean Plus','LED indicator','Top-loading filter','Easy maintenance'],
   '{"pool_size_max_ft": 50, "cable_length_ft": 60, "filtration_microns": 2, "cycle_time_hours": 2.5, "wall_climbing": true, "waterline_scrubbing": true, "app_control": true}',
   'https://www.maytronics.com/us/dolphin-explorer-e70'),
  ('99996281-USF', 'Dolphin Explorer E50', 'Dolphin Explorer', 5, false, 900,
   ARRAY['CleverClean navigation','Wall climbing','Top-loading filter','Plug-and-play setup'],
   '{"pool_size_max_ft": 40, "cable_length_ft": 50, "filtration_microns": 2, "cycle_time_hours": 2, "wall_climbing": true, "waterline_scrubbing": false}',
   'https://www.maytronics.com/us/dolphin-explorer-e50'),
  ('99996231-USF', 'Dolphin Escape', 'Dolphin Escape', 5, false, 700,
   ARRAY['Above-ground pool cleaner','HyperBrush system','SmartNav navigation','Floor and wall cleaning'],
   '{"pool_size_max_ft": 33, "cable_length_ft": 40, "filtration_microns": 2, "cycle_time_hours": 1.5, "wall_climbing": true, "waterline_scrubbing": false, "above_ground": true}',
   'https://www.maytronics.com/us/dolphin-escape')
) AS v(model_number, model_name, series, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'maytronics' AND c.slug = 'pool-cleaner';


-- ============================================================================
-- POLARIS (Pressure-Side Cleaner Specialist) - 8 models
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', v.install, NULL, NULL, NULL, true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('F9550', 'Polaris 9550 Sport Robotic Cleaner', '9000 Series', 'in-ground', 5, true, 1400,
   ARRAY['4WD robotic cleaner','Aqua-Trax tires','Vortex vacuum','App control','7-day scheduler','Motion-sensing remote'],
   '{"pool_size_max_ft": 60, "cable_length_ft": 70, "filtration_microns": 2, "cycle_time_hours": 3, "wall_climbing": true, "app_control": true, "four_wheel_drive": true}',
   'https://www.polaris.com/en-us/pool-cleaners/robotic/9550-sport'),
  ('F9450', 'Polaris 9450 Sport Robotic Cleaner', '9000 Series', 'in-ground', 5, true, 1200,
   ARRAY['4WD robotic cleaner','Aqua-Trax tires','Vortex vacuum','App control','Weekly scheduler'],
   '{"pool_size_max_ft": 50, "cable_length_ft": 60, "filtration_microns": 2, "cycle_time_hours": 2.5, "wall_climbing": true, "app_control": true, "four_wheel_drive": true}',
   'https://www.polaris.com/en-us/pool-cleaners/robotic/9450-sport'),
  ('F9350', 'Polaris 9350 Sport Robotic Cleaner', '9000 Series', 'in-ground', 5, false, 900,
   ARRAY['2WD robotic cleaner','Aqua-Trax tires','Vortex vacuum','Easy lift system'],
   '{"pool_size_max_ft": 50, "cable_length_ft": 60, "filtration_microns": 2, "cycle_time_hours": 2.5, "wall_climbing": true}',
   'https://www.polaris.com/en-us/pool-cleaners/robotic/9350-sport'),
  ('F945', 'Polaris P945 Pressure Cleaner', 'P900 Series', 'in-ground', 5, false, 700,
   ARRAY['Pressure-side cleaner','All-wheel drive','5-liter debris bag','PosiDrive system','No booster pump needed'],
   '{"pool_size_max_ft": 50, "type": "pressure_side", "debris_bag_liters": 5, "booster_pump_required": false}',
   'https://www.polaris.com/en-us/pool-cleaners/pressure/p945'),
  ('F39', 'Polaris P39 Pressure Cleaner', 'P30 Series', 'in-ground', 5, false, 500,
   ARRAY['Pressure-side cleaner','Triple jet sweep','All-purpose bag','Universal wall fitting'],
   '{"pool_size_max_ft": 40, "type": "pressure_side", "booster_pump_required": false}',
   'https://www.polaris.com/en-us/pool-cleaners/pressure/p39'),
  ('F380', 'Polaris 380 Pressure Cleaner', '380 Series', 'in-ground', 5, false, 900,
   ARRAY['Pressure-side cleaner','Triple jet propulsion','Dedicated booster pump','All-purpose zippered bag','Belt drive'],
   '{"pool_size_max_ft": 50, "type": "pressure_side", "booster_pump_required": true, "belt_drive": true}',
   'https://www.polaris.com/en-us/pool-cleaners/pressure/380'),
  ('F360', 'Polaris 360 Pressure Cleaner', '360 Series', 'in-ground', 5, false, 600,
   ARRAY['Pressure-side cleaner','No booster pump needed','Triple jets','Belt drive'],
   '{"pool_size_max_ft": 40, "type": "pressure_side", "booster_pump_required": false, "belt_drive": true}',
   'https://www.polaris.com/en-us/pool-cleaners/pressure/360'),
  ('165', 'Polaris 165 Above Ground Pressure', '100 Series', 'above-ground', 5, false, 350,
   ARRAY['Pressure-side cleaner','Above-ground pools','Easy installation','Single jet'],
   '{"pool_size_max_ft": 33, "type": "pressure_side", "booster_pump_required": false, "above_ground": true}',
   'https://www.polaris.com/en-us/pool-cleaners/pressure/165')
) AS v(model_number, model_name, series, install, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'polaris-pool' AND c.slug = 'pool-cleaner';


-- ============================================================================
-- ZODIAC (Cleaners & Multi-Category) - 10 models
-- ============================================================================

-- Zodiac Suction-Side Cleaners
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'in-ground', NULL, NULL, NULL, true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('W70671', 'MX6 EL Suction Side Cleaner', 'MX Series', 5, false, 350,
   ARRAY['Suction-side cleaner','Cyclonic scrubbing','Low-flow design','X-Drive navigation','No booster pump'],
   '{"pool_size_max_ft": 40, "type": "suction_side", "booster_pump_required": false, "cyclonic_action": true}',
   'https://www.zodiacpoolsystems.com/en/products/cleaners/mx6-el'),
  ('W83278', 'MX8 Elite Suction Side Cleaner', 'MX Series', 5, false, 500,
   ARRAY['Suction-side cleaner','X-Drive dual cyclonic','Max-Drive tracks','Flex power turbine','Superior climbing'],
   '{"pool_size_max_ft": 50, "type": "suction_side", "booster_pump_required": false, "cyclonic_action": true, "track_drive": true}',
   'https://www.zodiacpoolsystems.com/en/products/cleaners/mx8-elite'),
  ('W78147', 'Baracuda G3 Suction Side Cleaner', 'Baracuda', 5, false, 250,
   ARRAY['Suction-side cleaner','Diaphragm-driven','FlowKeeper valve','Quiet operation','Long hose'],
   '{"pool_size_max_ft": 40, "type": "suction_side", "booster_pump_required": false}',
   'https://www.zodiacpoolsystems.com/en/products/cleaners/baracuda-g3'),
  ('W70674', 'T5 Duo Suction Side Cleaner', 'T-Series', 5, false, 400,
   ARRAY['Suction-side cleaner','Patented Twist Lock hose','FlowKeeper valve','Extra-large debris intake'],
   '{"pool_size_max_ft": 50, "type": "suction_side", "booster_pump_required": false, "large_debris": true}',
   'https://www.zodiacpoolsystems.com/en/products/cleaners/t5-duo')
) AS v(model_number, model_name, series, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'zodiac-pool' AND c.slug = 'pool-cleaner';

-- Zodiac Pumps
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'in-ground', NULL, v.cap, 'hp', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('VS-FHP270DV', 'FloPro VS 2.7HP Variable Speed', 'FloPro', 2.7, 10, true, true, 1800,
   ARRAY['Variable speed','2.7 THP','Energy Star','Dual voltage','Programmable speeds'],
   '{"hp": 2.7, "flow_gpm": 145, "voltage": 230, "variable_speed": true, "speed_settings": 8, "pool_size_max_gallons": 40000}',
   'https://www.zodiacpoolsystems.com/en/products/pumps/flopro-vs'),
  ('VS-FHP165DV', 'FloPro VS 1.65HP Variable Speed', 'FloPro', 1.65, 10, true, true, 1300,
   ARRAY['Variable speed','1.65 THP','Energy Star','Compact design','Easy retrofit'],
   '{"hp": 1.65, "flow_gpm": 90, "voltage": 115, "variable_speed": true, "speed_settings": 8, "pool_size_max_gallons": 25000}',
   'https://www.zodiacpoolsystems.com/en/products/pumps/flopro-vs')
) AS v(model_number, model_name, series, cap, lifespan, wifi, estar, msrp, features, specs, url)
WHERE m.slug = 'zodiac-pool' AND c.slug = 'pool-pump';

-- Zodiac Salt Chlorine Generators
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'in-ground', NULL, v.cap, 'gallons', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('EI35PRO', 'Ei Terrain 35K Salt Chlorinator', 'Ei Terrain', 35000, 5, true, 1200,
   ARRAY['35K gallon capacity','Self-cleaning cell','iAqualink compatible','Digital display','Easy installation'],
   '{"max_gallons": 35000, "cell_type": "titanium", "self_cleaning": true, "chlorine_output_lbs_day": 1.2}',
   'https://www.zodiacpoolsystems.com/en/products/sanitization/ei-terrain'),
  ('EI25PRO', 'Ei Terrain 25K Salt Chlorinator', 'Ei Terrain', 25000, 5, true, 1000,
   ARRAY['25K gallon capacity','Self-cleaning cell','Compact control box','Digital interface'],
   '{"max_gallons": 25000, "cell_type": "titanium", "self_cleaning": true, "chlorine_output_lbs_day": 0.85}',
   'https://www.zodiacpoolsystems.com/en/products/sanitization/ei-terrain'),
  ('LM2-40', 'LM2 40K Salt Chlorinator', 'LM2 Series', 40000, 5, false, 1100,
   ARRAY['40K gallon capacity','Reverse polarity self-cleaning','LED diagnostics','Proven reliability'],
   '{"max_gallons": 40000, "cell_type": "titanium", "self_cleaning": true, "chlorine_output_lbs_day": 1.4}',
   'https://www.zodiacpoolsystems.com/en/products/sanitization/lm2'),
  ('LM2-24', 'LM2 24K Salt Chlorinator', 'LM2 Series', 24000, 5, false, 800,
   ARRAY['24K gallon capacity','Self-cleaning cell','LED status indicators','Budget-friendly salt'],
   '{"max_gallons": 24000, "cell_type": "titanium", "self_cleaning": true, "chlorine_output_lbs_day": 0.8}',
   'https://www.zodiacpoolsystems.com/en/products/sanitization/lm2')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'zodiac-pool' AND c.slug = 'salt-chlorine-generator';


-- ============================================================================
-- AUTOPILOT (Salt Chlorine Specialist) - 6 models
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'in-ground', NULL, v.cap, 'gallons', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DNP2', 'Digital Nano Plus 28K', 'Digital Nano Plus', 28000, 5, false, 800,
   ARRAY['28K gallon capacity','Digital display','Easy installation','Self-cleaning cell','Budget-friendly'],
   '{"max_gallons": 28000, "cell_type": "titanium", "self_cleaning": true, "chlorine_output_lbs_day": 0.9}',
   'https://www.autopilot.com/product/digital-nano-plus'),
  ('SC-48', 'Pool Pilot Digital SC-48', 'Pool Pilot Digital', 40000, 5, false, 1300,
   ARRAY['40K gallon capacity','Digital controls','Manifold cell','Self-cleaning','Salt display'],
   '{"max_gallons": 40000, "cell_type": "titanium", "self_cleaning": true, "chlorine_output_lbs_day": 1.47}',
   'https://www.autopilot.com/product/pool-pilot-digital'),
  ('SC-36', 'Pool Pilot Digital SC-36', 'Pool Pilot Digital', 30000, 5, false, 1100,
   ARRAY['30K gallon capacity','Digital controls','Self-cleaning cell','Easy maintenance'],
   '{"max_gallons": 30000, "cell_type": "titanium", "self_cleaning": true, "chlorine_output_lbs_day": 1.1}',
   'https://www.autopilot.com/product/pool-pilot-digital'),
  ('PP-SALT', 'Pool Pilot Professional 60K', 'Pool Pilot Professional', 60000, 5, false, 1800,
   ARRAY['60K gallon capacity','Professional grade','Commercial-residential','High output','Digital readout'],
   '{"max_gallons": 60000, "cell_type": "titanium", "self_cleaning": true, "chlorine_output_lbs_day": 2.0}',
   'https://www.autopilot.com/product/pool-pilot-professional'),
  ('TC-RC35', 'Total Control RC-35', 'Total Control', 35000, 5, true, 1500,
   ARRAY['35K gallon capacity','App control','Remote monitoring','ORP sensing','Salt/temp display'],
   '{"max_gallons": 35000, "cell_type": "titanium", "self_cleaning": true, "chlorine_output_lbs_day": 1.2, "orp_sensing": true}',
   'https://www.autopilot.com/product/total-control'),
  ('TC-RC52', 'Total Control RC-52', 'Total Control', 52000, 5, true, 1900,
   ARRAY['52K gallon capacity','App control','Remote monitoring','ORP sensing','High output'],
   '{"max_gallons": 52000, "cell_type": "titanium", "self_cleaning": true, "chlorine_output_lbs_day": 1.8, "orp_sensing": true}',
   'https://www.autopilot.com/product/total-control')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'autopilot' AND c.slug = 'salt-chlorine-generator';


-- ============================================================================
-- CIRCUPOOL (Salt Chlorine Specialist) - 6 models
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', v.install, NULL, v.cap, 'gallons', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('RJ-45+', 'RJ-45 Plus Salt Chlorinator', 'RJ Plus', 'in-ground', 45000, 5, true, 900,
   ARRAY['45K gallon capacity','WiFi app control','Self-cleaning cell','Flow sensor','Real-time monitoring'],
   '{"max_gallons": 45000, "cell_type": "titanium", "self_cleaning": true, "chlorine_output_lbs_day": 1.5, "flow_sensor": true}',
   'https://www.circupool.com/products/rj-plus-salt-chlorinator'),
  ('RJ-30+', 'RJ-30 Plus Salt Chlorinator', 'RJ Plus', 'in-ground', 30000, 5, true, 750,
   ARRAY['30K gallon capacity','WiFi app control','Self-cleaning cell','Flow sensor','Budget-friendly'],
   '{"max_gallons": 30000, "cell_type": "titanium", "self_cleaning": true, "chlorine_output_lbs_day": 1.0, "flow_sensor": true}',
   'https://www.circupool.com/products/rj-plus-salt-chlorinator'),
  ('RJ-16+', 'RJ-16 Plus Salt Chlorinator', 'RJ Plus', 'in-ground', 16000, 5, true, 600,
   ARRAY['16K gallon capacity','WiFi app control','Self-cleaning cell','Compact design'],
   '{"max_gallons": 16000, "cell_type": "titanium", "self_cleaning": true, "chlorine_output_lbs_day": 0.55}',
   'https://www.circupool.com/products/rj-plus-salt-chlorinator'),
  ('SJ-40', 'SJ-40 Salt Chlorinator', 'SJ Series', 'in-ground', 40000, 5, false, 700,
   ARRAY['40K gallon capacity','Self-cleaning cell','Digital display','Easy installation','Value leader'],
   '{"max_gallons": 40000, "cell_type": "titanium", "self_cleaning": true, "chlorine_output_lbs_day": 1.4}',
   'https://www.circupool.com/products/sj-salt-chlorinator'),
  ('SJ-20', 'SJ-20 Salt Chlorinator', 'SJ Series', 'in-ground', 20000, 5, false, 500,
   ARRAY['20K gallon capacity','Self-cleaning cell','Digital display','Compact control box'],
   '{"max_gallons": 20000, "cell_type": "titanium", "self_cleaning": true, "chlorine_output_lbs_day": 0.7}',
   'https://www.circupool.com/products/sj-salt-chlorinator'),
  ('EDGE-40', 'Edge 40 Salt Chlorinator', 'Edge', 'above-ground', 40000, 5, true, 650,
   ARRAY['40K gallon capacity','WiFi control','Works with above-ground pools','Plug-and-play','No plumbing'],
   '{"max_gallons": 40000, "cell_type": "titanium", "self_cleaning": true, "chlorine_output_lbs_day": 1.4, "above_ground": true}',
   'https://www.circupool.com/products/edge-salt-chlorinator')
) AS v(model_number, model_name, series, install, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'circupool' AND c.slug = 'salt-chlorine-generator';


-- ============================================================================
-- INTEX (Budget/Above-Ground) - 12 models
-- ============================================================================

-- Intex Pumps
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'above-ground', NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('26679EG', 'Krystal Clear 2150 GPH Sand Filter Pump', 'Krystal Clear', 2150.0, 'gph', 5, 250,
   ARRAY['Sand filter pump combo','2150 GPH flow rate','6-function valve','GFCI plug','Pre-programmed timer'],
   '{"hp": 0.5, "flow_gpm": 36, "voltage": 115, "variable_speed": false, "pool_size_max_gallons": 16000, "filter_included": true}',
   'https://www.intexcorp.com/pools/pool-pumps/krystal-clear-sand-filter-pump-2150-gph.html'),
  ('28637EG', 'Krystal Clear 1000 GPH Cartridge Filter Pump', 'Krystal Clear', 1000.0, 'gph', 3, 80,
   ARRAY['Cartridge filter pump','1000 GPH','GFCI plug','Easy setup','Type A/C filter'],
   '{"hp": 0.25, "flow_gpm": 17, "voltage": 115, "variable_speed": false, "pool_size_max_gallons": 6000, "filter_included": true}',
   'https://www.intexcorp.com/pools/pool-pumps/krystal-clear-cartridge-filter-pump-1000-gph.html'),
  ('28633EG', 'Krystal Clear 2500 GPH Cartridge Filter Pump', 'Krystal Clear', 2500.0, 'gph', 3, 120,
   ARRAY['Cartridge filter pump','2500 GPH','GFCI plug','Timer','Type B filter'],
   '{"hp": 0.5, "flow_gpm": 42, "voltage": 115, "variable_speed": false, "pool_size_max_gallons": 16800, "filter_included": true}',
   'https://www.intexcorp.com/pools/pool-pumps/krystal-clear-cartridge-filter-pump-2500-gph.html'),
  ('26651EG', 'Krystal Clear 3000 GPH Sand Filter Pump', 'Krystal Clear', 3000.0, 'gph', 5, 350,
   ARRAY['Sand filter pump combo','3000 GPH','6-function valve','24-hour timer','GFCI plug'],
   '{"hp": 0.75, "flow_gpm": 50, "voltage": 115, "variable_speed": false, "pool_size_max_gallons": 22000, "filter_included": true}',
   'https://www.intexcorp.com/pools/pool-pumps/krystal-clear-sand-filter-pump-3000-gph.html')
) AS v(model_number, model_name, series, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'intex' AND c.slug = 'pool-pump';

-- Intex Heaters
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'above-ground', NULL, v.cap, 'btu', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('28684E', 'Electric Pool Heater for Above Ground Pools', 'Intex Heater', 3000, 5, 160,
   ARRAY['Electric heater','For above-ground pools','Thermostat control','GFCI plug','Easy hookup'],
   '{"btu": 3000, "efficiency_pct": 95, "pool_size_max_gallons": 2600, "type": "electric_resistance", "voltage": 115}',
   'https://www.intexcorp.com/pools/pool-heaters/electric-pool-heater.html'),
  ('28685E', 'Solar Heater Mat for Above Ground Pools', 'Intex Solar Mat', 0, 3, 50,
   ARRAY['Solar heating mat','Passive solar','No electricity needed','Easy setup','Eco-friendly'],
   '{"btu": 0, "type": "solar_mat", "pool_size_max_gallons": 8000, "solar_collector_area_sqft": 47}',
   'https://www.intexcorp.com/pools/pool-heaters/solar-heater-mat.html')
) AS v(model_number, model_name, series, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'intex' AND c.slug = 'pool-heater';

-- Intex Salt Systems
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'above-ground', NULL, v.cap, 'gallons', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('26669EG', 'Krystal Clear ECO 15K Saltwater System', 'Krystal Clear', 15000, 3, 250,
   ARRAY['15K gallon capacity','E.C.O. electrocatalytic oxidation','Self-cleaning','GFCI plug','Above-ground pools'],
   '{"max_gallons": 15000, "cell_type": "titanium", "self_cleaning": true, "chlorine_output_lbs_day": 0.53, "above_ground": true}',
   'https://www.intexcorp.com/pools/pool-sanitization/krystal-clear-saltwater-system.html'),
  ('26667EG', 'Krystal Clear ECO 5K Saltwater System', 'Krystal Clear', 5000, 3, 150,
   ARRAY['5K gallon capacity','E.C.O. technology','GFCI plug','For small above-ground pools'],
   '{"max_gallons": 5000, "cell_type": "titanium", "self_cleaning": true, "chlorine_output_lbs_day": 0.18, "above_ground": true}',
   'https://www.intexcorp.com/pools/pool-sanitization/krystal-clear-saltwater-system.html')
) AS v(model_number, model_name, series, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'intex' AND c.slug = 'salt-chlorine-generator';

-- Intex Cleaners
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'above-ground', NULL, NULL, NULL, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('28005E', 'ZX300 Deluxe Automatic Pool Cleaner', 'ZX Series', 3, 200,
   ARRAY['Auto pool cleaner','Venturi suction','For above-ground pools','21 ft hose','Easy connect'],
   '{"pool_size_max_ft": 24, "type": "suction_side", "hose_length_ft": 21, "above_ground": true}',
   'https://www.intexcorp.com/pools/pool-cleaners/zx300-deluxe-automatic-pool-cleaner.html'),
  ('28001E', 'Auto Pool Cleaner', 'Intex Auto', 3, 100,
   ARRAY['Automatic pool cleaner','For above-ground Intex pools','Connects to filter pump','Simple setup'],
   '{"pool_size_max_ft": 20, "type": "suction_side", "above_ground": true}',
   'https://www.intexcorp.com/pools/pool-cleaners/auto-pool-cleaner.html'),
  ('28620E', 'Rechargeable Handheld Pool Vacuum', 'Intex Handheld', 2, 60,
   ARRAY['Rechargeable battery','Handheld vacuum','Telescoping shaft','For small debris','Portable'],
   '{"type": "handheld", "battery_powered": true, "above_ground": true}',
   'https://www.intexcorp.com/pools/pool-cleaners/rechargeable-handheld-vacuum.html'),
  ('29057E', 'Pool Maintenance Kit', 'Intex Maintenance', 2, 40,
   ARRAY['Leaf skimmer','Wall brush','Vacuum head','Telescoping pole','All-in-one kit'],
   '{"type": "manual_kit", "above_ground": true, "includes": ["leaf_skimmer", "wall_brush", "vacuum_head", "pole"]}',
   'https://www.intexcorp.com/pools/pool-cleaners/pool-maintenance-kit.html')
) AS v(model_number, model_name, series, lifespan, msrp, features, specs, url)
WHERE m.slug = 'intex' AND c.slug = 'pool-cleaner';


-- ============================================================================
-- INTERMATIC (Timers & Automation) - 10 models
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'in-ground', NULL, v.cap, 'zones', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('PE653', 'MultiWave 5-Circuit Pool Control', 'MultiWave', 5, 12, true, 1200,
   ARRAY['5-circuit wireless control','App control','Z-Wave compatible','Wireless remote','Retrofit-friendly'],
   '{"zones": 5, "supports_salt": false, "supports_heater": true, "app_control": true, "z_wave": true, "wireless_remote": true}',
   'https://www.intermatic.com/pool-spa/electronic-controls/multiwave'),
  ('PE653RC', 'MultiWave Receiver with 5 Circuits', 'MultiWave', 5, 12, true, 900,
   ARRAY['5-circuit receiver','Z-Wave wireless','Integrates with PE653','Add-on module'],
   '{"zones": 5, "supports_salt": false, "supports_heater": true, "app_control": true, "z_wave": true}',
   'https://www.intermatic.com/pool-spa/electronic-controls/multiwave'),
  ('P1353ME', 'Pool/Spa Portable Timer', 'P1000 Series', 1, 10, false, 40,
   ARRAY['Plug-in timer','3-conductor','24-hour mechanical','Heavy-duty','GFCI compatible'],
   '{"zones": 1, "supports_salt": false, "supports_heater": false, "app_control": false, "timer_type": "mechanical_24hr"}',
   'https://www.intermatic.com/pool-spa/mechanical-timers/p1353me'),
  ('T104M', 'Mechanical Time Switch 24-Hour', 'T100 Series', 1, 15, false, 80,
   ARRAY['24-hour mechanical timer','Heavy-duty contacts','DPST switch','Indoor/outdoor enclosure','Industry standard'],
   '{"zones": 1, "supports_salt": false, "supports_heater": true, "app_control": false, "timer_type": "mechanical_24hr", "amperage": 40}',
   'https://www.intermatic.com/pool-spa/mechanical-timers/t104m'),
  ('T101R', 'Mechanical Time Switch 24-Hour SPST', 'T100 Series', 1, 15, false, 60,
   ARRAY['24-hour mechanical timer','SPST switch','Compact enclosure','Reliable operation'],
   '{"zones": 1, "supports_salt": false, "supports_heater": false, "app_control": false, "timer_type": "mechanical_24hr", "amperage": 20}',
   'https://www.intermatic.com/pool-spa/mechanical-timers/t101r'),
  ('PF1103T', 'Freeze Protection Timer', 'PF Series', 1, 10, false, 120,
   ARRAY['Freeze protection','Thermostat-controlled','24-hour timer','DPST switch','Prevents freeze damage'],
   '{"zones": 1, "supports_salt": false, "supports_heater": false, "app_control": false, "timer_type": "freeze_protection", "freeze_temp_f": 38}',
   'https://www.intermatic.com/pool-spa/freeze-protection/pf1103t'),
  ('PE24VA', 'Valve Actuator 24V', 'PE Series', 1, 10, false, 180,
   ARRAY['24V valve actuator','180-degree rotation','Weatherproof','For diverter valves','Works with automation'],
   '{"zones": 1, "supports_salt": false, "supports_heater": false, "app_control": false, "valve_actuator": true, "voltage": 24, "rotation_degrees": 180}',
   'https://www.intermatic.com/pool-spa/valve-actuators/pe24va'),
  ('P4043ME', 'Pool Pump Timer Two-Speed', 'P4000 Series', 2, 10, false, 130,
   ARRAY['Two-speed pump timer','Dual circuit','24-hour clock','DPST contacts','For dual-speed pumps'],
   '{"zones": 2, "supports_salt": false, "supports_heater": false, "app_control": false, "timer_type": "mechanical_24hr", "dual_speed": true}',
   'https://www.intermatic.com/pool-spa/mechanical-timers/p4043me'),
  ('ET8215C', 'Digital Electronic Timer 2-Circuit', 'ET Series', 2, 12, false, 200,
   ARRAY['Digital electronic timer','2 independent circuits','7-day programming','Astronomic feature','Battery backup'],
   '{"zones": 2, "supports_salt": false, "supports_heater": true, "app_control": false, "timer_type": "digital_7day", "astronomic": true}',
   'https://www.intermatic.com/pool-spa/electronic-timers/et8215c'),
  ('ET1125C', 'Digital Electronic Timer 1-Circuit', 'ET Series', 1, 12, false, 160,
   ARRAY['Digital electronic timer','1 circuit','7-day programming','Astronomic feature','Battery backup'],
   '{"zones": 1, "supports_salt": false, "supports_heater": true, "app_control": false, "timer_type": "digital_7day", "astronomic": true}',
   'https://www.intermatic.com/pool-spa/electronic-timers/et1125c')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'intermatic' AND c.slug = 'pool-automation';


-- ============================================================================
-- ADDITIONAL PENTAIR CLEANERS - 4 models
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'in-ground', NULL, NULL, NULL, true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('360228', 'Warrior SE Robotic Cleaner', 'Warrior', 5, true, 1200,
   ARRAY['Robotic cleaner','SmartClean technology','App control','Wall and waterline cleaning','Easy-access filtration'],
   '{"pool_size_max_ft": 50, "cable_length_ft": 60, "filtration_microns": 2, "cycle_time_hours": 3, "wall_climbing": true, "waterline_scrubbing": true, "app_control": true}',
   'https://www.pentair.com/en-us/products/residential/pool-spa-equipment/pool-cleaners/warrior-se-robotic-cleaner.html'),
  ('360240', 'Warrior SI Robotic Cleaner', 'Warrior', 5, false, 900,
   ARRAY['Robotic cleaner','SmartClean technology','Floor and wall cleaning','Top-loading filter'],
   '{"pool_size_max_ft": 40, "cable_length_ft": 50, "filtration_microns": 2, "cycle_time_hours": 2.5, "wall_climbing": true, "waterline_scrubbing": false}',
   'https://www.pentair.com/en-us/products/residential/pool-spa-equipment/pool-cleaners/warrior-si-robotic-cleaner.html'),
  ('360042', 'Kreepy Krauly Suction Cleaner', 'Kreepy Krauly', 5, false, 300,
   ARRAY['Suction-side cleaner','No booster pump needed','Single moving part','Proven design','Quiet operation'],
   '{"pool_size_max_ft": 40, "type": "suction_side", "booster_pump_required": false}',
   'https://www.pentair.com/en-us/products/residential/pool-spa-equipment/pool-cleaners/kreepy-krauly-suction-cleaner.html'),
  ('360302', 'Prowler 930 Robotic Cleaner', 'Prowler', 5, true, 1500,
   ARRAY['Robotic cleaner','WiFi app control','Wall climbing','Caddy included','Multi-layer filtration','Weekly scheduler'],
   '{"pool_size_max_ft": 50, "cable_length_ft": 60, "filtration_microns": 2, "cycle_time_hours": 3, "wall_climbing": true, "waterline_scrubbing": true, "app_control": true}',
   'https://www.pentair.com/en-us/products/residential/pool-spa-equipment/pool-cleaners/prowler-930-robotic-cleaner.html')
) AS v(model_number, model_name, series, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'pentair' AND c.slug = 'pool-cleaner';


-- ============================================================================
-- ADDITIONAL HAYWARD CLEANERS - 5 models
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'in-ground', NULL, NULL, NULL, true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('W3RC9742CUBY', 'AquaVac 6 Series Robotic Cleaner', 'AquaVac', 5, true, 1300,
   ARRAY['Robotic cleaner','WiFi app control','Wall climbing','Top-loading filter','4WD traction','Voice control'],
   '{"pool_size_max_ft": 50, "cable_length_ft": 60, "filtration_microns": 2, "cycle_time_hours": 3, "wall_climbing": true, "waterline_scrubbing": true, "app_control": true}',
   'https://www.hayward.com/shop/products/cleaners/aquavac-6-series'),
  ('W3RC9740CUB', 'AquaVac 5 Series Robotic Cleaner', 'AquaVac', 5, true, 1100,
   ARRAY['Robotic cleaner','App control','Floor wall waterline','Smart steering','Easy lift caddy'],
   '{"pool_size_max_ft": 50, "cable_length_ft": 60, "filtration_microns": 2, "cycle_time_hours": 3, "wall_climbing": true, "waterline_scrubbing": true, "app_control": true}',
   'https://www.hayward.com/shop/products/cleaners/aquavac-5-series'),
  ('W3PVS20GST', 'PoolVac V-Flex Suction Cleaner', 'PoolVac', 5, false, 400,
   ARRAY['Suction-side cleaner','V-Flex variable turbine','AquaPilot navigation','Adjustable flow'],
   '{"pool_size_max_ft": 40, "type": "suction_side", "booster_pump_required": false, "variable_turbine": true}',
   'https://www.hayward.com/shop/products/cleaners/poolvac-v-flex'),
  ('W3PHS41CST', 'Navigator Pro Suction Cleaner', 'Navigator', 5, false, 350,
   ARRAY['Suction-side cleaner','SmartDrive programming','Self-adjusting turbine','Concrete and vinyl safe'],
   '{"pool_size_max_ft": 40, "type": "suction_side", "booster_pump_required": false}',
   'https://www.hayward.com/shop/products/cleaners/navigator-pro'),
  ('W3TVP500C', 'TracVac Pressure Side Cleaner', 'TracVac', 5, false, 700,
   ARRAY['Pressure-side cleaner','Programmable steering','Large debris bag','No booster pump needed'],
   '{"pool_size_max_ft": 50, "type": "pressure_side", "booster_pump_required": false, "debris_bag_liters": 4.5}',
   'https://www.hayward.com/shop/products/cleaners/tracvac-pressure-cleaner')
) AS v(model_number, model_name, series, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'hayward' AND c.slug = 'pool-cleaner';


-- ============================================================================
-- ADDITIONAL PENTAIR FILTERS - 2 more models
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'in-ground', NULL, v.cap, 'sq_ft', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('160316', 'Clean & Clear 150 Cartridge Filter', 'Clean & Clear', 150, 8, 550,
   ARRAY['150 sq ft filtration area','Compact design','Low maintenance','Easy cartridge removal'],
   '{"sq_ft": 150, "flow_rate_gpm": 60, "filter_type": "cartridge", "tank_diameter": 19, "pool_size_max_gallons": 15000}',
   'https://www.pentair.com/en-us/products/residential/pool-spa-equipment/pool-filters/clean-clear-cartridge-filter.html'),
  ('145220', 'Triton II TR60 Sand Filter', 'Triton II', 60, 10, 500,
   ARRAY['Fiberglass-reinforced tank','Top-mount multiport valve','Corrosion resistant','Mid-size pools'],
   '{"sq_ft": 60, "flow_rate_gpm": 60, "filter_type": "sand", "tank_diameter": 24, "pool_size_max_gallons": 30000}',
   'https://www.pentair.com/en-us/products/residential/pool-spa-equipment/pool-filters/triton-ii-sand-filter.html')
) AS v(model_number, model_name, series, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'pentair' AND c.slug = 'pool-filter';


-- ============================================================================
-- ADDITIONAL HAYWARD FILTERS - 2 more models
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'in-ground', NULL, v.cap, 'sq_ft', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('C48002', 'SwimClear C480 Cartridge Filter', 'SwimClear', 480, 8, 1000,
   ARRAY['480 sq ft filtration area','Four-element design','Extended cleaning cycles','Heavy-duty clamp'],
   '{"sq_ft": 480, "flow_rate_gpm": 150, "filter_type": "cartridge", "tank_diameter": 24, "pool_size_max_gallons": 48000}',
   'https://www.hayward.com/shop/products/filters/swimclear-cartridge-filters'),
  ('W3S244T2', 'Pro-Series S244T2 Sand Filter', 'Pro-Series', 75, 10, 550,
   ARRAY['Top-mount valve','Fiberglass tank','24-inch diameter','Self-cleaning laterals'],
   '{"sq_ft": 75, "flow_rate_gpm": 62, "filter_type": "sand", "tank_diameter": 24, "pool_size_max_gallons": 22000}',
   'https://www.hayward.com/shop/products/filters/pro-series-sand-filter')
) AS v(model_number, model_name, series, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'hayward' AND c.slug = 'pool-filter';


-- ============================================================================
-- ADDITIONAL JANDY CLEANERS - 3 models
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'in-ground', NULL, NULL, NULL, true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('CNX4020IQDTL', 'TruClean Robotic Cleaner', 'TruClean', 5, true, 1600,
   ARRAY['Robotic cleaner','iAqualink app control','Dual scrub brushes','Floor wall waterline','Caddy included'],
   '{"pool_size_max_ft": 60, "cable_length_ft": 70, "filtration_microns": 2, "cycle_time_hours": 3, "wall_climbing": true, "waterline_scrubbing": true, "app_control": true}',
   'https://www.jandy.com/en/products/cleaners/truclean-robotic-cleaner'),
  ('W20800ADV', 'Ray-Vac Energy Suction Cleaner', 'Ray-Vac', 5, false, 300,
   ARRAY['Suction-side cleaner','Low-flow operation','Self-adjusting','Floor and wall cleaning'],
   '{"pool_size_max_ft": 40, "type": "suction_side", "booster_pump_required": false, "low_flow": true}',
   'https://www.jandy.com/en/products/cleaners/ray-vac-energy-suction-cleaner'),
  ('F-5B', 'Polaris 280 Pressure Cleaner', '280 Series', 5, false, 600,
   ARRAY['Pressure-side cleaner','Dual jets','All-purpose bag','Belt drive','Booster pump included'],
   '{"pool_size_max_ft": 40, "type": "pressure_side", "booster_pump_required": true, "belt_drive": true}',
   'https://www.jandy.com/en/products/cleaners/polaris-280')
) AS v(model_number, model_name, series, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'jandy' AND c.slug = 'pool-cleaner';


-- ============================================================================
-- ADDITIONAL MODELS TO REACH 200+ TARGET
-- ============================================================================

-- Additional Pentair Pumps (above-ground)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'above-ground', NULL, v.cap, 'hp', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('340210', 'OptiFlo 1HP Above Ground Pump', 'OptiFlo', 1.0, 6, 300,
   ARRAY['Above-ground pump','Self-priming','Large strainer basket','Corrosion resistant'],
   '{"hp": 1.0, "flow_gpm": 55, "voltage": 115, "variable_speed": false, "pool_size_max_gallons": 15000}',
   'https://www.pentair.com/en-us/products/residential/pool-spa-equipment/pool-pumps/optiflo-above-ground-pump.html'),
  ('340211', 'OptiFlo 1.5HP Above Ground Pump', 'OptiFlo', 1.5, 6, 350,
   ARRAY['Above-ground pump','Self-priming','High flow','Large strainer'],
   '{"hp": 1.5, "flow_gpm": 70, "voltage": 115, "variable_speed": false, "pool_size_max_gallons": 18000}',
   'https://www.pentair.com/en-us/products/residential/pool-spa-equipment/pool-pumps/optiflo-above-ground-pump.html')
) AS v(model_number, model_name, series, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'pentair' AND c.slug = 'pool-pump';

-- Additional Hayward Pumps (above-ground)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'above-ground', NULL, v.cap, 'hp', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('W3SP1580', 'Power-Flo Matrix 1HP Above Ground', 'Power-Flo Matrix', 1.0, 6, 280,
   ARRAY['Above-ground pump','Self-priming','See-through strainer','Corrosion proof body'],
   '{"hp": 1.0, "flow_gpm": 50, "voltage": 115, "variable_speed": false, "pool_size_max_gallons": 13000}',
   'https://www.hayward.com/shop/products/pumps/power-flo-matrix'),
  ('W3SP15932S', 'Power-Flo LX 1.5HP Above Ground', 'Power-Flo LX', 1.5, 6, 350,
   ARRAY['Above-ground pump','Large strainer basket','Self-priming','High flow rate'],
   '{"hp": 1.5, "flow_gpm": 68, "voltage": 115, "variable_speed": false, "pool_size_max_gallons": 17000}',
   'https://www.hayward.com/shop/products/pumps/power-flo-lx')
) AS v(model_number, model_name, series, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'hayward' AND c.slug = 'pool-pump';

-- Additional Raypak Gas Heaters (Propane variants)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'in-ground', NULL, v.cap, 'btu', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('014949', 'Digital 336A Propane Heater', 'Digital', 'propane', 336000, 10, 2500,
   ARRAY['336K BTU','Propane fuel','Digital controls','PolyTuf finish'],
   '{"btu": 336000, "efficiency_pct": 83, "pool_size_max_gallons": 33000, "ignition": "electronic", "low_nox": true, "fuel": "propane"}',
   'https://www.raypak.com/products/pool-spa-heaters/digital-gas-heaters'),
  ('014947', 'Digital 266A Propane Heater', 'Digital', 'propane', 266000, 10, 2200,
   ARRAY['266K BTU','Propane fuel','Digital controls','Compact cabinet'],
   '{"btu": 266000, "efficiency_pct": 83, "pool_size_max_gallons": 26000, "ignition": "electronic", "low_nox": true, "fuel": "propane"}',
   'https://www.raypak.com/products/pool-spa-heaters/digital-gas-heaters'),
  ('014935', 'Digital 206A Gas Heater', 'Digital', 'gas', 199000, 10, 1800,
   ARRAY['199K BTU','Digital controls','PolyTuf finish','For medium pools and spas'],
   '{"btu": 199000, "efficiency_pct": 83, "pool_size_max_gallons": 20000, "ignition": "electronic", "low_nox": true}',
   'https://www.raypak.com/products/pool-spa-heaters/digital-gas-heaters')
) AS v(model_number, model_name, series, fuel, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'raypak' AND c.slug = 'pool-heater';

-- Additional Pentair Heaters (Propane variants)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'in-ground', NULL, v.cap, 'btu', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('461060', 'MasterTemp 400 Propane Heater', 'MasterTemp', 'propane', 400000, 10, 2900,
   ARRAY['400K BTU','Propane fuel','Hot surface ignition','Compact design','Corrosion-resistant headers'],
   '{"btu": 400000, "efficiency_pct": 84, "pool_size_max_gallons": 40000, "ignition": "hot_surface", "low_nox": true, "fuel": "propane"}',
   'https://www.pentair.com/en-us/products/residential/pool-spa-equipment/pool-heaters/mastertemp-high-performance-heater.html'),
  ('461061', 'MasterTemp 250 Propane Heater', 'MasterTemp', 'propane', 250000, 10, 2300,
   ARRAY['250K BTU','Propane fuel','Compact footprint','Hot surface ignition'],
   '{"btu": 250000, "efficiency_pct": 84, "pool_size_max_gallons": 25000, "ignition": "hot_surface", "low_nox": true, "fuel": "propane"}',
   'https://www.pentair.com/en-us/products/residential/pool-spa-equipment/pool-heaters/mastertemp-high-performance-heater.html'),
  ('460968', 'UltraTemp 120 Heat Pump', 'UltraTemp', 'electric', 120000, 12, 4000,
   ARRAY['120K BTU heat pump','ThermaFlo titanium exchanger','Ultra-quiet fan','Heating and cooling mode'],
   '{"btu": 120000, "efficiency_pct": 600, "pool_size_max_gallons": 30000, "type": "heat_pump", "cop": 6.0, "titanium_exchanger": true}',
   'https://www.pentair.com/en-us/products/residential/pool-spa-equipment/pool-heaters/ultratemp-heat-pump.html')
) AS v(model_number, model_name, series, fuel, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'pentair' AND c.slug = 'pool-heater';

-- Additional Hayward Heaters (Propane + additional heat pump)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'in-ground', NULL, v.cap, 'btu', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('W3H400FDP', 'Universal H-Series H400FD Propane', 'Universal H-Series', 'propane', 400000, 10, false, 3000,
   ARRAY['400K BTU','Propane fuel','Low NOx','Forced draft','Polymer headers'],
   '{"btu": 400000, "efficiency_pct": 83, "pool_size_max_gallons": 40000, "ignition": "hot_surface", "low_nox": true, "fuel": "propane"}',
   'https://www.hayward.com/shop/products/heating/universal-h-series-heater'),
  ('W3HP21104T', 'HeatPro 110K BTU Heat Pump', 'HeatPro', 'electric', 110000, 12, true, 3600,
   ARRAY['110K BTU heat pump','Titanium heat exchanger','Ultra Gold coating','Quiet fan design'],
   '{"btu": 110000, "efficiency_pct": 580, "pool_size_max_gallons": 28000, "type": "heat_pump", "cop": 5.8, "titanium_exchanger": true}',
   'https://www.hayward.com/shop/products/heating/heatpro-heat-pump'),
  ('W3HP50CL', 'HeatPro Compact 50K BTU Heat Pump', 'HeatPro Compact', 'electric', 50000, 12, false, 2800,
   ARRAY['50K BTU heat pump','Compact design','For smaller pools and spas','Titanium exchanger'],
   '{"btu": 50000, "efficiency_pct": 560, "pool_size_max_gallons": 12000, "type": "heat_pump", "cop": 5.6, "titanium_exchanger": true}',
   'https://www.hayward.com/shop/products/heating/heatpro-heat-pump')
) AS v(model_number, model_name, series, fuel, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'hayward' AND c.slug = 'pool-heater';

-- Additional Jandy Heaters (Propane)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'in-ground', NULL, v.cap, 'btu', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('JXI400P', 'JXi 400K BTU Propane Heater', 'JXi', 'propane', 400000, 10, true, 3300,
   ARRAY['400K BTU','Propane fuel','Low NOx','iAqualink ready','Polymer headers'],
   '{"btu": 400000, "efficiency_pct": 85, "pool_size_max_gallons": 40000, "ignition": "hot_surface", "low_nox": true, "fuel": "propane"}',
   'https://www.jandy.com/en/products/heaters/jxi-gas-heater'),
  ('JXI260P', 'JXi 260K BTU Propane Heater', 'JXi', 'propane', 260000, 10, true, 2700,
   ARRAY['260K BTU','Propane fuel','Low NOx','iAqualink ready','Compact'],
   '{"btu": 260000, "efficiency_pct": 85, "pool_size_max_gallons": 26000, "ignition": "hot_surface", "low_nox": true, "fuel": "propane"}',
   'https://www.jandy.com/en/products/heaters/jxi-gas-heater'),
  ('JE2000T', 'JE 2000 Heat Pump', 'JE Series', 'electric', 108000, 12, true, 3800,
   ARRAY['108K BTU heat pump','Titanium heat exchanger','TruHeat technology','iAqualink ready','Quiet operation'],
   '{"btu": 108000, "efficiency_pct": 580, "pool_size_max_gallons": 27000, "type": "heat_pump", "cop": 5.8, "titanium_exchanger": true}',
   'https://www.jandy.com/en/products/heaters/je-heat-pump')
) AS v(model_number, model_name, series, fuel, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'jandy' AND c.slug = 'pool-heater';


-- ============================================================================
-- ADDITIONAL PENTAIR PUMPS (Booster + Specialty) - 4 models
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'in-ground', NULL, v.cap, 'hp', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('011518', 'IntelliFlo3 VSF 3HP High Performance', 'IntelliFlo3', 3.0, 10, 2300,
   ARRAY['Variable speed and flow','High performance motor','TouchScreen interface','SmartFlow diagnostics','Drop-in replacement'],
   '{"hp": 3.0, "flow_gpm": 170, "voltage": 230, "variable_speed": true, "speed_settings": 8, "pool_size_max_gallons": 45000, "touchscreen": true}',
   'https://www.pentair.com/en-us/products/residential/pool-spa-equipment/pool-pumps/intelliflo3-vsf-variable-speed-pump.html'),
  ('LA01N', 'Booster Pump for Pressure Cleaners', 'Booster', 0.75, 8, 500,
   ARRAY['Booster pump','For pressure-side cleaners','Self-priming','Quiet operation'],
   '{"hp": 0.75, "flow_gpm": 47, "voltage": 115, "variable_speed": false, "purpose": "booster_for_cleaner"}',
   'https://www.pentair.com/en-us/products/residential/pool-spa-equipment/pool-pumps/booster-pump.html'),
  ('342001', 'WhisperFlo VST Variable Speed', 'WhisperFlo', 2.6, 10, 1600,
   ARRAY['Variable speed','Ultra quiet','Full-rated motor','Integrated timer','Large strainer basket'],
   '{"hp": 2.6, "flow_gpm": 140, "voltage": 230, "variable_speed": true, "speed_settings": 8, "pool_size_max_gallons": 35000}',
   'https://www.pentair.com/en-us/products/residential/pool-spa-equipment/pool-pumps/whisperflo-vst-variable-speed-pump.html'),
  ('011486', 'IntelliFlo i1 Variable Speed', 'IntelliFlo', 1.0, 10, 1200,
   ARRAY['Variable speed','Drop-in replacement','Single speed retrofit','Built-in timer','Energy Star'],
   '{"hp": 1.0, "flow_gpm": 60, "voltage": 115, "variable_speed": true, "speed_settings": 4, "pool_size_max_gallons": 15000}',
   'https://www.pentair.com/en-us/products/residential/pool-spa-equipment/pool-pumps/intelliflo-i1-variable-speed-pump.html')
) AS v(model_number, model_name, series, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'pentair' AND c.slug = 'pool-pump';


-- ============================================================================
-- ADDITIONAL HAYWARD PUMPS (Booster + Specialty) - 4 models
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'in-ground', NULL, v.cap, 'hp', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('W3SP2607X10', 'Super Pump 1.0HP Single Speed', 'Super Pump', 1.0, 8, false, false, 420,
   ARRAY['Single speed','1.0HP','See-through strainer lid','Self-priming'],
   '{"hp": 1.0, "flow_gpm": 60, "voltage": 115, "variable_speed": false, "pool_size_max_gallons": 15000}',
   'https://www.hayward.com/shop/products/pumps/super-pump'),
  ('W3SP2670007X', 'Super Pump 0.75HP Single Speed', 'Super Pump', 0.75, 8, false, false, 380,
   ARRAY['Single speed','0.75HP','For smaller pools','Self-priming'],
   '{"hp": 0.75, "flow_gpm": 50, "voltage": 115, "variable_speed": false, "pool_size_max_gallons": 12000}',
   'https://www.hayward.com/shop/products/pumps/super-pump'),
  ('W3SP2810X15', 'Booster Pump for Pressure Cleaners', 'Booster', 1.5, 8, false, false, 550,
   ARRAY['Booster pump','For pressure-side cleaners','Self-priming','Thermoplastic body'],
   '{"hp": 1.5, "flow_gpm": 47, "voltage": 115, "variable_speed": false, "purpose": "booster_for_cleaner"}',
   'https://www.hayward.com/shop/products/pumps/booster-pump'),
  ('W3SP3202VSP', 'TriStar VS 950 Omni', 'TriStar Omni', 2.7, 10, true, true, 2200,
   ARRAY['Variable speed','OmniLogic compatible','Smart scheduling','Omni ecosystem integration','Energy Star'],
   '{"hp": 2.7, "flow_gpm": 148, "voltage": 230, "variable_speed": true, "speed_settings": 8, "pool_size_max_gallons": 40000, "omni_compatible": true}',
   'https://www.hayward.com/shop/products/pumps/tristar-vs-950-omni-variable-speed-pump')
) AS v(model_number, model_name, series, cap, lifespan, wifi, estar, msrp, features, specs, url)
WHERE m.slug = 'hayward' AND c.slug = 'pool-pump';


-- ============================================================================
-- ADDITIONAL JANDY PUMPS - 3 models
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'in-ground', NULL, v.cap, 'hp', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('VSSHP165AUT', 'ePump 1.65HP Variable Speed', 'ePump', 1.65, 10, true, true, 1400,
   ARRAY['Variable speed','1.65 THP','iAqualink compatible','Energy Star','Built-in timer'],
   '{"hp": 1.65, "flow_gpm": 90, "voltage": 115, "variable_speed": true, "speed_settings": 8, "pool_size_max_gallons": 25000}',
   'https://www.jandy.com/en/products/pumps/epump'),
  ('PB4-60', 'Polaris Booster Pump PB4-60', 'Booster', 0.75, 8, false, false, 450,
   ARRAY['Booster pump','For Polaris cleaners','Self-priming','Quiet operation','Energy efficient'],
   '{"hp": 0.75, "flow_gpm": 47, "voltage": 115, "variable_speed": false, "purpose": "booster_for_cleaner"}',
   'https://www.jandy.com/en/products/pumps/polaris-booster-pump'),
  ('FHPM10-2A', 'FloPro 1.0HP Single Speed', 'FloPro', 1.0, 8, false, false, 400,
   ARRAY['Single speed','1.0HP','Medium head','Self-priming','For smaller pools'],
   '{"hp": 1.0, "flow_gpm": 55, "voltage": 115, "variable_speed": false, "pool_size_max_gallons": 15000}',
   'https://www.jandy.com/en/products/pumps/flopro')
) AS v(model_number, model_name, series, cap, lifespan, wifi, estar, msrp, features, specs, url)
WHERE m.slug = 'jandy' AND c.slug = 'pool-pump';


-- ============================================================================
-- ADDITIONAL JANDY FILTERS - 2 models
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'in-ground', NULL, v.cap, 'sq_ft', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('CL580', 'CL 580 Cartridge Filter', 'CL Series', 580, 8, 1000,
   ARRAY['580 sq ft filtration area','Rapid-release clamp','Large capacity','Service-ease design'],
   '{"sq_ft": 580, "flow_rate_gpm": 150, "filter_type": "cartridge", "tank_diameter": 28, "pool_size_max_gallons": 58000}',
   'https://www.jandy.com/en/products/filters/cl-cartridge-filter'),
  ('DEV60', 'DEV60 DE Filter', 'DEV Series', 60, 8, 1000,
   ARRAY['60 sq ft DE filter','PermaLast body','Top-access design','High capacity','Precision manifold'],
   '{"sq_ft": 60, "flow_rate_gpm": 120, "filter_type": "de", "tank_diameter": 25, "pool_size_max_gallons": 30000}',
   'https://www.jandy.com/en/products/filters/dev-de-filter')
) AS v(model_number, model_name, series, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'jandy' AND c.slug = 'pool-filter';


-- ============================================================================
-- ADDITIONAL MAYTRONICS CLEANERS - 4 models
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'in-ground', NULL, NULL, NULL, true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('99996190-USF', 'Dolphin Quantum', 'Dolphin Quantum', 5, true, 1600,
   ARRAY['WiFi app control','Dual scrubbing brushes','PowerClean technology','Oversized filtration','Caddy included'],
   '{"pool_size_max_ft": 50, "cable_length_ft": 60, "filtration_microns": 2, "cycle_time_hours": 3, "wall_climbing": true, "waterline_scrubbing": true, "app_control": true}',
   'https://www.maytronics.com/us/dolphin-quantum'),
  ('99996220-USF', 'Dolphin Cayman', 'Dolphin Cayman', 5, false, 500,
   ARRAY['Entry-level robotic','CleverClean navigation','Lightweight','Top-loading filter','Floor only cleaning'],
   '{"pool_size_max_ft": 33, "cable_length_ft": 40, "filtration_microns": 2, "cycle_time_hours": 2, "wall_climbing": false, "waterline_scrubbing": false}',
   'https://www.maytronics.com/us/dolphin-cayman'),
  ('99996200-USF', 'Dolphin Oasis Z5i', 'Dolphin Oasis', 5, true, 2500,
   ARRAY['WiFi app control','Commercial-grade','Oversized debris canister','Floor wall waterline','Caddy included','Dual filter option'],
   '{"pool_size_max_ft": 60, "cable_length_ft": 70, "filtration_microns": 2, "cycle_time_hours": 4, "wall_climbing": true, "waterline_scrubbing": true, "app_control": true, "commercial_grade": true}',
   'https://www.maytronics.com/us/dolphin-oasis-z5i'),
  ('99996203-USF', 'Dolphin S300i', 'Dolphin S-Series', 5, true, 1300,
   ARRAY['WiFi app control','Gyroscope navigation','Top-access filter basket','Weekly schedule','LED indicator'],
   '{"pool_size_max_ft": 50, "cable_length_ft": 60, "filtration_microns": 2, "cycle_time_hours": 2.5, "wall_climbing": true, "waterline_scrubbing": true, "app_control": true}',
   'https://www.maytronics.com/us/dolphin-s300i')
) AS v(model_number, model_name, series, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'maytronics' AND c.slug = 'pool-cleaner';


-- ============================================================================
-- ADDITIONAL INTERMATIC MODELS - 3 models
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'in-ground', NULL, v.cap, 'zones', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('PE25300', 'MultiWave Wireless Switch', 'MultiWave', 3, 10, true, 400,
   ARRAY['3-circuit wireless switch','Z-Wave Plus','Wall-mount','Controls pumps lights heater','Works with PE653'],
   '{"zones": 3, "supports_salt": false, "supports_heater": true, "app_control": true, "z_wave": true, "wall_mount": true}',
   'https://www.intermatic.com/pool-spa/electronic-controls/multiwave'),
  ('T106M', 'Mechanical Timer 24-Hour DPST Heavy Duty', 'T100 Series', 2, 15, false, 100,
   ARRAY['24-hour mechanical timer','Dual circuit DPST','Heavy-duty 40A contacts','Metal enclosure','Skipper wheel'],
   '{"zones": 2, "supports_salt": false, "supports_heater": true, "app_control": false, "timer_type": "mechanical_24hr", "amperage": 40, "dual_circuit": true}',
   'https://www.intermatic.com/pool-spa/mechanical-timers/t106m'),
  ('PF1112T', 'Freeze Protection Timer with Thermostat', 'PF Series', 2, 10, false, 150,
   ARRAY['Freeze protection','Dual circuit','Built-in thermostat','Adjustable set point','Prevents pipe damage'],
   '{"zones": 2, "supports_salt": false, "supports_heater": false, "app_control": false, "timer_type": "freeze_protection", "freeze_temp_f": 38, "dual_circuit": true}',
   'https://www.intermatic.com/pool-spa/freeze-protection/pf1112t')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'intermatic' AND c.slug = 'pool-automation';


-- ============================================================================
-- ADDITIONAL INTEX MODELS - 3 models
-- ============================================================================

-- Intex Filters (standalone)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'above-ground', NULL, v.cap, 'sq_ft', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('26643EG', 'Krystal Clear Sand Filter 1200 GPH', 'Krystal Clear', 15, 5, 180,
   ARRAY['Sand filter','1200 GPH','6-function valve','24-hour timer','For above-ground pools'],
   '{"sq_ft": 15, "flow_rate_gpm": 20, "filter_type": "sand", "tank_diameter": 12, "pool_size_max_gallons": 8000}',
   'https://www.intexcorp.com/pools/pool-filters/krystal-clear-sand-filter-1200-gph.html'),
  ('28635EG', 'Krystal Clear Cartridge Filter 1500 GPH', 'Krystal Clear', 10, 3, 90,
   ARRAY['Cartridge filter','1500 GPH','GFCI plug','Type B filter cartridge','Easy setup'],
   '{"sq_ft": 10, "flow_rate_gpm": 25, "filter_type": "cartridge", "pool_size_max_gallons": 10000}',
   'https://www.intexcorp.com/pools/pool-filters/krystal-clear-cartridge-filter-1500-gph.html'),
  ('26644EG', 'Krystal Clear Sand Filter 2100 GPH', 'Krystal Clear', 20, 5, 220,
   ARRAY['Sand filter','2100 GPH','6-function valve','Built-in timer','GFCI plug'],
   '{"sq_ft": 20, "flow_rate_gpm": 35, "filter_type": "sand", "tank_diameter": 14, "pool_size_max_gallons": 14000}',
   'https://www.intexcorp.com/pools/pool-filters/krystal-clear-sand-filter-2100-gph.html')
) AS v(model_number, model_name, series, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'intex' AND c.slug = 'pool-filter';


-- ============================================================================
-- ADDITIONAL ZODIAC CLEANERS - 3 models
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'in-ground', NULL, NULL, NULL, true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('W78058', 'Baracuda G4 Suction Side Cleaner', 'Baracuda', 5, false, 320,
   ARRAY['Suction-side cleaner','Advanced FlowKeeper valve','Diaphragm-driven','Quiet operation','36-finned disc'],
   '{"pool_size_max_ft": 44, "type": "suction_side", "booster_pump_required": false, "finned_disc": true}',
   'https://www.zodiacpoolsystems.com/en/products/cleaners/baracuda-g4'),
  ('CNX4025IQDTL', 'CX35 Robotic Cleaner', 'CX Series', 5, true, 1400,
   ARRAY['Robotic cleaner','WiFi app control','4WD traction','Floor wall waterline','Ultra-fine filtration'],
   '{"pool_size_max_ft": 50, "cable_length_ft": 60, "filtration_microns": 2, "cycle_time_hours": 3, "wall_climbing": true, "waterline_scrubbing": true, "app_control": true}',
   'https://www.zodiacpoolsystems.com/en/products/cleaners/cx35-robotic-cleaner'),
  ('W70483', 'MX6 Suction Side Cleaner', 'MX Series', 5, false, 300,
   ARRAY['Suction-side cleaner','X-Drive navigation','Cyclonic action','Low flow design','Tracks for traction'],
   '{"pool_size_max_ft": 40, "type": "suction_side", "booster_pump_required": false, "cyclonic_action": true}',
   'https://www.zodiacpoolsystems.com/en/products/cleaners/mx6')
) AS v(model_number, model_name, series, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'zodiac-pool' AND c.slug = 'pool-cleaner';


-- ============================================================================
-- ADDITIONAL ZODIAC PUMPS - 2 models
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'in-ground', NULL, v.cap, 'hp', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('VS-FHP100DV', 'FloPro VS 1.0HP Variable Speed', 'FloPro', 1.0, 10, true, true, 1000,
   ARRAY['Variable speed','1.0 THP','Energy Star','Compact design','For smaller pools'],
   '{"hp": 1.0, "flow_gpm": 60, "voltage": 115, "variable_speed": true, "speed_settings": 8, "pool_size_max_gallons": 15000}',
   'https://www.zodiacpoolsystems.com/en/products/pumps/flopro-vs'),
  ('FHPM15-ZP', 'FloPro 1.5HP Single Speed', 'FloPro', 1.5, 8, false, false, 480,
   ARRAY['Single speed','1.5HP','Self-priming','Durable construction'],
   '{"hp": 1.5, "flow_gpm": 75, "voltage": 115, "variable_speed": false, "pool_size_max_gallons": 20000}',
   'https://www.zodiacpoolsystems.com/en/products/pumps/flopro')
) AS v(model_number, model_name, series, cap, lifespan, wifi, estar, msrp, features, specs, url)
WHERE m.slug = 'zodiac-pool' AND c.slug = 'pool-pump';


-- ============================================================================
-- ADDITIONAL POLARIS CLEANERS - 2 models
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'in-ground', NULL, NULL, NULL, true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('F9650IQ', 'Polaris 9650IQ Sport Robotic Cleaner', '9000 Series', 5, true, 1700,
   ARRAY['4WD robotic cleaner','iAqualink app control','Aqua-Trax tires','Vortex vacuum','7-day scheduler','Smart motion sensing'],
   '{"pool_size_max_ft": 60, "cable_length_ft": 70, "filtration_microns": 2, "cycle_time_hours": 3, "wall_climbing": true, "app_control": true, "four_wheel_drive": true, "iaqualink": true}',
   'https://www.polaris.com/en-us/pool-cleaners/robotic/9650iq-sport'),
  ('F280', 'Polaris 280 Pressure Cleaner', '280 Series', 5, false, 500,
   ARRAY['Pressure-side cleaner','Dual jets','Sweep hose','All-purpose bag','Booster pump required'],
   '{"pool_size_max_ft": 40, "type": "pressure_side", "booster_pump_required": true, "dual_jets": true}',
   'https://www.polaris.com/en-us/pool-cleaners/pressure/280')
) AS v(model_number, model_name, series, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'polaris-pool' AND c.slug = 'pool-cleaner';


-- ============================================================================
-- SUMMARY
-- ============================================================================
-- Pentair:    12 pumps + 8 filters + 7 heaters + 3 salt + 3 automation + 4 cleaners = 37
-- Hayward:    12 pumps + 8 filters + 7 heaters + 3 salt + 3 automation + 5 cleaners = 38
-- Jandy:      8 pumps + 6 filters + 7 heaters + 2 salt + 3 automation + 3 cleaners = 29
-- Raypak:     13 heaters = 13
-- AquaCal:    8 heaters = 8
-- Maytronics: 14 cleaners = 14
-- Polaris:    10 cleaners = 10
-- Zodiac:     7 cleaners + 4 pumps + 4 salt = 15
-- AutoPilot:  6 salt = 6
-- CircuPool:  6 salt = 6
-- Intex:      4 pumps + 3 filters + 2 heaters + 2 salt + 4 cleaners = 15
-- Intermatic: 13 automation = 13
-- ============================================================================
-- TOTAL: 204 models across 12 brands and 6 categories
-- ============================================================================
