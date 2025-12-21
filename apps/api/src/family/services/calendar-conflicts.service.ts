import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { FamilyEventCategory } from '@prisma/client';

interface ConflictCheckResult {
  hasConflict: boolean;
  conflicts: ConflictDetail[];
}

interface ConflictDetail {
  type: 'OVERLAP' | 'TRAVEL' | 'CHILDCARE' | 'ACCESS';
  severity: 'INFO' | 'WARNING' | 'CRITICAL';
  message: string;
  conflictingEventId?: string;
  suggestedAction?: string;
}

interface EventInput {
  householdId: string;
  startDate: Date;
  endDate?: Date;
  isAllDay?: boolean;
  category?: FamilyEventCategory;
  requiresAccess?: boolean;
  attendees?: string[];
}

@Injectable()
export class CalendarConflictsService {
  private readonly logger = new Logger(CalendarConflictsService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Check for all types of conflicts when adding/updating an event
   */
  async checkConflicts(event: EventInput, excludeEventId?: string): Promise<ConflictCheckResult> {
    const conflicts: ConflictDetail[] = [];

    // Run all conflict checks in parallel
    const [overlaps, travelConflicts, childcareNeeds, accessIssues] = await Promise.all([
      this.checkOverlappingEvents(event, excludeEventId),
      this.checkTravelConflicts(event),
      this.checkChildcareNeeds(event),
      this.checkAccessRequirements(event),
    ]);

    conflicts.push(...overlaps, ...travelConflicts, ...childcareNeeds, ...accessIssues);

    return {
      hasConflict: conflicts.some(c => c.severity === 'CRITICAL' || c.severity === 'WARNING'),
      conflicts,
    };
  }

  /**
   * Check for overlapping events at the same time
   */
  private async checkOverlappingEvents(
    event: EventInput,
    excludeEventId?: string,
  ): Promise<ConflictDetail[]> {
    const conflicts: ConflictDetail[] = [];
    const eventEnd = event.endDate || new Date(event.startDate.getTime() + 60 * 60 * 1000); // Default 1 hour

    const overlappingEvents = await this.prisma.familyEvent.findMany({
      where: {
        householdId: event.householdId,
        id: excludeEventId ? { not: excludeEventId } : undefined,
        OR: [
          {
            // Event starts during our event
            startDate: {
              gte: event.startDate,
              lt: eventEnd,
            },
          },
          {
            // Event ends during our event
            endDate: {
              gt: event.startDate,
              lte: eventEnd,
            },
          },
          {
            // Event completely contains our event
            AND: [
              { startDate: { lte: event.startDate } },
              { endDate: { gte: eventEnd } },
            ],
          },
        ],
      },
      select: {
        id: true,
        title: true,
        startDate: true,
        category: true,
      },
    });

    for (const overlap of overlappingEvents) {
      // Determine severity based on event types
      let severity: ConflictDetail['severity'] = 'INFO';
      if (
        (event.category === 'MEDICAL' && overlap.category === 'MEDICAL') ||
        (event.category === 'SCHOOL' && overlap.category === 'SCHOOL')
      ) {
        severity = 'CRITICAL';
      } else if (overlap.category !== 'OTHER') {
        severity = 'WARNING';
      }

      conflicts.push({
        type: 'OVERLAP',
        severity,
        message: `Overlaps with "${overlap.title}" at ${overlap.startDate.toLocaleTimeString()}`,
        conflictingEventId: overlap.id,
        suggestedAction: severity === 'CRITICAL' ? 'Reschedule one of these events' : undefined,
      });
    }

    return conflicts;
  }

  /**
   * Check if anyone will be traveling during this event
   */
  private async checkTravelConflicts(event: EventInput): Promise<ConflictDetail[]> {
    const conflicts: ConflictDetail[] = [];
    const eventEnd = event.endDate || new Date(event.startDate.getTime() + 60 * 60 * 1000);

    // Check for travel events that overlap
    const travelEvents = await this.prisma.familyEvent.findMany({
      where: {
        householdId: event.householdId,
        category: 'TRAVEL',
        AND: [
          { startDate: { lte: eventEnd } },
          { endDate: { gte: event.startDate } },
        ],
      },
      select: {
        id: true,
        title: true,
        startDate: true,
        endDate: true,
        assignedTo: {
          select: {
            nickname: true,
            user: { select: { displayName: true } },
          },
        },
      },
    });

    for (const travel of travelEvents) {
      const travelerName = travel.assignedTo?.user?.displayName || travel.assignedTo?.nickname || 'Family';

      conflicts.push({
        type: 'TRAVEL',
        severity: event.category === 'MAINTENANCE' ? 'CRITICAL' : 'WARNING',
        message: `${travelerName} will be away (${travel.title})`,
        conflictingEventId: travel.id,
        suggestedAction: event.category === 'MAINTENANCE'
          ? 'Ensure someone will be home or grant access'
          : undefined,
      });
    }

    return conflicts;
  }

  /**
   * Check if childcare might be needed for this event
   */
  private async checkChildcareNeeds(event: EventInput): Promise<ConflictDetail[]> {
    const conflicts: ConflictDetail[] = [];

    // Only check for events that require adult attendance
    const adultCategories: FamilyEventCategory[] = ['SOCIAL', 'WORK', 'MEDICAL'];
    if (!event.category || !adultCategories.includes(event.category)) {
      return conflicts;
    }

    // Get household members to identify children
    const members = await this.prisma.householdMember.findMany({
      where: {
        householdId: event.householdId,
        isActive: true,
      },
      select: {
        id: true,
        nickname: true,
        role: true,
        relationship: true,
      },
    });

    const children = members.filter(m =>
      m.relationship === 'CHILD' || m.role === 'CHILD'
    );

    if (children.length === 0) {
      return conflicts;
    }

    // Check if there are any kid events at the same time (meaning kids will be supervised)
    const eventEnd = event.endDate || new Date(event.startDate.getTime() + 60 * 60 * 1000);

    const kidEvents = await this.prisma.familyEvent.findMany({
      where: {
        householdId: event.householdId,
        category: { in: ['SCHOOL', 'SPORTS'] },
        AND: [
          { startDate: { lte: eventEnd } },
          { endDate: { gte: event.startDate } },
        ],
      },
    });

    // If no kid events, they might need supervision
    if (kidEvents.length === 0) {
      const startHour = event.startDate.getHours();
      const isSchoolHours = startHour >= 8 && startHour < 15;
      const isWeekday = event.startDate.getDay() > 0 && event.startDate.getDay() < 6;

      // Only warn outside school hours or on weekends
      if (!isSchoolHours || !isWeekday) {
        conflicts.push({
          type: 'CHILDCARE',
          severity: 'INFO',
          message: `Consider childcare for ${children.map(c => c.nickname).join(', ')}`,
          suggestedAction: 'Arrange supervision or bring kids along',
        });
      }
    }

    return conflicts;
  }

  /**
   * Check if the event requires home access and if anyone will be home
   */
  private async checkAccessRequirements(event: EventInput): Promise<ConflictDetail[]> {
    const conflicts: ConflictDetail[] = [];

    // Only check for maintenance-type events that typically need access
    const accessCategories: FamilyEventCategory[] = ['MAINTENANCE'];
    if (!event.category || !accessCategories.includes(event.category)) {
      return conflicts;
    }

    const eventEnd = event.endDate || new Date(event.startDate.getTime() + 60 * 60 * 1000);

    // Check if any family members have events during this time (meaning they're away)
    const awayEvents = await this.prisma.familyEvent.findMany({
      where: {
        householdId: event.householdId,
        category: { in: ['WORK', 'SCHOOL', 'TRAVEL', 'SPORTS', 'MEDICAL'] },
        AND: [
          { startDate: { lte: event.startDate } },
          { endDate: { gte: event.startDate } },
        ],
      },
      select: {
        assignedTo: {
          select: { role: true },
        },
      },
    });

    // If we find away events, check if any adults are home
    const adultsAway = awayEvents.filter(e =>
      e.assignedTo?.role === 'PARENT' || e.assignedTo?.role === 'ADULT'
    );

    if (adultsAway.length > 0) {
      conflicts.push({
        type: 'ACCESS',
        severity: 'WARNING',
        message: 'No one may be home during this service visit',
        suggestedAction: 'Share access code or reschedule',
      });
    }

    return conflicts;
  }

  /**
   * Get events that need attention (conflicts, action required)
   */
  async getEventsNeedingAttention(householdId: string): Promise<{
    conflictEvents: any[];
    actionRequiredEvents: any[];
    upcomingReminders: any[];
  }> {
    const now = new Date();
    const oneWeekAhead = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

    const [conflictEvents, actionRequiredEvents, upcomingReminders] = await Promise.all([
      // Events with unresolved conflicts
      this.prisma.familyEvent.findMany({
        where: {
          householdId,
          hasConflict: true,
          conflictResolvedAt: null,
          startDate: { gte: now, lte: oneWeekAhead },
        },
        orderBy: { startDate: 'asc' },
      }),

      // Events requiring homeowner action
      this.prisma.familyEvent.findMany({
        where: {
          householdId,
          requiresAction: true,
          actionCompletedAt: null,
          startDate: { gte: now, lte: oneWeekAhead },
        },
        orderBy: { startDate: 'asc' },
      }),

      // Events with custom reminders that haven't been sent
      this.prisma.familyEvent.findMany({
        where: {
          householdId,
          reminderText: { not: null },
          reminderSentAt: null,
          startDate: { gte: now, lte: oneWeekAhead },
        },
        orderBy: { startDate: 'asc' },
      }),
    ]);

    return {
      conflictEvents,
      actionRequiredEvents,
      upcomingReminders,
    };
  }

  /**
   * Get days that need attention in a date range
   */
  async getDaysNeedingAttention(
    householdId: string,
    startDate: Date,
    endDate: Date,
  ): Promise<Map<string, string[]>> {
    const dayIssues = new Map<string, string[]>();

    const problemEvents = await this.prisma.familyEvent.findMany({
      where: {
        householdId,
        startDate: { gte: startDate, lte: endDate },
        OR: [
          { hasConflict: true, conflictResolvedAt: null },
          { requiresAction: true, actionCompletedAt: null },
        ],
      },
      select: {
        startDate: true,
        hasConflict: true,
        conflictReason: true,
        requiresAction: true,
        actionDescription: true,
      },
    });

    for (const event of problemEvents) {
      const dateKey = event.startDate.toISOString().split('T')[0];
      const issues = dayIssues.get(dateKey!) || [];

      if (event.hasConflict && event.conflictReason) {
        issues.push(event.conflictReason);
      }
      if (event.requiresAction && event.actionDescription) {
        issues.push(event.actionDescription);
      }

      dayIssues.set(dateKey!, issues);
    }

    return dayIssues;
  }

  /**
   * Resolve a conflict
   */
  async resolveConflict(eventId: string, householdId: string): Promise<void> {
    await this.prisma.familyEvent.update({
      where: { id: eventId, householdId },
      data: {
        conflictResolvedAt: new Date(),
        hasConflict: false,
      },
    });
  }

  /**
   * Mark action as completed
   */
  async completeAction(eventId: string, householdId: string): Promise<void> {
    await this.prisma.familyEvent.update({
      where: { id: eventId, householdId },
      data: {
        actionCompletedAt: new Date(),
        requiresAction: false,
      },
    });
  }
}
