import { Test, TestingModule } from '@nestjs/testing';
import { VendorCategory, BillingFrequency, PaymentResponsibility } from '@prisma/client';

import { PrismaService } from '../prisma';
import { NotificationsService } from '../notifications/notifications.service';

import { RemindersService } from './reminders.service';

describe('RemindersService', () => {
  let service: RemindersService;

  const mockHouseholdId = 'household-123';
  const mockUserId = 'user-123';
  const mockBillAccountId = 'bill-123';
  const mockMaintenanceTaskId = 'task-123';

  const mockOwner = {
    id: mockUserId,
    email: 'owner@example.com',
    firstName: 'John',
    lastName: 'Doe',
  };

  const mockHousehold = {
    id: mockHouseholdId,
    name: 'Test Home',
    owner: mockOwner,
    members: [{ user: mockOwner }],
  };

  const mockVendor = {
    id: 'vendor-123',
    displayName: 'Electric Company',
    category: VendorCategory.ELECTRIC,
  };

  // Bill due in 10 days
  const futureDueDate = new Date();
  futureDueDate.setDate(futureDueDate.getDate() + 10);

  const mockBillAccount = {
    id: mockBillAccountId,
    householdId: mockHouseholdId,
    vendorId: mockVendor.id,
    nickname: 'Electric Bill',
    category: VendorCategory.ELECTRIC,
    billingFrequency: BillingFrequency.MONTHLY,
    paymentResponsibility: PaymentResponsibility.OWNER_PAYS_DIRECT,
    typicalAmount: { toNumber: () => 150 },
    nextDueDate: futureDueDate,
    isActive: true,
    deletedAt: null,
    vendor: mockVendor,
    household: mockHousehold,
  };

  const mockMaintenanceTask = {
    id: mockMaintenanceTaskId,
    householdId: mockHouseholdId,
    title: 'HVAC Maintenance',
    description: 'Annual HVAC inspection',
    category: 'HVAC',
    status: 'PENDING',
    dueDate: futureDueDate,
    scheduledDate: null,
    estimatedCost: { toNumber: () => 200 },
    household: mockHousehold,
    assignedVendor: null,
  };

  const mockPrismaService = {
    billAccount: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
      count: jest.fn(),
    },
    maintenanceTask: {
      findMany: jest.fn(),
      count: jest.fn(),
    },
    reminder: {
      findMany: jest.fn(),
      findFirst: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    inAppNotification: {
      create: jest.fn(),
      findMany: jest.fn(),
      updateMany: jest.fn(),
      count: jest.fn(),
    },
  };

  const mockNotificationsService = {
    sendEmail: jest.fn(),
    sendPush: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        RemindersService,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: NotificationsService, useValue: mockNotificationsService },
      ],
    }).compile();

    service = module.get<RemindersService>(RemindersService);

    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('scheduleBillReminders', () => {
    it('should schedule reminders 7 days and 1 day before due date', async () => {
      mockPrismaService.billAccount.findMany.mockResolvedValue([mockBillAccount]);
      mockPrismaService.reminder.findFirst.mockResolvedValue(null); // No existing reminders
      mockPrismaService.reminder.create.mockResolvedValue({ id: 'reminder-1' });

      const scheduled = await service.scheduleBillReminders();

      // Should create 4 reminders: 2 dates x 2 channels (EMAIL, IN_APP)
      expect(mockPrismaService.reminder.create).toHaveBeenCalledTimes(4);
      expect(scheduled).toBe(4);

      // Verify the reminder dates
      const createCalls = mockPrismaService.reminder.create.mock.calls;

      // Check 7-day reminder
      const sevenDayReminder = createCalls.find(
        (call) => (call[0].data.payloadJson as Record<string, unknown>).daysBeforeLabel === '7 days',
      );
      expect(sevenDayReminder).toBeDefined();
      expect(sevenDayReminder[0].data.type).toBe('BILL_DUE');
      expect(sevenDayReminder[0].data.billAccountId).toBe(mockBillAccountId);

      // Check 1-day reminder
      const oneDayReminder = createCalls.find(
        (call) => (call[0].data.payloadJson as Record<string, unknown>).daysBeforeLabel === '1 day',
      );
      expect(oneDayReminder).toBeDefined();
    });

    it('should not create duplicate reminders', async () => {
      mockPrismaService.billAccount.findMany.mockResolvedValue([mockBillAccount]);
      // Simulate existing reminder
      mockPrismaService.reminder.findFirst.mockResolvedValue({
        id: 'existing-reminder',
        status: 'PENDING',
      });

      const scheduled = await service.scheduleBillReminders();

      // Should not create any new reminders
      expect(mockPrismaService.reminder.create).not.toHaveBeenCalled();
      expect(scheduled).toBe(0);
    });

    it('should skip bills with past due dates', async () => {
      const pastDueDate = new Date();
      pastDueDate.setDate(pastDueDate.getDate() - 5);

      mockPrismaService.billAccount.findMany.mockResolvedValue([
        {
          ...mockBillAccount,
          nextDueDate: pastDueDate,
        },
      ]);

      const scheduled = await service.scheduleBillReminders();

      // findMany already filters for future dates, but the loop should also skip
      expect(scheduled).toBe(0);
    });

    it('should skip reminder dates that are in the past', async () => {
      // Bill due in 2 days - 7-day reminder would be in the past
      const twoDaysFromNow = new Date();
      twoDaysFromNow.setDate(twoDaysFromNow.getDate() + 2);

      mockPrismaService.billAccount.findMany.mockResolvedValue([
        {
          ...mockBillAccount,
          nextDueDate: twoDaysFromNow,
        },
      ]);
      mockPrismaService.reminder.findFirst.mockResolvedValue(null);
      mockPrismaService.reminder.create.mockResolvedValue({ id: 'reminder-1' });

      const scheduled = await service.scheduleBillReminders();

      // Should only create 1-day reminders (EMAIL and IN_APP)
      expect(mockPrismaService.reminder.create).toHaveBeenCalledTimes(2);
      expect(scheduled).toBe(2);
    });

    it('should include bill amount and vendor info in payload', async () => {
      mockPrismaService.billAccount.findMany.mockResolvedValue([mockBillAccount]);
      mockPrismaService.reminder.findFirst.mockResolvedValue(null);
      mockPrismaService.reminder.create.mockResolvedValue({ id: 'reminder-1' });

      await service.scheduleBillReminders();

      const createCall = mockPrismaService.reminder.create.mock.calls[0];
      const payload = createCall[0].data.payloadJson as Record<string, unknown>;

      expect(payload.billNickname).toBe('Electric Bill');
      expect(payload.vendorName).toBe('Electric Company');
      expect(payload.amount).toBe(150);
      expect(payload.recipientEmail).toBe('owner@example.com');
    });
  });

  describe('scheduleMaintenanceReminders', () => {
    it('should schedule reminders for pending maintenance tasks', async () => {
      mockPrismaService.maintenanceTask.findMany.mockResolvedValue([mockMaintenanceTask]);
      mockPrismaService.reminder.findFirst.mockResolvedValue(null);
      mockPrismaService.reminder.create.mockResolvedValue({ id: 'reminder-1' });

      const scheduled = await service.scheduleMaintenanceReminders();

      // Should create 4 reminders: 2 dates x 2 channels
      expect(mockPrismaService.reminder.create).toHaveBeenCalledTimes(4);
      expect(scheduled).toBe(4);

      const createCalls = mockPrismaService.reminder.create.mock.calls;

      // Verify reminder type
      const anyReminder = createCalls[0];
      expect(anyReminder[0].data.type).toBe('MAINTENANCE_TASK');
      expect(anyReminder[0].data.maintenanceTaskId).toBe(mockMaintenanceTaskId);
    });

    it('should include task details in payload', async () => {
      mockPrismaService.maintenanceTask.findMany.mockResolvedValue([mockMaintenanceTask]);
      mockPrismaService.reminder.findFirst.mockResolvedValue(null);
      mockPrismaService.reminder.create.mockResolvedValue({ id: 'reminder-1' });

      await service.scheduleMaintenanceReminders();

      const createCall = mockPrismaService.reminder.create.mock.calls[0];
      const payload = createCall[0].data.payloadJson as Record<string, unknown>;

      expect(payload.taskTitle).toBe('HVAC Maintenance');
      expect(payload.category).toBe('HVAC');
      expect(payload.estimatedCost).toBe(200);
    });
  });

  describe('processReminders', () => {
    const pendingReminder = {
      id: 'reminder-1',
      type: 'BILL_DUE',
      channel: 'EMAIL',
      status: 'PENDING',
      scheduledAt: new Date(Date.now() - 1000), // In the past
      householdId: mockHouseholdId,
      billAccountId: mockBillAccountId,
      maintenanceTaskId: null,
      retryCount: 0,
      payloadJson: {
        billNickname: 'Electric Bill',
        vendorName: 'Electric Company',
        amount: 150,
        daysBeforeLabel: '1 day',
        recipientEmail: 'owner@example.com',
        recipientName: 'John Doe',
      },
      household: mockHousehold,
    };

    it('should process pending reminders and send notifications', async () => {
      mockPrismaService.reminder.findMany.mockResolvedValue([pendingReminder]);
      mockPrismaService.reminder.update.mockResolvedValue({ ...pendingReminder, status: 'SENT' });
      mockNotificationsService.sendEmail.mockResolvedValue(undefined);

      const processed = await service.processReminders();

      expect(processed).toBe(1);
      expect(mockNotificationsService.sendEmail).toHaveBeenCalled();
      expect(mockPrismaService.reminder.update).toHaveBeenCalledWith({
        where: { id: 'reminder-1' },
        data: {
          status: 'SENT',
          sentAt: expect.any(Date),
        },
      });
    });

    it('should send in-app notifications for IN_APP channel', async () => {
      const inAppReminder = {
        ...pendingReminder,
        channel: 'IN_APP',
      };

      mockPrismaService.reminder.findMany.mockResolvedValue([inAppReminder]);
      mockPrismaService.reminder.update.mockResolvedValue({ ...inAppReminder, status: 'SENT' });
      mockPrismaService.inAppNotification.create.mockResolvedValue({ id: 'notification-1' });

      const processed = await service.processReminders();

      expect(processed).toBe(1);
      expect(mockPrismaService.inAppNotification.create).toHaveBeenCalled();
    });

    it('should retry failed reminders up to 3 times', async () => {
      mockPrismaService.reminder.findMany.mockResolvedValue([pendingReminder]);
      mockNotificationsService.sendEmail.mockRejectedValue(new Error('Email service unavailable'));

      await service.processReminders();

      expect(mockPrismaService.reminder.update).toHaveBeenCalledWith({
        where: { id: 'reminder-1' },
        data: {
          status: 'PENDING', // Still pending for retry
          retryCount: { increment: 1 },
          errorMessage: 'Email service unavailable',
        },
      });
    });

    it('should mark as FAILED after 3 retries', async () => {
      const failedReminder = {
        ...pendingReminder,
        retryCount: 3, // Already retried 3 times
      };

      mockPrismaService.reminder.findMany.mockResolvedValue([failedReminder]);
      mockNotificationsService.sendEmail.mockRejectedValue(new Error('Email service unavailable'));

      await service.processReminders();

      expect(mockPrismaService.reminder.update).toHaveBeenCalledWith({
        where: { id: 'reminder-1' },
        data: {
          status: 'FAILED',
          retryCount: { increment: 1 },
          errorMessage: 'Email service unavailable',
        },
      });
    });
  });

  describe('getUpcomingBills', () => {
    it('should return upcoming bills with days until due', async () => {
      mockPrismaService.billAccount.findMany.mockResolvedValue([mockBillAccount]);

      const result = await service.getUpcomingBills(mockHouseholdId, 30);

      expect(result).toHaveLength(1);
      expect(result[0].nickname).toBe('Electric Bill');
      expect(result[0].vendorName).toBe('Electric Company');
      expect(result[0].daysUntilDue).toBe(10);
      expect(result[0].isOverdue).toBe(false);
    });

    it('should mark overdue bills correctly', async () => {
      const pastDueDate = new Date();
      pastDueDate.setDate(pastDueDate.getDate() - 3);

      mockPrismaService.billAccount.findMany.mockResolvedValue([
        {
          ...mockBillAccount,
          nextDueDate: pastDueDate,
        },
      ]);

      const result = await service.getUpcomingBills(mockHouseholdId, 30);

      expect(result[0].isOverdue).toBe(true);
      expect(result[0].daysUntilDue).toBeLessThan(0);
    });
  });

  describe('getUpcomingMaintenanceTasks', () => {
    it('should return upcoming maintenance tasks', async () => {
      mockPrismaService.maintenanceTask.findMany.mockResolvedValue([mockMaintenanceTask]);

      const result = await service.getUpcomingMaintenanceTasks(mockHouseholdId, 30);

      expect(result).toHaveLength(1);
      expect(result[0].title).toBe('HVAC Maintenance');
      expect(result[0].category).toBe('HVAC');
    });
  });

  describe('getDashboardData', () => {
    it('should return complete dashboard data', async () => {
      mockPrismaService.billAccount.findMany.mockResolvedValue([mockBillAccount]);
      mockPrismaService.maintenanceTask.findMany.mockResolvedValue([mockMaintenanceTask]);
      mockPrismaService.billAccount.count.mockResolvedValue(5);
      mockPrismaService.maintenanceTask.count
        .mockResolvedValueOnce(3) // Tasks scheduled
        .mockResolvedValueOnce(2); // Tasks completed

      const result = await service.getDashboardData(mockHouseholdId);

      expect(result.summary.billsManagedThisMonth).toBe(5);
      expect(result.summary.tasksScheduledThisMonth).toBe(3);
      expect(result.summary.tasksCompletedThisMonth).toBe(2);
      expect(result.upcomingBills).toHaveLength(1);
      expect(result.upcomingMaintenanceTasks).toHaveLength(1);
    });

    it('should determine next up item correctly', async () => {
      const billDue5Days = {
        ...mockBillAccount,
        nextDueDate: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000),
      };
      const taskDue3Days = {
        ...mockMaintenanceTask,
        dueDate: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000),
      };

      mockPrismaService.billAccount.findMany.mockResolvedValue([billDue5Days]);
      mockPrismaService.maintenanceTask.findMany.mockResolvedValue([taskDue3Days]);
      mockPrismaService.billAccount.count.mockResolvedValue(1);
      mockPrismaService.maintenanceTask.count.mockResolvedValue(1);

      const result = await service.getDashboardData(mockHouseholdId);

      // Maintenance task is due sooner
      expect(result.summary.nextUp?.type).toBe('maintenance');
      expect(result.summary.nextUp?.title).toBe('HVAC Maintenance');
    });
  });

  describe('runAllReminderJobs', () => {
    it('should run all reminder jobs and return summary', async () => {
      mockPrismaService.billAccount.findMany.mockResolvedValue([]);
      mockPrismaService.maintenanceTask.findMany.mockResolvedValue([]);
      mockPrismaService.reminder.findMany.mockResolvedValue([]);

      const result = await service.runAllReminderJobs();

      expect(result.success).toBe(true);
      expect(result.billRemindersScheduled).toBe(0);
      expect(result.maintenanceRemindersScheduled).toBe(0);
      expect(result.remindersProcessed).toBe(0);
    });

    it('should handle errors gracefully', async () => {
      mockPrismaService.billAccount.findMany.mockRejectedValue(new Error('Database error'));

      const result = await service.runAllReminderJobs();

      expect(result.success).toBe(false);
      expect(result.error).toBe('Database error');
    });
  });

  describe('notification management', () => {
    it('should get unread notifications', async () => {
      const notifications = [
        { id: 'notif-1', title: 'Test', isRead: false },
        { id: 'notif-2', title: 'Test 2', isRead: false },
      ];
      mockPrismaService.inAppNotification.findMany.mockResolvedValue(notifications);

      const result = await service.getInAppNotifications(mockUserId, true);

      expect(result).toHaveLength(2);
      expect(mockPrismaService.inAppNotification.findMany).toHaveBeenCalledWith({
        where: { userId: mockUserId, isRead: false },
        orderBy: { createdAt: 'desc' },
        take: 50,
      });
    });

    it('should mark notification as read', async () => {
      mockPrismaService.inAppNotification.updateMany.mockResolvedValue({ count: 1 });

      await service.markNotificationRead('notif-1', mockUserId, true);

      expect(mockPrismaService.inAppNotification.updateMany).toHaveBeenCalledWith({
        where: { id: 'notif-1', userId: mockUserId },
        data: {
          isRead: true,
          readAt: expect.any(Date),
        },
      });
    });

    it('should get unread count', async () => {
      mockPrismaService.inAppNotification.count.mockResolvedValue(5);

      const count = await service.getUnreadCount(mockUserId);

      expect(count).toBe(5);
    });
  });
});
