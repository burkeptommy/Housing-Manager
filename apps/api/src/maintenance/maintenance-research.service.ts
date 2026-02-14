import { Injectable, Logger } from '@nestjs/common';
import Anthropic from '@anthropic-ai/sdk';
import { PrismaService } from '../prisma/prisma.service';
import {
  MaintenanceCategory,
  MaintenanceFrequency,
  SeasonalTiming,
  TaskPriority,
  HomeSystemType,
} from '@prisma/client';

interface SystemInput {
  name: string;
  type?: HomeSystemType | string;
  category?: string;
  brand?: string;
  model?: string;
  modelNumber?: string;
  serialNumber?: string;
  installedDate?: Date;
  location?: string;
  fuelType?: string;
  capacity?: string;
  notes?: string;
}

interface ResearchedTask {
  title: string;
  description: string;
  category: string;
  frequency: string;
  seasonalTiming?: string;
  priority: string;
  estimatedCost?: number;
  estimatedDurationMinutes?: number;
  diyDifficulty?: 'EASY' | 'MODERATE' | 'PROFESSIONAL_REQUIRED';
  vendorType?: string;
  warningSignsToWatch?: string[];
  safetyNotes?: string;
}

interface ResearchResult {
  systemSummary: string;
  expectedLifespan?: string;
  warrantyTypical?: string;
  tasks: ResearchedTask[];
  vendorTypesNeeded: string[];
  annualMaintenanceBudget?: number;
  relatedSystems?: string[];
  efficiencyTips?: string[];
  commonProblems?: string[];
  whenToReplace?: string[];
}

@Injectable()
export class MaintenanceResearchService {
  private readonly logger = new Logger(MaintenanceResearchService.name);
  private anthropic: Anthropic;

  constructor(private prisma: PrismaService) {
    this.anthropic = new Anthropic({
      apiKey: process.env.ANTHROPIC_API_KEY,
    });
  }

  /**
   * Research maintenance requirements for ANY home system or appliance
   */
  async researchSystem(input: SystemInput, region?: string): Promise<ResearchResult> {
    const prompt = this.buildResearchPrompt(input, region);

    try {
      const response = await this.anthropic.messages.create({
        model: 'claude-sonnet-4-20250514',
        max_tokens: 4096,
        system: `You are a home maintenance expert with deep knowledge of all home systems, appliances, and equipment. Your job is to research and provide comprehensive maintenance schedules for any item in a home.

You have expertise in:
- HVAC systems (furnaces, boilers, heat pumps, AC units, mini-splits)
- Plumbing (water heaters, well systems, septic systems, water softeners, filtration)
- Fuel systems (oil tanks, propane tanks, natural gas)
- Electrical (panels, generators, solar, battery storage)
- Roofing and exterior (roofs, gutters, chimneys, siding, decks)
- Appliances (all kitchen and laundry appliances)
- Safety systems (smoke/CO detectors, fire extinguishers, security)
- Outdoor equipment (pools, irrigation, lawn equipment)
- Vehicles and recreational equipment

When given a specific brand and model, use your knowledge of that manufacturer's recommendations.
When given just a system type, provide industry-standard maintenance schedules.

Always consider:
- Regional factors (Northeast winters, hurricane zones, etc.)
- Safety-critical tasks (always HIGH priority)
- Cost-saving preventive maintenance
- DIY vs professional requirements
- Seasonal timing for optimal service

Respond with ONLY valid JSON. No markdown, no explanation.`,
        messages: [{ role: 'user', content: prompt }],
      });

      const content = response.content[0];
      if (content.type !== 'text') {
        throw new Error('Unexpected response type');
      }

      const jsonMatch = content.text.match(/\{[\s\S]*\}/);
      if (!jsonMatch) {
        throw new Error('No JSON found in response');
      }

      return JSON.parse(jsonMatch[0]) as ResearchResult;
    } catch (error) {
      this.logger.error('Failed to research system:', error);
      // Return a minimal result on error
      return {
        systemSummary: `${input.name} - maintenance research pending`,
        tasks: [],
        vendorTypesNeeded: [],
      };
    }
  }

