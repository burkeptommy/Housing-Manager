import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ActivityService } from '../activity/activity.service';

@Injectable()
export class DashboardService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly activityService: ActivityService,
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

    // Calculate home health score
    const homeHealth = await this.calculateHealthScore(householdId);

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
        paidAt: {
          gte: startOfMonth,
          lt: endOfMonth,
        },
        status: 'COMPLETED',
      },
    });

    const totalPaid = payments.reduce((sum, p) => sum + Number(p.amountPaid || 0), 0);
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
        status: { in: ['SCHEDULED', 'CONFIRMED'] },
      },
      include: {
        vendor: {
          select: { name: true },
        },
      },
      orderBy: { scheduledDate: 'asc' },
    });

    if (serviceRequest) {
      return {
        id: serviceRequest.id,
        title: serviceRequest.title || serviceRequest.description?.substring(0, 50) || 'Scheduled Service',
        vendorName: serviceRequest.vendor?.name || null,
        scheduledDate: serviceRequest.scheduledDate,
      };
    }

    // Look for upcoming work orders
    const workOrder = await this.prisma.workOrder.findFirst({
      where: {
        householdId,
        scheduledDate: { gte: now },
        status: { in: ['PENDING', 'APPROVED', 'ASSIGNED'] },
      },
      include: {
        vendor: {
          select: { displayName: true },
        },
      },
      orderBy: { scheduledDate: 'asc' },
    });

    if (workOrder) {
      return {
        id: workOrder.id,
        title: workOrder.title,
        vendorName: workOrder.vendor?.displayName || null,
        scheduledDate: workOrder.scheduledDate,
      };
    }

    return null;
  }

  /**
   * Get count of pending approvals for homeowner
   */
  async getPendingApprovalsCount(householdId: string): Promise<number> {
    // Count work orders pending homeowner approval
    const workOrderCount = await this.prisma.workOrder.count({
      where: {
        householdId,
        status: 'PENDING_APPROVAL',
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
        status: { in: ['SCHEDULED', 'CONFIRMED'] },
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
    let score = 100;

    // Check for overdue maintenance
    const overdueAssets = await this.prisma.propertyAsset.count({
      where: {
        householdId,
        isActive: true,
        nextServiceDate: { lt: new Date() },
      },
    });
    score -= overdueAssets * 5;

    // Check for assets in poor condition
    const poorConditionAssets = await this.prisma.propertyAsset.count({
      where: {
        householdId,
        isActive: true,
        condition: { in: ['Poor', 'Needs Replacement'] },
      },
    });
    score -= poorConditionAssets * 10;

    // Check for pending work orders
    const pendingWorkOrders = await this.prisma.workOrder.count({
      where: {
        householdId,
        status: { in: ['PENDING', 'PENDING_APPROVAL'] },
      },
    });
    score -= pendingWorkOrders * 3;

    // Check for open service requests
    const openServiceRequests = await this.prisma.serviceRequest.count({
      where: {
        householdId,
        status: { in: ['PENDING', 'IN_PROGRESS'] },
      },
    });
    score -= openServiceRequests * 2;

    // Ensure score is between 0 and 100
    return Math.max(0, Math.min(100, score));
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
        paymentRecords: {
          orderBy: { paidAt: 'desc' },
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
        lastPayment: bill.paymentRecords[0] ? {
          amount: Number(bill.paymentRecords[0].amountPaid),
          date: bill.paymentRecords[0].paidAt,
          status: bill.paymentRecords[0].status,
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
