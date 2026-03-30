-- ============================================================================
-- Premium Brands: KitchenAid, Bosch
-- ============================================================================

-- ======================== KITCHENAID ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, NULL, v.fuel, v.install, v.width, v.cap, v.cap_unit, true, v.lifespan, v.wifi, true, v.features, v.specs::jsonb, 'https://www.kitchenaid.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  -- French Door Refrigerators
  ('KRFC300ESS', '36" Counter-Depth French Door 20 Cu Ft', NULL, 'freestanding', 'refrigerator-french-door', 36, 20.0, 'cu_ft', 13, false, ARRAY['ExtendFresh temp management','Metal wine rack','Interior water dispenser','Produce preserver'], '{}'),
  ('KRFC704FPS', '36" Counter-Depth French Door 23.8 Cu Ft Platinum', NULL, 'freestanding', 'refrigerator-french-door', 36, 23.8, 'cu_ft', 13, false, ARRAY['Platinum interior','PrintShield finish','Preserva food care','Under-shelf prep zone'], '{}'),
  ('KRFC136RPS', '36" Counter-Depth French Door 20 Cu Ft - Current', NULL, 'freestanding', 'refrigerator-french-door', 36, 20.0, 'cu_ft', 13, false, ARRAY['Counter-depth','Interior dispense','PrintShield'], '{}'),
  ('KRFC302EPA', '36" Counter-Depth French Door Panel Ready', NULL, 'built-in', 'refrigerator-french-door', 36, 22.0, 'cu_ft', 13, false, ARRAY['Panel-ready','Counter-depth','Custom panel'], '{"panel_ready": true}'),
  ('KRFC736SPS', '36" Counter-Depth Smart French Door', NULL, 'freestanding', 'refrigerator-french-door', 36, NULL, NULL, 13, true, ARRAY['Smart/Wi-Fi','Counter-depth','PrintShield'], '{}'),
  -- Dishwashers
  ('KDTE204KPS', '24" Integrated Control Dishwasher 39dBA', 'electric', 'built-in', 'dishwasher', 24, NULL, NULL, 10, false, ARRAY['39 dBA','ProWash cycle','3rd utensil rack','Sani rinse','Express wash','PrintShield'], '{"noise_dba": 39, "place_settings": 13}'),
  -- Electric Ranges
  ('KSEG700ESS', '30" Electric Slide-In Convection Range - SS', 'electric', 'slide-in', 'range-electric', 30, 6.3, 'cu_ft', 15, false, ARRAY['Even-Heat true convection','Steam rack','Slide-in design','AquaLift self-clean'], '{}'),
  ('KSEG700EBS', '30" Electric Slide-In Convection - Black SS', 'electric', 'slide-in', 'range-electric', 30, 6.3, 'cu_ft', 15, false, ARRAY['Even-Heat true convection','PrintShield black stainless','Steam rack'], '{"color": "black_stainless"}'),
  ('KSEG950ESS', '30" Electric Slide-In Downdraft Range - SS', 'electric', 'slide-in', 'range-electric', 30, 6.4, 'cu_ft', 15, false, ARRAY['Built-in downdraft','Even-Heat true convection','SatinGlide racks','EasyConvect conversion'], '{"has_downdraft": true}'),
  -- Microwaves
  ('KMHC319LSS', '1.9 Cu Ft OTR Convection Microwave Air Fry - SS', 'electric', 'over-the-range', 'microwave-otr', 30, 1.9, 'cu_ft', 9, false, ARRAY['Convection cooking','Air fry mode','Sensor cooking','400 CFM ventilation'], '{"watts": 1000}'),
  ('KMHC319ESS', '1.9 Cu Ft OTR Convection Microwave - SS', 'electric', 'over-the-range', 'microwave-otr', 30, 1.9, 'cu_ft', 9, false, ARRAY['Convection cooking','Sensor cooking','400 CFM'], '{"watts": 1000}')
) AS v(model_number, model_name, fuel, install, cat_slug, width, cap, cap_unit, lifespan, wifi, features, specs)
WHERE m.slug = 'kitchenaid' AND c.slug = v.cat_slug;

