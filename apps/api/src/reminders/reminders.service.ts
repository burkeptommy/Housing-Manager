import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import {
  ReminderType,
  ReminderStatus,
  ReminderChannel,
  UpcomingBillDto,
  UpcomingMaintenanceTaskDto,
  CronJobResultDto,
  DashboardResponseDto,
  DashboardSummaryDto,
  NextUpItemDto,
  TodayTaskDto,
} from './dto';

@Injectable()
export class RemindersService {
  private readonly logger = new Logger(RemindersService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
  ) {}

  /**
   * Schedule bill reminders for all active bill accounts
   * Creates reminders at:
   * - 7 days before due date
   * - 1 day before due date
   */
  async scheduleBillReminders(): Promise<number> {
    this.logger.log('Starting to schedule bill reminders...');
    let scheduled = 0;

    // Get all active bill accounts with upcoming due dates
    const billAccounts = await this.prisma.billAccount.findMany({
      where: {
        isActive: true,
        deletedAt: null,
        nextDueDate: {
          not: null,
          gte: new Date(), // Due date is in the future
        },
      },
      include: {
        vendor: true,
        household: {
          include: {
            owner: true,
          },
        },
      },
    });

    for (const bill of billAccounts) {
      if (!bill.nextDueDate) continue;

      const dueDate = new Date(bill.nextDueDate);
      const now = new Date();

      // Calculate reminder dates
      const sevenDaysBefore = new Date(dueDate);
      sevenDaysBefore.setDate(sevenDaysBefore.getDate() - 7);

      const oneDayBefore = new Date(dueDate);
      oneDayBefore.setDate(oneDayBefore.getDate() - 1);

      const reminderDates = [
        { date: sevenDaysBefore, daysBeforeLabel: '7 days' },
        { date: oneDayBefore, daysBeforeLabel: '1 day' },
      ];

      for (const { date, daysBeforeLabel } of reminderDates) {
        // Skip if reminder date is in the past
        if (date <= now) continue;

        // Check if reminder already exists
        const existingReminder = await this.prisma.reminder.findFirst({
          where: {
            billAccountId: bill.id,
            type: 'BILL_DUE',
            scheduledAt: date,
            status: { not: 'CANCELLED' },
          },
        });

        if (existingReminder) continue;

        // Create reminder for both EMAIL and IN_APP channels
        for (const channel of ['EMAIL', 'IN_APP'] as const) {
          const payload = {
            billAccountId: bill.id,
            billNickname: bill.nickname,
            vendorName: bill.vendor.displayName,
            amount: bill.typicalAmount?.toNumber() || null,
            dueDate: dueDate.toISOString(),
            daysBeforeLabel,
            householdName: bill.household.name,
            recipientEmail: bill.household.owner.email,
            recipientName: `${bill.household.owner.firstName} ${bill.household.owner.lastName}`,
          };

          await this.prisma.reminder.create({
            data: {
              householdId: bill.householdId,
              type: 'BILL_DUE',
              billAccountId: bill.id,
              scheduledAt: date,
              channel,
              payloadJson: payload,
            },
          });
          scheduled++;
        }
      }
    }

    this.logger.log(`Scheduled ${scheduled} bill reminders`);
    return scheduled;
  }

