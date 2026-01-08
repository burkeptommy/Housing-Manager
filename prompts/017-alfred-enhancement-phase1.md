# ALFRED AI ENHANCEMENT - PHASE 1 IMPLEMENTATION

## GOAL

Enhance Alfred to be a true AI Home Manager that:
1. Knows everything about the household (loads full context)
2. Answers detailed questions (payment history, maintenance schedules)
3. Proactively identifies gaps and asks smart follow-up questions
4. Can take actions (add systems, schedule maintenance) through conversation

---

## STEP 1: Examine Current Alfred Implementation

```bash
# Check current Alfred service
cat /Users/tomburke/Projects/Housing-Manager/apps/api/src/alfred/alfred.service.ts

# Check Alfred controller
cat /Users/tomburke/Projects/Housing-Manager/apps/api/src/alfred/alfred.controller.ts

# Check Alfred module
cat /Users/tomburke/Projects/Housing-Manager/apps/api/src/alfred/alfred.module.ts

# Check what Prisma models we have
grep -E "^model " /Users/tomburke/Projects/Housing-Manager/apps/api/prisma/schema.prisma | head -30
```

---

## STEP 2: Create Enhanced Alfred Service

Replace or enhance `/Users/tomburke/Projects/Housing-Manager/apps/api/src/alfred/alfred.service.ts`:

```typescript
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import Anthropic from '@anthropic-ai/sdk';

interface Message {
  role: 'user' | 'assistant';
  content: string;
}

interface AlfredResponse {
  message: string;
  actions?: ActionTaken[];
  suggestions?: ProactiveSuggestion[];
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
  recentPayments: any[];
  maintenanceTasks: any[];
  pendingPrompts: ProactiveSuggestion[];
}

@Injectable()
export class AlfredService {
  private anthropic: Anthropic;

  constructor(private prisma: PrismaService) {
    this.anthropic = new Anthropic({
      apiKey: process.env.ANTHROPIC_API_KEY,
    });
  }

  /**
   * Main chat endpoint - the heart of Alfred
   */
  async chat(
    householdId: string,
    message: string,
    conversationHistory: Message[] = [],
  ): Promise<AlfredResponse> {
    // 1. Load complete household context
    const context = await this.loadHouseholdContext(householdId);
    
    // 2. Build the system prompt with all household knowledge
    const systemPrompt = this.buildSystemPrompt(context);
    
    // 3. Build messages array
    const messages: Anthropic.MessageParam[] = [
      ...conversationHistory.map(m => ({
        role: m.role as 'user' | 'assistant',
        content: m.content,
      })),
      { role: 'user', content: message },
    ];

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
        const action = await this.executeToolCall(block, householdId);
        if (action) {
          actions.push(action);
        }
      }
    }

    // 6. If there were tool calls, get Claude's final response
    if (response.stop_reason === 'tool_use') {
      // Continue conversation with tool results
      const toolResults = actions.map(a => ({
        type: 'tool_result' as const,
        tool_use_id: a.entityId || 'unknown',
        content: `Successfully ${a.description}`,
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

    return {
      message: responseText,
      actions: actions.length > 0 ? actions : undefined,
      suggestions: context.pendingPrompts.slice(0, 3),
    };
  }

  /**
   * Load ALL household data for context
   */
  private async loadHouseholdContext(householdId: string): Promise<HouseholdContext> {
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      include: {
        homeProfile: true,
        members: {
          include: {
            user: {
              select: { id: true, firstName: true, lastName: true, email: true },
            },
          },
        },
      },
    });

    if (!household) {
      throw new Error(`Household ${householdId} not found`);
    }

    // Load all related data
    const [familyMembers, pets, vehicles, systems, vendors, billAccounts, maintenanceTasks] = 
      await Promise.all([
        this.prisma.familyMember.findMany({ where: { householdId, isActive: true } }),
        this.prisma.pet.findMany({ where: { householdId, isActive: true } }),
        this.prisma.vehicle.findMany({ where: { householdId, isActive: true } }),
        this.prisma.homeSystem.findMany({ 
          where: { householdId, isActive: true },
          include: { serviceHistory: { take: 5, orderBy: { serviceDate: 'desc' } } },
        }),
        this.prisma.householdVendor.findMany({ where: { householdId } }),
        this.prisma.billAccount.findMany({ 
          where: { householdId, isActive: true },
          include: { vendor: true },
        }),
        this.prisma.maintenanceTask.findMany({ 
          where: { householdId },
          orderBy: { dueDate: 'asc' },
        }),
      ]);

    // Load recent payments (if Payment model exists)
    let recentPayments: any[] = [];
    try {
      // This may need adjustment based on your actual payment tracking
      recentPayments = []; // TODO: Add when payment tracking is implemented
    } catch (e) {
      // Payment model may not exist yet
    }

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
      recentPayments,
      maintenanceTasks,
      pendingPrompts,
    };
  }

  /**
   * Build comprehensive system prompt with all household knowledge
   */
  private buildSystemPrompt(context: HouseholdContext): string {
    const { household, homeProfile, members, familyMembers, pets, vehicles, systems, vendors, billAccounts, maintenanceTasks, pendingPrompts } = context;

    const today = new Date().toLocaleDateString('en-US', { 
      weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' 
    });
    const month = new Date().getMonth();
    const season = month >= 2 && month <= 4 ? 'spring' : month >= 5 && month <= 7 ? 'summer' : month >= 8 && month <= 10 ? 'fall' : 'winter';

    return `You are Alfred, the AI Home Manager for ${household.name}. Today is ${today}.

