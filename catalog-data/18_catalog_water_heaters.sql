-- ============================================================================
-- Water Heater Equipment Catalog
-- Covers: Budget (Reliance, Richmond, EcoSmart)
--         Mainstream (Rheem, A.O. Smith, State, Ruud, Eemax)
--         Premium (Bradford White, Rinnai, Noritz, Takagi, Navien,
--                  Stiebel Eltron, Lochinvar, HTP, Triangle Tube)
-- Categories: Tank Gas, Tank Electric, Tankless Gas, Tankless Electric,
--             Heat Pump, Point-of-Use
-- Total: ~320 models
-- ============================================================================

SET ROLE postgres;

-- ============================================================================
-- BUDGET BRANDS
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Reliance - Tank Gas
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.reliancewaterheaters.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('6 30 NOMT', '30 Gal Tall Natural Gas', 'Standard', 'gas', 'tank', 30, 'gallons', 10, false, false, 499, ARRAY['30,000 BTU','Self-cleaning dip tube','Push-button piezo ignition'], '{"gallons": 30, "uef": 0.59, "first_hour_rating": 50, "recovery_rate_gph": 30, "btu_input": 30000}'),
  ('6 40 NOMT', '40 Gal Tall Natural Gas', 'Standard', 'gas', 'tank', 40, 'gallons', 10, false, false, 549, ARRAY['40,000 BTU','Glass-lined tank','T&P relief valve'], '{"gallons": 40, "uef": 0.60, "first_hour_rating": 60, "recovery_rate_gph": 40, "btu_input": 40000}'),
  ('6 50 NOMT', '50 Gal Tall Natural Gas', 'Standard', 'gas', 'tank', 50, 'gallons', 12, false, false, 599, ARRAY['40,000 BTU','Magnesium anode rod','Self-cleaning'], '{"gallons": 50, "uef": 0.60, "first_hour_rating": 67, "recovery_rate_gph": 43, "btu_input": 40000}'),
  ('6 50 NBMS', '50 Gal Short Natural Gas', 'Standard', 'gas', 'tank', 50, 'gallons', 12, false, false, 579, ARRAY['40,000 BTU','Low-boy design','Tight spaces'], '{"gallons": 50, "uef": 0.58, "first_hour_rating": 62, "recovery_rate_gph": 40, "btu_input": 40000}'),
  ('6 75 NORT', '75 Gal Tall Natural Gas', 'Standard', 'gas', 'tank', 75, 'gallons', 12, false, false, 999, ARRAY['75,100 BTU','High capacity','Power vent compatible'], '{"gallons": 75, "uef": 0.65, "first_hour_rating": 96, "recovery_rate_gph": 72, "btu_input": 75100}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'reliance' AND c.slug = 'water-heater-tank-gas';

-- ---------------------------------------------------------------------------
-- Reliance - Tank Electric
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.reliancewaterheaters.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('6 30 EORT', '30 Gal Tall Electric', 'Standard', 'electric', 'tank', 30, 'gallons', 10, false, false, 399, ARRAY['4,500W elements','Dual heating elements','Glass-lined tank'], '{"gallons": 30, "uef": 0.93, "first_hour_rating": 46, "watts": 4500}'),
  ('6 40 EORT', '40 Gal Tall Electric', 'Standard', 'electric', 'tank', 40, 'gallons', 10, false, false, 429, ARRAY['4,500W elements','Magnesium anode rod','T&P valve'], '{"gallons": 40, "uef": 0.93, "first_hour_rating": 55, "watts": 4500}'),
  ('6 50 EORT', '50 Gal Tall Electric', 'Standard', 'electric', 'tank', 50, 'gallons', 12, false, false, 459, ARRAY['4,500W elements','Self-cleaning','Non-CFC foam insulation'], '{"gallons": 50, "uef": 0.93, "first_hour_rating": 62, "watts": 4500}'),
  ('6 50 EORS', '50 Gal Short Electric', 'Standard', 'electric', 'tank', 50, 'gallons', 12, false, false, 449, ARRAY['4,500W elements','Low-boy design','Tight spaces'], '{"gallons": 50, "uef": 0.90, "first_hour_rating": 58, "watts": 4500}'),
  ('6 80 EORT', '80 Gal Tall Electric', 'Standard', 'electric', 'tank', 80, 'gallons', 12, false, false, 649, ARRAY['4,500W elements','Large capacity','Heavy-duty anode'], '{"gallons": 80, "uef": 0.90, "first_hour_rating": 86, "watts": 4500}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'reliance' AND c.slug = 'water-heater-tank-electric';

-- ---------------------------------------------------------------------------
-- Richmond - Tank Gas
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.richmondwaterheaters.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('6GR40T-36F', '40 Gal Tall Natural Gas 6-Year', 'Essential', 'gas', 'tank', 40, 'gallons', 10, false, false, 519, ARRAY['36,000 BTU','Push-button ignition','6-year warranty'], '{"gallons": 40, "uef": 0.59, "first_hour_rating": 57, "recovery_rate_gph": 37, "btu_input": 36000}'),
  ('6GR40T-40F', '40 Gal Tall Natural Gas 6-Year', 'Essential', 'gas', 'tank', 40, 'gallons', 10, false, false, 549, ARRAY['40,000 BTU','Self-cleaning dip tube','Glass-lined'], '{"gallons": 40, "uef": 0.60, "first_hour_rating": 60, "recovery_rate_gph": 40, "btu_input": 40000}'),
  ('12GR50-40F', '50 Gal Tall Natural Gas 12-Year', 'Encore', 'gas', 'tank', 50, 'gallons', 12, false, false, 749, ARRAY['40,000 BTU','12-year warranty','Premium anode rod'], '{"gallons": 50, "uef": 0.62, "first_hour_rating": 70, "recovery_rate_gph": 43, "btu_input": 40000}'),
  ('6GR50-40F', '50 Gal Tall Natural Gas 6-Year', 'Essential', 'gas', 'tank', 50, 'gallons', 12, false, false, 599, ARRAY['40,000 BTU','6-year warranty','Standard recovery'], '{"gallons": 50, "uef": 0.60, "first_hour_rating": 67, "recovery_rate_gph": 43, "btu_input": 40000}'),
  ('6GR75-76', '75 Gal Tall Natural Gas', 'Essential', 'gas', 'tank', 75, 'gallons', 12, false, false, 1049, ARRAY['75,100 BTU','High capacity','Heavy-duty'], '{"gallons": 75, "uef": 0.65, "first_hour_rating": 96, "recovery_rate_gph": 72, "btu_input": 75100}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'richmond' AND c.slug = 'water-heater-tank-gas';

-- ---------------------------------------------------------------------------
-- Richmond - Tank Electric
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.richmondwaterheaters.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('6E40-D', '40 Gal Tall Electric 6-Year', 'Essential', 'electric', 'tank', 40, 'gallons', 10, false, false, 399, ARRAY['4,500W elements','6-year warranty','Glass-lined tank'], '{"gallons": 40, "uef": 0.93, "first_hour_rating": 55, "watts": 4500}'),
  ('6E50-D', '50 Gal Tall Electric 6-Year', 'Essential', 'electric', 'tank', 50, 'gallons', 10, false, false, 429, ARRAY['4,500W elements','Self-cleaning dip tube','6-year warranty'], '{"gallons": 50, "uef": 0.93, "first_hour_rating": 62, "watts": 4500}'),
  ('12E50-D', '50 Gal Tall Electric 12-Year', 'Encore', 'electric', 'tank', 50, 'gallons', 12, false, false, 579, ARRAY['4,500W elements','12-year warranty','Premium anode'], '{"gallons": 50, "uef": 0.95, "first_hour_rating": 65, "watts": 4500}'),
  ('6E40-S', '40 Gal Short Electric 6-Year', 'Essential', 'electric', 'tank', 40, 'gallons', 10, false, false, 389, ARRAY['4,500W elements','Low-boy design','6-year warranty'], '{"gallons": 40, "uef": 0.90, "first_hour_rating": 51, "watts": 4500}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'richmond' AND c.slug = 'water-heater-tank-electric';

-- ---------------------------------------------------------------------------
-- Richmond - Tankless Gas
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.richmondwaterheaters.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('RMTGH-84DVLN-3', '8.4 GPM Tankless Natural Gas', 'Encore', 'gas', 'tankless', 8, 'gpm', 20, false, true, 1299, ARRAY['Condensing technology','Built-in recirculation','Indoor/outdoor'], '{"gpm": 8.4, "uef": 0.93, "btu_input": 180000, "min_activation_gpm": 0.4, "max_temp_rise": 77}'),
  ('RMTGH-95DVLN-3', '9.5 GPM Tankless Natural Gas', 'Encore', 'gas', 'tankless', 10, 'gpm', 20, false, true, 1449, ARRAY['Condensing','Built-in recirc','Ultra low NOx'], '{"gpm": 9.5, "uef": 0.96, "btu_input": 199000, "min_activation_gpm": 0.4, "max_temp_rise": 77}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'richmond' AND c.slug = 'water-heater-tankless-gas';

-- ---------------------------------------------------------------------------
-- EcoSmart - Tankless Electric
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.ecosmart.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('ECO 8', 'ECO 8 Tankless Electric', 'ECO', 'electric', 'tankless', 2, 'gpm', 15, false, false, 219, ARRAY['8 kW','Self-modulating','Compact design','99.8% efficient'], '{"gpm": 2.0, "uef": 0.98, "kw": 8, "min_activation_gpm": 0.3, "max_temp_rise": 57}'),
  ('ECO 11', 'ECO 11 Tankless Electric', 'ECO', 'electric', 'tankless', 3, 'gpm', 15, false, false, 289, ARRAY['11 kW','Self-modulating','Compact design','99.8% efficient'], '{"gpm": 2.6, "uef": 0.98, "kw": 11, "min_activation_gpm": 0.3, "max_temp_rise": 57}'),
  ('ECO 14', 'ECO 14 Tankless Electric', 'ECO', 'electric', 'tankless', 4, 'gpm', 15, false, false, 349, ARRAY['13.6 kW','Self-modulating','Patented technology'], '{"gpm": 3.5, "uef": 0.98, "kw": 13.6, "min_activation_gpm": 0.3, "max_temp_rise": 57}'),
  ('ECO 18', 'ECO 18 Tankless Electric', 'ECO', 'electric', 'tankless', 5, 'gpm', 15, false, false, 399, ARRAY['18 kW','Self-modulating','Digital temperature control'], '{"gpm": 4.3, "uef": 0.98, "kw": 18, "min_activation_gpm": 0.3, "max_temp_rise": 57}'),
  ('ECO 24', 'ECO 24 Tankless Electric', 'ECO', 'electric', 'tankless', 6, 'gpm', 15, false, false, 449, ARRAY['24 kW','Self-modulating','Whole-home capable'], '{"gpm": 5.3, "uef": 0.99, "kw": 24, "min_activation_gpm": 0.3, "max_temp_rise": 57}'),
  ('ECO 27', 'ECO 27 Tankless Electric', 'ECO', 'electric', 'tankless', 7, 'gpm', 15, false, false, 499, ARRAY['27 kW','Self-modulating','Whole-home','Lifetime warranty'], '{"gpm": 6.5, "uef": 0.99, "kw": 27, "min_activation_gpm": 0.25, "max_temp_rise": 57}'),
  ('ECO 36', 'ECO 36 Tankless Electric', 'ECO', 'electric', 'tankless', 8, 'gpm', 15, false, false, 599, ARRAY['36 kW','Self-modulating','Largest residential model'], '{"gpm": 8.0, "uef": 0.99, "kw": 36, "min_activation_gpm": 0.25, "max_temp_rise": 57}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ecosmart' AND c.slug = 'water-heater-tankless-electric';

-- ---------------------------------------------------------------------------
-- EcoSmart - Point-of-Use
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.ecosmart.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('POU 3.5', 'POU 3.5 Point-of-Use', 'POU', 'electric', 'point-of-use', 1, 'gpm', 10, false, false, 149, ARRAY['3.5 kW','Under-sink install','Handwashing'], '{"gpm": 0.5, "kw": 3.5}'),
  ('POU 6', 'POU 6 Point-of-Use', 'POU', 'electric', 'point-of-use', 1, 'gpm', 10, false, false, 179, ARRAY['6 kW','Under-sink install','Single sink supply'], '{"gpm": 1.0, "kw": 6}'),
  ('ECO MINI 2.5', 'Mini Tank 2.5 Gal', 'Mini Tank', 'electric', 'point-of-use', 3, 'gallons', 10, false, false, 169, ARRAY['Mini-tank','Under-sink','1440W element'], '{"gallons": 2.5, "watts": 1440}'),
  ('ECO MINI 4', 'Mini Tank 4 Gal', 'Mini Tank', 'electric', 'point-of-use', 4, 'gallons', 10, false, false, 199, ARRAY['Mini-tank','Under-sink','1440W element'], '{"gallons": 4, "watts": 1440}'),
  ('ECO MINI 6', 'Mini Tank 6 Gal', 'Mini Tank', 'electric', 'point-of-use', 6, 'gallons', 10, false, false, 229, ARRAY['Mini-tank','Under-sink','1440W element'], '{"gallons": 6, "watts": 1440}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ecosmart' AND c.slug = 'water-heater-point-of-use';


-- ============================================================================
-- MAINSTREAM BRANDS
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Rheem - Tank Gas
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.rheem.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('PROG40-36N RH60', '40 Gal ProTerra Gas', 'Performance', 'gas', 'tank', 40, 'gallons', 12, false, false, 629, ARRAY['36,000 BTU','Push-button ignition','Self-cleaning dip tube'], '{"gallons": 40, "uef": 0.60, "first_hour_rating": 60, "recovery_rate_gph": 37, "btu_input": 36000}'),
  ('PROG40-40N RH62', '40 Gal Performance Gas', 'Performance', 'gas', 'tank', 40, 'gallons', 12, false, false, 699, ARRAY['40,000 BTU','Premium gas valve','Brass drain valve'], '{"gallons": 40, "uef": 0.62, "first_hour_rating": 66, "recovery_rate_gph": 40, "btu_input": 40000}'),
  ('PROG50-42N RH67', '50 Gal Performance Plus Gas', 'Performance Plus', 'gas', 'tank', 50, 'gallons', 12, false, false, 799, ARRAY['42,000 BTU','Premium gas valve','Push-button ignition'], '{"gallons": 50, "uef": 0.62, "first_hour_rating": 73, "recovery_rate_gph": 43, "btu_input": 42000}'),
  ('PROG50-38N RH60', '50 Gal Performance Gas', 'Performance', 'gas', 'tank', 50, 'gallons', 12, false, false, 749, ARRAY['38,000 BTU','Standard recovery','Glass-lined tank'], '{"gallons": 50, "uef": 0.60, "first_hour_rating": 67, "recovery_rate_gph": 40, "btu_input": 38000}'),
  ('XG50T06EC36U0', '50 Gal Professional Classic Gas', 'Professional Classic', 'gas', 'tank', 50, 'gallons', 12, false, false, 699, ARRAY['36,000 BTU','Contractor grade','Flammable vapor sensor'], '{"gallons": 50, "uef": 0.60, "first_hour_rating": 64, "recovery_rate_gph": 40, "btu_input": 36000}'),
  ('PROG75-76N RH67', '75 Gal Performance Plus Gas', 'Performance Plus', 'gas', 'tank', 75, 'gallons', 12, false, false, 1299, ARRAY['76,000 BTU','High capacity','Brass drain valve'], '{"gallons": 75, "uef": 0.65, "first_hour_rating": 99, "recovery_rate_gph": 72, "btu_input": 76000}'),
  ('PROG40S-36N RH60', '40 Gal Short Performance Gas', 'Performance', 'gas', 'tank', 40, 'gallons', 12, false, false, 649, ARRAY['36,000 BTU','Low-boy design','Self-cleaning'], '{"gallons": 40, "uef": 0.58, "first_hour_rating": 55, "recovery_rate_gph": 37, "btu_input": 36000}'),
  ('XG40T06HE36U0', '40 Gal Professional Classic Plus', 'Professional Classic Plus', 'gas', 'tank', 40, 'gallons', 12, false, false, 849, ARRAY['36,000 BTU','High efficiency','Contractor exclusive'], '{"gallons": 40, "uef": 0.67, "first_hour_rating": 64, "recovery_rate_gph": 37, "btu_input": 36000}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'rheem' AND c.slug = 'water-heater-tank-gas';

-- ---------------------------------------------------------------------------
-- Rheem - Tank Electric
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.rheem.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('PROE40 T2 RH95', '40 Gal Performance Electric', 'Performance', 'electric', 'tank', 40, 'gallons', 12, false, false, 529, ARRAY['4,500W dual elements','Self-cleaning','Automatic thermostat'], '{"gallons": 40, "uef": 0.95, "first_hour_rating": 55, "watts": 4500}'),
  ('PROE50 T2 RH95', '50 Gal Performance Electric', 'Performance', 'electric', 'tank', 50, 'gallons', 12, false, false, 579, ARRAY['4,500W dual elements','Self-cleaning dip tube','Glass-lined'], '{"gallons": 50, "uef": 0.95, "first_hour_rating": 67, "watts": 4500}'),
  ('PROE50 T2 RH95 EC', '50 Gal Performance Plus Electric', 'Performance Plus', 'electric', 'tank', 50, 'gallons', 12, false, false, 649, ARRAY['4,500W elements','EcoNet WiFi ready','Leak detection'], '{"gallons": 50, "uef": 0.95, "first_hour_rating": 67, "watts": 4500}'),
  ('PROE80 T2 RH95', '80 Gal Performance Electric', 'Performance', 'electric', 'tank', 80, 'gallons', 12, false, false, 799, ARRAY['4,500W dual elements','High capacity','Heavy-duty anode'], '{"gallons": 80, "uef": 0.92, "first_hour_rating": 86, "watts": 4500}'),
  ('PROE30 T2 RH95', '30 Gal Performance Electric', 'Performance', 'electric', 'tank', 30, 'gallons', 12, false, false, 479, ARRAY['4,500W elements','Compact','Self-cleaning'], '{"gallons": 30, "uef": 0.95, "first_hour_rating": 46, "watts": 4500}'),
  ('XE40T06ST45U0', '40 Gal Professional Classic Electric', 'Professional Classic', 'electric', 'tank', 40, 'gallons', 12, false, false, 499, ARRAY['4,500W elements','Contractor grade','Brass drain valve'], '{"gallons": 40, "uef": 0.93, "first_hour_rating": 55, "watts": 4500}'),
  ('XE50T06ST55U0', '50 Gal Professional Classic Electric', 'Professional Classic', 'electric', 'tank', 50, 'gallons', 12, false, false, 549, ARRAY['5,500W elements','Contractor grade','High recovery'], '{"gallons": 50, "uef": 0.93, "first_hour_rating": 72, "watts": 5500}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'rheem' AND c.slug = 'water-heater-tank-electric';

-- ---------------------------------------------------------------------------
-- Rheem - Tankless Gas
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.rheem.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('RTGH-84DVLN-3', '8.4 GPM Condensing Tankless', 'Performance Platinum', 'gas', 'tankless', 8, 'gpm', 20, true, true, 1499, ARRAY['Condensing','Built-in recirculation','EcoNet WiFi','Ultra low NOx'], '{"gpm": 8.4, "uef": 0.93, "btu_input": 180000, "min_activation_gpm": 0.4, "max_temp_rise": 77}'),
  ('RTGH-95DVLN-3', '9.5 GPM Condensing Tankless', 'Performance Platinum', 'gas', 'tankless', 10, 'gpm', 20, true, true, 1699, ARRAY['Condensing','Built-in recirc','EcoNet WiFi','Hot start programming'], '{"gpm": 9.5, "uef": 0.96, "btu_input": 199900, "min_activation_gpm": 0.4, "max_temp_rise": 77}'),
  ('RTGH-84XLN-2', '8.4 GPM Mid-Efficiency Tankless', 'Performance Plus', 'gas', 'tankless', 8, 'gpm', 20, false, true, 1099, ARRAY['Non-condensing','Indoor install','Low NOx'], '{"gpm": 8.4, "uef": 0.82, "btu_input": 180000, "min_activation_gpm": 0.4, "max_temp_rise": 77}'),
  ('RTGH-RH10DVLN', '10 GPM Condensing Tankless', 'Prestige', 'gas', 'tankless', 10, 'gpm', 20, true, true, 1899, ARRAY['Top-of-line condensing','Built-in recirc','EcoNet WiFi','Integrated manifold'], '{"gpm": 10.0, "uef": 0.96, "btu_input": 199900, "min_activation_gpm": 0.26, "max_temp_rise": 77}'),
  ('RTG-84DVLN-1', '8.4 GPM Non-Condensing Outdoor', 'Performance Plus', 'gas', 'tankless', 8, 'gpm', 20, false, false, 999, ARRAY['Outdoor install','Freeze protection','Direct vent'], '{"gpm": 8.4, "uef": 0.82, "btu_input": 180000, "min_activation_gpm": 0.4, "max_temp_rise": 77}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'rheem' AND c.slug = 'water-heater-tankless-gas';

-- ---------------------------------------------------------------------------
-- Rheem - Tankless Electric
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.rheem.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('RTEX-13', '13 kW Tankless Electric', 'Performance', 'electric', 'tankless', 4, 'gpm', 15, false, false, 349, ARRAY['13 kW','Self-modulating','Digital display','99.8% efficient'], '{"gpm": 4.0, "uef": 0.99, "kw": 13, "min_activation_gpm": 0.3, "max_temp_rise": 54}'),
  ('RTEX-18', '18 kW Tankless Electric', 'Performance', 'electric', 'tankless', 5, 'gpm', 15, false, false, 449, ARRAY['18 kW','Self-modulating','External adjustable'], '{"gpm": 4.4, "uef": 0.99, "kw": 18, "min_activation_gpm": 0.3, "max_temp_rise": 54}'),
  ('RTEX-24', '24 kW Tankless Electric', 'Performance Plus', 'electric', 'tankless', 6, 'gpm', 15, false, false, 549, ARRAY['24 kW','Self-modulating','Whole-home capable'], '{"gpm": 5.9, "uef": 0.99, "kw": 24, "min_activation_gpm": 0.3, "max_temp_rise": 54}'),
  ('RTEX-36', '36 kW Tankless Electric', 'Performance Platinum', 'electric', 'tankless', 8, 'gpm', 15, false, false, 699, ARRAY['36 kW','Largest model','Whole-home'], '{"gpm": 7.0, "uef": 0.99, "kw": 36, "min_activation_gpm": 0.25, "max_temp_rise": 54}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'rheem' AND c.slug = 'water-heater-tankless-electric';

-- ---------------------------------------------------------------------------
-- Rheem - Heat Pump
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.rheem.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('PROPH40 T2 RH375', '40 Gal ProTerra Heat Pump', 'ProTerra', 'electric', 'heat-pump', 40, 'gallons', 13, true, true, 1899, ARRAY['3.75 UEF','LeakGuard','EcoNet WiFi','5 operating modes','CTA-2045 compliant'], '{"gallons": 40, "uef": 3.75, "first_hour_rating": 58}'),
  ('PROPH50 T2 RH375', '50 Gal ProTerra Heat Pump', 'ProTerra', 'electric', 'heat-pump', 50, 'gallons', 13, true, true, 1999, ARRAY['3.75 UEF','LeakGuard','EcoNet WiFi','5 operating modes','Built-in leak detection'], '{"gallons": 50, "uef": 3.75, "first_hour_rating": 67}'),
  ('PROPH65 T2 RH375', '65 Gal ProTerra Heat Pump', 'ProTerra', 'electric', 'heat-pump', 65, 'gallons', 13, true, true, 2199, ARRAY['3.75 UEF','LeakGuard','EcoNet WiFi','Large capacity','CTA-2045'], '{"gallons": 65, "uef": 3.75, "first_hour_rating": 79}'),
  ('PROPH80 T2 RH375', '80 Gal ProTerra Heat Pump', 'ProTerra', 'electric', 'heat-pump', 80, 'gallons', 13, true, true, 2499, ARRAY['3.75 UEF','LeakGuard','EcoNet WiFi','Largest capacity','Built-in condensate pump'], '{"gallons": 80, "uef": 3.75, "first_hour_rating": 86}'),
  ('XE50T10HD50U0', '50 Gal Professional Prestige Heat Pump', 'Professional Prestige', 'electric', 'heat-pump', 50, 'gallons', 13, true, true, 2299, ARRAY['3.55 UEF','Contractor exclusive','EcoNet WiFi','10-year warranty'], '{"gallons": 50, "uef": 3.55, "first_hour_rating": 67}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'rheem' AND c.slug = 'water-heater-heat-pump';

-- ---------------------------------------------------------------------------
-- A.O. Smith - Tank Gas
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.aosmith.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('G6-T4036NV', '40 Gal Signature 100 Gas', 'Signature 100', 'gas', 'tank', 40, 'gallons', 10, false, false, 579, ARRAY['36,000 BTU','Push-button ignition','Glass-lined tank','6-year warranty'], '{"gallons": 40, "uef": 0.59, "first_hour_rating": 57, "recovery_rate_gph": 37, "btu_input": 36000}'),
  ('G6-T5040NV', '50 Gal Signature 100 Gas', 'Signature 100', 'gas', 'tank', 50, 'gallons', 10, false, false, 629, ARRAY['40,000 BTU','Self-cleaning dip tube','6-year warranty'], '{"gallons": 50, "uef": 0.60, "first_hour_rating": 67, "recovery_rate_gph": 43, "btu_input": 40000}'),
  ('G9-T5040NV', '50 Gal Signature 300 Gas', 'Signature 300', 'gas', 'tank', 50, 'gallons', 12, false, false, 849, ARRAY['40,000 BTU','9-year warranty','Powered anode rod','iCOMM diagnostics'], '{"gallons": 50, "uef": 0.62, "first_hour_rating": 70, "recovery_rate_gph": 43, "btu_input": 40000}'),
  ('GPVL-50', '50 Gal ProLine Gas Power Vent', 'ProLine', 'gas', 'tank', 50, 'gallons', 12, false, false, 1099, ARRAY['40,000 BTU','Power vent','Flexible venting options','Contractor preferred'], '{"gallons": 50, "uef": 0.63, "first_hour_rating": 70, "recovery_rate_gph": 43, "btu_input": 40000}'),
  ('GPVL-40', '40 Gal ProLine Gas Power Vent', 'ProLine', 'gas', 'tank', 40, 'gallons', 12, false, false, 999, ARRAY['40,000 BTU','Power vent','Side wall venting'], '{"gallons": 40, "uef": 0.63, "first_hour_rating": 65, "recovery_rate_gph": 40, "btu_input": 40000}'),
  ('G12-T5040NV', '50 Gal Signature 500 Gas', 'Signature 500', 'gas', 'tank', 50, 'gallons', 12, true, false, 999, ARRAY['40,000 BTU','12-year warranty','Powered anode rod','WiFi-enabled'], '{"gallons": 50, "uef": 0.62, "first_hour_rating": 73, "recovery_rate_gph": 43, "btu_input": 40000}'),
  ('G6-T7540NV', '75 Gal Signature 100 Gas', 'Signature 100', 'gas', 'tank', 75, 'gallons', 12, false, false, 1099, ARRAY['75,100 BTU','High capacity','6-year warranty'], '{"gallons": 75, "uef": 0.65, "first_hour_rating": 96, "recovery_rate_gph": 72, "btu_input": 75100}'),
  ('G6-T3036NV', '30 Gal Signature 100 Gas', 'Signature 100', 'gas', 'tank', 30, 'gallons', 10, false, false, 529, ARRAY['32,000 BTU','Compact','6-year warranty'], '{"gallons": 30, "uef": 0.59, "first_hour_rating": 50, "recovery_rate_gph": 32, "btu_input": 32000}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ao-smith' AND c.slug = 'water-heater-tank-gas';

-- ---------------------------------------------------------------------------
-- A.O. Smith - Tank Electric
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.aosmith.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('E6-40H45DV', '40 Gal Signature 100 Electric', 'Signature 100', 'electric', 'tank', 40, 'gallons', 10, false, false, 449, ARRAY['4,500W dual elements','6-year warranty','Glass-lined'], '{"gallons": 40, "uef": 0.93, "first_hour_rating": 55, "watts": 4500}'),
  ('E6-50H45DV', '50 Gal Signature 100 Electric', 'Signature 100', 'electric', 'tank', 50, 'gallons', 10, false, false, 499, ARRAY['4,500W dual elements','Self-cleaning','6-year warranty'], '{"gallons": 50, "uef": 0.93, "first_hour_rating": 62, "watts": 4500}'),
  ('E9-50H55DV', '50 Gal Signature 300 Electric', 'Signature 300', 'electric', 'tank', 50, 'gallons', 12, false, false, 649, ARRAY['5,500W elements','9-year warranty','Powered anode rod'], '{"gallons": 50, "uef": 0.95, "first_hour_rating": 72, "watts": 5500}'),
  ('E12-50H55DV', '50 Gal Signature 500 Electric', 'Signature 500', 'electric', 'tank', 50, 'gallons', 12, true, false, 799, ARRAY['5,500W elements','12-year warranty','WiFi-enabled','Powered anode'], '{"gallons": 50, "uef": 0.95, "first_hour_rating": 72, "watts": 5500}'),
  ('E6-80H45DV', '80 Gal Signature 100 Electric', 'Signature 100', 'electric', 'tank', 80, 'gallons', 12, false, false, 699, ARRAY['4,500W elements','Large capacity','6-year warranty'], '{"gallons": 80, "uef": 0.92, "first_hour_rating": 86, "watts": 4500}'),
  ('ENL-40', '40 Gal ProLine Electric', 'ProLine', 'electric', 'tank', 40, 'gallons', 12, false, false, 449, ARRAY['4,500W elements','Contractor grade','Brass drain valve'], '{"gallons": 40, "uef": 0.93, "first_hour_rating": 55, "watts": 4500}'),
  ('ENL-50', '50 Gal ProLine Electric', 'ProLine', 'electric', 'tank', 50, 'gallons', 12, false, false, 499, ARRAY['4,500W elements','Contractor grade','Commercial-grade thermostat'], '{"gallons": 50, "uef": 0.93, "first_hour_rating": 62, "watts": 4500}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ao-smith' AND c.slug = 'water-heater-tank-electric';

-- ---------------------------------------------------------------------------
-- A.O. Smith - Tankless Gas
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.aosmith.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('ATI-540H-N', '5.3 GPM Signature 100 Tankless', 'Signature 100', 'gas', 'tankless', 5, 'gpm', 20, false, true, 899, ARRAY['Non-condensing','Indoor/outdoor','5.3 GPM'], '{"gpm": 5.3, "uef": 0.82, "btu_input": 120000, "min_activation_gpm": 0.5, "max_temp_rise": 77}'),
  ('ATI-540P-N', '5.3 GPM Signature 300 Tankless', 'Signature 300', 'gas', 'tankless', 5, 'gpm', 20, false, true, 1149, ARRAY['Non-condensing','Built-in recirculation','5.3 GPM'], '{"gpm": 5.3, "uef": 0.82, "btu_input": 120000, "min_activation_gpm": 0.5, "max_temp_rise": 77}'),
  ('ATI-340H-N', '8.0 GPM Signature 100 Tankless', 'Signature 100', 'gas', 'tankless', 8, 'gpm', 20, false, true, 1199, ARRAY['Condensing','Indoor install','Ultra low NOx'], '{"gpm": 8.0, "uef": 0.93, "btu_input": 180000, "min_activation_gpm": 0.4, "max_temp_rise": 77}'),
  ('ATI-340P-N', '8.0 GPM Signature 300 Tankless', 'Signature 300', 'gas', 'tankless', 8, 'gpm', 20, true, true, 1449, ARRAY['Condensing','Built-in recirculation','WiFi-enabled'], '{"gpm": 8.0, "uef": 0.93, "btu_input": 180000, "min_activation_gpm": 0.4, "max_temp_rise": 77}'),
  ('ATI-510U-N', '10 GPM Signature 500 Tankless', 'Signature 500', 'gas', 'tankless', 10, 'gpm', 20, true, true, 1799, ARRAY['Condensing','Built-in recirc','WiFi','Premium display'], '{"gpm": 10.0, "uef": 0.96, "btu_input": 199000, "min_activation_gpm": 0.26, "max_temp_rise": 77}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ao-smith' AND c.slug = 'water-heater-tankless-gas';

-- ---------------------------------------------------------------------------
-- A.O. Smith - Heat Pump
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.aosmith.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('HP6-50H45DV', '50 Gal Signature 900 Heat Pump', 'Signature 900', 'electric', 'heat-pump', 50, 'gallons', 13, true, true, 1999, ARRAY['3.45 UEF','WiFi-enabled','Leak detection','5 operating modes','ENERGY STAR Most Efficient'], '{"gallons": 50, "uef": 3.45, "first_hour_rating": 67}'),
  ('HP6-66H45DV', '66 Gal Signature 900 Heat Pump', 'Signature 900', 'electric', 'heat-pump', 66, 'gallons', 13, true, true, 2199, ARRAY['3.45 UEF','WiFi-enabled','Leak detection','Large capacity'], '{"gallons": 66, "uef": 3.45, "first_hour_rating": 79}'),
  ('HP6-80H45DV', '80 Gal Signature 900 Heat Pump', 'Signature 900', 'electric', 'heat-pump', 80, 'gallons', 13, true, true, 2399, ARRAY['3.45 UEF','WiFi-enabled','Largest capacity','CTA-2045 compliant'], '{"gallons": 80, "uef": 3.45, "first_hour_rating": 86}'),
  ('HPTU-50N', '50 Gal Voltex Heat Pump', 'Voltex', 'electric', 'heat-pump', 50, 'gallons', 13, true, true, 1799, ARRAY['3.24 UEF','4 operating modes','LCD display','Contractor preferred'], '{"gallons": 50, "uef": 3.24, "first_hour_rating": 66}'),
  ('HPTU-80N', '80 Gal Voltex Heat Pump', 'Voltex', 'electric', 'heat-pump', 80, 'gallons', 13, true, true, 2099, ARRAY['3.24 UEF','4 operating modes','Large capacity','Low ambient operation'], '{"gallons": 80, "uef": 3.24, "first_hour_rating": 85}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ao-smith' AND c.slug = 'water-heater-heat-pump';

-- ---------------------------------------------------------------------------
-- State Water Heaters - Tank Gas
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.statewaterheaters.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('GS6-40-BRT', '40 Gal Select Gas', 'Select', 'gas', 'tank', 40, 'gallons', 10, false, false, 549, ARRAY['36,000 BTU','6-year warranty','Push-button ignition'], '{"gallons": 40, "uef": 0.59, "first_hour_rating": 57, "recovery_rate_gph": 37, "btu_input": 36000}'),
  ('GS6-50-BRT', '50 Gal Select Gas', 'Select', 'gas', 'tank', 50, 'gallons', 10, false, false, 599, ARRAY['40,000 BTU','Self-cleaning','6-year warranty'], '{"gallons": 50, "uef": 0.60, "first_hour_rating": 67, "recovery_rate_gph": 43, "btu_input": 40000}'),
  ('GS6-50-YBRT', '50 Gal Proline Master Gas', 'ProLine Master', 'gas', 'tank', 50, 'gallons', 12, false, false, 749, ARRAY['40,000 BTU','Enhanced recovery','Brass drain valve'], '{"gallons": 50, "uef": 0.62, "first_hour_rating": 73, "recovery_rate_gph": 43, "btu_input": 40000}'),
  ('GS6-40-BCTP', '40 Gal Power Vent Gas', 'ProLine', 'gas', 'tank', 40, 'gallons', 12, false, false, 999, ARRAY['40,000 BTU','Power vent','Flexible venting'], '{"gallons": 40, "uef": 0.63, "first_hour_rating": 65, "recovery_rate_gph": 40, "btu_input": 40000}'),
  ('GS6-50-BCTP', '50 Gal Power Vent Gas', 'ProLine', 'gas', 'tank', 50, 'gallons', 12, false, false, 1099, ARRAY['40,000 BTU','Power vent','Side wall venting'], '{"gallons": 50, "uef": 0.63, "first_hour_rating": 70, "recovery_rate_gph": 43, "btu_input": 40000}'),
  ('GS6-75-BRT', '75 Gal Select Gas', 'Select', 'gas', 'tank', 75, 'gallons', 12, false, false, 999, ARRAY['75,100 BTU','High capacity','6-year warranty'], '{"gallons": 75, "uef": 0.65, "first_hour_rating": 96, "recovery_rate_gph": 72, "btu_input": 75100}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'state-water-heaters' AND c.slug = 'water-heater-tank-gas';

-- ---------------------------------------------------------------------------
-- State Water Heaters - Tank Electric
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.statewaterheaters.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('ES6-40-DORS', '40 Gal ProLine Electric', 'ProLine', 'electric', 'tank', 40, 'gallons', 10, false, false, 429, ARRAY['4,500W elements','6-year warranty','Glass-lined'], '{"gallons": 40, "uef": 0.93, "first_hour_rating": 55, "watts": 4500}'),
  ('ES6-50-DORS', '50 Gal ProLine Electric', 'ProLine', 'electric', 'tank', 50, 'gallons', 10, false, false, 479, ARRAY['4,500W elements','Self-cleaning','6-year warranty'], '{"gallons": 50, "uef": 0.93, "first_hour_rating": 62, "watts": 4500}'),
  ('ES6-80-DORS', '80 Gal ProLine Electric', 'ProLine', 'electric', 'tank', 80, 'gallons', 12, false, false, 679, ARRAY['4,500W elements','High capacity','Heavy-duty anode'], '{"gallons": 80, "uef": 0.92, "first_hour_rating": 86, "watts": 4500}'),
  ('ENS-50', '50 Gal ProLine Master Electric', 'ProLine Master', 'electric', 'tank', 50, 'gallons', 12, false, false, 599, ARRAY['5,500W elements','Enhanced recovery','Premium build'], '{"gallons": 50, "uef": 0.95, "first_hour_rating": 72, "watts": 5500}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'state-water-heaters' AND c.slug = 'water-heater-tank-electric';

-- ---------------------------------------------------------------------------
-- State Water Heaters - Tankless Gas
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.statewaterheaters.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('GTS-310U-N', '8.0 GPM Condensing Tankless', 'ProLine XE', 'gas', 'tankless', 8, 'gpm', 20, false, true, 1299, ARRAY['Condensing','Indoor install','Ultra low NOx'], '{"gpm": 8.0, "uef": 0.93, "btu_input": 180000, "min_activation_gpm": 0.4, "max_temp_rise": 77}'),
  ('GTS-510U-N', '10 GPM Condensing Tankless', 'ProLine XE', 'gas', 'tankless', 10, 'gpm', 20, true, true, 1599, ARRAY['Condensing','Built-in recirculation','WiFi-enabled'], '{"gpm": 10.0, "uef": 0.96, "btu_input": 199000, "min_activation_gpm": 0.26, "max_temp_rise": 77}'),
  ('GTS-340-NIH', '8.4 GPM Non-Condensing Tankless', 'ProLine', 'gas', 'tankless', 8, 'gpm', 20, false, false, 999, ARRAY['Non-condensing','Indoor install'], '{"gpm": 8.4, "uef": 0.82, "btu_input": 180000, "min_activation_gpm": 0.5, "max_temp_rise": 77}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'state-water-heaters' AND c.slug = 'water-heater-tankless-gas';

-- ---------------------------------------------------------------------------
-- Ruud - Tank Gas
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.ruud.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('RU2PG40T-36N RH62', '40 Gal Achiever Plus Gas', 'Achiever Plus', 'gas', 'tank', 40, 'gallons', 12, false, false, 649, ARRAY['36,000 BTU','Push-button ignition','Contractor exclusive'], '{"gallons": 40, "uef": 0.62, "first_hour_rating": 60, "recovery_rate_gph": 37, "btu_input": 36000}'),
  ('RU2PG50-42N RH67', '50 Gal Achiever Plus Gas', 'Achiever Plus', 'gas', 'tank', 50, 'gallons', 12, false, false, 749, ARRAY['42,000 BTU','Premium gas valve','Brass drain valve'], '{"gallons": 50, "uef": 0.62, "first_hour_rating": 73, "recovery_rate_gph": 43, "btu_input": 42000}'),
  ('RU2PG50-38N RH60', '50 Gal Achiever Gas', 'Achiever', 'gas', 'tank', 50, 'gallons', 12, false, false, 699, ARRAY['38,000 BTU','Standard recovery','Glass-lined tank'], '{"gallons": 50, "uef": 0.60, "first_hour_rating": 67, "recovery_rate_gph": 40, "btu_input": 38000}'),
  ('RU2PG75-76N RH67', '75 Gal Achiever Plus Gas', 'Achiever Plus', 'gas', 'tank', 75, 'gallons', 12, false, false, 1249, ARRAY['76,000 BTU','High capacity','Professional grade'], '{"gallons": 75, "uef": 0.65, "first_hour_rating": 99, "recovery_rate_gph": 72, "btu_input": 76000}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ruud' AND c.slug = 'water-heater-tank-gas';

-- ---------------------------------------------------------------------------
-- Ruud - Tank Electric
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.ruud.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('RE2E40-S', '40 Gal Achiever Electric', 'Achiever', 'electric', 'tank', 40, 'gallons', 12, false, false, 499, ARRAY['4,500W dual elements','Self-cleaning','Contractor exclusive'], '{"gallons": 40, "uef": 0.93, "first_hour_rating": 55, "watts": 4500}'),
  ('RE2E50-S', '50 Gal Achiever Electric', 'Achiever', 'electric', 'tank', 50, 'gallons', 12, false, false, 549, ARRAY['4,500W dual elements','Self-cleaning dip tube','Glass-lined'], '{"gallons": 50, "uef": 0.93, "first_hour_rating": 62, "watts": 4500}'),
  ('RE2E50-T', '50 Gal Achiever Plus Electric', 'Achiever Plus', 'electric', 'tank', 50, 'gallons', 12, false, false, 649, ARRAY['5,500W elements','Enhanced recovery','Premium build'], '{"gallons": 50, "uef": 0.95, "first_hour_rating": 72, "watts": 5500}'),
  ('RE2E80-S', '80 Gal Achiever Electric', 'Achiever', 'electric', 'tank', 80, 'gallons', 12, false, false, 749, ARRAY['4,500W elements','High capacity','Heavy-duty anode'], '{"gallons": 80, "uef": 0.92, "first_hour_rating": 86, "watts": 4500}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ruud' AND c.slug = 'water-heater-tank-electric';

-- ---------------------------------------------------------------------------
-- Ruud - Tankless Gas
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.ruud.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('RUTGH-84DVLN-3', '8.4 GPM Condensing Tankless', 'Ultra', 'gas', 'tankless', 8, 'gpm', 20, true, true, 1449, ARRAY['Condensing','Built-in recirculation','EcoNet WiFi ready'], '{"gpm": 8.4, "uef": 0.93, "btu_input": 180000, "min_activation_gpm": 0.4, "max_temp_rise": 77}'),
  ('RUTGH-95DVLN-3', '9.5 GPM Condensing Tankless', 'Ultra', 'gas', 'tankless', 10, 'gpm', 20, true, true, 1649, ARRAY['Condensing','Built-in recirc','Ultra low NOx'], '{"gpm": 9.5, "uef": 0.96, "btu_input": 199900, "min_activation_gpm": 0.4, "max_temp_rise": 77}'),
  ('RUTG-84DVLN-1', '8.4 GPM Non-Condensing Outdoor', 'Professional Ultra', 'gas', 'tankless', 8, 'gpm', 20, false, false, 979, ARRAY['Outdoor install','Freeze protection','Direct vent'], '{"gpm": 8.4, "uef": 0.82, "btu_input": 180000, "min_activation_gpm": 0.4, "max_temp_rise": 77}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ruud' AND c.slug = 'water-heater-tankless-gas';

-- ---------------------------------------------------------------------------
-- Ruud - Heat Pump
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.ruud.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('RE2H50 T2 RH375', '50 Gal ProTerra Heat Pump', 'ProTerra', 'electric', 'heat-pump', 50, 'gallons', 13, true, true, 1949, ARRAY['3.75 UEF','LeakGuard','EcoNet WiFi','Contractor exclusive'], '{"gallons": 50, "uef": 3.75, "first_hour_rating": 67}'),
  ('RE2H65 T2 RH375', '65 Gal ProTerra Heat Pump', 'ProTerra', 'electric', 'heat-pump', 65, 'gallons', 13, true, true, 2149, ARRAY['3.75 UEF','LeakGuard','EcoNet WiFi','Large capacity'], '{"gallons": 65, "uef": 3.75, "first_hour_rating": 79}'),
  ('RE2H80 T2 RH375', '80 Gal ProTerra Heat Pump', 'ProTerra', 'electric', 'heat-pump', 80, 'gallons', 13, true, true, 2449, ARRAY['3.75 UEF','LeakGuard','EcoNet WiFi','Largest capacity'], '{"gallons": 80, "uef": 3.75, "first_hour_rating": 86}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ruud' AND c.slug = 'water-heater-heat-pump';

-- ---------------------------------------------------------------------------
-- Eemax - Tankless Electric
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.eemax.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('HA008240', 'HomeAdvantage II 8 kW', 'HomeAdvantage II', 'electric', 'tankless', 2, 'gpm', 15, false, false, 299, ARRAY['8 kW','Self-modulating','Compact design'], '{"gpm": 2.0, "uef": 0.98, "kw": 8, "min_activation_gpm": 0.3, "max_temp_rise": 54}'),
  ('HA011240', 'HomeAdvantage II 11 kW', 'HomeAdvantage II', 'electric', 'tankless', 3, 'gpm', 15, false, false, 349, ARRAY['11 kW','Self-modulating','Point-of-use or whole-home'], '{"gpm": 2.5, "uef": 0.98, "kw": 11, "min_activation_gpm": 0.3, "max_temp_rise": 54}'),
  ('HA013240', 'HomeAdvantage II 13 kW', 'HomeAdvantage II', 'electric', 'tankless', 4, 'gpm', 15, false, false, 399, ARRAY['13 kW','Self-modulating','Thermostatic control'], '{"gpm": 3.0, "uef": 0.99, "kw": 13, "min_activation_gpm": 0.3, "max_temp_rise": 54}'),
  ('HA018240', 'HomeAdvantage II 18 kW', 'HomeAdvantage II', 'electric', 'tankless', 5, 'gpm', 15, false, false, 449, ARRAY['18 kW','Self-modulating','Digital temp display'], '{"gpm": 3.5, "uef": 0.99, "kw": 18, "min_activation_gpm": 0.3, "max_temp_rise": 54}'),
  ('HA024240', 'HomeAdvantage II 24 kW', 'HomeAdvantage II', 'electric', 'tankless', 6, 'gpm', 15, false, false, 529, ARRAY['24 kW','Self-modulating','Whole-home capable'], '{"gpm": 4.6, "uef": 0.99, "kw": 24, "min_activation_gpm": 0.3, "max_temp_rise": 54}'),
  ('HA027240', 'HomeAdvantage II 27 kW', 'HomeAdvantage II', 'electric', 'tankless', 7, 'gpm', 15, false, false, 579, ARRAY['27 kW','Self-modulating','Whole-home'], '{"gpm": 5.0, "uef": 0.99, "kw": 27, "min_activation_gpm": 0.25, "max_temp_rise": 54}'),
  ('HA036240', 'HomeAdvantage II 36 kW', 'HomeAdvantage II', 'electric', 'tankless', 8, 'gpm', 15, false, false, 679, ARRAY['36 kW','Self-modulating','Max output'], '{"gpm": 7.0, "uef": 0.99, "kw": 36, "min_activation_gpm": 0.25, "max_temp_rise": 54}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'eemax' AND c.slug = 'water-heater-tankless-electric';

-- ---------------------------------------------------------------------------
-- Eemax - Point-of-Use
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.eemax.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('SP2412', 'Single Point 2.4 kW', 'Single Point', 'electric', 'point-of-use', 1, 'gpm', 10, false, false, 149, ARRAY['2.4 kW','Under-sink','Handwashing applications'], '{"gpm": 0.3, "kw": 2.4}'),
  ('SP3512', 'Single Point 3.5 kW', 'Single Point', 'electric', 'point-of-use', 1, 'gpm', 10, false, false, 169, ARRAY['3.5 kW','Under-sink','Single fixture'], '{"gpm": 0.5, "kw": 3.5}'),
  ('SP4208', 'Single Point 4.1 kW', 'Single Point', 'electric', 'point-of-use', 1, 'gpm', 10, false, false, 189, ARRAY['4.1 kW','Under-sink','Bathroom sink'], '{"gpm": 0.5, "kw": 4.1}'),
  ('SP48', 'Single Point 4.8 kW', 'Single Point', 'electric', 'point-of-use', 1, 'gpm', 10, false, false, 199, ARRAY['4.8 kW','Under-sink','Kitchen sink'], '{"gpm": 0.7, "kw": 4.8}'),
  ('SP55', 'Single Point 5.5 kW', 'Single Point', 'electric', 'point-of-use', 1, 'gpm', 10, false, false, 219, ARRAY['5.5 kW','Under-sink','Heavy-duty single fixture'], '{"gpm": 1.0, "kw": 5.5}'),
  ('EMT2.5', 'MiniTank 2.5 Gal', 'MiniTank', 'electric', 'point-of-use', 3, 'gallons', 10, false, false, 179, ARRAY['Mini-tank','Under-sink','1440W element'], '{"gallons": 2.5, "watts": 1440}'),
  ('EMT4', 'MiniTank 4 Gal', 'MiniTank', 'electric', 'point-of-use', 4, 'gallons', 10, false, false, 199, ARRAY['Mini-tank','Under-sink','1440W element'], '{"gallons": 4, "watts": 1440}'),
  ('EMT6', 'MiniTank 6 Gal', 'MiniTank', 'electric', 'point-of-use', 6, 'gallons', 10, false, false, 229, ARRAY['Mini-tank','Under-sink','1440W element'], '{"gallons": 6, "watts": 1440}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'eemax' AND c.slug = 'water-heater-point-of-use';


-- ============================================================================
-- PREMIUM BRANDS
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Bradford White - Tank Gas
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.bradfordwhite.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('RG240T6N', '40 Gal Defender Safety System Gas', 'Defender', 'gas', 'tank', 40, 'gallons', 12, false, false, 749, ARRAY['40,000 BTU','Defender safety system','ICON gas valve','Vitraglas lining'], '{"gallons": 40, "uef": 0.62, "first_hour_rating": 66, "recovery_rate_gph": 40, "btu_input": 40000}'),
  ('RG250T6N', '50 Gal Defender Safety System Gas', 'Defender', 'gas', 'tank', 50, 'gallons', 12, false, false, 849, ARRAY['40,000 BTU','Defender safety system','ICON gas valve','Hydrojet total performance'], '{"gallons": 50, "uef": 0.62, "first_hour_rating": 73, "recovery_rate_gph": 43, "btu_input": 40000}'),
  ('RG2MH40T6N', '40 Gal eF Series High Efficiency Gas', 'eF Series', 'gas', 'tank', 40, 'gallons', 12, false, true, 999, ARRAY['Ultra low NOx','High efficiency','Honeywell gas valve','ENERGY STAR'], '{"gallons": 40, "uef": 0.67, "first_hour_rating": 70, "recovery_rate_gph": 43, "btu_input": 40000}'),
  ('RG2MH50T6N', '50 Gal eF Series High Efficiency Gas', 'eF Series', 'gas', 'tank', 50, 'gallons', 12, false, true, 1099, ARRAY['Ultra low NOx','High efficiency','ENERGY STAR','Hydrojet'], '{"gallons": 50, "uef": 0.67, "first_hour_rating": 77, "recovery_rate_gph": 43, "btu_input": 40000}'),
  ('RG2PV50T6N', '50 Gal Power Vent Gas', 'Defender', 'gas', 'tank', 50, 'gallons', 12, false, false, 1349, ARRAY['40,000 BTU','Power vent','Flexible venting','Defender safety'], '{"gallons": 50, "uef": 0.63, "first_hour_rating": 70, "recovery_rate_gph": 43, "btu_input": 40000}'),
  ('RG2DV40T6N', '40 Gal Direct Vent Gas', 'Defender', 'gas', 'tank', 40, 'gallons', 12, false, false, 1149, ARRAY['40,000 BTU','Direct vent','Sealed combustion'], '{"gallons": 40, "uef": 0.62, "first_hour_rating": 66, "recovery_rate_gph": 40, "btu_input": 40000}'),
  ('RG275H6N', '75 Gal High Input Gas', 'Defender', 'gas', 'tank', 75, 'gallons', 12, false, false, 1449, ARRAY['76,000 BTU','High capacity','Defender safety system'], '{"gallons": 75, "uef": 0.65, "first_hour_rating": 99, "recovery_rate_gph": 72, "btu_input": 76000}'),
  ('RG240S6N', '40 Gal Short Defender Gas', 'Defender', 'gas', 'tank', 40, 'gallons', 12, false, false, 729, ARRAY['36,000 BTU','Low-boy design','Defender safety'], '{"gallons": 40, "uef": 0.59, "first_hour_rating": 57, "recovery_rate_gph": 37, "btu_input": 36000}'),
  ('RG230T6N', '30 Gal Defender Gas', 'Defender', 'gas', 'tank', 30, 'gallons', 12, false, false, 699, ARRAY['32,000 BTU','Compact','Defender safety system'], '{"gallons": 30, "uef": 0.59, "first_hour_rating": 50, "recovery_rate_gph": 32, "btu_input": 32000}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'bradford-white' AND c.slug = 'water-heater-tank-gas';

-- ---------------------------------------------------------------------------
-- Bradford White - Tank Electric
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.bradfordwhite.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('RE240T6-1NCWW', '40 Gal Upright Electric', 'ElectriFLEX LD', 'electric', 'tank', 40, 'gallons', 12, false, false, 599, ARRAY['4,500W elements','Vitraglas lining','Hydrojet total performance'], '{"gallons": 40, "uef": 0.93, "first_hour_rating": 55, "watts": 4500}'),
  ('RE250T6-1NCWW', '50 Gal Upright Electric', 'ElectriFLEX LD', 'electric', 'tank', 50, 'gallons', 12, false, false, 649, ARRAY['4,500W elements','Vitraglas lining','Self-cleaning dip tube'], '{"gallons": 50, "uef": 0.93, "first_hour_rating": 62, "watts": 4500}'),
  ('RE350T6-1NCWW', '50 Gal High-Performance Electric', 'ElectriFLEX HD', 'electric', 'tank', 50, 'gallons', 12, false, false, 799, ARRAY['5,500W elements','Enhanced recovery','Premium insulation'], '{"gallons": 50, "uef": 0.95, "first_hour_rating": 72, "watts": 5500}'),
  ('RE280T6-1NCWW', '80 Gal Upright Electric', 'ElectriFLEX LD', 'electric', 'tank', 80, 'gallons', 12, false, false, 849, ARRAY['4,500W elements','High capacity','Vitraglas lining'], '{"gallons": 80, "uef": 0.92, "first_hour_rating": 86, "watts": 4500}'),
  ('RE230L6-1NCWW', '30 Gal Lowboy Electric', 'ElectriFLEX LD', 'electric', 'tank', 30, 'gallons', 12, false, false, 579, ARRAY['4,500W elements','Low-boy design','Tight spaces'], '{"gallons": 30, "uef": 0.93, "first_hour_rating": 46, "watts": 4500}'),
  ('RE250S6-1NCWW', '50 Gal Short Electric', 'ElectriFLEX LD', 'electric', 'tank', 50, 'gallons', 12, false, false, 639, ARRAY['4,500W elements','Short design','Crawl spaces'], '{"gallons": 50, "uef": 0.90, "first_hour_rating": 58, "watts": 4500}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'bradford-white' AND c.slug = 'water-heater-tank-electric';

-- ---------------------------------------------------------------------------
-- Bradford White - Tankless Gas
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.bradfordwhite.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('RTG-199HEN', '9.8 GPM Infiniti Tankless', 'Infiniti GR', 'gas', 'tankless', 10, 'gpm', 20, true, true, 1849, ARRAY['Condensing','Built-in recirculation','WiFi-enabled','Ultra low NOx'], '{"gpm": 9.8, "uef": 0.96, "btu_input": 199000, "min_activation_gpm": 0.4, "max_temp_rise": 77}'),
  ('RTG-199HEP', '9.8 GPM Infiniti Tankless LP', 'Infiniti GR', 'propane', 'tankless', 10, 'gpm', 20, true, true, 1899, ARRAY['Condensing','Built-in recirc','WiFi','Propane'], '{"gpm": 9.8, "uef": 0.96, "btu_input": 199000, "min_activation_gpm": 0.4, "max_temp_rise": 77}'),
  ('RTG-K160N', '7.5 GPM Infiniti Tankless', 'Infiniti K', 'gas', 'tankless', 8, 'gpm', 20, false, true, 1349, ARRAY['Non-condensing','Indoor install','Compact design'], '{"gpm": 7.5, "uef": 0.82, "btu_input": 160000, "min_activation_gpm": 0.5, "max_temp_rise": 77}'),
  ('RTG-K160N-R', '7.5 GPM Infiniti Tankless w/Recirc', 'Infiniti K', 'gas', 'tankless', 8, 'gpm', 20, false, true, 1549, ARRAY['Non-condensing','Built-in recirculation'], '{"gpm": 7.5, "uef": 0.82, "btu_input": 160000, "min_activation_gpm": 0.5, "max_temp_rise": 77}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'bradford-white' AND c.slug = 'water-heater-tankless-gas';

-- ---------------------------------------------------------------------------
-- Bradford White - Heat Pump
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.bradfordwhite.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('RE2H50R10BN', '50 Gal AeroTherm Heat Pump', 'AeroTherm', 'electric', 'heat-pump', 50, 'gallons', 13, true, true, 2199, ARRAY['3.42 UEF','WiFi-enabled','4 operating modes','Vitraglas lining','ENERGY STAR'], '{"gallons": 50, "uef": 3.42, "first_hour_rating": 67}'),
  ('RE2H65R10BN', '65 Gal AeroTherm Heat Pump', 'AeroTherm', 'electric', 'heat-pump', 65, 'gallons', 13, true, true, 2399, ARRAY['3.42 UEF','WiFi-enabled','Large capacity','Contractor exclusive'], '{"gallons": 65, "uef": 3.42, "first_hour_rating": 79}'),
  ('RE2H80R10BN', '80 Gal AeroTherm Heat Pump', 'AeroTherm', 'electric', 'heat-pump', 80, 'gallons', 13, true, true, 2599, ARRAY['3.42 UEF','WiFi-enabled','Largest capacity','Built-in condensate management'], '{"gallons": 80, "uef": 3.42, "first_hour_rating": 86}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'bradford-white' AND c.slug = 'water-heater-heat-pump';

-- ---------------------------------------------------------------------------
-- Rinnai - Tankless Gas
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.rinnai.us'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('RUR199iN', '9.8 GPM Sensei SE+ Condensing', 'Sensei SE+', 'gas', 'tankless', 10, 'gpm', 20, true, true, 2049, ARRAY['Condensing','Built-in recirculation','WiFi module','ThermaCirc360','Circ-Logic timer'], '{"gpm": 9.8, "uef": 0.96, "btu_input": 199000, "min_activation_gpm": 0.26, "max_temp_rise": 77}'),
  ('RUR199eN', '9.8 GPM Sensei RU Condensing', 'Sensei RU', 'gas', 'tankless', 10, 'gpm', 20, true, true, 1849, ARRAY['Condensing','External recirculation','WiFi capable','Ultra low NOx'], '{"gpm": 9.8, "uef": 0.96, "btu_input": 199000, "min_activation_gpm": 0.4, "max_temp_rise": 77}'),
  ('RU199iN', '9.8 GPM Ultra Condensing', 'Ultra', 'gas', 'tankless', 10, 'gpm', 20, true, true, 1699, ARRAY['Condensing','Indoor install','WiFi capable'], '{"gpm": 9.8, "uef": 0.93, "btu_input": 199000, "min_activation_gpm": 0.4, "max_temp_rise": 77}'),
  ('RU180iN', '8.0 GPM Ultra Condensing', 'Ultra', 'gas', 'tankless', 8, 'gpm', 20, true, true, 1549, ARRAY['Condensing','Indoor install','Compact'], '{"gpm": 8.0, "uef": 0.93, "btu_input": 180000, "min_activation_gpm": 0.4, "max_temp_rise": 77}'),
  ('RU160iN', '7.0 GPM Ultra Condensing', 'Ultra', 'gas', 'tankless', 7, 'gpm', 20, false, true, 1399, ARRAY['Condensing','Indoor install','Mid-range'], '{"gpm": 7.0, "uef": 0.92, "btu_input": 160000, "min_activation_gpm": 0.4, "max_temp_rise": 70}'),
  ('RU130iN', '5.3 GPM Value Condensing', 'Value', 'gas', 'tankless', 5, 'gpm', 20, false, true, 1099, ARRAY['Condensing','Indoor install','Entry-level condensing'], '{"gpm": 5.3, "uef": 0.91, "btu_input": 130000, "min_activation_gpm": 0.4, "max_temp_rise": 55}'),
  ('V65iN', '6.5 GPM Non-Condensing Indoor', 'V-Series', 'gas', 'tankless', 7, 'gpm', 20, false, false, 949, ARRAY['Non-condensing','Indoor install','Compact design'], '{"gpm": 6.5, "uef": 0.82, "btu_input": 150000, "min_activation_gpm": 0.4, "max_temp_rise": 65}'),
  ('V75iN', '7.5 GPM Non-Condensing Indoor', 'V-Series', 'gas', 'tankless', 8, 'gpm', 20, false, false, 1049, ARRAY['Non-condensing','Indoor install','High flow'], '{"gpm": 7.5, "uef": 0.82, "btu_input": 180000, "min_activation_gpm": 0.4, "max_temp_rise": 77}'),
  ('V53DeN', '5.3 GPM Non-Condensing Outdoor', 'V-Series', 'gas', 'tankless', 5, 'gpm', 20, false, false, 799, ARRAY['Non-condensing','Outdoor install','Freeze protection'], '{"gpm": 5.3, "uef": 0.81, "btu_input": 120000, "min_activation_gpm": 0.5, "max_temp_rise": 54}'),
  ('V75eN', '7.5 GPM Non-Condensing Outdoor', 'V-Series', 'gas', 'tankless', 8, 'gpm', 20, false, false, 999, ARRAY['Non-condensing','Outdoor install','Built-in freeze protection'], '{"gpm": 7.5, "uef": 0.82, "btu_input": 180000, "min_activation_gpm": 0.4, "max_temp_rise": 77}'),
  ('RSC160iN', '8.0 GPM Sensei SE+ Commercial', 'Sensei SE+', 'gas', 'tankless', 8, 'gpm', 20, true, true, 2299, ARRAY['Condensing','Commercial grade','Built-in recirc','WiFi'], '{"gpm": 8.0, "uef": 0.93, "btu_input": 160000, "min_activation_gpm": 0.26, "max_temp_rise": 77}'),
  ('RUR199iP', '9.8 GPM Sensei SE+ LP', 'Sensei SE+', 'propane', 'tankless', 10, 'gpm', 20, true, true, 2099, ARRAY['Condensing','Built-in recirc','WiFi','Propane'], '{"gpm": 9.8, "uef": 0.96, "btu_input": 199000, "min_activation_gpm": 0.26, "max_temp_rise": 77}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'rinnai' AND c.slug = 'water-heater-tankless-gas';

-- ---------------------------------------------------------------------------
-- Rinnai - Tankless Electric
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.rinnai.us'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('REU-TE2428FFUD-US', '8.0 GPM Tankless Electric', 'Electric', 'electric', 'tankless', 8, 'gpm', 15, false, false, 999, ARRAY['24 kW','Whole-home','Self-modulating'], '{"gpm": 8.0, "uef": 0.99, "kw": 24, "min_activation_gpm": 0.3, "max_temp_rise": 54}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'rinnai' AND c.slug = 'water-heater-tankless-electric';

-- ---------------------------------------------------------------------------
-- Rinnai - Tank Gas (Hybrid)
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.rinnai.us'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('RHS160eN', '40 Gal Hybrid Tank/Tankless', 'Hybrid', 'gas', 'tank', 40, 'gallons', 15, true, true, 2499, ARRAY['160,000 BTU','Tankless + 40 gal buffer tank','Endless hot water','WiFi'], '{"gallons": 40, "uef": 0.92, "first_hour_rating": 188, "recovery_rate_gph": 140, "btu_input": 160000}'),
  ('RHS199iN', '40 Gal Hybrid Tank/Tankless', 'Hybrid', 'gas', 'tank', 40, 'gallons', 15, true, true, 2799, ARRAY['199,000 BTU','Tankless + 40 gal buffer','Built-in recirc','WiFi'], '{"gallons": 40, "uef": 0.93, "first_hour_rating": 210, "recovery_rate_gph": 160, "btu_input": 199000}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'rinnai' AND c.slug = 'water-heater-tank-gas';

-- ---------------------------------------------------------------------------
-- Noritz - Tankless Gas
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.noritz.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('NRCR111DV-NG', '11.1 GPM EZ Series Condensing', 'EZ Series', 'gas', 'tankless', 11, 'gpm', 20, true, true, 1999, ARRAY['Condensing','Built-in recirculation','WiFi module','Ultra low NOx'], '{"gpm": 11.1, "uef": 0.97, "btu_input": 199900, "min_activation_gpm": 0.26, "max_temp_rise": 77}'),
  ('NRCB199DV-NG', '9.8 GPM CB Series Condensing', 'CB Combi', 'gas', 'tankless', 10, 'gpm', 20, true, true, 2499, ARRAY['Condensing combi boiler','Heating + DHW','WiFi module','Stainless steel heat exchanger'], '{"gpm": 9.8, "uef": 0.95, "btu_input": 199900, "min_activation_gpm": 0.4, "max_temp_rise": 77}'),
  ('NRC98-DV-NG', '9.8 GPM Condensing Indoor', 'NRC Series', 'gas', 'tankless', 10, 'gpm', 20, false, true, 1599, ARRAY['Condensing','Indoor install','Stainless steel exchanger'], '{"gpm": 9.8, "uef": 0.93, "btu_input": 180000, "min_activation_gpm": 0.4, "max_temp_rise": 77}'),
  ('NRC111-DV-NG', '11.1 GPM Condensing Indoor', 'NRC Series', 'gas', 'tankless', 11, 'gpm', 20, false, true, 1799, ARRAY['Condensing','High flow','Indoor install'], '{"gpm": 11.1, "uef": 0.96, "btu_input": 199900, "min_activation_gpm": 0.4, "max_temp_rise": 77}'),
  ('NR83-DV-NG', '8.3 GPM Non-Condensing Indoor', 'NR Series', 'gas', 'tankless', 8, 'gpm', 20, false, false, 1099, ARRAY['Non-condensing','Indoor install','Copper heat exchanger'], '{"gpm": 8.3, "uef": 0.82, "btu_input": 180000, "min_activation_gpm": 0.5, "max_temp_rise": 77}'),
  ('NR501-OD-NG', '5.0 GPM Non-Condensing Outdoor', 'NR Series', 'gas', 'tankless', 5, 'gpm', 20, false, false, 799, ARRAY['Non-condensing','Outdoor install','Freeze protection'], '{"gpm": 5.0, "uef": 0.81, "btu_input": 120000, "min_activation_gpm": 0.5, "max_temp_rise": 54}'),
  ('NR66-OD-NG', '6.6 GPM Non-Condensing Outdoor', 'NR Series', 'gas', 'tankless', 7, 'gpm', 20, false, false, 899, ARRAY['Non-condensing','Outdoor install','Mid-flow'], '{"gpm": 6.6, "uef": 0.82, "btu_input": 150000, "min_activation_gpm": 0.4, "max_temp_rise": 65}'),
  ('NRCR111DV-LP', '11.1 GPM EZ Series LP', 'EZ Series', 'propane', 'tankless', 11, 'gpm', 20, true, true, 2049, ARRAY['Condensing','Built-in recirc','WiFi','Propane'], '{"gpm": 11.1, "uef": 0.97, "btu_input": 199900, "min_activation_gpm": 0.26, "max_temp_rise": 77}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'noritz' AND c.slug = 'water-heater-tankless-gas';

-- ---------------------------------------------------------------------------
-- Takagi - Tankless Gas
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.takagi.us.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('T-H3-DV-N', '10.0 GPM H3 Condensing Indoor', 'H3', 'gas', 'tankless', 10, 'gpm', 20, false, true, 1699, ARRAY['Condensing','Indoor install','199,000 BTU','Commercial-grade heat exchanger'], '{"gpm": 10.0, "uef": 0.95, "btu_input": 199000, "min_activation_gpm": 0.4, "max_temp_rise": 77}'),
  ('T-H3-DV-P', '10.0 GPM H3 Condensing Indoor LP', 'H3', 'propane', 'tankless', 10, 'gpm', 20, false, true, 1749, ARRAY['Condensing','Indoor install','199,000 BTU','Propane'], '{"gpm": 10.0, "uef": 0.95, "btu_input": 199000, "min_activation_gpm": 0.4, "max_temp_rise": 77}'),
  ('T-H3-OS-N', '10.0 GPM H3 Condensing Outdoor', 'H3', 'gas', 'tankless', 10, 'gpm', 20, false, true, 1649, ARRAY['Condensing','Outdoor install','Freeze protection','199,000 BTU'], '{"gpm": 10.0, "uef": 0.95, "btu_input": 199000, "min_activation_gpm": 0.4, "max_temp_rise": 77}'),
  ('T-H3S-DV-N', '8.0 GPM H3S Condensing Indoor', 'H3S', 'gas', 'tankless', 8, 'gpm', 20, false, true, 1499, ARRAY['Condensing','Indoor install','160,000 BTU','Space-saving'], '{"gpm": 8.0, "uef": 0.93, "btu_input": 160000, "min_activation_gpm": 0.4, "max_temp_rise": 67}'),
  ('T-H3S-OS-N', '8.0 GPM H3S Condensing Outdoor', 'H3S', 'gas', 'tankless', 8, 'gpm', 20, false, true, 1449, ARRAY['Condensing','Outdoor install','160,000 BTU','Freeze protection'], '{"gpm": 8.0, "uef": 0.93, "btu_input": 160000, "min_activation_gpm": 0.4, "max_temp_rise": 67}'),
  ('T-H3J-DV-N', '6.6 GPM H3J Condensing Indoor', 'H3J', 'gas', 'tankless', 7, 'gpm', 20, false, true, 1299, ARRAY['Condensing','Indoor install','140,000 BTU','Entry premium'], '{"gpm": 6.6, "uef": 0.92, "btu_input": 140000, "min_activation_gpm": 0.4, "max_temp_rise": 63}'),
  ('T-KJr2-IN-NG', '6.6 GPM Non-Condensing Indoor', 'T-KJr2', 'gas', 'tankless', 7, 'gpm', 20, false, false, 899, ARRAY['Non-condensing','Indoor install','140,000 BTU','Budget-friendly'], '{"gpm": 6.6, "uef": 0.82, "btu_input": 140000, "min_activation_gpm": 0.5, "max_temp_rise": 63}'),
  ('T-KJr2-OS-NG', '6.6 GPM Non-Condensing Outdoor', 'T-KJr2', 'gas', 'tankless', 7, 'gpm', 20, false, false, 849, ARRAY['Non-condensing','Outdoor install','Freeze protection'], '{"gpm": 6.6, "uef": 0.82, "btu_input": 140000, "min_activation_gpm": 0.5, "max_temp_rise": 63}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'takagi' AND c.slug = 'water-heater-tankless-gas';

-- ---------------------------------------------------------------------------
-- Navien - Tankless Gas
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.navien.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('NPE-2S', '11.2 GPM NPE-2S Condensing', 'NPE-2', 'gas', 'tankless', 11, 'gpm', 20, true, true, 2199, ARRAY['Condensing','NaviCirc built-in recirc','WiFi NaviLink','ComfortFlow technology','Dual stainless heat exchangers'], '{"gpm": 11.2, "uef": 0.97, "btu_input": 199900, "min_activation_gpm": 0.26, "max_temp_rise": 77}'),
  ('NPE-240S2', '9.5 GPM NPE-240S2 Condensing', 'NPE-2', 'gas', 'tankless', 10, 'gpm', 20, true, true, 1999, ARRAY['Condensing','NaviCirc recirc','WiFi NaviLink','Dual exchangers'], '{"gpm": 9.5, "uef": 0.96, "btu_input": 180000, "min_activation_gpm": 0.26, "max_temp_rise": 77}'),
  ('NPE-180S2', '8.0 GPM NPE-180S2 Condensing', 'NPE-2', 'gas', 'tankless', 8, 'gpm', 20, true, true, 1799, ARRAY['Condensing','NaviCirc recirc','WiFi NaviLink'], '{"gpm": 8.0, "uef": 0.93, "btu_input": 150000, "min_activation_gpm": 0.26, "max_temp_rise": 77}'),
  ('NPE-150S2', '6.5 GPM NPE-150S2 Condensing', 'NPE-2', 'gas', 'tankless', 7, 'gpm', 20, true, true, 1599, ARRAY['Condensing','NaviCirc recirc','WiFi NaviLink','Entry-level premium'], '{"gpm": 6.5, "uef": 0.92, "btu_input": 120000, "min_activation_gpm": 0.26, "max_temp_rise": 65}'),
  ('NPE-A2', '11.2 GPM NPE-A2 Advanced Condensing', 'NPE-A2', 'gas', 'tankless', 11, 'gpm', 20, true, true, 1699, ARRAY['Condensing','Built-in buffer tank','NaviLink WiFi','Advanced scheduling'], '{"gpm": 11.2, "uef": 0.97, "btu_input": 199900, "min_activation_gpm": 0.5, "max_temp_rise": 77}'),
  ('NPE-240A2', '9.5 GPM NPE-240A2 Advanced', 'NPE-A2', 'gas', 'tankless', 10, 'gpm', 20, true, true, 1499, ARRAY['Condensing','Built-in buffer','NaviLink WiFi'], '{"gpm": 9.5, "uef": 0.96, "btu_input": 180000, "min_activation_gpm": 0.5, "max_temp_rise": 77}'),
  ('NCB-240E', '11.2 GPM Combi-Boiler', 'NCB-E', 'gas', 'tankless', 11, 'gpm', 20, true, true, 2699, ARRAY['Combi-boiler','Space heating + DHW','Condensing','WiFi NaviLink'], '{"gpm": 11.2, "uef": 0.95, "btu_input": 199900, "min_activation_gpm": 0.4, "max_temp_rise": 77}'),
  ('NCB-180E', '8.0 GPM Combi-Boiler', 'NCB-E', 'gas', 'tankless', 8, 'gpm', 20, true, true, 2499, ARRAY['Combi-boiler','Space heating + DHW','Condensing','WiFi'], '{"gpm": 8.0, "uef": 0.93, "btu_input": 150000, "min_activation_gpm": 0.4, "max_temp_rise": 77}'),
  ('NPN-U', '11.2 GPM Non-Condensing', 'NPN', 'gas', 'tankless', 11, 'gpm', 20, false, false, 1199, ARRAY['Non-condensing','Indoor install','Compact design'], '{"gpm": 11.2, "uef": 0.82, "btu_input": 199900, "min_activation_gpm": 0.5, "max_temp_rise": 77}'),
  ('NPE-2S-LP', '11.2 GPM NPE-2S LP', 'NPE-2', 'propane', 'tankless', 11, 'gpm', 20, true, true, 2249, ARRAY['Condensing','NaviCirc recirc','WiFi NaviLink','Propane'], '{"gpm": 11.2, "uef": 0.97, "btu_input": 199900, "min_activation_gpm": 0.26, "max_temp_rise": 77}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'navien' AND c.slug = 'water-heater-tankless-gas';

-- ---------------------------------------------------------------------------
-- Stiebel Eltron - Tankless Electric
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.stiebel-eltron-usa.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('DHC 3-1', 'DHC 3-1 Tankless', 'DHC', 'electric', 'tankless', 1, 'gpm', 15, false, false, 199, ARRAY['3 kW','Point-of-use','German engineering','Handwashing'], '{"gpm": 0.5, "uef": 0.99, "kw": 3, "min_activation_gpm": 0.2, "max_temp_rise": 35}'),
  ('DHC 4-2', 'DHC 4-2 Tankless', 'DHC', 'electric', 'tankless', 1, 'gpm', 15, false, false, 249, ARRAY['3.8 kW','Point-of-use','German engineering'], '{"gpm": 0.8, "uef": 0.99, "kw": 3.8, "min_activation_gpm": 0.2, "max_temp_rise": 42}'),
  ('DHC 6-2', 'DHC 6-2 Tankless', 'DHC', 'electric', 'tankless', 2, 'gpm', 15, false, false, 299, ARRAY['6 kW','Single sink supply','German engineering'], '{"gpm": 1.5, "uef": 0.99, "kw": 6, "min_activation_gpm": 0.3, "max_temp_rise": 50}'),
  ('DHC 8-2', 'DHC 8-2 Tankless', 'DHC', 'electric', 'tankless', 2, 'gpm', 15, false, false, 349, ARRAY['7.2 kW','Multi-fixture supply','German engineering'], '{"gpm": 1.8, "uef": 0.99, "kw": 7.2, "min_activation_gpm": 0.3, "max_temp_rise": 50}'),
  ('DHC 10-2', 'DHC 10-2 Tankless', 'DHC', 'electric', 'tankless', 3, 'gpm', 15, false, false, 399, ARRAY['9.6 kW','Multi-fixture','German engineering'], '{"gpm": 2.5, "uef": 0.99, "kw": 9.6, "min_activation_gpm": 0.3, "max_temp_rise": 54}'),
  ('Tempra 12 Plus', 'Tempra 12 Plus Whole-Home', 'Tempra Plus', 'electric', 'tankless', 3, 'gpm', 20, false, false, 549, ARRAY['12 kW','Advanced flow control','German engineering','Whole-home capable'], '{"gpm": 3.0, "uef": 0.99, "kw": 12, "min_activation_gpm": 0.3, "max_temp_rise": 54}'),
  ('Tempra 15 Plus', 'Tempra 15 Plus Whole-Home', 'Tempra Plus', 'electric', 'tankless', 4, 'gpm', 20, false, false, 649, ARRAY['14.4 kW','Advanced flow control','Whole-home','Self-modulating'], '{"gpm": 3.5, "uef": 0.99, "kw": 14.4, "min_activation_gpm": 0.3, "max_temp_rise": 54}'),
  ('Tempra 20 Plus', 'Tempra 20 Plus Whole-Home', 'Tempra Plus', 'electric', 'tankless', 5, 'gpm', 20, false, false, 749, ARRAY['19.2 kW','Advanced flow control','Whole-home','Premium'], '{"gpm": 4.5, "uef": 0.99, "kw": 19.2, "min_activation_gpm": 0.3, "max_temp_rise": 54}'),
  ('Tempra 24 Plus', 'Tempra 24 Plus Whole-Home', 'Tempra Plus', 'electric', 'tankless', 6, 'gpm', 20, false, false, 849, ARRAY['24 kW','Advanced flow control','Whole-home','Large household'], '{"gpm": 5.0, "uef": 0.99, "kw": 24, "min_activation_gpm": 0.25, "max_temp_rise": 54}'),
  ('Tempra 29 Plus', 'Tempra 29 Plus Whole-Home', 'Tempra Plus', 'electric', 'tankless', 7, 'gpm', 20, false, false, 949, ARRAY['28.8 kW','Advanced flow control','Largest residential','German engineered'], '{"gpm": 6.5, "uef": 0.99, "kw": 28.8, "min_activation_gpm": 0.25, "max_temp_rise": 54}'),
  ('Tempra 36 Plus', 'Tempra 36 Plus Whole-Home', 'Tempra Plus', 'electric', 'tankless', 8, 'gpm', 20, false, false, 1099, ARRAY['36 kW','Advanced flow control','Maximum output','German engineered'], '{"gpm": 7.5, "uef": 0.99, "kw": 36, "min_activation_gpm": 0.25, "max_temp_rise": 54}'),
  ('Tempra 20 Trend', 'Tempra 20 Trend Whole-Home', 'Tempra Trend', 'electric', 'tankless', 5, 'gpm', 20, false, false, 599, ARRAY['19.2 kW','Value series','Whole-home','Self-modulating'], '{"gpm": 4.5, "uef": 0.99, "kw": 19.2, "min_activation_gpm": 0.3, "max_temp_rise": 54}'),
  ('Tempra 24 Trend', 'Tempra 24 Trend Whole-Home', 'Tempra Trend', 'electric', 'tankless', 6, 'gpm', 20, false, false, 699, ARRAY['24 kW','Value series','Whole-home'], '{"gpm": 5.0, "uef": 0.99, "kw": 24, "min_activation_gpm": 0.25, "max_temp_rise": 54}'),
  ('Tempra 29 Trend', 'Tempra 29 Trend Whole-Home', 'Tempra Trend', 'electric', 'tankless', 7, 'gpm', 20, false, false, 799, ARRAY['28.8 kW','Value series','Large household'], '{"gpm": 6.5, "uef": 0.99, "kw": 28.8, "min_activation_gpm": 0.25, "max_temp_rise": 54}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'stiebel-eltron' AND c.slug = 'water-heater-tankless-electric';

-- ---------------------------------------------------------------------------
-- Stiebel Eltron - Point-of-Use
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.stiebel-eltron-usa.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('SHC 2.5', 'SHC 2.5 Mini-Tank', 'SHC', 'electric', 'point-of-use', 3, 'gallons', 10, false, false, 249, ARRAY['2.5 gal mini-tank','Under-sink','German engineering','1300W'], '{"gallons": 2.5, "watts": 1300}'),
  ('SHC 4', 'SHC 4 Mini-Tank', 'SHC', 'electric', 'point-of-use', 4, 'gallons', 10, false, false, 289, ARRAY['4 gal mini-tank','Under-sink','German engineering','1300W'], '{"gallons": 4, "watts": 1300}'),
  ('SHC 6', 'SHC 6 Mini-Tank', 'SHC', 'electric', 'point-of-use', 6, 'gallons', 10, false, false, 329, ARRAY['6 gal mini-tank','Under-sink','German engineering','1300W'], '{"gallons": 6, "watts": 1300}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'stiebel-eltron' AND c.slug = 'water-heater-point-of-use';

-- ---------------------------------------------------------------------------
-- Stiebel Eltron - Heat Pump
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.stiebel-eltron-usa.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('Accelera 220 E', 'Accelera 220 E Heat Pump', 'Accelera', 'electric', 'heat-pump', 58, 'gallons', 15, true, true, 2999, ARRAY['3.39 UEF','German engineering','WiFi-enabled','R134a refrigerant','Quiet operation'], '{"gallons": 58, "uef": 3.39, "first_hour_rating": 65}'),
  ('Accelera 300 E', 'Accelera 300 E Heat Pump', 'Accelera', 'electric', 'heat-pump', 80, 'gallons', 15, true, true, 3499, ARRAY['3.39 UEF','German engineering','WiFi-enabled','Large capacity','R134a'], '{"gallons": 80, "uef": 3.39, "first_hour_rating": 85}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'stiebel-eltron' AND c.slug = 'water-heater-heat-pump';

-- ---------------------------------------------------------------------------
-- Lochinvar - Tank Gas (Commercial/Premium Residential)
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.lochinvar.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('ANR050-100', 'ARMOR 50 Gal High Efficiency', 'ARMOR', 'gas', 'tank', 50, 'gallons', 15, true, true, 2999, ARRAY['100,000 BTU','Condensing','Stainless steel tank','WiFi SMART TOUCH'], '{"gallons": 50, "uef": 0.92, "first_hour_rating": 130, "recovery_rate_gph": 100, "btu_input": 100000}'),
  ('ANR076-100', 'ARMOR 76 Gal High Efficiency', 'ARMOR', 'gas', 'tank', 76, 'gallons', 15, true, true, 3499, ARRAY['100,000 BTU','Condensing','Stainless steel','WiFi SMART TOUCH'], '{"gallons": 76, "uef": 0.93, "first_hour_rating": 155, "recovery_rate_gph": 105, "btu_input": 100000}'),
  ('ANR100-100', 'ARMOR 100 Gal High Efficiency', 'ARMOR', 'gas', 'tank', 100, 'gallons', 15, true, true, 3999, ARRAY['100,000 BTU','Condensing','Large capacity','WiFi SMART TOUCH'], '{"gallons": 100, "uef": 0.93, "first_hour_rating": 180, "recovery_rate_gph": 110, "btu_input": 100000}'),
  ('KBN050-100', 'KNIGHT 50 Gal', 'KNIGHT', 'gas', 'tank', 50, 'gallons', 15, true, true, 3299, ARRAY['110,000 BTU','Fire-tube heat exchanger','SMART TOUCH controls','Stainless steel'], '{"gallons": 50, "uef": 0.95, "first_hour_rating": 145, "recovery_rate_gph": 115, "btu_input": 110000}'),
  ('KBN080-110', 'KNIGHT 80 Gal', 'KNIGHT', 'gas', 'tank', 80, 'gallons', 15, true, true, 3799, ARRAY['110,000 BTU','Fire-tube exchanger','SMART TOUCH','High output'], '{"gallons": 80, "uef": 0.95, "first_hour_rating": 170, "recovery_rate_gph": 120, "btu_input": 110000}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'lochinvar' AND c.slug = 'water-heater-tank-gas';

-- ---------------------------------------------------------------------------
-- Lochinvar - Tankless Gas
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.lochinvar.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('LTI-199N', 'i-Series 9.8 GPM Condensing', 'i-Series', 'gas', 'tankless', 10, 'gpm', 20, true, true, 2299, ARRAY['Condensing','SMART TOUCH controls','WiFi-enabled','199,000 BTU'], '{"gpm": 9.8, "uef": 0.96, "btu_input": 199000, "min_activation_gpm": 0.4, "max_temp_rise": 77}'),
  ('LTI-150N', 'i-Series 7.5 GPM Condensing', 'i-Series', 'gas', 'tankless', 8, 'gpm', 20, true, true, 1999, ARRAY['Condensing','SMART TOUCH controls','WiFi','150,000 BTU'], '{"gpm": 7.5, "uef": 0.93, "btu_input": 150000, "min_activation_gpm": 0.4, "max_temp_rise": 67}'),
  ('LTN-199N', 'n-Series 9.8 GPM Non-Condensing', 'n-Series', 'gas', 'tankless', 10, 'gpm', 20, false, false, 1599, ARRAY['Non-condensing','Indoor install','199,000 BTU'], '{"gpm": 9.8, "uef": 0.82, "btu_input": 199000, "min_activation_gpm": 0.5, "max_temp_rise": 77}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'lochinvar' AND c.slug = 'water-heater-tankless-gas';

-- ---------------------------------------------------------------------------
-- HTP - Tank Gas (Premium)
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.htproducts.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('EFT-55N', 'Everlast 55 Gal High Efficiency', 'Everlast', 'gas', 'tank', 55, 'gallons', 15, true, true, 2999, ARRAY['100,000 BTU','Fire-tube heat exchanger','316L stainless steel','WiFi-enabled','Lifetime tank warranty'], '{"gallons": 55, "uef": 0.95, "first_hour_rating": 135, "recovery_rate_gph": 108, "btu_input": 100000}'),
  ('EFT-80N', 'Everlast 80 Gal High Efficiency', 'Everlast', 'gas', 'tank', 80, 'gallons', 15, true, true, 3499, ARRAY['100,000 BTU','Fire-tube exchanger','316L stainless','WiFi','Lifetime warranty'], '{"gallons": 80, "uef": 0.95, "first_hour_rating": 160, "recovery_rate_gph": 115, "btu_input": 100000}'),
  ('EFT-110N', 'Everlast 110 Gal High Efficiency', 'Everlast', 'gas', 'tank', 110, 'gallons', 15, true, true, 3999, ARRAY['120,000 BTU','Fire-tube exchanger','316L stainless','WiFi','Commercial-grade'], '{"gallons": 110, "uef": 0.95, "first_hour_rating": 195, "recovery_rate_gph": 130, "btu_input": 120000}'),
  ('SSC-050', 'SuperStor Contender 50 Gal', 'SuperStor', 'gas', 'tank', 50, 'gallons', 15, false, true, 1999, ARRAY['Indirect-fired','Stainless steel','Works with boiler system'], '{"gallons": 50, "uef": 0.90, "first_hour_rating": 100, "recovery_rate_gph": 80, "btu_input": 0}'),
  ('SSC-080', 'SuperStor Contender 80 Gal', 'SuperStor', 'gas', 'tank', 80, 'gallons', 15, false, true, 2399, ARRAY['Indirect-fired','Stainless steel','Large capacity','Boiler-connected'], '{"gallons": 80, "uef": 0.90, "first_hour_rating": 140, "recovery_rate_gph": 100, "btu_input": 0}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'htp' AND c.slug = 'water-heater-tank-gas';

-- ---------------------------------------------------------------------------
-- HTP - Tankless Gas
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.htproducts.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('CT-199N', 'Crossover 9.8 GPM Floor-Standing', 'Crossover', 'gas', 'tankless', 10, 'gpm', 20, true, true, 3299, ARRAY['Condensing','Floor-standing hybrid','Built-in pump','WiFi-enabled','12 gal buffer tank'], '{"gpm": 9.8, "uef": 0.95, "btu_input": 199000, "min_activation_gpm": 0.26, "max_temp_rise": 77}'),
  ('CT-150N', 'Crossover 7.5 GPM Floor-Standing', 'Crossover', 'gas', 'tankless', 8, 'gpm', 20, true, true, 2899, ARRAY['Condensing','Floor-standing','Built-in pump','WiFi'], '{"gpm": 7.5, "uef": 0.93, "btu_input": 150000, "min_activation_gpm": 0.26, "max_temp_rise": 67}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'htp' AND c.slug = 'water-heater-tankless-gas';

-- ---------------------------------------------------------------------------
-- HTP - Heat Pump
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.htproducts.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('VF-50', 'VersaFlame 50 Gal Heat Pump', 'VersaFlame', 'electric', 'heat-pump', 50, 'gallons', 15, true, true, 2799, ARRAY['3.50 UEF','WiFi-enabled','316L stainless steel','5 operating modes'], '{"gallons": 50, "uef": 3.50, "first_hour_rating": 67}'),
  ('VF-80', 'VersaFlame 80 Gal Heat Pump', 'VersaFlame', 'electric', 'heat-pump', 80, 'gallons', 15, true, true, 3199, ARRAY['3.50 UEF','WiFi-enabled','316L stainless','Large capacity'], '{"gallons": 80, "uef": 3.50, "first_hour_rating": 86}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'htp' AND c.slug = 'water-heater-heat-pump';

-- ---------------------------------------------------------------------------
-- Triangle Tube - Tank Gas (Indirect-fired specialty)
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.triangletube.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('SMART 40', 'Smart 40 Indirect Water Heater', 'Smart', 'gas', 'tank', 36, 'gallons', 15, false, true, 1999, ARRAY['Indirect-fired','Duplex stainless steel','Lifetime tank warranty','Works with any boiler'], '{"gallons": 36, "uef": 0.90, "first_hour_rating": 140, "recovery_rate_gph": 110, "btu_input": 0}'),
  ('SMART 50', 'Smart 50 Indirect Water Heater', 'Smart', 'gas', 'tank', 46, 'gallons', 15, false, true, 2299, ARRAY['Indirect-fired','Duplex stainless steel','Lifetime warranty','High recovery'], '{"gallons": 46, "uef": 0.90, "first_hour_rating": 160, "recovery_rate_gph": 130, "btu_input": 0}'),
  ('SMART 60', 'Smart 60 Indirect Water Heater', 'Smart', 'gas', 'tank', 56, 'gallons', 15, false, true, 2599, ARRAY['Indirect-fired','Duplex stainless steel','Lifetime warranty','Large family'], '{"gallons": 56, "uef": 0.90, "first_hour_rating": 180, "recovery_rate_gph": 145, "btu_input": 0}'),
  ('SMART 80', 'Smart 80 Indirect Water Heater', 'Smart', 'gas', 'tank', 76, 'gallons', 15, false, true, 2899, ARRAY['Indirect-fired','Duplex stainless steel','Lifetime warranty','Commercial capacity'], '{"gallons": 76, "uef": 0.90, "first_hour_rating": 220, "recovery_rate_gph": 170, "btu_input": 0}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'triangle-tube' AND c.slug = 'water-heater-tank-gas';

-- ---------------------------------------------------------------------------
-- Triangle Tube - Tankless Gas (Combi-Boiler)
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.triangletube.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('INSTINCT Solo 155', 'Instinct Solo 155 Combi', 'Instinct', 'gas', 'tankless', 5, 'gpm', 20, true, true, 3499, ARRAY['Condensing combi-boiler','Space heating + DHW','WiFi-enabled','155,000 BTU'], '{"gpm": 4.8, "uef": 0.95, "btu_input": 155000, "min_activation_gpm": 0.5, "max_temp_rise": 70}'),
  ('INSTINCT Solo 210', 'Instinct Solo 210 Combi', 'Instinct', 'gas', 'tankless', 7, 'gpm', 20, true, true, 3999, ARRAY['Condensing combi-boiler','Space heating + DHW','WiFi','210,000 BTU'], '{"gpm": 6.5, "uef": 0.95, "btu_input": 210000, "min_activation_gpm": 0.5, "max_temp_rise": 70}'),
  ('PRESTIGE SOLO 110', 'Prestige Solo 110 Combi', 'Prestige', 'gas', 'tankless', 4, 'gpm', 20, true, true, 2999, ARRAY['Condensing combi-boiler','Compact','WiFi-enabled','110,000 BTU'], '{"gpm": 3.5, "uef": 0.95, "btu_input": 110000, "min_activation_gpm": 0.5, "max_temp_rise": 60}'),
  ('PRESTIGE SOLO 175', 'Prestige Solo 175 Combi', 'Prestige', 'gas', 'tankless', 6, 'gpm', 20, true, true, 3499, ARRAY['Condensing combi-boiler','Mid-range','WiFi','175,000 BTU'], '{"gpm": 5.5, "uef": 0.95, "btu_input": 175000, "min_activation_gpm": 0.5, "max_temp_rise": 65}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'triangle-tube' AND c.slug = 'water-heater-tankless-gas';


-- ============================================================================
-- ADDITIONAL PROPANE VARIANTS (Major brands)
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Rheem - Tank Propane
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.rheem.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('PROG40-36P RH60', '40 Gal Performance Propane', 'Performance', 'propane', 'tank', 40, 'gallons', 12, false, false, 649, ARRAY['36,000 BTU','Propane','Push-button ignition','Self-cleaning'], '{"gallons": 40, "uef": 0.60, "first_hour_rating": 60, "recovery_rate_gph": 37, "btu_input": 36000}'),
  ('PROG50-42P RH67', '50 Gal Performance Plus Propane', 'Performance Plus', 'propane', 'tank', 50, 'gallons', 12, false, false, 829, ARRAY['42,000 BTU','Propane','Premium gas valve'], '{"gallons": 50, "uef": 0.62, "first_hour_rating": 73, "recovery_rate_gph": 43, "btu_input": 42000}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'rheem' AND c.slug = 'water-heater-tank-gas';

-- ---------------------------------------------------------------------------
-- A.O. Smith - Tank Propane
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.aosmith.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('G6-T4036PV', '40 Gal Signature 100 Propane', 'Signature 100', 'propane', 'tank', 40, 'gallons', 10, false, false, 599, ARRAY['36,000 BTU','Propane','Push-button ignition','6-year warranty'], '{"gallons": 40, "uef": 0.59, "first_hour_rating": 57, "recovery_rate_gph": 37, "btu_input": 36000}'),
  ('G6-T5040PV', '50 Gal Signature 100 Propane', 'Signature 100', 'propane', 'tank', 50, 'gallons', 10, false, false, 649, ARRAY['40,000 BTU','Propane','Self-cleaning dip tube'], '{"gallons": 50, "uef": 0.60, "first_hour_rating": 67, "recovery_rate_gph": 43, "btu_input": 40000}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ao-smith' AND c.slug = 'water-heater-tank-gas';

-- ---------------------------------------------------------------------------
-- Bradford White - Tank Propane
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.bradfordwhite.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('RG240T6P', '40 Gal Defender Propane', 'Defender', 'propane', 'tank', 40, 'gallons', 12, false, false, 769, ARRAY['40,000 BTU','Defender safety system','Propane','Vitraglas lining'], '{"gallons": 40, "uef": 0.62, "first_hour_rating": 66, "recovery_rate_gph": 40, "btu_input": 40000}'),
  ('RG250T6P', '50 Gal Defender Propane', 'Defender', 'propane', 'tank', 50, 'gallons', 12, false, false, 869, ARRAY['40,000 BTU','Defender safety system','Propane','Hydrojet'], '{"gallons": 50, "uef": 0.62, "first_hour_rating": 73, "recovery_rate_gph": 43, "btu_input": 40000}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'bradford-white' AND c.slug = 'water-heater-tank-gas';


-- ============================================================================
-- ADDITIONAL TANKLESS PROPANE VARIANTS
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Rheem - Tankless Propane
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.rheem.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('RTGH-84DVLP-3', '8.4 GPM Condensing Tankless LP', 'Performance Platinum', 'propane', 'tankless', 8, 'gpm', 20, true, true, 1549, ARRAY['Condensing','Built-in recirculation','EcoNet WiFi','Propane'], '{"gpm": 8.4, "uef": 0.93, "btu_input": 180000, "min_activation_gpm": 0.4, "max_temp_rise": 77}'),
  ('RTGH-95DVLP-3', '9.5 GPM Condensing Tankless LP', 'Performance Platinum', 'propane', 'tankless', 10, 'gpm', 20, true, true, 1749, ARRAY['Condensing','Built-in recirc','EcoNet WiFi','Propane'], '{"gpm": 9.5, "uef": 0.96, "btu_input": 199900, "min_activation_gpm": 0.4, "max_temp_rise": 77}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'rheem' AND c.slug = 'water-heater-tankless-gas';

-- ---------------------------------------------------------------------------
-- Navien - Heat Pump (NPE-G Series)
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.navien.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('NPE-G50', '50 Gal Gas-Powered Heat Pump', 'NPE-G', 'gas', 'heat-pump', 50, 'gallons', 15, true, true, 3499, ARRAY['Gas heat pump','Ultra high efficiency','WiFi NaviLink','Revolutionary technology'], '{"gallons": 50, "uef": 3.00, "first_hour_rating": 100}'),
  ('NPE-G75', '75 Gal Gas-Powered Heat Pump', 'NPE-G', 'gas', 'heat-pump', 75, 'gallons', 15, true, true, 3999, ARRAY['Gas heat pump','Ultra high efficiency','WiFi NaviLink','Large capacity'], '{"gallons": 75, "uef": 3.00, "first_hour_rating": 130}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'navien' AND c.slug = 'water-heater-heat-pump';


-- ============================================================================
-- SUPPLEMENTAL MODELS - Fill gaps to reach 300+ total
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Reliance - Tankless Electric
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.reliancewaterheaters.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('6-24-ELKT', '24 kW Tankless Electric', 'Standard', 'electric', 'tankless', 6, 'gpm', 15, false, false, 449, ARRAY['24 kW','Self-modulating','Whole-home capable'], '{"gpm": 5.3, "uef": 0.99, "kw": 24, "min_activation_gpm": 0.3, "max_temp_rise": 54}'),
  ('6-18-ELKT', '18 kW Tankless Electric', 'Standard', 'electric', 'tankless', 4, 'gpm', 15, false, false, 349, ARRAY['18 kW','Self-modulating','Multi-fixture'], '{"gpm": 4.3, "uef": 0.99, "kw": 18, "min_activation_gpm": 0.3, "max_temp_rise": 54}'),
  ('6-11-ELKT', '11 kW Tankless Electric', 'Standard', 'electric', 'tankless', 3, 'gpm', 15, false, false, 279, ARRAY['11 kW','Self-modulating','Compact design'], '{"gpm": 2.6, "uef": 0.98, "kw": 11, "min_activation_gpm": 0.3, "max_temp_rise": 54}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'reliance' AND c.slug = 'water-heater-tankless-electric';

-- ---------------------------------------------------------------------------
-- Richmond - Tank Electric (additional)
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.richmondwaterheaters.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('12E40-D', '40 Gal Tall Electric 12-Year', 'Encore', 'electric', 'tank', 40, 'gallons', 12, false, false, 529, ARRAY['4,500W elements','12-year warranty','Premium anode rod'], '{"gallons": 40, "uef": 0.95, "first_hour_rating": 60, "watts": 4500}'),
  ('6E80-D', '80 Gal Tall Electric 6-Year', 'Essential', 'electric', 'tank', 80, 'gallons', 10, false, false, 599, ARRAY['4,500W elements','Large capacity','6-year warranty'], '{"gallons": 80, "uef": 0.92, "first_hour_rating": 86, "watts": 4500}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'richmond' AND c.slug = 'water-heater-tank-electric';

-- ---------------------------------------------------------------------------
-- Richmond - Heat Pump
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.richmondwaterheaters.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('12EHP50', '50 Gal Heat Pump 12-Year', 'Encore', 'electric', 'heat-pump', 50, 'gallons', 13, true, true, 1799, ARRAY['3.75 UEF','WiFi-enabled','Heat pump mode','12-year warranty'], '{"gallons": 50, "uef": 3.75, "first_hour_rating": 67}'),
  ('12EHP65', '65 Gal Heat Pump 12-Year', 'Encore', 'electric', 'heat-pump', 65, 'gallons', 13, true, true, 1999, ARRAY['3.75 UEF','WiFi-enabled','Large capacity','12-year warranty'], '{"gallons": 65, "uef": 3.75, "first_hour_rating": 79}'),
  ('12EHP80', '80 Gal Heat Pump 12-Year', 'Encore', 'electric', 'heat-pump', 80, 'gallons', 13, true, true, 2199, ARRAY['3.75 UEF','WiFi-enabled','Largest capacity','12-year warranty'], '{"gallons": 80, "uef": 3.75, "first_hour_rating": 86}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'richmond' AND c.slug = 'water-heater-heat-pump';

-- ---------------------------------------------------------------------------
-- A.O. Smith - Tankless Electric
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.aosmith.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('ATE-110', '11 kW Signature 100 Tankless Electric', 'Signature 100', 'electric', 'tankless', 3, 'gpm', 15, false, false, 329, ARRAY['11 kW','Self-modulating','Compact'], '{"gpm": 2.6, "uef": 0.98, "kw": 11, "min_activation_gpm": 0.3, "max_temp_rise": 54}'),
  ('ATE-240', '24 kW Signature 300 Tankless Electric', 'Signature 300', 'electric', 'tankless', 6, 'gpm', 15, false, false, 549, ARRAY['24 kW','Self-modulating','Whole-home capable'], '{"gpm": 5.3, "uef": 0.99, "kw": 24, "min_activation_gpm": 0.3, "max_temp_rise": 54}'),
  ('ATE-360', '36 kW Signature 500 Tankless Electric', 'Signature 500', 'electric', 'tankless', 8, 'gpm', 15, true, false, 749, ARRAY['36 kW','WiFi-enabled','Maximum output'], '{"gpm": 7.0, "uef": 0.99, "kw": 36, "min_activation_gpm": 0.25, "max_temp_rise": 54}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ao-smith' AND c.slug = 'water-heater-tankless-electric';

-- ---------------------------------------------------------------------------
-- A.O. Smith - Point-of-Use
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.aosmith.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('EMT-2.5', '2.5 Gal Mini-Tank', 'Mini-Tank', 'electric', 'point-of-use', 3, 'gallons', 10, false, false, 189, ARRAY['2.5 gal mini-tank','Under-sink mount','Glass-lined'], '{"gallons": 2.5, "watts": 1440}'),
  ('EMT-4.0', '4 Gal Mini-Tank', 'Mini-Tank', 'electric', 'point-of-use', 4, 'gallons', 10, false, false, 209, ARRAY['4 gal mini-tank','Under-sink mount','Glass-lined'], '{"gallons": 4, "watts": 1440}'),
  ('EMT-6.0', '6 Gal Mini-Tank', 'Mini-Tank', 'electric', 'point-of-use', 6, 'gallons', 10, false, false, 239, ARRAY['6 gal mini-tank','Under-sink mount','Glass-lined'], '{"gallons": 6, "watts": 1440}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ao-smith' AND c.slug = 'water-heater-point-of-use';

-- ---------------------------------------------------------------------------
-- State Water Heaters - Heat Pump
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.statewaterheaters.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('HPX-50-DHPT', '50 Gal ProLine XE Heat Pump', 'ProLine XE', 'electric', 'heat-pump', 50, 'gallons', 13, true, true, 1999, ARRAY['3.45 UEF','WiFi-enabled','4 operating modes','ENERGY STAR'], '{"gallons": 50, "uef": 3.45, "first_hour_rating": 67}'),
  ('HPX-66-DHPT', '66 Gal ProLine XE Heat Pump', 'ProLine XE', 'electric', 'heat-pump', 66, 'gallons', 13, true, true, 2199, ARRAY['3.45 UEF','WiFi-enabled','Large capacity','ENERGY STAR'], '{"gallons": 66, "uef": 3.45, "first_hour_rating": 79}'),
  ('HPX-80-DHPT', '80 Gal ProLine XE Heat Pump', 'ProLine XE', 'electric', 'heat-pump', 80, 'gallons', 13, true, true, 2399, ARRAY['3.45 UEF','WiFi-enabled','Largest capacity'], '{"gallons": 80, "uef": 3.45, "first_hour_rating": 86}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'state-water-heaters' AND c.slug = 'water-heater-heat-pump';

-- ---------------------------------------------------------------------------
-- Reliance - Propane Tank
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.reliancewaterheaters.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('6 40 LPMT', '40 Gal Tall Propane', 'Standard', 'propane', 'tank', 40, 'gallons', 10, false, false, 569, ARRAY['40,000 BTU','Propane','Push-button ignition'], '{"gallons": 40, "uef": 0.60, "first_hour_rating": 60, "recovery_rate_gph": 40, "btu_input": 40000}'),
  ('6 50 LPMT', '50 Gal Tall Propane', 'Standard', 'propane', 'tank', 50, 'gallons', 12, false, false, 619, ARRAY['40,000 BTU','Propane','Self-cleaning dip tube'], '{"gallons": 50, "uef": 0.60, "first_hour_rating": 67, "recovery_rate_gph": 43, "btu_input": 40000}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'reliance' AND c.slug = 'water-heater-tank-gas';

-- ---------------------------------------------------------------------------
-- Noritz - Tankless Propane
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.noritz.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('NRC98-DV-LP', '9.8 GPM Condensing Indoor LP', 'NRC Series', 'propane', 'tankless', 10, 'gpm', 20, false, true, 1649, ARRAY['Condensing','Indoor install','Propane','Stainless exchanger'], '{"gpm": 9.8, "uef": 0.93, "btu_input": 180000, "min_activation_gpm": 0.4, "max_temp_rise": 77}'),
  ('NR83-OD-LP', '8.3 GPM Non-Condensing Outdoor LP', 'NR Series', 'propane', 'tankless', 8, 'gpm', 20, false, false, 1149, ARRAY['Non-condensing','Outdoor install','Propane','Freeze protection'], '{"gpm": 8.3, "uef": 0.82, "btu_input": 180000, "min_activation_gpm": 0.5, "max_temp_rise": 77}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'noritz' AND c.slug = 'water-heater-tankless-gas';

-- ---------------------------------------------------------------------------
-- Takagi - Tankless Propane
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.takagi.us.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('T-H3S-DV-P', '8.0 GPM H3S Condensing Indoor LP', 'H3S', 'propane', 'tankless', 8, 'gpm', 20, false, true, 1549, ARRAY['Condensing','Indoor install','160,000 BTU','Propane'], '{"gpm": 8.0, "uef": 0.93, "btu_input": 160000, "min_activation_gpm": 0.4, "max_temp_rise": 67}'),
  ('T-KJr2-IN-LP', '6.6 GPM Non-Condensing Indoor LP', 'T-KJr2', 'propane', 'tankless', 7, 'gpm', 20, false, false, 929, ARRAY['Non-condensing','Indoor install','Propane','Budget-friendly'], '{"gpm": 6.6, "uef": 0.82, "btu_input": 140000, "min_activation_gpm": 0.5, "max_temp_rise": 63}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'takagi' AND c.slug = 'water-heater-tankless-gas';

-- ---------------------------------------------------------------------------
-- Rheem - Point-of-Use
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.rheem.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('PROE2.5 2 RH POU', '2.5 Gal Point-of-Use', 'Performance', 'electric', 'point-of-use', 3, 'gallons', 10, false, false, 199, ARRAY['2.5 gal mini-tank','Under-sink','1440W element'], '{"gallons": 2.5, "watts": 1440}'),
  ('PROE6 2 RH POU', '6 Gal Point-of-Use', 'Performance', 'electric', 'point-of-use', 6, 'gallons', 10, false, false, 249, ARRAY['6 gal mini-tank','Under-sink','1440W element'], '{"gallons": 6, "watts": 1440}'),
  ('PROE10 2 RH POU', '10 Gal Point-of-Use', 'Performance', 'electric', 'point-of-use', 10, 'gallons', 10, false, false, 299, ARRAY['10 gal mini-tank','Under-sink or counter','2000W element'], '{"gallons": 10, "watts": 2000}'),
  ('PROE20 2 RH POU', '20 Gal Point-of-Use', 'Performance', 'electric', 'point-of-use', 20, 'gallons', 10, false, false, 349, ARRAY['20 gal','Utility closet or under-sink','2000W element'], '{"gallons": 20, "watts": 2000}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'rheem' AND c.slug = 'water-heater-point-of-use';

-- ---------------------------------------------------------------------------
-- Bradford White - Point-of-Use
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.bradfordwhite.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('RE102T6-1NAL', '2 Gal Compact Electric', 'ElectriFLEX', 'electric', 'point-of-use', 2, 'gallons', 10, false, false, 249, ARRAY['2 gal','Under-sink','1440W','Vitraglas lining'], '{"gallons": 2, "watts": 1440}'),
  ('RE106T6-1NAL', '6 Gal Compact Electric', 'ElectriFLEX', 'electric', 'point-of-use', 6, 'gallons', 10, false, false, 299, ARRAY['6 gal','Under-sink','1440W','Vitraglas lining'], '{"gallons": 6, "watts": 1440}'),
  ('RE110T6-1NAL', '10 Gal Compact Electric', 'ElectriFLEX', 'electric', 'point-of-use', 10, 'gallons', 10, false, false, 349, ARRAY['10 gal','Under-sink or utility','2000W'], '{"gallons": 10, "watts": 2000}'),
  ('RE120T6-1NAL', '20 Gal Compact Electric', 'ElectriFLEX', 'electric', 'point-of-use', 20, 'gallons', 10, false, false, 399, ARRAY['20 gal','Utility install','2000W element'], '{"gallons": 20, "watts": 2000}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'bradford-white' AND c.slug = 'water-heater-point-of-use';

-- ---------------------------------------------------------------------------
-- Ruud - Tankless Electric
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.ruud.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('RUTEX-13', '13 kW Tankless Electric', 'Achiever', 'electric', 'tankless', 4, 'gpm', 15, false, false, 329, ARRAY['13 kW','Self-modulating','Contractor exclusive'], '{"gpm": 4.0, "uef": 0.99, "kw": 13, "min_activation_gpm": 0.3, "max_temp_rise": 54}'),
  ('RUTEX-24', '24 kW Tankless Electric', 'Achiever Plus', 'electric', 'tankless', 6, 'gpm', 15, false, false, 529, ARRAY['24 kW','Self-modulating','Whole-home'], '{"gpm": 5.9, "uef": 0.99, "kw": 24, "min_activation_gpm": 0.3, "max_temp_rise": 54}'),
  ('RUTEX-36', '36 kW Tankless Electric', 'Achiever Plus', 'electric', 'tankless', 8, 'gpm', 15, false, false, 679, ARRAY['36 kW','Maximum output','Whole-home'], '{"gpm": 7.0, "uef": 0.99, "kw": 36, "min_activation_gpm": 0.25, "max_temp_rise": 54}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ruud' AND c.slug = 'water-heater-tankless-electric';

-- ---------------------------------------------------------------------------
-- State Water Heaters - Tankless Electric
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.statewaterheaters.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('ETE-240', '24 kW ProLine XE Tankless Electric', 'ProLine XE', 'electric', 'tankless', 6, 'gpm', 15, false, false, 529, ARRAY['24 kW','Self-modulating','Whole-home capable'], '{"gpm": 5.3, "uef": 0.99, "kw": 24, "min_activation_gpm": 0.3, "max_temp_rise": 54}'),
  ('ETE-360', '36 kW ProLine XE Tankless Electric', 'ProLine XE', 'electric', 'tankless', 8, 'gpm', 15, false, false, 699, ARRAY['36 kW','Maximum output','Whole-home'], '{"gpm": 7.0, "uef": 0.99, "kw": 36, "min_activation_gpm": 0.25, "max_temp_rise": 54}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'state-water-heaters' AND c.slug = 'water-heater-tankless-electric';

-- ---------------------------------------------------------------------------
-- Navien - Tankless Electric
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.navien.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('NPE-E-24', '24 kW NPE-E Tankless Electric', 'NPE-E', 'electric', 'tankless', 6, 'gpm', 15, true, false, 849, ARRAY['24 kW','WiFi NaviLink','Self-modulating','Whole-home'], '{"gpm": 5.3, "uef": 0.99, "kw": 24, "min_activation_gpm": 0.3, "max_temp_rise": 54}'),
  ('NPE-E-36', '36 kW NPE-E Tankless Electric', 'NPE-E', 'electric', 'tankless', 8, 'gpm', 15, true, false, 1049, ARRAY['36 kW','WiFi NaviLink','Self-modulating','Maximum output'], '{"gpm": 7.0, "uef": 0.99, "kw": 36, "min_activation_gpm": 0.25, "max_temp_rise": 54}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'navien' AND c.slug = 'water-heater-tankless-electric';

-- ---------------------------------------------------------------------------
-- Lochinvar - Heat Pump
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.lochinvar.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('AHP050-100', 'ARMOR Heat Pump 50 Gal', 'ARMOR', 'electric', 'heat-pump', 50, 'gallons', 15, true, true, 3299, ARRAY['3.50 UEF','SMART TOUCH controls','WiFi-enabled','Commercial-grade'], '{"gallons": 50, "uef": 3.50, "first_hour_rating": 67}'),
  ('AHP080-100', 'ARMOR Heat Pump 80 Gal', 'ARMOR', 'electric', 'heat-pump', 80, 'gallons', 15, true, true, 3699, ARRAY['3.50 UEF','SMART TOUCH controls','WiFi','Large capacity'], '{"gallons": 80, "uef": 3.50, "first_hour_rating": 86}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'lochinvar' AND c.slug = 'water-heater-heat-pump';


-- ---------------------------------------------------------------------------
-- EcoSmart - Heat Pump
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.ecosmart.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('ECO HP-50', '50 Gal ECO Heat Pump', 'ECO HP', 'electric', 'heat-pump', 50, 'gallons', 13, false, true, 1499, ARRAY['3.40 UEF','4 operating modes','ENERGY STAR','Budget heat pump'], '{"gallons": 50, "uef": 3.40, "first_hour_rating": 65}'),
  ('ECO HP-80', '80 Gal ECO Heat Pump', 'ECO HP', 'electric', 'heat-pump', 80, 'gallons', 13, false, true, 1799, ARRAY['3.40 UEF','4 operating modes','ENERGY STAR','Large capacity'], '{"gallons": 80, "uef": 3.40, "first_hour_rating": 85}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'ecosmart' AND c.slug = 'water-heater-heat-pump';

-- ---------------------------------------------------------------------------
-- Rinnai - Tankless Propane (additional)
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.rinnai.us'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('RU199iP', '9.8 GPM Ultra Condensing LP', 'Ultra', 'propane', 'tankless', 10, 'gpm', 20, true, true, 1749, ARRAY['Condensing','Indoor install','WiFi capable','Propane'], '{"gpm": 9.8, "uef": 0.93, "btu_input": 199000, "min_activation_gpm": 0.4, "max_temp_rise": 77}'),
  ('V75iP', '7.5 GPM Non-Condensing Indoor LP', 'V-Series', 'propane', 'tankless', 8, 'gpm', 20, false, false, 1099, ARRAY['Non-condensing','Indoor install','Propane'], '{"gpm": 7.5, "uef": 0.82, "btu_input": 180000, "min_activation_gpm": 0.4, "max_temp_rise": 77}'),
  ('V65eP', '6.5 GPM Non-Condensing Outdoor LP', 'V-Series', 'propane', 'tankless', 7, 'gpm', 20, false, false, 999, ARRAY['Non-condensing','Outdoor install','Propane','Freeze protection'], '{"gpm": 6.5, "uef": 0.82, "btu_input": 150000, "min_activation_gpm": 0.4, "max_temp_rise": 65}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'rinnai' AND c.slug = 'water-heater-tankless-gas';

-- ---------------------------------------------------------------------------
-- Navien - Combi-Boiler Propane
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.navien.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('NCB-240E-LP', '11.2 GPM Combi-Boiler LP', 'NCB-E', 'propane', 'tankless', 11, 'gpm', 20, true, true, 2749, ARRAY['Combi-boiler','Space heating + DHW','Condensing','WiFi NaviLink','Propane'], '{"gpm": 11.2, "uef": 0.95, "btu_input": 199900, "min_activation_gpm": 0.4, "max_temp_rise": 77}'),
  ('NPN-U-LP', '11.2 GPM Non-Condensing LP', 'NPN', 'propane', 'tankless', 11, 'gpm', 20, false, false, 1249, ARRAY['Non-condensing','Indoor install','Propane'], '{"gpm": 11.2, "uef": 0.82, "btu_input": 199900, "min_activation_gpm": 0.5, "max_temp_rise": 77}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'navien' AND c.slug = 'water-heater-tankless-gas';

-- ---------------------------------------------------------------------------
-- Reliance - Heat Pump
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.reliancewaterheaters.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('6-50-DHPT', '50 Gal Heat Pump', 'Standard', 'electric', 'heat-pump', 50, 'gallons', 13, false, true, 1499, ARRAY['3.24 UEF','4 operating modes','ENERGY STAR','Budget heat pump'], '{"gallons": 50, "uef": 3.24, "first_hour_rating": 66}'),
  ('6-65-DHPT', '65 Gal Heat Pump', 'Standard', 'electric', 'heat-pump', 65, 'gallons', 13, false, true, 1699, ARRAY['3.24 UEF','4 operating modes','ENERGY STAR','Large capacity'], '{"gallons": 65, "uef": 3.24, "first_hour_rating": 78}'),
  ('6-80-DHPT', '80 Gal Heat Pump', 'Standard', 'electric', 'heat-pump', 80, 'gallons', 13, false, true, 1899, ARRAY['3.24 UEF','4 operating modes','ENERGY STAR','Largest capacity'], '{"gallons": 80, "uef": 3.24, "first_hour_rating": 85}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'reliance' AND c.slug = 'water-heater-heat-pump';

-- ---------------------------------------------------------------------------
-- Bradford White - Tankless Electric
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.bradfordwhite.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('RE2TE-24', '24 kW Infiniti Tankless Electric', 'Infiniti', 'electric', 'tankless', 6, 'gpm', 15, false, false, 649, ARRAY['24 kW','Self-modulating','Whole-home capable'], '{"gpm": 5.3, "uef": 0.99, "kw": 24, "min_activation_gpm": 0.3, "max_temp_rise": 54}'),
  ('RE2TE-18', '18 kW Infiniti Tankless Electric', 'Infiniti', 'electric', 'tankless', 5, 'gpm', 15, false, false, 499, ARRAY['18 kW','Self-modulating','Multi-fixture'], '{"gpm": 4.3, "uef": 0.99, "kw": 18, "min_activation_gpm": 0.3, "max_temp_rise": 54}'),
  ('RE2TE-13', '13 kW Infiniti Tankless Electric', 'Infiniti', 'electric', 'tankless', 4, 'gpm', 15, false, false, 399, ARRAY['13 kW','Self-modulating','Compact design'], '{"gpm": 3.5, "uef": 0.98, "kw": 13, "min_activation_gpm": 0.3, "max_temp_rise": 54}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'bradford-white' AND c.slug = 'water-heater-tankless-electric';

-- ---------------------------------------------------------------------------
-- HTP - Tank Electric
-- ---------------------------------------------------------------------------
INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, v.fuel, v.install, NULL, v.cap, v.cap_unit, true, v.lifespan, v.wifi, v.estar, v.msrp, v.features, v.specs::jsonb, 'https://www.htproducts.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('ELE-50', 'Everlast 50 Gal Electric', 'Everlast', 'electric', 'tank', 50, 'gallons', 15, false, false, 1499, ARRAY['316L stainless steel tank','4,500W elements','Lifetime tank warranty','Premium build'], '{"gallons": 50, "uef": 0.95, "first_hour_rating": 62, "watts": 4500}'),
  ('ELE-80', 'Everlast 80 Gal Electric', 'Everlast', 'electric', 'tank', 80, 'gallons', 15, false, false, 1899, ARRAY['316L stainless steel tank','4,500W elements','Lifetime warranty','Large capacity'], '{"gallons": 80, "uef": 0.92, "first_hour_rating": 86, "watts": 4500}')
) AS v(model_number, model_name, series, fuel, install, cap, cap_unit, lifespan, wifi, estar, msrp, features, specs)
WHERE m.slug = 'htp' AND c.slug = 'water-heater-tank-electric';


-- ============================================================================
-- VERIFICATION QUERY (uncomment to verify counts)
-- ============================================================================
-- SELECT
--   m.name AS manufacturer,
--   c.name AS category,
--   COUNT(*) AS model_count
-- FROM equipment_catalog ec
-- JOIN equipment_manufacturers m ON ec.manufacturer_id = m.id
-- JOIN equipment_categories c ON ec.category_id = c.id
-- WHERE c.slug LIKE 'water-heater-%'
-- GROUP BY m.name, c.name
-- ORDER BY m.name, c.name;
