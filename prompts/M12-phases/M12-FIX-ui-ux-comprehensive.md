# M12-FIX: COMPREHENSIVE UI/UX FIXES

## OVERVIEW

This prompt fixes critical UI/UX issues across the Haven mobile app:
1. Status bar / safe area issues (navy should extend to top edge)
2. Login screen logo cutoff
3. Broken detail screens (Vehicle, Pet, Staff)
4. Plaid connection error
5. Extra tabs in bottom navigation
6. Inconsistent header experience

---

# PHASE 1: CREATE CONSISTENT HEADER/SAFE AREA SYSTEM
=====================================================

The core issue is inconsistent handling of the iPhone's safe area (notch/Dynamic Island). 
We need the navy background to extend to the TOP EDGE of the screen while keeping content below the safe area.

## 1.1: Create a Unified Screen Container Component

File: `apps/mobile/src/components/ScreenContainer.tsx`

```tsx
import React from 'react';
import { View, StyleSheet, StatusBar, Platform } from 'react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';

interface ScreenContainerProps {
  children: React.ReactNode;
  // Background color for the area behind status bar
  statusBarBackground?: string;
  // Background color for main content area
  backgroundColor?: string;
  // Whether to show the default header
  showHeader?: boolean;
  // Custom header component
  header?: React.ReactNode;
}

const NAVY = '#0a1929';
const LIGHT_BG = '#f8fafc';

export function ScreenContainer({
  children,
  statusBarBackground = NAVY,
  backgroundColor = LIGHT_BG,
  header,
}: ScreenContainerProps) {
  const insets = useSafeAreaInsets();

  return (
    <View style={styles.container}>
      {/* Status bar configuration */}
      <StatusBar 
        barStyle="light-content" 
        backgroundColor={statusBarBackground}
        translucent={Platform.OS === 'android'}
      />
      
      {/* Background that extends behind status bar */}
      <View 
        style={[
          styles.statusBarBackground, 
          { 
            backgroundColor: statusBarBackground,
            height: insets.top,
          }
        ]} 
      />
      
      {/* Optional header */}
      {header && (
        <View style={[styles.headerContainer, { backgroundColor: statusBarBackground }]}>
          {header}
        </View>
      )}
      
      {/* Main content */}
      <View style={[styles.content, { backgroundColor }]}>
        {children}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  statusBarBackground: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    zIndex: 100,
  },
  headerContainer: {
    zIndex: 99,
  },
  content: {
    flex: 1,
  },
});
```

## 1.2: Create a Consistent Header Component

File: `apps/mobile/src/components/AppHeader.tsx`

```tsx
import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';

interface AppHeaderProps {
  title: string;
  showBack?: boolean;
  onBackPress?: () => void;
  rightAction?: React.ReactNode;
  backgroundColor?: string;
  textColor?: string;
}

const NAVY = '#0a1929';

export function AppHeader({
  title,
  showBack = false,
  onBackPress,
  rightAction,
  backgroundColor = NAVY,
  textColor = '#ffffff',
}: AppHeaderProps) {
  const router = useRouter();
  const insets = useSafeAreaInsets();

  const handleBack = () => {
    if (onBackPress) {
      onBackPress();
    } else if (router.canGoBack()) {
      router.back();
    }
  };

  return (
    <View style={[styles.container, { backgroundColor, paddingTop: insets.top }]}>
      <View style={styles.content}>
        {/* Left - Back button */}
        <View style={styles.leftSection}>
          {showBack && (
            <TouchableOpacity onPress={handleBack} style={styles.backButton}>
              <Ionicons name="chevron-back" size={24} color={textColor} />
            </TouchableOpacity>
          )}
        </View>

        {/* Center - Title */}
        <View style={styles.centerSection}>
          <Text style={[styles.title, { color: textColor }]} numberOfLines={1}>
            {title}
          </Text>
        </View>

        {/* Right - Optional action */}
        <View style={styles.rightSection}>
          {rightAction}
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    width: '100%',
  },
  content: {
    flexDirection: 'row',
    alignItems: 'center',
    height: 56,
    paddingHorizontal: 16,
  },
  leftSection: {
    width: 60,
    alignItems: 'flex-start',
  },
  centerSection: {
    flex: 1,
    alignItems: 'center',
  },
  rightSection: {
    width: 60,
    alignItems: 'flex-end',
  },
  backButton: {
    padding: 8,
    marginLeft: -8,
  },
  title: {
    fontSize: 17,
    fontWeight: '600',
  },
});
```

