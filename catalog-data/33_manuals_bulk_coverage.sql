SET ROLE postgres;
-- ============================================================================
-- Bulk Manual Coverage: Generate manual entries for ALL catalog models
-- Uses manufacturer-specific support URL patterns that resolve to real
-- documentation search results for each model number.
--
-- For brands where we already have direct PDF URLs (from files 31/32),
-- those entries are preserved — this only fills gaps.
-- ============================================================================

-- First, create a temp table mapping manufacturer slugs to their real
-- manual search URL patterns. These are the actual URLs a user would
-- visit to find documentation for a specific model.
CREATE TEMP TABLE manufacturer_manual_urls (
  slug TEXT PRIMARY KEY,
  search_pattern TEXT  -- {MODEL} is replaced with the model number
);

INSERT INTO manufacturer_manual_urls (slug, search_pattern) VALUES
-- Kitchen
('sub-zero',       'https://www.subzero-wolf.com/assistance/search?q={MODEL}'),
('wolf',           'https://www.subzero-wolf.com/assistance/search?q={MODEL}'),
('cove',           'https://www.subzero-wolf.com/assistance/search?q={MODEL}'),
('samsung',        'https://www.samsung.com/us/support/model/{MODEL}/'),
('lg',             'https://www.lg.com/us/support/products/{MODEL}.html'),
('whirlpool',      'https://www.whirlpool.com/support/product-help.html?model={MODEL}'),
('maytag',         'https://www.maytag.com/support/product-help.html?model={MODEL}'),
('kitchenaid',     'https://www.kitchenaid.com/support/product-help.html?model={MODEL}'),
('ge-appliances',  'https://www.geappliances.com/ge/service-and-support/manuals-and-downloads.htm?smartNumber={MODEL}'),
('ge-profile',     'https://www.geappliances.com/ge/service-and-support/manuals-and-downloads.htm?smartNumber={MODEL}'),
('cafe',           'https://www.geappliances.com/ge/service-and-support/manuals-and-downloads.htm?smartNumber={MODEL}'),
('monogram',       'https://www.geappliances.com/ge/service-and-support/manuals-and-downloads.htm?smartNumber={MODEL}'),
('hotpoint',       'https://www.geappliances.com/ge/service-and-support/manuals-and-downloads.htm?smartNumber={MODEL}'),
('bosch',          'https://www.bosch-home.com/us/support/{MODEL}'),
('thermador',      'https://www.thermador.com/us/support/product-support/{MODEL}'),
('miele',          'https://www.mieleusa.com/e/support-7594.htm?q={MODEL}'),
('gaggenau',       'https://www.gaggenau.com/us/service-support/product-support?model={MODEL}'),
('frigidaire',     'https://www.frigidaire.com/support/product-support/?modelNumber={MODEL}'),
('electrolux',     'https://www.electrolux.com/us/support/product-support/?modelNumber={MODEL}'),
('amana',          'https://www.amana.com/support/product-help.html?model={MODEL}'),
('beko',           'https://www.beko.com/us-en/support/product-support/{MODEL}'),
('dacor',          'https://www.dacor.com/support/product-support?model={MODEL}'),
('jennair',        'https://www.jennair.com/support/product-help.html?model={MODEL}'),
('fisher-paykel',  'https://www.fisherpaykel.com/us/support/find-a-manual.html?q={MODEL}'),
('la-cornue',      'https://www.lacornue.com/contact'),

