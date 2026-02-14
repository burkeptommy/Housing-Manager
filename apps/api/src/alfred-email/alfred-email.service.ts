import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../storage/storage.service';
import { EmailParserService } from './email-parser.service';
import { EmailActionsService } from './email-actions.service';
import {
  generateCaseNumber,
  generateUniqueAlfredEmailCode,
} from './utils';
import {
  EmailCaseStatus,
  EmailCaseActivityType,
  VendorCategory,
  TaskPriority,
  DocumentCategory,
  ReminderType,
  ReminderStatus,
  ReminderChannel,
} from '@prisma/client';
import { AuthPayload } from '../firebase';

const ALFRED_EMAIL_DOMAIN =
  process.env.ALFRED_EMAIL_DOMAIN || 'alfred.havenhome.dev';

interface InboundEmailData {
  to: string;
  from: string;
  subject: string;
  text?: string;
  html?: string;
  envelope: { to: string[]; from: string };
  attachments: Array<{
    filename: string;
    type: string;
    content: string; // base64
  }>;
  messageId: string;
}

@Injectable()
export class AlfredEmailService {
  private readonly logger = new Logger(AlfredEmailService.name);

  constructor(
    private prisma: PrismaService,
    private storageService: StorageService,
    private emailParser: EmailParserService,
    private emailActions: EmailActionsService,
  ) {}

