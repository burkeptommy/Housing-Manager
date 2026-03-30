-- Equipment Catalog: HVAC Systems
-- ============================================================================
-- Covers all HVAC brands: Budget, Mainstream, Premium, High-End, Ultra-Luxury
-- Categories: central-ac, furnace, heat-pump, boiler, mini-split, air-handler
-- 400+ models across 24 brands
-- ============================================================================

SET ROLE postgres;

-- ======================== BUDGET BRANDS ========================

-- -------------------- GOODMAN --------------------

-- Goodman Central AC
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'split-system', NULL, v.cap, 'tons', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.goodmanmfg.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('GSXC180361', 'GSXC18 3-Ton AC', 'GSXC18', 3, 15, false, true, 3800, ARRAY['Up to 19 SEER','Two-stage compressor','ComfortBridge technology','Sound: 71 dB'], '{"seer": 19, "seer2": 18.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage", "compressor": "scroll"}'),
  ('GSXC180481', 'GSXC18 4-Ton AC', 'GSXC18', 4, 15, false, true, 4200, ARRAY['Up to 19 SEER','Two-stage compressor','ComfortBridge technology'], '{"seer": 19, "seer2": 18.0, "tons": 4, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage", "compressor": "scroll"}'),
  ('GSXC180601', 'GSXC18 5-Ton AC', 'GSXC18', 5, 15, false, true, 4600, ARRAY['Up to 18 SEER','Two-stage compressor','ComfortBridge technology'], '{"seer": 18, "seer2": 17.2, "tons": 5, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage", "compressor": "scroll"}'),
  ('GSX160241', 'GSX16 2-Ton AC', 'GSX16', 2, 15, false, true, 2200, ARRAY['Up to 16 SEER','Single-stage compressor','Factory-charged R-410A'], '{"seer": 16, "seer2": 15.2, "tons": 2, "voltage": 208, "refrigerant": "R-410A", "stages": "single", "compressor": "scroll"}'),
  ('GSX160361', 'GSX16 3-Ton AC', 'GSX16', 3, 15, false, true, 2600, ARRAY['Up to 16 SEER','Single-stage compressor','Chlorine-free R-410A'], '{"seer": 16, "seer2": 15.2, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single", "compressor": "scroll"}'),
  ('GSX160481', 'GSX16 4-Ton AC', 'GSX16', 4, 15, false, true, 3000, ARRAY['Up to 16 SEER','Single-stage compressor','Heavy-gauge galvanized steel'], '{"seer": 16, "seer2": 15.2, "tons": 4, "voltage": 208, "refrigerant": "R-410A", "stages": "single", "compressor": "scroll"}'),
  ('GSX140361', 'GSX14 3-Ton AC', 'GSX14', 3, 15, false, false, 1800, ARRAY['Up to 15 SEER','Single-stage compressor','Entry-level efficiency'], '{"seer": 15, "seer2": 14.3, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single", "compressor": "scroll"}'),
  ('GSX140241', 'GSX14 2-Ton AC', 'GSX14', 2, 15, false, false, 1500, ARRAY['Up to 15 SEER','Single-stage','Budget-friendly'], '{"seer": 15, "seer2": 14.3, "tons": 2, "voltage": 208, "refrigerant": "R-410A", "stages": "single", "compressor": "scroll"}'),
  ('GSXN404810', 'GSXN4 4-Ton AC', 'GSXN4', 4, 15, false, true, 3100, ARRAY['Up to 15.2 SEER2','Single-stage','Next-gen platform'], '{"seer2": 15.2, "tons": 4, "voltage": 208, "refrigerant": "R-410A", "stages": "single", "compressor": "scroll"}'),
  ('GSXN403610', 'GSXN4 3-Ton AC', 'GSXN4', 3, 15, false, true, 2700, ARRAY['Up to 15.2 SEER2','Single-stage','Next-gen platform'], '{"seer2": 15.2, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single", "compressor": "scroll"}')
) AS v(model_number, model_name, series, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'goodman' AND c.slug = 'hvac-central-ac';

-- Goodman Furnaces
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'split-system', NULL, v.cap, 'btu', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.goodmanmfg.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('GMVC961005CN', 'GMVC96 100K BTU Furnace', 'GMVC96', 'gas', 100000, 20, false, true, 2800, ARRAY['96% AFUE','Variable-speed blower','Two-stage gas valve','ComfortBridge'], '{"afue": 96, "btu": 100000, "voltage": 120, "stages": "two-stage", "blower": "variable-speed"}'),
  ('GMVC960804CN', 'GMVC96 80K BTU Furnace', 'GMVC96', 'gas', 80000, 20, false, true, 2500, ARRAY['96% AFUE','Variable-speed blower','Two-stage gas valve'], '{"afue": 96, "btu": 80000, "voltage": 120, "stages": "two-stage", "blower": "variable-speed"}'),
  ('GMVC960603BN', 'GMVC96 60K BTU Furnace', 'GMVC96', 'gas', 60000, 20, false, true, 2200, ARRAY['96% AFUE','Variable-speed blower','Compact cabinet'], '{"afue": 96, "btu": 60000, "voltage": 120, "stages": "two-stage", "blower": "variable-speed"}'),
  ('GMSS920804CN', 'GMSS92 80K BTU Furnace', 'GMSS92', 'gas', 80000, 20, false, true, 2000, ARRAY['92% AFUE','Single-stage','Multi-speed blower'], '{"afue": 92, "btu": 80000, "voltage": 120, "stages": "single", "blower": "multi-speed"}'),
  ('GMSS921005CN', 'GMSS92 100K BTU Furnace', 'GMSS92', 'gas', 100000, 20, false, true, 2200, ARRAY['92% AFUE','Single-stage','Silicon nitride igniter'], '{"afue": 92, "btu": 100000, "voltage": 120, "stages": "single", "blower": "multi-speed"}'),
  ('GMS80804BN', 'GMS80 80K BTU Furnace', 'GMS80', 'gas', 80000, 20, false, false, 1400, ARRAY['80% AFUE','Single-stage','Entry-level furnace'], '{"afue": 80, "btu": 80000, "voltage": 120, "stages": "single", "blower": "multi-speed"}'),
  ('GMS81005CN', 'GMS80 100K BTU Furnace', 'GMS80', 'gas', 100000, 20, false, false, 1600, ARRAY['80% AFUE','Single-stage','Non-condensing'], '{"afue": 80, "btu": 100000, "voltage": 120, "stages": "single", "blower": "multi-speed"}'),
  ('GCVM970804CN', 'GCVM97 80K BTU Furnace', 'GCVM97', 'gas', 80000, 20, false, true, 3200, ARRAY['97% AFUE','Variable-speed ECM blower','Modulating gas valve','ComfortBridge'], '{"afue": 97, "btu": 80000, "voltage": 120, "stages": "modulating", "blower": "variable-speed"}'),
  ('GCVM971005CN', 'GCVM97 100K BTU Furnace', 'GCVM97', 'gas', 100000, 20, false, true, 3500, ARRAY['97% AFUE','Modulating gas valve','Variable-speed ECM blower'], '{"afue": 97, "btu": 100000, "voltage": 120, "stages": "modulating", "blower": "variable-speed"}')
) AS v(model_number, model_name, series, fuel, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'goodman' AND c.slug = 'hvac-furnace';

-- Goodman Heat Pumps
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'split-system', NULL, v.cap, 'tons', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.goodmanmfg.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('GSZC180361', 'GSZC18 3-Ton Heat Pump', 'GSZC18', 3, 15, false, true, 4200, ARRAY['Up to 19 SEER','Two-stage compressor','Heating down to 0F'], '{"seer": 19, "hspf": 10.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage", "compressor": "scroll"}'),
  ('GSZC180481', 'GSZC18 4-Ton Heat Pump', 'GSZC18', 4, 15, false, true, 4600, ARRAY['Up to 18 SEER','Two-stage compressor','ComfortBridge compatible'], '{"seer": 18, "hspf": 9.5, "tons": 4, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage", "compressor": "scroll"}'),
  ('GSZB600361', 'GSZB6 3-Ton Heat Pump', 'GSZB6', 3, 15, false, true, 3200, ARRAY['Up to 15.2 SEER2','Single-stage','R-410A'], '{"seer2": 15.2, "hspf2": 7.8, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single", "compressor": "scroll"}'),
  ('GSZB600241', 'GSZB6 2-Ton Heat Pump', 'GSZB6', 2, 15, false, true, 2800, ARRAY['Up to 15.2 SEER2','Single-stage','Factory-charged'], '{"seer2": 15.2, "hspf2": 7.8, "tons": 2, "voltage": 208, "refrigerant": "R-410A", "stages": "single", "compressor": "scroll"}')
) AS v(model_number, model_name, series, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'goodman' AND c.slug = 'hvac-heat-pump';

-- Goodman Air Handlers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'split-system', NULL, v.cap, 'tons', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, 'https://www.goodmanmfg.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('AVPTC49D14', 'AVPTC 4-Ton Air Handler', 'AVPTC', 4, 15, 1800, ARRAY['Variable-speed ECM blower','Multi-position install','All-aluminum evaporator coil'], '{"tons": 4, "voltage": 208, "blower": "variable-speed"}'),
  ('AVPTC37C14', 'AVPTC 3-Ton Air Handler', 'AVPTC', 3, 15, 1500, ARRAY['Variable-speed ECM blower','Factory-installed TXV'], '{"tons": 3, "voltage": 208, "blower": "variable-speed"}'),
  ('AMST36CU1400', 'AMST 3-Ton Air Handler', 'AMST', 3, 15, 1200, ARRAY['Multi-speed blower','Multi-position install'], '{"tons": 3, "voltage": 208, "blower": "multi-speed"}'),
  ('AMST48DU1400', 'AMST 4-Ton Air Handler', 'AMST', 4, 15, 1400, ARRAY['Multi-speed blower','Aluminum evaporator coil'], '{"tons": 4, "voltage": 208, "blower": "multi-speed"}')
) AS v(model_number, model_name, series, cap, lifespan, msrp, features, specs)
WHERE m.slug = 'goodman' AND c.slug = 'hvac-air-handler';

-- -------------------- PAYNE --------------------

-- Payne Central AC
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'split-system', NULL, v.cap, 'tons', true, v.lifespan, false, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.payne.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('PA17NA036', 'PA17NA 3-Ton AC', 'PA17NA', 3, 15, true, 2800, ARRAY['Up to 17 SEER','Two-stage compressor','WeatherArmor Ultra protection'], '{"seer": 17, "seer2": 16.2, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage", "compressor": "scroll"}'),
  ('PA17NA048', 'PA17NA 4-Ton AC', 'PA17NA', 4, 15, true, 3200, ARRAY['Up to 17 SEER','Two-stage compressor','Silencer System II'], '{"seer": 17, "seer2": 16.2, "tons": 4, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage", "compressor": "scroll"}'),
  ('PA16NA036', 'PA16NA 3-Ton AC', 'PA16NA', 3, 15, true, 2200, ARRAY['Up to 16 SEER','Single-stage compressor','Sound: 72 dB'], '{"seer": 16, "seer2": 15.2, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single", "compressor": "scroll"}'),
  ('PA14NA036', 'PA14NA 3-Ton AC', 'PA14NA', 3, 15, false, 1700, ARRAY['Up to 14.3 SEER2','Single-stage','Entry-level'], '{"seer2": 14.3, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single", "compressor": "scroll"}'),
  ('PA14NA024', 'PA14NA 2-Ton AC', 'PA14NA', 2, 15, false, 1400, ARRAY['Up to 14.3 SEER2','Single-stage','Compact footprint'], '{"seer2": 14.3, "tons": 2, "voltage": 208, "refrigerant": "R-410A", "stages": "single", "compressor": "scroll"}')
) AS v(model_number, model_name, series, cap, lifespan, estar, msrp, features, specs)
WHERE m.slug = 'payne' AND c.slug = 'hvac-central-ac';

-- Payne Furnaces
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'gas', 'split-system', NULL, v.cap, 'btu', true, v.lifespan, false, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.payne.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('PG96VAT36080B', 'PG96VA 80K BTU Furnace', 'PG96VA', 80000, 20, true, 2400, ARRAY['96% AFUE','Variable-speed blower','Two-stage gas valve'], '{"afue": 96, "btu": 80000, "voltage": 120, "stages": "two-stage", "blower": "variable-speed"}'),
  ('PG96VAT42100C', 'PG96VA 100K BTU Furnace', 'PG96VA', 100000, 20, true, 2700, ARRAY['96% AFUE','Variable-speed blower','Two-stage gas valve'], '{"afue": 96, "btu": 100000, "voltage": 120, "stages": "two-stage", "blower": "variable-speed"}'),
  ('PG95SAT36060B', 'PG95SA 60K BTU Furnace', 'PG95SA', 60000, 20, true, 1800, ARRAY['95% AFUE','Single-stage','Multi-speed blower'], '{"afue": 95, "btu": 60000, "voltage": 120, "stages": "single", "blower": "multi-speed"}'),
  ('PG80ESA42080B', 'PG80ES 80K BTU Furnace', 'PG80ES', 80000, 20, false, 1200, ARRAY['80% AFUE','Single-stage','Entry-level'], '{"afue": 80, "btu": 80000, "voltage": 120, "stages": "single", "blower": "multi-speed"}'),
  ('PG80ESA42100C', 'PG80ES 100K BTU Furnace', 'PG80ES', 100000, 20, false, 1400, ARRAY['80% AFUE','Single-stage','Non-condensing'], '{"afue": 80, "btu": 100000, "voltage": 120, "stages": "single", "blower": "multi-speed"}')
) AS v(model_number, model_name, series, cap, lifespan, estar, msrp, features, specs)
WHERE m.slug = 'payne' AND c.slug = 'hvac-furnace';

-- Payne Heat Pumps
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'split-system', NULL, v.cap, 'tons', true, 15, false, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.payne.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('PH17NA036', 'PH17NA 3-Ton Heat Pump', 'PH17NA', 3, true, 3200, ARRAY['Up to 17 SEER','Two-stage compressor','Heating and cooling'], '{"seer": 17, "hspf": 9.5, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage"}'),
  ('PH16NA036', 'PH16NA 3-Ton Heat Pump', 'PH16NA', 3, true, 2600, ARRAY['Up to 16 SEER','Single-stage','WeatherArmor protection'], '{"seer": 16, "hspf": 9.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}'),
  ('PH14NB036', 'PH14NB 3-Ton Heat Pump', 'PH14NB', 3, false, 2000, ARRAY['Up to 14.3 SEER2','Single-stage','Entry-level heat pump'], '{"seer2": 14.3, "hspf2": 7.5, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}')
) AS v(model_number, model_name, series, cap, estar, msrp, features, specs)
WHERE m.slug = 'payne' AND c.slug = 'hvac-heat-pump';

-- -------------------- RUNTRU --------------------

-- RunTru Central AC
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'split-system', NULL, v.cap, 'tons', true, 15, false, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.runtru.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('A4AC5036E1', 'A4AC5 3-Ton AC', 'A4AC5', 3, true, 2400, ARRAY['Up to 15.2 SEER2','Single-stage','Trane-built quality at value price'], '{"seer2": 15.2, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single", "compressor": "scroll"}'),
  ('A4AC5048E1', 'A4AC5 4-Ton AC', 'A4AC5', 4, true, 2800, ARRAY['Up to 15.2 SEER2','Single-stage','Durable Climatuff compressor'], '{"seer2": 15.2, "tons": 4, "voltage": 208, "refrigerant": "R-410A", "stages": "single", "compressor": "scroll"}'),
  ('A4AC5024E1', 'A4AC5 2-Ton AC', 'A4AC5', 2, true, 2000, ARRAY['Up to 15.2 SEER2','Single-stage','Compact footprint'], '{"seer2": 15.2, "tons": 2, "voltage": 208, "refrigerant": "R-410A", "stages": "single", "compressor": "scroll"}'),
  ('A4AC5060E1', 'A4AC5 5-Ton AC', 'A4AC5', 5, true, 3200, ARRAY['Up to 15.2 SEER2','Single-stage','For larger homes'], '{"seer2": 15.2, "tons": 5, "voltage": 208, "refrigerant": "R-410A", "stages": "single", "compressor": "scroll"}')
) AS v(model_number, model_name, series, cap, estar, msrp, features, specs)
WHERE m.slug = 'runtru' AND c.slug = 'hvac-central-ac';

-- RunTru Furnaces
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'gas', 'split-system', NULL, v.cap, 'btu', true, 20, false, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.runtru.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('A95UH1E080B12S', 'A95UH 80K BTU Furnace', 'A95UH', 80000, true, 1800, ARRAY['95% AFUE','Single-stage','Multi-speed blower','Trane-built'], '{"afue": 95, "btu": 80000, "voltage": 120, "stages": "single", "blower": "multi-speed"}'),
  ('A95UH1E060B12S', 'A95UH 60K BTU Furnace', 'A95UH', 60000, true, 1500, ARRAY['95% AFUE','Single-stage','Compact cabinet'], '{"afue": 95, "btu": 60000, "voltage": 120, "stages": "single", "blower": "multi-speed"}'),
  ('A95UH2E100C16S', 'A95UH 100K BTU Furnace', 'A95UH', 100000, true, 2000, ARRAY['95% AFUE','Single-stage','Large capacity'], '{"afue": 95, "btu": 100000, "voltage": 120, "stages": "single", "blower": "multi-speed"}'),
  ('A80UH1E080B12S', 'A80UH 80K BTU Furnace', 'A80UH', 80000, false, 1200, ARRAY['80% AFUE','Single-stage','Builder-grade'], '{"afue": 80, "btu": 80000, "voltage": 120, "stages": "single", "blower": "multi-speed"}')
) AS v(model_number, model_name, series, cap, estar, msrp, features, specs)
WHERE m.slug = 'runtru' AND c.slug = 'hvac-furnace';

-- RunTru Heat Pumps
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'split-system', NULL, v.cap, 'tons', true, 15, false, true, v.msrp, v.features, v.specs::jsonb, 'https://www.runtru.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('A4HP5036E1', 'A4HP5 3-Ton Heat Pump', 'A4HP5', 3, 2800, ARRAY['Up to 15.2 SEER2','Single-stage','Heating and cooling'], '{"seer2": 15.2, "hspf2": 7.8, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}'),
  ('A4HP5048E1', 'A4HP5 4-Ton Heat Pump', 'A4HP5', 4, 3200, ARRAY['Up to 15.2 SEER2','Single-stage','Climatuff compressor'], '{"seer2": 15.2, "hspf2": 7.8, "tons": 4, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}')
) AS v(model_number, model_name, series, cap, msrp, features, specs)
WHERE m.slug = 'runtru' AND c.slug = 'hvac-heat-pump';

