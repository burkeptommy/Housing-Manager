# Haven Mobile - Remove Hard-Coded Data & Real Data Integration

## OVERVIEW

Remove ALL hard-coded/mock data from the mobile app. Replace with real data from the database, and show helpful setup prompts when data is missing.

---

## CORE PRINCIPLE

**No more fake data.** Every piece of information displayed must come from:
1. The database (via API)
2. Connected services (calendars, etc.)
3. User input

When data is missing, show a **helpful prompt** to guide the user to set it up.

---

## PART 1: HOME SCREEN - TODAY'S NOTES

### Current Problem
Today's Notes shows hard-coded items like:
- "Trash day tomorrow - bins out?"
- "Amazon delivery expected 2-5pm"
- "Emma's soccer practice 4pm"

### New Data Sources

Today's Notes should aggregate from:

1. **Calendar Events** (from synced calendars)
2. **Bills Due** (from bills/payments system)
3. **Maintenance Tasks Due** (from maintenance system)
4. **Family Activities** (from family member activities)
5. **Manual Notes** (user-created notes)

### Implementation

**Create a Notes/Events aggregation API endpoint:**

```typescript
// apps/api/src/dashboard/dashboard.controller.ts
@Get('today')
@UseGuards(JwtAuthGuard)
async getTodaysDashboard(@CurrentUser() user: User) {
  const household = await this.getActiveHousehold(user);
  
  const today = new Date();
  const tomorrow = addDays(today, 1);
  
  // Aggregate all sources
  const [
    calendarEvents,
    billsDue,
    maintenanceTasks,
    manualNotes,
  ] = await Promise.all([
    this.calendarService.getEventsForDateRange(household.id, today, tomorrow),
    this.billsService.getBillsDueSoon(household.id, 2), // Next 2 days
    this.maintenanceService.getTasksDueSoon(household.id, 7), // Next 7 days
    this.notesService.getActiveNotes(household.id),
  ]);

  // Transform into unified format
  const todaysNotes = [
    ...calendarEvents.map(e => ({
      id: e.id,
      type: 'calendar',
      icon: 'calendar',
      title: e.title,
      subtitle: formatTime(e.startTime),
      color: e.calendar?.color || '#627d98',
    })),
    ...billsDue.map(b => ({
      id: b.id,
      type: 'bill',
      icon: 'card',
      title: `${b.vendorName} due`,
      subtitle: formatCurrency(b.amount),
      color: isOverdue(b.dueDate) ? '#dc2626' : '#c4a574',
    })),
    ...maintenanceTasks.map(t => ({
      id: t.id,
      type: 'maintenance',
      icon: 'construct',
      title: t.title,
      subtitle: `Due ${formatRelativeDate(t.dueDate)}`,
      color: '#627d98',
    })),
    ...manualNotes.map(n => ({
      id: n.id,
      type: 'note',
      icon: n.icon || 'document-text',
      title: n.content,
      subtitle: null,
      color: '#627d98',
    })),
  ];

  return {
    todaysNotes,
    isEmpty: todaysNotes.length === 0,
  };
}
```

**Mobile - Fetch Real Data:**

```typescript
// apps/mobile/app/(tabs)/index.tsx
const [todaysNotes, setTodaysNotes] = useState<TodayNote[]>([]);
const [isLoading, setIsLoading] = useState(true);

useEffect(() => {
  fetchTodaysNotes();
}, []);

const fetchTodaysNotes = async () => {
  try {
    const token = await getIdToken();
    const response = await fetch(`${API_URL}/dashboard/today`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    const data = await response.json();
    setTodaysNotes(data.todaysNotes || []);
  } catch (err) {
    console.error('Failed to fetch today\'s notes:', err);
  } finally {
    setIsLoading(false);
  }
};
```

### Empty State - Setup Prompts

When Today's Notes is empty, show setup suggestions:

```typescript
{todaysNotes.length === 0 ? (
  <View style={styles.emptyNotesContainer}>
    <Text style={styles.emptyTitle}>No notes for today</Text>
    <Text style={styles.emptySubtitle}>
      Connect your calendar and set up Alfred to see your day at a glance
    </Text>
    
    <View style={styles.setupSuggestions}>
      <TouchableOpacity 
        style={styles.setupCard}
        onPress={() => router.push('/(tabs)/more/settings/calendars')}
      >
        <Ionicons name="calendar" size={24} color={colors.haven.champagne[500]} />
        <Text style={styles.setupCardTitle}>Connect Calendar</Text>
        <Text style={styles.setupCardSubtitle}>
          Sync Google, Outlook, or Apple Calendar
        </Text>
      </TouchableOpacity>
      
      <TouchableOpacity 
        style={styles.setupCard}
        onPress={() => router.push('/(tabs)/more/settings/alfred-email')}
      >
        <Ionicons name="mail" size={24} color={colors.haven.champagne[500]} />
        <Text style={styles.setupCardTitle}>Setup Personal Assistant</Text>
        <Text style={styles.setupCardSubtitle}>
          CC Alfred on emails to auto-add events & handle tasks
        </Text>
      </TouchableOpacity>
    </View>
  </View>
) : (
  <FlatList
    data={todaysNotes}
    renderItem={({ item }) => <NoteItem note={item} />}
  />
)}
```

---

## PART 2: SETUP CHECKLIST (Above Today's Notes)

### New Feature
Show a setup progress checklist for new users. This appears above Today's Notes until completed (or dismissed).

### Checklist Items

```typescript
interface SetupItem {
  id: string;
  title: string;
  description: string;
  icon: string;
  completed: boolean;
  route: string;
  priority: number;
}

const SETUP_CHECKLIST: SetupItem[] = [
  {
    id: 'profile',
    title: 'Complete Your Profile',
    description: 'Add your name and contact info',
    icon: 'person',
    route: '/(tabs)/profile',
    priority: 1,
  },
  {
    id: 'property',
    title: 'Confirm Property Details',
    description: 'Verify bedrooms, bathrooms, and systems',
    icon: 'home',
    route: '/(tabs)/more/property',
    priority: 2,
  },
  {
    id: 'heating',
    title: 'Set Up Heating Info',
    description: 'Who delivers your oil/gas? Who services your furnace?',
    icon: 'flame',
    route: '/(tabs)/more/vendors?type=heating',
    priority: 3,
  },
  {
    id: 'electricity',
    title: 'Add Electricity Provider',
    description: 'Connect your electric utility for bill tracking',
    icon: 'flash',
    route: '/(tabs)/more/vendors?type=electric',
    priority: 4,
  },
  {
    id: 'calendar',
    title: 'Connect Calendar',
    description: 'Sync your calendar to see events on your dashboard',
    icon: 'calendar',
    route: '/(tabs)/more/settings/calendars',
    priority: 5,
  },
  {
    id: 'family',
    title: 'Add Family Members',
    description: 'Invite your household to Haven',
    icon: 'people',
    route: '/(tabs)/more/family',
    priority: 6,
  },
  {
    id: 'plaid',
    title: 'Connect Bank Account',
    description: 'Auto-detect bills and set up payments',
    icon: 'card',
    route: '/(tabs)/money/connect',
    priority: 7,
  },
];
```

### API Endpoint for Checklist Status

```typescript
// apps/api/src/dashboard/dashboard.controller.ts
@Get('setup-status')
@UseGuards(JwtAuthGuard)
async getSetupStatus(@CurrentUser() user: User) {
  const household = await this.getActiveHousehold(user);
  const homeProfile = await this.prisma.homeProfile.findUnique({
    where: { householdId: household.id },
  });

  return {
    profile: !!(user.firstName && user.lastName),
    property: !!(homeProfile?.bedrooms && homeProfile?.bathrooms),
    heating: !!(household.heatingFuel && household.heatingFuelProvider),
    electricity: await this.hasVendorOfType(household.id, 'electric'),
    calendar: await this.hasConnectedCalendar(household.id),
    family: await this.hasFamilyMembers(household.id),
    plaid: await this.hasPlaidConnection(household.id),
  };
}
```