  /**
   * Process an inbound email from SendGrid webhook
   */
  async processInboundEmail(emailData: InboundEmailData) {
    this.logger.log(`Processing email: ${emailData.subject}`);

    // 1. Extract household code from "to" address
    const householdCode = this.extractHouseholdCode(emailData.to);
    if (!householdCode) {
      throw new BadRequestException('Invalid Alfred email address format');
    }

    // 2. Find household by code
    const household = await this.prisma.household.findUnique({
      where: { alfredEmailCode: householdCode },
      include: { authorizedEmails: true },
    });

    if (!household) {
      this.logger.warn(`No household found for code: ${householdCode}`);
      throw new BadRequestException('Invalid household code');
    }

    // 3. Verify sender is authorized
    const senderEmail = this.extractEmailAddress(emailData.from);
    const isAuthorized = await this.isEmailAuthorized(
      household.id,
      senderEmail,
    );

    // Generate case number for this email
    const caseNumber = await generateCaseNumber(this.prisma);
    const messageId = emailData.messageId || `msg_${Date.now()}`;

    // 4. Create the email case
    const emailCase = await this.prisma.emailCase.create({
      data: {
        householdId: household.id,
        caseNumber,
        messageId,
        fromEmail: senderEmail,
        fromName: this.extractName(emailData.from),
        subject: emailData.subject,
        bodyText: emailData.text,
        bodyHtml: emailData.html,
        receivedAt: new Date(),
        status: isAuthorized
          ? EmailCaseStatus.PROCESSING
          : EmailCaseStatus.AWAITING_INPUT,
      },
    });

    // Log case creation
    await this.prisma.emailCaseActivity.create({
      data: {
        caseId: emailCase.id,
        type: EmailCaseActivityType.CASE_CREATED,
        description: `Case ${caseNumber} created from email "${emailData.subject}"`,
        actor: 'system',
        actorName: 'System',
      },
    });

    // If not authorized, ask for authorization
    if (!isAuthorized) {
      this.logger.warn(
        `Unauthorized sender: ${senderEmail} for household ${household.id}`,
      );

      await this.prisma.emailCase.update({
        where: { id: emailCase.id },
        data: {
          pendingQuestion: `Received email from unknown sender ${senderEmail}. Would you like to authorize this email address?`,
          questionOptions: ['Yes, authorize', 'No, ignore this email'],
        },
      });

      await this.prisma.emailCaseActivity.create({
        data: {
          caseId: emailCase.id,
          type: EmailCaseActivityType.QUESTION_ASKED,
          description: `Asked about authorizing sender: ${senderEmail}`,
          actor: 'alfred',
          actorName: 'Alfred',
        },
      });

      return { caseId: emailCase.id, caseNumber, status: 'awaiting_authorization' };
    }

    // 5. Store attachments (upload to GCS)
    if (emailData.attachments?.length > 0) {
      for (const attachment of emailData.attachments) {
        const buffer = Buffer.from(attachment.content, 'base64');
        let storageUrl: string | undefined;

        try {
          const uploaded = await this.storageService.uploadBuffer(
            buffer,
            household.id,
            'email-attachments',
            attachment.filename,
            attachment.type,
          );
          storageUrl = uploaded.url;
        } catch (uploadError) {
          this.logger.warn(
            `Failed to upload attachment "${attachment.filename}" to GCS:`,
            uploadError,
          );
        }

        await this.prisma.emailAttachment.create({
          data: {
            caseId: emailCase.id,
            filename: attachment.filename,
            contentType: attachment.type,
            sizeBytes: buffer.length,
            storageUrl,
          },
        });

        await this.prisma.emailCaseActivity.create({
          data: {
            caseId: emailCase.id,
            type: EmailCaseActivityType.ATTACHMENT_PROCESSED,
            description: `Attachment "${attachment.filename}" ${storageUrl ? 'uploaded' : 'received (upload failed)'}`,
            actor: 'system',
            actorName: 'System',
          },
        });
      }
    }

    // 6. Parse email with Claude
    try {
      const parseResult = await this.emailParser.parseEmail({
        subject: emailData.subject,
        body: emailData.text || emailData.html || '',
        attachments: emailData.attachments,
        householdContext: await this.getHouseholdContext(household.id),
      });

      // Log parsing completed
      await this.prisma.emailCaseActivity.create({
        data: {
          caseId: emailCase.id,
          type: EmailCaseActivityType.EMAIL_PARSED,
          description: `Email analyzed: ${parseResult.emailType} - ${parseResult.summary}`,
          details: JSON.parse(JSON.stringify({ extractedData: parseResult })),
          actor: 'alfred',
          actorName: 'Alfred',
        },
      });

      // 7. Build suggestions - ALWAYS ask user, never auto-execute
      const suggestions = this.emailParser.buildAlfredSuggestions(
        parseResult,
        emailData.subject,
      );

      const alfredMessage = `${suggestions.greeting}\n\n${suggestions.summary}\n\nWhat would you like me to do?`;

      // 8. Update email case - ALWAYS set to AWAITING_INPUT
      await this.prisma.emailCase.update({
        where: { id: emailCase.id },
        data: {
          status: EmailCaseStatus.AWAITING_INPUT,
          summary: parseResult.summary,
          detectedIntent: parseResult.emailType,
          extractedData: JSON.parse(JSON.stringify(parseResult)),
          confidence: suggestions.confidence,
          pendingQuestion: alfredMessage,
          questionOptions: JSON.parse(JSON.stringify(suggestions.suggestedActions)),
        },
      });

      // Log that we're waiting for user input
      await this.prisma.emailCaseActivity.create({
        data: {
          caseId: emailCase.id,
          type: EmailCaseActivityType.QUESTION_ASKED,
          description: `Alfred suggested ${suggestions.suggestedActions.length - 1} action(s) and is waiting for user input`,
          actor: 'alfred',
          actorName: 'Alfred',
        },
      });

      return {
        caseId: emailCase.id,
        caseNumber,
        status: 'awaiting_input',
        suggestions,
      };
    } catch (error) {
      this.logger.error(`Failed to parse email: ${error.message}`);

      await this.prisma.emailCase.update({
        where: { id: emailCase.id },
        data: {
          status: EmailCaseStatus.AWAITING_INPUT,
          pendingQuestion:
            'I had trouble understanding this email. What would you like me to do with it?',
          questionOptions: [
            { label: 'Add to Calendar', type: 'CALENDAR', data: { title: emailData.subject } },
            { label: 'Track as Bill', type: 'BILL', data: { vendorName: emailData.subject } },
            { label: 'Save as Document', type: 'DOCUMENT', data: { name: emailData.subject, category: 'general' } },
            { label: "Have Alfred's team handle this", type: 'ESCALATE', data: { title: `Handle: ${emailData.subject}` } },
            { label: 'Something else...', type: 'CUSTOM', data: null },
          ],
        },
      });

      await this.prisma.emailCaseActivity.create({
        data: {
          caseId: emailCase.id,
          type: EmailCaseActivityType.PROCESSING_ERROR,
          description: `Error parsing email: ${error.message}`,
          actor: 'system',
          actorName: 'System',
        },
      });

      return { caseId: emailCase.id, caseNumber, status: 'awaiting_input', error: error.message };
    }
  }

  /**
   * Extract household code from {code}@alfred.havenhome.dev
   */
  private extractHouseholdCode(toAddress: string): string | null {
    // Handle format: abc123@alfred.havenhome.dev or "Alfred <abc123@alfred.havenhome.dev>"
    const match = toAddress.match(
      /<?([a-zA-Z0-9]+)@alfred\.havenhome\.dev>?/i,
    );
    return match ? match[1] : null;
  }

  /**
   * Extract email address from "Name <email@domain.com>" format
   */
  private extractEmailAddress(from: string): string {
    const match = from.match(/<([^>]+)>/);
    return match ? match[1].toLowerCase() : from.toLowerCase().trim();
  }

  /**
   * Extract name from "Name <email@domain.com>" format
   */
  private extractName(from: string): string | null {
    const match = from.match(/^([^<]+)</);
    return match ? match[1].trim() : null;
  }

