SET ROLE postgres;
-- ============================================================================
-- Equipment Catalog: Well Water Systems & Water Treatment
-- Brands: Goulds, Franklin Electric, Grundfos, Sta-Rite, Wayne, Flotec,
--         Amtrol, Culligan, Kinetico, Fleck, SpringWell, Aquasana, Pelican, Viqua
-- Categories: well-pump, pressure-tank, water-treatment-softener,
--             water-treatment-whole-house, water-treatment-uv,
--             water-treatment-iron, water-treatment-ro
-- ============================================================================


-- ======================== GOULDS WELL PUMPS ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('5GS05',  '1/2 HP 4" Submersible Pump 5 GPM',  'GS', 'submersible', 5,  'gpm', 15, false, 650,  ARRAY['4-inch stainless steel','5 GPM','1/2 HP motor','Sand resistant'], '{"hp": 0.5, "gpm": 5, "voltage": 230, "depth_ft": 200, "wire": "2-wire", "material": "stainless"}', 'https://www.gouldswatertech.com'),
  ('7GS05',  '1/2 HP 4" Submersible Pump 7 GPM',  'GS', 'submersible', 7,  'gpm', 15, false, 725,  ARRAY['4-inch stainless steel','7 GPM','1/2 HP motor','Floating impellers'], '{"hp": 0.5, "gpm": 7, "voltage": 230, "depth_ft": 180, "wire": "2-wire", "material": "stainless"}', 'https://www.gouldswatertech.com'),
  ('10GS05', '1/2 HP 4" Submersible Pump 10 GPM', 'GS', 'submersible', 10, 'gpm', 15, false, 780,  ARRAY['4-inch stainless steel','10 GPM','1/2 HP motor','Noryl impellers'], '{"hp": 0.5, "gpm": 10, "voltage": 230, "depth_ft": 120, "wire": "2-wire", "material": "stainless"}', 'https://www.gouldswatertech.com'),
  ('10GS10', '1 HP 4" Submersible Pump 10 GPM',   'GS', 'submersible', 10, 'gpm', 15, false, 850,  ARRAY['4-inch stainless steel','10 GPM','1 HP motor','Sand resistant'], '{"hp": 1.0, "gpm": 10, "voltage": 230, "depth_ft": 300, "wire": "2-wire", "material": "stainless"}', 'https://www.gouldswatertech.com'),
  ('10GS15', '1.5 HP 4" Submersible Pump 10 GPM', 'GS', 'submersible', 10, 'gpm', 15, false, 975,  ARRAY['4-inch stainless steel','10 GPM','1.5 HP motor','Deep well capable'], '{"hp": 1.5, "gpm": 10, "voltage": 230, "depth_ft": 480, "wire": "2-wire", "material": "stainless"}', 'https://www.gouldswatertech.com'),
  ('10GS20', '2 HP 4" Submersible Pump 10 GPM',   'GS', 'submersible', 10, 'gpm', 15, false, 1150, ARRAY['4-inch stainless steel','10 GPM','2 HP motor','High head capability'], '{"hp": 2.0, "gpm": 10, "voltage": 230, "depth_ft": 640, "wire": "2-wire", "material": "stainless"}', 'https://www.gouldswatertech.com'),
  ('18GS10', '1 HP 4" Submersible Pump 18 GPM',   'GS', 'submersible', 18, 'gpm', 15, false, 1050, ARRAY['4-inch stainless steel','18 GPM','1 HP motor','High flow residential'], '{"hp": 1.0, "gpm": 18, "voltage": 230, "depth_ft": 180, "wire": "2-wire", "material": "stainless"}', 'https://www.gouldswatertech.com'),
  ('25GS10', '1 HP 4" Submersible Pump 25 GPM',   'GS', 'submersible', 25, 'gpm', 15, false, 1200, ARRAY['4-inch stainless steel','25 GPM','1 HP motor','Large home capacity'], '{"hp": 1.0, "gpm": 25, "voltage": 230, "depth_ft": 120, "wire": "2-wire", "material": "stainless"}', 'https://www.gouldswatertech.com'),
  ('J05',    '1/2 HP Shallow Well Jet Pump',       'J',  'inline',      12, 'gpm', 12, false, 420,  ARRAY['Cast iron body','Shallow well to 25 ft','Self-priming','Thermoplastic impeller'], '{"hp": 0.5, "gpm": 12, "voltage": 115, "max_suction_lift_ft": 25, "material": "cast_iron"}', 'https://www.gouldswatertech.com'),
  ('J10',    '1 HP Shallow Well Jet Pump',          'J',  'inline',      22, 'gpm', 12, false, 520,  ARRAY['Cast iron body','Shallow well to 25 ft','Self-priming','High flow'], '{"hp": 1.0, "gpm": 22, "voltage": 115, "max_suction_lift_ft": 25, "material": "cast_iron"}', 'https://www.gouldswatertech.com'),
  ('J05S',   '1/2 HP Convertible Jet Pump',         'J',  'inline',      8,  'gpm', 12, false, 475,  ARRAY['Cast iron body','Convertible shallow/deep well','Up to 90 ft depth'], '{"hp": 0.5, "gpm": 8, "voltage": 115, "max_depth_ft": 90, "material": "cast_iron"}', 'https://www.gouldswatertech.com'),
  ('J10S',   '1 HP Convertible Jet Pump',            'J',  'inline',      14, 'gpm', 12, false, 575,  ARRAY['Cast iron body','Convertible shallow/deep well','Up to 90 ft depth','High capacity'], '{"hp": 1.0, "gpm": 14, "voltage": 115, "max_depth_ft": 90, "material": "cast_iron"}', 'https://www.gouldswatertech.com')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'goulds' AND c.slug = 'well-pump';


-- ======================== FRANKLIN ELECTRIC WELL PUMPS ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('15FA05S4-PE', '1/2 HP 4" Submersible Pump',  'FPS',      'submersible', 15, 'gpm', 15, false, 680,  ARRAY['4-inch stainless','15 GPM','1/2 HP','Sand Fighter impellers'], '{"hp": 0.5, "gpm": 15, "voltage": 230, "depth_ft": 150, "wire": "2-wire", "material": "stainless"}', 'https://www.franklin-electric.com'),
  ('15FA10S4-PE', '1 HP 4" Submersible Pump',     'FPS',      'submersible', 15, 'gpm', 15, false, 820,  ARRAY['4-inch stainless','15 GPM','1 HP','Sand Fighter impellers'], '{"hp": 1.0, "gpm": 15, "voltage": 230, "depth_ft": 300, "wire": "2-wire", "material": "stainless"}', 'https://www.franklin-electric.com'),
  ('15FA15S4-PE', '1.5 HP 4" Submersible Pump',   'FPS',      'submersible', 15, 'gpm', 15, false, 960,  ARRAY['4-inch stainless','15 GPM','1.5 HP','Deep well rated'], '{"hp": 1.5, "gpm": 15, "voltage": 230, "depth_ft": 480, "wire": "2-wire", "material": "stainless"}', 'https://www.franklin-electric.com'),
  ('10FA10S4-PE', '1 HP 4" Submersible Pump 10 GPM', 'FPS',   'submersible', 10, 'gpm', 15, false, 790,  ARRAY['4-inch stainless','10 GPM','1 HP','Residential standard'], '{"hp": 1.0, "gpm": 10, "voltage": 230, "depth_ft": 360, "wire": "2-wire", "material": "stainless"}', 'https://www.franklin-electric.com'),
  ('25FA10S4-PE', '1 HP 4" Submersible Pump 25 GPM', 'FPS',   'submersible', 25, 'gpm', 15, false, 1100, ARRAY['4-inch stainless','25 GPM','1 HP','High flow residential'], '{"hp": 1.0, "gpm": 25, "voltage": 230, "depth_ft": 140, "wire": "2-wire", "material": "stainless"}', 'https://www.franklin-electric.com'),
  ('25FA15S4-PE', '1.5 HP 4" Submersible Pump 25 GPM', 'FPS', 'submersible', 25, 'gpm', 15, false, 1280, ARRAY['4-inch stainless','25 GPM','1.5 HP','High capacity deep well'], '{"hp": 1.5, "gpm": 25, "voltage": 230, "depth_ft": 280, "wire": "2-wire", "material": "stainless"}', 'https://www.franklin-electric.com'),
  ('FPS-4400-10',  'SubDrive Connect 1 HP VFD',   'SubDrive', 'submersible', 15, 'gpm', 15, true,  1850, ARRAY['Variable frequency drive','Constant pressure','WiFi monitoring','Soft start'], '{"hp": 1.0, "gpm": 15, "voltage": 230, "vfd": true, "constant_pressure": true}', 'https://www.franklin-electric.com'),
  ('FPS-4400-15',  'SubDrive Connect 1.5 HP VFD', 'SubDrive', 'submersible', 20, 'gpm', 15, true,  2100, ARRAY['Variable frequency drive','Constant pressure','WiFi monitoring','Dry run protection'], '{"hp": 1.5, "gpm": 20, "voltage": 230, "vfd": true, "constant_pressure": true}', 'https://www.franklin-electric.com'),
  ('FPS-4400-20',  'SubDrive Connect 2 HP VFD',   'SubDrive', 'submersible', 25, 'gpm', 15, true,  2400, ARRAY['Variable frequency drive','Constant pressure','WiFi monitoring','Energy savings up to 30%'], '{"hp": 2.0, "gpm": 25, "voltage": 230, "vfd": true, "constant_pressure": true}', 'https://www.franklin-electric.com'),
  ('DERA-075',     '3/4 HP Convertible Jet Pump',  'DERA',    'inline',      14, 'gpm', 12, false, 450,  ARRAY['Cast iron','Convertible shallow/deep','Dual voltage','Thermoplastic impeller'], '{"hp": 0.75, "gpm": 14, "voltage": 115, "max_depth_ft": 70, "material": "cast_iron"}', 'https://www.franklin-electric.com'),
  ('DERA-100',     '1 HP Convertible Jet Pump',     'DERA',    'inline',      18, 'gpm', 12, false, 530,  ARRAY['Cast iron','Convertible shallow/deep','Dual voltage','High capacity'], '{"hp": 1.0, "gpm": 18, "voltage": 115, "max_depth_ft": 70, "material": "cast_iron"}', 'https://www.franklin-electric.com')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'franklin-electric' AND c.slug = 'well-pump';


