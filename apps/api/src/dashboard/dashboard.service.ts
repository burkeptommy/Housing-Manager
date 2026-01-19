import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ActivityService } from '../activity/activity.service';
import { HomeHealthService } from '../home-health/home-health.service';

@Injectable()
export class DashboardService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly activityService: ActivityService,
    private readonly homeHealthService: HomeHealthService,
  ) {}

  /**
   * Get dashboard data for a household
   */
  async getDashboard(householdId: string) {
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      include: {
        homeProfile: true,
        manager: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            email: true,
            phone: true,
          },
        },
        owner: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
          },
        },
      },
    });

    if (!household) {
      throw new NotFoundException('Household not found');
    }

    // Get billing summary for this month
    const billingSummary = await this.getMonthlySummary(householdId);

    // Get next scheduled service
    const nextService = await this.getNextScheduledService(householdId);

    // Get pending approvals count
    const pendingApprovals = await this.getPendingApprovalsCount(householdId);

    // Get recent activity (last 10)
    const recentActivity = await this.activityService.getRecentForHomeowner(householdId, 10);

    // Get upcoming items (next 7 days)
    const upcoming = await this.getUpcomingItems(householdId, 7);

    // Calculate home health score using the comprehensive HomeHealthService
    const healthResult = await this.homeHealthService.calculateHealthScore(householdId);
    const homeHealth = healthResult.score;

    const propertyAddress = household.homeProfile
      ? `${household.homeProfile.addressLine1}, ${household.homeProfile.city}, ${household.homeProfile.state} ${household.homeProfile.postalCode}`
      : null;

    return {
      household: {
        id: household.id,
        name: household.name,
        propertyAddress,
      },
      manager: household.manager ? {
        id: household.manager.id,
        name: `${household.manager.firstName} ${household.manager.lastName}`.trim(),
        email: household.manager.email,
        phone: household.manager.phone,
      } : null,
      homeHealth,
      billing: {
        monthlyFunding: billingSummary.funding,
        amountPaid: billingSummary.totalPaid,
        billsPaidCount: billingSummary.billsPaidCount,
        bufferRemaining: billingSummary.funding - billingSummary.totalPaid,
      },
      nextService: nextService ? {
        title: nextService.title,
        vendorName: nextService.vendorName,
        date: nextService.scheduledDate,
      } : null,
      pendingApprovals,
      recentActivity: recentActivity.map(a => ({
        id: a.id,
        title: a.title,
        description: a.description,
        actorName: a.actorName,
        category: a.category,
        createdAt: a.createdAt,
      })),
      upcoming: upcoming.map(u => ({
        id: u.id,
        title: u.title,
        type: u.type,
        date: u.date,
      })),
    };
  }

  /**
   * Get monthly billing summary
   */
  async getMonthlySummary(householdId: string) {
    const startOfMonth = new Date();
    startOfMonth.setDate(1);
    startOfMonth.setHours(0, 0, 0, 0);

    const endOfMonth = new Date(startOfMonth);
    endOfMonth.setMonth(endOfMonth.getMonth() + 1);

    // Get household intake for funding amount
    const intake = await this.prisma.householdIntake.findUnique({
      where: { householdId },
      select: { calculatedMonthlyFunding: true },
    });

    // Get payments this month from BillPaymentRecord
    const payments = await this.prisma.billPaymentRecord.findMany({
      where: {
        bill: { householdId },
        paidDate: {
          gte: startOfMonth,
          lt: endOfMonth,
        },
      },
    });

    const totalPaid = payments.reduce((sum, p) => sum + Number(p.amount || 0), 0);
    const funding = Number(intake?.calculatedMonthlyFunding || 0);

    return {
      funding,
      totalPaid,
      billsPaidCount: payments.length,
    };
  }

  /**
   * Get the next scheduled service
   */
  async getNextScheduledService(householdId: string) {
    const now = new Date();

    // Look for upcoming service requests
    const serviceRequest = await this.prisma.serviceRequest.findFirst({
      where: {
        householdId,
        scheduledDate: { gte: now },
        status: { in: ['SUBMITTED', 'ASSIGNED', 'IN_PROGRESS'] },
      },
      include: {
        vendor: {
          select: { displayName: true },
        },
      },
      orderBy: { scheduledDate: 'asc' },
    });

    if (serviceRequest) {
      return {
        id: serviceRequest.id,
        title: serviceRequest.title || serviceRequest.description?.substring(0, 50) || 'Scheduled Service',
        vendorName: serviceRequest.vendor?.displayName || null,
        scheduledDate: serviceRequest.scheduledDate,
      };
    }

    // Look for upcoming work orders
    const workOrder = await this.prisma.workOrder.findFirst({
      where: {
        householdId,
        scheduledStart: { gte: now },
        status: { in: ['SCHEDULED', 'ASSIGNED', 'IN_PROGRESS'] },
      },
      include: {
        vendor: {
          select: { displayName: true },
        },
      },
      orderBy: { scheduledStart: 'asc' },
    });

    if (workOrder) {
      return {
        id: workOrder.id,
        title: workOrder.title,
        vendorName: workOrder.vendor?.displayName || null,
        scheduledDate: workOrder.scheduledStart,
      };
    }

    return null;
  }

  /**
   * Get count of pending approvals for homeowner
   */
  async getPendingApprovalsCount(householdId: string): Promise<number> {
    // Count work orders pending homeowner approval (REQUESTED status means awaiting approval)
    const workOrderCount = await this.prisma.workOrder.count({
      where: {
        householdId,
        status: 'REQUESTED',
      },
    });

    // Could also add approval requests here if we have an Approval model

    return workOrderCount;
  }

  /**
   * Get upcoming items for the next N days
   */
  async getUpcomingItems(householdId: string, days: number) {
    const now = new Date();
    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + days);

    const items: Array<{ id: string; title: string; type: string; date: Date }> = [];

    // Get upcoming services
    const services = await this.prisma.serviceRequest.findMany({
      where: {
        householdId,
        scheduledDate: { gte: now, lte: futureDate },
        status: { in: ['SUBMITTED', 'ASSIGNED', 'IN_PROGRESS'] },
      },
      orderBy: { scheduledDate: 'asc' },
      take: 5,
    });

    services.forEach(s => {
      if (s.scheduledDate) {
        items.push({
          id: s.id,
          title: s.title || 'Scheduled Service',
          type: 'service',
          date: s.scheduledDate,
        });
      }
    });

    // Get upcoming bills due
    const today = now.getDate();
    const endDay = futureDate.getDate();

    const bills = await this.prisma.comprehensiveBill.findMany({
      where: {
        householdId,
        status: 'ACTIVE',
        dueDay: {
          gte: today,
          lte: endDay,
        },
      },
      orderBy: { dueDay: 'asc' },
      take: 5,
    });

    bills.forEach(b => {
      if (b.dueDay) {
        const dueDate = new Date(now.getFullYear(), now.getMonth(), b.dueDay);
        items.push({
          id: b.id,
          title: b.name,
          type: 'bill',
          date: dueDate,
        });
      }
    });

    // Sort by date
    return items.sort((a, b) => a.date.getTime() - b.date.getTime()).slice(0, 10);
  }

  /**
   * Calculate home health score based on various factors
   */
  async calculateHealthScore(householdId: string): Promise<number> {
    const healthResult = await this.homeHealthService.calculateHealthScore(householdId);
    return healthResult.score;
  }

  /**
   * Get full health score with factors breakdown
   */
  async getFullHealthScore(householdId: string) {
    const healthResult = await this.homeHealthService.calculateHealthScore(householdId);

    // Group factors by positive/negative for easier UI display
    const helping = healthResult.factors
      .filter(f => f.status === 'positive')
      .map(f => f.description);

    const needsAttention = healthResult.factors
      .filter(f => f.status === 'negative')
      .map(f => f.description);

    return {
      score: healthResult.score,
      maxScore: healthResult.maxScore,
      grade: healthResult.grade,
      factors: {
        helping,
        needsAttention,
      },
      recommendations: healthResult.recommendations,
      detailedFactors: healthResult.factors,
    };
  }

  /**
   * Get today's notes aggregated from various sources
   */
  async getTodaysNotes(householdId: string) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const nextWeek = new Date(today);
    nextWeek.setDate(nextWeek.getDate() + 7);

    const notes: Array<{
      id: string;
      type: 'bill' | 'maintenance' | 'service' | 'activity' | 'event';
      icon: string;
      text: string;
      color: string;
      priority: number;
    }> = [];

    // 1. Bills due in the next 3 days
    const currentDay = today.getDate();
    const threeDaysFromNow = new Date(today);
    threeDaysFromNow.setDate(threeDaysFromNow.getDate() + 3);
    const threeDaysDay = threeDaysFromNow.getDate();

    const billsDue = await this.prisma.comprehensiveBill.findMany({
      where: {
        householdId,
        status: 'ACTIVE',
        dueDay: {
          gte: currentDay,
          lte: threeDaysDay,
        },
      },
      take: 5,
    });

    billsDue.forEach(bill => {
      const daysUntilDue = (bill.dueDay || 0) - currentDay;
      const dueText = daysUntilDue === 0 ? 'today' : daysUntilDue === 1 ? 'tomorrow' : `in ${daysUntilDue} days`;
      notes.push({
        id: `bill-${bill.id}`,
        type: 'bill',
        icon: 'card-outline',
        text: `${bill.name} due ${dueText}`,
        color: daysUntilDue === 0 ? '#dc2626' : '#c4a574',
        priority: daysUntilDue === 0 ? 1 : 2,
      });
    });

    // 2. Maintenance tasks due soon
    const maintenanceTasks = await this.prisma.maintenanceTask.findMany({
      where: {
        householdId,
        status: { in: ['PENDING', 'DUE_SOON', 'OVERDUE'] },
        dueDate: { lte: nextWeek },
      },
      take: 5,
      orderBy: { dueDate: 'asc' },
    });

    maintenanceTasks.forEach(task => {
      const isOverdue = task.status === 'OVERDUE' || (task.dueDate && task.dueDate < today);
      notes.push({
        id: `maintenance-${task.id}`,
        type: 'maintenance',
        icon: 'construct-outline',
        text: isOverdue ? `${task.title} is overdue` : `${task.title} due soon`,
        color: isOverdue ? '#dc2626' : '#f59e0b',
        priority: isOverdue ? 1 : 3,
      });
    });

    // 3. Scheduled services today/tomorrow
    const upcomingServices = await this.prisma.serviceRequest.findMany({
      where: {
        householdId,
        scheduledDate: {
          gte: today,
          lt: tomorrow,
        },
        status: { in: ['SUBMITTED', 'ASSIGNED', 'IN_PROGRESS', 'SCHEDULED'] },
      },
      include: {
        vendor: { select: { displayName: true } },
      },
      take: 3,
    });

    upcomingServices.forEach(service => {
      const time = service.scheduledDate
        ? new Date(service.scheduledDate).toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' })
        : '';
      notes.push({
        id: `service-${service.id}`,
        type: 'service',
        icon: 'hammer-outline',
        text: `${service.vendor?.displayName || 'Service'} ${time ? `at ${time}` : 'scheduled today'}`,
        color: '#3b82f6',
        priority: 2,
      });
    });

    // 4. Family activities today
    const familyActivities = await this.prisma.kidActivity.findMany({
      where: { householdId },
      include: {
        familyMember: { select: { firstName: true } },
      },
      take: 5,
    });

    // Check if any activities have schedules that mention today's day
    const todayDayName = today.toLocaleDateString('en-US', { weekday: 'long' }).toLowerCase();
    familyActivities.forEach(activity => {
      if (activity.schedule?.toLowerCase().includes(todayDayName)) {
        notes.push({
          id: `activity-${activity.id}`,
          type: 'activity',
          icon: 'calendar-outline',
          text: `${activity.familyMember?.firstName || 'Family'}'s ${activity.name}`,
          color: '#c4a574',
          priority: 4,
        });
      }
    });

    // 5. Family events today
    const familyEvents = await this.prisma.familyEvent.findMany({
      where: {
        householdId,
        startDate: {
          gte: today,
          lt: tomorrow,
        },
      },
      take: 5,
    });

    familyEvents.forEach(event => {
      const time = event.startDate
        ? new Date(event.startDate).toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' })
        : '';
      notes.push({
        id: `event-${event.id}`,
        type: 'event',
        icon: 'calendar-outline',
        text: `${event.title}${time ? ` at ${time}` : ''}`,
        color: event.color || '#627d98',
        priority: 3,
      });
    });

    // Sort by priority
    notes.sort((a, b) => a.priority - b.priority);

    return {
      notes: notes.slice(0, 10),
      isEmpty: notes.length === 0,
      counts: {
        bills: billsDue.length,
        maintenance: maintenanceTasks.length,
        services: upcomingServices.length,
        activities: familyActivities.filter(a =>
          a.schedule?.toLowerCase().includes(todayDayName)
        ).length,
        events: familyEvents.length,
      },
    };
  }

  /**
   * Get setup/onboarding status for a household
   * Returns completion status for each setup step
   */
  async getSetupStatus(householdId: string) {
    const [
      user,
      homeProfile,
      familyMemberCount,
      vendorCount,
      documentCount,
      hasHvacSystem,
      hasElectricVendor,
    ] = await Promise.all([
      // Get household owner
      this.prisma.household.findUnique({
        where: { id: householdId },
        include: { owner: { select: { firstName: true, lastName: true } } },
      }),
      // Get home profile
      this.prisma.homeProfile.findUnique({
        where: { householdId },
      }),
      // Family members count
      this.prisma.familyMember.count({
        where: { householdId },
      }),
      // Vendors count
      this.prisma.householdVendor.count({
        where: { householdId },
      }),
      // Documents count
      this.prisma.document.count({
        where: { householdId },
      }),
      // Check for HVAC system
      this.prisma.propertyAsset.count({
        where: { householdId, category: 'HVAC', isActive: true },
      }),
      // Check for electric vendor - look in household vendors
      this.prisma.householdVendor.count({
        where: {
          householdId,
          vendor: {
            category: 'UTILITY',
          },
        },
      }),
    ]);

    // Calculate completion
    const items = {
      profile: !!(user?.owner?.firstName && user?.owner?.lastName),
      property: !!(homeProfile?.bedrooms && homeProfile?.bathrooms),
      heating: hasHvacSystem > 0,
      electricity: hasElectricVendor > 0,
      family: familyMemberCount > 1, // More than just the owner
      documents: documentCount > 0,
      vendors: vendorCount > 0,
    };

    const completedCount = Object.values(items).filter(Boolean).length;
    const totalCount = Object.keys(items).length;

    return {
      items,
      completedCount,
      totalCount,
      progress: completedCount / totalCount,
      isComplete: completedCount === totalCount,
    };
  }

  /**
   * Get all bills for a household grouped by category
   */
  async getBills(householdId: string) {
    const bills = await this.prisma.comprehensiveBill.findMany({
      where: {
        householdId,
        status: 'ACTIVE',
      },
      include: {
        payments: {
          orderBy: { paidDate: 'desc' },
          take: 1,
        },
        vendor: {
          select: { id: true, displayName: true },
        },
      },
      orderBy: [{ category: 'asc' }, { name: 'asc' }],
    });

    // Get monthly funding
    const intake = await this.prisma.householdIntake.findUnique({
      where: { householdId },
      select: { calculatedMonthlyFunding: true },
    });

    // Calculate totals by category
    const byCategory: Record<string, { bills: typeof bills; total: number }> = {};
    let totalMonthly = 0;

    bills.forEach(bill => {
      const category = bill.category;
      if (!byCategory[category]) {
        byCategory[category] = { bills: [], total: 0 };
      }
      byCategory[category].bills.push(bill);

      // Calculate monthly amount based on frequency
      let monthlyAmount = Number(bill.amount) || 0;
      switch (bill.frequency?.toLowerCase()) {
        case 'weekly':
          monthlyAmount = monthlyAmount * 4.33;
          break;
        case 'bi-weekly':
          monthlyAmount = monthlyAmount * 2.17;
          break;
        case 'quarterly':
          monthlyAmount = monthlyAmount / 3;
          break;
        case 'semi-annually':
        case 'semi-annual':
          monthlyAmount = monthlyAmount / 6;
          break;
        case 'annually':
        case 'annual':
          monthlyAmount = monthlyAmount / 12;
          break;
        // monthly is default
      }

      byCategory[category].total += monthlyAmount;
      totalMonthly += monthlyAmount;
    });

    return {
      bills: bills.map(bill => ({
        id: bill.id,
        category: bill.category,
        name: bill.name,
        payeeName: bill.payeeName,
        amount: Number(bill.amount),
        frequency: bill.frequency,
        dueDay: bill.dueDay,
        status: bill.status,
        havenManaged: bill.havenManaged,
        verified: bill.verified,
        currentAutopay: bill.currentAutopay,
        vendor: bill.vendor?.displayName,
        lastPayment: bill.payments[0] ? {
          amount: Number(bill.payments[0].amount),
          date: bill.payments[0].paidDate,
          status: bill.payments[0].paidBy || 'Haven',
        } : null,
      })),
      byCategory: Object.entries(byCategory).map(([category, data]) => ({
        category,
        billCount: data.bills.length,
        monthlyTotal: Math.round(data.total * 100) / 100,
      })),
      summary: {
        totalBills: bills.length,
        monthlyTotal: Math.round(totalMonthly * 100) / 100,
        monthlyFunding: Number(intake?.calculatedMonthlyFunding || 0),
      },
    };
  }

  /**
   * Create a new bill for a household
   */
  async createBill(
    householdId: string,
    data: {
      name: string;
      category: string;
      amount: number;
      frequency: string;
      dueDay?: number | null;
    },
  ) {
    // Map category to BillCategory enum if possible
    const categoryMap: Record<string, string> = {
      MORTGAGE_RENT: 'MORTGAGE_RENT',
      UTILITY: 'UTILITY',
      INSURANCE: 'INSURANCE',
      HOME_SERVICE: 'HOME_SERVICE',
      VEHICLE: 'VEHICLE',
      KID_ACTIVITY: 'KID_ACTIVITIES',
      PET: 'PET',
      HEALTH: 'HEALTH',
      OTHER: 'OTHER',
    };

    const mappedCategory = categoryMap[data.category] || 'OTHER';

    const bill = await this.prisma.comprehensiveBill.create({
      data: {
        householdId,
        category: mappedCategory as any,
        name: data.name,
        amount: data.amount,
        frequency: data.frequency as any,
        dueDay: data.dueDay,
        status: 'ACTIVE',
        havenManaged: false,
        verified: false,
        currentAutopay: false,
      },
    });

    return { success: true, bill };
  }

  /**
   * Get onboarding checklist status for a household
   * Returns which onboarding items have been completed
   */
  async getOnboardingChecklist(householdId: string) {
    // Check if bank is connected (Plaid link exists)
    const bankConnected = await this.prisma.plaidLink.count({
      where: { householdId },
    }) > 0;

    // Check if HVAC system exists (PropertyAsset with HVAC category)
    const hasHvacSystem = await this.prisma.propertyAsset.count({
      where: {
        householdId,
        category: 'HVAC',
        isActive: true,
      },
    }) > 0;

    // Check if any documents exist in vault
    const hasDocuments = await this.prisma.document.count({
      where: { householdId },
    }) > 0;

    // Check if family members beyond owner exist (more than 1)
    const familyMemberCount = await this.prisma.familyMember.count({
      where: { householdId },
    });
    const hasFamilyMembers = familyMemberCount > 1;

    // Check if any maintenance tasks exist
    const hasMaintenanceTask = await this.prisma.maintenanceTask.count({
      where: { householdId },
    }) > 0;

    // Check if any vendors are added
    const hasVendor = await this.prisma.householdVendor.count({
      where: { householdId },
    }) > 0;

    return {
      bankConnected,
      hasHvacSystem,
      hasDocuments,
      hasFamilyMembers,
      hasMaintenanceTask,
      hasVendor,
    };
  }

  /**
   * Get family data for a household
   */
  async getFamily(householdId: string) {
    // Get family members
    const members = await this.prisma.familyMember.findMany({
      where: { householdId },
      include: {
        activities: true,
      },
      orderBy: [{ type: 'asc' }, { firstName: 'asc' }],
    });

    // Get pets
    const pets = await this.prisma.pet.findMany({
      where: { householdId },
      orderBy: { name: 'asc' },
    });

    // Calculate summary
    const adults = members.filter(m => m.type === 'ADULT');
    const children = members.filter(m => m.type === 'CHILD');
    const staff = members.filter(m => m.type === 'STAFF');

    // Get all activities
    const activities = await this.prisma.kidActivity.findMany({
      where: { householdId },
      include: {
        familyMember: {
          select: { firstName: true, lastName: true },
        },
      },
      orderBy: { name: 'asc' },
    });

    // Calculate monthly activities cost
    let monthlyActivitiesCost = 0;
    activities.forEach(activity => {
      let monthlyCost = Number(activity.cost) || 0;
      switch (activity.costFrequency?.toUpperCase()) {
        case 'WEEKLY':
          monthlyCost = monthlyCost * 4.33;
          break;
        case 'QUARTERLY':
          monthlyCost = monthlyCost / 3;
          break;
        case 'SEMI_ANNUALLY':
          monthlyCost = monthlyCost / 6;
          break;
        case 'ANNUALLY':
          monthlyCost = monthlyCost / 12;
          break;
        // MONTHLY is default
      }
      monthlyActivitiesCost += monthlyCost;
    });

    return {
      members: members.map(m => ({
        id: m.id,
        firstName: m.firstName,
        lastName: m.lastName,
        nickname: m.nickname,
        type: m.type,
        relationship: m.relationship,
        email: m.email,
        phone: m.phone,
        birthdate: m.birthdate,
        school: m.school,
        schoolGrade: m.schoolGrade,
        teacher: m.teacher,
        workSchedule: m.workSchedule,
        responsibilities: m.responsibilities,
        activitiesCount: m.activities?.length || 0,
      })),
      pets: pets.map(p => ({
        id: p.id,
        name: p.name,
        type: p.type,
        breed: p.breed,
        color: p.color,
        size: p.size,
        weight: p.weight ? Number(p.weight) : null,
        birthday: p.birthday,
        gender: p.gender,
        vetClinicName: p.vetClinicName,
        vetClinicPhone: p.vetClinicPhone,
        allergies: p.allergies,
        medications: p.medications,
        specialNeeds: p.specialNeeds,
      })),
      activities: activities.map(a => ({
        id: a.id,
        name: a.name,
        type: a.type,
        organization: a.organization,
        location: a.location,
        schedule: a.schedule,
        cost: a.cost ? Number(a.cost) : null,
        costFrequency: a.costFrequency,
        coachName: a.coachName,
        contactPhone: a.contactPhone,
        memberName: a.familyMember
          ? `${a.familyMember.firstName} ${a.familyMember.lastName || ''}`.trim()
          : null,
      })),
      summary: {
        adultsCount: adults.length,
        childrenCount: children.length,
        staffCount: staff.length,
        petsCount: pets.length,
        activitiesCount: activities.length,
        monthlyActivitiesCost: Math.round(monthlyActivitiesCost * 100) / 100,
      },
    };
  }
}