  /**
   * Check if sender email is authorized for this household
   */
  private async isEmailAuthorized(
    householdId: string,
    email: string,
  ): Promise<boolean> {
    // Check authorized emails list
    const authorized = await this.prisma.authorizedEmail.findFirst({
      where: {
        householdId,
        email: email.toLowerCase(),
      },
    });
    if (authorized) return true;

    // Check household members
    const member = await this.prisma.householdMember.findFirst({
      where: {
        householdId,
        user: { email: email.toLowerCase() },
      },
    });
    if (member) return true;

    // Check family members
    const familyMember = await this.prisma.familyMember.findFirst({
      where: {
        householdId,
        email: email.toLowerCase(),
      },
    });
    if (familyMember) return true;

    return false;
  }

  /**
   * Get context about household for better parsing
   */
  private async getHouseholdContext(householdId: string) {
    const [members, familyMembers, vendors, systems, bills] = await Promise.all([
      this.prisma.householdMember.findMany({
        where: { householdId },
        select: {
          id: true,
          role: true,
          user: { select: { firstName: true, lastName: true } },
        },
      }),
      this.prisma.familyMember.findMany({
        where: { householdId },
        select: { id: true, firstName: true, lastName: true, relationship: true },
      }),
      this.prisma.householdVendor.findMany({
        where: { householdId },
        include: {
          vendor: { select: { id: true, displayName: true, category: true } },
        },
      }),
      this.prisma.propertyAsset.findMany({
        where: { householdId },
        select: { id: true, name: true, category: true },
      }),
      this.prisma.bill.findMany({
        where: { householdId, status: 'active' },
        include: {
          vendor: {
            include: { vendor: { select: { displayName: true } } },
          },
        },
      }),
    ]);

    return {
      members: members.map((m) => ({
        id: m.id,
        firstName: m.user.firstName || '',
        lastName: m.user.lastName || '',
        type: m.role,
      })),
      children: familyMembers
        .filter((m) => m.relationship === 'CHILD')
        .map((m) => ({
          id: m.id,
          firstName: m.firstName,
          lastName: m.lastName || '',
        })),
      vendors: vendors.map((v) => ({
        id: v.vendor.id,
        displayName: v.vendor.displayName,
        category: v.vendor.category,
      })),
      systems: systems.map((s) => ({
        id: s.id,
        name: s.name,
        category: s.category,
      })),
      existingBills: bills.map((b) => ({
        id: b.id,
        name: b.name,
        vendorName: b.vendor?.vendor?.displayName || b.name,
        category: b.category,
        frequency: b.frequency,
        isAutoPay: b.paymentMethod === 'auto',
        lastAmount: b.amount,
      })),
    };
  }

  /**
   * Get Alfred email address for household
   * Generates code from address if not already set
   */
  async getAlfredEmailAddress(user: AuthPayload) {
    let household = await this.getHousehold(user);

    // Generate code if not set (for existing households)
    if (!household.alfredEmailCode) {
      const homeProfile = await this.prisma.homeProfile.findFirst({
        where: { householdId: household.id },
      });

      if (homeProfile?.addressLine1) {
        const code = await generateUniqueAlfredEmailCode(
          this.prisma,
          homeProfile.addressLine1,
        );

        household = await this.prisma.household.update({
          where: { id: household.id },
          data: { alfredEmailCode: code },
        });
      }
    }

    return {
      email: household.alfredEmailCode
        ? `${household.alfredEmailCode}@${ALFRED_EMAIL_DOMAIN}`
        : null,
      code: household.alfredEmailCode,
    };
  }

  /**
   * Get authorized emails for household
   */
  async getAuthorizedEmails(user: AuthPayload) {
    const household = await this.getHousehold(user);
    return this.prisma.authorizedEmail.findMany({
      where: { householdId: household.id },
      orderBy: { createdAt: 'desc' },
    });
  }

  /**
   * Add authorized email
   */
  async addAuthorizedEmail(user: AuthPayload, email: string, label?: string) {
    const household = await this.getHousehold(user);

    return this.prisma.authorizedEmail.create({
      data: {
        householdId: household.id,
        email: email.toLowerCase(),
        label,
        addedById: user.userId,
      },
    });
  }

  /**
   * Remove authorized email
   */
  async removeAuthorizedEmail(user: AuthPayload, id: string) {
    const household = await this.getHousehold(user);

    return this.prisma.authorizedEmail.delete({
      where: { id, householdId: household.id },
    });
  }

