import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  MaintenanceCategory,
  MaintenanceFrequency,
  SeasonalTiming,
  TaskPriority,
} from '@prisma/client';

interface PropertyEnrichment {
  heatingType?: string;
  heatingFuel?: string;
  coolingType?: string;
  hasPool?: boolean;
  hasSeptic?: boolean;
  hasWellWater?: boolean;
  fireplaceCount?: number;
  yearBuilt?: number;
  roofType?: string;
  roofYear?: number;
  squareFeet?: number;
  stories?: number;
  garageType?: string;
  lotSizeAcres?: number;
}

interface TaskTemplate {
  title: string;
  description: string;
  category: MaintenanceCategory;
  frequency: MaintenanceFrequency;
  seasonalTiming?: SeasonalTiming;
  priority?: TaskPriority;
  estimatedCost?: number;
  sourceSystem: string;
  condition?: (enrichment: PropertyEnrichment) => boolean;
  dueDateCalculator?: (now: Date) => Date;
}

@Injectable()
export class MaintenanceGeneratorService {
  private readonly logger = new Logger(MaintenanceGeneratorService.name);

  constructor(private prisma: PrismaService) {}

  /**
   * Generate maintenance tasks for a household based on property data
   */
  async generateTasksForHousehold(
    householdId: string,
    enrichment: PropertyEnrichment,
    state?: string,
  ): Promise<number> {
    const templates = this.getApplicableTemplates(enrichment, state);
    const now = new Date();

    let created = 0;

    for (const template of templates) {
      // Check if task already exists
      const existing = await this.prisma.maintenanceTask.findFirst({
        where: {
          householdId,
          title: template.title,
          sourceSystem: template.sourceSystem,
        },
      });

      if (existing) continue;

      // Calculate next due date
      const nextDueDate = template.dueDateCalculator
        ? template.dueDateCalculator(now)
        : this.calculateNextDueDate(
            template.frequency,
            template.seasonalTiming,
            now,
          );

      // Create the task
      await this.prisma.maintenanceTask.create({
        data: {
          householdId,
          title: template.title,
          description: template.description,
          category: template.category,
          frequency: template.frequency,
          seasonalTiming: template.seasonalTiming,
          nextDueDate,
          dueDate: nextDueDate,
          sourceSystem: template.sourceSystem,
          source: 'SYSTEM_GENERATED',
          priority: template.priority || 'MEDIUM',
          estimatedCost: template.estimatedCost,
          isRecurring: template.frequency !== 'ONE_TIME',
          status: 'UPCOMING',
        },
      });

      created++;
    }

    this.logger.log(
      `Generated ${created} maintenance tasks for household ${householdId}`,
    );
    return created;
  }

  /**
   * Get task templates that apply to this property
   */
  private getApplicableTemplates(
    enrichment: PropertyEnrichment,
    state?: string,
  ): TaskTemplate[] {
    const allTemplates = this.getAllTemplates(state);
    return allTemplates.filter((t) => !t.condition || t.condition(enrichment));
  }

