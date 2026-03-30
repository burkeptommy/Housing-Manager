SET ROLE postgres;
-- ============================================================================
-- Equipment Catalog: Irrigation & Sprinkler Systems
-- ============================================================================
-- Brands: Orbit, Rain Bird, Hunter Industries, Toro, Irritrol, K-Rain,
--         Weathermatic, Rachio, Netafim, Watts
-- Categories: irrigation-controller, sprinkler-head, backflow-preventer
-- ============================================================================

-- ======================== RACHIO (Smart Controllers) ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('8ZULW-C', 'Rachio 3 8-Zone', 'Rachio 3', 'wall-mount', 8, 'zones', 10, true, true, 230, ARRAY['Weather Intelligence Plus','WaterSense certified','Hyperlocal forecasting','App control','Alexa/Google/HomeKit'], '{"zones": 8, "wifi": true, "weather_intelligence": true, "flow_sensor_compatible": true, "seasonal_adjust": true}', 'https://www.rachio.com/products/rachio-3/'),
  ('16ZULW-C', 'Rachio 3 16-Zone', 'Rachio 3', 'wall-mount', 16, 'zones', 10, true, true, 280, ARRAY['Weather Intelligence Plus','WaterSense certified','16-zone capacity','App control','Alexa/Google/HomeKit'], '{"zones": 16, "wifi": true, "weather_intelligence": true, "flow_sensor_compatible": true, "seasonal_adjust": true}', 'https://www.rachio.com/products/rachio-3/'),
  ('R3E-8ZONE', 'Rachio 3e 8-Zone', 'Rachio 3e', 'wall-mount', 8, 'zones', 10, true, true, 150, ARRAY['Weather Intelligence','WaterSense certified','App control','Budget smart option'], '{"zones": 8, "wifi": true, "weather_intelligence": true, "flow_sensor_compatible": false, "seasonal_adjust": true}', 'https://www.rachio.com/products/rachio-3e/'),
  ('WM-1', 'Rachio Smart Hose Timer', 'Rachio', 'hose-mount', 1, 'zones', 8, true, false, 65, ARRAY['Smart hose timer','App control','Weather-based scheduling','Quick connect'], '{"zones": 1, "wifi": true, "weather_intelligence": true, "hose_thread": "3/4 inch"}', 'https://www.rachio.com/products/smart-hose-timer/'),
  ('WM-2', 'Rachio Smart Hose Timer 2-Zone', 'Rachio', 'hose-mount', 2, 'zones', 8, true, false, 80, ARRAY['Dual-zone hose timer','App control','Weather-based scheduling','Independent zone control'], '{"zones": 2, "wifi": true, "weather_intelligence": true, "hose_thread": "3/4 inch"}', 'https://www.rachio.com/products/smart-hose-timer/'),
  ('FLWSNS', 'Rachio Wireless Flow Meter', 'Rachio', 'inline', NULL, NULL, 10, true, false, 100, ARRAY['Wireless flow monitoring','Leak detection','Usage tracking','Works with Rachio 3'], '{"connection": "wireless", "pipe_sizes": ["3/4 inch", "1 inch", "1.5 inch"], "battery_life_years": 2}', 'https://www.rachio.com/products/wireless-flow-meter/')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs, url)
WHERE m.slug = 'rachio' AND c.slug = 'irrigation-controller';

-- ======================== RAIN BIRD (Professional Grade) ========================

-- Rain Bird Controllers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('ESP-TM2-8', 'ESP-TM2 8-Station', 'ESP-TM2', 'wall-mount', 8, 'zones', 12, false, false, 120, ARRAY['Modular up to 16 stations','Extra-large wiring compartment','365-day programming','Contractor favorite'], '{"zones": 8, "expandable_to": 16, "wifi": false, "seasonal_adjust": true, "rain_sensor_ready": true}', 'https://www.rainbird.com/products/esp-tm2-series'),
  ('ESP-TM2-12', 'ESP-TM2 12-Station', 'ESP-TM2', 'wall-mount', 12, 'zones', 12, false, false, 140, ARRAY['Modular design','12 stations included','365-day programming','Contractor favorite'], '{"zones": 12, "expandable_to": 16, "wifi": false, "seasonal_adjust": true, "rain_sensor_ready": true}', 'https://www.rainbird.com/products/esp-tm2-series'),
  ('ST8O-2.0', 'ST8O-2.0 WiFi 8-Zone', 'ARC8', 'wall-mount', 8, 'zones', 10, true, true, 180, ARRAY['WiFi/app control','EPA WaterSense','Weather-based adjustment','Simple setup'], '{"zones": 8, "wifi": true, "weather_intelligence": true, "flow_sensor_compatible": true, "seasonal_adjust": true}', 'https://www.rainbird.com/products/arc8-smart-controller'),
  ('ESP-ME3-12', 'ESP-ME3 12-Station', 'ESP-ME3', 'wall-mount', 12, 'zones', 12, true, false, 200, ARRAY['WiFi/LNK2 ready','Modular up to 22 stations','Flow sensing ready','Contractor grade'], '{"zones": 12, "expandable_to": 22, "wifi": true, "weather_intelligence": true, "flow_sensor_compatible": true}', 'https://www.rainbird.com/products/esp-me3-series'),
  ('ESP-ME3-22', 'ESP-ME3 22-Station', 'ESP-ME3', 'wall-mount', 22, 'zones', 12, true, false, 280, ARRAY['WiFi/LNK2 ready','22 stations max','Flow Smart technology','Commercial grade'], '{"zones": 22, "expandable_to": 22, "wifi": true, "weather_intelligence": true, "flow_sensor_compatible": true}', 'https://www.rainbird.com/products/esp-me3-series'),
  ('SST-600O', 'SST-600O 6-Zone', 'SST', 'wall-mount', 6, 'zones', 10, false, false, 55, ARRAY['Simple set timer','Easy programming','Budget-friendly','Residential'], '{"zones": 6, "wifi": false, "seasonal_adjust": true, "rain_sensor_ready": true}', 'https://www.rainbird.com/products/sst-series')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs, url)
WHERE m.slug = 'rain-bird' AND c.slug = 'irrigation-controller';

