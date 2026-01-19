# Haven Homepage Overhaul: Alfred-First Marketing

**Created:** January 16, 2025  
**Priority:** HIGH - Strategic marketing pivot  
**Estimated Time:** 2-3 hours

---

## Overview

Complete overhaul of the Haven homepage to lead with **Alfred** as the primary value proposition. The $39/month Essentials tier is the default choice for 90-99% of users, with human managers positioned as premium upgrades.

---

## Key Principles

1. **Alfred is the hero** - Not Sarah, not human managers
2. **$39 is the default** - "Start Here" positioning
3. **Hero = Total Value** - Bill consolidation, maintenance reminders, savings, one payment
4. **Email forwarding is a feature** - Shown in "How It Works", NOT the headline
5. **Handyman is a major value prop** - Dedicated section, real person who knows your home
6. **Home manual** - Key differentiator, Alfred builds it for you
7. **Three use cases** - Newcomer, Optimizer, Busy Bee
8. **NO AI language** - No "AI-powered", "powered by Claude", "machine learning", etc.

---

## Typography Standards

| Element | Font | Tailwind Class |
|---------|------|----------------|
| Hero h1 only | Playfair Display | `font-serif` |
| All section h2s | Inter | default (no class needed) |
| Body text | Inter | default |
| Buttons | Inter | default |
| Badges/Labels | Inter | default |

**Rules:**
- Only the main hero headline uses `font-serif`
- Everything else uses Inter (default sans-serif)
- Never mix serif into body text or section headers
- Text on dark backgrounds: `text-white` not `text-warm-900`

---

## Design Consistency

### Border Radius
| Element | Class |
|---------|-------|
| Cards, sections | `rounded-2xl` |
| Buttons, inputs | `rounded-xl` |
| Badges | `rounded-full` |

### Spacing
- Section padding: `py-16 sm:py-24`
- Container: `max-w-6xl mx-auto px-4 sm:px-6`
- Card padding: `p-6`
- Grid gaps: `gap-6` or `gap-8`

### Colors
| Use Case | Class |
|----------|-------|
| Primary CTA | `bg-champagne-400 text-haven-navy-900` |
| Secondary button | `bg-warm-100 text-warm-700` |
| Dark section text | `text-white`, `text-haven-200` |
| Accent | `text-champagne-500` (light) / `text-champagne-300` (dark) |

---

## PHASE 1: Copy Alfred Assets

```bash
cp /Users/tomburke/Projects/Housing-Manager/apps/mobile/assets/alfred/alfred-logo-light-bg.svg \
   /Users/tomburke/Projects/Housing-Manager/apps/web/public/alfred-logo.svg

cp /Users/tomburke/Projects/Housing-Manager/apps/mobile/assets/alfred/alfred-logo-dark-bg.svg \
   /Users/tomburke/Projects/Housing-Manager/apps/web/public/alfred-logo-white.svg

cp /Users/tomburke/Projects/Housing-Manager/apps/mobile/assets/alfred/alfred-icon-tab-mono.svg \
   /Users/tomburke/Projects/Housing-Manager/apps/web/public/alfred-icon.svg
```

---

## PHASE 2: Create Components

### 2.1 Create `apps/web/src/components/marketing/AlfredLogo.tsx`

```tsx
import Image from 'next/image';

interface AlfredLogoProps {
  variant?: 'light' | 'dark';
  size?: 'sm' | 'md' | 'lg' | 'xl';
  className?: string;
}

const sizes = { sm: 48, md: 80, lg: 120, xl: 160 };

export function AlfredLogo({ variant = 'light', size = 'md', className = '' }: AlfredLogoProps) {
  const src = variant === 'light' ? '/alfred-logo.svg' : '/alfred-logo-white.svg';
  return (
    <Image
      src={src}
      alt="Alfred"
      width={sizes[size]}
      height={sizes[size]}
      className={className}
    />
  );
}
```

### 2.2 Create `apps/web/src/components/marketing/AlfredChatPreview.tsx`

