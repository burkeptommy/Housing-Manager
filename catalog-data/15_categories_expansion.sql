-- ============================================================================
-- Expanded Equipment Categories: HVAC, Water Heaters, Laundry, Generators,
-- Sump Pumps, Well Water Systems, Bathroom Fixtures, Irrigation, Pool Systems
-- ============================================================================

-- ======================== PRIMARY CATEGORIES ========================

INSERT INTO equipment_categories (name, slug, parent_category_id, room, typical_lifespan_years, description) VALUES
-- HVAC
('HVAC', 'hvac', NULL, 'hvac', 15, 'Heating, ventilation, and air conditioning systems'),
-- Water Heaters
('Water Heater', 'water-heater', NULL, 'utility', 12, 'Tank, tankless, and heat pump water heating systems'),
-- Laundry
('Washer', 'washer', NULL, 'laundry', 11, 'Clothes washing machines — front-load, top-load, and compact'),
('Dryer', 'dryer', NULL, 'laundry', 13, 'Clothes dryers — gas, electric, heat pump, and ventless'),
('Washer-Dryer Combo', 'washer-dryer-combo', NULL, 'laundry', 10, 'All-in-one combination washer and dryer units'),
('Garment Care', 'garment-care', NULL, 'laundry', 10, 'Steam closets, fabric refreshers, and specialty garment care appliances'),
-- Generators
('Generator', 'generator', NULL, 'outdoor', 15, 'Portable, inverter, and whole-home standby generators'),
('Power Station', 'power-station', NULL, 'outdoor', 10, 'Battery-based portable power stations with solar capability'),
-- Sump Pumps
('Sump Pump', 'sump-pump', NULL, 'basement', 10, 'Sump pumps, battery backups, and sewage ejectors'),
-- Well Water Systems
('Well Pump', 'well-pump', NULL, 'utility', 12, 'Submersible and jet pumps for residential well water'),
('Pressure Tank', 'pressure-tank', NULL, 'utility', 15, 'Well water pressure tanks and expansion tanks'),
('Water Treatment', 'water-treatment', NULL, 'utility', 12, 'Whole-house water filtration, softeners, UV disinfection, and iron removal'),
-- Bathroom Fixtures
('Toilet', 'toilet', NULL, 'bathroom', 25, 'Floor-mounted, wall-hung, and smart toilets'),
('Bathroom Faucet', 'bathroom-faucet', NULL, 'bathroom', 15, 'Lavatory faucets — single-handle, widespread, and wall-mount'),
('Shower System', 'shower-system', NULL, 'bathroom', 20, 'Showerheads, shower valves, body sprays, and complete shower systems'),
('Bathtub', 'bathtub', NULL, 'bathroom', 25, 'Soaking tubs, freestanding tubs, whirlpool tubs, and air baths'),
('Bidet', 'bidet', NULL, 'bathroom', 15, 'Standalone bidets and bidet toilet seats'),
-- Irrigation
('Irrigation Controller', 'irrigation-controller', NULL, 'outdoor', 10, 'Smart and traditional sprinkler timers and controllers'),
('Sprinkler Head', 'sprinkler-head', NULL, 'outdoor', 8, 'Rotors, spray heads, and drip irrigation components'),
('Backflow Preventer', 'backflow-preventer', NULL, 'outdoor', 20, 'Required backflow prevention devices for irrigation systems'),
-- Pool Systems
('Pool Pump', 'pool-pump', NULL, 'outdoor', 10, 'Variable-speed, single-speed, and dual-speed pool circulation pumps'),
('Pool Filter', 'pool-filter', NULL, 'outdoor', 8, 'Sand, cartridge, and D.E. pool filtration systems'),
('Pool Heater', 'pool-heater', NULL, 'outdoor', 10, 'Gas heaters, heat pumps, and solar pool heating systems'),
('Salt Chlorine Generator', 'salt-chlorine-generator', NULL, 'outdoor', 5, 'Salt water chlorination systems for pools'),
('Pool Cleaner', 'pool-cleaner', NULL, 'outdoor', 5, 'Robotic, suction-side, and pressure-side pool cleaners'),
('Pool Automation', 'pool-automation', NULL, 'outdoor', 12, 'Pool and spa automation control systems');

-- ======================== HVAC SUB-CATEGORIES ========================

INSERT INTO equipment_categories (name, slug, parent_category_id, room, typical_lifespan_years, description)
SELECT sub.name, sub.slug, c.id, 'hvac', sub.lifespan, sub.desc
FROM equipment_categories c,
(VALUES
    ('Central Air Conditioner', 'hvac-central-ac', 15, 'Split-system and packaged central air conditioning units'),
    ('Furnace', 'hvac-furnace', 20, 'Gas, oil, and electric forced-air furnaces'),
    ('Heat Pump', 'hvac-heat-pump', 15, 'Ducted and ductless heat pump systems for heating and cooling'),
    ('Boiler', 'hvac-boiler', 25, 'Gas, oil, and electric boilers for hydronic heating'),
    ('Mini-Split', 'hvac-mini-split', 15, 'Ductless mini-split heat pump and AC systems'),
    ('Air Handler', 'hvac-air-handler', 15, 'Indoor air handler units for split systems'),
    ('Thermostat', 'hvac-thermostat', 10, 'Programmable, smart, and traditional thermostats')
) AS sub(name, slug, lifespan, "desc")
WHERE c.slug = 'hvac';

-- ======================== WATER HEATER SUB-CATEGORIES ========================

