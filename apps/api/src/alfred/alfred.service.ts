import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { HomeHealthService } from '../home-health/home-health.service';
import { BillToolsService, billToolDefinitions } from './tools/bill-tools';
import { MaintenanceResearchService } from '../maintenance/maintenance-research.service';
import Anthropic from '@anthropic-ai/sdk';

interface ConversationMessage {
  role: 'user' | 'assistant';
  content: string;
}

interface ActionTaken {
  type: string;
  description: string;
  entityId?: string;
}

interface ProactiveSuggestion {
  id: string;
  type: 'MISSING_DATA' | 'MAINTENANCE_DUE' | 'SEASONAL' | 'OPTIMIZATION' | 'SAFETY';
  priority: number;
  message: string;
  quickActions?: string[];
}

interface AlfredResponse {
  message: string;
  actions?: ActionTaken[];
  suggestions?: string[];
  proactivePrompts?: ProactiveSuggestion[];
}

interface HouseholdContext {
  household: any;
  homeProfile: any;
  members: any[];
  familyMembers: any[];
  pets: any[];
  vehicles: any[];
  systems: any[];
  vendors: any[];
  billAccounts: any[];
  maintenanceTasks: any[];
  healthScore: any;
  season: string;
  pendingPrompts: ProactiveSuggestion[];
}

@Injectable()
export class AlfredService {
  private readonly logger = new Logger(AlfredService.name);
  private anthropic: Anthropic;

