import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { HomeHealthService } from '../home-health/home-health.service';
import Anthropic from '@anthropic-ai/sdk';

interface ConversationMessage {
  role: 'user' | 'assistant';
  content: string;
}

interface AlfredAction {
  type: string;
  data: Record<string, any>;
  requiresConfirmation: boolean;
}

interface AlfredResponse {
  message: string;
  action?: AlfredAction;
  suggestions?: string[];
}

@Injectable()
export class AlfredService {
  private readonly logger = new Logger(AlfredService.name);
  private anthropic: Anthropic;

  constructor(
    private prisma: PrismaService,
    private homeHealthService: HomeHealthService,
  ) {
    if (!process.env.ANTHROPIC_API_KEY) {
      this.logger.warn(
        'ANTHROPIC_API_KEY not configured - Alfred AI features will not work',
      );
    }
    this.anthropic = new Anthropic({
      apiKey: process.env.ANTHROPIC_API_KEY,
    });
  }

  async chat(
    userId: string,
    householdId: string,
    message: string,
    conversationHistory: ConversationMessage[] = [],
  ): Promise<AlfredResponse> {
    const context = await this.getHouseholdContext(householdId);
    const systemPrompt = this.buildSystemPrompt(context);

    const messages = [
      ...conversationHistory.map((msg) => ({
        role: msg.role as 'user' | 'assistant',
        content: msg.content,
      })),
      { role: 'user' as const, content: message },
    ];

    try {
      const response = await this.anthropic.messages.create({
        model: 'claude-sonnet-4-20250514',
        max_tokens: 1024,
        system: systemPrompt,
        messages,
      });

      const assistantMessage =
        response.content[0].type === 'text' ? response.content[0].text : '';

      const { cleanMessage, action } =
        this.parseResponseForActions(assistantMessage);

      return {
        message: cleanMessage,
        action,
        suggestions: this.generateSuggestions(context),
      };
    } catch (error) {
      this.logger.error('Alfred chat error:', error);
      return {
        message:
          "I'm having trouble connecting right now. Please try again in a moment.",
      };
    }
  }

  private async getHouseholdContext(householdId: string) {
    try {
      const [
        household,
        allMaintenanceTasks,
        approvalRequests,
        documents,
        recentActivity,
        healthScore,
        homeSystems,
      ] = await Promise.all([
        this.prisma.household.findUnique({
          where: { id: householdId },
          include: {
            homeProfile: true,
            members: { include: { user: true } },
            vehicles: true,
            pets: true,
          },
        }),
        this.prisma.maintenanceTask.findMany({
          where: { householdId },
          orderBy: { dueDate: 'asc' },
        }),
        this.prisma.approvalRequest
          .findMany({
            where: { householdId, status: 'PENDING' },
            orderBy: { createdAt: 'desc' },
          })
          .catch(() => []),
        this.prisma.document.findMany({ where: { householdId } }).catch(() => []),
        this.prisma.activityLog
          .findMany({
            where: { householdId },
            orderBy: { createdAt: 'desc' },
            take: 20,
          })
          .catch(() => []),
        this.homeHealthService.calculateHealthScore(householdId).catch(() => null),
        this.prisma.homeSystem
          .findMany({
            where: { householdId, isActive: true },
            include: {
              maintenanceTasks: {
                where: { status: { not: 'COMPLETED' } },
                orderBy: { dueDate: 'asc' },
                take: 3,
              },
            },
            orderBy: { nextMaintenanceDate: 'asc' },
          })
          .catch(() => []),
      ]);

      // Categorize maintenance tasks
      const overdueTasks = allMaintenanceTasks.filter((t) => t.status === 'OVERDUE');
      const upcomingTasks = allMaintenanceTasks.filter(
        (t) => t.status === 'UPCOMING' || t.status === 'SCHEDULED' || t.status === 'DUE_SOON',
      );
      const completedTasks = allMaintenanceTasks.filter((t) => t.status === 'COMPLETED');

      // Get current month for seasonal awareness
      const currentMonth = new Date().getMonth() + 1;
      const season = this.getSeason(currentMonth);

      return {
        household,
        homeProfile: household?.homeProfile,
        members: household?.members || [],
        vehicles: household?.vehicles || [],
        pets: household?.pets || [],
        pendingApprovals: approvalRequests,
        overdueTasks,
        upcomingTasks,
        completedTasks,
        recentCompletedTasks: completedTasks.slice(0, 10),
        documents,
        healthScore,
        recentActivity,
        currentMonth,
        season,
        homeSystems,
      };
    } catch (error) {
      this.logger.warn('Failed to fetch household context:', error);
      return {
        household: null,
        homeProfile: null,
        members: [],
        vehicles: [],
        pets: [],
        pendingApprovals: [],
        overdueTasks: [],
        upcomingTasks: [],
        completedTasks: [],
        recentCompletedTasks: [],
        documents: [],
        healthScore: null,
        recentActivity: [],
        currentMonth: new Date().getMonth() + 1,
        season: 'unknown',
        homeSystems: [],
      };
    }
  }

