import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import {
  MaintenanceCategory,
  MaintenanceTaskStatus,
  TaskPriority,
  VendorCategory,
  Prisma,
} from '@prisma/client';

import { PrismaService } from '../prisma';

import {
  CreateMaintenanceTaskDto,
  UpdateMaintenanceTaskDto,
  GenerateFromTemplatesDto,
  MaintenanceTaskResponseDto,
  MaintenanceTemplateResponseDto,
} from './dto';

@Injectable()
export class MaintenanceTasksService {
  constructor(private readonly prisma: PrismaService) {}

  async create(
    userId: string,
    dto: CreateMaintenanceTaskDto,
  ): Promise<MaintenanceTaskResponseDto> {
    // Verify user has access to this household
    await this.verifyHouseholdAccess(dto.householdId, userId);

    // Verify vendor if provided
    if (dto.assignedVendorId) {
      const vendor = await this.prisma.vendor.findFirst({
        where: {
          id: dto.assignedVendorId,
          OR: [
            { householdId: dto.householdId },
            { householdId: null },
          ],
        },
      });

      if (!vendor) {
        throw new BadRequestException('Vendor not found or not accessible');
      }
    }

    // If creating from template, get template data
    let templateData: {
      category: MaintenanceCategory;
      description: string | null;
      estimatedCostMin: Prisma.Decimal | null;
    } | null = null;

    if (dto.templateId) {
      const template = await this.prisma.maintenanceTemplate.findUnique({
        where: { id: dto.templateId },
      });

      if (!template) {
        throw new BadRequestException('Template not found');
      }

      templateData = {
        category: template.category,
        description: template.description,
        estimatedCostMin: template.estimatedCostMin,
      };
    }

    const task = await this.prisma.maintenanceTask.create({
      data: {
        householdId: dto.householdId,
        templateId: dto.templateId,
        assignedVendorId: dto.assignedVendorId,
        title: dto.title,
        description: dto.description ?? templateData?.description,
        category: dto.category ?? templateData?.category ?? MaintenanceCategory.GENERAL,
        status: MaintenanceTaskStatus.PENDING,
        dueDate: dto.dueDate ? new Date(dto.dueDate) : null,
        scheduledDate: dto.scheduledDate ? new Date(dto.scheduledDate) : null,
        estimatedCost: dto.estimatedCost ?? (templateData?.estimatedCostMin ? Number(templateData.estimatedCostMin) : null),
        priority: dto.priority ?? TaskPriority.MEDIUM,
        notes: dto.notes,
        createdFromTemplate: !!dto.templateId,
      },
      include: {
        template: true,
        assignedVendor: true,
      },
    });

    return this.mapToResponse(task);
  }

  async findAll(
    userId: string,
    options: {
      householdId: string;
      category?: MaintenanceCategory;
      status?: MaintenanceTaskStatus;
      dueDateFrom?: string;
      dueDateTo?: string;
      includeCompleted?: boolean;
    },
  ): Promise<MaintenanceTaskResponseDto[]> {
    // Verify user has access to this household
    await this.verifyHouseholdAccess(options.householdId, userId);

    const where: Prisma.MaintenanceTaskWhereInput = {
      householdId: options.householdId,
      ...(options.category && { category: options.category }),
      ...(options.status && { status: options.status }),
    };

    // Filter by status unless includeCompleted
    if (!options.includeCompleted && !options.status) {
      where.status = {
        notIn: [MaintenanceTaskStatus.COMPLETED, MaintenanceTaskStatus.SKIPPED],
      };
    }

    // Filter by due date range
    if (options.dueDateFrom || options.dueDateTo) {
      where.dueDate = {};
      if (options.dueDateFrom) {
        where.dueDate.gte = new Date(options.dueDateFrom);
      }
      if (options.dueDateTo) {
        where.dueDate.lte = new Date(options.dueDateTo);
      }
    }

    const tasks = await this.prisma.maintenanceTask.findMany({
      where,
      include: {
        template: true,
        assignedVendor: true,
      },
      orderBy: [
        { dueDate: 'asc' },
        { priority: 'desc' },
        { createdAt: 'desc' },
      ],
    });

    return tasks.map(this.mapToResponse);
  }

  async findOne(
    id: string,
    userId: string,
  ): Promise<MaintenanceTaskResponseDto> {
    const task = await this.prisma.maintenanceTask.findUnique({
      where: { id },
      include: {
        template: true,
        assignedVendor: true,
      },
    });

    if (!task) {
      throw new NotFoundException(`Maintenance task with ID ${id} not found`);
    }

    // Verify user has access to this household
    await this.verifyHouseholdAccess(task.householdId, userId);

    return this.mapToResponse(task);
  }

