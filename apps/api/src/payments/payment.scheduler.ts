import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { OrchestrationService } from './orchestration.service';

@Injectable()
export class PaymentScheduler {
  private readonly logger = new Logger(PaymentScheduler.name);

  constructor(private orchestrationService: OrchestrationService) {}

  /**
   * Process bills daily at 6 AM ET
   */
  @Cron('0 6 * * *', { timeZone: 'America/New_York' })
  async processUpcomingBills() {
    this.logger.log('Running scheduled payment processing...');

    try {
      const result = await this.orchestrationService.processUpcomingBills();
      this.logger.log(`Scheduled run complete: ${JSON.stringify(result)}`);
    } catch (error) {
      this.logger.error(`Scheduled payment processing failed: ${error.message}`);
    }
  }

  /**
   * Send payment reminders at 9 AM ET
   */
  @Cron('0 9 * * *', { timeZone: 'America/New_York' })
  async sendPaymentReminders() {
    this.logger.log('Sending payment reminders...');
    // TODO: Implement reminder notifications for upcoming bills
  }

  /**
   * Expire old approvals at midnight
   */
  @Cron(CronExpression.EVERY_DAY_AT_MIDNIGHT)
  async expireApprovals() {
    this.logger.log('Expiring old approval requests...');

    try {
      const count = await this.orchestrationService.expireOldApprovals();
      this.logger.log(`Expired ${count} approval requests`);
    } catch (error) {
      this.logger.error(`Failed to expire approvals: ${error.message}`);
    }
  }

  /**
   * Reconcile payments at noon
   * Check that completed payments actually went through
   */
  @Cron('0 12 * * *', { timeZone: 'America/New_York' })
  async reconcilePayments() {
    this.logger.log('Reconciling payments...');
    // TODO: Check Checkbook.io status for pending checks
    // TODO: Verify Stripe payments cleared
  }
}