### UI Component

```typescript
function SetupChecklist({ status, onDismiss }: { status: SetupStatus; onDismiss: () => void }) {
  const router = useRouter();
  
  const items = SETUP_CHECKLIST.map(item => ({
    ...item,
    completed: status[item.id] || false,
  }));
  
  const completedCount = items.filter(i => i.completed).length;
  const totalCount = items.length;
  const progress = completedCount / totalCount;
  
  // Don't show if all complete
  if (completedCount === totalCount) return null;
  
  // Get next incomplete item
  const nextItem = items.find(i => !i.completed);

  return (
    <View style={styles.checklistContainer}>
      {/* Header */}
      <View style={styles.checklistHeader}>
        <View>
          <Text style={styles.checklistTitle}>Set Up Your Home</Text>
          <Text style={styles.checklistProgress}>
            {completedCount} of {totalCount} complete
          </Text>
        </View>
        <TouchableOpacity onPress={onDismiss}>
          <Text style={styles.dismissText}>Dismiss</Text>
        </TouchableOpacity>
      </View>
      
      {/* Progress Bar */}
      <View style={styles.progressBar}>
        <View style={[styles.progressFill, { width: `${progress * 100}%` }]} />
      </View>
      
      {/* Next Action Card */}
      {nextItem && (
        <TouchableOpacity 
          style={styles.nextActionCard}
          onPress={() => router.push(nextItem.route)}
        >
          <View style={styles.nextActionIcon}>
            <Ionicons name={nextItem.icon} size={24} color={colors.haven.champagne[500]} />
          </View>
          <View style={styles.nextActionText}>
            <Text style={styles.nextActionTitle}>{nextItem.title}</Text>
            <Text style={styles.nextActionDescription}>{nextItem.description}</Text>
          </View>
          <Ionicons name="chevron-forward" size={20} color={colors.haven.navy[400]} />
        </TouchableOpacity>
      )}
      
      {/* Expand to see all */}
      <TouchableOpacity 
        style={styles.seeAllButton}
        onPress={() => router.push('/(tabs)/more/setup')}
      >
        <Text style={styles.seeAllText}>See all setup tasks</Text>
      </TouchableOpacity>
    </View>
  );
}
```

---

## PART 3: HOME HEALTH SCORE - REAL CALCULATION

### Current Problem
Home Health Score is hard-coded or uses fake data.

### Calculation Factors

```typescript
interface HealthScoreFactors {
  billsOnTime: {
    score: number;      // 0-100
    weight: 0.25;       // 25% of total
    details: string;    // "3 of 4 bills paid on time this month"
  };
  maintenanceCompleted: {
    score: number;
    weight: 0.25;
    details: string;    // "2 overdue maintenance tasks"
  };
  systemsDocumented: {
    score: number;
    weight: 0.15;
    details: string;    // "HVAC and plumbing documented"
  };
  documentsUploaded: {
    score: number;
    weight: 0.10;
    details: string;    // "Insurance and warranty docs on file"
  };
  calendarConnected: {
    score: number;
    weight: 0.10;
    details: string;
  };
  familyComplete: {
    score: number;
    weight: 0.10;
    details: string;
  };
  vendorsSetup: {
    score: number;
    weight: 0.05;
    details: string;
  };
}
```

### API Endpoint

