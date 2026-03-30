SET ROLE postgres;

-- ============================================================================
-- Equipment Manuals: HVAC Systems & Water Heaters
-- ============================================================================
-- Covers manuals for HVAC brands (Goodman, Carrier, Trane, Lennox, Rheem,
-- Daikin, Bryant, Mitsubishi Electric) and Water Heater brands (A.O. Smith,
-- Rheem, Bradford White, Rinnai, Navien, Noritz).
-- 310 manual entries across 14 brands.
-- ============================================================================

-- ======================== HVAC — GOODMAN ========================

-- Goodman Central AC manuals
INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('GSXC180361', 'owners_manual',       'GSXC18 Owner''s Manual',                 'https://iwae.com/media/manuals/goodman/gsx18-owner.pdf'),
  ('GSXC180361', 'installation_guide',  'GSXC18 Installation Instructions',       'https://documents.alpinehomeair.com/product/GSXC18%20Installation%20Instructions%202019.pdf'),
  ('GSXC180361', 'spec_sheet',          'GSXC18 3-Ton Specification Sheet',       'https://buy.goodmanmfg.com/assets/Documents/SS-GSXC18.pdf'),
  ('GSXC180481', 'owners_manual',       'GSXC18 Owner''s Manual',                 'https://iwae.com/media/manuals/goodman/gsx18-owner.pdf'),
  ('GSXC180481', 'installation_guide',  'GSXC18 Installation Instructions',       'https://documents.alpinehomeair.com/product/GSXC18%20Installation%20Instructions%202019.pdf'),
  ('GSX160361',  'owners_manual',       'GSX16 Owner''s Manual',                  'https://www.goodmanmfg.com/support/literature-library?model=GSX16'),
  ('GSX160361',  'installation_guide',  'GSX16 Installation Instructions',        'https://documents.alpinehomeair.com/product/Goodman%20GSX16%20Technical%20Information%202.2014.pdf'),
  ('GSX160361',  'spec_sheet',          'GSX16 3-Ton Specification Sheet',        'https://apps.goodmanmfg.com/brochures/files/5b9686fe6c593SS-FGSXC16.pdf'),
  ('GSX160481',  'owners_manual',       'GSX16 Owner''s Manual',                  'https://www.goodmanmfg.com/support/literature-library?model=GSX16'),
  ('GSX140361',  'owners_manual',       'GSX14 Owner''s Manual',                  'https://www.goodmanmfg.com/support/literature-library?model=GSX14'),
  ('GSX140361',  'installation_guide',  'GSX14 Installation Instructions',        'https://www.goodmanmfg.com/support/literature-library?model=GSX14'),
  ('GSXN403610', 'owners_manual',       'GSXN4 Owner''s Manual',                  'https://www.goodmanmfg.com/support/literature-library?model=GSXN4'),
  ('GSXN403610', 'installation_guide',  'GSXN4 Installation Instructions',        'https://www.goodmanmfg.com/support/literature-library?model=GSXN4')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- Goodman Furnace manuals
INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('GMVC961005CN', 'owners_manual',       'GMVC96 Owner''s Manual',               'https://www.goodmanmfg.com/support/literature-library?model=GMVC96'),
  ('GMVC961005CN', 'installation_guide',  'GMVC96 Installation Instructions',     'https://www.acdirect.com/media/specs/Goodman/goodman-gmes96-u-installation-instructions.pdf'),
  ('GMVC961005CN', 'spec_sheet',          'GMVC96 Specification Sheet',           'https://apps.goodmanmfg.com/brochures/files/5d94ab7d6f9adSS-FGMVC96.pdf'),
  ('GMVC960804CN', 'owners_manual',       'GMVC96 Owner''s Manual',               'https://www.goodmanmfg.com/support/literature-library?model=GMVC96'),
  ('GMVC960804CN', 'installation_guide',  'GMVC96 Installation Instructions',     'https://www.acdirect.com/media/specs/Goodman/goodman-gmes96-u-installation-instructions.pdf'),
  ('GCVM970804CN', 'owners_manual',       'GCVM97 Owner''s Manual',               'https://www.goodmanmfg.com/support/literature-library?model=GCVM97'),
  ('GCVM970804CN', 'installation_guide',  'GCVM97 Installation Instructions',     'https://www.goodmanmfg.com/support/literature-library?model=GCVM97'),
  ('GCVM970804CN', 'spec_sheet',          'GCVM97 Specification Sheet',           'https://apps.goodmanmfg.com/brochures/files/5ba3984a94c6fSS-GMEC96.pdf'),
  ('GMSS920804CN', 'owners_manual',       'GMSS92 Owner''s Manual',               'https://www.goodmanmfg.com/support/literature-library?model=GMSS92'),
  ('GMSS920804CN', 'installation_guide',  'GMSS92 Installation Instructions',     'https://www.goodmanmfg.com/support/literature-library?model=GMSS92'),
  ('GMS80804BN',   'owners_manual',       'GMS80 Owner''s Manual',                'https://www.goodmanmfg.com/support/literature-library?model=GMS80'),
  ('GMS80804BN',   'installation_guide',  'GMS80 Installation Instructions',      'https://www.goodmanmfg.com/support/literature-library?model=GMS80')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- Goodman Heat Pump manuals
INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('GSZC180361', 'owners_manual',       'GSZC18 Heat Pump Owner''s Manual',      'https://www.goodmanmfg.com/support/literature-library?model=GSZC18'),
  ('GSZC180361', 'installation_guide',  'GSZC18 Heat Pump Installation Guide',   'https://hvacdirect.com/media/hvac/pdf/goodman-gszc18-installation.pdf'),
  ('GSZC180361', 'spec_sheet',          'GSZC18 Specification Sheet',            'https://apps.goodmanmfg.com/brochures/files/5a9ec51f02a3fCB-GSZC18.pdf'),
  ('GSZC180481', 'owners_manual',       'GSZC18 Heat Pump Owner''s Manual',      'https://www.goodmanmfg.com/support/literature-library?model=GSZC18'),
  ('GSZB600361', 'owners_manual',       'GSZB6 Heat Pump Owner''s Manual',       'https://www.goodmanmfg.com/support/literature-library?model=GSZB6'),
  ('GSZB600361', 'installation_guide',  'GSZB6 Heat Pump Installation Guide',    'https://www.goodmanmfg.com/support/literature-library?model=GSZB6')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- ======================== HVAC — CARRIER ========================

-- Carrier Central AC manuals
INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('24ACC636A003',  'owners_manual',       'Carrier 24ACC6 Owner''s Manual',              'https://www.carrier.com/residential/en/us/homeowner-resources/product-literature/?model=24ACC636A003'),
  ('24ACC636A003',  'installation_guide',  'Carrier 24ACC6 Installation Instructions',    'https://www.carrier.com/residential/en/us/homeowner-resources/product-literature/?model=24ACC636A003'),
  ('24ACC636A003',  'spec_sheet',          'Carrier 24ACC6 Product Data',                 'https://www.carrier.com/residential/en/us/homeowner-resources/product-literature/?model=24ACC636A003'),
  ('24ACC648A003',  'owners_manual',       'Carrier 24ACC6 Owner''s Manual',              'https://www.carrier.com/residential/en/us/homeowner-resources/product-literature/?model=24ACC648A003'),
  ('24SCA636A003',  'owners_manual',       'Carrier 24SCA6 Owner''s Manual',              'https://www.carrier.com/residential/en/us/homeowner-resources/product-literature/?model=24SCA636A003'),
  ('24SCA636A003',  'installation_guide',  'Carrier 24SCA6 Installation Instructions',    'https://www.carrier.com/residential/en/us/homeowner-resources/product-literature/?model=24SCA636A003'),
  ('24SPA536A003',  'owners_manual',       'Carrier 24SPA5 Owner''s Manual',              'https://www.carrier.com/residential/en/us/homeowner-resources/product-literature/?model=24SPA536A003'),
  ('24SPA536A003',  'installation_guide',  'Carrier 24SPA5 Installation Instructions',    'https://www.carrier.com/residential/en/us/homeowner-resources/product-literature/?model=24SPA536A003'),
  ('24ANB136A003',  'owners_manual',       'Carrier 24ANB1 Owner''s Manual',              'https://www.carrier.com/residential/en/us/homeowner-resources/product-literature/?model=24ANB136A003'),
  ('24ANB136A003',  'installation_guide',  'Carrier 24ANB1 Installation Instructions',    'https://www.carrier.com/residential/en/us/homeowner-resources/product-literature/?model=24ANB136A003')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- Carrier Furnace manuals
INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('59MN7A080V21-20', 'owners_manual',       'Carrier 59MN7 Owner''s Manual',              'https://www.carrier.com/residential/en/us/homeowner-resources/product-literature/?model=59MN7A080V21-20'),
  ('59MN7A080V21-20', 'installation_guide',  'Carrier 59MN7 Installation Instructions',    'https://www.carrier.com/residential/en/us/homeowner-resources/product-literature/?model=59MN7A080V21-20'),
  ('59MN7A100V21-20', 'owners_manual',       'Carrier 59MN7 Owner''s Manual',              'https://www.carrier.com/residential/en/us/homeowner-resources/product-literature/?model=59MN7A100V21-20'),
  ('59TN6A080V21-14', 'owners_manual',       'Carrier 59TN6 Owner''s Manual',              'https://www.carrier.com/residential/en/us/homeowner-resources/product-literature/?model=59TN6A080V21-14'),
  ('59TN6A080V21-14', 'installation_guide',  'Carrier 59TN6 Installation Instructions',    'https://www.carrier.com/residential/en/us/homeowner-resources/product-literature/?model=59TN6A080V21-14'),
  ('59SC5A080S21-14', 'owners_manual',       'Carrier 59SC5 Owner''s Manual',              'https://www.carrier.com/residential/en/us/homeowner-resources/product-literature/?model=59SC5A080S21-14'),
  ('59SC5A080S21-14', 'installation_guide',  'Carrier 59SC5 Installation Instructions',    'https://www.carrier.com/residential/en/us/homeowner-resources/product-literature/?model=59SC5A080S21-14'),
  ('59SP5A080E21-14', 'owners_manual',       'Carrier 59SP5 Owner''s Manual',              'https://www.carrier.com/residential/en/us/homeowner-resources/product-literature/?model=59SP5A080E21-14')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- Carrier Heat Pump manuals
INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('25VNA036A003', 'owners_manual',       'Carrier Infinity 25VNA Owner''s Manual',       'https://www.carrier.com/residential/en/us/homeowner-resources/product-literature/?model=25VNA036A003'),
  ('25VNA036A003', 'installation_guide',  'Carrier Infinity 25VNA Installation Guide',    'https://www.carrier.com/residential/en/us/homeowner-resources/product-literature/?model=25VNA036A003'),
  ('25VNA048A003', 'owners_manual',       'Carrier Infinity 25VNA Owner''s Manual',       'https://www.carrier.com/residential/en/us/homeowner-resources/product-literature/?model=25VNA048A003'),
  ('25HCB636A003', 'owners_manual',       'Carrier 25HCB6 Owner''s Manual',              'https://www.carrier.com/residential/en/us/homeowner-resources/product-literature/?model=25HCB636A003'),
  ('25HCB636A003', 'installation_guide',  'Carrier 25HCB6 Installation Guide',           'https://www.carrier.com/residential/en/us/homeowner-resources/product-literature/?model=25HCB636A003')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- ======================== HVAC — TRANE ========================

-- Trane Central AC & Heat Pump manuals
INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('4TTR8036A1000A',  'owners_manual',       'Trane XV20i Outdoor Unit Owner''s Guide',          'https://www.trane.com/content/dam/Trane/residential/downloads/manuals/22-5213-WEB01_Outdoor_Units.pdf'),
  ('4TTR8036A1000A',  'installation_guide',  'Trane XV20i Installation Manual',                  'https://www.trane.com/residential/en/resources/owners-guides/?model=4TTR8036A1000A'),
  ('4TTR8036A1000A',  'spec_sheet',          'Trane XV20i Product Data',                         'https://www.trane.com/residential/en/resources/owners-guides/?model=4TTR8036A1000A'),
  ('4TTV8036A1000B',  'owners_manual',       'Trane XV18 Outdoor Unit Owner''s Guide',           'https://www.trane.com/content/dam/Trane/residential/downloads/manuals/22-5213-WEB01_Outdoor_Units.pdf'),
  ('4TTV8048A1000B',  'owners_manual',       'Trane XV18 Outdoor Unit Owner''s Guide',           'https://www.trane.com/content/dam/Trane/residential/downloads/manuals/22-5213-WEB01_Outdoor_Units.pdf'),
  ('4TTR6036J1000AA', 'owners_manual',       'Trane XR16 Outdoor Unit Owner''s Guide',           'https://www.trane.com/content/dam/Trane/residential/downloads/manuals/22-5213-WEB01_Outdoor_Units.pdf'),
  ('4TTR6036J1000AA', 'installation_guide',  'Trane XR16 Installation Manual',                   'https://www.trane.com/residential/en/resources/owners-guides/?model=4TTR6036J1000AA'),
  ('4TTR5036E1000A',  'owners_manual',       'Trane XR15 Outdoor Unit Owner''s Guide',           'https://www.trane.com/content/dam/Trane/residential/downloads/manuals/22-5213-WEB01_Outdoor_Units.pdf'),
  ('4TTR4036L1000A',  'owners_manual',       'Trane XR14 Outdoor Unit Owner''s Guide',           'https://www.trane.com/content/dam/Trane/residential/downloads/manuals/22-5213-WEB01_Outdoor_Units.pdf'),
  ('4TWR8036A1000A',  'owners_manual',       'Trane XV20i Heat Pump Owner''s Guide',             'https://www.trane.com/content/dam/Trane/residential/downloads/manuals/22-5213-WEB01_Outdoor_Units.pdf'),
  ('4TWR8036A1000A',  'installation_guide',  'Trane XV20i Heat Pump Installation Manual',        'https://www.trane.com/residential/en/resources/owners-guides/?model=4TWR8036A1000A'),
  ('4TWR6036J1000AA', 'owners_manual',       'Trane XR16 Heat Pump Owner''s Guide',              'https://www.trane.com/content/dam/Trane/residential/downloads/manuals/22-5213-WEB01_Outdoor_Units.pdf'),
  ('4TWR5036E1000A',  'owners_manual',       'Trane XR15 Heat Pump Owner''s Guide',              'https://www.trane.com/content/dam/Trane/residential/downloads/manuals/22-5213-WEB01_Outdoor_Units.pdf'),
  ('4TWV8036A1000B',  'owners_manual',       'Trane XV18 Heat Pump Owner''s Guide',              'https://www.trane.com/content/dam/Trane/residential/downloads/manuals/22-5213-WEB01_Outdoor_Units.pdf')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- Trane Furnace manuals
INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('S9V2B080U5PSB',  'owners_manual',       'Trane S9V2 Furnace Owner''s Guide',               'https://www.trane.com/content/dam/Trane/residential/downloads/manuals/32-5064-WEB01_Indoor_Units.pdf'),
  ('S9V2B080U5PSB',  'installation_guide',  'Trane S9V2 Furnace Installation Manual',          'https://www.trane.com/residential/en/resources/owners-guides/?model=S9V2B080U5PSB'),
  ('S9V2C100U5PSB',  'owners_manual',       'Trane S9V2 Furnace Owner''s Guide',               'https://www.trane.com/content/dam/Trane/residential/downloads/manuals/32-5064-WEB01_Indoor_Units.pdf'),
  ('S9X2B080U5PSA',  'owners_manual',       'Trane S9X2 Furnace Owner''s Guide',               'https://www.trane.com/content/dam/Trane/residential/downloads/manuals/32-5064-WEB01_Indoor_Units.pdf'),
  ('S9X2B080U5PSA',  'installation_guide',  'Trane S9X2 Furnace Installation Manual',          'https://www.trane.com/residential/en/resources/owners-guides/?model=S9X2B080U5PSA'),
  ('S8X1B080M3PSA',  'owners_manual',       'Trane S8X1 Furnace Owner''s Guide',               'https://www.trane.com/content/dam/Trane/residential/downloads/manuals/32-5064-WEB01_Indoor_Units.pdf'),
  ('S8X1B080M3PSA',  'installation_guide',  'Trane S8X1 Furnace Installation Manual',          'https://www.trane.com/residential/en/resources/owners-guides/?model=S8X1B080M3PSA')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- Trane Air Handler manuals
INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('TAM9A0C36V31CA', 'owners_manual',       'Trane TAM9 Air Handler Owner''s Guide',           'https://www.trane.com/content/dam/Trane/residential/downloads/manuals/32-5064-WEB01_Indoor_Units.pdf'),
  ('TAM9A0C36V31CA', 'installation_guide',  'Trane TAM9 Air Handler Installation Manual',      'https://www.trane.com/residential/en/resources/owners-guides/?model=TAM9A0C36V31CA'),
  ('TAM7A0C36H31CA', 'owners_manual',       'Trane TAM7 Air Handler Owner''s Guide',           'https://www.trane.com/content/dam/Trane/residential/downloads/manuals/32-5064-WEB01_Indoor_Units.pdf'),
  ('GAM5A0C36M31SA', 'owners_manual',       'Trane GAM5 Air Handler Owner''s Guide',           'https://www.trane.com/content/dam/Trane/residential/downloads/manuals/32-5064-WEB01_Indoor_Units.pdf')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- ======================== HVAC — LENNOX ========================

