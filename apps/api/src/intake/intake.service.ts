import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { IntakeGeneratorService } from './intake-generator.service';
import { PropertyService } from '../property/property.service';
import { IntakeStatus, Prisma } from '@prisma/client';

export interface CreateIntakeDto {
  householdId: string;
  managerId?: string;
  scheduledAt?: Date;
}

export interface UpdateIntakeDto {
  status?: IntakeStatus;
  sectionsCompleted?: Record<string, boolean>;
  callNotes?: string;
  managerNotes?: string;
  nextSteps?: string;
  followUpDate?: Date;
}

export interface IntakeAnswerDto {
  sectionId: string;
  itemId: string;
  value: string | number | boolean;
}

@Injectable()
export class IntakeService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly intakeGenerator: IntakeGeneratorService,
    private readonly propertyService: PropertyService,
  ) {}

  /**
   * Get or create an intake for a household
   */
  async getOrCreateIntake(householdId: string, managerId?: string) {
    // Check if intake already exists
    let intake = await this.prisma.householdIntake.findUnique({
      where: { householdId },
      include: {
        household: {
          include: {
            homeProfile: true,
          },
        },
        manager: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            email: true,
          },
        },
      },
    });

    if (!intake) {
      // Create new intake
      intake = await this.prisma.householdIntake.create({
        data: {
          householdId,
          managerId,
          status: 'PENDING',
          progress: 0,
        },
        include: {
          household: {
            include: {
              homeProfile: true,
            },
          },
          manager: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
              email: true,
            },
          },
        },
      });
    }

    return intake;
  }

  /**
   * Get intake with generated sections
   */
  async getIntakeWithSections(householdId: string) {
    const intake = await this.getOrCreateIntake(householdId);

    // Get property enrichment data if available
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      select: {
        enrichmentData: true,
        homeProfile: {
          select: {
            state: true,
          },
        },
      },
    });

    const propertyData = household?.enrichmentData as any || null;
    const state = household?.homeProfile?.state;

    // Generate intake sections
    const sections = this.intakeGenerator.generateIntakeSections(propertyData, state);

    return {
      intake,
      sections,
      summary: this.intakeGenerator.getIntakeSummary(propertyData, state),
    };
  }

  /**
   * Update intake status and progress
   */
  async updateIntake(householdId: string, data: UpdateIntakeDto) {
    const intake = await this.prisma.householdIntake.findUnique({
      where: { householdId },
    });

    if (!intake) {
      throw new NotFoundException('Intake not found');
    }

    const updateData: Prisma.HouseholdIntakeUpdateInput = {};

    if (data.status !== undefined) {
      updateData.status = data.status;

      // Set timestamps based on status
      if (data.status === 'IN_PROGRESS' && !intake.startedAt) {
        updateData.startedAt = new Date();
      } else if (data.status === 'COMPLETED') {
        updateData.completedAt = new Date();
      }
    }

    if (data.sectionsCompleted !== undefined) {
      updateData.sectionsCompleted = data.sectionsCompleted;

      // Calculate progress
      const totalSections = 12; // We have 12 sections
      const completedCount = Object.values(data.sectionsCompleted).filter(Boolean).length;
      updateData.progress = Math.round((completedCount / totalSections) * 100);
    }

    if (data.callNotes !== undefined) updateData.callNotes = data.callNotes;
    if (data.managerNotes !== undefined) updateData.managerNotes = data.managerNotes;
    if (data.nextSteps !== undefined) updateData.nextSteps = data.nextSteps;
    if (data.followUpDate !== undefined) updateData.followUpDate = data.followUpDate;

    return this.prisma.householdIntake.update({
      where: { householdId },
      data: updateData,
      include: {
        manager: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
          },
        },
      },
    });
  }

  /**
   * Start an intake call
   */
  async startIntake(householdId: string, managerId: string) {
    return this.updateIntake(householdId, {
      status: 'IN_PROGRESS',
    });
  }

  /**
   * Complete an intake call
   */
  async completeIntake(householdId: string, answers: Record<string, any>) {
    // Calculate monthly funding from answers
    const funding = this.intakeGenerator.calculateMonthlyFunding(answers);

    return this.prisma.householdIntake.update({
      where: { householdId },
      data: {
        status: 'COMPLETED',
        completedAt: new Date(),
        progress: 100,
        calculatedMonthlyFunding: funding.total,
        fundingBreakdown: funding.breakdown,
      },
    });
  }

  /**
   * Save an answer and create related records (appliances, family members, etc.)
   */
  async saveAnswer(householdId: string, answer: IntakeAnswerDto) {
    // For now, just store in the household's intake JSON
    // In a full implementation, this would create proper records
    // (Appliance, FamilyMember, BillAccount, Vendor, etc.)

    // Get current intake
    const intake = await this.prisma.householdIntake.findUnique({
      where: { householdId },
    });

    if (!intake) {
      throw new NotFoundException('Intake not found');
    }

    // Store answer in notes or a separate JSON field
    // This is a simplified implementation
    const existingNotes = intake.callNotes || '';
    const newNote = `[${answer.sectionId}/${answer.itemId}]: ${answer.value}`;

    await this.prisma.householdIntake.update({
      where: { householdId },
      data: {
        callNotes: existingNotes ? `${existingNotes}\n${newNote}` : newNote,
      },
    });

    return { success: true };
  }

  /**
   * Create a family member from intake
   */
  async createFamilyMember(
    householdId: string,
    data: {
      firstName: string;
      lastName?: string;
      type: 'ADULT' | 'CHILD' | 'STAFF';
      relationship?: string;
      birthdate?: Date;
      school?: string;
      schoolGrade?: string;
    },
  ) {
    return this.prisma.familyMember.create({
      data: {
        householdId,
        firstName: data.firstName,
        lastName: data.lastName,
        type: data.type,
        relationship: data.relationship,
        birthdate: data.birthdate,
        school: data.school,
        schoolGrade: data.schoolGrade,
      },
    });
  }

  /**
   * Create a family activity from intake
   */
  async createFamilyActivity(
    householdId: string,
    data: {
      familyMemberId?: string;
      name: string;
      category: string;
      schedule?: string;
      organizationName?: string;
      costAmount?: number;
      costFrequency?: string;
    },
  ) {
    return this.prisma.familyActivity.create({
      data: {
        householdId,
        familyMemberId: data.familyMemberId,
        name: data.name,
        category: data.category,
        schedule: data.schedule,
        organizationName: data.organizationName,
        costAmount: data.costAmount,
        costFrequency: data.costFrequency as any,
      },
    });
  }

  /**
   * Get all pending intakes for a manager
   */
  async getManagerIntakes(managerId: string) {
    return this.prisma.householdIntake.findMany({
      where: {
        managerId,
        status: {
          in: ['PENDING', 'SCHEDULED', 'IN_PROGRESS', 'PAUSED'],
        },
      },
      include: {
        household: {
          include: {
            homeProfile: true,
            owner: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
                email: true,
                phone: true,
              },
            },
          },
        },
      },
      orderBy: [
        { status: 'asc' },
        { scheduledAt: 'asc' },
        { createdAt: 'asc' },
      ],
    });
  }

  /**
   * Get all households needing intake
   */
  async getHouseholdsNeedingIntake() {
    // Find households without intakes or with incomplete intakes
    const households = await this.prisma.household.findMany({
      where: {
        OR: [
          { householdIntake: null },
          {
            householdIntake: {
              status: {
                notIn: ['COMPLETED', 'ARCHIVED'],
              },
            },
          },
        ],
      },
      include: {
        homeProfile: true,
        owner: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            email: true,
            phone: true,
          },
        },
        householdIntake: true,
      },
      orderBy: {
        createdAt: 'asc',
      },
    });

    return households;
  }

  /**
   * Schedule an intake call
   */
  async scheduleIntake(householdId: string, scheduledAt: Date, managerId: string) {
    const intake = await this.getOrCreateIntake(householdId, managerId);

    return this.prisma.householdIntake.update({
      where: { id: intake.id },
      data: {
        status: 'SCHEDULED',
        scheduledAt,
        managerId,
      },
    });
  }
}
