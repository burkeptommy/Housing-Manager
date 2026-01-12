# M12-3: FIX NAVIGATION - BACK BUTTON & CLICKABLE FAMILY ICONS

## CRITICAL INSTRUCTIONS

**DO NOT** say "already works". Actually test by:
1. Navigate from Home → Family → Family Member Detail
2. Press Back button
3. If it goes to Home instead of Family list, IT'S BROKEN

---

## PROBLEM STATEMENT

1. **Back button goes to home page instead of previous screen**
   - User navigates: Home → Settings → Profile
   - User taps back
   - Expected: Go to Settings
   - Actual: Goes to Home

2. **Family member icons on home screen are not tappable**
   - Home screen shows family member avatars
   - Tapping them does nothing
   - Should navigate to that family member's detail page

---

## REQUIRED DELIVERABLES

### 1. Audit Current Navigation Usage

Run this to find problematic navigation:
```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Find all router.replace calls (these break back button)
grep -rn "router.replace" app/ --include="*.tsx"

# Find all custom back button handlers
grep -rn "goBack\|router.back\|headerLeft" app/ --include="*.tsx"
```

### 2. Fix Navigation Pattern

**RULE:** Only use `router.replace()` for:
- Auth redirects (login → home after auth)
- Replacing current screen entirely (wizard steps)

**For normal navigation, always use `router.push()`:**

Find and fix any incorrect usage:

```typescript
// WRONG - breaks back button
router.replace('/(tabs)/home');

// CORRECT - maintains history
router.push('/(tabs)/home');
```

### 3. Fix Custom Back Button Handlers

In any screen with a custom back button, use this pattern:

```typescript
import { useRouter } from 'expo-router';

const router = useRouter();

const handleBack = () => {
  if (router.canGoBack()) {
    router.back();
  } else {
    // Fallback if there's no history (deep link, etc.)
    router.replace('/(tabs)');
  }
};
```

### 4. Make Family Icons Clickable on Home Screen

**File:** Find the home screen that shows family avatars. Likely one of:
- `apps/mobile/app/(tabs)/index.tsx`
- `apps/mobile/app/(tabs)/home.tsx`
- `apps/mobile/app/(tabs)/home/index.tsx`

```bash
# Find where family members are rendered on home screen
grep -rn "family\|member\|avatar" /Users/tomburke/Projects/Housing-Manager/apps/mobile/app/\(tabs\)/ --include="*.tsx" | head -30
```

Update the family section to be tappable:

```tsx
import { useRouter } from 'expo-router';

// In component
const router = useRouter();

// Family section - make each member tappable
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
            style={styles.familyMemberAvatar} 
          />
        ) : (
          <View style={styles.familyMemberAvatarPlaceholder}>
            <Text style={styles.familyMemberInitials}>
              {member.firstName?.[0]}{member.lastName?.[0]}
            </Text>
          </View>
        )}
        <Text style={styles.familyMemberName} numberOfLines={1}>
          {member.firstName}
        </Text>
        <Text style={styles.familyMemberRole} numberOfLines={1}>
          {member.role || (member.isAdult ? 'Adult' : 'Child')}
        </Text>
      </TouchableOpacity>
    ))}
  </ScrollView>
</View>
```

Add styles:
```typescript
familySection: {
  marginBottom: 24,
},
sectionHeader: {
  flexDirection: 'row',
  justifyContent: 'space-between',
  alignItems: 'center',
  paddingHorizontal: 16,
  marginBottom: 12,
},
sectionTitle: {
  fontSize: 18,
  fontWeight: '600',
  color: '#0f172a',
},
seeAllLink: {
  fontSize: 14,
  color: '#c4a574',
  fontWeight: '500',
},
familyScroll: {
  paddingHorizontal: 16,
  gap: 12,
},
familyMemberCard: {
  alignItems: 'center',
  width: 72,
},
familyMemberAvatar: {
  width: 56,
  height: 56,
  borderRadius: 28,
  marginBottom: 6,
},
familyMemberAvatarPlaceholder: {
  width: 56,
  height: 56,
  borderRadius: 28,
  backgroundColor: '#e2e8f0',
  alignItems: 'center',
  justifyContent: 'center',
  marginBottom: 6,
},
familyMemberInitials: {
  fontSize: 18,
  fontWeight: '600',
  color: '#64748b',
},
familyMemberName: {
  fontSize: 12,
  fontWeight: '500',
  color: '#0f172a',
  textAlign: 'center',
},
familyMemberRole: {
  fontSize: 10,
  color: '#94a3b8',
  textAlign: 'center',
},
```

### 5. Ensure Family Detail Route Exists

**File:** `apps/mobile/app/(tabs)/family/[id].tsx`

This was created in M12-2, but verify it exists:
```bash
ls -la /Users/tomburke/Projects/Housing-Manager/apps/mobile/app/\(tabs\)/family/
```

If `[id].tsx` doesn't exist, create it (see M12-2).

### 6. Update Family Tab Layout

**File:** `apps/mobile/app/(tabs)/family/_layout.tsx`

Create if it doesn't exist:
```tsx
import { Stack } from 'expo-router';

export default function FamilyLayout() {
  return (
    <Stack>
      <Stack.Screen 
        name="index" 
        options={{ 
          title: 'Family',
          headerShown: true,
        }} 
      />
      <Stack.Screen 
        name="[id]" 
        options={{ 
          title: 'Family Member',
          headerShown: true,
          // This ensures proper back button behavior
          presentation: 'card',
        }} 
      />
    </Stack>
  );
}
```

---

## VERIFICATION STEPS

### Test 1: Back Button Navigation

1. Start at Home tab
2. Tap on a family member icon → Goes to Family Member Detail
3. Tap Back button → Should go back to Home (or Family list)
4. Navigate: Home → Settings → Edit Profile
5. Tap Back → Should go to Settings, NOT Home

### Test 2: Family Icons Clickable

1. Go to Home tab
2. Find family member avatars
3. Tap on one → Should navigate to their detail page
4. Verify the correct member's info is shown

### Test 3: Full Navigation Flow

1. Home → tap Family icon → Family Member Detail
2. Back → Family list (or Home)
3. Home → tap "Family" tab → Family list
4. Tap a member → Detail
5. Back → Family list
6. Tap Home tab → Home

---

## SUCCESS CRITERIA

- [ ] Back button returns to previous screen, not always Home
- [ ] Family member icons on home screen are tappable
- [ ] Tapping family icon navigates to correct member detail
- [ ] Navigation history is maintained properly
- [ ] No navigation-related crashes
