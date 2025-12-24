# Haven Homepage Complete Redesign Specification

## Overview

This document contains the complete specification for redesigning the Haven marketing homepage. The current page is visually bland with poor section separation, incorrect text colors in some areas, and uses em dashes which should be removed. This redesign adds visual pop through color, gradients, shadows, and better contrast between sections.

**File to modify:** `apps/web/src/app/page.tsx`

---

## PART 1: GLOBAL FIXES

### 1.1 Remove All Em Dashes

Search and replace every instance of "—" (em dash) and "–" (en dash) in the file.

| Find | Replace With |
|------|--------------|
| `Get Started — $39/month` | `Get Started for $39/month` |
| `$39–$3,499` | `$39 to $3,499` |
| `— or get full service` | `. Or get full service` |
| `Haven? Text us and go back to bed—we'll handle it.` | `Haven? Text us and go back to bed. We'll handle it.` |
| `that's $400 in value for a $349 membership—before counting` | `that's $400 in value for a $349 membership, before counting` |
| Any other `—` or `–` | Context-appropriate replacement (comma, period, "to", or remove) |

### 1.2 Imports Required

Ensure these Lucide icons are imported (add any missing):
```tsx
import {
  ArrowRight,
  Check,
  X,
  ChevronDown,
  ChevronUp,
  Star,
  Shield,
  Clock,
  DollarSign,
  Home,
  Wrench,
  Users,
  FileText,
  MessageCircle,
  Phone,
  Calendar,
  Zap,
  Heart,
  Award,
  Building,
  Sparkles,
  CircleDot,
  BadgeCheck,
  CreditCard,
  Banknote,
  Receipt,
  ShoppingBag,
  Plane,
  PartyPopper,
  Crown,
  ChevronRight,
  Play,
  CheckCircle2,
  XCircle,
  Timer,
  Headphones,
  HandCoins,
  ClipboardList,
  AlertTriangle,
  Brain,
  Coffee,
} from 'lucide-react';
```

---

## PART 2: SECTION-BY-SECTION SPECIFICATIONS

### 2.1 HERO SECTION

**Current State:** Light gradient (haven-50 to white), bland appearance
**New State:** Dark dramatic gradient with amber accents

#### Container Classes
```tsx
<section className="relative overflow-hidden bg-gradient-to-br from-haven-600 via-haven-700 to-haven-800 pt-8 pb-16 sm:pt-12 sm:pb-24">
```

#### Background Decorations (add inside section, before content)
```tsx
{/* Background decoration */}
<div className="absolute inset-0 overflow-hidden pointer-events-none">
  <div className="absolute -top-40 -right-40 w-96 h-96 bg-haven-500 rounded-full blur-3xl opacity-30" />
  <div className="absolute top-1/2 -left-20 w-72 h-72 bg-amber-500 rounded-full blur-3xl opacity-20" />
  <div className="absolute bottom-0 right-1/4 w-64 h-64 bg-haven-400 rounded-full blur-3xl opacity-20" />
</div>
```

#### Trust Badge
```tsx
<div className="inline-flex items-center gap-2 px-3 py-1.5 bg-white/10 backdrop-blur border border-white/20 rounded-full mb-6">
  <span className="flex items-center gap-1">
    <Star className="w-4 h-4 text-amber-400 fill-current" />
    <span className="text-sm font-medium text-white">4.9/5</span>
  </span>
  <span className="text-white/40">|</span>
  <span className="text-sm text-white/80">500+ families served</span>
</div>
```

#### Main Headline
```tsx
<h1 className="text-4xl sm:text-5xl lg:text-6xl font-bold text-white tracking-tight leading-[1.1]">
  Stop managing your home.
  <br />
  <span className="text-amber-400">Start living in it.</span>
</h1>
```

#### Subheadline
```tsx
<p className="mt-6 text-lg sm:text-xl text-haven-100 max-w-xl">
  One payment covers everything. One text handles anything.
  From paying bills to fixing leaks, we've got it.
</p>
```

#### Value Props
```tsx
<div className="mt-6 flex flex-wrap justify-center lg:justify-start gap-4 text-sm">
  <span className="flex items-center gap-2 text-white">
    <CheckCircle2 className="w-5 h-5 text-amber-400" />
    8+ hours saved monthly
  </span>
  <span className="flex items-center gap-2 text-white">
    <CheckCircle2 className="w-5 h-5 text-amber-400" />
    No setup fees
  </span>
  <span className="flex items-center gap-2 text-white">
    <CheckCircle2 className="w-5 h-5 text-amber-400" />
    Cancel anytime
  </span>
</div>
```

