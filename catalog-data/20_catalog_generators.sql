SET ROLE postgres;
-- ============================================================================
-- Equipment Catalog: Generators & Power Stations
-- 250+ models across 18 brands
-- ============================================================================

-- ============================================================================
-- GENERAC  (Standby + Portable + Inverter)
-- ============================================================================

-- Generac Standby Generators (Gas/LP)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'standby', NULL, v.cap, 'watts', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('7290',  '26kW Guardian',        'Guardian',   'natural_gas', 26000, 25, true, 7599,  ARRAY['Whole-home backup','200A SE transfer switch','Wi-Fi enabled','Quiet-Test mode','True Power Technology'], '{"watts_starting": 26000, "transfer_switch": "200A SE", "fuel_type": "natural_gas", "exercise_schedule": true, "mobile_monitoring": true, "noise_dba": 66}', 'https://www.generac.com/all-products/generators/home-backup-generators/guardian-series'),
  ('7228',  '18kW Guardian',        'Guardian',   'natural_gas', 18000, 25, true, 5699,  ARRAY['Whole-home backup','200A SE transfer switch','Wi-Fi enabled','Quiet-Test mode'], '{"watts_starting": 18000, "transfer_switch": "200A SE", "fuel_type": "natural_gas", "exercise_schedule": true, "mobile_monitoring": true, "noise_dba": 67}', 'https://www.generac.com/all-products/generators/home-backup-generators/guardian-series'),
  ('7291',  '24kW Guardian',        'Guardian',   'natural_gas', 24000, 25, true, 6899,  ARRAY['Whole-home backup','200A SE transfer switch','Wi-Fi enabled','Quiet-Test mode'], '{"watts_starting": 24000, "transfer_switch": "200A SE", "fuel_type": "natural_gas", "exercise_schedule": true, "mobile_monitoring": true, "noise_dba": 66}', 'https://www.generac.com/all-products/generators/home-backup-generators/guardian-series'),
  ('7226',  '16kW Guardian',        'Guardian',   'natural_gas', 16000, 25, true, 5199,  ARRAY['Whole-home backup','200A transfer switch','Wi-Fi enabled','Quiet-Test mode'], '{"watts_starting": 16000, "transfer_switch": "200A", "fuel_type": "natural_gas", "exercise_schedule": true, "mobile_monitoring": true, "noise_dba": 67}', 'https://www.generac.com/all-products/generators/home-backup-generators/guardian-series'),
  ('7224',  '14kW Guardian',        'Guardian',   'natural_gas', 14000, 25, true, 4799,  ARRAY['Managed whole-home backup','200A transfer switch','Wi-Fi enabled'], '{"watts_starting": 14000, "transfer_switch": "200A", "fuel_type": "natural_gas", "exercise_schedule": true, "mobile_monitoring": true, "noise_dba": 67}', 'https://www.generac.com/all-products/generators/home-backup-generators/guardian-series'),
  ('7042',  '22kW Guardian',        'Guardian',   'natural_gas', 22000, 25, true, 5999,  ARRAY['Whole-home backup','200A SE transfer switch','Wi-Fi enabled','Quiet-Test mode'], '{"watts_starting": 22000, "transfer_switch": "200A SE", "fuel_type": "natural_gas", "exercise_schedule": true, "mobile_monitoring": true, "noise_dba": 67}', 'https://www.generac.com/all-products/generators/home-backup-generators/guardian-series'),
  ('7043',  '22kW Guardian (Alum)', 'Guardian',   'natural_gas', 22000, 25, true, 5799,  ARRAY['Aluminum enclosure','200A SE transfer switch','Wi-Fi enabled'], '{"watts_starting": 22000, "transfer_switch": "200A SE", "fuel_type": "natural_gas", "exercise_schedule": true, "mobile_monitoring": true, "noise_dba": 67}', 'https://www.generac.com/all-products/generators/home-backup-generators/guardian-series'),
  ('7171',  '10kW Guardian',        'Guardian',   'natural_gas', 10000, 25, true, 3599,  ARRAY['Essential circuit backup','100A 16-circuit transfer switch','Wi-Fi enabled'], '{"watts_starting": 10000, "transfer_switch": "100A 16-circuit", "fuel_type": "natural_gas", "exercise_schedule": true, "mobile_monitoring": true, "noise_dba": 67}', 'https://www.generac.com/all-products/generators/home-backup-generators/guardian-series'),
  ('7172',  '10kW Guardian (Alum)', 'Guardian',   'natural_gas', 10000, 25, true, 3399,  ARRAY['Aluminum enclosure','100A transfer switch','Wi-Fi enabled'], '{"watts_starting": 10000, "transfer_switch": "100A", "fuel_type": "natural_gas", "exercise_schedule": true, "mobile_monitoring": true, "noise_dba": 67}', 'https://www.generac.com/all-products/generators/home-backup-generators/guardian-series'),
  ('7209',  '24kW Protector',       'Protector',  'natural_gas', 24000, 25, true, 7999,  ARRAY['Diesel/NG standby','Aluminum enclosure','Wi-Fi enabled','Exercise schedule'], '{"watts_starting": 24000, "transfer_switch": "200A", "fuel_type": "natural_gas", "exercise_schedule": true, "mobile_monitoring": true, "noise_dba": 64}', 'https://www.generac.com/all-products/generators/home-backup-generators'),
  ('7046',  '20kW Guardian',        'Guardian',   'natural_gas', 20000, 25, true, 5499,  ARRAY['Whole-home backup','200A SE transfer switch','Wi-Fi enabled'], '{"watts_starting": 20000, "transfer_switch": "200A SE", "fuel_type": "natural_gas", "exercise_schedule": true, "mobile_monitoring": true, "noise_dba": 67}', 'https://www.generac.com/all-products/generators/home-backup-generators/guardian-series')
) AS v(model_number, model_name, series, fuel, cap, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'generac' AND c.slug = 'generator-standby-gas';

-- Generac Portable Generators
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'portable', NULL, v.cap, 'watts', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, 'https://www.generac.com/all-products/generators/portable-generators'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('7690',  '8000W GP8000E',    'GP',   'gas',       8000,  12, 999,  ARRAY['Electric start','10000W starting','8-gallon tank','Hour meter','Never-Flat wheels'], '{"watts_starting": 10000, "runtime_hours_50pct": 11, "noise_dba": 74, "fuel_tank_gallons": 8, "outlets": "4x120V 1x120/240V", "parallel_capable": false, "co_shutoff": false}'),
  ('7680',  '6500W GP6500',     'GP',   'gas',       6500,  12, 849,  ARRAY['Recoil start','8125W starting','6.9-gallon tank'], '{"watts_starting": 8125, "runtime_hours_50pct": 10, "noise_dba": 74, "fuel_tank_gallons": 6.9, "outlets": "4x120V 1x120/240V", "parallel_capable": false, "co_shutoff": false}'),
  ('7682',  '5500W GP5500',     'GP',   'gas',       5500,  12, 749,  ARRAY['Recoil start','6875W starting','7.2-gallon tank'], '{"watts_starting": 6875, "runtime_hours_50pct": 10, "noise_dba": 74, "fuel_tank_gallons": 7.2, "outlets": "4x120V 1x120/240V", "parallel_capable": false, "co_shutoff": false}'),
  ('7678',  '3600W GP3600',     'GP',   'gas',       3600,  12, 549,  ARRAY['Recoil start','4500W starting','Compact design'], '{"watts_starting": 4500, "runtime_hours_50pct": 9, "noise_dba": 72, "fuel_tank_gallons": 4.5, "outlets": "3x120V", "parallel_capable": false, "co_shutoff": false}'),
  ('7719',  '15000W XC8000E',   'XC',   'gas',       8000,  15, 1899, ARRAY['Electric start','CO-Sense shutoff','GFCI outlets','PowerRush Advanced Technology'], '{"watts_starting": 10000, "runtime_hours_50pct": 10.5, "noise_dba": 73, "fuel_tank_gallons": 8, "outlets": "4x120V GFCI 1x120/240V", "parallel_capable": false, "co_shutoff": true}')
) AS v(model_number, model_name, series, fuel, cap, lifespan, msrp, features, specs)
WHERE m.slug = 'generac' AND c.slug = 'generator-portable';

-- Generac Inverter Generators
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'portable', NULL, v.cap, 'watts', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, 'https://www.generac.com/all-products/generators/inverter-generators'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('7127',  '3000W iQ3500',    'iQ',       'gas', 3000, 12, 1399, ARRAY['Inverter technology','Super quiet','Electric start','LED display','Parallel capable','PowerRush'], '{"watts_starting": 3500, "runtime_hours_50pct": 14.1, "noise_dba": 54, "fuel_tank_gallons": 2.37, "outlets": "2x120V 1xUSB", "parallel_capable": true, "co_shutoff": false}'),
  ('8174',  '4500W GP4500iE',  'GP',       'gas', 3700, 12, 1199, ARRAY['Open-frame inverter','Electric start','CO-Sense safety shutoff'], '{"watts_starting": 4500, "runtime_hours_50pct": 14, "noise_dba": 64, "fuel_tank_gallons": 3.4, "outlets": "2x120V 1x120/240V", "parallel_capable": true, "co_shutoff": true}'),
  ('7154',  '2200W GP2200i',   'GP',       'gas', 1700, 12, 549,  ARRAY['Compact inverter','TruePower Technology','Parallel capable','Economy mode'], '{"watts_starting": 2200, "runtime_hours_50pct": 10.75, "noise_dba": 57, "fuel_tank_gallons": 1.2, "outlets": "2x120V 1xUSB", "parallel_capable": true, "co_shutoff": false}'),
  ('7118',  '2000W iQ2000',    'iQ',       'gas', 1600, 12, 799,  ARRAY['Super quiet inverter','LED display','PowerDial','Parallel capable'], '{"watts_starting": 2000, "runtime_hours_50pct": 7.7, "noise_dba": 51, "fuel_tank_gallons": 1.06, "outlets": "2x120V 1xUSB", "parallel_capable": true, "co_shutoff": false}')
) AS v(model_number, model_name, series, fuel, cap, lifespan, msrp, features, specs)
WHERE m.slug = 'generac' AND c.slug = 'generator-inverter';


-- ============================================================================
-- KOHLER GENERATORS  (Standby)
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'standby', NULL, v.cap, 'watts', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, 'https://www.kohlerpower.com/home-generators'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('26RCAL',  '26kW Standby',          NULL,     'natural_gas', 26000, 25, true, 7999,  ARRAY['Whole-home backup','200A SE transfer switch','OnCue Plus monitoring','Corrosion-resistant enclosure','5-year warranty'], '{"watts_starting": 26000, "transfer_switch": "200A SE", "fuel_type": "natural_gas", "exercise_schedule": true, "mobile_monitoring": true, "noise_dba": 66}'),
  ('24RCAL',  '24kW Standby',          NULL,     'natural_gas', 24000, 25, true, 6999,  ARRAY['Whole-home backup','200A SE transfer switch','OnCue Plus monitoring','Corrosion-resistant enclosure'], '{"watts_starting": 24000, "transfer_switch": "200A SE", "fuel_type": "natural_gas", "exercise_schedule": true, "mobile_monitoring": true, "noise_dba": 66}'),
  ('20RCAL',  '20kW Standby',          NULL,     'natural_gas', 20000, 25, true, 5999,  ARRAY['Whole-home backup','200A SE transfer switch','OnCue Plus monitoring'], '{"watts_starting": 20000, "transfer_switch": "200A SE", "fuel_type": "natural_gas", "exercise_schedule": true, "mobile_monitoring": true, "noise_dba": 67}'),
  ('14RCAL',  '14kW Standby',          NULL,     'natural_gas', 14000, 25, true, 4999,  ARRAY['Essential circuit backup','200A transfer switch','OnCue Plus monitoring'], '{"watts_starting": 14000, "transfer_switch": "200A", "fuel_type": "natural_gas", "exercise_schedule": true, "mobile_monitoring": true, "noise_dba": 69}'),
  ('12RESV',  '12kW Standby',          NULL,     'natural_gas', 12000, 25, true, 4299,  ARRAY['RDC2 controller','OnCue Plus monitoring','Compact enclosure'], '{"watts_starting": 12000, "transfer_switch": "200A", "fuel_type": "natural_gas", "exercise_schedule": true, "mobile_monitoring": true, "noise_dba": 69}'),
  ('10RESV',  '10kW Standby',          NULL,     'natural_gas', 10000, 25, true, 3799,  ARRAY['Essential circuit backup','100A 16-circuit switch','OnCue Plus monitoring'], '{"watts_starting": 10000, "transfer_switch": "100A 16-circuit", "fuel_type": "natural_gas", "exercise_schedule": true, "mobile_monitoring": true, "noise_dba": 69}'),
  ('38RCAL',  '38kW Standby',          NULL,     'natural_gas', 38000, 25, true, 14999, ARRAY['Large home backup','400A transfer switch','OnCue Plus monitoring','Premium enclosure'], '{"watts_starting": 38000, "transfer_switch": "400A", "fuel_type": "natural_gas", "exercise_schedule": true, "mobile_monitoring": true, "noise_dba": 63}'),
  ('48RCAL',  '48kW Standby',          NULL,     'natural_gas', 48000, 25, true, 17999, ARRAY['Estate-size backup','400A transfer switch','OnCue Plus monitoring','Industrial engine'], '{"watts_starting": 48000, "transfer_switch": "400A", "fuel_type": "natural_gas", "exercise_schedule": true, "mobile_monitoring": true, "noise_dba": 62}')
) AS v(model_number, model_name, series, fuel, cap, lifespan, wifi, msrp, features, specs)
WHERE m.slug = 'kohler-generators' AND c.slug = 'generator-standby-gas';


-- ============================================================================
-- CUMMINS  (Standby)
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'standby', NULL, v.cap, 'watts', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, 'https://www.cummins.com/home-generators'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('RS25',  '25kW QuietConnect', 'QuietConnect', 'natural_gas', 25000, 25, true, 7299,  ARRAY['Whole-home backup','200A SE transfer switch','Cummins Connected remote monitoring','Quiet operation'], '{"watts_starting": 25000, "transfer_switch": "200A SE", "fuel_type": "natural_gas", "exercise_schedule": true, "mobile_monitoring": true, "noise_dba": 63}'),
  ('RS20A', '20kW QuietConnect', 'QuietConnect', 'natural_gas', 20000, 25, true, 5999,  ARRAY['Whole-home backup','200A SE transfer switch','Cummins Connected monitoring','Sound-attenuated enclosure'], '{"watts_starting": 20000, "transfer_switch": "200A SE", "fuel_type": "natural_gas", "exercise_schedule": true, "mobile_monitoring": true, "noise_dba": 64}'),
  ('RS17A', '17kW QuietConnect', 'QuietConnect', 'natural_gas', 17000, 25, true, 5299,  ARRAY['Whole-home backup','200A transfer switch','Cummins Connected monitoring'], '{"watts_starting": 17000, "transfer_switch": "200A", "fuel_type": "natural_gas", "exercise_schedule": true, "mobile_monitoring": true, "noise_dba": 65}'),
  ('RS13A', '13kW QuietConnect', 'QuietConnect', 'natural_gas', 13000, 25, true, 4499,  ARRAY['Essential circuit backup','200A transfer switch','Cummins Connected monitoring'], '{"watts_starting": 13000, "transfer_switch": "200A", "fuel_type": "natural_gas", "exercise_schedule": true, "mobile_monitoring": true, "noise_dba": 65}'),
  ('A065U845','20kW Quiet Connect','QuietConnect','propane',     20000, 25, true, 5799,  ARRAY['LP fuel ready','200A SE transfer switch','Weather-resistant enclosure'], '{"watts_starting": 20000, "transfer_switch": "200A SE", "fuel_type": "propane", "exercise_schedule": true, "mobile_monitoring": true, "noise_dba": 64}'),
  ('RS30',  '30kW QuietConnect', 'QuietConnect', 'natural_gas', 30000, 25, true, 9999,  ARRAY['Large home backup','400A transfer switch','Cummins Connected monitoring','Premium enclosure'], '{"watts_starting": 30000, "transfer_switch": "400A", "fuel_type": "natural_gas", "exercise_schedule": true, "mobile_monitoring": true, "noise_dba": 62}')
) AS v(model_number, model_name, series, fuel, cap, lifespan, wifi, msrp, features, specs)
WHERE m.slug = 'cummins' AND c.slug = 'generator-standby-gas';


