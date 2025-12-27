import { Injectable } from '@nestjs/common';
import { PropertyDetails } from './property.service';

export interface ChecklistItem {
  id: string;
  category: 'systems' | 'utilities' | 'vendors' | 'maintenance' | 'info';
  priority: 'high' | 'medium' | 'low';
  question: string;
  context?: string; // Why we're asking (from ATTOM data)
  dataField: string; // What field this populates
  inputType: 'text' | 'select' | 'date' | 'phone' | 'vendor';
  options?: string[]; // For select type
  answered?: boolean;
  answer?: string;
}

@Injectable()
export class ChecklistGeneratorService {
  /**
   * Generates a smart checklist based on ATTOM property data.
   * This creates context-aware questions for the Home Manager to ask during the intro call.
   */
  generateChecklist(
    property: PropertyDetails,
    state: string,
    city: string,
  ): ChecklistItem[] {
    const checklist: ChecklistItem[] = [];

    // === HEATING / FUEL ===
    if (property.heatingFuel?.toLowerCase().includes('oil')) {
      checklist.push({
        id: 'oil_vendor',
        category: 'vendors',
        priority: 'high',
        question: 'Who delivers your heating oil?',
        context: 'Property records show oil heat',
        dataField: 'vendors.oil',
        inputType: 'vendor',
      });
      checklist.push({
        id: 'oil_tank_location',
        category: 'systems',
        priority: 'medium',
        question: 'Where is your oil tank located?',
        context: 'Oil heat system',
        dataField: 'systems.oilTank.location',
        inputType: 'select',
        options: ['Basement', 'Garage', 'Underground', 'Above ground outside'],
      });
    }

    if (
      property.heatingFuel?.toLowerCase().includes('propane') ||
      property.heatingFuel?.toLowerCase().includes('lp')
    ) {
      checklist.push({
        id: 'propane_vendor',
        category: 'vendors',
        priority: 'high',
        question: 'Who is your propane provider?',
        context: 'Property records show propane heat',
        dataField: 'vendors.propane',
        inputType: 'vendor',
      });
    }

    if (
      property.heatingFuel?.toLowerCase().includes('gas') ||
      property.heatingFuel?.toLowerCase().includes('natural')
    ) {
      checklist.push({
        id: 'gas_provider',
        category: 'utilities',
        priority: 'high',
        question: 'Who is your gas provider?',
        context: 'Property records show natural gas',
        dataField: 'utilities.gas',
        inputType: 'vendor',
      });
    }

    // Furnace/Boiler details
    if (property.heatingType) {
      checklist.push({
        id: 'heating_brand',
        category: 'systems',
        priority: 'medium',
        question: `What brand/model is your ${property.heatingType.toLowerCase()}?`,
        context: `Property has ${property.heatingType}`,
        dataField: 'systems.heating.brand',
        inputType: 'text',
      });
      checklist.push({
        id: 'heating_service',
        category: 'vendors',
        priority: 'medium',
        question: 'Who services your heating system?',
        context: 'Annual maintenance recommended',
        dataField: 'vendors.hvac',
        inputType: 'vendor',
      });
      checklist.push({
        id: 'heating_last_service',
        category: 'maintenance',
        priority: 'low',
        question: 'When was it last serviced?',
        dataField: 'systems.heating.lastService',
        inputType: 'date',
      });
    }

    // === COOLING ===
    if (
      property.coolingType &&
      !property.coolingType.toLowerCase().includes('none')
    ) {
      checklist.push({
        id: 'ac_brand',
        category: 'systems',
        priority: 'low',
        question: 'What brand is your AC system?',
        context: `Property has ${property.coolingType}`,
        dataField: 'systems.cooling.brand',
        inputType: 'text',
      });
    }

    // === WATER HEATER ===
    checklist.push({
      id: 'water_heater_type',
      category: 'systems',
      priority: 'medium',
      question: 'What type of water heater do you have?',
      dataField: 'systems.waterHeater.type',
      inputType: 'select',
      options: [
        'Gas tank',
        'Electric tank',
        'Tankless gas',
        'Tankless electric',
        'Heat pump',
        'Solar',
        'Not sure',
      ],
    });
    checklist.push({
      id: 'water_heater_age',
      category: 'systems',
      priority: 'low',
      question: 'Approximately how old is it?',
      dataField: 'systems.waterHeater.age',
      inputType: 'text',
    });

    // === FIREPLACES ===
    if (property.fireplaces && property.fireplaces > 0) {
      checklist.push({
        id: 'fireplace_type',
        category: 'systems',
        priority: 'medium',
        question:
          property.fireplaces > 1
            ? `What type are your ${property.fireplaces} fireplaces?`
            : 'What type is your fireplace?',
        context: `Property has ${property.fireplaces} fireplace(s)`,
        dataField: 'systems.fireplace.type',
        inputType: 'select',
        options: ['Wood burning', 'Gas', 'Electric', 'Pellet', 'Mixed'],
      });
      checklist.push({
        id: 'chimney_sweep',
        category: 'vendors',
        priority: 'medium',
        question: 'Do you have a chimney sweep service?',
        context: 'Annual chimney inspection recommended',
        dataField: 'vendors.chimneySweep',
        inputType: 'vendor',
      });
      checklist.push({
        id: 'chimney_last_cleaned',
        category: 'maintenance',
        priority: 'low',
        question: 'When was the chimney last cleaned?',
        dataField: 'systems.fireplace.lastCleaned',
        inputType: 'date',
      });
    }

    // === SEPTIC ===
    if (property.sewerType?.toLowerCase().includes('septic')) {
      checklist.push({
        id: 'septic_company',
        category: 'vendors',
        priority: 'high',
        question: 'Who services your septic system?',
        context: 'Property has septic (not municipal sewer)',
        dataField: 'vendors.septic',
        inputType: 'vendor',
      });
      checklist.push({
        id: 'septic_last_pumped',
        category: 'maintenance',
        priority: 'high',
        question: 'When was it last pumped?',
        context: 'Recommended every 3-5 years',
        dataField: 'systems.septic.lastPumped',
        inputType: 'date',
      });
      checklist.push({
        id: 'septic_tank_size',
        category: 'systems',
        priority: 'low',
        question: 'Do you know the tank size?',
        dataField: 'systems.septic.tankSize',
        inputType: 'text',
      });
    }

    // === WELL WATER ===
    if (property.waterType?.toLowerCase().includes('well')) {
      checklist.push({
        id: 'well_service',
        category: 'vendors',
        priority: 'medium',
        question: 'Who services your well?',
        context: 'Property has well water',
        dataField: 'vendors.well',
        inputType: 'vendor',
      });
      checklist.push({
        id: 'well_last_tested',
        category: 'maintenance',
        priority: 'medium',
        question: 'When was the water last tested?',
        context: 'Annual testing recommended',
        dataField: 'systems.well.lastTested',
        inputType: 'date',
      });
    }

    // === ROOF ===
    checklist.push({
      id: 'roof_age',
      category: 'systems',
      priority: 'medium',
      question: property.roofMaterial
        ? `Approximately when was your ${property.roofMaterial.toLowerCase()} roof installed?`
        : 'Approximately when was your roof installed?',
      context: property.roofMaterial
        ? `Property has ${property.roofMaterial} roof`
        : undefined,
      dataField: 'systems.roof.installed',
      inputType: 'text',
    });
    checklist.push({
      id: 'roofer',
      category: 'vendors',
      priority: 'low',
      question: 'Do you have a roofer you use?',
      dataField: 'vendors.roofer',
      inputType: 'vendor',
    });

    // === GUTTERS ===
    checklist.push({
      id: 'gutter_cleaning',
      category: 'vendors',
      priority: 'medium',
      question: 'Who cleans your gutters?',
      context: 'Recommended 1-2x per year',
      dataField: 'vendors.gutters',
      inputType: 'vendor',
    });

    // === POOL ===
    if (property.pool) {
      checklist.push({
        id: 'pool_service',
        category: 'vendors',
        priority: 'high',
        question: 'Who services your pool?',
        context: `Property has a ${property.poolType || 'pool'}`,
        dataField: 'vendors.pool',
        inputType: 'vendor',
      });
      checklist.push({
        id: 'pool_opening',
        category: 'maintenance',
        priority: 'medium',
        question: 'When do you typically open the pool?',
        dataField: 'systems.pool.openingMonth',
        inputType: 'select',
        options: ['April', 'May', 'June', 'Year-round'],
      });
    }

    // === GARAGE ===
    if (property.garageSpaces && property.garageSpaces > 0) {
      checklist.push({
        id: 'garage_door_service',
        category: 'vendors',
        priority: 'low',
        question: 'Who services your garage door(s)?',
        context: `${property.garageSpaces}-car ${property.garage || 'garage'}`,
        dataField: 'vendors.garageDoor',
        inputType: 'vendor',
      });
    }

    // === STANDARD UTILITIES ===
    checklist.push({
      id: 'electric_provider',
      category: 'utilities',
      priority: 'high',
      question: 'Who is your electric provider?',
      dataField: 'utilities.electric',
      inputType: 'vendor',
    });

    // Only ask about gas if they don't have it from heating
    if (!property.heatingFuel?.toLowerCase().includes('electric')) {
      const hasGasQuestion = checklist.find((c) => c.id === 'gas_provider');
      if (!hasGasQuestion) {
        checklist.push({
          id: 'gas_provider',
          category: 'utilities',
          priority: 'medium',
          question: 'Do you have gas service? If so, who is the provider?',
          dataField: 'utilities.gas',
          inputType: 'vendor',
        });
      }
    }

    // Municipal water billing
    if (!property.waterType?.toLowerCase().includes('well')) {
      checklist.push({
        id: 'water_provider',
        category: 'utilities',
        priority: 'medium',
        question: 'Who bills you for water?',
        context: 'Usually municipal',
        dataField: 'utilities.water',
        inputType: 'vendor',
      });
    }

    // === TELECOM ===
    checklist.push({
      id: 'internet_provider',
      category: 'utilities',
      priority: 'medium',
      question: 'Who is your internet provider?',
      dataField: 'utilities.internet',
      inputType: 'vendor',
    });
    checklist.push({
      id: 'cell_provider',
      category: 'utilities',
      priority: 'low',
      question: 'Cell phone provider?',
      dataField: 'utilities.cell',
      inputType: 'vendor',
    });

    // === SECURITY/MONITORING ===
    checklist.push({
      id: 'security_system',
      category: 'systems',
      priority: 'medium',
      question: 'Do you have a security/alarm system? If so, who monitors it?',
      dataField: 'systems.security.provider',
      inputType: 'vendor',
    });

    // === APPLIANCES ===
    checklist.push({
      id: 'appliance_ages',
      category: 'info',
      priority: 'low',
      question:
        'Are any major appliances old or needing replacement soon? (Fridge, dishwasher, washer, dryer, oven)',
      dataField: 'appliances.notes',
      inputType: 'text',
    });

    // === LAWN/LANDSCAPE ===
    if (property.lotSizeAcres && property.lotSizeAcres > 0.25) {
      checklist.push({
        id: 'lawn_service',
        category: 'vendors',
        priority: 'medium',
        question: 'Do you have a lawn/landscaping service?',
        context: `Property is ${property.lotSizeAcres.toFixed(2)} acres`,
        dataField: 'vendors.lawn',
        inputType: 'vendor',
      });
    } else {
      checklist.push({
        id: 'lawn_service',
        category: 'vendors',
        priority: 'low',
        question: 'Do you use a lawn or landscaping service?',
        dataField: 'vendors.lawn',
        inputType: 'vendor',
      });
    }

    // === SNOW REMOVAL (Northeast states) ===
    const northeastStates = [
      'CT',
      'MA',
      'NH',
      'ME',
      'VT',
      'RI',
      'NY',
      'NJ',
      'PA',
      'OH',
      'MI',
      'WI',
      'MN',
      'IL',
      'IN',
    ];
    if (northeastStates.includes(state.toUpperCase())) {
      checklist.push({
        id: 'snow_removal',
        category: 'vendors',
        priority: 'medium',
        question: 'Who handles snow removal?',
        context: 'Important for winter months',
        dataField: 'vendors.snow',
        inputType: 'vendor',
      });
    }

    // === PEST CONTROL ===
    checklist.push({
      id: 'pest_control',
      category: 'vendors',
      priority: 'low',
      question: 'Do you use a pest control service?',
      dataField: 'vendors.pestControl',
      inputType: 'vendor',
    });

    // === GENERAL TRADES ===
    checklist.push({
      id: 'handyman',
      category: 'vendors',
      priority: 'low',
      question: 'Do you have a go-to handyman?',
      dataField: 'vendors.handyman',
      inputType: 'vendor',
    });
    checklist.push({
      id: 'electrician',
      category: 'vendors',
      priority: 'low',
      question: 'Electrician you trust?',
      dataField: 'vendors.electrician',
      inputType: 'vendor',
    });
    checklist.push({
      id: 'plumber',
      category: 'vendors',
      priority: 'low',
      question: 'Plumber you use?',
      dataField: 'vendors.plumber',
      inputType: 'vendor',
    });

    // === INSURANCE ===
    checklist.push({
      id: 'home_insurance',
      category: 'info',
      priority: 'medium',
      question: 'Who is your home insurance with?',
      dataField: 'insurance.home',
      inputType: 'vendor',
    });

    // === PREFERENCES ===
    checklist.push({
      id: 'urgent_concerns',
      category: 'info',
      priority: 'high',
      question:
        'Is there anything about your home that needs attention soon or has been bothering you?',
      dataField: 'notes.urgentConcerns',
      inputType: 'text',
    });

    checklist.push({
      id: 'special_instructions',
      category: 'info',
      priority: 'medium',
      question:
        'Any special instructions for service providers? (Gate codes, pet concerns, preferred contact times)',
      dataField: 'notes.specialInstructions',
      inputType: 'text',
    });

    // Sort by priority
    const priorityOrder: Record<string, number> = { high: 0, medium: 1, low: 2 };
    checklist.sort((a, b) => priorityOrder[a.priority] - priorityOrder[b.priority]);

    return checklist;
  }

  /**
   * Get a summary of what the checklist covers based on property data
   */
  getChecklistSummary(property: PropertyDetails): {
    totalQuestions: number;
    highPriority: number;
    categories: string[];
    highlights: string[];
  } {
    const checklist = this.generateChecklist(property, '', '');
    const highlights: string[] = [];

    if (property.heatingFuel?.toLowerCase().includes('oil')) {
      highlights.push('Oil heating system detected');
    }
    if (property.pool) {
      highlights.push('Pool detected');
    }
    if (property.fireplaces && property.fireplaces > 0) {
      highlights.push(`${property.fireplaces} fireplace(s) detected`);
    }
    if (property.sewerType?.toLowerCase().includes('septic')) {
      highlights.push('Septic system detected');
    }
    if (property.lotSizeAcres && property.lotSizeAcres > 1) {
      highlights.push(`Large lot (${property.lotSizeAcres.toFixed(1)} acres)`);
    }

    const categories = [...new Set(checklist.map((c) => c.category))];

    return {
      totalQuestions: checklist.length,
      highPriority: checklist.filter((c) => c.priority === 'high').length,
      categories,
      highlights,
    };
  }
}
