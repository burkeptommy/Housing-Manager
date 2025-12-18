import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import {
  TriageStatus,
  RequestCategory,
  WorkOrderStatus,
  WorkOrderBillingType,
  TransactionStatus,
  TransactionPayoutMethod,
  ProjectIdeaStatus,
  ProjectCategory,
} from '@prisma/client';
import { ExecutionResultDto } from '../dto/triage.dto';

export interface ExecutionContext {
  requestId: string;
  suggestionId: string;
  userId: string;
  householdId: string;
  actionType: string;
  actionData: Record<string, unknown>;
  overrideData?: Record<string, unknown>;
}

@Injectable()
export class ExecutionPipelineService {
  private readonly logger = new Logger(ExecutionPipelineService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Execute an approved triage action
   */
  async executeAction(ctx: ExecutionContext): Promise<ExecutionResultDto> {
    this.logger.log(`Executing action ${ctx.actionType} for request ${ctx.requestId}`);

    // Merge action data with overrides
    const data = { ...ctx.actionData, ...ctx.overrideData };

    try {
      let result: ExecutionResultDto;

      switch (ctx.actionType) {
        case 'PAY_BILL':
          result = await this.executeBillPipeline(ctx, data);
          break;

        case 'CREATE_WORK_ORDER':
          result = await this.executeFixPipeline(ctx, data);
          break;

        case 'CREATE_PROJECT':
          result = await this.executeProjectPipeline(ctx, data);
          break;

        case 'CREATE_EVENT':
          result = await this.executeCalendarPipeline(ctx, data);
          break;

        case 'CREATE_TRIP':
          result = await this.executeTripPipeline(ctx, data);
          break;

        case 'RESPOND_INQUIRY':
          result = await this.executeInquiryPipeline(ctx, data);
          break;

        default:
          throw new BadRequestException(`Unknown action type: ${ctx.actionType}`);
      }

      // Mark suggestion as approved and request as resolved
      await this.markResolved(ctx, result);

      return result;
    } catch (error) {
      this.logger.error(`Failed to execute action ${ctx.actionType}:`, error);
      return {
        success: false,
        actionType: ctx.actionType,
        entityType: null,
        entityId: null,
        message: 'Action execution failed',
        error: error instanceof Error ? error.message : 'Unknown error',
      };
    }
  }

  /**
   * Reject a triage request
   */
  async rejectRequest(requestId: string, userId: string, reason: string): Promise<void> {
    await this.prisma.inboundRequest.update({
      where: { id: requestId },
      data: {
        status: TriageStatus.REJECTED,
        resolvedAction: 'REJECTED',
        resolvedByUserId: userId,
        resolvedAt: new Date(),
        aiReasoning: `Rejected: ${reason}`,
      },
    });
  }

  // =========================================================================
  // BILL PIPELINE
  // =========================================================================

  private async executeBillPipeline(
    ctx: ExecutionContext,
    data: Record<string, unknown>,
  ): Promise<ExecutionResultDto> {
    const vendor = data.vendor as string || 'Unknown Vendor';
    const amount = data.amount as number || 0;
    const dueDate = data.date as string || data.dueDate as string;
    const description = data.description as string || `Bill from ${vendor}`;

    // Find vendor record if exists
    let vendorRecord = await this.prisma.vendor.findFirst({
      where: {
        OR: [
          { displayName: { contains: vendor, mode: 'insensitive' } },
          { email: { contains: vendor, mode: 'insensitive' } },
        ],
      },
    });

    // Get a manager for this household
    const household = await this.prisma.household.findUnique({
      where: { id: ctx.householdId },
      select: { managerId: true },
    });

    // Create transaction for the bill
    const transaction = await this.prisma.transaction.create({
      data: {
        householdId: ctx.householdId,
        vendorId: vendorRecord?.id,
        managerId: household?.managerId || ctx.userId,
        description,
        amount,
        status: TransactionStatus.PENDING,
        payoutMethod: TransactionPayoutMethod.BANK_TRANSFER,
        inboundRequestId: ctx.requestId,
        dueDate: dueDate ? new Date(dueDate) : null,
        notes: `Auto-created from inbound request`,
      },
    });

    return {
      success: true,
      actionType: 'PAY_BILL',
      entityType: 'Transaction',
      entityId: transaction.id,
      message: `Created bill transaction for ${vendor}: $${amount}`,
    };
  }

  // =========================================================================
  // FIX PIPELINE
  // =========================================================================

  private async executeFixPipeline(
    ctx: ExecutionContext,
    data: Record<string, unknown>,
  ): Promise<ExecutionResultDto> {
    const title = data.title as string || data.description as string || 'Repair Request';
    const description = data.description as string || '';
    const location = data.location as string;

    // Determine billing type
    let billingType: WorkOrderBillingType = WorkOrderBillingType.BILLABLE_TO_CLIENT;
    const lowerTitle = title.toLowerCase();
    const lowerDesc = description.toLowerCase();

    // Check for minor maintenance items
    const minorKeywords = ['filter', 'light bulb', 'battery', 'loose', 'squeaky'];
    if (minorKeywords.some((k) => lowerTitle.includes(k) || lowerDesc.includes(k))) {
      billingType = WorkOrderBillingType.INCLUSIVE;
    }

    // Get household with handyman
    const household = await this.prisma.household.findUnique({
      where: { id: ctx.householdId },
      select: {
        assignedHandymanId: true,
        homeProfile: { select: { city: true } },
      },
    });

    // Create work order
    const workOrder = await this.prisma.workOrder.create({
      data: {
        householdId: ctx.householdId,
        createdByUserId: ctx.userId,
        handymanId: household?.assignedHandymanId,
        title,
        description: `${description}${location ? `\n\nLocation: ${location}` : ''}`,
        status: household?.assignedHandymanId ? WorkOrderStatus.ASSIGNED : WorkOrderStatus.OPEN,
        billingType,
        isConciergeRequest: true,
        serviceArea: household?.homeProfile?.city || null,
        inboundRequestId: ctx.requestId,
      },
    });

    return {
      success: true,
      actionType: 'CREATE_WORK_ORDER',
      entityType: 'WorkOrder',
      entityId: workOrder.id,
      message: `Created work order: ${title}`,
    };
  }

  // =========================================================================
  // PROJECT PIPELINE
  // =========================================================================

  private async executeProjectPipeline(
    ctx: ExecutionContext,
    data: Record<string, unknown>,
  ): Promise<ExecutionResultDto> {
    const title = data.title as string || 'New Project Idea';
    const description = data.description as string || '';
    const categoryStr = data.category as string || data.projectType as string;

    // Map to project category
    let category: ProjectCategory = ProjectCategory.OTHER;
    if (categoryStr) {
      const catUpper = categoryStr.toUpperCase().replace(/\s+/g, '_');
      if (Object.values(ProjectCategory).includes(catUpper as ProjectCategory)) {
        category = catUpper as ProjectCategory;
      }
    }

    // Create project idea
    const projectIdea = await this.prisma.projectIdea.create({
      data: {
        householdId: ctx.householdId,
        createdByUserId: ctx.userId,
        title,
        description,
        category,
        status: ProjectIdeaStatus.DREAMING,
        vibeNotes: data.style as string,
        inboundRequestId: ctx.requestId,
      },
    });

    return {
      success: true,
      actionType: 'CREATE_PROJECT',
      entityType: 'ProjectIdea',
      entityId: projectIdea.id,
      message: `Created project idea: ${title}`,
    };
  }

  // =========================================================================
  // CALENDAR PIPELINE
  // =========================================================================

  private async executeCalendarPipeline(
    ctx: ExecutionContext,
    data: Record<string, unknown>,
  ): Promise<ExecutionResultDto> {
    const title = data.title as string || data.eventTitle as string || 'New Event';
    const description = data.description as string || '';
    const dateStr = data.date as string;
    const location = data.location as string;
    const isRecurring = data.recurring as boolean || false;

    // Parse date
    let startDate = dateStr ? new Date(dateStr) : new Date();
    if (isNaN(startDate.getTime())) {
      startDate = new Date();
    }

    // Create family event
    const event = await this.prisma.familyEvent.create({
      data: {
        householdId: ctx.householdId,
        createdByUserId: ctx.userId,
        title,
        description,
        startDate,
        endDate: new Date(startDate.getTime() + 60 * 60 * 1000), // 1 hour default
        location,
        isRecurring,
        inboundRequestId: ctx.requestId,
      },
    });

    return {
      success: true,
      actionType: 'CREATE_EVENT',
      entityType: 'FamilyEvent',
      entityId: event.id,
      message: `Created calendar event: ${title}`,
    };
  }

  // =========================================================================
  // TRIP PIPELINE
  // =========================================================================

  private async executeTripPipeline(
    ctx: ExecutionContext,
    data: Record<string, unknown>,
  ): Promise<ExecutionResultDto> {
    const title = data.title as string || `Trip to ${data.destination || 'TBD'}`;
    const destination = data.destination as string || '';
    const startDateStr = data.startDate as string || data.date as string;
    const endDateStr = data.endDate as string;
    const travelers = data.travelers as number || 1;

    // Parse dates
    let startDate = startDateStr ? new Date(startDateStr) : null;
    let endDate = endDateStr ? new Date(endDateStr) : null;

    if (startDate && isNaN(startDate.getTime())) {
      startDate = null;
    }
    if (endDate && isNaN(endDate.getTime())) {
      endDate = null;
    }

    // Create trip
    const trip = await this.prisma.trip.create({
      data: {
        householdId: ctx.householdId,
        createdByUserId: ctx.userId,
        title,
        destination,
        startDate,
        endDate,
        travelers,
        status: 'PLANNING',
        notes: data.notes as string,
        inboundRequestId: ctx.requestId,
      },
    });

    return {
      success: true,
      actionType: 'CREATE_TRIP',
      entityType: 'Trip',
      entityId: trip.id,
      message: `Created trip: ${title}`,
    };
  }

  // =========================================================================
  // INQUIRY PIPELINE
  // =========================================================================

  private async executeInquiryPipeline(
    ctx: ExecutionContext,
    data: Record<string, unknown>,
  ): Promise<ExecutionResultDto> {
    return {
      success: true,
      actionType: 'RESPOND_INQUIRY',
      entityType: null,
      entityId: null,
      message: 'Inquiry acknowledged - follow-up may be needed',
    };
  }

  // =========================================================================
  // HELPERS
  // =========================================================================

  private async markResolved(ctx: ExecutionContext, result: ExecutionResultDto): Promise<void> {
    // Mark suggestion as approved
    await this.prisma.triageSuggestion.update({
      where: { id: ctx.suggestionId },
      data: { isApproved: true },
    });

    // Mark request as resolved
    await this.prisma.inboundRequest.update({
      where: { id: ctx.requestId },
      data: {
        status: TriageStatus.RESOLVED,
        resolvedAction: result.actionType,
        resolvedEntityType: result.entityType,
        resolvedEntityId: result.entityId,
        resolvedByUserId: ctx.userId,
        resolvedAt: new Date(),
      },
    });
  }
}
