import { Injectable, Logger, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateTripDto, UpdateTripDto, TripQueryDto, AssignTripDto } from '../dto';
import { TripStatus } from '@prisma/client';

@Injectable()
export class TripService {
  private readonly logger = new Logger(TripService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Create a new trip inquiry
   */
  async create(householdId: string, userId: string, dto: CreateTripDto) {
    return this.prisma.trip.create({
      data: {
        householdId,
        createdByUserId: userId,
        title: dto.title,
        destination: dto.destination,
        destinationCountry: dto.destinationCountry,
        departureCity: dto.departureCity,
        startDate: dto.startDate,
        endDate: dto.endDate,
        isFlexibleDates: dto.isFlexibleDates ?? false,
        budgetMin: dto.budgetMin,
        budgetMax: dto.budgetMax,
        budgetNotes: dto.budgetNotes,
        travelerCount: dto.travelerCount ?? 1,
        travelers: dto.travelers,
        notes: dto.notes,
        status: TripStatus.INQUIRY,
      },
      include: {
        createdBy: {
          select: { id: true, displayName: true },
        },
        household: {
          select: { id: true, name: true },
        },
      },
    });
  }

  /**
   * Create trip from chat/AI classification
   */
  async createFromChat(
    householdId: string,
    userId: string,
    extractedEntities: {
      destination?: string;
      dates?: { start?: string; end?: string };
      budget?: number;
      travelers?: number;
    },
  ) {
    const title = extractedEntities.destination
      ? `Trip to ${extractedEntities.destination}`
      : 'New Trip Request';

    return this.create(householdId, userId, {
      title,
      destination: extractedEntities.destination || 'TBD',
      startDate: extractedEntities.dates?.start
        ? new Date(extractedEntities.dates.start)
        : new Date(),
      endDate: extractedEntities.dates?.end
        ? new Date(extractedEntities.dates.end)
        : new Date(),
      budgetMax: extractedEntities.budget,
      travelerCount: extractedEntities.travelers,
    });
  }

  /**
   * Get all trips for a household
   */
  async findAllByHousehold(householdId: string, query?: TripQueryDto) {
    const where: any = { householdId };

    if (query?.status && query.status.length > 0) {
      where.status = { in: query.status };
    }

    return this.prisma.trip.findMany({
      where,
      include: {
        createdBy: {
          select: { id: true, displayName: true },
        },
        assignedManager: {
          select: { id: true, displayName: true },
        },
        _count: {
          select: {
            proposals: true,
            itineraryItems: true,
          },
        },
      },
      orderBy: { startDate: 'asc' },
      take: query?.limit,
    });
  }

  /**
   * Get trip details
   */
  async findOne(id: string, householdId?: string) {
    const trip = await this.prisma.trip.findUnique({
      where: { id },
      include: {
        household: {
          select: { id: true, name: true },
        },
        createdBy: {
          select: { id: true, displayName: true, email: true },
        },
        assignedManager: {
          select: { id: true, displayName: true, email: true },
        },
        proposals: {
          orderBy: { createdAt: 'desc' },
          include: {
            createdByManager: {
              select: { id: true, displayName: true },
            },
          },
        },
        itineraryItems: {
          orderBy: { startDateTime: 'asc' },
        },
        houseProtocol: {
          include: {
            assignedTo: {
              select: { id: true, displayName: true },
            },
            items: {
              orderBy: { sortOrder: 'asc' },
            },
          },
        },
        transactions: {
          select: {
            id: true,
            description: true,
            amount: true,
            status: true,
          },
        },
      },
    });

    if (!trip) {
      throw new NotFoundException('Trip not found');
    }

    if (householdId && trip.householdId !== householdId) {
      throw new ForbiddenException('Access denied');
    }

    return trip;
  }

  /**
   * Update a trip
   */
  async update(id: string, householdId: string, dto: UpdateTripDto) {
    const trip = await this.findOne(id, householdId);

    return this.prisma.trip.update({
      where: { id },
      data: {
        title: dto.title,
        destination: dto.destination,
        destinationCountry: dto.destinationCountry,
        departureCity: dto.departureCity,
        startDate: dto.startDate,
        endDate: dto.endDate,
        isFlexibleDates: dto.isFlexibleDates,
        budgetMin: dto.budgetMin,
        budgetMax: dto.budgetMax,
        budgetNotes: dto.budgetNotes,
        travelerCount: dto.travelerCount,
        travelers: dto.travelers,
        notes: dto.notes,
        status: dto.status,
      },
      include: {
        createdBy: {
          select: { id: true, displayName: true },
        },
      },
    });
  }

  /**
   * Update trip status
   */
  async updateStatus(id: string, status: TripStatus, householdId?: string) {
    if (householdId) {
      await this.findOne(id, householdId);
    }

    return this.prisma.trip.update({
      where: { id },
      data: { status },
    });
  }

  /**
   * Cancel a trip
   */
  async cancel(id: string, householdId: string) {
    await this.findOne(id, householdId);

    return this.prisma.trip.update({
      where: { id },
      data: { status: TripStatus.CANCELLED },
    });
  }

  /**
   * Assign a manager to a trip (internal use)
   */
  async assignManager(id: string, managerId: string) {
    return this.prisma.trip.update({
      where: { id },
      data: { assignedManagerId: managerId },
      include: {
        assignedManager: {
          select: { id: true, displayName: true, email: true },
        },
      },
    });
  }

  /**
   * Recalculate trip totals from itinerary items
   */
  async recalculateTotals(tripId: string) {
    const items = await this.prisma.itineraryItem.findMany({
      where: { tripId },
    });

    const totalEstimatedCost = items.reduce(
      (sum, item) => sum + Number(item.cost),
      0,
    );

    // Actual cost is from linked transactions
    const transactions = await this.prisma.transaction.findMany({
      where: { tripId },
    });

    const totalActualCost = transactions.reduce(
      (sum, t) => sum + Number(t.amount),
      0,
    );

    return this.prisma.trip.update({
      where: { id: tripId },
      data: {
        totalEstimatedCost,
        totalActualCost: totalActualCost || null,
      },
    });
  }

  /**
   * Get pipeline view for managers (trips by status)
   */
  async getPipeline() {
    const trips = await this.prisma.trip.findMany({
      include: {
        household: {
          select: { id: true, name: true },
        },
        createdBy: {
          select: { id: true, displayName: true },
        },
        assignedManager: {
          select: { id: true, displayName: true },
        },
        _count: {
          select: {
            proposals: true,
            itineraryItems: true,
          },
        },
      },
      orderBy: { startDate: 'asc' },
    });

    // Group by status
    const pipeline: Record<TripStatus, typeof trips> = {
      [TripStatus.INQUIRY]: [],
      [TripStatus.PROPOSAL_SENT]: [],
      [TripStatus.PENDING_SELECTION]: [],
      [TripStatus.BOOKED]: [],
      [TripStatus.ACTIVE]: [],
      [TripStatus.COMPLETED]: [],
      [TripStatus.CANCELLED]: [],
    };

    for (const trip of trips) {
      pipeline[trip.status].push(trip);
    }

    return pipeline;
  }

  /**
   * Get upcoming trips (for dashboard)
   */
  async getUpcoming(householdId: string, limit = 5) {
    return this.prisma.trip.findMany({
      where: {
        householdId,
        status: { in: [TripStatus.BOOKED, TripStatus.ACTIVE] },
        startDate: { gte: new Date() },
      },
      include: {
        houseProtocol: {
          select: { status: true },
        },
        _count: {
          select: { itineraryItems: true },
        },
      },
      orderBy: { startDate: 'asc' },
      take: limit,
    });
  }
}
