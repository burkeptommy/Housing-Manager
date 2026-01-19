# Prompt 018: Beta Core Features - Home Management Complete

## Overview

Build out the core home management features for Haven beta launch. Focus on making the app genuinely useful for homeowners WITHOUT bill pay features. The beta must nail: **home dashboard, maintenance, vendors, home manual, and budgeting**.

Also add **free home walkthrough** promotion for qualifying users in Fairfield County CT or Westchester County NY.

## Current State Audit

### ✅ What's Working Well

**Dashboard (index.tsx)**
- Home health score with expansion details
- Today's notes (bills, maintenance, events)
- Family status cards
- Alfred email activity
- Pending approvals
- Quick actions grid
- Recent activity feed

**Home Screen (home/index.tsx)**
- Property details (beds, baths, sqft, year)
- Zones grid with assets
- Utilities section
- Home systems section (basic)
- Recent activity
- Ask Alfred card

**Maintenance (maintenance/index.tsx)**
- Tasks view with filters (All, Upcoming, Overdue)
- Systems view (derived from tasks by category)
- Task details with checklists
- Assigned vendor/person tracking

**Vendors (vendors/index.tsx)**
- My Vendors list with categories
- Category filter chips
- Call/email quick actions
- "Find Vendors" tab (empty - needs implementation)

### ❌ Critical Gaps for Beta

1. **Free Home Walkthrough Banner** - Not implemented
2. **Vendor Search** - Returns empty, no external API
3. **Home Manual** - No dedicated view for system documentation
4. **Maintenance Budget** - No cost tracking or forecasting
5. **System Management** - Can't add systems directly, no detail pages
6. **Smart Empty States** - Generic, don't guide users

---

## Part 1: Free Home Walkthrough Feature

### Requirements

Show a prominent banner promoting free home walkthrough to:
1. **New users** (< 7 days since signup) in qualifying areas
2. **Existing users** with incomplete profiles (< 3 systems OR < 3 vendors OR < 5 bills)

Qualifying areas:
- Fairfield County, CT (zip codes: 068xx)
- Westchester County, NY (zip codes: 105xx, 106xx, 107xx, 108xx, 109xx)

### API Endpoint

Create: `POST /api/walkthrough/request`

```typescript
// apps/api/src/walkthrough/walkthrough.controller.ts

@Controller('walkthrough')
export class WalkthroughController {
  @Post('request')
  async requestWalkthrough(
    @CurrentUser() user: User,
    @Body() dto: RequestWalkthroughDto,
  ) {
    // Create service request for walkthrough
    // Send notification to operations team
    // Track in household
  }

  @Get('eligibility/:householdId')
  async checkEligibility(@Param('householdId') householdId: string) {
    // Check if user qualifies for free walkthrough
    // Returns: { eligible: boolean, reason: string, hasScheduled: boolean }
  }
}
```

### Mobile Component

Create: `apps/mobile/src/components/FreeWalkthroughBanner.tsx`

