import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { WorkOrderStatus, MaintenanceTaskStatus, ReminderType, ReminderChannel } from '@prisma/client';
import {
  CreateWorkOrderDto,
  UpdateWorkOrderDto,
  CreateWorkOrderNoteDto,
  WorkOrderQueryDto,
  InternalWorkOrderQueryDto,
} from './dto';

@Injectable()
export class WorkOrdersService {
  constructor(private prisma: PrismaService) {}

  // Include relations for work order responses
  private readonly workOrderInclude = {
    household: {
      select: {
        id: true,
        name: true,
      },
    },
    maintenanceTask: {
      select: {
        id: true,
        title: true,
        category: true,
        status: true,
      },
    },
    vendor: {
      select: {
        id: true,
        displayName: true,
        phone: true,
        email: true,
        category: true,
      },
    },
    createdBy: {
      select: {
        id: true,
        firstName: true,
        lastName: true,
        email: true,
      },
    },
    notes: {
      include: {
        author: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            email: true,
          },
        },
      },
      orderBy: {
        createdAt: 'desc' as const,
      },
    },
  };

  /**
   * Create a new work order for a household
   */
  async createWorkOrder(
    householdId: string,
    userId: string,
    dto: CreateWorkOrderDto,
  ) {
    // If linking to a maintenance task, get task details
    let maintenanceTask = null;
    if (dto.maintenanceTaskId) {
      maintenanceTask = await this.prisma.maintenanceTask.findFirst({
        where: {
          id: dto.maintenanceTaskId,
          householdId,
        },
      });

      if (!maintenanceTask) {
        throw new NotFoundException('Maintenance task not found');
      }
    }

    // Create the work order
    const workOrder = await this.prisma.workOrder.create({
      data: {
        householdId,
        createdByUserId: userId,
        maintenanceTaskId: dto.maintenanceTaskId,
        vendorId: dto.vendorId,
        title: dto.title || maintenanceTask?.title || 'Service Request',
        description: dto.description || maintenanceTask?.description,
        status: WorkOrderStatus.REQUESTED,
        preferredDate: dto.preferredDate ? new Date(dto.preferredDate) : null,
        preferredTimeWindowStart: dto.preferredTimeWindowStart,
        preferredTimeWindowEnd: dto.preferredTimeWindowEnd,
      },
      include: this.workOrderInclude,
    });

    // If linked to maintenance task, update task status to SCHEDULED
    if (dto.maintenanceTaskId && maintenanceTask) {
      await this.prisma.maintenanceTask.update({
        where: { id: dto.maintenanceTaskId },
        data: { status: MaintenanceTaskStatus.SCHEDULED },
      });
    }

    // Create notification for household members
    await this.createWorkOrderNotification(
      workOrder.householdId,
      workOrder.id,
      'New Work Order Created',
      `Work order "${workOrder.title}" has been submitted.`,
    );

    return workOrder;
  }

  /**
   * List work orders for a household
   */
  async listWorkOrders(householdId: string, query: WorkOrderQueryDto) {
    const where: any = { householdId };

    if (query.status) {
      where.status = query.status;
    } else if (!query.includeCompleted) {
      where.status = {
        notIn: [WorkOrderStatus.COMPLETED, WorkOrderStatus.CANCELLED],
      };
    }

    return this.prisma.workOrder.findMany({
      where,
      include: this.workOrderInclude,
      orderBy: [
        { scheduledStart: 'asc' },
        { preferredDate: 'asc' },
        { createdAt: 'desc' },
      ],
    });
  }

  /**
   * Get a single work order
   */
  async getWorkOrder(workOrderId: string, householdId?: string) {
    const where: any = { id: workOrderId };
    if (householdId) {
      where.householdId = householdId;
    }

    const workOrder = await this.prisma.workOrder.findFirst({
      where,
      include: this.workOrderInclude,
    });

    if (!workOrder) {
      throw new NotFoundException('Work order not found');
    }

    return workOrder;
  }

  /**
   * List work orders for internal queue (home managers)
   */
  async listInternalWorkOrders(query: InternalWorkOrderQueryDto) {
    const where: any = {};

    if (query.status) {
      where.status = query.status;
    } else {
      // Default to non-completed work orders
      where.status = {
        notIn: [WorkOrderStatus.COMPLETED, WorkOrderStatus.CANCELLED],
      };
    }

    if (query.unassigned) {
      where.vendorId = null;
    }

    if (query.upcoming) {
      where.status = WorkOrderStatus.SCHEDULED;
      where.scheduledStart = {
        gte: new Date(),
      };
    }

    return this.prisma.workOrder.findMany({
      where,
      include: this.workOrderInclude,
      orderBy: [
        { status: 'asc' },
        { scheduledStart: 'asc' },
        { preferredDate: 'asc' },
        { createdAt: 'desc' },
      ],
    });
  }

  /**
   * Update a work order (internal use by home managers)
   */
  async updateWorkOrder(workOrderId: string, dto: UpdateWorkOrderDto) {
    const workOrder = await this.prisma.workOrder.findUnique({
      where: { id: workOrderId },
      include: { maintenanceTask: true },
    });

    if (!workOrder) {
      throw new NotFoundException('Work order not found');
    }

    const updateData: any = {};

    if (dto.title !== undefined) updateData.title = dto.title;
    if (dto.description !== undefined) updateData.description = dto.description;
    if (dto.vendorId !== undefined) updateData.vendorId = dto.vendorId;
    if (dto.status !== undefined) updateData.status = dto.status;
    if (dto.estimatedCost !== undefined) updateData.estimatedCost = dto.estimatedCost;
    if (dto.actualCost !== undefined) updateData.actualCost = dto.actualCost;

    if (dto.scheduledStart !== undefined) {
      updateData.scheduledStart = dto.scheduledStart ? new Date(dto.scheduledStart) : null;
    }
    if (dto.scheduledEnd !== undefined) {
      updateData.scheduledEnd = dto.scheduledEnd ? new Date(dto.scheduledEnd) : null;
    }

    // Handle status changes
    if (dto.status === WorkOrderStatus.COMPLETED) {
      updateData.completedAt = new Date();

      // If linked to maintenance task, mark it as completed
      if (workOrder.maintenanceTaskId) {
        await this.prisma.maintenanceTask.update({
          where: { id: workOrder.maintenanceTaskId },
          data: {
            status: MaintenanceTaskStatus.COMPLETED,
            completedAt: new Date(),
            actualCost: dto.actualCost ?? workOrder.actualCost,
          },
        });
      }
    }

    // If scheduling, create reminders
    if (dto.scheduledStart && dto.status === WorkOrderStatus.SCHEDULED) {
      await this.createWorkOrderReminders(workOrderId, workOrder.householdId, new Date(dto.scheduledStart));
    }

    const updated = await this.prisma.workOrder.update({
      where: { id: workOrderId },
      data: updateData,
      include: this.workOrderInclude,
    });

    // Create notification for status changes
    if (dto.status && dto.status !== workOrder.status) {
      await this.createWorkOrderNotification(
        updated.householdId,
        updated.id,
        'Work Order Updated',
        `Work order "${updated.title}" status changed to ${dto.status}.`,
      );
    }

    return updated;
  }

  /**
   * Add a note to a work order
   */
  async addNote(workOrderId: string, authorUserId: string, dto: CreateWorkOrderNoteDto) {
    const workOrder = await this.prisma.workOrder.findUnique({
      where: { id: workOrderId },
    });

    if (!workOrder) {
      throw new NotFoundException('Work order not found');
    }

    return this.prisma.workOrderNote.create({
      data: {
        workOrderId,
        authorUserId,
        body: dto.body,
      },
      include: {
        author: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            email: true,
          },
        },
      },
    });
  }

  /**
   * Create reminders for scheduled work order
   * - 1 day before
   * - 1 hour before
   */
  private async createWorkOrderReminders(
    workOrderId: string,
    householdId: string,
    scheduledStart: Date,
  ) {
    const reminders = [];

    // 1 day before
    const oneDayBefore = new Date(scheduledStart);
    oneDayBefore.setDate(oneDayBefore.getDate() - 1);

    if (oneDayBefore > new Date()) {
      reminders.push({
        householdId,
        type: ReminderType.WORK_ORDER,
        workOrderId,
        scheduledAt: oneDayBefore,
        channel: ReminderChannel.IN_APP,
        payloadJson: {
          message: 'Vendor visit scheduled for tomorrow',
          workOrderId,
        },
      });
    }

    // 1 hour before
    const oneHourBefore = new Date(scheduledStart);
    oneHourBefore.setHours(oneHourBefore.getHours() - 1);

    if (oneHourBefore > new Date()) {
      reminders.push({
        householdId,
        type: ReminderType.WORK_ORDER,
        workOrderId,
        scheduledAt: oneHourBefore,
        channel: ReminderChannel.IN_APP,
        payloadJson: {
          message: 'Vendor visit scheduled in 1 hour',
          workOrderId,
        },
      });
    }

    if (reminders.length > 0) {
      // Remove existing reminders for this work order
      await this.prisma.reminder.deleteMany({
        where: {
          workOrderId,
          status: 'PENDING',
        },
      });

      // Create new reminders
      await this.prisma.reminder.createMany({
        data: reminders,
      });
    }
  }

  /**
   * Create in-app notification for work order events
   */
  private async createWorkOrderNotification(
    householdId: string,
    workOrderId: string,
    title: string,
    body: string,
  ) {
    // Get household members to notify
    const members = await this.prisma.householdMember.findMany({
      where: {
        householdId,
        status: 'ACTIVE',
      },
      select: { userId: true },
    });

    if (members.length > 0) {
      await this.prisma.inAppNotification.createMany({
        data: members.map((m) => ({
          userId: m.userId,
          householdId,
          title,
          body,
          link: `/app/work-orders/${workOrderId}`,
          workOrderId,
        })),
      });
    }
  }
}