-- -------------------- AMERISTAR --------------------

-- Ameristar Central AC
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'split-system', NULL, v.cap, 'tons', true, 15, false, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.ameristar.us.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('M4AC5036E1', 'M4AC5 3-Ton AC', 'M4AC5', 3, true, 2300, ARRAY['Up to 15.2 SEER2','Single-stage','Trane-manufactured'], '{"seer2": 15.2, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}'),
  ('M4AC5048E1', 'M4AC5 4-Ton AC', 'M4AC5', 4, true, 2700, ARRAY['Up to 15.2 SEER2','Single-stage','Climatuff compressor'], '{"seer2": 15.2, "tons": 4, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}'),
  ('M4AC5024E1', 'M4AC5 2-Ton AC', 'M4AC5', 2, true, 1900, ARRAY['Up to 15.2 SEER2','Single-stage','Compact design'], '{"seer2": 15.2, "tons": 2, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}'),
  ('M4AC4036A1', 'M4AC4 3-Ton AC', 'M4AC4', 3, false, 1800, ARRAY['Up to 14.3 SEER2','Single-stage','Budget-friendly'], '{"seer2": 14.3, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}')
) AS v(model_number, model_name, series, cap, estar, msrp, features, specs)
WHERE m.slug = 'ameristar' AND c.slug = 'hvac-central-ac';

-- Ameristar Furnaces
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'gas', 'split-system', NULL, v.cap, 'btu', true, 20, false, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.ameristar.us.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('M95ESN1002120A', 'M95ESN 100K BTU Furnace', 'M95ESN', 100000, true, 2000, ARRAY['95% AFUE','Single-stage','Trane-built'], '{"afue": 95, "btu": 100000, "voltage": 120, "stages": "single", "blower": "multi-speed"}'),
  ('M95ESN0801716A', 'M95ESN 80K BTU Furnace', 'M95ESN', 80000, true, 1700, ARRAY['95% AFUE','Single-stage','Multi-speed blower'], '{"afue": 95, "btu": 80000, "voltage": 120, "stages": "single", "blower": "multi-speed"}'),
  ('M80ESN0801716A', 'M80ESN 80K BTU Furnace', 'M80ESN', 80000, false, 1100, ARRAY['80% AFUE','Single-stage','Builder-grade pricing'], '{"afue": 80, "btu": 80000, "voltage": 120, "stages": "single", "blower": "multi-speed"}')
) AS v(model_number, model_name, series, cap, estar, msrp, features, specs)
WHERE m.slug = 'ameristar' AND c.slug = 'hvac-furnace';

-- Ameristar Heat Pumps
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'split-system', NULL, v.cap, 'tons', true, 15, false, true, v.msrp, v.features, v.specs::jsonb, 'https://www.ameristar.us.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('M4HP5036E1', 'M4HP5 3-Ton Heat Pump', 'M4HP5', 3, 2700, ARRAY['Up to 15.2 SEER2','Single-stage','Climatuff compressor'], '{"seer2": 15.2, "hspf2": 7.8, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}'),
  ('M4HP5048E1', 'M4HP5 4-Ton Heat Pump', 'M4HP5', 4, 3100, ARRAY['Up to 15.2 SEER2','Single-stage','Large capacity'], '{"seer2": 15.2, "hspf2": 7.8, "tons": 4, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}')
) AS v(model_number, model_name, series, cap, msrp, features, specs)
WHERE m.slug = 'ameristar' AND c.slug = 'hvac-heat-pump';

-- -------------------- DUCANE --------------------

-- Ducane Central AC
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'split-system', NULL, v.cap, 'tons', true, 15, false, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.ducane.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('2AC16L36P', '2AC16L 3-Ton AC', '2AC16L', 3, true, 2400, ARRAY['Up to 16 SEER','Single-stage','Lennox-built quality'], '{"seer": 16, "seer2": 15.2, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single", "compressor": "scroll"}'),
  ('2AC16L48P', '2AC16L 4-Ton AC', '2AC16L', 4, true, 2800, ARRAY['Up to 16 SEER','Single-stage','Corrosion-resistant coil'], '{"seer": 16, "seer2": 15.2, "tons": 4, "voltage": 208, "refrigerant": "R-410A", "stages": "single", "compressor": "scroll"}'),
  ('2AC14L36P', '2AC14L 3-Ton AC', '2AC14L', 3, false, 1800, ARRAY['Up to 14.3 SEER2','Single-stage','Entry-level'], '{"seer2": 14.3, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}'),
  ('2AC16L24P', '2AC16L 2-Ton AC', '2AC16L', 2, true, 2000, ARRAY['Up to 16 SEER','Single-stage','Compact design'], '{"seer": 16, "seer2": 15.2, "tons": 2, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}')
) AS v(model_number, model_name, series, cap, estar, msrp, features, specs)
WHERE m.slug = 'ducane' AND c.slug = 'hvac-central-ac';

-- Ducane Furnaces
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'gas', 'split-system', NULL, v.cap, 'btu', true, 20, false, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.ducane.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('2MG1E080B16S1', '2MG1 80K BTU 96% Furnace', '2MG1', 80000, true, 2200, ARRAY['96% AFUE','Single-stage','Variable-speed blower','Lennox-built'], '{"afue": 96, "btu": 80000, "voltage": 120, "stages": "single", "blower": "variable-speed"}'),
  ('2MG1E100C20S1', '2MG1 100K BTU 96% Furnace', '2MG1', 100000, true, 2500, ARRAY['96% AFUE','Single-stage','Variable-speed blower'], '{"afue": 96, "btu": 100000, "voltage": 120, "stages": "single", "blower": "variable-speed"}'),
  ('2MS1E080B12S1', '2MS1 80K BTU 80% Furnace', '2MS1', 80000, false, 1200, ARRAY['80% AFUE','Single-stage','Multi-speed blower','Budget'], '{"afue": 80, "btu": 80000, "voltage": 120, "stages": "single", "blower": "multi-speed"}'),
  ('2MG1E060B12S1', '2MG1 60K BTU 96% Furnace', '2MG1', 60000, true, 1900, ARRAY['96% AFUE','Single-stage','Compact cabinet'], '{"afue": 96, "btu": 60000, "voltage": 120, "stages": "single", "blower": "variable-speed"}')
) AS v(model_number, model_name, series, cap, estar, msrp, features, specs)
WHERE m.slug = 'ducane' AND c.slug = 'hvac-furnace';

-- Ducane Heat Pumps
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'split-system', NULL, v.cap, 'tons', true, 15, false, true, v.msrp, v.features, v.specs::jsonb, 'https://www.ducane.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('2HP16L36P', '2HP16L 3-Ton Heat Pump', '2HP16L', 3, 2800, ARRAY['Up to 16 SEER','Single-stage','Heating and cooling'], '{"seer": 16, "hspf": 9.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}'),
  ('2HP16L48P', '2HP16L 4-Ton Heat Pump', '2HP16L', 4, 3200, ARRAY['Up to 16 SEER','Single-stage','Large capacity'], '{"seer": 16, "hspf": 9.0, "tons": 4, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}')
) AS v(model_number, model_name, series, cap, msrp, features, specs)
WHERE m.slug = 'ducane' AND c.slug = 'hvac-heat-pump';

-- ======================== MAINSTREAM BRANDS ========================

-- -------------------- RHEEM --------------------

-- Rheem Central AC
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'split-system', NULL, v.cap, 'tons', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.rheem.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('RA20AZ036', 'Prestige RA20AZ 3-Ton AC', 'Prestige', 3, 15, true, true, 5200, ARRAY['Up to 20 SEER','Variable-speed inverter','EcoNet enabled','Ultra-quiet 55 dB'], '{"seer": 20, "seer2": 19.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter"}'),
  ('RA20AZ048', 'Prestige RA20AZ 4-Ton AC', 'Prestige', 4, 15, true, true, 5800, ARRAY['Up to 20 SEER','Variable-speed inverter','EcoNet smart connectivity'], '{"seer": 20, "seer2": 19.0, "tons": 4, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter"}'),
  ('RA17AZ036', 'Classic Plus RA17AZ 3-Ton AC', 'Classic Plus', 3, 15, true, true, 3800, ARRAY['Up to 17 SEER','Two-stage compressor','Sound: 69 dB'], '{"seer": 17, "seer2": 16.2, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage", "compressor": "scroll"}'),
  ('RA17AZ048', 'Classic Plus RA17AZ 4-Ton AC', 'Classic Plus', 4, 15, true, true, 4200, ARRAY['Up to 17 SEER','Two-stage compressor','WeatherShield protection'], '{"seer": 17, "seer2": 16.2, "tons": 4, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage", "compressor": "scroll"}'),
  ('RA16AZ036', 'Classic RA16AZ 3-Ton AC', 'Classic', 3, 15, false, true, 2800, ARRAY['Up to 16 SEER','Single-stage','Scroll compressor'], '{"seer": 16, "seer2": 15.2, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single", "compressor": "scroll"}'),
  ('RA16AZ048', 'Classic RA16AZ 4-Ton AC', 'Classic', 4, 15, false, true, 3200, ARRAY['Up to 16 SEER','Single-stage','Quiet operation'], '{"seer": 16, "seer2": 15.2, "tons": 4, "voltage": 208, "refrigerant": "R-410A", "stages": "single", "compressor": "scroll"}'),
  ('RA14AZ024', 'Classic RA14AZ 2-Ton AC', 'Classic', 2, 15, false, false, 2000, ARRAY['Up to 14.3 SEER2','Single-stage','Entry-level'], '{"seer2": 14.3, "tons": 2, "voltage": 208, "refrigerant": "R-410A", "stages": "single", "compressor": "scroll"}'),
  ('RA14AZ036', 'Classic RA14AZ 3-Ton AC', 'Classic', 3, 15, false, false, 2300, ARRAY['Up to 14.3 SEER2','Single-stage','Reliable operation'], '{"seer2": 14.3, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single", "compressor": "scroll"}')
) AS v(model_number, model_name, series, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'rheem' AND c.slug = 'hvac-central-ac';

-- Rheem Furnaces
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'gas', 'split-system', NULL, v.cap, 'btu', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.rheem.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('R97VA080521MSA', 'Prestige R97V 80K BTU', 'Prestige', 80000, 20, true, true, 3800, ARRAY['97% AFUE','Modulating gas valve','Variable-speed ECM blower','EcoNet enabled'], '{"afue": 97, "btu": 80000, "voltage": 120, "stages": "modulating", "blower": "variable-speed"}'),
  ('R97VA100521MSA', 'Prestige R97V 100K BTU', 'Prestige', 100000, 20, true, true, 4200, ARRAY['97% AFUE','Modulating gas valve','Variable-speed blower','EcoNet WiFi'], '{"afue": 97, "btu": 100000, "voltage": 120, "stages": "modulating", "blower": "variable-speed"}'),
  ('R96VA080521MSA', 'Classic Plus R96V 80K BTU', 'Classic Plus', 80000, 20, true, true, 3000, ARRAY['96% AFUE','Two-stage gas valve','Variable-speed blower'], '{"afue": 96, "btu": 80000, "voltage": 120, "stages": "two-stage", "blower": "variable-speed"}'),
  ('R96VA100521MSA', 'Classic Plus R96V 100K BTU', 'Classic Plus', 100000, 20, true, true, 3400, ARRAY['96% AFUE','Two-stage gas valve','Variable-speed blower'], '{"afue": 96, "btu": 100000, "voltage": 120, "stages": "two-stage", "blower": "variable-speed"}'),
  ('R95T0801521MSA', 'Classic R95T 80K BTU', 'Classic', 80000, 20, false, true, 2200, ARRAY['95% AFUE','Single-stage','Multi-speed blower','Budget-friendly'], '{"afue": 95, "btu": 80000, "voltage": 120, "stages": "single", "blower": "multi-speed"}'),
  ('R801T0804521MSA', 'Classic R801T 80K BTU', 'Classic', 80000, 20, false, false, 1400, ARRAY['80% AFUE','Single-stage','Non-condensing'], '{"afue": 80, "btu": 80000, "voltage": 120, "stages": "single", "blower": "multi-speed"}')
) AS v(model_number, model_name, series, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'rheem' AND c.slug = 'hvac-furnace';

-- Rheem Heat Pumps
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'split-system', NULL, v.cap, 'tons', true, 15, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.rheem.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('RP20AZ036', 'Prestige RP20AZ 3-Ton Heat Pump', 'Prestige', 3, true, true, 5800, ARRAY['Up to 20 SEER','Variable-speed inverter','EcoNet enabled','Heating to -22F'], '{"seer": 20, "hspf": 11.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter"}'),
  ('RP17AZ036', 'Classic Plus RP17AZ 3-Ton HP', 'Classic Plus', 3, true, true, 4200, ARRAY['Up to 17 SEER','Two-stage compressor','Heating and cooling'], '{"seer": 17, "hspf": 9.5, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage"}'),
  ('RP16AZ036', 'Classic RP16AZ 3-Ton HP', 'Classic', 3, false, true, 3200, ARRAY['Up to 16 SEER','Single-stage','Scroll compressor'], '{"seer": 16, "hspf": 9.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}'),
  ('RP14AZ036', 'Classic RP14AZ 3-Ton HP', 'Classic', 3, false, false, 2600, ARRAY['Up to 14.3 SEER2','Single-stage','Entry-level heat pump'], '{"seer2": 14.3, "hspf2": 7.5, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}')
) AS v(model_number, model_name, series, cap, wifi, estar, msrp, features, specs)
WHERE m.slug = 'rheem' AND c.slug = 'hvac-heat-pump';

-- -------------------- RUUD --------------------

-- Ruud Central AC
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'split-system', NULL, v.cap, 'tons', true, 15, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.ruud.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('UA20AZ036', 'Endeavor UA20AZ 3-Ton AC', 'Endeavor', 3, true, true, 5200, ARRAY['Up to 20 SEER','Variable-speed inverter','EcoNet enabled'], '{"seer": 20, "seer2": 19.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter"}'),
  ('UA17AZ036', 'Achiever Plus UA17AZ 3-Ton AC', 'Achiever Plus', 3, true, true, 3800, ARRAY['Up to 17 SEER','Two-stage compressor','Sound: 69 dB'], '{"seer": 17, "seer2": 16.2, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage", "compressor": "scroll"}'),
  ('UA16AZ036', 'Achiever UA16AZ 3-Ton AC', 'Achiever', 3, false, true, 2800, ARRAY['Up to 16 SEER','Single-stage','Scroll compressor'], '{"seer": 16, "seer2": 15.2, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single", "compressor": "scroll"}'),
  ('UA14AZ036', 'Achiever UA14AZ 3-Ton AC', 'Achiever', 3, false, false, 2300, ARRAY['Up to 14.3 SEER2','Single-stage','Entry-level'], '{"seer2": 14.3, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}')
) AS v(model_number, model_name, series, cap, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ruud' AND c.slug = 'hvac-central-ac';

-- Ruud Furnaces
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'gas', 'split-system', NULL, v.cap, 'btu', true, 20, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.ruud.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('U97VA080521MSA', 'Endeavor U97V 80K BTU', 'Endeavor', 80000, true, true, 3800, ARRAY['97% AFUE','Modulating gas valve','Variable-speed ECM','EcoNet enabled'], '{"afue": 97, "btu": 80000, "voltage": 120, "stages": "modulating", "blower": "variable-speed"}'),
  ('U96VA080521MSA', 'Achiever Plus U96V 80K BTU', 'Achiever Plus', 80000, true, true, 3000, ARRAY['96% AFUE','Two-stage','Variable-speed blower'], '{"afue": 96, "btu": 80000, "voltage": 120, "stages": "two-stage", "blower": "variable-speed"}'),
  ('U95T0801521MSA', 'Achiever U95T 80K BTU', 'Achiever', 80000, false, true, 2200, ARRAY['95% AFUE','Single-stage','Multi-speed blower'], '{"afue": 95, "btu": 80000, "voltage": 120, "stages": "single", "blower": "multi-speed"}'),
  ('U801T0804521MSA', 'Achiever U801T 80K BTU', 'Achiever', 80000, false, false, 1400, ARRAY['80% AFUE','Single-stage','Non-condensing'], '{"afue": 80, "btu": 80000, "voltage": 120, "stages": "single", "blower": "multi-speed"}')
) AS v(model_number, model_name, series, cap, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ruud' AND c.slug = 'hvac-furnace';

-- -------------------- YORK --------------------

-- York Central AC
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'split-system', NULL, v.cap, 'tons', true, 15, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.york.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DERA036S', 'YXV 3-Ton AC', 'YXV', 3, true, true, 5500, ARRAY['Up to 21 SEER','Variable-speed inverter','Quiet Drive sound insulation','Hx3 communicating'], '{"seer": 21, "seer2": 20.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter"}'),
  ('DERA048S', 'YXV 4-Ton AC', 'YXV', 4, true, true, 6000, ARRAY['Up to 20 SEER','Variable-speed inverter','Quiet Drive system'], '{"seer": 20, "seer2": 19.0, "tons": 4, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter"}'),
  ('DCRA036S', 'YZF 3-Ton AC', 'YZF', 3, true, true, 3800, ARRAY['Up to 18 SEER','Two-stage compressor','ClimaTrak communicating'], '{"seer": 18, "seer2": 17.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage", "compressor": "scroll"}'),
  ('DCRA048S', 'YZF 4-Ton AC', 'YZF', 4, true, true, 4200, ARRAY['Up to 17 SEER','Two-stage compressor','Sound: 72 dB'], '{"seer": 17, "seer2": 16.2, "tons": 4, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage", "compressor": "scroll"}'),
  ('TCGD36S41S3', 'YFE 3-Ton AC', 'YFE', 3, false, true, 2800, ARRAY['Up to 16 SEER','Single-stage','Scroll compressor'], '{"seer": 16, "seer2": 15.2, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single", "compressor": "scroll"}'),
  ('TCGD36S21S1', 'YCD 3-Ton AC', 'YCD', 3, false, false, 2200, ARRAY['Up to 14.3 SEER2','Single-stage','Entry-level'], '{"seer2": 14.3, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}')
) AS v(model_number, model_name, series, cap, wifi, estar, msrp, features, specs)
WHERE m.slug = 'york' AND c.slug = 'hvac-central-ac';

-- York Furnaces
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'gas', 'split-system', NULL, v.cap, 'btu', true, 20, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.york.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('TM9V080B12MP11', 'YP9C 80K BTU Modulating', 'YP9C', 80000, true, true, 4200, ARRAY['98% AFUE','Modulating gas valve','Variable-speed ECM','Hx3 communicating'], '{"afue": 98, "btu": 80000, "voltage": 120, "stages": "modulating", "blower": "variable-speed"}'),
  ('TM9V100C16MP11', 'YP9C 100K BTU Modulating', 'YP9C', 100000, true, true, 4600, ARRAY['98% AFUE','Modulating gas valve','Variable-speed blower'], '{"afue": 98, "btu": 100000, "voltage": 120, "stages": "modulating", "blower": "variable-speed"}'),
  ('TM9T080B12MP11', 'TM9T 80K BTU Two-Stage', 'TM9T', 80000, true, true, 3200, ARRAY['96% AFUE','Two-stage gas valve','Variable-speed blower'], '{"afue": 96, "btu": 80000, "voltage": 120, "stages": "two-stage", "blower": "variable-speed"}'),
  ('TM9T100C20MP11', 'TM9T 100K BTU Two-Stage', 'TM9T', 100000, true, true, 3600, ARRAY['96% AFUE','Two-stage gas valve','Variable-speed blower'], '{"afue": 96, "btu": 100000, "voltage": 120, "stages": "two-stage", "blower": "variable-speed"}'),
  ('TM9E080B12MP11', 'TM9E 80K BTU Single-Stage', 'TM9E', 80000, false, true, 2000, ARRAY['95% AFUE','Single-stage','Multi-speed blower'], '{"afue": 95, "btu": 80000, "voltage": 120, "stages": "single", "blower": "multi-speed"}'),
  ('TM8E080B12MP11', 'TM8E 80K BTU 80% Furnace', 'TM8E', 80000, false, false, 1400, ARRAY['80% AFUE','Single-stage','Non-condensing','Entry-level'], '{"afue": 80, "btu": 80000, "voltage": 120, "stages": "single", "blower": "multi-speed"}')
) AS v(model_number, model_name, series, cap, wifi, estar, msrp, features, specs)
WHERE m.slug = 'york' AND c.slug = 'hvac-furnace';