## YOUR PERSONALITY
You are modeled after Batman's Alfred Pennyworth - distinguished, helpful, proactive, and always looking out for the family's best interests. You are:
- Knowledgeable about everything in this household
- Proactive in identifying gaps and suggesting improvements  
- Helpful in finding better rates, vendors, and services
- Action-oriented - you can add systems, schedule maintenance, and manage the home
- Warm but professional, with occasional dry wit

## THIS HOUSEHOLD

### Property
Address: ${homeProfile?.addressLine1 || 'Not set'}, ${homeProfile?.city || ''}, ${homeProfile?.state || ''} ${homeProfile?.postalCode || ''}
Type: ${homeProfile?.propertyType || 'Unknown'}
${homeProfile?.bedrooms ? `Bedrooms: ${homeProfile.bedrooms}` : ''}
${homeProfile?.bathrooms ? `Bathrooms: ${homeProfile.bathrooms}` : ''}
${homeProfile?.yearBuilt ? `Year Built: ${homeProfile.yearBuilt}` : ''}
${homeProfile?.squareFeet ? `Square Feet: ${homeProfile.squareFeet}` : ''}

### Family Members
${members.map(m => `- ${m.user?.firstName} ${m.user?.lastName} (${m.role})`).join('\n') || 'None added'}
${familyMembers.map(m => `- ${m.displayName} (${m.role})${m.profile?.notes ? ` - ${m.profile.notes}` : ''}`).join('\n')}

### Pets
${pets.length > 0 ? pets.map(p => `- ${p.name}: ${p.breed || p.type}${p.birthday ? `, born ${new Date(p.birthday).getFullYear()}` : ''}`).join('\n') : 'No pets on file'}

### Vehicles
${vehicles.length > 0 ? vehicles.map(v => `- ${v.year} ${v.make} ${v.model}${v.nickname ? ` "${v.nickname}"` : ''}`).join('\n') : 'No vehicles on file'}

### Home Systems & Appliances
${systems.length > 0 ? systems.map(s => {
  const details = [s.brand, s.model].filter(Boolean).join(' ');
  const lastService = s.serviceHistory?.[0]?.serviceDate 
    ? `Last serviced: ${new Date(s.serviceHistory[0].serviceDate).toLocaleDateString()}`
    : 'No service history';
  return `- ${s.name} (${s.systemType}): ${details || 'Details unknown'}. ${lastService}`;
}).join('\n') : 'No systems on file'}

