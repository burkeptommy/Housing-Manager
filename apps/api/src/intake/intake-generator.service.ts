import { Injectable } from '@nestjs/common';
import { PropertyDetails } from '../property/property.service';

// ===========================================================================
// INTAKE SECTION & ITEM TYPES
// ===========================================================================

export type IntakeZone =
  | 'family'
  | 'kitchen'
  | 'laundry'
  | 'garage'
  | 'hvac'
  | 'plumbing'
  | 'exterior'
  | 'electrical'
  | 'utilities'
  | 'housing'
  | 'bills'
  | 'vendors'
  // Comprehensive bill zones
  | 'bills_housing'
  | 'bills_utilities'
  | 'bills_telecom'
  | 'bills_vehicles'
  | 'bills_loans'
  | 'bills_family'
  | 'bills_insurance'
  | 'bills_home_services'
  | 'bills_memberships'
  | 'bills_other';

export type IntakeCategory =
  | 'family_info'
  | 'appliances'
  | 'systems'
  | 'utilities'
  | 'bills'
  | 'vendors'
  | 'maintenance';

export type InputType = 'text' | 'select' | 'date' | 'number' | 'phone' | 'currency' | 'boolean' | 'multi_select' | 'url' | 'percentage';

// Bill category from schema
export type BillCategoryType =
  | 'MORTGAGE' | 'RENT' | 'PROPERTY_TAX' | 'HOA' | 'HOME_INSURANCE'
  | 'ELECTRIC' | 'GAS' | 'WATER_SEWER' | 'OIL_PROPANE' | 'TRASH'
  | 'INTERNET' | 'CABLE_TV' | 'CELL_PHONE' | 'LANDLINE'
  | 'CAR_PAYMENT' | 'AUTO_INSURANCE' | 'CAR_REGISTRATION' | 'PARKING' | 'TOLLS'
  | 'SCHOOL_TUITION' | 'CHILDCARE' | 'NANNY' | 'KIDS_ACTIVITY' | 'SCHOOL_LUNCH' | 'TUTORING'
  | 'STUDENT_LOAN' | 'PERSONAL_LOAN' | 'HELOC' | 'CREDIT_CARD'
  | 'LIFE_INSURANCE' | 'HEALTH_INSURANCE' | 'UMBRELLA_INSURANCE' | 'PET_INSURANCE' | 'DISABILITY_INSURANCE' | 'LONG_TERM_CARE'
  | 'LAWN_LANDSCAPE' | 'POOL_SERVICE' | 'PEST_CONTROL' | 'SECURITY_MONITORING' | 'HOUSE_CLEANING' | 'SNOW_REMOVAL'
  | 'GYM_FITNESS' | 'CLUB_MEMBERSHIP' | 'STREAMING_SERVICE' | 'SOFTWARE_SUBSCRIPTION' | 'NEWSPAPER_MAGAZINE' | 'MEAL_KIT' | 'AMAZON_PRIME' | 'WAREHOUSE_CLUB'
  | 'STORAGE' | 'PET_CARE' | 'CHARITY_DONATION' | 'CHILD_SUPPORT' | 'ALIMONY' | 'OTHER_BILL';

// Comprehensive Bill Intake Item - extends standard with bill-specific fields
export interface BillIntakeItem {
  id: string;
  billCategory: BillCategoryType;
  label: string;
  description?: string;
  icon?: string;
  // Field configuration
  fields: BillFieldConfig[];
  // Conditional display
  showIf?: (context: BillIntakeContext) => boolean;
  // Pre-fill from property data
  prefillFrom?: string;
}

export interface BillFieldConfig {
  id: string;
  label: string;
  inputType: InputType;
  required: boolean;
  options?: string[];
  placeholder?: string;
  helpText?: string;
  conditional?: (values: Record<string, any>) => boolean;
}

export interface BillIntakeContext {
  hasPool: boolean;
  hasChildren: boolean;
  hasVehicles: boolean;
  vehicleCount: number;
  hasGasService: boolean;
  hasMortgage: boolean;
  hasPets: boolean;
  hasStaff: boolean;
  state?: string;
  propertyData?: PropertyDetails | null;
  previousAnswers: Record<string, any>;
}

export interface BillIntakeSection {
  id: IntakeZone;
  title: string;
  description: string;
  icon: string;
  bills: BillIntakeItem[];
  showIf?: (context: BillIntakeContext) => boolean;
}

export interface IntakeItem {
  id: string;
  zone: IntakeZone;
  category: IntakeCategory;
  label: string;
  question: string;
  context?: string; // Additional info from property data or previous answers
  inputType: InputType;
  options?: string[];
  required: boolean;
  applianceType?: string; // For appliance items, what type of appliance
  billCategory?: string; // For bill items, what VendorCategory to use
  repeatFor?: 'family_members' | 'vehicles' | 'pets'; // If this question repeats per person/item
}

export interface IntakeSection {
  id: IntakeZone;
  title: string;
  description: string;
  icon: string;
  items: IntakeItem[];
  conditionallyShow?: (propertyData: PropertyDetails | null) => boolean;
}

// ===========================================================================
// INTAKE GENERATOR SERVICE
// ===========================================================================

