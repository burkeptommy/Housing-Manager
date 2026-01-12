# Haven Mobile - Typography Refinements

## OVERVIEW

Premium apps have refined typography. These changes ensure readability, accessibility, and elegance throughout the Haven mobile app.

---

## CHANGE 1: Update Theme Typography Scale

### File to Edit
```
apps/mobile/src/lib/theme.ts
```

### Find Current Typography
```typescript
export const typography = {
  fontSizes: {
    '2xs': 10,
    xs: 12,
    sm: 14,
    // ...
  },
  // ...
};
```

### Replace With Refined Typography
```typescript
export const typography = {
  // =========================================================================
  // FONT SIZES - Minimum 13px for accessibility and readability
  // =========================================================================
  fontSizes: {
    xs: 13,      // Was 12 - minimum readable size (captions, timestamps)
    sm: 14,      // Secondary text, button labels  
    base: 16,    // Body text, inputs
    lg: 18,      // Subheadings, card titles
    xl: 20,      // Section titles
    '2xl': 24,   // Screen titles
    '3xl': 30,   // Large headings
    '4xl': 36,   // Hero text
    '5xl': 48,   // Extra large display
  },

  // =========================================================================
  // FONT WEIGHTS - Clear hierarchy
  // =========================================================================
  fontWeights: {
    regular: '400' as const,   // Body text
    medium: '500' as const,    // Labels, secondary emphasis
    semibold: '600' as const,  // Headings, buttons
    bold: '700' as const,      // Strong emphasis
  },

  // =========================================================================
  // LINE HEIGHTS - Comfortable reading
  // =========================================================================
  lineHeights: {
    none: 1,        // Single line items
    tight: 1.2,     // Headings
    snug: 1.375,    // Compact text
    normal: 1.5,    // Body text (default)
    relaxed: 1.625, // Long-form text
    loose: 2,       // Extra spacing
  },

  // =========================================================================
  // LETTER SPACING - Elegance and readability
  // =========================================================================
  letterSpacing: {
    tighter: -0.5,   // Large display text (36px+)
    tight: -0.25,    // Headings (24px+)
    normal: 0,       // Body text
    wide: 0.25,      // Buttons, labels
    wider: 0.5,      // Small caps
    widest: 1.5,     // UPPERCASE LABELS
  },
};
```

### Key Changes
| Property | Old | New | Why |
|----------|-----|-----|-----|
| `xs` | 10 or 12 | **13** | Minimum readable size |
| `2xs` | 10 | **REMOVE** | Too small |
| Added `letterSpacing` | N/A | New | Elegance |

---

## CHANGE 2: Apply Letter Spacing to Headings

### Find Large Headings Throughout App

Search for large text styles:
```bash
grep -rn "fontSize.*2[4-9]\|fontSize.*3[0-9]\|fontSizes\.\(2xl\|3xl\|4xl\)" apps/mobile --include="*.tsx" | head -30
```

### Add Letter Spacing to Heading Styles

**Pattern: Any text 24px or larger should have tight letter spacing**

Before:
```typescript
heroGreeting: {
  fontSize: 28,
  fontWeight: '700',
  color: '#ffffff',
},
```

After:
```typescript
heroGreeting: {
  fontSize: 28,
  fontWeight: '700',
  color: '#ffffff',
  letterSpacing: -0.5,  // ADD: Tighter for large text
},
```

### Key Screens to Update

#### Home Dashboard (`apps/mobile/app/(tabs)/index.tsx`)
```typescript
// Hero greeting
heroGreeting: {
  fontSize: 28,
  fontWeight: typography.fontWeights.bold,
  color: colors.white,
  letterSpacing: -0.5,  // ADD
},

// Section titles
sectionTitle: {
  fontSize: typography.fontSizes.lg,  // 18px
  fontWeight: typography.fontWeights.semibold,
  color: colors.text.primary,
  letterSpacing: -0.25,  // ADD
},

// Card titles
cardTitle: {
  fontSize: typography.fontSizes.base,  // 16px
  fontWeight: typography.fontWeights.semibold,
  color: colors.text.primary,
  letterSpacing: -0.25,  // ADD (optional for 16px)
},
```

#### Screen Headers (AppHeader component)
```typescript
// apps/mobile/src/components/AppHeader.tsx
title: {
  fontSize: 17,
  fontWeight: '600',
  letterSpacing: -0.25,  // ADD
},
```

#### Section Headers (SectionHeader component)
```typescript
// apps/mobile/src/components/ui/SectionHeader.tsx
title: {
  fontSize: typography.fontSizes.base,
  fontWeight: typography.fontWeights.semibold,
  color: colors.text.primary,
  letterSpacing: -0.25,  // ADD
},
```

---

## CHANGE 3: Apply Wide Letter Spacing to Uppercase Labels

### Find Uppercase Text
```bash
grep -rn "textTransform.*uppercase\|UPPERCASE" apps/mobile --include="*.tsx" | head -20
```

### Update Uppercase Label Styles

Before:
```typescript
sectionTitle: {
  fontSize: 12,
  fontWeight: '600',
  color: '#627d98',
  textTransform: 'uppercase',
},
```

After:
```typescript
sectionTitle: {
  fontSize: 13,              // CHANGE: Min 13px
  fontWeight: '600',
  color: '#627d98',
  textTransform: 'uppercase',
  letterSpacing: 1.5,        // ADD: Wide for uppercase
},
```

