import {
  Controller,
  Post,
  Get,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { AlfredService } from './alfred.service';
import { AlfredQuestionsService } from './alfred-questions.service';
import { FirebaseAuthGuard, AuthPayload } from '../firebase/firebase-auth.guard';
import { CurrentUser } from '../firebase/current-user.decorator';

interface ChatRequest {
  message: string;
  conversationHistory?: { role: 'user' | 'assistant'; content: string }[];
}

@Controller('alfred')
@UseGuards(FirebaseAuthGuard)
export class AlfredController {
  constructor(
    private alfredService: AlfredService,
    private questionsService: AlfredQuestionsService,
  ) {}

  @Post('chat')
  async chat(@CurrentUser() user: AuthPayload, @Body() body: ChatRequest) {
    const userId = user.userId;
    const householdId = user.householdId;

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
  async getSuggestions(@CurrentUser() user: AuthPayload) {
    const householdId = user.householdId;

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

  @Get('next-question/:householdId')
  async getNextQuestion(
    @Param('householdId') householdId: string,
    @Query('context') context?: string,
  ) {
    const question = await this.questionsService.getNextQuestion(
      householdId,
      context,
    );
    return { question };
  }

  @Post('answer-question')
  async answerQuestion(
    @Body()
    body: { householdId: string; questionId: string; answer: string },
  ) {
    return this.questionsService.processAnswer(
      body.householdId,
      body.questionId,
      body.answer,
    );
  }

  @Get('data-gaps/:householdId')
  async getDataGaps(@Param('householdId') householdId: string) {
    return this.questionsService.getDataGapsSummary(householdId);
  }
}
