import { Injectable, Logger } from '@nestjs/common';
import { BillService } from '../../payments/bill.service';
import { OrchestrationService } from '../../payments/orchestration.service';
import { PrismaService } from '../../prisma/prisma.service';
import { SavingsIntelligenceService } from '../../budgeting/savings-intelligence.service';

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
    name: 'get_pending_approvals',
    description: 'Get payments waiting for user approval. Use when user asks about pending approvals.',
    parameters: {
      type: 'object',
      properties: {},
      required: [],
    },
  },
  {
    name: 'find_savings',
    description: 'Find savings opportunities for the household including refinancing, rate optimization, subscription audit, and insurance bundling. Use when user asks about saving money, finding better rates, reviewing subscriptions, or reducing bills.',
    parameters: {
      type: 'object',
      properties: {
        focus: {
          type: 'string',
          enum: ['all', 'refinancing', 'rates', 'subscriptions', 'insurance'],
          description: 'Which area to focus on (default: all)',
        },
      },
      required: [],
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
];

@Injectable()
export class BillToolsService {
  private readonly logger = new Logger(BillToolsService.name);

  constructor(
    private billService: BillService,
    private orchestrationService: OrchestrationService,
    private prisma: PrismaService,
    private savingsService: SavingsIntelligenceService,
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

    try {
      switch (toolName) {
        case 'get_upcoming_bills':
          return await this.getUpcomingBills(householdId, parameters.days || 7);

        case 'get_bill_summary':
          return await this.billService.getBillSummary(householdId);

        case 'get_pending_approvals':
          return await this.orchestrationService.getPendingApprovals(householdId);

        case 'find_savings':
          return await this.findSavings(householdId, userId, parameters.focus);

        case 'request_service':
          return await this.createServiceRequest(householdId, userId, parameters);

        default:
          return { success: false, error: `Unknown tool: ${toolName}`, message: `I don't know how to do that yet.` };
      }
    } catch (error) {
      this.logger.error(`Error executing bill tool ${toolName}:`, error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
        message: `Sorry, I ran into an issue: ${error instanceof Error ? error.message : 'Unknown error'}`,
      };
    }
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

  private async createServiceRequest(householdId: string, userId: string, params: any) {
    const typeMessages: Record<string, string> = {
      negotiate: "I'll work on negotiating this for you.",
      dispute: "I'll look into this dispute and get back to you.",
      research: "I'll research this and report back.",
      setup: "I'll get this set up for you.",
      cancel: "I'll handle the cancellation.",
      find_vendor: "I'll find some good options for you.",
      other: "I've logged your request and will follow up.",
    };

    const quickCategoryMap: Record<string, string> = {
      negotiate: 'RESEARCH',
      dispute: 'RESEARCH',
      research: 'RESEARCH',
      setup: 'SCHEDULE',
      cancel: 'OTHER',
      find_vendor: 'RESEARCH',
      other: 'OTHER',
    };

    const priorityMap: Record<string, string> = {
      low: 'LOW',
      normal: 'MEDIUM',
      high: 'HIGH',
      urgent: 'URGENT',
    };

    const serviceRequest = await this.prisma.serviceRequest.create({
      data: {
        householdId,
        createdById: userId,
        title: params.title,
        description: params.description,
        status: 'SUBMITTED',
        priority: (priorityMap[params.priority] || 'MEDIUM') as any,
        quickCategory: (quickCategoryMap[params.type] || 'OTHER') as any,
      },
    });

    this.logger.log(`Service request created: ${serviceRequest.id} - ${params.type} - ${params.title}`);

    return {
      success: true,
      requestId: serviceRequest.id,
      requestType: params.type,
      message: typeMessages[params.type] || "I've logged your request.",
    };
  }

  private async findSavings(householdId: string, userId: string, focus?: string) {
    const user = { userId } as any;

    try {
      if (focus === 'refinancing') {
        const result = await this.savingsService.getRefinancingOpportunities(user);
        return {
          success: true,
          type: 'refinancing',
          ...result,
          message: result.opportunities.length > 0
            ? `Found ${result.opportunities.length} refinancing opportunity(ies) with potential savings of $${result.totalPotentialSavings}/month.`
            : 'No refinancing opportunities found at current market rates.',
        };
      }

      if (focus === 'rates') {
        const result = await this.savingsService.getRateOptimizations(user);
        return {
          success: true,
          type: 'rate_optimization',
          ...result,
          message: result.optimizations.length > 0
            ? `Found ${result.optimizations.length} categories where spending is above local median.`
            : 'Your spending is in line with local averages.',
        };
      }

      // Default: full summary
      const summary = await this.savingsService.getSavingsSummary(user);
      return {
        success: true,
        type: 'savings_summary',
        ...summary,
        message: summary.totalMonthlySavings > 0
          ? `Found potential savings of $${summary.totalMonthlySavings}/month ($${summary.totalAnnualSavings}/year) across refinancing, rate optimization, and insurance bundling.`
          : 'No major savings opportunities detected right now. Your spending looks well-optimized!',
      };
    } catch (error) {
      this.logger.error('Error finding savings:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
        message: 'Sorry, I had trouble analyzing your savings opportunities.',
      };
    }
  }

}
