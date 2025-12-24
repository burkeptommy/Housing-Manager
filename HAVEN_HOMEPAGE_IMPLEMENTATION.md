# Haven Homepage Implementation - Champagne Accent

## Color Palette Update

Replace all amber/gold references with a sophisticated champagne palette:

```
Champagne Palette:
- champagne-50:  #FAF8F5  (very light, backgrounds)
- champagne-100: #F5F0E8  (light tint)
- champagne-200: #E8E0D0  (subtle backgrounds)
- champagne-300: #D4C5A9  (PRIMARY - the main accent)
- champagne-400: #C4B393  (slightly darker)
- champagne-500: #A89968  (darker, for text)
- champagne-600: #8C7D4E  (dark, high contrast text)
```

The primary champagne color is `#D4C5A9` - use this for accents on dark backgrounds.

---

## TASK 1: Update Tailwind Config

Add the champagne color to `apps/web/tailwind.config.ts` (or `tailwind.config.js`):

Find the `colors` section in the theme extend and add:

```js
champagne: {
  50: '#FAF8F5',
  100: '#F5F0E8',
  200: '#E8E0D0',
  300: '#D4C5A9',
  400: '#C4B393',
  500: '#A89968',
  600: '#8C7D4E',
},
```

---

## TASK 2: Create Navigation Bar Component

Create `apps/web/src/components/marketing/Navbar.tsx`:

```tsx
'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { Menu, X } from 'lucide-react';

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

  const navLinks = [
    { href: '#how-it-works', label: 'How It Works' },
    { href: '#services', label: 'Services' },
    { href: '#pricing', label: 'Pricing' },
    { href: '#faq', label: 'FAQ' },
  ];

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
          <Link href="/" className="flex items-center">
            <span className={`text-2xl font-bold transition-colors ${
              isScrolled ? 'text-haven-600' : 'text-white'
            }`}>
              Haven
            </span>
          </Link>

          {/* Desktop Navigation */}
          <div className="hidden lg:flex items-center gap-8">
            {navLinks.map((link) => (
              <a
                key={link.href}
                href={link.href}
                className={`text-sm font-medium transition-colors ${
                  isScrolled 
                    ? 'text-warm-600 hover:text-haven-600' 
                    : 'text-white/90 hover:text-white'
                }`}
              >
                {link.label}
              </a>
            ))}
          </div>

          {/* Desktop CTA */}
          <div className="hidden lg:flex items-center gap-4">
            <Link
              href="/login"
              className={`text-sm font-medium transition-colors ${
                isScrolled ? 'text-warm-600 hover:text-haven-600' : 'text-white/90 hover:text-white'
              }`}
            >
              Sign In
            </Link>
            <Link
              href="/register"
              className={`px-5 py-2.5 text-sm font-semibold rounded-xl transition-all ${
                isScrolled
                  ? 'bg-haven-600 text-white hover:bg-haven-700 shadow-sm hover:shadow-md'
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
            aria-label="Toggle menu"
          >
            {isMobileMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
          </button>
        </div>

        {/* Mobile Menu */}
        {isMobileMenuOpen && (
          <div className="lg:hidden bg-white border-t border-warm-100 py-4 shadow-lg">
            <div className="flex flex-col gap-1">
              {navLinks.map((link) => (
                <a
                  key={link.href}
                  href={link.href}
                  className="px-4 py-3 text-warm-700 font-medium rounded-lg hover:bg-warm-50 transition-colors"
                  onClick={() => setIsMobileMenuOpen(false)}
                >
                  {link.label}
                </a>
              ))}
              <div className="border-t border-warm-100 mt-2 pt-2 px-2">
                <Link
                  href="/login"
                  className="block px-4 py-3 text-warm-700 font-medium rounded-lg hover:bg-warm-50 transition-colors"
                  onClick={() => setIsMobileMenuOpen(false)}
                >
                  Sign In
                </Link>
                <Link
                  href="/register"
                  className="block mt-2 px-4 py-3 bg-haven-600 text-white font-semibold rounded-xl text-center hover:bg-haven-700 transition-colors"
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

---

## TASK 3: Update page.tsx

Modify `apps/web/src/app/page.tsx` with all the following changes:

### 3.1 Add Navbar Import

At the top of the file with other imports:

```tsx
import { Navbar } from '@/components/marketing/Navbar';
```

Also ensure `Clock` is imported from lucide-react (for the stat highlight bar).

### 3.2 Add Navbar to Page

Inside the return statement, add Navbar as first child:

```tsx
return (
  <div className="min-h-screen bg-white">
    <Navbar />
    
    {/* Hero section - note padding for fixed nav */}
    <section className="...">
```

### 3.3 Remove ALL Em Dashes

Search and replace every instance:

| Find | Replace With |
|------|--------------|
| `—` (em dash) | See context below |
| `–` (en dash) | See context below |

Specific replacements:
- `Get Started — $39/month` → `Get Started for $39/month`
- `$39–$3,499` → `$39 to $3,499`
- `From paying bills to fixing leaks—we've got it.` → `From paying bills to fixing leaks, we've got it.`
- `Haven? Text us and go back to bed—we'll handle it.` → `Haven? Text us and go back to bed. We'll handle it.`
- `$349 membership—before counting` → `$349 membership, before counting`
- `— or get full service` → `. Or get full service`
- In mobile table: Replace any `—` with `None` or appropriate text

### 3.4 Update Hero Section

```tsx
<section className="relative overflow-hidden bg-gradient-to-br from-haven-600 via-haven-700 to-haven-800 pt-24 sm:pt-32 pb-16 sm:pb-24">
  {/* Background decoration */}
  <div className="absolute inset-0 overflow-hidden pointer-events-none">
    <div className="absolute -top-40 -right-40 w-96 h-96 bg-haven-500 rounded-full blur-3xl opacity-30" />
    <div className="absolute top-1/2 -left-20 w-72 h-72 bg-champagne-300/30 rounded-full blur-3xl opacity-40" />
    <div className="absolute bottom-0 right-1/4 w-64 h-64 bg-haven-400 rounded-full blur-3xl opacity-20" />
  </div>

  <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
```

Update hero elements:

**Trust Badge:**
```tsx
<div className="inline-flex items-center gap-2 px-3 py-1.5 bg-white/10 backdrop-blur border border-white/20 rounded-full mb-6">
  <span className="flex items-center gap-1">
    <Star className="w-4 h-4 text-champagne-300 fill-current" />
    <span className="text-sm font-medium text-white">4.9/5</span>
  </span>
  <span className="text-white/40">|</span>
  <span className="text-sm text-white/80">500+ families served</span>
</div>
```

**Headline:**
```tsx
<h1 className="text-4xl sm:text-5xl lg:text-6xl font-bold text-white tracking-tight leading-[1.1]">
  Stop managing your home.
  <br />
  <span className="text-champagne-300">Start living in it.</span>
</h1>
```

**Subheadline:**
```tsx
<p className="mt-6 text-lg sm:text-xl text-haven-100 max-w-xl">
  One payment covers everything. One text handles anything.
  From paying bills to fixing leaks, we've got it.
</p>
```

**Value Props:**
```tsx
<div className="mt-6 flex flex-wrap justify-center lg:justify-start gap-4 text-sm">
  <span className="flex items-center gap-2 text-white">
    <CheckCircle2 className="w-5 h-5 text-champagne-300" />
    8+ hours saved monthly
  </span>
  <span className="flex items-center gap-2 text-white">
    <CheckCircle2 className="w-5 h-5 text-champagne-300" />
    No setup fees
  </span>
  <span className="flex items-center gap-2 text-white">
    <CheckCircle2 className="w-5 h-5 text-champagne-300" />
    Cancel anytime
  </span>
</div>
```

**CTA Buttons:**
```tsx
<div className="mt-8 flex flex-col sm:flex-row items-center justify-center lg:justify-start gap-4">
  <Link
    href="/register"
    className="w-full sm:w-auto px-8 py-4 bg-white text-haven-700 font-semibold rounded-xl hover:bg-champagne-50 transition-all hover:shadow-lg text-lg flex items-center justify-center gap-2"
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

**Trust Elements:**
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

**Chat Interface - Bills Paid Icon (use champagne instead of amber):**
```tsx
<div className="w-8 h-8 rounded-full bg-champagne-100 flex items-center justify-center flex-shrink-0">
  <DollarSign className="w-4 h-4 text-champagne-600" />
</div>
```

### 3.5 Update Pain Points Section

Container:
```tsx
<section className="py-16 sm:py-20 bg-white">
```

**"Without Haven" Card:**
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

**"With Haven" Card:**
```tsx
<div className="bg-gradient-to-br from-haven-600 to-haven-700 rounded-2xl p-6 text-white">
  <div className="flex items-center gap-2 mb-4">
    <CheckCircle2 className="w-6 h-6 text-champagne-300" />
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
        <Check className="w-5 h-5 text-champagne-300 flex-shrink-0 mt-0.5" />
        <span>{item}</span>
      </li>
    ))}
  </ul>
</div>
```

**Stat Highlight Bar (after the grid):**
```tsx
<div className="mt-8 text-center">
  <div className="inline-flex items-center gap-3 px-6 py-3 bg-champagne-100 rounded-full">
    <Clock className="w-5 h-5 text-champagne-600" />
    <p className="text-lg font-semibold text-champagne-600">
      8+ hours per month. That's what our members get back.
    </p>
  </div>
</div>
```

### 3.6 Update How It Works Section

```tsx
<section id="how-it-works" className="py-16 sm:py-24 bg-gradient-to-b from-warm-100 to-warm-50">
```

Icon containers with shadows:
```tsx
<div className={`w-24 h-24 rounded-2xl ${item.color} flex items-center justify-center shadow-lg`}>
  <item.icon className="w-10 h-10" />
</div>
```

Step colors:
- Step 1 (Home): `bg-haven-100 text-haven-600`
- Step 2 (CreditCard): `bg-champagne-200 text-champagne-600`
- Step 3 (MessageCircle): `bg-blue-100 text-blue-600`

### 3.7 Update Services Section

```tsx
<section id="services" className="py-16 sm:py-24 bg-white">
```

Card structure with accent bar and hover:
```tsx
<div className="bg-white rounded-2xl border border-warm-200 overflow-hidden hover:shadow-xl hover:-translate-y-1 transition-all duration-300">
  <div className={`h-1.5 ${service.accentColor}`} />
  <div className="p-6">
    {/* content */}
  </div>
</div>
```

Accent colors for services:
- Bill Management: `bg-haven-500`
- Home Maintenance: `bg-blue-500`
- Vendor Coordination: `bg-purple-500`
- Life Management: `bg-champagne-400`

### 3.8 Update Handyman Section (CRITICAL FIX)

```tsx
<section className="py-16 sm:py-24 bg-gradient-to-br from-warm-900 via-warm-800 to-warm-900 text-white relative overflow-hidden">
  {/* Background decoration */}
  <div className="absolute inset-0 overflow-hidden pointer-events-none">
    <div className="absolute top-0 right-0 w-96 h-96 bg-champagne-300 rounded-full blur-3xl opacity-10" />
    <div className="absolute bottom-0 left-0 w-72 h-72 bg-haven-500 rounded-full blur-3xl opacity-10" />
  </div>

  <div className="relative max-w-6xl mx-auto px-4 sm:px-6">
    <div className="grid lg:grid-cols-2 gap-12 items-center">
      <div>
        <p className="text-champagne-300 font-semibold mb-2">The Haven Difference</p>
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
              <CheckCircle2 className="w-5 h-5 text-champagne-300" />
              <span className="text-warm-200">{item}</span>
            </div>
          ))}
        </div>
      </div>

      <div className="bg-white rounded-2xl p-6 text-warm-900 shadow-2xl">
        <div className="flex items-center gap-4 mb-4">
          <div className="w-16 h-16 rounded-full bg-gradient-to-br from-champagne-300 to-champagne-400 flex items-center justify-center text-warm-800 font-bold text-xl shadow-lg">
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
            <span className="font-medium text-haven-600">12 (saved $3,400+)</span>
          </div>
          <div className="flex justify-between">
            <span className="text-warm-500">Your home</span>
            <span className="font-medium">Knows it inside & out</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</section>