  private buildResearchPrompt(input: SystemInput, region?: string): string {
    let prompt = `Research the maintenance requirements for this home system/appliance:\n\n`;

    prompt += `**Item:** ${input.name}\n`;
    if (input.type) prompt += `**Type:** ${input.type}\n`;
    if (input.brand) prompt += `**Brand:** ${input.brand}\n`;
    if (input.model) prompt += `**Model:** ${input.model}\n`;
    if (input.modelNumber) prompt += `**Model Number:** ${input.modelNumber}\n`;
    if (input.fuelType) prompt += `**Fuel Type:** ${input.fuelType}\n`;
    if (input.capacity) prompt += `**Capacity:** ${input.capacity}\n`;
    if (input.installedDate) prompt += `**Installed:** ${input.installedDate.toISOString().split('T')[0]}\n`;
    if (input.location) prompt += `**Location in home:** ${input.location}\n`;
    if (input.notes) prompt += `**Additional notes:** ${input.notes}\n`;
    if (region) prompt += `**Region:** ${region}\n`;

    prompt += `
Return a JSON object with this structure:
{
  "systemSummary": "Brief description of this system and its importance",
  "expectedLifespan": "Typical lifespan (e.g., '15-20 years')",
  "warrantyTypical": "Typical warranty period",
  "tasks": [
    {
      "title": "Task name",
      "description": "Detailed description of what to do and why",
      "category": "HVAC|PLUMBING|ELECTRICAL|ROOFING|SEPTIC|POOL|SAFETY|APPLIANCES|EXTERIOR|LANDSCAPING|GENERAL",
      "frequency": "MONTHLY|QUARTERLY|SEMI_ANNUAL|ANNUAL|BIENNIAL|TRIENNIAL|AS_NEEDED",
      "seasonalTiming": "SPRING|SUMMER|FALL|WINTER|ANY",
      "priority": "LOW|MEDIUM|HIGH|URGENT",
      "estimatedCost": 150,
      "estimatedDurationMinutes": 60,
      "diyDifficulty": "EASY|MODERATE|PROFESSIONAL_REQUIRED",
      "vendorType": "Type of professional needed if not DIY",
      "warningSignsToWatch": ["Signs that indicate this task is overdue"],
      "safetyNotes": "Any safety considerations"
    }
  ],
  "vendorTypesNeeded": ["HVAC Technician", "Plumber", etc.],
  "annualMaintenanceBudget": 500,
  "relatedSystems": ["Other systems that work with this one"],
  "efficiencyTips": ["Tips to maximize efficiency and lifespan"],
  "commonProblems": ["Common issues to watch for"],
  "whenToReplace": ["Signs it's time to replace rather than repair"]
}

Be comprehensive - include ALL recommended maintenance tasks for this specific item.
If a model number is provided, be specific to that model's requirements.
Include both DIY tasks and professional service requirements.
Consider seasonal timing appropriate for the region.`;

    return prompt;
  }

  /**
   * Create maintenance tasks from research results
   */
  async createTasksFromResearch(
    householdId: string,
    systemId: string,
    systemName: string,
    research: ResearchResult,
  ): Promise<number> {
    let created = 0;
    const now = new Date();

    // Look up the system to get install date and last service date
    const system = await this.prisma.homeSystem.findUnique({
      where: { id: systemId },
      select: { installedDate: true, lastServiceDate: true },
    });

    // Use last service date or install date as baseline for scheduling
    // This ensures tasks are calculated from when things were actually last serviced
    const baselineDate = system?.lastServiceDate || system?.installedDate || now;

    for (const task of research.tasks) {
      // Check if task already exists
      const existing = await this.prisma.maintenanceTask.findFirst({
        where: {
          householdId,
          homeSystemId: systemId,
          title: task.title,
        },
      });

      if (existing) continue;

      // Calculate next due date based on frequency, season, and when system was last serviced
      let nextDueDate = this.calculateNextDueDate(
        task.frequency as MaintenanceFrequency,
        task.seasonalTiming as SeasonalTiming,
        baselineDate,
      );

      // If the calculated date is in the past (system overdue), set to soon from now
      if (nextDueDate < now) {
        // Overdue - schedule within the next 30 days
        nextDueDate = new Date(now);
        nextDueDate.setDate(nextDueDate.getDate() + 14);
      }

      await this.prisma.maintenanceTask.create({
        data: {
          householdId,
          homeSystemId: systemId,
          title: task.title,
          description: task.description,
          category: this.mapCategory(task.category),
          frequency: this.mapFrequency(task.frequency),
          seasonalTiming: this.mapSeasonalTiming(task.seasonalTiming),
          nextDueDate,
          dueDate: nextDueDate,
          priority: task.priority as TaskPriority,
          estimatedCost: task.estimatedCost,
          source: 'SYSTEM_GENERATED',
          sourceSystem: systemName,
          isRecurring: task.frequency !== 'AS_NEEDED',
          status: 'UPCOMING',
          notes: this.buildTaskNotes(task),
        },
      });

      created++;
    }

    this.logger.log(
      `Created ${created} maintenance tasks for system ${systemName}`,
    );
    return created;
  }

