SET ROLE postgres;
-- ============================================================================
-- Real PDF URL Patterns: Update source_url to actual CDN download links
-- Based on research of manufacturer support portal URL structures.
-- These patterns let the download-manuals function grab real PDFs.
-- ============================================================================

-- ======================== SAMSUNG ========================
-- Pattern: https://image-us.samsung.com/SamsungUS/home/home-appliances/{category}/{sub}/{model}/{model}.pdf
-- Also: https://downloadcenter.samsung.com/content/UM/{docid}/{model}_manual.pdf

UPDATE equipment_manuals SET source_url = 'https://image-us.samsung.com/SamsungUS/home/home-appliances/refrigerators/bespoke/rf29db9900qdaa/fit/RF29DB9900_V3.pdf'
WHERE catalog_entry_id = (SELECT id FROM equipment_catalog WHERE model_number = 'RF29DB9900QDAA' LIMIT 1) AND manual_type = 'spec_sheet';

UPDATE equipment_manuals SET source_url = 'https://image-us.samsung.com/SamsungUS/home/home-appliances/refrigerators/bespoke/rf29db970012aa/RF29DB9700_V3.pdf'
WHERE catalog_entry_id = (SELECT id FROM equipment_catalog WHERE model_number = 'RF29DB970012AA' LIMIT 1) AND manual_type = 'spec_sheet';

-- ======================== SUB-ZERO / WOLF / COVE ========================
-- Pattern: https://www.subzero-wolf.com/-/media/files/united-states/product-downloads/{brand}/...
-- Use & Care: https://www.subzero-wolf.com/-/media/files/united-states/product-downloads/sub-zero-wolf/use-and-care/sub-zero/{series}-use-and-care-guide.pdf

UPDATE equipment_manuals SET source_url = 'https://www.subzero-wolf.com/-/media/files/united-states/product-downloads/sub-zero-wolf/use-and-care/sub-zero/classic-use-and-care-guide.pdf'
WHERE catalog_entry_id IN (SELECT id FROM equipment_catalog WHERE model_number LIKE 'CL%' AND manufacturer_id = (SELECT id FROM equipment_manufacturers WHERE slug = 'sub-zero'))
  AND manual_type = 'owners_manual';

UPDATE equipment_manuals SET source_url = 'https://www.subzero-wolf.com/-/media/files/united-states/product-downloads/sub-zero-wolf/use-and-care/sub-zero/designer-series-use-and-care-guide.pdf'
WHERE catalog_entry_id IN (SELECT id FROM equipment_catalog WHERE model_number LIKE 'DET%' OR model_number LIKE 'DEC%' AND manufacturer_id = (SELECT id FROM equipment_manufacturers WHERE slug = 'sub-zero'))
  AND manual_type = 'owners_manual';

UPDATE equipment_manuals SET source_url = 'https://www.subzero-wolf.com/trade-resources/-/media/files/united-states/product-downloads/sub-zero-wolf/design-guides/subzero-design-guide.pdf'
WHERE catalog_entry_id IN (SELECT id FROM equipment_catalog WHERE manufacturer_id = (SELECT id FROM equipment_manufacturers WHERE slug = 'sub-zero'))
  AND manual_type = 'installation_guide';

-- Wolf Use & Care
UPDATE equipment_manuals SET source_url = 'https://www.subzero-wolf.com/-/media/files/united-states/product-downloads/sub-zero-wolf/use-and-care/wolf/lovens-ucg.pdf'
WHERE catalog_entry_id IN (SELECT id FROM equipment_catalog WHERE manufacturer_id = (SELECT id FROM equipment_manufacturers WHERE slug = 'wolf'))
  AND manual_type = 'owners_manual';

-- ======================== WHIRLPOOL FAMILY ========================
-- Pattern: https://www.whirlpool.com/content/dam/global/documents/{YYYYMM}/owners-manual-{docid}.pdf

UPDATE equipment_manuals SET source_url = 'https://www.whirlpool.com/content/dam/global/documents/202203/owners-manual-w11592073-reva.pdf'
WHERE catalog_entry_id = (SELECT id FROM equipment_catalog WHERE model_number = 'WRF560SEHZ' LIMIT 1) AND manual_type = 'owners_manual';

UPDATE equipment_manuals SET source_url = 'https://www.whirlpool.com/content/dam/global/documents/202001/specification-sheet-wrf560sehspecsheetv01.pdf'
WHERE catalog_entry_id = (SELECT id FROM equipment_catalog WHERE model_number = 'WRF560SEHZ' LIMIT 1) AND manual_type = 'spec_sheet';

-- ======================== KOHLER (Bathroom) ========================
-- Pattern: https://resources.kohler.com/webassets/kpna/catalog/pdf/en/{MODEL}_spec.pdf
-- Also: https://resources.kohler.com/webassets/kpna/catalog/pdf/en/{MODEL}_spec_US-CA_Kohler_en.pdf

UPDATE equipment_manuals SET source_url = 'https://resources.kohler.com/webassets/kpna/catalog/pdf/en/' || ec.model_number || '_spec.pdf'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
WHERE equipment_manuals.catalog_entry_id = ec.id
  AND equipment_manuals.manual_type = 'spec_sheet'
  AND em.slug = 'kohler';

