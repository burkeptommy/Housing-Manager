import { Controller, Get, Param, UseGuards, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { FirebaseAuthGuard } from '../firebase';

@Controller('home')
@UseGuards(FirebaseAuthGuard)
export class HomeController {
  constructor(private prisma: PrismaService) {}

  @Get('dashboard/:householdId')
  async getDashboard(@Param('householdId') householdId: string) {
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      include: {
        homeProfile: true,
        zones: {
          include: {
            assets: {
              where: { isActive: true },
              select: { id: true, category: true },
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

    // Get upcoming maintenance tasks
    const upcomingMaintenance = await this.prisma.maintenanceTask.findMany({
      where: {
        householdId,
        status: { in: ['PENDING', 'SCHEDULED', 'DUE_SOON', 'UPCOMING', 'OVERDUE'] },
      },
      orderBy: { dueDate: 'asc' },
      take: 5,
    });

    // Get comprehensive bills as services
    const services = await this.prisma.comprehensiveBill.findMany({
      where: {
        householdId,
        status: 'ACTIVE',
        category: {
          in: ['LAWN_LANDSCAPE', 'POOL_SERVICE', 'PEST_CONTROL', 'HOUSE_CLEANING', 'SECURITY_MONITORING'],
        },
      },
      select: {
        id: true,
        name: true,
        category: true,
        amount: true,
        frequency: true,
      },
    });

    // Build utilities object
    const utilities = {
      electricity: {
        provider: household.electricityProvider,
        confirmed: household.electricityConfirmed,
      },
      gas: {
        provider: household.gasProvider,
        confirmed: household.gasConfirmed,
      },
      water: {
        source: household.waterSource,
        provider: household.waterProvider,
        confirmed: household.waterSourceConfirmed,
      },
      sewer: {
        type: household.sewerType,
        provider: household.sewerProvider,
        confirmed: household.sewerTypeConfirmed,
      },
      heatingFuel: {
        type: household.heatingFuel,
        provider: household.heatingFuelProvider,
      },
      internet: {
        provider: household.internetProvider,
      },
      cable: {
        provider: household.cableProvider,
      },
    };

    // Calculate systems status
    const systems = this.getSystemsStatus(enrichmentData);

    // Get Alfred data gaps summary
    const dataGaps = (household.alfredDataGaps as string[]) || [];
    const questionsAsked = (household.alfredQuestionsAsked as string[]) || [];

    return {
      household: {
        id: household.id,
        name: household.name,
        homeHealthScore: household.homeHealthScore || 85,
        attomDataFetched: household.attomDataFetched,
        plaidDataAnalyzed: household.plaidDataAnalyzed,
        initialSetupComplete: household.initialSetupComplete,
      },
      property: {
        address: homeProfile
          ? {
              street: homeProfile.addressLine1,
              city: homeProfile.city,
              state: homeProfile.state,
              zip: homeProfile.postalCode,
              full: `${homeProfile.addressLine1}, ${homeProfile.city}, ${homeProfile.state} ${homeProfile.postalCode}`,
            }
          : null,
        details: {
          bedrooms: enrichmentData?.bedrooms ?? null,
          bathrooms: enrichmentData?.bathrooms ?? null,
          squareFeet: enrichmentData?.squareFeet ?? null,
          yearBuilt: enrichmentData?.yearBuilt ?? null,
          lotSize: enrichmentData?.lotSizeAcres ?? null,
          propertyType: homeProfile?.propertyType ?? null,
        },
      },
      utilities,
      systems,
      zones: household.zones.map((z) => ({
        id: z.id,
        name: z.name,
        type: z.type,
        floor: z.floor,
        assetCount: z.assets.length,
        needsAttention: 0, // Could calculate based on asset conditions
      })),
      services: services.map((s) => ({
        id: s.id,
        name: s.name,
        category: s.category,
        monthlyCost: s.amount ? Number(s.amount) : null,
        frequency: s.frequency,
      })),
      upcomingMaintenance: upcomingMaintenance.map((m) => ({
        id: m.id,
        title: m.title,
        status: m.status,
        dueDate: m.dueDate,
        category: m.category,
      })),
      alfred: {
        pendingQuestions: dataGaps.length - questionsAsked.length,
        dataCompletion: dataGaps.length > 0
          ? Math.round(((questionsAsked.length) / Math.max(dataGaps.length + questionsAsked.length, 1)) * 100)
          : 100,
      },
    };
  }

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
}
