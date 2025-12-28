import { Injectable, NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ActivityService } from '../activity/activity.service';
import {
  ApprovalType,
  ApprovalStatus,
  ApprovalPriority,
  ActorType,
  ActivityAction,
  ActivityCategory,
} from '@prisma/client';

export interface CreateApprovalDto {
  householdId: string;
  type: ApprovalType;
  priority?: ApprovalPriority;
  title: string;
  description?: string;
  amount?: number;
  vendorName?: string;
  workOrderId?: string;
  serviceRequestId?: string;
  projectId?: string;
  expiresAt?: Date;
}

export interface UpdateApprovalDto {
  status: ApprovalStatus;
  decisionNote?: string;
}

export interface AddCommentDto {
  content: string;
}

@Injectable()
export class ApprovalService {
  constructor(
    private prisma: PrismaService,
    private activityService: ActivityService,
  ) {}

  /**
   * Create a new approval request (manager only)
   */
  async create(requesterId: string, requesterName: string, data: CreateApprovalDto) {
    // Verify manager has access to this household
    const household = await this.prisma.household.findFirst({
      where: {
        id: data.householdId,
        managerId: requesterId,
      },
    });

    if (!household) {
      throw new ForbiddenException('You do not manage this household');
    }

    const approval = await this.prisma.approvalRequest.create({
      data: {
        householdId: data.householdId,
        requesterId,
        type: data.type,
        priority: data.priority || ApprovalPriority.MEDIUM,
        title: data.title,
        description: data.description,
        amount: data.amount,
        vendorName: data.vendorName,
        workOrderId: data.workOrderId,
        serviceRequestId: data.serviceRequestId,
        projectId: data.projectId,
        expiresAt: data.expiresAt,
        status: ApprovalStatus.PENDING,
      },
      include: {
        requester: {
          select: { id: true, displayName: true, firstName: true, lastName: true },
        },
      },
    });

    // Log activity
    await this.activityService.log({
      householdId: data.householdId,
      actorId: requesterId,
      actorType: ActorType.HOME_MANAGER,
      actorName: requesterName,
      action: ActivityAction.OTHER,
      category: ActivityCategory.MAINTENANCE,
      title: `Approval requested: ${data.title}`,
      description: data.description || `${data.type} approval requested`,
      amount: data.amount,
      visibleToHomeowner: true,
    });

    return approval;
  }

  /**
   * Get approval requests for a household (homeowner view)
   */
  async getForHousehold(householdId: string, status?: ApprovalStatus) {
    const where: Record<string, unknown> = { householdId };
    if (status) {
      where.status = status;
    }

    return this.prisma.approvalRequest.findMany({
      where,
      orderBy: [
        { status: 'asc' }, // PENDING first
        { priority: 'desc' }, // Then by priority
        { createdAt: 'desc' },
      ],
      include: {
        requester: {
          select: { id: true, displayName: true, firstName: true, lastName: true },
        },
        decider: {
          select: { id: true, displayName: true, firstName: true, lastName: true },
        },
        comments: {
          orderBy: { createdAt: 'asc' },
          include: {
            author: {
              select: { id: true, displayName: true, firstName: true, lastName: true },
            },
          },
        },
      },
    });
  }

  /**
   * Get pending approval count for a household
   */
  async getPendingCount(householdId: string): Promise<number> {
    return this.prisma.approvalRequest.count({
      where: {
        householdId,
        status: ApprovalStatus.PENDING,
      },
    });
  }

  /**
   * Get approval requests created by a manager
   */
  async getByManager(managerId: string, status?: ApprovalStatus) {
    const where: Record<string, unknown> = { requesterId: managerId };
    if (status) {
      where.status = status;
    }

    return this.prisma.approvalRequest.findMany({
      where,
      orderBy: [
        { status: 'asc' },
        { createdAt: 'desc' },
      ],
      include: {
        household: {
          select: { id: true, name: true },
        },
        decider: {
          select: { id: true, displayName: true, firstName: true, lastName: true },
        },
        comments: {
          orderBy: { createdAt: 'asc' },
        },
      },
    });
  }

  /**
   * Get a single approval request by ID
   */
  async getById(approvalId: string) {
    const approval = await this.prisma.approvalRequest.findUnique({
      where: { id: approvalId },
      include: {
        household: {
          select: { id: true, name: true, ownerId: true, managerId: true },
        },
        requester: {
          select: { id: true, displayName: true, firstName: true, lastName: true, email: true },
        },
        decider: {
          select: { id: true, displayName: true, firstName: true, lastName: true },
        },
        comments: {
          orderBy: { createdAt: 'asc' },
          include: {
            author: {
              select: { id: true, displayName: true, firstName: true, lastName: true },
            },
          },
        },
      },
    });

    if (!approval) {
      throw new NotFoundException('Approval request not found');
    }

    return approval;
  }

