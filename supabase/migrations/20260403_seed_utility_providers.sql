-- Seed additional utility providers: propane/fuel, pest control, landscaping, water
INSERT INTO utility_providers (name, slug, provider_type, brand_color, website) VALUES
-- Propane / Fuel Oil
('Hocon Gas', 'hocon-gas', 'propane', '#D4272A', 'hocongas.com'),
('Suburban Propane', 'suburban-propane', 'propane', '#e41e2d', 'suburbanpropane.com'),
('AmeriGas', 'amerigas', 'propane', '#1e4ca1', 'amerigas.com'),
('Ferrellgas', 'ferrellgas', 'propane', '#00599b', 'ferrellgas.com'),
('Petro Home Services', 'petro-home', 'oil', '#fdb924', 'petro.com'),
('Sippin Energy', 'sippin-energy', 'propane', '#1B3A5C', 'sippinenergy.com'),
('Santa Energy', 'santa-energy', 'propane', '#C94435', 'santaenergy.com'),
('Shipley Energy', 'shipley-energy', 'oil', '#2E7D6D', 'shipleyenergy.com'),
('Paraco Gas', 'paraco-gas', 'propane', '#005DAA', 'paracogas.com'),
('Blue Flame Gas', 'blue-flame-gas', 'propane', '#2A5DB0', 'blueflamegas.com'),
('Kamps Propane', 'kamps-propane', 'propane', '#D4693B', 'kampspropane.com'),
('Blossman Gas', 'blossman-gas', 'propane', '#004B87', 'blossmangas.com'),
('Thompson Gas', 'thompson-gas', 'propane', '#8B5E3C', 'thompsongas.com'),
('Crystal Flash', 'crystal-flash', 'propane', '#C47D2A', 'crystalflash.com'),
('Lakes Gas', 'lakes-gas', 'propane', '#3B7DD8', 'lakesgas.com'),
-- Pest Control
('Terminix', 'terminix', 'pest_control', '#1B365D', 'terminix.com'),
('Orkin', 'orkin', 'pest_control', '#CC0000', 'orkin.com'),
('Truly Nolen', 'truly-nolen', 'pest_control', '#FFD700', 'trulynolen.com'),
('ABC Home & Commercial', 'abc-home-commercial', 'pest_control', '#0067B1', 'abchomeandcommercial.com'),
('HomeTeam Pest Defense', 'hometeam-pest', 'pest_control', '#2D8C3C', 'pestdefense.com'),
('Aptive Environmental', 'aptive', 'pest_control', '#00B386', 'goaptive.com'),
('Turner Pest Control', 'turner-pest', 'pest_control', '#4D7B9A', 'turnerpest.com'),
('Hawx Pest Control', 'hawx-pest', 'pest_control', '#5B4FA0', 'hawxpestcontrol.com'),
-- Landscaping
('TruGreen', 'trugreen', 'landscaping', '#00873E', 'trugreen.com'),
('Lawn Doctor', 'lawn-doctor', 'landscaping', '#417505', 'lawndoctor.com'),
('Weed Man', 'weed-man', 'landscaping', '#2D8C3C', 'weedman.com'),
('Spring-Green', 'spring-green', 'landscaping', '#5CA632', 'spring-green.com'),
('SavATree', 'savatree', 'landscaping', '#3A6B35', 'savatree.com'),
('Bartlett Tree Experts', 'bartlett-tree', 'landscaping', '#1B5E20', 'bartlett.com'),
-- Water / Sewer (Regional)
('Aquarion Water', 'aquarion', 'water', '#00457c', 'aquarionwater.com'),
('American Water', 'american-water', 'water', '#2fa2fb', 'amwater.com'),
('South Central CT Regional Water', 'south-central-ct-water', 'water', '#005A9C', 'rfrwa.com'),
('Birmingham Utilities', 'birmingham-utilities', 'water', '#4D7B9A', 'birminghamutilities.com')
ON CONFLICT (slug) DO NOTHING;
