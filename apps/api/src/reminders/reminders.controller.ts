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
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { HouseholdMemberGuard } from '../common/guards/household-member.guard';
import { RemindersService } from './reminders.service';
import {
  UpcomingItemsResponseDto,
  InAppNotificationDto,
  MarkNotificationReadDto,
  CronJobResultDto,
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
  @UseGuards(JwtAuthGuard, HouseholdMemberGuard)
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
   * Get in-app notifications for current user
   */
  @Get('notifications')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get in-app notifications for current user' })
  @ApiQuery({ name: 'unreadOnly', required: false, type: Boolean })
  @ApiResponse({ status: 200, type: [InAppNotificationDto] })
  async getNotifications(
    @CurrentUser() user: { id: string },
    @Query('unreadOnly') unreadOnly?: boolean,
  ): Promise<InAppNotificationDto[]> {
    const notifications = await this.remindersService.getInAppNotifications(
      user.id,
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
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get unread notification count' })
  @ApiResponse({ status: 200, schema: { properties: { count: { type: 'number' } } } })
  async getUnreadCount(
    @CurrentUser() user: { id: string },
  ): Promise<{ count: number }> {
    const count = await this.remindersService.getUnreadCount(user.id);
    return { count };
  }

  /**
   * Mark a notification as read/unread
   */
  @Patch('notifications/:id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Mark notification as read/unread' })
  @ApiResponse({ status: 200 })
  async markNotificationRead(
    @Param('id') id: string,
    @CurrentUser() user: { id: string },
    @Body() dto: MarkNotificationReadDto,
  ): Promise<{ success: boolean }> {
    await this.remindersService.markNotificationRead(id, user.id, dto.isRead);
    return { success: true };
  }

  /**
   * Mark all notifications as read
   */
  @Post('notifications/mark-all-read')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Mark all notifications as read' })
  @ApiResponse({ status: 200 })
  async markAllNotificationsRead(
    @CurrentUser() user: { id: string },
  ): Promise<{ success: boolean }> {
    await this.remindersService.markAllNotificationsRead(user.id);
    return { success: true };
  }
}
