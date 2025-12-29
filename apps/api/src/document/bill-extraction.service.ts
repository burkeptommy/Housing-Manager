import { Injectable, Logger } from '@nestjs/common';
import Anthropic from '@anthropic-ai/sdk';
// eslint-disable-next-line @typescript-eslint/no-require-imports
const pdfParse = require('pdf-parse');

interface ExtractedBill {
  vendorName: string;
  category: string;
  amount: number;
  dueDate: string | null;
  accountNumber: string | null;
  frequency: string;
  confidence: number;
}

@Injectable()
export class BillExtractionService {
  private readonly logger = new Logger(BillExtractionService.name);
  private anthropic: Anthropic | null = null;

  constructor() {
    if (process.env.ANTHROPIC_API_KEY) {
      this.anthropic = new Anthropic({
        apiKey: process.env.ANTHROPIC_API_KEY,
      });
    }
  }

  /**
   * Extract bill information from an uploaded document
   */
  async extractBillFromDocument(
    fileBuffer: Buffer,
    mimeType: string,
    _fileName: string,
  ): Promise<ExtractedBill | null> {
    if (!this.anthropic) {
      this.logger.warn('Anthropic not configured, skipping bill extraction');
      return null;
    }

    let textContent = '';

    // Extract text from PDF
    if (mimeType === 'application/pdf') {
      try {
        const pdfData = await pdfParse(fileBuffer);
        textContent = pdfData.text;
      } catch (error) {
        this.logger.error('PDF parsing failed:', error);
        return null;
      }
    }

    // For images, use Claude's vision
    if (mimeType.startsWith('image/')) {
      try {
        const base64 = fileBuffer.toString('base64');
        const response = await this.anthropic.messages.create({
          model: 'claude-3-haiku-20240307',
          max_tokens: 1024,
          messages: [
            {
              role: 'user',
              content: [
                {
                  type: 'image',
                  source: {
                    type: 'base64',
                    media_type: mimeType as
                      | 'image/jpeg'
                      | 'image/png'
                      | 'image/gif'
                      | 'image/webp',
                    data: base64,
                  },
                },
                {
                  type: 'text',
                  text: `This is an image of a bill or invoice. Extract the following information and respond with JSON only:
{
  "vendorName": "Name of the company/service provider",
  "category": "One of: ELECTRIC, GAS, WATER_SEWER, INTERNET, CELL_PHONE, HOME_INSURANCE, AUTO_INSURANCE, SOFTWARE_SUBSCRIPTION, OTHER_BILL",
  "amount": 123.45 (number, the amount due),
  "dueDate": "2024-01-15" (ISO date string or null),
  "accountNumber": "Account number if visible" (string or null),
  "frequency": "MONTHLY, QUARTERLY, or ANNUAL",
  "confidence": 0.0-1.0 (how confident you are in this extraction)
}

If this doesn't appear to be a bill, respond with null.`,
                },
              ],
            },
          ],
        });

        const content = response.content[0];
        if (content.type === 'text') {
          const result = JSON.parse(content.text);
          return result;
        }
      } catch (error) {
        this.logger.error('Image bill extraction failed:', error);
        return null;
      }
    }

    // For text-based PDFs
    if (textContent) {
      try {
        const response = await this.anthropic.messages.create({
          model: 'claude-3-haiku-20240307',
          max_tokens: 1024,
          messages: [
            {
              role: 'user',
              content: `Extract bill information from this document text:

---
${textContent.slice(0, 4000)}
---

Respond with JSON only:
{
  "vendorName": "Name of the company/service provider",
  "category": "One of: ELECTRIC, GAS, WATER_SEWER, INTERNET, CELL_PHONE, HOME_INSURANCE, AUTO_INSURANCE, SOFTWARE_SUBSCRIPTION, OTHER_BILL",
  "amount": 123.45,
  "dueDate": "2024-01-15" or null,
  "accountNumber": "Account number" or null,
  "frequency": "MONTHLY, QUARTERLY, or ANNUAL",
  "confidence": 0.0-1.0
}

If this doesn't appear to be a bill, respond with null.`,
            },
          ],
        });

        const content = response.content[0];
        if (content.type === 'text') {
          return JSON.parse(content.text);
        }
      } catch (error) {
        this.logger.error('PDF bill extraction failed:', error);
      }
    }

    return null;
  }

  /**
   * Process uploaded document and optionally create a bill
   */
  async processDocumentForBills(
    _documentId: string,
    _householdId: string,
    fileBuffer: Buffer,
    mimeType: string,
    fileName: string,
  ): Promise<{ extracted: boolean; bill: ExtractedBill | null }> {
    const extracted = await this.extractBillFromDocument(
      fileBuffer,
      mimeType,
      fileName,
    );

    if (extracted && extracted.confidence > 0.7) {
      // Could automatically create a bill or prompt user
      return { extracted: true, bill: extracted };
    }

    return { extracted: false, bill: null };
  }
}
