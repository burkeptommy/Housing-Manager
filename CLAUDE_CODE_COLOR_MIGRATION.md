# HAVEN COLOR SCHEME MIGRATION
## Remove Green, Apply Navy/Champagne Palette

**Priority:** HIGH
**Estimated Time:** 30-60 minutes

---

## OBJECTIVE

Remove ALL instances of green/emerald colors from the Haven codebase and replace with the approved Navy + Champagne + White palette.

---

## STEP 1: FIND ALL GREEN REFERENCES

Run these searches in the project root:

```bash
# Search for Tailwind green classes
grep -rn --include="*.tsx" --include="*.ts" --include="*.css" \
  -E "(bg-green|text-green|border-green|bg-emerald|text-emerald|border-emerald|ring-green|ring-emerald)" \
  apps/web/src/

# Search for hex green colors
grep -rn --include="*.tsx" --include="*.ts" --include="*.css" \
  -E "#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})" apps/web/src/ | grep -iE "(0b|10b|22c|059|047|34d|4ade)"

# Search for RGB green values
grep -rn --include="*.tsx" --include="*.ts" --include="*.css" \
  -E "rgb\([^)]*\)" apps/web/src/ | grep -iE "(16.*185|34.*197|5.*150)"

# Search for CSS variable references to green
grep -rn --include="*.tsx" --include="*.ts" --include="*.css" \
  -E "(--.*green|--.*emerald)" apps/web/src/
```

---

## STEP 2: COLOR REPLACEMENT MAP

### Tailwind Class Replacements

| Old (Green) | New (Navy/Champagne) | Use Case |
|-------------|---------------------|----------|
| `bg-green-500` | `bg-haven-champagne-500` | Accent backgrounds |
| `bg-green-600` | `bg-haven-navy-800` | Primary buttons |
| `bg-green-700` | `bg-haven-navy-900` | Hover states |
| `bg-green-50` | `bg-haven-champagne-50` | Light backgrounds |
| `bg-green-100` | `bg-haven-champagne-100` | Card highlights |
| `bg-emerald-500` | `bg-haven-champagne-500` | Success accents |
| `bg-emerald-600` | `bg-haven-champagne-600` | Hover accents |
| `text-green-500` | `text-haven-champagne-500` | Accent text |
| `text-green-600` | `text-haven-champagne-600` | Links, emphasis |
| `text-green-700` | `text-haven-navy-700` | Dark accent text |
| `text-emerald-500` | `text-haven-champagne-500` | Accent text |
| `text-emerald-600` | `text-haven-champagne-600` | Links |
| `border-green-500` | `border-haven-champagne-500` | Accent borders |
| `border-green-600` | `border-haven-navy-600` | Focus borders |
| `ring-green-500` | `ring-haven-champagne-500` | Focus rings |
| `hover:bg-green-600` | `hover:bg-haven-champagne-400` | Hover states |
| `hover:bg-green-700` | `hover:bg-haven-navy-800` | Dark hover |

### Hex Color Replacements

| Old Hex | Color Name | New Hex | New Color |
|---------|------------|---------|-----------|
| `#10b981` | Emerald 500 | `#c4a574` | Champagne 500 |
| `#22c55e` | Green 500 | `#c4a574` | Champagne 500 |
| `#059669` | Emerald 600 | `#b08d54` | Champagne 600 |
| `#047857` | Emerald 700 | `#937542` | Champagne 700 |
| `#34d399` | Emerald 400 | `#d4c4a5` | Champagne 400 |
| `#4ade80` | Green 400 | `#d4c4a5` | Champagne 400 |
| `#16a34a` | Green 600 | `#b08d54` | Champagne 600 |
| `#15803d` | Green 700 | `#243b53` | Navy 800 |
| `#166534` | Green 800 | `#102a43` | Navy 900 |
| `#ecfdf5` | Emerald 50 | `#fdfcf9` | Champagne 50 |
| `#d1fae5` | Emerald 100 | `#faf6ed` | Champagne 100 |
| `#a7f3d0` | Emerald 200 | `#f4ebda` | Champagne 200 |

---

## STEP 3: EXCEPTION - SUCCESS/ERROR STATES

**DO NOT REPLACE** green used for semantic success states. These are accessibility-important:

```tsx
// KEEP these patterns (semantic success indicators)
<CheckCircle className="text-green-500" />  // Success checkmarks
<Badge variant="success">Completed</Badge>   // Success badges
className="text-green-600" // When showing "Paid", "Confirmed", "On Track"
```

