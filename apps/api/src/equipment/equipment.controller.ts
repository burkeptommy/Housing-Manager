import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { EquipmentService } from './equipment.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { HomeSystemType } from '@prisma/client';
import { SYSTEM_CATEGORIES, COMMON_MANUFACTURERS } from './system-categories';

@Controller('equipment')
@UseGuards(JwtAuthGuard)
export class EquipmentController {
  constructor(private equipmentService: EquipmentService) {}

  /**
   * Get available system categories and types
   */
  @Get('categories')
  getCategories() {
    return {
      categories: SYSTEM_CATEGORIES,
      manufacturers: COMMON_MANUFACTURERS,
      types: Object.values(HomeSystemType),
    };
  }

  /**
   * Add a new home system
   */
  @Post('systems')
  async addSystem(
    @Request() req: any,
    @Body()
    body: {
      type: HomeSystemType;
      name: string;
      brand?: string;
      model?: string;
      modelNumber?: string;
      serialNumber?: string;
      installedDate?: string;
      purchaseDate?: string;
      location?: string;
      lastMaintenanceDate?: string;
      warrantyExpires?: string;
    },
  ) {
    const householdId = req.user.householdId;

    if (!householdId) {
      return { error: 'No household found' };
    }

    return this.equipmentService.addSystem({
      householdId,
      type: body.type,
      name: body.name,
      brand: body.brand,
      model: body.model,
      modelNumber: body.modelNumber,
      serialNumber: body.serialNumber,
      installedDate: body.installedDate ? new Date(body.installedDate) : undefined,
      purchaseDate: body.purchaseDate ? new Date(body.purchaseDate) : undefined,
      location: body.location,
      lastMaintenanceDate: body.lastMaintenanceDate
        ? new Date(body.lastMaintenanceDate)
        : undefined,
      warrantyExpires: body.warrantyExpires ? new Date(body.warrantyExpires) : undefined,
    });
  }

  /**
   * Get all systems for household
   */
  @Get('systems')
  async getSystems(@Request() req: any) {
    const householdId = req.user.householdId;

    if (!householdId) {
      return { error: 'No household found', systems: [] };
    }

    return this.equipmentService.getSystems(householdId);
  }

  /**
   * Get systems due for service soon
   */
  @Get('systems/due-soon')
  async getSystemsDueSoon(
    @Request() req: any,
    @Query('days') days?: string,
  ) {
    const householdId = req.user.householdId;

    if (!householdId) {
      return { error: 'No household found', systems: [] };
    }

    return this.equipmentService.getSystemsDueSoon(
      householdId,
      days ? parseInt(days, 10) : 30,
    );
  }

  /**
   * Get a specific system
   */
  @Get('systems/:id')
  async getSystem(@Param('id') id: string) {
    return this.equipmentService.getSystemById(id);
  }

  /**
   * Update a system
   */
  @Patch('systems/:id')
  async updateSystem(
    @Param('id') id: string,
    @Body()
    body: {
      name?: string;
      brand?: string;
      model?: string;
      modelNumber?: string;
      serialNumber?: string;
      location?: string;
      installedDate?: string;
      purchaseDate?: string;
      warrantyExpires?: string;
    },
  ) {
    return this.equipmentService.updateSystem(id, {
      name: body.name,
      brand: body.brand,
      model: body.model,
      modelNumber: body.modelNumber,
      serialNumber: body.serialNumber,
      location: body.location,
      installedDate: body.installedDate ? new Date(body.installedDate) : undefined,
      purchaseDate: body.purchaseDate ? new Date(body.purchaseDate) : undefined,
      warrantyExpires: body.warrantyExpires ? new Date(body.warrantyExpires) : undefined,
    });
  }

  /**
   * Deactivate a system
   */
  @Delete('systems/:id')
  async deactivateSystem(@Param('id') id: string) {
    return this.equipmentService.deactivateSystem(id);
  }

  /**
   * Record service for a system
   */
  @Post('systems/:id/service')
  async recordService(
    @Param('id') id: string,
    @Body()
    body: {
      serviceDate: string;
      serviceType: string;
      description?: string;
      performedBy?: string;
      cost?: number;
      vendorId?: string;
    },
  ) {
    return this.equipmentService.recordService(
      id,
      new Date(body.serviceDate),
      body.serviceType,
      body.description,
      body.performedBy,
      body.cost,
      body.vendorId,
    );
  }
}
