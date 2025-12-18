import { Injectable, Logger, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateVehicleDto, UpdateVehicleDto, CreateVehicleServiceRecordDto } from '../dto';
import { Prisma } from '@prisma/client';

@Injectable()
export class VehicleService {
  private readonly logger = new Logger(VehicleService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Create a new vehicle for a household
   */
  async create(householdId: string, dto: CreateVehicleDto) {
    return this.prisma.vehicle.create({
      data: {
        householdId,
        ...dto,
        purchasePrice: dto.purchasePrice ? new Prisma.Decimal(dto.purchasePrice) : undefined,
      },
      include: {
        preferredVendor: true,
      },
    });
  }

  /**
   * Get all vehicles for a household
   */
  async findAllByHousehold(householdId: string, includeInactive = false) {
    return this.prisma.vehicle.findMany({
      where: {
        householdId,
        ...(includeInactive ? {} : { isActive: true }),
      },
      include: {
        serviceRecords: {
          orderBy: { serviceDate: 'desc' },
          take: 5,
        },
        preferredVendor: {
          select: { id: true, displayName: true, phone: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  /**
   * Get a single vehicle by ID
   */
  async findOne(id: string, householdId: string) {
    const vehicle = await this.prisma.vehicle.findUnique({
      where: { id },
      include: {
        serviceRecords: {
          orderBy: { serviceDate: 'desc' },
        },
        preferredVendor: true,
        events: {
          where: {
            startDate: { gte: new Date() },
          },
          orderBy: { startDate: 'asc' },
          take: 5,
        },
      },
    });

    if (!vehicle) {
      throw new NotFoundException('Vehicle not found');
    }

    if (vehicle.householdId !== householdId) {
      throw new ForbiddenException('Access denied');
    }

    return vehicle;
  }

  /**
   * Update a vehicle
   */
  async update(id: string, householdId: string, dto: UpdateVehicleDto) {
    await this.findOne(id, householdId);

    return this.prisma.vehicle.update({
      where: { id },
      data: {
        ...dto,
        purchasePrice: dto.purchasePrice ? new Prisma.Decimal(dto.purchasePrice) : undefined,
        lastMileageUpdate: dto.currentMileage ? new Date() : undefined,
      },
      include: {
        preferredVendor: true,
      },
    });
  }

  /**
   * Delete (archive) a vehicle
   */
  async remove(id: string, householdId: string) {
    await this.findOne(id, householdId);

    return this.prisma.vehicle.update({
      where: { id },
      data: { isActive: false },
    });
  }

  /**
   * Add a service record
   */
  async addServiceRecord(vehicleId: string, householdId: string, dto: CreateVehicleServiceRecordDto) {
    const vehicle = await this.findOne(vehicleId, householdId);

    const record = await this.prisma.vehicleServiceRecord.create({
      data: {
        vehicleId,
        ...dto,
        cost: dto.cost ? new Prisma.Decimal(dto.cost) : undefined,
      },
    });

    // Update vehicle with latest service info if applicable
    const updateData: Prisma.VehicleUpdateInput = {};

    if (dto.serviceType.toLowerCase().includes('oil')) {
      updateData.lastOilChangeDate = dto.serviceDate;
      updateData.lastOilChangeMileage = dto.mileageAtService;
    }

    if (dto.serviceType.toLowerCase().includes('tire') && dto.serviceType.toLowerCase().includes('rotation')) {
      updateData.lastTireRotationDate = dto.serviceDate;
      updateData.lastTireRotationMileage = dto.mileageAtService;
    }

    if (dto.mileageAtService && (!vehicle.currentMileage || dto.mileageAtService > vehicle.currentMileage)) {
      updateData.currentMileage = dto.mileageAtService;
      updateData.lastMileageUpdate = new Date();
    }

    if (Object.keys(updateData).length > 0) {
      await this.prisma.vehicle.update({
        where: { id: vehicleId },
        data: updateData,
      });
    }

    return record;
  }

  /**
   * Get service records for a vehicle
   */
  async getServiceRecords(vehicleId: string, householdId: string) {
    await this.findOne(vehicleId, householdId);

    return this.prisma.vehicleServiceRecord.findMany({
      where: { vehicleId },
      include: {
        vendor: {
          select: { id: true, displayName: true },
        },
      },
      orderBy: { serviceDate: 'desc' },
    });
  }

  /**
   * Check for upcoming maintenance needs
   */
  async getMaintenanceAlerts(householdId: string) {
    const vehicles = await this.prisma.vehicle.findMany({
      where: {
        householdId,
        isActive: true,
      },
    });

    const alerts: Array<{
      vehicleId: string;
      vehicleName: string;
      type: string;
      message: string;
      severity: 'low' | 'medium' | 'high';
    }> = [];

    const now = new Date();

    for (const vehicle of vehicles) {
      const vehicleName = vehicle.nickname || `${vehicle.year} ${vehicle.make} ${vehicle.model}`;

      // Check oil change
      if (vehicle.lastOilChangeDate && vehicle.oilChangeIntervalMonths) {
        const monthsSinceOilChange = (now.getTime() - vehicle.lastOilChangeDate.getTime()) / (1000 * 60 * 60 * 24 * 30);
        if (monthsSinceOilChange >= vehicle.oilChangeIntervalMonths) {
          alerts.push({
            vehicleId: vehicle.id,
            vehicleName,
            type: 'OIL_CHANGE',
            message: `Oil change overdue (last: ${vehicle.lastOilChangeDate.toLocaleDateString()})`,
            severity: 'high',
          });
        } else if (monthsSinceOilChange >= vehicle.oilChangeIntervalMonths - 1) {
          alerts.push({
            vehicleId: vehicle.id,
            vehicleName,
            type: 'OIL_CHANGE',
            message: `Oil change due soon`,
            severity: 'medium',
          });
        }
      }

      // Check mileage-based oil change
      if (vehicle.currentMileage && vehicle.lastOilChangeMileage && vehicle.oilChangeIntervalMiles) {
        const milesSinceOilChange = vehicle.currentMileage - vehicle.lastOilChangeMileage;
        if (milesSinceOilChange >= vehicle.oilChangeIntervalMiles) {
          alerts.push({
            vehicleId: vehicle.id,
            vehicleName,
            type: 'OIL_CHANGE_MILEAGE',
            message: `Oil change overdue by mileage (${milesSinceOilChange.toLocaleString()} miles since last)`,
            severity: 'high',
          });
        }
      }

      // Check registration
      if (vehicle.registrationExpires) {
        const daysUntilExpiry = (vehicle.registrationExpires.getTime() - now.getTime()) / (1000 * 60 * 60 * 24);
        if (daysUntilExpiry <= 0) {
          alerts.push({
            vehicleId: vehicle.id,
            vehicleName,
            type: 'REGISTRATION',
            message: `Registration expired`,
            severity: 'high',
          });
        } else if (daysUntilExpiry <= 30) {
          alerts.push({
            vehicleId: vehicle.id,
            vehicleName,
            type: 'REGISTRATION',
            message: `Registration expires in ${Math.ceil(daysUntilExpiry)} days`,
            severity: 'medium',
          });
        }
      }

      // Check insurance
      if (vehicle.insuranceExpires) {
        const daysUntilExpiry = (vehicle.insuranceExpires.getTime() - now.getTime()) / (1000 * 60 * 60 * 24);
        if (daysUntilExpiry <= 0) {
          alerts.push({
            vehicleId: vehicle.id,
            vehicleName,
            type: 'INSURANCE',
            message: `Insurance expired`,
            severity: 'high',
          });
        } else if (daysUntilExpiry <= 30) {
          alerts.push({
            vehicleId: vehicle.id,
            vehicleName,
            type: 'INSURANCE',
            message: `Insurance expires in ${Math.ceil(daysUntilExpiry)} days`,
            severity: 'medium',
          });
        }
      }

      // Check inspection
      if (vehicle.inspectionExpires) {
        const daysUntilExpiry = (vehicle.inspectionExpires.getTime() - now.getTime()) / (1000 * 60 * 60 * 24);
        if (daysUntilExpiry <= 0) {
          alerts.push({
            vehicleId: vehicle.id,
            vehicleName,
            type: 'INSPECTION',
            message: `Inspection expired`,
            severity: 'high',
          });
        } else if (daysUntilExpiry <= 30) {
          alerts.push({
            vehicleId: vehicle.id,
            vehicleName,
            type: 'INSPECTION',
            message: `Inspection expires in ${Math.ceil(daysUntilExpiry)} days`,
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
