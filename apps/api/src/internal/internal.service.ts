import { Injectable, NotFoundException } from '@nestjs/common';
import { ConversationStatus, WorkOrderStatus } from '@prisma/client';

import { DbService } from '../db';

@Injectable()
export class InternalService {
  constructor(private db: DbService) {}

  /**
   * Get dashboard stats for internal console
   */
  async getDashboardStats() {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const [
      activeHouseholds,
      openConversations,
      unassignedConversations,
      openWorkOrders,
      todaysAppointments,
    ] = await Promise.all([
      // Active households (with active subscription)
      this.db.household.count({
        where: {
          subscriptionStatus: 'ACTIVE',
        },
      }),
      // Open conversations
      this.db.supportConversation.count({
        where: {
          status: { in: ['OPEN', 'PENDING'] },
        },
      }),
      // Unassigned conversations
      this.db.supportConversation.count({
        where: {
          status: { in: ['OPEN', 'PENDING'] },
          assignedToId: null,
        },
      }),
      // Open work orders
      this.db.workOrder.count({
        where: {
          status: { in: ['DRAFT', 'REQUESTED', 'SCHEDULED', 'IN_PROGRESS'] },
        },
      }),
      // Appointments scheduled for today
      this.db.workOrder.count({
        where: {
          scheduledStart: {
            gte: today,
            lt: tomorrow,
          },
        },
      }),
    ]);

    return {
      activeHouseholds,
      openConversations,
      unassignedConversations,
      openWorkOrders,
      todaysAppointments,
    };
  }

  /**
   * Get all households with details for internal view
   */
  async getHouseholds() {
    return this.db.household.findMany({
      select: {
        id: true,
        name: true,
        description: true,
        subscriptionPlan: true,
        subscriptionStatus: true,
        createdAt: true,
        updatedAt: true,
        owner: {
          select: {
            id: true,
            email: true,
            firstName: true,
            lastName: true,
            phone: true,
          },
        },
        homeProfile: {
          select: {
            id: true,
            propertyType: true,
            addressLine1: true,
            addressLine2: true,
            city: true,
            state: true,
            postalCode: true,
          },
        },
        _count: {
          select: {
            members: true,
            serviceRequests: true,
            tasks: true,
            billAccounts: true,
            conversations: true,
            workOrders: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  /**
   * Get household detail for internal view
   */
  async getHouseholdById(id: string) {
    const household = await this.db.household.findUnique({
      where: { id },
      include: {
        owner: {
          select: {
            id: true,
            email: true,
            firstName: true,
            lastName: true,
            phone: true,
          },
        },
        members: {
          include: {
            user: {
              select: {
                id: true,
                email: true,
                firstName: true,
                lastName: true,
                phone: true,
              },
            },
          },
        },
        homeProfile: true,
        billAccounts: {
          orderBy: { createdAt: 'desc' },
        },
        tasks: {
          orderBy: { createdAt: 'desc' },
          take: 20,
          include: {
            category: true,
          },
        },
        serviceRequests: {
          orderBy: { createdAt: 'desc' },
          take: 20,
          include: {
            category: true,
          },
        },
        workOrders: {
          orderBy: { createdAt: 'desc' },
          take: 20,
          include: {
            vendor: true,
          },
        },
        conversations: {
          orderBy: { updatedAt: 'desc' },
          take: 20,
          include: {
            assignedTo: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
              },
            },
          },
        },
      },
    });

    if (!household) {
      throw new NotFoundException('Household not found');
    }

    return household;
  }

  /**
   * Get support conversations queue
   */
  async getConversations(filters: {
    status?: 'all' | 'unassigned' | 'assigned' | 'closed';
    assignedToId?: string;
  }) {
    const where: any = {};

    if (filters.status === 'unassigned') {
      where.status = { in: ['OPEN', 'PENDING'] };
      where.assignedToId = null;
    } else if (filters.status === 'assigned') {
      where.status = { in: ['OPEN', 'PENDING'] };
      where.assignedToId = filters.assignedToId || { not: null };
    } else if (filters.status === 'closed') {
      where.status = 'CLOSED';
    } else if (filters.status !== 'all') {
      // Default: all open
      where.status = { in: ['OPEN', 'PENDING'] };
    }

    return this.db.supportConversation.findMany({
      where,
      include: {
        household: {
          select: {
            id: true,
            name: true,
            owner: {
              select: {
                firstName: true,
                lastName: true,
                email: true,
              },
            },
          },
        },
        assignedTo: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
          },
        },
        _count: {
          select: {
            messages: true,
          },
        },
      },
      orderBy: [{ updatedAt: 'desc' }],
    });
  }

  /**
   * Assign conversation to manager
   */
  async assignConversation(
    conversationId: string,
    assignedToId: string | null,
  ) {
    return this.db.supportConversation.update({
      where: { id: conversationId },
      data: { assignedToId },
    });
  }

  /**
   * Update conversation status
   */
  async updateConversationStatus(
    conversationId: string,
    status: ConversationStatus,
  ) {
    return this.db.supportConversation.update({
      where: { id: conversationId },
      data: {
        status,
        closedAt: status === 'CLOSED' ? new Date() : null,
      },
    });
  }

  /**
   * Get work orders queue
   */
  async getWorkOrders(filters: {
    status?: WorkOrderStatus | 'all';
    dateFrom?: Date;
    dateTo?: Date;
  }) {
    const where: any = {};

    if (filters.status && filters.status !== 'all') {
      where.status = filters.status;
    }

    if (filters.dateFrom || filters.dateTo) {
      where.scheduledStart = {};
      if (filters.dateFrom) {
        where.scheduledStart.gte = filters.dateFrom;
      }
      if (filters.dateTo) {
        where.scheduledStart.lte = filters.dateTo;
      }
    }

    return this.db.workOrder.findMany({
      where,
      include: {
        household: {
          select: {
            id: true,
            name: true,
            homeProfile: {
              select: {
                addressLine1: true,
                city: true,
                state: true,
              },
            },
          },
        },
        vendor: {
          select: {
            id: true,
            name: true,
            phone: true,
          },
        },
        maintenanceTask: {
          select: {
            id: true,
            name: true,
          },
        },
        createdBy: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
          },
        },
        _count: {
          select: {
            notes: true,
          },
        },
      },
      orderBy: [{ scheduledStart: 'asc' }, { createdAt: 'desc' }],
    });
  }

  /**
   * Get upcoming appointments for today/week view
   */
  async getUpcomingAppointments(days: number = 7) {
    const startDate = new Date();
    startDate.setHours(0, 0, 0, 0);
    const endDate = new Date(startDate);
    endDate.setDate(endDate.getDate() + days);

    return this.db.workOrder.findMany({
      where: {
        scheduledStart: {
          gte: startDate,
          lt: endDate,
        },
        status: { in: ['SCHEDULED', 'IN_PROGRESS'] },
      },
      include: {
        household: {
          select: {
            id: true,
            name: true,
            homeProfile: {
              select: {
                addressLine1: true,
                city: true,
                state: true,
              },
            },
          },
        },
        vendor: {
          select: {
            id: true,
            name: true,
            phone: true,
          },
        },
      },
      orderBy: { scheduledStart: 'asc' },
    });
  }
}
