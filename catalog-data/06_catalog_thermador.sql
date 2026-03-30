-- ============================================================================
-- Thermador Equipment Catalog Entries
-- ============================================================================

-- Thermador Refrigerators - Bottom Freezer French Door
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'built-in', v.width, true, 18, v.wifi, true, v.features, v.specs::jsonb, 'https://www.thermador.com/us/products-list/refrigeration'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  -- 48" French Door
  ('T48BT110NS', '48" Built-In French Door - Masterpiece Handles', 'Masterpiece', 48, true, ARRAY['ThermaFlex drawer','Diamond ice maker','SoftClose doors'], '{"capacity_cu_ft": 26.7, "handles": "masterpiece"}'),
  ('T48BT120NS', '48" Built-In French Door - Professional Handles', 'Professional', 48, true, ARRAY['ThermaFlex drawer','Diamond ice maker','SoftClose doors'], '{"capacity_cu_ft": 26.7, "handles": "professional"}'),
  -- 42" French Door
  ('T42BT110NS', '42" Built-In French Door - Masterpiece Handles', 'Masterpiece', 42, true, ARRAY['ThermaFlex drawer','SuperCool','SuperFreeze'], '{"capacity_cu_ft": 23.1, "handles": "masterpiece"}'),
  ('T42BT120NS', '42" Built-In French Door - Professional Handles', 'Professional', 42, true, ARRAY['ThermaFlex drawer','SuperCool','SuperFreeze'], '{"capacity_cu_ft": 23.1, "handles": "professional"}'),
  ('T42IT100NP', '42" Built-In French Door - Panel Ready', NULL, 42, true, ARRAY['ThermaFlex drawer','Panel ready','Custom panel'], '{"capacity_cu_ft": 23.1, "panel_ready": true}'),
  -- 36" French Door
  ('T36BT110NS', '36" Built-In French Door - Masterpiece Handles', 'Masterpiece', 36, true, ARRAY['ThermaFlex drawer','Diamond ice maker'], '{"capacity_cu_ft": 19.5, "handles": "masterpiece"}'),
  ('T36BT120NS', '36" Built-In French Door - Professional Handles', 'Professional', 36, true, ARRAY['ThermaFlex drawer','Diamond ice maker'], '{"capacity_cu_ft": 19.5, "handles": "professional"}'),
  ('T36BT820NS', '36" Fully Flush French Door - Professional', 'Professional', 36, true, ARRAY['Fully flush installation','ThermaFlex drawer'], '{"capacity_cu_ft": 19.5, "flush_mount": true}'),
  ('T36BT925NS', '36" Smart French Door - Professional', 'Professional', 36, true, ARRAY['Smart Home Connect','Diamond ice maker','UltraClarity water filter'], '{"capacity_cu_ft": 19.4, "smart": true}'),
  ('T36IT100NP', '36" Built-In French Door - Panel Ready', NULL, 36, true, ARRAY['Panel ready','ThermaFlex drawer'], '{"capacity_cu_ft": 19.5, "panel_ready": true}'),
  ('T36IT800NP', '36" Panel Ready French Door', NULL, 36, true, ARRAY['Panel ready','Adjustable glass shelves'], '{"capacity_cu_ft": 19.5, "panel_ready": true}'),
  ('T36IT900NP', '36" Freedom French Door - Panel Ready', 'Freedom', 36, true, ARRAY['Freedom collection','Panel ready','ThermaFlex drawer'], '{"capacity_cu_ft": 19.5, "panel_ready": true, "freedom_collection": true}'),
  -- 36" Freestanding
  ('T36FT820NS', '36" Freestanding French Door - Counter Depth', NULL, 36, true, ARRAY['Counter-depth','Freestanding','Professional handles'], '{"capacity_cu_ft": 20.8, "counter_depth": true, "freestanding": true}'),
  ('T36FL821NS', '36" Freestanding French Door Bottom Mount', NULL, 36, true, ARRAY['Freestanding','Professional handles'], '{"capacity_cu_ft": 20.4, "freestanding": true}')
) AS v(model_number, model_name, series, width, wifi, features, specs)
WHERE m.slug = 'thermador' AND c.slug = 'refrigerator-built-in';

-- Thermador Bottom Freezer (2-Door)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'built-in', v.width, true, 18, true, true, ARRAY['SuperCool','SuperFreeze','SoftClose'], v.specs::jsonb, 'https://www.thermador.com/us/products-list/refrigeration'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('T36BB120SS', '36" Bottom Freezer - Professional Handles', 'Professional', 36, '{"capacity_cu_ft": 19.0, "handles": "professional"}'),
  ('T36BB110SS', '36" Bottom Freezer - Masterpiece Handles', 'Masterpiece', 36, '{"capacity_cu_ft": 19.0, "handles": "masterpiece"}'),
  ('T30BB820SS', '30" Bottom Freezer - Stainless Steel', NULL, 30, '{"capacity_cu_ft": 16.0}'),
  ('T30IB800SP', '30" Bottom Freezer - Panel Ready', NULL, 30, '{"capacity_cu_ft": 16.0, "panel_ready": true}'),
  ('T30IB905SP', '30" Freedom Bottom Freezer - Panel Ready', 'Freedom', 30, '{"capacity_cu_ft": 16.0, "panel_ready": true, "freedom_collection": true}')
) AS v(model_number, model_name, series, width, specs)
WHERE m.slug = 'thermador' AND c.slug = 'refrigerator-bottom-freezer';

-- Thermador Columns
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, 'Freedom', NULL, 'built-in', v.width, true, 18, true, true, ARRAY['Freedom collection','Panel ready','Individual compressor'], v.specs::jsonb, 'https://www.thermador.com/us/products-list/refrigeration'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('T24IR800SP', '24" Refrigerator Column - Panel Ready', 'refrigerator-column', 24, '{"capacity_cu_ft": 13.0, "panel_ready": true}'),
  ('T30IR800SP', '30" Refrigerator Column - Panel Ready', 'refrigerator-column', 30, '{"capacity_cu_ft": 17.0, "panel_ready": true}')
) AS v(model_number, model_name, cat_slug, width, specs)
WHERE m.slug = 'thermador' AND c.slug = v.cat_slug;

-- Thermador Under-Counter
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'under-counter', 24, true, 18, false, true, v.features, v.specs::jsonb, 'https://www.thermador.com/us/products-list/refrigeration/under-counter'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('T24UR925DS', '24" Under-Counter Double Drawer - Professional', 'Professional', 'refrigerator-under-counter', ARRAY['Double drawer','Professional handle','Panel-ready option'], '{"handles": "professional"}'),
  ('T24UR915DS', '24" Under-Counter Double Drawer - Masterpiece', 'Masterpiece', 'refrigerator-under-counter', ARRAY['Double drawer','Masterpiece handle'], '{"handles": "masterpiece"}'),
  ('T24UC925DS', '24" Under-Counter Combo - Professional', 'Professional', 'refrigerator-under-counter', ARRAY['Refrigerator/Freezer combo','Double drawer','Professional handle'], '{"type": "combo", "handles": "professional"}'),
  ('T24UC915DS', '24" Under-Counter Combo - Masterpiece', 'Masterpiece', 'refrigerator-under-counter', ARRAY['Refrigerator/Freezer combo','Double drawer','Masterpiece handle'], '{"type": "combo", "handles": "masterpiece"}')
) AS v(model_number, model_name, series, cat_slug, features, specs)
WHERE m.slug = 'thermador' AND c.slug = v.cat_slug;
