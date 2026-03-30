-- ============================================================================
-- Supplemental models from training data (to be verified)
-- Source: Ultra-luxury agent JSON with 177 models
-- These supplement the web-researched data in files 03-13
-- ============================================================================

-- Wolf Gas Cooktops (not in previous files)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, NULL, 'gas', 'built-in', v.width, true, 20, false, ARRAY['Dual-stacked burners','Iconic red knobs','Seamless grates'], v.specs::jsonb, 'https://www.subzero-wolf.com/wolf/cooktops'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('CG152TF/S', '15" Transitional Gas Cooktop', 15, '{"burners": 2, "style": "transitional"}'),
  ('CG244TF/S', '24" Transitional Gas Cooktop', 24, '{"burners": 4, "style": "transitional"}'),
  ('CG304P/S', '30" Professional Gas Cooktop', 30, '{"burners": 4, "style": "professional"}'),
  ('CG304T/S', '30" Transitional Gas Cooktop', 30, '{"burners": 4, "style": "transitional"}'),
  ('CG365P/S', '36" Professional Gas Cooktop', 36, '{"burners": 5, "style": "professional"}'),
  ('CG365T/S', '36" Transitional Gas Cooktop', 36, '{"burners": 5, "style": "transitional"}')
) AS v(model_number, model_name, width, specs)
WHERE m.slug = 'wolf' AND c.slug = 'cooktop-gas';

-- Wolf Induction Cooktops
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, NULL, 'induction', 'built-in', v.width, true, 20, false, ARRAY['Induction cooking','Red knobs','Precise temperature control'], v.specs::jsonb, 'https://www.subzero-wolf.com/wolf/cooktops'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('CI152TF/S', '15" Transitional Induction Cooktop', 15, '{"zones": 2, "style": "transitional"}'),
  ('CI243TF/S', '24" Transitional Induction Cooktop', 24, '{"zones": 3, "style": "transitional"}'),
  ('CI304TF/S', '30" Transitional Induction Cooktop', 30, '{"zones": 4, "style": "transitional"}'),
  ('CI365TF/S', '36" Transitional Induction Cooktop', 36, '{"zones": 5, "style": "transitional"}')
) AS v(model_number, model_name, width, specs)
WHERE m.slug = 'wolf' AND c.slug = 'cooktop-induction';

-- Wolf Rangetops (professional rangetops separate from ranges)
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, NULL, 'gas', 'built-in', v.width, true, 20, false, v.features, v.specs::jsonb, 'https://www.subzero-wolf.com/wolf/cooktops'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('SRT304', '30" Sealed Burner Rangetop', 30, ARRAY['Sealed burners','Red knobs','Professional rangetop'], '{"burners": 4}'),
  ('SRT364C', '36" Sealed Rangetop - Charbroiler', 36, ARRAY['Infrared charbroiler','Sealed burners'], '{"burners": 4, "has_charbroiler": true}'),
  ('SRT364G', '36" Sealed Rangetop - Griddle', 36, ARRAY['Chrome griddle','Sealed burners'], '{"burners": 4, "has_griddle": true}'),
  ('SRT366', '36" Sealed Rangetop 6 Burners', 36, ARRAY['6 dual-stacked burners','Red knobs'], '{"burners": 6}'),
  ('SRT484CG', '48" Sealed Rangetop - Charbroiler + Griddle', 48, ARRAY['Charbroiler','Griddle','Sealed burners'], '{"burners": 4, "has_charbroiler": true, "has_griddle": true}'),
  ('SRT486G', '48" Sealed Rangetop 6 Burners + Griddle', 48, ARRAY['6 burners','Chrome griddle'], '{"burners": 6, "has_griddle": true}'),
  ('SRT488', '48" Sealed Rangetop 8 Burners', 48, ARRAY['8 dual-stacked burners','Professional'], '{"burners": 8}')
) AS v(model_number, model_name, width, features, specs)
WHERE m.slug = 'wolf' AND c.slug = 'cooktop-gas';

