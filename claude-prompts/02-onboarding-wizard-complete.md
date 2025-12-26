# Claude Code Prompt: Onboarding Wizard - Complete Implementation

## Context

This is Phase 2 of the Haven onboarding system. Phase 1 created the route structure and shell components. Now we're building out the complete wizard with real forms, validation, state management, and data persistence.

**Project Location:** `/Users/tomburke/Projects/Housing-Manager/`
**Web App Location:** `apps/web/src/`

## Critical Requirements

1. **All forms must be functional** - not just UI placeholders
2. **State must persist across steps** - use React Context or URL state
3. **Every step has "Skip" option** - links to schedule call/visit
4. **Mobile-first responsive design**
5. **Haven branding** - navy (#102a43) and champagne (#c4a574), NO GREEN

---

# PART 1: DATA MODELS & TYPES

## Create Type Definitions

Create a comprehensive types file for all onboarding data:

```typescript
// apps/web/src/types/onboarding.ts

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
```

---

# PART 2: STATE MANAGEMENT

## Create Onboarding Context

Create a React Context to manage onboarding state across all wizard pages:

```typescript
// apps/web/src/context/OnboardingContext.tsx

'use client';

import React, { createContext, useContext, useReducer, useEffect, ReactNode } from 'react';
import { 
  OnboardingData, 
  ServiceTier, 
  OnboardingPath, 
  OnboardingStatus,
  PropertyDetails,
  Bill,
  HomeSystem,
  Appliance,
  FamilyMember,
  Vehicle,
  Pet,
  HouseholdStaff,
} from '@/types/onboarding';

// ============================================
// INITIAL STATE
// ============================================

const initialOnboardingData: OnboardingData = {
  tier: 'haven',
  path: 'self_serve',
  status: 'started',
  startedAt: new Date().toISOString(),
  steps: {
    property: false,
    bills: false,
    systems: false,
    family: false,
    review: false,
  },
  property: null,
  bills: [],
  systems: [],
  appliances: [],
  familyMembers: [],
  vehicles: [],
  pets: [],
  staff: [],
};

// ============================================
// ACTION TYPES
// ============================================

type OnboardingAction =
  | { type: 'SET_TIER'; payload: ServiceTier }
  | { type: 'SET_PATH'; payload: OnboardingPath }
  | { type: 'SET_STATUS'; payload: OnboardingStatus }
  | { type: 'SET_PROPERTY'; payload: PropertyDetails }
  | { type: 'ADD_BILL'; payload: Bill }
  | { type: 'UPDATE_BILL'; payload: Bill }
  | { type: 'REMOVE_BILL'; payload: string }
  | { type: 'SET_BILLS'; payload: Bill[] }
  | { type: 'ADD_SYSTEM'; payload: HomeSystem }
  | { type: 'UPDATE_SYSTEM'; payload: HomeSystem }
  | { type: 'REMOVE_SYSTEM'; payload: string }
  | { type: 'SET_SYSTEMS'; payload: HomeSystem[] }
  | { type: 'ADD_APPLIANCE'; payload: Appliance }
  | { type: 'UPDATE_APPLIANCE'; payload: Appliance }
  | { type: 'REMOVE_APPLIANCE'; payload: string }
  | { type: 'SET_APPLIANCES'; payload: Appliance[] }
  | { type: 'ADD_FAMILY_MEMBER'; payload: FamilyMember }
  | { type: 'UPDATE_FAMILY_MEMBER'; payload: FamilyMember }
  | { type: 'REMOVE_FAMILY_MEMBER'; payload: string }
  | { type: 'SET_FAMILY_MEMBERS'; payload: FamilyMember[] }
  | { type: 'ADD_VEHICLE'; payload: Vehicle }
  | { type: 'UPDATE_VEHICLE'; payload: Vehicle }
  | { type: 'REMOVE_VEHICLE'; payload: string }
  | { type: 'SET_VEHICLES'; payload: Vehicle[] }
  | { type: 'ADD_PET'; payload: Pet }
  | { type: 'UPDATE_PET'; payload: Pet }
  | { type: 'REMOVE_PET'; payload: string }
  | { type: 'SET_PETS'; payload: Pet[] }
  | { type: 'ADD_STAFF'; payload: HouseholdStaff }
  | { type: 'UPDATE_STAFF'; payload: HouseholdStaff }
  | { type: 'REMOVE_STAFF'; payload: string }
  | { type: 'SET_STAFF'; payload: HouseholdStaff[] }
  | { type: 'COMPLETE_STEP'; payload: keyof OnboardingData['steps'] }
  | { type: 'SET_SCHEDULED_CALL'; payload: string }
  | { type: 'SET_SCHEDULED_VISIT'; payload: string }
  | { type: 'SET_ACTIVATION_CALL'; payload: string }
  | { type: 'RESET' }
  | { type: 'LOAD_STATE'; payload: OnboardingData };

// ============================================
// REDUCER
// ============================================

function onboardingReducer(state: OnboardingData, action: OnboardingAction): OnboardingData {
  switch (action.type) {
    case 'SET_TIER':
      return { ...state, tier: action.payload };
    
    case 'SET_PATH':
      return { ...state, path: action.payload, status: 'path_selected' };
    
    case 'SET_STATUS':
      return { ...state, status: action.payload };
    
    case 'SET_PROPERTY':
      return { ...state, property: action.payload };
    
    case 'ADD_BILL':
      return { ...state, bills: [...state.bills, action.payload] };
    
    case 'UPDATE_BILL':
      return {
        ...state,
        bills: state.bills.map(b => b.id === action.payload.id ? action.payload : b),
      };
    
    case 'REMOVE_BILL':
      return { ...state, bills: state.bills.filter(b => b.id !== action.payload) };
    
    case 'SET_BILLS':
      return { ...state, bills: action.payload };
    
    case 'ADD_SYSTEM':
      return { ...state, systems: [...state.systems, action.payload] };
    
    case 'UPDATE_SYSTEM':
      return {
        ...state,
        systems: state.systems.map(s => s.id === action.payload.id ? action.payload : s),
      };
    
    case 'REMOVE_SYSTEM':
      return { ...state, systems: state.systems.filter(s => s.id !== action.payload) };
    
    case 'SET_SYSTEMS':
      return { ...state, systems: action.payload };
    
    case 'ADD_APPLIANCE':
      return { ...state, appliances: [...state.appliances, action.payload] };
    
    case 'UPDATE_APPLIANCE':
      return {
        ...state,
        appliances: state.appliances.map(a => a.id === action.payload.id ? action.payload : a),
      };
    
    case 'REMOVE_APPLIANCE':
      return { ...state, appliances: state.appliances.filter(a => a.id !== action.payload) };
    
    case 'SET_APPLIANCES':
      return { ...state, appliances: action.payload };
    
    case 'ADD_FAMILY_MEMBER':
      return { ...state, familyMembers: [...state.familyMembers, action.payload] };
    
    case 'UPDATE_FAMILY_MEMBER':
      return {
        ...state,
        familyMembers: state.familyMembers.map(m => m.id === action.payload.id ? action.payload : m),
      };
    
    case 'REMOVE_FAMILY_MEMBER':
      return { ...state, familyMembers: state.familyMembers.filter(m => m.id !== action.payload) };
    
    case 'SET_FAMILY_MEMBERS':
      return { ...state, familyMembers: action.payload };
    
    case 'ADD_VEHICLE':
      return { ...state, vehicles: [...state.vehicles, action.payload] };
    
    case 'UPDATE_VEHICLE':
      return {
        ...state,
        vehicles: state.vehicles.map(v => v.id === action.payload.id ? action.payload : v),
      };
    
    case 'REMOVE_VEHICLE':
      return { ...state, vehicles: state.vehicles.filter(v => v.id !== action.payload) };
    
    case 'SET_VEHICLES':
      return { ...state, vehicles: action.payload };
    
    case 'ADD_PET':
      return { ...state, pets: [...state.pets, action.payload] };
    
    case 'UPDATE_PET':
      return {
        ...state,
        pets: state.pets.map(p => p.id === action.payload.id ? action.payload : p),
      };
    
    case 'REMOVE_PET':
      return { ...state, pets: state.pets.filter(p => p.id !== action.payload) };
    
    case 'SET_PETS':
      return { ...state, pets: action.payload };
    
    case 'ADD_STAFF':
      return { ...state, staff: [...state.staff, action.payload] };
    
    case 'UPDATE_STAFF':
      return {
        ...state,
        staff: state.staff.map(s => s.id === action.payload.id ? action.payload : s),
      };
    
    case 'REMOVE_STAFF':
      return { ...state, staff: state.staff.filter(s => s.id !== action.payload) };
    
    case 'SET_STAFF':
      return { ...state, staff: action.payload };
    
    case 'COMPLETE_STEP':
      return {
        ...state,
        steps: { ...state.steps, [action.payload]: true },
      };
    
    case 'SET_SCHEDULED_CALL':
      return { ...state, scheduledCallAt: action.payload };
    
    case 'SET_SCHEDULED_VISIT':
      return { ...state, scheduledVisitAt: action.payload };
    
    case 'SET_ACTIVATION_CALL':
      return { ...state, activationCallAt: action.payload };
    
    case 'RESET':
      return { ...initialOnboardingData, startedAt: new Date().toISOString() };
    
    case 'LOAD_STATE':
      return action.payload;
    
    default:
      return state;
  }
}

// ============================================
// CONTEXT
// ============================================

interface OnboardingContextType {
  data: OnboardingData;
  dispatch: React.Dispatch<OnboardingAction>;
  
  // Helper functions
  setTier: (tier: ServiceTier) => void;
  setPath: (path: OnboardingPath) => void;
  setProperty: (property: PropertyDetails) => void;
  addBill: (bill: Bill) => void;
  updateBill: (bill: Bill) => void;
  removeBill: (id: string) => void;
  addSystem: (system: HomeSystem) => void;
  updateSystem: (system: HomeSystem) => void;
  removeSystem: (id: string) => void;
  addAppliance: (appliance: Appliance) => void;
  updateAppliance: (appliance: Appliance) => void;
  removeAppliance: (id: string) => void;
  addFamilyMember: (member: FamilyMember) => void;
  updateFamilyMember: (member: FamilyMember) => void;
  removeFamilyMember: (id: string) => void;
  addVehicle: (vehicle: Vehicle) => void;
  updateVehicle: (vehicle: Vehicle) => void;
  removeVehicle: (id: string) => void;
  addPet: (pet: Pet) => void;
  updatePet: (pet: Pet) => void;
  removePet: (id: string) => void;
  addStaff: (staff: HouseholdStaff) => void;
  updateStaff: (staff: HouseholdStaff) => void;
  removeStaff: (id: string) => void;
  completeStep: (step: keyof OnboardingData['steps']) => void;
  getCompletedSteps: () => string[];
  getCurrentStep: () => string;
  getNextStep: () => string | null;
  calculateMonthlyTotal: () => number;
  reset: () => void;
}

const OnboardingContext = createContext<OnboardingContextType | undefined>(undefined);

// ============================================
// PROVIDER
// ============================================

const STORAGE_KEY = 'haven_onboarding_data';

export function OnboardingProvider({ children }: { children: ReactNode }) {
  const [data, dispatch] = useReducer(onboardingReducer, initialOnboardingData);

  // Load from localStorage on mount
  useEffect(() => {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (saved) {
      try {
        const parsed = JSON.parse(saved);
        dispatch({ type: 'LOAD_STATE', payload: parsed });
      } catch (e) {
        console.error('Failed to load onboarding state:', e);
      }
    }
  }, []);

  // Save to localStorage on change
  useEffect(() => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
  }, [data]);

  // Helper functions
  const setTier = (tier: ServiceTier) => dispatch({ type: 'SET_TIER', payload: tier });
  const setPath = (path: OnboardingPath) => dispatch({ type: 'SET_PATH', payload: path });
  const setProperty = (property: PropertyDetails) => dispatch({ type: 'SET_PROPERTY', payload: property });
  
  const addBill = (bill: Bill) => dispatch({ type: 'ADD_BILL', payload: bill });
  const updateBill = (bill: Bill) => dispatch({ type: 'UPDATE_BILL', payload: bill });
  const removeBill = (id: string) => dispatch({ type: 'REMOVE_BILL', payload: id });
  
  const addSystem = (system: HomeSystem) => dispatch({ type: 'ADD_SYSTEM', payload: system });
  const updateSystem = (system: HomeSystem) => dispatch({ type: 'UPDATE_SYSTEM', payload: system });
  const removeSystem = (id: string) => dispatch({ type: 'REMOVE_SYSTEM', payload: id });
  
  const addAppliance = (appliance: Appliance) => dispatch({ type: 'ADD_APPLIANCE', payload: appliance });
  const updateAppliance = (appliance: Appliance) => dispatch({ type: 'UPDATE_APPLIANCE', payload: appliance });
  const removeAppliance = (id: string) => dispatch({ type: 'REMOVE_APPLIANCE', payload: id });
  
  const addFamilyMember = (member: FamilyMember) => dispatch({ type: 'ADD_FAMILY_MEMBER', payload: member });
  const updateFamilyMember = (member: FamilyMember) => dispatch({ type: 'UPDATE_FAMILY_MEMBER', payload: member });
  const removeFamilyMember = (id: string) => dispatch({ type: 'REMOVE_FAMILY_MEMBER', payload: id });
  
  const addVehicle = (vehicle: Vehicle) => dispatch({ type: 'ADD_VEHICLE', payload: vehicle });
  const updateVehicle = (vehicle: Vehicle) => dispatch({ type: 'UPDATE_VEHICLE', payload: vehicle });
  const removeVehicle = (id: string) => dispatch({ type: 'REMOVE_VEHICLE', payload: id });
  
  const addPet = (pet: Pet) => dispatch({ type: 'ADD_PET', payload: pet });
  const updatePet = (pet: Pet) => dispatch({ type: 'UPDATE_PET', payload: pet });
  const removePet = (id: string) => dispatch({ type: 'REMOVE_PET', payload: id });
  
  const addStaff = (staff: HouseholdStaff) => dispatch({ type: 'ADD_STAFF', payload: staff });
  const updateStaff = (staff: HouseholdStaff) => dispatch({ type: 'UPDATE_STAFF', payload: staff });
  const removeStaff = (id: string) => dispatch({ type: 'REMOVE_STAFF', payload: id });
  
  const completeStep = (step: keyof OnboardingData['steps']) => dispatch({ type: 'COMPLETE_STEP', payload: step });
  
  const getCompletedSteps = () => {
    return Object.entries(data.steps)
      .filter(([_, completed]) => completed)
      .map(([step]) => step);
  };
  
  const stepOrder = ['property', 'bills', 'systems', 'family', 'review'];
  
  const getCurrentStep = () => {
    for (const step of stepOrder) {
      if (!data.steps[step as keyof OnboardingData['steps']]) {
        return step;
      }
    }
    return 'review';
  };
  
  const getNextStep = () => {
    const current = getCurrentStep();
    const currentIndex = stepOrder.indexOf(current);
    if (currentIndex < stepOrder.length - 1) {
      return stepOrder[currentIndex + 1];
    }
    return null;
  };
  
  const calculateMonthlyTotal = () => {
    return data.bills.reduce((total, bill) => {
      switch (bill.frequency) {
        case 'monthly':
          return total + bill.amount;
        case 'quarterly':
          return total + (bill.amount / 3);
        case 'semi_annual':
          return total + (bill.amount / 6);
        case 'annual':
          return total + (bill.amount / 12);
        case 'one_time':
          return total; // Don't include one-time in monthly
        default:
          return total + bill.amount;
      }
    }, 0);
  };
  
  const reset = () => dispatch({ type: 'RESET' });

  return (
    <OnboardingContext.Provider
      value={{
        data,
        dispatch,
        setTier,
        setPath,
        setProperty,
        addBill,
        updateBill,
        removeBill,
        addSystem,
        updateSystem,
        removeSystem,
        addAppliance,
        updateAppliance,
        removeAppliance,
        addFamilyMember,
        updateFamilyMember,
        removeFamilyMember,
        addVehicle,
        updateVehicle,
        removeVehicle,
        addPet,
        updatePet,
        removePet,
        addStaff,
        updateStaff,
        removeStaff,
        completeStep,
        getCompletedSteps,
        getCurrentStep,
        getNextStep,
        calculateMonthlyTotal,
        reset,
      }}
    >
      {children}
    </OnboardingContext.Provider>
  );
}

// ============================================
// HOOK
// ============================================

export function useOnboarding() {
  const context = useContext(OnboardingContext);
  if (context === undefined) {
    throw new Error('useOnboarding must be used within an OnboardingProvider');
  }
  return context;
}
```

## Update Onboarding Layout to Include Provider

Update the onboarding layout to wrap children with the provider:

```typescript
// apps/web/src/app/onboarding/layout.tsx

import { OnboardingHeader } from '@/components/onboarding/OnboardingHeader';
import { HelpFloatingButton } from '@/components/onboarding/HelpFloatingButton';
import { OnboardingProvider } from '@/context/OnboardingContext';

export default function OnboardingLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <OnboardingProvider>
      <div className="min-h-screen bg-gray-50">
        <OnboardingHeader />
        <main className="pb-24">
          {children}
        </main>
        <HelpFloatingButton />
      </div>
    </OnboardingProvider>
  );
}
```

---

# PART 3: UTILITY FUNCTIONS & HOOKS

## Create ID Generator

```typescript
// apps/web/src/lib/id.ts

export function generateId(): string {
  return `${Date.now()}-${Math.random().toString(36).substring(2, 9)}`;
}
```

## Create Format Utilities

```typescript
// apps/web/src/lib/format.ts

export function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount);
}

export function formatCurrencyWithCents(amount: number): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
  }).format(amount);
}

export function formatPhone(phone: string): string {
  const cleaned = phone.replace(/\D/g, '');
  if (cleaned.length === 10) {
    return `(${cleaned.slice(0, 3)}) ${cleaned.slice(3, 6)}-${cleaned.slice(6)}`;
  }
  return phone;
}

export function formatDate(date: string | Date): string {
  return new Intl.DateTimeFormat('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  }).format(new Date(date));
}
```

---

# PART 4: FORM COMPONENTS

## Create Reusable Form Components

```typescript
// apps/web/src/components/onboarding/forms/FormInput.tsx

'use client';

import { forwardRef, InputHTMLAttributes } from 'react';
import { cn } from '@/lib/utils';

interface FormInputProps extends InputHTMLAttributes<HTMLInputElement> {
  label: string;
  error?: string;
  hint?: string;
  icon?: React.ReactNode;
}

export const FormInput = forwardRef<HTMLInputElement, FormInputProps>(
  ({ label, error, hint, icon, className, ...props }, ref) => {
    return (
      <div className="space-y-1">
        <label className="block text-sm font-medium text-gray-700">
          {label}
          {props.required && <span className="text-red-500 ml-1">*</span>}
        </label>
        <div className="relative">
          {icon && (
            <div className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400">
              {icon}
            </div>
          )}
          <input
            ref={ref}
            className={cn(
              'w-full px-4 py-3 rounded-xl border transition-all outline-none',
              'focus:ring-2 focus:ring-haven-champagne-200',
              icon && 'pl-11',
              error
                ? 'border-red-300 focus:border-red-500'
                : 'border-gray-300 focus:border-haven-champagne-500',
              className
            )}
            {...props}
          />
        </div>
        {hint && !error && (
          <p className="text-sm text-gray-500">{hint}</p>
        )}
        {error && (
          <p className="text-sm text-red-600">{error}</p>
        )}
      </div>
    );
  }
);

FormInput.displayName = 'FormInput';
```

```typescript
// apps/web/src/components/onboarding/forms/FormSelect.tsx

'use client';

import { forwardRef, SelectHTMLAttributes } from 'react';
import { cn } from '@/lib/utils';
import { ChevronDown } from 'lucide-react';

interface Option {
  value: string;
  label: string;
}

interface FormSelectProps extends SelectHTMLAttributes<HTMLSelectElement> {
  label: string;
  options: Option[];
  error?: string;
  hint?: string;
  placeholder?: string;
}

export const FormSelect = forwardRef<HTMLSelectElement, FormSelectProps>(
  ({ label, options, error, hint, placeholder, className, ...props }, ref) => {
    return (
      <div className="space-y-1">
        <label className="block text-sm font-medium text-gray-700">
          {label}
          {props.required && <span className="text-red-500 ml-1">*</span>}
        </label>
        <div className="relative">
          <select
            ref={ref}
            className={cn(
              'w-full px-4 py-3 rounded-xl border transition-all outline-none appearance-none bg-white',
              'focus:ring-2 focus:ring-haven-champagne-200',
              error
                ? 'border-red-300 focus:border-red-500'
                : 'border-gray-300 focus:border-haven-champagne-500',
              className
            )}
            {...props}
          >
            {placeholder && (
              <option value="" disabled>
                {placeholder}
              </option>
            )}
            {options.map((option) => (
              <option key={option.value} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
          <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400 pointer-events-none" />
        </div>
        {hint && !error && (
          <p className="text-sm text-gray-500">{hint}</p>
        )}
        {error && (
          <p className="text-sm text-red-600">{error}</p>
        )}
      </div>
    );
  }
);

FormSelect.displayName = 'FormSelect';
```

```typescript
// apps/web/src/components/onboarding/forms/FormTextarea.tsx

'use client';

import { forwardRef, TextareaHTMLAttributes } from 'react';
import { cn } from '@/lib/utils';

interface FormTextareaProps extends TextareaHTMLAttributes<HTMLTextAreaElement> {
  label: string;
  error?: string;
  hint?: string;
}

export const FormTextarea = forwardRef<HTMLTextAreaElement, FormTextareaProps>(
  ({ label, error, hint, className, ...props }, ref) => {
    return (
      <div className="space-y-1">
        <label className="block text-sm font-medium text-gray-700">
          {label}
          {props.required && <span className="text-red-500 ml-1">*</span>}
        </label>
        <textarea
          ref={ref}
          className={cn(
            'w-full px-4 py-3 rounded-xl border transition-all outline-none resize-none',
            'focus:ring-2 focus:ring-haven-champagne-200',
            error
              ? 'border-red-300 focus:border-red-500'
              : 'border-gray-300 focus:border-haven-champagne-500',
            className
          )}
          {...props}
        />
        {hint && !error && (
          <p className="text-sm text-gray-500">{hint}</p>
        )}
        {error && (
          <p className="text-sm text-red-600">{error}</p>
        )}
      </div>
    );
  }
);

FormTextarea.displayName = 'FormTextarea';
```

```typescript
// apps/web/src/components/onboarding/forms/FormCurrency.tsx

'use client';

import { forwardRef, InputHTMLAttributes, useState } from 'react';
import { cn } from '@/lib/utils';
import { DollarSign } from 'lucide-react';

interface FormCurrencyProps extends Omit<InputHTMLAttributes<HTMLInputElement>, 'onChange' | 'value'> {
  label: string;
  error?: string;
  hint?: string;
  value: number | undefined;
  onChange: (value: number | undefined) => void;
}

export const FormCurrency = forwardRef<HTMLInputElement, FormCurrencyProps>(
  ({ label, error, hint, value, onChange, className, ...props }, ref) => {
    const [displayValue, setDisplayValue] = useState(
      value !== undefined ? value.toString() : ''
    );

    const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
      const raw = e.target.value.replace(/[^0-9.]/g, '');
      setDisplayValue(raw);
      
      const num = parseFloat(raw);
      onChange(isNaN(num) ? undefined : num);
    };

    const handleBlur = () => {
      if (value !== undefined) {
        setDisplayValue(value.toFixed(2));
      }
    };

    return (
      <div className="space-y-1">
        <label className="block text-sm font-medium text-gray-700">
          {label}
          {props.required && <span className="text-red-500 ml-1">*</span>}
        </label>
        <div className="relative">
          <div className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400">
            <DollarSign className="w-5 h-5" />
          </div>
          <input
            ref={ref}
            type="text"
            inputMode="decimal"
            value={displayValue}
            onChange={handleChange}
            onBlur={handleBlur}
            className={cn(
              'w-full pl-11 pr-4 py-3 rounded-xl border transition-all outline-none',
              'focus:ring-2 focus:ring-haven-champagne-200',
              error
                ? 'border-red-300 focus:border-red-500'
                : 'border-gray-300 focus:border-haven-champagne-500',
              className
            )}
            {...props}
          />
        </div>
        {hint && !error && (
          <p className="text-sm text-gray-500">{hint}</p>
        )}
        {error && (
          <p className="text-sm text-red-600">{error}</p>
        )}
      </div>
    );
  }
);

FormCurrency.displayName = 'FormCurrency';
```

```typescript
// apps/web/src/components/onboarding/forms/FormCheckbox.tsx

'use client';

import { forwardRef, InputHTMLAttributes } from 'react';
import { cn } from '@/lib/utils';
import { Check } from 'lucide-react';

interface FormCheckboxProps extends Omit<InputHTMLAttributes<HTMLInputElement>, 'type'> {
  label: string;
  description?: string;
}

export const FormCheckbox = forwardRef<HTMLInputElement, FormCheckboxProps>(
  ({ label, description, className, ...props }, ref) => {
    return (
      <label className="flex items-start gap-3 cursor-pointer group">
        <div className="relative mt-0.5">
          <input
            ref={ref}
            type="checkbox"
            className="sr-only peer"
            {...props}
          />
          <div className={cn(
            'w-5 h-5 rounded border-2 transition-all',
            'border-gray-300 group-hover:border-gray-400',
            'peer-checked:bg-haven-navy-900 peer-checked:border-haven-navy-900',
            'peer-focus:ring-2 peer-focus:ring-haven-champagne-200 peer-focus:ring-offset-2'
          )} />
          <Check className="absolute top-0.5 left-0.5 w-4 h-4 text-white opacity-0 peer-checked:opacity-100 transition-opacity" />
        </div>
        <div>
          <span className="text-sm font-medium text-gray-900">{label}</span>
          {description && (
            <p className="text-sm text-gray-500">{description}</p>
          )}
        </div>
      </label>
    );
  }
);

FormCheckbox.displayName = 'FormCheckbox';
```

```typescript
// apps/web/src/components/onboarding/forms/index.ts

export { FormInput } from './FormInput';
export { FormSelect } from './FormSelect';
export { FormTextarea } from './FormTextarea';
export { FormCurrency } from './FormCurrency';
export { FormCheckbox } from './FormCheckbox';
```

---

# PART 5: WIZARD PAGES - COMPLETE IMPLEMENTATIONS

## Property Page (Complete)

```typescript
// apps/web/src/app/onboarding/wizard/property/page.tsx

'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { 
  MapPin, 
  ArrowRight, 
  Upload, 
  Building2, 
  Home,
  Check,
  X,
  Loader2,
  FileText,
  AlertCircle,
} from 'lucide-react';
import { SkipToHumanBanner } from '@/components/onboarding/SkipToHumanBanner';
import { FormInput, FormSelect } from '@/components/onboarding/forms';
import { useOnboarding } from '@/context/OnboardingContext';
import { isInServiceArea, getServiceAreaName, PropertyDetails } from '@/types/onboarding';
import { cn } from '@/lib/utils';

const PROPERTY_TYPES = [
  { value: 'single_family', label: 'Single Family Home' },
  { value: 'condo', label: 'Condo / Co-op' },
  { value: 'townhouse', label: 'Townhouse' },
  { value: 'multi_family', label: 'Multi-Family' },
  { value: 'estate', label: 'Estate' },
];

export default function PropertyPage() {
  const router = useRouter();
  const { data, setProperty, completeStep } = useOnboarding();
  
  // Form state
  const [street, setStreet] = useState(data.property?.address?.street || '');
  const [unit, setUnit] = useState(data.property?.address?.unit || '');
  const [city, setCity] = useState(data.property?.address?.city || '');
  const [state, setState] = useState(data.property?.address?.state || '');
  const [zipCode, setZipCode] = useState(data.property?.address?.zipCode || '');
  const [propertyName, setPropertyName] = useState(data.property?.propertyName || '');
  const [propertyType, setPropertyType] = useState(data.property?.propertyType || 'single_family');
  const [bedrooms, setBedrooms] = useState(data.property?.bedrooms?.toString() || '');
  const [bathrooms, setBathrooms] = useState(data.property?.bathrooms?.toString() || '');
  const [squareFeet, setSquareFeet] = useState(data.property?.squareFeet?.toString() || '');
  const [yearBuilt, setYearBuilt] = useState(data.property?.yearBuilt?.toString() || '');
  
  // UI state
  const [isValidatingZip, setIsValidatingZip] = useState(false);
  const [serviceArea, setServiceArea] = useState<string | null>(null);
  const [isOutOfArea, setIsOutOfArea] = useState(false);
  const [uploadedFile, setUploadedFile] = useState<File | null>(null);
  const [errors, setErrors] = useState<Record<string, string>>({});

  // Validate ZIP code when it changes
  useEffect(() => {
    if (zipCode.length === 5) {
      setIsValidatingZip(true);
      // Simulate API call
      setTimeout(() => {
        const area = getServiceAreaName(zipCode);
        setServiceArea(area);
        setIsOutOfArea(!area);
        setIsValidatingZip(false);
      }, 500);
    } else {
      setServiceArea(null);
      setIsOutOfArea(false);
    }
  }, [zipCode]);

  const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setUploadedFile(file);
      // TODO: Upload to storage and process
    }
  };

  const validate = (): boolean => {
    const newErrors: Record<string, string> = {};
    
    if (!street.trim()) newErrors.street = 'Street address is required';
    if (!city.trim()) newErrors.city = 'City is required';
    if (!state.trim()) newErrors.state = 'State is required';
    if (!zipCode.trim()) newErrors.zipCode = 'ZIP code is required';
    if (zipCode && !/^\d{5}(-\d{4})?$/.test(zipCode)) {
      newErrors.zipCode = 'Please enter a valid ZIP code';
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleContinue = () => {
    if (!validate()) return;

    const property: PropertyDetails = {
      address: {
        street,
        unit: unit || undefined,
        city,
        state,
        zipCode,
        country: 'USA',
        formatted: `${street}${unit ? ` ${unit}` : ''}, ${city}, ${state} ${zipCode}`,
      },
      propertyName: propertyName || undefined,
      propertyType: propertyType as PropertyDetails['propertyType'],
      bedrooms: bedrooms ? parseInt(bedrooms) : undefined,
      bathrooms: bathrooms ? parseFloat(bathrooms) : undefined,
      squareFeet: squareFeet ? parseInt(squareFeet) : undefined,
      yearBuilt: yearBuilt ? parseInt(yearBuilt) : undefined,
    };

    setProperty(property);
    completeStep('property');
    router.push('/onboarding/wizard/bills');
  };

  return (
    <div className="max-w-2xl mx-auto px-4 py-8">
      <SkipToHumanBanner />

      {/* Header */}
      <div className="text-center mb-8">
        <div className="w-14 h-14 bg-haven-champagne-100 rounded-2xl flex items-center justify-center mx-auto mb-4">
          <Building2 className="w-7 h-7 text-haven-champagne-600" />
        </div>
        <h1 className="text-2xl font-bold text-haven-navy-900 mb-2">
          Let's start with your property
        </h1>
        <p className="text-gray-600">
          Enter your address and basic property details.
        </p>
      </div>

      {/* Form */}
      <div className="bg-white rounded-2xl border border-gray-200 p-6 space-y-6">
        
        {/* Property Name (Optional) */}
        <FormInput
          label="Property Name (optional)"
          placeholder="e.g., Inspiration Farm, Beach House"
          value={propertyName}
          onChange={(e) => setPropertyName(e.target.value)}
          hint="Give your home a nickname if you'd like"
        />

        {/* Address Section */}
        <div className="space-y-4">
          <h3 className="font-medium text-haven-navy-900">Address</h3>
          
          <FormInput
            label="Street Address"
            placeholder="123 Main Street"
            value={street}
            onChange={(e) => setStreet(e.target.value)}
            error={errors.street}
            icon={<MapPin className="w-5 h-5" />}
            required
          />

          <FormInput
            label="Unit / Apt (optional)"
            placeholder="Apt 4B"
            value={unit}
            onChange={(e) => setUnit(e.target.value)}
          />

          <div className="grid grid-cols-2 gap-4">
            <FormInput
              label="City"
              placeholder="Greenwich"
              value={city}
              onChange={(e) => setCity(e.target.value)}
              error={errors.city}
              required
            />
            <FormInput
              label="State"
              placeholder="CT"
              value={state}
              onChange={(e) => setState(e.target.value.toUpperCase().slice(0, 2))}
              error={errors.state}
              maxLength={2}
              required
            />
          </div>

          <div className="relative">
            <FormInput
              label="ZIP Code"
              placeholder="06831"
              value={zipCode}
              onChange={(e) => setZipCode(e.target.value.replace(/\D/g, '').slice(0, 5))}
              error={errors.zipCode}
              maxLength={5}
              required
            />
            
            {/* ZIP Validation Feedback */}
            {isValidatingZip && (
              <div className="flex items-center gap-2 mt-2 text-sm text-gray-500">
                <Loader2 className="w-4 h-4 animate-spin" />
                Checking service area...
              </div>
            )}
            
            {serviceArea && (
              <div className="flex items-center gap-2 mt-2 text-sm text-green-600">
                <Check className="w-4 h-4" />
                Great! We service {serviceArea}
              </div>
            )}
            
            {isOutOfArea && (
              <div className="mt-3 p-4 bg-amber-50 border border-amber-200 rounded-xl">
                <div className="flex items-start gap-3">
                  <AlertCircle className="w-5 h-5 text-amber-500 flex-shrink-0 mt-0.5" />
                  <div>
                    <p className="text-sm font-medium text-amber-800">
                      We're not in your area yet
                    </p>
                    <p className="text-sm text-amber-700 mt-1">
                      We currently service Westchester County, NY and Fairfield County, CT. 
                      We can still do a virtual walkthrough via video call!
                    </p>
                    <Link
                      href="/onboarding/schedule?type=virtual"
                      className="inline-flex items-center gap-1 text-sm font-medium text-amber-800 hover:text-amber-900 mt-2"
                    >
                      Schedule virtual walkthrough →
                    </Link>
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Divider */}
        <div className="border-t border-gray-200" />

        {/* Property Details */}
        <div className="space-y-4">
          <h3 className="font-medium text-haven-navy-900">Property Details</h3>
          
          <FormSelect
            label="Property Type"
            options={PROPERTY_TYPES}
            value={propertyType}
            onChange={(e) => setPropertyType(e.target.value)}
          />

          <div className="grid grid-cols-2 gap-4">
            <FormInput
              label="Bedrooms"
              type="number"
              placeholder="4"
              value={bedrooms}
              onChange={(e) => setBedrooms(e.target.value)}
              min={0}
              max={20}
            />
            <FormInput
              label="Bathrooms"
              type="number"
              placeholder="3.5"
              value={bathrooms}
              onChange={(e) => setBathrooms(e.target.value)}
              min={0}
              max={20}
              step={0.5}
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <FormInput
              label="Square Feet"
              type="number"
              placeholder="2,500"
              value={squareFeet}
              onChange={(e) => setSquareFeet(e.target.value)}
            />
            <FormInput
              label="Year Built"
              type="number"
              placeholder="1985"
              value={yearBuilt}
              onChange={(e) => setYearBuilt(e.target.value)}
              min={1800}
              max={new Date().getFullYear()}
            />
          </div>
        </div>

        {/* Divider */}
        <div className="border-t border-gray-200" />

        {/* Inspection Upload */}
        <div className="space-y-4">
          <h3 className="font-medium text-haven-navy-900">Home Inspection (optional)</h3>
          <p className="text-sm text-gray-500">
            Upload a recent inspection if you have one. We'll extract system details automatically.
          </p>
          
          {!uploadedFile ? (
            <label className="block border-2 border-dashed border-gray-200 rounded-xl p-8 text-center hover:border-haven-champagne-500 transition-colors cursor-pointer group">
              <input
                type="file"
                className="sr-only"
                accept=".pdf,.jpg,.jpeg,.png"
                onChange={handleFileUpload}
              />
              <Upload className="w-8 h-8 text-gray-400 mx-auto mb-2 group-hover:text-haven-champagne-500" />
              <p className="text-sm text-gray-600">
                Drag & drop or <span className="text-haven-champagne-600 font-medium">browse</span>
              </p>
              <p className="text-xs text-gray-400 mt-1">PDF, JPG, or PNG up to 10MB</p>
            </label>
          ) : (
            <div className="flex items-center gap-4 p-4 bg-gray-50 rounded-xl">
              <div className="w-10 h-10 bg-haven-champagne-100 rounded-lg flex items-center justify-center">
                <FileText className="w-5 h-5 text-haven-champagne-600" />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium text-haven-navy-900 truncate">
                  {uploadedFile.name}
                </p>
                <p className="text-xs text-gray-500">
                  {(uploadedFile.size / 1024 / 1024).toFixed(2)} MB
                </p>
              </div>
              <button
                onClick={() => setUploadedFile(null)}
                className="text-gray-400 hover:text-red-500"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
          )}

          {/* Or Get From Town */}
          <div className="relative">
            <div className="absolute inset-0 flex items-center">
              <div className="w-full border-t border-gray-200" />
            </div>
            <div className="relative flex justify-center text-sm">
              <span className="px-3 bg-white text-gray-500">or</span>
            </div>
          </div>

          <button className="w-full py-3 px-4 rounded-xl border border-gray-200 hover:bg-gray-50 text-gray-700 font-medium transition-colors flex items-center justify-center gap-2">
            <Home className="w-5 h-5" />
            Get my inspection from town records
          </button>
          <p className="text-xs text-gray-400 text-center">
            We'll request your inspection report from local records (may take 1-2 business days)
          </p>
        </div>
      </div>

      {/* Navigation */}
      <div className="flex justify-between mt-8">
        <Link
          href="/onboarding/choose-path"
          className="text-gray-600 hover:text-haven-navy-900 py-3 px-4 font-medium transition-colors"
        >
          ← Back
        </Link>
        <button
          onClick={handleContinue}
          className="bg-haven-navy-900 hover:bg-haven-navy-800 text-white py-3 px-6 rounded-xl font-medium flex items-center gap-2 transition-colors"
        >
          Continue
          <ArrowRight className="w-4 h-4" />
        </button>
      </div>
    </div>
  );
}
```

## Bills Page (Complete)

```typescript
// apps/web/src/app/onboarding/wizard/bills/page.tsx

'use client';

import { useState, useMemo } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { 
  Receipt, 
  ArrowRight, 
  ArrowLeft,
  Plus,
  X,
  Check,
  ChevronDown,
  ChevronUp,
  Pencil,
  Trash2,
} from 'lucide-react';
import * as LucideIcons from 'lucide-react';
import { SkipToHumanBanner } from '@/components/onboarding/SkipToHumanBanner';
import { FormInput, FormSelect, FormCurrency, FormCheckbox } from '@/components/onboarding/forms';
import { useOnboarding } from '@/context/OnboardingContext';
import { Bill, BillCategory, BillFrequency, BILL_CATEGORIES } from '@/types/onboarding';
import { generateId } from '@/lib/id';
import { formatCurrency } from '@/lib/format';
import { cn } from '@/lib/utils';

const FREQUENCY_OPTIONS = [
  { value: 'monthly', label: 'Monthly' },
  { value: 'quarterly', label: 'Quarterly' },
  { value: 'semi_annual', label: 'Semi-Annual' },
  { value: 'annual', label: 'Annual' },
  { value: 'one_time', label: 'One-Time' },
];

// Group categories for display
const CATEGORY_GROUPS = [
  { 
    name: 'Housing', 
    categories: ['mortgage', 'property_tax', 'hoa', 'homeowners_insurance', 'umbrella_insurance'] 
  },
  { 
    name: 'Utilities', 
    categories: ['electric', 'gas', 'oil', 'water_sewer', 'trash'] 
  },
  { 
    name: 'Telecom', 
    categories: ['internet', 'cable_streaming', 'cell_phone'] 
  },
  { 
    name: 'Home Services', 
    categories: ['security_monitoring', 'lawn_landscape', 'pool_service', 'cleaning_service', 'pest_control'] 
  },
  { 
    name: 'Family', 
    categories: ['school_tuition', 'activities_lessons', 'camps', 'childcare_nanny', 'pet_care'] 
  },
  { 
    name: 'Vehicles', 
    categories: ['vehicle_payment', 'vehicle_insurance'] 
  },
  { 
    name: 'Other', 
    categories: ['gym_membership', 'subscriptions', 'other'] 
  },
];

export default function BillsPage() {
  const router = useRouter();
  const { data, addBill, updateBill, removeBill, completeStep, calculateMonthlyTotal } = useOnboarding();
  
  // Modal state
  const [isAddingBill, setIsAddingBill] = useState(false);
  const [editingBill, setEditingBill] = useState<Bill | null>(null);
  const [expandedGroups, setExpandedGroups] = useState<string[]>(['Housing', 'Utilities']);
  
  // Form state
  const [selectedCategory, setSelectedCategory] = useState<BillCategory | null>(null);
  const [provider, setProvider] = useState('');
  const [amount, setAmount] = useState<number | undefined>();
  const [frequency, setFrequency] = useState<BillFrequency>('monthly');
  const [dueDay, setDueDay] = useState('');
  const [accountNumber, setAccountNumber] = useState('');
  const [autoPay, setAutoPay] = useState(false);
  const [notes, setNotes] = useState('');
  const [customCategory, setCustomCategory] = useState('');

  const monthlyTotal = calculateMonthlyTotal();

  const billsByGroup = useMemo(() => {
    const grouped: Record<string, Bill[]> = {};
    
    CATEGORY_GROUPS.forEach(group => {
      grouped[group.name] = data.bills.filter(bill => 
        group.categories.includes(bill.category)
      );
    });
    
    return grouped;
  }, [data.bills]);

  const toggleGroup = (groupName: string) => {
    setExpandedGroups(prev => 
      prev.includes(groupName)
        ? prev.filter(g => g !== groupName)
        : [...prev, groupName]
    );
  };

  const resetForm = () => {
    setSelectedCategory(null);
    setProvider('');
    setAmount(undefined);
    setFrequency('monthly');
    setDueDay('');
    setAccountNumber('');
    setAutoPay(false);
    setNotes('');
    setCustomCategory('');
  };

  const openAddModal = (category?: BillCategory) => {
    resetForm();
    if (category) setSelectedCategory(category);
    setIsAddingBill(true);
  };

  const openEditModal = (bill: Bill) => {
    setEditingBill(bill);
    setSelectedCategory(bill.category);
    setProvider(bill.provider);
    setAmount(bill.amount);
    setFrequency(bill.frequency);
    setDueDay(bill.dueDay?.toString() || '');
    setAccountNumber(bill.accountNumber || '');
    setAutoPay(bill.autoPay);
    setNotes(bill.notes || '');
    setCustomCategory(bill.customCategory || '');
    setIsAddingBill(true);
  };

  const handleSaveBill = () => {
    if (!selectedCategory || !provider.trim() || amount === undefined) return;

    const bill: Bill = {
      id: editingBill?.id || generateId(),
      category: selectedCategory,
      customCategory: selectedCategory === 'other' ? customCategory : undefined,
      provider: provider.trim(),
      amount,
      frequency,
      dueDay: dueDay ? parseInt(dueDay) : undefined,
      accountNumber: accountNumber || undefined,
      autoPay,
      notes: notes || undefined,
    };

    if (editingBill) {
      updateBill(bill);
    } else {
      addBill(bill);
    }

    setIsAddingBill(false);
    setEditingBill(null);
    resetForm();
  };

  const handleDeleteBill = (id: string) => {
    if (confirm('Are you sure you want to remove this bill?')) {
      removeBill(id);
    }
  };

  const handleContinue = () => {
    completeStep('bills');
    router.push('/onboarding/wizard/systems');
  };

  const getIcon = (iconName: string) => {
    const Icon = (LucideIcons as Record<string, React.ComponentType<{ className?: string }>>)[iconName];
    return Icon ? <Icon className="w-5 h-5" /> : null;
  };

  return (
    <div className="max-w-2xl mx-auto px-4 py-8">
      <SkipToHumanBanner />

      {/* Header */}
      <div className="text-center mb-8">
        <div className="w-14 h-14 bg-haven-champagne-100 rounded-2xl flex items-center justify-center mx-auto mb-4">
          <Receipt className="w-7 h-7 text-haven-champagne-600" />
        </div>
        <h1 className="text-2xl font-bold text-haven-navy-900 mb-2">
          Your bills & accounts
        </h1>
        <p className="text-gray-600">
          Tell us about your recurring bills so we can manage payments for you.
        </p>
      </div>

      {/* Monthly Total Summary */}
      {data.bills.length > 0 && (
        <div className="bg-haven-navy-900 text-white rounded-2xl p-6 mb-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-white/70 text-sm">Estimated Monthly Total</p>
              <p className="text-3xl font-bold mt-1">{formatCurrency(monthlyTotal)}</p>
            </div>
            <div className="text-right">
              <p className="text-white/70 text-sm">{data.bills.length} bills added</p>
            </div>
          </div>
        </div>
      )}

      {/* Bill Categories */}
      <div className="space-y-4">
        {CATEGORY_GROUPS.map((group) => {
          const groupBills = billsByGroup[group.name];
          const isExpanded = expandedGroups.includes(group.name);
          const hasEntries = groupBills.length > 0;

          return (
            <div 
              key={group.name}
              className="bg-white rounded-2xl border border-gray-200 overflow-hidden"
            >
              {/* Group Header */}
              <button
                onClick={() => toggleGroup(group.name)}
                className="w-full px-6 py-4 flex items-center justify-between hover:bg-gray-50 transition-colors"
              >
                <div className="flex items-center gap-3">
                  <h3 className="font-semibold text-haven-navy-900">{group.name}</h3>
                  {hasEntries && (
                    <span className="bg-haven-champagne-100 text-haven-champagne-700 text-xs font-medium px-2 py-0.5 rounded-full">
                      {groupBills.length}
                    </span>
                  )}
                </div>
                {isExpanded ? (
                  <ChevronUp className="w-5 h-5 text-gray-400" />
                ) : (
                  <ChevronDown className="w-5 h-5 text-gray-400" />
                )}
              </button>

              {/* Group Content */}
              {isExpanded && (
                <div className="px-6 pb-6 space-y-3">
                  {/* Existing bills in this group */}
                  {groupBills.map((bill) => {
                    const catInfo = BILL_CATEGORIES[bill.category];
                    return (
                      <div 
                        key={bill.id}
                        className="flex items-center gap-4 p-4 bg-gray-50 rounded-xl group"
                      >
                        <div className="w-10 h-10 bg-white rounded-lg flex items-center justify-center text-gray-600">
                          {getIcon(catInfo.icon)}
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="font-medium text-haven-navy-900">{bill.provider}</p>
                          <p className="text-sm text-gray-500">
                            {catInfo.label} • {formatCurrency(bill.amount)}/{bill.frequency}
                          </p>
                        </div>
                        <div className="flex items-center gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                          <button
                            onClick={() => openEditModal(bill)}
                            className="p-2 text-gray-400 hover:text-haven-navy-900 hover:bg-white rounded-lg"
                          >
                            <Pencil className="w-4 h-4" />
                          </button>
                          <button
                            onClick={() => handleDeleteBill(bill.id)}
                            className="p-2 text-gray-400 hover:text-red-500 hover:bg-white rounded-lg"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </div>
                      </div>
                    );
                  })}

                  {/* Quick-add buttons for categories in this group */}
                  <div className="flex flex-wrap gap-2 pt-2">
                    {group.categories.map((catKey) => {
                      const cat = BILL_CATEGORIES[catKey as BillCategory];
                      const hasEntry = data.bills.some(b => b.category === catKey);
                      
                      return (
                        <button
                          key={catKey}
                          onClick={() => openAddModal(catKey as BillCategory)}
                          className={cn(
                            'inline-flex items-center gap-2 px-3 py-2 rounded-lg text-sm font-medium transition-colors',
                            hasEntry
                              ? 'bg-green-50 text-green-700 hover:bg-green-100'
                              : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                          )}
                        >
                          {hasEntry && <Check className="w-3 h-3" />}
                          <Plus className={cn('w-3 h-3', hasEntry && 'hidden')} />
                          {cat.label}
                        </button>
                      );
                    })}
                  </div>
                </div>
              )}
            </div>
          );
        })}
      </div>

      {/* Add Bill Button */}
      <button
        onClick={() => openAddModal()}
        className="w-full mt-6 py-4 px-6 border-2 border-dashed border-gray-200 rounded-2xl text-gray-500 hover:border-haven-champagne-500 hover:text-haven-champagne-600 transition-colors flex items-center justify-center gap-2"
      >
        <Plus className="w-5 h-5" />
        Add another bill
      </button>

      {/* Navigation */}
      <div className="flex justify-between mt-8">
        <Link
          href="/onboarding/wizard/property"
          className="text-gray-600 hover:text-haven-navy-900 py-3 px-4 font-medium flex items-center gap-2 transition-colors"
        >
          <ArrowLeft className="w-4 h-4" />
          Back
        </Link>
        <button
          onClick={handleContinue}
          className="bg-haven-navy-900 hover:bg-haven-navy-800 text-white py-3 px-6 rounded-xl font-medium flex items-center gap-2 transition-colors"
        >
          Continue
          <ArrowRight className="w-4 h-4" />
        </button>
      </div>

      {/* Add/Edit Bill Modal */}
      {isAddingBill && (
        <div className="fixed inset-0 bg-black/50 flex items-end sm:items-center justify-center z-50 p-4">
          <div className="bg-white rounded-t-2xl sm:rounded-2xl w-full max-w-lg max-h-[90vh] overflow-y-auto">
            {/* Modal Header */}
            <div className="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between">
              <h2 className="text-lg font-semibold text-haven-navy-900">
                {editingBill ? 'Edit Bill' : 'Add Bill'}
              </h2>
              <button
                onClick={() => {
                  setIsAddingBill(false);
                  setEditingBill(null);
                  resetForm();
                }}
                className="text-gray-400 hover:text-gray-600"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Modal Content */}
            <div className="p-6 space-y-6">
              {/* Category Selection */}
              {!selectedCategory && (
                <div className="space-y-3">
                  <label className="block text-sm font-medium text-gray-700">
                    What type of bill is this?
                  </label>
                  <div className="grid grid-cols-2 gap-2 max-h-64 overflow-y-auto">
                    {Object.entries(BILL_CATEGORIES).map(([key, cat]) => (
                      <button
                        key={key}
                        onClick={() => setSelectedCategory(key as BillCategory)}
                        className="flex items-center gap-2 p-3 rounded-xl border border-gray-200 hover:border-haven-champagne-500 hover:bg-haven-champagne-50 text-left transition-colors"
                      >
                        <span className="text-gray-500">{getIcon(cat.icon)}</span>
                        <span className="text-sm font-medium text-haven-navy-900">{cat.label}</span>
                      </button>
                    ))}
                  </div>
                </div>
              )}

              {/* Bill Details Form */}
              {selectedCategory && (
                <>
                  {/* Selected Category Indicator */}
                  <div className="flex items-center gap-3 p-3 bg-haven-champagne-50 rounded-xl">
                    <div className="w-10 h-10 bg-haven-champagne-100 rounded-lg flex items-center justify-center text-haven-champagne-600">
                      {getIcon(BILL_CATEGORIES[selectedCategory].icon)}
                    </div>
                    <div className="flex-1">
                      <p className="font-medium text-haven-navy-900">
                        {BILL_CATEGORIES[selectedCategory].label}
                      </p>
                    </div>
                    {!editingBill && (
                      <button
                        onClick={() => setSelectedCategory(null)}
                        className="text-sm text-haven-champagne-600 hover:text-haven-champagne-700"
                      >
                        Change
                      </button>
                    )}
                  </div>

                  {/* Custom category name for "Other" */}
                  {selectedCategory === 'other' && (
                    <FormInput
                      label="Category Name"
                      placeholder="e.g., Storage Unit"
                      value={customCategory}
                      onChange={(e) => setCustomCategory(e.target.value)}
                      required
                    />
                  )}

                  <FormInput
                    label="Provider / Company"
                    placeholder="e.g., Eversource, Optimum"
                    value={provider}
                    onChange={(e) => setProvider(e.target.value)}
                    required
                  />

                  <div className="grid grid-cols-2 gap-4">
                    <FormCurrency
                      label="Amount"
                      placeholder="150.00"
                      value={amount}
                      onChange={setAmount}
                      required
                    />
                    <FormSelect
                      label="Frequency"
                      options={FREQUENCY_OPTIONS}
                      value={frequency}
                      onChange={(e) => setFrequency(e.target.value as BillFrequency)}
                    />
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <FormInput
                      label="Due Day (optional)"
                      type="number"
                      placeholder="15"
                      value={dueDay}
                      onChange={(e) => setDueDay(e.target.value)}
                      min={1}
                      max={31}
                      hint="Day of month"
                    />
                    <FormInput
                      label="Account # (optional)"
                      placeholder="****1234"
                      value={accountNumber}
                      onChange={(e) => setAccountNumber(e.target.value)}
                    />
                  </div>

                  <FormCheckbox
                    label="Auto-pay is enabled"
                    description="This bill is set to auto-pay from my bank/card"
                    checked={autoPay}
                    onChange={(e) => setAutoPay(e.target.checked)}
                  />

                  <FormInput
                    label="Notes (optional)"
                    placeholder="Any additional details..."
                    value={notes}
                    onChange={(e) => setNotes(e.target.value)}
                  />
                </>
              )}
            </div>

            {/* Modal Footer */}
            {selectedCategory && (
              <div className="sticky bottom-0 bg-white border-t border-gray-200 px-6 py-4 flex gap-3">
                <button
                  onClick={() => {
                    setIsAddingBill(false);
                    setEditingBill(null);
                    resetForm();
                  }}
                  className="flex-1 py-3 px-4 border border-gray-200 rounded-xl font-medium text-gray-700 hover:bg-gray-50 transition-colors"
                >
                  Cancel
                </button>
                <button
                  onClick={handleSaveBill}
                  disabled={!provider.trim() || amount === undefined}
                  className="flex-1 py-3 px-4 bg-haven-navy-900 text-white rounded-xl font-medium hover:bg-haven-navy-800 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {editingBill ? 'Save Changes' : 'Add Bill'}
                </button>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
```

---

# PART 6: REMAINING WIZARD PAGES

Continue in the same detailed fashion for these pages. I'll provide the structure - implement them fully:

## Systems Page Structure

```typescript
// apps/web/src/app/onboarding/wizard/systems/page.tsx

// Similar structure to bills page, but with:
// - SYSTEM_CATEGORIES and APPLIANCE_CATEGORIES
// - Two sections: "Home Systems" and "Major Appliances"
// - Modal for adding/editing systems with fields:
//   - Category (required)
//   - Brand, Model, Serial Number
//   - Install Date, Age
//   - Last Service Date, Service Vendor, Vendor Phone
//   - Warranty Expiration
//   - Fuel Type (for HVAC, water heater)
//   - Notes
//   - Photo upload (optional)
// - Quick-add buttons for common systems
// - "Schedule home visit to document everything" prominent CTA
```

## Family Page Structure

```typescript
// apps/web/src/app/onboarding/wizard/family/page.tsx

// Four collapsible sections:
// 1. Family Members
//    - Add adults (name, email, phone, occupation)
//    - Add children (name, school, grade, activities, allergies)
// 2. Vehicles
//    - Year, Make, Model, Color, License Plate
//    - Owner (select from family members)
//    - Lease/Own/Finance, Payment amount
// 3. Pets
//    - Name, Species, Breed, Age
//    - Vet info, Food brand
//    - Groomer, Walker
// 4. Household Staff
//    - Role, Name, Phone, Email
//    - Agency, Schedule, Pay rate
```

## Review Page Structure

```typescript
// apps/web/src/app/onboarding/wizard/review/page.tsx

// Summary view showing:
// - Property card with address, details
// - Bills summary with monthly total
// - Systems & Appliances count
// - Family overview
// - Edit buttons for each section
// - "Everything look good?" CTA
// - Continue to Activation Call scheduling
```

## Activation Page Structure

```typescript
// apps/web/src/app/onboarding/activation/page.tsx

// - Explanation of what happens next
// - Monthly total calculation display
// - Calendly embed for 30-min activation call
// - What to expect on the call
// - "Your Home Manager: Sarah Chen" intro
```

## Complete Page Structure

```typescript
// apps/web/src/app/onboarding/complete/page.tsx

// Celebration screen:
// - Confetti or subtle animation
// - "Welcome to Haven, [Name]!"
// - Your next steps card
// - Sarah Chen intro card
// - CTA: "Go to Dashboard"
```

---

# PART 7: UPDATE WIZARD LAYOUT FOR DYNAMIC STEPS

```typescript
// apps/web/src/app/onboarding/wizard/layout.tsx

'use client';

import { usePathname } from 'next/navigation';
import { ProgressStepper } from '@/components/onboarding/ProgressStepper';
import { useOnboarding } from '@/context/OnboardingContext';

const WIZARD_STEPS = [
  { id: 'property', label: 'Property', href: '/onboarding/wizard/property' },
  { id: 'bills', label: 'Bills', href: '/onboarding/wizard/bills' },
  { id: 'systems', label: 'Systems', href: '/onboarding/wizard/systems' },
  { id: 'family', label: 'Family', href: '/onboarding/wizard/family' },
  { id: 'review', label: 'Review', href: '/onboarding/wizard/review' },
];

export default function WizardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  const { data } = useOnboarding();
  
  // Determine current step from URL
  const currentStep = WIZARD_STEPS.find(step => 
    pathname.includes(step.id)
  )?.id || 'property';
  
  // Get completed steps from context
  const completedSteps = Object.entries(data.steps)
    .filter(([_, completed]) => completed)
    .map(([step]) => step);

  return (
    <div>
      <ProgressStepper
        steps={WIZARD_STEPS}
        currentStep={currentStep}
        completedSteps={completedSteps}
      />
      {children}
    </div>
  );
}
```

---

# VERIFICATION CHECKLIST

After implementing, verify:

1. ✅ Types file created at `apps/web/src/types/onboarding.ts`
2. ✅ Context created at `apps/web/src/context/OnboardingContext.tsx`
3. ✅ Form components created in `apps/web/src/components/onboarding/forms/`
4. ✅ Property page is fully functional with validation
5. ✅ Bills page allows adding/editing/deleting bills
6. ✅ Service area validation works for ZIP codes
7. ✅ State persists to localStorage
8. ✅ Progress stepper updates based on completed steps
9. ✅ Navigation between wizard steps works
10. ✅ Skip to human banners appear on all wizard pages
11. ✅ Monthly total calculates correctly
12. ✅ No TypeScript errors: `pnpm build`
13. ✅ Mobile responsive

## Test Flow

1. Go to `/onboarding/welcome`
2. Click through to `/onboarding/choose-path`
3. Select "On my own" → `/onboarding/wizard`
4. Complete property form → Continue
5. Add 2-3 bills → Continue
6. Verify progress saves (refresh page)
7. Check localStorage for `haven_onboarding_data`
