import { Injectable, Logger, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateFamilyEventDto, UpdateFamilyEventDto, CalendarFeedQueryDto } from '../dto';
import { FamilyEventCategory } from '@prisma/client';
import * as crypto from 'crypto';

@Injectable()
export class CalendarService {
  private readonly logger = new Logger(CalendarService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Create a new family event
   */
  async create(householdId: string, userId: string, dto: CreateFamilyEventDto) {
    return this.prisma.familyEvent.create({
      data: {
        householdId,
        createdByUserId: userId,
        ...dto,
      },
      include: {
        assignedTo: {
          select: { id: true, nickname: true, user: { select: { displayName: true } } },
        },
        vehicle: {
          select: { id: true, nickname: true, make: true, model: true },
        },
        pet: {
          select: { id: true, name: true, type: true },
        },
      },
    });
  }

  /**
   * Get all events for a household within a date range
   */
  async findAllByHousehold(
    householdId: string,
    startDate?: Date,
    endDate?: Date,
    categories?: FamilyEventCategory[],
    memberId?: string,
  ) {
    const where: any = {
      householdId,
    };

    if (startDate || endDate) {
      where.startDate = {};
      if (startDate) where.startDate.gte = startDate;
      if (endDate) where.startDate.lte = endDate;
    }

    if (categories && categories.length > 0) {
      where.category = { in: categories };
    }

    if (memberId) {
      where.assignedToMemberId = memberId;
    }

    return this.prisma.familyEvent.findMany({
      where,
      include: {
        assignedTo: {
          select: { id: true, nickname: true, user: { select: { displayName: true } } },
        },
        vehicle: {
          select: { id: true, nickname: true, make: true, model: true },
        },
        pet: {
          select: { id: true, name: true, type: true },
        },
      },
      orderBy: { startDate: 'asc' },
    });
  }

  /**
   * Get a single event by ID
   */
  async findOne(id: string, householdId: string) {
    const event = await this.prisma.familyEvent.findUnique({
      where: { id },
      include: {
        assignedTo: {
          include: { user: { select: { displayName: true } } },
        },
        vehicle: true,
        pet: true,
        createdBy: {
          select: { id: true, displayName: true },
        },
      },
    });

    if (!event) {
      throw new NotFoundException('Event not found');
    }

    if (event.householdId !== householdId) {
      throw new ForbiddenException('Access denied');
    }

    return event;
  }

  /**
   * Update an event
   */
  async update(id: string, householdId: string, dto: UpdateFamilyEventDto) {
    await this.findOne(id, householdId);

    return this.prisma.familyEvent.update({
      where: { id },
      data: dto,
      include: {
        assignedTo: {
          select: { id: true, nickname: true, user: { select: { displayName: true } } },
        },
      },
    });
  }

  /**
   * Delete an event
   */
  async remove(id: string, householdId: string) {
    await this.findOne(id, householdId);

    return this.prisma.familyEvent.delete({
      where: { id },
    });
  }

  /**
   * Get upcoming events for a household
   */
  async getUpcoming(householdId: string, limit = 10) {
    return this.prisma.familyEvent.findMany({
      where: {
        householdId,
        startDate: { gte: new Date() },
      },
      include: {
        assignedTo: {
          select: { id: true, nickname: true, user: { select: { displayName: true } } },
        },
      },
      orderBy: { startDate: 'asc' },
      take: limit,
    });
  }

  /**
   * Get unified calendar view (family events + maintenance)
   */
  async getUnifiedCalendar(
    householdId: string,
    startDate: Date,
    endDate: Date,
    includeWorkOrders = true,
  ) {
    // Get family events
    const familyEvents = await this.prisma.familyEvent.findMany({
      where: {
        householdId,
        startDate: { gte: startDate, lte: endDate },
      },
      include: {
        assignedTo: {
          select: { id: true, nickname: true, user: { select: { displayName: true } } },
        },
        vehicle: {
          select: { id: true, nickname: true, make: true, model: true },
        },
        pet: {
          select: { id: true, name: true },
        },
      },
      orderBy: { startDate: 'asc' },
    });

    const events: Array<{
      id: string;
      title: string;
      start: Date;
      end?: Date;
      allDay: boolean;
      category: string;
      color?: string;
      type: 'family' | 'maintenance';
      meta?: any;
    }> = familyEvents.map(event => ({
      id: event.id,
      title: event.title,
      start: event.startDate,
      end: event.endDate || undefined,
      allDay: event.isAllDay,
      category: event.category,
      color: event.color || this.getCategoryColor(event.category),
      type: 'family' as const,
      meta: {
        description: event.description,
        location: event.location,
        assignedTo: event.assignedTo?.user?.displayName || event.assignedTo?.nickname,
        vehicle: event.vehicle,
        pet: event.pet,
      },
    }));

    // Include scheduled work orders as maintenance events
    if (includeWorkOrders) {
      const workOrders = await this.prisma.workOrder.findMany({
        where: {
          householdId,
          scheduledDate: { gte: startDate, lte: endDate },
          status: { in: ['SCHEDULED', 'IN_PROGRESS'] },
        },
        include: {
          vendor: {
            select: { displayName: true },
          },
        },
      });

      for (const wo of workOrders) {
        events.push({
          id: wo.id,
          title: `🔧 ${wo.title}`,
          start: wo.scheduledDate!,
          end: wo.scheduledEndDate || undefined,
          allDay: false,
          category: 'MAINTENANCE',
          color: '#f59e0b', // Amber for maintenance
          type: 'maintenance',
          meta: {
            description: wo.description,
            vendor: wo.vendor?.displayName,
            status: wo.status,
            workOrderId: wo.id,
          },
        });
      }
    }

    return events.sort((a, b) => a.start.getTime() - b.start.getTime());
  }

  /**
   * Generate iCal feed for a household
   */
  async generateICalFeed(
    householdId: string,
    feedToken: string,
    query: CalendarFeedQueryDto,
  ): Promise<string> {
    // Verify feed token
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
    });

