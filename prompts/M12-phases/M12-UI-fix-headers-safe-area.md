# M12-UI: FIX SAFE AREA, HEADERS & API ERRORS

## OVERVIEW

This prompt fixes critical UI/UX issues across the Haven mobile app:

1. **Safe Area Issues** - Headers don't extend to screen edge, overlap with status bar
2. **Inconsistent Headers** - Different screens have different header implementations
3. **API Failures** - Pet, Vehicle, Staff detail screens fail to load
4. **Plaid Error** - "Failed to create link token" when connecting bank

---

## PART 1: CREATE UNIFIED SCREEN HEADER COMPONENT

### Problem
- Navy blue doesn't extend to top edge of screen
- Content overlaps with system status bar (time, wifi, battery)
- Inconsistent header styling across screens

### Solution
Create a reusable `ScreenHeader` component that properly handles safe areas.

**File:** `apps/mobile/src/components/ScreenHeader.tsx`

```tsx
import React from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  StatusBar,
  Platform,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';

interface ScreenHeaderProps {
  title: string;
  showBackButton?: boolean;
  onBackPress?: () => void;
  rightAction?: React.ReactNode;
  variant?: 'navy' | 'white' | 'transparent';
  subtitle?: string;
}

export function ScreenHeader({
  title,
  showBackButton = true,
  onBackPress,
  rightAction,
  variant = 'navy',
  subtitle,
}: ScreenHeaderProps) {
  const insets = useSafeAreaInsets();
  const router = useRouter();

  const handleBack = () => {
    if (onBackPress) {
      onBackPress();
    } else if (router.canGoBack()) {
      router.back();
    }
  };

  const isNavy = variant === 'navy';
  const isTransparent = variant === 'transparent';

  return (
    <>
      {/* Set status bar style based on variant */}
      <StatusBar
        barStyle={isNavy || isTransparent ? 'light-content' : 'dark-content'}
        backgroundColor="transparent"
        translucent
      />
      
      {/* Background that extends under status bar */}
      <View
        style={[
          styles.headerBackground,
          {
            paddingTop: insets.top,
            backgroundColor: isNavy ? '#0a1929' : isTransparent ? 'transparent' : '#ffffff',
          },
        ]}
      >
        {/* Header content - positioned below safe area */}
        <View style={styles.headerContent}>
          {/* Left - Back Button */}
          <View style={styles.leftSection}>
            {showBackButton && (
              <TouchableOpacity
                style={styles.backButton}
                onPress={handleBack}
                hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
              >
                <Ionicons
                  name="chevron-back"
                  size={24}
                  color={isNavy ? '#ffffff' : '#0f172a'}
                />
                {Platform.OS === 'ios' && (
                  <Text style={[styles.backText, !isNavy && styles.backTextDark]}>
                    Back
                  </Text>
                )}
              </TouchableOpacity>
            )}
          </View>

          {/* Center - Title */}
          <View style={styles.centerSection}>
            <Text
              style={[styles.title, !isNavy && styles.titleDark]}
              numberOfLines={1}
            >
              {title}
            </Text>
            {subtitle && (
              <Text style={[styles.subtitle, !isNavy && styles.subtitleDark]}>
                {subtitle}
              </Text>
            )}
          </View>

          {/* Right - Action */}
          <View style={styles.rightSection}>
            {rightAction}
          </View>
        </View>
      </View>
    </>
  );
}

const styles = StyleSheet.create({
  headerBackground: {
    width: '100%',
  },
  headerContent: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    height: 56,
    paddingHorizontal: 8,
  },
  leftSection: {
    width: 80,
    alignItems: 'flex-start',
  },
  centerSection: {
    flex: 1,
    alignItems: 'center',
  },
  rightSection: {
    width: 80,
    alignItems: 'flex-end',
    paddingRight: 8,
  },
  backButton: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 8,
    paddingHorizontal: 4,
  },
  backText: {
    fontSize: 17,
    color: '#ffffff',
    marginLeft: 4,
  },
  backTextDark: {
    color: '#0f172a',
  },
  title: {
    fontSize: 17,
    fontWeight: '600',
    color: '#ffffff',
    textAlign: 'center',
  },
  titleDark: {
    color: '#0f172a',
  },
  subtitle: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
    marginTop: 2,
  },
  subtitleDark: {
    color: '#64748b',
  },
});
```

