SET ROLE postgres;
-- ============================================================================
-- Supplemental Equipment Catalog #2: Missing Brand Catalog Entries
-- Brands added in 28_manufacturers_supplemental.sql that lack catalog entries
-- Covers: Well Water, Irrigation, Bathroom Fixtures, Pool Systems
-- Target: 250+ models
-- ============================================================================


-- ############################################################################
-- WELL WATER SYSTEMS
-- ############################################################################

-- ======================== BERKELEY (Well Pumps) ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('B5P4S-07',  '1/2 HP 4" Submersible 5 GPM',   'B5P', 'submersible', 5,  'gpm', 12, 480,  ARRAY['4-inch stainless steel','5 GPM','1/2 HP','Pentair brand','2-wire'], '{"hp": 0.5, "gpm": 5, "voltage": 230, "depth_ft": 200, "wire": "2-wire", "material": "stainless"}', 'https://www.pentair.com/en-us/brands/berkeley.html'),
  ('B10P4S-10', '1 HP 4" Submersible 10 GPM',     'B10P', 'submersible', 10, 'gpm', 12, 620,  ARRAY['4-inch stainless steel','10 GPM','1 HP motor','Sand resistant'], '{"hp": 1.0, "gpm": 10, "voltage": 230, "depth_ft": 300, "wire": "2-wire", "material": "stainless"}', 'https://www.pentair.com/en-us/brands/berkeley.html'),
  ('B15P4S-15', '1.5 HP 4" Submersible 15 GPM',   'B15P', 'submersible', 15, 'gpm', 12, 780,  ARRAY['4-inch stainless steel','15 GPM','1.5 HP motor','Deep well rated'], '{"hp": 1.5, "gpm": 15, "voltage": 230, "depth_ft": 480, "wire": "2-wire", "material": "stainless"}', 'https://www.pentair.com/en-us/brands/berkeley.html'),
  ('B20P4S-20', '2 HP 4" Submersible 20 GPM',     'B20P', 'submersible', 20, 'gpm', 12, 950,  ARRAY['4-inch stainless steel','20 GPM','2 HP motor','High capacity'], '{"hp": 2.0, "gpm": 20, "voltage": 230, "depth_ft": 600, "wire": "2-wire", "material": "stainless"}', 'https://www.pentair.com/en-us/brands/berkeley.html'),
  ('BSW5J-07',  '1/2 HP Shallow Well Jet Pump',    'BSW',  'inline',      12, 'gpm', 10, 350,  ARRAY['Cast iron body','Shallow well to 25 ft','Self-priming','Thermoplastic impeller'], '{"hp": 0.5, "gpm": 12, "voltage": 115, "max_suction_lift_ft": 25, "material": "cast_iron"}', 'https://www.pentair.com/en-us/brands/berkeley.html'),
  ('BDJ-10',    '1 HP Convertible Deep Well Jet',   'BDJ',  'inline',      14, 'gpm', 10, 480,  ARRAY['Cast iron body','Convertible shallow/deep well','Up to 90 ft depth','Dual voltage'], '{"hp": 1.0, "gpm": 14, "voltage": 115, "max_depth_ft": 90, "material": "cast_iron"}', 'https://www.pentair.com/en-us/brands/berkeley.html')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'berkeley' AND c.slug = 'well-pump';