```tsx
interface FreeWalkthroughBannerProps {
  householdId: string;
  systemCount: number;
  vendorCount: number;
  billCount: number;
  zipCode?: string;
  createdAt: string;
  onDismiss?: () => void;
}

export function FreeWalkthroughBanner({
  householdId,
  systemCount,
  vendorCount,
  billCount,
  zipCode,
  createdAt,
  onDismiss,
}: FreeWalkthroughBannerProps) {
  const [isEligible, setIsEligible] = useState(false);
  const [hasScheduled, setHasScheduled] = useState(false);
  const [showScheduleModal, setShowScheduleModal] = useState(false);

  // Check eligibility based on:
  // 1. Location (Fairfield CT or Westchester NY)
  // 2. Profile completeness (< 3 systems OR < 3 vendors OR < 5 bills)
  // 3. Account age (< 30 days for best offer)

  const isQualifyingZip = (zip: string) => {
    if (!zip) return false;
    // Fairfield County CT
    if (zip.startsWith('068')) return true;
    // Westchester County NY
    if (['105', '106', '107', '108', '109'].some(p => zip.startsWith(p))) return true;
    return false;
  };

  const needsWalkthrough = systemCount < 3 || vendorCount < 3 || billCount < 5;

  useEffect(() => {
    if (isQualifyingZip(zipCode) && needsWalkthrough && !hasScheduled) {
      setIsEligible(true);
    }
  }, [zipCode, systemCount, vendorCount, billCount]);

  if (!isEligible || hasScheduled) return null;

  return (
    <View style={styles.banner}>
      <LinearGradient
        colors={[colors.haven.navy[900], colors.haven.navy[800]]}
        style={styles.gradient}
      >
        <View style={styles.iconContainer}>
          <Ionicons name="home" size={32} color={colors.haven.champagne[400]} />
          <View style={styles.checkBadge}>
            <Ionicons name="checkmark" size={12} color={colors.white} />
          </View>
        </View>
        
        <View style={styles.content}>
          <Text style={styles.title}>Free Home Walkthrough</Text>
          <Text style={styles.subtitle}>
            We'll visit your home, document all systems, and set up your complete maintenance schedule.
          </Text>
          <Text style={styles.value}>$299 value - FREE for beta users</Text>
        </View>

        <TouchableOpacity
          style={styles.scheduleButton}
          onPress={() => setShowScheduleModal(true)}
        >
          <Text style={styles.scheduleButtonText}>Schedule</Text>
        </TouchableOpacity>

        {onDismiss && (
          <TouchableOpacity style={styles.dismissButton} onPress={onDismiss}>
            <Ionicons name="close" size={20} color={colors.white} />
          </TouchableOpacity>
        )}
      </LinearGradient>

      <WalkthroughScheduleModal
        visible={showScheduleModal}
        onClose={() => setShowScheduleModal(false)}
        householdId={householdId}
        onScheduled={() => {
          setHasScheduled(true);
          setShowScheduleModal(false);
        }}
      />
    </View>
  );
}
```

### Where to Show

1. **Dashboard** - After hero stats, before Today's Notes (most prominent)
2. **Maintenance > Systems tab** - When < 3 systems shown
3. **Home Screen** - When systems section is empty
4. **Wallet/Billing** - When < 5 bills

---

## Part 2: Vendor Search Integration

### Option A: Human-Assisted (Recommended for Beta)

Position vendor discovery as a service differentiator. When user searches for vendors:

1. Show "Let Alfred Find Vendors For You" prompt
2. Create a ServiceRequest when user asks
3. Human manager researches and adds 2-3 vetted options
4. Notify user when vendors are added

This is the Haven advantage - we vet vendors so you don't have to.

### Implementation

Update: `apps/mobile/app/(tabs)/manager/vendors/index.tsx`

```tsx
// In the Find Vendors tab empty state:

const renderFindVendorsTab = () => (
  <>
    {/* Search Section */}
    <View style={styles.searchSection}>
      <View style={styles.searchInputContainer}>
        <Ionicons name="search-outline" size={20} color={colors.text.tertiary} />
        <TextInput
          style={styles.searchInput}
          placeholder="What service do you need?"
          placeholderTextColor={colors.text.tertiary}
          value={searchQuery}
          onChangeText={setSearchQuery}
        />
      </View>

      {/* Category Pills */}
      <ScrollView horizontal showsHorizontalScrollIndicator={false}>
        {VENDOR_CATEGORIES.map(cat => (
          <TouchableOpacity
            key={cat.id}
            style={[styles.categoryPill, selectedCategory === cat.id && styles.categoryPillActive]}
            onPress={() => setSelectedCategory(cat.id)}
          >
            <Ionicons name={cat.icon} size={16} color={selectedCategory === cat.id ? colors.white : colors.text.secondary} />
            <Text style={[styles.categoryPillText, selectedCategory === cat.id && styles.categoryPillTextActive]}>
              {cat.label}
            </Text>
          </TouchableOpacity>
        ))}
      </ScrollView>
    </View>

    {/* Alfred Find Vendors CTA */}
    <View style={styles.alfredFindContainer}>
      <View style={styles.alfredFindIcon}>
        <AlfredTabIcon size={48} color={colors.haven.champagne[500]} />
      </View>
      <Text style={styles.alfredFindTitle}>Let Haven Find the Right Vendor</Text>
      <Text style={styles.alfredFindSubtitle}>
        Tell us what you need and we'll research and recommend vetted local professionals - no searching required.
      </Text>
      
      <TouchableOpacity
        style={styles.alfredFindButton}
        onPress={() => {
          // Create service request with search query and category
          router.push({
            pathname: '/(tabs)/manager/new-request',
            params: {
              prefill: `Find me a ${selectedCategory !== 'all' ? selectedCategory : 'service provider'}: ${searchQuery}`,
            },
          });
        }}
      >
        <Ionicons name="sparkles" size={20} color={colors.white} />
        <Text style={styles.alfredFindButtonText}>
          {searchQuery ? `Find ${searchQuery}` : 'Request Vendor Recommendation'}
        </Text>
      </TouchableOpacity>

      <Text style={styles.alfredFindNote}>
        We typically respond within 24 hours with 2-3 vetted options
      </Text>
    </View>

    {/* Or Browse Social Recommendations */}
    <View style={styles.socialSection}>
      <Text style={styles.socialTitle}>From Your Neighbors</Text>
      <Text style={styles.socialSubtitle}>
        See which vendors other Haven members in your area use and recommend
      </Text>
      <TouchableOpacity
        style={styles.socialButton}
        onPress={() => router.push('/(tabs)/manager/vendors/social')}
      >
        <Ionicons name="people-outline" size={18} color={colors.haven.champagne[500]} />
        <Text style={styles.socialButtonText}>Browse Neighborhood Recommendations</Text>
      </TouchableOpacity>
    </View>
  </>
);
```

