-- ============================================================================
-- Gaggenau Equipment Catalog Entries
-- ============================================================================

-- Gaggenau Ovens
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'built-in', v.width, true, 20, true, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  -- Iconic
  ('EB333', 'EB 333 Iconic Oven', NULL, 'wall-oven-single', 36, ARRAY['Hand-built icon for 30+ years','17 heating methods','TFT touch display','Rotisserie','Pyrolytic self-clean'], '{"capacity_liters": 110, "heating_methods": 17}', 'https://www.gaggenau.com/us/products/ovens/eb-333'),
  -- 400 Series Ovens
  ('BO480', '400 Series Oven 30"', '400 Series', 'wall-oven-single', 30, ARRAY['17 heating methods','TFT touch display','Rotisserie spit','Auto side-opening door','Pyrolytic self-clean'], '{"capacity_liters": 110, "heating_methods": 17, "door": "side_opening"}', 'https://www.gaggenau.com/us/products/ovens'),
  ('BO450', '400 Series Oven 24"', '400 Series', 'wall-oven-single', 24, ARRAY['17 heating methods','TFT touch display','Pyrolytic self-clean'], '{"capacity_liters": 76, "heating_methods": 17}', 'https://www.gaggenau.com/us/products/ovens'),
  -- 400 Series Combi-Steam
  ('BS470', '400 Series Combi-Steam Oven 30"', '400 Series', 'steam-oven', 30, ARRAY['Steam + convection','Sous vide','Full surface grill','Auto self-clean'], '{"capacity_liters": 50, "steam": true, "sous_vide": true}', 'https://www.gaggenau.com/us/products/ovens'),
  ('BS450', '400 Series Combi-Steam Compact 24"', '400 Series', 'steam-oven', 24, ARRAY['Steam + convection','Water tank','Compact'], '{"capacity_liters": 34, "steam": true, "compact": true}', 'https://www.gaggenau.com/us/products/ovens'),
  -- 400 Series Combi-Microwave
  ('BM484', '400 Series Combi-Microwave 30"', '400 Series', 'speed-oven', 30, ARRAY['Microwave + convection','Up to 1000W','Compact'], '{"capacity_liters": 36, "microwave_watts": 1000}', 'https://www.gaggenau.com/us/products/ovens'),
  ('BM454', '400 Series Combi-Microwave 24"', '400 Series', 'speed-oven', 24, ARRAY['Microwave + convection','Compact'], '{"capacity_liters": 36, "microwave_watts": 1000}', 'https://www.gaggenau.com/us/products/ovens'),
  -- 200 Series Ovens
  ('BOP250', '200 Series Single Oven 24"', '200 Series', 'wall-oven-single', 24, ARRAY['Single oven','Multiple heating methods'], '{"capacity_liters": 76, "note": "Discontinuing December 2025"}', 'https://www.gaggenau.com/us/products/ovens'),
  ('BSP270', '200 Series Combi-Steam 24"', '200 Series', 'steam-oven', 24, ARRAY['Combi-steam','200 series'], '{"steam": true}', 'https://www.gaggenau.com/us/products/ovens'),
  -- Expressive Series
  ('GO470720', 'Expressive Series Single Oven 24"', 'Expressive', 'wall-oven-single', 24, ARRAY['Bauhaus-inspired design','Smoked grey glass','Control ring','6.8" TFT touch'], '{"design": "expressive", "display": "6.8_inch_tft"}', 'https://www.gaggenau.com/us/products/ovens'),
  ('GM450120', 'Expressive Combi-Microwave 30"', 'Expressive', 'speed-oven', 30, ARRAY['Bauhaus-inspired','Smoked grey glass','Control ring'], '{"design": "expressive"}', 'https://www.gaggenau.com/us/products/ovens'),
  -- Espresso
  ('CM450', '400 Series Espresso Machine 24"', '400 Series', 'coffee-system', 24, ARRAY['Fully automatic','12 beverage types','Built-in','Plumbed water option'], '{"beverages": 12, "built_in": true}', 'https://www.gaggenau.com/us/products/ovens')
) AS v(model_number, model_name, series, cat_slug, width, features, specs, url)
WHERE m.slug = 'gaggenau' AND c.slug = v.cat_slug;

