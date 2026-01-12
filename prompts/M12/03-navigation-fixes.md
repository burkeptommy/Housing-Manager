# M12-03: FIX NAVIGATION - BACK BUTTON & CLICKABLE FAMILY ICONS

## CRITICAL INSTRUCTIONS

**DO NOT** say "navigation works correctly" without testing every single flow.

**YOU MUST:**
1. Test the back button from at least 5 different screens
2. Document which screen you were on and where the back button took you
3. If ANY back button goes to home instead of the previous screen → FIX IT

---

## PROBLEM STATEMENT

**Issue 1:** Back button on many screens goes to the Home tab instead of the previous screen in the navigation stack.

**Issue 2:** Family member icons/avatars on the Home screen are not tappable - they should navigate to the family member detail page.

---

## STEP 1: Audit Current Navigation Behavior

Test these flows manually in the simulator and document the results:

| Start Screen | Action | Expected Destination | Actual Destination |
|--------------|--------|---------------------|-------------------|
| Home → Family → Member Detail | Tap Back | Family list | ??? |
| Home → Maintenance → Task Detail | Tap Back | Maintenance list | ??? |
| Home → Billing → Add Bill | Tap Back | Billing | ??? |
| Home → Home Tab → Zones → Zone Detail | Tap Back | Zones list | ??? |
| Alfred → (any navigation) | Tap Back | Alfred | ??? |

Fill in "Actual Destination" by testing in the simulator.

---

## STEP 2: Find the Root Cause

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Find all uses of router.replace (this might be the culprit)
echo "=== ROUTER.REPLACE USAGE ==="
grep -rn "router\.replace" app/ --include="*.tsx" | head -20

# Find all uses of router.push
echo "=== ROUTER.PUSH USAGE ==="
grep -rn "router\.push" app/ --include="*.tsx" | head -20

# Find custom back button implementations
echo "=== BACK BUTTON IMPLEMENTATIONS ==="
grep -rn "router\.back\|goBack\|canGoBack" app/ --include="*.tsx" | head -20

# Find hardcoded navigation to home
echo "=== HARDCODED HOME NAVIGATION ==="
grep -rn "/(tabs)\|/home\|router.*home" app/ --include="*.tsx" | grep -v "node_modules" | head -20
```

**COMMON CAUSES:**
1. Using `router.replace()` instead of `router.push()` for normal navigation
2. Custom back buttons that hardcode `router.push('/(tabs)')` instead of `router.back()`
3. Missing navigation stack due to incorrect route structure

---

## STEP 3: Fix Back Button Navigation

### 3A: Create a Reusable Back Button Component

Create `apps/mobile/src/components/BackButton.tsx`:

```tsx
import React from 'react';
import { TouchableOpacity, Text, StyleSheet, View } from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { colors, spacing, typography } from '../lib/theme';

interface BackButtonProps {
  label?: string;
  fallbackRoute?: string;
}

export function BackButton({ label = 'Back', fallbackRoute = '/(tabs)' }: BackButtonProps) {
  const router = useRouter();

  const handleBack = () => {
    // Always try to go back in the stack first
    if (router.canGoBack()) {
      router.back();
    } else {
      // Only use fallback if there's no back history
      router.replace(fallbackRoute);
    }
  };

  return (
    <TouchableOpacity 
      style={styles.container} 
      onPress={handleBack}
      hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
    >
      <Ionicons name="chevron-back" size={24} color={colors.haven.champagne[500]} />
      <Text style={styles.label}>{label}</Text>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[2],
  },
  label: {
    fontSize: typography.fontSizes.base,
    color: colors.haven.champagne[500],
    marginLeft: spacing[1],
  },
});
```

### 3B: Fix All Screens with Custom Back Navigation

Search and fix any screen that has hardcoded back navigation:

```bash
# Find screens with potential issues
grep -rn "router\.\(push\|replace\).*\(tabs\)" app/ --include="*.tsx"
```

**REPLACE** any code like this:
```typescript
// BAD - Hardcoded route
const handleBack = () => {
  router.push('/(tabs)');
};