```

### 3.9 Update Pricing Section

```tsx
<section id="pricing" className="py-16 sm:py-24 bg-gradient-to-b from-haven-50 to-white">
```

Card accent bars:
- Essentials: `<div className="h-1.5 bg-warm-300" />`
- Lite (Most Popular): `<div className="h-1.5 bg-gradient-to-r from-haven-500 to-haven-600" />`
- Haven: `<div className="h-1.5 bg-champagne-400" />`

Most Popular badge:
```tsx
<span className="px-4 py-1.5 bg-gradient-to-r from-haven-600 to-haven-700 text-white text-sm font-semibold rounded-full shadow-lg">
  Most Popular
</span>
```

"How Your Bill Works" - change price range text:
```tsx
<p className="text-haven-600 font-bold">$39 to $3,499</p>
```

Example highlight box:
```tsx
<div className="mt-6 p-4 bg-champagne-100 rounded-xl border border-champagne-200">
  <p className="text-center text-sm text-champagne-600">
    <strong>Example:</strong> $3,200 in monthly bills + $39 Essentials = <strong>$3,239 total</strong>.
    One payment to Haven. We pay everyone else.
  </p>
</div>
```

### 3.10 Update Compare Plans Section

```tsx
<section className="py-16 sm:py-24 bg-warm-900 text-white">
```

Table header - Lite column:
```tsx
<th className="text-center py-4 px-4 bg-haven-600/20">
  <div className="font-semibold text-champagne-300">Lite</div>
  <div className="text-haven-400 font-bold">$349/mo</div>