## 1.3: Create Dark Header Variant for Home Screen

The home screen has a special header with greeting, stats, etc. Create a wrapper:

File: `apps/mobile/src/components/HomeHeader.tsx`

```tsx
import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

interface HomeHeaderProps {
  children: React.ReactNode;
}

const NAVY = '#0a1929';

export function HomeHeader({ children }: HomeHeaderProps) {
  const insets = useSafeAreaInsets();

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      {children}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: NAVY,
    paddingBottom: 20,
  },
});
```

---

# PHASE 2: FIX HOME SCREEN (IMG_1774)
=====================================

The navy header must extend to the top edge of the screen.

File: `apps/mobile/app/(tabs)/index.tsx` or `apps/mobile/app/(tabs)/home.tsx`

Find the main home screen and update it:

```tsx
import { View, ScrollView, StyleSheet, StatusBar } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

export default function HomeScreen() {
  const insets = useSafeAreaInsets();

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor="#0a1929" />
      
      {/* Navy background that extends to top edge */}
      <View style={[styles.navyBackground, { paddingTop: insets.top }]}>
        {/* Date and weather row */}
        <View style={styles.topRow}>
          <Text style={styles.dateText}>Saturday, January 10</Text>
          <View style={styles.weatherBadge}>
            <Text style={styles.weatherText}>☀️ 68°</Text>
          </View>
        </View>
        
        {/* Greeting */}
        <Text style={styles.greeting}>Good evening, Tom</Text>
        <Text style={styles.subGreeting}>Your home is in great shape.</Text>
        
        {/* Stats cards */}
        <View style={styles.statsRow}>
          {/* ... stats ... */}
        </View>
      </View>
      
      {/* White content area */}
      <ScrollView style={styles.content}>
        {/* Today's Notes, Family, Quick Actions, Activity Feed */}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f8fafc',
  },
  navyBackground: {
    backgroundColor: '#0a1929',
    paddingHorizontal: 16,
    paddingBottom: 24,
  },
  // ... rest of styles
});
```

KEY CHANGE: Remove `<SafeAreaView>` wrapping the whole screen. Instead:
1. Set the container background
2. Use `useSafeAreaInsets()` to get the top inset
3. Add `paddingTop: insets.top` to the navy header

---

# PHASE 3: FIX LOGIN SCREEN (Logo Cutoff)
==========================================

The login screen logo is being cut off by the Dynamic Island/notch.

File: `apps/mobile/app/(auth)/login.tsx` or similar

```tsx
import { View, StyleSheet, StatusBar, KeyboardAvoidingView, Platform } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

export default function LoginScreen() {
  const insets = useSafeAreaInsets();

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor="#0a1929" />
      
      <KeyboardAvoidingView 
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        style={styles.keyboardView}
      >
        {/* Logo section - with safe area padding */}
        <View style={[styles.logoSection, { paddingTop: insets.top + 20 }]}>
          {/* Haven Logo */}
          <View style={styles.logoContainer}>
            <Image source={require('../../assets/logo.png')} style={styles.logo} />
          </View>
          <Text style={styles.brandName}>H A V E N</Text>
          <Text style={styles.tagline}>Home management, simplified</Text>
        </View>
        
        {/* Login form card */}
        <View style={styles.formCard}>
          {/* ... form content ... */}
        </View>
      </KeyboardAvoidingView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0a1929',
  },
  keyboardView: {
    flex: 1,
  },
  logoSection: {
    alignItems: 'center',
    paddingBottom: 30,
  },
  logoContainer: {
    width: 80,
    height: 80,
    // ... logo styles
  },
  // ... rest
});
```

