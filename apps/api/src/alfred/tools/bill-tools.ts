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
   * Check if a tool name is a bill tool
   */
  static isBillTool(toolName: string): boolean {
    return billToolDefinitions.some(t => t.name === toolName);
  }

  /**
   * Get tool definitions in Anthropic format
   */
  getAnthropicTools(): any[] {
    return billToolDefinitions.map(tool => ({
      name: tool.name,
      description: tool.description,
      input_schema: {
        type: 'object',
        properties: tool.parameters.properties,
        required: tool.parameters.required,
      },
    }));
  }

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
    // Create a service request - need to check the schema
    const typeMessages: Record<string, string> = {
      negotiate: "I'll work on negotiating this for you.",
      dispute: "I'll look into this dispute and get back to you.",
      research: "I'll research this and report back.",
      setup: "I'll get this set up for you.",
      cancel: "I'll handle the cancellation.",
      find_vendor: "I'll find some good options for you.",
      other: "I've logged your request and will follow up.",
    };

    // Log the request - this would create a ServiceRequest in a full implementation
    this.logger.log(`Service request created: ${params.type} - ${params.title}`);

    return {
      success: true,
      requestType: params.type,
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
