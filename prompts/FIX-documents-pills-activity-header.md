# Haven Mobile - Critical UI Fixes (January 2025)

## EXECUTIVE SUMMARY

The app is in good shape overall (B+ grade). Only **2 critical issues** remain:
1. Documents page filter pills are broken (giant vertical bars)
2. Activity page has wrong header color

---

## CRITICAL FIX 1: Documents Page Filter Pills

### Problem
The Documents/Vault screen has filter categories (All, Property, Insurance, Warranty) rendering as GIANT VERTICAL PILLS that take up ~50% of the screen height.

**Current (BROKEN):**
```
┌─────────────────────────────────┐
│         Documents               │  ← Header
├─────────────────────────────────┤
│ ┌────┐ ┌────┐ ┌────┐ ┌────┐    │
│ │    │ │    │ │    │ │    │    │
│ │All │ │Prop│ │Ins │ │Warr│    │  ← VERTICAL pills
│ │    │ │    │ │    │ │    │    │     taking 50% height
│ │    │ │    │ │    │ │    │    │
│ │    │ │    │ │    │ │    │    │
│ └────┘ └────┘ └────┘ └────┘    │
├─────────────────────────────────┤
│      Empty state below          │
└─────────────────────────────────┘
```

**Should be (like Maintenance screen):**
```
┌─────────────────────────────────┐
│         Documents               │  ← Header
├─────────────────────────────────┤
│ [All] [Property] [Insurance]... │  ← HORIZONTAL compact pills
├─────────────────────────────────┤
│                                 │
│      Much more content          │
│      space available            │
│                                 │
└─────────────────────────────────┘
```

### Solution

Find the Documents/Vault screen and fix the filter pills styling:

```bash
# Find the vault/documents screen
find /Users/tomburke/Projects/Housing-Manager/apps/mobile -name "*vault*" -o -name "*document*" | grep -i tsx
```

The filter pills should use a **horizontal ScrollView** with compact pill styling:

```typescript
// CORRECT: Horizontal scrolling filter pills
<View style={styles.filterContainer}>
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
        onPress={() => setSelectedCategory(category.id)}
      >
        <Text
          style={[
            styles.filterPillText,
            selectedCategory === category.id && styles.filterPillTextActive,
          ]}
        >
          {category.name}
        </Text>
      </TouchableOpacity>
    ))}
  </ScrollView>
</View>

// CORRECT STYLES:
const styles = StyleSheet.create({
  filterContainer: {
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#f1f5f9',
  },
  filterScrollContent: {
    paddingHorizontal: 16,
    gap: 8,
  },
  filterPill: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 20,
    backgroundColor: '#f1f5f9',
    height: 36,  // FIXED HEIGHT - compact
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

**Key properties to check:**
- `height` should be ~36-40px (NOT flex or percentage)
- `flexDirection` on container should be 'row' 
- Pills should be in a `horizontal` ScrollView
- NO `flex: 1` on the pill container

### Reference: Maintenance Screen Pills (CORRECT)
Look at how the Maintenance screen implements its filter pills - copy that exact pattern.

---

## CRITICAL FIX 2: Activity Page Header Color

### Problem
The Activity page header appears to be a different shade than the standard navy #0a1929.

### Solution

Find the Activity screen and ensure the header uses the correct color:

```bash
# Find activity screen
grep -rn "Activity" /Users/tomburke/Projects/Housing-Manager/apps/mobile/app --include="*.tsx" | head -10
```

The header should use:
```typescript
headerStyle: {
  backgroundColor: '#0a1929',  // Must be this exact color
},
headerTintColor: '#ffffff',
```

If using ScreenContainer or AppHeader component:
```typescript
<ScreenContainer 
  title="Activity"
  // Header color should default to #0a1929
/>
```

If it's a custom header, ensure:
```typescript
const NAVY = '#0a1929';  // NOT #102a43 or any other shade

<View style={[styles.header, { backgroundColor: NAVY }]}>
```

---

## VERIFICATION CHECKLIST

After fixes, verify:

### Documents Page
- [ ] Filter pills are horizontal (in a row)
- [ ] Each pill is ~36px tall (compact)
- [ ] Pills scroll horizontally if needed
- [ ] Selected pill is navy with white text
- [ ] Unselected pills are light gray with dark text
- [ ] Empty state has plenty of room below pills

### Activity Page
- [ ] Header background is exactly #0a1929
- [ ] Header matches Home, Alfred, Money, Tasks, More screens
- [ ] Title "Activity" is white and centered
- [ ] Back button is white

---

## TEST COMMAND

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile
npx expo start --clear
```

Test flow:
1. More → Document Vault → Pills should be horizontal and compact
2. More → Activity → Header should match other screens exactly

---

## FILES LIKELY NEEDING CHANGES

```
apps/mobile/app/(tabs)/vault/index.tsx      # Documents page - FIX PILLS
apps/mobile/app/(tabs)/activity.tsx         # Activity page - FIX HEADER COLOR
```

Or if vault is in a subdirectory:
```
apps/mobile/app/(tabs)/vault/_layout.tsx
apps/mobile/app/(tabs)/vault/[category].tsx
```

---

## QUICK REFERENCE: Correct Filter Pill Dimensions

| Property | Value |
|----------|-------|
| Container height | auto (based on pill height) |
| Pill height | 36px |
| Pill padding horizontal | 16px |
| Pill padding vertical | 8px |
| Pill border radius | 20px (full round) |
| Pill gap | 8px |
| Container padding | 16px horizontal, 12px vertical |
| Active background | #0a1929 (navy) |
| Inactive background | #f1f5f9 (gray-100) |
| Active text | #ffffff (white) |
| Inactive text | #627d98 (navy-500) |