-- York Heat Pumps
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'split-system', NULL, v.cap, 'tons', true, 15, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.york.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DERP036S', 'YXV 3-Ton Heat Pump', 'YXV', 3, true, true, 6000, ARRAY['Up to 20 SEER','Variable-speed inverter','Quiet Drive system','Hx3 communicating'], '{"seer": 20, "hspf": 11.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter"}'),
  ('DCRP036S', 'YZH 3-Ton Heat Pump', 'YZH', 3, true, true, 4200, ARRAY['Up to 18 SEER','Two-stage compressor','ClimaTrak communicating'], '{"seer": 18, "hspf": 9.5, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage"}'),
  ('TCHD36S41S3', 'YFH 3-Ton Heat Pump', 'YFH', 3, false, true, 3200, ARRAY['Up to 16 SEER','Single-stage','Scroll compressor'], '{"seer": 16, "hspf": 9.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}')
) AS v(model_number, model_name, series, cap, wifi, estar, msrp, features, specs)
WHERE m.slug = 'york' AND c.slug = 'hvac-heat-pump';

-- -------------------- HEIL --------------------

-- Heil Central AC
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'split-system', NULL, v.cap, 'tons', true, 15, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.heil-hvac.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('HVA936GKA', 'QuietComfort Deluxe 19 3-Ton', 'QuietComfort Deluxe', 3, true, true, 4200, ARRAY['Up to 19 SEER','Two-stage compressor','Observer communicating'], '{"seer": 19, "seer2": 18.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage", "compressor": "scroll"}'),
  ('HVA736GKA', 'QuietComfort 17 3-Ton', 'QuietComfort', 3, false, true, 3200, ARRAY['Up to 17 SEER','Two-stage compressor','Sound: 72 dB'], '{"seer": 17, "seer2": 16.2, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage", "compressor": "scroll"}'),
  ('HCA636GKA', 'QuietComfort 16 3-Ton', 'QuietComfort', 3, false, true, 2600, ARRAY['Up to 16 SEER','Single-stage','Scroll compressor'], '{"seer": 16, "seer2": 15.2, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}'),
  ('HSA636GKA', 'Performance 14 3-Ton', 'Performance', 3, false, false, 2000, ARRAY['Up to 14.3 SEER2','Single-stage','Entry-level'], '{"seer2": 14.3, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}')
) AS v(model_number, model_name, series, cap, wifi, estar, msrp, features, specs)
WHERE m.slug = 'heil' AND c.slug = 'hvac-central-ac';

-- Heil Furnaces
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'gas', 'split-system', NULL, v.cap, 'btu', true, 20, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.heil-hvac.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('HG9MVE080B12A', 'QuietComfort Deluxe 98 80K', 'QuietComfort Deluxe', 80000, true, true, 3800, ARRAY['98% AFUE','Modulating gas valve','Variable-speed ECM','Observer communicating'], '{"afue": 98, "btu": 80000, "voltage": 120, "stages": "modulating", "blower": "variable-speed"}'),
  ('H9MVE080B12A', 'QuietComfort 96 80K', 'QuietComfort', 80000, true, true, 3000, ARRAY['96% AFUE','Two-stage gas valve','Variable-speed blower'], '{"afue": 96, "btu": 80000, "voltage": 120, "stages": "two-stage", "blower": "variable-speed"}'),
  ('H8MPN080B12A', 'Performance 80 80K', 'Performance', 80000, false, false, 1400, ARRAY['80% AFUE','Single-stage','Multi-speed blower','Entry-level'], '{"afue": 80, "btu": 80000, "voltage": 120, "stages": "single", "blower": "multi-speed"}')
) AS v(model_number, model_name, series, cap, wifi, estar, msrp, features, specs)
WHERE m.slug = 'heil' AND c.slug = 'hvac-furnace';

-- -------------------- COLEMAN --------------------

-- Coleman Central AC
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'split-system', NULL, v.cap, 'tons', true, 15, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.colemanac.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DERA036S', 'Echelon 3-Ton AC', 'Echelon', 3, true, true, 5200, ARRAY['Up to 20 SEER','Variable-speed inverter','Quiet Drive system'], '{"seer": 20, "seer2": 19.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter"}'),
  ('DCRA036S', 'LX 3-Ton AC', 'LX', 3, true, true, 3600, ARRAY['Up to 17 SEER','Two-stage compressor','ClimaTrak system'], '{"seer": 17, "seer2": 16.2, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage"}'),
  ('TCGD36S41S3', 'LX 16 3-Ton AC', 'LX', 3, false, true, 2600, ARRAY['Up to 16 SEER','Single-stage','Scroll compressor'], '{"seer": 16, "seer2": 15.2, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}'),
  ('TCGD36S21S1', 'TC 3-Ton AC', 'TC', 3, false, false, 2000, ARRAY['Up to 14.3 SEER2','Single-stage','Entry-level'], '{"seer2": 14.3, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}')
) AS v(model_number, model_name, series, cap, wifi, estar, msrp, features, specs)
WHERE m.slug = 'coleman-hvac' AND c.slug = 'hvac-central-ac';

-- Coleman Furnaces
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'gas', 'split-system', NULL, v.cap, 'btu', true, 20, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.colemanac.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('TM9V080B12MP11', 'Echelon 98 80K BTU', 'Echelon', 80000, true, true, 4000, ARRAY['98% AFUE','Modulating gas valve','Variable-speed ECM','Hx3 communicating'], '{"afue": 98, "btu": 80000, "voltage": 120, "stages": "modulating", "blower": "variable-speed"}'),
  ('TM9T080B12MP11', 'LX 96 80K BTU', 'LX', 80000, true, true, 3000, ARRAY['96% AFUE','Two-stage gas valve','Variable-speed blower'], '{"afue": 96, "btu": 80000, "voltage": 120, "stages": "two-stage", "blower": "variable-speed"}'),
  ('TM9E080B12MP11', 'LX 95 80K BTU', 'LX', 80000, false, true, 2000, ARRAY['95% AFUE','Single-stage','Multi-speed blower'], '{"afue": 95, "btu": 80000, "voltage": 120, "stages": "single", "blower": "multi-speed"}'),
  ('TM8E080B12MP11', 'TC 80 80K BTU', 'TC', 80000, false, false, 1300, ARRAY['80% AFUE','Single-stage','Non-condensing'], '{"afue": 80, "btu": 80000, "voltage": 120, "stages": "single", "blower": "multi-speed"}')
) AS v(model_number, model_name, series, cap, wifi, estar, msrp, features, specs)
WHERE m.slug = 'coleman-hvac' AND c.slug = 'hvac-furnace';

-- ======================== PREMIUM BRANDS ========================

-- -------------------- CARRIER --------------------

-- Carrier Central AC
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'split-system', NULL, v.cap, 'tons', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.carrier.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('24ACC636A003', 'Infinity 26 3-Ton AC', 'Infinity 26', 3, 15, true, true, 7500, ARRAY['Up to 26 SEER','Variable-speed inverter','Greenspeed Intelligence','Sound: 51 dB'], '{"seer": 26, "seer2": 24.5, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter"}'),
  ('24ACC648A003', 'Infinity 26 4-Ton AC', 'Infinity 26', 4, 15, true, true, 8200, ARRAY['Up to 24 SEER','Variable-speed inverter','Greenspeed Intelligence'], '{"seer": 24, "seer2": 22.5, "tons": 4, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter"}'),
  ('24ACC624A003', 'Infinity 26 2-Ton AC', 'Infinity 26', 2, 15, true, true, 6800, ARRAY['Up to 26 SEER','Variable-speed inverter','Ultra-quiet operation'], '{"seer": 26, "seer2": 24.5, "tons": 2, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter"}'),
  ('24ANB136A003', 'Infinity 21 3-Ton AC', 'Infinity 21', 3, 15, true, true, 5800, ARRAY['Up to 21 SEER','Two-stage compressor','Infinity communicating'], '{"seer": 21, "seer2": 19.5, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage", "compressor": "scroll"}'),
  ('24ANB148A003', 'Infinity 21 4-Ton AC', 'Infinity 21', 4, 15, true, true, 6200, ARRAY['Up to 21 SEER','Two-stage compressor','Sound: 65 dB'], '{"seer": 21, "seer2": 19.5, "tons": 4, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage", "compressor": "scroll"}'),
  ('24SPA536A003', 'Performance 17 3-Ton AC', 'Performance', 3, 15, true, true, 4200, ARRAY['Up to 17 SEER','Two-stage compressor','Silencer System II'], '{"seer": 17, "seer2": 16.2, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage", "compressor": "scroll"}'),
  ('24SCA636A003', 'Performance 16 3-Ton AC', 'Performance', 3, 15, false, true, 3200, ARRAY['Up to 16 SEER','Single-stage','Scroll compressor'], '{"seer": 16, "seer2": 15.2, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single", "compressor": "scroll"}'),
  ('24SCA648A003', 'Performance 16 4-Ton AC', 'Performance', 4, 15, false, true, 3600, ARRAY['Up to 16 SEER','Single-stage','WeatherArmor protection'], '{"seer": 16, "seer2": 15.2, "tons": 4, "voltage": 208, "refrigerant": "R-410A", "stages": "single", "compressor": "scroll"}'),
  ('24ACC536A003', 'Comfort 15 3-Ton AC', 'Comfort', 3, 15, false, false, 2400, ARRAY['Up to 15.2 SEER2','Single-stage','Entry-level Carrier'], '{"seer2": 15.2, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}'),
  ('24SCA524A003', 'Comfort 14 2-Ton AC', 'Comfort', 2, 15, false, false, 2000, ARRAY['Up to 14.3 SEER2','Single-stage','Compact footprint'], '{"seer2": 14.3, "tons": 2, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}')
) AS v(model_number, model_name, series, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'carrier' AND c.slug = 'hvac-central-ac';

-- Carrier Furnaces
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'gas', 'split-system', NULL, v.cap, 'btu', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.carrier.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('59MN7A080V21-20', 'Infinity 98 80K BTU', 'Infinity 98', 80000, 20, true, true, 5200, ARRAY['98.5% AFUE','Modulating gas valve','Variable-speed ECM','Greenspeed Intelligence'], '{"afue": 98.5, "btu": 80000, "voltage": 120, "stages": "modulating", "blower": "variable-speed"}'),
  ('59MN7A100V21-20', 'Infinity 98 100K BTU', 'Infinity 98', 100000, 20, true, true, 5800, ARRAY['98.5% AFUE','Modulating gas valve','Variable-speed blower','WiFi enabled'], '{"afue": 98.5, "btu": 100000, "voltage": 120, "stages": "modulating", "blower": "variable-speed"}'),
  ('59TN6A080V21-14', 'Infinity 96 80K BTU', 'Infinity 96', 80000, 20, true, true, 4200, ARRAY['96.7% AFUE','Two-stage gas valve','Variable-speed blower','Infinity communicating'], '{"afue": 96.7, "btu": 80000, "voltage": 120, "stages": "two-stage", "blower": "variable-speed"}'),
  ('59SP5A080E21-14', 'Performance 96 80K BTU', 'Performance', 80000, 20, true, true, 3200, ARRAY['96% AFUE','Two-stage','Variable-speed ECM blower'], '{"afue": 96, "btu": 80000, "voltage": 120, "stages": "two-stage", "blower": "variable-speed"}'),
  ('59SC5A080S21-14', 'Performance 80 80K BTU', 'Performance', 80000, 20, false, false, 2000, ARRAY['80% AFUE','Single-stage','Multi-speed blower'], '{"afue": 80, "btu": 80000, "voltage": 120, "stages": "single", "blower": "multi-speed"}'),
  ('59SC5A100S21-16', 'Performance 80 100K BTU', 'Performance', 100000, 20, false, false, 2300, ARRAY['80% AFUE','Single-stage','Non-condensing'], '{"afue": 80, "btu": 100000, "voltage": 120, "stages": "single", "blower": "multi-speed"}')
) AS v(model_number, model_name, series, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'carrier' AND c.slug = 'hvac-furnace';

-- Carrier Heat Pumps
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'split-system', NULL, v.cap, 'tons', true, 15, v.wifi, true, v.msrp, v.features, v.specs::jsonb, 'https://www.carrier.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('25VNA036A003', 'Infinity 24 3-Ton HP', 'Infinity 24', 'electric', 3, true, 8000, ARRAY['Up to 24 SEER','Variable-speed inverter','Greenspeed Intelligence','Heating to -15F'], '{"seer": 24, "hspf": 13.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter"}'),
  ('25VNA048A003', 'Infinity 24 4-Ton HP', 'Infinity 24', 'electric', 4, true, 8800, ARRAY['Up to 22 SEER','Variable-speed inverter','Greenspeed Intelligence'], '{"seer": 22, "hspf": 12.0, "tons": 4, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter"}'),
  ('25HNB636A003', 'Infinity 19 3-Ton HP', 'Infinity', 'electric', 3, true, 5800, ARRAY['Up to 19 SEER','Two-stage compressor','Infinity communicating'], '{"seer": 19, "hspf": 10.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage"}'),
  ('25SPB636A003', 'Performance 17 3-Ton HP', 'Performance', 'electric', 3, true, 4200, ARRAY['Up to 17 SEER','Two-stage compressor','Silencer System II'], '{"seer": 17, "hspf": 9.5, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage"}'),
  ('25HCB636A003', 'Performance 16 3-Ton HP', 'Performance', 'electric', 3, false, 3200, ARRAY['Up to 16 SEER','Single-stage','Scroll compressor'], '{"seer": 16, "hspf": 9.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}'),
  ('25HCE636A003', 'Comfort 15 3-Ton HP', 'Comfort', 'electric', 3, false, 2600, ARRAY['Up to 15.2 SEER2','Single-stage','Entry-level'], '{"seer2": 15.2, "hspf2": 7.8, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}')
) AS v(model_number, model_name, series, fuel, cap, wifi, msrp, features, specs)
WHERE m.slug = 'carrier' AND c.slug = 'hvac-heat-pump';

-- -------------------- TRANE --------------------

-- Trane Central AC
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'split-system', NULL, v.cap, 'tons', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.trane.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('4TTV8036A1000B', 'XV20i 3-Ton AC', 'XV20i', 3, 15, true, true, 7800, ARRAY['Up to 22 SEER','Variable-speed inverter','TruComfort variable speed','Quiet: 55 dB'], '{"seer": 22, "seer2": 20.5, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter"}'),
  ('4TTV8048A1000B', 'XV20i 4-Ton AC', 'XV20i', 4, 15, true, true, 8400, ARRAY['Up to 21 SEER','Variable-speed inverter','TruComfort technology'], '{"seer": 21, "seer2": 19.5, "tons": 4, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter"}'),
  ('4TTR8036A1000A', 'XV18 3-Ton AC', 'XV18', 3, 15, true, true, 5800, ARRAY['Up to 18 SEER','Two-stage Climatuff compressor','Spine Fin coil'], '{"seer": 18, "seer2": 17.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage", "compressor": "scroll"}'),
  ('4TTR6036J1000AA', 'XR17 3-Ton AC', 'XR17', 3, 15, true, true, 4500, ARRAY['Up to 18 SEER','Two-stage compressor','Climatuff compressor'], '{"seer": 18, "seer2": 16.5, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage", "compressor": "scroll"}'),
  ('4TTR6048J1000AA', 'XR17 4-Ton AC', 'XR17', 4, 15, true, true, 5000, ARRAY['Up to 17 SEER','Two-stage compressor','Spine Fin coil'], '{"seer": 17, "seer2": 16.0, "tons": 4, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage", "compressor": "scroll"}'),
  ('4TTR5036E1000A', 'XR16 3-Ton AC', 'XR16', 3, 15, false, true, 3500, ARRAY['Up to 17 SEER','Single-stage','Climatuff scroll compressor'], '{"seer": 17, "seer2": 15.5, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single", "compressor": "scroll"}'),
  ('4TTR5036E1000B', 'XR15 3-Ton AC', 'XR15', 3, 15, false, true, 2800, ARRAY['Up to 16 SEER','Single-stage','Spine Fin outdoor coil'], '{"seer": 16, "seer2": 15.2, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single", "compressor": "scroll"}'),
  ('4TTR4036L1000A', 'XR14 3-Ton AC', 'XR14', 3, 15, false, false, 2200, ARRAY['Up to 15 SEER','Single-stage','Reliable Climatuff'], '{"seer": 15, "seer2": 14.3, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single", "compressor": "scroll"}'),
  ('4TTR4024L1000A', 'XR14 2-Ton AC', 'XR14', 2, 15, false, false, 1800, ARRAY['Up to 15 SEER','Single-stage','Compact design'], '{"seer": 15, "seer2": 14.3, "tons": 2, "voltage": 208, "refrigerant": "R-410A", "stages": "single", "compressor": "scroll"}'),
  ('4TTR4048L1000A', 'XR14 4-Ton AC', 'XR14', 4, 15, false, false, 2600, ARRAY['Up to 14.3 SEER2','Single-stage','Large capacity'], '{"seer2": 14.3, "tons": 4, "voltage": 208, "refrigerant": "R-410A", "stages": "single", "compressor": "scroll"}')
) AS v(model_number, model_name, series, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'trane' AND c.slug = 'hvac-central-ac';

-- Trane Furnaces
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'gas', 'split-system', NULL, v.cap, 'btu', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.trane.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('S9V2B080U5PSB', 'XV95 80K BTU', 'XV95', 80000, 20, true, true, 5500, ARRAY['Up to 97.3% AFUE','Modulating gas valve','Variable-speed ECM','ComfortLink II communicating'], '{"afue": 97.3, "btu": 80000, "voltage": 120, "stages": "modulating", "blower": "variable-speed"}'),
  ('S9V2C100U5PSB', 'XV95 100K BTU', 'XV95', 100000, 20, true, true, 6000, ARRAY['Up to 97.3% AFUE','Modulating gas valve','Variable-speed blower'], '{"afue": 97.3, "btu": 100000, "voltage": 120, "stages": "modulating", "blower": "variable-speed"}'),
  ('S9V2B060U3PSB', 'XV95 60K BTU', 'XV95', 60000, 20, true, true, 5000, ARRAY['Up to 97.3% AFUE','Modulating gas valve','Compact cabinet'], '{"afue": 97.3, "btu": 60000, "voltage": 120, "stages": "modulating", "blower": "variable-speed"}'),
  ('S9X2B080U5PSA', 'XR95 80K BTU', 'XR95', 80000, 20, true, true, 3800, ARRAY['96% AFUE','Two-stage gas valve','Variable-speed blower'], '{"afue": 96, "btu": 80000, "voltage": 120, "stages": "two-stage", "blower": "variable-speed"}'),
  ('S9X2C100U5PSA', 'XR95 100K BTU', 'XR95', 100000, 20, true, true, 4200, ARRAY['96% AFUE','Two-stage gas valve','Variable-speed ECM'], '{"afue": 96, "btu": 100000, "voltage": 120, "stages": "two-stage", "blower": "variable-speed"}'),
  ('S8X1B080M3PSA', 'XR80 80K BTU', 'XR80', 80000, 20, false, false, 1800, ARRAY['80% AFUE','Single-stage','Multi-speed blower'], '{"afue": 80, "btu": 80000, "voltage": 120, "stages": "single", "blower": "multi-speed"}'),
  ('S8X1C100M5PSA', 'XR80 100K BTU', 'XR80', 100000, 20, false, false, 2100, ARRAY['80% AFUE','Single-stage','Non-condensing'], '{"afue": 80, "btu": 100000, "voltage": 120, "stages": "single", "blower": "multi-speed"}'),
  ('S9X1B060M3PSA', 'S9X1 60K BTU', 'S9X1', 60000, 20, false, true, 2400, ARRAY['95% AFUE','Single-stage','Multi-speed blower','Condensing'], '{"afue": 95, "btu": 60000, "voltage": 120, "stages": "single", "blower": "multi-speed"}')
) AS v(model_number, model_name, series, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'trane' AND c.slug = 'hvac-furnace';

-- Trane Heat Pumps
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'split-system', NULL, v.cap, 'tons', true, 15, v.wifi, true, v.msrp, v.features, v.specs::jsonb, 'https://www.trane.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('4TWV8036A1000B', 'XV20i 3-Ton HP', 'XV20i', 3, true, 8200, ARRAY['Up to 20 SEER','Variable-speed inverter','TruComfort','Heating to -22F','Quiet: 55 dB'], '{"seer": 20, "hspf": 13.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter"}'),
  ('4TWR8036A1000A', 'XV18 3-Ton HP', 'XV18', 3, true, 6200, ARRAY['Up to 18.5 SEER','Two-stage Climatuff','Spine Fin coil'], '{"seer": 18.5, "hspf": 10.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage"}'),
  ('4TWR6036J1000AA', 'XR17 3-Ton HP', 'XR17', 3, true, 4800, ARRAY['Up to 17.5 SEER','Two-stage compressor','Climatuff compressor'], '{"seer": 17.5, "hspf": 9.8, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage"}'),
  ('4TWR5036E1000A', 'XR16 3-Ton HP', 'XR16', 3, false, 3800, ARRAY['Up to 16 SEER','Single-stage','Climatuff scroll'], '{"seer": 16, "hspf": 9.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}'),
  ('4TWR4036L1000A', 'XR14 3-Ton HP', 'XR14', 3, false, 2800, ARRAY['Up to 14.3 SEER2','Single-stage','Entry-level heat pump'], '{"seer2": 14.3, "hspf2": 7.5, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}')
) AS v(model_number, model_name, series, cap, wifi, msrp, features, specs)
WHERE m.slug = 'trane' AND c.slug = 'hvac-heat-pump';

-- -------------------- AMERICAN STANDARD --------------------

-- American Standard Central AC
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'split-system', NULL, v.cap, 'tons', true, 15, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.americanstandardair.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('4A7V8036A1000B', 'AccuComfort Platinum 20 3T', 'Platinum 20', 3, true, true, 7500, ARRAY['Up to 22 SEER','Variable-speed inverter','AccuComfort variable speed','Ultra-quiet'], '{"seer": 22, "seer2": 20.5, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter"}'),
  ('4A7V8048A1000B', 'AccuComfort Platinum 20 4T', 'Platinum 20', 4, true, true, 8100, ARRAY['Up to 21 SEER','Variable-speed inverter','AccuComfort technology'], '{"seer": 21, "seer2": 19.5, "tons": 4, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter"}'),
  ('4A7A8036A1000A', 'Gold 18 3-Ton AC', 'Gold 18', 3, true, true, 5600, ARRAY['Up to 18 SEER','Two-stage compressor','Climatuff compressor'], '{"seer": 18, "seer2": 17.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage", "compressor": "scroll"}'),
  ('4A7A6036J1000AA', 'Gold 17 3-Ton AC', 'Gold 17', 3, true, true, 4400, ARRAY['Up to 17 SEER','Two-stage compressor','Spine Fin coil'], '{"seer": 17, "seer2": 16.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage", "compressor": "scroll"}'),
  ('4A6S5036E1000A', 'Silver 16 3-Ton AC', 'Silver 16', 3, false, true, 3400, ARRAY['Up to 17 SEER','Single-stage','Scroll compressor'], '{"seer": 17, "seer2": 15.5, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single", "compressor": "scroll"}'),
  ('4A6S4036L1000A', 'Silver 14 3-Ton AC', 'Silver 14', 3, false, false, 2200, ARRAY['Up to 15 SEER','Single-stage','Entry-level'], '{"seer": 15, "seer2": 14.3, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}')
) AS v(model_number, model_name, series, cap, wifi, estar, msrp, features, specs)
WHERE m.slug = 'american-standard-hvac' AND c.slug = 'hvac-central-ac';

