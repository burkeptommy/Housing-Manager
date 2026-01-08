import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { EquipmentResearchService, MaintenanceRequirement } from './equipment-research.service';
import { SYSTEM_TYPE_TO_CATEGORY } from './system-categories';
import { HomeSystemType, MaintenanceTaskStatus, MaintenanceCategory, MaintenanceFrequency, TaskSource } from '@prisma/client';

interface CreateSystemInput {
  householdId: string;
  type: HomeSystemType;
  name: string;
  brand?: string;
  model?: string;
  modelNumber?: string;
  serialNumber?: string;
  installedDate?: Date;
  purchaseDate?: Date;
  location?: string;
  lastMaintenanceDate?: Date;
  warrantyExpires?: Date;
}

@Injectable()
export class EquipmentService {
  private readonly logger = new Logger(EquipmentService.name);

  constructor(
    private prisma: PrismaService,
    private researchService: EquipmentResearchService,
  ) {}

  async addSystem(input: CreateSystemInput) {
    const {
      householdId,
      type,
      name,
      brand,
      model,
      modelNumber,
      serialNumber,
      installedDate,
      purchaseDate,
      location,
      lastMaintenanceDate,
      warrantyExpires,
    } = input;

    // Get category from type
    const category = SYSTEM_TYPE_TO_CATEGORY[type] || 'APPLIANCE';

    // Research maintenance requirements for this equipment
    this.logger.log(`Researching maintenance for ${brand || ''} ${model || ''} ${type}`);

    const research = await this.researchService.researchEquipment(
      category,
      type,
      brand,
      model,
    );

    // Calculate next service date based on primary maintenance interval
    const primaryMaintenance = research.maintenanceRequirements.find(
      (m) => m.criticalLevel === 'HIGH' || m.criticalLevel === 'CRITICAL',
    ) || research.maintenanceRequirements[0];

    const intervalMonths = primaryMaintenance?.intervalMonths || 12;

    let nextMaintenanceDate: Date;
    if (lastMaintenanceDate) {
      nextMaintenanceDate = new Date(lastMaintenanceDate);
      nextMaintenanceDate.setMonth(nextMaintenanceDate.getMonth() + intervalMonths);
    } else if (installedDate) {
      nextMaintenanceDate = new Date(installedDate);
      nextMaintenanceDate.setMonth(nextMaintenanceDate.getMonth() + intervalMonths);
    } else {
      // Default to interval from now
      nextMaintenanceDate = new Date();
      nextMaintenanceDate.setMonth(nextMaintenanceDate.getMonth() + intervalMonths);
    }

    // Ensure next service date is in the future
    const now = new Date();
    while (nextMaintenanceDate < now) {
      nextMaintenanceDate.setMonth(nextMaintenanceDate.getMonth() + intervalMonths);
    }

    // Create the system record
    const system = await this.prisma.homeSystem.create({
      data: {
        householdId,
        type,
        name,
        brand,
        model,
        modelNumber,
        serialNumber,
        installedDate,
        purchaseDate,
        location,
        lastMaintenanceDate,
        nextMaintenanceDate,
        warrantyExpires,
        maintenanceIntervalMonths: intervalMonths,
        maintenanceNotes: research.generalNotes,
      },
    });

    // Create maintenance tasks for each requirement
    const tasksCreated = await this.createMaintenanceTasks(
      system.id,
      householdId,
      research.maintenanceRequirements,
      lastMaintenanceDate,
    );

    return {
      system,
      research,
      tasksCreated,
    };
  }

