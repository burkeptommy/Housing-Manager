# PHASE 4: Alfred Tool Calling for Bills

## OVERVIEW
Give Alfred the ability to create bills, trigger payments, and manage the payment system through conversation. This is the "magic" interface for users.

---

## STEP 1: Define Alfred Bill Tools

Create `/Users/tomburke/Projects/Housing-Manager/apps/api/src/alfred/tools/bill-tools.ts`:

```typescript
import { Injectable, Logger } from '@nestjs/common';
import { BillService, CreateBillDto } from '../../payments/bill.service';
import { PaymentExecutionService } from '../../payments/payment-execution.service';
import { OrchestrationService } from '../../payments/orchestration.service';
import { CardService } from '../../payments/card.service';
import { PrismaService } from '../../prisma/prisma.service';

export interface ToolDefinition {
  name: string;
  description: string;
  parameters: {
    type: string;
    properties: Record<string, any>;
    required: string[];
  };
}

export const billToolDefinitions: ToolDefinition[] = [
  {
    name: 'create_bill',
    description: 'Create a new recurring bill for automatic payment. Use this when the user wants to set up a new bill, service payment, or subscription.',
    parameters: {
      type: 'object',
      properties: {
        name: {
          type: 'string',
          description: 'Name of the bill or vendor (e.g., "Eversource Electric", "Mike\'s Landscaping")',
        },
        category: {
          type: 'string',
          enum: ['utility', 'insurance', 'mortgage', 'service', 'subscription', 'tax', 'other'],
          description: 'Category of the bill',
        },
        amount: {
          type: 'number',
          description: 'Bill amount in dollars. Omit if variable.',
        },
        isVariableAmount: {
          type: 'boolean',
          description: 'True if amount varies each month (like electric bills)',
        },
        frequency: {
          type: 'string',
          enum: ['weekly', 'biweekly', 'monthly', 'quarterly', 'semi_annual', 'annual', 'one_time'],
          description: 'How often the bill occurs',
        },
        dueDay: {
          type: 'number',
          description: 'Day of month the bill is due (1-31)',
        },
        paymentMethod: {
          type: 'string',
          enum: ['card', 'check_digital', 'check_physical'],
          description: 'How to pay: card (credit/debit), check_digital (emailed check), check_physical (mailed check)',
        },
        paymentEmail: {
          type: 'string',
          description: 'Vendor email for digital check payments',
        },
        mailingAddress: {
          type: 'string',
          description: 'Full mailing address for physical check payments',
        },
        accountNumber: {
          type: 'string',
          description: 'User\'s account number with the vendor (for reference on checks)',
        },
      },
      required: ['name', 'category', 'frequency', 'paymentMethod'],
    },
  },
  {
    name: 'get_upcoming_bills',
    description: 'Get bills that are due soon. Use this when user asks about upcoming payments or what\'s due.',
    parameters: {
      type: 'object',
      properties: {
        days: {
          type: 'number',
          description: 'Number of days to look ahead (default 7)',
        },
      },
      required: [],
    },
  },
  {
    name: 'get_bill_summary',
    description: 'Get a summary of all bills including monthly total, paid this month, and remaining. Use when user asks about their bills overview.',
    parameters: {
      type: 'object',
      properties: {},
      required: [],
    },
  },
  {
    name: 'pay_bill_now',
    description: 'Immediately pay a specific bill. Use when user wants to pay something right now.',
    parameters: {
      type: 'object',
      properties: {
        billId: {
          type: 'string',
          description: 'ID of the bill to pay',
        },
        amount: {
          type: 'number',
          description: 'Amount to pay (required for variable bills)',
        },
      },
      required: ['billId'],
    },
  },
  {
    name: 'pause_bill',
    description: 'Pause automatic payments for a bill. Use when user wants to stop autopay temporarily.',
    parameters: {
      type: 'object',
      properties: {
        billId: {
          type: 'string',
          description: 'ID of the bill to pause',
        },
      },
      required: ['billId'],
    },
  },
  {
    name: 'resume_bill',
    description: 'Resume automatic payments for a paused bill.',
    parameters: {
      type: 'object',
      properties: {
        billId: {
          type: 'string',
          description: 'ID of the bill to resume',
        },
      },
      required: ['billId'],
    },
  },
  {
    name: 'confirm_detected_bill',
    description: 'Confirm a bill that was automatically detected from bank transactions and set up autopay.',
    parameters: {
      type: 'object',
      properties: {
        detectedBillId: {
          type: 'string',
          description: 'ID of the detected bill to confirm',
        },
        paymentMethod: {
          type: 'string',
          enum: ['card', 'check_digital', 'check_physical'],
          description: 'How to pay this bill',
        },
        paymentEmail: {
          type: 'string',
          description: 'Vendor email for digital checks',
        },
        mailingAddress: {
          type: 'string',
          description: 'Address for physical checks',
        },
      },
      required: ['detectedBillId', 'paymentMethod'],
    },
  },
  {
    name: 'get_pending_approvals',
    description: 'Get payments waiting for user approval. Use when user asks about pending approvals.',
    parameters: {
      type: 'object',
      properties: {},
      required: [],
    },
  },
  {
    name: 'approve_payment',
    description: 'Approve a pending payment. Use when user confirms they want to proceed with a payment.',
    parameters: {
      type: 'object',
      properties: {
        approvalId: {
          type: 'string',
          description: 'ID of the approval to approve',
        },
      },
      required: ['approvalId'],
    },
  },
  {
    name: 'request_service',
    description: 'Request Haven team to do something like negotiate a bill, dispute a charge, or find a vendor.',
    parameters: {
      type: 'object',
      properties: {
        type: {
          type: 'string',
          enum: ['negotiate', 'dispute', 'research', 'setup', 'cancel', 'find_vendor', 'other'],
          description: 'Type of service request',
        },
        title: {
          type: 'string',
          description: 'Brief title for the request',
        },
        description: {
          type: 'string',
          description: 'Detailed description of what the user needs',
        },
        billId: {
          type: 'string',
          description: 'Related bill ID if applicable',
        },
        priority: {
          type: 'string',
          enum: ['low', 'normal', 'high', 'urgent'],
          description: 'Priority level',
        },
      },
      required: ['type', 'title', 'description'],
    },
  },
  {
    name: 'get_haven_card',
    description: 'Get information about the user\'s Haven virtual card.',
    parameters: {
      type: 'object',
      properties: {},
      required: [],
    },
  },
  {
    name: 'setup_haven_card',
    description: 'Set up a new Haven virtual card for the household. Use when user wants to enable card payments.',
    parameters: {
      type: 'object',
      properties: {},
      required: [],
    },
  },
];

@Injectable()
export class BillToolsService {
  private readonly logger = new Logger(BillToolsService.name);

  constructor(
    private billService: BillService,
    private paymentService: PaymentExecutionService,
    private orchestrationService: OrchestrationService,
    private cardService: CardService,
    private prisma: PrismaService,
  ) {}

  /**
   * Execute a tool call from Alfred
   */
  async executeTool(
    toolName: string,
    parameters: any,
    householdId: string,
    userId: string,
  ): Promise<any> {
    this.logger.log(`Executing tool: ${toolName} with params: ${JSON.stringify(parameters)}`);

    switch (toolName) {
      case 'create_bill':
        return this.createBill(householdId, parameters);

      case 'get_upcoming_bills':
        return this.getUpcomingBills(householdId, parameters.days || 7);

      case 'get_bill_summary':
        return this.billService.getBillSummary(householdId);

      case 'pay_bill_now':
        return this.payBillNow(parameters.billId, parameters.amount);

      case 'pause_bill':
        return this.billService.toggleAutopay(parameters.billId, householdId, false);

      case 'resume_bill':
        return this.billService.toggleAutopay(parameters.billId, householdId, true);

      case 'confirm_detected_bill':
        return this.confirmDetectedBill(householdId, parameters);

      case 'get_pending_approvals':
        return this.orchestrationService.getPendingApprovals(householdId);

      case 'approve_payment':
        return this.orchestrationService.processApproval(parameters.approvalId, true, userId);

      case 'request_service':
        return this.createServiceRequest(householdId, userId, parameters);

      case 'get_haven_card':
        return this.cardService.getHouseholdCard(householdId);

      case 'setup_haven_card':
        return this.cardService.createHouseholdCard(householdId, userId);

      default:
        throw new Error(`Unknown tool: ${toolName}`);
    }
  }

  private async createBill(householdId: string, params: any) {
    const billData: CreateBillDto = {
      name: params.name,
      category: params.category,
      amount: params.amount,
      isVariableAmount: params.isVariableAmount || !params.amount,
      frequency: params.frequency,
      dueDay: params.dueDay,
      paymentMethod: params.paymentMethod,
      paymentEmail: params.paymentEmail,
      mailingAddress: params.mailingAddress,
      accountNumber: params.accountNumber,
    };

    const bill = await this.billService.createBill(householdId, billData);

    return {
      success: true,
      bill: {
        id: bill.id,
        name: bill.name,
        amount: bill.amount,
        frequency: bill.frequency,
        paymentMethod: bill.paymentMethod,
        nextDueDate: bill.nextDueDate,
      },
      message: `I've set up ${bill.name} for automatic payment. ${
        bill.amount ? `$${bill.amount}` : 'Variable amount'
      } ${bill.frequency} via ${this.formatPaymentMethod(bill.paymentMethod)}.`,
    };
  }

  private async getUpcomingBills(householdId: string, days: number) {
    const bills = await this.billService.getUpcomingBills(householdId, days);

    return {
      bills: bills.map(b => ({
        id: b.id,
        name: b.name,
        amount: b.amount || b.averageAmount,
        dueDate: b.nextDueDate,
        paymentMethod: b.paymentMethod,
        autopayEnabled: b.autopayEnabled,
      })),
      count: bills.length,
      totalAmount: bills.reduce((sum, b) => sum + (b.amount || b.averageAmount || 0), 0),
    };
  }

  private async payBillNow(billId: string, amount?: number) {
    const result = await this.paymentService.executePayment(billId, amount);

    if (result.success) {
      return {
        success: true,
        paymentId: result.paymentId,
        amount: result.amount,
        message: `Payment of $${result.amount} has been processed.`,
      };
    } else {
      return {
        success: false,
        error: result.error,
        message: `Payment failed: ${result.error}`,
      };
    }
  }

  private async confirmDetectedBill(householdId: string, params: any) {
    const bill = await this.billService.createBillFromDetected(
      householdId,
      params.detectedBillId,
      params.paymentMethod,
      {
        paymentEmail: params.paymentEmail,
        mailingAddress: params.mailingAddress,
      },
    );

    return {
      success: true,
      bill: {
        id: bill.id,
        name: bill.name,
        amount: bill.amount,
        frequency: bill.frequency,
      },
      message: `I've set up automatic payments for ${bill.name}.`,
    };
  }

  private async createServiceRequest(householdId: string, userId: string, params: any) {
    const request = await this.prisma.serviceRequest.create({
      data: {
        householdId,
        userId,
        type: params.type,
        title: params.title,
        description: params.description,
        billId: params.billId,
        priority: params.priority || 'normal',
      },
    });

    const typeMessages: Record<string, string> = {
      negotiate: "I'll work on negotiating this for you.",
      dispute: "I'll look into this dispute and get back to you.",
      research: "I'll research this and report back.",
      setup: "I'll get this set up for you.",
      cancel: "I'll handle the cancellation.",
      find_vendor: "I'll find some good options for you.",
      other: "I've logged your request and will follow up.",
    };

    return {
      success: true,
      requestId: request.id,
      message: typeMessages[params.type] || "I've logged your request.",
    };
  }

  private formatPaymentMethod(method: string): string {
    const formats: Record<string, string> = {
      card: 'credit/debit card',
      check_digital: 'digital check',
      check_physical: 'mailed check',
    };
    return formats[method] || method;
  }
}
```

---

## STEP 2: Create Alfred Tools Module

Create `/Users/tomburke/Projects/Housing-Manager/apps/api/src/alfred/tools/tools.module.ts`:

```typescript
import { Module } from '@nestjs/common';
import { PrismaModule } from '../../prisma/prisma.module';
import { PaymentsModule } from '../../payments/payments.module';
import { BillToolsService, billToolDefinitions } from './bill-tools';