INSERT INTO equipment_categories (name, slug, parent_category_id, room, typical_lifespan_years, description)
SELECT sub.name, sub.slug, c.id, 'utility', sub.lifespan, sub.desc
FROM equipment_categories c,
(VALUES
    ('Tank Water Heater (Gas)', 'water-heater-tank-gas', 12, 'Traditional tank-type gas water heaters'),
    ('Tank Water Heater (Electric)', 'water-heater-tank-electric', 12, 'Traditional tank-type electric water heaters'),
    ('Tankless Water Heater (Gas)', 'water-heater-tankless-gas', 20, 'On-demand gas tankless water heaters'),
    ('Tankless Water Heater (Electric)', 'water-heater-tankless-electric', 15, 'On-demand electric tankless water heaters'),
    ('Heat Pump Water Heater', 'water-heater-heat-pump', 13, 'Hybrid heat pump water heaters for energy efficiency'),
    ('Point-of-Use Water Heater', 'water-heater-point-of-use', 10, 'Small under-sink or point-of-use water heaters')
) AS sub(name, slug, lifespan, "desc")
WHERE c.slug = 'water-heater';

-- ======================== WASHER SUB-CATEGORIES ========================

INSERT INTO equipment_categories (name, slug, parent_category_id, room, typical_lifespan_years, description)
SELECT sub.name, sub.slug, c.id, 'laundry', sub.lifespan, sub.desc
FROM equipment_categories c,
(VALUES
    ('Front-Load Washer', 'washer-front-load', 11, 'High-efficiency front-loading washing machines'),
    ('Top-Load Washer (Agitator)', 'washer-top-load-agitator', 12, 'Traditional top-load washers with center agitator'),
    ('Top-Load Washer (Impeller)', 'washer-top-load-impeller', 11, 'High-efficiency top-load washers with impeller plate'),
    ('Compact Washer', 'washer-compact', 10, 'Stackable 24-inch compact washing machines')
) AS sub(name, slug, lifespan, "desc")
WHERE c.slug = 'washer';

-- ======================== DRYER SUB-CATEGORIES ========================

INSERT INTO equipment_categories (name, slug, parent_category_id, room, typical_lifespan_years, description)
SELECT sub.name, sub.slug, c.id, 'laundry', sub.lifespan, sub.desc
FROM equipment_categories c,
(VALUES
    ('Electric Dryer', 'dryer-electric', 13, 'Standard vented electric dryers'),
    ('Gas Dryer', 'dryer-gas', 14, 'Vented gas dryers — lower operating cost'),
    ('Heat Pump Dryer', 'dryer-heat-pump', 13, 'Ventless heat pump dryers — highest efficiency'),
    ('Compact Dryer', 'dryer-compact', 12, 'Stackable 24-inch compact dryers — vented or ventless')
) AS sub(name, slug, lifespan, "desc")
WHERE c.slug = 'dryer';

-- ======================== SUMP PUMP SUB-CATEGORIES ========================

INSERT INTO equipment_categories (name, slug, parent_category_id, room, typical_lifespan_years, description)
SELECT sub.name, sub.slug, c.id, 'basement', sub.lifespan, sub.desc
FROM equipment_categories c,
(VALUES
    ('Submersible Sump Pump', 'sump-pump-submersible', 10, 'Submersible sump pumps installed inside the sump pit'),
    ('Pedestal Sump Pump', 'sump-pump-pedestal', 12, 'Pedestal sump pumps with motor above the pit'),
    ('Battery Backup Sump Pump', 'sump-pump-battery-backup', 5, 'Battery-powered backup sump pump systems'),
    ('Combination Sump Pump', 'sump-pump-combination', 10, 'Primary pump with integrated battery backup'),
    ('Sewage Ejector Pump', 'sump-pump-sewage-ejector', 10, 'Sewage and effluent ejector pumps for below-grade bathrooms')
) AS sub(name, slug, lifespan, "desc")
WHERE c.slug = 'sump-pump';

-- ======================== WATER TREATMENT SUB-CATEGORIES ========================

INSERT INTO equipment_categories (name, slug, parent_category_id, room, typical_lifespan_years, description)
SELECT sub.name, sub.slug, c.id, 'utility', sub.lifespan, sub.desc
FROM equipment_categories c,
(VALUES
    ('Water Softener', 'water-treatment-softener', 15, 'Ion-exchange water softeners for hard water'),
    ('Whole-House Filter', 'water-treatment-whole-house', 10, 'Whole-house sediment, carbon, and multi-stage filtration'),
    ('UV Disinfection', 'water-treatment-uv', 10, 'Ultraviolet water purification systems'),
    ('Iron Filter', 'water-treatment-iron', 12, 'Iron, manganese, and sulfur removal systems'),
    ('Reverse Osmosis', 'water-treatment-ro', 10, 'Under-sink and whole-house reverse osmosis systems')
) AS sub(name, slug, lifespan, "desc")
WHERE c.slug = 'water-treatment';

-- ======================== GENERATOR SUB-CATEGORIES ========================

INSERT INTO equipment_categories (name, slug, parent_category_id, room, typical_lifespan_years, description)
SELECT sub.name, sub.slug, c.id, 'outdoor', sub.lifespan, sub.desc
FROM equipment_categories c,
(VALUES
    ('Portable Generator (Open Frame)', 'generator-portable', 12, 'Open-frame portable generators for jobsite and emergency backup'),
    ('Portable Inverter Generator', 'generator-inverter', 12, 'Quiet, clean-power inverter generators for sensitive electronics'),
    ('Standby Generator (Gas/LP)', 'generator-standby-gas', 20, 'Permanently installed whole-home standby generators — natural gas or LP'),
    ('Standby Generator (Diesel)', 'generator-standby-diesel', 25, 'Diesel-powered standby generators for large loads')
) AS sub(name, slug, lifespan, "desc")
WHERE c.slug = 'generator';
