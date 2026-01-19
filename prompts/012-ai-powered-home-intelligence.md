# Prompt 012: AI-Powered Home Intelligence System

## Overview

Build a comprehensive AI-powered system that automatically researches and creates maintenance programs for ANY home system, appliance, or item added to Haven. When a user says "I have well water" or "I have a Carrier 59MN7 furnace", Alfred should research that specific item and create a complete maintenance program with tasks, reminders, vendor recommendations, and budget estimates.

This also includes comprehensive bill detection - the system should identify ALL possible household bills from bank transactions.

## Goals

1. **AI Maintenance Research** - When any system/appliance is added, use Claude to research and create appropriate maintenance tasks
2. **Model-Specific Intelligence** - If a model number is provided, look up that specific model's requirements
3. **Proactive Task Generation** - Auto-create all relevant tasks with proper frequencies and seasonal timing
4. **Comprehensive Bill Detection** - Identify every possible household bill from Plaid transactions
5. **Vendor Suggestions** - Recommend types of vendors needed for each system
6. **Budget Estimation** - Provide typical maintenance costs

## Part 1: AI Maintenance Research Service

### Create: `apps/api/src/maintenance/maintenance-research.service.ts`

```typescript
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
  location?: string; // Zone name
  fuelType?: string; // For HVAC: oil, gas, propane, electric
  capacity?: string; // Tank size, BTU, tons, etc.
  notes?: string;
}

interface ResearchedTask {
  title: string;
  description: string;
  category: string;
  frequency: string; // MONTHLY, QUARTERLY, SEMI_ANNUAL, ANNUAL, BIENNIAL, TRIENNIAL, AS_NEEDED
  seasonalTiming?: string; // SPRING, SUMMER, FALL, WINTER, ANY
  priority: string; // LOW, MEDIUM, HIGH, URGENT
  estimatedCost?: number;
  estimatedDurationMinutes?: number;
  diyDifficulty?: 'EASY' | 'MODERATE' | 'PROFESSIONAL_REQUIRED';
  vendorType?: string; // Type of vendor needed (plumber, HVAC tech, etc.)
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
  relatedSystems?: string[]; // Other systems that often need attention with this one
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

      // Calculate next due date based on frequency and season
      const nextDueDate = this.calculateNextDueDate(
        task.frequency as MaintenanceFrequency,
        task.seasonalTiming as SeasonalTiming,
        now,
      );

      await this.prisma.maintenanceTask.create({
        data: {
          householdId,
          homeSystemId: systemId,
          title: task.title,
          description: task.description,
          category: this.mapCategory(task.category),
          frequency: task.frequency as MaintenanceFrequency,
          seasonalTiming: (task.seasonalTiming as SeasonalTiming) || 'ANY',
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
    frequency: MaintenanceFrequency,
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
    
    // Define season start months (approximate)
    const seasonMonths: Record<SeasonalTiming, number> = {
      SPRING: 3, // April
      SUMMER: 5, // June
      FALL: 8,   // September
      WINTER: 11, // December
      ANY: month,
    };

    const targetMonth = seasonMonths[season];
    let targetYear = year;

    // If we've passed this season, schedule for next year
    if (month >= targetMonth) {
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

    // 2. Create or update the home system record
    const systemType = this.inferSystemType(input);
    
    let system = await this.prisma.homeSystem.findFirst({
      where: {
        householdId,
        name: input.name,
      },
    });

    if (!system) {
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
        },
      });
    }

    // 3. Create maintenance tasks
    const tasksCreated = await this.createTasksFromResearch(
      householdId,
      system.id,
      input.name,
      research,
    );

    // 4. Store research results for reference
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

    return { system, research, tasksCreated };
  }

  private inferSystemType(input: SystemInput): HomeSystemType {
    const name = (input.name + ' ' + (input.type || '')).toLowerCase();

    // HVAC
    if (/furnace|heating|heater(?!.*water)/i.test(name)) return 'FURNACE';
    if (/air\s*condition|ac\s|a\/c|cooling/i.test(name)) return 'AIR_CONDITIONER';
    if (/heat\s*pump/i.test(name)) return 'HEAT_PUMP';
    if (/boiler/i.test(name)) return 'BOILER';
    if (/thermostat|nest|ecobee/i.test(name)) return 'THERMOSTAT';

    // Water
    if (/water\s*heater|hot\s*water/i.test(name)) return 'WATER_HEATER';
    if (/water\s*soften/i.test(name)) return 'WATER_SOFTENER';
    if (/well|well\s*pump/i.test(name)) return 'WELL_PUMP';
    if (/sump/i.test(name)) return 'SUMP_PUMP';

    // Energy
    if (/electric.*panel|breaker|fuse/i.test(name)) return 'ELECTRICAL_PANEL';
    if (/generator/i.test(name)) return 'GENERATOR';
    if (/solar/i.test(name)) return 'SOLAR_PANELS';
    if (/battery.*storage|powerwall/i.test(name)) return 'BATTERY_STORAGE';

    // Kitchen
    if (/refrigerat|fridge/i.test(name)) return 'REFRIGERATOR';
    if (/dishwash/i.test(name)) return 'DISHWASHER';
    if (/oven|range|stove|cooktop/i.test(name)) return 'OVEN_RANGE';
    if (/microwave/i.test(name)) return 'MICROWAVE';
    if (/garbage\s*disposal|disposer/i.test(name)) return 'GARBAGE_DISPOSAL';

    // Laundry
    if (/washer|washing\s*machine/i.test(name)) return 'WASHER';
    if (/dryer/i.test(name)) return 'DRYER';

    // Outdoor
    if (/irrigat|sprinkler/i.test(name)) return 'IRRIGATION_SYSTEM';
    if (/pool/i.test(name)) return 'POOL_EQUIPMENT';
    if (/hot\s*tub|spa|jacuzzi/i.test(name)) return 'HOT_TUB';
    if (/mower|lawn.*mower/i.test(name)) return 'LAWN_MOWER';

    // Safety
    if (/smoke/i.test(name)) return 'SMOKE_DETECTOR';
    if (/co\s*detect|carbon\s*monox/i.test(name)) return 'CO_DETECTOR';
    if (/security|alarm/i.test(name)) return 'SECURITY_SYSTEM';
    if (/fire\s*extinguish/i.test(name)) return 'FIRE_EXTINGUISHER';

    // Other
    if (/garage.*door/i.test(name)) return 'GARAGE_DOOR_OPENER';
    if (/ceiling\s*fan/i.test(name)) return 'CEILING_FAN';
    if (/fireplace/i.test(name)) return 'FIREPLACE';

    return 'OTHER';
  }
}
```

