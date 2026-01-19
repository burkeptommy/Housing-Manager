import { Injectable, Logger } from '@nestjs/common';
import Anthropic from '@anthropic-ai/sdk';

interface ParseEmailInput {
  subject: string;
  body: string;
  attachments?: Array<{
    filename: string;
    type: string;
    content: string;
  }>;
  householdContext: {
    members: Array<{
      id: string;
      firstName: string;
      lastName: string;
      type: string;
    }>;
    children: Array<{ id: string; firstName: string; lastName: string }>;
    vendors: Array<{ id: string; displayName: string; category: string }>;
    systems: Array<{ id: string; name: string; category: string }>;
    pets?: Array<{ id: string; name: string; type: string }>;
    existingBills?: Array<{
      id: string;
      name: string;
      vendorName: string;
      category: string;
      frequency: string;
      isAutoPay: boolean;
      lastAmount: number | null;
    }>;
  };
}

// Expanded email types covering all possible categories
export type EmailIntentType =
  // Calendar & Scheduling
  | 'CAMP_REGISTRATION'
  | 'SCHOOL_EVENT'
  | 'APPOINTMENT'
  | 'SERVICE_WINDOW'
  | 'TRAVEL_ITINERARY'
  | 'RECURRING_EVENT'
  | 'DEADLINE'
  | 'PARTY_INVITATION'
  | 'SPORTS_SCHEDULE'
  | 'LESSON_SCHEDULE'
  | 'RESERVATION'
  | 'MEETING'
  // Financial & Bills
  | 'INVOICE'
  | 'PAYMENT_CONFIRMATION'
  | 'PAYMENT_REMINDER'
  | 'SUBSCRIPTION_NOTICE'
  | 'FEE_INCREASE'
  | 'REFUND_NOTICE'
  | 'TAX_DOCUMENT'
  | 'INSURANCE_RENEWAL'
  | 'INSURANCE_CLAIM'
  | 'STATEMENT'
  | 'TUITION_BILL'
  | 'MEDICAL_BILL'
  | 'UTILITY_BILL'
  | 'MEMBERSHIP_DUES'
  | 'DONATION_RECEIPT'
  | 'ESTIMATE'
  // Vendor & Service
  | 'NEW_VENDOR_CONTACT'
  | 'SERVICE_QUOTE'
  | 'SERVICE_AGREEMENT'
  | 'SERVICE_CONFIRMATION'
  | 'SERVICE_COMPLETION'
  | 'WARRANTY_INFO'
  | 'MAINTENANCE_AGREEMENT'
  | 'VENDOR_UPDATE'
  | 'RECOMMENDATION'
  // Home & Property
  | 'INSPECTION_REPORT'
  | 'MAINTENANCE_REMINDER'
  | 'HOA_NOTICE'
  | 'UTILITY_NOTICE'
  | 'PERMIT_STATUS'
  | 'PROPERTY_TAX'
  | 'APPRAISAL'
  | 'RECALL_NOTICE'
  | 'RENOVATION_UPDATE'
  | 'APPLIANCE_REGISTRATION'
  // Family & Household
  | 'MEDICAL_RECORD'
  | 'SCHOOL_REPORT'
  | 'SCHOOL_NOTICE'
  | 'ACTIVITY_REGISTRATION'
  | 'PET_RECORD'
  | 'PRESCRIPTION_NOTICE'
  | 'IMMUNIZATION_RECORD'
  | 'CHILDCARE_INVOICE'
  // Disputes & Correspondence
  | 'BILLING_DISPUTE'
  | 'SERVICE_COMPLAINT'
  | 'WARRANTY_CLAIM'
  | 'REFUND_REQUEST'
  | 'CANCELLATION_REQUEST'
  | 'PRICE_NEGOTIATION'
  // Informational
  | 'NEWSLETTER'
  | 'ANNOUNCEMENT'
  | 'SHIPPING_UPDATE'
  | 'ORDER_CONFIRMATION'
  | 'TRAVEL_UPDATE'
  | 'WEATHER_ALERT'
  | 'SCHOOL_CLOSURE'
  // Catch-all
  | 'UNKNOWN';

