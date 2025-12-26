// ============================================
// ENUMS
// ============================================

export type ServiceTier = 'essentials' | 'lite' | 'haven' | 'haven_plus' | 'estate';

export type OnboardingPath = 'self_serve' | 'guided_call' | 'home_visit' | 'virtual_walkthrough';

export type OnboardingStatus =
  | 'started'
  | 'path_selected'
  | 'property_complete'
  | 'bills_complete'
  | 'systems_complete'
  | 'family_complete'
  | 'review_complete'
  | 'activation_scheduled'
  | 'complete';

// ============================================
// PROPERTY
// ============================================

export interface PropertyAddress {
  street: string;
  unit?: string;
  city: string;
  state: string;
  zipCode: string;
  country: string;
  formatted: string; // Full formatted address
  latitude?: number;
  longitude?: number;
}

export interface PropertyDetails {
  address: PropertyAddress;
  propertyName?: string; // e.g., "Inspiration Farm"
  propertyType: 'single_family' | 'condo' | 'townhouse' | 'multi_family' | 'estate';
  bedrooms?: number;
  bathrooms?: number;
  squareFeet?: number;
  lotSize?: number; // in acres
  lotSizeUnit?: 'acres' | 'sqft';
  yearBuilt?: number;
  purchaseDate?: string;
  purchasePrice?: number;
  estimatedValue?: number;
  inspectionReportUrl?: string;
  inspectionDate?: string;
}

// ============================================
// BILLS & ACCOUNTS
// ============================================

export type BillCategory =
  | 'mortgage'
  | 'property_tax'
  | 'hoa'
  | 'homeowners_insurance'
  | 'umbrella_insurance'
  | 'electric'
  | 'gas'
  | 'oil'
  | 'water_sewer'
  | 'trash'
  | 'internet'
  | 'cable_streaming'
  | 'cell_phone'
  | 'security_monitoring'
  | 'lawn_landscape'
  | 'pool_service'
  | 'cleaning_service'
  | 'pest_control'
  | 'school_tuition'
  | 'activities_lessons'
  | 'camps'
  | 'childcare_nanny'
  | 'pet_care'
  | 'vehicle_payment'
  | 'vehicle_insurance'
  | 'gym_membership'
  | 'subscriptions'
  | 'other';

export type BillFrequency = 'monthly' | 'quarterly' | 'semi_annual' | 'annual' | 'one_time';

export interface Bill {
  id: string;
  category: BillCategory;
  customCategory?: string; // If category is 'other'
  provider: string; // Company name
  accountNumber?: string;
  amount: number;
  frequency: BillFrequency;
  dueDay?: number; // Day of month (1-31)
  autoPay: boolean;
  notes?: string;
}

