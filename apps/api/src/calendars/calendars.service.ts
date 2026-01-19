import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Cron } from '@nestjs/schedule';
import { AuthPayload } from '../firebase';
import * as crypto from 'crypto';

// Type for calendar connection from Prisma
interface CalendarConnectionRecord {
  id: string;
  householdId: string;
  userId: string;
  provider: string;
  accountEmail: string | null;
  accessToken: string | null;
  refreshToken: string | null;
  tokenExpiry: Date | null;
  deviceCalendarIds: string[];
  isActive: boolean;
  lastSyncAt: Date | null;
  syncError: string | null;
  createdAt: Date;
  updatedAt: Date;
}

@Injectable()
export class CalendarsService {
  private readonly logger = new Logger(CalendarsService.name);
  private readonly encryptionKey: string;

  constructor(private prisma: PrismaService) {
    // Get encryption key from env, pad or truncate to 32 chars
    const key = process.env.CALENDAR_ENCRYPTION_KEY || 'default-key-change-me-32chars!!';
    this.encryptionKey = key.padEnd(32, '0').slice(0, 32);
  }

  private encrypt(text: string): string {
    try {
      const iv = crypto.randomBytes(16);
      const cipher = crypto.createCipheriv(
        'aes-256-cbc',
        Buffer.from(this.encryptionKey),
        iv,
      );
      let encrypted = cipher.update(text);
      encrypted = Buffer.concat([encrypted, cipher.final()]);
      return iv.toString('hex') + ':' + encrypted.toString('hex');
    } catch (error) {
      this.logger.error('Encryption failed:', error);
      throw new Error('Failed to encrypt token');
    }
  }

  private decrypt(text: string): string {
    try {
      const parts = text.split(':');
      const iv = Buffer.from(parts.shift()!, 'hex');
      const encryptedText = Buffer.from(parts.join(':'), 'hex');
      const decipher = crypto.createDecipheriv(
        'aes-256-cbc',
        Buffer.from(this.encryptionKey),
        iv,
      );
      let decrypted = decipher.update(encryptedText);
      decrypted = Buffer.concat([decrypted, decipher.final()]);
      return decrypted.toString();
    } catch (error) {
      this.logger.error('Decryption failed:', error);
      throw new Error('Failed to decrypt token');
    }
  }

  private getHouseholdId(user: AuthPayload): string {
    if (!user.householdId) {
      throw new BadRequestException('No household found for user');
    }
    return user.householdId;
  }

  async getConnections(user: AuthPayload) {
    const householdId = this.getHouseholdId(user);

    return this.prisma.calendarConnection.findMany({
      where: { householdId, isActive: true },
      select: {
        id: true,
        provider: true,
        accountEmail: true,
        lastSyncAt: true,
        syncError: true,
        deviceCalendarIds: true,
      },
    });
  }

  async connectGoogle(
    user: AuthPayload,
    accessToken: string,
    refreshToken?: string,
  ) {
    const householdId = this.getHouseholdId(user);

    // Get user info from Google
    const userInfo = await this.fetchGoogleUserInfo(accessToken);

    // Create or update connection
    const connection = await this.prisma.calendarConnection.upsert({
      where: {
        householdId_provider_accountEmail: {
          householdId,
          provider: 'google',
          accountEmail: userInfo.email,
        },
      },
      update: {
        accessToken: this.encrypt(accessToken),
        refreshToken: refreshToken ? this.encrypt(refreshToken) : undefined,
        isActive: true,
        syncError: null,
      },
      create: {
        householdId,
        userId: user.userId,
        provider: 'google',
        accountEmail: userInfo.email,
        accessToken: this.encrypt(accessToken),
        refreshToken: refreshToken ? this.encrypt(refreshToken) : undefined,
      },
    });

    // Trigger initial sync
    await this.syncGoogleCalendar(connection);

    return { success: true, provider: 'google', email: userInfo.email };
  }

  async connectApple(user: AuthPayload, calendarIds: string[]) {
    const householdId = this.getHouseholdId(user);

    // Get user email for identification
    const dbUser = await this.prisma.user.findUnique({
      where: { id: user.userId },
      select: { email: true },
    });

    // Create or update connection
    await this.prisma.calendarConnection.upsert({
      where: {
        householdId_provider_accountEmail: {
          householdId,
          provider: 'apple',
          accountEmail: dbUser?.email || user.email,
        },
      },
      update: {
        deviceCalendarIds: calendarIds,
        isActive: true,
        syncError: null,
        lastSyncAt: new Date(), // Apple calendars sync on-device
      },
      create: {
        householdId,
        userId: user.userId,
        provider: 'apple',
        accountEmail: dbUser?.email || user.email,
        deviceCalendarIds: calendarIds,
        lastSyncAt: new Date(),
      },
    });

    return { success: true, provider: 'apple', calendarCount: calendarIds.length };
  }

  async disconnect(user: AuthPayload, provider: string) {
    const householdId = this.getHouseholdId(user);

    // Deactivate connection
    await this.prisma.calendarConnection.updateMany({
      where: { householdId, provider },
      data: { isActive: false },
    });

    // Delete synced events for this provider
    const connections = await this.prisma.calendarConnection.findMany({
      where: { householdId, provider },
      select: { id: true },
    });

    for (const conn of connections) {
      await this.prisma.calendarEvent.deleteMany({
        where: { connectionId: conn.id },
      });
    }

    return { success: true };
  }

