import { Injectable, Logger, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CompleteProtocolItemDto, AssignProtocolDto, ProtocolQueryDto, CreateProtocolItemDto } from '../dto';
import { HouseProtocolStatus, ProtocolItemStatus, TripStatus } from '@prisma/client';

interface DefaultProtocolItem {
  title: string;
  description?: string;
  category: string;
  isRequired: boolean;
}

const DEFAULT_PROTOCOL_ITEMS: DefaultProtocolItem[] = [
  {
    title: 'Shut off water main',
    description: 'Locate and turn off the main water valve to prevent leaks',
    category: 'Water',
    isRequired: true,
  },
  {
    title: 'Set thermostat to away mode',
    description: 'Adjust HVAC to energy-saving temperature',
    category: 'HVAC',
    isRequired: true,
  },
  {
    title: 'Set alarm to Away mode',
    description: 'Arm the security system in away/vacation mode',
    category: 'Security',
    isRequired: true,
  },
  {
    title: 'Arrange mail hold',
    description: 'Set up mail hold with USPS or arrange for pickup',
    category: 'Mail',
    isRequired: true,
  },
  {
    title: 'Set light timers',
    description: 'Configure smart lights or timers for security',
    category: 'Lighting',
    isRequired: false,
  },
  {
    title: 'Unplug sensitive electronics',
    description: 'Disconnect TVs, computers, and other electronics',
    category: 'Electrical',
    isRequired: false,
  },
  {
    title: 'Empty perishables from refrigerator',
    description: 'Remove items that may spoil during the trip',
    category: 'Kitchen',
    isRequired: false,
  },
  {
    title: 'Take out trash',
    description: 'Remove all garbage to prevent odors and pests',
    category: 'Kitchen',
    isRequired: true,
  },
];

