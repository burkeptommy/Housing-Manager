import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AuthPayload } from '../firebase';
import Anthropic from '@anthropic-ai/sdk';

const SYSTEM_LIFESPANS: Record<string, { min: number; max: number; typical: number; avgCost: number }> = {
  HVAC_FURNACE: { min: 15, max: 30, typical: 20, avgCost: 5000 },
  HVAC_AC: { min: 10, max: 20, typical: 15, avgCost: 4000 },
  HVAC_HEAT_PUMP: { min: 10, max: 20, typical: 15, avgCost: 6000 },
  WATER_HEATER_TANK: { min: 8, max: 15, typical: 12, avgCost: 1500 },
  WATER_HEATER_TANKLESS: { min: 15, max: 25, typical: 20, avgCost: 3000 },
  ROOF_ASPHALT: { min: 20, max: 30, typical: 25, avgCost: 15000 },
  ROOF_METAL: { min: 40, max: 70, typical: 50, avgCost: 25000 },
  ROOF_TILE: { min: 50, max: 100, typical: 75, avgCost: 30000 },
  SEPTIC: { min: 25, max: 40, typical: 30, avgCost: 10000 },
  WELL_PUMP: { min: 8, max: 15, typical: 10, avgCost: 2000 },
  GARAGE_DOOR: { min: 15, max: 30, typical: 20, avgCost: 1500 },
  APPLIANCE_DISHWASHER: { min: 8, max: 15, typical: 10, avgCost: 800 },
  APPLIANCE_WASHER: { min: 10, max: 15, typical: 12, avgCost: 900 },
  APPLIANCE_DRYER: { min: 10, max: 18, typical: 13, avgCost: 800 },
  APPLIANCE_REFRIGERATOR: { min: 10, max: 20, typical: 15, avgCost: 1500 },
  APPLIANCE_OVEN: { min: 12, max: 20, typical: 15, avgCost: 1200 },
  POOL_PUMP: { min: 8, max: 12, typical: 10, avgCost: 2500 },
  POOL_HEATER: { min: 7, max: 12, typical: 10, avgCost: 3500 },
  GENERATOR: { min: 15, max: 30, typical: 20, avgCost: 8000 },
  SIDING_VINYL: { min: 20, max: 40, typical: 30, avgCost: 12000 },
  SIDING_WOOD: { min: 15, max: 25, typical: 20, avgCost: 15000 },
  WINDOWS: { min: 15, max: 30, typical: 20, avgCost: 10000 },
  DECK: { min: 10, max: 20, typical: 15, avgCost: 5000 },
  DRIVEWAY_ASPHALT: { min: 15, max: 25, typical: 20, avgCost: 4000 },
  DRIVEWAY_CONCRETE: { min: 25, max: 50, typical: 30, avgCost: 6000 },
};

interface SystemForecastInput {
  systemType: string;
  systemName: string;
  installYear?: number;
  estimatedReplacementCost?: number;
  notes?: string;
}

@Injectable()
export class ForecastService {
  private readonly logger = new Logger(ForecastService.name);
  private anthropic: Anthropic;

  constructor(private prisma: PrismaService) {
    this.anthropic = new Anthropic({
      apiKey: process.env.ANTHROPIC_API_KEY,
    });
  }

  private async getHouseholdId(user: AuthPayload): Promise<string> {
    const member = await this.prisma.householdMember.findFirst({
      where: { userId: user.userId },
      select: { householdId: true },
    });
    if (!member) throw new BadRequestException('No household found');
    return member.householdId;
  }

  async getHomeForecasts(user: AuthPayload) {
    const householdId = await this.getHouseholdId(user);

    const forecasts = await this.prisma.systemForecast.findMany({
      where: { householdId },
      orderBy: { expectedReplacementYear: 'asc' },
    });

    if (forecasts.length === 0) {
      // Auto-generate from property assets and home systems
      await this.generateForecastsFromSystems(householdId);
      // Check for end-of-life systems
      await this.detectEndOfLife(householdId);
      return this.prisma.systemForecast.findMany({
        where: { householdId },
        orderBy: { expectedReplacementYear: 'asc' },
      });
    }

    // Refresh end-of-life detection on each view
    await this.detectEndOfLife(householdId);

    return forecasts;
  }

