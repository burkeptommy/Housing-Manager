-- ============================================================================
-- JennAir Equipment Catalog Entries
-- ============================================================================

-- JennAir Refrigerators
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'built-in', v.width, v.cap, 'cu_ft', true, 18, true, true, v.features, v.specs::jsonb, 'https://www.jennair.com/refrigeration.html'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  -- Column Refrigerators (Panel Ready)
  ('JBRFR24IGX', '24" Panel Ready Column Refrigerator', NULL, 'refrigerator-column', 24, 13.0, ARRAY['Panel-ready','Fully integrated','Obsidian interior'], '{"panel_ready": true}'),
  ('JBRFR30IGX', '30" Panel Ready Column Refrigerator', NULL, 'refrigerator-column', 30, 17.0, ARRAY['Panel-ready','Fully integrated','Obsidian interior'], '{"panel_ready": true}'),
  ('JBRFR36IGX', '36" Panel Ready Column Refrigerator', NULL, 'refrigerator-column', 36, 20.0, ARRAY['Panel-ready','Fully integrated'], '{"panel_ready": true}'),
  ('JBRFSR30RX', '30" Panel Ready Column w/ SlimTech', NULL, 'refrigerator-column', 30, 17.0, ARRAY['SlimTech insulation','Panel-ready','More interior space'], '{"panel_ready": true, "slimtech": true}'),
  -- Column Freezers (Panel Ready)
  ('JBZFR18IGX', '18" Panel Ready Column Freezer', NULL, 'freezer-column', 18, 8.0, ARRAY['Panel-ready','Column freezer'], '{"panel_ready": true}'),
  ('JBZFR24IGX', '24" Panel Ready Column Freezer', NULL, 'freezer-column', 24, 13.0, ARRAY['Panel-ready','Column freezer'], '{"panel_ready": true}'),
  ('JBZFR30IGX', '30" Panel Ready Column Freezer', NULL, 'freezer-column', 30, 17.0, ARRAY['Panel-ready','Column freezer'], '{"panel_ready": true}'),
  -- Built-In French Door (Panel Ready)
  ('JF36NXFXDE', '36" Panel Ready French Door', NULL, 'refrigerator-built-in', 36, 20.8, ARRAY['Panel-ready','Built-in','Counter-depth','Obsidian interior'], '{"panel_ready": true, "counter_depth": true}'),
  ('JF42NXFXDE', '42" Panel Ready French Door', NULL, 'refrigerator-built-in', 42, 24.2, ARRAY['Panel-ready','Built-in','Counter-depth'], '{"panel_ready": true, "counter_depth": true}'),
  -- NOIR Panel Kits
  ('JBFFS36NHM', 'NOIR 36" French Door Panel-Kit', 'NOIR', 'refrigerator-built-in', 36, NULL, ARRAY['NOIR design','Floating glass black','French door'], '{"design": "noir"}'),
  ('JBSFS42NHM', 'NOIR 42" Side-by-Side Panel-Kit', 'NOIR', 'refrigerator-built-in', 42, NULL, ARRAY['NOIR design','Side-by-side'], '{"design": "noir"}'),
  ('JBSFS48NHM', 'NOIR 48" Side-by-Side Panel-Kit', 'NOIR', 'refrigerator-built-in', 48, NULL, ARRAY['NOIR design','Side-by-side'], '{"design": "noir"}'),
  -- RISE Stainless
  ('JBSS48E22L', 'RISE 48" Side-by-Side - SS', 'RISE', 'refrigerator-built-in', 48, 29.4, ARRAY['RISE design','Stainless steel','Built-in','Counter-depth'], '{"design": "rise"}'),
  -- Freestanding
  ('JFFCF72DKL', 'RISE 36" French Door Freestanding', 'RISE', 'refrigerator-french-door', 36, 21.9, ARRAY['RISE design','Freestanding','Stainless steel'], '{"design": "rise", "freestanding": true}'),
  ('JFFCC72EHL', 'RISE 36" Counter-Depth French Door', 'RISE', 'refrigerator-french-door', 36, 23.8, ARRAY['RISE design','Counter-depth','Obsidian interior'], '{"design": "rise", "counter_depth": true}'),
  ('JFFCF72DKM', 'NOIR 36" French Door Freestanding', 'NOIR', 'refrigerator-french-door', 36, 21.9, ARRAY['NOIR design','Freestanding'], '{"design": "noir", "freestanding": true}')
) AS v(model_number, model_name, series, cat_slug, width, cap, features, specs)
WHERE m.slug = 'jennair' AND c.slug = v.cat_slug;