@Injectable()
export class IntakeGeneratorService {
  /**
   * Generates the complete intake sections for a comprehensive Home Manager call.
   * This covers everything needed for a 30-45 minute intro call.
   */
  generateIntakeSections(
    propertyData: PropertyDetails | null,
    state?: string,
  ): IntakeSection[] {
    const sections: IntakeSection[] = [];

    // ===========================================================================
    // 1. FAMILY INFORMATION
    // ===========================================================================
    sections.push({
      id: 'family',
      title: 'Family & Household',
      description: 'Who lives in the home and their needs',
      icon: '👨‍👩‍👧‍👦',
      items: [
        {
          id: 'adults_in_home',
          zone: 'family',
          category: 'family_info',
          label: 'Adults in household',
          question: 'How many adults live in the home?',
          inputType: 'number',
          required: true,
        },
        {
          id: 'children_count',
          zone: 'family',
          category: 'family_info',
          label: 'Children',
          question: 'How many children? (And what are their ages?)',
          inputType: 'text',
          required: false,
        },
        {
          id: 'pets',
          zone: 'family',
          category: 'family_info',
          label: 'Pets',
          question: 'Do you have any pets? (Type, names, any special needs)',
          inputType: 'text',
          required: false,
        },
        {
          id: 'household_staff',
          zone: 'family',
          category: 'family_info',
          label: 'Household staff',
          question: 'Do you have any household staff? (Nanny, housekeeper, etc.)',
          inputType: 'text',
          required: false,
        },
        {
          id: 'kids_activities',
          zone: 'family',
          category: 'family_info',
          label: 'Kids activities',
          question: 'What activities are the kids involved in? (Sports, lessons, etc.)',
          inputType: 'text',
          required: false,
        },
        {
          id: 'special_needs',
          zone: 'family',
          category: 'family_info',
          label: 'Special considerations',
          question: 'Any special accessibility needs or considerations?',
          inputType: 'text',
          required: false,
        },
      ],
    });

    // ===========================================================================
    // 2. KITCHEN APPLIANCES
    // ===========================================================================
    sections.push({
      id: 'kitchen',
      title: 'Kitchen',
      description: 'Appliances, equipment, and services',
      icon: '🍳',
      items: [
        {
          id: 'refrigerator',
          zone: 'kitchen',
          category: 'appliances',
          label: 'Refrigerator',
          question: 'What type of refrigerator? (Brand/model if known, how old?)',
          inputType: 'text',
          required: false,
          applianceType: 'REFRIGERATOR',
        },
        {
          id: 'refrigerator_issues',
          zone: 'kitchen',
          category: 'appliances',
          label: 'Refrigerator issues',
          question: 'Any issues with the refrigerator?',
          inputType: 'text',
          required: false,
        },
        {
          id: 'oven_range',
          zone: 'kitchen',
          category: 'appliances',
          label: 'Oven/Range',
          question: 'Oven/range type? (Gas or electric, brand, age)',
          inputType: 'select',
          options: ['Gas range', 'Electric range', 'Induction', 'Double oven', 'Wall oven + cooktop'],
          required: false,
          applianceType: 'OVEN',
        },
        {
          id: 'dishwasher',
          zone: 'kitchen',
          category: 'appliances',
          label: 'Dishwasher',
          question: 'Dishwasher brand/age? Any issues?',
          inputType: 'text',
          required: false,
          applianceType: 'DISHWASHER',
        },
        {
          id: 'microwave',
          zone: 'kitchen',
          category: 'appliances',
          label: 'Microwave',
          question: 'Built-in or countertop microwave?',
          inputType: 'select',
          options: ['Built-in over range', 'Built-in trim kit', 'Countertop', 'None'],
          required: false,
          applianceType: 'MICROWAVE',
        },
        {
          id: 'garbage_disposal',
          zone: 'kitchen',
          category: 'appliances',
          label: 'Garbage disposal',
          question: 'Do you have a garbage disposal? Working properly?',
          inputType: 'select',
          options: ['Yes, working', 'Yes, needs repair', 'No'],
          required: false,
          applianceType: 'GARBAGE_DISPOSAL',
        },
        {
          id: 'wine_fridge',
          zone: 'kitchen',
          category: 'appliances',
          label: 'Wine fridge',
          question: 'Wine refrigerator or beverage cooler?',
          inputType: 'text',
          required: false,
          applianceType: 'WINE_FRIDGE',
        },
        {
          id: 'water_filter',
          zone: 'kitchen',
          category: 'appliances',
          label: 'Water filter',
          question: 'Water filtration system? (Under sink, whole house, fridge)',
          inputType: 'text',
          required: false,
          applianceType: 'WATER_FILTER',
        },
      ],
    });

    // ===========================================================================
    // 3. LAUNDRY
    // ===========================================================================
    sections.push({
      id: 'laundry',
      title: 'Laundry',
      description: 'Washer, dryer, and laundry services',
      icon: '🧺',
      items: [
        {
          id: 'washer',
          zone: 'laundry',
          category: 'appliances',
          label: 'Washing machine',
          question: 'Washer brand/type? (Top load, front load, how old?)',
          inputType: 'text',
          required: false,
          applianceType: 'WASHER',
        },
        {
          id: 'dryer',
          zone: 'laundry',
          category: 'appliances',
          label: 'Dryer',
          question: 'Dryer type? (Electric or gas, brand, age)',
          inputType: 'select',
          options: ['Electric dryer', 'Gas dryer', 'Heat pump dryer', 'Ventless dryer'],
          required: false,
          applianceType: 'DRYER',
        },
        {
          id: 'dryer_vent_cleaning',
          zone: 'laundry',
          category: 'maintenance',
          label: 'Dryer vent cleaning',
          question: 'When was the dryer vent last cleaned?',
          inputType: 'date',
          required: false,
        },
        {
          id: 'laundry_service',
          zone: 'laundry',
          category: 'vendors',
          label: 'Laundry service',
          question: 'Do you use a laundry or dry cleaning service?',
          inputType: 'text',
          required: false,
        },
      ],
    });

    // ===========================================================================
    // 4. GARAGE
    // ===========================================================================
    const garageSpaces = propertyData?.garageSpaces || 0;
    sections.push({
      id: 'garage',
      title: 'Garage & Vehicles',
      description: 'Garage systems and vehicle information',
      icon: '🚗',
      conditionallyShow: () => garageSpaces > 0,
      items: [
        {
          id: 'garage_door_opener',
          zone: 'garage',
          category: 'systems',
          label: 'Garage door opener',
          question: 'Garage door opener brand/type?',
          inputType: 'text',
          required: false,
          context: garageSpaces > 0 ? `${garageSpaces}-car garage` : undefined,
        },
        {
          id: 'garage_door_service',
          zone: 'garage',
          category: 'vendors',
          label: 'Garage door service',
          question: 'Who services your garage door?',
          inputType: 'text',
          required: false,
        },
        {
          id: 'vehicles',
          zone: 'garage',
          category: 'family_info',
          label: 'Vehicles',
          question: 'What vehicles does the family have? (Make, model, year)',
          inputType: 'text',
          required: false,
        },
        {
          id: 'preferred_mechanic',
          zone: 'garage',
          category: 'vendors',
          label: 'Preferred mechanic',
          question: 'Do you have a preferred mechanic or dealer for service?',
          inputType: 'text',
          required: false,
        },
        {
          id: 'ev_charger',
          zone: 'garage',
          category: 'systems',
          label: 'EV charger',
          question: 'Do you have an EV charger? (Level 2, brand)',
          inputType: 'text',
          required: false,
        },
      ],
    });

    // ===========================================================================
    // 5. HVAC / CLIMATE
    // ===========================================================================
    sections.push({
      id: 'hvac',
      title: 'HVAC & Climate',
      description: 'Heating, cooling, and air quality',
      icon: '🌡️',
      items: [
        {
          id: 'heating_type',
          zone: 'hvac',
          category: 'systems',
          label: 'Heating system',
          question: 'What type of heating system?',
          inputType: 'select',
          options: ['Gas furnace', 'Oil furnace', 'Boiler (steam)', 'Boiler (hot water)', 'Heat pump', 'Electric baseboard', 'Radiant floor', 'Other'],
          required: true,
          context: propertyData?.heatingType ? `Records show: ${propertyData.heatingType}` : undefined,
        },
        {
          id: 'heating_brand',
          zone: 'hvac',
          category: 'systems',
          label: 'Heating brand',
          question: 'Brand and approximate age of heating system?',
          inputType: 'text',
          required: false,
        },
        {
          id: 'hvac_service',
          zone: 'hvac',
          category: 'vendors',
          label: 'HVAC service',
          question: 'Who services your heating/cooling?',
          inputType: 'text',
          required: true,
        },
        {
          id: 'hvac_last_service',
          zone: 'hvac',
          category: 'maintenance',
          label: 'Last HVAC service',
          question: 'When was it last serviced?',
          inputType: 'date',
          required: false,
        },
        {
          id: 'cooling_type',
          zone: 'hvac',
          category: 'systems',
          label: 'Cooling system',
          question: 'Cooling system type?',
          inputType: 'select',
          options: ['Central AC', 'Heat pump', 'Mini-split', 'Window units', 'None'],
          required: false,
          context: propertyData?.coolingType ? `Records show: ${propertyData.coolingType}` : undefined,
        },
        {
          id: 'filter_size',
          zone: 'hvac',
          category: 'systems',
          label: 'Filter size',
          question: 'What size HVAC filter do you use?',
          inputType: 'text',
          required: false,
        },
        {
          id: 'thermostat',
          zone: 'hvac',
          category: 'systems',
          label: 'Thermostat',
          question: 'What type of thermostat? (Nest, Ecobee, traditional)',
          inputType: 'text',
          required: false,
        },
        {
          id: 'humidifier',
          zone: 'hvac',
          category: 'systems',
          label: 'Humidifier/dehumidifier',
          question: 'Whole-house humidifier or dehumidifier?',
          inputType: 'text',
          required: false,
        },
        ...(this.needsOilHeating(propertyData) ? [
          {
            id: 'oil_provider',
            zone: 'hvac' as IntakeZone,
            category: 'vendors' as IntakeCategory,
            label: 'Oil provider',
            question: 'Who delivers your heating oil?',
            inputType: 'text' as InputType,
            required: true,
            context: 'Oil heat system detected',
          },
          {
            id: 'oil_tank_location',
            zone: 'hvac' as IntakeZone,
            category: 'systems' as IntakeCategory,
            label: 'Oil tank',
            question: 'Where is the oil tank? (Basement, underground, above ground)',
            inputType: 'select' as InputType,
            options: ['Basement', 'Underground', 'Above ground outside', 'Garage'],
            required: false,
          },
        ] : []),
        ...(this.needsPropane(propertyData) ? [
          {
            id: 'propane_provider',
            zone: 'hvac' as IntakeZone,
            category: 'vendors' as IntakeCategory,
            label: 'Propane provider',
            question: 'Who is your propane provider?',
            inputType: 'text' as InputType,
            required: true,
            context: 'Propane system detected',
          },
        ] : []),
        ...(this.hasFireplace(propertyData) ? [
          {
            id: 'fireplace_type',
            zone: 'hvac' as IntakeZone,
            category: 'systems' as IntakeCategory,
            label: 'Fireplace',
            question: `What type is your fireplace${propertyData?.fireplaces && propertyData.fireplaces > 1 ? 's' : ''}?`,
            inputType: 'select' as InputType,
            options: ['Wood burning', 'Gas', 'Electric', 'Pellet', 'Mixed types'],
            required: false,
            context: `${propertyData?.fireplaces} fireplace(s)`,
          },
          {
            id: 'chimney_sweep',
            zone: 'hvac' as IntakeZone,
            category: 'vendors' as IntakeCategory,
            label: 'Chimney sweep',
            question: 'Who sweeps your chimney?',
            inputType: 'text' as InputType,
            required: false,
          },
          {
            id: 'chimney_last_cleaned',
            zone: 'hvac' as IntakeZone,
            category: 'maintenance' as IntakeCategory,
            label: 'Last chimney cleaning',
            question: 'When was the chimney last cleaned?',
            inputType: 'date' as InputType,
            required: false,
          },
        ] : []),
      ],
    });

    // ===========================================================================
    // 6. PLUMBING
    // ===========================================================================
    sections.push({
      id: 'plumbing',
      title: 'Plumbing',
      description: 'Water systems, water heater, and fixtures',
      icon: '🚿',
      items: [
        {
          id: 'water_heater_type',
          zone: 'plumbing',
          category: 'systems',
          label: 'Water heater',
          question: 'What type of water heater?',
          inputType: 'select',
          options: ['Gas tank', 'Electric tank', 'Tankless gas', 'Tankless electric', 'Heat pump', 'Solar', 'Boiler-fed'],
          required: true,
        },
        {
          id: 'water_heater_age',
          zone: 'plumbing',
          category: 'systems',
          label: 'Water heater age',
          question: 'How old is the water heater?',
          inputType: 'text',
          required: false,
        },
        {
          id: 'plumber',
          zone: 'plumbing',
          category: 'vendors',
          label: 'Plumber',
          question: 'Do you have a plumber you use?',
          inputType: 'text',
          required: false,
        },
        {
          id: 'water_softener',
          zone: 'plumbing',
          category: 'systems',
          label: 'Water softener',
          question: 'Do you have a water softener?',
          inputType: 'select',
          options: ['Yes', 'No'],
          required: false,
        },
        {
          id: 'sump_pump',
          zone: 'plumbing',
          category: 'systems',
          label: 'Sump pump',
          question: 'Do you have a sump pump? Battery backup?',
          inputType: 'text',
          required: false,
        },
        ...(this.hasSeptic(propertyData) ? [
          {
            id: 'septic_service',
            zone: 'plumbing' as IntakeZone,
            category: 'vendors' as IntakeCategory,
            label: 'Septic service',
            question: 'Who services your septic system?',
            inputType: 'text' as InputType,
            required: true,
            context: 'Septic system (not municipal sewer)',
          },
          {
            id: 'septic_last_pumped',
            zone: 'plumbing' as IntakeZone,
            category: 'maintenance' as IntakeCategory,
            label: 'Last septic pump',
            question: 'When was it last pumped?',
            inputType: 'date' as InputType,
            required: false,
            context: 'Recommended every 3-5 years',
          },
          {
            id: 'septic_tank_size',
            zone: 'plumbing' as IntakeZone,
            category: 'systems' as IntakeCategory,
            label: 'Septic tank size',
            question: 'Do you know the tank size?',
            inputType: 'text' as InputType,
            required: false,
          },
        ] : []),
        ...(this.hasWell(propertyData) ? [
          {
            id: 'well_service',
            zone: 'plumbing' as IntakeZone,
            category: 'vendors' as IntakeCategory,
            label: 'Well service',
            question: 'Who services your well?',
            inputType: 'text' as InputType,
            required: false,
            context: 'Well water',
          },
          {
            id: 'well_last_tested',
            zone: 'plumbing' as IntakeZone,
            category: 'maintenance' as IntakeCategory,
            label: 'Last well test',
            question: 'When was the water last tested?',
            inputType: 'date' as InputType,
            required: false,
            context: 'Annual testing recommended',
          },
        ] : []),
      ],
    });

    // ===========================================================================
    // 7. EXTERIOR
    // ===========================================================================
    sections.push({
      id: 'exterior',
      title: 'Exterior & Landscaping',
      description: 'Roof, siding, landscaping, pool, and outdoor areas',
      icon: '🏡',
      items: [
        {
          id: 'roof_age',
          zone: 'exterior',
          category: 'systems',
          label: 'Roof age',
          question: 'How old is the roof?',
          inputType: 'text',
          required: false,
          context: propertyData?.roofMaterial ? `${propertyData.roofMaterial} roof` : undefined,
        },
        {
          id: 'roofer',
          zone: 'exterior',
          category: 'vendors',
          label: 'Roofer',
          question: 'Do you have a roofer you use?',
          inputType: 'text',
          required: false,
        },
        {
          id: 'gutter_service',
          zone: 'exterior',
          category: 'vendors',
          label: 'Gutter service',
          question: 'Who cleans your gutters?',
          inputType: 'text',
          required: false,
        },
        {
          id: 'gutter_last_cleaned',
          zone: 'exterior',
          category: 'maintenance',
          label: 'Last gutter cleaning',
          question: 'When were they last cleaned?',
          inputType: 'date',
          required: false,
        },
        {
          id: 'lawn_service',
          zone: 'exterior',
          category: 'vendors',
          label: 'Lawn service',
          question: 'Do you have a lawn/landscaping service?',
          inputType: 'text',
          required: false,
          context: propertyData?.lotSizeAcres ? `${propertyData.lotSizeAcres.toFixed(2)} acre lot` : undefined,
        },
        {
          id: 'lawn_equipment',
          zone: 'exterior',
          category: 'systems',
          label: 'Lawn equipment',
          question: 'What lawn equipment do you own? (Mower, blower, trimmer)',
          inputType: 'text',
          required: false,
        },
        {
          id: 'irrigation',
          zone: 'exterior',
          category: 'systems',
          label: 'Irrigation',
          question: 'Do you have an irrigation/sprinkler system?',
          inputType: 'select',
          options: ['Yes - automatic', 'Yes - manual zones', 'No'],
          required: false,
        },
        ...(this.hasPool(propertyData) ? [
          {
            id: 'pool_type',
            zone: 'exterior' as IntakeZone,
            category: 'systems' as IntakeCategory,
            label: 'Pool type',
            question: 'What type of pool?',
            inputType: 'select' as InputType,
            options: ['In-ground chlorine', 'In-ground salt', 'Above ground', 'Hot tub/spa only'],
            required: false,
            context: `Property has ${propertyData?.poolType || 'pool'}`,
          },
          {
            id: 'pool_service',
            zone: 'exterior' as IntakeZone,
            category: 'vendors' as IntakeCategory,
            label: 'Pool service',
            question: 'Who services your pool?',
            inputType: 'text' as InputType,
            required: true,
          },
          {
            id: 'pool_opening',
            zone: 'exterior' as IntakeZone,
            category: 'maintenance' as IntakeCategory,
            label: 'Pool opening',
            question: 'When do you typically open the pool?',
            inputType: 'select' as InputType,
            options: ['April', 'May', 'June', 'Year-round'],
            required: false,
          },
        ] : []),
        {
          id: 'deck_patio',
          zone: 'exterior',
          category: 'systems',
          label: 'Deck/patio',
          question: 'Do you have a deck or patio? Material and condition?',
          inputType: 'text',
          required: false,
        },
        {
          id: 'fence',
          zone: 'exterior',
          category: 'systems',
          label: 'Fence',
          question: 'Do you have a fence? Type and condition?',
          inputType: 'text',
          required: false,
        },
        ...(this.needsSnowRemoval(state) ? [
          {
            id: 'snow_removal',
            zone: 'exterior' as IntakeZone,
            category: 'vendors' as IntakeCategory,
            label: 'Snow removal',
            question: 'Who handles snow removal?',
            inputType: 'text' as InputType,
            required: false,
            context: 'Winter maintenance',
          },
        ] : []),
        {
          id: 'pest_control',
          zone: 'exterior',
          category: 'vendors',
          label: 'Pest control',
          question: 'Do you use a pest control service?',
          inputType: 'text',
          required: false,
        },
      ],
    });

    // ===========================================================================
    // 8. ELECTRICAL & TECH
    // ===========================================================================
    sections.push({
      id: 'electrical',
      title: 'Electrical & Technology',
      description: 'Electrical panel, smart home, security',
      icon: '⚡',
      items: [
        {
          id: 'electrical_panel',
          zone: 'electrical',
          category: 'systems',
          label: 'Electrical panel',
          question: 'Electrical panel amps? (100, 200, 400)',
          inputType: 'select',
          options: ['100 amp', '200 amp', '400 amp', "Don't know"],
          required: false,
        },
        {
          id: 'electrician',
          zone: 'electrical',
          category: 'vendors',
          label: 'Electrician',
          question: 'Do you have an electrician you use?',
          inputType: 'text',
          required: false,
        },
        {
          id: 'generator',
          zone: 'electrical',
          category: 'systems',
          label: 'Generator',
          question: 'Do you have a backup generator?',
          inputType: 'select',
          options: ['Whole-house generator', 'Portable generator', 'Battery backup (Powerwall)', 'None'],
          required: false,
        },
        {
          id: 'solar_panels',
          zone: 'electrical',
          category: 'systems',
          label: 'Solar panels',
          question: 'Do you have solar panels? (Owned or leased)',
          inputType: 'select',
          options: ['Owned', 'Leased/PPA', 'No'],
          required: false,
        },
        {
          id: 'security_system',
          zone: 'electrical',
          category: 'systems',
          label: 'Security system',
          question: 'Security/alarm system? Who monitors?',
          inputType: 'text',
          required: false,
        },
        {
          id: 'smart_home',
          zone: 'electrical',
          category: 'systems',
          label: 'Smart home',
          question: 'Smart home platform? (Ring, Nest, Apple, etc.)',
          inputType: 'text',
          required: false,
        },
        {
          id: 'internet_provider',
          zone: 'electrical',
          category: 'utilities',
          label: 'Internet',
          question: 'Who is your internet provider?',
          inputType: 'text',
          required: true,
        },
        {
          id: 'wifi_issues',
          zone: 'electrical',
          category: 'systems',
          label: 'WiFi coverage',
          question: 'Any WiFi dead spots or issues?',
          inputType: 'text',
          required: false,
        },
      ],
    });

    // ===========================================================================
    // 9. UTILITIES
    // ===========================================================================
    sections.push({
      id: 'utilities',
      title: 'Utilities',
      description: 'Electric, gas, water providers and accounts',
      icon: '💡',
      items: [
        {
          id: 'electric_provider',
          zone: 'utilities',
          category: 'utilities',
          label: 'Electric',
          question: 'Who is your electric provider?',
          inputType: 'text',
          required: true,
          billCategory: 'ELECTRIC',
        },
        {
          id: 'electric_monthly',
          zone: 'utilities',
          category: 'bills',
          label: 'Electric cost',
          question: 'Typical monthly electric bill?',
          inputType: 'currency',
          required: false,
        },
        ...(this.needsGas(propertyData) ? [
          {
            id: 'gas_provider',
            zone: 'utilities' as IntakeZone,
            category: 'utilities' as IntakeCategory,
            label: 'Gas',
            question: 'Who is your gas provider?',
            inputType: 'text' as InputType,
            required: true,
            billCategory: 'GAS',
          },
          {
            id: 'gas_monthly',
            zone: 'utilities' as IntakeZone,
            category: 'bills' as IntakeCategory,
            label: 'Gas cost',
            question: 'Typical monthly gas bill?',
            inputType: 'currency' as InputType,
            required: false,
          },
        ] : []),
        ...(!this.hasWell(propertyData) ? [
          {
            id: 'water_provider',
            zone: 'utilities' as IntakeZone,
            category: 'utilities' as IntakeCategory,
            label: 'Water/Sewer',
            question: 'Who bills you for water/sewer?',
            inputType: 'text' as InputType,
            required: false,
            billCategory: 'WATER_SEWER',
          },
          {
            id: 'water_monthly',
            zone: 'utilities' as IntakeZone,
            category: 'bills' as IntakeCategory,
            label: 'Water cost',
            question: 'Typical quarterly water/sewer bill?',
            inputType: 'currency' as InputType,
            required: false,
          },
        ] : []),
        {
          id: 'trash_provider',
          zone: 'utilities',
          category: 'utilities',
          label: 'Trash/Recycling',
          question: 'Trash and recycling provider? (Municipal or private)',
          inputType: 'text',
          required: false,
          billCategory: 'TRASH',
        },
      ],
    });

    // ===========================================================================
    // 10. HOUSING COSTS
    // ===========================================================================
    sections.push({
      id: 'housing',
      title: 'Housing Costs',
      description: 'Mortgage, taxes, insurance, HOA',
      icon: '🏠',
      items: [
        {
          id: 'mortgage_lender',
          zone: 'housing',
          category: 'bills',
          label: 'Mortgage lender',
          question: 'Who holds your mortgage?',
          inputType: 'text',
          required: false,
          billCategory: 'MORTGAGE',
        },
        {
          id: 'mortgage_payment',
          zone: 'housing',
          category: 'bills',
          label: 'Mortgage payment',
          question: 'Monthly mortgage payment?',
          inputType: 'currency',
          required: false,
        },
        {
          id: 'property_tax',
          zone: 'housing',
          category: 'bills',
          label: 'Property tax',
          question: 'Annual property tax? (Or included in escrow)',
          inputType: 'currency',
          required: false,
          billCategory: 'PROPERTY_TAX',
        },
        {
          id: 'home_insurance',
          zone: 'housing',
          category: 'bills',
          label: 'Home insurance',
          question: 'Home insurance provider and annual premium?',
          inputType: 'text',
          required: true,
          billCategory: 'HOME_INSURANCE',
        },
        {
          id: 'has_hoa',
          zone: 'housing',
          category: 'bills',
          label: 'HOA',
          question: 'Are you in an HOA? Monthly/annual fee?',
          inputType: 'text',
          required: false,
          billCategory: 'HOA',
        },
        {
          id: 'umbrella_insurance',
          zone: 'housing',
          category: 'bills',
          label: 'Umbrella insurance',
          question: 'Do you have umbrella insurance?',
          inputType: 'text',
          required: false,
          billCategory: 'UMBRELLA_INSURANCE',
        },
      ],
    });

    // ===========================================================================
    // 11. OTHER RECURRING BILLS
    // ===========================================================================
    sections.push({
      id: 'bills',
      title: 'Other Bills & Subscriptions',
      description: 'Recurring payments Haven can help manage',
      icon: '💳',
      items: [
        {
          id: 'auto_insurance',
          zone: 'bills',
          category: 'bills',
          label: 'Auto insurance',
          question: 'Auto insurance provider? Monthly cost?',
          inputType: 'text',
          required: false,
          billCategory: 'AUTO_INSURANCE',
        },
        {
          id: 'life_insurance',
          zone: 'bills',
          category: 'bills',
          label: 'Life insurance',
          question: 'Life insurance? Provider and monthly cost?',
          inputType: 'text',
          required: false,
          billCategory: 'LIFE_INSURANCE',
        },
        {
          id: 'cell_phones',
          zone: 'bills',
          category: 'bills',
          label: 'Cell phones',
          question: 'Cell phone provider and monthly cost?',
          inputType: 'text',
          required: false,
          billCategory: 'MOBILE',
        },
        {
          id: 'streaming_services',
          zone: 'bills',
          category: 'bills',
          label: 'Streaming',
          question: 'What streaming services? (Netflix, Hulu, Disney+, etc.)',
          inputType: 'text',
          required: false,
          billCategory: 'STREAMING',
        },
        {
          id: 'gym_memberships',
          zone: 'bills',
          category: 'bills',
          label: 'Gym',
          question: 'Gym or fitness memberships?',
          inputType: 'text',
          required: false,
          billCategory: 'GYM',
        },
        {
          id: 'cleaning_service',
          zone: 'bills',
          category: 'bills',
          label: 'Cleaning service',
          question: 'Do you have a house cleaning service? How often?',
          inputType: 'text',
          required: false,
          billCategory: 'CLEANING',
        },
        {
          id: 'other_subscriptions',
          zone: 'bills',
          category: 'bills',
          label: 'Other subscriptions',
          question: 'Any other recurring subscriptions or memberships?',
          inputType: 'text',
          required: false,
        },
      ],
    });

    // ===========================================================================
    // 12. GENERAL VENDORS
    // ===========================================================================
    sections.push({
      id: 'vendors',
      title: 'Trusted Vendors',
      description: 'Other service providers you use',
      icon: '🛠️',
      items: [
        {
          id: 'handyman',
          zone: 'vendors',
          category: 'vendors',
          label: 'Handyman',
          question: 'Do you have a go-to handyman?',
          inputType: 'text',
          required: false,
        },
        {
          id: 'general_contractor',
          zone: 'vendors',
          category: 'vendors',
          label: 'General contractor',
          question: 'General contractor you trust?',
          inputType: 'text',
          required: false,
        },
        {
          id: 'painter',
          zone: 'vendors',
          category: 'vendors',
          label: 'Painter',
          question: 'Painter you use?',
          inputType: 'text',
          required: false,
        },
        {
          id: 'window_washer',
          zone: 'vendors',
          category: 'vendors',
          label: 'Window washing',
          question: 'Window washing service?',
          inputType: 'text',
          required: false,
        },
        {
          id: 'vet',
          zone: 'vendors',
          category: 'vendors',
          label: 'Veterinarian',
          question: 'Veterinarian (if pets)?',
          inputType: 'text',
          required: false,
        },
        {
          id: 'urgent_concerns',
          zone: 'vendors',
          category: 'family_info',
          label: 'Urgent concerns',
          question: "Is there anything about your home that's been bothering you or needs attention soon?",
          inputType: 'text',
          required: false,
        },
        {
          id: 'special_instructions',
          zone: 'vendors',
          category: 'family_info',
          label: 'Special instructions',
          question: 'Any special instructions for service providers? (Gate codes, pet warnings, preferred times)',
          inputType: 'text',
          required: false,
        },
      ],
    });

    return sections;
  }

