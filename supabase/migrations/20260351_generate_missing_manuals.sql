-- Generate manual entries for all catalog products that don't have any.
-- Uses manufacturer-specific support URL patterns.

CREATE TEMP TABLE mfg_support_urls (
  slug TEXT PRIMARY KEY,
  url_pattern TEXT
);

INSERT INTO mfg_support_urls (slug, url_pattern) VALUES
  ('bosch',          'https://www.bosch-home.com/us/en/productservice/{MODEL}-01'),
  ('samsung',        'https://www.samsung.com/us/support/model/{MODEL}/'),
  ('lg',             'https://www.lg.com/us/support/products/{MODEL}.html'),
  ('whirlpool',      'https://www.whirlpool.com/support/product-help.html?model={MODEL}'),
  ('maytag',         'https://www.maytag.com/support/product-help.html?model={MODEL}'),
  ('kitchenaid',     'https://www.kitchenaid.com/support/product-help.html?model={MODEL}'),
  ('amana',          'https://www.amana.com/support/product-help.html?model={MODEL}'),
  ('jennair',        'https://jennair.com/support/product-help.html?model={MODEL}'),
  ('ge-appliances',  'https://www.geappliances.com/ge/service-and-support/manuals-and-downloads.htm?smartNumber={MODEL}'),
  ('ge-profile',     'https://www.geappliances.com/ge/service-and-support/manuals-and-downloads.htm?smartNumber={MODEL}'),
  ('cafe',           'https://www.geappliances.com/ge/service-and-support/manuals-and-downloads.htm?smartNumber={MODEL}'),
  ('monogram',       'https://www.geappliances.com/ge/service-and-support/manuals-and-downloads.htm?smartNumber={MODEL}'),
  ('hotpoint',       'https://www.geappliances.com/ge/service-and-support/manuals-and-downloads.htm?smartNumber={MODEL}'),
  ('thermador',      'https://www.thermador.com/us/support/product-support/{MODEL}'),
  ('gaggenau',       'https://www.gaggenau.com/us/service-support/product-support?model={MODEL}'),
  ('miele',          'https://www.mieleusa.com/e/support-7594.htm?q={MODEL}'),
  ('frigidaire',     'https://www.frigidaire.com/support/product-support/?modelNumber={MODEL}'),
  ('electrolux',     'https://www.electrolux.com/us/support/product-support/?modelNumber={MODEL}'),
  ('sub-zero',       'https://www.subzero-wolf.com/assistance/search?q={MODEL}'),
  ('wolf',           'https://www.subzero-wolf.com/assistance/search?q={MODEL}'),
  ('cove',           'https://www.subzero-wolf.com/assistance/search?q={MODEL}'),
  ('fisher-paykel',  'https://www.fisherpaykel.com/us/support.html?q={MODEL}'),
  ('beko',           'https://www.beko.com/us-en/support/product-support/{MODEL}'),
  ('dacor',          'https://www.dacor.com/support/product-support/{MODEL}'),
  ('viking',         'https://www.vikingrange.com/support/{MODEL}'),
  ('carrier',        'https://www.carrier.com/residential/en/us/for-owners/find-a-manual/?modelNumber={MODEL}'),
  ('trane',          'https://www.trane.com/residential/en/resources/library/?search={MODEL}'),
  ('lennox',         'https://www.lennox.com/support/find-manuals?modelNumber={MODEL}'),
  ('rheem',          'https://www.rheem.com/product-search/?s={MODEL}'),
  ('ruud',           'https://www.ruud.com/product-search/?s={MODEL}'),
  ('goodman',        'https://www.goodmanmfg.com/resources/document-library?search={MODEL}'),
  ('bryant',         'https://www.bryant.com/en/us/for-owners/find-a-manual/?modelNumber={MODEL}'),
  ('daikin',         'https://www.daikin.com/global_search/search?q={MODEL}'),
  ('american-standard', 'https://www.americanstandard.com/support/product-support?model={MODEL}'),
  ('american-standard-hvac', 'https://www.americanstandardair.com/support?modelNumber={MODEL}'),
  ('navien',         'https://www.navien.com/us/support/documentation/?q={MODEL}'),
  ('rinnai',         'https://www.rinnai.us/support/product-support?model={MODEL}'),
  ('noritz',         'https://www.noritz.com/support/documentation/?q={MODEL}'),
  ('ao-smith',       'https://www.hotwater.com/support/product-support/?modelNumber={MODEL}'),
  ('bradford-white',  'https://www.bradfordwhite.com/for-the-pro/literature-library/?q={MODEL}'),
  ('kohler',         'https://www.kohler.com/en/support/product-support?modelNumber={MODEL}'),
  ('toto',           'https://www.totousa.com/support?search={MODEL}'),
  ('moen',           'https://www.moen.com/support/find-your-product?model={MODEL}'),
  ('delta-faucet',   'https://www.deltafaucet.com/service-parts/find-your-product?model={MODEL}'),
  ('grohe',          'https://www.grohe.us/support/product-support?model={MODEL}'),
  ('hansgrohe',      'https://www.hansgrohe-usa.com/service/support?q={MODEL}'),
  ('generac',        'https://www.generac.com/service-support/product-support-lookup?modelNumber={MODEL}'),
  ('hayward',        'https://www.hayward-pool.com/support/search?q={MODEL}'),
  ('pentair',        'https://www.pentair.com/en-us/support.html?q={MODEL}'),
  ('speed-queen',    'https://www.speedqueen.com/support/product-support/?model={MODEL}'),
  ('kenmore',        'https://www.kenmore.com/support/?model={MODEL}'),
  ('hisense',        'https://www.hisense-usa.com/support/product-support?model={MODEL}');

-- Insert owners_manual for every product that doesn't have one
INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, language)
SELECT ec.id, 'owners_manual', 'Owners Manual',
  REPLACE(mu.url_pattern, '{MODEL}', ec.model_number), 'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN mfg_support_urls mu ON em.slug = mu.slug
WHERE NOT EXISTS (
  SELECT 1 FROM equipment_manuals m
  WHERE m.catalog_entry_id = ec.id AND m.manual_type = 'owners_manual'
);

-- Insert spec_sheet for every product that doesn't have one
INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, language)
SELECT ec.id, 'spec_sheet', 'Spec Sheet',
  REPLACE(mu.url_pattern, '{MODEL}', ec.model_number), 'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN mfg_support_urls mu ON em.slug = mu.slug
WHERE NOT EXISTS (
  SELECT 1 FROM equipment_manuals m
  WHERE m.catalog_entry_id = ec.id AND m.manual_type = 'spec_sheet'
);

DROP TABLE mfg_support_urls;
