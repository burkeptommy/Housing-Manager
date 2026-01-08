import { Injectable, Logger } from '@nestjs/common';
import Anthropic from '@anthropic-ai/sdk';

export interface MaintenanceRequirement {
  taskName: string;
  description: string;
  intervalMonths: number;
  estimatedCost: { min: number; max: number };
  diyPossible: boolean;
  professionalRecommended: boolean;
  criticalLevel: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
  seasonalPreference?: string; // "spring", "fall", "before-winter", etc.
  notes?: string;
}

export interface EquipmentResearchResult {
  manufacturer: string;
  model: string;
  category: string;
  type: string;
  typicalLifespan: string;
  maintenanceRequirements: MaintenanceRequirement[];
  warrantyInfo?: string;
  commonIssues?: string[];
  energyEfficiencyTips?: string[];
  generalNotes?: string;
}

@Injectable()
export class EquipmentResearchService {
  private readonly logger = new Logger(EquipmentResearchService.name);
  private anthropic: Anthropic;

  constructor() {
    if (!process.env.ANTHROPIC_API_KEY) {
      this.logger.warn('ANTHROPIC_API_KEY not configured - equipment research will use defaults');
    }
    this.anthropic = new Anthropic({
      apiKey: process.env.ANTHROPIC_API_KEY,
    });
  }

  async researchEquipment(
    category: string,
    type: string,
    manufacturer?: string,
    model?: string,
  ): Promise<EquipmentResearchResult> {
    if (!process.env.ANTHROPIC_API_KEY) {
      return this.getDefaultMaintenanceRequirements(category, type, manufacturer, model);
    }

    const prompt = `You are an expert home maintenance advisor. Research and provide detailed maintenance requirements for this home equipment:

Category: ${category}
Type: ${type}
${manufacturer ? `Manufacturer: ${manufacturer}` : ''}
${model ? `Model: ${model}` : ''}

Provide a JSON response with this exact structure:
{
  "manufacturer": "${manufacturer || 'Generic'}",
  "model": "${model || 'Standard'}",
  "category": "${category}",
  "type": "${type}",
  "typicalLifespan": "X-Y years",
  "maintenanceRequirements": [
    {
      "taskName": "Task name",
      "description": "What this maintenance involves",
      "intervalMonths": 12,
      "estimatedCost": { "min": 100, "max": 200 },
      "diyPossible": false,
      "professionalRecommended": true,
      "criticalLevel": "HIGH",
      "seasonalPreference": "fall",
      "notes": "Additional notes"
    }
  ],
  "warrantyInfo": "Typical warranty information",
  "commonIssues": ["Issue 1", "Issue 2"],
  "energyEfficiencyTips": ["Tip 1", "Tip 2"],
  "generalNotes": "Any other important information"
}

Be specific and accurate. Include ALL recommended maintenance tasks for this equipment type. Consider:
- Regular service intervals (annual, semi-annual, quarterly, monthly)
- Filter changes if applicable
- Professional inspections
- Cleaning requirements
- Safety checks
- Seasonal preparation

Respond ONLY with valid JSON, no other text.`;

    try {
      const response = await this.anthropic.messages.create({
        model: 'claude-sonnet-4-20250514',
        max_tokens: 2000,
        messages: [{ role: 'user', content: prompt }],
      });

      const content = response.content[0].type === 'text' ? response.content[0].text : '';

      // Parse JSON from response
      const jsonMatch = content.match(/\{[\s\S]*\}/);
      if (!jsonMatch) {
        throw new Error('No JSON found in response');
      }

      const result = JSON.parse(jsonMatch[0]) as EquipmentResearchResult;
      this.logger.log(`Successfully researched ${type} maintenance requirements`);
      return result;
    } catch (error) {
      this.logger.error('Equipment research failed:', error);

      // Return default maintenance requirements based on category
      return this.getDefaultMaintenanceRequirements(category, type, manufacturer, model);
    }
  }