-- Rain Bird Rotors
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'in-ground', NULL, v.cap, 'radius_ft', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('5004-PC', '5004 Plus Rotor', '5000 Series', 40, 8, 18, ARRAY['Rain Curtain nozzle technology','Part/full circle adjustable','Seal-A-Matic check valve option','Industry standard'], '{"radius_ft": 40, "arc_degrees": 360, "gpm_range": "1.0-6.3", "nozzle_set": "included", "pop_up_height": 4, "inlet": "1/2 inch"}', 'https://www.rainbird.com/products/5000-series-rotor'),
  ('5004-SAM-PC', '5004 Plus SAM Rotor', '5000 Series', 40, 8, 20, ARRAY['Seal-A-Matic check valve built-in','Prevents low-head drainage','Rain Curtain nozzles','Part/full circle'], '{"radius_ft": 40, "arc_degrees": 360, "gpm_range": "1.0-6.3", "nozzle_set": "included", "pop_up_height": 4, "check_valve": true}', 'https://www.rainbird.com/products/5000-series-rotor'),
  ('42SA+', '42SA+ Simple Adjust Rotor', '42SA+', 35, 8, 16, ARRAY['Simple arc adjustment','Non-strippable drive','Rubber cover','Budget rotor'], '{"radius_ft": 35, "arc_degrees": 360, "gpm_range": "0.6-4.5", "pop_up_height": 4, "inlet": "1/2 inch"}', 'https://www.rainbird.com/products/42sa-rotor'),
  ('8005', '8005 Large-Area Rotor', '8000 Series', 55, 10, 22, ARRAY['Commercial/large residential','Trip point memory arc','Full/part circle','Heavy-duty construction'], '{"radius_ft": 55, "arc_degrees": 360, "gpm_range": "3.0-14.0", "nozzle_set": "included", "pop_up_height": 6, "inlet": "1 inch"}', 'https://www.rainbird.com/products/8000-series-rotor')
) AS v(model_number, model_name, series, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'rain-bird' AND c.slug = 'sprinkler-head';

-- Rain Bird Spray Heads
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'in-ground', NULL, v.cap, 'radius_ft', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('1804-SAM', '1804 SAM Spray Head', '1800 Series', 15, 8, 5, ARRAY['Seal-A-Matic check valve','4-inch pop-up','Wiper seal','Industry standard spray body'], '{"radius_ft": 15, "pop_up_height": 4, "inlet": "1/2 inch", "check_valve": true, "pattern": "interchangeable_nozzle"}', 'https://www.rainbird.com/products/1800-series-spray'),
  ('1806-SAM', '1806 SAM Spray Head 6-inch', '1800 Series', 15, 8, 7, ARRAY['6-inch pop-up for taller grass','Seal-A-Matic check valve','Wiper seal','Spray body'], '{"radius_ft": 15, "pop_up_height": 6, "inlet": "1/2 inch", "check_valve": true, "pattern": "interchangeable_nozzle"}', 'https://www.rainbird.com/products/1800-series-spray'),
  ('U-8M', 'U-Series 8-ft Male Nozzle', 'U-Series', 8, 6, 2, ARRAY['Matched precipitation rate','Even coverage','Male thread','Fixed arc'], '{"radius_ft": 8, "arc_degrees": 360, "gpm": 0.4, "pattern": "fixed", "type": "nozzle_only"}', 'https://www.rainbird.com/products/u-series-nozzles'),
  ('HE-VAN-15', 'High Efficiency VAN Nozzle 15ft', 'HE-VAN', 15, 6, 5, ARRAY['30% water savings','Variable arc 0-360','Pressure-compensating','Matched precipitation'], '{"radius_ft": 15, "arc_degrees": 360, "gpm": 1.5, "pattern": "variable_arc", "type": "high_efficiency_nozzle"}', 'https://www.rainbird.com/products/he-van-nozzle'),
  ('R-VAN-18', 'R-VAN Rotary Nozzle 18ft', 'R-VAN', 18, 8, 6, ARRAY['Multi-stream rotating','30% water savings','Wind-resistant','Retrofits standard spray body'], '{"radius_ft": 18, "arc_degrees": 360, "gpm": 0.6, "pattern": "rotary_multi_stream", "type": "rotary_nozzle"}', 'https://www.rainbird.com/products/r-van-nozzle')
) AS v(model_number, model_name, series, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'rain-bird' AND c.slug = 'sprinkler-head';

-- ======================== HUNTER INDUSTRIES (Professional) ========================

-- Hunter Controllers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('HC-1200I', 'Hydrawise HC 12-Zone Indoor', 'Hydrawise Pro-HC', 'wall-mount', 12, 'zones', 12, true, true, 250, ARRAY['Hydrawise cloud-based management','Predictive watering','EPA WaterSense','Flow monitoring ready','App control'], '{"zones": 12, "expandable_to": 12, "wifi": true, "weather_intelligence": true, "flow_sensor_compatible": true, "seasonal_adjust": true}', 'https://www.hunterindustries.com/product/hydrawise-hc-controller'),
  ('HC-600I', 'Hydrawise HC 6-Zone Indoor', 'Hydrawise Pro-HC', 'wall-mount', 6, 'zones', 12, true, true, 180, ARRAY['Hydrawise cloud-based management','Predictive watering','EPA WaterSense','App control'], '{"zones": 6, "wifi": true, "weather_intelligence": true, "flow_sensor_compatible": true, "seasonal_adjust": true}', 'https://www.hunterindustries.com/product/hydrawise-hc-controller'),
  ('PHC-2400I', 'Pro-HC 24-Zone Indoor', 'Pro-HC', 'wall-mount', 24, 'zones', 12, true, true, 340, ARRAY['Commercial/large residential','Hydrawise platform','Flow Smart ready','24 stations','Contractor grade'], '{"zones": 24, "wifi": true, "weather_intelligence": true, "flow_sensor_compatible": true, "seasonal_adjust": true}', 'https://www.hunterindustries.com/product/pro-hc-controller'),
  ('XC-800I', 'X-Core 8-Zone Indoor', 'X-Core', 'wall-mount', 8, 'zones', 12, false, false, 100, ARRAY['Simple programming','Sensor ready','3 programs','Budget professional grade'], '{"zones": 8, "wifi": false, "seasonal_adjust": true, "rain_sensor_ready": true, "programs": 3}', 'https://www.hunterindustries.com/product/x-core-controller'),
  ('NODE-BT-400', 'Node-BT 4-Station', 'Node-BT', 'valve-box', 4, 'zones', 8, true, false, 120, ARRAY['Battery-powered','Bluetooth control','No wiring needed','Valve-box mount','IP68 waterproof'], '{"zones": 4, "wifi": false, "bluetooth": true, "battery_powered": true, "waterproof": "IP68"}', 'https://www.hunterindustries.com/product/node-bt')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs, url)
WHERE m.slug = 'hunter-industries' AND c.slug = 'irrigation-controller';

