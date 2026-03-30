-- ============================================================================
-- Mainstream Brands: Whirlpool, Maytag, LG
-- ============================================================================

-- ======================== WHIRLPOOL ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, NULL, v.fuel, v.install, v.width, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.whirlpool.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  -- French Door Refrigerators
  ('WRF560SEHZ', '36" French Door 20 Cu Ft', NULL, 'freestanding', 'refrigerator-french-door', 36, 20.0, 'cu_ft', 13, false, true, 1498, ARRAY['Counter-depth','Internal water dispenser','Fingerprint resistant'], '{}'),
  ('WRMF3636RZ', '36" French Door Smart', NULL, 'freestanding', 'refrigerator-french-door', 36, NULL, NULL, 13, true, true, 2999, ARRAY['Smart features','Wi-Fi','Premium french door'], '{}'),
  -- Side-by-Side
  ('WRS321SDHZ', '33" Side-by-Side 21 Cu Ft', NULL, 'freestanding', 'refrigerator-side-by-side', 33, 21.0, 'cu_ft', 13, false, true, 1247, ARRAY['External ice/water','LED interior','Fingerprint resistant'], '{}'),
  -- Dishwashers
  ('WDT750SAHZ', '24" Top Control Dishwasher 47dBA', NULL, 'built-in', 'dishwasher', 24, NULL, NULL, 10, true, true, 648, ARRAY['Stainless steel tub','47 dBA','Sensor cycle','Third level rack'], '{"noise_dba": 47}'),
  ('WDT730HAMZ', '24" Dishwasher', NULL, 'built-in', 'dishwasher', 24, NULL, NULL, 10, false, true, 538, ARRAY['Built-in','Standard features'], '{}'),
  ('WDPS7024RZ', '24" Premium Dishwasher', NULL, 'built-in', 'dishwasher', 24, NULL, NULL, 10, true, true, 1079, ARRAY['Premium features','Quiet operation'], '{}'),
  -- Microwaves
  ('WMH31017HS', '1.7 Cu Ft OTR Microwave', NULL, 'over-the-range', 'microwave-otr', 30, 1.7, 'cu_ft', 9, false, false, NULL, ARRAY['Electronic touch controls','Sensor cooking','300 CFM'], '{"watts": 1000}'),
  -- Gas Range
  ('WFG505M0MS', '30" Gas Range 5.1 Cu Ft', 'gas', 'freestanding', 'range-gas', 30, 5.1, 'cu_ft', 15, false, false, NULL, ARRAY['Under-oven broiler','SpeedHeat burner','Fingerprint resistant'], '{"burners": 5}'),
  -- Electric Range
  ('WFE505W0JZ', '30" Electric Range 5.3 Cu Ft', 'electric', 'freestanding', 'range-electric', 30, 5.3, 'cu_ft', 14, false, false, NULL, ARRAY['Self-clean','FlexHeat element','Frozen Bake technology'], '{}')
) AS v(model_number, model_name, fuel, install, cat_slug, width, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'whirlpool' AND c.slug = v.cat_slug;

-- ======================== MAYTAG ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, NULL, v.fuel, v.install, v.width, v.cap, v.cap_unit, true, v.lifespan, false, true, v.msrp::numeric, v.features, v.specs::jsonb, 'https://www.maytag.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  -- French Door Refrigerators
  ('MFI2570FEZ', '36" French Door 25 Cu Ft PowerCold', NULL, 'freestanding', 'refrigerator-french-door', 36, 25.0, 'cu_ft', 13, NULL, ARRAY['PowerCold feature','Fingerprint resistant','Wide-N-Fresh deli drawer'], '{}'),
  ('MRFF4236RZ', '36" French Door 25 Cu Ft', NULL, 'freestanding', 'refrigerator-french-door', 36, 25.0, 'cu_ft', 13, NULL, ARRAY['French door','Bottom mount'], '{}'),
  -- Side-by-Side
  ('MRSF6636RZ', '36" Side-by-Side', NULL, 'freestanding', 'refrigerator-side-by-side', 36, NULL, NULL, 13, NULL, ARRAY['Side-by-side','External dispenser'], '{}'),
  ('MSS25N4MKZ', '36" Side-by-Side 25 Cu Ft', NULL, 'freestanding', 'refrigerator-side-by-side', 36, 25.0, 'cu_ft', 13, NULL, ARRAY['External ice/water','Fingerprint resistant'], '{}'),
  -- Top Freezer
  ('MRT311FFFZ', '33" Top Freezer 20.5 Cu Ft PowerCold', NULL, 'freestanding', 'refrigerator-top-freezer', 33, 20.5, 'cu_ft', 14, NULL, ARRAY['PowerCold feature','Glass shelves','Deli drawer'], '{}'),
  ('MRT118FFFZ', '30" Top Freezer 18 Cu Ft', NULL, 'freestanding', 'refrigerator-top-freezer', 30, 18.0, 'cu_ft', 14, NULL, ARRAY['Up-front temp controls','Gallon door bins'], '{}'),
  -- Electric Ranges
  ('MFES6030RZ', '30" Electric Range Air Fry - SS', 'electric', 'freestanding', 'range-electric', 30, 5.3, 'cu_ft', 15, NULL, ARRAY['No preheat air fry','Air baking','True convection','Power burner'], '{}'),
  ('MFES6030RB', '30" Electric Range Air Fry - Black', 'electric', 'freestanding', 'range-electric', 30, 5.3, 'cu_ft', 15, NULL, ARRAY['No preheat air fry','Air baking'], '{"color": "black"}'),
  ('MER4800PZ', '30" Electric Range Steam Clean', 'electric', 'freestanding', 'range-electric', 30, 5.3, 'cu_ft', 15, NULL, ARRAY['Steam clean','Precision cooking'], '{}'),
  -- Gas Ranges
  ('MFGS6030RZ', '30" Gas Range Air Fry - SS', 'gas', 'freestanding', 'range-gas', 30, 5.0, 'cu_ft', 15, NULL, ARRAY['No preheat air fry','5 sealed burners','True convection'], '{"burners": 5}'),
  -- Dishwashers
  ('MDFS3924RZ', '24" Front Control Dishwasher PowerBlast', 'electric', 'built-in', 'dishwasher', 24, NULL, NULL, 10, NULL, ARRAY['PowerBlast cycle','Heated dry','Dual Power filtration','50 dBA'], '{"noise_dba": 50}'),
  ('MDB4949SKZ', '24" Front Control Dishwasher 50dBA', 'electric', 'built-in', 'dishwasher', 24, NULL, NULL, 10, NULL, ARRAY['PowerBlast cycle','Dual Power filtration','Stainless tub','50 dBA'], '{"noise_dba": 50}'),
  ('MDB8959SKZ', '24" Top Control Dishwasher 47dBA', 'electric', 'built-in', 'dishwasher', 24, NULL, NULL, 10, NULL, ARRAY['PowerBlast cycle','3rd level rack','Dual Power filtration','47 dBA'], '{"noise_dba": 47}')
) AS v(model_number, model_name, fuel, install, cat_slug, width, cap, cap_unit, lifespan, msrp, features, specs)
WHERE m.slug = 'maytag' AND c.slug = v.cat_slug;