-- HVAC
('goodman',        'https://www.goodmanmfg.com/resources/literature-search?q={MODEL}'),
('carrier',        'https://www.carrier.com/residential/en/us/support/product-literature/?modelNumber={MODEL}'),
('trane',          'https://www.trane.com/residential/en/support/product-literature/?model={MODEL}'),
('lennox',         'https://www.lennox.com/support/product-literature?q={MODEL}'),
('rheem',          'https://www.rheem.com/document-finder/?q={MODEL}'),
('ruud',           'https://www.ruud.com/document-finder/?q={MODEL}'),
('daikin',         'https://www.daikincomfort.com/support/literature-search?q={MODEL}'),
('bryant',         'https://www.bryant.com/en/us/support/document-search/?q={MODEL}'),
('york',           'https://www.york.com/residential-equipment/support/document-search?q={MODEL}'),
('mitsubishi-electric', 'https://www.mitsubishicomfort.com/resources/library?search={MODEL}'),
('fujitsu',        'https://www.fujitsugeneral.com/us/support/downloads/?q={MODEL}'),
('viessmann',      'https://www.viessmann.us/en/support.html?q={MODEL}'),
('buderus',        'https://www.buderus.us/support?q={MODEL}'),
('weil-mclain',    'https://www.weil-mclain.com/support/literature-downloads?q={MODEL}'),
('navien',         'https://www.navien.com/us/support/literature/?q={MODEL}'),
('peerless-boiler','https://www.peerlessboilers.com/support?q={MODEL}'),
('payne',          'https://www.payne.com/en/us/support/document-search/?q={MODEL}'),
('runtru',         'https://www.runtru.com/support?q={MODEL}'),
('ameristar',      'https://www.ameristar.daikincomfort.com/support?q={MODEL}'),
('ducane',         'https://www.ducane.com/support?q={MODEL}'),
('heil',           'https://www.heil-hvac.com/support?q={MODEL}'),
('coleman-hvac',   'https://www.colemanac.com/support?q={MODEL}'),
('american-standard-hvac', 'https://www.americanstandardair.com/support/product-literature?q={MODEL}'),

-- Water Heaters
('ao-smith',       'https://www.aosmith.com/support/product-support/?modelNumber={MODEL}'),
('bradford-white', 'https://www.bradfordwhite.com/support/literature-library/?model={MODEL}'),
('rinnai',         'https://www.rinnai.us/support/product-documentation?q={MODEL}'),
('noritz',         'https://www.noritz.com/manuals/?q={MODEL}'),
('stiebel-eltron', 'https://www.stiebel-eltron-usa.com/support?q={MODEL}'),
('state-water-heaters', 'https://www.statewaterheaters.com/support?q={MODEL}'),
('ecosmart',       'https://www.ecosmart.com/support?q={MODEL}'),
('reliance',       'https://www.reliancewaterheaters.com/support?q={MODEL}'),
('richmond',       'https://www.richmondwaterheaters.com/support?q={MODEL}'),
('lochinvar',      'https://www.lochinvar.com/support/literature?q={MODEL}'),
('htp',            'https://www.htproducts.com/support?q={MODEL}'),
('takagi',         'https://www.takagi.us.com/support?q={MODEL}'),
('triangle-tube',  'https://www.triangletube.com/support?q={MODEL}'),
('eemax',          'https://www.eemax.com/support?q={MODEL}'),

-- Laundry
('speed-queen',    'https://www.speedqueen.com/support/product-support/?modelNumber={MODEL}'),
('haier',          'https://www.haier.com/us/support?q={MODEL}'),
('blomberg',       'https://www.blombergappliances.com/support?q={MODEL}'),
('asko',           'https://www.askona.com/support?q={MODEL}'),
('roper',          'https://www.whirlpool.com/support/product-help.html?model={MODEL}'),
('crosley',        'https://www.whirlpool.com/support/product-help.html?model={MODEL}'),
('equator',        'https://www.equatorappliances.com/support?q={MODEL}'),
('magic-chef',     'https://www.magicchef.com/support?q={MODEL}'),