-- ======================== WATERWORKER (Pressure Tanks) ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'floor-standing', NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('HT-14B',  '14 Gallon Vertical Pressure Tank',  'HT', 14, 'gallons', 15, 160, ARRAY['14-gallon capacity','Vertical design','Pre-charged bladder','Stainless steel connection'], '{"gallons": 14, "orientation": "vertical", "max_psi": 100, "pre_charge_psi": 38, "connection": "1 inch", "material": "steel"}', 'https://www.amtrol.com/waterworker'),
  ('HT-20B',  '20 Gallon Vertical Pressure Tank',  'HT', 20, 'gallons', 15, 200, ARRAY['20-gallon capacity','Vertical design','Pre-charged bladder','Popular residential size'], '{"gallons": 20, "orientation": "vertical", "max_psi": 100, "pre_charge_psi": 38, "connection": "1 inch", "material": "steel"}', 'https://www.amtrol.com/waterworker'),
  ('HT-32B',  '32 Gallon Vertical Pressure Tank',  'HT', 32, 'gallons', 15, 280, ARRAY['32-gallon capacity','Vertical design','Pre-charged bladder','Medium household'], '{"gallons": 32, "orientation": "vertical", "max_psi": 100, "pre_charge_psi": 38, "connection": "1 inch", "material": "steel"}', 'https://www.amtrol.com/waterworker'),
  ('HT-44B',  '44 Gallon Vertical Pressure Tank',  'HT', 44, 'gallons', 15, 350, ARRAY['44-gallon capacity','Vertical design','Pre-charged bladder','Larger residential'], '{"gallons": 44, "orientation": "vertical", "max_psi": 100, "pre_charge_psi": 38, "connection": "1.25 inch", "material": "steel"}', 'https://www.amtrol.com/waterworker'),
  ('HT-62B',  '62 Gallon Vertical Pressure Tank',  'HT', 62, 'gallons', 15, 480, ARRAY['62-gallon capacity','Vertical design','Pre-charged bladder','Large home capacity'], '{"gallons": 62, "orientation": "vertical", "max_psi": 100, "pre_charge_psi": 38, "connection": "1.25 inch", "material": "steel"}', 'https://www.amtrol.com/waterworker'),
  ('HT-86B',  '86 Gallon Vertical Pressure Tank',  'HT', 86, 'gallons', 15, 620, ARRAY['86-gallon capacity','Vertical design','Pre-charged bladder','High demand households'], '{"gallons": 86, "orientation": "vertical", "max_psi": 100, "pre_charge_psi": 38, "connection": "1.25 inch", "material": "steel"}', 'https://www.amtrol.com/waterworker')
) AS v(model_number, model_name, series, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'waterworker' AND c.slug = 'pressure-tank';


-- ======================== EXPRESS WATER (RO & Whole-House) ========================

-- Express Water RO Systems
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'under-sink', NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('ROALK5D',    '5-Stage RO with Alkaline Remineralization', 'Alkaline', 50, 'gpd', 10, 190, ARRAY['5-stage filtration','Alkaline remineralization','NSF/ANSI 58 tested','Chrome faucet included','Quick-connect fittings'], '{"stages": 5, "gpd": 50, "tds_rejection": 0.99, "tank_gallons": 3.2, "alkaline": true}', 'https://www.expresswater.com'),
  ('RO5DX',      '5-Stage Under-Sink RO System',              'RO5DX',    50, 'gpd', 10, 150, ARRAY['5-stage reverse osmosis','99% contaminant removal','Quick-connect fittings','Deluxe chrome faucet'], '{"stages": 5, "gpd": 50, "tds_rejection": 0.99, "tank_gallons": 3.2}', 'https://www.expresswater.com'),
  ('RO10DX',     '10-Stage Under-Sink RO System',             'RO10DX',  100, 'gpd', 10, 250, ARRAY['10-stage filtration','UV + alkaline stages','Double capacity','Premium faucet'], '{"stages": 10, "gpd": 100, "tds_rejection": 0.99, "tank_gallons": 4, "uv": true, "alkaline": true}', 'https://www.expresswater.com'),
  ('TANKRO5DX',  'Tankless 5-Stage RO System',                'Tankless', 400, 'gpd', 10, 330, ARRAY['Tankless design','400 GPD capacity','Compact under-sink','Smart LED indicator','1:1 drain ratio'], '{"stages": 5, "gpd": 400, "tds_rejection": 0.99, "tankless": true}', 'https://www.expresswater.com')
) AS v(model_number, model_name, series, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'express-water' AND c.slug = 'water-treatment-ro';

-- Express Water Whole-House
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'inline', NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WH300SCKS',  '3-Stage Whole-House Filter',    'Heavy Metal', 15, 'gpm', 8, 380, ARRAY['3-stage filtration','KDF + carbon + sediment','100K gallon capacity','1-inch ports'], '{"stages": 3, "gpm": 15, "capacity_gallons": 100000, "port_size": "1 inch"}', 'https://www.expresswater.com'),
  ('WH300SCGS',  '3-Stage Whole-House Anti-Scale', 'Anti-Scale',  15, 'gpm', 8, 420, ARRAY['3-stage filtration','Anti-scale media','Sediment + carbon','Salt-free conditioning'], '{"stages": 3, "gpm": 15, "capacity_gallons": 100000, "anti_scale": true}', 'https://www.expresswater.com')
) AS v(model_number, model_name, series, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'express-water' AND c.slug = 'water-treatment-whole-house';


-- ======================== FLEXCON (Pressure Tanks) ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'floor-standing', NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('FL4',    'Flexlite FL4 14 Gallon',    'FL', 14, 'gallons', 15, 210, ARRAY['Lightweight composite construction','No corrosion','NSF/ANSI 61 certified','Stainless steel connection'], '{"gallons": 14, "orientation": "vertical", "max_psi": 100, "pre_charge_psi": 40, "material": "composite", "weight_lbs": 10}', 'https://www.flexconind.com'),
  ('FL7',    'Flexlite FL7 22 Gallon',    'FL', 22, 'gallons', 15, 280, ARRAY['Lightweight composite','22 gallon capacity','No corrosion ever','Easy one-person install'], '{"gallons": 22, "orientation": "vertical", "max_psi": 100, "pre_charge_psi": 40, "material": "composite", "weight_lbs": 14}', 'https://www.flexconind.com'),
  ('FL12',   'Flexlite FL12 35 Gallon',   'FL', 35, 'gallons', 15, 390, ARRAY['Lightweight composite','35 gallon capacity','NSF/ANSI 61','Professional grade'], '{"gallons": 35, "orientation": "vertical", "max_psi": 100, "pre_charge_psi": 40, "material": "composite", "weight_lbs": 20}', 'https://www.flexconind.com'),
  ('FL18',   'Flexlite FL18 50 Gallon',   'FL', 50, 'gallons', 15, 520, ARRAY['Lightweight composite','50 gallon capacity','Commercial grade','No condensation'], '{"gallons": 50, "orientation": "vertical", "max_psi": 100, "pre_charge_psi": 40, "material": "composite", "weight_lbs": 28}', 'https://www.flexconind.com'),
  ('WR140R', 'Stetson WR 14 Gallon Steel', 'WR', 14, 'gallons', 12, 140, ARRAY['Steel construction','Replaceable bladder','Budget option','Standard residential'], '{"gallons": 14, "orientation": "vertical", "max_psi": 100, "pre_charge_psi": 38, "material": "steel", "bladder_replaceable": true}', 'https://www.flexconind.com'),
  ('WR220R', 'Stetson WR 20 Gallon Steel', 'WR', 20, 'gallons', 12, 180, ARRAY['Steel construction','Replaceable bladder','20 gallon','Value option'], '{"gallons": 20, "orientation": "vertical", "max_psi": 100, "pre_charge_psi": 38, "material": "steel", "bladder_replaceable": true}', 'https://www.flexconind.com')
) AS v(model_number, model_name, series, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'flexcon' AND c.slug = 'pressure-tank';


-- ======================== ECOWATER (Water Softeners) ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'floor-standing', NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('ERR3500R20',  'ERR 3500 Series 20 Grain',    'ERR 3500', 20000, 'grains', 15, true, 1800, ARRAY['HydroLink Plus WiFi monitoring','Demand-initiated regeneration','Salt and water efficient','Dealer-installed'], '{"grain_capacity": 20000, "flow_rate_gpm": 7, "salt_capacity_lbs": 100, "wifi": true, "monitoring": "HydroLink Plus"}', 'https://www.ecowater.com'),
  ('ERR3500R30',  'ERR 3500 Series 30 Grain',    'ERR 3500', 30000, 'grains', 15, true, 2100, ARRAY['HydroLink Plus WiFi','30K grain capacity','Smart salt monitoring','NSF certified'], '{"grain_capacity": 30000, "flow_rate_gpm": 9, "salt_capacity_lbs": 150, "wifi": true, "monitoring": "HydroLink Plus"}', 'https://www.ecowater.com'),
  ('ERR3500R40',  'ERR 3500 Series 40 Grain',    'ERR 3500', 40000, 'grains', 15, true, 2400, ARRAY['HydroLink Plus WiFi','40K grain capacity','Large household','Smart diagnostics'], '{"grain_capacity": 40000, "flow_rate_gpm": 11, "salt_capacity_lbs": 200, "wifi": true, "monitoring": "HydroLink Plus"}', 'https://www.ecowater.com'),
  ('ERR3700R30',  'ERR 3700 Series 30 Grain',    'ERR 3700', 30000, 'grains', 15, true, 2600, ARRAY['HydroLink Plus WiFi','Integrated whole-house filter','Dual-media filtration','Premium series'], '{"grain_capacity": 30000, "flow_rate_gpm": 10, "salt_capacity_lbs": 150, "wifi": true, "integrated_filter": true}', 'https://www.ecowater.com'),
  ('ERR3700R45',  'ERR 3700 Series 45 Grain',    'ERR 3700', 45000, 'grains', 15, true, 3000, ARRAY['HydroLink Plus WiFi','Integrated carbon filter','45K grain','Large family capacity'], '{"grain_capacity": 45000, "flow_rate_gpm": 12, "salt_capacity_lbs": 250, "wifi": true, "integrated_filter": true}', 'https://www.ecowater.com')
) AS v(model_number, model_name, series, cap, cap_unit, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'ecowater' AND c.slug = 'water-treatment-softener';


-- ======================== WATER-RIGHT (Water Softeners) ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'floor-standing', NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('IMP-1054',   'Impression Series 1054',          'Impression',      24000, 'grains', 15, 1600, ARRAY['Crystal-Right media option','Clack WS1 valve','1.0 cu ft resin','Dealer-installed'], '{"grain_capacity": 24000, "flow_rate_gpm": 7, "resin_cu_ft": 1.0, "valve": "Clack WS1"}', 'https://www.water-right.com'),
  ('IMP-1252',   'Impression Series 1252',          'Impression',      32000, 'grains', 15, 1900, ARRAY['Crystal-Right media option','Clack WS1 valve','1.25 cu ft resin','Medium household'], '{"grain_capacity": 32000, "flow_rate_gpm": 9, "resin_cu_ft": 1.25, "valve": "Clack WS1"}', 'https://www.water-right.com'),
  ('IMP-1354',   'Impression Series 1354',          'Impression',      40000, 'grains', 15, 2200, ARRAY['Crystal-Right media option','Clack WS1 valve','1.5 cu ft resin','Large household'], '{"grain_capacity": 40000, "flow_rate_gpm": 11, "resin_cu_ft": 1.5, "valve": "Clack WS1"}', 'https://www.water-right.com'),
  ('IMP-1665',   'Impression Plus Series 1665',     'Impression Plus', 48000, 'grains', 15, 2800, ARRAY['Twin-tank continuous soft water','No hard water during regen','Commercial capacity','Clack WS1 valve'], '{"grain_capacity": 48000, "flow_rate_gpm": 14, "resin_cu_ft": 2.0, "valve": "Clack WS1", "twin_tank": true}', 'https://www.water-right.com'),
  ('SANP-1054',  'Sanitizer Plus Iron/Sulfur Filter', 'Sanitizer Plus', 1, 'cu_ft', 12, 2100, ARRAY['Ozone sanitizing','Iron + sulfur removal','Chemical-free','Air injection oxidation','No filter media to replace'], '{"media_cu_ft": 1.0, "iron_ppm_max": 10, "sulfur_ppm_max": 5, "flow_rate_gpm": 8, "oxidation": "ozone"}', 'https://www.water-right.com'),
  ('SANP-1252',  'Sanitizer Plus 1252',              'Sanitizer Plus', 1.25, 'cu_ft', 12, 2500, ARRAY['Ozone sanitizing','Heavy iron removal','Sulfur elimination','Larger capacity'], '{"media_cu_ft": 1.25, "iron_ppm_max": 15, "sulfur_ppm_max": 8, "flow_rate_gpm": 10, "oxidation": "ozone"}', 'https://www.water-right.com')
) AS v(model_number, model_name, series, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'water-right' AND c.slug = 'water-treatment-softener';


-- ======================== CLACK (Water Softener Control Valves) ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'floor-standing', NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WS1CS',     'WS1 Complete Softener 1.0 cu ft', 'WS1', 24000, 'grains', 15, 850, ARRAY['Industry standard WS1 valve','1.0 cu ft resin','Meter-initiated regen','DIY-friendly','Bypass valve included'], '{"grain_capacity": 24000, "flow_rate_gpm": 7, "resin_cu_ft": 1.0, "valve": "WS1", "bypass": true}', 'https://www.clackcorp.com'),
  ('WS1CS-15',  'WS1 Complete Softener 1.5 cu ft', 'WS1', 40000, 'grains', 15, 1050, ARRAY['WS1 valve head','1.5 cu ft resin','Meter-initiated regen','Medium household'], '{"grain_capacity": 40000, "flow_rate_gpm": 11, "resin_cu_ft": 1.5, "valve": "WS1", "bypass": true}', 'https://www.clackcorp.com'),
  ('WS1CS-20',  'WS1 Complete Softener 2.0 cu ft', 'WS1', 56000, 'grains', 15, 1250, ARRAY['WS1 valve head','2.0 cu ft resin','Large home capacity','High flow rate'], '{"grain_capacity": 56000, "flow_rate_gpm": 14, "resin_cu_ft": 2.0, "valve": "WS1", "bypass": true}', 'https://www.clackcorp.com'),
  ('WS125CS',   'WS1.25 Complete Softener 2.5 cu ft', 'WS1.25', 64000, 'grains', 15, 1600, ARRAY['WS1.25 valve head','1.25-inch ports','2.5 cu ft resin','High flow commercial-residential'], '{"grain_capacity": 64000, "flow_rate_gpm": 18, "resin_cu_ft": 2.5, "valve": "WS1.25", "port_size": "1.25 inch"}', 'https://www.clackcorp.com'),
  ('WS1CF',     'WS1 Carbon Filter 1.0 cu ft',     'WS1', 1, 'cu_ft', 10, 650, ARRAY['WS1 valve head','Granular activated carbon','Chlorine + taste + odor removal','Automatic backwash'], '{"media_cu_ft": 1.0, "media_type": "GAC", "flow_rate_gpm": 7, "valve": "WS1"}', 'https://www.clackcorp.com')
) AS v(model_number, model_name, series, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'clack' AND c.slug = 'water-treatment-softener';


-- ======================== LUMINOR (UV Disinfection) ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'inline', NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('LB4-061',   'Blackcomb 5.1 4 GPM',     'Blackcomb', 4,  'gpm', 10, 520,  ARRAY['UV-C LED technology','No lamp replacement needed','Compact design','NSF 55 Class B','Instant on'], '{"gpm": 4, "uv_dose_mj_cm2": 40, "technology": "UV-C LED", "lamp_life_hours": 50000, "nsf_class": "B"}', 'https://www.luminoruv.com'),
  ('LB6-101',   'Blackcomb 5.1 6 GPM',     'Blackcomb', 6,  'gpm', 10, 680,  ARRAY['UV-C LED technology','No mercury','6 GPM flow rate','NSF 55 Class B','Low power consumption'], '{"gpm": 6, "uv_dose_mj_cm2": 40, "technology": "UV-C LED", "lamp_life_hours": 50000, "nsf_class": "B"}', 'https://www.luminoruv.com'),
  ('LB5-201',   'Blackcomb 5.1 10 GPM',    'Blackcomb', 10, 'gpm', 10, 880,  ARRAY['UV-C LED','Whole-house capacity','10 GPM','NSF 55 Class B','Low maintenance'], '{"gpm": 10, "uv_dose_mj_cm2": 40, "technology": "UV-C LED", "lamp_life_hours": 50000, "nsf_class": "B"}', 'https://www.luminoruv.com'),
  ('LH5-272',   'Hallett 30 UV System',     'Hallett',   18, 'gpm', 10, 1400, ARRAY['High-output UV lamp','Commercial capacity','NSF 55 Class A','Ballast monitoring','Quartz sleeve'], '{"gpm": 18, "uv_dose_mj_cm2": 40, "technology": "UV lamp", "lamp_life_hours": 9000, "nsf_class": "A"}', 'https://www.luminoruv.com'),
  ('LH5-302',   'Hallett 40 UV System',     'Hallett',   30, 'gpm', 10, 1800, ARRAY['High-output UV lamp','Large estate capacity','NSF 55 Class A','UV monitor','Audible alarm'], '{"gpm": 30, "uv_dose_mj_cm2": 40, "technology": "UV lamp", "lamp_life_hours": 9000, "nsf_class": "A"}', 'https://www.luminoruv.com')
) AS v(model_number, model_name, series, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'luminor' AND c.slug = 'water-treatment-uv';


-- ======================== TROJANUV (UV Disinfection) ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'inline', NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('650650',   'UVMax A',   'UVMax', 3,  'gpm', 10, 350,  ARRAY['Point-of-use UV','3 GPM','Compact design','Countdown timer','Audible lamp alarm'], '{"gpm": 3, "uv_dose_mj_cm2": 40, "lamp_life_hours": 9000, "power_watts": 14}', 'https://www.trojanuv.com'),
  ('650653',   'UVMax B4',  'UVMax', 4,  'gpm', 10, 420,  ARRAY['Small home UV','4 GPM','NSF 55 Class B','Countdown timer','Easy lamp change'], '{"gpm": 4, "uv_dose_mj_cm2": 40, "lamp_life_hours": 9000, "power_watts": 16}', 'https://www.trojanuv.com'),
  ('650654',   'UVMax C4',  'UVMax', 6,  'gpm', 10, 520,  ARRAY['Mid-size home UV','6 GPM','NSF 55 Class B','Smart monitoring','Quartz sleeve'], '{"gpm": 6, "uv_dose_mj_cm2": 40, "lamp_life_hours": 9000, "power_watts": 22}', 'https://www.trojanuv.com'),
  ('650656',   'UVMax D4',  'UVMax', 8,  'gpm', 10, 650,  ARRAY['Standard home UV','8 GPM','NSF 55 Class B','UV intensity monitor','Auto shutoff'], '{"gpm": 8, "uv_dose_mj_cm2": 40, "lamp_life_hours": 9000, "power_watts": 39}', 'https://www.trojanuv.com'),
  ('650658',   'UVMax E4',  'UVMax', 12, 'gpm', 10, 780,  ARRAY['Large home UV','12 GPM','NSF 55 Class B','Solenoid valve option','High output'], '{"gpm": 12, "uv_dose_mj_cm2": 40, "lamp_life_hours": 9000, "power_watts": 40}', 'https://www.trojanuv.com'),
  ('650660',   'UVMax F4',  'UVMax', 18, 'gpm', 10, 980,  ARRAY['Estate/commercial UV','18 GPM','NSF 55 Class A','UV sensor','Solenoid shutoff'], '{"gpm": 18, "uv_dose_mj_cm2": 40, "lamp_life_hours": 9000, "power_watts": 60, "nsf_class": "A"}', 'https://www.trojanuv.com'),
  ('650662',   'UVMax G4',  'UVMax', 25, 'gpm', 10, 1200, ARRAY['Large estate UV','25 GPM','NSF 55 Class A','High flow capacity','UV intensity sensor'], '{"gpm": 25, "uv_dose_mj_cm2": 40, "lamp_life_hours": 9000, "power_watts": 75, "nsf_class": "A"}', 'https://www.trojanuv.com')
) AS v(model_number, model_name, series, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'trojanuv' AND c.slug = 'water-treatment-uv';


-- ############################################################################
-- IRRIGATION SYSTEMS
-- ############################################################################

-- ======================== MELNOR (Hose Timers & Sprinklers) ========================

-- Melnor Controllers/Timers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('65034-AMZ', 'WiFi AquaTimer 2-Zone',   'AquaTimer', 'hose-mount', 2, 'zones', 6, true,  55, ARRAY['WiFi/app control','2-zone hose timer','Bluetooth + WiFi','Rain delay','Manual water button'], '{"zones": 2, "wifi": true, "bluetooth": true, "battery": "2x AA", "hose_thread": "3/4 inch"}', 'https://www.melnor.com'),
  ('65035-AMZ', 'WiFi AquaTimer 4-Zone',   'AquaTimer', 'hose-mount', 4, 'zones', 6, true,  75, ARRAY['WiFi/app control','4-zone hose timer','Independent scheduling','Rain delay'], '{"zones": 4, "wifi": true, "bluetooth": true, "battery": "2x AA", "hose_thread": "3/4 inch"}', 'https://www.melnor.com'),
  ('63280',     'Hydrologic 2-Zone Timer', 'Hydrologic', 'hose-mount', 2, 'zones', 5, false, 35, ARRAY['Digital 2-zone timer','Easy programming','Manual override','Water budgeting'], '{"zones": 2, "wifi": false, "battery": "2x AA", "hose_thread": "3/4 inch"}', 'https://www.melnor.com')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'melnor' AND c.slug = 'irrigation-controller';

-- Melnor Sprinklers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'hose-end', NULL, v.cap, 'sq_ft', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('65078-AMZ', 'XT Turbo Oscillating Sprinkler',   'XT',     4200, 5, 28, ARRAY['Turbo drive motor','Infinity adjustment','4200 sq ft coverage','Clog-resistant'], '{"coverage_sqft": 4200, "width_ft": 70, "length_ft": 60, "type": "oscillating"}', 'https://www.melnor.com'),
  ('65074-AMZ', 'XT Mini Turbo Oscillating',          'XT',     2800, 5, 18, ARRAY['Compact turbo design','Precision control','2800 sq ft coverage'], '{"coverage_sqft": 2800, "width_ft": 50, "length_ft": 56, "type": "oscillating"}', 'https://www.melnor.com'),
  ('9560',      'Revolving Sprinkler',                 'Classic', 1900, 5, 12, ARRAY['3-arm revolving','1900 sq ft coverage','Durable construction'], '{"coverage_sqft": 1900, "type": "revolving", "arms": 3}', 'https://www.melnor.com')
) AS v(model_number, model_name, series, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'melnor' AND c.slug = 'sprinkler-head';


-- ======================== GILMOUR (Sprinklers) ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'hose-end', NULL, v.cap, 'sq_ft', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('813753-1001', 'Pattern Master Circular Sprinkler',  'Pattern Master', 5670, 5, 25, ARRAY['Adjustable pattern','86 ft diameter coverage','Metal base','5670 sq ft'], '{"coverage_sqft": 5670, "diameter_ft": 86, "type": "circular", "material": "metal"}', 'https://www.gilmour.com'),
  ('845003-1001', 'Turbo Rotor Sprinkler',              'Turbo Rotor',    3800, 5, 20, ARRAY['Full or partial circle','Adjustable distance','Turbine drive','3800 sq ft'], '{"coverage_sqft": 3800, "type": "rotor", "adjustable_arc": true}', 'https://www.gilmour.com'),
  ('812173-1001', 'Rectangular Oscillating Sprinkler',   'Oscillating',    4000, 5, 22, ARRAY['Rectangular pattern','Adjustable width','Clog-resistant nozzles','4000 sq ft'], '{"coverage_sqft": 4000, "width_ft": 60, "length_ft": 67, "type": "oscillating"}', 'https://www.gilmour.com'),
  ('808993-1001', 'Spot Sprinkler Circle Pattern',       'Spot',            700,  5, 10, ARRAY['Compact spot watering','Circle pattern','Metal spike base','Small area coverage'], '{"coverage_sqft": 700, "type": "spot", "diameter_ft": 30}', 'https://www.gilmour.com')
) AS v(model_number, model_name, series, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'gilmour' AND c.slug = 'sprinkler-head';


-- ======================== RAINDRIP (Drip Irrigation) ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'drip', NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('SDFSTH1P', 'Drip Irrigation Patio Kit',      'Patio Kit',    25, 'emitters', 5, 30, ARRAY['25-plant patio kit','1/4-inch tubing','Adjustable emitters','Timer included'], '{"plants": 25, "tubing_type": "1/4 inch", "emitter_type": "adjustable"}', 'https://www.raindrip.com'),
  ('SDGCBHP',  'Ground Cover Drip Kit',           'Ground Cover', 50, 'emitters', 5, 40, ARRAY['50-emitter ground cover kit','1/2-inch mainline','Pressure compensating','500 sq ft'], '{"plants": 50, "coverage_sqft": 500, "tubing_type": "1/2 inch"}', 'https://www.raindrip.com'),
  ('SDFSTH2P', 'Automatic Container Drip Kit',    'Container',    20, 'emitters', 5, 35, ARRAY['20-container automatic kit','Battery timer included','Micro-tubing','Patio and deck'], '{"containers": 20, "timer_included": true, "tubing_type": "1/4 inch"}', 'https://www.raindrip.com'),
  ('SDFVSKIT', 'Vegetable Garden Drip Kit',        'Garden',       30, 'emitters', 5, 45, ARRAY['Garden row drip kit','Soaker tubing','75 ft coverage','Water efficient'], '{"plants": 30, "coverage_ft": 75, "tubing_type": "soaker"}', 'https://www.raindrip.com')
) AS v(model_number, model_name, series, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'raindrip' AND c.slug = 'sprinkler-head';


-- ======================== DIG (Drip & Micro-Sprinklers) ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'drip', NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('ML50',    'Maverick 1/2" Drip Line 50ft',    'Maverick',  50, 'linear_ft', 5, 15, ARRAY['1/2-inch drip line','12-inch emitter spacing','Pressure compensating','0.9 GPH per emitter'], '{"length_ft": 50, "emitter_spacing_in": 12, "gph_per_emitter": 0.9}', 'https://www.digcorp.com'),
  ('ML100',   'Maverick 1/2" Drip Line 100ft',   'Maverick', 100, 'linear_ft', 5, 22, ARRAY['1/2-inch drip line','100 ft roll','12-inch spacing','Pressure compensating'], '{"length_ft": 100, "emitter_spacing_in": 12, "gph_per_emitter": 0.9}', 'https://www.digcorp.com'),
  ('B36B',    'Micro-Sprinkler Full Circle',       'Micro',     8, 'ft_radius', 5, 3,  ARRAY['Full circle micro-sprinkler','Adjustable flow','8 ft radius','On stake'], '{"radius_ft": 8, "pattern": "full_circle", "gph": 13}', 'https://www.digcorp.com'),
  ('GE200',   'Drip and Micro-Sprinkler Kit',      'Complete',  20, 'emitters',  5, 55, ARRAY['Complete drip kit','20 micro-sprinklers','Timer + filter + tubing','200 sq ft coverage'], '{"emitters": 20, "coverage_sqft": 200, "timer_included": true}', 'https://www.digcorp.com'),
  ('D47AS',   'Adjustable Dripper 0-10 GPH',       'Dripper',   10, 'gph',       5, 2,  ARRAY['Adjustable 0-10 GPH','Barb connection','Individually adjustable','Flag type'], '{"gph_range": "0-10", "type": "adjustable_flag"}', 'https://www.digcorp.com')
) AS v(model_number, model_name, series, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'dig' AND c.slug = 'sprinkler-head';


-- ======================== NETRO (Smart Controllers) ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, true, v.estar, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('NTR-SPR-01', 'Sprite 6-Zone Smart Controller', 'Sprite', 'wall-mount', 6,  'zones', 8, true,  90,  ARRAY['WiFi/app control','AI-based scheduling','Weather-adaptive','EPA WaterSense','Easy DIY install'], '{"zones": 6, "wifi": true, "weather_intelligence": true, "ai_scheduling": true}', 'https://www.netrohome.com'),
  ('NTR-SPR-02', 'Sprite 12-Zone Smart Controller', 'Sprite', 'wall-mount', 12, 'zones', 8, true,  120, ARRAY['WiFi/app control','12-zone capacity','AI scheduling','WaterSense','Alexa/Google'], '{"zones": 12, "wifi": true, "weather_intelligence": true, "ai_scheduling": true}', 'https://www.netrohome.com'),
  ('NTR-PIX-01', 'Pixie Hose Timer',                'Pixie',  'hose-mount', 1,  'zones', 6, false, 50,  ARRAY['Smart hose timer','Bluetooth control','Weather-aware','Battery powered','Compact design'], '{"zones": 1, "bluetooth": true, "wifi": false, "battery": "2x AA"}', 'https://www.netrohome.com'),
  ('NTR-WSP-01', 'Whisperer Soil Sensor',            'Whisperer', 'ground', NULL, NULL, 5, true,  60,  ARRAY['Wireless soil moisture sensor','Sunlight and temperature','Works with Sprite','2-year battery'], '{"sensors": ["moisture", "light", "temperature"], "battery_life_years": 2, "wireless": true}', 'https://www.netrohome.com')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, estar, msrp, features, specs, url)