-- Lennox Central AC manuals
INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('XC25-036-230',    'owners_manual',       'Lennox XC25 Owner''s Manual',                    'https://www.lennox.com/lib/legacy-res/pdfs/brochures/lennox_xc25_air_conditioner.pdf'),
  ('XC25-036-230',    'installation_guide',  'Lennox XC25 Installation Instructions',          'https://www.lennox.com/dA/9269906c48/508066-01.pdf'),
  ('XC25-036-230',    'spec_sheet',          'Lennox XC25 Product Specifications',             'https://www.lennox.com/owners/assistance/product-literature/?model=XC25-036-230'),
  ('XC25-048-230',    'owners_manual',       'Lennox XC25 Owner''s Manual',                    'https://www.lennox.com/lib/legacy-res/pdfs/brochures/lennox_xc25_air_conditioner.pdf'),
  ('XC21-036-230',    'owners_manual',       'Lennox XC21 Owner''s Manual',                    'https://www.lennox.com/owners/assistance/product-literature/?model=XC21-036-230'),
  ('XC21-036-230',    'installation_guide',  'Lennox XC21 Installation Instructions',          'https://www.lennox.com/dA/8d83fa736b/Lennox_XC21_IOM.pdf'),
  ('EL18XCV-036-230', 'owners_manual',       'Lennox EL18XCV Owner''s Manual',                 'https://www.lennox.com/owners/assistance/product-literature/?model=EL18XCV-036-230'),
  ('EL18XCV-036-230', 'installation_guide',  'Lennox EL18XCV Installation Instructions',       'https://www.lennox.com/owners/assistance/product-literature/?model=EL18XCV-036-230'),
  ('EL16XC1-036-230', 'owners_manual',       'Lennox EL16XC1 Owner''s Manual',                 'https://www.lennox.com/owners/assistance/product-literature/?model=EL16XC1-036-230'),
  ('ML14XC1-036-230', 'owners_manual',       'Lennox ML14XC1 Owner''s Manual',                 'https://www.lennox.com/owners/assistance/product-literature/?model=ML14XC1-036-230'),
  ('ML18XC2-036-230', 'owners_manual',       'Lennox ML18XC2 Owner''s Manual',                 'https://www.lennox.com/owners/assistance/product-literature/?model=ML18XC2-036-230')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- Lennox Furnace manuals
INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('SLP99V070XP36C',  'owners_manual',       'Lennox SLP99V Owner''s Manual',                  'https://www.lennox.com/owners/assistance/product-literature/?model=SLP99V070XP36C'),
  ('SLP99V070XP36C',  'installation_guide',  'Lennox SLP99V Installation Instructions',        'https://www.lennox.com/owners/assistance/product-literature/?model=SLP99V070XP36C'),
  ('SLP99V070XP36C',  'spec_sheet',          'Lennox SLP99V Product Specifications',           'https://www.lennox.com/owners/assistance/product-literature/?model=SLP99V070XP36C'),
  ('SLP99V090XP48C',  'owners_manual',       'Lennox SLP99V Owner''s Manual',                  'https://www.lennox.com/owners/assistance/product-literature/?model=SLP99V090XP48C'),
  ('SL297NV070XP36C', 'owners_manual',       'Lennox SL297NV Owner''s Manual',                 'https://www.lennox.com/owners/assistance/product-literature/?model=SL297NV070XP36C'),
  ('SL297NV070XP36C', 'installation_guide',  'Lennox SL297NV Installation Instructions',       'https://www.lennox.com/owners/assistance/product-literature/?model=SL297NV070XP36C'),
  ('EL296V070XP36A',  'owners_manual',       'Lennox EL296V Owner''s Manual',                  'https://www.lennox.com/dA/e876acaf5a/506771f.pdf'),
  ('ML196UH070XP36B', 'owners_manual',       'Lennox ML196UH Owner''s Manual',                 'https://www.lennox.com/owners/assistance/product-literature/?model=ML196UH070XP36B'),
  ('ML180UH070XP36B', 'owners_manual',       'Lennox ML180UH Owner''s Manual',                 'https://www.lennox.com/owners/assistance/product-literature/?model=ML180UH070XP36B')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- Lennox Heat Pump manuals
INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('XP25-036-230',    'owners_manual',       'Lennox XP25 Heat Pump Owner''s Manual',          'https://www.lennox.com/lib/legacy-res/pdfs/installation_maintenance/lennox_xp17_iom.pdf'),
  ('XP25-036-230',    'installation_guide',  'Lennox XP25 Heat Pump Installation Guide',       'https://www.lennox.com/owners/assistance/product-literature/?model=XP25-036-230'),
  ('XP21-036-230',    'owners_manual',       'Lennox XP21 Heat Pump Owner''s Manual',          'https://www.lennox.com/owners/assistance/product-literature/?model=XP21-036-230'),
  ('EL18XPV-036-230', 'owners_manual',       'Lennox EL18XPV Heat Pump Owner''s Manual',       'https://www.lennox.com/owners/assistance/product-literature/?model=EL18XPV-036-230'),
  ('EL18XPV-036-230', 'installation_guide',  'Lennox EL18XPV Heat Pump Installation Guide',    'https://www.lennox.com/owners/assistance/product-literature/?model=EL18XPV-036-230'),
  ('14HPX-036-230',   'owners_manual',       'Lennox 14HPX Heat Pump Owner''s Manual',         'https://www.lennox.com/owners/assistance/product-literature/?model=14HPX-036-230')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- ======================== HVAC — RHEEM ========================

-- Rheem Central AC manuals
INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('RA20AZ036', 'owners_manual',       'Rheem RA20AZ Owner''s Manual',                'https://www.rheem.com/document-finder/?model=RA20AZ036'),
  ('RA20AZ036', 'installation_guide',  'Rheem RA20AZ Installation Instructions',      'https://www.rheem.com/document-finder/?model=RA20AZ036'),
  ('RA20AZ036', 'spec_sheet',          'Rheem RA20AZ Product Specification',          'https://www.rheem.com/document-finder/?model=RA20AZ036'),
  ('RA20AZ048', 'owners_manual',       'Rheem RA20AZ Owner''s Manual',                'https://www.rheem.com/document-finder/?model=RA20AZ048'),
  ('RA17AZ036', 'owners_manual',       'Rheem RA17AZ Owner''s Manual',                'https://www.rheem.com/document-finder/?model=RA17AZ036'),
  ('RA17AZ036', 'installation_guide',  'Rheem RA17AZ Installation Instructions',      'https://pts.myrheem.com/docstore/webdocs/Public/ServicePublic/Trouble2a/pdfs/AC/RA17/92-104921-07-00_RA17.pdf'),
  ('RA16AZ036', 'owners_manual',       'Rheem RA16AZ Owner''s Manual',                'https://www.rheem.com/document-finder/?model=RA16AZ036'),
  ('RA14AZ036', 'owners_manual',       'Rheem RA14AZ Owner''s Manual',                'https://www.rheem.com/document-finder/?model=RA14AZ036')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- Rheem Furnace manuals
INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('R97VA080521MSA',  'owners_manual',       'Rheem R97V Furnace Owner''s Manual',              'https://www.rheem.com/document-finder/?model=R97VA080521MSA'),
  ('R97VA080521MSA',  'installation_guide',  'Rheem R97V Furnace Installation Manual',          'https://www.rheem.com/document-finder/?model=R97VA080521MSA'),
  ('R97VA100521MSA',  'owners_manual',       'Rheem R97V Furnace Owner''s Manual',              'https://www.rheem.com/document-finder/?model=R97VA100521MSA'),
  ('R96VA080521MSA',  'owners_manual',       'Rheem R96V Furnace Owner''s Manual',              'https://www.rheem.com/document-finder/?model=R96VA080521MSA'),
  ('R96VA080521MSA',  'installation_guide',  'Rheem R96V Furnace Installation Manual',          'https://www.rheem.com/document-finder/?model=R96VA080521MSA'),
  ('R95T0801521MSA',  'owners_manual',       'Rheem R95T Furnace Owner''s Manual',              'https://www.rheem.com/document-finder/?model=R95T0801521MSA'),
  ('R801T0804521MSA', 'owners_manual',       'Rheem R801T Furnace Owner''s Manual',             'https://www.rheem.com/document-finder/?model=R801T0804521MSA')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- Rheem Heat Pump manuals
INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('RP20AZ036', 'owners_manual',       'Rheem RP20AZ Heat Pump Owner''s Manual',       'https://www.rheem.com/document-finder/?model=RP20AZ036'),
  ('RP20AZ036', 'installation_guide',  'Rheem RP20AZ Heat Pump Installation Guide',    'https://www.rheem.com/document-finder/?model=RP20AZ036'),
  ('RP17AZ036', 'owners_manual',       'Rheem RP17AZ Heat Pump Owner''s Manual',       'https://www.rheem.com/document-finder/?model=RP17AZ036'),
  ('RP16AZ036', 'owners_manual',       'Rheem RP16AZ Heat Pump Owner''s Manual',       'https://www.rheem.com/document-finder/?model=RP16AZ036'),
  ('RP14AZ036', 'owners_manual',       'Rheem RP14AZ Heat Pump Owner''s Manual',       'https://www.rheem.com/document-finder/?model=RP14AZ036')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- ======================== HVAC — DAIKIN ========================

-- Daikin Central AC manuals
INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('DX20VC0361AA', 'owners_manual',       'Daikin DX20VC Owner''s Manual',                 'https://daikincomfort.com/my-daikin-systems/owner-support-center?model=DX20VC0361AA'),
  ('DX20VC0361AA', 'installation_guide',  'Daikin DX20VC Installation Instructions',       'https://daikincomfort.com/my-daikin-systems/owner-support-center?model=DX20VC0361AA'),
  ('DX20VC0361AA', 'spec_sheet',          'Daikin DX20VC Product Specifications',          'https://daikincomfort.com/my-daikin-systems/owner-support-center?model=DX20VC0361AA'),
  ('DX20VC0481AA', 'owners_manual',       'Daikin DX20VC Owner''s Manual',                 'https://daikincomfort.com/my-daikin-systems/owner-support-center?model=DX20VC0481AA'),
  ('DX18TC0361AA', 'owners_manual',       'Daikin DX18TC Owner''s Manual',                 'https://daikincomfort.com/my-daikin-systems/owner-support-center?model=DX18TC0361AA'),
  ('DX18TC0361AA', 'installation_guide',  'Daikin DX18TC Installation Instructions',       'https://daikincomfort.com/my-daikin-systems/owner-support-center?model=DX18TC0361AA'),
  ('DX16SA0361AA', 'owners_manual',       'Daikin DX16SA Owner''s Manual',                 'https://daikincomfort.com/my-daikin-systems/owner-support-center?model=DX16SA0361AA'),
  ('DX14SN0361AA', 'owners_manual',       'Daikin DX14SN Owner''s Manual',                 'https://daikincomfort.com/my-daikin-systems/owner-support-center?model=DX14SN0361AA')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- Daikin Furnace manuals
INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('DM97MC0803BN',  'owners_manual',       'Daikin DM97MC Furnace Owner''s Manual',          'https://daikincomfort.com/my-daikin-systems/owner-support-center?model=DM97MC0803BN'),
  ('DM97MC0803BN',  'installation_guide',  'Daikin DM97MC Furnace Installation Guide',       'https://daikincomfort.com/my-daikin-systems/owner-support-center?model=DM97MC0803BN'),
  ('DM97MC1005CN',  'owners_manual',       'Daikin DM97MC Furnace Owner''s Manual',          'https://daikincomfort.com/my-daikin-systems/owner-support-center?model=DM97MC1005CN'),
  ('DM96VE0804BN',  'owners_manual',       'Daikin DM96VE Furnace Owner''s Manual',          'https://daikincomfort.com/my-daikin-systems/owner-support-center?model=DM96VE0804BN'),
  ('DM80VE0804BN',  'owners_manual',       'Daikin DM80VE Furnace Owner''s Manual',          'https://daikincomfort.com/my-daikin-systems/owner-support-center?model=DM80VE0804BN'),
  ('DC96VE0803BN',  'owners_manual',       'Daikin DC96VE Furnace Owner''s Manual',          'https://daikincomfort.com/my-daikin-systems/owner-support-center?model=DC96VE0803BN')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- Daikin Heat Pump manuals
INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('DZ20VC0361AA', 'owners_manual',       'Daikin DZ20VC Heat Pump Owner''s Manual',        'https://daikincomfort.com/my-daikin-systems/owner-support-center?model=DZ20VC0361AA'),
  ('DZ20VC0361AA', 'installation_guide',  'Daikin DZ20VC Heat Pump Installation Guide',     'https://daikincomfort.com/my-daikin-systems/owner-support-center?model=DZ20VC0361AA'),
  ('DZ18TC0361AA', 'owners_manual',       'Daikin DZ18TC Heat Pump Owner''s Manual',        'https://daikincomfort.com/my-daikin-systems/owner-support-center?model=DZ18TC0361AA'),
  ('DZ16SA0361AA', 'owners_manual',       'Daikin DZ16SA Heat Pump Owner''s Manual',        'https://daikincomfort.com/my-daikin-systems/owner-support-center?model=DZ16SA0361AA'),
  ('DZ14SN0361AA', 'owners_manual',       'Daikin DZ14SN Heat Pump Owner''s Manual',        'https://daikincomfort.com/my-daikin-systems/owner-support-center?model=DZ14SN0361AA')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- Daikin Mini-Split manuals
INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('RXB12AXVJU', 'owners_manual',       'Daikin RXB12 Mini-Split Operation Manual',      'https://backend.daikincomfort.com/docs/default-source/product-documents/residential/manuals/operationmanuals/om-fctkx_axvju-3p601789-1-b.pdf'),
  ('RXB12AXVJU', 'installation_guide',  'Daikin RXB12 Mini-Split Installation Guide',    'https://daikincomfort.com/my-daikin-systems/owner-support-center?model=RXB12AXVJU'),
  ('RXB18AXVJU', 'owners_manual',       'Daikin RXB18 Mini-Split Operation Manual',      'https://backend.daikincomfort.com/docs/default-source/product-documents/residential/manuals/operationmanuals/om-fctkx_axvju-3p601789-1-b.pdf')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- ======================== HVAC — BRYANT ========================

-- Bryant Central AC manuals
INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('289BNV036000', 'owners_manual',       'Bryant Evolution 289BNV Owner''s Manual',       'https://www.bryant.com/en/us/current-owners/document-search/?model=289BNV036000'),
  ('289BNV036000', 'installation_guide',  'Bryant Evolution 289BNV Installation Guide',    'https://www.bryant.com/en/us/current-owners/document-search/?model=289BNV036000'),
  ('280ANV036000', 'owners_manual',       'Bryant Evolution 280ANV Owner''s Manual',       'https://www.bryant.com/en/us/current-owners/document-search/?model=280ANV036000'),
  ('280ANV036000', 'installation_guide',  'Bryant Evolution 280ANV Installation Guide',    'https://www.bryant.com/en/us/current-owners/document-search/?model=280ANV036000'),
  ('226ANA036000', 'owners_manual',       'Bryant 226ANA Owner''s Manual',                 'https://www.bryant.com/en/us/current-owners/document-search/?model=226ANA036000'),
  ('189BNV036000', 'owners_manual',       'Bryant Preferred 189BNV Owner''s Manual',       'https://www.bryant.com/en/us/current-owners/document-search/?model=189BNV036000'),
  ('180BNV036000', 'owners_manual',       'Bryant Preferred 180BNV Owner''s Manual',       'https://www.bryant.com/en/us/current-owners/document-search/?model=180BNV036000'),
  ('127BNA036000', 'owners_manual',       'Bryant Legacy 127BNA Owner''s Manual',          'https://www.bryant.com/en/us/current-owners/document-search/?model=127BNA036000'),
  ('116BNA036000', 'owners_manual',       'Bryant Legacy 116BNA Owner''s Manual',          'https://www.bryant.com/en/us/current-owners/document-search/?model=116BNA036000'),
  ('113ANA036000', 'owners_manual',       'Bryant Legacy 113ANA Owner''s Manual',          'https://www.bryant.com/en/us/current-owners/document-search/?model=113ANA036000')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- Bryant Furnace manuals
INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('987MA42080V21',  'owners_manual',       'Bryant Evolution 987M Furnace Owner''s Manual',    'https://www.bryant.com/en/us/current-owners/document-search/?model=987MA42080V21'),
  ('987MA42080V21',  'installation_guide',  'Bryant Evolution 987M Furnace Installation Guide', 'https://www.bryant.com/en/us/current-owners/document-search/?model=987MA42080V21'),
  ('987MA42100V21',  'owners_manual',       'Bryant Evolution 987M Furnace Owner''s Manual',    'https://www.bryant.com/en/us/current-owners/document-search/?model=987MA42100V21'),
  ('926TA36080V17',  'owners_manual',       'Bryant Preferred 926T Furnace Owner''s Manual',    'https://www.bryant.com/en/us/current-owners/document-search/?model=926TA36080V17'),
  ('926TA36080V17',  'installation_guide',  'Bryant Preferred 926T Furnace Installation Guide', 'https://www.bryant.com/en/us/current-owners/document-search/?model=926TA36080V17'),
  ('915SA36080V14',  'owners_manual',       'Bryant Preferred 915S Furnace Owner''s Manual',    'https://www.bryant.com/en/us/current-owners/document-search/?model=915SA36080V14'),
  ('801SA36080M14',  'owners_manual',       'Bryant Legacy 801S Furnace Owner''s Manual',       'https://www.bryant.com/en/us/current-owners/document-search/?model=801SA36080M14')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- ======================== HVAC — MITSUBISHI ELECTRIC ========================