export interface ParsedEmailResult {
  emailType: EmailIntentType;
  category:
    | 'CALENDAR'
    | 'FINANCIAL'
    | 'VENDOR'
    | 'HOME'
    | 'FAMILY'
    | 'DISPUTE'
    | 'INFORMATIONAL'
    | 'UNKNOWN';
  summary: string;
  urgency: 'URGENT' | 'HIGH' | 'NORMAL' | 'LOW';

  // Extracted entities
  dates?: string[]; // All dates mentioned
  amounts?: number[]; // All dollar amounts
  people?: string[]; // Names mentioned
  companies?: string[]; // Company/organization names
  phoneNumbers?: string[];
  emailAddresses?: string[];
  addresses?: string[];
  accountNumbers?: string[];
  confirmationNumbers?: string[];
  trackingNumbers?: string[];

  // Calendar events to create
  calendarEvents?: Array<{
    title: string;
    description?: string;
    startDate: string;
    endDate?: string;
    isAllDay: boolean;
    location?: string;
    recurrence?: string; // RRULE format
    forMemberId?: string;
    forMemberName?: string;
    eventSubtype?: string; // camp, appointment, delivery, etc.
  }>;

  // Bills to create
  bills?: Array<{
    vendorName: string;
    vendorId?: string;
    amount?: number;
    dueDate?: string;
    accountNumber?: string;
    description?: string;
    billType?: string; // utility, medical, tuition, etc.
    billingType?: 'variable' | 'fixed'; // variable = usage-based (utilities), fixed = same each month
    isRecurring?: boolean;
    frequency?: string;
    existingBillId?: string; // If this matches an existing bill account
    existingBillMatched?: boolean; // True if household already tracks this vendor
  }>;

  // Vendor info to update/create
  vendorUpdates?: Array<{
    vendorId?: string;
    vendorName: string;
    phone?: string;
    email?: string;
    address?: string;
    website?: string;
    category?: string;
    notes?: string;
    recommendedBy?: string;
  }>;

  // Systems/assets from inspection
  systems?: Array<{
    name: string;
    category: string;
    zoneName?: string;
    condition?: string;
    notes?: string;
    recommendedAction?: string;
    urgency?: string;
  }>;

  // Tasks to create
  tasks?: Array<{
    title: string;
    description?: string;
    priority: 'URGENT' | 'HIGH' | 'NORMAL' | 'LOW';
    dueDate?: string;
    assignedToId?: string;
  }>;

  // Documents to save
  documents?: Array<{
    name: string;
    category: string; // tax, contracts, receipts, medical, school, general
    forMemberId?: string;
  }>;

  // Reminders to create
  reminders?: Array<{
    message: string;
    remindAt: string;
  }>;

  // Warranty info
  warranty?: {
    productName: string;
    vendorName?: string;
    purchaseDate?: string;
    expirationDate?: string;
    warrantyTerms?: string;
  };

  // Shipping/delivery info
  shipping?: {
    carrier?: string;
    trackingNumber?: string;
    estimatedDelivery?: string;
    itemDescription?: string;
    status?: string;
  };

  // Dispute response draft
  disputeResponse?: {
    to: string;
    subject: string;
    body: string;
    disputeType?: string;
  };

  // HOA-specific info
  hoaNotice?: {
    hasDues?: boolean;
    amount?: number;
    dueDate?: string;
    hasMeeting?: boolean;
    meetingDate?: string;
    meetingLocation?: string;
    hasViolation?: boolean;
    violationDescription?: string;
    responseDeadline?: string;
  };

  // Subscription changes
  subscriptionChange?: {
    vendorName: string;
    changeType: 'RENEWAL' | 'PRICE_CHANGE' | 'CANCELLATION' | 'NEW';
    oldAmount?: number;
    newAmount?: number;
    effectiveDate?: string;
  };

  // Family member this relates to
  familyMemberId?: string;
  familyMemberName?: string;

  // Pet this relates to
  petId?: string;
  petName?: string;

  // Clarification needed
  needsClarification?: {
    question: string;
    options?: string[];
    context: string;
  };

  // Suggested actions for unknown emails
  suggestedActions?: string[];
}

@Injectable()
export class EmailParserService {
  private readonly logger = new Logger(EmailParserService.name);
  private anthropic: Anthropic;

  constructor() {
    this.anthropic = new Anthropic({
      apiKey: process.env.ANTHROPIC_API_KEY,
    });
  }