export const BILL_CATEGORIES: Record<BillCategory, { label: string; icon: string; group: string }> = {
  // Housing
  mortgage: { label: 'Mortgage', icon: 'Home', group: 'Housing' },
  property_tax: { label: 'Property Tax', icon: 'Building2', group: 'Housing' },
  hoa: { label: 'HOA Fees', icon: 'Users', group: 'Housing' },
  homeowners_insurance: { label: 'Homeowners Insurance', icon: 'Shield', group: 'Housing' },
  umbrella_insurance: { label: 'Umbrella Insurance', icon: 'Umbrella', group: 'Housing' },

  // Utilities
  electric: { label: 'Electric', icon: 'Zap', group: 'Utilities' },
  gas: { label: 'Gas', icon: 'Flame', group: 'Utilities' },
  oil: { label: 'Heating Oil', icon: 'Droplet', group: 'Utilities' },
  water_sewer: { label: 'Water & Sewer', icon: 'Droplets', group: 'Utilities' },
  trash: { label: 'Trash & Recycling', icon: 'Trash2', group: 'Utilities' },

  // Telecom
  internet: { label: 'Internet', icon: 'Wifi', group: 'Telecom' },
  cable_streaming: { label: 'Cable / Streaming', icon: 'Tv', group: 'Telecom' },
  cell_phone: { label: 'Cell Phone', icon: 'Smartphone', group: 'Telecom' },

  // Home Services
  security_monitoring: { label: 'Security Monitoring', icon: 'ShieldCheck', group: 'Home Services' },
  lawn_landscape: { label: 'Lawn & Landscape', icon: 'Trees', group: 'Home Services' },
  pool_service: { label: 'Pool Service', icon: 'Waves', group: 'Home Services' },
  cleaning_service: { label: 'Cleaning Service', icon: 'Sparkles', group: 'Home Services' },
  pest_control: { label: 'Pest Control', icon: 'Bug', group: 'Home Services' },

  // Family
  school_tuition: { label: 'School Tuition', icon: 'GraduationCap', group: 'Family' },
  activities_lessons: { label: 'Activities & Lessons', icon: 'Music', group: 'Family' },
  camps: { label: 'Camps', icon: 'Tent', group: 'Family' },
  childcare_nanny: { label: 'Childcare / Nanny', icon: 'Baby', group: 'Family' },
  pet_care: { label: 'Pet Care', icon: 'PawPrint', group: 'Family' },

  // Vehicles
  vehicle_payment: { label: 'Vehicle Payment', icon: 'Car', group: 'Vehicles' },
  vehicle_insurance: { label: 'Vehicle Insurance', icon: 'CarFront', group: 'Vehicles' },

  // Other
  gym_membership: { label: 'Gym Membership', icon: 'Dumbbell', group: 'Other' },
  subscriptions: { label: 'Subscriptions', icon: 'CreditCard', group: 'Other' },
  other: { label: 'Other', icon: 'MoreHorizontal', group: 'Other' },
};

// ============================================
// HOME SYSTEMS
// ============================================

export type SystemCategory =
  | 'hvac_heating'
  | 'hvac_cooling'
  | 'water_heater'
  | 'electrical'
  | 'plumbing'
  | 'sump_pump'
  | 'generator'
  | 'pool_spa'
  | 'septic'
  | 'well'
  | 'security'
  | 'smart_home'
  | 'solar'
  | 'ev_charger';

export type ApplianceCategory =
  | 'refrigerator'
  | 'dishwasher'
  | 'washer'
  | 'dryer'
  | 'oven_range'
  | 'microwave'
  | 'garbage_disposal'
  | 'wine_fridge'
  | 'freezer';

export interface HomeSystem {
  id: string;
  category: SystemCategory;
  brand?: string;
  model?: string;
  serialNumber?: string;
  installDate?: string;
  age?: number; // years
  lastServiceDate?: string;
  serviceVendor?: string;
  serviceVendorPhone?: string;
  warrantyExpiration?: string;
  fuelType?: 'electric' | 'gas' | 'oil' | 'propane' | 'solar';
  notes?: string;
  photos?: string[]; // URLs
}

export interface Appliance {
  id: string;
  category: ApplianceCategory;
  brand?: string;
  model?: string;
  serialNumber?: string;
  purchaseDate?: string;
  warrantyExpiration?: string;
  notes?: string;
  photos?: string[];
}

export const SYSTEM_CATEGORIES: Record<SystemCategory, { label: string; icon: string; description: string }> = {
  hvac_heating: { label: 'Heating System', icon: 'Thermometer', description: 'Furnace, boiler, heat pump' },
  hvac_cooling: { label: 'Cooling System', icon: 'Snowflake', description: 'Central AC, mini-splits' },
  water_heater: { label: 'Water Heater', icon: 'Droplet', description: 'Tank or tankless' },
  electrical: { label: 'Electrical Panel', icon: 'Zap', description: 'Main panel, subpanels' },
  plumbing: { label: 'Plumbing', icon: 'Droplets', description: 'Main shutoff, pipe material' },
  sump_pump: { label: 'Sump Pump', icon: 'ArrowUpFromLine', description: 'Basement water management' },
  generator: { label: 'Generator', icon: 'BatteryCharging', description: 'Standby or portable' },
  pool_spa: { label: 'Pool / Spa', icon: 'Waves', description: 'Pool equipment, hot tub' },
  septic: { label: 'Septic System', icon: 'Container', description: 'Tank, leach field' },
  well: { label: 'Well', icon: 'CircleDot', description: 'Well pump, pressure tank' },
  security: { label: 'Security System', icon: 'ShieldCheck', description: 'Alarm, cameras' },
  smart_home: { label: 'Smart Home', icon: 'Cpu', description: 'Hub, connected devices' },
  solar: { label: 'Solar', icon: 'Sun', description: 'Panels, inverter, battery' },
  ev_charger: { label: 'EV Charger', icon: 'PlugZap', description: 'Electric vehicle charging' },
};