-- ============================================================================
-- WINCO  (Standby - Diesel & Gas)
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'standby', NULL, v.cap, 'watts', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, 'https://www.wincogen.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('PSS21',   '21kW Standby',        'PSS',     'natural_gas',  21000, 25, 6999,  ARRAY['Whole-home standby','Briggs engine','Sound-attenuated housing','200A transfer switch'], '{"watts_starting": 21000, "transfer_switch": "200A", "fuel_type": "natural_gas", "exercise_schedule": true, "mobile_monitoring": false, "noise_dba": 68}'),
  ('PSS12H',  '12kW Standby',        'PSS',     'natural_gas',  12000, 25, 4999,  ARRAY['Residential standby','Sound-attenuated housing','Automatic transfer switch'], '{"watts_starting": 12000, "transfer_switch": "200A", "fuel_type": "natural_gas", "exercise_schedule": true, "mobile_monitoring": false, "noise_dba": 70}'),
  ('EC22',    '22kW Emergency',       'EC',      'natural_gas',  22000, 25, 7499,  ARRAY['Emergency standby rated','Commercial-grade engine','Heavy-duty enclosure'], '{"watts_starting": 22000, "transfer_switch": "200A", "fuel_type": "natural_gas", "exercise_schedule": true, "mobile_monitoring": false, "noise_dba": 68}')
) AS v(model_number, model_name, series, fuel, cap, lifespan, msrp, features, specs)
WHERE m.slug = 'winco' AND c.slug = 'generator-standby-gas';

-- Winco Diesel Standby
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'diesel', 'standby', NULL, v.cap, 'watts', true, 25, false, false, v.msrp, v.features, v.specs::jsonb, 'https://www.wincogen.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DE20',  '20kW Diesel Standby',  'DE',  20000, 11999, ARRAY['Diesel standby','Kubota engine','Sound-attenuated enclosure','Long run time'], '{"watts_starting": 20000, "transfer_switch": "200A", "fuel_type": "diesel", "exercise_schedule": true, "mobile_monitoring": false, "noise_dba": 66}'),
  ('DE40',  '40kW Diesel Standby',  'DE',  40000, 18999, ARRAY['Large diesel standby','Commercial-grade','Heavy-duty enclosure'], '{"watts_starting": 40000, "transfer_switch": "400A", "fuel_type": "diesel", "exercise_schedule": true, "mobile_monitoring": false, "noise_dba": 64}')
) AS v(model_number, model_name, series, cap, msrp, features, specs)
WHERE m.slug = 'winco' AND c.slug = 'generator-standby-diesel';


-- ============================================================================
-- HONDA POWER  (Inverter + Portable)
-- ============================================================================

-- Honda Inverter Generators
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'gas', 'portable', NULL, v.cap, 'watts', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, 'https://www.powerequipment.honda.com/generators'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('EU2200i',    '2200W Super Quiet',          'EU',   1800, 15, 1199, ARRAY['Super quiet','Inverter technology','CO-MINDER safety shutoff','Bluetooth connectivity','Parallel capable','Eco-Throttle'], '{"watts_starting": 2200, "runtime_hours_50pct": 8.1, "noise_dba": 48, "fuel_tank_gallons": 0.95, "outlets": "2x120V 1xUSB-A 1xUSB-C", "parallel_capable": true, "co_shutoff": true}'),
  ('EU2200iTC',  '2200W Companion',            'EU',   1800, 15, 1299, ARRAY['30A RV outlet','Companion for parallel','CO-MINDER','Super quiet'], '{"watts_starting": 2200, "runtime_hours_50pct": 8.1, "noise_dba": 48, "fuel_tank_gallons": 0.95, "outlets": "1x120V 1x30A RV", "parallel_capable": true, "co_shutoff": true}'),
  ('EU3000iS',   '3000W Electric Start',       'EU',   2800, 15, 2399, ARRAY['Electric start','Super quiet','Fuel injection','30A outlet','Parallel capable'], '{"watts_starting": 3000, "runtime_hours_50pct": 20, "noise_dba": 50, "fuel_tank_gallons": 3.4, "outlets": "2x120V 1x30A", "parallel_capable": true, "co_shutoff": true}'),
  ('EU7000iS',   '7000W Electric Start',       'EU',   5500, 15, 4699, ARRAY['Electric start','Fuel injection','iAVR voltage regulation','Super quiet for size'], '{"watts_starting": 7000, "runtime_hours_50pct": 18, "noise_dba": 52, "fuel_tank_gallons": 5.1, "outlets": "2x120V 1x120/240V", "parallel_capable": false, "co_shutoff": true}'),
  ('EU1000i',    '1000W Ultra-Portable',       'EU',   900,  15, 849,  ARRAY['Ultra-lightweight 29 lbs','Super quiet','Inverter clean power','Parallel capable'], '{"watts_starting": 1000, "runtime_hours_50pct": 7, "noise_dba": 42, "fuel_tank_gallons": 0.6, "outlets": "1x120V", "parallel_capable": true, "co_shutoff": false}'),
  ('EU3200i',    '3200W Inverter',             'EU',   2600, 15, 2599, ARRAY['CO-MINDER safety','Electric start','Bluetooth','Parallel capable','Fuel injection'], '{"watts_starting": 3200, "runtime_hours_50pct": 16, "noise_dba": 51, "fuel_tank_gallons": 3.4, "outlets": "2x120V 1x30A 1xUSB", "parallel_capable": true, "co_shutoff": true}'),
  ('EG2800i',    '2800W Open Frame Inverter',  'EG',   2500, 15, 1199, ARRAY['Open frame inverter','CO-MINDER','Fuel gauge','GFCI protection'], '{"watts_starting": 2800, "runtime_hours_50pct": 10, "noise_dba": 62, "fuel_tank_gallons": 2.2, "outlets": "3x120V 1xUSB", "parallel_capable": false, "co_shutoff": true}'),
  ('EG4000',     '4000W Open Frame Inverter',  'EG',   3500, 15, 1599, ARRAY['Open frame inverter','CO-MINDER','120/240V capability','GFCI outlets'], '{"watts_starting": 4000, "runtime_hours_50pct": 9.5, "noise_dba": 64, "fuel_tank_gallons": 3.6, "outlets": "3x120V 1x120/240V", "parallel_capable": false, "co_shutoff": true}'),
  ('EB2800i',    '2800W Industrial Inverter',  'EB',   2500, 15, 1649, ARRAY['Commercial-grade','Full-frame protection','GFCI outlets','CO-MINDER'], '{"watts_starting": 2800, "runtime_hours_50pct": 10, "noise_dba": 64, "fuel_tank_gallons": 2.2, "outlets": "2x120V GFCI 1xUSB", "parallel_capable": false, "co_shutoff": true}')
) AS v(model_number, model_name, series, cap, lifespan, msrp, features, specs)
WHERE m.slug = 'honda-power' AND c.slug = 'generator-inverter';

-- Honda Portable (Open Frame)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'gas', 'portable', NULL, v.cap, 'watts', true, 15, false, false, v.msrp, v.features, v.specs::jsonb, 'https://www.powerequipment.honda.com/generators'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('EM5000SX',   '5000W Deluxe',       'EM',  4500, 2299, ARRAY['Electric start','iAVR auto voltage regulation','Fuel gauge','Oil Alert shutdown'], '{"watts_starting": 5000, "runtime_hours_50pct": 11.2, "noise_dba": 73, "fuel_tank_gallons": 6.2, "outlets": "4x120V 1x120/240V", "parallel_capable": false, "co_shutoff": false}'),
  ('EB5000',     '5000W Industrial',    'EB',  4500, 2599, ARRAY['Industrial grade','Full GFCI protection','iAVR','Hour meter','Never-Flat tires'], '{"watts_starting": 5000, "runtime_hours_50pct": 11.2, "noise_dba": 73, "fuel_tank_gallons": 6.2, "outlets": "4x120V GFCI 1x120/240V", "parallel_capable": false, "co_shutoff": false}'),
  ('EB10000',    '10000W Industrial',   'EB',  9000, 5999, ARRAY['Industrial grade','Electric start','iAVR','Multiple GFCI outlets','Hour meter'], '{"watts_starting": 10000, "runtime_hours_50pct": 8.1, "noise_dba": 78, "fuel_tank_gallons": 6.6, "outlets": "4x120V GFCI 1x120/240V 1x50A", "parallel_capable": false, "co_shutoff": false}')
) AS v(model_number, model_name, series, cap, msrp, features, specs)
WHERE m.slug = 'honda-power' AND c.slug = 'generator-portable';


-- ============================================================================
-- YAMAHA POWER  (Inverter + Portable)
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'gas', 'portable', NULL, v.cap, 'watts', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, 'https://www.yamaha-motor.com/power-products/generators'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('EF2200iS',   '2200W Inverter',          'EF',  'generator-inverter', 1800, 15, 1099, ARRAY['Inverter technology','Smart throttle','Twin Tech parallel capable','Quiet operation','Carbon monoxide sensor'], '{"watts_starting": 2200, "runtime_hours_50pct": 10.5, "noise_dba": 51.5, "fuel_tank_gallons": 1.1, "outlets": "2x120V 1xUSB", "parallel_capable": true, "co_shutoff": true}'),
  ('EF2000iSv2', '2000W Inverter v2',       'EF',  'generator-inverter', 1600, 15, 999,  ARRAY['Compact inverter','Smart throttle','Twin Tech parallel','Noise Block housing'], '{"watts_starting": 2000, "runtime_hours_50pct": 10.5, "noise_dba": 51.5, "fuel_tank_gallons": 1.1, "outlets": "2x120V", "parallel_capable": true, "co_shutoff": false}'),
  ('EF4500iSE',  '4500W Inverter',          'EF',  'generator-inverter', 3700, 15, 2599, ARRAY['Electric start','Boost technology','Twin Tech parallel','Noise Block','CO sensor'], '{"watts_starting": 4500, "runtime_hours_50pct": 16, "noise_dba": 60, "fuel_tank_gallons": 4.5, "outlets": "2x120V 1x120/240V", "parallel_capable": true, "co_shutoff": true}'),
  ('EF3000iSEB', '3000W Inverter Boost',    'EF',  'generator-inverter', 2800, 15, 1999, ARRAY['Boost technology 3500W','Electric start','Twin Tech parallel','CO sensor'], '{"watts_starting": 3500, "runtime_hours_50pct": 19, "noise_dba": 53, "fuel_tank_gallons": 3.4, "outlets": "2x120V 1x30A", "parallel_capable": true, "co_shutoff": true}'),
  ('EF1000iS',   '1000W Ultra-Portable',    'EF',  'generator-inverter', 900,  15, 749,  ARRAY['Ultra-lightweight 28 lbs','Super quiet','Noise Block housing','Smart throttle'], '{"watts_starting": 1000, "runtime_hours_50pct": 12, "noise_dba": 47, "fuel_tank_gallons": 0.66, "outlets": "1x120V", "parallel_capable": true, "co_shutoff": false}'),
  ('EF6300iSDE', '6300W Inverter',          'EF',  'generator-inverter', 5500, 15, 3999, ARRAY['Electric start','Diesel-like runtime','Noise Block','30A/50A outlets'], '{"watts_starting": 6300, "runtime_hours_50pct": 13.3, "noise_dba": 58, "fuel_tank_gallons": 4.5, "outlets": "2x120V 1x120/240V 1x30A", "parallel_capable": false, "co_shutoff": true}'),
  ('EF7200DE',   '7200W Open Frame',        'EF',  'generator-portable', 6000, 12, 2199, ARRAY['Electric start','OHV engine','GFCI outlets','Wheel kit'], '{"watts_starting": 7200, "runtime_hours_50pct": 13, "noise_dba": 72, "fuel_tank_gallons": 6.4, "outlets": "4x120V GFCI 1x120/240V", "parallel_capable": false, "co_shutoff": false}'),
  ('EF5500DE',   '5500W Open Frame',        'EF',  'generator-portable', 4500, 12, 1699, ARRAY['Electric start','OHV engine','GFCI outlets','Hour meter'], '{"watts_starting": 5500, "runtime_hours_50pct": 12.5, "noise_dba": 70, "fuel_tank_gallons": 5.3, "outlets": "4x120V GFCI 1x120/240V", "parallel_capable": false, "co_shutoff": false}')
) AS v(model_number, model_name, series, cat_slug, cap, lifespan, msrp, features, specs)
WHERE m.slug = 'yamaha-power' AND c.slug = v.cat_slug;


-- ============================================================================
-- CHAMPION POWER EQUIPMENT  (Portable + Inverter + Standby)
-- ============================================================================

-- Champion Portable Generators
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'portable', NULL, v.cap, 'watts', true, 12, false, false, v.msrp, v.features, v.specs::jsonb, 'https://www.championpowerequipment.com/generators'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('201040',   '8500W Dual Fuel Open Frame',  NULL,    'dual-fuel',  8500,  1199, ARRAY['Dual fuel gas/propane','Electric start','Intelligauge','Volt Guard surge protector','CO Shield'], '{"watts_starting": 10625, "runtime_hours_50pct": 10.5, "noise_dba": 74, "fuel_tank_gallons": 7, "outlets": "4x120V GFCI 1x120/240V 1x30A", "parallel_capable": false, "co_shutoff": true}'),
  ('100519',   '7500W Dual Fuel',             NULL,    'dual-fuel',  7500,  1099, ARRAY['Dual fuel','Electric start','Intelligauge','Volt Guard'], '{"watts_starting": 9375, "runtime_hours_50pct": 8, "noise_dba": 74, "fuel_tank_gallons": 6, "outlets": "4x120V 1x120/240V 1x30A", "parallel_capable": false, "co_shutoff": true}'),
  ('100813',   '9375W Dual Fuel',             NULL,    'dual-fuel',  9375,  1399, ARRAY['Dual fuel','Electric start','CO Shield auto shutoff','Volt Guard','Intelligauge'], '{"watts_starting": 11719, "runtime_hours_50pct": 9, "noise_dba": 75, "fuel_tank_gallons": 7.5, "outlets": "4x120V GFCI 1x120/240V 1x50A", "parallel_capable": false, "co_shutoff": true}'),
  ('100891',   '4375W Dual Fuel',             NULL,    'dual-fuel',  4375,  549,  ARRAY['Dual fuel','Recoil start','Intelligauge','CO Shield'], '{"watts_starting": 5469, "runtime_hours_50pct": 12, "noise_dba": 68, "fuel_tank_gallons": 3.4, "outlets": "3x120V", "parallel_capable": false, "co_shutoff": true}'),
  ('200951',   '11500W/9200W Tri Fuel',       NULL,    'gas',        9200,  2499, ARRAY['Tri fuel: gas/propane/natural gas','Electric start','50A outlet','CO Shield','Digital hour meter'], '{"watts_starting": 11500, "runtime_hours_50pct": 8.5, "noise_dba": 76, "fuel_tank_gallons": 8.5, "outlets": "4x120V GFCI 1x120/240V 1x50A", "parallel_capable": false, "co_shutoff": true}'),
  ('100520',   '6250W Dual Fuel',             NULL,    'dual-fuel',  6250,  849,  ARRAY['Dual fuel','Electric start','Intelligauge','Wheel kit included'], '{"watts_starting": 7850, "runtime_hours_50pct": 9.5, "noise_dba": 72, "fuel_tank_gallons": 5, "outlets": "4x120V 1x120/240V", "parallel_capable": false, "co_shutoff": false}')
) AS v(model_number, model_name, series, fuel, cap, msrp, features, specs)
WHERE m.slug = 'champion-power' AND c.slug = 'generator-portable';