@Module({
  imports: [PrismaModule, PaymentsModule],
  providers: [BillToolsService],
  exports: [BillToolsService],
})
export class AlfredToolsModule {}

export { BillToolsService, billToolDefinitions };
```

---

## STEP 3: Integrate Tools with Alfred Service

Update the Alfred service to include bill tools. Find the Alfred service file (likely at `apps/api/src/alfred/alfred.service.ts` or similar) and add:

```typescript
import { BillToolsService, billToolDefinitions } from './tools/bill-tools';

// Add to constructor
constructor(
  // ... existing dependencies
  private billTools: BillToolsService,
) {}

// Add tool definitions to the Claude API call
const tools = [
  ...billToolDefinitions,
  // ... other existing tools
];

// Handle tool calls in the response processing
async handleToolCall(toolName: string, parameters: any, householdId: string, userId: string) {
  // Check if it's a bill tool
  if (billToolDefinitions.some(t => t.name === toolName)) {
    return this.billTools.executeTool(toolName, parameters, householdId, userId);
  }
  
  // ... handle other tools
}
```

---

## STEP 4: Update Alfred Module

Update the Alfred module to import the tools:

```typescript
import { Module } from '@nestjs/common';
import { AlfredToolsModule } from './tools/tools.module';
import { AlfredService } from './alfred.service';
import { AlfredController } from './alfred.controller';

