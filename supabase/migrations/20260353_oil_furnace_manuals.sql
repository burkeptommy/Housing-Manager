-- Generate manual entries for the oil furnaces added in 20260352
-- These were inserted after the auto-generation migration (20260351) ran.

INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, language)
SELECT ec.id, 'owners_manual', 'Owners Manual',
  'https://www.americanstandardair.com/support?modelNumber=' || ec.model_number, 'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
WHERE em.slug = 'american-standard-hvac'
  AND ec.fuel_type = 'oil'
  AND NOT EXISTS (
    SELECT 1 FROM equipment_manuals m
    WHERE m.catalog_entry_id = ec.id AND m.manual_type = 'owners_manual'
  );

INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, language)
SELECT ec.id, 'spec_sheet', 'Spec Sheet',
  'https://www.americanstandardair.com/support?modelNumber=' || ec.model_number, 'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
WHERE em.slug = 'american-standard-hvac'
  AND ec.fuel_type = 'oil'
  AND NOT EXISTS (
    SELECT 1 FROM equipment_manuals m
    WHERE m.catalog_entry_id = ec.id AND m.manual_type = 'spec_sheet'
  );