  async parseEmail(input: ParseEmailInput): Promise<ParsedEmailResult> {
    const systemPrompt = `You are Alfred, a home management AI assistant. Analyze this email and extract ALL actionable information.

The household has the following context:
- Family members: ${JSON.stringify(input.householdContext.members)}
- Children: ${JSON.stringify(input.householdContext.children)}
- Known vendors: ${JSON.stringify(input.householdContext.vendors)}
- Home systems: ${JSON.stringify(input.householdContext.systems)}
${input.householdContext.pets ? `- Pets: ${JSON.stringify(input.householdContext.pets)}` : ''}
${input.householdContext.existingBills?.length ? `- Existing bill accounts: ${JSON.stringify(input.householdContext.existingBills)}` : '- No bill accounts set up yet'}

IMPORTANT - Bill Classification:
- VARIABLE bills (usage-based, amount changes monthly): electricity, gas, water, sewer, propane, oil
- FIXED bills (same amount each month): internet, phone, streaming services, insurance premiums, subscriptions, memberships
- When you identify a bill, set billingType to 'variable' or 'fixed'
- Check if the vendor matches an existing bill account - if so, set existingBillMatched=true and existingBillId

You must identify:

1. **Intent Classification** (pick the most specific one):
   CALENDAR types: CAMP_REGISTRATION, SCHOOL_EVENT, APPOINTMENT, SERVICE_WINDOW, TRAVEL_ITINERARY, RECURRING_EVENT, DEADLINE, PARTY_INVITATION, SPORTS_SCHEDULE, LESSON_SCHEDULE, RESERVATION, MEETING
   FINANCIAL types: INVOICE, PAYMENT_CONFIRMATION, PAYMENT_REMINDER, SUBSCRIPTION_NOTICE, FEE_INCREASE, REFUND_NOTICE, TAX_DOCUMENT, INSURANCE_RENEWAL, INSURANCE_CLAIM, STATEMENT, TUITION_BILL, MEDICAL_BILL, UTILITY_BILL, MEMBERSHIP_DUES, DONATION_RECEIPT, ESTIMATE
   VENDOR types: NEW_VENDOR_CONTACT, SERVICE_QUOTE, SERVICE_AGREEMENT, SERVICE_CONFIRMATION, SERVICE_COMPLETION, WARRANTY_INFO, MAINTENANCE_AGREEMENT, VENDOR_UPDATE, RECOMMENDATION
   HOME types: INSPECTION_REPORT, MAINTENANCE_REMINDER, HOA_NOTICE, UTILITY_NOTICE, PERMIT_STATUS, PROPERTY_TAX, APPRAISAL, RECALL_NOTICE, RENOVATION_UPDATE, APPLIANCE_REGISTRATION
   FAMILY types: MEDICAL_RECORD, SCHOOL_REPORT, SCHOOL_NOTICE, ACTIVITY_REGISTRATION, PET_RECORD, PRESCRIPTION_NOTICE, IMMUNIZATION_RECORD, CHILDCARE_INVOICE
   DISPUTE types: BILLING_DISPUTE, SERVICE_COMPLAINT, WARRANTY_CLAIM, REFUND_REQUEST, CANCELLATION_REQUEST, PRICE_NEGOTIATION
   INFORMATIONAL types: NEWSLETTER, ANNOUNCEMENT, SHIPPING_UPDATE, ORDER_CONFIRMATION, TRAVEL_UPDATE, WEATHER_ALERT, SCHOOL_CLOSURE
   UNKNOWN: Cannot determine - extract what you can

2. **Category** (broader grouping): CALENDAR, FINANCIAL, VENDOR, HOME, FAMILY, DISPUTE, INFORMATIONAL, UNKNOWN

3. **Extract ALL of these if present**:
   - dates: Any dates or times mentioned (ISO format)
   - amounts: Any dollar amounts (numbers only)
   - people: Names of people mentioned
   - companies: Company/organization names
   - phoneNumbers: Phone numbers found
   - emailAddresses: Email addresses found
   - addresses: Physical addresses
   - accountNumbers: Account/policy numbers
   - confirmationNumbers: Confirmation/reference numbers
   - trackingNumbers: Package tracking numbers

4. **Determine urgency**:
   - URGENT: Deadline within 48 hours, safety issue, time-sensitive
   - HIGH: Deadline within 1 week, financial impact
   - NORMAL: Standard processing
   - LOW: Informational only

5. **Identify which family member** this relates to (match to household context if possible)

6. **Create specific action items**:
   - calendarEvents: Events to add to calendar
   - bills: Bills to track - ALWAYS include billingType ('variable' or 'fixed')
     For bills, also set needsClarification if:
     - The household doesn't already track this vendor (existingBillMatched=false)
     - You should ask what they want to do: "set up as recurring", "track this one bill", or "ignore"
   - vendorUpdates: Vendor info to save/update
   - systems: Home systems from inspections
   - tasks: Tasks to create (especially for urgent items)
   - documents: Documents to save to vault
   - reminders: Reminders to set
   - warranty: Warranty info to save
   - shipping: Package tracking info

7. **For specific email types**, populate:
   - hoaNotice: For HOA emails (dues, meetings, violations)
   - subscriptionChange: For subscription/rate changes
   - disputeResponse: Draft response for disputes

8. **Summarize** the email in one clear sentence

IMPORTANT RULES:
- If you can match a family member or child by name, include their ID in familyMemberId
- If you can't determine which member, set needsClarification with a question
- For disputes, ALWAYS draft a professional response in disputeResponse
- For UNKNOWN emails, ALWAYS set suggestedActions with helpful options like:
  ["Add to calendar", "Track as a bill", "Save as vendor contact", "Save document to vault", "Create a task/reminder", "Save for reference"]
- NEVER return an empty result - always extract whatever information is available

Respond with ONLY a JSON object. Do not include markdown code blocks or any other text.`;

    const userMessage = `
Subject: ${input.subject}

Body:
${input.body}

${input.attachments?.length ? `Attachments: ${input.attachments.map((a) => a.filename).join(', ')}` : ''}
`;

    try {
      const response = await this.anthropic.messages.create({
        model: 'claude-sonnet-4-20250514',
        max_tokens: 8192,
        system: systemPrompt,
        messages: [{ role: 'user', content: userMessage }],
      });

      const content = response.content[0];
      if (content.type !== 'text') {
        throw new Error('Unexpected response type');
      }

      // Parse JSON from response
      const jsonMatch = content.text.match(/\{[\s\S]*\}/);
      if (!jsonMatch) {
        throw new Error('No JSON found in response');
      }

      let result = JSON.parse(jsonMatch[0]) as ParsedEmailResult & { actionItems?: Record<string, unknown> };

      // Handle if Claude wrapped action items in an actionItems object
      // We expect bills, tasks, etc. at the root level, but sometimes AI returns them nested
      if (result.actionItems && typeof result.actionItems === 'object') {
        const actionItems = result.actionItems as Record<string, unknown>;
        // Move nested items to root level if they exist
        if (actionItems.bills && !result.bills) {
          result.bills = actionItems.bills as ParsedEmailResult['bills'];
        }
        if (actionItems.calendarEvents && !result.calendarEvents) {
          result.calendarEvents = actionItems.calendarEvents as ParsedEmailResult['calendarEvents'];
        }
        if (actionItems.tasks && !result.tasks) {
          result.tasks = actionItems.tasks as ParsedEmailResult['tasks'];
        }
        if (actionItems.vendorUpdates && !result.vendorUpdates) {
          result.vendorUpdates = actionItems.vendorUpdates as ParsedEmailResult['vendorUpdates'];
        }
        if (actionItems.systems && !result.systems) {
          result.systems = actionItems.systems as ParsedEmailResult['systems'];
        }
        if (actionItems.reminders && !result.reminders) {
          result.reminders = actionItems.reminders as ParsedEmailResult['reminders'];
        }
        if (actionItems.documents && !result.documents) {
          result.documents = actionItems.documents as ParsedEmailResult['documents'];
        }
      }

      // Also normalize extracted entity data if nested
      if ((result as Record<string, unknown>).extractedData && typeof (result as Record<string, unknown>).extractedData === 'object') {
        const extractedData = (result as Record<string, unknown>).extractedData as Record<string, unknown>;
        if (extractedData.dates && !result.dates) result.dates = extractedData.dates as string[];
        if (extractedData.amounts && !result.amounts) result.amounts = extractedData.amounts as number[];
        if (extractedData.people && !result.people) result.people = extractedData.people as string[];
        if (extractedData.companies && !result.companies) result.companies = extractedData.companies as string[];
        if (extractedData.phoneNumbers && !result.phoneNumbers) result.phoneNumbers = extractedData.phoneNumbers as string[];
        if (extractedData.emailAddresses && !result.emailAddresses) result.emailAddresses = extractedData.emailAddresses as string[];
        if (extractedData.accountNumbers && !result.accountNumbers) result.accountNumbers = extractedData.accountNumbers as string[];
      }

      // Normalize bill fields (vendor -> vendorName)
      if (result.bills?.length) {
        result.bills = result.bills.map((bill) => {
          const b = bill as Record<string, unknown>;
          // If vendor exists but vendorName doesn't, copy it over
          if (b.vendor && !b.vendorName) {
            return { ...bill, vendorName: b.vendor as string };
          }
          return bill;
        });
      }

      // Ensure we always have a valid result
      if (!result.emailType) {
        result.emailType = 'UNKNOWN';
      }
      if (!result.category) {
        result.category = 'UNKNOWN';
      }
      if (!result.summary) {
        result.summary = `Email from sender about: ${input.subject}`;
      }
      if (!result.urgency) {
        result.urgency = 'NORMAL';
      }

      return result;
    } catch (error) {
      this.logger.error(`Failed to parse email with Claude: ${error.message}`);
      throw error;
    }
  }