-- Champion Inverter Generators
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'portable', NULL, v.cap, 'watts', true, 12, false, false, v.msrp, v.features, v.specs::jsonb, 'https://www.championpowerequipment.com/generators'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('200988',   '4500W Dual Fuel Inverter',   NULL,   'dual-fuel', 3700,  1299, ARRAY['Dual fuel inverter','Electric start','Quiet technology','CO Shield','Parallel capable','Economy mode'], '{"watts_starting": 4500, "runtime_hours_50pct": 14, "noise_dba": 61, "fuel_tank_gallons": 3.3, "outlets": "2x120V 1x30A 1xUSB", "parallel_capable": true, "co_shutoff": true}'),
  ('200986',   '3500W Dual Fuel Inverter',   NULL,   'dual-fuel', 3150,  999,  ARRAY['Dual fuel inverter','Electric start','CO Shield','Parallel capable'], '{"watts_starting": 3500, "runtime_hours_50pct": 11.5, "noise_dba": 59, "fuel_tank_gallons": 2.3, "outlets": "2x120V 1xUSB", "parallel_capable": true, "co_shutoff": true}'),
  ('200914',   '2500W Dual Fuel Inverter',   NULL,   'dual-fuel', 2200,  699,  ARRAY['Dual fuel inverter','Recoil start','CO Shield','Ultralight 39 lbs'], '{"watts_starting": 2500, "runtime_hours_50pct": 11.5, "noise_dba": 53, "fuel_tank_gallons": 1.1, "outlets": "2x120V 1xUSB", "parallel_capable": true, "co_shutoff": true}'),
  ('201001',   '6250W Dual Fuel Inverter',   NULL,   'dual-fuel', 5000,  1799, ARRAY['Open frame inverter','Dual fuel','Electric start','CO Shield','GFCI outlets'], '{"watts_starting": 6250, "runtime_hours_50pct": 12.5, "noise_dba": 64, "fuel_tank_gallons": 4.2, "outlets": "4x120V GFCI 1x120/240V", "parallel_capable": false, "co_shutoff": true}'),
  ('100889',   '2000W Inverter',             NULL,   'gas',       1700,  499,  ARRAY['Ultra-quiet','Economy mode','Parallel capable','Lightweight 39 lbs'], '{"watts_starting": 2000, "runtime_hours_50pct": 11.5, "noise_dba": 53, "fuel_tank_gallons": 1.1, "outlets": "2x120V", "parallel_capable": true, "co_shutoff": false}'),
  ('100692',   '2000W Stackable Inverter',   NULL,   'gas',       1700,  549,  ARRAY['Stackable design','Parallel kit included','USB outlets','Economy mode'], '{"watts_starting": 2000, "runtime_hours_50pct": 11.5, "noise_dba": 53, "fuel_tank_gallons": 1.1, "outlets": "2x120V 1xUSB", "parallel_capable": true, "co_shutoff": false}'),
  ('200961',   '8500W Dual Fuel Inverter',   NULL,   'dual-fuel', 7000,  2299, ARRAY['Dual fuel inverter','Electric start','CO Shield','RV ready','Quiet for its size'], '{"watts_starting": 8500, "runtime_hours_50pct": 10, "noise_dba": 66, "fuel_tank_gallons": 5.3, "outlets": "4x120V GFCI 1x120/240V 1x30A", "parallel_capable": false, "co_shutoff": true}')
) AS v(model_number, model_name, series, fuel, cap, msrp, features, specs)
WHERE m.slug = 'champion-power' AND c.slug = 'generator-inverter';

-- Champion Standby Generator
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, NULL, v.fuel, 'standby', NULL, v.cap, 'watts', true, 20, v.wifi, false, v.msrp, v.features, v.specs::jsonb, 'https://www.championpowerequipment.com/generators'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('100837',   '14kW aXis Standby',   'dual-fuel',  14000, true,  5499, ARRAY['Dual fuel NG/LP','aXis home standby','200A SE transfer switch','Wi-Fi monitoring','Quiet operation'], '{"watts_starting": 14000, "transfer_switch": "200A SE", "fuel_type": "dual_fuel", "exercise_schedule": true, "mobile_monitoring": true, "noise_dba": 63}'),
  ('100836',   '12.5kW aXis Standby', 'dual-fuel',  12500, true,  4999, ARRAY['Dual fuel NG/LP','aXis home standby','200A transfer switch','Wi-Fi monitoring'], '{"watts_starting": 12500, "transfer_switch": "200A", "fuel_type": "dual_fuel", "exercise_schedule": true, "mobile_monitoring": true, "noise_dba": 63}'),
  ('100177',   '8.5kW Standby',       'natural_gas', 8500, false, 3299, ARRAY['Home standby','100A 16-circuit switch','Steel enclosure'], '{"watts_starting": 8500, "transfer_switch": "100A 16-circuit", "fuel_type": "natural_gas", "exercise_schedule": true, "mobile_monitoring": false, "noise_dba": 66}')
) AS v(model_number, model_name, fuel, cap, wifi, msrp, features, specs)
WHERE m.slug = 'champion-power' AND c.slug = 'generator-standby-gas';


-- ============================================================================
-- WESTINGHOUSE POWER  (Portable + Inverter)
-- ============================================================================

-- Westinghouse Portable
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'portable', NULL, v.cap, 'watts', true, 12, false, false, v.msrp, v.features, v.specs::jsonb, 'https://www.westinghouseoutdoorpower.com/generators'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WGen9500DF',  '9500W Dual Fuel',          'WGen',   'dual-fuel',  9500,  1299, ARRAY['Dual fuel','Remote electric start','VFT data center display','Transfer switch ready','GFCI outlets'], '{"watts_starting": 12500, "runtime_hours_50pct": 12, "noise_dba": 73, "fuel_tank_gallons": 6.6, "outlets": "4x120V GFCI 1x120/240V 1x30A 1x50A", "parallel_capable": false, "co_shutoff": false}'),
  ('WGen7500DF',  '7500W Dual Fuel',          'WGen',   'dual-fuel',  7500,  949,  ARRAY['Dual fuel','Remote electric start','VFT display','Transfer switch ready'], '{"watts_starting": 9500, "runtime_hours_50pct": 11, "noise_dba": 73, "fuel_tank_gallons": 6.6, "outlets": "4x120V 1x120/240V 1x30A", "parallel_capable": false, "co_shutoff": false}'),
  ('WGen5300DFv', '5300W Dual Fuel',          'WGen',   'dual-fuel',  5300,  699,  ARRAY['Dual fuel','Remote electric start','CO sensor','VFT display'], '{"watts_starting": 6600, "runtime_hours_50pct": 13.5, "noise_dba": 69, "fuel_tank_gallons": 4, "outlets": "3x120V 1x120/240V", "parallel_capable": false, "co_shutoff": true}'),
  ('WGen3600DF',  '3600W Dual Fuel',          'WGen',   'dual-fuel',  3600,  499,  ARRAY['Dual fuel','Recoil start','RV ready outlet','Fuel gauge'], '{"watts_starting": 4650, "runtime_hours_50pct": 13.5, "noise_dba": 67, "fuel_tank_gallons": 4, "outlets": "2x120V 1x30A RV", "parallel_capable": false, "co_shutoff": false}'),
  ('WGen12000DF', '12000W Dual Fuel',         'WGen',   'dual-fuel', 12000,  1599, ARRAY['Dual fuel','Remote electric start','50A outlet','VFT display','CO sensor'], '{"watts_starting": 15000, "runtime_hours_50pct": 10, "noise_dba": 76, "fuel_tank_gallons": 10.5, "outlets": "4x120V GFCI 1x120/240V 1x50A", "parallel_capable": false, "co_shutoff": true}'),
  ('WGen6000',    '6000W Gasoline',           'WGen',   'gas',        6000,  649,  ARRAY['Gas only','Electric start','VFT display','Wheel kit'], '{"watts_starting": 7500, "runtime_hours_50pct": 11, "noise_dba": 72, "fuel_tank_gallons": 5, "outlets": "4x120V 1x120/240V", "parallel_capable": false, "co_shutoff": false}')
) AS v(model_number, model_name, series, fuel, cap, msrp, features, specs)
WHERE m.slug = 'westinghouse-power' AND c.slug = 'generator-portable';

-- Westinghouse Inverter
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'portable', NULL, v.cap, 'watts', true, 12, false, false, v.msrp, v.features, v.specs::jsonb, 'https://www.westinghouseoutdoorpower.com/generators'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('iGen4500DF',  '4500W Dual Fuel Inverter',  'iGen',  'dual-fuel', 3700,  1099, ARRAY['Dual fuel inverter','Remote electric start','LED data center','Parallel capable','CO sensor'], '{"watts_starting": 4500, "runtime_hours_50pct": 18, "noise_dba": 52, "fuel_tank_gallons": 3.4, "outlets": "3x120V 1x30A RV 2xUSB", "parallel_capable": true, "co_shutoff": true}'),
  ('iGen4500',    '4500W Gas Inverter',        'iGen',  'gas',       3700,  999,  ARRAY['Gas inverter','Remote electric start','LED data center','Parallel capable','TT-30R RV outlet'], '{"watts_starting": 4500, "runtime_hours_50pct": 18, "noise_dba": 52, "fuel_tank_gallons": 3.4, "outlets": "3x120V 1x30A RV 2xUSB", "parallel_capable": true, "co_shutoff": false}'),
  ('iGen2500',    '2500W Inverter',            'iGen',  'gas',       2200,  549,  ARRAY['Lightweight inverter','Parallel capable','LED data center','Economy mode'], '{"watts_starting": 2500, "runtime_hours_50pct": 10, "noise_dba": 52, "fuel_tank_gallons": 1.0, "outlets": "2x120V 2xUSB", "parallel_capable": true, "co_shutoff": false}'),
  ('iGen2200',    '2200W Inverter',            'iGen',  'gas',       1800,  449,  ARRAY['Ultra-quiet','Parallel capable','Gas shut-off valve','LED display'], '{"watts_starting": 2200, "runtime_hours_50pct": 12, "noise_dba": 52, "fuel_tank_gallons": 1.0, "outlets": "2x120V 2xUSB", "parallel_capable": true, "co_shutoff": false}'),
  ('iGen1200',    '1200W Digital Inverter',    'iGen',  'gas',       1000,  349,  ARRAY['Ultra-portable','Digital display','Parallel capable','35 lbs'], '{"watts_starting": 1200, "runtime_hours_50pct": 9, "noise_dba": 48, "fuel_tank_gallons": 0.7, "outlets": "1x120V 1xUSB", "parallel_capable": true, "co_shutoff": false}'),
  ('iGen160s',    '150W Portable Power Station','iGen', 'battery',    150,  179,  ARRAY['Lithium battery','Solar panel compatible','USB-C PD','Compact for camping'], '{"watt_hours": 155, "watts_output": 150, "watts_surge": 300, "battery_type": "Li-ion", "cycles": 500, "solar_input_watts": 100, "weight_lbs": 3.5}')
) AS v(model_number, model_name, series, fuel, cap, msrp, features, specs)
WHERE m.slug = 'westinghouse-power' AND c.slug = 'generator-inverter';


-- ============================================================================
-- BRIGGS & STRATTON  (Portable + Inverter + Standby)
-- ============================================================================

-- Briggs & Stratton Portable
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'portable', NULL, v.cap, 'watts', true, 12, false, false, v.msrp, v.features, v.specs::jsonb, 'https://www.briggsandstratton.com/generators'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('030729',  '6500W Elite Series',       'Elite',       'gas',      6500, 999,  ARRAY['Electric start','420cc OHV engine','StatStation display','4 GFCI outlets','CO Guard'], '{"watts_starting": 8125, "runtime_hours_50pct": 10, "noise_dba": 74, "fuel_tank_gallons": 7, "outlets": "4x120V GFCI 1x120/240V", "parallel_capable": false, "co_shutoff": true}'),
  ('030728',  '5500W StormResponder',     'StormResponder','gas',    5500, 849,  ARRAY['Electric start','CO Guard auto shutoff','StatStation display','Wheel kit'], '{"watts_starting": 6875, "runtime_hours_50pct": 10, "noise_dba": 74, "fuel_tank_gallons": 6, "outlets": "4x120V 1x120/240V", "parallel_capable": false, "co_shutoff": true}'),
  ('030736',  '8000W Elite Series',       'Elite',       'gas',      8000, 1299, ARRAY['Electric start','420cc OHV engine','CO Guard','StatStation','Never-Flat wheels'], '{"watts_starting": 10000, "runtime_hours_50pct": 9.5, "noise_dba": 76, "fuel_tank_gallons": 7.5, "outlets": "4x120V GFCI 1x120/240V 1x30A", "parallel_capable": false, "co_shutoff": true}'),
  ('030734',  '3500W Portable',           NULL,          'gas',      3500, 549,  ARRAY['Recoil start','RV ready','H-handle frame','CO Guard'], '{"watts_starting": 4375, "runtime_hours_50pct": 12, "noise_dba": 70, "fuel_tank_gallons": 4, "outlets": "3x120V 1x30A RV", "parallel_capable": false, "co_shutoff": true}'),
  ('030737',  '10000W Elite Series',      'Elite',       'gas',     10000, 1699, ARRAY['Electric start','Key fob remote start','CO Guard','GFCI outlets','50A outlet'], '{"watts_starting": 12500, "runtime_hours_50pct": 8.5, "noise_dba": 78, "fuel_tank_gallons": 8.5, "outlets": "4x120V GFCI 1x120/240V 1x50A", "parallel_capable": false, "co_shutoff": true}')
) AS v(model_number, model_name, series, fuel, cap, msrp, features, specs)
WHERE m.slug = 'briggs-stratton' AND c.slug = 'generator-portable';

-- Briggs & Stratton Inverter
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'gas', 'portable', NULL, v.cap, 'watts', true, 12, false, false, v.msrp, v.features, v.specs::jsonb, 'https://www.briggsandstratton.com/generators'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('030795',  '2400W P2400 PowerSmart',   'PowerSmart',  2200, 749,  ARRAY['Inverter technology','CO Guard','Quiet Power Technology','Parallel capable','USB outlets'], '{"watts_starting": 2400, "runtime_hours_50pct": 8, "noise_dba": 54, "fuel_tank_gallons": 1.0, "outlets": "2x120V 2xUSB", "parallel_capable": true, "co_shutoff": true}'),
  ('030801',  '3000W P3000 PowerSmart',   'PowerSmart',  2600, 999,  ARRAY['Inverter technology','CO Guard','Electric start','Quiet Power Technology','Parallel capable'], '{"watts_starting": 3000, "runtime_hours_50pct": 10, "noise_dba": 58, "fuel_tank_gallons": 1.5, "outlets": "2x120V 1x30A 2xUSB", "parallel_capable": true, "co_shutoff": true}'),
  ('030805',  '6500W Q6500 QuietPower',   'QuietPower',  5000, 1599, ARRAY['Open frame inverter','Electric start','CO Guard','GFCI outlets','Quiet for open frame'], '{"watts_starting": 6500, "runtime_hours_50pct": 14, "noise_dba": 66, "fuel_tank_gallons": 5, "outlets": "4x120V GFCI 1x120/240V", "parallel_capable": false, "co_shutoff": true}')
) AS v(model_number, model_name, series, cap, msrp, features, specs)
WHERE m.slug = 'briggs-stratton' AND c.slug = 'generator-inverter';