export const APPLIANCE_CATEGORIES: Record<ApplianceCategory, { label: string; icon: string }> = {
  refrigerator: { label: 'Refrigerator', icon: 'Refrigerator' },
  dishwasher: { label: 'Dishwasher', icon: 'Disc' },
  washer: { label: 'Washer', icon: 'Waves' },
  dryer: { label: 'Dryer', icon: 'Wind' },
  oven_range: { label: 'Oven / Range', icon: 'Flame' },
  microwave: { label: 'Microwave', icon: 'Microwave' },
  garbage_disposal: { label: 'Garbage Disposal', icon: 'Trash' },
  wine_fridge: { label: 'Wine Fridge', icon: 'Wine' },
  freezer: { label: 'Freezer', icon: 'Snowflake' },
};

// ============================================
// FAMILY & HOUSEHOLD
// ============================================

export type FamilyMemberType = 'adult' | 'child' | 'other';

export interface FamilyMember {
  id: string;
  type: FamilyMemberType;
  firstName: string;
  lastName: string;
  email?: string;
  phone?: string;
  birthDate?: string;
  relationship?: string; // 'spouse', 'child', 'parent', etc.
  occupation?: string;
  employer?: string;
  school?: string;
  grade?: string;
  allergies?: string[];
  medicalNotes?: string;
  activities?: string[];
  notes?: string;
}

export interface Vehicle {
  id: string;
  year: number;
  make: string;
  model: string;
  color?: string;
  licensePlate?: string;
  vin?: string;
  ownerId?: string; // FamilyMember id
  leaseOrOwn?: 'lease' | 'own' | 'finance';
  paymentAmount?: number;
  insuranceProvider?: string;
  insurancePolicy?: string;
}

export interface Pet {
  id: string;
  name: string;
  species: 'dog' | 'cat' | 'bird' | 'fish' | 'other';
  breed?: string;
  age?: number;
  weight?: number;
  vetName?: string;
  vetPhone?: string;
  vetClinic?: string;
  foodBrand?: string;
  medications?: string[];
  allergies?: string[];
  groomer?: string;
  walker?: string;
  notes?: string;
}

export interface HouseholdStaff {
  id: string;
  role: 'nanny' | 'housekeeper' | 'au_pair' | 'caregiver' | 'personal_assistant' | 'other';
  customRole?: string;
  firstName: string;
  lastName: string;
  phone?: string;
  email?: string;
  agency?: string;
  schedule?: string;
  payAmount?: number;
  payFrequency?: 'hourly' | 'weekly' | 'biweekly' | 'monthly';
  startDate?: string;
  notes?: string;
}

// ============================================
// COMPLETE ONBOARDING STATE
// ============================================

export interface OnboardingData {
  // Meta
  userId?: string;
  tier: ServiceTier;
  path: OnboardingPath;
  status: OnboardingStatus;
  startedAt: string;
  completedAt?: string;

  // Progress
  steps: {
    property: boolean;
    bills: boolean;
    systems: boolean;
    family: boolean;
    review: boolean;
  };

  // Data
  property: PropertyDetails | null;
  bills: Bill[];
  systems: HomeSystem[];
  appliances: Appliance[];
  familyMembers: FamilyMember[];
  vehicles: Vehicle[];
  pets: Pet[];
  staff: HouseholdStaff[];

  // Scheduling
  scheduledCallAt?: string;
  scheduledVisitAt?: string;
  activationCallAt?: string;

  // Calculated
  estimatedMonthlyTotal?: number;
}

// ============================================
// SERVICE AREA
// ============================================

