import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { IntakeGeneratorService, BillIntakeContext, BillCategoryType } from './intake-generator.service';
import { PropertyService } from '../property/property.service';
import { IntakeStatus, Prisma, BillCategory, PaymentFrequency, BillPaymentMethod, AmountType, BillStatus, PayeeType } from '@prisma/client';

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

  // ===========================================================================
  // COMPREHENSIVE BILL METHODS
  // ===========================================================================

  /**
   * Get bill intake sections with context from household data
   */
  async getBillIntakeSections(householdId: string) {
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      include: {
        homeProfile: true,
        vehicles: { where: { isActive: true } },
        pets: { where: { isActive: true } },
        familyMembers: { where: { isActive: true } },
      },
    });

    if (!household) {
      throw new NotFoundException('Household not found');
    }

    const propertyData = household.enrichmentData as any || null;
    const hasChildren = household.familyMembers.some(m => m.type === 'CHILD');
    const hasStaff = household.familyMembers.some(m => m.type === 'STAFF');
    const heatingFuel = propertyData?.heatingFuel?.toLowerCase() || '';

    const context: BillIntakeContext = {
      hasPool: propertyData?.pool || false,
      hasChildren,
      hasVehicles: household.vehicles.length > 0,
      vehicleCount: household.vehicles.length,
      hasGasService: heatingFuel.includes('gas') || heatingFuel.includes('natural'),
      hasMortgage: true, // Default to true, can be set by intake
      hasPets: household.pets.length > 0,
      hasStaff,
      state: household.homeProfile?.state,
      propertyData,
      previousAnswers: {},
    };

    const sections = this.intakeGenerator.generateBillIntakeSections(context);
    const billTypes = this.intakeGenerator.getAllBillTypes();

    return {
      sections,
      billTypes,
      context,
    };
  }

  /**
   * Create a comprehensive bill from intake
   */
  async createBill(
    householdId: string,
    data: {
      category: BillCategoryType;
      name: string;
      payeeName?: string;
      accountNumber?: string;
      amount: number;
      frequency: string;
      dueDay?: number;
      amountType?: string;
      paymentMethod?: string;
      currentAutopay?: boolean;
      portalUrl?: string;
      portalUsername?: string;
      portalNotes?: string;
      notes?: string;
      // Loan fields
      principalBalance?: number;
      interestRate?: number;
      loanTerm?: string;
      maturityDate?: Date;
      escrowIncluded?: boolean;
      // Insurance fields
      policyNumber?: string;
      coverageAmount?: number;
      deductible?: number;
      renewalDate?: Date;
      // Linked entities
      vendorId?: string;
      vehicleId?: string;
      familyMemberId?: string;
      assetId?: string;
    },
  ) {
    const isLoan = ['MORTGAGE', 'CAR_PAYMENT', 'STUDENT_LOAN', 'PERSONAL_LOAN', 'HELOC', 'CREDIT_CARD'].includes(data.category);
    const isInsurance = ['HOME_INSURANCE', 'AUTO_INSURANCE', 'LIFE_INSURANCE', 'HEALTH_INSURANCE', 'UMBRELLA_INSURANCE', 'PET_INSURANCE', 'DISABILITY_INSURANCE', 'LONG_TERM_CARE'].includes(data.category);

    // Map frequency string to enum
    const frequencyMap: Record<string, PaymentFrequency> = {
      'WEEKLY': 'WEEKLY',
      'BI-WEEKLY': 'BIWEEKLY',
      'BIWEEKLY': 'BIWEEKLY',
      'TWICE_MONTHLY': 'TWICE_MONTHLY',
      'MONTHLY': 'MONTHLY',
      'QUARTERLY': 'QUARTERLY',
      'SEMI-ANNUAL': 'SEMI_ANNUAL',
      'SEMI_ANNUAL': 'SEMI_ANNUAL',
      'ANNUAL': 'ANNUAL',
      'ONE_TIME': 'ONE_TIME',
      'AS NEEDED': 'AS_NEEDED',
      'AS_NEEDED': 'AS_NEEDED',
    };

    // Map payment method string to enum
    const paymentMethodMap: Record<string, BillPaymentMethod> = {
      'HAVEN PAYS': 'HAVEN_PAYS',
      'HAVEN_PAYS': 'HAVEN_PAYS',
      'CURRENT AUTOPAY': 'OWNER_AUTOPAY',
      'OWNER_AUTOPAY': 'OWNER_AUTOPAY',
      'MANUAL PAYMENT': 'OWNER_MANUAL',
      'OWNER PAYS': 'OWNER_MANUAL',
      'OWNER_MANUAL': 'OWNER_MANUAL',
      'PAYROLL DEDUCTION': 'PAYROLL',
      'PAYROLL': 'PAYROLL',
      'ESCROW': 'ESCROW',
    };

    // Map amount type string to enum
    const amountTypeMap: Record<string, AmountType> = {
      'FIXED': 'FIXED',
      'VARIABLE': 'VARIABLE',
      'ESTIMATED': 'ESTIMATED',
    };

    const bill = await this.prisma.comprehensiveBill.create({
      data: {
        householdId,
        category: data.category as BillCategory,
        name: data.name,
        payeeName: data.payeeName,
        accountNumber: data.accountNumber,
        amount: data.amount,
        frequency: frequencyMap[data.frequency.toUpperCase()] || 'MONTHLY',
        dueDay: data.dueDay,
        amountType: data.amountType ? (amountTypeMap[data.amountType.toUpperCase()] || 'FIXED') : 'FIXED',
        paymentMethod: data.paymentMethod ? (paymentMethodMap[data.paymentMethod.toUpperCase()] || 'HAVEN_PAYS') : 'HAVEN_PAYS',
        currentAutopay: data.currentAutopay || false,
        portalUrl: data.portalUrl,
        portalUsername: data.portalUsername,
        portalNotes: data.portalNotes,
        notes: data.notes,
        // Loan fields
        isLoan,
        principalBalance: data.principalBalance,
        interestRate: data.interestRate,
        loanTerm: data.loanTerm,
        maturityDate: data.maturityDate,
        escrowIncluded: data.escrowIncluded,
        // Insurance fields
        isInsurance,
        policyNumber: data.policyNumber,
        coverageAmount: data.coverageAmount,
        deductible: data.deductible,
        renewalDate: data.renewalDate,
        // Linked entities
        vendorId: data.vendorId,
        vehicleId: data.vehicleId,
        familyMemberId: data.familyMemberId,
        assetId: data.assetId,
        // Status
        status: 'ACTIVE',
        havenManaged: data.paymentMethod?.toUpperCase().includes('HAVEN') || false,
      },
    });

    return bill;
  }

  /**
   * Get all bills for a household
   */
  async getHouseholdBills(householdId: string) {
    const bills = await this.prisma.comprehensiveBill.findMany({
      where: {
        householdId,
        status: { not: 'CANCELLED' },
      },
      include: {
        vendor: {
          select: { id: true, displayName: true },
        },
        vehicle: {
          select: { id: true, name: true, make: true, model: true },
        },
        familyMember: {
          select: { id: true, firstName: true, lastName: true },
        },
      },
      orderBy: [
        { category: 'asc' },
        { name: 'asc' },
      ],
    });

    return bills;
  }

  /**
   * Update a bill
   */
  async updateBill(
    householdId: string,
    billId: string,
    data: Partial<{
      name: string;
      payeeName: string;
      accountNumber: string;
      amount: number;
      frequency: string;
      dueDay: number;
      amountType: string;
      paymentMethod: string;
      currentAutopay: boolean;
      portalUrl: string;
      portalUsername: string;
      portalNotes: string;
      notes: string;
      status: string;
      havenManaged: boolean;
      verified: boolean;
    }>,
  ) {
    const updateData: any = { ...data };

    // Map enums if provided
    if (data.frequency) {
      const frequencyMap: Record<string, PaymentFrequency> = {
        'WEEKLY': 'WEEKLY',
        'BI-WEEKLY': 'BIWEEKLY',
        'BIWEEKLY': 'BIWEEKLY',
        'TWICE_MONTHLY': 'TWICE_MONTHLY',
        'MONTHLY': 'MONTHLY',
        'QUARTERLY': 'QUARTERLY',
        'SEMI-ANNUAL': 'SEMI_ANNUAL',
        'SEMI_ANNUAL': 'SEMI_ANNUAL',
        'ANNUAL': 'ANNUAL',
        'ONE_TIME': 'ONE_TIME',
        'AS_NEEDED': 'AS_NEEDED',
      };
      updateData.frequency = frequencyMap[data.frequency.toUpperCase()] || 'MONTHLY';
    }

    if (data.status) {
      updateData.status = data.status as BillStatus;
    }

    return this.prisma.comprehensiveBill.update({
      where: { id: billId, householdId },
      data: updateData,
    });
  }

  /**
   * Delete a bill (soft delete by setting status to CANCELLED)
   */
  async deleteBill(householdId: string, billId: string) {
    return this.prisma.comprehensiveBill.update({
      where: { id: billId, householdId },
      data: { status: 'CANCELLED' },
    });
  }

  /**
   * Calculate monthly funding for a household
   */
  async calculateHouseholdFunding(householdId: string) {
    const bills = await this.prisma.comprehensiveBill.findMany({
      where: {
        householdId,
        status: 'ACTIVE',
        havenManaged: true,
      },
    });

    const billData = bills.map(b => ({
      amount: Number(b.amount),
      frequency: b.frequency,
      status: b.status,
    }));

    return this.intakeGenerator.calculateComprehensiveMonthlyFunding(billData);
  }

  /**
   * Get bill summary by category for a household
   */
  async getBillSummary(householdId: string) {
    const bills = await this.prisma.comprehensiveBill.findMany({
      where: {
        householdId,
        status: 'ACTIVE',
      },
    });

    // Normalize to monthly
    const normalizeToMonthly = (amount: number, frequency: PaymentFrequency): number => {
      switch (frequency) {
        case 'WEEKLY': return amount * 4.33;
        case 'BIWEEKLY': return amount * 2.17;
        case 'TWICE_MONTHLY': return amount * 2;
        case 'MONTHLY': return amount;
        case 'QUARTERLY': return amount / 3;
        case 'SEMI_ANNUAL': return amount / 6;
        case 'ANNUAL': return amount / 12;
        default: return amount;
      }
    };

    // Category groups
    const categoryGroups: Record<string, string[]> = {
      housing: ['MORTGAGE', 'RENT', 'PROPERTY_TAX', 'HOA', 'HOME_INSURANCE'],
      utilities: ['ELECTRIC', 'GAS', 'WATER_SEWER', 'OIL_PROPANE', 'TRASH'],
      telecom: ['INTERNET', 'CABLE_TV', 'CELL_PHONE', 'LANDLINE'],
      vehicles: ['CAR_PAYMENT', 'AUTO_INSURANCE', 'CAR_REGISTRATION', 'PARKING', 'TOLLS'],
      loans: ['STUDENT_LOAN', 'PERSONAL_LOAN', 'HELOC', 'CREDIT_CARD'],
      family: ['SCHOOL_TUITION', 'CHILDCARE', 'NANNY', 'KIDS_ACTIVITY', 'SCHOOL_LUNCH', 'TUTORING'],
      insurance: ['LIFE_INSURANCE', 'HEALTH_INSURANCE', 'UMBRELLA_INSURANCE', 'PET_INSURANCE', 'DISABILITY_INSURANCE', 'LONG_TERM_CARE'],
      homeServices: ['LAWN_LANDSCAPE', 'POOL_SERVICE', 'PEST_CONTROL', 'SECURITY_MONITORING', 'HOUSE_CLEANING', 'SNOW_REMOVAL'],
      memberships: ['GYM_FITNESS', 'CLUB_MEMBERSHIP', 'STREAMING_SERVICE', 'SOFTWARE_SUBSCRIPTION', 'NEWSPAPER_MAGAZINE', 'MEAL_KIT', 'AMAZON_PRIME', 'WAREHOUSE_CLUB'],
      other: ['STORAGE', 'PET_CARE', 'CHARITY_DONATION', 'CHILD_SUPPORT', 'ALIMONY', 'OTHER_BILL'],
    };

    const summary: Record<string, { count: number; monthlyTotal: number; bills: any[] }> = {};
    let totalMonthly = 0;
    let havenManagedTotal = 0;

    for (const [group, categories] of Object.entries(categoryGroups)) {
      const groupBills = bills.filter(b => categories.includes(b.category));
      const monthlyTotal = groupBills.reduce((sum, b) => sum + normalizeToMonthly(Number(b.amount), b.frequency), 0);
      summary[group] = {
        count: groupBills.length,
        monthlyTotal,
        bills: groupBills.map(b => ({
          id: b.id,
          name: b.name,
          category: b.category,
          payeeName: b.payeeName,
          amount: Number(b.amount),
          frequency: b.frequency,
          monthlyAmount: normalizeToMonthly(Number(b.amount), b.frequency),
          havenManaged: b.havenManaged,
        })),
      };
      totalMonthly += monthlyTotal;
      havenManagedTotal += groupBills.filter(b => b.havenManaged).reduce((sum, b) => sum + normalizeToMonthly(Number(b.amount), b.frequency), 0);
    }

    const havenServiceFee = havenManagedTotal * 0.03;
    const recommendedBuffer = havenManagedTotal * 0.10;

    return {
      summary,
      totalBills: bills.length,
      totalMonthly,
      havenManagedTotal,
      havenServiceFee,
      recommendedBuffer,
      recommendedMonthlyFunding: havenManagedTotal + havenServiceFee + recommendedBuffer,
    };
  }
}