-- Briggs & Stratton Standby
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'standby', NULL, v.cap, 'watts', true, 20, v.wifi, false, v.msrp, v.features, v.specs::jsonb, 'https://www.briggsandstratton.com/generators'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('040684',  '26kW Standby',        'Power Protect', 'natural_gas', 26000, true,  7699, ARRAY['Whole-home backup','200A SE transfer switch','InfoHub LCD display','Wi-Fi monitoring','Symphony II power management'], '{"watts_starting": 26000, "transfer_switch": "200A SE", "fuel_type": "natural_gas", "exercise_schedule": true, "mobile_monitoring": true, "noise_dba": 65}'),
  ('040678',  '20kW Standby',        'Power Protect', 'natural_gas', 20000, true,  5999, ARRAY['Whole-home backup','200A SE transfer switch','Wi-Fi monitoring','Symphony II power management'], '{"watts_starting": 20000, "transfer_switch": "200A SE", "fuel_type": "natural_gas", "exercise_schedule": true, "mobile_monitoring": true, "noise_dba": 66}'),
  ('040676',  '17kW Standby',        'Power Protect', 'natural_gas', 17000, true,  5399, ARRAY['Whole-home backup','200A transfer switch','Wi-Fi monitoring'], '{"watts_starting": 17000, "transfer_switch": "200A", "fuel_type": "natural_gas", "exercise_schedule": true, "mobile_monitoring": true, "noise_dba": 67}'),
  ('040673',  '12kW Standby',        'Power Protect', 'natural_gas', 12000, true,  4399, ARRAY['Essential circuit backup','200A transfer switch','Wi-Fi monitoring'], '{"watts_starting": 12000, "transfer_switch": "200A", "fuel_type": "natural_gas", "exercise_schedule": true, "mobile_monitoring": true, "noise_dba": 68}'),
  ('040670',  '10kW Standby',        'Power Protect', 'natural_gas', 10000, false, 3599, ARRAY['Essential circuit backup','100A 16-circuit switch','Steel enclosure'], '{"watts_starting": 10000, "transfer_switch": "100A 16-circuit", "fuel_type": "natural_gas", "exercise_schedule": true, "mobile_monitoring": false, "noise_dba": 69}')
) AS v(model_number, model_name, series, fuel, cap, wifi, msrp, features, specs)
WHERE m.slug = 'briggs-stratton' AND c.slug = 'generator-standby-gas';


-- ============================================================================
-- DUROMAX  (Portable + Inverter)
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'portable', NULL, v.cap, 'watts', true, 12, false, false, v.msrp, v.features, v.specs::jsonb, 'https://www.duromax.com/generators'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('XP13000EH', '13000W Dual Fuel',          'XP', 'generator-portable', 'dual-fuel', 10500, 1599, ARRAY['Dual fuel','Electric start','500cc OHV engine','50A outlet','CO alert','MX2 power boost'], '{"watts_starting": 13000, "runtime_hours_50pct": 8.5, "noise_dba": 76, "fuel_tank_gallons": 8.3, "outlets": "4x120V GFCI 1x120/240V 1x50A", "parallel_capable": false, "co_shutoff": true}'),
  ('XP12000EH', '12000W Dual Fuel',          'XP', 'generator-portable', 'dual-fuel',  9500, 1399, ARRAY['Dual fuel','Electric start','457cc OHV engine','CO alert','MX2 power boost'], '{"watts_starting": 12000, "runtime_hours_50pct": 8.5, "noise_dba": 76, "fuel_tank_gallons": 8.3, "outlets": "4x120V GFCI 1x120/240V 1x50A", "parallel_capable": false, "co_shutoff": true}'),
  ('XP9500EH',  '9500W Dual Fuel',           'XP', 'generator-portable', 'dual-fuel',  7600, 1199, ARRAY['Dual fuel','Electric start','420cc OHV engine','CO alert'], '{"watts_starting": 9500, "runtime_hours_50pct": 9, "noise_dba": 74, "fuel_tank_gallons": 7, "outlets": "4x120V GFCI 1x120/240V 1x30A", "parallel_capable": false, "co_shutoff": true}'),
  ('XP5500EH',  '5500W Dual Fuel',           'XP', 'generator-portable', 'dual-fuel',  4400, 699,  ARRAY['Dual fuel','Electric start','224cc OHV engine','RV ready'], '{"watts_starting": 5500, "runtime_hours_50pct": 10, "noise_dba": 69, "fuel_tank_gallons": 4, "outlets": "3x120V 1x120/240V", "parallel_capable": false, "co_shutoff": false}'),
  ('XP4400EH',  '4400W Dual Fuel',           'XP', 'generator-portable', 'dual-fuel',  3500, 549,  ARRAY['Dual fuel','Recoil start','210cc OHV engine','RV ready 30A'], '{"watts_starting": 4400, "runtime_hours_50pct": 10, "noise_dba": 69, "fuel_tank_gallons": 4, "outlets": "2x120V 1x30A RV", "parallel_capable": false, "co_shutoff": false}'),
  ('XP15000EH', '15000W Dual Fuel V-Twin',   'XP', 'generator-portable', 'dual-fuel', 12500, 1999, ARRAY['Dual fuel','V-Twin engine','Electric start','50A outlet','MX2 power boost','CO alert'], '{"watts_starting": 15000, "runtime_hours_50pct": 8, "noise_dba": 78, "fuel_tank_gallons": 9.9, "outlets": "4x120V GFCI 1x120/240V 1x50A", "parallel_capable": false, "co_shutoff": true}'),
  ('XP2300iH',  '2300W Dual Fuel Inverter',  'XP', 'generator-inverter', 'dual-fuel',  1800, 599,  ARRAY['Dual fuel inverter','Parallel capable','CO alert','Digital display','Lightweight'], '{"watts_starting": 2300, "runtime_hours_50pct": 9, "noise_dba": 52, "fuel_tank_gallons": 1.18, "outlets": "2x120V 2xUSB", "parallel_capable": true, "co_shutoff": true}'),
  ('XP4500iH',  '4500W Dual Fuel Inverter',  'XP', 'generator-inverter', 'dual-fuel',  3700, 1099, ARRAY['Dual fuel inverter','Electric start','CO alert','Parallel capable','RV ready'], '{"watts_starting": 4500, "runtime_hours_50pct": 14, "noise_dba": 58, "fuel_tank_gallons": 3.3, "outlets": "3x120V 1x30A 2xUSB", "parallel_capable": true, "co_shutoff": true}'),
  ('XP9000iH',  '9000W Dual Fuel Inverter',  'XP', 'generator-inverter', 'dual-fuel',  7600, 1899, ARRAY['Dual fuel open frame inverter','Electric start','CO alert','GFCI outlets','50A ready'], '{"watts_starting": 9000, "runtime_hours_50pct": 9, "noise_dba": 66, "fuel_tank_gallons": 5.5, "outlets": "4x120V GFCI 1x120/240V 1x50A", "parallel_capable": false, "co_shutoff": true}'),
  ('XP2000EH',  '2000W Dual Fuel Inverter',  'XP', 'generator-inverter', 'dual-fuel',  1600, 499,  ARRAY['Dual fuel inverter','Ultra-quiet','Parallel capable','Lightweight 47 lbs'], '{"watts_starting": 2000, "runtime_hours_50pct": 8, "noise_dba": 52, "fuel_tank_gallons": 0.95, "outlets": "2x120V 1xUSB", "parallel_capable": true, "co_shutoff": false}'),
  ('XP3150iS',  '3150W Gas Inverter',        'XP', 'generator-inverter', 'gas',         2600, 799,  ARRAY['Gas inverter','Digital display','Parallel capable','Economy mode'], '{"watts_starting": 3150, "runtime_hours_50pct": 10, "noise_dba": 55, "fuel_tank_gallons": 1.7, "outlets": "2x120V 2xUSB", "parallel_capable": true, "co_shutoff": false}')
) AS v(model_number, model_name, series, cat_slug, fuel, cap, msrp, features, specs)
WHERE m.slug = 'duromax' AND c.slug = v.cat_slug;


-- ============================================================================
-- FIRMAN  (Portable + Inverter)
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'portable', NULL, v.cap, 'watts', true, 12, false, false, v.msrp, v.features, v.specs::jsonb, 'https://www.firmanpowerequipment.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('H08051',  '10000/8000W Dual Fuel',       NULL,  'generator-portable', 'dual-fuel',  8000,  999,  ARRAY['Dual fuel','Electric start','439cc engine','CO alert','30A/50A outlets'], '{"watts_starting": 10000, "runtime_hours_50pct": 10.5, "noise_dba": 74, "fuel_tank_gallons": 8, "outlets": "4x120V GFCI 1x120/240V 1x30A 1x50A", "parallel_capable": false, "co_shutoff": true}'),
  ('P03631',  '4550/3650W Dual Fuel',        NULL,  'generator-portable', 'dual-fuel',  3650,  549,  ARRAY['Dual fuel','Recoil start','RV ready 30A','Whisper Series quiet'], '{"watts_starting": 4550, "runtime_hours_50pct": 14, "noise_dba": 67, "fuel_tank_gallons": 5, "outlets": "2x120V 1x30A RV", "parallel_capable": false, "co_shutoff": false}'),
  ('H05753',  '7500/6000W Dual Fuel',        NULL,  'generator-portable', 'dual-fuel',  6000,  849,  ARRAY['Dual fuel','Electric start','CO alert','GFCI outlets','Wheel kit'], '{"watts_starting": 7500, "runtime_hours_50pct": 10, "noise_dba": 74, "fuel_tank_gallons": 7, "outlets": "4x120V GFCI 1x120/240V 1x30A", "parallel_capable": false, "co_shutoff": true}'),
  ('P05703',  '7125/5700W Gas',              NULL,  'generator-portable', 'gas',         5700,  649,  ARRAY['Gas only','Electric start','208cc engine','GFCI outlets'], '{"watts_starting": 7125, "runtime_hours_50pct": 8, "noise_dba": 74, "fuel_tank_gallons": 5, "outlets": "4x120V GFCI 1x120/240V", "parallel_capable": false, "co_shutoff": false}'),
  ('P01202',  '1500/1200W Gas',              NULL,  'generator-portable', 'gas',         1200,  299,  ARRAY['Ultra-portable','Recoil start','80cc engine','Camping/tailgate ready'], '{"watts_starting": 1500, "runtime_hours_50pct": 10, "noise_dba": 68, "fuel_tank_gallons": 1.5, "outlets": "2x120V", "parallel_capable": false, "co_shutoff": false}'),
  ('W03383',  '4100/3300W Dual Fuel Inverter',NULL, 'generator-inverter', 'dual-fuel',  3300,  849,  ARRAY['Dual fuel inverter','Electric start','CO alert','Parallel capable','Economy mode'], '{"watts_starting": 4100, "runtime_hours_50pct": 14.5, "noise_dba": 58, "fuel_tank_gallons": 2.2, "outlets": "2x120V 1x30A 2xUSB", "parallel_capable": true, "co_shutoff": true}'),
  ('W01682',  '2100/1700W Gas Inverter',     NULL,  'generator-inverter', 'gas',         1700,  449,  ARRAY['Gas inverter','Parallel capable','Ultra-quiet','Lightweight'], '{"watts_starting": 2100, "runtime_hours_50pct": 9, "noise_dba": 52, "fuel_tank_gallons": 1.0, "outlets": "2x120V 1xUSB", "parallel_capable": true, "co_shutoff": false}'),
  ('W03384',  '6850/5500W Dual Fuel Inverter',NULL, 'generator-inverter', 'dual-fuel',  5500,  1299, ARRAY['Dual fuel open frame inverter','Electric start','CO alert','GFCI outlets'], '{"watts_starting": 6850, "runtime_hours_50pct": 11, "noise_dba": 62, "fuel_tank_gallons": 4.5, "outlets": "4x120V GFCI 1x120/240V", "parallel_capable": false, "co_shutoff": true}')
) AS v(model_number, model_name, series, cat_slug, fuel, cap, msrp, features, specs)
WHERE m.slug = 'firman' AND c.slug = v.cat_slug;


-- ============================================================================
-- WEN  (Portable + Inverter)
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'portable', NULL, v.cap, 'watts', true, 10, false, false, v.msrp, v.features, v.specs::jsonb, 'https://www.wenproducts.com/generators'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('GN9500',   '9500W Dual Fuel',         NULL, 'generator-portable', 'dual-fuel',  7500,  899,  ARRAY['Dual fuel','Electric start','420cc OHV engine','30A outlet','Wheel kit'], '{"watts_starting": 9500, "runtime_hours_50pct": 8.5, "noise_dba": 73, "fuel_tank_gallons": 6.6, "outlets": "4x120V 1x120/240V 1x30A", "parallel_capable": false, "co_shutoff": false}'),
  ('GN6000',   '6000W Gas',               NULL, 'generator-portable', 'gas',         5000,  549,  ARRAY['Gas only','Electric start','272cc OHV engine','Fuel gauge'], '{"watts_starting": 6000, "runtime_hours_50pct": 10, "noise_dba": 72, "fuel_tank_gallons": 4.7, "outlets": "4x120V 1x120/240V", "parallel_capable": false, "co_shutoff": false}'),
  ('GN4500',   '4500W Dual Fuel',         NULL, 'generator-portable', 'dual-fuel',  3600,  449,  ARRAY['Dual fuel','Recoil start','212cc engine','RV ready'], '{"watts_starting": 4500, "runtime_hours_50pct": 10, "noise_dba": 70, "fuel_tank_gallons": 4, "outlets": "3x120V 1x30A RV", "parallel_capable": false, "co_shutoff": false}'),
  ('56380i',   '3800W Inverter',          NULL, 'generator-inverter', 'gas',         3400,  699,  ARRAY['Inverter technology','Electric start','Eco mode','Parallel capable','CO watchdog'], '{"watts_starting": 3800, "runtime_hours_50pct": 10.5, "noise_dba": 57, "fuel_tank_gallons": 2.2, "outlets": "2x120V 1x30A 2xUSB", "parallel_capable": true, "co_shutoff": true}'),
  ('56235i',   '2350W Inverter',          NULL, 'generator-inverter', 'gas',         1900,  449,  ARRAY['Compact inverter','Parallel capable','Eco mode','USB outlets','CO watchdog'], '{"watts_starting": 2350, "runtime_hours_50pct": 10, "noise_dba": 51, "fuel_tank_gallons": 1.0, "outlets": "2x120V 2xUSB", "parallel_capable": true, "co_shutoff": true}'),
  ('56125i',   '1250W Inverter',          NULL, 'generator-inverter', 'gas',         1000,  299,  ARRAY['Ultra-portable 33 lbs','Super quiet','Parallel capable','USB ports'], '{"watts_starting": 1250, "runtime_hours_50pct": 10.5, "noise_dba": 48, "fuel_tank_gallons": 0.7, "outlets": "1x120V 2xUSB", "parallel_capable": true, "co_shutoff": false}'),
  ('DF1100T',  '11000W Dual Fuel',        NULL, 'generator-portable', 'dual-fuel',  8300, 1199, ARRAY['Dual fuel','Electric start','457cc V-Twin','50A outlet','Wheel kit'], '{"watts_starting": 11000, "runtime_hours_50pct": 7.5, "noise_dba": 76, "fuel_tank_gallons": 8.3, "outlets": "4x120V GFCI 1x120/240V 1x50A", "parallel_capable": false, "co_shutoff": false}'),
  ('56475',    '4750W Dual Fuel Open Frame','GN','generator-portable', 'dual-fuel',  3800,  499,  ARRAY['Dual fuel','Electric start','223cc engine','RV ready'], '{"watts_starting": 4750, "runtime_hours_50pct": 11, "noise_dba": 70, "fuel_tank_gallons": 4, "outlets": "3x120V 1x30A RV", "parallel_capable": false, "co_shutoff": false}')
) AS v(model_number, model_name, series, cat_slug, fuel, cap, msrp, features, specs)
WHERE m.slug = 'wen' AND c.slug = v.cat_slug;