-- American Standard Furnaces
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'gas', 'split-system', NULL, v.cap, 'btu', true, 20, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.americanstandardair.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('AUH2B080A9V5VB', 'Platinum 97 80K BTU', 'Platinum', 80000, true, true, 5200, ARRAY['97.3% AFUE','Modulating gas valve','Variable-speed ECM','AccuLink communicating'], '{"afue": 97.3, "btu": 80000, "voltage": 120, "stages": "modulating", "blower": "variable-speed"}'),
  ('AUH2C100A9V5VB', 'Platinum 97 100K BTU', 'Platinum', 100000, true, true, 5700, ARRAY['97.3% AFUE','Modulating gas valve','Variable-speed blower'], '{"afue": 97.3, "btu": 100000, "voltage": 120, "stages": "modulating", "blower": "variable-speed"}'),
  ('AUH1B080A9421A', 'Gold 95v 80K BTU', 'Gold', 80000, true, true, 3600, ARRAY['96% AFUE','Two-stage gas valve','Variable-speed blower'], '{"afue": 96, "btu": 80000, "voltage": 120, "stages": "two-stage", "blower": "variable-speed"}'),
  ('AUH1C100A9521A', 'Gold 95v 100K BTU', 'Gold', 100000, true, true, 4000, ARRAY['96% AFUE','Two-stage','Variable-speed ECM blower'], '{"afue": 96, "btu": 100000, "voltage": 120, "stages": "two-stage", "blower": "variable-speed"}'),
  ('AUD1B080A9361A', 'Silver 95 80K BTU', 'Silver', 80000, false, true, 2200, ARRAY['95% AFUE','Single-stage','Multi-speed blower'], '{"afue": 95, "btu": 80000, "voltage": 120, "stages": "single", "blower": "multi-speed"}'),
  ('AUD1B080H3M36A', 'Silver 80 80K BTU', 'Silver', 80000, false, false, 1600, ARRAY['80% AFUE','Single-stage','Non-condensing'], '{"afue": 80, "btu": 80000, "voltage": 120, "stages": "single", "blower": "multi-speed"}')
) AS v(model_number, model_name, series, cap, wifi, estar, msrp, features, specs)
WHERE m.slug = 'american-standard-hvac' AND c.slug = 'hvac-furnace';

-- American Standard Heat Pumps
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'split-system', NULL, v.cap, 'tons', true, 15, v.wifi, true, v.msrp, v.features, v.specs::jsonb, 'https://www.americanstandardair.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('4A7V8036A1000B', 'Platinum 20 3-Ton HP', 'Platinum 20', 3, true, 8000, ARRAY['Up to 20 SEER','Variable-speed inverter','AccuComfort','Heating to -22F'], '{"seer": 20, "hspf": 13.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter"}'),
  ('4A7A8036A1000A', 'Gold 18 3-Ton HP', 'Gold 18', 3, true, 5800, ARRAY['Up to 18.5 SEER','Two-stage compressor','Spine Fin coil'], '{"seer": 18.5, "hspf": 10.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage"}'),
  ('4A6S5036E1000A', 'Silver 16 3-Ton HP', 'Silver 16', 3, false, 3600, ARRAY['Up to 16 SEER','Single-stage','Scroll compressor'], '{"seer": 16, "hspf": 9.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}'),
  ('4A6S4036L1000A', 'Silver 14 3-Ton HP', 'Silver 14', 3, false, 2600, ARRAY['Up to 14.3 SEER2','Single-stage','Entry-level'], '{"seer2": 14.3, "hspf2": 7.5, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}')
) AS v(model_number, model_name, series, cap, wifi, msrp, features, specs)
WHERE m.slug = 'american-standard-hvac' AND c.slug = 'hvac-heat-pump';

-- -------------------- LENNOX --------------------

-- Lennox Central AC
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'split-system', NULL, v.cap, 'tons', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.lennox.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('XC25-036-230', 'XC25 3-Ton AC', 'Dave Lennox Signature', 3, 15, true, true, 9500, ARRAY['Up to 26 SEER','Variable-capacity inverter','SilentComfort technology','Precise Comfort','Sound: 59 dB'], '{"seer": 26, "seer2": 24.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter"}'),
  ('XC25-048-230', 'XC25 4-Ton AC', 'Dave Lennox Signature', 4, 15, true, true, 10200, ARRAY['Up to 24 SEER','Variable-capacity inverter','SilentComfort technology'], '{"seer": 24, "seer2": 22.5, "tons": 4, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter"}'),
  ('XC21-036-230', 'XC21 3-Ton AC', 'Dave Lennox Signature', 3, 15, true, true, 7200, ARRAY['Up to 21 SEER','Two-stage scroll compressor','SilentComfort','iComfort enabled'], '{"seer": 21, "seer2": 19.5, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage", "compressor": "scroll"}'),
  ('XC21-048-230', 'XC21 4-Ton AC', 'Dave Lennox Signature', 4, 15, true, true, 7800, ARRAY['Up to 20 SEER','Two-stage scroll compressor','SilentComfort'], '{"seer": 20, "seer2": 18.5, "tons": 4, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage", "compressor": "scroll"}'),
  ('EL18XCV-036-230', 'EL18XCV 3-Ton AC', 'Elite', 3, 15, true, true, 5200, ARRAY['Up to 18 SEER','Variable-speed compressor','iComfort compatible'], '{"seer": 18, "seer2": 17.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "scroll"}'),
  ('EL16XC1-036-230', 'EL16XC1 3-Ton AC', 'Elite', 3, 15, false, true, 3800, ARRAY['Up to 17 SEER','Single-stage','Quiet operation'], '{"seer": 17, "seer2": 15.5, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single", "compressor": "scroll"}'),
  ('ML18XC2-036-230', 'ML18XC2 3-Ton AC', 'Merit', 3, 15, false, true, 3200, ARRAY['Up to 18 SEER','Two-stage compressor','Value efficiency'], '{"seer": 18, "seer2": 16.5, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage"}'),
  ('ML14XC1-036-230', 'ML14XC1 3-Ton AC', 'Merit', 3, 15, false, false, 2200, ARRAY['Up to 16 SEER','Single-stage','Entry-level Lennox'], '{"seer": 16, "seer2": 14.3, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}'),
  ('14ACX-036-230', '14ACX 3-Ton AC', 'Merit', 3, 15, false, false, 1800, ARRAY['Up to 14.3 SEER2','Single-stage','Budget option'], '{"seer2": 14.3, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}')
) AS v(model_number, model_name, series, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'lennox' AND c.slug = 'hvac-central-ac';

-- Lennox Furnaces
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'gas', 'split-system', NULL, v.cap, 'btu', true, 20, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.lennox.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('SLP99V070XP36C', 'SLP99V 70K BTU', 'Dave Lennox Signature', 70000, true, true, 6200, ARRAY['98.7% AFUE','Variable-speed modulating','SilentComfort','Precise Comfort','iComfort enabled'], '{"afue": 98.7, "btu": 70000, "voltage": 120, "stages": "modulating", "blower": "variable-speed"}'),
  ('SLP99V090XP48C', 'SLP99V 90K BTU', 'Dave Lennox Signature', 90000, true, true, 6800, ARRAY['98.7% AFUE','Variable-speed modulating','SilentComfort technology'], '{"afue": 98.7, "btu": 90000, "voltage": 120, "stages": "modulating", "blower": "variable-speed"}'),
  ('SLP99V110XP60C', 'SLP99V 110K BTU', 'Dave Lennox Signature', 110000, true, true, 7400, ARRAY['98.7% AFUE','Variable-speed modulating','Large capacity'], '{"afue": 98.7, "btu": 110000, "voltage": 120, "stages": "modulating", "blower": "variable-speed"}'),
  ('SL297NV070XP36C', 'SL297NV 70K BTU', 'Dave Lennox Signature', 70000, true, true, 5000, ARRAY['97% AFUE','Two-stage','Variable-speed blower','iComfort'], '{"afue": 97, "btu": 70000, "voltage": 120, "stages": "two-stage", "blower": "variable-speed"}'),
  ('EL296V070XP36A', 'EL296V 70K BTU', 'Elite', 70000, true, true, 3800, ARRAY['96% AFUE','Two-stage','Variable-speed ECM'], '{"afue": 96, "btu": 70000, "voltage": 120, "stages": "two-stage", "blower": "variable-speed"}'),
  ('EL296V090XP48A', 'EL296V 90K BTU', 'Elite', 90000, true, true, 4200, ARRAY['96% AFUE','Two-stage','Variable-speed ECM blower'], '{"afue": 96, "btu": 90000, "voltage": 120, "stages": "two-stage", "blower": "variable-speed"}'),
  ('ML196UH070XP36B', 'ML196UH 70K BTU', 'Merit', 70000, false, true, 2400, ARRAY['96% AFUE','Single-stage','Multi-speed blower'], '{"afue": 96, "btu": 70000, "voltage": 120, "stages": "single", "blower": "multi-speed"}'),
  ('ML180UH070XP36B', 'ML180UH 70K BTU', 'Merit', 70000, false, false, 1600, ARRAY['80% AFUE','Single-stage','Non-condensing','Entry-level'], '{"afue": 80, "btu": 70000, "voltage": 120, "stages": "single", "blower": "multi-speed"}')
) AS v(model_number, model_name, series, cap, wifi, estar, msrp, features, specs)
WHERE m.slug = 'lennox' AND c.slug = 'hvac-furnace';

-- Lennox Heat Pumps
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'split-system', NULL, v.cap, 'tons', true, 15, v.wifi, true, v.msrp, v.features, v.specs::jsonb, 'https://www.lennox.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('XP25-036-230', 'XP25 3-Ton HP', 'Dave Lennox Signature', 3, true, 10000, ARRAY['Up to 23.5 SEER','Variable-capacity inverter','SilentComfort','Heating to -22F','Sound: 58 dB'], '{"seer": 23.5, "hspf": 10.2, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter"}'),
  ('XP21-036-230', 'XP21 3-Ton HP', 'Dave Lennox Signature', 3, true, 7500, ARRAY['Up to 21 SEER','Two-stage','SilentComfort','iComfort enabled'], '{"seer": 21, "hspf": 10.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage"}'),
  ('EL18XPV-036-230', 'EL18XPV 3-Ton HP', 'Elite', 3, true, 5500, ARRAY['Up to 18 SEER','Variable-speed compressor','iComfort compatible'], '{"seer": 18, "hspf": 9.5, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "variable"}'),
  ('14HPX-036-230', '14HPX 3-Ton HP', 'Merit', 3, false, 2800, ARRAY['Up to 16 SEER','Single-stage','Entry-level heat pump'], '{"seer": 16, "hspf": 9.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}')
) AS v(model_number, model_name, series, cap, wifi, msrp, features, specs)
WHERE m.slug = 'lennox' AND c.slug = 'hvac-heat-pump';

-- -------------------- BRYANT --------------------

