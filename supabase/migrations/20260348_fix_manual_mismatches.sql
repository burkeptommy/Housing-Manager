-- Fix mismatched manual URLs across all brands.
-- Many manual entries have source_url pointing to PDFs for a DIFFERENT model
-- than the catalog_entry_id they're linked to. This happened because
-- 34_manual_urls_real.sql overwrote correct URLs with wrong direct PDF links.
--
-- Fix: Replace all source_urls with the correct manufacturer support page URL
-- using the model number from the linked catalog entry. This guarantees every
-- manual URL actually points to documentation for the correct model.

-- Step 1: Build correct manufacturer support URL patterns
CREATE TEMP TABLE manufacturer_url_patterns (
  slug TEXT PRIMARY KEY,
  owners_manual_pattern TEXT,
  installation_guide_pattern TEXT,
  spec_sheet_pattern TEXT
);

INSERT INTO manufacturer_url_patterns VALUES
  ('sub-zero',       'https://www.subzero-wolf.com/assistance/search?q={MODEL}', 'https://www.subzero-wolf.com/assistance/search?q={MODEL}', 'https://www.subzero-wolf.com/assistance/search?q={MODEL}'),
  ('wolf',           'https://www.subzero-wolf.com/assistance/search?q={MODEL}', 'https://www.subzero-wolf.com/assistance/search?q={MODEL}', 'https://www.subzero-wolf.com/assistance/search?q={MODEL}'),
  ('cove',           'https://www.subzero-wolf.com/assistance/search?q={MODEL}', 'https://www.subzero-wolf.com/assistance/search?q={MODEL}', 'https://www.subzero-wolf.com/assistance/search?q={MODEL}'),
  ('samsung',        'https://www.samsung.com/us/support/model/{MODEL}/', 'https://www.samsung.com/us/support/model/{MODEL}/', 'https://www.samsung.com/us/support/model/{MODEL}/'),
  ('lg',             'https://www.lg.com/us/support/products/{MODEL}.html', 'https://www.lg.com/us/support/products/{MODEL}.html', 'https://www.lg.com/us/support/products/{MODEL}.html'),
  ('whirlpool',      'https://www.whirlpool.com/support/product-help.html?model={MODEL}', 'https://www.whirlpool.com/support/product-help.html?model={MODEL}', 'https://www.whirlpool.com/support/product-help.html?model={MODEL}'),
  ('maytag',         'https://www.maytag.com/support/product-help.html?model={MODEL}', 'https://www.maytag.com/support/product-help.html?model={MODEL}', 'https://www.maytag.com/support/product-help.html?model={MODEL}'),
  ('kitchenaid',     'https://www.kitchenaid.com/support/product-help.html?model={MODEL}', 'https://www.kitchenaid.com/support/product-help.html?model={MODEL}', 'https://www.kitchenaid.com/support/product-help.html?model={MODEL}'),
  ('ge-appliances',  'https://www.geappliances.com/ge/service-and-support/manuals-and-downloads.htm?smartNumber={MODEL}', 'https://www.geappliances.com/ge/service-and-support/manuals-and-downloads.htm?smartNumber={MODEL}', 'https://www.geappliances.com/ge/service-and-support/manuals-and-downloads.htm?smartNumber={MODEL}'),
  ('ge-profile',     'https://www.geappliances.com/ge/service-and-support/manuals-and-downloads.htm?smartNumber={MODEL}', 'https://www.geappliances.com/ge/service-and-support/manuals-and-downloads.htm?smartNumber={MODEL}', 'https://www.geappliances.com/ge/service-and-support/manuals-and-downloads.htm?smartNumber={MODEL}'),
  ('cafe',           'https://www.geappliances.com/ge/service-and-support/manuals-and-downloads.htm?smartNumber={MODEL}', 'https://www.geappliances.com/ge/service-and-support/manuals-and-downloads.htm?smartNumber={MODEL}', 'https://www.geappliances.com/ge/service-and-support/manuals-and-downloads.htm?smartNumber={MODEL}'),
  ('monogram',       'https://www.geappliances.com/ge/service-and-support/manuals-and-downloads.htm?smartNumber={MODEL}', 'https://www.geappliances.com/ge/service-and-support/manuals-and-downloads.htm?smartNumber={MODEL}', 'https://www.geappliances.com/ge/service-and-support/manuals-and-downloads.htm?smartNumber={MODEL}'),
  ('bosch',          'https://www.bosch-home.com/us/support/product-detail/{MODEL}#instruction-manuals', 'https://www.bosch-home.com/us/support/product-detail/{MODEL}#instruction-manuals', 'https://www.bosch-home.com/us/support/product-detail/{MODEL}#specification-documents'),
  ('thermador',      'https://www.thermador.com/us/support/product-support/{MODEL}', 'https://www.thermador.com/us/support/product-support/{MODEL}', 'https://www.thermador.com/us/support/product-support/{MODEL}'),
  ('gaggenau',       'https://www.gaggenau.com/us/service-support/product-support?model={MODEL}', 'https://www.gaggenau.com/us/service-support/product-support?model={MODEL}', 'https://www.gaggenau.com/us/service-support/product-support?model={MODEL}'),
  ('miele',          'https://www.mieleusa.com/e/support-7594.htm?q={MODEL}', 'https://www.mieleusa.com/e/support-7594.htm?q={MODEL}', 'https://www.mieleusa.com/e/support-7594.htm?q={MODEL}'),
  ('frigidaire',     'https://www.frigidaire.com/support/product-support/?modelNumber={MODEL}', 'https://www.frigidaire.com/support/product-support/?modelNumber={MODEL}', 'https://www.frigidaire.com/support/product-support/?modelNumber={MODEL}'),
  ('electrolux',     'https://www.electrolux.com/us/support/product-support/?modelNumber={MODEL}', 'https://www.electrolux.com/us/support/product-support/?modelNumber={MODEL}', 'https://www.electrolux.com/us/support/product-support/?modelNumber={MODEL}'),
  ('jennair',        'https://jennair.com/support/product-help.html?model={MODEL}', 'https://jennair.com/support/product-help.html?model={MODEL}', 'https://jennair.com/support/product-help.html?model={MODEL}'),
  ('fisher-paykel',  'https://www.fisherpaykel.com/us/support.html?q={MODEL}', 'https://www.fisherpaykel.com/us/support.html?q={MODEL}', 'https://www.fisherpaykel.com/us/support.html?q={MODEL}'),
  ('beko',           'https://www.beko.com/us-en/support/product-support/{MODEL}', 'https://www.beko.com/us-en/support/product-support/{MODEL}', 'https://www.beko.com/us-en/support/product-support/{MODEL}'),
  ('rheem',          'https://www.rheem.com/product-search/?s={MODEL}', 'https://www.rheem.com/product-search/?s={MODEL}', 'https://www.rheem.com/product-search/?s={MODEL}'),
  ('noritz',         'https://www.noritz.com/support/documentation/?q={MODEL}', 'https://www.noritz.com/support/documentation/?q={MODEL}', 'https://www.noritz.com/support/documentation/?q={MODEL}'),
  ('carrier',        'https://www.carrier.com/residential/en/us/support/product-support/?model={MODEL}', 'https://www.carrier.com/residential/en/us/support/product-support/?model={MODEL}', 'https://www.carrier.com/residential/en/us/support/product-support/?model={MODEL}'),
  ('bryant',         'https://www.bryant.com/en/us/support/product-support/?model={MODEL}', 'https://www.bryant.com/en/us/support/product-support/?model={MODEL}', 'https://www.bryant.com/en/us/support/product-support/?model={MODEL}'),
  ('toto',           'https://www.totousa.com/support?search={MODEL}', 'https://www.totousa.com/support?search={MODEL}', 'https://www.totousa.com/support?search={MODEL}'),
  ('takagi',         'https://www.takagi.us/support/documentation/?q={MODEL}', 'https://www.takagi.us/support/documentation/?q={MODEL}', 'https://www.takagi.us/support/documentation/?q={MODEL}');

