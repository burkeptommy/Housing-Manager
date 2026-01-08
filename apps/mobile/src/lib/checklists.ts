import { Ionicons } from '@expo/vector-icons';

// =============================================================================
// HOME MAINTENANCE CHECKLIST SYSTEM
// =============================================================================
// Pre-defined maintenance tasks that help Essentials users know what needs
// to be done to maintain their home throughout the year.

export type ChecklistCategory = 'hvac' | 'plumbing' | 'electrical' | 'exterior' | 'safety' | 'seasonal' | 'appliances';
export type ChecklistFrequency = 'monthly' | 'quarterly' | 'semi-annual' | 'annual' | 'as-needed';
export type DIYDifficulty = 'easy' | 'medium' | 'hard' | 'professional';

export interface ChecklistItem {
  id: string;
  title: string;
  description: string;
  category: ChecklistCategory;
  frequency: ChecklistFrequency;
  typicalCost: { min: number; max: number };
  diyDifficulty: DIYDifficulty;
  canHandymanDo: boolean;
  reminderMonths: number[]; // 1-12 for which months to remind
  icon: keyof typeof Ionicons.glyphMap;
  tips?: string[];
  warningSign?: string;
}

// =============================================================================
// CATEGORY CONFIGURATION
// =============================================================================

export const CHECKLIST_CATEGORIES: Record<ChecklistCategory, {
  label: string;
  icon: keyof typeof Ionicons.glyphMap;
  color: string;
}> = {
  hvac: { label: 'HVAC', icon: 'thermometer-outline', color: '#ef4444' },
  plumbing: { label: 'Plumbing', icon: 'water-outline', color: '#3b82f6' },
  electrical: { label: 'Electrical', icon: 'flash-outline', color: '#f59e0b' },
  exterior: { label: 'Exterior', icon: 'home-outline', color: '#10b981' },
  safety: { label: 'Safety', icon: 'shield-checkmark-outline', color: '#8b5cf6' },
  seasonal: { label: 'Seasonal', icon: 'calendar-outline', color: '#ec4899' },
  appliances: { label: 'Appliances', icon: 'cube-outline', color: '#6366f1' },
};

export const FREQUENCY_LABELS: Record<ChecklistFrequency, string> = {
  monthly: 'Monthly',
  quarterly: 'Every 3 months',
  'semi-annual': 'Twice a year',
  annual: 'Yearly',
  'as-needed': 'As needed',
};

export const DIFFICULTY_LABELS: Record<DIYDifficulty, { label: string; description: string }> = {
  easy: { label: 'Easy DIY', description: 'Most homeowners can do this' },
  medium: { label: 'Moderate', description: 'Some skill or tools required' },
  hard: { label: 'Challenging', description: 'Experience recommended' },
  professional: { label: 'Pro Only', description: 'Hire a licensed professional' },
};

// =============================================================================
// HOME MAINTENANCE CHECKLIST
// =============================================================================

