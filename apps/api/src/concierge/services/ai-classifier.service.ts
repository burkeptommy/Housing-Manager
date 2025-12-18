import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import OpenAI from 'openai';
import { RequestCategory, TriagePriority } from '@prisma/client';

export interface ClassificationResult {
  category: RequestCategory;
  confidence: number;
  priority: TriagePriority;
  summary: string;
  extractedEntities: {
    vendor?: string;
    amount?: number;
    date?: string;
    location?: string;
    eventTitle?: string;
    urgencyKeywords?: string[];
  };
  suggestedActions: SuggestedAction[];
  reasoning: string;
}

export interface SuggestedAction {
  actionType: string;
  title: string;
  description: string;
  confidence: number;
  actionData: Record<string, unknown>;
}

const CLASSIFICATION_SYSTEM_PROMPT = `You are an AI assistant for a home management service called Haven. Your job is to analyze incoming requests from homeowners and classify them into categories.

Analyze the request and classify it into ONE of these categories:
- BILL: Financial obligation or invoice (e.g., "Here's my electric bill", forwarded invoices, statements)
- FIX: Maintenance issue or repair needed (e.g., "Leaky faucet", "AC not working", "Broken door hinge")
- PROJECT: Home renovation or improvement idea (e.g., "Want to add a patio", "Thinking about new kitchen")
- CALENDAR: Event or scheduling request (e.g., "Add soccer practice to calendar", "Schedule dentist appointment")
- TRIP: Travel planning request (e.g., "Plan trip to Aspen", "Book flights for vacation")
- INQUIRY: General question or information request that doesn't fit other categories
- UNKNOWN: Cannot determine the intent

Also determine the priority:
- URGENT: Immediate attention needed (safety issues, major system failures, time-sensitive)
- HIGH: Important but not emergency (affecting daily life, financial deadlines soon)
- MEDIUM: Standard request (routine maintenance, general planning)
- LOW: Nice to have (future ideas, minor convenience)

Extract any relevant entities:
- For BILL: vendor name, amount, due date
- For FIX: what's broken, location in house, urgency indicators
- For PROJECT: project type, scope, estimated budget mentions
- For CALENDAR: event title, date/time, location, recurring
- For TRIP: destination, dates, number of travelers

Suggest specific actions that can be taken.

Respond in JSON format:
{
  "category": "CATEGORY",
  "confidence": 0.0-1.0,
  "priority": "PRIORITY",
  "summary": "Brief human-readable summary",
  "extractedEntities": {
    "vendor": "if applicable",
    "amount": 0.00,
    "date": "YYYY-MM-DD if found",
    "location": "if applicable",
    "eventTitle": "if calendar event"
  },
  "suggestedActions": [
    {
      "actionType": "PAY_BILL|CREATE_WORK_ORDER|CREATE_PROJECT|CREATE_EVENT|CREATE_TRIP|RESPOND_INQUIRY",
      "title": "Action title",
      "description": "What this action will do",
      "confidence": 0.0-1.0,
      "actionData": {}
    }
  ],
  "reasoning": "Brief explanation of classification"
}`;

@Injectable()
export class AIClassifierService {
  private readonly logger = new Logger(AIClassifierService.name);
  private openai: OpenAI;

  constructor(private readonly configService: ConfigService) {
    const apiKey = this.configService.get<string>('OPENAI_API_KEY');
    if (apiKey) {
      this.openai = new OpenAI({ apiKey });
    } else {
      this.logger.warn('OPENAI_API_KEY not configured - AI classification disabled');
    }
  }

