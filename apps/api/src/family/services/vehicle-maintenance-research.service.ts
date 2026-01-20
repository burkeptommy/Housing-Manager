import { Injectable, Logger } from '@nestjs/common';
import Anthropic from '@anthropic-ai/sdk';
import { PrismaService } from '../../prisma/prisma.service';

interface MaintenanceItem {
  type: string;
  name: string;
  description: string;
  intervalMiles: number;
  intervalMonths?: number;
  estimatedCostLow: number;
  estimatedCostHigh: number;
  priority: 'CRITICAL' | 'IMPORTANT' | 'RECOMMENDED';
  diyDifficulty: 'EASY' | 'MODERATE' | 'PROFESSIONAL_REQUIRED';
  warningSignsToWatch: string[];
}

interface RecallInfo {
  campaignNumber: string;
  component: string;
  summary: string;
  consequence: string;
  remedy: string;
  dateIssued: string;
}

interface VehicleMaintenanceSchedule {
  maintenanceItems: MaintenanceItem[];
  recalls: RecallInfo[];
  tips: string[];
  specificNotes: string[];
}

@Injectable()
export class VehicleMaintenanceResearchService {
  private readonly logger = new Logger(VehicleMaintenanceResearchService.name);
  private anthropic: Anthropic;

  constructor(private readonly prisma: PrismaService) {
    this.anthropic = new Anthropic();
  }