#### CTA Buttons
```tsx
<div className="mt-8 flex flex-col sm:flex-row items-center justify-center lg:justify-start gap-4">
  <Link
    href="/register"
    className="w-full sm:w-auto px-8 py-4 bg-amber-500 text-warm-900 font-semibold rounded-xl hover:bg-amber-400 transition-all hover:shadow-lg hover:shadow-amber-500/25 text-lg flex items-center justify-center gap-2"
  >
    Get Started for $39/month
    <ArrowRight className="w-5 h-5" />
  </Link>
  <a
    href="#how-it-works"
    className="w-full sm:w-auto px-8 py-4 border-2 border-white/30 text-white font-semibold rounded-xl hover:bg-white/10 transition-colors text-lg flex items-center justify-center gap-2"
  >
    <Play className="w-5 h-5" />
    See How It Works
  </a>
</div>
```

#### Trust Elements Footer
```tsx
<div className="mt-8 pt-8 border-t border-white/20 flex flex-wrap items-center justify-center lg:justify-start gap-6">
  <div className="flex items-center gap-2 text-sm text-white/70">
    <Shield className="w-4 h-4" />
    <span>FDIC Insured</span>
  </div>
  <div className="flex items-center gap-2 text-sm text-white/70">
    <BadgeCheck className="w-4 h-4" />
    <span>SOC 2 Certified</span>
  </div>
  <div className="flex items-center gap-2 text-sm text-white/70">
    <Award className="w-4 h-4" />
    <span>Vetted Pros Only</span>
  </div>
</div>
```

#### Chat Interface Header (Sarah)
```tsx
<div className="bg-gradient-to-r from-haven-600 to-haven-700 px-4 py-3 flex items-center gap-3">
```

#### Chat Message Icons - Update colors
- Furnace completed: `bg-green-100` with `text-green-600`
- Bills paid: `bg-amber-100` with `text-amber-600` (changed from haven)
- Gutter scheduled: `bg-blue-100` with `text-blue-600`

---

### 2.2 PAIN POINTS SECTION

**Current State:** `bg-warm-50` background, plain white cards
**New State:** White background, colored cards with better contrast

#### Container
```tsx
<section className="py-16 sm:py-20 bg-white">
```

#### "Without Haven" Card
```tsx
<div className="bg-red-50 rounded-2xl p-6 border border-red-100">
  <div className="flex items-center gap-2 mb-4">
    <XCircle className="w-6 h-6 text-red-500" />
    <h3 className="text-lg font-semibold text-warm-900">Without Haven</h3>
  </div>
  <ul className="space-y-3">
    {[
      '12+ vendor relationships to juggle',
      'Dozens of bills arriving at random',
      'Hours spent on hold with contractors',
      'Forgotten maintenance = expensive repairs',
      "You're the unpaid project manager",
      'Constant mental overhead',
    ].map((item, idx) => (
      <li key={idx} className="flex items-start gap-3 text-warm-700">
        <X className="w-5 h-5 text-red-400 flex-shrink-0 mt-0.5" />
        <span>{item}</span>
      </li>
    ))}
  </ul>
</div>
```

#### "With Haven" Card
```tsx
<div className="bg-gradient-to-br from-haven-600 to-haven-700 rounded-2xl p-6 text-white">
  <div className="flex items-center gap-2 mb-4">
    <CheckCircle2 className="w-6 h-6 text-amber-400" />
    <h3 className="text-lg font-semibold">With Haven</h3>
  </div>
  <ul className="space-y-3">
    {[
      '1 dedicated Home Manager',
      '1 monthly bill, auto-paid',
      'Text your manager, we make the calls',
      'Proactive maintenance catches issues early',
      'Results, not more to-do lists',
      'Complete peace of mind',
    ].map((item, idx) => (
      <li key={idx} className="flex items-start gap-3 text-haven-100">
        <Check className="w-5 h-5 text-amber-400 flex-shrink-0 mt-0.5" />
        <span>{item}</span>
      </li>
    ))}
  </ul>
</div>
```

#### Highlight Stat Bar (add after the grid)
```tsx
<div className="mt-8 text-center">
  <div className="inline-flex items-center gap-3 px-6 py-3 bg-amber-100 rounded-full">
    <Clock className="w-5 h-5 text-amber-600" />
    <p className="text-lg font-semibold text-amber-800">
      8+ hours per month. That's what our members get back.
    </p>
  </div>
</div>
```

---

### 2.3 HOW IT WORKS SECTION

**Current State:** `bg-white` background
**New State:** Light warm gradient background, colored step icons

#### Container
```tsx
<section id="how-it-works" className="py-16 sm:py-24 bg-gradient-to-b from-warm-100 to-warm-50">
```