// BAD - Replace instead of back
const handleBack = () => {
  router.replace('/(tabs)/family');
};
```

**WITH** this:
```typescript
// GOOD - Respects navigation stack
const handleBack = () => {
  if (router.canGoBack()) {
    router.back();
  } else {
    router.replace('/(tabs)');
  }
};
```

### 3C: Check Route Structure

Ensure nested routes are set up correctly in `app/(tabs)/_layout.tsx`:

```tsx
import { Tabs } from 'expo-router';

export default function TabsLayout() {
  return (
    <Tabs
      screenOptions={{
        // Ensure the tab bar doesn't interfere with back navigation
        headerShown: false,
      }}
    >
      <Tabs.Screen name="index" options={{ title: 'Home' }} />
      <Tabs.Screen name="alfred" options={{ title: 'Alfred' }} />
      <Tabs.Screen name="family" options={{ title: 'Family' }} />
      <Tabs.Screen name="billing" options={{ title: 'Bills' }} />
      <Tabs.Screen name="maintenance" options={{ title: 'Tasks' }} />
      {/* etc */}
    </Tabs>
  );
}
```

For nested routes like `family/[id].tsx`, ensure the Stack is configured:

```tsx
// In app/(tabs)/family/_layout.tsx
import { Stack } from 'expo-router';

export default function FamilyLayout() {
  return (
    <Stack
      screenOptions={{
        headerBackTitle: 'Back',
        // This ensures proper back navigation
      }}
    >
      <Stack.Screen name="index" options={{ title: 'Family' }} />
      <Stack.Screen name="[id]" options={{ title: 'Details' }} />
    </Stack>
  );
}
```

---

## STEP 4: Make Family Icons Clickable on Home Screen

### 4A: Find the Family Section on Home Screen

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Find where family members are displayed on home
grep -rn "family\|member\|avatar" app/\(tabs\)/index.tsx app/\(tabs\)/home.tsx app/\(tabs\)/home/index.tsx 2>/dev/null | head -30
```

### 4B: Update Family Members Section

Find the section that displays family members and make them tappable:

```tsx
// Find the family members section (likely looks something like this)
// and wrap each member in TouchableOpacity

import { TouchableOpacity } from 'react-native';
import { useRouter } from 'expo-router';

// Inside the component:
const router = useRouter();

// In the JSX where family members are rendered:
<View style={styles.familySection}>
  <View style={styles.sectionHeader}>
    <Text style={styles.sectionTitle}>Family</Text>
    <TouchableOpacity onPress={() => router.push('/(tabs)/family')}>
      <Text style={styles.seeAllLink}>See All</Text>
    </TouchableOpacity>
  </View>
  
  <ScrollView 
    horizontal 
    showsHorizontalScrollIndicator={false}
    contentContainerStyle={styles.familyScroll}
  >
    {familyMembers.map((member) => (
      <TouchableOpacity
        key={member.id}
        style={styles.familyMemberCard}
        onPress={() => router.push(`/(tabs)/family/${member.id}`)}
        activeOpacity={0.7}
      >
        {member.profilePhotoUrl ? (
          <Image 
            source={{ uri: member.profilePhotoUrl }} 
            style={styles.familyMemberPhoto}
          />
        ) : (
          <View style={styles.familyMemberPhotoPlaceholder}>
            <Text style={styles.familyMemberInitials}>
              {member.firstName[0]}{member.lastName[0]}
            </Text>
          </View>
        )}
        <Text style={styles.familyMemberName} numberOfLines={1}>
          {member.firstName}
        </Text>
        <Text style={styles.familyMemberRole} numberOfLines={1}>
          {member.relationship || member.role}
        </Text>
      </TouchableOpacity>
    ))}
    
    {/* Add Family Member Button */}
    <TouchableOpacity
      style={styles.addFamilyMemberCard}
      onPress={() => router.push('/(tabs)/family/add')}
    >
      <View style={styles.addFamilyMemberIcon}>
        <Ionicons name="add" size={24} color={colors.haven.champagne[500]} />
      </View>
      <Text style={styles.addFamilyMemberText}>Add</Text>
    </TouchableOpacity>
  </ScrollView>
</View>
```