---

## Part 2: Integrate with Alfred Chat

### Update: `apps/api/src/alfred/alfred.service.ts`

Add a new tool for Alfred to use when users mention systems:

```typescript
// Add to the tools array in Alfred service:

{
  name: 'research_and_add_system',
  description: `Research and add a home system, appliance, or equipment with full maintenance program. 
Use this when user mentions they have any home system, appliance, or equipment.
Examples:
- "I have well water" -> research well water system maintenance
- "We have a Carrier 59MN7 furnace" -> research that specific furnace model
- "I have an oil tank" -> research oil tank maintenance
- "We just got a new Samsung refrigerator model RF28R7551SR" -> research that model
- "I have a propane tank" -> research propane system maintenance
- "We have a septic system" -> research septic maintenance
- "I have a Generac generator" -> research generator maintenance
This will create the system AND all recommended maintenance tasks automatically.`,
  input_schema: {
    type: 'object',
    properties: {
      name: {
        type: 'string',
        description: 'Name of the system (e.g., "Well Water System", "Main Furnace", "Kitchen Refrigerator")',
      },
      systemType: {
        type: 'string',
        description: 'Type of system (e.g., "well", "furnace", "refrigerator", "septic", "oil_tank", "propane", "generator", "pool", "hvac", "water_heater")',
      },
      brand: {
        type: 'string',
        description: 'Brand name if known (e.g., "Carrier", "Samsung", "Generac")',
      },
      model: {
        type: 'string',
        description: 'Model name if known',
      },
      modelNumber: {
        type: 'string',
        description: 'Model number if known (e.g., "59MN7", "RF28R7551SR")',
      },
      fuelType: {
        type: 'string',
        description: 'Fuel type for HVAC/heating (oil, natural_gas, propane, electric)',
      },
      capacity: {
        type: 'string',
        description: 'Capacity if relevant (e.g., "275 gallon", "100,000 BTU", "22kW")',
      },
      location: {
        type: 'string',
        description: 'Location in home (e.g., "Basement", "Garage", "Kitchen")',
      },
      installedDate: {
        type: 'string',
        description: 'When installed (ISO date or year)',
      },
      notes: {
        type: 'string',
        description: 'Any additional notes about the system',
      },
    },
    required: ['name', 'systemType'],
  },
},
```

### Tool Handler Implementation:

```typescript
case 'research_and_add_system': {
  const { name, systemType, brand, model, modelNumber, fuelType, capacity, location, installedDate, notes } = toolInput;
  
  // Get household region from address
  const homeProfile = await this.prisma.homeProfile.findUnique({
    where: { householdId },
    select: { state: true },
  });
  
  const result = await this.maintenanceResearchService.createMaintenanceProgram(
    householdId,
    {
      name,
      type: systemType,
      brand,
      model,
      modelNumber,
      fuelType,
      capacity,
      location,
      installedDate: installedDate ? new Date(installedDate) : undefined,
      notes,
    },
    homeProfile?.state,
  );
  
  toolResults.push({
    tool: 'research_and_add_system',
    result: {
      success: true,
      systemId: result.system.id,
      systemName: result.system.name,
      tasksCreated: result.tasksCreated,
      summary: result.research.systemSummary,
      expectedLifespan: result.research.expectedLifespan,
      annualBudget: result.research.annualMaintenanceBudget,
      vendorTypesNeeded: result.research.vendorTypesNeeded,
      tasks: result.research.tasks.map(t => ({
        title: t.title,
        frequency: t.frequency,
        season: t.seasonalTiming,
        estimatedCost: t.estimatedCost,
      })),
    },
  });
  break;
}
```

---

## Part 3: Comprehensive Bill Detection Patterns

### Update: `apps/api/src/plaid/transaction-analyzer.service.ts`

Replace the patterns object with comprehensive detection:

```typescript
// Complete merchant patterns for ALL possible household bills
private patterns: Record<string, RegExp[]> = {
  // ==================== HOUSING ====================
  mortgage: [
    /quicken|rocket\s*mortgage/i,
    /wells\s*fargo.*mtg|wells\s*fargo.*mortgage/i,
    /chase.*mortgage|jpmorgan.*mtg/i,
    /bank\s*of\s*america.*mtg|boa.*mortgage/i,
    /us\s*bank.*mortgage/i,
    /pnc.*mortgage/i,
    /citizens.*mortgage/i,
    /mr\s*cooper/i,
    /pennymac/i,
    /freedom\s*mortgage/i,
    /loancare/i,
    /nationstar/i,
    /caliber\s*home/i,
    /newrez/i,
    /guild\s*mortgage/i,
    /loandepot/i,
    /better\s*mortgage/i,
    /crosscountry/i,
    /homepoint/i,
    /planet\s*home/i,
    /fairway/i,
    /guaranteed\s*rate/i,
    /movement\s*mortgage/i,
    /united\s*wholesale/i,
  ],
  rent: [
    /rent\s*payment/i,
    /apartments\.com/i,
    /zillow.*rent/i,
    /avail.*rent/i,
    /cozy.*rent/i,
    /rentcafe/i,
    /appfolio/i,
    /buildium/i,
    /property.*management/i,
  ],
  hoa: [
    /hoa|homeowner.*assoc/i,
    /condo.*assoc/i,
    /property.*assoc/i,
    /community.*assoc/i,
    /maintenance\s*fee/i,
  ],
  propertyTax: [
    /property\s*tax/i,
    /county\s*tax/i,
    /town\s*of.*tax/i,
    /city\s*of.*tax/i,
    /tax\s*collector/i,
    /assessor/i,
  ],

  // ==================== INSURANCE ====================
  homeInsurance: [
    /state\s*farm/i,
    /allstate/i,
    /geico/i,
    /progressive/i,
    /liberty\s*mutual/i,
    /travelers/i,
    /nationwide/i,
    /farmers\s*ins/i,
    /usaa/i,
    /amica/i,
    /hartford/i,
    /chubb/i,
    /american\s*family/i,
    /erie\s*insurance/i,
    /auto.*owners/i,
    /safeco/i,
    /homesite/i,
    /lemonade/i,
    /hippo/i,
    /branch\s*insurance/i,
  ],
  autoInsurance: [
    /geico.*auto/i,
    /progressive.*auto/i,
    /state\s*farm.*auto/i,
    /allstate.*auto/i,
    /esurance/i,
    /root\s*insurance/i,
    /metromile/i,
  ],
  healthInsurance: [
    /anthem/i,
    /united.*health|uhc|unitedhealthcare/i,
    /cigna/i,
    /aetna/i,
    /kaiser/i,
    /humana/i,
    /bcbs|blue.*cross|blue.*shield/i,
    /oscar.*health/i,
    /centene/i,
    /molina/i,
    /ambetter/i,
    /bright.*health/i,
    /clover.*health/i,
    /devoted.*health/i,
    /medicare/i,
    /medicaid/i,
  ],
  lifeInsurance: [
    /northwestern\s*mutual/i,
    /new\s*york\s*life/i,
    /mass\s*mutual|massmutual/i,
    /prudential.*life/i,
    /metlife/i,
    /lincoln\s*financial/i,
    /principal\s*financial/i,
    /transamerica/i,
    /aflac/i,
    /guardian\s*life/i,
    /haven\s*life/i,
    /ladder.*life/i,
    /bestow/i,
    /ethos\s*life/i,
  ],
  petInsurance: [
    /healthy\s*paws/i,
    /embrace.*pet/i,
    /trupanion/i,
    /nationwide.*pet/i,
    /pets\s*best/i,
    /figo/i,
    /lemonade.*pet/i,
    /spot.*pet/i,
    /pumpkin.*pet/i,
  ],

  // ==================== UTILITIES ====================
  electricity: [
    /eversource/i,
    /united\s*illuminating|^ui\s/i,
    /con\s*edison|coned/i,
    /pseg|pse&g/i,
    /national\s*grid/i,
    /duke\s*energy/i,
    /dominion\s*energy/i,
    /xcel\s*energy/i,
    /aep|american\s*electric/i,
    /southern\s*company/i,
    /entergy/i,
    /firstenergy/i,
    /ppl\s*electric/i,
    /exelon/i,
    /comed/i,
    /peco/i,
    /baltimore\s*gas/i,
    /pg&e|pacific\s*gas/i,
    /sce|socal\s*edison/i,
    /sdge|san\s*diego\s*gas/i,
    /florida\s*power/i,
    /fpl\s/i,
    /georgia\s*power/i,
    /jea\s/i,
    /lakeland\s*electric/i,
    /hawaiian\s*electric/i,
    /puget\s*sound/i,
    /avista/i,
    /rocky\s*mountain\s*power/i,
    /pacificorp/i,
    /consumers\s*energy/i,
    /dte\s*energy/i,
    /centerpoint/i,
    /oncor/i,
    /aes\s*ohio/i,
    /evergy/i,
    /ameren/i,
    /alliant\s*energy/i,
    /we\s*energies/i,
    /madison\s*gas/i,
    /otter\s*tail/i,
    /minnkota/i,
    /oge\s*energy/i,
    /nv\s*energy/i,
    /tucson\s*electric/i,
    /el\s*paso\s*electric/i,
    /pnm\s*resources/i,
    /public\s*service.*nm/i,
    /cleco/i,
    /southwestern\s*electric/i,
    /empire\s*district/i,
    /westar/i,
    /black\s*hills/i,
    /midamerican/i,
  ],
  gas: [
    /eversource.*gas/i,
    /southern\s*ct\s*gas/i,
    /cng|connecticut\s*natural/i,
    /yankee\s*gas/i,
    /atmos\s*energy/i,
    /nicor\s*gas/i,
    /peoples\s*gas/i,
    /spire\s*energy/i,
    /southwest\s*gas/i,
    /washington\s*gas/i,
    /new\s*jersey\s*natural/i,
    /south\s*jersey\s*gas/i,
    /columbia\s*gas/i,
    /centerpoint.*gas/i,
    /piedmont\s*natural/i,
    /northwest\s*natural/i,
    /cascade\s*natural/i,
    /puget.*natural/i,
    /intermountain\s*gas/i,
    /questar\s*gas/i,
    /energen/i,
    /agl\s*resources/i,
    /laclede\s*gas/i,
    /national\s*fuel/i,
    /berkshire\s*gas/i,
    /liberty\s*utilities.*gas/i,
    /unitil.*gas/i,
    /bay\s*state\s*gas/i,
  ],
  water: [
    /aquarion/i,
    /american\s*water/i,
    /ct\s*water|connecticut\s*water/i,
    /aqua\s*america/i,
    /california\s*water/i,
    /san\s*jose\s*water/i,
    /golden\s*state\s*water/i,
    /middlesex\s*water/i,
    /artesian\s*water/i,
    /york\s*water/i,
    /sjw\s*group/i,
    /essential\s*utilities/i,
    /water\s*service/i,
    /water\s*dept/i,
    /municipal\s*water/i,
    /city.*water/i,
    /town.*water/i,
    /water\s*utility/i,
    /water\s*authority/i,
  ],
  sewer: [
    /sewer/i,
    /wastewater/i,
    /sanitation/i,
    /sewerage/i,
  ],
  trash: [
    /waste\s*management/i,
    /republic\s*services/i,
    /waste.*connections/i,
    /casella/i,
    /advanced\s*disposal/i,
    /waste.*industries/i,
    /gfl\s*environmental/i,
    /rumpke/i,
    /waste\s*pro/i,
    /recology/i,
    /town.*trash|town.*waste/i,
    /city.*trash|city.*waste/i,
    /garbage/i,
    /refuse/i,
    /sanitation.*dept/i,
  ],
  oil: [
    /heating\s*oil/i,
    /fuel\s*oil/i,
    /oil\s*delivery/i,
    /petroleum/i,
    /petro\s*home/i,
    /dead\s*river/i,
    /sprague/i,
    /mirabito/i,
    /global\s*partners/i,
    /rymes/i,
    /eastern\s*propane.*oil/i,
    /shipley\s*energy/i,
    /brickman.*oil/i,
    /superior.*oil/i,
    /meenan\s*oil/i,
    /heller.*oil/i,
    /griffith\s*energy/i,
    /foster\s*fuels/i,
    /valley\s*oil/i,
    /bottini\s*fuel/i,
    /main\s*care\s*energy/i,
  ],
  propane: [
    /propane/i,
    /amerigas/i,
    /ferrellgas/i,
    /suburban\s*propane/i,
    /blue\s*rhino/i,
    /paraco/i,
    /thompson\s*gas/i,
    /chs\s*propane/i,
    /eastern\s*propane/i,
    /hocon\s*gas/i,
  ],

  // ==================== TELECOM ====================
  internet: [
    /comcast|xfinity/i,
    /verizon.*fios|fios/i,
    /at&t.*internet|att.*internet/i,
    /spectrum|charter/i,
    /optimum|altice/i,
    /cox\s*communications/i,
    /frontier\s*communications/i,
    /centurylink|lumen/i,
    /windstream/i,
    /mediacom/i,
    /suddenlink/i,
    /wow\s*internet/i,
    /rcn\s/i,
    /astound/i,
    /earthlink/i,
    /hughesnet/i,
    /viasat/i,
    /starlink/i,
    /t-mobile.*home/i,
    /google\s*fiber/i,
    /ziply\s*fiber/i,
    /consolidated\s*communications/i,
    /metronet/i,
    /breezeline/i,
    /atlantic\s*broadband/i,
  ],
  cable: [
    /directv|direct\s*tv/i,
    /dish\s*network/i,
    /youtube\s*tv/i,
    /hulu.*live/i,
    /sling\s*tv/i,
    /fubo/i,
    /philo/i,
  ],
  cellPhone: [
    /t-mobile/i,
    /verizon\s*wireless/i,
    /at&t\s*wireless|att\s*wireless|at&t\s*mobility/i,
    /sprint/i,
    /mint\s*mobile/i,
    /visible/i,
    /google\s*fi/i,
    /us\s*cellular/i,
    /cricket/i,
    /metro\s*by\s*t-mobile|metropcs/i,
    /boost\s*mobile/i,
    /straight\s*talk/i,
    /consumer\s*cellular/i,
    /ting/i,
    /republic\s*wireless/i,
    /xfinity\s*mobile/i,
    /spectrum\s*mobile/i,
  ],
  landline: [
    /landline/i,
    /home\s*phone/i,
    /voip/i,
    /ooma/i,
    /vonage/i,
    /magicjack/i,
  ],

  // ==================== STREAMING & SUBSCRIPTIONS ====================
  streaming: [
    /netflix/i,
    /hulu(?!\s*live)/i,
    /disney.*plus|disney\+/i,
    /hbo.*max|^max\s/i,
    /paramount.*plus|paramount\+/i,
    /peacock/i,
    /apple\s*tv|apple\s*one/i,
    /amazon.*video|prime\s*video/i,
    /discovery.*plus|discovery\+/i,
    /espn.*plus|espn\+/i,
    /showtime/i,
    /starz/i,
    /bet.*plus/i,
    /britbox/i,
    /acorn\s*tv/i,
    /shudder/i,
    /crunchyroll/i,
    /funimation/i,
    /curiosity\s*stream/i,
    /mubi/i,
    /criterion/i,
    /kanopy/i,
    /tubi/i,
    /pluto/i,
  ],
  music: [
    /spotify/i,
    /apple\s*music/i,
    /amazon\s*music/i,
    /youtube\s*music|youtube\s*premium/i,
    /pandora/i,
    /tidal/i,
    /deezer/i,
    /soundcloud/i,
    /audible/i,
    /sirius.*xm/i,
  ],
  gaming: [
    /xbox.*live|xbox.*game\s*pass/i,
    /playstation.*plus|playstation.*now/i,
    /nintendo.*online/i,
    /ea\s*play/i,
    /ubisoft/i,
    /steam/i,
    /epic\s*games/i,
    /humble\s*bundle/i,
  ],
  software: [
    /microsoft\s*365|office\s*365/i,
    /adobe/i,
    /dropbox/i,
    /google\s*one|google\s*workspace/i,
    /icloud/i,
    /evernote/i,
    /notion/i,
    /slack/i,
    /zoom/i,
    /lastpass/i,
    /1password/i,
    /dashlane/i,
    /nordvpn/i,
    /expressvpn/i,
    /norton/i,
    /mcafee/i,
    /malwarebytes/i,
    /grammarly/i,
    /canva/i,
    /squarespace/i,
    /wix/i,
    /shopify/i,
    /quickbooks/i,
    /turbotax/i,
    /intuit/i,
  ],
  news: [
    /new\s*york\s*times|nytimes/i,
    /wall\s*street\s*journal|wsj/i,
    /washington\s*post/i,
    /the\s*athletic/i,
    /bloomberg/i,
    /economist/i,
    /financial\s*times/i,
    /barrons/i,
    /medium/i,
    /substack/i,
    /patreon/i,
  ],
  amazon: [
    /amazon\s*prime(?!\s*video)/i,
    /prime\s*membership/i,
    /amazon\s*fresh/i,
    /whole\s*foods/i,
  ],
  warehouse: [
    /costco/i,
    /sam.*club/i,
    /bj.*wholesale/i,
  ],
  mealKit: [
    /hello\s*fresh/i,
    /blue\s*apron/i,
    /home\s*chef/i,
    /factor/i,
    /freshly/i,
    /daily\s*harvest/i,
    /sunbasket/i,
    /green\s*chef/i,
    /gobble/i,
    /dinnerly/i,
    /every\s*plate/i,
    /hungryroot/i,
    /tovala/i,
    /snap\s*kitchen/i,
  ],
  petFood: [
    /chewy/i,
    /petco/i,
    /petsmart/i,
    /farmer.*dog/i,
    /nom\s*nom/i,
    /ollie/i,
    /just\s*food.*dogs/i,
    /bark\s*box/i,
    /bully\s*sticks/i,
  ],

  // ==================== FITNESS & WELLNESS ====================
  gym: [
    /planet\s*fitness/i,
    /la\s*fitness/i,
    /24\s*hour\s*fitness/i,
    /equinox/i,
    /ymca|ywca/i,
    /orangetheory/i,
    /crossfit/i,
    /lifetime\s*fitness/i,
    /gold.*gym/i,
    /anytime\s*fitness/i,
    /crunch\s*fitness/i,
    /blink\s*fitness/i,
    /esporta/i,
    /retro\s*fitness/i,
    /world\s*gym/i,
    /snap\s*fitness/i,
    /club\s*fitness/i,
    /athletic\s*club/i,
    /soul\s*cycle/i,
    /barry.*bootcamp/i,
    /f45/i,
    /pure\s*barre/i,
    /core\s*power/i,
    /yoga.*works/i,
    /hot.*yoga/i,
    /bikram/i,
  ],
  fitnessApp: [
    /peloton/i,
    /mirror/i,
    /tonal/i,
    /tempo/i,
    /beachbody/i,
    /daily\s*burn/i,
    /aaptiv/i,
    /fitbit\s*premium/i,
    /apple\s*fitness/i,
    /strava/i,
    /calm/i,
    /headspace/i,
    /noom/i,
    /weight\s*watchers|ww\s/i,
  ],
  clubMembership: [
    /country\s*club/i,
    /golf\s*club/i,
    /tennis\s*club/i,
    /swim\s*club/i,
    /beach\s*club/i,
    /yacht\s*club/i,
  ],

  // ==================== VEHICLES ====================
  carPayment: [
    /toyota\s*financial/i,
    /honda\s*financial/i,
    /ford\s*credit/i,
    /ally\s*(auto|financial)/i,
    /capital\s*one\s*auto/i,
    /chase\s*auto/i,
    /bmw\s*financial/i,
    /mercedes.*financial/i,
    /gm\s*financial/i,
    /chrysler\s*capital/i,
    /hyundai\s*motor\s*finance/i,
    /kia\s*finance/i,
    /nissan\s*motor/i,
    /subaru\s*motors\s*finance/i,
    /vw\s*credit|volkswagen\s*credit/i,
    /audi\s*financial/i,
    /porsche\s*financial/i,
    /lexus\s*financial/i,
    /acura\s*financial/i,
    /infiniti\s*financial/i,
    /mazda\s*financial/i,
    /world\s*omni/i,
    /santander.*auto/i,
    /td\s*auto/i,
    /citizens\s*auto/i,
    /pnc\s*auto/i,
    /suntrust.*auto/i,
    /exeter\s*finance/i,
    /westlake\s*financial/i,
    /credit\s*acceptance/i,
    /carmax\s*auto/i,
    /carvana/i,
    /vroom/i,
  ],
  carLease: [
    /lease\s*payment/i,
    /us\s*bank.*lease/i,
    /ally.*lease/i,
  ],
  parking: [
    /parking/i,
    /spothero/i,
    /parkwhiz/i,
    /bestparking/i,
    /parkme/i,
    /garage\s*rent/i,
  ],
  tolls: [
    /ez.*pass|ezpass/i,
    /fastrak/i,
    /sunpass/i,
    /i-pass|ipass/i,
    /k-tag/i,
    /pike\s*pass/i,
    /good\s*to\s*go/i,
    /peach\s*pass/i,
    /txtag/i,
    /toll.*road/i,
    /turnpike/i,
  ],
  carRegistration: [
    /dmv|dept.*motor/i,
    /vehicle\s*registration/i,
    /plate\s*renewal/i,
  ],

  // ==================== LOANS & DEBT ====================
  studentLoan: [
    /nelnet/i,
    /navient/i,
    /mohela/i,
    /aidvantage/i,
    /great\s*lakes/i,
    /fedloan|fed\s*loan/i,
    /dept.*education/i,
    /sallie\s*mae/i,
    /sofi.*student/i,
    /earnest/i,
    /laurel\s*road/i,
    /commonbond/i,
    /elfi/i,
    /lendkey/i,
    /college\s*ave/i,
    /discover.*student/i,
    /citizens.*student/i,
  ],
  personalLoan: [
    /sofi.*personal/i,
    /marcus|goldman.*sachs/i,
    /lightstream/i,
    /upstart/i,
    /prosper/i,
    /lending\s*club/i,
    /best\s*egg/i,
    /payoff/i,
    /avant/i,
    /upgrade/i,
    /happy\s*money/i,
  ],
  heloc: [
    /heloc/i,
    /home\s*equity/i,
    /figure.*heloc/i,
  ],
  creditCard: [
    /chase.*credit|chase.*card/i,
    /amex|american\s*express/i,
    /capital\s*one.*card/i,
    /citi.*card|citibank.*card/i,
    /discover.*card/i,
    /bank\s*of\s*america.*card/i,
    /wells\s*fargo.*card/i,
    /us\s*bank.*card/i,
    /barclays/i,
    /synchrony/i,
    /apple\s*card/i,
    /target.*card/i,
    /amazon.*card/i,
    /costco.*card/i,
  ],

  // ==================== FAMILY & KIDS ====================
  schoolTuition: [
    /tuition/i,
    /school.*payment/i,
    /academy/i,
    /montessori/i,
    /preparatory/i,
    /private\s*school/i,
    /catholic\s*school/i,
    /christian\s*school/i,
    /hebrew\s*school/i,
    /waldorf/i,
  ],
  college529: [
    /529\s*plan/i,
    /college\s*savings/i,
    /fidelity.*529/i,
    /vanguard.*529/i,
    /ny\s*saves/i,
    /illinois.*bright/i,
    /utah.*educational/i,
  ],
  childcare: [
    /daycare/i,
    /preschool/i,
    /childcare|child\s*care/i,
    /kindercare/i,
    /bright\s*horizons/i,
    /primrose\s*schools/i,
    /goddard\s*school/i,
    /learning\s*experience/i,
    /lightbridge/i,
    /children.*learning/i,
    /kiddie\s*academy/i,
    /la\s*petite/i,
    /tutor\s*time/i,
    /care\.com/i,
    /sittercity/i,
    /urbansitter/i,
  ],
  nanny: [
    /nanny/i,
    /au\s*pair/i,
    /cultural\s*care/i,
    /aupaircare/i,
    /care\.com/i,
    /breedlove/i,
    /gtm\s*payroll/i,
    /homepayhq/i,
    /paychex.*household/i,
    /payroll.*nanny/i,
  ],
  kidsActivities: [
    /little\s*league/i,
    /ayso|soccer.*assoc/i,
    /ymca.*youth/i,
    /karate|martial\s*arts|taekwondo/i,
    /dance\s*academy|ballet/i,
    /music\s*lesson|piano\s*lesson|guitar\s*lesson/i,
    /swim\s*lesson/i,
    /gymboree/i,
    /my\s*gym/i,
    /the\s*little\s*gym/i,
    /kumon/i,
    /mathnasium/i,
    /sylvan/i,
    /tutoring|tutor/i,
    /camp/i,
    /scouts|boy\s*scout|girl\s*scout/i,
  ],

  // ==================== HOME SERVICES ====================
  landscaping: [
    /landscap/i,
    /lawn\s*(care|service|maint)/i,
    /trugreen/i,
    /scotts.*lawn/i,
    /sunday\s*lawn/i,
    /weed\s*man/i,
    /spring.*green/i,
    /ryan.*lawn/i,
    /lawn\s*doctor/i,
    /grounds.*guys/i,
    /brickman/i,
    /brightview/i,
    /yellowstone/i,
    /davey\s*tree/i,
    /bartlett\s*tree/i,
    /tree.*service/i,
    /arborist/i,
    /mowing/i,
    /grass\s*cutting/i,
    /yard\s*work/i,
  ],
  pool: [
    /pool\s*(service|supply|care|cleaning|maintenance)/i,
    /leslie.*pool/i,
    /pinch\s*a\s*penny/i,
    /pool\s*corp/i,
    /america.*pool/i,
    /pool.*spa/i,
  ],
  pestControl: [
    /orkin/i,
    /terminix/i,
    /pest\s*(control|service|management)/i,
    /rentokil/i,
    /truly\s*nolen/i,
    /western\s*pest/i,
    /ehrlich/i,
    /arrow\s*exterminat/i,
    /home\s*team\s*pest/i,
    /aptive/i,
    /bulwark/i,
    /mosquito\s*joe/i,
    /mosquito\s*squad/i,
    /exterminator/i,
  ],
  cleaning: [
    /maid|merry\s*maids|molly\s*maid/i,
    /cleaning\s*service/i,
    /house.*clean/i,
    /the\s*maids/i,
    /two\s*maids/i,
    /maidpro/i,
    /handy/i,
    /homejoy/i,
    /tidy/i,
  ],
  windowWashing: [
    /window.*wash|window.*clean/i,
    /fish\s*window/i,
  ],
  gutterCleaning: [
    /gutter/i,
    /leaf\s*filter/i,
    /leafguard/i,
  ],
  security: [
    /adt/i,
    /vivint/i,
    /simplisafe/i,
    /ring.*protect/i,
    /nest.*aware/i,
    /brinks/i,
    /frontpoint/i,
    /abode/i,
    /cove.*security/i,
    /scout.*alarm/i,
    /link\s*interactive/i,
    /protect\s*america/i,
    /alarm\.com/i,
  ],
  snowRemoval: [
    /snow.*remov/i,
    /snow.*plow/i,
    /ice.*removal/i,
    /winter.*service/i,
  ],
  hvacService: [
    /hvac/i,
    /heating.*cooling/i,
    /air.*condition.*service/i,
    /furnace.*service/i,
    /carrier/i,
    /trane/i,
    /lennox/i,
    /rheem/i,
    /goodman/i,
    /one\s*hour.*heating/i,
    /service\s*experts/i,
  ],
  plumbing: [
    /plumber|plumbing/i,
    /roto.*rooter/i,
    /mr\.*rooter/i,
    /benjamin\s*franklin\s*plumb/i,
    /rescue\s*rooter/i,
  ],
  electrical: [
    /electrician|electrical\s*service/i,
    /mister\s*sparky/i,
    /mr\.*electric/i,
  ],
  homeWarranty: [
    /american\s*home\s*shield/i,
    /choice\s*home\s*warranty/i,
    /select\s*home\s*warranty/i,
    /first\s*american\s*home/i,
    /home\s*warranty.*america/i,
    /ahs\s*warranty/i,
    /2-10.*warranty/i,
    /hwa\s*home/i,
    /landmark\s*home/i,
    /total\s*protect/i,
    /cinch\s*home/i,
  ],

  // ==================== STORAGE ====================
  storage: [
    /public\s*storage/i,
    /extra\s*space/i,
    /cubesmart/i,
    /life\s*storage/i,
    /u-haul.*storage/i,
    /uncle\s*bob/i,
    /iron\s*mountain/i,
    /storage.*unit/i,
    /self.*storage/i,
    /mini.*storage/i,
  ],

  // ==================== CHARITABLE ====================
  charity: [
    /donation/i,
    /charity/i,
    /foundation/i,
    /red\s*cross/i,
    /united\s*way/i,
    /salvation\s*army/i,
    /goodwill/i,
    /habitat.*humanity/i,
    /st\.*jude/i,
    /make.*wish/i,
    /wounded\s*warrior/i,
    /aspca/i,
    /humane\s*society/i,
    /npr|public\s*radio/i,
    /pbs/i,
    /church/i,
    /synagogue/i,
    /mosque/i,
    /tithe|tithing/i,
  ],
};
```