  private getSeason(month: number): string {
    if ([12, 1, 2].includes(month)) return 'winter';
    if ([3, 4, 5].includes(month)) return 'spring';
    if ([6, 7, 8].includes(month)) return 'summer';
    return 'fall';
  }

  private buildSystemPrompt(context: any): string {
    const {
      household,
      homeProfile,
      members,
      vehicles,
      pets,
      pendingApprovals,
      overdueTasks,
      upcomingTasks,
      recentCompletedTasks,
      healthScore,
      season,
      homeSystems,
    } = context;

    // Build detailed property info
    const propertyInfo = homeProfile
      ? `
- Address: ${homeProfile.addressLine1 || 'Unknown'}${homeProfile.city ? `, ${homeProfile.city}` : ''}${homeProfile.state ? `, ${homeProfile.state}` : ''} ${homeProfile.postalCode || ''}
- Type: ${homeProfile.propertyType || 'Single Family Home'}
- Size: ${homeProfile.squareFeet || 'Unknown'} sq ft
- Bedrooms: ${homeProfile.bedrooms || 'Unknown'}, Bathrooms: ${homeProfile.bathrooms || 'Unknown'}
- Year Built: ${homeProfile.yearBuilt || 'Unknown'}
- Lot Size: ${homeProfile.lotSize ? homeProfile.lotSize + ' acres' : 'Unknown'}`
      : 'Property details not available';

    // Build family info
    const familyInfo =
      members.length > 0
        ? members
            .map((m: any) => `- ${m.user?.firstName || 'Unknown'} ${m.user?.lastName || ''} (${m.role})`)
            .join('\n')
        : 'No family members on file';

    // Build health score info
    const healthInfo = healthScore
      ? `
## Home Health Score: ${healthScore.score}/100 (${healthScore.grade})

### Positive Factors:
${healthScore.factors.filter((f: any) => f.status === 'positive').map((f: any) => `- ${f.description}`).join('\n') || 'None identified'}

### Areas Needing Attention:
${healthScore.factors.filter((f: any) => f.status === 'negative').map((f: any) => `- ${f.description}`).join('\n') || 'None - great job!'}

### Top Recommendations to Improve Score:
${healthScore.recommendations.map((r: string, i: number) => `${i + 1}. ${r}`).join('\n') || 'No recommendations - home is in great shape!'}`
      : 'Health score not available';

    // Build maintenance summary
    const maintenanceSummary = `
## Maintenance Status:
- Overdue Tasks: ${overdueTasks.length}${overdueTasks.length > 0 ? ` (${overdueTasks.slice(0, 3).map((t: any) => t.title).join(', ')})` : ''}
- Upcoming Tasks: ${upcomingTasks.length}${upcomingTasks.length > 0 ? ` (${upcomingTasks.slice(0, 3).map((t: any) => t.title).join(', ')})` : ''}
- Recently Completed: ${recentCompletedTasks.length > 0 ? recentCompletedTasks.slice(0, 3).map((t: any) => t.title).join(', ') : 'None recently'}`;

    // Build pending approvals summary
    const approvalsSummary =
      pendingApprovals.length > 0
        ? `
## Pending Approvals (${pendingApprovals.length}):
${pendingApprovals.slice(0, 5).map((a: any) => `- ${a.title}: $${a.amount || 0} (${a.priority || 'Normal'} priority)`).join('\n')}`
        : '## Pending Approvals: None';

    // Vehicles and pets
    const vehiclesInfo =
      vehicles.length > 0
        ? `\n## Vehicles:\n${vehicles.map((v: any) => `- ${v.year || ''} ${v.make || ''} ${v.model || ''}`).join('\n')}`
        : '';

    const petsInfo =
      pets.length > 0
        ? `\n## Pets:\n${pets.map((p: any) => `- ${p.name} (${p.species}${p.breed ? ', ' + p.breed : ''})`).join('\n')}`
        : '';

    // Build home systems info
    const systemsInfo =
      homeSystems?.length > 0
        ? `\n## Home Systems & Equipment (${homeSystems.length}):\n${homeSystems.map((s: any) => {
            const age = s.installedDate
              ? Math.floor((Date.now() - new Date(s.installedDate).getTime()) / (1000 * 60 * 60 * 24 * 365))
              : null;
            const ageStr = age !== null ? ` - ${age} years old` : '';
            const warrantyStr = s.warrantyExpires
              ? new Date(s.warrantyExpires) > new Date()
                ? ' (Under Warranty)'
                : ' (Warranty Expired)'
              : '';
            const nextService = s.nextMaintenanceDate
              ? ` - Next service: ${new Date(s.nextMaintenanceDate).toLocaleDateString()}`
              : '';
            const pendingTasks = s.maintenanceTasks?.length > 0
              ? ` - ${s.maintenanceTasks.length} pending task(s)`
              : '';
            return `- ${s.name}${s.brand ? ` (${s.brand}${s.model ? ' ' + s.model : ''})` : ''}${ageStr}${warrantyStr}${nextService}${pendingTasks}`;
          }).join('\n')}`
        : '\n## Home Systems & Equipment: None registered yet';

    // Seasonal awareness
    const seasonalTips = this.getSeasonalTips(season);

    return `You are Alfred, an AI Home Manager for Haven. You have COMPLETE knowledge of this homeowner's property and situation. Use this context to give personalized, specific advice.

## Your Personality
- Warm, professional, and proactive
- You know this home intimately and reference specific details
- You anticipate needs before they become problems
- You explain the "why" behind recommendations
- You're like a knowledgeable friend who happens to be an expert in home maintenance

## Your Capabilities
1. **Answer questions** about their specific home, maintenance history, equipment, and what's due
2. **Make recommendations** based on their actual situation and home health score
3. **Schedule vendors** for any home service
4. **Book handyman** for small tasks ($50/visit)
5. **Explain the home health score** and how to improve it
6. **Provide seasonal guidance** specific to their location and home
7. **Track home systems** - Know the age, warranty status, and maintenance needs of their HVAC, water heater, appliances, etc.

## Current Household: ${household?.name || 'Unknown'}

## Property Details:
${propertyInfo}

## Family Members:
${familyInfo}
${vehiclesInfo}
${petsInfo}
${systemsInfo}

${healthInfo}

${maintenanceSummary}

${approvalsSummary}

## Current Season: ${season.charAt(0).toUpperCase() + season.slice(1)}
${seasonalTips}

## How to Respond:
1. **Be specific** - Reference their actual tasks, property details, and situation
2. **Be proactive** - If they ask about one thing, mention related items they should know
3. **Explain impact** - Tell them how actions affect their home health score
4. **Prioritize** - Help them focus on what's most important first
5. **Offer next steps** - Always suggest what they can do right now

When suggesting actions, use: [ACTION:type:{"key":"value"}]
Types: schedule_vendor, book_handyman, create_task, mark_complete, get_quotes

Remember: You're not just answering questions - you're their trusted home advisor who knows their situation inside and out.`;
  }