  private async createMaintenanceTasks(
    homeSystemId: string,
    householdId: string,
    requirements: MaintenanceRequirement[],
    lastServiceDate?: Date,
  ): Promise<number> {
    const now = new Date();
    let tasksCreated = 0;

    for (const req of requirements) {
      // Calculate next due date for this specific task
      let dueDate: Date;
      if (lastServiceDate) {
        dueDate = new Date(lastServiceDate);
        dueDate.setMonth(dueDate.getMonth() + req.intervalMonths);
      } else {
        dueDate = new Date();
        dueDate.setMonth(dueDate.getMonth() + req.intervalMonths);
      }

      // Ensure due date is in the future
      while (dueDate < now) {
        dueDate.setMonth(dueDate.getMonth() + req.intervalMonths);
      }

      // Adjust for seasonal preference
      if (req.seasonalPreference) {
        dueDate = this.adjustForSeason(dueDate, req.seasonalPreference);
      }

      // Determine status
      const thirtyDaysFromNow = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
      let status: MaintenanceTaskStatus;
      if (dueDate < now) {
        status = MaintenanceTaskStatus.OVERDUE;
      } else if (dueDate < thirtyDaysFromNow) {
        status = MaintenanceTaskStatus.UPCOMING;
      } else {
        status = MaintenanceTaskStatus.SCHEDULED;
      }

      await this.prisma.maintenanceTask.create({
        data: {
          householdId,
          homeSystemId,
          title: req.taskName,
          description: req.description,
          category: this.mapCriticalLevelToCategory(req.criticalLevel),
          status,
          dueDate,
          frequency: this.mapIntervalToFrequency(req.intervalMonths),
          estimatedCost: req.estimatedCost?.max,
          isRecurring: true,
          recurringIntervalMonths: req.intervalMonths,
          source: TaskSource.AUTO_GENERATED,
          notes: req.notes,
        },
      });

      tasksCreated++;
    }

    return tasksCreated;
  }

  private adjustForSeason(date: Date, season: string): Date {
    const targetMonths: Record<string, number[]> = {
      spring: [2, 3, 4], // March, April, May
      summer: [5, 6, 7], // June, July, August
      fall: [8, 9, 10], // September, October, November
      winter: [11, 0, 1], // December, January, February
      'before-winter': [9, 10], // October, November
      'before-summer': [3, 4], // April, May
    };

    const targets = targetMonths[season];
    if (!targets) return date;

    // Find the nearest target month
    const year = date.getFullYear();
    let bestDate = date;
    let minDiff = Infinity;

    for (const targetMonth of targets) {
      const candidate = new Date(year, targetMonth, 15);
      if (candidate < new Date()) {
        candidate.setFullYear(year + 1);
      }
      const diff = Math.abs(candidate.getTime() - date.getTime());
      if (diff < minDiff) {
        minDiff = diff;
        bestDate = candidate;
      }
    }

    return bestDate;
  }

  private mapIntervalToFrequency(months: number): MaintenanceFrequency {
    if (months <= 1) return MaintenanceFrequency.MONTHLY;
    if (months <= 3) return MaintenanceFrequency.QUARTERLY;
    if (months <= 6) return MaintenanceFrequency.SEMI_ANNUAL;
    if (months <= 12) return MaintenanceFrequency.ANNUAL;
    if (months <= 24) return MaintenanceFrequency.BIENNIAL;
    return MaintenanceFrequency.AS_NEEDED;
  }

  private mapCriticalLevelToCategory(level: string): MaintenanceCategory {
    switch (level) {
      case 'CRITICAL':
        return MaintenanceCategory.SAFETY;
      case 'HIGH':
        return MaintenanceCategory.HVAC;
      case 'MEDIUM':
        return MaintenanceCategory.GENERAL;
      default:
        return MaintenanceCategory.OTHER;
    }
  }

  async getSystems(householdId: string) {
    return this.prisma.homeSystem.findMany({
      where: { householdId, isActive: true },
      include: {
        maintenanceTasks: {
          where: { status: { not: MaintenanceTaskStatus.COMPLETED } },
          orderBy: { dueDate: 'asc' },
          take: 5,
        },
        serviceHistory: {
          orderBy: { serviceDate: 'desc' },
          take: 5,
        },
      },
      orderBy: { nextMaintenanceDate: 'asc' },
    });
  }

  async getSystemById(id: string) {
    const system = await this.prisma.homeSystem.findUnique({
      where: { id },
      include: {
        maintenanceTasks: {
          orderBy: { dueDate: 'asc' },
        },
        serviceHistory: {
          orderBy: { serviceDate: 'desc' },
        },
      },
    });

    if (!system) {
      throw new NotFoundException('System not found');
    }

    return system;
  }