  private async fetchGoogleUserInfo(accessToken: string): Promise<{ email: string; name?: string }> {
    const response = await fetch(
      'https://www.googleapis.com/oauth2/v2/userinfo',
      {
        headers: { Authorization: `Bearer ${accessToken}` },
      },
    );
    if (!response.ok) {
      throw new BadRequestException('Failed to fetch Google user info');
    }
    return response.json() as Promise<{ email: string; name?: string }>;
  }

  private async fetchGoogleCalendars(accessToken: string): Promise<Array<{ id: string; summary: string; backgroundColor?: string }>> {
    const response = await fetch(
      'https://www.googleapis.com/calendar/v3/users/me/calendarList',
      { headers: { Authorization: `Bearer ${accessToken}` } },
    );
    if (!response.ok) {
      throw new Error('Failed to fetch Google calendars');
    }
    const data = await response.json() as { items?: Array<{ id: string; summary: string; backgroundColor?: string }> };
    return data.items || [];
  }

  private async fetchGoogleEvents(
    accessToken: string,
    calendarId: string,
    timeMin: Date,
    timeMax: Date,
  ): Promise<Array<{
    id: string;
    summary?: string;
    description?: string;
    location?: string;
    start?: { dateTime?: string; date?: string };
    end?: { dateTime?: string; date?: string };
  }>> {
    const params = new URLSearchParams({
      timeMin: timeMin.toISOString(),
      timeMax: timeMax.toISOString(),
      singleEvents: 'true',
      orderBy: 'startTime',
      maxResults: '100',
    });

    const response = await fetch(
      `https://www.googleapis.com/calendar/v3/calendars/${encodeURIComponent(calendarId)}/events?${params}`,
      { headers: { Authorization: `Bearer ${accessToken}` } },
    );
    if (!response.ok) {
      throw new Error('Failed to fetch Google events');
    }
    const data = await response.json() as { items?: Array<{
      id: string;
      summary?: string;
      description?: string;
      location?: string;
      start?: { dateTime?: string; date?: string };
      end?: { dateTime?: string; date?: string };
    }> };
    return data.items || [];
  }

  async syncGoogleCalendar(connection: CalendarConnectionRecord) {
    if (!connection.accessToken) {
      this.logger.warn(`No access token for connection ${connection.id}`);
      return;
    }

    try {
      const accessToken = this.decrypt(connection.accessToken);

      // Fetch events for next 30 days
      const now = new Date();
      const endDate = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);

      const calendars = await this.fetchGoogleCalendars(accessToken);

      for (const calendar of calendars) {
        try {
          const events = await this.fetchGoogleEvents(
            accessToken,
            calendar.id,
            now,
            endDate,
          );

          for (const event of events) {
            if (!event.id) continue;

            await this.prisma.calendarEvent.upsert({
              where: {
                connectionId_externalId: {
                  connectionId: connection.id,
                  externalId: event.id,
                },
              },
              update: {
                title: event.summary || '(No title)',
                description: event.description || null,
                location: event.location || null,
                startTime: new Date(event.start?.dateTime || event.start?.date),
                endTime: new Date(event.end?.dateTime || event.end?.date),
                isAllDay: !!event.start?.date,
                calendarName: calendar.summary,
                calendarColor: calendar.backgroundColor,
              },
              create: {
                connectionId: connection.id,
                householdId: connection.householdId,
                externalId: event.id,
                title: event.summary || '(No title)',
                description: event.description || null,
                location: event.location || null,
                startTime: new Date(event.start?.dateTime || event.start?.date),
                endTime: new Date(event.end?.dateTime || event.end?.date),
                isAllDay: !!event.start?.date,
                calendarName: calendar.summary,
                calendarColor: calendar.backgroundColor,
              },
            });
          }
        } catch (calError) {
          this.logger.warn(
            `Failed to sync calendar ${calendar.id}: ${calError.message}`,
          );
        }
      }

      await this.prisma.calendarConnection.update({
        where: { id: connection.id },
        data: { lastSyncAt: new Date(), syncError: null },
      });

      this.logger.log(`Synced Google calendar for connection ${connection.id}`);
    } catch (error) {
      this.logger.error(`Google calendar sync failed: ${error.message}`);
      await this.prisma.calendarConnection.update({
        where: { id: connection.id },
        data: { syncError: error.message },
      });
    }
  }

  // Scheduled sync - every 15 minutes
  @Cron('0 */15 * * * *') // Every 15 minutes
  async scheduledSync() {
    this.logger.log('Starting scheduled calendar sync...');

    const connections = await this.prisma.calendarConnection.findMany({
      where: { isActive: true, provider: 'google' },
    });

    for (const connection of connections) {
      try {
        await this.syncGoogleCalendar(connection);
      } catch (error) {
        this.logger.error(
          `Scheduled sync failed for connection ${connection.id}: ${error.message}`,
        );
      }
    }

    this.logger.log(`Scheduled sync complete. Processed ${connections.length} connections.`);
  }

  async getEvents(user: AuthPayload, startDate: Date, endDate: Date) {
    const householdId = this.getHouseholdId(user);

    return this.prisma.calendarEvent.findMany({
      where: {
        householdId,
        startTime: { gte: startDate },
        endTime: { lte: endDate },
        connection: { isActive: true },
      },
      orderBy: { startTime: 'asc' },
      include: {
        familyMember: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
          },
        },
      },
    });
  }

  async syncAllCalendars(user: AuthPayload) {
    const householdId = this.getHouseholdId(user);

    const connections = await this.prisma.calendarConnection.findMany({
      where: { householdId, isActive: true },
    });

    let synced = 0;
    for (const connection of connections) {
      if (connection.provider === 'google') {
        await this.syncGoogleCalendar(connection);
        synced++;
      }
      // Apple calendars are synced on-device, not server-side
    }

    return { success: true, synced };
  }
}