  constructor(
    private prisma: PrismaService,
    private homeHealthService: HomeHealthService,
    private billToolsService: BillToolsService,
    private maintenanceResearchService: MaintenanceResearchService,
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

  /**
   * Get or create the Alfred chat thread for a user
   */
  private async getOrCreateThread(userId: string, householdId: string) {
    let thread = await this.prisma.conciergeThread.findUnique({
      where: { householdId_userId: { householdId, userId } },
    });

    if (!thread) {
      thread = await this.prisma.conciergeThread.create({
        data: {
          householdId,
          userId,
          title: 'Alfred Chat',
          isActive: true,
        },
      });
    }

    return thread;
  }

  /**
   * Main chat endpoint - the heart of Alfred
   */
  async chat(
    userId: string,
    householdId: string,
    message: string,
    conversationHistory: ConversationMessage[] = [],
  ): Promise<AlfredResponse> {
    // 1. Get or create the conversation thread
    const thread = await this.getOrCreateThread(userId, householdId);

    // 2. Load complete household context
    const context = await this.loadHouseholdContext(householdId);

    // 3. Build the system prompt with all household knowledge
    const systemPrompt = this.buildSystemPrompt(context);

    // 4. Load recent conversation history from DB if none provided
    let history = conversationHistory;
    if (history.length === 0) {
      const dbMessages = await this.prisma.conciergeMessage.findMany({
        where: { threadId: thread.id },
        orderBy: { createdAt: 'desc' },
        take: 20,
      });
      history = dbMessages.reverse().map((m) => ({
        role: m.role as 'user' | 'assistant',
        content: m.content,
      }));
    }

    // 5. Build messages array
    const messages: Anthropic.MessageParam[] = [
      ...history.map((m) => ({
        role: m.role as 'user' | 'assistant',
        content: m.content,
      })),
      { role: 'user', content: message },
    ];

    // Save user message to DB
    await this.prisma.conciergeMessage.create({
      data: {
        threadId: thread.id,
        role: 'user',
        content: message,
      },
    });

    try {
      // 4. Call Claude with tool use enabled
      const response = await this.anthropic.messages.create({
        model: 'claude-sonnet-4-20250514',
        max_tokens: 2048,
        system: systemPrompt,
        tools: this.getTools(),
        messages,
      });

      // 5. Process response and execute any tool calls
      const actions: ActionTaken[] = [];
      let responseText = '';

      for (const block of response.content) {
        if (block.type === 'text') {
          responseText += block.text;
        } else if (block.type === 'tool_use') {
          const action = await this.executeToolCall(block, householdId, userId);
          if (action) {
            actions.push(action);
          }
        }
      }

      // 6. If there were tool calls, get Claude's final response
      if (response.stop_reason === 'tool_use') {
        const toolUseBlocks = response.content.filter(
          (b): b is Anthropic.ToolUseBlock => b.type === 'tool_use',
        );
        const toolResults = actions.map((a, i) => ({
          type: 'tool_result' as const,
          tool_use_id: toolUseBlocks[i]?.id || `tool_${i}`,
          content: a.description.startsWith('Failed to execute')
            ? `Error: ${a.description}`
            : `Successfully ${a.description}`,
          is_error: a.description.startsWith('Failed to execute'),
        }));

        const followUp = await this.anthropic.messages.create({
          model: 'claude-sonnet-4-20250514',
          max_tokens: 1024,
          system: systemPrompt,
          messages: [
            ...messages,
            { role: 'assistant', content: response.content },
            { role: 'user', content: toolResults },
          ],
        });

        for (const block of followUp.content) {
          if (block.type === 'text') {
            responseText = block.text;
          }
        }
      }

      // Save assistant response to DB
      await this.prisma.conciergeMessage.create({
        data: {
          threadId: thread.id,
          role: 'assistant',
          content: responseText,
          aiModel: 'claude-sonnet-4-20250514',
        },
      });

      // Update thread last message timestamp
      await this.prisma.conciergeThread.update({
        where: { id: thread.id },
        data: { lastMessageAt: new Date() },
      });

      return {
        message: responseText,
        actions: actions.length > 0 ? actions : undefined,
        suggestions: this.generateSuggestions(context),
        proactivePrompts: context.pendingPrompts.slice(0, 3),
      };
    } catch (error) {
      this.logger.error('Alfred chat error:', error);
      return {
        message:
          "I'm having trouble connecting right now. Please try again in a moment.",
      };
    }
  }

  /**
   * Load ALL household data for comprehensive context
   */
  private async loadHouseholdContext(
    householdId: string,
  ): Promise<HouseholdContext> {
    try {
      const household = await this.prisma.household.findUnique({
        where: { id: householdId },
        include: {
          homeProfile: true,
          members: {
            include: {
              user: {
                select: {
                  id: true,
                  firstName: true,
                  lastName: true,
                  email: true,
                },
              },
            },
          },
        },
      });

      if (!household) {
        throw new Error(`Household ${householdId} not found`);
      }

      // Load all related data in parallel for performance
      const [
        familyMembers,
        pets,
        vehicles,
        systems,
        householdVendors,
        billAccounts,
        maintenanceTasks,
        healthScore,
      ] = await Promise.all([
        this.prisma.familyMember
          .findMany({ where: { householdId, isActive: true } })
          .catch(() => []),
        this.prisma.pet
          .findMany({ where: { householdId, isActive: true } })
          .catch(() => []),
        this.prisma.vehicle
          .findMany({ where: { householdId, isActive: true } })
          .catch(() => []),
        this.prisma.homeSystem
          .findMany({
            where: { householdId, isActive: true },
            include: {
              serviceHistory: { take: 3, orderBy: { serviceDate: 'desc' } },
            },
          })
          .catch(() => []),
        this.prisma.householdVendor
          .findMany({
            where: { householdId },
            include: { vendor: true },
          })
          .catch(() => []),
        this.prisma.billAccount
          .findMany({
            where: { householdId, isActive: true },
            include: { vendor: true },
          })
          .catch(() => []),
        this.prisma.maintenanceTask
          .findMany({
            where: { householdId },
            orderBy: { dueDate: 'asc' },
          })
          .catch(() => []),
        this.homeHealthService.calculateHealthScore(householdId).catch(() => null),
      ]);

      // Extract vendors from household-vendor relationships
      const vendors = householdVendors.map((hv: any) => ({
        ...hv.vendor,
        isFavorite: hv.isFavorite,
        notes: hv.notes,
      }));

      // Get current season
      const month = new Date().getMonth();
      const season =
        month >= 2 && month <= 4
          ? 'spring'
          : month >= 5 && month <= 7
            ? 'summer'
            : month >= 8 && month <= 10
              ? 'fall'
              : 'winter';

      // Generate proactive prompts based on gaps
      const pendingPrompts = this.generateProactivePrompts({
        household,
        systems,
        vendors,
        billAccounts,
        maintenanceTasks,
        pets,
        vehicles,
      });

      return {
        household,
        homeProfile: household.homeProfile,
        members: household.members,
        familyMembers,
        pets,
        vehicles,
        systems,
        vendors,
        billAccounts,
        maintenanceTasks,
        healthScore,
        season,
        pendingPrompts,
      };
    } catch (error) {
      this.logger.warn('Failed to load household context:', error);
      // Return minimal context
      return {
        household: null,
        homeProfile: null,
        members: [],
        familyMembers: [],
        pets: [],
        vehicles: [],
        systems: [],
        vendors: [],
        billAccounts: [],
        maintenanceTasks: [],
        healthScore: null,
        season: 'unknown',
        pendingPrompts: [],
      };
    }
  }

  /**
   * Build comprehensive system prompt with all household knowledge
   */
  private buildSystemPrompt(context: HouseholdContext): string {
    const {
      household,
      homeProfile,
      members,
      familyMembers,
      pets,
      vehicles,
      systems,
      vendors,
      billAccounts,
      maintenanceTasks,
      healthScore,
      season,
      pendingPrompts,
    } = context;

    const today = new Date().toLocaleDateString('en-US', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    });

    // Build members list
    const membersStr =
      members.length > 0
        ? members
            .map(
              (m: any) =>
                `- ${m.user?.firstName || 'Unknown'} ${m.user?.lastName || ''} (${m.role})`,
            )
            .join('\n')
        : 'None on file';

    // Build family members (non-user)
    const familyStr =
      familyMembers.length > 0
        ? familyMembers
            .map((m: any) => {
              const age = m.birthdate
                ? Math.floor(
                    (Date.now() - new Date(m.birthdate).getTime()) /
                      (365.25 * 24 * 60 * 60 * 1000),
                  )
                : null;
              return `- ${m.firstName} ${m.lastName || ''} (${m.type})${age !== null ? `, ${age} years old` : ''}${m.relationship ? ` - ${m.relationship}` : ''}`;
            })
            .join('\n')
        : '';

    // Build pets list
    const petsStr =
      pets.length > 0
        ? pets
            .map((p: any) => {
              const age = p.birthday
                ? Math.floor(
                    (Date.now() - new Date(p.birthday).getTime()) /
                      (365.25 * 24 * 60 * 60 * 1000),
                  )
                : null;
              return `- ${p.name}: ${p.breed || p.type}${age !== null ? `, ${age} years old` : ''}`;
            })
            .join('\n')
        : 'No pets on file';

    // Build vehicles list
    const vehiclesStr =
      vehicles.length > 0
        ? vehicles
            .map(
              (v: any) =>
                `- ${v.year} ${v.make} ${v.model}${v.name ? ` "${v.name}"` : ''}${v.hasLoan ? ' (has loan)' : ' (paid off)'}`,
            )
            .join('\n')
        : 'No vehicles on file';

    // Build systems list
    const systemsStr =
      systems.length > 0
        ? systems
            .map((s: any) => {
              const details = [s.brand, s.model].filter(Boolean).join(' ');
              const lastService = s.serviceHistory?.[0]?.serviceDate
                ? `Last serviced: ${new Date(s.serviceHistory[0].serviceDate).toLocaleDateString()}`
                : s.lastMaintenanceDate
                  ? `Last maintained: ${new Date(s.lastMaintenanceDate).toLocaleDateString()}`
                  : 'No service history';
              return `- ${s.name} (${s.type}): ${details || 'Details unknown'}. ${lastService}`;
            })
            .join('\n')
        : 'No systems on file';

    // Build vendors list
    const vendorsStr =
      vendors.length > 0
        ? vendors
            .map(
              (v: any) =>
                `- ${v.displayName} (${v.category})${v.notes ? ` - Note: ${v.notes}` : ''}`,
            )
            .join('\n')
        : 'No vendors on file';

    // Build bills list
    const billsStr =
      billAccounts.length > 0
        ? billAccounts
            .map(
              (b: any) =>
                `- ${b.nickname}: ${b.vendor?.displayName || 'Unknown vendor'} (${b.category}) - ${b.billingFrequency}${b.typicalAmount ? `, ~$${b.typicalAmount}` : ''}`,
            )
            .join('\n')
        : 'No bills being tracked';

    // Build maintenance tasks
    const pendingTasks = maintenanceTasks.filter(
      (t: any) => t.status === 'PENDING' || t.status === 'OVERDUE',
    );
    const maintenanceStr =
      pendingTasks.length > 0
        ? pendingTasks
            .slice(0, 5)
            .map(
              (t: any) =>
                `- ${t.title}${t.dueDate ? ` - Due: ${new Date(t.dueDate).toLocaleDateString()}` : ''}${t.status === 'OVERDUE' ? ' [OVERDUE]' : ''}`,
            )
            .join('\n')
        : 'No upcoming maintenance scheduled';

    // Build health score section
    const healthStr = healthScore
      ? `Home Health Score: ${healthScore.score}/100 (${healthScore.grade})
Top Recommendations: ${healthScore.recommendations?.slice(0, 3).join(', ') || 'None'}`
      : 'Health score not available';

    // Seasonal tips
    const seasonalTips = this.getSeasonalTips(season);

    // Proactive items
    const proactiveStr =
      pendingPrompts.length > 0
        ? pendingPrompts
            .slice(0, 5)
            .map((p) => `- [${p.type}] ${p.message}`)
            .join('\n')
        : 'None at this time';

    return `You are Alfred, the AI Home Manager for ${household?.name || 'this household'}. Today is ${today}.

## YOUR PERSONALITY
You are modeled after Batman's Alfred Pennyworth - distinguished, helpful, proactive, and always looking out for the family's best interests. You are:
- Knowledgeable about everything in this household
- Proactive in identifying gaps and suggesting improvements
- Helpful in finding better rates, vendors, and services
- Action-oriented - you can add systems, schedule maintenance, and manage the home
- Warm but professional, with occasional dry wit

## THIS HOUSEHOLD

### Property
Address: ${homeProfile?.addressLine1 || 'Not set'}${homeProfile?.city ? `, ${homeProfile.city}` : ''}${homeProfile?.state ? `, ${homeProfile.state}` : ''} ${homeProfile?.postalCode || ''}
Type: ${homeProfile?.propertyType || 'Unknown'}
${homeProfile?.bedrooms ? `Bedrooms: ${homeProfile.bedrooms}` : ''}
${homeProfile?.bathrooms ? `Bathrooms: ${homeProfile.bathrooms}` : ''}
${homeProfile?.yearBuilt ? `Year Built: ${homeProfile.yearBuilt}` : ''}
${homeProfile?.squareFeet ? `Square Feet: ${homeProfile.squareFeet}` : ''}

### Household Members (App Users)
${membersStr}

### Family Members (Additional)
${familyStr || 'None on file'}

### Pets
${petsStr}

### Vehicles
${vehiclesStr}

### Home Systems & Appliances
${systemsStr}

### Vendors & Service Providers
${vendorsStr}

### Bills Being Tracked
${billsStr}

### Upcoming Maintenance
${maintenanceStr}

### ${healthStr}

## CURRENT SEASON: ${season.toUpperCase()}
${seasonalTips}

## PROACTIVE ITEMS TO MENTION (when relevant)
${proactiveStr}

## YOUR CAPABILITIES

You can use tools to:

### Bill Tracking & Service Requests
1. **get_upcoming_bills** - Get bills due in the next few days
2. **get_bill_summary** - Get an overview of all bills and spending
3. **get_pending_approvals** - See items awaiting approval
4. **find_savings** - Find savings opportunities (refinancing, rate optimization, subscriptions, insurance bundling)
5. **request_service** - Request Haven team to negotiate rates, dispute charges, find vendors, schedule service, or research something

IMPORTANT: You do NOT handle payments or autopay. If a user asks about paying a bill, setting up automatic payments, or using a Haven card, let them know that bill payment features are coming soon. For now, you can help them track bills, find better rates, dispute charges, schedule service, and find vendors.

### Savings & Rate Intelligence
When users ask about saving money, reducing bills, or finding better rates, USE the find_savings tool. It analyzes:
- **Refinancing**: Loans/mortgages where current rate exceeds market rate
- **Rate optimization**: Spending categories above local median costs
- **Subscription audit**: Lists all active subscriptions for review
- **Insurance bundling**: Identifies multi-provider insurance that could be bundled for savings

### Home Management
11. **add_home_system** - Add a new appliance or system (refrigerator, furnace, etc.)
12. **update_home_system** - Update details on an existing system
13. **add_vendor** - Add a new service provider
14. **schedule_maintenance** - Create a maintenance task/reminder
15. **research_and_add_system** - Research and add ANY home system with full maintenance program (USE THIS!)
16. **coordinate_vendor_for_maintenance** - Find and coordinate a vendor for maintenance (USE THIS when user needs service!)

## PROACTIVE SYSTEM DETECTION - CRITICAL!

When a user mentions ANY of these things, IMMEDIATELY use the research_and_add_system tool to create a full maintenance program:

**HOME SYSTEMS:**
- "I have well water" / "we're on a well" -> research well water system
- "I have septic" / "septic system" / "septic tank" -> research septic system
- "I have an oil tank" / "oil heat" / "we use oil" -> research oil tank/heating
- "propane tank" / "propane heat" -> research propane system
- "generator" / "backup generator" / "Generac" -> research generator
- "solar panels" / "solar system" -> research solar panels
- "pool" / "swimming pool" -> research pool maintenance
- "hot tub" / "spa" / "jacuzzi" -> research hot tub maintenance

**HVAC:**
- Any furnace mention (brand/model if given) -> research furnace
- Any AC/air conditioner mention -> research AC system
- "heat pump" -> research heat pump
- "boiler" -> research boiler
- "mini split" -> research mini split system
- Any thermostat (Nest, Ecobee, Honeywell) -> research smart thermostat

**WATER:**
- "water heater" + brand/type -> research water heater
- "tankless water heater" -> research tankless system
- "water softener" -> research water softener
- "water filtration" / "whole house filter" / "reverse osmosis" -> research filtration
- "sump pump" -> research sump pump

**APPLIANCES:**
- Any refrigerator + brand/model -> research refrigerator
- Any dishwasher mention -> research dishwasher
- Any washer/dryer mention -> research washer/dryer
- "garbage disposal" -> research disposal
- Range/oven/stove -> research cooking appliances

**EXTERIOR:**
- "roof" + age/material -> research roof maintenance
- "gutters" -> research gutter maintenance
- "chimney" -> research chimney maintenance
- "deck" -> research deck maintenance
- "driveway" + material (asphalt/concrete) -> research driveway

**SAFETY:**
- "smoke detectors" -> research smoke detector maintenance
- "CO detectors" -> research CO detector maintenance
- "fire extinguisher" -> research fire extinguisher maintenance
- "radon system" / "radon mitigation" -> research radon system
- "security system" + brand -> research security system

The goal is: EVERY system the user mentions should trigger automatic research and task creation.
Never just acknowledge - always research and create the maintenance program.

## VENDOR COORDINATION - CRITICAL!

When a user needs maintenance or service:
1. **Always offer to coordinate** - "I can get your [vendor] to handle this"
2. **Use coordinate_vendor_for_maintenance** when user says things like:
   - "I need my furnace serviced" -> coordinate HVAC vendor
   - "Can you get someone to fix..." -> coordinate relevant vendor
   - "Who handles our pool?" -> look up POOL vendor
   - "The AC isn't working" -> coordinate HVAC vendor (URGENT)
   - "We need the gutters cleaned" -> coordinate a vendor
3. **If no vendor on file** - offer to add one with add_vendor, or say the team will find one
4. **Match vendors to systems** - link vendors to the systems they maintain

## IMPORTANT BEHAVIORS

1. **Be specific and helpful** - Reference actual data from the household
2. **Ask follow-up questions** - When information is incomplete, ask for details
3. **Be proactive** - Mention relevant gaps or upcoming maintenance when appropriate
4. **Take action** - When the user wants to add or update something, use your tools
5. **Zone awareness** - When discussing a zone (kitchen, HVAC, etc.), mention what's missing
6. **Seasonal awareness** - It's ${season}, mention relevant seasonal maintenance
7. **Auto-research systems** - When user mentions ANY home system, USE research_and_add_system tool
8. **Coordinate vendors** - When user needs service, USE coordinate_vendor_for_maintenance tool

## ZONE CHECKLIST (for reference)

**Kitchen**: Refrigerator, Oven/Range, Dishwasher, Microwave, Garbage Disposal, Range Hood
**Laundry**: Washer, Dryer, Utility Sink
**HVAC**: Furnace/Boiler, AC, Heat Pump, Thermostat, Humidifier, Air Filters
**Water**: Water Heater, Water Softener, Well Pump (if well), Sump Pump, Water Filtration
**Electrical**: Main Panel, Generator, Solar, EV Charger
**Exterior**: Roof, Gutters, Siding, Deck/Patio, Driveway, Fence, Irrigation, Pool
**Safety**: Smoke Detectors, CO Detectors, Fire Extinguishers, Security System
**Garage**: Garage Door Opener, Tools/Equipment

When the user asks about a zone, check what they have vs. what's common for that zone.
`;
  }

