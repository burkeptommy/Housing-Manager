import { Controller, Get, Post, Param, Body, UseGuards, Req } from '@nestjs/common';
import { OrchestrationService } from './orchestration.service';
import { FirebaseAuthGuard } from '../firebase';

@Controller('payments/approvals')
@UseGuards(FirebaseAuthGuard)
export class ApprovalController {
  constructor(private orchestrationService: OrchestrationService) {}

  @Get()
  async getPendingApprovals(@Req() req: any) {
    const { householdId } = req.user;
    return this.orchestrationService.getPendingApprovals(householdId);
  }

  @Post(':id/approve')
  async approvePayment(
    @Req() req: any,
    @Param('id') id: string,
    @Body('note') note?: string,
  ) {
    const { userId } = req.user;
    return this.orchestrationService.processApproval(id, true, userId, note);
  }

  @Post(':id/deny')
  async denyPayment(
    @Req() req: any,
    @Param('id') id: string,
    @Body('note') note?: string,
  ) {
    const { userId } = req.user;
    return this.orchestrationService.processApproval(id, false, userId, note);
  }
}
