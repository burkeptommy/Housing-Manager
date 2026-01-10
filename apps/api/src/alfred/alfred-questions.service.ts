import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

interface AlfredQuestion {
  id: string;
  dataGap: string;
  question: string;
  followUp?: string;
  responseType: 'choice' | 'text' | 'confirm';
  choices?: { label: string; value: string }[];
  priority: number;
  contextTrigger?: string;
}

@Injectable()
export class AlfredQuestionsService {
  private readonly logger = new Logger(AlfredQuestionsService.name);

  constructor(private prisma: PrismaService) {}

  private questions: AlfredQuestion[] = [
    {
      id: 'water_source',
      dataGap: 'water_source',
      question:
        'Quick question about your home - do you have town water or a private well?',
      responseType: 'choice',
      choices: [
        { label: 'Town/Municipal Water', value: 'municipal' },
        { label: 'Private Well', value: 'well' },
      ],
      priority: 1,
    },
    {
      id: 'water_source_no_bill',
      dataGap: 'water_source_no_bill',
      question:
        "I noticed you don't have a water bill in your bank transactions. Do you have a private well?",
      responseType: 'choice',
      choices: [
        { label: 'Yes, we have a well', value: 'well' },
        { label: 'No, we have town water', value: 'municipal' },
      ],
      priority: 1,
    },
    {
      id: 'sewer_type',
      dataGap: 'sewer_type',
      question: 'Is your home on town sewer or do you have a septic system?',
      responseType: 'choice',
      choices: [
        { label: 'Town Sewer', value: 'municipal' },
        { label: 'Septic System', value: 'septic' },
      ],
      priority: 1,
    },
    {
      id: 'sewer_type_no_bill',
      dataGap: 'sewer_type_no_bill',
      question:
        "I don't see a sewer bill in your transactions. Does your home have a septic system?",
      responseType: 'choice',
      choices: [
        { label: 'Yes, we have septic', value: 'septic' },
        { label: 'No, we have town sewer', value: 'municipal' },
      ],
      priority: 1,
    },
    {
      id: 'oil_provider',
      dataGap: 'oil_provider',
      question:
        'I see you have oil heat. Who delivers your heating oil? I can help track prices and schedule deliveries.',
      responseType: 'text',
      followUp:
        "Just type the company name, or say 'not sure' and I can help you find one.",
      priority: 2,
    },
    {
      id: 'propane_provider',
      dataGap: 'propane_provider',
      question:
        "Who's your propane supplier? I can monitor your usage and help schedule refills.",
      responseType: 'text',
      priority: 2,
    },
    {
      id: 'year_built',
      dataGap: 'year_built',
      question:
        'Do you know approximately when your home was built? This helps me estimate when systems might need attention.',
      responseType: 'text',
      followUp: "Just a rough year is fine, like '1985' or 'early 2000s'.",
      priority: 3,
    },
  ];