-- ======================== BOSCH ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, v.width, v.cap, v.cap_unit, true, v.lifespan, v.wifi, true, v.msrp, v.features, v.specs::jsonb, 'https://www.bosch-home.com/us/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  -- Dishwashers - 800 Series
  ('SHP78CM5N', '800 Series 24" Pocket Handle Dishwasher 42dBA', '800 Series', 'electric', 'built-in', 'dishwasher', 24, NULL, NULL, 12, true, 1249, ARRAY['CrystalDry','42 dBA','PrecisionWash','3rd rack','Home Connect'], '{"noise_dba": 42, "drying": "crystaldry"}'),
  ('SHP878ZD5N', '800 Series 24" Pocket Handle w/ ExtraScrub', '800 Series', 'electric', 'built-in', 'dishwasher', 24, NULL, NULL, 12, true, NULL, ARRAY['CrystalDry','ExtraScrub','42 dBA','3rd rack','Home Connect'], '{"noise_dba": 42, "drying": "crystaldry"}'),
  ('SHPM88Z75N', '800 Series 24" Pocket Handle Dishwasher', '800 Series', 'electric', 'built-in', 'dishwasher', 24, NULL, NULL, 12, true, NULL, ARRAY['CrystalDry','42 dBA','PrecisionWash','3rd rack'], '{"noise_dba": 42}'),
  -- Dishwashers - 500 Series
  ('SHP65CM5N', '500 Series 24" Pocket Handle Dishwasher 44dBA', '500 Series', 'electric', 'built-in', 'dishwasher', 24, NULL, NULL, 12, true, 999, ARRAY['AutoAir dry','44 dBA','PrecisionWash','3rd rack','RackMatic'], '{"noise_dba": 44, "drying": "autoair"}'),
  ('SHP65DM5N', '500 Series 24" Pocket Handle Dishwasher', '500 Series', 'electric', 'built-in', 'dishwasher', 24, NULL, NULL, 12, true, 999, ARRAY['AutoAir dry','44 dBA','PrecisionWash'], '{"noise_dba": 44}'),
  -- Dishwashers - 100 Series
  ('SHE41CM5N', '100 Series 24" Recessed Handle Dishwasher', '100 Series', 'electric', 'built-in', 'dishwasher', 24, NULL, NULL, 12, false, 569, ARRAY['PureDry','50 dBA','Hybrid tub','Speed60 cycle'], '{"noise_dba": 50, "drying": "puredry"}'),
  -- Dishwashers - Benchmark
  ('SHP9PCM5N', 'Benchmark 24" Pocket Handle Dishwasher 38dBA', 'Benchmark', 'electric', 'built-in', 'dishwasher', 24, NULL, NULL, 12, true, 1799, ARRAY['CrystalDry+','38 dBA','PrecisionWash','Premium 3rd rack','Home Connect'], '{"noise_dba": 38, "drying": "crystaldry_plus"}'),
  ('SHX89PW75N', 'Benchmark 24" Bar Handle Dishwasher', 'Benchmark', 'electric', 'built-in', 'dishwasher', 24, NULL, NULL, 12, true, NULL, ARRAY['CrystalDry','Adjustable racks','Ultra-quiet'], '{"noise_dba": 38}'),
  -- Wall Ovens - 800 Series
  ('HBL8651UC', '800 Series 30" Double Wall Oven - SS', '800 Series', 'electric', 'built-in', 'wall-oven-double', 30, 9.2, 'cu_ft', 14, true, NULL, ARRAY['True European convection','Self-clean','12 cooking modes','Stainless steel'], '{}'),
  ('HBL8453UC', '800 Series 30" Single Wall Oven - SS', '800 Series', 'electric', 'built-in', 'wall-oven-single', 30, 4.6, 'cu_ft', 14, true, NULL, ARRAY['True European convection','Self-clean','Eco Clean'], '{}'),
  ('HBL8443UC', '800 Series 30" Single Wall Oven - Black SS', '800 Series', 'electric', 'built-in', 'wall-oven-single', 30, 4.6, 'cu_ft', 14, true, NULL, ARRAY['True European convection','Black stainless steel'], '{"color": "black_stainless"}'),
  -- Wall Ovens - 500 Series
  ('HBL5451UC', '500 Series 30" Single Wall Oven - SS', '500 Series', 'electric', 'built-in', 'wall-oven-single', 30, 4.6, 'cu_ft', 14, false, NULL, ARRAY['European convection','Self-clean','Heavy-duty metal knobs'], '{}'),
  ('HBL5351UC', '500 Series 30" Single Wall Oven - SS', '500 Series', 'electric', 'built-in', 'wall-oven-single', 30, 4.6, 'cu_ft', 14, false, NULL, ARRAY['Eco Clean','Bread proofing','Heavy-duty metal knobs'], '{}'),
  -- Cooktops - 800 Series Gas
  ('NGM8059UC', '800 Series 30" Gas Cooktop - SS', '800 Series', 'gas', 'built-in', 'cooktop-gas', 30, NULL, NULL, 15, false, 1649, ARRAY['FlameSelect 9 heat levels','5 sealed burners','Continuous grates'], '{"burners": 5, "btu_max": 19000}'),
  ('NGM8058UC', '800 Series 30" Gas Cooktop', '800 Series', 'gas', 'built-in', 'cooktop-gas', 30, NULL, NULL, 15, false, NULL, ARRAY['FlameSelect','5 burners','OptiSim burner'], '{"burners": 5}'),
  -- Cooktops - 500 Series Gas
  ('NGM5659UC', '500 Series 36" Gas Cooktop', '500 Series', 'gas', 'built-in', 'cooktop-gas', 36, NULL, NULL, 15, false, 1399, ARRAY['5 sealed burners','Continuous grates'], '{"burners": 5}'),
  -- Cooktops - Benchmark Gas
  ('NGMP659UC', 'Benchmark 36" Gas Cooktop', 'Benchmark', 'gas', 'built-in', 'cooktop-gas', 36, NULL, NULL, 15, false, 2199, ARRAY['FlameSelect','18,000 BTU power burner','Premium continuous grates'], '{"burners": 5, "btu_max": 18000}'),
  -- Cooktops - Induction
  ('NIT8060SUC', '800 Series 30" Induction Cooktop', '800 Series', 'induction', 'built-in', 'cooktop-induction', 30, NULL, NULL, 14, true, NULL, ARRAY['SpeedBoost','AutoChef','FlexInduction','Home Connect'], '{}'),
  ('NIT8060UC', '800 Series 30" Induction Cooktop', '800 Series', 'induction', 'built-in', 'cooktop-induction', 30, NULL, NULL, 14, false, NULL, ARRAY['SpeedBoost','4 induction elements'], '{}')
) AS v(model_number, model_name, series, fuel, install, cat_slug, width, cap, cap_unit, lifespan, wifi, msrp, features, specs)
WHERE m.slug = 'bosch' AND c.slug = v.cat_slug;
