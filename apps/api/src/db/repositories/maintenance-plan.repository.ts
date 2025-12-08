import { Injectable } from '@nestjs/common';
import { Prisma, MaintenancePlan, MaintenanceFrequency } from '@prisma/client';

import { PrismaService } from '../../prisma';

import { BaseRepository, PaginatedResult, PaginationParams } from './base.repository';

export type MaintenancePlanWithCategory = Prisma.MaintenancePlanGetPayload<{
  include: { serviceCategory: true; household: true };
}>;

@Injectable()
export class MaintenancePlanRepository extends BaseRepository {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async create(data: Prisma.MaintenancePlanCreateInput): Promise<MaintenancePlan> {
    return this.prisma.maintenancePlan.create({ data });
  }

  async findById(id: string): Promise<MaintenancePlan | null> {
    return this.prisma.maintenancePlan.findUnique({ where: { id } });
  }

  async findByIdWithRelations(id: string): Promise<MaintenancePlanWithCategory | null> {
    return this.prisma.maintenancePlan.findUnique({
      where: { id },
      include: { serviceCategory: true, household: true },
    });
  }

  async findByHousehold(
    householdId: string,
    params: PaginationParams & { isActive?: boolean } = {}
  ): Promise<PaginatedResult<MaintenancePlanWithCategory>> {
    const { page, pageSize, isActive } = params;

    const where: Prisma.MaintenancePlanWhereInput = { householdId };
    if (typeof isActive === 'boolean') where.isActive = isActive;

    const [data, total] = await Promise.all([
      this.prisma.maintenancePlan.findMany({
        where,
        include: { serviceCategory: true, household: true },
        ...this.getPaginationParams({ page, pageSize }),
        orderBy: { nextDueDate: 'asc' },
      }),
      this.prisma.maintenancePlan.count({ where }),
    ]);

    return this.paginate(data, total, { page, pageSize });
  }

  async findDue(daysAhead: number = 7): Promise<MaintenancePlan[]> {
    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + daysAhead);

    return this.prisma.maintenancePlan.findMany({
      where: {
        isActive: true,
        nextDueDate: { lte: futureDate },
      },
      orderBy: { nextDueDate: 'asc' },
    });
  }

  async update(id: string, data: Prisma.MaintenancePlanUpdateInput): Promise<MaintenancePlan> {
    return this.prisma.maintenancePlan.update({ where: { id }, data });
  }

  async markCompleted(id: string): Promise<MaintenancePlan> {
    const plan = await this.findById(id);
    if (!plan) throw new Error('Maintenance plan not found');

    const nextDueDate = this.calculateNextDueDate(plan.frequency);

    return this.prisma.maintenancePlan.update({
      where: { id },
      data: {
        lastCompletedAt: new Date(),
        nextDueDate,
      },
    });
  }

  async delete(id: string): Promise<MaintenancePlan> {
    return this.prisma.maintenancePlan.delete({ where: { id } });
  }

  async toggleActive(id: string): Promise<MaintenancePlan> {
    const plan = await this.findById(id);
    if (!plan) throw new Error('Maintenance plan not found');

    return this.prisma.maintenancePlan.update({
      where: { id },
      data: { isActive: !plan.isActive },
    });
  }

  private calculateNextDueDate(frequency: MaintenanceFrequency): Date {
    const now = new Date();

    switch (frequency) {
      case 'WEEKLY':
        now.setDate(now.getDate() + 7);
        break;
      case 'BIWEEKLY':
        now.setDate(now.getDate() + 14);
        break;
      case 'MONTHLY':
        now.setMonth(now.getMonth() + 1);
        break;
      case 'QUARTERLY':
        now.setMonth(now.getMonth() + 3);
        break;
      case 'SEMIANNUALLY':
        now.setMonth(now.getMonth() + 6);
        break;
      case 'ANNUALLY':
        now.setFullYear(now.getFullYear() + 1);
        break;
    }

    return now;
  }
}
