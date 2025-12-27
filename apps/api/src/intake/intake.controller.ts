import {
  Controller,
  Get,
  Post,
  Put,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { IntakeService, UpdateIntakeDto, IntakeAnswerDto } from './intake.service';
import { IntakeGeneratorService, BillCategoryType } from './intake-generator.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('intake')
@UseGuards(JwtAuthGuard)
export class IntakeController {
  constructor(
    private readonly intakeService: IntakeService,
    private readonly intakeGenerator: IntakeGeneratorService,
  ) {}

  /**
   * Get all households needing intake (for manager dashboard)
   */
  @Get('pending')
  async getPendingIntakes(@Request() req: any) {
    return this.intakeService.getHouseholdsNeedingIntake();
  }

  /**
   * Get manager's assigned intakes
   */
  @Get('my-intakes')
  async getMyIntakes(@Request() req: any) {
    return this.intakeService.getManagerIntakes(req.user.userId);
  }

  /**
   * Get intake for a specific household with generated sections
   */
  @Get('household/:householdId')
  async getHouseholdIntake(@Param('householdId') householdId: string) {
    return this.intakeService.getIntakeWithSections(householdId);
  }

  /**
   * Preview intake sections without creating a record
   * Useful for seeing what questions will be asked based on property data
   */
  @Post('preview')
  async previewIntakeSections(
    @Body() data: {
      street?: string;
      city?: string;
      state?: string;
      zip?: string;
      propertyData?: any;
    },
  ) {
    const propertyData = data.propertyData || null;
    const state = data.state;

    const sections = this.intakeGenerator.generateIntakeSections(propertyData, state);
    const summary = this.intakeGenerator.getIntakeSummary(propertyData, state);

    return {
      success: true,
      sections,
      summary,
    };
  }

  /**
   * Start an intake session
   */
  @Post('household/:householdId/start')
  async startIntake(
    @Param('householdId') householdId: string,
    @Request() req: any,
  ) {
    return this.intakeService.startIntake(householdId, req.user.userId);
  }

  /**
   * Update intake status and notes
   */
  @Patch('household/:householdId')
  async updateIntake(
    @Param('householdId') householdId: string,
    @Body() data: UpdateIntakeDto,
  ) {
    return this.intakeService.updateIntake(householdId, data);
  }

  /**
   * Save an individual answer
   */
  @Post('household/:householdId/answer')
  async saveAnswer(
    @Param('householdId') householdId: string,
    @Body() answer: IntakeAnswerDto,
  ) {
    return this.intakeService.saveAnswer(householdId, answer);
  }

  /**
   * Complete intake and calculate funding
   */
  @Post('household/:householdId/complete')
  async completeIntake(
    @Param('householdId') householdId: string,
    @Body() data: { answers: Record<string, any> },
  ) {
    return this.intakeService.completeIntake(householdId, data.answers);
  }

  /**
   * Schedule an intake call
   */
  @Post('household/:householdId/schedule')
  async scheduleIntake(
    @Param('householdId') householdId: string,
    @Body() data: { scheduledAt: string },
    @Request() req: any,
  ) {
    return this.intakeService.scheduleIntake(
      householdId,
      new Date(data.scheduledAt),
      req.user.userId,
    );
  }

  /**
   * Create a family member
   */
  @Post('household/:householdId/family-member')
  async createFamilyMember(
    @Param('householdId') householdId: string,
    @Body() data: {
      firstName: string;
      lastName?: string;
      type: 'ADULT' | 'CHILD' | 'STAFF';
      relationship?: string;
      birthdate?: string;
      school?: string;
      schoolGrade?: string;
    },
  ) {
    return this.intakeService.createFamilyMember(householdId, {
      ...data,
      birthdate: data.birthdate ? new Date(data.birthdate) : undefined,
    });
  }

  /**
   * Create a family activity
   */
  @Post('household/:householdId/activity')
  async createFamilyActivity(
    @Param('householdId') householdId: string,
    @Body() data: {
      familyMemberId?: string;
      name: string;
      category: string;
      schedule?: string;
      organizationName?: string;
      costAmount?: number;
      costFrequency?: string;
    },
  ) {
    return this.intakeService.createFamilyActivity(householdId, data);
  }

  /**
   * Calculate monthly funding from answers
   */
  @Post('calculate-funding')
  async calculateFunding(@Body() data: { answers: Record<string, any> }) {
    return this.intakeGenerator.calculateMonthlyFunding(data.answers);
  }

  // ===========================================================================
  // COMPREHENSIVE BILL ENDPOINTS
  // ===========================================================================

  /**
   * Get bill intake sections for a household
   */
  @Get('household/:householdId/bill-sections')
  async getBillSections(@Param('householdId') householdId: string) {
    return this.intakeService.getBillIntakeSections(householdId);
  }

  /**
   * Get all bills for a household
   */
  @Get('household/:householdId/bills')
  async getHouseholdBills(@Param('householdId') householdId: string) {
    return this.intakeService.getHouseholdBills(householdId);
  }

  /**
   * Get bill summary with monthly funding calculation
   */
  @Get('household/:householdId/bills/summary')
  async getBillSummary(@Param('householdId') householdId: string) {
    return this.intakeService.getBillSummary(householdId);
  }

  /**
   * Calculate monthly funding for a household
   */
  @Get('household/:householdId/bills/funding')
  async calculateHouseholdFunding(@Param('householdId') householdId: string) {
    return this.intakeService.calculateHouseholdFunding(householdId);
  }

  /**
   * Create a new bill
   */
  @Post('household/:householdId/bills')
  async createBill(
    @Param('householdId') householdId: string,
    @Body() data: {
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
      maturityDate?: string;
      escrowIncluded?: boolean;
      // Insurance fields
      policyNumber?: string;
      coverageAmount?: number;
      deductible?: number;
      renewalDate?: string;
      // Linked entities
      vendorId?: string;
      vehicleId?: string;
      familyMemberId?: string;
      assetId?: string;
    },
  ) {
    return this.intakeService.createBill(householdId, {
      ...data,
      maturityDate: data.maturityDate ? new Date(data.maturityDate) : undefined,
      renewalDate: data.renewalDate ? new Date(data.renewalDate) : undefined,
    });
  }

  /**
   * Update a bill
   */
  @Patch('household/:householdId/bills/:billId')
  async updateBill(
    @Param('householdId') householdId: string,
    @Param('billId') billId: string,
    @Body() data: Partial<{
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
    return this.intakeService.updateBill(householdId, billId, data);
  }

  /**
   * Delete a bill
   */
  @Delete('household/:householdId/bills/:billId')
  @HttpCode(HttpStatus.NO_CONTENT)
  async deleteBill(
    @Param('householdId') householdId: string,
    @Param('billId') billId: string,
  ) {
    return this.intakeService.deleteBill(householdId, billId);
  }

  /**
   * Get all bill types for dropdown
   */
  @Get('bill-types')
  async getBillTypes() {
    return this.intakeGenerator.getAllBillTypes();
  }
}