  /**
   * Parse attachment content (PDFs, images)
   */
  async parseAttachment(attachment: {
    filename: string;
    type: string;
    content: string;
  }): Promise<Record<string, unknown> | null> {
    // For PDFs and images, we can use Claude's vision capabilities
    if (attachment.type.includes('pdf') || attachment.type.includes('image')) {
      try {
        const response = await this.anthropic.messages.create({
          model: 'claude-sonnet-4-20250514',
          max_tokens: 4096,
          messages: [
            {
              role: 'user',
              content: [
                {
                  type: 'image',
                  source: {
                    type: 'base64',
                    media_type: attachment.type as
                      | 'image/jpeg'
                      | 'image/png'
                      | 'image/gif'
                      | 'image/webp',
                    data: attachment.content,
                  },
                },
                {
                  type: 'text',
                  text: `Extract all relevant information from this document. Return as JSON with these fields if present:
- documentType: invoice, receipt, inspection_report, medical_record, tax_form, contract, warranty, other
- dates: array of dates found
- amounts: array of dollar amounts
- vendorName: company/organization name
- accountNumber: any account or policy numbers
- systems: if inspection report, array of {name, condition, notes, recommendedAction}
- summary: one sentence summary`,
                },
              ],
            },
          ],
        });

        const content = response.content[0];
        if (content.type === 'text') {
          const jsonMatch = content.text.match(/\{[\s\S]*\}/);
          if (jsonMatch) {
            return JSON.parse(jsonMatch[0]);
          }
        }
      } catch (error) {
        this.logger.error(
          `Failed to parse attachment ${attachment.filename}: ${error.message}`,
        );
      }
    }

    return null;
  }

  /**
   * Generate a dispute response using Claude
   */
  async generateDisputeResponse(params: {
    vendor: string;
    disputeType: string;
    description: string;
    desiredOutcome: string;
    supportingDetails?: Record<string, unknown>;
  }): Promise<string> {
    const prompt = `Generate a professional but firm dispute letter for:
Vendor: ${params.vendor}
Type: ${params.disputeType}
Issue: ${params.description}
Desired Outcome: ${params.desiredOutcome}
${params.supportingDetails ? `Supporting Details: ${JSON.stringify(params.supportingDetails)}` : ''}

Keep it concise (under 200 words), factual, and actionable. Include:
1. Clear statement of the issue
2. Reference to any account numbers or dates
3. Specific resolution requested
4. Reasonable deadline for response

Do not include placeholders like [YOUR NAME] - just write the body of the letter.`;

    const response = await this.anthropic.messages.create({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 1024,
      messages: [{ role: 'user', content: prompt }],
    });

    const content = response.content[0];
    if (content.type === 'text') {
      return content.text;
    }

    throw new Error('Failed to generate dispute response');
  }
}
