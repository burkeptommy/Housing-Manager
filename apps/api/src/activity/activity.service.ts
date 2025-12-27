import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ActorType, ActivityAction, ActivityCategory } from '@prisma/client';

export interface LogActivityData {
  householdId: string;
  actorId: string;
  actorType: ActorType;
  actorName: string;
  action: ActivityAction;
  category: ActivityCategory;
  title: string;
  description?: string;
  billId?: string;
  vendorId?: string;
  assetId?: string;
  zoneId?: string;
  taskId?: string;
  amount?: number;
  metadata?: Record<string, unknown>;
  visibleToHomeowner?: boolean;
  visibleToHandyman?: boolean;
}

export interface GetActivityOptions {
  limit?: number;
  category?: ActivityCategory;
  startDate?: Date;
  endDate?: Date;
  visibleToHomeowner?: boolean;
}

@Injectable()
export class ActivityService {
  constructor(private prisma: PrismaService) {}

  /**
   * Log an activity for a household
   */
  async log(data: LogActivityData) {
    return this.prisma.activityLog.create({
      data: {
        householdId: data.householdId,
        actorId: data.actorId,
        actorType: data.actorType,
        actorName: data.actorName,
        action: data.action,
        category: data.category,
        title: data.title,
        description: data.description,
        billId: data.billId,
        vendorId: data.vendorId,
        assetId: data.assetId,
        zoneId: data.zoneId,
        taskId: data.taskId,
        amount: data.amount,
        metadata: data.metadata,
        visibleToHomeowner: data.visibleToHomeowner ?? true,
        visibleToHandyman: data.visibleToHandyman ?? false,
      },
    });
  }

  /**
   * Get activities for a household with optional filtering
   */
  async getForHousehold(householdId: string, options?: GetActivityOptions) {
    const where: Record<string, unknown> = {
      householdId,
    };

    // Only filter by visibility if explicitly requested
    if (options?.visibleToHomeowner !== undefined) {
      where.visibleToHomeowner = options.visibleToHomeowner;
    }

    if (options?.category) {
      where.category = options.category;
    }

    if (options?.startDate || options?.endDate) {
      where.createdAt = {};
      if (options?.startDate) {
        (where.createdAt as Record<string, Date>).gte = options.startDate;
      }
      if (options?.endDate) {
        (where.createdAt as Record<string, Date>).lte = options.endDate;
      }
    }

    return this.prisma.activityLog.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      take: options?.limit || 20,
    });
  }

  /**
   * Get recent activities for homeowner view (only visible ones)
   */
  async getRecentForHomeowner(householdId: string, limit = 10) {
    return this.getForHousehold(householdId, {
      limit,
      visibleToHomeowner: true,
    });
  }

  /**
   * Get activities by category
   */
  async getByCategory(householdId: string, category: ActivityCategory, limit = 20) {
    return this.getForHousehold(householdId, {
      limit,
      category,
      visibleToHomeowner: true,
    });
  }

  /**
   * Get activities for a specific bill
   */
  async getForBill(householdId: string, billId: string) {
    return this.prisma.activityLog.findMany({
      where: {
        householdId,
        billId,
        visibleToHomeowner: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  /**
   * Get activities for a specific vendor
   */
  async getForVendor(householdId: string, vendorId: string) {
    return this.prisma.activityLog.findMany({
      where: {
        householdId,
        vendorId,
        visibleToHomeowner: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  /**
   * Get activities for a specific asset
   */
  async getForAsset(householdId: string, assetId: string) {
    return this.prisma.activityLog.findMany({
      where: {
        householdId,
        assetId,
        visibleToHomeowner: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  /**
   * Get activity count by category for a date range
   */
  async getActivitySummary(householdId: string, startDate: Date, endDate: Date) {
    const activities = await this.prisma.activityLog.groupBy({
      by: ['category'],
      where: {
        householdId,
        createdAt: {
          gte: startDate,
          lte: endDate,
        },
      },
      _count: true,
    });

    return activities.reduce(
      (acc, item) => {
        acc[item.category] = item._count;
        return acc;
      },
      {} as Record<ActivityCategory, number>,
    );
  }
}
