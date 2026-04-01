-- Add American Standard oil furnaces to the equipment catalog
-- The user's specific model: TLR1M087A9V5S (Oil Low Boy, 100K BTU)

INSERT INTO equipment_catalog (manufacturer_id, category_id, model_number, model_name, series, fuel_type, installation_type, width_inches, capacity_value, capacity_unit, is_current_model, expected_lifespan_years, wifi_enabled, energy_star, msrp_usd, key_features, specs, product_url)
SELECT m.id, c.id, v.model_number, v.model_name, v.series, 'oil', v.install_type, NULL, v.cap, 'btu', true, 25, false, false, v.msrp, v.features, v.specs::jsonb, 'https://www.americanstandardair.com'
FROM equipment_manufacturers m, equipment_categories c,
(VALUES
  ('TLR1M087A9V5S', 'Oil Low Boy 87K BTU Rear Flue', 'Low Boy', 'lowboy', 87000, 2800, ARRAY['Oil-fired','Low boy rear flue','Multi-speed blower','Beckett burner'], '{"btu_input": 87000, "btu_output": 73000, "afue": 83.7, "voltage": 120, "type": "lowboy", "flue": "rear"}'),
  ('TLR1M112A9V5S', 'Oil Low Boy 112K BTU Rear Flue', 'Low Boy', 'lowboy', 112000, 3100, ARRAY['Oil-fired','Low boy rear flue','Multi-speed blower','Beckett burner'], '{"btu_input": 112000, "btu_output": 94000, "afue": 83.7, "voltage": 120, "type": "lowboy", "flue": "rear"}'),
  ('TLR1M140A9V5S', 'Oil Low Boy 140K BTU Rear Flue', 'Low Boy', 'lowboy', 140000, 3400, ARRAY['Oil-fired','Low boy rear flue','Multi-speed blower','Beckett burner'], '{"btu_input": 140000, "btu_output": 117000, "afue": 83.7, "voltage": 120, "type": "lowboy", "flue": "rear"}'),
  ('TUH1B060A9241A', 'Oil Highboy 60K BTU Upflow', 'Highboy', 'upflow', 60000, 2500, ARRAY['Oil-fired','Highboy upflow','Multi-speed blower','Beckett burner'], '{"btu_input": 60000, "btu_output": 50000, "afue": 83.5, "voltage": 120, "type": "highboy", "flue": "top"}'),
  ('TUH1B080A9361A', 'Oil Highboy 80K BTU Upflow', 'Highboy', 'upflow', 80000, 2700, ARRAY['Oil-fired','Highboy upflow','Multi-speed blower','Beckett burner'], '{"btu_input": 80000, "btu_output": 67000, "afue": 83.5, "voltage": 120, "type": "highboy", "flue": "top"}'),
  ('TUH1C100A9V3VA', 'Oil Highboy 100K BTU Upflow', 'Highboy', 'upflow', 100000, 3000, ARRAY['Oil-fired','Highboy upflow','Multi-speed blower','Beckett burner'], '{"btu_input": 100000, "btu_output": 84000, "afue": 83.5, "voltage": 120, "type": "highboy", "flue": "top"}'),
  ('TUH1C120A9V5VA', 'Oil Highboy 120K BTU Upflow', 'Highboy', 'upflow', 120000, 3200, ARRAY['Oil-fired','Highboy upflow','Multi-speed blower','Beckett burner'], '{"btu_input": 120000, "btu_output": 101000, "afue": 83.5, "voltage": 120, "type": "highboy", "flue": "top"}'),
  ('TUH1C140A9V5VA', 'Oil Highboy 140K BTU Upflow', 'Highboy', 'upflow', 140000, 3500, ARRAY['Oil-fired','Highboy upflow','Multi-speed blower','Beckett burner'], '{"btu_input": 140000, "btu_output": 117000, "afue": 83.5, "voltage": 120, "type": "highboy", "flue": "top"}')
) AS v(model_number, model_name, series, install_type, cap, msrp, features, specs)
WHERE m.slug = 'american-standard-hvac' AND c.slug = 'hvac-furnace';
