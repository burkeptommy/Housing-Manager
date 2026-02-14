import { Injectable, Logger, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateVehicleDto, UpdateVehicleDto, CreateVehicleServiceRecordDto } from '../dto';
import { Prisma, VehicleServiceType } from '@prisma/client';

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
        name: dto.nickname || `${dto.year} ${dto.make} ${dto.model}`,
        make: dto.make,
        model: dto.model,
        year: dto.year,
        vehicleType: dto.type,
        color: dto.color,
        licensePlate: dto.licensePlate,
        vin: dto.vin,
        currentMileage: dto.currentMileage,
        insuranceProvider: dto.insuranceProvider,
        insurancePolicyNum: dto.insurancePolicyNum,
        insuranceExpiry: dto.insuranceExpiry,
        registrationExpiry: dto.registrationExpiry,
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
        services: {
          orderBy: { serviceDate: 'desc' },
          take: 5,
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
        services: {
          orderBy: { serviceDate: 'desc' },
        },
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
        ...(dto.nickname !== undefined && { name: dto.nickname }),
        ...(dto.make !== undefined && { make: dto.make }),
        ...(dto.model !== undefined && { model: dto.model }),
        ...(dto.year !== undefined && { year: dto.year }),
        ...(dto.type !== undefined && { vehicleType: dto.type }),
        ...(dto.color !== undefined && { color: dto.color }),
        ...(dto.licensePlate !== undefined && { licensePlate: dto.licensePlate }),
        ...(dto.vin !== undefined && { vin: dto.vin }),
        ...(dto.currentMileage !== undefined && { currentMileage: dto.currentMileage }),
        ...(dto.insuranceProvider !== undefined && { insuranceProvider: dto.insuranceProvider }),
        ...(dto.insurancePolicyNum !== undefined && { insurancePolicyNum: dto.insurancePolicyNum }),
        ...(dto.insuranceExpiry !== undefined && { insuranceExpiry: dto.insuranceExpiry }),
        ...(dto.registrationExpiry !== undefined && { registrationExpiry: dto.registrationExpiry }),
        ...(dto.lastOilChange !== undefined && { lastOilChange: dto.lastOilChange }),
        ...(dto.oilChangeMileage !== undefined && { oilChangeMileage: dto.oilChangeMileage }),
        ...(dto.preferredServiceShop !== undefined && { preferredServiceShop: dto.preferredServiceShop }),
        ...(dto.photoUrl !== undefined && { photoUrl: dto.photoUrl }),
        ...(dto.registrationState !== undefined && { registrationState: dto.registrationState }),
        mileageUpdatedAt: dto.currentMileage ? new Date() : undefined,
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

    const record = await this.prisma.vehicleService.create({
      data: {
        vehicleId,
        serviceDate: dto.serviceDate,
        serviceType: dto.serviceType as VehicleServiceType,
        description: dto.description,
        mileageAt: dto.mileageAt,
        cost: dto.cost ? new Prisma.Decimal(dto.cost) : undefined,
        shopName: dto.shopName,
        receiptUrl: dto.receiptUrl,
        nextServiceDate: dto.nextServiceDate,
        nextServiceMileage: dto.nextServiceMileage,
        notes: dto.notes,
      },
    });

    // Update vehicle with latest service info if applicable
    const updateData: Prisma.VehicleUpdateInput = {};

    if (dto.serviceType.toLowerCase().includes('oil')) {
      updateData.lastOilChange = dto.serviceDate;
      updateData.oilChangeMileage = dto.mileageAt;
    }

    if (dto.mileageAt && (!vehicle.currentMileage || dto.mileageAt > vehicle.currentMileage)) {
      updateData.currentMileage = dto.mileageAt;
      updateData.mileageUpdatedAt = new Date();
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

    return this.prisma.vehicleService.findMany({
      where: { vehicleId },
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
      const vehicleName = vehicle.name || `${vehicle.year} ${vehicle.make} ${vehicle.model}`;

      // Check oil change (time-based using last service records)
      if (vehicle.lastOilChange) {
        const monthsSinceOilChange = (now.getTime() - vehicle.lastOilChange.getTime()) / (1000 * 60 * 60 * 24 * 30);
        // Default to 6-month oil change interval if AI schedule hasn't been researched
        const intervalMonths = 6;
        if (monthsSinceOilChange >= intervalMonths) {
          alerts.push({
            vehicleId: vehicle.id,
            vehicleName,
            type: 'OIL_CHANGE',
            message: `Oil change overdue (last: ${vehicle.lastOilChange.toLocaleDateString()})`,
            severity: 'high',
          });
        } else if (monthsSinceOilChange >= intervalMonths - 1) {
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
      if (vehicle.currentMileage && vehicle.oilChangeMileage) {
        const milesSinceOilChange = vehicle.currentMileage - vehicle.oilChangeMileage;
        // Default to 5000 mile interval
        const intervalMiles = 5000;
        if (milesSinceOilChange >= intervalMiles) {
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
      if (vehicle.registrationExpiry) {
        const daysUntilExpiry = (vehicle.registrationExpiry.getTime() - now.getTime()) / (1000 * 60 * 60 * 24);
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
      if (vehicle.insuranceExpiry) {
        const daysUntilExpiry = (vehicle.insuranceExpiry.getTime() - now.getTime()) / (1000 * 60 * 60 * 24);
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
    }

    return alerts.sort((a, b) => {
      const severityOrder = { high: 0, medium: 1, low: 2 };
      return severityOrder[a.severity] - severityOrder[b.severity];
    });
  }
}
