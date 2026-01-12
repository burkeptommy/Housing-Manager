import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  MaintenanceTaskStatus,
  MaintenanceCategory,
  MaintenanceFrequency,
} from '@prisma/client';
import {
  CHECKLIST_TEMPLATES,
  ChecklistStep,
  findMatchingTemplate,
  createChecklistFromTemplate,
  getWhyThisMatters,
} from './checklist-templates';

@Injectable()
export class MaintenanceService {
  constructor(private prisma: PrismaService) {}

  /**
   * Get all maintenance tasks for a household
   */
  async getHouseholdTasks(
    householdId: string,
    filters?: {
      status?: MaintenanceTaskStatus;
      category?: MaintenanceCategory;
      dueBefore?: Date;
    },
  ) {
    const where: any = { householdId };

    if (filters?.status) where.status = filters.status;
    if (filters?.category) where.category = filters.category;
    if (filters?.dueBefore) {
      where.nextDueDate = { lte: filters.dueBefore };
    }

    return this.prisma.maintenanceTask.findMany({
      where,
      include: {
        assignedVendor: {
          select: { id: true, displayName: true, phone: true },
        },
      },
      orderBy: [{ nextDueDate: 'asc' }, { priority: 'desc' }],
    });
  }

  /**
   * Get tasks grouped by season/month for calendar view
   */
  async getTaskCalendar(householdId: string) {
    const tasks = await this.prisma.maintenanceTask.findMany({
      where: { householdId },
      orderBy: { nextDueDate: 'asc' },
    });

    const now = new Date();

    // Group by season
    const calendar = {
      overdue: tasks.filter(
        (t) =>
          t.nextDueDate &&
          t.nextDueDate < now &&
          t.status !== 'COMPLETED' &&
          t.status !== 'SKIPPED',
      ),
      thisMonth: tasks.filter((t) => {
        if (!t.nextDueDate) return false;
        return (
          t.nextDueDate.getMonth() === now.getMonth() &&
          t.nextDueDate.getFullYear() === now.getFullYear()
        );
      }),
      upcoming: tasks.filter((t) => {
        if (!t.nextDueDate) return false;
        const threeMonths = new Date(now.getFullYear(), now.getMonth() + 3, 1);
        return t.nextDueDate > now && t.nextDueDate < threeMonths;
      }),
      spring: tasks.filter((t) => t.seasonalTiming === 'SPRING'),
      summer: tasks.filter((t) => t.seasonalTiming === 'SUMMER'),
      fall: tasks.filter((t) => t.seasonalTiming === 'FALL'),
      winter: tasks.filter((t) => t.seasonalTiming === 'WINTER'),
    };

    return calendar;
  }

  /**
   * Get summary stats for dashboard
   */
  async getTaskSummary(householdId: string) {
    const now = new Date();
    const thirtyDays = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);

    const [total, overdue, dueSoon, completed] = await Promise.all([
      this.prisma.maintenanceTask.count({ where: { householdId } }),
      this.prisma.maintenanceTask.count({
        where: {
          householdId,
          nextDueDate: { lt: now },
          status: { notIn: ['COMPLETED', 'SKIPPED'] },
        },
      }),
      this.prisma.maintenanceTask.count({
        where: {
          householdId,
          nextDueDate: { gte: now, lte: thirtyDays },
          status: { notIn: ['COMPLETED', 'SKIPPED'] },
        },
      }),
      this.prisma.maintenanceTask.count({
        where: { householdId, status: 'COMPLETED' },
      }),
    ]);