-- ============================================================================
-- ECOFLOW  (Power Stations)
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'battery', 'portable', NULL, v.cap, 'watt_hours', true, v.lifespan, true, false, v.msrp, v.features, v.specs::jsonb, 'https://www.ecoflow.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DELTA Pro 3',    'DELTA Pro 3',                'DELTA',    4096, 10, 3699, ARRAY['4kWh expandable to 12kWh','X-Stream 2200W charging','Home backup with smart panel','LFP battery','App control','240V output'], '{"watt_hours": 4096, "watts_output": 4000, "watts_surge": 8000, "battery_type": "LiFePO4", "cycles": 4000, "solar_input_watts": 1600, "weight_lbs": 114}'),
  ('DELTA Pro',      'DELTA Pro',                  'DELTA',    3600, 10, 2299, ARRAY['3.6kWh expandable to 25kWh','X-Stream 1800W charging','Smart home panel option','LFP battery','App control'], '{"watt_hours": 3600, "watts_output": 3600, "watts_surge": 7200, "battery_type": "LiFePO4", "cycles": 3500, "solar_input_watts": 1600, "weight_lbs": 84}'),
  ('DELTA Pro Ultra','DELTA Pro Ultra',            'DELTA',    6144, 10, 5799, ARRAY['6.1kWh to 90kWh scalable','Home backup integration','Smart panel 2','240V 7200W output','LFP battery'], '{"watt_hours": 6144, "watts_output": 7200, "watts_surge": 14400, "battery_type": "LiFePO4", "cycles": 4000, "solar_input_watts": 5600, "weight_lbs": 170}'),
  ('DELTA 2 Max',    'DELTA 2 Max',                'DELTA',    2048, 10, 1699, ARRAY['2kWh expandable to 6kWh','X-Stream 1500W charging','LFP battery','6 AC outlets','App control'], '{"watt_hours": 2048, "watts_output": 2400, "watts_surge": 4800, "battery_type": "LiFePO4", "cycles": 3000, "solar_input_watts": 1000, "weight_lbs": 51}'),
  ('DELTA 2',        'DELTA 2',                    'DELTA',    1024, 10, 999,  ARRAY['1kWh expandable to 3kWh','X-Stream 1200W fast charging','LFP battery','App monitoring'], '{"watt_hours": 1024, "watts_output": 1800, "watts_surge": 2700, "battery_type": "LiFePO4", "cycles": 3000, "solar_input_watts": 500, "weight_lbs": 27}'),
  ('DELTA 3 Plus',   'DELTA 3 Plus',               'DELTA',    1024, 10, 1199, ARRAY['1kWh expandable','X-Boost 1800W','GaN inverter','Ultra-fast charging','240V with two units'], '{"watt_hours": 1024, "watts_output": 1800, "watts_surge": 3600, "battery_type": "LiFePO4", "cycles": 4000, "solar_input_watts": 800, "weight_lbs": 25}'),
  ('RIVER 3 Plus',   'RIVER 3 Plus',               'RIVER',     600, 10, 599,  ARRAY['600Wh portable','X-Boost 1000W','Fast recharge 56 min','App control','Lightweight'], '{"watt_hours": 600, "watts_output": 600, "watts_surge": 1200, "battery_type": "LiFePO4", "cycles": 4000, "solar_input_watts": 220, "weight_lbs": 17}'),
  ('RIVER 3',        'RIVER 3',                    'RIVER',     245, 10, 269,  ARRAY['245Wh ultra-portable','X-Boost 600W','Fast recharge','USB-C 100W','Compact design'], '{"watt_hours": 245, "watts_output": 230, "watts_surge": 460, "battery_type": "LiFePO4", "cycles": 4000, "solar_input_watts": 110, "weight_lbs": 8}'),
  ('RIVER 2 Pro',    'RIVER 2 Pro',                'RIVER',     768, 10, 599,  ARRAY['768Wh capacity','X-Stream 800W fast charging','LFP battery','App control','4 AC outlets'], '{"watt_hours": 768, "watts_output": 800, "watts_surge": 1600, "battery_type": "LiFePO4", "cycles": 3000, "solar_input_watts": 220, "weight_lbs": 17}'),
  ('RIVER 2 Max',    'RIVER 2 Max',                'RIVER',     512, 10, 399,  ARRAY['512Wh capacity','X-Stream 660W charging','LFP battery','Bluetooth+Wi-Fi'], '{"watt_hours": 512, "watts_output": 500, "watts_surge": 1000, "battery_type": "LiFePO4", "cycles": 3000, "solar_input_watts": 220, "weight_lbs": 14}'),
  ('DELTA Mini',     'DELTA Mini',                 'DELTA',     882, 8,  599,  ARRAY['882Wh capacity','X-Stream 900W fast charge','5 AC outlets','USB-C 100W PD'], '{"watt_hours": 882, "watts_output": 1400, "watts_surge": 2100, "battery_type": "Li-ion NMC", "cycles": 800, "solar_input_watts": 300, "weight_lbs": 24}'),
  ('DELTA Max 2000', 'DELTA Max 2000',             'DELTA',    2016, 10, 1799, ARRAY['2kWh expandable to 6kWh','X-Stream 1800W fast charge','Emergency backup','Dual charging'], '{"watt_hours": 2016, "watts_output": 2400, "watts_surge": 4600, "battery_type": "Li-ion NMC", "cycles": 800, "solar_input_watts": 900, "weight_lbs": 48}')
) AS v(model_number, model_name, series, cap, lifespan, msrp, features, specs)
WHERE m.slug = 'ecoflow' AND c.slug = 'power-station';


-- ============================================================================
-- JACKERY  (Power Stations)
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'battery', 'portable', NULL, v.cap, 'watt_hours', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, 'https://www.jackery.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('Explorer 3000 Pro',  'Explorer 3000 Pro',   'Explorer', 3024, 10, true,  2499, ARRAY['3024Wh LFP battery','3000W output','Smart app control','Fast wall charging','11 output ports'], '{"watt_hours": 3024, "watts_output": 3000, "watts_surge": 6000, "battery_type": "LiFePO4", "cycles": 2000, "solar_input_watts": 1400, "weight_lbs": 64}'),
  ('Explorer 2000 Plus', 'Explorer 2000 Plus',  'Explorer', 2042, 10, true,  1899, ARRAY['2042Wh expandable to 24kWh','LFP battery','3000W output','App control','ChargeShield'], '{"watt_hours": 2042, "watts_output": 3000, "watts_surge": 6000, "battery_type": "LiFePO4", "cycles": 4000, "solar_input_watts": 1200, "weight_lbs": 61}'),
  ('Explorer 1000 Plus', 'Explorer 1000 Plus',  'Explorer', 1264, 10, true,  1299, ARRAY['1264Wh expandable','LFP battery','2000W output','App control','Fast charging'], '{"watt_hours": 1264, "watts_output": 2000, "watts_surge": 4000, "battery_type": "LiFePO4", "cycles": 4000, "solar_input_watts": 800, "weight_lbs": 32}'),
  ('Explorer 1500 Pro',  'Explorer 1500 Pro',   'Explorer', 1512, 8,  false, 1399, ARRAY['1512Wh capacity','1800W output','Ultra-fast solar charging','9 outputs','Foldable handle'], '{"watt_hours": 1512, "watts_output": 1800, "watts_surge": 3600, "battery_type": "Li-ion NMC", "cycles": 800, "solar_input_watts": 1400, "weight_lbs": 35}'),
  ('Explorer 1000 Pro',  'Explorer 1000 Pro',   'Explorer', 1002, 8,  false, 999,  ARRAY['1002Wh capacity','1000W output','Wall recharge in 1.8h','Compact design'], '{"watt_hours": 1002, "watts_output": 1000, "watts_surge": 2000, "battery_type": "Li-ion NMC", "cycles": 800, "solar_input_watts": 800, "weight_lbs": 25}'),
  ('Explorer 600 Plus',  'Explorer 600 Plus',   'Explorer',  632, 10, true,  699,  ARRAY['632Wh LFP battery','800W output','Fast charging','UPS function','Lightweight'], '{"watt_hours": 632, "watts_output": 800, "watts_surge": 1600, "battery_type": "LiFePO4", "cycles": 4000, "solar_input_watts": 200, "weight_lbs": 18}'),
  ('Explorer 500',       'Explorer 500',        'Explorer',  518, 8,  false, 499,  ARRAY['518Wh capacity','500W output','Pure sine wave','LCD display','Lightweight'], '{"watt_hours": 518, "watts_output": 500, "watts_surge": 1000, "battery_type": "Li-ion NMC", "cycles": 500, "solar_input_watts": 100, "weight_lbs": 13}'),
  ('Explorer 300 Plus',  'Explorer 300 Plus',   'Explorer',  288, 10, true,  299,  ARRAY['288Wh LFP battery','300W output','Ultra-portable 8 lbs','USB-C 100W PD'], '{"watt_hours": 288, "watts_output": 300, "watts_surge": 600, "battery_type": "LiFePO4", "cycles": 3000, "solar_input_watts": 100, "weight_lbs": 8}'),
  ('Explorer 100 Plus',  'Explorer 100 Plus',   'Explorer',   99, 10, false, 149,  ARRAY['99Wh ultra-portable','128W output','USB-C 100W PD','TSA-approved'], '{"watt_hours": 99, "watts_output": 128, "watts_surge": 256, "battery_type": "LiFePO4", "cycles": 3000, "solar_input_watts": 65, "weight_lbs": 3}'),
  ('Explorer 2000 Pro',  'Explorer 2000 Pro',   'Explorer', 2160, 8,  false, 1999, ARRAY['2160Wh capacity','2200W output','Fast solar charging','Foldable handle'], '{"watt_hours": 2160, "watts_output": 2200, "watts_surge": 4400, "battery_type": "Li-ion NMC", "cycles": 800, "solar_input_watts": 1400, "weight_lbs": 43}')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs)
WHERE m.slug = 'jackery' AND c.slug = 'power-station';


-- ============================================================================
-- BLUETTI  (Power Stations)
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'battery', 'portable', NULL, v.cap, 'watt_hours', true, v.lifespan, true, false, v.msrp, v.features, v.specs::jsonb, 'https://www.bluettipower.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('AC300',       'AC300 + B300',          'AC',       3072, 10, 3098, ARRAY['3072Wh with B300 battery','3000W output','Modular expandable to 12kWh','LFP battery','Split-phase 240V','App control','UPS function'], '{"watt_hours": 3072, "watts_output": 3000, "watts_surge": 6000, "battery_type": "LiFePO4", "cycles": 3500, "solar_input_watts": 2400, "weight_lbs": 137}'),
  ('AC500',       'AC500 + B300S',         'AC',       3072, 10, 4399, ARRAY['5000W output','Modular up to 18.4kWh','LFP battery','Split-phase 240V 5000W','App control','UPS function'], '{"watt_hours": 3072, "watts_output": 5000, "watts_surge": 10000, "battery_type": "LiFePO4", "cycles": 3500, "solar_input_watts": 3000, "weight_lbs": 143}'),
  ('AC200MAX',    'AC200MAX',              'AC',       2048, 10, 1799, ARRAY['2048Wh expandable to 8192Wh','2200W output','LFP battery','App control','7 ways to recharge'], '{"watt_hours": 2048, "watts_output": 2200, "watts_surge": 4800, "battery_type": "LiFePO4", "cycles": 3500, "solar_input_watts": 900, "weight_lbs": 62}'),
  ('AC200P',      'AC200P',                'AC',       2000, 10, 1499, ARRAY['2000Wh capacity','2000W output','LFP battery','17 output ports','Wireless charging pad'], '{"watt_hours": 2000, "watts_output": 2000, "watts_surge": 4800, "battery_type": "LiFePO4", "cycles": 3500, "solar_input_watts": 700, "weight_lbs": 60}'),
  ('AC200L',      'AC200L',                'AC',       2048, 10, 1599, ARRAY['2048Wh expandable to 8192Wh','2400W output','LFP battery','App control','Lift-off design'], '{"watt_hours": 2048, "watts_output": 2400, "watts_surge": 3600, "battery_type": "LiFePO4", "cycles": 3000, "solar_input_watts": 1200, "weight_lbs": 62}'),
  ('AC180',       'AC180',                 'AC',       1152, 10, 999,  ARRAY['1152Wh capacity','1800W output','LFP battery','Fast turbo charging','App control'], '{"watt_hours": 1152, "watts_output": 1800, "watts_surge": 2700, "battery_type": "LiFePO4", "cycles": 3500, "solar_input_watts": 500, "weight_lbs": 35}'),
  ('AC70',        'AC70',                  'AC',        768, 10, 549,  ARRAY['768Wh capacity','1000W output','LFP battery','Compact design','UPS mode'], '{"watt_hours": 768, "watts_output": 1000, "watts_surge": 2000, "battery_type": "LiFePO4", "cycles": 3500, "solar_input_watts": 200, "weight_lbs": 22}'),
  ('AC60',        'AC60',                  'AC',        403, 10, 449,  ARRAY['403Wh capacity','600W output','IP65 dustproof/waterproof','LFP battery','Rugged outdoor design'], '{"watt_hours": 403, "watts_output": 600, "watts_surge": 1200, "battery_type": "LiFePO4", "cycles": 3000, "solar_input_watts": 200, "weight_lbs": 19}'),
  ('EB70S',       'EB70S',                 'EB',        716, 10, 499,  ARRAY['716Wh capacity','800W output','LFP battery','12 output ports','200W solar input'], '{"watt_hours": 716, "watts_output": 800, "watts_surge": 1400, "battery_type": "LiFePO4", "cycles": 2500, "solar_input_watts": 200, "weight_lbs": 21}'),
  ('EB3A',        'EB3A',                  'EB',        268, 10, 229,  ARRAY['268Wh compact','600W output','LFP battery','App control','Wireless charging'], '{"watt_hours": 268, "watts_output": 600, "watts_surge": 1200, "battery_type": "LiFePO4", "cycles": 2500, "solar_input_watts": 200, "weight_lbs": 10}'),
  ('AC180P',      'AC180P',                'AC',       1440, 10, 1199, ARRAY['1440Wh capacity','2700W output','LFP battery','Fast turbo charge','Home UPS function'], '{"watt_hours": 1440, "watts_output": 2700, "watts_surge": 4000, "battery_type": "LiFePO4", "cycles": 3500, "solar_input_watts": 500, "weight_lbs": 37}'),
  ('EP500Pro',    'EP500Pro Home Backup',  'EP',       5120, 10, 4999, ARRAY['5.1kWh home battery','3000W output','30A outlet','240V split-phase','LFP battery','Whole-home UPS'], '{"watt_hours": 5120, "watts_output": 3000, "watts_surge": 6000, "battery_type": "LiFePO4", "cycles": 3500, "solar_input_watts": 2400, "weight_lbs": 176}')
) AS v(model_number, model_name, series, cap, lifespan, msrp, features, specs)
WHERE m.slug = 'bluetti' AND c.slug = 'power-station';


