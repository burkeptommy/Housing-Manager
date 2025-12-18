import { Injectable, Logger, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateProposalDto, UpdateProposalDto, SelectProposalOptionDto } from '../dto';
import { TripStatus } from '@prisma/client';

@Injectable()
export class ProposalService {
  private readonly logger = new Logger(ProposalService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Create a proposal (manager)
   */
  async create(tripId: string, managerId: string, dto: CreateProposalDto) {
    // Verify trip exists
    const trip = await this.prisma.trip.findUnique({
      where: { id: tripId },
    });

    if (!trip) {
      throw new NotFoundException('Trip not found');
    }

    return this.prisma.tripProposal.create({
      data: {
        tripId,
        createdByManagerId: managerId,
        title: dto.title,
        category: dto.category,
        description: dto.description,
        options: dto.options,
        expiresAt: dto.expiresAt,
      },
      include: {
        trip: {
          select: { id: true, title: true, householdId: true },
        },
        createdByManager: {
          select: { id: true, displayName: true },
        },
      },
    });
  }

  /**
   * Update a proposal
   */
  async update(id: string, dto: UpdateProposalDto) {
    const proposal = await this.prisma.tripProposal.findUnique({
      where: { id },
    });

    if (!proposal) {
      throw new NotFoundException('Proposal not found');
    }

    if (proposal.selectedOptionIndex !== null) {
      throw new BadRequestException('Cannot update a proposal after selection');
    }

    return this.prisma.tripProposal.update({
      where: { id },
      data: {
        title: dto.title,
        category: dto.category,
        description: dto.description,
        options: dto.options,
        expiresAt: dto.expiresAt,
      },
    });
  }

  /**
   * Send proposal to user (marks as sent)
   */
  async send(id: string) {
    const proposal = await this.prisma.tripProposal.findUnique({
      where: { id },
      include: {
        trip: true,
      },
    });

    if (!proposal) {
      throw new NotFoundException('Proposal not found');
    }

    // Update proposal as sent
    const updatedProposal = await this.prisma.tripProposal.update({
      where: { id },
      data: { sentAt: new Date() },
    });

    // Update trip status if first proposal
    const proposalCount = await this.prisma.tripProposal.count({
      where: {
        tripId: proposal.tripId,
        sentAt: { not: null },
      },
    });

    if (proposalCount === 1) {
      await this.prisma.trip.update({
        where: { id: proposal.tripId },
        data: { status: TripStatus.PROPOSAL_SENT },
      });
    }

    // TODO: Send notification to user

    return updatedProposal;
  }

  /**
   * User selects an option
   */
  async selectOption(id: string, userId: string, dto: SelectProposalOptionDto) {
    const proposal = await this.prisma.tripProposal.findUnique({
      where: { id },
      include: {
        trip: true,
      },
    });

    if (!proposal) {
      throw new NotFoundException('Proposal not found');
    }

    if (proposal.selectedOptionIndex !== null) {
      throw new BadRequestException('An option has already been selected');
    }

    const options = proposal.options as any[];
    if (dto.optionIndex >= options.length) {
      throw new BadRequestException('Invalid option index');
    }

    // Check if proposal has expired
    if (proposal.expiresAt && new Date() > proposal.expiresAt) {
      throw new BadRequestException('This proposal has expired');
    }

    const updatedProposal = await this.prisma.tripProposal.update({
      where: { id },
      data: {
        selectedOptionIndex: dto.optionIndex,
        selectedAt: new Date(),
      },
    });

    // Check if all proposals have been responded to
    const pendingProposals = await this.prisma.tripProposal.count({
      where: {
        tripId: proposal.tripId,
        sentAt: { not: null },
        selectedOptionIndex: null,
      },
    });

    // If no more pending proposals, update trip status
    if (pendingProposals === 0) {
      await this.prisma.trip.update({
        where: { id: proposal.tripId },
        data: { status: TripStatus.PENDING_SELECTION },
      });
    }

    return updatedProposal;
  }

  /**
   * Get proposals for a trip
   */
  async findByTrip(tripId: string, householdId?: string) {
    // Verify household access if provided
    if (householdId) {
      const trip = await this.prisma.trip.findUnique({
        where: { id: tripId },
      });

      if (!trip || trip.householdId !== householdId) {
        throw new NotFoundException('Trip not found');
      }
    }

    return this.prisma.tripProposal.findMany({
      where: { tripId },
      include: {
        createdByManager: {
          select: { id: true, displayName: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  /**
   * Get a single proposal
   */
  async findOne(id: string, householdId?: string) {
    const proposal = await this.prisma.tripProposal.findUnique({
      where: { id },
      include: {
        trip: {
          select: { id: true, title: true, householdId: true },
        },
        createdByManager: {
          select: { id: true, displayName: true },
        },
      },
    });

    if (!proposal) {
      throw new NotFoundException('Proposal not found');
    }

    if (householdId && proposal.trip.householdId !== householdId) {
      throw new NotFoundException('Proposal not found');
    }

    return proposal;
  }

  /**
   * Get pending proposals for a household (needing response)
   */
  async getPendingProposals(householdId: string) {
    return this.prisma.tripProposal.findMany({
      where: {
        trip: { householdId },
        sentAt: { not: null },
        selectedOptionIndex: null,
      },
      include: {
        trip: {
          select: { id: true, title: true, destination: true },
        },
        createdByManager: {
          select: { id: true, displayName: true },
        },
      },
      orderBy: { sentAt: 'desc' },
    });
  }

  /**
   * Delete a proposal (only if not sent)
   */
  async remove(id: string) {
    const proposal = await this.prisma.tripProposal.findUnique({
      where: { id },
    });

    if (!proposal) {
      throw new NotFoundException('Proposal not found');
    }

    if (proposal.sentAt) {
      throw new BadRequestException('Cannot delete a sent proposal');
    }

    return this.prisma.tripProposal.delete({
      where: { id },
    });
  }
}