  private mapCategory(category: string): MaintenanceCategory {
    const mapping: Record<string, MaintenanceCategory> = {
      HVAC: 'HVAC',
      PLUMBING: 'PLUMBING',
      ELECTRICAL: 'ELECTRICAL',
      ROOFING: 'ROOFING',
      ROOF_GUTTER: 'ROOF_GUTTER',
      SEPTIC: 'SEPTIC',
      POOL: 'POOL',
      SAFETY: 'SAFETY',
      APPLIANCES: 'APPLIANCES',
      EXTERIOR: 'EXTERIOR',
      INTERIOR: 'INTERIOR',
      LANDSCAPING: 'LANDSCAPING',
      CHIMNEY: 'CHIMNEY',
      PEST: 'PEST',
      CLEANING: 'CLEANING',
      SEASONAL: 'SEASONAL',
      GENERAL: 'GENERAL',
    };
    return mapping[category] || 'OTHER';
  }

  private mapFrequency(frequency: string): MaintenanceFrequency {
    const mapping: Record<string, MaintenanceFrequency> = {
      MONTHLY: 'MONTHLY',
      QUARTERLY: 'QUARTERLY',
      SEMI_ANNUAL: 'SEMIANNUALLY',
      SEMIANNUALLY: 'SEMIANNUALLY',
      ANNUAL: 'ANNUALLY',
      ANNUALLY: 'ANNUALLY',
      BIENNIAL: 'ANNUALLY', // Fallback - we'll handle in due date calculation
      TRIENNIAL: 'ANNUALLY', // Fallback
      AS_NEEDED: 'AS_NEEDED',
    };
    return mapping[frequency] || 'ANNUALLY';
  }

  private mapSeasonalTiming(timing?: string): SeasonalTiming {
    if (!timing) return 'ANY';
    const mapping: Record<string, SeasonalTiming> = {
      SPRING: 'SPRING',
      SUMMER: 'SUMMER',
      FALL: 'FALL',
      WINTER: 'WINTER',
      ANY: 'ANY',
    };
    return mapping[timing] || 'ANY';
  }

  private buildTaskNotes(task: ResearchedTask): string {
    const notes: string[] = [];

    if (task.diyDifficulty) {
      notes.push(`DIY Difficulty: ${task.diyDifficulty}`);
    }
    if (task.vendorType) {
      notes.push(`Vendor needed: ${task.vendorType}`);
    }
    if (task.estimatedDurationMinutes) {
      notes.push(`Estimated time: ${task.estimatedDurationMinutes} minutes`);
    }
    if (task.warningSignsToWatch?.length) {
      notes.push(`Warning signs: ${task.warningSignsToWatch.join(', ')}`);
    }
    if (task.safetyNotes) {
      notes.push(`Safety: ${task.safetyNotes}`);
    }

    return notes.join('\n');
  }

  private calculateNextDueDate(
    frequency: MaintenanceFrequency | string,
    seasonalTiming: SeasonalTiming | undefined,
    now: Date,
  ): Date {
    // If seasonal, calculate based on season
    if (seasonalTiming && seasonalTiming !== 'ANY') {
      return this.getNextSeasonalDate(seasonalTiming, now);
    }

    // Otherwise calculate based on frequency
    const result = new Date(now);

    switch (frequency) {
      case 'MONTHLY':
        result.setMonth(result.getMonth() + 1);
        break;
      case 'QUARTERLY':
        result.setMonth(result.getMonth() + 3);
        break;
      case 'SEMI_ANNUAL':
      case 'SEMIANNUALLY':
        result.setMonth(result.getMonth() + 6);
        break;
      case 'ANNUAL':
      case 'ANNUALLY':
        result.setFullYear(result.getFullYear() + 1);
        break;
      case 'BIENNIAL':
        result.setFullYear(result.getFullYear() + 2);
        break;
      case 'TRIENNIAL':
        result.setFullYear(result.getFullYear() + 3);
        break;
      default:
        result.setMonth(result.getMonth() + 12); // Default to annual
    }

    return result;
  }

