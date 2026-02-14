import { Injectable, Logger, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateHomeSystemDto, UpdateHomeSystemDto, CreateHomeSystemServiceDto } from '../dto';
import { Prisma, HomeSystemType } from '@prisma/client';

@Injectable()
export class HomeSystemService {
  private readonly logger = new Logger(HomeSystemService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Create a new home system/appliance
   */
  async create(householdId: string, dto: CreateHomeSystemDto) {
    return this.prisma.homeSystem.create({
      data: {
        householdId,
        ...dto,
        purchasePrice: dto.purchasePrice ? new Prisma.Decimal(dto.purchasePrice) : undefined,
        tankCapacity: dto.tankCapacity ? new Prisma.Decimal(dto.tankCapacity) : undefined,
        estimatedRemaining: dto.estimatedRemaining ? new Prisma.Decimal(dto.estimatedRemaining) : undefined,
      },
      include: {
        serviceVendor: {
          select: { id: true, displayName: true, phone: true },
        },
      },
    });
  }

  /**
   * Get all systems for a household
   */
  async findAllByHousehold(householdId: string, includeInactive = false) {
    return this.prisma.homeSystem.findMany({
      where: {
        householdId,
        ...(includeInactive ? {} : { isActive: true }),
      },
      include: {
        serviceHistory: {
          orderBy: { serviceDate: 'desc' },
          take: 3,
        },
        serviceVendor: {
          select: { id: true, displayName: true, phone: true },
        },
      },
      orderBy: [
        { type: 'asc' },
        { name: 'asc' },
      ],
    });
  }

  /**
   * Get systems by type for a household
   */
  async findByType(householdId: string, systemType: HomeSystemType) {
    return this.prisma.homeSystem.findMany({
      where: {
        householdId,
        type: systemType,
        isActive: true,
      },
      include: {
        serviceHistory: {
          orderBy: { serviceDate: 'desc' },
          take: 5,
        },
        serviceVendor: {
          select: { id: true, displayName: true, phone: true },
        },
      },
    });
  }

  /**
   * Get a single system by ID
   */
  async findOne(id: string, householdId: string) {
    const system = await this.prisma.homeSystem.findUnique({
      where: { id },
      include: {
        serviceHistory: {
          orderBy: { serviceDate: 'desc' },
          include: {
            vendor: {
              select: { id: true, displayName: true },
            },
          },
        },
        serviceVendor: true,
        maintenanceTasks: {
          where: {
            status: { in: ['PENDING', 'SCHEDULED', 'IN_PROGRESS'] },
          },
          orderBy: { createdAt: 'desc' },
          take: 5,
        },
      },
    });

    if (!system) {
      throw new NotFoundException('Home system not found');
    }

    if (system.householdId !== householdId) {
      throw new ForbiddenException('Access denied');
    }

    return system;
  }

  /**
   * Update a system
   */
  async update(id: string, householdId: string, dto: UpdateHomeSystemDto) {
    await this.findOne(id, householdId);

    return this.prisma.homeSystem.update({
      where: { id },
      data: {
        ...dto,
        purchasePrice: dto.purchasePrice ? new Prisma.Decimal(dto.purchasePrice) : undefined,
        tankCapacity: dto.tankCapacity ? new Prisma.Decimal(dto.tankCapacity) : undefined,
        estimatedRemaining: dto.estimatedRemaining ? new Prisma.Decimal(dto.estimatedRemaining) : undefined,
      },
      include: {
        serviceVendor: {
          select: { id: true, displayName: true, phone: true },
        },
      },
    });
  }

  /**
   * Delete (archive) a system
   */
  async remove(id: string, householdId: string) {
    await this.findOne(id, householdId);

    return this.prisma.homeSystem.update({
      where: { id },
      data: { isActive: false },
    });
  }

  /**
   * Add a service record
   */
  async addServiceRecord(systemId: string, householdId: string, dto: CreateHomeSystemServiceDto) {
    await this.findOne(systemId, householdId);

    const record = await this.prisma.homeSystemService.create({
      data: {
        homeSystemId: systemId,
        serviceDate: dto.serviceDate,
        serviceType: dto.serviceType,
        description: dto.description,
        technicianName: dto.technicianName,
        partsReplaced: dto.partsReplaced || [],
        laborCost: dto.laborCost ? new Prisma.Decimal(dto.laborCost) : undefined,
        partsCost: dto.partsCost ? new Prisma.Decimal(dto.partsCost) : undefined,
        totalCost: dto.totalCost ? new Prisma.Decimal(dto.totalCost) : undefined,
        vendorId: dto.vendorId,
        vendorName: dto.vendorName,
        invoiceUrl: dto.invoiceUrl,
        receiptUrl: dto.receiptUrl,
        nextServiceDate: dto.nextServiceDate,
        recommendations: dto.recommendations,
      },
    });

    // Update system with latest service info
    const updateData: Prisma.HomeSystemUpdateInput = {
      lastServiceDate: dto.serviceDate,
    };

    if (dto.nextServiceDate) {
      updateData.nextMaintenanceDate = dto.nextServiceDate;
    }

    // If service type indicates filter change, update filter date
    if (dto.serviceType?.toLowerCase().includes('filter')) {
      updateData.lastFilterChange = dto.serviceDate;
    }

    await this.prisma.homeSystem.update({
      where: { id: systemId },
      data: updateData,
    });

    return record;
  }

  /**
   * Get service records for a system
   */
  async getServiceRecords(systemId: string, householdId: string) {
    await this.findOne(systemId, householdId);

    return this.prisma.homeSystemService.findMany({
      where: { homeSystemId: systemId },
      include: {
        vendor: {
          select: { id: true, displayName: true },
        },
      },
      orderBy: { serviceDate: 'desc' },
    });
  }

  /**
   * Update tank level (for propane, oil, etc.)
   */
  async updateTankLevel(id: string, householdId: string, level: number) {
    await this.findOne(id, householdId);

    return this.prisma.homeSystem.update({
      where: { id },
      data: {
        estimatedRemaining: new Prisma.Decimal(level),
        lastFillDate: new Date(),
      },
    });
  }

  /**
   * Get home systems dashboard summary
   */
  async getHomeDashboard(householdId: string) {
    const systems = await this.prisma.homeSystem.findMany({
      where: {
        householdId,
        isActive: true,
      },
      include: {
        serviceHistory: {
          orderBy: { serviceDate: 'desc' },
          take: 1,
        },
        serviceVendor: {
          select: { id: true, displayName: true, phone: true },
        },
      },
      orderBy: { type: 'asc' },
    });

    // Group by category
    const hvac = systems.filter(s =>
      ['FURNACE', 'AIR_CONDITIONER', 'HEAT_PUMP', 'BOILER', 'THERMOSTAT'].includes(s.type)
    );
    const water = systems.filter(s =>
      ['WATER_HEATER', 'WATER_SOFTENER', 'WELL_PUMP', 'SUMP_PUMP'].includes(s.type)
    );
    const electrical = systems.filter(s =>
      ['ELECTRICAL_PANEL', 'GENERATOR', 'SOLAR_PANELS', 'BATTERY_STORAGE'].includes(s.type)
    );
    const kitchen = systems.filter(s =>
      ['REFRIGERATOR', 'DISHWASHER', 'OVEN_RANGE', 'MICROWAVE', 'GARBAGE_DISPOSAL'].includes(s.type)
    );
    const laundry = systems.filter(s =>
      ['WASHER', 'DRYER'].includes(s.type)
    );
    const outdoor = systems.filter(s =>
      ['IRRIGATION_SYSTEM', 'POOL_EQUIPMENT', 'HOT_TUB', 'LAWN_MOWER'].includes(s.type)
    );
    const safety = systems.filter(s =>
      ['SMOKE_DETECTOR', 'CO_DETECTOR', 'SECURITY_SYSTEM', 'FIRE_EXTINGUISHER'].includes(s.type)
    );
    const other = systems.filter(s =>
      ['GARAGE_DOOR_OPENER', 'CEILING_FAN', 'FIREPLACE', 'OTHER'].includes(s.type)
    );

    // Format system info for display
    const formatSystem = (system: typeof systems[0]) => ({
      id: system.id,
      type: system.type,
      name: system.name,
      brand: system.brand,
      model: system.model,
      serialNumber: system.serialNumber,
      installDate: system.installedDate,
      warrantyExpires: system.warrantyExpires,
      lastServiceDate: system.lastServiceDate,
      nextServiceDue: system.nextMaintenanceDate,
      condition: system.condition,
      location: system.location,
      notes: system.notes,
      // Utility info
      utilityProvider: system.serviceProvider,
      accountNumber: system.serviceAccountNumber,
      // Tank info (for propane, oil, etc.)
      tankCapacity: system.tankCapacity,
      currentTankLevel: system.estimatedRemaining,
      lastFillDate: system.lastFillDate,
      // Filter info
      filterSize: system.filterSize,
      lastFilterChange: system.lastFilterChange,
      filterChangeIntervalMonths: system.filterChangeIntervalMonths,
      // Vendor
      serviceVendor: (system as any).serviceVendor,
      // Last service
      lastService: system.serviceHistory[0] ? {
        date: system.serviceHistory[0].serviceDate,
        type: system.serviceHistory[0].serviceType,
        notes: system.serviceHistory[0].notes,
      } : null,
    });

    return {
      hvac: hvac.map(formatSystem),
      water: water.map(formatSystem),
      electrical: electrical.map(formatSystem),
      kitchen: kitchen.map(formatSystem),
      laundry: laundry.map(formatSystem),
      outdoor: outdoor.map(formatSystem),
      safety: safety.map(formatSystem),
      other: other.map(formatSystem),
      totalSystems: systems.length,
    };
  }

  /**
   * Check for maintenance alerts
   */
  async getMaintenanceAlerts(householdId: string) {
    const systems = await this.prisma.homeSystem.findMany({
      where: {
        householdId,
        isActive: true,
      },
    });

    const alerts: Array<{
      systemId: string;
      systemName: string;
      systemType: HomeSystemType;
      type: string;
      message: string;
      severity: 'low' | 'medium' | 'high';
    }> = [];

    const now = new Date();

    for (const system of systems) {
      const systemName = system.name || system.type;

      // Check warranty expiration
      if (system.warrantyExpires) {
        const daysUntilExpiry = (system.warrantyExpires.getTime() - now.getTime()) / (1000 * 60 * 60 * 24);
        if (daysUntilExpiry <= 0) {
          alerts.push({
            systemId: system.id,
            systemName,
            systemType: system.type,
            type: 'WARRANTY',
            message: `Warranty expired`,
            severity: 'low',
          });
        } else if (daysUntilExpiry <= 30) {
          alerts.push({
            systemId: system.id,
            systemName,
            systemType: system.type,
            type: 'WARRANTY',
            message: `Warranty expires in ${Math.ceil(daysUntilExpiry)} days`,
            severity: 'low',
          });
        }
      }

      // Check service due
      if (system.nextMaintenanceDate) {
        const daysUntilService = (system.nextMaintenanceDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24);
        if (daysUntilService <= 0) {
          alerts.push({
            systemId: system.id,
            systemName,
            systemType: system.type,
            type: 'SERVICE',
            message: `Service overdue`,
            severity: 'high',
          });
        } else if (daysUntilService <= 30) {
          alerts.push({
            systemId: system.id,
            systemName,
            systemType: system.type,
            type: 'SERVICE',
            message: `Service due in ${Math.ceil(daysUntilService)} days`,
            severity: 'medium',
          });
        }
      }

      // Check filter change (compute next filter date from last change + interval)
      const nextFilterDate = system.lastFilterChange && system.filterChangeIntervalMonths
        ? new Date(new Date(system.lastFilterChange).setMonth(system.lastFilterChange.getMonth() + system.filterChangeIntervalMonths))
        : null;
      if (nextFilterDate) {
        const daysUntilFilter = (nextFilterDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24);
        if (daysUntilFilter <= 0) {
          alerts.push({
            systemId: system.id,
            systemName,
            systemType: system.type,
            type: 'FILTER',
            message: `Filter change overdue`,
            severity: 'medium',
          });
        } else if (daysUntilFilter <= 14) {
          alerts.push({
            systemId: system.id,
            systemName,
            systemType: system.type,
            type: 'FILTER',
            message: `Filter change due in ${Math.ceil(daysUntilFilter)} days`,
            severity: 'low',
          });
        }
      }

      // Check tank level
      if (system.tankCapacity && system.estimatedRemaining) {
        const levelPercent = Number(system.estimatedRemaining) / Number(system.tankCapacity) * 100;
        if (levelPercent <= 10) {
          alerts.push({
            systemId: system.id,
            systemName,
            systemType: system.type,
            type: 'TANK_LEVEL',
            message: `Tank critically low (${Math.round(levelPercent)}%)`,
            severity: 'high',
          });
        } else if (levelPercent <= 25) {
          alerts.push({
            systemId: system.id,
            systemName,
            systemType: system.type,
            type: 'TANK_LEVEL',
            message: `Tank level low (${Math.round(levelPercent)}%)`,
            severity: 'medium',
          });
        }
      }

      // Check condition
      if (system.condition === 'NEEDS_REPAIR') {
        alerts.push({
          systemId: system.id,
          systemName,
          systemType: system.type,
          type: 'CONDITION',
          message: `Needs repair`,
          severity: 'high',
        });
      }

      // Check safety equipment (smoke/CO detectors) - recommend annual check
      if (['SMOKE_DETECTOR', 'CO_DETECTOR', 'FIRE_EXTINGUISHER'].includes(system.type)) {
        if (system.lastServiceDate) {
          const daysSinceService = (now.getTime() - system.lastServiceDate.getTime()) / (1000 * 60 * 60 * 24);
          if (daysSinceService > 365) {
            alerts.push({
              systemId: system.id,
              systemName,
              systemType: system.type,
              type: 'SAFETY_CHECK',
              message: `Annual safety check overdue`,
              severity: 'high',
            });
          }
        } else {
          alerts.push({
            systemId: system.id,
            systemName,
            systemType: system.type,
            type: 'SAFETY_CHECK',
            message: `No service record - schedule safety check`,
            severity: 'medium',
          });
        }
      }
    }

    return alerts.sort((a, b) => {
      const severityOrder = { high: 0, medium: 1, low: 2 };
      return severityOrder[a.severity] - severityOrder[b.severity];
    });
  }
}