```typescript
// apps/api/src/dashboard/dashboard.controller.ts
@Get('health-score')
@UseGuards(JwtAuthGuard)
async getHealthScore(@CurrentUser() user: User) {
  const household = await this.getActiveHousehold(user);
  
  // Calculate each factor
  const factors = await this.calculateHealthFactors(household.id);
  
  // Calculate weighted total
  const totalScore = Object.values(factors).reduce(
    (sum, factor) => sum + (factor.score * factor.weight),
    0
  );
  
  // Get status label
  const status = this.getHealthStatus(totalScore);
  
  return {
    score: Math.round(totalScore),
    status, // 'Excellent', 'Good', 'Fair', 'Needs Work'
    factors,
    improvements: this.getTopImprovements(factors),
  };
}

private async calculateHealthFactors(householdId: string) {
  // Bills on time
  const bills = await this.prisma.bill.findMany({
    where: { householdId },
    take: 10,
    orderBy: { dueDate: 'desc' },
  });
  const paidOnTime = bills.filter(b => 
    b.status === 'paid' && b.paidAt <= b.dueDate
  ).length;
  const billsScore = bills.length > 0 ? (paidOnTime / bills.length) * 100 : 0;

  // Maintenance
  const overdueTasks = await this.prisma.maintenanceTask.count({
    where: {
      householdId,
      status: 'PENDING',
      dueDate: { lt: new Date() },
    },
  });
  const maintenanceScore = overdueTasks === 0 ? 100 : Math.max(0, 100 - (overdueTasks * 20));

  // Systems documented
  const systemsCount = await this.prisma.propertyAsset.count({
    where: { householdId },
  });
  const systemsScore = Math.min(100, systemsCount * 20); // 5 systems = 100%

  // Documents
  const docsCount = await this.prisma.document.count({
    where: { householdId },
  });
  const docsScore = Math.min(100, docsCount * 10); // 10 docs = 100%

  // Calendar
  const hasCalendar = await this.prisma.calendarConnection.count({
    where: { householdId },
  }) > 0;

  // Family
  const familyCount = await this.prisma.householdMember.count({
    where: { householdId },
  });

  // Vendors
  const vendorCount = await this.prisma.vendor.count({
    where: { householdId },
  });

  return {
    billsOnTime: {
      score: billsScore,
      weight: 0.25,
      details: `${paidOnTime} of ${bills.length} bills paid on time`,
    },
    maintenanceCompleted: {
      score: maintenanceScore,
      weight: 0.25,
      details: overdueTasks === 0 
        ? 'All maintenance up to date' 
        : `${overdueTasks} overdue tasks`,
    },
    systemsDocumented: {
      score: systemsScore,
      weight: 0.15,
      details: `${systemsCount} systems documented`,
    },
    documentsUploaded: {
      score: docsScore,
      weight: 0.10,
      details: `${docsCount} documents on file`,
    },
    calendarConnected: {
      score: hasCalendar ? 100 : 0,
      weight: 0.10,
      details: hasCalendar ? 'Calendar connected' : 'No calendar connected',
    },
    familyComplete: {
      score: Math.min(100, familyCount * 50),
      weight: 0.10,
      details: `${familyCount} family members added`,
    },
    vendorsSetup: {
      score: Math.min(100, vendorCount * 20),
      weight: 0.05,
      details: `${vendorCount} vendors set up`,
    },
  };
}
```

### Mobile UI - Health Score with Breakdown