  private getNextSeasonalDate(season: SeasonalTiming, now: Date): Date {
    const year = now.getFullYear();
    const month = now.getMonth();

    // Define season start months (aligned with maintenance-generator.service.ts)
    const seasonMonths: Record<SeasonalTiming, number> = {
      SPRING: 3, // April
      SUMMER: 6, // July
      FALL: 9, // October
      WINTER: 0, // January
      ANY: month,
    };

    const targetMonth = seasonMonths[season];
    let targetYear = year;

    // If we've passed this season's window, schedule for next year
    if (month >= targetMonth + 2) {
      targetYear++;
    }

    return new Date(targetYear, targetMonth, 15); // Mid-month
  }

  /**
   * Research and create complete maintenance program for a system
   */
  async createMaintenanceProgram(
    householdId: string,
    input: SystemInput,
    region?: string,
  ): Promise<{
    system: any;
    research: ResearchResult;
    tasksCreated: number;
  }> {
    // 1. Research the system
    this.logger.log(`Researching maintenance for: ${input.name}`);
    const research = await this.researchSystem(input, region);

    // 2. Infer system type
    const systemType = this.inferSystemType(input);

    // 3. Check if system already exists
    let system = await this.prisma.homeSystem.findFirst({
      where: {
        householdId,
        name: input.name,
      },
    });

    if (!system) {
      // Create the system
      system = await this.prisma.homeSystem.create({
        data: {
          householdId,
          name: input.name,
          type: systemType,
          brand: input.brand,
          model: input.model,
          modelNumber: input.modelNumber,
          serialNumber: input.serialNumber,
          installedDate: input.installedDate,
          location: input.location,
          notes: `${research.systemSummary}\n\nExpected lifespan: ${research.expectedLifespan || 'Unknown'}\nTypical warranty: ${research.warrantyTypical || 'Unknown'}`,
          maintenanceNotes: JSON.stringify({
            researchedAt: new Date().toISOString(),
            annualBudget: research.annualMaintenanceBudget,
            vendorTypesNeeded: research.vendorTypesNeeded,
            efficiencyTips: research.efficiencyTips,
            commonProblems: research.commonProblems,
            whenToReplace: research.whenToReplace,
          }),
        },
      });
    } else {
      // Update existing system with research data
      await this.prisma.homeSystem.update({
        where: { id: system.id },
        data: {
          maintenanceNotes: JSON.stringify({
            researchedAt: new Date().toISOString(),
            annualBudget: research.annualMaintenanceBudget,
            vendorTypesNeeded: research.vendorTypesNeeded,
            efficiencyTips: research.efficiencyTips,
            commonProblems: research.commonProblems,
            whenToReplace: research.whenToReplace,
          }),
        },
      });
    }

    // 4. Create maintenance tasks
    const tasksCreated = await this.createTasksFromResearch(
      householdId,
      system.id,
      input.name,
      research,
    );

    // 5. Generate SystemForecast record for replacement planning
    await this.generateForecastForSystem(householdId, system, research, input);

    return { system, research, tasksCreated };
  }

