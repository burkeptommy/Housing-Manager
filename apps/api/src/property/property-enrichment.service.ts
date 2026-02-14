import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { PropertyDetails } from './property.service';
import {
  getUtilityProviders,
  inferSewerType,
  inferWaterSource,
} from '../utilities/utility-providers';

@Injectable()
export class PropertyEnrichmentService {
  private readonly logger = new Logger(PropertyEnrichmentService.name);

  constructor(private prisma: PrismaService) {}

  async enrichHouseholdFromPropertyData(householdId: string, propertyData: PropertyDetails) {
    // Extract all available property data
    const enrichedData: any = {
      attomDataFetched: true,
    };

    // Get the home profile for this household
    const homeProfile = await this.prisma.homeProfile.findUnique({
      where: { householdId },
    });

    // Update HomeProfile with property data if it exists
    if (homeProfile) {
      const profileUpdates: any = {};

      if (propertyData.yearBuilt) {
        profileUpdates.yearBuilt = propertyData.yearBuilt;
      }
      if (propertyData.squareFeet) {
        profileUpdates.squareFeet = propertyData.squareFeet;
      }
      if (propertyData.lotSizeAcres) {
        profileUpdates.lotSize = propertyData.lotSizeAcres;
      }
      if (propertyData.bedrooms) {
        profileUpdates.bedrooms = propertyData.bedrooms;
      }
      if (propertyData.bathrooms) {
        profileUpdates.bathrooms = propertyData.bathrooms;
      }
      if (propertyData.stories) {
        profileUpdates.stories = propertyData.stories;
      }
      if (propertyData.garageSpaces) {
        profileUpdates.garageSpaces = propertyData.garageSpaces;
      }

      if (Object.keys(profileUpdates).length > 0) {
        await this.prisma.homeProfile.update({
          where: { householdId },
          data: profileUpdates,
        });
      }
    }

    // Extract heating/cooling info for household
    const heatingFuel = this.mapHeatingFuel(propertyData.heatingFuel);
    if (heatingFuel) {
      enrichedData.heatingFuel = heatingFuel;
    }

    // Get utility providers based on location
    if (homeProfile) {
      const utilities = getUtilityProviders(
        homeProfile.postalCode,
        homeProfile.city,
        homeProfile.state,
      );
      enrichedData.electricityProvider = utilities.electricity;
      if (heatingFuel === 'natural-gas') {
        enrichedData.gasProvider = utilities.gas;
      }

      // Use property data sewer/water if available, otherwise infer
      if (propertyData.sewerType) {
        enrichedData.sewerType = propertyData.sewerType.toLowerCase().includes('septic')
          ? 'septic' : 'municipal';
      } else {
        const lotSize = homeProfile.lotSize;
        const sewerInference = inferSewerType(
          lotSize,
          homeProfile.city,
          homeProfile.postalCode,
        );
        if (sewerInference.confidence >= 0.7) {
          enrichedData.sewerType = sewerInference.type;
        }
      }

      if (propertyData.waterType) {
        enrichedData.waterSource = propertyData.waterType.toLowerCase().includes('well')
          ? 'well' : 'municipal';
      } else {
        const lotSize = homeProfile.lotSize;
        const waterInference = inferWaterSource(
          lotSize,
          homeProfile.city,
          enrichedData.sewerType || 'unknown',
        );
        if (waterInference.confidence >= 0.7) {
          enrichedData.waterSource = waterInference.type;
        }
      }
    }

    // Store property data as enrichment data
    enrichedData.enrichmentData = propertyData;

    // Update household with enriched data
    await this.prisma.household.update({
      where: { id: householdId },
      data: enrichedData,
    });

    // Auto-generate zones and systems
    if (homeProfile) {
      await this.autoGenerateZonesAndSystems(householdId, homeProfile);
    }

    // Identify data gaps for Alfred to ask about
    const dataGaps = this.identifyDataGaps(enrichedData);
    await this.prisma.household.update({
      where: { id: householdId },
      data: { alfredDataGaps: dataGaps },
    });

    return enrichedData;
  }

