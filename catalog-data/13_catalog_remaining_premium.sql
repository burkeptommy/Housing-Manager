-- ============================================================================
-- Remaining Premium & Luxury: Fisher & Paykel, Electrolux, Miele, Dacor, La Cornue
-- ============================================================================

-- ======================== FISHER & PAYKEL ========================

-- Fisher & Paykel DishDrawer Dishwashers
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'electric', 'built-in', 24, true, 12, true, true, v.features, v.specs::jsonb, 'https://www.fisherpaykel.com/us/dishwashing/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DD24DAX9N', 'Series 7 Contemporary Double DishDrawer', 'Series 7', ARRAY['Double DishDrawer','Two independent drawers','Contemporary style'], '{"drawers": 2, "design": "contemporary"}'),
  ('DD24DTI9N', 'Series 9 Integrated Tall Double DishDrawer', 'Series 9', ARRAY['Tall tub','Double DishDrawer','Fully integrated','Panel-ready'], '{"drawers": 2, "panel_ready": true, "tall_tub": true}'),
  ('DD24SI9N', 'Series 9 Integrated Single DishDrawer', 'Series 9', ARRAY['Single DishDrawer','ADA compliant','Panel-ready','Compact'], '{"drawers": 1, "panel_ready": true, "ada": true}'),
  ('DD24DV2T9N', 'Series 9 Professional Tall Double DishDrawer', 'Series 9', ARRAY['Professional style','Tall tub','Double DishDrawer'], '{"drawers": 2, "professional": true, "tall_tub": true}'),
  ('DD24DHTI9N', 'Fully Integrated DishDrawer - Panel Ready', NULL, ARRAY['Panel-ready','Fully integrated','DishDrawer'], '{"panel_ready": true}'),
  ('DD24DI9N', 'Fully Integrated DishDrawer - Panel Ready', NULL, ARRAY['Panel-ready','Fully integrated'], '{"panel_ready": true}')
) AS v(model_number, model_name, series, features, specs)
WHERE m.slug = 'fisher-paykel' AND c.slug = 'dishwasher';

-- Fisher & Paykel Gas Ranges
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'gas', 'freestanding', v.width, true, 18, false, v.features, v.specs::jsonb, 'https://www.fisherpaykel.com/us/cooking/ranges/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('RGV3-304-N', '30" Series 7 Pro Gas Range 4 Burners', 'Series 7', 30, ARRAY['Professional style','Sealed Dual Flow burners','Convection oven'], '{"burners": 4}'),
  ('RGV3-305-N', '30" Series 7 Pro Gas Range 5 Burners', 'Series 7', 30, ARRAY['Professional style','5 Dual Flow burners'], '{"burners": 5}'),
  ('RGV3-366-N', '36" Series 7 Pro Gas Range 6 Burners', 'Series 7', 36, ARRAY['Professional style','6 Dual Flow burners','23,500 BTU max','5.3 cu ft oven'], '{"burners": 6, "btu_max": 23500, "oven_cu_ft": 5.3}'),
  ('RGV3-488-N', '48" Series 7 Pro Gas Range 8 Burners', 'Series 7', 48, ARRAY['Professional style','8 Dual Flow burners','Dual ovens'], '{"burners": 8, "dual_oven": true}')
) AS v(model_number, model_name, series, width, features, specs)
WHERE m.slug = 'fisher-paykel' AND c.slug = 'range-gas';

-- Fisher & Paykel Dual Fuel Ranges
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, 'Series 9', 'dual-fuel', 'freestanding', v.width, true, 18, true, v.msrp, v.features, v.specs::jsonb, 'https://www.fisherpaykel.com/us/cooking/ranges/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('RDV3-304-N', '30" Series 9 Pro Dual Fuel Range 4 Burners', 30, NULL, ARRAY['Smart touchscreen guided cooking','Self-cleaning','Dual Flow burners','Convection electric oven'], '{"burners": 4}'),
  ('RDV2-364GD-N', '36" Series 9 Pro Dual Fuel 4 Burners + Griddle', 36, NULL, ARRAY['Griddle','Dual Flow burners','23,500 BTU max','Smart'], '{"burners": 4, "has_griddle": true, "btu_max": 23500}'),
  ('RDV3-366-N', '36" Series 9 Pro Smart Dual Fuel 6 Burners', 36, 11499, ARRAY['Smart connectivity','6 Dual Flow burners','Convection electric oven','Self-cleaning'], '{"burners": 6}')
) AS v(model_number, model_name, width, msrp, features, specs)
WHERE m.slug = 'fisher-paykel' AND c.slug = 'range-dual-fuel';

