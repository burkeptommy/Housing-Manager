import { Controller, Post, Get, UseGuards, Headers, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { OrchestrationService } from './orchestration.service';

@Controller('internal/payments')
export class OrchestrationController {
  constructor(
    private orchestrationService: OrchestrationService,
    private configService: ConfigService,
  ) {}

  /**
   * Manually trigger payment processing
   * Protected by cron secret
   */
  @Post('process')
  async triggerProcessing(@Headers('x-cron-secret') cronSecret: string) {
    const expectedSecret = this.configService.get<string>('CRON_SECRET');

    // In dev mode without secret, allow access for testing
    const isDev = this.configService.get<string>('NODE_ENV') !== 'production';
    if (!isDev && (!expectedSecret || cronSecret !== expectedSecret)) {
      throw new UnauthorizedException('Invalid cron secret');
    }

    return this.orchestrationService.processUpcomingBills();
  }

  /**
   * Get orchestration status
   */
  @Get('status')
  async getStatus(@Headers('x-cron-secret') cronSecret: string) {
    const expectedSecret = this.configService.get<string>('CRON_SECRET');

    // In dev mode without secret, allow access for testing
    const isDev = this.configService.get<string>('NODE_ENV') !== 'production';
    if (!isDev && (!expectedSecret || cronSecret !== expectedSecret)) {
      throw new UnauthorizedException('Invalid cron secret');
    }

    // Return basic stats
    return {
      status: 'healthy',
      timestamp: new Date().toISOString(),
    };
  }
}