  async generateForecastsFromSystems(householdId: string) {
    const assets = await this.prisma.propertyAsset.findMany({
      where: { householdId },
    });

    const homeProfile = await this.prisma.homeProfile.findFirst({
      where: { householdId },
    });

    // Also query HomeSystem records - these have install dates and detailed system info
    const homeSystems = await this.prisma.homeSystem.findMany({
      where: { householdId, isActive: true },
    });

    // Look up local cost data for the household's zip code
    const zipCode = homeProfile?.postalCode;
    const localCosts = zipCode
      ? await this.prisma.localCostData.findMany({
          where: { zipCode },
        })
      : [];
    const localCostMap = new Map(localCosts.map((c) => [c.category, c]));

    const currentYear = new Date().getFullYear();

    // Generate forecasts from PropertyAssets
    for (const asset of assets) {
      const systemType = this.mapAssetToSystemType(asset.category, asset.name);
      if (!systemType || !SYSTEM_LIFESPANS[systemType]) continue;

      const lifespan = SYSTEM_LIFESPANS[systemType];

      const installYear = asset.purchaseDate
        ? new Date(asset.purchaseDate).getFullYear()
        : homeProfile?.yearBuilt || currentYear - Math.floor(lifespan.typical / 2);

      const currentAge = currentYear - installYear;
      const expectedReplacementYear = installYear + lifespan.typical;

      let urgency = 'LOW';
      const remainingYears = expectedReplacementYear - currentYear;
      if (remainingYears <= 0) urgency = 'CRITICAL';
      else if (remainingYears <= 2) urgency = 'HIGH';
      else if (remainingYears <= 5) urgency = 'MEDIUM';

      // Use local cost data if available, otherwise fall back to national average
      const localCost = localCostMap.get(systemType);
      const estimatedCost = localCost
        ? Number(localCost.medianMonthly) * 12 // Use annual from monthly median as proxy
        : lifespan.avgCost;

      // Check if forecast already exists for this asset
      const existing = await this.prisma.systemForecast.findFirst({
        where: { householdId, systemId: asset.id },
      });

      if (existing) {
        await this.prisma.systemForecast.update({
          where: { id: existing.id },
          data: {
            currentAge,
            urgency,
            expectedReplacementYear,
            estimatedReplacementCost: estimatedCost,
          },
        });
      } else {
        await this.prisma.systemForecast.create({
          data: {
            householdId,
            systemId: asset.id,
            systemType,
            systemName: asset.name || this.getSystemDisplayName(systemType),
            installYear,
            currentAge,
            typicalLifespan: lifespan.typical,
            lifespanMin: lifespan.min,
            lifespanMax: lifespan.max,
            estimatedReplacementCost: estimatedCost,
            expectedReplacementYear,
            urgency,
          },
        });
      }
    }

    // Generate forecasts from HomeSystems (these may not overlap with PropertyAssets)
    for (const system of homeSystems) {
      // Skip if we already have a forecast for this system (from maintenance research)
      const existingForecast = await this.prisma.systemForecast.findFirst({
        where: { householdId, systemId: system.id },
      });
      if (existingForecast) continue;

      const systemType = this.mapHomeSystemType(system.type);
      if (!systemType || !SYSTEM_LIFESPANS[systemType]) continue;

      const lifespan = SYSTEM_LIFESPANS[systemType];

      const installYear = system.installedDate
        ? new Date(system.installedDate).getFullYear()
        : homeProfile?.yearBuilt || currentYear - Math.floor(lifespan.typical / 2);

      const currentAge = currentYear - installYear;
      const expectedReplacementYear = installYear + lifespan.typical;

      let urgency = 'LOW';
      const remainingYears = expectedReplacementYear - currentYear;
      if (remainingYears <= 0) urgency = 'CRITICAL';
      else if (remainingYears <= 2) urgency = 'HIGH';
      else if (remainingYears <= 5) urgency = 'MEDIUM';

      // Use local cost data if available
      const localCost = localCostMap.get(systemType);
      const estimatedCost = localCost
        ? Number(localCost.medianMonthly) * 12
        : lifespan.avgCost;

      await this.prisma.systemForecast.create({
        data: {
          householdId,
          systemId: system.id,
          systemType,
          systemName: system.name || this.getSystemDisplayName(systemType),
          installYear,
          currentAge,
          typicalLifespan: lifespan.typical,
          lifespanMin: lifespan.min,
          lifespanMax: lifespan.max,
          estimatedReplacementCost: estimatedCost,
          expectedReplacementYear,
          urgency,
        },
      });
    }
  }