```tsx
'use client';

import { TrendingDown, Calendar, Mail, Sparkles } from 'lucide-react';

export function AlfredChatPreview() {
  return (
    <div className="relative bg-white rounded-2xl shadow-2xl border border-warm-200 overflow-hidden max-w-sm mx-auto lg:max-w-none">
      {/* Header */}
      <div className="bg-gradient-to-r from-haven-navy-900 to-haven-navy-800 px-4 py-3 flex items-center gap-3">
        <div className="relative">
          <div className="w-10 h-10 rounded-full bg-champagne-100 flex items-center justify-center">
            <img src="/alfred-icon.svg" alt="Alfred" className="w-6 h-6" />
          </div>
          <div className="absolute -bottom-0.5 -right-0.5 w-3 h-3 bg-champagne-400 border-2 border-haven-navy-900 rounded-full" />
        </div>
        <div>
          <p className="font-semibold text-white flex items-center gap-1.5">
            Alfred
            <Sparkles className="w-4 h-4 text-champagne-300" />
          </p>
          <p className="text-haven-200 text-sm">Your Home Manager</p>
        </div>
      </div>

      {/* Messages */}
      <div className="p-4 space-y-3 bg-warm-50">
        <div className="bg-white rounded-xl p-3 shadow-sm border border-warm-100">
          <div className="flex items-start gap-3">
            <div className="w-8 h-8 rounded-full bg-blue-100 flex items-center justify-center flex-shrink-0">
              <Mail className="w-4 h-4 text-blue-600" />
            </div>
            <div>
              <p className="font-medium text-warm-900">Got your Eversource bill</p>
              <p className="text-sm text-warm-500">Added to October bills. Due Nov 15.</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-xl p-3 shadow-sm border border-warm-100">
          <div className="flex items-start gap-3">
            <div className="w-8 h-8 rounded-full bg-green-100 flex items-center justify-center flex-shrink-0">
              <TrendingDown className="w-4 h-4 text-green-600" />
            </div>
            <div>
              <p className="font-medium text-warm-900">Found a better electric rate</p>
              <p className="text-sm text-warm-500">Switch to save $340/year</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-xl p-3 shadow-sm border border-warm-100">
          <div className="flex items-start gap-3">
            <div className="w-8 h-8 rounded-full bg-amber-100 flex items-center justify-center flex-shrink-0">
              <Calendar className="w-4 h-4 text-amber-600" />
            </div>
            <div>
              <p className="font-medium text-warm-900">Furnace service overdue</p>
              <p className="text-sm text-warm-500">Last serviced 26 months ago</p>
            </div>
          </div>
        </div>

        <div className="bg-champagne-50 rounded-xl p-3 border border-champagne-200">
          <p className="text-sm text-champagne-700 flex items-center gap-2">
            <Sparkles className="w-4 h-4" />
            Just forward your emails. I'll handle the rest.
          </p>
        </div>
      </div>

      {/* Stats */}
      <div className="bg-white border-t border-warm-200 px-4 py-3 flex items-center justify-around">
        <div className="text-center">
          <p className="text-lg font-bold text-haven-700">$340</p>
          <p className="text-xs text-warm-500">savings found</p>
        </div>
        <div className="w-px h-8 bg-warm-200" />
        <div className="text-center">
          <p className="text-lg font-bold text-haven-700">14</p>
          <p className="text-xs text-warm-500">systems tracked</p>
        </div>
        <div className="w-px h-8 bg-warm-200" />
        <div className="text-center">
          <p className="text-lg font-bold text-haven-700">1</p>
          <p className="text-xs text-warm-500">monthly bill</p>
        </div>
      </div>
    </div>
  );
}
```

---

## PHASE 3: Replace Homepage

Replace `apps/web/src/app/page.tsx` with the complete new homepage.

### Page Structure

```
1. HERO SECTION
   - Badge: "Meet Alfred | Your Home Manager"
   - H1 (font-serif): "Your home, finally under control."
   - Subheadline: Total value prop (bills, maintenance, savings, one payment)
   - Value props: One bill, Never miss maintenance, Handyman who knows your home
   - CTA: "Get Started with Alfred"
   - Trust: Bank-Level Security, 4.9/5 Rating, 500+ Homes

2. HOW IT WORKS (email forwarding lives here)
   - Step 1: Forward Your Emails
   - Step 2: Alfred Handles It
   - Step 3: One Bill, Done
   - Email examples grid

3. WHAT ALFRED DOES
   - 6 feature cards (Reads Emails, Finds Savings, Never Forgets, 
     Builds Home Manual, One Bill, Answers Anything)

4. HANDYMAN SECTION (dark bg)
   - "A Real Handyman Who Knows Your Home"
   - Mike Rodriguez profile card
   - Benefits list
   - Pricing: $99/visit Essentials, included for Haven

5. USE CASES
   - The Newcomer ($39) - Just bought a home
   - The Optimizer ($39) - "Most Popular" badge
   - The Busy Bee ($349) - No time to make calls

6. ONE BILL SECTION (dark bg)
   - Before/After comparison
   - 7 bills → 1 payment

7. PRICING
   - Essentials + Alfred ($39) - "Start Here" badge
   - Haven Lite ($349)
   - Haven ($749)
   - Collapsible: Haven+ ($1,499), Estate ($3,499)

8. TESTIMONIALS
   - 3 testimonials matching use cases
   - Stats: $400 savings, 500+ homes, 4.9 rating, 1 bill

9. FAQ
   - What is Alfred?
   - How does email forwarding work?
   - Is $39 enough?
   - Alfred vs Sarah?
   - Tell me about the handyman
   - How does one-bill work?
   - Contracts?

10. FINAL CTA (dark bg)
    - "Ready to take control?"
    - "Get Started with Alfred — $39/mo"

11. FOOTER
```