### Vendors & Service Providers
${vendors.length > 0 ? vendors.map(v => `- ${v.displayName} (${v.category})${v.notes ? ` - Note: ${v.notes}` : ''}`).join('\n') : 'No vendors on file'}

### Bills Being Tracked
${billAccounts.length > 0 ? billAccounts.map(b => 
  `- ${b.nickname}: ${b.vendor?.displayName || 'Unknown vendor'} (${b.category}) - ${b.billingFrequency}${b.typicalAmount ? `, ~$${b.typicalAmount}` : ''}`
).join('\n') : 'No bills being tracked'}

### Upcoming Maintenance
${maintenanceTasks.filter(t => t.status === 'PENDING').slice(0, 5).map(t => 
  `- ${t.title}${t.dueDate ? ` - Due: ${new Date(t.dueDate).toLocaleDateString()}` : ''}`
).join('\n') || 'No upcoming maintenance scheduled'}

## CURRENT SEASON: ${season.toUpperCase()}
${this.getSeasonalTips(season)}

## PROACTIVE ITEMS TO MENTION (when relevant)
${pendingPrompts.slice(0, 5).map(p => `- [${p.type}] ${p.message}`).join('\n') || 'None at this time'}

## YOUR CAPABILITIES

You can use tools to:
1. **add_home_system** - Add a new appliance or system (refrigerator, furnace, etc.)
2. **update_home_system** - Update details on an existing system
3. **add_vendor** - Add a new service provider
4. **add_bill** - Add a new bill to track
5. **schedule_maintenance** - Create a maintenance task/reminder
6. **search_web** - Search for rates, vendors, or information online

## IMPORTANT BEHAVIORS