  /**
   * Detect systems nearing end-of-life and create replacement planning reminders
   */
  async detectEndOfLife(householdId: string) {
    const forecasts = await this.prisma.systemForecast.findMany({
      where: { householdId },
    });

    const currentYear = new Date().getFullYear();
    const alerts: Array<{
      forecastId: string;
      systemName: string;
      urgency: string;
      remainingYears: number;
      estimatedCost: number;
    }> = [];

    for (const forecast of forecasts) {
      const remainingYears = forecast.expectedReplacementYear - currentYear;
      const lifespanPercent = forecast.currentAge / forecast.typicalLifespan;

      // Flag systems at 80%+ of expected lifespan
      if (lifespanPercent >= 0.8 || remainingYears <= 3) {
        let urgency = forecast.urgency || 'LOW';
        if (remainingYears <= 0) urgency = 'CRITICAL';
        else if (remainingYears <= 2) urgency = 'HIGH';
        else if (remainingYears <= 5) urgency = 'MEDIUM';

        // Update urgency if changed
        if (urgency !== forecast.urgency) {
          await this.prisma.systemForecast.update({
            where: { id: forecast.id },
            data: { urgency, currentAge: forecast.currentAge },
          });
        }

        // Create a maintenance task for replacement planning if one doesn't exist
        if (remainingYears <= 2) {
          const existingTask = await this.prisma.maintenanceTask.findFirst({
            where: {
              householdId,
              title: { contains: `${forecast.systemName} replacement` },
              status: { in: ['UPCOMING', 'PENDING', 'SCHEDULED', 'IN_PROGRESS'] },
            },
          });

          if (!existingTask) {
            await this.prisma.maintenanceTask.create({
              data: {
                householdId,
                title: `Plan ${forecast.systemName} replacement`,
                description: remainingYears <= 0
                  ? `Your ${forecast.systemName} is past its typical ${forecast.typicalLifespan}-year lifespan. Consider budgeting ~$${forecast.estimatedReplacementCost?.toLocaleString() || 'unknown'} for replacement.`
                  : `Your ${forecast.systemName} is expected to need replacement within ${remainingYears} year${remainingYears === 1 ? '' : 's'}. Estimated cost: ~$${forecast.estimatedReplacementCost?.toLocaleString() || 'unknown'}.`,
                category: 'GENERAL',
                frequency: 'ONE_TIME',
                priority: remainingYears <= 0 ? 'URGENT' : 'HIGH',
                status: 'UPCOMING',
                source: 'SYSTEM_GENERATED',
                sourceSystem: 'Forecast',
                dueDate: new Date(currentYear + Math.max(remainingYears, 0), 0, 15),
                nextDueDate: new Date(currentYear + Math.max(remainingYears, 0), 0, 15),
                estimatedCost: forecast.estimatedReplacementCost || undefined,
              },
            });
          }
        }

        alerts.push({
          forecastId: forecast.id,
          systemName: forecast.systemName,
          urgency,
          remainingYears,
          estimatedCost: forecast.estimatedReplacementCost || 0,
        });
      }
    }

    return alerts;
  }