  async updateSystem(
    id: string,
    data: Partial<CreateSystemInput>,
  ) {
    const system = await this.prisma.homeSystem.findUnique({ where: { id } });
    if (!system) {
      throw new NotFoundException('System not found');
    }

    return this.prisma.homeSystem.update({
      where: { id },
      data: {
        name: data.name,
        brand: data.brand,
        model: data.model,
        modelNumber: data.modelNumber,
        serialNumber: data.serialNumber,
        location: data.location,
        installedDate: data.installedDate,
        purchaseDate: data.purchaseDate,
        warrantyExpires: data.warrantyExpires,
      },
    });
  }

  async recordService(
    systemId: string,
    serviceDate: Date,
    serviceType: string,
    description?: string,
    performedBy?: string,
    cost?: number,
    vendorId?: string,
  ) {
    const system = await this.prisma.homeSystem.findUnique({
      where: { id: systemId },
    });

    if (!system) {
      throw new NotFoundException('System not found');
    }

    // Calculate next service date
    const intervalMonths = system.maintenanceIntervalMonths || 12;
    const nextServiceDate = new Date(serviceDate);
    nextServiceDate.setMonth(nextServiceDate.getMonth() + intervalMonths);

    // Create service record
    await this.prisma.homeSystemService.create({
      data: {
        homeSystemId: systemId,
        serviceDate,
        serviceType,
        description,
        technicianName: performedBy,
        totalCost: cost,
        vendorId,
        nextServiceDate,
      },
    });

    // Update system
    await this.prisma.homeSystem.update({
      where: { id: systemId },
      data: {
        lastMaintenanceDate: serviceDate,
        lastServiceDate: serviceDate,
        nextMaintenanceDate: nextServiceDate,
      },
    });

    // Mark related maintenance tasks as completed
    await this.prisma.maintenanceTask.updateMany({
      where: {
        homeSystemId: systemId,
        status: { in: [MaintenanceTaskStatus.OVERDUE, MaintenanceTaskStatus.UPCOMING, MaintenanceTaskStatus.SCHEDULED, MaintenanceTaskStatus.DUE_SOON] },
      },
      data: {
        status: MaintenanceTaskStatus.COMPLETED,
        completedAt: serviceDate,
      },
    });

    // Create new maintenance task for next service
    await this.prisma.maintenanceTask.create({
      data: {
        householdId: system.householdId,
        homeSystemId: systemId,
        title: `${system.name} Service`,
        description: system.maintenanceNotes || `Scheduled maintenance for ${system.name}`,
        category: MaintenanceCategory.GENERAL,
        status: MaintenanceTaskStatus.SCHEDULED,
        dueDate: nextServiceDate,
        frequency: this.mapIntervalToFrequency(intervalMonths),
        estimatedCost: cost,
        isRecurring: true,
        recurringIntervalMonths: intervalMonths,
        source: TaskSource.AUTO_GENERATED,
      },
    });

    return { success: true, nextServiceDate };
  }

  async deactivateSystem(id: string) {
    const system = await this.prisma.homeSystem.findUnique({ where: { id } });
    if (!system) {
      throw new NotFoundException('System not found');
    }

    // Deactivate the system
    await this.prisma.homeSystem.update({
      where: { id },
      data: { isActive: false },
    });

    // Cancel pending maintenance tasks
    await this.prisma.maintenanceTask.updateMany({
      where: {
        homeSystemId: id,
        status: { in: [MaintenanceTaskStatus.PENDING, MaintenanceTaskStatus.SCHEDULED, MaintenanceTaskStatus.UPCOMING] },
      },
      data: {
        status: MaintenanceTaskStatus.SKIPPED,
        notes: 'System deactivated',
      },
    });

    return { success: true };
  }

  async getSystemsDueSoon(householdId: string, days: number = 30) {
    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + days);

    return this.prisma.homeSystem.findMany({
      where: {
        householdId,
        isActive: true,
        nextMaintenanceDate: {
          lte: futureDate,
        },
      },
      include: {
        maintenanceTasks: {
          where: {
            status: { not: MaintenanceTaskStatus.COMPLETED },
            dueDate: { lte: futureDate },
          },
        },
      },
      orderBy: { nextMaintenanceDate: 'asc' },
    });
  }
}
