# Haven Mobile - Final 2 Fixes (January 2025)

## STATUS: App is 98% Complete - Only 2 Issues Remain

The mobile app UI is excellent. Almost every screen is polished and premium-feeling. Only 2 issues need fixing:

---

## FIX 1: Documents Page - Broken Filter Pills (CRITICAL)

### The Problem

On the Documents/Vault screen, the filter pills (All, Property, Insurance, Warranty) are rendering as **giant vertical bars** that take up ~50% of the screen height.

**Screenshot shows:** Tall vertical pill shapes instead of horizontal compact pills

### The Reference (What It Should Look Like)

Look at the **Maintenance screen** filter pills - they work correctly:
- Horizontal layout (in a row)
- Compact height (~36-40px)
- Pills scroll horizontally if needed
- "All" is selected (navy background, white text)
- Others are unselected (light gray background)

The **Vendors**, **Approvals**, and **Activity** screens also have correctly working pills.

### How to Fix

Find the Documents/Vault screen file and ensure the pills use the same pattern as Maintenance:

```bash
# Find the vault/documents files
find apps/mobile -name "*.tsx" | xargs grep -l -i "documents\|vault" | head -10
```

The filter pills need:

```typescript
// Container: HORIZONTAL scroll
<ScrollView
  horizontal
  showsHorizontalScrollIndicator={false}
  contentContainerStyle={styles.filterScrollContent}
>
  {categories.map((category) => (
    <TouchableOpacity
      key={category.id}
      style={[
        styles.filterPill,
        selectedCategory === category.id && styles.filterPillActive,
      ]}
    >
      <Text style={[
        styles.filterPillText,
        selectedCategory === category.id && styles.filterPillTextActive,
      ]}>
        {category.name}
      </Text>
    </TouchableOpacity>
  ))}
</ScrollView>

// CRITICAL STYLES - Fixed height, horizontal layout
const styles = StyleSheet.create({
  filterContainer: {
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#f1f5f9',
  },
  filterScrollContent: {
    flexDirection: 'row',  // MUST be row
    paddingHorizontal: 16,
    gap: 8,
  },
  filterPill: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 20,
    backgroundColor: '#f1f5f9',
    height: 36,  // FIXED HEIGHT - not flex, not percentage
    justifyContent: 'center',
    alignItems: 'center',
  },
  filterPillActive: {
    backgroundColor: '#0a1929',
  },
  filterPillText: {
    fontSize: 14,
    fontWeight: '500',
    color: '#627d98',
  },
  filterPillTextActive: {
    color: '#ffffff',
  },
});
```

### Common Bugs to Check

1. **No `flex: 1`** on the pill or its container - this causes vertical expansion
2. **No percentage heights** - use fixed pixel height (36px)
3. **`flexDirection: 'row'`** must be set on the container
4. **`horizontal` prop** must be on ScrollView
5. Check for any parent container forcing column layout

### Copy From Working Screen

The easiest fix: Copy the exact filter pill implementation from the Maintenance Tasks screen (`apps/mobile/app/(tabs)/maintenance/index.tsx` or similar) and use it in the Documents screen.

---

## FIX 2: Activity Page - Header Color (MINOR)

### The Problem

The Activity page header appears to be a slightly different shade than the standard navy #0a1929.

### How to Fix

Find the Activity screen and ensure header uses exact color:

```bash
grep -rn "Activity" apps/mobile/app --include="*.tsx" | head -5
```

If using custom header or ScreenContainer:
```typescript
// Ensure this exact color
const NAVY = '#0a1929';  // NOT #102a43 or any other shade

// If using ScreenContainer
<ScreenContainer title="Activity" />  // Should default to #0a1929

// If custom header
<View style={{ backgroundColor: '#0a1929' }}>
  <Text style={{ color: '#ffffff' }}>Activity</Text>
</View>
```

---

## VERIFICATION

After fixes, verify:

### Documents Page
- [ ] Filter pills are in a horizontal row
- [ ] Each pill is ~36px tall (compact)
- [ ] "All" pill is navy with white text when selected
- [ ] Other pills are light gray with dark text
- [ ] Empty state has plenty of room below pills
- [ ] Matches Maintenance screen pill style exactly

### Activity Page  
- [ ] Header background is exactly #0a1929
- [ ] Matches Home, Alfred, Money, Tasks, More headers
- [ ] Title "Activity" is white and centered

---

## TEST

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile
npx expo start --clear
```

Test flow:
1. More → Document Vault → Pills should be horizontal and compact
2. More → Activity → Header should match other screens exactly

---

## FILES TO UPDATE

```
apps/mobile/app/(tabs)/vault/index.tsx     # Documents page - FIX PILLS
apps/mobile/app/(tabs)/activity.tsx        # Activity - FIX HEADER COLOR
```

---

## REFERENCE: Correct vs Broken Pills

### ✅ CORRECT (Maintenance, Vendors, Approvals, Activity)
```
┌────────────────────────────────────────┐
│ [All] [Upcoming] [Overdue]             │  ← ~36px height total
└────────────────────────────────────────┘
```

### ❌ BROKEN (Documents - Current State)
```
┌────────────────────────────────────────┐
│ ┌────┐ ┌────────┐ ┌─────────┐ ┌──────┐│
│ │    │ │        │ │         │ │      ││
│ │All │ │Property│ │Insurance│ │Warr..││  ← ~200px+ height
│ │    │ │        │ │         │ │      ││
│ │    │ │        │ │         │ │      ││
│ └────┘ └────────┘ └─────────┘ └──────┘│
└────────────────────────────────────────┘
```

The fix is simple: ensure `height: 36` (fixed) and `flexDirection: 'row'` on container.
