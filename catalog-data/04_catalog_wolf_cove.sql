-- ============================================================================
-- Wolf Equipment Catalog Entries
-- ============================================================================

-- Wolf Dual Fuel Ranges
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, NULL, 'dual-fuel', 'freestanding', v.width, true, 20, false, v.features, v.specs::jsonb, 'https://www.subzero-wolf.com/wolf/ranges'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DF36650', '36" Dual Fuel Range - All Burners', 36, ARRAY['Dual-stacked burners','Electric convection oven','Iconic red knobs','Self-clean'], '{"burners": 6, "oven_capacity_cu_ft": 5.5, "btu_max": 20000}'),
  ('DF36450C', '36" Dual Fuel Range - Charbroiler', 36, ARRAY['Dual-stacked burners','Infrared charbroiler','Electric convection oven','Red knobs'], '{"burners": 4, "has_charbroiler": true, "oven_capacity_cu_ft": 5.5}'),
  ('DF36450G', '36" Dual Fuel Range - Griddle', 36, ARRAY['Dual-stacked burners','Chrome griddle','Electric convection oven','Red knobs'], '{"burners": 4, "has_griddle": true, "oven_capacity_cu_ft": 5.5}'),
  ('DF48450F', '48" Dual Fuel Range - French Top', 48, ARRAY['French top','Dual-stacked burners','Dual convection ovens','Red knobs'], '{"burners": 4, "has_french_top": true, "dual_oven": true}'),
  ('DF48650', '48" Dual Fuel Range - All Burners', 48, ARRAY['Dual-stacked burners','Dual convection ovens','Red knobs'], '{"burners": 6, "dual_oven": true, "btu_max": 20000}'),
  ('DF60650', '60" Dual Fuel Range', 60, ARRAY['Dual-stacked burners','Dual convection ovens','Griddle or charbroiler','Red knobs'], '{"burners": 6, "dual_oven": true, "has_griddle": true}')
) AS v(model_number, model_name, width, features, specs)
WHERE m.slug = 'wolf' AND c.slug = 'range-dual-fuel';

-- Wolf Gas Ranges
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, NULL, 'gas', 'freestanding', v.width, true, 20, false, ARRAY['Dual-stacked burners','Gas convection oven','Iconic red knobs','Infrared broiler'], v.specs::jsonb, 'https://www.subzero-wolf.com/wolf/ranges'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('GR364C', '36" Gas Range - Charbroiler', 36, '{"burners": 4, "has_charbroiler": true, "btu_max": 20000}'),
  ('GR364G', '36" Gas Range - Griddle', 36, '{"burners": 4, "has_griddle": true, "btu_max": 20000}'),
  ('GR366', '36" Gas Range - All Burners', 36, '{"burners": 6, "btu_max": 20000}'),
  ('GR484C', '48" Gas Range - Charbroiler', 48, '{"burners": 4, "has_charbroiler": true, "dual_oven": true}'),
  ('GR484G', '48" Gas Range - Griddle', 48, '{"burners": 4, "has_griddle": true, "dual_oven": true}'),
  ('GR486', '48" Gas Range - All Burners', 48, '{"burners": 6, "dual_oven": true}'),
  ('GR606C', '60" Gas Range - Charbroiler', 60, '{"burners": 6, "has_charbroiler": true, "dual_oven": true}'),
  ('GR606G', '60" Gas Range - Griddle', 60, '{"burners": 6, "has_griddle": true, "dual_oven": true}')
) AS v(model_number, model_name, width, specs)
WHERE m.slug = 'wolf' AND c.slug = 'range-gas';

-- Wolf Induction Ranges
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, NULL, 'induction', 'freestanding', v.width, true, 20, false, ARRAY['Induction cooking zones','Electric convection oven','Red knobs','Professional styling'], v.specs::jsonb, 'https://www.subzero-wolf.com/wolf/ranges'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('IR36450', '36" Induction Range', 36, '{"zones": 5, "oven_capacity_cu_ft": 5.5}'),
  ('IR48450', '48" Induction Range', 48, '{"zones": 5, "dual_oven": true}'),
  ('PROIR36', '36" Professional Induction Range', 36, '{"zones": 5, "oven_capacity_cu_ft": 5.5, "professional_series": true}'),
  ('IR51P', '48" Professional Induction Range', 48, '{"zones": 6, "dual_oven": true, "professional_series": true}')
) AS v(model_number, model_name, width, specs)
WHERE m.slug = 'wolf' AND c.slug = 'range-induction';

-- Wolf Wall Ovens
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'built-in', 30, true, 20, false, v.features, v.specs::jsonb, 'https://www.subzero-wolf.com/wolf/ovens'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('SO30TE', 'E Series 30" Single Oven', 'E Series', 'wall-oven-single', ARRAY['Dual VertiFlow convection','10 cooking modes','Self-clean','Gourmet mode'], '{"oven_capacity_cu_ft": 5.1}'),
  ('SO30TM', 'M Series 30" Single Oven', 'M Series', 'wall-oven-single', ARRAY['Dual VertiFlow convection','Advanced touch controls','Self-clean','Gourmet mode'], '{"oven_capacity_cu_ft": 5.1, "most_advanced": true}'),
  ('DO30TE', 'E Series 30" Double Oven', 'E Series', 'wall-oven-double', ARRAY['Dual VertiFlow convection','Both ovens full-size','Self-clean'], '{"total_capacity_cu_ft": 10.2}'),
  ('DO30TM', 'M Series 30" Double Oven', 'M Series', 'wall-oven-double', ARRAY['Dual VertiFlow convection','Advanced touch controls','Self-clean'], '{"total_capacity_cu_ft": 10.2}'),
  ('CSO3050PE', 'Convection Steam Oven 30"', NULL, 'steam-oven', ARRAY['Steam + convection cooking','Climate sensor','Gourmet mode','Self-clean'], '{"oven_capacity_cu_ft": 2.4, "steam": true}'),
  ('SPO3050TE', 'Speed Oven 30"', NULL, 'speed-oven', ARRAY['Convection + microwave','10 cooking modes','Gourmet mode'], '{"oven_capacity_cu_ft": 1.8, "microwave_watts": 1000}')
) AS v(model_number, model_name, series, cat_slug, features, specs)
WHERE m.slug = 'wolf' AND c.slug = v.cat_slug;

-- ============================================================================
-- Cove Equipment Catalog Entries
-- ============================================================================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, NULL, 'electric', 'built-in', 24, true, 15, true, true, v.features, v.specs::jsonb, 'https://www.subzero-wolf.com/cove'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DW2450', '24" Cove Dishwasher - Panel Ready', ARRAY['Panel-ready','3 spray arms','LED interior lighting','Quiet operation','FlexFit rack system'], '{"noise_dba": 40, "place_settings": 16, "panel_ready": true, "cycles": 6}'),
  ('DW2450WS', '24" Cove Dishwasher - Stainless Steel', ARRAY['Stainless steel door','3 spray arms','LED interior lighting','FlexFit rack system'], '{"noise_dba": 40, "place_settings": 16, "panel_ready": false, "finish": "stainless_steel", "cycles": 6}')
) AS v(model_number, model_name, features, specs)
WHERE m.slug = 'cove' AND c.slug = 'dishwasher';