  /**
   * Get email cases history
   */
  async getCases(user: AuthPayload, status?: string) {
    const household = await this.getHousehold(user);

    return this.prisma.emailCase.findMany({
      where: {
        householdId: household.id,
        ...(status ? { status: status as EmailCaseStatus } : {}),
      },
      orderBy: { receivedAt: 'desc' },
      take: 50,
      include: {
        attachments: {
          select: { id: true, filename: true, contentType: true },
        },
      },
    });
  }

  /**
   * Get single case with full details
   */
  async getCase(user: AuthPayload, caseId: string) {
    const household = await this.getHousehold(user);

    const emailCase = await this.prisma.emailCase.findFirst({
      where: { id: caseId, householdId: household.id },
      include: {
        attachments: true,
        activities: {
          orderBy: { createdAt: 'asc' },
        },
      },
    });

    if (!emailCase) {
      throw new BadRequestException('Case not found');
    }

    return emailCase;
  }

  /**
   * Answer a pending question
   */
  async answerQuestion(
    user: AuthPayload,
    caseId: string,
    answer: { answer: string; selectedOption?: string },
  ) {
    const household = await this.getHousehold(user);

    const emailCase = await this.prisma.emailCase.findFirst({
      where: { id: caseId, householdId: household.id },
    });

    if (!emailCase || emailCase.status !== EmailCaseStatus.AWAITING_INPUT) {
      throw new BadRequestException('No pending question for this case');
    }

    // Handle authorization request
    if (emailCase.pendingQuestion?.includes('unknown sender')) {
      if (
        answer.answer.toLowerCase().includes('yes') ||
        answer.selectedOption === 'Yes, authorize'
      ) {
        // Add the sender to authorized emails
        await this.prisma.authorizedEmail.create({
          data: {
            householdId: household.id,
            email: emailCase.fromEmail.toLowerCase(),
            label: `Added from email case ${emailCase.caseNumber}`,
            addedById: user.userId,
          },
        });

        // Re-process the email
        return this.processInboundEmail({
          to: `${household.alfredEmailCode}@${ALFRED_EMAIL_DOMAIN}`,
          from: emailCase.fromEmail,
          subject: emailCase.subject,
          text: emailCase.bodyText || undefined,
          html: emailCase.bodyHtml || undefined,
          envelope: { to: [], from: emailCase.fromEmail },
          attachments: [],
          messageId: emailCase.messageId,
        });
      } else {
        // Archive the case
        await this.prisma.emailCase.update({
          where: { id: caseId },
          data: {
            status: EmailCaseStatus.ARCHIVED,
            userResponse: answer.answer,
            respondedAt: new Date(),
            resolvedAt: new Date(),
            resolutionNotes: 'User declined to authorize sender',
          },
        });

        await this.prisma.emailCaseActivity.create({
          data: {
            caseId,
            type: EmailCaseActivityType.CASE_ARCHIVED,
            description: 'User declined to authorize sender, case archived',
            actor: 'user',
            actorName: user.email || 'User',
          },
        });

        return { status: 'archived' };
      }
    }

    // Get question context from extracted data
    const questionContext =
      (emailCase.extractedData as Record<string, unknown>)?.questionContext ||
      {};

    // Re-process with the answer
    const result = await this.emailActions.continueWithAnswer(
      household.id,
      caseId,
      questionContext as Record<string, unknown>,
      answer,
    );

    await this.prisma.emailCase.update({
      where: { id: caseId },
      data: {
        status: EmailCaseStatus.COMPLETED,
        actionsTaken: result.actions,
        userResponse: answer.answer,
        respondedAt: new Date(),
        resolvedAt: new Date(),
      },
    });

    await this.prisma.emailCaseActivity.create({
      data: {
        caseId,
        type: EmailCaseActivityType.CASE_RESOLVED,
        description: `Case completed after user response`,
        actor: 'alfred',
        actorName: 'Alfred',
      },
    });

    return result;
  }