</th>
```

Lite column cells:
```tsx
<td className="py-4 px-4 text-center bg-haven-600/20">
  {row.lite === true ? (
    <Check className="w-5 h-5 text-champagne-300 mx-auto" />
  ) : row.lite === false ? (
    <X className="w-5 h-5 text-warm-600 mx-auto" />
  ) : (
    <span className="text-sm font-medium text-champagne-300">{row.lite}</span>
  )}
</td>
```

Mobile cards - Lite column:
```tsx
<div className="p-3 text-center bg-haven-600/20">
  <div className="text-xs text-champagne-300 mb-1">$349</div>
  <div className="text-sm font-medium text-champagne-300">{row.lite}</div>
</div>
```

CTA button:
```tsx
<Link
  href="/register"
  className="inline-flex items-center gap-2 px-8 py-3 bg-white text-haven-700 font-semibold rounded-xl hover:bg-champagne-50 transition-colors"
>
  Start for $39/month
  <ArrowRight className="w-5 h-5" />
</Link>
```

### 3.11 Update Software vs Service Section

```tsx
<section className="py-16 sm:py-24 bg-white">
```

Table headers:
```tsx
<div className="p-4 sm:p-6 text-center border-b sm:border-b-0 sm:border-r border-warm-200 bg-red-50">
  <p className="font-semibold text-red-700">Household Software</p>
  <p className="text-sm text-red-600">$375/mo + $3K setup</p>
</div>
<div className="p-4 sm:p-6 text-center bg-haven-50">
  <p className="font-semibold text-haven-700">Haven</p>
  <p className="text-sm text-haven-600">$349/mo, no setup fee</p>
</div>
```

Bottom CTA box:
```tsx
<div className="mt-8 bg-gradient-to-r from-haven-600 to-haven-700 rounded-2xl p-6 sm:p-8 text-center text-white">
  <p className="text-lg sm:text-xl font-semibold mb-4">
    Why pay more for software that makes YOU do the work?
  </p>
  <p className="text-haven-100 mb-6">
    Start with Haven Essentials for just $39/month or get full service at $349/month with no setup fee.
  </p>
  <Link
    href="/register"
    className="inline-flex items-center gap-2 px-8 py-3 bg-white text-haven-700 font-semibold rounded-xl hover:bg-champagne-50 transition-colors"
  >
    Start for $39/month
    <ArrowRight className="w-5 h-5" />
  </Link>