  async getForecastTimeline(user: AuthPayload, years: number) {
    const householdId = await this.getHouseholdId(user);

    const forecasts = await this.prisma.systemForecast.findMany({
      where: { householdId },
      orderBy: { expectedReplacementYear: 'asc' },
    });

    const currentYear = new Date().getFullYear();
    const timeline: Array<{
      year: number;
      items: Array<{ id: string; name: string; type: string; cost: number; urgency: string | null }>;
      totalCost: number;
    }> = [];

    for (let y = currentYear; y <= currentYear + years; y++) {
      const yearItems = forecasts
        .filter((f) => f.expectedReplacementYear === y)
        .map((f) => ({
          id: f.id,
          name: f.systemName,
          type: f.systemType,
          cost: f.estimatedReplacementCost || 0,
          urgency: f.urgency,
        }));

      timeline.push({
        year: y,
        items: yearItems,
        totalCost: yearItems.reduce((sum, i) => sum + i.cost, 0),
      });
    }

    return {
      years: timeline,
      totalProjected: forecasts.reduce((sum, f) => sum + (f.estimatedReplacementCost || 0), 0),
    };
  }

  async addSystemForecast(user: AuthPayload, body: SystemForecastInput) {
    const householdId = await this.getHouseholdId(user);
    const lifespan = SYSTEM_LIFESPANS[body.systemType];
    if (!lifespan) throw new BadRequestException(`Unknown system type: ${body.systemType}`);

    const currentYear = new Date().getFullYear();
    const installYear = body.installYear || currentYear;
    const currentAge = currentYear - installYear;
    const expectedReplacementYear = installYear + lifespan.typical;

    let urgency = 'LOW';
    const remainingYears = expectedReplacementYear - currentYear;
    if (remainingYears <= 0) urgency = 'CRITICAL';
    else if (remainingYears <= 2) urgency = 'HIGH';
    else if (remainingYears <= 5) urgency = 'MEDIUM';

    return this.prisma.systemForecast.create({
      data: {
        householdId,
        systemType: body.systemType,
        systemName: body.systemName || this.getSystemDisplayName(body.systemType),
        installYear,
        currentAge,
        typicalLifespan: lifespan.typical,
        lifespanMin: lifespan.min,
        lifespanMax: lifespan.max,
        estimatedReplacementCost: body.estimatedReplacementCost || lifespan.avgCost,
        expectedReplacementYear,
        urgency,
        notes: body.notes,
      },
    });
  }

  async updateSystemForecast(user: AuthPayload, id: string, body: Partial<SystemForecastInput>) {
    const householdId = await this.getHouseholdId(user);

    const forecast = await this.prisma.systemForecast.findFirst({
      where: { id, householdId },
    });
    if (!forecast) throw new BadRequestException('Forecast not found');

    const updateData: Record<string, unknown> = {};
    if (body.systemName) updateData.systemName = body.systemName;
    if (body.estimatedReplacementCost) updateData.estimatedReplacementCost = body.estimatedReplacementCost;
    if (body.notes !== undefined) updateData.notes = body.notes;

    if (body.installYear) {
      const currentYear = new Date().getFullYear();
      updateData.installYear = body.installYear;
      updateData.currentAge = currentYear - body.installYear;
      updateData.expectedReplacementYear = body.installYear + forecast.typicalLifespan;

      const remaining = (updateData.expectedReplacementYear as number) - currentYear;
      if (remaining <= 0) updateData.urgency = 'CRITICAL';
      else if (remaining <= 2) updateData.urgency = 'HIGH';
      else if (remaining <= 5) updateData.urgency = 'MEDIUM';
      else updateData.urgency = 'LOW';
    }

    return this.prisma.systemForecast.update({
      where: { id },
      data: updateData,
    });
  }

