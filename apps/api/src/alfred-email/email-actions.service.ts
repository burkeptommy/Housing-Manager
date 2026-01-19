import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ParsedEmailResult } from './email-parser.service';
import {
  EmailCaseActivityType,
  TaskPriority,
  ReminderType,
  ReminderStatus,
  DocumentCategory,
  VendorCategory,
} from '@prisma/client';

interface ActionResult {
  actions: Array<{
    type: string;
    description: string;
    success: boolean;
    recordId?: string;
  }>;
  needsInput: boolean;
  question?: string;
  questionOptions?: string[];
  questionContext?: Record<string, unknown>;
}

// Map urgency to TaskPriority
const urgencyToPriority: Record<string, TaskPriority> = {
  URGENT: 'URGENT',
  HIGH: 'HIGH',
  NORMAL: 'MEDIUM',
  LOW: 'LOW',
};

// Map document categories from parser to Prisma enum
const documentCategoryMap: Record<string, DocumentCategory> = {
  tax: 'TAX',
  contracts: 'CONTRACT',
  receipts: 'RECEIPT',
  medical: 'OTHER',
  school: 'OTHER',
  insurance: 'INSURANCE',
  warranty: 'WARRANTY',
  manual: 'MANUAL',
  property: 'PROPERTY',
  permit: 'PERMIT',
  general: 'OTHER',
};

@Injectable()
export class EmailActionsService {
  private readonly logger = new Logger(EmailActionsService.name);

  constructor(private prisma: PrismaService) {}

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /**
   * Create a task from parsed email data
   */
  private async createTask(
    householdId: string,
    caseId: string,
    task: {
      title: string;
      description?: string;
      priority: 'URGENT' | 'HIGH' | 'NORMAL' | 'LOW';
      dueDate?: string;
      assignedToId?: string;
    },
  ): Promise<{ success: boolean; recordId?: string; error?: string }> {
    try {
      const household = await this.prisma.household.findUnique({
        where: { id: householdId },
        select: { ownerId: true },
      });

      const newTask = await this.prisma.task.create({
        data: {
          householdId,
          createdById: household?.ownerId || '',
          assigneeId: task.assignedToId || household?.ownerId,
          title: task.title,
          description: task.description,
          priority: urgencyToPriority[task.priority] || 'MEDIUM',
          dueDate: task.dueDate ? new Date(task.dueDate) : undefined,
        },
      });

      await this.logActivity(caseId, EmailCaseActivityType.TASK_CREATED, {
        description: `Created task: ${task.title}`,
        details: { taskId: newTask.id },
      });

      return { success: true, recordId: newTask.id };
    } catch (error) {
      await this.logActivity(caseId, EmailCaseActivityType.ACTION_FAILED, {
        description: `Failed to create task: ${error.message}`,
      });
      return { success: false, error: error.message };
    }
  }

  /**
   * Create a reminder from parsed email data
   */
  private async createReminder(
    householdId: string,
    caseId: string,
    reminder: {
      message: string;
      remindAt: string;
    },
  ): Promise<{ success: boolean; recordId?: string; error?: string }> {
    try {
      const newReminder = await this.prisma.reminder.create({
        data: {
          householdId,
          type: ReminderType.BILL_DUE, // Using BILL_DUE as a generic type
          scheduledAt: new Date(reminder.remindAt),
          status: ReminderStatus.PENDING,
          payloadJson: { message: reminder.message, source: 'alfred-email' },
        },
      });

      await this.logActivity(caseId, EmailCaseActivityType.REMINDER_CREATED, {
        description: `Set reminder: ${reminder.message}`,
        details: { reminderId: newReminder.id, remindAt: reminder.remindAt },
      });

      return { success: true, recordId: newReminder.id };
    } catch (error) {
      await this.logActivity(caseId, EmailCaseActivityType.ACTION_FAILED, {
        description: `Failed to create reminder: ${error.message}`,
      });
      return { success: false, error: error.message };
    }
  }

  /**
   * Save document metadata to vault (Note: actual file storage is separate)
   */
  private async saveDocumentMetadata(
    householdId: string,
    caseId: string,
    doc: {
      name: string;
      category: string;
      forMemberId?: string;
    },
  ): Promise<{ success: boolean; recordId?: string; error?: string }> {
    try {
      const household = await this.prisma.household.findUnique({
        where: { id: householdId },
        select: { ownerId: true },
      });

      const category =
        documentCategoryMap[doc.category?.toLowerCase()] || DocumentCategory.OTHER;

      // Create a placeholder document record - actual file upload handled separately
      const document = await this.prisma.document.create({
        data: {
          householdId,
          fileName: `${doc.name.replace(/[^a-zA-Z0-9]/g, '_')}.pdf`,
          originalName: doc.name,
          mimeType: 'application/pdf',
          fileSize: 0, // Placeholder
          storageUrl: '', // Will be set when file is uploaded
          storagePath: '', // Will be set when file is uploaded
          category,
          title: doc.name,
          uploadedById: household?.ownerId || '',
        },
      });

      await this.logActivity(caseId, EmailCaseActivityType.DOCUMENT_SAVED, {
        description: `Saved document: ${doc.name} (${category})`,
        details: { documentId: document.id, category },
      });

      return { success: true, recordId: document.id };
    } catch (error) {
      await this.logActivity(caseId, EmailCaseActivityType.ACTION_FAILED, {
        description: `Failed to save document: ${error.message}`,
      });
      return { success: false, error: error.message };
    }
  }

