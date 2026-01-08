# ALFRED AI HOME MANAGER - COMPREHENSIVE CAPABILITIES

## VISION

Alfred is not a chatbot. Alfred is an **AI Home Manager** that:
1. **Knows everything** about your home, family, systems, vendors, and bills
2. **Proactively identifies gaps** in your home profile and asks smart questions
3. **Suggests optimizations** (better rates, upcoming maintenance, cost savings)
4. **Takes action** (schedules maintenance, adds systems, finds vendors)
5. **Learns your home** through conversation and builds the complete picture

---

## PART 1: ENHANCED QUERY CAPABILITIES

### 1.1 Payment & Bill Questions

Alfred should answer:
- "When did I last pay the cleaners?"
- "How much have I spent on landscaping this year?"
- "What's my average electric bill?"
- "Which bills are due this week?"
- "Show me my payment history for Renata Cleaning"

**Required Backend:**
```typescript
// New endpoints needed
GET /api/bills/payment-history?vendorId=X&startDate=Y&endDate=Z
GET /api/bills/spending-summary?category=X&period=monthly|yearly
GET /api/bills/upcoming?days=7
```

### 1.2 Rate Comparison Questions

Alfred should answer:
- "Are there better electric rates in my area?"
- "Is my landscaping service priced competitively?"
- "What do other people in Bethel pay for oil delivery?"

**Required:**
- Web search integration for rate comparisons
- Regional pricing data (can use web search)
- Vendor comparison logic

### 1.3 Maintenance Questions

Alfred should answer:
- "What maintenance is coming up?"
- "When was the furnace last serviced?"
- "What maintenance have I been putting off?"
- "What should I schedule before winter?"

**Required Backend:**
```typescript
GET /api/maintenance/upcoming?householdId=X
GET /api/maintenance/overdue?householdId=X
GET /api/maintenance/seasonal?season=winter|spring|summer|fall
GET /api/systems/{id}/service-history
```

---

## PART 2: PROACTIVE GAP DETECTION

### 2.1 System Completeness Checker

Alfred should detect incomplete system profiles and proactively ask:

```
"I noticed you added your propane generator, but I don't have the make, 
model, or serial number. Would you like to:
1. Take a photo of the data plate and I'll read it
2. Tell me the details now
3. Add it later

Having this info helps me schedule the right maintenance and find 
compatible parts if something breaks."
```

**Logic:**
```typescript
interface SystemCompletenessCheck {
  systemId: string;
  systemType: HomeSystemType;
  requiredFields: string[];
  missingFields: string[];
  importanceScore: number; // 1-10, affects prompt priority
  suggestedAction: 'photo' | 'manual' | 'skip';
}

function checkSystemCompleteness(system: HomeSystem): SystemCompletenessCheck {
  const requiredByType: Record<HomeSystemType, string[]> = {
    GENERATOR: ['brand', 'model', 'serialNumber', 'installDate', 'fuelType'],
    FURNACE: ['brand', 'model', 'fuelType', 'lastServiceDate', 'filterSize'],
    WATER_HEATER: ['brand', 'model', 'tankCapacityGallons', 'installDate'],
    // ... etc
  };
  // Return missing fields
}
```

### 2.2 Zone-Based System Discovery

Alfred should guide users through each zone of their home:

**Kitchen Zone Questions:**
```
"Let's make sure I know about your kitchen appliances:

☐ Refrigerator - Brand, model, age?
☐ Oven/Range - Gas or electric? Brand?
☐ Dishwasher - Brand, model?
☐ Microwave - Built-in or countertop?
☐ Garbage Disposal - Working properly?
☐ Range Hood/Vent - Filter type?
☐ Water filtration - Whole house? Under sink? Fridge filter?

Which would you like to add first?"
```

**Follow-up Intelligence:**
- If user says "gas range" → Ask about gas line inspection schedule
- If user says "water filter" → Ask filter replacement frequency, add to maintenance
- If user says "garbage disposal" → Ask if it's working, when last replaced