-- Fisher & Paykel Refrigerators
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, NULL, 'built-in', v.width, v.cap, 'cu_ft', true, 15, true, true, v.features, v.specs::jsonb, 'https://www.fisherpaykel.com/us/cooling/refrigeration/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('RS36A72J1N', 'Series 7 36" French Door', 'Series 7', 'refrigerator-built-in', 36, 16.8, ARRAY['Panel-ready','ActiveSmart technology','Built-in'], '{"panel_ready": true}'),
  ('RS32A72J1', 'Series 7 32" Integrated French Door', 'Series 7', 'refrigerator-built-in', 32, 14.7, ARRAY['Panel-ready','ActiveSmart','Integrated'], '{"panel_ready": true}'),
  ('RS3084SRK1', '30" Column Refrigerator', NULL, 'refrigerator-column', 30, 16.3, ARRAY['Panel-ready','Column refrigerator','ActiveSmart'], '{"panel_ready": true}'),
  ('RS2484SRK1', '24" Column Refrigerator', NULL, 'refrigerator-column', 24, 12.4, ARRAY['Panel-ready','Column refrigerator'], '{"panel_ready": true}'),
  ('RS3084FLJK1', '30" Column Freezer', NULL, 'freezer-column', 30, 15.6, ARRAY['Panel-ready','Column freezer'], '{"panel_ready": true}'),
  ('RS2484FLJK1', '24" Column Freezer', NULL, 'freezer-column', 24, 11.9, ARRAY['Panel-ready','Column freezer'], '{"panel_ready": true}')
) AS v(model_number, model_name, series, cat_slug, width, cap, features, specs)
WHERE m.slug = 'fisher-paykel' AND c.slug = v.cat_slug;

-- ======================== ELECTROLUX ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, NULL, v.fuel, v.install, v.width, v.cap, v.cap_unit, true, v.lifespan, true, true, v.features, '{}', 'https://www.electrolux.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  -- Ranges
  ('ECFD3668AS', '36" Dual Fuel Range 6 Burners - SS', 'dual-fuel', 'freestanding', 'range-dual-fuel', 36, 4.4, 'cu_ft', 15, ARRAY['True convection','Dual brass power burners','Steam clean','Soft close door','Temp probe']),
  -- Refrigerators
  ('ERMC2295AS', '36" Counter-Depth French Door 21.8 Cu Ft', NULL, 'freestanding', 'refrigerator-french-door', 36, 21.8, 'cu_ft', 13, ARRAY['Counter-depth','LuxCool cooling','Pure Advantage filtration']),
  ('ERFG2393AS', '36" Counter-Depth French Door 22.6 Cu Ft', NULL, 'freestanding', 'refrigerator-french-door', 36, 22.6, 'cu_ft', 13, ARRAY['Counter-depth','LuxCool cooling']),
  ('EI33AR80WS', '33" Column Refrigerator 18.9 Cu Ft', NULL, 'freestanding', 'refrigerator-column', 33, 18.9, 'cu_ft', 13, ARRAY['All refrigerator column','PureAdvantage filtration']),
  ('EI33AF80WS', '33" Column Freezer 18.9 Cu Ft', NULL, 'freestanding', 'freezer-column', 33, 18.9, 'cu_ft', 13, ARRAY['All freezer column']),
  -- Wall Ovens
  ('ECWS3012AS', '30" Single Wall Oven - SS', 'electric', 'built-in', 'wall-oven-single', 30, 5.1, 'cu_ft', 14, ARRAY['True convection','Self-clean','Luxury-Design lighting']),
  -- Microwaves
  ('EMBD3010AS', '1.6 Cu Ft Built-In Microwave', 'electric', 'built-in', 'microwave-built-in', 30, 1.6, 'cu_ft', 9, ARRAY['Built-in','Drop-down door']),
  ('EMOW1911AS', '1.9 Cu Ft OTR Convection Microwave', 'electric', 'over-the-range', 'microwave-otr', 30, 1.9, 'cu_ft', 9, ARRAY['Convection microwave','Over-the-range','Sensor cooking'])
) AS v(model_number, model_name, fuel, install, cat_slug, width, cap, cap_unit, lifespan, features)
WHERE m.slug = 'electrolux' AND c.slug = v.cat_slug;