-- ============================================================================
-- ANKER SOLIX  (Power Stations)
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'battery', 'portable', NULL, v.cap, 'watt_hours', true, v.lifespan, true, false, v.msrp, v.features, v.specs::jsonb, 'https://www.anker.com/solix'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('F3800',       'SOLIX F3800',               'SOLIX',   3840, 10, 3999, ARRAY['3.84kWh expandable to 26.9kWh','6000W output','120V/240V','LFP battery','NEMA 14-50 outlet','Home panel option','App control'], '{"watt_hours": 3840, "watts_output": 6000, "watts_surge": 9000, "battery_type": "LiFePO4", "cycles": 3500, "solar_input_watts": 2400, "weight_lbs": 132}'),
  ('F2600',       'SOLIX F2600',               'SOLIX',   2560, 10, 1999, ARRAY['2560Wh capacity','2400W output','LFP battery','Fast recharge','App control','RV ready'], '{"watt_hours": 2560, "watts_output": 2400, "watts_surge": 4800, "battery_type": "LiFePO4", "cycles": 3000, "solar_input_watts": 1000, "weight_lbs": 60}'),
  ('F2000',       'SOLIX F2000 (PowerHouse 767)','SOLIX', 2048, 10, 1699, ARRAY['2048Wh capacity','2400W output','LFP battery','GaNPrime technology','HyperFlash recharge'], '{"watt_hours": 2048, "watts_output": 2400, "watts_surge": 4600, "battery_type": "LiFePO4", "cycles": 3000, "solar_input_watts": 1000, "weight_lbs": 54}'),
  ('F1500',       'SOLIX F1500 (PowerHouse 757)','SOLIX', 1500, 10, 1299, ARRAY['1500Wh capacity','1800W output','LFP battery','HyperFlash recharge 1h','6 AC outlets'], '{"watt_hours": 1500, "watts_output": 1800, "watts_surge": 2400, "battery_type": "LiFePO4", "cycles": 3000, "solar_input_watts": 600, "weight_lbs": 42}'),
  ('F1200',       'SOLIX F1200 (C1000)',       'SOLIX',   1056, 10, 799,  ARRAY['1056Wh capacity','1800W output with SurgePad','LFP battery','Compact design','App control'], '{"watt_hours": 1056, "watts_output": 1200, "watts_surge": 1800, "battery_type": "LiFePO4", "cycles": 3000, "solar_input_watts": 400, "weight_lbs": 28}'),
  ('C300',        'SOLIX C300 DC',             'SOLIX',    288, 10, 199,  ARRAY['288Wh ultra-portable','300W DC output','USB-C 140W','LFP battery','Compact camping'], '{"watt_hours": 288, "watts_output": 300, "watts_surge": 600, "battery_type": "LiFePO4", "cycles": 3000, "solar_input_watts": 100, "weight_lbs": 8}'),
  ('C800',        'SOLIX C800',                'SOLIX',    768, 10, 599,  ARRAY['768Wh capacity','1200W output','LFP battery','Retractable handle','App control'], '{"watt_hours": 768, "watts_output": 1200, "watts_surge": 1800, "battery_type": "LiFePO4", "cycles": 3000, "solar_input_watts": 400, "weight_lbs": 24}'),
  ('C800 Plus',   'SOLIX C800 Plus',           'SOLIX',    768, 10, 649,  ARRAY['768Wh capacity','1600W output','LFP battery','SurgePad 2300W','Built-in light'], '{"watt_hours": 768, "watts_output": 1600, "watts_surge": 2300, "battery_type": "LiFePO4", "cycles": 3000, "solar_input_watts": 400, "weight_lbs": 24}'),
  ('F3800 BP',    'SOLIX BP3800 Expansion',    'SOLIX',   3840, 10, 2599, ARRAY['3.84kWh expansion battery','Works with F3800','LFP battery','Daisy-chain capable'], '{"watt_hours": 3840, "watts_output": 0, "watts_surge": 0, "battery_type": "LiFePO4", "cycles": 3500, "solar_input_watts": 0, "weight_lbs": 110}')
) AS v(model_number, model_name, series, cap, lifespan, msrp, features, specs)
WHERE m.slug = 'anker-solix' AND c.slug = 'power-station';


-- ============================================================================
-- GOAL ZERO  (Power Stations)
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'battery', 'portable', NULL, v.cap, 'watt_hours', true, v.lifespan, true, false, v.msrp, v.features, v.specs::jsonb, 'https://www.goalzero.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('Yeti 6000X',   'Yeti 6000X',              'Yeti',   6071, 10, 5499, ARRAY['6071Wh capacity','2000W output','Tank expansion ready','Li-ion NMC','App control','Integrated MPPT'], '{"watt_hours": 6071, "watts_output": 2000, "watts_surge": 3500, "battery_type": "Li-ion NMC", "cycles": 500, "solar_input_watts": 600, "weight_lbs": 106}'),
  ('Yeti 3000X',   'Yeti 3000X',              'Yeti',   2982, 10, 3499, ARRAY['2982Wh capacity','2000W output','Tank expansion ready','Li-ion NMC','App control'], '{"watt_hours": 2982, "watts_output": 2000, "watts_surge": 3500, "battery_type": "Li-ion NMC", "cycles": 500, "solar_input_watts": 600, "weight_lbs": 70}'),
  ('Yeti 1500X',   'Yeti 1500X',              'Yeti',   1516, 10, 1999, ARRAY['1516Wh capacity','2000W output','MPPT charge controller','App control','Multiple output ports'], '{"watt_hours": 1516, "watts_output": 2000, "watts_surge": 3500, "battery_type": "Li-ion NMC", "cycles": 500, "solar_input_watts": 600, "weight_lbs": 46}'),
  ('Yeti 1000X',   'Yeti 1000X',              'Yeti',   983,  10, 1299, ARRAY['983Wh capacity','1500W output','MPPT','App control','Compact design'], '{"watt_hours": 983, "watts_output": 1500, "watts_surge": 2500, "battery_type": "Li-ion NMC", "cycles": 500, "solar_input_watts": 300, "weight_lbs": 32}'),
  ('Yeti 500X',    'Yeti 500X',               'Yeti',   505,  10, 699,  ARRAY['505Wh capacity','300W output','MPPT','App control','Lightweight'], '{"watt_hours": 505, "watts_output": 300, "watts_surge": 600, "battery_type": "Li-ion NMC", "cycles": 500, "solar_input_watts": 150, "weight_lbs": 13}'),
  ('Yeti 200X',    'Yeti 200X',               'Yeti',   187,  10, 299,  ARRAY['187Wh ultra-portable','120W output','USB-C PD 60W','USB-A','Compact camping power'], '{"watt_hours": 187, "watts_output": 120, "watts_surge": 240, "battery_type": "Li-ion NMC", "cycles": 500, "solar_input_watts": 100, "weight_lbs": 5}'),
  ('Yeti PRO 4000','Yeti PRO 4000',           'Yeti PRO',3995, 10, 4499, ARRAY['3995Wh LFP battery','3000W output','Expansion to 12kWh','Tank Pro expansion','App control','Home integration'], '{"watt_hours": 3995, "watts_output": 3000, "watts_surge": 6000, "battery_type": "LiFePO4", "cycles": 3000, "solar_input_watts": 1200, "weight_lbs": 94}'),
  ('Yeti 1000 Core','Yeti 1000 Core',         'Yeti',   983,  10, 899,  ARRAY['983Wh capacity','1200W output','Budget-friendly Yeti','Integrated MPPT','Compact'], '{"watt_hours": 983, "watts_output": 1200, "watts_surge": 2000, "battery_type": "Li-ion NMC", "cycles": 500, "solar_input_watts": 300, "weight_lbs": 31}')
) AS v(model_number, model_name, series, cap, lifespan, msrp, features, specs)
WHERE m.slug = 'goal-zero' AND c.slug = 'power-station';


-- ============================================================================
-- EGO POWER+  (Power Stations - Battery platform)
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'battery', 'portable', NULL, v.cap, 'watt_hours', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, 'https://www.egopowerplus.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('PST3042',    'Nexus Power Station',             'Nexus',    3000, 10, true,  5499, ARRAY['3000W output','Uses EGO 56V batteries','4 battery bays','120V/240V','Portable whole-home backup','App control'], '{"watt_hours": 3000, "watts_output": 3000, "watts_surge": 6000, "battery_type": "Li-ion 56V", "cycles": 1000, "solar_input_watts": 0, "weight_lbs": 90}'),
  ('PST3041',    'Nexus Portable Power Station',    'Nexus',    2000, 10, false, 2499, ARRAY['2000W output','Uses EGO 56V batteries','Interchangeable with lawn tools','Portable design'], '{"watt_hours": 2000, "watts_output": 2000, "watts_surge": 4000, "battery_type": "Li-ion 56V", "cycles": 1000, "solar_input_watts": 0, "weight_lbs": 52}'),
  ('PAD1500',    'Nexus Escape 150',                'Nexus',     150, 10, false, 199,  ARRAY['150Wh portable','Uses EGO 56V battery','USB-C 100W PD','Compact camping power','Cross-compatible'], '{"watt_hours": 150, "watts_output": 150, "watts_surge": 300, "battery_type": "Li-ion 56V", "cycles": 1000, "solar_input_watts": 0, "weight_lbs": 6}'),
  ('PST3043',    'Nexus Power Station X',           'Nexus',    4000, 10, true,  6999, ARRAY['4000W output','6-battery capacity','240V split-phase','Home backup panel','App control','50A outlet'], '{"watt_hours": 4000, "watts_output": 4000, "watts_surge": 7500, "battery_type": "Li-ion 56V", "cycles": 1000, "solar_input_watts": 0, "weight_lbs": 105}')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs)
WHERE m.slug = 'ego-power' AND c.slug = 'power-station';

-- EGO Inverter Generator (battery-powered)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'battery', 'portable', NULL, v.cap, 'watts', true, 10, false, false, v.msrp, v.features, v.specs::jsonb, 'https://www.egopowerplus.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('GS3020E',  'EGO 3000W Generator',  'Nexus', 2400, 3499, ARRAY['Battery-powered generator','Zero emissions','Ultra-quiet','Uses EGO 56V batteries','No gas or fumes'], '{"watts_starting": 3000, "runtime_hours_50pct": 4, "noise_dba": 42, "fuel_tank_gallons": 0, "outlets": "4x120V 1x120/240V", "parallel_capable": false, "co_shutoff": false}'),
  ('GS2400',   'EGO 2400W Generator',  'Nexus', 2000, 1499, ARRAY['Battery-powered generator','Zero emissions','Quiet operation','Uses EGO 56V batteries'], '{"watts_starting": 2400, "runtime_hours_50pct": 3, "noise_dba": 44, "fuel_tank_gallons": 0, "outlets": "4x120V", "parallel_capable": false, "co_shutoff": false}')
) AS v(model_number, model_name, series, cap, msrp, features, specs)
WHERE m.slug = 'ego-power' AND c.slug = 'generator-inverter';


-- ============================================================================
-- VERIFY COUNTS
-- ============================================================================
-- Expected totals:
-- Generac:     11 standby + 5 portable + 4 inverter = 20
-- Kohler:       8 standby = 8
-- Cummins:      6 standby = 6
-- Winco:        3 gas standby + 2 diesel standby = 5
-- Honda:        9 inverter + 3 portable = 12
-- Yamaha:       6 inverter + 2 portable = 8
-- Champion:     6 portable + 7 inverter + 3 standby = 16
-- Westinghouse: 6 portable + 6 inverter = 12
-- Briggs:       5 portable + 3 inverter + 5 standby = 13
-- DuroMax:      6 portable + 5 inverter = 11
-- Firman:       5 portable + 3 inverter = 8
-- WEN:          4 portable + 4 inverter = 8
-- EcoFlow:     12 power stations = 12
-- Jackery:     10 power stations = 10
-- Bluetti:     12 power stations = 12
-- Anker SOLIX:  9 power stations = 9
-- Goal Zero:    8 power stations = 8
-- EGO Power+:   4 power stations + 2 inverter = 6
-- ─────────────────────────────────
-- GRAND TOTAL: 184 models
--
-- Note: Additional models below bring total above 250.


-- ============================================================================
-- ADDITIONAL GENERAC MODELS  (to reach 250+)
-- ============================================================================

-- Generac PWRcell (Home Battery / Power Station category)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'battery', 'standby', NULL, v.cap, 'watt_hours', true, 10, true, false, v.msrp, v.features, v.specs::jsonb, 'https://www.generac.com/all-products/clean-energy/pwrcell'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('PWRcell M6',     'PWRcell M6',                'PWRcell',  9000, 12999, ARRAY['9kWh home battery','Modular expandable to 18kWh','Automatic transfer','Solar + grid charging','PWRview app','Whole-home backup'], '{"watt_hours": 9000, "watts_output": 9000, "watts_surge": 11000, "battery_type": "Li-ion NMC", "cycles": 7300, "solar_input_watts": 7600, "weight_lbs": 295}'),
  ('PWRcell M4',     'PWRcell M4',                'PWRcell',  6000, 9999,  ARRAY['6kWh modular home battery','Expandable','Solar integration','PWRview monitoring','Backup power'], '{"watt_hours": 6000, "watts_output": 6000, "watts_surge": 9000, "battery_type": "Li-ion NMC", "cycles": 7300, "solar_input_watts": 7600, "weight_lbs": 230}'),
  ('PWRcell M3',     'PWRcell M3',                'PWRcell',  4500, 7999,  ARRAY['4.5kWh entry point','Expandable','Solar integration','PWRview monitoring'], '{"watt_hours": 4500, "watts_output": 4500, "watts_surge": 6000, "battery_type": "Li-ion NMC", "cycles": 7300, "solar_input_watts": 7600, "weight_lbs": 195}'),
  ('PWRgenerator',   'PWRgenerator',              'PWRcell',  0,    2999,  ARRAY['Clean energy generator','Pairs with PWRcell','Indoor rated','Grid-forming inverter'], '{"watt_hours": 0, "watts_output": 9000, "watts_surge": 11000, "battery_type": "n/a", "cycles": 0, "solar_input_watts": 0, "weight_lbs": 130}')
) AS v(model_number, model_name, series, cap, msrp, features, specs)
WHERE m.slug = 'generac' AND c.slug = 'power-station';


-- ============================================================================
-- ADDITIONAL CHAMPION MODELS
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'portable', NULL, v.cap, 'watts', true, 12, false, false, v.msrp, v.features, v.specs::jsonb, 'https://www.championpowerequipment.com/generators'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('200954',   '11500W/9200W Dual Fuel',     NULL,  'generator-portable', 'dual-fuel',  9200, 1599, ARRAY['Dual fuel','Electric start','459cc engine','CO Shield','50A outlet','Digital meter'], '{"watts_starting": 11500, "runtime_hours_50pct": 9, "noise_dba": 76, "fuel_tank_gallons": 8.5, "outlets": "4x120V GFCI 1x120/240V 1x50A", "parallel_capable": false, "co_shutoff": true}'),
  ('100165',   '3400W Dual Fuel Inverter RV', NULL,  'generator-inverter', 'dual-fuel',  3100, 1049, ARRAY['Dual fuel inverter','Electric start','RV ready 30A','Parallel capable','Quiet 59dB'], '{"watts_starting": 3400, "runtime_hours_50pct": 7.5, "noise_dba": 59, "fuel_tank_gallons": 1.6, "outlets": "2x120V 1x30A RV 2xUSB", "parallel_capable": true, "co_shutoff": false}'),
  ('200987',   '4250W Dual Fuel RV Ready',   NULL,  'generator-inverter', 'dual-fuel',  3500, 1149, ARRAY['Dual fuel inverter','Electric start','RV ready 30A/50A','CO Shield','Parallel ready'], '{"watts_starting": 4250, "runtime_hours_50pct": 16, "noise_dba": 61, "fuel_tank_gallons": 2.9, "outlets": "2x120V 1x30A 1xUSB-C", "parallel_capable": true, "co_shutoff": true}')
) AS v(model_number, model_name, series, cat_slug, fuel, cap, msrp, features, specs)
WHERE m.slug = 'champion-power' AND c.slug = v.cat_slug;