### 2.3 Zone Taxonomy

```typescript
const HOME_ZONES = {
  KITCHEN: {
    name: 'Kitchen',
    systems: [
      { type: 'REFRIGERATOR', questions: ['brand', 'model', 'age', 'filterType'] },
      { type: 'OVEN_RANGE', questions: ['fuelType', 'brand', 'model', 'selfCleaning'] },
      { type: 'DISHWASHER', questions: ['brand', 'model', 'age'] },
      { type: 'MICROWAVE', questions: ['builtIn', 'brand', 'ventType'] },
      { type: 'GARBAGE_DISPOSAL', questions: ['brand', 'horsepower', 'age'] },
      { type: 'RANGE_HOOD', questions: ['filterType', 'lastCleaned'] },
      { type: 'WATER_FILTER', questions: ['type', 'filterModel', 'changeFrequency'] },
    ],
  },
  LAUNDRY: {
    name: 'Laundry Room',
    systems: [
      { type: 'WASHER', questions: ['brand', 'model', 'frontLoad', 'age'] },
      { type: 'DRYER', questions: ['brand', 'model', 'gasOrElectric', 'ventCleaned'] },
    ],
  },
  HVAC: {
    name: 'Heating & Cooling',
    systems: [
      { type: 'FURNACE', questions: ['fuelType', 'brand', 'model', 'filterSize', 'lastService'] },
      { type: 'AIR_CONDITIONER', questions: ['type', 'brand', 'tonnage', 'lastService'] },
      { type: 'HEAT_PUMP', questions: ['brand', 'model', 'age'] },
      { type: 'THERMOSTAT', questions: ['brand', 'smart', 'model'] },
      { type: 'HUMIDIFIER', questions: ['wholeHouse', 'brand', 'filterType'] },
      { type: 'AIR_PURIFIER', questions: ['wholeHouse', 'brand', 'filterType'] },
    ],
  },
  WATER: {
    name: 'Water Systems',
    systems: [
      { type: 'WATER_HEATER', questions: ['tankOrTankless', 'fuelType', 'capacity', 'age'] },
      { type: 'WATER_SOFTENER', questions: ['brand', 'saltType', 'lastService'] },
      { type: 'WELL_PUMP', questions: ['depth', 'brand', 'lastService', 'pressureTank'] },
      { type: 'SUMP_PUMP', questions: ['brand', 'batteryBackup', 'lastTested'] },
      { type: 'SEPTIC_SYSTEM', questions: ['tankSize', 'lastPumped', 'drainFieldAge'] },
    ],
    followUp: {
      waterSource: {
        question: 'Is your water from a well or town/municipal supply?',
        ifWell: ['Add well pump', 'Ask last service', 'Ask water test date', 'Add to maintenance'],
        ifTown: ['Add water bill to wallet', 'Ask about sewer vs septic'],
      },
    },
  },
  ELECTRICAL: {
    name: 'Electrical',
    systems: [
      { type: 'ELECTRICAL_PANEL', questions: ['amps', 'brand', 'lastInspection'] },
      { type: 'GENERATOR', questions: ['brand', 'model', 'fuelType', 'kw', 'automatic'] },
      { type: 'SOLAR_PANELS', questions: ['kw', 'brand', 'installDate', 'warrantyExpires'] },
      { type: 'BATTERY_STORAGE', questions: ['brand', 'capacity', 'installDate'] },
      { type: 'EV_CHARGER', questions: ['brand', 'level', 'amps'] },
    ],
  },
  EXTERIOR: {
    name: 'Exterior',
    systems: [
      { type: 'ROOF', questions: ['material', 'age', 'lastInspection', 'warranty'] },
      { type: 'GUTTERS', questions: ['material', 'guards', 'lastCleaned'] },
      { type: 'SIDING', questions: ['material', 'age', 'lastPainted'] },
      { type: 'DECK_PATIO', questions: ['material', 'age', 'lastStained'] },
      { type: 'DRIVEWAY', questions: ['material', 'lastSealed'] },
      { type: 'FENCE', questions: ['material', 'age', 'length'] },
      { type: 'IRRIGATION', questions: ['zones', 'brand', 'winterized'] },
      { type: 'POOL', questions: ['type', 'size', 'heater', 'cover'] },
      { type: 'HOT_TUB', questions: ['brand', 'age', 'lastDrained'] },
    ],
  },
  SAFETY: {
    name: 'Safety & Security',
    systems: [
      { type: 'SMOKE_DETECTOR', questions: ['count', 'hardwired', 'lastTested', 'batteryAge'] },
      { type: 'CO_DETECTOR', questions: ['count', 'hardwired', 'lastTested'] },
      { type: 'FIRE_EXTINGUISHER', questions: ['count', 'locations', 'lastInspected'] },
      { type: 'SECURITY_SYSTEM', questions: ['provider', 'monitored', 'cameras'] },
      { type: 'SAFE', questions: ['fireproof', 'location'] },
    ],
  },
  GARAGE: {
    name: 'Garage',
    systems: [
      { type: 'GARAGE_DOOR_OPENER', questions: ['brand', 'age', 'smart', 'batteryBackup'] },
      { type: 'WORKBENCH_TOOLS', questions: ['compressor', 'shopVac'] },
    ],
  },
};
```