  /**
   * All possible maintenance task templates
   */
  private getAllTemplates(state?: string): TaskTemplate[] {
    const isNortheast = [
      'CT',
      'NY',
      'NJ',
      'MA',
      'NH',
      'VT',
      'ME',
      'RI',
      'PA',
    ].includes(state || '');

    return [
      // ========== HVAC ==========
      {
        title: 'HVAC Filter Change',
        description:
          'Replace or clean HVAC air filters for optimal efficiency and air quality',
        category: 'HVAC',
        frequency: 'QUARTERLY',
        seasonalTiming: 'ANY',
        priority: 'MEDIUM',
        estimatedCost: 30,
        sourceSystem: 'HVAC',
        condition: (e) => !!e.heatingType || !!e.coolingType,
      },
      {
        title: 'Furnace Annual Service',
        description:
          'Professional inspection and tune-up of heating system before winter',
        category: 'HVAC',
        frequency: 'ANNUAL',
        seasonalTiming: 'FALL',
        priority: 'HIGH',
        estimatedCost: 150,
        sourceSystem: 'HVAC',
        condition: (e) =>
          e.heatingType?.toLowerCase().includes('forced') ||
          e.heatingFuel?.toLowerCase().includes('gas') ||
          e.heatingFuel?.toLowerCase().includes('oil'),
      },
      {
        title: 'AC Annual Service',
        description:
          'Professional inspection and tune-up of cooling system before summer',
        category: 'HVAC',
        frequency: 'ANNUAL',
        seasonalTiming: 'SPRING',
        priority: 'HIGH',
        estimatedCost: 150,
        sourceSystem: 'HVAC',
        condition: (e) => e.coolingType?.toLowerCase().includes('central'),
      },
      {
        title: 'Oil Tank Inspection',
        description: 'Annual inspection of oil tank for leaks and corrosion',
        category: 'HVAC',
        frequency: 'ANNUAL',
        seasonalTiming: 'FALL',
        priority: 'HIGH',
        estimatedCost: 100,
        sourceSystem: 'HVAC',
        condition: (e) => e.heatingFuel?.toLowerCase().includes('oil'),
      },

      // ========== POOL ==========
      {
        title: 'Pool Opening',
        description:
          'Remove cover, start filtration, balance chemicals, inspect equipment',
        category: 'POOL',
        frequency: 'ANNUAL',
        seasonalTiming: 'SPRING',
        priority: 'HIGH',
        estimatedCost: 350,
        sourceSystem: 'Pool',
        condition: (e) => e.hasPool === true,
      },
      {
        title: 'Pool Closing',
        description:
          'Winterize pool, add closing chemicals, install cover, drain equipment',
        category: 'POOL',
        frequency: 'ANNUAL',
        seasonalTiming: 'FALL',
        priority: 'HIGH',
        estimatedCost: 350,
        sourceSystem: 'Pool',
        condition: (e) => e.hasPool === true && isNortheast,
      },
      {
        title: 'Pool Weekly Service',
        description: 'Test and balance chemicals, clean filter, skim debris',
        category: 'POOL',
        frequency: 'AS_NEEDED',
        seasonalTiming: 'SUMMER',
        priority: 'MEDIUM',
        estimatedCost: 150,
        sourceSystem: 'Pool',
        condition: (e) => e.hasPool === true,
      },

      // ========== SEPTIC ==========
      {
        title: 'Septic Tank Pumping',
        description:
          'Pump and inspect septic tank (recommended every 3-5 years)',
        category: 'SEPTIC',
        frequency: 'TRIENNIAL',
        seasonalTiming: 'ANY',
        priority: 'HIGH',
        estimatedCost: 400,
        sourceSystem: 'Septic',
        condition: (e) => e.hasSeptic === true,
      },
      {
        title: 'Septic System Inspection',
        description: 'Professional inspection of septic system components',
        category: 'SEPTIC',
        frequency: 'ANNUAL',
        seasonalTiming: 'SPRING',
        priority: 'MEDIUM',
        estimatedCost: 150,
        sourceSystem: 'Septic',
        condition: (e) => e.hasSeptic === true,
      },

      // ========== WELL WATER ==========
      {
        title: 'Well Water Testing',
        description: 'Test well water for bacteria, nitrates, and contaminants',
        category: 'PLUMBING',
        frequency: 'ANNUAL',
        seasonalTiming: 'SPRING',
        priority: 'HIGH',
        estimatedCost: 150,
        sourceSystem: 'Well',
        condition: (e) => e.hasWellWater === true,
      },
      {
        title: 'Well Pump Inspection',
        description: 'Inspect well pump and pressure tank',
        category: 'PLUMBING',
        frequency: 'ANNUAL',
        seasonalTiming: 'ANY',
        priority: 'MEDIUM',
        estimatedCost: 200,
        sourceSystem: 'Well',
        condition: (e) => e.hasWellWater === true,
      },

      // ========== FIREPLACE ==========
      {
        title: 'Chimney Sweep & Inspection',
        description: 'Professional chimney cleaning and safety inspection',
        category: 'CHIMNEY',
        frequency: 'ANNUAL',
        seasonalTiming: 'FALL',
        priority: 'HIGH',
        estimatedCost: 250,
        sourceSystem: 'Fireplace',
        condition: (e) => (e.fireplaceCount || 0) > 0,
      },

      // ========== ROOF ==========
      {
        title: 'Roof Inspection',
        description:
          'Professional inspection for damage, wear, and potential issues',
        category: 'ROOFING',
        frequency: 'ANNUAL',
        seasonalTiming: 'SPRING',
        priority: 'MEDIUM',
        estimatedCost: 200,
        sourceSystem: 'Roof',
        condition: (e) => {
          // Recommend if roof is 15+ years old
          if (!e.yearBuilt && !e.roofYear) return true;
          const roofAge = e.roofYear
            ? new Date().getFullYear() - e.roofYear
            : new Date().getFullYear() - (e.yearBuilt || 2000);
          return roofAge >= 15;
        },
      },

      // ========== EXTERIOR - ALWAYS APPLICABLE ==========
      {
        title: 'Gutter Cleaning',
        description: 'Clean gutters and downspouts, check for damage',
        category: 'EXTERIOR',
        frequency: 'SEMI_ANNUAL',
        seasonalTiming: 'FALL',
        priority: 'MEDIUM',
        estimatedCost: 150,
        sourceSystem: 'Exterior',
      },
      {
        title: 'Spring Gutter Check',
        description: 'Clean gutters after winter, check for ice damage',
        category: 'EXTERIOR',
        frequency: 'ANNUAL',
        seasonalTiming: 'SPRING',
        priority: 'MEDIUM',
        estimatedCost: 150,
        sourceSystem: 'Exterior',
        condition: () => isNortheast,
      },
      {
        title: 'Power Wash Exterior',
        description: 'Clean siding, walkways, and driveway',
        category: 'EXTERIOR',
        frequency: 'ANNUAL',
        seasonalTiming: 'SPRING',
        priority: 'LOW',
        estimatedCost: 300,
        sourceSystem: 'Exterior',
      },

      // ========== LANDSCAPING ==========
      {
        title: 'Spring Lawn Treatment',
        description: 'Fertilization, weed control, and soil testing',
        category: 'LANDSCAPING',
        frequency: 'ANNUAL',
        seasonalTiming: 'SPRING',
        priority: 'MEDIUM',
        estimatedCost: 200,
        sourceSystem: 'Landscaping',
        condition: (e) => (e.lotSizeAcres || 0) > 0.25,
      },
      {
        title: 'Fall Lawn Aeration',
        description: 'Aerate and overseed lawn for winter preparation',
        category: 'LANDSCAPING',
        frequency: 'ANNUAL',
        seasonalTiming: 'FALL',
        priority: 'LOW',
        estimatedCost: 200,
        sourceSystem: 'Landscaping',
        condition: (e) => (e.lotSizeAcres || 0) > 0.25,
      },
      {
        title: 'Tree & Shrub Trimming',
        description: 'Professional pruning of trees and landscaping',
        category: 'LANDSCAPING',
        frequency: 'ANNUAL',
        seasonalTiming: 'SPRING',
        priority: 'LOW',
        estimatedCost: 400,
        sourceSystem: 'Landscaping',
      },

      // ========== SAFETY ==========
      {
        title: 'Smoke & CO Detector Test',
        description:
          'Test all smoke and carbon monoxide detectors, replace batteries',
        category: 'SAFETY',
        frequency: 'SEMI_ANNUAL',
        seasonalTiming: 'ANY',
        priority: 'HIGH',
        estimatedCost: 0,
        sourceSystem: 'Safety',
      },
      {
        title: 'Fire Extinguisher Check',
        description: 'Inspect fire extinguishers, replace if needed',
        category: 'SAFETY',
        frequency: 'ANNUAL',
        seasonalTiming: 'ANY',
        priority: 'MEDIUM',
        estimatedCost: 50,
        sourceSystem: 'Safety',
      },

      // ========== PLUMBING ==========
      {
        title: 'Water Heater Flush',
        description: 'Drain and flush water heater to remove sediment',
        category: 'PLUMBING',
        frequency: 'ANNUAL',
        seasonalTiming: 'ANY',
        priority: 'MEDIUM',
        estimatedCost: 100,
        sourceSystem: 'Plumbing',
      },
      {
        title: 'Water Heater Inspection',
        description: 'Check anode rod, inspect for leaks and corrosion',
        category: 'PLUMBING',
        frequency: 'ANNUAL',
        seasonalTiming: 'ANY',
        priority: 'MEDIUM',
        estimatedCost: 100,
        sourceSystem: 'Plumbing',
        condition: (e) => {
          // Especially important for older homes
          const age = e.yearBuilt
            ? new Date().getFullYear() - e.yearBuilt
            : 0;
          return age > 10;
        },
      },

      // ========== SEASONAL (NORTHEAST) ==========
      {
        title: 'Winterization Checklist',
        description:
          'Disconnect hoses, insulate pipes, check weatherstripping, reverse ceiling fans',
        category: 'SEASONAL',
        frequency: 'ANNUAL',
        seasonalTiming: 'FALL',
        priority: 'HIGH',
        estimatedCost: 0,
        sourceSystem: 'Seasonal',
        condition: () => isNortheast,
      },
      {
        title: 'Spring Home Checklist',
        description:
          'Inspect roof after winter, check foundation, clean AC condenser, inspect deck/patio',
        category: 'SEASONAL',
        frequency: 'ANNUAL',
        seasonalTiming: 'SPRING',
        priority: 'MEDIUM',
        estimatedCost: 0,
        sourceSystem: 'Seasonal',
      },

      // ========== APPLIANCES ==========
      {
        title: 'Dryer Vent Cleaning',
        description:
          'Clean dryer vent to prevent fire hazard and improve efficiency',
        category: 'APPLIANCES',
        frequency: 'ANNUAL',
        seasonalTiming: 'ANY',
        priority: 'HIGH',
        estimatedCost: 100,
        sourceSystem: 'Appliances',
      },
      {
        title: 'Refrigerator Coil Cleaning',
        description: 'Clean condenser coils for energy efficiency',
        category: 'APPLIANCES',
        frequency: 'ANNUAL',
        seasonalTiming: 'ANY',
        priority: 'LOW',
        estimatedCost: 0,
        sourceSystem: 'Appliances',
      },

      // ========== GARAGE ==========
      {
        title: 'Garage Door Service',
        description: 'Lubricate tracks and springs, test safety features',
        category: 'EXTERIOR',
        frequency: 'ANNUAL',
        seasonalTiming: 'ANY',
        priority: 'MEDIUM',
        estimatedCost: 100,
        sourceSystem: 'Garage',
        condition: (e) => !!e.garageType && e.garageType !== 'None',
      },
    ];
  }

