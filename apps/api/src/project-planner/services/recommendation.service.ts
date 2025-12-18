import { Injectable, NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { RecommendationRequestStatus } from '@prisma/client';
import * as h3 from 'h3-js';
import {
  CreateRecommendationRequestDto,
  ListRecommendationRequestsQueryDto,
  RecommendationRequestDto,
  SubmitVendorSuggestionDto,
  VendorSuggestionDto,
  SuggestionFeedbackDto,
} from '../dto';

@Injectable()
export class RecommendationService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Create a "Community Ask" for vendor recommendations
   */
  async createRequest(
    userId: string,
    householdId: string,
    dto: CreateRecommendationRequestDto,
  ): Promise<RecommendationRequestDto> {
    // Verify project idea exists and belongs to household
    const idea = await this.prisma.projectIdea.findUnique({
      where: { id: dto.projectIdeaId },
      include: {
        household: {
          select: { h3Index: true },
        },
        recommendationRequest: true,
      },
    });

    if (!idea) {
      throw new NotFoundException('Project idea not found');
    }

    if (idea.householdId !== householdId) {
      throw new ForbiddenException('Access denied to this project idea');
    }

    if (idea.recommendationRequest) {
      throw new BadRequestException('A recommendation request already exists for this idea');
    }

    const request = await this.prisma.recommendationRequest.create({
      data: {
        projectIdeaId: dto.projectIdeaId,
        householdId,
        createdByUserId: userId,
        title: dto.title,
        description: dto.description,
        budget: dto.budget,
        timeline: dto.timeline,
        h3Index: idea.household.h3Index,
        isPublic: dto.isPublic ?? true,
        expiresAt: dto.expiresAt ? new Date(dto.expiresAt) : null,
        status: 'OPEN',
      },
      include: {
        projectIdea: {
          select: {
            id: true,
            title: true,
            category: true,
            estimatedCostMin: true,
            estimatedCostMax: true,
          },
        },
        createdBy: {
          select: { id: true, displayName: true },
        },
        household: {
          select: { id: true, name: true },
        },
      },
    });

    // Update project idea status to PLANNING if still DREAMING
    if (idea.status === 'DREAMING') {
      await this.prisma.projectIdea.update({
        where: { id: dto.projectIdeaId },
        data: { status: 'PLANNING' },
      });
    }

    return this.mapRequestToDto(request);
  }

  /**
   * List user's recommendation requests
   */
  async listMyRequests(
    householdId: string,
    query: ListRecommendationRequestsQueryDto,
  ): Promise<{ requests: RecommendationRequestDto[]; total: number }> {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const skip = (page - 1) * limit;

    const where = {
      householdId,
      ...(query.status ? { status: query.status } : {}),
    };

    const [requests, total] = await Promise.all([
      this.prisma.recommendationRequest.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          projectIdea: {
            select: {
              id: true,
              title: true,
              category: true,
              estimatedCostMin: true,
              estimatedCostMax: true,
            },
          },
          createdBy: {
            select: { id: true, displayName: true },
          },
          household: {
            select: { id: true, name: true },
          },
        },
      }),
      this.prisma.recommendationRequest.count({ where }),
    ]);

    return {
      requests: requests.map(this.mapRequestToDto),
      total,
    };
  }

  /**
   * Get nearby requests from neighbors (the "Community Asks" feed)
   */
  async getNearbyRequests(
    householdId: string,
    h3Index?: string,
  ): Promise<RecommendationRequestDto[]> {
    let neighborCells: string[] = [];

    if (h3Index) {
      neighborCells = h3.gridDisk(h3Index, 2);
    } else {
      // Get household's H3 index
      const household = await this.prisma.household.findUnique({
        where: { id: householdId },
        select: { h3Index: true },
      });

      if (household?.h3Index) {
        neighborCells = h3.gridDisk(household.h3Index, 2);
      }
    }

    if (neighborCells.length === 0) {
      return [];
    }

    const requests = await this.prisma.recommendationRequest.findMany({
      where: {
        h3Index: { in: neighborCells },
        householdId: { not: householdId },
        isPublic: true,
        status: 'OPEN',
        OR: [
          { expiresAt: null },
          { expiresAt: { gte: new Date() } },
        ],
      },
      orderBy: { createdAt: 'desc' },
      take: 20,
      include: {
        projectIdea: {
          select: {
            id: true,
            title: true,
            category: true,
            estimatedCostMin: true,
            estimatedCostMax: true,
          },
        },
        createdBy: {
          select: { id: true, displayName: true },
        },
        household: {
          select: { id: true, name: true },
        },
      },
    });

    // Increment view counts
    const requestIds = requests.map(r => r.id);
    if (requestIds.length > 0) {
      await this.prisma.recommendationRequest.updateMany({
        where: { id: { in: requestIds } },
        data: { viewCount: { increment: 1 } },
      });
    }

    return requests.map(this.mapRequestToDto);
  }

  /**
   * Submit a vendor suggestion (neighbor recommendation)
   */
  async submitSuggestion(
    userId: string,
    dto: SubmitVendorSuggestionDto,
  ): Promise<VendorSuggestionDto> {
    // Validate that either projectIdeaId or recommendationRequestId is provided
    if (!dto.projectIdeaId && !dto.recommendationRequestId) {
      throw new BadRequestException(
        'Either projectIdeaId or recommendationRequestId must be provided',
      );
    }

    // Verify vendor exists
    const vendor = await this.prisma.vendor.findUnique({
      where: { id: dto.vendorId },
    });

    if (!vendor) {
      throw new NotFoundException('Vendor not found');
    }

    // Check for duplicate suggestion
    const existingSuggestion = await this.prisma.vendorSuggestion.findFirst({
      where: {
        ...(dto.projectIdeaId ? { projectIdeaId: dto.projectIdeaId } : {}),
        ...(dto.recommendationRequestId ? { recommendationRequestId: dto.recommendationRequestId } : {}),
        vendorId: dto.vendorId,
        suggestedByUserId: userId,
      },
    });

    if (existingSuggestion) {
      throw new BadRequestException('You have already suggested this vendor');
    }

    const suggestion = await this.prisma.vendorSuggestion.create({
      data: {
        projectIdeaId: dto.projectIdeaId,
        recommendationRequestId: dto.recommendationRequestId,
        vendorId: dto.vendorId,
        suggestedByUserId: userId,
        comment: dto.comment,
        rating: dto.rating,
        isSystemSuggestion: false,
        referenceProjectPostId: dto.referenceProjectPostId,
      },
      include: {
        vendor: {
          select: {
            id: true,
            displayName: true,
            contactName: true,
            email: true,
            phone: true,
            category: true,
          },
        },
        suggestedBy: {
          select: { id: true, displayName: true },
        },
        referenceProjectPost: {
          select: {
            id: true,
            title: true,
            beforeImages: true,
            afterImages: true,
          },
        },
      },
    });

    // Update suggestion count on recommendation request
    if (dto.recommendationRequestId) {
      await this.prisma.recommendationRequest.update({
        where: { id: dto.recommendationRequestId },
        data: { suggestionCount: { increment: 1 } },
      });
    }

    return this.mapSuggestionToDto(suggestion);
  }

  /**
   * Get all suggestions for a project idea
   */
  async getSuggestionsForIdea(
    projectIdeaId: string,
    householdId: string,
  ): Promise<VendorSuggestionDto[]> {
    // Verify access
    const idea = await this.prisma.projectIdea.findUnique({
      where: { id: projectIdeaId },
    });

    if (!idea) {
      throw new NotFoundException('Project idea not found');
    }

    if (idea.householdId !== householdId) {
      throw new ForbiddenException('Access denied to this project idea');
    }

    const suggestions = await this.prisma.vendorSuggestion.findMany({
      where: { projectIdeaId },
      orderBy: [
        { isSystemSuggestion: 'asc' }, // User suggestions first
        { rating: 'desc' },
        { createdAt: 'desc' },
      ],
      include: {
        vendor: {
          select: {
            id: true,
            displayName: true,
            contactName: true,
            email: true,
            phone: true,
            category: true,
          },
        },
        suggestedBy: {
          select: { id: true, displayName: true },
        },
        referenceProjectPost: {
          select: {
            id: true,
            title: true,
            beforeImages: true,
            afterImages: true,
          },
        },
      },
    });

    return suggestions.map(this.mapSuggestionToDto);
  }

  /**
   * Mark a suggestion as helpful or not
   */
  async submitFeedback(
    suggestionId: string,
    householdId: string,
    dto: SuggestionFeedbackDto,
  ): Promise<void> {
    const suggestion = await this.prisma.vendorSuggestion.findUnique({
      where: { id: suggestionId },
      include: {
        projectIdea: { select: { householdId: true } },
        recommendationRequest: { select: { householdId: true } },
      },
    });

    if (!suggestion) {
      throw new NotFoundException('Suggestion not found');
    }

    // Verify the user owns the project idea or request
    const ownerHouseholdId =
      suggestion.projectIdea?.householdId ??
      suggestion.recommendationRequest?.householdId;

    if (ownerHouseholdId !== householdId) {
      throw new ForbiddenException('Access denied to this suggestion');
    }

    await this.prisma.vendorSuggestion.update({
      where: { id: suggestionId },
      data: { isHelpful: dto.isHelpful },
    });
  }

  /**
   * Update recommendation request status
   */
  async updateRequestStatus(
    requestId: string,
    householdId: string,
    status: RecommendationRequestStatus,
  ): Promise<RecommendationRequestDto> {
    const request = await this.prisma.recommendationRequest.findUnique({
      where: { id: requestId },
    });

    if (!request) {
      throw new NotFoundException('Recommendation request not found');
    }

    if (request.householdId !== householdId) {
      throw new ForbiddenException('Access denied to this request');
    }

    const updated = await this.prisma.recommendationRequest.update({
      where: { id: requestId },
      data: {
        status,
        ...(status === 'CLOSED' ? { closedAt: new Date() } : {}),
      },
      include: {
        projectIdea: {
          select: {
            id: true,
            title: true,
            category: true,
            estimatedCostMin: true,
            estimatedCostMax: true,
          },
        },
        createdBy: {
          select: { id: true, displayName: true },
        },
        household: {
          select: { id: true, name: true },
        },
      },
    });

    return this.mapRequestToDto(updated);
  }

  private mapRequestToDto(request: any): RecommendationRequestDto {
    return {
      id: request.id,
      projectIdeaId: request.projectIdeaId,
      householdId: request.householdId,
      createdByUserId: request.createdByUserId,
      title: request.title,
      description: request.description,
      budget: request.budget,
      timeline: request.timeline,
      h3Index: request.h3Index,
      isPublic: request.isPublic,
      status: request.status,
      viewCount: request.viewCount,
      suggestionCount: request.suggestionCount,
      expiresAt: request.expiresAt,
      closedAt: request.closedAt,
      createdAt: request.createdAt,
      updatedAt: request.updatedAt,
      projectIdea: request.projectIdea
        ? {
            id: request.projectIdea.id,
            title: request.projectIdea.title,
            category: request.projectIdea.category,
            estimatedCostMin: request.projectIdea.estimatedCostMin
              ? Number(request.projectIdea.estimatedCostMin)
              : undefined,
            estimatedCostMax: request.projectIdea.estimatedCostMax
              ? Number(request.projectIdea.estimatedCostMax)
              : undefined,
          }
        : undefined,
      createdBy: request.createdBy,
      household: request.household,
    };
  }

  private mapSuggestionToDto(suggestion: any): VendorSuggestionDto {
    return {
      id: suggestion.id,
      projectIdeaId: suggestion.projectIdeaId,
      recommendationRequestId: suggestion.recommendationRequestId,
      vendorId: suggestion.vendorId,
      suggestedByUserId: suggestion.suggestedByUserId,
      comment: suggestion.comment,
      rating: suggestion.rating,
      isSystemSuggestion: suggestion.isSystemSuggestion,
      systemNote: suggestion.systemNote,
      referenceProjectPostId: suggestion.referenceProjectPostId,
      isHelpful: suggestion.isHelpful,
      createdAt: suggestion.createdAt,
      vendor: suggestion.vendor ? {
        id: suggestion.vendor.id,
        companyName: suggestion.vendor.displayName,
        contactName: suggestion.vendor.contactName,
        email: suggestion.vendor.email,
        phone: suggestion.vendor.phone,
        specialty: suggestion.vendor.category ? [suggestion.vendor.category] : undefined,
      } : undefined,
      suggestedBy: suggestion.suggestedBy,
      referenceProjectPost: suggestion.referenceProjectPost ? {
        id: suggestion.referenceProjectPost.id,
        title: suggestion.referenceProjectPost.title,
        mediaUrls: [
          ...(suggestion.referenceProjectPost.beforeImages || []),
          ...(suggestion.referenceProjectPost.afterImages || []),
        ],
      } : undefined,
    };
  }
}