  async update(
    id: string,
    userId: string,
    dto: UpdateMaintenanceTaskDto,
  ): Promise<MaintenanceTaskResponseDto> {
    const existing = await this.prisma.maintenanceTask.findUnique({
      where: { id },
    });

    if (!existing) {
      throw new NotFoundException(`Maintenance task with ID ${id} not found`);
    }

    // Verify user has access to this household
    await this.verifyHouseholdAccess(existing.householdId, userId);

    // Verify vendor if changing
    if (dto.assignedVendorId) {
      const vendor = await this.prisma.vendor.findFirst({
        where: {
          id: dto.assignedVendorId,
          OR: [
            { householdId: existing.householdId },
            { householdId: null },
          ],
        },
      });

      if (!vendor) {
        throw new BadRequestException('Vendor not found or not accessible');
      }
    }

    // Set completedAt if status is being changed to COMPLETED
    const completedAt = dto.status === MaintenanceTaskStatus.COMPLETED && existing.status !== MaintenanceTaskStatus.COMPLETED
      ? new Date()
      : undefined;

    const task = await this.prisma.maintenanceTask.update({
      where: { id },
      data: {
        ...(dto.title !== undefined && { title: dto.title }),
        ...(dto.description !== undefined && { description: dto.description }),
        ...(dto.category !== undefined && { category: dto.category }),
        ...(dto.status !== undefined && { status: dto.status }),
        ...(dto.dueDate !== undefined && { dueDate: dto.dueDate ? new Date(dto.dueDate) : null }),
        ...(dto.scheduledDate !== undefined && { scheduledDate: dto.scheduledDate ? new Date(dto.scheduledDate) : null }),
        ...(dto.assignedVendorId !== undefined && { assignedVendorId: dto.assignedVendorId }),
        ...(dto.estimatedCost !== undefined && { estimatedCost: dto.estimatedCost }),
        ...(dto.actualCost !== undefined && { actualCost: dto.actualCost }),
        ...(dto.priority !== undefined && { priority: dto.priority }),
        ...(dto.notes !== undefined && { notes: dto.notes }),
        ...(completedAt && { completedAt }),
      },
      include: {
        template: true,
        assignedVendor: true,
      },
    });

    return this.mapToResponse(task);
  }

  async remove(id: string, userId: string): Promise<void> {
    const existing = await this.prisma.maintenanceTask.findUnique({
      where: { id },
    });

    if (!existing) {
      throw new NotFoundException(`Maintenance task with ID ${id} not found`);
    }

    // Verify user has access to this household
    await this.verifyHouseholdAccess(existing.householdId, userId);

    await this.prisma.maintenanceTask.delete({
      where: { id },
    });
  }

  async generateFromTemplates(
    userId: string,
    dto: GenerateFromTemplatesDto,
  ): Promise<MaintenanceTaskResponseDto[]> {
    // Verify user has access to this household
    await this.verifyHouseholdAccess(dto.householdId, userId);

    // Get all active templates
    const templates = await this.prisma.maintenanceTemplate.findMany({
      where: { isActive: true },
      orderBy: { sortOrder: 'asc' },
    });

    // Get property features from homeProfile if not provided
    const propertyFeatures = dto.propertyFeatures ?? {};

    // Get homeProfile for additional context
    const homeProfile = await this.prisma.homeProfile.findFirst({
      where: {
        household: {
          id: dto.householdId,
        },
      },
    });

    // Merge property features from homeProfile.notes (if it contains JSON)
    if (homeProfile?.notes) {
      try {
        const notesData = JSON.parse(homeProfile.notes);
        if (notesData.systems) {
          Object.assign(propertyFeatures, {
            has_pool: notesData.systems.hasPool ?? false,
            has_septic: notesData.systems.septicOrSewer === 'septic',
            has_sprinkler_system: notesData.systems.hasSprinklerSystem ?? false,
            has_security_system: notesData.systems.hasSecuritySystem ?? false,
            has_smart_home: notesData.systems.hasSmartHome ?? false,
          });
        }
      } catch {
        // Notes is not JSON, ignore
      }
    }

    // Check for existing tasks from templates to avoid duplicates
    const existingTasks = await this.prisma.maintenanceTask.findMany({
      where: {
        householdId: dto.householdId,
        templateId: { not: null },
        status: {
          in: [MaintenanceTaskStatus.PENDING, MaintenanceTaskStatus.SCHEDULED],
        },
      },
      select: { templateId: true },
    });

    const existingTemplateIds = new Set(existingTasks.map(t => t.templateId));

    // Filter templates based on property conditions and existing tasks
    const applicableTemplates = templates.filter(template => {
      // Skip if already has a pending/scheduled task for this template
      if (existingTemplateIds.has(template.id)) {
        return false;
      }

      // Check property conditions
      if (template.propertyConditionsJson) {
        const conditions = template.propertyConditionsJson as Record<string, unknown>;

        for (const [key, requiredValue] of Object.entries(conditions)) {
          const actualValue = propertyFeatures[key];

          if (typeof requiredValue === 'boolean') {
            if (actualValue !== requiredValue) {
              return false;
            }
          } else if (requiredValue !== undefined && actualValue !== requiredValue) {
            return false;
          }
        }
      }

      return true;
    });

    // Generate tasks from applicable templates
    const now = new Date();
    const createdTasks: MaintenanceTaskResponseDto[] = [];

    for (const template of applicableTemplates) {
      // Calculate due date based on template's recommended schedule
      let dueDate: Date | null = null;

      if (template.recommendedSeasonStartMonth) {
        // Use recommended season
        dueDate = new Date(now.getFullYear(), template.recommendedSeasonStartMonth - 1, 15);

        // If the season start has passed this year, schedule for next year
        if (dueDate < now) {
          dueDate = new Date(now.getFullYear() + 1, template.recommendedSeasonStartMonth - 1, 15);
        }
      } else if (template.recommendedFrequencyMonths) {
        // Calculate based on frequency
        dueDate = new Date(now);
        dueDate.setMonth(dueDate.getMonth() + Math.ceil(template.recommendedFrequencyMonths / 2));
      } else {
        // Default to 30 days from now
        dueDate = new Date(now);
        dueDate.setDate(dueDate.getDate() + 30);
      }

      const task = await this.prisma.maintenanceTask.create({
        data: {
          householdId: dto.householdId,
          templateId: template.id,
          title: template.title,
          description: template.description,
          category: template.category,
          status: MaintenanceTaskStatus.PENDING,
          dueDate,
          estimatedCost: template.estimatedCostMin ? Number(template.estimatedCostMin) : null,
          priority: TaskPriority.MEDIUM,
          createdFromTemplate: true,
        },
        include: {
          template: true,
          assignedVendor: true,
        },
      });

      createdTasks.push(this.mapToResponse(task));
    }

    return createdTasks;
  }