WHERE m.slug = 'netro' AND c.slug = 'irrigation-controller';


-- ======================== YARDIAN (Smart Controller with Camera) ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'wall-mount', NULL, v.cap, 'zones', true, v.lifespan, true, v.estar, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('YA-PRO-8',  'Yardian Pro 8-Zone',  'Pro', 8,  8, true,  150, ARRAY['Built-in HD camera','WiFi/app control','Weather-adaptive','Motion detection','Night vision','WaterSense'], '{"zones": 8, "wifi": true, "camera": "HD", "motion_detection": true, "night_vision": true, "weather_intelligence": true}', 'https://www.yardian.com'),
  ('YA-PRO-12', 'Yardian Pro 12-Zone', 'Pro', 12, 8, true,  200, ARRAY['Built-in HD camera','12-zone capacity','WiFi/app control','Weather-adaptive','Motion alerts','Alexa/Google'], '{"zones": 12, "wifi": true, "camera": "HD", "motion_detection": true, "night_vision": true, "weather_intelligence": true}', 'https://www.yardian.com'),
  ('YA-PRO-16', 'Yardian Pro 16-Zone', 'Pro', 16, 8, true,  250, ARRAY['Built-in HD camera','16-zone capacity','Large property','WiFi/app','Motion + security'], '{"zones": 16, "wifi": true, "camera": "HD", "motion_detection": true, "night_vision": true, "weather_intelligence": true}', 'https://www.yardian.com')
) AS v(model_number, model_name, series, cap, lifespan, estar, msrp, features, specs, url)
WHERE m.slug = 'yardian' AND c.slug = 'irrigation-controller';


-- ======================== FLUME (Smart Water Monitor) ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, NULL, NULL, true, v.lifespan, true, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('FLM-2-001', 'Flume 2 Smart Water Monitor',    'Flume 2', 'meter-clamp', 10, 199, ARRAY['Clamps onto water meter','Real-time usage tracking','Leak detection alerts','WiFi bridge included','No plumbing required'], '{"wifi": true, "leak_detection": true, "real_time": true, "install": "non-invasive", "battery_life_years": 2}', 'https://www.flumewater.com'),
  ('FLM-2-PRO', 'Flume 2 Pro Water Monitor',      'Flume 2 Pro', 'meter-clamp', 10, 299, ARRAY['Enhanced leak detection','Budget tracking','Irrigation insights','Usage goals','Extended WiFi range'], '{"wifi": true, "leak_detection": true, "real_time": true, "budget_tracking": true, "irrigation_insights": true}', 'https://www.flumewater.com')
) AS v(model_number, model_name, series, install, lifespan, msrp, features, specs, url)
WHERE m.slug = 'flume' AND c.slug = 'irrigation-controller';


