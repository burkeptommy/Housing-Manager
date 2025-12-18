import { Injectable, NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { ProjectIdeaStatus, ProjectCategory } from '@prisma/client';
import {
  CreateProjectIdeaDto,
  UpdateProjectIdeaDto,
  ListProjectIdeasQueryDto,
  ProjectIdeaDto,
  ConvertToWorkOrderDto,
} from '../dto';

@Injectable()
export class ProjectIdeaService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Create a new project idea
   */
  async create(
    userId: string,
    householdId: string,
    dto: CreateProjectIdeaDto,
  ): Promise<ProjectIdeaDto> {
    const idea = await this.prisma.projectIdea.create({
      data: {
        householdId,
        createdByUserId: userId,
        templateId: dto.templateId,
        title: dto.title,
        category: dto.category,
        description: dto.description,
        specs: dto.specs as any,
        style: dto.style,
        vibeNotes: dto.vibeNotes,
        moodBoardImages: dto.moodBoardImages ?? [],
        estimatedCostMin: dto.estimatedCostMin,
        estimatedCostMax: dto.estimatedCostMax,
        neighborProjectCount: dto.neighborProjectCount ?? 0,
        socialProofNote: dto.socialProofNote,
        targetStartDate: dto.targetStartDate ? new Date(dto.targetStartDate) : null,
        targetCompletionDate: dto.targetCompletionDate ? new Date(dto.targetCompletionDate) : null,
        urgency: dto.urgency,
        status: 'DREAMING',
      },
      include: {
        template: {
          select: { id: true, name: true, slug: true },
        },
        createdBy: {
          select: { id: true, displayName: true },
        },
      },
    });

    return this.mapToDto(idea);
  }

  /**
   * List project ideas for a household
   */
  async list(
    householdId: string,
    query: ListProjectIdeasQueryDto,
  ): Promise<{ ideas: ProjectIdeaDto[]; total: number }> {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const skip = (page - 1) * limit;

    const where = {
      householdId,
      ...(query.status ? { status: query.status } : {}),
      ...(query.category ? { category: query.category } : {}),
    };

    const [ideas, total] = await Promise.all([
      this.prisma.projectIdea.findMany({
        where,
        skip,
        take: limit,
        orderBy: [
          { status: 'asc' },
          { updatedAt: 'desc' },
        ],
        include: {
          template: {
            select: { id: true, name: true, slug: true },
          },
          createdBy: {
            select: { id: true, displayName: true },
          },
        },
      }),
      this.prisma.projectIdea.count({ where }),
    ]);

    return {
      ideas: ideas.map(this.mapToDto),
      total,
    };
  }

  /**
   * Get a single project idea by ID
   */
  async getById(id: string, householdId: string): Promise<ProjectIdeaDto> {
    const idea = await this.prisma.projectIdea.findUnique({
      where: { id },
      include: {
        template: {
          select: { id: true, name: true, slug: true },
        },
        createdBy: {
          select: { id: true, displayName: true },
        },
        recommendationRequest: true,
        vendorSuggestions: {
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
          },
        },
      },
    });

    if (!idea) {
      throw new NotFoundException('Project idea not found');
    }

    if (idea.householdId !== householdId) {
      throw new ForbiddenException('Access denied to this project idea');
    }

    return this.mapToDto(idea);
  }

  /**
   * Update a project idea
   */
  async update(
    id: string,
    householdId: string,
    dto: UpdateProjectIdeaDto,
  ): Promise<ProjectIdeaDto> {
    const idea = await this.prisma.projectIdea.findUnique({
      where: { id },
    });

    if (!idea) {
      throw new NotFoundException('Project idea not found');
    }

    if (idea.householdId !== householdId) {
      throw new ForbiddenException('Access denied to this project idea');
    }

    const updated = await this.prisma.projectIdea.update({
      where: { id },
      data: {
        ...(dto.templateId !== undefined && { templateId: dto.templateId }),
        ...(dto.title !== undefined && { title: dto.title }),
        ...(dto.category !== undefined && { category: dto.category }),
        ...(dto.description !== undefined && { description: dto.description }),
        ...(dto.specs !== undefined && { specs: dto.specs as any }),
        ...(dto.style !== undefined && { style: dto.style }),
        ...(dto.vibeNotes !== undefined && { vibeNotes: dto.vibeNotes }),
        ...(dto.moodBoardImages !== undefined && { moodBoardImages: dto.moodBoardImages }),
        ...(dto.estimatedCostMin !== undefined && { estimatedCostMin: dto.estimatedCostMin }),
        ...(dto.estimatedCostMax !== undefined && { estimatedCostMax: dto.estimatedCostMax }),
        ...(dto.neighborProjectCount !== undefined && { neighborProjectCount: dto.neighborProjectCount }),
        ...(dto.socialProofNote !== undefined && { socialProofNote: dto.socialProofNote }),
        ...(dto.targetStartDate !== undefined && {
          targetStartDate: dto.targetStartDate ? new Date(dto.targetStartDate) : null,
        }),
        ...(dto.targetCompletionDate !== undefined && {
          targetCompletionDate: dto.targetCompletionDate ? new Date(dto.targetCompletionDate) : null,
        }),
        ...(dto.urgency !== undefined && { urgency: dto.urgency }),
      },
      include: {
        template: {
          select: { id: true, name: true, slug: true },
        },
        createdBy: {
          select: { id: true, displayName: true },
        },
      },
    });

    return this.mapToDto(updated);
  }

  /**
   * Progress a project idea to the next status
   */
  async progressStatus(
    id: string,
    householdId: string,
    newStatus: ProjectIdeaStatus,
  ): Promise<ProjectIdeaDto> {
    const idea = await this.prisma.projectIdea.findUnique({
      where: { id },
    });

    if (!idea) {
      throw new NotFoundException('Project idea not found');
    }

    if (idea.householdId !== householdId) {
      throw new ForbiddenException('Access denied to this project idea');
    }

    // Validate status transitions
    const validTransitions: Record<ProjectIdeaStatus, ProjectIdeaStatus[]> = {
      DREAMING: ['PLANNING', 'ARCHIVED'],
      PLANNING: ['ACTIVE', 'DREAMING', 'ARCHIVED'],
      ACTIVE: ['COMPLETED', 'PLANNING', 'ARCHIVED'],
      COMPLETED: ['ARCHIVED'],
      ARCHIVED: ['DREAMING'],
    };

    if (!validTransitions[idea.status]?.includes(newStatus)) {
      throw new BadRequestException(
        `Cannot transition from ${idea.status} to ${newStatus}`,
      );
    }

    const updated = await this.prisma.projectIdea.update({
      where: { id },
      data: { status: newStatus },
      include: {
        template: {
          select: { id: true, name: true, slug: true },
        },
        createdBy: {
          select: { id: true, displayName: true },
        },
      },
    });

    return this.mapToDto(updated);
  }

  /**
   * Convert a project idea to a work order
   */
  async convertToWorkOrder(
    id: string,
    householdId: string,
    dto: ConvertToWorkOrderDto,
  ): Promise<{ ideaId: string; workOrderId: string }> {
    const idea = await this.prisma.projectIdea.findUnique({
      where: { id },
      include: { template: true },
    });

    if (!idea) {
      throw new NotFoundException('Project idea not found');
    }

    if (idea.householdId !== householdId) {
      throw new ForbiddenException('Access denied to this project idea');
    }

    if (idea.workOrderId) {
      throw new BadRequestException('This idea has already been converted to a work order');
    }

    // Get the creating user's ID
    const member = await this.prisma.householdMember.findFirst({
      where: { householdId, status: 'ACTIVE' },
      select: { userId: true },
    });

    if (!member) {
      throw new BadRequestException('No active household member found');
    }

    // Create work order
    const workOrder = await this.prisma.workOrder.create({
      data: {
        householdId,
        createdByUserId: member.userId,
        title: dto.title ?? idea.title,
        description: dto.description ?? idea.description ?? `Project from idea: ${idea.title}`,
        status: 'DRAFT',
        estimatedCost: idea.estimatedCostMax,
        ...(dto.vendorId && { vendorId: dto.vendorId }),
      },
    });

    // Update idea with work order link and status
    await this.prisma.projectIdea.update({
      where: { id },
      data: {
        workOrderId: workOrder.id,
        status: 'ACTIVE',
      },
    });

    return {
      ideaId: id,
      workOrderId: workOrder.id,
    };
  }

  /**
   * Archive (soft delete) a project idea
   */
  async archive(id: string, householdId: string): Promise<void> {
    const idea = await this.prisma.projectIdea.findUnique({
      where: { id },
    });

    if (!idea) {
      throw new NotFoundException('Project idea not found');
    }

    if (idea.householdId !== householdId) {
      throw new ForbiddenException('Access denied to this project idea');
    }

    await this.prisma.projectIdea.update({
      where: { id },
      data: { status: 'ARCHIVED' },
    });
  }

  /**
   * Get pipeline stats for a household
   */
  async getPipelineStats(householdId: string): Promise<Record<ProjectIdeaStatus, number>> {
    const counts = await this.prisma.projectIdea.groupBy({
      by: ['status'],
      where: { householdId },
      _count: { status: true },
    });

    const stats: Record<ProjectIdeaStatus, number> = {
      DREAMING: 0,
      PLANNING: 0,
      ACTIVE: 0,
      COMPLETED: 0,
      ARCHIVED: 0,
    };

    for (const count of counts) {
      stats[count.status] = count._count.status;
    }

    return stats;
  }

  private mapCategoryToWorkOrderType(category: ProjectCategory): string {
    const mapping: Partial<Record<ProjectCategory, string>> = {
      BATHROOM_REMODEL: 'RENOVATION',
      KITCHEN_REMODEL: 'RENOVATION',
      DECK_PATIO: 'RENOVATION',
      LANDSCAPING: 'LANDSCAPING',
      ROOF: 'REPAIR',
      WINDOWS_DOORS: 'REPAIR',
      FLOORING: 'RENOVATION',
      PAINTING: 'COSMETIC',
      HVAC: 'REPAIR',
      ELECTRICAL: 'REPAIR',
      PLUMBING: 'REPAIR',
      ADDITION: 'RENOVATION',
      BASEMENT: 'RENOVATION',
      GARAGE: 'RENOVATION',
      FENCE: 'RENOVATION',
      POOL: 'RENOVATION',
      SOLAR: 'UPGRADE',
      SMART_HOME: 'UPGRADE',
      EXTERIOR_SIDING: 'REPAIR',
      OTHER: 'OTHER',
    };
    return mapping[category] ?? 'OTHER';
  }

  private mapToDto(idea: any): ProjectIdeaDto {
    return {
      id: idea.id,
      householdId: idea.householdId,
      createdByUserId: idea.createdByUserId,
      templateId: idea.templateId,
      title: idea.title,
      category: idea.category,
      description: idea.description,
      specs: idea.specs as Record<string, unknown> | undefined,
      style: idea.style,
      vibeNotes: idea.vibeNotes,
      moodBoardImages: idea.moodBoardImages,
      estimatedCostMin: idea.estimatedCostMin ? Number(idea.estimatedCostMin) : undefined,
      estimatedCostMax: idea.estimatedCostMax ? Number(idea.estimatedCostMax) : undefined,
      neighborProjectCount: idea.neighborProjectCount,
      socialProofNote: idea.socialProofNote,
      status: idea.status,
      targetStartDate: idea.targetStartDate,
      targetCompletionDate: idea.targetCompletionDate,
      urgency: idea.urgency,
      workOrderId: idea.workOrderId,
      projectPostId: idea.projectPostId,
      createdAt: idea.createdAt,
      updatedAt: idea.updatedAt,
      template: idea.template,
      createdBy: idea.createdBy,
    };
  }
}