---

## Part 4: Auto-Research on System Creation

### Update: `apps/api/src/alfred-email/email-actions.service.ts`

When Alfred email processing creates a system from an inspection report or other source, trigger research:

```typescript
// In the createHomeSystem method:

async createHomeSystem(
  householdId: string,
  systemData: any,
): Promise<void> {
  // Create the system record
  const system = await this.prisma.homeSystem.create({
    data: {
      householdId,
      name: systemData.name,
      type: this.inferSystemType(systemData),
      brand: systemData.brand,
      model: systemData.model,
      condition: systemData.condition,
      notes: systemData.notes,
    },
  });

  // AUTO-RESEARCH: Trigger maintenance research for this new system
  try {
    const homeProfile = await this.prisma.homeProfile.findUnique({
      where: { householdId },
      select: { state: true },
    });

    await this.maintenanceResearchService.createMaintenanceProgram(
      householdId,
      {
        name: systemData.name,
        type: system.type,
        brand: systemData.brand,
        model: systemData.model,
        notes: systemData.notes,
      },
      homeProfile?.state,
    );

    this.logger.log(`Auto-researched maintenance for new system: ${systemData.name}`);
  } catch (error) {
    this.logger.warn(`Failed to auto-research system ${systemData.name}: ${error.message}`);
  }
}
```

