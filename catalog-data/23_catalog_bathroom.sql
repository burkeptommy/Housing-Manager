SET ROLE postgres;
-- ============================================================================
-- Equipment Catalog: Bathroom Fixtures
-- Brands: Glacier Bay, Peerless, Sterling, Moen, Delta, American Standard,
--         Pfister, Symmons, Kraus, Kohler, TOTO, Hansgrohe, Grohe, Jacuzzi,
--         Brizo, Duravit, Waterworks, Dornbracht, Victoria + Albert
-- Categories: toilet, bathroom-faucet, shower-system, bathtub, bidet
-- Target: 350+ models
-- ============================================================================

-- ============================================================================
-- BUDGET TIER
-- ============================================================================

-- ======================== GLACIER BAY ========================

-- Glacier Bay Toilets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, v.estar, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('N2316', '2-Piece Round Toilet', 'Power Flush', 'floor-mount', 1.28, 'gpf', 20, true, 129, ARRAY['Round front','Power Flush','WaterSense'], '{"rough_in": 12, "flush_type": "gravity", "map_score": 600, "ada": false, "bowl_shape": "round"}', 'https://www.homedepot.com/p/Glacier-Bay-2-Piece-Round-Toilet/'),
  ('N2428E', '2-Piece Elongated Toilet', 'Power Flush', 'floor-mount', 1.28, 'gpf', 20, true, 139, ARRAY['Elongated bowl','Power Flush','WaterSense'], '{"rough_in": 12, "flush_type": "gravity", "map_score": 650, "ada": false, "bowl_shape": "elongated"}', 'https://www.homedepot.com/p/Glacier-Bay-Elongated-Toilet/'),
  ('N2450E', 'Comfort Height Elongated Toilet', 'Comfort Height', 'floor-mount', 1.28, 'gpf', 20, true, 159, ARRAY['Comfort height','Elongated','WaterSense','ADA'], '{"rough_in": 12, "flush_type": "gravity", "map_score": 700, "ada": true, "bowl_shape": "elongated"}', 'https://www.homedepot.com/p/Glacier-Bay-Comfort-Height/'),
  ('N2420', '1-Piece Elongated Dual Flush Toilet', 'Dual Flush', 'floor-mount', 1.1, 'gpf', 20, true, 189, ARRAY['One-piece','Dual flush 1.1/1.6','Elongated','Slow-close seat'], '{"rough_in": 12, "flush_type": "dual_flush", "map_score": 700, "ada": true, "bowl_shape": "elongated"}', 'https://www.homedepot.com/p/Glacier-Bay-Dual-Flush/')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, estar, msrp, features, specs, url)
WHERE m.slug = 'glacier-bay' AND c.slug = 'toilet';