  /**
   * Classify an inbound request using GPT-4o
   */
  async classifyRequest(params: {
    subject?: string;
    body: string;
    senderEmail?: string;
    senderName?: string;
    attachmentSummaries?: string[];
  }): Promise<ClassificationResult> {
    if (!this.openai) {
      // Return a default classification if OpenAI is not configured
      return this.getDefaultClassification(params.body);
    }

    try {
      // Build the message for classification
      const userMessage = this.buildUserMessage(params);

      const response = await this.openai.chat.completions.create({
        model: 'gpt-4o',
        messages: [
          { role: 'system', content: CLASSIFICATION_SYSTEM_PROMPT },
          { role: 'user', content: userMessage },
        ],
        response_format: { type: 'json_object' },
        temperature: 0.3, // Lower temperature for more consistent classification
        max_tokens: 1000,
      });

      const content = response.choices[0]?.message?.content;
      if (!content) {
        throw new Error('No response from OpenAI');
      }

      const parsed = JSON.parse(content) as ClassificationResult;

      // Validate and normalize the result
      return this.normalizeClassification(parsed);
    } catch (error) {
      this.logger.error('Error classifying request:', error);
      return this.getDefaultClassification(params.body);
    }
  }

  /**
   * Extract text from an attachment (PDF, image) using GPT-4o vision
   */
  async extractAttachmentContent(params: {
    contentType: string;
    base64Content?: string;
    url?: string;
  }): Promise<{ text: string; analysis: Record<string, unknown> }> {
    if (!this.openai) {
      return { text: '', analysis: {} };
    }

    try {
      // For images and PDFs, use vision capabilities
      if (params.contentType.startsWith('image/') || params.contentType === 'application/pdf') {
        const imageUrl = params.url || `data:${params.contentType};base64,${params.base64Content}`;

        const response = await this.openai.chat.completions.create({
          model: 'gpt-4o',
          messages: [
            {
              role: 'user',
              content: [
                {
                  type: 'text',
                  text: `Extract all text and key information from this document. If it's a bill or invoice, extract: vendor name, amount due, due date, account number. If it's a receipt, extract: vendor, items, total. If it's a quote, extract: vendor, description of work, price. Return JSON: { "extractedText": "...", "documentType": "bill|receipt|quote|other", "entities": { ... } }`,
                },
                {
                  type: 'image_url',
                  image_url: { url: imageUrl },
                },
              ],
            },
          ],
          response_format: { type: 'json_object' },
          max_tokens: 2000,
        });

        const content = response.choices[0]?.message?.content;
        if (content) {
          const parsed = JSON.parse(content);
          return {
            text: parsed.extractedText || '',
            analysis: parsed,
          };
        }
      }

      return { text: '', analysis: {} };
    } catch (error) {
      this.logger.error('Error extracting attachment content:', error);
      return { text: '', analysis: {} };
    }
  }

  /**
   * Generate a response for the chat concierge
   */
  async generateChatResponse(params: {
    conversationHistory: Array<{ role: 'user' | 'assistant'; content: string }>;
    householdContext: Record<string, unknown>;
  }): Promise<{ response: string; shouldCreateRequest: boolean; requestData?: Record<string, unknown> }> {
    if (!this.openai) {
      return {
        response: "I'm sorry, the AI assistant is currently unavailable. Please try again later or contact support.",
        shouldCreateRequest: false,
      };
    }

    try {
      const systemPrompt = `You are Haven's AI concierge assistant. You help homeowners manage their homes by:
- Answering questions about home maintenance
- Helping them report issues that need fixing
- Discussing renovation project ideas
- Managing their calendar and schedules
- Planning trips

When a user describes something that requires action (a repair, a bill to pay, an event to schedule, etc.), ask clarifying questions if needed, then confirm you'll create a request for their home manager.

Context about this household:
${JSON.stringify(params.householdContext, null, 2)}

If the user's message is a clear request for action, include in your response:
[CREATE_REQUEST: {"category": "BILL|FIX|PROJECT|CALENDAR|TRIP", "title": "...", "description": "...", "priority": "LOW|MEDIUM|HIGH|URGENT"}]`;

      const messages: Array<{ role: 'system' | 'user' | 'assistant'; content: string }> = [
        { role: 'system', content: systemPrompt },
        ...params.conversationHistory,
      ];

      const response = await this.openai.chat.completions.create({
        model: 'gpt-4o',
        messages,
        temperature: 0.7,
        max_tokens: 1000,
      });

      const content = response.choices[0]?.message?.content || '';

      // Check if the response includes a request creation directive
      const requestMatch = content.match(/\[CREATE_REQUEST: (.+?)\]/);
      if (requestMatch) {
        try {
          const requestData = JSON.parse(requestMatch[1]);
          const cleanedResponse = content.replace(/\[CREATE_REQUEST: .+?\]/, '').trim();
          return {
            response: cleanedResponse,
            shouldCreateRequest: true,
            requestData,
          };
        } catch {
          // Ignore parsing errors
        }
      }

      return {
        response: content,
        shouldCreateRequest: false,
      };
    } catch (error) {
      this.logger.error('Error generating chat response:', error);
      return {
        response: "I'm sorry, I encountered an error processing your request. Please try again.",
        shouldCreateRequest: false,
      };
    }
  }