#### Steps Data with Colors
```tsx
{[
  {
    step: '1',
    title: 'Tell Us About Your Home',
    description: 'Share your vendors, bills, and preferences. We set up auto-pay and take over the relationships.',
    icon: Home,
    color: 'bg-haven-100 text-haven-600',
  },
  {
    step: '2',
    title: 'Fund Your Haven Wallet',
    description: 'One monthly payment covers everything. We pay your mortgage, utilities, and every vendor. FDIC-insured.',
    icon: CreditCard,
    color: 'bg-amber-100 text-amber-600',
  },
  {
    step: '3',
    title: 'Text Your Manager',
    description: 'Something need fixing? Question about your home? Text once. Your dedicated manager handles everything.',
    icon: MessageCircle,
    color: 'bg-blue-100 text-blue-600',
  },
].map((item, idx) => (
  // ... render logic
))}
```

#### Step Icon Container
```tsx
<div className="relative inline-flex mb-4">
  <div className={`w-24 h-24 rounded-2xl ${item.color} flex items-center justify-center shadow-lg`}>
    <item.icon className="w-10 h-10" />
  </div>
  <span className="absolute -top-2 -right-2 w-8 h-8 bg-haven-600 text-white rounded-full flex items-center justify-center font-bold text-sm shadow-md">
    {item.step}
  </span>
</div>
```

#### Connector Line
```tsx
{idx < 2 && (
  <div className="hidden md:block absolute top-12 left-[60%] w-[80%] h-0.5 bg-gradient-to-r from-warm-300 to-transparent" />
)}
```

---

### 2.4 SERVICES SECTION

**Current State:** `bg-warm-50` background, plain cards
**New State:** White background, cards with colored top accent bars and hover effects

#### Container
```tsx
<section className="py-16 sm:py-24 bg-white">
```

#### Services Data with Colors
```tsx
{[
  {
    title: 'Bill Management',
    icon: Receipt,
    accentColor: 'bg-green-500',
    iconBg: 'bg-green-100 text-green-600',
    items: [
      'Mortgage & property taxes',
      'All utilities (electric, gas, water)',
      'Insurance & HOA dues',
      'Every vendor invoice, on time',
    ],
  },
  {
    title: 'Home Maintenance',
    icon: Wrench,
    accentColor: 'bg-blue-500',
    iconBg: 'bg-blue-100 text-blue-600',
    items: [
      'Monthly handyman visits',
      'HVAC service & filter changes',
      'Plumbing & electrical coordination',
      'Seasonal prep & winterization',
    ],
  },
  {
    title: 'Vendor Coordination',
    icon: Users,
    accentColor: 'bg-purple-500',
    iconBg: 'bg-purple-100 text-purple-600',
    items: [
      'Find & vet qualified pros',
      'Schedule & oversee all work',
      'Handle disputes & issues',
      'Negotiate on your behalf',
    ],
  },
  {
    title: 'Life Management',
    icon: Sparkles,
    accentColor: 'bg-amber-500',
    iconBg: 'bg-amber-100 text-amber-600',
    badge: 'Haven+',
    items: [
      'Errand running & pickups',
      'Package handling & returns',
      'Travel coordination',
      'Event planning',
    ],
  },
].map((service, idx) => (
  // ... render logic
))}
```

#### Service Card Structure
```tsx
<div key={idx} className="bg-white rounded-2xl border border-warm-200 overflow-hidden hover:shadow-xl transition-all hover:-translate-y-1">
  {/* Colored top accent bar */}
  <div className={`h-2 ${service.accentColor}`} />
  <div className="p-6">
    <div className={`w-12 h-12 rounded-xl ${service.iconBg} flex items-center justify-center mb-4`}>
      <service.icon className="w-6 h-6" />
    </div>
    <div className="flex items-center gap-2 mb-3">
      <h3 className="text-lg font-semibold text-warm-900">{service.title}</h3>
      {service.badge && (
        <span className="px-2 py-0.5 bg-amber-100 text-amber-700 text-xs font-medium rounded-full">
          {service.badge}
        </span>
      )}
    </div>
    <ul className="space-y-2">
      {service.items.map((item, i) => (
        <li key={i} className="flex items-start gap-2 text-sm text-warm-600">
          <Check className="w-4 h-4 text-haven-500 flex-shrink-0 mt-0.5" />
          <span>{item}</span>
        </li>
      ))}
    </ul>
  </div>
</div>
```

---

### 2.5 HANDYMAN SECTION (CRITICAL FIX)

**Current State:** `bg-haven-600` with BLACK heading text (broken)
**New State:** Dark charcoal gradient with WHITE heading text and amber accents

#### Container
```tsx
<section className="py-16 sm:py-24 bg-gradient-to-br from-warm-900 via-warm-800 to-warm-900 text-white relative overflow-hidden">
```

#### Background Decorations
```tsx
{/* Background decoration */}
<div className="absolute inset-0 overflow-hidden pointer-events-none">
  <div className="absolute top-0 right-0 w-96 h-96 bg-amber-500 rounded-full blur-3xl opacity-10" />
  <div className="absolute bottom-0 left-0 w-72 h-72 bg-haven-500 rounded-full blur-3xl opacity-10" />
</div>
```

