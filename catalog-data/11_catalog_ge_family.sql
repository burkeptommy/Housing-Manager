-- ============================================================================
-- GE Family: GE Appliances (base), GE Profile, Café
-- ============================================================================

-- ======================== GE APPLIANCES (BASE LINE) ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, NULL, v.fuel, v.install, v.width, v.cap, v.cap_unit, true, v.lifespan, v.wifi, true, v.features, v.specs::jsonb, 'https://www.geappliances.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  -- French Door Refrigerators
  ('GFE26JYMFS', 'ENERGY STAR 25.7 Cu Ft French Door - SS', NULL, 'freestanding', 'refrigerator-french-door', 36, 25.7, 'cu_ft', 13, false, ARRAY['Internal water dispenser','Full-width deli drawer','Fingerprint resistant'], '{}'),
  ('GFE26JSMSS', 'ENERGY STAR 25.6 Cu Ft French Door', NULL, 'freestanding', 'refrigerator-french-door', 36, 25.6, 'cu_ft', 13, false, ARRAY['External ice/water dispenser','Turbo Cool setting'], '{}'),
  ('GNE27JYMFS', '27 Cu Ft French Door - SS', NULL, 'freestanding', 'refrigerator-french-door', 36, 27.0, 'cu_ft', 13, false, ARRAY['Fingerprint resistant','Internal water dispenser'], '{}'),
  -- Side-by-Side
  ('GSS25GYPFS', '25.3 Cu Ft Side-by-Side - SS', NULL, 'freestanding', 'refrigerator-side-by-side', 36, 25.3, 'cu_ft', 13, false, ARRAY['External ice/water','Gallon door bins','LED lighting'], '{}'),
  -- Top Freezer
  ('GTS22KYNRFS', '21.9 Cu Ft Garage Ready Top Freezer', NULL, 'freestanding', 'refrigerator-top-freezer', 33, 21.9, 'cu_ft', 14, false, ARRAY['Garage ready','Fingerprint resistant','LED lighting'], '{}'),
  -- Dishwashers
  ('GDT550PYRFS', 'Top Control Dishwasher Dry Boost', 'electric', 'built-in', 'dishwasher', 24, NULL, NULL, 10, false, ARRAY['Dry Boost','Steam+Sani','Autosense','16 place settings','4 wash cycles'], '{"noise_dba": 52, "place_settings": 16}'),
  ('GDT670SYVFS', 'Top Control Dishwasher w/ Sanitize', 'electric', 'built-in', 'dishwasher', 24, NULL, NULL, 10, false, ARRAY['Sanitize cycle','Stainless interior','Dry Boost','Bottle jets'], '{}'),
  -- Gas Ranges
  ('JGB735SPSS', '30" Gas Convection Range Air Fry - SS', 'gas', 'freestanding', 'range-gas', 30, 5.0, 'cu_ft', 15, false, ARRAY['No preheat air fry','Convection','Integrated griddle','Self-clean+Steam','5 sealed burners'], '{"burners": 5}'),
  ('JGBS66REKSS', '30" Gas Range Standard - SS', 'gas', 'freestanding', 'range-gas', 30, 5.0, 'cu_ft', 15, false, ARRAY['Standard gas range','Sealed burners'], '{"burners": 4}'),
  ('GGF600AVSS', '30" Gas Range 600 Series - SS', 'gas', 'freestanding', 'range-gas', 30, 5.3, 'cu_ft', 15, false, ARRAY['600 series','No preheat air fry'], '{}')
) AS v(model_number, model_name, fuel, install, cat_slug, width, cap, cap_unit, lifespan, wifi, features, specs)
WHERE m.slug = 'ge-appliances' AND c.slug = v.cat_slug;

