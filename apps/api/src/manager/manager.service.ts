import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ActivityAction, ActivityCategory, ActorType } from '@prisma/client';

@Injectable()
export class ManagerService {
  constructor(private prisma: PrismaService) {}

  // =========================================================================
  // DASHBOARD
  // =========================================================================

  async getDashboard(managerId: string) {
    // Get manager's assigned households
    const households = await this.prisma.household.findMany({
      where: { managerId },
      include: {
        homeProfile: true,
        owner: {
          select: { id: true, displayName: true, firstName: true, lastName: true, email: true },
        },
        comprehensiveBills: { where: { status: 'ACTIVE' } },
        _count: { select: { activityLogs: true, familyMembers: true } },
      },
    });

    // Get pending onboarding sessions for this manager
    const pendingOnboarding = await this.prisma.onboardingProgress.findMany({
      where: {
        homeManagerId: managerId,
        status: { in: ['PENDING_CALL', 'CALL_SCHEDULED', 'INTAKE_PARTIAL'] },
      },
      include: {
        household: {
          include: {
            homeProfile: true,
            owner: {
              select: { id: true, displayName: true, firstName: true, lastName: true, phone: true },
            },
          },
        },
      },
    });

    // Get recent activity across all managed households
    const householdIds = households.map((h) => h.id);
    const recentActivity = await this.prisma.activityLog.findMany({
      where: { householdId: { in: householdIds } },
      orderBy: { createdAt: 'desc' },
      take: 20,
      include: { household: { select: { name: true } } },
    });

    // Calculate stats
    const urgentCount = pendingOnboarding.filter((s) => s.status === 'PENDING_CALL').length;

    const totalBillsDue = households.reduce((sum, h) => {
      const monthlyBills = h.comprehensiveBills.reduce(
        (s, b) => s + (Number(b.typicalAmount) || 0),
        0,
      );
      return sum + monthlyBills;
    }, 0);

    return {
      stats: {
        householdsManaged: households.length,
        pendingOnboarding: pendingOnboarding.length,
        urgentItems: urgentCount,
        tasksToday: 0,
        billsDueThisWeek: totalBillsDue,
      },
      households: households.map((h) => ({
        id: h.id,
        name: h.name,
        address: h.homeProfile
          ? `${h.homeProfile.addressLine1}, ${h.homeProfile.city}`
          : null,
        primaryContact:
          h.owner?.displayName ||
          `${h.owner?.firstName || ''} ${h.owner?.lastName || ''}`.trim() ||
          'Unknown',
        status: 'good',
        taskCount: 0,
        unreadMessages: 0,
      })),
      pendingOnboarding: pendingOnboarding.map((s) => ({
        id: s.id,
        householdId: s.householdId,
        status: s.status,
        homeownerName:
          s.household.owner?.displayName ||
          `${s.household.owner?.firstName || ''} ${s.household.owner?.lastName || ''}`.trim() ||
          'Unknown',
        homeownerPhone: s.household.owner?.phone,
        address: s.household.homeProfile
          ? `${s.household.homeProfile.addressLine1}, ${s.household.homeProfile.city}`
          : null,
        createdAt: s.createdAt,
      })),
      recentActivity: recentActivity.map((a) => ({
        id: a.id,
        title: a.title,
        description: a.description,
        householdName: a.household.name,
        category: a.category,
        createdAt: a.createdAt,
      })),
    };
  }

  // =========================================================================
  // HOUSEHOLDS
  // =========================================================================

  async getMyHouseholds(managerId: string) {
    const households = await this.prisma.household.findMany({
      where: { managerId },
      include: {
        homeProfile: true,
        owner: {
          select: { id: true, displayName: true, firstName: true, lastName: true, email: true, phone: true },
        },
        familyMembers: true,
        vehicles: true,
        comprehensiveBills: { where: { status: 'ACTIVE' } },
        ownedVendors: true,
        onboardingProgress: true,
      },
    });

    return households.map((h) => {
      const totalMonthly = h.comprehensiveBills.reduce(
        (sum, b) => sum + (Number(b.typicalAmount) || 0),
        0,
      );

      return {
        id: h.id,
        name: h.name,
        tier: h.subscriptionPlan,
        status: h.subscriptionStatus,
        address: h.homeProfile
          ? {
              street: h.homeProfile.addressLine1,
              city: h.homeProfile.city,
              state: h.homeProfile.state,
              zip: h.homeProfile.zipCode,
              full: `${h.homeProfile.addressLine1}, ${h.homeProfile.city}, ${h.homeProfile.state} ${h.homeProfile.zipCode}`,
            }
          : null,
        propertyDetails: h.homeProfile
          ? {
              bedrooms: h.homeProfile.bedrooms,
              bathrooms: h.homeProfile.bathrooms,
              squareFeet: h.homeProfile.squareFeet,
              yearBuilt: h.homeProfile.yearBuilt,
            }
          : null,
        homeowners: [
          {
            id: h.owner?.id,
            name:
              h.owner?.displayName ||
              `${h.owner?.firstName || ''} ${h.owner?.lastName || ''}`.trim(),
            email: h.owner?.email,
            phone: h.owner?.phone,
          },
        ],
        memberCount: h.familyMembers.length,
        vehicleCount: h.vehicles.length,
        billCount: h.comprehensiveBills.length,
        vendorCount: h.ownedVendors.length,
        totalMonthlyBills: totalMonthly,
        onboardingStatus: h.onboardingProgress?.status || 'ACTIVE',
        createdAt: h.createdAt,
      };
    });
  }