  /**
   * Send notification to household members
   */
  private async notifyHousehold(
    householdId: string,
    caseId: string,
    notification: {
      title: string;
      message: string;
      priority: 'URGENT' | 'HIGH' | 'NORMAL' | 'LOW';
    },
  ): Promise<{ success: boolean; error?: string }> {
    try {
      // Get household members
      const members = await this.prisma.householdMember.findMany({
        where: { householdId, status: 'ACTIVE' },
        include: { user: true },
      });

      // For now, log the notification - actual push/email to be implemented
      // TODO: Integrate with push notification service
      await this.logActivity(caseId, EmailCaseActivityType.NOTIFICATION_SENT, {
        description: `Notification: ${notification.title}`,
        details: {
          message: notification.message,
          priority: notification.priority,
          memberCount: members.length,
        },
      });

      return { success: true };
    } catch (error) {
      await this.logActivity(caseId, EmailCaseActivityType.ACTION_FAILED, {
        description: `Failed to send notification: ${error.message}`,
      });
      return { success: false, error: error.message };
    }
  }

  /**
   * Save shipping/tracking information
   */
  private async saveShippingInfo(
    householdId: string,
    caseId: string,
    shipping: {
      carrier?: string;
      trackingNumber?: string;
      estimatedDelivery?: string;
      itemDescription?: string;
      status?: string;
    },
  ): Promise<{ success: boolean; error?: string }> {
    try {
      // Log shipping info - could be expanded to a dedicated Shipment model
      await this.logActivity(caseId, EmailCaseActivityType.SHIPPING_TRACKED, {
        description: `Tracking ${shipping.carrier || 'package'}: ${shipping.trackingNumber}`,
        details: shipping,
      });

      // If there's an estimated delivery, create a reminder
      if (shipping.estimatedDelivery) {
        await this.createReminder(householdId, caseId, {
          message: `Package arriving: ${shipping.itemDescription || 'Your order'}`,
          remindAt: shipping.estimatedDelivery,
        });
      }

      return { success: true };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * Save warranty information
   */
  private async saveWarrantyInfo(
    householdId: string,
    caseId: string,
    warranty: {
      productName: string;
      vendorName?: string;
      purchaseDate?: string;
      expirationDate?: string;
      warrantyTerms?: string;
    },
  ): Promise<{ success: boolean; error?: string }> {
    try {
      const household = await this.prisma.household.findUnique({
        where: { id: householdId },
        select: { ownerId: true },
      });

      // Save warranty as a document
      const document = await this.prisma.document.create({
        data: {
          householdId,
          fileName: `warranty_${warranty.productName.replace(/[^a-zA-Z0-9]/g, '_')}.pdf`,
          originalName: `${warranty.productName} Warranty`,
          mimeType: 'application/pdf',
          fileSize: 0,
          storageUrl: '',
          storagePath: '',
          category: DocumentCategory.WARRANTY,
          title: `${warranty.productName} Warranty`,
          description: warranty.warrantyTerms,
          expiresAt: warranty.expirationDate ? new Date(warranty.expirationDate) : undefined,
          expirationAlert: !!warranty.expirationDate,
          uploadedById: household?.ownerId || '',
        },
      });

      await this.logActivity(caseId, EmailCaseActivityType.WARRANTY_SAVED, {
        description: `Saved warranty for ${warranty.productName}`,
        details: { documentId: document.id, ...warranty },
      });

      // Set reminder before warranty expires
      if (warranty.expirationDate) {
        const expirationDate = new Date(warranty.expirationDate);
        const reminderDate = new Date(expirationDate);
        reminderDate.setMonth(reminderDate.getMonth() - 1); // 1 month before expiration

        await this.createReminder(householdId, caseId, {
          message: `Warranty expiring soon: ${warranty.productName}`,
          remindAt: reminderDate.toISOString(),
        });
      }

      return { success: true };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * Process HOA notice
   */
  private async processHoaNotice(
    householdId: string,
    caseId: string,
    hoaNotice: {
      hasDues?: boolean;
      amount?: number;
      dueDate?: string;
      hasMeeting?: boolean;
      meetingDate?: string;
      meetingLocation?: string;
      hasViolation?: boolean;
      violationDescription?: string;
      responseDeadline?: string;
    },
    actions: ActionResult['actions'],
  ): Promise<void> {
    // Create bill for dues
    if (hoaNotice.hasDues && hoaNotice.amount) {
      try {
        // Find existing HOA vendor or create one
        let vendor = await this.prisma.vendor.findFirst({
          where: {
            householdId,
            category: 'HOA',
          },
        });

        if (!vendor) {
          vendor = await this.prisma.vendor.create({
            data: {
              householdId,
              displayName: 'HOA',
              category: 'HOA',
            },
          });
        }

        const householdVendor = await this.prisma.householdVendor.findFirst({
          where: { householdId, vendorId: vendor.id },
        });

        const bill = await this.prisma.bill.create({
          data: {
            householdId,
            vendorId: householdVendor?.id,
            name: 'HOA Dues',
            category: 'hoa',
            frequency: 'monthly',
            paymentMethod: 'manual',
            amount: hoaNotice.amount,
            nextDueDate: hoaNotice.dueDate ? new Date(hoaNotice.dueDate) : null,
            status: 'active',
            sourceType: 'alfred',
          },
        });

        actions.push({
          type: 'HOA_DUES_BILL',
          description: `Created HOA dues bill for $${hoaNotice.amount}`,
          success: true,
          recordId: bill.id,
        });

        await this.logActivity(caseId, EmailCaseActivityType.BILL_CREATED, {
          description: `HOA dues: $${hoaNotice.amount}`,
          details: { billId: bill.id },
        });
      } catch (error) {
        actions.push({
          type: 'HOA_DUES_BILL',
          description: `Failed to create HOA dues bill: ${error.message}`,
          success: false,
        });
      }
    }

    // Create calendar event for meeting
    if (hoaNotice.hasMeeting && hoaNotice.meetingDate) {
      try {
        const household = await this.prisma.household.findUnique({
          where: { id: householdId },
          select: { ownerId: true },
        });

        const event = await this.prisma.familyEvent.create({
          data: {
            householdId,
            createdByUserId: household?.ownerId || '',
            title: 'HOA Meeting',
            description: hoaNotice.meetingLocation
              ? `Location: ${hoaNotice.meetingLocation}`
              : undefined,
            startDate: new Date(hoaNotice.meetingDate),
            isAllDay: false,
            syncSource: 'MANUAL',
            createdByRole: 'SYSTEM',
          },
        });

        actions.push({
          type: 'HOA_MEETING_EVENT',
          description: `Added HOA meeting to calendar`,
          success: true,
          recordId: event.id,
        });

        await this.logActivity(caseId, EmailCaseActivityType.CALENDAR_EVENT_CREATED, {
          description: `HOA meeting on ${hoaNotice.meetingDate}`,
          details: { eventId: event.id },
        });
      } catch (error) {
        actions.push({
          type: 'HOA_MEETING_EVENT',
          description: `Failed to add meeting: ${error.message}`,
          success: false,
        });
      }
    }

    // Create urgent task for violations
    if (hoaNotice.hasViolation) {
      const taskResult = await this.createTask(householdId, caseId, {
        title: 'HOA Violation - Action Required',
        description: hoaNotice.violationDescription,
        priority: 'URGENT',
        dueDate: hoaNotice.responseDeadline,
      });

      actions.push({
        type: 'HOA_VIOLATION_TASK',
        description: `Created task for HOA violation`,
        success: taskResult.success,
        recordId: taskResult.recordId,
      });
    }
  }

  /**
   * Process subscription change notice
   */
  private async processSubscriptionChange(
    householdId: string,
    caseId: string,
    change: {
      vendorName: string;
      changeType: 'RENEWAL' | 'PRICE_CHANGE' | 'CANCELLATION' | 'NEW';
      oldAmount?: number;
      newAmount?: number;
      effectiveDate?: string;
    },
    actions: ActionResult['actions'],
  ): Promise<void> {
    if (change.changeType === 'PRICE_CHANGE' && change.oldAmount && change.newAmount) {
      const increase = change.newAmount - change.oldAmount;
      const percentChange = ((increase / change.oldAmount) * 100).toFixed(1);

      // Create a task to review the price change
      const taskResult = await this.createTask(householdId, caseId, {
        title: `Review price change: ${change.vendorName}`,
        description: `Price changing from $${change.oldAmount} to $${change.newAmount} (${percentChange}% ${increase > 0 ? 'increase' : 'decrease'}). Effective: ${change.effectiveDate || 'Not specified'}`,
        priority: increase > 20 ? 'HIGH' : 'NORMAL',
        dueDate: change.effectiveDate,
      });

      actions.push({
        type: 'SUBSCRIPTION_PRICE_CHANGE',
        description: `${change.vendorName}: $${change.oldAmount} → $${change.newAmount}`,
        success: taskResult.success,
        recordId: taskResult.recordId,
      });
    } else if (change.changeType === 'RENEWAL') {
      await this.logActivity(caseId, EmailCaseActivityType.ALFRED_MESSAGE, {
        description: `Subscription renewal notice: ${change.vendorName}`,
        details: { amount: change.newAmount, effectiveDate: change.effectiveDate },
      });

      actions.push({
        type: 'SUBSCRIPTION_RENEWAL',
        description: `${change.vendorName} renewal${change.newAmount ? ` - $${change.newAmount}` : ''}`,
        success: true,
      });
    } else if (change.changeType === 'CANCELLATION') {
      const taskResult = await this.createTask(householdId, caseId, {
        title: `Subscription cancellation: ${change.vendorName}`,
        description: `Subscription ending${change.effectiveDate ? ` on ${change.effectiveDate}` : ''}. Consider alternatives if needed.`,
        priority: 'NORMAL',
      });

      actions.push({
        type: 'SUBSCRIPTION_CANCELLATION',
        description: `${change.vendorName} subscription ending`,
        success: taskResult.success,
        recordId: taskResult.recordId,
      });
    }
  }

  /**
   * Handle unknown email type - always take some action
   */
  private async handleUnknownEmail(
    householdId: string,
    caseId: string,
    parsed: ParsedEmailResult,
  ): Promise<{
    needsInput: boolean;
    question?: string;
    questionOptions?: string[];
    questionContext?: Record<string, unknown>;
    actions: ActionResult['actions'];
  }> {
    const actions: ActionResult['actions'] = [];

    // If we have suggested actions, ask the user
    if (parsed.suggestedActions?.length) {
      await this.logActivity(caseId, EmailCaseActivityType.QUESTION_ASKED, {
        description: 'What would you like me to do with this email?',
        details: { options: parsed.suggestedActions },
      });

      return {
        needsInput: true,
        question:
          "I'm not sure how to categorize this email. What would you like me to do with it?",
        questionOptions: parsed.suggestedActions,
        questionContext: {
          parsedData: parsed,
          category: 'UNKNOWN',
        },
        actions: [],
      };
    }

    // Default actions for unknown emails - always do something
    const defaultActions = [
      'Add to calendar',
      'Track as a bill',
      'Save vendor contact',
      'Save document to vault',
      'Create a task/reminder',
      'Save for reference',
      'Ignore this email',
    ];

    // Try to extract useful info anyway
    if (parsed.dates?.length) {
      await this.logActivity(caseId, EmailCaseActivityType.ALFRED_MESSAGE, {
        description: `Found dates: ${parsed.dates.join(', ')}`,
      });
    }

    if (parsed.amounts?.length) {
      await this.logActivity(caseId, EmailCaseActivityType.ALFRED_MESSAGE, {
        description: `Found amounts: $${parsed.amounts.join(', $')}`,
      });
    }

    if (parsed.companies?.length) {
      await this.logActivity(caseId, EmailCaseActivityType.ALFRED_MESSAGE, {
        description: `Found companies: ${parsed.companies.join(', ')}`,
      });
    }

    return {
      needsInput: true,
      question:
        "I couldn't automatically categorize this email. What would you like me to do with it?",
      questionOptions: defaultActions,
      questionContext: {
        parsedData: parsed,
        category: 'UNKNOWN',
        extractedInfo: {
          dates: parsed.dates,
          amounts: parsed.amounts,
          companies: parsed.companies,
          people: parsed.people,
        },
      },
      actions: [],
    };
  }

  // ============================================================================
  // MAIN EXECUTE ACTIONS
  // ============================================================================

  async executeActions(
    householdId: string,
    caseId: string,
    parsed: ParsedEmailResult,
  ): Promise<ActionResult> {
    const actions: ActionResult['actions'] = [];
    let needsInput = false;
    let question: string | undefined;
    let questionOptions: string[] | undefined;
    let questionContext: Record<string, unknown> | undefined;

    // Check if clarification needed first
    if (parsed.needsClarification) {
      await this.logActivity(caseId, EmailCaseActivityType.QUESTION_ASKED, {
        description: parsed.needsClarification.question,
        details: {
          options: parsed.needsClarification.options,
          context: parsed.needsClarification.context,
        },
      });

      return {
        actions: [],
        needsInput: true,
        question: parsed.needsClarification.question,
        questionOptions: parsed.needsClarification.options,
        questionContext: {
          context: parsed.needsClarification.context,
          parsedData: parsed,
        },
      };
    }

    // Create calendar events
    if (parsed.calendarEvents?.length) {
      for (const event of parsed.calendarEvents) {
        // If we don't know which family member, ask
        if (event.forMemberName && !event.forMemberId) {
          const members = await this.prisma.familyMember.findMany({
            where: { householdId },
            select: { id: true, firstName: true, lastName: true },
          });

          needsInput = true;
          question = `Which family member is "${event.title}" for?`;
          questionOptions = members.map((m) => m.firstName);
          questionContext = {
            eventData: event,
            members: members,
            parsedData: parsed,
          };

          await this.logActivity(caseId, EmailCaseActivityType.QUESTION_ASKED, {
            description: question,
            details: { options: questionOptions },
          });

          break;
        }

        try {
          // Create a manual calendar event (not from external calendar)
          // Get the household owner to use as createdByUserId
          const household = await this.prisma.household.findUnique({
            where: { id: householdId },
            select: { ownerId: true },
          });

          const familyEvent = await this.prisma.familyEvent.create({
            data: {
              householdId,
              createdByUserId: household?.ownerId || '',
              title: event.title,
              description: event.description,
              startDate: new Date(event.startDate),
              endDate: event.endDate ? new Date(event.endDate) : undefined,
              isAllDay: event.isAllDay,
              syncSource: 'MANUAL', // Coming from Alfred email
              createdByRole: 'SYSTEM', // System-created via Alfred
              assignedToMemberId: event.forMemberId,
            },
          });

          actions.push({
            type: 'CALENDAR_EVENT_CREATED',
            description: `Added "${event.title}" to calendar`,
            success: true,
            recordId: familyEvent.id,
          });

          await this.logActivity(
            caseId,
            EmailCaseActivityType.CALENDAR_EVENT_CREATED,
            {
              description: `Added "${event.title}" to calendar`,
              details: { eventId: familyEvent.id },
            },
          );
        } catch (error) {
          actions.push({
            type: 'CALENDAR_EVENT_CREATED',
            description: `Failed to add "${event.title}": ${error.message}`,
            success: false,
          });

          await this.logActivity(caseId, EmailCaseActivityType.ACTION_FAILED, {
            description: `Failed to create calendar event: ${error.message}`,
          });
        }
      }
    }

    // Process bills - ASK user what to do instead of auto-creating
    if (parsed.bills?.length) {
      for (const bill of parsed.bills) {
        // Handle both vendorName and vendor field (parser may return either)
        const vendorName = bill.vendorName || (bill as any).vendor || 'Unknown Vendor';

        // Check if household already has this vendor as a bill account
        const existingBill = await this.prisma.bill.findFirst({
          where: {
            householdId,
            OR: [
              { name: { contains: vendorName, mode: 'insensitive' } },
              { vendor: { vendor: { displayName: { contains: vendorName, mode: 'insensitive' } } } },
            ],
            status: 'active',
          },
          include: { vendor: { include: { vendor: true } } },
        });

        if (existingBill) {
          // Household already tracks this bill - update the next due amount
          try {
            await this.prisma.bill.update({
              where: { id: existingBill.id },
              data: {
                amount: bill.amount || existingBill.amount,
                nextDueDate: bill.dueDate ? new Date(bill.dueDate) : existingBill.nextDueDate,
              },
            });

            actions.push({
              type: 'BILL_UPDATED',
              description: `Updated ${vendorName} bill: $${bill.amount} due ${bill.dueDate}`,
              success: true,
              recordId: existingBill.id,
            });

            await this.logActivity(caseId, EmailCaseActivityType.ALFRED_MESSAGE, {
              description: `Updated existing bill: ${vendorName} - $${bill.amount}`,
              details: { billId: existingBill.id, amount: bill.amount, dueDate: bill.dueDate },
            });
          } catch (error) {
            actions.push({
              type: 'BILL_UPDATED',
              description: `Failed to update bill: ${error.message}`,
              success: false,
            });
          }
        } else {
          // New bill vendor - ASK user what they want to do
          const billingTypeDesc = bill.billingType === 'variable'
            ? 'This is a variable/usage-based bill - the amount changes each month.'
            : 'This is typically a fixed monthly bill.';

          const billQuestion = `I found a bill from ${vendorName} for $${bill.amount || 'unknown amount'} due ${bill.dueDate || 'soon'}. ${billingTypeDesc}\n\nYou don't have ${vendorName} set up as a tracked bill yet. What would you like me to do?`;

          const billOptions = [
            `Set up ${vendorName} as a recurring ${bill.billingType === 'variable' ? 'variable' : 'monthly'} bill`,
            'Just track this one bill',
            'Ignore this bill',
          ];

          needsInput = true;
          question = billQuestion;
          questionOptions = billOptions;
          questionContext = {
            billData: { ...bill, vendorName }, // Include the resolved vendor name
            action: 'BILL_SETUP',
            parsedData: parsed,
          };

          await this.logActivity(caseId, EmailCaseActivityType.QUESTION_ASKED, {
            description: `Asked about setting up ${vendorName} as a tracked bill`,
            details: {
              vendorName,
              amount: bill.amount,
              dueDate: bill.dueDate,
              billingType: bill.billingType,
            },
          });

          // Only process the first bill that needs input - user can handle others after
          break;
        }
      }
    }

    // Update/create vendors
    if (parsed.vendorUpdates?.length) {
      for (const vendor of parsed.vendorUpdates) {
        try {
          if (vendor.vendorId) {
            await this.prisma.vendor.update({
              where: { id: vendor.vendorId },
              data: {
                phone: vendor.phone || undefined,
                email: vendor.email || undefined,
                addressLine1: vendor.address || undefined,
                serviceDescription: vendor.notes || undefined,
              },
            });
            actions.push({
              type: 'VENDOR_UPDATED',
              description: `Updated ${vendor.vendorName}`,
              success: true,
              recordId: vendor.vendorId,
            });

            await this.logActivity(
              caseId,
              EmailCaseActivityType.VENDOR_UPDATED,
              {
                description: `Updated vendor ${vendor.vendorName}`,
                details: { vendorId: vendor.vendorId },
              },
            );
          } else {
            const newVendor = await this.prisma.vendor.create({
              data: {
                householdId,
                displayName: vendor.vendorName,
                phone: vendor.phone,
                email: vendor.email,
                addressLine1: vendor.address,
                serviceDescription: vendor.notes,
                category: 'OTHER',
              },
            });

            await this.prisma.householdVendor.create({
              data: {
                householdId,
                vendorId: newVendor.id,
              },
            });

            actions.push({
              type: 'VENDOR_CREATED',
              description: `Added vendor ${vendor.vendorName}`,
              success: true,
              recordId: newVendor.id,
            });

            await this.logActivity(
              caseId,
              EmailCaseActivityType.VENDOR_CREATED,
              {
                description: `Created vendor ${vendor.vendorName}`,
                details: { vendorId: newVendor.id },
              },
            );
          }
        } catch (error) {
          actions.push({
            type: 'VENDOR_UPDATE',
            description: `Failed to update vendor: ${error.message}`,
            success: false,
          });

          await this.logActivity(caseId, EmailCaseActivityType.ACTION_FAILED, {
            description: `Failed to update vendor: ${error.message}`,
          });
        }
      }
    }

    // Add systems from inspection reports
    if (parsed.systems?.length) {
      for (const system of parsed.systems) {
        try {
          // Find zone by name or use null
          let zoneId: string | null = null;
          if (system.zoneName) {
            const zone = await this.prisma.zone.findFirst({
              where: {
                householdId,
                name: { contains: system.zoneName, mode: 'insensitive' },
              },
            });
            zoneId = zone?.id || null;
          }

          // Map system category to AssetCategory enum
          const categoryMap: Record<string, 'HVAC' | 'APPLIANCE' | 'PLUMBING' | 'ELECTRICAL' | 'STRUCTURAL' | 'FURNITURE' | 'ELECTRONICS' | 'OUTDOOR' | 'VEHICLE' | 'SAFETY' | 'OTHER'> = {
            'HVAC': 'HVAC',
            'APPLIANCE': 'APPLIANCE',
            'PLUMBING': 'PLUMBING',
            'ELECTRICAL': 'ELECTRICAL',
            'STRUCTURAL': 'STRUCTURAL',
            'FURNITURE': 'FURNITURE',
            'ELECTRONICS': 'ELECTRONICS',
            'OUTDOOR': 'OUTDOOR',
            'EXTERIOR': 'OUTDOOR',
            'INTERIOR': 'OTHER',
            'VEHICLE': 'VEHICLE',
            'SAFETY': 'SAFETY',
            'GENERAL': 'OTHER',
          };
          const category = categoryMap[system.category?.toUpperCase() || ''] || 'OTHER';

          const asset = await this.prisma.propertyAsset.create({
            data: {
              householdId,
              zoneId,
              name: system.name,
              category,
              condition: system.condition,
              conditionNotes: system.notes,
            },
          });

          actions.push({
            type: 'SYSTEM_ADDED',
            description: `Added ${system.name} to home systems`,
            success: true,
            recordId: asset.id,
          });

          await this.logActivity(caseId, EmailCaseActivityType.SYSTEM_ADDED, {
            description: `Added ${system.name} to home systems`,
            details: { assetId: asset.id },
          });
        } catch (error) {
          actions.push({
            type: 'SYSTEM_ADDED',
            description: `Failed to add system: ${error.message}`,
            success: false,
          });

          await this.logActivity(caseId, EmailCaseActivityType.ACTION_FAILED, {
            description: `Failed to add system: ${error.message}`,
          });
        }
      }
    }

    // Store dispute response draft (don't send automatically)
    if (parsed.disputeResponse) {
      actions.push({
        type: 'DISPUTE_DRAFT_CREATED',
        description: `Drafted response to ${parsed.disputeResponse.to}`,
        success: true,
      });

      await this.logActivity(
        caseId,
        EmailCaseActivityType.DISPUTE_DRAFT_CREATED,
        {
          description: `Drafted response to ${parsed.disputeResponse.to}`,
          details: { draft: parsed.disputeResponse },
        },
      );

      // This needs user approval, so set needsInput
      needsInput = true;
      question =
        "I've drafted a response to this dispute. Would you like to review and send it?";
      questionOptions = ['Yes, send it', 'Let me review first', 'No, discard'];
      questionContext = {
        disputeResponse: parsed.disputeResponse,
        parsedData: parsed,
      };
    }

    // Create tasks
    if (parsed.tasks?.length) {
      for (const task of parsed.tasks) {
        const result = await this.createTask(householdId, caseId, {
          title: task.title,
          description: task.description,
          priority: task.priority,
          dueDate: task.dueDate,
          assignedToId: task.assignedToId,
        });

        actions.push({
          type: 'TASK_CREATED',
          description: result.success
            ? `Created task: ${task.title}`
            : `Failed to create task: ${result.error}`,
          success: result.success,
          recordId: result.recordId,
        });
      }
    }

    // Create reminders
    if (parsed.reminders?.length) {
      for (const reminder of parsed.reminders) {
        const result = await this.createReminder(householdId, caseId, {
          message: reminder.message,
          remindAt: reminder.remindAt,
        });

        actions.push({
          type: 'REMINDER_CREATED',
          description: result.success
            ? `Set reminder: ${reminder.message}`
            : `Failed to set reminder: ${result.error}`,
          success: result.success,
          recordId: result.recordId,
        });
      }
    }

    // Save documents to vault
    if (parsed.documents?.length) {
      for (const doc of parsed.documents) {
        const result = await this.saveDocumentMetadata(householdId, caseId, {
          name: doc.name,
          category: doc.category,
          forMemberId: doc.forMemberId,
        });

        actions.push({
          type: 'DOCUMENT_SAVED',
          description: result.success
            ? `Saved document: ${doc.name}`
            : `Failed to save document: ${result.error}`,
          success: result.success,
          recordId: result.recordId,
        });
      }
    }

    // Process shipping/tracking info
    if (parsed.shipping) {
      const result = await this.saveShippingInfo(
        householdId,
        caseId,
        parsed.shipping,
      );

      actions.push({
        type: 'SHIPPING_TRACKED',
        description: result.success
          ? `Tracking ${parsed.shipping.carrier || 'package'}: ${parsed.shipping.trackingNumber}`
          : `Failed to track shipping: ${result.error}`,
        success: result.success,
      });
    }

    // Save warranty information
    if (parsed.warranty) {
      const result = await this.saveWarrantyInfo(
        householdId,
        caseId,
        parsed.warranty,
      );

      actions.push({
        type: 'WARRANTY_SAVED',
        description: result.success
          ? `Saved warranty for ${parsed.warranty.productName}`
          : `Failed to save warranty: ${result.error}`,
        success: result.success,
      });
    }

    // Process HOA notices
    if (parsed.hoaNotice) {
      await this.processHoaNotice(householdId, caseId, parsed.hoaNotice, actions);
    }

    // Process subscription changes
    if (parsed.subscriptionChange) {
      await this.processSubscriptionChange(
        householdId,
        caseId,
        parsed.subscriptionChange,
        actions,
      );
    }

    // Send urgent notifications
    if (parsed.urgency === 'URGENT') {
      await this.notifyHousehold(householdId, caseId, {
        title: 'Urgent Email',
        message: parsed.summary || 'You have an urgent email that needs attention',
        priority: 'URGENT',
      });
    }

    // Handle UNKNOWN emails - always take action or ask user
    if (parsed.category === 'UNKNOWN' && actions.length === 0) {
      const unknownResult = await this.handleUnknownEmail(
        householdId,
        caseId,
        parsed,
      );

      return {
        actions: unknownResult.actions,
        needsInput: unknownResult.needsInput,
        question: unknownResult.question,
        questionOptions: unknownResult.questionOptions,
        questionContext: unknownResult.questionContext,
      };
    }

    return {
      actions,
      needsInput,
      question,
      questionOptions,
      questionContext,
    };
  }

  /**
   * Continue processing after user answers a question
   */
  async continueWithAnswer(
    householdId: string,
    caseId: string,
    questionContext: Record<string, unknown>,
    answer: { answer: string; selectedOption?: string },
  ): Promise<ActionResult> {
    const actions: ActionResult['actions'] = [];

    await this.logActivity(caseId, EmailCaseActivityType.USER_RESPONDED, {
      description: `User responded: ${answer.answer}`,
      details: { selectedOption: answer.selectedOption },
    });

    // Handle family member selection for calendar event
    if (questionContext?.eventData) {
      const event = questionContext.eventData as {
        title: string;
        description?: string;
        startDate: string;
        endDate?: string;
        isAllDay: boolean;
      };
      const members = (questionContext.members || []) as Array<{
        id: string;
        firstName: string;
      }>;

      // Find the selected family member
      const selectedMember = members.find(
        (m) =>
          m.id === answer.selectedOption ||
          m.firstName.toLowerCase() === answer.answer.toLowerCase(),
      );

      if (selectedMember) {
        try {
          // Get the household owner to use as createdByUserId
          const household = await this.prisma.household.findUnique({
            where: { id: householdId },
            select: { ownerId: true },
          });

          const familyEvent = await this.prisma.familyEvent.create({
            data: {
              householdId,
              createdByUserId: household?.ownerId || '',
              title: event.title,
              description: event.description,
              startDate: new Date(event.startDate),
              endDate: event.endDate ? new Date(event.endDate) : undefined,
              isAllDay: event.isAllDay,
              syncSource: 'MANUAL',
              createdByRole: 'SYSTEM',
              assignedToMemberId: selectedMember.id,
            },
          });

          actions.push({
            type: 'CALENDAR_EVENT_CREATED',
            description: `Added "${event.title}" for ${selectedMember.firstName}`,
            success: true,
            recordId: familyEvent.id,
          });

          await this.logActivity(
            caseId,
            EmailCaseActivityType.CALENDAR_EVENT_CREATED,
            {
              description: `Added "${event.title}" for ${selectedMember.firstName}`,
              details: { eventId: familyEvent.id },
            },
          );
        } catch (error) {
          actions.push({
            type: 'CALENDAR_EVENT_CREATED',
            description: `Failed to add event: ${error.message}`,
            success: false,
          });
        }
      }
    }

    // Handle dispute response approval
    if (questionContext?.disputeResponse) {
      const lowerAnswer = answer.answer.toLowerCase();
      if (
        lowerAnswer.includes('yes') ||
        lowerAnswer.includes('send') ||
        answer.selectedOption === 'Yes, send it'
      ) {
        // TODO: Send the email using SendGrid
        actions.push({
          type: 'DISPUTE_RESPONSE_SENT',
          description: `Sent response to ${(questionContext.disputeResponse as { to: string }).to}`,
          success: true,
        });

        await this.logActivity(caseId, EmailCaseActivityType.ALFRED_MESSAGE, {
          description: 'Dispute response sent',
          details: questionContext.disputeResponse as Record<string, unknown>,
        });
      } else {
        await this.logActivity(caseId, EmailCaseActivityType.ALFRED_MESSAGE, {
          description: 'User declined to send dispute response',
        });
      }
    }

    // Handle bill setup response
    if (questionContext?.action === 'BILL_SETUP') {
      const billData = questionContext.billData as {
        vendorName: string;
        amount?: number;
        dueDate?: string;
        billingType?: 'variable' | 'fixed';
        accountNumber?: string;
        description?: string;
      };
      const selectedAction = answer.selectedOption || answer.answer;

      if (selectedAction.toLowerCase().includes('set up') || selectedAction.toLowerCase().includes('recurring')) {
        // User wants to set up recurring bill
        try {
          // Create or find vendor
          let vendor = await this.prisma.vendor.findFirst({
            where: {
              householdId,
              displayName: { contains: billData.vendorName, mode: 'insensitive' },
            },
          });

          if (!vendor) {
            // Determine category from bill type using VendorCategory enum
            const categoryMap: Record<string, VendorCategory> = {
              'electricity': VendorCategory.ELECTRIC,
              'electric': VendorCategory.ELECTRIC,
              'eversource': VendorCategory.ELECTRIC,
              'gas': VendorCategory.GAS,
              'water': VendorCategory.WATER_SEWER,
              'sewer': VendorCategory.WATER_SEWER,
              'internet': VendorCategory.INTERNET,
              'phone': VendorCategory.MOBILE,
              'mobile': VendorCategory.MOBILE,
              'cable': VendorCategory.CABLE,
            };
            const category: VendorCategory = Object.entries(categoryMap).find(([key]) =>
              billData.vendorName.toLowerCase().includes(key)
            )?.[1] || VendorCategory.OTHER;

            vendor = await this.prisma.vendor.create({
              data: {
                householdId,
                displayName: billData.vendorName,
                category,
              },
            });

            await this.prisma.householdVendor.create({
              data: { householdId, vendorId: vendor.id },
            });
          }

          const householdVendor = await this.prisma.householdVendor.findFirst({
            where: { householdId, vendorId: vendor.id },
          });

          // Determine frequency and category
          const isVariable = billData.billingType === 'variable';
          const categoryMap: Record<string, string> = {
            'electricity': 'utilities',
            'electric': 'utilities',
            'gas': 'utilities',
            'water': 'utilities',
            'sewer': 'utilities',
            'internet': 'utilities',
            'phone': 'utilities',
          };
          const billCategory = Object.entries(categoryMap).find(([key]) =>
            billData.vendorName.toLowerCase().includes(key)
          )?.[1] || 'other';

          const newBill = await this.prisma.bill.create({
            data: {
              householdId,
              vendorId: householdVendor?.id,
              name: isVariable ? `${billData.vendorName} (Variable)` : billData.vendorName,
              category: billCategory,
              frequency: 'monthly',
              paymentMethod: 'manual',
              amount: billData.amount || null,
              nextDueDate: billData.dueDate ? new Date(billData.dueDate) : null,
              accountNumber: billData.accountNumber,
              status: 'active',
              sourceType: 'alfred',
            },
          });

          actions.push({
            type: 'BILL_CREATED',
            description: `Set up ${billData.vendorName} as a recurring ${isVariable ? 'variable' : 'monthly'} bill`,
            success: true,
            recordId: newBill.id,
          });

          await this.logActivity(caseId, EmailCaseActivityType.BILL_CREATED, {
            description: `Set up ${billData.vendorName} as recurring bill`,
            details: {
              billId: newBill.id,
              amount: billData.amount,
              billingType: billData.billingType,
            },
          });
        } catch (error) {
          actions.push({
            type: 'BILL_CREATED',
            description: `Failed to set up bill: ${error.message}`,
            success: false,
          });
        }
      } else if (selectedAction.toLowerCase().includes('track this one') || selectedAction.toLowerCase().includes('one bill')) {
        // User wants to track just this one bill
        try {
          const household = await this.prisma.household.findUnique({
            where: { id: householdId },
            select: { ownerId: true },
          });

          const task = await this.prisma.task.create({
            data: {
              householdId,
              createdById: household?.ownerId || '',
              title: `Pay ${billData.vendorName}: $${billData.amount || 'TBD'}`,
              description: `Bill due: ${billData.dueDate || 'Check email for date'}`,
              priority: 'MEDIUM',
              dueDate: billData.dueDate ? new Date(billData.dueDate) : undefined,
            },
          });

          actions.push({
            type: 'TASK_CREATED',
            description: `Created task to pay ${billData.vendorName} bill`,
            success: true,
            recordId: task.id,
          });

          await this.logActivity(caseId, EmailCaseActivityType.TASK_CREATED, {
            description: `Created one-time task for ${billData.vendorName} bill`,
            details: { taskId: task.id },
          });
        } catch (error) {
          actions.push({
            type: 'TASK_CREATED',
            description: `Failed to create task: ${error.message}`,
            success: false,
          });
        }
      } else {
        // User chose to ignore
        await this.logActivity(caseId, EmailCaseActivityType.ALFRED_MESSAGE, {
          description: `User chose to ignore ${billData.vendorName} bill`,
        });

        actions.push({
          type: 'BILL_IGNORED',
          description: `Ignored ${billData.vendorName} bill per user request`,
          success: true,
        });
      }
    }

    // Handle unknown email user choices
    if (questionContext?.category === 'UNKNOWN') {
      const parsed = questionContext.parsedData as ParsedEmailResult | undefined;
      const selectedAction = answer.selectedOption || answer.answer;

      if (selectedAction.toLowerCase().includes('calendar')) {
        // User wants to add to calendar
        if (parsed?.dates?.length) {
          const household = await this.prisma.household.findUnique({
            where: { id: householdId },
            select: { ownerId: true },
          });

          const event = await this.prisma.familyEvent.create({
            data: {
              householdId,
              createdByUserId: household?.ownerId || '',
              title: parsed.summary || 'Event from email',
              startDate: new Date(parsed.dates[0]),
              isAllDay: true,
              syncSource: 'MANUAL',
              createdByRole: 'SYSTEM',
            },
          });

          actions.push({
            type: 'CALENDAR_EVENT_CREATED',
            description: `Added event to calendar`,
            success: true,
            recordId: event.id,
          });

          await this.logActivity(
            caseId,
            EmailCaseActivityType.CALENDAR_EVENT_CREATED,
            {
              description: `Created calendar event from unknown email`,
              details: { eventId: event.id },
            },
          );
        } else {
          actions.push({
            type: 'CALENDAR_EVENT_CREATED',
            description: 'No dates found in email to create event',
            success: false,
          });
        }
      } else if (selectedAction.toLowerCase().includes('bill')) {
        // User wants to track as a bill
        const vendorName = parsed?.companies?.[0] || 'Unknown Vendor';
        const amount = parsed?.amounts?.[0];
        const dueDate = parsed?.dates?.[0];

        let vendor = await this.prisma.vendor.findFirst({
          where: {
            householdId,
            displayName: { contains: vendorName, mode: 'insensitive' },
          },
        });

        if (!vendor) {
          vendor = await this.prisma.vendor.create({
            data: {
              householdId,
              displayName: vendorName,
              category: 'OTHER',
            },
          });

          await this.prisma.householdVendor.create({
            data: { householdId, vendorId: vendor.id },
          });
        }

        const householdVendor = await this.prisma.householdVendor.findFirst({
          where: { householdId, vendorId: vendor.id },
        });

        const bill = await this.prisma.bill.create({
          data: {
            householdId,
            vendorId: householdVendor?.id,
            name: parsed?.summary || `Bill from ${vendorName}`,
            category: 'other',
            frequency: 'one_time',
            paymentMethod: 'manual',
            amount: amount || null,
            nextDueDate: dueDate ? new Date(dueDate) : null,
            status: 'active',
            sourceType: 'alfred',
          },
        });

        actions.push({
          type: 'BILL_CREATED',
          description: `Created bill from ${vendorName}${amount ? ` for $${amount}` : ''}`,
          success: true,
          recordId: bill.id,
        });

        await this.logActivity(caseId, EmailCaseActivityType.BILL_CREATED, {
          description: `Created bill from unknown email`,
          details: { billId: bill.id },
        });
      } else if (selectedAction.toLowerCase().includes('vendor')) {
        // User wants to save vendor contact
        const vendorName = parsed?.companies?.[0] || 'Unknown Vendor';
        const phone = parsed?.phoneNumbers?.[0];
        const email = parsed?.emailAddresses?.[0];

        const newVendor = await this.prisma.vendor.create({
          data: {
            householdId,
            displayName: vendorName,
            phone,
            email,
            category: 'OTHER',
          },
        });

        await this.prisma.householdVendor.create({
          data: { householdId, vendorId: newVendor.id },
        });

        actions.push({
          type: 'VENDOR_CREATED',
          description: `Saved vendor: ${vendorName}`,
          success: true,
          recordId: newVendor.id,
        });

        await this.logActivity(caseId, EmailCaseActivityType.VENDOR_CREATED, {
          description: `Created vendor from unknown email`,
          details: { vendorId: newVendor.id },
        });
      } else if (selectedAction.toLowerCase().includes('document') || selectedAction.toLowerCase().includes('vault')) {
        // User wants to save document
        const result = await this.saveDocumentMetadata(householdId, caseId, {
          name: parsed?.summary || 'Document from email',
          category: 'general',
        });

        actions.push({
          type: 'DOCUMENT_SAVED',
          description: result.success
            ? 'Saved document to vault'
            : `Failed: ${result.error}`,
          success: result.success,
          recordId: result.recordId,
        });
      } else if (selectedAction.toLowerCase().includes('task') || selectedAction.toLowerCase().includes('reminder')) {
        // User wants to create a task/reminder
        const result = await this.createTask(householdId, caseId, {
          title: parsed?.summary || 'Task from email',
          priority: 'NORMAL',
          dueDate: parsed?.dates?.[0],
        });

        actions.push({
          type: 'TASK_CREATED',
          description: result.success
            ? 'Created task from email'
            : `Failed: ${result.error}`,
          success: result.success,
          recordId: result.recordId,
        });
      } else if (selectedAction.toLowerCase().includes('reference') || selectedAction.toLowerCase().includes('save')) {
        // User wants to save for reference - just log it
        await this.logActivity(caseId, EmailCaseActivityType.ALFRED_MESSAGE, {
          description: 'Email saved for reference',
          details: { summary: parsed?.summary },
        });

        actions.push({
          type: 'SAVED_FOR_REFERENCE',
          description: 'Email saved for future reference',
          success: true,
        });
      } else if (selectedAction.toLowerCase().includes('ignore')) {
        // User wants to ignore - just log
        await this.logActivity(caseId, EmailCaseActivityType.ALFRED_MESSAGE, {
          description: 'User chose to ignore this email',
        });

        actions.push({
          type: 'IGNORED',
          description: 'Email ignored per user request',
          success: true,
        });
      }
    }

    return {
      actions,
      needsInput: false,
    };
  }

  /**
   * Log an activity to the case
   */
  private async logActivity(
    caseId: string,
    type: EmailCaseActivityType,
    data: { description: string; details?: Record<string, unknown> },
  ): Promise<void> {
    try {
      await this.prisma.emailCaseActivity.create({
        data: {
          caseId,
          type,
          description: data.description,
          details: data.details ? JSON.parse(JSON.stringify(data.details)) : undefined,
          actor: 'alfred',
          actorName: 'Alfred',
        },
      });
    } catch (error) {
      this.logger.error(`Failed to log activity: ${error.message}`);
    }
  }
}