-- JennAir Ranges
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'freestanding', 30, true, 18, true, v.features, v.specs::jsonb, 'https://www.jennair.com/ranges.html'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('JGRP430HL', 'RISE 30" Gas Range', 'RISE', 'gas', 'range-gas', ARRAY['RISE design','Professional-style','Dual-stacked burners'], '{"design": "rise", "burners": 4}'),
  ('JGRP430HM', 'NOIR 30" Gas Range', 'NOIR', 'gas', 'range-gas', ARRAY['NOIR design','Professional-style','Dual-stacked burners'], '{"design": "noir", "burners": 4}')
) AS v(model_number, model_name, series, fuel, cat_slug, features, specs)
WHERE m.slug = 'jennair' AND c.slug = v.cat_slug;

-- JennAir Wall Ovens
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'built-in', 30, true, 18, true, v.features, v.specs::jsonb, 'https://www.jennair.com/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('JOESC730RM', 'NOIR 30" Single Wall Oven', 'NOIR', 'wall-oven-single', ARRAY['NOIR design','V2 Vertical Dual-Fan True Convection'], '{"design": "noir"}'),
  ('JOEDC730RM', 'NOIR 30" Double Wall Oven', 'NOIR', 'wall-oven-double', ARRAY['NOIR design','V2 Vertical Dual-Fan True Convection'], '{"design": "noir"}'),
  ('JOECC530RL', 'RISE 30" Oven/Micro Combo', 'RISE', 'wall-oven-combo', ARRAY['RISE design','MultiMode convection','Microwave combo'], '{"design": "rise"}')
) AS v(model_number, model_name, series, cat_slug, features, specs)
WHERE m.slug = 'jennair' AND c.slug = v.cat_slug;

-- JennAir Dishwashers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'built-in', 24, true, 12, true, true, v.features, v.specs::jsonb, 'https://www.jennair.com/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('JDPSS244PM', 'NOIR 24" Dishwasher', 'NOIR', ARRAY['NOIR design','Panel-ready option','Quiet operation'], '{"design": "noir"}'),
  ('JDPSS244PL', 'RISE 24" Dishwasher', 'RISE', ARRAY['RISE design','Panel-ready option','Quiet operation'], '{"design": "rise"}')
) AS v(model_number, model_name, series, features, specs)
WHERE m.slug = 'jennair' AND c.slug = 'dishwasher';

-- JennAir Microwaves
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', v.install, v.width, true, 12, true, v.features, v.specs::jsonb, 'https://www.jennair.com/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('JMHF730RBL', 'OTR Microwave Floating Glass Black', NULL, 'microwave-otr', 'over-the-range', 30, ARRAY['Floating glass black','1.1 cu ft'], '{"capacity_cu_ft": 1.1}'),
  ('JMDFS24HM', 'NOIR Under Counter Microwave', 'NOIR', 'microwave-drawer', 'built-in', 24, ARRAY['NOIR design','Under counter','Drawer style','1.2 cu ft'], '{"capacity_cu_ft": 1.2, "design": "noir"}'),
  ('JMDFS24JL', 'RISE Under Counter Microwave', 'RISE', 'microwave-drawer', 'built-in', 24, ARRAY['RISE design','Under counter','Drawer style','1.2 cu ft'], '{"capacity_cu_ft": 1.2, "design": "rise"}'),
  ('JMDFS30HL', 'RISE Built-In Microwave 30"', 'RISE', 'microwave-built-in', 'built-in', 30, ARRAY['RISE design','Built-in','1.2 cu ft'], '{"capacity_cu_ft": 1.2, "design": "rise"}')
) AS v(model_number, model_name, series, cat_slug, install, width, features, specs)
WHERE m.slug = 'jennair' AND c.slug = v.cat_slug;