  private getDefaultMaintenanceRequirements(
    category: string,
    type: string,
    manufacturer?: string,
    model?: string,
  ): EquipmentResearchResult {
    const defaults: Record<string, MaintenanceRequirement[]> = {
      HVAC: [
        {
          taskName: 'Annual HVAC Service',
          description: 'Professional inspection, cleaning, and tune-up',
          intervalMonths: 12,
          estimatedCost: { min: 150, max: 300 },
          diyPossible: false,
          professionalRecommended: true,
          criticalLevel: 'HIGH',
          seasonalPreference: 'fall',
        },
        {
          taskName: 'Replace Air Filter',
          description: 'Replace HVAC air filter for optimal airflow and air quality',
          intervalMonths: 3,
          estimatedCost: { min: 15, max: 50 },
          diyPossible: true,
          professionalRecommended: false,
          criticalLevel: 'MEDIUM',
        },
      ],
      PLUMBING: [
        {
          taskName: 'Water Heater Flush',
          description: 'Drain and flush sediment from water heater tank',
          intervalMonths: 12,
          estimatedCost: { min: 100, max: 200 },
          diyPossible: true,
          professionalRecommended: false,
          criticalLevel: 'MEDIUM',
        },
        {
          taskName: 'Water Heater Inspection',
          description: 'Professional inspection of anode rod, valves, and connections',
          intervalMonths: 24,
          estimatedCost: { min: 100, max: 150 },
          diyPossible: false,
          professionalRecommended: true,
          criticalLevel: 'HIGH',
        },
      ],
      ELECTRICAL: [
        {
          taskName: 'Generator Service',
          description: 'Oil change, filter replacement, and system check',
          intervalMonths: 12,
          estimatedCost: { min: 200, max: 400 },
          diyPossible: false,
          professionalRecommended: true,
          criticalLevel: 'HIGH',
        },
        {
          taskName: 'Generator Exercise Run',
          description: 'Run generator for 15-30 minutes to keep it operational',
          intervalMonths: 1,
          estimatedCost: { min: 0, max: 10 },
          diyPossible: true,
          professionalRecommended: false,
          criticalLevel: 'MEDIUM',
        },
      ],
      SEPTIC: [
        {
          taskName: 'Septic Tank Pumping',
          description: 'Pump and inspect septic tank',
          intervalMonths: 36,
          estimatedCost: { min: 300, max: 600 },
          diyPossible: false,
          professionalRecommended: true,
          criticalLevel: 'CRITICAL',
        },
        {
          taskName: 'Septic Inspection',
          description: 'Professional inspection of septic system',
          intervalMonths: 12,
          estimatedCost: { min: 100, max: 200 },
          diyPossible: false,
          professionalRecommended: true,
          criticalLevel: 'HIGH',
        },
      ],
      POOL: [
        {
          taskName: 'Pool Opening Service',
          description: 'Professional pool opening, chemical balance, and equipment check',
          intervalMonths: 12,
          estimatedCost: { min: 200, max: 400 },
          diyPossible: false,
          professionalRecommended: true,
          criticalLevel: 'HIGH',
          seasonalPreference: 'spring',
        },
        {
          taskName: 'Pool Closing Service',
          description: 'Professional winterization and cover installation',
          intervalMonths: 12,
          estimatedCost: { min: 200, max: 400 },
          diyPossible: false,
          professionalRecommended: true,
          criticalLevel: 'HIGH',
          seasonalPreference: 'fall',
        },
      ],
      APPLIANCE: [
        {
          taskName: 'Appliance Cleaning & Inspection',
          description: 'Clean and inspect appliance for optimal operation',
          intervalMonths: 12,
          estimatedCost: { min: 0, max: 50 },
          diyPossible: true,
          professionalRecommended: false,
          criticalLevel: 'LOW',
        },
      ],
      SAFETY: [
        {
          taskName: 'Safety System Test',
          description: 'Test and inspect safety equipment',
          intervalMonths: 6,
          estimatedCost: { min: 0, max: 50 },
          diyPossible: true,
          professionalRecommended: false,
          criticalLevel: 'CRITICAL',
        },
        {
          taskName: 'Battery Replacement',
          description: 'Replace batteries in smoke/CO detectors',
          intervalMonths: 12,
          estimatedCost: { min: 10, max: 30 },
          diyPossible: true,
          professionalRecommended: false,
          criticalLevel: 'CRITICAL',
        },
      ],
      EXTERIOR: [
        {
          taskName: 'Annual Inspection',
          description: 'Inspect for damage, wear, and needed repairs',
          intervalMonths: 12,
          estimatedCost: { min: 100, max: 300 },
          diyPossible: false,
          professionalRecommended: true,
          criticalLevel: 'MEDIUM',
        },
      ],
      LAWN: [
        {
          taskName: 'Irrigation System Winterization',
          description: 'Blow out lines and prepare system for winter',
          intervalMonths: 12,
          estimatedCost: { min: 75, max: 150 },
          diyPossible: false,
          professionalRecommended: true,
          criticalLevel: 'HIGH',
          seasonalPreference: 'before-winter',
        },
        {
          taskName: 'Irrigation System Startup',
          description: 'Test and activate irrigation system for season',
          intervalMonths: 12,
          estimatedCost: { min: 75, max: 150 },
          diyPossible: false,
          professionalRecommended: true,
          criticalLevel: 'MEDIUM',
          seasonalPreference: 'spring',
        },
      ],
    };

    // Get category from type mapping
    const categoryKey = this.getCategoryFromType(type, category);
    const requirements = defaults[categoryKey] || defaults.APPLIANCE;

    return {
      manufacturer: manufacturer || 'Generic',
      model: model || 'Standard',
      category: categoryKey,
      type,
      typicalLifespan: this.getTypicalLifespan(categoryKey, type),
      maintenanceRequirements: requirements,
      generalNotes: 'Default maintenance schedule applied. Consider researching specific model requirements.',
    };
  }