    return { total, overdue, dueSoon, completed };
  }

  /**
   * Mark a task as complete
   */
  async completeTask(
    taskId: string,
    userId: string,
    data: { notes?: string; actualCost?: number },
  ) {
    const task = await this.prisma.maintenanceTask.findUnique({
      where: { id: taskId },
    });

    if (!task) throw new NotFoundException('Task not found');

    const updated = await this.prisma.maintenanceTask.update({
      where: { id: taskId },
      data: {
        status: 'COMPLETED',
        completedById: userId,
        completedAt: new Date(),
        lastCompletedDate: new Date(),
        completionNotes: data.notes,
        actualCost: data.actualCost,
        // If recurring, set next due date
        nextDueDate: task.isRecurring
          ? this.calculateNextDueDate(
              task.frequency as MaintenanceFrequency,
              task.nextDueDate,
            )
          : null,
      },
    });

    // Log activity
    await this.prisma.activityLog.create({
      data: {
        householdId: task.householdId,
        actorId: userId,
        actorType: 'HOME_MANAGER',
        actorName: 'Home Manager',
        action: 'SERVICE_COMPLETED',
        category: 'SERVICE',
        title: `Completed: ${task.title}`,
        description: data.notes,
        amount: data.actualCost,
        visibleToHomeowner: true,
      },
    });

    return updated;
  }

  /**
   * Schedule a task (assign vendor, set date)
   */
  async scheduleTask(
    taskId: string,
    data: { vendorId?: string; scheduledDate?: Date; notes?: string },
  ) {
    const task = await this.prisma.maintenanceTask.findUnique({
      where: { id: taskId },
    });

    if (!task) throw new NotFoundException('Task not found');

    return this.prisma.maintenanceTask.update({
      where: { id: taskId },
      data: {
        status: 'SCHEDULED',
        assignedVendorId: data.vendorId,
        scheduledDate: data.scheduledDate || task.scheduledDate,
        notes: data.notes,
      },
    });
  }

  /**
   * Skip a task (postpone to next cycle)
   */
  async skipTask(taskId: string, reason?: string) {
    const task = await this.prisma.maintenanceTask.findUnique({
      where: { id: taskId },
    });

    if (!task) throw new NotFoundException('Task not found');

    return this.prisma.maintenanceTask.update({
      where: { id: taskId },
      data: {
        status: 'SKIPPED',
        completionNotes: reason,
        nextDueDate: task.isRecurring
          ? this.calculateNextDueDate(
              task.frequency as MaintenanceFrequency,
              task.nextDueDate,
            )
          : null,
      },
    });
  }

  private calculateNextDueDate(
    frequency: MaintenanceFrequency,
    fromDate: Date | null,
  ): Date {
    const date = fromDate ? new Date(fromDate) : new Date();

    switch (frequency) {
      case 'MONTHLY':
        date.setMonth(date.getMonth() + 1);
        break;
      case 'QUARTERLY':
        date.setMonth(date.getMonth() + 3);
        break;
      case 'SEMI_ANNUAL':
      case 'SEMIANNUALLY':
        date.setMonth(date.getMonth() + 6);
        break;
      case 'ANNUAL':
      case 'ANNUALLY':
        date.setFullYear(date.getFullYear() + 1);
        break;
      case 'BIENNIAL':
        date.setFullYear(date.getFullYear() + 2);
        break;
      case 'TRIENNIAL':
        date.setFullYear(date.getFullYear() + 3);
        break;
    }

    return date;
  }

  /**
   * Get all checklist templates
   */
  getTemplates() {
    return CHECKLIST_TEMPLATES.map((t) => ({
      id: t.id,
      name: t.name,
      category: t.category,
      whyThisMatters: t.whyThisMatters,
      stepCount: t.steps.length,
    }));
  }

  /**
   * Get a single maintenance task with full details
   */
  async getTask(taskId: string) {
    const task = await this.prisma.maintenanceTask.findUnique({
      where: { id: taskId },
      include: {
        assignedVendor: {
          select: { id: true, displayName: true, phone: true, email: true },
        },
        homeSystem: {
          select: {
            id: true,
            name: true,
            type: true,
            brand: true,
            model: true,
            location: true,
            installedDate: true,
            warrantyExpires: true,
          },
        },
        completedBy: {
          select: { id: true, firstName: true, lastName: true },
        },
      },
    });

    if (!task) throw new NotFoundException('Task not found');

    // If task has no checklist, try to initialize from template
    if (!task.checklistSteps) {
      const template = findMatchingTemplate(task.title, task.category);
      if (template) {
        const checklist = createChecklistFromTemplate(template);
        const whyThisMatters = template.whyThisMatters;

        // Update task with initial checklist
        await this.prisma.maintenanceTask.update({
          where: { id: taskId },
          data: {
            checklistSteps: checklist as any,
            intervalExplanation: whyThisMatters,
          },
        });

        return {
          ...task,
          checklistSteps: checklist,
          intervalExplanation: whyThisMatters,
          templateId: template.id,
        };
      }
    }

    return task;
  }

  /**
   * Complete a checklist step
   */
  async completeChecklistStep(
    taskId: string,
    stepId: string,
    userId: string,
    completed: boolean,
  ) {
    const task = await this.prisma.maintenanceTask.findUnique({
      where: { id: taskId },
    });

    if (!task) throw new NotFoundException('Task not found');

    // Parse existing checklist
    const checklist = (task.checklistSteps as unknown as ChecklistStep[]) || [];

    // Find and update the step
    const stepIndex = checklist.findIndex((s) => s.id === stepId);
    if (stepIndex === -1) {
      throw new NotFoundException('Checklist step not found');
    }

    checklist[stepIndex] = {
      ...checklist[stepIndex],
      completed,
      completedAt: completed ? new Date().toISOString() : undefined,
    };

    // Check if all steps are completed
    const allCompleted = checklist.every((s) => s.completed);

    // Update task
    const updated = await this.prisma.maintenanceTask.update({
      where: { id: taskId },
      data: {
        checklistSteps: checklist as any,
        // If all steps completed, mark task as completed
        ...(allCompleted && {
          status: 'COMPLETED',
          completedById: userId,
          completedAt: new Date(),
          lastCompletedDate: new Date(),
          nextDueDate: task.isRecurring
            ? this.calculateNextDueDate(
                task.frequency as MaintenanceFrequency,
                task.nextDueDate,
              )
            : null,
        }),
      },
      include: {
        assignedVendor: {
          select: { id: true, displayName: true, phone: true },
        },
        homeSystem: {
          select: {
            id: true,
            name: true,
            type: true,
            location: true,
          },
        },
      },
    });

    // Log activity if task is completed
    if (allCompleted) {
      await this.prisma.activityLog.create({
        data: {
          householdId: task.householdId,
          actorId: userId,
          actorType: 'HOME_MANAGER',
          actorName: 'Home Manager',
          action: 'SERVICE_COMPLETED',
          category: 'SERVICE',
          title: `Completed: ${task.title}`,
          description: 'All checklist items completed',
          visibleToHomeowner: true,
        },
      });
    }

    return updated;
  }

  /**
   * Initialize checklist for a task from a template
   */
  async initializeChecklist(taskId: string, templateId?: string) {
    const task = await this.prisma.maintenanceTask.findUnique({
      where: { id: taskId },
    });

    if (!task) throw new NotFoundException('Task not found');

    // Find template
    let template;
    if (templateId) {
      template = CHECKLIST_TEMPLATES.find((t) => t.id === templateId);
    } else {
      template = findMatchingTemplate(task.title, task.category);
    }

    if (!template) {
      throw new NotFoundException('No matching template found');
    }

    const checklist = createChecklistFromTemplate(template);

    return this.prisma.maintenanceTask.update({
      where: { id: taskId },
      data: {
        checklistSteps: checklist as any,
        intervalExplanation: template.whyThisMatters,
      },
    });
  }

  /**
   * Update checklist steps (for reordering or custom modifications)
   */
  async updateChecklist(taskId: string, steps: ChecklistStep[]) {
    const task = await this.prisma.maintenanceTask.findUnique({
      where: { id: taskId },
    });

    if (!task) throw new NotFoundException('Task not found');

    return this.prisma.maintenanceTask.update({
      where: { id: taskId },
      data: {
        checklistSteps: steps as any,
      },
    });
  }
}
