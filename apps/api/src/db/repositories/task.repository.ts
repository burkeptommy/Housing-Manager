import { Injectable } from '@nestjs/common';
import { Prisma, Task, TaskStatus, TaskPriority } from '@prisma/client';

import { PrismaService } from '../../prisma';

import { BaseRepository, PaginatedResult, PaginationParams } from './base.repository';

export type TaskWithRelations = Prisma.TaskGetPayload<{
  include: {
    household: true;
    createdBy: true;
    assignee: true;
  };
}>;

export interface TaskFilters {
  householdId?: string;
  assigneeId?: string;
  createdById?: string;
  status?: TaskStatus;
  priority?: TaskPriority;
  dueBefore?: Date;
  dueAfter?: Date;
}

@Injectable()
export class TaskRepository extends BaseRepository {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async create(data: Prisma.TaskCreateInput): Promise<Task> {
    return this.prisma.task.create({ data });
  }

  async findById(id: string): Promise<Task | null> {
    return this.prisma.task.findUnique({ where: { id } });
  }

  async findByIdWithRelations(id: string): Promise<TaskWithRelations | null> {
    return this.prisma.task.findUnique({
      where: { id },
      include: {
        household: true,
        createdBy: true,
        assignee: true,
      },
    });
  }

  async findMany(
    filters: TaskFilters,
    params: PaginationParams = {}
  ): Promise<PaginatedResult<TaskWithRelations>> {
    const { page, pageSize } = params;
    const { householdId, assigneeId, createdById, status, priority, dueBefore, dueAfter } = filters;

    const where: Prisma.TaskWhereInput = {};

    if (householdId) where.householdId = householdId;
    if (assigneeId) where.assigneeId = assigneeId;
    if (createdById) where.createdById = createdById;
    if (status) where.status = status;
    if (priority) where.priority = priority;

    if (dueBefore || dueAfter) {
      where.dueDate = {};
      if (dueBefore) where.dueDate.lte = dueBefore;
      if (dueAfter) where.dueDate.gte = dueAfter;
    }

    const [data, total] = await Promise.all([
      this.prisma.task.findMany({
        where,
        include: {
          household: true,
          createdBy: true,
          assignee: true,
        },
        ...this.getPaginationParams({ page, pageSize }),
        orderBy: [{ dueDate: 'asc' }, { priority: 'desc' }, { createdAt: 'desc' }],
      }),
      this.prisma.task.count({ where }),
    ]);

    return this.paginate(data, total, { page, pageSize });
  }

  async findByHousehold(
    householdId: string,
    params: PaginationParams = {}
  ): Promise<PaginatedResult<TaskWithRelations>> {
    return this.findMany({ householdId }, params);
  }

  async findByAssignee(
    assigneeId: string,
    params: PaginationParams = {}
  ): Promise<PaginatedResult<TaskWithRelations>> {
    return this.findMany({ assigneeId }, params);
  }

  async findOverdue(householdId?: string): Promise<Task[]> {
    const where: Prisma.TaskWhereInput = {
      status: { in: ['PENDING', 'IN_PROGRESS'] },
      dueDate: { lt: new Date() },
    };

    if (householdId) where.householdId = householdId;

    return this.prisma.task.findMany({
      where,
      orderBy: { dueDate: 'asc' },
    });
  }

  async update(id: string, data: Prisma.TaskUpdateInput): Promise<Task> {
    return this.prisma.task.update({ where: { id }, data });
  }

  async updateStatus(id: string, status: TaskStatus): Promise<Task> {
    return this.prisma.task.update({
      where: { id },
      data: {
        status,
        completedAt: status === 'COMPLETED' ? new Date() : undefined,
      },
    });
  }

  async assign(id: string, assigneeId: string): Promise<Task> {
    return this.prisma.task.update({
      where: { id },
      data: { assigneeId },
    });
  }

  async delete(id: string): Promise<Task> {
    return this.prisma.task.delete({ where: { id } });
  }

  async countByStatus(householdId: string): Promise<Record<TaskStatus, number>> {
    const counts = await this.prisma.task.groupBy({
      by: ['status'],
      where: { householdId },
      _count: { status: true },
    });

    const result: Record<TaskStatus, number> = {
      PENDING: 0,
      IN_PROGRESS: 0,
      COMPLETED: 0,
      CANCELLED: 0,
    };

    for (const item of counts) {
      result[item.status] = item._count.status;
    }

    return result;
  }
}