KEY: Add `paddingTop: insets.top + 20` to push the logo below the notch.

---

# PHASE 4: FIX TASKS SCREEN (IMG_1773)
======================================

The Tasks screen header is going under the status bar.

File: `apps/mobile/app/(tabs)/maintenance/index.tsx` or similar

Apply the same pattern - use `useSafeAreaInsets()` and add paddingTop to the header.

---

# PHASE 5: FIX FAMILY SCREEN (IMG_1769)
=======================================

The "Invite to Household" banner is under the status bar.

File: `apps/mobile/app/(tabs)/family/index.tsx`

```tsx
import { useSafeAreaInsets } from 'react-native-safe-area-context';

export default function FamilyScreen() {
  const insets = useSafeAreaInsets();

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor="#0a1929" />
      
      {/* Header with proper safe area */}
      <View style={[styles.header, { paddingTop: insets.top }]}>
        <TouchableOpacity style={styles.inviteBanner}>
          {/* Invite to Household content */}
        </TouchableOpacity>
      </View>
      
      <ScrollView>
        {/* Family members list */}
      </ScrollView>
    </View>
  );
}
```

---

# PHASE 6: FIX BROKEN DETAIL SCREENS (IMG_1770, 1771, 1772)
===========================================================

Vehicle, Pet, and Staff detail screens show "Unable to Load" errors.
This means the API endpoints don't exist.

## 6.1: Check if API endpoints exist

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/api

# Check for vehicle endpoints
grep -rn "vehicle" src/ --include="*.ts" | grep -i "controller\|get\|post"

# Check for pet endpoints
grep -rn "pet" src/ --include="*.ts" | grep -i "controller\|get\|post"

# Check for staff endpoints
grep -rn "staff" src/ --include="*.ts" | grep -i "controller\|get\|post"
```

## 6.2: Create missing endpoints if needed

If these don't exist, create them:

File: `apps/api/src/households/households.controller.ts`

Add these endpoints:

```typescript
// GET /households/:householdId/vehicles/:vehicleId
@Get(':householdId/vehicles/:vehicleId')
async getVehicle(
  @Param('householdId') householdId: string,
  @Param('vehicleId') vehicleId: string,
) {
  return this.prisma.vehicle.findUnique({
    where: { id: vehicleId },
  });
}

// GET /households/:householdId/pets/:petId
@Get(':householdId/pets/:petId')
async getPet(
  @Param('householdId') householdId: string,
  @Param('petId') petId: string,
) {
  return this.prisma.pet.findUnique({
    where: { id: petId },
  });
}

// GET /households/:householdId/staff/:staffId
@Get(':householdId/staff/:staffId')
async getStaffMember(
  @Param('householdId') householdId: string,
  @Param('staffId') staffId: string,
) {
  return this.prisma.householdStaff.findUnique({
    where: { id: staffId },
  });
}
```

## 6.3: Update mobile screens to call correct endpoints

Check the mobile detail screens and ensure they're calling the right URLs.

---

# PHASE 7: FIX PLAID CONNECTION ERROR (IMG_1768)
=================================================

"Failed to create link token" means the backend Plaid endpoint is failing.

## 7.1: Check Plaid environment variables

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/api

# Check if Plaid env vars are set
cat .env | grep PLAID
cat .env.production | grep PLAID
```

Required variables:
```
PLAID_CLIENT_ID=your_client_id
PLAID_SECRET=your_secret
PLAID_ENV=sandbox
```

## 7.2: Check Cloud Run environment variables

```bash
gcloud run services describe haven-api --region=us-east1 --project=home-manager-480616 --format='yaml' | grep -A 50 'env:'
```

