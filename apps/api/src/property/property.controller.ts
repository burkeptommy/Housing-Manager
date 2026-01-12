import { Controller, Get, Post, Put, Delete, Body, Query, Param, UseGuards, NotFoundException } from '@nestjs/common';
import { FirebaseAuthGuard } from '../firebase';
import { PropertyService, PropertyLookupResult, PropertyDetails } from './property.service';
import { ChecklistGeneratorService, ChecklistItem } from './checklist-generator.service';
import { PrismaService } from '../prisma/prisma.service';
import { CreateZoneDto, UpdateZoneDto, CreateAssetDto, UpdateAssetDto } from './dto';

interface GenerateChecklistRequest {
  street: string;
  city: string;
  state: string;
  zip: string;
  propertyData?: PropertyDetails;
}

interface GenerateChecklistResponse {
  success: boolean;
  checklist: ChecklistItem[];
  summary: {
    totalQuestions: number;
    highPriority: number;
    categories: string[];
    highlights: string[];
  };
  error?: string;
}

@Controller('property')
@UseGuards(FirebaseAuthGuard)
export class PropertyController {
  constructor(
    private readonly propertyService: PropertyService,
    private readonly checklistGeneratorService: ChecklistGeneratorService,
    private readonly prisma: PrismaService,
  ) {}

