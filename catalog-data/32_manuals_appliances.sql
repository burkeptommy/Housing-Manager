SET ROLE postgres;
-- ============================================================================
-- Equipment Manuals: Kitchen, Laundry, Bathroom, Pool, and Generator Brands
-- 17 brands, 100+ manual entries
-- Manual types: owners_manual, installation_guide, spec_sheet
-- ============================================================================


-- ============================================================================
-- KITCHEN BRANDS
-- ============================================================================

-- ======================== SUB-ZERO ========================

INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('CL4850UFD',   'owners_manual',      'Use & Care Guide',         'https://www.subzero-wolf.com/assistance/manuals'),
  ('CL4850UFD',   'installation_guide',  'Installation Guide',       'https://www.subzero-wolf.com/assistance/installation'),
  ('CL4850UFD',   'spec_sheet',          'Specification Sheet',      'https://www.subzero-wolf.com/sub-zero/full-size-refrigeration/builtin-refrigerators'),
  ('CL3650UFD',   'owners_manual',      'Use & Care Guide',         'https://www.subzero-wolf.com/assistance/manuals'),
  ('CL3650UFD',   'installation_guide',  'Installation Guide',       'https://www.subzero-wolf.com/assistance/installation'),
  ('DET3650CIID', 'owners_manual',      'Use & Care Guide',         'https://www.subzero-wolf.com/assistance/manuals'),
  ('DET3650CIID', 'installation_guide',  'Installation Guide',       'https://www.subzero-wolf.com/assistance/installation'),
  ('DEC3650RID',  'owners_manual',      'Use & Care Guide',         'https://www.subzero-wolf.com/assistance/manuals'),
  ('DEC3650RID',  'spec_sheet',          'Specification Sheet',      'https://www.subzero-wolf.com/sub-zero/full-size-refrigeration/integrated-fridges')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- ======================== WOLF ========================

INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('DF36650',  'owners_manual',      'Use & Care Guide',         'https://www.subzero-wolf.com/assistance/manuals'),
  ('DF36650',  'installation_guide',  'Installation Guide',       'https://www.subzero-wolf.com/assistance/installation'),
  ('DF36650',  'spec_sheet',          'Specification Sheet',      'https://www.subzero-wolf.com/wolf/ranges'),
  ('DF48650',  'owners_manual',      'Use & Care Guide',         'https://www.subzero-wolf.com/assistance/manuals'),
  ('DF48650',  'installation_guide',  'Installation Guide',       'https://www.subzero-wolf.com/assistance/installation'),
  ('GR366',    'owners_manual',      'Use & Care Guide',         'https://www.subzero-wolf.com/assistance/manuals'),
  ('GR366',    'installation_guide',  'Installation Guide',       'https://www.subzero-wolf.com/assistance/installation'),
  ('SO30TE',   'owners_manual',      'Use & Care Guide',         'https://www.subzero-wolf.com/assistance/manuals'),
  ('SO30TE',   'installation_guide',  'Installation Guide',       'https://www.subzero-wolf.com/assistance/installation'),
  ('DO30TE',   'owners_manual',      'Use & Care Guide',         'https://www.subzero-wolf.com/assistance/manuals'),
  ('CSO3050PE','owners_manual',      'Use & Care Guide',         'https://www.subzero-wolf.com/assistance/manuals')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- ======================== COVE ========================

INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('DW2450',   'owners_manual',      'Use & Care Guide',         'https://www.subzero-wolf.com/assistance/manuals'),
  ('DW2450',   'installation_guide',  'Installation Guide',       'https://www.subzero-wolf.com/assistance/installation'),
  ('DW2450',   'spec_sheet',          'Specification Sheet',      'https://www.subzero-wolf.com/cove/dishwashers'),
  ('DW2450WS', 'owners_manual',      'Use & Care Guide',         'https://www.subzero-wolf.com/assistance/manuals'),
  ('DW2450WS', 'installation_guide',  'Installation Guide',       'https://www.subzero-wolf.com/assistance/installation')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- ======================== SAMSUNG ========================

INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  -- Refrigerators
  ('RF29DB9900QDAA',  'owners_manual',      'Owner''s Manual',     'https://downloadcenter.samsung.com/content/UM/202401/20240110/RF29DB9900QD_AA_OM_EN.pdf'),
  ('RF29DB9900QDAA',  'installation_guide',  'Installation Guide',  'https://downloadcenter.samsung.com/content/UM/202401/20240110/RF29DB9900QD_AA_IG_EN.pdf'),
  ('RF29DB9600QLAA',  'owners_manual',      'Owner''s Manual',     'https://downloadcenter.samsung.com/content/UM/202401/RF29DB9600QL_AA_OM_EN.pdf'),
  ('RF23DB9750QLAA',  'owners_manual',      'Owner''s Manual',     'https://downloadcenter.samsung.com/content/UM/202401/RF23DB9750QL_AA_OM_EN.pdf'),
  ('RF32CG5900SRAA',  'owners_manual',      'Owner''s Manual',     'https://downloadcenter.samsung.com/content/UM/202310/RF32CG5900SR_AA_OM_EN.pdf'),
  -- Ranges
  ('NSI6DB990012AA',  'owners_manual',      'Owner''s Manual',     'https://downloadcenter.samsung.com/content/UM/202401/NSI6DB990012_AA_OM_EN.pdf'),
  ('NSI6DB990012AA',  'installation_guide',  'Installation Guide',  'https://downloadcenter.samsung.com/content/UM/202401/NSI6DB990012_AA_IG_EN.pdf'),
  ('NSE6DB870012AA',  'owners_manual',      'Owner''s Manual',     'https://downloadcenter.samsung.com/content/UM/202401/NSE6DB870012_AA_OM_EN.pdf'),
  ('NSG6DB870012AA',  'owners_manual',      'Owner''s Manual',     'https://downloadcenter.samsung.com/content/UM/202401/NSG6DB870012_AA_OM_EN.pdf'),
  -- Dishwashers
  ('DW90F89P0USRAA',  'owners_manual',      'Owner''s Manual',     'https://downloadcenter.samsung.com/content/UM/202401/DW90F89P0USR_AA_OM_EN.pdf'),
  ('DW80B7070US-AA',  'owners_manual',      'Owner''s Manual',     'https://downloadcenter.samsung.com/content/UM/202301/DW80B7070US_AA_OM_EN.pdf'),
  ('DW80B7070US-AA',  'installation_guide',  'Installation Guide',  'https://downloadcenter.samsung.com/content/UM/202301/DW80B7070US_AA_IG_EN.pdf')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- ======================== LG ========================

INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  -- Refrigerators
  ('LRFGC2706S',  'owners_manual',      'Owner''s Manual',     'https://www.lg.com/us/support/products/lg-LRFGC2706S.html#manuals'),
  ('LRFGC2706S',  'installation_guide',  'Installation Guide',  'https://www.lg.com/us/support/products/lg-LRFGC2706S.html#manuals'),
  ('LMXS28626S',  'owners_manual',      'Owner''s Manual',     'https://www.lg.com/us/support/products/lg-LMXS28626S.html#manuals'),
  -- Ranges
  ('LREL6325F',   'owners_manual',      'Owner''s Manual',     'https://www.lg.com/us/support/products/lg-LREL6325F.html#manuals'),
  ('LREL6325F',   'installation_guide',  'Installation Guide',  'https://www.lg.com/us/support/products/lg-LREL6325F.html#manuals'),
  ('LSEL6335F',   'owners_manual',      'Owner''s Manual',     'https://www.lg.com/us/support/products/lg-LSEL6335F.html#manuals'),
  ('LSGL6335F',   'owners_manual',      'Owner''s Manual',     'https://www.lg.com/us/support/products/lg-LSGL6335F.html#manuals'),
  -- Wall Ovens
  ('WSEP4727F',   'owners_manual',      'Owner''s Manual',     'https://www.lg.com/us/support/products/lg-WSEP4727F.html#manuals'),
  ('WSEP4727F',   'installation_guide',  'Installation Guide',  'https://www.lg.com/us/support/products/lg-WSEP4727F.html#manuals'),
  ('WDEP9427F',   'owners_manual',      'Owner''s Manual',     'https://www.lg.com/us/support/products/lg-WDEP9427F.html#manuals')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- ======================== WHIRLPOOL ========================

INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('WRF560SEHZ',  'owners_manual',      'Owner''s Manual',     'https://www.whirlpool.com/support/product-help/search.html?q=WRF560SEHZ'),
  ('WRF560SEHZ',  'installation_guide',  'Installation Guide',  'https://www.whirlpool.com/support/product-help/search.html?q=WRF560SEHZ'),
  ('WDT750SAHZ',  'owners_manual',      'Owner''s Manual',     'https://www.whirlpool.com/support/product-help/search.html?q=WDT750SAHZ'),
  ('WDT750SAHZ',  'installation_guide',  'Installation Guide',  'https://www.whirlpool.com/support/product-help/search.html?q=WDT750SAHZ'),
  ('WFG505M0MS',  'owners_manual',      'Owner''s Manual',     'https://www.whirlpool.com/support/product-help/search.html?q=WFG505M0MS'),
  ('WFE505W0JZ',  'owners_manual',      'Owner''s Manual',     'https://www.whirlpool.com/support/product-help/search.html?q=WFE505W0JZ'),
  ('WMH31017HS',  'owners_manual',      'Owner''s Manual',     'https://www.whirlpool.com/support/product-help/search.html?q=WMH31017HS')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- ======================== MAYTAG ========================

INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('MFI2570FEZ',  'owners_manual',      'Owner''s Manual',     'https://www.maytag.com/support/product-help/search.html?q=MFI2570FEZ'),
  ('MFI2570FEZ',  'installation_guide',  'Installation Guide',  'https://www.maytag.com/support/product-help/search.html?q=MFI2570FEZ'),
  ('MFES6030RZ',  'owners_manual',      'Owner''s Manual',     'https://www.maytag.com/support/product-help/search.html?q=MFES6030RZ'),
  ('MFGS6030RZ',  'owners_manual',      'Owner''s Manual',     'https://www.maytag.com/support/product-help/search.html?q=MFGS6030RZ'),
  ('MDB8959SKZ',  'owners_manual',      'Owner''s Manual',     'https://www.maytag.com/support/product-help/search.html?q=MDB8959SKZ'),
  ('MDB8959SKZ',  'installation_guide',  'Installation Guide',  'https://www.maytag.com/support/product-help/search.html?q=MDB8959SKZ')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- ======================== KITCHENAID ========================

INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('KRFC300ESS',  'owners_manual',      'Owner''s Manual',     'https://www.kitchenaid.com/support/product-help/search.html?q=KRFC300ESS'),
  ('KRFC300ESS',  'installation_guide',  'Installation Guide',  'https://www.kitchenaid.com/support/product-help/search.html?q=KRFC300ESS'),
  ('KDTE204KPS',  'owners_manual',      'Owner''s Manual',     'https://www.kitchenaid.com/support/product-help/search.html?q=KDTE204KPS'),
  ('KDTE204KPS',  'installation_guide',  'Installation Guide',  'https://www.kitchenaid.com/support/product-help/search.html?q=KDTE204KPS'),
  ('KSEG700ESS',  'owners_manual',      'Owner''s Manual',     'https://www.kitchenaid.com/support/product-help/search.html?q=KSEG700ESS'),
  ('KSEG950ESS',  'owners_manual',      'Owner''s Manual',     'https://www.kitchenaid.com/support/product-help/search.html?q=KSEG950ESS'),
  ('KMHC319LSS',  'owners_manual',      'Owner''s Manual',     'https://www.kitchenaid.com/support/product-help/search.html?q=KMHC319LSS')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- ======================== GE APPLIANCES / GE PROFILE / CAFE ========================

INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  -- GE Base
  ('GFE26JYMFS',  'owners_manual',      'Owner''s Manual',     'https://products.geappliances.com/MarketingObjectRetrieval/Dispatcher?RequestType=PDF&Name=GFE26JYMFS-OwnersManual.pdf'),
  ('GFE26JYMFS',  'installation_guide',  'Installation Guide',  'https://products.geappliances.com/MarketingObjectRetrieval/Dispatcher?RequestType=PDF&Name=GFE26JYMFS-InstallGuide.pdf'),
  ('GDT550PYRFS', 'owners_manual',      'Owner''s Manual',     'https://products.geappliances.com/MarketingObjectRetrieval/Dispatcher?RequestType=PDF&Name=GDT550PYRFS-OwnersManual.pdf'),
  ('GDT670SYVFS', 'owners_manual',      'Owner''s Manual',     'https://products.geappliances.com/MarketingObjectRetrieval/Dispatcher?RequestType=PDF&Name=GDT670SYVFS-OwnersManual.pdf'),
  ('JGB735SPSS',  'owners_manual',      'Owner''s Manual',     'https://products.geappliances.com/MarketingObjectRetrieval/Dispatcher?RequestType=PDF&Name=JGB735SPSS-OwnersManual.pdf'),
  ('JGB735SPSS',  'installation_guide',  'Installation Guide',  'https://products.geappliances.com/MarketingObjectRetrieval/Dispatcher?RequestType=PDF&Name=JGB735SPSS-InstallGuide.pdf'),
  -- GE Profile
  ('PVD28BYNFS',  'owners_manual',      'Owner''s Manual',     'https://products.geappliances.com/MarketingObjectRetrieval/Dispatcher?RequestType=PDF&Name=PVD28BYNFS-OwnersManual.pdf'),
  ('PVD28BYNFS',  'installation_guide',  'Installation Guide',  'https://products.geappliances.com/MarketingObjectRetrieval/Dispatcher?RequestType=PDF&Name=PVD28BYNFS-InstallGuide.pdf'),
  ('PDT715SYNFS', 'owners_manual',      'Owner''s Manual',     'https://products.geappliances.com/MarketingObjectRetrieval/Dispatcher?RequestType=PDF&Name=PDT715SYNFS-OwnersManual.pdf'),
  ('PGS930YPFS',  'owners_manual',      'Owner''s Manual',     'https://products.geappliances.com/MarketingObjectRetrieval/Dispatcher?RequestType=PDF&Name=PGS930YPFS-OwnersManual.pdf'),
  ('PHS930YPFS',  'owners_manual',      'Owner''s Manual',     'https://products.geappliances.com/MarketingObjectRetrieval/Dispatcher?RequestType=PDF&Name=PHS930YPFS-OwnersManual.pdf'),
  -- Cafe
  ('CYE22TP3MD1', 'owners_manual',      'Owner''s Manual',     'https://products.geappliances.com/MarketingObjectRetrieval/Dispatcher?RequestType=PDF&Name=CYE22TP3MD1-OwnersManual.pdf'),
  ('CGS750P3MD1', 'owners_manual',      'Owner''s Manual',     'https://products.geappliances.com/MarketingObjectRetrieval/Dispatcher?RequestType=PDF&Name=CGS750P3MD1-OwnersManual.pdf'),
  ('CHS950P3MD1', 'owners_manual',      'Owner''s Manual',     'https://products.geappliances.com/MarketingObjectRetrieval/Dispatcher?RequestType=PDF&Name=CHS950P3MD1-OwnersManual.pdf'),
  ('CDT875P3ND1', 'owners_manual',      'Owner''s Manual',     'https://products.geappliances.com/MarketingObjectRetrieval/Dispatcher?RequestType=PDF&Name=CDT875P3ND1-OwnersManual.pdf'),
  ('CDT875P3ND1', 'installation_guide',  'Installation Guide',  'https://products.geappliances.com/MarketingObjectRetrieval/Dispatcher?RequestType=PDF&Name=CDT875P3ND1-InstallGuide.pdf'),
  ('CTS90DP3ND1', 'owners_manual',      'Owner''s Manual',     'https://products.geappliances.com/MarketingObjectRetrieval/Dispatcher?RequestType=PDF&Name=CTS90DP3ND1-OwnersManual.pdf')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- ======================== BOSCH ========================

INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  -- Dishwashers
  ('SHP78CM5N',   'owners_manual',      'Owner''s Manual',     'https://www.bosch-home.com/us/support/product-detail/SHP78CM5N#instruction-manuals'),
  ('SHP78CM5N',   'installation_guide',  'Installation Guide',  'https://www.bosch-home.com/us/support/product-detail/SHP78CM5N#instruction-manuals'),
  ('SHP78CM5N',   'spec_sheet',          'Specification Sheet', 'https://www.bosch-home.com/us/support/product-detail/SHP78CM5N#specification-documents'),
  ('SHP65CM5N',   'owners_manual',      'Owner''s Manual',     'https://www.bosch-home.com/us/support/product-detail/SHP65CM5N#instruction-manuals'),
  ('SHP65CM5N',   'installation_guide',  'Installation Guide',  'https://www.bosch-home.com/us/support/product-detail/SHP65CM5N#instruction-manuals'),
  ('SHP9PCM5N',   'owners_manual',      'Owner''s Manual',     'https://www.bosch-home.com/us/support/product-detail/SHP9PCM5N#instruction-manuals'),
  ('SHE41CM5N',   'owners_manual',      'Owner''s Manual',     'https://www.bosch-home.com/us/support/product-detail/SHE41CM5N#instruction-manuals'),
  -- Wall Ovens
  ('HBL8651UC',   'owners_manual',      'Owner''s Manual',     'https://www.bosch-home.com/us/support/product-detail/HBL8651UC#instruction-manuals'),
  ('HBL8651UC',   'installation_guide',  'Installation Guide',  'https://www.bosch-home.com/us/support/product-detail/HBL8651UC#instruction-manuals'),
  ('HBL8453UC',   'owners_manual',      'Owner''s Manual',     'https://www.bosch-home.com/us/support/product-detail/HBL8453UC#instruction-manuals'),
  -- Cooktops
  ('NGM8059UC',   'owners_manual',      'Owner''s Manual',     'https://www.bosch-home.com/us/support/product-detail/NGM8059UC#instruction-manuals'),
  ('NGM8059UC',   'installation_guide',  'Installation Guide',  'https://www.bosch-home.com/us/support/product-detail/NGM8059UC#instruction-manuals'),
  ('NIT8060SUC',  'owners_manual',      'Owner''s Manual',     'https://www.bosch-home.com/us/support/product-detail/NIT8060SUC#instruction-manuals')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- ======================== MIELE ========================

INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  -- Dishwashers
  ('G7166SCVI',    'owners_manual',      'Operating Instructions', 'https://www.mieleusa.com/e/operating-instructions-G7166SCVI'),
  ('G7166SCVI',    'installation_guide',  'Installation Guide',    'https://www.mieleusa.com/e/installation-instructions-G7166SCVI'),
  ('G7316SCUXXL',  'owners_manual',      'Operating Instructions', 'https://www.mieleusa.com/e/operating-instructions-G7316SCUXXL'),
  ('G7566SCVISF',  'owners_manual',      'Operating Instructions', 'https://www.mieleusa.com/e/operating-instructions-G7566SCVISF'),
  ('G7966SCVI',    'owners_manual',      'Operating Instructions', 'https://www.mieleusa.com/e/operating-instructions-G7966SCVI'),
  ('G7986SCVIK2O', 'owners_manual',      'Operating Instructions', 'https://www.mieleusa.com/e/operating-instructions-G7986SCVIK2O'),
  -- Combi-Steam Oven
  ('DGC7860CTS',   'owners_manual',      'Operating Instructions', 'https://www.mieleusa.com/e/operating-instructions-DGC7860CTS'),
  ('DGC7860CTS',   'installation_guide',  'Installation Guide',    'https://www.mieleusa.com/e/installation-instructions-DGC7860CTS'),
  -- Coffee Machines
  ('CVA7440',      'owners_manual',      'Operating Instructions', 'https://www.mieleusa.com/e/operating-instructions-CVA7440'),
  ('CVA7845',      'owners_manual',      'Operating Instructions', 'https://www.mieleusa.com/e/operating-instructions-CVA7845')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;


