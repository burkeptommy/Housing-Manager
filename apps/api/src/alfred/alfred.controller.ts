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

interface ChatRequest {
  message: string;
  conversationHistory?: { role: 'user' | 'assistant'; content: string }[];
}

@Controller('alfred')
@UseGuards(JwtAuthGuard)
export class AlfredController {
  constructor(private alfredService: AlfredService) {}

  @Post('chat')
  async chat(@Request() req, @Body() body: ChatRequest) {
    const userId = req.user.sub || req.user.userId || req.user.id;
    const householdId = req.user.householdId;

    if (!householdId) {
      return {
        message:
          "I don't see a household associated with your account yet. Please complete the onboarding process first.",
        suggestions: ['Set up your home first'],
      };
    }

    return this.alfredService.chat(
      userId,
      householdId,
      body.message,
      body.conversationHistory || [],
    );
  }

  @Get('suggestions')
  async getSuggestions(@Request() req) {
    const householdId = req.user.householdId;

    if (!householdId) {
      return {
        suggestions: [
          'Set up your home first',
          'Complete onboarding to get started',
        ],
      };
    }

    const suggestions = await this.alfredService.getSuggestions(householdId);
    return { suggestions };
  }
}