-- Mitsubishi Electric Mini-Split manuals
INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('MSZ-FH09NA',     'owners_manual',       'Mitsubishi MSZ-FH Hyper-Heating Owner''s Manual',    'https://www.mitsubishicomfort.com/brochures-catalogs'),
  ('MSZ-FH09NA',     'installation_guide',  'Mitsubishi MSZ-FH Installation Manual',              'http://meus1.mylinkdrive.com/files/MSZ-06-15NA(H)-U1_MSY-GL09-15NA(H)-U1_Install_12-15.pdf'),
  ('MSZ-FH12NA',     'owners_manual',       'Mitsubishi MSZ-FH Hyper-Heating Owner''s Manual',    'https://www.mitsubishicomfort.com/brochures-catalogs'),
  ('MSZ-FH15NA',     'owners_manual',       'Mitsubishi MSZ-FH Hyper-Heating Owner''s Manual',    'https://www.mitsubishicomfort.com/brochures-catalogs'),
  ('MSZ-FH18NA',     'owners_manual',       'Mitsubishi MSZ-FH Hyper-Heating Owner''s Manual',    'https://www.mitsubishicomfort.com/brochures-catalogs'),
  ('MSZ-GL09NA',     'owners_manual',       'Mitsubishi MSZ-GL Owner''s Manual',                  'https://www.mitsubishicomfort.com/brochures-catalogs'),
  ('MSZ-GL09NA',     'installation_guide',  'Mitsubishi MSZ-GL Installation Manual',              'http://meus1.mylinkdrive.com/files/MSZ-06-15NA(H)-U1_MSY-GL09-15NA(H)-U1_Install_12-15.pdf'),
  ('MSZ-GL12NA',     'owners_manual',       'Mitsubishi MSZ-GL Owner''s Manual',                  'https://www.mitsubishicomfort.com/brochures-catalogs'),
  ('MSZ-GL18NA',     'owners_manual',       'Mitsubishi MSZ-GL Owner''s Manual',                  'https://www.mitsubishicomfort.com/brochures-catalogs'),
  ('MSZ-GL24NA',     'owners_manual',       'Mitsubishi MSZ-GL Owner''s Manual',                  'https://www.mitsubishicomfort.com/brochures-catalogs'),
  ('MXZ-2C20NAHZ2',  'owners_manual',       'Mitsubishi MXZ Multi-Zone Owner''s Manual',          'https://www.mitsubishicomfort.com/brochures-catalogs'),
  ('MXZ-2C20NAHZ2',  'installation_guide',  'Mitsubishi MXZ Multi-Zone Installation Manual',      'https://genscocustomer.com/pages/product-resources/catalog/MXZ_Multizone_Tech_Manual.pdf'),
  ('MXZ-3C30NAHZ2',  'owners_manual',       'Mitsubishi MXZ Multi-Zone Owner''s Manual',          'https://www.mitsubishicomfort.com/brochures-catalogs'),
  ('MXZ-4C36NAHZ',   'owners_manual',       'Mitsubishi MXZ Multi-Zone Owner''s Manual',          'https://www.mitsubishicomfort.com/brochures-catalogs'),
  ('MXZ-5C42NAHZ',   'owners_manual',       'Mitsubishi MXZ Multi-Zone Owner''s Manual',          'https://www.mitsubishicomfort.com/brochures-catalogs'),
  ('PUZ-HA36NHA5',   'owners_manual',       'Mitsubishi PUZ-HA Ducted Heat Pump Owner''s Manual', 'https://www.mitsubishicomfort.com/brochures-catalogs'),
  ('PUZ-HA36NHA5',   'installation_guide',  'Mitsubishi PUZ-HA Installation Manual',              'https://www.mitsubishicomfort.com/brochures-catalogs'),
  ('PUZ-HA42NHA5',   'owners_manual',       'Mitsubishi PUZ-HA Ducted Heat Pump Owner''s Manual', 'https://www.mitsubishicomfort.com/brochures-catalogs')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- ======================== WATER HEATERS — A.O. SMITH ========================

-- A.O. Smith Tank Gas Water Heater manuals
INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('G6-T4036NV',   'owners_manual',       'A.O. Smith ProLine Gas Water Heater Owner''s Manual',         'https://assets.aosmith.com/damroot/Original/10004/100349445.pdf'),
  ('G6-T4036NV',   'installation_guide',  'A.O. Smith ProLine Gas Installation Instructions',            'https://assets.aosmith.com/damroot/Original/10004/198142-000.pdf'),
  ('G6-T5040NV',   'owners_manual',       'A.O. Smith ProLine Gas Water Heater Owner''s Manual',         'https://assets.aosmith.com/damroot/Original/10004/100349445.pdf'),
  ('G6-T5040NV',   'installation_guide',  'A.O. Smith ProLine Gas Installation Instructions',            'https://assets.aosmith.com/damroot/Original/10004/198142-000.pdf'),
  ('G6-T7540NV',   'owners_manual',       'A.O. Smith ProLine XE Gas Owner''s Manual',                   'https://assets.aosmith.com/damroot/Original/10004/100349445.pdf'),
  ('G9-T5040NV',   'owners_manual',       'A.O. Smith ProLine XE High-Efficiency Gas Owner''s Manual',   'https://assets.aosmith.com/damroot/Original/10004/100349445.pdf'),
  ('G12-T5040NV',  'owners_manual',       'A.O. Smith Polaris Gas Owner''s Manual',                      'https://assets.aosmith.com/damroot/Original/10005/100295494.pdf'),
  ('G6-T4036PV',   'owners_manual',       'A.O. Smith ProLine Gas (LP) Owner''s Manual',                 'https://assets.aosmith.com/damroot/Original/10004/100349445.pdf')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- A.O. Smith Tank Electric Water Heater manuals
INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('E6-40H45DV',  'owners_manual',       'A.O. Smith ProLine Electric Water Heater Owner''s Manual',    'https://assets.aosmith.com/damroot/Original/10004/100349445.pdf'),
  ('E6-40H45DV',  'installation_guide',  'A.O. Smith ProLine Electric Installation Instructions',       'https://assets.aosmith.com/damroot/Original/10004/198142-000.pdf'),
  ('E6-50H45DV',  'owners_manual',       'A.O. Smith ProLine Electric Water Heater Owner''s Manual',    'https://assets.aosmith.com/damroot/Original/10004/100349445.pdf'),
  ('E6-80H45DV',  'owners_manual',       'A.O. Smith ProLine Electric Water Heater Owner''s Manual',    'https://assets.aosmith.com/damroot/Original/10004/100349445.pdf'),
  ('ENL-40',      'owners_manual',       'A.O. Smith ProLine Electric Lowboy Owner''s Manual',          'https://assets.aosmith.com/damroot/Original/10004/100349445.pdf'),
  ('ENL-50',      'owners_manual',       'A.O. Smith ProLine Electric Lowboy Owner''s Manual',          'https://assets.aosmith.com/damroot/Original/10004/100349445.pdf')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- A.O. Smith Tankless manuals
INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('ATI-540H-N', 'owners_manual',       'A.O. Smith Tankless Owner''s Manual',                          'https://assets.aosmith.com/damroot/Original/10004/tankless%20manual%20110.310.510%20models.pdf'),
  ('ATI-540H-N', 'installation_guide',  'A.O. Smith Tankless Installation Guide',                       'https://assets.aosmith.com/damroot/Original/10004/tankless%20manual%20110.310.510%20models.pdf'),
  ('ATI-340H-N', 'owners_manual',       'A.O. Smith Tankless Owner''s Manual',                          'https://assets.aosmith.com/damroot/Original/10004/tankless%20manual%20110.310.510%20models.pdf'),
  ('ATI-510U-N', 'owners_manual',       'A.O. Smith Tankless Commercial Owner''s Manual',               'https://assets.aosmith.com/damroot/Original/10004/tankless%20manual%20110.310.510%20models.pdf'),
  ('ATE-110',    'owners_manual',       'A.O. Smith Tankless Electric Owner''s Manual',                  'https://assets.aosmith.com/damroot/Original/10004/tankless%20manual%20110.310.510%20models.pdf'),
  ('ATE-240',    'owners_manual',       'A.O. Smith Tankless Electric Owner''s Manual',                  'https://assets.aosmith.com/damroot/Original/10004/tankless%20manual%20110.310.510%20models.pdf')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- A.O. Smith Heat Pump Water Heater manuals
INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('HP6-50H45DV', 'owners_manual',       'A.O. Smith Voltex Hybrid Heat Pump Owner''s Manual',          'https://assets.aosmith.com/damroot/Original/10004/100268628.pdf'),
  ('HP6-50H45DV', 'installation_guide',  'A.O. Smith Voltex Hybrid Heat Pump Installation Guide',       'https://assets.aosmith.com/damroot/Original/10004/100268628.pdf'),
  ('HP6-50H45DV', 'energy_guide',        'A.O. Smith Voltex Hybrid Heat Pump Energy Guide',             'https://assets.aosmith.com/damroot/Original/10004/100268628.pdf'),
  ('HP6-66H45DV', 'owners_manual',       'A.O. Smith Voltex Hybrid Heat Pump Owner''s Manual',          'https://assets.aosmith.com/damroot/Original/10004/100268628.pdf'),
  ('HP6-80H45DV', 'owners_manual',       'A.O. Smith Voltex Hybrid Heat Pump Owner''s Manual',          'https://assets.aosmith.com/damroot/Original/10004/100268628.pdf'),
  ('HPTU-50N',    'owners_manual',       'A.O. Smith HPTU Hybrid Electric Owner''s Manual',             'https://assets.aosmith.com/damroot/Original/10004/100268628.pdf'),
  ('HPTU-80N',    'owners_manual',       'A.O. Smith HPTU Hybrid Electric Owner''s Manual',             'https://assets.aosmith.com/damroot/Original/10004/100268628.pdf')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- ======================== WATER HEATERS — RHEEM ========================

-- Rheem Tank Gas Water Heater manuals
INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('PROG50-42N RH67',  'owners_manual',       'Rheem ProTerra Gas Water Heater Use & Care Manual',    'https://www.rheem.com/document-finder/?model=PROG50-42N'),
  ('PROG50-42N RH67',  'installation_guide',  'Rheem ProTerra Gas Installation Manual',               'https://www.rheem.com/document-finder/?model=PROG50-42N'),
  ('PROG50-38N RH60',  'owners_manual',       'Rheem Performance Gas Water Heater Use & Care Manual', 'https://www.rheem.com/document-finder/?model=PROG50-38N'),
  ('PROG40-40N RH62',  'owners_manual',       'Rheem Performance Gas Water Heater Use & Care Manual', 'https://www.rheem.com/document-finder/?model=PROG40-40N'),
  ('PROG40-36N RH60',  'owners_manual',       'Rheem Performance Gas Water Heater Use & Care Manual', 'https://www.rheem.com/document-finder/?model=PROG40-36N'),
  ('XG50T06EC36U0',    'owners_manual',       'Rheem XG50 Gas Water Heater Use & Care Manual',        'https://www.rheem.com/document-finder/?model=XG50T06EC36U0'),
  ('XG40T06HE36U0',    'owners_manual',       'Rheem XG40 Gas Water Heater Use & Care Manual',        'https://www.rheem.com/document-finder/?model=XG40T06HE36U0')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- Rheem Tank Electric Water Heater manuals
INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('PROE50 T2 RH95',    'owners_manual',       'Rheem ProTerra Electric Water Heater Use & Care Manual',  'https://files.rheem.com/blobazrheem/wp-content/uploads/sites/2/AP21980-Rev-02-Electric-Residential-WH-with-e-control-HIGH-TIER.pdf'),
  ('PROE50 T2 RH95',    'installation_guide',  'Rheem ProTerra Electric Installation Manual',             'https://files.rheem.com/blobazrheem/wp-content/uploads/sites/2/AP21980-Rev-02-Electric-Residential-WH-with-e-control-HIGH-TIER.pdf'),
  ('PROE40 T2 RH95',    'owners_manual',       'Rheem ProTerra Electric Water Heater Use & Care Manual',  'https://files.rheem.com/blobazrheem/wp-content/uploads/sites/2/AP21980-Rev-02-Electric-Residential-WH-with-e-control-HIGH-TIER.pdf'),
  ('PROE80 T2 RH95',    'owners_manual',       'Rheem ProTerra Electric Water Heater Use & Care Manual',  'https://files.rheem.com/blobazrheem/wp-content/uploads/sites/2/AP21980-Rev-02-Electric-Residential-WH-with-e-control-HIGH-TIER.pdf'),
  ('XE50T06ST55U0',     'owners_manual',       'Rheem XE50 Electric Water Heater Use & Care Manual',     'https://www.rheem.com/document-finder/?model=XE50T06ST55U0'),
  ('XE40T06ST45U0',     'owners_manual',       'Rheem XE40 Electric Water Heater Use & Care Manual',     'https://www.rheem.com/document-finder/?model=XE40T06ST45U0')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- Rheem Tankless Water Heater manuals
INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('RTGH-95DVLN-3',   'owners_manual',       'Rheem RTGH-95 Condensing Tankless Use & Care Manual',       'https://media.rheem.com/media/uploads/iat/sites/36/2023/01/AP22745-Rev04-1.pdf'),
  ('RTGH-95DVLN-3',   'installation_guide',  'Rheem RTGH-95 Condensing Tankless Installation Manual',     'https://media.rheem.com/media/uploads/iat/sites/36/2023/01/AP22745-Rev04-1.pdf'),
  ('RTGH-84DVLN-3',   'owners_manual',       'Rheem RTGH-84 Condensing Tankless Use & Care Manual',       'https://media.rheem.com/media/uploads/iat/sites/36/2023/01/AP22745-Rev04-1.pdf'),
  ('RTGH-84DVLP-3',   'owners_manual',       'Rheem RTGH-84 Condensing Tankless (LP) Use & Care Manual',  'https://media.rheem.com/media/uploads/iat/sites/36/2023/01/AP22745-Rev04-1.pdf'),
  ('RTGH-RH10DVLN',   'owners_manual',       'Rheem Tankless with Recirculation Use & Care Manual',       'https://media.rheem.com/media/uploads/iat/sites/36/2023/01/AP22745-Rev04-1.pdf'),
  ('RTG-84DVLN-1',    'owners_manual',       'Rheem RTG Non-Condensing Tankless User Manual',             'https://media.rheem.com/media/uploads/iat/sites/36/2023/07/TanklessUser_84161404w.pdf'),
  ('RTEX-13',         'owners_manual',       'Rheem RTEX Electric Tankless Owner''s Manual',              'https://www.rheem.com/document-finder/?model=RTEX-13'),
  ('RTEX-18',         'owners_manual',       'Rheem RTEX Electric Tankless Owner''s Manual',              'https://www.rheem.com/document-finder/?model=RTEX-18'),
  ('RTEX-24',         'owners_manual',       'Rheem RTEX Electric Tankless Owner''s Manual',              'https://www.rheem.com/document-finder/?model=RTEX-24')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- Rheem Heat Pump Water Heater manuals
INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('PROPH50 T2 RH375', 'owners_manual',       'Rheem ProTerra Hybrid Heat Pump Use & Care Manual',        'https://media.rheem.com/blobazrheem/wp-content/uploads/sites/36/2025/01/AP23657-Use-Care-Manual.pdf'),
  ('PROPH50 T2 RH375', 'installation_guide',  'Rheem ProTerra Hybrid Heat Pump Installation Manual',      'https://media.rheem.com/blobazrheem/wp-content/uploads/sites/36/2025/01/AP23657-Use-Care-Manual.pdf'),
  ('PROPH50 T2 RH375', 'energy_guide',        'Rheem ProTerra Hybrid Heat Pump Energy Guide',             'https://www.rheem.com/document-finder/?model=PROPH50'),
  ('PROPH65 T2 RH375', 'owners_manual',       'Rheem ProTerra Hybrid Heat Pump Use & Care Manual',        'https://media.rheem.com/blobazrheem/wp-content/uploads/sites/36/2025/01/AP23657-Use-Care-Manual.pdf'),
  ('PROPH80 T2 RH375', 'owners_manual',       'Rheem ProTerra Hybrid Heat Pump Use & Care Manual',        'https://media.rheem.com/blobazrheem/wp-content/uploads/sites/36/2025/01/AP23657-Use-Care-Manual.pdf'),
  ('PROPH40 T2 RH375', 'owners_manual',       'Rheem ProTerra Hybrid Heat Pump Use & Care Manual',        'https://media.rheem.com/blobazrheem/wp-content/uploads/sites/36/2025/01/AP23657-Use-Care-Manual.pdf')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- ======================== WATER HEATERS — BRADFORD WHITE ========================

