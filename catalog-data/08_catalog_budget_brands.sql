-- ============================================================================
-- Budget Brands: Amana, Hotpoint, Frigidaire, Beko
-- ============================================================================

-- ======================== AMANA ========================

-- Amana Top Freezer Refrigerators
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, NULL, NULL, 'freestanding', v.width, v.cap, 'cu_ft', true, 13, false, true, v.msrp, v.features, v.specs::jsonb, 'https://www.amana.com/refrigerators/top-freezer.html'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('ART104TFDB', '28" Top Freezer - Black', 28, 14.0, NULL, ARRAY['Dairy bin','Full-width crisper','Reversible door','Up-front temp controls'], '{"color": "black"}'),
  ('ART104TFDW', '28" Top Freezer - White', 28, 14.0, NULL, ARRAY['Dairy bin','Full-width crisper','Reversible door'], '{"color": "white"}'),
  ('ARTX3028PB', '30" Top Freezer - Black', 30, 16.3, NULL, ARRAY['LED interior lights','Adjustable door bins','Up-front temp controls'], '{"color": "black"}'),
  ('ART308FFDW', '30" Top Freezer Garden Fresh - White', 30, 18.0, NULL, ARRAY['Garden Fresh crisper bins','Gallon door storage','Flip-up shelf','Reversible door'], '{"color": "white"}'),
  ('ART308FFDM', '30" Top Freezer Garden Fresh - SS', 30, 18.0, NULL, ARRAY['Garden Fresh crisper bins','Gallon door storage','Monochromatic stainless'], '{"color": "stainless"}'),
  ('ART318FFDB', '30" Top Freezer Glass Shelves - Black', 30, 18.0, NULL, ARRAY['Glass shelves','Garden Fresh crisper bins','Gallon door storage','Optional ice maker'], '{"color": "black"}'),
  ('ART318FFDW', '30" Top Freezer Glass Shelves - White', 30, 18.0, NULL, ARRAY['Glass shelves','Garden Fresh crisper bins','Reversible door'], '{"color": "white"}'),
  ('ART318FFDS', '30" Top Freezer Glass Shelves - SS', 30, 18.0, NULL, ARRAY['Glass shelves','Garden Fresh crisper bins','Stainless steel'], '{"color": "stainless"}')
) AS v(model_number, model_name, width, cap, msrp, features, specs)
WHERE m.slug = 'amana' AND c.slug = 'refrigerator-top-freezer';

-- Amana Side-by-Side Refrigerators
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, NULL, NULL, 'freestanding', v.width, v.cap, 'cu_ft', true, 13, false, true, v.msrp, v.features, '{}', 'https://www.amana.com/refrigerators/side-by-side.html'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('ASI2175GRS', '33" Side-by-Side - SS', 33, 21.4, 1299, ARRAY['Dual pad external ice/water','EveryDrop water filter','Temp Assure controls','Gallon door bins']),
  ('ASI2575GRS', '36" Side-by-Side - SS', 36, 24.6, 1199, ARRAY['Dual pad external ice/water','EveryDrop water filter','Temp Assure controls','LED lighting','ADA compliant'])
) AS v(model_number, model_name, width, cap, msrp, features)
WHERE m.slug = 'amana' AND c.slug = 'refrigerator-side-by-side';

-- Amana Gas Ranges
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, NULL, 'gas', 'freestanding', 30, 5.1, 'cu_ft', true, 15, false, false, v.features, v.specs::jsonb, 'https://www.amana.com/kitchen/cooking/ranges.html'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('AGR5330BAS', '30" Gas Range - SS', ARRAY['Easy Touch electronic controls','Sealed burners','Extra-large window','Temp Assure'], '{"burners": 4, "color": "stainless"}'),
  ('AGR6303MMS', '30" Gas Range Bake Assist - SS', ARRAY['Bake Assist temps','Easy Touch Plus controls','Extra-large window'], '{"burners": 4, "color": "stainless"}'),
  ('AGR6303MMW', '30" Gas Range Bake Assist - White', ARRAY['Bake Assist temps','Easy Touch Plus controls'], '{"burners": 4, "color": "white"}')
) AS v(model_number, model_name, features, specs)
WHERE m.slug = 'amana' AND c.slug = 'range-gas';