  // ===========================================================================
  // HELPER METHODS FOR CONDITIONAL QUESTIONS
  // ===========================================================================

  private needsOilHeating(propertyData: PropertyDetails | null): boolean {
    return (
      propertyData?.heatingFuel?.toLowerCase().includes('oil') || false
    );
  }

  private needsPropane(propertyData: PropertyDetails | null): boolean {
    const fuel = propertyData?.heatingFuel?.toLowerCase() || '';
    return fuel.includes('propane') || fuel.includes('lp');
  }

  private needsGas(propertyData: PropertyDetails | null): boolean {
    const fuel = propertyData?.heatingFuel?.toLowerCase() || '';
    return fuel.includes('gas') || fuel.includes('natural');
  }

  private hasFireplace(propertyData: PropertyDetails | null): boolean {
    return (propertyData?.fireplaces || 0) > 0;
  }

  private hasSeptic(propertyData: PropertyDetails | null): boolean {
    return (
      propertyData?.sewerType?.toLowerCase().includes('septic') || false
    );
  }

  private hasWell(propertyData: PropertyDetails | null): boolean {
    return (
      propertyData?.waterType?.toLowerCase().includes('well') || false
    );
  }

  private hasPool(propertyData: PropertyDetails | null): boolean {
    return propertyData?.pool || false;
  }