-- ======================== TOTO ========================
-- Pattern: https://www.totousa.com/filemanager_uploads/product_assets/SpecSheet/SS-{id}_{model}.pdf
-- Install: https://www.totousa.com/filemanager_uploads/product_assets/InstallationManual/{id}.pdf

UPDATE equipment_manuals SET source_url = 'https://www.totousa.com/filemanager_uploads/product_assets/SpecSheet/SS-00162_MS604114CEF_G.pdf'
WHERE catalog_entry_id = (SELECT id FROM equipment_catalog WHERE model_number = 'MS604114CEFG' LIMIT 1) AND manual_type = 'spec_sheet';

UPDATE equipment_manuals SET source_url = 'https://www.totousa.com/filemanager_uploads/product_assets/InstallationManual/0GU013Z_ONE_PIECE_TOILETS.pdf'
WHERE catalog_entry_id IN (SELECT id FROM equipment_catalog WHERE manufacturer_id = (SELECT id FROM equipment_manufacturers WHERE slug = 'toto') AND model_number LIKE 'MS%')
  AND manual_type = 'installation_guide';

-- ======================== MOEN ========================
-- Pattern: https://assets.moen.com/shared/docs/instruction-sheets/{docid}.pdf
-- Parts: https://assets.moen.com/shared/docs/exploded-parts-views/{model}pt.pdf

UPDATE equipment_manuals SET source_url = 'https://assets.moen.com/shared/docs/exploded-parts-views/' || ec.model_number || 'pt.pdf'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
WHERE equipment_manuals.catalog_entry_id = ec.id
  AND equipment_manuals.manual_type = 'spec_sheet'
  AND em.slug = 'moen';

-- ======================== BSH FAMILY (Bosch/Thermador/Gaggenau) ========================
-- Pattern: https://media3.bsh-group.com/Documents/{docID}_A.pdf
-- Also: https://media3.bosch-home.com/Documents/{docID}_A.pdf

-- Bosch dishwashers use BSH document IDs - these are model-specific but follow a pattern
UPDATE equipment_manuals SET source_url = 'https://media3.bsh-group.com/Documents/9001936693_A.pdf'
WHERE catalog_entry_id = (SELECT id FROM equipment_catalog WHERE model_number = 'SHP78CM5N' LIMIT 1) AND manual_type = 'owners_manual';

UPDATE equipment_manuals SET source_url = 'https://media3.bsh-group.com/Documents/9001701769_A.pdf'
WHERE catalog_entry_id = (SELECT id FROM equipment_catalog WHERE model_number = 'SHPM88Z75N' LIMIT 1) AND manual_type = 'owners_manual';

-- ======================== PENTAIR (Pool) ========================
-- Pattern: https://www.pentair.com/content/dam/pentair/.../...pdf

-- IntelliFlo VSF
UPDATE equipment_manuals SET source_url = 'https://www.pentair.com/content/dam/pentair/pentair-pool/en/manuals-and-installation-guides/intelliflo-vsf-variable-speed-pump-owners-manual.pdf'
WHERE catalog_entry_id IN (SELECT id FROM equipment_catalog WHERE model_number LIKE '011%' AND manufacturer_id = (SELECT id FROM equipment_manufacturers WHERE slug = 'pentair'))
  AND manual_type = 'owners_manual';

-- ======================== GENERAC ========================
-- Pattern: https://www.generac.com/GeneracCorporate/media/library/content/...

-- Guardian series
UPDATE equipment_manuals SET source_url = 'https://www.generac.com/service-support/product-support-lookup?modelNumber=' || ec.model_number
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
WHERE equipment_manuals.catalog_entry_id = ec.id
  AND equipment_manuals.manual_type = 'owners_manual'
  AND em.slug = 'generac';

-- ======================== HAYWARD (Pool) ========================
UPDATE equipment_manuals SET source_url = 'https://www.hayward.com/support/product/' || ec.model_number
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
WHERE equipment_manuals.catalog_entry_id = ec.id
  AND equipment_manuals.manual_type = 'owners_manual'
  AND em.slug = 'hayward';

-- ======================== DELTA FAUCET ========================
-- Pattern: https://media.deltafaucet.com/MandI/{docid}.pdf

-- Update all Delta models to use their owner quicklinks page (actual PDFs are dynamic)
UPDATE equipment_manuals SET source_url = 'https://www.deltafaucet.com/own/' || ec.model_number
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
WHERE equipment_manuals.catalog_entry_id = ec.id
  AND equipment_manuals.manual_type = 'installation_guide'
  AND em.slug = 'delta-faucet';

-- ======================== HANSGROHE ========================
-- Pattern: https://assets.hansgrohe.com/...

UPDATE equipment_manuals SET source_url = 'https://www.hansgrohe-usa.com/articledetail-' || ec.model_number
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
WHERE equipment_manuals.catalog_entry_id = ec.id
  AND equipment_manuals.manual_type = 'spec_sheet'
  AND em.slug = 'hansgrohe';

-- ======================== SPEED QUEEN ========================
UPDATE equipment_manuals SET source_url = 'https://www.speedqueen.com/support/product-support/?modelNumber=' || ec.model_number
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
WHERE equipment_manuals.catalog_entry_id = ec.id
  AND em.slug = 'speed-queen';

-- ======================== Log summary ========================
-- After running this, invoke download-manuals to attempt downloading
-- all updated URLs. The function validates PDF magic bytes so non-PDF
-- responses are automatically skipped.