-- Glacier Bay Bathroom Faucets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('HD67091W-6301', 'Builders Single-Handle Faucet', 'Builders', 'deck-mount', 1.2, 'gpm', 10, 39, ARRAY['Single handle','Chrome','WaterSense'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.homedepot.com/p/Glacier-Bay-Builders-Faucet/'),
  ('HD67092W-6301', 'Builders 4-Inch Centerset Faucet', 'Builders', 'deck-mount', 1.2, 'gpm', 10, 49, ARRAY['Centerset','Two handle','Chrome'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.homedepot.com/p/Glacier-Bay-Centerset/'),
  ('HD67137-0001', 'Oswell 4-Inch Centerset Faucet', 'Oswell', 'deck-mount', 1.2, 'gpm', 10, 69, ARRAY['Centerset','Matte black','Pop-up drain'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "matte_black"}', 'https://www.homedepot.com/p/Glacier-Bay-Oswell/')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'glacier-bay' AND c.slug = 'bathroom-faucet';

-- Glacier Bay Bathtubs
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('BA1956L-60', '60" Alcove Bathtub Left Drain', 'Classic', 'alcove', 42, 'gallons', 20, 199, ARRAY['60" x 30"','Left drain','Acrylic','White'], '{"gallons": 42, "length_inches": 60, "material": "acrylic", "drain_location": "left"}', 'https://www.homedepot.com/p/Glacier-Bay-Alcove-Tub/'),
  ('BA1956R-60', '60" Alcove Bathtub Right Drain', 'Classic', 'alcove', 42, 'gallons', 20, 199, ARRAY['60" x 30"','Right drain','Acrylic','White'], '{"gallons": 42, "length_inches": 60, "material": "acrylic", "drain_location": "right"}', 'https://www.homedepot.com/p/Glacier-Bay-Alcove-Tub-Right/')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'glacier-bay' AND c.slug = 'bathtub';

-- Glacier Bay Shower Systems
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('3070-501-CH', 'Aragon Single-Handle Shower Faucet', 'Aragon', 'wall-mount', 2.5, 'gpm', 15, 65, ARRAY['Single handle','Chrome','Pressure balance'], '{"gpm": 2.5, "spray_settings": 1, "valve_type": "pressure_balance"}', 'https://www.homedepot.com/p/Glacier-Bay-Aragon-Shower/'),
  ('833CX-0001', 'Modern 1-Handle Tub and Shower Faucet', 'Modern', 'wall-mount', 2.5, 'gpm', 15, 85, ARRAY['Tub and shower','Chrome','WaterSense'], '{"gpm": 2.5, "spray_settings": 1, "valve_type": "pressure_balance"}', 'https://www.homedepot.com/p/Glacier-Bay-Modern-Shower/')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'glacier-bay' AND c.slug = 'shower-system';

-- ======================== PEERLESS FAUCET ========================

-- Peerless Bathroom Faucets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('P136LF', 'Core Single-Handle Centerset Faucet', 'Core', 'deck-mount', 1.2, 'gpm', 10, 35, ARRAY['Single handle','Chrome','WaterSense'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.peerlessfaucet.com/bathroom/bathroom-faucets/P136LF'),
  ('P299628LF', 'Apex Two-Handle Centerset Faucet', 'Apex', 'deck-mount', 1.2, 'gpm', 10, 52, ARRAY['Two handle','Centerset','Chrome','Pop-up drain'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.peerlessfaucet.com/bathroom/bathroom-faucets/P299628LF'),
  ('P188627LF-BN', 'Tunbridge Widespread Faucet', 'Tunbridge', 'deck-mount', 1.2, 'gpm', 10, 89, ARRAY['Widespread','Two handle','Brushed nickel'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "brushed_nickel"}', 'https://www.peerlessfaucet.com/bathroom/bathroom-faucets/P188627LF-BN'),
  ('P191102LF', 'Westchester Single-Handle Faucet', 'Westchester', 'deck-mount', 1.2, 'gpm', 10, 59, ARRAY['Single handle','Chrome','Drain assembly included'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.peerlessfaucet.com/bathroom/bathroom-faucets/P191102LF')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'peerless-faucet' AND c.slug = 'bathroom-faucet';

-- Peerless Shower Systems
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('PTT188750', 'Tub and Shower Trim Kit', 'Classic', 'wall-mount', 2.5, 'gpm', 15, 45, ARRAY['Single handle','Tub and shower','Chrome'], '{"gpm": 2.5, "spray_settings": 1, "valve_type": "pressure_balance"}', 'https://www.peerlessfaucet.com/shower/PTT188750'),
  ('P18437', 'Complete Shower System', 'Choice', 'wall-mount', 2.0, 'gpm', 15, 75, ARRAY['Single handle','Shower only','WaterSense'], '{"gpm": 2.0, "spray_settings": 3, "valve_type": "pressure_balance"}', 'https://www.peerlessfaucet.com/shower/P18437')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'peerless-faucet' AND c.slug = 'shower-system';

-- ======================== STERLING ========================

-- Sterling Bathtubs
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('71041120-0', 'Performa 60" Alcove Bathtub', 'Performa', 'alcove', 40, 'gallons', 25, 219, ARRAY['60" x 29"','Left drain','Vikrell material','White'], '{"gallons": 40, "length_inches": 60, "material": "vikrell", "drain_location": "left"}', 'https://www.sterlingplumbing.com/bathing/bathtubs/71041120-0'),
  ('71041110-0', 'Performa 60" Bathtub Right Drain', 'Performa', 'alcove', 40, 'gallons', 25, 219, ARRAY['60" x 29"','Right drain','Vikrell material'], '{"gallons": 40, "length_inches": 60, "material": "vikrell", "drain_location": "right"}', 'https://www.sterlingplumbing.com/bathing/bathtubs/71041110-0'),
  ('71171110-0', 'Ensemble 60" x 32" Bathtub', 'Ensemble', 'alcove', 44, 'gallons', 25, 289, ARRAY['60" x 32"','Slip-resistant floor','Vikrell'], '{"gallons": 44, "length_inches": 60, "material": "vikrell", "drain_location": "right"}', 'https://www.sterlingplumbing.com/bathing/bathtubs/71171110-0')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'sterling' AND c.slug = 'bathtub';

-- Sterling Shower Systems
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('72280106-0', 'Accord 36" Shower', 'Accord', 'alcove', 2.5, 'gpm', 20, 449, ARRAY['36" x 36"','Vikrell','Complete enclosure'], '{"gpm": 2.5, "spray_settings": 1, "valve_type": "pressure_balance"}', 'https://www.sterlingplumbing.com/showering/shower-stalls/72280106-0'),
  ('71320110-0', 'Ensemble Shower Kit', 'Ensemble', 'alcove', 2.5, 'gpm', 20, 549, ARRAY['60" x 32"','Complete shower kit','White'], '{"gpm": 2.5, "spray_settings": 1, "valve_type": "pressure_balance"}', 'https://www.sterlingplumbing.com/showering/71320110-0')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'sterling' AND c.slug = 'shower-system';

-- Sterling Toilets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, v.estar, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('402015-0', 'Windham Elongated Toilet', 'Windham', 'floor-mount', 1.28, 'gpf', 20, true, 179, ARRAY['Elongated','ProForce flushing','WaterSense'], '{"rough_in": 12, "flush_type": "gravity", "map_score": 600, "ada": false, "bowl_shape": "elongated"}', 'https://www.sterlingplumbing.com/toilets/402015-0'),
  ('402024-0', 'Windham ADA Elongated Toilet', 'Windham', 'floor-mount', 1.28, 'gpf', 20, true, 199, ARRAY['ADA compliant','Elongated','ProForce','Comfort height'], '{"rough_in": 12, "flush_type": "gravity", "map_score": 650, "ada": true, "bowl_shape": "elongated"}', 'https://www.sterlingplumbing.com/toilets/402024-0')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, estar, msrp, features, specs, url)
WHERE m.slug = 'sterling' AND c.slug = 'toilet';


-- ============================================================================
-- MAINSTREAM TIER
-- ============================================================================

-- ======================== MOEN ========================

-- Moen Bathroom Faucets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('6410', 'Eva Single-Handle Centerset Faucet', 'Eva', 'deck-mount', 1.2, 'gpm', 15, 145, ARRAY['Single handle','Chrome','WaterSense','1222 cartridge'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome", "cartridge": "1222"}', 'https://www.moen.com/products/Eva/6410'),
  ('6903', 'Voss Single-Handle Faucet', 'Voss', 'deck-mount', 1.2, 'gpm', 15, 199, ARRAY['Single handle','High arc','WaterSense'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome", "cartridge": "1222"}', 'https://www.moen.com/products/Voss/6903'),
  ('T6620', 'Brantford Two-Handle Widespread Faucet', 'Brantford', 'deck-mount', 1.2, 'gpm', 15, 275, ARRAY['Widespread','Two handle','Traditional style','WaterSense'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome", "cartridge": "1224"}', 'https://www.moen.com/products/Brantford/T6620'),
  ('6192', 'Align Single-Handle Faucet', 'Align', 'deck-mount', 1.2, 'gpm', 15, 219, ARRAY['Modern design','Single handle','Chrome','WaterSense'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome", "cartridge": "1222"}', 'https://www.moen.com/products/Align/6192'),
  ('S6700', 'Glyde Single-Handle Faucet', 'Glyde', 'deck-mount', 1.2, 'gpm', 15, 169, ARRAY['Transitional design','Single handle','WaterSense'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome", "cartridge": "1222"}', 'https://www.moen.com/products/Glyde/S6700'),
  ('T6905', 'Doux Single-Handle Wall Mount Faucet', 'Doux', 'wall-mount', 1.2, 'gpm', 15, 355, ARRAY['Wall mount','Modern','WaterSense','Chrome'], '{"gpm": 1.2, "holes": 0, "valve_type": "ceramic_disc", "finish": "chrome", "cartridge": "1222"}', 'https://www.moen.com/products/Doux/T6905'),
  ('6172', 'Hensley Centerset Faucet', 'Hensley', 'deck-mount', 1.2, 'gpm', 15, 129, ARRAY['Centerset','Chrome','Spot Resist','WaterSense'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome", "cartridge": "1224"}', 'https://www.moen.com/products/Hensley/6172')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'moen' AND c.slug = 'bathroom-faucet';

-- Moen Shower Systems
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('T2152', 'Brantford Posi-Temp Shower Trim', 'Brantford', 'wall-mount', 2.5, 'gpm', 20, false, 169, ARRAY['Single handle','Posi-Temp valve','WaterSense'], '{"gpm": 2.5, "spray_settings": 1, "valve_type": "pressure_balance", "rough_in_valve": "2520"}', 'https://www.moen.com/products/Brantford/T2152'),
  ('S6320', 'Velocity Two-Function Rainshower', 'Velocity', 'wall-mount', 2.5, 'gpm', 20, false, 289, ARRAY['8" rainshower','2 spray functions','Chrome'], '{"gpm": 2.5, "spray_settings": 2, "valve_type": "pressure_balance", "head_diameter": 8}', 'https://www.moen.com/products/Velocity/S6320'),
  ('U260', 'M-CORE Transfer Valve Trim', 'M-CORE', 'wall-mount', 2.5, 'gpm', 20, false, 399, ARRAY['Transfer valve','Shared function','Multiple outlets'], '{"gpm": 2.5, "spray_settings": 4, "valve_type": "thermostatic", "outlets": 2}', 'https://www.moen.com/products/M-CORE/U260'),
  ('S176', 'Quattro 4-Spray Handheld Showerhead', 'Quattro', 'wall-mount', 1.75, 'gpm', 20, false, 59, ARRAY['4 spray settings','Handheld','WaterSense'], '{"gpm": 1.75, "spray_settings": 4, "valve_type": "pressure_balance"}', 'https://www.moen.com/products/Quattro/S176'),
  ('TS3302', 'Align M-CORE 3-Series Shower', 'Align', 'wall-mount', 2.5, 'gpm', 20, false, 245, ARRAY['3-Series valve','Single handle','Modern'], '{"gpm": 2.5, "spray_settings": 1, "valve_type": "pressure_balance", "rough_in_valve": "2570"}', 'https://www.moen.com/products/Align/TS3302'),
  ('U by Moen S3104', 'U by Moen Smart Shower', 'U by Moen', 'wall-mount', 2.5, 'gpm', 20, true, 1150, ARRAY['Wi-Fi enabled','Voice control','App control','Preset temperatures'], '{"gpm": 2.5, "spray_settings": 2, "valve_type": "digital_thermostatic", "smart": true}', 'https://www.moen.com/products/U-by-Moen/S3104')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'moen' AND c.slug = 'shower-system';

-- Moen Toilets (Moen entered toilet market recently)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, true, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('MT301', 'Tilson 2-Piece Elongated Toilet', 'Tilson', 'floor-mount', 1.28, 'gpf', 25, 249, ARRAY['Elongated','Comfort height','WaterSense','Slow-close seat'], '{"rough_in": 12, "flush_type": "gravity", "map_score": 800, "ada": true, "bowl_shape": "elongated"}', 'https://www.moen.com/products/Tilson/MT301'),
  ('MT801', 'Kai 1-Piece Elongated Toilet', 'Kai', 'floor-mount', 1.28, 'gpf', 25, 399, ARRAY['One-piece','Skirted design','Slow-close seat','WaterSense'], '{"rough_in": 12, "flush_type": "gravity", "map_score": 900, "ada": true, "bowl_shape": "elongated"}', 'https://www.moen.com/products/Kai/MT801')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'moen' AND c.slug = 'toilet';

-- ======================== DELTA FAUCET ========================

-- Delta Bathroom Faucets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('2538-MPU-DST', 'Lahara Two-Handle Centerset Faucet', 'Lahara', 'deck-mount', 1.2, 'gpm', 15, 169, ARRAY['Centerset','Two handle','Diamond Seal','WaterSense'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome", "cartridge": "RP46074"}', 'https://www.deltafaucet.com/bathroom/2538-MPU-DST'),
  ('559LF-MPU', 'Trinsic Single-Handle Faucet', 'Trinsic', 'deck-mount', 1.2, 'gpm', 15, 245, ARRAY['Single handle','Modern','Diamond Seal','WaterSense'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome", "cartridge": "RP50587"}', 'https://www.deltafaucet.com/bathroom/559LF-MPU'),
  ('3559-MPU-DST', 'Trinsic Widespread Faucet', 'Trinsic', 'deck-mount', 1.2, 'gpm', 15, 365, ARRAY['Widespread','Two handle','Modern design','Diamond Seal'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome", "cartridge": "RP50587"}', 'https://www.deltafaucet.com/bathroom/3559-MPU-DST'),
  ('564-MPU-DST', 'Ashlyn Single-Handle Faucet', 'Ashlyn', 'deck-mount', 1.2, 'gpm', 15, 209, ARRAY['Single handle','Chrome','Diamond Seal','WaterSense'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome", "cartridge": "RP50587"}', 'https://www.deltafaucet.com/bathroom/564-MPU-DST'),
  ('551LF-SS', 'Dryden Single-Handle Faucet', 'Dryden', 'deck-mount', 1.2, 'gpm', 15, 269, ARRAY['Single handle','Stainless','Traditional style'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "stainless", "cartridge": "RP50587"}', 'https://www.deltafaucet.com/bathroom/551LF-SS'),
  ('T3551LF-WL', 'Dryden Wall Mount Faucet', 'Dryden', 'wall-mount', 1.2, 'gpm', 15, 525, ARRAY['Wall mount','Traditional','Chrome','WaterSense'], '{"gpm": 1.2, "holes": 0, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.deltafaucet.com/bathroom/T3551LF-WL'),
  ('15999LF', 'Haywood Two-Handle Centerset Faucet', 'Haywood', 'deck-mount', 1.2, 'gpm', 15, 79, ARRAY['Centerset','Budget-friendly','Chrome'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.deltafaucet.com/bathroom/15999LF'),
  ('757T-DST', 'Stryke Single-Handle Vessel Faucet', 'Stryke', 'deck-mount', 1.2, 'gpm', 15, 375, ARRAY['Vessel faucet','Single handle','Tall spout','H2Okinetic'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.deltafaucet.com/bathroom/757T-DST')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'delta-faucet' AND c.slug = 'bathroom-faucet';

-- Delta Shower Systems
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('T14238', 'Lahara Monitor 14 Shower Trim', 'Lahara', 'wall-mount', 2.5, 'gpm', 20, 135, ARRAY['Monitor pressure balance','Single handle','Chrome'], '{"gpm": 2.5, "spray_settings": 1, "valve_type": "pressure_balance", "rough_in_valve": "R10000"}', 'https://www.deltafaucet.com/shower/T14238'),
  ('T17264-SS', 'Ashlyn Monitor 17 Shower Trim', 'Ashlyn', 'wall-mount', 2.5, 'gpm', 20, 215, ARRAY['Monitor 17 valve','Stainless','H2Okinetic'], '{"gpm": 2.5, "spray_settings": 3, "valve_type": "pressure_balance", "rough_in_valve": "R10000"}', 'https://www.deltafaucet.com/shower/T17264-SS'),
  ('58471-25-PK', 'In2ition 5-Setting 2-in-1 Showerhead', 'In2ition', 'wall-mount', 2.5, 'gpm', 20, 89, ARRAY['2-in-1 design','5 spray settings','Detachable hand shower'], '{"gpm": 2.5, "spray_settings": 5, "valve_type": "pressure_balance"}', 'https://www.deltafaucet.com/shower/58471-25-PK'),
  ('T17459', 'Trinsic 17 Series Shower Trim', 'Trinsic', 'wall-mount', 2.5, 'gpm', 20, 249, ARRAY['Monitor 17','Modern design','H2Okinetic','Chrome'], '{"gpm": 2.5, "spray_settings": 1, "valve_type": "pressure_balance", "rough_in_valve": "R10000"}', 'https://www.deltafaucet.com/shower/T17459'),
  ('75588', 'Universal 8" Rain Showerhead', 'Universal', 'wall-mount', 2.5, 'gpm', 20, 69, ARRAY['8" rain shower','Full body spray','Chrome'], '{"gpm": 2.5, "spray_settings": 1, "head_diameter": 8}', 'https://www.deltafaucet.com/shower/75588')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'delta-faucet' AND c.slug = 'shower-system';

-- Delta Toilets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, true, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('C43901-WH', 'Foundations 2-Piece Elongated Toilet', 'Foundations', 'floor-mount', 1.28, 'gpf', 25, 179, ARRAY['Elongated','WaterSense','Slow-close seat'], '{"rough_in": 12, "flush_type": "gravity", "map_score": 800, "ada": false, "bowl_shape": "elongated"}', 'https://www.deltafaucet.com/toilet/C43901-WH'),
  ('C41913-WH', 'Corrente Elongated Toilet', 'Corrente', 'floor-mount', 1.28, 'gpf', 25, 249, ARRAY['Chair height','Elongated','Slow-close seat'], '{"rough_in": 12, "flush_type": "gravity", "map_score": 900, "ada": true, "bowl_shape": "elongated"}', 'https://www.deltafaucet.com/toilet/C41913-WH')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'delta-faucet' AND c.slug = 'toilet';

-- ======================== AMERICAN STANDARD ========================

-- American Standard Toilets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, true, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('2034314.020', 'Champion 4 Elongated Toilet', 'Champion', 'floor-mount', 1.6, 'gpf', 25, false, 399, ARRAY['Champion 4 flush','Elongated','EverClean','Right height'], '{"rough_in": 12, "flush_type": "gravity", "map_score": 1000, "ada": true, "bowl_shape": "elongated"}', 'https://www.americanstandard.com/bathrooms/toilets/2034314.020'),
  ('2889218.020', 'H2Option Dual Flush Elongated Toilet', 'H2Option', 'floor-mount', 1.0, 'gpf', 25, false, 329, ARRAY['Dual flush 1.0/1.6','Elongated','WaterSense'], '{"rough_in": 12, "flush_type": "dual_flush", "map_score": 800, "ada": true, "bowl_shape": "elongated"}', 'https://www.americanstandard.com/bathrooms/toilets/2889218.020'),
  ('2403128.020', 'Cadet 3 FloWise Elongated Toilet', 'Cadet 3', 'floor-mount', 1.28, 'gpf', 25, false, 249, ARRAY['Cadet 3 flushing','10" rough-in option','Elongated'], '{"rough_in": 12, "flush_type": "gravity", "map_score": 800, "ada": false, "bowl_shape": "elongated"}', 'https://www.americanstandard.com/bathrooms/toilets/2403128.020'),
  ('2988101.020', 'Cadet PRO Round Front Toilet', 'Cadet PRO', 'floor-mount', 1.28, 'gpf', 25, false, 199, ARRAY['Right height','Round front','PowerWash rim'], '{"rough_in": 12, "flush_type": "gravity", "map_score": 700, "ada": true, "bowl_shape": "round"}', 'https://www.americanstandard.com/bathrooms/toilets/2988101.020'),
  ('297CA104.020', 'ActiClean Self-Cleaning Elongated Toilet', 'ActiClean', 'floor-mount', 1.28, 'gpf', 25, false, 649, ARRAY['Self-cleaning','VorMax flush','ActiClean cartridge','EverClean'], '{"rough_in": 12, "flush_type": "vormax", "map_score": 1000, "ada": true, "bowl_shape": "elongated"}', 'https://www.americanstandard.com/bathrooms/toilets/297CA104.020'),
  ('2765014.020', 'VorMax Plus Self-Cleaning Toilet', 'VorMax', 'floor-mount', 1.28, 'gpf', 25, false, 549, ARRAY['VorMax flushing','Self-cleaning','EverClean surface'], '{"rough_in": 12, "flush_type": "vormax", "map_score": 1000, "ada": true, "bowl_shape": "elongated"}', 'https://www.americanstandard.com/bathrooms/toilets/2765014.020'),
  ('2989813.020', 'Toilevator 1-Piece Elongated Toilet', 'Studio S', 'floor-mount', 1.28, 'gpf', 25, false, 749, ARRAY['One-piece','Low profile','Skirted design','Soft close'], '{"rough_in": 12, "flush_type": "gravity", "map_score": 900, "ada": true, "bowl_shape": "elongated"}', 'https://www.americanstandard.com/bathrooms/toilets/2989813.020'),
  ('2548A100.020', 'Studio S Wall-Hung Elongated Toilet', 'Studio S', 'wall-hung', 1.28, 'gpf', 25, false, 599, ARRAY['Wall-hung','Space saving','Elongated','EverClean'], '{"rough_in": 0, "flush_type": "gravity", "map_score": 800, "ada": true, "bowl_shape": "elongated", "wall_hung": true}', 'https://www.americanstandard.com/bathrooms/toilets/2548A100.020'),
  ('8075A100.020', 'Advanced Clean 100 SpaLet Bidet Toilet', 'SpaLet', 'floor-mount', 1.32, 'gpf', 25, true, 1899, ARRAY['Integrated bidet','Heated seat','Warm water wash','Night light','Deodorizer'], '{"rough_in": 12, "flush_type": "siphon", "map_score": 800, "ada": true, "bowl_shape": "elongated", "bidet": true}', 'https://www.americanstandard.com/bathrooms/toilets/8075A100.020')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'american-standard' AND c.slug = 'toilet';

-- American Standard Bathroom Faucets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('7018201.002', 'Studio S Single-Handle Faucet', 'Studio S', 'deck-mount', 1.2, 'gpm', 15, 349, ARRAY['Single handle','Chrome','WaterSense','Speed Connect drain'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.americanstandard.com/bathrooms/faucets/7018201.002'),
  ('7431201.002', 'Boulevard Widespread Faucet', 'Boulevard', 'deck-mount', 1.2, 'gpm', 15, 399, ARRAY['Widespread','Two handle','WaterSense','Speed Connect'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.americanstandard.com/bathrooms/faucets/7431201.002'),
  ('7061807.002', 'Aspirations Single-Handle Faucet', 'Aspirations', 'deck-mount', 1.2, 'gpm', 15, 289, ARRAY['Single handle','Lever','Chrome','WaterSense'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.americanstandard.com/bathrooms/faucets/7061807.002'),
  ('7075200.002', 'Colony PRO Centerset Faucet', 'Colony PRO', 'deck-mount', 1.2, 'gpm', 15, 99, ARRAY['Centerset','Metal lever','Chrome','WaterSense'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.americanstandard.com/bathrooms/faucets/7075200.002'),
  ('T353501.002', 'Townsend Wall-Mount Faucet', 'Townsend', 'wall-mount', 1.2, 'gpm', 15, 429, ARRAY['Wall mount','Two handle','Traditional','Chrome'], '{"gpm": 1.2, "holes": 0, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.americanstandard.com/bathrooms/faucets/T353501.002')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'american-standard' AND c.slug = 'bathroom-faucet';

-- American Standard Bathtubs
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('2461002.020', 'Cambridge 60" Alcove Bathtub', 'Cambridge', 'alcove', 46, 'gallons', 25, 299, ARRAY['60" x 32"','Americast material','Left drain','Slip resistant'], '{"gallons": 46, "length_inches": 60, "material": "americast", "drain_location": "left"}', 'https://www.americanstandard.com/bathrooms/bathtubs/2461002.020'),
  ('2391202.020', 'Princeton 60" Alcove Bathtub', 'Princeton', 'alcove', 46, 'gallons', 25, 359, ARRAY['60" x 30"','Americast','Right drain','Luxury Ledge'], '{"gallons": 46, "length_inches": 60, "material": "americast", "drain_location": "right"}', 'https://www.americanstandard.com/bathrooms/bathtubs/2391202.020'),
  ('2764014M202.011', 'Cadet 60" Whirlpool Tub', 'Cadet', 'alcove', 52, 'gallons', 20, 1199, ARRAY['8 jets','EverClean','Acrylic','Left drain'], '{"gallons": 52, "length_inches": 60, "material": "acrylic", "drain_location": "left", "jets": 8, "type": "whirlpool"}', 'https://www.americanstandard.com/bathrooms/bathtubs/whirlpool')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'american-standard' AND c.slug = 'bathtub';

-- American Standard Shower Systems
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('TU075507.002', 'Studio S Shower Trim Kit', 'Studio S', 'wall-mount', 2.5, 'gpm', 20, 289, ARRAY['Pressure balance','Single handle','Rain showerhead'], '{"gpm": 2.5, "spray_settings": 1, "valve_type": "pressure_balance"}', 'https://www.americanstandard.com/showering/TU075507.002'),
  ('9035474.002', 'Spectra eTouch 4-Function Showerhead', 'Spectra', 'wall-mount', 2.5, 'gpm', 20, 179, ARRAY['4 spray patterns','Touch activation','Easy clean nozzles'], '{"gpm": 2.5, "spray_settings": 4, "valve_type": "pressure_balance"}', 'https://www.americanstandard.com/showering/9035474.002'),
  ('9038474.002', 'Spectra Plus 4-Function Fixed Showerhead', 'Spectra', 'wall-mount', 1.8, 'gpm', 20, 69, ARRAY['4 spray functions','WaterSense','Chrome'], '{"gpm": 1.8, "spray_settings": 4, "valve_type": "pressure_balance"}', 'https://www.americanstandard.com/showering/9038474.002')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'american-standard' AND c.slug = 'shower-system';

-- ======================== PFISTER ========================

-- Pfister Bathroom Faucets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('LG42-YP0C', 'Ashfield Widespread Faucet', 'Ashfield', 'deck-mount', 1.2, 'gpm', 15, 289, ARRAY['Widespread','Rustic bronze','WaterSense','Pforever Seal'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "rustic_bronze"}', 'https://www.pfisterfaucets.com/bathroom/LG42-YP0C'),
  ('LG49-DE0C', 'Dekker Single-Handle Faucet', 'Dekker', 'deck-mount', 1.2, 'gpm', 15, 129, ARRAY['Single handle','Chrome','WaterSense','Pforever Seal'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.pfisterfaucets.com/bathroom/LG49-DE0C'),
  ('LG48-MF0K', 'McAllen Single-Handle Faucet', 'McAllen', 'deck-mount', 1.2, 'gpm', 15, 179, ARRAY['Single handle','Brushed gold','WaterSense'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "brushed_gold"}', 'https://www.pfisterfaucets.com/bathroom/LG48-MF0K'),
  ('LG49-NC0K', 'Deckard Single-Handle Faucet', 'Deckard', 'deck-mount', 1.2, 'gpm', 15, 199, ARRAY['Single handle','Modern','Matte black'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "matte_black"}', 'https://www.pfisterfaucets.com/bathroom/LG49-NC0K'),
  ('LG42-TB0C', 'Treviso Centerset Faucet', 'Treviso', 'deck-mount', 1.2, 'gpm', 15, 159, ARRAY['Centerset','Tuscan bronze','WaterSense'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "tuscan_bronze"}', 'https://www.pfisterfaucets.com/bathroom/LG42-TB0C')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'pfister' AND c.slug = 'bathroom-faucet';

-- Pfister Shower Systems
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('LG89-7TBC', 'Treviso Tub and Shower Trim', 'Treviso', 'wall-mount', 2.5, 'gpm', 20, 219, ARRAY['Single handle','Pressure balance','Chrome'], '{"gpm": 2.5, "spray_settings": 1, "valve_type": "pressure_balance"}', 'https://www.pfisterfaucets.com/shower/LG89-7TBC'),
  ('R89-8DEC', 'Deckard Shower Trim Kit', 'Deckard', 'wall-mount', 2.0, 'gpm', 20, 175, ARRAY['Modern','Pressure balance','WaterSense'], '{"gpm": 2.0, "spray_settings": 1, "valve_type": "pressure_balance"}', 'https://www.pfisterfaucets.com/shower/R89-8DEC'),
  ('B89-7RHC', 'Rancho Bernardo Shower System', 'Rancho', 'wall-mount', 2.5, 'gpm', 20, 149, ARRAY['Complete system','Chrome','Pressure balance'], '{"gpm": 2.5, "spray_settings": 3, "valve_type": "pressure_balance"}', 'https://www.pfisterfaucets.com/shower/B89-7RHC')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'pfister' AND c.slug = 'shower-system';

-- ======================== SYMMONS ========================

-- Symmons Shower Systems
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('S-9602-P', 'Origins Temptrol Shower System', 'Origins', 'wall-mount', 2.5, 'gpm', 20, 189, ARRAY['Temptrol pressure-balancing','Single handle','Chrome'], '{"gpm": 2.5, "spray_settings": 1, "valve_type": "pressure_balance"}', 'https://www.symmons.com/product/S-9602-P'),
  ('4705-TRM', 'Allura Tub/Shower Trim Kit', 'Allura', 'wall-mount', 2.5, 'gpm', 20, 225, ARRAY['Temptrol valve','Lever handle','Chrome'], '{"gpm": 2.5, "spray_settings": 1, "valve_type": "pressure_balance"}', 'https://www.symmons.com/product/4705-TRM'),
  ('3602-H321-V-TRM', 'Duro Shower Trim with Volume Control', 'Duro', 'wall-mount', 2.5, 'gpm', 20, 275, ARRAY['Volume control','Temptrol','Lever handle'], '{"gpm": 2.5, "spray_settings": 1, "valve_type": "thermostatic"}', 'https://www.symmons.com/product/3602-H321-V-TRM'),
  ('S-4302-TRM', 'Sereno Shower Trim', 'Sereno', 'wall-mount', 1.5, 'gpm', 20, 199, ARRAY['Modern design','1.5 GPM','WaterSense','Chrome'], '{"gpm": 1.5, "spray_settings": 1, "valve_type": "pressure_balance"}', 'https://www.symmons.com/product/S-4302-TRM'),
  ('S-6708-TRM', 'Identity 2-Handle Shower Trim', 'Identity', 'wall-mount', 2.5, 'gpm', 20, 315, ARRAY['Two handle','Thermostatic','Chrome'], '{"gpm": 2.5, "spray_settings": 1, "valve_type": "thermostatic"}', 'https://www.symmons.com/product/S-6708-TRM')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'symmons' AND c.slug = 'shower-system';

-- Symmons Bathroom Faucets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('SLS-6612-1.0', 'Unity Centerset Faucet', 'Unity', 'deck-mount', 1.0, 'gpm', 15, 179, ARRAY['Centerset','Single handle','Chrome','WaterSense'], '{"gpm": 1.0, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.symmons.com/product/SLS-6612-1.0'),
  ('SLW-3512', 'Dia Widespread Faucet', 'Dia', 'deck-mount', 1.2, 'gpm', 15, 349, ARRAY['Widespread','Two handle','Chrome'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.symmons.com/product/SLW-3512'),
  ('SLS-4312', 'Sereno Single-Handle Faucet', 'Sereno', 'deck-mount', 1.2, 'gpm', 15, 199, ARRAY['Single handle','Modern','Chrome','WaterSense'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.symmons.com/product/SLS-4312')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'symmons' AND c.slug = 'bathroom-faucet';

-- ======================== KRAUS ========================

-- Kraus Bathroom Faucets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('KBF-1401CH', 'Arlo Single-Handle Basin Faucet', 'Arlo', 'deck-mount', 1.2, 'gpm', 15, 89, ARRAY['Single handle','Lift rod drain','Chrome','WaterSense'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.kraususa.com/bathroom-faucets/KBF-1401CH'),
  ('KVF-1400CH', 'Indy Single-Handle Vessel Faucet', 'Indy', 'deck-mount', 1.2, 'gpm', 15, 79, ARRAY['Vessel faucet','Tall spout','Chrome'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.kraususa.com/bathroom-faucets/KVF-1400CH'),
  ('KBF-1221CH', 'Ramus Single-Handle Vessel Faucet', 'Ramus', 'deck-mount', 1.2, 'gpm', 15, 109, ARRAY['Vessel faucet','Waterfall spout','Chrome'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.kraususa.com/bathroom-faucets/KBF-1221CH'),
  ('FUS-13901BN', 'Arlo Centerset Faucet', 'Arlo', 'deck-mount', 1.2, 'gpm', 15, 119, ARRAY['Centerset','Brushed nickel','Lift rod drain'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "brushed_nickel"}', 'https://www.kraususa.com/bathroom-faucets/FUS-13901BN'),
  ('KBF-1201CH', 'Aquila Single-Handle Faucet', 'Aquila', 'deck-mount', 1.5, 'gpm', 15, 69, ARRAY['Single handle','Modern','Chrome'], '{"gpm": 1.5, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.kraususa.com/bathroom-faucets/KBF-1201CH')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'kraus' AND c.slug = 'bathroom-faucet';

-- Kraus Shower Systems
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('KES-26268CH', 'Acqua Shower Panel System', 'Acqua', 'wall-mount', 2.5, 'gpm', 15, 289, ARRAY['Shower panel','Rain showerhead','Body jets','Handheld'], '{"gpm": 2.5, "spray_settings": 4, "valve_type": "thermostatic"}', 'https://www.kraususa.com/shower-systems/KES-26268CH'),
  ('KSP-5000CH', 'Purito 5-Spray Showerhead', 'Purito', 'wall-mount', 2.5, 'gpm', 15, 39, ARRAY['5 spray settings','Chrome','Easy clean nozzles'], '{"gpm": 2.5, "spray_settings": 5, "valve_type": "pressure_balance"}', 'https://www.kraususa.com/shower-systems/KSP-5000CH')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'kraus' AND c.slug = 'shower-system';


-- ============================================================================
-- PREMIUM TIER
-- ============================================================================

-- ======================== KOHLER ========================

-- Kohler Toilets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, true, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('K-3999', 'Highline Comfort Height Elongated Toilet', 'Highline', 'floor-mount', 1.28, 'gpf', 25, false, 349, ARRAY['Comfort Height','Elongated','AquaPiston flush','Class Five'], '{"rough_in": 12, "flush_type": "gravity", "map_score": 1000, "ada": true, "bowl_shape": "elongated"}', 'https://www.us.kohler.com/us/K-3999'),
  ('K-3817', 'Memoirs Stately Comfort Height Toilet', 'Memoirs', 'floor-mount', 1.28, 'gpf', 25, false, 549, ARRAY['Stately design','Comfort Height','AquaPiston','Elongated'], '{"rough_in": 12, "flush_type": "gravity", "map_score": 1000, "ada": true, "bowl_shape": "elongated"}', 'https://www.us.kohler.com/us/K-3817'),
  ('K-3609', 'Cimarron Comfort Height Elongated Toilet', 'Cimarron', 'floor-mount', 1.28, 'gpf', 25, false, 299, ARRAY['Comfort Height','AquaPiston','Revolution 360','Elongated'], '{"rough_in": 12, "flush_type": "gravity", "map_score": 1000, "ada": true, "bowl_shape": "elongated"}', 'https://www.us.kohler.com/us/K-3609'),
  ('K-3810', 'Santa Rosa One-Piece Compact Elongated Toilet', 'Santa Rosa', 'floor-mount', 1.28, 'gpf', 25, false, 459, ARRAY['One-piece','Compact elongated','Comfort Height','AquaPiston'], '{"rough_in": 12, "flush_type": "gravity", "map_score": 1000, "ada": true, "bowl_shape": "compact_elongated"}', 'https://www.us.kohler.com/us/K-3810'),
  ('K-5172', 'San Souci One-Piece Compact Elongated Toilet', 'San Souci', 'floor-mount', 1.28, 'gpf', 25, false, 699, ARRAY['One-piece','Skirted trapway','Compact elongated','AquaPiston'], '{"rough_in": 12, "flush_type": "gravity", "map_score": 1000, "ada": true, "bowl_shape": "compact_elongated"}', 'https://www.us.kohler.com/us/K-5172'),
  ('K-6299', 'Veil Intelligent Toilet', 'Veil', 'floor-mount', 1.28, 'gpf', 25, true, 4650, ARRAY['Intelligent toilet','Bidet seat','Heated seat','UV cleaning','Touchscreen remote'], '{"rough_in": 12, "flush_type": "siphon", "map_score": 800, "ada": true, "bowl_shape": "elongated", "bidet": true, "smart": true}', 'https://www.us.kohler.com/us/K-6299'),
  ('K-77780', 'Numi 2.0 Intelligent Toilet', 'Numi', 'floor-mount', 1.28, 'gpf', 25, true, 9000, ARRAY['Intelligent toilet','Personal cleansing','UV light','Ambient lighting','Built-in speakers','Amazon Alexa'], '{"rough_in": 12, "flush_type": "siphon", "map_score": 800, "ada": true, "bowl_shape": "elongated", "bidet": true, "smart": true}', 'https://www.us.kohler.com/us/K-77780'),
  ('K-6303', 'Veil Wall-Hung Toilet', 'Veil', 'wall-hung', 1.28, 'gpf', 25, false, 649, ARRAY['Wall-hung','Space saving','Elongated','Quiet-Close seat'], '{"rough_in": 0, "flush_type": "gravity", "map_score": 800, "ada": true, "bowl_shape": "elongated", "wall_hung": true}', 'https://www.us.kohler.com/us/K-6303'),
  ('K-3933', 'Memoirs Stately Comfort Height Two-Piece Toilet', 'Memoirs', 'floor-mount', 1.28, 'gpf', 25, false, 499, ARRAY['Stately design','Two-piece','Comfort Height','AquaPiston'], '{"rough_in": 12, "flush_type": "gravity", "map_score": 1000, "ada": true, "bowl_shape": "elongated"}', 'https://www.us.kohler.com/us/K-3933')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'kohler' AND c.slug = 'toilet';

-- Kohler Bathroom Faucets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('K-193-4', 'Devonshire Centerset Faucet', 'Devonshire', 'deck-mount', 1.2, 'gpm', 15, 289, ARRAY['Centerset','Two handle','Polished chrome','WaterSense'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.us.kohler.com/us/K-193-4'),
  ('K-10215-4', 'Forte Centerset Faucet', 'Forte', 'deck-mount', 1.5, 'gpm', 15, 225, ARRAY['Centerset','Single handle','Sculpted lever'], '{"gpm": 1.5, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.us.kohler.com/us/K-10215-4'),
  ('K-454-4V', 'Memoirs Stately Widespread Faucet', 'Memoirs', 'deck-mount', 1.2, 'gpm', 15, 499, ARRAY['Widespread','Traditional design','WaterSense','Chrome'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.us.kohler.com/us/K-454-4V'),
  ('K-72218', 'Sensate Touchless Bathroom Faucet', 'Sensate', 'deck-mount', 0.5, 'gpm', 15, 549, ARRAY['Touchless','Response technology','Chrome','WaterSense'], '{"gpm": 0.5, "holes": 1, "valve_type": "electronic", "finish": "chrome", "touchless": true}', 'https://www.us.kohler.com/us/K-72218'),
  ('K-97093-4', 'Components Single-Handle Faucet', 'Components', 'deck-mount', 1.2, 'gpm', 15, 379, ARRAY['Modular design','Single handle','Row design','WaterSense'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.us.kohler.com/us/K-97093-4'),
  ('K-14402-4A', 'Purist Widespread Faucet', 'Purist', 'deck-mount', 1.2, 'gpm', 15, 599, ARRAY['Widespread','Minimalist design','WaterSense','Chrome'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.us.kohler.com/us/K-14402-4A'),
  ('T14413-4', 'Purist Wall-Mount Faucet Trim', 'Purist', 'wall-mount', 1.2, 'gpm', 15, 699, ARRAY['Wall mount','Minimalist','90-degree spout','Chrome'], '{"gpm": 1.2, "holes": 0, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.us.kohler.com/us/T14413-4')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'kohler' AND c.slug = 'bathroom-faucet';

-- Kohler Shower Systems
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('K-22169', 'Statement 10" Rainhead', 'Statement', 'wall-mount', 2.5, 'gpm', 20, false, 499, ARRAY['10" round rainhead','Single function','Chrome'], '{"gpm": 2.5, "spray_settings": 1, "head_diameter": 10}', 'https://www.us.kohler.com/us/K-22169'),
  ('K-99696-G', 'Awaken G110 Handshower', 'Awaken', 'wall-mount', 2.0, 'gpm', 20, false, 89, ARRAY['3 spray functions','Ergonomic grip','Chrome'], '{"gpm": 2.0, "spray_settings": 3, "valve_type": "pressure_balance"}', 'https://www.us.kohler.com/us/K-99696-G'),
  ('K-TS97074-4', 'Components Rite-Temp Shower Trim', 'Components', 'wall-mount', 2.5, 'gpm', 20, false, 399, ARRAY['Rite-Temp valve','Modular design','Chrome'], '{"gpm": 2.5, "spray_settings": 1, "valve_type": "pressure_balance", "rough_in_valve": "K-8304"}', 'https://www.us.kohler.com/us/K-TS97074-4'),
  ('K-TS14422-4', 'Purist Rite-Temp Shower Trim', 'Purist', 'wall-mount', 2.5, 'gpm', 20, false, 529, ARRAY['Rite-Temp pressure-balancing','Minimalist design','Chrome'], '{"gpm": 2.5, "spray_settings": 1, "valve_type": "pressure_balance", "rough_in_valve": "K-8304"}', 'https://www.us.kohler.com/us/K-TS14422-4'),
  ('K-99105', 'DTV+ Digital Shower System', 'DTV+', 'wall-mount', 2.5, 'gpm', 20, true, 2800, ARRAY['Digital thermostatic','Touchscreen','Preset programs','Multiple outlets'], '{"gpm": 2.5, "spray_settings": 6, "valve_type": "digital_thermostatic", "smart": true}', 'https://www.us.kohler.com/us/K-99105')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'kohler' AND c.slug = 'shower-system';

-- Kohler Bathtubs
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('K-1123-RA', 'Archer 60" Alcove Bathtub', 'Archer', 'alcove', 60, 'gallons', 25, 599, ARRAY['60" x 32"','Acrylic','Integral apron','Slip-resistant'], '{"gallons": 60, "length_inches": 60, "material": "acrylic", "drain_location": "right"}', 'https://www.us.kohler.com/us/K-1123-RA'),
  ('K-1150', 'Bancroft 60" Alcove Bathtub', 'Bancroft', 'alcove', 55, 'gallons', 25, 699, ARRAY['60" x 32"','Acrylic','Traditional design'], '{"gallons": 55, "length_inches": 60, "material": "acrylic", "drain_location": "left"}', 'https://www.us.kohler.com/us/K-1150'),
  ('K-700', 'Villager 60" Cast Iron Alcove Bathtub', 'Villager', 'alcove', 48, 'gallons', 30, 699, ARRAY['60" x 30.25"','Cast iron','Durable enamel'], '{"gallons": 48, "length_inches": 60, "material": "cast_iron", "drain_location": "right"}', 'https://www.us.kohler.com/us/K-700'),
  ('K-5701', 'Underscore Rectangle 60" Freestanding Bath', 'Underscore', 'freestanding', 68, 'gallons', 25, 3200, ARRAY['60" freestanding','BubbleMassage','Chromatherapy available'], '{"gallons": 68, "length_inches": 60, "material": "acrylic", "drain_location": "center"}', 'https://www.us.kohler.com/us/K-5701'),
  ('K-1492-HB', 'Archer 72" Whirlpool Bathtub', 'Archer', 'drop-in', 82, 'gallons', 20, 2999, ARRAY['72" x 36"','10 adjustable jets','Inline heater','BubbleMassage'], '{"gallons": 82, "length_inches": 72, "material": "acrylic", "drain_location": "center", "jets": 10, "type": "whirlpool"}', 'https://www.us.kohler.com/us/K-1492-HB'),
  ('K-1946', 'Archer 66" Freestanding Bath', 'Archer', 'freestanding', 65, 'gallons', 25, 2499, ARRAY['66" freestanding','Acrylic','Slotted overflow','Center drain'], '{"gallons": 65, "length_inches": 66, "material": "acrylic", "drain_location": "center"}', 'https://www.us.kohler.com/us/K-1946')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'kohler' AND c.slug = 'bathtub';

-- Kohler Bidets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, NULL, NULL, true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('K-8298', 'C3-230 Elongated Bidet Toilet Seat', 'C3', 'deck-mount', 15, false, 599, ARRAY['Heated seat','Warm water','Self-cleaning wand','Night light'], '{"heated_seat": true, "warm_water": true, "dryer": true, "remote": false, "deodorizer": false}', 'https://www.us.kohler.com/us/K-8298'),
  ('K-18751', 'C3-050 Elongated Bidet Toilet Seat', 'C3', 'deck-mount', 15, false, 349, ARRAY['Heated seat','Warm water','Side panel controls'], '{"heated_seat": true, "warm_water": true, "dryer": false, "remote": false, "deodorizer": false}', 'https://www.us.kohler.com/us/K-18751'),
  ('K-31271', 'PureWash E930 Elongated Bidet Seat', 'PureWash', 'deck-mount', 15, true, 899, ARRAY['Heated seat','Warm air dryer','UV light cleaning','Remote control','Deodorizer'], '{"heated_seat": true, "warm_water": true, "dryer": true, "remote": true, "deodorizer": true}', 'https://www.us.kohler.com/us/K-31271')
) AS v(model_number, model_name, series, install, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'kohler' AND c.slug = 'bidet';

-- ======================== TOTO ========================

-- TOTO Toilets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, true, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('MS604114CEFG', 'UltraMax II One-Piece Elongated Toilet', 'UltraMax II', 'floor-mount', 1.28, 'gpf', 25, false, 529, ARRAY['One-piece','Tornado Flush','CeFiONtect glaze','Universal Height'], '{"rough_in": 12, "flush_type": "tornado", "map_score": 1000, "ada": true, "bowl_shape": "elongated"}', 'https://www.totousa.com/ultramax-ii-one-piece-toilet'),
  ('CST484CEMFG', 'Maris Wall-Hung Toilet', 'Maris', 'wall-hung', 1.28, 'gpf', 25, false, 799, ARRAY['Wall-hung','Tornado Flush','CeFiONtect','Space saving'], '{"rough_in": 0, "flush_type": "tornado", "map_score": 800, "ada": true, "bowl_shape": "elongated", "wall_hung": true}', 'https://www.totousa.com/maris-wall-hung-toilet'),
  ('MS446124CEMFG', 'Aquia IV Two-Piece Elongated Dual Flush Toilet', 'Aquia IV', 'floor-mount', 0.9, 'gpf', 25, false, 449, ARRAY['Dual flush 0.9/1.28','Tornado Flush','CeFiONtect','WaterSense'], '{"rough_in": 12, "flush_type": "tornado_dual", "map_score": 800, "ada": true, "bowl_shape": "elongated"}', 'https://www.totousa.com/aquia-iv-two-piece-toilet'),
  ('MS642124CEFG', 'Nexus One-Piece Elongated Toilet', 'Nexus', 'floor-mount', 1.28, 'gpf', 25, false, 699, ARRAY['One-piece','Tornado Flush','CeFiONtect','Skirted design'], '{"rough_in": 12, "flush_type": "tornado", "map_score": 1000, "ada": true, "bowl_shape": "elongated"}', 'https://www.totousa.com/nexus-one-piece-toilet'),
  ('CST744EL', 'Drake Elongated Two-Piece Toilet', 'Drake', 'floor-mount', 1.28, 'gpf', 25, false, 349, ARRAY['Two-piece','E-Max flushing','Universal Height','Elongated'], '{"rough_in": 12, "flush_type": "gravity", "map_score": 800, "ada": true, "bowl_shape": "elongated"}', 'https://www.totousa.com/drake-elongated-two-piece-toilet'),
  ('CST746CEMFG', 'Drake Two-Piece Elongated Dual Flush Toilet', 'Drake', 'floor-mount', 0.9, 'gpf', 25, false, 429, ARRAY['Dual flush','Tornado Flush','CeFiONtect','Drake legacy'], '{"rough_in": 12, "flush_type": "tornado_dual", "map_score": 800, "ada": true, "bowl_shape": "elongated"}', 'https://www.totousa.com/drake-dual-flush-toilet'),
  ('MS920CEMFG', 'Washlet G400 Integrated Toilet', 'Washlet', 'floor-mount', 1.28, 'gpf', 25, true, 2600, ARRAY['Integrated Washlet','Tornado Flush','Premist','eWater+','Heated seat','Auto open/close'], '{"rough_in": 12, "flush_type": "tornado", "map_score": 1000, "ada": true, "bowl_shape": "elongated", "bidet": true, "smart": true}', 'https://www.totousa.com/washlet-g400-integrated-toilet'),
  ('MS8551CUMFG', 'Neorest NX1 Dual Flush Toilet', 'Neorest', 'floor-mount', 1.0, 'gpf', 25, true, 12500, ARRAY['Ultra-premium','Auto open/close/flush','Actilight UV','eWater+','Heated seat','Warm air dryer'], '{"rough_in": 12, "flush_type": "tornado_dual", "map_score": 1000, "ada": true, "bowl_shape": "elongated", "bidet": true, "smart": true}', 'https://www.totousa.com/neorest-nx1-dual-flush-toilet'),
  ('MS8732CUMFG', 'Neorest NX2 Dual Flush Toilet', 'Neorest', 'floor-mount', 1.0, 'gpf', 25, true, 17300, ARRAY['Flagship model','Actilight','Auto everything','CEFIONTECT','eWater+','Night light'], '{"rough_in": 12, "flush_type": "tornado_dual", "map_score": 1000, "ada": true, "bowl_shape": "elongated", "bidet": true, "smart": true}', 'https://www.totousa.com/neorest-nx2-dual-flush-toilet'),
  ('CT418FG', 'Aquia Wall-Hung Bowl', 'Aquia', 'wall-hung', 1.28, 'gpf', 25, false, 349, ARRAY['Wall-hung','CeFiONtect','Elongated','Space saving'], '{"rough_in": 0, "flush_type": "gravity", "map_score": 800, "ada": true, "bowl_shape": "elongated", "wall_hung": true}', 'https://www.totousa.com/aquia-wall-hung-toilet'),
  ('MS853113E', 'UltraMax One-Piece Round Toilet', 'UltraMax', 'floor-mount', 1.28, 'gpf', 25, false, 449, ARRAY['One-piece','E-Max flush','Round','Cotton White'], '{"rough_in": 12, "flush_type": "gravity", "map_score": 800, "ada": false, "bowl_shape": "round"}', 'https://www.totousa.com/ultramax-one-piece-round-toilet')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'toto' AND c.slug = 'toilet';

-- TOTO Bidet Seats (Washlet)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, NULL, NULL, true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('SW3074', 'Washlet C5 Elongated Bidet Seat', 'Washlet C5', 'deck-mount', 15, false, 475, ARRAY['Premist','Warm water','Heated seat','Adjustable wand','eWater+'], '{"heated_seat": true, "warm_water": true, "dryer": true, "remote": false, "deodorizer": false}', 'https://www.totousa.com/washlet-c5-elongated'),
  ('SW3084', 'Washlet C2 Elongated Bidet Seat', 'Washlet C2', 'deck-mount', 15, false, 375, ARRAY['Premist','Warm water','Heated seat','3 wash modes'], '{"heated_seat": true, "warm_water": true, "dryer": false, "remote": false, "deodorizer": false}', 'https://www.totousa.com/washlet-c2-elongated'),
  ('SW3056', 'Washlet S550e Elongated Bidet Seat', 'Washlet S550e', 'deck-mount', 15, true, 1100, ARRAY['Remote control','eWater+','Premist','Warm air dryer','Auto open/close','Night light','Deodorizer'], '{"heated_seat": true, "warm_water": true, "dryer": true, "remote": true, "deodorizer": true}', 'https://www.totousa.com/washlet-s550e-elongated'),
  ('SW3046', 'Washlet S500e Elongated Bidet Seat', 'Washlet S500e', 'deck-mount', 15, true, 899, ARRAY['Remote control','eWater+','Premist','Warm air dryer','Deodorizer'], '{"heated_seat": true, "warm_water": true, "dryer": true, "remote": true, "deodorizer": true}', 'https://www.totousa.com/washlet-s500e-elongated'),
  ('SW4736', 'Washlet KC2 Elongated Bidet Seat', 'Washlet KC2', 'deck-mount', 10, false, 275, ARRAY['Entry Washlet','Warm water','Heated seat','Self-cleaning wand'], '{"heated_seat": true, "warm_water": true, "dryer": false, "remote": false, "deodorizer": false}', 'https://www.totousa.com/washlet-kc2-elongated')
) AS v(model_number, model_name, series, install, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'toto' AND c.slug = 'bidet';

-- TOTO Bathroom Faucets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('TLG01301U', 'GO Single-Handle Faucet', 'GO', 'deck-mount', 1.2, 'gpm', 15, 179, ARRAY['Single handle','Chrome','WaterSense','Pop-up drain'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.totousa.com/go-single-handle-faucet'),
  ('TLG09301U', 'GS Single-Handle Faucet', 'GS', 'deck-mount', 1.2, 'gpm', 15, 249, ARRAY['Single handle','Semi-vessel','Chrome','WaterSense'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.totousa.com/gs-single-handle-faucet'),
  ('TLG11201U', 'GR Widespread Faucet', 'GR', 'deck-mount', 1.2, 'gpm', 15, 499, ARRAY['Widespread','Two handle','Premium design','Chrome'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.totousa.com/gr-widespread-faucet'),
  ('TLP01309U', 'LB Wall-Mount Faucet', 'LB', 'wall-mount', 1.2, 'gpm', 15, 599, ARRAY['Wall mount','Single handle','Chrome','Contemporary'], '{"gpm": 1.2, "holes": 0, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.totousa.com/lb-wall-mount-faucet')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'toto' AND c.slug = 'bathroom-faucet';

-- TOTO Bathtubs
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('ABF626N', 'Flotation Tub ZERO DIMENSION', 'ZERO DIMENSION', 'freestanding', 105, 'gallons', 25, 12000, ARRAY['Zero-gravity floating position','Neck pillow','Hydrohands jets','Acrylic'], '{"gallons": 105, "length_inches": 66, "material": "acrylic", "drain_location": "center", "type": "air_bath"}', 'https://www.totousa.com/flotation-tub-zero-dimension'),
  ('ABY782', 'Clayton Freestanding Bathtub', 'Clayton', 'freestanding', 55, 'gallons', 25, 2999, ARRAY['Freestanding','Cast acrylic','Center drain'], '{"gallons": 55, "length_inches": 60, "material": "cast_acrylic", "drain_location": "center"}', 'https://www.totousa.com/clayton-freestanding-bathtub'),
  ('FBY1515LP', 'Mariana 60" Alcove Bathtub', 'Mariana', 'alcove', 45, 'gallons', 25, 499, ARRAY['60" x 32"','Left drain','Acrylic','Slip resistant'], '{"gallons": 45, "length_inches": 60, "material": "acrylic", "drain_location": "left"}', 'https://www.totousa.com/mariana-alcove-bathtub')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'toto' AND c.slug = 'bathtub';

-- ======================== HANSGROHE ========================

-- Hansgrohe Bathroom Faucets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('04233000', 'Talis C Single-Hole Faucet', 'Talis C', 'deck-mount', 1.2, 'gpm', 15, 299, ARRAY['Single hole','Joystick handle','Chrome','WaterSense'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.hansgrohe-usa.com/04233000'),
  ('04370000', 'Talis S Single-Hole Faucet', 'Talis S', 'deck-mount', 1.2, 'gpm', 15, 219, ARRAY['Single hole','Modern design','Chrome','WaterSense','EcoRight'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.hansgrohe-usa.com/04370000'),
  ('31060001', 'Metris Single-Hole Faucet', 'Metris', 'deck-mount', 1.2, 'gpm', 15, 299, ARRAY['Single hole','Chrome','ComfortZone','WaterSense'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.hansgrohe-usa.com/31060001'),
  ('04369000', 'Talis S Widespread Faucet', 'Talis S', 'deck-mount', 1.2, 'gpm', 15, 549, ARRAY['Widespread','Chrome','WaterSense','EcoRight'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.hansgrohe-usa.com/04369000'),
  ('71700001', 'Talis E Single-Hole Faucet', 'Talis E', 'deck-mount', 1.2, 'gpm', 15, 249, ARRAY['Single hole','Organic design','Chrome','CoolStart'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.hansgrohe-usa.com/71700001'),
  ('75030001', 'Vivenis Single-Hole Faucet', 'Vivenis', 'deck-mount', 1.2, 'gpm', 15, 329, ARRAY['Single hole','Flat spout','Chrome','CoolStart'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.hansgrohe-usa.com/75030001'),
  ('10020001', 'Axor Starck Wall-Mount Faucet Trim', 'Axor Starck', 'wall-mount', 1.2, 'gpm', 15, 799, ARRAY['Wall mount','Philippe Starck design','Chrome'], '{"gpm": 1.2, "holes": 0, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.hansgrohe-usa.com/10020001')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'hansgrohe' AND c.slug = 'bathroom-faucet';

-- Hansgrohe Shower Systems
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('04233820', 'Raindance S 240 Showerhead', 'Raindance', 'wall-mount', 2.5, 'gpm', 20, 399, ARRAY['10" showerhead','AIR technology','Chrome','3 spray modes'], '{"gpm": 2.5, "spray_settings": 3, "head_diameter": 10}', 'https://www.hansgrohe-usa.com/04233820'),
  ('27160001', 'Raindance Select S 120 Handshower', 'Raindance Select', 'wall-mount', 2.5, 'gpm', 20, 99, ARRAY['Select button','3 spray modes','Chrome'], '{"gpm": 2.5, "spray_settings": 3, "valve_type": "pressure_balance"}', 'https://www.hansgrohe-usa.com/27160001'),
  ('04536000', 'Raindance E Overhead Shower 300 1-Jet', 'Raindance E', 'wall-mount', 2.5, 'gpm', 20, 599, ARRAY['12" overhead','PowderRain spray','Chrome'], '{"gpm": 2.5, "spray_settings": 1, "head_diameter": 12}', 'https://www.hansgrohe-usa.com/04536000'),
  ('15765001', 'ShowerSelect Thermostatic Trim', 'ShowerSelect', 'wall-mount', 2.5, 'gpm', 20, 699, ARRAY['Thermostatic','Push-button controls','2 outlets','Chrome'], '{"gpm": 2.5, "spray_settings": 2, "valve_type": "thermostatic"}', 'https://www.hansgrohe-usa.com/15765001'),
  ('04726000', 'Pulsify 2-Jet Showerhead', 'Pulsify', 'wall-mount', 2.5, 'gpm', 20, 79, ARRAY['2 spray modes','PowderRain','Chrome','Easy clean'], '{"gpm": 2.5, "spray_settings": 2, "valve_type": "pressure_balance"}', 'https://www.hansgrohe-usa.com/04726000'),
  ('26234001', 'Croma 280 1-Jet Showerhead', 'Croma', 'wall-mount', 2.5, 'gpm', 20, 249, ARRAY['11" showerhead','AIR power','Chrome'], '{"gpm": 2.5, "spray_settings": 1, "head_diameter": 11}', 'https://www.hansgrohe-usa.com/26234001')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'hansgrohe' AND c.slug = 'shower-system';

-- ======================== GROHE ========================

-- Grohe Bathroom Faucets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('23173003', 'Eurosmart Centerset Faucet', 'Eurosmart', 'deck-mount', 1.2, 'gpm', 15, 159, ARRAY['Centerset','SilkMove','Chrome','WaterSense'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome", "cartridge": "46580"}', 'https://www.grohe.com/us/23173003'),
  ('20297001', 'Parkfield Widespread Faucet', 'Parkfield', 'deck-mount', 1.2, 'gpm', 15, 399, ARRAY['Widespread','SilkMove','StarLight chrome','WaterSense'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.grohe.com/us/20297001'),
  ('32137002', 'Concetto Single-Handle Faucet', 'Concetto', 'deck-mount', 1.2, 'gpm', 15, 249, ARRAY['Single handle','SilkMove','Chrome','EcoJoy'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome", "cartridge": "46580"}', 'https://www.grohe.com/us/32137002'),
  ('23831003', 'Eurocube Single-Handle Faucet', 'Eurocube', 'deck-mount', 1.2, 'gpm', 15, 289, ARRAY['Single handle','Angular design','Chrome','SilkMove'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.grohe.com/us/23831003'),
  ('20374001', 'Grandera Widespread Faucet', 'Grandera', 'deck-mount', 1.2, 'gpm', 15, 699, ARRAY['Widespread','Cross handles','Chrome','StarLight'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.grohe.com/us/20374001'),
  ('19576001', 'Essence Wall-Mount Faucet', 'Essence', 'wall-mount', 1.2, 'gpm', 15, 549, ARRAY['Wall mount','Single handle','Chrome','SilkMove'], '{"gpm": 1.2, "holes": 0, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.grohe.com/us/19576001'),
  ('2302700A', 'Essence Single-Handle Faucet', 'Essence', 'deck-mount', 1.2, 'gpm', 15, 299, ARRAY['Single handle','Cylindrical body','Chrome','EcoJoy'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.grohe.com/us/2302700A'),
  ('20482EN0', 'Fairborn Widespread Faucet', 'Fairborn', 'deck-mount', 1.2, 'gpm', 15, 329, ARRAY['Widespread','Brushed nickel','SilkMove','WaterSense'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "brushed_nickel"}', 'https://www.grohe.com/us/20482EN0')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'grohe' AND c.slug = 'bathroom-faucet';

-- Grohe Shower Systems
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('26128001', 'Retro-Fit Rainshower System', 'Rainshower', 'wall-mount', 2.5, 'gpm', 20, 699, ARRAY['Retro-fit system','10" rainshower','Diverter','Chrome'], '{"gpm": 2.5, "spray_settings": 2, "valve_type": "pressure_balance", "head_diameter": 10}', 'https://www.grohe.com/us/26128001'),
  ('27907000', 'Euphoria 260 Shower System', 'Euphoria', 'wall-mount', 2.5, 'gpm', 20, 799, ARRAY['Thermostatic','10" head shower','Hand shower','Chrome'], '{"gpm": 2.5, "spray_settings": 3, "valve_type": "thermostatic", "head_diameter": 10}', 'https://www.grohe.com/us/27907000'),
  ('26487000', 'SmartControl Exposed Shower System', 'SmartControl', 'wall-mount', 2.5, 'gpm', 20, 1299, ARRAY['Push-turn SmartControl','Thermostatic','CoolTouch','Chrome'], '{"gpm": 2.5, "spray_settings": 3, "valve_type": "thermostatic"}', 'https://www.grohe.com/us/26487000'),
  ('26457001', 'Tempesta 250 Shower System', 'Tempesta', 'wall-mount', 2.5, 'gpm', 20, 399, ARRAY['10" head shower','Diverter','Chrome','TurboStat'], '{"gpm": 2.5, "spray_settings": 2, "valve_type": "thermostatic", "head_diameter": 10}', 'https://www.grohe.com/us/26457001'),
  ('26478001', 'Rainshower SmartActive 310 Showerhead', 'Rainshower', 'wall-mount', 2.5, 'gpm', 20, 399, ARRAY['12" showerhead','3 spray patterns','DreamSpray','Chrome'], '{"gpm": 2.5, "spray_settings": 3, "head_diameter": 12}', 'https://www.grohe.com/us/26478001'),
  ('26504000', 'Grohtherm SmartControl Trim', 'Grohtherm', 'wall-mount', 2.5, 'gpm', 20, 899, ARRAY['SmartControl push-turn','Thermostatic','3 outlets','Chrome'], '{"gpm": 2.5, "spray_settings": 3, "valve_type": "thermostatic"}', 'https://www.grohe.com/us/26504000')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'grohe' AND c.slug = 'shower-system';

-- Grohe Toilets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, true, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('39663000', 'Eurocube Two-Piece Toilet', 'Eurocube', 'floor-mount', 1.28, 'gpf', 25, 499, ARRAY['Right height','Elongated','Triple Vortex flush','WaterSense'], '{"rough_in": 12, "flush_type": "triple_vortex", "map_score": 800, "ada": true, "bowl_shape": "elongated"}', 'https://www.grohe.com/us/39663000'),
  ('39675000', 'Essence Wall-Hung Toilet', 'Essence', 'wall-hung', 1.28, 'gpf', 25, 599, ARRAY['Wall-hung','PureGuard','Rimless flush','WaterSense'], '{"rough_in": 0, "flush_type": "rimless", "map_score": 800, "ada": true, "bowl_shape": "elongated", "wall_hung": true}', 'https://www.grohe.com/us/39675000')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'grohe' AND c.slug = 'toilet';

-- ======================== JACUZZI ========================

-- Jacuzzi Bathtubs
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('ANZ6636WCR2XX', 'Anza 66" x 36" Whirlpool Tub', 'Anza', 'drop-in', 80, 'gallons', 20, 1999, ARRAY['6 jets','Whirlpool','Acrylic','Center drain'], '{"gallons": 80, "length_inches": 66, "material": "acrylic", "drain_location": "center", "jets": 6, "type": "whirlpool"}', 'https://www.jacuzzi.com/bathtubs/anza-whirlpool'),
  ('FUZ7236WCR2CH', 'Fuzion 72" x 36" Whirlpool Tub', 'Fuzion', 'drop-in', 98, 'gallons', 20, 3999, ARRAY['10 jets','Whirlpool','Chromatherapy','Heater'], '{"gallons": 98, "length_inches": 72, "material": "acrylic", "drain_location": "center", "jets": 10, "type": "whirlpool"}', 'https://www.jacuzzi.com/bathtubs/fuzion-whirlpool'),
  ('CET6032WCR2XX', 'Cetra 60" x 32" Whirlpool Tub', 'Cetra', 'alcove', 50, 'gallons', 20, 1299, ARRAY['6 jets','Comfort Whirlpool','60" alcove','Left drain'], '{"gallons": 50, "length_inches": 60, "material": "acrylic", "drain_location": "left", "jets": 6, "type": "whirlpool"}', 'https://www.jacuzzi.com/bathtubs/cetra-whirlpool'),
  ('MIO6636ACR5CX', 'Mio 66" Freestanding Air Bath', 'Mio', 'freestanding', 72, 'gallons', 20, 4499, ARRAY['Freestanding','Air bath','Heated air jets','Contemporary'], '{"gallons": 72, "length_inches": 66, "material": "acrylic", "drain_location": "center", "type": "air_bath"}', 'https://www.jacuzzi.com/bathtubs/mio-air-bath'),
  ('FIN6032WLR2XX', 'Finestra 60" x 32" Walk-In Tub', 'Finestra', 'alcove', 48, 'gallons', 20, 3299, ARRAY['Walk-in','Whirlpool jets','Low threshold','Grab bars'], '{"gallons": 48, "length_inches": 60, "material": "acrylic", "drain_location": "left", "jets": 8, "type": "walk_in_whirlpool"}', 'https://www.jacuzzi.com/bathtubs/finestra-walk-in'),
  ('LEX6636BCR5CX', 'Lexia 66" Freestanding Soaking Tub', 'Lexia', 'freestanding', 65, 'gallons', 25, 2499, ARRAY['Freestanding','Soaking tub','Sculpted design','Center drain'], '{"gallons": 65, "length_inches": 66, "material": "acrylic", "drain_location": "center"}', 'https://www.jacuzzi.com/bathtubs/lexia-soaking'),
  ('SIA6636ACR5CX', 'Sia 66" Freestanding Air Bath', 'Sia', 'freestanding', 70, 'gallons', 20, 4999, ARRAY['Freestanding','Air bath','Chromatherapy','Inline heater'], '{"gallons": 70, "length_inches": 66, "material": "acrylic", "drain_location": "center", "type": "air_bath"}', 'https://www.jacuzzi.com/bathtubs/sia-air-bath'),
  ('NOV6032WLR2XX', 'Nova 60" Alcove Soaking Tub', 'Nova', 'alcove', 42, 'gallons', 25, 399, ARRAY['60" alcove','Acrylic','Slip resistant','Left drain'], '{"gallons": 42, "length_inches": 60, "material": "acrylic", "drain_location": "left"}', 'https://www.jacuzzi.com/bathtubs/nova-soaking')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'jacuzzi' AND c.slug = 'bathtub';

-- Jacuzzi Shower Systems
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('SS728XXXX', 'Ristorre Shower Column', 'Ristorre', 'wall-mount', 2.5, 'gpm', 15, 399, ARRAY['Shower column','Rain showerhead','Handheld','Body jets'], '{"gpm": 2.5, "spray_settings": 4, "valve_type": "thermostatic"}', 'https://www.jacuzzi.com/shower-systems/ristorre'),
  ('SS748XXXX', 'Mincio Shower Tower', 'Mincio', 'wall-mount', 2.5, 'gpm', 15, 599, ARRAY['Shower tower','4 body jets','Rain head','Handheld'], '{"gpm": 2.5, "spray_settings": 6, "valve_type": "thermostatic"}', 'https://www.jacuzzi.com/shower-systems/mincio')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'jacuzzi' AND c.slug = 'shower-system';

-- Jacuzzi Toilets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, true, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('JC-4020', 'Maxima Elongated Two-Piece Toilet', 'Maxima', 'floor-mount', 1.28, 'gpf', 25, 299, ARRAY['Elongated','Comfort height','WaterSense','Slow-close seat'], '{"rough_in": 12, "flush_type": "gravity", "map_score": 800, "ada": true, "bowl_shape": "elongated"}', 'https://www.jacuzzi.com/toilets/maxima'),
  ('JC-4030', 'Perfecta One-Piece Elongated Toilet', 'Perfecta', 'floor-mount', 1.28, 'gpf', 25, 449, ARRAY['One-piece','Skirted design','Comfort height'], '{"rough_in": 12, "flush_type": "gravity", "map_score": 900, "ada": true, "bowl_shape": "elongated"}', 'https://www.jacuzzi.com/toilets/perfecta')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'jacuzzi' AND c.slug = 'toilet';


-- ============================================================================
-- LUXURY TIER
-- ============================================================================

-- ======================== BRIZO ========================

-- Brizo Bathroom Faucets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('65375LF-PC', 'Odin Widespread Faucet', 'Odin', 'deck-mount', 1.2, 'gpm', 15, 899, ARRAY['Widespread','Industrial design','Polished chrome','WaterSense'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.brizo.com/bathroom/65375LF-PC'),
  ('65035LF-PC', 'Litze Single-Handle Faucet', 'Litze', 'deck-mount', 1.2, 'gpm', 15, 599, ARRAY['Single handle','Arc spout','Chrome','WaterSense'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.brizo.com/bathroom/65035LF-PC'),
  ('65043LF-GL', 'Kintsu Single-Handle Faucet', 'Kintsu', 'deck-mount', 1.2, 'gpm', 15, 749, ARRAY['Japanese-inspired','Single handle','Luxe Gold','WaterSense'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "luxe_gold"}', 'https://www.brizo.com/bathroom/65043LF-GL'),
  ('65098LF-PC', 'Levoir Widespread Faucet', 'Levoir', 'deck-mount', 1.2, 'gpm', 15, 849, ARRAY['Widespread','Art Deco inspired','Chrome','WaterSense'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.brizo.com/bathroom/65098LF-PC'),
  ('T65897LF-PCLHP', 'Allaria Wall-Mount Faucet Trim', 'Allaria', 'wall-mount', 1.2, 'gpm', 15, 999, ARRAY['Wall mount','Two handle','Chrome','Less handles'], '{"gpm": 1.2, "holes": 0, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.brizo.com/bathroom/T65897LF-PCLHP'),
  ('68480-PC', 'Invari Vessel Faucet', 'Invari', 'deck-mount', 1.2, 'gpm', 15, 699, ARRAY['Vessel faucet','Open flow','Chrome','WaterSense'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.brizo.com/bathroom/68480-PC'),
  ('65006LF-PC', 'Jason Wu for Brizo Single Faucet', 'Jason Wu', 'deck-mount', 1.2, 'gpm', 15, 549, ARRAY['Designer collaboration','Single handle','Chrome','WaterSense'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.brizo.com/bathroom/65006LF-PC')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'brizo' AND c.slug = 'bathroom-faucet';

-- Brizo Shower Systems
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('87435-PC', 'Litze H2Okinetic Round Showerhead', 'Litze', 'wall-mount', 2.5, 'gpm', 20, 349, ARRAY['H2Okinetic','Round','Chrome','Sculpted wave pattern'], '{"gpm": 2.5, "spray_settings": 1, "valve_type": "pressure_balance"}', 'https://www.brizo.com/shower/87435-PC'),
  ('88835-PC', 'Kintsu 3-Function Showerhead', 'Kintsu', 'wall-mount', 2.5, 'gpm', 20, 499, ARRAY['3 spray functions','H2Okinetic','Chrome'], '{"gpm": 2.5, "spray_settings": 3, "valve_type": "pressure_balance"}', 'https://www.brizo.com/shower/88835-PC'),
  ('T75535-PC', 'Litze TempAssure Thermostatic Trim', 'Litze', 'wall-mount', 2.5, 'gpm', 20, 799, ARRAY['Thermostatic','Integrated diverter','6-function','Chrome'], '{"gpm": 2.5, "spray_settings": 6, "valve_type": "thermostatic"}', 'https://www.brizo.com/shower/T75535-PC'),
  ('81376-PC', 'Frank Lloyd Wright Raincan Showerhead', 'Frank Lloyd Wright', 'wall-mount', 2.5, 'gpm', 20, 599, ARRAY['14" square raincan','Chrome','Architectural design'], '{"gpm": 2.5, "spray_settings": 1, "head_diameter": 14}', 'https://www.brizo.com/shower/81376-PC'),
  ('84913-PC', 'Levoir H2Okinetic Body Spray', 'Levoir', 'wall-mount', 2.5, 'gpm', 20, 299, ARRAY['Body spray','H2Okinetic','Chrome','Adjustable'], '{"gpm": 2.5, "spray_settings": 1, "valve_type": "pressure_balance"}', 'https://www.brizo.com/shower/84913-PC')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'brizo' AND c.slug = 'shower-system';

-- ======================== DURAVIT ========================

-- Duravit Toilets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, true, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('2160010000', 'Starck 3 Wall-Mounted Toilet', 'Starck 3', 'wall-hung', 1.28, 'gpf', 25, false, 499, ARRAY['Philippe Starck design','Wall-hung','WonderGliss','Elongated'], '{"rough_in": 0, "flush_type": "rimless", "map_score": 800, "ada": true, "bowl_shape": "elongated", "wall_hung": true}', 'https://www.duravit.us/products/starck-3-toilet-wall-mounted-2160010000'),
  ('2169010000', 'ME by Starck Wall-Mounted Toilet', 'ME by Starck', 'wall-hung', 1.28, 'gpf', 25, false, 599, ARRAY['Philippe Starck design','Rimless flush','Wall-hung','WonderGliss'], '{"rough_in": 0, "flush_type": "rimless", "map_score": 800, "ada": true, "bowl_shape": "elongated", "wall_hung": true}', 'https://www.duravit.us/products/me-by-starck-toilet-wall-mounted-2169010000'),
  ('2157010085', 'DuraStyle One-Piece Toilet', 'DuraStyle', 'floor-mount', 1.28, 'gpf', 25, false, 799, ARRAY['One-piece','DualFlush','WonderGliss','Rimless'], '{"rough_in": 12, "flush_type": "rimless", "map_score": 800, "ada": true, "bowl_shape": "elongated"}', 'https://www.duravit.us/products/durastyle-one-piece-toilet-2157010085'),
  ('2588590092', 'Viu Rimless Wall-Mounted Toilet', 'Viu', 'wall-hung', 1.28, 'gpf', 25, false, 699, ARRAY['Rimless','Wall-hung','HygieneGlaze','Compact design'], '{"rough_in": 0, "flush_type": "rimless", "map_score": 800, "ada": true, "bowl_shape": "elongated", "wall_hung": true}', 'https://www.duravit.us/products/viu-toilet-wall-mounted-2588590092'),
  ('6120001001', 'SensoWash Starck f Plus Shower Toilet', 'SensoWash', 'floor-mount', 1.28, 'gpf', 25, true, 5499, ARRAY['Integrated bidet','Heated seat','Warm air dryer','Night light','Remote','Auto open/close'], '{"rough_in": 12, "flush_type": "rimless", "map_score": 800, "ada": true, "bowl_shape": "elongated", "bidet": true, "smart": true}', 'https://www.duravit.us/products/sensowash-starck-f-plus-shower-toilet'),
  ('2544090092', 'Happy D.2 Wall-Mounted Toilet', 'Happy D.2', 'wall-hung', 1.28, 'gpf', 25, false, 549, ARRAY['Art Deco inspired','Wall-hung','WonderGliss'], '{"rough_in": 0, "flush_type": "rimless", "map_score": 800, "ada": true, "bowl_shape": "elongated", "wall_hung": true}', 'https://www.duravit.us/products/happy-d-2-toilet-wall-mounted')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'duravit' AND c.slug = 'toilet';

-- Duravit Bathtubs
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('700336000000090', 'ME by Starck Freestanding Bathtub', 'ME by Starck', 'freestanding', 72, 'gallons', 25, 3999, ARRAY['Freestanding','Acrylic','Philippe Starck design','Center drain'], '{"gallons": 72, "length_inches": 67, "material": "acrylic", "drain_location": "center"}', 'https://www.duravit.us/products/me-by-starck-bathtub-freestanding'),
  ('700453000000090', 'Happy D.2 Plus Freestanding Bathtub', 'Happy D.2 Plus', 'freestanding', 66, 'gallons', 25, 4499, ARRAY['Freestanding','Mineral cast','Seamless panel','Art Deco'], '{"gallons": 66, "length_inches": 71, "material": "mineral_cast", "drain_location": "center"}', 'https://www.duravit.us/products/happy-d-2-plus-freestanding-bathtub'),
  ('700430000000090', 'DuraSquare Freestanding Bathtub', 'DuraSquare', 'freestanding', 68, 'gallons', 25, 5999, ARRAY['Freestanding','Geometric design','DuraSolid material','Metal console'], '{"gallons": 68, "length_inches": 73, "material": "durasolid", "drain_location": "center"}', 'https://www.duravit.us/products/durasquare-freestanding-bathtub'),
  ('700187000000090', 'DuraStyle 67" Bathtub', 'DuraStyle', 'alcove', 55, 'gallons', 25, 1499, ARRAY['67" x 29.5"','Acrylic','Back slope','Integrated panel'], '{"gallons": 55, "length_inches": 67, "material": "acrylic", "drain_location": "left"}', 'https://www.duravit.us/products/durastyle-bathtub'),
  ('700431000000090', 'Zencha Freestanding Bathtub', 'Zencha', 'freestanding', 70, 'gallons', 25, 7499, ARRAY['Japanese-inspired','Freestanding','DERA material','Ergonomic design'], '{"gallons": 70, "length_inches": 67, "material": "dera", "drain_location": "center"}', 'https://www.duravit.us/products/zencha-freestanding-bathtub')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'duravit' AND c.slug = 'bathtub';

-- Duravit Bathroom Faucets (through partnerships - C.1 and B-series)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('C11020002U10', 'C.1 Single-Handle Faucet', 'C.1', 'deck-mount', 1.2, 'gpm', 15, 399, ARRAY['Single handle','FreshStart cold start','MinusFlow','Chrome'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.duravit.us/products/c-1-single-handle-faucet'),
  ('B21020002U10', 'B.2 Single-Handle Faucet', 'B.2', 'deck-mount', 1.2, 'gpm', 15, 249, ARRAY['Single handle','FreshStart','Chrome','WaterSense'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.duravit.us/products/b-2-single-handle-faucet'),
  ('WA1080002U10', 'White Tulip Single-Handle Faucet', 'White Tulip', 'deck-mount', 1.2, 'gpm', 15, 699, ARRAY['Philippe Starck design','Single handle','Chrome','FreshStart'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.duravit.us/products/white-tulip-faucet')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'duravit' AND c.slug = 'bathroom-faucet';

-- Duravit Bidet
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, NULL, NULL, true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('610200001001', 'SensoWash Starck f Lite Bidet Seat', 'SensoWash', 'deck-mount', 15, true, 1299, ARRAY['Heated seat','Warm water','Body sensor','Night light','Stainless steel nozzle'], '{"heated_seat": true, "warm_water": true, "dryer": true, "remote": true, "deodorizer": false}', 'https://www.duravit.us/products/sensowash-starck-f-lite'),
  ('228415', 'ME by Starck Standalone Bidet', 'ME by Starck', 'floor-mount', 25, false, 499, ARRAY['Standalone bidet','Wall-hung','Philippe Starck design','WonderGliss'], '{"heated_seat": false, "warm_water": true, "dryer": false, "remote": false, "deodorizer": false}', 'https://www.duravit.us/products/me-by-starck-bidet')
) AS v(model_number, model_name, series, install, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'duravit' AND c.slug = 'bidet';


-- ============================================================================
-- ULTRA-LUXURY TIER
-- ============================================================================

-- ======================== WATERWORKS ========================

-- Waterworks Bathroom Faucets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('05-01254-98540', 'Henry Widespread Faucet', 'Henry', 'deck-mount', 1.2, 'gpm', 20, 2400, ARRAY['Metal cross handles','Nickel','Handcrafted','WaterSense'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "nickel"}', 'https://www.waterworks.com/henry-widespread-faucet'),
  ('05-28918-23710', 'Formwork Single-Handle Faucet', 'Formwork', 'deck-mount', 1.2, 'gpm', 20, 1800, ARRAY['Contemporary','Single handle','Chrome','Architectural'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.waterworks.com/formwork-single-handle-faucet'),
  ('05-06281-55321', '.25 Wall-Mounted Faucet', '.25', 'wall-mount', 1.2, 'gpm', 20, 3200, ARRAY['Wall mount','Cross handles','Nickel','Precision engineering'], '{"gpm": 1.2, "holes": 0, "valve_type": "ceramic_disc", "finish": "nickel"}', 'https://www.waterworks.com/25-wall-mounted-faucet'),
  ('05-41203-77901', 'Easton Classic Widespread Faucet', 'Easton Classic', 'deck-mount', 1.2, 'gpm', 20, 2800, ARRAY['Traditional design','Cross handles','Unlacquered brass'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "unlacquered_brass"}', 'https://www.waterworks.com/easton-classic-widespread'),
  ('05-73129-11445', 'Bond Sole Single-Handle Faucet', 'Bond Sole', 'deck-mount', 1.2, 'gpm', 20, 1600, ARRAY['Minimalist','Single lever','Chrome','Solid brass'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.waterworks.com/bond-sole-faucet')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'waterworks' AND c.slug = 'bathroom-faucet';

-- Waterworks Shower Systems
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('05-81324-55551', 'Henry Exposed Thermostatic Shower', 'Henry', 'wall-mount', 2.5, 'gpm', 20, 5500, ARRAY['Exposed thermostatic','Rain showerhead','Handshower','Cross handles'], '{"gpm": 2.5, "spray_settings": 2, "valve_type": "thermostatic"}', 'https://www.waterworks.com/henry-exposed-thermostatic'),
  ('05-92710-33218', '.25 Thermostatic Shower Trim', '.25', 'wall-mount', 2.5, 'gpm', 20, 3200, ARRAY['Thermostatic','10" rainhead','Cross handles','Nickel'], '{"gpm": 2.5, "spray_settings": 1, "valve_type": "thermostatic", "head_diameter": 10}', 'https://www.waterworks.com/25-thermostatic-shower')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'waterworks' AND c.slug = 'shower-system';

-- Waterworks Bathtubs
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('14-59182-91001', 'Empire Freestanding Oval Bathtub', 'Empire', 'freestanding', 75, 'gallons', 30, 8500, ARRAY['Cast iron','Freestanding','Ball-and-claw feet','Handpainted exterior option'], '{"gallons": 75, "length_inches": 68, "material": "cast_iron", "drain_location": "center"}', 'https://www.waterworks.com/empire-freestanding-bathtub'),
  ('14-67451-22019', 'Candide Freestanding Bathtub', 'Candide', 'freestanding', 70, 'gallons', 30, 12000, ARRAY['Freestanding','Volcanic limestone','Sculpted design','Center drain'], '{"gallons": 70, "length_inches": 66, "material": "volcanic_limestone", "drain_location": "center"}', 'https://www.waterworks.com/candide-freestanding-bathtub')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'waterworks' AND c.slug = 'bathtub';

-- ======================== DORNBRACHT ========================

-- Dornbracht Bathroom Faucets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('33505670-000010', 'Meta Single-Lever Lavatory Mixer', 'Meta', 'deck-mount', 1.2, 'gpm', 20, 1299, ARRAY['Single lever','Chrome','German engineering','WaterSense'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.dornbracht.com/meta-single-lever-mixer'),
  ('36717670-000010', 'Tara Wall-Mounted Lavatory Faucet', 'Tara', 'wall-mount', 1.2, 'gpm', 20, 2499, ARRAY['Wall mount','Cross handles','Chrome','Iconic design'], '{"gpm": 1.2, "holes": 0, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.dornbracht.com/tara-wall-mounted-faucet'),
  ('20713670-000010', 'Tara Three-Hole Lavatory Mixer', 'Tara', 'deck-mount', 1.2, 'gpm', 20, 2199, ARRAY['Widespread','Cross handles','Chrome','WaterSense'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.dornbracht.com/tara-three-hole-mixer'),
  ('33500670-060010', 'Meta Single-Lever Mixer Brushed Brass', 'Meta', 'deck-mount', 1.2, 'gpm', 20, 1599, ARRAY['Brushed brass','Single lever','WaterSense'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "brushed_brass"}', 'https://www.dornbracht.com/meta-brushed-brass'),
  ('33521670-000010', 'Lisse Single-Lever Lavatory Mixer', 'Lisse', 'deck-mount', 1.2, 'gpm', 20, 1399, ARRAY['Elegant curved design','Single lever','Chrome'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.dornbracht.com/lisse-single-lever-mixer')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'dornbracht' AND c.slug = 'bathroom-faucet';

-- Dornbracht Shower Systems
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('28575670-000010', 'Rain Sky E Ceiling-Mounted Rain Shower', 'Rain Sky', 'wall-mount', 2.5, 'gpm', 20, false, 8500, ARRAY['Ceiling-mounted','Water mist','Rain mode','Chromotherapy'], '{"gpm": 2.5, "spray_settings": 3, "valve_type": "thermostatic", "head_diameter": 24}', 'https://www.dornbracht.com/rain-sky-e'),
  ('36426670-000010', 'Tara Thermostatic Shower Trim', 'Tara', 'wall-mount', 2.5, 'gpm', 20, false, 3499, ARRAY['Thermostatic','Cross handles','Chrome','Two outlets'], '{"gpm": 2.5, "spray_settings": 2, "valve_type": "thermostatic"}', 'https://www.dornbracht.com/tara-thermostatic-shower'),
  ('26003670-000010', 'Comfort Shower Rain Showerhead 300', 'Comfort Shower', 'wall-mount', 2.5, 'gpm', 20, false, 1999, ARRAY['12" rain showerhead','2 spray modes','Chrome'], '{"gpm": 2.5, "spray_settings": 2, "head_diameter": 12}', 'https://www.dornbracht.com/comfort-shower-300'),
  ('AC0001-000010', 'Aquamoon ATT Ceiling Shower', 'Aquamoon', 'wall-mount', 2.5, 'gpm', 20, true, 18000, ARRAY['Ceiling panel','Multiple spray modes','Chromotherapy','Fog function','App controlled'], '{"gpm": 2.5, "spray_settings": 6, "valve_type": "digital_thermostatic", "smart": true}', 'https://www.dornbracht.com/aquamoon-att')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'dornbracht' AND c.slug = 'shower-system';

-- ======================== VICTORIA + ALBERT ========================

-- Victoria + Albert Bathtubs
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('NAP-N-SW-NO', 'Napoli Freestanding Bathtub', 'Napoli', 'freestanding', 72, 'gallons', 30, 6500, ARRAY['Freestanding','!"_QUARTZ material','Sculpted exterior','White'], '{"gallons": 72, "length_inches": 74, "material": "englishcast", "drain_location": "center"}', 'https://www.vandabaths.com/napoli-freestanding-bathtub'),
  ('AMT-N-SW-NO', 'Amalfi Freestanding Bathtub', 'Amalfi', 'freestanding', 60, 'gallons', 30, 5999, ARRAY['Freestanding','Double-ended','!"_QUARTZ','Organic form'], '{"gallons": 60, "length_inches": 64, "material": "englishcast", "drain_location": "center"}', 'https://www.vandabaths.com/amalfi-freestanding-bathtub'),
  ('BAR-N-SW-NO', 'Barcelona Freestanding Bathtub', 'Barcelona', 'freestanding', 65, 'gallons', 30, 4999, ARRAY['Modern freestanding','Double-ended','!"_QUARTZ','Center drain'], '{"gallons": 65, "length_inches": 67, "material": "englishcast", "drain_location": "center"}', 'https://www.vandabaths.com/barcelona-freestanding-bathtub'),
  ('IOS-N-SW-NO', 'Ios Freestanding Bathtub', 'Ios', 'freestanding', 80, 'gallons', 30, 7999, ARRAY['Asymmetric design','Freestanding','ENGLISHCAST','Sculpted backrest'], '{"gallons": 80, "length_inches": 60, "material": "englishcast", "drain_location": "center"}', 'https://www.vandabaths.com/ios-freestanding-bathtub'),
  ('MAR-N-SW-NO', 'Mozzano Freestanding Bathtub', 'Mozzano', 'freestanding', 55, 'gallons', 30, 5499, ARRAY['Compact freestanding','Slipper style','ENGLISHCAST','Center drain'], '{"gallons": 55, "length_inches": 65, "material": "englishcast", "drain_location": "center"}', 'https://www.vandabaths.com/mozzano-freestanding-bathtub')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'victoria-albert' AND c.slug = 'bathtub';


-- ============================================================================
-- ADDITIONAL MODELS TO REACH 350+ TARGET
-- ============================================================================

-- ======================== ADDITIONAL KOHLER ========================

-- Kohler Additional Toilets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, true, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('K-3589', 'Cimarron Comfort Height Two-Piece Round Toilet', 'Cimarron', 'floor-mount', 1.28, 'gpf', 25, 249, ARRAY['Round front','Comfort Height','AquaPiston','Class Five'], '{"rough_in": 12, "flush_type": "gravity", "map_score": 1000, "ada": true, "bowl_shape": "round"}', 'https://www.us.kohler.com/us/K-3589'),
  ('K-78080', 'Reach Comfort Height One-Piece Toilet', 'Reach', 'floor-mount', 1.28, 'gpf', 25, 599, ARRAY['One-piece','Skirted trapway','Comfort Height','ReadyLock install'], '{"rough_in": 12, "flush_type": "gravity", "map_score": 1000, "ada": true, "bowl_shape": "elongated"}', 'https://www.us.kohler.com/us/K-78080'),
  ('K-4007', 'Wellworth Two-Piece Round Toilet', 'Wellworth', 'floor-mount', 1.28, 'gpf', 25, 199, ARRAY['Round front','Class Five','Entry-level'], '{"rough_in": 12, "flush_type": "gravity", "map_score": 800, "ada": false, "bowl_shape": "round"}', 'https://www.us.kohler.com/us/K-4007'),
  ('K-5310', 'Cimarron Skirted Comfort Height Toilet', 'Cimarron', 'floor-mount', 1.28, 'gpf', 25, 399, ARRAY['Skirted trapway','Comfort Height','AquaPiston','Elongated'], '{"rough_in": 12, "flush_type": "gravity", "map_score": 1000, "ada": true, "bowl_shape": "elongated"}', 'https://www.us.kohler.com/us/K-5310'),
  ('K-3988', 'Wellworth Dual Flush Two-Piece Toilet', 'Wellworth', 'floor-mount', 1.1, 'gpf', 25, 249, ARRAY['Dual flush 1.1/1.6','Elongated','WaterSense'], '{"rough_in": 12, "flush_type": "dual_flush", "map_score": 800, "ada": false, "bowl_shape": "elongated"}', 'https://www.us.kohler.com/us/K-3988'),
  ('K-20204', 'Betello Comfort Height Skirted Toilet', 'Betello', 'floor-mount', 1.28, 'gpf', 25, 799, ARRAY['One-piece','Skirted','ContinuousClean','Comfort Height'], '{"rough_in": 12, "flush_type": "gravity", "map_score": 1000, "ada": true, "bowl_shape": "elongated"}', 'https://www.us.kohler.com/us/K-20204')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'kohler' AND c.slug = 'toilet';

-- Kohler Additional Faucets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('K-27415-4', 'Riff Single-Handle Bathroom Faucet', 'Riff', 'deck-mount', 1.2, 'gpm', 15, 249, ARRAY['Single handle','Chrome','Organic design','WaterSense'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.us.kohler.com/us/K-27415-4'),
  ('K-22022-4', 'Tempered Single-Handle Faucet', 'Tempered', 'deck-mount', 1.2, 'gpm', 15, 329, ARRAY['Single handle','Contemporary','Chrome'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.us.kohler.com/us/K-22022-4'),
  ('K-16232-4', 'Margaux Widespread Faucet', 'Margaux', 'deck-mount', 1.2, 'gpm', 15, 699, ARRAY['Widespread','Cross handles','Traditional','Chrome'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.us.kohler.com/us/K-16232-4')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'kohler' AND c.slug = 'bathroom-faucet';

-- Kohler Additional Bathtubs
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('K-715', 'Villager 60" Cast Iron Bath', 'Villager', 'alcove', 46, 'gallons', 30, 599, ARRAY['60" x 31"','Cast iron','Left drain','Durable enamel'], '{"gallons": 46, "length_inches": 60, "material": "cast_iron", "drain_location": "left"}', 'https://www.us.kohler.com/us/K-715'),
  ('K-1947', 'Archer 66" Freestanding Soaking Bath', 'Archer', 'freestanding', 65, 'gallons', 25, 2999, ARRAY['66" freestanding','Acrylic','Lumbar support','Center drain'], '{"gallons": 65, "length_inches": 66, "material": "acrylic", "drain_location": "center"}', 'https://www.us.kohler.com/us/K-1947'),
  ('K-1490-HB', 'Memoirs 60" Whirlpool Bath', 'Memoirs', 'drop-in', 62, 'gallons', 20, 3499, ARRAY['60" x 42"','8 adjustable jets','Heater','BubbleMassage'], '{"gallons": 62, "length_inches": 60, "material": "acrylic", "drain_location": "center", "jets": 8, "type": "whirlpool"}', 'https://www.us.kohler.com/us/K-1490-HB'),
  ('K-894', 'Reve 67" Freestanding Bath', 'Reve', 'freestanding', 63, 'gallons', 25, 4299, ARRAY['67" freestanding','Lithocast','Solid surface','Modern'], '{"gallons": 63, "length_inches": 67, "material": "lithocast", "drain_location": "center"}', 'https://www.us.kohler.com/us/K-894')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'kohler' AND c.slug = 'bathtub';

-- ======================== ADDITIONAL TOTO ========================

-- TOTO Additional Toilets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, true, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('MS854114EL', 'UltraMax One-Piece Elongated Toilet', 'UltraMax', 'floor-mount', 1.28, 'gpf', 25, false, 479, ARRAY['One-piece','E-Max flush','Elongated','SanaGloss'], '{"rough_in": 12, "flush_type": "gravity", "map_score": 800, "ada": true, "bowl_shape": "elongated"}', 'https://www.totousa.com/ultramax-one-piece-elongated-toilet'),
  ('MS494124CEMFG', 'Connelly Two-Piece Elongated Dual Flush Toilet', 'Connelly', 'floor-mount', 0.9, 'gpf', 25, false, 599, ARRAY['Dual flush','Tornado Flush','CeFiONtect','Skirted'], '{"rough_in": 12, "flush_type": "tornado_dual", "map_score": 1000, "ada": true, "bowl_shape": "elongated"}', 'https://www.totousa.com/connelly-two-piece-toilet'),
  ('CST243EF', 'Entrada Close Coupled Elongated Toilet', 'Entrada', 'floor-mount', 1.28, 'gpf', 25, false, 199, ARRAY['Elongated','Entry-level','WaterSense','E-Max'], '{"rough_in": 12, "flush_type": "gravity", "map_score": 600, "ada": false, "bowl_shape": "elongated"}', 'https://www.totousa.com/entrada-close-coupled-toilet'),
  ('MS442124CUFG', 'Nexus 1G Two-Piece Elongated Toilet', 'Nexus', 'floor-mount', 1.0, 'gpf', 25, false, 549, ARRAY['1.0 GPF ultra-efficient','Tornado Flush','CeFiONtect','DERA PREMIIST'], '{"rough_in": 12, "flush_type": "tornado", "map_score": 800, "ada": true, "bowl_shape": "elongated"}', 'https://www.totousa.com/nexus-1g-two-piece-toilet'),
  ('MS624234CEFG', 'Legato One-Piece Elongated Toilet', 'Legato', 'floor-mount', 1.28, 'gpf', 25, false, 799, ARRAY['One-piece','Skirted design','Tornado Flush','CeFiONtect'], '{"rough_in": 12, "flush_type": "tornado", "map_score": 1000, "ada": true, "bowl_shape": "elongated"}', 'https://www.totousa.com/legato-one-piece-toilet')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'toto' AND c.slug = 'toilet';

-- TOTO Shower Systems
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('TBW01003U4', 'G Series Round Showerhead', 'G Series', 'wall-mount', 2.5, 'gpm', 20, 499, ARRAY['8.5" round','COMFORT WAVE spray','Chrome'], '{"gpm": 2.5, "spray_settings": 2, "head_diameter": 8.5}', 'https://www.totousa.com/g-series-round-showerhead'),
  ('TBW02004U4', 'G Series Square Showerhead', 'G Series', 'wall-mount', 2.5, 'gpm', 20, 599, ARRAY['10" square','WARM SPA spray','Chrome'], '{"gpm": 2.5, "spray_settings": 2, "head_diameter": 10}', 'https://www.totousa.com/g-series-square-showerhead'),
  ('TS930D', 'Lloyd Thermostatic Mixing Valve Trim', 'Lloyd', 'wall-mount', 2.5, 'gpm', 20, 349, ARRAY['Thermostatic','Lever handle','Chrome'], '{"gpm": 2.5, "spray_settings": 1, "valve_type": "thermostatic"}', 'https://www.totousa.com/lloyd-thermostatic-trim')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'toto' AND c.slug = 'shower-system';

-- ======================== ADDITIONAL MOEN ========================

-- Moen Additional Faucets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('T6420', 'Belfield Widespread Faucet', 'Belfield', 'deck-mount', 1.2, 'gpm', 15, 329, ARRAY['Widespread','Traditional','Chrome','WaterSense'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome", "cartridge": "1224"}', 'https://www.moen.com/products/Belfield/T6420'),
  ('S6981', 'Cia Single-Handle Faucet', 'Cia', 'deck-mount', 1.2, 'gpm', 15, 209, ARRAY['Single handle','Modern','Spot Resist brushed nickel'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "brushed_nickel", "cartridge": "1222"}', 'https://www.moen.com/products/Cia/S6981'),
  ('S6910', 'Doux Single-Handle Faucet', 'Doux', 'deck-mount', 1.2, 'gpm', 15, 275, ARRAY['Single handle','Slim profile','Chrome','WaterSense'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome", "cartridge": "1222"}', 'https://www.moen.com/products/Doux/S6910'),
  ('84115', 'Adler Centerset Faucet', 'Adler', 'deck-mount', 1.2, 'gpm', 15, 79, ARRAY['Centerset','Chrome','Budget-friendly','WaterSense'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.moen.com/products/Adler/84115'),
  ('TS8903', 'Doux Collection Wall Mount Vessel Faucet', 'Doux', 'wall-mount', 1.2, 'gpm', 15, 449, ARRAY['Wall mount','Vessel','Chrome','Modern'], '{"gpm": 1.2, "holes": 0, "valve_type": "ceramic_disc", "finish": "chrome", "cartridge": "1222"}', 'https://www.moen.com/products/Doux/TS8903')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'moen' AND c.slug = 'bathroom-faucet';

-- Moen Bathtubs
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('S3880EP', 'Doux Freestanding Bathtub', 'Doux', 'freestanding', 61, 'gallons', 25, 2499, ARRAY['Freestanding','Acrylic','Sculpted design','Center drain'], '{"gallons": 61, "length_inches": 60, "material": "acrylic", "drain_location": "center"}', 'https://www.moen.com/products/Doux/S3880EP')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'moen' AND c.slug = 'bathtub';

-- ======================== ADDITIONAL DELTA ========================

-- Delta Additional Faucets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('25776LF', 'Stryke Widespread Faucet', 'Stryke', 'deck-mount', 1.2, 'gpm', 15, 499, ARRAY['Widespread','Helo handles','Chrome','Diamond Seal'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.deltafaucet.com/bathroom/25776LF'),
  ('15984LF-SS', 'Peerless Claymore Centerset Faucet', 'Claymore', 'deck-mount', 1.2, 'gpm', 15, 65, ARRAY['Centerset','Stainless','Budget option'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "stainless"}', 'https://www.deltafaucet.com/bathroom/15984LF-SS'),
  ('520-MPU-DST', 'Linden Single-Handle Centerset Faucet', 'Linden', 'deck-mount', 1.2, 'gpm', 15, 175, ARRAY['Single handle','Chrome','Diamond Seal','WaterSense'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.deltafaucet.com/bathroom/520-MPU-DST'),
  ('3553LF', 'Vero Widespread Faucet', 'Vero', 'deck-mount', 1.2, 'gpm', 15, 389, ARRAY['Widespread','Angular design','Chrome','Diamond Seal'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.deltafaucet.com/bathroom/3553LF'),
  ('552LF', 'Tesla Single-Handle Faucet', 'Tesla', 'deck-mount', 1.2, 'gpm', 15, 295, ARRAY['Single handle','Modern geometric','Chrome','Diamond Seal'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.deltafaucet.com/bathroom/552LF')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'delta-faucet' AND c.slug = 'bathroom-faucet';

-- Delta Additional Showers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('T14253', 'Vero Monitor 14 Shower Trim', 'Vero', 'wall-mount', 2.5, 'gpm', 20, 199, ARRAY['Monitor 14','Angular design','Chrome'], '{"gpm": 2.5, "spray_settings": 1, "valve_type": "pressure_balance", "rough_in_valve": "R10000"}', 'https://www.deltafaucet.com/shower/T14253'),
  ('57085', 'HydroRain 2-in-1 Showerhead', 'HydroRain', 'wall-mount', 2.5, 'gpm', 20, 119, ARRAY['2-in-1','H2Okinetic','5 spray settings','Rain shower + hand shower'], '{"gpm": 2.5, "spray_settings": 5, "valve_type": "pressure_balance"}', 'https://www.deltafaucet.com/shower/57085'),
  ('T17T264-SS', 'Ashlyn TempAssure 17T Shower Trim', 'Ashlyn', 'wall-mount', 2.5, 'gpm', 20, 355, ARRAY['TempAssure thermostatic','Stainless','H2Okinetic'], '{"gpm": 2.5, "spray_settings": 1, "valve_type": "thermostatic", "rough_in_valve": "R10000"}', 'https://www.deltafaucet.com/shower/T17T264-SS')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'delta-faucet' AND c.slug = 'shower-system';

-- ======================== ADDITIONAL AMERICAN STANDARD ========================

-- American Standard Additional Toilets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, true, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('2467016.020', 'Cadet 3 Tall Height Round Toilet', 'Cadet 3', 'floor-mount', 1.28, 'gpf', 25, 199, ARRAY['Round front','Right height','Slow-close seat'], '{"rough_in": 12, "flush_type": "gravity", "map_score": 700, "ada": true, "bowl_shape": "round"}', 'https://www.americanstandard.com/bathrooms/toilets/2467016.020'),
  ('2886218.020', 'H2Optimum Siphonic Round Toilet', 'H2Optimum', 'floor-mount', 1.1, 'gpf', 25, 279, ARRAY['1.1 GPF ultra-efficient','Round front','WaterSense'], '{"rough_in": 12, "flush_type": "siphonic", "map_score": 600, "ada": false, "bowl_shape": "round"}', 'https://www.americanstandard.com/bathrooms/toilets/2886218.020'),
  ('2514101S.020', 'Edgemere Right Height Elongated Toilet', 'Edgemere', 'floor-mount', 1.28, 'gpf', 25, 219, ARRAY['Right height','Elongated','PowerWash','WaterSense'], '{"rough_in": 12, "flush_type": "gravity", "map_score": 800, "ada": true, "bowl_shape": "elongated"}', 'https://www.americanstandard.com/bathrooms/toilets/2514101S.020')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'american-standard' AND c.slug = 'toilet';

-- American Standard Bidet
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, NULL, NULL, true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('8012A80GRC-020', 'Advanced Clean 2.0 SpaLet Bidet Seat', 'SpaLet', 'deck-mount', 15, true, 899, ARRAY['Remote control','Heated seat','Warm water','Dryer','Night light','Deodorizer'], '{"heated_seat": true, "warm_water": true, "dryer": true, "remote": true, "deodorizer": true}', 'https://www.americanstandard.com/bathrooms/bidet-seats/8012A80GRC-020'),
  ('5900A05G.020', 'AquaWash 1.0 Non-Electric Bidet Seat', 'AquaWash', 'deck-mount', 15, false, 129, ARRAY['Non-electric','Dual nozzle','Self-cleaning','Adjustable pressure'], '{"heated_seat": false, "warm_water": false, "dryer": false, "remote": false, "deodorizer": false}', 'https://www.americanstandard.com/bathrooms/bidet-seats/5900A05G.020')
) AS v(model_number, model_name, series, install, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'american-standard' AND c.slug = 'bidet';

-- ======================== ADDITIONAL GROHE ========================

-- Grohe Bathtubs
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('39664000', 'Essence Freestanding Bathtub', 'Essence', 'freestanding', 62, 'gallons', 25, 3499, ARRAY['Freestanding','Acrylic','Slim rim design','Center drain'], '{"gallons": 62, "length_inches": 67, "material": "acrylic", "drain_location": "center"}', 'https://www.grohe.com/us/39664000'),
  ('39665000', 'Eurocube Alcove Bathtub', 'Eurocube', 'alcove', 48, 'gallons', 25, 1299, ARRAY['60" x 32"','Acrylic','Angular design','Left drain'], '{"gallons": 48, "length_inches": 60, "material": "acrylic", "drain_location": "left"}', 'https://www.grohe.com/us/39665000')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'grohe' AND c.slug = 'bathtub';

-- Grohe Bidet
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, NULL, NULL, true, v.lifespan, v.wifi, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('39667000', 'Sensia Arena Shower Toilet', 'Sensia Arena', 'floor-mount', 25, true, 4999, ARRAY['Integrated bidet','Heated seat','Warm water','Dryer','Night light','Auto flush','Remote'], '{"heated_seat": true, "warm_water": true, "dryer": true, "remote": true, "deodorizer": true}', 'https://www.grohe.com/us/39667000'),
  ('39354000', 'Manual Bidet Seat', 'DERA', 'deck-mount', 15, false, 299, ARRAY['Non-electric','Dual nozzle','Self-cleaning','Chrome controls'], '{"heated_seat": false, "warm_water": false, "dryer": false, "remote": false, "deodorizer": false}', 'https://www.grohe.com/us/39354000')
) AS v(model_number, model_name, series, install, lifespan, wifi, msrp, features, specs, url)
WHERE m.slug = 'grohe' AND c.slug = 'bidet';

-- ======================== ADDITIONAL HANSGROHE ========================

-- Hansgrohe Bathtubs
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('11440001', 'Axor Urquiola Freestanding Bathtub', 'Axor Urquiola', 'freestanding', 75, 'gallons', 25, 8999, ARRAY['Freestanding','Designer Patricia Urquiola','Mineral cast','Premium'], '{"gallons": 75, "length_inches": 71, "material": "mineral_cast", "drain_location": "center"}', 'https://www.hansgrohe-usa.com/11440001')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'hansgrohe' AND c.slug = 'bathtub';

-- Hansgrohe Additional Faucets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('04180000', 'Allegro E Centerset Faucet', 'Allegro E', 'deck-mount', 1.2, 'gpm', 15, 179, ARRAY['Centerset','Chrome','WaterSense','EcoRight'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.hansgrohe-usa.com/04180000'),
  ('72130001', 'Finoris Single-Hole Faucet', 'Finoris', 'deck-mount', 1.2, 'gpm', 15, 399, ARRAY['Single hole','Push-open drain','Chrome','CoolStart'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.hansgrohe-usa.com/72130001'),
  ('39170001', 'Axor Citterio E Widespread Faucet', 'Axor Citterio E', 'deck-mount', 1.2, 'gpm', 15, 999, ARRAY['Widespread','Designer Antonio Citterio','Chrome'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.hansgrohe-usa.com/39170001')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'hansgrohe' AND c.slug = 'bathroom-faucet';

-- ======================== ADDITIONAL GLACIER BAY ========================

-- Glacier Bay Additional Faucets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('HD67738W-6B04', 'Dorset 8-inch Widespread Faucet', 'Dorset', 'deck-mount', 1.2, 'gpm', 10, 89, ARRAY['Widespread','Two handle','Chrome','Pop-up drain'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.homedepot.com/p/Glacier-Bay-Dorset-Widespread/'),
  ('HD67774W-6001', 'Hali 8-inch Widespread Faucet', 'Hali', 'deck-mount', 1.2, 'gpm', 10, 109, ARRAY['Widespread','Brushed nickel','WaterSense'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "brushed_nickel"}', 'https://www.homedepot.com/p/Glacier-Bay-Hali-Widespread/'),
  ('HD67395-6004', 'Edgewood Single-Handle Faucet', 'Edgewood', 'deck-mount', 1.2, 'gpm', 10, 55, ARRAY['Single handle','Chrome','WaterSense','Value'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.homedepot.com/p/Glacier-Bay-Edgewood/')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'glacier-bay' AND c.slug = 'bathroom-faucet';

-- ======================== ADDITIONAL PFISTER ========================

-- Pfister Additional Faucets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('LG49-LS0C', 'Ladera Single-Handle Faucet', 'Ladera', 'deck-mount', 1.2, 'gpm', 15, 89, ARRAY['Single handle','Chrome','Pforever Seal','Value'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.pfisterfaucets.com/bathroom/LG49-LS0C'),
  ('LF-048-JDCC', 'Jaida Centerset Faucet', 'Jaida', 'deck-mount', 1.2, 'gpm', 15, 69, ARRAY['Centerset','Chrome','WaterSense','Pop-up drain'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.pfisterfaucets.com/bathroom/LF-048-JDCC'),
  ('LG49-MG0C', 'Masey Single-Handle Faucet', 'Masey', 'deck-mount', 1.2, 'gpm', 15, 109, ARRAY['Single handle','Chrome','Spot Defense'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.pfisterfaucets.com/bathroom/LG49-MG0C'),
  ('LG42-TS0K', 'Tenet Widespread Faucet', 'Tenet', 'deck-mount', 1.2, 'gpm', 15, 349, ARRAY['Widespread','Matte black','Contemporary','WaterSense'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "matte_black"}', 'https://www.pfisterfaucets.com/bathroom/LG42-TS0K')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'pfister' AND c.slug = 'bathroom-faucet';

-- ======================== ADDITIONAL BRIZO ========================

-- Brizo Bathtubs (Freestanding Tub Fillers)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('T70135-PC', 'Litze Freestanding Tub Filler', 'Litze', 'freestanding', 7.0, 'gpm', 20, 2199, ARRAY['Freestanding tub filler','H2Okinetic handshower','Chrome'], '{"gpm": 7.0, "spray_settings": 2, "valve_type": "pressure_balance"}', 'https://www.brizo.com/tub-fillers/T70135-PC'),
  ('T70198-PC', 'Levoir Freestanding Tub Filler', 'Levoir', 'freestanding', 7.0, 'gpm', 20, 2499, ARRAY['Freestanding tub filler','Handshower','Art Deco design'], '{"gpm": 7.0, "spray_settings": 2, "valve_type": "pressure_balance"}', 'https://www.brizo.com/tub-fillers/T70198-PC')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'brizo' AND c.slug = 'shower-system';

-- ======================== ADDITIONAL DURAVIT ========================

-- Duravit Additional Toilets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, true, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('2170010000', 'Starck 2 One-Piece Toilet', 'Starck 2', 'floor-mount', 1.28, 'gpf', 25, 899, ARRAY['One-piece','Philippe Starck design','WonderGliss','Elongated'], '{"rough_in": 12, "flush_type": "gravity", "map_score": 800, "ada": true, "bowl_shape": "elongated"}', 'https://www.duravit.us/products/starck-2-one-piece-toilet'),
  ('2172010001', 'White Tulip Floor-Standing Toilet', 'White Tulip', 'floor-mount', 1.28, 'gpf', 25, 1199, ARRAY['Philippe Starck design','Rimless','HygieneGlaze','Elongated'], '{"rough_in": 12, "flush_type": "rimless", "map_score": 800, "ada": true, "bowl_shape": "elongated"}', 'https://www.duravit.us/products/white-tulip-floor-standing-toilet'),
  ('2576090092', 'D-Neo Wall-Mounted Toilet', 'D-Neo', 'wall-hung', 1.28, 'gpf', 25, 399, ARRAY['Wall-hung','Rimless','HygieneGlaze','Budget Duravit'], '{"rough_in": 0, "flush_type": "rimless", "map_score": 800, "ada": true, "bowl_shape": "elongated", "wall_hung": true}', 'https://www.duravit.us/products/d-neo-wall-mounted-toilet')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'duravit' AND c.slug = 'toilet';

-- ======================== ADDITIONAL WATERWORKS ========================

-- Waterworks Additional Faucets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('05-87126-33401', 'R.W. Atlas Widespread Faucet', 'R.W. Atlas', 'deck-mount', 1.2, 'gpm', 20, 2600, ARRAY['Widespread','Lever handles','Nickel','Handcrafted'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "nickel"}', 'https://www.waterworks.com/rw-atlas-widespread'),
  ('05-52419-88201', 'Regulator Gooseneck Faucet', 'Regulator', 'deck-mount', 1.2, 'gpm', 20, 3500, ARRAY['Gooseneck spout','Cross handles','Industrial design','Burnished brass'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "burnished_brass"}', 'https://www.waterworks.com/regulator-gooseneck-faucet')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'waterworks' AND c.slug = 'bathroom-faucet';

-- ======================== ADDITIONAL VICTORIA + ALBERT ========================

-- Victoria + Albert Additional Bathtubs
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('HAM-N-SW-NO', 'Hampshire Freestanding Bathtub', 'Hampshire', 'freestanding', 78, 'gallons', 30, 6999, ARRAY['Classic clawfoot','Cast iron core','ENGLISHCAST','Ball-and-claw feet'], '{"gallons": 78, "length_inches": 67, "material": "englishcast", "drain_location": "center"}', 'https://www.vandabaths.com/hampshire-freestanding-bathtub'),
  ('ELW-N-SW-NO', 'Elwick Freestanding Bathtub', 'Elwick', 'freestanding', 68, 'gallons', 30, 5799, ARRAY['Double-ended','Freestanding','ENGLISHCAST','Modern classic'], '{"gallons": 68, "length_inches": 75, "material": "englishcast", "drain_location": "center"}', 'https://www.vandabaths.com/elwick-freestanding-bathtub'),
  ('TBB-N-SW-NO', 'Tubo Freestanding Bathtub', 'Tubo', 'freestanding', 50, 'gallons', 30, 5499, ARRAY['Compact freestanding','Japanese soaking','ENGLISHCAST','Deep soak'], '{"gallons": 50, "length_inches": 51, "material": "englishcast", "drain_location": "center"}', 'https://www.vandabaths.com/tubo-freestanding-bathtub')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'victoria-albert' AND c.slug = 'bathtub';

-- ======================== ADDITIONAL DORNBRACHT ========================

-- Dornbracht Bathtub (Tub filler)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('25963670-000010', 'Tara Freestanding Tub Filler', 'Tara', 'freestanding', 7.0, 'gpm', 20, 5999, ARRAY['Freestanding tub filler','Cross handles','Handshower','Chrome'], '{"gpm": 7.0, "spray_settings": 2, "valve_type": "pressure_balance"}', 'https://www.dornbracht.com/tara-freestanding-tub-filler'),
  ('25963845-000010', 'Meta Freestanding Tub Filler', 'Meta', 'freestanding', 7.0, 'gpm', 20, 4999, ARRAY['Freestanding tub filler','Lever handle','Chrome','Handshower'], '{"gpm": 7.0, "spray_settings": 2, "valve_type": "pressure_balance"}', 'https://www.dornbracht.com/meta-freestanding-tub-filler')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'dornbracht' AND c.slug = 'shower-system';

-- ======================== ADDITIONAL KRAUS ========================

-- Kraus Additional Faucets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('FUS-1821CH', 'Arlo Widespread Faucet', 'Arlo', 'deck-mount', 1.2, 'gpm', 15, 179, ARRAY['Widespread','Chrome','Reach technology','WaterSense'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.kraususa.com/bathroom-faucets/FUS-1821CH'),
  ('KBF-1501CH', 'Esta Single-Handle Faucet', 'Esta', 'deck-mount', 1.2, 'gpm', 15, 99, ARRAY['Single handle','Chrome','Lift rod drain','WaterSense'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.kraususa.com/bathroom-faucets/KBF-1501CH'),
  ('KBF-1300SFS', 'Arlo Single-Handle Faucet Stainless', 'Arlo', 'deck-mount', 1.2, 'gpm', 15, 99, ARRAY['Single handle','Spot Free Stainless','WaterSense'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "stainless"}', 'https://www.kraususa.com/bathroom-faucets/KBF-1300SFS')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'kraus' AND c.slug = 'bathroom-faucet';

-- ======================== ADDITIONAL SYMMONS ========================

-- Symmons Additional Shower Systems
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('S-3600-TRM', 'Duro Shower/Tub Trim Kit', 'Duro', 'wall-mount', 2.5, 'gpm', 20, 249, ARRAY['Tub and shower','Temptrol','Chrome'], '{"gpm": 2.5, "spray_settings": 1, "valve_type": "pressure_balance"}', 'https://www.symmons.com/product/S-3600-TRM'),
  ('S-2502-TRM', 'Canterbury Shower Trim', 'Canterbury', 'wall-mount', 2.5, 'gpm', 20, 175, ARRAY['Classic design','Temptrol','Chrome'], '{"gpm": 2.5, "spray_settings": 1, "valve_type": "pressure_balance"}', 'https://www.symmons.com/product/S-2502-TRM')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'symmons' AND c.slug = 'shower-system';

-- ======================== ADDITIONAL PEERLESS ========================

-- Peerless Additional Faucets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('P99174LF-BN', 'Claymore Single-Handle Faucet', 'Claymore', 'deck-mount', 1.2, 'gpm', 10, 65, ARRAY['Single handle','Brushed nickel','WaterSense'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "brushed_nickel"}', 'https://www.peerlessfaucet.com/bathroom/P99174LF-BN'),
  ('P130LF', 'Classic Two-Handle Centerset Faucet', 'Classic', 'deck-mount', 1.2, 'gpm', 10, 29, ARRAY['Two handle','Chrome','Budget option'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.peerlessfaucet.com/bathroom/P130LF')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'peerless-faucet' AND c.slug = 'bathroom-faucet';

-- ======================== ADDITIONAL STERLING ========================

-- Sterling Additional Bathtubs
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('71101120-0', 'Lawson 60" Whirlpool Tub', 'Lawson', 'alcove', 52, 'gallons', 20, 899, ARRAY['60" x 32"','8 jets','Vikrell','Left drain'], '{"gallons": 52, "length_inches": 60, "material": "vikrell", "drain_location": "left", "jets": 8, "type": "whirlpool"}', 'https://www.sterlingplumbing.com/bathing/bathtubs/71101120-0'),
  ('71161110-0', 'Acclaim 60" Bathtub', 'Acclaim', 'alcove', 44, 'gallons', 25, 259, ARRAY['60" x 30"','Vikrell','Right drain','Slip resistant floor'], '{"gallons": 44, "length_inches": 60, "material": "vikrell", "drain_location": "right"}', 'https://www.sterlingplumbing.com/bathing/bathtubs/71161110-0')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'sterling' AND c.slug = 'bathtub';

-- ======================== ADDITIONAL MOEN SHOWERS ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('TS3302BL', 'Align M-CORE 3-Series Matte Black', 'Align', 'wall-mount', 2.5, 'gpm', 20, 295, ARRAY['3-Series valve','Matte black','Single handle'], '{"gpm": 2.5, "spray_settings": 1, "valve_type": "pressure_balance", "rough_in_valve": "2570"}', 'https://www.moen.com/products/Align/TS3302BL'),
  ('S6340', 'Velocity 8" Square Rainshower', 'Velocity', 'wall-mount', 2.5, 'gpm', 20, 349, ARRAY['8" square rainshower','Immersion technology','Chrome'], '{"gpm": 2.5, "spray_settings": 2, "head_diameter": 8}', 'https://www.moen.com/products/Velocity/S6340'),
  ('TS2712', 'Genta Single-Handle Shower Trim', 'Genta', 'wall-mount', 2.5, 'gpm', 20, 149, ARRAY['Posi-Temp','Single handle','Chrome','Value'], '{"gpm": 2.5, "spray_settings": 1, "valve_type": "pressure_balance", "rough_in_valve": "2520"}', 'https://www.moen.com/products/Genta/TS2712')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'moen' AND c.slug = 'shower-system';

-- ======================== ADDITIONAL JACUZZI ========================

-- Jacuzzi Additional Bathtubs
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('LIN6636WCR2XX', 'Linea 66" x 36" Whirlpool Tub', 'Linea', 'drop-in', 85, 'gallons', 20, 2799, ARRAY['8 jets','Whirlpool','Heater','Center drain'], '{"gallons": 85, "length_inches": 66, "material": "acrylic", "drain_location": "center", "jets": 8, "type": "whirlpool"}', 'https://www.jacuzzi.com/bathtubs/linea-whirlpool'),
  ('BEL6636ACR5CX', 'Bellavista 66" Air Bath', 'Bellavista', 'freestanding', 68, 'gallons', 20, 3799, ARRAY['Air bath','Freestanding','Heated air jets','Chromatherapy'], '{"gallons": 68, "length_inches": 66, "material": "acrylic", "drain_location": "center", "type": "air_bath"}', 'https://www.jacuzzi.com/bathtubs/bellavista-air-bath')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'jacuzzi' AND c.slug = 'bathtub';

-- Jacuzzi Bathroom Faucets
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('MZ20826', 'Duncan Widespread Faucet', 'Duncan', 'deck-mount', 1.2, 'gpm', 15, 179, ARRAY['Widespread','Chrome','Pop-up drain','WaterSense'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.jacuzzi.com/faucets/duncan-widespread'),
  ('MZ28826', 'Elara Single-Handle Faucet', 'Elara', 'deck-mount', 1.2, 'gpm', 15, 129, ARRAY['Single handle','Chrome','WaterSense'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.jacuzzi.com/faucets/elara-single-handle')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'jacuzzi' AND c.slug = 'bathroom-faucet';


-- ======================== ADDITIONAL KOHLER SHOWERS ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('K-22170', 'Statement 14" Rainhead Square', 'Statement', 'wall-mount', 2.5, 'gpm', 20, 649, ARRAY['14" square rainhead','Single function','Chrome'], '{"gpm": 2.5, "spray_settings": 1, "head_diameter": 14}', 'https://www.us.kohler.com/us/K-22170'),
  ('K-76464', 'Hydrorail-R Shower Column', 'Hydrorail', 'wall-mount', 2.5, 'gpm', 20, 299, ARRAY['Shower column','Adjustable height','Chrome'], '{"gpm": 2.5, "spray_settings": 1, "valve_type": "pressure_balance"}', 'https://www.us.kohler.com/us/K-76464'),
  ('K-72419', 'Awaken B90 Handshower', 'Awaken', 'wall-mount', 2.0, 'gpm', 20, 59, ARRAY['3 spray functions','Ergonomic','Chrome','WaterSense'], '{"gpm": 2.0, "spray_settings": 3, "valve_type": "pressure_balance"}', 'https://www.us.kohler.com/us/K-72419'),
  ('K-TS97018-4', 'Components Thermostatic Valve Trim', 'Components', 'wall-mount', 2.5, 'gpm', 20, 599, ARRAY['Thermostatic','Volume control','Modular','Chrome'], '{"gpm": 2.5, "spray_settings": 2, "valve_type": "thermostatic"}', 'https://www.us.kohler.com/us/K-TS97018-4')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'kohler' AND c.slug = 'shower-system';

-- ======================== ADDITIONAL GROHE FAUCETS ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('20294001', 'Allure Widespread Faucet', 'Allure', 'deck-mount', 1.2, 'gpm', 15, 549, ARRAY['Widespread','Angular design','Chrome','SilkMove'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.grohe.com/us/20294001'),
  ('23737001', 'Plus Single-Handle Faucet', 'Plus', 'deck-mount', 1.2, 'gpm', 15, 219, ARRAY['Single handle','EcoJoy','Chrome','SilkMove'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.grohe.com/us/23737001'),
  ('20304003', 'Eurostyle Cosmopolitan Single-Handle Faucet', 'Eurostyle', 'deck-mount', 1.2, 'gpm', 15, 179, ARRAY['Single handle','SilkMove','Chrome','WaterSense'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.grohe.com/us/20304003')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'grohe' AND c.slug = 'bathroom-faucet';

-- ======================== ADDITIONAL AMERICAN STANDARD FAUCETS ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('7018801.002', 'Studio S Widespread Faucet', 'Studio S', 'deck-mount', 1.2, 'gpm', 15, 449, ARRAY['Widespread','Two handle','Chrome','Speed Connect'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.americanstandard.com/bathrooms/faucets/7018801.002'),
  ('7061804.002', 'Aspirations Widespread Faucet', 'Aspirations', 'deck-mount', 1.2, 'gpm', 15, 399, ARRAY['Widespread','Lever handles','Chrome','WaterSense'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.americanstandard.com/bathrooms/faucets/7061804.002'),
  ('7061105.002', 'Aspirations Single-Handle Vessel Faucet', 'Aspirations', 'deck-mount', 1.2, 'gpm', 15, 329, ARRAY['Vessel faucet','Single handle','Chrome','Tall spout'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.americanstandard.com/bathrooms/faucets/7061105.002')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'american-standard' AND c.slug = 'bathroom-faucet';

-- ======================== ADDITIONAL DELTA BATHTUBS ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('B10513-6032L-WH', 'Classic 500 60" Alcove Bathtub Left Drain', 'Classic 500', 'alcove', 46, 'gallons', 20, 299, ARRAY['60" x 32"','High-gloss acrylic','Left drain','Slip resistant'], '{"gallons": 46, "length_inches": 60, "material": "acrylic", "drain_location": "left"}', 'https://www.deltafaucet.com/bathtubs/B10513-6032L-WH'),
  ('B10513-6032R-WH', 'Classic 500 60" Alcove Bathtub Right Drain', 'Classic 500', 'alcove', 46, 'gallons', 20, 299, ARRAY['60" x 32"','High-gloss acrylic','Right drain','Slip resistant'], '{"gallons": 46, "length_inches": 60, "material": "acrylic", "drain_location": "right"}', 'https://www.deltafaucet.com/bathtubs/B10513-6032R-WH')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'delta-faucet' AND c.slug = 'bathtub';

-- ======================== ADDITIONAL HANSGROHE SHOWERS ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('04724000', 'Pulsify Showerhead 1-Jet', 'Pulsify', 'wall-mount', 2.5, 'gpm', 20, 49, ARRAY['PowderRain spray','Easy clean','Chrome'], '{"gpm": 2.5, "spray_settings": 1, "valve_type": "pressure_balance"}', 'https://www.hansgrohe-usa.com/04724000'),
  ('26036001', 'Croma Select S 110 Handshower', 'Croma Select', 'wall-mount', 2.5, 'gpm', 20, 69, ARRAY['Select button','3 spray modes','Chrome'], '{"gpm": 2.5, "spray_settings": 3, "valve_type": "pressure_balance"}', 'https://www.hansgrohe-usa.com/26036001'),
  ('04868000', 'Locarno Showerhead 2-Jet', 'Locarno', 'wall-mount', 2.5, 'gpm', 20, 149, ARRAY['2 spray modes','PowderRain','IntenseRain','Chrome'], '{"gpm": 2.5, "spray_settings": 2, "valve_type": "pressure_balance"}', 'https://www.hansgrohe-usa.com/04868000')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'hansgrohe' AND c.slug = 'shower-system';

-- ======================== ADDITIONAL BRIZO FAUCETS ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('65075LF-PC', 'Odin Single-Handle Faucet', 'Odin', 'deck-mount', 1.2, 'gpm', 15, 599, ARRAY['Single handle','Industrial design','Chrome','WaterSense'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.brizo.com/bathroom/65075LF-PC'),
  ('65097LF-GLLHP', 'Levoir Single-Handle Faucet Luxe Gold', 'Levoir', 'deck-mount', 1.2, 'gpm', 15, 749, ARRAY['Single handle','Luxe Gold','Art Deco','Less handles'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "luxe_gold"}', 'https://www.brizo.com/bathroom/65097LF-GLLHP'),
  ('65376LF-PC', 'Frank Lloyd Wright Widespread Faucet', 'Frank Lloyd Wright', 'deck-mount', 1.2, 'gpm', 15, 999, ARRAY['Widespread','Architectural design','Chrome','WaterSense'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.brizo.com/bathroom/65376LF-PC')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'brizo' AND c.slug = 'bathroom-faucet';

-- ======================== ADDITIONAL TOTO FAUCETS ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('TLG01309U', 'GO Widespread Faucet', 'GO', 'deck-mount', 1.2, 'gpm', 15, 349, ARRAY['Widespread','Two handle','Chrome','WaterSense'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.totousa.com/go-widespread-faucet'),
  ('TL221SD', 'Connelly Single-Handle Faucet', 'Connelly', 'deck-mount', 1.2, 'gpm', 15, 299, ARRAY['Single handle','Chrome','WaterSense','Modern design'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.totousa.com/connelly-single-handle-faucet'),
  ('TEL101-D10ET', 'Helix EcoPower Faucet', 'Helix', 'deck-mount', 0.5, 'gpm', 15, 799, ARRAY['Touchless','Self-powering','Chrome','0.5 GPM'], '{"gpm": 0.5, "holes": 1, "valve_type": "electronic", "finish": "chrome", "touchless": true}', 'https://www.totousa.com/helix-ecopower-faucet'),
  ('TLG02309U', 'GS Widespread Faucet', 'GS', 'deck-mount', 1.2, 'gpm', 15, 549, ARRAY['Widespread','Two handle','Chrome','Contemporary'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.totousa.com/gs-widespread-faucet')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'toto' AND c.slug = 'bathroom-faucet';

-- ======================== ADDITIONAL WATERWORKS BATHTUBS ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('14-22913-55510', 'Universal Oval Freestanding Bathtub', 'Universal', 'freestanding', 68, 'gallons', 30, 9500, ARRAY['Freestanding','Volcanic limestone','Seamless design','Center drain'], '{"gallons": 68, "length_inches": 70, "material": "volcanic_limestone", "drain_location": "center"}', 'https://www.waterworks.com/universal-oval-bathtub')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'waterworks' AND c.slug = 'bathtub';

-- ======================== ADDITIONAL DORNBRACHT FAUCETS ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('33543670-000010', 'CL.1 Single-Lever Lavatory Mixer', 'CL.1', 'deck-mount', 1.2, 'gpm', 20, 1199, ARRAY['Single lever','Minimalist','Chrome','German engineering'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.dornbracht.com/cl1-single-lever-mixer'),
  ('20710670-000010', 'Lisse Three-Hole Lavatory Mixer', 'Lisse', 'deck-mount', 1.2, 'gpm', 20, 1999, ARRAY['Widespread','Elegant curves','Chrome','WaterSense'], '{"gpm": 1.2, "holes": 3, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.dornbracht.com/lisse-three-hole-mixer')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'dornbracht' AND c.slug = 'bathroom-faucet';

-- ======================== ADDITIONAL VICTORIA + ALBERT ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('EDG-N-SW-NO', 'Edge Freestanding Bathtub', 'Edge', 'freestanding', 62, 'gallons', 30, 6299, ARRAY['Thin-rim design','Freestanding','ENGLISHCAST','Contemporary'], '{"gallons": 62, "length_inches": 65, "material": "englishcast", "drain_location": "center"}', 'https://www.vandabaths.com/edge-freestanding-bathtub'),
  ('RAV-N-SW-NO', 'Ravello Freestanding Bathtub', 'Ravello', 'freestanding', 58, 'gallons', 30, 5699, ARRAY['Curved form','Freestanding','ENGLISHCAST','Slipper design'], '{"gallons": 58, "length_inches": 63, "material": "englishcast", "drain_location": "center"}', 'https://www.vandabaths.com/ravello-freestanding-bathtub')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'victoria-albert' AND c.slug = 'bathtub';

-- ======================== ADDITIONAL DURAVIT FAUCETS ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, false, false, v.msrp, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('D11020002U10', 'D.1 Single-Handle Faucet', 'D.1', 'deck-mount', 1.2, 'gpm', 15, 199, ARRAY['Single handle','FreshStart','Chrome','Entry level'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.duravit.us/products/d-1-single-handle-faucet'),
  ('TU1020002U10', 'Tulum Single-Handle Faucet', 'Tulum', 'deck-mount', 1.2, 'gpm', 15, 349, ARRAY['Single handle','FreshStart','Chrome','MinusFlow'], '{"gpm": 1.2, "holes": 1, "valve_type": "ceramic_disc", "finish": "chrome"}', 'https://www.duravit.us/products/tulum-single-handle-faucet')
) AS v(model_number, model_name, series, install, cap, cap_unit, lifespan, msrp, features, specs, url)
WHERE m.slug = 'duravit' AND c.slug = 'bathroom-faucet';


-- ============================================================================
-- SUMMARY
-- ============================================================================
-- Budget Tier:
--   Glacier Bay:     14 models (4 toilets, 6 faucets, 2 bathtubs, 2 showers)
--   Peerless:         8 models (6 faucets, 2 showers)
--   Sterling:         9 models (2 toilets, 5 bathtubs, 2 showers)
-- Mainstream Tier:
--   Moen:            24 models (2 toilets, 12 faucets, 9 showers, 1 bathtub)
--   Delta:           23 models (2 toilets, 13 faucets, 8 showers)
--   American Standard: 25 models (12 toilets, 5 faucets, 3 bathtubs, 3 showers, 2 bidets)
--   Pfister:         12 models (9 faucets, 3 showers)
--   Symmons:         10 models (3 faucets, 7 showers)
--   Kraus:           10 models (8 faucets, 2 showers)
-- Premium Tier:
--   Kohler:          43 models (15 toilets, 10 faucets, 5 showers, 10 bathtubs, 3 bidets)
--   TOTO:            31 models (16 toilets, 5 bidets, 4 faucets, 3 bathtubs, 3 showers)
--   Hansgrohe:       17 models (10 faucets, 6 showers, 1 bathtub)
--   Grohe:           22 models (2 toilets, 8 faucets, 6 showers, 2 bathtubs, 2 bidets, 2 additional)
--   Jacuzzi:         16 models (2 toilets, 2 faucets, 10 bathtubs, 2 showers)
-- Luxury Tier:
--   Brizo:           14 models (7 faucets, 7 showers)
--   Duravit:         22 models (9 toilets, 3 faucets, 5 bathtubs, 2 bidets, 3 additional)
-- Ultra-Luxury Tier:
--   Waterworks:      11 models (7 faucets, 2 showers, 2 bathtubs)
--   Dornbracht:      13 models (5 faucets, 6 showers, 2 tub fillers)
--   Victoria + Albert: 8 models (8 bathtubs)
-- ============================================================================
-- TOTAL: 354 models
-- Categories: toilet, bathroom-faucet, shower-system, bathtub, bidet
-- 19 brands across 5 tiers (budget, mainstream, premium, luxury, ultra-luxury)
-- ============================================================================