-- Hunter Rotors
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'in-ground', NULL, v.cap, 'radius_ft', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('PGP-ADJ', 'PGP-ADJ Rotor', 'PGP Ultra', 40, 10, 18, ARRAY['Industry-leading rotor','Part circle adjustable','Auto-arc return','12 nozzles included'], '{"radius_ft": 40, "arc_degrees": 360, "gpm_range": "0.5-6.5", "nozzle_set": "12 included", "pop_up_height": 4, "inlet": "1/2 inch"}', 'https://www.hunterindustries.com/product/pgp-ultra'),
  ('PGP-04-CV', 'PGP Ultra Check Valve', 'PGP Ultra', 40, 10, 22, ARRAY['Built-in check valve','Prevents low-head drainage','Auto-arc return','12 nozzles included'], '{"radius_ft": 40, "arc_degrees": 360, "gpm_range": "0.5-6.5", "nozzle_set": "12 included", "pop_up_height": 4, "check_valve": true}', 'https://www.hunterindustries.com/product/pgp-ultra'),
  ('PGJ-04', 'PGJ Rotor', 'PGJ', 30, 8, 12, ARRAY['Compact rotor for small areas','Part circle adjustable','Water-lubricated gear drive','Economical'], '{"radius_ft": 30, "arc_degrees": 360, "gpm_range": "0.4-4.5", "nozzle_set": "6 included", "pop_up_height": 4, "inlet": "1/2 inch"}', 'https://www.hunterindustries.com/product/pgj'),
  ('I-20-04-SS', 'I-20 Stainless Steel Rotor', 'I-20', 46, 10, 35, ARRAY['Stainless steel riser','Commercial grade','Part/full circle','Heavy traffic areas'], '{"radius_ft": 46, "arc_degrees": 360, "gpm_range": "2.0-11.0", "nozzle_set": "included", "pop_up_height": 4, "riser": "stainless_steel"}', 'https://www.hunterindustries.com/product/i-20'),
  ('I-25-06', 'I-25 Large-Area Rotor 6-inch', 'I-25', 57, 10, 40, ARRAY['Large radius coverage','6-inch pop-up','Commercial/sports turf','High-wind performance'], '{"radius_ft": 57, "arc_degrees": 360, "gpm_range": "4.0-19.0", "nozzle_set": "included", "pop_up_height": 6, "inlet": "1 inch"}', 'https://www.hunterindustries.com/product/i-25')
) AS v(model_number, model_name, series, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'hunter-industries' AND c.slug = 'sprinkler-head';

-- Hunter Spray Heads
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'in-ground', NULL, v.cap, 'radius_ft', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('PROS-04-CV', 'Pro-Spray 4-inch Check Valve', 'Pro-Spray', 15, 8, 5, ARRAY['Integrated check valve','4-inch pop-up','Accepts all Hunter nozzles','Wiper seal'], '{"radius_ft": 15, "pop_up_height": 4, "inlet": "1/2 inch", "check_valve": true, "pattern": "interchangeable_nozzle"}', 'https://www.hunterindustries.com/product/pro-spray'),
  ('PROS-06-CV', 'Pro-Spray 6-inch Check Valve', 'Pro-Spray', 15, 8, 7, ARRAY['6-inch pop-up for tall turf','Integrated check valve','Accepts all Hunter nozzles'], '{"radius_ft": 15, "pop_up_height": 6, "inlet": "1/2 inch", "check_valve": true, "pattern": "interchangeable_nozzle"}', 'https://www.hunterindustries.com/product/pro-spray'),
  ('MP3000-90', 'MP Rotator 3000 90-210', 'MP Rotator', 30, 8, 7, ARRAY['Multi-stream rotating nozzle','Matched precipitation rate','Low precipitation rate','Wind-resistant'], '{"radius_ft": 30, "arc_degrees": 210, "gpm": 0.8, "pattern": "rotary_multi_stream", "type": "rotary_nozzle"}', 'https://www.hunterindustries.com/product/mp-rotator'),
  ('MP2000-90', 'MP Rotator 2000 90-210', 'MP Rotator', 21, 8, 6, ARRAY['Multi-stream rotating nozzle','Matched precipitation rate','Retrofits spray bodies'], '{"radius_ft": 21, "arc_degrees": 210, "gpm": 0.5, "pattern": "rotary_multi_stream", "type": "rotary_nozzle"}', 'https://www.hunterindustries.com/product/mp-rotator'),
  ('MP1000-90', 'MP Rotator 1000 90-210', 'MP Rotator', 13, 8, 5, ARRAY['Short-range multi-stream','For tight areas','Retrofits spray bodies','Matched precipitation'], '{"radius_ft": 13, "arc_degrees": 210, "gpm": 0.3, "pattern": "rotary_multi_stream", "type": "rotary_nozzle"}', 'https://www.hunterindustries.com/product/mp-rotator'),
  ('A17-A', 'Pro Fixed Nozzle 17ft Adjustable', 'Pro Spray Nozzle', 17, 6, 3, ARRAY['Adjustable arc 0-360','Fixed spray pattern','Matched precipitation','Male thread'], '{"radius_ft": 17, "arc_degrees": 360, "gpm": 2.2, "pattern": "adjustable", "type": "fixed_spray_nozzle"}', 'https://www.hunterindustries.com/product/pro-spray-fixed-arc-nozzles')
) AS v(model_number, model_name, series, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'hunter-industries' AND c.slug = 'sprinkler-head';

-- ======================== TORO (Professional/Mainstream) ========================

-- Toro Controllers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('53742', 'Tempus DC 2-Zone', 'Tempus', 'valve-box', 2, 'zones', 8, false, false, 60, ARRAY['Battery-powered DC controller','No wiring needed','Valve-box mount','Easy programming'], '{"zones": 2, "wifi": false, "battery_powered": true, "latching_solenoid": true}', 'https://www.toro.com/products/tempus-dc-controller'),
  ('53808', 'Tempus T-8 8-Zone Indoor', 'Tempus', 'wall-mount', 8, 'zones', 10, false, false, 85, ARRAY['Simple interface','8 stations','3 programs','Rain sensor ready'], '{"zones": 8, "wifi": false, "seasonal_adjust": true, "rain_sensor_ready": true, "programs": 3}', 'https://www.toro.com/products/tempus-t-controller'),
  ('TMC-212', 'TMC-212 12-Zone', 'TMC', 'wall-mount', 12, 'zones', 12, false, false, 140, ARRAY['Professional grade','Modular design','12 zones standard','Rain sensor ready'], '{"zones": 12, "expandable_to": 12, "wifi": false, "seasonal_adjust": true, "rain_sensor_ready": true}', 'https://www.toro.com/products/tmc-controller'),
  ('EVO-8-OD', 'Evolution 8-Zone Outdoor', 'Evolution', 'wall-mount', 8, 'zones', 12, true, true, 200, ARRAY['WiFi enabled','Weather-based watering','App control','WaterSense certified'], '{"zones": 8, "expandable_to": 16, "wifi": true, "weather_intelligence": true, "flow_sensor_compatible": true, "seasonal_adjust": true}', 'https://www.toro.com/products/evolution-controller'),
  ('EVO-16-OD', 'Evolution 16-Zone Outdoor', 'Evolution', 'wall-mount', 16, 'zones', 12, true, true, 280, ARRAY['WiFi enabled','16 zones','Weather-based watering','Flow monitoring ready','WaterSense'], '{"zones": 16, "expandable_to": 16, "wifi": true, "weather_intelligence": true, "flow_sensor_compatible": true}', 'https://www.toro.com/products/evolution-controller')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs, url)
WHERE m.slug = 'toro' AND c.slug = 'irrigation-controller';