-- ======================== GRUNDFOS WELL PUMPS ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('SQE 2-85',   '1/2 HP Constant Pressure Submersible',  'SQE', 'submersible', 8,  'gpm', 15, false, 1650, ARRAY['Constant pressure system','Variable speed','4-inch stainless','Built-in VFD'], '{"hp": 0.5, "gpm": 8, "voltage": 230, "depth_ft": 400, "wire": "3-wire", "vfd": true, "material": "stainless"}', 'https://www.grundfos.com/us'),
  ('SQE 3-65',   '3/4 HP Constant Pressure Submersible',  'SQE', 'submersible', 12, 'gpm', 15, false, 1800, ARRAY['Constant pressure system','Variable speed','4-inch stainless','Dry run protection'], '{"hp": 0.75, "gpm": 12, "voltage": 230, "depth_ft": 320, "wire": "3-wire", "vfd": true, "material": "stainless"}', 'https://www.grundfos.com/us'),
  ('SQE 5-150',  '1.5 HP Constant Pressure Submersible',  'SQE', 'submersible', 20, 'gpm', 15, false, 2200, ARRAY['Constant pressure system','Variable speed','4-inch stainless','High capacity'], '{"hp": 1.5, "gpm": 20, "voltage": 230, "depth_ft": 500, "wire": "3-wire", "vfd": true, "material": "stainless"}', 'https://www.grundfos.com/us'),
  ('SQE 5-70',   '1 HP Constant Pressure Submersible',    'SQE', 'submersible', 20, 'gpm', 15, false, 1950, ARRAY['Constant pressure system','Variable speed','4-inch stainless','Energy efficient'], '{"hp": 1.0, "gpm": 20, "voltage": 230, "depth_ft": 350, "wire": "3-wire", "vfd": true, "material": "stainless"}', 'https://www.grundfos.com/us'),
  ('SQ 2-85',    '1/2 HP Fixed Speed Submersible',         'SQ',  'submersible', 8,  'gpm', 15, false, 1100, ARRAY['Fixed speed','4-inch stainless','Floating impellers','Compact design'], '{"hp": 0.5, "gpm": 8, "voltage": 230, "depth_ft": 400, "wire": "3-wire", "material": "stainless"}', 'https://www.grundfos.com/us'),
  ('SQ 3-65',    '3/4 HP Fixed Speed Submersible',          'SQ',  'submersible', 12, 'gpm', 15, false, 1250, ARRAY['Fixed speed','4-inch stainless','Floating impellers','Dry run protection'], '{"hp": 0.75, "gpm": 12, "voltage": 230, "depth_ft": 320, "wire": "3-wire", "material": "stainless"}', 'https://www.grundfos.com/us'),
  ('SQ 5-70',    '1 HP Fixed Speed Submersible',            'SQ',  'submersible', 20, 'gpm', 15, false, 1350, ARRAY['Fixed speed','4-inch stainless','Floating impellers','High flow'], '{"hp": 1.0, "gpm": 20, "voltage": 230, "depth_ft": 350, "wire": "3-wire", "material": "stainless"}', 'https://www.grundfos.com/us'),
  ('SQ 7-30',    '3/4 HP Fixed Speed Submersible 7 GPM',    'SQ',  'submersible', 30, 'gpm', 15, false, 1450, ARRAY['Fixed speed','4-inch stainless','High flow capacity','Residential large'], '{"hp": 0.75, "gpm": 30, "voltage": 230, "depth_ft": 150, "wire": "3-wire", "material": "stainless"}', 'https://www.grundfos.com/us'),
  ('MQ3-35',     '1 HP Pressure Booster Pump',              'MQ',  'inline',      8,  'gpm', 12, false, 850,  ARRAY['Self-priming','Integrated controller','Dry run protection','Compact all-in-one'], '{"hp": 1.0, "gpm": 8, "voltage": 115, "max_pressure_psi": 72, "material": "stainless"}', 'https://www.grundfos.com/us'),
  ('MQ3-45',     '1 HP Pressure Booster Pump High Flow',     'MQ',  'inline',      12, 'gpm', 12, false, 950,  ARRAY['Self-priming','Integrated controller','Dry run protection','Higher flow rate'], '{"hp": 1.0, "gpm": 12, "voltage": 115, "max_pressure_psi": 65, "material": "stainless"}', 'https://www.grundfos.com/us')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'grundfos' AND c.slug = 'well-pump';


-- ======================== STA-RITE WELL PUMPS ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('HP05S05-04',  '1/2 HP 4" Submersible 5 GPM',       'Dominator', 'submersible', 5,  'gpm', 15, false, 500,  ARRAY['4-inch stainless','5 GPM','1/2 HP','Pentair brand'], '{"hp": 0.5, "gpm": 5, "voltage": 230, "depth_ft": 250, "wire": "2-wire", "material": "stainless"}', 'https://www.pentair.com/en-us/brands/sta-rite.html'),
  ('HP07S07-04',  '3/4 HP 4" Submersible 7 GPM',       'Dominator', 'submersible', 7,  'gpm', 15, false, 580,  ARRAY['4-inch stainless','7 GPM','3/4 HP','Thermoplastic impellers'], '{"hp": 0.75, "gpm": 7, "voltage": 230, "depth_ft": 280, "wire": "2-wire", "material": "stainless"}', 'https://www.pentair.com/en-us/brands/sta-rite.html'),
  ('HP10S10-04',  '1 HP 4" Submersible 10 GPM',        'Dominator', 'submersible', 10, 'gpm', 15, false, 680,  ARRAY['4-inch stainless','10 GPM','1 HP','Sand resistant'], '{"hp": 1.0, "gpm": 10, "voltage": 230, "depth_ft": 360, "wire": "2-wire", "material": "stainless"}', 'https://www.pentair.com/en-us/brands/sta-rite.html'),
  ('HP15S15-04',  '1.5 HP 4" Submersible 15 GPM',      'Dominator', 'submersible', 15, 'gpm', 15, false, 850,  ARRAY['4-inch stainless','15 GPM','1.5 HP','Deep well'], '{"hp": 1.5, "gpm": 15, "voltage": 230, "depth_ft": 480, "wire": "2-wire", "material": "stainless"}', 'https://www.pentair.com/en-us/brands/sta-rite.html'),
  ('HP20S20-04',  '2 HP 4" Submersible 20 GPM',        'Dominator', 'submersible', 20, 'gpm', 15, false, 1050, ARRAY['4-inch stainless','20 GPM','2 HP','High capacity'], '{"hp": 2.0, "gpm": 20, "voltage": 230, "depth_ft": 600, "wire": "2-wire", "material": "stainless"}', 'https://www.pentair.com/en-us/brands/sta-rite.html'),
  ('HNE-L',       '1/2 HP Shallow Well Jet Pump',       'HNE',       'inline',      12, 'gpm', 12, false, 380,  ARRAY['Cast iron body','Self-priming','Shallow well to 25 ft','Dual voltage'], '{"hp": 0.5, "gpm": 12, "voltage": 115, "max_suction_lift_ft": 25, "material": "cast_iron"}', 'https://www.pentair.com/en-us/brands/sta-rite.html'),
  ('HNE-1L',      '1 HP Shallow Well Jet Pump',          'HNE',       'inline',      22, 'gpm', 12, false, 480,  ARRAY['Cast iron body','Self-priming','Shallow well to 25 ft','High flow'], '{"hp": 1.0, "gpm": 22, "voltage": 115, "max_suction_lift_ft": 25, "material": "cast_iron"}', 'https://www.pentair.com/en-us/brands/sta-rite.html'),
  ('HSND-L',      '3/4 HP Deep Well Jet Pump',           'HSN',       'inline',      8,  'gpm', 12, false, 520,  ARRAY['Cast iron body','Deep well to 90 ft','Injector included','Noryl impeller'], '{"hp": 0.75, "gpm": 8, "voltage": 115, "max_depth_ft": 90, "material": "cast_iron"}', 'https://www.pentair.com/en-us/brands/sta-rite.html')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'sta-rite' AND c.slug = 'well-pump';