```typescript
function HomeHealthCard({ healthData }: { healthData: HealthScore | null }) {
  const router = useRouter();
  
  // New user / no data state
  if (!healthData || healthData.score === 0) {
    return (
      <TouchableOpacity 
        style={styles.healthCardEmpty}
        onPress={() => router.push('/(tabs)/more/setup')}
      >
        <View style={styles.healthIconEmpty}>
          <Ionicons name="add" size={32} color={colors.haven.champagne[500]} />
        </View>
        <View>
          <Text style={styles.healthLabelEmpty}>Home Health</Text>
          <Text style={styles.healthPrompt}>
            Set up your home to see your health score
          </Text>
        </View>
        <Ionicons name="chevron-forward" size={20} color={colors.haven.navy[400]} />
      </TouchableOpacity>
    );
  }

  return (
    <TouchableOpacity 
      style={styles.healthCard}
      onPress={() => router.push('/(tabs)/more/health-details')}
    >
      <View style={styles.healthHeader}>
        <Text style={styles.healthLabel}>Home Health</Text>
        <View style={[styles.healthBadge, { backgroundColor: getStatusColor(healthData.status) }]}>
          <Text style={styles.healthBadgeText}>{healthData.status}</Text>
        </View>
      </View>
      
      <View style={styles.healthScoreRow}>
        <Text style={styles.healthScore}>{healthData.score}%</Text>
        <Text style={styles.healthScoreLabel}>
          {healthData.improvements?.[0]?.suggestion || 'Looking good!'}
        </Text>
      </View>
      
      {/* Mini progress bars for each factor */}
      <View style={styles.healthFactors}>
        {Object.entries(healthData.factors).slice(0, 3).map(([key, factor]) => (
          <View key={key} style={styles.factorRow}>
            <Text style={styles.factorLabel}>{formatFactorName(key)}</Text>
            <View style={styles.factorBar}>
              <View 
                style={[
                  styles.factorFill, 
                  { width: `${factor.score}%`, backgroundColor: getScoreColor(factor.score) }
                ]} 
              />
            </View>
          </View>
        ))}
      </View>
      
      <Text style={styles.healthSeeMore}>Tap to see details →</Text>
    </TouchableOpacity>
  );
}
```

---

## PART 4: SMART PROMPTS THROUGHOUT APP

### Principle
Every screen with missing data should show a helpful, contextual prompt.

### Examples

**Money Page - No Bills:**
```typescript
{bills.length === 0 && (
  <EmptyStateCard
    icon="card"
    title="No bills detected yet"
    description="Connect your bank to auto-detect bills, or add them manually"
    actions={[
      { label: 'Connect Bank', route: '/(tabs)/money/connect', primary: true },
      { label: 'Add Manually', route: '/(tabs)/money/add-bill' },
    ]}
  />
)}
```

**Maintenance - No Systems:**
```typescript
{systems.length === 0 && (
  <EmptyStateCard
    icon="construct"
    title="No home systems documented"
    description="Add your HVAC, plumbing, and other systems to get maintenance reminders"
    alfredPrompt="Tell Alfred about your heating system to get started"
    actions={[
      { label: 'Ask Alfred', route: '/(tabs)/manager', primary: true },
      { label: 'Add System', route: '/(tabs)/maintenance/add-system' },
    ]}
  />
)}
```

**Vendors - No Utility Provider:**
```typescript
{!hasElectricVendor && (
  <SuggestionBanner
    icon="flash"
    text="Who provides your electricity?"
    action={() => router.push('/(tabs)/more/vendors/add?type=electric')}
    actionLabel="Add Provider"
  />
)}
```

### Reusable Components

**EmptyStateCard:**
```typescript
interface EmptyStateCardProps {
  icon: string;
  title: string;
  description: string;
  alfredPrompt?: string;
  actions: Array<{
    label: string;
    route: string;
    primary?: boolean;
  }>;
}

function EmptyStateCard({ icon, title, description, alfredPrompt, actions }: EmptyStateCardProps) {
  const router = useRouter();
  
  return (
    <View style={styles.emptyCard}>
      <View style={styles.emptyIconContainer}>
        <Ionicons name={icon} size={32} color={colors.haven.champagne[500]} />
      </View>
      <Text style={styles.emptyTitle}>{title}</Text>
      <Text style={styles.emptyDescription}>{description}</Text>
      
      {alfredPrompt && (
        <View style={styles.alfredPrompt}>
          <Ionicons name="sparkles" size={16} color={colors.haven.champagne[500]} />
          <Text style={styles.alfredPromptText}>{alfredPrompt}</Text>
        </View>
      )}
      
      <View style={styles.emptyActions}>
        {actions.map((action, i) => (
          <TouchableOpacity
            key={i}
            style={[styles.emptyButton, action.primary && styles.emptyButtonPrimary]}
            onPress={() => router.push(action.route)}
          >
            <Text style={[
              styles.emptyButtonText, 
              action.primary && styles.emptyButtonTextPrimary
            ]}>
              {action.label}
            </Text>
          </TouchableOpacity>
        ))}
      </View>
    </View>
  );
}
```