-- Bradford White Tank Gas manuals
INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('RG240T6N',      'owners_manual',       'Bradford White Defender Gas Water Heater Owner''s Manual',     'https://www.bradfordwhite.com/wp-content/uploads/2024/03/G3-Owners-Manual.pdf'),
  ('RG240T6N',      'installation_guide',  'Bradford White Defender Gas Installation & Operation Manual',  'https://docs.bradfordwhite.com/I&O/238-54649-00_Current.pdf'),
  ('RG250T6N',      'owners_manual',       'Bradford White Defender Gas Water Heater Owner''s Manual',     'https://www.bradfordwhite.com/wp-content/uploads/2024/03/G3-Owners-Manual.pdf'),
  ('RG250T6N',      'installation_guide',  'Bradford White Defender Gas Installation & Operation Manual',  'https://docs.bradfordwhite.com/I&O/238-54649-00_Current.pdf'),
  ('RG275H6N',      'owners_manual',       'Bradford White High-Input Gas Owner''s Manual',                'https://www.bradfordwhite.com/wp-content/uploads/2024/03/G3-Owners-Manual.pdf'),
  ('RG240T6P',      'owners_manual',       'Bradford White Defender Gas (LP) Owner''s Manual',             'https://www.bradfordwhite.com/wp-content/uploads/2024/03/G3-Owners-Manual.pdf'),
  ('RG2DV40T6N',    'owners_manual',       'Bradford White Direct Vent Gas Owner''s Manual',               'https://www.bradfordwhite.com/wp-content/uploads/2024/03/G3-Owners-Manual.pdf'),
  ('RG2MH50T6N',    'owners_manual',       'Bradford White Residential Atmospheric Gas Owner''s Manual',   'https://www.bradfordwhite.com/wp-content/uploads/2024/03/G3-Owners-Manual.pdf')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- Bradford White Tank Electric manuals
INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('RE240T6-1NCWW',  'owners_manual',       'Bradford White Electric Water Heater Owner''s Manual',        'https://docs.bradfordwhite.com/I&O/238-44422-00_Current.pdf'),
  ('RE240T6-1NCWW',  'installation_guide',  'Bradford White Electric Installation & Operation Manual',     'https://docs.bradfordwhite.com/I&O/238-44422-00_Current.pdf'),
  ('RE250T6-1NCWW',  'owners_manual',       'Bradford White Electric Water Heater Owner''s Manual',        'https://docs.bradfordwhite.com/I&O/238-44422-00_Current.pdf'),
  ('RE280T6-1NCWW',  'owners_manual',       'Bradford White Electric Water Heater Owner''s Manual',        'https://docs.bradfordwhite.com/I&O/238-44422-00_Current.pdf'),
  ('RE350T6-1NCWW',  'owners_manual',       'Bradford White Electric Water Heater Owner''s Manual',        'https://docs.bradfordwhite.com/I&O/238-44422-00_Current.pdf')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- Bradford White Tankless manuals
INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('RTG-199HEN',     'owners_manual',       'Bradford White Infiniti Tankless Owner''s Manual',           'https://forthepro.bradfordwhite.com/documentation/usa-en/residential/tankless-gas/'),
  ('RTG-199HEN',     'installation_guide',  'Bradford White Infiniti Tankless Installation Manual',       'https://forthepro.bradfordwhite.com/documentation/usa-en/residential/tankless-gas/'),
  ('RTG-199HEP',     'owners_manual',       'Bradford White Infiniti Tankless (LP) Owner''s Manual',      'https://forthepro.bradfordwhite.com/documentation/usa-en/residential/tankless-gas/'),
  ('RTG-K160N',      'owners_manual',       'Bradford White Infiniti K-Series Owner''s Manual',           'https://forthepro.bradfordwhite.com/documentation/usa-en/residential/tankless-gas/'),
  ('RTG-K160N-R',    'owners_manual',       'Bradford White Infiniti K-Series Recirc Owner''s Manual',    'https://forthepro.bradfordwhite.com/documentation/usa-en/residential/tankless-gas/')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- Bradford White Heat Pump Water Heater manuals
INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('RE2H50R10BN',  'owners_manual',       'Bradford White AeroTherm Heat Pump Owner''s Manual',          'https://docs.bradfordwhite.com/Service_Manual/238-51791-00_Current.pdf'),
  ('RE2H50R10BN',  'installation_guide',  'Bradford White AeroTherm Heat Pump Installation Manual',      'https://docs.bradfordwhite.com/Service_Manual/238-51791-00_Current.pdf'),
  ('RE2H65R10BN',  'owners_manual',       'Bradford White AeroTherm Heat Pump Owner''s Manual',          'https://docs.bradfordwhite.com/Service_Manual/238-51791-00_Current.pdf'),
  ('RE2H80R10BN',  'owners_manual',       'Bradford White AeroTherm Heat Pump Owner''s Manual',          'https://docs.bradfordwhite.com/Service_Manual/238-51791-00_Current.pdf')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- ======================== WATER HEATERS — RINNAI ========================

-- Rinnai Tankless Gas manuals
INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('RUR199iN',           'owners_manual',       'Rinnai SENSEI RUR199i Installation & Operation Manual',   'https://media.rinnai.us/salsify_asset/s-bb57a000-5f48-4159-ac3c-47e47f8180f7/100000467-N%20Series%20Residential%20Condensing%20Installation%20and%20Operation%20Manual.pdf'),
  ('RUR199iN',           'installation_guide',  'Rinnai SENSEI RUR199i Installation Guide',                'https://media.rinnai.us/salsify_asset/s-bb57a000-5f48-4159-ac3c-47e47f8180f7/100000467-N%20Series%20Residential%20Condensing%20Installation%20and%20Operation%20Manual.pdf'),
  ('RUR199iP',           'owners_manual',       'Rinnai SENSEI RUR199i (LP) Installation & Operation',     'https://media.rinnai.us/salsify_asset/s-bb57a000-5f48-4159-ac3c-47e47f8180f7/100000467-N%20Series%20Residential%20Condensing%20Installation%20and%20Operation%20Manual.pdf'),
  ('RU199iN',            'owners_manual',       'Rinnai SENSEI RU199i Installation & Operation Manual',    'https://media.rinnai.us/salsify_asset/s-5dcde422-3307-426c-ab15-29ecd56cac15/100000839%20SENSEI%20RX%20Residential%20Installation%20and%20Operation%20Manual.pdf'),
  ('RU199iN',            'installation_guide',  'Rinnai SENSEI RU199i Installation Guide',                 'https://media.rinnai.us/salsify_asset/s-5dcde422-3307-426c-ab15-29ecd56cac15/100000839%20SENSEI%20RX%20Residential%20Installation%20and%20Operation%20Manual.pdf'),
  ('RU199iP',            'owners_manual',       'Rinnai SENSEI RU199i (LP) Installation & Operation',      'https://media.rinnai.us/salsify_asset/s-5dcde422-3307-426c-ab15-29ecd56cac15/100000839%20SENSEI%20RX%20Residential%20Installation%20and%20Operation%20Manual.pdf'),
  ('RU180iN',            'owners_manual',       'Rinnai SENSEI RU180i Installation & Operation Manual',    'https://media.rinnai.us/salsify_asset/s-5dcde422-3307-426c-ab15-29ecd56cac15/100000839%20SENSEI%20RX%20Residential%20Installation%20and%20Operation%20Manual.pdf'),
  ('RU160iN',            'owners_manual',       'Rinnai SENSEI RU160i Installation & Operation Manual',    'https://media.rinnai.us/salsify_asset/s-5dcde422-3307-426c-ab15-29ecd56cac15/100000839%20SENSEI%20RX%20Residential%20Installation%20and%20Operation%20Manual.pdf'),
  ('RU130iN',            'owners_manual',       'Rinnai SENSEI RU130i Installation & Operation Manual',    'https://media.rinnai.us/salsify_asset/s-5dcde422-3307-426c-ab15-29ecd56cac15/100000839%20SENSEI%20RX%20Residential%20Installation%20and%20Operation%20Manual.pdf'),
  ('V75iN',              'owners_manual',       'Rinnai V75i Non-Condensing Installation & Operation',     'https://media.rinnai.us/salsify_asset/s-d8dba17e-35c3-45d7-8953-8d3ce916df8d/100000244-VC%20Installation%20and%20Operation%20Manual.pdf'),
  ('V75iN',              'installation_guide',  'Rinnai V75i Installation Guide',                          'https://media.rinnai.us/salsify_asset/s-d8dba17e-35c3-45d7-8953-8d3ce916df8d/100000244-VC%20Installation%20and%20Operation%20Manual.pdf'),
  ('V75eN',              'owners_manual',       'Rinnai V75e Outdoor Installation & Operation Manual',     'https://media.rinnai.us/salsify_asset/s-65ec5737-4726-4c1a-beb2-341cdbcb2561/100000561-V53De%20Installation%20and%20Operation%20Manual.pdf'),
  ('V65iN',              'owners_manual',       'Rinnai V65i Non-Condensing Installation & Operation',     'https://media.rinnai.us/salsify_asset/s-d8dba17e-35c3-45d7-8953-8d3ce916df8d/100000244-VC%20Installation%20and%20Operation%20Manual.pdf'),
  ('V53DeN',             'owners_manual',       'Rinnai V53De Outdoor Installation & Operation Manual',    'https://media.rinnai.us/salsify_asset/s-65ec5737-4726-4c1a-beb2-341cdbcb2561/100000561-V53De%20Installation%20and%20Operation%20Manual.pdf'),
  ('V53DeN',             'installation_guide',  'Rinnai V53De Outdoor Installation Guide',                 'https://media.rinnai.us/salsify_asset/s-65ec5737-4726-4c1a-beb2-341cdbcb2561/100000561-V53De%20Installation%20and%20Operation%20Manual.pdf'),
  ('RSC160iN',           'owners_manual',       'Rinnai RSC160i Condensing Owner''s Manual',               'https://www.rinnai.us/professional/document-library?model=RSC160iN'),
  ('RHS199iN',           'owners_manual',       'Rinnai RHS199i Hybrid Tank-Tankless Owner''s Manual',     'https://media.rinnai.us/salsify_asset/s-53e7dd42-0ec5-464d-a63a-32e3684a43a8/100000319-RH180%20Installation%20and%20Operation%20Manual.pdf'),
  ('RHS160eN',           'owners_manual',       'Rinnai RHS160e Hybrid Tank-Tankless Owner''s Manual',     'https://media.rinnai.us/salsify_asset/s-53e7dd42-0ec5-464d-a63a-32e3684a43a8/100000319-RH180%20Installation%20and%20Operation%20Manual.pdf'),
  ('REU-TE2428FFUD-US', 'owners_manual',       'Rinnai REU-TE2428 Commercial Owner''s Manual',            'https://www.rinnai.us/professional/document-library?model=REU-TE2428FFUD-US')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- ======================== WATER HEATERS — NAVIEN ========================