  private needsSnowRemoval(state?: string): boolean {
    const snowStates = [
      'CT', 'MA', 'NH', 'ME', 'VT', 'RI', 'NY', 'NJ', 'PA',
      'OH', 'MI', 'WI', 'MN', 'IL', 'IN', 'CO', 'UT',
    ];
    return state ? snowStates.includes(state.toUpperCase()) : false;
  }

  // ===========================================================================
  // MONTHLY FUNDING CALCULATION
  // ===========================================================================

  /**
   * Calculate recommended monthly funding based on captured bills.
   * Returns a breakdown by category.
   */
  calculateMonthlyFunding(answers: Record<string, string | number>): {
    total: number;
    breakdown: {
      housing: number;
      utilities: number;
      insurance: number;
      services: number;
      other: number;
    };
  } {
    const breakdown = {
      housing: 0,
      utilities: 0,
      insurance: 0,
      services: 0,
      other: 0,
    };

    // Parse currency values
    const parseCurrency = (value: string | number | undefined): number => {
      if (!value) return 0;
      if (typeof value === 'number') return value;
      return parseFloat(value.replace(/[^0-9.]/g, '')) || 0;
    };

    // Housing costs
    breakdown.housing += parseCurrency(answers['mortgage_payment']);
    breakdown.housing += parseCurrency(answers['property_tax']) / 12; // Annual to monthly
    breakdown.housing += parseCurrency(answers['has_hoa']);

    // Utilities
    breakdown.utilities += parseCurrency(answers['electric_monthly']);
    breakdown.utilities += parseCurrency(answers['gas_monthly']);
    breakdown.utilities += parseCurrency(answers['water_monthly']) / 3; // Quarterly to monthly

    // Insurance
    breakdown.insurance += parseCurrency(answers['home_insurance']) / 12;
    breakdown.insurance += parseCurrency(answers['auto_insurance']);
    breakdown.insurance += parseCurrency(answers['life_insurance']);
    breakdown.insurance += parseCurrency(answers['umbrella_insurance']) / 12;

    // Services (estimated based on text responses - would need more sophisticated parsing)
    // For now, placeholder logic
    if (answers['cleaning_service']) breakdown.services += 150; // Estimate
    if (answers['lawn_service']) breakdown.services += 200; // Estimate
    if (answers['pool_service']) breakdown.services += 150; // Estimate

    // Other
    if (answers['gym_memberships']) breakdown.other += 50; // Estimate
    if (answers['cell_phones']) breakdown.other += parseCurrency(answers['cell_phones']);

    const total =
      breakdown.housing +
      breakdown.utilities +
      breakdown.insurance +
      breakdown.services +
      breakdown.other;

    return { total, breakdown };
  }

  /**
   * Get a summary of the intake for display
   */
  getIntakeSummary(propertyData: PropertyDetails | null, state?: string): {
    totalSections: number;
    totalQuestions: number;
    highlights: string[];
  } {
    const sections = this.generateIntakeSections(propertyData, state);
    const totalQuestions = sections.reduce((sum, s) => sum + s.items.length, 0);

    const highlights: string[] = [];
    if (this.needsOilHeating(propertyData)) highlights.push('Oil heating');
    if (this.hasSeptic(propertyData)) highlights.push('Septic system');
    if (this.hasWell(propertyData)) highlights.push('Well water');
    if (this.hasPool(propertyData)) highlights.push('Pool');
    if (this.hasFireplace(propertyData)) highlights.push(`${propertyData?.fireplaces} fireplace(s)`);
    if (propertyData?.garageSpaces) highlights.push(`${propertyData.garageSpaces}-car garage`);

    return {
      totalSections: sections.length,
      totalQuestions,
      highlights,
    };
  }

  // ===========================================================================
  // COMPREHENSIVE BILL INTAKE GENERATOR
  // ===========================================================================

  /**
   * Standard fields for all bill types
   */
  private getStandardBillFields(): BillFieldConfig[] {
    return [
      { id: 'payee_name', label: 'Payee Name', inputType: 'text', required: true, placeholder: 'e.g., Con Edison' },
      { id: 'account_number', label: 'Account Number', inputType: 'text', required: true, placeholder: 'Account or policy number' },
      { id: 'amount', label: 'Amount', inputType: 'currency', required: true, placeholder: '$0.00' },
      { id: 'frequency', label: 'Frequency', inputType: 'select', required: true, options: ['Monthly', 'Quarterly', 'Semi-Annual', 'Annual', 'Weekly', 'Bi-Weekly', 'As Needed'] },
      { id: 'due_day', label: 'Due Day of Month', inputType: 'number', required: false, placeholder: '1-28' },
      { id: 'amount_type', label: 'Amount Type', inputType: 'select', required: false, options: ['Fixed', 'Variable', 'Estimated'] },
      { id: 'payment_method', label: 'Payment Method', inputType: 'select', required: true, options: ['Haven Pays', 'Current Autopay', 'Manual Payment', 'Payroll Deduction', 'Escrow'] },
      { id: 'current_autopay', label: 'Currently on Autopay?', inputType: 'boolean', required: false },
      { id: 'portal_url', label: 'Online Portal URL', inputType: 'url', required: false, placeholder: 'https://...' },
      { id: 'portal_username', label: 'Portal Username/Email', inputType: 'text', required: false },
      { id: 'portal_notes', label: 'Portal Notes', inputType: 'text', required: false, placeholder: 'Login hints, security questions, etc.' },
      { id: 'notes', label: 'Additional Notes', inputType: 'text', required: false },
    ];
  }

  /**
   * Extra fields for loan-type bills
   */
  private getLoanFields(): BillFieldConfig[] {
    return [
      { id: 'principal_balance', label: 'Principal Balance', inputType: 'currency', required: false, placeholder: 'Remaining balance' },
      { id: 'interest_rate', label: 'Interest Rate (%)', inputType: 'percentage', required: false, placeholder: '4.5' },
      { id: 'loan_term', label: 'Loan Term', inputType: 'text', required: false, placeholder: '30 years, 60 months, etc.' },
      { id: 'maturity_date', label: 'Payoff Date', inputType: 'date', required: false },
      { id: 'escrow_included', label: 'Escrow Included?', inputType: 'boolean', required: false, helpText: 'Does payment include property tax/insurance?' },
    ];
  }

  /**
   * Extra fields for insurance-type bills
   */
  private getInsuranceFields(): BillFieldConfig[] {
    return [
      { id: 'policy_number', label: 'Policy Number', inputType: 'text', required: true },
      { id: 'coverage_amount', label: 'Coverage Amount', inputType: 'currency', required: false },
      { id: 'deductible', label: 'Deductible', inputType: 'currency', required: false },
      { id: 'renewal_date', label: 'Renewal Date', inputType: 'date', required: false },
    ];
  }

