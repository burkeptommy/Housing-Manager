# Haven Homepage Visual Cleanup + Sage Color Palette

**Created:** January 16, 2025  
**Priority:** HIGH - Visual polish + color rebrand  
**Estimated Time:** 1.5 hours

---

## Overview

Two changes in one prompt:
1. **Visual cleanup** — Fix button colors, price badge, expand "How It Works"
2. **Color rebrand** — Replace champagne with Sage Green palette

---

## New Color Palette: Sage Green

**Vibe:** Natural, grounded, calm. A well-organized home with a garden. Modern without being cold.

| Role | Name | Hex | Usage |
|------|------|-----|-------|
| Primary | Navy | `#0a1929` | Headers, primary buttons, dark sections |
| Accent | Sage | `#7D8E74` | Accent buttons, icons, highlights |
| Soft Accent | Light Sage | `#A4B494` | Hover states, secondary accents |
| Light BG | Soft Green | `#F4F6F2` | Page backgrounds, light sections |
| Card BG | Cream | `#FAFAF7` | Cards, content areas |
| Text Dark | Navy | `#0a1929` | Primary text |
| Text Muted | Warm Gray | `#6B7280` | Secondary text |

---

## PHASE 1: Update Tailwind Config

**File:** `apps/web/tailwind.config.ts`

Add the sage color palette to the `extend.colors` section:

```typescript
// Replace the champagne colors with sage
sage: {
  50: '#F4F6F2',   // Light BG / Soft Green
  100: '#E8EDE4',  // Subtle backgrounds
  200: '#D1DBC9',  // Borders, dividers
  300: '#A4B494',  // Light Sage / soft accent
  400: '#8FA37F',  // Medium accent
  500: '#7D8E74',  // Primary Sage accent
  600: '#6B7A63',  // Darker accent / hover
  700: '#5A6853',  // Dark accent
  800: '#4A5544',  // Very dark
  900: '#3B4536',  // Darkest
},

// Keep cream for card backgrounds
cream: {
  50: '#FEFDFB',
  100: '#FAFAF7',  // Card BG
  200: '#F5F4F0',
},
```

**Full colors section should look like:**

```typescript
colors: {
  // PRIMARY: Deep Navy
  haven: {
    50: '#F5F7FA',
    100: '#E8ECF2',
    200: '#CBD5E1',
    300: '#94A3B8',
    400: '#64748B',
    500: '#475569',
    600: '#334155',
    700: '#1E2A3B',
    800: '#172032',
    900: '#111827',
    950: '#0B1120',
  },
  'haven-navy': {
    50: '#F5F7FA',
    100: '#E8ECF2',
    200: '#CBD5E1',
    300: '#94A3B8',
    400: '#64748B',
    500: '#475569',
    600: '#334155',
    700: '#1E2A3B',
    800: '#172032',
    900: '#102a43',
    950: '#0a1929',
  },
  // ACCENT: Sage Green (replaces champagne)
  sage: {
    50: '#F4F6F2',
    100: '#E8EDE4',
    200: '#D1DBC9',
    300: '#A4B494',
    400: '#8FA37F',
    500: '#7D8E74',
    600: '#6B7A63',
    700: '#5A6853',
    800: '#4A5544',
    900: '#3B4536',
  },
  // Card backgrounds
  cream: {
    50: '#FEFDFB',
    100: '#FAFAF7',
    200: '#F5F4F0',
  },
  // NEUTRALS: Warm grays (keep as-is)
  warm: {
    50: '#FAFAF9',
    100: '#F5F5F4',
    200: '#E7E5E4',
    300: '#D6D3D1',
    400: '#A8A29E',
    500: '#78716C',
    600: '#57534E',
    700: '#44403C',
    800: '#292524',
    900: '#1C1917',
    950: '#0C0A09',
  },
  // Keep gold for premium badges only (Estate tier, etc.)
  gold: {
    50: '#FDFBF3',
    100: '#FBF5E1',
    200: '#F6E9C3',
    300: '#EFD89C',
    400: '#E5C06D',
    500: '#DBA844',
    600: '#C48C33',
    700: '#A36D2B',
    800: '#855729',
    900: '#6D4825',
    950: '#3D2512',
  },
},
```

---

## PHASE 2: Update Global CSS

**File:** `apps/web/src/app/globals.css`

Update the body background and any champagne references:

```css
body {
  @apply font-sans text-warm-800 bg-sage-50;
  font-feature-settings: 'cv02', 'cv03', 'cv04', 'cv11';
}
```

Add new utility classes:

```css
/* Sage accent card */
.card-sage {
  @apply bg-gradient-to-br from-sage-50 to-sage-100 rounded-2xl border border-sage-200;
}

/* Badge variants */
.badge-sage {
  @apply bg-sage-100 text-sage-700 ring-1 ring-inset ring-sage-500/20;
}
```

---

## PHASE 3: Update Homepage

**File:** `apps/web/src/app/page.tsx`

### Global Search & Replace

| Find | Replace With |
|------|--------------|
| `champagne-50` | `sage-50` |
| `champagne-100` | `sage-100` |
| `champagne-200` | `sage-200` |
| `champagne-300` | `sage-300` |
| `champagne-400` | `sage-500` |
| `champagne-500` | `sage-500` |
| `champagne-600` | `sage-600` |
| `champagne-700` | `sage-700` |
| `bg-warm-50` | `bg-sage-50` or `bg-cream-100` |

### Specific Changes

#### 1. Hero Section

**Badge:**
```tsx
<div className="inline-flex items-center gap-2 px-3 py-1.5 bg-white/10 backdrop-blur border border-white/20 rounded-full mb-6">
  <Sparkles className="w-4 h-4 text-sage-300" />
  <span className="text-sm font-medium text-white">Meet Alfred</span>
  <span className="text-white/40">|</span>
  <span className="text-sm text-white/80">Your Home Manager</span>
</div>
```

**H1 accent color:**
```tsx
<h1 className="text-4xl sm:text-5xl lg:text-6xl font-bold text-white tracking-tight leading-[1.1] font-serif">
  Your home, finally
  <br />
  <span className="text-sage-300">under control.</span>
</h1>
```

**Price badge (clean stacked):**
```tsx
<div className="mt-6">
  <div className="flex items-baseline gap-1">
    <span className="text-4xl font-bold text-white">$39</span>
    <span className="text-xl text-white/70">/month</span>
  </div>
  <p className="text-sm text-sage-300 mt-1">Cancel anytime. No setup fees.</p>
</div>
```

**Value prop checkmarks:**
```tsx
<CheckCircle2 className="w-5 h-5 text-sage-300" />
```

**Primary CTA (white on dark):**
```tsx
<Link
  href="/onboarding/welcome"
  className="w-full sm:w-auto px-8 py-4 bg-white text-haven-navy-900 font-semibold rounded-xl hover:bg-sage-50 transition-all shadow-lg text-lg flex items-center justify-center gap-2"
>
  Get Started with Alfred
  <ArrowRight className="w-5 h-5" />
</Link>
```

**Trust badges:**
```tsx
<Star className="w-4 h-4 text-sage-300 fill-current" />
```

#### 2. AlfredChatPreview Component

Update `apps/web/src/components/marketing/AlfredChatPreview.tsx`:

```tsx
// Header sparkle
<Sparkles className="w-4 h-4 text-sage-300" />

// Online indicator
<div className="absolute -bottom-0.5 -right-0.5 w-3 h-3 bg-sage-400 border-2 border-haven-navy-900 rounded-full" />

// Bottom prompt box
<div className="bg-sage-50 rounded-xl p-3 border border-sage-200">
  <p className="text-sm text-sage-700 flex items-center gap-2">
    <Sparkles className="w-4 h-4" />
    Just forward your emails. I'll handle the rest.
  </p>
</div>
```

#### 3. How It Works Section (Expanded)