  async getHouseholdDetail(managerId: string, householdId: string) {
    // Verify manager has access
    const household = await this.prisma.household.findFirst({
      where: { id: householdId, managerId },
    });

    if (!household) {
      throw new ForbiddenException('You do not manage this household');
    }

    return this.prisma.household.findUnique({
      where: { id: householdId },
      include: {
        homeProfile: {
          include: { zones: { include: { assets: true } } },
        },
        owner: true,
        manager: true,
        familyMembers: { include: { activities: true } },
        vehicles: true,
        ownedVendors: true,
        comprehensiveBills: true,
        onboardingProgress: true,
        activityLogs: {
          take: 50,
          orderBy: { createdAt: 'desc' },
        },
      },
    });
  }

  // =========================================================================
  // ONBOARDING QUEUE
  // =========================================================================

  async getOnboardingQueue(managerId: string, status?: string) {
    const where: any = {
      homeManagerId: managerId,
    };

    if (status && status !== 'active') {
      where.status = status;
    } else {
      where.status = {
        in: [
          'PENDING_CALL',
          'CALL_SCHEDULED',
          'CALL_IN_PROGRESS',
          'INTAKE_PARTIAL',
          'INTAKE_COMPLETE',
          'PROFILE_BUILDING',
        ],
      };
    }

    const sessions = await this.prisma.onboardingProgress.findMany({
      where,
      orderBy: { createdAt: 'asc' },
      include: {
        household: {
          include: {
            homeProfile: true,
            owner: {
              select: {
                id: true,
                displayName: true,
                firstName: true,
                lastName: true,
                email: true,
                phone: true,
              },
            },
          },
        },
      },
    });

    return sessions.map((s) => ({
      id: s.id,
      householdId: s.householdId,
      status: s.status,
      homeownerName:
        s.household.owner?.displayName ||
        `${s.household.owner?.firstName || ''} ${s.household.owner?.lastName || ''}`.trim() ||
        'Unknown',
      homeownerEmail: s.household.owner?.email,
      homeownerPhone: s.household.owner?.phone,
      propertyAddress: s.household.homeProfile
        ? `${s.household.homeProfile.addressLine1}, ${s.household.homeProfile.city}, ${s.household.homeProfile.state}`
        : 'No address',
      biggestChallenge: s.biggestChallenge,
      selectedTier: s.selectedTier,
      callScheduledFor: s.callScheduledFor,
      progress: this.calculateOverallProgress(s),
      enrichmentHighlights: this.getEnrichmentHighlights(s.household.homeProfile),
      createdAt: s.createdAt,
    }));
  }

  private calculateOverallProgress(session: any): number {
    const sections = [
      session.familyComplete || 0,
      session.propertyComplete || 0,
      session.zonesComplete || 0,
      session.systemsComplete || 0,
      session.vendorsComplete || 0,
      session.billsComplete || 0,
    ];
    return Math.round(sections.reduce((a, b) => a + b, 0) / sections.length);
  }

  private getEnrichmentHighlights(homeProfile: any): string[] {
    if (!homeProfile) return [];
    const highlights: string[] = [];

    const enrichment = homeProfile.enrichmentData as any;
    if (!enrichment) return highlights;

    if (enrichment.heatingFuel) highlights.push(`${enrichment.heatingFuel} heat`);
    if (enrichment.pool) highlights.push('Pool');
    if (enrichment.fireplaces > 0) highlights.push(`${enrichment.fireplaces} fireplace(s)`);
    if (enrichment.sewerType === 'Septic') highlights.push('Septic');

    return highlights;
  }

  // =========================================================================
  // ACTIVITY
  // =========================================================================

  async getMyActivity(managerId: string, limit = 50) {
    // Get all households this manager manages
    const households = await this.prisma.household.findMany({
      where: { managerId },
      select: { id: true },
    });

    const householdIds = households.map((h) => h.id);

    return this.prisma.activityLog.findMany({
      where: { householdId: { in: householdIds } },
      orderBy: { createdAt: 'desc' },
      take: limit,
      include: {
        household: { select: { name: true } },
      },
    });
  }

  async logActivity(
    managerId: string,
    managerName: string,
    data: {
      householdId: string;
      action: ActivityAction;
      category: ActivityCategory;
      title: string;
      description?: string;
      amount?: number;
    },
  ) {
    return this.prisma.activityLog.create({
      data: {
        householdId: data.householdId,
        actorId: managerId,
        actorType: ActorType.HOME_MANAGER,
        actorName: managerName,
        action: data.action,
        category: data.category,
        title: data.title,
        description: data.description,
        amount: data.amount,
        visibleToHomeowner: true,
      },
    });
  }
}