  async autoGenerateZonesAndSystems(householdId: string, homeProfile: any) {
    // Check if zones already exist
    const existingZones = await this.prisma.zone.count({
      where: { householdId },
    });
    if (existingZones > 0) {
      this.logger.log('Zones already exist, skipping auto-generation');
      return;
    }

    const zones: any[] = [];

    // Always create these zones
    zones.push({
      name: 'Kitchen',
      type: 'KITCHEN',
      floor: '1st Floor',
    });
    zones.push({
      name: 'Living Room',
      type: 'LIVING_ROOM',
      floor: '1st Floor',
    });
    zones.push({
      name: 'Exterior',
      type: 'EXTERIOR',
      floor: null,
    });
    zones.push({
      name: 'Basement',
      type: 'BASEMENT',
      floor: 'Basement',
    });

    // Bedrooms based on count
    const bedrooms = homeProfile.bedrooms || 3;
    zones.push({
      name: 'Primary Bedroom',
      type: 'BEDROOM',
      floor: '2nd Floor',
    });
    for (let i = 2; i <= Math.min(bedrooms, 6); i++) {
      zones.push({
        name: `Bedroom ${i}`,
        type: 'BEDROOM',
        floor: '2nd Floor',
      });
    }

    // Bathrooms based on count
    const bathrooms = Math.floor(homeProfile.bathrooms || 2);
    zones.push({
      name: 'Primary Bathroom',
      type: 'BATHROOM',
      floor: '2nd Floor',
    });
    for (let i = 2; i <= Math.min(bathrooms, 5); i++) {
      const floor = i <= 2 ? '1st Floor' : '2nd Floor';
      zones.push({
        name: `Bathroom ${i}`,
        type: 'BATHROOM',
        floor,
      });
    }

    // Garage if present
    if (homeProfile.garageSpaces && homeProfile.garageSpaces > 0) {
      zones.push({
        name: `${homeProfile.garageSpaces}-Car Garage`,
        type: 'GARAGE',
        floor: '1st Floor',
      });
    }

    // Create zones in database
    const createdZones: Record<string, string> = {};
    for (let i = 0; i < zones.length; i++) {
      const zone = zones[i];
      const created = await this.prisma.zone.create({
        data: {
          householdId,
          ...zone,
          sortOrder: i,
        },
      });
      createdZones[zone.type] = created.id;
    }

    // Auto-generate property assets (systems) based on property data
    await this.autoGeneratePropertyAssets(
      householdId,
      homeProfile,
      createdZones,
    );

    // Generate initial maintenance tasks
    await this.generateMaintenanceTasks(householdId, homeProfile);
  }