#### Content Container
```tsx
<div className="relative max-w-6xl mx-auto px-4 sm:px-6">
```

#### Left Column Content
```tsx
<div>
  <p className="text-amber-400 font-semibold mb-2">The Haven Difference</p>
  <h2 className="text-3xl sm:text-4xl font-bold text-white mb-4">
    Your Own Dedicated Handyman
  </h2>
  <p className="text-warm-300 text-lg mb-6">
    Unlike software that just tracks maintenance, Haven includes a dedicated handyman who physically visits your home monthly. They catch small issues before they become expensive emergencies.
  </p>
  <div className="grid sm:grid-cols-2 gap-4">
    {[
      'Monthly preventive visits',
      'Same person every time',
      'Filter changes included',
      'Minor repairs on the spot',
    ].map((item, idx) => (
      <div key={idx} className="flex items-center gap-2">
        <CheckCircle2 className="w-5 h-5 text-amber-400" />
        <span className="text-warm-200">{item}</span>
      </div>
    ))}
  </div>
</div>
```

#### Right Column - Handyman Card
```tsx
<div className="bg-white rounded-2xl p-6 text-warm-900 shadow-2xl">
  <div className="flex items-center gap-4 mb-4">
    <div className="w-16 h-16 rounded-full bg-gradient-to-br from-amber-400 to-amber-500 flex items-center justify-center text-white font-bold text-xl shadow-lg">
      MR
    </div>
    <div>
      <p className="font-bold text-lg">Mike Rodriguez</p>
      <p className="text-warm-500">Your Dedicated Handyman</p>
    </div>
  </div>
  <div className="space-y-3 pt-4 border-t border-warm-200">
    <div className="flex justify-between">
      <span className="text-warm-500">Next visit</span>
      <span className="font-medium">Tuesday, 10am</span>
    </div>
    <div className="flex justify-between">
      <span className="text-warm-500">Issues caught this year</span>
      <span className="font-medium text-green-600">12 (saved $3,400+)</span>
    </div>
    <div className="flex justify-between">
      <span className="text-warm-500">Your home</span>
      <span className="font-medium">Knows it inside & out</span>
    </div>
  </div>
</div>
```

---

### 2.6 PRICING SECTION

**Current State:** `bg-white` background
**New State:** Light green gradient, cards with colored top accents

#### Container
```tsx
<section id="pricing" className="py-16 sm:py-24 bg-gradient-to-b from-haven-50 to-white">
```

#### Essentials Card ($39)
```tsx
<div className="bg-white rounded-2xl border border-warm-200 overflow-hidden flex flex-col hover:border-haven-300 hover:shadow-lg transition-all">
  <div className="h-2 bg-warm-300" />
  <div className="p-6 flex-1">
    {/* ... content ... */}
  </div>
</div>
```

#### Lite Card ($349) - Most Popular
```tsx
<div className="relative pt-4">
  {/* Most Popular Badge */}
  <div className="absolute -top-0 left-1/2 -translate-x-1/2 z-10">
    <span className="px-4 py-1.5 bg-gradient-to-r from-haven-600 to-haven-700 text-white text-sm font-semibold rounded-full shadow-lg">
      Most Popular
    </span>
  </div>
  <div className="bg-white rounded-2xl border-2 border-haven-500 overflow-hidden flex flex-col shadow-xl shadow-haven-100">
    <div className="h-2 bg-gradient-to-r from-haven-500 to-haven-600" />
    <div className="p-6 pt-4 flex-1">
      <h3 className="text-lg font-semibold text-haven-700">Haven Lite</h3>
      {/* ... rest of content ... */}
    </div>
  </div>
</div>
```

#### Haven Card ($749)
```tsx
<div className="bg-white rounded-2xl border border-warm-200 overflow-hidden flex flex-col hover:border-haven-300 hover:shadow-lg transition-all">
  <div className="h-2 bg-amber-400" />
  <div className="p-6 flex-1">
    {/* ... content ... */}
  </div>
</div>
```

#### Premium Tiers Button
```tsx
<button
  onClick={() => setShowPremiumTiers(!showPremiumTiers)}
  className="w-full py-4 px-6 bg-white rounded-xl border border-warm-200 flex items-center justify-between hover:bg-warm-50 hover:border-warm-300 transition-colors shadow-sm"
>
```

#### Haven+ Card (in expanded section)
```tsx
<div className="bg-white rounded-xl border border-purple-200 p-6 shadow-lg">
```

#### Haven Estate Card (in expanded section)
```tsx
<div className="bg-gradient-to-br from-warm-900 to-warm-800 rounded-xl p-6 text-white shadow-lg">
```