-- ============================================================================
-- LAUNDRY BRANDS
-- ============================================================================

-- ======================== SPEED QUEEN ========================

INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('TC5003WN',  'owners_manual',      'Owner''s Manual',     'https://www.speedqueen.com/support/manuals/?model=TC5003WN'),
  ('TC5003WN',  'installation_guide',  'Installation Guide',  'https://www.speedqueen.com/support/manuals/?model=TC5003WN'),
  ('TR3003WN',  'owners_manual',      'Owner''s Manual',     'https://www.speedqueen.com/support/manuals/?model=TR3003WN'),
  ('TR5003WN',  'owners_manual',      'Owner''s Manual',     'https://www.speedqueen.com/support/manuals/?model=TR5003WN'),
  ('TR7003WN',  'owners_manual',      'Owner''s Manual',     'https://www.speedqueen.com/support/manuals/?model=TR7003WN'),
  ('TR7003WN',  'installation_guide',  'Installation Guide',  'https://www.speedqueen.com/support/manuals/?model=TR7003WN'),
  ('FF7005WN',  'owners_manual',      'Owner''s Manual',     'https://www.speedqueen.com/support/manuals/?model=FF7005WN'),
  ('FF7005WN',  'installation_guide',  'Installation Guide',  'https://www.speedqueen.com/support/manuals/?model=FF7005WN'),
  ('DC5003WE',  'owners_manual',      'Owner''s Manual',     'https://www.speedqueen.com/support/manuals/?model=DC5003WE'),
  ('DR5004WE',  'owners_manual',      'Owner''s Manual',     'https://www.speedqueen.com/support/manuals/?model=DR5004WE'),
  ('DR7004WE',  'owners_manual',      'Owner''s Manual',     'https://www.speedqueen.com/support/manuals/?model=DR7004WE'),
  ('DR7004WE',  'installation_guide',  'Installation Guide',  'https://www.speedqueen.com/support/manuals/?model=DR7004WE')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- ======================== ELECTROLUX ========================

INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('ECFD3668AS',  'owners_manual',      'Owner''s Manual',     'https://www.electrolux.com/us/support/product-support/?model=ECFD3668AS'),
  ('ECFD3668AS',  'installation_guide',  'Installation Guide',  'https://www.electrolux.com/us/support/product-support/?model=ECFD3668AS'),
  ('ERMC2295AS',  'owners_manual',      'Owner''s Manual',     'https://www.electrolux.com/us/support/product-support/?model=ERMC2295AS'),
  ('ECWS3012AS',  'owners_manual',      'Owner''s Manual',     'https://www.electrolux.com/us/support/product-support/?model=ECWS3012AS'),
  ('ECWS3012AS',  'installation_guide',  'Installation Guide',  'https://www.electrolux.com/us/support/product-support/?model=ECWS3012AS')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;


-- ============================================================================
-- BATHROOM BRANDS
-- ============================================================================

-- ======================== KOHLER ========================

INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  -- Toilets
  ('K-3999',   'owners_manual',      'Owner''s Manual',       'https://www.us.kohler.com/webassets/kpna/catalog/pdf/en/K-3999_spec.pdf'),
  ('K-3999',   'installation_guide',  'Installation Guide',    'https://www.us.kohler.com/webassets/kpna/catalog/pdf/en/K-3999_install.pdf'),
  ('K-3999',   'spec_sheet',          'Specification Sheet',   'https://www.us.kohler.com/webassets/kpna/catalog/pdf/en/K-3999_spec.pdf'),
  ('K-3609',   'owners_manual',      'Owner''s Manual',       'https://www.us.kohler.com/webassets/kpna/catalog/pdf/en/K-3609_spec.pdf'),
  ('K-3609',   'installation_guide',  'Installation Guide',    'https://www.us.kohler.com/webassets/kpna/catalog/pdf/en/K-3609_install.pdf'),
  ('K-3810',   'owners_manual',      'Owner''s Manual',       'https://www.us.kohler.com/webassets/kpna/catalog/pdf/en/K-3810_spec.pdf'),
  ('K-3810',   'installation_guide',  'Installation Guide',    'https://www.us.kohler.com/webassets/kpna/catalog/pdf/en/K-3810_install.pdf'),
  ('K-77780',  'owners_manual',      'Owner''s Manual',       'https://www.us.kohler.com/webassets/kpna/catalog/pdf/en/K-77780_spec.pdf'),
  ('K-6299',   'owners_manual',      'Owner''s Manual',       'https://www.us.kohler.com/webassets/kpna/catalog/pdf/en/K-6299_spec.pdf'),
  -- Faucets
  ('K-72218',  'spec_sheet',          'Specification Sheet',   'https://www.us.kohler.com/webassets/kpna/catalog/pdf/en/K-72218_spec.pdf'),
  ('K-72218',  'installation_guide',  'Installation Guide',    'https://www.us.kohler.com/webassets/kpna/catalog/pdf/en/K-72218_install.pdf'),
  -- Shower Systems
  ('K-22169',  'spec_sheet',          'Specification Sheet',   'https://www.us.kohler.com/webassets/kpna/catalog/pdf/en/K-22169_spec.pdf'),
  ('K-99105',  'owners_manual',      'Owner''s Manual',       'https://www.us.kohler.com/webassets/kpna/catalog/pdf/en/K-99105_spec.pdf'),
  ('K-99105',  'installation_guide',  'Installation Guide',    'https://www.us.kohler.com/webassets/kpna/catalog/pdf/en/K-99105_install.pdf'),
  -- Bathtubs
  ('K-1150',   'spec_sheet',          'Specification Sheet',   'https://www.us.kohler.com/webassets/kpna/catalog/pdf/en/K-1150_spec.pdf'),
  ('K-1150',   'installation_guide',  'Installation Guide',    'https://www.us.kohler.com/webassets/kpna/catalog/pdf/en/K-1150_install.pdf'),
  ('K-5701',   'spec_sheet',          'Specification Sheet',   'https://www.us.kohler.com/webassets/kpna/catalog/pdf/en/K-5701_spec.pdf'),
  -- Bidets
  ('K-31271',  'owners_manual',      'Owner''s Manual',       'https://www.us.kohler.com/webassets/kpna/catalog/pdf/en/K-31271_spec.pdf'),
  ('K-31271',  'installation_guide',  'Installation Guide',    'https://www.us.kohler.com/webassets/kpna/catalog/pdf/en/K-31271_install.pdf'),
  ('K-8298',   'owners_manual',      'Owner''s Manual',       'https://www.us.kohler.com/webassets/kpna/catalog/pdf/en/K-8298_spec.pdf')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- ======================== TOTO ========================

INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  -- Toilets
  ('MS604114CEFG',  'owners_manual',      'Owner''s Manual',     'https://www.totousa.com/media/product/specsheet/MS604114CEFG_OM.pdf'),
  ('MS604114CEFG',  'spec_sheet',          'Specification Sheet', 'https://www.totousa.com/media/product/specsheet/MS604114CEFG_spec.pdf'),
  ('MS604114CEFG',  'installation_guide',  'Installation Guide',  'https://www.totousa.com/media/product/specsheet/MS604114CEFG_install.pdf'),
  ('CST744EL',      'owners_manual',      'Owner''s Manual',     'https://www.totousa.com/media/product/specsheet/CST744EL_OM.pdf'),
  ('CST744EL',      'installation_guide',  'Installation Guide',  'https://www.totousa.com/media/product/specsheet/CST744EL_install.pdf'),
  ('MS642124CEFG',  'owners_manual',      'Owner''s Manual',     'https://www.totousa.com/media/product/specsheet/MS642124CEFG_OM.pdf'),
  ('MS446124CEMFG', 'owners_manual',      'Owner''s Manual',     'https://www.totousa.com/media/product/specsheet/MS446124CEMFG_OM.pdf'),
  ('MS920CEMFG',    'owners_manual',      'Owner''s Manual',     'https://www.totousa.com/media/product/specsheet/MS920CEMFG_OM.pdf'),
  ('MS8551CUMFG',   'owners_manual',      'Owner''s Manual',     'https://www.totousa.com/media/product/specsheet/MS8551CUMFG_OM.pdf'),
  -- Washlet / Bidet Seats
  ('SW3056',        'owners_manual',      'Owner''s Manual',     'https://www.totousa.com/media/product/specsheet/SW3056_OM.pdf'),
  ('SW3056',        'installation_guide',  'Installation Guide',  'https://www.totousa.com/media/product/specsheet/SW3056_install.pdf'),
  ('SW3074',        'owners_manual',      'Owner''s Manual',     'https://www.totousa.com/media/product/specsheet/SW3074_OM.pdf'),
  ('SW3074',        'installation_guide',  'Installation Guide',  'https://www.totousa.com/media/product/specsheet/SW3074_install.pdf'),
  -- Faucets
  ('TLG01301U',     'spec_sheet',          'Specification Sheet', 'https://www.totousa.com/media/product/specsheet/TLG01301U_spec.pdf'),
  ('TLG11201U',     'spec_sheet',          'Specification Sheet', 'https://www.totousa.com/media/product/specsheet/TLG11201U_spec.pdf')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- ======================== MOEN ========================

INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('6410',   'installation_guide',  'Installation Guide',    'https://www.moen.com/shared/docs/installation/6410_install.pdf'),
  ('6410',   'spec_sheet',          'Specification Sheet',   'https://www.moen.com/shared/docs/specsheets/6410_spec.pdf'),
  ('6903',   'installation_guide',  'Installation Guide',    'https://www.moen.com/shared/docs/installation/6903_install.pdf'),
  ('6903',   'spec_sheet',          'Specification Sheet',   'https://www.moen.com/shared/docs/specsheets/6903_spec.pdf'),
  ('6192',   'installation_guide',  'Installation Guide',    'https://www.moen.com/shared/docs/installation/6192_install.pdf'),
  ('T6620',  'installation_guide',  'Installation Guide',    'https://www.moen.com/shared/docs/installation/T6620_install.pdf'),
  ('T6620',  'spec_sheet',          'Specification Sheet',   'https://www.moen.com/shared/docs/specsheets/T6620_spec.pdf'),
  ('T2152',  'installation_guide',  'Installation Guide',    'https://www.moen.com/shared/docs/installation/T2152_install.pdf'),
  ('T2152',  'spec_sheet',          'Specification Sheet',   'https://www.moen.com/shared/docs/specsheets/T2152_spec.pdf'),
  ('6172',   'installation_guide',  'Installation Guide',    'https://www.moen.com/shared/docs/installation/6172_install.pdf')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- ======================== DELTA ========================

INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('559LF-MPU',      'installation_guide',  'Installation Guide',    'https://www.deltafaucet.com/service-parts/product/559LF-MPU'),
  ('559LF-MPU',      'spec_sheet',          'Specification Sheet',   'https://www.deltafaucet.com/service-parts/product/559LF-MPU'),
  ('3559-MPU-DST',   'installation_guide',  'Installation Guide',    'https://www.deltafaucet.com/service-parts/product/3559-MPU-DST'),
  ('3559-MPU-DST',   'spec_sheet',          'Specification Sheet',   'https://www.deltafaucet.com/service-parts/product/3559-MPU-DST'),
  ('2538-MPU-DST',   'installation_guide',  'Installation Guide',    'https://www.deltafaucet.com/service-parts/product/2538-MPU-DST'),
  ('T14238',         'installation_guide',  'Installation Guide',    'https://www.deltafaucet.com/service-parts/product/T14238'),
  ('T14238',         'spec_sheet',          'Specification Sheet',   'https://www.deltafaucet.com/service-parts/product/T14238'),
  ('T17459',         'installation_guide',  'Installation Guide',    'https://www.deltafaucet.com/service-parts/product/T17459'),
  ('C43901-WH',      'installation_guide',  'Installation Guide',    'https://www.deltafaucet.com/service-parts/product/C43901-WH'),
  ('C43901-WH',      'spec_sheet',          'Specification Sheet',   'https://www.deltafaucet.com/service-parts/product/C43901-WH')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;


-- ============================================================================
-- POOL BRANDS
-- ============================================================================

-- ======================== PENTAIR ========================

INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  -- Pumps
  ('011028',  'owners_manual',      'Owner''s Manual',     'https://www.pentair.com/content/dam/extranet/product-related/residential-pool/pumps/intelliflo-vsf/manual-intelliflo-vsf.pdf'),
  ('011028',  'installation_guide',  'Installation Guide',  'https://www.pentair.com/content/dam/extranet/product-related/residential-pool/pumps/intelliflo-vsf/install-intelliflo-vsf.pdf'),
  ('011056',  'owners_manual',      'Owner''s Manual',     'https://www.pentair.com/content/dam/extranet/product-related/residential-pool/pumps/intelliflo3-vsf/manual-intelliflo3-vsf.pdf'),
  ('011056',  'installation_guide',  'Installation Guide',  'https://www.pentair.com/content/dam/extranet/product-related/residential-pool/pumps/intelliflo3-vsf/install-intelliflo3-vsf.pdf'),
  ('340039',  'owners_manual',      'Owner''s Manual',     'https://www.pentair.com/content/dam/extranet/product-related/residential-pool/pumps/superflo-vs/manual-superflo-vs.pdf'),
  -- Filters
  ('160332',  'owners_manual',      'Owner''s Manual',     'https://www.pentair.com/content/dam/extranet/product-related/residential-pool/filters/clean-clear-plus/manual-clean-clear-plus.pdf'),
  ('160332',  'installation_guide',  'Installation Guide',  'https://www.pentair.com/content/dam/extranet/product-related/residential-pool/filters/clean-clear-plus/install-clean-clear-plus.pdf'),
  ('145240',  'owners_manual',      'Owner''s Manual',     'https://www.pentair.com/content/dam/extranet/product-related/residential-pool/filters/triton-ii/manual-triton-ii.pdf'),
  -- Heaters
  ('461021',  'owners_manual',      'Owner''s Manual',     'https://www.pentair.com/content/dam/extranet/product-related/residential-pool/heaters/mastertemp/manual-mastertemp.pdf'),
  ('461021',  'installation_guide',  'Installation Guide',  'https://www.pentair.com/content/dam/extranet/product-related/residential-pool/heaters/mastertemp/install-mastertemp.pdf')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- ======================== HAYWARD ========================

INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  -- Pumps
  ('W3SP3400VSP',  'owners_manual',      'Owner''s Manual',     'https://www.hayward.com/support/product-support/tristar-vs-950-omni-variable-speed-pump'),
  ('W3SP3400VSP',  'installation_guide',  'Installation Guide',  'https://www.hayward.com/support/product-support/tristar-vs-950-omni-variable-speed-pump'),
  ('W3SP2610X15',  'owners_manual',      'Owner''s Manual',     'https://www.hayward.com/support/product-support/super-pump'),
  ('W3SP26315VSP', 'owners_manual',      'Owner''s Manual',     'https://www.hayward.com/support/product-support/super-pump-vs-700-variable-speed-pump'),
  -- Filters
  ('C17502',       'owners_manual',      'Owner''s Manual',     'https://www.hayward.com/support/product-support/swimclear-cartridge-filters'),
  ('W3S310T2',     'owners_manual',      'Owner''s Manual',     'https://www.hayward.com/support/product-support/pro-series-sand-filter'),
  ('W3S310T2',     'installation_guide',  'Installation Guide',  'https://www.hayward.com/support/product-support/pro-series-sand-filter'),
  -- Heaters
  ('W3H400FDN',    'owners_manual',      'Owner''s Manual',     'https://www.hayward.com/support/product-support/universal-h-series-heater'),
  ('W3H400FDN',    'installation_guide',  'Installation Guide',  'https://www.hayward.com/support/product-support/universal-h-series-heater'),
  -- Salt Systems
  ('W3AQR15',      'owners_manual',      'Owner''s Manual',     'https://www.hayward.com/support/product-support/aquarite-s3-salt-chlorination-system'),
  ('W3AQR15',      'installation_guide',  'Installation Guide',  'https://www.hayward.com/support/product-support/aquarite-s3-salt-chlorination-system'),
  -- Automation
  ('HLX-PLUS',     'owners_manual',      'Owner''s Manual',     'https://www.hayward.com/support/product-support/omnilogic-smart-pool-and-spa-control'),
  ('HLX-PLUS',     'installation_guide',  'Installation Guide',  'https://www.hayward.com/support/product-support/omnilogic-smart-pool-and-spa-control')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;


-- ============================================================================
-- GENERATOR BRANDS
-- ============================================================================

-- ======================== GENERAC ========================

INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  -- Standby
  ('7290',  'owners_manual',      'Owner''s Manual',     'https://www.generac.com/service-support/product-support-lookup?modelNo=7290'),
  ('7290',  'installation_guide',  'Installation Guide',  'https://www.generac.com/service-support/product-support-lookup?modelNo=7290'),
  ('7042',  'owners_manual',      'Owner''s Manual',     'https://www.generac.com/service-support/product-support-lookup?modelNo=7042'),
  ('7042',  'installation_guide',  'Installation Guide',  'https://www.generac.com/service-support/product-support-lookup?modelNo=7042'),
  ('7228',  'owners_manual',      'Owner''s Manual',     'https://www.generac.com/service-support/product-support-lookup?modelNo=7228'),
  ('7171',  'owners_manual',      'Owner''s Manual',     'https://www.generac.com/service-support/product-support-lookup?modelNo=7171'),
  ('7226',  'owners_manual',      'Owner''s Manual',     'https://www.generac.com/service-support/product-support-lookup?modelNo=7226'),
  -- Portable
  ('7690',  'owners_manual',      'Owner''s Manual',     'https://www.generac.com/service-support/product-support-lookup?modelNo=7690'),
  ('7719',  'owners_manual',      'Owner''s Manual',     'https://www.generac.com/service-support/product-support-lookup?modelNo=7719'),
  -- Inverter
  ('7127',  'owners_manual',      'Owner''s Manual',     'https://www.generac.com/service-support/product-support-lookup?modelNo=7127'),
  ('7154',  'owners_manual',      'Owner''s Manual',     'https://www.generac.com/service-support/product-support-lookup?modelNo=7154')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;

-- ======================== HONDA POWER ========================

INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT ec.id, v.manual_type, v.title, v.source_url,
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/' || v.manual_type || '.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN (VALUES
  ('EU2200i',   'owners_manual',      'Owner''s Manual',     'https://powerequipment.honda.com/support/owners-manuals?model=EU2200i'),
  ('EU2200i',   'spec_sheet',          'Specification Sheet', 'https://powerequipment.honda.com/generators/models/EU2200i'),
  ('EU3000iS',  'owners_manual',      'Owner''s Manual',     'https://powerequipment.honda.com/support/owners-manuals?model=EU3000iS'),
  ('EU3000iS',  'spec_sheet',          'Specification Sheet', 'https://powerequipment.honda.com/generators/models/EU3000iS'),
  ('EU7000iS',  'owners_manual',      'Owner''s Manual',     'https://powerequipment.honda.com/support/owners-manuals?model=EU7000iS'),
  ('EU7000iS',  'spec_sheet',          'Specification Sheet', 'https://powerequipment.honda.com/generators/models/EU7000iS'),
  ('EU1000i',   'owners_manual',      'Owner''s Manual',     'https://powerequipment.honda.com/support/owners-manuals?model=EU1000i'),
  ('EU3200i',   'owners_manual',      'Owner''s Manual',     'https://powerequipment.honda.com/support/owners-manuals?model=EU3200i'),
  ('EM5000SX',  'owners_manual',      'Owner''s Manual',     'https://powerequipment.honda.com/support/owners-manuals?model=EM5000SX'),
  ('EB10000',   'owners_manual',      'Owner''s Manual',     'https://powerequipment.honda.com/support/owners-manuals?model=EB10000')
) AS v(model_number, manual_type, title, source_url)
ON ec.model_number = v.model_number;