  async getTemplates(): Promise<MaintenanceTemplateResponseDto[]> {
    const templates = await this.prisma.maintenanceTemplate.findMany({
      where: { isActive: true },
      orderBy: [
        { category: 'asc' },
        { sortOrder: 'asc' },
      ],
    });

    return templates.map(t => ({
      id: t.id,
      slug: t.slug,
      title: t.title,
      description: t.description,
      category: t.category,
      recommendedFrequencyMonths: t.recommendedFrequencyMonths,
      recommendedSeasonStartMonth: t.recommendedSeasonStartMonth,
      recommendedSeasonEndMonth: t.recommendedSeasonEndMonth,
      propertyConditionsJson: t.propertyConditionsJson as Record<string, unknown> | null,
      defaultVendorCategory: t.defaultVendorCategory,
      estimatedCostMin: t.estimatedCostMin ? Number(t.estimatedCostMin) : null,
      estimatedCostMax: t.estimatedCostMax ? Number(t.estimatedCostMax) : null,
      isActive: t.isActive,
      sortOrder: t.sortOrder,
    }));
  }

  private async verifyHouseholdAccess(
    householdId: string,
    userId: string,
  ): Promise<void> {
    const membership = await this.prisma.householdMember.findUnique({
      where: {
        householdId_userId: {
          householdId,
          userId,
        },
      },
    });

    if (!membership || membership.status !== 'ACTIVE') {
      throw new ForbiddenException('You do not have access to this household');
    }
  }

  private mapToResponse(task: {
    id: string;
    householdId: string;
    templateId: string | null;
    assignedVendorId: string | null;
    title: string;
    description: string | null;
    category: MaintenanceCategory;
    status: MaintenanceTaskStatus;
    dueDate: Date | null;
    nextDueDate?: Date | null;
    scheduledDate: Date | null;
    completedAt: Date | null;
    estimatedCost: Prisma.Decimal | null;
    actualCost: Prisma.Decimal | null;
    createdFromTemplate: boolean;
    notes: string | null;
    priority: TaskPriority;
    createdAt: Date;
    updatedAt: Date;
    checklistSteps?: Prisma.JsonValue | null;
    template?: {
      id: string;
      slug: string;
      title: string;
    } | null;
    assignedVendor?: {
      id: string;
      displayName: string;
      category: VendorCategory;
    } | null;
  }): MaintenanceTaskResponseDto {
    return {
      id: task.id,
      householdId: task.householdId,
      templateId: task.templateId,
      assignedVendorId: task.assignedVendorId,
      title: task.title,
      description: task.description,
      category: task.category,
      status: task.status,
      dueDate: task.dueDate,
      nextDueDate: task.nextDueDate ?? task.dueDate,
      scheduledDate: task.scheduledDate,
      completedAt: task.completedAt,
      estimatedCost: task.estimatedCost ? Number(task.estimatedCost) : null,
      actualCost: task.actualCost ? Number(task.actualCost) : null,
      createdFromTemplate: task.createdFromTemplate,
      notes: task.notes,
      priority: task.priority,
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
      checklistSteps: task.checklistSteps as { id: string; completed: boolean }[] | undefined,
      template: task.template ? {
        id: task.template.id,
        slug: task.template.slug,
        title: task.template.title,
      } : undefined,
      assignedVendor: task.assignedVendor ? {
        id: task.assignedVendor.id,
        displayName: task.assignedVendor.displayName,
        category: task.assignedVendor.category,
      } : undefined,
    };
  }
}
