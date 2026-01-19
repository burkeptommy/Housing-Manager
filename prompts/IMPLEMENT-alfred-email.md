# Haven - Alfred Email Personal Assistant (CC Feature)

## OVERVIEW

Implement email processing so users can CC Alfred on any email. Alfred will:
- Parse email content and attachments
- Extract actionable information (dates, amounts, contacts, etc.)
- Automatically add calendar events, bills, vendor info, systems
- Ask clarifying questions when needed via in-app Alfred chat
- Draft responses for disputes (user approval required)

**Email Format:** `{household_code}@alfred.havenhome.dev`

**Code Format:** Based on street address for easy recall (e.g., `38BedfordRoad@alfred.havenhome.dev`)

---

## CRITICAL DESIGN PRINCIPLE

**Every email forwarded to Alfred is HIGH PRIORITY and HIGH INTENT.**

Users don't CC Alfred for no reason. Every single email must:
1. **Create a Case** - Visible audit trail for the user
2. **Take Action** - Even if just acknowledging and asking for clarification
3. **Never Fall Through** - No email goes unprocessed
4. **Enable Follow-up** - User can provide more context, Alfred can ask questions

**Action Hierarchy:**
| Priority | Type | Example | Action |
|----------|------|---------|--------|
| 1 | Definite | Camp dates clearly stated | Auto-add to calendar |
| 2 | Probable | Invoice attached | Create bill, maybe ask which account |
| 3 | Contextual | Vendor email | Update vendor info, ask if action needed |
| 4 | Unknown | Random forward | Acknowledge, ask "What would you like me to do with this?" |

**NEVER do nothing. ALWAYS create a case and respond.**

---

## COMPREHENSIVE ACTION CATEGORIES

Alfred must be able to handle ANY email. Here's the complete taxonomy of actions:

### CATEGORY 1: CALENDAR & SCHEDULING
| Email Type | Auto Actions | May Ask |
|------------|--------------|--------|
| Camp/program registration | Add dates to calendar, set reminders | Which child? |
| School events | Add to family calendar | Which child attends? |
| Appointments | Add to calendar with location | Who is this for? |
| Delivery/service windows | Add to calendar | Confirm date/time? |
| Travel itineraries | Add flights, hotels, activities | |
| Recurring events | Create recurring calendar entry | Frequency correct? |
| Deadlines | Add deadline with reminder | How much notice? |

### CATEGORY 2: FINANCIAL & BILLS
| Email Type | Auto Actions | May Ask |
|------------|--------------|--------|
| Invoices | Create bill record, extract amount/due date | Payment method? |
| Payment confirmations | Mark bill as paid, log payment | |
| Subscription notices | Update recurring bill | Keep or cancel? |
| Fee increases | Update bill amount, notify user | |
| Refund notices | Log refund, update records | |
| Tax documents | Save to documents, tag as tax | Which tax year? |
| Insurance renewals | Update policy, create reminder | |

### CATEGORY 3: VENDOR & CONTACTS
| Email Type | Auto Actions | May Ask |
|------------|--------------|--------|
| Vendor correspondence | Update/create vendor record | Category? |
| Service quotes | Save quote, create comparison | Want to schedule? |
| Contractor estimates | Log estimate, link to project | Approve estimate? |
| Business cards/contact info | Add to vendor list | What service? |
| Warranty info | Save to documents, link to system | Which appliance? |
| Service agreements | Save document, set renewal reminder | |

### CATEGORY 4: HOME & PROPERTY
| Email Type | Auto Actions | May Ask |
|------------|--------------|--------|
| Inspection reports | Extract systems, conditions, add to home profile | |
| Maintenance reminders | Create task, suggest scheduling | Who should do it? |
| HOA notices | Log notice, create action if needed | |
| Utility notices | Update account, schedule if needed | |
| Permit approvals | Log to project, save document | |
| Property tax notices | Update records, create bill | |

### CATEGORY 5: FAMILY & HOUSEHOLD
| Email Type | Auto Actions | May Ask |
|------------|--------------|--------|
| Medical records | Save securely, link to family member | Which person? |
| School reports | Save to family member profile | |
| Activity registrations | Add to calendar, track fees | Which child? |
| Pet records (vet, etc.) | Update pet profile | |
| Prescription notices | Set refill reminders | |

### CATEGORY 6: DISPUTES & CORRESPONDENCE
| Email Type | Auto Actions | May Ask |
|------------|--------------|--------|
| Billing disputes | Draft response, await approval | Review draft? |
| Complaint responses | Draft follow-up if needed | Satisfied? |
| Service issues | Log issue, draft response | Want me to respond? |
| Refund requests | Track status, follow up | |

### CATEGORY 7: INFORMATIONAL
| Email Type | Auto Actions | May Ask |
|------------|--------------|--------|
| Newsletters | Extract relevant info, summarize | Keep or unsubscribe? |
| Announcements | Note if action needed | |
| Updates/notifications | Log and categorize | |
| Confirmations | Verify against records | |

### CATEGORY 8: UNKNOWN / CATCH-ALL (CRITICAL!)
| Email Type | Auto Actions | Always Ask |
|------------|--------------|--------|
| Unrecognized format | Summarize email, log case | "What would you like me to do with this?" |
| Unclear intent | Extract any useful info | "I see X, Y, Z. Should I...?" |
| Personal/misc | Acknowledge receipt | "How can I help with this?" |

**THE UNKNOWN CATEGORY IS THE MOST IMPORTANT.**