  /**
   * Generate comprehensive bill intake sections
   */
  generateBillIntakeSections(context: BillIntakeContext): BillIntakeSection[] {
    const sections: BillIntakeSection[] = [];

    // ===========================================================================
    // 1. HOUSING COSTS
    // ===========================================================================
    sections.push({
      id: 'bills_housing',
      title: 'Housing Costs',
      description: 'Mortgage, rent, property tax, HOA, and home insurance',
      icon: '🏠',
      bills: [
        {
          id: 'mortgage',
          billCategory: 'MORTGAGE',
          label: 'Mortgage',
          description: 'Primary mortgage payment',
          icon: '🏦',
          showIf: (ctx) => ctx.hasMortgage,
          fields: [
            ...this.getStandardBillFields(),
            ...this.getLoanFields(),
            { id: 'lender_name', label: 'Lender/Servicer', inputType: 'text', required: true, placeholder: 'e.g., Wells Fargo, Rocket Mortgage' },
          ],
        },
        {
          id: 'rent',
          billCategory: 'RENT',
          label: 'Rent',
          description: 'Monthly rent payment',
          icon: '🔑',
          showIf: (ctx) => !ctx.hasMortgage,
          fields: [
            ...this.getStandardBillFields(),
            { id: 'landlord_name', label: 'Landlord/Management Company', inputType: 'text', required: true },
            { id: 'landlord_phone', label: 'Landlord Phone', inputType: 'phone', required: false },
          ],
        },
        {
          id: 'property_tax',
          billCategory: 'PROPERTY_TAX',
          label: 'Property Tax',
          description: 'Annual property taxes (if not in escrow)',
          icon: '📋',
          showIf: (ctx) => ctx.hasMortgage, // Only show if owned
          fields: [
            { id: 'payee_name', label: 'Tax Collector', inputType: 'text', required: true, placeholder: 'County/Town name' },
            { id: 'account_number', label: 'Parcel/Tax ID', inputType: 'text', required: true },
            { id: 'amount', label: 'Annual Amount', inputType: 'currency', required: true },
            { id: 'frequency', label: 'Payment Frequency', inputType: 'select', required: true, options: ['Annual', 'Semi-Annual', 'Quarterly', 'Included in Escrow'] },
            { id: 'due_date', label: 'Due Date(s)', inputType: 'text', required: false, placeholder: 'e.g., Jan 1, Jul 1' },
            { id: 'payment_method', label: 'Payment Method', inputType: 'select', required: true, options: ['Haven Pays', 'Escrow', 'Owner Pays Directly'] },
            { id: 'portal_url', label: 'Online Portal URL', inputType: 'url', required: false },
            { id: 'notes', label: 'Notes', inputType: 'text', required: false },
          ],
        },
        {
          id: 'hoa',
          billCategory: 'HOA',
          label: 'HOA Dues',
          description: 'Homeowners association fees',
          icon: '🏘️',
          fields: [
            ...this.getStandardBillFields(),
            { id: 'hoa_name', label: 'HOA Name', inputType: 'text', required: true },
            { id: 'contact_phone', label: 'HOA Contact Phone', inputType: 'phone', required: false },
          ],
        },
        {
          id: 'home_insurance',
          billCategory: 'HOME_INSURANCE',
          label: 'Home Insurance',
          description: 'Homeowners or renters insurance',
          icon: '🛡️',
          fields: [
            ...this.getStandardBillFields(),
            ...this.getInsuranceFields(),
            { id: 'agent_name', label: 'Agent Name', inputType: 'text', required: false },
            { id: 'agent_phone', label: 'Agent Phone', inputType: 'phone', required: false },
          ],
        },
      ],
    });

    // ===========================================================================
    // 2. UTILITIES
    // ===========================================================================
    sections.push({
      id: 'bills_utilities',
      title: 'Utilities',
      description: 'Electric, gas, water, and trash services',
      icon: '💡',
      bills: [
        {
          id: 'electric',
          billCategory: 'ELECTRIC',
          label: 'Electric',
          description: 'Electricity provider',
          icon: '⚡',
          fields: this.getStandardBillFields(),
        },
        {
          id: 'gas',
          billCategory: 'GAS',
          label: 'Natural Gas',
          description: 'Gas utility (if applicable)',
          icon: '🔥',
          showIf: (ctx) => ctx.hasGasService,
          fields: this.getStandardBillFields(),
        },
        {
          id: 'oil_propane',
          billCategory: 'OIL_PROPANE',
          label: 'Oil/Propane',
          description: 'Heating oil or propane delivery',
          icon: '🛢️',
          showIf: (ctx) => {
            const fuel = ctx.propertyData?.heatingFuel?.toLowerCase() || '';
            return fuel.includes('oil') || fuel.includes('propane');
          },
          fields: [
            ...this.getStandardBillFields(),
            { id: 'tank_size', label: 'Tank Size (gallons)', inputType: 'number', required: false },
            { id: 'last_delivery', label: 'Last Delivery Date', inputType: 'date', required: false },
          ],
        },
        {
          id: 'water_sewer',
          billCategory: 'WATER_SEWER',
          label: 'Water/Sewer',
          description: 'Municipal water and sewer',
          icon: '💧',
          showIf: (ctx) => !ctx.propertyData?.waterType?.toLowerCase().includes('well'),
          fields: this.getStandardBillFields(),
        },
        {
          id: 'trash',
          billCategory: 'TRASH',
          label: 'Trash/Recycling',
          description: 'Waste collection service',
          icon: '🗑️',
          fields: [
            ...this.getStandardBillFields(),
            { id: 'pickup_days', label: 'Pickup Days', inputType: 'text', required: false, placeholder: 'e.g., Tuesday, Friday' },
          ],
        },
      ],
    });

    // ===========================================================================
    // 3. TELECOM & INTERNET
    // ===========================================================================
    sections.push({
      id: 'bills_telecom',
      title: 'Internet & Phone',
      description: 'Internet, cable, and phone services',
      icon: '📱',
      bills: [
        {
          id: 'internet',
          billCategory: 'INTERNET',
          label: 'Internet',
          description: 'Home internet service',
          icon: '🌐',
          fields: [
            ...this.getStandardBillFields(),
            { id: 'speed_tier', label: 'Speed/Plan', inputType: 'text', required: false, placeholder: 'e.g., 500 Mbps' },
          ],
        },
        {
          id: 'cable_tv',
          billCategory: 'CABLE_TV',
          label: 'Cable/Streaming TV',
          description: 'Television service',
          icon: '📺',
          fields: [
            ...this.getStandardBillFields(),
            { id: 'package', label: 'Package/Tier', inputType: 'text', required: false },
          ],
        },
        {
          id: 'cell_phone',
          billCategory: 'CELL_PHONE',
          label: 'Cell Phone',
          description: 'Mobile phone plan',
          icon: '📱',
          fields: [
            ...this.getStandardBillFields(),
            { id: 'lines', label: 'Number of Lines', inputType: 'number', required: false },
            { id: 'device_payments', label: 'Includes Device Payments?', inputType: 'boolean', required: false },
          ],
        },
        {
          id: 'landline',
          billCategory: 'LANDLINE',
          label: 'Landline',
          description: 'Home phone service',
          icon: '☎️',
          fields: this.getStandardBillFields(),
        },
      ],
    });

    // ===========================================================================
    // 4. VEHICLES
    // ===========================================================================
    sections.push({
      id: 'bills_vehicles',
      title: 'Vehicle Expenses',
      description: 'Car payments, insurance, and registration',
      icon: '🚗',
      showIf: (ctx) => ctx.hasVehicles,
      bills: [
        {
          id: 'car_payment',
          billCategory: 'CAR_PAYMENT',
          label: 'Car Payment',
          description: 'Auto loan or lease payment',
          icon: '🚙',
          fields: [
            ...this.getStandardBillFields(),
            ...this.getLoanFields(),
            { id: 'vehicle_description', label: 'Vehicle', inputType: 'text', required: true, placeholder: 'e.g., 2023 Tesla Model Y' },
            { id: 'is_lease', label: 'Is this a lease?', inputType: 'boolean', required: false },
            { id: 'lease_end', label: 'Lease End Date', inputType: 'date', required: false },
          ],
        },
        {
          id: 'auto_insurance',
          billCategory: 'AUTO_INSURANCE',
          label: 'Auto Insurance',
          description: 'Vehicle insurance policy',
          icon: '🛡️',
          fields: [
            ...this.getStandardBillFields(),
            ...this.getInsuranceFields(),
            { id: 'vehicles_covered', label: 'Vehicles Covered', inputType: 'text', required: false, placeholder: 'All family vehicles' },
            { id: 'agent_name', label: 'Agent Name', inputType: 'text', required: false },
            { id: 'agent_phone', label: 'Agent Phone', inputType: 'phone', required: false },
          ],
        },
        {
          id: 'car_registration',
          billCategory: 'CAR_REGISTRATION',
          label: 'Vehicle Registration',
          description: 'Annual DMV registration',
          icon: '📝',
          fields: [
            { id: 'vehicle_description', label: 'Vehicle', inputType: 'text', required: true },
            { id: 'amount', label: 'Registration Fee', inputType: 'currency', required: true },
            { id: 'due_date', label: 'Expiration Date', inputType: 'date', required: true },
            { id: 'plate_number', label: 'Plate Number', inputType: 'text', required: false },
            { id: 'payment_method', label: 'Payment Method', inputType: 'select', required: true, options: ['Haven Pays', 'Owner Pays'] },
            { id: 'notes', label: 'Notes', inputType: 'text', required: false },
          ],
        },
        {
          id: 'parking',
          billCategory: 'PARKING',
          label: 'Parking',
          description: 'Monthly parking fee',
          icon: '🅿️',
          fields: this.getStandardBillFields(),
        },
        {
          id: 'tolls',
          billCategory: 'TOLLS',
          label: 'Toll Account',
          description: 'EZ-Pass or toll transponder',
          icon: '🛣️',
          fields: [
            { id: 'payee_name', label: 'Toll Authority', inputType: 'text', required: true, placeholder: 'e.g., EZ-Pass, FasTrak' },
            { id: 'account_number', label: 'Account Number', inputType: 'text', required: true },
            { id: 'amount_type', label: 'Funding Type', inputType: 'select', required: true, options: ['Auto-Replenish', 'Manual Top-up'] },
            { id: 'replenish_amount', label: 'Replenish Amount', inputType: 'currency', required: false },
            { id: 'payment_method', label: 'Payment Method', inputType: 'select', required: true, options: ['Haven Pays', 'Credit Card on File'] },
            { id: 'portal_url', label: 'Online Portal URL', inputType: 'url', required: false },
            { id: 'portal_username', label: 'Portal Username', inputType: 'text', required: false },
          ],
        },
      ],
    });

    // ===========================================================================
    // 5. LOANS & DEBT
    // ===========================================================================
    sections.push({
      id: 'bills_loans',
      title: 'Loans & Debt',
      description: 'Student loans, personal loans, and credit lines',
      icon: '💳',
      bills: [
        {
          id: 'student_loan',
          billCategory: 'STUDENT_LOAN',
          label: 'Student Loan',
          description: 'Education loan payments',
          icon: '🎓',
          fields: [
            ...this.getStandardBillFields(),
            ...this.getLoanFields(),
            { id: 'borrower_name', label: 'Borrower Name', inputType: 'text', required: false },
          ],
        },
        {
          id: 'personal_loan',
          billCategory: 'PERSONAL_LOAN',
          label: 'Personal Loan',
          description: 'Personal or signature loan',
          icon: '📄',
          fields: [
            ...this.getStandardBillFields(),
            ...this.getLoanFields(),
          ],
        },
        {
          id: 'heloc',
          billCategory: 'HELOC',
          label: 'HELOC',
          description: 'Home equity line of credit',
          icon: '🏡',
          fields: [
            ...this.getStandardBillFields(),
            ...this.getLoanFields(),
            { id: 'credit_limit', label: 'Credit Limit', inputType: 'currency', required: false },
            { id: 'draw_period_end', label: 'Draw Period Ends', inputType: 'date', required: false },
          ],
        },
        {
          id: 'credit_card',
          billCategory: 'CREDIT_CARD',
          label: 'Credit Card',
          description: 'Credit card payment (if Haven manages)',
          icon: '💳',
          fields: [
            { id: 'payee_name', label: 'Card Issuer', inputType: 'text', required: true, placeholder: 'e.g., Chase, Amex' },
            { id: 'card_name', label: 'Card Name', inputType: 'text', required: false, placeholder: 'e.g., Sapphire Reserve' },
            { id: 'account_number', label: 'Last 4 Digits', inputType: 'text', required: true, placeholder: '1234' },
            { id: 'amount', label: 'Typical Monthly Payment', inputType: 'currency', required: true },
            { id: 'amount_type', label: 'Payment Type', inputType: 'select', required: true, options: ['Statement Balance', 'Minimum Payment', 'Fixed Amount'] },
            { id: 'due_day', label: 'Due Day', inputType: 'number', required: false },
            { id: 'payment_method', label: 'Payment Method', inputType: 'select', required: true, options: ['Haven Pays', 'Current Autopay', 'Owner Pays'] },
            { id: 'portal_url', label: 'Online Portal URL', inputType: 'url', required: false },
            { id: 'portal_username', label: 'Portal Username', inputType: 'text', required: false },
          ],
        },
      ],
    });

    // ===========================================================================
    // 6. FAMILY & CHILDREN
    // ===========================================================================
    sections.push({
      id: 'bills_family',
      title: 'Family & Children',
      description: 'School, childcare, and kids activities',
      icon: '👨‍👩‍👧‍👦',
      showIf: (ctx) => ctx.hasChildren || ctx.hasStaff,
      bills: [
        {
          id: 'school_tuition',
          billCategory: 'SCHOOL_TUITION',
          label: 'School Tuition',
          description: 'Private school or college tuition',
          icon: '🏫',
          showIf: (ctx) => ctx.hasChildren,
          fields: [
            { id: 'payee_name', label: 'School Name', inputType: 'text', required: true },
            { id: 'student_name', label: 'Student Name', inputType: 'text', required: true },
            { id: 'student_id', label: 'Student ID', inputType: 'text', required: false },
            { id: 'account_number', label: 'Family Account Number', inputType: 'text', required: false },
            { id: 'amount', label: 'Payment Amount', inputType: 'currency', required: true },
            { id: 'frequency', label: 'Frequency', inputType: 'select', required: true, options: ['Monthly', 'Quarterly', 'Semester', 'Annual'] },
            { id: 'due_day', label: 'Due Day', inputType: 'number', required: false },
            { id: 'payment_method', label: 'Payment Method', inputType: 'select', required: true, options: ['Haven Pays', 'Current Autopay', 'Owner Pays'] },
            { id: 'portal_url', label: 'Parent Portal URL', inputType: 'url', required: false },
            { id: 'portal_username', label: 'Portal Username', inputType: 'text', required: false },
            { id: 'notes', label: 'Notes', inputType: 'text', required: false },
          ],
        },
        {
          id: 'childcare',
          billCategory: 'CHILDCARE',
          label: 'Daycare/Childcare',
          description: 'Daycare or preschool',
          icon: '👶',
          showIf: (ctx) => ctx.hasChildren,
          fields: [
            { id: 'payee_name', label: 'Provider Name', inputType: 'text', required: true },
            { id: 'child_name', label: 'Child Name', inputType: 'text', required: true },
            { id: 'account_number', label: 'Account Number', inputType: 'text', required: false },
            { id: 'amount', label: 'Weekly/Monthly Amount', inputType: 'currency', required: true },
            { id: 'frequency', label: 'Frequency', inputType: 'select', required: true, options: ['Weekly', 'Bi-Weekly', 'Monthly'] },
            { id: 'payment_method', label: 'Payment Method', inputType: 'select', required: true, options: ['Haven Pays', 'Current Autopay', 'Owner Pays'] },
            { id: 'portal_url', label: 'Portal URL', inputType: 'url', required: false },
            { id: 'notes', label: 'Notes', inputType: 'text', required: false, placeholder: 'Drop-off/pickup times, allergies, etc.' },
          ],
        },
        {
          id: 'nanny',
          billCategory: 'NANNY',
          label: 'Nanny/Au Pair',
          description: 'Nanny or au pair salary',
          icon: '👩‍🍼',
          showIf: (ctx) => ctx.hasStaff,
          fields: [
            { id: 'payee_name', label: 'Nanny Name', inputType: 'text', required: true },
            { id: 'amount', label: 'Payment Amount', inputType: 'currency', required: true },
            { id: 'frequency', label: 'Frequency', inputType: 'select', required: true, options: ['Weekly', 'Bi-Weekly', 'Monthly'] },
            { id: 'payment_method', label: 'Payment Method', inputType: 'select', required: true, options: ['Haven Pays', 'Direct Deposit', 'Payroll Service', 'Check'] },
            { id: 'payroll_service', label: 'Payroll Service', inputType: 'text', required: false, placeholder: 'e.g., GTM Payroll, SurePayroll' },
            { id: 'payroll_account', label: 'Payroll Account Number', inputType: 'text', required: false },
            { id: 'schedule', label: 'Work Schedule', inputType: 'text', required: false },
            { id: 'notes', label: 'Notes', inputType: 'text', required: false },
          ],
        },
        {
          id: 'kids_activity',
          billCategory: 'KIDS_ACTIVITY',
          label: 'Kids Activities',
          description: 'Sports, lessons, camps, etc.',
          icon: '⚽',
          showIf: (ctx) => ctx.hasChildren,
          fields: [
            { id: 'activity_name', label: 'Activity Name', inputType: 'text', required: true, placeholder: 'e.g., Soccer, Piano Lessons' },
            { id: 'payee_name', label: 'Organization/Provider', inputType: 'text', required: true },
            { id: 'child_name', label: 'Child Name', inputType: 'text', required: true },
            { id: 'account_number', label: 'Registration/Account Number', inputType: 'text', required: false },
            { id: 'amount', label: 'Cost', inputType: 'currency', required: true },
            { id: 'frequency', label: 'Frequency', inputType: 'select', required: true, options: ['Monthly', 'Per Session', 'Seasonal', 'Annual'] },
            { id: 'season', label: 'Season/Term', inputType: 'text', required: false, placeholder: 'e.g., Fall 2024' },
            { id: 'payment_method', label: 'Payment Method', inputType: 'select', required: true, options: ['Haven Pays', 'Current Autopay', 'Owner Pays'] },
            { id: 'portal_url', label: 'Portal URL', inputType: 'url', required: false },
            { id: 'schedule', label: 'Schedule', inputType: 'text', required: false, placeholder: 'e.g., Tuesdays 4-5pm' },
            { id: 'location', label: 'Location', inputType: 'text', required: false },
            { id: 'notes', label: 'Notes', inputType: 'text', required: false },
          ],
        },
        {
          id: 'school_lunch',
          billCategory: 'SCHOOL_LUNCH',
          label: 'School Lunch Account',
          description: 'School cafeteria account',
          icon: '🍎',
          showIf: (ctx) => ctx.hasChildren,
          fields: [
            { id: 'payee_name', label: 'School/District', inputType: 'text', required: true },
            { id: 'student_name', label: 'Student Name', inputType: 'text', required: true },
            { id: 'account_number', label: 'Lunch Account Number', inputType: 'text', required: true },
            { id: 'amount', label: 'Auto-Replenish Amount', inputType: 'currency', required: false },
            { id: 'replenish_threshold', label: 'Replenish When Below', inputType: 'currency', required: false },
            { id: 'payment_method', label: 'Payment Method', inputType: 'select', required: true, options: ['Haven Pays', 'Auto-Replenish on File'] },
            { id: 'portal_url', label: 'Portal URL', inputType: 'url', required: false, placeholder: 'e.g., MySchoolBucks' },
            { id: 'portal_username', label: 'Portal Username', inputType: 'text', required: false },
          ],
        },
        {
          id: 'tutoring',
          billCategory: 'TUTORING',
          label: 'Tutoring',
          description: 'Academic tutoring services',
          icon: '📚',
          showIf: (ctx) => ctx.hasChildren,
          fields: [
            { id: 'payee_name', label: 'Tutor/Company Name', inputType: 'text', required: true },
            { id: 'student_name', label: 'Student Name', inputType: 'text', required: true },
            { id: 'subject', label: 'Subject(s)', inputType: 'text', required: false },
            { id: 'amount', label: 'Cost', inputType: 'currency', required: true },
            { id: 'frequency', label: 'Frequency', inputType: 'select', required: true, options: ['Per Session', 'Weekly', 'Monthly'] },
            { id: 'payment_method', label: 'Payment Method', inputType: 'select', required: true, options: ['Haven Pays', 'Owner Pays Directly'] },
            { id: 'schedule', label: 'Schedule', inputType: 'text', required: false },
            { id: 'notes', label: 'Notes', inputType: 'text', required: false },
          ],
        },
      ],
    });

    // ===========================================================================
    // 7. INSURANCE
    // ===========================================================================
    sections.push({
      id: 'bills_insurance',
      title: 'Insurance',
      description: 'Life, health, umbrella, and other insurance',
      icon: '🛡️',
      bills: [
        {
          id: 'life_insurance',
          billCategory: 'LIFE_INSURANCE',
          label: 'Life Insurance',
          description: 'Life insurance premiums',
          icon: '💝',
          fields: [
            ...this.getStandardBillFields(),
            ...this.getInsuranceFields(),
            { id: 'insured_name', label: 'Insured Person', inputType: 'text', required: false },
            { id: 'policy_type', label: 'Policy Type', inputType: 'select', required: false, options: ['Term', 'Whole Life', 'Universal'] },
          ],
        },
        {
          id: 'health_insurance',
          billCategory: 'HEALTH_INSURANCE',
          label: 'Health Insurance',
          description: 'Health insurance premiums (if not through employer)',
          icon: '🏥',
          fields: [
            ...this.getStandardBillFields(),
            ...this.getInsuranceFields(),
            { id: 'plan_name', label: 'Plan Name', inputType: 'text', required: false },
            { id: 'covered_members', label: 'Covered Family Members', inputType: 'text', required: false },
          ],
        },
        {
          id: 'umbrella_insurance',
          billCategory: 'UMBRELLA_INSURANCE',
          label: 'Umbrella Insurance',
          description: 'Excess liability coverage',
          icon: '☂️',
          fields: [
            ...this.getStandardBillFields(),
            ...this.getInsuranceFields(),
          ],
        },
        {
          id: 'pet_insurance',
          billCategory: 'PET_INSURANCE',
          label: 'Pet Insurance',
          description: 'Pet health insurance',
          icon: '🐾',
          showIf: (ctx) => ctx.hasPets,
          fields: [
            ...this.getStandardBillFields(),
            ...this.getInsuranceFields(),
            { id: 'pet_name', label: 'Pet Name', inputType: 'text', required: true },
            { id: 'pet_type', label: 'Pet Type/Breed', inputType: 'text', required: false },
          ],
        },
        {
          id: 'disability_insurance',
          billCategory: 'DISABILITY_INSURANCE',
          label: 'Disability Insurance',
          description: 'Long or short-term disability',
          icon: '🦽',
          fields: [
            ...this.getStandardBillFields(),
            ...this.getInsuranceFields(),
            { id: 'coverage_type', label: 'Type', inputType: 'select', required: false, options: ['Short-Term', 'Long-Term', 'Both'] },
          ],
        },
        {
          id: 'long_term_care',
          billCategory: 'LONG_TERM_CARE',
          label: 'Long-Term Care Insurance',
          description: 'LTC insurance premiums',
          icon: '🏠',
          fields: [
            ...this.getStandardBillFields(),
            ...this.getInsuranceFields(),
            { id: 'insured_name', label: 'Insured Person', inputType: 'text', required: false },
          ],
        },
      ],
    });

    // ===========================================================================
    // 8. HOME SERVICES
    // ===========================================================================
    sections.push({
      id: 'bills_home_services',
      title: 'Home Services',
      description: 'Recurring maintenance and service contracts',
      icon: '🔧',
      bills: [
        {
          id: 'lawn_landscape',
          billCategory: 'LAWN_LANDSCAPE',
          label: 'Lawn/Landscaping',
          description: 'Regular lawn care service',
          icon: '🌿',
          fields: [
            ...this.getStandardBillFields(),
            { id: 'services_included', label: 'Services Included', inputType: 'text', required: false, placeholder: 'Mowing, edging, leaf cleanup, etc.' },
            { id: 'contact_name', label: 'Contact Name', inputType: 'text', required: false },
            { id: 'contact_phone', label: 'Contact Phone', inputType: 'phone', required: false },
          ],
        },
        {
          id: 'pool_service',
          billCategory: 'POOL_SERVICE',
          label: 'Pool Service',
          description: 'Pool maintenance and cleaning',
          icon: '🏊',
          showIf: (ctx) => ctx.hasPool,
          fields: [
            ...this.getStandardBillFields(),
            { id: 'service_day', label: 'Service Day', inputType: 'text', required: false, placeholder: 'e.g., Wednesdays' },
            { id: 'contact_name', label: 'Contact Name', inputType: 'text', required: false },
            { id: 'contact_phone', label: 'Contact Phone', inputType: 'phone', required: false },
          ],
        },
        {
          id: 'pest_control',
          billCategory: 'PEST_CONTROL',
          label: 'Pest Control',
          description: 'Regular pest control service',
          icon: '🐜',
          fields: [
            ...this.getStandardBillFields(),
            { id: 'service_frequency', label: 'Service Frequency', inputType: 'text', required: false, placeholder: 'e.g., Quarterly' },
            { id: 'contact_phone', label: 'Contact Phone', inputType: 'phone', required: false },
          ],
        },
        {
          id: 'security_monitoring',
          billCategory: 'SECURITY_MONITORING',
          label: 'Security Monitoring',
          description: 'Alarm monitoring service',
          icon: '🔐',
          fields: [
            ...this.getStandardBillFields(),
            { id: 'system_type', label: 'System Type', inputType: 'text', required: false, placeholder: 'e.g., ADT, Ring, SimpliSafe' },
            { id: 'passcode_location', label: 'Passcode Info', inputType: 'text', required: false, placeholder: 'Where is master code documented?' },
          ],
        },
        {
          id: 'house_cleaning',
          billCategory: 'HOUSE_CLEANING',
          label: 'House Cleaning',
          description: 'Regular cleaning service',
          icon: '🧹',
          fields: [
            ...this.getStandardBillFields(),
            { id: 'cleaning_day', label: 'Cleaning Day(s)', inputType: 'text', required: false },
            { id: 'contact_name', label: 'Contact Name', inputType: 'text', required: false },
            { id: 'contact_phone', label: 'Contact Phone', inputType: 'phone', required: false },
            { id: 'access_method', label: 'How Do They Access Home?', inputType: 'text', required: false, placeholder: 'Key, code, etc.' },
          ],
        },
        {
          id: 'snow_removal',
          billCategory: 'SNOW_REMOVAL',
          label: 'Snow Removal',
          description: 'Winter snow plowing/shoveling',
          icon: '❄️',
          showIf: (ctx) => {
            const snowStates = ['CT', 'MA', 'NH', 'ME', 'VT', 'RI', 'NY', 'NJ', 'PA', 'OH', 'MI', 'WI', 'MN', 'IL', 'IN', 'CO', 'UT'];
            return ctx.state ? snowStates.includes(ctx.state.toUpperCase()) : false;
          },
          fields: [
            ...this.getStandardBillFields(),
            { id: 'trigger_amount', label: 'Trigger Amount (inches)', inputType: 'number', required: false },
            { id: 'contact_phone', label: 'Contact Phone', inputType: 'phone', required: false },
          ],
        },
      ],
    });

    // ===========================================================================
    // 9. MEMBERSHIPS & SUBSCRIPTIONS
    // ===========================================================================
    sections.push({
      id: 'bills_memberships',
      title: 'Memberships & Subscriptions',
      description: 'Gym, clubs, streaming, and other subscriptions',
      icon: '🎬',
      bills: [
        {
          id: 'gym_fitness',
          billCategory: 'GYM_FITNESS',
          label: 'Gym/Fitness',
          description: 'Gym or fitness membership',
          icon: '🏋️',
          fields: [
            ...this.getStandardBillFields(),
            { id: 'member_names', label: 'Member Name(s)', inputType: 'text', required: false },
          ],
        },
        {
          id: 'club_membership',
          billCategory: 'CLUB_MEMBERSHIP',
          label: 'Club Membership',
          description: 'Country club, social club, etc.',
          icon: '🏌️',
          fields: [
            ...this.getStandardBillFields(),
            { id: 'club_type', label: 'Club Type', inputType: 'text', required: false, placeholder: 'Country club, tennis club, etc.' },
            { id: 'member_number', label: 'Member Number', inputType: 'text', required: false },
          ],
        },
        {
          id: 'streaming_service',
          billCategory: 'STREAMING_SERVICE',
          label: 'Streaming Services',
          description: 'Netflix, Spotify, etc.',
          icon: '📺',
          fields: [
            { id: 'service_name', label: 'Service Name', inputType: 'text', required: true, placeholder: 'e.g., Netflix, Spotify, Disney+' },
            { id: 'amount', label: 'Monthly Cost', inputType: 'currency', required: true },
            { id: 'frequency', label: 'Billing Frequency', inputType: 'select', required: true, options: ['Monthly', 'Annual'] },
            { id: 'payment_method', label: 'Payment Method', inputType: 'select', required: false, options: ['Credit Card on File', 'Haven Pays'] },
            { id: 'account_email', label: 'Account Email', inputType: 'text', required: false },
            { id: 'notes', label: 'Notes', inputType: 'text', required: false, placeholder: 'Plan tier, family sharing, etc.' },
          ],
        },
        {
          id: 'software_subscription',
          billCategory: 'SOFTWARE_SUBSCRIPTION',
          label: 'Software Subscriptions',
          description: 'Microsoft 365, Adobe, etc.',
          icon: '💻',
          fields: [
            { id: 'service_name', label: 'Software/Service', inputType: 'text', required: true },
            { id: 'amount', label: 'Cost', inputType: 'currency', required: true },
            { id: 'frequency', label: 'Billing Frequency', inputType: 'select', required: true, options: ['Monthly', 'Annual'] },
            { id: 'account_email', label: 'Account Email', inputType: 'text', required: false },
            { id: 'payment_method', label: 'Payment Method', inputType: 'select', required: false, options: ['Credit Card on File', 'Haven Pays'] },
          ],
        },
        {
          id: 'amazon_prime',
          billCategory: 'AMAZON_PRIME',
          label: 'Amazon Prime',
          description: 'Amazon Prime membership',
          icon: '📦',
          fields: [
            { id: 'amount', label: 'Annual Cost', inputType: 'currency', required: true },
            { id: 'renewal_date', label: 'Renewal Date', inputType: 'date', required: false },
            { id: 'account_email', label: 'Account Email', inputType: 'text', required: false },
            { id: 'payment_method', label: 'Payment Method', inputType: 'select', required: false, options: ['Credit Card on File', 'Haven Pays'] },
          ],
        },
        {
          id: 'warehouse_club',
          billCategory: 'WAREHOUSE_CLUB',
          label: 'Warehouse Club',
          description: 'Costco, Sam\'s Club, etc.',
          icon: '🛒',
          fields: [
            { id: 'payee_name', label: 'Club Name', inputType: 'text', required: true, placeholder: 'Costco, Sam\'s Club, BJ\'s' },
            { id: 'member_number', label: 'Member Number', inputType: 'text', required: false },
            { id: 'amount', label: 'Annual Fee', inputType: 'currency', required: true },
            { id: 'renewal_date', label: 'Renewal Date', inputType: 'date', required: false },
            { id: 'payment_method', label: 'Payment Method', inputType: 'select', required: false, options: ['Auto-Renew on File', 'Haven Pays'] },
          ],
        },
        {
          id: 'newspaper_magazine',
          billCategory: 'NEWSPAPER_MAGAZINE',
          label: 'News/Magazine',
          description: 'Newspaper or magazine subscriptions',
          icon: '📰',
          fields: [
            { id: 'publication_name', label: 'Publication', inputType: 'text', required: true },
            { id: 'amount', label: 'Cost', inputType: 'currency', required: true },
            { id: 'frequency', label: 'Billing Frequency', inputType: 'select', required: true, options: ['Monthly', 'Annual', 'Quarterly'] },
            { id: 'account_email', label: 'Account Email', inputType: 'text', required: false },
            { id: 'delivery_type', label: 'Delivery Type', inputType: 'select', required: false, options: ['Digital Only', 'Print', 'Both'] },
          ],
        },
        {
          id: 'meal_kit',
          billCategory: 'MEAL_KIT',
          label: 'Meal Kit Service',
          description: 'HelloFresh, Blue Apron, etc.',
          icon: '🍽️',
          fields: [
            { id: 'payee_name', label: 'Service Name', inputType: 'text', required: true },
            { id: 'amount', label: 'Weekly Cost', inputType: 'currency', required: true },
            { id: 'frequency', label: 'Delivery Frequency', inputType: 'select', required: true, options: ['Weekly', 'Bi-Weekly', 'Paused'] },
            { id: 'account_email', label: 'Account Email', inputType: 'text', required: false },
            { id: 'delivery_day', label: 'Delivery Day', inputType: 'text', required: false },
          ],
        },
      ],
    });

    // ===========================================================================
    // 10. OTHER BILLS
    // ===========================================================================
    sections.push({
      id: 'bills_other',
      title: 'Other Bills',
      description: 'Storage, pet care, donations, and other recurring payments',
      icon: '📋',
      bills: [
        {
          id: 'storage',
          billCategory: 'STORAGE',
          label: 'Storage Unit',
          description: 'Self-storage rental',
          icon: '📦',
          fields: [
            ...this.getStandardBillFields(),
            { id: 'unit_number', label: 'Unit Number', inputType: 'text', required: false },
            { id: 'unit_size', label: 'Unit Size', inputType: 'text', required: false },
            { id: 'access_code', label: 'Gate/Access Code', inputType: 'text', required: false },
          ],
        },
        {
          id: 'pet_care',
          billCategory: 'PET_CARE',
          label: 'Pet Care',
          description: 'Dog walker, groomer, vet plans',
          icon: '🐕',
          showIf: (ctx) => ctx.hasPets,
          fields: [
            { id: 'service_type', label: 'Service Type', inputType: 'text', required: true, placeholder: 'Dog walking, grooming, vet care' },
            { id: 'payee_name', label: 'Provider Name', inputType: 'text', required: true },
            { id: 'pet_name', label: 'Pet Name', inputType: 'text', required: false },
            { id: 'amount', label: 'Cost', inputType: 'currency', required: true },
            { id: 'frequency', label: 'Frequency', inputType: 'select', required: true, options: ['Per Visit', 'Weekly', 'Monthly'] },
            { id: 'payment_method', label: 'Payment Method', inputType: 'select', required: true, options: ['Haven Pays', 'Owner Pays'] },
            { id: 'contact_phone', label: 'Contact Phone', inputType: 'phone', required: false },
          ],
        },
        {
          id: 'charity_donation',
          billCategory: 'CHARITY_DONATION',
          label: 'Recurring Donations',
          description: 'Charitable giving',
          icon: '❤️',
          fields: [
            { id: 'organization', label: 'Organization Name', inputType: 'text', required: true },
            { id: 'amount', label: 'Donation Amount', inputType: 'currency', required: true },
            { id: 'frequency', label: 'Frequency', inputType: 'select', required: true, options: ['Monthly', 'Quarterly', 'Annual'] },
            { id: 'payment_method', label: 'Payment Method', inputType: 'select', required: true, options: ['Haven Pays', 'Auto-Debit on File'] },
            { id: 'donor_account', label: 'Donor ID/Account', inputType: 'text', required: false },
          ],
        },
        {
          id: 'child_support',
          billCategory: 'CHILD_SUPPORT',
          label: 'Child Support',
          description: 'Child support payments',
          icon: '👶',
          fields: [
            { id: 'payee_name', label: 'Payee Name', inputType: 'text', required: true },
            { id: 'amount', label: 'Payment Amount', inputType: 'currency', required: true },
            { id: 'frequency', label: 'Frequency', inputType: 'select', required: true, options: ['Weekly', 'Bi-Weekly', 'Monthly'] },
            { id: 'case_number', label: 'Case Number', inputType: 'text', required: false },
            { id: 'payment_method', label: 'Payment Method', inputType: 'select', required: true, options: ['Haven Pays', 'State Disbursement Unit', 'Direct Payment'] },
            { id: 'notes', label: 'Notes', inputType: 'text', required: false },
          ],
        },
        {
          id: 'alimony',
          billCategory: 'ALIMONY',
          label: 'Alimony/Spousal Support',
          description: 'Spousal support payments',
          icon: '💍',
          fields: [
            { id: 'payee_name', label: 'Payee Name', inputType: 'text', required: true },
            { id: 'amount', label: 'Payment Amount', inputType: 'currency', required: true },
            { id: 'frequency', label: 'Frequency', inputType: 'select', required: true, options: ['Monthly'] },
            { id: 'end_date', label: 'End Date (if known)', inputType: 'date', required: false },
            { id: 'payment_method', label: 'Payment Method', inputType: 'select', required: true, options: ['Haven Pays', 'Direct Payment'] },
          ],
        },
        {
          id: 'other_bill',
          billCategory: 'OTHER_BILL',
          label: 'Other Recurring Bill',
          description: 'Any other recurring payment',
          icon: '📄',
          fields: [
            { id: 'bill_description', label: 'Bill Description', inputType: 'text', required: true, placeholder: 'What is this payment for?' },
            ...this.getStandardBillFields(),
          ],
        },
      ],
    });

    return sections;
  }

