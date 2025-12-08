import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';

import { PrismaService } from '../prisma';
import { JwtPayload } from '../auth';

import {
  CreateServiceRequestDto,
  UpdateServiceRequestDto,
  ServiceRequestDto,
  ServiceRequestDetailDto,
  ServiceRequestStatus,
  ServiceRequestPriority,
} from './dto';

@Injectable()
export class ServiceRequestsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(
    dto: CreateServiceRequestDto,
    user: JwtPayload,
  ): Promise<ServiceRequestDetailDto> {
    // Verify user has access to the household
    const membership = await this.prisma.householdMember.findUnique({
      where: {
        householdId_userId: {
          householdId: dto.householdId,
          userId: user.sub,
        },
      },
    });

    if (!membership && user.role !== 'ADMIN') {
      throw new ForbiddenException('You are not a member of this household');
    }

    // Verify category exists if provided
    if (dto.categoryId) {
      const category = await this.prisma.serviceCategory.findUnique({
        where: { id: dto.categoryId },
      });
      if (!category) {
        throw new BadRequestException(`Service category with ID ${dto.categoryId} not found`);
      }
    }

    const request = await this.prisma.serviceRequest.create({
      data: {
        household: { connect: { id: dto.householdId } },
        serviceCategory: dto.categoryId
          ? { connect: { id: dto.categoryId } }
          : undefined,
        createdBy: { connect: { id: user.sub } },
        title: dto.title,
        description: dto.description,
        priority: dto.priority || 'MEDIUM',
        preferredDate: dto.preferredDate ? new Date(dto.preferredDate) : null,
        notes: dto.notes,
        status: 'SUBMITTED',
      },
      include: {
        serviceCategory: true,
        vendor: true,
        createdBy: true,
        household: true,
      },
    });

    return this.mapToDetailDto(request);
  }

  async findByHousehold(
    householdId: string,
    user: JwtPayload,
  ): Promise<ServiceRequestDto[]> {
    // Verify user has access to the household (unless admin)
    if (user.role !== 'ADMIN') {
      const membership = await this.prisma.householdMember.findUnique({
        where: {
          householdId_userId: {
            householdId,
            userId: user.sub,
          },
        },
      });

      if (!membership || membership.status !== 'ACTIVE') {
        throw new ForbiddenException('You are not a member of this household');
      }
    }

    const requests = await this.prisma.serviceRequest.findMany({
      where: { householdId },
      orderBy: { createdAt: 'desc' },
    });

    return requests.map((r) => this.mapToDto(r));
  }

  async findManagerRequests(user: JwtPayload): Promise<ServiceRequestDetailDto[]> {
    // Manager sees requests assigned to them or from households they manage
    const managedHouseholds = await this.prisma.householdMember.findMany({
      where: {
        userId: user.sub,
        role: 'MANAGER',
        status: 'ACTIVE',
      },
      select: { householdId: true },
    });

    const householdIds = managedHouseholds.map((h) => h.householdId);

    const requests = await this.prisma.serviceRequest.findMany({
      where: {
        householdId: { in: householdIds },
        status: {
          in: ['SUBMITTED', 'ASSIGNED', 'IN_PROGRESS'],
        },
      },
      include: {
        serviceCategory: true,
        vendor: true,
        createdBy: true,
        household: true,
      },
      orderBy: [
        { priority: 'desc' },
        { createdAt: 'asc' },
      ],
    });

    return requests.map((r) => this.mapToDetailDto(r));
  }

  async findOne(id: string, user: JwtPayload): Promise<ServiceRequestDetailDto> {
    const request = await this.prisma.serviceRequest.findUnique({
      where: { id },
      include: {
        serviceCategory: true,
        vendor: true,
        createdBy: true,
        household: true,
      },
    });

    if (!request) {
      throw new NotFoundException(`Service request with ID ${id} not found`);
    }

    // Verify access
    if (user.role !== 'ADMIN') {
      const membership = await this.prisma.householdMember.findUnique({
        where: {
          householdId_userId: {
            householdId: request.householdId,
            userId: user.sub,
          },
        },
      });

      if (!membership || membership.status !== 'ACTIVE') {
        throw new ForbiddenException('You do not have access to this request');
      }
    }

    return this.mapToDetailDto(request);
  }

  async update(
    id: string,
    dto: UpdateServiceRequestDto,
    user: JwtPayload,
  ): Promise<ServiceRequestDetailDto> {
    const existing = await this.prisma.serviceRequest.findUnique({
      where: { id },
      include: { household: true },
    });

    if (!existing) {
      throw new NotFoundException(`Service request with ID ${id} not found`);
    }

    // Verify access based on role
    if (user.role !== 'ADMIN') {
      const membership = await this.prisma.householdMember.findUnique({
        where: {
          householdId_userId: {
            householdId: existing.householdId,
            userId: user.sub,
          },
        },
      });

      if (!membership || membership.status !== 'ACTIVE') {
        throw new ForbiddenException('You do not have access to this request');
      }

      // Only managers and admins can update status, assign vendors, or schedule
      if (
        (dto.status || dto.vendorId || dto.scheduledDate) &&
        membership.role !== 'MANAGER'
      ) {
        throw new ForbiddenException(
          'Only managers can update status, assign vendors, or schedule',
        );
      }
    }

    // Build update data
    const updateData: Prisma.ServiceRequestUpdateInput = {};

    if (dto.title !== undefined) updateData.title = dto.title;
    if (dto.description !== undefined) updateData.description = dto.description;
    if (dto.priority !== undefined) updateData.priority = dto.priority;
    if (dto.notes !== undefined) updateData.notes = dto.notes;
    if (dto.preferredDate !== undefined) {
      updateData.preferredDate = dto.preferredDate ? new Date(dto.preferredDate) : null;
    }

    if (dto.status !== undefined) {
      updateData.status = dto.status;
      // Auto-set completedDate when status changes to COMPLETED
      if (dto.status === 'COMPLETED') {
        updateData.completedDate = new Date();
      }
    }

    if (dto.vendorId !== undefined) {
      if (dto.vendorId) {
        // Verify vendor exists
        const vendor = await this.prisma.vendor.findUnique({
          where: { id: dto.vendorId },
        });
        if (!vendor) {
          throw new BadRequestException(`Vendor with ID ${dto.vendorId} not found`);
        }
        updateData.vendor = { connect: { id: dto.vendorId } };
        // Auto-set status to ASSIGNED when vendor is assigned
        if (!dto.status && existing.status === 'SUBMITTED') {
          updateData.status = 'ASSIGNED';
        }
      } else {
        updateData.vendor = { disconnect: true };
      }
    }

    if (dto.scheduledDate !== undefined) {
      updateData.scheduledDate = dto.scheduledDate ? new Date(dto.scheduledDate) : null;
    }

    if (dto.estimatedCost !== undefined) updateData.estimatedCost = dto.estimatedCost;
    if (dto.actualCost !== undefined) updateData.actualCost = dto.actualCost;

    if (dto.categoryId !== undefined) {
      if (dto.categoryId) {
        updateData.serviceCategory = { connect: { id: dto.categoryId } };
      } else {
        updateData.serviceCategory = { disconnect: true };
      }
    }

    const request = await this.prisma.serviceRequest.update({
      where: { id },
      data: updateData,
      include: {
        serviceCategory: true,
        vendor: true,
        createdBy: true,
        household: true,
      },
    });

    return this.mapToDetailDto(request);
  }

  private mapToDto(request: Prisma.ServiceRequestGetPayload<object>): ServiceRequestDto {
    return {
      id: request.id,
      householdId: request.householdId,
      serviceCategoryId: request.serviceCategoryId,
      vendorId: request.vendorId,
      createdById: request.createdById,
      title: request.title,
      description: request.description,
      status: request.status as ServiceRequestStatus,
      priority: request.priority as ServiceRequestPriority,
      preferredDate: request.preferredDate,
      scheduledDate: request.scheduledDate,
      completedDate: request.completedDate,
      estimatedCost: request.estimatedCost ? Number(request.estimatedCost) : null,
      actualCost: request.actualCost ? Number(request.actualCost) : null,
      notes: request.notes,
      createdAt: request.createdAt,
      updatedAt: request.updatedAt,
    };
  }

  private mapToDetailDto(
    request: Prisma.ServiceRequestGetPayload<{
      include: {
        serviceCategory: true;
        vendor: true;
        createdBy: true;
        household: true;
      };
    }>,
  ): ServiceRequestDetailDto {
    return {
      ...this.mapToDto(request),
      serviceCategory: request.serviceCategory
        ? {
            id: request.serviceCategory.id,
            name: request.serviceCategory.name,
            icon: request.serviceCategory.icon,
          }
        : null,
      vendor: request.vendor
        ? {
            id: request.vendor.id,
            companyName: request.vendor.companyName,
          }
        : null,
      createdBy: {
        id: request.createdBy.id,
        firstName: request.createdBy.firstName,
        lastName: request.createdBy.lastName,
        email: request.createdBy.email,
      },
      household: {
        id: request.household.id,
        name: request.household.name,
      },
    };
  }
}