  /**
   * Get seasonal maintenance tips
   */
  private getSeasonalTips(season: string): string {
    const tips: Record<string, string> = {
      winter: `Winter priorities: Furnace service, pipe insulation, generator testing, snow removal prep, chimney cleaning before use`,
      spring: `Spring priorities: AC tune-up, gutter cleaning, lawn equipment service, exterior inspection, window cleaning`,
      summer: `Summer priorities: AC maintenance, pest control, irrigation check, deck/patio maintenance, pool care (if applicable)`,
      fall: `Fall priorities: Furnace service before heating season, chimney cleaning, gutter cleaning, winterization, generator testing`,
      unknown: ``,
    };
    return tips[season] || '';
  }

  /**
   * Generate proactive suggestions based on gaps in data
   */
  private generateProactivePrompts(data: {
    household: any;
    systems: any[];
    vendors: any[];
    billAccounts: any[];
    maintenanceTasks: any[];
    pets: any[];
    vehicles: any[];
  }): ProactiveSuggestion[] {
    const prompts: ProactiveSuggestion[] = [];

    // Check for incomplete systems
    for (const system of data.systems) {
      const missingFields: string[] = [];
      if (!system.brand) missingFields.push('brand');
      if (!system.model) missingFields.push('model');
      if (!system.serialNumber) missingFields.push('serial number');

      if (missingFields.length >= 2) {
        prompts.push({
          id: `system-${system.id}`,
          type: 'MISSING_DATA',
          priority: 6,
          message: `Your ${system.name} is missing ${missingFields.join(', ')}. Having this info helps with maintenance and repairs.`,
          quickActions: ['Add details now', 'Take a photo', 'Remind me later'],
        });
      }
    }

    // Check for overdue maintenance
    const now = new Date();
    for (const task of data.maintenanceTasks) {
      if (
        (task.status === 'PENDING' || task.status === 'OVERDUE') &&
        task.dueDate &&
        new Date(task.dueDate) < now
      ) {
        prompts.push({
          id: `maint-${task.id}`,
          type: 'MAINTENANCE_DUE',
          priority: 8,
          message: `${task.title} is overdue (was due ${new Date(task.dueDate).toLocaleDateString()})`,
          quickActions: ['Schedule now', 'Mark complete', 'Snooze 1 week'],
        });
      }
    }

    // Check for common missing systems
    const systemTypes = data.systems.map((s: any) => s.type);

    if (!systemTypes.includes('SMOKE_DETECTOR')) {
      prompts.push({
        id: 'safety-smoke',
        type: 'SAFETY',
        priority: 10,
        message: `I don't have smoke detectors on file. Do you have them? (This is important for safety tracking)`,
        quickActions: ['Add smoke detectors', 'Not applicable'],
      });
    }

    // Seasonal prompts
    const month = new Date().getMonth();
    if (month >= 8 && month <= 10) {
      // Fall
      const furnace = data.systems.find((s: any) => s.type === 'FURNACE');
      if (
        furnace &&
        !furnace.serviceHistory?.some((h: any) => {
          const serviceDate = new Date(h.serviceDate);
          return serviceDate.getFullYear() === now.getFullYear();
        })
      ) {
        prompts.push({
          id: 'seasonal-furnace',
          type: 'SEASONAL',
          priority: 7,
          message: `Winter is coming! Your furnace hasn't been serviced this year. Want me to help schedule it?`,
          quickActions: ['Find HVAC techs', 'Schedule reminder', 'Already done'],
        });
      }
    }

    // Check for pet vet info
    for (const pet of data.pets) {
      if (!pet.vetClinicName && !pet.vetClinicPhone) {
        prompts.push({
          id: `pet-${pet.id}`,
          type: 'MISSING_DATA',
          priority: 5,
          message: `${pet.name} doesn't have vet information on file. This is helpful in emergencies.`,
          quickActions: ['Add vet info', 'Remind me later'],
        });
      }
    }

    return prompts.sort((a, b) => b.priority - a.priority);
  }

