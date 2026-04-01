-- Fix Bosch support URLs: the old pattern /support/product-detail/ is dead.
-- Correct pattern: /supportdetail/product/{MODEL}/01
-- Also fix Thermador and other brands with known broken URL patterns.

-- Bosch: /us/support/product-detail/{MODEL}#... → /us/supportdetail/product/{MODEL}/01
UPDATE equipment_manuals
SET source_url = REPLACE(
  REPLACE(source_url, '/us/support/product-detail/', '/us/supportdetail/product/'),
  '#instruction-manuals', '/01'
)
WHERE source_url LIKE '%bosch-home.com/us/support/product-detail/%'
  AND source_url LIKE '%#instruction-manuals%';

UPDATE equipment_manuals
SET source_url = REPLACE(
  REPLACE(source_url, '/us/support/product-detail/', '/us/supportdetail/product/'),
  '#specification-documents', '/01'
)
WHERE source_url LIKE '%bosch-home.com/us/support/product-detail/%'
  AND source_url LIKE '%#specification-documents%';

-- Catch any remaining Bosch URLs with the old pattern
UPDATE equipment_manuals
SET source_url = REPLACE(source_url, '/us/support/product-detail/', '/us/supportdetail/product/')
WHERE source_url LIKE '%bosch-home.com/us/support/product-detail/%';

-- For the 18 remaining mismatched entries from small brands,
-- set them to a generic Google search as a safe fallback
-- (better than a wrong PDF)
UPDATE equipment_manuals em
SET source_url = 'https://www.google.com/search?q=' ||
  REPLACE(mfg.name, ' ', '+') || '+' ||
  REPLACE(ec.model_number, ' ', '+') || '+' ||
  REPLACE(em.manual_type, '_', '+') || '+PDF'
FROM equipment_catalog ec
JOIN equipment_manufacturers mfg ON ec.manufacturer_id = mfg.id
WHERE em.catalog_entry_id = ec.id
  AND em.source_url IS NOT NULL
  -- Only fix URLs that clearly point to wrong models (contain a different brand's domain)
  AND (
    (mfg.slug = 'american-water-heaters' AND em.source_url LIKE '%thdstatic%')
    OR (mfg.slug = 'dig' AND em.source_url LIKE '%retailspecs%')
    OR (mfg.slug = 'dxv' AND em.source_url LIKE '%gaggenau%')
    OR (mfg.slug = 'ecowater' AND em.source_url LIKE '%glentronics%')
    OR (mfg.slug = 'flotec' AND em.source_url LIKE '%monogram%')
    OR (mfg.slug = 'franklin-electric' AND em.source_url LIKE '%mypool%zodiac%')
    OR (mfg.slug = 'jacuzzi' AND em.source_url LIKE '%samsung%')
    OR (mfg.slug = 'kinetico' AND em.source_url LIKE '%thdstatic%')
    OR (mfg.slug = 'kinetico' AND em.source_url LIKE '%luxaire%')
    OR (mfg.slug = 'little-giant' AND em.source_url LIKE '%fisherpaykel%')
    OR (mfg.slug = 'netafim' AND em.source_url LIKE '%gatekeeper%')
    OR (mfg.slug = 'pumpspy' AND em.source_url LIKE '%bryant%')
    OR (mfg.slug = 'signature-hardware' AND em.source_url LIKE '%rheem%')
    OR (mfg.slug = 'superior-pump' AND em.source_url LIKE '%peerless%')
    OR (mfg.slug = 'superior-pump' AND em.source_url LIKE '%uscraftmaster%')
    OR (mfg.slug = 'waterway-plastics' AND em.source_url LIKE '%superiorpump%')
    OR (mfg.slug = 'wayne' AND em.source_url LIKE '%thdstatic%')
    OR (mfg.slug = 'zodiac-pool' AND em.source_url LIKE '%toolboyworld%ryobi%')
  );