-- Amana Electric Ranges
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, NULL, 'electric', 'freestanding', 30, 4.8, 'cu_ft', true, 14, false, false, v.features, v.specs::jsonb, 'https://www.amana.com/kitchen/cooking/ranges.html'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('AER6603SFS', '30" Electric Range - SS', ARRAY['Self-clean option','Bake Assist','Extra-large window','Temp Assure'], '{"color": "stainless"}'),
  ('AER6603SFB', '30" Electric Range - Black', ARRAY['Self-clean option','Bake Assist','Extra-large window'], '{"color": "black"}'),
  ('AER6603SFW', '30" Electric Range - White', ARRAY['Self-clean option','Bake Assist','Temp Assure'], '{"color": "white"}'),
  ('AER6303MFS', '30" Electric Range - SS', ARRAY['Bake Assist','Extra-large window','Easy Touch Plus'], '{"color": "stainless"}'),
  ('AER6303MFB', '30" Electric Range - Black', ARRAY['Bake Assist','Extra-large window'], '{"color": "black"}')
) AS v(model_number, model_name, features, specs)
WHERE m.slug = 'amana' AND c.slug = 'range-electric';

-- Amana Dishwashers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, NULL, 'electric', 'built-in', 24, true, 10, false, true, v.features, v.specs::jsonb, 'https://www.amana.com/kitchen/dishwashers.html'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('ADB1400AMS', '24" Dishwasher - SS', ARRAY['Triple filter wash','12 place settings','3 wash cycles','Heated dry option'], '{"noise_dba": 63, "place_settings": 12, "cycles": 3, "color": "stainless"}'),
  ('ADB1400AMW', '24" Dishwasher - White', ARRAY['Triple filter wash','12 place settings','3 wash cycles'], '{"noise_dba": 63, "place_settings": 12, "cycles": 3, "color": "white"}'),
  ('ADB1400AGW', '24" Dishwasher Energy Star - White', ARRAY['Triple filter wash','12 place settings','1-hour wash','High-temp wash'], '{"noise_dba": 63, "place_settings": 12, "cycles": 3, "color": "white"}')
) AS v(model_number, model_name, features, specs)
WHERE m.slug = 'amana' AND c.slug = 'dishwasher';

-- Amana Microwaves
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, NULL, 'electric', 'over-the-range', 30, true, 9, false, false, v.msrp, v.features, v.specs::jsonb, 'https://www.amana.com/cooking/microwaves.html'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('AMV2307PFS', '1.6 Cu Ft OTR Microwave - SS', 230, ARRAY['Add 0:30 seconds','Defrost','Reheat','Popcorn button'], '{"capacity_cu_ft": 1.6, "watts": 1000, "color": "stainless"}'),
  ('AMV2307PFW', '1.6 Cu Ft OTR Microwave - White', NULL, ARRAY['Add 0:30 seconds','Defrost','Reheat'], '{"capacity_cu_ft": 1.6, "watts": 1000, "color": "white"}'),
  ('UMV1170LW', '1.7 Cu Ft OTR Microwave - White', NULL, ARRAY['1000 watts','1.7 cu ft capacity'], '{"capacity_cu_ft": 1.7, "watts": 1000, "color": "white"}')
) AS v(model_number, model_name, msrp, features, specs)
WHERE m.slug = 'amana' AND c.slug = 'microwave-otr';

-- ======================== HOTPOINT ========================

-- Hotpoint Top Freezer Refrigerators
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, NULL, NULL, 'freestanding', v.width, v.cap, 'cu_ft', true, 13, false, true, v.msrp, ARRAY['Recessed handle','Budget-friendly','Apartment/rental ready'], v.specs::jsonb, 'https://www.hotpoint.com/refrigerator-freezer/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('HPS10LGVRBB', '24" Top Freezer - Black', 24, 9.7, 679, '{"color": "black"}'),
  ('HPS10LGVRWW', '24" Top Freezer - White', 24, 9.7, 679, '{"color": "white"}'),
  ('HPS16BTNLWW', '28" Top Freezer Left Hinge - White', 28, 15.6, 829, '{"color": "white", "hinge": "left"}'),
  ('HPS16BTNRBB', '28" Top Freezer - Black', 28, 15.6, 829, '{"color": "black"}'),
  ('HPS16BTNRWW', '28" Top Freezer - White', 28, 15.6, 829, '{"color": "white"}'),
  ('HPS18BTNRWW', '30" Top Freezer - White', 30, 17.5, 849, '{"color": "white"}'),
  ('HPS18BTNRBB', '30" Top Freezer - Black', 30, 17.5, 849, '{"color": "black"}'),
  ('HTS17GCSWW', '28" Top Freezer w/ Icemaker - White', 28, 16.6, NULL, '{"color": "white", "has_icemaker": true}')
) AS v(model_number, model_name, width, cap, msrp, specs)
WHERE m.slug = 'hotpoint' AND c.slug = 'refrigerator-top-freezer';