  /**
   * Generate a SystemForecast record for a home system based on research data
   */
  private async generateForecastForSystem(
    householdId: string,
    system: { id: string; installedDate: Date | null; name: string; type: HomeSystemType },
    research: ResearchResult,
    input: SystemInput,
  ) {
    try {
      // Parse lifespan from research (e.g., "15-20 years")
      let typicalLifespan = 20;
      let lifespanMin = 15;
      let lifespanMax = 25;

      if (research.expectedLifespan) {
        const match = research.expectedLifespan.match(/(\d+)\s*[-–to]+\s*(\d+)/);
        if (match) {
          lifespanMin = parseInt(match[1], 10);
          lifespanMax = parseInt(match[2], 10);
          typicalLifespan = Math.round((lifespanMin + lifespanMax) / 2);
        } else {
          const singleMatch = research.expectedLifespan.match(/(\d+)/);
          if (singleMatch) {
            typicalLifespan = parseInt(singleMatch[1], 10);
            lifespanMin = Math.round(typicalLifespan * 0.75);
            lifespanMax = Math.round(typicalLifespan * 1.25);
          }
        }
      }

      const currentYear = new Date().getFullYear();
      const installYear = system.installedDate
        ? new Date(system.installedDate).getFullYear()
        : input.installedDate
          ? new Date(input.installedDate).getFullYear()
          : currentYear;

      const currentAge = currentYear - installYear;
      const expectedReplacementYear = installYear + typicalLifespan;
      const remainingYears = expectedReplacementYear - currentYear;

      let urgency = 'LOW';
      if (remainingYears <= 0) urgency = 'CRITICAL';
      else if (remainingYears <= 2) urgency = 'HIGH';
      else if (remainingYears <= 5) urgency = 'MEDIUM';

      // Check if forecast already exists for this system
      const existing = await this.prisma.systemForecast.findFirst({
        where: { householdId, systemId: system.id },
      });

      const forecastData = {
        systemType: system.type,
        systemName: system.name || input.name,
        installYear,
        currentAge,
        typicalLifespan,
        lifespanMin,
        lifespanMax,
        estimatedReplacementCost: research.annualMaintenanceBudget
          ? research.annualMaintenanceBudget * typicalLifespan * 0.5
          : undefined,
        expectedReplacementYear,
        urgency,
      };

      if (existing) {
        await this.prisma.systemForecast.update({
          where: { id: existing.id },
          data: forecastData,
        });
      } else {
        await this.prisma.systemForecast.create({
          data: {
            householdId,
            systemId: system.id,
            ...forecastData,
          },
        });
      }

      this.logger.log(
        `Generated forecast for ${system.name}: replacement in ~${remainingYears} years (urgency: ${urgency})`,
      );
    } catch (error) {
      this.logger.error(`Failed to generate forecast for ${system.name}:`, error);
      // Non-fatal - don't break the maintenance program creation
    }
  }