@Injectable()
export class VacationModeService {
  private readonly logger = new Logger(VacationModeService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Auto-generate protocol from household's home profile
   */
  async generateProtocol(tripId: string) {
    const trip = await this.prisma.trip.findUnique({
      where: { id: tripId },
      include: {
        household: {
          include: {
            homeProfile: true,
            pets: {
              where: { isActive: true },
            },
            homeSystems: {
              where: {
                type: { in: ['POOL', 'SPRINKLER', 'HVAC', 'SECURITY'] },
              },
            },
          },
        },
      },
    });

    if (!trip) {
      throw new NotFoundException('Trip not found');
    }

    // Check if protocol already exists
    const existing = await this.prisma.houseProtocol.findUnique({
      where: { tripId },
    });

    if (existing) {
      throw new BadRequestException('Protocol already exists for this trip');
    }

    // Build items list
    const items: (DefaultProtocolItem & { sortOrder: number })[] = [];
    let sortOrder = 0;

    // Add default items
    for (const item of DEFAULT_PROTOCOL_ITEMS) {
      items.push({ ...item, sortOrder: sortOrder++ });
    }

    // Add items based on home profile
    const homeProfile = trip.household.homeProfile;
    const homeSystems = trip.household.homeSystems;

    // Check for pool
    if (homeSystems.some(s => s.type === 'POOL')) {
      items.push({
        title: 'Arrange pool service coverage',
        description: 'Notify pool service or arrange for maintenance during absence',
        category: 'Pool',
        isRequired: true,
        sortOrder: sortOrder++,
      });
    }

    // Check for sprinkler/garden
    if (homeSystems.some(s => s.type === 'SPRINKLER') || homeProfile?.hasGarden) {
      items.push({
        title: 'Arrange plant/garden watering',
        description: 'Set up irrigation schedule or arrange for plant care',
        category: 'Outdoor',
        isRequired: false,
        sortOrder: sortOrder++,
      });
    }

    // Check for pets
    if (trip.household.pets.length > 0) {
      items.push({
        title: 'Confirm pet care arrangements',
        description: `Verify ${trip.household.pets.map(p => p.name).join(', ')} care is arranged`,
        category: 'Pets',
        isRequired: true,
        sortOrder: sortOrder++,
      });
    }

    // Calculate scheduled date (24h before trip start)
    const scheduledDate = new Date(trip.startDate);
    scheduledDate.setDate(scheduledDate.getDate() - 1);

    // Create protocol with items
    return this.prisma.houseProtocol.create({
      data: {
        tripId,
        householdId: trip.householdId,
        scheduledDate,
        status: HouseProtocolStatus.PENDING,
        items: {
          create: items.map(item => ({
            title: item.title,
            description: item.description,
            category: item.category,
            isRequired: item.isRequired,
            sortOrder: item.sortOrder,
            status: ProtocolItemStatus.PENDING,
          })),
        },
      },
      include: {
        items: {
          orderBy: { sortOrder: 'asc' },
        },
      },
    });
  }

  /**
   * Get protocol for a trip
   */
  async findByTrip(tripId: string, householdId?: string) {
    const protocol = await this.prisma.houseProtocol.findUnique({
      where: { tripId },
      include: {
        trip: {
          select: { id: true, title: true, destination: true, startDate: true, householdId: true },
        },
        household: {
          select: { id: true, name: true },
        },
        assignedTo: {
          select: { id: true, displayName: true },
        },
        items: {
          orderBy: { sortOrder: 'asc' },
          include: {
            completedBy: {
              select: { id: true, displayName: true },
            },
          },
        },
      },
    });

    if (!protocol) {
      throw new NotFoundException('Protocol not found');
    }

    if (householdId && protocol.householdId !== householdId) {
      throw new NotFoundException('Protocol not found');
    }

    return protocol;
  }

  /**
   * Get protocol by ID
   */
  async findOne(id: string) {
    const protocol = await this.prisma.houseProtocol.findUnique({
      where: { id },
      include: {
        trip: {
          select: { id: true, title: true, destination: true, startDate: true },
        },
        household: {
          select: { id: true, name: true },
        },
        assignedTo: {
          select: { id: true, displayName: true },
        },
        items: {
          orderBy: { sortOrder: 'asc' },
          include: {
            completedBy: {
              select: { id: true, displayName: true },
            },
          },
        },
      },
    });

    if (!protocol) {
      throw new NotFoundException('Protocol not found');
    }

    return protocol;
  }

  /**
   * Assign protocol to a manager/handyman
   */
  async assign(id: string, dto: AssignProtocolDto, currentUserId: string) {
    const protocol = await this.prisma.houseProtocol.findUnique({
      where: { id },
    });

    if (!protocol) {
      throw new NotFoundException('Protocol not found');
    }

    const assignedToUserId = dto.assignedToUserId || currentUserId;

    return this.prisma.houseProtocol.update({
      where: { id },
      data: { assignedToUserId },
      include: {
        assignedTo: {
          select: { id: true, displayName: true },
        },
      },
    });
  }

  /**
   * Complete a protocol item with proof
   */
  async completeItem(itemId: string, userId: string, dto: CompleteProtocolItemDto) {
    const item = await this.prisma.houseProtocolItem.findUnique({
      where: { id: itemId },
      include: { protocol: true },
    });

    if (!item) {
      throw new NotFoundException('Protocol item not found');
    }

    // Update item
    const updatedItem = await this.prisma.houseProtocolItem.update({
      where: { id: itemId },
      data: {
        status: ProtocolItemStatus.COMPLETED,
        completedAt: new Date(),
        completedByUserId: userId,
        proofPhotoUrl: dto.proofPhotoUrl,
        proofFileAssetId: dto.proofFileAssetId,
        proofNotes: dto.proofNotes,
      },
    });

    // Check if all required items are complete
    await this.checkProtocolCompletion(item.protocolId);

    return updatedItem;
  }

  /**
   * Skip a protocol item
   */
  async skipItem(itemId: string, userId: string, reason?: string) {
    const item = await this.prisma.houseProtocolItem.findUnique({
      where: { id: itemId },
      include: { protocol: true },
    });

    if (!item) {
      throw new NotFoundException('Protocol item not found');
    }

    if (item.isRequired) {
      throw new BadRequestException('Cannot skip a required item');
    }

    const updatedItem = await this.prisma.houseProtocolItem.update({
      where: { id: itemId },
      data: {
        status: ProtocolItemStatus.SKIPPED,
        completedAt: new Date(),
        completedByUserId: userId,
        proofNotes: reason,
      },
    });

    await this.checkProtocolCompletion(item.protocolId);

    return updatedItem;
  }

  /**
   * Mark item as blocked
   */
  async blockItem(itemId: string, userId: string, reason: string) {
    const item = await this.prisma.houseProtocolItem.findUnique({
      where: { id: itemId },
    });

    if (!item) {
      throw new NotFoundException('Protocol item not found');
    }

    return this.prisma.houseProtocolItem.update({
      where: { id: itemId },
      data: {
        status: ProtocolItemStatus.BLOCKED,
        completedByUserId: userId,
        proofNotes: reason,
      },
    });
  }

  /**
   * Check if protocol is complete and update status
   */
  private async checkProtocolCompletion(protocolId: string) {
    const items = await this.prisma.houseProtocolItem.findMany({
      where: { protocolId },
    });

    const requiredItems = items.filter(i => i.isRequired);
    const completedRequired = requiredItems.filter(
      i => i.status === ProtocolItemStatus.COMPLETED
    );

    // All required items complete
    if (completedRequired.length === requiredItems.length) {
      await this.prisma.houseProtocol.update({
        where: { id: protocolId },
        data: {
          status: HouseProtocolStatus.COMPLETED,
          completedAt: new Date(),
        },
      });
    }
  }

  /**
   * Verify protocol (homeowner confirms)
   */
  async verify(protocolId: string, userId: string) {
    const protocol = await this.prisma.houseProtocol.findUnique({
      where: { id: protocolId },
    });

    if (!protocol) {
      throw new NotFoundException('Protocol not found');
    }

    if (protocol.status !== HouseProtocolStatus.COMPLETED) {
      throw new BadRequestException('Protocol must be completed before verification');
    }

    return this.prisma.houseProtocol.update({
      where: { id: protocolId },
      data: {
        status: HouseProtocolStatus.VERIFIED,
        verifiedAt: new Date(),
        verifiedByUserId: userId,
      },
    });
  }

  /**
   * Get pending protocols (for manager view)
   */
  async getPendingProtocols(query?: ProtocolQueryDto) {
    const where: any = {};

    if (query?.status && query.status.length > 0) {
      where.status = { in: query.status };
    } else {
      where.status = { in: [HouseProtocolStatus.PENDING, HouseProtocolStatus.IN_PROGRESS] };
    }

    if (query?.scheduledBefore) {
      where.scheduledDate = { ...where.scheduledDate, lte: query.scheduledBefore };
    }

    if (query?.scheduledAfter) {
      where.scheduledDate = { ...where.scheduledDate, gte: query.scheduledAfter };
    }

    return this.prisma.houseProtocol.findMany({
      where,
      include: {
        trip: {
          select: { id: true, title: true, destination: true, startDate: true },
        },
        household: {
          select: { id: true, name: true },
        },
        assignedTo: {
          select: { id: true, displayName: true },
        },
        _count: {
          select: { items: true },
        },
      },
      orderBy: { scheduledDate: 'asc' },
    });
  }

  /**
   * Start a protocol (marks as in progress)
   */
  async startProtocol(id: string) {
    const protocol = await this.prisma.houseProtocol.findUnique({
      where: { id },
    });

    if (!protocol) {
      throw new NotFoundException('Protocol not found');
    }

    return this.prisma.houseProtocol.update({
      where: { id },
      data: { status: HouseProtocolStatus.IN_PROGRESS },
    });
  }

  /**
   * Add custom item to protocol
   */
  async addItem(protocolId: string, dto: CreateProtocolItemDto) {
    const protocol = await this.prisma.houseProtocol.findUnique({
      where: { id: protocolId },
    });

    if (!protocol) {
      throw new NotFoundException('Protocol not found');
    }

    // Get next sort order
    const lastItem = await this.prisma.houseProtocolItem.findFirst({
      where: { protocolId },
      orderBy: { sortOrder: 'desc' },
    });

    const sortOrder = dto.sortOrder ?? (lastItem?.sortOrder ?? 0) + 1;

    return this.prisma.houseProtocolItem.create({
      data: {
        protocolId,
        title: dto.title,
        description: dto.description,
        category: dto.category,
        sortOrder,
        isRequired: dto.isRequired ?? false,
        status: ProtocolItemStatus.PENDING,
      },
    });
  }

  /**
   * Get protocol completion percentage
   */
  async getCompletionPercentage(protocolId: string): Promise<number> {
    const items = await this.prisma.houseProtocolItem.findMany({
      where: { protocolId },
    });

    if (items.length === 0) return 100;

    const completedCount = items.filter(
      i => i.status === ProtocolItemStatus.COMPLETED || i.status === ProtocolItemStatus.SKIPPED
    ).length;

    return Math.round((completedCount / items.length) * 100);
  }

  /**
   * Auto-activate trips that have started
   */
  async activateDepartedTrips() {
    const now = new Date();

    const trips = await this.prisma.trip.findMany({
      where: {
        status: TripStatus.BOOKED,
        startDate: { lte: now },
      },
    });

    for (const trip of trips) {
      await this.prisma.trip.update({
        where: { id: trip.id },
        data: { status: TripStatus.ACTIVE },
      });

      this.logger.log(`Activated trip ${trip.id} - ${trip.title}`);
    }

    return trips.length;
  }

  /**
   * Auto-complete trips that have ended
   */
  async completeEndedTrips() {
    const now = new Date();

    const trips = await this.prisma.trip.findMany({
      where: {
        status: TripStatus.ACTIVE,
        endDate: { lt: now },
      },
    });

    for (const trip of trips) {
      await this.prisma.trip.update({
        where: { id: trip.id },
        data: { status: TripStatus.COMPLETED },
      });

      this.logger.log(`Completed trip ${trip.id} - ${trip.title}`);
    }

    return trips.length;
  }
}