---

## PART 2: CREATE HOME SCREEN HEADER (SPECIAL VARIANT)

The home screen has a special header with greeting, stats, etc. Create a dedicated component.

**File:** `apps/mobile/src/components/HomeHeader.tsx`

```tsx
import React from 'react';
import { View, Text, StyleSheet, StatusBar } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';

interface HomeHeaderProps {
  userName: string;
  greeting: string;
  subtitle: string;
  weather?: { temp: number; icon: string };
  stats: {
    homeHealth: { value: string; label: string };
    billsPaid: { value: string; label: string };
    nextService: { value: string; label: string };
  };
}

export function HomeHeader({
  userName,
  greeting,
  subtitle,
  weather,
  stats,
}: HomeHeaderProps) {
  const insets = useSafeAreaInsets();

  return (
    <>
      <StatusBar barStyle="light-content" backgroundColor="#0a1929" translucent />
      
      {/* Navy background that extends to screen edge */}
      <View style={[styles.container, { paddingTop: insets.top }]}>
        {/* Date and Weather Row */}
        <View style={styles.topRow}>
          <Text style={styles.dateText}>
            {new Date().toLocaleDateString('en-US', {
              weekday: 'long',
              month: 'long',
              day: 'numeric',
            })}
          </Text>
          {weather && (
            <View style={styles.weatherContainer}>
              <Ionicons name="sunny" size={16} color="#fbbf24" />
              <Text style={styles.weatherText}>{weather.temp}°</Text>
            </View>
          )}
        </View>

        {/* Greeting */}
        <Text style={styles.greeting}>{greeting}, {userName}</Text>
        <Text style={styles.subtitle}>{subtitle}</Text>

        {/* Stats Row */}
        <View style={styles.statsRow}>
          <View style={styles.statCard}>
            <Text style={styles.statLabel}>{stats.homeHealth.label}</Text>
            <View style={styles.statValueRow}>
              <Text style={styles.statValue}>{stats.homeHealth.value}</Text>
              <View style={styles.badge}>
                <Text style={styles.badgeText}>Excellent</Text>
              </View>
            </View>
          </View>
          <View style={styles.statCard}>
            <Text style={styles.statLabel}>{stats.billsPaid.label}</Text>
            <Text style={styles.statValue}>{stats.billsPaid.value}</Text>
          </View>
          <View style={styles.statCard}>
            <Text style={styles.statLabel}>{stats.nextService.label}</Text>
            <Text style={styles.statValue}>{stats.nextService.value}</Text>
          </View>
        </View>
      </View>
    </>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: '#0a1929',
    paddingHorizontal: 16,
    paddingBottom: 20,
    borderBottomLeftRadius: 24,
    borderBottomRightRadius: 24,
  },
  topRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 8,
    marginBottom: 12,
  },
  dateText: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.8)',
  },
  weatherContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 12,
    gap: 4,
  },
  weatherText: {
    fontSize: 14,
    color: '#ffffff',
    fontWeight: '500',
  },
  greeting: {
    fontSize: 28,
    fontWeight: '700',
    color: '#ffffff',
    marginBottom: 4,
  },
  subtitle: {
    fontSize: 15,
    color: 'rgba(255, 255, 255, 0.7)',
    marginBottom: 16,
  },
  statsRow: {
    flexDirection: 'row',
    gap: 8,
  },
  statCard: {
    flex: 1,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    borderRadius: 12,
    padding: 12,
  },
  statLabel: {
    fontSize: 11,
    color: 'rgba(255, 255, 255, 0.7)',
    marginBottom: 4,
  },
  statValueRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  statValue: {
    fontSize: 18,
    fontWeight: '700',
    color: '#4ade80',
  },
  badge: {
    backgroundColor: '#4ade80',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
  },
  badgeText: {
    fontSize: 10,
    fontWeight: '600',
    color: '#0a1929',
  },
});
```

---

## PART 3: FIX LOGIN SCREEN LOGO CUTOFF

**File:** `apps/mobile/app/(auth)/login.tsx` or similar

The logo is being cut off by the iPhone notch/Dynamic Island. Fix by:

1. Using SafeAreaView properly
2. Adding proper top padding