#### "How Your Bill Works" Box
```tsx
<div className="mt-12 max-w-3xl mx-auto">
  <div className="bg-white rounded-2xl p-6 sm:p-8 border border-warm-200 shadow-lg">
    <h3 className="text-lg font-semibold text-warm-900 text-center mb-6">How Your Bill Works</h3>
    {/* ... content ... */}
    
    {/* Example box - amber highlight */}
    <div className="mt-6 p-4 bg-amber-50 rounded-xl border border-amber-200">
      <p className="text-center text-sm text-amber-800">
        <strong>Example:</strong> $3,200 in monthly bills + $39 Essentials = <strong>$3,239 total</strong>.
        One payment to Haven. We pay everyone else.
      </p>
    </div>
  </div>
</div>
```

#### Price Range Text Fix
Change from `$39–$3,499` to `$39 to $3,499`

---

### 2.7 COMPARE PLANS TABLE

**Current State:** `bg-warm-50` with white table
**New State:** Dark theme (warm-900) for strong visual contrast

#### Container
```tsx
<section className="py-16 sm:py-24 bg-warm-900 text-white">
```

#### Desktop Table
```tsx
<div className="hidden lg:block bg-warm-800 rounded-2xl overflow-hidden">
  <table className="w-full">
    <thead>
      <tr className="border-b border-warm-700">
        <th className="text-left py-4 px-6 font-semibold text-warm-400 w-1/4">Feature</th>
        <th className="text-center py-4 px-4">
          <div className="font-semibold text-warm-200">Essentials</div>
          <div className="text-haven-400 font-bold">$39/mo</div>
        </th>
        <th className="text-center py-4 px-4 bg-haven-600/20">
          <div className="font-semibold text-amber-400">Lite</div>
          <div className="text-haven-400 font-bold">$349/mo</div>
        </th>
        <th className="text-center py-4 px-4">
          <div className="font-semibold text-warm-200">Haven</div>
          <div className="text-haven-400 font-bold">$749/mo</div>
        </th>
      </tr>
    </thead>
    <tbody className="divide-y divide-warm-700">
      {/* ... rows ... */}
    </tbody>
  </table>
</div>
```

#### Table Row Styling
```tsx
<tr key={idx}>
  <td className="py-4 px-6 text-warm-300 font-medium">{row.feature}</td>
  <td className="py-4 px-4 text-center">
    {row.essentials === true ? (
      <Check className="w-5 h-5 text-green-400 mx-auto" />
    ) : row.essentials === false ? (
      <X className="w-5 h-5 text-warm-600 mx-auto" />
    ) : (
      <span className="text-sm text-warm-400">{row.essentials}</span>
    )}
  </td>
  <td className="py-4 px-4 text-center bg-haven-600/20">
    {row.lite === true ? (
      <Check className="w-5 h-5 text-amber-400 mx-auto" />
    ) : row.lite === false ? (
      <X className="w-5 h-5 text-warm-600 mx-auto" />
    ) : (
      <span className="text-sm font-medium text-amber-400">{row.lite}</span>
    )}
  </td>
  <td className="py-4 px-4 text-center">
    {row.haven === true ? (
      <Check className="w-5 h-5 text-green-400 mx-auto" />
    ) : row.haven === false ? (
      <X className="w-5 h-5 text-warm-600 mx-auto" />
    ) : (
      <span className="text-sm text-warm-400">{row.haven}</span>
    )}
  </td>
</tr>
```

#### Mobile Cards (also dark theme)
```tsx
<div className="lg:hidden space-y-3">
  {/* Update mobile card data - remove em dashes */}
  {[
    { feature: 'Bill Consolidation', essentials: 'Unlimited', lite: 'Unlimited', haven: 'Unlimited' },
    { feature: 'Home Manager', essentials: 'None', lite: 'Text-based', haven: 'Proactive', highlight: true },
    { feature: 'Response Time', essentials: 'Self-service', lite: 'Same-day', haven: '12 hours' },
    { feature: 'Handyman Visits', essentials: '$99/visit', lite: 'Add-on', haven: '2 hrs included', highlight: true },
    { feature: 'Vendor Coordination', essentials: 'None', lite: 'Reactive', haven: 'Full oversight' },
  ].map((row, idx) => (
    <div key={idx} className={`bg-warm-800 rounded-xl border overflow-hidden ${row.highlight ? 'border-haven-500' : 'border-warm-700'}`}>
      <div className="bg-warm-700 px-4 py-2">
        <span className="font-medium text-warm-200 text-sm">{row.feature}</span>
      </div>
      <div className="grid grid-cols-3 divide-x divide-warm-700">
        <div className="p-3 text-center">
          <div className="text-xs text-warm-500 mb-1">$39</div>
          <div className="text-sm text-warm-300">{row.essentials}</div>
        </div>
        <div className="p-3 text-center bg-haven-600/20">
          <div className="text-xs text-amber-400 mb-1">$349</div>
          <div className="text-sm font-medium text-amber-400">{row.lite}</div>
        </div>
        <div className="p-3 text-center">
          <div className="text-xs text-warm-500 mb-1">$749</div>
          <div className="text-sm text-warm-300">{row.haven}</div>
        </div>
      </div>
    </div>
  ))}
</div>
```

