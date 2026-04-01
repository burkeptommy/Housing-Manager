-- Fix Bosch URL pattern: /supportdetail/product/{MODEL}/01 → /us/en/productservice/{MODEL}-01
-- The supportdetail URL redirects but the productservice URL is the canonical one.

UPDATE equipment_manuals
SET source_url = REPLACE(
  REPLACE(source_url, '/us/supportdetail/product/', '/us/en/productservice/'),
  '/01', '-01'
)
WHERE source_url LIKE '%bosch-home.com/us/supportdetail/product/%';