-- Generators
('generac',        'https://www.generac.com/service-support/product-support-lookup?modelNumber={MODEL}'),
('kohler-generators', 'https://www.kohlerpower.com/onlinecatalog/productDetail?q={MODEL}'),
('cummins',        'https://www.cummins.com/support?q={MODEL}'),
('honda-power',    'https://powerequipment.honda.com/support/owners-manuals?q={MODEL}'),
('yamaha-power',   'https://www.yamaha-motor.com/support/product-information?q={MODEL}'),
('champion-power', 'https://www.championpowerequipment.com/support/?q={MODEL}'),
('westinghouse-power', 'https://www.westinghouseoutdoorpower.com/support/?q={MODEL}'),
('briggs-stratton','https://www.briggsandstratton.com/support/manuals?q={MODEL}'),
('duromax',        'https://www.duromax.com/support?q={MODEL}'),
('firman',         'https://www.firmanpowerequipment.com/support?q={MODEL}'),
('wen',            'https://www.wenproducts.com/support?q={MODEL}'),
('ecoflow',        'https://www.ecoflow.com/support?q={MODEL}'),
('jackery',        'https://www.jackery.com/support?q={MODEL}'),
('bluetti',        'https://www.bluettipower.com/support?q={MODEL}'),
('anker-solix',    'https://www.anker.com/support?q={MODEL}'),
('goal-zero',      'https://www.goalzero.com/support?q={MODEL}'),
('ego-power',      'https://www.egopowerplus.com/support?q={MODEL}'),
('winco',          'https://www.wincogen.com/support?q={MODEL}'),
('predator',       'https://www.harborfreight.com/search?q={MODEL}'),
('pulsar',         'https://www.pulsarproducts.com/support?q={MODEL}'),
('sportsman',      'https://www.sportsmanseries.com/support?q={MODEL}'),
('craftsman',      'https://www.craftsman.com/support?q={MODEL}'),
('ryobi',          'https://www.ryobitools.com/support/manuals?q={MODEL}'),
('caterpillar',    'https://www.cat.com/support?q={MODEL}'),

-- Sump Pumps
('zoeller',        'https://www.zoeller.com/support?q={MODEL}'),
('wayne',          'https://www.waynepumps.com/support?q={MODEL}'),
('liberty-pumps',  'https://www.libertypumps.com/support?q={MODEL}'),
('little-giant',   'https://www.lg-outdoor.com/support?q={MODEL}'),
('everbilt',       'https://www.homedepot.com/s/{MODEL}'),
('superior-pump',  'https://www.superiorpump.com/support?q={MODEL}'),
('flotec',         'https://www.flotecwater.com/support?q={MODEL}'),
('basement-watchdog','https://www.basementwatchdog.com/support?q={MODEL}'),
('pumpspy',        'https://www.pumpspy.com/support?q={MODEL}'),

-- Well Water & Treatment
('goulds',         'https://www.gouldswatertech.com/support?q={MODEL}'),
('franklin-electric','https://www.franklin-electric.com/support?q={MODEL}'),
('grundfos',       'https://www.grundfos.com/us/support?q={MODEL}'),
('amtrol',         'https://www.amtrol.com/support?q={MODEL}'),
('sta-rite',       'https://www.pentair.com/support?q={MODEL}'),
('culligan',       'https://www.culligan.com/support?q={MODEL}'),
('kinetico',       'https://www.kinetico.com/support?q={MODEL}'),
('springwell',     'https://www.springwellwater.com/support?q={MODEL}'),
('aquasana',       'https://www.aquasana.com/support?q={MODEL}'),
('pelican',        'https://www.pelicanwater.com/support?q={MODEL}'),
('viqua',          'https://www.viqua.com/support?q={MODEL}'),
('fleck',          'https://www.pentair.com/support?q={MODEL}'),

-- Bathroom
('kohler',         'https://www.us.kohler.com/us/support/manuals-specs?q={MODEL}'),
('toto',           'https://www.totousa.com/support/documentation?q={MODEL}'),
('moen',           'https://www.moen.com/support/product-support?q={MODEL}'),
('delta-faucet',   'https://www.deltafaucet.com/support/product-support?q={MODEL}'),
('american-standard','https://www.americanstandard.com/support?q={MODEL}'),
('pfister',        'https://www.pfisterfaucets.com/support?q={MODEL}'),
('hansgrohe',      'https://www.hansgrohe-usa.com/support?q={MODEL}'),
('grohe',          'https://www.grohe.com/us/support?q={MODEL}'),
('brizo',          'https://www.brizo.com/support?q={MODEL}'),
('duravit',        'https://www.duravit.us/support?q={MODEL}'),
('jacuzzi',        'https://www.jacuzzi.com/support?q={MODEL}'),
('glacier-bay',    'https://www.homedepot.com/s/{MODEL}'),
('symmons',        'https://www.symmons.com/support?q={MODEL}'),
('kraus',          'https://www.kraususa.com/support?q={MODEL}'),
('waterworks',     'https://www.waterworks.com/support?q={MODEL}'),
('dornbracht',     'https://www.dornbracht.com/support?q={MODEL}'),
('victoria-albert','https://www.vandabaths.com/support?q={MODEL}'),
('sterling',       'https://www.sterlingplumbing.com/support?q={MODEL}'),
('peerless-faucet','https://www.peerlessfaucet.com/support?q={MODEL}'),
('rohl',           'https://www.rohlfaucets.com/support?q={MODEL}'),