---

## PART 3: SMART FOLLOW-UP LOGIC

### 3.1 Contextual Question Trees

When user mentions something, Alfred follows up intelligently:

```typescript
const FOLLOW_UP_TREES = {
  'water_source': {
    initial: "Is your water from a private well or town/municipal supply?",
    branches: {
      'well': {
        followUps: [
          "When was your well last tested for quality?",
          "Do you know the well depth?",
          "Who services your well pump?",
          "Do you have a water softener or treatment system?",
        ],
        actions: [
          { type: 'ADD_SYSTEM', systemType: 'WELL_PUMP' },
          { type: 'ADD_MAINTENANCE', task: 'Annual well water test', frequency: 12 },
          { type: 'ADD_MAINTENANCE', task: 'Well pump inspection', frequency: 24 },
        ],
      },
      'town': {
        followUps: [
          "Do you have a separate sewer bill, or is it combined with water?",
          "Is your home on septic or town sewer?",
        ],
        actions: [
          { type: 'ADD_BILL', category: 'WATER_SEWER', prompt: 'water utility' },
        ],
      },
    },
  },
  'heating_type': {
    initial: "What type of heating does your home have?",
    branches: {
      'oil': {
        followUps: [
          "Who delivers your oil?",
          "Do you have automatic delivery or do you call when low?",
          "Where is your oil tank - basement or buried outside?",
        ],
        actions: [
          { type: 'ADD_VENDOR', category: 'GAS', name: 'Oil Delivery' },
          { type: 'ADD_SYSTEM', systemType: 'OIL_TANK' },
          { type: 'ADD_MAINTENANCE', task: 'Oil burner annual service', frequency: 12 },
        ],
      },
      'gas': {
        followUps: [
          "Is it natural gas or propane?",
          "Who is your gas provider?",
        ],
        actions: [
          { type: 'ADD_BILL', category: 'GAS' },
          { type: 'ADD_MAINTENANCE', task: 'Furnace annual service', frequency: 12 },
        ],
      },
      'electric': {
        followUps: [
          "Is it baseboard heat, heat pump, or forced air?",
        ],
        actions: [
          { type: 'ADD_MAINTENANCE', task: 'HVAC filter change', frequency: 3 },
        ],
      },
    },
  },
};
```

### 3.2 Proactive Prompt Queue

Alfred maintains a queue of things to ask about, prioritized by:
1. **Safety** (smoke detectors, CO detectors)
2. **Seasonal urgency** (furnace before winter, AC before summer)
3. **Incomplete critical systems** (generator without model number)
4. **Cost optimization** (rate comparisons, vendor alternatives)