export const HOME_MAINTENANCE_CHECKLIST: ChecklistItem[] = [
  // ========== HVAC ==========
  {
    id: 'hvac-filter',
    title: 'Replace HVAC Filters',
    description: 'Replace air filters to maintain air quality and system efficiency. Dirty filters make your system work harder and can affect air quality.',
    category: 'hvac',
    frequency: 'monthly',
    typicalCost: { min: 10, max: 30 },
    diyDifficulty: 'easy',
    canHandymanDo: true,
    reminderMonths: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    icon: 'filter-outline',
    tips: [
      'Buy filters in bulk to save money',
      'Check filter size before purchasing',
      'Consider HEPA filters for allergies',
      'Set a monthly phone reminder',
    ],
    warningSign: 'Reduced airflow, dusty rooms, or higher energy bills',
  },
  {
    id: 'hvac-service',
    title: 'Annual HVAC Service',
    description: 'Professional inspection and tune-up of heating/cooling system. Extends equipment life and catches problems early.',
    category: 'hvac',
    frequency: 'annual',
    typicalCost: { min: 150, max: 300 },
    diyDifficulty: 'professional',
    canHandymanDo: false,
    reminderMonths: [3, 9], // Spring and Fall
    icon: 'thermometer-outline',
    tips: [
      'Schedule in spring (A/C) and fall (heating)',
      'Ask about maintenance contracts',
      'Get refrigerant levels checked',
      'Request efficiency report',
    ],
    warningSign: 'Unusual noises, weak airflow, or inconsistent temperatures',
  },
  {
    id: 'hvac-ducts',
    title: 'Clean Air Ducts',
    description: 'Professional cleaning of ductwork to remove dust, debris, and potential allergens.',
    category: 'hvac',
    frequency: 'annual',
    typicalCost: { min: 300, max: 500 },
    diyDifficulty: 'professional',
    canHandymanDo: false,
    reminderMonths: [4],
    icon: 'git-branch-outline',
    tips: [
      'Schedule after construction or renovation',
      'Check for mold or pest evidence',
      'Seal any leaky connections',
    ],
    warningSign: 'Visible dust around vents, musty smells, or allergy flare-ups',
  },
  {
    id: 'furnace-pilot',
    title: 'Check Furnace & Pilot Light',
    description: 'Ensure pilot light is functioning properly and furnace is ready for heating season.',
    category: 'hvac',
    frequency: 'annual',
    typicalCost: { min: 0, max: 100 },
    diyDifficulty: 'medium',
    canHandymanDo: true,
    reminderMonths: [9, 10],
    icon: 'flame-outline',
    tips: [
      'Test before first cold snap',
      'Check for gas smells',
      'Clear area around furnace',
      'Replace batteries in thermostat',
    ],
    warningSign: 'Yellow pilot flame (should be blue), clicking sounds',
  },

  // ========== PLUMBING ==========
  {
    id: 'water-heater-flush',
    title: 'Flush Water Heater',
    description: 'Drain sediment from water heater tank to extend its life and improve efficiency.',
    category: 'plumbing',
    frequency: 'annual',
    typicalCost: { min: 100, max: 200 },
    diyDifficulty: 'medium',
    canHandymanDo: true,
    reminderMonths: [4],
    icon: 'water-outline',
    tips: [
      'Turn off power/gas first',
      'Let water cool before draining',
      'Inspect anode rod condition',
      'Check temperature setting (120°F recommended)',
    ],
    warningSign: 'Rusty water, popping sounds, or slow heating',
  },
  {
    id: 'septic-pump',
    title: 'Pump Septic Tank',
    description: 'Have septic tank pumped and inspected by a professional (if applicable).',
    category: 'plumbing',
    frequency: 'annual',
    typicalCost: { min: 300, max: 600 },
    diyDifficulty: 'professional',
    canHandymanDo: false,
    reminderMonths: [4, 5],
    icon: 'water',
    tips: [
      'Keep pumping records',
      'Note household size for frequency',
      'Ask about baffle condition',
      'Get drain field inspected',
    ],
    warningSign: 'Slow drains, sewage odors, or wet spots in yard',
  },
  {
    id: 'drain-cleaning',
    title: 'Clean Drains',
    description: 'Clear buildup from bathroom and kitchen drains to prevent clogs.',
    category: 'plumbing',
    frequency: 'quarterly',
    typicalCost: { min: 0, max: 50 },
    diyDifficulty: 'easy',
    canHandymanDo: true,
    reminderMonths: [1, 4, 7, 10],
    icon: 'funnel-outline',
    tips: [
      'Use enzyme cleaners, not chemicals',
      'Install drain screens',
      'Flush with hot water weekly',
      'Never pour grease down drains',
    ],
  },
  {
    id: 'water-softener',
    title: 'Service Water Softener',
    description: 'Add salt and clean brine tank for water softener systems.',
    category: 'plumbing',
    frequency: 'monthly',
    typicalCost: { min: 10, max: 30 },
    diyDifficulty: 'easy',
    canHandymanDo: true,
    reminderMonths: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    icon: 'beaker-outline',
    tips: [
      'Check salt level monthly',
      'Use recommended salt type',
      'Clean brine tank yearly',
    ],
  },

  // ========== SAFETY ==========
  {
    id: 'smoke-detectors',
    title: 'Test Smoke & CO Detectors',
    description: 'Test all smoke and carbon monoxide detectors, replace batteries as needed.',
    category: 'safety',
    frequency: 'semi-annual',
    typicalCost: { min: 20, max: 50 },
    diyDifficulty: 'easy',
    canHandymanDo: true,
    reminderMonths: [3, 9], // Spring forward, fall back
    icon: 'alert-circle-outline',
    tips: [
      'Test monthly, change batteries twice yearly',
      'Replace entire unit every 10 years',
      'One detector per floor minimum',
      'Install CO detector near bedrooms',
    ],
    warningSign: 'Chirping sounds indicate low battery',
  },
  {
    id: 'fire-extinguisher',
    title: 'Check Fire Extinguishers',
    description: 'Inspect fire extinguishers and replace if expired or discharged.',
    category: 'safety',
    frequency: 'annual',
    typicalCost: { min: 20, max: 100 },
    diyDifficulty: 'easy',
    canHandymanDo: true,
    reminderMonths: [1],
    icon: 'flame-outline',
    tips: [
      'Check pressure gauge (green = good)',
      'Keep one on each floor',
      'Know the PASS technique',
      'Replace after any use',
    ],
  },
  {
    id: 'electrical-panel',
    title: 'Inspect Electrical Panel',
    description: 'Visual inspection of electrical panel for signs of wear, burning, or corrosion.',
    category: 'safety',
    frequency: 'annual',
    typicalCost: { min: 0, max: 200 },
    diyDifficulty: 'easy',
    canHandymanDo: false,
    reminderMonths: [6],
    icon: 'flash-outline',
    tips: [
      'Look for scorch marks',
      'Check for burning smell',
      'Ensure proper labeling',
      'Call electrician for any concerns',
    ],
    warningSign: 'Burning smell, flickering lights, or warm panel',
  },
  {
    id: 'gfci-test',
    title: 'Test GFCI Outlets',
    description: 'Test ground fault circuit interrupter outlets in bathrooms, kitchen, and outdoor areas.',
    category: 'safety',
    frequency: 'monthly',
    typicalCost: { min: 0, max: 0 },
    diyDifficulty: 'easy',
    canHandymanDo: true,
    reminderMonths: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    icon: 'power-outline',
    tips: [
      'Press TEST button, then RESET',
      'Replace if it won\'t reset',
      'Required near water sources',
    ],
  },

  // ========== EXTERIOR ==========
  {
    id: 'chimney-sweep',
    title: 'Chimney Sweep & Inspection',
    description: 'Professional cleaning and inspection of chimney and flue.',
    category: 'exterior',
    frequency: 'annual',
    typicalCost: { min: 150, max: 350 },
    diyDifficulty: 'professional',
    canHandymanDo: false,
    reminderMonths: [8, 9],
    icon: 'bonfire-outline',
    tips: [
      'Schedule before first fire of season',
      'Get Level 2 inspection if buying/selling',
      'Ask about cap installation',
      'Request creosote level report',
    ],
    warningSign: 'Strong odors, smoke in room, or visible buildup',
  },
  {
    id: 'gutter-cleaning',
    title: 'Clean Gutters',
    description: 'Remove debris from gutters and downspouts to prevent water damage.',
    category: 'exterior',
    frequency: 'semi-annual',
    typicalCost: { min: 100, max: 250 },
    diyDifficulty: 'medium',
    canHandymanDo: true,
    reminderMonths: [4, 11],
    icon: 'rainy-outline',
    tips: [
      'Clean after leaves fall',
      'Check for proper slope',
      'Extend downspouts away from foundation',
      'Consider gutter guards',
    ],
    warningSign: 'Overflowing gutters, water stains on siding',
  },
  {
    id: 'roof-inspection',
    title: 'Roof Inspection',
    description: 'Professional inspection for damage, missing shingles, and potential leaks.',
    category: 'exterior',
    frequency: 'annual',
    typicalCost: { min: 200, max: 500 },
    diyDifficulty: 'professional',
    canHandymanDo: false,
    reminderMonths: [4, 5],
    icon: 'home-outline',
    tips: [
      'Inspect after severe storms',
      'Check flashing around vents',
      'Look for curling shingles',
      'Document for insurance',
    ],
    warningSign: 'Missing shingles, water stains on ceiling, granules in gutters',
  },
  {
    id: 'deck-maintenance',
    title: 'Clean & Seal Deck',
    description: 'Power wash and apply sealant to wooden deck or patio.',
    category: 'exterior',
    frequency: 'annual',
    typicalCost: { min: 200, max: 500 },
    diyDifficulty: 'medium',
    canHandymanDo: true,
    reminderMonths: [5],
    icon: 'sunny-outline',
    tips: [
      'Let wood dry before sealing',
      'Check for loose boards',
      'Replace rotted wood first',
      'Use UV-resistant sealant',
    ],
  },
  {
    id: 'driveway-seal',
    title: 'Seal Driveway',
    description: 'Apply sealant to asphalt driveway to protect from weather and cracks.',
    category: 'exterior',
    frequency: 'annual',
    typicalCost: { min: 100, max: 300 },
    diyDifficulty: 'medium',
    canHandymanDo: true,
    reminderMonths: [5, 6],
    icon: 'car-outline',
    tips: [
      'Fill cracks before sealing',
      'Apply in dry weather',
      'Keep off for 24-48 hours',
    ],
  },
  {
    id: 'window-caulking',
    title: 'Check Window & Door Seals',
    description: 'Inspect and repair caulking around windows and doors.',
    category: 'exterior',
    frequency: 'annual',
    typicalCost: { min: 20, max: 100 },
    diyDifficulty: 'easy',
    canHandymanDo: true,
    reminderMonths: [9, 10],
    icon: 'albums-outline',
    tips: [
      'Check for drafts',
      'Remove old caulk completely',
      'Use weatherstripping for doors',
      'Saves on heating/cooling bills',
    ],
  },

  // ========== SEASONAL ==========
  {
    id: 'winterize-outdoor',
    title: 'Winterize Outdoor Faucets',
    description: 'Disconnect hoses, drain outdoor faucets, and insulate pipes to prevent freezing.',
    category: 'seasonal',
    frequency: 'annual',
    typicalCost: { min: 0, max: 50 },
    diyDifficulty: 'easy',
    canHandymanDo: true,
    reminderMonths: [10, 11],
    icon: 'snow-outline',
    tips: [
      'Disconnect all hoses',
      'Open outdoor faucets to drain',
      'Install faucet covers',
      'Know main water shutoff location',
    ],
    warningSign: 'Do before first freeze',
  },
  {
    id: 'spring-irrigation',
    title: 'Activate Irrigation System',
    description: 'Turn on sprinkler system, check for leaks, and adjust heads.',
    category: 'seasonal',
    frequency: 'annual',
    typicalCost: { min: 50, max: 150 },
    diyDifficulty: 'medium',
    canHandymanDo: true,
    reminderMonths: [3, 4],
    icon: 'water-outline',
    tips: [
      'Turn on gradually to pressurize',
      'Walk each zone looking for leaks',
      'Adjust coverage patterns',
      'Program timer for water restrictions',
    ],
  },
  {
    id: 'fall-irrigation',
    title: 'Winterize Irrigation System',
    description: 'Blow out sprinkler lines to prevent freeze damage.',
    category: 'seasonal',
    frequency: 'annual',
    typicalCost: { min: 75, max: 150 },
    diyDifficulty: 'professional',
    canHandymanDo: false,
    reminderMonths: [10],
    icon: 'leaf-outline',
    tips: [
      'Schedule before first freeze',
      'Requires air compressor',
      'Turn off backflow preventer',
      'Open manual drains',
    ],
  },
  {
    id: 'pool-opening',
    title: 'Pool Opening',
    description: 'Remove cover, start equipment, balance chemicals, and prepare for swimming season.',
    category: 'seasonal',
    frequency: 'annual',
    typicalCost: { min: 200, max: 400 },
    diyDifficulty: 'professional',
    canHandymanDo: false,
    reminderMonths: [4, 5],
    icon: 'sunny-outline',
    tips: [
      'Clean cover before storing',
      'Check pump and filter',
      'Shock the pool',
      'Test water chemistry',
    ],
  },
  {
    id: 'pool-closing',
    title: 'Pool Closing',
    description: 'Winterize pool by balancing chemicals, lowering water, and installing cover.',
    category: 'seasonal',
    frequency: 'annual',
    typicalCost: { min: 200, max: 400 },
    diyDifficulty: 'professional',
    canHandymanDo: false,
    reminderMonths: [9, 10],
    icon: 'moon-outline',
    tips: [
      'Balance chemicals first',
      'Blow out lines',
      'Lower water level',
      'Secure cover tightly',
    ],
  },
  {
    id: 'ac-prep',
    title: 'Prepare A/C for Summer',
    description: 'Clean outdoor unit, check refrigerant levels, and test cooling.',
    category: 'seasonal',
    frequency: 'annual',
    typicalCost: { min: 100, max: 200 },
    diyDifficulty: 'medium',
    canHandymanDo: true,
    reminderMonths: [4, 5],
    icon: 'thermometer-outline',
    tips: [
      'Clean debris from outdoor unit',
      'Trim vegetation 2ft away',
      'Replace filter',
      'Test before hot weather',
    ],
  },

  // ========== APPLIANCES ==========
  {
    id: 'dryer-vent',
    title: 'Clean Dryer Vent',
    description: 'Remove lint buildup from dryer vent to prevent fire hazard.',
    category: 'appliances',
    frequency: 'annual',
    typicalCost: { min: 100, max: 200 },
    diyDifficulty: 'medium',
    canHandymanDo: true,
    reminderMonths: [6],
    icon: 'flame-outline',
    tips: [
      'Disconnect and vacuum hose',
      'Clean from outside vent',
      'Use long brush attachment',
      'Check vent hood operation',
    ],
    warningSign: 'Clothes taking longer to dry, burning smell',
  },
  {
    id: 'refrigerator-coils',
    title: 'Clean Refrigerator Coils',
    description: 'Vacuum condenser coils to improve efficiency and extend appliance life.',
    category: 'appliances',
    frequency: 'semi-annual',
    typicalCost: { min: 0, max: 0 },
    diyDifficulty: 'easy',
    canHandymanDo: true,
    reminderMonths: [3, 9],
    icon: 'cube-outline',
    tips: [
      'Unplug before cleaning',
      'Use brush attachment',
      'Coils on back or bottom',
      'Improves energy efficiency',
    ],
  },
  {
    id: 'dishwasher-clean',
    title: 'Deep Clean Dishwasher',
    description: 'Clean filter, spray arms, and run cleaning cycle.',
    category: 'appliances',
    frequency: 'quarterly',
    typicalCost: { min: 0, max: 10 },
    diyDifficulty: 'easy',
    canHandymanDo: true,
    reminderMonths: [1, 4, 7, 10],
    icon: 'apps-outline',
    tips: [
      'Remove and clean filter',
      'Clear spray arm holes',
      'Run with vinegar or cleaner',
      'Wipe door gasket',
    ],
  },
  {
    id: 'garbage-disposal',
    title: 'Clean Garbage Disposal',
    description: 'Freshen and clean garbage disposal to prevent odors.',
    category: 'appliances',
    frequency: 'monthly',
    typicalCost: { min: 0, max: 5 },
    diyDifficulty: 'easy',
    canHandymanDo: true,
    reminderMonths: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    icon: 'refresh-outline',
    tips: [
      'Ice cubes sharpen blades',
      'Citrus peels for freshness',
      'Never use drain cleaner',
      'Run cold water while operating',
    ],
  },
];