  private buildUserMessage(params: {
    subject?: string;
    body: string;
    senderEmail?: string;
    senderName?: string;
    attachmentSummaries?: string[];
  }): string {
    let message = '';

    if (params.senderName || params.senderEmail) {
      message += `From: ${params.senderName || ''} <${params.senderEmail || ''}>\n`;
    }

    if (params.subject) {
      message += `Subject: ${params.subject}\n`;
    }

    message += `\nMessage:\n${params.body}`;

    if (params.attachmentSummaries && params.attachmentSummaries.length > 0) {
      message += `\n\nAttachments:\n${params.attachmentSummaries.join('\n')}`;
    }

    return message;
  }

  private normalizeClassification(parsed: Partial<ClassificationResult>): ClassificationResult {
    // Ensure category is valid
    const validCategories = ['BILL', 'FIX', 'PROJECT', 'CALENDAR', 'TRIP', 'INQUIRY', 'UNKNOWN'];
    const category = validCategories.includes(parsed.category as string)
      ? (parsed.category as RequestCategory)
      : RequestCategory.UNKNOWN;

    // Ensure priority is valid
    const validPriorities = ['LOW', 'MEDIUM', 'HIGH', 'URGENT'];
    const priority = validPriorities.includes(parsed.priority as string)
      ? (parsed.priority as TriagePriority)
      : TriagePriority.MEDIUM;

    return {
      category,
      confidence: Math.min(1, Math.max(0, parsed.confidence || 0.5)),
      priority,
      summary: parsed.summary || 'Request received',
      extractedEntities: parsed.extractedEntities || {},
      suggestedActions: parsed.suggestedActions || [],
      reasoning: parsed.reasoning || '',
    };
  }

  private getDefaultClassification(body: string): ClassificationResult {
    // Simple keyword-based fallback classification
    const lowerBody = body.toLowerCase();

    let category: RequestCategory = RequestCategory.UNKNOWN;
    let priority: TriagePriority = TriagePriority.MEDIUM;

    if (lowerBody.includes('bill') || lowerBody.includes('invoice') || lowerBody.includes('payment') || lowerBody.includes('due')) {
      category = RequestCategory.BILL;
    } else if (lowerBody.includes('broken') || lowerBody.includes('leak') || lowerBody.includes('fix') || lowerBody.includes('repair')) {
      category = RequestCategory.FIX;
      if (lowerBody.includes('emergency') || lowerBody.includes('urgent') || lowerBody.includes('flood')) {
        priority = TriagePriority.URGENT;
      }
    } else if (lowerBody.includes('renovate') || lowerBody.includes('remodel') || lowerBody.includes('project') || lowerBody.includes('build')) {
      category = RequestCategory.PROJECT;
    } else if (lowerBody.includes('schedule') || lowerBody.includes('calendar') || lowerBody.includes('appointment') || lowerBody.includes('event')) {
      category = RequestCategory.CALENDAR;
    } else if (lowerBody.includes('trip') || lowerBody.includes('travel') || lowerBody.includes('vacation') || lowerBody.includes('flight')) {
      category = RequestCategory.TRIP;
    }

    return {
      category,
      confidence: 0.3, // Low confidence for fallback
      priority,
      summary: 'Request pending AI classification',
      extractedEntities: {},
      suggestedActions: [],
      reasoning: 'Classified using keyword fallback (AI unavailable)',
    };
  }
}