  /**
   * Update approval status (homeowner decides)
   */
  async decide(
    approvalId: string,
    deciderId: string,
    deciderName: string,
    data: UpdateApprovalDto,
  ) {
    const approval = await this.getById(approvalId);

    // Verify the decider is the household owner
    if (approval.household.ownerId !== deciderId) {
      throw new ForbiddenException('Only the household owner can approve or reject');
    }

    // Verify the approval is still pending
    if (approval.status !== ApprovalStatus.PENDING) {
      throw new BadRequestException(`Approval is already ${approval.status.toLowerCase()}`);
    }

    // Validate status transition
    if (data.status !== ApprovalStatus.APPROVED && data.status !== ApprovalStatus.REJECTED) {
      throw new BadRequestException('Can only approve or reject');
    }

    const updated = await this.prisma.approvalRequest.update({
      where: { id: approvalId },
      data: {
        status: data.status,
        deciderId,
        decidedAt: new Date(),
        decisionNote: data.decisionNote,
      },
      include: {
        requester: {
          select: { id: true, displayName: true, firstName: true, lastName: true },
        },
        decider: {
          select: { id: true, displayName: true, firstName: true, lastName: true },
        },
        comments: {
          orderBy: { createdAt: 'asc' },
        },
      },
    });

    // Log activity
    const actionWord = data.status === ApprovalStatus.APPROVED ? 'Approved' : 'Rejected';
    await this.activityService.log({
      householdId: approval.householdId,
      actorId: deciderId,
      actorType: ActorType.HOMEOWNER,
      actorName: deciderName,
      action: ActivityAction.OTHER,
      category: ActivityCategory.MAINTENANCE,
      title: `${actionWord}: ${approval.title}`,
      description: data.decisionNote || `${approval.type} request ${actionWord.toLowerCase()}`,
      amount: approval.amount ? Number(approval.amount) : undefined,
      visibleToHomeowner: true,
    });

    return updated;
  }

  /**
   * Cancel an approval request (manager only)
   */
  async cancel(approvalId: string, managerId: string, managerName: string) {
    const approval = await this.getById(approvalId);

    // Verify the manager owns this request
    if (approval.requesterId !== managerId) {
      throw new ForbiddenException('You can only cancel your own approval requests');
    }

    // Verify the approval is still pending
    if (approval.status !== ApprovalStatus.PENDING) {
      throw new BadRequestException(`Cannot cancel - approval is already ${approval.status.toLowerCase()}`);
    }

    const updated = await this.prisma.approvalRequest.update({
      where: { id: approvalId },
      data: {
        status: ApprovalStatus.CANCELLED,
      },
    });

    // Log activity
    await this.activityService.log({
      householdId: approval.householdId,
      actorId: managerId,
      actorType: ActorType.HOME_MANAGER,
      actorName: managerName,
      action: ActivityAction.OTHER,
      category: ActivityCategory.MAINTENANCE,
      title: `Cancelled: ${approval.title}`,
      description: 'Approval request cancelled by manager',
      visibleToHomeowner: true,
    });

    return updated;
  }

  /**
   * Add a comment to an approval request
   */
  async addComment(
    approvalId: string,
    authorId: string,
    authorName: string,
    data: AddCommentDto,
  ) {
    const approval = await this.getById(approvalId);

    // Verify the author has access (either owner or manager)
    if (approval.household.ownerId !== authorId && approval.requesterId !== authorId) {
      throw new ForbiddenException('You do not have access to this approval request');
    }

    const comment = await this.prisma.approvalComment.create({
      data: {
        approvalId,
        authorId,
        content: data.content,
      },
      include: {
        author: {
          select: { id: true, displayName: true, firstName: true, lastName: true },
        },
      },
    });

    // Log activity
    const actorType = approval.household.ownerId === authorId
      ? ActorType.HOMEOWNER
      : ActorType.HOME_MANAGER;

    await this.activityService.log({
      householdId: approval.householdId,
      actorId: authorId,
      actorType,
      actorName: authorName,
      action: ActivityAction.OTHER,
      category: ActivityCategory.MAINTENANCE,
      title: `Comment on: ${approval.title}`,
      description: data.content.substring(0, 100) + (data.content.length > 100 ? '...' : ''),
      visibleToHomeowner: true,
    });

    return comment;
  }

  /**
   * Get comments for an approval request
   */
  async getComments(approvalId: string) {
    return this.prisma.approvalComment.findMany({
      where: { approvalId },
      orderBy: { createdAt: 'asc' },
      include: {
        author: {
          select: { id: true, displayName: true, firstName: true, lastName: true },
        },
      },
    });
  }
}