  async autoGeneratePropertyAssets(
    householdId: string,
    homeProfile: any,
    createdZones: Record<string, string>,
  ) {
    const basementZoneId = createdZones['BASEMENT'];
    const exteriorZoneId = createdZones['EXTERIOR'];
    const yearBuilt = homeProfile.yearBuilt || 2000;
    const systemAge = new Date().getFullYear() - yearBuilt;

    const assets: any[] = [];

    // Get household heating info
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      select: { heatingFuel: true },
    });

    // Heating system
    if (household?.heatingFuel) {
      assets.push({
        householdId,
        zoneId: basementZoneId,
        name: this.getHeatingSystemName(household.heatingFuel),
        category: 'HVAC',
        condition: systemAge > 15 ? 'Needs Service' : 'Good',
        serviceInterval: 'annual',
      });

      // Oil tank if oil heat
      if (household.heatingFuel === 'oil') {
        assets.push({
          householdId,
          zoneId: basementZoneId,
          name: 'Oil Tank',
          category: 'HVAC',
          conditionNotes: 'Typical capacity: 275 gallons',
          condition: systemAge > 20 ? 'Needs Service' : 'Good',
        });
      }
    }

    // Water heater (every home has one)
    assets.push({
      householdId,
      zoneId: basementZoneId,
      name: 'Water Heater',
      category: 'PLUMBING',
      serviceInterval: 'annual',
      condition: systemAge > 10 ? 'Needs Service' : 'Good',
    });

    // Create property assets in database
    for (const asset of assets) {
      await this.prisma.propertyAsset.create({ data: asset });
    }
  }

  async generateMaintenanceTasks(householdId: string, homeProfile: any) {
    // Check if tasks already exist
    const existingTasks = await this.prisma.maintenanceTask.count({
      where: { householdId },
    });
    if (existingTasks > 0) {
      this.logger.log(
        'Maintenance tasks already exist, skipping auto-generation',
      );
      return;
    }

    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      select: { heatingFuel: true, sewerType: true, waterSource: true },
    });

    const now = new Date();
    const tasks: any[] = [];

    // HVAC service
    tasks.push({
      householdId,
      title: 'HVAC Professional Service',
      description:
        'Annual professional service for heating and cooling systems',
      category: 'HVAC',
      frequency: 'ANNUAL',
      seasonalTiming: 'FALL',
      dueDate: this.getNextSeasonalDate('fall'),
      status: 'PENDING',
      estimatedCost: 150,
      intervalExplanation:
        'Professional HVAC service ensures efficient operation and catches problems early.',
      checklistSteps: JSON.stringify([
        {
          id: '1',
          order: 1,
          title: 'Schedule service appointment',
          alfredCanHandle: true,
          completed: false,
        },
        {
          id: '2',
          order: 2,
          title: 'Confirm technician arrival time',
          alfredCanHandle: true,
          completed: false,
        },
        {
          id: '3',
          order: 3,
          title: 'Be present for service visit',
          alfredCanHandle: false,
          completed: false,
        },
        {
          id: '4',
          order: 4,
          title: 'Review service report',
          alfredCanHandle: false,
          completed: false,
        },
      ]),
    });

    // Oil delivery (if oil heat)
    if (household?.heatingFuel === 'oil') {
      tasks.push({
        householdId,
        title: 'Schedule Oil Delivery',
        description:
          'Monitor oil levels and schedule delivery before running low',
        category: 'HEATING',
        frequency: 'AS_NEEDED',
        seasonalTiming: 'FALL',
        dueDate: this.getNextSeasonalDate('fall'),
        status: 'PENDING',
        estimatedCost: 500,
        intervalExplanation:
          'Oil tanks should be refilled when below 1/4 full to prevent sludge buildup.',
        checklistSteps: JSON.stringify([
          {
            id: '1',
            order: 1,
            title: 'Check current oil tank level',
            alfredCanHandle: false,
            completed: false,
          },
          {
            id: '2',
            order: 2,
            title: 'Compare prices from providers',
            alfredCanHandle: true,
            completed: false,
          },
          {
            id: '3',
            order: 3,
            title: 'Schedule delivery date',
            alfredCanHandle: true,
            completed: false,
          },
        ]),
      });
    }

    // Septic pumping (if septic)
    if (household?.sewerType === 'septic') {
      tasks.push({
        householdId,
        title: 'Septic Tank Pumping',
        description:
          'Regular septic pumping prevents backups and system failure',
        category: 'PLUMBING',
        frequency: 'EVERY_3_YEARS',
        dueDate: new Date(now.getFullYear() + 1, 5, 1),
        status: 'PENDING',
        estimatedCost: 350,
        intervalExplanation:
          'Septic tanks should be pumped every 3-5 years depending on household size.',
        checklistSteps: JSON.stringify([
          {
            id: '1',
            order: 1,
            title: 'Locate septic tank access',
            alfredCanHandle: false,
            completed: false,
          },
          {
            id: '2',
            order: 2,
            title: 'Get quotes from septic services',
            alfredCanHandle: true,
            completed: false,
          },
          {
            id: '3',
            order: 3,
            title: 'Schedule pumping appointment',
            alfredCanHandle: true,
            completed: false,
          },
        ]),
      });
    }

    // Gutter cleaning (everyone)
    tasks.push({
      householdId,
      title: 'Clean Gutters',
      description: 'Remove debris from gutters and downspouts',
      category: 'EXTERIOR',
      frequency: 'SEMI_ANNUAL',
      seasonalTiming: 'FALL',
      dueDate: this.getNextSeasonalDate('fall'),
      status: 'PENDING',
      estimatedCost: 150,
      intervalExplanation:
        'Gutters should be cleaned twice yearly to prevent water damage.',
      checklistSteps: JSON.stringify([
        {
          id: '1',
          order: 1,
          title: 'Inspect gutters for debris',
          alfredCanHandle: false,
          completed: false,
        },
        {
          id: '2',
          order: 2,
          title: 'Get quotes from gutter services',
          alfredCanHandle: true,
          completed: false,
        },
        {
          id: '3',
          order: 3,
          title: 'Schedule cleaning appointment',
          alfredCanHandle: true,
          completed: false,
        },
      ]),
    });

    // Smoke detector testing (everyone)
    tasks.push({
      householdId,
      title: 'Test Smoke & CO Detectors',
      description: 'Test all smoke and carbon monoxide detectors',
      category: 'SAFETY',
      frequency: 'MONTHLY',
      dueDate: new Date(now.getFullYear(), now.getMonth() + 1, 1),
      status: 'PENDING',
      estimatedCost: 0,
      intervalExplanation:
        'Smoke and CO detectors should be tested monthly. These devices save lives.',
      checklistSteps: JSON.stringify([
        {
          id: '1',
          order: 1,
          title: 'Test all smoke detectors',
          alfredCanHandle: false,
          completed: false,
        },
        {
          id: '2',
          order: 2,
          title: 'Test all CO detectors',
          alfredCanHandle: false,
          completed: false,
        },
        {
          id: '3',
          order: 3,
          title: 'Replace batteries if needed',
          alfredCanHandle: false,
          completed: false,
        },
      ]),
    });

    // Create tasks in database
    for (const task of tasks) {
      await this.prisma.maintenanceTask.create({ data: task });
    }
  }

  identifyDataGaps(enrichedData: any): string[] {
    const gaps: string[] = [];

    if (!enrichedData.sewerType || enrichedData.sewerType === 'unknown') {
      gaps.push('sewer_type');
    }
    if (!enrichedData.waterSource || enrichedData.waterSource === 'unknown') {
      gaps.push('water_source');
    }
    if (enrichedData.heatingFuel === 'oil' && !enrichedData.heatingFuelProvider) {
      gaps.push('oil_provider');
    }
    if (
      enrichedData.heatingFuel === 'propane' &&
      !enrichedData.heatingFuelProvider
    ) {
      gaps.push('propane_provider');
    }

    gaps.push('plaid_analysis_pending');

    return gaps;
  }

  // Helper methods
  private mapHeatingFuel(fuel: string | null): string | null {
    if (!fuel) return null;
    const f = fuel.toLowerCase();
    if (f.includes('oil')) return 'oil';
    if (f.includes('gas') || f.includes('natural')) return 'natural-gas';
    if (f.includes('propane') || f.includes('lp')) return 'propane';
    if (f.includes('electric')) return 'electric';
    return 'other';
  }

  private getHeatingSystemName(fuel: string): string {
    const fuelNames: Record<string, string> = {
      oil: 'Oil Furnace/Boiler',
      'natural-gas': 'Gas Furnace',
      propane: 'Propane Furnace',
      electric: 'Electric Heat',
    };
    return fuelNames[fuel] || 'Heating System';
  }

  private getNextSeasonalDate(
    season: 'spring' | 'summer' | 'fall' | 'winter',
  ): Date {
    const now = new Date();
    const year = now.getFullYear();

    const seasons = {
      spring: { month: 3, day: 15 },
      summer: { month: 5, day: 1 },
      fall: { month: 9, day: 15 },
      winter: { month: 11, day: 1 },
    };

    const target = seasons[season];
    let targetDate = new Date(year, target.month, target.day);

    if (targetDate < now) {
      targetDate = new Date(year + 1, target.month, target.day);
    }

    return targetDate;
  }
}