  /**
   * Calculate next due date based on frequency and seasonal timing
   */
  private calculateNextDueDate(
    frequency: MaintenanceFrequency,
    seasonalTiming: SeasonalTiming | undefined,
    from: Date,
  ): Date {
    const now = new Date(from);

    // If seasonal, find the next occurrence of that season
    if (seasonalTiming && seasonalTiming !== 'ANY') {
      return this.getNextSeasonDate(seasonalTiming, now);
    }

    // Otherwise, calculate based on frequency
    switch (frequency) {
      case 'MONTHLY':
        now.setMonth(now.getMonth() + 1);
        break;
      case 'QUARTERLY':
        now.setMonth(now.getMonth() + 3);
        break;
      case 'SEMI_ANNUAL':
      case 'SEMIANNUALLY':
        now.setMonth(now.getMonth() + 6);
        break;
      case 'ANNUAL':
      case 'ANNUALLY':
        now.setFullYear(now.getFullYear() + 1);
        break;
      case 'BIENNIAL':
        now.setFullYear(now.getFullYear() + 2);
        break;
      case 'TRIENNIAL':
        now.setFullYear(now.getFullYear() + 3);
        break;
      default:
        // ONE_TIME or AS_NEEDED - no specific due date
        break;
    }

    return now;
  }

  /**
   * Get the next date for a specific season
   */
  private getNextSeasonDate(season: SeasonalTiming, from: Date): Date {
    const year = from.getFullYear();
    const month = from.getMonth();

    // Season start months (approximate)
    const seasonMonths = {
      SPRING: 3, // April
      SUMMER: 6, // July
      FALL: 9, // October
      WINTER: 0, // January
    };

    let targetMonth = seasonMonths[season as keyof typeof seasonMonths];
    let targetYear = year;

    // If we're past this season, schedule for next year
    if (month >= targetMonth + 2) {
      targetYear++;
    }

    return new Date(targetYear, targetMonth, 15); // Mid-month
  }
}
