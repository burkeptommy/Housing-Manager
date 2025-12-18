import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export interface VendorAddress {
  name: string;
  line1: string;
  line2?: string;
  city: string;
  state: string;
  zip: string;
  country?: string;
}

export interface CheckbookCheckRequest {
  vendorAddress: VendorAddress;
  amount: number;
  memo?: string;
  description?: string;
}

export interface CheckbookCheckResponse {
  checkId: string;
  status: 'QUEUED' | 'MAILED' | 'DELIVERED' | 'CASHED' | 'VOIDED';
  checkNumber?: string;
  estimatedDelivery?: string;
  trackingNumber?: string;
}

// Checkbook.io API response type
interface CheckbookApiResponse {
  id: string;
  status: string;
  number?: string;
  estimated_delivery?: string;
  tracking_number?: string;
}

/**
 * CheckbookService - Integrates with Checkbook.io API for sending physical checks
 *
 * Business Model: Haven pays vendors immediately ("The Float") using various methods.
 * For vendors without digital payment options, we mail physical checks.
 *
 * API Documentation: https://docs.checkbook.io/
 */
@Injectable()
export class CheckbookService {
  private readonly logger = new Logger(CheckbookService.name);
  private readonly apiKey: string;
  private readonly apiSecret: string;
  private readonly baseUrl: string;
  private readonly isTestMode: boolean;

  constructor(private readonly configService: ConfigService) {
    this.apiKey = this.configService.get<string>('CHECKBOOK_API_KEY') || '';
    this.apiSecret = this.configService.get<string>('CHECKBOOK_API_SECRET') || '';
    this.baseUrl = this.configService.get<string>('CHECKBOOK_API_URL') || 'https://api.checkbook.io/v3';
    this.isTestMode = this.configService.get<string>('CHECKBOOK_TEST_MODE') === 'true' || !this.apiKey;
  }

  /**
   * Send a physical check to a vendor
   *
   * @param request - Check request details including vendor address and amount
   * @returns Check response with checkId and status
   */
  async sendPhysicalCheck(request: CheckbookCheckRequest): Promise<CheckbookCheckResponse> {
    this.logger.log(`Sending physical check to ${request.vendorAddress.name} for $${request.amount}`);

    // In test mode, simulate the API response
    if (this.isTestMode) {
      return this.simulateCheckResponse(request);
    }

    try {
      const response = await fetch(`${this.baseUrl}/check`, {
        method: 'POST',
        headers: {
          'Authorization': this.getAuthHeader(),
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          recipient: {
            name: request.vendorAddress.name,
            address: {
              line_1: request.vendorAddress.line1,
              line_2: request.vendorAddress.line2 || '',
              city: request.vendorAddress.city,
              state: request.vendorAddress.state,
              zip: request.vendorAddress.zip,
              country: request.vendorAddress.country || 'US',
            },
          },
          amount: request.amount,
          description: request.description || `Payment from Haven Home Management`,
          memo: request.memo || 'Services Rendered',
        }),
      });

      if (!response.ok) {
        const errorBody = await response.text();
        this.logger.error(`Checkbook API error: ${response.status} - ${errorBody}`);
        throw new Error(`Checkbook API error: ${response.status}`);
      }

      const data = (await response.json()) as CheckbookApiResponse;

      return {
        checkId: data.id,
        status: this.mapCheckbookStatus(data.status),
        checkNumber: data.number,
        estimatedDelivery: data.estimated_delivery,
        trackingNumber: data.tracking_number,
      };
    } catch (error) {
      this.logger.error(`Failed to send check: ${error}`);
      throw error;
    }
  }

  /**
   * Get the status of a previously sent check
   */
  async getCheckStatus(checkId: string): Promise<CheckbookCheckResponse> {
    if (this.isTestMode) {
      return {
        checkId,
        status: 'MAILED',
        checkNumber: `CHK-${checkId.substring(0, 8)}`,
        estimatedDelivery: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000).toISOString(),
      };
    }

    const response = await fetch(`${this.baseUrl}/check/${checkId}`, {
      method: 'GET',
      headers: {
        'Authorization': this.getAuthHeader(),
      },
    });

    if (!response.ok) {
      throw new Error(`Failed to get check status: ${response.status}`);
    }

    const data = (await response.json()) as CheckbookApiResponse;

    return {
      checkId: data.id,
      status: this.mapCheckbookStatus(data.status),
      checkNumber: data.number,
      estimatedDelivery: data.estimated_delivery,
      trackingNumber: data.tracking_number,
    };
  }

  /**
   * Void/cancel a check that hasn't been cashed yet
   */
  async voidCheck(checkId: string): Promise<boolean> {
    if (this.isTestMode) {
      this.logger.log(`[TEST MODE] Voiding check ${checkId}`);
      return true;
    }

    const response = await fetch(`${this.baseUrl}/check/${checkId}/void`, {
      method: 'POST',
      headers: {
        'Authorization': this.getAuthHeader(),
      },
    });

    return response.ok;
  }

  private getAuthHeader(): string {
    const credentials = Buffer.from(`${this.apiKey}:${this.apiSecret}`).toString('base64');
    return `Basic ${credentials}`;
  }

  private mapCheckbookStatus(status: string): CheckbookCheckResponse['status'] {
    const statusMap: Record<string, CheckbookCheckResponse['status']> = {
      'queued': 'QUEUED',
      'in_production': 'QUEUED',
      'mailed': 'MAILED',
      'in_transit': 'MAILED',
      'delivered': 'DELIVERED',
      'processed': 'CASHED',
      'voided': 'VOIDED',
      'returned': 'VOIDED',
    };
    return statusMap[status.toLowerCase()] || 'QUEUED';
  }

  /**
   * Simulate check response for test mode
   */
  private simulateCheckResponse(request: CheckbookCheckRequest): CheckbookCheckResponse {
    const checkId = `chk_test_${Date.now()}_${Math.random().toString(36).substring(7)}`;
    const checkNumber = `CHK-${Math.floor(100000 + Math.random() * 900000)}`;

    this.logger.log(`[TEST MODE] Simulated check ${checkNumber} for $${request.amount} to ${request.vendorAddress.name}`);

    return {
      checkId,
      status: 'QUEUED',
      checkNumber,
      estimatedDelivery: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000).toISOString(),
    };
  }
}
