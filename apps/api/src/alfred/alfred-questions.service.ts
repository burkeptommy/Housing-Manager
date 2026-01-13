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
    {
      id: 'heating_fuel',
      dataGap: 'heating_fuel',
      question:
        'What type of heating does your home have? This helps me plan maintenance and track your energy costs.',
      responseType: 'choice',
      choices: [
        { label: 'Natural Gas', value: 'natural-gas' },
        { label: 'Oil', value: 'oil' },
        { label: 'Propane', value: 'propane' },
        { label: 'Electric', value: 'electric' },
        { label: 'Heat Pump', value: 'heat-pump' },
        { label: 'Other', value: 'other' },
      ],
      priority: 1,
    },
    {
      id: 'cooling_type',
      dataGap: 'cooling_type',
      question:
        'How do you cool your home during summer?',
      responseType: 'choice',
      choices: [
        { label: 'Central Air Conditioning', value: 'central-ac' },
        { label: 'Window Units', value: 'window-units' },
        { label: 'Mini-Split / Ductless', value: 'mini-split' },
        { label: 'Heat Pump', value: 'heat-pump' },
        { label: 'No Air Conditioning', value: 'none' },
      ],
      priority: 2,
    },
    {
      id: 'bedrooms',
      dataGap: 'bedrooms',
      question:
        'How many bedrooms does your home have?',
      responseType: 'text',
      followUp: 'Just the number is fine.',
      priority: 3,
    },
    {
      id: 'bathrooms',
      dataGap: 'bathrooms',
      question:
        'How many bathrooms? Half baths count as 0.5.',
      responseType: 'text',
      followUp: 'For example: 2.5 or 3',
      priority: 3,
    },
    {
      id: 'square_feet',
      dataGap: 'square_feet',
      question:
        'Approximately how many square feet is your home? This helps me estimate maintenance costs.',
      responseType: 'text',
      followUp: "A rough estimate is fine, like '2000' or 'about 1500'.",
      priority: 4,
    },
    {
      id: 'garage',
      dataGap: 'garage',
      question:
        'Does your home have a garage? If so, how many cars does it fit?',
      responseType: 'choice',
      choices: [
        { label: 'No Garage', value: '0' },
        { label: '1-Car Garage', value: '1' },
        { label: '2-Car Garage', value: '2' },
        { label: '3+ Car Garage', value: '3' },
      ],
      priority: 4,
    },
    {
      id: 'pool',
      dataGap: 'pool',
      question:
        'Does your home have a pool?',
      responseType: 'choice',
      choices: [
        { label: 'Yes, in-ground pool', value: 'inground' },
        { label: 'Yes, above-ground pool', value: 'aboveground' },
        { label: 'No pool', value: 'none' },
      ],
      priority: 4,
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
          // Update the homeProfile for year_built
          await this.updateHomeProfile(householdId, { yearBuilt: year });
          const age = new Date().getFullYear() - year;
          message = `Got it! Your home was built around ${year}, making it about ${age} years old. This helps me estimate when major systems might need attention.`;
        } else {
          message =
            "I'll note that for now. If you find out later, just let me know!";
        }
        removeGap = 'year_built';
        break;

      case 'heating_fuel':
        updates.heatingFuel = answer;
        if (answer === 'oil') {
          // Add follow-up question for oil provider
          await this.addDataGap(householdId, 'oil_provider');
          message = "Got it, oil heat! I'll ask about your oil provider next so I can help track deliveries.";
        } else if (answer === 'propane') {
          await this.addDataGap(householdId, 'propane_provider');
          message = "Propane heat noted! I'll help you track refills and find competitive pricing.";
        } else if (answer === 'natural-gas') {
          message = "Natural gas heat - great for efficiency! I'll monitor your gas usage.";
        } else {
          message = `${answer.charAt(0).toUpperCase() + answer.slice(1).replace('-', ' ')} heating noted!`;
        }
        removeGap = 'heating_fuel';
        break;

      case 'cooling_type':
        // Store in household or homeProfile as appropriate
        message = answer === 'none'
          ? "No AC - got it! I'll remind you about window unit maintenance if you add them."
          : `${answer.replace('-', ' ')} cooling system noted. I'll add filter reminders to your maintenance schedule.`;
        if (answer !== 'none') {
          // Could create HVAC maintenance tasks here
        }
        removeGap = 'cooling_type';
        break;

      case 'bedrooms':
        const bedroomsNum = parseInt(answer);
        if (bedroomsNum > 0) {
          await this.updateHomeProfile(householdId, { bedrooms: bedroomsNum });
          message = `${bedroomsNum} bedrooms noted!`;
        } else {
          message = "I'll make a note of that.";
        }
        removeGap = 'bedrooms';
        break;

      case 'bathrooms':
        const bathroomsNum = parseFloat(answer);
        if (bathroomsNum > 0) {
          await this.updateHomeProfile(householdId, { bathrooms: bathroomsNum });
          message = `${bathroomsNum} bathrooms noted!`;
        } else {
          message = "I'll make a note of that.";
        }
        removeGap = 'bathrooms';
        break;

      case 'square_feet':
        const sqft = this.parseNumber(answer);
        if (sqft) {
          await this.updateHomeProfile(householdId, { squareFeet: sqft });
          message = `About ${sqft.toLocaleString()} square feet - this helps me estimate costs for things like HVAC and painting.`;
        } else {
          message = "No problem! We can estimate this later.";
        }
        removeGap = 'square_feet';
        break;

      case 'garage':
        const garageSpaces = parseInt(answer);
        await this.updateHomeProfile(householdId, { garageSpaces });
        if (garageSpaces === 0) {
          message = "No garage - got it!";
        } else {
          message = `${garageSpaces}-car garage noted. I'll add garage door maintenance to your schedule.`;
        }
        removeGap = 'garage';
        break;

      case 'pool':
        if (answer !== 'none') {
          await this.createPoolMaintenanceTask(householdId, answer === 'inground');
          message = answer === 'inground'
            ? "In-ground pool! I've added pool opening, closing, and maintenance reminders to your schedule."
            : "Above-ground pool noted! I'll remind you about seasonal setup and winterization.";
        } else {
          message = "No pool - got it!";
        }
        removeGap = 'pool';
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

  private parseNumber(answer: string): number | null {
    // Remove commas and extract numbers
    const cleaned = answer.replace(/,/g, '').replace(/[^\d.]/g, ' ').trim();
    const match = cleaned.match(/\d+/);
    if (match) {
      const num = parseInt(match[0]);
      return num > 0 ? num : null;
    }
    return null;
  }

  private async addDataGap(householdId: string, gap: string) {
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      select: { alfredDataGaps: true },
    });

    const dataGaps = (household?.alfredDataGaps as string[]) || [];
    if (!dataGaps.includes(gap)) {
      dataGaps.push(gap);
      await this.prisma.household.update({
        where: { id: householdId },
        data: { alfredDataGaps: dataGaps },
      });
    }
  }

  private async updateHomeProfile(householdId: string, data: Record<string, any>) {
    await this.prisma.homeProfile.updateMany({
      where: { householdId },
      data,
    });
  }

  private async createPoolMaintenanceTask(householdId: string, isInground: boolean) {
    // Check if pool task already exists
    const existingTask = await this.prisma.maintenanceTask.findFirst({
      where: { householdId, title: { contains: 'Pool' } },
    });

    if (!existingTask) {
      // Create pool opening task (spring)
      await this.prisma.maintenanceTask.create({
        data: {
          householdId,
          title: isInground ? 'Pool Opening (In-Ground)' : 'Pool Setup (Above-Ground)',
          description: isInground
            ? 'Annual pool opening: remove cover, add chemicals, start filter'
            : 'Set up above-ground pool for the season',
          frequency: 'ANNUAL',
          dueDate: this.getNextSpringDate(),
          status: 'UPCOMING',
          estimatedCost: isInground ? 300 : 50,
        },
      });

      // Create pool closing task (fall)
      await this.prisma.maintenanceTask.create({
        data: {
          householdId,
          title: isInground ? 'Pool Closing (In-Ground)' : 'Pool Winterization (Above-Ground)',
          description: isInground
            ? 'Annual pool closing: winterize plumbing, cover pool'
            : 'Drain and store above-ground pool for winter',
          frequency: 'ANNUAL',
          dueDate: this.getNextFallDate(),
          status: 'UPCOMING',
          estimatedCost: isInground ? 350 : 25,
        },
      });

      this.logger.log(`Created pool maintenance tasks for household ${householdId}`);
    }
  }

  private getNextSpringDate(): Date {
    const now = new Date();
    const year = now.getMonth() < 4 ? now.getFullYear() : now.getFullYear() + 1;
    return new Date(year, 4, 1); // May 1st
  }

  private getNextFallDate(): Date {
    const now = new Date();
    const year = now.getMonth() < 9 ? now.getFullYear() : now.getFullYear() + 1;
    return new Date(year, 9, 1); // October 1st
  }

  /**
   * Initialize data gaps for a new household based on what ATTOM didn't provide
   * Called after registration to determine what questions Alfred should ask
   */
  async initializeDataGaps(householdId: string): Promise<string[]> {
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      include: {
        homeProfile: true,
      },
    });

    if (!household) return [];

    const dataGaps: string[] = [];

    // Check what data is missing from household
    if (!household.waterSource && !household.waterSourceConfirmed) {
      dataGaps.push('water_source');
    }
    if (!household.sewerType && !household.sewerTypeConfirmed) {
      dataGaps.push('sewer_type');
    }
    if (!household.heatingFuel) {
      dataGaps.push('heating_fuel');
    }

    // Check homeProfile for missing property details
    const homeProfile = household.homeProfile;
    if (homeProfile) {
      if (!homeProfile.yearBuilt) {
        dataGaps.push('year_built');
      }
      if (!homeProfile.bedrooms) {
        dataGaps.push('bedrooms');
      }
      if (!homeProfile.bathrooms) {
        dataGaps.push('bathrooms');
      }
      if (!homeProfile.squareFeet) {
        dataGaps.push('square_feet');
      }
      if (homeProfile.garageSpaces === null || homeProfile.garageSpaces === undefined) {
        dataGaps.push('garage');
      }
    }

    // Save the data gaps to the household
    if (dataGaps.length > 0) {
      await this.prisma.household.update({
        where: { id: householdId },
        data: { alfredDataGaps: dataGaps },
      });
      this.logger.log(`Initialized ${dataGaps.length} data gaps for household ${householdId}: ${dataGaps.join(', ')}`);
    }

    return dataGaps;
  }
}