---

## Part 5: Schema Updates

### Add to schema.prisma for system types we're missing:

```prisma
enum HomeSystemType {
  // HVAC
  FURNACE
  AIR_CONDITIONER
  HEAT_PUMP
  BOILER
  THERMOSTAT
  MINI_SPLIT
  
  // Fuel Storage
  OIL_TANK
  PROPANE_TANK
  
  // Water Systems
  WATER_HEATER
  WATER_SOFTENER
  WELL_PUMP
  WELL_SYSTEM          // NEW
  SUMP_PUMP
  WATER_FILTRATION     // NEW
  SEPTIC_SYSTEM        // NEW
  SEPTIC_TANK          // NEW
  
  // Energy
  ELECTRICAL_PANEL
  GENERATOR
  SOLAR_PANELS
  BATTERY_STORAGE
  EV_CHARGER           // NEW
  
  // Kitchen
  REFRIGERATOR
  DISHWASHER
  OVEN_RANGE
  MICROWAVE
  GARBAGE_DISPOSAL
  RANGE_HOOD           // NEW
  ICE_MAKER            // NEW
  WINE_COOLER          // NEW
  
  // Laundry
  WASHER
  DRYER
  
  // Outdoor
  IRRIGATION_SYSTEM
  POOL_EQUIPMENT
  POOL_HEATER          // NEW
  HOT_TUB
  LAWN_MOWER
  SNOW_BLOWER          // NEW
  
  // Safety
  SMOKE_DETECTOR
  CO_DETECTOR
  SECURITY_SYSTEM
  FIRE_EXTINGUISHER
  FIRE_SPRINKLER       // NEW
  RADON_SYSTEM         // NEW
  
  // Structural
  ROOF                 // NEW
  GUTTERS              // NEW
  CHIMNEY              // NEW
  DECK                 // NEW
  FENCE                // NEW
  DRIVEWAY             // NEW
  EXTERIOR_PAINT       // NEW
  WINDOWS              // NEW
  
  // Other
  GARAGE_DOOR_OPENER
  CEILING_FAN
  FIREPLACE
  HUMIDIFIER           // NEW
  DEHUMIDIFIER         // NEW
  AIR_PURIFIER         // NEW
  ATTIC_FAN            // NEW
  WHOLE_HOUSE_FAN      // NEW
  CENTRAL_VACUUM       // NEW
  INTERCOM             // NEW
  HOME_THEATER         // NEW
  
  OTHER
}
```

