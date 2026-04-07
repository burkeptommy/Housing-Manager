-- Phase 15 / FIX A: Seed pool_service and irrigation providers so the
-- House Quiz utility picker has results to show for q12 (pool) and q14
-- (irrigation). Slugs are unique; ON CONFLICT DO NOTHING keeps this
-- migration idempotent if any of these rows already exist.
INSERT INTO utility_providers (name, slug, provider_type, brand_color, website) VALUES
-- Pool service
('Anthony & Sylvan Pools', 'anthony-sylvan-pools', 'pool_service', '#0E4D8C', 'anthonysylvan.com'),
('Pinch A Penny', 'pinch-a-penny', 'pool_service', '#005DAA', 'pinchapenny.com'),
('Leslie''s Pool Supplies', 'leslies-pool-supplies', 'pool_service', '#0072CE', 'lesliespool.com'),
('ASP - America''s Swimming Pool Co', 'asp-pool-co', 'pool_service', '#0066B2', 'aspoolco.com'),
('Premier Pools & Spas', 'premier-pools-spas', 'pool_service', '#1B365D', 'premierpoolsandspas.com'),
('Pentair Pool Solutions', 'pentair-pool', 'pool_service', '#003B71', 'pentair.com'),
('Aqua Pool & Patio', 'aqua-pool-patio', 'pool_service', '#0096D6', 'aquapool.com'),
('Hayward Pool Products', 'hayward-pool', 'pool_service', '#003E7E', 'hayward-pool.com'),
('Blue Haven Pools', 'blue-haven-pools', 'pool_service', '#1F75B7', 'bluehaven.com'),
('California Pools', 'california-pools', 'pool_service', '#005A8B', 'californiapools.com'),
-- Irrigation
('Hunter Industries', 'hunter-industries', 'irrigation', '#1E4F8E', 'hunterindustries.com'),
('Rain Bird', 'rain-bird', 'irrigation', '#0064A8', 'rainbird.com'),
('Toro Sprinkler', 'toro-sprinkler', 'irrigation', '#D8232A', 'toro.com'),
('Conserva Irrigation', 'conserva-irrigation', 'irrigation', '#0E7B3D', 'conservairrigation.com'),
('NaanDanJain', 'naandanjain', 'irrigation', '#1E5BA8', 'naandanjain.com'),
('The Sprinkler Doctor', 'sprinkler-doctor', 'irrigation', '#1E88E5', 'thesprinklerdoctor.com'),
('Aqua-Bright Irrigation', 'aqua-bright-irrigation', 'irrigation', '#0085C7', 'aqua-bright.com'),
('Sprinkler Master Services', 'sprinkler-master', 'irrigation', '#0066A1', 'sprinklermaster.com'),
('Heads Up Sprinkler Systems', 'heads-up-sprinkler', 'irrigation', '#1B5E20', 'headsupsprinklers.com'),
('Conservation Plus', 'conservation-plus-irrigation', 'irrigation', '#2E7D32', 'conservationplus.com')
ON CONFLICT (slug) DO NOTHING;