-- Toro Rotors and Spray Heads
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'in-ground', NULL, v.cap, 'radius_ft', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('T5-PC', 'T5 RapidSet Rotor', 'T5', 40, 8, 18, ARRAY['RapidSet arc adjustment','Part/full circle','Pre-installed nozzle tree','High-efficiency'], '{"radius_ft": 40, "arc_degrees": 360, "gpm_range": "0.6-6.5", "nozzle_set": "included", "pop_up_height": 5, "inlet": "1/2 inch"}', 'https://www.toro.com/products/t5-rotor'),
  ('T7-PC', 'T7 RapidSet Rotor', 'T7', 50, 8, 28, ARRAY['Large-area rotor','RapidSet arc','Full/part circle','Heavy-duty construction'], '{"radius_ft": 50, "arc_degrees": 360, "gpm_range": "2.5-12.0", "nozzle_set": "included", "pop_up_height": 5, "inlet": "3/4 inch"}', 'https://www.toro.com/products/t7-rotor'),
  ('TR50-XP', 'Mini-8 50 Series Rotor', 'Mini-8', 35, 8, 14, ARRAY['Compact gear-drive rotor','Part/full circle','Non-strippable drive','Residential applications'], '{"radius_ft": 35, "arc_degrees": 360, "gpm_range": "0.5-4.0", "nozzle_set": "included", "pop_up_height": 4}', 'https://www.toro.com/products/mini-8-rotor'),
  ('570Z-4P-CV', '570Z 4-inch Spray Body with Check Valve', '570Z', 15, 8, 5, ARRAY['Built-in check valve','4-inch pop-up','Accepts Toro/Irritrol nozzles','Flush cap'], '{"radius_ft": 15, "pop_up_height": 4, "inlet": "1/2 inch", "check_valve": true, "pattern": "interchangeable_nozzle"}', 'https://www.toro.com/products/570z-spray'),
  ('570Z-6P-CV', '570Z 6-inch Spray Body with Check Valve', '570Z', 15, 8, 7, ARRAY['6-inch pop-up height','Built-in check valve','For taller turf areas'], '{"radius_ft": 15, "pop_up_height": 6, "inlet": "1/2 inch", "check_valve": true, "pattern": "interchangeable_nozzle"}', 'https://www.toro.com/products/570z-spray'),
  ('O-T-15-TTP', 'Precision Rotating Nozzle 15ft', 'Precision Series', 15, 8, 5, ARRAY['Multi-stream rotating','Matched precipitation rate','Low application rate','Retrofits spray bodies'], '{"radius_ft": 15, "arc_degrees": 360, "gpm": 0.5, "pattern": "rotary_multi_stream", "type": "precision_nozzle"}', 'https://www.toro.com/products/precision-rotating-nozzle'),
  ('O-T-25-TTP', 'Precision Rotating Nozzle 25ft', 'Precision Series', 25, 8, 6, ARRAY['Mid-range multi-stream','Matched precipitation','Wind-resistant streams'], '{"radius_ft": 25, "arc_degrees": 360, "gpm": 0.7, "pattern": "rotary_multi_stream", "type": "precision_nozzle"}', 'https://www.toro.com/products/precision-rotating-nozzle')
) AS v(model_number, model_name, series, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'toro' AND c.slug = 'sprinkler-head';

-- ======================== ORBIT (Budget-Friendly) ========================

-- Orbit Controllers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('57946', 'B-hyve XR 8-Zone WiFi', 'B-hyve XR', 'wall-mount', 8, 'zones', 8, true, true, 120, ARRAY['WiFi smart controller','Weather-based watering','EPA WaterSense','App control','Alexa/Google'], '{"zones": 8, "wifi": true, "weather_intelligence": true, "flow_sensor_compatible": false, "seasonal_adjust": true}', 'https://www.orbitonline.com/product/b-hyve-xr-smart-controller-8-zone'),
  ('57950', 'B-hyve XR 16-Zone WiFi', 'B-hyve XR', 'wall-mount', 16, 'zones', 8, true, true, 160, ARRAY['WiFi smart controller','16-zone capacity','Weather-based watering','WaterSense','App control'], '{"zones": 16, "wifi": true, "weather_intelligence": true, "flow_sensor_compatible": false, "seasonal_adjust": true}', 'https://www.orbitonline.com/product/b-hyve-xr-smart-controller-16-zone'),
  ('57925', 'B-hyve Smart Hose Faucet Timer', 'B-hyve', 'hose-mount', 2, 'zones', 6, true, false, 50, ARRAY['WiFi hose timer','2-outlet control','Weather-based','App control','Easy setup'], '{"zones": 2, "wifi": true, "weather_intelligence": true, "hose_thread": "3/4 inch"}', 'https://www.orbitonline.com/product/b-hyve-smart-hose-faucet-timer'),
  ('57894', 'B-hyve 6-Zone WiFi', 'B-hyve', 'wall-mount', 6, 'zones', 8, true, true, 80, ARRAY['WiFi smart controller','Weather-based watering','WaterSense','App control','Budget smart'], '{"zones": 6, "wifi": true, "weather_intelligence": true, "seasonal_adjust": true}', 'https://www.orbitonline.com/product/b-hyve-smart-controller-6-zone'),
  ('57899', 'B-hyve 12-Zone WiFi', 'B-hyve', 'wall-mount', 12, 'zones', 8, true, true, 100, ARRAY['WiFi smart controller','12-zone capacity','Weather-based watering','WaterSense'], '{"zones": 12, "wifi": true, "weather_intelligence": true, "seasonal_adjust": true}', 'https://www.orbitonline.com/product/b-hyve-smart-controller-12-zone'),
  ('57596', 'Easy-Set Logic 6-Zone', 'Easy-Set', 'wall-mount', 6, 'zones', 8, false, false, 30, ARRAY['Basic timer','Easy programming','Budget-friendly','Rain delay button'], '{"zones": 6, "wifi": false, "seasonal_adjust": false, "rain_delay": true}', 'https://www.orbitonline.com/product/easy-set-logic-timer-6-zone'),
  ('57162', 'Easy Dial 4-Zone', 'Easy Dial', 'wall-mount', 4, 'zones', 8, false, false, 22, ARRAY['Simple dial programming','4 stations','Budget entry-level','Manual watering button'], '{"zones": 4, "wifi": false, "seasonal_adjust": false}', 'https://www.orbitonline.com/product/easy-dial-timer-4-zone')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs, url)
WHERE m.slug = 'orbit' AND c.slug = 'irrigation-controller';

-- Orbit Spray Heads and Rotors
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'in-ground', NULL, v.cap, 'radius_ft', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('55662', 'Voyager II Gear-Drive Rotor', 'Voyager II', 40, 8, 12, ARRAY['Adjustable arc 40-360','Gear-drive mechanism','9 nozzles included','Budget rotor'], '{"radius_ft": 40, "arc_degrees": 360, "gpm_range": "0.5-5.5", "nozzle_set": "9 included", "pop_up_height": 4}', 'https://www.orbitonline.com/product/voyager-ii-rotor'),
  ('55660', 'Saturn III Gear-Drive Rotor', 'Saturn III', 35, 8, 10, ARRAY['Part/full circle','Gear-drive','Adjustable arc','Value rotor'], '{"radius_ft": 35, "arc_degrees": 360, "gpm_range": "0.4-4.0", "nozzle_set": "included", "pop_up_height": 3}', 'https://www.orbitonline.com/product/saturn-iii-rotor'),
  ('54183', '4-inch Pop-Up Spray Head', 'Professional', 15, 6, 3, ARRAY['Professional grade spray body','4-inch pop-up','Spring retraction','Half-inch inlet'], '{"radius_ft": 15, "pop_up_height": 4, "inlet": "1/2 inch", "pattern": "interchangeable_nozzle"}', 'https://www.orbitonline.com/product/4-inch-professional-pop-up'),
  ('54281', '6-inch Pop-Up Spray Head', 'Professional', 15, 6, 4, ARRAY['6-inch pop-up height','Professional grade','For taller turf','Interchangeable nozzles'], '{"radius_ft": 15, "pop_up_height": 6, "inlet": "1/2 inch", "pattern": "interchangeable_nozzle"}', 'https://www.orbitonline.com/product/6-inch-professional-pop-up'),
  ('55070', 'Strip Pattern Nozzle', 'Strip', 15, 6, 3, ARRAY['Side-strip pattern','For narrow areas','4x15 ft pattern','Center or end strip'], '{"radius_ft": 15, "pattern": "strip", "coverage": "4x15 ft", "type": "strip_nozzle"}', 'https://www.orbitonline.com/product/strip-pattern-nozzle'),
  ('55050', 'Adjustable Nozzle 15ft', 'Orbit', 15, 6, 2, ARRAY['Adjustable arc 0-360','15-ft radius','Female thread','Matched precipitation'], '{"radius_ft": 15, "arc_degrees": 360, "gpm": 1.8, "pattern": "adjustable", "type": "adjustable_nozzle"}', 'https://www.orbitonline.com/product/adjustable-arc-nozzle')
) AS v(model_number, model_name, series, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'orbit' AND c.slug = 'sprinkler-head';

-- ======================== IRRITROL (Toro Subsidiary, Professional) ========================

-- Irritrol Controllers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('RAIN-DIAL-R', 'Rain Dial-R 6-Zone', 'Rain Dial', 'wall-mount', 6, 'zones', 10, false, false, 65, ARRAY['Easy dial programming','Rain sensor ready','Manual override','Budget professional'], '{"zones": 6, "wifi": false, "seasonal_adjust": true, "rain_sensor_ready": true}', 'https://www.irritrol.com/products/rain-dial-r'),
  ('TOTAL-CTRL-R', 'Total Control-R 12-Zone', 'Total Control', 'wall-mount', 12, 'zones', 12, false, false, 120, ARRAY['12 stations standard','4 programs','Rain sensor ready','Professional'], '{"zones": 12, "wifi": false, "seasonal_adjust": true, "rain_sensor_ready": true, "programs": 4}', 'https://www.irritrol.com/products/total-control'),
  ('KWIK-DIAL-9', 'Kwik Dial 9-Zone', 'Kwik Dial', 'wall-mount', 9, 'zones', 10, false, false, 45, ARRAY['Quick-set programming','Budget controller','Rain delay','Residential'], '{"zones": 9, "wifi": false, "seasonal_adjust": true}', 'https://www.irritrol.com/products/kwik-dial'),
  ('CLIMATE-LOGIC', 'Climate Logic Wireless Weather Sensor', 'Climate Logic', 'wall-mount', NULL, NULL, 8, true, true, 150, ARRAY['Wireless weather sensor','ET-based scheduling','Solar/wind/rain/freeze sensors','WaterSense'], '{"zones": null, "wifi": true, "weather_intelligence": true, "sensor_type": "wireless_weather_station"}', 'https://www.irritrol.com/products/climate-logic')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs, url)