-- ======================== GE PROFILE ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, 'Profile', v.fuel, v.install, v.width, v.cap, v.cap_unit, true, v.lifespan, true, true, v.features, v.specs::jsonb, 'https://www.geappliances.com/ge-profile/'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  -- Refrigerators
  ('PVD28BYNFS', 'Profile 36" 4-Door French Door - SS', NULL, 'freestanding', 'refrigerator-4-door', 36, 27.9, 'cu_ft', 13, ARRAY['4-door french door','Hands-free autofill','TwinChill evaporators','Wi-Fi'], '{}'),
  ('PFE28KYNFS', 'Profile 36" French Door - SS', NULL, 'freestanding', 'refrigerator-french-door', 36, 27.7, 'cu_ft', 13, ARRAY['Keurig K-Cup brewing system','Hands-free autofill','TwinChill','Wi-Fi'], '{}'),
  ('PYE22KYNFS', 'Profile 36" Counter-Depth French Door - SS', NULL, 'freestanding', 'refrigerator-french-door', 36, 22.1, 'cu_ft', 13, ARRAY['Counter-depth','Hands-free autofill','TwinChill','Fingerprint resistant'], '{}'),
  -- Dishwashers
  ('PDT715SYNFS', 'Profile Top Control Smart Dishwasher', 'electric', 'built-in', 'dishwasher', 24, NULL, NULL, 10, ARRAY['UltraFresh system with Microban','Deep-clean 3rd rack','Dry Boost with Fan Assist','42 dBA','Wi-Fi'], '{"noise_dba": 42}'),
  -- Ranges
  ('PGS930YPFS', 'Profile 30" Smart Slide-In Gas Range', 'gas', 'slide-in', 'range-gas', 30, 5.6, 'cu_ft', 15, ARRAY['Air Fry','True convection','Wi-Fi','Precision cooking modes'], '{"burners": 5}'),
  ('PSE940YPFS', 'Profile 30" Smart Slide-In Electric Range', 'electric', 'slide-in', 'range-electric', 30, 5.3, 'cu_ft', 15, ARRAY['Air Fry','True convection','Wi-Fi','Precision cooking'], '{}'),
  ('PHS930YPFS', 'Profile 30" Smart Slide-In Induction Range', 'induction', 'slide-in', 'range-induction', 30, 5.3, 'cu_ft', 15, ARRAY['Induction','Air Fry','True convection','Wi-Fi','Precision cooking'], '{}'),
  -- Ice Makers
  ('?"?"', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL) -- placeholder removed
) AS v(model_number, model_name, fuel, install, cat_slug, width, cap, cap_unit, lifespan, features, specs)
WHERE m.slug = 'ge-profile' AND c.slug = v.cat_slug
AND v.model_number != '?"?"';

-- ======================== CAFÉ ========================

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, 'Café', v.fuel, v.install, v.width, v.cap, v.cap_unit, true, v.lifespan, true, true, v.features, v.specs::jsonb, 'https://www.cafeappliances.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  -- Refrigerators (Café uses C prefix)
  ('CYE22TP3MD1', 'Café 36" Counter-Depth French Door - Matte Black', NULL, 'freestanding', 'refrigerator-french-door', 36, 22.2, 'cu_ft', 13, ARRAY['Counter-depth','Customizable hardware','Matte finish','TwinChill','Hot water dispenser','Wi-Fi'], '{"finish": "matte_black", "customizable_hardware": true}'),
  ('CYE22TP4MW2', 'Café 36" Counter-Depth French Door - Matte White', NULL, 'freestanding', 'refrigerator-french-door', 36, 22.2, 'cu_ft', 13, ARRAY['Counter-depth','Customizable hardware','Matte white','Wi-Fi'], '{"finish": "matte_white", "customizable_hardware": true}'),
  ('CVE28DP3ND1', 'Café 36" Quad-Door French Door - Platinum Glass', NULL, 'freestanding', 'refrigerator-4-door', 36, 27.4, 'cu_ft', 13, ARRAY['Quad door','Customizable hardware','Platinum glass','Wi-Fi'], '{"customizable_hardware": true}'),
  -- Ranges
  ('CGS750P3MD1', 'Café 30" Smart Slide-In Gas Range - Matte Black', 'gas', 'slide-in', 'range-gas', 30, 5.6, 'cu_ft', 15, ARRAY['Customizable hardware','Matte finish','True convection','Wi-Fi','No preheat air fry'], '{"customizable_hardware": true}'),
  ('CES750P3MD1', 'Café 30" Smart Slide-In Electric Range - Matte Black', 'electric', 'slide-in', 'range-electric', 30, 5.3, 'cu_ft', 15, ARRAY['Customizable hardware','Matte finish','True convection','Wi-Fi'], '{"customizable_hardware": true}'),
  ('CHS950P3MD1', 'Café 30" Smart Slide-In Induction Range - Matte Black', 'induction', 'slide-in', 'range-induction', 30, 5.7, 'cu_ft', 15, ARRAY['Induction','Customizable hardware','Matte finish','Wi-Fi','SyncBurners'], '{"customizable_hardware": true}'),
  -- Dishwashers
  ('CDT875P3ND1', 'Café Top Control Smart Dishwasher - Platinum Glass', 'electric', 'built-in', 'dishwasher', 24, NULL, NULL, 10, ARRAY['Ultra Wash & Dual Convection Dry','44 dBA','Customizable handle','Bottle wash jets','Wi-Fi'], '{"noise_dba": 44, "customizable_hardware": true}'),
  -- Wall Ovens
  ('CTS90DP3ND1', 'Café 30" Smart Single Wall Oven - Platinum Glass', 'electric', 'built-in', 'wall-oven-single', 30, 5.0, 'cu_ft', 14, ARRAY['True European convection','Customizable hardware','Wi-Fi','No preheat air fry'], '{"customizable_hardware": true}'),
  ('CTD90DP3ND1', 'Café 30" Smart Double Wall Oven - Platinum Glass', 'electric', 'built-in', 'wall-oven-double', 30, 10.0, 'cu_ft', 14, ARRAY['True European convection','Customizable hardware','Wi-Fi','Both ovens convection'], '{"customizable_hardware": true}')
) AS v(model_number, model_name, fuel, install, cat_slug, width, cap, cap_unit, lifespan, features, specs)
WHERE m.slug = 'cafe' AND c.slug = v.cat_slug;