### Key Locations with Uppercase Labels
- More menu section headers ("YOUR HOME", "FINANCIAL", "ACCOUNT")
- Settings section headers ("SUBSCRIPTION", "NOTIFICATIONS", "SECURITY")
- Task category labels ("HVAC", "GENERAL", "CHIMNEY")
- Any other CAPS labels

---

## CHANGE 4: Fix Any Sub-13px Font Sizes

### Search for Small Font Sizes
```bash
grep -rn "fontSize.*1[0-2]\b\|fontSizes\.\(2xs\|xs\)" apps/mobile --include="*.tsx" | head -50
```

### Common Patterns to Fix

**Timestamps:**
```typescript
// Before
messageTime: {
  fontSize: 10,  // TOO SMALL
  color: colors.text.tertiary,
},

// After
messageTime: {
  fontSize: 13,  // Minimum readable
  color: colors.text.tertiary,
},
```

**Badges:**
```typescript
// Before
badgeText: {
  fontSize: 10,  // TOO SMALL
  fontWeight: '600',
},

// After  
badgeText: {
  fontSize: 11,  // Exception: badges can be 11px if space-constrained
  fontWeight: '700',  // Bolder to compensate
},
```

**Captions:**
```typescript
// Before
caption: {
  fontSize: 11,  // TOO SMALL
},

// After
caption: {
  fontSize: 13,  // Minimum
},
```

### Exception: Tab Bar Labels

Tab bar labels at 11px are acceptable because:
1. They're always the same text (predictable)
2. They're paired with icons
3. iOS convention

```typescript
tabBarLabelStyle: {
  fontSize: 11,  // OK - exception for tab bar
  fontWeight: '600',
  letterSpacing: 0.25,  // ADD: helps readability at small size
},
```

---

## CHANGE 5: Ensure Body Text Uses Proper Line Height

### Check Long-Form Text
```bash
grep -rn "lineHeight" apps/mobile --include="*.tsx" | head -20
```

### Apply Line Heights

**Body text (descriptions, paragraphs):**
```typescript
description: {
  fontSize: 14,
  color: colors.text.secondary,
  lineHeight: 14 * 1.5,  // 21px - comfortable reading
},
```

**Or using the theme:**
```typescript
description: {
  fontSize: typography.fontSizes.sm,
  color: colors.text.secondary,
  lineHeight: typography.fontSizes.sm * typography.lineHeights.normal,
},
```

**Key locations:**
- Task descriptions in Maintenance
- "Why This Matters" sections
- Empty state descriptions
- Modal content
- Alfred chat messages

---

## QUICK REFERENCE

### Font Size Guidelines
| Size | Use For | Letter Spacing |
|------|---------|----------------|
| 13px | Timestamps, captions, small labels | normal (0) |
| 14px | Secondary text, buttons | normal or wide (0.25) |
| 16px | Body text, inputs | normal (0) |
| 18px | Subheadings, card titles | tight (-0.25) |
| 20px | Section titles | tight (-0.25) |
| 24px+ | Screen titles, hero text | tighter (-0.5) |

### Letter Spacing Guidelines
| Type | Spacing | Value |
|------|---------|-------|
| Large headings (24px+) | tighter | -0.5 |
| Medium headings (18-24px) | tight | -0.25 |
| Body text | normal | 0 |
| Buttons, labels | wide | 0.25 |
| UPPERCASE | widest | 1.5 |

---

## VERIFICATION CHECKLIST

### Font Sizes
- [ ] No text smaller than 13px (except tab bar labels at 11px)
- [ ] Timestamps are readable (13px)
- [ ] Captions are readable (13px)
- [ ] Body text is 16px

### Letter Spacing
- [ ] Hero greeting has tight spacing
- [ ] Section titles have slight tight spacing
- [ ] UPPERCASE labels have wide spacing (1.5)
- [ ] Body text has no extra spacing

### Line Heights
- [ ] Descriptions have 1.5 line height
- [ ] Multi-line text is comfortable to read
- [ ] Single-line items have appropriate height

### Test Flow
```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile
npx expo start --clear
```

1. Home screen - Check hero greeting typography
2. All screens - Check section headers
3. Settings - Check uppercase section labels
4. Maintenance task detail - Check "Why This Matters" readability
5. Any timestamps - Should be readable at 13px

---

## FILES TO UPDATE

### Core Theme
```
apps/mobile/src/lib/theme.ts
```

### Components
```
apps/mobile/src/components/AppHeader.tsx
apps/mobile/src/components/ui/SectionHeader.tsx
apps/mobile/src/components/ui/Badge.tsx
apps/mobile/src/components/ui/Card.tsx
```

### Screens (check and fix inline styles)
```
apps/mobile/app/(tabs)/index.tsx              # Home
apps/mobile/app/(tabs)/manager/index.tsx      # Alfred
apps/mobile/app/(tabs)/more.tsx               # More menu
apps/mobile/app/(tabs)/settings/index.tsx     # Settings
apps/mobile/app/(tabs)/maintenance/*.tsx      # Maintenance
```

---

## SUMMARY

1. **Update theme.ts** - New typography scale with 13px minimum and letter spacing
2. **Apply letter spacing** - Tight for headings, wide for uppercase
3. **Fix small fonts** - Find and update anything under 13px
4. **Add line heights** - For multi-line body text

These refinements make the app feel more polished and professional.
