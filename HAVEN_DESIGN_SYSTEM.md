# Haven Homepage Design System & Implementation Guide

## Executive Summary

This document provides a complete design evaluation and implementation specification for the Haven homepage. After analyzing the current design against competitor Nines Living and industry best practices, this guide addresses typography, color palette, spacing, navigation, and component styling to create a premium, trustworthy appearance.

---

## PART 1: DESIGN EVALUATION

### Current Issues Identified

| Area | Problem | Impact |
|------|---------|--------|
| **Navigation** | No top navigation bar visible | Users can't easily navigate, no login access, looks incomplete |
| **Typography** | Generic system fonts, poor hierarchy | Lacks premium feel, hard to scan |
| **Color Usage** | Monotone green, sections blend together | No visual rhythm, feels flat |
| **Whitespace** | Inconsistent spacing, sections crowded | Looks cramped, unprofessional |
| **Depth** | Flat cards, no shadows | Lacks dimension, feels dated |
| **Buttons** | Inconsistent styling | Confusing hierarchy of actions |

### Competitor Analysis: Nines Living

**What Nines Does Well:**
1. **Professional Navigation** - Clean top bar with logo left, menu center, CTA right
2. **Typography** - Refined serif/sans-serif pairing, clear hierarchy
3. **Whitespace** - Generous padding, content breathes
4. **Credibility** - Trust badges, press logos, testimonials prominent
5. **Depth** - Subtle shadows, layered elements
6. **Premium Feel** - Sophisticated color palette, refined interactions

**What Haven Should Adopt:**
- Fixed top navigation with login
- Better font pairing and sizing
- More generous whitespace
- Cleaner section transitions
- Subtle depth through shadows
- Refined micro-interactions

---

## PART 2: NAVIGATION BAR SPECIFICATION

### Structure

```
┌─────────────────────────────────────────────────────────────────────┐
│  [Logo]     Home  Services  Pricing  About  |  [Login]  [Get Started] │
└─────────────────────────────────────────────────────────────────────┘
```

### Navigation Component Code

Create a new file `apps/web/src/components/marketing/Navbar.tsx`:

```tsx
'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { Menu, X, ChevronDown } from 'lucide-react';

export function Navbar() {
  const [isScrolled, setIsScrolled] = useState(false);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 20);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  return (
    <nav
      className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
        isScrolled
          ? 'bg-white/95 backdrop-blur-md shadow-sm border-b border-warm-100'
          : 'bg-transparent'
      }`}
    >
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16 lg:h-20">
          {/* Logo */}
          <Link href="/" className="flex items-center gap-2">
            <div className={`text-2xl font-bold transition-colors ${
              isScrolled ? 'text-haven-600' : 'text-white'
            }`}>
              Haven
            </div>
          </Link>

          {/* Desktop Navigation */}
          <div className="hidden lg:flex items-center gap-8">
            <Link
              href="#how-it-works"
              className={`text-sm font-medium transition-colors hover:text-haven-500 ${
                isScrolled ? 'text-warm-700' : 'text-white/90 hover:text-white'
              }`}
            >
              How It Works
            </Link>
            <Link
              href="#services"
              className={`text-sm font-medium transition-colors hover:text-haven-500 ${
                isScrolled ? 'text-warm-700' : 'text-white/90 hover:text-white'
              }`}
            >
              Services
            </Link>
            <Link
              href="#pricing"
              className={`text-sm font-medium transition-colors hover:text-haven-500 ${
                isScrolled ? 'text-warm-700' : 'text-white/90 hover:text-white'
              }`}
            >
              Pricing
            </Link>
            <Link
              href="#faq"
              className={`text-sm font-medium transition-colors hover:text-haven-500 ${
                isScrolled ? 'text-warm-700' : 'text-white/90 hover:text-white'
              }`}
            >
              FAQ
            </Link>
          </div>

          {/* Desktop CTA */}
          <div className="hidden lg:flex items-center gap-4">
            <Link
              href="/login"
              className={`text-sm font-medium transition-colors ${
                isScrolled ? 'text-warm-700 hover:text-haven-600' : 'text-white/90 hover:text-white'
              }`}
            >
              Sign In
            </Link>
            <Link
              href="/register"
              className={`px-5 py-2.5 text-sm font-semibold rounded-lg transition-all ${
                isScrolled
                  ? 'bg-haven-600 text-white hover:bg-haven-700 shadow-sm'
                  : 'bg-white text-haven-700 hover:bg-white/90 shadow-lg shadow-black/10'
              }`}
            >
              Get Started
            </Link>
          </div>

          {/* Mobile Menu Button */}
          <button
            onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
            className={`lg:hidden p-2 rounded-lg transition-colors ${
              isScrolled ? 'text-warm-700 hover:bg-warm-100' : 'text-white hover:bg-white/10'
            }`}
          >
            {isMobileMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
          </button>
        </div>

        {/* Mobile Menu */}
        {isMobileMenuOpen && (
          <div className="lg:hidden bg-white border-t border-warm-100 py-4 px-2">
            <div className="flex flex-col gap-1">
              <Link
                href="#how-it-works"
                className="px-4 py-3 text-warm-700 font-medium rounded-lg hover:bg-warm-50"
                onClick={() => setIsMobileMenuOpen(false)}
              >
                How It Works
              </Link>
              <Link
                href="#services"
                className="px-4 py-3 text-warm-700 font-medium rounded-lg hover:bg-warm-50"
                onClick={() => setIsMobileMenuOpen(false)}
              >
                Services
              </Link>
              <Link
                href="#pricing"
                className="px-4 py-3 text-warm-700 font-medium rounded-lg hover:bg-warm-50"
                onClick={() => setIsMobileMenuOpen(false)}
              >
                Pricing
              </Link>
              <Link
                href="#faq"
                className="px-4 py-3 text-warm-700 font-medium rounded-lg hover:bg-warm-50"
                onClick={() => setIsMobileMenuOpen(false)}
              >
                FAQ
              </Link>
              <div className="border-t border-warm-100 mt-2 pt-2">
                <Link
                  href="/login"
                  className="block px-4 py-3 text-warm-700 font-medium rounded-lg hover:bg-warm-50"
                  onClick={() => setIsMobileMenuOpen(false)}
                >
                  Sign In
                </Link>
                <Link
                  href="/register"
                  className="block mx-2 mt-2 px-4 py-3 bg-haven-600 text-white font-semibold rounded-lg text-center hover:bg-haven-700"
                  onClick={() => setIsMobileMenuOpen(false)}
                >
                  Get Started
                </Link>
              </div>
            </div>
          </div>
        )}
      </div>
    </nav>
  );
}
```

### Integration in page.tsx

At the top of the page component, import and add the Navbar:

```tsx
import { Navbar } from '@/components/marketing/Navbar';

export default function MarketingPage() {
  // ... state ...

  return (
    <div className="min-h-screen bg-white">
      {/* Add Navbar */}
      <Navbar />
      
      {/* Hero section needs top padding to account for fixed nav */}
      <section className="relative overflow-hidden ... pt-24 sm:pt-28 pb-16 sm:pb-24">
      {/* ... rest of content ... */}
    </div>
  );
}
```

---

## PART 3: TYPOGRAPHY SYSTEM

### Font Stack Recommendation

**Primary Font (Headings):** Inter or system-ui
**Secondary Font (Body):** Inter or system-ui

If you want more premium feel, consider adding Google Fonts:
- **Headings:** "Plus Jakarta Sans" (modern, geometric)
- **Body:** "Inter" (clean, readable)

### Typography Scale

| Element | Size (Mobile) | Size (Desktop) | Weight | Line Height | Letter Spacing |
|---------|---------------|----------------|--------|-------------|----------------|
| H1 (Hero) | 36px (text-4xl) | 60px (text-6xl) | 700 (bold) | 1.1 | -0.02em (tracking-tight) |
| H2 (Section) | 30px (text-3xl) | 40px (text-4xl) | 700 (bold) | 1.2 | -0.01em |
| H3 (Card) | 18px (text-lg) | 20px (text-xl) | 600 (semibold) | 1.3 | 0 |
| H4 (Subhead) | 16px (text-base) | 18px (text-lg) | 600 (semibold) | 1.4 | 0 |
| Body Large | 18px (text-lg) | 20px (text-xl) | 400 (normal) | 1.6 | 0 |
| Body | 16px (text-base) | 16px (text-base) | 400 (normal) | 1.6 | 0 |
| Body Small | 14px (text-sm) | 14px (text-sm) | 400 (normal) | 1.5 | 0 |
| Caption | 12px (text-xs) | 12px (text-xs) | 500 (medium) | 1.4 | 0.05em (tracking-wide) |
| Label | 12px (text-xs) | 14px (text-sm) | 600 (semibold) | 1.4 | 0.05em (tracking-wide) |

### Typography Classes to Use

```tsx
// Hero Headline
<h1 className="text-4xl sm:text-5xl lg:text-6xl font-bold tracking-tight leading-[1.1]">

