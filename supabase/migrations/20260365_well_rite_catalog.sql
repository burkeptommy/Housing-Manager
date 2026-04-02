-- Add Well-Rite brand (Amtrol's professional-grade well pressure tank line)
-- and common Well-Rite pressure tank models to the equipment catalog.

INSERT INTO equipment_manufacturers (name, slug, parent_company, country_of_origin, website_url, support_url, support_phone, tier, description)
VALUES (
  'Well-Rite', 'well-rite', 'Amtrol Inc.', 'US',
  'https://www.amtrol.com/well-rite', 'https://www.amtrol.com/support',
  '1-401-884-6300', 'premium',
  'Amtrol professional-grade well pressure tanks. Steel construction with replaceable bladders.'
)
ON CONFLICT (slug) DO NOTHING;

-- Add Well-Rite pressure tank models
INSERT INTO equipment_catalog (
  manufacturer_id, category_id, model_number, model_name, series,
  capacity_value, capacity_unit, expected_lifespan_years, msrp_usd,
  key_features, specs, is_current_model
)
SELECT m.id, c.id, v.model, v.name, v.series,
       v.gallons, 'gallons', v.lifespan, v.msrp,
       v.features, v.specs::jsonb, true
FROM equipment_manufacturers m,
     equipment_categories c,
     (VALUES
       ('WR-60',  'WR-60 Well Pressure Tank 20 Gal',   'WR', 20, 15, 199,
        ARRAY['20-gallon capacity','Pre-charged bladder','Steel construction','NSF/ANSI 61 certified'],
        '{"gallons": 20, "orientation": "vertical", "max_psi": 100, "pre_charge_psi": 38, "connection": "1 inch", "material": "steel", "diameter_inches": 15, "height_inches": 24}'::text),
       ('WR-100', 'WR-100 Well Pressure Tank 32 Gal',  'WR', 32, 15, 269,
        ARRAY['32-gallon capacity','Pre-charged bladder','Steel construction','Replaceable bladder'],
        '{"gallons": 32, "orientation": "vertical", "max_psi": 100, "pre_charge_psi": 38, "connection": "1 inch", "material": "steel", "diameter_inches": 15, "height_inches": 33}'::text),
       ('WR-140', 'WR-140 Well Pressure Tank 44 Gal',  'WR', 44, 15, 349,
        ARRAY['44-gallon capacity','Pre-charged bladder','Steel construction','NSF/ANSI 61'],
        '{"gallons": 44, "orientation": "vertical", "max_psi": 100, "pre_charge_psi": 38, "connection": "1.25 inch", "material": "steel", "diameter_inches": 20, "height_inches": 36}'::text),
       ('WR-200', 'WR-200 Well Pressure Tank 62 Gal',  'WR', 62, 15, 415,
        ARRAY['62-gallon capacity','Pre-charged bladder','Steel construction','Replaceable bladder','NSF/ANSI 61 certified'],
        '{"gallons": 62, "orientation": "vertical", "max_psi": 100, "pre_charge_psi": 38, "connection": "1.25 inch", "material": "steel", "diameter_inches": 20, "height_inches": 49}'::text),
       ('WR-250', 'WR-250 Well Pressure Tank 81 Gal',  'WR', 81, 15, 549,
        ARRAY['81-gallon capacity','Pre-charged bladder','Steel construction','Heavy-duty'],
        '{"gallons": 81, "orientation": "vertical", "max_psi": 100, "pre_charge_psi": 38, "connection": "1.25 inch", "material": "steel", "diameter_inches": 22, "height_inches": 50}'::text),
       ('WR-360', 'WR-360 Well Pressure Tank 119 Gal', 'WR', 119, 15, 749,
        ARRAY['119-gallon capacity','Pre-charged bladder','Steel construction','Commercial grade'],
        '{"gallons": 119, "orientation": "vertical", "max_psi": 100, "pre_charge_psi": 38, "connection": "1.25 inch", "material": "steel", "diameter_inches": 24, "height_inches": 62}'::text)
     ) AS v(model, name, series, gallons, lifespan, msrp, features, specs)
WHERE m.slug = 'well-rite' AND c.slug = 'pressure-tank';