Add these styles:

```typescript
familySection: {
  marginTop: spacing[6],
},
sectionHeader: {
  flexDirection: 'row',
  justifyContent: 'space-between',
  alignItems: 'center',
  paddingHorizontal: spacing[4],
  marginBottom: spacing[3],
},
sectionTitle: {
  fontSize: typography.fontSizes.lg,
  fontWeight: typography.fontWeights.semibold,
  color: colors.slate[900],
},
seeAllLink: {
  fontSize: typography.fontSizes.sm,
  color: colors.haven.champagne[500],
  fontWeight: typography.fontWeights.medium,
},
familyScroll: {
  paddingHorizontal: spacing[4],
  gap: spacing[3],
},
familyMemberCard: {
  alignItems: 'center',
  width: 80,
},
familyMemberPhoto: {
  width: 60,
  height: 60,
  borderRadius: 30,
  marginBottom: spacing[2],
},
familyMemberPhotoPlaceholder: {
  width: 60,
  height: 60,
  borderRadius: 30,
  backgroundColor: colors.haven.champagne[100],
  alignItems: 'center',
  justifyContent: 'center',
  marginBottom: spacing[2],
},
familyMemberInitials: {
  fontSize: typography.fontSizes.lg,
  fontWeight: typography.fontWeights.semibold,
  color: colors.haven.champagne[600],
},
familyMemberName: {
  fontSize: typography.fontSizes.sm,
  fontWeight: typography.fontWeights.medium,
  color: colors.slate[900],
  textAlign: 'center',
},
familyMemberRole: {
  fontSize: typography.fontSizes.xs,
  color: colors.slate[500],
  textAlign: 'center',
},
addFamilyMemberCard: {
  alignItems: 'center',
  width: 80,
},
addFamilyMemberIcon: {
  width: 60,
  height: 60,
  borderRadius: 30,
  borderWidth: 2,
  borderColor: colors.haven.champagne[300],
  borderStyle: 'dashed',
  alignItems: 'center',
  justifyContent: 'center',
  marginBottom: spacing[2],
},
addFamilyMemberText: {
  fontSize: typography.fontSizes.sm,
  color: colors.haven.champagne[500],
  fontWeight: typography.fontWeights.medium,
},
```

---

## STEP 5: Test in Simulator

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile
npx expo start --clear --ios
```

**MANUAL TEST CHECKLIST - DOCUMENT EACH RESULT:**

### Back Button Tests

| Test # | Flow | Back Button Works? |
|--------|------|-------------------|
| 1 | Home → Family tab → Tap member → Back | [ ] YES [ ] NO |
| 2 | Home → Billing tab → Tap bill → Back | [ ] YES [ ] NO |
| 3 | Home → Maintenance → Tap task → Back | [ ] YES [ ] NO |
| 4 | Home → Your Home → Zones → Zone detail → Back | [ ] YES [ ] NO |
| 5 | Alfred tab → (any sub-screen) → Back | [ ] YES [ ] NO |

### Family Icons Tests

| Test # | Action | Expected | Works? |
|--------|--------|----------|--------|
| 1 | Tap family member photo on Home | Opens member detail | [ ] YES [ ] NO |
| 2 | Tap "Add" button in family row | Opens add member screen | [ ] YES [ ] NO |
| 3 | Tap "See All" in family section | Opens Family tab | [ ] YES [ ] NO |

---

## DELIVERABLES

1. Completed test tables above with actual results
2. List of files that were modified
3. Confirmation that all back buttons now work correctly
4. Confirmation that family icons are tappable