-- ======================== WAYNE WELL PUMPS ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('T50S10-4',  '1 HP 4" Submersible 10 GPM',        'T-Series', 'submersible', 10, 'gpm', 12, false, 520,  ARRAY['4-inch stainless','10 GPM','1 HP','2-wire installation'], '{"hp": 1.0, "gpm": 10, "voltage": 230, "depth_ft": 300, "wire": "2-wire", "material": "stainless"}', 'https://www.waynepumps.com'),
  ('T50S10-22', '1 HP 4" Submersible 10 GPM 3-Wire',  'T-Series', 'submersible', 10, 'gpm', 12, false, 540,  ARRAY['4-inch stainless','10 GPM','1 HP','3-wire with control box'], '{"hp": 1.0, "gpm": 10, "voltage": 230, "depth_ft": 300, "wire": "3-wire", "material": "stainless"}', 'https://www.waynepumps.com'),
  ('T75S10-4',  '3/4 HP 4" Submersible 10 GPM',       'T-Series', 'submersible', 10, 'gpm', 12, false, 475,  ARRAY['4-inch stainless','10 GPM','3/4 HP','Residential standard'], '{"hp": 0.75, "gpm": 10, "voltage": 230, "depth_ft": 240, "wire": "2-wire", "material": "stainless"}', 'https://www.waynepumps.com'),
  ('T50S05-4',  '1/2 HP 4" Submersible 10 GPM',       'T-Series', 'submersible', 10, 'gpm', 12, false, 420,  ARRAY['4-inch stainless','10 GPM','1/2 HP','Value residential'], '{"hp": 0.5, "gpm": 10, "voltage": 230, "depth_ft": 180, "wire": "2-wire", "material": "stainless"}', 'https://www.waynepumps.com'),
  ('SWS50',     '1/2 HP Shallow Well Jet Pump',        'SWS',      'inline',      12, 'gpm', 10, false, 300,  ARRAY['Cast iron body','Self-priming','Shallow well to 25 ft','Budget friendly'], '{"hp": 0.5, "gpm": 12, "voltage": 115, "max_suction_lift_ft": 25, "material": "cast_iron"}', 'https://www.waynepumps.com'),
  ('SWS75',     '3/4 HP Shallow Well Jet Pump',        'SWS',      'inline',      16, 'gpm', 10, false, 360,  ARRAY['Cast iron body','Self-priming','Shallow well to 25 ft','Mid-range'], '{"hp": 0.75, "gpm": 16, "voltage": 115, "max_suction_lift_ft": 25, "material": "cast_iron"}', 'https://www.waynepumps.com'),
  ('SWS100',    '1 HP Shallow Well Jet Pump',           'SWS',      'inline',      25, 'gpm', 10, false, 420,  ARRAY['Cast iron body','Self-priming','Shallow well to 25 ft','High flow'], '{"hp": 1.0, "gpm": 25, "voltage": 115, "max_suction_lift_ft": 25, "material": "cast_iron"}', 'https://www.waynepumps.com'),
  ('CWS50',     '1/2 HP Convertible Well Jet Pump',    'CWS',      'inline',      8,  'gpm', 10, false, 320,  ARRAY['Cast iron body','Convertible shallow/deep','Up to 90 ft'], '{"hp": 0.5, "gpm": 8, "voltage": 115, "max_depth_ft": 90, "material": "cast_iron"}', 'https://www.waynepumps.com'),
  ('CWS75',     '3/4 HP Convertible Well Jet Pump',    'CWS',      'inline',      12, 'gpm', 10, false, 380,  ARRAY['Cast iron body','Convertible shallow/deep','Up to 90 ft','Higher flow'], '{"hp": 0.75, "gpm": 12, "voltage": 115, "max_depth_ft": 90, "material": "cast_iron"}', 'https://www.waynepumps.com'),
  ('CWS100',    '1 HP Convertible Well Jet Pump',      'CWS',      'inline',      16, 'gpm', 10, false, 450,  ARRAY['Cast iron body','Convertible shallow/deep','Up to 90 ft','High capacity'], '{"hp": 1.0, "gpm": 16, "voltage": 115, "max_depth_ft": 90, "material": "cast_iron"}', 'https://www.waynepumps.com')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'wayne' AND c.slug = 'well-pump';


-- ======================== FLOTEC WELL PUMPS ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('FP2212-08', '1/2 HP 4" Submersible 10 GPM',      'FP', 'submersible', 10, 'gpm', 10, false, 350,  ARRAY['4-inch stainless','10 GPM','1/2 HP','Budget submersible'], '{"hp": 0.5, "gpm": 10, "voltage": 230, "depth_ft": 150, "wire": "2-wire", "material": "stainless"}', 'https://www.flotecwater.com'),
  ('FP2222-08', '3/4 HP 4" Submersible 10 GPM',      'FP', 'submersible', 10, 'gpm', 10, false, 400,  ARRAY['4-inch stainless','10 GPM','3/4 HP','Mid-range submersible'], '{"hp": 0.75, "gpm": 10, "voltage": 230, "depth_ft": 220, "wire": "2-wire", "material": "stainless"}', 'https://www.flotecwater.com'),
  ('FP2232-08', '1 HP 4" Submersible 10 GPM',         'FP', 'submersible', 10, 'gpm', 10, false, 475,  ARRAY['4-inch stainless','10 GPM','1 HP','Value deep well pump'], '{"hp": 1.0, "gpm": 10, "voltage": 230, "depth_ft": 300, "wire": "2-wire", "material": "stainless"}', 'https://www.flotecwater.com'),
  ('FP4012-10', '1/2 HP Shallow Well Jet Pump',        'FP', 'inline',      12, 'gpm', 10, false, 250,  ARRAY['Thermoplastic body','Self-priming','Shallow well to 25 ft','Corrosion proof'], '{"hp": 0.5, "gpm": 12, "voltage": 115, "max_suction_lift_ft": 25, "material": "thermoplastic"}', 'https://www.flotecwater.com'),
  ('FP4022-08', '3/4 HP Shallow Well Jet Pump',        'FP', 'inline',      16, 'gpm', 10, false, 290,  ARRAY['Cast iron body','Self-priming','Shallow well to 25 ft'], '{"hp": 0.75, "gpm": 16, "voltage": 115, "max_suction_lift_ft": 25, "material": "cast_iron"}', 'https://www.flotecwater.com'),
  ('FP4032-08', '1 HP Shallow Well Jet Pump',           'FP', 'inline',      22, 'gpm', 10, false, 340,  ARRAY['Cast iron body','Self-priming','Shallow well to 25 ft','High flow'], '{"hp": 1.0, "gpm": 22, "voltage": 115, "max_suction_lift_ft": 25, "material": "cast_iron"}', 'https://www.flotecwater.com'),
  ('FP4112-08', '1/2 HP Convertible Jet Pump',          'FP', 'inline',      8,  'gpm', 10, false, 275,  ARRAY['Cast iron body','Convertible shallow/deep','Up to 70 ft'], '{"hp": 0.5, "gpm": 8, "voltage": 115, "max_depth_ft": 70, "material": "cast_iron"}', 'https://www.flotecwater.com'),
  ('FP4122-08', '3/4 HP Convertible Jet Pump',          'FP', 'inline',      12, 'gpm', 10, false, 320,  ARRAY['Cast iron body','Convertible shallow/deep','Up to 70 ft'], '{"hp": 0.75, "gpm": 12, "voltage": 115, "max_depth_ft": 70, "material": "cast_iron"}', 'https://www.flotecwater.com')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'flotec' AND c.slug = 'well-pump';