-- Wolf Ventilation / Range Hoods
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, NULL, NULL, v.install, v.width, true, 20, false, v.features, '{}', 'https://www.subzero-wolf.com/wolf/ventilation'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  -- Pro Wall Hoods
  ('PW302210', '30" Pro Wall Hood', 'range-hood-wall', 'wall-mount', 30, ARRAY['Professional style','Stainless steel','Halogen lighting']),
  ('PW362210', '36" Pro Wall Hood', 'range-hood-wall', 'wall-mount', 36, ARRAY['Professional style','Stainless steel']),
  ('PW422210', '42" Pro Wall Hood', 'range-hood-wall', 'wall-mount', 42, ARRAY['Professional style','Stainless steel']),
  ('PW482210', '48" Pro Wall Hood', 'range-hood-wall', 'wall-mount', 48, ARRAY['Professional style','Stainless steel']),
  ('PW602210', '60" Pro Wall Hood', 'range-hood-wall', 'wall-mount', 60, ARRAY['Professional style','60" wide']),
  -- Pro Island Hoods
  ('PI302210', '30" Pro Island Hood', 'range-hood-island', 'ceiling-mount', 30, ARRAY['Island mount','Professional style']),
  ('PI362210', '36" Pro Island Hood', 'range-hood-island', 'ceiling-mount', 36, ARRAY['Island mount','Professional style']),
  ('PI422210', '42" Pro Island Hood', 'range-hood-island', 'ceiling-mount', 42, ARRAY['Island mount','Professional style']),
  ('PI482210', '48" Pro Island Hood', 'range-hood-island', 'ceiling-mount', 48, ARRAY['Island mount','Professional style']),
  -- Low-Profile Hoods
  ('VC30S', '30" Low-Profile Wall Hood', 'range-hood-wall', 'wall-mount', 30, ARRAY['Low-profile design','Stainless steel']),
  ('VC36S', '36" Low-Profile Wall Hood', 'range-hood-wall', 'wall-mount', 36, ARRAY['Low-profile design','Stainless steel']),
  ('VC48S', '48" Low-Profile Wall Hood', 'range-hood-wall', 'wall-mount', 48, ARRAY['Low-profile design','Stainless steel']),
  -- Ventilation Inserts
  ('VW30S', '30" Hood Insert', 'range-hood-insert', 'built-in', 30, ARRAY['Insert for custom cabinetry','Blower included']),
  ('VW36S', '36" Hood Insert', 'range-hood-insert', 'built-in', 36, ARRAY['Insert for custom cabinetry','Blower included']),
  -- Downdraft
  ('DD30', '30" Downdraft Ventilation', 'range-hood-downdraft', 'built-in', 30, ARRAY['Pop-up downdraft','For island cooktops']),
  ('DD36', '36" Downdraft Ventilation', 'range-hood-downdraft', 'built-in', 36, ARRAY['Pop-up downdraft','For island cooktops']),
  ('DD46', '46" Downdraft Ventilation', 'range-hood-downdraft', 'built-in', 46, ARRAY['Pop-up downdraft','For large cooktops'])
) AS v(model_number, model_name, cat_slug, install, width, features)
WHERE m.slug = 'wolf' AND c.slug = v.cat_slug;

-- Wolf Warming Drawers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, NULL, 'electric', 'built-in', 30, true, 20, false, ARRAY['Warming drawer','Multiple temperature settings','Moist/Crisp modes'], '{}', 'https://www.subzero-wolf.com/wolf'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('WWD30', '30" Warming Drawer')
) AS v(model_number, model_name)
WHERE m.slug = 'wolf' AND c.slug = 'warming-drawer';

-- Wolf Coffee System
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, key_features, specs, product_url)
SELECT m.id, c.id, 'EC24/S', '24" Built-In Coffee System', NULL, 'electric', 'built-in', 24, true, 15, false, ARRAY['Built-in whole-bean coffee system','Plumbed water option','Multiple drink types','Adjustable grind and brew'], '{}', 'https://www.subzero-wolf.com/wolf'
FROM equipment_manufacturers m, equipment_categories c
WHERE m.slug = 'wolf' AND c.slug = 'coffee-system';

-- Sub-Zero Undercounter Ice Makers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'under-counter', v.width, true, 15, false, v.features, '{}', 'https://www.subzero-wolf.com/sub-zero'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('UC-15I', '15" Undercounter Ice Maker', 'Designer', 15, ARRAY['Clear ice cubes','15" width','Panel-ready']),
  ('UC-15IP', '15" Undercounter Ice Maker - Pro Handle', 'Designer', 15, ARRAY['Clear ice cubes','Pro handle','Panel-ready'])
) AS v(model_number, model_name, series, width, features)
WHERE m.slug = 'sub-zero' AND c.slug = 'ice-maker';