export const SERVICE_AREA_ZIPS = {
  WESTCHESTER_UPPER: [
    '10502', // Armonk
    '10504', // Armonk
    '10506', // Bedford
    '10507', // Bedford Hills
    '10510', // Briarcliff Manor
    '10514', // Chappaqua
    '10518', // Cross River
    '10519', // Croton Falls
    '10520', // Croton-on-Hudson
    '10526', // Goldens Bridge
    '10527', // Granite Springs
    '10528', // Harrison
    '10530', // Hartsdale
    '10532', // Hawthorne
    '10533', // Irvington
    '10536', // Katonah
    '10538', // Larchmont
    '10543', // Mamaroneck
    '10545', // Maryknoll
    '10546', // Millwood
    '10547', // Mohegan Lake
    '10549', // Mount Kisco
    '10560', // North Salem
    '10562', // Ossining
    '10570', // Pleasantville
    '10573', // Port Chester
    '10576', // Pound Ridge
    '10577', // Purchase
    '10578', // Purdys
    '10580', // Rye
    '10583', // Scarsdale
    '10588', // Shrub Oak
    '10589', // Somers
    '10590', // South Salem
    '10591', // Tarrytown
    '10594', // Thornwood
    '10595', // Valhalla
    '10596', // Verplanck
    '10597', // Waccabuc
    '10598', // Yorktown Heights
    '10604', // West Harrison
    '10605', // White Plains
    '10606', // White Plains
    '10607', // White Plains
    '10701', // Yonkers
    '10702', // Yonkers
    '10703', // Yonkers
    '10704', // Yonkers
    '10705', // Yonkers
    '10706', // Hastings-on-Hudson
    '10707', // Tuckahoe
    '10708', // Bronxville
    '10709', // Eastchester
    '10710', // Yonkers
    '10801', // New Rochelle
    '10802', // New Rochelle
    '10803', // Pelham
    '10804', // New Rochelle
    '10805', // New Rochelle
  ],
  FAIRFIELD_COUNTY: [
    '06801', // Bethel
    '06804', // Brookfield
    '06807', // Cos Cob
    '06810', // Danbury
    '06811', // Danbury
    '06812', // New Fairfield
    '06820', // Darien
    '06824', // Fairfield
    '06825', // Fairfield
    '06828', // Easton
    '06830', // Greenwich
    '06831', // Greenwich
    '06840', // New Canaan
    '06850', // Norwalk
    '06851', // Norwalk
    '06852', // Norwalk
    '06853', // Norwalk
    '06854', // Norwalk
    '06855', // Norwalk
    '06856', // Norwalk
    '06857', // Norwalk
    '06858', // Norwalk
    '06860', // Norwalk
    '06870', // Old Greenwich
    '06875', // Redding
    '06876', // Redding Ridge
    '06877', // Ridgefield
    '06878', // Riverside
    '06879', // Ridgefield
    '06880', // Westport
    '06881', // Westport
    '06883', // Weston
    '06889', // Westport
    '06890', // Southport
    '06896', // Redding
    '06897', // Wilton
    '06901', // Stamford
    '06902', // Stamford
    '06903', // Stamford
    '06904', // Stamford
    '06905', // Stamford
    '06906', // Stamford
    '06907', // Stamford
    '06910', // Stamford
    '06911', // Stamford
    '06912', // Stamford
    '06913', // Stamford
    '06914', // Stamford
    '06920', // Stamford
    '06921', // Stamford
    '06922', // Stamford
    '06926', // Stamford
    '06927', // Stamford
  ],
};

export function isInServiceArea(zipCode: string): boolean {
  const allZips = [
    ...SERVICE_AREA_ZIPS.WESTCHESTER_UPPER,
    ...SERVICE_AREA_ZIPS.FAIRFIELD_COUNTY,
  ];
  return allZips.includes(zipCode.substring(0, 5));
}

export function getServiceAreaName(zipCode: string): string | null {
  if (SERVICE_AREA_ZIPS.WESTCHESTER_UPPER.includes(zipCode.substring(0, 5))) {
    return 'Westchester County, NY';
  }
  if (SERVICE_AREA_ZIPS.FAIRFIELD_COUNTY.includes(zipCode.substring(0, 5))) {
    return 'Fairfield County, CT';
  }
  return null;
}