-- ======================== MIELE ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, 'built-in', 24, true, 20, true, true, v.features, v.specs::jsonb, 'https://www.mieleusa.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  -- Dishwashers
  ('G7166SCVI', 'G7000 Entry Dishwasher - Panel Ready', 'Generation 7000', 'electric', 'dishwasher', ARRAY['AutoDos automatic detergent dispensing','Panel-ready','Fully integrated','WiFi/Home Connect'], '{"autodos": true, "panel_ready": true}'),
  ('G7316SCUXXL', 'G7000 Dishwasher AutoDos XXL', 'Generation 7000', 'electric', 'dishwasher', ARRAY['AutoDos','AutoStart','XXL tub','Wi-Fi','Glass buttons'], '{"autodos": true, "xxl_tub": true}'),
  ('G7566SCVISF', 'G7000 Premium Dishwasher', 'Generation 7000', 'electric', 'dishwasher', ARRAY['AutoDos','LED interior','Knock2Open','Extra quiet mode'], '{"autodos": true, "knock2open": true}'),
  ('G7966SCVI', 'G7000 Top Dishwasher M-Touch', 'Generation 7000', 'electric', 'dishwasher', ARRAY['M-Touch controls','AutoDos','5-year warranty','Every innovation'], '{"autodos": true, "m_touch": true}'),
  ('G7986SCVIK2O', 'G7000 Flagship Dishwasher 37dBA', 'Generation 7000', 'electric', 'dishwasher', ARRAY['37 dBA quietest','AutoDos','Knock2Open','M-Touch','Replaces G7966'], '{"noise_dba": 37, "autodos": true, "knock2open": true}'),
  -- Combi-Steam Oven
  ('DGC7860CTS', 'Gen 7000 Combi-Steam Oven 24"', 'Generation 7000', 'electric', 'steam-oven', ARRAY['DualSteam','M-Touch Display','Motion React','FoodView camera','XXL cooking compartment'], '{"capacity_cu_ft": 2.54, "steam": true, "camera": true}'),
  -- Coffee Machines
  ('CVA7440', 'Gen 7000 Built-In Coffee Machine', 'Generation 7000', 'electric', 'coffee-system', ARRAY['Whole-bean system','12 beverage types','Built-in','Available in Clean Touch Steel and Graphite Grey'], '{"beverages": 12}'),
  ('CVA7845', 'Gen 7000 Coffee Machine DirectWater', 'Generation 7000', 'electric', 'coffee-system', ARRAY['DirectWater plumbed connection','Top-tier model','Built-in','Multiple beverages'], '{"plumbed_water": true}'),
  ('CVA7840', 'Gen 7000 Built-In Coffee Machine Premium', 'Generation 7000', 'electric', 'coffee-system', ARRAY['Premium model','Built-in','Multiple beverages'], '{}')
) AS v(model_number, model_name, series, fuel, cat_slug, features, specs)
WHERE m.slug = 'miele' AND c.slug = v.cat_slug;

-- ======================== DACOR ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, v.width, v.cap, v.cap_unit, true, 18, true, v.features, v.specs::jsonb, 'https://www.dacor.com/us/products/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  -- Refrigerators
  ('DRF365300AP', '36" Panel Ready French Door 21.3 Cu Ft', NULL, NULL, 'built-in', 'refrigerator-built-in', 36, 21.3, 'cu_ft', ARRAY['Panel-ready','Counter-depth','Built-in','SmartThings'], '{"panel_ready": true}'),
  ('DRF36C500SR', '36" French Door 22.8 Cu Ft - Silver SS', 'Contemporary', NULL, 'freestanding', 'refrigerator-french-door', 36, 22.8, 'cu_ft', ARRAY['Silver stainless','Counter-depth','FreshZone drawer'], '{}'),
  ('DRS425300SR', '42" Side-by-Side 24 Cu Ft - Silver SS', NULL, NULL, 'built-in', 'refrigerator-built-in', 42, 24.0, 'cu_ft', ARRAY['Built-in','Side-by-side','Silver stainless'], '{}'),
  ('DRF487500AP', '48" Panel Ready French Door 27.7 Cu Ft', NULL, NULL, 'built-in', 'refrigerator-built-in', 48, 27.7, 'cu_ft', ARRAY['Panel-ready','48" width','Built-in'], '{"panel_ready": true}'),
  ('DRZ24980LAP', 'Contemporary Column Freezer 13.6 Cu Ft', 'Contemporary', NULL, 'built-in', 'freezer-column', 24, 13.6, 'cu_ft', ARRAY['Panel-ready','Column freezer','Contemporary style'], '{"panel_ready": true}'),
  -- Ranges
  ('DOP36T86GLS', 'Transitional 36" Gas Range - Silver SS', 'Transitional', 'gas', 'freestanding', 'range-gas', 36, NULL, NULL, ARRAY['Transitional design','7" LCD touchscreen','Wi-Fi','Dual-stack brass burners'], '{}'),
  ('DOP36C86DLS', 'Contemporary 36" Dual Fuel Steam Range', 'Contemporary', 'dual-fuel', 'freestanding', 'range-dual-fuel', 36, NULL, NULL, ARRAY['RealSteam oven','LCD touchscreen','Contemporary design','Wi-Fi'], '{}'),
  ('DOP30T840GS', 'Transitional 30" Gas Range - Silver SS', 'Transitional', 'gas', 'freestanding', 'range-gas', 30, NULL, NULL, ARRAY['Transitional design','LCD touchscreen','Wi-Fi'], '{}'),
  -- Dishwasher
  ('DDW24G9000APDA', '24" Panel Ready Dishwasher', NULL, 'electric', 'built-in', 'dishwasher', 24, NULL, NULL, ARRAY['Panel-ready','Fully integrated','SmartThings'], '{"panel_ready": true}'),
  -- Cooktop
  ('DTG36M955FM', '36" Gas Cooktop', 'Contemporary', 'gas', 'built-in', 'cooktop-gas', 36, NULL, NULL, ARRAY['Contemporary style','Brass burners'], '{}'),
  -- Microwave Drawers
  ('DMR30M977WM', 'Contemporary 30" Microwave Drawer', 'Contemporary', 'electric', 'built-in', 'microwave-drawer', 30, 1.2, 'cu_ft', ARRAY['Microwave-in-a-drawer','Graphite stainless','Contemporary'], '{}'),
  ('DMR24M977WM', 'Contemporary 24" Microwave Drawer', 'Contemporary', 'electric', 'built-in', 'microwave-drawer', 24, 1.2, 'cu_ft', ARRAY['Microwave-in-a-drawer','Graphite stainless'], '{}')
) AS v(model_number, model_name, series, fuel, install, cat_slug, width, cap, cap_unit, features, specs)
WHERE m.slug = 'dacor' AND c.slug = v.cat_slug;