-- Bryant Central AC
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'split-system', NULL, v.cap, 'tons', true, 15, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.bryant.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('189BNV036000', 'Evolution Extreme 26 3T', 'Evolution Extreme', 3, true, true, 7200, ARRAY['Up to 26 SEER','Variable-speed inverter','Evolution Connex control','Sound: 51 dB'], '{"seer": 26, "seer2": 24.5, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter"}'),
  ('180BNV036000', 'Evolution 180B 3-Ton AC', 'Evolution', 3, true, true, 5600, ARRAY['Up to 21 SEER','Two-stage compressor','Evolution Connex'], '{"seer": 21, "seer2": 19.5, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage", "compressor": "scroll"}'),
  ('127BNA036000', 'Preferred 127B 3-Ton AC', 'Preferred', 3, true, true, 3800, ARRAY['Up to 17 SEER','Two-stage compressor','Sound: 72 dB'], '{"seer": 17, "seer2": 16.2, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage"}'),
  ('116BNA036000', 'Legacy 116B 3-Ton AC', 'Legacy', 3, false, true, 2800, ARRAY['Up to 16 SEER','Single-stage','Scroll compressor'], '{"seer": 16, "seer2": 15.2, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}'),
  ('113ANA036000', 'Legacy 113A 3-Ton AC', 'Legacy', 3, false, false, 2200, ARRAY['Up to 14.3 SEER2','Single-stage','Entry-level'], '{"seer2": 14.3, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}')
) AS v(model_number, model_name, series, cap, wifi, estar, msrp, features, specs)
WHERE m.slug = 'bryant' AND c.slug = 'hvac-central-ac';

-- Bryant Furnaces
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'gas', 'split-system', NULL, v.cap, 'btu', true, 20, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.bryant.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('987MA42080V21', 'Evolution 987M 80K BTU', 'Evolution', 80000, true, true, 5000, ARRAY['98.3% AFUE','Modulating gas valve','Variable-speed ECM','Evolution Connex'], '{"afue": 98.3, "btu": 80000, "voltage": 120, "stages": "modulating", "blower": "variable-speed"}'),
  ('987MA42100V21', 'Evolution 987M 100K BTU', 'Evolution', 100000, true, true, 5500, ARRAY['98.3% AFUE','Modulating gas valve','Variable-speed blower'], '{"afue": 98.3, "btu": 100000, "voltage": 120, "stages": "modulating", "blower": "variable-speed"}'),
  ('926TA36080V17', 'Preferred 926T 80K BTU', 'Preferred', 80000, true, true, 3600, ARRAY['96% AFUE','Two-stage gas valve','Variable-speed blower'], '{"afue": 96, "btu": 80000, "voltage": 120, "stages": "two-stage", "blower": "variable-speed"}'),
  ('915SA36080V14', 'Preferred 915S 80K BTU', 'Preferred', 80000, false, true, 2400, ARRAY['96% AFUE','Single-stage','Multi-speed blower'], '{"afue": 96, "btu": 80000, "voltage": 120, "stages": "single", "blower": "multi-speed"}'),
  ('801SA36080M14', 'Legacy 801S 80K BTU', 'Legacy', 80000, false, false, 1600, ARRAY['80% AFUE','Single-stage','Non-condensing'], '{"afue": 80, "btu": 80000, "voltage": 120, "stages": "single", "blower": "multi-speed"}')
) AS v(model_number, model_name, series, cap, wifi, estar, msrp, features, specs)
WHERE m.slug = 'bryant' AND c.slug = 'hvac-furnace';

-- Bryant Heat Pumps
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'split-system', NULL, v.cap, 'tons', true, 15, v.wifi, true, v.msrp, v.features, v.specs::jsonb, 'https://www.bryant.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('289BNV036000', 'Evolution Extreme 24 3T HP', 'Evolution Extreme', 3, true, 7800, ARRAY['Up to 24 SEER','Variable-speed inverter','Evolution Connex','Heating to -15F'], '{"seer": 24, "hspf": 13.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter"}'),
  ('280ANV036000', 'Evolution 280A 3-Ton HP', 'Evolution', 3, true, 5600, ARRAY['Up to 19 SEER','Two-stage compressor','Evolution Connex'], '{"seer": 19, "hspf": 10.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage"}'),
  ('226ANA036000', 'Preferred 226A 3-Ton HP', 'Preferred', 3, true, 4000, ARRAY['Up to 17 SEER','Two-stage compressor','Sound: 72 dB'], '{"seer": 17, "hspf": 9.5, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage"}'),
  ('215BNA036000', 'Legacy 215B 3-Ton HP', 'Legacy', 3, false, 2800, ARRAY['Up to 16 SEER','Single-stage','Entry-level'], '{"seer": 16, "hspf": 9.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}')
) AS v(model_number, model_name, series, cap, wifi, msrp, features, specs)
WHERE m.slug = 'bryant' AND c.slug = 'hvac-heat-pump';

-- -------------------- DAIKIN --------------------

-- Daikin Central AC
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'split-system', NULL, v.cap, 'tons', true, 15, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.daikincomfort.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DX20VC0361AA', 'DX20VC 3-Ton AC', 'DX20VC', 3, true, true, 6800, ARRAY['Up to 24.5 SEER','Variable-speed inverter','Daikin One+ smart thermostat','Sound: 55 dB'], '{"seer": 24.5, "seer2": 23.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter"}'),
  ('DX20VC0481AA', 'DX20VC 4-Ton AC', 'DX20VC', 4, true, true, 7400, ARRAY['Up to 23 SEER','Variable-speed inverter','Daikin One+ compatible'], '{"seer": 23, "seer2": 21.5, "tons": 4, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter"}'),
  ('DX18TC0361AA', 'DX18TC 3-Ton AC', 'DX18TC', 3, true, true, 4800, ARRAY['Up to 18 SEER','Two-stage compressor','Quiet operation'], '{"seer": 18, "seer2": 17.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage", "compressor": "scroll"}'),
  ('DX16SA0361AA', 'DX16SA 3-Ton AC', 'DX16SA', 3, false, true, 3200, ARRAY['Up to 16 SEER','Single-stage','Scroll compressor','Factory R-410A'], '{"seer": 16, "seer2": 15.2, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single", "compressor": "scroll"}'),
  ('DX14SN0361AA', 'DX14SN 3-Ton AC', 'DX14SN', 3, false, false, 2200, ARRAY['Up to 15 SEER','Single-stage','Entry-level Daikin'], '{"seer": 15, "seer2": 14.3, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}'),
  ('DX16SA0481AA', 'DX16SA 4-Ton AC', 'DX16SA', 4, false, true, 3600, ARRAY['Up to 16 SEER','Single-stage','Large capacity'], '{"seer": 16, "seer2": 15.2, "tons": 4, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}')
) AS v(model_number, model_name, series, cap, wifi, estar, msrp, features, specs)
WHERE m.slug = 'daikin' AND c.slug = 'hvac-central-ac';

-- Daikin Furnaces
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'gas', 'split-system', NULL, v.cap, 'btu', true, 20, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.daikincomfort.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DM97MC0803BN', 'DM97MC 80K BTU', 'DM97MC', 80000, true, true, 4200, ARRAY['97% AFUE','Modulating gas valve','Variable-speed ECM','Daikin One+ compatible'], '{"afue": 97, "btu": 80000, "voltage": 120, "stages": "modulating", "blower": "variable-speed"}'),
  ('DM97MC1005CN', 'DM97MC 100K BTU', 'DM97MC', 100000, true, true, 4600, ARRAY['97% AFUE','Modulating gas valve','Variable-speed blower'], '{"afue": 97, "btu": 100000, "voltage": 120, "stages": "modulating", "blower": "variable-speed"}'),
  ('DM96VE0804BN', 'DM96VE 80K BTU', 'DM96VE', 80000, true, true, 3200, ARRAY['96% AFUE','Two-stage gas valve','Variable-speed ECM blower'], '{"afue": 96, "btu": 80000, "voltage": 120, "stages": "two-stage", "blower": "variable-speed"}'),
  ('DC96VE0803BN', 'DC96VE 80K BTU', 'DC96VE', 80000, false, true, 2600, ARRAY['96% AFUE','Two-stage','Multi-speed blower'], '{"afue": 96, "btu": 80000, "voltage": 120, "stages": "two-stage", "blower": "multi-speed"}'),
  ('DM80VE0804BN', 'DM80VE 80K BTU', 'DM80VE', 80000, false, false, 1600, ARRAY['80% AFUE','Single-stage','Variable-speed blower'], '{"afue": 80, "btu": 80000, "voltage": 120, "stages": "single", "blower": "variable-speed"}')
) AS v(model_number, model_name, series, cap, wifi, estar, msrp, features, specs)
WHERE m.slug = 'daikin' AND c.slug = 'hvac-furnace';

-- Daikin Heat Pumps
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'split-system', NULL, v.cap, 'tons', true, 15, v.wifi, true, v.msrp, v.features, v.specs::jsonb, 'https://www.daikincomfort.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DZ20VC0361AA', 'DZ20VC 3-Ton HP', 'DZ20VC', 3, true, 7200, ARRAY['Up to 23 SEER','Variable-speed inverter','Daikin One+ compatible','Heating to -15F'], '{"seer": 23, "hspf": 12.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter"}'),
  ('DZ18TC0361AA', 'DZ18TC 3-Ton HP', 'DZ18TC', 3, true, 5000, ARRAY['Up to 19 SEER','Two-stage compressor','Quiet operation'], '{"seer": 19, "hspf": 10.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage"}'),
  ('DZ16SA0361AA', 'DZ16SA 3-Ton HP', 'DZ16SA', 3, false, 3400, ARRAY['Up to 16 SEER','Single-stage','Scroll compressor'], '{"seer": 16, "hspf": 9.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}'),
  ('DZ14SN0361AA', 'DZ14SN 3-Ton HP', 'DZ14SN', 3, false, 2400, ARRAY['Up to 14.3 SEER2','Single-stage','Entry-level'], '{"seer2": 14.3, "hspf2": 7.5, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}')
) AS v(model_number, model_name, series, cap, wifi, msrp, features, specs)
WHERE m.slug = 'daikin' AND c.slug = 'hvac-heat-pump';

-- Daikin Mini-Splits
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'ductless', NULL, v.cap, 'btu', true, 15, v.wifi, true, v.msrp, v.features, v.specs::jsonb, 'https://www.daikincomfort.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('RXB12AXVJU', 'Fit 12K BTU Outdoor', 'Fit', 12000, true, 2200, ARRAY['Up to 19 SEER','Inverter technology','Heat pump','Compact design'], '{"seer": 19, "hspf": 10.0, "btu": 12000, "voltage": 208, "refrigerant": "R-32", "stages": "variable", "compressor": "inverter", "zones": 1}'),
  ('RXB18AXVJU', 'Fit 18K BTU Outdoor', 'Fit', 18000, true, 2800, ARRAY['Up to 19 SEER','Inverter','R-32 refrigerant'], '{"seer": 19, "hspf": 10.0, "btu": 18000, "voltage": 208, "refrigerant": "R-32", "stages": "variable", "compressor": "inverter", "zones": 1}'),
  ('MXS348MVJU9', '3-Zone 48K BTU Multi-Split', 'Aurora', 48000, true, 6500, ARRAY['Up to 20.9 SEER','Multi-zone','3-zone outdoor unit','Inverter'], '{"seer": 20.9, "hspf": 11.0, "btu": 48000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 3}'),
  ('MXS548MVJU9', '5-Zone 48K BTU Multi-Split', 'Aurora', 48000, true, 8000, ARRAY['Up to 19.9 SEER','5-zone outdoor','Heating to 5F'], '{"seer": 19.9, "hspf": 10.5, "btu": 48000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 5}')
) AS v(model_number, model_name, series, cap, wifi, msrp, features, specs)
WHERE m.slug = 'daikin' AND c.slug = 'hvac-mini-split';

-- ======================== HIGH-END BRANDS ========================

-- -------------------- MITSUBISHI ELECTRIC --------------------

-- Mitsubishi Mini-Splits (their primary product)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', v.install, NULL, v.cap, 'btu', true, v.lifespan, v.wifi, true, v.msrp, v.features, v.specs::jsonb, 'https://www.mitsubishicomfort.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('MSZ-FH09NA', 'MSZ-FH09 9K BTU Wall Mount', 'FH-Series Hyper-Heat', 9000, 'wall-mount', 15, true, 2400, ARRAY['33.1 SEER','Hyper-Heat to -13F','3D i-see Sensor','Dual barrier coating','Whisper quiet 19 dB'], '{"seer": 33.1, "hspf": 14.2, "btu": 9000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}'),
  ('MSZ-FH12NA', 'MSZ-FH12 12K BTU Wall Mount', 'FH-Series Hyper-Heat', 12000, 'wall-mount', 15, true, 2800, ARRAY['30.5 SEER','Hyper-Heat to -13F','3D i-see Sensor','Plasma Quad filtration'], '{"seer": 30.5, "hspf": 13.5, "btu": 12000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}'),
  ('MSZ-FH15NA', 'MSZ-FH15 15K BTU Wall Mount', 'FH-Series Hyper-Heat', 15000, 'wall-mount', 15, true, 3200, ARRAY['25.3 SEER','Hyper-Heat to -13F','3D i-see Sensor','Auto-vane airflow'], '{"seer": 25.3, "hspf": 12.5, "btu": 15000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}'),
  ('MSZ-FH18NA', 'MSZ-FH18 18K BTU Wall Mount', 'FH-Series Hyper-Heat', 18000, 'wall-mount', 15, true, 3600, ARRAY['22.0 SEER','Hyper-Heat to -13F','3D i-see Sensor','Econo Cool mode'], '{"seer": 22.0, "hspf": 12.0, "btu": 18000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}'),
  ('MSZ-GL09NA', 'MSZ-GL09 9K BTU Wall Mount', 'GL-Series', 9000, 'wall-mount', 15, true, 1800, ARRAY['24.6 SEER','Standard cold climate','Anti-allergy enzyme filter','Econo Cool'], '{"seer": 24.6, "hspf": 12.0, "btu": 9000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}'),
  ('MSZ-GL12NA', 'MSZ-GL12 12K BTU Wall Mount', 'GL-Series', 12000, 'wall-mount', 15, true, 2000, ARRAY['22.0 SEER','Standard cold climate','Anti-allergy filter','Quiet: 21 dB'], '{"seer": 22.0, "hspf": 11.0, "btu": 12000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}'),
  ('MSZ-GL18NA', 'MSZ-GL18 18K BTU Wall Mount', 'GL-Series', 18000, 'wall-mount', 15, true, 2600, ARRAY['20.0 SEER','Standard cold climate','Multi-vane airflow'], '{"seer": 20.0, "hspf": 10.5, "btu": 18000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}'),
  ('MSZ-GL24NA', 'MSZ-GL24 24K BTU Wall Mount', 'GL-Series', 24000, 'wall-mount', 15, true, 3000, ARRAY['19.0 SEER','Standard cold climate','Large room coverage'], '{"seer": 19.0, "hspf": 10.0, "btu": 24000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}'),
  ('MLZ-KP09NA', 'MLZ-KP09 9K BTU Ceiling Cassette', 'KP-Series', 9000, 'ductless', 15, true, 2800, ARRAY['26.1 SEER','Ceiling cassette','4-way airflow','Low profile 8" depth'], '{"seer": 26.1, "hspf": 12.5, "btu": 9000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}'),
  ('MLZ-KP12NA', 'MLZ-KP12 12K BTU Ceiling Cassette', 'KP-Series', 12000, 'ductless', 15, true, 3200, ARRAY['25.0 SEER','Ceiling cassette','4-way airflow','Hyper-Heat compatible'], '{"seer": 25.0, "hspf": 12.0, "btu": 12000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}'),
  ('MFZ-KJ09NA', 'MFZ-KJ09 9K BTU Floor Mount', 'KJ-Series', 9000, 'wall-mount', 15, true, 2600, ARRAY['26.0 SEER','Floor-standing unit','Dual airflow','Hyper-Heat to -13F'], '{"seer": 26.0, "hspf": 12.5, "btu": 9000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}'),
  ('MFZ-KJ12NA', 'MFZ-KJ12 12K BTU Floor Mount', 'KJ-Series', 12000, 'wall-mount', 15, true, 3000, ARRAY['23.0 SEER','Floor-standing unit','Dual airflow','Quiet operation'], '{"seer": 23.0, "hspf": 12.0, "btu": 12000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}')
) AS v(model_number, model_name, series, cap, install, lifespan, wifi, msrp, features, specs)
WHERE m.slug = 'mitsubishi-electric' AND c.slug = 'hvac-mini-split';

-- Mitsubishi Multi-Zone Outdoor Units
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'ductless', NULL, v.cap, 'btu', true, 15, true, true, v.msrp, v.features, v.specs::jsonb, 'https://www.mitsubishicomfort.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('MXZ-2C20NAHZ2', 'MXZ-2C20 2-Zone 20K BTU', 'MXZ Hyper-Heat', 20000, 4200, ARRAY['2-zone multi-split outdoor','Hyper-Heat to -13F','20.0 SEER','Inverter-driven'], '{"seer": 20.0, "hspf": 12.0, "btu": 20000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 2}'),
  ('MXZ-3C30NAHZ2', 'MXZ-3C30 3-Zone 30K BTU', 'MXZ Hyper-Heat', 30000, 5800, ARRAY['3-zone multi-split outdoor','Hyper-Heat to -13F','19.4 SEER'], '{"seer": 19.4, "hspf": 11.5, "btu": 30000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 3}'),
  ('MXZ-4C36NAHZ', 'MXZ-4C36 4-Zone 36K BTU', 'MXZ Hyper-Heat', 36000, 7200, ARRAY['4-zone multi-split outdoor','Hyper-Heat to -13F','18.9 SEER'], '{"seer": 18.9, "hspf": 11.0, "btu": 36000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 4}'),
  ('MXZ-5C42NAHZ', 'MXZ-5C42 5-Zone 42K BTU', 'MXZ Hyper-Heat', 42000, 8800, ARRAY['5-zone multi-split outdoor','Hyper-Heat to -13F','18.0 SEER'], '{"seer": 18.0, "hspf": 10.5, "btu": 42000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 5}'),
  ('MXZ-8C48NAHZ', 'MXZ-8C48 8-Zone 48K BTU', 'MXZ Hyper-Heat', 48000, 12000, ARRAY['8-zone multi-split outdoor','Hyper-Heat to -13F','Whole-home solution'], '{"seer": 17.5, "hspf": 10.2, "btu": 48000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 8}')
) AS v(model_number, model_name, series, cap, msrp, features, specs)
WHERE m.slug = 'mitsubishi-electric' AND c.slug = 'hvac-mini-split';