  /**
   * Execute user-selected actions from email case suggestions.
   * This is the "always ask intent" flow - user taps action buttons, we execute.
   */
  async executeSelectedActions(
    user: AuthPayload,
    caseId: string,
    body: { actionTypes: string[]; customRequest?: string },
  ) {
    const household = await this.getHousehold(user);

    const emailCase = await this.prisma.emailCase.findFirst({
      where: { id: caseId, householdId: household.id },
    });

    if (!emailCase) throw new BadRequestException('Case not found');

    const extractedData = emailCase.extractedData as Record<string, unknown> | null;
    const questionOptions = emailCase.questionOptions as Array<{
      label: string;
      type: string;
      data: unknown;
    }> | null;

    // Handle "Something else..." custom request
    if (body.actionTypes.includes('CUSTOM') && body.customRequest) {
      const customResult = await this.emailParser.parseWithCustomIntent(
        emailCase,
        body.customRequest,
      );

      await this.prisma.emailCase.update({
        where: { id: caseId },
        data: {
          pendingQuestion: `${customResult.greeting}\n\n${customResult.summary}\n\nWhat would you like me to do?`,
          questionOptions: JSON.parse(JSON.stringify(customResult.suggestedActions)),
        },
      });

      await this.prisma.emailCaseActivity.create({
        data: {
          caseId,
          type: EmailCaseActivityType.USER_RESPONDED,
          description: `User requested: "${body.customRequest}"`,
          actor: 'user',
          actorName: user.email || 'User',
        },
      });

      return { status: 'awaiting_input', message: customResult };
    }

    // Handle "All of the Above" - expand to all non-CUSTOM, non-ALL types
    let actionTypes = body.actionTypes;
    if (actionTypes.includes('ALL') && questionOptions) {
      actionTypes = questionOptions
        .map((a) => a.type)
        .filter((t) => t !== 'CUSTOM' && t !== 'ALL');
    }

    // Execute selected actions using the existing EmailActionsService
    const parsedResult = extractedData as Record<string, unknown> | null;
    const actions: Array<{ type: string; success: boolean; id?: string; error?: string }> = [];

    for (const actionType of actionTypes) {
      // Find the action data from questionOptions
      const actionOption = questionOptions?.find((a) => a.type === actionType);
      if (!actionOption?.data) continue;

      try {
        switch (actionType) {
          case 'CALENDAR': {
            const eventData = actionOption.data as Record<string, unknown>;
            const hh = await this.prisma.household.findUnique({
              where: { id: household.id },
              select: { ownerId: true },
            });
            const event = await this.prisma.familyEvent.create({
              data: {
                householdId: household.id,
                createdByUserId: hh?.ownerId || '',
                title: (eventData.title as string) || emailCase.subject,
                description: (eventData.description as string) || undefined,
                startDate: eventData.startDate ? new Date(eventData.startDate as string) : new Date(),
                endDate: eventData.endDate ? new Date(eventData.endDate as string) : undefined,
                isAllDay: (eventData.isAllDay as boolean) || false,
                location: (eventData.location as string) || undefined,
                syncSource: 'MANUAL',
                createdByRole: 'SYSTEM',
              },
            });
            actions.push({ type: 'CALENDAR', success: true, id: event.id });
            break;
          }

          case 'BILL': {
            const billData = actionOption.data as Record<string, unknown>;
            // Find or create vendor
            let vendorId: string | undefined;
            const vendorName = (billData.vendorName as string) || emailCase.subject;

            const existingVendor = await this.prisma.vendor.findFirst({
              where: { displayName: { contains: vendorName, mode: 'insensitive' } },
            });

            if (existingVendor) {
              vendorId = existingVendor.id;
            }

            // Create HouseholdVendor link if vendor found
            let householdVendorId: string | undefined;
            if (vendorId) {
              const hv = await this.prisma.householdVendor.findFirst({
                where: { householdId: household.id, vendorId },
              });
              householdVendorId = hv?.id;
            }

            const bill = await this.prisma.bill.create({
              data: {
                householdId: household.id,
                name: vendorName,
                amount: (billData.amount as number) || 0,
                nextDueDate: billData.dueDate ? new Date(billData.dueDate as string) : null,
                category: (billData.billType as string) || 'other',
                frequency: (billData.isRecurring as boolean) ? (billData.frequency as string) || 'monthly' : 'one-time',
                paymentMethod: 'manual',
                status: 'active',
                sourceType: 'alfred',
                vendorId: householdVendorId || undefined,
              },
            });
            actions.push({ type: 'BILL', success: true, id: bill.id });
            break;
          }

          case 'VENDOR': {
            const vendorData = actionOption.data as Record<string, unknown>;
            const vendor = await this.prisma.vendor.create({
              data: {
                displayName: (vendorData.vendorName as string) || 'Unknown Vendor',
                phone: (vendorData.phone as string) || undefined,
                email: (vendorData.email as string) || undefined,
                category: ((vendorData.category as string)?.toUpperCase() as VendorCategory) || VendorCategory.OTHER,
              },
            });
            // Link to household
            await this.prisma.householdVendor.create({
              data: {
                householdId: household.id,
                vendorId: vendor.id,
              },
            });
            actions.push({ type: 'VENDOR', success: true, id: vendor.id });
            break;
          }

          case 'TASK': {
            const taskData = actionOption.data as Record<string, unknown>;
            const hhForTask = await this.prisma.household.findUnique({
              where: { id: household.id },
              select: { ownerId: true },
            });
            const priorityMap: Record<string, TaskPriority> = {
              URGENT: TaskPriority.URGENT,
              HIGH: TaskPriority.HIGH,
              NORMAL: TaskPriority.MEDIUM,
              MEDIUM: TaskPriority.MEDIUM,
              LOW: TaskPriority.LOW,
            };
            const task = await this.prisma.task.create({
              data: {
                householdId: household.id,
                createdById: hhForTask?.ownerId || '',
                assigneeId: hhForTask?.ownerId || undefined,
                title: (taskData.title as string) || emailCase.subject,
                description: (taskData.description as string) || undefined,
                priority: priorityMap[((taskData.priority as string) || 'NORMAL').toUpperCase()] || TaskPriority.MEDIUM,
              },
            });
            actions.push({ type: 'TASK', success: true, id: task.id });
            break;
          }

          case 'DOCUMENT': {
            const docData = actionOption.data as Record<string, unknown>;
            const docCategoryMap: Record<string, DocumentCategory> = {
              general: DocumentCategory.OTHER,
              tax: DocumentCategory.TAX,
              contracts: DocumentCategory.CONTRACT,
              receipts: DocumentCategory.RECEIPT,
              medical: DocumentCategory.OTHER,
              school: DocumentCategory.OTHER,
              insurance: DocumentCategory.INSURANCE,
              warranty: DocumentCategory.WARRANTY,
              property: DocumentCategory.PROPERTY,
            };
            const hhForDoc = await this.prisma.household.findUnique({
              where: { id: household.id },
              select: { ownerId: true },
            });
            const docName = (docData.name as string) || emailCase.subject;
            const doc = await this.prisma.document.create({
              data: {
                householdId: household.id,
                fileName: `${docName.replace(/[^a-zA-Z0-9]/g, '_')}.pdf`,
                originalName: docName,
                mimeType: 'application/pdf',
                fileSize: 0,
                storageUrl: '',
                storagePath: '',
                category: docCategoryMap[(docData.category as string) || 'general'] || DocumentCategory.OTHER,
                title: docName,
                uploadedById: hhForDoc?.ownerId || '',
              },
            });
            actions.push({ type: 'DOCUMENT', success: true, id: doc.id });
            break;
          }

          case 'REMINDER': {
            const reminderData = actionOption.data as Record<string, unknown>;
            const reminder = await this.prisma.reminder.create({
              data: {
                householdId: household.id,
                type: ReminderType.BILL_DUE,
                scheduledAt: reminderData.remindAt ? new Date(reminderData.remindAt as string) : new Date(),
                status: ReminderStatus.PENDING,
                channel: ReminderChannel.EMAIL,
                payloadJson: { message: (reminderData.message as string) || `Reminder: ${emailCase.subject}`, source: 'alfred-email' },
              },
            });
            actions.push({ type: 'REMINDER', success: true, id: reminder.id });
            break;
          }

          case 'WARRANTY': {
            const warrantyData = actionOption.data as Record<string, unknown>;
            const hhForWarranty = await this.prisma.household.findUnique({
              where: { id: household.id },
              select: { ownerId: true },
            });
            const warrantyDoc = await this.prisma.document.create({
              data: {
                householdId: household.id,
                fileName: `warranty_${((warrantyData.productName as string) || 'product').replace(/[^a-zA-Z0-9]/g, '_')}.pdf`,
                originalName: `${(warrantyData.productName as string) || 'Product'} Warranty`,
                mimeType: 'application/pdf',
                fileSize: 0,
                storageUrl: '',
                storagePath: '',
                category: DocumentCategory.WARRANTY,
                title: `${(warrantyData.productName as string) || 'Product'} Warranty`,
                description: (warrantyData.warrantyTerms as string) || undefined,
                expiresAt: warrantyData.expirationDate ? new Date(warrantyData.expirationDate as string) : undefined,
                expirationAlert: !!warrantyData.expirationDate,
                uploadedById: hhForWarranty?.ownerId || '',
              },
            });
            // Set reminder before warranty expires
            if (warrantyData.expirationDate) {
              const expDate = new Date(warrantyData.expirationDate as string);
              const reminderDate = new Date(expDate);
              reminderDate.setMonth(reminderDate.getMonth() - 1);
              await this.prisma.reminder.create({
                data: {
                  householdId: household.id,
                  type: ReminderType.BILL_DUE,
                  scheduledAt: reminderDate,
                  status: ReminderStatus.PENDING,
                  channel: ReminderChannel.EMAIL,
                  payloadJson: { message: `Warranty expiring soon: ${(warrantyData.productName as string) || 'Product'}`, source: 'alfred-email' },
                },
              });
            }
            actions.push({ type: 'WARRANTY', success: true, id: warrantyDoc.id });
            break;
          }

          case 'SHIPPING': {
            const shippingData = actionOption.data as Record<string, unknown>;
            // Create a reminder for estimated delivery
            if (shippingData.estimatedDelivery) {
              const deliveryReminder = await this.prisma.reminder.create({
                data: {
                  householdId: household.id,
                  type: ReminderType.BILL_DUE,
                  scheduledAt: new Date(shippingData.estimatedDelivery as string),
                  status: ReminderStatus.PENDING,
                  channel: ReminderChannel.EMAIL,
                  payloadJson: JSON.parse(JSON.stringify({
                    message: `Package arriving: ${(shippingData.itemDescription as string) || 'Your order'}`,
                    carrier: shippingData.carrier,
                    trackingNumber: shippingData.trackingNumber,
                    source: 'alfred-email',
                  })),
                },
              });
              actions.push({ type: 'SHIPPING', success: true, id: deliveryReminder.id });
            } else {
              // Log tracking info even without delivery date
              actions.push({ type: 'SHIPPING', success: true });
            }
            break;
          }

          case 'ESCALATE': {
            // Create a service request for the Haven team to handle behind the scenes
            const escalateData = actionOption.data as Record<string, unknown>;
            const serviceRequest = await this.prisma.serviceRequest.create({
              data: {
                householdId: household.id,
                createdById: user.userId,
                title: (escalateData.title as string) || `Handle email: ${emailCase.subject}`,
                description: (escalateData.description as string) || `Email forwarded to Alfred requires human handling.\n\nSubject: ${emailCase.subject}\nFrom: ${emailCase.fromEmail}\n\nUser selected: Have Alfred's team handle this.`,
                status: 'SUBMITTED',
                priority: 'MEDIUM',
                quickCategory: 'OTHER',
              },
            });
            actions.push({ type: 'ESCALATE', success: true, id: serviceRequest.id });
            break;
          }
        }

        // Log each action
        await this.prisma.emailCaseActivity.create({
          data: {
            caseId,
            type: `${actionType}_CREATED` as EmailCaseActivityType,
            description: `Created ${actionType.toLowerCase()} from email`,
            actor: 'alfred',
            actorName: 'Alfred',
          },
        });
      } catch (error) {
        this.logger.error(`Failed to execute ${actionType}: ${error.message}`);
        actions.push({ type: actionType, success: false, error: error.message });
      }
    }

    // Build confirmation message
    const successful = actions.filter((a) => a.success);
    let confirmationMessage: string;
    if (successful.length === 0) {
      confirmationMessage = "Hmm, I ran into some issues. Let me try again?";
    } else {
      const items = successful.map((a) => {
        switch (a.type) {
          case 'CALENDAR': return '📅 Added to calendar';
          case 'BILL': return '💵 Tracking the bill';
          case 'VENDOR': return '📋 Saved contact info';
          case 'TASK': return '✅ Created task';
          case 'DOCUMENT': return '📄 Saved document';
          case 'REMINDER': return '⏰ Set reminder';
          case 'WARRANTY': return '🛡️ Saved warranty info';
          case 'SHIPPING': return '📦 Tracking package';
          case 'ESCALATE': return '🤝 Our team is on it';
          default: return `✓ ${a.type}`;
        }
      });
      confirmationMessage = `Done! ✨\n\n${items.join('\n')}\n\nAnything else you need?`;
    }

    // Update case status
    await this.prisma.emailCase.update({
      where: { id: caseId },
      data: {
        status: EmailCaseStatus.COMPLETED,
        actionsTaken: JSON.parse(JSON.stringify(actions)),
        userResponse: `Selected: ${actionTypes.join(', ')}`,
        respondedAt: new Date(),
        resolvedAt: new Date(),
        resolutionNotes: confirmationMessage,
      },
    });

    await this.prisma.emailCaseActivity.create({
      data: {
        caseId,
        type: EmailCaseActivityType.CASE_RESOLVED,
        description: confirmationMessage,
        actor: 'alfred',
        actorName: 'Alfred',
      },
    });

    return { status: 'completed', actions, message: confirmationMessage };
  }