-- ======================== LG ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, v.width, v.cap, v.cap_unit, true, v.lifespan, true, true, v.features, v.specs::jsonb, 'https://www.lg.com/us/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  -- Refrigerators
  ('LRFGC2706S', '27 Cu Ft Counter-Depth MAX French Door', NULL, NULL, 'freestanding', 'refrigerator-french-door', 36, 27.0, 'cu_ft', 13, ARRAY['Counter-Depth MAX','InstaView','Dual Ice Maker','ThinQ Wi-Fi'], '{}'),
  ('LMXS28626D', 'French Door w/ InstaView - Black SS', NULL, NULL, 'freestanding', 'refrigerator-french-door', 36, 28.0, 'cu_ft', 13, ARRAY['InstaView Door-in-Door','Black stainless'], '{"color": "black_stainless"}'),
  ('LMXS28626S', 'French Door w/ InstaView - SS', NULL, NULL, 'freestanding', 'refrigerator-french-door', 36, 28.0, 'cu_ft', 13, ARRAY['InstaView Door-in-Door','Stainless steel'], '{}'),
  ('LRFS28XBS', 'Side-by-Side w/ InstaView - Black SS', NULL, NULL, 'freestanding', 'refrigerator-side-by-side', 36, 28.0, 'cu_ft', 13, ARRAY['InstaView','Side-by-side','Black stainless'], '{}'),
  -- Ranges
  ('LREL6323D', 'Electric Range - Black SS', NULL, 'electric', 'freestanding', 'range-electric', 30, 6.3, 'cu_ft', 15, ARRAY['ProBake Convection','EasyClean','SmartDiagnosis'], '{}'),
  ('LREL6325F', 'Electric Range InstaView - SS', 'InstaView', 'electric', 'freestanding', 'range-electric', 30, 6.3, 'cu_ft', 15, ARRAY['InstaView window','ProBake Convection','Air Fry','ThinQ'], '{}'),
  ('LRGL5823D', 'Gas Range - Black SS', NULL, 'gas', 'freestanding', 'range-gas', 30, 5.8, 'cu_ft', 15, ARRAY['ProBake Convection','UltraHeat burner','EasyClean'], '{}'),
  ('LRGL5825F', 'Gas Range InstaView - SS', 'InstaView', 'gas', 'freestanding', 'range-gas', 30, 5.8, 'cu_ft', 15, ARRAY['InstaView window','ProBake Convection','Air Fry','ThinQ'], '{}'),
  ('LSEL6335F', 'Slide-In Electric Range InstaView', 'InstaView', 'electric', 'slide-in', 'range-electric', 30, 6.3, 'cu_ft', 15, ARRAY['Slide-in','InstaView','ProBake','Air Fry','ThinQ'], '{}'),
  ('LSGL6335F', 'Slide-In Gas Range InstaView', 'InstaView', 'gas', 'slide-in', 'range-gas', 30, 6.3, 'cu_ft', 15, ARRAY['Slide-in','InstaView','ProBake','Air Fry','ThinQ'], '{}'),
  -- Wall Ovens
  ('WSEP4727F', '30" Single Wall Oven InstaView', 'InstaView', 'electric', 'built-in', 'wall-oven-single', 30, 4.7, 'cu_ft', 14, ARRAY['InstaView','True Convection','Air Fry','ThinQ'], '{}'),
  ('WDEP9427F', '30" Double Wall Oven InstaView', 'InstaView', 'electric', 'built-in', 'wall-oven-double', 30, 9.4, 'cu_ft', 14, ARRAY['InstaView','True Convection','Air Fry','ThinQ'], '{}'),
  ('WCEP6427F', '30" Combo Wall Oven InstaView', 'InstaView', 'electric', 'built-in', 'wall-oven-combo', 30, NULL, NULL, 14, ARRAY['InstaView','Microwave combo','True Convection','Air Fry'], '{}'),
  -- Cooktops
  ('CBGJ3623D', '36" Gas Cooktop - Black SS', NULL, 'gas', 'built-in', 'cooktop-gas', 36, NULL, NULL, 15, ARRAY['5 sealed burners','UltraHeat 22K BTU','Cast iron grates'], '{"burners": 5}'),
  ('CBGJ3627S', '36" Gas Cooktop - SS', NULL, 'gas', 'built-in', 'cooktop-gas', 36, NULL, NULL, 15, ARRAY['5 sealed burners','UltraHeat','ThinQ'], '{"burners": 5}')
) AS v(model_number, model_name, series, fuel, install, cat_slug, width, cap, cap_unit, lifespan, features, specs)
WHERE m.slug = 'lg' AND c.slug = v.cat_slug;
