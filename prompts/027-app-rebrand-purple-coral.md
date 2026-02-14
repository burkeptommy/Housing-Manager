# Prompt 027: Complete App Rebrand — Purple + White + Coral

## Context
Haven is rebranding from the current Navy/Sage color scheme to a bold new palette centered on Deep Purple (#6200EA) and White, with Coral (#FF6B6B) used sparingly as a secondary accent. We're also changing the typography from Inter/Playfair Display to **Plus Jakarta Sans** throughout the entire app (web + mobile) to achieve a more modern, friendly, Airbnb-like feel.

This prompt covers the **app only** (web app portal + mobile app). The marketing website homepage will be handled in a separate prompt.

## Objective
Replace ALL existing colors and fonts across the entire Haven application — both web (`apps/web/`) and mobile (`apps/mobile/`) — with the new brand system defined below.

---

## NEW BRAND SYSTEM

### Color Palette

#### Primary: Deep Purple
```
purple-950: #1A0044   ← Darkest (sidebar bg, dark mode bg)
purple-900: #2D006B   ← Deep emphasis
purple-800: #3D008F   ← Dark buttons
purple-700: #4A00B4   ← Hover states
purple-600: #5500D4   ← Active states
purple-500: #6200EA   ← PRIMARY BRAND COLOR — buttons, headers, links, icons
purple-400: #7C4DFF   ← Lighter interactive
purple-300: #B388FF   ← Light accent text, badges
purple-200: #D1B3FF   ← Subtle highlights
purple-100: #EDE7F6   ← Card backgrounds, input fills, tinted sections
purple-50:  #F9F5FF   ← Page background, subtle tints
```

#### Secondary Accent: Coral (USE SPARINGLY)
```
coral-600: #E85555   ← Darkened for text on white (meets WCAG AA)
coral-500: #FF6B6B   ← PRIMARY CORAL — badges, alerts, urgent items, secondary CTAs
coral-400: #FF8A8A   ← Hover state
coral-100: #FFE0E0   ← Light coral background
coral-50:  #FFF0F0   ← Subtle coral tint
```

#### Neutrals
```
gray-900: #1A1A2E   ← Primary text (dark with purple tint)
gray-800: #2D2D44   ← Secondary text
gray-700: #444466   ← Tertiary text
gray-500: #6B7280   ← Muted text, placeholders
gray-300: #D1D5DB   ← Borders
gray-200: #E5E7EB   ← Subtle borders
gray-100: #F3F4F6   ← Alternative backgrounds
gray-50:  #F9FAFB   ← Lightest background
```

#### Semantic / Status Colors (keep functional, DO NOT change these)
```
success:  #059669 (emerald-600) — checkmarks, confirmed, paid
warning:  #D97706 (amber-600) — caution states
error:    #DC2626 (red-600) — errors, destructive actions
info:     #0284c7 (sky-600) — informational
```

### Color Usage Rules — CRITICAL

1. **Purple (#6200EA) is the dominant color.** Used for: primary buttons, navigation active states, headers, links, icons, Alfred's identity, the Haven logo, progress bars, focused inputs.

2. **White (#FFFFFF) is the primary background.** Cards are white. Page backgrounds are white or purple-50 (#F9F5FF). The app should feel bright, clean, and airy.

3. **Coral (#FF6B6B) is used SPARINGLY.** It appears in ONLY these contexts:
   - Alert/urgent badges (e.g., "Action Needed", "Overdue")
   - Notification count badges
   - Secondary CTA buttons when a page already has a purple primary CTA
   - Destructive/warning indicators that aren't errors (e.g., "overdue maintenance")
   - Accent in data visualization (e.g., budget progress gradient endpoints)
   - **Coral is NEVER used for:** logos, navigation, primary buttons, headers, Alfred's identity, icons in nav

4. **The Haven logo is purple + white ONLY.** No coral in the logo ever.

5. **Alfred's identity is purple + white ONLY.** Alfred avatar, Alfred chat bubbles, Alfred header — all purple/white. No coral.

6. **Buttons:**
   - Primary CTA: Purple background (#6200EA), white text
   - Secondary: Purple-100 background (#EDE7F6), purple text (#6200EA)
   - Tertiary/Ghost: White background, purple text, subtle border
   - Alert/Urgent CTA: Coral background (#FF6B6B), white text (rare)
   - On dark/purple backgrounds: White background, purple text

7. **Navigation (sidebar/bottom tabs):**
   - Active item: Purple (#6200EA) icon + text
   - Inactive: Gray (#6B7280)
   - Background: White (light mode) or gray-900 (#1A1A2E, dark mode)

### Typography

#### Font: Plus Jakarta Sans (everywhere)
- **Web**: Import from Google Fonts. Replace both Inter AND Playfair Display with Plus Jakarta Sans. No more serif font for h1 — everything is Plus Jakarta Sans.
- **Mobile**: Use expo-google-fonts package: `@expo-google-fonts/plus-jakarta-sans`

#### Font Weights
```
300 — Light (decorative use only)
400 — Regular (body text)
500 — Medium (labels, secondary emphasis)
600 — SemiBold (subheadings, buttons, card titles)
700 — Bold (section titles, emphasis)
800 — ExtraBold (hero text, display headings, screen titles)
```

#### Heading Style
- ALL headings use Plus Jakarta Sans (no serif anywhere)
- Display/hero text: 800 weight, tight letter-spacing (-0.5px to -1.5px)
- Body text: 400 weight, normal letter-spacing
- Buttons/labels: 600–700 weight

---

## FILES TO MODIFY

### 1. Mobile Theme — `apps/mobile/src/lib/theme.ts`

**Complete rewrite of the colors object.** Replace the entire `haven`, `sage`, `champagne`, `primary`, `accent` color blocks with the new purple-based system. Structure:

```typescript
export const colors = {
  // Haven Purple (Primary Brand)
  haven: {
    purple: {
      950: '#1A0044',
      900: '#2D006B',
      800: '#3D008F',
      700: '#4A00B4',
      600: '#5500D4',
      500: '#6200EA',  // Primary
      400: '#7C4DFF',
      300: '#B388FF',
      200: '#D1B3FF',
      100: '#EDE7F6',
      50:  '#F9F5FF',
    },
    // Coral accent (use sparingly)
    coral: {
      600: '#E85555',
      500: '#FF6B6B',
      400: '#FF8A8A',
      100: '#FFE0E0',
      50:  '#FFF0F0',
    },
  },

  // Update all semantic references:
  text: {
    primary: '#1A1A2E',
    secondary: '#6B7280',
    tertiary: '#9CA3AF',
    inverse: '#FFFFFF',
    accent: '#6200EA',    // Was sage
  },
  border: {
    default: '#E5E7EB',
    light: '#F3F4F6',
    dark: '#D1D5DB',
    focus: '#6200EA',     // Was sage
  },
  background: {
    primary: '#FFFFFF',
    secondary: '#F9F5FF',  // Was #f8fafc — now light purple tint
    tertiary: '#EDE7F6',   // Was #f1f5f9 — now purple-100
  },
  // ... keep gray, status, and basic colors
};
```

**IMPORTANT:** Also search the ENTIRE `apps/mobile/src/` directory for any hardcoded color references:
- Any hex codes matching old navy (#0a1929, #102a43, #243b53, #334e68, etc.) → replace with corresponding purple shade
- Any hex codes matching old sage (#7D8E74, #A4B494, #8FA37F, etc.) → replace with purple-500 or purple-300
- Any hex codes matching old champagne → replace with purple equivalents
- `colors.haven.navy.*` references → `colors.haven.purple.*`
- `colors.haven.sage.*` references → `colors.haven.purple.*` (or coral where it's an alert/badge)
- `colors.text.accent` references → update to new purple value
- `colors.border.focus` references → update to new purple value

Run this search:
```bash
grep -rn --include="*.tsx" --include="*.ts" -E "(haven\.navy|haven\.sage|haven\.champagne|#0a1929|#102a43|#243b53|#334e68|#486581|#627d98|#7D8E74|#A4B494|#8FA37F|#6B7A63|#c4a574|sage|champagne)" apps/mobile/src/
```

### 2. Web Tailwind Config — `apps/web/tailwind.config.ts`

**Replace the entire color configuration.** Remove `haven`, `haven-navy`, `sage`, `haven-sage`, `champagne`, `haven-champagne`, `cream`, `warm`, `gold` color blocks. Replace with:

```typescript
colors: {
  // PRIMARY: Deep Purple
  haven: {
    50: '#F9F5FF',
    100: '#EDE7F6',
    200: '#D1B3FF',
    300: '#B388FF',
    400: '#7C4DFF',
    500: '#6200EA',  // Primary brand
    600: '#5500D4',
    700: '#4A00B4',
    800: '#3D008F',
    900: '#2D006B',
    950: '#1A0044',
  },
  // ACCENT: Coral (sparingly)
  coral: {
    50: '#FFF0F0',
    100: '#FFE0E0',
    400: '#FF8A8A',
    500: '#FF6B6B',
    600: '#E85555',
  },
  // Neutrals
  neutral: {
    50: '#F9FAFB',
    100: '#F3F4F6',
    200: '#E5E7EB',
    300: '#D1D5DB',
    400: '#9CA3AF',
    500: '#6B7280',
    600: '#4B5563',
    700: '#374151',
    800: '#1F2937',
    900: '#1A1A2E',
    950: '#0F0F1E',
  },
},
```

**Update fontFamily:**
```typescript
fontFamily: {
  sans: ['var(--font-jakarta)', 'Plus Jakarta Sans', '-apple-system', 'BlinkMacSystemFont', 'sans-serif'],
  // Remove serif entirely — no more Playfair Display
},
```

**Update boxShadow:** Replace `glow-sage` and any sage-referencing shadows:
```typescript
'glow': '0 0 24px rgba(98, 0, 234, 0.15)',
'glow-purple': '0 0 24px rgba(98, 0, 234, 0.25)',
```

### 3. Web Layout — `apps/web/src/app/layout.tsx`

- Remove `Inter` and `Playfair_Display` imports from `next/font/google`
- Add `Plus_Jakarta_Sans` import:
```typescript
import { Plus_Jakarta_Sans } from 'next/font/google';

const jakarta = Plus_Jakarta_Sans({
  subsets: ['latin'],
  variable: '--font-jakarta',
  weight: ['300', '400', '500', '600', '700', '800'],
});
```
- Update the className on `<body>` or `<html>` to use `jakarta.variable` instead of `inter.variable` and remove `playfair.variable`

### 4. Web Global CSS — `apps/web/src/app/globals.css`

- Update the Google Fonts import URL to Plus Jakarta Sans:
```css
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@300;400;500;600;700;800&display=swap');
```
- Remove the old Inter + Playfair import
- Update `body` styles: replace `bg-sage-50` with `bg-white` or `bg-haven-50`
- Update `h1` styles: remove `font-serif`, use `font-sans font-extrabold`
- Update `::selection` to use purple: `@apply bg-haven-100 text-haven-900`
- Search for any remaining sage/champagne/navy class references in this file

### 5. Web Logo Components

**`apps/web/src/components/ui/HavenLogo.tsx`** — Update all color references to purple. The logo should render in purple (#6200EA) on light backgrounds and white on dark backgrounds. Remove any sage/navy/champagne references.

**`apps/web/src/components/marketing/AlfredLogo.tsx`** — Same treatment. Alfred's visual identity is purple + white only.

### 6. Mobile Logo Assets

**`apps/mobile/assets/alfred/alfred-logo-dark-bg.svg`** — Update colors to white (for dark backgrounds)
**`apps/mobile/assets/alfred/alfred-logo-light-bg.svg`** — Update colors to purple #6200EA (for light backgrounds)

### 7. Full Codebase Color Sweep

After updating the config files, do a comprehensive search-and-replace across BOTH apps:

**Web app (`apps/web/src/`):**
```bash
# Find all old color class references
grep -rn --include="*.tsx" --include="*.ts" --include="*.css" -E "(bg-sage|text-sage|border-sage|bg-haven-navy|text-haven-navy|bg-haven-champagne|text-haven-champagne|bg-champagne|text-champagne|bg-warm|text-warm|bg-cream|font-serif)" apps/web/src/
```

**Replacement map for Tailwind classes:**
| Old Class Pattern | New Class |
|---|---|
| `bg-sage-50` | `bg-haven-50` |
| `bg-sage-100` | `bg-haven-100` |
| `bg-sage-500` | `bg-haven-500` |
| `text-sage-*` | `text-haven-*` (corresponding shade) |
| `border-sage-*` | `border-haven-*` |
| `bg-haven-navy-950` | `bg-haven-950` |
| `bg-haven-navy-900` | `bg-haven-900` |
| `text-haven-navy-*` | `text-haven-*` |
| `bg-haven-champagne-*` | `bg-haven-*` |
| `bg-champagne-*` | `bg-haven-*` |
| `bg-warm-*` | `bg-neutral-*` |
| `text-warm-*` | `text-neutral-*` |
| `bg-cream-*` | `bg-white` or `bg-haven-50` |
| `font-serif` | `font-sans font-extrabold` |
| `glow-sage` | `glow-purple` |
| `bg-gold-*` | Keep for premium badges OR replace with `bg-coral-*` |

**Mobile app (`apps/mobile/src/`):**
```bash
# Find all old color references in mobile
grep -rn --include="*.tsx" --include="*.ts" -E "(colors\.(haven\.(navy|sage|champagne)|primary|accent)\.|#0a1929|#102a43|#7D8E74|#A4B494|sage|champagne)" apps/mobile/src/
```

Replace all `colors.haven.navy.XXX` → `colors.haven.purple.XXX`
Replace all `colors.haven.sage.XXX` → `colors.haven.purple.XXX`
Replace all `colors.haven.champagne.XXX` → `colors.haven.purple.XXX`
Replace all `colors.accent.XXX` → `colors.haven.purple.XXX`
Replace all `colors.primary.XXX` → `colors.haven.purple.XXX`

### 8. Mobile Font Change

Install Plus Jakarta Sans for Expo:
```bash
cd apps/mobile
npx expo install @expo-google-fonts/plus-jakarta-sans expo-font
```

Update the font loading in the mobile app's root layout (likely `apps/mobile/app/_layout.tsx` or similar) to load Plus Jakarta Sans instead of the current system/Inter font.

### 9. App Icon & Splash Screen

**`apps/mobile/app.json`** — Update any splash screen background colors from old navy/sage to purple:
- `splash.backgroundColor` → `#6200EA` or `#FFFFFF`
- `android.adaptiveIcon.backgroundColor` → `#6200EA`

---

## VERIFICATION CHECKLIST

After making all changes, verify:

1. **Build check:**
   ```bash
   cd apps/web && pnpm build
   cd apps/mobile && npx expo export --platform ios
   ```

2. **No remaining old colors:**
   ```bash
   # Web
   grep -rn --include="*.tsx" --include="*.ts" --include="*.css" -E "(sage|champagne|#0a1929|#102a43|#7D8E74|#A4B494|font-serif|Playfair)" apps/web/src/ | grep -v node_modules
   
   # Mobile
   grep -rn --include="*.tsx" --include="*.ts" -E "(\.navy\.|\.sage\.|\.champagne\.|#0a1929|#102a43|#7D8E74)" apps/mobile/src/ | grep -v node_modules
   ```

3. **Visual spot-check these key screens:**
   - Login / Sign-up flow
   - Main dashboard
   - Alfred chat
   - Money / Budget page
   - Maintenance / Home Systems
   - Navigation (sidebar on web, bottom tabs on mobile)
   - Settings / Profile
   - Any modals or slide-overs

4. **Accessibility:** Ensure all text on purple backgrounds uses white or very light text. Ensure coral text is NEVER used on white backgrounds (use coral-600 #E85555 minimum, or use coral only as backgrounds/badges).

5. **Coral usage audit:**
   ```bash
   grep -rn --include="*.tsx" --include="*.ts" -E "(coral|#FF6B6B|#E85555|#FFE0E0|#FFF0F0)" apps/web/src/ apps/mobile/src/
   ```
   Review every instance — coral should ONLY appear for alerts, urgent badges, secondary CTAs, and data visualization accents. If it appears in nav, headers, logos, or Alfred, remove it.

---

## IMPORTANT NOTES

- **DO NOT touch `apps/web/src/app/page.tsx`** (the marketing homepage). That will be rebranded in a separate prompt.
- **DO NOT change status colors** (success green, warning amber, error red, info blue). These are semantic and should remain as-is.
- **Clean up dead code:** Remove any `champagne`, `sage`, `haven-champagne`, `haven-sage`, `warm`, `cream` color definitions that are no longer referenced after migration.
- **The font change is critical.** Every screen, every component, every heading must use Plus Jakarta Sans. No Inter, no Playfair Display should remain anywhere in the rendered app.
- **Test dark mode if it exists.** Dark mode backgrounds should use gray-900 (#1A1A2E) or purple-950 (#1A0044), with purple-300/400 for accent text.
