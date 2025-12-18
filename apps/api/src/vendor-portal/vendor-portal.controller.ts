import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { VendorPortalService } from './vendor-portal.service';
import { FirebaseAuthGuard } from '../firebase/firebase-auth.guard';
import { CurrentUser, AuthPayload } from '../firebase/current-user.decorator';
import {
  AcceptJobDto,
  CheckInDto,
  CheckOutDto,
  JobBoardQueryDto,
  VerifyJobDto,
  RequestRevisionDto,
} from './dto';

@Controller('vendor-portal')
@UseGuards(FirebaseAuthGuard)
export class VendorPortalController {
  constructor(private readonly vendorPortalService: VendorPortalService) {}

  // =====================
  // VENDOR ENDPOINTS
  // =====================

  /**
   * Get current vendor's profile
   */
  @Get('profile')
  async getProfile(@CurrentUser() user: AuthPayload) {
    return this.vendorPortalService.getVendorByUserId(user.uid);
  }

  /**
   * Get open jobs for job board
   */
  @Get('jobs')
  async getJobBoard(
    @CurrentUser() user: AuthPayload,
    @Query() query: JobBoardQueryDto,
  ) {
    const vendor = await this.vendorPortalService.getVendorByUserId(user.uid);
    return this.vendorPortalService.getJobBoard(vendor.id, query);
  }

  /**
   * Get vendor's schedule (accepted jobs)
   */
  @Get('schedule')
  async getMySchedule(@CurrentUser() user: AuthPayload) {
    const vendor = await this.vendorPortalService.getVendorByUserId(user.uid);
    return this.vendorPortalService.getMySchedule(vendor.id);
  }

  /**
   * Get a single job detail
   */
  @Get('jobs/:id')
  async getJobDetail(
    @CurrentUser() user: AuthPayload,
    @Param('id') workOrderId: string,
  ) {
    const vendor = await this.vendorPortalService.getVendorByUserId(user.uid);
    return this.vendorPortalService.getJobDetail(vendor.id, workOrderId);
  }

  /**
   * Accept/claim an open job
   */
  @Post('jobs/accept')
  async acceptJob(
    @CurrentUser() user: AuthPayload,
    @Body() dto: AcceptJobDto,
  ) {
    const vendor = await this.vendorPortalService.getVendorByUserId(user.uid);
    return this.vendorPortalService.acceptJob(vendor.id, dto);
  }

  /**
   * Check in to start a job
   */
  @Post('jobs/check-in')
  async checkIn(
    @CurrentUser() user: AuthPayload,
    @Body() dto: CheckInDto,
  ) {
    const vendor = await this.vendorPortalService.getVendorByUserId(user.uid);
    return this.vendorPortalService.checkIn(vendor.id, dto);
  }

  /**
   * Check out to complete a job
   */
  @Post('jobs/check-out')
  async checkOut(
    @CurrentUser() user: AuthPayload,
    @Body() dto: CheckOutDto,
  ) {
    const vendor = await this.vendorPortalService.getVendorByUserId(user.uid);
    return this.vendorPortalService.checkOut(vendor.id, dto);
  }

  /**
   * Get completed jobs history
   */
  @Get('history')
  async getCompletedJobs(@CurrentUser() user: AuthPayload) {
    const vendor = await this.vendorPortalService.getVendorByUserId(user.uid);
    return this.vendorPortalService.getCompletedJobs(vendor.id);
  }

  // =====================
  // MANAGER VERIFICATION ENDPOINTS
  // =====================

  /**
   * Get verification queue (jobs awaiting approval)
   */
  @Get('verification-queue')
  async getVerificationQueue() {
    return this.vendorPortalService.getVerificationQueue();
  }

  /**
   * Verify/approve a completed job
   */
  @Post('verify')
  async verifyJob(
    @CurrentUser() user: AuthPayload,
    @Body() dto: VerifyJobDto,
  ) {
    return this.vendorPortalService.verifyJob(user.uid, dto.workOrderId, dto.notes);
  }

  /**
   * Request revision on a completed job
   */
  @Post('request-revision')
  async requestRevision(
    @CurrentUser() user: AuthPayload,
    @Body() dto: RequestRevisionDto,
  ) {
    return this.vendorPortalService.requestRevision(user.uid, dto.workOrderId, dto.reason);
  }
}
