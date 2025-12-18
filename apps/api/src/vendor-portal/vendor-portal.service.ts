import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { WorkOrderStatus, VendorCategory } from '@prisma/client';
import {
  AcceptJobDto,
  CheckInDto,
  CheckOutDto,
  JobBoardQueryDto,
} from './dto';

@Injectable()
export class VendorPortalService {
  constructor(private prisma: PrismaService) {}

  // Include relations for work order responses
  private readonly workOrderInclude = {
    household: {
      select: {
        id: true,
        name: true,
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
      },
    },
  };

  /**
   * Get the vendor profile for a user
   */
  async getVendorByUserId(userId: string) {
    const vendor = await this.prisma.vendor.findFirst({
      where: { userId },
    });

    if (!vendor) {
      throw new NotFoundException('Vendor profile not found');
    }

    return vendor;
  }

  /**
   * Get open jobs matching vendor's category and service area
   */
  async getJobBoard(vendorId: string, query: JobBoardQueryDto) {
    const vendor = await this.prisma.vendor.findUnique({
      where: { id: vendorId },
    });

    if (!vendor) {
      throw new NotFoundException('Vendor not found');
    }

    const where: any = {
      status: WorkOrderStatus.OPEN,
      vendorId: null, // Only unassigned jobs
    };

    // Filter by vendor's category if applicable
    // Jobs might be for specific vendor categories based on the maintenance task
    // For now, we show all open jobs in the vendor's service areas

    // Filter by service area if vendor has service areas defined
    if (vendor.serviceAreas.length > 0) {
      if (query.serviceArea) {
        // Filter by specific area
        where.serviceArea = query.serviceArea;
      } else {
        // Filter by any of vendor's service areas
        where.serviceArea = {
          in: vendor.serviceAreas,
        };
      }
    }

    const jobs = await this.prisma.workOrder.findMany({
      where,
      include: this.workOrderInclude,
      orderBy: [{ scheduledStart: 'asc' }, { createdAt: 'desc' }],
    });

    return jobs;
  }

  /**
   * Get vendor's accepted/in-progress jobs (schedule)
   */
  async getMySchedule(vendorId: string) {
    const jobs = await this.prisma.workOrder.findMany({
      where: {
        vendorId,
        status: {
          in: [WorkOrderStatus.ASSIGNED, WorkOrderStatus.IN_PROGRESS],
        },
      },
      include: {
        ...this.workOrderInclude,
        household: {
          select: {
            id: true,
            name: true,
            homeProfile: {
              select: {
                addressLine1: true,
                addressLine2: true,
                city: true,
                state: true,
                postalCode: true,
                latitude: true,
                longitude: true,
              },
            },
          },
        },
      },
      orderBy: [{ scheduledStart: 'asc' }, { createdAt: 'desc' }],
    });

    return jobs.map((job) => ({
      ...job,
      household: {
        id: job.household.id,
        name: job.household.name,
        homeProfile: job.household.homeProfile
          ? {
              address: [
                job.household.homeProfile.addressLine1,
                job.household.homeProfile.addressLine2,
                job.household.homeProfile.city,
                job.household.homeProfile.state,
                job.household.homeProfile.postalCode,
              ]
                .filter(Boolean)
                .join(', '),
              latitude: job.household.homeProfile.latitude,
              longitude: job.household.homeProfile.longitude,
            }
          : undefined,
      },
    }));
  }