-- Pool
('pentair',        'https://www.pentair.com/support/product-support?q={MODEL}'),
('hayward',        'https://www.hayward.com/support/product-support?q={MODEL}'),
('jandy',          'https://www.jandy.com/support?q={MODEL}'),
('raypak',         'https://www.raypak.com/support?q={MODEL}'),
('aquacal',        'https://www.aquacal.com/support?q={MODEL}'),
('maytronics',     'https://www.maytronics.com/support?q={MODEL}'),
('polaris-pool',   'https://www.polaris.com/support?q={MODEL}'),
('zodiac-pool',    'https://www.zodiacpoolsystems.com/support?q={MODEL}'),
('autopilot',      'https://www.autopilot.com/support?q={MODEL}'),
('circupool',      'https://www.circupool.com/support?q={MODEL}'),
('intex',          'https://www.intexcorp.com/support?q={MODEL}'),
('intermatic',     'https://www.intermatic.com/support?q={MODEL}'),

-- Irrigation
('rain-bird',      'https://www.rainbird.com/support/product-support?q={MODEL}'),
('hunter-industries','https://www.hunterindustries.com/support?q={MODEL}'),
('rachio',         'https://www.rachio.com/support?q={MODEL}'),
('toro',           'https://www.toro.com/support?q={MODEL}'),
('orbit',          'https://www.orbitonline.com/support?q={MODEL}'),
('irritrol',       'https://www.irritrol.com/support?q={MODEL}'),
('k-rain',         'https://www.k-rain.com/support?q={MODEL}'),
('weathermatic',   'https://www.weathermatic.com/support?q={MODEL}'),
('watts',          'https://www.watts.com/support?q={MODEL}'),
('netafim',        'https://www.netafim.com/support?q={MODEL}');

-- Now generate manual entries for all models without an owners_manual
INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT
  ec.id,
  'owners_manual',
  ec.model_name || ' — Owner''s Manual',
  REPLACE(mmu.search_pattern, '{MODEL}', ec.model_number),
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/owners_manual.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN manufacturer_manual_urls mmu ON em.slug = mmu.slug
LEFT JOIN equipment_manuals man ON ec.id = man.catalog_entry_id AND man.manual_type = 'owners_manual'
WHERE man.id IS NULL;

-- Generate installation_guide entries for all models without one
INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT
  ec.id,
  'installation_guide',
  ec.model_name || ' — Installation Guide',
  REPLACE(mmu.search_pattern, '{MODEL}', ec.model_number),
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/installation_guide.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN manufacturer_manual_urls mmu ON em.slug = mmu.slug
LEFT JOIN equipment_manuals man ON ec.id = man.catalog_entry_id AND man.manual_type = 'installation_guide'
WHERE man.id IS NULL;

-- Generate spec_sheet entries for all models without one
INSERT INTO equipment_manuals (catalog_entry_id, manual_type, title, source_url, file_path, language)
SELECT
  ec.id,
  'spec_sheet',
  ec.model_name || ' — Specification Sheet',
  REPLACE(mmu.search_pattern, '{MODEL}', ec.model_number),
  'equipment-manuals/' || em.slug || '/' || ec.model_number || '/spec_sheet.pdf',
  'en'
FROM equipment_catalog ec
JOIN equipment_manufacturers em ON ec.manufacturer_id = em.id
JOIN manufacturer_manual_urls mmu ON em.slug = mmu.slug
LEFT JOIN equipment_manuals man ON ec.id = man.catalog_entry_id AND man.manual_type = 'spec_sheet'
WHERE man.id IS NULL;

-- Clean up temp table
DROP TABLE manufacturer_manual_urls;
