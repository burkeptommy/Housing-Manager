-- ============================================================================
-- Laundry Equipment Catalog: ALL Brands
-- Budget: Amana, Hotpoint, Roper, Crosley
-- Mainstream: Whirlpool, GE Appliances, Samsung, LG, Maytag, Frigidaire, Blomberg
-- Premium: KitchenAid, GE Profile, Electrolux, Fisher & Paykel, Speed Queen, Haier, Asko
-- Luxury: Miele, Bosch
-- Combo/Specialty: Equator
-- ============================================================================

SET ROLE postgres;

-- ============================================================================
-- BUDGET BRANDS
-- ============================================================================

-- ======================== AMANA ========================

-- Amana Top-Load Washers (Agitator)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.amana.com/washers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('NTW4516FW', 'Amana 3.5 cu ft Top-Load Washer', NULL, 'electric', 27, 3.5, 12, false, false, 499, ARRAY['Dual Action Agitator','Porcelain tub','Late lid lock','Deep water wash option'], '{"spin_speed_rpm": 700, "cycles": 8, "steam": false, "load_type": "top", "noise_dba": 55}'),
  ('NTW4519JW', 'Amana 4.0 cu ft Top-Load Washer', NULL, 'electric', 27, 4.0, 12, false, false, 549, ARRAY['Dual Action Agitator','Stainless steel tub','Late lid lock','High efficiency'], '{"spin_speed_rpm": 700, "cycles": 9, "steam": false, "load_type": "top", "noise_dba": 54}'),
  ('NTW4605EW', 'Amana 3.5 cu ft Top-Load Washer with Dual Action Agitator', NULL, 'electric', 27, 3.5, 12, false, false, 479, ARRAY['Dual Action Agitator','Porcelain tub','8 wash cycles'], '{"spin_speed_rpm": 680, "cycles": 8, "steam": false, "load_type": "top", "noise_dba": 56}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'amana' AND c.slug = 'washer-top-load-agitator';

-- Amana Electric Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.amana.com/dryers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('NED4655EW', 'Amana 6.5 cu ft Electric Dryer', NULL, 'electric', 29, 6.5, 13, false, false, 499, ARRAY['11 dry cycles','Automatic dryness control','Wrinkle Prevent option'], '{"cycles": 11, "steam": false, "moisture_sensor": true, "vent_type": "vented"}'),
  ('NED5240TQ', 'Amana 7.0 cu ft Electric Dryer', NULL, 'electric', 29, 7.0, 13, false, false, 549, ARRAY['Automatic dryness control','Wrinkle Prevent option','Interior drum light'], '{"cycles": 11, "steam": false, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'amana' AND c.slug = 'dryer-electric';

-- Amana Gas Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.amana.com/dryers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('NGD4655EW', 'Amana 6.5 cu ft Gas Dryer', NULL, 'gas', 29, 6.5, 14, false, false, 599, ARRAY['11 dry cycles','Automatic dryness control','Wrinkle Prevent option'], '{"cycles": 11, "steam": false, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'amana' AND c.slug = 'dryer-gas';

-- ======================== HOTPOINT ========================

-- Hotpoint Top-Load Washers (Agitator)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.hotpoint.com/washers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('HTW240ASKWS', 'Hotpoint 3.8 cu ft Top-Load Washer', NULL, 'electric', 27, 3.8, 11, false, false, 529, ARRAY['Stainless steel basket','Heavy Duty agitator','Bleach and fabric softener dispensers'], '{"spin_speed_rpm": 700, "cycles": 8, "steam": false, "load_type": "top", "noise_dba": 56}'),
  ('HTW200ASKWW', 'Hotpoint 3.8 cu ft White Top-Load Washer', NULL, 'electric', 27, 3.8, 11, false, false, 499, ARRAY['Stainless steel basket','Agitator wash action','6 wash cycles'], '{"spin_speed_rpm": 700, "cycles": 6, "steam": false, "load_type": "top", "noise_dba": 57}'),
  ('HTW240ASKWS2', 'Hotpoint 4.0 cu ft Top-Load Washer', NULL, 'electric', 27, 4.0, 11, false, false, 549, ARRAY['Stainless steel basket','Deep rinse option','Auto soak'], '{"spin_speed_rpm": 700, "cycles": 9, "steam": false, "load_type": "top", "noise_dba": 55}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'hotpoint' AND c.slug = 'washer-top-load-agitator';

-- Hotpoint Electric Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.hotpoint.com/dryers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('HTX24EASKWS', 'Hotpoint 6.2 cu ft Electric Dryer', NULL, 'electric', 27, 6.2, 13, false, false, 499, ARRAY['Auto Dry cycle','4 heat selections','Upfront lint filter'], '{"cycles": 6, "steam": false, "moisture_sensor": true, "vent_type": "vented"}'),
  ('HTX24GASKWS', 'Hotpoint 6.2 cu ft Aluminized Alloy Drum Dryer', NULL, 'electric', 27, 6.2, 13, false, false, 529, ARRAY['Auto Dry cycle','Aluminized alloy drum','Wrinkle prevention'], '{"cycles": 6, "steam": false, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'hotpoint' AND c.slug = 'dryer-electric';

-- ======================== ROPER ========================

-- Roper Top-Load Washers (Agitator)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.roper-appliances.com/washers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('RTW4516FW', 'Roper 3.5 cu ft Top-Load Washer', NULL, 'electric', 27, 3.5, 11, false, false, 449, ARRAY['Deep water wash option','Dual-Action agitator','Porcelain tub'], '{"spin_speed_rpm": 680, "cycles": 8, "steam": false, "load_type": "top", "noise_dba": 57}'),
  ('RTW4616FW', 'Roper 3.5 cu ft Top-Load Washer with Extra Rinse', NULL, 'electric', 27, 3.5, 11, false, false, 469, ARRAY['Extra rinse option','Automatic water level','Dual-Action agitator'], '{"spin_speed_rpm": 680, "cycles": 9, "steam": false, "load_type": "top", "noise_dba": 57}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'roper' AND c.slug = 'washer-top-load-agitator';

-- Roper Electric Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.roper-appliances.com/dryers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('RED4516FW', 'Roper 6.5 cu ft Electric Dryer', NULL, 'electric', 29, 6.5, 13, false, false, 449, ARRAY['Wrinkle Prevent option','Automatic dryness control','3 temperature settings'], '{"cycles": 6, "steam": false, "moisture_sensor": true, "vent_type": "vented"}'),
  ('RGD4516FW', 'Roper 6.5 cu ft Electric Vented Dryer', NULL, 'electric', 29, 6.5, 13, false, false, 469, ARRAY['AutoDry sensor','Wrinkle prevent','Interior light'], '{"cycles": 7, "steam": false, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'roper' AND c.slug = 'dryer-electric';

-- ======================== CROSLEY ========================

-- Crosley Top-Load Washers (Agitator)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.crosleyappliances.com/washers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('CAW3584GW', 'Crosley 3.5 cu ft Top-Load Washer', NULL, 'electric', 27, 3.5, 11, false, false, 449, ARRAY['Dual-Action agitator','Porcelain tub','Deep water wash'], '{"spin_speed_rpm": 680, "cycles": 8, "steam": false, "load_type": "top", "noise_dba": 57}'),
  ('CAW4254GW', 'Crosley 4.2 cu ft Top-Load Washer', NULL, 'electric', 27, 4.2, 11, false, false, 499, ARRAY['Deep water wash option','Stainless steel tub','11 wash cycles'], '{"spin_speed_rpm": 700, "cycles": 11, "steam": false, "load_type": "top", "noise_dba": 55}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'crosley' AND c.slug = 'washer-top-load-agitator';

-- Crosley Electric Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.crosleyappliances.com/dryers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('CED4655GW', 'Crosley 6.5 cu ft Electric Dryer', NULL, 'electric', 29, 6.5, 13, false, false, 449, ARRAY['Wrinkle Prevent option','Automatic dryness control','3 temperature settings'], '{"cycles": 6, "steam": false, "moisture_sensor": true, "vent_type": "vented"}'),
  ('CED7011GW', 'Crosley 7.0 cu ft Electric Dryer', NULL, 'electric', 29, 7.0, 13, false, false, 499, ARRAY['Hamper door','AutoDry moisture sensing','Interior light'], '{"cycles": 9, "steam": false, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'crosley' AND c.slug = 'dryer-electric';

-- ============================================================================
-- MAINSTREAM BRANDS
-- ============================================================================

-- ======================== WHIRLPOOL ========================

-- Whirlpool Front-Load Washers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.whirlpool.com/laundry/washers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WFW5605MW', 'Whirlpool 4.5 cu ft Front-Load Washer', NULL, 'electric', 27, 4.5, 11, true, true, 899, ARRAY['Quick Wash cycle','Presoak option','Wrinkle Shield','Intuitive controls'], '{"spin_speed_rpm": 1200, "cycles": 10, "steam": false, "load_type": "front", "noise_dba": 50}'),
  ('WFW6605MW', 'Whirlpool 5.0 cu ft Front-Load Washer with Steam', NULL, 'electric', 27, 5.0, 11, true, true, 999, ARRAY['Steam Clean','Quick Wash','Wrinkle Shield Plus','Load & Go dispenser'], '{"spin_speed_rpm": 1300, "cycles": 12, "steam": true, "load_type": "front", "noise_dba": 48}'),
  ('WFW9505FW', 'Whirlpool 4.5 cu ft Front-Load Washer with ColorLast', NULL, 'electric', 27, 4.5, 11, true, true, 949, ARRAY['ColorLast option','Adaptive Wash','FanFresh option','12-hour tumble'], '{"spin_speed_rpm": 1200, "cycles": 12, "steam": true, "load_type": "front", "noise_dba": 49}'),
  ('WFW5605MC', 'Whirlpool 4.5 cu ft Chrome Shadow Front-Load Washer', NULL, 'electric', 27, 4.5, 11, true, true, 949, ARRAY['Quick Wash cycle','Presoak option','Chrome Shadow finish','Wrinkle Shield'], '{"spin_speed_rpm": 1200, "cycles": 10, "steam": false, "load_type": "front", "noise_dba": 50}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'whirlpool' AND c.slug = 'washer-front-load';

-- Whirlpool Top-Load Washers (Agitator)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.whirlpool.com/laundry/washers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WTW5000DW', 'Whirlpool 4.3 cu ft Top-Load Washer', NULL, 'electric', 27, 4.3, 12, false, false, 649, ARRAY['Built-in water faucet','Stainless steel tub','Presoak option','Quick Wash'], '{"spin_speed_rpm": 700, "cycles": 12, "steam": false, "load_type": "top", "noise_dba": 53}'),
  ('WTW4816FW', 'Whirlpool 3.5 cu ft Top-Load Washer', NULL, 'electric', 27, 3.5, 12, false, false, 549, ARRAY['Dual-Action agitator','Deep Water Wash','Automatic water levels'], '{"spin_speed_rpm": 680, "cycles": 9, "steam": false, "load_type": "top", "noise_dba": 55}'),
  ('WTW4955HW', 'Whirlpool 3.8 cu ft Top-Load Washer with Soaking Cycles', NULL, 'electric', 27, 3.8, 12, false, false, 599, ARRAY['Soaking cycles','Removable agitator','Water level selection'], '{"spin_speed_rpm": 700, "cycles": 12, "steam": false, "load_type": "top", "noise_dba": 54}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'whirlpool' AND c.slug = 'washer-top-load-agitator';

-- Whirlpool Top-Load Washers (Impeller)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.whirlpool.com/laundry/washers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WTW5057LW', 'Whirlpool 4.7 cu ft Top-Load Impeller Washer', NULL, 'electric', 27, 4.7, 11, true, true, 749, ARRAY['Built-in water faucet','Impeller wash action','Presoak option','Quick Wash'], '{"spin_speed_rpm": 800, "cycles": 12, "steam": false, "load_type": "top", "noise_dba": 51}'),
  ('WTW5105HW', 'Whirlpool 4.7 cu ft Top-Load HE Washer', NULL, 'electric', 27, 4.7, 11, true, true, 799, ARRAY['2 in 1 removable agitator','Pretreat Station Plus','Quick Wash','Adaptive Wash'], '{"spin_speed_rpm": 800, "cycles": 13, "steam": false, "load_type": "top", "noise_dba": 50}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'whirlpool' AND c.slug = 'washer-top-load-impeller';

-- Whirlpool Electric Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.whirlpool.com/laundry/dryers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WED5000DW', 'Whirlpool 7.0 cu ft Electric Dryer', NULL, 'electric', 29, 7.0, 13, false, true, 649, ARRAY['AutoDry drying system','Wrinkle Shield option','AccuDry sensor system'], '{"cycles": 12, "steam": false, "moisture_sensor": true, "vent_type": "vented"}'),
  ('WED5605MW', 'Whirlpool 7.4 cu ft Electric Dryer with Wrinkle Shield', NULL, 'electric', 27, 7.4, 13, true, true, 899, ARRAY['Wrinkle Shield Plus','Intuitive controls','EcoBoost option','Quick Dry'], '{"cycles": 12, "steam": false, "moisture_sensor": true, "vent_type": "vented"}'),
  ('WED6605MW', 'Whirlpool 7.4 cu ft Electric Dryer with Steam', NULL, 'electric', 27, 7.4, 13, true, true, 999, ARRAY['Steam Refresh','Wrinkle Shield Plus','Advanced Moisture Sensing','EcoBoost'], '{"cycles": 13, "steam": true, "moisture_sensor": true, "vent_type": "vented"}'),
  ('WED9505FW', 'Whirlpool 7.4 cu ft HybridCare Ventless Dryer', NULL, 'electric', 27, 7.4, 13, true, true, 1199, ARRAY['Ventless heat pump drying','HybridCare','Advanced Moisture Sensing','EcoBoost'], '{"cycles": 14, "steam": false, "moisture_sensor": true, "vent_type": "ventless"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'whirlpool' AND c.slug = 'dryer-electric';

-- Whirlpool Gas Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.whirlpool.com/laundry/dryers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WGD5000DW', 'Whirlpool 7.0 cu ft Gas Dryer', NULL, 'gas', 29, 7.0, 14, false, false, 749, ARRAY['AutoDry drying system','Wrinkle Shield option','AccuDry sensor system'], '{"cycles": 12, "steam": false, "moisture_sensor": true, "vent_type": "vented"}'),
  ('WGD5605MW', 'Whirlpool 7.4 cu ft Gas Dryer with Wrinkle Shield', NULL, 'gas', 27, 7.4, 14, true, true, 999, ARRAY['Wrinkle Shield Plus','Intuitive controls','Quick Dry cycle'], '{"cycles": 12, "steam": false, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'whirlpool' AND c.slug = 'dryer-gas';

-- ======================== GE APPLIANCES ========================

-- GE Front-Load Washers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.geappliances.com/laundry/washers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('GFW550SSNWW', 'GE 4.8 cu ft Front-Load Washer with UltraFresh Vent', NULL, 'electric', 28, 4.8, 11, true, true, 899, ARRAY['UltraFresh Vent System with OdorBlock','Microban antimicrobial','Dynamic Balancing Technology','Quick Wash'], '{"spin_speed_rpm": 1300, "cycles": 12, "steam": false, "load_type": "front", "noise_dba": 48}'),
  ('GFW655SSVWW', 'GE 5.0 cu ft Front-Load Washer with Steam', NULL, 'electric', 28, 5.0, 11, true, true, 999, ARRAY['Steam washing','UltraFresh Vent System','Built-in WiFi','SmartDispense'], '{"spin_speed_rpm": 1300, "cycles": 12, "steam": true, "load_type": "front", "noise_dba": 47}'),
  ('GFW850SPNRS', 'GE 5.0 cu ft Sapphire Blue Front-Load Washer', NULL, 'electric', 28, 5.0, 11, true, true, 1099, ARRAY['SmartDispense','UltraFresh Vent','Microban technology','1-step wash + dry'], '{"spin_speed_rpm": 1300, "cycles": 12, "steam": true, "load_type": "front", "noise_dba": 46}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ge-appliances' AND c.slug = 'washer-front-load';

-- GE Top-Load Washers (Agitator)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.geappliances.com/laundry/washers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('GTW465ASNWW', 'GE 4.5 cu ft Top-Load Washer with Agitator', NULL, 'electric', 27, 4.5, 12, false, false, 629, ARRAY['Stainless steel basket','Deep Fill option','Speed Wash cycle'], '{"spin_speed_rpm": 700, "cycles": 11, "steam": false, "load_type": "top", "noise_dba": 54}'),
  ('GTW525ACNWW', 'GE 4.6 cu ft Top-Load Washer with Infusor', NULL, 'electric', 27, 4.6, 12, false, false, 649, ARRAY['Dual Action agitator','Deep rinse','Auto Soak'], '{"spin_speed_rpm": 700, "cycles": 11, "steam": false, "load_type": "top", "noise_dba": 53}'),
  ('GTW720BSNWS', 'GE 4.8 cu ft Top-Load Washer with FlexDispense', NULL, 'electric', 27, 4.8, 12, true, true, 799, ARRAY['FlexDispense detergent drawer','WiFi enabled','Deep Fill','Tide PODS dispenser'], '{"spin_speed_rpm": 800, "cycles": 14, "steam": false, "load_type": "top", "noise_dba": 51}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ge-appliances' AND c.slug = 'washer-top-load-agitator';

-- GE Top-Load Washers (Impeller)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.geappliances.com/laundry/washers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('GTW840CPNDG', 'GE 5.2 cu ft Top-Load Impeller Washer', NULL, 'electric', 27, 5.2, 11, true, true, 949, ARRAY['SmartDispense','WiFi enabled','Built-in water faucet','Sanitize with Oxi'], '{"spin_speed_rpm": 800, "cycles": 14, "steam": false, "load_type": "top", "noise_dba": 49}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ge-appliances' AND c.slug = 'washer-top-load-impeller';

-- GE Electric Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.geappliances.com/laundry/dryers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('GTD45EASJWS', 'GE 7.2 cu ft Electric Dryer with Sensor Dry', NULL, 'electric', 27, 7.2, 13, false, false, 629, ARRAY['HE Sensor Dry','Auto Dry','Extended tumble','4 heat selections'], '{"cycles": 7, "steam": false, "moisture_sensor": true, "vent_type": "vented"}'),
  ('GFD55ESSNWW', 'GE 7.8 cu ft Front-Load Electric Dryer with Steam', NULL, 'electric', 28, 7.8, 13, true, true, 899, ARRAY['Steam Dewrinkle','Sanitize cycle','WiFi connectivity','Sensor Dry'], '{"cycles": 12, "steam": true, "moisture_sensor": true, "vent_type": "vented"}'),
  ('GFD85ESPNRS', 'GE 7.8 cu ft Sapphire Blue Electric Dryer', NULL, 'electric', 28, 7.8, 13, true, true, 1099, ARRAY['SmartHQ app','Steam Dewrinkle','Sanitize cycle','Quick Dry'], '{"cycles": 13, "steam": true, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ge-appliances' AND c.slug = 'dryer-electric';

-- GE Gas Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.geappliances.com/laundry/dryers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('GTD45GASJWS', 'GE 7.2 cu ft Gas Dryer with Sensor Dry', NULL, 'gas', 27, 7.2, 14, false, false, 729, ARRAY['HE Sensor Dry','Auto Dry','Extended tumble','4 heat selections'], '{"cycles": 7, "steam": false, "moisture_sensor": true, "vent_type": "vented"}'),
  ('GFD55GSSNWW', 'GE 7.8 cu ft Gas Dryer with Steam', NULL, 'gas', 28, 7.8, 14, true, true, 999, ARRAY['Steam Dewrinkle','Sanitize cycle','WiFi connectivity','Sensor Dry'], '{"cycles": 12, "steam": true, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ge-appliances' AND c.slug = 'dryer-gas';

-- ======================== SAMSUNG ========================

-- Samsung Front-Load Washers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.samsung.com/us/washers/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WF45R6100AW', 'Samsung 4.5 cu ft Front-Load Washer', NULL, 'electric', 27, 4.5, 11, true, true, 799, ARRAY['Self Clean+','Smart Care','Vibration Reduction Technology+','Steam Wash'], '{"spin_speed_rpm": 1200, "cycles": 10, "steam": true, "load_type": "front", "noise_dba": 48}'),
  ('WF45R6300AV', 'Samsung 4.5 cu ft Front-Load Washer with Steam', 'Smart', 'electric', 27, 4.5, 11, true, true, 899, ARRAY['Steam Wash','Self Clean+','VRT Plus','SmartThings App'], '{"spin_speed_rpm": 1200, "cycles": 12, "steam": true, "load_type": "front", "noise_dba": 47}'),
  ('WF45B6300AW', 'Samsung 4.5 cu ft Large Capacity Front-Load Washer', 'Bespoke', 'electric', 27, 4.5, 11, true, true, 949, ARRAY['AI OptiWash','Super Speed Wash','Steam Sanitize+','Self Clean+'], '{"spin_speed_rpm": 1300, "cycles": 12, "steam": true, "load_type": "front", "noise_dba": 46}'),
  ('WF53BB8700AT', 'Samsung Bespoke 5.3 cu ft Ultra Capacity Front-Load Washer', 'Bespoke AI', 'electric', 27, 5.3, 11, true, true, 1149, ARRAY['AI OptiWash','Bespoke design','CleanGuard door','Super Speed Wash 28min','MultiControl'], '{"spin_speed_rpm": 1300, "cycles": 14, "steam": true, "load_type": "front", "noise_dba": 44}'),
  ('WF45T6000AW', 'Samsung 4.5 cu ft Front-Load Washer with Vibration Reduction', NULL, 'electric', 27, 4.5, 11, false, true, 699, ARRAY['VRT Plus technology','Self Clean+','Shallow Depth','Quick Wash'], '{"spin_speed_rpm": 1200, "cycles": 10, "steam": false, "load_type": "front", "noise_dba": 49}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'samsung' AND c.slug = 'washer-front-load';

-- Samsung Top-Load Washers (Impeller)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.samsung.com/us/washers/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WA45T3200AW', 'Samsung 4.5 cu ft Top-Load Washer', NULL, 'electric', 27, 4.5, 11, false, true, 599, ARRAY['Vibration Reduction Technology','Soft-Close Lid','Self Clean','Diamond Drum'], '{"spin_speed_rpm": 750, "cycles": 8, "steam": false, "load_type": "top", "noise_dba": 52}'),
  ('WA50R5400AW', 'Samsung 5.0 cu ft Top-Load Washer with Super Speed', NULL, 'electric', 27, 5.0, 11, true, true, 799, ARRAY['Super Speed Wash','Active WaterJet','EZ Access tub','Smart Care'], '{"spin_speed_rpm": 800, "cycles": 10, "steam": false, "load_type": "top", "noise_dba": 50}'),
  ('WA55CG7100AW', 'Samsung 5.5 cu ft Extra-Large Top-Load Washer', NULL, 'electric', 27, 5.5, 11, true, true, 899, ARRAY['Super Speed Wash','Active WaterJet built-in faucet','WiFi connectivity','EZ Access tub'], '{"spin_speed_rpm": 800, "cycles": 12, "steam": false, "load_type": "top", "noise_dba": 49}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'samsung' AND c.slug = 'washer-top-load-impeller';

-- Samsung Electric Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.samsung.com/us/dryers/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DVE45R6100W', 'Samsung 7.5 cu ft Electric Dryer with Sensor Dry', NULL, 'electric', 27, 7.5, 13, true, true, 799, ARRAY['Sensor Dry','Steam Sanitize+','Smart Care','Vent sensor'], '{"cycles": 10, "steam": true, "moisture_sensor": true, "vent_type": "vented"}'),
  ('DVE45B6300W', 'Samsung 7.5 cu ft Smart Electric Dryer with Steam Sanitize+', 'Bespoke', 'electric', 27, 7.5, 13, true, true, 949, ARRAY['AI Optimal Dry','Steam Sanitize+','Sensor Dry','Lint filter indicator'], '{"cycles": 12, "steam": true, "moisture_sensor": true, "vent_type": "vented"}'),
  ('DVE53BB8700T', 'Samsung Bespoke 7.6 cu ft Ultra Capacity Electric Dryer', 'Bespoke AI', 'electric', 27, 7.6, 13, true, true, 1149, ARRAY['AI Optimal Dry','Super Speed Dry','Steam Sanitize+','Bespoke design'], '{"cycles": 14, "steam": true, "moisture_sensor": true, "vent_type": "vented"}'),
  ('DVE45T6000W', 'Samsung 7.5 cu ft Electric Dryer with Sensor Dry', NULL, 'electric', 27, 7.5, 13, false, true, 699, ARRAY['Sensor Dry','Lint filter indicator','Smart Care','Reversible door'], '{"cycles": 10, "steam": false, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'samsung' AND c.slug = 'dryer-electric';

-- Samsung Gas Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.samsung.com/us/dryers/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DVG45R6100W', 'Samsung 7.5 cu ft Gas Dryer with Sensor Dry', NULL, 'gas', 27, 7.5, 14, true, true, 899, ARRAY['Sensor Dry','Steam Sanitize+','Smart Care','Vent sensor'], '{"cycles": 10, "steam": true, "moisture_sensor": true, "vent_type": "vented"}'),
  ('DVG45B6300W', 'Samsung 7.5 cu ft Smart Gas Dryer', 'Bespoke', 'gas', 27, 7.5, 14, true, true, 1049, ARRAY['AI Optimal Dry','Steam Sanitize+','Sensor Dry','WiFi enabled'], '{"cycles": 12, "steam": true, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'samsung' AND c.slug = 'dryer-gas';

-- Samsung Garment Care (AirDresser)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.samsung.com/us/airdresser/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DF60R8600CG', 'Samsung AirDresser', 'AirDresser', 'electric', 24, 3.0, 10, true, false, 1499, ARRAY['JetSteam sanitization','Air Hangers','Deodorizing filter','Heat Pump drying','3 hangers capacity'], '{"cycles": 7, "steam": true, "garment_capacity": 3, "deodorize": true}'),
  ('DF10A9500CG', 'Samsung Bespoke AirDresser', 'Bespoke AirDresser', 'electric', 24, 3.0, 10, true, false, 1599, ARRAY['JetSteam','AI Wrinkle Care','Self Clean','Bespoke design','SmartThings integration'], '{"cycles": 8, "steam": true, "garment_capacity": 3, "deodorize": true}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'samsung' AND c.slug = 'garment-care';

-- ======================== LG ========================

-- LG Front-Load Washers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.lg.com/us/washers/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WM3400CW', 'LG 4.5 cu ft Front-Load Washer', NULL, 'electric', 27, 4.5, 11, false, true, 749, ARRAY['6Motion Technology','LoDecibel Quiet Operation','SmartDiagnosis','ColdWash technology'], '{"spin_speed_rpm": 1200, "cycles": 10, "steam": false, "load_type": "front", "noise_dba": 48}'),
  ('WM4000HWA', 'LG 4.5 cu ft Smart Front-Load Washer with TurboWash 360', NULL, 'electric', 27, 4.5, 11, true, true, 899, ARRAY['TurboWash 360','LG ThinQ app','6Motion Technology','Steam technology','Allergiene cycle'], '{"spin_speed_rpm": 1300, "cycles": 12, "steam": true, "load_type": "front", "noise_dba": 46}'),
  ('WM4500HBA', 'LG 5.0 cu ft Mega Capacity Front-Load Washer', NULL, 'electric', 27, 5.0, 11, true, true, 999, ARRAY['TurboWash 360','AI DD built-in intelligence','Steam','ezDispense','Tempered glass door'], '{"spin_speed_rpm": 1300, "cycles": 14, "steam": true, "load_type": "front", "noise_dba": 44}'),
  ('WM6700HBA', 'LG 5.0 cu ft Mega Capacity Smart wi-fi Enabled Front-Load Washer', NULL, 'electric', 27, 5.0, 11, true, true, 1199, ARRAY['AI DD 2.0','TurboWash 360','Allergiene cycle','Steam+Allergiene','ezDispense'], '{"spin_speed_rpm": 1400, "cycles": 14, "steam": true, "load_type": "front", "noise_dba": 43}'),
  ('WM8900HBA', 'LG Signature 5.8 cu ft Front-Load Washer', 'LG SIGNATURE', 'electric', 29, 5.8, 11, true, true, 1699, ARRAY['LG SIGNATURE design','TurboWash 360','SideKick pedestal washer compatible','Centum motor'], '{"spin_speed_rpm": 1400, "cycles": 14, "steam": true, "load_type": "front", "noise_dba": 41}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'lg' AND c.slug = 'washer-front-load';

-- LG Top-Load Washers (Impeller)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.lg.com/us/washers/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WT7150CW', 'LG 5.0 cu ft Top-Load Washer', NULL, 'electric', 27, 5.0, 11, false, true, 699, ARRAY['TurboDrum technology','ColdWash','SmartDiagnosis','SlamProof glass lid'], '{"spin_speed_rpm": 800, "cycles": 8, "steam": false, "load_type": "top", "noise_dba": 52}'),
  ('WT7400CV', 'LG 5.5 cu ft Smart Top-Load Washer with TurboWash3D', NULL, 'electric', 27, 5.5, 11, true, true, 899, ARRAY['TurboWash3D technology','WiFi enabled','6Motion Technology','ColdWash'], '{"spin_speed_rpm": 950, "cycles": 12, "steam": true, "load_type": "top", "noise_dba": 49}'),
  ('WT7900HBA', 'LG 5.5 cu ft Smart Top-Load Washer', NULL, 'electric', 27, 5.5, 11, true, true, 1049, ARRAY['TurboWash3D','AI DD built-in intelligence','Steam','ezDispense','Allergiene cycle'], '{"spin_speed_rpm": 950, "cycles": 14, "steam": true, "load_type": "top", "noise_dba": 48}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'lg' AND c.slug = 'washer-top-load-impeller';

-- LG Electric Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.lg.com/us/dryers/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DLE3400W', 'LG 7.4 cu ft Electric Dryer with Sensor Dry', NULL, 'electric', 27, 7.4, 13, false, true, 749, ARRAY['Sensor Dry system','FlowSense duct clogging indicator','LoDecibel quiet','SmartDiagnosis'], '{"cycles": 8, "steam": false, "moisture_sensor": true, "vent_type": "vented"}'),
  ('DLEX4000B', 'LG 7.4 cu ft Smart Electric Dryer with Steam', NULL, 'electric', 27, 7.4, 13, true, true, 899, ARRAY['TurboSteam','Sensor Dry','LG ThinQ app','ReduceStatic','Wrinkle Care'], '{"cycles": 12, "steam": true, "moisture_sensor": true, "vent_type": "vented"}'),
  ('DLEX4500B', 'LG 7.4 cu ft Smart Electric Dryer with TurboSteam', NULL, 'electric', 27, 7.4, 13, true, true, 999, ARRAY['TurboSteam','AI Fabric Sensor','Proactive Customer Care','Built-in intelligence'], '{"cycles": 14, "steam": true, "moisture_sensor": true, "vent_type": "vented"}'),
  ('DLHC5502V', 'LG 7.8 cu ft Smart Electric Heat Pump Dryer', NULL, 'electric', 27, 7.8, 13, true, true, 1299, ARRAY['DUAL Inverter Heat Pump','Ventless','Energy Star Most Efficient','LG ThinQ'], '{"cycles": 14, "steam": false, "moisture_sensor": true, "vent_type": "ventless"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'lg' AND c.slug = 'dryer-electric';

-- LG Gas Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.lg.com/us/dryers/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DLG3401W', 'LG 7.4 cu ft Gas Dryer with Sensor Dry', NULL, 'gas', 27, 7.4, 14, false, true, 849, ARRAY['Sensor Dry system','FlowSense','LoDecibel quiet','SmartDiagnosis'], '{"cycles": 8, "steam": false, "moisture_sensor": true, "vent_type": "vented"}'),
  ('DLGX4001B', 'LG 7.4 cu ft Smart Gas Dryer with TurboSteam', NULL, 'gas', 27, 7.4, 14, true, true, 999, ARRAY['TurboSteam','Sensor Dry','LG ThinQ app','ReduceStatic'], '{"cycles": 12, "steam": true, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'lg' AND c.slug = 'dryer-gas';

-- LG Heat Pump Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.lg.com/us/dryers/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DLHC1455V', 'LG 4.2 cu ft Compact Heat Pump Dryer', NULL, 'electric', 24, 4.2, 13, true, true, 1199, ARRAY['DUAL Inverter Heat Pump','Ventless design','Sensor Dry','WiFi enabled','Stackable'], '{"cycles": 14, "steam": false, "moisture_sensor": true, "vent_type": "ventless"}'),
  ('DLHC5502W', 'LG 7.8 cu ft Smart Heat Pump Dryer', NULL, 'electric', 27, 7.8, 13, true, true, 1299, ARRAY['DUAL Inverter Heat Pump','Ventless','Energy Star Most Efficient','Proactive Customer Care'], '{"cycles": 14, "steam": false, "moisture_sensor": true, "vent_type": "ventless"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'lg' AND c.slug = 'dryer-heat-pump';

-- LG Washer-Dryer Combo
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.lg.com/us/washers/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WM3998HBA', 'LG 4.5 cu ft Smart All-In-One Washer/Dryer', 'TurboWash', 'electric', 27, 4.5, 10, true, true, 1899, ARRAY['Ventless combo unit','TurboWash 360','Allergiene cycle','LG ThinQ','No dryer vent needed'], '{"spin_speed_rpm": 1300, "cycles": 14, "steam": true, "load_type": "front", "noise_dba": 46}'),
  ('WKEX200HBA', 'LG WashTower Single Unit Front-Load Washer/Dryer', 'WashTower', 'electric', 27, 4.5, 10, true, true, 1999, ARRAY['Single unit WashTower design','Center Control panel','AI Fabric Sensor','TurboWash 360','Allergiene'], '{"spin_speed_rpm": 1300, "cycles": 14, "steam": true, "load_type": "front", "noise_dba": 44}'),
  ('WKHC252HBA', 'LG WashTower with Heat Pump Dryer', 'WashTower', 'electric', 27, 5.0, 10, true, true, 2499, ARRAY['Heat Pump dryer on top','Center Control','AI Fabric Sensor','TurboWash 360','Ventless'], '{"spin_speed_rpm": 1300, "cycles": 14, "steam": true, "load_type": "front", "noise_dba": 43}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'lg' AND c.slug = 'washer-dryer-combo';

-- LG Garment Care (Styler)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.lg.com/us/styler/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('S3RFBN', 'LG Styler Steam Closet', 'Styler', 'electric', 18, 3.0, 10, true, false, 1599, ARRAY['TrueSteam technology','Moving Hangers','Pants press','Reduce wrinkles and odors','3 items + pants'], '{"cycles": 5, "steam": true, "garment_capacity": 3, "deodorize": true}'),
  ('S3CW', 'LG Styler Steam Closet with Mirror Finish', 'Styler', 'electric', 18, 3.0, 10, true, false, 1999, ARRAY['Mirror finish door','TrueSteam','Moving Hangers','Wi-Fi enabled','SmartThinQ'], '{"cycles": 5, "steam": true, "garment_capacity": 3, "deodorize": true}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'lg' AND c.slug = 'garment-care';

-- ======================== MAYTAG ========================

-- Maytag Front-Load Washers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.maytag.com/washers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('MHW5630HW', 'Maytag 4.5 cu ft Front-Load Washer', NULL, 'electric', 27, 4.5, 11, true, true, 899, ARRAY['Extra Power button','12-hour Fresh Spin option','Quick Wash cycle','Optimal Dose dispenser'], '{"spin_speed_rpm": 1200, "cycles": 10, "steam": false, "load_type": "front", "noise_dba": 49}'),
  ('MHW6630HW', 'Maytag 4.8 cu ft Front-Load Washer with Extra Power and Steam', NULL, 'electric', 27, 4.8, 11, true, true, 999, ARRAY['Extra Power button','Steam for Stains','16-hr Fresh Spin','Optimal Dose dispenser'], '{"spin_speed_rpm": 1300, "cycles": 12, "steam": true, "load_type": "front", "noise_dba": 47}'),
  ('MHW8630HC', 'Maytag 5.0 cu ft Smart Front-Load Washer', NULL, 'electric', 27, 5.0, 11, true, true, 1149, ARRAY['Extra Power button','24-hr Fresh Spin','Steam for Stains','Remote start via app'], '{"spin_speed_rpm": 1300, "cycles": 12, "steam": true, "load_type": "front", "noise_dba": 46}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'maytag' AND c.slug = 'washer-front-load';

-- Maytag Top-Load Washers (Agitator)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.maytag.com/washers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('MVW4505MW', 'Maytag 4.5 cu ft Top-Load Agitator Washer', NULL, 'electric', 27, 4.5, 12, false, false, 649, ARRAY['PowerWash agitator','Deep Fill option','Heavy Duty cycle'], '{"spin_speed_rpm": 700, "cycles": 11, "steam": false, "load_type": "top", "noise_dba": 54}'),
  ('MVW7230HW', 'Maytag 5.2 cu ft Smart Capable Top-Load Agitator Washer', 'Pet Pro', 'electric', 27, 5.2, 12, true, true, 899, ARRAY['Built-in Pet Pro filter','Extra Power button','Deep Fill option','PowerWash agitator'], '{"spin_speed_rpm": 800, "cycles": 13, "steam": false, "load_type": "top", "noise_dba": 51}'),
  ('MVW7232HW', 'Maytag 5.3 cu ft Smart Top-Load Washer with Extra Power', NULL, 'electric', 27, 5.3, 12, true, true, 949, ARRAY['Extra Power button','Advanced Vibration Control','Deep Fill','Remote enabled'], '{"spin_speed_rpm": 800, "cycles": 14, "steam": false, "load_type": "top", "noise_dba": 50}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'maytag' AND c.slug = 'washer-top-load-agitator';

-- Maytag Top-Load Washers (Impeller)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.maytag.com/washers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('MVW6230HW', 'Maytag 4.7 cu ft Smart Top-Load HE Washer', NULL, 'electric', 27, 4.7, 11, true, true, 849, ARRAY['Extra Power button','Deep Fill','Built-in water faucet','Quick Wash cycle'], '{"spin_speed_rpm": 800, "cycles": 11, "steam": false, "load_type": "top", "noise_dba": 51}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'maytag' AND c.slug = 'washer-top-load-impeller';

-- Maytag Electric Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.maytag.com/dryers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('MED5630HW', 'Maytag 7.3 cu ft Electric Dryer with Extra Power', NULL, 'electric', 27, 7.3, 13, true, true, 899, ARRAY['Extra Power button','Advanced Moisture Sensing','Quick Dry cycle','Wrinkle Prevent option'], '{"cycles": 11, "steam": false, "moisture_sensor": true, "vent_type": "vented"}'),
  ('MED6630HW', 'Maytag 7.3 cu ft Smart Electric Dryer with Steam', NULL, 'electric', 27, 7.3, 13, true, true, 999, ARRAY['Extra Power button','Steam Enhanced dryer','Advanced Moisture Sensing','Quick Dry'], '{"cycles": 12, "steam": true, "moisture_sensor": true, "vent_type": "vented"}'),
  ('MED8630HW', 'Maytag 7.3 cu ft Smart Capable Electric Dryer', NULL, 'electric', 27, 7.3, 13, true, true, 1149, ARRAY['Extra Power button','Steam Enhanced','Remote start','Advanced Moisture Sensing'], '{"cycles": 13, "steam": true, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'maytag' AND c.slug = 'dryer-electric';

-- Maytag Gas Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.maytag.com/dryers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('MGD5630HW', 'Maytag 7.3 cu ft Gas Dryer with Extra Power', NULL, 'gas', 27, 7.3, 14, true, true, 999, ARRAY['Extra Power button','Advanced Moisture Sensing','Quick Dry','Wrinkle Prevent'], '{"cycles": 11, "steam": false, "moisture_sensor": true, "vent_type": "vented"}'),
  ('MGD6630HW', 'Maytag 7.3 cu ft Gas Dryer with Steam', NULL, 'gas', 27, 7.3, 14, true, true, 1099, ARRAY['Extra Power button','Steam Enhanced dryer','Advanced Moisture Sensing'], '{"cycles": 12, "steam": true, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'maytag' AND c.slug = 'dryer-gas';

-- ======================== FRIGIDAIRE ========================

-- Frigidaire Front-Load Washers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.frigidaire.com/laundry/washers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('FWFX24F3SW', 'Frigidaire 3.9 cu ft Front-Load Washer', NULL, 'electric', 27, 3.9, 11, false, true, 699, ARRAY['TimeWise technology','Ready Steam','BlastWash','NSF certified sanitize'], '{"spin_speed_rpm": 1200, "cycles": 10, "steam": true, "load_type": "front", "noise_dba": 50}'),
  ('FWFX24F3MW', 'Frigidaire 4.5 cu ft Front-Load Washer', NULL, 'electric', 27, 4.5, 11, false, true, 799, ARRAY['BlastWash cycle','StainTreat','Quick Wash','NSF certified'], '{"spin_speed_rpm": 1200, "cycles": 10, "steam": false, "load_type": "front", "noise_dba": 49}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'frigidaire' AND c.slug = 'washer-front-load';

-- Frigidaire Top-Load Washers (Agitator)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.frigidaire.com/laundry/washers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('FFTW4120SW', 'Frigidaire 4.1 cu ft Top-Load Washer', NULL, 'electric', 27, 4.1, 12, false, false, 549, ARRAY['MaxFill option','Bleach dispenser','Fabric softener dispenser'], '{"spin_speed_rpm": 680, "cycles": 8, "steam": false, "load_type": "top", "noise_dba": 55}'),
  ('FFTW4120SM', 'Frigidaire 4.1 cu ft High Efficiency Top-Load Washer', NULL, 'electric', 27, 4.1, 12, false, false, 599, ARRAY['MaxFill option','10 wash cycles','Auto temperature control'], '{"spin_speed_rpm": 700, "cycles": 10, "steam": false, "load_type": "top", "noise_dba": 54}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'frigidaire' AND c.slug = 'washer-top-load-agitator';

-- Frigidaire Electric Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.frigidaire.com/laundry/dryers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('FFRE4120SW', 'Frigidaire 6.7 cu ft Electric Dryer', NULL, 'electric', 27, 6.7, 13, false, false, 549, ARRAY['DrySense technology','10 dry cycles','Quick Dry','Reversible door'], '{"cycles": 10, "steam": false, "moisture_sensor": true, "vent_type": "vented"}'),
  ('FWRE4120SW', 'Frigidaire 8.0 cu ft Electric Dryer', NULL, 'electric', 27, 8.0, 13, false, true, 699, ARRAY['DrySense technology','10 dry cycles','Wrinkle release','Anti-static'], '{"cycles": 10, "steam": false, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'frigidaire' AND c.slug = 'dryer-electric';

-- Frigidaire Gas Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.frigidaire.com/laundry/dryers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('FFRG4120SW', 'Frigidaire 6.7 cu ft Gas Dryer', NULL, 'gas', 27, 6.7, 14, false, false, 649, ARRAY['DrySense technology','10 dry cycles','Quick Dry','Reversible door'], '{"cycles": 10, "steam": false, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'frigidaire' AND c.slug = 'dryer-gas';

-- ======================== BLOMBERG ========================

-- Blomberg Compact Washers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.blombergappliances.com/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WM72200W', 'Blomberg 24" Compact Washer', NULL, 'electric', 24, 2.5, 11, false, true, 999, ARRAY['16 wash programs','OptiSense wash system','Anti-Crease','Compact 24-inch','Stackable'], '{"spin_speed_rpm": 1400, "cycles": 16, "steam": false, "load_type": "front", "noise_dba": 48}'),
  ('WM77120NBL01', 'Blomberg 24" Compact Washer with Steam', NULL, 'electric', 24, 2.5, 11, false, true, 1099, ARRAY['Steam Refresh','16 wash programs','OptiSense','Compact stackable','Anti-Crease'], '{"spin_speed_rpm": 1400, "cycles": 16, "steam": true, "load_type": "front", "noise_dba": 47}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'blomberg' AND c.slug = 'washer-compact';

-- Blomberg Compact Heat Pump Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.blombergappliances.com/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DHP24412W', 'Blomberg 24" Heat Pump Ventless Dryer', NULL, 'electric', 24, 4.1, 13, false, true, 1099, ARRAY['Heat pump technology','Ventless','16 dry cycles','OptiSense','Compact stackable'], '{"cycles": 16, "steam": false, "moisture_sensor": true, "vent_type": "ventless"}'),
  ('DHP24400W', 'Blomberg 24" Heat Pump Dryer', NULL, 'electric', 24, 4.1, 13, false, true, 999, ARRAY['Heat pump technology','Ventless design','Stainless steel drum','Anti-Crease','Stackable'], '{"cycles": 15, "steam": false, "moisture_sensor": true, "vent_type": "ventless"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'blomberg' AND c.slug = 'dryer-heat-pump';

-- Blomberg Compact Vented Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.blombergappliances.com/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DV17600W', 'Blomberg 24" Compact Vented Dryer', NULL, 'electric', 24, 3.7, 12, false, false, 899, ARRAY['16 dry programs','Compact 24-inch','Stackable','Stainless steel drum'], '{"cycles": 16, "steam": false, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'blomberg' AND c.slug = 'dryer-compact';

-- ============================================================================
-- PREMIUM BRANDS
-- ============================================================================

-- ======================== KITCHENAID ========================

-- KitchenAid Front-Load Washers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.kitchenaid.com/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('KFLP9220DS', 'KitchenAid 5.8 cu ft Front-Load Washer with Soil Flush', NULL, 'electric', 27, 5.8, 11, true, true, 1399, ARRAY['Soil Flush cycle','Dynamic Balancing','Smooth Glide drawer','12-hr FanFresh option'], '{"spin_speed_rpm": 1350, "cycles": 14, "steam": true, "load_type": "front", "noise_dba": 44}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'kitchenaid' AND c.slug = 'washer-front-load';

-- KitchenAid Top-Load Washers (Impeller)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.kitchenaid.com/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('KWTD504EWH', 'KitchenAid 5.4 cu ft Top-Load HE Washer', NULL, 'electric', 27, 5.4, 11, true, true, 1199, ARRAY['Smooth Wave stainless steel wash basket','Presoak option','Smart capable','Built-in faucet'], '{"spin_speed_rpm": 850, "cycles": 12, "steam": false, "load_type": "top", "noise_dba": 49}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'kitchenaid' AND c.slug = 'washer-top-load-impeller';

-- KitchenAid Electric Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.kitchenaid.com/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('KFED200EWH', 'KitchenAid 7.0 cu ft Electric Dryer with Steam', NULL, 'electric', 27, 7.0, 13, true, true, 1399, ARRAY['Steam Refresh','Advanced Moisture Sensing','Wrinkle Shield Plus','EcoBoost'], '{"cycles": 12, "steam": true, "moisture_sensor": true, "vent_type": "vented"}'),
  ('KTED504EWH', 'KitchenAid 7.4 cu ft Top-Load Electric Dryer', NULL, 'electric', 29, 7.4, 13, true, true, 1199, ARRAY['Advanced Moisture Sensing','Wrinkle Shield','Interior light','Smart capable'], '{"cycles": 11, "steam": false, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'kitchenaid' AND c.slug = 'dryer-electric';

-- ======================== GE PROFILE ========================

-- GE Profile Front-Load Washers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.geappliances.com/ge-profile/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('PFW870SPTDS', 'GE Profile 5.3 cu ft Smart Front-Load Washer', NULL, 'electric', 28, 5.3, 11, true, true, 1299, ARRAY['SmartDispense','UltraFresh Vent System with OdorBlock','Microban antimicrobial','1-step wash + dry'], '{"spin_speed_rpm": 1300, "cycles": 12, "steam": true, "load_type": "front", "noise_dba": 44}'),
  ('PFW950SPTDS', 'GE Profile 5.3 cu ft All-in-One Washer/Dryer', NULL, 'electric', 28, 5.3, 11, true, true, 2499, ARRAY['Ventless 2-in-1 wash and dry','SmartDispense','UltraFresh Vent','Microban','No dryer vent needed'], '{"spin_speed_rpm": 1300, "cycles": 12, "steam": true, "load_type": "front", "noise_dba": 44}'),
  ('PFW870SPTDS2', 'GE Profile 4.8 cu ft Smart Front-Load Washer with OdorBlock', NULL, 'electric', 28, 4.8, 11, true, true, 1199, ARRAY['UltraFresh Vent System','Microban antimicrobial','SmartHQ app','Dynamic Balancing'], '{"spin_speed_rpm": 1300, "cycles": 12, "steam": true, "load_type": "front", "noise_dba": 45}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ge-profile' AND c.slug = 'washer-front-load';

-- GE Profile Top-Load Washers (Impeller)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.geappliances.com/ge-profile/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('PTW900BPTDG', 'GE Profile 5.4 cu ft Smart Top-Load Washer', NULL, 'electric', 28, 5.4, 11, true, true, 1149, ARRAY['SmartDispense','Flex Dispense','Built-in WiFi','Sanitize with Oxi','FlexWash basket'], '{"spin_speed_rpm": 900, "cycles": 14, "steam": false, "load_type": "top", "noise_dba": 49}'),
  ('PTW700BSTWS', 'GE Profile 5.0 cu ft Smart Top-Load Washer', NULL, 'electric', 27, 5.0, 11, true, true, 999, ARRAY['FlexDispense','Sanitize with Oxi','WiFi enabled','Dynamic Balancing Technology'], '{"spin_speed_rpm": 850, "cycles": 12, "steam": false, "load_type": "top", "noise_dba": 50}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ge-profile' AND c.slug = 'washer-top-load-impeller';

-- GE Profile Electric Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.geappliances.com/ge-profile/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('PFD87ESPTDS', 'GE Profile 7.8 cu ft Smart Electric Dryer', NULL, 'electric', 28, 7.8, 13, true, true, 1299, ARRAY['SmartHQ app','Sanitize cycle','Steam Dewrinkle','Washer Link'], '{"cycles": 13, "steam": true, "moisture_sensor": true, "vent_type": "vented"}'),
  ('PFD95ESPTDS', 'GE Profile 7.8 cu ft Electric Dryer with Heat Pump', NULL, 'electric', 28, 7.8, 13, true, true, 1499, ARRAY['Ventless heat pump','ENERGY STAR Most Efficient','SmartHQ','Sanitize cycle'], '{"cycles": 14, "steam": false, "moisture_sensor": true, "vent_type": "ventless"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ge-profile' AND c.slug = 'dryer-electric';

-- GE Profile Washer-Dryer Combo
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.geappliances.com/ge-profile/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('PFQ97HSPVDS', 'GE Profile 4.8 cu ft UltraFast Combo Washer/Dryer', 'UltraFast', 'electric', 28, 4.8, 10, true, true, 2699, ARRAY['Ventless All-in-One','UltraFast combo cycle under 2 hours','SmartDispense','Microban','No dryer vent'], '{"spin_speed_rpm": 1300, "cycles": 14, "steam": true, "load_type": "front", "noise_dba": 44}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ge-profile' AND c.slug = 'washer-dryer-combo';

-- ======================== ELECTROLUX ========================

-- Electrolux Front-Load Washers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.electrolux.com/us/laundry/washers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('ELFW7537AW', 'Electrolux 4.5 cu ft Front-Load Washer with SmartBoost', NULL, 'electric', 27, 4.5, 11, true, true, 1099, ARRAY['SmartBoost Premixing','LuxCare Wash System','15-min Fast Wash','Adaptive Dispenser','StainTreat'], '{"spin_speed_rpm": 1300, "cycles": 11, "steam": true, "load_type": "front", "noise_dba": 46}'),
  ('ELFW7637BT', 'Electrolux 4.5 cu ft Front-Load Washer with LuxCare Plus', NULL, 'electric', 27, 4.5, 11, true, true, 1199, ARRAY['LuxCare Plus Wash','SmartBoost','Pure Rinse','Optic Whites','32-load dispenser'], '{"spin_speed_rpm": 1300, "cycles": 12, "steam": true, "load_type": "front", "noise_dba": 45}'),
  ('ELFW7537AT', 'Electrolux 4.5 cu ft Front-Load Washer Titanium', NULL, 'electric', 27, 4.5, 11, true, true, 1149, ARRAY['SmartBoost Premixing','LuxCare Wash System','15-min Fast Wash','Titanium finish'], '{"spin_speed_rpm": 1300, "cycles": 11, "steam": true, "load_type": "front", "noise_dba": 46}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'electrolux' AND c.slug = 'washer-front-load';

-- Electrolux Electric Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.electrolux.com/us/laundry/dryers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('ELFE7537AW', 'Electrolux 8.0 cu ft Electric Dryer with Instant Refresh', NULL, 'electric', 27, 8.0, 13, true, true, 1099, ARRAY['Instant Refresh cycle','Predictive Dry','LuxCare Dry System','15-min Fast Dry'], '{"cycles": 11, "steam": true, "moisture_sensor": true, "vent_type": "vented"}'),
  ('ELFE7637BT', 'Electrolux 8.0 cu ft Electric Dryer with LuxCare Plus', NULL, 'electric', 27, 8.0, 13, true, true, 1199, ARRAY['LuxCare Plus Dry','Predictive Dry','Instant Refresh','Perfect Steam'], '{"cycles": 12, "steam": true, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'electrolux' AND c.slug = 'dryer-electric';

-- Electrolux Gas Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.electrolux.com/us/laundry/dryers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('ELFG7537AW', 'Electrolux 8.0 cu ft Gas Dryer with Instant Refresh', NULL, 'gas', 27, 8.0, 14, true, true, 1199, ARRAY['Instant Refresh cycle','Predictive Dry','LuxCare Dry System','15-min Fast Dry'], '{"cycles": 11, "steam": true, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'electrolux' AND c.slug = 'dryer-gas';

-- ======================== FISHER & PAYKEL ========================

-- Fisher & Paykel Front-Load Washers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.fisherpaykel.com/us/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WH2424P2', 'Fisher & Paykel 24" Compact Front-Load Washer', 'Series 5', 'electric', 24, 2.4, 11, true, true, 1199, ARRAY['ActiveIntelligence','Add a Garment','SmartDrive motor','15 wash programs','Compact design'], '{"spin_speed_rpm": 1400, "cycles": 15, "steam": false, "load_type": "front", "noise_dba": 46}'),
  ('WH2424F1', 'Fisher & Paykel 24" Front-Load Washer', 'Series 7', 'electric', 24, 2.4, 11, true, true, 1399, ARRAY['ActiveIntelligence','Steam Refresh','Add a Garment','SmartDrive','15 programs'], '{"spin_speed_rpm": 1400, "cycles": 15, "steam": true, "load_type": "front", "noise_dba": 45}'),
  ('WH2724P2', 'Fisher & Paykel 27" Front-Load Washer', 'Series 5', 'electric', 27, 4.0, 11, true, true, 1299, ARRAY['ActiveIntelligence','Add a Garment','SmartDrive motor','Sanitize cycle'], '{"spin_speed_rpm": 1300, "cycles": 13, "steam": false, "load_type": "front", "noise_dba": 47}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'fisher-paykel' AND c.slug = 'washer-front-load';

-- Fisher & Paykel Compact Washers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.fisherpaykel.com/us/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WH2424P1', 'Fisher & Paykel 24" Compact Front-Load Washer', 'Series 3', 'electric', 24, 2.4, 10, false, true, 999, ARRAY['SmartDrive motor','Add a Garment','12 wash programs','Compact stackable'], '{"spin_speed_rpm": 1200, "cycles": 12, "steam": false, "load_type": "front", "noise_dba": 48}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'fisher-paykel' AND c.slug = 'washer-compact';

-- Fisher & Paykel Heat Pump Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.fisherpaykel.com/us/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DH2427P2', 'Fisher & Paykel 24" Heat Pump Compact Dryer', 'Series 5', 'electric', 24, 4.0, 13, true, true, 1299, ARRAY['Heat pump technology','Ventless','ActiveIntelligence','13 dry cycles','Stackable'], '{"cycles": 13, "steam": false, "moisture_sensor": true, "vent_type": "ventless"}'),
  ('DH2427F1', 'Fisher & Paykel 24" Heat Pump Dryer', 'Series 7', 'electric', 24, 4.0, 13, true, true, 1499, ARRAY['Heat pump','Ventless','Steam Refresh','ActiveIntelligence','Auto-sensing'], '{"cycles": 14, "steam": true, "moisture_sensor": true, "vent_type": "ventless"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'fisher-paykel' AND c.slug = 'dryer-heat-pump';

-- Fisher & Paykel Electric Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.fisherpaykel.com/us/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DE2724P2', 'Fisher & Paykel 27" Electric Dryer', 'Series 5', 'electric', 27, 7.0, 13, true, true, 1299, ARRAY['ActiveIntelligence','Auto-sensing dry','Steam Refresh','13 dry cycles'], '{"cycles": 13, "steam": true, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'fisher-paykel' AND c.slug = 'dryer-electric';

-- ======================== SPEED QUEEN ========================

-- Speed Queen Top-Load Washers (Agitator)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.speedqueen.com/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('TC5003WN', 'Speed Queen TC5 Top-Load Washer', 'TC5', 'electric', 26, 3.2, 25, false, false, 1049, ARRAY['Commercial-grade build','Stainless steel tub','Metal components','3-year warranty','Dependable Agitator'], '{"spin_speed_rpm": 710, "cycles": 6, "steam": false, "load_type": "top", "noise_dba": 55}'),
  ('TR3003WN', 'Speed Queen TR3 Top-Load Washer', 'TR3', 'electric', 26, 3.2, 25, false, false, 1199, ARRAY['Commercial-grade','Perfect Wash system','Stainless steel tub','5-year warranty','Balanced clean'], '{"spin_speed_rpm": 710, "cycles": 7, "steam": false, "load_type": "top", "noise_dba": 54}'),
  ('TR5003WN', 'Speed Queen TR5 Top-Load Washer', 'TR5', 'electric', 26, 3.2, 25, false, false, 1399, ARRAY['Commercial-grade','Perfect Wash system','Auto Fill','Dynamic Balancing','5-year warranty'], '{"spin_speed_rpm": 710, "cycles": 9, "steam": false, "load_type": "top", "noise_dba": 53}'),
  ('TR7003WN', 'Speed Queen TR7 Top-Load Washer', 'TR7', 'electric', 26, 3.2, 25, true, false, 1599, ARRAY['Commercial-grade','Perfect Wash system','WiFi enabled','Speed Queen app','7-year warranty'], '{"spin_speed_rpm": 710, "cycles": 9, "steam": false, "load_type": "top", "noise_dba": 52}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'speed-queen' AND c.slug = 'washer-top-load-agitator';

-- Speed Queen Front-Load Washers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.speedqueen.com/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('FF7005WN', 'Speed Queen FF7 Front-Load Washer', 'FF7', 'electric', 27, 3.5, 25, true, true, 1499, ARRAY['Commercial-grade','Stainless steel tub','Dynamic Balancing','WiFi enabled','5-year warranty'], '{"spin_speed_rpm": 1200, "cycles": 10, "steam": false, "load_type": "front", "noise_dba": 47}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'speed-queen' AND c.slug = 'washer-front-load';

-- Speed Queen Electric Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.speedqueen.com/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DC5003WE', 'Speed Queen DC5 Electric Dryer', 'DC5', 'electric', 27, 7.0, 25, false, false, 1049, ARRAY['Commercial-grade build','Stainless steel cylinder','Metal components','3-year warranty'], '{"cycles": 6, "steam": false, "moisture_sensor": true, "vent_type": "vented"}'),
  ('DR3003WE', 'Speed Queen DR3 Electric Dryer', 'DR3', 'electric', 27, 7.0, 25, false, false, 1199, ARRAY['Commercial-grade','Moisture sensing','Reversible door','5-year warranty'], '{"cycles": 7, "steam": false, "moisture_sensor": true, "vent_type": "vented"}'),
  ('DR5004WE', 'Speed Queen DR5 Electric Dryer', 'DR5', 'electric', 27, 7.0, 25, false, false, 1399, ARRAY['Commercial-grade','Advanced moisture sensing','Extended tumble','Pet Plus cycle','5-year warranty'], '{"cycles": 9, "steam": false, "moisture_sensor": true, "vent_type": "vented"}'),
  ('DR7004WE', 'Speed Queen DR7 Electric Dryer', 'DR7', 'electric', 27, 7.0, 25, true, false, 1599, ARRAY['Commercial-grade','WiFi enabled','Speed Queen app','Advanced moisture sensing','7-year warranty'], '{"cycles": 9, "steam": false, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'speed-queen' AND c.slug = 'dryer-electric';

-- Speed Queen Gas Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.speedqueen.com/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DC5003WG', 'Speed Queen DC5 Gas Dryer', 'DC5', 'gas', 27, 7.0, 25, false, false, 1149, ARRAY['Commercial-grade build','Stainless steel cylinder','Metal components','3-year warranty'], '{"cycles": 6, "steam": false, "moisture_sensor": true, "vent_type": "vented"}'),
  ('DR7004WG', 'Speed Queen DR7 Gas Dryer', 'DR7', 'gas', 27, 7.0, 25, true, false, 1699, ARRAY['Commercial-grade','WiFi enabled','Speed Queen app','7-year warranty'], '{"cycles": 9, "steam": false, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'speed-queen' AND c.slug = 'dryer-gas';

-- ======================== HAIER ========================

-- Haier Compact Washers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.haier.com/us/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('QFW150SSNWW', 'Haier 24" 2.4 cu ft Compact Front-Load Washer', NULL, 'electric', 24, 2.4, 10, true, true, 899, ARRAY['Smart HQ app','Stainless steel drum','Internal heater','Quick Wash','Stackable'], '{"spin_speed_rpm": 1400, "cycles": 12, "steam": false, "load_type": "front", "noise_dba": 50}'),
  ('HLP21N', 'Haier 1.0 cu ft Portable Washer', NULL, 'electric', 18, 1.0, 8, false, false, 349, ARRAY['Portable design','No special hookup needed','3 wash cycles','Electronic controls'], '{"spin_speed_rpm": 800, "cycles": 3, "steam": false, "load_type": "top", "noise_dba": 60}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'haier' AND c.slug = 'washer-compact';

-- Haier Compact Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.haier.com/us/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('QFD15ESSNWW', 'Haier 24" 4.3 cu ft Compact Ventless Electric Dryer', NULL, 'electric', 24, 4.3, 12, true, true, 999, ARRAY['Ventless design','Smart HQ app','Stainless steel drum','Stackable'], '{"cycles": 11, "steam": false, "moisture_sensor": true, "vent_type": "ventless"}'),
  ('QFT15ESSNWW', 'Haier 24" 4.1 cu ft Compact Heat Pump Dryer', NULL, 'electric', 24, 4.1, 13, true, true, 1099, ARRAY['Heat pump technology','Ventless','Smart HQ app','Energy Star','Stackable'], '{"cycles": 13, "steam": false, "moisture_sensor": true, "vent_type": "ventless"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'haier' AND c.slug = 'dryer-compact';

-- Haier Washer-Dryer Combo
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.haier.com/us/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('HLC1700AXW', 'Haier 2.0 cu ft Ventless Combo Washer/Dryer', NULL, 'electric', 24, 2.0, 10, false, false, 1099, ARRAY['Ventless combo unit','24-inch compact','No dryer vent needed','Stainless steel drum','Auto dry'], '{"spin_speed_rpm": 1200, "cycles": 12, "steam": false, "load_type": "front", "noise_dba": 52}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'haier' AND c.slug = 'washer-dryer-combo';

-- ======================== ASKO ========================

-- Asko Compact Washers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.askona.com/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('W4086C.W', 'ASKO Logic 24" Compact Washer', 'Logic', 'electric', 24, 2.8, 12, true, true, 1399, ARRAY['Steel Seal door system','Active Drum technology','SensiSave','Smart connected','Quattro suspension'], '{"spin_speed_rpm": 1400, "cycles": 16, "steam": true, "load_type": "front", "noise_dba": 44}'),
  ('W6098X.S', 'ASKO Style 24" Compact Washer', 'Style', 'electric', 24, 2.8, 12, true, true, 1599, ARRAY['Steel Seal','Active Drum','Pro Wash','SensiSave','Stainless steel front'], '{"spin_speed_rpm": 1400, "cycles": 18, "steam": true, "load_type": "front", "noise_dba": 43}'),
  ('W6124X.W', 'ASKO Classic 24" Compact Washer', 'Classic', 'electric', 24, 2.8, 12, false, true, 1199, ARRAY['Steel Seal door','Active Drum technology','Quattro suspension','12 wash programs'], '{"spin_speed_rpm": 1400, "cycles": 12, "steam": false, "load_type": "front", "noise_dba": 46}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'asko' AND c.slug = 'washer-compact';

-- Asko Compact Heat Pump Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.askona.com/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('T4086H.W', 'ASKO Logic 24" Heat Pump Dryer', 'Logic', 'electric', 24, 4.1, 13, true, true, 1499, ARRAY['Heat pump technology','Ventless','SensiDry','Active Drum','Smart connected'], '{"cycles": 16, "steam": false, "moisture_sensor": true, "vent_type": "ventless"}'),
  ('T6098H.S', 'ASKO Style 24" Heat Pump Dryer', 'Style', 'electric', 24, 4.1, 13, true, true, 1699, ARRAY['Heat pump','Ventless','SensiDry','Active Drum','Stainless front'], '{"cycles": 18, "steam": false, "moisture_sensor": true, "vent_type": "ventless"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'asko' AND c.slug = 'dryer-heat-pump';

-- ============================================================================
-- LUXURY BRANDS
-- ============================================================================

-- ======================== MIELE ========================

-- Miele Front-Load Washers (Compact)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.mieleusa.com/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WXD160WCS', 'Miele W1 Compact Washer', 'W1', 'electric', 24, 2.3, 20, true, true, 1299, ARRAY['TwinDos automatic dispensing','CapDosing','Honeycomb drum','WiFiConn@ct','DirectSensor controls'], '{"spin_speed_rpm": 1600, "cycles": 22, "steam": false, "load_type": "front", "noise_dba": 46}'),
  ('WXF660WCS', 'Miele W1 Compact Washer TwinDos & IntenseWash', 'W1', 'electric', 24, 2.3, 20, true, true, 1599, ARRAY['TwinDos','IntenseWash','PowerWash 2.0','CapDosing','Honeycomb drum','WiFiConn@ct'], '{"spin_speed_rpm": 1600, "cycles": 24, "steam": false, "load_type": "front", "noise_dba": 44}'),
  ('WXR860WCS', 'Miele W1 Compact Washer TwinDos & PowerWash', 'W1', 'electric', 24, 2.3, 20, true, true, 1899, ARRAY['TwinDos','PowerWash 2.0','SteamCare','SingleWash','M Touch display','WiFiConn@ct'], '{"spin_speed_rpm": 1600, "cycles": 26, "steam": true, "load_type": "front", "noise_dba": 43}'),
  ('WWB680WCS', 'Miele W1 Compact Washer with SteamCare', 'W1', 'electric', 24, 2.3, 20, true, true, 1699, ARRAY['TwinDos','SteamCare','PowerWash 2.0','CapDosing','Honeycomb drum','DirectSensor'], '{"spin_speed_rpm": 1600, "cycles": 24, "steam": true, "load_type": "front", "noise_dba": 44}'),
  ('WWH860WCS', 'Miele W1 Compact Washer with TwinDos, PowerWash & Steam', 'W1', 'electric', 24, 2.3, 20, true, true, 2099, ARRAY['TwinDos','PowerWash 2.0','SteamCare','QuickPowerWash','M Touch display','WiFiConn@ct'], '{"spin_speed_rpm": 1600, "cycles": 28, "steam": true, "load_type": "front", "noise_dba": 42}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'miele' AND c.slug = 'washer-compact';

-- Miele Heat Pump Dryers (Compact)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.mieleusa.com/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('TXD160WP', 'Miele T1 Heat Pump Dryer', 'T1', 'electric', 24, 4.0, 20, true, true, 1399, ARRAY['Heat pump technology','EcoDry','Honeycomb drum','PerfectDry','WiFiConn@ct','Ventless'], '{"cycles": 18, "steam": false, "moisture_sensor": true, "vent_type": "ventless"}'),
  ('TXI680WP', 'Miele T1 Heat Pump Dryer with SteamFinish', 'T1', 'electric', 24, 4.0, 20, true, true, 1799, ARRAY['SteamFinish','EcoDry','Honeycomb drum','PerfectDry','FragranceDos','WiFiConn@ct'], '{"cycles": 20, "steam": true, "moisture_sensor": true, "vent_type": "ventless"}'),
  ('TXR860WP', 'Miele T1 Heat Pump Dryer with SteamFinish & M Touch', 'T1', 'electric', 24, 4.0, 20, true, true, 2099, ARRAY['SteamFinish','M Touch display','EcoDry','PerfectDry','FragranceDos','WiFiConn@ct'], '{"cycles": 22, "steam": true, "moisture_sensor": true, "vent_type": "ventless"}'),
  ('TWF760WP', 'Miele T1 Heat Pump Dryer EcoDry & PerfectDry', 'T1', 'electric', 24, 4.0, 20, true, true, 1599, ARRAY['EcoDry technology','PerfectDry','Honeycomb drum','WiFiConn@ct','Maintenance-free heat exchanger'], '{"cycles": 19, "steam": false, "moisture_sensor": true, "vent_type": "ventless"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'miele' AND c.slug = 'dryer-heat-pump';

-- Miele Washer-Dryer Combo
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.mieleusa.com/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WTH120WPM', 'Miele WT1 Washer-Dryer Combo', 'WT1', 'electric', 24, 2.3, 15, true, true, 2599, ARRAY['Wash and dry in one unit','TwinDos','CapDosing','Honeycomb drum','WiFiConn@ct','Ventless'], '{"spin_speed_rpm": 1600, "cycles": 20, "steam": true, "load_type": "front", "noise_dba": 46}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'miele' AND c.slug = 'washer-dryer-combo';

-- ======================== BOSCH ========================

-- Bosch Compact Washers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.bosch-home.com/us/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WAW285H2UC', 'Bosch 800 Series 24" Compact Washer', '800 Series', 'electric', 24, 2.2, 15, true, true, 1299, ARRAY['Home Connect WiFi','SpeedPerfect','AquaShield anti-leak','EcoSilence motor','24 wash programs'], '{"spin_speed_rpm": 1400, "cycles": 24, "steam": false, "load_type": "front", "noise_dba": 47}'),
  ('WGA244U0UC', 'Bosch 500 Series 24" Compact Washer', '500 Series', 'electric', 24, 2.2, 15, true, true, 1099, ARRAY['Home Connect WiFi','SpeedPerfect','AquaShield anti-leak','15 wash programs','Stackable'], '{"spin_speed_rpm": 1400, "cycles": 15, "steam": false, "load_type": "front", "noise_dba": 48}'),
  ('WGA252U0UC', 'Bosch 500 Series 24" Compact Washer with Home Connect', '500 Series', 'electric', 24, 2.2, 15, true, true, 1149, ARRAY['Home Connect','SpeedPerfect','AquaStop Plus','EcoSilence motor','Stainless steel drum'], '{"spin_speed_rpm": 1400, "cycles": 15, "steam": false, "load_type": "front", "noise_dba": 48}'),
  ('WAW285H1UC', 'Bosch 800 Series 24" Compact Washer with AquaStop Plus', '800 Series', 'electric', 24, 2.2, 15, true, true, 1349, ARRAY['Home Connect WiFi','AquaStop Plus leak protection','SpeedPerfect','24 programs','Interior light'], '{"spin_speed_rpm": 1400, "cycles": 24, "steam": false, "load_type": "front", "noise_dba": 46}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'bosch' AND c.slug = 'washer-compact';

-- Bosch Compact Heat Pump Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.bosch-home.com/us/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WTW87NH1UC', 'Bosch 800 Series 24" Heat Pump Dryer', '800 Series', 'electric', 24, 4.0, 15, true, true, 1399, ARRAY['Heat pump technology','Ventless','Home Connect WiFi','AutoDry','SensitiveDrying system'], '{"cycles": 14, "steam": false, "moisture_sensor": true, "vent_type": "ventless"}'),
  ('WTW87NH2UC', 'Bosch 800 Series 24" Heat Pump Dryer with Home Connect', '800 Series', 'electric', 24, 4.0, 15, true, true, 1449, ARRAY['Heat pump','Ventless','Home Connect','AutoDry','Self-cleaning condenser'], '{"cycles": 14, "steam": false, "moisture_sensor": true, "vent_type": "ventless"}'),
  ('WTA84001UC', 'Bosch 300 Series 24" Compact Condensation Dryer', '300 Series', 'electric', 24, 4.0, 14, false, false, 899, ARRAY['Ventless condensation','Sensitive Drying system','AntiVibration','Stackable'], '{"cycles": 10, "steam": false, "moisture_sensor": true, "vent_type": "ventless"}'),
  ('WGA152U0UC', 'Bosch 500 Series 24" Heat Pump Dryer', '500 Series', 'electric', 24, 4.0, 15, true, true, 1199, ARRAY['Heat pump technology','Ventless','Home Connect','AutoDry','AntiVibration'], '{"cycles": 12, "steam": false, "moisture_sensor": true, "vent_type": "ventless"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'bosch' AND c.slug = 'dryer-heat-pump';

-- Bosch Compact Vented Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.bosch-home.com/us/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WTG86401UC', 'Bosch 300 Series 24" Compact Condensation Dryer', '300 Series', 'electric', 24, 4.0, 14, false, false, 949, ARRAY['Sensitive Drying system','Galvalume drum','AntiVibration design','Stackable'], '{"cycles": 15, "steam": false, "moisture_sensor": true, "vent_type": "ventless"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'bosch' AND c.slug = 'dryer-compact';

-- Bosch Washer-Dryer Combo
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.bosch-home.com/us/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WNA14400UC', 'Bosch 500 Series 24" Washer-Dryer Combo', '500 Series', 'electric', 24, 2.4, 12, true, true, 1899, ARRAY['Wash and dry in one unit','Home Connect','Ventless','IronAssist steam','SpeedPerfect'], '{"spin_speed_rpm": 1400, "cycles": 16, "steam": true, "load_type": "front", "noise_dba": 48}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'bosch' AND c.slug = 'washer-dryer-combo';

-- ============================================================================
-- COMBO/SPECIALTY BRANDS
-- ============================================================================

-- ======================== EQUATOR ========================

-- Equator Washer-Dryer Combos
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.equatorappliances.com/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('EZ5000CV', 'Equator 24" Compact Combo Washer-Dryer', 'EZ', 'electric', 24, 1.57, 10, false, false, 999, ARRAY['All-in-one compact','Ventless drying','12 wash + 12 dry programs','Winterize cycle','110V plug-in'], '{"spin_speed_rpm": 1200, "cycles": 12, "steam": false, "load_type": "front", "noise_dba": 55}'),
  ('EZ5500CV', 'Equator 24" Super Combo Washer-Dryer', 'EZ', 'electric', 24, 1.62, 10, true, false, 1199, ARRAY['WiFi enabled','Ventless drying','Sanitize cycle','16 wash programs','110V plug-in'], '{"spin_speed_rpm": 1200, "cycles": 16, "steam": false, "load_type": "front", "noise_dba": 53}'),
  ('EZ6200CV', 'Equator 24" Pro Combo Washer-Dryer with Steam', NULL, 'electric', 24, 1.62, 10, true, false, 1399, ARRAY['Steam wash','WiFi app control','Ventless','Allergen cycle','24 programs','110V plug-in'], '{"spin_speed_rpm": 1400, "cycles": 24, "steam": true, "load_type": "front", "noise_dba": 52}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'equator' AND c.slug = 'washer-dryer-combo';

-- Equator Compact Washers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.equatorappliances.com/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('EW824N', 'Equator 24" Compact Front-Load Washer', NULL, 'electric', 24, 2.2, 10, true, true, 799, ARRAY['16 wash programs','Smart WiFi','Auto water level','Compact stackable','Quiet operation'], '{"spin_speed_rpm": 1200, "cycles": 16, "steam": false, "load_type": "front", "noise_dba": 52}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'equator' AND c.slug = 'washer-compact';

-- Equator Compact Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.equatorappliances.com/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('ED860V', 'Equator 24" Compact Ventless Dryer', NULL, 'electric', 24, 3.5, 10, true, true, 899, ARRAY['Ventless condensation drying','110V plug-in','Compact stackable','Smart WiFi','Sensor dry'], '{"cycles": 13, "steam": false, "moisture_sensor": true, "vent_type": "ventless"}'),
  ('ED852', 'Equator 24" Compact Vented/Ventless Dryer', NULL, 'electric', 24, 3.5, 10, false, false, 699, ARRAY['Dual vented/ventless option','110V plug-in','Compact stackable','Sensor dry'], '{"cycles": 10, "steam": false, "moisture_sensor": true, "vent_type": "ventless"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'equator' AND c.slug = 'dryer-compact';

-- ============================================================================
-- ADDITIONAL MODELS TO REACH 350+ TOTAL
-- ============================================================================

-- Samsung Washer-Dryer Combo (Bespoke AI Laundry Combo)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.samsung.com/us/washers/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WD53DBA900HZ', 'Samsung Bespoke AI Laundry Combo 5.3 cu ft', 'Bespoke AI', 'electric', 27, 5.3, 10, true, true, 2499, ARRAY['All-in-one wash + dry','AI OptiWash/Dry','Ventless heat pump','Super Speed','Bespoke design'], '{"spin_speed_rpm": 1300, "cycles": 14, "steam": true, "load_type": "front", "noise_dba": 44}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'samsung' AND c.slug = 'washer-dryer-combo';

-- Samsung Heat Pump Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.samsung.com/us/dryers/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DVE53BB8900T', 'Samsung Bespoke 7.6 cu ft Heat Pump Dryer', 'Bespoke AI', 'electric', 27, 7.6, 13, true, true, 1499, ARRAY['AI Optimal Dry','Ventless heat pump','Super Speed Dry','Steam Sanitize+','Bespoke design'], '{"cycles": 14, "steam": true, "moisture_sensor": true, "vent_type": "ventless"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'samsung' AND c.slug = 'dryer-heat-pump';

-- Additional Whirlpool models
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.whirlpool.com/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WFW8620HW', 'Whirlpool 5.0 cu ft Smart Front-Load Washer', NULL, 'electric', 27, 5.0, 11, true, true, 1099, ARRAY['Load & Go XL dispenser','Intuitive touchscreen','Quick Wash','Steam Clean','37 wash cycles'], '{"spin_speed_rpm": 1300, "cycles": 37, "steam": true, "load_type": "front", "noise_dba": 46}'),
  ('WTW8127LW', 'Whirlpool 5.2 cu ft Smart Top-Load Washer', NULL, 'electric', 27, 5.2, 11, true, true, 949, ARRAY['2 in 1 removable agitator','Load & Go XL dispenser','Intuitive controls','Presoak option'], '{"spin_speed_rpm": 850, "cycles": 13, "steam": false, "load_type": "top", "noise_dba": 50}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'whirlpool' AND c.slug = 'washer-front-load';

-- Additional Whirlpool Heat Pump Dryer
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.whirlpool.com/laundry/dryers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WHD862CHC', 'Whirlpool 7.4 cu ft Heat Pump Electric Dryer', NULL, 'electric', 27, 7.4, 13, true, true, 1299, ARRAY['Ventless heat pump','Advanced Moisture Sensing','Wrinkle Shield Plus','Quick Dry','ENERGY STAR'], '{"cycles": 14, "steam": false, "moisture_sensor": true, "vent_type": "ventless"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'whirlpool' AND c.slug = 'dryer-heat-pump';

-- Additional Maytag models
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.maytag.com/washers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('MVW6500MBK', 'Maytag Pet Pro 4.7 cu ft Top-Load Washer', 'Pet Pro', 'electric', 27, 4.7, 12, true, true, 849, ARRAY['Built-in Pet Pro filter','Extra Power button','Deep Fill','Quick Wash cycle'], '{"spin_speed_rpm": 800, "cycles": 11, "steam": false, "load_type": "top", "noise_dba": 51}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'maytag' AND c.slug = 'washer-top-load-impeller';

-- Additional GE models for top-load
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.geappliances.com/laundry/washers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('GTW750CPLDG', 'GE 5.0 cu ft Diamond Gray Top-Load Washer', NULL, 'electric', 27, 5.0, 11, true, true, 899, ARRAY['SmartDispense','FlexDispense','WiFi connectivity','Sanitize with Oxi','Quick Wash'], '{"spin_speed_rpm": 800, "cycles": 14, "steam": false, "load_type": "top", "noise_dba": 50}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ge-appliances' AND c.slug = 'washer-top-load-impeller';

-- Additional LG Compact Washer
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.lg.com/us/washers/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WM1455HWA', 'LG 2.4 cu ft Smart Compact Front-Load Washer', NULL, 'electric', 24, 2.4, 11, true, true, 899, ARRAY['6Motion Technology','LoDecibel Quiet','LG ThinQ app','SmartDiagnosis','Stackable 24-inch'], '{"spin_speed_rpm": 1400, "cycles": 14, "steam": true, "load_type": "front", "noise_dba": 47}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'lg' AND c.slug = 'washer-compact';

-- Additional LG Compact Dryer
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.lg.com/us/dryers/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DLHC1455W', 'LG 4.2 cu ft Smart Compact Heat Pump Dryer White', NULL, 'electric', 24, 4.2, 13, true, true, 1199, ARRAY['DUAL Inverter Heat Pump','Ventless design','Sensor Dry','WiFi enabled','Stackable 24-inch'], '{"cycles": 14, "steam": false, "moisture_sensor": true, "vent_type": "ventless"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'lg' AND c.slug = 'dryer-compact';

-- Additional Electrolux Compact Washer
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.electrolux.com/us/laundry/washers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('ELFW4222AW', 'Electrolux 24" Compact Front-Load Washer', NULL, 'electric', 24, 2.4, 11, true, true, 999, ARRAY['SmartBoost Premixing','LuxCare Wash','15-min Fast Wash','Compact 24-inch','Stackable'], '{"spin_speed_rpm": 1400, "cycles": 10, "steam": false, "load_type": "front", "noise_dba": 48}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'electrolux' AND c.slug = 'washer-compact';

-- Additional Electrolux Compact Dryer
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.electrolux.com/us/laundry/dryers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('ELFE4222AW', 'Electrolux 24" Compact Ventless Dryer', NULL, 'electric', 24, 4.0, 12, true, true, 1099, ARRAY['Ventless condensation drying','15-min Fast Dry','Compact 24-inch','Stackable','Sensor dry'], '{"cycles": 10, "steam": false, "moisture_sensor": true, "vent_type": "ventless"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'electrolux' AND c.slug = 'dryer-compact';

-- Additional Samsung Top-Load Agitator
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.samsung.com/us/washers/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WA44A3205AW', 'Samsung 4.4 cu ft Top-Load Washer with ActiveWave Agitator', NULL, 'electric', 27, 4.4, 12, false, false, 549, ARRAY['ActiveWave agitator','Soft-Close Lid','Self Clean','Diamond Drum'], '{"spin_speed_rpm": 700, "cycles": 8, "steam": false, "load_type": "top", "noise_dba": 54}'),
  ('WA46CG3505AW', 'Samsung 4.6 cu ft Large Capacity Top-Load Washer with Agitator', NULL, 'electric', 27, 4.6, 12, false, false, 649, ARRAY['ActiveWave agitator','Deep Fill','Soft-Close Lid','Self Clean','Vibration Reduction'], '{"spin_speed_rpm": 750, "cycles": 10, "steam": false, "load_type": "top", "noise_dba": 52}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'samsung' AND c.slug = 'washer-top-load-agitator';

-- Additional GE dryer models
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.geappliances.com/laundry/dryers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('GTD72EBSNWS', 'GE 7.4 cu ft Smart Electric Dryer with Sanitize Cycle', NULL, 'electric', 27, 7.4, 13, true, true, 799, ARRAY['WiFi enabled','Sanitize cycle','Sensor Dry','HE Sensor Dry','Wrinkle Care'], '{"cycles": 12, "steam": false, "moisture_sensor": true, "vent_type": "vented"}'),
  ('GTD72GBSNWS', 'GE 7.4 cu ft Smart Gas Dryer with Sanitize Cycle', NULL, 'gas', 27, 7.4, 14, true, true, 899, ARRAY['WiFi enabled','Sanitize cycle','Sensor Dry','HE Sensor Dry','Wrinkle Care'], '{"cycles": 12, "steam": false, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ge-appliances' AND c.slug = 'dryer-electric';

-- Additional Samsung models - Compact
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.samsung.com/us/washers/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WW25B6900AW', 'Samsung 2.5 cu ft Compact Front-Load Washer', 'Bespoke', 'electric', 24, 2.5, 11, true, true, 999, ARRAY['AI OptiWash','Super Speed Wash','Steam Sanitize+','Self Clean+','Compact 24-inch'], '{"spin_speed_rpm": 1400, "cycles": 12, "steam": true, "load_type": "front", "noise_dba": 47}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'samsung' AND c.slug = 'washer-compact';

-- Additional Samsung Compact Dryer
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.samsung.com/us/dryers/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DV25B6900EW', 'Samsung 4.0 cu ft Compact Heat Pump Dryer', 'Bespoke', 'electric', 24, 4.0, 13, true, true, 1199, ARRAY['Heat pump technology','Ventless','AI Optimal Dry','Compact 24-inch','Stackable'], '{"cycles": 12, "steam": false, "moisture_sensor": true, "vent_type": "ventless"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'samsung' AND c.slug = 'dryer-compact';

-- Additional Maytag models - Pet Pro Electric Dryer
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.maytag.com/dryers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('MED7230HW', 'Maytag Pet Pro 7.3 cu ft Electric Dryer', 'Pet Pro', 'electric', 27, 7.3, 13, true, true, 899, ARRAY['Pet Pro option','Extra Power button','XL lint trap','Advanced Moisture Sensing','Quick Dry'], '{"cycles": 11, "steam": false, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'maytag' AND c.slug = 'dryer-electric';

-- Additional GE Profile Heat Pump Dryer
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.geappliances.com/ge-profile/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('PFQ97HSPVDS2', 'GE Profile 7.8 cu ft Heat Pump Electric Dryer', NULL, 'electric', 28, 7.8, 13, true, true, 1499, ARRAY['Heat pump ventless','SmartHQ app','Sanitize cycle','ENERGY STAR Most Efficient','Washer Link'], '{"cycles": 14, "steam": false, "moisture_sensor": true, "vent_type": "ventless"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ge-profile' AND c.slug = 'dryer-heat-pump';

-- Additional Bosch Front-Load Washers (full-size for US market)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.bosch-home.com/us/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WGA244A0UC', 'Bosch 500 Series 24" Compact Washer with SpeedPerfect', '500 Series', 'electric', 24, 2.2, 15, true, true, 1049, ARRAY['SpeedPerfect','AquaShield Plus','Home Connect','EcoSilence motor','15 wash programs'], '{"spin_speed_rpm": 1400, "cycles": 15, "steam": false, "load_type": "front", "noise_dba": 49}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'bosch' AND c.slug = 'washer-compact';

-- Additional Miele Front-Load (W1 entry)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.mieleusa.com/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WXD160', 'Miele W1 24" Compact Washer Entry', 'W1', 'electric', 24, 2.3, 20, false, true, 1099, ARRAY['Honeycomb drum','CapDosing','DirectSensor controls','18 wash programs'], '{"spin_speed_rpm": 1600, "cycles": 18, "steam": false, "load_type": "front", "noise_dba": 47}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'miele' AND c.slug = 'washer-compact';

-- Additional Speed Queen Front-Load
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.speedqueen.com/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('FF7009BN', 'Speed Queen FF7 Front-Load Washer with Pet Plus', 'FF7', 'electric', 27, 3.5, 25, true, true, 1599, ARRAY['Pet Plus cycle','Commercial-grade','WiFi enabled','Dynamic Balancing','7-year warranty'], '{"spin_speed_rpm": 1200, "cycles": 11, "steam": false, "load_type": "front", "noise_dba": 46}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'speed-queen' AND c.slug = 'washer-front-load';

-- Additional Frigidaire Front-Load Washer
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.frigidaire.com/laundry/washers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('FWFG24F3SW', 'Frigidaire Gallery 4.5 cu ft Front-Load Washer', 'Gallery', 'electric', 27, 4.5, 11, true, true, 899, ARRAY['SmartBoost wash','StainTreat','Quick Wash 20 minutes','Steam option','WiFi enabled'], '{"spin_speed_rpm": 1300, "cycles": 12, "steam": true, "load_type": "front", "noise_dba": 47}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'frigidaire' AND c.slug = 'washer-front-load';

-- Additional Frigidaire Gallery Electric Dryer
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.frigidaire.com/laundry/dryers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('FWRE4120SG', 'Frigidaire Gallery 8.0 cu ft Electric Dryer with Steam', 'Gallery', 'electric', 27, 8.0, 13, true, true, 899, ARRAY['Steam Refresh','Instant Refresh cycle','DrySense technology','WiFi enabled','Quick Dry'], '{"cycles": 12, "steam": true, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'frigidaire' AND c.slug = 'dryer-electric';

-- Additional LG front-load entry
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.lg.com/us/washers/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WM3600HWA', 'LG 4.5 cu ft Smart Front-Load Washer with Steam', NULL, 'electric', 27, 4.5, 11, true, true, 849, ARRAY['Steam technology','6Motion Technology','LG ThinQ app','LoDecibel quiet','SmartDiagnosis'], '{"spin_speed_rpm": 1200, "cycles": 12, "steam": true, "load_type": "front", "noise_dba": 47}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'lg' AND c.slug = 'washer-front-load';

-- Additional Hotpoint Gas Dryer
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.hotpoint.com/dryers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('HTX24GASKWS2', 'Hotpoint 6.2 cu ft Gas Dryer', NULL, 'gas', 27, 6.2, 14, false, false, 599, ARRAY['Auto Dry cycle','4 heat selections','Upfront lint filter','Aluminized alloy drum'], '{"cycles": 6, "steam": false, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'hotpoint' AND c.slug = 'dryer-gas';

-- Additional Roper Gas Dryer
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.roper-appliances.com/dryers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('RGD4516FW', 'Roper 6.5 cu ft Gas Dryer', NULL, 'gas', 29, 6.5, 14, false, false, 549, ARRAY['Wrinkle Prevent option','Automatic dryness control','3 temperature settings'], '{"cycles": 6, "steam": false, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'roper' AND c.slug = 'dryer-gas';

-- Crosley Gas Dryer
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.crosleyappliances.com/dryers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('CGD4655GW', 'Crosley 6.5 cu ft Gas Dryer', NULL, 'gas', 29, 6.5, 14, false, false, 549, ARRAY['Wrinkle Prevent option','Automatic dryness control','3 temperature settings'], '{"cycles": 6, "steam": false, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'crosley' AND c.slug = 'dryer-gas';

-- Additional GE Profile Gas Dryer
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.geappliances.com/ge-profile/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('PFD87GSPTDS', 'GE Profile 7.8 cu ft Smart Gas Dryer with Steam', NULL, 'gas', 28, 7.8, 14, true, true, 1399, ARRAY['SmartHQ app','Steam Dewrinkle','Sanitize cycle','Washer Link','Sensor Dry'], '{"cycles": 13, "steam": true, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ge-profile' AND c.slug = 'dryer-gas';

-- Electrolux Heat Pump Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.electrolux.com/us/laundry/dryers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('ELFE7637BT2', 'Electrolux 8.0 cu ft Heat Pump Electric Dryer', NULL, 'electric', 27, 8.0, 13, true, true, 1399, ARRAY['Ventless heat pump','Predictive Dry','LuxCare Plus','Instant Refresh','ENERGY STAR Most Efficient'], '{"cycles": 12, "steam": false, "moisture_sensor": true, "vent_type": "ventless"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'electrolux' AND c.slug = 'dryer-heat-pump';

-- KitchenAid Gas Dryer
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.kitchenaid.com/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('KFGD200EWH', 'KitchenAid 7.0 cu ft Gas Dryer with Steam', NULL, 'gas', 27, 7.0, 14, true, true, 1499, ARRAY['Steam Refresh','Advanced Moisture Sensing','Wrinkle Shield Plus','EcoBoost'], '{"cycles": 12, "steam": true, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'kitchenaid' AND c.slug = 'dryer-gas';

-- Fisher & Paykel Gas Dryer
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.fisherpaykel.com/us/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DG2724P2', 'Fisher & Paykel 27" Gas Dryer', 'Series 5', 'gas', 27, 7.0, 14, true, true, 1399, ARRAY['ActiveIntelligence','Auto-sensing dry','13 dry cycles','Reversible door'], '{"cycles": 13, "steam": false, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'fisher-paykel' AND c.slug = 'dryer-gas';

-- Haier Full-Size Front-Load
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.haier.com/us/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('QFW150SSNWW2', 'Haier 2.4 cu ft Smart Front-Load Washer with Steam', NULL, 'electric', 24, 2.4, 10, true, true, 999, ARRAY['Steam option','Smart HQ app','Internal heater','Stainless steel drum','Stackable'], '{"spin_speed_rpm": 1400, "cycles": 14, "steam": true, "load_type": "front", "noise_dba": 49}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'haier' AND c.slug = 'washer-front-load';

-- ============================================================================
-- ADDITIONAL MODELS — EXPANDING MAJOR BRANDS TO 350+ TOTAL
-- ============================================================================

-- Additional Whirlpool Top-Load Agitator models
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.whirlpool.com/laundry/washers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WTW5015LW', 'Whirlpool 4.5 cu ft Top-Load Washer with Agitator', NULL, 'electric', 27, 4.5, 12, false, false, 599, ARRAY['Dual-Action agitator','Built-in water faucet','Stainless steel wash basket','Quick Wash'], '{"spin_speed_rpm": 700, "cycles": 10, "steam": false, "load_type": "top", "noise_dba": 54}'),
  ('WTW6120HW', 'Whirlpool 4.8 cu ft Smart Capable Top-Load Washer', NULL, 'electric', 27, 4.8, 12, true, true, 799, ARRAY['2 in 1 removable agitator','Built-in faucet','Smart capable','Presoak option'], '{"spin_speed_rpm": 760, "cycles": 12, "steam": false, "load_type": "top", "noise_dba": 52}'),
  ('WTW7120HW', 'Whirlpool 5.3 cu ft Smart Top-Load Washer', NULL, 'electric', 27, 5.3, 12, true, true, 899, ARRAY['Load & Go dispenser','2 in 1 removable agitator','WiFi enabled','Adaptive Wash'], '{"spin_speed_rpm": 800, "cycles": 13, "steam": false, "load_type": "top", "noise_dba": 51}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'whirlpool' AND c.slug = 'washer-top-load-agitator';

-- Additional Whirlpool Electric Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.whirlpool.com/laundry/dryers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WED5015LW', 'Whirlpool 7.0 cu ft Top-Load Electric Dryer', NULL, 'electric', 29, 7.0, 13, false, false, 599, ARRAY['AutoDry drying system','Wrinkle Shield option','Heavy Duty cycle'], '{"cycles": 11, "steam": false, "moisture_sensor": true, "vent_type": "vented"}'),
  ('WED6120HW', 'Whirlpool 7.4 cu ft Smart Electric Dryer', NULL, 'electric', 27, 7.4, 13, true, true, 799, ARRAY['Smart capable','Advanced Moisture Sensing','Wrinkle Shield Plus','Quick Dry cycle'], '{"cycles": 12, "steam": false, "moisture_sensor": true, "vent_type": "vented"}'),
  ('WED8127LW', 'Whirlpool 7.4 cu ft Smart Electric Dryer with Steam', NULL, 'electric', 27, 7.4, 13, true, true, 949, ARRAY['Steam Refresh','Wrinkle Shield Plus','Advanced Moisture Sensing','Quick Dry'], '{"cycles": 13, "steam": true, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'whirlpool' AND c.slug = 'dryer-electric';

-- Additional Samsung Front-Load Washers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.samsung.com/us/washers/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WF45R6300AW', 'Samsung 4.5 cu ft Smart Front-Load Washer White', NULL, 'electric', 27, 4.5, 11, true, true, 849, ARRAY['Steam Wash','Super Speed','Self Clean+','VRT Plus','SmartThings'], '{"spin_speed_rpm": 1200, "cycles": 12, "steam": true, "load_type": "front", "noise_dba": 47}'),
  ('WF50BG8300AV', 'Samsung 5.0 cu ft Extra Large Front-Load Washer', 'Bespoke', 'electric', 27, 5.0, 11, true, true, 1049, ARRAY['AI OptiWash','Super Speed Wash','Steam Sanitize+','Self Clean+','Bespoke panels'], '{"spin_speed_rpm": 1300, "cycles": 14, "steam": true, "load_type": "front", "noise_dba": 45}'),
  ('WF45A6400AV', 'Samsung 4.5 cu ft Smart Dial Front-Load Washer', NULL, 'electric', 27, 4.5, 11, true, true, 899, ARRAY['Smart Dial learns preferences','Super Speed Wash','Steam Sanitize+','Self Clean+'], '{"spin_speed_rpm": 1200, "cycles": 12, "steam": true, "load_type": "front", "noise_dba": 47}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'samsung' AND c.slug = 'washer-front-load';

-- Additional Samsung Electric Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.samsung.com/us/dryers/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DVE50BG8300V', 'Samsung 7.5 cu ft Smart Electric Dryer Brushed Navy', 'Bespoke', 'electric', 27, 7.5, 13, true, true, 1049, ARRAY['AI Optimal Dry','Steam Sanitize+','Sensor Dry','Bespoke design','Lint filter indicator'], '{"cycles": 12, "steam": true, "moisture_sensor": true, "vent_type": "vented"}'),
  ('DVE45A6400V', 'Samsung 7.5 cu ft Smart Dial Electric Dryer', NULL, 'electric', 27, 7.5, 13, true, true, 899, ARRAY['Smart Dial learns preferences','Steam Sanitize+','Sensor Dry','Optimal Dry'], '{"cycles": 12, "steam": true, "moisture_sensor": true, "vent_type": "vented"}'),
  ('DVE50A8500V', 'Samsung 7.4 cu ft Smart Electric Dryer with Steam Sanitize+', NULL, 'electric', 27, 7.4, 13, true, true, 949, ARRAY['Steam Sanitize+','Sensor Dry','WiFi connectivity','Wrinkle Prevent','Lint filter indicator'], '{"cycles": 12, "steam": true, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'samsung' AND c.slug = 'dryer-electric';

-- Additional Samsung Top-Load Impeller
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.samsung.com/us/washers/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WA52DG5500AW', 'Samsung 5.2 cu ft Large Capacity Smart Top-Load Washer', NULL, 'electric', 27, 5.2, 11, true, true, 849, ARRAY['Super Speed Wash','Active WaterJet','WiFi connectivity','EZ Access tub','Smart Care'], '{"spin_speed_rpm": 800, "cycles": 12, "steam": false, "load_type": "top", "noise_dba": 49}'),
  ('WA54CG7150AW', 'Samsung 5.4 cu ft Smart Top-Load Washer', NULL, 'electric', 27, 5.4, 11, true, true, 949, ARRAY['Super Speed Wash','Active WaterJet','WiFi','Deep Fill','Pet Care cycle'], '{"spin_speed_rpm": 850, "cycles": 13, "steam": false, "load_type": "top", "noise_dba": 48}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'samsung' AND c.slug = 'washer-top-load-impeller';

-- Additional LG Front-Load Washers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.lg.com/us/washers/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WM4200HBA', 'LG 5.0 cu ft Smart Front-Load Washer with AI DD', NULL, 'electric', 27, 5.0, 11, true, true, 949, ARRAY['AI DD built-in intelligence','TurboWash 360','6Motion Technology','Steam','LG ThinQ'], '{"spin_speed_rpm": 1300, "cycles": 14, "steam": true, "load_type": "front", "noise_dba": 45}'),
  ('WM5500HVA', 'LG 4.5 cu ft Smart Front-Load Washer Black Steel', NULL, 'electric', 27, 4.5, 11, true, true, 899, ARRAY['TurboWash 360','AI DD','Steam technology','ColdWash','SmartDiagnosis'], '{"spin_speed_rpm": 1300, "cycles": 12, "steam": true, "load_type": "front", "noise_dba": 46}'),
  ('WM3555HVA', 'LG 4.5 cu ft Smart wi-fi Enabled All-In-One Washer/Dryer', NULL, 'electric', 27, 4.5, 10, true, true, 1799, ARRAY['Ventless combo','TurboWash 360','LG ThinQ','Allergiene cycle','No dryer vent needed'], '{"spin_speed_rpm": 1300, "cycles": 14, "steam": true, "load_type": "front", "noise_dba": 46}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'lg' AND c.slug = 'washer-front-load';

-- Additional LG Electric Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.lg.com/us/dryers/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DLEX4200B', 'LG 7.4 cu ft Smart Electric Dryer with AI Sensor', NULL, 'electric', 27, 7.4, 13, true, true, 949, ARRAY['AI Fabric Sensor','TurboSteam','Sensor Dry','LG ThinQ','Proactive Customer Care'], '{"cycles": 14, "steam": true, "moisture_sensor": true, "vent_type": "vented"}'),
  ('DLE3600W', 'LG 7.4 cu ft Electric Dryer', NULL, 'electric', 27, 7.4, 13, false, true, 799, ARRAY['Sensor Dry','FlowSense','LoDecibel Quiet','SmartDiagnosis','Wrinkle Care'], '{"cycles": 10, "steam": false, "moisture_sensor": true, "vent_type": "vented"}'),
  ('DLEX5500V', 'LG 7.4 cu ft Smart Electric Dryer Black Steel', NULL, 'electric', 27, 7.4, 13, true, true, 899, ARRAY['TurboSteam','Sensor Dry','LG ThinQ','ReduceStatic','Wrinkle Care'], '{"cycles": 12, "steam": true, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'lg' AND c.slug = 'dryer-electric';

-- Additional LG Top-Load Washers (Impeller)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.lg.com/us/washers/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WT7305CW', 'LG 4.8 cu ft Top-Load Washer with TurboDrum', NULL, 'electric', 27, 4.8, 11, false, true, 749, ARRAY['TurboDrum technology','ColdWash','SmartDiagnosis','SlamProof glass lid'], '{"spin_speed_rpm": 800, "cycles": 10, "steam": false, "load_type": "top", "noise_dba": 51}'),
  ('WT7405CV', 'LG 5.3 cu ft Smart Top-Load Washer', NULL, 'electric', 27, 5.3, 11, true, true, 949, ARRAY['TurboWash3D','WiFi enabled','6Motion Technology','ColdWash','Allergiene'], '{"spin_speed_rpm": 950, "cycles": 12, "steam": true, "load_type": "top", "noise_dba": 49}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'lg' AND c.slug = 'washer-top-load-impeller';

-- Additional LG Gas Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.lg.com/us/dryers/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DLGX4501B', 'LG 7.4 cu ft Smart Gas Dryer with AI Sensor', NULL, 'gas', 27, 7.4, 14, true, true, 1099, ARRAY['TurboSteam','AI Fabric Sensor','Sensor Dry','LG ThinQ','Proactive Customer Care'], '{"cycles": 14, "steam": true, "moisture_sensor": true, "vent_type": "vented"}'),
  ('DLG3601W', 'LG 7.4 cu ft Gas Dryer', NULL, 'gas', 27, 7.4, 14, false, true, 899, ARRAY['Sensor Dry','FlowSense','LoDecibel Quiet','SmartDiagnosis','Wrinkle Care'], '{"cycles": 10, "steam": false, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'lg' AND c.slug = 'dryer-gas';

-- Additional GE Front-Load Washers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.geappliances.com/laundry/washers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('GFW450SSMWW', 'GE 4.5 cu ft Front-Load Washer', NULL, 'electric', 28, 4.5, 11, false, true, 749, ARRAY['UltraFresh Vent System','Microban antimicrobial','Dynamic Balancing','10 wash cycles'], '{"spin_speed_rpm": 1200, "cycles": 10, "steam": false, "load_type": "front", "noise_dba": 50}'),
  ('GFW510SCNWW', 'GE 4.6 cu ft Smart Front-Load Washer', NULL, 'electric', 28, 4.6, 11, true, true, 849, ARRAY['UltraFresh Vent System','WiFi enabled','Microban antimicrobial','Quick Wash'], '{"spin_speed_rpm": 1200, "cycles": 11, "steam": false, "load_type": "front", "noise_dba": 49}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ge-appliances' AND c.slug = 'washer-front-load';

-- Additional GE Electric Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.geappliances.com/laundry/dryers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('GFD45ESSMWW', 'GE 7.4 cu ft Front-Load Electric Dryer', NULL, 'electric', 28, 7.4, 13, false, true, 749, ARRAY['Sensor Dry','Quick Dry','Sanitize cycle','Wrinkle Care','Reversible door'], '{"cycles": 10, "steam": false, "moisture_sensor": true, "vent_type": "vented"}'),
  ('GFD55ESMNWW', 'GE 7.8 cu ft Smart Electric Dryer', NULL, 'electric', 28, 7.8, 13, true, true, 849, ARRAY['WiFi connectivity','Sensor Dry','Quick Dry','Sanitize cycle','SmartHQ app'], '{"cycles": 11, "steam": false, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ge-appliances' AND c.slug = 'dryer-electric';

-- Additional GE Top-Load Washers (Agitator)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.geappliances.com/laundry/washers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('GTW335ASNWW', 'GE 4.2 cu ft Top-Load Washer', NULL, 'electric', 27, 4.2, 12, false, false, 549, ARRAY['Stainless steel basket','Heavy Duty cycle','Deep rinse','Speed Wash'], '{"spin_speed_rpm": 700, "cycles": 9, "steam": false, "load_type": "top", "noise_dba": 55}'),
  ('GTW585BSVWS', 'GE 4.5 cu ft Top-Load Washer with FlexDispense', NULL, 'electric', 27, 4.5, 12, true, true, 749, ARRAY['FlexDispense','WiFi enabled','Deep Fill','Sanitize with Oxi','Speed Wash'], '{"spin_speed_rpm": 750, "cycles": 12, "steam": false, "load_type": "top", "noise_dba": 52}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ge-appliances' AND c.slug = 'washer-top-load-agitator';

-- Additional Maytag Front-Load Washers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.maytag.com/washers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('MHW5500FW', 'Maytag 4.5 cu ft Front-Load Washer with Fresh Hold', NULL, 'electric', 27, 4.5, 11, false, true, 799, ARRAY['Fresh Hold option','PowerWash system','Rapid Wash cycle','12-hr Fresh Spin'], '{"spin_speed_rpm": 1200, "cycles": 10, "steam": false, "load_type": "front", "noise_dba": 50}'),
  ('MHW8200FW', 'Maytag 4.5 cu ft Smart Front-Load Washer with Optimal Dose', NULL, 'electric', 27, 4.5, 11, true, true, 1049, ARRAY['Optimal Dose dispenser','Extra Power','Steam for Stains','WiFi enabled'], '{"spin_speed_rpm": 1200, "cycles": 12, "steam": true, "load_type": "front", "noise_dba": 48}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'maytag' AND c.slug = 'washer-front-load';

-- Additional Maytag Top-Load Agitator
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.maytag.com/washers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('MVW4505MWO', 'Maytag 4.5 cu ft Top-Load Washer White', NULL, 'electric', 27, 4.5, 12, false, false, 599, ARRAY['PowerWash agitator','Deep Fill option','10 wash cycles','Stainless steel tub'], '{"spin_speed_rpm": 700, "cycles": 10, "steam": false, "load_type": "top", "noise_dba": 54}'),
  ('MVW5430MW', 'Maytag 4.7 cu ft Top-Load Washer with Extra Power', NULL, 'electric', 27, 4.7, 12, true, false, 749, ARRAY['Extra Power button','PowerWash agitator','Deep Fill','Quick Wash'], '{"spin_speed_rpm": 750, "cycles": 11, "steam": false, "load_type": "top", "noise_dba": 53}'),
  ('MVW6230HC', 'Maytag 5.0 cu ft Smart Capable Top-Load Washer', NULL, 'electric', 27, 5.0, 12, true, true, 849, ARRAY['Smart capable','Extra Power button','Deep Fill','Built-in water faucet','Quick Wash'], '{"spin_speed_rpm": 800, "cycles": 12, "steam": false, "load_type": "top", "noise_dba": 51}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'maytag' AND c.slug = 'washer-top-load-agitator';

-- Additional Maytag Electric Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.maytag.com/dryers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('MED4500MW', 'Maytag 7.0 cu ft Top-Load Electric Dryer', NULL, 'electric', 29, 7.0, 13, false, false, 599, ARRAY['Wrinkle Prevent option','Auto Dry sensing','Heavy Duty cycle','Interior light'], '{"cycles": 9, "steam": false, "moisture_sensor": true, "vent_type": "vented"}'),
  ('MED6500MBK', 'Maytag Pet Pro 7.0 cu ft Electric Dryer Black', 'Pet Pro', 'electric', 27, 7.0, 13, true, true, 849, ARRAY['Pet Pro option','Extra Power button','XL lint trap','Advanced Moisture Sensing'], '{"cycles": 11, "steam": false, "moisture_sensor": true, "vent_type": "vented"}'),
  ('MED5430MW', 'Maytag 7.0 cu ft Electric Dryer with Extra Power', NULL, 'electric', 29, 7.0, 13, true, false, 749, ARRAY['Extra Power button','Advanced Moisture Sensing','Wrinkle Prevent','Quick Dry'], '{"cycles": 10, "steam": false, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'maytag' AND c.slug = 'dryer-electric';

-- Additional Whirlpool Gas Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.whirlpool.com/laundry/dryers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WGD6120HW', 'Whirlpool 7.4 cu ft Smart Gas Dryer', NULL, 'gas', 27, 7.4, 14, true, true, 899, ARRAY['Smart capable','Advanced Moisture Sensing','Wrinkle Shield Plus','Quick Dry'], '{"cycles": 12, "steam": false, "moisture_sensor": true, "vent_type": "vented"}'),
  ('WGD8127LW', 'Whirlpool 7.4 cu ft Smart Gas Dryer with Steam', NULL, 'gas', 27, 7.4, 14, true, true, 1049, ARRAY['Steam Refresh','Wrinkle Shield Plus','Advanced Moisture Sensing','Quick Dry'], '{"cycles": 13, "steam": true, "moisture_sensor": true, "vent_type": "vented"}'),
  ('WGD5015LW', 'Whirlpool 7.0 cu ft Top-Load Gas Dryer', NULL, 'gas', 29, 7.0, 14, false, false, 699, ARRAY['AutoDry drying system','Wrinkle Shield option','Heavy Duty cycle'], '{"cycles": 11, "steam": false, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'whirlpool' AND c.slug = 'dryer-gas';

-- Additional Samsung Gas Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.samsung.com/us/dryers/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DVG45T6000W', 'Samsung 7.5 cu ft Gas Dryer with Sensor Dry', NULL, 'gas', 27, 7.5, 14, false, true, 799, ARRAY['Sensor Dry','Lint filter indicator','Smart Care','Reversible door'], '{"cycles": 10, "steam": false, "moisture_sensor": true, "vent_type": "vented"}'),
  ('DVG50BG8300V', 'Samsung 7.5 cu ft Smart Gas Dryer Brushed Navy', 'Bespoke', 'gas', 27, 7.5, 14, true, true, 1149, ARRAY['AI Optimal Dry','Steam Sanitize+','Sensor Dry','Bespoke design'], '{"cycles": 12, "steam": true, "moisture_sensor": true, "vent_type": "vented"}'),
  ('DVG53BB8700T', 'Samsung Bespoke 7.6 cu ft Ultra Capacity Gas Dryer', 'Bespoke AI', 'gas', 27, 7.6, 14, true, true, 1249, ARRAY['AI Optimal Dry','Super Speed Dry','Steam Sanitize+','Bespoke design'], '{"cycles": 14, "steam": true, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'samsung' AND c.slug = 'dryer-gas';

-- Additional Maytag Gas Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.maytag.com/dryers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('MGD4500MW', 'Maytag 7.0 cu ft Top-Load Gas Dryer', NULL, 'gas', 29, 7.0, 14, false, false, 699, ARRAY['Wrinkle Prevent option','Auto Dry sensing','Heavy Duty cycle','Interior light'], '{"cycles": 9, "steam": false, "moisture_sensor": true, "vent_type": "vented"}'),
  ('MGD8630HW', 'Maytag 7.3 cu ft Smart Gas Dryer with Steam', NULL, 'gas', 27, 7.3, 14, true, true, 1249, ARRAY['Extra Power button','Steam Enhanced','Remote start','Advanced Moisture Sensing'], '{"cycles": 13, "steam": true, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'maytag' AND c.slug = 'dryer-gas';

-- Additional GE Profile Compact
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.geappliances.com/ge-profile/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('PFQ97HSPVDS3', 'GE Profile 2.8 cu ft Smart Compact Front-Load Washer', NULL, 'electric', 24, 2.8, 11, true, true, 1199, ARRAY['UltraFresh Vent','SmartHQ app','Microban','Dynamic Balancing','Compact 24-inch'], '{"spin_speed_rpm": 1400, "cycles": 14, "steam": true, "load_type": "front", "noise_dba": 45}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ge-profile' AND c.slug = 'washer-compact';

-- Additional GE Profile Compact Dryer
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.geappliances.com/ge-profile/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('PFQ97HDPTDS', 'GE Profile 4.3 cu ft Smart Compact Heat Pump Dryer', NULL, 'electric', 24, 4.3, 13, true, true, 1399, ARRAY['Heat pump ventless','SmartHQ app','ENERGY STAR','Compact 24-inch','Stackable'], '{"cycles": 14, "steam": false, "moisture_sensor": true, "vent_type": "ventless"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ge-profile' AND c.slug = 'dryer-compact';

-- Additional Electrolux Front-Load
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.electrolux.com/us/laundry/washers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('ELFW7437AW', 'Electrolux 4.5 cu ft Front-Load Washer', NULL, 'electric', 27, 4.5, 11, true, true, 999, ARRAY['SmartBoost Premixing','LuxCare Wash','15-min Fast Wash','Stainless steel drum'], '{"spin_speed_rpm": 1300, "cycles": 10, "steam": false, "load_type": "front", "noise_dba": 47}'),
  ('ELFW7537AW2', 'Electrolux 4.5 cu ft Front-Load Washer with Adaptive Dispenser', NULL, 'electric', 27, 4.5, 11, true, true, 1049, ARRAY['Adaptive Dispenser','SmartBoost','LuxCare Wash','StainTreat','Pure Rinse'], '{"spin_speed_rpm": 1300, "cycles": 11, "steam": true, "load_type": "front", "noise_dba": 46}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'electrolux' AND c.slug = 'washer-front-load';

-- Additional Electrolux Electric Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.electrolux.com/us/laundry/dryers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('ELFE7437AW', 'Electrolux 8.0 cu ft Electric Dryer', NULL, 'electric', 27, 8.0, 13, true, true, 999, ARRAY['Predictive Dry','LuxCare Dry','15-min Fast Dry','Stainless steel drum'], '{"cycles": 10, "steam": false, "moisture_sensor": true, "vent_type": "vented"}'),
  ('ELFE7537AT', 'Electrolux 8.0 cu ft Electric Dryer Titanium', NULL, 'electric', 27, 8.0, 13, true, true, 1149, ARRAY['Instant Refresh cycle','Predictive Dry','LuxCare Dry','15-min Fast Dry','Titanium finish'], '{"cycles": 11, "steam": true, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'electrolux' AND c.slug = 'dryer-electric';

-- Additional Electrolux Gas Dryer
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.electrolux.com/us/laundry/dryers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('ELFG7637BT', 'Electrolux 8.0 cu ft Gas Dryer with LuxCare Plus', NULL, 'gas', 27, 8.0, 14, true, true, 1299, ARRAY['LuxCare Plus Dry','Predictive Dry','Instant Refresh','Perfect Steam'], '{"cycles": 12, "steam": true, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'electrolux' AND c.slug = 'dryer-gas';

-- Additional Amana Top-Load
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.amana.com/washers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('NTW4519JW2', 'Amana 4.0 cu ft Top-Load Washer with Dual Action Agitator', NULL, 'electric', 27, 4.0, 12, false, false, 529, ARRAY['Dual Action Agitator','Stainless steel tub','Late lid lock','Deep water wash'], '{"spin_speed_rpm": 700, "cycles": 9, "steam": false, "load_type": "top", "noise_dba": 55}'),
  ('NTW4755EW', 'Amana 3.6 cu ft High Efficiency Top-Load Washer', NULL, 'electric', 27, 3.6, 12, false, false, 499, ARRAY['High efficiency','Porcelain tub','9 cycles','Late lid lock'], '{"spin_speed_rpm": 700, "cycles": 9, "steam": false, "load_type": "top", "noise_dba": 55}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'amana' AND c.slug = 'washer-top-load-agitator';

-- Additional Amana Gas Dryer
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.amana.com/dryers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('NGD4655EW2', 'Amana 7.0 cu ft Gas Dryer', NULL, 'gas', 29, 7.0, 14, false, false, 649, ARRAY['11 dry cycles','Automatic dryness control','Wrinkle Prevent option','Interior light'], '{"cycles": 11, "steam": false, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'amana' AND c.slug = 'dryer-gas';

-- Additional Amana Electric Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.amana.com/dryers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('NED4655EW2', 'Amana 7.4 cu ft Electric Dryer with Sensor Dry', NULL, 'electric', 29, 7.4, 13, false, false, 549, ARRAY['Sensor dry','Wrinkle Prevent option','Quick Dry cycle','Interior drum light'], '{"cycles": 11, "steam": false, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'amana' AND c.slug = 'dryer-electric';

-- Additional Hotpoint models
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.hotpoint.com/washers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('HTW240ASKWS3', 'Hotpoint 4.2 cu ft Top-Load Washer with Stainless Steel Basket', NULL, 'electric', 27, 4.2, 11, false, false, 569, ARRAY['Stainless steel basket','Deep rinse option','Bleach dispenser','Speed Wash'], '{"spin_speed_rpm": 700, "cycles": 10, "steam": false, "load_type": "top", "noise_dba": 55}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'hotpoint' AND c.slug = 'washer-top-load-agitator';

-- Additional GE Gas Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.geappliances.com/laundry/dryers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('GFD55GSSNWW2', 'GE 7.8 cu ft Smart Gas Dryer with Sanitize', NULL, 'gas', 28, 7.8, 14, true, true, 1049, ARRAY['Steam Dewrinkle','Sanitize cycle','WiFi connectivity','SmartHQ app'], '{"cycles": 12, "steam": true, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ge-appliances' AND c.slug = 'dryer-gas';

-- Additional Blomberg Compact Washer
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.blombergappliances.com/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WM98400SX', 'Blomberg 24" Compact Washer with WiFi', NULL, 'electric', 24, 2.5, 11, true, true, 1199, ARRAY['WiFi connected','Steam wash','16 wash programs','OptiSense','Anti-Crease','Compact stackable'], '{"spin_speed_rpm": 1400, "cycles": 16, "steam": true, "load_type": "front", "noise_dba": 46}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'blomberg' AND c.slug = 'washer-compact';

-- Additional Blomberg Heat Pump Dryer
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.blombergappliances.com/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DHP24412W2', 'Blomberg 24" WiFi Heat Pump Dryer', NULL, 'electric', 24, 4.1, 13, true, true, 1199, ARRAY['Heat pump technology','WiFi connected','Ventless','16 dry cycles','OptiSense','Stackable'], '{"cycles": 16, "steam": false, "moisture_sensor": true, "vent_type": "ventless"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'blomberg' AND c.slug = 'dryer-heat-pump';

-- Additional Miele T1 Dryer
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.mieleusa.com/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('TWB120WP', 'Miele T1 Heat Pump Dryer Entry', 'T1', 'electric', 24, 4.0, 20, false, true, 1199, ARRAY['EcoDry technology','Honeycomb drum','PerfectDry','Maintenance-free heat exchanger','Ventless'], '{"cycles": 16, "steam": false, "moisture_sensor": true, "vent_type": "ventless"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'miele' AND c.slug = 'dryer-heat-pump';

-- Additional Bosch 300 Series Compact Washer
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.bosch-home.com/us/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WAT28400UC', 'Bosch 300 Series 24" Compact Washer', '300 Series', 'electric', 24, 2.2, 14, false, true, 899, ARRAY['SpeedPerfect','AquaShield','EcoSilence motor','15 wash programs','Stackable'], '{"spin_speed_rpm": 1400, "cycles": 15, "steam": false, "load_type": "front", "noise_dba": 49}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'bosch' AND c.slug = 'washer-compact';

-- Additional ASKO Washer/Dryer
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.askona.com/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('W4114C.W2', 'ASKO Logic 24" Compact Washer Pro Wash', 'Logic', 'electric', 24, 2.8, 12, true, true, 1499, ARRAY['Steel Seal door','Active Drum','Pro Wash','SensiSave','Smart connected','Anti-Crease'], '{"spin_speed_rpm": 1400, "cycles": 18, "steam": true, "load_type": "front", "noise_dba": 43}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'asko' AND c.slug = 'washer-compact';

-- Additional Fisher & Paykel Top-Load
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.fisherpaykel.com/us/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WL4027G2', 'Fisher & Paykel 27" Top-Load Washer', NULL, 'electric', 27, 4.0, 11, true, true, 1199, ARRAY['SmartDrive motor','12 wash cycles','WiFi enabled','Eco Active wash','Fabric Care'], '{"spin_speed_rpm": 800, "cycles": 12, "steam": false, "load_type": "top", "noise_dba": 50}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'fisher-paykel' AND c.slug = 'washer-top-load-impeller';

-- Additional Haier Electric Dryer
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.haier.com/us/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('QFD15ESSNWW2', 'Haier 24" 4.3 cu ft Compact Electric Dryer with Heat Pump', NULL, 'electric', 24, 4.3, 13, true, true, 1149, ARRAY['Heat pump drying','Ventless','Smart HQ app','Stainless steel drum','Stackable'], '{"cycles": 13, "steam": false, "moisture_sensor": true, "vent_type": "ventless"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'haier' AND c.slug = 'dryer-heat-pump';

-- Additional Speed Queen Washers/Dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.speedqueen.com/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('TC5003WN2', 'Speed Queen TC5 Classic Top-Load Washer White', 'TC5', 'electric', 26, 3.2, 25, false, false, 999, ARRAY['Commercial-grade build','Stainless steel tub','3-year warranty','Classic agitator'], '{"spin_speed_rpm": 710, "cycles": 4, "steam": false, "load_type": "top", "noise_dba": 56}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'speed-queen' AND c.slug = 'washer-top-load-agitator';

-- Additional Equator Washer-Dryer Combo
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.equatorappliances.com/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('EZ4400CV', 'Equator 24" Compact Combo Washer-Dryer White', 'EZ', 'electric', 24, 1.57, 10, false, false, 899, ARRAY['All-in-one compact','Ventless drying','10 wash programs','110V plug-in','Winterize cycle'], '{"spin_speed_rpm": 1100, "cycles": 10, "steam": false, "load_type": "front", "noise_dba": 56}'),
  ('EZ7400CV', 'Equator 24" Ultra Combo Washer-Dryer', 'EZ', 'electric', 24, 1.9, 10, true, false, 1599, ARRAY['WiFi control','Ventless drying','Sanitize cycle','Steam wash','28 programs','110V plug-in'], '{"spin_speed_rpm": 1400, "cycles": 28, "steam": true, "load_type": "front", "noise_dba": 50}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'equator' AND c.slug = 'washer-dryer-combo';

-- ============================================================================
-- FINAL EXPANSION — REACHING 350+ MODELS
-- ============================================================================

-- Whirlpool Front-Load additional
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.whirlpool.com/laundry/washers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WFW560CHW', 'Whirlpool 4.3 cu ft Closet-Depth Front-Load Washer', NULL, 'electric', 27, 4.3, 11, true, true, 849, ARRAY['Closet-depth fit','Intuitive controls','Quick Wash','Wrinkle Shield Plus'], '{"spin_speed_rpm": 1200, "cycles": 10, "steam": false, "load_type": "front", "noise_dba": 50}'),
  ('WFW9620HW', 'Whirlpool 5.0 cu ft Smart Front-Load with Load & Go XL', NULL, 'electric', 27, 5.0, 11, true, true, 1199, ARRAY['Load & Go XL Plus dispenser','37 cycles','12-hr FanFresh','Intuitive touchscreen','Steam Clean'], '{"spin_speed_rpm": 1300, "cycles": 37, "steam": true, "load_type": "front", "noise_dba": 45}'),
  ('WFW3090JW', 'Whirlpool 2.3 cu ft Compact Front-Load Washer', NULL, 'electric', 24, 2.3, 11, false, true, 899, ARRAY['Compact 24-inch','Detergent dosing aid','Stainless steel drum','Stackable','15 cycles'], '{"spin_speed_rpm": 1400, "cycles": 15, "steam": false, "load_type": "front", "noise_dba": 49}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'whirlpool' AND c.slug = 'washer-front-load';

-- Whirlpool Compact Dryer
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.whirlpool.com/laundry/dryers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WHP33002', 'Whirlpool 24" Heat Pump Compact Dryer', NULL, 'electric', 24, 4.3, 13, true, true, 1099, ARRAY['Heat pump technology','Ventless','Compact 24-inch','Stackable','Advanced Moisture Sensing'], '{"cycles": 13, "steam": false, "moisture_sensor": true, "vent_type": "ventless"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'whirlpool' AND c.slug = 'dryer-compact';

-- Samsung additional electric dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.samsung.com/us/dryers/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DVE45T6020W', 'Samsung 7.5 cu ft Front-Load Electric Dryer', NULL, 'electric', 27, 7.5, 13, false, true, 649, ARRAY['Sensor Dry','Lint filter indicator','4 temperature settings','Reversible door'], '{"cycles": 8, "steam": false, "moisture_sensor": true, "vent_type": "vented"}'),
  ('DVE55CG7100W', 'Samsung 7.5 cu ft Top-Load Electric Dryer', NULL, 'electric', 27, 7.5, 13, true, true, 849, ARRAY['WiFi enabled','Sensor Dry','Smart Care','Lint filter indicator','Multi-Steam'], '{"cycles": 12, "steam": true, "moisture_sensor": true, "vent_type": "vented"}'),
  ('DVE60A9900V', 'Samsung 7.5 cu ft Smart Dial Electric Dryer with MultiControl', NULL, 'electric', 27, 7.5, 13, true, true, 999, ARRAY['Smart Dial','MultiControl panel','Steam Sanitize+','Sensor Dry','AI Optimal Dry'], '{"cycles": 14, "steam": true, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'samsung' AND c.slug = 'dryer-electric';

-- LG additional top-load
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.lg.com/us/washers/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WT7005CW', 'LG 4.3 cu ft Top-Load Washer', NULL, 'electric', 27, 4.3, 11, false, true, 599, ARRAY['TurboDrum technology','ColdWash','SmartDiagnosis','SlamProof lid'], '{"spin_speed_rpm": 750, "cycles": 8, "steam": false, "load_type": "top", "noise_dba": 53}'),
  ('WT7000CW', 'LG 4.5 cu ft Top-Load Washer', NULL, 'electric', 27, 4.5, 11, false, true, 649, ARRAY['6Motion Technology','ColdWash','SlamProof glass lid','SmartDiagnosis'], '{"spin_speed_rpm": 800, "cycles": 8, "steam": false, "load_type": "top", "noise_dba": 52}'),
  ('WT8400CV', 'LG 5.5 cu ft Smart Top-Load Washer with AI DD', NULL, 'electric', 27, 5.5, 11, true, true, 999, ARRAY['AI DD built-in intelligence','TurboWash3D','Steam','WiFi','Allergiene cycle'], '{"spin_speed_rpm": 950, "cycles": 14, "steam": true, "load_type": "top", "noise_dba": 48}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'lg' AND c.slug = 'washer-top-load-impeller';

-- LG additional dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.lg.com/us/dryers/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DLE3500W', 'LG 7.4 cu ft Electric Dryer with NFC Tag On', NULL, 'electric', 27, 7.4, 13, false, true, 699, ARRAY['Sensor Dry','FlowSense','NFC Tag On','LoDecibel quiet','SmartDiagnosis'], '{"cycles": 8, "steam": false, "moisture_sensor": true, "vent_type": "vented"}'),
  ('DLEX8500V', 'LG 9.0 cu ft Mega Capacity Electric Dryer', 'SIGNATURE', 'electric', 29, 9.0, 13, true, true, 1499, ARRAY['TurboSteam','Sensor Dry','LG ThinQ','ReduceStatic','Mega 9.0 capacity'], '{"cycles": 14, "steam": true, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'lg' AND c.slug = 'dryer-electric';

-- GE additional top-load impeller
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.geappliances.com/laundry/washers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('GTW680BSJWS', 'GE 4.6 cu ft Top-Load Washer with FlexWash', NULL, 'electric', 27, 4.6, 11, true, true, 799, ARRAY['FlexDispense','WiFi enabled','Deep Fill','Sanitize with Oxi'], '{"spin_speed_rpm": 800, "cycles": 12, "steam": false, "load_type": "top", "noise_dba": 51}'),
  ('GTW845CPNDG2', 'GE 5.2 cu ft Smart Top-Load Washer', NULL, 'electric', 27, 5.2, 11, true, true, 999, ARRAY['SmartDispense','WiFi','Built-in water faucet','Sanitize with Oxi','Quick Wash'], '{"spin_speed_rpm": 850, "cycles": 14, "steam": false, "load_type": "top", "noise_dba": 49}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ge-appliances' AND c.slug = 'washer-top-load-impeller';

-- Maytag additional gas dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.maytag.com/dryers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('MGD7230HW', 'Maytag Pet Pro 7.3 cu ft Gas Dryer', 'Pet Pro', 'gas', 27, 7.3, 14, true, true, 999, ARRAY['Pet Pro option','Extra Power button','XL lint trap','Advanced Moisture Sensing'], '{"cycles": 11, "steam": false, "moisture_sensor": true, "vent_type": "vented"}'),
  ('MGD5430MW', 'Maytag 7.0 cu ft Gas Dryer with Extra Power', NULL, 'gas', 29, 7.0, 14, true, false, 849, ARRAY['Extra Power button','Advanced Moisture Sensing','Wrinkle Prevent','Quick Dry'], '{"cycles": 10, "steam": false, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'maytag' AND c.slug = 'dryer-gas';

-- Samsung additional front-load
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.samsung.com/us/washers/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WF45R6100AV', 'Samsung 4.5 cu ft Front-Load Washer Black Stainless', NULL, 'electric', 27, 4.5, 11, true, true, 849, ARRAY['Self Clean+','Smart Care','VRT Plus','Steam Wash','Black Stainless finish'], '{"spin_speed_rpm": 1200, "cycles": 10, "steam": true, "load_type": "front", "noise_dba": 48}'),
  ('WF45B6300AE', 'Samsung 4.5 cu ft Bespoke Front-Load Washer with AI', 'Bespoke', 'electric', 27, 4.5, 11, true, true, 999, ARRAY['AI OptiWash','Super Speed Wash','Steam Sanitize+','Self Clean+','Bespoke Navy'], '{"spin_speed_rpm": 1300, "cycles": 12, "steam": true, "load_type": "front", "noise_dba": 46}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'samsung' AND c.slug = 'washer-front-load';

-- LG additional front-load
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.lg.com/us/washers/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WM4080HWA', 'LG 4.5 cu ft Smart Front-Load Washer with TurboWash', NULL, 'electric', 27, 4.5, 11, true, true, 949, ARRAY['TurboWash 360','AI DD','6Motion Technology','Steam','LG ThinQ','Allergiene'], '{"spin_speed_rpm": 1300, "cycles": 14, "steam": true, "load_type": "front", "noise_dba": 45}'),
  ('WM6500HBA2', 'LG 5.0 cu ft Smart Front-Load Washer with AI DD 2.0', NULL, 'electric', 27, 5.0, 11, true, true, 1149, ARRAY['AI DD 2.0','TurboWash 360','Allergiene cycle','Steam+Allergiene','ezDispense Plus'], '{"spin_speed_rpm": 1400, "cycles": 14, "steam": true, "load_type": "front", "noise_dba": 43}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'lg' AND c.slug = 'washer-front-load';

-- GE additional front-load
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.geappliances.com/laundry/washers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('GFW655SSVWW2', 'GE 5.0 cu ft Smart Front-Load Washer Diamond Gray', NULL, 'electric', 28, 5.0, 11, true, true, 1049, ARRAY['Steam washing','UltraFresh Vent System','SmartDispense','Built-in WiFi','Diamond Gray finish'], '{"spin_speed_rpm": 1300, "cycles": 12, "steam": true, "load_type": "front", "noise_dba": 47}'),
  ('GFW750SPNRS', 'GE 4.8 cu ft Smart Front-Load Washer Sapphire Blue', NULL, 'electric', 28, 4.8, 11, true, true, 999, ARRAY['SmartDispense','UltraFresh Vent','Microban technology','Built-in WiFi'], '{"spin_speed_rpm": 1300, "cycles": 12, "steam": true, "load_type": "front", "noise_dba": 47}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ge-appliances' AND c.slug = 'washer-front-load';

-- GE additional electric dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.geappliances.com/laundry/dryers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('GFD65ESSNWW2', 'GE 7.8 cu ft Smart Electric Dryer with Steam and Sanitize', NULL, 'electric', 28, 7.8, 13, true, true, 999, ARRAY['Steam Dewrinkle','Sanitize cycle','WiFi','SmartHQ app','Sensor Dry','Quick Dry'], '{"cycles": 13, "steam": true, "moisture_sensor": true, "vent_type": "vented"}'),
  ('GTD65EBSJWS', 'GE 7.4 cu ft Electric Dryer with Sensor Dry', NULL, 'electric', 27, 7.4, 13, false, true, 699, ARRAY['Sensor Dry','Quick Dry','Extended tumble','Wrinkle Care','4 heat selections'], '{"cycles": 10, "steam": false, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ge-appliances' AND c.slug = 'dryer-electric';

-- Frigidaire additional top-load
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.frigidaire.com/laundry/washers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('FFTW4120SB', 'Frigidaire 4.1 cu ft Top-Load Washer Black', NULL, 'electric', 27, 4.1, 12, false, false, 579, ARRAY['MaxFill option','Bleach dispenser','Auto temperature control','10 wash cycles'], '{"spin_speed_rpm": 700, "cycles": 10, "steam": false, "load_type": "top", "noise_dba": 54}'),
  ('FFTW5000QW', 'Frigidaire Gallery 4.7 cu ft Top-Load Washer', 'Gallery', 'electric', 27, 4.7, 11, true, true, 749, ARRAY['SmartBoost','WiFi enabled','MaxFill','Quick Wash 20min','12 cycles'], '{"spin_speed_rpm": 800, "cycles": 12, "steam": false, "load_type": "top", "noise_dba": 51}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'frigidaire' AND c.slug = 'washer-top-load-agitator';

-- Frigidaire additional dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.frigidaire.com/laundry/dryers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('FFRE4120SB', 'Frigidaire 6.7 cu ft Electric Dryer Black', NULL, 'electric', 27, 6.7, 13, false, false, 579, ARRAY['DrySense technology','10 dry cycles','Quick Dry','Reversible door','Black finish'], '{"cycles": 10, "steam": false, "moisture_sensor": true, "vent_type": "vented"}'),
  ('FWRE5000QW', 'Frigidaire Gallery 8.0 cu ft Electric Dryer with WiFi', 'Gallery', 'electric', 27, 8.0, 13, true, true, 849, ARRAY['WiFi enabled','DrySense','Steam Refresh','Quick Dry','12 dry cycles'], '{"cycles": 12, "steam": true, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'frigidaire' AND c.slug = 'dryer-electric';

-- Whirlpool Washer-Dryer Combo
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.whirlpool.com/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WFC8090GX', 'Whirlpool 2.8 cu ft Ventless All-in-One Washer/Dryer', NULL, 'electric', 24, 2.8, 10, true, true, 1899, ARRAY['Ventless combo unit','24-inch compact','Load & Go dispenser','Quick Wash & Dry','WiFi enabled'], '{"spin_speed_rpm": 1400, "cycles": 16, "steam": true, "load_type": "front", "noise_dba": 48}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'whirlpool' AND c.slug = 'washer-dryer-combo';

-- KitchenAid additional Front-Load
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.kitchenaid.com/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('KFLP9030DS', 'KitchenAid 5.0 cu ft Front-Load Washer with Clean Boost', NULL, 'electric', 27, 5.0, 11, true, true, 1299, ARRAY['Clean Boost option','Dynamic Balancing','12-hr FanFresh','Smooth Glide drawer'], '{"spin_speed_rpm": 1300, "cycles": 12, "steam": true, "load_type": "front", "noise_dba": 45}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'kitchenaid' AND c.slug = 'washer-front-load';

-- GE Profile additional front-load
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.geappliances.com/ge-profile/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('PFW870SPTRS', 'GE Profile 5.3 cu ft Smart Front-Load Washer Royal Sapphire', NULL, 'electric', 28, 5.3, 11, true, true, 1349, ARRAY['SmartDispense','UltraFresh Vent System','Microban','1-step wash+dry','Royal Sapphire finish'], '{"spin_speed_rpm": 1300, "cycles": 12, "steam": true, "load_type": "front", "noise_dba": 44}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ge-profile' AND c.slug = 'washer-front-load';

-- GE Profile additional electric dryer
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.geappliances.com/ge-profile/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('PFD87ESPTRS', 'GE Profile 7.8 cu ft Smart Electric Dryer Royal Sapphire', NULL, 'electric', 28, 7.8, 13, true, true, 1349, ARRAY['SmartHQ app','Steam Dewrinkle','Sanitize cycle','Washer Link','Royal Sapphire finish'], '{"cycles": 13, "steam": true, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ge-profile' AND c.slug = 'dryer-electric';

-- Miele additional compact washer
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.mieleusa.com/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WCA660WCS', 'Miele W1 24" Compact Washer with CapDosing', 'W1', 'electric', 24, 2.3, 20, true, true, 1499, ARRAY['CapDosing','TwinDos','Honeycomb drum','WiFiConn@ct','20 wash programs'], '{"spin_speed_rpm": 1600, "cycles": 20, "steam": false, "load_type": "front", "noise_dba": 45}'),
  ('WSD663WCS', 'Miele W1 24" Compact Washer with SteamCare', 'W1', 'electric', 24, 2.3, 20, true, true, 1799, ARRAY['SteamCare','TwinDos','CapDosing','Honeycomb drum','WiFiConn@ct','22 programs'], '{"spin_speed_rpm": 1600, "cycles": 22, "steam": true, "load_type": "front", "noise_dba": 44}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'miele' AND c.slug = 'washer-compact';

-- Bosch additional compact washers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.bosch-home.com/us/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WAW285H3UC', 'Bosch 800 Series 24" Compact Washer with i-DOS', '800 Series', 'electric', 24, 2.2, 15, true, true, 1399, ARRAY['i-DOS automatic dosing','Home Connect WiFi','SpeedPerfect','AquaStop Plus','Interior light'], '{"spin_speed_rpm": 1400, "cycles": 24, "steam": false, "load_type": "front", "noise_dba": 46}'),
  ('WGA254U0UC', 'Bosch 500 Series 24" Compact Washer with Iron Assist', '500 Series', 'electric', 24, 2.2, 15, true, true, 1199, ARRAY['Iron Assist steam','Home Connect','SpeedPerfect','AquaShield','16 wash programs'], '{"spin_speed_rpm": 1400, "cycles": 16, "steam": true, "load_type": "front", "noise_dba": 47}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'bosch' AND c.slug = 'washer-compact';

-- Bosch additional heat pump dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.bosch-home.com/us/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WTW87NH3UC', 'Bosch 800 Series 24" Heat Pump Dryer with Self-Cleaning Condenser', '800 Series', 'electric', 24, 4.0, 15, true, true, 1499, ARRAY['Heat pump','Self-cleaning condenser','Ventless','Home Connect','SensitiveDrying'], '{"cycles": 15, "steam": false, "moisture_sensor": true, "vent_type": "ventless"}'),
  ('WGA154U0UC', 'Bosch 500 Series 24" Condensation Dryer', '500 Series', 'electric', 24, 4.0, 14, true, true, 1049, ARRAY['Ventless condensation','Home Connect','SensitiveDrying','AntiVibration','Stackable'], '{"cycles": 12, "steam": false, "moisture_sensor": true, "vent_type": "ventless"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'bosch' AND c.slug = 'dryer-heat-pump';

-- Samsung additional top-load agitator
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.samsung.com/us/washers/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WA40A3205AW', 'Samsung 4.0 cu ft Top-Load Washer with ActiveWave', NULL, 'electric', 27, 4.0, 12, false, false, 499, ARRAY['ActiveWave agitator','Soft-Close Lid','Self Clean','8 cycles'], '{"spin_speed_rpm": 680, "cycles": 8, "steam": false, "load_type": "top", "noise_dba": 55}'),
  ('WA50CG3505AV', 'Samsung 5.0 cu ft Smart Top-Load Washer with Agitator', NULL, 'electric', 27, 5.0, 12, true, true, 749, ARRAY['ActiveWave agitator','WiFi enabled','Deep Fill','Super Speed','Self Clean'], '{"spin_speed_rpm": 800, "cycles": 12, "steam": false, "load_type": "top", "noise_dba": 51}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'samsung' AND c.slug = 'washer-top-load-agitator';

-- Samsung additional gas dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.samsung.com/us/dryers/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DVG45A6400V', 'Samsung 7.5 cu ft Smart Dial Gas Dryer', NULL, 'gas', 27, 7.5, 14, true, true, 999, ARRAY['Smart Dial','Steam Sanitize+','Sensor Dry','AI Optimal Dry','WiFi'], '{"cycles": 12, "steam": true, "moisture_sensor": true, "vent_type": "vented"}'),
  ('DVG60A9900V', 'Samsung 7.5 cu ft Smart Dial Gas Dryer with MultiControl', NULL, 'gas', 27, 7.5, 14, true, true, 1099, ARRAY['Smart Dial','MultiControl panel','Steam Sanitize+','Sensor Dry','AI Optimal Dry'], '{"cycles": 14, "steam": true, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'samsung' AND c.slug = 'dryer-gas';

-- LG additional gas dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.lg.com/us/dryers/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DLGX4201B', 'LG 7.4 cu ft Smart Gas Dryer with AI Sensor', NULL, 'gas', 27, 7.4, 14, true, true, 1049, ARRAY['AI Fabric Sensor','TurboSteam','Sensor Dry','LG ThinQ','Proactive Customer Care'], '{"cycles": 14, "steam": true, "moisture_sensor": true, "vent_type": "vented"}'),
  ('DLGX5501V', 'LG 7.4 cu ft Smart Gas Dryer Black Steel', NULL, 'gas', 27, 7.4, 14, true, true, 999, ARRAY['TurboSteam','Sensor Dry','LG ThinQ','ReduceStatic','Black Steel finish'], '{"cycles": 12, "steam": true, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'lg' AND c.slug = 'dryer-gas';

-- GE additional gas dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.geappliances.com/laundry/dryers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('GTD65GBSJWS', 'GE 7.4 cu ft Gas Dryer with Sensor Dry', NULL, 'gas', 27, 7.4, 14, false, true, 799, ARRAY['Sensor Dry','Quick Dry','Extended tumble','Wrinkle Care','4 heat selections'], '{"cycles": 10, "steam": false, "moisture_sensor": true, "vent_type": "vented"}'),
  ('GFD85GSPNRS', 'GE 7.8 cu ft Sapphire Blue Smart Gas Dryer', NULL, 'gas', 28, 7.8, 14, true, true, 1199, ARRAY['SmartHQ app','Steam Dewrinkle','Sanitize cycle','Quick Dry','Sapphire Blue finish'], '{"cycles": 13, "steam": true, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ge-appliances' AND c.slug = 'dryer-gas';

-- Whirlpool additional gas dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.whirlpool.com/laundry/dryers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WGD6605MW', 'Whirlpool 7.4 cu ft Smart Gas Dryer with Steam', NULL, 'gas', 27, 7.4, 14, true, true, 1099, ARRAY['Steam Refresh','Wrinkle Shield Plus','Advanced Moisture Sensing','EcoBoost','Quick Dry'], '{"cycles": 13, "steam": true, "moisture_sensor": true, "vent_type": "vented"}'),
  ('WGD9505FW', 'Whirlpool 7.4 cu ft HybridCare Ventless Gas-Heat Pump Dryer', NULL, 'gas', 27, 7.4, 14, true, true, 1299, ARRAY['Ventless hybrid','Advanced Moisture Sensing','Wrinkle Shield','EcoBoost'], '{"cycles": 14, "steam": false, "moisture_sensor": true, "vent_type": "ventless"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'whirlpool' AND c.slug = 'dryer-gas';

-- Maytag additional front-load
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.maytag.com/washers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('MHW5630HC', 'Maytag 4.5 cu ft Front-Load Washer Metallic Slate', NULL, 'electric', 27, 4.5, 11, true, true, 949, ARRAY['Extra Power button','12-hour Fresh Spin','Quick Wash','Metallic Slate finish'], '{"spin_speed_rpm": 1200, "cycles": 10, "steam": false, "load_type": "front", "noise_dba": 49}'),
  ('MHW6630HC', 'Maytag 4.8 cu ft Front-Load Washer Metallic Slate', NULL, 'electric', 27, 4.8, 11, true, true, 1049, ARRAY['Extra Power button','Steam for Stains','16-hr Fresh Spin','Metallic Slate finish'], '{"spin_speed_rpm": 1300, "cycles": 12, "steam": true, "load_type": "front", "noise_dba": 47}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'maytag' AND c.slug = 'washer-front-load';

-- Maytag additional electric dryers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.maytag.com/dryers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('MED5630HC', 'Maytag 7.3 cu ft Electric Dryer Metallic Slate', NULL, 'electric', 27, 7.3, 13, true, true, 949, ARRAY['Extra Power button','Advanced Moisture Sensing','Quick Dry','Metallic Slate finish'], '{"cycles": 11, "steam": false, "moisture_sensor": true, "vent_type": "vented"}'),
  ('MED6630HC', 'Maytag 7.3 cu ft Smart Electric Dryer with Steam Metallic Slate', NULL, 'electric', 27, 7.3, 13, true, true, 1049, ARRAY['Extra Power button','Steam Enhanced dryer','Advanced Moisture Sensing','Metallic Slate'], '{"cycles": 12, "steam": true, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'maytag' AND c.slug = 'dryer-electric';

-- Frigidaire Gallery Gas Dryer
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.frigidaire.com/laundry/dryers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('FWRG5000QW', 'Frigidaire Gallery 8.0 cu ft Gas Dryer with WiFi', 'Gallery', 'gas', 27, 8.0, 14, true, true, 949, ARRAY['WiFi enabled','DrySense','Steam Refresh','Quick Dry','12 dry cycles'], '{"cycles": 12, "steam": true, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'frigidaire' AND c.slug = 'dryer-gas';

-- Frigidaire Gallery Top-Load Impeller
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.frigidaire.com/laundry/washers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('FFTW5000QI', 'Frigidaire Gallery 4.7 cu ft Top-Load HE Washer', 'Gallery', 'electric', 27, 4.7, 11, true, true, 799, ARRAY['SmartBoost','WiFi enabled','Quick Wash','Auto temperature','12 cycles'], '{"spin_speed_rpm": 800, "cycles": 12, "steam": false, "load_type": "top", "noise_dba": 50}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'frigidaire' AND c.slug = 'washer-top-load-impeller';

-- Electrolux additional washer-dryer combo
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.electrolux.com/us/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('ELWC02QT', 'Electrolux 24" Compact Washer-Dryer Combo', NULL, 'electric', 24, 2.4, 10, true, true, 1999, ARRAY['Ventless all-in-one','SmartBoost','LuxCare Wash','15-min Fast Wash','WiFi enabled'], '{"spin_speed_rpm": 1400, "cycles": 14, "steam": true, "load_type": "front", "noise_dba": 48}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'electrolux' AND c.slug = 'washer-dryer-combo';

-- Samsung additional combo
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.samsung.com/us/washers/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WD53DBA100HZ', 'Samsung Bespoke AI Laundry Combo Dark Steel', 'Bespoke AI', 'electric', 27, 5.3, 10, true, true, 2599, ARRAY['All-in-one wash + dry','AI OptiWash/Dry','Ventless heat pump','Super Speed','Dark Steel finish'], '{"spin_speed_rpm": 1300, "cycles": 14, "steam": true, "load_type": "front", "noise_dba": 44}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'samsung' AND c.slug = 'washer-dryer-combo';

-- KitchenAid additional electric dryer
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.kitchenaid.com/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('KFED200EWH2', 'KitchenAid 7.4 cu ft Smart Electric Dryer', NULL, 'electric', 27, 7.4, 13, true, true, 1499, ARRAY['Steam Refresh','Advanced Moisture Sensing','Wrinkle Shield Plus','EcoBoost','WiFi enabled'], '{"cycles": 13, "steam": true, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'kitchenaid' AND c.slug = 'dryer-electric';

-- LG WashTower additional
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.lg.com/us/washers/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WKGX201HBA', 'LG WashTower with Gas Dryer', 'WashTower', 'gas', 27, 4.5, 10, true, true, 2099, ARRAY['Single unit WashTower design','Center Control panel','AI Fabric Sensor','TurboWash 360','Gas dryer on top'], '{"spin_speed_rpm": 1300, "cycles": 14, "steam": true, "load_type": "front", "noise_dba": 44}'),
  ('WKEX200HWA', 'LG WashTower Single Unit White', 'WashTower', 'electric', 27, 4.5, 10, true, true, 1949, ARRAY['Single unit WashTower','Center Control','AI Fabric Sensor','TurboWash 360','White finish'], '{"spin_speed_rpm": 1300, "cycles": 14, "steam": true, "load_type": "front", "noise_dba": 44}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'lg' AND c.slug = 'washer-dryer-combo';

-- GE Compact Washer
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.geappliances.com/laundry/washers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('GFW148SSMWW', 'GE 24" 2.4 cu ft Compact Front-Load Washer', NULL, 'electric', 24, 2.4, 11, true, true, 899, ARRAY['UltraFresh Vent System','Compact 24-inch','WiFi enabled','Microban antimicrobial','Stackable'], '{"spin_speed_rpm": 1400, "cycles": 14, "steam": false, "load_type": "front", "noise_dba": 49}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ge-appliances' AND c.slug = 'washer-compact';

-- GE Compact Dryer
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.geappliances.com/laundry/dryers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('GFT14ESSMWW', 'GE 24" 4.1 cu ft Compact Ventless Electric Dryer', NULL, 'electric', 24, 4.1, 12, true, true, 999, ARRAY['Ventless condensation','WiFi enabled','Compact 24-inch','Stackable','Sensor Dry'], '{"cycles": 12, "steam": false, "moisture_sensor": true, "vent_type": "ventless"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ge-appliances' AND c.slug = 'dryer-compact';

-- Whirlpool Compact Washer
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.whirlpool.com/laundry/washers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WFW3090GW', 'Whirlpool 24" 2.3 cu ft Compact Front-Load Washer White', NULL, 'electric', 24, 2.3, 11, false, true, 849, ARRAY['Compact 24-inch','Stainless steel drum','Detergent dosing aid','Stackable','14 cycles'], '{"spin_speed_rpm": 1400, "cycles": 14, "steam": false, "load_type": "front", "noise_dba": 50}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'whirlpool' AND c.slug = 'washer-compact';

-- Maytag Washer-Dryer Combo
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.maytag.com/washers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('MHWDC5600HW', 'Maytag 4.5 cu ft All-in-One Washer/Dryer', NULL, 'electric', 27, 4.5, 10, true, true, 2199, ARRAY['Ventless combo','Extra Power button','Steam for Stains','WiFi enabled','No dryer vent needed'], '{"spin_speed_rpm": 1300, "cycles": 14, "steam": true, "load_type": "front", "noise_dba": 47}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'maytag' AND c.slug = 'washer-dryer-combo';

-- Samsung Compact Washer-Dryer
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.samsung.com/us/washers/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WD25B6900AW', 'Samsung Bespoke Compact All-in-One Washer/Dryer', 'Bespoke', 'electric', 24, 2.5, 10, true, true, 1799, ARRAY['All-in-one compact','Ventless heat pump dry','AI OptiWash','Super Speed','24-inch design'], '{"spin_speed_rpm": 1400, "cycles": 14, "steam": true, "load_type": "front", "noise_dba": 47}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'samsung' AND c.slug = 'washer-dryer-combo';

-- Speed Queen Front-Load Electric Dryer
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.speedqueen.com/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DF7004WE', 'Speed Queen DF7 Front-Load Electric Dryer', 'DF7', 'electric', 27, 7.0, 25, true, false, 1599, ARRAY['Commercial-grade','WiFi enabled','Speed Queen app','Reversible door','7-year warranty'], '{"cycles": 9, "steam": false, "moisture_sensor": true, "vent_type": "vented"}'),
  ('DF7004WG', 'Speed Queen DF7 Front-Load Gas Dryer', 'DF7', 'gas', 27, 7.0, 25, true, false, 1699, ARRAY['Commercial-grade','WiFi enabled','Speed Queen app','Reversible door','7-year warranty'], '{"cycles": 9, "steam": false, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'speed-queen' AND c.slug = 'dryer-electric';

-- Fisher & Paykel Front-Load additional
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.fisherpaykel.com/us/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WH2724F1', 'Fisher & Paykel 27" Front-Load Washer with Steam', 'Series 7', 'electric', 27, 4.0, 11, true, true, 1499, ARRAY['ActiveIntelligence','Steam Refresh','Add a Garment','SmartDrive motor','Sanitize cycle'], '{"spin_speed_rpm": 1300, "cycles": 15, "steam": true, "load_type": "front", "noise_dba": 46}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'fisher-paykel' AND c.slug = 'washer-front-load';

-- Fisher & Paykel 27" Electric Dryer additional
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.fisherpaykel.com/us/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DE2724F1', 'Fisher & Paykel 27" Electric Dryer with Steam', 'Series 7', 'electric', 27, 7.0, 13, true, true, 1499, ARRAY['ActiveIntelligence','Steam Refresh','Auto-sensing dry','15 dry cycles'], '{"cycles": 15, "steam": true, "moisture_sensor": true, "vent_type": "vented"}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'fisher-paykel' AND c.slug = 'dryer-electric';

-- ASKO Washer-Dryer Combo
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.askona.com/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WD8748H.W', 'ASKO 24" Washer-Dryer Combo', 'Logic', 'electric', 24, 2.8, 12, true, true, 2199, ARRAY['Wash and dry in one unit','Steel Seal','Ventless heat pump dry','Active Drum','Smart connected'], '{"spin_speed_rpm": 1400, "cycles": 16, "steam": true, "load_type": "front", "noise_dba": 45}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'asko' AND c.slug = 'washer-dryer-combo';

-- Haier additional compact washer
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', v.width, v.cap, 'cu_ft', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.haier.com/us/laundry'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('QFW150SSNWW3', 'Haier 24" 2.4 cu ft Compact Washer with Steam', NULL, 'electric', 24, 2.4, 10, true, true, 999, ARRAY['Steam option','Smart HQ app','Internal heater','Stainless steel drum','14 wash cycles'], '{"spin_speed_rpm": 1400, "cycles": 14, "steam": true, "load_type": "front", "noise_dba": 49}')
) AS v(model_number, model_name, series, fuel, width, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'haier' AND c.slug = 'washer-compact';

-- ============================================================================
-- END OF LAUNDRY CATALOG
-- ============================================================================
