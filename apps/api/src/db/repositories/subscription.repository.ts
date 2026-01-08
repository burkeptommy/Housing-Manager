import { Injectable } from '@nestjs/common';
import { Prisma, Subscription, SubscriptionStatus, SubscriptionTier } from '@prisma/client';

import { PrismaService } from '../../prisma';

import { BaseRepository, PaginatedResult, PaginationParams } from './base.repository';

export type SubscriptionWithUser = Prisma.SubscriptionGetPayload<{
  include: { user: true };
}>;

@Injectable()
export class SubscriptionRepository extends BaseRepository {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async create(data: Prisma.SubscriptionCreateInput): Promise<Subscription> {
    return this.prisma.subscription.create({ data });
  }

  async findById(id: string): Promise<Subscription | null> {
    return this.prisma.subscription.findUnique({ where: { id } });
  }

  async findByUserId(userId: string): Promise<Subscription | null> {
    return this.prisma.subscription.findFirst({
      where: {
        userId,
        status: { in: ['ACTIVE', 'PAST_DUE'] },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findActiveByUserId(userId: string): Promise<Subscription | null> {
    return this.prisma.subscription.findFirst({
      where: {
        userId,
        status: 'ACTIVE',
      },
    });
  }

  async findByStripeSubscriptionId(stripeSubscriptionId: string): Promise<Subscription | null> {
    return this.prisma.subscription.findFirst({
      where: { stripeSubscriptionId },
    });
  }

  async findMany(
    params: PaginationParams & {
      status?: SubscriptionStatus;
      tier?: SubscriptionTier;
    }
  ): Promise<PaginatedResult<SubscriptionWithUser>> {
    const { page, pageSize, status, tier } = params;

    const where: Prisma.SubscriptionWhereInput = {};

    if (status) where.status = status;
    if (tier) where.tier = tier;

    const [data, total] = await Promise.all([
      this.prisma.subscription.findMany({
        where,
        include: { user: true },
        ...this.getPaginationParams({ page, pageSize }),
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.subscription.count({ where }),
    ]);

    return this.paginate(data, total, { page, pageSize });
  }

  async update(id: string, data: Prisma.SubscriptionUpdateInput): Promise<Subscription> {
    return this.prisma.subscription.update({ where: { id }, data });
  }

  async updateStatus(id: string, status: SubscriptionStatus): Promise<Subscription> {
    const data: Prisma.SubscriptionUpdateInput = { status };

    if (status === 'CANCELLED') {
      data.cancelledAt = new Date();
    }

    return this.prisma.subscription.update({ where: { id }, data });
  }

  async upgradeTier(id: string, tier: SubscriptionTier): Promise<Subscription> {
    return this.prisma.subscription.update({
      where: { id },
      data: { tier },
    });
  }

  async cancel(id: string, atPeriodEnd: boolean = true): Promise<Subscription> {
    return this.prisma.subscription.update({
      where: { id },
      data: {
        cancelAtPeriodEnd: atPeriodEnd,
        cancelledAt: atPeriodEnd ? null : new Date(),
        status: atPeriodEnd ? undefined : 'CANCELLED',
      },
    });
  }

  async renewPeriod(
    id: string,
    periodStart: Date,
    periodEnd: Date
  ): Promise<Subscription> {
    return this.prisma.subscription.update({
      where: { id },
      data: {
        currentPeriodStart: periodStart,
        currentPeriodEnd: periodEnd,
        status: 'ACTIVE',
      },
    });
  }

  async findExpiring(daysAhead: number = 7): Promise<Subscription[]> {
    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + daysAhead);

    return this.prisma.subscription.findMany({
      where: {
        status: 'ACTIVE',
        currentPeriodEnd: { lte: futureDate },
        cancelAtPeriodEnd: false,
      },
      orderBy: { currentPeriodEnd: 'asc' },
    });
  }

  async countByTier(): Promise<Record<SubscriptionTier, number>> {
    const counts = await this.prisma.subscription.groupBy({
      by: ['tier'],
      where: { status: 'ACTIVE' },
      _count: { tier: true },
    });

    const result: Record<SubscriptionTier, number> = {
      FREE: 0,
      BASIC: 0,
      PREMIUM: 0,
      ENTERPRISE: 0,
      // Haven tiers
      ESSENTIALS: 0,
      LITE: 0,
      HAVEN: 0,
      HAVEN_PLUS: 0,
      ESTATE: 0,
    };

    for (const item of counts) {
      result[item.tier] = item._count.tier;
    }

    return result;
  }
}