-- Gaggenau Cooktops
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'built-in', v.width, true, 20, true, v.features, v.specs::jsonb, 'https://www.gaggenau.com/us/products/cooktops'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  -- 400 Series Full Surface Induction
  ('CX492612', 'Vario 400 Full Surface Induction 36"', '400 Series', 'induction', 'cooktop-induction', 36, ARRAY['Full surface induction','TFT display','Professional/Dynamic cooking','Flex cooking zones'], '{"zones": "full_surface", "flex": true}'),
  ('CX482', 'Vario 400 Full Surface Induction 30"', '400 Series', 'induction', 'cooktop-induction', 30, ARRAY['Full surface induction','TFT display'], '{"zones": "full_surface"}'),
  -- 400 Series Flex Induction
  ('VI492', '400 Series Flex Induction 36"', '400 Series', 'induction', 'cooktop-induction', 36, ARRAY['Flex induction zones','TFT display'], '{"zones": 5, "flex": true}'),
  ('VI482', '400 Series Flex Induction 30"', '400 Series', 'induction', 'cooktop-induction', 30, ARRAY['Flex induction zones'], '{"zones": 4, "flex": true}'),
  ('VI462', '400 Series Flex Induction 24"', '400 Series', 'induction', 'cooktop-induction', 24, ARRAY['Flex induction zones','Compact'], '{"zones": 3, "flex": true}'),
  ('VI422', '400 Series Vario Flex Induction 15"', '400 Series', 'induction', 'cooktop-induction', 15, ARRAY['Vario modular','Flex induction'], '{"zones": 2, "vario_modular": true}'),
  -- 400 Series with Integrated Ventilation
  ('CV492', '400 Series Flex Induction w/ Ventilation 36"', '400 Series', 'induction', 'cooktop-induction', 36, ARRAY['Integrated downdraft ventilation','Flex induction','TFT display'], '{"zones": 5, "integrated_ventilation": true}'),
  -- 400 Series Gas
  ('VG491211CA', 'Vario 400 Gas Cooktop 36"', '400 Series', 'gas', 'cooktop-gas', 36, ARRAY['Vario series','Cast iron grates','Wok burner'], '{"burners": 5}'),
  ('VG425', 'Vario 400 Gas 15"', '400 Series', 'gas', 'cooktop-gas', 15, ARRAY['Vario modular gas'], '{"burners": 2, "vario_modular": true}'),
  -- 400 Series Specialty
  ('VP414611', 'Vario 400 Teppan Yaki 15"', '400 Series', 'electric', 'cooktop-electric', 15, ARRAY['Teppan Yaki surface','Vario modular','Stainless steel cooking surface'], '{"type": "teppan_yaki", "vario_modular": true}'),
  ('VR414', 'Vario 400 Electric Grill 15"', '400 Series', 'electric', 'cooktop-electric', 15, ARRAY['Electric grill','Vario modular','Lava stone'], '{"type": "electric_grill", "vario_modular": true}'),
  -- 400 Series Downdraft
  ('VL414', 'Vario 400 Downdraft Ventilation', '400 Series', NULL, 'range-hood-downdraft', 6, ARRAY['Downdraft ventilation','Vario modular','Flush mount'], '{"type": "downdraft", "vario_modular": true}'),
  -- 200 Series
  ('VG295250CA', '200 Series Gas Cooktop 36"', '200 Series', 'gas', 'cooktop-gas', 36, ARRAY['200 series','5 burners','Cast iron grates'], '{"burners": 5}'),
  ('CG280212CA', '200 Series Gas Cooktop 30"', '200 Series', 'gas', 'cooktop-gas', 30, ARRAY['200 series','4 burners'], '{"burners": 4}'),
  ('CI292', '200 Series Flex Induction 36"', '200 Series', 'induction', 'cooktop-induction', 36, ARRAY['200 series','Flex induction'], '{"zones": 5, "flex": true}'),
  ('CI282', '200 Series Flex Induction 30"', '200 Series', 'induction', 'cooktop-induction', 30, ARRAY['200 series','Flex induction'], '{"zones": 4, "flex": true}'),
  ('VP230620', '200 Series Vario Teppan Yaki 12"', '200 Series', 'electric', 'cooktop-electric', 12, ARRAY['Teppan Yaki','200 series','Vario modular'], '{"type": "teppan_yaki", "vario_modular": true}'),
  ('VR230620', '200 Series Vario Electric Grill', '200 Series', 'electric', 'cooktop-electric', 12, ARRAY['Electric grill','200 series','Vario modular'], '{"type": "electric_grill", "vario_modular": true}')
) AS v(model_number, model_name, series, fuel, cat_slug, width, features, specs)
WHERE m.slug = 'gaggenau' AND c.slug = v.cat_slug;