-- Hotpoint Electric Ranges
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, NULL, 'electric', 'freestanding', v.width, true, 14, false, true, v.msrp, v.features, v.specs::jsonb, 'https://www.hotpoint.com/range-microwave/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('RAS240DMWW', '24" Electric Range - White', 24, 849, ARRAY['Compact 24" width','Free-standing','Front controls'], '{"color": "white", "width": 24}'),
  ('RBS160DMBB', '30" Electric Range - Black', 30, 679, ARRAY['Coil burners','Standard clean'], '{"color": "black"}'),
  ('RBS160DMWW', '30" Electric Range - White', 30, 679, ARRAY['Coil burners','Standard clean'], '{"color": "white"}'),
  ('RBS360DMWW', '30" Electric Range Standard Clean - White', 30, 799, ARRAY['Standard clean','Coil burners'], '{"color": "white"}'),
  ('RBS360DMBB', '30" Electric Range Standard Clean - Black', 30, 799, ARRAY['Standard clean','Coil burners'], '{"color": "black"}')
) AS v(model_number, model_name, width, msrp, features, specs)
WHERE m.slug = 'hotpoint' AND c.slug = 'range-electric';

-- Hotpoint Gas Ranges
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, NULL, 'gas', 'freestanding', 30, true, 15, false, false, v.msrp, ARRAY['Standard clean','Budget-friendly'], v.specs::jsonb, 'https://www.hotpoint.com/range-microwave/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('RGBS400DMWW', '30" Gas Range - White', 749, '{"color": "white", "burners": 4}'),
  ('RGBS400DMBB', '30" Gas Range - Black', 749, '{"color": "black", "burners": 4}')
) AS v(model_number, model_name, msrp, specs)
WHERE m.slug = 'hotpoint' AND c.slug = 'range-gas';

-- Hotpoint Dishwashers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, NULL, 'electric', 'built-in', 24, true, 10, false, false, v.msrp, v.features, v.specs::jsonb, 'https://www.hotpoint.com/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('HDF310PGRWW', 'One Button Dishwasher - White', 409, ARRAY['One button operation','Plastic interior','Budget-friendly'], '{"color": "white", "tub": "plastic"}'),
  ('HDF310PGRBB', 'One Button Dishwasher - Black', 409, ARRAY['One button operation','Plastic interior'], '{"color": "black", "tub": "plastic"}'),
  ('HDA2100HWW', 'Built-In Dishwasher - White', 369, ARRAY['Built-in','Standard features'], '{"color": "white"}'),
  ('HDA2100HBB', 'Built-In Dishwasher - Black', 369, ARRAY['Built-in','Standard features'], '{"color": "black"}'),
  ('HDA2100HCC', 'Built-In Dishwasher - Bisque', 369, ARRAY['Built-in','Bisque finish'], '{"color": "bisque"}')
) AS v(model_number, model_name, msrp, features, specs)
WHERE m.slug = 'hotpoint' AND c.slug = 'dishwasher';

-- ======================== FRIGIDAIRE (Base Line) ========================

-- Frigidaire Top Freezer Refrigerators
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, NULL, NULL, 'freestanding', 30, v.cap, 'cu_ft', true, 13, false, true, v.features, v.specs::jsonb, 'https://www.frigidaire.com/en/kitchen-appliances/refrigerators/view-all'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('FFTR1835VS', '30" Top Freezer 18.3 Cu Ft - SS', 18.3, ARRAY['EvenTemp cooling','Humidity-controlled crispers','Auto-close doors','ADA compliant'], '{"color": "stainless"}'),
  ('FFTR1835VW', '30" Top Freezer 18.3 Cu Ft - White', 18.3, ARRAY['EvenTemp cooling','Humidity-controlled crispers','Auto-close doors'], '{"color": "white"}'),
  ('FFTR1835VB', '30" Top Freezer 18.3 Cu Ft - Black', 18.3, ARRAY['EvenTemp cooling','Humidity-controlled crispers'], '{"color": "black"}'),
  ('FFTR2045VS', '30" Top Freezer 20 Cu Ft Garage Ready - SS', 20.0, ARRAY['Garage ready','EvenTemp cooling','LED lighting','ADA compliant'], '{"color": "stainless", "garage_ready": true}'),
  ('FFTR2045VW', '30" Top Freezer 20 Cu Ft Garage Ready - White', 20.0, ARRAY['Garage ready','EvenTemp cooling'], '{"color": "white", "garage_ready": true}')
) AS v(model_number, model_name, cap, features, specs)
WHERE m.slug = 'frigidaire' AND c.slug = 'refrigerator-top-freezer';