```typescript
interface ProactivePrompt {
  id: string;
  type: 'MISSING_DATA' | 'MAINTENANCE_DUE' | 'SEASONAL' | 'OPTIMIZATION' | 'SAFETY';
  priority: number; // 1-10
  message: string;
  context: Record<string, any>;
  suggestedActions: string[];
  expiresAt?: Date; // For seasonal prompts
}

function generateProactivePrompts(household: HouseholdWithRelations): ProactivePrompt[] {
  const prompts: ProactivePrompt[] = [];
  
  // Check for incomplete systems
  for (const system of household.systems) {
    const missing = checkSystemCompleteness(system);
    if (missing.missingFields.length > 0) {
      prompts.push({
        type: 'MISSING_DATA',
        priority: missing.importanceScore,
        message: `I noticed your ${system.name} is missing some details...`,
        // ...
      });
    }
  }
  
  // Check for seasonal maintenance
  const month = new Date().getMonth();
  if (month >= 8 && month <= 10) { // Sept-Nov
    if (!household.systems.find(s => s.type === 'FURNACE')?.lastServiceDate) {
      prompts.push({
        type: 'SEASONAL',
        priority: 8,
        message: "Winter is coming! I don't see a recent furnace service...",
      });
    }
  }
  
  // Check for safety items
  const hasSmoke = household.systems.some(s => s.type === 'SMOKE_DETECTOR');
  if (!hasSmoke) {
    prompts.push({
      type: 'SAFETY',
      priority: 10,
      message: "I don't have any smoke detectors on file. Do you have them?",
    });
  }
  
  return prompts.sort((a, b) => b.priority - a.priority);
}
```

---

## PART 4: ALFRED SERVICE ENHANCEMENT

### 4.1 Enhanced Alfred Service

```typescript
// apps/api/src/alfred/alfred.service.ts

@Injectable()
export class AlfredService {
  constructor(
    private prisma: PrismaService,
    private anthropic: AnthropicService,
    private webSearch: WebSearchService,
  ) {}

  async chat(
    householdId: string,
    message: string,
    conversationHistory: Message[],
  ): Promise<AlfredResponse> {
    // 1. Load full household context
    const context = await this.loadHouseholdContext(householdId);
    
    // 2. Build system prompt with household knowledge
    const systemPrompt = this.buildSystemPrompt(context);
    
    // 3. Determine if web search is needed
    const needsSearch = this.analyzeForSearchIntent(message);
    let searchResults = null;
    if (needsSearch) {
      searchResults = await this.webSearch.search(needsSearch.query);
    }
    
    // 4. Call Claude with full context
    const response = await this.anthropic.chat({
      system: systemPrompt,
      messages: [
        ...conversationHistory,
        { role: 'user', content: message },
      ],
      tools: this.getAvailableTools(),
    });
    
    // 5. Execute any tool calls (add system, schedule maintenance, etc.)
    const actions = await this.executeToolCalls(response.toolCalls, householdId);
    
    // 6. Return response with any actions taken
    return {
      message: response.content,
      actions,
      suggestions: await this.getProactiveSuggestions(householdId),
    };
  }

  private async loadHouseholdContext(householdId: string): Promise<HouseholdContext> {
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      include: {
        homeProfile: true,
        members: { include: { user: true } },
        familyMembers: true,
        pets: true,
        vehicles: true,
        homeSystems: { include: { serviceHistory: true } },
        vendors: true,
        billAccounts: { include: { payments: { take: 10, orderBy: { date: 'desc' } } } },
        maintenanceTasks: true,
      },
    });
    
    return {
      household,
      pendingPrompts: await this.generateProactivePrompts(household),
      recentActivity: await this.getRecentActivity(householdId),
    };
  }

  private buildSystemPrompt(context: HouseholdContext): string {
    return `You are Alfred, the AI Home Manager for ${context.household.name}.

## YOUR ROLE
You are a distinguished, helpful home manager - like Batman's Alfred Pennyworth. You are:
- Knowledgeable about everything in this household
- Proactive in identifying gaps and suggesting improvements
- Helpful in finding better rates, vendors, and services
- Action-oriented - you can add systems, schedule maintenance, and manage the home