---

## Part 6: Proactive System Detection in Alfred Chat

### Add detection logic to Alfred system prompt:

```typescript
// Add to Alfred's system prompt:

PROACTIVE SYSTEM DETECTION:
When a user mentions ANY of these things, use the research_and_add_system tool to create a full maintenance program:

HOME SYSTEMS:
- "I have well water" / "we're on a well" -> research well water system
- "I have septic" / "septic system" / "septic tank" -> research septic system  
- "I have an oil tank" / "oil heat" / "we use oil" -> research oil tank/heating
- "propane tank" / "propane heat" -> research propane system
- "generator" / "backup generator" / "Generac" -> research generator
- "solar panels" / "solar system" -> research solar panels
- "pool" / "swimming pool" -> research pool maintenance
- "hot tub" / "spa" / "jacuzzi" -> research hot tub maintenance

HVAC:
- Any furnace mention (brand/model if given) -> research furnace
- Any AC/air conditioner mention -> research AC system
- "heat pump" -> research heat pump
- "boiler" -> research boiler
- "mini split" -> research mini split system
- Any thermostat (Nest, Ecobee, Honeywell) -> research smart thermostat

WATER:
- "water heater" + brand/type -> research water heater
- "tankless water heater" -> research tankless system
- "water softener" -> research water softener
- "water filtration" / "whole house filter" / "reverse osmosis" -> research filtration
- "sump pump" -> research sump pump

APPLIANCES:
- Any refrigerator + brand/model -> research refrigerator
- Any dishwasher mention -> research dishwasher  
- Any washer/dryer mention -> research washer/dryer
- "garbage disposal" -> research disposal
- Range/oven/stove -> research cooking appliances

EXTERIOR:
- "roof" + age/material -> research roof maintenance
- "gutters" -> research gutter maintenance
- "chimney" -> research chimney maintenance
- "deck" -> research deck maintenance
- "driveway" + material (asphalt/concrete) -> research driveway

SAFETY:
- "smoke detectors" -> research smoke detector maintenance
- "CO detectors" -> research CO detector maintenance
- "fire extinguisher" -> research fire extinguisher maintenance
- "radon system" / "radon mitigation" -> research radon system
- "security system" + brand -> research security system

VEHICLES:
- Any vehicle + make/model/year -> research vehicle maintenance

The goal is: EVERY system the user mentions should trigger automatic research and task creation.
Never just acknowledge - always research and create the maintenance program.
```