// Section Headline
<h2 className="text-3xl sm:text-4xl font-bold tracking-tight">

// Section Subheadline
<p className="mt-4 text-lg sm:text-xl text-warm-600 leading-relaxed">

// Card Title
<h3 className="text-lg sm:text-xl font-semibold text-warm-900">

// Body Text
<p className="text-base text-warm-600 leading-relaxed">

// Small Label (uppercase)
<span className="text-xs sm:text-sm font-semibold text-haven-600 uppercase tracking-wide">

// Caption
<span className="text-xs text-warm-500">
```

---

## PART 4: COLOR SYSTEM

### Primary Palette

Keep the Haven green but refine usage:

```
Haven Green (Primary):
- haven-50:  #f0fdf4  (very light tint, backgrounds)
- haven-100: #dcfce7  (light tint, hover states)
- haven-200: #bbf7d0  (accents)
- haven-300: #86efac  (highlights)
- haven-400: #4ade80  (interactive elements)
- haven-500: #22c55e  (primary buttons hover)
- haven-600: #16a34a  (PRIMARY - buttons, links)
- haven-700: #15803d  (primary hover/active)
- haven-800: #166534  (dark green)
- haven-900: #14532d  (very dark)
```

### Secondary Palette (Amber Accent)

Use amber for highlights and CTAs on dark backgrounds:

```
Amber (Secondary Accent):
- amber-50:  #fffbeb
- amber-100: #fef3c7
- amber-200: #fde68a
- amber-300: #fcd34d
- amber-400: #fbbf24  (accent highlights)
- amber-500: #f59e0b  (CTAs on dark)
- amber-600: #d97706
```

### Neutral Palette

```
Warm Neutrals:
- warm-50:  #fafaf9   (page backgrounds)
- warm-100: #f5f5f4   (section backgrounds)
- warm-200: #e7e5e4   (borders, dividers)
- warm-300: #d6d3d1   (disabled states)
- warm-400: #a8a29e   (placeholder text)
- warm-500: #78716c   (secondary text)
- warm-600: #57534e   (body text)
- warm-700: #44403c   (headings)
- warm-800: #292524   (dark headings)
- warm-900: #1c1917   (darkest text, dark bg)
```

### Semantic Colors

```
Success: green-500 (#22c55e)
Warning: amber-500 (#f59e0b)
Error: red-500 (#ef4444)
Info: blue-500 (#3b82f6)
```

### Color Usage Rules

| Element | Color | Notes |
|---------|-------|-------|
| Primary CTA (light bg) | `bg-haven-600 text-white` | Main action buttons |
| Primary CTA (dark bg) | `bg-amber-500 text-warm-900` | Stand out on dark sections |
| Secondary CTA | `bg-warm-100 text-warm-700` | Less prominent actions |
| Ghost CTA (dark bg) | `border-white/30 text-white` | Alternative actions |
| Links | `text-haven-600 hover:text-haven-700` | Interactive text |
| Headlines | `text-warm-900` | Maximum contrast |
| Body text | `text-warm-600` | Comfortable reading |
| Secondary text | `text-warm-500` | De-emphasized |
| Borders | `border-warm-200` | Subtle separation |
| Card backgrounds | `bg-white` | Clean containers |
| Section alternation | `bg-white` → `bg-warm-50` → `bg-haven-600` | Visual rhythm |

---

## PART 5: SPACING SYSTEM

### Spacing Scale (Tailwind)

| Token | Value | Usage |
|-------|-------|-------|
| 1 | 4px | Tight spacing, icon gaps |
| 2 | 8px | Small gaps, compact lists |
| 3 | 12px | Default gap between inline items |
| 4 | 16px | Standard padding, card gaps |
| 6 | 24px | Section padding (mobile) |
| 8 | 32px | Generous card padding |
| 12 | 48px | Section vertical padding (sm) |
| 16 | 64px | Section vertical padding (lg) |
| 20 | 80px | Large section padding |
| 24 | 96px | Extra large section padding |

### Section Padding Standard

```tsx
// Standard section (light background)
<section className="py-16 sm:py-24">

// Compact section
<section className="py-12 sm:py-16">

// Hero section (with nav offset)
<section className="pt-24 sm:pt-28 pb-16 sm:pb-24">
```

### Container Width

```tsx
// Standard content width
<div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">

// Narrow content (text-heavy)
<div className="max-w-3xl mx-auto px-4 sm:px-6">

// Medium content (pricing, features)
<div className="max-w-5xl mx-auto px-4 sm:px-6">
```

---

## PART 6: SHADOW & DEPTH SYSTEM

### Shadow Scale

```
shadow-sm:   0 1px 2px rgba(0,0,0,0.05)              - Subtle lift
shadow:      0 1px 3px rgba(0,0,0,0.1)               - Default cards
shadow-md:   0 4px 6px rgba(0,0,0,0.1)               - Elevated cards
shadow-lg:   0 10px 15px rgba(0,0,0,0.1)             - Modals, dropdowns
shadow-xl:   0 20px 25px rgba(0,0,0,0.1)             - Hover states
shadow-2xl:  0 25px 50px rgba(0,0,0,0.25)            - Hero cards
```

### Depth Usage

| Element | Default | Hover |
|---------|---------|-------|
| Navigation (scrolled) | `shadow-sm` | - |
| Standard card | `shadow-sm` or `border` | `shadow-lg` |
| Featured card | `shadow-lg` | `shadow-xl` |
| Hero chat mockup | `shadow-2xl` | - |
| Pricing card (popular) | `shadow-xl shadow-haven-100` | - |
| Buttons | `shadow-sm` | `shadow-md` |

### Card Hover Effect

```tsx
// Standard card with hover lift
<div className="bg-white rounded-2xl border border-warm-200 p-6 
  transition-all duration-300 hover:shadow-lg hover:-translate-y-1">

// Featured card (already elevated)
<div className="bg-white rounded-2xl shadow-xl p-6
  transition-all duration-300 hover:shadow-2xl">
```

---

## PART 7: COMPONENT SPECIFICATIONS

### Buttons

```tsx
// Primary Button (light background)
<button className="px-6 py-3 bg-haven-600 text-white font-semibold rounded-xl 
  hover:bg-haven-700 transition-all shadow-sm hover:shadow-md">
  Get Started
</button>

// Primary Button (dark background)
<button className="px-6 py-3 bg-amber-500 text-warm-900 font-semibold rounded-xl 
  hover:bg-amber-400 transition-all shadow-sm hover:shadow-md">
  Get Started
</button>

// Secondary Button
<button className="px-6 py-3 bg-warm-100 text-warm-700 font-semibold rounded-xl 
  hover:bg-warm-200 transition-colors">
  Learn More
</button>

// Ghost Button (dark background)
<button className="px-6 py-3 border-2 border-white/30 text-white font-semibold rounded-xl 
  hover:bg-white/10 transition-colors">
  Compare Plans
</button>

// Text Link Button
<button className="text-haven-600 font-medium hover:text-haven-700 transition-colors 
  inline-flex items-center gap-1">
  View details <ArrowRight className="w-4 h-4" />
</button>
```

### Cards

```tsx
// Standard Card
<div className="bg-white rounded-2xl border border-warm-200 p-6 
  transition-all duration-300 hover:shadow-lg hover:-translate-y-1">
  {/* Card content */}
</div>

// Card with Accent Bar
<div className="bg-white rounded-2xl border border-warm-200 overflow-hidden
  transition-all duration-300 hover:shadow-lg hover:-translate-y-1">
  <div className="h-1.5 bg-gradient-to-r from-haven-500 to-haven-600" />
  <div className="p-6">
    {/* Card content */}
  </div>
</div>

// Featured Card (Most Popular)
<div className="bg-white rounded-2xl border-2 border-haven-500 overflow-hidden
  shadow-xl shadow-haven-500/10">
  <div className="h-1.5 bg-gradient-to-r from-haven-500 to-haven-600" />
  <div className="p-6">
    {/* Card content */}
  </div>
</div>

// Dark Card
<div className="bg-gradient-to-br from-warm-900 to-warm-800 rounded-2xl p-6 text-white">
  {/* Card content */}
</div>
```

### Badges

```tsx
// Trust Badge
<div className="inline-flex items-center gap-2 px-3 py-1.5 bg-white/10 backdrop-blur 
  border border-white/20 rounded-full">
  <Star className="w-4 h-4 text-amber-400 fill-current" />
  <span className="text-sm font-medium text-white">4.9/5</span>
</div>

// Label Badge
<span className="px-3 py-1 bg-haven-100 text-haven-700 text-xs font-semibold rounded-full">
  Most Popular
</span>

// Status Badge
<span className="px-2 py-0.5 bg-green-100 text-green-700 text-xs font-medium rounded-full">
  Active
</span>
```

### Section Headers

```tsx
// Standard Section Header
<div className="text-center mb-12 sm:mb-16">
  <span className="text-sm font-semibold text-haven-600 uppercase tracking-wide">
    Section Label
  </span>
  <h2 className="mt-2 text-3xl sm:text-4xl font-bold text-warm-900 tracking-tight">
    Section Headline
  </h2>
  <p className="mt-4 text-lg text-warm-600 max-w-2xl mx-auto">
    Section description text goes here with supporting information.
  </p>
</div>

// Left-Aligned Section Header
<div className="mb-8 sm:mb-12">
  <span className="text-sm font-semibold text-haven-600 uppercase tracking-wide">
    Section Label
  </span>
  <h2 className="mt-2 text-3xl sm:text-4xl font-bold text-warm-900 tracking-tight">
    Section Headline
  </h2>
</div>
```

---

## PART 8: SECTION-BY-SECTION IMPLEMENTATION

### Hero Section

**Background:** Dark gradient `bg-gradient-to-br from-haven-600 via-haven-700 to-haven-800`
**Padding:** `pt-24 sm:pt-28 pb-16 sm:pb-24` (accounts for fixed nav)

Key elements:
- Decorative blur circles in background
- Trust badge with star rating
- Large headline with amber accent
- Subheadline in haven-100
- Amber primary CTA, ghost secondary CTA
- Trust badges (FDIC, SOC 2, Vetted Pros)
- Chat mockup with shadow-2xl

### Pain Points Section

**Background:** `bg-white`
**Padding:** `py-16 sm:py-24`

Key elements:
- "Without Haven" card: `bg-red-50 border-red-100`
- "With Haven" card: `bg-gradient-to-br from-haven-600 to-haven-700`
- Stat highlight bar below: `bg-amber-100` with amber text

### How It Works Section

**Background:** `bg-gradient-to-b from-warm-100 to-warm-50`
**Padding:** `py-16 sm:py-24`

Key elements:
- Colored icon containers with shadows
- Numbered step badges
- Connector lines between steps

### Services Section

**Background:** `bg-white`
**Padding:** `py-16 sm:py-24`

Key elements:
- Cards with colored top accent bars
- Hover lift effect
- Colored icon backgrounds

### Handyman Section

**Background:** `bg-gradient-to-br from-warm-900 via-warm-800 to-warm-900`
**Padding:** `py-16 sm:py-24`

Key elements:
- Decorative blur circles
- Amber accent label
- White heading text
- Warm-300 body text
- White card with shadow-2xl

### Pricing Section

**Background:** `bg-gradient-to-b from-haven-50 to-white`
**Padding:** `py-16 sm:py-24`

Key elements:
- Cards with colored top accent bars
- Most Popular badge with gradient
- Featured card with border-2 and shadow

### Compare Plans Section

**Background:** `bg-warm-900`
**Padding:** `py-16 sm:py-24`

Key elements:
- Table on dark background
- Amber highlights for "Lite" column
- Green checkmarks, muted X marks

### Software vs Service Section

**Background:** `bg-white`
**Padding:** `py-16 sm:py-24`

Key elements:
- Red tint for competitor column
- Green/haven tint for Haven column
- Gradient CTA box at bottom

### Testimonials Section

**Background:** `bg-gradient-to-b from-amber-50 to-amber-100/50`
**Padding:** `py-16 sm:py-24`

Key elements:
- White cards with shadow-lg
- Consistent avatar styling
- Colored highlight badges
- Stats in white cards with shadows

### FAQ Section

**Background:** `bg-white`
**Padding:** `py-16 sm:py-24`

Key elements:
- Accordion with warm-50 expanded background
- Haven-colored chevron when open

### Final CTA Section

**Background:** `bg-gradient-to-br from-haven-600 via-haven-700 to-haven-800`
**Padding:** `py-16 sm:py-24`

Key elements:
- Decorative blur circles
- Amber highlight text
- Amber primary CTA
- Ghost secondary CTA

### Footer

**Background:** `bg-warm-900`
**Padding:** `py-12`

Key elements:
- Light text on dark background
- Organized link columns
- Trust badges

---

## PART 9: IMPLEMENTATION CHECKLIST

### Phase 1: Foundation
- [ ] Create Navbar component
- [ ] Add Navbar to page.tsx
- [ ] Adjust hero padding for fixed nav
- [ ] Remove all em dashes

### Phase 2: Typography
- [ ] Update all headlines to use proper scale
- [ ] Add tracking-tight to large headlines
- [ ] Ensure consistent text colors
- [ ] Add proper line heights

### Phase 3: Colors & Backgrounds
- [ ] Update hero to dark gradient
- [ ] Add amber accents throughout
- [ ] Implement section background alternation
- [ ] Fix handyman section colors

### Phase 4: Components
- [ ] Add shadow system to cards
- [ ] Implement hover effects
- [ ] Add colored accent bars to cards
- [ ] Update button styles

### Phase 5: Polish
- [ ] Add decorative blur circles to dark sections
- [ ] Verify responsive behavior
- [ ] Test all hover states
- [ ] Verify contrast ratios

---

## PART 10: FULL PAGE.TSX UPDATES

### Import the Navbar

At the top of the file, add:

```tsx
import { Navbar } from '@/components/marketing/Navbar';
```

### Update the Return Statement

The page should start with:

```tsx
return (
  <div className="min-h-screen bg-white">
    {/* Navigation */}
    <Navbar />
    
    {/* Hero - note the pt-24 to account for fixed nav */}
    <section className="relative overflow-hidden bg-gradient-to-br from-haven-600 via-haven-700 to-haven-800 pt-24 sm:pt-28 pb-16 sm:pb-24">
      {/* ... hero content ... */}
    </section>
    
    {/* Rest of sections... */}
  </div>
);
```

---

## VERIFICATION

After implementation, verify:

1. **Navigation**
   - [ ] Navbar appears at top of page
   - [ ] Navbar is transparent on hero, white when scrolled
   - [ ] Login and Get Started buttons visible
   - [ ] Mobile menu works correctly

2. **Typography**
   - [ ] Headlines are bold with tight tracking
   - [ ] Body text is readable (warm-600)
   - [ ] Proper hierarchy throughout

3. **Colors**
   - [ ] Haven green is primary
   - [ ] Amber is used for accents/highlights
   - [ ] Dark sections use warm-900/800
   - [ ] Section backgrounds alternate

4. **Depth**
   - [ ] Cards have appropriate shadows
   - [ ] Hover states add depth
   - [ ] Featured elements are more elevated

5. **Spacing**
   - [ ] Consistent section padding
   - [ ] Generous whitespace
   - [ ] Content doesn't feel cramped

6. **Mobile**
   - [ ] All sections look good on mobile
   - [ ] Navigation hamburger works
   - [ ] Text is readable
   - [ ] Buttons are tappable

---

## DEPLOYMENT

After all changes:

```bash
# Build to check for errors
pnpm build

# Test locally
pnpm dev

# Commit
git add .
git commit -m "Redesign homepage with navigation, refined typography, and color system"

# Push to production
git push origin main
```