## HOUSEHOLD INFORMATION

### Property
${JSON.stringify(context.household.homeProfile, null, 2)}

### Family Members
${context.household.members.map(m => `- ${m.user?.firstName} ${m.user?.lastName} (${m.role})`).join('\n')}
${context.household.familyMembers.map(m => `- ${m.displayName} (${m.role})`).join('\n')}

### Pets
${context.household.pets.map(p => `- ${p.name}: ${p.breed || p.type}, ${p.age} years old`).join('\n')}

### Vehicles
${context.household.vehicles.map(v => `- ${v.year} ${v.make} ${v.model} "${v.nickname}"`).join('\n')}

### Home Systems
${context.household.homeSystems.map(s => `- ${s.name} (${s.systemType}): ${s.brand || 'Unknown brand'} ${s.model || ''}`).join('\n')}

### Vendors & Bills
${context.household.vendors.map(v => `- ${v.displayName} (${v.category})`).join('\n')}

### Recent Payments
${context.household.billAccounts.flatMap(b => b.payments.map(p => `- ${b.nickname}: $${p.amount} on ${p.date}`)).join('\n')}

### Upcoming Maintenance
${context.household.maintenanceTasks.filter(t => t.status === 'PENDING').map(t => `- ${t.title}: Due ${t.dueDate}`).join('\n')}

## THINGS TO PROACTIVELY MENTION
${context.pendingPrompts.slice(0, 3).map(p => `- ${p.message}`).join('\n')}

## YOUR CAPABILITIES
You can:
1. Answer questions about the household, payments, maintenance, etc.
2. Add new systems, vendors, or bills when the user provides information
3. Schedule maintenance tasks
4. Search the web for better rates, vendor reviews, or service information
5. Proactively ask about missing information to complete the home profile

## IMPORTANT BEHAVIORS
- When information is incomplete, ask follow-up questions
- When discussing systems, mention if key details are missing
- Suggest seasonal maintenance based on the time of year
- Offer to find better rates or alternative vendors when relevant
- Always be helpful, proactive, and action-oriented
`;
  }

  private getAvailableTools(): Tool[] {
    return [
      {
        name: 'add_home_system',
        description: 'Add a new home system/appliance',
        parameters: {
          systemType: { type: 'string', enum: Object.keys(HomeSystemType) },
          name: { type: 'string' },
          brand: { type: 'string', optional: true },
          model: { type: 'string', optional: true },
          // ... more fields
        },
      },
      {
        name: 'update_home_system',
        description: 'Update an existing home system with new information',
        parameters: {
          systemId: { type: 'string' },
          updates: { type: 'object' },
        },
      },
      {
        name: 'add_vendor',
        description: 'Add a new vendor/service provider',
        parameters: {
          displayName: { type: 'string' },
          category: { type: 'string', enum: Object.keys(VendorCategory) },
          // ...
        },
      },
      {
        name: 'add_bill_account',
        description: 'Add a new bill to track',
        parameters: {
          vendorId: { type: 'string' },
          nickname: { type: 'string' },
          category: { type: 'string' },
          // ...
        },
      },
      {
        name: 'schedule_maintenance',
        description: 'Create a maintenance task',
        parameters: {
          title: { type: 'string' },
          description: { type: 'string' },
          category: { type: 'string' },
          dueDate: { type: 'string' },
          // ...
        },
      },
      {
        name: 'search_web',
        description: 'Search the web for rates, vendors, or information',
        parameters: {
          query: { type: 'string' },
          location: { type: 'string', optional: true },
        },
      },
      {
        name: 'get_payment_history',
        description: 'Get payment history for a vendor or bill',
        parameters: {
          vendorId: { type: 'string', optional: true },
          category: { type: 'string', optional: true },
          startDate: { type: 'string', optional: true },
        },
      },
    ];
  }
}
```

---

## PART 5: IMPLEMENTATION PLAN