1. **Be specific and helpful** - Reference actual data from the household
2. **Ask follow-up questions** - When information is incomplete, ask for details
3. **Be proactive** - Mention relevant gaps or upcoming maintenance when appropriate
4. **Take action** - When the user wants to add or update something, use your tools
5. **Zone awareness** - When discussing a zone (kitchen, HVAC, etc.), mention what's missing
6. **Seasonal awareness** - It's ${season}, mention relevant seasonal maintenance

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
      if (task.status === 'PENDING' && task.dueDate && new Date(task.dueDate) < now) {
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
    const systemTypes = data.systems.map(s => s.systemType);
    
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
    if (month >= 8 && month <= 10) { // Fall
      const furnace = data.systems.find(s => s.systemType === 'FURNACE');
      if (furnace && !furnace.serviceHistory?.some((h: any) => {
        const serviceDate = new Date(h.serviceDate);
        return serviceDate.getFullYear() === now.getFullYear();
      })) {
        prompts.push({
          id: 'seasonal-furnace',
          type: 'SEASONAL',
          priority: 7,
          message: `Winter is coming! Your furnace hasn't been serviced this year. Want me to help schedule it?`,
          quickActions: ['Find HVAC techs', 'Schedule reminder', 'Already done'],
        });
      }
    }

    return prompts.sort((a, b) => b.priority - a.priority);
  }

  /**
   * Define available tools for Claude
   */
  private getTools(): Anthropic.Tool[] {
    return [
      {
        name: 'add_home_system',
        description: 'Add a new home system or appliance to the household inventory',
        input_schema: {
          type: 'object',
          properties: {
            systemType: {
              type: 'string',
              description: 'Type of system (e.g., FURNACE, WATER_HEATER, REFRIGERATOR, DISHWASHER)',
            },
            name: {
              type: 'string',
              description: 'Display name for the system',
            },
            brand: { type: 'string', description: 'Brand/manufacturer' },
            model: { type: 'string', description: 'Model number' },
            serialNumber: { type: 'string', description: 'Serial number' },
            location: { type: 'string', description: 'Location in home (e.g., Kitchen, Basement)' },
            notes: { type: 'string', description: 'Additional notes' },
          },
          required: ['systemType', 'name'],
        },
      },
      {
        name: 'update_home_system',
        description: 'Update an existing home system with new information',
        input_schema: {
          type: 'object',
          properties: {
            systemId: { type: 'string', description: 'ID of the system to update' },
            brand: { type: 'string' },
            model: { type: 'string' },
            serialNumber: { type: 'string' },
            notes: { type: 'string' },
            lastServiceDate: { type: 'string', description: 'Date of last service (ISO format)' },
          },
          required: ['systemId'],
        },
      },
      {
        name: 'add_vendor',
        description: 'Add a new vendor or service provider',
        input_schema: {
          type: 'object',
          properties: {
            displayName: { type: 'string', description: 'Name of the vendor' },
            category: { 
              type: 'string', 
              description: 'Category (e.g., ELECTRIC, CLEANING, LANDSCAPING, PLUMBING)' 
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
          type: 'object',
          properties: {
            title: { type: 'string', description: 'Title of the maintenance task' },
            description: { type: 'string' },
            category: { 
              type: 'string', 
              description: 'Category (e.g., HVAC, PLUMBING, EXTERIOR, SAFETY)' 
            },
            dueDate: { type: 'string', description: 'Due date (ISO format)' },
            priority: { type: 'string', enum: ['LOW', 'MEDIUM', 'HIGH', 'URGENT'] },
          },
          required: ['title', 'category'],
        },
      },
      {
        name: 'search_web',
        description: 'Search the web for information about rates, vendors, or home services',
        input_schema: {
          type: 'object',
          properties: {
            query: { type: 'string', description: 'Search query' },
            type: { 
              type: 'string', 
              enum: ['rates', 'vendors', 'general'],
              description: 'Type of search' 
            },
          },
          required: ['query'],
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
  ): Promise<ActionTaken | null> {
    const { name, input, id } = toolCall;
    const params = input as Record<string, any>;

    try {
      switch (name) {
        case 'add_home_system':
          const system = await this.prisma.homeSystem.create({
            data: {
              householdId,
              systemType: params.systemType,
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
            description: `Added ${params.name} (${params.systemType}) to your home`,
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
              lastServiceDate: params.lastServiceDate ? new Date(params.lastServiceDate) : undefined,
            },
          });
          return {
            type: 'UPDATE_SYSTEM',
            description: `Updated system information`,
            entityId: params.systemId,
          };

        case 'add_vendor':
          const vendor = await this.prisma.householdVendor.create({
            data: {
              householdId,
              displayName: params.displayName,
              category: params.category,
              phone: params.phone,
              email: params.email,
              notes: params.notes,
              isLocal: true,
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
              createdFromTemplate: false,
            },
          });
          return {
            type: 'SCHEDULE_MAINTENANCE',
            description: `Scheduled: ${params.title}`,
            entityId: task.id,
          };

        case 'search_web':
          // For now, return a placeholder - implement actual web search later
          return {
            type: 'SEARCH_WEB',
            description: `Searched for: ${params.query}`,
            entityId: id,
          };

        default:
          return null;
      }
    } catch (error) {
      console.error(`Error executing tool ${name}:`, error);
      return null;
    }
  }

  /**
   * Get suggestions for the chat UI
   */
  async getSuggestions(householdId: string): Promise<string[]> {
    const context = await this.loadHouseholdContext(householdId);
    
    const suggestions: string[] = [];
    
    // Add proactive suggestions
    for (const prompt of context.pendingPrompts.slice(0, 2)) {
      if (prompt.type === 'MISSING_DATA') {
        suggestions.push(`Tell me about my ${prompt.message.split(' ')[1]}`);
      } else if (prompt.type === 'MAINTENANCE_DUE') {
        suggestions.push(`Schedule ${prompt.message.split(' ')[0]}`);
      }
    }

    // Add common helpful suggestions
    suggestions.push(
      'What maintenance is coming up?',
      'Help me add a new appliance',
      'Find vendors in my area',
    );

    return suggestions.slice(0, 5);
  }
}
```

---

## STEP 3: Update Alfred Controller

Ensure the controller supports the enhanced service:

```typescript
// apps/api/src/alfred/alfred.controller.ts

import { Controller, Post, Get, Body, UseGuards, Request } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AlfredService } from './alfred.service';

interface ChatRequest {
  message: string;
  conversationHistory?: { role: 'user' | 'assistant'; content: string }[];
}

@Controller('alfred')
@UseGuards(JwtAuthGuard)
export class AlfredController {
  constructor(private alfredService: AlfredService) {}

  @Post('chat')
  async chat(@Request() req, @Body() body: ChatRequest) {
    const householdId = req.user.householdId;
    
    if (!householdId) {
      return { error: 'No household associated with user' };
    }

    return this.alfredService.chat(
      householdId,
      body.message,
      body.conversationHistory || [],
    );
  }

  @Get('suggestions')
  async getSuggestions(@Request() req) {
    const householdId = req.user.householdId;
    
    if (!householdId) {
      return { suggestions: ['Set up your home first'] };
    }

    const suggestions = await this.alfredService.getSuggestions(householdId);
    return { suggestions };
  }
}
```

---

## STEP 4: Test Locally

```bash
cd /Users/tomburke/Projects/Housing-Manager

# Start the API
cd apps/api && pnpm dev

# In another terminal, test Alfred with curl (replace TOKEN with valid JWT)
curl -X POST http://localhost:4000/api/alfred/chat \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "message": "What home systems do I have?"
  }'
```

---

## STEP 5: Test These Conversations

Once implemented, test these conversations:

1. **"What home systems do I have?"**
   - Should list Oil Furnace, Hot Water Tank, Generator, Chimneys

2. **"When did I last pay the cleaners?"**
   - Should note payment tracking isn't fully set up OR provide last payment

3. **"Help me add my kitchen appliances"**
   - Should start zone discovery for Kitchen
   - Ask about refrigerator, oven, dishwasher, etc.

4. **"My refrigerator is a Samsung RF28R7551SR"**
   - Should use add_home_system tool to add it

5. **"What maintenance should I do before winter?"**
   - Should mention furnace service, chimney cleaning, generator test

6. **"Find me a chimney sweep in Bethel CT"**
   - Should use search_web tool (placeholder for now)

---

## STEP 6: Commit and Deploy

```bash
cd /Users/tomburke/Projects/Housing-Manager

git add -A
git commit -m "feat: enhance Alfred AI with full household context and tool use

- Load complete household context (systems, vendors, bills, family, pets, vehicles)
- Add proactive gap detection (missing system details, overdue maintenance)
- Implement tool calling (add_home_system, add_vendor, schedule_maintenance)
- Add zone-based system discovery hints
- Add seasonal awareness for maintenance suggestions
- Comprehensive system prompt with household knowledge"

git push origin main
```

---

## EXPECTED ALFRED BEHAVIOR

After implementation, Alfred should:

1. ✅ Know all household data and reference it naturally
2. ✅ Answer questions about systems, vendors, maintenance
3. ✅ Proactively mention gaps ("Your generator is missing make/model")
4. ✅ Add systems through conversation ("I'll add that Samsung refrigerator")
5. ✅ Create maintenance tasks ("I've scheduled the chimney cleaning")
6. ✅ Suggest seasonal maintenance based on time of year
7. ✅ Guide through zone discovery ("Let's add your kitchen appliances")

---

## REPORT

After implementation, confirm:

1. **Service Updated**: Is alfred.service.ts enhanced?
2. **Context Loading**: Does it load all household data?
3. **Tool Calls**: Can it add systems/vendors through conversation?
4. **Proactive Prompts**: Does it identify gaps?
5. **Test Results**: Can you have the test conversations?

---

# END OF PROMPT