    if (!household) {
      throw new NotFoundException('Household not found');
    }

    // In production, verify the feed token matches
    // For now, we'll generate a simple hash-based verification
    const expectedToken = this.generateFeedToken(householdId);
    if (feedToken !== expectedToken) {
      throw new ForbiddenException('Invalid feed token');
    }

    // Get events for the feed
    const now = new Date();
    const startDate = query.lookbackDays
      ? new Date(now.getTime() - query.lookbackDays * 24 * 60 * 60 * 1000)
      : new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000); // Default 30 days back
    const endDate = query.lookaheadDays
      ? new Date(now.getTime() + query.lookaheadDays * 24 * 60 * 60 * 1000)
      : new Date(now.getTime() + 365 * 24 * 60 * 60 * 1000); // Default 1 year ahead

    const events = await this.getUnifiedCalendar(
      householdId,
      startDate,
      endDate,
      query.includeMaintenance !== false,
    );

    // Generate iCal format
    const ical = this.buildICalendar(householdId, events);
    return ical;
  }

  /**
   * Generate a feed token for a household
   */
  generateFeedToken(householdId: string): string {
    // In production, use a secret key from environment
    const secret = process.env.ICAL_SECRET || 'haven-ical-secret';
    return crypto
      .createHmac('sha256', secret)
      .update(householdId)
      .digest('hex')
      .substring(0, 32);
  }

  /**
   * Get feed URL for a household
   */
  getFeedUrl(householdId: string, baseUrl: string): string {
    const token = this.generateFeedToken(householdId);
    return `${baseUrl}/api/family/calendar/${householdId}/feed/${token}.ics`;
  }

  /**
   * Build iCalendar string
   */
  private buildICalendar(
    householdId: string,
    events: Array<{
      id: string;
      title: string;
      start: Date;
      end?: Date;
      allDay: boolean;
      category: string;
      type: string;
      meta?: any;
    }>,
  ): string {
    const lines: string[] = [
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//Haven//Family Calendar//EN',
      'CALSCALE:GREGORIAN',
      'METHOD:PUBLISH',
      `X-WR-CALNAME:Haven Family Calendar`,
      `X-WR-CALDESC:Family events and home maintenance`,
    ];

    for (const event of events) {
      lines.push('BEGIN:VEVENT');
      lines.push(`UID:${event.id}@haven.app`);
      lines.push(`DTSTAMP:${this.formatICalDate(new Date())}`);

      if (event.allDay) {
        lines.push(`DTSTART;VALUE=DATE:${this.formatICalDateOnly(event.start)}`);
        if (event.end) {
          lines.push(`DTEND;VALUE=DATE:${this.formatICalDateOnly(event.end)}`);
        }
      } else {
        lines.push(`DTSTART:${this.formatICalDate(event.start)}`);
        if (event.end) {
          lines.push(`DTEND:${this.formatICalDate(event.end)}`);
        }
      }

      lines.push(`SUMMARY:${this.escapeICalText(event.title)}`);

      if (event.meta?.description) {
        lines.push(`DESCRIPTION:${this.escapeICalText(event.meta.description)}`);
      }

      if (event.meta?.location) {
        lines.push(`LOCATION:${this.escapeICalText(event.meta.location)}`);
      }

      // Add category
      lines.push(`CATEGORIES:${event.category}`);

      lines.push('END:VEVENT');
    }

    lines.push('END:VCALENDAR');

    return lines.join('\r\n');
  }

  /**
   * Format date for iCal (UTC)
   */
  private formatICalDate(date: Date): string {
    return date.toISOString().replace(/[-:]/g, '').replace(/\.\d{3}/, '');
  }

  /**
   * Format date only for iCal (no time)
   */
  private formatICalDateOnly(date: Date): string {
    return date.toISOString().split('T')[0].replace(/-/g, '');
  }

  /**
   * Escape text for iCal format
   */
  private escapeICalText(text: string): string {
    return text
      .replace(/\\/g, '\\\\')
      .replace(/;/g, '\\;')
      .replace(/,/g, '\\,')
      .replace(/\n/g, '\\n');
  }

  /**
   * Get color for category
   */
  private getCategoryColor(category: FamilyEventCategory): string {
    const colors: Record<FamilyEventCategory, string> = {
      SCHOOL: '#3b82f6', // Blue
      MEDICAL: '#ef4444', // Red
      SPORTS: '#22c55e', // Green
      SOCIAL: '#a855f7', // Purple
      WORK: '#6366f1', // Indigo
      TRAVEL: '#06b6d4', // Cyan
      MAINTENANCE: '#f59e0b', // Amber
      FINANCIAL: '#84cc16', // Lime
      RELIGIOUS: '#8b5cf6', // Violet
      BIRTHDAY: '#ec4899', // Pink
      HOLIDAY: '#f97316', // Orange
      OTHER: '#6b7280', // Gray
    };
    return colors[category] || '#6b7280';
  }

  /**
   * Get calendar summary for dashboard
   */
  async getCalendarSummary(householdId: string) {
    const now = new Date();
    const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const endOfWeek = new Date(startOfDay.getTime() + 7 * 24 * 60 * 60 * 1000);
    const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0);

    const [todayEvents, weekEvents, monthEvents] = await Promise.all([
      this.prisma.familyEvent.count({
        where: {
          householdId,
          startDate: {
            gte: startOfDay,
            lt: new Date(startOfDay.getTime() + 24 * 60 * 60 * 1000),
          },
        },
      }),
      this.prisma.familyEvent.count({
        where: {
          householdId,
          startDate: { gte: startOfDay, lte: endOfWeek },
        },
      }),
      this.prisma.familyEvent.count({
        where: {
          householdId,
          startDate: { gte: startOfDay, lte: endOfMonth },
        },
      }),
    ]);

    // Get upcoming birthdays
    const members = await this.prisma.householdMember.findMany({
      where: {
        householdId,
        isActive: true,
      },
    });

    const upcomingBirthdays = members
      .filter(m => {
        const profile = m.profile as any;
        if (!profile?.birthday) return false;
        const birthday = new Date(profile.birthday);
        const nextBirthday = new Date(now.getFullYear(), birthday.getMonth(), birthday.getDate());
        if (nextBirthday < now) {
          nextBirthday.setFullYear(nextBirthday.getFullYear() + 1);
        }
        const daysUntil = (nextBirthday.getTime() - now.getTime()) / (1000 * 60 * 60 * 24);
        return daysUntil <= 30;
      })
      .map(m => {
        const profile = m.profile as any;
        const birthday = new Date(profile.birthday);
        const nextBirthday = new Date(now.getFullYear(), birthday.getMonth(), birthday.getDate());
        if (nextBirthday < now) {
          nextBirthday.setFullYear(nextBirthday.getFullYear() + 1);
        }
        const daysUntil = Math.ceil((nextBirthday.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
        return {
          memberId: m.id,
          name: m.displayName,
          date: nextBirthday,
          daysUntil,
        };
      })
      .sort((a, b) => a.daysUntil - b.daysUntil);

    return {
      todayCount: todayEvents,
      weekCount: weekEvents,
      monthCount: monthEvents,
      upcomingBirthdays,
    };
  }
}