  async getNextQuestion(
    householdId: string,
    conversationContext?: string,
  ): Promise<AlfredQuestion | null> {
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      select: {
        alfredDataGaps: true,
        alfredQuestionsAsked: true,
      },
    });

    if (!household) return null;

    const dataGaps = (household.alfredDataGaps as string[]) || [];
    const questionsAsked = (household.alfredQuestionsAsked as string[]) || [];

    let candidates = this.questions.filter(
      (q) => dataGaps.includes(q.dataGap) && !questionsAsked.includes(q.id),
    );

    if (conversationContext) {
      const contextMatches = candidates.filter((q) => {
        if (!q.contextTrigger) return false;
        const regex = new RegExp(q.contextTrigger, 'i');
        return regex.test(conversationContext);
      });

      if (contextMatches.length > 0) {
        contextMatches.sort((a, b) => a.priority - b.priority);
        return contextMatches[0];
      }
    }

    candidates.sort((a, b) => a.priority - b.priority);
    return candidates[0] || null;
  }

  async markQuestionAsked(householdId: string, questionId: string) {
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      select: { alfredQuestionsAsked: true },
    });

    const questionsAsked =
      (household?.alfredQuestionsAsked as string[]) || [];
    if (!questionsAsked.includes(questionId)) {
      questionsAsked.push(questionId);
      await this.prisma.household.update({
        where: { id: householdId },
        data: { alfredQuestionsAsked: questionsAsked },
      });
    }
  }

  async processAnswer(
    householdId: string,
    questionId: string,
    answer: string,
  ): Promise<{ success: boolean; error?: string; message?: string }> {
    const question = this.questions.find((q) => q.id === questionId);
    if (!question)
      return { success: false, error: 'Question not found' };

    const updates: Record<string, any> = {};
    let removeGap: string | null = null;
    let message: string | undefined;

    switch (questionId) {
      case 'water_source':
      case 'water_source_no_bill':
        updates.waterSource = answer;
        updates.waterSourceConfirmed = true;
        removeGap = question.dataGap;
        message =
          answer === 'well'
            ? "Got it! I'll keep track of your well system and remind you about water testing."
            : "Great, I've noted your municipal water connection.";
        break;

      case 'sewer_type':
      case 'sewer_type_no_bill':
        updates.sewerType = answer;
        updates.sewerTypeConfirmed = true;
        removeGap = question.dataGap;

        if (answer === 'septic') {
          await this.createSepticTask(householdId);
          message =
            "Thanks! I've added septic tank maintenance to your schedule. I'll remind you when it's time for pumping.";
        } else {
          message = "Perfect, I've noted your municipal sewer connection.";
        }
        break;

      case 'oil_provider':
        if (answer.toLowerCase() !== 'not sure') {
          updates.heatingFuelProvider = answer;
          message = `Great, I've saved ${answer} as your oil provider. I can help monitor prices and schedule deliveries.`;
        } else {
          message =
            "No problem! When you're ready, I can help you find competitive oil delivery options in your area.";
        }
        removeGap = 'oil_provider';
        break;

      case 'propane_provider':
        if (answer.toLowerCase() !== 'not sure') {
          updates.heatingFuelProvider = answer;
          message = `Perfect, I've saved ${answer} as your propane supplier.`;
        } else {
          message =
            'No worries! Let me know when you want to explore propane delivery options.';
        }
        removeGap = 'propane_provider';
        break;

      case 'year_built':
        const year = this.parseYear(answer);
        if (year) {
          updates.yearBuilt = year;
          const age = new Date().getFullYear() - year;
          message = `Got it! Your home was built around ${year}, making it about ${age} years old. This helps me estimate when major systems might need attention.`;
        } else {
          message =
            "I'll note that for now. If you find out later, just let me know!";
        }
        removeGap = 'year_built';
        break;

      default:
        return { success: false, error: 'Unknown question type' };
    }

    if (Object.keys(updates).length > 0) {
      await this.prisma.household.update({
        where: { id: householdId },
        data: updates,
      });
    }

    if (removeGap) {
      await this.removeDataGap(householdId, removeGap);
    }

    await this.markQuestionAsked(householdId, questionId);

    this.logger.log(
      `Processed answer for question ${questionId} in household ${householdId}`,
    );

    return { success: true, message };
  }

  private parseYear(answer: string): number | null {
    // Try direct parse
    const directMatch = answer.match(/\d{4}/);
    if (directMatch) {
      const year = parseInt(directMatch[0]);
      if (year > 1800 && year <= new Date().getFullYear()) {
        return year;
      }
    }

    // Handle decade references
    const decadePatterns: Record<string, number> = {
      'early 90s': 1992,
      'mid 90s': 1995,
      'late 90s': 1998,
      'early 2000s': 2002,
      'mid 2000s': 2005,
      'late 2000s': 2008,
      'early 80s': 1982,
      'mid 80s': 1985,
      'late 80s': 1988,
    };

    const lowerAnswer = answer.toLowerCase();
    for (const [pattern, year] of Object.entries(decadePatterns)) {
      if (lowerAnswer.includes(pattern)) {
        return year;
      }
    }

    return null;
  }

  private async removeDataGap(householdId: string, gap: string) {
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      select: { alfredDataGaps: true },
    });

    let dataGaps = (household?.alfredDataGaps as string[]) || [];
    dataGaps = dataGaps.filter((g) => g !== gap);

    await this.prisma.household.update({
      where: { id: householdId },
      data: { alfredDataGaps: dataGaps },
    });
  }

  private async createSepticTask(householdId: string) {
    // Check if septic task already exists
    const existingTask = await this.prisma.maintenanceTask.findFirst({
      where: { householdId, title: { contains: 'Septic' } },
    });

    if (!existingTask) {
      await this.prisma.maintenanceTask.create({
        data: {
          householdId,
          title: 'Septic Tank Pumping',
          description:
            'Regular septic pumping prevents backups and system failure',
          frequency: 'TRIENNIAL',
          dueDate: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000), // 1 year from now
          status: 'UPCOMING',
          estimatedCost: 350,
        },
      });

      this.logger.log(`Created septic maintenance task for household ${householdId}`);
    }
  }

  async getDataGapsSummary(householdId: string): Promise<{
    totalGaps: number;
    questionsRemaining: number;
    completionPercentage: number;
  }> {
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      select: {
        alfredDataGaps: true,
        alfredQuestionsAsked: true,
      },
    });

    const dataGaps = (household?.alfredDataGaps as string[]) || [];
    const questionsAsked = (household?.alfredQuestionsAsked as string[]) || [];

    const pendingQuestions = this.questions.filter(
      (q) => dataGaps.includes(q.dataGap) && !questionsAsked.includes(q.id),
    );

    const totalQuestions = this.questions.length;
    const answered = questionsAsked.length;
    const completionPercentage =
      totalQuestions > 0 ? Math.round((answered / totalQuestions) * 100) : 100;

    return {
      totalGaps: dataGaps.length,
      questionsRemaining: pendingQuestions.length,
      completionPercentage,
    };
  }
}
