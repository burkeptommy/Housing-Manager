-- Phase 1 of the equipment catalog expansion (plan: i-tried-to-add-reactive-boole.md).
--
-- Adds the categories and manufacturer brands the existing seed missed. The
-- existing catalog is heavy on appliances + HVAC + water heaters + pool + sump
-- + well; this fills the rest of the residential surface area: roofing,
-- windows, doors, garage, security, EV, fireplaces, solar, septic, central
-- vacuum, outdoor lighting, built-in grills, audio/video, home automation,
-- lawn equipment, snow blowers, outdoor heaters, pizza ovens.
--
-- Phases 2 and 3 then expand each (brand, category) pair into a full product
-- portfolio via Claude. This migration ships the empty scaffolding only.
--
-- Idempotent: every INSERT uses ON CONFLICT (slug) DO NOTHING so the migration
-- can be re-run safely.

BEGIN;

-- ============================================================================
-- New equipment_categories
-- ============================================================================

INSERT INTO equipment_categories (name, slug, room, typical_lifespan_years, description) VALUES
  -- Roofing
  ('Roofing', 'roofing', 'exterior', 25, 'Roof covering systems'),
  ('Asphalt Shingle Roofing', 'roofing-asphalt-shingle', 'exterior', 25, 'Architectural and three-tab asphalt shingles'),
  ('Metal Roofing', 'roofing-metal', 'exterior', 50, 'Standing seam, corrugated, metal shingle systems'),
  ('Slate Roofing', 'roofing-slate', 'exterior', 100, 'Natural and synthetic slate'),
  ('Tile Roofing', 'roofing-tile', 'exterior', 50, 'Clay and concrete tile systems'),
  ('Synthetic Roofing', 'roofing-synthetic', 'exterior', 50, 'Composite, polymer, rubber roofing'),

  -- Windows
  ('Window', 'window', 'exterior', 30, 'Residential window systems'),
  ('Vinyl Window', 'window-vinyl', 'exterior', 25, 'Vinyl-frame windows'),
  ('Fiberglass Window', 'window-fiberglass', 'exterior', 35, 'Fiberglass-composite-frame windows'),
  ('Wood Window', 'window-wood', 'exterior', 30, 'Solid-wood and wood-clad windows'),
  ('Aluminum Window', 'window-aluminum', 'exterior', 30, 'Aluminum-frame windows'),

  -- Doors (exterior)
  ('Exterior Door', 'door-exterior', 'exterior', 30, 'Residential entry, patio, sliding doors'),
  ('Entry Door', 'door-entry', 'exterior', 30, 'Front and side entry doors'),
  ('Patio Door', 'door-patio', 'exterior', 25, 'Hinged French doors, sliding glass doors'),
  ('Sliding Glass Door', 'door-sliding-glass', 'exterior', 25, 'Sliding glass patio door systems'),

  -- Garage doors + openers
  ('Garage Door', 'garage-door', 'garage', 30, 'Sectional and roll-up residential garage doors'),
  ('Garage Door Opener', 'garage-door-opener', 'garage', 15, 'Belt, chain, screw, jackshaft openers'),

  -- Smart home cameras + video doorbells + security
  ('Security Camera', 'security-camera', 'security', 7, 'Indoor and outdoor home security cameras'),
  ('Video Doorbell', 'video-doorbell', 'security', 7, 'Smart doorbells with camera'),
  ('Security System', 'security-system', 'security', 10, 'Whole-home security systems and panels'),
  ('Smart Lock', 'smart-lock', 'security', 7, 'Wi-Fi or Bluetooth-enabled door locks'),

  -- Detection
  ('Smoke Detector', 'smoke-detector', 'safety', 10, 'Smoke alarms (single and combo units)'),
  ('Carbon Monoxide Detector', 'co-detector', 'safety', 10, 'Stand-alone and combination CO alarms'),

  -- Electrical
  ('Electrical Panel', 'electrical-panel', 'electrical', 40, 'Main service panels and load centers'),
  ('Electrical Sub-Panel', 'electrical-sub-panel', 'electrical', 40, 'Secondary distribution panels'),
  ('Whole-Home Surge Protector', 'surge-protector', 'electrical', 10, 'Type 1 and Type 2 surge protective devices'),
  ('Transfer Switch', 'transfer-switch', 'electrical', 25, 'Manual and automatic generator transfer switches'),

  -- EV
  ('EV Charger', 'ev-charger', 'electrical', 12, 'Level 2 home EV charging stations'),

  -- Whole-home humidifiers + dehumidifiers
  ('Whole-Home Humidifier', 'humidifier-whole-home', 'hvac', 15, 'Bypass, fan-powered, steam humidifiers'),
  ('Whole-Home Dehumidifier', 'dehumidifier-whole-home', 'hvac', 12, 'Ducted whole-home dehumidifiers'),

  -- Air purifiers
  ('Air Purifier', 'air-purifier', 'hvac', 10, 'Whole-home and room air purification'),
  ('Whole-Home Air Purifier', 'air-purifier-whole-home', 'hvac', 12, 'In-duct UV / filtration / ionization systems'),
  ('Room Air Purifier', 'air-purifier-room', 'hvac', 8, 'Portable room HEPA air purifiers'),

  -- Fireplaces
  ('Fireplace', 'fireplace', 'living', 30, 'Residential fireplace systems'),
  ('Gas Fireplace', 'fireplace-gas', 'living', 25, 'Direct-vent and vent-free gas fireplaces'),
  ('Gas Fireplace Insert', 'fireplace-gas-insert', 'living', 25, 'Gas inserts retrofit into masonry fireplaces'),
  ('Wood Burning Fireplace', 'fireplace-wood', 'living', 50, 'Masonry and prefab wood-burning fireplaces'),
  ('Wood Burning Stove', 'stove-wood', 'living', 30, 'Free-standing wood stoves'),
  ('Wood Burning Insert', 'fireplace-wood-insert', 'living', 25, 'Wood-burning inserts retrofit into masonry fireplaces'),
  ('Pellet Stove', 'stove-pellet', 'living', 15, 'Pellet-burning stoves and inserts'),

  -- Solar
  ('Solar Panel', 'solar-panel', 'exterior', 30, 'Residential photovoltaic modules'),
  ('Solar Inverter', 'solar-inverter', 'electrical', 15, 'String, microinverter, and hybrid solar inverters'),
  ('Solar Battery', 'solar-battery', 'electrical', 12, 'Residential battery energy storage'),
  ('Solar Microinverter', 'solar-microinverter', 'electrical', 25, 'Module-level microinverters'),

  -- Septic
  ('Septic System', 'septic-system', 'wastewater', 30, 'Conventional and advanced treatment septic systems'),
  ('Septic Tank', 'septic-tank', 'wastewater', 30, 'Concrete, plastic, fiberglass septic tanks'),
  ('Septic Pump', 'septic-pump', 'wastewater', 15, 'Effluent and grinder pumps for septic systems'),
  ('Septic Aerator', 'septic-aerator', 'wastewater', 8, 'Aerobic treatment unit aerators'),
  ('Septic Drainfield', 'septic-drainfield', 'wastewater', 25, 'Conventional and advanced drainfield systems'),

  -- Radon mitigation
  ('Radon Mitigation System', 'radon-mitigation', 'safety', 15, 'Sub-slab depressurization and crawlspace systems'),
  ('Radon Fan', 'radon-fan', 'safety', 8, 'Inline radon mitigation fans'),

  -- Central vacuum
  ('Central Vacuum', 'central-vacuum', 'cleaning', 20, 'Whole-home built-in vacuum systems'),

  -- Outdoor lighting
  ('Outdoor Lighting Transformer', 'outdoor-lighting-transformer', 'exterior', 20, 'Low-voltage landscape lighting transformers'),
  ('Landscape Lighting', 'landscape-lighting', 'exterior', 15, 'Path, spot, well, and accent low-voltage fixtures'),

  -- Built-in outdoor grills + outdoor kitchens
  ('Built-In Grill', 'grill-built-in', 'outdoor', 15, 'Permanent built-in gas/charcoal/hybrid grills'),
  ('Outdoor Kitchen', 'outdoor-kitchen', 'outdoor', 20, 'Outdoor kitchen modules and systems'),
  ('Outdoor Refrigeration', 'outdoor-refrigeration', 'outdoor', 12, 'Outdoor-rated refrigerators and ice makers'),

  -- Wine + beverage sub-categories (refining the existing wine-beverage)
  ('Wine Cellar', 'wine-cellar', 'kitchen', 25, 'Walk-in and reach-in wine storage units'),
  ('Wine Cooler', 'wine-cooler', 'kitchen', 12, 'Free-standing wine coolers'),
  ('Beverage Center', 'beverage-center', 'kitchen', 12, 'Under-counter beverage refrigerators'),

  -- Audio/video / home automation / lighting controls
  ('Multi-Room Audio', 'audio-multi-room', 'living', 12, 'Whole-home and multi-room audio systems'),
  ('AV Receiver', 'av-receiver', 'living', 10, 'Home theater receivers and processors'),
  ('Speaker', 'speaker', 'living', 15, 'Architectural, in-wall, in-ceiling, and stand-alone speakers'),
  ('Home Automation Hub', 'home-automation-hub', 'living', 10, 'Whole-home automation controllers'),
  ('Lighting Control System', 'lighting-control', 'electrical', 15, 'Dimmer, switch, and centralized lighting control'),

  -- Lawn equipment
  ('Lawn Mower', 'lawn-mower', 'outdoor', 12, 'Residential walk-behind lawn mowers'),
  ('Riding Mower', 'mower-riding', 'outdoor', 15, 'Riding lawn tractors'),
  ('Zero-Turn Mower', 'mower-zero-turn', 'outdoor', 10, 'Zero-turn-radius mowers'),
  ('Robotic Mower', 'mower-robotic', 'outdoor', 8, 'Autonomous robotic lawn mowers'),
  ('String Trimmer', 'string-trimmer', 'outdoor', 7, 'Gas, electric, battery weed trimmers'),
  ('Leaf Blower', 'leaf-blower', 'outdoor', 7, 'Hand-held and backpack leaf blowers'),
  ('Chainsaw', 'chainsaw', 'outdoor', 8, 'Gas, electric, battery chainsaws'),

  -- Snow blowers
  ('Snow Blower', 'snow-blower', 'outdoor', 10, 'Single-stage, two-stage, three-stage snow blowers'),

  -- Outdoor patio heaters
  ('Patio Heater', 'patio-heater', 'outdoor', 10, 'Outdoor radiant patio heaters'),

  -- Outdoor pizza ovens
  ('Pizza Oven', 'pizza-oven', 'outdoor', 12, 'Wood, gas, multi-fuel pizza ovens')
