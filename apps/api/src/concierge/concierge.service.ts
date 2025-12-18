import { Injectable, NotFoundException, BadRequestException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  CreateConciergeRequestDto,
  HandymanCheckInDto,
  HandymanCheckOutDto,
  AssignHandymanDto,
  RejectRequestDto,
  HouseholdProfitQueryDto,
  ConciergeRequestResponseDto,
  HouseholdProfitResponseDto,
  HandymanDashboardDto,
  ConciergeTaskType,
} from './dto';
import { WorkOrderStatus, WorkOrderBillingType, ServiceCategoryTier, TransactionStatus, TransactionPayoutMethod } from '@prisma/client';

// Default hourly rate for handymen (can be made configurable per user later)
const DEFAULT_HANDYMAN_HOURLY_RATE = 35;

@Injectable()
export class ConciergeService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Create a concierge request (homeowner flow)
   * Automatically routes to household's assigned handyman if eligible
   */
  async createConciergeRequest(
    userId: string,
    householdId: string,
    dto: CreateConciergeRequestDto,
  ): Promise<ConciergeRequestResponseDto> {
    // Verify user belongs to household
    const membership = await this.prisma.householdMember.findFirst({
      where: { userId, householdId, status: 'ACTIVE' },
    });

    if (!membership) {
      throw new ForbiddenException('You do not have access to this household');
    }

    // Get household with handyman
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      include: {
        assignedHandyman: true,
        homeProfile: true,
      },
    });

    if (!household) {
      throw new NotFoundException('Household not found');
    }

    // Check if concierge is enabled for this household
    if (!household.conciergeEnabled) {
      throw new BadRequestException('Concierge service is not enabled for this household');
    }

    // Determine service category based on task type
    const categoryMapping: Record<ConciergeTaskType, string> = {
      [ConciergeTaskType.FILTER_CHANGE]: 'General Handyman',
      [ConciergeTaskType.LIGHT_BULB]: 'General Handyman',
      [ConciergeTaskType.LOOSE_HINGE]: 'General Handyman',
      [ConciergeTaskType.CAULKING]: 'General Handyman',
      [ConciergeTaskType.MINOR_REPAIR]: 'General Handyman',
      [ConciergeTaskType.SMOKE_DETECTOR_BATTERY]: 'General Handyman',
      [ConciergeTaskType.GENERAL_INSPECTION]: 'General Handyman',
      [ConciergeTaskType.OTHER]: 'General Handyman',
    };

    // Find or create the service category
    let serviceCategory = await this.prisma.serviceCategory.findFirst({
      where: { name: categoryMapping[dto.taskType] },
    });

    // Determine billing type based on service category tier
    const billingType = serviceCategory?.tier === ServiceCategoryTier.MINOR_MAINTENANCE
      ? WorkOrderBillingType.INCLUSIVE
      : WorkOrderBillingType.BILLABLE_TO_CLIENT;

    // Create the work order
    const workOrder = await this.prisma.workOrder.create({
      data: {
        householdId,
        createdByUserId: userId,
        serviceCategoryId: serviceCategory?.id,
        handymanId: household.assignedHandymanId, // Auto-assign to household's handyman
        title: dto.title,
        description: dto.description || `${dto.taskType}: ${dto.title}`,
        status: household.assignedHandymanId ? WorkOrderStatus.ASSIGNED : WorkOrderStatus.OPEN,
        isConciergeRequest: true,
        billingType,
        preferredDate: dto.preferredDate ? new Date(dto.preferredDate) : null,
        preferredTimeWindowStart: dto.preferredTimeStart,
        preferredTimeWindowEnd: dto.preferredTimeEnd,
        serviceArea: household.homeProfile?.city || null,
      },
      include: {
        handyman: {
          select: {
            id: true,
            displayName: true,
            phone: true,
          },
        },
      },
    });

    // If no handyman assigned, notify manager
    if (!household.assignedHandymanId && household.managerId) {
      await this.notifyManagerOfUnassignedRequest(
        household.managerId,
        householdId,
        workOrder.id,
        workOrder.title,
      );
    }

    return {
      id: workOrder.id,
      title: workOrder.title,
      description: workOrder.description,
      status: workOrder.status,
      billingType: workOrder.billingType,
      isConciergeRequest: workOrder.isConciergeRequest,
      scheduledStart: workOrder.scheduledStart,
      scheduledEnd: workOrder.scheduledEnd,
      handyman: workOrder.handyman,
      createdAt: workOrder.createdAt,
    };
  }

  /**
   * Get concierge requests for a household
   */
  async getHouseholdConciergeRequests(
    userId: string,
    householdId: string,
  ): Promise<ConciergeRequestResponseDto[]> {
    // Verify access
    const membership = await this.prisma.householdMember.findFirst({
      where: { userId, householdId, status: 'ACTIVE' },
    });

    if (!membership) {
      throw new ForbiddenException('You do not have access to this household');
    }

    const workOrders = await this.prisma.workOrder.findMany({
      where: {
        householdId,
        isConciergeRequest: true,
      },
      include: {
        handyman: {
          select: {
            id: true,
            displayName: true,
            phone: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return workOrders.map((wo) => ({
      id: wo.id,
      title: wo.title,
      description: wo.description,
      status: wo.status,
      billingType: wo.billingType,
      isConciergeRequest: wo.isConciergeRequest,
      scheduledStart: wo.scheduledStart,
      scheduledEnd: wo.scheduledEnd,
      handyman: wo.handyman,
      createdAt: wo.createdAt,
    }));
  }

  /**
   * Handyman check-in with geolocation
   */
  async handymanCheckIn(handymanId: string, dto: HandymanCheckInDto): Promise<void> {
    const workOrder = await this.prisma.workOrder.findUnique({
      where: { id: dto.workOrderId },
    });

    if (!workOrder) {
      throw new NotFoundException('Work order not found');
    }

    if (workOrder.handymanId !== handymanId) {
      throw new ForbiddenException('This work order is not assigned to you');
    }

    if (workOrder.status !== WorkOrderStatus.ASSIGNED) {
      throw new BadRequestException('Work order must be in ASSIGNED status to check in');
    }

    await this.prisma.workOrder.update({
      where: { id: dto.workOrderId },
      data: {
        status: WorkOrderStatus.IN_PROGRESS,
        checkInAt: new Date(),
        checkInLatitude: dto.latitude,
        checkInLongitude: dto.longitude,
      },
    });
  }

  /**
   * Handyman check-out with completion details
   */
  async handymanCheckOut(handymanId: string, dto: HandymanCheckOutDto): Promise<void> {
    const workOrder = await this.prisma.workOrder.findUnique({
      where: { id: dto.workOrderId },
      include: { household: true },
    });

    if (!workOrder) {
      throw new NotFoundException('Work order not found');
    }

    if (workOrder.handymanId !== handymanId) {
      throw new ForbiddenException('This work order is not assigned to you');
    }

    if (workOrder.status !== WorkOrderStatus.IN_PROGRESS) {
      throw new BadRequestException('Work order must be in IN_PROGRESS status to check out');
    }

    // Calculate internal cost if hours worked provided
    const hoursWorked = dto.hoursWorked || 0;
    const internalCost = hoursWorked * DEFAULT_HANDYMAN_HOURLY_RATE;

    // Update work order
    await this.prisma.workOrder.update({
      where: { id: dto.workOrderId },
      data: {
        status: WorkOrderStatus.COMPLETED,
        checkOutAt: new Date(),
        completedAt: new Date(),
        proofImages: dto.proofImages || [],
        internalCost: internalCost > 0 ? internalCost : null,
      },
    });

    // If work order has notes, create a work order note
    if (dto.notes) {
      await this.prisma.workOrderNote.create({
        data: {
          workOrderId: dto.workOrderId,
          authorUserId: handymanId,
          body: dto.notes,
        },
      });
    }

    // For inclusive tasks, log expense against company wallet
    if (workOrder.billingType === WorkOrderBillingType.INCLUSIVE && internalCost > 0) {
      await this.logInclusiveExpense(workOrder.id, workOrder.householdId, handymanId, hoursWorked, internalCost);
    }
  }

  /**
   * Log an inclusive expense (company absorbs cost)
   */
  private async logInclusiveExpense(
    workOrderId: string,
    householdId: string,
    handymanId: string,
    hoursWorked: number,
    amount: number,
  ): Promise<void> {
    // Get a manager for this household (or system admin)
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      select: { managerId: true },
    });

    // Use household manager or find an admin
    let managerId = household?.managerId;
    if (!managerId) {
      const admin = await this.prisma.user.findFirst({
        where: { role: 'ADMIN' },
        select: { id: true },
      });
      managerId = admin?.id || handymanId; // Fallback to handyman
    }

    // Create transaction record
    await this.prisma.transaction.create({
      data: {
        householdId,
        handymanId,
        managerId,
        workOrderId,
        description: 'Inclusive concierge service',
        amount,
        payoutMethod: TransactionPayoutMethod.CASH, // Internal cost tracking
        status: TransactionStatus.PAID_TO_VENDOR, // Immediately "paid" (cost absorbed)
        isReimbursable: false, // Client doesn't reimburse
        isInclusiveExpense: true,
        handymanHours: hoursWorked,
        handymanHourlyRate: DEFAULT_HANDYMAN_HOURLY_RATE,
        paidAt: new Date(),
      },
    });

    // Update company wallet outstanding float (optional - for tracking)
    await this.prisma.companyWallet.updateMany({
      data: {
        monthlyDisbursements: { increment: amount },
      },
    });
  }

  /**
   * Assign handyman to work order (manager function)
   */
  async assignHandyman(managerId: string, dto: AssignHandymanDto): Promise<void> {
    // Verify work order exists and manager has access
    const workOrder = await this.prisma.workOrder.findUnique({
      where: { id: dto.workOrderId },
      include: { household: true },
    });

    if (!workOrder) {
      throw new NotFoundException('Work order not found');
    }

    // Verify manager has access to this household
    if (workOrder.household.managerId !== managerId) {
      // Check if user is admin
      const user = await this.prisma.user.findUnique({
        where: { id: managerId },
        select: { role: true },
      });
      if (user?.role !== 'ADMIN') {
        throw new ForbiddenException('You do not have access to this household');
      }
    }

    // Verify handyman exists and has HANDYMAN role
    const handyman = await this.prisma.user.findUnique({
      where: { id: dto.handymanId },
      select: { role: true },
    });

    if (!handyman || handyman.role !== 'HANDYMAN') {
      throw new BadRequestException('Invalid handyman user');
    }

    await this.prisma.workOrder.update({
      where: { id: dto.workOrderId },
      data: {
        handymanId: dto.handymanId,
        status: WorkOrderStatus.ASSIGNED,
      },
    });
  }

  /**
   * Get profit per household report
   */
  async getHouseholdProfit(
    householdId: string,
    query: HouseholdProfitQueryDto,
  ): Promise<HouseholdProfitResponseDto> {
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      select: {
        id: true,
        name: true,
        subscriptionPlan: true,
      },
    });

    if (!household) {
      throw new NotFoundException('Household not found');
    }

    // Default to current month
    const startDate = query.startDate
      ? new Date(query.startDate)
      : new Date(new Date().getFullYear(), new Date().getMonth(), 1);
    const endDate = query.endDate
      ? new Date(query.endDate)
      : new Date(new Date().getFullYear(), new Date().getMonth() + 1, 0);

    // Get subscription revenue (simplified - would need pricing lookup)
    const subscriptionPricing: Record<string, number> = {
      FREE: 0,
      ESSENTIALS: 99,
      PREMIUM: 249,
    };
    const subscriptionRevenue = subscriptionPricing[household.subscriptionPlan] || 0;

    // Get inclusive expenses (costs company absorbed)
    const inclusiveExpenses = await this.prisma.transaction.aggregate({
      where: {
        householdId,
        isInclusiveExpense: true,
        createdAt: { gte: startDate, lte: endDate },
      },
      _sum: { amount: true },
      _count: true,
    });

    // Get billable revenue (from work orders)
    const billableWorkOrders = await this.prisma.workOrder.aggregate({
      where: {
        householdId,
        billingType: WorkOrderBillingType.BILLABLE_TO_CLIENT,
        status: WorkOrderStatus.VERIFIED,
        verifiedAt: { gte: startDate, lte: endDate },
      },
      _sum: { actualCost: true },
      _count: true,
    });

    const inclusiveCosts = Number(inclusiveExpenses._sum.amount || 0);
    const billableRevenue = Number(billableWorkOrders._sum.actualCost || 0);
    const netProfit = subscriptionRevenue - inclusiveCosts + (billableRevenue * 0.15); // Assuming 15% markup on billable

    return {
      householdId: household.id,
      householdName: household.name,
      subscriptionPlan: household.subscriptionPlan,
      period: {
        startDate: startDate.toISOString().split('T')[0],
        endDate: endDate.toISOString().split('T')[0],
      },
      subscriptionRevenue,
      inclusiveCosts,
      billableRevenue,
      netProfit,
      inclusiveTaskCount: inclusiveExpenses._count || 0,
      billableTaskCount: billableWorkOrders._count || 0,
    };
  }

  /**
   * Get handyman dashboard data
   */
  async getHandymanDashboard(handymanId: string): Promise<HandymanDashboardDto> {
    const handyman = await this.prisma.user.findUnique({
      where: { id: handymanId },
      select: {
        id: true,
        displayName: true,
        firstName: true,
        lastName: true,
        role: true,
      },
    });

    if (!handyman || handyman.role !== 'HANDYMAN') {
      throw new ForbiddenException('User is not a handyman');
    }

    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);
    const startOfMonth = new Date(today.getFullYear(), today.getMonth(), 1);

    // Get today's tasks
    const todaysTasks = await this.prisma.workOrder.findMany({
      where: {
        handymanId,
        status: { in: [WorkOrderStatus.ASSIGNED, WorkOrderStatus.IN_PROGRESS] },
        scheduledStart: { gte: today, lt: tomorrow },
      },
      include: {
        household: {
          include: { homeProfile: true },
        },
      },
      orderBy: { scheduledStart: 'asc' },
    });

    // Get upcoming tasks (next 7 days)
    const nextWeek = new Date(today);
    nextWeek.setDate(nextWeek.getDate() + 7);
    const upcomingTasks = await this.prisma.workOrder.findMany({
      where: {
        handymanId,
        status: { in: [WorkOrderStatus.ASSIGNED] },
        scheduledStart: { gte: tomorrow, lt: nextWeek },
      },
      include: {
        household: true,
      },
      orderBy: { scheduledStart: 'asc' },
      take: 10,
    });

    // Get assigned households
    const assignedHouseholds = await this.prisma.household.findMany({
      where: { assignedHandymanId: handymanId },
      include: { homeProfile: true },
    });

    // Get stats
    const completedThisMonth = await this.prisma.workOrder.count({
      where: {
        handymanId,
        status: WorkOrderStatus.COMPLETED,
        completedAt: { gte: startOfMonth },
      },
    });

    const hoursAggregate = await this.prisma.transaction.aggregate({
      where: {
        handymanId,
        isInclusiveExpense: true,
        createdAt: { gte: startOfMonth },
      },
      _sum: { handymanHours: true },
    });

    const pendingTasks = await this.prisma.workOrder.count({
      where: {
        handymanId,
        status: { in: [WorkOrderStatus.ASSIGNED, WorkOrderStatus.IN_PROGRESS] },
      },
    });

    return {
      handymanId: handyman.id,
      handymanName: handyman.displayName || `${handyman.firstName} ${handyman.lastName}`,
      todaysTasks: todaysTasks.map((t) => ({
        id: t.id,
        title: t.title,
        householdName: t.household.name,
        scheduledStart: t.scheduledStart,
        status: t.status,
        address: t.household.homeProfile?.addressLine1 || null,
      })),
      upcomingTasks: upcomingTasks.map((t) => ({
        id: t.id,
        title: t.title,
        householdName: t.household.name,
        scheduledStart: t.scheduledStart,
        status: t.status,
      })),
      assignedHouseholds: assignedHouseholds.map((h) => ({
        id: h.id,
        name: h.name,
        address: h.homeProfile?.addressLine1 || null,
        monthlyVisitDay: h.monthlyVisitDay,
        conciergeEnabled: h.conciergeEnabled,
      })),
      stats: {
        completedThisMonth,
        hoursThisMonth: Number(hoursAggregate._sum.handymanHours || 0),
        pendingTasks,
      },
    };
  }

  /**
   * Get all handymen (for assignment dropdown)
   */
  async getHandymen(): Promise<{ id: string; displayName: string | null; email: string }[]> {
    const handymen = await this.prisma.user.findMany({
      where: { role: 'HANDYMAN' },
      select: {
        id: true,
        displayName: true,
        email: true,
      },
      orderBy: { displayName: 'asc' },
    });

    return handymen;
  }

  /**
   * Assign handyman to household (manager function)
   */
  async assignHandymanToHousehold(
    managerId: string,
    householdId: string,
    handymanId: string,
  ): Promise<void> {
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
    });

    if (!household) {
      throw new NotFoundException('Household not found');
    }

    // Verify manager access
    if (household.managerId !== managerId) {
      const user = await this.prisma.user.findUnique({
        where: { id: managerId },
        select: { role: true },
      });
      if (user?.role !== 'ADMIN') {
        throw new ForbiddenException('You do not have access to this household');
      }
    }

    // Verify handyman
    const handyman = await this.prisma.user.findUnique({
      where: { id: handymanId },
      select: { role: true },
    });

    if (!handyman || handyman.role !== 'HANDYMAN') {
      throw new BadRequestException('Invalid handyman user');
    }

    await this.prisma.household.update({
      where: { id: householdId },
      data: {
        assignedHandymanId: handymanId,
        conciergeEnabled: true, // Auto-enable concierge when handyman assigned
      },
    });
  }

  /**
   * Handyman rejects a work order assignment
   */
  async rejectRequest(handymanId: string, dto: RejectRequestDto): Promise<void> {
    const workOrder = await this.prisma.workOrder.findUnique({
      where: { id: dto.workOrderId },
      include: {
        household: true,
        handyman: { select: { displayName: true } },
      },
    });

    if (!workOrder) {
      throw new NotFoundException('Work order not found');
    }

    if (workOrder.handymanId !== handymanId) {
      throw new ForbiddenException('This work order is not assigned to you');
    }

    if (workOrder.status !== WorkOrderStatus.ASSIGNED) {
      throw new BadRequestException('Can only reject work orders in ASSIGNED status');
    }

    // Update work order - remove handyman, set to OPEN for reassignment
    await this.prisma.workOrder.update({
      where: { id: dto.workOrderId },
      data: {
        handymanId: null,
        status: WorkOrderStatus.OPEN,
      },
    });

    // Create work order note with rejection reason
    await this.prisma.workOrderNote.create({
      data: {
        workOrderId: dto.workOrderId,
        authorUserId: handymanId,
        body: `[REJECTED] ${workOrder.handyman?.displayName || 'Handyman'} declined this task. Reason: ${dto.reason}`,
      },
    });

    // Notify manager about rejection
    if (workOrder.household.managerId) {
      await this.prisma.inAppNotification.create({
        data: {
          userId: workOrder.household.managerId,
          householdId: workOrder.householdId,
          title: 'Handyman Declined Task',
          body: `${workOrder.handyman?.displayName || 'Handyman'} declined "${workOrder.title}". Reason: ${dto.reason}`,
          link: `/internal/work-orders/${dto.workOrderId}`,
          workOrderId: dto.workOrderId,
        },
      });
    }
  }

  /**
   * Notify manager about unassigned concierge request
   */
  private async notifyManagerOfUnassignedRequest(
    managerId: string,
    householdId: string,
    workOrderId: string,
    title: string,
  ): Promise<void> {
    await this.prisma.inAppNotification.create({
      data: {
        userId: managerId,
        householdId,
        title: 'Concierge Request Needs Assignment',
        body: `New concierge request "${title}" has no assigned handyman.`,
        link: `/internal/work-orders/${workOrderId}`,
        workOrderId,
      },
    });
  }
}