-- Gaggenau Refrigeration
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'built-in', v.width, true, 20, true, v.features, v.specs::jsonb, 'https://www.gaggenau.com/us/products/refrigerators'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  -- Fridge-Freezer Combinations
  ('RVB497790', '400 Series Fridge-Freezer 36" Dark Brushed SS', '400 Series', 'refrigerator-built-in', 36, ARRAY['Dark brushed stainless steel','Bottom freezer','Panel-ready'], '{"capacity_cu_ft": 20.0}'),
  ('RVB477790', '400 Series Fridge-Freezer 30"', '400 Series', 'refrigerator-bottom-freezer', 30, ARRAY['Bottom freezer','Panel-ready'], '{"capacity_cu_ft": 16.7}'),
  -- Column Refrigerators
  ('RC462705', '400 Series Column Refrigerator 24"', '400 Series', 'refrigerator-column', 24, ARRAY['Panel-ready','Fully integrated','Vario 400'], '{"capacity_cu_ft": 13.0, "panel_ready": true}'),
  ('RC472', '400 Series Column Refrigerator', '400 Series', 'refrigerator-column', 30, ARRAY['Panel-ready','Fully integrated'], '{"panel_ready": true}'),
  -- Column Freezers
  ('RF411705', '400 Series Column Freezer', '400 Series', 'freezer-column', 18, ARRAY['Panel-ready','Fully integrated'], '{"capacity_cu_ft": 8.6, "panel_ready": true}'),
  ('RF463707', '400 Series Column Freezer', '400 Series', 'freezer-column', 24, ARRAY['Panel-ready','Fully integrated'], '{"capacity_cu_ft": 11.2, "panel_ready": true}'),
  ('RF461705', '400 Series Column Freezer', '400 Series', 'freezer-column', 24, ARRAY['Panel-ready','Fully integrated'], '{"capacity_cu_ft": 12.2, "panel_ready": true}'),
  -- 200 Series
  ('RB282705', '200 Series Bottom Freezer 22"', '200 Series', 'refrigerator-bottom-freezer', 22, ARRAY['200 series','Panel-ready','Compact'], '{"capacity_cu_ft": 8.3, "panel_ready": true}')
) AS v(model_number, model_name, series, cat_slug, width, features, specs)
WHERE m.slug = 'gaggenau' AND c.slug = v.cat_slug;

-- Gaggenau Dishwashers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'built-in', 24, true, 15, true, v.features, v.specs::jsonb, 'https://www.gaggenau.com/us/products-list/dishwashing'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DF480700', '400 Series Dishwasher - Push-to-Open', '400 Series', ARRAY['Push-to-open door','8 programs','Aqua Sensor','Zeolite drying','Home Connect'], '{"programs": 8, "zeolite_drying": true, "push_to_open": true}'),
  ('DF281760', '200 Series Dishwasher - Fully Integrated', '200 Series', ARRAY['Fully integrated','Panel-ready','Home Connect'], '{"panel_ready": true}'),
  ('DF210701', '200 Series Dishwasher', '200 Series', ARRAY['Fully integrated','24" panel-ready'], '{"panel_ready": true}'),
  ('DF211701', '200 Series Dishwasher - Cutlery Tray', '200 Series', ARRAY['Fully integrated','Cutlery tray','Panel-ready'], '{"panel_ready": true, "cutlery_tray": true}')
) AS v(model_number, model_name, series, features, specs)
WHERE m.slug = 'gaggenau' AND c.slug = 'dishwasher';

-- Gaggenau Specialty
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'built-in', 24, true, 20, false, v.features, v.specs::jsonb, 'https://www.gaggenau.com/us/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DV461710', '400 Series Vacuuming Drawer 24"', '400 Series', 'vacuum-sealer', ARRAY['Built-in vacuum drawer','Stainless steel','Sous vide preparation'], '{"type": "vacuum_drawer"}'),
  ('MW420621', '400 Series Microwave Drawer', '400 Series', 'microwave-drawer', ARRAY['Built-in microwave drawer','1.2 cu ft','Stainless steel'], '{"capacity_cu_ft": 1.2, "type": "drawer"}')
) AS v(model_number, model_name, series, cat_slug, features, specs)
WHERE m.slug = 'gaggenau' AND c.slug = v.cat_slug;