-- ======================== LA CORNUE ========================

-- La Cornue CornuFé Series
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, 'CornuFé', 'dual-fuel', 'freestanding', v.width, true, 25, false, v.msrp, v.features, v.specs::jsonb, 'https://www.lacornueusa.com/cornufe'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('C1IN', 'CornuFé 110 (43") Dual Fuel - Stainless Steel', 43, 14205, ARRAY['Two electric convection ovens','Five gas burners','Seven cooking modes','11 color options','3 trim options','French engineered'], '{"ovens": 2, "burners": 5, "btu_max": 17000, "weight_lbs": 350, "made_in": "England"}'),
  ('C9IN', 'CornuFé 90 Albertine (36") Dual Fuel - SS', 36, 11525, ARRAY['Single multi-function convection oven','Five gas burners','Seven cooking modes','Designed for US market','5-year warranty'], '{"ovens": 1, "burners": 5, "btu_max": 17000, "weight_lbs": 315, "made_in": "England"}')
) AS v(model_number, model_name, width, msrp, features, specs)
WHERE m.slug = 'la-cornue' AND c.slug = 'range-dual-fuel';

-- La Cornue Château Series
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, is_current_model, expected_lifespan_years, wifi_enabled, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, 'Château', 'dual-fuel', 'freestanding', v.width, true, 30, false, v.msrp, ARRAY['Hand-crafted in France','Bespoke/custom built to order','Vaulted oven design','50+ enamel/metal finishes','11 trim options','Natural convection'], v.specs::jsonb, 'https://www.lacornueusa.com/resources/chateau-specs-and-manuals'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('G47STANDARD', 'Château 75 (~30")', 30, 35000, '{"ovens": 1, "made_in": "France", "custom": true, "rangetop_configs": 5}'),
  ('G49STANDARD', 'Château 90 (~36")', 36, 45000, '{"ovens": 1, "made_in": "France", "custom": true, "rangetop_configs": 6}'),
  ('G42STANDARD', 'Château 120 (~48")', 48, 60000, '{"ovens": 2, "made_in": "France", "custom": true, "rangetop_configs": 8}'),
  ('G45STANDARD', 'Château 150 (~60") - Most Popular', 60, 80000, '{"ovens": 2, "made_in": "France", "custom": true, "rangetop_configs": 9, "most_popular": true}'),
  ('G46STANDARD', 'Château 165 (~65")', 65, 100000, '{"ovens": 2, "made_in": "France", "custom": true, "rangetop_configs": 5}'),
  ('G48STANDARD', 'Grand Palais 180 (~71") - Crown Jewel', 71, 175000, '{"ovens": 2, "made_in": "France", "custom": true, "rangetop_configs": 7, "flagship": true}')
) AS v(model_number, model_name, width, msrp, specs)
WHERE m.slug = 'la-cornue' AND c.slug = 'range-dual-fuel';