</div>
```

### 3.12 Update Testimonials Section

```tsx
<section className="py-16 sm:py-24 bg-gradient-to-b from-champagne-50 to-champagne-100/50">
```

Cards:
```tsx
<div className="bg-white rounded-2xl p-6 border border-warm-200 flex flex-col shadow-lg">
```

Highlight badges - use varied sophisticated colors:
```tsx
{[
  {
    // ... other fields
    highlight: 'Worth every penny',
    badgeColor: 'bg-haven-100 text-haven-700',
  },
  {
    // ... other fields
    highlight: 'Saved $400',
    badgeColor: 'bg-green-100 text-green-700',
  },
  {
    // ... other fields
    highlight: 'Prevented major repair',
    badgeColor: 'bg-champagne-200 text-champagne-600',
  },
]}
```

Stats row:
```tsx
{[
  { value: '8+', label: 'Hours saved monthly', color: 'text-haven-600' },
  { value: '500+', label: 'Families served', color: 'text-champagne-500' },
  { value: '4.9', label: 'Average rating', color: 'text-haven-600' },
  { value: '$0', label: 'Hidden fees', color: 'text-green-600' },
].map((stat, idx) => (
  <div key={idx} className="text-center bg-white rounded-xl p-4 shadow-md border border-warm-200">
    <p className={`text-3xl sm:text-4xl font-bold ${stat.color}`}>{stat.value}</p>
    <p className="text-warm-500">{stat.label}</p>
  </div>
))}
```

### 3.13 Update FAQ Section

```tsx
<section id="faq" className="py-16 sm:py-24 bg-white">
```

Open state chevron:
```tsx
{openFaq === idx ? (
  <ChevronUp className="w-5 h-5 text-haven-600 flex-shrink-0" />
) : (
  <ChevronDown className="w-5 h-5 text-warm-400 flex-shrink-0" />
)}
```

Expanded answer:
```tsx
{openFaq === idx && (
  <div className="px-6 pb-4 text-warm-600 bg-warm-50">
    {faq.a}
  </div>
)}
```

### 3.14 Update Final CTA Section

```tsx
<section className="py-16 sm:py-24 bg-gradient-to-br from-haven-600 via-haven-700 to-haven-800 relative overflow-hidden">
  {/* Background decoration */}
  <div className="absolute inset-0 overflow-hidden pointer-events-none">
    <div className="absolute top-0 right-0 w-96 h-96 bg-champagne-300 rounded-full blur-3xl opacity-15" />
    <div className="absolute bottom-0 left-0 w-72 h-72 bg-haven-400 rounded-full blur-3xl opacity-20" />
  </div>

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
    <p className="mt-4 text-champagne-300 font-medium">
      Not another app. Actual help when you need it.
    </p>
    <div className="mt-8 flex flex-col sm:flex-row items-center justify-center gap-4">
      <Link
        href="/register"
        className="w-full sm:w-auto px-8 py-4 bg-white text-haven-700 font-semibold rounded-xl hover:bg-champagne-50 transition-colors text-lg flex items-center justify-center gap-2"
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
</section>
```

---

## TASK 4: Verification Checklist

After implementing, verify:

- [ ] Navbar appears at top of page
- [ ] Navbar changes from transparent to white on scroll
- [ ] Navbar has Sign In link and Get Started button
- [ ] Mobile menu works correctly
- [ ] No em dashes (— or –) anywhere in the file
- [ ] Hero has dark gradient, champagne accent text
- [ ] Hero CTAs are white (primary) and ghost border (secondary)
- [ ] Pain points have red/green card styling
- [ ] Stat bar uses champagne colors
- [ ] Service cards have colored accent bars and hover effects
- [ ] Handyman section has DARK background (warm-900) with WHITE heading
- [ ] Handyman section uses champagne accents (not amber)
- [ ] Pricing cards have accent bars
- [ ] Compare Plans has dark background with champagne highlights
- [ ] Testimonials has champagne gradient background
- [ ] FAQ has section id="faq"
- [ ] All navigation links work (smooth scroll to sections)

---

## TASK 5: Build and Deploy

```bash
# Build to check for TypeScript errors
pnpm build

# Test locally
pnpm dev

# Commit changes
git add .
git commit -m "Add navigation bar, implement champagne accent color, refine homepage design"

# Push to production
git push origin main
```