### Phase 1: Enhanced Context & Queries (Week 1)
1. Update Alfred service to load full household context
2. Add payment history endpoint
3. Add spending summary endpoint
4. Update system prompt with all household data
5. Test detailed queries ("When did I last pay cleaners?")

### Phase 2: Tool Calling (Week 2)
1. Implement `add_home_system` tool
2. Implement `update_home_system` tool
3. Implement `add_vendor` tool
4. Implement `schedule_maintenance` tool
5. Test conversational system creation

### Phase 3: Proactive Prompts (Week 3)
1. Build gap detection for all system types
2. Implement priority queue for proactive prompts
3. Add seasonal awareness (winter prep, summer prep)
4. Surface prompts in Alfred chat UI

### Phase 4: Web Search & Optimization (Week 4)
1. Integrate web search for rate comparisons
2. Build vendor comparison logic
3. Add "find better rates" capability
4. Add "find vendors in my area" capability

### Phase 5: Zone-Based Discovery (Week 5)
1. Implement zone taxonomy
2. Build zone walkthrough flow
3. Add follow-up question trees
4. Complete kitchen, laundry, HVAC, water, electrical, exterior zones

---

## STEP 1: Start Implementation

Create the enhanced Alfred service now. Begin with:

1. **Enhanced context loading** - Load ALL household data
2. **Improved system prompt** - Include all household information
3. **Payment history queries** - Answer "when did I last pay X"
4. **Basic tool calling** - Add/update systems through conversation

Run the following to start:

```bash
# Examine current Alfred service
cat /Users/tomburke/Projects/Housing-Manager/apps/api/src/alfred/alfred.service.ts

# Check what endpoints exist
grep -rn "alfred" /Users/tomburke/Projects/Housing-Manager/apps/api/src --include="*.controller.ts"
```

Then implement the enhanced service following the patterns above.

---

## EXPECTED ALFRED CONVERSATIONS

### Example 1: Payment Query
**User:** "When did I last pay the cleaners?"
**Alfred:** "Your last payment to Renata Cleaning Services was on December 20th for $150. She comes every two weeks, so the next payment would be due around January 3rd. Remember, Renata only accepts cash or check - would you like me to add a reminder?"

### Example 2: Rate Comparison
**User:** "Are there better electric rates in my area?"
**Alfred:** "You're currently with Eversource. In Connecticut, you can choose alternative electric suppliers while Eversource still delivers the power. Let me search for current rates in Bethel...

I found a few options:
- Direct Energy: 11.9¢/kWh (vs Eversource standard rate of ~13.5¢/kWh)
- Town Square Energy: 10.8¢/kWh (12-month fixed)

Would you like me to save this information, or help you switch?"

### Example 3: Proactive Gap Detection
**Alfred:** "I was reviewing your home systems and noticed your propane generator doesn't have a make, model, or serial number on file. This information helps me:
- Schedule the right maintenance intervals
- Find compatible parts if something breaks
- Track warranty information

Would you like to:
1. 📸 Take a photo of the data plate - I can read it
2. ✏️ Tell me the details now
3. ⏰ Remind me later"

### Example 4: Seasonal Proactive
**Alfred:** "Winter is approaching! Looking at your home, I want to make sure you're prepared:

✅ Oil furnace - You have one, but I don't see a recent service record. When was it last serviced?
✅ Generator - Ready for power outages, but let's test it
⚠️ Chimneys - Due for annual cleaning before you start using the fireplaces
⚠️ Gutters - Should be cleaned before freeze

Would you like me to help schedule any of these?"

### Example 5: Zone Discovery
**User:** "Help me add my kitchen appliances"
**Alfred:** "Great! Let's go through your kitchen. Tell me about each appliance:

**Refrigerator**
- What brand and model? (Look for a label inside the door)
- Approximately how old is it?
- Does it have a water/ice dispenser with a filter?

Once you tell me about the fridge, we'll move on to the oven, dishwasher, and other appliances."

---

# END OF SPEC

This is the complete vision for Alfred. Implement in phases, starting with enhanced context and queries.