ON CONFLICT DO NOTHING;


-- ============================================================================
-- New equipment_manufacturers
-- ============================================================================

INSERT INTO equipment_manufacturers (name, slug, parent_company, country_of_origin, tier) VALUES
  -- Roofing
  ('GAF', 'gaf', 'Standard Industries', 'United States', 'mainstream'),
  ('CertainTeed', 'certainteed', 'Saint-Gobain', 'United States', 'mainstream'),
  ('Owens Corning', 'owens-corning', 'Owens Corning', 'United States', 'mainstream'),
  ('IKO', 'iko', 'IKO Industries', 'Canada', 'mainstream'),
  ('Atlas Roofing', 'atlas-roofing', 'Atlas Roofing Corporation', 'United States', 'mainstream'),
  ('Tamko', 'tamko', 'Tamko Building Products', 'United States', 'budget'),
  ('Malarkey', 'malarkey', 'Malarkey Roofing Products', 'United States', 'mainstream'),
  ('DaVinci Roofscapes', 'davinci-roofscapes', 'Westlake Royal Building Products', 'United States', 'premium'),
  ('Brava Roof Tile', 'brava-roof-tile', 'Brava Roof Tile', 'United States', 'premium'),
  ('Eagle Roofing', 'eagle-roofing', 'Eagle Roofing Products', 'United States', 'mainstream'),
  ('Boral', 'boral', 'Boral Roofing', 'United States', 'mainstream'),
  ('DECRA', 'decra', 'Westlake Royal Building Products', 'United States', 'premium'),

  -- Windows + doors
  ('Andersen', 'andersen', 'Andersen Corporation', 'United States', 'premium'),
  ('Pella', 'pella', 'Pella Corporation', 'United States', 'premium'),
  ('Marvin', 'marvin', 'Marvin Companies', 'United States', 'luxury'),
  ('Milgard', 'milgard', 'MITER Brands', 'United States', 'mainstream'),
  ('Loewen', 'loewen', 'Loewen Windows', 'Canada', 'luxury'),
  ('Sierra Pacific', 'sierra-pacific', 'Sierra Pacific Industries', 'United States', 'premium'),
  ('Jeld-Wen', 'jeld-wen', 'JELD-WEN', 'United States', 'mainstream'),
  ('Simonton', 'simonton', 'Cornerstone Building Brands', 'United States', 'mainstream'),
  ('Kolbe', 'kolbe', 'Kolbe & Kolbe Millwork', 'United States', 'luxury'),
  ('Weather Shield', 'weather-shield', 'Weather Shield Manufacturing', 'United States', 'premium'),
  ('Hurd Windows', 'hurd-windows', 'Sierra Pacific Industries', 'United States', 'premium'),
  ('Therma-Tru', 'therma-tru', 'Fortune Brands Innovations', 'United States', 'mainstream'),
  ('Masonite', 'masonite', 'Masonite International', 'United States', 'mainstream'),
  ('Plastpro', 'plastpro', 'Plastpro Inc.', 'United States', 'mainstream'),

  -- Garage doors
  ('Clopay', 'clopay', 'Griffon Corporation', 'United States', 'mainstream'),
  ('Wayne Dalton', 'wayne-dalton', 'Overhead Door Corporation', 'United States', 'mainstream'),
  ('Amarr', 'amarr', 'Entrematic (ASSA ABLOY)', 'United States', 'mainstream'),
  ('Haas Door', 'haas-door', 'Haas Door Company', 'United States', 'mainstream'),
  ('CHI Overhead Doors', 'chi-overhead-doors', 'CHI Overhead Doors', 'United States', 'mainstream'),
  ('Northwest Door', 'northwest-door', 'Northwest Door', 'United States', 'mainstream'),
  ('Overhead Door', 'overhead-door', 'Overhead Door Corporation', 'United States', 'mainstream'),

  -- Garage door openers
  ('LiftMaster', 'liftmaster', 'Chamberlain Group', 'United States', 'premium'),
  ('Chamberlain', 'chamberlain', 'Chamberlain Group', 'United States', 'mainstream'),
  ('Genie', 'genie', 'GMI Holdings', 'United States', 'mainstream'),
  ('Sommer', 'sommer', 'SOMMER Antriebs- und Funktechnik', 'Germany', 'premium'),
  ('Marantec', 'marantec', 'Marantec Group', 'Germany', 'premium'),
  ('Linear', 'linear', 'Nortek Security & Control', 'United States', 'mainstream'),
  ('Skylink', 'skylink', 'Skylink Group', 'Canada', 'budget'),

  -- Smart home cameras + security
  ('Ring', 'ring', 'Amazon', 'United States', 'mainstream'),
  ('Nest', 'nest', 'Google', 'United States', 'premium'),
  ('Arlo', 'arlo', 'Arlo Technologies', 'United States', 'premium'),
  ('Eufy', 'eufy', 'Anker Innovations', 'China', 'mainstream'),
  ('Reolink', 'reolink', 'Reolink Innovation', 'China', 'mainstream'),
  ('Wyze', 'wyze', 'Wyze Labs', 'United States', 'budget'),
  ('Lorex', 'lorex', 'Lorex Technology', 'Canada', 'mainstream'),
  ('SimpliSafe', 'simplisafe', 'SimpliSafe', 'United States', 'mainstream'),
  ('Vivint', 'vivint', 'Vivint Smart Home', 'United States', 'premium'),
  ('ADT', 'adt', 'ADT Inc.', 'United States', 'premium'),
  ('Blink', 'blink', 'Amazon', 'United States', 'budget'),
  ('Swann', 'swann', 'Swann Communications', 'Australia', 'budget'),
  ('Ubiquiti', 'ubiquiti', 'Ubiquiti Networks', 'United States', 'premium'),
  ('Hikvision', 'hikvision', 'Hikvision', 'China', 'mainstream'),
  ('Google Nest', 'google-nest', 'Google', 'United States', 'premium'),

  -- Smart locks
  ('August', 'august-locks', 'ASSA ABLOY', 'United States', 'premium'),
  ('Schlage', 'schlage', 'Allegion', 'United States', 'mainstream'),
  ('Yale', 'yale-locks', 'ASSA ABLOY', 'United States', 'mainstream'),
  ('Kwikset', 'kwikset', 'Spectrum Brands', 'United States', 'mainstream'),
  ('Level Locks', 'level-locks', 'Level Home', 'United States', 'luxury'),

  -- Smoke / CO detection
  ('First Alert', 'first-alert', 'Resideo', 'United States', 'mainstream'),
  ('Kidde', 'kidde', 'Carrier Global', 'United States', 'mainstream'),
  ('X-Sense', 'x-sense', 'X-Sense Innovations', 'China', 'mainstream'),
  ('Heiman', 'heiman', 'Heiman Technology', 'China', 'budget'),

  -- Electrical panels
  ('Square D', 'square-d', 'Schneider Electric', 'France', 'premium'),
  ('Eaton', 'eaton', 'Eaton Corporation', 'Ireland/United States', 'premium'),
  ('Siemens', 'siemens', 'Siemens AG', 'Germany', 'premium'),
  ('GE Industrial', 'ge-industrial', 'ABB Ltd.', 'United States', 'premium'),
  ('Leviton', 'leviton', 'Leviton Manufacturing', 'United States', 'premium'),
  ('Schneider Electric', 'schneider-electric', 'Schneider Electric', 'France', 'premium'),

  -- EV chargers
  ('Tesla', 'tesla', 'Tesla, Inc.', 'United States', 'premium'),
  ('ChargePoint', 'chargepoint', 'ChargePoint', 'United States', 'mainstream'),
  ('Wallbox', 'wallbox', 'Wallbox', 'Spain', 'premium'),
  ('JuiceBox', 'juicebox', 'Enel X Way', 'United States', 'mainstream'),
  ('ClipperCreek', 'clippercreek', 'ClipperCreek (Enphase)', 'United States', 'premium'),
  ('Grizzl-E', 'grizzl-e', 'United Chargers', 'Canada', 'mainstream'),
  ('Lectron', 'lectron', 'Lectron', 'United States', 'budget'),
  ('Emporia', 'emporia', 'Emporia Energy', 'United States', 'mainstream'),
  ('Enel X', 'enel-x', 'Enel X Way', 'Italy', 'mainstream'),
  ('Autel', 'autel', 'Autel Energy', 'United States', 'mainstream'),
  ('Pulsar Plus', 'pulsar-plus', 'Wallbox', 'Spain', 'premium'),

  -- Whole-home humidifiers + dehumidifiers
  ('Aprilaire', 'aprilaire', 'Research Products Corporation', 'United States', 'premium'),
  ('Honeywell', 'honeywell', 'Resideo', 'United States', 'mainstream'),
  ('GeneralAire', 'generalaire', 'General Filters Inc.', 'United States', 'mainstream'),
  ('Skuttle', 'skuttle', 'Skuttle Indoor Air Quality Products', 'United States', 'mainstream'),
  ('Santa Fe', 'santa-fe', 'Therma-Stor', 'United States', 'premium'),

  -- Air purifiers (whole-home + room)
  ('IQAir', 'iqair', 'IQAir', 'Switzerland', 'luxury'),
  ('Reme Halo', 'reme-halo', 'RGF Environmental', 'United States', 'premium'),
  ('Coway', 'coway', 'Coway', 'South Korea', 'premium'),
  ('Levoit', 'levoit', 'Vesync', 'United States', 'mainstream'),
  ('Dyson', 'dyson', 'Dyson Limited', 'United Kingdom', 'luxury'),
  ('Blueair', 'blueair', 'Unilever', 'Sweden', 'premium'),
  ('Molekule', 'molekule', 'Molekule', 'United States', 'luxury'),
  ('Winix', 'winix', 'Winix', 'South Korea', 'mainstream'),
  ('Alen', 'alen', 'Alen Corporation', 'United States', 'premium'),
  ('Austin Air', 'austin-air', 'Austin Air Systems', 'United States', 'premium'),

  -- Gas + wood fireplaces
  ('Heatilator', 'heatilator', 'Hearth & Home Technologies', 'United States', 'mainstream'),
  ('Mendota', 'mendota', 'Mendota Hearth', 'United States', 'luxury'),
  ('Heat & Glo', 'heat-and-glo', 'Hearth & Home Technologies', 'United States', 'premium'),
  ('Napoleon', 'napoleon', 'Napoleon Group', 'Canada', 'premium'),
  ('Majestic', 'majestic', 'Hearth & Home Technologies', 'United States', 'mainstream'),
  ('Empire', 'empire-comfort', 'Empire Comfort Systems', 'United States', 'mainstream'),
  ('Travis Industries', 'travis-industries', 'Travis Industries', 'United States', 'premium'),
  ('Regency', 'regency-fireplace', 'FPI Fireplace Products International', 'Canada', 'premium'),
  ('Valor', 'valor-fireplace', 'Miles Industries', 'Canada', 'luxury'),
  ('Vermont Castings', 'vermont-castings', 'HHT/MHSC', 'United States', 'premium'),
  ('Jotul', 'jotul', 'Jotul AS', 'Norway', 'luxury'),
  ('Lopi', 'lopi', 'Travis Industries', 'United States', 'premium'),
  ('Quadrafire', 'quadrafire', 'Hearth & Home Technologies', 'United States', 'premium'),
  ('Hearthstone', 'hearthstone', 'Hearthstone', 'United States', 'premium'),
  ('Pacific Energy', 'pacific-energy', 'Pacific Energy', 'Canada', 'premium'),
  ('Blaze King', 'blaze-king', 'Blaze King Industries', 'Canada', 'premium'),
  ('Drolet', 'drolet', 'Stove Builder International', 'Canada', 'mainstream'),
  ('Harman', 'harman-stoves', 'Hearth & Home Technologies', 'United States', 'premium'),

  -- Solar
  ('Tesla Solar', 'tesla-solar', 'Tesla, Inc.', 'United States', 'premium'),
  ('Enphase', 'enphase', 'Enphase Energy', 'United States', 'premium'),
  ('SunPower', 'sunpower', 'SunPower Corporation', 'United States', 'luxury'),
  ('SolarEdge', 'solaredge', 'SolarEdge Technologies', 'Israel', 'premium'),
  ('REC Solar', 'rec-solar', 'REC Group', 'Norway', 'premium'),
  ('Panasonic Solar', 'panasonic-solar', 'Panasonic Corporation', 'Japan', 'premium'),
  ('LG Solar', 'lg-solar', 'LG Corporation', 'South Korea', 'premium'),
  ('Q CELLS', 'q-cells', 'Hanwha Q CELLS', 'South Korea', 'mainstream'),
  ('Canadian Solar', 'canadian-solar', 'Canadian Solar Inc.', 'Canada', 'mainstream'),
  ('Silfab', 'silfab', 'Silfab Solar', 'Canada', 'mainstream'),
  ('Trina Solar', 'trina-solar', 'Trina Solar', 'China', 'mainstream'),
  ('Jinko Solar', 'jinko-solar', 'Jinko Solar', 'China', 'mainstream'),
  ('Generac PWRcell', 'generac-pwrcell', 'Generac Holdings', 'United States', 'premium'),
  ('Franklin Home Power', 'franklin-home-power', 'Franklin Electric', 'United States', 'premium'),

  -- Septic
  ('Orenco', 'orenco', 'Orenco Systems', 'United States', 'premium'),
  ('Eljen', 'eljen', 'Eljen Corporation', 'United States', 'premium'),
  ('Norweco', 'norweco', 'Norweco', 'United States', 'premium'),
  ('Bio-Microbics', 'bio-microbics', 'Bio-Microbics', 'United States', 'premium'),
  ('Infiltrator', 'infiltrator', 'Infiltrator Water Technologies', 'United States', 'mainstream'),
  ('Presby Environmental', 'presby-environmental', 'Presby Environmental', 'United States', 'premium'),
  ('Salcor', 'salcor', 'Salcor Inc.', 'United States', 'premium'),

  -- Radon
  ('RadonAway', 'radonaway', 'RadonAway', 'United States', 'premium'),
  ('Festa Radon Technologies', 'festa-radon', 'Festa Radon Technologies', 'United States', 'premium'),
  ('AMG Manufacturing', 'amg-manufacturing', 'AMG Manufacturing', 'United States', 'mainstream'),
  ('Fantech', 'fantech', 'Fantech', 'United States', 'mainstream'),
  ('Suncourt', 'suncourt', 'Suncourt Inc.', 'United States', 'mainstream'),

  -- Central vacuum
  ('Beam', 'beam', 'Electrolux', 'United States', 'mainstream'),
  ('Electrolux Central', 'electrolux-central', 'Electrolux', 'Sweden', 'mainstream'),
  ('MD Manufacturing', 'md-manufacturing', 'MD Manufacturing', 'United States', 'premium'),
  ('Vacuflo', 'vacuflo', 'H-P Products', 'United States', 'premium'),
  ('NuTone', 'nutone', 'Broan-NuTone', 'United States', 'mainstream'),
  ('Cyclo Vac', 'cyclo-vac', 'Trovac Industries', 'Canada', 'premium'),
  ('Drainvac', 'drainvac', 'Trovac Industries', 'Canada', 'premium'),
  ('Vacumaid', 'vacumaid', 'H-P Products', 'United States', 'mainstream'),

  -- Outdoor lighting transformers + landscape lighting
  ('Kichler', 'kichler', 'Masco Corporation', 'United States', 'premium'),
  ('FX Luminaire', 'fx-luminaire', 'Hunter Industries', 'United States', 'luxury'),
  ('Hinkley', 'hinkley', 'Hinkley Lighting', 'United States', 'premium'),
  ('Hadco', 'hadco', 'Signify (Philips)', 'United States', 'premium'),
  ('Vista', 'vista-lighting', 'Vista Professional Outdoor Lighting', 'United States', 'premium'),
  ('Lumien', 'lumien', 'Lumien Outdoor Lighting', 'United States', 'luxury'),
  ('Volt Lighting', 'volt-lighting', 'Volt Lighting', 'United States', 'premium'),
  ('Unique Lighting Systems', 'unique-lighting-systems', 'Hunter Industries', 'United States', 'luxury'),

  -- Built-in outdoor grills
  ('Lynx', 'lynx', 'Middleby Corporation', 'United States', 'luxury'),
  ('DCS', 'dcs', 'Fisher & Paykel Appliances', 'New Zealand', 'luxury'),
  ('Twin Eagles', 'twin-eagles', 'Twin Eagles', 'United States', 'luxury'),
  ('Kalamazoo', 'kalamazoo-outdoor', 'Kalamazoo Outdoor Gourmet', 'United States', 'ultra-luxury'),
  ('Coyote', 'coyote-grills', 'Coyote Outdoor Living', 'United States', 'premium'),
  ('Fire Magic', 'fire-magic', 'RH Peterson Co.', 'United States', 'premium'),
  ('Bull Outdoor', 'bull-outdoor', 'Bull Outdoor Products', 'United States', 'premium'),
  ('Blaze Grills', 'blaze-grills', 'BBQGuys', 'United States', 'premium'),
  ('Summerset', 'summerset-grills', 'Summerset Grills', 'United States', 'premium'),
  ('RCS Gas Grills', 'rcs-gas-grills', 'BBQGuys', 'United States', 'premium'),
  -- Hestan Outdoor is the same brand as the Hestan kitchen line; one row covers both (Phase 2 will surface multi-category coverage)

  -- Wine cellars + coolers
  ('EuroCave', 'eurocave', 'EuroCave Group', 'France', 'ultra-luxury'),
  ('U-Line', 'u-line', 'U-Line Corporation', 'United States', 'premium'),
  ('Marvel', 'marvel-refrigeration', 'AGA Marvel', 'United States', 'premium'),
  ('Wine Enthusiast', 'wine-enthusiast', 'Wine Enthusiast Companies', 'United States', 'mainstream'),
  ('Whynter', 'whynter', 'Whynter LLC', 'United States', 'mainstream'),
  ('Vinotemp', 'vinotemp', 'Vinotemp International', 'United States', 'premium'),
  ('Allavino', 'allavino', 'Allavino', 'United States', 'mainstream'),
  ('Le Cache', 'le-cache', 'Vinotemp International', 'United States', 'luxury'),

  -- Audio/video / home automation
  ('Sonos', 'sonos', 'Sonos, Inc.', 'United States', 'premium'),
  ('Bluesound', 'bluesound', 'Lenbrook Industries', 'Canada', 'luxury'),
  ('Yamaha Audio', 'yamaha-audio', 'Yamaha Corporation', 'Japan', 'premium'),
  ('Denon', 'denon', 'Sound United', 'Japan', 'premium'),
  ('Marantz', 'marantz', 'Sound United', 'Japan', 'luxury'),
  ('McIntosh', 'mcintosh', 'McIntosh Group', 'United States', 'ultra-luxury'),
  ('Anthem', 'anthem-av', 'Paradigm Electronics', 'Canada', 'luxury'),
  ('Onkyo', 'onkyo', 'Sharp Corporation / Onkyo Home Entertainment', 'Japan', 'premium'),
  ('Bose', 'bose', 'Bose Corporation', 'United States', 'premium'),
  ('B&W (Bowers & Wilkins)', 'bowers-wilkins', 'Sound United', 'United Kingdom', 'ultra-luxury'),
  ('KEF', 'kef', 'GP Acoustics', 'United Kingdom', 'luxury'),
  ('Klipsch', 'klipsch', 'VOXX International', 'United States', 'premium'),
  ('Polk Audio', 'polk-audio', 'Sound United', 'United States', 'mainstream'),
  ('Definitive Technology', 'definitive-technology', 'Sound United', 'United States', 'premium'),
  ('Control4', 'control4', 'Snap One', 'United States', 'luxury'),
  ('Crestron', 'crestron', 'Crestron Electronics', 'United States', 'ultra-luxury'),
  ('Savant', 'savant', 'Savant Systems', 'United States', 'ultra-luxury'),
  ('Lutron', 'lutron', 'Lutron Electronics', 'United States', 'luxury'),
  ('URC (Universal Remote Control)', 'urc', 'Universal Remote Control', 'United States', 'premium'),
  ('Russound', 'russound', 'Russound', 'United States', 'premium'),

  -- Lawn equipment (the brands NOT already in)
  ('John Deere', 'john-deere', 'Deere & Company', 'United States', 'premium'),
  ('Kubota', 'kubota', 'Kubota Corporation', 'Japan', 'premium'),
  ('Husqvarna', 'husqvarna', 'Husqvarna Group', 'Sweden', 'premium'),
  ('Cub Cadet', 'cub-cadet', 'MTD Products (Stanley Black & Decker)', 'United States', 'mainstream'),
  ('Stihl', 'stihl', 'STIHL Group', 'Germany', 'premium'),
  ('Snapper', 'snapper', 'Briggs & Stratton', 'United States', 'mainstream'),
  ('Troy-Bilt', 'troy-bilt', 'MTD Products', 'United States', 'mainstream'),
  ('Greenworks', 'greenworks', 'Globe Tools Group', 'United States', 'mainstream'),
  ('Ariens', 'ariens', 'AriensCo', 'United States', 'premium'),
  ('Echo', 'echo-power', 'Yamabiko Corporation', 'Japan', 'premium'),
  ('Scag', 'scag', 'Metalcraft of Mayville', 'United States', 'luxury'),
  ('Walker Mowers', 'walker-mowers', 'Walker Manufacturing', 'United States', 'luxury'),
  ('Exmark', 'exmark', 'Toro Company', 'United States', 'premium'),
  ('Gravely', 'gravely', 'AriensCo', 'United States', 'premium'),

  -- Robotic mowers
  ('Husqvarna Automower', 'husqvarna-automower', 'Husqvarna Group', 'Sweden', 'luxury'),
  ('Worx Landroid', 'worx-landroid', 'Positec Tool Corporation', 'China', 'mainstream'),
  ('Robomow', 'robomow', 'MTD Products', 'Israel', 'premium'),
  ('Mammotion', 'mammotion', 'Mammotion Tech', 'China', 'premium'),
  ('Segway Navimow', 'segway-navimow', 'Segway-Ninebot', 'United States', 'premium'),
  ('Ambrogio', 'ambrogio', 'Zucchetti Centro Sistemi', 'Italy', 'luxury'),

  -- Patio heaters
  ('Bromic', 'bromic', 'Bromic Group', 'Australia', 'luxury'),
  ('Infratech', 'infratech', 'Infratech', 'United States', 'luxury'),
  ('Sunpak', 'sunpak', 'Sundance Industries', 'United States', 'premium'),
  ('Schwank', 'schwank', 'Schwank', 'Germany', 'premium'),
  ('Solaira', 'solaira', 'Inferno Manufacturing', 'Canada', 'premium'),
  ('Mr. Heater', 'mr-heater', 'Enerco Group', 'United States', 'mainstream'),
  ('Calcana', 'calcana', 'Calcana Industries', 'Canada', 'premium'),

  -- Pizza ovens
  ('Ooni', 'ooni', 'Ooni Pizza Ovens', 'United Kingdom', 'mainstream'),
  ('Gozney', 'gozney', 'Gozney', 'United Kingdom', 'premium'),
  ('Alfa', 'alfa', 'Alfa Forni', 'Italy', 'luxury'),
  ('Forno Bravo', 'forno-bravo', 'Forno Bravo', 'United States', 'premium'),
  ('Solo Stove', 'solo-stove', 'Solo Brands', 'United States', 'mainstream'),
  ('Pizzello', 'pizzello', 'Pizzello', 'United States', 'mainstream'),

  -- Smart thermostats
  ('Ecobee', 'ecobee', 'Ecobee Inc.', 'Canada', 'premium'),
  ('Resideo', 'resideo', 'Resideo Technologies', 'United States', 'mainstream'),
  ('Sensi', 'sensi', 'Emerson Electric', 'United States', 'mainstream'),

  -- HNW kitchen brands missing
  ('Viking', 'viking', 'Middleby Corporation', 'United States', 'luxury'),
  ('Hestan', 'hestan', 'Hestan Commercial Corporation', 'United States', 'luxury'),
  ('BlueStar', 'bluestar', 'Prizer-Painter Stove Works', 'United States', 'luxury'),
  ('AGA', 'aga', 'AGA Rangemaster', 'United Kingdom', 'ultra-luxury'),
  ('Lacanche', 'lacanche', 'Lacanche', 'France', 'ultra-luxury'),
  ('Ilve', 'ilve', 'Ilve', 'Italy', 'luxury')

ON CONFLICT DO NOTHING;

COMMIT;