-- ======================== ANTELCO (Micro-Irrigation) ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'drip', NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('SHRUB-360',  'Shrubbler 360 Adjustable',      'Shrubbler', 10, 'gph', 5, 3, ARRAY['360-degree adjustable','0-10 GPH','Barb or threaded connection','Individual plant watering'], '{"gph_range": "0-10", "pattern": "360", "type": "adjustable_emitter"}', 'https://www.antelco.com'),
  ('SHRUB-180',  'Shrubbler 180 Half Circle',      'Shrubbler', 10, 'gph', 5, 3, ARRAY['180-degree pattern','0-10 GPH','Half-circle coverage','Garden beds'], '{"gph_range": "0-10", "pattern": "180", "type": "adjustable_emitter"}', 'https://www.antelco.com'),
  ('RTRSP-360',  'Rotor Spray 360 Full Circle',    'Rotor Spray', 13, 'ft_radius', 5, 4, ARRAY['360-degree rotating spray','13 ft radius','Low precipitation rate','Even coverage'], '{"radius_ft": 13, "pattern": "360_rotating", "gph": 20, "type": "micro_rotor"}', 'https://www.antelco.com'),
  ('RTRSP-180',  'Rotor Spray 180 Half Circle',    'Rotor Spray', 13, 'ft_radius', 5, 4, ARRAY['180-degree rotating spray','13 ft radius','Garden beds and borders','Stake mount'], '{"radius_ft": 13, "pattern": "180_rotating", "gph": 10, "type": "micro_rotor"}', 'https://www.antelco.com'),
  ('CANE-25',    'Cane Emitter 360 2 GPH',          'Cane',        2,  'gph',       5, 2, ARRAY['360-degree drip emitter','2 GPH fixed flow','On riser cane','Container gardens'], '{"gph": 2, "pattern": "360", "type": "fixed_emitter"}', 'https://www.antelco.com')
) AS v(model_number, model_name, series, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'antelco' AND c.slug = 'sprinkler-head';


-- ======================== JAIN IRRIGATION (Sprinklers) ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'in-ground', NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('TC-2500',  'Turbo Cascade 2500 Pop-Up',    'Turbo Cascade', 25, 'ft_radius', 8, 12, ARRAY['Multi-stream rotary nozzle','Pop-up body','25 ft radius','Water efficient','Low precipitation rate'], '{"radius_ft": 25, "pattern": "multi_stream", "gpm": 0.8, "pop_up_height": 4}', 'https://www.jains.com'),
  ('TC-3500',  'Turbo Cascade 3500 Pop-Up',    'Turbo Cascade', 35, 'ft_radius', 8, 15, ARRAY['Multi-stream rotary','35 ft radius','Adjustable arc','Residential/commercial'], '{"radius_ft": 35, "pattern": "multi_stream", "gpm": 1.5, "pop_up_height": 4}', 'https://www.jains.com'),
  ('JT-2000',  'J-Turbo Rotary Nozzle',         'J-Turbo',       18, 'ft_radius', 8, 6,  ARRAY['Rotary nozzle retrofit','18 ft radius','Water saving','Fits standard spray bodies'], '{"radius_ft": 18, "pattern": "rotary", "gpm": 0.5, "type": "retrofit_nozzle"}', 'https://www.jains.com'),
  ('JT-3000',  'J-Turbo Long Range Nozzle',     'J-Turbo',       24, 'ft_radius', 8, 8,  ARRAY['Extended range rotary','24 ft radius','Uniform coverage','Matched precipitation'], '{"radius_ft": 24, "pattern": "rotary", "gpm": 0.9, "type": "retrofit_nozzle"}', 'https://www.jains.com')
) AS v(model_number, model_name, series, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'jain-irrigation' AND c.slug = 'sprinkler-head';


-- ======================== FEBCO (Backflow Preventers) ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'inline', NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('765-075',  '765 3/4" PVB',     '765', 0.75, 'inches', 20, 120, ARRAY['Pressure vacuum breaker','3/4-inch','ASSE 1020 certified','Most common residential','Freeze-resistant'], '{"size_inches": 0.75, "type": "pvb", "certification": "ASSE 1020", "max_psi": 150}', 'https://www.watts.com/brands/febco'),
  ('765-100',  '765 1" PVB',       '765', 1.0,  'inches', 20, 150, ARRAY['Pressure vacuum breaker','1-inch','ASSE 1020 certified','Residential/light commercial'], '{"size_inches": 1.0, "type": "pvb", "certification": "ASSE 1020", "max_psi": 150}', 'https://www.watts.com/brands/febco'),
  ('825Y-075', '825Y 3/4" RPZ',    '825Y', 0.75, 'inches', 25, 280, ARRAY['Reduced pressure zone','3/4-inch','ASSE 1013 certified','Highest protection','Required for chemical injection'], '{"size_inches": 0.75, "type": "rpz", "certification": "ASSE 1013", "max_psi": 175}', 'https://www.watts.com/brands/febco'),
  ('825Y-100', '825Y 1" RPZ',      '825Y', 1.0,  'inches', 25, 350, ARRAY['Reduced pressure zone','1-inch','ASSE 1013','Testable and repairable'], '{"size_inches": 1.0, "type": "rpz", "certification": "ASSE 1013", "max_psi": 175}', 'https://www.watts.com/brands/febco'),
  ('860-075',  '860 3/4" DCVA',    '860', 0.75, 'inches', 25, 180, ARRAY['Double check valve assembly','3/4-inch','ASSE 1015','Inline installation','Low pressure loss'], '{"size_inches": 0.75, "type": "dcva", "certification": "ASSE 1015", "max_psi": 175}', 'https://www.watts.com/brands/febco'),
  ('860-100',  '860 1" DCVA',      '860', 1.0,  'inches', 25, 220, ARRAY['Double check valve assembly','1-inch','ASSE 1015','Irrigation standard'], '{"size_inches": 1.0, "type": "dcva", "certification": "ASSE 1015", "max_psi": 175}', 'https://www.watts.com/brands/febco')
) AS v(model_number, model_name, series, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'febco' AND c.slug = 'backflow-preventer';


-- ======================== WILKINS (Backflow Preventers) ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'inline', NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('375-075',   '375 3/4" PVB',       '375',    0.75, 'inches', 20, 110, ARRAY['Pressure vacuum breaker','3/4-inch','ASSE 1020','Residential standard','Anti-siphon'], '{"size_inches": 0.75, "type": "pvb", "certification": "ASSE 1020", "max_psi": 150}', 'https://www.zurn.com/brands/wilkins'),
  ('375-100',   '375 1" PVB',         '375',    1.0,  'inches', 20, 140, ARRAY['Pressure vacuum breaker','1-inch','ASSE 1020','Residential/commercial'], '{"size_inches": 1.0, "type": "pvb", "certification": "ASSE 1020", "max_psi": 150}', 'https://www.zurn.com/brands/wilkins'),
  ('975XL-075', '975XL 3/4" RPZ',     '975XL',  0.75, 'inches', 25, 300, ARRAY['Reduced pressure zone','3/4-inch','ASSE 1013','Compact design','Top access for testing'], '{"size_inches": 0.75, "type": "rpz", "certification": "ASSE 1013", "max_psi": 175}', 'https://www.zurn.com/brands/wilkins'),
  ('975XL-100', '975XL 1" RPZ',       '975XL',  1.0,  'inches', 25, 380, ARRAY['Reduced pressure zone','1-inch','ASSE 1013','Field-serviceable'], '{"size_inches": 1.0, "type": "rpz", "certification": "ASSE 1013", "max_psi": 175}', 'https://www.zurn.com/brands/wilkins'),
  ('350-075',   '350 3/4" DCVA',      '350',    0.75, 'inches', 25, 160, ARRAY['Double check valve','3/4-inch','ASSE 1015','Bronze body','Low pressure drop'], '{"size_inches": 0.75, "type": "dcva", "certification": "ASSE 1015", "max_psi": 175}', 'https://www.zurn.com/brands/wilkins'),
  ('350-100',   '350 1" DCVA',        '350',    1.0,  'inches', 25, 200, ARRAY['Double check valve','1-inch','ASSE 1015','Bronze body','Irrigation systems'], '{"size_inches": 1.0, "type": "dcva", "certification": "ASSE 1015", "max_psi": 175}', 'https://www.zurn.com/brands/wilkins')
) AS v(model_number, model_name, series, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'wilkins' AND c.slug = 'backflow-preventer';


-- ======================== CHAMPION IRRIGATION (Sprinklers) ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, 'ft_radius', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('Z-7',     'Full Circle Impact Sprinkler',    'Impact',  45, 'hose-end',  5,  8,  ARRAY['Full circle brass impact','45 ft radius','Classic design','Sled base'], '{"radius_ft": 45, "pattern": "full_circle", "type": "impact", "material": "brass"}', 'https://www.championirr.com'),
  ('Z-8A',    'Part Circle Impact Sprinkler',    'Impact',  45, 'hose-end',  5,  10, ARRAY['Part circle brass impact','Adjustable arc','45 ft radius','Trip collar'], '{"radius_ft": 45, "pattern": "adjustable", "type": "impact", "material": "brass"}', 'https://www.championirr.com'),
  ('UPS-04',  '4-inch Pop-Up Spray Head',         'Pop-Up',  15, 'in-ground', 6,  3,  ARRAY['4-inch pop-up','15 ft radius','Nozzle included','Wiper seal'], '{"radius_ft": 15, "pop_up_height": 4, "inlet": "1/2 inch", "type": "pop_up_spray"}', 'https://www.championirr.com'),
  ('UPS-06',  '6-inch Pop-Up Spray Head',         'Pop-Up',  15, 'in-ground', 6,  4,  ARRAY['6-inch pop-up','For taller grass','15 ft radius','Spring retract'], '{"radius_ft": 15, "pop_up_height": 6, "inlet": "1/2 inch", "type": "pop_up_spray"}', 'https://www.championirr.com')
) AS v(model_number, model_name, series, cap, install, lifespan, msrp, features, specs, url)
WHERE m.slug = 'champion-irrigation' AND c.slug = 'sprinkler-head';


-- ############################################################################
-- BATHROOM FIXTURES
-- ############################################################################

-- ======================== PROJECT SOURCE (Budget Toilets & Faucets) ========================

-- Project Source Toilets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, v.estar, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('PRO-T001',  '2-Piece Round Toilet White',       'Pro',  'floor-mount', 1.28, 'gpf', 20, true,  89,  ARRAY['Round front','WaterSense','12-inch rough-in','Budget friendly'], '{"rough_in": 12, "flush_type": "gravity", "map_score": 500, "ada": false, "bowl_shape": "round"}', 'https://www.lowes.com'),
  ('PRO-T002',  '2-Piece Elongated Toilet White',   'Pro',  'floor-mount', 1.28, 'gpf', 20, true,  99,  ARRAY['Elongated bowl','WaterSense','Comfort height option','Budget'], '{"rough_in": 12, "flush_type": "gravity", "map_score": 550, "ada": false, "bowl_shape": "elongated"}', 'https://www.lowes.com'),
  ('PRO-T003',  'ADA Elongated Comfort Height',      'Pro',  'floor-mount', 1.28, 'gpf', 20, true,  109, ARRAY['ADA compliant','Elongated','Comfort height','WaterSense'], '{"rough_in": 12, "flush_type": "gravity", "map_score": 600, "ada": true, "bowl_shape": "elongated"}', 'https://www.lowes.com'),
  ('PRO-T004',  'Dual Flush 1-Piece Elongated',      'ProPlus', 'floor-mount', 1.1, 'gpf', 20, true, 139, ARRAY['One-piece','Dual flush 1.1/1.6 GPF','Slow-close seat','WaterSense'], '{"rough_in": 12, "flush_type": "dual_flush", "map_score": 600, "ada": true, "bowl_shape": "elongated"}', 'https://www.lowes.com')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, estar, msrp, features, specs, url)
WHERE m.slug = 'project-source' AND c.slug = 'toilet';

