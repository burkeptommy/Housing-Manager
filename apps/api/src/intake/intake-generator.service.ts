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
  | 'vendors';

export type IntakeCategory =
  | 'family_info'
  | 'appliances'
  | 'systems'
  | 'utilities'
  | 'bills'
  | 'vendors'
  | 'maintenance';

export type InputType = 'text' | 'select' | 'date' | 'number' | 'phone' | 'currency' | 'boolean' | 'multi_select';

export interface IntakeItem {
  id: string;
  zone: IntakeZone;
  category: IntakeCategory;
  label: string;
  question: string;
  context?: string; // Additional info from ATTOM or previous answers
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
}