### Option B: External API Integration (Phase 2)

For later, integrate with Google Places or Angi API:

```typescript
// apps/api/src/vendors/vendor-search.service.ts

@Injectable()
export class VendorSearchService {
  async searchExternalVendors(
    query: string,
    category: string,
    location: { lat: number; lng: number },
    radius: number = 25, // miles
  ): Promise<ExternalVendor[]> {
    // Call Google Places API
    // Or Angi/Thumbtack partner API
    // Return normalized results
  }
}
```

---

## Part 3: Home Manual

Create a dedicated "Home Manual" view that serves as the single source of truth for everything about the home.

### New Screen: `apps/mobile/app/(tabs)/home/manual.tsx`

```tsx
export default function HomeManualScreen() {
  // Tabs: Overview | Systems | Documents | Maintenance History

  return (
    <ScreenContainer title="Home Manual" scrollable={false}>
      {/* Tab Bar */}
      <View style={styles.tabBar}>
        <Tab label="Overview" active={tab === 'overview'} onPress={() => setTab('overview')} />
        <Tab label="Systems" active={tab === 'systems'} onPress={() => setTab('systems')} />
        <Tab label="Docs" active={tab === 'docs'} onPress={() => setTab('docs')} />
        <Tab label="History" active={tab === 'history'} onPress={() => setTab('history')} />
      </View>

      {tab === 'overview' && <OverviewTab property={property} />}
      {tab === 'systems' && <SystemsTab systems={systems} />}
      {tab === 'docs' && <DocumentsTab documents={documents} />}
      {tab === 'history' && <MaintenanceHistoryTab history={history} />}
    </ScreenContainer>
  );
}

// Overview Tab
function OverviewTab({ property }) {
  return (
    <ScrollView>
      {/* Property Photo + Address */}
      <PropertyHeader property={property} />

      {/* Key Facts */}
      <SectionHeader title="Property Details" />
      <Card>
        <DetailRow label="Address" value={property.address.full} />
        <DetailRow label="Year Built" value={property.yearBuilt} />
        <DetailRow label="Square Feet" value={property.squareFeet?.toLocaleString()} />
        <DetailRow label="Lot Size" value={`${property.lotSize} acres`} />
        <DetailRow label="Bedrooms" value={property.bedrooms} />
        <DetailRow label="Bathrooms" value={property.bathrooms} />
      </Card>

      {/* Utilities Summary */}
      <SectionHeader title="Utilities" />
      <Card>
        <UtilityRow icon="flash" label="Electric" value={utilities.electricity?.provider} />
        <UtilityRow icon="flame" label="Gas" value={utilities.gas?.provider} />
        <UtilityRow icon="water" label="Water" value={utilities.water?.provider} />
        <UtilityRow icon="wifi" label="Internet" value={utilities.internet?.provider} />
      </Card>

      {/* Systems Summary */}
      <SectionHeader title="Major Systems" actionText="View All" onAction={() => setTab('systems')} />
      <HorizontalSystemCards systems={systems.slice(0, 4)} />

      {/* Important Dates */}
      <SectionHeader title="Important Dates" />
      <Card>
        <DateRow label="Roof Installed" value={systems.find(s => s.type === 'ROOF')?.installedDate} />
        <DateRow label="HVAC Installed" value={systems.find(s => s.type === 'FURNACE')?.installedDate} />
        <DateRow label="Water Heater" value={systems.find(s => s.type === 'WATER_HEATER')?.installedDate} />
      </Card>
    </ScrollView>
  );
}

// Systems Tab
function SystemsTab({ systems }) {
  return (
    <FlatList
      data={systems}
      renderItem={({ item }) => (
        <SystemCard
          system={item}
          onPress={() => router.push(`/home/system/${item.id}`)}
        />
      )}
      ListHeaderComponent={
        <View style={styles.systemsHeader}>
          <Text style={styles.systemsCount}>{systems.length} systems tracked</Text>
          <TouchableOpacity onPress={() => setShowAddSystem(true)}>
            <Text style={styles.addSystemText}>+ Add System</Text>
          </TouchableOpacity>
        </View>
      }
      ListEmptyComponent={
        <EmptySystemsWithWalkthroughCTA />
      }
    />
  );
}
```

