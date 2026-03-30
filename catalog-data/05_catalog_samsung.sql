-- ============================================================================
-- Samsung Equipment Catalog Entries
-- ============================================================================

-- Samsung Refrigerators
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'freestanding', 36, true, 13, true, true, v.msrp, v.features, v.specs::jsonb,
  'https://www.samsung.com/us/home-appliances/refrigerators/all-refrigerators/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  -- 4-Door Flex
  ('RF29DB9900QDAA', 'Bespoke AI 4-Door Flex', 'Bespoke AI', 'refrigerator-4-door', 3699, ARRAY['AI Vision with Google Gemini','Family Hub','4-Door Flex','Beverage Center'], '{"capacity_cu_ft": 29, "type": "4-door-flex"}'),
  ('RF29DB9600QLAA', 'Bespoke AI 4-Door Flex', 'Bespoke AI', 'refrigerator-4-door', 2999, ARRAY['AI Vision','4-Door Flex','FlexZone drawer'], '{"capacity_cu_ft": 29, "type": "4-door-flex"}'),
  ('RF23DB9750QLAA', 'Bespoke AI 4-Door Flex Counter-Depth', 'Bespoke AI', 'refrigerator-4-door', 2049, ARRAY['Counter-depth','4-Door Flex','AI Energy Mode'], '{"capacity_cu_ft": 23, "type": "4-door-flex", "counter_depth": true}'),
  ('RF29BB8600QLAA', 'Bespoke 4-Door French Door', 'Bespoke', 'refrigerator-4-door', 2299, ARRAY['Bespoke customizable panels','Beverage Center','Dual Ice Maker'], '{"capacity_cu_ft": 29, "type": "4-door-french-door"}'),
  -- French Door
  ('RF90F29AECRAA', 'Bespoke AI 4-Door French Door', 'Bespoke AI', 'refrigerator-french-door', 3699, ARRAY['AI Vision','Counter-depth','AutoFill pitcher'], '{"capacity_cu_ft": 29}'),
  ('RF90F29BECRAA', 'Bespoke AI 4-Door French Door', 'Bespoke AI', 'refrigerator-french-door', 3599, ARRAY['AI Vision','Counter-depth'], '{"capacity_cu_ft": 29}'),
  ('RF90F23EECRAA', 'Bespoke AI 4-Door French Door', 'Bespoke AI', 'refrigerator-french-door', 3399, ARRAY['AI Vision','Counter-depth'], '{"capacity_cu_ft": 23}'),
  ('RF70H30GEEAA', 'Bespoke AI 3-Door French Door', 'Bespoke AI', 'refrigerator-french-door', 2999, ARRAY['AI Vision','AutoFill pitcher','Dual Auto Ice Maker'], '{"capacity_cu_ft": 29}'),
  ('RF70H30KEEAA', 'Bespoke AI 3-Door French Door', 'Bespoke AI', 'refrigerator-french-door', 2599, ARRAY['AI Vision','Dual Auto Ice Maker'], '{"capacity_cu_ft": 30}'),
  ('RF70H25HERAA', 'Bespoke AI 3-Door French Door Counter-Depth', 'Bespoke AI', 'refrigerator-french-door', 2899, ARRAY['Counter-depth','AI Vision','Zero Clearance Fit'], '{"capacity_cu_ft": 24, "counter_depth": true}'),
  ('RF32CG5900SRAA', '3-Door French Door', NULL, 'refrigerator-french-door', 2999, ARRAY['External water/ice dispenser','Twin Cooling Plus'], '{"capacity_cu_ft": 30}'),
  ('RF32CG5B30SRAA', 'Bespoke AI 3-Door French Door', 'Bespoke AI', 'refrigerator-french-door', 2399, ARRAY['AI Energy Mode'], '{"capacity_cu_ft": 31}'),
  ('RF32CG5D00SRAA', 'Bespoke AI 3-Door French Door', 'Bespoke AI', 'refrigerator-french-door', 2099, ARRAY['AI Energy Mode','Full-depth'], '{"capacity_cu_ft": 32}'),
  ('RF30BB6600QLAA', 'Bespoke AI 3-Door French Door', 'Bespoke AI', 'refrigerator-french-door', 1999, ARRAY['AI Energy Mode'], '{"capacity_cu_ft": 30}'),
  ('RF30BB6200QLAA', 'Bespoke AI 3-Door French Door', 'Bespoke AI', 'refrigerator-french-door', 1299, ARRAY['Bespoke panels'], '{"capacity_cu_ft": 30}'),
  ('RF25C5A01SRAA', 'Bespoke AI 3-Door French Door Counter-Depth', 'Bespoke AI', 'refrigerator-french-door', 2099, ARRAY['Counter-depth','AI Energy Mode'], '{"capacity_cu_ft": 25, "counter_depth": true}'),
  ('RF70F29DERAA', 'Bespoke AI 4-Door French Door', 'Bespoke AI', 'refrigerator-french-door', 1899, ARRAY['AI Energy Mode','Dual Ice Maker'], '{"capacity_cu_ft": 29}'),
  ('RF28R7201SR-AA', '4-Door French Door', NULL, 'refrigerator-french-door', 1899, ARRAY['Food Showcase Door','FlexZone Drawer'], '{"capacity_cu_ft": 28}'),
  -- Side-by-Side
  ('RS70H27SDRAA', 'Bespoke AI Side-by-Side', 'Bespoke AI', 'refrigerator-side-by-side', 1999, ARRAY['AI Vision','Side-by-side','External dispenser'], '{"capacity_cu_ft": 27}'),
  ('RS28CB7600QLAA', 'Bespoke Side-by-Side', 'Bespoke', 'refrigerator-side-by-side', 1699, ARRAY['Bespoke panels','External dispenser'], '{"capacity_cu_ft": 28}'),
  -- Built-In
  ('RM80F23VMRAA', 'Bespoke AI 4-Door French Door Built-In', 'Bespoke AI', 'refrigerator-built-in', 3599, ARRAY['Built-in','Counter-depth','AI Vision'], '{"capacity_cu_ft": 23, "counter_depth": true}'),
  ('RM80F22WEWAA', 'Bespoke AI 4-Door French Door Built-In', 'Bespoke AI', 'refrigerator-built-in', 3399, ARRAY['Built-in','Counter-depth'], '{"capacity_cu_ft": 22, "counter_depth": true}'),
  -- Top Freezer
  ('RT70F18LASRAA', 'Top Freezer Refrigerator', NULL, 'refrigerator-top-freezer', 799, ARRAY['Flex Crisper','All-Around Cooling'], '{"capacity_cu_ft": 18}'),
  -- Freezer
  ('RZ11M7074SA-AA', 'Upright Freezer', NULL, 'freezer', 899, ARRAY['Slim design','All-Around Cooling'], '{"capacity_cu_ft": 11.4}')
) AS v(model_number, model_name, series, cat_slug, msrp, features, specs)
WHERE m.slug = 'samsung' AND c.slug = v.cat_slug;