```tsx
<section id="how-it-works" className="py-16 sm:py-24 bg-white">
  <div className="max-w-6xl mx-auto px-4 sm:px-6">
    <div className="text-center mb-12">
      <h2 className="text-3xl sm:text-4xl font-bold text-warm-900">
        How Alfred Works
      </h2>
      <p className="mt-4 text-lg text-warm-600 max-w-2xl mx-auto">
        Add your home once. Alfred handles everything else — tracking, reminders, bills, and more.
      </p>
    </div>

    <div className="grid md:grid-cols-3 gap-8">
      {[
        {
          step: '1',
          title: 'Add Your Home',
          description: 'Forward bills and receipts to Alfred. Add your home systems — HVAC, roof, water heater. Upload warranties and manuals. Alfred builds your complete home profile.',
          icon: Home,
          color: 'bg-sage-100 text-sage-700',
        },
        {
          step: '2',
          title: 'Alfred Tracks Everything',
          description: 'Bills, maintenance schedules, service history, warranties. Alfred knows when your furnace was last serviced, when your roof needs inspection, and what filters you need.',
          icon: ClipboardList,
          color: 'bg-sage-100 text-sage-700',
        },
        {
          step: '3',
          title: 'Never Miss Anything',
          description: 'Proactive reminders before things break. Vendor recommendations when you need service. And one monthly bill that covers everything — no more juggling due dates.',
          icon: Bell,
          color: 'bg-sage-100 text-sage-700',
        },
      ].map((item, idx) => (
        <div key={idx} className="relative">
          {idx < 2 && (
            <div className="hidden md:block absolute top-12 left-[60%] w-[80%] h-0.5 bg-gradient-to-r from-sage-300 to-transparent" />
          )}
          <div className="text-center">
            <div className="relative inline-flex mb-4">
              <div className={`w-20 h-20 rounded-2xl ${item.color} flex items-center justify-center shadow-lg`}>
                <item.icon className="w-9 h-9" />
              </div>
              <span className="absolute -top-2 -right-2 w-7 h-7 bg-haven-navy-900 text-white rounded-full flex items-center justify-center font-bold text-sm shadow-md">
                {item.step}
              </span>
            </div>
            <h3 className="text-xl font-semibold text-warm-900 mb-2">{item.title}</h3>
            <p className="text-warm-600">{item.description}</p>
          </div>
        </div>
      ))}
    </div>

    <p className="text-sm text-warm-500 mt-12 text-center max-w-2xl mx-auto">
      Forward any home email to Alfred: utility bills, contractor invoices, warranties, service confirmations, appliance receipts — he handles them all.
    </p>
  </div>
</section>
```

#### 4. What Alfred Does Section

Update feature card colors:
```tsx
// Change champagne cards to sage
{
  icon: BookOpen,
  title: 'Builds Your Home Manual',
  description: '...',
  color: 'bg-sage-100 text-sage-700',
},
{
  icon: MessageCircle,
  title: 'Answers Anything',
  description: '...',
  color: 'bg-sage-100 text-sage-700',
},
```

#### 5. Use Cases Section

**"Most Popular" badge:**
```tsx
<span className="px-4 py-1.5 bg-sage-500 text-white text-sm font-bold rounded-full shadow-lg">
  Most Popular
</span>
```

**The Optimizer card border:**
```tsx
className="bg-white rounded-2xl border-2 border-sage-400 overflow-hidden hover:shadow-xl transition-all hover:border-sage-500 relative"
```

**Card accent bar:**
```tsx
<div className="h-2 bg-gradient-to-r from-sage-400 to-sage-500" />
```

**CTA buttons on use case cards:**
```tsx
// Newcomer & Optimizer (both $39)
className="block w-full py-3 text-center bg-haven-navy-900 text-white font-semibold rounded-xl hover:bg-haven-navy-800 transition-colors"

// Busy Bee ($349) - keep purple
className="block w-full py-3 text-center bg-purple-600 text-white font-semibold rounded-xl hover:bg-purple-700 transition-colors"
```

#### 6. Pricing Section

**"Start Here" badge:**
```tsx
<span className="px-4 py-1.5 bg-sage-500 text-white text-sm font-bold rounded-full shadow-lg">
  Start Here
</span>
```

**Essentials card border:**
```tsx
className="bg-white rounded-2xl border-2 border-sage-400 overflow-hidden flex flex-col shadow-xl"
```

**Essentials accent bar:**
```tsx
<div className="h-2 bg-gradient-to-r from-sage-400 to-sage-500" />
```

**Checkmarks:**
```tsx
<Check className="w-5 h-5 text-sage-500 flex-shrink-0 mt-0.5" />
```

**Essentials CTA:**
```tsx
className="block w-full py-3 text-center bg-haven-navy-900 text-white font-semibold rounded-xl hover:bg-haven-navy-800 transition-colors"
```

#### 7. Testimonials Section

**Background:**
```tsx
className="py-16 sm:py-24 bg-gradient-to-b from-sage-50 to-sage-100/50"
```