### System Detail Screen: `apps/mobile/app/(tabs)/home/system/[id].tsx`

```tsx
export default function SystemDetailScreen() {
  const { id } = useLocalSearchParams();
  const [system, setSystem] = useState<HomeSystem | null>(null);

  return (
    <ScreenContainer title={system?.name || 'System'}>
      <ScrollView>
        {/* System Header */}
        <View style={styles.header}>
          <View style={styles.iconContainer}>
            <Ionicons name={getSystemIcon(system.type)} size={32} color={colors.haven.champagne[500]} />
          </View>
          <Text style={styles.systemName}>{system.name}</Text>
          <Badge label={system.condition || 'Unknown'} variant={getConditionVariant(system.condition)} />
        </View>

        {/* Details Card */}
        <Card>
          <DetailRow label="Brand" value={system.brand} />
          <DetailRow label="Model" value={system.model} />
          <DetailRow label="Model Number" value={system.modelNumber} />
          <DetailRow label="Serial Number" value={system.serialNumber} />
          <DetailRow label="Installed" value={formatDate(system.installedDate)} />
          <DetailRow label="Location" value={system.location} />
          <DetailRow label="Expected Lifespan" value={system.maintenanceResearch?.expectedLifespan} />
        </Card>

        {/* Maintenance Schedule */}
        <SectionHeader title="Maintenance Schedule" />
        <Card>
          {system.tasks?.map(task => (
            <TaskRow
              key={task.id}
              task={task}
              onPress={() => router.push(`/maintenance/${task.id}`)}
            />
          ))}
        </Card>

        {/* Annual Budget */}
        <SectionHeader title="Annual Maintenance Budget" />
        <Card>
          <View style={styles.budgetRow}>
            <Text style={styles.budgetLabel}>Estimated Annual Cost</Text>
            <Text style={styles.budgetValue}>
              {formatCurrency(system.maintenanceResearch?.annualBudget || 0)}
            </Text>
          </View>
        </Card>

        {/* Vendors */}
        <SectionHeader title="Service Providers" />
        {system.vendors?.length > 0 ? (
          system.vendors.map(vendor => (
            <VendorRow key={vendor.id} vendor={vendor} />
          ))
        ) : (
          <Card>
            <TouchableOpacity onPress={() => router.push('/manager/vendors')}>
              <Text>Add a service provider for this system</Text>
            </TouchableOpacity>
          </Card>
        )}

        {/* Documents */}
        <SectionHeader title="Documents" />
        <DocumentsList
          documents={documents.filter(d => d.systemId === system.id)}
          onUpload={() => router.push(`/vault/upload?systemId=${system.id}`)}
        />

        {/* Service History */}
        <SectionHeader title="Service History" />
        <ServiceHistoryList systemId={system.id} />

        {/* Tips from AI Research */}
        {system.maintenanceResearch?.efficiencyTips && (
          <>
            <SectionHeader title="Tips & Recommendations" />
            <Card>
              {system.maintenanceResearch.efficiencyTips.map((tip, i) => (
                <TipRow key={i} tip={tip} />
              ))}
            </Card>
          </>
        )}
      </ScrollView>
    </ScreenContainer>
  );
}
```

---

## Part 4: Maintenance Budget

### Add to Dashboard

Show annual maintenance budget overview on dashboard:

```tsx
// In Dashboard, after Today's Notes card:

<AnimatedCard style={styles.budgetCard}>
  <View style={styles.budgetHeader}>
    <Text style={styles.budgetTitle}>Annual Maintenance Budget</Text>
    <TouchableOpacity onPress={() => router.push('/maintenance/budget')}>
      <Text style={styles.budgetLink}>Details</Text>
    </TouchableOpacity>
  </View>
  
  <View style={styles.budgetAmounts}>
    <View style={styles.budgetItem}>
      <Text style={styles.budgetLabel}>Estimated</Text>
      <Text style={styles.budgetValue}>{formatCurrency(budget.estimated)}</Text>
    </View>
    <View style={styles.budgetDivider} />
    <View style={styles.budgetItem}>
      <Text style={styles.budgetLabel}>Spent YTD</Text>
      <Text style={styles.budgetValue}>{formatCurrency(budget.spentYTD)}</Text>
    </View>
    <View style={styles.budgetDivider} />
    <View style={styles.budgetItem}>
      <Text style={styles.budgetLabel}>Upcoming</Text>
      <Text style={styles.budgetValue}>{formatCurrency(budget.upcoming)}</Text>
    </View>
  </View>

  {/* Progress bar */}
  <View style={styles.budgetProgress}>
    <View style={[styles.budgetProgressFill, { width: `${(budget.spentYTD / budget.estimated) * 100}%` }]} />
  </View>
</AnimatedCard>
```

### New Screen: `apps/mobile/app/(tabs)/maintenance/budget.tsx`

```tsx
export default function MaintenanceBudgetScreen() {
  return (
    <ScreenContainer title="Maintenance Budget">
      <ScrollView>
        {/* Annual Summary Card */}
        <Card style={styles.summaryCard}>
          <Text style={styles.summaryTitle}>2025 Maintenance Budget</Text>
          <Text style={styles.summaryAmount}>{formatCurrency(budget.total)}</Text>
          <Text style={styles.summarySubtext}>Based on your home systems and industry averages</Text>
        </Card>

        {/* Breakdown by Category */}
        <SectionHeader title="By Category" />
        {budgetByCategory.map(cat => (
          <CategoryBudgetRow
            key={cat.category}
            category={cat.category}
            estimated={cat.estimated}
            spent={cat.spent}
            upcoming={cat.upcoming}
          />
        ))}

        {/* Breakdown by System */}
        <SectionHeader title="By System" />
        {budgetBySystem.map(sys => (
          <SystemBudgetRow
            key={sys.systemId}
            system={sys}
            onPress={() => router.push(`/home/system/${sys.systemId}`)}
          />
        ))}

        {/* Upcoming Costs */}
        <SectionHeader title="Upcoming Maintenance Costs" />
        {upcomingTasks.map(task => (
          <UpcomingCostRow
            key={task.id}
            task={task}
            onPress={() => router.push(`/maintenance/${task.id}`)}
          />
        ))}

        {/* Historical Spending */}
        <SectionHeader title="Historical Spending" />
        <MonthlySpendingChart data={monthlySpending} />
      </ScrollView>
    </ScreenContainer>
  );
}
```

### API Endpoint

Create: `GET /api/maintenance/budget/:householdId`

```typescript
interface MaintenanceBudget {
  total: number;
  estimated: number;
  spentYTD: number;
  upcoming: number;
  byCategory: {
    category: string;
    estimated: number;
    spent: number;
    upcoming: number;
  }[];
  bySystem: {
    systemId: string;
    systemName: string;
    systemType: string;
    estimated: number;
    spent: number;
    upcoming: number;
  }[];
  upcomingTasks: {
    id: string;
    title: string;
    dueDate: string;
    estimatedCost: number;
    systemName: string;
  }[];
  monthlySpending: {
    month: string;
    amount: number;
  }[];
}
```

---

## Part 5: Smart Empty States

Update all empty states to be actionable and guide users.

### Dashboard Empty State