#### CTA Button
```tsx
<div className="mt-8 text-center">
  <Link
    href="/register"
    className="inline-flex items-center gap-2 px-8 py-3 bg-amber-500 text-warm-900 font-semibold rounded-xl hover:bg-amber-400 transition-colors"
  >
    Start for $39/month
    <ArrowRight className="w-5 h-5" />
  </Link>
</div>
```

---

### 2.8 SOFTWARE VS SERVICE SECTION

**Current State:** Neutral colors
**New State:** Better contrast with red for competitor, green for Haven

#### Container
```tsx
<section className="py-16 sm:py-24 bg-white">
```

#### Table Header Row
```tsx
<div className="bg-warm-50 rounded-2xl overflow-hidden border border-warm-200">
  <div className="grid sm:grid-cols-3">
    <div className="p-4 sm:p-6 font-semibold text-warm-600 border-b sm:border-b-0 sm:border-r border-warm-200 bg-warm-100">
      FEATURE
    </div>
    <div className="p-4 sm:p-6 text-center border-b sm:border-b-0 sm:border-r border-warm-200 bg-red-50">
      <p className="font-semibold text-red-700">Household Software</p>
      <p className="text-sm text-red-600">$375/mo + $3K setup</p>
    </div>
    <div className="p-4 sm:p-6 text-center bg-haven-100">
      <p className="font-semibold text-haven-700">Haven</p>
      <p className="text-sm text-haven-600">$349/mo, no setup fee</p>
    </div>
  </div>
```

#### Table Rows - Fix em dashes in data
```tsx
{[
  { feature: 'Monthly Cost', software: '$375/month', haven: '$349/month' },
  { feature: 'Setup/Onboarding', software: '$3,000 to $5,000', haven: '$0' },
  { feature: 'First Year Total', software: '$7,500+', haven: '$4,188' },
  { feature: 'Contract Required', software: '12-month prepaid', haven: 'Month-to-month' },
  { feature: 'Bills Paid For You', software: 'No (you pay each vendor)', haven: 'Yes, one payment covers all' },
  { feature: 'Vendor Coordination', software: 'No (just a contact list)', haven: 'Yes, we call, schedule, oversee' },
  { feature: 'Handyman Visits', software: 'No', haven: 'Yes, monthly preventive visits' },
  { feature: 'Humans Doing Work', software: 'No (software only)', haven: 'Yes, dedicated manager' },
  { feature: 'When Something Breaks', software: 'You figure it out', haven: 'Text us. We fix it.' },
].map((row, idx) => (
  // ... render
))}
```

#### Table Row Styling
```tsx
<div key={idx} className="grid sm:grid-cols-3 border-t border-warm-200">
  <div className="p-4 sm:p-5 text-warm-700 font-medium border-b sm:border-b-0 sm:border-r border-warm-200">
    {row.feature}
  </div>
  <div className="p-4 sm:p-5 text-center border-b sm:border-b-0 sm:border-r border-warm-200 flex items-center justify-center gap-2 bg-red-50/50">
    <XCircle className="w-4 h-4 text-red-400 hidden sm:block" />
    <span className="text-sm text-red-700">{row.software}</span>
  </div>
  <div className="p-4 sm:p-5 text-center bg-haven-50 flex items-center justify-center gap-2">
    <CheckCircle2 className="w-4 h-4 text-haven-600 hidden sm:block" />
    <span className="text-sm font-medium text-haven-700">{row.haven}</span>
  </div>
</div>
```

#### Bottom CTA Box
```tsx
<div className="mt-8 bg-gradient-to-r from-haven-600 to-haven-700 rounded-2xl p-6 sm:p-8 text-center text-white">
  <p className="text-lg sm:text-xl font-semibold mb-4">
    Why pay more for software that makes YOU do the work?
  </p>
  <p className="text-haven-200 mb-6">
    Start with Haven Essentials for just $39/month or get full service at $349/month with no setup fee.
  </p>
  <Link
    href="/register"
    className="inline-flex items-center gap-2 px-8 py-3 bg-amber-500 text-warm-900 font-semibold rounded-xl hover:bg-amber-400 transition-colors"
  >
    Start for $39/month
    <ArrowRight className="w-5 h-5" />
  </Link>
</div>
```

---

### 2.9 TESTIMONIALS SECTION