  /**
   * Define available tools for Claude
   */
  private getTools(): Anthropic.Tool[] {
    // Get bill tools from BillToolsService
    const billTools = this.billToolsService.getAnthropicTools();

    return [
      // Bill tools for payment management
      ...billTools,
      {
        name: 'add_home_system',
        description:
          'Add a new home system or appliance to the household inventory',
        input_schema: {
          type: 'object' as const,
          properties: {
            type: {
              type: 'string',
              description:
                'Type of system (e.g., FURNACE, WATER_HEATER, REFRIGERATOR, DISHWASHER, GENERATOR, FIREPLACE)',
            },
            name: {
              type: 'string',
              description: 'Display name for the system',
            },
            brand: { type: 'string', description: 'Brand/manufacturer' },
            model: { type: 'string', description: 'Model number' },
            serialNumber: { type: 'string', description: 'Serial number' },
            location: {
              type: 'string',
              description: 'Location in home (e.g., Kitchen, Basement)',
            },
            notes: { type: 'string', description: 'Additional notes' },
          },
          required: ['type', 'name'],
        },
      },
      {
        name: 'update_home_system',
        description: 'Update an existing home system with new information',
        input_schema: {
          type: 'object' as const,
          properties: {
            systemId: {
              type: 'string',
              description: 'ID of the system to update',
            },
            brand: { type: 'string' },
            model: { type: 'string' },
            serialNumber: { type: 'string' },
            notes: { type: 'string' },
            lastServiceDate: {
              type: 'string',
              description: 'Date of last service (ISO format)',
            },
          },
          required: ['systemId'],
        },
      },
      {
        name: 'add_vendor',
        description: 'Add a new vendor or service provider to the household',
        input_schema: {
          type: 'object' as const,
          properties: {
            displayName: { type: 'string', description: 'Name of the vendor' },
            category: {
              type: 'string',
              description:
                'Category (e.g., ELECTRIC, CLEANING, LANDSCAPING, PLUMBING, HVAC)',
            },
            phone: { type: 'string' },
            email: { type: 'string' },
            notes: { type: 'string' },
          },
          required: ['displayName', 'category'],
        },
      },
      {
        name: 'schedule_maintenance',
        description: 'Create a new maintenance task or reminder',
        input_schema: {
          type: 'object' as const,
          properties: {
            title: {
              type: 'string',
              description: 'Title of the maintenance task',
            },
            description: { type: 'string' },
            category: {
              type: 'string',
              description:
                'Category (e.g., HVAC, PLUMBING, ELECTRICAL, EXTERIOR, SAFETY, GENERAL)',
            },
            dueDate: { type: 'string', description: 'Due date (ISO format)' },
            priority: {
              type: 'string',
              enum: ['LOW', 'MEDIUM', 'HIGH', 'URGENT'],
            },
          },
          required: ['title', 'category'],
        },
      },
      {
        name: 'research_and_add_system',
        description: `Research and add a home system, appliance, or equipment with full maintenance program.
Use this when user mentions they have any home system, appliance, or equipment.
Examples:
- "I have well water" -> research well water system maintenance
- "We have a Carrier 59MN7 furnace" -> research that specific furnace model
- "I have an oil tank" -> research oil tank maintenance
- "We just got a new Samsung refrigerator model RF28R7551SR" -> research that model
- "I have a propane tank" -> research propane system maintenance
- "We have a septic system" -> research septic maintenance
- "I have a Generac generator" -> research generator maintenance
This will create the system AND all recommended maintenance tasks automatically.`,
        input_schema: {
          type: 'object' as const,
          properties: {
            name: {
              type: 'string',
              description: 'Name of the system (e.g., "Well Water System", "Main Furnace", "Kitchen Refrigerator")',
            },
            systemType: {
              type: 'string',
              description: 'Type of system (e.g., "well", "furnace", "refrigerator", "septic", "oil_tank", "propane", "generator", "pool", "hvac", "water_heater")',
            },
            brand: {
              type: 'string',
              description: 'Brand name if known (e.g., "Carrier", "Samsung", "Generac")',
            },
            model: {
              type: 'string',
              description: 'Model name if known',
            },
            modelNumber: {
              type: 'string',
              description: 'Model number if known (e.g., "59MN7", "RF28R7551SR")',
            },
            fuelType: {
              type: 'string',
              description: 'Fuel type for HVAC/heating (oil, natural_gas, propane, electric)',
            },
            capacity: {
              type: 'string',
              description: 'Capacity if relevant (e.g., "275 gallon", "100,000 BTU", "22kW")',
            },
            location: {
              type: 'string',
              description: 'Location in home (e.g., "Basement", "Garage", "Kitchen")',
            },
            installedDate: {
              type: 'string',
              description: 'When installed (ISO date or year)',
            },
            notes: {
              type: 'string',
              description: 'Any additional notes about the system',
            },
          },
          required: ['name', 'systemType'],
        },
      },
      {
        name: 'coordinate_vendor_for_maintenance',
        description: `Find and coordinate a vendor for a home maintenance task.
Use this when:
- User needs maintenance done on a home system (e.g., "I need my furnace serviced")
- A maintenance task is overdue and needs a vendor
- User wants to schedule service with a specific vendor
- User asks "who handles my [system]?" or "can you get someone to fix [thing]?"
This will find vendors that match the system type and create a service request.`,
        input_schema: {
          type: 'object' as const,
          properties: {
            systemType: {
              type: 'string',
              description: 'Type of system needing service (e.g., HVAC, PLUMBING, ELECTRICAL, LANDSCAPING)',
            },
            systemId: {
              type: 'string',
              description: 'ID of the specific home system (if known)',
            },
            description: {
              type: 'string',
              description: 'Description of what needs to be done',
            },
            priority: {
              type: 'string',
              enum: ['LOW', 'MEDIUM', 'HIGH', 'URGENT'],
              description: 'How urgent is the service needed',
            },
            preferredVendorId: {
              type: 'string',
              description: 'ID of a preferred vendor (if user specified one)',
            },
          },
          required: ['systemType', 'description'],
        },
      },
    ];
  }