```tsx
import { useSafeAreaInsets } from 'react-native-safe-area-context';

export default function LoginScreen() {
  const insets = useSafeAreaInsets();

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" />
      
      {/* Logo section - add top inset padding */}
      <View style={[styles.logoSection, { paddingTop: insets.top + 20 }]}>
        <Image source={require('../assets/logo.png')} style={styles.logo} />
        <Text style={styles.title}>HAVEN</Text>
        <Text style={styles.tagline}>Home management, simplified</Text>
      </View>
      
      {/* Rest of login form */}
      <View style={styles.formSection}>
        {/* ... */}
      </View>
    </View>
  );
}
```

Find the actual login file:
```bash
find /Users/tomburke/Projects/Housing-Manager/apps/mobile -name "*.tsx" | xargs grep -l "Sign in with Apple\|Welcome back" | head -5
```

Then update it to use safe area insets for the logo.

---

## PART 4: FIX FAMILY DETAIL SCREENS (Pet, Vehicle, Staff)

These screens show "Unable to Load" because the API endpoints don't exist or aren't working.

### Step 4.1: Check what endpoints are being called

```bash
# Find the Pet detail screen
grep -rn "pet\|Pet" /Users/tomburke/Projects/Housing-Manager/apps/mobile/app/ --include="*.tsx" | grep -i "fetch\|api\|API_BASE"
```

### Step 4.2: Check if API endpoints exist

```bash
# Check for pet endpoints in API
grep -rn "pet\|Pet" /Users/tomburke/Projects/Housing-Manager/apps/api/src/ --include="*.ts" | head -20

# Check for vehicle endpoints
grep -rn "vehicle\|Vehicle" /Users/tomburke/Projects/Housing-Manager/apps/api/src/ --include="*.ts" | head -20

# Check for staff endpoints  
grep -rn "staff\|Staff" /Users/tomburke/Projects/Housing-Manager/apps/api/src/ --include="*.ts" | head -20
```

### Step 4.3: Create missing endpoints if needed

If endpoints don't exist, create them:

**File:** `apps/api/src/households/households.controller.ts`

Add these endpoints:

```typescript
// GET /households/:id/pets/:petId
@Get(':id/pets/:petId')
async getPet(
  @Param('id') householdId: string,
  @Param('petId') petId: string,
) {
  return this.prisma.pet.findFirst({
    where: { id: petId, householdId },
  });
}

// GET /households/:id/vehicles/:vehicleId
@Get(':id/vehicles/:vehicleId')
async getVehicle(
  @Param('id') householdId: string,
  @Param('vehicleId') vehicleId: string,
) {
  return this.prisma.vehicle.findFirst({
    where: { id: vehicleId, householdId },
  });
}

// GET /households/:id/staff/:staffId
@Get(':id/staff/:staffId')
async getStaffMember(
  @Param('id') householdId: string,
  @Param('staffId') staffId: string,
) {
  return this.prisma.householdStaff.findFirst({
    where: { id: staffId, householdId },
  });
}
```

### Step 4.4: Fix mobile screens to use correct endpoints

Check each detail screen and ensure it's calling the right endpoint with the right parameters.

---

## PART 5: FIX PLAID "FAILED TO CREATE LINK TOKEN" ERROR

This error means the Plaid API isn't configured properly in production.

### Step 5.1: Check Plaid environment variables

```bash
# Check if Plaid vars are in Cloud Run
gcloud run services describe haven-api --region=us-east1 --project=home-manager-480616 --format='yaml' | grep -i plaid
```

Required environment variables:
- `PLAID_CLIENT_ID`
- `PLAID_SECRET`
- `PLAID_ENV` (sandbox, development, or production)

### Step 5.2: Verify Plaid credentials

```bash
# Check local .env
cat /Users/tomburke/Projects/Housing-Manager/apps/api/.env | grep -i plaid
```

### Step 5.3: If Plaid isn't configured, add placeholder behavior

If you don't have Plaid credentials yet, the app should gracefully handle this:

**File:** `apps/api/src/plaid/plaid.controller.ts`

```typescript
@Post('link-token')
async createLinkToken(@Body() body: { householdId: string }) {
  // Check if Plaid is configured
  if (!process.env.PLAID_CLIENT_ID || !process.env.PLAID_SECRET) {
    throw new BadRequestException(
      'Bank connection is not yet available. Please check back soon.'
    );
  }
  
  // ... rest of implementation
}
```