If PLAID variables are missing, add them:

```bash
gcloud run services update haven-api \
  --region=us-east1 \
  --project=home-manager-480616 \
  --set-env-vars="PLAID_CLIENT_ID=xxx,PLAID_SECRET=xxx,PLAID_ENV=sandbox"
```

## 7.3: Test Plaid endpoint locally

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/api
pnpm dev

# In another terminal, test the endpoint
curl -X POST http://localhost:4000/api/plaid/link-token \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"householdId": "test-household-id"}'
```

---

# PHASE 8: FIX BOTTOM TAB BAR (Extra broken tabs)
=================================================

The bottom navigation shows extra tabs (act..., ho..., ho..., ho..., ho...).

File: `apps/mobile/app/(tabs)/_layout.tsx`

## 8.1: Audit current tabs

```bash
cat /Users/tomburke/Projects/Housing-Manager/apps/mobile/app/\(tabs\)/_layout.tsx
```

## 8.2: Remove extra/broken tabs

The tabs should ONLY be:
1. Home
2. Alfred
3. Messages
4. Money
5. More

Update the _layout.tsx to only include these 5 tabs:

```tsx
import { Tabs } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';

export default function TabLayout() {
  return (
    <Tabs
      screenOptions={{
        tabBarActiveTintColor: '#c4a574',
        tabBarInactiveTintColor: '#64748b',
        tabBarStyle: {
          backgroundColor: '#ffffff',
          borderTopColor: '#e2e8f0',
          paddingBottom: 5,
          paddingTop: 5,
          height: 60,
        },
        headerShown: false, // We handle headers ourselves
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: 'Home',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="home-outline" size={size} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="alfred"
        options={{
          title: 'Alfred',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="sparkles-outline" size={size} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="messages"
        options={{
          title: 'Messages',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="chatbubble-outline" size={size} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="money"
        options={{
          title: 'Money',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="wallet-outline" size={size} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="more"
        options={{
          title: 'More',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="menu-outline" size={size} color={color} />
          ),
        }}
      />
      
      {/* HIDE these screens from tab bar - they're accessed via navigation */}
      <Tabs.Screen name="family" options={{ href: null }} />
      <Tabs.Screen name="home" options={{ href: null }} />
      <Tabs.Screen name="maintenance" options={{ href: null }} />
      <Tabs.Screen name="activity" options={{ href: null }} />
      {/* Add any other screens that should be hidden from tabs */}
    </Tabs>
  );
}
```

KEY: Use `href: null` to hide screens from the tab bar while keeping them navigable.

---

# PHASE 9: DEPLOY AND TEST
===========================

After all fixes:

1. Test locally in simulator:
```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile
npx expo start --clear --ios
```

2. Verify each fix:
- [ ] Home screen - navy extends to top edge
- [ ] Login screen - logo not cut off
- [ ] Tasks screen - no overlap with status bar
- [ ] Family screen - no overlap with status bar
- [ ] Vehicle/Pet/Staff detail screens load
- [ ] Bottom tab bar shows only 5 tabs
- [ ] Plaid connection works (after env vars set)

3. Deploy API if backend changes made:
```bash
cd /Users/tomburke/Projects/Housing-Manager
gcloud builds submit --config=cloudbuild-api.yaml --project=home-manager-480616
```

4. Build for TestFlight:
```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile
eas build --platform ios --profile production --auto-submit
```

---

# SUMMARY OF CHANGES

| Issue | Fix |
|-------|-----|
| Navy not extending to top | Use `useSafeAreaInsets()` + `paddingTop` on navy container |
| Login logo cutoff | Add `paddingTop: insets.top + 20` to logo section |
| Status bar overlap | Apply safe area insets to all headers |
| Vehicle/Pet/Staff broken | Add API endpoints for detail views |
| Plaid error | Set PLAID env vars in Cloud Run |
| Extra tabs | Use `href: null` to hide non-tab screens |