  async researchVehicleMaintenance(
    year: number,
    make: string,
    model: string,
  ): Promise<VehicleMaintenanceSchedule> {
    this.logger.log(`Researching maintenance for ${year} ${make} ${model}`);

    const systemPrompt = `You are an expert automotive technician with deep knowledge of vehicle maintenance schedules, manufacturer recommendations, and common issues for all vehicle makes and models.

For the given vehicle, provide MANUFACTURER-SPECIFIC maintenance schedules based on the actual owner's manual recommendations, not generic advice.

Include:
1. Complete maintenance schedule with mileage/time intervals
2. Estimated costs (realistic ranges for professional service)
3. DIY difficulty rating
4. Warning signs for each item
5. Known recalls from NHTSA (only include real, verified recalls)
6. Model-specific tips and common issues`;

    const userPrompt = `Research the complete maintenance schedule for a ${year} ${make} ${model}.

Provide comprehensive data in JSON format:
{
  "maintenanceItems": [
    {
      "type": "OIL_CHANGE",
      "name": "Oil Change",
      "description": "Full synthetic oil change with filter replacement",
      "intervalMiles": 7500,
      "intervalMonths": 6,
      "estimatedCostLow": 50,
      "estimatedCostHigh": 90,
      "priority": "CRITICAL",
      "diyDifficulty": "EASY",
      "warningSignsToWatch": ["Oil light on dashboard", "Engine knocking", "Dark or gritty oil on dipstick"]
    }
  ],
  "recalls": [
    {
      "campaignNumber": "21V-123",
      "component": "Airbag",
      "summary": "Passenger airbag may not deploy properly",
      "consequence": "Increased risk of injury in a crash",
      "remedy": "Dealers will replace airbag module free of charge",
      "dateIssued": "2021-03-15"
    }
  ],
  "tips": [
    "This model uses a timing chain, not a belt, so no timing belt replacement needed",
    "The ${make} ${model} is known for premature brake wear - inspect brakes frequently"
  ],
  "specificNotes": [
    "Uses 0W-20 full synthetic oil",
    "Cabin air filter is difficult to access - recommend professional service"
  ]
}

Include ALL standard maintenance items based on manufacturer recommendations:
- Oil & filter
- Air filter (engine)
- Cabin air filter
- Tire rotation
- Tire replacement
- Brake inspection
- Brake pad replacement
- Brake fluid flush
- Transmission fluid
- Coolant flush
- Spark plugs
- Battery
- Serpentine belt
- Timing belt/chain (if applicable)
- Differential fluid (if applicable)
- Transfer case fluid (if AWD)
- Wheel alignment
- Suspension inspection
- Wiper blades

For recalls, only include REAL recalls from NHTSA. If uncertain, include an empty array.`;

    try {
      const response = await this.anthropic.messages.create({
        model: 'claude-sonnet-4-20250514',
        max_tokens: 4000,
        system: systemPrompt,
        messages: [{ role: 'user', content: userPrompt }],
      });

      const content = response.content[0];
      if (!content || content.type !== 'text') {
        throw new Error('Unexpected response type');
      }

      // Parse JSON from response
      const jsonMatch = content.text.match(/\{[\s\S]*\}/);
      if (!jsonMatch) {
        throw new Error('Failed to parse maintenance schedule');
      }

      return JSON.parse(jsonMatch[0]);
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`Failed to research maintenance: ${errorMessage}`);
      // Return default schedule if research fails
      return this.getDefaultSchedule(year, make, model);
    }
  }

  private getDefaultSchedule(year: number, make: string, model: string): VehicleMaintenanceSchedule {
    return {
      maintenanceItems: [
        {
          type: 'OIL_CHANGE',
          name: 'Oil Change',
          description: 'Engine oil and filter replacement',
          intervalMiles: 5000,
          intervalMonths: 6,
          estimatedCostLow: 40,
          estimatedCostHigh: 80,
          priority: 'CRITICAL',
          diyDifficulty: 'EASY',
          warningSignsToWatch: ['Oil warning light', 'Dark/dirty oil', 'Engine noise'],
        },
        {
          type: 'TIRE_ROTATION',
          name: 'Tire Rotation',
          description: 'Rotate tires for even wear',
          intervalMiles: 5000,
          intervalMonths: 6,
          estimatedCostLow: 20,
          estimatedCostHigh: 50,
          priority: 'IMPORTANT',
          diyDifficulty: 'MODERATE',
          warningSignsToWatch: ['Uneven tire wear', 'Vibration', 'Pulling to one side'],
        },
        {
          type: 'BRAKE_INSPECTION',
          name: 'Brake Inspection',
          description: 'Inspect brake pads, rotors, and fluid',
          intervalMiles: 12000,
          intervalMonths: 12,
          estimatedCostLow: 30,
          estimatedCostHigh: 80,
          priority: 'CRITICAL',
          diyDifficulty: 'MODERATE',
          warningSignsToWatch: ['Squealing sounds', 'Grinding', 'Soft brake pedal'],
        },
        {
          type: 'AIR_FILTER',
          name: 'Engine Air Filter',
          description: 'Replace engine air filter',
          intervalMiles: 15000,
          intervalMonths: 12,
          estimatedCostLow: 20,
          estimatedCostHigh: 50,
          priority: 'IMPORTANT',
          diyDifficulty: 'EASY',
          warningSignsToWatch: ['Reduced fuel economy', 'Reduced power', 'Dirty filter visible'],
        },
        {
          type: 'CABIN_AIR_FILTER',
          name: 'Cabin Air Filter',
          description: 'Replace cabin air filter',
          intervalMiles: 15000,
          intervalMonths: 12,
          estimatedCostLow: 30,
          estimatedCostHigh: 70,
          priority: 'RECOMMENDED',
          diyDifficulty: 'EASY',
          warningSignsToWatch: ['Musty odor', 'Poor AC airflow', 'Allergy symptoms'],
        },
        {
          type: 'TRANSMISSION_FLUID',
          name: 'Transmission Fluid',
          description: 'Transmission fluid change',
          intervalMiles: 60000,
          intervalMonths: 48,
          estimatedCostLow: 150,
          estimatedCostHigh: 300,
          priority: 'CRITICAL',
          diyDifficulty: 'PROFESSIONAL_REQUIRED',
          warningSignsToWatch: ['Delayed shifting', 'Slipping gears', 'Burnt smell'],
        },
        {
          type: 'COOLANT_FLUSH',
          name: 'Coolant Flush',
          description: 'Flush and replace engine coolant',
          intervalMiles: 30000,
          intervalMonths: 24,
          estimatedCostLow: 100,
          estimatedCostHigh: 200,
          priority: 'IMPORTANT',
          diyDifficulty: 'MODERATE',
          warningSignsToWatch: ['Overheating', 'Sweet smell', 'Low coolant level'],
        },
        {
          type: 'SPARK_PLUGS',
          name: 'Spark Plugs',
          description: 'Replace spark plugs',
          intervalMiles: 60000,
          intervalMonths: 60,
          estimatedCostLow: 100,
          estimatedCostHigh: 250,
          priority: 'IMPORTANT',
          diyDifficulty: 'MODERATE',
          warningSignsToWatch: ['Rough idle', 'Misfire', 'Hard starting'],
        },
        {
          type: 'BATTERY',
          name: 'Battery',
          description: 'Battery replacement',
          intervalMiles: 50000,
          intervalMonths: 48,
          estimatedCostLow: 100,
          estimatedCostHigh: 250,
          priority: 'CRITICAL',
          diyDifficulty: 'EASY',
          warningSignsToWatch: ['Slow cranking', 'Check battery light', 'Corrosion on terminals'],
        },
      ],
      recalls: [],
      tips: [
        `Refer to your ${year} ${make} ${model} owner's manual for exact specifications`,
        'Keep all service records for resale value',
        'Address warning lights promptly',
      ],
      specificNotes: [
        'Consult dealer for manufacturer-specific recommendations',
        'Use manufacturer-recommended fluids and parts',
      ],
    };
  }

  calculateMaintenanceDue(
    item: MaintenanceItem,
    currentMileage: number,
    lastServiceMileage?: number,
    lastServiceDate?: Date,
  ): {
    dueMileage: number;
    dueDate?: Date;
    milesUntilDue: number;
    daysUntilDue?: number;
    status: 'ok' | 'due_soon' | 'overdue';
  } {
    // Calculate next due mileage
    const baseMileage = lastServiceMileage || 0;
    const dueMileage = baseMileage + item.intervalMiles;
    const milesUntilDue = dueMileage - currentMileage;

    // Calculate next due date
    let dueDate: Date | undefined;
    let daysUntilDue: number | undefined;
    if (item.intervalMonths) {
      if (lastServiceDate) {
        dueDate = new Date(lastServiceDate);
        dueDate.setMonth(dueDate.getMonth() + item.intervalMonths);
      } else {
        // No last service, assume due based on interval from now
        dueDate = new Date();
        dueDate.setMonth(dueDate.getMonth() + item.intervalMonths);
      }
      daysUntilDue = Math.ceil((dueDate.getTime() - Date.now()) / (1000 * 60 * 60 * 24));
    }

    // Determine status (use stricter of mileage or time)
    let status: 'ok' | 'due_soon' | 'overdue' = 'ok';

    // Check mileage
    if (milesUntilDue < 0) {
      status = 'overdue';
    } else if (milesUntilDue < 1000) {
      status = 'due_soon';
    }

    // Check time (if applicable)
    if (daysUntilDue !== undefined) {
      if (daysUntilDue < 0 && status !== 'overdue') {
        status = 'overdue';
      } else if (daysUntilDue < 30 && status === 'ok') {
        status = 'due_soon';
      }
    }

    return {
      dueMileage,
      dueDate,
      milesUntilDue,
      daysUntilDue,
      status,
    };
  }

  async getMaintenanceDue(vehicleId: string) {
    const vehicle = await this.prisma.vehicle.findUnique({
      where: { id: vehicleId },
      include: {
        services: {
          orderBy: { serviceDate: 'desc' },
        },
      },
    });

    if (!vehicle) throw new Error('Vehicle not found');

    // Check if we have researched maintenance for this vehicle
    let schedule = vehicle.maintenanceSchedule as unknown as VehicleMaintenanceSchedule | null;

    if (!schedule) {
      // Research maintenance schedule
      schedule = await this.researchVehicleMaintenance(
        vehicle.year,
        vehicle.make,
        vehicle.model,
      );

      // Save to vehicle
      await this.prisma.vehicle.update({
        where: { id: vehicleId },
        data: {
          maintenanceSchedule: schedule as any,
          maintenanceResearchedAt: new Date(),
        },
      });
    }

    const currentMileage = vehicle.currentMileage || 0;

    // Calculate status for each maintenance item
    const items = schedule.maintenanceItems.map(item => {
      // Find last service of this type
      const lastService = vehicle.services?.find(
        s => s.serviceType?.toUpperCase() === item.type.toUpperCase()
      );

      const dueInfo = this.calculateMaintenanceDue(
        item,
        currentMileage,
        lastService?.mileageAt || undefined,
        lastService?.serviceDate ? new Date(lastService.serviceDate) : undefined,
      );

      return {
        ...item,
        lastServiceDate: lastService?.serviceDate,
        lastServiceMileage: lastService?.mileageAt,
        lastServiceCost: lastService?.cost ? Number(lastService.cost) : undefined,
        ...dueInfo,
      };
    });

    // Sort by priority and status
    items.sort((a, b) => {
      const statusOrder = { overdue: 0, due_soon: 1, ok: 2 };
      const priorityOrder = { CRITICAL: 0, IMPORTANT: 1, RECOMMENDED: 2 };

      if (statusOrder[a.status] !== statusOrder[b.status]) {
        return statusOrder[a.status] - statusOrder[b.status];
      }
      return priorityOrder[a.priority] - priorityOrder[b.priority];
    });

    return {
      currentMileage,
      items,
      recalls: schedule.recalls || [],
      tips: schedule.tips || [],
      specificNotes: schedule.specificNotes || [],
    };
  }

  async refreshMaintenanceResearch(vehicleId: string) {
    const vehicle = await this.prisma.vehicle.findUnique({
      where: { id: vehicleId },
    });

    if (!vehicle) throw new Error('Vehicle not found');

    // Force refresh the research
    const schedule = await this.researchVehicleMaintenance(
      vehicle.year,
      vehicle.make,
      vehicle.model,
    );

    // Save to vehicle
    await this.prisma.vehicle.update({
      where: { id: vehicleId },
      data: {
        maintenanceSchedule: schedule as any,
        maintenanceResearchedAt: new Date(),
      },
    });

    return this.getMaintenanceDue(vehicleId);
  }
}
