# Fix Mobile UI: Consistent Headers, Navigation & Styling

## PROBLEM SUMMARY

Multiple screens have inconsistent headers, broken back buttons, and navigation issues. The goal is to make EVERY screen look like the correctly styled screens (Profile, Settings, Activity).

---

## REFERENCE: CORRECT HEADER STYLE

Looking at Profile, Settings, and Activity screens - the correct header style is:

```
┌─────────────────────────────────────────┐
│  7:21        [Dynamic Island]      ≋ 🔋  │  ← Status bar
├─────────────────────────────────────────┤
│  <          Screen Title                │  ← Navy header (#0a1929)
│                                         │     White text, centered title
│                                         │     Simple "<" back button (no background)
└─────────────────────────────────────────┘
```

**Correct Header Properties:**
- Background: Navy (#0a1929 or navy-950)
- Height: ~100px (including safe area padding)
- Title: White, centered, medium font weight
- Back button: White "<" chevron, NO grey background circle, left-aligned
- Consistent across ALL screens

---

## ISSUES TO FIX

### Issue 1: Grey Back Button Background
**Affected:** Maintenance → HVAC, possibly others
**Problem:** Back button has a grey circular background instead of being transparent
**Fix:** Remove background styling from back button, keep only the white chevron icon

### Issue 2: Missing Headers
**Affected:** Property & Zones, Document Vault, Approvals
**Problem:** These screens have no header at all - content starts immediately
**Fix:** Add the standard navy header with title and back button

### Issue 3: Excessive Whitespace on Nested Screens
**Affected:** Maintenance → HVAC (task detail), Maintenance → Systems → System detail
**Problem:** When navigating into a sub-screen, there's a double header effect with lots of whitespace
**Fix:** Nested screens should have a single header, not multiple stacked headers

### Issue 4: Inconsistent Header Blue Shade
**Affected:** Family & Household
**Problem:** Header blue is a different shade than other screens
**Fix:** Ensure all headers use exact same color: #0a1929 (navy-950)

### Issue 5: Document Vault Filter Pills Oversized
**Affected:** Document Vault
**Problem:** The "All", "Property", "Warranty" filter pills are too tall, taking up too much vertical space
**Fix:** Make filter pills compact height (~36px), not full-height vertical pills

### Issue 6: Back Button Navigation Wrong
**Affected:** Vendors screen
**Problem:** Pressing back from Vendors goes to Alfred tab instead of previous screen (More menu)
**Fix:** Ensure back navigation uses proper stack navigation (navigation.goBack()) not hardcoded routes

### Issue 7: Time Overlapping Content
**Affected:** Approvals screen
**Problem:** Status bar time "7:20" overlaps with "Pending" tab
**Fix:** Add proper safe area padding at top of screen

---

## STEP 1: Create a Reusable Header Component

Create a single, reusable header component that ALL screens use:

```typescript
// src/components/ScreenHeader.tsx
import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useNavigation } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';

interface ScreenHeaderProps {
  title: string;
  showBackButton?: boolean;
  onBackPress?: () => void;
  rightElement?: React.ReactNode;
}

export function ScreenHeader({ 
  title, 
  showBackButton = true, 
  onBackPress,
  rightElement 
}: ScreenHeaderProps) {
  const insets = useSafeAreaInsets();
  const navigation = useNavigation();

  const handleBack = () => {
    if (onBackPress) {
      onBackPress();
    } else if (navigation.canGoBack()) {
      navigation.goBack();
    }
  };

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      <View style={styles.content}>
        {/* Back Button */}
        <View style={styles.leftContainer}>
          {showBackButton && (
            <TouchableOpacity 
              onPress={handleBack} 
              style={styles.backButton}
              hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
            >
              <Ionicons name="chevron-back" size={28} color="#ffffff" />
            </TouchableOpacity>
          )}
        </View>

        {/* Title */}
        <Text style={styles.title} numberOfLines={1}>
          {title}
        </Text>

        {/* Right Element */}
        <View style={styles.rightContainer}>
          {rightElement}
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: '#0a1929', // navy-950 - EXACT color
  },
  content: {
    height: 56,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
  },
  leftContainer: {
    width: 40,
    alignItems: 'flex-start',
  },
  backButton: {
    // NO background color - transparent
    // NO borderRadius
    // NO padding that would create a visible container
    padding: 4,
  },
  title: {
    flex: 1,
    color: '#ffffff',
    fontSize: 18,
    fontWeight: '600',
    textAlign: 'center',
  },
  rightContainer: {
    width: 40,
    alignItems: 'flex-end',
  },
});
```

---

## STEP 2: Create Screen Container Component

Create a container that wraps all screens with consistent structure:

```typescript
// src/components/ScreenContainer.tsx
import React from 'react';
import { View, StyleSheet, ScrollView } from 'react-native';
import { ScreenHeader } from './ScreenHeader';

interface ScreenContainerProps {
  title: string;
  showBackButton?: boolean;
  onBackPress?: () => void;
  rightElement?: React.ReactNode;
  children: React.ReactNode;
  scrollable?: boolean;
  backgroundColor?: string;
}

export function ScreenContainer({
  title,
  showBackButton = true,
  onBackPress,
  rightElement,
  children,
  scrollable = true,
  backgroundColor = '#f9fafb', // gray-50
}: ScreenContainerProps) {
  const Content = scrollable ? ScrollView : View;

  return (
    <View style={styles.container}>
      <ScreenHeader
        title={title}
        showBackButton={showBackButton}
        onBackPress={onBackPress}
        rightElement={rightElement}
      />
      <Content 
        style={[styles.content, { backgroundColor }]}
        contentContainerStyle={scrollable ? styles.scrollContent : undefined}
      >
        {children}
      </Content>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0a1929', // Match header for status bar area
  },
  content: {
    flex: 1,
  },
  scrollContent: {
    flexGrow: 1,
  },
});
```

---

## STEP 3: Fix Each Broken Screen

### 3.1 Property & Zones Screen

```typescript
// Before: Missing header entirely
export default function PropertyZonesScreen() {
  return (
    <View>
      <Text>The Burke Family</Text>
      {/* content */}
    </View>
  );
}

// After: With proper header
import { ScreenContainer } from '@/components/ScreenContainer';

export default function PropertyZonesScreen() {
  return (
    <ScreenContainer title="Property & Zones">
      <View style={styles.content}>
        <Text style={styles.familyName}>The Burke Family</Text>
        {/* rest of content */}
      </View>
    </ScreenContainer>
  );
}
```

### 3.2 Document Vault Screen

```typescript
// Fix: Add header AND fix filter pills
import { ScreenContainer } from '@/components/ScreenContainer';

export default function DocumentVaultScreen() {
  return (
    <ScreenContainer title="Documents">
      {/* Filter Pills - HORIZONTAL, compact */}
      <View style={styles.filterContainer}>
        <ScrollView horizontal showsHorizontalScrollIndicator={false}>
          {categories.map(cat => (
            <TouchableOpacity
              key={cat.id}
              style={[
                styles.filterPill,
                selectedCategory === cat.id && styles.filterPillActive
              ]}
            >
              <Text style={styles.filterPillText}>{cat.name}</Text>
            </TouchableOpacity>
          ))}
        </ScrollView>
      </View>
      
      {/* Document list */}
      {/* ... */}
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  filterContainer: {
    paddingVertical: 12,
    paddingHorizontal: 16,
    backgroundColor: '#ffffff',
  },
  filterPill: {
    paddingHorizontal: 16,
    paddingVertical: 8,      // Compact height
    borderRadius: 20,
    backgroundColor: '#f3f4f6',
    marginRight: 8,
  },
  filterPillActive: {
    backgroundColor: '#0a1929',
  },
  filterPillText: {
    fontSize: 14,
    fontWeight: '500',
  },
});
```

### 3.3 Approvals Screen

```typescript
// Fix: Add header with proper safe area
import { ScreenContainer } from '@/components/ScreenContainer';

export default function ApprovalsScreen() {
  return (
    <ScreenContainer title="Approvals">
      {/* Tab selector */}
      <View style={styles.tabContainer}>
        <TouchableOpacity style={[styles.tab, styles.tabActive]}>
          <Text style={styles.tabTextActive}>Pending</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.tab}>
          <Text style={styles.tabText}>All</Text>
        </TouchableOpacity>
      </View>
      
      {/* Content */}
      {/* ... */}
    </ScreenContainer>
  );
}
```

### 3.4 Family Screen - Fix Header Color

```typescript
// Ensure header uses exact navy color
// Check if there's a custom header or if ScreenHeader is used with wrong color

// The header background MUST be: #0a1929
// Not: #102a43 or any other shade
```

### 3.5 Maintenance Task Detail - Fix Double Header

```typescript
// The issue is there's a "Maintenance" header followed by "HVAC" sub-header
// This creates excessive whitespace

// Solution: Single header with the specific screen title

// Before (broken):
// ┌─ Maintenance ─────────────────┐
// │                               │
// │  < HVAC                       │  ← Sub-header with whitespace
// │                               │
// └───────────────────────────────┘

// After (fixed):
// ┌─ HVAC ────────────────────────┐  ← Single header with screen title
// │  <                            │
// └───────────────────────────────┘

export default function MaintenanceTaskScreen({ route }) {
  const { task } = route.params;
  
  return (
    <ScreenContainer title={task.category || 'Task'}>  {/* e.g., "HVAC" */}
      {/* Task content directly, no sub-header */}
      <View style={styles.taskCard}>
        <Text style={styles.taskTitle}>{task.title}</Text>
        {/* ... */}
      </View>
    </ScreenContainer>
  );
}
```

### 3.6 Vendors Screen - Fix Back Navigation

```typescript
// The back button is using hardcoded navigation instead of goBack()

// Before (broken):
const handleBack = () => {
  navigation.navigate('Alfred');  // WRONG - hardcoded route
};

// After (fixed):
const handleBack = () => {
  navigation.goBack();  // Correct - goes to previous screen in stack
};

// Or just use the ScreenContainer which handles this automatically:
export default function VendorsScreen() {
  return (
    <ScreenContainer title="Vendors">
      {/* ScreenHeader inside ScreenContainer already uses navigation.goBack() */}
      {/* content */}
    </ScreenContainer>
  );
}
```

---

## STEP 4: Audit All Screens

Go through EVERY screen in the app and ensure it uses the ScreenContainer or ScreenHeader:

```bash
# Find all screen files
find apps/mobile/src -name "*Screen.tsx" -o -name "*screen.tsx"
find apps/mobile/app -name "*.tsx" | grep -v "_layout"

# Check which screens are NOT using ScreenContainer/ScreenHeader
grep -L "ScreenContainer\|ScreenHeader" apps/mobile/src/screens/*.tsx
```

### Screens to Check:
- [ ] Home (tab screen - may not need back button)
- [ ] Alfred (tab screen)
- [ ] Messages (tab screen)
- [ ] Money (tab screen)
- [ ] More (tab screen - may not need back button)
- [ ] Property & Zones ← NEEDS FIX
- [ ] Family & Household ← NEEDS FIX (color)
- [ ] Maintenance ← Check nested screens
- [ ] Maintenance Task Detail ← NEEDS FIX
- [ ] Maintenance System Detail ← NEEDS FIX
- [ ] Document Vault ← NEEDS FIX
- [ ] Vendors ← NEEDS FIX (navigation)
- [ ] Vendor Detail
- [ ] Add Vendor
- [ ] Approvals ← NEEDS FIX
- [ ] Profile ✓
- [ ] Settings ✓
- [ ] Activity ✓

---

## STEP 5: Update Global Styles

Ensure the navy color is defined consistently:

```typescript
// src/constants/colors.ts or theme.ts
export const colors = {
  navy: {
    950: '#0a1929',  // Primary header color - USE THIS
    900: '#102a43',
    800: '#243b53',
    // ...
  },
  // ...
};
```

Check that no screen is using a different blue:
```bash
# Find hardcoded blue colors that might not match
grep -rn "102a43\|1e3a5f\|0d2137" apps/mobile/src/ --include="*.tsx"
```

---

## STEP 6: Test All Navigation Paths

After fixes, test these flows:

1. **More → Property & Zones → Back** → Should return to More
2. **More → Family → Back** → Should return to More
3. **More → Documents → Back** → Should return to More
4. **More → Vendors → Back** → Should return to More (NOT Alfred)
5. **More → Vendors → Vendor Detail → Back** → Should return to Vendors
6. **Tasks → Maintenance Task → Back** → Should return to Tasks
7. **More → Approvals → Back** → Should return to More

---

## VERIFICATION CHECKLIST

### Header Consistency
- [ ] All headers use background color #0a1929
- [ ] All headers have same height (~56px content + safe area)
- [ ] All titles are white, centered, same font size (18px)
- [ ] All back buttons are white chevrons with NO background

### Back Button
- [ ] Back button has NO grey circle/background
- [ ] Back button uses `navigation.goBack()` not hardcoded routes
- [ ] Back button works correctly on all screens

### Screens Fixed
- [ ] Property & Zones - has header
- [ ] Document Vault - has header, compact filter pills
- [ ] Approvals - has header with safe area
- [ ] Family - correct header color
- [ ] Maintenance Task - no double header, no whitespace
- [ ] Vendors - back navigation works correctly

### No Double Headers
- [ ] Nested screens show single header only
- [ ] No excessive whitespace between navigation layers

---

## STEP 7: Test and Build

```bash
cd apps/mobile

# Clear cache and test
npx expo start --clear

# Test each screen, verify headers match

# Build when ready
eas build --platform ios --profile production
```
