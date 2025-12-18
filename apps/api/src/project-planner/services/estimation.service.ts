import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { ProjectCategory } from '@prisma/client';
import * as h3 from 'h3-js';
import {
  CalculateEstimateDto,
  EstimateResultDto,
  SocialProofDto,
  RegionalMultiplierDto,
} from '../dto';

@Injectable()
export class EstimationService {
  private readonly logger = new Logger(EstimationService.name);
  private readonly REGIONAL_RESOLUTION = 5; // ~8km hexagons for regional coverage
  private readonly NEIGHBOR_RESOLUTION = 8; // ~460m for neighbor matching
  private readonly DEFAULT_MULTIPLIER = 1.0;
  private readonly ESTIMATE_VARIANCE = 0.15; // ±15% range

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Calculate project estimate with regional adjustment and social proof
   *
   * Algorithm:
   * 1. Base = (baseMaterialCost * sqFt) + (laborHours * sqFt * laborRate)
   * 2. Complexity Adjusted = Base * complexityFactor1 * complexityFactor2
   * 3. Regional Adjusted = Complexity Adjusted * regionalMultiplier
   * 4. Final Range = RegionalAdjusted * 0.85 to RegionalAdjusted * 1.15
   */
  async calculateEstimate(
    dto: CalculateEstimateDto,
    householdId: string,
  ): Promise<EstimateResultDto> {
    // Get household for location data
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      select: { h3Index: true },
    });

    // Get template if provided
    let template = null;
    if (dto.templateId) {
      template = await this.prisma.projectTemplate.findUnique({
        where: { id: dto.templateId },
      });
    }

    // If no template, find best matching one for category
    if (!template) {
      template = await this.prisma.projectTemplate.findFirst({
        where: {
          category: dto.category,
          isActive: true,
        },
        orderBy: { sortOrder: 'asc' },
      });
    }

    // Calculate base costs
    const sqFt = dto.specs.sqFt;
    const baseMaterialCostPerSqFt = template
      ? Number(template.baseMaterialCost)
      : this.getDefaultMaterialCost(dto.category);
    const laborHoursPerSqFt = template?.laborHoursPerSqFt
      ? Number(template.laborHoursPerSqFt)
      : this.getDefaultLaborHours(dto.category);
    const laborRate = template
      ? Number(template.baseLaborRate)
      : 75;

    const materialsCost = baseMaterialCostPerSqFt * sqFt;
    const laborCost = laborHoursPerSqFt * sqFt * laborRate;
    let baseCost = materialsCost + laborCost;

    // Apply complexity factors
    let complexityMultiplier = 1.0;
    const templateComplexity = template?.complexityFactors as Record<string, number> | null;

    if (dto.specs.complexity && templateComplexity) {
      for (const factor of dto.specs.complexity) {
        if (templateComplexity[factor]) {
          complexityMultiplier *= templateComplexity[factor];
        }
      }
    }
    const complexityAdjustedCost = baseCost * complexityMultiplier;

    // Get regional multiplier
    const regionalData = await this.getRegionalMultiplier(household?.h3Index);
    const regionalMultiplier = Number(regionalData.multiplier);
    const laborMultiplier = Number(regionalData.laborMultiplier);

    // Apply regional adjustment (materials get base multiplier, labor gets labor multiplier)
    const regionalMaterialsCost = materialsCost * complexityMultiplier * regionalMultiplier;
    const regionalLaborCost = laborCost * complexityMultiplier * laborMultiplier;
    const regionalAdjustedCost = regionalMaterialsCost + regionalLaborCost;

    // Calculate range
    const estimatedMin = Math.round(regionalAdjustedCost * (1 - this.ESTIMATE_VARIANCE));
    const estimatedMax = Math.round(regionalAdjustedCost * (1 + this.ESTIMATE_VARIANCE));

    // Get social proof
    const socialProof = await this.getNeighborhoodSocialProof(
      householdId,
      dto.category,
      household?.h3Index,
    );

    // Calculate estimated days if template has that data
    let estimatedDays: { min: number; max: number } | undefined;
    if (template?.estimatedDaysMin && template?.estimatedDaysMax) {
      estimatedDays = {
        min: template.estimatedDaysMin,
        max: template.estimatedDaysMax,
      };
    }

    return {
      estimatedMin,
      estimatedMax,
      breakdown: {
        materials: Math.round(regionalMaterialsCost),
        labor: Math.round(regionalLaborCost),
        regionalAdjustment: Math.round(regionalAdjustedCost - (baseCost * complexityMultiplier)),
        complexityAdjustment: Math.round((baseCost * complexityMultiplier) - baseCost),
      },
      regionalMultiplier,
      socialProof,
      templateName: template?.name,
      estimatedDays,
    };
  }

  /**
   * Get regional cost multiplier for a location
   */
  async getRegionalMultiplier(h3Index?: string | null): Promise<RegionalMultiplierDto> {
    if (!h3Index) {
      return {
        multiplier: this.DEFAULT_MULTIPLIER,
        laborMultiplier: this.DEFAULT_MULTIPLIER,
        h3Index: 'unknown',
      };
    }

    // Convert resolution 8 index to resolution 5 for regional lookup
    const regionalH3Index = h3.cellToParent(h3Index, this.REGIONAL_RESOLUTION);

    // Look up regional cost index
    const regionalIndex = await this.prisma.regionalCostIndex.findFirst({
      where: {
        h3Index: regionalH3Index,
        OR: [
          { effectiveTo: null },
          { effectiveTo: { gte: new Date() } },
        ],
      },
      orderBy: { effectiveFrom: 'desc' },
    });

    if (regionalIndex) {
      return {
        multiplier: Number(regionalIndex.multiplier),
        laborMultiplier: Number(regionalIndex.laborMultiplier),
        regionName: regionalIndex.regionName ?? undefined,
        stateCode: regionalIndex.stateCode ?? undefined,
        h3Index: regionalH3Index,
      };
    }

    // Fallback: try to find by state if we can get coordinates
    // For now, return default
    this.logger.debug(`No regional cost index found for H3: ${regionalH3Index}`);
    return {
      multiplier: this.DEFAULT_MULTIPLIER,
      laborMultiplier: this.DEFAULT_MULTIPLIER,
      h3Index: regionalH3Index,
    };
  }

  /**
   * Get social proof from neighbor projects
   */
  async getNeighborhoodSocialProof(
    householdId: string,
    category: ProjectCategory,
    h3Index?: string | null,
  ): Promise<SocialProofDto> {
    if (!h3Index) {
      return {
        neighborProjectCount: 0,
        note: 'Add your address to see what neighbors have done',
      };
    }

    // Get neighboring H3 cells (1 ring = immediate neighbors)
    const neighborCells = h3.gridDisk(h3Index, 1);

    // Find completed work orders in neighbor area for similar category
    const categoryToWorkOrderType = this.mapCategoryToWorkOrderType(category);

    const neighborProjects = await this.prisma.workOrder.findMany({
      where: {
        household: {
          h3Index: { in: neighborCells },
          id: { not: householdId }, // Exclude own household
        },
        status: 'COMPLETED',
      },
      select: {
        actualCost: true,
      },
    });

    // Also check ProjectPosts for completed projects
    const neighborPosts = await this.prisma.projectPost.findMany({
      where: {
        household: {
          h3Index: { in: neighborCells },
          id: { not: householdId },
        },
        completedAt: { not: null },
        actualCost: { not: null },
      },
      select: {
        actualCost: true,
      },
    });

    const totalCount = neighborProjects.length + neighborPosts.length;

    // Calculate average cost if we have data
    const costs = [
      ...neighborProjects.filter(p => p.actualCost).map(p => Number(p.actualCost)),
      ...neighborPosts.filter(p => p.actualCost).map(p => Number(p.actualCost)),
    ];

    const averageCost = costs.length > 0
      ? Math.round(costs.reduce((a, b) => a + b, 0) / costs.length)
      : undefined;

    // Generate human-readable note
    let note: string;
    if (totalCount === 0) {
      note = 'Be the first in your neighborhood!';
    } else if (totalCount === 1) {
      note = '1 neighbor completed a similar project';
    } else {
      note = `${totalCount} neighbors completed similar projects`;
    }

    if (averageCost) {
      note += ` (avg. $${averageCost.toLocaleString()})`;
    }

    return {
      neighborProjectCount: totalCount,
      averageCost,
      note,
    };
  }

  /**
   * Map project category to work order type for social proof lookup
   */
  private mapCategoryToWorkOrderType(category: ProjectCategory): string | null {
    const mapping: Partial<Record<ProjectCategory, string>> = {
      BATHROOM_REMODEL: 'RENOVATION',
      KITCHEN_REMODEL: 'RENOVATION',
      DECK_PATIO: 'RENOVATION',
      LANDSCAPING: 'LANDSCAPING',
      ROOF: 'REPAIR',
      WINDOWS_DOORS: 'REPAIR',
      FLOORING: 'RENOVATION',
      PAINTING: 'COSMETIC',
      HVAC: 'REPAIR',
      ELECTRICAL: 'REPAIR',
      PLUMBING: 'REPAIR',
      ADDITION: 'RENOVATION',
      BASEMENT: 'RENOVATION',
      GARAGE: 'RENOVATION',
      FENCE: 'RENOVATION',
      POOL: 'RENOVATION',
      SOLAR: 'UPGRADE',
      SMART_HOME: 'UPGRADE',
      EXTERIOR_SIDING: 'REPAIR',
    };
    return mapping[category] ?? null;
  }

  /**
   * Default material cost per sqft by category (used when no template)
   */
  private getDefaultMaterialCost(category: ProjectCategory): number {
    const defaults: Partial<Record<ProjectCategory, number>> = {
      BATHROOM_REMODEL: 75,
      KITCHEN_REMODEL: 100,
      DECK_PATIO: 25,
      LANDSCAPING: 15,
      ROOF: 8,
      FLOORING: 8,
      PAINTING: 2,
      HVAC: 50,
      ELECTRICAL: 30,
      PLUMBING: 40,
    };
    return defaults[category] ?? 50;
  }

  /**
   * Default labor hours per sqft by category (used when no template)
   */
  private getDefaultLaborHours(category: ProjectCategory): number {
    const defaults: Partial<Record<ProjectCategory, number>> = {
      BATHROOM_REMODEL: 0.5,
      KITCHEN_REMODEL: 0.6,
      DECK_PATIO: 0.3,
      LANDSCAPING: 0.2,
      ROOF: 0.15,
      FLOORING: 0.2,
      PAINTING: 0.1,
      HVAC: 0.25,
      ELECTRICAL: 0.3,
      PLUMBING: 0.35,
    };
    return defaults[category] ?? 0.25;
  }
}