  /**
   * Schedule maintenance task reminders
   * Creates reminders at:
   * - 7 days before due date
   * - 1 day before due date
   */
  async scheduleMaintenanceReminders(): Promise<number> {
    this.logger.log('Starting to schedule maintenance reminders...');
    let scheduled = 0;

    // Get all pending/scheduled maintenance tasks with due dates
    const tasks = await this.prisma.maintenanceTask.findMany({
      where: {
        status: { in: ['PENDING', 'SCHEDULED'] },
        dueDate: {
          not: null,
          gte: new Date(),
        },
      },
      include: {
        household: {
          include: {
            owner: true,
          },
        },
        assignedVendor: true,
      },
    });

    for (const task of tasks) {
      if (!task.dueDate) continue;

      const dueDate = new Date(task.dueDate);
      const now = new Date();

      // Calculate reminder dates
      const sevenDaysBefore = new Date(dueDate);
      sevenDaysBefore.setDate(sevenDaysBefore.getDate() - 7);

      const oneDayBefore = new Date(dueDate);
      oneDayBefore.setDate(oneDayBefore.getDate() - 1);

      const reminderDates = [
        { date: sevenDaysBefore, daysBeforeLabel: '7 days' },
        { date: oneDayBefore, daysBeforeLabel: '1 day' },
      ];

      for (const { date, daysBeforeLabel } of reminderDates) {
        // Skip if reminder date is in the past
        if (date <= now) continue;

        // Check if reminder already exists
        const existingReminder = await this.prisma.reminder.findFirst({
          where: {
            maintenanceTaskId: task.id,
            type: 'MAINTENANCE_TASK',
            scheduledAt: date,
            status: { not: 'CANCELLED' },
          },
        });

        if (existingReminder) continue;

        // Create reminder for both EMAIL and IN_APP channels
        for (const channel of ['EMAIL', 'IN_APP'] as const) {
          const payload = {
            maintenanceTaskId: task.id,
            taskTitle: task.title,
            taskDescription: task.description,
            category: task.category,
            dueDate: dueDate.toISOString(),
            daysBeforeLabel,
            householdName: task.household.name,
            assignedVendorName: task.assignedVendor?.displayName || null,
            estimatedCost: task.estimatedCost?.toNumber() || null,
            recipientEmail: task.household.owner.email,
            recipientName: `${task.household.owner.firstName} ${task.household.owner.lastName}`,
          };

          await this.prisma.reminder.create({
            data: {
              householdId: task.householdId,
              type: 'MAINTENANCE_TASK',
              maintenanceTaskId: task.id,
              scheduledAt: date,
              channel,
              payloadJson: payload,
            },
          });
          scheduled++;
        }
      }
    }

    this.logger.log(`Scheduled ${scheduled} maintenance reminders`);
    return scheduled;
  }

  /**
   * Process pending reminders that are due
   * Sends notifications via appropriate channels
   */
  async processReminders(): Promise<number> {
    this.logger.log('Starting to process reminders...');
    let processed = 0;

    const now = new Date();

    // Get all pending reminders that are due
    const reminders = await this.prisma.reminder.findMany({
      where: {
        status: 'PENDING',
        scheduledAt: {
          lte: now,
        },
      },
      include: {
        household: {
          include: {
            owner: true,
            members: {
              where: { status: 'ACTIVE' },
              include: { user: true },
            },
          },
        },
      },
      orderBy: { scheduledAt: 'asc' },
      take: 100, // Process in batches
    });

    for (const reminder of reminders) {
      try {
        const payload = reminder.payloadJson as Record<string, unknown> | null;

        if (reminder.channel === 'EMAIL') {
          await this.sendEmailReminder(reminder, payload);
        } else if (reminder.channel === 'IN_APP') {
          await this.sendInAppReminder(reminder, payload);
        }

        // Mark as sent
        await this.prisma.reminder.update({
          where: { id: reminder.id },
          data: {
            status: 'SENT',
            sentAt: new Date(),
          },
        });

        processed++;
      } catch (error) {
        this.logger.error(`Failed to process reminder ${reminder.id}:`, error);

        // Mark as failed with retry count
        await this.prisma.reminder.update({
          where: { id: reminder.id },
          data: {
            status: reminder.retryCount >= 3 ? 'FAILED' : 'PENDING',
            retryCount: { increment: 1 },
            errorMessage: error instanceof Error ? error.message : 'Unknown error',
          },
        });
      }
    }

    this.logger.log(`Processed ${processed} reminders`);
    return processed;
  }