-- ============================================================================
-- Monogram Equipment Catalog Entries
-- ============================================================================

-- Monogram Professional Ranges - Dual Fuel
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'dual-fuel', 'freestanding', v.width, true, 20, true, v.msrp, ARRAY['Professional-grade','Wi-Fi connected','Precision machining','Commercial-grade materials'], v.specs::jsonb, 'https://www.monogram.com/ranges/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('ZDP304NPSS', '30" Dual-Fuel Range 4 Burners', NULL, 30, NULL, '{"burners": 4}'),
  ('ZDP366NTSS', 'Statement 36" Dual-Fuel Range', 'Statement', 36, 10700, '{"burners": 6, "collection": "statement"}'),
  ('ZDP364NDPSS', '36" Dual-Fuel Range 4 Burners + Griddle', NULL, 36, NULL, '{"burners": 4, "has_griddle": true}'),
  ('ZDP364NRPSS', '36" Dual-Fuel Range 6 Burners', NULL, 36, NULL, '{"burners": 6}'),
  ('ZDP486NDTSS', 'Statement 48" Dual-Fuel 6 Burners + Griddle', 'Statement', 48, 14600, '{"burners": 6, "has_griddle": true, "collection": "statement"}'),
  ('ZDP486NRPSS', '48" Dual-Fuel Range 6 Burners', NULL, 48, NULL, '{"burners": 6}'),
  ('ZDP484NGPSS', '48" Dual-Fuel Range 4 Burners + Griddle', NULL, 48, NULL, '{"burners": 4, "has_griddle": true}')
) AS v(model_number, model_name, series, width, msrp, specs)
WHERE m.slug = 'monogram' AND c.slug = 'range-dual-fuel';

-- Monogram Professional Ranges - Gas
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'gas', 'freestanding', v.width, true, 20, true, v.msrp, ARRAY['All-gas professional','Wi-Fi connected','TrueTemp system'], v.specs::jsonb, 'https://www.monogram.com/ranges/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('ZGP304NRSS', '30" Gas Range 4 Burners', NULL, 30, NULL, '{"burners": 4}'),
  ('ZGP304NTSS', 'Statement 30" Gas Range', 'Statement', 30, NULL, '{"burners": 4, "collection": "statement"}'),
  ('ZGP366NTSS', 'Statement 36" Gas Range', 'Statement', 36, 7400, '{"burners": 6, "collection": "statement"}'),
  ('ZGP366NRSS', '36" Gas Range 6 Burners', NULL, 36, NULL, '{"burners": 6}'),
  ('ZGP364NDRSS', '36" Gas Range 4 Burners + Griddle', NULL, 36, NULL, '{"burners": 4, "has_griddle": true}'),
  ('ZGP486NDTSS', 'Statement 48" Gas Range 6 + Griddle', 'Statement', 48, NULL, '{"burners": 6, "has_griddle": true, "collection": "statement"}'),
  ('ZGP486NRRSS', '48" Gas Range 6 Burners', NULL, 48, NULL, '{"burners": 6}')
) AS v(model_number, model_name, series, width, msrp, specs)
WHERE m.slug = 'monogram' AND c.slug = 'range-gas';