-- Mitsubishi Ducted Systems
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'split-system', NULL, v.cap, 'tons', true, 15, true, true, v.msrp, v.features, v.specs::jsonb, 'https://www.mitsubishicomfort.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('PUZ-HA36NHA5', 'PUZ-HA36 3-Ton Ducted HP', 'H2i Hyper-Heat', 3, 7500, ARRAY['Up to 18.4 SEER','Hyper-Heat to -13F','Ducted solution','Whole-home replacement'], '{"seer": 18.4, "hspf": 11.5, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter"}'),
  ('PUZ-HA42NHA5', 'PUZ-HA42 3.5-Ton Ducted HP', 'H2i Hyper-Heat', 3.5, 8200, ARRAY['Up to 17.5 SEER','Hyper-Heat to -13F','Large capacity ducted'], '{"seer": 17.5, "hspf": 11.0, "tons": 3.5, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter"}'),
  ('SUZ-KA09NAHZ', 'SUZ-KA09 3/4-Ton Ducted HP', 'M-Series', 0.75, 3200, ARRAY['Up to 33.1 SEER','Hyper-Heat','Small ducted concealed'], '{"seer": 33.1, "hspf": 14.2, "btu": 9000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter"}')
) AS v(model_number, model_name, series, cap, msrp, features, specs)
WHERE m.slug = 'mitsubishi-electric' AND c.slug = 'hvac-heat-pump';

-- -------------------- BOSCH --------------------

-- Bosch Mini-Splits
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'ductless', NULL, v.cap, 'btu', true, 15, v.wifi, true, v.msrp, v.features, v.specs::jsonb, 'https://www.bosch-climate.us'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('BMS500-AAS009-1', 'Climate 5000 9K BTU Mini-Split', 'Climate 5000', 9000, true, 1600, ARRAY['Up to 27.0 SEER','Inverter compressor','Heating to -22F','Quiet 20 dB'], '{"seer": 27.0, "hspf": 12.5, "btu": 9000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}'),
  ('BMS500-AAS012-1', 'Climate 5000 12K BTU Mini-Split', 'Climate 5000', 12000, true, 1900, ARRAY['Up to 25.0 SEER','Inverter compressor','Heating to -22F'], '{"seer": 25.0, "hspf": 12.0, "btu": 12000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}'),
  ('BMS500-AAS018-1', 'Climate 5000 18K BTU Mini-Split', 'Climate 5000', 18000, true, 2400, ARRAY['Up to 22.0 SEER','Inverter compressor','WiFi built-in'], '{"seer": 22.0, "hspf": 11.0, "btu": 18000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}'),
  ('BMS500-AAS024-1', 'Climate 5000 24K BTU Mini-Split', 'Climate 5000', 24000, true, 2800, ARRAY['Up to 20.7 SEER','Inverter compressor','Large room coverage'], '{"seer": 20.7, "hspf": 10.5, "btu": 24000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}'),
  ('BMS500-AAM036-2', 'Climate 5000 2-Zone 36K BTU', 'Climate 5000', 36000, true, 4200, ARRAY['Up to 22.0 SEER','2-zone multi-split','Inverter driven'], '{"seer": 22.0, "hspf": 11.0, "btu": 36000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 2}')
) AS v(model_number, model_name, series, cap, wifi, msrp, features, specs)
WHERE m.slug = 'bosch' AND c.slug = 'hvac-mini-split';

-- Bosch Heat Pumps (Ducted IDS systems)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'split-system', NULL, v.cap, 'tons', true, 15, true, true, v.msrp, v.features, v.specs::jsonb, 'https://www.bosch-climate.us'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('BOVA-36HDN1-M20G', 'IDS Ultra 3-Ton HP', 'IDS Ultra', 3, 6800, ARRAY['Up to 20.5 SEER','Inverter-driven scroll','Heating to -4F','Variable-speed'], '{"seer": 20.5, "hspf": 11.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter"}'),
  ('BOVA-48HDN1-M20G', 'IDS Ultra 4-Ton HP', 'IDS Ultra', 4, 7600, ARRAY['Up to 19.0 SEER','Inverter-driven scroll','Large capacity'], '{"seer": 19.0, "hspf": 10.5, "tons": 4, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter"}'),
  ('BOVA-60HDN1-M20G', 'IDS Ultra 5-Ton HP', 'IDS Ultra', 5, 8400, ARRAY['Up to 18.0 SEER','Inverter-driven scroll','Whole-home solution'], '{"seer": 18.0, "hspf": 10.0, "tons": 5, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter"}'),
  ('BOVA-36HDN1-M18G', 'IDS Premium 3-Ton HP', 'IDS Premium', 3, 5200, ARRAY['Up to 18.5 SEER','Two-stage compressor','Heating to 5F'], '{"seer": 18.5, "hspf": 10.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage", "compressor": "scroll"}'),
  ('BOVA-48HDN1-M18G', 'IDS Premium 4-Ton HP', 'IDS Premium', 4, 5800, ARRAY['Up to 17.0 SEER','Two-stage compressor','Large capacity'], '{"seer": 17.0, "hspf": 9.5, "tons": 4, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage", "compressor": "scroll"}')
) AS v(model_number, model_name, series, cap, msrp, features, specs)
WHERE m.slug = 'bosch' AND c.slug = 'hvac-heat-pump';

-- Bosch Boilers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'split-system', NULL, v.cap, 'btu', true, v.lifespan, v.wifi, true, v.msrp, v.features, v.specs::jsonb, 'https://www.bosch-climate.us'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('GC9-80', 'Greenstar 9000 80K BTU', 'Greenstar 9000', 'gas', 80000, 25, true, 4800, ARRAY['95.0% AFUE','Condensing wall-hung','Modulating burner','Built-in pump'], '{"afue": 95.0, "btu": 80000, "voltage": 120, "stages": "modulating", "type": "wall-hung"}'),
  ('GC9-120', 'Greenstar 9000 120K BTU', 'Greenstar 9000', 'gas', 120000, 25, true, 5400, ARRAY['95.0% AFUE','Condensing wall-hung','Modulating burner'], '{"afue": 95.0, "btu": 120000, "voltage": 120, "stages": "modulating", "type": "wall-hung"}'),
  ('GC9-160', 'Greenstar 9000 160K BTU', 'Greenstar 9000', 'gas', 160000, 25, true, 6200, ARRAY['95.0% AFUE','Condensing wall-hung','Large capacity'], '{"afue": 95.0, "btu": 160000, "voltage": 120, "stages": "modulating", "type": "wall-hung"}'),
  ('GC5700WS-120', 'Greenstar 5700 120K BTU', 'Greenstar 5700', 'gas', 120000, 25, true, 4200, ARRAY['95.0% AFUE','Condensing floor-standing','Stainless heat exchanger'], '{"afue": 95.0, "btu": 120000, "voltage": 120, "stages": "modulating", "type": "floor-standing"}'),
  ('SSB85', 'Greenstar Combi 85K BTU', 'Greenstar Combi', 'gas', 85000, 20, true, 4500, ARRAY['95.0% AFUE','Combi boiler','Space heating + DHW','Wall-mounted'], '{"afue": 95.0, "btu": 85000, "voltage": 120, "stages": "modulating", "type": "combi"}')
) AS v(model_number, model_name, series, fuel, cap, lifespan, wifi, msrp, features, specs)
WHERE m.slug = 'bosch' AND c.slug = 'hvac-boiler';

-- -------------------- FUJITSU --------------------

-- Fujitsu Mini-Splits
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', v.install, NULL, v.cap, 'btu', true, 15, v.wifi, true, v.msrp, v.features, v.specs::jsonb, 'https://www.fujitsugeneral.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('ASU9RLS3Y', 'Halcyon 9K BTU Wall Mount', 'Halcyon', 9000, 'wall-mount', true, 2000, ARRAY['33.0 SEER','Inverter-driven','Heating to -5F','Quiet 20 dB','Energy Star Most Efficient'], '{"seer": 33.0, "hspf": 14.0, "btu": 9000, "voltage": 115, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}'),
  ('ASU12RLS3Y', 'Halcyon 12K BTU Wall Mount', 'Halcyon', 12000, 'wall-mount', true, 2400, ARRAY['29.3 SEER','Inverter-driven','Heating to -5F','Quiet 21 dB'], '{"seer": 29.3, "hspf": 13.0, "btu": 12000, "voltage": 115, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}'),
  ('ASU15RLS3Y', 'Halcyon 15K BTU Wall Mount', 'Halcyon', 15000, 'wall-mount', true, 2800, ARRAY['25.3 SEER','Inverter-driven','Multi-vane airflow'], '{"seer": 25.3, "hspf": 12.5, "btu": 15000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}'),
  ('ASU18RLS3Y', 'Halcyon 18K BTU Wall Mount', 'Halcyon', 18000, 'wall-mount', true, 3200, ARRAY['21.0 SEER','Inverter-driven','Timer and auto modes'], '{"seer": 21.0, "hspf": 11.0, "btu": 18000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}'),
  ('ASU24RLS3Y', 'Halcyon 24K BTU Wall Mount', 'Halcyon', 24000, 'wall-mount', true, 3800, ARRAY['20.0 SEER','Inverter-driven','Large room coverage'], '{"seer": 20.0, "hspf": 10.5, "btu": 24000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}'),
  ('ASU9RLF1', 'DERA09 9K BTU Wall Mount', 'XLTH', 9000, 'wall-mount', true, 2600, ARRAY['33.0 SEER','Extra Low Temp Heating to -15F','Hyper-Heat equivalent','Quiet: 19 dB'], '{"seer": 33.0, "hspf": 14.2, "btu": 9000, "voltage": 115, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}'),
  ('ASU12RLF1', 'XLTH 12K BTU Wall Mount', 'XLTH', 12000, 'wall-mount', true, 3000, ARRAY['30.5 SEER','Extra Low Temp Heating to -15F','WiFi included'], '{"seer": 30.5, "hspf": 13.5, "btu": 12000, "voltage": 115, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}'),
  ('AOU36RLXFZH', '3-Zone 36K Multi-Split', 'Halcyon Multi-Zone', 36000, 'ductless', true, 5200, ARRAY['Up to 19.7 SEER','3-zone outdoor unit','Heating to -5F','Inverter'], '{"seer": 19.7, "hspf": 11.0, "btu": 36000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 3}'),
  ('AOU48RLXFZH', '4-Zone 48K Multi-Split', 'Halcyon Multi-Zone', 48000, 'ductless', true, 7000, ARRAY['Up to 18.0 SEER','4-zone outdoor','Heating to -5F'], '{"seer": 18.0, "hspf": 10.5, "btu": 48000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 4}'),
  ('AUU12RGLX', '12K BTU Slim Duct', 'Halcyon Slim Duct', 12000, 'ductless', true, 2800, ARRAY['23.0 SEER','Concealed slim duct','Low profile 8"','Quiet: 23 dB'], '{"seer": 23.0, "hspf": 12.0, "btu": 12000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}')
) AS v(model_number, model_name, series, cap, install, wifi, msrp, features, specs)
WHERE m.slug = 'fujitsu' AND c.slug = 'hvac-mini-split';

-- ======================== ULTRA-LUXURY BOILER BRANDS ========================

-- -------------------- VIESSMANN --------------------

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'split-system', NULL, v.cap, 'btu', true, v.lifespan, v.wifi, true, v.msrp, v.features, v.specs::jsonb, 'https://www.viessmann.us'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('B2HA-19', 'Vitodens 200-W 19K BTU', 'Vitodens 200-W', 'gas', 19000, 25, true, 5200, ARRAY['98% AFUE','Modulating condensing','Stainless Inox-Radial heat exchanger','Wall-mounted','Self-calibrating Lambda Pro Plus'], '{"afue": 98, "btu": 19000, "voltage": 120, "stages": "modulating", "type": "wall-hung", "modulation_range": "10:1"}'),
  ('B2HA-35', 'Vitodens 200-W 35K BTU', 'Vitodens 200-W', 'gas', 35000, 25, true, 5800, ARRAY['98% AFUE','Modulating condensing','Stainless Inox-Radial','WiFi via ViCare app'], '{"afue": 98, "btu": 35000, "voltage": 120, "stages": "modulating", "type": "wall-hung"}'),
  ('B2HA-60', 'Vitodens 200-W 60K BTU', 'Vitodens 200-W', 'gas', 60000, 25, true, 6400, ARRAY['98% AFUE','Modulating condensing','Self-calibrating combustion'], '{"afue": 98, "btu": 60000, "voltage": 120, "stages": "modulating", "type": "wall-hung"}'),
  ('B2HA-100', 'Vitodens 200-W 100K BTU', 'Vitodens 200-W', 'gas', 100000, 25, true, 7200, ARRAY['98% AFUE','Modulating condensing','Large capacity residential'], '{"afue": 98, "btu": 100000, "voltage": 120, "stages": "modulating", "type": "wall-hung"}'),
  ('B2HA-150', 'Vitodens 200-W 150K BTU', 'Vitodens 200-W', 'gas', 150000, 25, true, 8500, ARRAY['98% AFUE','Modulating condensing','Commercial/residential crossover'], '{"afue": 98, "btu": 150000, "voltage": 120, "stages": "modulating", "type": "wall-hung"}'),
  ('B2HB-19', 'Vitodens 100-W 19K BTU', 'Vitodens 100-W', 'gas', 19000, 25, true, 3800, ARRAY['95.2% AFUE','Condensing wall-hung','Stainless steel heat exchanger'], '{"afue": 95.2, "btu": 19000, "voltage": 120, "stages": "modulating", "type": "wall-hung"}'),
  ('B2HB-50', 'Vitodens 100-W 50K BTU', 'Vitodens 100-W', 'gas', 50000, 25, true, 4400, ARRAY['95.2% AFUE','Condensing wall-hung','Compact design'], '{"afue": 95.2, "btu": 50000, "voltage": 120, "stages": "modulating", "type": "wall-hung"}'),
  ('B2HB-100', 'Vitodens 100-W 100K BTU', 'Vitodens 100-W', 'gas', 100000, 25, true, 5200, ARRAY['95.2% AFUE','Condensing wall-hung','Large capacity'], '{"afue": 95.2, "btu": 100000, "voltage": 120, "stages": "modulating", "type": "wall-hung"}'),
  ('B2HB-125C', 'Vitodens 100-W Combi 125K', 'Vitodens 100-W Combi', 'gas', 125000, 20, true, 5800, ARRAY['95.2% AFUE','Combi boiler','Space heating + 4.7 GPM DHW','Wall-mounted'], '{"afue": 95.2, "btu": 125000, "voltage": 120, "stages": "modulating", "type": "combi", "dhw_gpm": 4.7}'),
  ('B2KB-57', 'Vitocrossal 300 57K BTU', 'Vitocrossal 300', 'gas', 57000, 30, true, 9500, ARRAY['95% AFUE','Condensing floor-standing','Cast aluminum-silicon heat exchanger','Premium commercial-grade'], '{"afue": 95, "btu": 57000, "voltage": 120, "stages": "modulating", "type": "floor-standing"}')
) AS v(model_number, model_name, series, fuel, cap, lifespan, wifi, msrp, features, specs)
WHERE m.slug = 'viessmann' AND c.slug = 'hvac-boiler';

-- -------------------- BUDERUS --------------------

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'split-system', NULL, v.cap, 'btu', true, v.lifespan, v.wifi, true, v.msrp, v.features, v.specs::jsonb, 'https://www.buderus.us'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('GB142-24', 'GB142 24K BTU Wall-Hung', 'GB142', 'gas', 24000, 25, true, 4200, ARRAY['95.5% AFUE','Condensing wall-hung','Aluminum heat exchanger','Modulating burner'], '{"afue": 95.5, "btu": 24000, "voltage": 120, "stages": "modulating", "type": "wall-hung"}'),
  ('GB142-45', 'GB142 45K BTU Wall-Hung', 'GB142', 'gas', 45000, 25, true, 4800, ARRAY['95.5% AFUE','Condensing wall-hung','Modulating burner'], '{"afue": 95.5, "btu": 45000, "voltage": 120, "stages": "modulating", "type": "wall-hung"}'),
  ('GB142-60', 'GB142 60K BTU Wall-Hung', 'GB142', 'gas', 60000, 25, true, 5400, ARRAY['95.5% AFUE','Condensing wall-hung','Large capacity'], '{"afue": 95.5, "btu": 60000, "voltage": 120, "stages": "modulating", "type": "wall-hung"}'),
  ('GB142-100', 'GB142 100K BTU Wall-Hung', 'GB142', 'gas', 100000, 25, true, 6200, ARRAY['95.5% AFUE','Condensing wall-hung','High output residential'], '{"afue": 95.5, "btu": 100000, "voltage": 120, "stages": "modulating", "type": "wall-hung"}'),
  ('GB125-30', 'GB125 102K BTU Floor', 'GB125', 'gas', 102000, 30, false, 5800, ARRAY['92.8% AFUE','Cast iron floor-standing','Durable sectional design','25-year heat exchanger warranty'], '{"afue": 92.8, "btu": 102000, "voltage": 120, "stages": "single", "type": "floor-standing"}'),
  ('GB125-40', 'GB125 136K BTU Floor', 'GB125', 'gas', 136000, 30, false, 6500, ARRAY['92.8% AFUE','Cast iron floor-standing','Large capacity'], '{"afue": 92.8, "btu": 136000, "voltage": 120, "stages": "single", "type": "floor-standing"}'),
  ('SSB-85', 'SSB 85K BTU Combi', 'SSB Combi', 'gas', 85000, 20, true, 4500, ARRAY['95.0% AFUE','Combi boiler','Stainless heat exchanger','Space heating + DHW'], '{"afue": 95.0, "btu": 85000, "voltage": 120, "stages": "modulating", "type": "combi", "dhw_gpm": 4.0}'),
  ('G215-4', 'G215 Oil-Fired 119K BTU', 'G215', 'oil', 119000, 30, false, 5200, ARRAY['87% AFUE','Cast iron sections','Oil-fired floor-standing','Proven German engineering'], '{"afue": 87, "btu": 119000, "voltage": 120, "stages": "single", "type": "floor-standing", "fuel": "oil"}')
) AS v(model_number, model_name, series, fuel, cap, lifespan, wifi, msrp, features, specs)
WHERE m.slug = 'buderus' AND c.slug = 'hvac-boiler';