-- Samsung Ranges
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'slide-in', 30, true, 15, true, true, v.features, v.specs::jsonb,
  'https://www.samsung.com/us/ranges/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  -- Induction Slide-in
  ('NSI6DB990012AA', 'Bespoke AI Slide-in Induction Range', 'Bespoke AI', 'induction', 'range-induction', ARRAY['AI Camera','Flex Duo','Air Fry','Smart Dial'], '{"capacity_cu_ft": 6.3}'),
  ('NSI6DG9550SRAA', 'Bespoke Slide-in Induction - Flex Duo', 'Bespoke', 'induction', 'range-induction', ARRAY['Flex Duo','Air Fry','Wi-Fi'], '{"capacity_cu_ft": 6.3}'),
  ('NSI6DG9500MTAA', 'Bespoke Slide-in Induction', 'Bespoke', 'induction', 'range-induction', ARRAY['Air Fry','Smart Dial','Matte Black Steel'], '{"capacity_cu_ft": 6.3}'),
  ('NSI6DG9300SRAA', 'Bespoke Slide-in Induction', 'Bespoke', 'induction', 'range-induction', ARRAY['Air Fry','Wi-Fi'], '{"capacity_cu_ft": 6.3}'),
  ('NSI6DG9100SRAA', 'Bespoke Slide-in Induction', 'Bespoke', 'induction', 'range-induction', ARRAY['Wi-Fi','Air Fry'], '{"capacity_cu_ft": 6.3}'),
  -- Electric Slide-in
  ('NSE6DB870012AA', 'Bespoke AI Slide-in Electric Range', 'Bespoke AI', 'electric', 'range-electric', ARRAY['AI Camera','Air Fry','Smart Dial','White Glass'], '{"capacity_cu_ft": 6.3}'),
  ('NSE6DG8700SRAA', 'Bespoke Slide-in Electric', 'Bespoke', 'electric', 'range-electric', ARRAY['Air Fry','Smart Dial','Wi-Fi'], '{"capacity_cu_ft": 6.3}'),
  ('NSE6DG8550SRAA', 'Bespoke Slide-in Electric - Flex Duo', 'Bespoke', 'electric', 'range-electric', ARRAY['Flex Duo','Air Fry','Wi-Fi'], '{"capacity_cu_ft": 6.3}'),
  ('NSE6DG8500SRAA', 'Bespoke Slide-in Electric', 'Bespoke', 'electric', 'range-electric', ARRAY['Air Fry','Wi-Fi'], '{"capacity_cu_ft": 6.3}'),
  ('NSE6DG8300SRAA', 'Bespoke Slide-in Electric', 'Bespoke', 'electric', 'range-electric', ARRAY['Air Fry'], '{"capacity_cu_ft": 6.3}'),
  ('NSE6DG8100SRAA', 'Bespoke Slide-in Electric', 'Bespoke', 'electric', 'range-electric', ARRAY['Wi-Fi'], '{"capacity_cu_ft": 6.3}'),
  ('NE63A6511SS-AA', 'Freestanding Electric Range', NULL, 'electric', 'range-electric', ARRAY['Self-clean','Storage drawer'], '{"capacity_cu_ft": 6.3}'),
  -- Gas Slide-in
  ('NSG6DB870012AA', 'Bespoke AI Slide-in Gas Range', 'Bespoke AI', 'gas', 'range-gas', ARRAY['AI Camera','Air Fry','Smart Dial','White Glass'], '{"capacity_cu_ft": 6.0}'),
  ('NSG6DG8700SRAA', 'Bespoke Slide-in Gas', 'Bespoke', 'gas', 'range-gas', ARRAY['Air Fry','Smart Dial','Wi-Fi'], '{"capacity_cu_ft": 6.0}'),
  ('NSG6DG8550SRAA', 'Bespoke Slide-in Gas - Flex Duo', 'Bespoke', 'gas', 'range-gas', ARRAY['Flex Duo','Air Fry','Wi-Fi'], '{"capacity_cu_ft": 6.0}'),
  ('NSG6DG8500SRAA', 'Bespoke Slide-in Gas', 'Bespoke', 'gas', 'range-gas', ARRAY['Air Fry','Wi-Fi'], '{"capacity_cu_ft": 6.0}'),
  ('NSG6DG8300SRAA', 'Bespoke Slide-in Gas', 'Bespoke', 'gas', 'range-gas', ARRAY['Air Fry'], '{"capacity_cu_ft": 6.0}'),
  ('NSG6DG8100SRAA', 'Bespoke Slide-in Gas', 'Bespoke', 'gas', 'range-gas', ARRAY['Wi-Fi'], '{"capacity_cu_ft": 6.0}'),
  -- Dual Fuel
  ('NSY6DG8550SRAA', 'Bespoke Slide-in Dual Fuel - Flex Duo', 'Bespoke', 'dual-fuel', 'range-dual-fuel', ARRAY['Flex Duo','Air Fry','Wi-Fi','Gas burners + electric oven'], '{"capacity_cu_ft": 6.3}')
) AS v(model_number, model_name, series, fuel, cat_slug, features, specs)
WHERE m.slug = 'samsung' AND c.slug = v.cat_slug;

