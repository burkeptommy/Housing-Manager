import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Query,
  Body,
  Headers,
  UseGuards,
  UnauthorizedException,
  ForbiddenException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { FirebaseAuthGuard, CurrentUser, AuthPayload } from '../firebase';
import { HouseholdMemberGuard } from '../common/guards/household-member.guard';
import { RemindersService } from './reminders.service';
import {
  UpcomingItemsResponseDto,
  InAppNotificationDto,
  MarkNotificationReadDto,
  CronJobResultDto,
  DashboardResponseDto,
} from './dto';

@ApiTags('Dashboard')
@Controller()
export class RemindersController {
  constructor(
    private readonly remindersService: RemindersService,
    private readonly configService: ConfigService,
  ) {}

  /**
   * Internal cron endpoint for running reminder jobs
   * Protected by a shared secret header
   */
  @Post('internal/cron/run-reminder-jobs')
  @ApiOperation({ summary: 'Run reminder scheduling and processing jobs (internal cron endpoint)' })
  @ApiResponse({ status: 200, type: CronJobResultDto })
  @ApiResponse({ status: 401, description: 'Invalid or missing cron secret' })
  async runReminderJobs(
    @Headers('x-cron-secret') cronSecret: string,
  ): Promise<CronJobResultDto> {
    const expectedSecret = this.configService.get<string>('CRON_SECRET');

    // Validate cron secret
    if (!expectedSecret || cronSecret !== expectedSecret) {
      throw new UnauthorizedException('Invalid or missing cron secret');
    }

    return this.remindersService.runAllReminderJobs();
  }

  /**
   * Get upcoming items for dashboard
   */
  @Get('dashboard/upcoming')
  @UseGuards(FirebaseAuthGuard, HouseholdMemberGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get upcoming bills and maintenance tasks for dashboard' })
  @ApiQuery({ name: 'householdId', required: true })
  @ApiQuery({ name: 'days', required: false, description: 'Number of days ahead to look (default: 30)' })
  @ApiResponse({ status: 200, type: UpcomingItemsResponseDto })
  async getUpcomingItems(
    @Query('householdId') householdId: string,
    @Query('days') days?: number,
  ): Promise<UpcomingItemsResponseDto> {
    const daysAhead = days || 30;

    const [upcomingBills, upcomingMaintenanceTasks] = await Promise.all([
      this.remindersService.getUpcomingBills(householdId, daysAhead),
      this.remindersService.getUpcomingMaintenanceTasks(householdId, daysAhead),
    ]);

    return {
      upcomingBills,
      upcomingMaintenanceTasks,
    };
  }

  /**
   * Get full dashboard data including summary, next up, today's tasks, and upcoming items
   */
  @Get('dashboard')
  @UseGuards(FirebaseAuthGuard, HouseholdMemberGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Get full dashboard data',
    description:
      'Returns summary stats, next up item, today\'s tasks, upcoming bills, and maintenance tasks',
  })
  @ApiQuery({ name: 'householdId', required: true })
  @ApiResponse({ status: 200, type: DashboardResponseDto })
  async getDashboard(
    @Query('householdId') householdId: string,
  ): Promise<DashboardResponseDto> {
    return this.remindersService.getDashboardData(householdId);
  }

  /**
   * Get in-app notifications for current user
   */
  @Get('notifications')
  @UseGuards(FirebaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get in-app notifications for current user' })
  @ApiQuery({ name: 'unreadOnly', required: false, type: Boolean })
  @ApiResponse({ status: 200, type: [InAppNotificationDto] })
  async getNotifications(
    @CurrentUser() user: AuthPayload,
    @Query('unreadOnly') unreadOnly?: boolean,
  ): Promise<InAppNotificationDto[]> {
    const notifications = await this.remindersService.getInAppNotifications(
      user.userId,
      unreadOnly === true,
    );
    return notifications.map((n) => ({
      id: n.id,
      userId: n.userId,
      householdId: n.householdId ?? undefined,
      title: n.title,
      body: n.body,
      link: n.link ?? undefined,
      isRead: n.isRead,
      readAt: n.readAt ?? undefined,
      createdAt: n.createdAt,
    }));
  }

  /**
   * Get unread notification count
   */
  @Get('notifications/unread-count')
  @UseGuards(FirebaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get unread notification count' })
  @ApiResponse({ status: 200, schema: { properties: { count: { type: 'number' } } } })
  async getUnreadCount(
    @CurrentUser() user: AuthPayload,
  ): Promise<{ count: number }> {
    const count = await this.remindersService.getUnreadCount(user.userId);
    return { count };
  }

  /**
   * Mark a notification as read/unread
   */
  @Patch('notifications/:id')
  @UseGuards(FirebaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Mark notification as read/unread' })
  @ApiResponse({ status: 200 })
  async markNotificationRead(
    @Param('id') id: string,
    @CurrentUser() user: AuthPayload,
    @Body() dto: MarkNotificationReadDto,
  ): Promise<{ success: boolean }> {
    await this.remindersService.markNotificationRead(id, user.userId, dto.isRead);
    return { success: true };
  }

  /**
   * Mark all notifications as read
   */
  @Post('notifications/mark-all-read')
  @UseGuards(FirebaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Mark all notifications as read' })
  @ApiResponse({ status: 200 })
  async markAllNotificationsRead(
    @CurrentUser() user: AuthPayload,
  ): Promise<{ success: boolean }> {
    await this.remindersService.markAllNotificationsRead(user.userId);
    return { success: true };
  }
}
