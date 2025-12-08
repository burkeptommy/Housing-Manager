import { Injectable } from '@nestjs/common';
import { Prisma, ServiceRequest, ServiceRequestStatus, ServiceRequestPriority } from '@prisma/client';

import { PrismaService } from '../../prisma';

import { BaseRepository, PaginatedResult, PaginationParams } from './base.repository';

export type ServiceRequestWithRelations = Prisma.ServiceRequestGetPayload<{
  include: {
    household: true;
    serviceCategory: true;
    vendor: true;
    createdBy: true;
  };
}>;

export type ServiceRequestWithMessages = Prisma.ServiceRequestGetPayload<{
  include: {
    household: true;
    serviceCategory: true;
    vendor: true;
    createdBy: true;
    messages: { include: { sender: true; vendor: true } };
    files: true;
  };
}>;

export interface ServiceRequestFilters {
  householdId?: string;
  vendorId?: string;
  serviceCategoryId?: string;
  status?: ServiceRequestStatus;
  priority?: ServiceRequestPriority;
  createdById?: string;
}

@Injectable()
export class ServiceRequestRepository extends BaseRepository {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async create(data: Prisma.ServiceRequestCreateInput): Promise<ServiceRequest> {
    return this.prisma.serviceRequest.create({ data });
  }

  async findById(id: string): Promise<ServiceRequest | null> {
    return this.prisma.serviceRequest.findUnique({ where: { id } });
  }

  async findByIdWithRelations(id: string): Promise<ServiceRequestWithRelations | null> {
    return this.prisma.serviceRequest.findUnique({
      where: { id },
      include: {
        household: true,
        serviceCategory: true,
        vendor: true,
        createdBy: true,
      },
    });
  }

  async findByIdWithMessages(id: string): Promise<ServiceRequestWithMessages | null> {
    return this.prisma.serviceRequest.findUnique({
      where: { id },
      include: {
        household: true,
        serviceCategory: true,
        vendor: true,
        createdBy: true,
        messages: {
          include: { sender: true, vendor: true },
          orderBy: { createdAt: 'asc' },
        },
        files: true,
      },
    });
  }

  async findMany(
    filters: ServiceRequestFilters,
    params: PaginationParams = {}
  ): Promise<PaginatedResult<ServiceRequestWithRelations>> {
    const { page, pageSize } = params;
    const { householdId, vendorId, serviceCategoryId, status, priority, createdById } = filters;

    const where: Prisma.ServiceRequestWhereInput = {};

    if (householdId) where.householdId = householdId;
    if (vendorId) where.vendorId = vendorId;
    if (serviceCategoryId) where.serviceCategoryId = serviceCategoryId;
    if (status) where.status = status;
    if (priority) where.priority = priority;
    if (createdById) where.createdById = createdById;

    const [data, total] = await Promise.all([
      this.prisma.serviceRequest.findMany({
        where,
        include: {
          household: true,
          serviceCategory: true,
          vendor: true,
          createdBy: true,
        },
        ...this.getPaginationParams({ page, pageSize }),
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.serviceRequest.count({ where }),
    ]);

    return this.paginate(data, total, { page, pageSize });
  }

  async findByHousehold(
    householdId: string,
    params: PaginationParams = {}
  ): Promise<PaginatedResult<ServiceRequestWithRelations>> {
    return this.findMany({ householdId }, params);
  }

  async update(id: string, data: Prisma.ServiceRequestUpdateInput): Promise<ServiceRequest> {
    return this.prisma.serviceRequest.update({ where: { id }, data });
  }

  async updateStatus(
    id: string,
    status: ServiceRequestStatus,
    completedDate?: Date
  ): Promise<ServiceRequest> {
    return this.prisma.serviceRequest.update({
      where: { id },
      data: {
        status,
        completedDate: status === 'COMPLETED' ? completedDate ?? new Date() : undefined,
      },
    });
  }

  async assignVendor(id: string, vendorId: string): Promise<ServiceRequest> {
    return this.prisma.serviceRequest.update({
      where: { id },
      data: {
        vendorId,
        status: 'ASSIGNED',
      },
    });
  }

  async delete(id: string): Promise<ServiceRequest> {
    return this.prisma.serviceRequest.delete({ where: { id } });
  }

  async countByStatus(householdId: string): Promise<Record<ServiceRequestStatus, number>> {
    const counts = await this.prisma.serviceRequest.groupBy({
      by: ['status'],
      where: { householdId },
      _count: { status: true },
    });

    const result: Record<ServiceRequestStatus, number> = {
      DRAFT: 0,
      SUBMITTED: 0,
      ASSIGNED: 0,
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