-- -------------------- WEIL-McLAIN --------------------

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'split-system', NULL, v.cap, 'btu', true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.weil-mclain.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('ECO-70', 'ECO 70K BTU Condensing', 'ECO', 'gas', 70000, 25, true, true, 4200, ARRAY['95% AFUE','Condensing wall-hung','Stainless steel fire tube','Modulating burner','Compact design'], '{"afue": 95, "btu": 70000, "voltage": 120, "stages": "modulating", "type": "wall-hung"}'),
  ('ECO-110', 'ECO 110K BTU Condensing', 'ECO', 'gas', 110000, 25, true, true, 4800, ARRAY['95% AFUE','Condensing wall-hung','Stainless fire tube','Large output'], '{"afue": 95, "btu": 110000, "voltage": 120, "stages": "modulating", "type": "wall-hung"}'),
  ('ECO-155', 'ECO 155K BTU Condensing', 'ECO', 'gas', 155000, 25, true, true, 5600, ARRAY['95% AFUE','Condensing wall-hung','High output residential/light commercial'], '{"afue": 95, "btu": 155000, "voltage": 120, "stages": "modulating", "type": "wall-hung"}'),
  ('ECO-C100', 'ECO Combi 100K BTU', 'ECO Combi', 'gas', 100000, 20, true, true, 5200, ARRAY['95% AFUE','Combi boiler','3.5 GPM DHW','Space heating + domestic hot water'], '{"afue": 95, "btu": 100000, "voltage": 120, "stages": "modulating", "type": "combi", "dhw_gpm": 3.5}'),
  ('ULTRA-80', 'Ultra 80K BTU', 'Ultra', 'gas', 80000, 25, true, true, 5500, ARRAY['97% AFUE','Condensing firetube','Stainless steel','Premium residential'], '{"afue": 97, "btu": 80000, "voltage": 120, "stages": "modulating", "type": "wall-hung"}'),
  ('ULTRA-155', 'Ultra 155K BTU', 'Ultra', 'gas', 155000, 25, true, true, 6800, ARRAY['97% AFUE','Condensing firetube','High output','Premium efficiency'], '{"afue": 97, "btu": 155000, "voltage": 120, "stages": "modulating", "type": "wall-hung"}'),
  ('ULTRA-230', 'Ultra 230K BTU', 'Ultra', 'gas', 230000, 25, true, true, 8200, ARRAY['97% AFUE','Condensing firetube','Large commercial/residential'], '{"afue": 97, "btu": 230000, "voltage": 120, "stages": "modulating", "type": "wall-hung"}'),
  ('GV90+3', 'GV90+ 3 Section 70K BTU', 'GV90+', 'gas', 70000, 30, false, true, 3800, ARRAY['91.9% AFUE','Cast iron sections','Atmospheric draft','Proven reliability'], '{"afue": 91.9, "btu": 70000, "voltage": 120, "stages": "single", "type": "floor-standing"}'),
  ('GV90+4', 'GV90+ 4 Section 105K BTU', 'GV90+', 'gas', 105000, 30, false, true, 4400, ARRAY['91.9% AFUE','Cast iron sections','Atmospheric draft'], '{"afue": 91.9, "btu": 105000, "voltage": 120, "stages": "single", "type": "floor-standing"}'),
  ('GV90+5', 'GV90+ 5 Section 131K BTU', 'GV90+', 'gas', 131000, 30, false, true, 5000, ARRAY['91.9% AFUE','Cast iron sections','Large capacity'], '{"afue": 91.9, "btu": 131000, "voltage": 120, "stages": "single", "type": "floor-standing"}'),
  ('SGO-3', 'SGO 3 Section Oil 83K BTU', 'SGO', 'oil', 83000, 30, false, false, 3200, ARRAY['86.1% AFUE','Cast iron oil-fired','Floor-standing','Beckett burner compatible'], '{"afue": 86.1, "btu": 83000, "voltage": 120, "stages": "single", "type": "floor-standing", "fuel": "oil"}'),
  ('SGO-4', 'SGO 4 Section Oil 117K BTU', 'SGO', 'oil', 117000, 30, false, false, 3800, ARRAY['86.1% AFUE','Cast iron oil-fired','Large capacity'], '{"afue": 86.1, "btu": 117000, "voltage": 120, "stages": "single", "type": "floor-standing", "fuel": "oil"}')
) AS v(model_number, model_name, series, fuel, cap, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'weil-mclain' AND c.slug = 'hvac-boiler';

-- -------------------- NAVIEN --------------------

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'gas', 'split-system', NULL, v.cap, 'btu', true, v.lifespan, v.wifi, true, v.msrp, v.features, v.specs::jsonb, 'https://www.navien.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('NCB-240E', 'NCB-240E Combi-Boiler', 'NCB-E', 120000, 20, true, 4200, ARRAY['95% AFUE','Condensing combi-boiler','Space heating + 4.0 GPM DHW','Stainless heat exchanger','NaviLink WiFi'], '{"afue": 95, "btu": 120000, "voltage": 120, "stages": "modulating", "type": "combi", "dhw_gpm": 4.0}'),
  ('NCB-210E', 'NCB-210E Combi-Boiler', 'NCB-E', 100000, 20, true, 3800, ARRAY['95% AFUE','Condensing combi-boiler','3.4 GPM DHW','Compact wall-mount'], '{"afue": 95, "btu": 100000, "voltage": 120, "stages": "modulating", "type": "combi", "dhw_gpm": 3.4}'),
  ('NCB-180E', 'NCB-180E Combi-Boiler', 'NCB-E', 80000, 20, true, 3400, ARRAY['95% AFUE','Condensing combi-boiler','2.8 GPM DHW','Space-saving design'], '{"afue": 95, "btu": 80000, "voltage": 120, "stages": "modulating", "type": "combi", "dhw_gpm": 2.8}'),
  ('NHB-80', 'NHB-80 Heating Boiler', 'NHB', 80000, 25, true, 3200, ARRAY['95% AFUE','Condensing heating boiler','Stainless steel heat exchanger','Modulating burner'], '{"afue": 95, "btu": 80000, "voltage": 120, "stages": "modulating", "type": "wall-hung"}'),
  ('NHB-110', 'NHB-110 Heating Boiler', 'NHB', 110000, 25, true, 3600, ARRAY['95% AFUE','Condensing heating boiler','Stainless steel','Multi-zone capable'], '{"afue": 95, "btu": 110000, "voltage": 120, "stages": "modulating", "type": "wall-hung"}'),
  ('NHB-150', 'NHB-150 Heating Boiler', 'NHB', 150000, 25, true, 4200, ARRAY['95% AFUE','Condensing heating boiler','High output residential'], '{"afue": 95, "btu": 150000, "voltage": 120, "stages": "modulating", "type": "wall-hung"}'),
  ('NHB-199', 'NHB-199 Heating Boiler', 'NHB', 199000, 25, true, 4800, ARRAY['95% AFUE','Condensing heating boiler','Maximum residential output'], '{"afue": 95, "btu": 199000, "voltage": 120, "stages": "modulating", "type": "wall-hung"}'),
  ('NFB-200H', 'NFB-200H Fire Tube', 'NFB', 200000, 25, true, 6200, ARRAY['95% AFUE','Fire tube technology','Advanced burner system','Large capacity'], '{"afue": 95, "btu": 200000, "voltage": 120, "stages": "modulating", "type": "wall-hung"}'),
  ('NFB-301H', 'NFB-301H Fire Tube', 'NFB', 301000, 25, true, 7500, ARRAY['95% AFUE','Fire tube technology','High-output commercial/residential'], '{"afue": 95, "btu": 301000, "voltage": 120, "stages": "modulating", "type": "wall-hung"}')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs)
WHERE m.slug = 'navien' AND c.slug = 'hvac-boiler';

-- -------------------- PEERLESS BOILER --------------------

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'split-system', NULL, v.cap, 'btu', true, v.lifespan, false, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.peerlessboilers.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('PF-80', 'PureFire 80K BTU', 'PureFire', 'gas', 80000, 25, true, 4200, ARRAY['95% AFUE','Condensing wall-hung','Stainless steel heat exchanger','Modulating burner'], '{"afue": 95, "btu": 80000, "voltage": 120, "stages": "modulating", "type": "wall-hung"}'),
  ('PF-110', 'PureFire 110K BTU', 'PureFire', 'gas', 110000, 25, true, 4800, ARRAY['95% AFUE','Condensing wall-hung','Stainless steel','Multi-zone ready'], '{"afue": 95, "btu": 110000, "voltage": 120, "stages": "modulating", "type": "wall-hung"}'),
  ('PF-150', 'PureFire 150K BTU', 'PureFire', 'gas', 150000, 25, true, 5400, ARRAY['95% AFUE','Condensing wall-hung','High output'], '{"afue": 95, "btu": 150000, "voltage": 120, "stages": "modulating", "type": "wall-hung"}'),
  ('PF-200', 'PureFire 200K BTU', 'PureFire', 'gas', 200000, 25, true, 6200, ARRAY['95% AFUE','Condensing wall-hung','Maximum residential output'], '{"afue": 95, "btu": 200000, "voltage": 120, "stages": "modulating", "type": "wall-hung"}'),
  ('PF-C80', 'PureFire Combi 80K BTU', 'PureFire Combi', 'gas', 80000, 20, true, 4500, ARRAY['95% AFUE','Combi boiler','Space heating + 3.0 GPM DHW'], '{"afue": 95, "btu": 80000, "voltage": 120, "stages": "modulating", "type": "combi", "dhw_gpm": 3.0}'),
  ('PIN-II-4', 'Pinnacle II 4 Section 94K', 'Pinnacle II', 'gas', 94000, 30, true, 3800, ARRAY['92% AFUE','Cast iron floor-standing','Atmospheric draft','Sections: 4'], '{"afue": 92, "btu": 94000, "voltage": 120, "stages": "single", "type": "floor-standing", "sections": 4}'),
  ('PIN-II-5', 'Pinnacle II 5 Section 119K', 'Pinnacle II', 'gas', 119000, 30, true, 4200, ARRAY['92% AFUE','Cast iron floor-standing','Large capacity','Sections: 5'], '{"afue": 92, "btu": 119000, "voltage": 120, "stages": "single", "type": "floor-standing", "sections": 5}'),
  ('PIN-II-6', 'Pinnacle II 6 Section 145K', 'Pinnacle II', 'gas', 145000, 30, true, 4600, ARRAY['92% AFUE','Cast iron floor-standing','High output','Sections: 6'], '{"afue": 92, "btu": 145000, "voltage": 120, "stages": "single", "type": "floor-standing", "sections": 6}'),
  ('PV-3', 'Partner V 3 Section Oil 75K', 'Partner V', 'oil', 75000, 30, false, 2800, ARRAY['86% AFUE','Cast iron oil-fired','Floor-standing','3 sections'], '{"afue": 86, "btu": 75000, "voltage": 120, "stages": "single", "type": "floor-standing", "fuel": "oil"}'),
  ('PV-4', 'Partner V 4 Section Oil 105K', 'Partner V', 'oil', 105000, 30, false, 3200, ARRAY['86% AFUE','Cast iron oil-fired','Floor-standing','4 sections'], '{"afue": 86, "btu": 105000, "voltage": 120, "stages": "single", "type": "floor-standing", "fuel": "oil"}')
) AS v(model_number, model_name, series, fuel, cap, lifespan, estar, msrp, features, specs)
WHERE m.slug = 'peerless-boiler' AND c.slug = 'hvac-boiler';

-- ======================== ADDITIONAL AIR HANDLERS ========================

-- Carrier Air Handlers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'split-system', NULL, v.cap, 'tons', true, 15, v.wifi, false, v.msrp, v.features, v.specs::jsonb, 'https://www.carrier.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('FE4ANB003T00', 'Infinity FE4A 3-Ton AH', 'Infinity', 3, true, 2800, ARRAY['Variable-speed ECM blower','Infinity communicating','All-aluminum evaporator coil'], '{"tons": 3, "voltage": 208, "blower": "variable-speed"}'),
  ('FE4ANB004T00', 'Infinity FE4A 4-Ton AH', 'Infinity', 4, true, 3200, ARRAY['Variable-speed ECM blower','Infinity communicating','Multi-position install'], '{"tons": 4, "voltage": 208, "blower": "variable-speed"}'),
  ('FE5ANB003L00', 'Performance FE5A 3-Ton AH', 'Performance', 3, false, 1800, ARRAY['Multi-speed blower','Multi-position install','Factory-installed TXV'], '{"tons": 3, "voltage": 208, "blower": "multi-speed"}'),
  ('FE5ANB004L00', 'Performance FE5A 4-Ton AH', 'Performance', 4, false, 2100, ARRAY['Multi-speed blower','Multi-position install'], '{"tons": 4, "voltage": 208, "blower": "multi-speed"}')
) AS v(model_number, model_name, series, cap, wifi, msrp, features, specs)
WHERE m.slug = 'carrier' AND c.slug = 'hvac-air-handler';

-- Trane Air Handlers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'split-system', NULL, v.cap, 'tons', true, 15, v.wifi, false, v.msrp, v.features, v.specs::jsonb, 'https://www.trane.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('GAM5A0C36M31SA', 'Hyperion XV 3-Ton AH', 'Hyperion', 3, true, 3200, ARRAY['Variable-speed ECM','ComfortLink II communicating','All-aluminum coil'], '{"tons": 3, "voltage": 208, "blower": "variable-speed"}'),
  ('GAM5A0C48M41SA', 'Hyperion XV 4-Ton AH', 'Hyperion', 4, true, 3600, ARRAY['Variable-speed ECM','ComfortLink II','Multi-position'], '{"tons": 4, "voltage": 208, "blower": "variable-speed"}'),
  ('TAM9A0C36V31CA', 'TAM9 3-Ton AH', 'TAM9', 3, true, 2200, ARRAY['Variable-speed ECM blower','All-aluminum evaporator','Upflow/downflow'], '{"tons": 3, "voltage": 208, "blower": "variable-speed"}'),
  ('TAM7A0C36H31CA', 'TAM7 3-Ton AH', 'TAM7', 3, false, 1600, ARRAY['Multi-speed blower','All-aluminum coil','Multi-position install'], '{"tons": 3, "voltage": 208, "blower": "multi-speed"}')
) AS v(model_number, model_name, series, cap, wifi, msrp, features, specs)
WHERE m.slug = 'trane' AND c.slug = 'hvac-air-handler';

-- Lennox Air Handlers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'split-system', NULL, v.cap, 'tons', true, 15, v.wifi, false, v.msrp, v.features, v.specs::jsonb, 'https://www.lennox.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('CBA38MV-036-230', 'CBA38MV 3-Ton AH', 'Dave Lennox Signature', 3, true, 3000, ARRAY['Variable-speed ECM blower','iComfort enabled','All-aluminum coil','Quiet operation'], '{"tons": 3, "voltage": 208, "blower": "variable-speed"}'),
  ('CBA38MV-048-230', 'CBA38MV 4-Ton AH', 'Dave Lennox Signature', 4, true, 3400, ARRAY['Variable-speed ECM','iComfort enabled','Multi-position install'], '{"tons": 4, "voltage": 208, "blower": "variable-speed"}'),
  ('CBA27UH-036-230', 'CBA27UH 3-Ton AH', 'Elite', 3, false, 2000, ARRAY['Multi-speed blower','Upflow/horizontal install','Factory TXV'], '{"tons": 3, "voltage": 208, "blower": "multi-speed"}'),
  ('CBX27UH-036-230', 'CBX27UH 3-Ton AH', 'Merit', 3, false, 1400, ARRAY['Multi-speed blower','Upflow/horizontal','Entry-level air handler'], '{"tons": 3, "voltage": 208, "blower": "multi-speed"}')
) AS v(model_number, model_name, series, cap, wifi, msrp, features, specs)
WHERE m.slug = 'lennox' AND c.slug = 'hvac-air-handler';

-- Daikin Air Handlers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'split-system', NULL, v.cap, 'tons', true, 15, false, false, v.msrp, v.features, v.specs::jsonb, 'https://www.daikincomfort.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DAVPTC49D14', 'DAVPTC 4-Ton AH', 'DAVPTC', 4, 1900, ARRAY['Variable-speed ECM blower','Multi-position install','All-aluminum evaporator'], '{"tons": 4, "voltage": 208, "blower": "variable-speed"}'),
  ('DAVPTC37C14', 'DAVPTC 3-Ton AH', 'DAVPTC', 3, 1600, ARRAY['Variable-speed ECM blower','Factory-installed TXV'], '{"tons": 3, "voltage": 208, "blower": "variable-speed"}'),
  ('DAMST36CU1400', 'DAMST 3-Ton AH', 'DAMST', 3, 1200, ARRAY['Multi-speed blower','Multi-position install'], '{"tons": 3, "voltage": 208, "blower": "multi-speed"}')
) AS v(model_number, model_name, series, cap, msrp, features, specs)
WHERE m.slug = 'daikin' AND c.slug = 'hvac-air-handler';

-- ======================== ADDITIONAL PACKAGED UNITS ========================

-- Carrier Packaged Units
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'packaged', NULL, v.cap, 'tons', true, 15, false, true, v.msrp, v.features, v.specs::jsonb, 'https://www.carrier.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('48LCDA04A2A5', 'Infinity 48LCD Packaged 3T', 'Infinity', 'dual-fuel', 3, 6800, ARRAY['Up to 16 SEER','Packaged gas/electric','Dual-fuel option','Rooftop or pad mount'], '{"seer": 16, "tons": 3, "afue": 80, "voltage": 208, "stages": "two-stage"}'),
  ('48LCDA05A2A5', 'Infinity 48LCD Packaged 4T', 'Infinity', 'dual-fuel', 4, 7400, ARRAY['Up to 16 SEER','Packaged gas/electric','Dual-fuel','Large capacity'], '{"seer": 16, "tons": 4, "afue": 80, "voltage": 208, "stages": "two-stage"}'),
  ('50XCA036', 'Performance 50XCA Packaged 3T', 'Performance', 'electric', 3, 4200, ARRAY['Up to 15 SEER','All-electric packaged AC','Pad mount or rooftop'], '{"seer": 15, "tons": 3, "voltage": 208, "stages": "single"}'),
  ('50XCA048', 'Performance 50XCA Packaged 4T', 'Performance', 'electric', 4, 4800, ARRAY['Up to 15 SEER','All-electric packaged','Large capacity'], '{"seer": 15, "tons": 4, "voltage": 208, "stages": "single"}')
) AS v(model_number, model_name, series, fuel, cap, msrp, features, specs)
WHERE m.slug = 'carrier' AND c.slug = 'hvac-central-ac';

-- Goodman Packaged Units
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'packaged', NULL, v.cap, 'tons', true, 15, false, true, v.msrp, v.features, v.specs::jsonb, 'https://www.goodmanmfg.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('GPG1636080M41', 'GPG16 3-Ton Packaged Gas/Electric', 'GPG16', 'dual-fuel', 3, 3800, ARRAY['Up to 16 SEER','Packaged gas/electric','80K BTU furnace section','All-in-one'], '{"seer": 16, "tons": 3, "afue": 80, "btu": 80000, "voltage": 208, "stages": "single"}'),
  ('GPC1536H41', 'GPC15 3-Ton Packaged AC', 'GPC15', 'electric', 3, 2800, ARRAY['Up to 15 SEER','All-electric packaged','Horizontal discharge'], '{"seer": 15, "tons": 3, "voltage": 208, "stages": "single"}'),
  ('GPH1636H41', 'GPH16 3-Ton Packaged HP', 'GPH16', 'electric', 3, 3200, ARRAY['Up to 16 SEER','Packaged heat pump','Heating and cooling in one unit'], '{"seer": 16, "hspf": 8.5, "tons": 3, "voltage": 208, "stages": "single"}')
) AS v(model_number, model_name, series, fuel, cap, msrp, features, specs)
WHERE m.slug = 'goodman' AND c.slug = 'hvac-central-ac';