**Current State:** `bg-warm-50` plain background
**New State:** Warm amber gradient background

#### Container
```tsx
<section className="py-16 sm:py-24 bg-gradient-to-b from-amber-50 to-amber-100/50">
```

#### Testimonial Cards
```tsx
<div key={idx} className="bg-white rounded-2xl p-6 border border-warm-200 flex flex-col shadow-lg">
```

#### Avatar styling
```tsx
<div className="w-10 h-10 rounded-full bg-haven-600 flex items-center justify-center text-white font-semibold text-sm">
  {testimonial.avatar}
</div>
```

#### Highlight Badges with varied colors
```tsx
{[
  {
    quote: "...",
    name: 'Marcus T.',
    title: 'Software Developer, 3BR Colonial',
    highlight: 'Worth every penny',
    color: 'bg-haven-100 text-haven-700',
    avatar: 'MT',
  },
  {
    quote: "...",
    name: 'Jennifer L.',
    title: 'Working Mom, Townhouse',
    highlight: 'Saved $400',
    color: 'bg-green-100 text-green-700',
    avatar: 'JL',
  },
  {
    quote: "...",
    name: 'David S.',
    title: 'Small Business Owner, 4BR Home',
    highlight: 'Prevented major repair',
    color: 'bg-amber-100 text-amber-700',
    avatar: 'DS',
  },
]}
```

#### Stats Row with colored values
```tsx
<div className="mt-12 grid grid-cols-2 sm:grid-cols-4 gap-6">
  {[
    { value: '8+', label: 'Hours saved monthly', color: 'text-haven-600' },
    { value: '500+', label: 'Families served', color: 'text-amber-600' },
    { value: '4.9', label: 'Average rating', color: 'text-haven-600' },
    { value: '$0', label: 'Hidden fees', color: 'text-green-600' },
  ].map((stat, idx) => (
    <div key={idx} className="text-center bg-white rounded-xl p-4 shadow-md border border-warm-200">
      <p className={`text-3xl sm:text-4xl font-bold ${stat.color}`}>{stat.value}</p>
      <p className="text-warm-500">{stat.label}</p>
    </div>
  ))}
</div>
```

---

### 2.10 FAQ SECTION

**Current State:** Basic styling
**New State:** Better visual feedback on open/close

#### Container
```tsx
<section className="py-16 sm:py-24 bg-white">
```

#### FAQ Item - Open Chevron Color
```tsx
{openFaq === idx ? (
  <ChevronUp className="w-5 h-5 text-haven-600 flex-shrink-0" />
) : (
  <ChevronDown className="w-5 h-5 text-warm-400 flex-shrink-0" />
)}
```

#### Expanded Answer Background
```tsx
{openFaq === idx && (
  <div className="px-6 pb-4 text-warm-600 bg-warm-50">
    {faq.a}
  </div>
)}
```

#### FAQ Data - Fix em dashes
```tsx
{[
  {
    q: 'Is this only for rich people with big estates?',
    a: "Not at all. We built Haven because professional home management shouldn't require a trust fund. Our Essentials plan starts at just $39/month and works perfectly for condos and apartments. The value comes from saving you time and preventing expensive repairs. That's valuable for any homeowner.",
  },
  {
    q: 'How is Haven different from household management software?',
    a: "Software gives you tools to organize your own work. Haven gives you a person who does the work. When your furnace breaks at 10pm, software gives you a contact list. Haven? Text us and go back to bed. We'll handle it.",
  },
  {
    q: 'Why should I pay for this when I can manage things myself?',
    a: "You absolutely can. The question is: should you? Our members save 8+ hours monthly. If your time is worth $50/hour, that's $400 in value for a $349 membership, before counting the money we save on vendor negotiations and catching issues early.",
  },
  {
    q: 'Do I have to sign an annual contract?',
    a: "Never. All Haven memberships are month-to-month. No setup fees, no cancellation penalties. We earn your business every month.",
  },
  {
    q: 'How does the one-bill system work?',
    a: "You fund your Haven Wallet once monthly. We pay every bill on your behalf: mortgage, utilities, landscaper, pool guy, everyone. You see it all in your dashboard, but you never have to think about due dates or writing checks again.",
  },
  {
    q: 'Is my money safe?',
    a: "Yes. Your Haven Wallet is FDIC-insured up to $2 million through our banking partner. We're also SOC 2 certified, meaning your data and transactions meet the highest security standards.",
  },
]}
```

---

### 2.11 FINAL CTA SECTION

**Current State:** `bg-haven-600` simple
**New State:** Dark gradient with decorative elements and amber accents

#### Container
```tsx
<section className="py-16 sm:py-24 bg-gradient-to-br from-haven-600 via-haven-700 to-haven-800 relative overflow-hidden">
```