**Use case badges:**
```tsx
// The Newcomer
color: 'bg-haven-100 text-haven-700',

// The Optimizer  
color: 'bg-sage-100 text-sage-700',

// The Busy Bee
color: 'bg-purple-100 text-purple-700',
```

#### 8. Final CTA Section

**Accent text:**
```tsx
<Sparkles className="w-5 h-5 text-sage-300" />
```

**CTA button (white on dark):**
```tsx
<Link
  href="/onboarding/welcome"
  className="w-full sm:w-auto px-8 py-4 bg-white text-haven-navy-900 font-semibold rounded-xl hover:bg-sage-50 transition-colors shadow-lg text-lg flex items-center justify-center gap-2"
>
  Get Started with Alfred — $39/mo
  <ArrowRight className="w-5 h-5" />
</Link>
```

#### 9. Footer

**Accent:**
```tsx
<Star className="w-4 h-4 text-sage-300 fill-current" />
```

---

## PHASE 4: Update Additional Components

### Navbar (if using sage accents)

Any champagne references in the navbar should become sage.

### Other Pages

Run a global search for `champagne` across the web app and replace with `sage` equivalent:
```bash
grep -r "champagne" apps/web/src/ --include="*.tsx"
```

---

## Color Quick Reference

### Button Strategy

| Location | Background | Text | Hover |
|----------|------------|------|-------|
| Hero CTA (dark bg) | `bg-white` | `text-haven-navy-900` | `hover:bg-sage-50` |
| Light section CTA | `bg-haven-navy-900` | `text-white` | `hover:bg-haven-navy-800` |
| Final CTA (dark bg) | `bg-white` | `text-haven-navy-900` | `hover:bg-sage-50` |
| Secondary/Ghost | `bg-sage-100` | `text-sage-700` | `hover:bg-sage-200` |

### Accent Usage

| Element | Color |
|---------|-------|
| "Start Here" badge | `bg-sage-500 text-white` |
| "Most Popular" badge | `bg-sage-500 text-white` |
| Checkmarks | `text-sage-500` |
| Sparkle icons (dark bg) | `text-sage-300` |
| Sparkle icons (light bg) | `text-sage-500` |
| Card borders (featured) | `border-sage-400` |
| Accent bars | `bg-gradient-to-r from-sage-400 to-sage-500` |
| Subtle backgrounds | `bg-sage-50` or `bg-sage-100` |

### Section Backgrounds

| Section | Background |
|---------|------------|
| Hero | Navy gradient (keep as-is) |
| How It Works | `bg-white` |
| What Alfred Does | `bg-sage-50` or gradient to white |
| Handyman | Dark (`warm-900` gradient, keep) |
| Use Cases | `bg-white` |
| One Bill | Navy (`haven-navy-900`, keep) |
| Pricing | `bg-white` |
| Testimonials | `bg-gradient-to-b from-sage-50 to-sage-100/50` |
| FAQ | `bg-white` |
| Final CTA | Navy gradient (keep) |

---

## Verification Checklist

### Colors
- [ ] No `champagne` references remain in page.tsx
- [ ] Tailwind config has `sage` and `cream` colors
- [ ] Body background is `bg-sage-50`
- [ ] Badges are sage green, not champagne
- [ ] Checkmarks are `text-sage-500`
- [ ] Sparkles are `text-sage-300` (dark) / `text-sage-500` (light)

### Buttons
- [ ] Hero CTA: white with navy text
- [ ] Light section CTAs: navy with white text
- [ ] Final CTA: white with navy text
- [ ] Hover states use sage-50 tint

### Visual Fixes
- [ ] Price badge is stacked cleanly (not cramped)
- [ ] "How It Works" shows full value (systems, maintenance, not just email)
- [ ] Cards use `rounded-2xl`
- [ ] Buttons use `rounded-xl`

### Typography
- [ ] Only hero h1 uses `font-serif`
- [ ] All other headings use Inter (default)

---

## Build & Test

```bash
cd /Users/tomburke/Projects/Housing-Manager
pnpm build
pnpm dev:web
# Check http://localhost:3000
```

---

## Summary

| Before | After |
|--------|-------|
| Champagne (`#c4a574`) | Sage (`#7D8E74`) |
| Flat beige buttons | White (dark bg) / Navy (light bg) |
| Cramped price badge | Clean stacked layout |
| "How It Works" = email only | Full home management value |

**New Vibe:** Natural, grounded, calm. A well-organized home with a garden. Modern without being cold.