WHERE m.slug = 'irritrol' AND c.slug = 'irrigation-controller';

-- Irritrol Rotors and Spray Heads
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'in-ground', NULL, v.cap, 'radius_ft', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('550R', '550R Rotor', '550R', 40, 8, 15, ARRAY['Full/part circle','Non-strippable arc','Top-access adjustments','Professional grade'], '{"radius_ft": 40, "arc_degrees": 360, "gpm_range": "0.6-6.0", "nozzle_set": "included", "pop_up_height": 4, "inlet": "3/4 inch"}', 'https://www.irritrol.com/products/550r-rotor'),
  ('300R', '300R Rotor', '300R', 32, 8, 10, ARRAY['Compact gear-drive','Part/full circle','Residential rotor','6 nozzles included'], '{"radius_ft": 32, "arc_degrees": 360, "gpm_range": "0.4-3.5", "nozzle_set": "6 included", "pop_up_height": 4}', 'https://www.irritrol.com/products/300r-rotor'),
  ('I-PRO-400', 'I-Pro 400 Spray Head 4-inch', 'I-Pro', 15, 8, 4, ARRAY['4-inch pop-up','Professional spray body','Accepts standard nozzles','Spring retraction'], '{"radius_ft": 15, "pop_up_height": 4, "inlet": "1/2 inch", "pattern": "interchangeable_nozzle"}', 'https://www.irritrol.com/products/i-pro-spray'),
  ('I-PRO-600', 'I-Pro 600 Spray Head 6-inch', 'I-Pro', 15, 8, 5, ARRAY['6-inch pop-up','Professional spray body','For taller turf areas'], '{"radius_ft": 15, "pop_up_height": 6, "inlet": "1/2 inch", "pattern": "interchangeable_nozzle"}', 'https://www.irritrol.com/products/i-pro-spray'),
  ('R-CP-8', 'R-CP Rotor 8-inch Pop-Up', 'R-CP', 45, 8, 25, ARRAY['8-inch pop-up height','Commercial applications','Part/full circle','High-torque drive'], '{"radius_ft": 45, "arc_degrees": 360, "gpm_range": "2.0-10.0", "pop_up_height": 8, "inlet": "3/4 inch"}', 'https://www.irritrol.com/products/r-cp-rotor')
) AS v(model_number, model_name, series, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'irritrol' AND c.slug = 'sprinkler-head';

-- ======================== K-RAIN (Professional) ========================

-- K-Rain Controllers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('3206', 'RPS 46 Mini 6-Zone', 'RPS 46 Mini', 'wall-mount', 6, 'zones', 10, false, false, 50, ARRAY['Compact design','6 zones','Rain sensor ready','Budget professional'], '{"zones": 6, "wifi": false, "seasonal_adjust": true, "rain_sensor_ready": true}', 'https://www.k-rain.com/products/rps-46-mini'),
  ('3212', 'RPS 46 Mini 12-Zone', 'RPS 46 Mini', 'wall-mount', 12, 'zones', 10, false, false, 75, ARRAY['12 zones','Compact design','3 programs','Rain sensor ready'], '{"zones": 12, "wifi": false, "seasonal_adjust": true, "rain_sensor_ready": true, "programs": 3}', 'https://www.k-rain.com/products/rps-46-mini'),
  ('BL-KR-8', 'BL-KR Bluetooth 8-Zone', 'BL-KR', 'wall-mount', 8, 'zones', 10, true, false, 90, ARRAY['Bluetooth control','App programming','8 zones','No WiFi needed'], '{"zones": 8, "wifi": false, "bluetooth": true, "seasonal_adjust": true}', 'https://www.k-rain.com/products/bl-kr-controller'),
  ('3608', 'Pro-EX 2.0 8-Zone', 'Pro-EX 2.0', 'wall-mount', 8, 'zones', 12, true, true, 160, ARRAY['WiFi enabled','Smart watering','Weather-based','App control','WaterSense'], '{"zones": 8, "expandable_to": 16, "wifi": true, "weather_intelligence": true, "seasonal_adjust": true}', 'https://www.k-rain.com/products/pro-ex-2'),
  ('3616', 'Pro-EX 2.0 16-Zone', 'Pro-EX 2.0', 'wall-mount', 16, 'zones', 12, true, true, 220, ARRAY['WiFi enabled','16 zones','Smart watering','Weather-based','Professional'], '{"zones": 16, "wifi": true, "weather_intelligence": true, "seasonal_adjust": true}', 'https://www.k-rain.com/products/pro-ex-2')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs, url)
WHERE m.slug = 'k-rain' AND c.slug = 'irrigation-controller';