### Hero Section Code

```tsx
{/* HERO */}
<section className="relative overflow-hidden bg-gradient-to-br from-haven-navy-800 via-haven-navy-900 to-haven-navy-950 pt-24 sm:pt-32 pb-16 sm:pb-24">
  <div className="relative max-w-6xl mx-auto px-4 sm:px-6">
    <div className="grid lg:grid-cols-2 gap-12 items-center">
      <div className="text-center lg:text-left">
        {/* Badge */}
        <div className="inline-flex items-center gap-2 px-3 py-1.5 bg-white/10 backdrop-blur border border-white/20 rounded-full mb-6">
          <Sparkles className="w-4 h-4 text-champagne-300" />
          <span className="text-sm font-medium text-white">Meet Alfred</span>
          <span className="text-white/40">|</span>
          <span className="text-sm text-white/80">Your Home Manager</span>
        </div>

        {/* H1 - ONLY place font-serif is used */}
        <h1 className="text-4xl sm:text-5xl lg:text-6xl font-bold text-white tracking-tight leading-[1.1] font-serif">
          Your home, finally
          <br />
          <span className="text-champagne-300">under control.</span>
        </h1>

        {/* Subheadline - Total value, NOT email-focused */}
        <p className="mt-6 text-lg sm:text-xl text-haven-100 max-w-xl">
          Alfred tracks your bills, reminds you before things break, finds savings you're missing, and consolidates everything into one monthly payment. Stop managing. Start living.
        </p>

        {/* Price */}
        <div className="mt-6 inline-flex items-baseline gap-2 px-4 py-2 bg-white/10 rounded-xl border border-white/20">
          <span className="text-3xl font-bold text-white">$39</span>
          <span className="text-white/70">/month</span>
          <span className="text-champagne-300 text-sm ml-2">• Cancel anytime</span>
        </div>

        {/* Value props - Core benefits, NOT email */}
        <div className="mt-6 flex flex-wrap justify-center lg:justify-start gap-4 text-sm">
          <span className="flex items-center gap-2 text-white">
            <CheckCircle2 className="w-5 h-5 text-champagne-300" />
            One bill for everything
          </span>
          <span className="flex items-center gap-2 text-white">
            <CheckCircle2 className="w-5 h-5 text-champagne-300" />
            Never miss maintenance
          </span>
          <span className="flex items-center gap-2 text-white">
            <CheckCircle2 className="w-5 h-5 text-champagne-300" />
            Handyman who knows your home
          </span>
        </div>

        {/* CTAs */}
        <div className="mt-8 flex flex-col sm:flex-row items-center justify-center lg:justify-start gap-4">
          <Link
            href="/onboarding/welcome"
            className="w-full sm:w-auto px-8 py-4 bg-champagne-400 text-haven-navy-900 font-semibold rounded-xl hover:bg-champagne-300 transition-all text-lg flex items-center justify-center gap-2"
          >
            Get Started with Alfred
            <ArrowRight className="w-5 h-5" />
          </Link>
          <a
            href="#how-it-works"
            className="w-full sm:w-auto px-8 py-4 border-2 border-white/30 text-white font-semibold rounded-xl hover:bg-white/10 transition-colors text-lg"
          >
            See How It Works
          </a>
        </div>

        {/* Trust - NO AI language */}
        <div className="mt-8 pt-8 border-t border-white/20 flex flex-wrap items-center justify-center lg:justify-start gap-6">
          <div className="flex items-center gap-2 text-sm text-white/70">
            <Shield className="w-4 h-4" />
            <span>Bank-Level Security</span>
          </div>
          <div className="flex items-center gap-2 text-sm text-white/70">
            <Star className="w-4 h-4 text-champagne-300 fill-current" />
            <span>4.9/5 Rating</span>
          </div>
          <div className="flex items-center gap-2 text-sm text-white/70">
            <Award className="w-4 h-4" />
            <span>500+ Homes Managed</span>
          </div>
        </div>
      </div>

      {/* Right - Chat Preview */}
      <div className="relative lg:pl-8">
        <AlfredChatPreview />
      </div>
    </div>
  </div>
</section>
```

