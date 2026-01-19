import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { FirebaseAuthGuard, CurrentUser, AuthPayload } from '../firebase';
import { CalendarsService } from './calendars.service';

@ApiTags('calendars')
@ApiBearerAuth()
@Controller('calendars')
@UseGuards(FirebaseAuthGuard)
export class CalendarsController {
  constructor(private readonly calendarsService: CalendarsService) {}

  @Get('connections')
  @ApiOperation({ summary: 'Get calendar connections for current household' })
  async getConnections(@CurrentUser() user: AuthPayload) {
    return this.calendarsService.getConnections(user);
  }

  @Post('connect/google')
  @ApiOperation({ summary: 'Connect Google Calendar' })
  async connectGoogle(
    @CurrentUser() user: AuthPayload,
    @Body() body: { accessToken: string; refreshToken?: string },
  ) {
    return this.calendarsService.connectGoogle(
      user,
      body.accessToken,
      body.refreshToken,
    );
  }

  @Post('connect/apple')
  @ApiOperation({ summary: 'Connect iOS Calendar (device calendars)' })
  async connectApple(
    @CurrentUser() user: AuthPayload,
    @Body() body: { calendarIds: string[] },
  ) {
    return this.calendarsService.connectApple(user, body.calendarIds);
  }

  @Delete('disconnect/:provider')
  @ApiOperation({ summary: 'Disconnect a calendar provider' })
  async disconnect(
    @CurrentUser() user: AuthPayload,
    @Param('provider') provider: string,
  ) {
    return this.calendarsService.disconnect(user, provider);
  }

  @Get('events')
  @ApiOperation({ summary: 'Get synced calendar events' })
  async getEvents(
    @CurrentUser() user: AuthPayload,
    @Query('start') start: string,
    @Query('end') end: string,
  ) {
    return this.calendarsService.getEvents(
      user,
      new Date(start || new Date().toISOString()),
      new Date(end || new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString()),
    );
  }

  @Post('sync')
  @ApiOperation({ summary: 'Manually trigger calendar sync' })
  async syncCalendars(@CurrentUser() user: AuthPayload) {
    return this.calendarsService.syncAllCalendars(user);
  }
}
