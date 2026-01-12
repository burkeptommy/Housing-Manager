import { Controller, Post, Get, Param, UseGuards, Req } from '@nestjs/common';
import { CardService } from './card.service';
import { FirebaseAuthGuard } from '../firebase';

@Controller('payments/card')
@UseGuards(FirebaseAuthGuard)
export class CardController {
  constructor(private cardService: CardService) {}

  @Post('create')
  async createCard(@Req() req: any) {
    const { householdId, userId } = req.user;
    return this.cardService.createHouseholdCard(householdId, userId);
  }

  @Get()
  async getCard(@Req() req: any) {
    const { householdId } = req.user;
    return this.cardService.getHouseholdCard(householdId);
  }

  @Post('freeze')
  async freezeCard(@Req() req: any) {
    const { householdId } = req.user;
    return this.cardService.freezeCard(householdId);
  }

  @Post('unfreeze')
  async unfreezeCard(@Req() req: any) {
    const { householdId } = req.user;
    return this.cardService.unfreezeCard(householdId);
  }

  @Post('link-funding/:plaidAccountId')
  async linkFunding(@Req() req: any, @Param('plaidAccountId') plaidAccountId: string) {
    const { householdId } = req.user;
    return this.cardService.linkFundingSource(householdId, plaidAccountId);
  }
}