---

## Part 7: Testing

### Test Cases:

1. **Well Water:**
   ```
   User: "I have well water"
   Expected: Creates WELL_SYSTEM with tasks for water testing (annual), pump inspection (annual), pressure tank check, etc.
   ```

2. **Specific Furnace Model:**
   ```
   User: "We have a Carrier 59MN7 furnace installed in 2018"
   Expected: Creates FURNACE with Carrier brand, model 59MN7, install date, plus model-specific maintenance tasks
   ```

3. **Oil Tank:**
   ```
   User: "I have a 275-gallon oil tank in the basement"
   Expected: Creates OIL_TANK with 275 gallon capacity, basement location, tasks for tank inspection, filter replacement, etc.
   ```

4. **Septic System:**
   ```
   User: "We're on septic"
   Expected: Creates SEPTIC_SYSTEM with tasks for pumping (every 3-5 years), inspection (annual), etc.
   ```

5. **Pool:**
   ```
   User: "We have a pool"
   Expected: Creates POOL_EQUIPMENT with tasks for opening (spring), closing (fall if Northeast), weekly service (summer), equipment winterization
   ```

6. **Specific Appliance:**
   ```
   User: "We just got a Samsung RF28R7551SR refrigerator"
   Expected: Creates REFRIGERATOR with Samsung brand, model number, tasks for coil cleaning, filter replacement, door seal inspection
   ```

---

## Implementation Order

1. **Create MaintenanceResearchService** (Part 1)
2. **Add research_and_add_system tool to Alfred** (Part 2)
3. **Expand Plaid patterns** (Part 3)
4. **Update email-actions for auto-research** (Part 4)
5. **Schema migration for new system types** (Part 5)
6. **Update Alfred system prompt** (Part 6)
7. **Test all scenarios** (Part 7)

---

## Success Criteria

- User says "I have well water" → 5-8 maintenance tasks created automatically
- User provides specific model number → Model-specific maintenance schedule created
- Plaid detects 90%+ of common household bills
- Every system addition triggers AI research
- Tasks have proper seasonal timing and frequencies
- Budget estimates provided for annual maintenance costs
- Vendor types needed are identified for each system