**Mobile side - show better error:**

```typescript
const handleConnectBank = async () => {
  try {
    // ... existing code
  } catch (error) {
    const message = error.message?.includes('not yet available')
      ? 'Bank connection coming soon! We\'re still setting this up.'
      : 'Failed to connect bank. Please try again.';
    Alert.alert('Connection Error', message);
  }
};
```

---

## PART 6: UPDATE ALL SCREENS TO USE NEW HEADER

After creating the ScreenHeader component, update all screens:

### Screens that need ScreenHeader (navy variant):
- Tasks screen (`IMG_1773`)
- Family detail screens (Pet, Vehicle, Staff, Family Member)
- Vendor screens
- Settings screens

### Example update for Tasks screen:

```tsx
import { ScreenHeader } from '../../src/components/ScreenHeader';

export default function TasksScreen() {
  return (
    <View style={styles.container}>
      <ScreenHeader title="Tasks" showBackButton={false} />
      
      {/* Tab bar */}
      <View style={styles.tabBar}>
        {/* All, Upcoming, Overdue tabs */}
      </View>
      
      {/* Task list */}
      <FlatList ... />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f8fafc',
  },
  // Remove any existing header styles
});
```

---

## PART 7: UPDATE HOME SCREEN

Replace the current header with the new HomeHeader component:

```tsx
import { HomeHeader } from '../../src/components/HomeHeader';

export default function HomeScreen() {
  return (
    <View style={styles.container}>
      <HomeHeader
        userName="Tom"
        greeting="Good evening"
        subtitle="Your home is in great shape."
        weather={{ temp: 68, icon: 'sunny' }}
        stats={{
          homeHealth: { value: '92%', label: 'Home Health' },
          billsPaid: { value: '0', label: 'Bills Paid' },
          nextService: { value: '—', label: 'Next Service' },
        }}
      />
      
      <ScrollView style={styles.content}>
        {/* Today's Notes, Family, Quick Actions, etc. */}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f8fafc',
  },
  content: {
    flex: 1,
  },
});
```

---

## VERIFICATION CHECKLIST

After implementation, verify:

1. [ ] Home screen - Navy blue extends to top edge of screen (no white gap)
2. [ ] Home screen - Status bar icons (time, wifi, battery) are white/visible
3. [ ] Login screen - Logo is not cut off by notch
4. [ ] Tasks screen - Header doesn't overlap status bar
5. [ ] Family screen - Header doesn't overlap status bar
6. [ ] Pet detail screen - Loads data (or shows proper error)
7. [ ] Vehicle detail screen - Loads data (or shows proper error)
8. [ ] Staff detail screen - Loads data (or shows proper error)
9. [ ] Bank connection - Shows friendly message if Plaid not configured
10. [ ] Back button - Works correctly on all screens
11. [ ] All screens have consistent header styling

---

## FILES TO MODIFY

New files:
- `apps/mobile/src/components/ScreenHeader.tsx`
- `apps/mobile/src/components/HomeHeader.tsx`

Files to update:
- `apps/mobile/app/(tabs)/index.tsx` (or home screen)
- `apps/mobile/app/(tabs)/family/index.tsx`
- `apps/mobile/app/(tabs)/family/[id].tsx`
- `apps/mobile/app/(tabs)/home/pets/[id].tsx`
- `apps/mobile/app/(tabs)/home/vehicles/[id].tsx`
- `apps/mobile/app/(tabs)/home/staff/[id].tsx`
- `apps/mobile/app/(auth)/login.tsx`
- All screens with headers

API files:
- `apps/api/src/households/households.controller.ts` (add pet/vehicle/staff endpoints)
- `apps/api/src/plaid/plaid.controller.ts` (better error handling)

---

## RUN THIS PROMPT

```
Read and execute /Users/tomburke/Projects/Housing-Manager/prompts/M12-phases/M12-UI-fix-headers-safe-area.md

CRITICAL:
- Create the ScreenHeader and HomeHeader components FIRST
- Then update screens to use them
- Test each screen in iOS simulator
- The navy blue must extend to the TOP EDGE of the screen
- Status bar icons must be visible (white on navy)
- No content should overlap the status bar
```
