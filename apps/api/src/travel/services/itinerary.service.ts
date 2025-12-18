import { Injectable, Logger, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateItineraryItemDto, UpdateItineraryItemDto, AttachDocumentDto } from '../dto';
import { TripStatus } from '@prisma/client';

export interface ItineraryDay {
  date: string;
  dayNumber: number;
  items: any[];
}

@Injectable()
export class ItineraryService {
  private readonly logger = new Logger(ItineraryService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Add an itinerary item to a trip
   */
  async create(tripId: string, dto: CreateItineraryItemDto) {
    const trip = await this.prisma.trip.findUnique({
      where: { id: tripId },
    });

    if (!trip) {
      throw new NotFoundException('Trip not found');
    }

    // Get the next sort order
    const lastItem = await this.prisma.itineraryItem.findFirst({
      where: { tripId },
      orderBy: { sortOrder: 'desc' },
    });

    const sortOrder = dto.sortOrder ?? (lastItem?.sortOrder ?? 0) + 1;

    const item = await this.prisma.itineraryItem.create({
      data: {
        tripId,
        type: dto.type,
        title: dto.title,
        description: dto.description,
        startDateTime: dto.startDateTime,
        endDateTime: dto.endDateTime,
        timezone: dto.timezone,
        startLocation: dto.startLocation,
        endLocation: dto.endLocation,
        confirmationNumber: dto.confirmationNumber,
        bookingReference: dto.bookingReference,
        providerName: dto.providerName,
        cost: dto.cost,
        currency: dto.currency ?? 'USD',
        paidByHaven: dto.paidByHaven ?? true,
        documents: dto.documents ?? [],
        sortOrder,
        notes: dto.notes,
      },
    });

    // Recalculate trip totals
    await this.recalculateTripTotals(tripId);

    return item;
  }

  /**
   * Update an itinerary item
   */
  async update(id: string, dto: UpdateItineraryItemDto) {
    const item = await this.prisma.itineraryItem.findUnique({
      where: { id },
    });

    if (!item) {
      throw new NotFoundException('Itinerary item not found');
    }

    const updated = await this.prisma.itineraryItem.update({
      where: { id },
      data: {
        type: dto.type,
        title: dto.title,
        description: dto.description,
        startDateTime: dto.startDateTime,
        endDateTime: dto.endDateTime,
        timezone: dto.timezone,
        startLocation: dto.startLocation,
        endLocation: dto.endLocation,
        confirmationNumber: dto.confirmationNumber,
        bookingReference: dto.bookingReference,
        providerName: dto.providerName,
        cost: dto.cost,
        currency: dto.currency,
        paidByHaven: dto.paidByHaven,
        documents: dto.documents,
        sortOrder: dto.sortOrder,
        notes: dto.notes,
      },
    });

    // Recalculate trip totals
    await this.recalculateTripTotals(item.tripId);

    return updated;
  }

  /**
   * Delete an itinerary item
   */
  async remove(id: string) {
    const item = await this.prisma.itineraryItem.findUnique({
      where: { id },
    });

    if (!item) {
      throw new NotFoundException('Itinerary item not found');
    }

    await this.prisma.itineraryItem.delete({
      where: { id },
    });

    // Recalculate trip totals
    await this.recalculateTripTotals(item.tripId);
  }

  /**
   * Get itinerary for a trip
   */
  async findByTrip(tripId: string, householdId?: string) {
    if (householdId) {
      const trip = await this.prisma.trip.findUnique({
        where: { id: tripId },
      });

      if (!trip || trip.householdId !== householdId) {
        throw new NotFoundException('Trip not found');
      }
    }

    return this.prisma.itineraryItem.findMany({
      where: { tripId },
      orderBy: { startDateTime: 'asc' },
    });
  }

  /**
   * Get itinerary as day-by-day timeline
   */
  async getTimeline(tripId: string, householdId?: string): Promise<ItineraryDay[]> {
    const trip = await this.prisma.trip.findUnique({
      where: { id: tripId },
    });

    if (!trip) {
      throw new NotFoundException('Trip not found');
    }

    if (householdId && trip.householdId !== householdId) {
      throw new ForbiddenException('Access denied');
    }

    const items = await this.prisma.itineraryItem.findMany({
      where: { tripId },
      orderBy: { startDateTime: 'asc' },
    });

    // Group items by date
    const dayMap = new Map<string, any[]>();
    const tripStart = new Date(trip.startDate);

    for (const item of items) {
      const dateStr = item.startDateTime.toISOString().split('T')[0];
      if (!dayMap.has(dateStr)) {
        dayMap.set(dateStr, []);
      }
      dayMap.get(dateStr)!.push(item);
    }

    // Convert to array with day numbers
    const timeline: ItineraryDay[] = [];
    const sortedDates = Array.from(dayMap.keys()).sort();

    for (const dateStr of sortedDates) {
      const date = new Date(dateStr);
      const dayNumber = Math.floor(
        (date.getTime() - tripStart.getTime()) / (1000 * 60 * 60 * 24)
      ) + 1;

      timeline.push({
        date: dateStr,
        dayNumber,
        items: dayMap.get(dateStr)!,
      });
    }

    return timeline;
  }

  /**
   * Link itinerary item to a transaction
   */
  async linkToTransaction(itemId: string, transactionId: string) {
    const item = await this.prisma.itineraryItem.findUnique({
      where: { id: itemId },
    });

    if (!item) {
      throw new NotFoundException('Itinerary item not found');
    }

    const transaction = await this.prisma.transaction.findUnique({
      where: { id: transactionId },
    });

    if (!transaction) {
      throw new NotFoundException('Transaction not found');
    }

    // Update both the item and the transaction
    await this.prisma.$transaction([
      this.prisma.itineraryItem.update({
        where: { id: itemId },
        data: { transactionId },
      }),
      this.prisma.transaction.update({
        where: { id: transactionId },
        data: { tripId: item.tripId },
      }),
    ]);

    // Recalculate trip totals
    await this.recalculateTripTotals(item.tripId);

    return this.prisma.itineraryItem.findUnique({
      where: { id: itemId },
      include: { transaction: true },
    });
  }

  /**
   * Attach a document to an itinerary item
   */
  async attachDocument(itemId: string, dto: AttachDocumentDto) {
    const item = await this.prisma.itineraryItem.findUnique({
      where: { id: itemId },
    });

    if (!item) {
      throw new NotFoundException('Itinerary item not found');
    }

    // Get file asset URL
    const fileAsset = await this.prisma.fileAsset.findUnique({
      where: { id: dto.fileAssetId },
    });

    const currentDocs = (item.documents as any[]) || [];
    const newDoc = {
      name: dto.name,
      fileAssetId: dto.fileAssetId,
      url: fileAsset?.url,
    };

    return this.prisma.itineraryItem.update({
      where: { id: itemId },
      data: {
        documents: [...currentDocs, newDoc],
      },
    });
  }

  /**
   * Get all documents for a trip
   */
  async getDocuments(tripId: string, householdId?: string) {
    if (householdId) {
      const trip = await this.prisma.trip.findUnique({
        where: { id: tripId },
      });

      if (!trip || trip.householdId !== householdId) {
        throw new NotFoundException('Trip not found');
      }
    }

    const items = await this.prisma.itineraryItem.findMany({
      where: { tripId },
      select: {
        id: true,
        title: true,
        type: true,
        documents: true,
      },
    });

    return items
      .filter(item => item.documents && (item.documents as any[]).length > 0)
      .flatMap(item =>
        (item.documents as any[]).map(doc => ({
          ...doc,
          itemId: item.id,
          itemTitle: item.title,
          itemType: item.type,
        }))
      );
  }

  /**
   * Recalculate trip totals from itinerary items
   */
  private async recalculateTripTotals(tripId: string) {
    const items = await this.prisma.itineraryItem.findMany({
      where: { tripId },
    });

    const totalEstimatedCost = items.reduce(
      (sum, item) => sum + Number(item.cost),
      0,
    );

    // Get actual cost from linked transactions
    const transactions = await this.prisma.transaction.findMany({
      where: { tripId },
    });

    const totalActualCost = transactions.length > 0
      ? transactions.reduce((sum, t) => sum + Number(t.amount), 0)
      : null;

    await this.prisma.trip.update({
      where: { id: tripId },
      data: {
        totalEstimatedCost,
        totalActualCost,
      },
    });
  }

  /**
   * Mark trip as booked (all items added)
   */
  async markTripAsBooked(tripId: string) {
    return this.prisma.trip.update({
      where: { id: tripId },
      data: { status: TripStatus.BOOKED },
    });
  }
}