-- Monogram Wall Ovens
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'built-in', 30, true, 18, true, v.msrp, v.features, '{}', 'https://www.monogram.com/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('ZKD90DPSN', 'Statement 27" Double Wall Oven', 'Statement', 'wall-oven-double', 8600, ARRAY['Statement collection','Smart convection','Wi-Fi']),
  ('ZTDX1FPSNSS', 'Statement 30" Double Wall Oven', 'Statement', 'wall-oven-double', 8600, ARRAY['Statement collection','True European convection']),
  ('ZSB9132VSS', '30" Speed Oven', NULL, 'speed-oven', 3900, ARRAY['Convection + microwave','Speed cooking']),
  ('ZEP30SKSS', 'Indoor Pizza Oven', NULL, 'wall-oven-single', NULL, ARRAY['Indoor pizza oven','Ventless','Commercial-grade'])
) AS v(model_number, model_name, series, cat_slug, msrp, features)
WHERE m.slug = 'monogram' AND c.slug = v.cat_slug;

-- Monogram Cooktops
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, NULL, v.fuel, 'built-in', v.width, true, 18, true, v.msrp, v.features, '{}', 'https://www.monogram.com/cooktops-rangetops'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('ZHU36RSTSS', '36" Induction Cooktop', 'induction', 'cooktop-induction', 36, 3600, ARRAY['Induction','Glide Touch controls','Wi-Fi']),
  ('ZHU36RSJSS', '36" Induction Cooktop', 'induction', 'cooktop-induction', 36, NULL, ARRAY['Induction','Touch controls']),
  ('ZHU30RSJSS', '30" Induction Cooktop', 'induction', 'cooktop-induction', 30, NULL, ARRAY['Induction','Touch controls']),
  ('ZEU36RSJSS', '36" Electric Cooktop', 'electric', 'cooktop-electric', 36, NULL, ARRAY['Radiant electric','Touch controls']),
  ('ZEU30RSJSS', '30" Electric Cooktop', 'electric', 'cooktop-electric', 30, NULL, ARRAY['Radiant electric','Touch controls']),
  ('ZGU486NDPSS', '48" Gas Rangetop', 'gas', 'cooktop-gas', 48, NULL, ARRAY['Professional rangetop','6 burners + griddle']),
  ('ZGU366NPSS', '36" Gas Rangetop 6 Burners', 'gas', 'cooktop-gas', 36, NULL, ARRAY['Professional rangetop','6 burners'])
) AS v(model_number, model_name, fuel, cat_slug, width, msrp, features)
WHERE m.slug = 'monogram' AND c.slug = v.cat_slug;

-- Monogram Refrigerators
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, NULL, NULL, 'built-in', v.width, v.cap, 'cu_ft', true, 18, true, v.msrp, v.features, v.specs::jsonb, 'https://www.monogram.com/full-size-refrigerators/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('ZIS480NNII', '48" Panel-Ready Side-by-Side', 'refrigerator-built-in', 48, 29.5, 11500, ARRAY['Panel-ready','Built-in','Smart features','Climate-control'], '{"panel_ready": true}'),
  ('ZISS480DNSS', '48" Stainless Side-by-Side', 'refrigerator-built-in', 48, 28.6, NULL, ARRAY['Stainless steel','Built-in','Counter-depth','Smart'], '{}'),
  ('ZIR301NPNII', '30" Column Refrigerator - Panel Ready', 'refrigerator-column', 30, NULL, NULL, ARRAY['Panel-ready','Column refrigerator','Smart'], '{"panel_ready": true}'),
  ('ZIF301NPNII', '30" Column Freezer - Panel Ready', 'freezer-column', 30, NULL, NULL, ARRAY['Panel-ready','Column freezer','Smart'], '{"panel_ready": true}')
) AS v(model_number, model_name, cat_slug, width, cap, msrp, features, specs)
WHERE m.slug = 'monogram' AND c.slug = v.cat_slug;

-- Monogram Dishwasher
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, key_features, specs, product_url)
SELECT m.id, c.id, 'ZDT925SINII', '24" Panel-Ready Fully Integrated Dishwasher', NULL, 'electric', 'built-in', 24, true, 15, true, ARRAY['Panel-ready','Fully integrated','Statement or Minimalist handles','Wi-Fi connected'], '{"panel_ready": true}', 'https://www.monogram.com/'
FROM equipment_manufacturers m, equipment_categories c
WHERE m.slug = 'monogram' AND c.slug = 'dishwasher';