  private getSeasonalTips(season: string): string {
    const tips: Record<string, string> = {
      winter: `### Winter Tips (Current):
- Ensure heating system is running efficiently
- Check for drafts and ice dams
- Keep walkways clear and safe
- Monitor pipes for freezing risk`,
      spring: `### Spring Tips (Current):
- Schedule AC tune-up before summer
- Clean gutters after winter debris
- Check roof for winter damage
- Start lawn care and landscaping`,
      summer: `### Summer Tips (Current):
- Ensure AC is running efficiently
- Check irrigation systems
- Inspect deck and outdoor structures
- Monitor humidity levels inside`,
      fall: `### Fall Tips (Current):
- Schedule heating system service
- Clean gutters before winter
- Winterize outdoor faucets and irrigation
- Check weatherstripping and insulation`,
    };
    return tips[season] || '';
  }

  private parseResponseForActions(response: string): {
    cleanMessage: string;
    action?: AlfredAction;
  } {
    const actionRegex = /\[ACTION:(\w+):(\{.*?\})\]/g;
    let action: AlfredAction | undefined;

    const match = actionRegex.exec(response);
    if (match) {
      try {
        action = {
          type: match[1],
          data: JSON.parse(match[2]),
          requiresConfirmation: ['schedule_vendor', 'book_handyman'].includes(
            match[1],
          ),
        };
      } catch (e) {
        this.logger.warn('Failed to parse action:', e);
      }
    }

    const cleanMessage = response.replace(actionRegex, '').trim();
    return { cleanMessage, action };
  }

  private generateSuggestions(context: any): string[] {
    const suggestions: string[] = [];
    const { healthScore, pendingApprovals, overdueTasks, upcomingTasks, season } = context;

    // Add health score recommendations first
    if (healthScore?.recommendations?.length > 0) {
      suggestions.push(...healthScore.recommendations.slice(0, 2));
    }

    // Add context-aware suggestions
    if (pendingApprovals?.length > 0) {
      suggestions.push(`Review ${pendingApprovals.length} pending approval${pendingApprovals.length > 1 ? 's' : ''}`);
    }

    if (overdueTasks?.length > 0) {
      suggestions.push(`Address ${overdueTasks.length} overdue task${overdueTasks.length > 1 ? 's' : ''}`);
    }

    // Seasonal suggestions
    if (season === 'fall') {
      suggestions.push('Prepare home for winter');
    } else if (season === 'spring') {
      suggestions.push('Schedule spring maintenance');
    }

    // General helpful suggestions
    if (suggestions.length < 3) {
      suggestions.push("What's my home health score?");
    }

    return suggestions.slice(0, 4);
  }

  async getConversationHistory(userId: string, limit = 50) {
    // Return empty for now - can implement conversation storage later
    return [];
  }
}