### Key Section Headers (all use Inter, NOT serif)

```tsx
{/* How It Works */}
<h2 className="text-3xl sm:text-4xl font-bold text-warm-900">
  It's Stupidly Simple
</h2>

{/* What Alfred Does */}
<h2 className="text-3xl sm:text-4xl font-bold text-warm-900">
  What Alfred Does for You
</h2>

{/* Handyman */}
<h2 className="text-3xl sm:text-4xl font-bold text-white">
  A Real Handyman Who Knows Your Home
</h2>

{/* Use Cases */}
<h2 className="text-3xl sm:text-4xl font-bold text-warm-900">
  Is Haven Right for You?
</h2>

{/* One Bill */}
<h2 className="text-3xl sm:text-4xl font-bold text-white">
  One Bill. Seriously.
</h2>

{/* Pricing */}
<h2 className="text-3xl sm:text-4xl font-bold text-warm-900">
  Simple, Transparent Pricing
</h2>

{/* Testimonials */}
<h2 className="text-3xl sm:text-4xl font-bold text-warm-900">
  Real Homeowners. Real Results.
</h2>

{/* FAQ */}
<h2 className="text-3xl sm:text-4xl font-bold text-warm-900">
  Questions? We've Got Answers.
</h2>

{/* Final CTA */}
<h2 className="text-3xl sm:text-4xl font-bold text-white">
  Ready to take control of your home?
</h2>
```

---

## PHASE 4: Verify

```bash
cd /Users/tomburke/Projects/Housing-Manager
pnpm build
pnpm dev:web
# Open http://localhost:3000
```

### Checklist

**Hero:**
- [ ] Badge: "Meet Alfred | Your Home Manager" (no AI)
- [ ] H1 uses Playfair Display (`font-serif`)
- [ ] Subheadline: total value (bills, maintenance, savings, one payment)
- [ ] Value props: One bill, Never miss maintenance, Handyman
- [ ] Trust: Bank-Level Security, 4.9/5, 500+ Homes (no "Powered by")

**How It Works:**
- [ ] Email forwarding explained here (not in hero)
- [ ] 3 steps: Forward → Alfred Handles → One Bill
- [ ] Email examples grid

**What Alfred Does:**
- [ ] 6 cards including "Builds Your Home Manual"
- [ ] No AI language

**Handyman:**
- [ ] Full dark section
- [ ] Mike Rodriguez card
- [ ] $99/visit Essentials, included Haven
- [ ] Morrison family testimonial

**Use Cases:**
- [ ] Newcomer ($39)
- [ ] Optimizer ($39) - "Most Popular"
- [ ] Busy Bee ($349)

**Pricing:**
- [ ] Essentials first with "Start Here"
- [ ] Features list includes home manual, handyman

**Typography:**
- [ ] Only hero h1 is serif
- [ ] All other h2s are sans-serif
- [ ] Body text is Inter throughout

**Design:**
- [ ] Cards: `rounded-2xl`
- [ ] Buttons: `rounded-xl`
- [ ] Section padding: `py-16 sm:py-24`
- [ ] Champagne CTAs, Navy secondary

---

## PHASE 5: Deploy

```bash
cd /Users/tomburke/Projects/Housing-Manager

git add .
git commit -m "feat: Alfred-first homepage overhaul

- Hero focuses on total value (not email forwarding)
- Email forwarding in How It Works section
- Dedicated handyman section
- Home manual as key feature
- Typography: Playfair Display hero only, Inter everywhere else
- Design consistency: rounded-2xl cards, rounded-xl buttons
- Three use cases: Newcomer, Optimizer, Busy Bee
- Pricing restructured with Essentials first
- No AI/powered-by language"

git push origin main

gcloud builds submit --config=cloudbuild-web.yaml --project=home-manager-480616
```

---

## Summary

| Section | Key Message |
|---------|-------------|
| **Hero** | "Your home, finally under control" + total value props |
| **How It Works** | "Just forward your emails" (feature, not headline) |
| **What Alfred Does** | 6 capabilities including home manual |
| **Handyman** | Real person who knows your home |
| **Use Cases** | Newcomer, Optimizer, Busy Bee |
| **Pricing** | $39 Essentials first |
| **Final CTA** | "One bill. One app. A handyman who knows your home." |

**Typography:** Playfair Display (serif) for hero h1 ONLY. Inter (sans) for everything else.

**No AI language anywhere.**