-- K-Rain Rotors and Spray Heads
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'in-ground', NULL, v.cap, 'radius_ft', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('11003', 'SuperPro Rotor', 'SuperPro', 40, 8, 14, ARRAY['Part/full circle adjustable','Water-lubricated gear drive','9 nozzles included','K-Rain flagship rotor'], '{"radius_ft": 40, "arc_degrees": 360, "gpm_range": "0.5-6.5", "nozzle_set": "9 included", "pop_up_height": 4, "inlet": "1/2 inch"}', 'https://www.k-rain.com/products/superpro-rotor'),
  ('11003-CV', 'SuperPro Rotor with Check Valve', 'SuperPro', 40, 8, 18, ARRAY['Built-in check valve','Part/full circle','Prevents low-head drainage','9 nozzles included'], '{"radius_ft": 40, "arc_degrees": 360, "gpm_range": "0.5-6.5", "nozzle_set": "9 included", "pop_up_height": 4, "check_valve": true}', 'https://www.k-rain.com/products/superpro-rotor'),
  ('10003', 'ProPlus Rotor', 'ProPlus', 48, 10, 30, ARRAY['Large-area coverage','Commercial grade','Part/full circle','High-torque gear drive'], '{"radius_ft": 48, "arc_degrees": 360, "gpm_range": "2.0-13.0", "nozzle_set": "included", "pop_up_height": 5, "inlet": "3/4 inch"}', 'https://www.k-rain.com/products/proplus-rotor'),
  ('12004', 'ProSport Rotor', 'ProSport', 55, 10, 40, ARRAY['Sports turf grade','Extra long-range','Full/part circle','Stainless steel riser'], '{"radius_ft": 55, "arc_degrees": 360, "gpm_range": "4.0-18.0", "pop_up_height": 6, "inlet": "1 inch", "riser": "stainless_steel"}', 'https://www.k-rain.com/products/prosport-rotor'),
  ('SPRAY-4-CV', 'K-Spray 4-inch with Check Valve', 'K-Spray', 15, 8, 4, ARRAY['4-inch pop-up','Built-in check valve','Accepts standard nozzles','Spring retraction'], '{"radius_ft": 15, "pop_up_height": 4, "inlet": "1/2 inch", "check_valve": true, "pattern": "interchangeable_nozzle"}', 'https://www.k-rain.com/products/k-spray'),
  ('RN-100', 'RN Rotary Nozzle', 'RN Series', 24, 8, 5, ARRAY['Multi-stream rotary nozzle','Matched precipitation','Water-saving','Retrofits spray bodies'], '{"radius_ft": 24, "arc_degrees": 360, "gpm": 0.6, "pattern": "rotary_multi_stream", "type": "rotary_nozzle"}', 'https://www.k-rain.com/products/rn-rotary-nozzle')
) AS v(model_number, model_name, series, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'k-rain' AND c.slug = 'sprinkler-head';

-- ======================== WEATHERMATIC (Professional/Smart) ========================

-- Weathermatic Controllers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('SL1608', 'SmartLine 8-Zone', 'SmartLine', 'wall-mount', 8, 'zones', 12, true, true, 250, ARRAY['ET Everywhere cloud-based','Automatic weather adjustment','WaterSense certified','Remote management','Flow monitoring'], '{"zones": 8, "expandable_to": 16, "wifi": true, "weather_intelligence": true, "flow_sensor_compatible": true, "seasonal_adjust": true}', 'https://www.weathermatic.com/products/smartline-controller'),
  ('SL1616', 'SmartLine 16-Zone', 'SmartLine', 'wall-mount', 16, 'zones', 12, true, true, 320, ARRAY['ET Everywhere cloud-based','16-zone capacity','Automatic weather adjustment','WaterSense','Flow monitoring'], '{"zones": 16, "expandable_to": 48, "wifi": true, "weather_intelligence": true, "flow_sensor_compatible": true, "seasonal_adjust": true}', 'https://www.weathermatic.com/products/smartline-controller'),
  ('SL4800', 'SmartLine 48-Zone', 'SmartLine', 'wall-mount', 48, 'zones', 15, true, true, 700, ARRAY['Commercial/estate grade','48-zone capacity','ET Everywhere','Multi-program','Master valve support'], '{"zones": 48, "wifi": true, "weather_intelligence": true, "flow_sensor_compatible": true, "master_valve": true}', 'https://www.weathermatic.com/products/smartline-controller'),
  ('SLW', 'SmartLink Wireless Module', 'SmartLink', 'add-on', NULL, NULL, 10, true, false, 150, ARRAY['Wireless two-way communication','Pairs with SmartLine','Up to 1 mile range','No wiring between controller and valves'], '{"wireless_range_ft": 5280, "two_way": true, "compatible_with": "SmartLine"}', 'https://www.weathermatic.com/products/smartlink'),
  ('PL1600-8', 'ProLine 8-Zone', 'ProLine', 'wall-mount', 8, 'zones', 10, false, false, 70, ARRAY['Budget professional','Easy programming','Rain sensor ready','8 stations'], '{"zones": 8, "wifi": false, "seasonal_adjust": true, "rain_sensor_ready": true}', 'https://www.weathermatic.com/products/proline-controller')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs, url)
WHERE m.slug = 'weathermatic' AND c.slug = 'irrigation-controller';