-- ============================================================================
-- ADDITIONAL WESTINGHOUSE MODELS
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'portable', NULL, v.cap, 'watts', true, 12, false, false, v.msrp, v.features, v.specs::jsonb, 'https://www.westinghouseoutdoorpower.com/generators'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('iGen4500cv',   '4500W RV Ready Inverter CO Sensor', 'iGen', 'generator-inverter', 'gas',       3700, 1049, ARRAY['Gas inverter','CO sensor auto shutoff','Remote start','RV ready 30A','LED display'], '{"watts_starting": 4500, "runtime_hours_50pct": 18, "noise_dba": 52, "fuel_tank_gallons": 3.4, "outlets": "3x120V 1x30A RV 2xUSB", "parallel_capable": true, "co_shutoff": true}'),
  ('WGen11500TFc', '11500W Tri Fuel',                   'WGen', 'generator-portable', 'gas',      11500, 1799, ARRAY['Tri fuel: gas/propane/natural gas','Remote electric start','CO sensor','50A outlet','VFT display'], '{"watts_starting": 14500, "runtime_hours_50pct": 9, "noise_dba": 76, "fuel_tank_gallons": 10.5, "outlets": "4x120V GFCI 1x120/240V 1x50A", "parallel_capable": false, "co_shutoff": true}'),
  ('WGen5300v',    '5300W Gas Portable',                 'WGen', 'generator-portable', 'gas',       5300, 599,  ARRAY['Gas only','Remote electric start','VFT display','Transfer switch ready'], '{"watts_starting": 6600, "runtime_hours_50pct": 13, "noise_dba": 69, "fuel_tank_gallons": 4, "outlets": "3x120V 1x120/240V", "parallel_capable": false, "co_shutoff": false}'),
  ('iPro4200',     '4200W Professional Inverter',        'iPro', 'generator-inverter', 'gas',       3500, 999,  ARRAY['Professional grade','Open frame inverter','Electric start','GFCI outlets'], '{"watts_starting": 4200, "runtime_hours_50pct": 12, "noise_dba": 64, "fuel_tank_gallons": 3.4, "outlets": "4x120V GFCI 1x120/240V", "parallel_capable": false, "co_shutoff": false}')
) AS v(model_number, model_name, series, cat_slug, fuel, cap, msrp, features, specs)
WHERE m.slug = 'westinghouse-power' AND c.slug = v.cat_slug;


-- ============================================================================
-- ADDITIONAL DUROMAX MODELS
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'portable', NULL, v.cap, 'watts', true, 12, false, false, v.msrp, v.features, v.specs::jsonb, 'https://www.duromax.com/generators'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('XP16000HX',  '16000W Dual Fuel V-Twin',    'XP',  'generator-portable', 'dual-fuel', 13000, 2499, ARRAY['Dual fuel V-Twin','Electric start','16000W starting','50A outlet','CO alert','MX2 power boost'], '{"watts_starting": 16000, "runtime_hours_50pct": 8, "noise_dba": 78, "fuel_tank_gallons": 10, "outlets": "4x120V GFCI 1x120/240V 1x50A", "parallel_capable": false, "co_shutoff": true}'),
  ('XP2000iS',   '2000W Gas Inverter',         'XP',  'generator-inverter', 'gas',        1600, 449,  ARRAY['Gas inverter','Ultra-quiet 50dBA','Parallel capable','Digital display','Compact 46 lbs'], '{"watts_starting": 2000, "runtime_hours_50pct": 12, "noise_dba": 50, "fuel_tank_gallons": 0.95, "outlets": "2x120V 1xUSB", "parallel_capable": true, "co_shutoff": false}'),
  ('XP4850EH',   '4850W Dual Fuel',            'XP',  'generator-portable', 'dual-fuel',  3850, 599,  ARRAY['Dual fuel','Electric start','210cc engine','RV ready 30A'], '{"watts_starting": 4850, "runtime_hours_50pct": 10, "noise_dba": 69, "fuel_tank_gallons": 4, "outlets": "3x120V 1x30A RV", "parallel_capable": false, "co_shutoff": false}'),
  ('XP10000EH',  '10000W Dual Fuel',           'XP',  'generator-portable', 'dual-fuel',  8000, 1299, ARRAY['Dual fuel','Electric start','420cc engine','CO alert','50A outlet'], '{"watts_starting": 10000, "runtime_hours_50pct": 8.5, "noise_dba": 74, "fuel_tank_gallons": 8.3, "outlets": "4x120V GFCI 1x120/240V 1x50A", "parallel_capable": false, "co_shutoff": true}'),
  ('XP6500EH',   '6500W Dual Fuel',            'XP',  'generator-portable', 'dual-fuel',  5500, 799,  ARRAY['Dual fuel','Electric start','274cc engine','CO alert'], '{"watts_starting": 6500, "runtime_hours_50pct": 9, "noise_dba": 72, "fuel_tank_gallons": 5, "outlets": "4x120V 1x120/240V", "parallel_capable": false, "co_shutoff": true}')
) AS v(model_number, model_name, series, cat_slug, fuel, cap, msrp, features, specs)
WHERE m.slug = 'duromax' AND c.slug = v.cat_slug;


-- ============================================================================
-- ADDITIONAL FIRMAN MODELS
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'portable', NULL, v.cap, 'watts', true, 12, false, false, v.msrp, v.features, v.specs::jsonb, 'https://www.firmanpowerequipment.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('T08071',   '10000/8000W Tri Fuel',         NULL,  'generator-portable', 'gas',       8000,  1199, ARRAY['Tri fuel: gas/propane/NG','Electric start','CO alert','50A outlet','GFCI protection'], '{"watts_starting": 10000, "runtime_hours_50pct": 10.5, "noise_dba": 74, "fuel_tank_gallons": 8, "outlets": "4x120V GFCI 1x120/240V 1x30A 1x50A", "parallel_capable": false, "co_shutoff": true}'),
  ('W03381',   '3300/2600W Dual Fuel Inverter', NULL,  'generator-inverter', 'dual-fuel', 2600,  699,  ARRAY['Dual fuel inverter','Recoil start','CO alert','Parallel capable','Economy mode'], '{"watts_starting": 3300, "runtime_hours_50pct": 10, "noise_dba": 54, "fuel_tank_gallons": 1.8, "outlets": "2x120V 2xUSB", "parallel_capable": true, "co_shutoff": true}'),
  ('H03652',   '4550/3650W Dual Fuel',         NULL,  'generator-portable', 'dual-fuel', 3650,  599,  ARRAY['Dual fuel','Recoil start','Whisper Series quiet','CO alert'], '{"watts_starting": 4550, "runtime_hours_50pct": 14, "noise_dba": 67, "fuel_tank_gallons": 5, "outlets": "3x120V 1x30A RV", "parallel_capable": false, "co_shutoff": true}'),
  ('WH03242',  '4000/3200W Gas Inverter',      NULL,  'generator-inverter', 'gas',       3200,  749,  ARRAY['Gas inverter','Electric start','Parallel capable','Economy mode','USB-C outlet'], '{"watts_starting": 4000, "runtime_hours_50pct": 10, "noise_dba": 56, "fuel_tank_gallons": 2.0, "outlets": "2x120V 1x30A 1xUSB-C", "parallel_capable": true, "co_shutoff": false}')
) AS v(model_number, model_name, series, cat_slug, fuel, cap, msrp, features, specs)
WHERE m.slug = 'firman' AND c.slug = v.cat_slug;


-- ============================================================================
-- ADDITIONAL WEN MODELS
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'portable', NULL, v.cap, 'watts', true, 10, false, false, v.msrp, v.features, v.specs::jsonb, 'https://www.wenproducts.com/generators'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('56203i',    '2000W Super Quiet Inverter',   NULL,  'generator-inverter', 'gas',       1600, 399,  ARRAY['Super quiet 51 dBA','Inverter technology','Parallel capable','Economy mode','CARB/EPA III compliant'], '{"watts_starting": 2000, "runtime_hours_50pct": 9.4, "noise_dba": 51, "fuel_tank_gallons": 1.0, "outlets": "2x120V 1xUSB-A 1x12V DC", "parallel_capable": true, "co_shutoff": false}'),
  ('GN875i',    '8750W Dual Fuel Open Frame Inv',NULL, 'generator-inverter', 'dual-fuel', 7000, 1099, ARRAY['Open frame inverter','Dual fuel','Electric start','CO watchdog','GFCI outlets'], '{"watts_starting": 8750, "runtime_hours_50pct": 8, "noise_dba": 67, "fuel_tank_gallons": 5.5, "outlets": "4x120V GFCI 1x120/240V 1x50A", "parallel_capable": false, "co_shutoff": true}'),
  ('GN400i',    '4000W Open Frame Inverter',    NULL,  'generator-inverter', 'gas',       3500, 599,  ARRAY['Open frame inverter','Electric start','CO watchdog','Hour meter'], '{"watts_starting": 4000, "runtime_hours_50pct": 10, "noise_dba": 63, "fuel_tank_gallons": 2.4, "outlets": "3x120V GFCI 1x120/240V", "parallel_capable": false, "co_shutoff": true}'),
  ('DF475T',    '4750W Dual Fuel',              'GN',  'generator-portable', 'dual-fuel', 3800, 549,  ARRAY['Dual fuel','Electric start','223cc engine','Transfer switch ready'], '{"watts_starting": 4750, "runtime_hours_50pct": 11, "noise_dba": 70, "fuel_tank_gallons": 4, "outlets": "3x120V 1x30A RV", "parallel_capable": false, "co_shutoff": false}')
) AS v(model_number, model_name, series, cat_slug, fuel, cap, msrp, features, specs)
WHERE m.slug = 'wen' AND c.slug = v.cat_slug;


-- ============================================================================
-- ADDITIONAL HONDA MODELS
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'gas', 'portable', NULL, v.cap, 'watts', true, 15, false, false, v.msrp, v.features, v.specs::jsonb, 'https://www.powerequipment.honda.com/generators'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('EU2200iTAG',  '2200W CO-MINDER + Bluetooth',  'EU',  'generator-inverter', 1800, 1349, ARRAY['CO-MINDER safety','Bluetooth connectivity','Super quiet','Parallel capable','Eco-Throttle system'], '{"watts_starting": 2200, "runtime_hours_50pct": 8.1, "noise_dba": 48, "fuel_tank_gallons": 0.95, "outlets": "2x120V 2xUSB", "parallel_capable": true, "co_shutoff": true}'),
  ('EM6500SX',    '6500W Deluxe',                  'EM',  'generator-portable', 5500, 2699, ARRAY['Electric start','iAVR auto voltage','Fuel gauge','Oil Alert system','Full-frame protection'], '{"watts_starting": 6500, "runtime_hours_50pct": 10.2, "noise_dba": 74, "fuel_tank_gallons": 6.2, "outlets": "4x120V 1x120/240V", "parallel_capable": false, "co_shutoff": false}'),
  ('EG5000CL',    '5000W Economy',                 'EG',  'generator-portable', 4500, 1899, ARRAY['Commercial-grade','Economy class pricing','OHV engine','GFCI protection'], '{"watts_starting": 5000, "runtime_hours_50pct": 11, "noise_dba": 73, "fuel_tank_gallons": 6.2, "outlets": "4x120V GFCI 1x120/240V", "parallel_capable": false, "co_shutoff": false}')
) AS v(model_number, model_name, series, cat_slug, cap, msrp, features, specs)
WHERE m.slug = 'honda-power' AND c.slug = v.cat_slug;


-- ============================================================================
-- ADDITIONAL YAMAHA MODELS
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'gas', 'portable', NULL, v.cap, 'watts', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, 'https://www.yamaha-motor.com/power-products/generators'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('EF2600',      '2600W Portable',              'EF',  'generator-portable', 2300, 12, 899,  ARRAY['Compact portable','OHV engine','12V DC output','Auto decompressor for easy start'], '{"watts_starting": 2600, "runtime_hours_50pct": 10.5, "noise_dba": 68, "fuel_tank_gallons": 3.7, "outlets": "2x120V 1x12V DC", "parallel_capable": false, "co_shutoff": false}'),
  ('EF2400iSHC',  '2400W Inverter with CO Sensor','EF', 'generator-inverter', 2000, 15, 1199, ARRAY['Inverter technology','CO sensor shutoff','Twin Tech parallel','Smart throttle','Noise Block'], '{"watts_starting": 2400, "runtime_hours_50pct": 10, "noise_dba": 51, "fuel_tank_gallons": 1.6, "outlets": "2x120V 1xUSB", "parallel_capable": true, "co_shutoff": true}'),
  ('EF4500iSE-T', '4500W Inverter (Transfer Ready)','EF','generator-inverter', 3700, 15, 2799, ARRAY['Transfer switch ready','Electric start','Boost technology','CO sensor','30A twist-lock'], '{"watts_starting": 4500, "runtime_hours_50pct": 16, "noise_dba": 60, "fuel_tank_gallons": 4.5, "outlets": "2x120V 1x120/240V 1x30A", "parallel_capable": true, "co_shutoff": true}'),
  ('EF3000iSE',   '3000W Inverter Electric Start', 'EF', 'generator-inverter', 2800, 15, 2199, ARRAY['Electric start','Boost technology','CO sensor','Twin Tech parallel'], '{"watts_starting": 3000, "runtime_hours_50pct": 19, "noise_dba": 53, "fuel_tank_gallons": 3.4, "outlets": "2x120V 1x30A", "parallel_capable": true, "co_shutoff": true}')
) AS v(model_number, model_name, series, cat_slug, cap, lifespan, msrp, features, specs)
WHERE m.slug = 'yamaha-power' AND c.slug = v.cat_slug;


-- ============================================================================
-- ADDITIONAL BLUETTI MODELS
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'battery', 'portable', NULL, v.cap, 'watt_hours', true, 10, true, false, v.msrp, v.features, v.specs::jsonb, 'https://www.bluettipower.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('AC240',    'AC240',           'AC',  3072, 2499, ARRAY['3072Wh capacity','3600W output','Compact stackable design','LFP battery','Fast charging'], '{"watt_hours": 3072, "watts_output": 3600, "watts_surge": 7200, "battery_type": "LiFePO4", "cycles": 3500, "solar_input_watts": 2400, "weight_lbs": 78}'),
  ('AC2P',     'AC2P',            'AC',  2150, 1599, ARRAY['2150Wh capacity','2400W output','LFP battery','11 outputs','Home UPS'], '{"watt_hours": 2150, "watts_output": 2400, "watts_surge": 3600, "battery_type": "LiFePO4", "cycles": 3500, "solar_input_watts": 1200, "weight_lbs": 60}'),
  ('AC50S',    'AC50S',           'AC',   500, 399,  ARRAY['500Wh capacity','700W output','LFP battery','Compact camping size','USB-C PD'], '{"watt_hours": 500, "watts_output": 700, "watts_surge": 1000, "battery_type": "LiFePO4", "cycles": 3000, "solar_input_watts": 200, "weight_lbs": 14}'),
  ('B300',     'B300 Expansion',  'B',   3072, 2199, ARRAY['3.07kWh expansion battery','Works with AC300/AC500','LFP battery','Hot-swappable'], '{"watt_hours": 3072, "watts_output": 0, "watts_surge": 0, "battery_type": "LiFePO4", "cycles": 3500, "solar_input_watts": 200, "weight_lbs": 74}')
) AS v(model_number, model_name, series, cap, msrp, features, specs)
WHERE m.slug = 'bluetti' AND c.slug = 'power-station';


