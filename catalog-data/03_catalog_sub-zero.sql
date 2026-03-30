-- ============================================================================
-- Sub-Zero Equipment Catalog Entries
-- ============================================================================
-- Note: Each base model has many configurations (hinge, panel, handle).
-- We store the base model and note configurations in specs JSONB.

-- Classic Series - French Door
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'built-in', v.width, true, 20, true, true, v.features, v.specs::jsonb, v.url
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('CL4850UFD', '48" Classic French Door', 'Classic', 48, ARRAY['Split climate dual refrigeration','NASA-inspired air purification','ClearSight LED','Internal water dispenser available'], '{"capacity_cu_ft": 28.9, "configurations": ["S/P (Stainless Pro Handle)", "S/T (Stainless Tubular Handle)", "O/L (Panel Ready Left)", "O/R (Panel Ready Right)"], "has_internal_dispenser_variant": "CL4850UFDID"}', 'https://www.subzero-wolf.com/sub-zero/full-size-refrigeration/builtin-refrigerators'),
  ('CL4850UFDID', '48" Classic French Door w/ Internal Dispenser', 'Classic', 48, ARRAY['Split climate dual refrigeration','Internal filtered water dispenser','NASA-inspired air purification','ClearSight LED'], '{"capacity_cu_ft": 28.9, "configurations": ["S/P", "S/T", "O/L", "O/R"]}', 'https://www.subzero-wolf.com/sub-zero/full-size-refrigeration/builtin-refrigerators'),
  ('CL4250UFDID', '42" Classic French Door w/ Internal Dispenser', 'Classic', 42, ARRAY['Split climate dual refrigeration','Internal filtered water dispenser','NASA-inspired air purification'], '{"capacity_cu_ft": 24.5, "configurations": ["S/P", "S/T", "O/L", "O/R"]}', 'https://www.subzero-wolf.com/sub-zero/full-size-refrigeration/builtin-refrigerators'),
  ('CL3650UFD', '36" Classic French Door', 'Classic', 36, ARRAY['Split climate dual refrigeration','NASA-inspired air purification','ClearSight LED'], '{"capacity_cu_ft": 20.7, "configurations": ["S/P", "S/T", "O/L", "O/R"]}', 'https://www.subzero-wolf.com/sub-zero/full-size-refrigeration/builtin-refrigerators'),
  ('CL3650UFDID', '36" Classic French Door w/ Internal Dispenser', 'Classic', 36, ARRAY['Split climate dual refrigeration','Internal filtered water dispenser'], '{"capacity_cu_ft": 20.7, "configurations": ["S/P", "S/T", "O/L", "O/R"]}', 'https://www.subzero-wolf.com/sub-zero/full-size-refrigeration/builtin-refrigerators')
) AS v(model_number, model_name, series, width, features, specs, url)
WHERE m.slug = 'sub-zero' AND c.slug = 'refrigerator-built-in';

-- Classic Series - Over-and-Under (Bottom Freezer)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, 'Classic', NULL, 'built-in', v.width, true, 20, true, true, v.features, v.specs::jsonb, 'https://www.subzero-wolf.com/sub-zero/full-size-refrigeration/builtin-refrigerators'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('CL3650UID', '36" Classic Over-and-Under w/ Internal Dispenser', 36, ARRAY['Split climate dual refrigeration','Internal filtered water dispenser','Bottom freezer drawer'], '{"capacity_cu_ft": 20.7, "configurations": ["S/P", "S/T", "O/L", "O/R"]}'),
  ('CL3050U', '30" Classic Over-and-Under', 30, ARRAY['Split climate dual refrigeration','Bottom freezer drawer','NASA-inspired air purification'], '{"capacity_cu_ft": 15.6, "configurations": ["S/P", "S/T", "O/L", "O/R"]}')
) AS v(model_number, model_name, width, features, specs)
WHERE m.slug = 'sub-zero' AND c.slug = 'refrigerator-bottom-freezer';

-- Classic Series - Columns
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, 'Classic', NULL, 'built-in', v.width, true, 20, true, true, ARRAY['Split climate','NASA-inspired air purification','ClearSight LED'], v.specs::jsonb, 'https://www.subzero-wolf.com/sub-zero/full-size-refrigeration/builtin-refrigerators'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('CL3650R', '36" Classic All Refrigerator Column', 'refrigerator-column', 36, '{"capacity_cu_ft": 22.0, "type": "all_refrigerator", "configurations": ["S/P", "S/T", "O/L", "O/R"]}'),
  ('CL3650F', '36" Classic All Freezer Column', 'freezer-column', 36, '{"capacity_cu_ft": 20.0, "type": "all_freezer", "configurations": ["S/P", "S/T", "O/L", "O/R"]}')
) AS v(model_number, model_name, cat_slug, width, specs)
WHERE m.slug = 'sub-zero' AND c.slug = v.cat_slug;

