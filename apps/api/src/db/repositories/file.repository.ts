import { Injectable } from '@nestjs/common';
import { Prisma, File, FileCategory } from '@prisma/client';

import { PrismaService } from '../../prisma';

import { BaseRepository, PaginatedResult, PaginationParams } from './base.repository';

export interface FileFilters {
  userId?: string;
  householdId?: string;
  serviceRequestId?: string;
  taskId?: string;
  invoiceId?: string;
  category?: FileCategory;
}

@Injectable()
export class FileRepository extends BaseRepository {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async create(data: Prisma.FileCreateInput): Promise<File> {
    return this.prisma.file.create({ data });
  }

  async findById(id: string): Promise<File | null> {
    return this.prisma.file.findUnique({ where: { id } });
  }

  async findMany(
    filters: FileFilters,
    params: PaginationParams = {}
  ): Promise<PaginatedResult<File>> {
    const { page, pageSize } = params;
    const { userId, householdId, serviceRequestId, taskId, invoiceId, category } = filters;

    const where: Prisma.FileWhereInput = {};

    if (userId) where.userId = userId;
    if (householdId) where.householdId = householdId;
    if (serviceRequestId) where.serviceRequestId = serviceRequestId;
    if (taskId) where.taskId = taskId;
    if (invoiceId) where.invoiceId = invoiceId;
    if (category) where.category = category;

    const [data, total] = await Promise.all([
      this.prisma.file.findMany({
        where,
        ...this.getPaginationParams({ page, pageSize }),
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.file.count({ where }),
    ]);

    return this.paginate(data, total, { page, pageSize });
  }

  async findByHousehold(
    householdId: string,
    params: PaginationParams & { category?: FileCategory } = {}
  ): Promise<PaginatedResult<File>> {
    const { category, ...paginationParams } = params;
    return this.findMany({ householdId, category }, paginationParams);
  }

  async findByServiceRequest(serviceRequestId: string): Promise<File[]> {
    return this.prisma.file.findMany({
      where: { serviceRequestId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findByTask(taskId: string): Promise<File[]> {
    return this.prisma.file.findMany({
      where: { taskId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async update(id: string, data: Prisma.FileUpdateInput): Promise<File> {
    return this.prisma.file.update({ where: { id }, data });
  }

  async delete(id: string): Promise<File> {
    return this.prisma.file.delete({ where: { id } });
  }

  async deleteMany(ids: string[]): Promise<Prisma.BatchPayload> {
    return this.prisma.file.deleteMany({
      where: { id: { in: ids } },
    });
  }

  async getTotalSizeByHousehold(householdId: string): Promise<number> {
    const result = await this.prisma.file.aggregate({
      where: { householdId },
      _sum: { size: true },
    });

    return result._sum.size || 0;
  }

  async countByCategory(householdId: string): Promise<Record<FileCategory, number>> {
    const counts = await this.prisma.file.groupBy({
      by: ['category'],
      where: { householdId },
      _count: { category: true },
    });

    const result: Record<FileCategory, number> = {
      DOCUMENT: 0,
      IMAGE: 0,
      RECEIPT: 0,
      WARRANTY: 0,
      MANUAL: 0,
      CONTRACT: 0,
      OTHER: 0,
    };

    for (const item of counts) {
      result[item.category] = item._count.category;
    }

    return result;
  }
}