-- Project Source Faucets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('PS-F001',  'Single-Handle Chrome Faucet',       'Essential', 'deck-mount', 1.2, 'gpm', 8,  29, ARRAY['Single handle','Chrome','WaterSense','Ceramic disc valve'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.lowes.com'),
  ('PS-F002',  'Centerset Two-Handle Chrome',        'Essential', 'deck-mount', 1.2, 'gpm', 8,  35, ARRAY['4-inch centerset','Two handle','Chrome','Pop-up drain'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.lowes.com'),
  ('PS-F003',  'Centerset Single-Handle Brushed Nickel', 'Essentials', 'deck-mount', 1.2, 'gpm', 8, 39, ARRAY['Single handle','Brushed nickel','Pop-up drain','WaterSense'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "brushed_nickel"}', 'https://www.lowes.com'),
  ('PS-F004',  'Widespread Two-Handle Chrome',       'Classic', 'deck-mount', 1.2, 'gpm', 8,  49, ARRAY['Widespread 8-inch','Two handle','Chrome','Budget widespread option'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome", "spread": "8 inch"}', 'https://www.lowes.com')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'project-source' AND c.slug = 'bathroom-faucet';


-- ======================== GERBER (Toilets & Faucets) ========================

-- Gerber Toilets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'floor-mount', NULL, v.cap, 'gpf', true, v.lifespan, false, v.estar, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('21-014',   'Viper 1.28 GPF Elongated',       'Viper',      1.28, 25, true,  250, ARRAY['12-inch rough-in','Elongated bowl','WaterSense','1000g MaP score','Plumber favorite'], '{"rough_in": 12, "flush_type": "gravity", "map_score": 1000, "ada": false, "bowl_shape": "elongated"}', 'https://www.gerberonline.com'),
  ('21-019',   'Viper 1.28 GPF ADA Elongated',   'Viper',      1.28, 25, true,  280, ARRAY['ADA height','Elongated','WaterSense','1000g MaP','Comfort height'], '{"rough_in": 12, "flush_type": "gravity", "map_score": 1000, "ada": true, "bowl_shape": "elongated"}', 'https://www.gerberonline.com'),
  ('21-952',   'Avalanche 1.28 GPF Elongated',   'Avalanche',  1.28, 25, true,  320, ARRAY['EverClean surface','Elongated bowl','WaterSense','800g MaP','Premium glaze'], '{"rough_in": 12, "flush_type": "gravity", "map_score": 800, "ada": true, "bowl_shape": "elongated", "surface": "EverClean"}', 'https://www.gerberonline.com'),
  ('21-012',   'Maxwell 1.28 GPF Round',          'Maxwell',    1.28, 25, true,  180, ARRAY['Round front bowl','Budget-friendly','WaterSense','12-inch rough-in'], '{"rough_in": 12, "flush_type": "gravity", "map_score": 600, "ada": false, "bowl_shape": "round"}', 'https://www.gerberonline.com'),
  ('21-018',   'Maxwell 1.28 GPF Elongated',      'Maxwell',    1.28, 25, true,  200, ARRAY['Elongated bowl','WaterSense','Budget professional grade','12-inch rough-in'], '{"rough_in": 12, "flush_type": "gravity", "map_score": 600, "ada": false, "bowl_shape": "elongated"}', 'https://www.gerberonline.com'),
  ('21-117',   'Maxwell SE 1.6 GPF Elongated',    'Maxwell SE', 1.6,  25, false, 160, ARRAY['1.6 GPF standard flush','Builder grade','12-inch rough-in','Vitreous china'], '{"rough_in": 12, "flush_type": "gravity", "map_score": 500, "ada": false, "bowl_shape": "elongated"}', 'https://www.gerberonline.com')
) AS v(model_number, model_name, series, cap, lifespan, estar, msrp, features, specs, url)
WHERE m.slug = 'gerber' AND c.slug = 'toilet';

-- Gerber Faucets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'deck-mount', NULL, v.cap, 'gpm', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('D301130',  'Amalfi Single-Handle Faucet',   'Amalfi',  1.2, 12, 160, ARRAY['Single handle','Chrome','Touch-down drain','Ceramic disc cartridge'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.gerberonline.com'),
  ('D301230',  'Amalfi Single-Handle BN',        'Amalfi',  1.2, 12, 185, ARRAY['Single handle','Brushed nickel','Touch-down drain','WaterSense'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "brushed_nickel"}', 'https://www.gerberonline.com'),
  ('D303057',  'Parma Single-Handle Faucet',     'Parma',   1.2, 12, 200, ARRAY['Modern design','Single handle','Chrome','WaterSense'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.gerberonline.com'),
  ('D224530',  'South Shore Centerset',           'South Shore', 1.2, 12, 120, ARRAY['4-inch centerset','Two handle','Chrome','Drip-free ceramic disc'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.gerberonline.com')
) AS v(model_number, model_name, series, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'gerber' AND c.slug = 'bathroom-faucet';


-- ======================== VIGO (Vessel Faucets & Shower) ========================

-- Vigo Faucets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, 'gpm', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('VG03023CH',  'Niko Vessel Faucet Chrome',        'Niko',        'vessel-mount', 1.2, 15, 150, ARRAY['Single handle vessel faucet','7-layer chrome finish','Solid brass','WaterSense'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome", "mount": "vessel"}', 'https://www.vigoindustries.com'),
  ('VG03023BN',  'Niko Vessel Faucet Brushed Nickel', 'Niko',       'vessel-mount', 1.2, 15, 165, ARRAY['Vessel faucet','Brushed nickel','Solid brass body','Drip-free cartridge'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "brushed_nickel", "mount": "vessel"}', 'https://www.vigoindustries.com'),
  ('VG01030CH',  'Linus Single-Handle Faucet',        'Linus',      'deck-mount',   1.2, 15, 120, ARRAY['Single handle','Chrome','Brass body','WaterSense','Pop-up drain'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.vigoindustries.com'),
  ('VG01038MG',  'Davidson Vessel Faucet Matte Gold',  'Davidson',  'vessel-mount', 1.2, 15, 200, ARRAY['Matte brushed gold','Modern vessel design','Solid brass','WaterSense'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "matte_brushed_gold", "mount": "vessel"}', 'https://www.vigoindustries.com'),
  ('VG01028CH',  'Paloma Centerset Faucet',             'Paloma',    'deck-mount',   1.2, 15, 105, ARRAY['4-inch centerset','Chrome','Brass body','Pop-up drain included'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.vigoindustries.com')
) AS v(model_number, model_name, series, install, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'vigo' AND c.slug = 'bathroom-faucet';

-- Vigo Shower
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, 'gpm', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('VG6042CHCL60',  'Elan 60" Frameless Sliding Shower Door',   'Elan',    'wall-mount', NULL, 20, 850,  ARRAY['Frameless glass','60-inch sliding','3/8-inch tempered glass','Chrome hardware','RollerDisk technology'], '{"width_inches": 60, "glass_thickness": "3/8 inch", "type": "frameless_sliding"}', 'https://www.vigoindustries.com'),
  ('VG6051CHCL60',  'Winslow 60" Frameless Sliding Door',        'Winslow', 'wall-mount', NULL, 20, 950,  ARRAY['Frameless bypass sliding','60-inch opening','Clear glass','Stainless steel hardware'], '{"width_inches": 60, "glass_thickness": "3/8 inch", "type": "frameless_bypass"}', 'https://www.vigoindustries.com'),
  ('VG6012CHCL3662','Piedmont 36x62 Frameless Neo-Angle Shower', 'Piedmont','corner',     NULL, 20, 1100, ARRAY['Neo-angle design','Frameless glass','36x36 base','Chrome hardware'], '{"width_inches": 36, "glass_thickness": "3/8 inch", "type": "neo_angle_frameless"}', 'https://www.vigoindustries.com')
) AS v(model_number, model_name, series, install, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'vigo' AND c.slug = 'shower-system';


-- ======================== SIGNATURE HARDWARE ========================

-- Signature Hardware Toilets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, 'gpf', true, v.lifespan, false, true, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('948483', 'Bradenton 1-Piece Skirted Elongated', 'Bradenton', 'floor-mount', 1.28, 25, 450, ARRAY['One-piece skirted design','Elongated bowl','Slow-close seat','WaterSense'], '{"rough_in": 12, "flush_type": "gravity", "ada": true, "bowl_shape": "elongated", "skirted": true}', 'https://www.signaturehardware.com'),
  ('446030', 'Key West Dual Flush Elongated',       'Key West',  'floor-mount', 1.1,  25, 380, ARRAY['Dual flush 1.1/1.6 GPF','Elongated bowl','Comfort height','WaterSense'], '{"rough_in": 12, "flush_type": "dual_flush", "ada": true, "bowl_shape": "elongated"}', 'https://www.signaturehardware.com'),
  ('948759', 'Desoto Wall-Hung Toilet',             'Desoto',    'wall-hung',   1.28, 25, 520, ARRAY['Wall-hung concealed tank','Space-saving','Modern design','ADA'], '{"rough_in": "in-wall_carrier", "flush_type": "concealed_tank", "ada": true, "bowl_shape": "elongated", "wall_hung": true}', 'https://www.signaturehardware.com')
) AS v(model_number, model_name, series, install, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'signature-hardware' AND c.slug = 'toilet';

-- Signature Hardware Faucets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'deck-mount', NULL, 1.2, 'gpm', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('948421', 'Greyfield Widespread Faucet',  'Greyfield',  15, 250, ARRAY['Widespread','Cross handles','Pop-up drain','Multiple finishes available'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.signaturehardware.com'),
  ('449300', 'Lentz Widespread Faucet',      'Lentz',      15, 280, ARRAY['Widespread','Lever handles','Pop-up drain','WaterSense'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.signaturehardware.com'),
  ('926458', 'Vilamonte Bridge Faucet',      'Vilamonte',  15, 320, ARRAY['Bridge style','Cross handles','Vintage aesthetic','Solid brass'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "polished_nickel", "style": "bridge"}', 'https://www.signaturehardware.com'),
  ('948209', 'Hibiscus Single-Hole Faucet',  'Hibiscus',   15, 180, ARRAY['Single hole','Lever handle','Modern design','Pop-up drain'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.signaturehardware.com')
) AS v(model_number, model_name, series, lifespan, msrp, features, specs, url)
WHERE m.slug = 'signature-hardware' AND c.slug = 'bathroom-faucet';

-- Signature Hardware Bathtubs
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, 'gallons', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('948612', 'Henley Cast Iron Clawfoot Tub 66"',  'Henley',   'freestanding', 40, 25, 1600, ARRAY['Cast iron','Imperial claw feet','66-inch length','Porcelain enamel interior'], '{"gallons": 40, "length_inches": 66, "material": "cast_iron", "feet": "imperial_claw"}', 'https://www.signaturehardware.com'),
  ('447004', 'Wyndham Acrylic Freestanding Tub 67"', 'Wyndham', 'freestanding', 58, 25, 900, ARRAY['Acrylic freestanding','67-inch length','Modern oval design','Glossy white'], '{"gallons": 58, "length_inches": 67, "material": "acrylic", "shape": "oval"}', 'https://www.signaturehardware.com'),
  ('926901', 'Lena Pedestal Tub 60"',               'Lena',    'freestanding', 42, 25, 1200, ARRAY['Cast iron pedestal base','60-inch','Double-ended','Vintage style'], '{"gallons": 42, "length_inches": 60, "material": "cast_iron", "style": "pedestal"}', 'https://www.signaturehardware.com')
) AS v(model_number, model_name, series, install, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'signature-hardware' AND c.slug = 'bathtub';


-- ======================== VILLEROY & BOCH ========================

-- Villeroy & Boch Toilets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, 'gpf', true, v.lifespan, false, true, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('5614R201',   'Subway 2.0 Wall-Hung Toilet',       'Subway 2.0',     'wall-hung',   1.28, 25, 650,  ARRAY['Wall-hung','DirectFlush','CeramicPlus finish','Rimless design','European design'], '{"flush_type": "direct_flush", "wall_hung": true, "rimless": true, "surface": "CeramicPlus", "bowl_shape": "elongated"}', 'https://www.villeroy-boch.com'),
  ('4611R001',   'Architectura Wall-Hung Toilet',      'Architectura',   'wall-hung',   1.28, 25, 480,  ARRAY['Wall-hung','DirectFlush','Clean lines','AntiBac glaze'], '{"flush_type": "direct_flush", "wall_hung": true, "rimless": true, "surface": "AntiBac"}', 'https://www.villeroy-boch.com'),
  ('56811001',   'O.novo Floor-Standing Toilet',       'O.novo',         'floor-mount', 1.28, 25, 350,  ARRAY['Floor-standing','Close-coupled','WaterSense','Budget V&B'], '{"rough_in": 12, "flush_type": "gravity", "ada": true, "bowl_shape": "elongated"}', 'https://www.villeroy-boch.com'),
  ('5614R0R1',   'Subway 2.0 Comfort Height Wall-Hung', 'Subway 2.0',   'wall-hung',   1.28, 25, 720,  ARRAY['Wall-hung','Comfort height','DirectFlush','CeramicPlus','ADA'], '{"flush_type": "direct_flush", "wall_hung": true, "rimless": true, "ada": true, "surface": "CeramicPlus"}', 'https://www.villeroy-boch.com'),
  ('4611RS01',   'Architectura Slimseat',               'Architectura',  'wall-hung',   1.28, 25, 520,  ARRAY['Wall-hung with SlimSeat','Soft close','Quick release','DirectFlush'], '{"flush_type": "direct_flush", "wall_hung": true, "seat": "SlimSeat"}', 'https://www.villeroy-boch.com')
) AS v(model_number, model_name, series, install, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'villeroy-boch' AND c.slug = 'toilet';

-- Villeroy & Boch Bathtubs
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, 'gallons', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('UBQ177OBE7V',  'Oberon 2.0 66" Freestanding',   'Oberon 2.0',     'freestanding', 52, 25, 3200, ARRAY['Quaryl material','Freestanding oval','66-inch','Seamless design','Made in Germany'], '{"gallons": 52, "length_inches": 66, "material": "quaryl", "shape": "oval"}', 'https://www.villeroy-boch.com'),
  ('UBA180FIN7V',  'Finion 71" Freestanding',        'Finion',          'freestanding', 58, 25, 5800, ARRAY['Premium Quaryl','71-inch freestanding','Emotion LED lighting','Design Collection'], '{"gallons": 58, "length_inches": 71, "material": "quaryl", "led_lighting": true}', 'https://www.villeroy-boch.com'),
  ('UBA177SVB7V',  'Subway 3.0 Freestanding 67"',    'Subway 3.0',     'freestanding', 50, 25, 2800, ARRAY['Quaryl material','67-inch freestanding','Modern minimalist','AntiBac'], '{"gallons": 50, "length_inches": 67, "material": "quaryl", "shape": "oval"}', 'https://www.villeroy-boch.com'),
  ('UBA170ARC7V',  'Architectura 67" Freestanding',   'Architectura',  'freestanding', 48, 25, 1800, ARRAY['Acrylic freestanding','67-inch','Minimalist design','Budget V&B tub'], '{"gallons": 48, "length_inches": 67, "material": "acrylic", "shape": "oval"}', 'https://www.villeroy-boch.com')
) AS v(model_number, model_name, series, install, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'villeroy-boch' AND c.slug = 'bathtub';

-- Villeroy & Boch Faucets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'deck-mount', NULL, 1.2, 'gpm', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('TVW10610511161', 'Subway 3.0 Single-Lever Basin Mixer', 'Subway 3.0', 15, 280, ARRAY['Single lever','Chrome','CoolStart technology','SoftClose cartridge'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome", "coolstart": true}', 'https://www.villeroy-boch.com'),
  ('TVW10210011061', 'Architectura Single-Lever Mixer',      'Architectura', 15, 220, ARRAY['Single lever','Chrome','EcoSmart flow control','Pop-up drain'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.villeroy-boch.com'),
  ('TVW11210011061', 'O.novo Single-Lever Basin Mixer',      'O.novo',       15, 160, ARRAY['Budget V&B faucet','Single lever','Chrome','Ceramic cartridge'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.villeroy-boch.com')
) AS v(model_number, model_name, series, lifespan, msrp, features, specs, url)
WHERE m.slug = 'villeroy-boch' AND c.slug = 'bathroom-faucet';


-- ======================== KALLISTA (Ultra-Luxury Faucets & Shower) ========================

-- Kallista Faucets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, 1.2, 'gpm', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('P24480-00-CP', 'One Single-Control Faucet',          'One',    'deck-mount', 20, 1200, ARRAY['Minimalist design','Single control','Polished chrome','Hand-finished'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "polished_chrome", "style": "minimalist"}', 'https://www.kallista.com'),
  ('P24490-00-CP', 'Script Widespread Faucet',           'Script', 'deck-mount', 20, 1800, ARRAY['Widespread','Lever handles','Premium craftsmanship','Kohler luxury brand'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "polished_chrome", "spread": "8 inch"}', 'https://www.kallista.com'),
  ('P24600-LV-CP', 'Vir Stil Minimal Single Control',    'Vir Stil', 'deck-mount', 20, 1500, ARRAY['Ultra-minimal design','Joystick control','Polished chrome','Michael McCoy design'], '{"gpm": 1.2, "holes": 1, "valve_type": "joystick", "finish": "polished_chrome", "designer": "Michael McCoy"}', 'https://www.kallista.com'),
  ('P24030-WB-CP', 'One Wall-Mount Faucet',              'One',    'wall-mount',  20, 1600, ARRAY['Wall-mounted','Single control','Clean wall aesthetic','Concealed plumbing'], '{"gpm": 1.2, "holes": 0, "valve_type": "ceramic_disc", "finish": "polished_chrome", "mount": "wall"}', 'https://www.kallista.com'),
  ('P21210-00-CP', 'Script Single-Control Basin Faucet', 'Script', 'deck-mount', 20, 1100, ARRAY['Transitional design','Single hole','Lever handle','Premium finish'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "polished_chrome"}', 'https://www.kallista.com')
) AS v(model_number, model_name, series, install, lifespan, msrp, features, specs, url)
WHERE m.slug = 'kallista' AND c.slug = 'bathroom-faucet';

-- Kallista Shower Systems
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'wall-mount', NULL, v.cap, 'gpm', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('P24501-00-CP', 'One Showerhead 8" Round',     'One',    2.5, 20, 600,  ARRAY['8-inch round showerhead','Single function','Polished chrome','Katalyst spray technology'], '{"gpm": 2.5, "head_size": 8, "spray_functions": 1, "technology": "Katalyst"}', 'https://www.kallista.com'),
  ('P24550-00-CP', 'One Rain Showerhead 10"',      'One',    2.5, 20, 900,  ARRAY['10-inch rainfall','Ceiling mount option','Katalyst air-induction','Premium rain experience'], '{"gpm": 2.5, "head_size": 10, "spray_functions": 1, "technology": "Katalyst", "mount": "ceiling_or_wall"}', 'https://www.kallista.com'),
  ('P24700-LV-CP', 'Vir Stil Thermostatic Trim',  'Vir Stil', 2.5, 20, 1400, ARRAY['Thermostatic valve trim','Volume control','Minimal lever handles','Premium valve'], '{"gpm": 2.5, "valve_type": "thermostatic", "controls": 2}', 'https://www.kallista.com')
) AS v(model_number, model_name, series, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'kallista' AND c.slug = 'shower-system';


-- ======================== NEWPORT BRASS ========================

-- Newport Brass Faucets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'deck-mount', NULL, 1.2, 'gpm', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('1500-15',   'East Linear Widespread Faucet',       'East Linear', 15, 700,  ARRAY['Widespread','Lever handles','30+ finish options','Made in USA','Solid brass'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "polished_chrome", "made_in": "USA"}', 'https://www.newportbrass.com'),
  ('1500-15S',  'East Linear Single-Hole Faucet',      'East Linear', 15, 550,  ARRAY['Single hole','Lever handle','30+ finishes','American made'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "polished_chrome"}', 'https://www.newportbrass.com'),
  ('1200-15',   'Metropole Widespread Faucet',          'Metropole',   15, 650,  ARRAY['Widespread','Cross handles','Traditional design','30+ finishes'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "polished_chrome", "handle_type": "cross"}', 'https://www.newportbrass.com'),
  ('2540-15',   'Sutton Widespread Faucet',             'Sutton',      15, 750,  ARRAY['Widespread','Lever handles','Transitional style','Solid brass'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "polished_chrome"}', 'https://www.newportbrass.com'),
  ('3100-15',   'Pavani Widespread Faucet',             'Pavani',      15, 800,  ARRAY['Widespread','Modern minimalist','Square handles','Premium finish'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "polished_chrome", "style": "modern"}', 'https://www.newportbrass.com'),
  ('1400-15',   'Parisa Wall-Mount Lavatory Faucet',    'Parisa',      15, 900,  ARRAY['Wall mounted','Cross handles','Traditional','30+ finishes','Brass body'], '{"gpm": 1.2, "holes": 0, "valve_type": "ceramic_disc", "mount": "wall", "handle_type": "cross"}', 'https://www.newportbrass.com')
) AS v(model_number, model_name, series, lifespan, msrp, features, specs, url)
WHERE m.slug = 'newport-brass' AND c.slug = 'bathroom-faucet';

-- Newport Brass Shower Systems
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'wall-mount', NULL, v.cap, 'gpm', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('3-1504BP',  'East Linear Pressure Balance Shower', 'East Linear', 2.5, 15, 600,  ARRAY['Pressure balance valve','Lever handle','Showerhead + arm','30+ finishes'], '{"gpm": 2.5, "valve_type": "pressure_balance", "components": ["valve", "showerhead", "arm"]}', 'https://www.newportbrass.com'),
  ('3-2574BP',  'Sutton Thermostatic Shower System',   'Sutton',      2.5, 15, 1200, ARRAY['Thermostatic with volume','Lever handles','Rain showerhead','Body sprays available'], '{"gpm": 2.5, "valve_type": "thermostatic", "controls": 2}', 'https://www.newportbrass.com'),
  ('3-3104BP',  'Pavani Rain Shower System',            'Pavani',     2.5, 15, 1500, ARRAY['Thermostatic rain system','Square rain head','Hand shower','Modern design'], '{"gpm": 2.5, "valve_type": "thermostatic", "rain_head": true, "hand_shower": true}', 'https://www.newportbrass.com')
) AS v(model_number, model_name, series, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'newport-brass' AND c.slug = 'shower-system';


-- ======================== DXV (Luxury Toilets & Faucets) ========================

-- DXV Toilets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, 'gpf', true, v.lifespan, false, true, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('D22015A100.415', 'Percy 1-Piece Elongated',     'Percy',    'floor-mount', 1.28, 25, 800,  ARRAY['One-piece','Elongated','Comfort height','Slow-close seat','AquaSentry flush system'], '{"rough_in": 12, "flush_type": "siphon", "map_score": 1000, "ada": true, "bowl_shape": "elongated"}', 'https://www.dxv.com'),
  ('D22005C100.415', 'Belshire 2-Piece Elongated',  'Belshire', 'floor-mount', 1.28, 25, 650,  ARRAY['Two-piece','Traditional design','WaterSense','12-inch rough-in'], '{"rough_in": 12, "flush_type": "gravity", "ada": true, "bowl_shape": "elongated"}', 'https://www.dxv.com'),
  ('D29030C100.415', 'Randall 1-Piece Elongated',   'Randall',  'floor-mount', 1.28, 25, 900,  ARRAY['One-piece','Skirted trapway','AquaSentry flush','Comfort height','Premium design'], '{"rough_in": 12, "flush_type": "siphon", "ada": true, "bowl_shape": "elongated", "skirted": true}', 'https://www.dxv.com'),
  ('D22020A100.415', 'Percy Wall-Hung Toilet',       'Percy',   'wall-hung',   1.28, 25, 750,  ARRAY['Wall-hung','Clean design','Space-saving','Concealed tank required'], '{"flush_type": "concealed_tank", "wall_hung": true, "ada": true, "bowl_shape": "elongated"}', 'https://www.dxv.com')
) AS v(model_number, model_name, series, install, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'dxv' AND c.slug = 'toilet';

-- DXV Faucets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'deck-mount', NULL, 1.2, 'gpm', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('D35101840.100', 'Percy Widespread Faucet Chrome',    'Percy',    15, 550, ARRAY['Widespread','Cross handles','Pop-up drain','Traditional luxury'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "polished_chrome", "handle_type": "cross"}', 'https://www.dxv.com'),
  ('D35155840.100', 'Belshire Widespread Faucet',        'Belshire', 15, 600, ARRAY['Widespread','Lever handles','Classic American design','Premium finish'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "polished_chrome"}', 'https://www.dxv.com'),
  ('D35160840.100', 'Randall Widespread Faucet',         'Randall',  15, 650, ARRAY['Widespread','Cross handles','Art Deco inspired','Multiple finishes'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "polished_chrome", "style": "art_deco"}', 'https://www.dxv.com'),
  ('D35170100.100', 'Vibrato 3D-Printed Faucet',        'Vibrato',  15, 18000, ARRAY['3D printed metal','Single hole','One-of-a-kind design','Laser-sintered','Limited production'], '{"gpm": 1.2, "holes": 1, "manufacturing": "3D_printed_metal", "finish": "polished_chrome"}', 'https://www.dxv.com'),
  ('D35101102.100', 'Percy Single-Hole Faucet',          'Percy',   15, 400, ARRAY['Single hole','Cross handle','Traditional design','Pop-up drain'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "polished_chrome"}', 'https://www.dxv.com')
) AS v(model_number, model_name, series, lifespan, msrp, features, specs, url)
WHERE m.slug = 'dxv' AND c.slug = 'bathroom-faucet';


-- ======================== WATERMARK (Ultra-Luxury Faucets & Shower) ========================

-- Watermark Faucets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, 1.2, 'gpm', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('31-1.15-PC',  'Brooklyn Single-Hole Faucet',       'Brooklyn',   'deck-mount', 20, 650,  ARRAY['Industrial design','Lever handle','65+ finishes','Brooklyn-made','Solid brass'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "polished_chrome", "finishes_available": 65}', 'https://www.watermark-designs.com'),
  ('31-2-PC',     'Brooklyn Widespread Faucet',         'Brooklyn',   'deck-mount', 20, 1100, ARRAY['Widespread','Industrial lever handles','65+ finishes','Handmade in Brooklyn'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "polished_chrome"}', 'https://www.watermark-designs.com'),
  ('37-1.15-PC',  'Loft Single-Hole Faucet',            'Loft',      'deck-mount', 20, 700,  ARRAY['Modern minimalist','Single lever','65+ finishes','Clean lines'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "polished_chrome"}', 'https://www.watermark-designs.com'),
  ('37-2-PC',     'Loft Widespread Faucet',              'Loft',      'deck-mount', 20, 1200, ARRAY['Widespread','Lever handles','Minimalist design','65+ finishes'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "polished_chrome"}', 'https://www.watermark-designs.com'),
  ('38-1.15-PC',  'Elements Single-Hole Faucet',        'Elements',  'deck-mount', 20, 600,  ARRAY['Joystick control','Single hole','Compact design','65+ finishes'], '{"gpm": 1.2, "holes": 1, "valve_type": "joystick", "finish": "polished_chrome"}', 'https://www.watermark-designs.com'),
  ('31-1.2WM-PC', 'Brooklyn Wall-Mount Faucet',         'Brooklyn',  'wall-mount', 20, 1400, ARRAY['Wall mounted','Industrial style','Concealed plumbing','65+ finishes'], '{"gpm": 1.2, "holes": 0, "valve_type": "ceramic_disc", "mount": "wall"}', 'https://www.watermark-designs.com')
) AS v(model_number, model_name, series, install, lifespan, msrp, features, specs, url)
WHERE m.slug = 'watermark' AND c.slug = 'bathroom-faucet';

-- Watermark Shower Systems
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'wall-mount', NULL, v.cap, 'gpm', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('31-7.1?"',   'Brooklyn Thermostatic Shower Set',  'Brooklyn', 2.5, 20, 2200, ARRAY['Thermostatic valve','Rain showerhead','Hand shower','Industrial style','65+ finishes'], '{"gpm": 2.5, "valve_type": "thermostatic", "rain_head": true, "hand_shower": true}', 'https://www.watermark-designs.com'),
  ('37-7.1?"',   'Loft Thermostatic Shower Set',      'Loft',     2.5, 20, 2400, ARRAY['Thermostatic valve','Square rain head','Minimalist design','Hand shower included'], '{"gpm": 2.5, "valve_type": "thermostatic", "rain_head": true, "hand_shower": true, "style": "minimalist"}', 'https://www.watermark-designs.com'),
  ('38-7.1?"',   'Elements Pressure Balance Shower',   'Elements', 2.5, 20, 1600, ARRAY['Pressure balance valve','Rain showerhead','Compact design','65+ finishes'], '{"gpm": 2.5, "valve_type": "pressure_balance", "rain_head": true}', 'https://www.watermark-designs.com')
) AS v(model_number, model_name, series, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'watermark' AND c.slug = 'shower-system';


-- ======================== FRANZ VIEGENER (Ultra-Luxury Faucets) ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'deck-mount', NULL, 1.2, 'gpm', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('FV182.01',  'Edge Single-Hole Faucet',          'Edge',      20, 850,  ARRAY['Angular design','Single lever','Solid brass','Argentine craftsmanship'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "polished_chrome"}', 'https://www.franzviegener.com'),
  ('FV182.02',  'Edge Widespread Faucet',            'Edge',      20, 1400, ARRAY['Widespread','Angular lever handles','Solid brass','Premium finish options'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "polished_chrome"}', 'https://www.franzviegener.com'),
  ('FV181.01',  'Lollipop Single-Hole Faucet',       'Lollipop', 20, 900,  ARRAY['Round handle design','Single hole mount','Playful aesthetic','Multiple finishes'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "polished_chrome", "style": "playful"}', 'https://www.franzviegener.com'),
  ('FV181.02',  'Lollipop Widespread Faucet',         'Lollipop', 20, 1500, ARRAY['Widespread','Round knob handles','Whimsical design','Solid brass'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "polished_chrome"}', 'https://www.franzviegener.com'),
  ('FV100.01',  'Smooth Lines Single-Hole Faucet',    'Smooth Lines', 20, 750, ARRAY['Organic curved design','Single lever','Flowing lines','Artisan crafted'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "polished_chrome", "style": "organic"}', 'https://www.franzviegener.com')
) AS v(model_number, model_name, series, lifespan, msrp, features, specs, url)
WHERE m.slug = 'franz-viegener' AND c.slug = 'bathroom-faucet';


-- ############################################################################
-- POOL SYSTEMS
-- ############################################################################

-- ======================== GULFSTREAM (Pool Heat Pumps) ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'in-ground', NULL, v.cap, 'btu', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('HE110RA',   'HE110 110K BTU Heat Pump',   'HE', 110000, 12, 3200, ARRAY['110K BTU heat pump','Titanium heat exchanger','Scroll compressor','R-410A refrigerant','Digital controls'], '{"btu": 110000, "type": "heat_pump", "cop": 5.8, "voltage": 230, "pool_size_max_gallons": 25000, "exchanger": "titanium"}', 'https://www.gulfstreamheatpumps.com'),
  ('HE125RA',   'HE125 125K BTU Heat Pump',   'HE', 125000, 12, 3800, ARRAY['125K BTU heat pump','Titanium exchanger','Quiet operation','Scroll compressor','Digital display'], '{"btu": 125000, "type": "heat_pump", "cop": 6.0, "voltage": 230, "pool_size_max_gallons": 30000, "exchanger": "titanium"}', 'https://www.gulfstreamheatpumps.com'),
  ('HE150RA',   'HE150 140K BTU Heat Pump',   'HE', 140000, 12, 4200, ARRAY['140K BTU heat pump','Titanium heat exchanger','Large pool capacity','Low noise design'], '{"btu": 140000, "type": "heat_pump", "cop": 6.2, "voltage": 230, "pool_size_max_gallons": 40000, "exchanger": "titanium"}', 'https://www.gulfstreamheatpumps.com'),
  ('HE90RA',    'HE90 90K BTU Heat Pump',     'HE', 90000,  12, 2800, ARRAY['90K BTU heat pump','Titanium exchanger','Compact design','Ideal for smaller pools'], '{"btu": 90000, "type": "heat_pump", "cop": 5.5, "voltage": 230, "pool_size_max_gallons": 20000, "exchanger": "titanium"}', 'https://www.gulfstreamheatpumps.com')
) AS v(model_number, model_name, series, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'gulfstream' AND c.slug = 'pool-heater';


-- ======================== COATES (Electric Pool Heaters) ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'in-ground', NULL, v.cap, 'kw', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('12411ST',  '11 kW Electric Pool Heater',  'ST', 11, 10, 1800, ARRAY['11 kW electric','Titanium elements','No gas line needed','Digital thermostat','Compact design'], '{"kw": 11, "voltage": 240, "amps": 46, "btu_equivalent": 37500, "element_material": "titanium"}', 'https://www.coatesheaters.com'),
  ('12415ST',  '15 kW Electric Pool Heater',  'ST', 15, 10, 2200, ARRAY['15 kW electric','Titanium elements','Digital thermostat','Flow switch safety','?"No gas required'], '{"kw": 15, "voltage": 240, "amps": 62.5, "btu_equivalent": 51200, "element_material": "titanium"}', 'https://www.coatesheaters.com'),
  ('12418ST',  '18 kW Electric Pool Heater',  'ST', 18, 10, 2600, ARRAY['18 kW electric','Titanium elements','Digital thermostat','Flow switch','Stainless steel housing'], '{"kw": 18, "voltage": 240, "amps": 75, "btu_equivalent": 61400, "element_material": "titanium"}', 'https://www.coatesheaters.com'),
  ('12424ST',  '24 kW Electric Pool Heater',  'ST', 24, 10, 3200, ARRAY['24 kW electric','Titanium elements','Large pool capacity','Digital controls','Stainless housing'], '{"kw": 24, "voltage": 240, "amps": 100, "btu_equivalent": 81900, "element_material": "titanium"}', 'https://www.coatesheaters.com'),
  ('12436ST',  '36 kW Electric Pool Heater',  'ST', 36, 10, 4500, ARRAY['36 kW electric','Titanium elements','Commercial grade','Dual element banks','3-phase option'], '{"kw": 36, "voltage": 240, "amps": 150, "btu_equivalent": 122900, "element_material": "titanium"}', 'https://www.coatesheaters.com'),
  ('12457ST',  '57 kW Electric Pool Heater',  'ST', 57, 10, 6200, ARRAY['57 kW electric','Commercial/large residential','Titanium elements','3-phase power','Rapid heating'], '{"kw": 57, "voltage": 480, "amps": 69, "btu_equivalent": 194500, "element_material": "titanium", "phase": 3}', 'https://www.coatesheaters.com')
) AS v(model_number, model_name, series, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'coates' AND c.slug = 'pool-heater';


-- ======================== AQUABOT (Robotic Pool Cleaners) ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'in-ground', NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('ABBRZ-XLS', 'Breeze XLS Robotic Cleaner',    'Breeze',  40, 'ft_length', 4, false, 600,  ARRAY['Floor and cove cleaning','Easy clean filter','Lightweight design','Budget robotic option'], '{"pool_length_max_ft": 40, "cable_length_ft": 50, "cleaning": ["floor", "cove"], "filter_type": "easy_clean", "cycle_hours": 2}', 'https://www.aquabot.com'),
  ('ABRAPIDXLS', 'Rapids XLS Robotic Cleaner',    'Rapids',  40, 'ft_length', 4, false, 800,  ARRAY['Floor + wall + waterline cleaning','Dual brush system','Large filter basket','Smart steering'], '{"pool_length_max_ft": 40, "cable_length_ft": 55, "cleaning": ["floor", "wall", "waterline"], "filter_type": "basket", "cycle_hours": 2.5}', 'https://www.aquabot.com'),
  ('ABX4-XLS',   'X4 Robotic Cleaner',            'X4',      60, 'ft_length', 5, true,  1400, ARRAY['Premium robotic cleaner','App control','Gyroscope navigation','60 ft pool capacity','Ultra-fine filtration'], '{"pool_length_max_ft": 60, "cable_length_ft": 70, "cleaning": ["floor", "wall", "waterline"], "filter_type": "ultra_fine", "cycle_hours": 3, "app_control": true}', 'https://www.aquabot.com'),
  ('ABPRM-XLS',  'Prime Robotic Cleaner',          'Prime',  50, 'ft_length', 5, false, 1000, ARRAY['Quad-brush system','Floor + wall cleaning','Large debris capacity','50 ft pools'], '{"pool_length_max_ft": 50, "cable_length_ft": 60, "cleaning": ["floor", "wall"], "filter_type": "basket", "cycle_hours": 2.5}', 'https://www.aquabot.com')
) AS v(model_number, model_name, series, cap, cap_unit, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'aquabot' AND c.slug = 'pool-cleaner';


-- ======================== BESTWAY (Above-Ground Pool Equipment) ========================

-- Bestway Pumps
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'above-ground', NULL, v.cap, 'gph', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('58390E',  'Flowclear 1500 GPH Filter Pump',   'Flowclear', 1500, 5, 80,  ARRAY['1500 GPH pump','Above-ground pools','Easy setup','Includes filter cartridge'], '{"gph": 1500, "voltage": 110, "pool_size_max_gallons": 8000, "type": "cartridge_pump"}', 'https://www.bestway.com'),
  ('58392E',  'Flowclear 2500 GPH Filter Pump',   'Flowclear', 2500, 5, 120, ARRAY['2500 GPH pump','Above-ground pools','Type III filter','Easy maintenance'], '{"gph": 2500, "voltage": 110, "pool_size_max_gallons": 15000, "type": "cartridge_pump"}', 'https://www.bestway.com'),
  ('58498E',  'Flowclear Sand Filter Pump 1500',   'Flowclear', 1500, 6, 180, ARRAY['Sand filter pump combo','1500 GPH','Above-ground pools','6-way valve'], '{"gph": 1500, "voltage": 110, "pool_size_max_gallons": 10000, "type": "sand_filter_pump", "valve": "6-way"}', 'https://www.bestway.com')
) AS v(model_number, model_name, series, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'bestway' AND c.slug = 'pool-pump';

-- Bestway Filters
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'above-ground', NULL, v.cap, 'gph', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('58499E',  'Flowclear Sand Filter 2200 GPH',   'Flowclear', 2200, 6, 220, ARRAY['Sand filter system','2200 GPH','Above-ground pools','Pressure gauge','6-way valve'], '{"gph": 2200, "filter_type": "sand", "sand_lbs": 40, "pool_size_max_gallons": 15000}', 'https://www.bestway.com'),
  ('58503E',  'Flowclear Sand Filter 3000 GPH',   'Flowclear', 3000, 6, 280, ARRAY['Sand filter system','3000 GPH','Large above-ground','Timer included'], '{"gph": 3000, "filter_type": "sand", "sand_lbs": 55, "pool_size_max_gallons": 20000}', 'https://www.bestway.com')
) AS v(model_number, model_name, series, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'bestway' AND c.slug = 'pool-filter';


-- ======================== WATERWAY PLASTICS (Pool Pumps) ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'in-ground', NULL, v.cap, 'hp', true, v.lifespan, false, v.estar, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DERA-CH-100', 'Champion 1 HP Single Speed',     'Champion', 1.0, 8, false, 450,  ARRAY['1 HP single speed','56-frame motor','Self-priming','Budget in-ground pump'], '{"hp": 1.0, "flow_gpm": 80, "voltage": 115, "variable_speed": false, "pool_size_max_gallons": 20000}', 'https://www.waterway.com'),
  ('DERA-CH-150', 'Champion 1.5 HP Single Speed',   'Champion', 1.5, 8, false, 520,  ARRAY['1.5 HP single speed','56-frame motor','Self-priming','Cast iron impeller'], '{"hp": 1.5, "flow_gpm": 100, "voltage": 230, "variable_speed": false, "pool_size_max_gallons": 25000}', 'https://www.waterway.com'),
  ('DERA-EX-200', 'Executive 2 HP Single Speed',    'Executive', 2.0, 8, false, 650, ARRAY['2 HP single speed','48-frame motor','High performance','Self-priming'], '{"hp": 2.0, "flow_gpm": 120, "voltage": 230, "variable_speed": false, "pool_size_max_gallons": 30000}', 'https://www.waterway.com'),
  ('DERA-EX-300', 'Executive 3 HP Single Speed',    'Executive', 3.0, 8, false, 780, ARRAY['3 HP single speed','56-frame motor','Commercial capacity','Heavy duty'], '{"hp": 3.0, "flow_gpm": 140, "voltage": 230, "variable_speed": false, "pool_size_max_gallons": 40000}', 'https://www.waterway.com'),
  ('DERA-EX-VS',  'Executive VS Variable Speed 3HP', 'Executive VS', 3.0, 10, true, 1400, ARRAY['Variable speed','3 HP','Energy Star certified','Digital keypad','8 speed settings'], '{"hp": 3.0, "flow_gpm": 140, "voltage": 230, "variable_speed": true, "speed_settings": 8, "pool_size_max_gallons": 40000}', 'https://www.waterway.com')
) AS v(model_number, model_name, series, cap, lifespan, estar, msrp, features, specs, url)
WHERE m.slug = 'waterway-plastics' AND c.slug = 'pool-pump';


-- ======================== HARRIS POOL (Budget Pumps & Filters) ========================

-- Harris Pool Pumps
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'in-ground', NULL, v.cap, 'hp', true, v.lifespan, false, v.estar, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('H1572730',    'ProForce 1.5 HP In-Ground Pump',   'ProForce', 1.5, 8, false, 350, ARRAY['1.5 HP in-ground pump','Self-priming','Budget-friendly','Amazon best-seller','Hayward replacement'], '{"hp": 1.5, "flow_gpm": 90, "voltage": 115, "variable_speed": false, "pool_size_max_gallons": 22000}', 'https://www.harrispoolproducts.com'),
  ('H1572728',    'ProForce 1 HP In-Ground Pump',     'ProForce', 1.0, 8, false, 280, ARRAY['1 HP in-ground pump','Self-priming','Budget option','Easy install'], '{"hp": 1.0, "flow_gpm": 70, "voltage": 115, "variable_speed": false, "pool_size_max_gallons": 18000}', 'https://www.harrispoolproducts.com'),
  ('H1572732',    'ProForce 2 HP In-Ground Pump',     'ProForce', 2.0, 8, false, 420, ARRAY['2 HP in-ground pump','Self-priming','Heavy duty','Large pool capacity'], '{"hp": 2.0, "flow_gpm": 110, "voltage": 230, "variable_speed": false, "pool_size_max_gallons": 30000}', 'https://www.harrispoolproducts.com'),
  ('H1572734VS',  'ProForce 1.5 HP Variable Speed',   'ProForce VS', 1.5, 10, true, 750, ARRAY['Variable speed','1.5 HP','Energy Star','Digital control','Budget VS option'], '{"hp": 1.5, "flow_gpm": 90, "voltage": 230, "variable_speed": true, "speed_settings": 4, "pool_size_max_gallons": 22000}', 'https://www.harrispoolproducts.com')
) AS v(model_number, model_name, series, cap, lifespan, estar, msrp, features, specs, url)
WHERE m.slug = 'harris-pool' AND c.slug = 'pool-pump';

-- Harris Pool Filters
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'in-ground', NULL, v.cap, 'sq_ft', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('73052-6030', 'ProGrid 60 sq ft DE Filter',        'ProGrid',    60,  7, 600, ARRAY['60 sq ft DE filtration','Hayward replacement','Budget DE option','Easy grid cleaning'], '{"sq_ft": 60, "flow_rate_gpm": 120, "filter_type": "de", "pool_size_max_gallons": 30000}', 'https://www.harrispoolproducts.com'),
  ('73052-4810', 'ProGrid 48 sq ft DE Filter',        'ProGrid',    48,  7, 500, ARRAY['48 sq ft DE filtration','Budget option','Easy maintenance','Clamp-on design'], '{"sq_ft": 48, "flow_rate_gpm": 96, "filter_type": "de", "pool_size_max_gallons": 24000}', 'https://www.harrispoolproducts.com'),
  ('72100',      'Sand Filter System 100 lb',          'Sand Master', 100, 8, 350, ARRAY['100 lb sand capacity','6-way top-mount valve','Budget sand filter','Easy backwash'], '{"sand_lbs": 100, "flow_rate_gpm": 60, "filter_type": "sand", "pool_size_max_gallons": 20000}', 'https://www.harrispoolproducts.com')
) AS v(model_number, model_name, series, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'harris-pool' AND c.slug = 'pool-filter';


-- ======================== LOOP-LOC (Safety Covers) ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'in-ground', NULL, NULL, NULL, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('LL-MESH-STD', 'Super Dense Mesh Safety Cover',    'Super Dense Mesh', 15, 2500, ARRAY['Mesh safety cover','Blocks 99% of sunlight','Custom measured','Spring and anchor system','Made on Long Island'], '{"type": "mesh_safety_cover", "light_block_pct": 99, "custom_fit": true, "warranty_years": 15}', 'https://www.looploc.com'),
  ('LL-SOLID-STD', 'Solid Safety Cover',               'Solid',           15, 3200, ARRAY['Solid vinyl safety cover','Blocks all debris','Auto drain panel','Custom measured','Prevents algae'], '{"type": "solid_safety_cover", "light_block_pct": 100, "auto_drain": true, "custom_fit": true, "warranty_years": 15}', 'https://www.looploc.com'),
  ('LL-ULTRALOC',  'Ultra-Loc Solid Safety Cover',     'Ultra-Loc',       15, 3800, ARRAY['Premium solid cover','Lightweight design','Custom fit','Superior strength','Child safety rated'], '{"type": "solid_safety_cover", "light_block_pct": 100, "lightweight": true, "custom_fit": true}', 'https://www.looploc.com'),
  ('LL-BABY-LOC',  'Baby-Loc Removable Pool Fence',    'Baby-Loc',        10, 1800, ARRAY['Removable pool fence','Self-closing gate','ASTM F1346 compliant','Mesh panels','Drill-in anchors'], '{"type": "removable_fence", "height_inches": 48, "self_closing_gate": true, "compliance": "ASTM F1346"}', 'https://www.looploc.com')
) AS v(model_number, model_name, series, lifespan, msrp, features, specs, url)
WHERE m.slug = 'loop-loc' AND c.slug = 'pool-automation';


-- ======================== S.R. SMITH (Pool Deck Equipment) ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'in-ground', NULL, NULL, NULL, true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('68-209-7362',  'Frontier III 8ft Diving Board',     'Frontier III',   NULL,     15, false, 650,  ARRAY['8-foot diving board','Radiant white','Salt pool compatible','UV resistant','250 lb capacity'], '{"type": "diving_board", "length_ft": 8, "weight_capacity_lbs": 250, "material": "fiberglass"}', 'https://www.srsmith.com'),
  ('68-209-5962',  'Frontier III 6ft Diving Board',     'Frontier III',   NULL,     15, false, 550,  ARRAY['6-foot diving board','Radiant white','Salt compatible','UV stabilized'], '{"type": "diving_board", "length_ft": 6, "weight_capacity_lbs": 250, "material": "fiberglass"}', 'https://www.srsmith.com'),
  ('VLLS-60E-VDB', 'Veo Pool Slide',                    'Veo',            NULL,     15, false, 1800, ARRAY['Right curve pool slide','Enclosed flume','Ladder steps','Gray granite finish'], '{"type": "pool_slide", "height_ft": 5, "curve": "right", "material": "rotomolded"}', 'https://www.srsmith.com'),
  ('FSBRD-24',     'Flyte-Deck II Stand with Board',    'Flyte-Deck II',  NULL,     15, false, 1200, ARRAY['24-inch stand','8-foot board combo','Stainless steel frame','Rust resistant'], '{"type": "diving_board_stand", "height_inches": 24, "board_length_ft": 8, "material": "stainless_steel"}', 'https://www.srsmith.com'),
  ('FLED-C-TR-30', 'Treo LED Pool Light Color',         'Treo',           'electric', 10, false, 250, ARRAY['Color LED pool light','No niche required','Micro-size','Cord length 30ft','5 color modes'], '{"type": "led_pool_light", "color_modes": 5, "cord_length_ft": 30, "voltage": 12, "watts": 5}', 'https://www.srsmith.com'),
  ('FLED-TM-RGB',  'PoolLUX Premier LED Light',         'PoolLUX',        'electric', 10, true,  450, ARRAY['WiFi LED pool light','Color changing','App control','100ft cord','Niche mount'], '{"type": "led_pool_light", "color_modes": 16, "cord_length_ft": 100, "voltage": 12, "wifi": true, "watts": 40}', 'https://www.srsmith.com')
) AS v(model_number, model_name, series, fuel, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'sr-smith' AND c.slug = 'pool-automation';


-- ======================== PARAMOUNT (In-Floor Cleaning) ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'in-ground', NULL, NULL, NULL, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('004-552-5020-01', 'PCC2000 In-Floor Cleaning System',  'PCC2000', 15, 4500, ARRAY['In-floor cleaning','Pop-up heads','Zone valve system','No visible equipment','Continuous cleaning'], '{"type": "in_floor_cleaning", "zones": 6, "heads_per_zone": 4, "cleaning": "pop_up_rotating"}', 'https://www.paramount.com'),
  ('004-552-3500-01', 'PV3 In-Floor Cleaning Head',        'PV3',     15, 3200, ARRAY['Next-gen pop-up head','360 degree rotation','Wider cleaning arc','Debris collection'], '{"type": "in_floor_head", "rotation": 360, "pop_up": true, "generation": "PV3"}', 'https://www.paramount.com'),
  ('004-627-5060-01', 'Vanquish In-Floor Retrofit Kit',    'Vanquish', 12, 2800, ARRAY['Retrofit in-floor system','For existing pools','Pop-up cleaning heads','Zone control'], '{"type": "in_floor_retrofit", "retrofit": true, "zones": 4}', 'https://www.paramount.com'),
  ('004-762-3032-01', 'SDX2 High Flow Drain',              'SDX2',    20, 180,  ARRAY['High flow safety drain','Anti-entrapment','VGB compliant','2 covers per drain'], '{"type": "safety_drain", "vgb_compliant": true, "flow_gpm": 316}', 'https://www.paramount.com')
) AS v(model_number, model_name, series, lifespan, msrp, features, specs, url)
WHERE m.slug = 'paramount' AND c.slug = 'pool-cleaner';


-- ======================== WATERCO (Pumps, Filters, Salt Chlorinators) ========================

-- Waterco Pumps
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'in-ground', NULL, v.cap, 'hp', true, v.lifespan, false, v.estar, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('HS150',    'Hydrostorm Plus 1.5 HP',           'Hydrostorm Plus', 1.5, 8, false, 480,  ARRAY['1.5 HP single speed','Self-priming','Corrosion resistant','Australian quality'], '{"hp": 1.5, "flow_gpm": 95, "voltage": 230, "variable_speed": false}', 'https://www.waterco.com'),
  ('HS200',    'Hydrostorm Plus 2 HP',             'Hydrostorm Plus', 2.0, 8, false, 580,  ARRAY['2 HP single speed','Self-priming','Large strainer basket','Heavy duty'], '{"hp": 2.0, "flow_gpm": 115, "voltage": 230, "variable_speed": false}', 'https://www.waterco.com'),
  ('HSECO150', 'Hydrostorm ECO-V 1.5 HP VS',      'Hydrostorm ECO-V', 1.5, 10, true, 1200, ARRAY['Variable speed','1.5 HP','Energy efficient','Digital display','Low noise'], '{"hp": 1.5, "flow_gpm": 95, "voltage": 230, "variable_speed": true, "speed_settings": 8}', 'https://www.waterco.com'),
  ('HSECO200', 'Hydrostorm ECO-V 2 HP VS',        'Hydrostorm ECO-V', 2.0, 10, true, 1400, ARRAY['Variable speed','2 HP','Energy Star','Digital keypad','Quiet operation'], '{"hp": 2.0, "flow_gpm": 115, "voltage": 230, "variable_speed": true, "speed_settings": 8}', 'https://www.waterco.com')
) AS v(model_number, model_name, series, cap, lifespan, estar, msrp, features, specs, url)
WHERE m.slug = 'waterco' AND c.slug = 'pool-pump';

-- Waterco Filters
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'in-ground', NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('MC16',      'MultiCyclone 16 Pre-Filter',        'MultiCyclone', 16, 'cyclones', 15, 450, ARRAY['16-cyclone centrifugal pre-filter','No filter media','Reduces backwash by 80%','Extends filter life'], '{"cyclones": 16, "type": "centrifugal_prefilter", "flow_rate_gpm": 60, "backwash_reduction_pct": 80}', 'https://www.waterco.com'),
  ('MC12',      'MultiCyclone 12 Pre-Filter',        'MultiCyclone', 12, 'cyclones', 15, 380, ARRAY['12-cyclone pre-filter','No consumables','Reduces backwash','Compact design'], '{"cyclones": 12, "type": "centrifugal_prefilter", "flow_rate_gpm": 45, "backwash_reduction_pct": 80}', 'https://www.waterco.com'),
  ('WC300',     'Micron S300 Sand Filter',            'Micron',      300, 'lbs_sand', 10, 550, ARRAY['300 lb sand capacity','Top mount 6-way valve','Fiberglass tank','Residential standard'], '{"sand_lbs": 300, "filter_type": "sand", "flow_rate_gpm": 75, "tank_diameter": 24}', 'https://www.waterco.com'),
  ('WCC200',    'Trimline C200 Cartridge Filter',     'Trimline',    200, 'sq_ft',    8,  420, ARRAY['200 sq ft cartridge','Easy cartridge access','Corrosion resistant','Budget cartridge option'], '{"sq_ft": 200, "filter_type": "cartridge", "flow_rate_gpm": 80, "pool_size_max_gallons": 20000}', 'https://www.waterco.com')
) AS v(model_number, model_name, series, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'waterco' AND c.slug = 'pool-filter';

-- Waterco Salt Chlorine Generators
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'in-ground', NULL, v.cap, 'gallons', true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('EC25',   'Electrochlor 25K Gallon',   'Electrochlor', 25000, 5, 900,  ARRAY['25K gallon capacity','Self-cleaning cell','Digital display','Low salt indicator','Australian technology'], '{"pool_max_gallons": 25000, "cell_type": "self_cleaning", "salt_ppm": 3500, "chlorine_output_grams_hr": 18}', 'https://www.waterco.com'),
  ('EC40',   'Electrochlor 40K Gallon',   'Electrochlor', 40000, 5, 1200, ARRAY['40K gallon capacity','Self-cleaning cell','Digital display','Flow sensor','Boost mode'], '{"pool_max_gallons": 40000, "cell_type": "self_cleaning", "salt_ppm": 3500, "chlorine_output_grams_hr": 28}', 'https://www.waterco.com'),
  ('EC60',   'Electrochlor MK3 60K Gallon', 'Electrochlor MK3', 60000, 5, 1600, ARRAY['60K gallon capacity','MK3 technology','Self-cleaning','pH dosing compatible','Commercial grade'], '{"pool_max_gallons": 60000, "cell_type": "self_cleaning", "salt_ppm": 3500, "chlorine_output_grams_hr": 42, "generation": "MK3"}', 'https://www.waterco.com')
) AS v(model_number, model_name, series, cap, lifespan, msrp, features, specs, url)
WHERE m.slug = 'waterco' AND c.slug = 'salt-chlorine-generator';