**Instead, ensure these use the muted success color:**
```tsx
// Muted success green (acceptable)
text-emerald-600  →  Keep for success states OR use text-green-600
bg-green-50       →  Keep for success backgrounds
```

**The rule:** Green is ONLY acceptable for explicit success/positive status indicators (checkmarks, "Paid", "Confirmed", "Excellent"). All other decorative/brand uses must be Navy or Champagne.

---

## STEP 4: FILES TO CHECK (Priority Order)

1. **Global Styles**
   - `apps/web/src/app/globals.css`
   - `apps/web/tailwind.config.ts` or `tailwind.config.js`

2. **Layout Components**
   - `apps/web/src/app/app/layout.tsx` (sidebar)
   - `apps/web/src/components/layout/Sidebar.tsx`
   - `apps/web/src/components/layout/Header.tsx`

3. **Marketing Pages**
   - `apps/web/src/app/page.tsx` (homepage)
   - `apps/web/src/app/(marketing)/**`

4. **App Pages** (check each)
   - `apps/web/src/app/app/page.tsx` (dashboard)
   - `apps/web/src/app/app/sarah/page.tsx`
   - `apps/web/src/app/app/family/page.tsx`
   - `apps/web/src/app/app/money/page.tsx`
   - `apps/web/src/app/app/maintenance/page.tsx`
   - `apps/web/src/app/app/tasks/page.tsx`
   - `apps/web/src/app/app/home/page.tsx`
   - `apps/web/src/app/app/projects/page.tsx`
   - `apps/web/src/app/app/find-pros/page.tsx`
   - `apps/web/src/app/app/inventory/page.tsx`
   - `apps/web/src/app/app/profile/page.tsx`
   - `apps/web/src/app/app/settings/page.tsx`

5. **Shared Components**
   - `apps/web/src/components/**/*.tsx`
   - `packages/ui/src/**/*.tsx`

---

## STEP 5: TAILWIND CONFIG UPDATE

Ensure `tailwind.config.ts` has the Haven colors defined:

```typescript
import type { Config } from 'tailwindcss'

const config: Config = {
  content: [
    './src/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        haven: {
          navy: {
            50: '#f0f4f8',
            100: '#d9e2ec',
            200: '#bcccdc',
            300: '#9fb3c8',
            400: '#829ab1',
            500: '#627d98',
            600: '#486581',
            700: '#334e68',
            800: '#243b53',
            900: '#102a43',
            950: '#0a1929',
          },
          champagne: {
            50: '#fdfcf9',
            100: '#faf6ed',
            200: '#f4ebda',
            300: '#e9dcc4',
            400: '#d4c4a5',
            500: '#c4a574',
            600: '#b08d54',
            700: '#937542',
            800: '#7a6038',
            900: '#654f30',
          },
        },
      },
    },
  },
  plugins: [],
}

export default config
```

---

## STEP 6: VERIFICATION

After replacements, run:

```bash
# Verify no green remains (except success states)
grep -rn --include="*.tsx" --include="*.ts" \
  -E "(bg-green|bg-emerald|text-green|text-emerald)" \
  apps/web/src/ | grep -v "success\|Success\|check\|Check\|confirm\|Confirm\|paid\|Paid"

# Build to catch any errors
pnpm build

# Visual verification - check these pages:
# - Homepage (/)
# - Dashboard (/app)
# - Family page (/app/family)
# - Money page (/app/money)
# - Sarah page (/app/sarah)
```

---

## QUICK REFERENCE: THE HAVEN PALETTE

```
NAVY (Primary)
━━━━━━━━━━━━━━━━━━━━━━━━━━━
950: #0a1929  ← Sidebar BG
900: #102a43  ← Primary headings
800: #243b53  ← Buttons, emphasis
700: #334e68  ← Hover states
600: #486581  ← Secondary elements

CHAMPAGNE (Accent)
━━━━━━━━━━━━━━━━━━━━━━━━━━━
500: #c4a574  ← Primary accent
400: #d4c4a5  ← Hover accent
300: #e9dcc4  ← Light accent
100: #faf6ed  ← Subtle backgrounds

NEUTRALS
━━━━━━━━━━━━━━━━━━━━━━━━━━━
white: #ffffff ← Content backgrounds
gray-50: #f9fafb ← Page backgrounds
gray-200: #e5e7eb ← Borders
gray-500: #6b7280 ← Secondary text
gray-900: #111827 ← Primary text
```

---

*Run this audit before any demo. Green = old brand. Navy + Champagne = Haven.*