  async requestAlfredResearch(user: AuthPayload, forecastId: string) {
    const householdId = await this.getHouseholdId(user);

    const forecast = await this.prisma.systemForecast.findFirst({
      where: { id: forecastId, householdId },
    });
    if (!forecast) throw new BadRequestException('Forecast not found');

    const asset = forecast.systemId
      ? await this.prisma.propertyAsset.findUnique({
          where: { id: forecast.systemId },
        })
      : null;

    const homeProfile = await this.prisma.homeProfile.findFirst({
      where: { householdId },
    });

    const prompt = `Research the following home system for a homeowner:

System Type: ${forecast.systemType}
System Name: ${forecast.systemName}
${asset?.brand ? `Brand: ${asset.brand}` : ''}
${asset?.model ? `Model: ${asset.model}` : ''}
${forecast.installYear ? `Install Year: ${forecast.installYear}` : ''}
Location: ${homeProfile?.city || 'Unknown'}, ${homeProfile?.state || 'US'}
${homeProfile?.postalCode ? `ZIP Code: ${homeProfile.postalCode}` : ''}

Please provide:
1. Expected lifespan for this specific make/model (if known)
2. Common issues/failure points for this age
3. Any recalls or known problems
4. Estimated replacement cost for this specific area/zip code (factor in local labor rates and material costs)
5. Recommended maintenance to extend life
6. Signs that replacement is needed

Return as JSON:
{
  "specificLifespan": { "min": number, "max": number, "typical": number },
  "commonIssues": ["string"],
  "recalls": [{ "date": "string", "description": "string" }],
  "estimatedCost": { "low": number, "high": number, "average": number },
  "maintenanceTips": ["string"],
  "replacementSigns": ["string"],
  "notes": "string"
}`;

    try {
      const response = await this.anthropic.messages.create({
        model: 'claude-sonnet-4-20250514',
        max_tokens: 2000,
        messages: [{ role: 'user', content: prompt }],
      });

      const content = response.content[0];
      if (content.type !== 'text') throw new Error('Unexpected response');

      const jsonMatch = content.text.match(/\{[\s\S]*\}/);
      if (!jsonMatch) throw new Error('No JSON in response');

      const researchData = JSON.parse(jsonMatch[0]);

      await this.prisma.systemForecast.update({
        where: { id: forecastId },
        data: {
          alfredResearchDate: new Date(),
          alfredResearchData: researchData,
          ...(researchData.specificLifespan && {
            typicalLifespan: researchData.specificLifespan.typical,
            lifespanMin: researchData.specificLifespan.min,
            lifespanMax: researchData.specificLifespan.max,
          }),
          ...(researchData.estimatedCost && {
            estimatedReplacementCost: researchData.estimatedCost.average,
          }),
        },
      });

      return researchData;
    } catch (error) {
      this.logger.error(`Alfred research failed: ${error.message}`);
      throw error;
    }
  }

  // Available system types for the frontend dropdown
  getSystemTypes() {
    return Object.entries(SYSTEM_LIFESPANS).map(([type, data]) => ({
      type,
      name: this.getSystemDisplayName(type),
      typicalLifespan: data.typical,
      avgCost: data.avgCost,
    }));
  }

  private mapHomeSystemType(type: string): string | null {
    const mapping: Record<string, string> = {
      FURNACE: 'HVAC_FURNACE',
      BOILER: 'HVAC_FURNACE',
      AIR_CONDITIONER: 'HVAC_AC',
      HEAT_PUMP: 'HVAC_HEAT_PUMP',
      MINI_SPLIT: 'HVAC_AC',
      WATER_HEATER: 'WATER_HEATER_TANK',
      WELL_PUMP: 'WELL_PUMP',
      SEPTIC_SYSTEM: 'SEPTIC',
      SEPTIC_TANK: 'SEPTIC',
      GARAGE_DOOR_OPENER: 'GARAGE_DOOR',
      DISHWASHER: 'APPLIANCE_DISHWASHER',
      WASHER: 'APPLIANCE_WASHER',
      DRYER: 'APPLIANCE_DRYER',
      REFRIGERATOR: 'APPLIANCE_REFRIGERATOR',
      OVEN_RANGE: 'APPLIANCE_OVEN',
      POOL_EQUIPMENT: 'POOL_PUMP',
      POOL_HEATER: 'POOL_HEATER',
      GENERATOR: 'GENERATOR',
      WINDOWS: 'WINDOWS',
      DECK: 'DECK',
      ROOF: 'ROOF_ASPHALT',
      SOLAR_PANELS: 'GENERATOR',
      DRIVEWAY: 'DRIVEWAY_ASPHALT',
    };
    return mapping[type] || null;
  }