  /**
   * Send email reminder
   */
  private async sendEmailReminder(
    reminder: { id: string; type: string; household: { owner: { email: string; firstName: string } } },
    payload: Record<string, unknown> | null,
  ): Promise<void> {
    const recipientEmail = payload?.recipientEmail as string || reminder.household.owner.email;
    const recipientName = payload?.recipientName as string || reminder.household.owner.firstName;

    let subject: string;
    let body: string;

    if (reminder.type === 'BILL_DUE') {
      const billNickname = payload?.billNickname as string || 'Your bill';
      const vendorName = payload?.vendorName as string || 'Unknown vendor';
      const amount = payload?.amount as number | null;
      const daysBeforeLabel = payload?.daysBeforeLabel as string || 'soon';
      const dueDate = payload?.dueDate ? new Date(payload.dueDate as string).toLocaleDateString() : 'soon';

      subject = `Bill Reminder: ${billNickname} due ${daysBeforeLabel}`;
      body = `
        <h2>Bill Payment Reminder</h2>
        <p>Hi ${recipientName},</p>
        <p>This is a reminder that your <strong>${billNickname}</strong> payment to <strong>${vendorName}</strong> is due on <strong>${dueDate}</strong>.</p>
        ${amount ? `<p>Typical amount: <strong>$${amount.toFixed(2)}</strong></p>` : ''}
        <p>Don't forget to make your payment on time!</p>
        <p>- Haven Home Manager</p>
      `;
    } else {
      const taskTitle = payload?.taskTitle as string || 'Maintenance task';
      const category = payload?.category as string || 'General';
      const daysBeforeLabel = payload?.daysBeforeLabel as string || 'soon';
      const dueDate = payload?.dueDate ? new Date(payload.dueDate as string).toLocaleDateString() : 'soon';
      const assignedVendorName = payload?.assignedVendorName as string | null;

      subject = `Maintenance Reminder: ${taskTitle} due ${daysBeforeLabel}`;
      body = `
        <h2>Maintenance Task Reminder</h2>
        <p>Hi ${recipientName},</p>
        <p>This is a reminder that your <strong>${taskTitle}</strong> (${category}) is due on <strong>${dueDate}</strong>.</p>
        ${assignedVendorName ? `<p>Assigned vendor: <strong>${assignedVendorName}</strong></p>` : ''}
        <p>Make sure to schedule or complete this maintenance task!</p>
        <p>- Haven Home Manager</p>
      `;
    }

    await this.notificationsService.sendEmail({
      to: recipientEmail,
      subject,
      body,
      isHtml: true,
    });
  }

  /**
   * Send in-app notification
   */
  private async sendInAppReminder(
    reminder: {
      id: string;
      type: string;
      householdId: string;
      billAccountId: string | null;
      maintenanceTaskId: string | null;
      household: {
        owner: { id: string };
        members: Array<{ user: { id: string } }>;
      };
    },
    payload: Record<string, unknown> | null,
  ): Promise<void> {
    let title: string;
    let body: string;
    let link: string | null = null;

    if (reminder.type === 'BILL_DUE') {
      const billNickname = payload?.billNickname as string || 'Your bill';
      const daysBeforeLabel = payload?.daysBeforeLabel as string || 'soon';
      title = `Bill Due ${daysBeforeLabel}`;
      body = `${billNickname} is due ${daysBeforeLabel}. Don't forget to pay!`;
      link = `/app/bills/${reminder.billAccountId}`;
    } else {
      const taskTitle = payload?.taskTitle as string || 'Maintenance task';
      const daysBeforeLabel = payload?.daysBeforeLabel as string || 'soon';
      title = `Maintenance Due ${daysBeforeLabel}`;
      body = `${taskTitle} is due ${daysBeforeLabel}. Schedule it now!`;
      link = `/app/maintenance/${reminder.maintenanceTaskId}`;
    }

    // Create in-app notification for household owner and all active members
    const userIds = [
      reminder.household.owner.id,
      ...reminder.household.members.map((m) => m.user.id),
    ];
    const uniqueUserIds = [...new Set(userIds)];

    for (const userId of uniqueUserIds) {
      await this.prisma.inAppNotification.create({
        data: {
          userId,
          householdId: reminder.householdId,
          title,
          body,
          link,
          billAccountId: reminder.billAccountId,
          maintenanceTaskId: reminder.maintenanceTaskId,
          reminderId: reminder.id,
        },
      });
    }
  }

  /**
   * Get upcoming bills for dashboard
   */
  async getUpcomingBills(householdId: string, daysAhead: number = 30): Promise<UpcomingBillDto[]> {
    const now = new Date();
    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + daysAhead);

    const bills = await this.prisma.billAccount.findMany({
      where: {
        householdId,
        isActive: true,
        deletedAt: null,
        nextDueDate: {
          lte: futureDate,
        },
      },
      include: {
        vendor: true,
      },
      orderBy: { nextDueDate: 'asc' },
    });