  private inferSystemType(input: SystemInput): HomeSystemType {
    // If type is explicitly provided and valid, use it
    if (input.type && Object.values(HomeSystemType).includes(input.type as HomeSystemType)) {
      return input.type as HomeSystemType;
    }

    const name = (input.name + ' ' + (input.type || '')).toLowerCase();

    // HVAC
    if (/furnace|heating|heater(?!.*water)/i.test(name)) return HomeSystemType.FURNACE;
    if (/air\s*condition|ac\s|a\/c|cooling/i.test(name)) return HomeSystemType.AIR_CONDITIONER;
    if (/heat\s*pump/i.test(name)) return HomeSystemType.HEAT_PUMP;
    if (/boiler/i.test(name)) return HomeSystemType.BOILER;
    if (/thermostat|nest|ecobee/i.test(name)) return HomeSystemType.THERMOSTAT;
    if (/mini.*split|ductless/i.test(name)) return HomeSystemType.MINI_SPLIT;

    // Fuel Storage
    if (/oil\s*tank/i.test(name)) return HomeSystemType.OIL_TANK;
    if (/propane\s*tank/i.test(name)) return HomeSystemType.PROPANE_TANK;

    // Water
    if (/water\s*heater|hot\s*water/i.test(name)) return HomeSystemType.WATER_HEATER;
    if (/water\s*soften/i.test(name)) return HomeSystemType.WATER_SOFTENER;
    if (/well\s*pump/i.test(name)) return HomeSystemType.WELL_PUMP;
    if (/well\s*water|well\s*system/i.test(name)) return HomeSystemType.WELL_SYSTEM;
    if (/sump/i.test(name)) return HomeSystemType.SUMP_PUMP;
    if (/water\s*filter|filtration|reverse\s*osmosis/i.test(name)) return HomeSystemType.WATER_FILTRATION;
    if (/septic\s*system/i.test(name)) return HomeSystemType.SEPTIC_SYSTEM;
    if (/septic\s*tank/i.test(name)) return HomeSystemType.SEPTIC_TANK;

    // Energy
    if (/electric.*panel|breaker|fuse/i.test(name)) return HomeSystemType.ELECTRICAL_PANEL;
    if (/generator/i.test(name)) return HomeSystemType.GENERATOR;
    if (/solar/i.test(name)) return HomeSystemType.SOLAR_PANELS;
    if (/battery.*storage|powerwall/i.test(name)) return HomeSystemType.BATTERY_STORAGE;
    if (/ev\s*charger|electric.*vehicle.*charger|tesla\s*charger/i.test(name)) return HomeSystemType.EV_CHARGER;

    // Kitchen
    if (/refrigerat|fridge/i.test(name)) return HomeSystemType.REFRIGERATOR;
    if (/dishwash/i.test(name)) return HomeSystemType.DISHWASHER;
    if (/oven|range|stove|cooktop/i.test(name)) return HomeSystemType.OVEN_RANGE;
    if (/microwave/i.test(name)) return HomeSystemType.MICROWAVE;
    if (/garbage\s*disposal|disposer/i.test(name)) return HomeSystemType.GARBAGE_DISPOSAL;
    if (/range\s*hood|exhaust.*hood/i.test(name)) return HomeSystemType.RANGE_HOOD;
    if (/ice\s*maker/i.test(name)) return HomeSystemType.ICE_MAKER;
    if (/wine\s*cooler|wine\s*fridge/i.test(name)) return HomeSystemType.WINE_COOLER;

    // Laundry
    if (/washer|washing\s*machine/i.test(name)) return HomeSystemType.WASHER;
    if (/dryer/i.test(name)) return HomeSystemType.DRYER;

    // Outdoor
    if (/irrigat|sprinkler/i.test(name)) return HomeSystemType.IRRIGATION_SYSTEM;
    if (/pool\s*heat/i.test(name)) return HomeSystemType.POOL_HEATER;
    if (/pool/i.test(name)) return HomeSystemType.POOL_EQUIPMENT;
    if (/hot\s*tub|spa|jacuzzi/i.test(name)) return HomeSystemType.HOT_TUB;
    if (/mower|lawn.*mower/i.test(name)) return HomeSystemType.LAWN_MOWER;
    if (/snow\s*blow/i.test(name)) return HomeSystemType.SNOW_BLOWER;

    // Safety
    if (/smoke/i.test(name)) return HomeSystemType.SMOKE_DETECTOR;
    if (/co\s*detect|carbon\s*monox/i.test(name)) return HomeSystemType.CO_DETECTOR;
    if (/security|alarm/i.test(name)) return HomeSystemType.SECURITY_SYSTEM;
    if (/fire\s*extinguish/i.test(name)) return HomeSystemType.FIRE_EXTINGUISHER;
    if (/sprinkler\s*system|fire\s*sprinkler/i.test(name)) return HomeSystemType.FIRE_SPRINKLER;
    if (/radon/i.test(name)) return HomeSystemType.RADON_SYSTEM;

    // Structural
    if (/roof/i.test(name)) return HomeSystemType.ROOF;
    if (/gutter/i.test(name)) return HomeSystemType.GUTTERS;
    if (/chimney/i.test(name)) return HomeSystemType.CHIMNEY;
    if (/deck|patio/i.test(name)) return HomeSystemType.DECK;
    if (/fence/i.test(name)) return HomeSystemType.FENCE;
    if (/driveway/i.test(name)) return HomeSystemType.DRIVEWAY;
    if (/exterior\s*paint|house\s*paint/i.test(name)) return HomeSystemType.EXTERIOR_PAINT;
    if (/window/i.test(name)) return HomeSystemType.WINDOWS;

    // Other
    if (/garage.*door/i.test(name)) return HomeSystemType.GARAGE_DOOR_OPENER;
    if (/ceiling\s*fan/i.test(name)) return HomeSystemType.CEILING_FAN;
    if (/fireplace/i.test(name)) return HomeSystemType.FIREPLACE;
    if (/humidifier/i.test(name)) return HomeSystemType.HUMIDIFIER;
    if (/dehumidifier/i.test(name)) return HomeSystemType.DEHUMIDIFIER;
    if (/air\s*purifier/i.test(name)) return HomeSystemType.AIR_PURIFIER;
    if (/attic\s*fan/i.test(name)) return HomeSystemType.ATTIC_FAN;
    if (/whole\s*house\s*fan/i.test(name)) return HomeSystemType.WHOLE_HOUSE_FAN;
    if (/central\s*vacuum/i.test(name)) return HomeSystemType.CENTRAL_VACUUM;
    if (/intercom/i.test(name)) return HomeSystemType.INTERCOM;
    if (/home\s*theater/i.test(name)) return HomeSystemType.HOME_THEATER;

    return HomeSystemType.OTHER;
  }
}