  /**
   * Get a flattened list of all bill types for dropdown selection
   */
  getAllBillTypes(): { category: BillCategoryType; label: string; icon: string }[] {
    const types: { category: BillCategoryType; label: string; icon: string }[] = [
      // Housing
      { category: 'MORTGAGE', label: 'Mortgage', icon: '🏦' },
      { category: 'RENT', label: 'Rent', icon: '🔑' },
      { category: 'PROPERTY_TAX', label: 'Property Tax', icon: '📋' },
      { category: 'HOA', label: 'HOA Dues', icon: '🏘️' },
      { category: 'HOME_INSURANCE', label: 'Home Insurance', icon: '🛡️' },
      // Utilities
      { category: 'ELECTRIC', label: 'Electric', icon: '⚡' },
      { category: 'GAS', label: 'Natural Gas', icon: '🔥' },
      { category: 'WATER_SEWER', label: 'Water/Sewer', icon: '💧' },
      { category: 'OIL_PROPANE', label: 'Oil/Propane', icon: '🛢️' },
      { category: 'TRASH', label: 'Trash/Recycling', icon: '🗑️' },
      // Telecom
      { category: 'INTERNET', label: 'Internet', icon: '🌐' },
      { category: 'CABLE_TV', label: 'Cable/Streaming TV', icon: '📺' },
      { category: 'CELL_PHONE', label: 'Cell Phone', icon: '📱' },
      { category: 'LANDLINE', label: 'Landline', icon: '☎️' },
      // Vehicles
      { category: 'CAR_PAYMENT', label: 'Car Payment', icon: '🚙' },
      { category: 'AUTO_INSURANCE', label: 'Auto Insurance', icon: '🛡️' },
      { category: 'CAR_REGISTRATION', label: 'Vehicle Registration', icon: '📝' },
      { category: 'PARKING', label: 'Parking', icon: '🅿️' },
      { category: 'TOLLS', label: 'Toll Account', icon: '🛣️' },
      // Loans
      { category: 'STUDENT_LOAN', label: 'Student Loan', icon: '🎓' },
      { category: 'PERSONAL_LOAN', label: 'Personal Loan', icon: '📄' },
      { category: 'HELOC', label: 'HELOC', icon: '🏡' },
      { category: 'CREDIT_CARD', label: 'Credit Card', icon: '💳' },
      // Family
      { category: 'SCHOOL_TUITION', label: 'School Tuition', icon: '🏫' },
      { category: 'CHILDCARE', label: 'Daycare/Childcare', icon: '👶' },
      { category: 'NANNY', label: 'Nanny/Au Pair', icon: '👩‍🍼' },
      { category: 'KIDS_ACTIVITY', label: 'Kids Activities', icon: '⚽' },
      { category: 'SCHOOL_LUNCH', label: 'School Lunch Account', icon: '🍎' },
      { category: 'TUTORING', label: 'Tutoring', icon: '📚' },
      // Insurance
      { category: 'LIFE_INSURANCE', label: 'Life Insurance', icon: '💝' },
      { category: 'HEALTH_INSURANCE', label: 'Health Insurance', icon: '🏥' },
      { category: 'UMBRELLA_INSURANCE', label: 'Umbrella Insurance', icon: '☂️' },
      { category: 'PET_INSURANCE', label: 'Pet Insurance', icon: '🐾' },
      { category: 'DISABILITY_INSURANCE', label: 'Disability Insurance', icon: '🦽' },
      { category: 'LONG_TERM_CARE', label: 'Long-Term Care Insurance', icon: '🏠' },
      // Home Services
      { category: 'LAWN_LANDSCAPE', label: 'Lawn/Landscaping', icon: '🌿' },
      { category: 'POOL_SERVICE', label: 'Pool Service', icon: '🏊' },
      { category: 'PEST_CONTROL', label: 'Pest Control', icon: '🐜' },
      { category: 'SECURITY_MONITORING', label: 'Security Monitoring', icon: '🔐' },
      { category: 'HOUSE_CLEANING', label: 'House Cleaning', icon: '🧹' },
      { category: 'SNOW_REMOVAL', label: 'Snow Removal', icon: '❄️' },
      // Memberships
      { category: 'GYM_FITNESS', label: 'Gym/Fitness', icon: '🏋️' },
      { category: 'CLUB_MEMBERSHIP', label: 'Club Membership', icon: '🏌️' },
      { category: 'STREAMING_SERVICE', label: 'Streaming Services', icon: '📺' },
      { category: 'SOFTWARE_SUBSCRIPTION', label: 'Software Subscriptions', icon: '💻' },
      { category: 'AMAZON_PRIME', label: 'Amazon Prime', icon: '📦' },
      { category: 'WAREHOUSE_CLUB', label: 'Warehouse Club', icon: '🛒' },
      { category: 'NEWSPAPER_MAGAZINE', label: 'News/Magazine', icon: '📰' },
      { category: 'MEAL_KIT', label: 'Meal Kit Service', icon: '🍽️' },
      // Other
      { category: 'STORAGE', label: 'Storage Unit', icon: '📦' },
      { category: 'PET_CARE', label: 'Pet Care', icon: '🐕' },
      { category: 'CHARITY_DONATION', label: 'Recurring Donations', icon: '❤️' },
      { category: 'CHILD_SUPPORT', label: 'Child Support', icon: '👶' },
      { category: 'ALIMONY', label: 'Alimony/Spousal Support', icon: '💍' },
      { category: 'OTHER_BILL', label: 'Other Recurring Bill', icon: '📄' },
    ];
    return types;
  }