    return bills.map((bill) => {
      const dueDate = bill.nextDueDate ? new Date(bill.nextDueDate) : new Date();
      const diffTime = dueDate.getTime() - now.getTime();
      const daysUntilDue = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

      return {
        id: bill.id,
        nickname: bill.nickname,
        vendorName: bill.vendor.displayName,
        vendorId: bill.vendorId,
        category: bill.category,
        typicalAmount: bill.typicalAmount?.toNumber(),
        nextDueDate: dueDate,
        daysUntilDue,
        isOverdue: daysUntilDue < 0,
        paymentResponsibility: bill.paymentResponsibility,
      };
    });
  }

  /**
   * Get upcoming maintenance tasks for dashboard
   */
  async getUpcomingMaintenanceTasks(householdId: string, daysAhead: number = 30): Promise<UpcomingMaintenanceTaskDto[]> {
    const now = new Date();
    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + daysAhead);

    const tasks = await this.prisma.maintenanceTask.findMany({
      where: {
        householdId,
        status: { in: ['PENDING', 'SCHEDULED'] },
        dueDate: {
          lte: futureDate,
        },
      },
      include: {
        assignedVendor: true,
      },
      orderBy: { dueDate: 'asc' },
    });

    return tasks.map((task) => {
      const dueDate = task.dueDate ? new Date(task.dueDate) : new Date();
      const diffTime = dueDate.getTime() - now.getTime();
      const daysUntilDue = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

      return {
        id: task.id,
        title: task.title,
        description: task.description ?? undefined,
        category: task.category,
        status: task.status,
        dueDate: task.dueDate ?? undefined,
        scheduledDate: task.scheduledDate ?? undefined,
        daysUntilDue,
        isOverdue: daysUntilDue < 0,
        assignedVendorId: task.assignedVendorId ?? undefined,
        assignedVendorName: task.assignedVendor?.displayName,
        estimatedCost: task.estimatedCost?.toNumber(),
      };
    });
  }

  /**
   * Get full dashboard data for homeowner
   * Returns summary stats, next up item, today's tasks, and upcoming items
   */
  async getDashboardData(householdId: string): Promise<DashboardResponseDto> {
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0);
    const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const endOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59);

    // Fetch all data in parallel
    const [
      upcomingBills,
      upcomingMaintenanceTasks,
      billsThisMonth,
      tasksScheduledThisMonth,
      tasksCompletedThisMonth,
      todayBills,
      todayTasks,
    ] = await Promise.all([
      // Upcoming bills (next 30 days)
      this.getUpcomingBills(householdId, 30),
      // Upcoming maintenance tasks (next 30 days)
      this.getUpcomingMaintenanceTasks(householdId, 30),
      // Bills managed this month (active bill accounts with due dates this month)
      this.prisma.billAccount.count({
        where: {
          householdId,
          isActive: true,
          deletedAt: null,
          nextDueDate: {
            gte: startOfMonth,
            lte: endOfMonth,
          },
        },
      }),
      // Tasks scheduled this month
      this.prisma.maintenanceTask.count({
        where: {
          householdId,
          createdAt: {
            gte: startOfMonth,
            lte: endOfMonth,
          },
        },
      }),
      // Tasks completed this month
      this.prisma.maintenanceTask.count({
        where: {
          householdId,
          status: 'COMPLETED',
          completedAt: {
            gte: startOfMonth,
            lte: endOfMonth,
          },
        },
      }),
      // Today's bills
      this.prisma.billAccount.findMany({
        where: {
          householdId,
          isActive: true,
          deletedAt: null,
          nextDueDate: {
            gte: startOfDay,
            lte: endOfDay,
          },
        },
        include: { vendor: true },
      }),
      // Today's maintenance tasks
      this.prisma.maintenanceTask.findMany({
        where: {
          householdId,
          status: { in: ['PENDING', 'SCHEDULED'] },
          OR: [
            {
              dueDate: {
                gte: startOfDay,
                lte: endOfDay,
              },
            },
            {
              scheduledDate: {
                gte: startOfDay,
                lte: endOfDay,
              },
            },
          ],
        },
        include: { assignedVendor: true },
      }),
    ]);

    // Determine "Next Up" - the most imminent item
    let nextUp: NextUpItemDto | undefined;
    const allUpcoming: Array<{
      type: 'bill' | 'maintenance';
      id: string;
      title: string;
      category: string;
      vendorName?: string;
      amount?: number;
      daysUntilDue: number;
      dueDate: Date;
    }> = [];

    // Add bills to the combined list
    for (const bill of upcomingBills) {
      if (!bill.isOverdue) {
        allUpcoming.push({
          type: 'bill',
          id: bill.id,
          title: bill.nickname,
          category: bill.category,
          vendorName: bill.vendorName,
          amount: bill.typicalAmount,
          daysUntilDue: bill.daysUntilDue,
          dueDate: bill.nextDueDate,
        });
      }
    }

    // Add maintenance tasks to the combined list
    for (const task of upcomingMaintenanceTasks) {
      if (!task.isOverdue && task.dueDate) {
        allUpcoming.push({
          type: 'maintenance',
          id: task.id,
          title: task.title,
          category: task.category,
          vendorName: task.assignedVendorName,
          amount: task.estimatedCost,
          daysUntilDue: task.daysUntilDue,
          dueDate: new Date(task.dueDate),
        });
      }
    }

    // Sort by days until due and pick the first
    allUpcoming.sort((a, b) => a.daysUntilDue - b.daysUntilDue);
    if (allUpcoming.length > 0) {
      nextUp = allUpcoming[0];
    }

    // Build today's tasks list
    const todaysTasks: TodayTaskDto[] = [];

    for (const bill of todayBills) {
      todaysTasks.push({
        type: 'bill',
        id: bill.id,
        title: bill.nickname,
        category: bill.category,
        vendorName: bill.vendor?.displayName,
        amount: bill.typicalAmount?.toNumber(),
      });
    }

    for (const task of todayTasks) {
      todaysTasks.push({
        type: 'maintenance',
        id: task.id,
        title: task.title,
        category: task.category,
        vendorName: task.assignedVendor?.displayName,
        estimatedCost: task.estimatedCost?.toNumber(),
        scheduledTime: task.scheduledDate
          ? new Date(task.scheduledDate).toLocaleTimeString('en-US', {
              hour: 'numeric',
              minute: '2-digit',
            })
          : undefined,
      });
    }

    // Build summary
    const summary: DashboardSummaryDto = {
      billsManagedThisMonth: billsThisMonth,
      tasksScheduledThisMonth: tasksScheduledThisMonth,
      tasksCompletedThisMonth: tasksCompletedThisMonth,
      nextUp,
      todaysTasks,
    };

    return {
      summary,
      upcomingBills,
      upcomingMaintenanceTasks,
    };
  }

  /**
   * Run all reminder jobs (called by cron endpoint)
   */
  async runAllReminderJobs(): Promise<CronJobResultDto> {
    try {
      const billRemindersScheduled = await this.scheduleBillReminders();
      const maintenanceRemindersScheduled = await this.scheduleMaintenanceReminders();
      const remindersProcessed = await this.processReminders();

      return {
        success: true,
        billRemindersScheduled,
        maintenanceRemindersScheduled,
        remindersProcessed,
      };
    } catch (error) {
      this.logger.error('Failed to run reminder jobs:', error);
      return {
        success: false,
        billRemindersScheduled: 0,
        maintenanceRemindersScheduled: 0,
        remindersProcessed: 0,
        error: error instanceof Error ? error.message : 'Unknown error',
      };
    }
  }

  /**
   * Get in-app notifications for a user
   */
  async getInAppNotifications(userId: string, unreadOnly: boolean = false) {
    return this.prisma.inAppNotification.findMany({
      where: {
        userId,
        ...(unreadOnly ? { isRead: false } : {}),
      },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
  }

  /**
   * Mark notification as read
   */
  async markNotificationRead(notificationId: string, userId: string, isRead: boolean) {
    return this.prisma.inAppNotification.updateMany({
      where: { id: notificationId, userId },
      data: {
        isRead,
        readAt: isRead ? new Date() : null,
      },
    });
  }

  /**
   * Mark all notifications as read for a user
   */
  async markAllNotificationsRead(userId: string) {
    return this.prisma.inAppNotification.updateMany({
      where: { userId, isRead: false },
      data: {
        isRead: true,
        readAt: new Date(),
      },
    });
  }

  /**
   * Get unread notification count
   */
  async getUnreadCount(userId: string): Promise<number> {
    return this.prisma.inAppNotification.count({
      where: { userId, isRead: false },
    });
  }
}