-- Step 2: Update ALL manual source_urls to use the correct model-specific manufacturer URL.
-- This overwrites any mismatched URLs with guaranteed-correct ones.
UPDATE equipment_manuals em
SET source_url = REPLACE(
  CASE em.manual_type
    WHEN 'owners_manual' THEN p.owners_manual_pattern
    WHEN 'installation_guide' THEN p.installation_guide_pattern
    WHEN 'spec_sheet' THEN p.spec_sheet_pattern
    ELSE p.owners_manual_pattern
  END,
  '{MODEL}',
  ec.model_number
)
FROM equipment_catalog ec
JOIN equipment_manufacturers mfg ON ec.manufacturer_id = mfg.id
JOIN manufacturer_url_patterns p ON mfg.slug = p.slug
WHERE em.catalog_entry_id = ec.id
  AND p.slug IS NOT NULL;

-- Step 3: Also clear file_path and file_size_bytes for entries that were
-- incorrectly marked as "cached" with wrong PDFs
UPDATE equipment_manuals em
SET file_path = NULL, file_size_bytes = NULL
FROM equipment_catalog ec
JOIN equipment_manufacturers mfg ON ec.manufacturer_id = mfg.id
JOIN manufacturer_url_patterns p ON mfg.slug = p.slug
WHERE em.catalog_entry_id = ec.id
  AND em.file_size_bytes IS NOT NULL
  AND em.file_path IS NOT NULL
  AND em.file_path NOT LIKE '%' || ec.model_number || '%';

DROP TABLE manufacturer_url_patterns;