**SuggestionBanner:**
```typescript
function SuggestionBanner({ icon, text, action, actionLabel }: SuggestionBannerProps) {
  return (
    <TouchableOpacity style={styles.suggestionBanner} onPress={action}>
      <Ionicons name={icon} size={20} color={colors.haven.champagne[500]} />
      <Text style={styles.suggestionText}>{text}</Text>
      <Text style={styles.suggestionAction}>{actionLabel} →</Text>
    </TouchableOpacity>
  );
}
```

---

## PART 5: ALFRED CHAT - PROACTIVE QUESTIONS FOR NEW USERS

### Current Behavior
Alfred waits for user to ask questions.

### New Behavior
For new users (incomplete setup), Alfred proactively asks onboarding questions.

```typescript
// When loading Alfred chat, check if user needs onboarding questions
const getAlfredGreeting = async (household: Household) => {
  const setupStatus = await getSetupStatus(household.id);
  
  // Find first incomplete item
  if (!setupStatus.heating) {
    return {
      message: "Hi! I noticed we don't have your heating information yet. What type of heating do you have? (oil, gas, electric, propane)",
      quickReplies: ['Oil', 'Natural Gas', 'Electric', 'Propane', 'Other'],
      context: 'heating_setup',
    };
  }
  
  if (!setupStatus.electricity) {
    return {
      message: "Great! Now, who provides your electricity? This helps me track your bills and find better rates.",
      quickReplies: ['Eversource', 'UI', 'Other'],
      context: 'electricity_setup',
    };
  }
  
  // Default greeting
  return {
    message: "Hi! How can I help you with your home today?",
    quickReplies: ['Pay a bill', 'Schedule service', 'Add a reminder'],
    context: 'general',
  };
};
```

---

## FILES TO UPDATE

### Remove Hard-Coded Data From:
- `apps/mobile/app/(tabs)/index.tsx` - Home dashboard
- `apps/mobile/app/(tabs)/money/index.tsx` - Bills list
- `apps/mobile/app/(tabs)/maintenance/index.tsx` - Tasks/systems
- `apps/mobile/app/(tabs)/more/family/index.tsx` - Family list
- `apps/mobile/app/(tabs)/more/vendors/index.tsx` - Vendors list

### New Files to Create:
- `apps/mobile/src/components/SetupChecklist.tsx`
- `apps/mobile/src/components/EmptyStateCard.tsx`
- `apps/mobile/src/components/SuggestionBanner.tsx`
- `apps/mobile/src/components/HomeHealthCard.tsx`
- `apps/mobile/app/(tabs)/more/health-details.tsx` - Health score breakdown
- `apps/mobile/app/(tabs)/more/setup.tsx` - Full setup checklist page

### API Endpoints to Create/Update:
- `GET /api/dashboard/today` - Today's notes aggregation
- `GET /api/dashboard/setup-status` - Setup checklist status
- `GET /api/dashboard/health-score` - Health score with breakdown

---

## VERIFICATION CHECKLIST

### Home Screen
- [ ] Today's Notes shows real data from database
- [ ] Empty Today's Notes shows setup prompts
- [ ] Setup checklist appears for incomplete users
- [ ] Health score is calculated from real data
- [ ] Health score shows N/A or setup prompt for new users

### Throughout App
- [ ] No hard-coded family members
- [ ] No hard-coded bills
- [ ] No hard-coded vendors
- [ ] No hard-coded maintenance tasks
- [ ] All empty states have helpful prompts

### Alfred
- [ ] New users get proactive questions
- [ ] Questions match incomplete setup items
- [ ] Quick replies help speed up setup

---

## TEST

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile
npx expo start --clear
```

Test with:
1. New user (fresh account) - should see setup checklist
2. Existing user with data - should see real Today's Notes
3. Empty each section - verify helpful prompts appear