-- Weathermatic Rotors and Spray Heads
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'in-ground', NULL, v.cap, 'radius_ft', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('T3-S04', 'Turbo 3 Rotor', 'Turbo 3', 40, 8, 16, ARRAY['TruJectory adjustable trajectory','Part/full circle','Non-strippable drive','12 nozzles included'], '{"radius_ft": 40, "arc_degrees": 360, "gpm_range": "0.5-6.0", "nozzle_set": "12 included", "pop_up_height": 4, "trajectory_adjustable": true}', 'https://www.weathermatic.com/products/turbo-3-rotor'),
  ('T3-S04-CV', 'Turbo 3 Rotor Check Valve', 'Turbo 3', 40, 8, 20, ARRAY['Built-in check valve','TruJectory','Part/full circle','Prevents low-head drainage'], '{"radius_ft": 40, "arc_degrees": 360, "gpm_range": "0.5-6.0", "nozzle_set": "12 included", "pop_up_height": 4, "check_valve": true, "trajectory_adjustable": true}', 'https://www.weathermatic.com/products/turbo-3-rotor'),
  ('T5-S06', 'Turbo 5 Rotor 6-inch', 'Turbo 5', 52, 10, 32, ARRAY['Large-area rotor','6-inch pop-up','TruJectory','Commercial grade'], '{"radius_ft": 52, "arc_degrees": 360, "gpm_range": "2.5-14.0", "nozzle_set": "included", "pop_up_height": 6, "inlet": "1 inch"}', 'https://www.weathermatic.com/products/turbo-5-rotor'),
  ('MAX-4', 'Max Spray Body 4-inch', 'Max', 15, 8, 4, ARRAY['4-inch pop-up','Spring retraction','Accepts standard nozzles','Professional grade'], '{"radius_ft": 15, "pop_up_height": 4, "inlet": "1/2 inch", "pattern": "interchangeable_nozzle"}', 'https://www.weathermatic.com/products/max-spray-body'),
  ('LX-A', 'LX Adjustable Nozzle 15ft', 'LX Series', 15, 6, 3, ARRAY['Adjustable arc 0-360','Pressure-compensating','Low precipitation','Matched precipitation'], '{"radius_ft": 15, "arc_degrees": 360, "gpm": 1.5, "pattern": "adjustable", "pressure_compensating": true}', 'https://www.weathermatic.com/products/lx-nozzle')
) AS v(model_number, model_name, series, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'weathermatic' AND c.slug = 'sprinkler-head';

-- ======================== NETAFIM (Drip Irrigation Specialist) ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('TLDI-09-12', 'Techline DL Dripline 0.9 GPH 12-inch', 'Techline DL', 'subsurface', NULL, NULL, 15, ARRAY['Subsurface drip irrigation','0.9 GPH emitters','12-inch spacing','Anti-siphon','Copper Shield root barrier'], '{"gph_per_emitter": 0.9, "emitter_spacing_inches": 12, "tubing_diameter": "17mm", "max_run_ft": 300, "root_intrusion_barrier": "Copper Shield", "type": "subsurface_drip"}', 'https://www.netafim.com/products/techline-dl'),
  ('TLDI-06-18', 'Techline DL Dripline 0.6 GPH 18-inch', 'Techline DL', 'subsurface', NULL, NULL, 15, ARRAY['Low-flow subsurface drip','0.6 GPH emitters','18-inch spacing','Copper Shield','Anti-siphon'], '{"gph_per_emitter": 0.6, "emitter_spacing_inches": 18, "tubing_diameter": "17mm", "max_run_ft": 400, "root_intrusion_barrier": "Copper Shield", "type": "subsurface_drip"}', 'https://www.netafim.com/products/techline-dl'),
  ('TLCV-09-12', 'Techline CV Dripline 0.9 GPH', 'Techline CV', 'subsurface', NULL, NULL, 12, ARRAY['Check valve emitters','0.9 GPH','Prevents low-head drainage','Slope irrigation capable'], '{"gph_per_emitter": 0.9, "emitter_spacing_inches": 12, "tubing_diameter": "17mm", "check_valve": true, "type": "subsurface_drip"}', 'https://www.netafim.com/products/techline-cv'),
  ('TECHFIT-12', 'TechFit Retrofit Dripline Kit', 'TechFit', 'surface', NULL, NULL, 10, ARRAY['Retrofit existing spray zones','Pressure-compensating','Self-cleaning emitters','Easy installation'], '{"gph_per_emitter": 0.9, "emitter_spacing_inches": 12, "tubing_diameter": "17mm", "type": "retrofit_drip_kit"}', 'https://www.netafim.com/products/techfit'),
  ('WPCJ-2L', 'WPC Pressure Compensating Dripper 2 GPH', 'WPC', 'surface', NULL, NULL, 8, ARRAY['Pressure-compensating dripper','Self-cleaning','Barbed outlet','2 GPH flow rate'], '{"gph": 2.0, "pressure_compensating": true, "type": "point_source_emitter", "connection": "barb"}', 'https://www.netafim.com/products/wpc-dripper'),
  ('WPCJ-4L', 'WPC Pressure Compensating Dripper 4 GPH', 'WPC', 'surface', NULL, NULL, 8, ARRAY['Pressure-compensating dripper','4 GPH flow rate','Self-cleaning','For larger plants/trees'], '{"gph": 4.0, "pressure_compensating": true, "type": "point_source_emitter", "connection": "barb"}', 'https://www.netafim.com/products/wpc-dripper'),
  ('SPINNET-RG', 'SpinNet Residential Micro-Sprinkler', 'SpinNet', 'above-ground', 20, 'radius_ft', 8, ARRAY['Micro-sprinkler','Rotating deflector','Low precipitation rate','Uniform coverage'], '{"radius_ft": 20, "gph": 14, "pattern": "full_circle", "type": "micro_sprinkler"}', 'https://www.netafim.com/products/spinnet'),
  ('COOLNET-PRO', 'CoolNet Pro Fogger', 'CoolNet', 'above-ground', NULL, NULL, 6, ARRAY['Ultra-fine mist fogger','Greenhouse/patio cooling','Anti-drip mechanism','Low flow'], '{"gph": 2.0, "droplet_size_microns": 50, "type": "fogger_mister", "anti_drip": true}', 'https://www.netafim.com/products/coolnet'),
  ('FLEXNET-KIT', 'FlexNet Landscape Drip Kit', 'FlexNet', 'surface', NULL, NULL, 10, ARRAY['Complete drip kit','Includes tubing, emitters, filter','Easy DIY installation','For garden beds'], '{"kit_coverage_sqft": 200, "tubing_length_ft": 100, "emitter_count": 50, "type": "complete_drip_kit"}', 'https://www.netafim.com/products/flexnet'),
  ('UNIRAM-17', 'UniRam Dripline 0.5 GPH 12-inch', 'UniRam', 'subsurface', NULL, NULL, 15, ARRAY['Anti-siphon dripper','TurboNet filter','Pressure-compensating','Self-flushing'], '{"gph_per_emitter": 0.5, "emitter_spacing_inches": 12, "tubing_diameter": "17mm", "pressure_compensating": true, "type": "subsurface_drip"}', 'https://www.netafim.com/products/uniram')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'netafim' AND c.slug = 'sprinkler-head';

-- ======================== WATTS (Backflow Prevention) ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('009M2-QT-3/4', '009M2-QT 3/4-inch RPZ', '009', 'inline', 1, 'size_inches', 25, 285, ARRAY['Reduced Pressure Zone backflow','3/4-inch','Quarter-turn shutoff','Bronze body','ASSE 1013 listed'], '{"size_inches": 0.75, "type": "RPZ", "max_psi": 175, "material": "bronze", "connection": "threaded", "approval": "ASSE 1013"}', 'https://www.watts.com/products/backflow-prevention/009m2'),
  ('009M2-QT-1', '009M2-QT 1-inch RPZ', '009', 'inline', 1, 'size_inches', 25, 350, ARRAY['Reduced Pressure Zone backflow','1-inch','Quarter-turn shutoff','Bronze body','ASSE 1013'], '{"size_inches": 1.0, "type": "RPZ", "max_psi": 175, "material": "bronze", "connection": "threaded", "approval": "ASSE 1013"}', 'https://www.watts.com/products/backflow-prevention/009m2'),
  ('009M2-QT-1.5', '009M2-QT 1-1/2-inch RPZ', '009', 'inline', 2, 'size_inches', 25, 750, ARRAY['Reduced Pressure Zone backflow','1-1/2 inch','Quarter-turn shutoff','Bronze body','Commercial'], '{"size_inches": 1.5, "type": "RPZ", "max_psi": 175, "material": "bronze", "connection": "threaded", "approval": "ASSE 1013"}', 'https://www.watts.com/products/backflow-prevention/009m2'),
  ('009M2-QT-2', '009M2-QT 2-inch RPZ', '009', 'inline', 2, 'size_inches', 25, 1100, ARRAY['Reduced Pressure Zone backflow','2-inch','Commercial/large residential','Quarter-turn shutoff','Bronze'], '{"size_inches": 2.0, "type": "RPZ", "max_psi": 175, "material": "bronze", "connection": "flanged", "approval": "ASSE 1013"}', 'https://www.watts.com/products/backflow-prevention/009m2'),
  ('007M1-QT-3/4', '007M1-QT 3/4-inch DCVA', '007', 'inline', 1, 'size_inches', 25, 130, ARRAY['Double Check Valve Assembly','3/4-inch','Quarter-turn shutoff','Bronze body','Low hazard applications'], '{"size_inches": 0.75, "type": "DCVA", "max_psi": 175, "material": "bronze", "connection": "threaded", "approval": "ASSE 1015"}', 'https://www.watts.com/products/backflow-prevention/007m1'),
  ('007M1-QT-1', '007M1-QT 1-inch DCVA', '007', 'inline', 1, 'size_inches', 25, 175, ARRAY['Double Check Valve Assembly','1-inch','Quarter-turn shutoff','Bronze body','Low hazard'], '{"size_inches": 1.0, "type": "DCVA", "max_psi": 175, "material": "bronze", "connection": "threaded", "approval": "ASSE 1015"}', 'https://www.watts.com/products/backflow-prevention/007m1'),
  ('800M4-QT-3/4', '800M4-QT 3/4-inch PVB', '800', 'above-grade', 1, 'size_inches', 20, 80, ARRAY['Pressure Vacuum Breaker','3/4-inch','Quarter-turn shutoff','Bronze body','Non-testable'], '{"size_inches": 0.75, "type": "PVB", "max_psi": 150, "material": "bronze", "connection": "threaded", "approval": "ASSE 1020"}', 'https://www.watts.com/products/backflow-prevention/800m4'),
  ('800M4-QT-1', '800M4-QT 1-inch PVB', '800', 'above-grade', 1, 'size_inches', 20, 95, ARRAY['Pressure Vacuum Breaker','1-inch','Quarter-turn shutoff','Bronze body','Residential irrigation'], '{"size_inches": 1.0, "type": "PVB", "max_psi": 150, "material": "bronze", "connection": "threaded", "approval": "ASSE 1020"}', 'https://www.watts.com/products/backflow-prevention/800m4'),
  ('LF009M2-QT-3/4', 'LF009M2-QT 3/4-inch Lead-Free RPZ', 'LF009', 'inline', 1, 'size_inches', 25, 340, ARRAY['Lead-free bronze RPZ','3/4-inch','NSF/ANSI 372 compliant','Quarter-turn shutoff','Potable water safe'], '{"size_inches": 0.75, "type": "RPZ", "max_psi": 175, "material": "lead_free_bronze", "connection": "threaded", "approval": "ASSE 1013", "lead_free": true}', 'https://www.watts.com/products/backflow-prevention/lf009m2'),
  ('LF009M2-QT-1', 'LF009M2-QT 1-inch Lead-Free RPZ', 'LF009', 'inline', 1, 'size_inches', 25, 425, ARRAY['Lead-free bronze RPZ','1-inch','NSF/ANSI 372 compliant','Quarter-turn shutoff','Potable water safe'], '{"size_inches": 1.0, "type": "RPZ", "max_psi": 175, "material": "lead_free_bronze", "connection": "threaded", "approval": "ASSE 1013", "lead_free": true}', 'https://www.watts.com/products/backflow-prevention/lf009m2'),
  ('LF007M1-QT-1', 'LF007M1-QT 1-inch Lead-Free DCVA', 'LF007', 'inline', 1, 'size_inches', 25, 210, ARRAY['Lead-free Double Check','1-inch','NSF/ANSI 372 compliant','Quarter-turn shutoff'], '{"size_inches": 1.0, "type": "DCVA", "max_psi": 175, "material": "lead_free_bronze", "connection": "threaded", "approval": "ASSE 1015", "lead_free": true}', 'https://www.watts.com/products/backflow-prevention/lf007m1'),
  ('919-QT-3/4', '919-QT 3/4-inch Spill-Resistant PVB', '919', 'above-grade', 1, 'size_inches', 20, 190, ARRAY['Spill-resistant PVB','3/4-inch','Testable','Quarter-turn shutoff','ASSE 1020 listed'], '{"size_inches": 0.75, "type": "SVB", "max_psi": 150, "material": "bronze", "connection": "threaded", "approval": "ASSE 1020", "spill_resistant": true}', 'https://www.watts.com/products/backflow-prevention/919'),
  ('919-QT-1', '919-QT 1-inch Spill-Resistant PVB', '919', 'above-grade', 1, 'size_inches', 20, 230, ARRAY['Spill-resistant PVB','1-inch','Testable','Quarter-turn shutoff','ASSE 1020'], '{"size_inches": 1.0, "type": "SVB", "max_psi": 150, "material": "bronze", "connection": "threaded", "approval": "ASSE 1020", "spill_resistant": true}', 'https://www.watts.com/products/backflow-prevention/919'),
  ('765-QT-1', '765 1-inch PVB', '765', 'above-grade', 1, 'size_inches', 20, 60, ARRAY['Pressure Vacuum Breaker','1-inch','Quarter-turn shutoff','Economy PVB','Residential irrigation'], '{"size_inches": 1.0, "type": "PVB", "max_psi": 150, "material": "bronze", "connection": "threaded"}', 'https://www.watts.com/products/backflow-prevention/765'),
  ('765-QT-3/4', '765 3/4-inch PVB', '765', 'above-grade', 1, 'size_inches', 20, 50, ARRAY['Pressure Vacuum Breaker','3/4-inch','Quarter-turn shutoff','Economy PVB'], '{"size_inches": 0.75, "type": "PVB", "max_psi": 150, "material": "bronze", "connection": "threaded"}', 'https://www.watts.com/products/backflow-prevention/765')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'watts' AND c.slug = 'backflow-preventer';

-- ======================== RAIN BIRD (Backflow) ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('PVB-075', 'PVB 3/4-inch Pressure Vacuum Breaker', 'PVB', 'above-grade', 1, 'size_inches', 20, 65, ARRAY['Pressure Vacuum Breaker','3/4-inch','Bronze construction','Residential irrigation'], '{"size_inches": 0.75, "type": "PVB", "max_psi": 150, "material": "bronze", "connection": "threaded"}', 'https://www.rainbird.com/products/pressure-vacuum-breaker'),
  ('PVB-100', 'PVB 1-inch Pressure Vacuum Breaker', 'PVB', 'above-grade', 1, 'size_inches', 20, 80, ARRAY['Pressure Vacuum Breaker','1-inch','Bronze construction','Residential irrigation'], '{"size_inches": 1.0, "type": "PVB", "max_psi": 150, "material": "bronze", "connection": "threaded"}', 'https://www.rainbird.com/products/pressure-vacuum-breaker')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'rain-bird' AND c.slug = 'backflow-preventer';

-- ======================== HUNTER (Backflow) ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('HBF-075', 'HBF 3/4-inch PVB', 'HBF', 'above-grade', 1, 'size_inches', 20, 70, ARRAY['Pressure Vacuum Breaker','3/4-inch','Bronze','Residential irrigation backflow'], '{"size_inches": 0.75, "type": "PVB", "max_psi": 150, "material": "bronze", "connection": "threaded"}', 'https://www.hunterindustries.com/product/hbf-backflow'),
  ('HBF-100', 'HBF 1-inch PVB', 'HBF', 'above-grade', 1, 'size_inches', 20, 85, ARRAY['Pressure Vacuum Breaker','1-inch','Bronze','Residential irrigation backflow'], '{"size_inches": 1.0, "type": "PVB", "max_psi": 150, "material": "bronze", "connection": "threaded"}', 'https://www.hunterindustries.com/product/hbf-backflow')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'hunter-industries' AND c.slug = 'backflow-preventer';

-- ======================== TORO/IRRITROL (Backflow) ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('R-075', 'Irritrol R 3/4-inch PVB', 'R Series', 'above-grade', 1, 'size_inches', 20, 55, ARRAY['Pressure Vacuum Breaker','3/4-inch','Bronze body','Residential irrigation'], '{"size_inches": 0.75, "type": "PVB", "max_psi": 150, "material": "bronze", "connection": "threaded"}', 'https://www.irritrol.com/products/backflow-preventer'),
  ('R-100', 'Irritrol R 1-inch PVB', 'R Series', 'above-grade', 1, 'size_inches', 20, 68, ARRAY['Pressure Vacuum Breaker','1-inch','Bronze body','Residential irrigation'], '{"size_inches": 1.0, "type": "PVB", "max_psi": 150, "material": "bronze", "connection": "threaded"}', 'https://www.irritrol.com/products/backflow-preventer')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'irritrol' AND c.slug = 'backflow-preventer';

-- ======================== ORBIT (Backflow / Valves) ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('51050', 'Orbit 3/4-inch Anti-Siphon Valve', 'Orbit', 'above-grade', 1, 'size_inches', 15, 12, ARRAY['Anti-siphon valve with backflow prevention','3/4-inch','Manual bleed','Budget-friendly'], '{"size_inches": 0.75, "type": "anti_siphon_valve", "max_psi": 150, "material": "plastic", "connection": "threaded"}', 'https://www.orbitonline.com/product/anti-siphon-valve'),
  ('51060', 'Orbit 1-inch Anti-Siphon Valve', 'Orbit', 'above-grade', 1, 'size_inches', 15, 14, ARRAY['Anti-siphon valve with backflow prevention','1-inch','Manual bleed','Budget-friendly'], '{"size_inches": 1.0, "type": "anti_siphon_valve", "max_psi": 150, "material": "plastic", "connection": "threaded"}', 'https://www.orbitonline.com/product/anti-siphon-valve'),
  ('51017', 'Orbit 3/4-inch Brass Anti-Siphon Valve', 'Orbit', 'above-grade', 1, 'size_inches', 20, 25, ARRAY['Brass anti-siphon valve','3/4-inch','Heavy-duty construction','Manual bleed'], '{"size_inches": 0.75, "type": "anti_siphon_valve", "max_psi": 150, "material": "brass", "connection": "threaded"}', 'https://www.orbitonline.com/product/brass-anti-siphon-valve')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'orbit' AND c.slug = 'backflow-preventer';

-- ============================================================================
-- Summary: 126 total irrigation equipment entries
-- Rachio:        6 controllers
-- Rain Bird:     6 controllers + 4 rotors + 5 spray heads + 2 backflow = 17
-- Hunter:        5 controllers + 5 rotors + 6 spray heads + 2 backflow = 18
-- Toro:          5 controllers + 3 rotors + 4 spray/nozzle = 12
-- Orbit:         7 controllers + 6 spray/rotors + 3 backflow = 16
-- Irritrol:      4 controllers + 5 rotors/spray + 2 backflow = 11
-- K-Rain:        5 controllers + 6 rotors/spray = 11
-- Weathermatic:  5 controllers + 5 rotors/spray = 10
-- Netafim:       10 drip components
-- Watts:         15 backflow preventers
-- ============================================================================