#### Background Decorations
```tsx
{/* Background decoration */}
<div className="absolute inset-0 overflow-hidden pointer-events-none">
  <div className="absolute top-0 right-0 w-96 h-96 bg-amber-500 rounded-full blur-3xl opacity-20" />
  <div className="absolute bottom-0 left-0 w-72 h-72 bg-haven-400 rounded-full blur-3xl opacity-20" />
</div>
```

#### Content
```tsx
<div className="relative max-w-4xl mx-auto px-4 sm:px-6 text-center">
  <h2 className="text-3xl sm:text-4xl font-bold text-white">
    Ready to simplify your home life?
  </h2>
  <p className="mt-4 text-lg text-haven-100">
    Start with bill consolidation for just $39/month. Upgrade anytime.
  </p>
  <p className="mt-2 text-haven-200">
    Join hundreds of families who've reclaimed their time and peace of mind.
  </p>
  <p className="mt-4 text-amber-400 font-medium">
    Not another app. Actual help when you need it.
  </p>
  <div className="mt-8 flex flex-col sm:flex-row items-center justify-center gap-4">
    <Link
      href="/register"
      className="w-full sm:w-auto px-8 py-4 bg-amber-500 text-warm-900 font-semibold rounded-xl hover:bg-amber-400 transition-colors text-lg flex items-center justify-center gap-2"
    >
      Start for $39/month
      <ArrowRight className="w-5 h-5" />
    </Link>
    <a
      href="#pricing"
      className="w-full sm:w-auto px-8 py-4 border-2 border-white/30 text-white font-semibold rounded-xl hover:bg-white/10 transition-colors text-lg"
    >
      Compare All Plans
    </a>
  </div>
  <p className="mt-6 text-sm text-haven-200">
    No contracts. No setup fees. Cancel anytime. 30-day money-back guarantee.
  </p>
</div>
```

---

### 2.12 FOOTER

**Current State:** Already `bg-warm-900`
**New State:** Keep as is, no changes needed

---

## PART 3: VISUAL DESIGN SUMMARY

### Color Palette Usage

| Purpose | Colors |
|---------|--------|
| Primary brand | haven-600, haven-700 |
| Secondary accent | amber-400, amber-500 |
| Dark backgrounds | warm-800, warm-900 |
| Light backgrounds | white, warm-50, warm-100, haven-50, amber-50 |
| Success/positive | green-400, green-500, green-600 |
| Error/negative | red-400, red-500, red-50 |
| Neutral | warm-200 to warm-700 |

### Section Background Alternation

1. Hero: Dark green gradient
2. Pain Points: White
3. How It Works: Light warm gradient
4. Services: White
5. Handyman: Dark charcoal
6. Pricing: Light green gradient
7. Compare Plans: Dark (warm-900)
8. Software vs Service: White
9. Testimonials: Amber gradient
10. FAQ: White
11. Final CTA: Dark green gradient
12. Footer: Dark charcoal

### Button Hierarchy

**Primary CTA (amber):**
```
bg-amber-500 text-warm-900 hover:bg-amber-400 transition-colors
```

**Secondary CTA (dark bg):**
```
border-2 border-white/30 text-white hover:bg-white/10 transition-colors
```

**Tertiary CTA (light bg):**
```
bg-warm-100 text-warm-700 hover:bg-warm-200 transition-colors
```

**Haven brand CTA:**
```
bg-haven-600 text-white hover:bg-haven-700 transition-colors
```

---

## PART 4: VERIFICATION CHECKLIST

After implementing all changes, verify:

- [ ] No em dashes (—) or en dashes (–) anywhere in the file
- [ ] Hero section has dark gradient background
- [ ] Hero CTA buttons are amber
- [ ] Pain points cards have red/green color coding
- [ ] How It Works icons have colored backgrounds with shadows
- [ ] Service cards have colored top accent bars
- [ ] Service cards have hover lift effect
- [ ] Handyman section has DARK background with WHITE heading
- [ ] Handyman section has amber accents
- [ ] Pricing cards have colored top accent bars
- [ ] Most Popular badge has gradient
- [ ] Compare Plans table has dark (warm-900) background
- [ ] Compare Plans Lite column has amber highlighting
- [ ] Software vs Service has red tint for competitor column
- [ ] Testimonials section has amber gradient background
- [ ] Stats have white card backgrounds with shadows
- [ ] FAQ expanded answers have warm-50 background
- [ ] Final CTA has dark gradient with decorative blur circles
- [ ] All hover effects work smoothly
- [ ] Page is responsive on mobile

---

## PART 5: DEPLOYMENT

After all changes are complete:

1. Run `pnpm build` to verify no TypeScript errors
2. Run `pnpm dev` locally to test all sections
3. Commit changes with message: "Redesign homepage with visual improvements and em dash removal"
4. Push to main branch for production deployment