  /**
   * Get a single job detail
   */
  async getJobDetail(vendorId: string, workOrderId: string) {
    const job = await this.prisma.workOrder.findFirst({
      where: {
        id: workOrderId,
        OR: [
          { vendorId }, // Vendor's own job
          { status: WorkOrderStatus.OPEN, vendorId: null }, // Open job
        ],
      },
      include: {
        ...this.workOrderInclude,
        household: {
          select: {
            id: true,
            name: true,
            homeProfile: {
              select: {
                addressLine1: true,
                addressLine2: true,
                city: true,
                state: true,
                postalCode: true,
                latitude: true,
                longitude: true,
              },
            },
          },
        },
        notes: {
          include: {
            author: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
              },
            },
          },
          orderBy: { createdAt: 'desc' },
        },
      },
    });

    if (!job) {
      throw new NotFoundException('Work order not found');
    }

    return job;
  }

  /**
   * Accept/claim an open job
   */
  async acceptJob(vendorId: string, dto: AcceptJobDto) {
    const job = await this.prisma.workOrder.findFirst({
      where: {
        id: dto.workOrderId,
        status: WorkOrderStatus.OPEN,
        vendorId: null,
      },
    });

    if (!job) {
      throw new NotFoundException('Job not found or already claimed');
    }

    const updatedJob = await this.prisma.workOrder.update({
      where: { id: dto.workOrderId },
      data: {
        vendorId,
        status: WorkOrderStatus.ASSIGNED,
      },
      include: this.workOrderInclude,
    });

    // Create notification for household
    await this.createJobNotification(
      job.householdId,
      job.id,
      'Vendor Assigned',
      `A vendor has accepted your work order "${job.title}".`,
    );

    return updatedJob;
  }

  /**
   * Check in to start a job (captures geolocation)
   */
  async checkIn(vendorId: string, dto: CheckInDto) {
    const job = await this.prisma.workOrder.findFirst({
      where: {
        id: dto.workOrderId,
        vendorId,
        status: WorkOrderStatus.ASSIGNED,
      },
    });

    if (!job) {
      throw new NotFoundException('Job not found or not assigned to you');
    }

    const updatedJob = await this.prisma.workOrder.update({
      where: { id: dto.workOrderId },
      data: {
        status: WorkOrderStatus.IN_PROGRESS,
        checkInAt: new Date(),
        checkInLatitude: dto.latitude,
        checkInLongitude: dto.longitude,
      },
      include: this.workOrderInclude,
    });

    // Create notification for household
    await this.createJobNotification(
      job.householdId,
      job.id,
      'Vendor Arrived',
      `The vendor has checked in and started work on "${job.title}".`,
    );

    return updatedJob;
  }

  /**
   * Check out to complete a job (with proof images)
   */
  async checkOut(vendorId: string, dto: CheckOutDto) {
    const job = await this.prisma.workOrder.findFirst({
      where: {
        id: dto.workOrderId,
        vendorId,
        status: WorkOrderStatus.IN_PROGRESS,
      },
    });

    if (!job) {
      throw new NotFoundException('Job not found or not in progress');
    }

    if (dto.proofImages.length === 0) {
      throw new BadRequestException('At least one proof image is required');
    }

    const updateData: any = {
      status: WorkOrderStatus.COMPLETED,
      checkOutAt: new Date(),
      completedAt: new Date(),
      proofImages: dto.proofImages,
    };

    const updatedJob = await this.prisma.workOrder.update({
      where: { id: dto.workOrderId },
      data: updateData,
      include: this.workOrderInclude,
    });

    // Add completion note if provided
    if (dto.notes) {
      await this.prisma.workOrderNote.create({
        data: {
          workOrderId: dto.workOrderId,
          authorUserId: (await this.prisma.vendor.findUnique({ where: { id: vendorId } }))
            ?.userId || '',
          body: dto.notes,
        },
      });
    }

    // Create notification for household
    await this.createJobNotification(
      job.householdId,
      job.id,
      'Job Completed',
      `The vendor has completed work on "${job.title}". Awaiting verification.`,
    );

    return updatedJob;
  }

  /**
   * Get vendor's completed jobs history
   */
  async getCompletedJobs(vendorId: string) {
    return this.prisma.workOrder.findMany({
      where: {
        vendorId,
        status: {
          in: [WorkOrderStatus.COMPLETED, WorkOrderStatus.VERIFIED],
        },
      },
      include: this.workOrderInclude,
      orderBy: { completedAt: 'desc' },
      take: 50,
    });
  }

  // =====================
  // MANAGER VERIFICATION
  // =====================

  /**
   * Get jobs pending verification (for managers)
   */
  async getVerificationQueue() {
    return this.prisma.workOrder.findMany({
      where: {
        status: WorkOrderStatus.COMPLETED,
      },
      include: {
        household: {
          select: {
            id: true,
            name: true,
          },
        },
        vendor: {
          select: {
            id: true,
            displayName: true,
            phone: true,
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
              },
            },
          },
          orderBy: { createdAt: 'desc' },
          take: 5,
        },
      },
      orderBy: { completedAt: 'asc' },
    });
  }

  /**
   * Verify/approve a completed job
   */
  async verifyJob(managerId: string, workOrderId: string, notes?: string) {
    const job = await this.prisma.workOrder.findFirst({
      where: {
        id: workOrderId,
        status: WorkOrderStatus.COMPLETED,
      },
    });

    if (!job) {
      throw new NotFoundException('Job not found or not awaiting verification');
    }

    const updatedJob = await this.prisma.workOrder.update({
      where: { id: workOrderId },
      data: {
        status: WorkOrderStatus.VERIFIED,
        verifiedAt: new Date(),
        verifiedByUserId: managerId,
      },
      include: this.workOrderInclude,
    });

    // Add verification note if provided
    if (notes) {
      await this.prisma.workOrderNote.create({
        data: {
          workOrderId,
          authorUserId: managerId,
          body: `[VERIFIED] ${notes}`,
        },
      });
    }

    // Create notification for household
    await this.createJobNotification(
      job.householdId,
      job.id,
      'Job Verified',
      `Work order "${job.title}" has been verified and approved.`,
    );

    return updatedJob;
  }

  /**
   * Request revision on a completed job
   */
  async requestRevision(managerId: string, workOrderId: string, reason: string) {
    const job = await this.prisma.workOrder.findFirst({
      where: {
        id: workOrderId,
        status: WorkOrderStatus.COMPLETED,
      },
    });

    if (!job) {
      throw new NotFoundException('Job not found or not awaiting verification');
    }

    // Set status back to IN_PROGRESS so vendor can redo
    const updatedJob = await this.prisma.workOrder.update({
      where: { id: workOrderId },
      data: {
        status: WorkOrderStatus.IN_PROGRESS,
        proofImages: [], // Clear proof images
        completedAt: null,
      },
      include: this.workOrderInclude,
    });

    // Add revision request note
    await this.prisma.workOrderNote.create({
      data: {
        workOrderId,
        authorUserId: managerId,
        body: `[REVISION REQUESTED] ${reason}`,
      },
    });

    // TODO: Send notification to vendor about revision request

    return updatedJob;
  }

  /**
   * Helper to create in-app notifications
   */
  private async createJobNotification(
    householdId: string,
    workOrderId: string,
    title: string,
    body: string,
  ) {
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
