/**
 * Checklist templates for maintenance tasks
 * Each template contains predefined steps with Alfred eligibility flags
 */

export interface ChecklistStep {
  id: string;
  order: number;
  title: string;
  description?: string;
  completed: boolean;
  completedAt?: string;
  alfredCanHandle: boolean;
  alfredPrompt?: string; // Pre-filled prompt for Alfred
  estimatedMinutes?: number;
  difficulty?: 'easy' | 'medium' | 'hard';
}

export interface ChecklistTemplate {
  id: string;
  name: string;
  category: string;
  matchPatterns: string[]; // Title patterns to match
  whyThisMatters: string;
  steps: Omit<ChecklistStep, 'completed' | 'completedAt'>[];
}

export const CHECKLIST_TEMPLATES: ChecklistTemplate[] = [
  // ================== HVAC ==================
  {
    id: 'hvac-filter-change',
    name: 'HVAC Filter Change',
    category: 'HVAC',
    matchPatterns: ['hvac filter', 'air filter', 'furnace filter', 'ac filter', 'replace filter'],
    whyThisMatters:
      'Clean filters improve air quality, reduce energy costs by up to 15%, and extend the life of your HVAC system. Dirty filters force your system to work harder, leading to higher bills and potential breakdowns.',
    steps: [
      {
        id: 'hvac-filter-1',
        order: 1,
        title: 'Check current filter size',
        description: 'Look at the edge of your existing filter for the size (e.g., 20x25x1)',
        alfredCanHandle: false,
        estimatedMinutes: 2,
        difficulty: 'easy',
      },
      {
        id: 'hvac-filter-2',
        order: 2,
        title: 'Order replacement filters',
        description: 'Order filters from preferred supplier or schedule Alfred to handle',
        alfredCanHandle: true,
        alfredPrompt: 'Order HVAC filters for my home. The current filter size is [SIZE]. Please find the best price and order a 3-pack.',
        estimatedMinutes: 5,
        difficulty: 'easy',
      },
      {
        id: 'hvac-filter-3',
        order: 3,
        title: 'Turn off HVAC system',
        description: 'Switch the thermostat to OFF before removing the filter',
        alfredCanHandle: false,
        estimatedMinutes: 1,
        difficulty: 'easy',
      },
      {
        id: 'hvac-filter-4',
        order: 4,
        title: 'Remove and dispose of old filter',
        description: 'Carefully remove the old filter and place in trash bag',
        alfredCanHandle: false,
        estimatedMinutes: 2,
        difficulty: 'easy',
      },
      {
        id: 'hvac-filter-5',
        order: 5,
        title: 'Install new filter',
        description: 'Insert new filter with arrow pointing toward airflow direction',
        alfredCanHandle: false,
        estimatedMinutes: 2,
        difficulty: 'easy',
      },
      {
        id: 'hvac-filter-6',
        order: 6,
        title: 'Turn HVAC system back on',
        description: 'Switch the thermostat back to AUTO or your preferred setting',
        alfredCanHandle: false,
        estimatedMinutes: 1,
        difficulty: 'easy',
      },
    ],
  },
  {
    id: 'hvac-service',
    name: 'HVAC Annual Service',
    category: 'HVAC',
    matchPatterns: ['hvac service', 'hvac maintenance', 'hvac tune-up', 'hvac inspection', 'furnace service', 'ac service'],
    whyThisMatters:
      'Annual HVAC service catches small problems before they become expensive repairs, ensures your system runs efficiently, and can extend equipment life by 5-10 years. Most manufacturer warranties require annual professional maintenance.',
    steps: [
      {
        id: 'hvac-service-1',
        order: 1,
        title: 'Schedule HVAC technician',
        description: 'Book appointment with your preferred HVAC company',
        alfredCanHandle: true,
        alfredPrompt: 'Schedule an HVAC tune-up service for my home. I prefer appointments in the morning. Please coordinate with my regular HVAC company if we have one on file.',
        estimatedMinutes: 10,
        difficulty: 'easy',
      },
      {
        id: 'hvac-service-2',
        order: 2,
        title: 'Ensure access to equipment',
        description: 'Clear area around furnace, AC unit, and thermostat',
        alfredCanHandle: false,
        estimatedMinutes: 15,
        difficulty: 'easy',
      },
      {
        id: 'hvac-service-3',
        order: 3,
        title: 'Review service report',
        description: 'Check technician recommendations and upload invoice',
        alfredCanHandle: false,
        estimatedMinutes: 10,
        difficulty: 'easy',
      },
    ],
  },

  // ================== PLUMBING ==================
  {
    id: 'water-heater-flush',
    name: 'Water Heater Flush',
    category: 'PLUMBING',
    matchPatterns: ['water heater flush', 'water heater maintenance', 'drain water heater', 'flush tank'],
    whyThisMatters:
      'Sediment buildup in water heaters reduces efficiency by up to 25% and can cause premature tank failure. Annual flushing removes sediment, improves hot water output, and extends tank life by 3-5 years.',
    steps: [
      {
        id: 'water-heater-1',
        order: 1,
        title: 'Schedule plumber or watch tutorial',
        description: 'This can be DIY or professionally done',
        alfredCanHandle: true,
        alfredPrompt: 'Schedule a plumber to flush my water heater, or send me a simple tutorial video if this is something I can do myself.',
        estimatedMinutes: 10,
        difficulty: 'easy',
      },
      {
        id: 'water-heater-2',
        order: 2,
        title: 'Turn off water heater',
        description: 'Turn off gas valve or flip breaker for electric heaters',
        alfredCanHandle: false,
        estimatedMinutes: 2,
        difficulty: 'easy',
      },
      {
        id: 'water-heater-3',
        order: 3,
        title: 'Connect hose to drain valve',
        description: 'Attach garden hose and run to floor drain or outside',
        alfredCanHandle: false,
        estimatedMinutes: 5,
        difficulty: 'medium',
      },
      {
        id: 'water-heater-4',
        order: 4,
        title: 'Open drain valve and flush',
        description: 'Let water drain until it runs clear (10-20 minutes)',
        alfredCanHandle: false,
        estimatedMinutes: 20,
        difficulty: 'medium',
      },
      {
        id: 'water-heater-5',
        order: 5,
        title: 'Close valve and restart',
        description: 'Close drain, remove hose, turn water heater back on',
        alfredCanHandle: false,
        estimatedMinutes: 5,
        difficulty: 'easy',
      },
    ],
  },

  // ================== SAFETY ==================
  {
    id: 'smoke-detector-test',
    name: 'Smoke Detector Test',
    category: 'SAFETY',
    matchPatterns: ['smoke detector', 'smoke alarm', 'fire alarm', 'detector test', 'detector battery'],
    whyThisMatters:
      'Working smoke detectors are your first line of defense against fire. Testing monthly and replacing batteries annually ensures your family has critical warning time in an emergency. Smoke detectors should be replaced every 10 years.',
    steps: [
      {
        id: 'smoke-1',
        order: 1,
        title: 'Locate all smoke detectors',
        description: 'Walk through home and identify each detector location',
        alfredCanHandle: false,
        estimatedMinutes: 5,
        difficulty: 'easy',
      },
      {
        id: 'smoke-2',
        order: 2,
        title: 'Test each detector',
        description: 'Press and hold test button until alarm sounds',
        alfredCanHandle: false,
        estimatedMinutes: 10,
        difficulty: 'easy',
      },
      {
        id: 'smoke-3',
        order: 3,
        title: 'Replace batteries if needed',
        description: 'Use 9V or AA batteries depending on model',
        alfredCanHandle: true,
        alfredPrompt: 'Order replacement batteries for my smoke detectors. I need [QUANTITY] 9V batteries.',
        estimatedMinutes: 5,
        difficulty: 'easy',
      },
      {
        id: 'smoke-4',
        order: 4,
        title: 'Check expiration dates',
        description: 'Smoke detectors expire after 10 years - check manufacture date',
        alfredCanHandle: false,
        estimatedMinutes: 5,
        difficulty: 'easy',
      },
    ],
  },
  {
    id: 'carbon-monoxide-test',
    name: 'Carbon Monoxide Detector Test',
    category: 'SAFETY',
    matchPatterns: ['carbon monoxide', 'co detector', 'co alarm', 'carbon monoxide detector'],
    whyThisMatters:
      'Carbon monoxide is an odorless, colorless gas that can be fatal. CO detectors provide critical early warning for gas leaks, furnace problems, or car exhaust intrusion. Test monthly and replace every 5-7 years.',
    steps: [
      {
        id: 'co-1',
        order: 1,
        title: 'Locate all CO detectors',
        description: 'Should be on each floor, especially near bedrooms and garage',
        alfredCanHandle: false,
        estimatedMinutes: 5,
        difficulty: 'easy',
      },
      {
        id: 'co-2',
        order: 2,
        title: 'Test each detector',
        description: 'Press and hold test button until alarm sounds',
        alfredCanHandle: false,
        estimatedMinutes: 10,
        difficulty: 'easy',
      },
      {
        id: 'co-3',
        order: 3,
        title: 'Replace batteries if needed',
        description: 'Most use AA batteries - check manufacturer recommendations',
        alfredCanHandle: true,
        alfredPrompt: 'Order replacement batteries for my CO detectors.',
        estimatedMinutes: 5,
        difficulty: 'easy',
      },
    ],
  },

  // ================== EXTERIOR ==================
  {
    id: 'gutter-cleaning',
    name: 'Gutter Cleaning',
    category: 'EXTERIOR',
    matchPatterns: ['gutter clean', 'gutter maintenance', 'clean gutters', 'downspout'],
    whyThisMatters:
      'Clogged gutters cause water to overflow and damage your foundation, siding, and landscaping. Ice dams in winter can cause roof leaks. Clean gutters in spring and fall protect your home from thousands in water damage.',
    steps: [
      {
        id: 'gutter-1',
        order: 1,
        title: 'Schedule gutter service or gather supplies',
        description: 'This can be DIY with ladder or hire a professional',
        alfredCanHandle: true,
        alfredPrompt: 'Schedule a gutter cleaning service for my home. I prefer to have this done professionally due to safety concerns with ladders.',
        estimatedMinutes: 10,
        difficulty: 'easy',
      },
      {
        id: 'gutter-2',
        order: 2,
        title: 'Remove debris from gutters',
        description: 'Scoop out leaves, twigs, and sediment with gloved hands or scoop',
        alfredCanHandle: false,
        estimatedMinutes: 60,
        difficulty: 'hard',
      },
      {
        id: 'gutter-3',
        order: 3,
        title: 'Flush with hose',
        description: 'Run water through gutters to clear remaining debris',
        alfredCanHandle: false,
        estimatedMinutes: 15,
        difficulty: 'medium',
      },
      {
        id: 'gutter-4',
        order: 4,
        title: 'Check downspouts',
        description: 'Ensure water flows freely through downspouts',
        alfredCanHandle: false,
        estimatedMinutes: 10,
        difficulty: 'easy',
      },
      {
        id: 'gutter-5',
        order: 5,
        title: 'Inspect for damage',
        description: 'Look for loose brackets, holes, or separation',
        alfredCanHandle: false,
        estimatedMinutes: 10,
        difficulty: 'easy',
      },
    ],
  },
  {
    id: 'exterior-inspection',
    name: 'Exterior Home Inspection',
    category: 'EXTERIOR',
    matchPatterns: ['exterior inspection', 'home inspection', 'siding check', 'foundation check'],
    whyThisMatters:
      'Regular exterior inspections catch small problems before they become expensive repairs. Cracks in foundation, damaged siding, and deteriorating caulk let water in, leading to mold, rot, and structural damage.',
    steps: [
      {
        id: 'exterior-1',
        order: 1,
        title: 'Walk around foundation',
        description: 'Look for cracks, settling, or water pooling near foundation',
        alfredCanHandle: false,
        estimatedMinutes: 15,
        difficulty: 'easy',
      },
      {
        id: 'exterior-2',
        order: 2,
        title: 'Inspect siding and paint',
        description: 'Look for peeling paint, damaged siding, or gaps',
        alfredCanHandle: false,
        estimatedMinutes: 15,
        difficulty: 'easy',
      },
      {
        id: 'exterior-3',
        order: 3,
        title: 'Check windows and doors',
        description: 'Inspect caulking, weatherstripping, and seals',
        alfredCanHandle: false,
        estimatedMinutes: 20,
        difficulty: 'easy',
      },
      {
        id: 'exterior-4',
        order: 4,
        title: 'Examine roof from ground',
        description: 'Use binoculars to check for missing shingles or damage',
        alfredCanHandle: false,
        estimatedMinutes: 10,
        difficulty: 'easy',
      },
      {
        id: 'exterior-5',
        order: 5,
        title: 'Report issues to Alfred',
        description: 'Note any concerns for follow-up scheduling',
        alfredCanHandle: true,
        alfredPrompt: 'I completed my exterior home inspection and found the following issues: [DESCRIBE ISSUES]. Please help me schedule the appropriate repairs.',
        estimatedMinutes: 5,
        difficulty: 'easy',
      },
    ],
  },

  // ================== LAWN & GARDEN ==================
  {
    id: 'lawn-winterization',
    name: 'Lawn Winterization',
    category: 'LAWN',
    matchPatterns: ['lawn winteriz', 'winter lawn', 'fall lawn', 'lawn prep winter'],
    whyThisMatters:
      'Proper fall lawn care helps grass develop strong roots before winter dormancy. Winterizing fertilizer, final mowing, and leaf removal prevent disease and ensure a healthy, green lawn in spring.',
    steps: [
      {
        id: 'lawn-winter-1',
        order: 1,
        title: 'Schedule final mowing',
        description: 'Lower mower blade for final cut to 2-2.5 inches',
        alfredCanHandle: true,
        alfredPrompt: 'Schedule a final fall mowing service with instructions to lower the blade for winterization.',
        estimatedMinutes: 5,
        difficulty: 'easy',
      },
      {
        id: 'lawn-winter-2',
        order: 2,
        title: 'Apply winterizer fertilizer',
        description: 'Use slow-release nitrogen fertilizer before ground freezes',
        alfredCanHandle: true,
        alfredPrompt: 'Order winterizer fertilizer for my lawn, approximately [SQ FT] square feet.',
        estimatedMinutes: 30,
        difficulty: 'medium',
      },
      {
        id: 'lawn-winter-3',
        order: 3,
        title: 'Clear leaves from lawn',
        description: 'Rake or mulch leaves to prevent lawn disease',
        alfredCanHandle: true,
        alfredPrompt: 'Schedule a leaf removal service for my property.',
        estimatedMinutes: 60,
        difficulty: 'medium',
      },
      {
        id: 'lawn-winter-4',
        order: 4,
        title: 'Store outdoor equipment',
        description: 'Drain and store hoses, winterize mower',
        alfredCanHandle: false,
        estimatedMinutes: 30,
        difficulty: 'easy',
      },
    ],
  },
  {
    id: 'irrigation-winterization',
    name: 'Sprinkler System Winterization',
    category: 'LAWN',
    matchPatterns: ['sprinkler winteriz', 'irrigation winteriz', 'blow out sprinkler', 'winterize irrigation'],
    whyThisMatters:
      'Water left in sprinkler lines will freeze and crack pipes, leading to expensive repairs in spring. Professional blowout service uses compressed air to clear all water before the first freeze.',
    steps: [
      {
        id: 'irrigation-1',
        order: 1,
        title: 'Schedule blowout service',
        description: 'Book irrigation company before first freeze',
        alfredCanHandle: true,
        alfredPrompt: 'Schedule sprinkler system winterization / blowout service before the first freeze. Please coordinate with our irrigation company if we have one on file.',
        estimatedMinutes: 5,
        difficulty: 'easy',
      },
      {
        id: 'irrigation-2',
        order: 2,
        title: 'Turn off water supply',
        description: 'Close main irrigation shutoff valve',
        alfredCanHandle: false,
        estimatedMinutes: 5,
        difficulty: 'easy',
      },
      {
        id: 'irrigation-3',
        order: 3,
        title: 'Confirm blowout complete',
        description: 'Technician should blow out each zone with compressed air',
        alfredCanHandle: false,
        estimatedMinutes: 5,
        difficulty: 'easy',
      },
    ],
  },

  // ================== HEATING OIL ==================
  {
    id: 'oil-delivery',
    name: 'Heating Oil Delivery',
    category: 'HVAC',
    matchPatterns: ['oil delivery', 'heating oil', 'fuel oil', 'oil tank', 'schedule oil'],
    whyThisMatters:
      'Running out of heating oil in winter is not just inconvenient - it can damage your furnace when air enters the fuel line. Regular deliveries and tank monitoring ensure uninterrupted heat during cold months.',
    steps: [
      {
        id: 'oil-1',
        order: 1,
        title: 'Check tank level',
        description: 'Look at gauge on tank - order when below 1/4',
        alfredCanHandle: false,
        estimatedMinutes: 2,
        difficulty: 'easy',
      },
      {
        id: 'oil-2',
        order: 2,
        title: 'Get delivery quotes',
        description: 'Compare prices from local oil companies',
        alfredCanHandle: true,
        alfredPrompt: 'Get heating oil delivery quotes for my home. My tank is at [LEVEL] and holds approximately [GALLONS] gallons. Please compare prices from local suppliers.',
        estimatedMinutes: 15,
        difficulty: 'easy',
      },
      {
        id: 'oil-3',
        order: 3,
        title: 'Schedule delivery',
        description: 'Book delivery before tank runs low',
        alfredCanHandle: true,
        alfredPrompt: 'Schedule heating oil delivery from our preferred supplier. Current tank level is [LEVEL].',
        estimatedMinutes: 5,
        difficulty: 'easy',
      },
      {
        id: 'oil-4',
        order: 4,
        title: 'Ensure access to fill pipe',
        description: 'Clear snow/debris from oil fill pipe location',
        alfredCanHandle: false,
        estimatedMinutes: 5,
        difficulty: 'easy',
      },
    ],
  },

  // ================== SEASONAL ==================
  {
    id: 'spring-home-prep',
    name: 'Spring Home Preparation',
    category: 'GENERAL',
    matchPatterns: ['spring prep', 'spring home', 'spring maintenance', 'spring check'],
    whyThisMatters:
      'Spring is the ideal time to inspect for winter damage and prepare your home for warmer months. Addressing issues now prevents problems from worsening and ensures your outdoor systems are ready for use.',
    steps: [
      {
        id: 'spring-1',
        order: 1,
        title: 'Inspect roof and gutters',
        description: 'Check for winter damage, ice dam effects, loose shingles',
        alfredCanHandle: true,
        alfredPrompt: 'Schedule a professional roof and gutter inspection to check for winter damage.',
        estimatedMinutes: 30,
        difficulty: 'medium',
      },
      {
        id: 'spring-2',
        order: 2,
        title: 'Test outdoor faucets',
        description: 'Check for freeze damage and leaks',
        alfredCanHandle: false,
        estimatedMinutes: 10,
        difficulty: 'easy',
      },
      {
        id: 'spring-3',
        order: 3,
        title: 'Service lawn equipment',
        description: 'Change oil, sharpen blades, replace spark plugs',
        alfredCanHandle: true,
        alfredPrompt: 'Schedule lawn mower service - oil change, blade sharpening, and tune-up.',
        estimatedMinutes: 60,
        difficulty: 'medium',
      },
      {
        id: 'spring-4',
        order: 4,
        title: 'Clean outdoor furniture',
        description: 'Wash patio furniture, inspect for damage',
        alfredCanHandle: false,
        estimatedMinutes: 30,
        difficulty: 'easy',
      },
      {
        id: 'spring-5',
        order: 5,
        title: 'Activate irrigation system',
        description: 'Turn on water, test each zone, adjust sprinkler heads',
        alfredCanHandle: true,
        alfredPrompt: 'Schedule irrigation system spring startup service.',
        estimatedMinutes: 30,
        difficulty: 'medium',
      },
    ],
  },
  {
    id: 'fall-home-prep',
    name: 'Fall Home Preparation',
    category: 'GENERAL',
    matchPatterns: ['fall prep', 'fall home', 'fall maintenance', 'winter prep', 'winterization'],
    whyThisMatters:
      'Preparing your home for winter prevents frozen pipes, ice dams, and heating inefficiency. Fall is the time to button up your home before cold weather arrives and ensure heating systems are ready.',
    steps: [
      {
        id: 'fall-1',
        order: 1,
        title: 'Schedule heating system service',
        description: 'Professional inspection and tune-up before heating season',
        alfredCanHandle: true,
        alfredPrompt: 'Schedule furnace/heating system inspection and tune-up before winter.',
        estimatedMinutes: 5,
        difficulty: 'easy',
      },
      {
        id: 'fall-2',
        order: 2,
        title: 'Disconnect and store hoses',
        description: 'Drain hoses and store inside to prevent freeze damage',
        alfredCanHandle: false,
        estimatedMinutes: 15,
        difficulty: 'easy',
      },
      {
        id: 'fall-3',
        order: 3,
        title: 'Insulate outdoor faucets',
        description: 'Install faucet covers on all exterior spigots',
        alfredCanHandle: true,
        alfredPrompt: 'Order faucet covers/insulators for my outdoor spigots. I have [COUNT] exterior faucets.',
        estimatedMinutes: 15,
        difficulty: 'easy',
      },
      {
        id: 'fall-4',
        order: 4,
        title: 'Check weatherstripping',
        description: 'Inspect and replace worn weatherstripping on doors/windows',
        alfredCanHandle: false,
        estimatedMinutes: 30,
        difficulty: 'easy',
      },
      {
        id: 'fall-5',
        order: 5,
        title: 'Clean chimney if applicable',
        description: 'Schedule chimney sweep before fireplace season',
        alfredCanHandle: true,
        alfredPrompt: 'Schedule chimney cleaning and inspection before fireplace season.',
        estimatedMinutes: 5,
        difficulty: 'easy',
      },
      {
        id: 'fall-6',
        order: 6,
        title: 'Test heating system',
        description: 'Turn on heat to verify proper operation before cold arrives',
        alfredCanHandle: false,
        estimatedMinutes: 10,
        difficulty: 'easy',
      },
    ],
  },

  // ================== APPLIANCES ==================
  {
    id: 'refrigerator-maintenance',
    name: 'Refrigerator Maintenance',
    category: 'APPLIANCE',
    matchPatterns: ['refrigerator', 'fridge maintenance', 'fridge coil', 'refrigerator clean'],
    whyThisMatters:
      'Dusty condenser coils make your refrigerator work up to 25% harder, increasing energy bills and shortening its lifespan. Annual cleaning and seal checks keep your fridge running efficiently for 15-20 years.',
    steps: [
      {
        id: 'fridge-1',
        order: 1,
        title: 'Clean condenser coils',
        description: 'Vacuum coils on back or bottom of fridge',
        alfredCanHandle: false,
        estimatedMinutes: 15,
        difficulty: 'easy',
      },
      {
        id: 'fridge-2',
        order: 2,
        title: 'Check door seals',
        description: 'Inspect gaskets for cracks, clean with soapy water',
        alfredCanHandle: false,
        estimatedMinutes: 10,
        difficulty: 'easy',
      },
      {
        id: 'fridge-3',
        order: 3,
        title: 'Check temperature settings',
        description: 'Fridge should be 37-40°F, freezer at 0°F',
        alfredCanHandle: false,
        estimatedMinutes: 5,
        difficulty: 'easy',
      },
      {
        id: 'fridge-4',
        order: 4,
        title: 'Clean drip pan',
        description: 'Remove and clean the drip pan underneath',
        alfredCanHandle: false,
        estimatedMinutes: 10,
        difficulty: 'easy',
      },
    ],
  },
  {
    id: 'dryer-vent-cleaning',
    name: 'Dryer Vent Cleaning',
    category: 'APPLIANCE',
    matchPatterns: ['dryer vent', 'dryer lint', 'vent cleaning', 'dryer maintenance'],
    whyThisMatters:
      'Clogged dryer vents cause 15,000+ house fires annually. Lint buildup reduces drying efficiency, increases energy costs, and creates a serious fire hazard. Annual cleaning is essential for safety.',
    steps: [
      {
        id: 'dryer-1',
        order: 1,
        title: 'Schedule professional cleaning or gather supplies',
        description: 'Dryer vent cleaning kits available at hardware stores',
        alfredCanHandle: true,
        alfredPrompt: 'Schedule professional dryer vent cleaning service. This is a fire safety priority.',
        estimatedMinutes: 5,
        difficulty: 'easy',
      },
      {
        id: 'dryer-2',
        order: 2,
        title: 'Disconnect dryer from vent',
        description: 'Unplug dryer and disconnect vent hose',
        alfredCanHandle: false,
        estimatedMinutes: 10,
        difficulty: 'medium',
      },
      {
        id: 'dryer-3',
        order: 3,
        title: 'Clean vent duct',
        description: 'Use vent brush to clear lint from entire duct',
        alfredCanHandle: false,
        estimatedMinutes: 20,
        difficulty: 'medium',
      },
      {
        id: 'dryer-4',
        order: 4,
        title: 'Clean exterior vent flap',
        description: 'Ensure exterior vent opens freely and is clear',
        alfredCanHandle: false,
        estimatedMinutes: 10,
        difficulty: 'easy',
      },
      {
        id: 'dryer-5',
        order: 5,
        title: 'Reconnect and test',
        description: 'Reconnect vent hose, run empty cycle to verify airflow',
        alfredCanHandle: false,
        estimatedMinutes: 10,
        difficulty: 'easy',
      },
    ],
  },

  // ================== POOL ==================
  {
    id: 'pool-opening',
    name: 'Pool Opening',
    category: 'POOL',
    matchPatterns: ['pool open', 'open pool', 'pool season', 'pool startup'],
    whyThisMatters:
      'Proper pool opening sets the stage for a safe, enjoyable summer. Rushing the process can lead to algae blooms, equipment damage, and water chemistry problems that are expensive to fix.',
    steps: [
      {
        id: 'pool-open-1',
        order: 1,
        title: 'Schedule pool service',
        description: 'Book professional opening or gather supplies',
        alfredCanHandle: true,
        alfredPrompt: 'Schedule pool opening service with our regular pool company.',
        estimatedMinutes: 5,
        difficulty: 'easy',
      },
      {
        id: 'pool-open-2',
        order: 2,
        title: 'Remove cover and clean',
        description: 'Remove winter cover, clean and store properly',
        alfredCanHandle: false,
        estimatedMinutes: 30,
        difficulty: 'medium',
      },
      {
        id: 'pool-open-3',
        order: 3,
        title: 'Reconnect equipment',
        description: 'Install pump, filter, and reconnect plumbing',
        alfredCanHandle: false,
        estimatedMinutes: 60,
        difficulty: 'hard',
      },
      {
        id: 'pool-open-4',
        order: 4,
        title: 'Fill and test water',
        description: 'Add water if needed, test chemistry levels',
        alfredCanHandle: false,
        estimatedMinutes: 30,
        difficulty: 'medium',
      },
      {
        id: 'pool-open-5',
        order: 5,
        title: 'Balance chemicals',
        description: 'Adjust pH, chlorine, alkalinity based on test results',
        alfredCanHandle: true,
        alfredPrompt: 'Order pool chemicals based on these test results: [PH], [CHLORINE], [ALKALINITY].',
        estimatedMinutes: 30,
        difficulty: 'medium',
      },
    ],
  },
  {
    id: 'pool-closing',
    name: 'Pool Closing',
    category: 'POOL',
    matchPatterns: ['pool clos', 'close pool', 'winterize pool', 'pool winterization'],
    whyThisMatters:
      'Proper winterization protects your pool and equipment from freeze damage. Skipping steps can lead to cracked pipes, damaged pumps, and expensive repairs before you can open next season.',
    steps: [
      {
        id: 'pool-close-1',
        order: 1,
        title: 'Schedule pool service',
        description: 'Book professional closing or gather supplies',
        alfredCanHandle: true,
        alfredPrompt: 'Schedule pool closing/winterization service with our regular pool company.',
        estimatedMinutes: 5,
        difficulty: 'easy',
      },
      {
        id: 'pool-close-2',
        order: 2,
        title: 'Balance and shock water',
        description: 'Adjust chemistry and add winterizing chemicals',
        alfredCanHandle: false,
        estimatedMinutes: 30,
        difficulty: 'medium',
      },
      {
        id: 'pool-close-3',
        order: 3,
        title: 'Lower water level',
        description: 'Drain water below skimmer line',
        alfredCanHandle: false,
        estimatedMinutes: 60,
        difficulty: 'medium',
      },
      {
        id: 'pool-close-4',
        order: 4,
        title: 'Blow out lines',
        description: 'Use air compressor to clear all water from plumbing',
        alfredCanHandle: false,
        estimatedMinutes: 60,
        difficulty: 'hard',
      },
      {
        id: 'pool-close-5',
        order: 5,
        title: 'Install winter cover',
        description: 'Secure pool cover properly for winter',
        alfredCanHandle: false,
        estimatedMinutes: 30,
        difficulty: 'medium',
      },
    ],
  },

  // ================== GENERIC TEMPLATES ==================
  {
    id: 'generic-inspection',
    name: 'General Inspection',
    category: 'GENERAL',
    matchPatterns: ['inspect', 'check', 'review', 'assess'],
    whyThisMatters:
      'Regular inspections catch small problems before they become expensive emergencies. Taking a few minutes to check systems and equipment can save thousands in repairs.',
    steps: [
      {
        id: 'generic-inspect-1',
        order: 1,
        title: 'Visual inspection',
        description: 'Look for obvious signs of wear, damage, or issues',
        alfredCanHandle: false,
        estimatedMinutes: 15,
        difficulty: 'easy',
      },
      {
        id: 'generic-inspect-2',
        order: 2,
        title: 'Test functionality',
        description: 'Verify system operates correctly',
        alfredCanHandle: false,
        estimatedMinutes: 10,
        difficulty: 'easy',
      },
      {
        id: 'generic-inspect-3',
        order: 3,
        title: 'Note any concerns',
        description: 'Document issues for follow-up',
        alfredCanHandle: true,
        alfredPrompt: 'I found the following issues during my inspection: [DESCRIBE]. Please help me schedule repairs or get quotes.',
        estimatedMinutes: 5,
        difficulty: 'easy',
      },
    ],
  },
  {
    id: 'generic-service',
    name: 'Professional Service',
    category: 'GENERAL',
    matchPatterns: ['service', 'maintenance', 'tune-up', 'annual'],
    whyThisMatters:
      'Professional service ensures your systems and equipment are operating safely and efficiently. Regular maintenance extends equipment life and catches problems early.',
    steps: [
      {
        id: 'generic-service-1',
        order: 1,
        title: 'Schedule service appointment',
        description: 'Contact vendor and book appointment',
        alfredCanHandle: true,
        alfredPrompt: 'Schedule a service appointment for this maintenance task.',
        estimatedMinutes: 10,
        difficulty: 'easy',
      },
      {
        id: 'generic-service-2',
        order: 2,
        title: 'Prepare access to equipment',
        description: 'Clear area and ensure technician can access equipment',
        alfredCanHandle: false,
        estimatedMinutes: 15,
        difficulty: 'easy',
      },
      {
        id: 'generic-service-3',
        order: 3,
        title: 'Review service report',
        description: 'Check technician recommendations and file invoice',
        alfredCanHandle: false,
        estimatedMinutes: 10,
        difficulty: 'easy',
      },
    ],
  },
];