-- Designer Series - Bottom Freezer
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, 'Designer', NULL, 'built-in', v.width, true, 20, true, true, ARRAY['Fully integrated panel-ready','Internal ice maker','Internal water dispenser','Split climate'], v.specs::jsonb, 'https://www.subzero-wolf.com/sub-zero/full-size-refrigeration/integrated-fridges'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DET3650CIID', '36" Designer Bottom Freezer w/ Ice & Dispenser', 36, '{"capacity_cu_ft": 19.6, "panel_ready": true, "configurations": ["/L (Left Hinge)", "/R (Right Hinge)"]}'),
  ('DET3050CIID', '30" Designer Bottom Freezer w/ Ice & Dispenser', 30, '{"capacity_cu_ft": 15.6, "panel_ready": true, "configurations": ["/L", "/R"]}')
) AS v(model_number, model_name, width, specs)
WHERE m.slug = 'sub-zero' AND c.slug = 'refrigerator-bottom-freezer';

-- Designer Series - Columns
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, 'Designer', NULL, 'built-in', v.width, true, 20, true, true, ARRAY['Fully integrated panel-ready','Split climate','NASA-inspired air purification'], v.specs::jsonb, 'https://www.subzero-wolf.com/sub-zero/full-size-refrigeration/integrated-fridges'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DEC3650RID', '36" Designer Column Refrigerator', 'refrigerator-column', 36, '{"capacity_cu_ft": 22.0, "panel_ready": true, "type": "all_refrigerator"}'),
  ('DEC3050RID', '30" Designer Column Refrigerator', 'refrigerator-column', 30, '{"capacity_cu_ft": 17.0, "panel_ready": true, "type": "all_refrigerator"}'),
  ('DEC3650FID', '36" Designer Column Freezer', 'freezer-column', 36, '{"capacity_cu_ft": 20.0, "panel_ready": true, "type": "all_freezer"}'),
  ('DEC3050FID', '30" Designer Column Freezer', 'freezer-column', 30, '{"capacity_cu_ft": 15.0, "panel_ready": true, "type": "all_freezer"}')
) AS v(model_number, model_name, cat_slug, width, specs)
WHERE m.slug = 'sub-zero' AND c.slug = v.cat_slug;

-- Designer Series - Undercounter
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, 'Designer', NULL, 'under-counter', 24, true, 20, false, true, v.features, v.specs::jsonb, 'https://www.subzero-wolf.com/sub-zero'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DEU2450R', '24" Designer Undercounter Refrigerator', 'refrigerator-under-counter', ARRAY['Panel-ready','Undercounter','ADA compliant option'], '{"panel_ready": true, "ada_compliant": true}'),
  ('DEU2450BG', '24" Designer Undercounter Beverage Center', 'wine-beverage', ARRAY['Panel-ready','Glass door','Undercounter'], '{"panel_ready": true, "door_type": "glass"}'),
  ('DEU2450W', '24" Designer Undercounter Wine Storage', 'wine-beverage', ARRAY['Panel-ready','Dual temperature zones','Wooden shelves'], '{"panel_ready": true, "dual_zone": true}')
) AS v(model_number, model_name, cat_slug, features, specs)
WHERE m.slug = 'sub-zero' AND c.slug = v.cat_slug;

-- PRO Series
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, 'PRO', NULL, 'built-in', v.width, true, 20, true, true, ARRAY['Stainless steel inside and out','Professional aesthetic','Split climate dual refrigeration','Exposed installation capable'], v.specs::jsonb, 'https://www.subzero-wolf.com/sub-zero'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('PRO4850', '48" PRO Refrigerator/Freezer', 48, '{"capacity_cu_ft": 28.9, "finish": "stainless_steel", "freestanding_capable": true}'),
  ('PRO3650', '36" PRO Refrigerator/Freezer', 36, '{"capacity_cu_ft": 20.7, "finish": "stainless_steel", "freestanding_capable": true}')
) AS v(model_number, model_name, width, specs)
WHERE m.slug = 'sub-zero' AND c.slug = 'refrigerator-built-in';

-- Wine Storage
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, v.install_type, v.width, true, 20, false, true, v.features, v.specs::jsonb, 'https://www.subzero-wolf.com/sub-zero/wine-storage'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('CL3050W', '30" Classic Wine Storage', 'Classic', 'built-in', 30, ARRAY['Dual temperature zones','UV-resistant glass door','Wooden shelves','Digital display'], '{"dual_zone": true, "bottle_capacity": 86}'),
  ('DEC3050W', '30" Designer Wine Storage Column', 'Designer', 'built-in', 30, ARRAY['Fully integrated panel-ready','Dual temperature zones','Wooden shelves'], '{"dual_zone": true, "panel_ready": true}')
) AS v(model_number, model_name, series, install_type, width, features, specs)
WHERE m.slug = 'sub-zero' AND c.slug = 'wine-beverage';