  private mapAssetToSystemType(category: string, name: string): string | null {
    const nameLower = (name || '').toLowerCase();

    if (category === 'HVAC') {
      if (nameLower.includes('furnace')) return 'HVAC_FURNACE';
      if (nameLower.includes('ac') || nameLower.includes('air condition')) return 'HVAC_AC';
      if (nameLower.includes('heat pump')) return 'HVAC_HEAT_PUMP';
    }
    if (nameLower.includes('water heater')) {
      return nameLower.includes('tankless') ? 'WATER_HEATER_TANKLESS' : 'WATER_HEATER_TANK';
    }
    if (nameLower.includes('roof')) return 'ROOF_ASPHALT';
    if (nameLower.includes('septic')) return 'SEPTIC';
    if (nameLower.includes('well') && nameLower.includes('pump')) return 'WELL_PUMP';
    if (nameLower.includes('garage door')) return 'GARAGE_DOOR';
    if (nameLower.includes('dishwasher')) return 'APPLIANCE_DISHWASHER';
    if (nameLower.includes('washer') && !nameLower.includes('dish')) return 'APPLIANCE_WASHER';
    if (nameLower.includes('dryer')) return 'APPLIANCE_DRYER';
    if (nameLower.includes('refrigerator') || nameLower.includes('fridge')) return 'APPLIANCE_REFRIGERATOR';
    if (nameLower.includes('oven') || nameLower.includes('range') || nameLower.includes('stove')) return 'APPLIANCE_OVEN';
    if (nameLower.includes('window')) return 'WINDOWS';
    if (nameLower.includes('deck')) return 'DECK';
    if (nameLower.includes('generator')) return 'GENERATOR';

    return null;
  }

  private getSystemDisplayName(systemType: string): string {
    const names: Record<string, string> = {
      HVAC_FURNACE: 'Furnace',
      HVAC_AC: 'Air Conditioner',
      HVAC_HEAT_PUMP: 'Heat Pump',
      WATER_HEATER_TANK: 'Water Heater (Tank)',
      WATER_HEATER_TANKLESS: 'Water Heater (Tankless)',
      ROOF_ASPHALT: 'Roof (Asphalt Shingle)',
      ROOF_METAL: 'Roof (Metal)',
      ROOF_TILE: 'Roof (Tile)',
      SEPTIC: 'Septic System',
      WELL_PUMP: 'Well Pump',
      GARAGE_DOOR: 'Garage Door',
      APPLIANCE_DISHWASHER: 'Dishwasher',
      APPLIANCE_WASHER: 'Washing Machine',
      APPLIANCE_DRYER: 'Dryer',
      APPLIANCE_REFRIGERATOR: 'Refrigerator',
      APPLIANCE_OVEN: 'Oven / Range',
      POOL_PUMP: 'Pool Pump',
      POOL_HEATER: 'Pool Heater',
      GENERATOR: 'Generator',
      SIDING_VINYL: 'Siding (Vinyl)',
      SIDING_WOOD: 'Siding (Wood)',
      WINDOWS: 'Windows',
      DECK: 'Deck',
      DRIVEWAY_ASPHALT: 'Driveway (Asphalt)',
      DRIVEWAY_CONCRETE: 'Driveway (Concrete)',
    };
    return names[systemType] || systemType;
  }
}