-- ======================== AMTROL PRESSURE TANKS ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'floor', NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WX-101',  'Well-X-Trol 2 Gallon',   'Well-X-Trol', 2,   'gal', 15, 85,   ARRAY['2 gallon capacity','In-line mounting','0.6 gal drawdown','Butyl diaphragm'], '{"gallons": 2, "drawdown_gallons": 0.6, "max_psi": 125, "pre_charge_psi": 38, "connection": "0.75_inch"}', 'https://www.amtrol.com'),
  ('WX-103',  'Well-X-Trol 7.6 Gallon',  'Well-X-Trol', 8,   'gal', 15, 120,  ARRAY['7.6 gallon capacity','Compact floor mount','2.2 gal drawdown','Steel shell'], '{"gallons": 7.6, "drawdown_gallons": 2.2, "max_psi": 125, "pre_charge_psi": 38, "connection": "0.75_inch"}', 'https://www.amtrol.com'),
  ('WX-200',  'Well-X-Trol 14 Gallon',   'Well-X-Trol', 14,  'gal', 15, 165,  ARRAY['14 gallon capacity','Floor mount','4.4 gal drawdown','Residential standard'], '{"gallons": 14, "drawdown_gallons": 4.4, "max_psi": 125, "pre_charge_psi": 38, "connection": "0.75_inch"}', 'https://www.amtrol.com'),
  ('WX-201',  'Well-X-Trol 14 Gallon Inline', 'Well-X-Trol', 14, 'gal', 15, 175, ARRAY['14 gallon capacity','Inline mounting','4.4 gal drawdown','Space saving'], '{"gallons": 14, "drawdown_gallons": 4.4, "max_psi": 125, "pre_charge_psi": 38, "connection": "0.75_inch", "orientation": "inline"}', 'https://www.amtrol.com'),
  ('WX-202',  'Well-X-Trol 20 Gallon',   'Well-X-Trol', 20,  'gal', 15, 210,  ARRAY['20 gallon capacity','Floor mount','5.9 gal drawdown','Most popular size'], '{"gallons": 20, "drawdown_gallons": 5.9, "max_psi": 125, "pre_charge_psi": 38, "connection": "1_inch"}', 'https://www.amtrol.com'),
  ('WX-203',  'Well-X-Trol 32 Gallon',   'Well-X-Trol', 32,  'gal', 15, 280,  ARRAY['32 gallon capacity','Floor mount','9.3 gal drawdown','Reduced pump cycling'], '{"gallons": 32, "drawdown_gallons": 9.3, "max_psi": 125, "pre_charge_psi": 38, "connection": "1_inch"}', 'https://www.amtrol.com'),
  ('WX-250',  'Well-X-Trol 44 Gallon',   'Well-X-Trol', 44,  'gal', 15, 380,  ARRAY['44 gallon capacity','Floor mount','13.2 gal drawdown','Extended pump life'], '{"gallons": 44, "drawdown_gallons": 13.2, "max_psi": 125, "pre_charge_psi": 38, "connection": "1.25_inch"}', 'https://www.amtrol.com'),
  ('WX-251',  'Well-X-Trol 62 Gallon',   'Well-X-Trol', 62,  'gal', 15, 490,  ARRAY['62 gallon capacity','Floor mount','18.4 gal drawdown','Large home use'], '{"gallons": 62, "drawdown_gallons": 18.4, "max_psi": 125, "pre_charge_psi": 38, "connection": "1.25_inch"}', 'https://www.amtrol.com'),
  ('WX-302',  'Well-X-Trol 86 Gallon',   'Well-X-Trol', 86,  'gal', 15, 650,  ARRAY['86 gallon capacity','Floor mount','26.4 gal drawdown','Commercial grade'], '{"gallons": 86, "drawdown_gallons": 26.4, "max_psi": 125, "pre_charge_psi": 38, "connection": "1.25_inch"}', 'https://www.amtrol.com'),
  ('WX-350',  'Well-X-Trol 119 Gallon',  'Well-X-Trol', 119, 'gal', 15, 850,  ARRAY['119 gallon capacity','Floor mount','35.8 gal drawdown','Estate/multi-home'], '{"gallons": 119, "drawdown_gallons": 35.8, "max_psi": 125, "pre_charge_psi": 38, "connection": "1.25_inch"}', 'https://www.amtrol.com'),
  ('WX-251D', 'Well-X-Trol 62 Gallon CAD', 'Well-X-Trol', 62, 'gal', 15, 550, ARRAY['62 gallon capacity','Controlled air diaphragm','18.4 gal drawdown','Premium design'], '{"gallons": 62, "drawdown_gallons": 18.4, "max_psi": 150, "pre_charge_psi": 40, "connection": "1.25_inch", "type": "CAD"}', 'https://www.amtrol.com')
) AS v(model_number, model_name, series, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'amtrol' AND c.slug = 'pressure-tank';


-- ======================== CULLIGAN WATER SOFTENERS ========================

-- Softeners
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'floor', NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('HE',          'Culligan High Efficiency 1.0',          'HE',          24000, 'grain', 15, false, 1500, ARRAY['24,000 grain capacity','Metered regeneration','Aqua-Sensor technology','Salt-saving'], '{"grain_capacity": 24000, "salt_efficiency": true, "regeneration": "metered", "flow_rate_gpm": 7, "bypass_valve": true}', 'https://www.culligan.com'),
  ('HE-1.25',     'Culligan High Efficiency 1.25',         'HE',          32000, 'grain', 15, false, 1800, ARRAY['32,000 grain capacity','Metered regeneration','Aqua-Sensor technology','Family size'], '{"grain_capacity": 32000, "salt_efficiency": true, "regeneration": "metered", "flow_rate_gpm": 9, "bypass_valve": true}', 'https://www.culligan.com'),
  ('HE-1.5',      'Culligan High Efficiency 1.5',          'HE',          40000, 'grain', 15, false, 2100, ARRAY['40,000 grain capacity','Metered regeneration','Aqua-Sensor','Large home'], '{"grain_capacity": 40000, "salt_efficiency": true, "regeneration": "metered", "flow_rate_gpm": 11, "bypass_valve": true}', 'https://www.culligan.com'),
  ('HE-2.0',      'Culligan High Efficiency 2.0',          'HE',          48000, 'grain', 15, false, 2500, ARRAY['48,000 grain capacity','Metered regeneration','Aqua-Sensor','Extra-large home'], '{"grain_capacity": 48000, "salt_efficiency": true, "regeneration": "metered", "flow_rate_gpm": 13, "bypass_valve": true}', 'https://www.culligan.com'),
  ('Smart HE',    'Culligan Smart HE WiFi Softener',       'Smart HE',    48000, 'grain', 15, true,  3200, ARRAY['48,000 grain capacity','WiFi connected','App monitoring','Salt level alerts','Usage tracking'], '{"grain_capacity": 48000, "salt_efficiency": true, "regeneration": "metered", "flow_rate_gpm": 13, "wifi": true, "app_control": true}', 'https://www.culligan.com'),
  ('CullarSoft',  'Culligan CullarSoft Softener',          'CullarSoft',  30000, 'grain', 12, false, 1200, ARRAY['30,000 grain capacity','Timer regeneration','Budget friendly','Compact design'], '{"grain_capacity": 30000, "salt_efficiency": false, "regeneration": "timer", "flow_rate_gpm": 8, "bypass_valve": true}', 'https://www.culligan.com')
) AS v(model_number, model_name, series, cap, cap_unit, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'culligan' AND c.slug = 'water-treatment-softener';

-- Culligan RO
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'under-sink', NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('AC-30',       'Culligan Aqua-Cleer 30 RO System',      'Aqua-Cleer',  30,    'gpd',  10, 600,  ARRAY['3-stage reverse osmosis','Under-sink installation','30 GPD','Dedicated faucet'], '{"stages": 3, "gpd": 30, "rejection_rate": 0.95, "tank_gallons": 2.5}', 'https://www.culligan.com'),
  ('AC-50',       'Culligan Aqua-Cleer 50 RO System',      'Aqua-Cleer',  50,    'gpd',  10, 850,  ARRAY['5-stage reverse osmosis','Under-sink installation','50 GPD','Premium filtration'], '{"stages": 5, "gpd": 50, "rejection_rate": 0.97, "tank_gallons": 3.0}', 'https://www.culligan.com')
) AS v(model_number, model_name, series, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'culligan' AND c.slug = 'water-treatment-ro';

-- Culligan Iron Filter
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'floor', NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('TotalDefense', 'Culligan Total Defense Iron Filter',    'Total Defense', 10,  'gpm',  12, 2200, ARRAY['Iron and manganese removal','Air injection','Chemical-free','Automatic backwash'], '{"iron_removal_ppm": 10, "manganese_removal_ppm": 2, "flow_rate_gpm": 10, "backwash": "automatic", "chemical_free": true}', 'https://www.culligan.com')
) AS v(model_number, model_name, series, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'culligan' AND c.slug = 'water-treatment-iron';


-- ======================== KINETICO WATER SOFTENERS ========================

-- Kinetico Softeners
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'floor', NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('2020c',        'Kinetico 2020c Compact Softener',     'Essential', 15000, 'grain', 20, false, 1200, ARRAY['Non-electric kinetic operation','Twin-tank continuous soft water','Compact design','Metered regeneration'], '{"grain_capacity": 15000, "salt_efficiency": true, "regeneration": "metered", "flow_rate_gpm": 6, "twin_tank": true, "non_electric": true}', 'https://www.kinetico.com'),
  ('2060s',        'Kinetico 2060s Standard Softener',    'Essential', 24000, 'grain', 20, false, 1600, ARRAY['Non-electric kinetic operation','Twin-tank','Standard home capacity','Countercurrent regeneration'], '{"grain_capacity": 24000, "salt_efficiency": true, "regeneration": "metered", "flow_rate_gpm": 8, "twin_tank": true, "non_electric": true}', 'https://www.kinetico.com'),
  ('2100s',        'Kinetico 2100s Softener',             'Essential', 32000, 'grain', 20, false, 2000, ARRAY['Non-electric kinetic operation','Twin-tank','Large home capacity','10-year warranty'], '{"grain_capacity": 32000, "salt_efficiency": true, "regeneration": "metered", "flow_rate_gpm": 10, "twin_tank": true, "non_electric": true}', 'https://www.kinetico.com'),
  ('Premier s250', 'Kinetico Premier s250 Softener',      'Premier',   25000, 'grain', 20, false, 2400, ARRAY['Non-electric','Twin-tank','Soft water on demand','Premium resin'], '{"grain_capacity": 25000, "salt_efficiency": true, "regeneration": "metered", "flow_rate_gpm": 9, "twin_tank": true, "non_electric": true}', 'https://www.kinetico.com'),
  ('Premier s650', 'Kinetico Premier s650 Softener',      'Premier',   40000, 'grain', 20, false, 3200, ARRAY['Non-electric','Twin-tank','Large capacity','Premium resin','High flow'], '{"grain_capacity": 40000, "salt_efficiency": true, "regeneration": "metered", "flow_rate_gpm": 12, "twin_tank": true, "non_electric": true}', 'https://www.kinetico.com'),
  ('Q850',         'Kinetico Q850 Signature Softener',    'Signature', 50000, 'grain', 20, true,  4500, ARRAY['Non-electric','Twin-tank','WiFi monitoring','Smart diagnostics','Top-tier residential'], '{"grain_capacity": 50000, "salt_efficiency": true, "regeneration": "metered", "flow_rate_gpm": 15, "twin_tank": true, "non_electric": true, "wifi": true}', 'https://www.kinetico.com')
) AS v(model_number, model_name, series, cap, cap_unit, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'kinetico' AND c.slug = 'water-treatment-softener';

-- Kinetico RO
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'under-sink', NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('K5',   'Kinetico K5 Drinking Water Station',   'K5',   50, 'gpd', 10, 2200, ARRAY['Reverse osmosis','Modular design','Quick-change filters','VOC removal cartridge'], '{"stages": 5, "gpd": 50, "rejection_rate": 0.98, "tank_gallons": 3.0, "modular": true}', 'https://www.kinetico.com'),
  ('A200', 'Kinetico A200 Drinking Water System',  'A200', 50, 'gpd', 10, 1200, ARRAY['Reverse osmosis','3-stage','Compact under-sink','Easy filter change'], '{"stages": 3, "gpd": 50, "rejection_rate": 0.95, "tank_gallons": 2.5}', 'https://www.kinetico.com')
) AS v(model_number, model_name, series, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'kinetico' AND c.slug = 'water-treatment-ro';

-- Kinetico Whole-House
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'floor', NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('Dechlorinator', 'Kinetico Dechlorinator',  'Dechlorinator', 10, 'gpm', 10, 1400, ARRAY['Whole-house chlorine removal','Non-electric backwash','Carbon media','No salt needed'], '{"media": "carbon", "flow_rate_gpm": 10, "non_electric": true, "chlorine_removal": true}', 'https://www.kinetico.com')
) AS v(model_number, model_name, series, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'kinetico' AND c.slug = 'water-treatment-whole-house';

-- Kinetico Iron/Sulfur
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'floor', NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('Sulfur Guard', 'Kinetico Sulfur Guard', 'Sulfur Guard', 8, 'gpm', 12, 1800, ARRAY['Hydrogen sulfide removal','Non-electric','Air injection oxidation','Chemical-free'], '{"h2s_removal_ppm": 8, "flow_rate_gpm": 8, "non_electric": true, "chemical_free": true}', 'https://www.kinetico.com')
) AS v(model_number, model_name, series, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'kinetico' AND c.slug = 'water-treatment-iron';


-- ======================== FLECK WATER SOFTENERS (VALVES/SYSTEMS) ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'floor', NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('5600SXT-24',    'Fleck 5600SXT 24K Grain Softener',    '5600SXT',   24000, 'grain', 15, false, 550,  ARRAY['Digital SXT metered valve','24,000 grain','10x44 tank','Fine mesh resin','DIY friendly'], '{"grain_capacity": 24000, "salt_efficiency": true, "regeneration": "metered", "flow_rate_gpm": 7, "valve_type": "digital_SXT", "tank_size": "10x44"}', 'https://www.pentair.com/en-us/brands/fleck.html'),
  ('5600SXT-32',    'Fleck 5600SXT 32K Grain Softener',    '5600SXT',   32000, 'grain', 15, false, 620,  ARRAY['Digital SXT metered valve','32,000 grain','10x54 tank','Standard residential'], '{"grain_capacity": 32000, "salt_efficiency": true, "regeneration": "metered", "flow_rate_gpm": 9, "valve_type": "digital_SXT", "tank_size": "10x54"}', 'https://www.pentair.com/en-us/brands/fleck.html'),
  ('5600SXT-48',    'Fleck 5600SXT 48K Grain Softener',    '5600SXT',   48000, 'grain', 15, false, 750,  ARRAY['Digital SXT metered valve','48,000 grain','12x52 tank','Large home','High flow'], '{"grain_capacity": 48000, "salt_efficiency": true, "regeneration": "metered", "flow_rate_gpm": 12, "valve_type": "digital_SXT", "tank_size": "12x52"}', 'https://www.pentair.com/en-us/brands/fleck.html'),
  ('5600SXT-64',    'Fleck 5600SXT 64K Grain Softener',    '5600SXT',   64000, 'grain', 15, false, 880,  ARRAY['Digital SXT metered valve','64,000 grain','13x54 tank','Extra large capacity'], '{"grain_capacity": 64000, "salt_efficiency": true, "regeneration": "metered", "flow_rate_gpm": 14, "valve_type": "digital_SXT", "tank_size": "13x54"}', 'https://www.pentair.com/en-us/brands/fleck.html'),
  ('5600SXT-80',    'Fleck 5600SXT 80K Grain Softener',    '5600SXT',   80000, 'grain', 15, false, 1050, ARRAY['Digital SXT metered valve','80,000 grain','14x65 tank','Estate/multi-bath'], '{"grain_capacity": 80000, "salt_efficiency": true, "regeneration": "metered", "flow_rate_gpm": 16, "valve_type": "digital_SXT", "tank_size": "14x65"}', 'https://www.pentair.com/en-us/brands/fleck.html'),
  ('2510SXT-48',    'Fleck 2510SXT 48K Grain Softener',    '2510SXT',   48000, 'grain', 15, false, 850,  ARRAY['Digital SXT metered valve','1-inch porting','48,000 grain','Higher flow rate'], '{"grain_capacity": 48000, "salt_efficiency": true, "regeneration": "metered", "flow_rate_gpm": 15, "valve_type": "digital_SXT", "port_size": "1_inch"}', 'https://www.pentair.com/en-us/brands/fleck.html'),
  ('2510SXT-64',    'Fleck 2510SXT 64K Grain Softener',    '2510SXT',   64000, 'grain', 15, false, 1000, ARRAY['Digital SXT metered valve','1-inch porting','64,000 grain','Commercial residential'], '{"grain_capacity": 64000, "salt_efficiency": true, "regeneration": "metered", "flow_rate_gpm": 17, "valve_type": "digital_SXT", "port_size": "1_inch"}', 'https://www.pentair.com/en-us/brands/fleck.html'),
  ('5600SXT-Iron1', 'Fleck 5600SXT Iron Pro 48K Combo',    '5600SXT',   48000, 'grain', 12, false, 850,  ARRAY['Combined softener + iron filter','Fine mesh resin','48,000 grain','Up to 6 ppm iron'], '{"grain_capacity": 48000, "iron_removal_ppm": 6, "regeneration": "metered", "flow_rate_gpm": 10, "valve_type": "digital_SXT", "combo": true}', 'https://www.pentair.com/en-us/brands/fleck.html'),
  ('5600SXT-Iron2', 'Fleck 5600SXT Iron Pro 64K Combo',    '5600SXT',   64000, 'grain', 12, false, 1000, ARRAY['Combined softener + iron filter','Fine mesh resin','64,000 grain','Up to 8 ppm iron'], '{"grain_capacity": 64000, "iron_removal_ppm": 8, "regeneration": "metered", "flow_rate_gpm": 12, "valve_type": "digital_SXT", "combo": true}', 'https://www.pentair.com/en-us/brands/fleck.html'),
  ('7000SXT-48',    'Fleck 7000SXT 48K Grain Softener',    '7000SXT',   48000, 'grain', 15, false, 950,  ARRAY['Top-mount digital valve','1.25-inch porting','48,000 grain','High flow commercial'], '{"grain_capacity": 48000, "salt_efficiency": true, "regeneration": "metered", "flow_rate_gpm": 21, "valve_type": "digital_SXT", "port_size": "1.25_inch"}', 'https://www.pentair.com/en-us/brands/fleck.html')
) AS v(model_number, model_name, series, cap, cap_unit, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'fleck' AND c.slug = 'water-treatment-softener';


-- ======================== SPRINGWELL WATER TREATMENT ========================

-- SpringWell Whole-House Filters
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'floor', NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('CF1',       'SpringWell CF1 Whole House Filter 1-3 Bath',   'CF',   9,  'gpm', 10, 850,  ARRAY['4-stage filtration','Coconut shell carbon','KDF media','1-3 bathroom homes','1M gallon capacity'], '{"stages": 4, "flow_rate_gpm": 9, "capacity_gallons": 1000000, "media": ["KDF", "coconut_carbon", "sediment"], "bathrooms": "1-3"}', 'https://www.springwellwater.com'),
  ('CF4',       'SpringWell CF4 Whole House Filter 4-6 Bath',   'CF',   12, 'gpm', 10, 1050, ARRAY['4-stage filtration','Coconut shell carbon','KDF media','4-6 bathroom homes','1M gallon capacity'], '{"stages": 4, "flow_rate_gpm": 12, "capacity_gallons": 1000000, "media": ["KDF", "coconut_carbon", "sediment"], "bathrooms": "4-6"}', 'https://www.springwellwater.com'),
  ('CF-Plus7',  'SpringWell CF+ Whole House Filter 7+ Bath',    'CF+',  20, 'gpm', 10, 1350, ARRAY['4-stage filtration','Coconut shell carbon','KDF media','7+ bathroom homes','High flow'], '{"stages": 4, "flow_rate_gpm": 20, "capacity_gallons": 1000000, "media": ["KDF", "coconut_carbon", "sediment"], "bathrooms": "7+"}', 'https://www.springwellwater.com')
) AS v(model_number, model_name, series, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'springwell' AND c.slug = 'water-treatment-whole-house';

-- SpringWell Water Softeners
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'floor', NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('SS1',      'SpringWell SS1 Salt-Based Softener 1-3 Bath',   'SS',  32000, 'grain', 15, true,  1450, ARRAY['Salt-based ion exchange','Bluetooth head','App monitoring','1-3 bathroom homes'], '{"grain_capacity": 32000, "salt_efficiency": true, "regeneration": "metered", "flow_rate_gpm": 11, "bluetooth": true}', 'https://www.springwellwater.com'),
  ('SS4',      'SpringWell SS4 Salt-Based Softener 4-6 Bath',   'SS',  48000, 'grain', 15, true,  1650, ARRAY['Salt-based ion exchange','Bluetooth head','App monitoring','4-6 bathroom homes'], '{"grain_capacity": 48000, "salt_efficiency": true, "regeneration": "metered", "flow_rate_gpm": 13, "bluetooth": true}', 'https://www.springwellwater.com'),
  ('SS-Plus7', 'SpringWell SS+ Salt-Based Softener 7+ Bath',    'SS+', 80000, 'grain', 15, true,  2050, ARRAY['Salt-based ion exchange','Bluetooth head','App monitoring','7+ bathroom homes','High flow'], '{"grain_capacity": 80000, "salt_efficiency": true, "regeneration": "metered", "flow_rate_gpm": 20, "bluetooth": true}', 'https://www.springwellwater.com'),
  ('FutureSoft-1', 'SpringWell FutureSoft Salt-Free 1-3 Bath',  'FutureSoft', 12, 'gpm', 10, false, 1550, ARRAY['Salt-free conditioning','Template Assisted Crystallization','No waste water','No electricity needed'], '{"flow_rate_gpm": 12, "technology": "TAC", "salt_free": true, "no_drain": true, "bathrooms": "1-3"}', 'https://www.springwellwater.com'),
  ('FutureSoft-4', 'SpringWell FutureSoft Salt-Free 4-6 Bath',  'FutureSoft', 20, 'gpm', 10, false, 1850, ARRAY['Salt-free conditioning','Template Assisted Crystallization','No waste water','No electricity needed'], '{"flow_rate_gpm": 20, "technology": "TAC", "salt_free": true, "no_drain": true, "bathrooms": "4-6"}', 'https://www.springwellwater.com')
) AS v(model_number, model_name, series, cap, cap_unit, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'springwell' AND c.slug = 'water-treatment-softener';

-- SpringWell Iron Filters
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'floor', NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WS1',       'SpringWell WS1 Well Water Filter 1-3 Bath',   'WS',   9,  'gpm', 12, 1500, ARRAY['Air injection iron filter','Iron manganese sulfur removal','Chemical-free','Automatic backwash','1-3 bath'], '{"iron_removal_ppm": 7, "manganese_removal_ppm": 1, "h2s_removal_ppm": 8, "flow_rate_gpm": 9, "chemical_free": true}', 'https://www.springwellwater.com'),
  ('WS4',       'SpringWell WS4 Well Water Filter 4-6 Bath',   'WS',   12, 'gpm', 12, 1800, ARRAY['Air injection iron filter','Iron manganese sulfur removal','Chemical-free','Automatic backwash','4-6 bath'], '{"iron_removal_ppm": 7, "manganese_removal_ppm": 1, "h2s_removal_ppm": 8, "flow_rate_gpm": 12, "chemical_free": true}', 'https://www.springwellwater.com'),
  ('WS-Plus7',  'SpringWell WS+ Well Water Filter 7+ Bath',    'WS+',  20, 'gpm', 12, 2200, ARRAY['Air injection iron filter','Iron manganese sulfur removal','Chemical-free','Automatic backwash','7+ bath'], '{"iron_removal_ppm": 7, "manganese_removal_ppm": 1, "h2s_removal_ppm": 8, "flow_rate_gpm": 20, "chemical_free": true}', 'https://www.springwellwater.com')
) AS v(model_number, model_name, series, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'springwell' AND c.slug = 'water-treatment-iron';

-- SpringWell RO
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'under-sink', NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('SWRO-Nickel',  'SpringWell SWRO Under-Sink RO System',       'SWRO',    75,  'gpd', 10, 450, ARRAY['4-stage reverse osmosis','Under-sink','75 GPD','Quick-connect fittings','Lead-free faucet'], '{"stages": 4, "gpd": 75, "rejection_rate": 0.99, "tank_gallons": 3.2}', 'https://www.springwellwater.com'),
  ('SWRO-Chrome',  'SpringWell SWRO Under-Sink RO Chrome',        'SWRO',    75,  'gpd', 10, 480, ARRAY['4-stage reverse osmosis','Under-sink','75 GPD','Chrome faucet','Quick-connect'], '{"stages": 4, "gpd": 75, "rejection_rate": 0.99, "tank_gallons": 3.2}', 'https://www.springwellwater.com')
) AS v(model_number, model_name, series, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'springwell' AND c.slug = 'water-treatment-ro';

-- SpringWell UV
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'inline', NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('UV-ADD', 'SpringWell UV Add-On System', 'UV', 15, 'gpm', 10, 480, ARRAY['UV disinfection add-on','15 GPM flow rate','99.9% bacteria kill','Easy lamp replacement'], '{"flow_rate_gpm": 15, "lamp_watts": 40, "lamp_life_hours": 9000, "kill_rate": 0.999, "alarm": true}', 'https://www.springwellwater.com')
) AS v(model_number, model_name, series, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'springwell' AND c.slug = 'water-treatment-uv';


-- ======================== AQUASANA WATER TREATMENT ========================

-- Aquasana Whole-House Filters
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'floor', NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('EQ-1000',    'Aquasana Rhino 1M Gallon Whole House',     'Rhino',  7,  'gpm', 10, 800,  ARRAY['1,000,000 gallon capacity','KDF media','Activated carbon','Sediment pre-filter','10 year lifespan'], '{"capacity_gallons": 1000000, "flow_rate_gpm": 7, "stages": 3, "media": ["KDF", "activated_carbon", "sediment"]}', 'https://www.aquasana.com'),
  ('EQ-600',     'Aquasana Rhino 600K Gallon Whole House',   'Rhino',  7,  'gpm', 6,  640,  ARRAY['600,000 gallon capacity','KDF media','Activated carbon','Budget whole house'], '{"capacity_gallons": 600000, "flow_rate_gpm": 7, "stages": 3, "media": ["KDF", "activated_carbon", "sediment"]}', 'https://www.aquasana.com'),
  ('EQ-WELL-UV', 'Aquasana Rhino Well Water + UV',           'Rhino',  7,  'gpm', 5,  1700, ARRAY['Well water specific','UV disinfection included','Iron/sulfur pre-filter','500K gallon capacity'], '{"capacity_gallons": 500000, "flow_rate_gpm": 7, "stages": 4, "media": ["sediment", "KDF", "activated_carbon"], "uv_included": true}', 'https://www.aquasana.com'),
  ('EQ-SS20',    'Aquasana SimplySoft Salt-Free Conditioner', 'SimplySoft', 7, 'gpm', 6, 850, ARRAY['Salt-free scale conditioning','SCM technology','No waste water','No electricity'], '{"flow_rate_gpm": 7, "technology": "SCM", "salt_free": true, "no_drain": true}', 'https://www.aquasana.com'),
  ('EQ-1000-AST','Aquasana Rhino + SimplySoft Combo',         'Rhino',  7,  'gpm', 10, 2000, ARRAY['1M gallon filter + salt-free conditioner','Complete whole house treatment','6 year filter life'], '{"capacity_gallons": 1000000, "flow_rate_gpm": 7, "stages": 4, "softener": "salt_free"}', 'https://www.aquasana.com')
) AS v(model_number, model_name, series, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'aquasana' AND c.slug = 'water-treatment-whole-house';

-- Aquasana Under-Sink RO
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'under-sink', NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('AQ-RO-3',       'Aquasana OptimH2O Reverse Osmosis',          'OptimH2O',    44, 'gpd', 10, 200, ARRAY['3-stage reverse osmosis','Remineralizing filter','Claryum technology','NSF certified'], '{"stages": 3, "gpd": 44, "rejection_rate": 0.95, "remineralizer": true}', 'https://www.aquasana.com'),
  ('AQ-RO-3-UV',    'Aquasana OptimH2O RO + UV',                   'OptimH2O',    44, 'gpd', 10, 350, ARRAY['3-stage RO + UV disinfection','Remineralizing filter','NSF certified','99.99% bacteria kill'], '{"stages": 4, "gpd": 44, "rejection_rate": 0.95, "remineralizer": true, "uv_included": true}', 'https://www.aquasana.com'),
  ('AQ-5200',       'Aquasana 2-Stage Under Sink Filter',           'Claryum',     35, 'gpd', 10, 130, ARRAY['2-stage carbon block','Under-sink','No RO waste water','Retains minerals'], '{"stages": 2, "capacity_gallons": 500, "flow_rate_gpm": 0.5}', 'https://www.aquasana.com'),
  ('AQ-5300+',      'Aquasana 3-Stage Max Flow Under Sink Filter',  'Claryum',     44, 'gpd', 10, 180, ARRAY['3-stage filtration','Under-sink','Max flow rate','NSF certified 77 contaminants'], '{"stages": 3, "capacity_gallons": 800, "flow_rate_gpm": 0.72}', 'https://www.aquasana.com')
) AS v(model_number, model_name, series, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'aquasana' AND c.slug = 'water-treatment-ro';


-- ======================== PELICAN WATER TREATMENT ========================

-- Pelican Whole-House Filters
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'floor', NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('PC600',     'Pelican Carbon Series 600K Gallon Filter',   'Carbon',    10, 'gpm', 5,  750,  ARRAY['600,000 gallon capacity','Catalytic carbon','5 micron sediment pre-filter','Chlorine chloramine removal'], '{"capacity_gallons": 600000, "flow_rate_gpm": 10, "stages": 2, "media": ["catalytic_carbon", "sediment"]}', 'https://www.pelicanwater.com'),
  ('PC1000',    'Pelican Carbon Series 1M Gallon Filter',     'Carbon',    15, 'gpm', 10, 1100, ARRAY['1,000,000 gallon capacity','Catalytic carbon','5 micron sediment pre-filter','10 year filter life'], '{"capacity_gallons": 1000000, "flow_rate_gpm": 15, "stages": 2, "media": ["catalytic_carbon", "sediment"]}', 'https://www.pelicanwater.com'),
  ('PSE1800',   'Pelican Premium Whole House Filter + Softener', 'Premium', 12, 'gpm', 10, 2600, ARRAY['Combo filter and softener','NaturSoft salt-free','1M gallon carbon filter','No waste water'], '{"capacity_gallons": 1000000, "flow_rate_gpm": 12, "softener": "salt_free", "technology": "NaturSoft"}', 'https://www.pelicanwater.com'),
  ('PSE2000',   'Pelican Pro Whole House Filter + Softener',     'Pro',     15, 'gpm', 10, 3200, ARRAY['Pro combo filter and softener','NaturSoft salt-free','1M gallon carbon','High flow'], '{"capacity_gallons": 1000000, "flow_rate_gpm": 15, "softener": "salt_free", "technology": "NaturSoft"}', 'https://www.pelicanwater.com')
) AS v(model_number, model_name, series, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'pelican' AND c.slug = 'water-treatment-whole-house';

-- Pelican Water Softeners (Salt-Free)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'floor', NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('NS3',       'Pelican NaturSoft Salt-Free 1-3 Bath',    'NaturSoft', 10, 'gpm', 10, 1600, ARRAY['Salt-free water conditioning','NaturSoft technology','No waste water','No electricity','1-3 bath homes'], '{"flow_rate_gpm": 10, "technology": "NaturSoft", "salt_free": true, "no_drain": true, "bathrooms": "1-3"}', 'https://www.pelicanwater.com'),
  ('NS6',       'Pelican NaturSoft Salt-Free 4-6 Bath',    'NaturSoft', 15, 'gpm', 10, 2000, ARRAY['Salt-free water conditioning','NaturSoft technology','No waste water','No electricity','4-6 bath homes'], '{"flow_rate_gpm": 15, "technology": "NaturSoft", "salt_free": true, "no_drain": true, "bathrooms": "4-6"}', 'https://www.pelicanwater.com'),
  ('NS9',       'Pelican NaturSoft Salt-Free 7+ Bath',     'NaturSoft', 20, 'gpm', 10, 2500, ARRAY['Salt-free water conditioning','NaturSoft technology','No waste water','No electricity','7+ bath homes'], '{"flow_rate_gpm": 20, "technology": "NaturSoft", "salt_free": true, "no_drain": true, "bathrooms": "7+"}', 'https://www.pelicanwater.com'),
  ('Advantage',  'Pelican Advantage Series Salt Softener',  'Advantage', 32000, 'grain', 15, 1200, ARRAY['Traditional salt-based softener','Digital metered valve','32,000 grain','Efficient regeneration'], '{"grain_capacity": 32000, "salt_efficiency": true, "regeneration": "metered", "flow_rate_gpm": 10}', 'https://www.pelicanwater.com'),
  ('Adv-48',     'Pelican Advantage Series 48K Softener',   'Advantage', 48000, 'grain', 15, 1500, ARRAY['Traditional salt-based softener','Digital metered valve','48,000 grain','Large home'], '{"grain_capacity": 48000, "salt_efficiency": true, "regeneration": "metered", "flow_rate_gpm": 12}', 'https://www.pelicanwater.com')
) AS v(model_number, model_name, series, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'pelican' AND c.slug = 'water-treatment-softener';

-- Pelican Iron Filters
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'floor', NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WF4',       'Pelican Iron & Manganese Filter 1-3 Bath',  'WF',  9,  'gpm', 12, 1500, ARRAY['Air injection oxidation','Iron and manganese removal','Chemical-free','Automatic backwash'], '{"iron_removal_ppm": 10, "manganese_removal_ppm": 2, "flow_rate_gpm": 9, "chemical_free": true, "backwash": "automatic"}', 'https://www.pelicanwater.com'),
  ('WF8',       'Pelican Iron & Manganese Filter 4-6 Bath',  'WF',  12, 'gpm', 12, 1900, ARRAY['Air injection oxidation','Iron and manganese removal','Chemical-free','High flow backwash'], '{"iron_removal_ppm": 10, "manganese_removal_ppm": 2, "flow_rate_gpm": 12, "chemical_free": true, "backwash": "automatic"}', 'https://www.pelicanwater.com')
) AS v(model_number, model_name, series, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'pelican' AND c.slug = 'water-treatment-iron';

-- Pelican RO
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'under-sink', NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('RO-6',     'Pelican 6-Stage RO System',          'RO',  50, 'gpd', 10, 350, ARRAY['6-stage reverse osmosis','Alkaline remineralization','Under-sink','Chrome faucet included'], '{"stages": 6, "gpd": 50, "rejection_rate": 0.97, "remineralizer": true, "tank_gallons": 3.0}', 'https://www.pelicanwater.com'),
  ('RO-4',     'Pelican 4-Stage RO System',          'RO',  50, 'gpd', 10, 250, ARRAY['4-stage reverse osmosis','Under-sink','Budget RO system','Quick-connect fittings'], '{"stages": 4, "gpd": 50, "rejection_rate": 0.95, "tank_gallons": 2.5}', 'https://www.pelicanwater.com')
) AS v(model_number, model_name, series, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'pelican' AND c.slug = 'water-treatment-ro';

-- Pelican UV
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'inline', NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('UV-18',    'Pelican UV Disinfection System 18 GPM',  'UV',  18, 'gpm', 10, 480, ARRAY['UV disinfection','18 GPM flow rate','99.9% pathogen kill','Visual lamp indicator'], '{"flow_rate_gpm": 18, "lamp_watts": 40, "lamp_life_hours": 9000, "kill_rate": 0.999, "alarm": true}', 'https://www.pelicanwater.com')
) AS v(model_number, model_name, series, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'pelican' AND c.slug = 'water-treatment-uv';


-- ======================== VIQUA UV DISINFECTION ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'inline', NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('D4',        'Viqua D4 Home UV System',              'D',    12, 'gpm', 10, false, 450,  ARRAY['12 GPM flow rate','Audible lamp-out alarm','40W lamp','Stainless steel chamber','1-2 bathroom homes'], '{"flow_rate_gpm": 12, "lamp_watts": 40, "lamp_life_hours": 9000, "alarm": true, "chamber": "stainless", "connection": "0.75_inch"}', 'https://www.viqua.com'),
  ('D4-Plus',   'Viqua D4-Plus Home UV System',         'D-Plus', 12, 'gpm', 10, false, 550, ARRAY['12 GPM flow rate','LCD controller','Countdown timer','Lamp replacement reminder','Enhanced monitoring'], '{"flow_rate_gpm": 12, "lamp_watts": 40, "lamp_life_hours": 9000, "alarm": true, "lcd_controller": true, "chamber": "stainless"}', 'https://www.viqua.com'),
  ('E4',        'Viqua E4 UV System',                   'E',    15, 'gpm', 10, false, 520,  ARRAY['15 GPM flow rate','Audible lamp-out alarm','50W lamp','Stainless steel chamber','2-4 bathroom homes'], '{"flow_rate_gpm": 15, "lamp_watts": 50, "lamp_life_hours": 9000, "alarm": true, "chamber": "stainless", "connection": "1_inch"}', 'https://www.viqua.com'),
  ('E4-Plus',   'Viqua E4-Plus UV System',              'E-Plus', 15, 'gpm', 10, false, 650, ARRAY['15 GPM flow rate','LCD controller','Countdown timer','Lamp replacement reminder','UV intensity monitor'], '{"flow_rate_gpm": 15, "lamp_watts": 50, "lamp_life_hours": 9000, "alarm": true, "lcd_controller": true, "uv_monitor": true}', 'https://www.viqua.com'),
  ('F4',        'Viqua F4 UV System',                   'F',    18, 'gpm', 10, false, 620,  ARRAY['18 GPM flow rate','Audible alarm','65W lamp','Stainless chamber','4-6 bathroom homes'], '{"flow_rate_gpm": 18, "lamp_watts": 65, "lamp_life_hours": 9000, "alarm": true, "chamber": "stainless", "connection": "1_inch"}', 'https://www.viqua.com'),
  ('F4-Plus',   'Viqua F4-Plus UV System',              'F-Plus', 18, 'gpm', 10, false, 750, ARRAY['18 GPM flow rate','LCD controller','Countdown timer','UV intensity monitor','Enhanced'], '{"flow_rate_gpm": 18, "lamp_watts": 65, "lamp_life_hours": 9000, "alarm": true, "lcd_controller": true, "uv_monitor": true}', 'https://www.viqua.com'),
  ('650650',    'Viqua 650650 Pro UV System',           'Pro',  25, 'gpm', 10, false, 900,  ARRAY['25 GPM flow rate','Professional grade','100W lamp','Large home/light commercial'], '{"flow_rate_gpm": 25, "lamp_watts": 100, "lamp_life_hours": 9000, "alarm": true, "chamber": "stainless", "connection": "1.25_inch"}', 'https://www.viqua.com'),
  ('650650-R',  'Viqua 650650-R Pro UV with Sensor',    'Pro',  25, 'gpm', 10, false, 1250, ARRAY['25 GPM flow rate','UV intensity sensor','Professional grade','Real-time monitoring','Digital display'], '{"flow_rate_gpm": 25, "lamp_watts": 100, "lamp_life_hours": 9000, "alarm": true, "uv_sensor": true, "digital_display": true}', 'https://www.viqua.com'),
  ('IHS22-D4',  'Viqua IHS22-D4 Integrated Home System','IHS',  12, 'gpm', 10, false, 750,  ARRAY['UV + sediment + carbon pre-filters','Complete home system','All-in-one','Easy maintenance'], '{"flow_rate_gpm": 12, "lamp_watts": 40, "lamp_life_hours": 9000, "pre_filters": ["sediment", "carbon"], "integrated": true}', 'https://www.viqua.com'),
  ('IHS22-E4',  'Viqua IHS22-E4 Integrated Home System','IHS',  15, 'gpm', 10, false, 850,  ARRAY['UV + sediment + carbon pre-filters','Complete home system','High flow','Easy maintenance'], '{"flow_rate_gpm": 15, "lamp_watts": 50, "lamp_life_hours": 9000, "pre_filters": ["sediment", "carbon"], "integrated": true}', 'https://www.viqua.com'),
  ('VH410',     'Viqua VH410 Whole Home UV',            'VH',   18, 'gpm', 10, true,  1100, ARRAY['WiFi connected','App monitoring','Lamp life tracking','Smart alerts','Premium whole home'], '{"flow_rate_gpm": 18, "lamp_watts": 55, "lamp_life_hours": 9000, "wifi": true, "app_control": true, "smart_alerts": true}', 'https://www.viqua.com'),
  ('VH200',     'Viqua VH200 Tap UV System',            'VH',   9,  'gpm', 10, false, 300,  ARRAY['Point-of-use UV','Compact design','9 GPM','Easy DIY install','Budget UV option'], '{"flow_rate_gpm": 9, "lamp_watts": 16, "lamp_life_hours": 9000, "alarm": false, "compact": true}', 'https://www.viqua.com'),
  ('S2Q-PA',    'Viqua Sterilight S2Q-PA UV System',   'Sterilight', 6, 'gpm', 10, false, 220, ARRAY['Point-of-entry UV','Compact 6 GPM','Budget residential','Easy lamp change'], '{"flow_rate_gpm": 6, "lamp_watts": 14, "lamp_life_hours": 9000, "alarm": false, "compact": true}', 'https://www.viqua.com'),
  ('S5Q-PA',    'Viqua Sterilight S5Q-PA UV System',   'Sterilight', 10, 'gpm', 10, false, 320, ARRAY['Point-of-entry UV','10 GPM','Mid-range residential','Audible alarm'], '{"flow_rate_gpm": 10, "lamp_watts": 25, "lamp_life_hours": 9000, "alarm": true, "compact": true}', 'https://www.viqua.com'),
  ('S8Q-PA',    'Viqua Sterilight S8Q-PA UV System',   'Sterilight', 14, 'gpm', 10, false, 380, ARRAY['Point-of-entry UV','14 GPM','Larger residential','Audible alarm'], '{"flow_rate_gpm": 14, "lamp_watts": 32, "lamp_life_hours": 9000, "alarm": true}', 'https://www.viqua.com')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'viqua' AND c.slug = 'water-treatment-uv';