  /**
   * Get property with zones and assets for homeowner view
   */
  @Get('household/:householdId')
  async getPropertyWithZones(@Param('householdId') householdId: string) {
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      include: {
        homeProfile: true,
        zones: {
          include: {
            assets: {
              where: { isActive: true },
              include: {
                serviceVendor: {
                  select: { id: true, displayName: true, phone: true },
                },
              },
              orderBy: { name: 'asc' },
            },
          },
          orderBy: { sortOrder: 'asc' },
        },
      },
    });

    if (!household) {
      throw new NotFoundException('Household not found');
    }

    const enrichmentData = household.enrichmentData as Record<string, any> | null;
    const homeProfile = household.homeProfile;

    // Calculate systems status from enrichment data
    const systems = this.getSystemsStatus(enrichmentData);

    return {
      property: {
        id: household.id,
        name: household.name,
        address: homeProfile ? {
          street: homeProfile.addressLine1,
          city: homeProfile.city,
          state: homeProfile.state,
          zip: homeProfile.postalCode,
          full: `${homeProfile.addressLine1}, ${homeProfile.city}, ${homeProfile.state} ${homeProfile.postalCode}`,
        } : null,
        details: {
          bedrooms: enrichmentData?.bedrooms ?? null,
          bathrooms: enrichmentData?.bathrooms ?? null,
          squareFeet: enrichmentData?.squareFeet ?? null,
          yearBuilt: enrichmentData?.yearBuilt ?? null,
          lotSize: enrichmentData?.lotSizeAcres ?? null,
          propertyType: homeProfile?.propertyType ?? null,
        },
        enrichment: enrichmentData,
      },
      systems,
      zones: household.zones.map(zone => ({
        id: zone.id,
        name: zone.name,
        type: zone.type,
        floor: zone.floor,
        assetCount: zone.assets.length,
        photos: zone.photos,
        notes: zone.notes,
        procedures: zone.procedures,
        assets: zone.assets.map(asset => ({
          id: asset.id,
          name: asset.name,
          category: asset.category,
          brand: asset.brand,
          model: asset.model,
          serialNumber: asset.serialNumber,
          condition: asset.condition,
          lastServiceDate: asset.lastServiceDate,
          nextServiceDate: asset.nextServiceDate,
          serviceVendor: asset.serviceVendor?.displayName ?? null,
          notes: asset.notes,
        })),
      })),
    };
  }

  /**
   * Get a single zone with its assets
   */
  @Get('zones/:zoneId')
  async getZone(@Param('zoneId') zoneId: string) {
    const zone = await this.prisma.zone.findUnique({
      where: { id: zoneId },
      include: {
        assets: {
          where: { isActive: true },
          include: {
            serviceVendor: {
              select: { id: true, displayName: true, phone: true },
            },
          },
          orderBy: { name: 'asc' },
        },
      },
    });

    if (!zone) {
      throw new NotFoundException('Zone not found');
    }

    return {
      id: zone.id,
      name: zone.name,
      type: zone.type,
      floor: zone.floor,
      photos: zone.photos,
      notes: zone.notes,
      procedures: zone.procedures,
      assets: zone.assets.map(asset => ({
        id: asset.id,
        name: asset.name,
        category: asset.category,
        brand: asset.brand,
        model: asset.model,
        serialNumber: asset.serialNumber,
        condition: asset.condition,
        lastServiceDate: asset.lastServiceDate,
        nextServiceDate: asset.nextServiceDate,
        serviceVendor: asset.serviceVendor?.displayName ?? null,
        notes: asset.notes,
      })),
    };
  }

  // ==========================================================================
  // ZONE CRUD
  // ==========================================================================

  /**
   * Create a new zone
   */
  @Post('zones/household/:householdId')
  async createZone(
    @Param('householdId') householdId: string,
    @Body() dto: CreateZoneDto,
  ) {
    // Verify household exists
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
    });

    if (!household) {
      throw new NotFoundException('Household not found');
    }

    const zone = await this.prisma.zone.create({
      data: {
        householdId,
        name: dto.name,
        type: dto.type,
        floor: dto.floor,
        photos: dto.photos ?? [],
        notes: dto.notes,
        procedures: dto.procedures,
        sortOrder: dto.sortOrder ?? 0,
      },
    });

    return {
      id: zone.id,
      name: zone.name,
      type: zone.type,
      floor: zone.floor,
      photos: zone.photos,
      notes: zone.notes,
      procedures: zone.procedures,
      sortOrder: zone.sortOrder,
    };
  }

  /**
   * Update a zone
   */
  @Put('zones/:zoneId')
  async updateZone(
    @Param('zoneId') zoneId: string,
    @Body() dto: UpdateZoneDto,
  ) {
    const existingZone = await this.prisma.zone.findUnique({
      where: { id: zoneId },
    });

    if (!existingZone) {
      throw new NotFoundException('Zone not found');
    }

    const zone = await this.prisma.zone.update({
      where: { id: zoneId },
      data: {
        name: dto.name,
        type: dto.type,
        floor: dto.floor,
        photos: dto.photos,
        notes: dto.notes,
        procedures: dto.procedures,
        sortOrder: dto.sortOrder,
      },
    });

    return {
      id: zone.id,
      name: zone.name,
      type: zone.type,
      floor: zone.floor,
      photos: zone.photos,
      notes: zone.notes,
      procedures: zone.procedures,
      sortOrder: zone.sortOrder,
    };
  }

  /**
   * Delete a zone
   */
  @Delete('zones/:zoneId')
  async deleteZone(@Param('zoneId') zoneId: string) {
    const existingZone = await this.prisma.zone.findUnique({
      where: { id: zoneId },
    });

    if (!existingZone) {
      throw new NotFoundException('Zone not found');
    }

    await this.prisma.zone.delete({
      where: { id: zoneId },
    });

    return { success: true };
  }

  // ==========================================================================
  // PROPERTY ASSET CRUD
  // ==========================================================================

  /**
   * Get all assets for a household
   */
  @Get('assets/household/:householdId')
  async getHouseholdAssets(@Param('householdId') householdId: string) {
    const assets = await this.prisma.propertyAsset.findMany({
      where: {
        householdId,
        isActive: true,
      },
      include: {
        zone: {
          select: { id: true, name: true, type: true },
        },
        serviceVendor: {
          select: { id: true, displayName: true, phone: true },
        },
      },
      orderBy: { name: 'asc' },
    });

    return assets.map(asset => ({
      id: asset.id,
      name: asset.name,
      category: asset.category,
      zone: asset.zone ? { id: asset.zone.id, name: asset.zone.name, type: asset.zone.type } : null,
      brand: asset.brand,
      model: asset.model,
      serialNumber: asset.serialNumber,
      color: asset.color,
      condition: asset.condition,
      conditionNotes: asset.conditionNotes,
      purchaseDate: asset.purchaseDate,
      purchasePrice: asset.purchasePrice,
      purchaseVendor: asset.purchaseVendor,
      warrantyExpires: asset.warrantyExpires,
      warrantyNotes: asset.warrantyNotes,
      lastServiceDate: asset.lastServiceDate,
      nextServiceDate: asset.nextServiceDate,
      serviceInterval: asset.serviceInterval,
      serviceVendor: asset.serviceVendor?.displayName ?? null,
      photos: asset.photos,
      manualUrl: asset.manualUrl,
      notes: asset.notes,
    }));
  }

  /**
   * Get a single asset
   */
  @Get('assets/:assetId')
  async getAsset(@Param('assetId') assetId: string) {
    const asset = await this.prisma.propertyAsset.findUnique({
      where: { id: assetId },
      include: {
        zone: {
          select: { id: true, name: true, type: true },
        },
        serviceVendor: {
          select: { id: true, displayName: true, phone: true },
        },
      },
    });

    if (!asset) {
      throw new NotFoundException('Asset not found');
    }

    return {
      id: asset.id,
      name: asset.name,
      category: asset.category,
      zone: asset.zone ? { id: asset.zone.id, name: asset.zone.name, type: asset.zone.type } : null,
      brand: asset.brand,
      model: asset.model,
      serialNumber: asset.serialNumber,
      color: asset.color,
      condition: asset.condition,
      conditionNotes: asset.conditionNotes,
      purchaseDate: asset.purchaseDate,
      purchasePrice: asset.purchasePrice,
      purchaseVendor: asset.purchaseVendor,
      warrantyExpires: asset.warrantyExpires,
      warrantyNotes: asset.warrantyNotes,
      lastServiceDate: asset.lastServiceDate,
      nextServiceDate: asset.nextServiceDate,
      serviceInterval: asset.serviceInterval,
      serviceVendorId: asset.serviceVendorId,
      serviceVendor: asset.serviceVendor?.displayName ?? null,
      photos: asset.photos,
      manualUrl: asset.manualUrl,
      notes: asset.notes,
    };
  }

  /**
   * Create a new asset
   */
  @Post('assets/household/:householdId')
  async createAsset(
    @Param('householdId') householdId: string,
    @Body() dto: CreateAssetDto,
  ) {
    // Verify household exists
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
    });

    if (!household) {
      throw new NotFoundException('Household not found');
    }

    // Verify zone exists if provided
    if (dto.zoneId) {
      const zone = await this.prisma.zone.findUnique({
        where: { id: dto.zoneId },
      });
      if (!zone || zone.householdId !== householdId) {
        throw new NotFoundException('Zone not found in this household');
      }
    }

    const asset = await this.prisma.propertyAsset.create({
      data: {
        householdId,
        zoneId: dto.zoneId,
        name: dto.name,
        category: dto.category,
        brand: dto.brand,
        model: dto.model,
        serialNumber: dto.serialNumber,
        color: dto.color,
        purchaseDate: dto.purchaseDate,
        purchasePrice: dto.purchasePrice,
        purchaseVendor: dto.purchaseVendor,
        warrantyExpires: dto.warrantyExpires,
        warrantyNotes: dto.warrantyNotes,
        condition: dto.condition,
        conditionNotes: dto.conditionNotes,
        serviceVendorId: dto.serviceVendorId,
        lastServiceDate: dto.lastServiceDate,
        nextServiceDate: dto.nextServiceDate,
        serviceInterval: dto.serviceInterval,
        photos: dto.photos ?? [],
        manualUrl: dto.manualUrl,
        notes: dto.notes,
      },
      include: {
        zone: {
          select: { id: true, name: true, type: true },
        },
      },
    });

    return {
      id: asset.id,
      name: asset.name,
      category: asset.category,
      zone: asset.zone ? { id: asset.zone.id, name: asset.zone.name, type: asset.zone.type } : null,
      brand: asset.brand,
      model: asset.model,
      serialNumber: asset.serialNumber,
      color: asset.color,
      condition: asset.condition,
      notes: asset.notes,
    };
  }

  /**
   * Update an asset
   */
  @Put('assets/:assetId')
  async updateAsset(
    @Param('assetId') assetId: string,
    @Body() dto: UpdateAssetDto,
  ) {
    const existingAsset = await this.prisma.propertyAsset.findUnique({
      where: { id: assetId },
    });

    if (!existingAsset) {
      throw new NotFoundException('Asset not found');
    }

    // Verify zone exists if provided
    if (dto.zoneId) {
      const zone = await this.prisma.zone.findUnique({
        where: { id: dto.zoneId },
      });
      if (!zone || zone.householdId !== existingAsset.householdId) {
        throw new NotFoundException('Zone not found in this household');
      }
    }

    const asset = await this.prisma.propertyAsset.update({
      where: { id: assetId },
      data: {
        zoneId: dto.zoneId,
        name: dto.name,
        category: dto.category,
        brand: dto.brand,
        model: dto.model,
        serialNumber: dto.serialNumber,
        color: dto.color,
        purchaseDate: dto.purchaseDate,
        purchasePrice: dto.purchasePrice,
        purchaseVendor: dto.purchaseVendor,
        warrantyExpires: dto.warrantyExpires,
        warrantyNotes: dto.warrantyNotes,
        condition: dto.condition,
        conditionNotes: dto.conditionNotes,
        serviceVendorId: dto.serviceVendorId,
        lastServiceDate: dto.lastServiceDate,
        nextServiceDate: dto.nextServiceDate,
        serviceInterval: dto.serviceInterval,
        photos: dto.photos,
        manualUrl: dto.manualUrl,
        notes: dto.notes,
        isActive: dto.isActive,
      },
      include: {
        zone: {
          select: { id: true, name: true, type: true },
        },
      },
    });

    return {
      id: asset.id,
      name: asset.name,
      category: asset.category,
      zone: asset.zone ? { id: asset.zone.id, name: asset.zone.name, type: asset.zone.type } : null,
      brand: asset.brand,
      model: asset.model,
      serialNumber: asset.serialNumber,
      color: asset.color,
      condition: asset.condition,
      notes: asset.notes,
    };
  }

  /**
   * Delete an asset (soft delete)
   */
  @Delete('assets/:assetId')
  async deleteAsset(@Param('assetId') assetId: string) {
    const existingAsset = await this.prisma.propertyAsset.findUnique({
      where: { id: assetId },
    });

    if (!existingAsset) {
      throw new NotFoundException('Asset not found');
    }

    // Soft delete by setting isActive to false
    await this.prisma.propertyAsset.update({
      where: { id: assetId },
      data: { isActive: false },
    });

    return { success: true };
  }

  /**
   * Get systems status from enrichment data
   */
  private getSystemsStatus(enrichmentData: Record<string, any> | null) {
    const systems: Array<{
      id: string;
      name: string;
      category: string;
      status: 'good' | 'warning' | 'attention';
      warning?: string;
    }> = [];

    if (!enrichmentData) return systems;

    // HVAC
    if (enrichmentData.heatingType || enrichmentData.coolingType) {
      systems.push({
        id: 'hvac',
        name: 'HVAC',
        category: 'HVAC',
        status: 'good',
      });
    }

    // Plumbing
    if (enrichmentData.waterType) {
      systems.push({
        id: 'plumbing',
        name: 'Plumbing',
        category: 'PLUMBING',
        status: 'good',
      });
    }

    // Electrical
    systems.push({
      id: 'electrical',
      name: 'Electrical',
      category: 'ELECTRICAL',
      status: 'good',
    });

    // Roof
    if (enrichmentData.roofType || enrichmentData.roofMaterial) {
      const yearBuilt = enrichmentData.yearBuilt;
      const roofAge = yearBuilt ? new Date().getFullYear() - yearBuilt : 0;
      systems.push({
        id: 'roof',
        name: 'Roof',
        category: 'ROOF',
        status: roofAge > 20 ? 'warning' : 'good',
        warning: roofAge > 20 ? `${roofAge} years old` : undefined,
      });
    }

    // Pool
    if (enrichmentData.pool) {
      systems.push({
        id: 'pool',
        name: 'Pool',
        category: 'POOL',
        status: 'good',
      });
    }

    return systems;
  }

  @Get('lookup')
  async lookupProperty(
    @Query('street') street: string,
    @Query('city') city: string,
    @Query('state') state: string,
    @Query('zip') zip: string,
  ): Promise<PropertyLookupResult> {
    if (!street || !city || !state || !zip) {
      return {
        success: false,
        data: null,
        error: 'street, city, state, and zip are required',
      };
    }

    return this.propertyService.lookupByAddress(street, city, state, zip);
  }

  /**
   * Generate a smart checklist for a property based on ATTOM data.
   * If propertyData is not provided, we'll fetch it from ATTOM.
   */
  @Post('checklist/generate')
  async generateChecklist(
    @Body() data: GenerateChecklistRequest,
  ): Promise<GenerateChecklistResponse> {
    const { street, city, state, zip, propertyData } = data;

    if (!street || !city || !state || !zip) {
      return {
        success: false,
        checklist: [],
        summary: { totalQuestions: 0, highPriority: 0, categories: [], highlights: [] },
        error: 'street, city, state, and zip are required',
      };
    }

    try {
      // Use provided property data or fetch from ATTOM
      let property: PropertyDetails | null = propertyData || null;

      if (!property) {
        const lookupResult = await this.propertyService.lookupByAddress(
          street,
          city,
          state,
          zip,
        );
        property = lookupResult.data;
      }

      // Generate checklist even if we don't have property data
      // (will just use default questions)
      const checklist = this.checklistGeneratorService.generateChecklist(
        property || {} as PropertyDetails,
        state,
        city,
      );

      const summary = this.checklistGeneratorService.getChecklistSummary(
        property || {} as PropertyDetails,
      );

      return {
        success: true,
        checklist,
        summary,
      };
    } catch (error: any) {
      return {
        success: false,
        checklist: [],
        summary: { totalQuestions: 0, highPriority: 0, categories: [], highlights: [] },
        error: error.message || 'Failed to generate checklist',
      };
    }
  }

  /**
   * Get a checklist preview (summary only) without generating the full checklist
   */
  @Get('checklist/preview')
  async getChecklistPreview(
    @Query('street') street: string,
    @Query('city') city: string,
    @Query('state') state: string,
    @Query('zip') zip: string,
  ): Promise<{
    success: boolean;
    summary?: {
      totalQuestions: number;
      highPriority: number;
      categories: string[];
      highlights: string[];
    };
    error?: string;
  }> {
    if (!street || !city || !state || !zip) {
      return {
        success: false,
        error: 'street, city, state, and zip are required',
      };
    }

    try {
      const lookupResult = await this.propertyService.lookupByAddress(
        street,
        city,
        state,
        zip,
      );

      const summary = this.checklistGeneratorService.getChecklistSummary(
        lookupResult.data || {} as PropertyDetails,
      );

      return {
        success: true,
        summary,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message || 'Failed to get checklist preview',
      };
    }
  }
}