/**
 * Find the best matching template for a maintenance task
 */
export function findMatchingTemplate(
  title: string,
  category?: string,
): ChecklistTemplate | undefined {
  const lowerTitle = title.toLowerCase();

  // First, try to find an exact category and pattern match
  for (const template of CHECKLIST_TEMPLATES) {
    if (
      template.category === category &&
      template.matchPatterns.some((pattern) => lowerTitle.includes(pattern))
    ) {
      return template;
    }
  }

  // Then try just pattern matching
  for (const template of CHECKLIST_TEMPLATES) {
    if (template.matchPatterns.some((pattern) => lowerTitle.includes(pattern))) {
      return template;
    }
  }

  // Fall back to generic templates based on keywords
  if (lowerTitle.includes('inspect') || lowerTitle.includes('check')) {
    return CHECKLIST_TEMPLATES.find((t) => t.id === 'generic-inspection');
  }

  if (lowerTitle.includes('service') || lowerTitle.includes('maintenance')) {
    return CHECKLIST_TEMPLATES.find((t) => t.id === 'generic-service');
  }

  return undefined;
}

/**
 * Create a fresh checklist from a template
 */
export function createChecklistFromTemplate(
  template: ChecklistTemplate,
): ChecklistStep[] {
  return template.steps.map((step) => ({
    ...step,
    completed: false,
    completedAt: undefined,
  }));
}

/**
 * Get the whyThisMatters text for a task
 */
export function getWhyThisMatters(
  title: string,
  category?: string,
): string | undefined {
  const template = findMatchingTemplate(title, category);
  return template?.whyThisMatters;
}