  private getCategoryFromType(type: string, fallbackCategory: string): string {
    const typeUpper = type.toUpperCase().replace(/[^A-Z_]/g, '_');

    // Map common types to categories
    const typeMapping: Record<string, string> = {
      FURNACE: 'HVAC',
      AIR_CONDITIONER: 'HVAC',
      AC: 'HVAC',
      HEAT_PUMP: 'HVAC',
      BOILER: 'HVAC',
      THERMOSTAT: 'HVAC',
      WATER_HEATER: 'PLUMBING',
      TANKLESS_WATER_HEATER: 'PLUMBING',
      SUMP_PUMP: 'PLUMBING',
      WELL_PUMP: 'PLUMBING',
      WATER_SOFTENER: 'PLUMBING',
      GENERATOR: 'ELECTRICAL',
      SOLAR: 'ELECTRICAL',
      EV_CHARGER: 'ELECTRICAL',
      SEPTIC: 'SEPTIC',
      SEPTIC_TANK: 'SEPTIC',
      POOL: 'POOL',
      POOL_PUMP: 'POOL',
      HOT_TUB: 'POOL',
      SPA: 'POOL',
      SMOKE_DETECTOR: 'SAFETY',
      CO_DETECTOR: 'SAFETY',
      SECURITY: 'SAFETY',
      ROOF: 'EXTERIOR',
      GUTTERS: 'EXTERIOR',
      DECK: 'EXTERIOR',
      FENCE: 'EXTERIOR',
      IRRIGATION: 'LAWN',
      SPRINKLER: 'LAWN',
      REFRIGERATOR: 'APPLIANCE',
      DISHWASHER: 'APPLIANCE',
      WASHER: 'APPLIANCE',
      DRYER: 'APPLIANCE',
      OVEN: 'APPLIANCE',
      RANGE: 'APPLIANCE',
    };

    return typeMapping[typeUpper] || fallbackCategory.toUpperCase() || 'APPLIANCE';
  }

  private getTypicalLifespan(category: string, type: string): string {
    const lifespans: Record<string, string> = {
      HVAC: '15-20 years',
      PLUMBING: '10-15 years',
      ELECTRICAL: '20-30 years',
      SEPTIC: '25-30 years',
      POOL: '8-12 years',
      APPLIANCE: '10-15 years',
      SAFETY: '7-10 years',
      EXTERIOR: '20-50 years',
      LAWN: '10-15 years',
    };

    return lifespans[category] || '10-15 years';
  }
}