```tsx
// When user has < 3 systems, < 3 vendors, and < 5 bills

<View style={styles.getStartedCard}>
  <Text style={styles.getStartedTitle}>Let's Set Up Your Home</Text>
  <Text style={styles.getStartedSubtitle}>
    Complete these steps to get the most out of Haven
  </Text>

  <SetupStep
    icon="home"
    title="Add your home systems"
    subtitle="HVAC, water heater, appliances..."
    completed={systemCount >= 3}
    onPress={() => router.push('/home')}
  />

  <SetupStep
    icon="people"
    title="Add your vendors"
    subtitle="Plumber, electrician, landscaper..."
    completed={vendorCount >= 3}
    onPress={() => router.push('/manager/vendors')}
  />

  <SetupStep
    icon="card"
    title="Connect your bills"
    subtitle="We'll track and remind you"
    completed={billCount >= 5}
    onPress={() => router.push('/billing')}
  />

  {/* Free Walkthrough CTA if eligible */}
  {isEligibleForWalkthrough && (
    <TouchableOpacity style={styles.walkthroughCTA} onPress={scheduleWalkthrough}>
      <Ionicons name="sparkles" size={20} color={colors.white} />
      <Text style={styles.walkthroughCTAText}>
        Or schedule a free home walkthrough - we'll do it for you!
      </Text>
    </TouchableOpacity>
  )}
</View>
```

### Maintenance Empty State

```tsx
// When no maintenance tasks

<View style={styles.emptyContainer}>
  <Ionicons name="construct-outline" size={64} color={colors.haven.navy[200]} />
  <Text style={styles.emptyTitle}>No Maintenance Tasks Yet</Text>
  <Text style={styles.emptySubtitle}>
    Add your home systems and we'll automatically create a maintenance schedule
  </Text>

  <TouchableOpacity
    style={styles.emptyButton}
    onPress={() => router.push('/home')}
  >
    <Ionicons name="add-circle-outline" size={20} color={colors.white} />
    <Text style={styles.emptyButtonText}>Add Home Systems</Text>
  </TouchableOpacity>

  {isEligibleForWalkthrough && (
    <TouchableOpacity
      style={styles.emptySecondaryButton}
      onPress={scheduleWalkthrough}
    >
      <Text style={styles.emptySecondaryText}>
        Schedule Free Home Walkthrough
      </Text>
    </TouchableOpacity>
  )}
</View>
```

---

## Part 6: Navigation Updates

### Update Tab Bar

The current tabs are: Home | Manager | Chat | More

Update to prioritize home management:

```tsx
// apps/mobile/app/(tabs)/_layout.tsx

<Tabs.Screen
  name="index"
  options={{
    title: 'Dashboard',
    tabBarIcon: ({ color }) => <Ionicons name="home" size={24} color={color} />,
  }}
/>
<Tabs.Screen
  name="maintenance"
  options={{
    title: 'Maintenance',
    tabBarIcon: ({ color }) => <Ionicons name="construct" size={24} color={color} />,
  }}
/>
<Tabs.Screen
  name="chat"
  options={{
    title: 'Alfred',
    tabBarIcon: ({ color }) => <AlfredTabIcon size={24} color={color} />,
  }}
/>
<Tabs.Screen
  name="home"
  options={{
    title: 'My Home',
    tabBarIcon: ({ color }) => <Ionicons name="business" size={24} color={color} />,
  }}
/>
<Tabs.Screen
  name="more"
  options={{
    title: 'More',
    tabBarIcon: ({ color }) => <Ionicons name="menu" size={24} color={color} />,
  }}
/>
```

---

## Implementation Order

1. **Free Walkthrough Banner** (Day 1)
   - Create FreeWalkthroughBanner component
   - Add eligibility check API
   - Add to Dashboard, Maintenance, Home screens

2. **Vendor Search Update** (Day 1)
   - Update Find Vendors to show Alfred CTA
   - Create ServiceRequest flow for vendor recommendations
   - Add social recommendations link

3. **Home Manual** (Day 2-3)
   - Create manual.tsx screen with tabs
   - Create system/[id].tsx detail screen
   - Add navigation from Home screen

4. **Maintenance Budget** (Day 2)
   - Create budget API endpoint
   - Add budget card to Dashboard
   - Create budget.tsx detail screen

5. **Smart Empty States** (Day 3)
   - Update all empty states with actionable CTAs
   - Add walkthrough promotion where relevant
   - Add setup progress tracking

6. **Navigation Polish** (Day 3)
   - Update tab bar order
   - Ensure all flows are connected
   - Test complete user journeys

---

## Success Criteria

- [ ] New users in Fairfield CT / Westchester NY see free walkthrough banner
- [ ] Users with incomplete profiles see setup guidance
- [ ] Vendor search provides clear next action (Alfred assistance)
- [ ] Home Manual provides complete view of property
- [ ] Maintenance budget is visible and actionable
- [ ] All empty states guide users to add data
- [ ] Navigation prioritizes home management features