-- ======================== ADDITIONAL MINI-SPLITS (MAINSTREAM BRANDS) ========================

-- Carrier Ductless Mini-Splits
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', v.install, NULL, v.cap, 'btu', true, 15, true, true, v.msrp, v.features, v.specs::jsonb, 'https://www.carrier.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('38MARBQ093', 'Performance 9K BTU Mini-Split', 'Performance', 9000, 'wall-mount', 2000, ARRAY['Up to 27.0 SEER','Inverter compressor','WiFi enabled','Heating to -4F'], '{"seer": 27.0, "hspf": 12.0, "btu": 9000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}'),
  ('38MARBQ123', 'Performance 12K BTU Mini-Split', 'Performance', 12000, 'wall-mount', 2400, ARRAY['Up to 24.6 SEER','Inverter compressor','WiFi enabled'], '{"seer": 24.6, "hspf": 11.5, "btu": 12000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}'),
  ('38MARBQ183', 'Performance 18K BTU Mini-Split', 'Performance', 18000, 'wall-mount', 3000, ARRAY['Up to 22.0 SEER','Inverter compressor','Large room coverage'], '{"seer": 22.0, "hspf": 10.5, "btu": 18000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}'),
  ('38MGQF36', 'Infinity 3-Zone 36K Multi-Split', 'Infinity', 36000, 'ductless', 6200, ARRAY['Up to 22.7 SEER','3-zone multi-split','Greenspeed Intelligence','Inverter'], '{"seer": 22.7, "hspf": 11.0, "btu": 36000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 3}')
) AS v(model_number, model_name, series, cap, install, msrp, features, specs)
WHERE m.slug = 'carrier' AND c.slug = 'hvac-mini-split';

-- Lennox Ductless Mini-Splits
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', v.install, NULL, v.cap, 'btu', true, 15, true, true, v.msrp, v.features, v.specs::jsonb, 'https://www.lennox.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('MHA009S4S-1P', 'MHA 9K BTU Mini-Split', 'Mini-Split', 9000, 'wall-mount', 2200, ARRAY['Up to 28.6 SEER','Inverter compressor','WiFi included','Quiet: 20 dB'], '{"seer": 28.6, "hspf": 12.5, "btu": 9000, "voltage": 115, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}'),
  ('MHA012S4S-1P', 'MHA 12K BTU Mini-Split', 'Mini-Split', 12000, 'wall-mount', 2600, ARRAY['Up to 25.0 SEER','Inverter compressor','WiFi included'], '{"seer": 25.0, "hspf": 12.0, "btu": 12000, "voltage": 115, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}'),
  ('MHA018S4S-1P', 'MHA 18K BTU Mini-Split', 'Mini-Split', 18000, 'wall-mount', 3200, ARRAY['Up to 22.0 SEER','Inverter compressor','Large room coverage'], '{"seer": 22.0, "hspf": 11.0, "btu": 18000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}'),
  ('MPA036S4M-1P', 'MPA 3-Zone 36K Multi-Split', 'Multi-Zone', 36000, 'ductless', 5800, ARRAY['Up to 22.0 SEER','3-zone outdoor unit','Inverter driven'], '{"seer": 22.0, "hspf": 11.0, "btu": 36000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 3}')
) AS v(model_number, model_name, series, cap, install, msrp, features, specs)
WHERE m.slug = 'lennox' AND c.slug = 'hvac-mini-split';

-- Rheem Ductless Mini-Splits
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'wall-mount', NULL, v.cap, 'btu', true, 15, true, true, v.msrp, v.features, v.specs::jsonb, 'https://www.rheem.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DERA09AZ-H', 'Mini-Split 9K BTU', 'Classic Plus', 9000, 1800, ARRAY['Up to 25.0 SEER','Inverter compressor','Heating to -4F','WiFi capable'], '{"seer": 25.0, "hspf": 12.0, "btu": 9000, "voltage": 115, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}'),
  ('DERA12AZ-H', 'Mini-Split 12K BTU', 'Classic Plus', 12000, 2200, ARRAY['Up to 22.0 SEER','Inverter compressor','WiFi capable'], '{"seer": 22.0, "hspf": 11.0, "btu": 12000, "voltage": 115, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}'),
  ('DERA18AZ-H', 'Mini-Split 18K BTU', 'Classic Plus', 18000, 2800, ARRAY['Up to 20.0 SEER','Inverter compressor','Large room coverage'], '{"seer": 20.0, "hspf": 10.5, "btu": 18000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}'),
  ('DERA24AZ-H', 'Mini-Split 24K BTU', 'Classic Plus', 24000, 3200, ARRAY['Up to 19.0 SEER','Inverter compressor','Maximum single-zone coverage'], '{"seer": 19.0, "hspf": 10.0, "btu": 24000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}')
) AS v(model_number, model_name, series, cap, msrp, features, specs)
WHERE m.slug = 'rheem' AND c.slug = 'hvac-mini-split';

-- Trane Mini-Splits
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'wall-mount', NULL, v.cap, 'btu', true, 15, true, true, v.msrp, v.features, v.specs::jsonb, 'https://www.trane.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('4MXW6509A10N', 'Ductless 9K BTU', '4MXW6', 9000, 2000, ARRAY['Up to 25.0 SEER','Inverter compressor','ComfortLink compatible','Quiet: 21 dB'], '{"seer": 25.0, "hspf": 12.0, "btu": 9000, "voltage": 115, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}'),
  ('4MXW6512A10N', 'Ductless 12K BTU', '4MXW6', 12000, 2400, ARRAY['Up to 22.0 SEER','Inverter compressor','WiFi enabled'], '{"seer": 22.0, "hspf": 11.0, "btu": 12000, "voltage": 115, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}'),
  ('4MXW6518A10N', 'Ductless 18K BTU', '4MXW6', 18000, 3000, ARRAY['Up to 20.0 SEER','Inverter compressor','Large room coverage'], '{"seer": 20.0, "hspf": 10.5, "btu": 18000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}')
) AS v(model_number, model_name, series, cap, msrp, features, specs)
WHERE m.slug = 'trane' AND c.slug = 'hvac-mini-split';

-- ======================== ADDITIONAL COVERAGE FOR 400+ TARGET ========================

-- York Heat Pump Mini-Splits
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'wall-mount', NULL, v.cap, 'btu', true, 15, true, true, v.msrp, v.features, v.specs::jsonb, 'https://www.york.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DHM09NWM09', 'YE2 9K BTU Mini-Split', 'YE2', 9000, 1800, ARRAY['Up to 25.0 SEER','Inverter compressor','Heating to -4F','WiFi enabled'], '{"seer": 25.0, "hspf": 12.0, "btu": 9000, "voltage": 115, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}'),
  ('DHM12NWM12', 'YE2 12K BTU Mini-Split', 'YE2', 12000, 2200, ARRAY['Up to 22.0 SEER','Inverter compressor','WiFi enabled'], '{"seer": 22.0, "hspf": 11.0, "btu": 12000, "voltage": 115, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}'),
  ('DHM18NWM18', 'YE2 18K BTU Mini-Split', 'YE2', 18000, 2800, ARRAY['Up to 20.0 SEER','Inverter compressor','Large room coverage'], '{"seer": 20.0, "hspf": 10.5, "btu": 18000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}'),
  ('DHM24NWM24', 'YE2 24K BTU Mini-Split', 'YE2', 24000, 3200, ARRAY['Up to 19.0 SEER','Inverter compressor','Maximum coverage'], '{"seer": 19.0, "hspf": 10.0, "btu": 24000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}')
) AS v(model_number, model_name, series, cap, msrp, features, specs)
WHERE m.slug = 'york' AND c.slug = 'hvac-mini-split';

-- Bryant Mini-Splits
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'wall-mount', NULL, v.cap, 'btu', true, 15, true, true, v.msrp, v.features, v.specs::jsonb, 'https://www.bryant.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('619PBQ009', 'Evolution 9K BTU Mini-Split', 'Evolution', 9000, 2200, ARRAY['Up to 28.0 SEER','Inverter compressor','WiFi built-in','Quiet: 20 dB'], '{"seer": 28.0, "hspf": 12.5, "btu": 9000, "voltage": 115, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}'),
  ('619PBQ012', 'Evolution 12K BTU Mini-Split', 'Evolution', 12000, 2600, ARRAY['Up to 24.6 SEER','Inverter compressor','WiFi built-in'], '{"seer": 24.6, "hspf": 11.5, "btu": 12000, "voltage": 115, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}'),
  ('619PBQ018', 'Evolution 18K BTU Mini-Split', 'Evolution', 18000, 3200, ARRAY['Up to 22.0 SEER','Inverter compressor','Large room coverage'], '{"seer": 22.0, "hspf": 11.0, "btu": 18000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}')
) AS v(model_number, model_name, series, cap, msrp, features, specs)
WHERE m.slug = 'bryant' AND c.slug = 'hvac-mini-split';

-- Additional Goodman/Daikin Mini-Splits
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'wall-mount', NULL, v.cap, 'btu', true, 15, false, true, v.msrp, v.features, v.specs::jsonb, 'https://www.goodmanmfg.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('MSA093E19', 'MSA 9K BTU Mini-Split', 'MSA', 9000, 1200, ARRAY['Up to 19 SEER','Inverter compressor','Entry-level ductless'], '{"seer": 19, "hspf": 10.0, "btu": 9000, "voltage": 115, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}'),
  ('MSA123E19', 'MSA 12K BTU Mini-Split', 'MSA', 12000, 1500, ARRAY['Up to 19 SEER','Inverter compressor','Budget ductless'], '{"seer": 19, "hspf": 10.0, "btu": 12000, "voltage": 115, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}'),
  ('MSA183E19', 'MSA 18K BTU Mini-Split', 'MSA', 18000, 1900, ARRAY['Up to 19 SEER','Inverter compressor','Large room'], '{"seer": 19, "hspf": 10.0, "btu": 18000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}'),
  ('MSA243E19', 'MSA 24K BTU Mini-Split', 'MSA', 24000, 2200, ARRAY['Up to 18 SEER','Inverter compressor','Maximum coverage'], '{"seer": 18, "hspf": 9.5, "btu": 24000, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter", "zones": 1}')
) AS v(model_number, model_name, series, cap, msrp, features, specs)
WHERE m.slug = 'goodman' AND c.slug = 'hvac-mini-split';

-- Additional Mitsubishi Air Handlers (Ducted)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'split-system', NULL, v.cap, 'btu', true, 15, true, true, v.msrp, v.features, v.specs::jsonb, 'https://www.mitsubishicomfort.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('SVZ-KP12NA', 'SVZ-KP12 12K BTU Ducted AH', 'KP-Series', 12000, 2400, ARRAY['Variable-speed ECM','Concealed ducted','Hyper-Heat compatible','Ultra-quiet'], '{"btu": 12000, "voltage": 208, "blower": "variable-speed"}'),
  ('SVZ-KP18NA', 'SVZ-KP18 18K BTU Ducted AH', 'KP-Series', 18000, 2800, ARRAY['Variable-speed ECM','Concealed ducted','Multi-position'], '{"btu": 18000, "voltage": 208, "blower": "variable-speed"}'),
  ('SVZ-KP24NA', 'SVZ-KP24 24K BTU Ducted AH', 'KP-Series', 24000, 3200, ARRAY['Variable-speed ECM','Concealed ducted','Large capacity'], '{"btu": 24000, "voltage": 208, "blower": "variable-speed"}'),
  ('SVZ-KP30NA', 'SVZ-KP30 30K BTU Ducted AH', 'KP-Series', 30000, 3600, ARRAY['Variable-speed ECM','Concealed ducted','Whole-zone solution'], '{"btu": 30000, "voltage": 208, "blower": "variable-speed"}'),
  ('SVZ-KP36NA', 'SVZ-KP36 36K BTU Ducted AH', 'KP-Series', 36000, 4000, ARRAY['Variable-speed ECM','Concealed ducted','Maximum capacity'], '{"btu": 36000, "voltage": 208, "blower": "variable-speed"}')
) AS v(model_number, model_name, series, cap, msrp, features, specs)
WHERE m.slug = 'mitsubishi-electric' AND c.slug = 'hvac-air-handler';

-- Viessmann Heat Pumps (expanding beyond boilers)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'split-system', NULL, v.cap, 'tons', true, 15, true, true, v.msrp, v.features, v.specs::jsonb, 'https://www.viessmann.us'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('VITOCAL-200-A-06', 'Vitocal 200-A 2-Ton HP', 'Vitocal 200-A', 2, 8500, ARRAY['Up to 19 SEER','Air-source heat pump','German engineering','Heating to -13F','R-32 refrigerant'], '{"seer": 19, "hspf": 11.0, "tons": 2, "voltage": 208, "refrigerant": "R-32", "stages": "variable", "compressor": "inverter"}'),
  ('VITOCAL-200-A-09', 'Vitocal 200-A 3-Ton HP', 'Vitocal 200-A', 3, 10200, ARRAY['Up to 18 SEER','Air-source heat pump','German engineering','Heating to -13F'], '{"seer": 18, "hspf": 10.5, "tons": 3, "voltage": 208, "refrigerant": "R-32", "stages": "variable", "compressor": "inverter"}'),
  ('VITOCAL-200-A-12', 'Vitocal 200-A 4-Ton HP', 'Vitocal 200-A', 4, 12000, ARRAY['Up to 17 SEER','Air-source heat pump','Large capacity','German engineering'], '{"seer": 17, "hspf": 10.0, "tons": 4, "voltage": 208, "refrigerant": "R-32", "stages": "variable", "compressor": "inverter"}'),
  ('VITOCAL-250-A-09', 'Vitocal 250-A 3-Ton HP', 'Vitocal 250-A', 3, 14000, ARRAY['Up to 20 SEER','Premium air-source HP','R-290 natural refrigerant','Heating to -22F','Ultra-premium'], '{"seer": 20, "hspf": 12.0, "tons": 3, "voltage": 208, "refrigerant": "R-290", "stages": "variable", "compressor": "inverter"}')
) AS v(model_number, model_name, series, cap, msrp, features, specs)
WHERE m.slug = 'viessmann' AND c.slug = 'hvac-heat-pump';

-- Additional Navien Combi-Boilers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'gas', 'split-system', NULL, v.cap, 'btu', true, v.lifespan, true, true, v.msrp, v.features, v.specs::jsonb, 'https://www.navien.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('NCB-240-SE', 'NCB-240-SE Premium Combi', 'NCB-SE', 120000, 20, 5200, ARRAY['95% thermal efficiency','Premium combi-boiler','Stainless dual heat exchangers','NaviLink WiFi','4.0 GPM DHW'], '{"afue": 95, "btu": 120000, "voltage": 120, "stages": "modulating", "type": "combi", "dhw_gpm": 4.0}'),
  ('NCB-210-SE', 'NCB-210-SE Premium Combi', 'NCB-SE', 100000, 20, 4800, ARRAY['95% thermal efficiency','Premium combi-boiler','Dual stainless exchangers','NaviLink WiFi'], '{"afue": 95, "btu": 100000, "voltage": 120, "stages": "modulating", "type": "combi", "dhw_gpm": 3.4}'),
  ('NFC-H-200', 'NFC 200K Fire Tube', 'NFC', 200000, 25, 5800, ARRAY['95% AFUE','Fire tube boiler','Advanced stainless steel heat exchanger','NaviLink WiFi'], '{"afue": 95, "btu": 200000, "voltage": 120, "stages": "modulating", "type": "wall-hung"}')
) AS v(model_number, model_name, series, cap, lifespan, msrp, features, specs)
WHERE m.slug = 'navien' AND c.slug = 'hvac-boiler';

-- Heil Heat Pumps
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'split-system', NULL, v.cap, 'tons', true, 15, v.wifi, true, v.msrp, v.features, v.specs::jsonb, 'https://www.heil-hvac.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('HVA919GKA', 'QuietComfort Deluxe 19 3T HP', 'QuietComfort Deluxe', 3, true, 4600, ARRAY['Up to 19 SEER','Two-stage compressor','Observer communicating','Heating to -10F'], '{"seer": 19, "hspf": 10.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage"}'),
  ('HVH736GKA', 'QuietComfort 17 3T HP', 'QuietComfort', 3, false, 3400, ARRAY['Up to 17 SEER','Two-stage compressor','Sound: 72 dB'], '{"seer": 17, "hspf": 9.5, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage"}'),
  ('HSH636GKA', 'Performance 16 3T HP', 'Performance', 3, false, 2600, ARRAY['Up to 16 SEER','Single-stage','Scroll compressor'], '{"seer": 16, "hspf": 9.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}')
) AS v(model_number, model_name, series, cap, wifi, msrp, features, specs)
WHERE m.slug = 'heil' AND c.slug = 'hvac-heat-pump';

-- Coleman Heat Pumps
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'split-system', NULL, v.cap, 'tons', true, 15, v.wifi, true, v.msrp, v.features, v.specs::jsonb, 'https://www.colemanac.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DERP036S', 'Echelon 20 3-Ton HP', 'Echelon', 3, true, 5800, ARRAY['Up to 20 SEER','Variable-speed inverter','Quiet Drive system'], '{"seer": 20, "hspf": 11.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "variable", "compressor": "inverter"}'),
  ('DCRP036S', 'LX 17 3-Ton HP', 'LX', 3, true, 4000, ARRAY['Up to 17 SEER','Two-stage compressor','ClimaTrak system'], '{"seer": 17, "hspf": 9.5, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "two-stage"}'),
  ('TCHD36S41S3', 'TC 16 3-Ton HP', 'TC', 3, false, 2800, ARRAY['Up to 16 SEER','Single-stage','Scroll compressor'], '{"seer": 16, "hspf": 9.0, "tons": 3, "voltage": 208, "refrigerant": "R-410A", "stages": "single"}')
) AS v(model_number, model_name, series, cap, wifi, msrp, features, specs)
WHERE m.slug = 'coleman-hvac' AND c.slug = 'hvac-heat-pump';

-- ============================================================================
-- End of HVAC Equipment Catalog
-- ============================================================================