  /**
   * Execute a tool call from Claude
   */
  private async executeToolCall(
    toolCall: Anthropic.ToolUseBlock,
    householdId: string,
    userId: string,
  ): Promise<ActionTaken | null> {
    const { name, input, id } = toolCall;
    const params = input as Record<string, any>;

    this.logger.log(`Executing tool: ${name} with params:`, params);

    try {
      // Check if this is a bill tool
      if (BillToolsService.isBillTool(name)) {
        const result = await this.billToolsService.executeTool(
          name,
          params,
          householdId,
          userId,
        );
        return {
          type: name.toUpperCase(),
          description: result.message || `Executed ${name}`,
          entityId: result.bill?.id || result.paymentId || undefined,
        };
      }

      switch (name) {
        case 'add_home_system':
          const system = await this.prisma.homeSystem.create({
            data: {
              householdId,
              type: params.type,
              name: params.name,
              brand: params.brand,
              model: params.model,
              serialNumber: params.serialNumber,
              location: params.location,
              notes: params.notes,
              isActive: true,
            },
          });
          return {
            type: 'ADD_SYSTEM',
            description: `Added ${params.name} (${params.type}) to your home`,
            entityId: system.id,
          };

        case 'update_home_system':
          await this.prisma.homeSystem.update({
            where: { id: params.systemId },
            data: {
              brand: params.brand,
              model: params.model,
              serialNumber: params.serialNumber,
              notes: params.notes,
              lastMaintenanceDate: params.lastServiceDate
                ? new Date(params.lastServiceDate)
                : undefined,
            },
          });
          return {
            type: 'UPDATE_SYSTEM',
            description: `Updated system information`,
            entityId: params.systemId,
          };

        case 'add_vendor':
          // First create the vendor
          const vendor = await this.prisma.vendor.create({
            data: {
              householdId, // Private vendor for this household
              displayName: params.displayName,
              category: params.category,
              phone: params.phone,
              email: params.email,
              isLocal: true,
              isActive: true,
            },
          });
          // Then link to household
          await this.prisma.householdVendor.create({
            data: {
              householdId,
              vendorId: vendor.id,
              notes: params.notes,
              isFavorite: false,
            },
          });
          return {
            type: 'ADD_VENDOR',
            description: `Added ${params.displayName} as a vendor`,
            entityId: vendor.id,
          };

        case 'schedule_maintenance':
          const task = await this.prisma.maintenanceTask.create({
            data: {
              householdId,
              title: params.title,
              description: params.description,
              category: params.category,
              dueDate: params.dueDate ? new Date(params.dueDate) : null,
              priority: params.priority || 'MEDIUM',
              status: 'PENDING',
            },
          });
          return {
            type: 'SCHEDULE_MAINTENANCE',
            description: `Scheduled: ${params.title}`,
            entityId: task.id,
          };

        case 'research_and_add_system':
          // Get household region from home profile
          const homeProfile = await this.prisma.homeProfile.findUnique({
            where: { householdId },
            select: { state: true },
          });

          const result = await this.maintenanceResearchService.createMaintenanceProgram(
            householdId,
            {
              name: params.name,
              type: params.systemType,
              brand: params.brand,
              model: params.model,
              modelNumber: params.modelNumber,
              fuelType: params.fuelType,
              capacity: params.capacity,
              location: params.location,
              installedDate: params.installedDate ? new Date(params.installedDate) : undefined,
              notes: params.notes,
            },
            homeProfile?.state,
          );

          return {
            type: 'RESEARCH_AND_ADD_SYSTEM',
            description: `Added ${result.system.name} with ${result.tasksCreated} maintenance tasks. ${result.research.systemSummary}`,
            entityId: result.system.id,
          };

        case 'coordinate_vendor_for_maintenance':
          // Map system types to vendor categories for matching
          const vendorCategoryMap: Record<string, string[]> = {
            'HVAC': ['HVAC', 'HEATING', 'COOLING', 'AIR_CONDITIONING'],
            'PLUMBING': ['PLUMBING', 'PLUMBER'],
            'ELECTRICAL': ['ELECTRIC', 'ELECTRICIAN', 'ELECTRICAL'],
            'LANDSCAPING': ['LAWN_LANDSCAPE', 'LANDSCAPING', 'LAWN'],
            'POOL': ['POOL_SERVICE', 'POOL'],
            'PEST': ['PEST_CONTROL', 'PEST'],
            'CLEANING': ['HOUSE_CLEANING', 'CLEANING'],
            'ROOFING': ['ROOFING', 'ROOF'],
            'APPLIANCE': ['APPLIANCE', 'APPLIANCE_REPAIR'],
            'GENERAL': ['HANDYMAN', 'GENERAL', 'OTHER'],
          };

          const matchCategories = vendorCategoryMap[params.systemType?.toUpperCase()] || [params.systemType?.toUpperCase(), 'OTHER'];

          // Find matching vendors for this household
          const matchingVendors = await this.prisma.householdVendor.findMany({
            where: {
              householdId,
              vendor: {
                OR: matchCategories.map(cat => ({ category: cat })),
                isActive: true,
              },
            },
            include: {
              vendor: { select: { id: true, displayName: true, category: true, phone: true, email: true } },
            },
          });

          // If user specified a preferred vendor, use that
          let selectedVendor = params.preferredVendorId
            ? matchingVendors.find(v => v.vendorId === params.preferredVendorId)
            : null;

          // Otherwise pick the first matching vendor (could be enhanced with ratings)
          if (!selectedVendor && matchingVendors.length > 0) {
            selectedVendor = matchingVendors[0];
          }

          // Link system to vendor if both exist
          if (params.systemId && selectedVendor) {
            await this.prisma.homeSystem.update({
              where: { id: params.systemId },
              data: { serviceVendorId: selectedVendor.vendor.id },
            }).catch(() => { /* System may not exist, that's OK */ });
          }

          // Create a service request for the vendor coordination
          const serviceReq = await this.prisma.serviceRequest.create({
            data: {
              householdId,
              createdById: userId,
              title: `${params.systemType} Service: ${params.description}`,
              description: `${params.description}${selectedVendor ? `\n\nPreferred vendor: ${selectedVendor.vendor.displayName} (${selectedVendor.vendor.phone || selectedVendor.vendor.email || 'no contact'})` : '\n\nNo matching vendor on file.'}`,
              status: 'SUBMITTED',
              priority: (params.priority || 'MEDIUM') as any,
              quickCategory: 'SCHEDULE',
            },
          });

          if (selectedVendor) {
            return {
              type: 'COORDINATE_VENDOR',
              description: `Found ${matchingVendors.length} vendor(s) for ${params.systemType}. Created service request with ${selectedVendor.vendor.displayName} (${selectedVendor.vendor.phone || selectedVendor.vendor.email || 'on file'}). Request #${serviceReq.id.slice(-6)}.${matchingVendors.length > 1 ? ` Other options: ${matchingVendors.slice(1, 3).map(v => v.vendor.displayName).join(', ')}.` : ''}`,
              entityId: serviceReq.id,
            };
          } else {
            return {
              type: 'COORDINATE_VENDOR',
              description: `No ${params.systemType} vendors on file yet. Created service request #${serviceReq.id.slice(-6)} - our team will find a qualified vendor for you. You can also add a vendor with the add_vendor tool.`,
              entityId: serviceReq.id,
            };
          }

        default:
          this.logger.warn(`Unknown tool: ${name}`);
          return null;
      }
    } catch (error) {
      this.logger.error(`Error executing tool ${name}:`, error);
      return {
        type: name.toUpperCase(),
        description: `Failed to execute ${name}: ${error instanceof Error ? error.message : 'Unknown error'}`,
      };
    }
  }