// =============================================================================
// HELPER FUNCTIONS
// =============================================================================

/**
 * Get checklist items due in a specific month
 */
export function getItemsDueInMonth(month: number): ChecklistItem[] {
  return HOME_MAINTENANCE_CHECKLIST.filter(
    item => item.reminderMonths.includes(month)
  );
}

/**
 * Get checklist items by category
 */
export function getItemsByCategory(category: ChecklistCategory): ChecklistItem[] {
  return HOME_MAINTENANCE_CHECKLIST.filter(item => item.category === category);
}

/**
 * Get items that a handyman can do
 */
export function getHandymanItems(): ChecklistItem[] {
  return HOME_MAINTENANCE_CHECKLIST.filter(item => item.canHandymanDo);
}

/**
 * Get items by difficulty level
 */
export function getItemsByDifficulty(difficulty: DIYDifficulty): ChecklistItem[] {
  return HOME_MAINTENANCE_CHECKLIST.filter(item => item.diyDifficulty === difficulty);
}

/**
 * Calculate estimated annual maintenance cost
 */
export function calculateAnnualCost(): { min: number; max: number } {
  return HOME_MAINTENANCE_CHECKLIST.reduce(
    (acc, item) => {
      // Factor in frequency
      let multiplier = 1;
      switch (item.frequency) {
        case 'monthly': multiplier = 12; break;
        case 'quarterly': multiplier = 4; break;
        case 'semi-annual': multiplier = 2; break;
        case 'annual': multiplier = 1; break;
        case 'as-needed': multiplier = 0.5; break;
      }
      return {
        min: acc.min + (item.typicalCost.min * multiplier),
        max: acc.max + (item.typicalCost.max * multiplier),
      };
    },
    { min: 0, max: 0 }
  );
}

/**
 * Get a checklist item by ID
 */
export function getChecklistItemById(id: string): ChecklistItem | undefined {
  return HOME_MAINTENANCE_CHECKLIST.find(item => item.id === id);
}