-- Frigidaire Side-by-Side
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, NULL, NULL, 'freestanding', 36, v.cap, 'cu_ft', true, 13, false, true, ARRAY['EvenTemp cooling','External water/ice dispenser','PureSource filtration'], '{}', 'https://www.frigidaire.com/en/kitchen-appliances/refrigerators/view-all'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('FRSS2623AS', '36" Side-by-Side 25.6 Cu Ft - SS', 25.6),
  ('FRFS2823AS', '36" Side-by-Side - SS', 28.0)
) AS v(model_number, model_name, cap)
WHERE m.slug = 'frigidaire' AND c.slug = 'refrigerator-side-by-side';

-- Frigidaire French Door
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, NULL, NULL, 'freestanding', v.width, v.cap, 'cu_ft', true, 13, false, true, ARRAY['EvenTemp cooling','CrispSeal crispers','LED lighting'], '{}', 'https://www.frigidaire.com/en/kitchen-appliances/refrigerators/view-all'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('FRFG1723AV', '31" Counter-Depth French Door 17.6 Cu Ft', 31, 17.6),
  ('FRFN2813AF', '36" French Door 28 Cu Ft', 36, 28.0)
) AS v(model_number, model_name, width, cap)
WHERE m.slug = 'frigidaire' AND c.slug = 'refrigerator-french-door';

-- Frigidaire Ranges
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, NULL, v.fuel, 'freestanding', 30, true, 15, false, false, v.features, '{}', 'https://www.frigidaire.com/en/cooking'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('FCRG3051BS', '30" Gas Range - SS', 'gas', 'range-gas', ARRAY['Even baking','Quick boil burner','Self-clean']),
  ('FCRG3052BS', '30" Gas Range - SS', 'gas', 'range-gas', ARRAY['Even baking','Quick boil burner']),
  ('FCRG3062AS', '30" Gas Range Quick Boil - SS', 'gas', 'range-gas', ARRAY['Quick boil','Self-clean','5 sealed burners']),
  ('FCRG3083AS', '30" Gas Range - SS', 'gas', 'range-gas', ARRAY['5 sealed burners','Steam clean']),
  ('FCRE3052BS', '30" Electric Range - SS', 'electric', 'range-electric', ARRAY['Smooth-top','Even baking','Self-clean']),
  ('FCRE3083AS', '30" Electric Range - SS', 'electric', 'range-electric', ARRAY['Smooth-top','Quick boil element']),
  ('FCFI3083AS', '30" Induction Range - SS', 'induction', 'range-induction', ARRAY['Induction cooktop','Convection oven','Quick boil'])
) AS v(model_number, model_name, fuel, cat_slug, features)
WHERE m.slug = 'frigidaire' AND c.slug = v.cat_slug;

-- Frigidaire Dishwashers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, NULL, 'electric', 'built-in', 24, true, 10, false, true, ARRAY['DishSense technology','Multiple wash cycles','ENERGY STAR certified'], '{}', 'https://www.frigidaire.com/en/dishwashers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('FDPH4316AS', '24" Dishwasher - SS'),
  ('FDPC4314AS', '24" Dishwasher - SS'),
  ('FDPC4221AS', '24" Dishwasher - SS'),
  ('FDHP4336AS', '24" Dishwasher - SS')
) AS v(model_number, model_name)
WHERE m.slug = 'frigidaire' AND c.slug = 'dishwasher';

-- Frigidaire Microwaves
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, NULL, 'electric', 'over-the-range', 30, true, 9, false, false, ARRAY['Sensor cooking','LED lighting','Multi-stage cooking'], '{}', 'https://www.frigidaire.com/en/cooking'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('FMOS1846BS', '1.8 Cu Ft OTR Microwave - SS'),
  ('FMOS1746BS', '1.7 Cu Ft OTR Microwave - SS'),
  ('FMOW1852AS', '1.8 Cu Ft OTR Microwave - SS')
) AS v(model_number, model_name)
WHERE m.slug = 'frigidaire' AND c.slug = 'microwave-otr';