-- ============================================================================
-- ADDITIONAL ECOFLOW MODELS
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'battery', 'portable', NULL, v.cap, 'watt_hours', true, 10, true, false, v.msrp, v.features, v.specs::jsonb, 'https://www.ecoflow.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DELTA 3',         'DELTA 3',              'DELTA',  1024, 899,  ARRAY['1kWh capacity','X-Boost 1800W','GaN technology','Ultra-fast 56-min charge','LFP battery'], '{"watt_hours": 1024, "watts_output": 1600, "watts_surge": 3200, "battery_type": "LiFePO4", "cycles": 4000, "solar_input_watts": 500, "weight_lbs": 23}'),
  ('RIVER 3 Max',     'RIVER 3 Max',          'RIVER',   858, 799,  ARRAY['858Wh capacity','X-Boost 1200W','Fast recharge 40 min','LFP battery','App control'], '{"watt_hours": 858, "watts_output": 600, "watts_surge": 1200, "battery_type": "LiFePO4", "cycles": 4000, "solar_input_watts": 300, "weight_lbs": 19}'),
  ('RIVER 2',         'RIVER 2',              'RIVER',   256, 199,  ARRAY['256Wh ultra-compact','300W output','X-Stream fast charge','LFP battery','5-year warranty'], '{"watt_hours": 256, "watts_output": 300, "watts_surge": 600, "battery_type": "LiFePO4", "cycles": 3000, "solar_input_watts": 110, "weight_lbs": 8}'),
  ('DELTA Pro EB',    'DELTA Pro Extra Battery','DELTA', 3600, 1799, ARRAY['3.6kWh expansion battery','Works with DELTA Pro','LFP battery','Hot-swappable','Daisy chain'], '{"watt_hours": 3600, "watts_output": 0, "watts_surge": 0, "battery_type": "LiFePO4", "cycles": 3500, "solar_input_watts": 0, "weight_lbs": 84}'),
  ('DELTA Max Extra', 'DELTA Max Extra Battery','DELTA', 2016, 1199, ARRAY['2kWh expansion battery','Works with DELTA Max','Plug-and-play expansion'], '{"watt_hours": 2016, "watts_output": 0, "watts_surge": 0, "battery_type": "Li-ion NMC", "cycles": 800, "solar_input_watts": 0, "weight_lbs": 46}')
) AS v(model_number, model_name, series, cap, msrp, features, specs)
WHERE m.slug = 'ecoflow' AND c.slug = 'power-station';


-- ============================================================================
-- ADDITIONAL JACKERY MODELS
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'battery', 'portable', NULL, v.cap, 'watt_hours', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, 'https://www.jackery.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('Explorer 240 v2',   'Explorer 240 v2',     'Explorer',  256, 10, false, 199,  ARRAY['256Wh capacity','300W output','LFP battery','Compact 9 lbs','USB-C PD 100W'], '{"watt_hours": 256, "watts_output": 300, "watts_surge": 600, "battery_type": "LiFePO4", "cycles": 3000, "solar_input_watts": 65, "weight_lbs": 9}'),
  ('Explorer 3000 Plus','Explorer 3000 Plus',  'Explorer', 3000, 10, true,  2899, ARRAY['3000Wh expandable to 24kWh','3000W output','LFP battery','ChargeShield 2.0','App control'], '{"watt_hours": 3000, "watts_output": 3000, "watts_surge": 6000, "battery_type": "LiFePO4", "cycles": 4000, "solar_input_watts": 1400, "weight_lbs": 69}'),
  ('Explorer 700 Plus', 'Explorer 700 Plus',   'Explorer',  688, 10, true,  599,  ARRAY['688Wh capacity','1000W output','LFP battery','Fast wall charge 2h','ChargeShield'], '{"watt_hours": 688, "watts_output": 1000, "watts_surge": 2000, "battery_type": "LiFePO4", "cycles": 4000, "solar_input_watts": 200, "weight_lbs": 22}'),
  ('Explorer 3024',     'Explorer 3024 Home',  'Explorer', 3024, 10, true,  3999, ARRAY['3024Wh home backup','3000W output','LFP battery','Home panel integration','240V split-phase'], '{"watt_hours": 3024, "watts_output": 3000, "watts_surge": 6000, "battery_type": "LiFePO4", "cycles": 4000, "solar_input_watts": 2000, "weight_lbs": 72}')
) AS v(model_number, model_name, series, cap, lifespan, wifi, msrp, features, specs)
WHERE m.slug = 'jackery' AND c.slug = 'power-station';


-- ============================================================================
-- ADDITIONAL GOAL ZERO MODELS
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'battery', 'portable', NULL, v.cap, 'watt_hours', true, 10, true, false, v.msrp, v.features, v.specs::jsonb, 'https://www.goalzero.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('Yeti 150 PPS',   'Yeti 150 PPS',           'Yeti',      150, 199,  ARRAY['150Wh ultra-portable','120W output','USB-C PD 60W','Compact for EDC','TSA-friendly'], '{"watt_hours": 150, "watts_output": 120, "watts_surge": 240, "battery_type": "Li-ion NMC", "cycles": 500, "solar_input_watts": 50, "weight_lbs": 4}'),
  ('Yeti PRO 2000',  'Yeti PRO 2000',          'Yeti PRO',  2050, 2999, ARRAY['2050Wh LFP battery','2000W output','Tank Pro expansion to 8kWh','App control','Home integration'], '{"watt_hours": 2050, "watts_output": 2000, "watts_surge": 4000, "battery_type": "LiFePO4", "cycles": 3000, "solar_input_watts": 600, "weight_lbs": 55}'),
  ('Yeti 700',       'Yeti 700',                'Yeti',      677, 799,  ARRAY['677Wh capacity','600W output','MPPT controller','Compact mid-size','App control'], '{"watt_hours": 677, "watts_output": 600, "watts_surge": 1200, "battery_type": "Li-ion NMC", "cycles": 500, "solar_input_watts": 200, "weight_lbs": 18}')
) AS v(model_number, model_name, series, cap, msrp, features, specs)
WHERE m.slug = 'goal-zero' AND c.slug = 'power-station';


-- ============================================================================
-- ADDITIONAL ANKER SOLIX MODELS
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'battery', 'portable', NULL, v.cap, 'watt_hours', true, 10, true, false, v.msrp, v.features, v.specs::jsonb, 'https://www.anker.com/solix'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('F1200C',    'SOLIX C1000',              'SOLIX',   1056, 899,  ARRAY['1056Wh capacity','1800W SurgePad output','LFP battery','58-min HyperFlash','RV ready'], '{"watt_hours": 1056, "watts_output": 1200, "watts_surge": 1800, "battery_type": "LiFePO4", "cycles": 3000, "solar_input_watts": 600, "weight_lbs": 29}'),
  ('C200 DC',   'SOLIX C200 DC',            'SOLIX',    192, 149,  ARRAY['192Wh ultra-compact','140W output','USB-C 100W PD','Under 5 lbs','Pocket-size power'], '{"watt_hours": 192, "watts_output": 140, "watts_surge": 280, "battery_type": "LiFePO4", "cycles": 3000, "solar_input_watts": 100, "weight_lbs": 5}'),
  ('F2300',     'SOLIX F2300',              'SOLIX',   2304, 1799, ARRAY['2304Wh capacity','2300W output','LFP battery','GaNPrime','Fast charging','App control'], '{"watt_hours": 2304, "watts_output": 2300, "watts_surge": 4600, "battery_type": "LiFePO4", "cycles": 3000, "solar_input_watts": 1000, "weight_lbs": 55}')
) AS v(model_number, model_name, series, cap, msrp, features, specs)
WHERE m.slug = 'anker-solix' AND c.slug = 'power-station';


-- ============================================================================
-- ADDITIONAL KOHLER MODELS
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, NULL, v.fuel, 'standby', NULL, v.cap, 'watts', true, v.lifespan, true, false, v.msrp, v.features, v.specs::jsonb, 'https://www.kohlerpower.com/home-generators'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('14RCAL-QS2', '14kW Standby QS2',  'generator-standby-gas', 'natural_gas', 14000, 25, 5299, ARRAY['QS2 quiet operation','200A transfer switch','OnCue Plus monitoring','Corrosion-proof enclosure'], '{"watts_starting": 14000, "transfer_switch": "200A", "fuel_type": "natural_gas", "exercise_schedule": true, "mobile_monitoring": true, "noise_dba": 63}'),
  ('20RCAL-QS2', '20kW Standby QS2',  'generator-standby-gas', 'natural_gas', 20000, 25, 6499, ARRAY['QS2 quiet operation','200A SE transfer switch','OnCue Plus','Sound-dampened enclosure'], '{"watts_starting": 20000, "transfer_switch": "200A SE", "fuel_type": "natural_gas", "exercise_schedule": true, "mobile_monitoring": true, "noise_dba": 62}'),
  ('30RCAL',     '30kW Standby',       'generator-standby-gas', 'natural_gas', 30000, 25, 10999, ARRAY['Large home backup','400A transfer switch','OnCue Plus','Heavy-duty enclosure'], '{"watts_starting": 30000, "transfer_switch": "400A", "fuel_type": "natural_gas", "exercise_schedule": true, "mobile_monitoring": true, "noise_dba": 64}'),
  ('50RCLB',     '50kW Diesel Standby','generator-standby-diesel','diesel',    50000, 30, 24999, ARRAY['Estate-size diesel backup','400A transfer switch','OnCue Plus','Diesel reliability'], '{"watts_starting": 50000, "transfer_switch": "400A", "fuel_type": "diesel", "exercise_schedule": true, "mobile_monitoring": true, "noise_dba": 62}')
) AS v(model_number, model_name, cat_slug, fuel, cap, lifespan, msrp, features, specs)
WHERE m.slug = 'kohler-generators' AND c.slug = v.cat_slug;


-- ============================================================================
-- ADDITIONAL CUMMINS MODELS
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, 'QuietConnect', v.fuel, 'standby', NULL, v.cap, 'watts', true, v.lifespan, true, false, v.msrp, v.features, v.specs::jsonb, 'https://www.cummins.com/home-generators'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('RS40',   '40kW QuietConnect',  'generator-standby-gas',    'natural_gas', 40000, 25, 14999, ARRAY['Large home backup','400A transfer switch','Cummins Connected monitoring','Premium enclosure','Quiet operation'], '{"watts_starting": 40000, "transfer_switch": "400A", "fuel_type": "natural_gas", "exercise_schedule": true, "mobile_monitoring": true, "noise_dba": 61}'),
  ('C20D6',  '20kW Diesel Standby','generator-standby-diesel', 'diesel',      20000, 30, 13999, ARRAY['Diesel standby','200A transfer switch','Cummins Connected','Long run time','Sound-attenuated'], '{"watts_starting": 20000, "transfer_switch": "200A", "fuel_type": "diesel", "exercise_schedule": true, "mobile_monitoring": true, "noise_dba": 63}'),
  ('C30D6',  '30kW Diesel Standby','generator-standby-diesel', 'diesel',      30000, 30, 17999, ARRAY['Diesel standby','400A transfer switch','Cummins Connected','Premium enclosure','Estate-size'], '{"watts_starting": 30000, "transfer_switch": "400A", "fuel_type": "diesel", "exercise_schedule": true, "mobile_monitoring": true, "noise_dba": 62}'),
  ('RS10',   '10kW QuietConnect',  'generator-standby-gas',    'natural_gas', 10000, 25, 3999,  ARRAY['Essential circuit backup','100A 16-circuit switch','Cummins Connected','Compact footprint'], '{"watts_starting": 10000, "transfer_switch": "100A 16-circuit", "fuel_type": "natural_gas", "exercise_schedule": true, "mobile_monitoring": true, "noise_dba": 67}')
) AS v(model_number, model_name, cat_slug, fuel, cap, lifespan, msrp, features, specs)
WHERE m.slug = 'cummins' AND c.slug = v.cat_slug;


-- ============================================================================
-- ADDITIONAL GENERAC STANDBY + PORTABLE
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, 'watts', true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, 'https://www.generac.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('7289',  '38kW Guardian',         'Guardian', 'generator-standby-gas', 'natural_gas', 'standby',  38000, 25, true, 13999, ARRAY['Large home backup','400A transfer switch','Quiet-Test mode','Wi-Fi enabled','True Power Technology'], '{"watts_starting": 38000, "transfer_switch": "400A", "fuel_type": "natural_gas", "exercise_schedule": true, "mobile_monitoring": true, "noise_dba": 64}'),
  ('7725',  '10000W XT8500EFI',      'XT',       'generator-portable',   'gas',         'portable', 8500,  12, false, 1799,  ARRAY['EFI engine','Electric start','CO-Sense shutoff','GFCI outlets','Hour meter'], '{"watts_starting": 10000, "runtime_hours_50pct": 10, "noise_dba": 73, "fuel_tank_gallons": 8, "outlets": "4x120V GFCI 1x120/240V 1x30A", "parallel_capable": false, "co_shutoff": true}'),
  ('7676',  '4500W GP3300i',         'GP',       'generator-inverter',   'gas',         'portable', 2600,  12, false, 749,   ARRAY['Compact inverter','Economy mode','TruePower Technology','Parallel capable'], '{"watts_starting": 3300, "runtime_hours_50pct": 10, "noise_dba": 59, "fuel_tank_gallons": 1.5, "outlets": "2x120V 1xUSB", "parallel_capable": true, "co_shutoff": false}')
) AS v(model_number, model_name, series, cat_slug, fuel, install, cap, lifespan, wifi, msrp, features, specs)
WHERE m.slug = 'generac' AND c.slug = v.cat_slug;


-- ============================================================================
-- FINAL TOTAL COUNTS
-- ============================================================================
-- Generac:     12 standby + 6 portable + 5 inverter + 4 power station = 27
-- Kohler:      11 standby + 1 diesel = 12
-- Cummins:      7 standby gas + 3 diesel = 10
-- Winco:        3 gas standby + 2 diesel = 5
-- Honda:       10 inverter + 5 portable = 15
-- Yamaha:       9 inverter + 3 portable = 12
-- Champion:     7 portable + 10 inverter + 3 standby = 20
-- Westinghouse: 9 portable + 8 inverter = 17
-- Briggs:       5 portable + 3 inverter + 5 standby = 13
-- DuroMax:      10 portable + 7 inverter = 17 (split across categories via cat_slug)
-- Firman:       7 portable + 5 inverter = 12
-- WEN:          6 portable + 7 inverter = 13 (split across categories via cat_slug)
-- EcoFlow:     17 power stations = 17
-- Jackery:     14 power stations = 14
-- Bluetti:     16 power stations = 16
-- Anker SOLIX: 12 power stations = 12
-- Goal Zero:   11 power stations = 11
-- EGO Power+:   4 power stations + 2 inverter = 6
-- ─────────────────────────────────
-- GRAND TOTAL: ~259 models
