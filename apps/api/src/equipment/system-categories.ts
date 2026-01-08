// System categories and common manufacturers for equipment research

export const SYSTEM_CATEGORIES = {
  HVAC: {
    name: 'HVAC',
    types: ['Furnace', 'Air Conditioner', 'Heat Pump', 'Boiler', 'Mini Split', 'Thermostat'],
    icon: 'thermometer',
  },
  PLUMBING: {
    name: 'Plumbing',
    types: ['Water Heater', 'Tankless Water Heater', 'Sump Pump', 'Well Pump', 'Water Softener', 'Water Filtration'],
    icon: 'water',
  },
  ELECTRICAL: {
    name: 'Electrical',
    types: ['Main Panel', 'Sub Panel', 'Generator', 'Solar Panels', 'EV Charger', 'Whole House Surge Protector'],
    icon: 'flash',
  },
  SAFETY: {
    name: 'Safety',
    types: ['Smoke Detector', 'CO Detector', 'Security System', 'Fire Extinguisher', 'Radon Mitigation'],
    icon: 'shield',
  },
  EXTERIOR: {
    name: 'Exterior',
    types: ['Roof', 'Siding', 'Windows', 'Doors', 'Deck', 'Fence', 'Driveway', 'Gutters'],
    icon: 'home',
  },
  SEPTIC: {
    name: 'Septic/Sewage',
    types: ['Septic Tank', 'Septic Pump', 'Grinder Pump', 'Sewage Ejector'],
    icon: 'construct',
  },
  POOL: {
    name: 'Pool/Spa',
    types: ['Pool', 'Hot Tub', 'Pool Pump', 'Pool Heater', 'Pool Filter'],
    icon: 'water',
  },
  APPLIANCE: {
    name: 'Appliances',
    types: ['Refrigerator', 'Dishwasher', 'Washer', 'Dryer', 'Oven', 'Range', 'Microwave', 'Garbage Disposal'],
    icon: 'cube',
  },
  LAWN: {
    name: 'Lawn & Garden',
    types: ['Irrigation System', 'Lawn Mower', 'Snow Blower', 'Outdoor Lighting'],
    icon: 'leaf',
  },
};

export const COMMON_MANUFACTURERS = {
  HVAC: ['Carrier', 'Trane', 'Lennox', 'Rheem', 'Goodman', 'Bryant', 'American Standard', 'York', 'Daikin'],
  PLUMBING: ['Rheem', 'A.O. Smith', 'Bradford White', 'Rinnai', 'Navien', 'State', 'Whirlpool'],
  ELECTRICAL: ['Generac', 'Kohler', 'Briggs & Stratton', 'Champion', 'Cummins', 'Tesla', 'SunPower', 'Enphase'],
  APPLIANCE: ['GE', 'Whirlpool', 'Samsung', 'LG', 'Bosch', 'KitchenAid', 'Maytag', 'Frigidaire', 'Sub-Zero', 'Viking'],
};

// Map HomeSystemType enum values to categories
export const SYSTEM_TYPE_TO_CATEGORY: Record<string, string> = {
  // HVAC
  FURNACE: 'HVAC',
  AIR_CONDITIONER: 'HVAC',
  HEAT_PUMP: 'HVAC',
  BOILER: 'HVAC',
  THERMOSTAT: 'HVAC',
  // Plumbing
  WATER_HEATER: 'PLUMBING',
  WATER_SOFTENER: 'PLUMBING',
  WELL_PUMP: 'PLUMBING',
  SUMP_PUMP: 'PLUMBING',
  // Electrical
  ELECTRICAL_PANEL: 'ELECTRICAL',
  GENERATOR: 'ELECTRICAL',
  SOLAR_PANELS: 'ELECTRICAL',
  BATTERY_STORAGE: 'ELECTRICAL',
  // Appliances
  REFRIGERATOR: 'APPLIANCE',
  DISHWASHER: 'APPLIANCE',
  OVEN_RANGE: 'APPLIANCE',
  MICROWAVE: 'APPLIANCE',
  GARBAGE_DISPOSAL: 'APPLIANCE',
  WASHER: 'APPLIANCE',
  DRYER: 'APPLIANCE',
  // Pool
  POOL_PUMP: 'POOL',
  POOL_HEATER: 'POOL',
  POOL_FILTER: 'POOL',
  HOT_TUB: 'POOL',
  // Septic
  SEPTIC_SYSTEM: 'SEPTIC',
  // Safety
  SMOKE_DETECTOR: 'SAFETY',
  CO_DETECTOR: 'SAFETY',
  SECURITY_SYSTEM: 'SAFETY',
  FIRE_EXTINGUISHER: 'SAFETY',
  // Exterior
  ROOF: 'EXTERIOR',
  GUTTERS: 'EXTERIOR',
  IRRIGATION: 'LAWN',
};