  /**
   * Calculate monthly funding from comprehensive bills
   */
  calculateComprehensiveMonthlyFunding(bills: Array<{
    amount: number;
    frequency: string;
    status?: string;
  }>): {
    total: number;
    breakdown: {
      housing: number;
      utilities: number;
      telecom: number;
      vehicles: number;
      loans: number;
      family: number;
      insurance: number;
      homeServices: number;
      memberships: number;
      other: number;
    };
    havenServiceFee: number;
    recommendedBuffer: number;
    recommendedMonthlyFunding: number;
  } {
    // Normalize all amounts to monthly
    const normalizeToMonthly = (amount: number, frequency: string): number => {
      switch (frequency.toUpperCase()) {
        case 'WEEKLY': return amount * 4.33;
        case 'BI-WEEKLY':
        case 'BIWEEKLY': return amount * 2.17;
        case 'TWICE_MONTHLY': return amount * 2;
        case 'MONTHLY': return amount;
        case 'QUARTERLY': return amount / 3;
        case 'SEMI-ANNUAL':
        case 'SEMI_ANNUAL': return amount / 6;
        case 'ANNUAL': return amount / 12;
        default: return amount;
      }
    };

    const breakdown = {
      housing: 0,
      utilities: 0,
      telecom: 0,
      vehicles: 0,
      loans: 0,
      family: 0,
      insurance: 0,
      homeServices: 0,
      memberships: 0,
      other: 0,
    };

    let total = 0;
    for (const bill of bills) {
      if (bill.status === 'CANCELLED' || bill.status === 'PAID_OFF') continue;
      const monthly = normalizeToMonthly(bill.amount, bill.frequency);
      total += monthly;
    }

    // Calculate Haven service fee (e.g., 3% of total managed bills)
    const havenServiceFee = total * 0.03;

    // Recommend a 10% buffer for variable bills
    const recommendedBuffer = total * 0.10;

    const recommendedMonthlyFunding = total + havenServiceFee + recommendedBuffer;

    return {
      total,
      breakdown,
      havenServiceFee,
      recommendedBuffer,
      recommendedMonthlyFunding,
    };
  }
}