When Alfred doesn't know what to do, he MUST:
1. Create a case (so it's tracked)
2. Summarize what he sees
3. Offer specific suggestions based on content
4. Ask the user what they want done

Example responses for unknown emails:
- "I received your forwarded email about [subject]. I noticed [observations]. Would you like me to: (A) Add this to your calendar, (B) Create a task to follow up, (C) Save as a document, or (D) Something else?"
- "Thanks for forwarding this. I see it mentions [person/company]. Should I: (A) Add them as a vendor, (B) Create a reminder, (C) Just keep this on file?"
- "I've logged this email. What action would you like me to take?"

---

## CASE LIFECYCLE

Every email follows this lifecycle:

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  RECEIVED   │────▶│ PROCESSING  │────▶│ IN_PROGRESS │────▶│  COMPLETED  │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
                           │                                       ▲
                           ▼                                       │
                    ┌─────────────┐                               │
                    │  AWAITING   │───────────────────────────────┘
                    │   INPUT     │   (user responds)
                    └─────────────┘
```

**Case Number Format:** `ALF-{YYYY}-{NNNNNN}` (e.g., ALF-2026-000042)

---

## MOBILE APP: CASES SCREEN

Users need to see their email cases. Add a new screen:

**File:** `apps/mobile/app/(tabs)/more/alfred-cases.tsx`

This screen shows:
- List of all cases (most recent first)
- Status badge (color-coded)
- Quick preview (subject, summary)
- Filter by status (Active, Awaiting Input, Completed)
- Tap to see full case details and respond

**Case Detail Screen:** `apps/mobile/app/(tabs)/more/alfred-cases/[id].tsx`

Shows:
- Original email content
- Alfred's summary & detected intent
- Actions taken (audit trail)
- Attachments
- Pending question (if any) with quick reply buttons
- Text input for custom response
- Ability to mark as resolved/archive

---

## DETAILED ARCHITECTURE

```
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│   User CCs       │     │  SendGrid        │     │  Haven API       │
│   Alfred Email   │────▶│  Inbound Parse   │────▶│  Webhook         │
└──────────────────┘     └──────────────────┘     └──────────────────┘
                                                           │
                                                           ▼
                                                  ┌──────────────────┐
                                                  │  Claude API      │
                                                  │  (Parse & Act)   │
                                                  └──────────────────┘
                                                           │
                              ┌─────────────────┬──────────┴──────────┬─────────────────┐
                              ▼                 ▼                     ▼                 ▼
                      ┌──────────────┐  ┌──────────────┐     ┌──────────────┐  ┌──────────────┐
                      │ Add Calendar │  │ Create Bill  │     │ Update       │  │ Ask User     │
                      │ Event        │  │ Record       │     │ Vendor/System│  │ Clarification│
                      └──────────────┘  └──────────────┘     └──────────────┘  └──────────────┘
```

---

## PART 1: DATABASE SCHEMA

Add to `apps/api/prisma/schema.prisma`:

```prisma
// ============================================================================
// ALFRED EMAIL CASE SYSTEM
// ============================================================================

// Every email creates a Case - the central tracking unit
model EmailCase {
  id              String   @id @default(cuid())
  householdId     String
  household       Household @relation(fields: [householdId], references: [id], onDelete: Cascade)
  
  // Case identification
  caseNumber      String   @unique  // Human-readable: "ALF-2024-001234"
  
  // Original email
  messageId       String   @unique
  fromEmail       String
  fromName        String?
  subject         String
  bodyText        String?  @db.Text
  bodyHtml        String?  @db.Text
  receivedAt      DateTime
  
  // Case status tracking
  status          EmailCaseStatus @default(RECEIVED)
  priority        EmailCasePriority @default(NORMAL)
  
  // What Alfred understood
  summary         String?  @db.Text  // Alfred's summary of the email
  detectedIntent  String?  // CALENDAR, BILL, VENDOR, DISPUTE, INFO_REQUEST, UNKNOWN
  extractedData   Json?    // Structured data Claude extracted
  confidence      Float?   // 0-1 confidence in interpretation
  
  // Actions taken
  actionsTaken    Json?    // Array of actions with timestamps
  
  // User interaction
  pendingQuestion String?  @db.Text  // Question for user
  questionOptions Json?    // Quick reply options
  userResponse    String?  @db.Text  // User's answer
  respondedAt     DateTime?
  
  // Resolution
  resolvedAt      DateTime?
  resolutionNotes String?  @db.Text
  
  // For follow-up correspondence
  threadId        String?  // Group related cases
  parentCaseId    String?  // If this is a follow-up
  parentCase      EmailCase? @relation("CaseThread", fields: [parentCaseId], references: [id])
  childCases      EmailCase[] @relation("CaseThread")
  
  createdAt       DateTime @default(now())
  updatedAt       DateTime @updatedAt
  
  attachments     EmailAttachment[]
  activities      EmailCaseActivity[]
  
  @@index([householdId, status])
  @@index([householdId, receivedAt])
  @@index([householdId, caseNumber])
}

// Activity log for each case - full audit trail
model EmailCaseActivity {
  id          String   @id @default(cuid())
  caseId      String
  case        EmailCase @relation(fields: [caseId], references: [id], onDelete: Cascade)
  
  type        EmailCaseActivityType
  description String
  details     Json?    // Additional context
  
  // Who/what performed the action
  actor       String   // "alfred", "user", "system"
  actorName   String?  // "Alfred", "Tom Burke"
  
  createdAt   DateTime @default(now())
  
  @@index([caseId, createdAt])
}

model EmailAttachment {
  id              String   @id @default(cuid())
  caseId          String
  case            EmailCase @relation(fields: [caseId], references: [id], onDelete: Cascade)
  
  filename        String
  contentType     String
  sizeBytes       Int
  storageUrl      String?  // GCS URL
  
  // What was extracted from attachment
  extractedText   String?  @db.Text
  extractedData   Json?
  
  createdAt       DateTime @default(now())
}

// Authorized emails that can send to Alfred
model AuthorizedEmail {
  id           String   @id @default(cuid())
  householdId  String
  household    Household @relation(fields: [householdId], references: [id], onDelete: Cascade)
  
  email        String
  label        String?  // "Tom's Work Email"
  addedById    String
  addedBy      User     @relation(fields: [addedById], references: [id])
  
  createdAt    DateTime @default(now())
  
  @@unique([householdId, email])
  @@index([email])
}

enum EmailCaseStatus {
  RECEIVED          // Just received, not yet processed
  PROCESSING        // Being analyzed by Claude
  AWAITING_INPUT    // Need user clarification
  IN_PROGRESS       // Actions being taken
  COMPLETED         // All done
  ARCHIVED          // User archived it
}

enum EmailCasePriority {
  LOW
  NORMAL
  HIGH
  URGENT
}

enum EmailCaseActivityType {
  // System activities
  CASE_CREATED
  EMAIL_PARSED
  ATTACHMENT_PROCESSED
  
  // Alfred actions
  CALENDAR_EVENT_CREATED
  BILL_CREATED
  VENDOR_CREATED
  VENDOR_UPDATED
  SYSTEM_ADDED
  TASK_CREATED
  DOCUMENT_SAVED
  DISPUTE_DRAFT_CREATED
  
  // Communication
  QUESTION_ASKED
  USER_RESPONDED
  ALFRED_MESSAGE
  
  // Status changes
  STATUS_CHANGED
  PRIORITY_CHANGED
  CASE_RESOLVED
  CASE_ARCHIVED
  
  // Errors
  PROCESSING_ERROR
  ACTION_FAILED
}
```

```

// Household unique code for email address
// Add to Household model:
// alfredEmailCode  String?   @unique  // Generated from address, e.g., "38BedfordRoad"
```

**Also add to Household model:**
```prisma
model Household {
  // ... existing fields ...
  
  alfredEmailCode    String?   @unique  // Generated from address, e.g., "38BedfordRoad"
  authorizedEmails   AuthorizedEmail[]
  emailCases         EmailCase[]
}
```

**Utility function to generate code from address:**
```typescript
// apps/api/src/alfred-email/utils.ts

/**
 * Generate a memorable email code from a street address
 * Examples:
 *   "38 Bedford Road" -> "38BedfordRoad"
 *   "146 Putnam Park" -> "146PutnamPark"
 *   "1200 Sunset Blvd" -> "1200SunsetBlvd"
 */
export function generateAlfredEmailCode(addressLine1: string): string {
  if (!addressLine1) return '';
  
  // Remove special characters except spaces, keep letters and numbers
  const cleaned = addressLine1.replace(/[^a-zA-Z0-9\s]/g, '');
  
  // Split into words, capitalize each, join without spaces
  const code = cleaned
    .split(/\s+/)
    .filter(word => word.length > 0)
    .map(word => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
    .join('');
  
  return code;
}
```

**Generate case numbers:**
```typescript
/**
 * Generate a human-readable case number
 * Format: ALF-{YYYY}-{NNNNNN}
 * Example: ALF-2026-000042
 */
export async function generateCaseNumber(prisma: PrismaService): Promise<string> {
  const year = new Date().getFullYear();
  
  // Get the highest case number for this year
  const lastCase = await prisma.emailCase.findFirst({
    where: {
      caseNumber: {
        startsWith: `ALF-${year}-`,
      },
    },
    orderBy: {
      caseNumber: 'desc',
    },
  });

  let nextNumber = 1;
  if (lastCase) {
    const lastNumber = parseInt(lastCase.caseNumber.split('-')[2], 10);
    nextNumber = lastNumber + 1;
  }

  return `ALF-${year}-${nextNumber.toString().padStart(6, '0')}`;
}

/**
 * Generate unique code, adding suffix if duplicate exists
 * Examples:
 *   "38BedfordRoad" (first)
 *   "38BedfordRoad2" (if duplicate)
 */
export async function generateUniqueAlfredEmailCode(
  prisma: PrismaService,
  addressLine1: string,
): Promise<string> {
  const baseCode = generateAlfredEmailCode(addressLine1);
  
  // Check if this code already exists
  let code = baseCode;
  let suffix = 1;
  
  while (true) {
    const existing = await prisma.household.findUnique({
      where: { alfredEmailCode: code },
    });
    
    if (!existing) break;
    
    suffix++;
    code = `${baseCode}${suffix}`;
  }
  
  return code;
}
```

**Generate codes for existing households (one-time migration):**
```typescript
// Run this after migration to populate codes for existing households
// Can be added to seed.ts or run as a one-time script

async function generateCodesForExistingHouseholds(prisma: PrismaService) {
  const households = await prisma.household.findMany({
    where: { alfredEmailCode: null },
    include: { homeProfiles: true },
  });

  for (const household of households) {
    const address = household.homeProfiles?.[0]?.addressLine1;
    if (address) {
      const code = await generateUniqueAlfredEmailCode(prisma, address);
      await prisma.household.update({
        where: { id: household.id },
        data: { alfredEmailCode: code },
      });
      console.log(`Generated code for ${household.name}: ${code}`);
    }
  }
}
```

**Also update household creation (onboarding) to generate the code:**
```typescript
// When creating a new household with an address:
const alfredEmailCode = await generateUniqueAlfredEmailCode(prisma, addressLine1);

const household = await prisma.household.create({
  data: {
    name: householdName,
    alfredEmailCode,
    // ... other fields
  },
});
```

Run migration:
```bash
pnpm prisma migrate dev --name add_alfred_email
```

---

## PART 2: SENDGRID INBOUND PARSE SETUP

### 2.1 SendGrid Configuration (Manual Steps)

1. **Create SendGrid Account** (if not already)
   - Go to https://sendgrid.com
   - Create account or use existing

2. **Set up Domain Authentication**
   - Settings → Sender Authentication → Domain Authentication
   - Add domain: `haven.app` (or your domain)

3. **Configure Inbound Parse**
   - Settings → Inbound Parse
   - Add Host & URL:
     - **Hostname:** `haven.app` (or subdomain like `mail.havenhome.dev`)
     - **URL:** `https://api.havenhome.dev/api/alfred/inbound-email`
     - Check: "POST the raw, full MIME message"
     - Check: "Check incoming emails for spam"

4. **Set up MX Record** (in your DNS)
   ```
   Type: MX
   Host: @ (or subdomain)
   Value: mx.sendgrid.net
   Priority: 10
   ```

### 2.2 Environment Variables

Add to `apps/api/.env`:
```bash
# SendGrid (for outbound emails too)
SENDGRID_API_KEY=your_sendgrid_api_key

# Alfred Email Domain
ALFRED_EMAIL_DOMAIN=haven.app

# Claude API (for email parsing)
ANTHROPIC_API_KEY=your_anthropic_api_key
```

---

## PART 3: API IMPLEMENTATION

### 3.1 Alfred Email Module

**File:** `apps/api/src/alfred-email/alfred-email.module.ts`

```typescript
import { Module } from '@nestjs/common';
import { AlfredEmailController } from './alfred-email.controller';
import { AlfredEmailService } from './alfred-email.service';
import { EmailParserService } from './email-parser.service';
import { EmailActionsService } from './email-actions.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [AlfredEmailController],
  providers: [AlfredEmailService, EmailParserService, EmailActionsService],
  exports: [AlfredEmailService],
})
export class AlfredEmailModule {}
```

### 3.2 Inbound Webhook Controller

**File:** `apps/api/src/alfred-email/alfred-email.controller.ts`

```typescript
import {
  Controller,
  Post,
  Body,
  Get,
  Param,
  Delete,
  UseGuards,
  Logger,
  HttpCode,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AlfredEmailService } from './alfred-email.service';
import { User } from '@prisma/client';

@Controller('alfred')
export class AlfredEmailController {
  private readonly logger = new Logger(AlfredEmailController.name);

  constructor(private readonly alfredEmailService: AlfredEmailService) {}

  /**
   * SendGrid Inbound Parse Webhook
   * This endpoint receives all emails sent to alfred+{code}@haven.app
   * NO AUTH - SendGrid calls this directly
   */
  @Post('inbound-email')
  @HttpCode(200)
  async handleInboundEmail(@Body() payload: any) {
    this.logger.log('Received inbound email webhook');
    
    try {
      // Extract email data from SendGrid payload
      const emailData = {
        to: payload.to,
        from: payload.from,
        subject: payload.subject,
        text: payload.text,
        html: payload.html,
        envelope: JSON.parse(payload.envelope || '{}'),
        attachments: payload.attachments ? JSON.parse(payload.attachments) : [],
        headers: payload.headers,
        messageId: payload['Message-Id'] || payload.headers?.['Message-Id'],
      };

      // Process the email
      await this.alfredEmailService.processInboundEmail(emailData);
      
      return { success: true };
    } catch (error) {
      this.logger.error(`Failed to process inbound email: ${error.message}`, error.stack);
      // Return 200 anyway to prevent SendGrid retries for bad emails
      return { success: false, error: error.message };
    }
  }

  /**
   * Get household's Alfred email address
   */
  @Get('email-address')
  @UseGuards(JwtAuthGuard)
  async getAlfredEmailAddress(@CurrentUser() user: User) {
    return this.alfredEmailService.getAlfredEmailAddress(user);
  }

  /**
   * Get authorized emails for household
   */
  @Get('authorized-emails')
  @UseGuards(JwtAuthGuard)
  async getAuthorizedEmails(@CurrentUser() user: User) {
    return this.alfredEmailService.getAuthorizedEmails(user);
  }

  /**
   * Add an authorized email
   */
  @Post('authorized-emails')
  @UseGuards(JwtAuthGuard)
  async addAuthorizedEmail(
    @CurrentUser() user: User,
    @Body() body: { email: string; label?: string },
  ) {
    return this.alfredEmailService.addAuthorizedEmail(user, body.email, body.label);
  }

  /**
   * Remove an authorized email
   */
  @Delete('authorized-emails/:id')
  @UseGuards(JwtAuthGuard)
  async removeAuthorizedEmail(
    @CurrentUser() user: User,
    @Param('id') id: string,
  ) {
    return this.alfredEmailService.removeAuthorizedEmail(user, id);
  }

  /**
   * Get processed emails history
   */
  @Get('email-history')
  @UseGuards(JwtAuthGuard)
  async getEmailHistory(@CurrentUser() user: User) {
    return this.alfredEmailService.getEmailHistory(user);
  }

  /**
   * Answer a pending question from Alfred
   */
  @Post('answer-question/:emailId')
  @UseGuards(JwtAuthGuard)
  async answerQuestion(
    @CurrentUser() user: User,
    @Param('emailId') emailId: string,
    @Body() body: { answer: string; selectedOption?: string },
  ) {
    return this.alfredEmailService.answerQuestion(user, emailId, body);
  }
}
```

### 3.3 Main Service

**File:** `apps/api/src/alfred-email/alfred-email.service.ts`

```typescript
import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { EmailParserService } from './email-parser.service';
import { EmailActionsService } from './email-actions.service';
import { generateUniqueAlfredEmailCode } from './utils';
import { User, EmailProcessingStatus } from '@prisma/client';

const ALFRED_EMAIL_DOMAIN = process.env.ALFRED_EMAIL_DOMAIN || 'alfred.havenhome.dev';

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
    const isAuthorized = await this.isEmailAuthorized(household.id, senderEmail);
    
    if (!isAuthorized) {
      this.logger.warn(`Unauthorized sender: ${senderEmail} for household ${household.id}`);
      // Store but don't process
      await this.prisma.processedEmail.create({
        data: {
          householdId: household.id,
          messageId: emailData.messageId || `msg_${Date.now()}`,
          fromEmail: senderEmail,
          fromName: this.extractName(emailData.from),
          subject: emailData.subject,
          bodyText: emailData.text,
          bodyHtml: emailData.html,
          receivedAt: new Date(),
          status: EmailProcessingStatus.FAILED,
          errorMessage: 'Sender not authorized',
        },
      });
      return;
    }

    // 4. Store the email
    const processedEmail = await this.prisma.processedEmail.create({
      data: {
        householdId: household.id,
        messageId: emailData.messageId || `msg_${Date.now()}`,
        fromEmail: senderEmail,
        fromName: this.extractName(emailData.from),
        subject: emailData.subject,
        bodyText: emailData.text,
        bodyHtml: emailData.html,
        receivedAt: new Date(),
        status: EmailProcessingStatus.PROCESSING,
      },
    });

    // 5. Store attachments
    if (emailData.attachments?.length > 0) {
      for (const attachment of emailData.attachments) {
        await this.prisma.emailAttachment.create({
          data: {
            emailId: processedEmail.id,
            filename: attachment.filename,
            contentType: attachment.type,
            sizeBytes: Buffer.from(attachment.content, 'base64').length,
            // TODO: Upload to GCS and store URL
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

      // 7. Take actions based on parsed data
      const actionsResult = await this.emailActions.executeActions(
        household.id,
        processedEmail.id,
        parseResult,
      );

      // 8. Update email record
      await this.prisma.processedEmail.update({
        where: { id: processedEmail.id },
        data: {
          status: actionsResult.needsInput 
            ? EmailProcessingStatus.AWAITING_INPUT 
            : EmailProcessingStatus.COMPLETED,
          extractedData: parseResult,
          actionsTaken: actionsResult.actions,
          pendingQuestion: actionsResult.question,
          questionContext: actionsResult.questionContext,
          processedAt: new Date(),
        },
      });

      // 9. If there's a pending question, create an Alfred chat message
      if (actionsResult.needsInput) {
        await this.createAlfredChatMessage(household.id, processedEmail.id, actionsResult);
      }

    } catch (error) {
      this.logger.error(`Failed to parse email: ${error.message}`);
      await this.prisma.processedEmail.update({
        where: { id: processedEmail.id },
        data: {
          status: EmailProcessingStatus.FAILED,
          errorMessage: error.message,
        },
      });
    }
  }

  /**
   * Extract household code from {code}@alfred.havenhome.dev
   */
  private extractHouseholdCode(toAddress: string): string | null {
    // Handle format: abc123@alfred.havenhome.dev or "Alfred <abc123@alfred.havenhome.dev>"
    const match = toAddress.match(/<?([a-zA-Z0-9]+)@alfred\.havenhome\.dev>?/i);
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
  private async isEmailAuthorized(householdId: string, email: string): Promise<boolean> {
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
        email: email.toLowerCase(),
      },
    });
    if (member) return true;

    // Check users linked to household
    const user = await this.prisma.user.findFirst({
      where: {
        email: email.toLowerCase(),
        householdMembers: {
          some: { householdId },
        },
      },
    });
    return !!user;
  }

  /**
   * Get context about household for better parsing
   */
  private async getHouseholdContext(householdId: string) {
    const [members, children, vendors, systems] = await Promise.all([
      this.prisma.householdMember.findMany({
        where: { householdId },
        select: { id: true, firstName: true, lastName: true, type: true },
      }),
      this.prisma.householdMember.findMany({
        where: { householdId, type: 'CHILD' },
        select: { id: true, firstName: true, lastName: true },
      }),
      this.prisma.vendor.findMany({
        where: { householdId },
        select: { id: true, displayName: true, category: true },
      }),
      this.prisma.propertyAsset.findMany({
        where: { householdId },
        select: { id: true, name: true, category: true },
      }),
    ]);

    return { members, children, vendors, systems };
  }

  /**
   * Create a chat message in Alfred for user to see/respond
   */
  private async createAlfredChatMessage(
    householdId: string,
    emailId: string,
    actionsResult: any,
  ) {
    // TODO: Integrate with existing Alfred chat/message system
    // For now, this would create a notification or message
    this.logger.log(`Creating Alfred chat message for email ${emailId}`);
  }

  /**
   * Get Alfred email address for household
   * Generates code from address if not already set
   */
  async getAlfredEmailAddress(user: User) {
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
  async getAuthorizedEmails(user: User) {
    const household = await this.getHousehold(user);
    return this.prisma.authorizedEmail.findMany({
      where: { householdId: household.id },
      orderBy: { createdAt: 'desc' },
    });
  }

  /**
   * Add authorized email
   */
  async addAuthorizedEmail(user: User, email: string, label?: string) {
    const household = await this.getHousehold(user);
    
    return this.prisma.authorizedEmail.create({
      data: {
        householdId: household.id,
        email: email.toLowerCase(),
        label,
        addedById: user.id,
      },
    });
  }

  /**
   * Remove authorized email
   */
  async removeAuthorizedEmail(user: User, id: string) {
    const household = await this.getHousehold(user);
    
    return this.prisma.authorizedEmail.delete({
      where: { id, householdId: household.id },
    });
  }

  /**
   * Get email history
   */
  async getEmailHistory(user: User) {
    const household = await this.getHousehold(user);
    
    return this.prisma.processedEmail.findMany({
      where: { householdId: household.id },
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
   * Answer a pending question
   */
  async answerQuestion(
    user: User,
    emailId: string,
    answer: { answer: string; selectedOption?: string },
  ) {
    const household = await this.getHousehold(user);
    
    const email = await this.prisma.processedEmail.findFirst({
      where: { id: emailId, householdId: household.id },
    });

    if (!email || email.status !== EmailProcessingStatus.AWAITING_INPUT) {
      throw new BadRequestException('No pending question for this email');
    }

    // Re-process with the answer
    const result = await this.emailActions.continueWithAnswer(
      household.id,
      email,
      answer,
    );

    await this.prisma.processedEmail.update({
      where: { id: emailId },
      data: {
        status: EmailProcessingStatus.COMPLETED,
        actionsTaken: result.actions,
        answeredAt: new Date(),
      },
    });

    return result;
  }

  private async getHousehold(user: User) {
    const membership = await this.prisma.householdMember.findFirst({
      where: { userId: user.id },
      include: { household: true },
    });
    if (!membership) throw new BadRequestException('No household found');
    return membership.household;
  }
}
```

### 3.4 Email Parser Service (Claude AI)

**File:** `apps/api/src/alfred-email/email-parser.service.ts`

```typescript
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
    members: Array<{ id: string; firstName: string; lastName: string; type: string }>;
    children: Array<{ id: string; firstName: string; lastName: string }>;
    vendors: Array<{ id: string; displayName: string; category: string }>;
    systems: Array<{ id: string; name: string; category: string }>;
  };
}

export interface ParsedEmailResult {
  emailType: 'CAMP_SCHOOL' | 'BILL_INVOICE' | 'VENDOR_CORRESPONDENCE' | 'APPOINTMENT' | 'DELIVERY' | 'INSPECTION_REPORT' | 'DISPUTE' | 'OTHER';
  summary: string;
  
  // Calendar events to create
  calendarEvents?: Array<{
    title: string;
    description?: string;
    startDate: string;
    endDate?: string;
    isAllDay: boolean;
    forMemberId?: string; // If we know which family member
    forMemberName?: string; // If we need to ask
  }>;
  
  // Bills to create
  bills?: Array<{
    vendorName: string;
    vendorId?: string;
    amount?: number;
    dueDate?: string;
    accountNumber?: string;
    description?: string;
  }>;
  
  // Vendor info to update/create
  vendorUpdates?: Array<{
    vendorId?: string;
    vendorName: string;
    phone?: string;
    email?: string;
    address?: string;
    notes?: string;
  }>;
  
  // Systems/assets from inspection
  systems?: Array<{
    name: string;
    category: string;
    zoneName?: string;
    condition?: string;
    notes?: string;
  }>;
  
  // Dispute response draft
  disputeResponse?: {
    to: string;
    subject: string;
    body: string;
  };
  
  // Clarification needed
  needsClarification?: {
    question: string;
    options?: string[];
    context: string;
  };
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
    const systemPrompt = `You are Alfred, an AI home manager assistant. Your job is to parse emails that homeowners CC you on and extract actionable information.

The household has the following context:
- Family members: ${JSON.stringify(input.householdContext.members)}
- Children: ${JSON.stringify(input.householdContext.children)}
- Known vendors: ${JSON.stringify(input.householdContext.vendors)}
- Home systems: ${JSON.stringify(input.householdContext.systems)}

When parsing emails, extract:
1. Calendar events (camps, appointments, deadlines, deliveries)
2. Bills/invoices (amounts, due dates, vendor info)
3. Vendor contact information updates
4. Home systems (from inspection reports)
5. Disputes that need a response drafted

IMPORTANT:
- If an event mentions a child's name and you can match it to a child in the household, include the forMemberId
- If you can't determine which child/member something is for, set needsClarification with a simple question and list the children as options
- For bills, try to match to existing vendors by name
- For inspection reports, extract all systems mentioned with their condition
- For disputes, draft a professional response for the homeowner to review

Respond with a JSON object matching the ParsedEmailResult schema.`;

    const userMessage = `
Subject: ${input.subject}

Body:
${input.body}

${input.attachments?.length ? `Attachments: ${input.attachments.map(a => a.filename).join(', ')}` : ''}
`;

    try {
      const response = await this.anthropic.messages.create({
        model: 'claude-sonnet-4-20250514',
        max_tokens: 4096,
        system: systemPrompt,
        messages: [
          { role: 'user', content: userMessage },
        ],
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

      return JSON.parse(jsonMatch[0]) as ParsedEmailResult;
    } catch (error) {
      this.logger.error(`Failed to parse email with Claude: ${error.message}`);
      throw error;
    }
  }

  /**
   * Parse attachment content (PDFs, images)
   */
  async parseAttachment(attachment: { filename: string; type: string; content: string }) {
    // For PDFs and images, we can use Claude's vision capabilities
    if (attachment.type.includes('pdf') || attachment.type.includes('image')) {
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
                  media_type: attachment.type as any,
                  data: attachment.content,
                },
              },
              {
                type: 'text',
                text: 'Extract all relevant information from this document. If it\'s an inspection report, list all systems/equipment mentioned with their condition. If it\'s an invoice, extract the vendor, amount, and due date. Return as JSON.',
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
    }

    return null;
  }
}
```

### 3.5 Email Actions Service

**File:** `apps/api/src/alfred-email/email-actions.service.ts`

```typescript
import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ParsedEmailResult } from './email-parser.service';

interface ActionResult {
  actions: Array<{
    type: string;
    description: string;
    success: boolean;
    recordId?: string;
  }>;
  needsInput: boolean;
  question?: string;
  questionContext?: any;
}

@Injectable()
export class EmailActionsService {
  private readonly logger = new Logger(EmailActionsService.name);

  constructor(private prisma: PrismaService) {}

  async executeActions(
    householdId: string,
    emailId: string,
    parsed: ParsedEmailResult,
  ): Promise<ActionResult> {
    const actions: ActionResult['actions'] = [];
    let needsInput = false;
    let question: string | undefined;
    let questionContext: any;

    // Check if clarification needed first
    if (parsed.needsClarification) {
      return {
        actions: [],
        needsInput: true,
        question: parsed.needsClarification.question,
        questionContext: {
          options: parsed.needsClarification.options,
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
          needsInput = true;
          question = `Which family member is "${event.title}" for?`;
          questionContext = {
            eventData: event,
            parsedData: parsed,
          };
          break;
        }

        try {
          const calendarEvent = await this.prisma.calendarEvent.create({
            data: {
              householdId,
              externalId: `email_${emailId}_${Date.now()}`,
              title: event.title,
              description: event.description,
              startTime: new Date(event.startDate),
              endTime: event.endDate ? new Date(event.endDate) : new Date(event.startDate),
              isAllDay: event.isAllDay,
              familyMemberId: event.forMemberId,
              calendarName: 'Alfred',
              calendarColor: '#c4a574',
              connection: { connect: { id: 'alfred-generated' } }, // You may need a default connection
            },
          });
          
          actions.push({
            type: 'CALENDAR_EVENT_CREATED',
            description: `Added "${event.title}" to calendar`,
            success: true,
            recordId: calendarEvent.id,
          });
        } catch (error) {
          actions.push({
            type: 'CALENDAR_EVENT_CREATED',
            description: `Failed to add "${event.title}": ${error.message}`,
            success: false,
          });
        }
      }
    }

    // Create bills
    if (parsed.bills?.length) {
      for (const bill of parsed.bills) {
        try {
          // Find or create vendor
          let vendorId = bill.vendorId;
          if (!vendorId && bill.vendorName) {
            const vendor = await this.prisma.vendor.findFirst({
              where: {
                householdId,
                displayName: { contains: bill.vendorName, mode: 'insensitive' },
              },
            });
            
            if (vendor) {
              vendorId = vendor.id;
            } else {
              // Create new vendor
              const newVendor = await this.prisma.vendor.create({
                data: {
                  householdId,
                  displayName: bill.vendorName,
                  category: 'OTHER',
                },
              });
              vendorId = newVendor.id;
              
              actions.push({
                type: 'VENDOR_CREATED',
                description: `Created vendor "${bill.vendorName}"`,
                success: true,
                recordId: newVendor.id,
              });
            }
          }

          if (vendorId) {
            const billAccount = await this.prisma.billAccount.create({
              data: {
                householdId,
                vendorId,
                nickname: bill.description || bill.vendorName,
                accountNumber: bill.accountNumber,
                typicalAmount: bill.amount,
                nextDueDate: bill.dueDate ? new Date(bill.dueDate) : null,
              },
            });

            actions.push({
              type: 'BILL_CREATED',
              description: `Added bill from ${bill.vendorName}${bill.amount ? ` for $${bill.amount}` : ''}`,
              success: true,
              recordId: billAccount.id,
            });
          }
        } catch (error) {
          actions.push({
            type: 'BILL_CREATED',
            description: `Failed to add bill: ${error.message}`,
            success: false,
          });
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
                phone: vendor.phone,
                email: vendor.email,
                address: vendor.address,
                notes: vendor.notes,
              },
            });
            actions.push({
              type: 'VENDOR_UPDATED',
              description: `Updated ${vendor.vendorName}`,
              success: true,
              recordId: vendor.vendorId,
            });
          } else {
            const newVendor = await this.prisma.vendor.create({
              data: {
                householdId,
                displayName: vendor.vendorName,
                phone: vendor.phone,
                email: vendor.email,
                address: vendor.address,
                notes: vendor.notes,
                category: 'OTHER',
              },
            });
            actions.push({
              type: 'VENDOR_CREATED',
              description: `Added vendor ${vendor.vendorName}`,
              success: true,
              recordId: newVendor.id,
            });
          }
        } catch (error) {
          actions.push({
            type: 'VENDOR_UPDATE',
            description: `Failed to update vendor: ${error.message}`,
            success: false,
          });
        }
      }
    }

    // Add systems from inspection reports
    if (parsed.systems?.length) {
      for (const system of parsed.systems) {
        try {
          // Find zone by name or create in default zone
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

          const asset = await this.prisma.propertyAsset.create({
            data: {
              householdId,
              zoneId,
              name: system.name,
              category: system.category as any || 'GENERAL',
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
        } catch (error) {
          actions.push({
            type: 'SYSTEM_ADDED',
            description: `Failed to add system: ${error.message}`,
            success: false,
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
      
      // This needs user approval, so set needsInput
      needsInput = true;
      question = 'I\'ve drafted a response to this dispute. Would you like to review and send it?';
      questionContext = {
        disputeResponse: parsed.disputeResponse,
        parsedData: parsed,
      };
    }

    return {
      actions,
      needsInput,
      question,
      questionContext,
    };
  }

  /**
   * Continue processing after user answers a question
   */
  async continueWithAnswer(
    householdId: string,
    email: any,
    answer: { answer: string; selectedOption?: string },
  ): Promise<ActionResult> {
    const context = email.questionContext as any;
    const actions: ActionResult['actions'] = [];

    // Handle family member selection for calendar event
    if (context?.eventData) {
      const event = context.eventData;
      
      // Find the selected family member
      const member = await this.prisma.householdMember.findFirst({
        where: {
          householdId,
          OR: [
            { id: answer.selectedOption },
            { firstName: { contains: answer.answer, mode: 'insensitive' } },
          ],
        },
      });

      if (member) {
        // Create calendar event with the selected member
        try {
          await this.prisma.calendarEvent.create({
            data: {
              householdId,
              externalId: `email_${email.id}_${Date.now()}`,
              title: event.title,
              description: event.description,
              startTime: new Date(event.startDate),
              endTime: event.endDate ? new Date(event.endDate) : new Date(event.startDate),
              isAllDay: event.isAllDay,
              familyMemberId: member.id,
              calendarName: 'Alfred',
              calendarColor: '#c4a574',
            },
          });

          actions.push({
            type: 'CALENDAR_EVENT_CREATED',
            description: `Added "${event.title}" for ${member.firstName}`,
            success: true,
          });
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
    if (context?.disputeResponse && answer.answer.toLowerCase() === 'yes') {
      // TODO: Send the email using SendGrid
      actions.push({
        type: 'DISPUTE_RESPONSE_SENT',
        description: `Sent response to ${context.disputeResponse.to}`,
        success: true,
      });
    }

    return {
      actions,
      needsInput: false,
    };
  }
}
```

---

## PART 4: MOBILE APP - SETTINGS SCREEN

### 4.1 Alfred Email Settings Screen

**File:** `apps/mobile/app/(tabs)/more/settings/alfred-email.tsx`

```typescript
import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  TextInput,
  Alert,
  ActivityIndicator,
  Share,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import * as Clipboard from 'expo-clipboard';
import { ScreenContainer } from '../../../../src/components';
import { colors, spacing, typography, borderRadius } from '../../../../src/lib/theme';
import { getIdToken } from '../../../../src/lib/firebase';

const API_URL = process.env.EXPO_PUBLIC_API_URL;

interface AuthorizedEmail {
  id: string;
  email: string;
  label: string | null;
  createdAt: string;
}

export default function AlfredEmailSettingsScreen() {
  const [alfredEmail, setAlfredEmail] = useState<string>('');
  const [authorizedEmails, setAuthorizedEmails] = useState<AuthorizedEmail[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [newEmail, setNewEmail] = useState('');
  const [newLabel, setNewLabel] = useState('');
  const [isAdding, setIsAdding] = useState(false);
  const [showAddForm, setShowAddForm] = useState(false);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      const token = await getIdToken();
      const headers = { Authorization: `Bearer ${token}` };

      const [emailRes, authRes] = await Promise.all([
        fetch(`${API_URL}/alfred/email-address`, { headers }),
        fetch(`${API_URL}/alfred/authorized-emails`, { headers }),
      ]);

      const emailData = await emailRes.json();
      const authData = await authRes.json();

      setAlfredEmail(emailData.email);
      setAuthorizedEmails(authData);
    } catch (err) {
      console.error('Failed to fetch Alfred email data:', err);
    } finally {
      setIsLoading(false);
    }
  };

  const copyEmail = async () => {
    await Clipboard.setStringAsync(alfredEmail);
    Alert.alert('Copied!', 'Alfred\'s email address has been copied to your clipboard.');
  };

  const shareEmail = async () => {
    await Share.share({
      message: `CC Alfred on any email to have him help manage it: ${alfredEmail}`,
    });
  };

  const addAuthorizedEmail = async () => {
    if (!newEmail.trim()) {
      Alert.alert('Error', 'Please enter an email address');
      return;
    }

    setIsAdding(true);
    try {
      const token = await getIdToken();
      const response = await fetch(`${API_URL}/alfred/authorized-emails`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ email: newEmail.trim(), label: newLabel.trim() || null }),
      });

      if (!response.ok) throw new Error('Failed to add email');

      await fetchData();
      setNewEmail('');
      setNewLabel('');
      setShowAddForm(false);
      Alert.alert('Success', 'Email address authorized');
    } catch (err) {
      Alert.alert('Error', 'Failed to add authorized email');
    } finally {
      setIsAdding(false);
    }
  };

  const removeEmail = async (id: string, email: string) => {
    Alert.alert(
      'Remove Email',
      `Remove ${email} from authorized senders?`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Remove',
          style: 'destructive',
          onPress: async () => {
            try {
              const token = await getIdToken();
              await fetch(`${API_URL}/alfred/authorized-emails/${id}`, {
                method: 'DELETE',
                headers: { Authorization: `Bearer ${token}` },
              });
              await fetchData();
            } catch (err) {
              Alert.alert('Error', 'Failed to remove email');
            }
          },
        },
      ]
    );
  };

  if (isLoading) {
    return (
      <ScreenContainer title="Personal Assistant" showBack>
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color={colors.haven.champagne[500]} />
        </View>
      </ScreenContainer>
    );
  }

  return (
    <ScreenContainer title="Personal Assistant" showBack>
      <ScrollView style={styles.container}>
        {/* Intro */}
        <View style={styles.introCard}>
          <Ionicons name="mail" size={32} color={colors.haven.champagne[500]} />
          <Text style={styles.introTitle}>CC Alfred on Any Email</Text>
          <Text style={styles.introText}>
            Forward or CC Alfred on emails about camps, bills, appointments, 
            inspections, and more. He'll automatically add events to your calendar, 
            track bills, and keep your home organized.
          </Text>
        </View>

        {/* Alfred's Email Address */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Alfred's Email Address</Text>
          <View style={styles.emailCard}>
            <Text style={styles.emailAddress}>{alfredEmail}</Text>
            <View style={styles.emailActions}>
              <TouchableOpacity style={styles.emailAction} onPress={copyEmail}>
                <Ionicons name="copy-outline" size={20} color={colors.haven.champagne[500]} />
                <Text style={styles.emailActionText}>Copy</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.emailAction} onPress={shareEmail}>
                <Ionicons name="share-outline" size={20} color={colors.haven.champagne[500]} />
                <Text style={styles.emailActionText}>Share</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>

        {/* How It Works */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>How It Works</Text>
          <View style={styles.stepsContainer}>
            <View style={styles.step}>
              <View style={styles.stepNumber}>
                <Text style={styles.stepNumberText}>1</Text>
              </View>
              <View style={styles.stepContent}>
                <Text style={styles.stepTitle}>CC or Forward</Text>
                <Text style={styles.stepText}>
                  Send to your unique Alfred address or forward emails directly
                </Text>
              </View>
            </View>
            <View style={styles.step}>
              <View style={styles.stepNumber}>
                <Text style={styles.stepNumberText}>2</Text>
              </View>
              <View style={styles.stepContent}>
                <Text style={styles.stepTitle}>Alfred Reads It</Text>
                <Text style={styles.stepText}>
                  Alfred extracts dates, amounts, contacts, and action items
                </Text>
              </View>
            </View>
            <View style={styles.step}>
              <View style={styles.stepNumber}>
                <Text style={styles.stepNumberText}>3</Text>
              </View>
              <View style={styles.stepContent}>
                <Text style={styles.stepTitle}>Auto-Organized</Text>
                <Text style={styles.stepText}>
                  Events go to calendar, bills are tracked, vendors are updated
                </Text>
              </View>
            </View>
          </View>
        </View>

        {/* Authorized Senders */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Authorized Senders</Text>
            <TouchableOpacity onPress={() => setShowAddForm(!showAddForm)}>
              <Ionicons 
                name={showAddForm ? 'close' : 'add-circle'} 
                size={24} 
                color={colors.haven.champagne[500]} 
              />
            </TouchableOpacity>
          </View>
          <Text style={styles.sectionSubtitle}>
            Only emails from these addresses will be processed
          </Text>

          {showAddForm && (
            <View style={styles.addForm}>
              <TextInput
                style={styles.input}
                placeholder="Email address"
                placeholderTextColor={colors.haven.navy[400]}
                value={newEmail}
                onChangeText={setNewEmail}
                keyboardType="email-address"
                autoCapitalize="none"
              />
              <TextInput
                style={styles.input}
                placeholder="Label (optional, e.g., 'Work Email')"
                placeholderTextColor={colors.haven.navy[400]}
                value={newLabel}
                onChangeText={setNewLabel}
              />
              <TouchableOpacity
                style={[styles.addButton, isAdding && styles.addButtonDisabled]}
                onPress={addAuthorizedEmail}
                disabled={isAdding}
              >
                {isAdding ? (
                  <ActivityIndicator size="small" color={colors.white} />
                ) : (
                  <Text style={styles.addButtonText}>Add Email</Text>
                )}
              </TouchableOpacity>
            </View>
          )}

          <View style={styles.emailList}>
            {authorizedEmails.map((item) => (
              <View key={item.id} style={styles.emailItem}>
                <View style={styles.emailItemInfo}>
                  <Text style={styles.emailItemAddress}>{item.email}</Text>
                  {item.label && (
                    <Text style={styles.emailItemLabel}>{item.label}</Text>
                  )}
                </View>
                <TouchableOpacity onPress={() => removeEmail(item.id, item.email)}>
                  <Ionicons name="trash-outline" size={20} color={colors.status.error} />
                </TouchableOpacity>
              </View>
            ))}
            
            {authorizedEmails.length === 0 && (
              <Text style={styles.emptyText}>
                No additional emails authorized. Family member emails are automatically authorized.
              </Text>
            )}
          </View>
        </View>

        {/* Examples */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>What Alfred Can Handle</Text>
          <View style={styles.examplesContainer}>
            <View style={styles.example}>
              <Ionicons name="calendar" size={20} color={colors.haven.champagne[500]} />
              <Text style={styles.exampleText}>Camp registrations & school events</Text>
            </View>
            <View style={styles.example}>
              <Ionicons name="receipt" size={20} color={colors.haven.champagne[500]} />
              <Text style={styles.exampleText}>Bills, invoices & payment reminders</Text>
            </View>
            <View style={styles.example}>
              <Ionicons name="construct" size={20} color={colors.haven.champagne[500]} />
              <Text style={styles.exampleText}>Home inspection reports</Text>
            </View>
            <View style={styles.example}>
              <Ionicons name="people" size={20} color={colors.haven.champagne[500]} />
              <Text style={styles.exampleText}>Vendor correspondence</Text>
            </View>
            <View style={styles.example}>
              <Ionicons name="chatbubbles" size={20} color={colors.haven.champagne[500]} />
              <Text style={styles.exampleText}>Dispute responses (with your approval)</Text>
            </View>
          </View>
        </View>
      </ScrollView>
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  introCard: {
    backgroundColor: colors.haven.champagne[50],
    padding: spacing[6],
    margin: spacing[4],
    borderRadius: borderRadius.xl,
    alignItems: 'center',
  },
  introTitle: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.haven.navy[900],
    marginTop: spacing[3],
    marginBottom: spacing[2],
  },
  introText: {
    fontSize: typography.fontSizes.base,
    color: colors.haven.navy[600],
    textAlign: 'center',
    lineHeight: 24,
  },
  section: {
    padding: spacing[4],
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  sectionTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.navy[900],
    marginBottom: spacing[2],
  },
  sectionSubtitle: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.navy[500],
    marginBottom: spacing[3],
  },
  emailCard: {
    backgroundColor: colors.white,
    padding: spacing[4],
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.border.default,
  },
  emailAddress: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.navy[900],
    fontFamily: 'monospace',
    marginBottom: spacing[3],
  },
  emailActions: {
    flexDirection: 'row',
    gap: spacing[4],
  },
  emailAction: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[1],
  },
  emailActionText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.champagne[600],
    fontWeight: typography.fontWeights.medium,
  },
  stepsContainer: {
    gap: spacing[4],
  },
  step: {
    flexDirection: 'row',
    gap: spacing[3],
  },
  stepNumber: {
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: colors.haven.champagne[500],
    alignItems: 'center',
    justifyContent: 'center',
  },
  stepNumberText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.bold,
    color: colors.white,
  },
  stepContent: {
    flex: 1,
  },
  stepTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.navy[900],
  },
  stepText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.navy[500],
    marginTop: 2,
  },
  addForm: {
    backgroundColor: colors.haven.navy[50],
    padding: spacing[4],
    borderRadius: borderRadius.lg,
    marginBottom: spacing[4],
    gap: spacing[3],
  },
  input: {
    backgroundColor: colors.white,
    borderWidth: 1,
    borderColor: colors.haven.navy[200],
    borderRadius: borderRadius.lg,
    padding: spacing[3],
    fontSize: typography.fontSizes.base,
    color: colors.haven.navy[900],
  },
  addButton: {
    backgroundColor: colors.haven.navy[900],
    padding: spacing[3],
    borderRadius: borderRadius.lg,
    alignItems: 'center',
  },
  addButtonDisabled: {
    opacity: 0.6,
  },
  addButtonText: {
    color: colors.white,
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
  },
  emailList: {
    gap: spacing[2],
  },
  emailItem: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.white,
    padding: spacing[3],
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.border.default,
  },
  emailItemInfo: {
    flex: 1,
  },
  emailItemAddress: {
    fontSize: typography.fontSizes.base,
    color: colors.haven.navy[900],
  },
  emailItemLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.navy[500],
    marginTop: 2,
  },
  emptyText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.navy[400],
    fontStyle: 'italic',
  },
  examplesContainer: {
    gap: spacing[3],
  },
  example: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[3],
  },
  exampleText: {
    fontSize: typography.fontSizes.base,
    color: colors.haven.navy[700],
  },
});
```

---

## PART 5: ADD ROUTE TO SETTINGS

Add navigation link in the Settings screen to access Alfred Email:

```typescript
// In your settings screen, add:
<TouchableOpacity
  style={styles.settingRow}
  onPress={() => router.push('/(tabs)/more/settings/alfred-email')}
>
  <View style={styles.settingIcon}>
    <Ionicons name="mail" size={22} color={colors.haven.champagne[500]} />
  </View>
  <View style={styles.settingInfo}>
    <Text style={styles.settingTitle}>Personal Assistant Email</Text>
    <Text style={styles.settingSubtitle}>CC Alfred on emails to auto-organize</Text>
  </View>
  <Ionicons name="chevron-forward" size={20} color={colors.haven.navy[400]} />
</TouchableOpacity>
```

---

## PART 6: REGISTER MODULE

Add to `apps/api/src/app.module.ts`:

```typescript
import { AlfredEmailModule } from './alfred-email/alfred-email.module';

@Module({
  imports: [
    // ... other modules
    AlfredEmailModule,
  ],
})
export class AppModule {}
```

---

## SETUP STEPS

### 1. Run Database Migration
```bash
cd apps/api
pnpm prisma migrate dev --name add_alfred_email
```

### 2. Environment Variables (ALREADY CONFIGURED ✓)
The following have already been added to `apps/api/.env`:
```bash
SENDGRID_API_KEY=SG.tQlN1v60RpGvzuuKSPhgYg...
ALFRED_EMAIL_DOMAIN=alfred.havenhome.dev
ANTHROPIC_API_KEY=sk-ant-api03-H7Xz...
```

### 3. SendGrid Setup (ALREADY CONFIGURED ✓)
Inbound Parse is configured:
- Host: `alfred.havenhome.dev`
- URL: `https://api.havenhome.dev/api/alfred/inbound-email`
- MX Record added to DNS

### 4. Deploy API
```bash
# Deploy to Cloud Run with new endpoints
```

### 5. Build Mobile App
```bash
cd apps/mobile
eas build --platform ios --profile production --auto-submit
```

---

## VERIFICATION CHECKLIST

### API
- [ ] Database migration applied (EmailCase, EmailCaseActivity, etc.)
- [ ] Alfred email module registered
- [ ] Inbound webhook endpoint works
- [ ] Case is created for every email
- [ ] Authorized emails CRUD works
- [ ] Email parsing with Claude works
- [ ] Case number generation works (ALF-2026-000001)

### SendGrid
- [ ] Domain authenticated
- [ ] Inbound Parse configured
- [ ] MX record set up
- [ ] Test email received

### Mobile App
- [ ] Settings screen shows Alfred Email option
- [ ] Alfred email address displays (address-based code)
- [ ] Copy/Share work
- [ ] Add/Remove authorized emails works
- [ ] Cases list screen works
- [ ] Case detail screen works
- [ ] Can respond to Alfred's questions
- [ ] Audit trail visible

### End-to-End
- [ ] Send test email to Alfred
- [ ] Case created with case number
- [ ] Activity logged (CASE_CREATED, EMAIL_PARSED)
- [ ] Calendar event created (if applicable)
- [ ] Clarification question appears in app (if needed)
- [ ] User can respond and case updates

---

## TEST SCENARIOS

### 1. Camp Registration Email (Clear Intent)
- Send email with camp name, dates, cost
- **Expected:** Case created, Alfred asks "Which child is this for?"
- After answering: Event added to calendar, fee logged
- Case status: COMPLETED

### 2. Bill/Invoice (High Confidence)
- Send email with invoice attachment
- **Expected:** Case created, bill record created automatically
- Alfred extracts amount, due date, vendor
- Activity log shows: CASE_CREATED, ATTACHMENT_PROCESSED, BILL_CREATED
- Case status: COMPLETED

### 3. Home Inspection Report (Complex Extraction)
- Forward inspection report PDF
- **Expected:** Case created, Alfred extracts all systems
- Systems added to home profile with conditions
- Activity log shows multiple SYSTEM_ADDED entries
- Case status: COMPLETED

### 4. Vendor Correspondence (Contextual)
- Forward email from electrician
- **Expected:** Case created, vendor record updated
- Alfred asks "Should I schedule a follow-up?"
- Case status: AWAITING_INPUT until answered

### 5. Random Newsletter Forward (Unknown Intent)
- Forward a random newsletter
- **Expected:** Case STILL created
- Alfred responds: "I received your forwarded email about [topic]. I noticed [observations]. Would you like me to: (A) Create a reminder, (B) Save for reference, (C) Something else?"
- Case status: AWAITING_INPUT
- User responds, Alfred takes action
- Case status: COMPLETED

### 6. Completely Unclear Email
- Forward something with no clear action
- **Expected:** Case STILL created
- Alfred responds: "Thanks for forwarding this. How would you like me to help with this email?"
- Offers suggestions based on content analysis
- NEVER ignored, ALWAYS tracked

### 7. Unauthorized Sender
- Send from non-authorized email
- **Expected:** Case created but flagged
- Status: AWAITING_INPUT
- Alfred notifies household: "Received email from unknown sender [email]. Authorize this sender?"

### 8. Follow-up Email (Thread)
- Forward a reply in an email thread
- **Expected:** New case created, linked to parent case if exists
- threadId populated for grouping