-- ======================== BEKO ========================

-- Beko Refrigerators
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, NULL, NULL, 'freestanding', v.width, v.cap, 'cu_ft', true, 13, false, true, v.msrp, v.features, v.specs::jsonb, 'https://www.beko.com/us-en/refrigerators'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('BFFD3626SS', '36" French Four-Door - SS', 'refrigerator-4-door', 36, 19.8, NULL, ARRAY['Counter-depth','Auto ice maker','Water dispenser','EverFresh+','MultiZone drawer'], '{"counter_depth": true}'),
  ('BFBF2414SS', '24" Bottom Freezer - SS', 'refrigerator-bottom-freezer', 24, 11.4, NULL, ARRAY['Counter-depth','ENERGY STAR Most Efficient','Compact'], '{"counter_depth": true, "compact": true}'),
  ('BFBD30216SSL', '30" Bottom Freezer Smart - SS', 'refrigerator-bottom-freezer', 30, NULL, 2099, ARRAY['Smart connectivity','Counter-depth'], '{"counter_depth": true, "smart": true}'),
  ('BFTF2716SS', '28" Top Freezer - SS', 'refrigerator-top-freezer', 28, 13.9, NULL, ARRAY['ENERGY STAR Most Efficient','Fingerprint-free stainless'], '{}'),
  ('BFTF2716WH', '28" Top Freezer - White', 'refrigerator-top-freezer', 28, 13.9, NULL, ARRAY['ENERGY STAR Most Efficient'], '{"color": "white"}'),
  ('BFTF2716SSIM', '28" Top Freezer w/ Ice Maker - SS', 'refrigerator-top-freezer', 28, 13.5, NULL, ARRAY['Auto ice maker','ENERGY STAR Most Efficient'], '{"has_icemaker": true}')
) AS v(model_number, model_name, cat_slug, width, cap, msrp, features, specs)
WHERE m.slug = 'beko' AND c.slug = v.cat_slug;

-- Beko Dishwashers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, NULL, 'electric', 'built-in', v.width, true, 10, false, true, v.features, v.specs::jsonb, 'https://www.beko.com/us-en/all-dishwashers'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DUT36522X', '24" Tall Tub Dishwasher', 24, ARRAY['CornerIntense spray arm','15 place settings','45 dBA','SelfDry'], '{"noise_dba": 45, "place_settings": 15}'),
  ('DUT25401W', '24" Tall Tub Dishwasher - White', 24, ARRAY['14 place settings','48 dBA','ENERGY STAR Most Efficient'], '{"noise_dba": 48, "place_settings": 14, "color": "white"}'),
  ('DIT39432', '24" Panel Ready Dishwasher', 24, ARRAY['Panel-ready','39 dBA','Fully integrated'], '{"noise_dba": 39, "panel_ready": true}'),
  ('DIS25842', '18" Slim Dishwasher Panel Ready', 18, ARRAY['Slim 18" width','8 place settings','48 dBA','Panel ready','ENERGY STAR Most Efficient'], '{"noise_dba": 48, "place_settings": 8, "slim": true}')
) AS v(model_number, model_name, width, features, specs)
WHERE m.slug = 'beko' AND c.slug = 'dishwasher';

-- Beko Ranges
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, NULL, v.fuel, v.install, v.width, true, 15, false, false, v.features, '{}', 'https://www.beko.com/us-en/ranges'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('SLER24410SS', '24" Slide-In Electric Range - SS', 'electric', 'range-electric', 'slide-in', 24, ARRAY['European convection','50% faster preheat','Compact 24"']),
  ('SLER30530SS', '30" Slide-In Electric Range - SS', 'electric', 'range-electric', 'slide-in', 30, ARRAY['Slide-in','European convection']),
  ('PRIR34450SS', '30" Pro-Style Induction Range - SS', 'induction', 'range-induction', 'freestanding', 30, ARRAY['Pro-style','5.7 cu ft capacity','Induction cooking','Twin turbo convection']),
  ('PRDF34550SS', '30" Pro-Style Dual Fuel Range - SS', 'dual-fuel', 'range-dual-fuel', 'freestanding', 30, ARRAY['Pro-style','Dual fuel','Gas burners + electric oven'])
) AS v(model_number, model_name, fuel, cat_slug, install, width, features)
WHERE m.slug = 'beko' AND c.slug = v.cat_slug;