  /**
   * Generate context-aware suggestions
   */
  private generateSuggestions(context: HouseholdContext): string[] {
    const suggestions: string[] = [];
    const { healthScore, pendingPrompts, maintenanceTasks, season } = context;

    // Add proactive suggestions from gaps
    for (const prompt of pendingPrompts.slice(0, 2)) {
      if (prompt.type === 'MAINTENANCE_DUE') {
        suggestions.push(`Schedule ${prompt.message.split(' ')[0]}`);
      }
    }

    // Add health score recommendations
    if (healthScore?.recommendations?.length > 0) {
      suggestions.push(healthScore.recommendations[0]);
    }

    // Check for overdue tasks
    const overdueTasks = maintenanceTasks.filter(
      (t: any) => t.status === 'OVERDUE',
    );
    if (overdueTasks.length > 0) {
      suggestions.push(
        `Address ${overdueTasks.length} overdue task${overdueTasks.length > 1 ? 's' : ''}`,
      );
    }

    // Add common helpful suggestions
    suggestions.push('What maintenance is coming up?');
    suggestions.push('Help me add a new appliance');

    // Seasonal suggestion
    if (season === 'fall') {
      suggestions.push('Prepare home for winter');
    } else if (season === 'spring') {
      suggestions.push('Schedule spring maintenance');
    }

    return suggestions.slice(0, 5);
  }

  /**
   * Get dynamic suggestions based on household context
   */
  async getSuggestions(householdId: string): Promise<string[]> {
    try {
      const context = await this.loadHouseholdContext(householdId);
      return this.generateSuggestions(context);
    } catch (error) {
      this.logger.warn('Failed to get suggestions:', error);
      return [
        'What maintenance is due?',
        'Help me add a home system',
        "What's my home health score?",
      ];
    }
  }

  /**
   * Get conversation history from database
   */
  async getConversationHistory(userId: string, householdId: string, limit = 50) {
    const thread = await this.prisma.conciergeThread.findUnique({
      where: { householdId_userId: { householdId, userId } },
    });

    if (!thread) {
      return [];
    }

    const messages = await this.prisma.conciergeMessage.findMany({
      where: { threadId: thread.id },
      orderBy: { createdAt: 'asc' },
      take: limit,
    });

    return messages.map((m) => ({
      id: m.id,
      role: m.role === 'assistant' ? 'alfred' : 'user',
      content: m.content,
      timestamp: m.createdAt,
    }));
  }
}