-- Navien Tankless manuals
INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('NPE-2S',        'owners_manual',       'Navien NPE-2S Condensing Tankless Owner''s Manual',          'https://www.navieninc.com/downloads/npe-user-s-information-manual-en'),
  ('NPE-2S',        'installation_guide',  'Navien NPE-2S Condensing Tankless Installation Manual',      'https://www.navieninc.com/downloads/npe-installation-manual-en'),
  ('NPE-2S-LP',     'owners_manual',       'Navien NPE-2S (LP) Condensing Tankless Owner''s Manual',     'https://www.navieninc.com/downloads/npe-user-s-information-manual-en'),
  ('NPE-A2',        'owners_manual',       'Navien NPE-A2 Premium Condensing Owner''s Manual',           'https://www.navieninc.com/downloads/npe-user-s-information-manual-en'),
  ('NPE-A2',        'installation_guide',  'Navien NPE-A2 Premium Condensing Installation Manual',       'https://www.navieninc.com/downloads/npe-installation-manual-en'),
  ('NPE-240A2',     'owners_manual',       'Navien NPE-240A2 Owner''s Manual',                           'https://www.navieninc.com/products/npe-240a/downloads'),
  ('NPE-240S2',     'owners_manual',       'Navien NPE-240S2 Owner''s Manual',                           'https://www.navieninc.com/downloads/npe-user-s-information-manual-en'),
  ('NPE-180S2',     'owners_manual',       'Navien NPE-180S2 Owner''s Manual',                           'https://www.navieninc.com/downloads/npe-user-s-information-manual-en'),
  ('NPE-150S2',     'owners_manual',       'Navien NPE-150S2 Owner''s Manual',                           'https://www.navieninc.com/downloads/npe-user-s-information-manual-en'),
  ('NPE-E-24',      'owners_manual',       'Navien NPE-E Tankless Electric Owner''s Manual',             'https://www.navieninc.com/downloads'),
  ('NPE-E-36',      'owners_manual',       'Navien NPE-E Tankless Electric Owner''s Manual',             'https://www.navieninc.com/downloads'),
  ('NPE-G50',       'owners_manual',       'Navien NPE-G Tank-Tankless Hybrid Owner''s Manual',          'https://www.navieninc.com/downloads'),
  ('NPE-G50',       'installation_guide',  'Navien NPE-G Tank-Tankless Hybrid Installation Manual',      'https://www.navieninc.com/downloads'),
  ('NPE-G75',       'owners_manual',       'Navien NPE-G Tank-Tankless Hybrid Owner''s Manual',          'https://www.navieninc.com/downloads'),
  ('NCB-240E',      'owners_manual',       'Navien NCB-240E Combi Boiler Owner''s Manual',               'https://us.navien.com/__DATA/ProductDocument/2015/10/7/NCB_User_Information_Manual_Eng.pdf'),
  ('NCB-240E',      'installation_guide',  'Navien NCB-240E Combi Boiler Installation Manual',           'https://www.navieninc.com/downloads/ncb-e-manuals-installation-manual-en'),
  ('NCB-180E',      'owners_manual',       'Navien NCB-180E Combi Boiler Owner''s Manual',               'https://us.navien.com/__DATA/ProductDocument/2015/10/7/NCB_User_Information_Manual_Eng.pdf'),
  ('NCB-240E-LP',   'owners_manual',       'Navien NCB-240E (LP) Combi Boiler Owner''s Manual',          'https://us.navien.com/__DATA/ProductDocument/2015/10/7/NCB_User_Information_Manual_Eng.pdf')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- ======================== WATER HEATERS — NORITZ ========================

-- Noritz Tankless manuals
INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('NRCR111DV-NG',  'owners_manual',       'Noritz NRCR111 Condensing Tankless Owner''s Guide',          'http://support-legacy.noritz.com/download.php?file=Literature+Page/Owners+Guide/NRC1111+OG.pdf&field=OwnersGuide'),
  ('NRCR111DV-NG',  'installation_guide',  'Noritz NRCR111 Condensing Tankless Installation Manual',     'https://noritz.com/manuals?model=NRCR111DV-NG'),
  ('NRCR111DV-LP',  'owners_manual',       'Noritz NRCR111 (LP) Condensing Owner''s Guide',              'http://support-legacy.noritz.com/download.php?file=Literature+Page/Owners+Guide/NRC1111+OG.pdf&field=OwnersGuide'),
  ('NRC111-DV-NG',  'owners_manual',       'Noritz NRC111 Condensing Tankless Owner''s Guide',           'http://support-legacy.noritz.com/download.php?file=Literature+Page/Owners+Guide/NRC661+OG.pdf&field=OwnersGuide'),
  ('NRC111-DV-NG',  'installation_guide',  'Noritz NRC111 Condensing Installation Manual',               'https://noritz.com/manuals?model=NRC111-DV-NG'),
  ('NRC98-DV-NG',   'owners_manual',       'Noritz NRC98 Condensing Tankless Owner''s Guide',            'http://support-legacy.noritz.com/download.php?file=Literature+Page/Owners+Guide/NRC661+OG.pdf&field=OwnersGuide'),
  ('NRC98-DV-NG',   'installation_guide',  'Noritz NRC98 Installation Manual',                           'https://noritz.com/manuals?model=NRC98-DV-NG'),
  ('NRC98-DV-LP',   'owners_manual',       'Noritz NRC98 (LP) Condensing Tankless Owner''s Guide',       'http://support-legacy.noritz.com/download.php?file=Literature+Page/Owners+Guide/NRC661+OG.pdf&field=OwnersGuide'),
  ('NRCB199DV-NG',  'owners_manual',       'Noritz NRCB199 Combi Boiler Owner''s Guide',                 'http://support-legacy.noritz.com/download.php?file=Literature+Page/Owners+Guide/NC199DVC+OG.pdf&field=OwnersGuide'),
  ('NRCB199DV-NG',  'installation_guide',  'Noritz NRCB199 Combi Boiler Installation Manual',            'https://noritz.com/manuals?model=NRCB199DV-NG'),
  ('NR83-DV-NG',    'owners_manual',       'Noritz NR83 Non-Condensing Owner''s Guide',                  'http://support-legacy.noritz.com/download.php?file=Literature+Page/Owners+Guide/NR981+OG.pdf&field=OwnersGuide'),
  ('NR83-DV-NG',    'installation_guide',  'Noritz NR83 Non-Condensing Installation Manual',             'http://support-legacy.noritz.com/download.php?file=Literature+Page/Installation+Manual/NR83DVC+IM.PDF&field=InstallationManual'),
  ('NR66-OD-NG',    'owners_manual',       'Noritz NR66 Outdoor Owner''s Guide',                         'https://noritz.com/manuals?model=NR66-OD-NG'),
  ('NR501-OD-NG',   'owners_manual',       'Noritz NR501 Outdoor Compact Owner''s Guide',                'https://noritz.com/manuals?model=NR501-OD-NG')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;