@Module({
  imports: [
    AlfredToolsModule,
    // ... other imports
  ],
  providers: [AlfredService],
  controllers: [AlfredController],
  exports: [AlfredService],
})
export class AlfredModule {}
```

---

## STEP 5: Example Alfred Conversations

After this is integrated, Alfred can handle conversations like:

### Example 1: Setting Up a Bill
```
User: "I need to set up payment for my landscaper Mike. He charges $400 a month."

Alfred: "I'll set that up! How does Mike prefer to be paid?
• Credit/debit card
• Digital check (emailed to him)  
• Physical check (mailed)"

User: "He only takes checks, mail it to him at 123 Oak Lane, Greenwich CT 06830"

Alfred: [calls create_bill tool]

Alfred: "Done! I've set up Mike's Landscaping:
• $400/month via mailed check
• Address: 123 Oak Lane, Greenwich CT 06830
• First check will be mailed on the 1st

I'll send you a confirmation before each payment."
```

### Example 2: Checking Bills
```
User: "What bills do I have coming up?"

Alfred: [calls get_upcoming_bills tool]

Alfred: "You have 3 bills due this week totaling $1,047:

📍 Eversource Electric - $312 due Thursday
📍 Mike's Landscaping - $400 due Friday  
📍 Netflix - $22.99 due Saturday

All are set to autopay. Need me to change anything?"
```

### Example 3: Service Request
```
User: "My cable bill seems too high. Can you try to get it lowered?"

Alfred: [calls request_service tool]

Alfred: "I'll work on negotiating your cable bill. I'll call them, try to find any available promotions or discounts, and let you know what I can get.

This usually takes 1-2 business days. I'll send you an update when I have news!"
```

---

## STEP 6: Test Tool Execution

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/api
pnpm dev
```

Test via Alfred endpoint (or direct tool test endpoint if you create one):

```bash
curl -X POST http://localhost:4000/api/alfred/chat \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Set up a monthly payment of $350 for Crystal Clear Pools. They take cards."
  }'
```

---

## VERIFICATION CHECKLIST

- [ ] Bill tool definitions created
- [ ] BillToolsService created with all tool handlers
- [ ] AlfredToolsModule created
- [ ] Tools integrated with Alfred service
- [ ] Alfred can create bills via conversation
- [ ] Alfred can get bill summaries
- [ ] Alfred can trigger payments
- [ ] Alfred can create service requests

---

## NEXT STEP

Proceed to PHASE-5-financial-dashboard.md
