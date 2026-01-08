import {
  Controller,
  Post,
  Get,
  Body,
  UseGuards,
  Request,
} from '@nestjs/common';
import { AlfredService } from './alfred.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('alfred')
@UseGuards(JwtAuthGuard)
export class AlfredController {
  constructor(private alfredService: AlfredService) {}

  @Post('chat')
  async chat(
    @Request() req,
    @Body() body: { message: string; conversationHistory?: any[] },
  ) {
    const userId = req.user.sub || req.user.userId || req.user.id;
    const householdId = req.user.householdId || 'default';

    return this.alfredService.chat(
      userId,
      householdId,
      body.message,
      body.conversationHistory || [],
    );
  }

  @Get('suggestions')
  async getSuggestions(@Request() req) {
    return {
      suggestions: [
        'Schedule my annual HVAC service',
        'What maintenance is due this month?',
        'Book a handyman to change filters',
        'Find a plumber for a leaky faucet',
      ],
    };
  }
}