-- Samsung Dishwashers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'built-in', 24, true, 10, true, true, v.msrp, v.features, v.specs::jsonb,
  'https://www.samsung.com/us/dishwashers/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DW90F89P0USRAA', 'Bespoke AI Auto Open Door 38dBA', 'Bespoke AI', 999, ARRAY['Auto Open Door','StormWash+','3rd Rack','Smart Dry with AutoRelease'], '{"noise_dba": 38, "place_settings": 16, "cycles": 7}'),
  ('DW90F89T0U12AA', 'Bespoke AI Smart 38dBA', 'Bespoke AI', 999, ARRAY['StormWash+','3rd Rack','Smart Dry with AutoRelease','White Glass Panel'], '{"noise_dba": 38, "place_settings": 16}'),
  ('DW90F89T0UMTAA', 'Bespoke AI Smart 38dBA Matte', 'Bespoke AI', 999, ARRAY['StormWash+','3rd Rack','Smart Dry','Matte Black Steel'], '{"noise_dba": 38, "place_settings": 16}'),
  ('DW90F89T0USRAA', 'Bespoke AI Smart 38dBA Stainless', 'Bespoke AI', 999, ARRAY['StormWash+','3rd Rack','Smart Dry','Stainless Steel'], '{"noise_dba": 38, "place_settings": 16}'),
  ('DW80B7070US-AA', 'Bespoke AutoRelease Smart 42dBA', 'Bespoke', 799, ARRAY['AutoRelease Door','StormWash+','3rd Rack','Wi-Fi'], '{"noise_dba": 42, "place_settings": 15}'),
  ('DW80B7070UG-AA', 'Bespoke AutoRelease Smart 42dBA Black', 'Bespoke', 879, ARRAY['AutoRelease Door','StormWash+','3rd Rack','Black Stainless'], '{"noise_dba": 42, "place_settings": 15}'),
  ('DW80BB707012AA', 'Bespoke AutoRelease 42dBA White', 'Bespoke', 799, ARRAY['AutoRelease Door','StormWash+','3rd Rack','White Glass'], '{"noise_dba": 42, "place_settings": 15}'),
  ('DW80CG5450SRAA', 'AutoRelease Smart 46dBA', NULL, NULL, ARRAY['AutoRelease Door','StormWash','Heat Dry','Wi-Fi'], '{"noise_dba": 46, "place_settings": 15}'),
  ('DW80CG5451SRAA', 'AutoRelease Smart 46dBA', NULL, NULL, ARRAY['AutoRelease Door','StormWash','Heat Dry'], '{"noise_dba": 46, "place_settings": 15}'),
  ('DW80CG4051SRAA', 'AutoRelease 51dBA', NULL, NULL, ARRAY['AutoRelease Door','3rd Rack','Heat Dry'], '{"noise_dba": 51, "place_settings": 15}'),
  ('DW80R9950US-AA', 'Linear Wash 39dBA Top Control', NULL, NULL, ARRAY['Linear Wash','AutoRelease Door','AquaBlast jets','3rd Rack'], '{"noise_dba": 39, "place_settings": 15}')
) AS v(model_number, model_name, series, msrp, features, specs)
WHERE m.slug = 'samsung' AND c.slug = 'dishwasher';