  /**
   * Archive a case
   */
  async archiveCase(user: AuthPayload, caseId: string) {
    const household = await this.getHousehold(user);

    await this.prisma.emailCase.update({
      where: { id: caseId, householdId: household.id },
      data: {
        status: EmailCaseStatus.ARCHIVED,
        resolvedAt: new Date(),
      },
    });

    await this.prisma.emailCaseActivity.create({
      data: {
        caseId,
        type: EmailCaseActivityType.CASE_ARCHIVED,
        description: 'Case archived by user',
        actor: 'user',
        actorName: user.email || 'User',
      },
    });

    return { success: true };
  }

  /**
   * Simulate a test email for dev/staging testing
   */
  async simulateTestEmail(user: AuthPayload, scenario: string) {
    const household = await this.getHousehold(user);

    if (!household.alfredEmailCode) {
      throw new BadRequestException(
        'Household does not have an Alfred email configured',
      );
    }

    const testEmails: Record<string, { from: string; subject: string; text: string }> = {
      camp_registration: {
        from: 'info@campwonderland.com',
        subject: 'Registration Confirmed - Summer Camp 2026',
        text: `Dear Morrison Family,

Thank you for registering Emma for Camp Wonderland!

Session Details:
- Dates: June 15-19, 2026
- Time: 9:00 AM - 3:00 PM daily
- Location: 45 Camp Road, Greenwich, CT

Registration Fee: $450 (due by March 1, 2026)

What to bring:
- Sunscreen
- Water bottle
- Lunch and snacks

We're excited to have Emma join us!

Best,
Camp Wonderland Team
(203) 555-0300`,
      },

      utility_bill: {
        from: 'noreply@eversource.com',
        subject: 'Your Eversource Bill is Ready',
        text: `Your monthly electric bill is now available.

Account: Morrison, Robert
Service Address: 146 Putnam Park Rd, Greenwich, CT

Amount Due: $287.43
Due Date: February 20, 2026

This is higher than your average bill of $215.00.

View and pay at eversource.com or call 800-286-2000.

Thank you for being an Eversource customer.`,
      },

      vendor_quote: {
        from: 'mike@acegutters.com',
        subject: 'Quote for Gutter Cleaning - 146 Putnam Park Rd',
        text: `Hi Bob,

Thanks for reaching out about gutter cleaning. Here's your quote:

Service: Full gutter cleaning and inspection
Property: 146 Putnam Park Rd, Greenwich, CT
Price: $275.00

Includes:
- Clean all gutters and downspouts
- Flush downspouts
- Minor repairs (up to 10 ft of resealing)
- Inspection report

We can schedule anytime in the next 2 weeks. Quote valid through March 1, 2026.

Let me know if you'd like to proceed!

Mike Rodriguez
Ace Gutters LLC
(203) 555-0199
mike@acegutters.com`,
      },

      appointment: {
        from: 'appointments@greenwichdental.com',
        subject: 'Appointment Reminder - Jack Morrison',
        text: `This is a reminder of your upcoming appointment:

Patient: Jack Morrison
Date: February 10, 2026
Time: 2:30 PM
Provider: Dr. Sarah Williams
Type: 6-Month Cleaning

Location:
Greenwich Dental Care
123 Main Street, Suite 200
Greenwich, CT 06830

Please arrive 10 minutes early. Call (203) 555-0400 to reschedule.`,
      },

      school_event: {
        from: 'events@gcds.net',
        subject: 'Save the Date: Spring Concert - March 15',
        text: `Dear GCDS Families,

Please save the date for our annual Spring Concert!

Event: Spring Concert 2026
Date: Saturday, March 15, 2026
Time: 7:00 PM
Location: Performing Arts Center

Emma Morrison will be performing with the 7th Grade Chorus.

Tickets: $15 adults, free for students
RSVP by March 10 at gcds.net/springconcert

We hope to see you there!

Greenwich Country Day School
Music Department`,
      },

      home_inspection: {
        from: 'reports@homeinspectpro.com',
        subject: 'Inspection Report Ready - 146 Putnam Park Rd',
        text: `Your home inspection report is ready.

Property: 146 Putnam Park Rd, Greenwich, CT 06830
Inspection Date: January 28, 2026
Inspector: James Chen, License #HI-2845

Summary Findings:
- HVAC: Furnace is 18 years old, recommend service
- Roof: Good condition, 8 years remaining life
- Water Heater: 12 years old, near end of life (recommend budgeting for replacement)
- Foundation: No issues
- Electrical: Panel updated, good condition

Full report attached (simulated).

Please call with any questions: (203) 555-0888

HomeInspect Pro
Licensed & Insured`,
      },
    };

    const emailData = testEmails[scenario];
    if (!emailData) {
      throw new BadRequestException(`Unknown scenario: ${scenario}`);
    }

    // Process as if it came from SendGrid webhook
    return this.processInboundEmail({
      from: emailData.from,
      to: `${household.alfredEmailCode}@${ALFRED_EMAIL_DOMAIN}`,
      subject: emailData.subject,
      text: emailData.text,
      html: undefined,
      envelope: {
        to: [`${household.alfredEmailCode}@${ALFRED_EMAIL_DOMAIN}`],
        from: emailData.from,
      },
      attachments: [],
      messageId: `test_${Date.now()}`,
    });
  }

  private async getHousehold(user: AuthPayload) {
    if (!user.householdId) {
      throw new BadRequestException('No household found for user');
    }

    const household = await this.prisma.household.findUnique({
      where: { id: user.householdId },
    });

    if (!household) {
      throw new BadRequestException('Household not found');
    }

    return household;
  }
}
