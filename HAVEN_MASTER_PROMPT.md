# 🏠 HAVEN MASTER UPDATE PROMPT
## Complete Homepage Redesign + Platform Fixes

This is a comprehensive update to transform Haven into a market-leading home management platform that crushes the competition (Nines Living). Execute all parts in order.

---

# PART 1: COMPETITIVE CONTEXT

## Our Competition: Nines Living (ninesliving.com)

**What Nines Charges:**
- Starter: $4,500/year ($375/mo) + $3,000 onboarding = $7,500 first year
- Standard: $6,300/year ($525/mo) + $5,000 onboarding = $11,300 first year
- 12-month prepaid commitment required

**What Nines Provides:**
- Software platform only (digital household manual)
- Templates, task lists, protocols
- Document storage
- Phone/email support
- NO bill payment
- NO vendor coordination (just tracking)
- NO handyman visits
- NO humans doing actual work

**Our Advantage:**
Haven charges LESS than Nines and provides ACTUAL SERVICE — real humans who do the work, not just software to help you do it yourself.

| Feature | Nines Starter | Haven Lite |
|---------|---------------|------------|
| Monthly Price | $375 | $349 |
| Onboarding Fee | $3,000+ | $0 |
| First Year Cost | $7,500+ | $4,188 |
| Contract | 12-mo prepaid | Monthly |
| Bills Paid For You | ❌ | ✅ |
| Vendors Coordinated | ❌ | ✅ |
| Humans Doing Work | ❌ | ✅ |

**Kill Shot Messaging:**
> "Nines charges $375/month for software to help YOU manage your home.
> Haven charges $349/month and WE manage your home for you."

---

# PART 2: HAVEN PRICING TIERS

## Tier 1: HAVEN LITE — $349/month
**"The Smart Start"**
- Bill consolidation & auto-pay (up to 15 accounts)
- Vendor directory & reactive coordination
- Document vault & digital home manual
- Text-based home manager support (25:1 ratio)
- Same-day response during business hours
- No onboarding fee
- Month-to-month (no annual commitment)

*Target: Condos, apartments, townhomes, smaller homes*
*Margin: ~31%*

---

## Tier 2: HAVEN — $749/month ⭐ MOST POPULAR
**"Complete Home Management"**
- Everything in Lite
- Proactive home manager with regular check-ins (12:1 ratio)
- Monthly handyman visit (2 hours)
- Vendor oversight, vetting & negotiation
- Maintenance tracking & preventive care program
- Seasonal prep coordination
- Grocery & household supply coordination
- 12-hour response time

*Target: Most homeowners, busy families, professionals*
*Margin: ~28%*

---

## Tier 3: HAVEN+ — $1,499/month
**"Home + Life Management"**
- Everything in Haven
- Personal assistant services (5:1 ratio)
- Errand running, pickups & returns
- Package management
- Shopping & personal procurement
- Travel coordination & booking
- Event planning assistance
- Pet care coordination
- Guest preparation
- 4-hour priority response
- Enhanced handyman (4 hours/month)

*Target: Executives, affluent families, busy professionals*
*Margin: ~17%*

---

## Tier 4: HAVEN ESTATE — $3,499+/month
**"White Glove Service"**
- Dedicated home manager (2:1 or 1:1 ratio)
- Dedicated handyman access (8+ hours/month)
- Full concierge services
- Multiple property management
- Custom service scope
- 2-hour priority response
- Quarterly home review meetings

*Target: Estates, UHNW families, multiple properties*
*Margin: ~15%*

---

## How Billing Works (Explain on Homepage)
- **Haven Membership:** $349-$3,499/mo (your manager, platform, handyman)
- **Household Bills:** Passed through at cost, zero markup
- **Example:** $3,200 in monthly bills + $749 Haven = $3,949 total to Haven. We pay everyone else.

---

# PART 3: HOMEPAGE COMPLETE REWRITE

Replace the entire contents of `apps/web/src/app/page.tsx` with:

```tsx
'use client';

import { useState } from 'react';
import Link from 'next/link';
import { motion } from 'framer-motion';
import {
  Home,
  Check,
  X,
  ArrowRight,
  DollarSign,
  MessageSquare,
  Wrench,
  Calendar,
  FileText,
  Shield,
  Clock,
  Users,
  Zap,
  Droplets,
  Wifi,
  Sparkles,
  Star,
  Lock,
  BadgeCheck,
  CheckCircle2,
  ChevronDown,
  ChevronRight,
  Award,
  ShieldCheck,
  Hammer,
  PiggyBank,
  Timer,
  Bot,
  Laptop,
  HeartHandshake,
  Receipt,
  Heart,
  Phone,
  Mail,
  Package,
  Car,
  ClipboardList,
  Flame,
  Leaf,
  Building2,
  MapPin,
} from 'lucide-react';

// ============================================================================
// NAVIGATION
// ============================================================================
function Navigation() {
  return (
    <nav className="fixed top-0 left-0 right-0 z-50 bg-white/95 backdrop-blur-sm border-b border-slate-200">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          <Link href="/" className="flex items-center gap-2">
            <div className="w-9 h-9 bg-emerald-600 rounded-xl flex items-center justify-center">
              <Home className="w-5 h-5 text-white" />
            </div>
            <span className="text-xl font-bold text-slate-900">Haven</span>
          </Link>
          <div className="hidden md:flex items-center gap-8">
            <a href="#how-it-works" className="text-slate-600 hover:text-slate-900 text-sm font-medium transition-colors">How It Works</a>
            <a href="#services" className="text-slate-600 hover:text-slate-900 text-sm font-medium transition-colors">Services</a>
            <a href="#pricing" className="text-slate-600 hover:text-slate-900 text-sm font-medium transition-colors">Pricing</a>
            <a href="#compare" className="text-slate-600 hover:text-slate-900 text-sm font-medium transition-colors">Compare</a>
            <Link href="/login" className="text-slate-600 hover:text-slate-900 text-sm font-medium transition-colors">Login</Link>
            <Link 
              href="/register" 
              className="px-5 py-2.5 bg-emerald-600 text-white text-sm font-semibold rounded-lg hover:bg-emerald-700 transition-colors shadow-sm"
            >
              Get Started
            </Link>
          </div>
          <Link href="/register" className="md:hidden px-4 py-2 bg-emerald-600 text-white text-sm font-semibold rounded-lg">
            Get Started
          </Link>
        </div>
      </div>
    </nav>
  );
}

// ============================================================================
// HERO SECTION
// ============================================================================
function HeroSection() {
  return (
    <section className="relative pt-24 pb-16 lg:pb-24 px-4 sm:px-6 lg:px-8 overflow-hidden bg-gradient-to-b from-slate-50 via-white to-white">
      <div className="absolute top-0 right-0 w-1/2 h-full bg-gradient-to-l from-emerald-50/50 to-transparent pointer-events-none" />
      
      <div className="max-w-7xl mx-auto relative">
        <div className="grid lg:grid-cols-2 gap-12 lg:gap-16 items-center">
          {/* Left Column - Content */}
          <div className="relative z-10">
            {/* Badge */}
            <div className="inline-flex items-center gap-2 px-4 py-2 bg-emerald-50 border border-emerald-200 rounded-full mb-6">
              <HeartHandshake className="w-4 h-4 text-emerald-600" />
              <span className="text-sm font-medium text-emerald-800">
                Full-service home management — not just software
              </span>
            </div>

            <h1 className="font-serif text-4xl sm:text-5xl lg:text-6xl font-bold text-slate-900 leading-[1.1] tracking-tight mb-6">
              Stop Managing
              <br />
              Your Home.
              <br />
              <span className="text-emerald-600">Start Living In It.</span>
            </h1>

            <p className="text-xl lg:text-2xl text-slate-900 font-semibold mb-2">
              One bill. One contact. Zero hassle.
            </p>
            
            <p className="text-lg text-slate-600 max-w-xl mb-8 leading-relaxed">
              Not another app to organize your chaos — <strong>actual humans who eliminate it.</strong> Your dedicated Home Manager handles everything so you can focus on what matters.
            </p>

            {/* Value Props */}
            <div className="flex flex-wrap gap-3 mb-8">
              {[
                { icon: Receipt, label: 'One Bill', color: 'amber' },
                { icon: MessageSquare, label: 'One Contact', color: 'emerald' },
                { icon: CheckCircle2, label: 'Zero Hassle', color: 'sky' },
              ].map(({ icon: Icon, label, color }) => (
                <div key={label} className="flex items-center gap-2 px-4 py-2 bg-white rounded-full border border-slate-200 shadow-sm">
                  <Icon className={`w-4 h-4 text-${color}-600`} />
                  <span className="text-sm font-medium text-slate-700">{label}</span>
                </div>
              ))}
            </div>

            {/* CTAs */}
            <div className="flex flex-col sm:flex-row items-start gap-4 mb-10">
              <Link
                href="/register"
                className="inline-flex items-center justify-center gap-2 px-8 py-4 bg-emerald-600 text-white text-lg font-semibold rounded-xl hover:bg-emerald-700 transition-all shadow-lg shadow-emerald-600/25 hover:shadow-xl hover:shadow-emerald-600/30"
              >
                Start for $349/month
                <ArrowRight className="w-5 h-5" />
              </Link>
              <a
                href="#how-it-works"
                className="inline-flex items-center justify-center gap-2 px-8 py-4 text-slate-700 text-lg font-medium hover:text-emerald-600 transition-colors"
              >
                See How It Works
                <ChevronDown className="w-5 h-5" />
              </a>
            </div>

            {/* Trust Bar */}
            <div className="flex flex-wrap items-center gap-6 pt-8 border-t border-slate-200">
              {[
                { icon: Lock, label: 'FDIC-Insured' },
                { icon: Shield, label: '$2M Coverage' },
                { icon: ShieldCheck, label: 'SOC 2 Certified' },
                { icon: Star, label: '4.9/5 Rating', fill: true },
              ].map(({ icon: Icon, label, fill }) => (
                <div key={label} className="flex items-center gap-2 text-slate-500">
                  <Icon className={`w-4 h-4 ${fill ? 'text-amber-400 fill-amber-400' : ''}`} />
                  <span className="text-sm font-medium">{label}</span>
                </div>
              ))}
            </div>
          </div>

          {/* Right Column - Visual */}
          <div className="relative hidden lg:block">
            <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[500px] h-[500px] bg-gradient-to-r from-emerald-200/30 to-sky-200/30 rounded-full blur-3xl" />
            
            {/* Manager Card */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2, duration: 0.6 }}
              className="relative bg-white rounded-2xl shadow-2xl shadow-slate-900/10 border border-slate-200 overflow-hidden max-w-sm mx-auto"
            >
              <div className="p-5 border-b border-slate-100 bg-gradient-to-r from-emerald-50 to-white">
                <div className="flex items-center gap-3">
                  <div className="w-12 h-12 bg-gradient-to-br from-emerald-500 to-emerald-600 rounded-full flex items-center justify-center shadow-lg shadow-emerald-500/30">
                    <span className="text-lg font-bold text-white">SH</span>
                  </div>
                  <div className="flex-1">
                    <p className="font-semibold text-slate-900">Sarah, Your Home Manager</p>
                    <p className="text-sm text-emerald-600 flex items-center gap-1.5">
                      <span className="w-2 h-2 bg-emerald-500 rounded-full animate-pulse" />
                      Active now
                    </p>
                  </div>
                </div>
              </div>
              
              <div className="p-5 space-y-3">
                <div className="flex items-start gap-3 p-3 bg-emerald-50 rounded-xl border border-emerald-100">
                  <CheckCircle2 className="w-5 h-5 text-emerald-600 mt-0.5 flex-shrink-0" />
                  <div>
                    <p className="text-sm font-medium text-slate-900">Furnace service completed</p>
                    <p className="text-xs text-slate-500">Filter changed, ready for winter</p>
                  </div>
                </div>
                
                <div className="flex items-start gap-3 p-3 bg-amber-50 rounded-xl border border-amber-100">
                  <DollarSign className="w-5 h-5 text-amber-600 mt-0.5 flex-shrink-0" />
                  <div>
                    <p className="text-sm font-medium text-slate-900">December bills paid</p>
                    <p className="text-xs text-slate-500">Mortgage, utilities, lawn care — all set</p>
                  </div>
                </div>
                
                <div className="flex items-start gap-3 p-3 bg-sky-50 rounded-xl border border-sky-100">
                  <Calendar className="w-5 h-5 text-sky-600 mt-0.5 flex-shrink-0" />
                  <div>
                    <p className="text-sm font-medium text-slate-900">Gutter cleaning scheduled</p>
                    <p className="text-xs text-slate-500">Tuesday 10am — no action needed</p>
                  </div>
                </div>
              </div>
              
              <div className="p-4 bg-slate-50 border-t border-slate-100">
                <p className="text-xs text-center text-slate-500 font-medium">
                  ✨ No action needed from you. We've got it covered.
                </p>
              </div>
            </motion.div>

            {/* Floating Badge - Bills */}
            <motion.div
              initial={{ opacity: 0, x: -30 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.5, duration: 0.5 }}
              className="absolute top-8 -left-4 bg-white rounded-xl shadow-xl border border-slate-200 p-4"
            >
              <div className="flex items-center gap-3 mb-2">
                <div className="flex -space-x-2">
                  {[Zap, Droplets, Wifi, Flame].map((Icon, i) => (
                    <div key={i} className={`w-7 h-7 rounded-full flex items-center justify-center border-2 border-white ${
                      ['bg-amber-100', 'bg-cyan-100', 'bg-purple-100', 'bg-orange-100'][i]
                    }`}>
                      <Icon className={`w-3.5 h-3.5 ${
                        ['text-amber-600', 'text-cyan-600', 'text-purple-600', 'text-orange-600'][i]
                      }`} />
                    </div>
                  ))}
                </div>
                <ArrowRight className="w-4 h-4 text-slate-400" />
                <div className="w-9 h-9 bg-emerald-600 rounded-lg flex items-center justify-center shadow-lg shadow-emerald-500/30">
                  <Home className="w-5 h-5 text-white" />
                </div>
              </div>
              <p className="text-sm font-semibold text-slate-900">12 bills → 1 payment</p>
            </motion.div>

            {/* Floating Badge - Time */}
            <motion.div
              initial={{ opacity: 0, x: 30 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.7, duration: 0.5 }}
              className="absolute bottom-24 -right-4 bg-white rounded-xl shadow-xl border border-slate-200 p-4"
            >
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-sky-100 rounded-lg flex items-center justify-center">
                  <Timer className="w-5 h-5 text-sky-600" />
                </div>
                <div>
                  <p className="text-2xl font-bold text-slate-900">8+ hrs</p>
                  <p className="text-xs text-slate-500 font-medium">saved monthly</p>
                </div>
              </div>
            </motion.div>
          </div>
        </div>
      </div>
    </section>
  );
}

// ============================================================================
// PROBLEM SECTION
// ============================================================================
function ProblemSection() {
  return (
    <section className="py-20 px-4 sm:px-6 lg:px-8 bg-slate-900 text-white">
      <div className="max-w-6xl mx-auto">
        <div className="text-center mb-12">
          <h2 className="font-serif text-3xl sm:text-4xl lg:text-5xl font-bold mb-4">
            Owning a home shouldn't feel like a second job.
          </h2>
          <p className="text-xl text-slate-300 max-w-3xl mx-auto">
            You're juggling a career, family, and life. The last thing you need is to be the unpaid project manager of your own home.
          </p>
        </div>

        <div className="grid md:grid-cols-2 gap-6 lg:gap-8">
          {/* Without Haven */}
          <div className="bg-slate-800/60 backdrop-blur rounded-2xl p-6 lg:p-8 border border-slate-700">
            <div className="flex items-center gap-2 mb-6">
              <div className="w-10 h-10 bg-red-500/20 rounded-lg flex items-center justify-center">
                <X className="w-5 h-5 text-red-400" />
              </div>
              <h3 className="text-xl font-semibold text-white">Without Haven</h3>
            </div>
            <ul className="space-y-4">
              {[
                '12+ vendor relationships to juggle',
                'Dozens of bills arriving at random',
                'Hours spent on hold with contractors',
                'Forgotten maintenance = expensive repairs',
                "You're the unpaid project manager",
                'Constant mental overhead',
              ].map((item, i) => (
                <li key={i} className="flex items-start gap-3">
                  <X className="w-5 h-5 text-red-400 mt-0.5 flex-shrink-0" />
                  <span className="text-slate-300">{item}</span>
                </li>
              ))}
            </ul>
          </div>

          {/* With Haven */}
          <div className="bg-emerald-900/40 backdrop-blur rounded-2xl p-6 lg:p-8 border border-emerald-700/50">
            <div className="flex items-center gap-2 mb-6">
              <div className="w-10 h-10 bg-emerald-500/20 rounded-lg flex items-center justify-center">
                <CheckCircle2 className="w-5 h-5 text-emerald-400" />
              </div>
              <h3 className="text-xl font-semibold text-white">With Haven</h3>
            </div>
            <ul className="space-y-4">
              {[
                '1 dedicated Home Manager',
                '1 monthly bill, auto-paid',
                'Text your manager, we make the calls',
                'Proactive maintenance catches issues early',
                'Results, not more to-do lists',
                'Complete peace of mind',
              ].map((item, i) => (
                <li key={i} className="flex items-start gap-3">
                  <Check className="w-5 h-5 text-emerald-400 mt-0.5 flex-shrink-0" />
                  <span className="text-emerald-100">{item}</span>
                </li>
              ))}
            </ul>
          </div>
        </div>

        <div className="mt-12 text-center">
          <p className="text-2xl text-white">
            <span className="font-bold">8+ hours per month</span>
            <span className="text-slate-300"> — that's what our members get back.</span>
          </p>
        </div>
      </div>
    </section>
  );
}

// ============================================================================
// COMPETITOR COMPARISON SECTION
// ============================================================================
function CompetitorSection() {
  return (
    <section id="compare" className="py-20 px-4 sm:px-6 lg:px-8 bg-amber-50 border-y border-amber-100">
      <div className="max-w-6xl mx-auto">
        <div className="text-center mb-12">
          <div className="inline-flex items-center gap-2 px-4 py-2 bg-amber-100 rounded-full mb-4">
            <Award className="w-4 h-4 text-amber-700" />
            <span className="text-sm font-semibold text-amber-800">The Real Difference</span>
          </div>
          <h2 className="font-serif text-3xl sm:text-4xl lg:text-5xl font-bold text-slate-900 mb-4">
            Software vs. Service
          </h2>
          <p className="text-xl text-slate-600 max-w-3xl mx-auto">
            Other companies give you software to organize your home management chaos.
            <strong> That's like giving a drowning person a waterproof notebook.</strong>
          </p>
        </div>

        {/* Main Comparison Table */}
        <div className="bg-white rounded-2xl shadow-xl border border-slate-200 overflow-hidden mb-12">
          {/* Header */}
          <div className="grid grid-cols-3 divide-x divide-slate-200">
            <div className="p-6 bg-slate-50">
              <p className="text-sm font-medium text-slate-500 uppercase tracking-wide">Feature</p>
            </div>
            <div className="p-6 bg-slate-100">
              <div className="flex items-center gap-2">
                <Bot className="w-5 h-5 text-slate-400" />
                <div>
                  <p className="text-sm font-semibold text-slate-500">Household Software</p>
                  <p className="text-xs text-slate-400">$375/mo + $3K setup</p>
                </div>
              </div>
            </div>
            <div className="p-6 bg-emerald-50">
              <div className="flex items-center gap-2">
                <Home className="w-5 h-5 text-emerald-600" />
                <div>
                  <p className="text-sm font-semibold text-emerald-700">Haven</p>
                  <p className="text-xs text-emerald-600">$349/mo, no setup fee</p>
                </div>
              </div>
            </div>
          </div>

          {/* Rows */}
          {[
            { feature: 'Monthly Cost', software: '$375/month', haven: '$349/month' },
            { feature: 'Setup/Onboarding', software: '$3,000 - $5,000', haven: '$0' },
            { feature: 'First Year Total', software: '$7,500+', haven: '$4,188' },
            { feature: 'Contract Required', software: '12-month prepaid', haven: 'Month-to-month' },
            { feature: 'Bills Paid For You', software: '❌ No — you pay each vendor', haven: '✅ Yes — one payment covers all' },
            { feature: 'Vendor Coordination', software: '❌ No — just a contact list', haven: '✅ Yes — we call, schedule, oversee' },
            { feature: 'Handyman Visits', software: '❌ No', haven: '✅ Yes — monthly preventive visits' },
            { feature: 'Humans Doing Work', software: '❌ No — software only', haven: '✅ Yes — dedicated manager' },
            { feature: 'When Something Breaks', software: 'You figure it out', haven: 'Text us. We fix it.' },
          ].map((row, i) => (
            <div key={i} className="grid grid-cols-3 divide-x divide-slate-200 border-t border-slate-200">
              <div className="p-4 md:p-5">
                <p className="font-medium text-slate-900 text-sm">{row.feature}</p>
              </div>
              <div className="p-4 md:p-5 bg-slate-50/50">
                <p className="text-sm text-slate-600">{row.software}</p>
              </div>
              <div className="p-4 md:p-5 bg-emerald-50/50">
                <p className="text-sm text-slate-900 font-medium">{row.haven}</p>
              </div>
            </div>
          ))}
        </div>

        {/* Bottom Message */}
        <div className="text-center">
          <div className="inline-block bg-white rounded-2xl p-8 shadow-lg border border-slate-200">
            <p className="text-2xl font-bold text-slate-900 mb-2">
              Why pay more for software that makes YOU do the work?
            </p>
            <p className="text-lg text-slate-600 mb-6">
              Haven costs <span className="text-emerald-600 font-semibold">$26/month less</span> with <span className="text-emerald-600 font-semibold">no setup fee</span> — and we actually do the work.
            </p>
            <Link
              href="/register"
              className="inline-flex items-center gap-2 px-8 py-4 bg-emerald-600 text-white font-semibold rounded-xl hover:bg-emerald-700 transition-colors shadow-lg shadow-emerald-600/25"
            >
              Get Actual Help — $349/month
              <ArrowRight className="w-5 h-5" />
            </Link>
          </div>
        </div>
      </div>
    </section>
  );
}

// ============================================================================
// HOW IT WORKS
// ============================================================================
function HowItWorksSection() {
  const steps = [
    {
      step: 1,
      icon: ClipboardList,
      title: 'Tell Us About Your Home',
      description: 'Share your vendors, bills, and preferences. We set up auto-pay and take over the relationships.',
      color: 'amber',
    },
    {
      step: 2,
      icon: PiggyBank,
      title: 'Fund Your Haven Wallet',
      description: 'One monthly payment covers everything. We pay your mortgage, utilities, and every vendor. FDIC-insured.',
      color: 'emerald',
    },
    {
      step: 3,
      icon: MessageSquare,
      title: 'Text Your Manager',
      description: "Something need fixing? Question about your home? Text once. Your dedicated manager handles everything.",
      color: 'sky',
    },
  ];

  return (
    <section id="how-it-works" className="py-24 px-4 sm:px-6 lg:px-8 bg-white">
      <div className="max-w-7xl mx-auto">
        <div className="text-center mb-16">
          <div className="inline-flex items-center gap-2 px-4 py-2 bg-emerald-100 rounded-full mb-4">
            <Sparkles className="w-4 h-4 text-emerald-700" />
            <span className="text-sm font-semibold text-emerald-800">Simple Setup</span>
          </div>
          <h2 className="font-serif text-3xl sm:text-4xl lg:text-5xl font-bold text-slate-900 mb-4">
            From Chaos to Calm in 3 Steps
          </h2>
          <p className="text-xl text-slate-600 max-w-2xl mx-auto">
            Get started in minutes. We handle everything from there.
          </p>
        </div>

        <div className="grid md:grid-cols-3 gap-8">
          {steps.map(({ step, icon: Icon, title, description, color }) => (
            <div key={step} className="relative">
              <div className={`absolute -top-4 -left-4 w-12 h-12 bg-${color}-600 rounded-full flex items-center justify-center text-white text-xl font-bold shadow-lg`}>
                {step}
              </div>
              <div className="bg-slate-50 rounded-2xl p-8 pt-12 h-full border border-slate-200 hover:border-slate-300 transition-colors">
                <div className={`w-14 h-14 bg-${color}-100 rounded-xl flex items-center justify-center mb-6`}>
                  <Icon className={`w-7 h-7 text-${color}-600`} />
                </div>
                <h3 className="text-xl font-bold text-slate-900 mb-3">{title}</h3>
                <p className="text-slate-600 leading-relaxed">{description}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

// ============================================================================
// SERVICES SECTION
// ============================================================================
function ServicesSection() {
  const services = [
    {
      icon: Receipt,
      title: 'Bill Management',
      color: 'amber',
      items: ['Mortgage & property taxes', 'All utilities (electric, gas, water)', 'Insurance & HOA dues', 'Every vendor invoice, on time'],
    },
    {
      icon: Wrench,
      title: 'Home Maintenance',
      color: 'emerald',
      items: ['Monthly handyman visits', 'HVAC service & filter changes', 'Plumbing & electrical coordination', 'Seasonal prep & winterization'],
    },
    {
      icon: Users,
      title: 'Vendor Coordination',
      color: 'sky',
      items: ['Find & vet qualified pros', 'Schedule & oversee all work', 'Handle disputes & issues', 'Negotiate on your behalf'],
    },
    {
      icon: Heart,
      title: 'Life Management',
      color: 'rose',
      badge: 'Haven+',
      items: ['Errand running & pickups', 'Package handling & returns', 'Travel coordination', 'Event planning'],
    },
  ];

  return (
    <section id="services" className="py-24 px-4 sm:px-6 lg:px-8 bg-slate-50">
      <div className="max-w-7xl mx-auto">
        <div className="text-center mb-16">
          <h2 className="font-serif text-3xl sm:text-4xl lg:text-5xl font-bold text-slate-900 mb-4">
            Everything Your Home Needs. Handled.
          </h2>
          <p className="text-xl text-slate-600 max-w-2xl mx-auto">
            From paying your mortgage to changing your furnace filter — we've got it.
          </p>
        </div>

        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
          {services.map((service) => (
            <div key={service.title} className="bg-white rounded-2xl p-6 border border-slate-200 shadow-sm hover:shadow-md transition-shadow">
              <div className="flex items-start justify-between mb-4">
                <div className={`w-12 h-12 bg-${service.color}-100 rounded-xl flex items-center justify-center`}>
                  <service.icon className={`w-6 h-6 text-${service.color}-600`} />
                </div>
                {service.badge && (
                  <span className="px-2 py-1 bg-rose-100 text-rose-700 text-xs font-semibold rounded-full">
                    {service.badge}
                  </span>
                )}
              </div>
              <h3 className="text-lg font-bold text-slate-900 mb-4">{service.title}</h3>
              <ul className="space-y-2">
                {service.items.map((item, i) => (
                  <li key={i} className="flex items-center gap-2 text-sm text-slate-600">
                    <Check className={`w-4 h-4 text-${service.color}-500 flex-shrink-0`} />
                    {item}
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>

        {/* Handyman Highlight */}
        <div className="mt-16 bg-emerald-900 rounded-3xl p-8 lg:p-12 text-white overflow-hidden relative">
          <div className="absolute top-0 right-0 w-1/3 h-full bg-gradient-to-l from-emerald-800/50 to-transparent" />
          <div className="relative grid lg:grid-cols-2 gap-8 items-center">
            <div>
              <div className="inline-flex items-center gap-2 px-4 py-2 bg-emerald-800 rounded-full mb-6">
                <Hammer className="w-4 h-4 text-emerald-300" />
                <span className="text-sm font-semibold text-emerald-200">The Haven Difference</span>
              </div>
              <h3 className="font-serif text-2xl sm:text-3xl font-bold mb-4 text-white">
                Your Own Dedicated Handyman
              </h3>
              <p className="text-emerald-100 text-lg leading-relaxed mb-6">
                Unlike software that just tracks maintenance, Haven includes a dedicated handyman who physically visits your home monthly. They catch small issues before they become expensive emergencies.
              </p>
              <div className="grid grid-cols-2 gap-4">
                {[
                  'Monthly preventive visits',
                  'Same person every time',
                  'Filter changes included',
                  'Minor repairs on the spot',
                ].map((item, i) => (
                  <div key={i} className="flex items-center gap-2">
                    <CheckCircle2 className="w-5 h-5 text-emerald-400 flex-shrink-0" />
                    <span className="text-sm text-emerald-100">{item}</span>
                  </div>
                ))}
              </div>
            </div>
            <div className="bg-emerald-800/50 rounded-2xl p-6 border border-emerald-700">
              <div className="flex items-center gap-4 mb-6">
                <div className="w-16 h-16 bg-emerald-700 rounded-full flex items-center justify-center text-2xl font-bold text-white">
                  MR
                </div>
                <div>
                  <p className="text-lg font-bold text-white">Mike Rodriguez</p>
                  <p className="text-emerald-300">Your Dedicated Handyman</p>
                </div>
              </div>
              <div className="space-y-3">
                {[
                  { label: 'Next visit', value: 'Tuesday, 10am' },
                  { label: 'Issues caught this year', value: '12 (saved $3,400+)' },
                  { label: 'Your home', value: 'Knows it inside & out' },
                ].map((stat, i) => (
                  <div key={i} className="flex items-center justify-between p-3 bg-emerald-900/60 rounded-lg">
                    <span className="text-emerald-200 text-sm">{stat.label}</span>
                    <span className="text-white font-semibold text-sm">{stat.value}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

// ============================================================================
// PRICING SECTION
// ============================================================================
function PricingSection() {
  const plans = [
    {
      name: 'Lite',
      price: 349,
      description: 'Essential home management',
      popular: false,
      features: [
        'Bill consolidation (up to 15 accounts)',
        'Vendor coordination (reactive)',
        'Text-based home manager',
        'Document vault & home manual',
        'Same-day response',
      ],
      cta: 'Get Started',
      best: 'Best for condos & apartments',
    },
    {
      name: 'Haven',
      price: 749,
      description: 'Complete home management',
      popular: true,
      features: [
        'Everything in Lite',
        'Proactive home manager',
        'Monthly handyman visit (2 hrs)',
        'Vendor oversight & negotiation',
        'Maintenance scheduling',
        'Grocery coordination',
        '12-hour response time',
      ],
      cta: 'Get Started',
      best: 'Best for most homeowners',
    },
    {
      name: 'Haven+',
      price: 1499,
      description: 'Home + life management',
      popular: false,
      features: [
        'Everything in Haven',
        'Personal assistant services',
        'Errands, shopping & returns',
        'Travel coordination',
        'Event planning',
        '4-hour priority response',
        'Enhanced handyman (4 hrs/mo)',
      ],
      cta: 'Get Started',
      best: 'Best for busy executives',
    },
  ];

  return (
    <section id="pricing" className="py-24 px-4 sm:px-6 lg:px-8 bg-white">
      <div className="max-w-7xl mx-auto">
        <div className="text-center mb-16">
          <div className="inline-flex items-center gap-2 px-4 py-2 bg-emerald-100 rounded-full mb-4">
            <DollarSign className="w-4 h-4 text-emerald-700" />
            <span className="text-sm font-semibold text-emerald-800">Transparent Pricing</span>
          </div>
          <h2 className="font-serif text-3xl sm:text-4xl lg:text-5xl font-bold text-slate-900 mb-4">
            Plans That Fit Real Life
          </h2>
          <p className="text-xl text-slate-600 max-w-2xl mx-auto">
            No hidden fees. No setup costs. No annual contracts.
          </p>
        </div>

        <div className="grid lg:grid-cols-3 gap-8 max-w-6xl mx-auto">
          {plans.map((plan) => (
            <div 
              key={plan.name}
              className={`relative rounded-2xl p-8 ${
                plan.popular 
                  ? 'bg-emerald-900 text-white shadow-2xl shadow-emerald-900/20 lg:-mt-4 lg:mb-[-1rem]' 
                  : 'bg-white border-2 border-slate-200 shadow-sm'
              }`}
            >
              {plan.popular && (
                <div className="absolute top-0 left-1/2 -translate-x-1/2 -translate-y-1/2">
                  <span className="inline-flex items-center gap-1 px-4 py-1.5 bg-amber-400 text-slate-900 text-sm font-bold rounded-full shadow-lg">
                    <Star className="w-4 h-4" />
                    Most Popular
                  </span>
                </div>
              )}
              
              <div className={`mb-6 ${plan.popular ? 'pt-4' : ''}`}>
                <h3 className={`text-2xl font-bold mb-1 ${plan.popular ? 'text-white' : 'text-slate-900'}`}>
                  {plan.name}
                </h3>
                <p className={plan.popular ? 'text-emerald-300' : 'text-slate-500'}>
                  {plan.description}
                </p>
              </div>
              
              <div className="mb-6">
                <span className={`text-5xl font-bold ${plan.popular ? 'text-white' : 'text-slate-900'}`}>
                  ${plan.price}
                </span>
                <span className={plan.popular ? 'text-emerald-300' : 'text-slate-500'}>/month</span>
              </div>
              
              <ul className="space-y-3 mb-8">
                {plan.features.map((feature, i) => (
                  <li key={i} className="flex items-start gap-3">
                    <Check className={`w-5 h-5 mt-0.5 flex-shrink-0 ${
                      plan.popular ? 'text-emerald-400' : 'text-emerald-600'
                    }`} />
                    <span className={plan.popular ? 'text-emerald-50' : 'text-slate-600'}>
                      {feature}
                    </span>
                  </li>
                ))}
              </ul>
              
              <Link
                href={`/register?plan=${plan.name.toLowerCase()}`}
                className={`block w-full text-center px-6 py-3 font-semibold rounded-xl transition-colors ${
                  plan.popular
                    ? 'bg-white text-emerald-900 hover:bg-emerald-50'
                    : 'bg-slate-100 text-slate-900 hover:bg-slate-200'
                }`}
              >
                {plan.cta}
              </Link>
              
              <p className={`text-center text-sm mt-4 ${plan.popular ? 'text-emerald-300' : 'text-slate-500'}`}>
                {plan.best}
              </p>
            </div>
          ))}
        </div>

        {/* Estate Tier */}
        <div className="mt-12 max-w-4xl mx-auto">
          <div className="bg-slate-900 rounded-2xl p-8 text-white">
            <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-6">
              <div>
                <div className="flex items-center gap-3 mb-2">
                  <Building2 className="w-6 h-6 text-amber-400" />
                  <h3 className="text-2xl font-bold">Haven Estate</h3>
                </div>
                <p className="text-slate-300 mb-2">White glove service for estates & multiple properties</p>
                <p className="text-3xl font-bold">$3,499<span className="text-lg text-slate-400">+/month</span></p>
              </div>
              <div className="flex flex-col gap-3">
                <ul className="text-sm text-slate-300 space-y-1">
                  <li className="flex items-center gap-2"><Check className="w-4 h-4 text-emerald-400" /> Dedicated home manager (2:1 or 1:1)</li>
                  <li className="flex items-center gap-2"><Check className="w-4 h-4 text-emerald-400" /> Dedicated handyman access</li>
                  <li className="flex items-center gap-2"><Check className="w-4 h-4 text-emerald-400" /> Full concierge & multiple properties</li>
                </ul>
                <Link
                  href="/contact"
                  className="inline-flex items-center justify-center gap-2 px-6 py-3 bg-white text-slate-900 font-semibold rounded-xl hover:bg-slate-100 transition-colors"
                >
                  Contact Us
                  <ArrowRight className="w-4 h-4" />
                </Link>
              </div>
            </div>
          </div>
        </div>

        {/* How Billing Works */}
        <div className="mt-12 max-w-4xl mx-auto bg-amber-50 rounded-2xl p-6 lg:p-8 border border-amber-200">
          <h3 className="text-lg font-bold text-slate-900 mb-4 flex items-center gap-2">
            <DollarSign className="w-5 h-5 text-amber-600" />
            How Your Bill Works
          </h3>
          <div className="grid sm:grid-cols-2 gap-4 mb-4">
            <div className="bg-white rounded-xl p-4 border border-amber-100">
              <p className="text-sm font-medium text-slate-600 mb-1">Haven Membership</p>
              <p className="text-2xl font-bold text-emerald-600">$349–$3,499</p>
              <p className="text-xs text-slate-500 mt-1">Your manager, platform, handyman visits</p>
            </div>
            <div className="bg-white rounded-xl p-4 border border-amber-100">
              <p className="text-sm font-medium text-slate-600 mb-1">Your Household Bills</p>
              <p className="text-2xl font-bold text-slate-900">At Cost</p>
              <p className="text-xs text-slate-500 mt-1">Mortgage, utilities, vendors — zero markup</p>
            </div>
          </div>
          <p className="text-sm text-slate-600">
            <strong>Example:</strong> $3,200 in monthly bills + $749 Haven = <strong>$3,949 total</strong>. One payment to Haven. We pay everyone else.
          </p>
        </div>

        <div className="mt-8 text-center">
          <p className="text-slate-500 font-medium">No contracts. No setup fees. Cancel anytime.</p>
        </div>
      </div>
    </section>
  );
}

// ============================================================================
// SOCIAL PROOF
// ============================================================================
function SocialProofSection() {
  const testimonials = [
    {
      quote: "I thought this kind of service was only for people with mansions. Turns out it's for anyone tired of being their own property manager. Best money I spend each month.",
      name: 'Marcus T.',
      role: 'Software Developer, 3BR Colonial',
      highlight: 'Worth every penny',
    },
    {
      quote: "Last month Sarah caught an overcharge from our landscaper and saved us $400. The membership has literally paid for itself multiple times over.",
      name: 'Jennifer L.',
      role: 'Working Mom, Townhouse',
      highlight: 'Saved $400',
    },
    {
      quote: "The monthly handyman visit is worth the membership alone. Mike caught a small leak that would've destroyed our basement. Can't imagine going back.",
      name: 'David S.',
      role: 'Small Business Owner, 4BR Home',
      highlight: 'Prevented major repair',
    },
  ];

  return (
    <section className="py-24 px-4 sm:px-6 lg:px-8 bg-slate-50">
      <div className="max-w-7xl mx-auto">
        <div className="text-center mb-16">
          <h2 className="font-serif text-3xl sm:text-4xl font-bold text-slate-900 mb-4">
            Real Homeowners. Real Results.
          </h2>
          <p className="text-xl text-slate-600">
            Join hundreds of families who've reclaimed their time.
          </p>
        </div>

        <div className="grid md:grid-cols-3 gap-8">
          {testimonials.map((t, i) => (
            <div key={i} className="bg-white rounded-2xl p-8 shadow-sm border border-slate-200">
              <div className="flex items-center gap-1 mb-4">
                {[...Array(5)].map((_, j) => (
                  <Star key={j} className="w-5 h-5 text-amber-400 fill-amber-400" />
                ))}
              </div>
              <blockquote className="text-slate-700 leading-relaxed mb-6">
                "{t.quote}"
              </blockquote>
              <div className="flex items-center justify-between">
                <div>
                  <p className="font-bold text-slate-900">{t.name}</p>
                  <p className="text-sm text-slate-500">{t.role}</p>
                </div>
                <span className="px-3 py-1.5 bg-emerald-100 text-emerald-700 text-sm font-semibold rounded-full">
                  {t.highlight}
                </span>
              </div>
            </div>
          ))}
        </div>

        {/* Stats */}
        <div className="mt-16 grid grid-cols-2 md:grid-cols-4 gap-8 text-center">
          {[
            { value: '8+', label: 'Hours saved monthly' },
            { value: '500+', label: 'Families served' },
            { value: '4.9', label: 'Average rating' },
            { value: '$0', label: 'Hidden fees' },
          ].map((stat, i) => (
            <div key={i}>
              <p className="text-4xl font-bold text-emerald-600">{stat.value}</p>
              <p className="text-slate-600 font-medium">{stat.label}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

// ============================================================================
// FAQ
// ============================================================================
function FAQSection() {
  const [openIndex, setOpenIndex] = useState<number | null>(0);

  const faqs = [
    {
      q: 'Is this only for rich people with big estates?',
      a: "Not at all. We built Haven because professional home management shouldn't require a trust fund. Our Lite plan works perfectly for condos and apartments. The value comes from saving you time and preventing expensive repairs — that's valuable for any homeowner.",
    },
    {
      q: 'How is Haven different from household management software?',
      a: "Software gives you tools to organize things yourself — you still do all the work. Haven gives you actual humans who handle things for you. We don't give you a better to-do list. We take things off your list entirely. That's why we cost less than software-only solutions while delivering far more value.",
    },
    {
      q: 'Why should I pay for this when I can manage things myself?',
      a: "You can. The question is whether you want to. If you enjoy tracking down vendors, waiting on hold, and remembering when the furnace filter was last changed — keep doing that. If you'd rather text once and have it handled, that's what we do. Most members say they get 8+ hours back every month.",
    },
    {
      q: 'Do I have to sign an annual contract?',
      a: 'No. Month-to-month, cancel anytime. Some competitors lock you into 12-month prepaid commitments with thousands in setup fees. We believe if we do a good job, you\'ll stay. No contracts needed.',
    },
    {
      q: 'How does the one-bill system work?',
      a: 'You make one monthly payment to Haven. We use it to pay your mortgage, utilities, lawn care, cleaning, and every other household expense. Routine bills are automatic. Repairs and one-time expenses require your approval first. You see every transaction in real-time.',
    },
    {
      q: 'Is my money safe?',
      a: "Yes. Your Haven Wallet is FDIC-insured through our banking partner. You see every transaction in real-time, maintain full visibility, and can withdraw anytime. We never mark up vendor costs — your bills pass through at exactly what they cost.",
    },
  ];

  return (
    <section className="py-24 px-4 sm:px-6 lg:px-8 bg-white">
      <div className="max-w-3xl mx-auto">
        <div className="text-center mb-16">
          <h2 className="font-serif text-3xl sm:text-4xl font-bold text-slate-900 mb-4">
            Questions? We've Got Answers.
          </h2>
        </div>

        <div className="space-y-4">
          {faqs.map((faq, i) => (
            <div key={i} className="bg-slate-50 rounded-xl border border-slate-200 overflow-hidden">
              <button
                onClick={() => setOpenIndex(openIndex === i ? null : i)}
                className="w-full p-6 text-left flex items-center justify-between gap-4"
              >
                <span className="font-semibold text-slate-900">{faq.q}</span>
                <ChevronRight className={`w-5 h-5 text-slate-400 transition-transform flex-shrink-0 ${openIndex === i ? 'rotate-90' : ''}`} />
              </button>
              {openIndex === i && (
                <div className="px-6 pb-6">
                  <p className="text-slate-600 leading-relaxed">{faq.a}</p>
                </div>
              )}
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

// ============================================================================
// FINAL CTA
// ============================================================================
function FinalCTASection() {
  return (
    <section className="py-24 px-4 sm:px-6 lg:px-8 bg-gradient-to-b from-emerald-900 to-emerald-950 text-white">
      <div className="max-w-4xl mx-auto text-center">
        <h2 className="font-serif text-4xl sm:text-5xl font-bold mb-6">
          Ready to stop managing your home?
        </h2>
        <p className="text-2xl text-emerald-200 mb-4">
          One bill. One contact. Zero hassle.
        </p>
        <p className="text-lg text-emerald-300 mb-10 max-w-2xl mx-auto">
          Join hundreds of families who've reclaimed their time and peace of mind.
          <br />
          <strong className="text-white">Not another app. Actual help.</strong>
        </p>
        <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
          <Link
            href="/register"
            className="inline-flex items-center gap-2 px-8 py-4 bg-white text-emerald-900 text-lg font-bold rounded-xl hover:bg-emerald-50 transition-colors shadow-xl"
          >
            Start for $349/month
            <ArrowRight className="w-5 h-5" />
          </Link>
          <Link
            href="/login"
            className="inline-flex items-center gap-2 px-8 py-4 text-white text-lg font-medium hover:text-emerald-200 transition-colors"
          >
            Member Login
          </Link>
        </div>
        <p className="text-emerald-400 text-sm mt-6 font-medium">
          No contracts. No setup fees. Cancel anytime.
        </p>
      </div>
    </section>
  );
}

// ============================================================================
// FOOTER
// ============================================================================
function Footer() {
  return (
    <footer className="py-16 px-4 sm:px-6 lg:px-8 bg-slate-900 text-white">
      <div className="max-w-7xl mx-auto">
        <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-12 mb-12">
          <div>
            <div className="flex items-center gap-2 mb-4">
              <div className="w-9 h-9 bg-emerald-600 rounded-xl flex items-center justify-center">
                <Home className="w-5 h-5 text-white" />
              </div>
              <span className="text-xl font-bold">Haven</span>
            </div>
            <p className="text-slate-400 text-sm leading-relaxed">
              Full-service home management for everyone. One bill. One contact. Zero hassle.
            </p>
          </div>
          <div>
            <h4 className="font-semibold mb-4 text-white">Product</h4>
            <ul className="space-y-3 text-slate-400 text-sm">
              <li><a href="#how-it-works" className="hover:text-white transition-colors">How It Works</a></li>
              <li><a href="#services" className="hover:text-white transition-colors">Services</a></li>
              <li><a href="#pricing" className="hover:text-white transition-colors">Pricing</a></li>
              <li><a href="#compare" className="hover:text-white transition-colors">Compare</a></li>
            </ul>
          </div>
          <div>
            <h4 className="font-semibold mb-4 text-white">Company</h4>
            <ul className="space-y-3 text-slate-400 text-sm">
              <li><a href="#" className="hover:text-white transition-colors">About</a></li>
              <li><a href="#" className="hover:text-white transition-colors">Careers</a></li>
              <li><a href="#" className="hover:text-white transition-colors">Contact</a></li>
              <li><Link href="/login" className="hover:text-white transition-colors">Member Login</Link></li>
            </ul>
          </div>
          <div>
            <h4 className="font-semibold mb-4 text-white">Partners</h4>
            <ul className="space-y-3 text-slate-400 text-sm">
              <li><Link href="/vendor/login" className="hover:text-white transition-colors">Vendor Portal</Link></li>
              <li><Link href="/handyman/login" className="hover:text-white transition-colors">Handyman Portal</Link></li>
              <li><a href="#" className="hover:text-white transition-colors">Become a Partner</a></li>
            </ul>
          </div>
        </div>
        
        {/* Trust Badges */}
        <div className="flex flex-wrap items-center justify-center gap-8 py-8 border-t border-slate-800">
          {[
            { icon: Lock, label: 'FDIC-Insured' },
            { icon: Shield, label: '$2M Coverage' },
            { icon: ShieldCheck, label: 'SOC 2' },
            { icon: BadgeCheck, label: 'Vetted Pros' },
          ].map(({ icon: Icon, label }) => (
            <div key={label} className="flex items-center gap-2 text-slate-400">
              <Icon className="w-5 h-5" />
              <span className="text-sm font-medium">{label}</span>
            </div>
          ))}
        </div>

        <div className="pt-8 border-t border-slate-800 flex flex-col sm:flex-row items-center justify-between gap-4">
          <p className="text-slate-500 text-sm">© {new Date().getFullYear()} Haven. All rights reserved.</p>
          <div className="flex items-center gap-6 text-slate-500 text-sm">
            <a href="#" className="hover:text-white transition-colors">Privacy</a>
            <a href="#" className="hover:text-white transition-colors">Terms</a>
            <a href="#" className="hover:text-white transition-colors">Security</a>
          </div>
        </div>
      </div>
    </footer>
  );
}

// ============================================================================
// MAIN PAGE COMPONENT
// ============================================================================
export default function HomePage() {
  return (
    <div className="min-h-screen bg-white">
      <Navigation />
      <HeroSection />
      <ProblemSection />
      <CompetitorSection />
      <HowItWorksSection />
      <ServicesSection />
      <PricingSection />
      <SocialProofSection />
      <FAQSection />
      <FinalCTASection />
      <Footer />
    </div>
  );
}
```

---

# PART 4: GLOBAL STYLES UPDATE

Add these styles to `apps/web/src/app/globals.css`:

```css
/* Add after existing styles */

/* Typography Rules */
.font-serif {
  font-family: 'Playfair Display', Georgia, serif;
}

/* Page titles - ONLY h1 elements with this class get serif */
h1.page-title,
.page-title {
  font-family: 'Playfair Display', Georgia, serif;
}

/* Everything else uses Inter */
body, h2, h3, h4, h5, h6, p, span, div, a, button, input, textarea, select, label {
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
}

/* Override for explicit serif usage */
.font-serif {
  font-family: 'Playfair Display', Georgia, serif !important;
}

/* Contrast Fixes - White text on dark backgrounds */
.bg-emerald-900 *,
.bg-emerald-950 *,
.bg-slate-900 *,
.bg-slate-800 *,
[class*="bg-emerald-9"] *,
[class*="bg-slate-9"] *,
[class*="bg-slate-8"] * {
  --tw-text-opacity: 1;
}

/* Ensure headings in dark sections are white */
.bg-emerald-900 h1,
.bg-emerald-900 h2,
.bg-emerald-900 h3,
.bg-emerald-950 h1,
.bg-emerald-950 h2,
.bg-emerald-950 h3,
.bg-slate-900 h1,
.bg-slate-900 h2,
.bg-slate-900 h3 {
  color: white;
}
```

---

# PART 5: PROPERTY CONFIGURATION

Create `apps/web/src/lib/demo-property.ts`:

```typescript
// Demo property configuration - 38 Bedford Rd, Greenwich, CT
export const demoProperty = {
  address: {
    street: '38 Bedford Rd',
    city: 'Greenwich',
    state: 'CT',
    zip: '06831',
    full: '38 Bedford Rd, Greenwich, CT 06831',
  },
  name: 'Inspiration Farm',
  details: {
    bedrooms: 4,
    bathrooms: 5.5,
    squareFeet: 4500,
    lotSize: '4.38 acres',
    yearBuilt: 1920,
    style: 'Colonial',
    stories: 2,
  },
  features: [
    'Pool',
    'Horse barn',
    'GRTA trail access',
    'Generator',
    'Security system',
    'Irrigation system',
    'Invisible fence',
    'Wine cellar',
    'Home office',
    'Mudroom',
  ],
  systems: [
    { name: 'HVAC', type: 'Carrier Central Air', installed: '2019', lastService: '2024-03-15' },
    { name: 'Water Heater', type: 'Rheem 50 Gallon', installed: '2021', lastService: '2024-01-10' },
    { name: 'Well Pump', type: 'Grundfos', installed: '2018', lastService: '2024-06-01' },
    { name: 'Septic', type: '1500 Gallon', installed: '2015', lastService: '2024-02-20' },
    { name: 'Generator', type: 'Generac 22kW', installed: '2020', lastService: '2024-04-15' },
    { name: 'Security', type: 'ADT Smart Home', installed: '2022', lastService: '2024-05-01' },
    { name: 'Pool', type: 'Gunite, Salt Water', installed: '2010', lastService: '2024-05-15' },
    { name: 'Irrigation', type: 'Rain Bird', installed: '2019', lastService: '2024-04-01' },
  ],
  images: [
    'https://photos.zillowstatic.com/fp/1d1c3e9a0e6b9c1d5c8b0e9a0e6b9c1d-cc_ft_768.webp',
    'https://photos.zillowstatic.com/fp/2e2d4f0b1f7c0d2e6d9c1f0b1f7c0d2e-cc_ft_768.webp',
    'https://photos.zillowstatic.com/fp/3f3e5g1c2g8d1e3f7e0d2g1c2g8d1e3f-cc_ft_768.webp',
  ],
  accessNotes: {
    gateCode: '1234#',
    alarmCode: '5678',
    wifiNetwork: 'InspirationFarm_5G',
    wifiPassword: 'Welcome2024!',
    lockboxLocation: 'Back door, under mat',
    emergencyShutoffs: {
      water: 'Basement, northeast corner',
      gas: 'Exterior, south side of house',
      electrical: 'Basement, main panel by stairs',
    },
  },
};

export type DemoProperty = typeof demoProperty;
```

---

# PART 6: AVATAR SYSTEM

Create `apps/web/src/lib/avatars.ts`:

```typescript
// DiceBear avatar system for consistent user avatars
const AVATAR_STYLE = 'lorelei';
const AVATAR_BASE_URL = 'https://api.dicebear.com/7.x';

// Predefined avatar seeds for consistent appearance
const userAvatarSeeds: Record<string, string> = {
  'Bob': 'bob-burke-haven',
  'Alice': 'alice-burke-haven',
  'Emma': 'emma-burke-haven',
  'Jack': 'jack-burke-haven',
  'Sarah': 'sarah-manager-haven',
  'Mike': 'mike-handyman-haven',
  'Admin': 'admin-haven-system',
};

// Background colors for avatars
const avatarBackgrounds = [
  'b6e3f4', // light blue
  'c0aede', // light purple
  'd1d4f9', // light indigo
  'ffd5dc', // light pink
  'ffdfbf', // light orange
  'a3e4d7', // light teal
];

export function getAvatarUrl(seed: string, size: number = 128): string {
  const bgIndex = seed.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0) % avatarBackgrounds.length;
  const bg = avatarBackgrounds[bgIndex];
  
  return `${AVATAR_BASE_URL}/${AVATAR_STYLE}/svg?seed=${encodeURIComponent(seed)}&size=${size}&backgroundColor=${bg}`;
}

export function getUserAvatar(name: string, size: number = 128): string {
  const seed = userAvatarSeeds[name] || `${name.toLowerCase()}-haven-user`;
  return getAvatarUrl(seed, size);
}

export function getInitials(name: string): string {
  return name
    .split(' ')
    .map(part => part[0])
    .join('')
    .toUpperCase()
    .slice(0, 2);
}

// Avatar component props
export interface AvatarProps {
  name: string;
  size?: 'sm' | 'md' | 'lg' | 'xl';
  className?: string;
}

export const avatarSizes = {
  sm: 32,
  md: 48,
  lg: 64,
  xl: 96,
};
```

---

# PART 7: VENDOR IMAGES

Create `apps/web/src/lib/images.ts`:

```typescript
// Vendor images by category
export const vendorImages: Record<string, string[]> = {
  plumbing: [
    'https://images.unsplash.com/photo-1607472586893-edb57bdc0e39?w=400',
    'https://images.unsplash.com/photo-1585704032915-c3400ca199e7?w=400',
  ],
  electrical: [
    'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=400',
    'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400',
  ],
  hvac: [
    'https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=400',
    'https://images.unsplash.com/photo-1631545806609-35d4ae440431?w=400',
  ],
  landscaping: [
    'https://images.unsplash.com/photo-1558904541-efa843a96f01?w=400',
    'https://images.unsplash.com/photo-1592417817098-8fd3d9eb14a5?w=400',
  ],
  cleaning: [
    'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400',
    'https://images.unsplash.com/photo-1628177142898-93e36e4e3a50?w=400',
  ],
  roofing: [
    'https://images.unsplash.com/photo-1632778149955-e80f8ceca2e8?w=400',
  ],
  painting: [
    'https://images.unsplash.com/photo-1562259949-e8e7689d7828?w=400',
  ],
  pest_control: [
    'https://images.unsplash.com/photo-1609840114035-3c981b782dfe?w=400',
  ],
  pool: [
    'https://images.unsplash.com/photo-1576013551627-0cc20b96c2a7?w=400',
  ],
  security: [
    'https://images.unsplash.com/photo-1558002038-1055907df827?w=400',
  ],
  appliance: [
    'https://images.unsplash.com/photo-1584568694244-14fbdf83bd30?w=400',
  ],
  general: [
    'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=400',
  ],
};

export function getVendorImage(category: string, index: number = 0): string {
  const normalizedCategory = category.toLowerCase().replace(/\s+/g, '_');
  const images = vendorImages[normalizedCategory] || vendorImages.general;
  return images[index % images.length];
}

// Property images
export const propertyImages = {
  exterior: 'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=800',
  interior: 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800',
  kitchen: 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=800',
  bathroom: 'https://images.unsplash.com/photo-1552321554-5fefe8c9ef14?w=800',
  backyard: 'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=800',
};
```

---

# PART 8: SEED DATA UPDATE

Update `apps/api/prisma/seed.ts` to include:

1. **Property:** 38 Bedford Rd, Greenwich, CT 06831
2. **Family:** Bob (head), Alice (spouse), Emma (14), Jack (10), Max (dog)
3. **Vendors:** 25+ vendors across categories
4. **Avatar URLs:** Use DiceBear

Add this to your seed file:

```typescript
// Family members for the Burke household
const familyMembers = [
  {
    name: 'Bob Burke',
    role: 'HEAD',
    email: 'bob@example.com',
    phone: '203-555-0101',
    relationship: 'Head of Household',
  },
  {
    name: 'Alice Burke',
    role: 'SPOUSE',
    email: 'alice@example.com',
    phone: '203-555-0102',
    relationship: 'Spouse',
  },
  {
    name: 'Emma Burke',
    role: 'CHILD',
    email: 'emma@example.com',
    phone: '203-555-0103',
    relationship: 'Daughter',
    notes: 'Age 14, attends Greenwich Academy',
  },
  {
    name: 'Jack Burke',
    role: 'CHILD',
    phone: null,
    relationship: 'Son',
    notes: 'Age 10, attends North Street School',
  },
  {
    name: 'Max',
    role: 'PET',
    relationship: 'Family Dog',
    notes: 'Golden Retriever, 4 years old. Vet: Greenwich Animal Hospital',
  },
];

// Comprehensive vendor list
const vendors = [
  // Plumbing
  { name: 'Greenwich Plumbing Co.', category: 'Plumbing', phone: '203-555-1001', email: 'service@greenwichplumbing.com', rating: 5 },
  { name: 'Drain Masters CT', category: 'Plumbing', phone: '203-555-1002', email: 'help@drainmastersct.com', rating: 4 },
  
  // Electrical
  { name: 'Spark Electric LLC', category: 'Electrical', phone: '203-555-2001', email: 'jobs@sparkelectric.com', rating: 5 },
  { name: 'PowerPro Electrical', category: 'Electrical', phone: '203-555-2002', email: 'info@powerproct.com', rating: 4 },
  
  // HVAC
  { name: 'ComfortAir HVAC', category: 'HVAC', phone: '203-555-3001', email: 'service@comfortairhvac.com', rating: 5 },
  { name: 'Cool Breeze Heating & Air', category: 'HVAC', phone: '203-555-3002', email: 'schedule@coolbreezect.com', rating: 4 },
  
  // Landscaping
  { name: 'Green Thumb Landscaping', category: 'Landscaping', phone: '203-555-4001', email: 'info@greenthumbct.com', rating: 5 },
  { name: 'Perfect Lawns LLC', category: 'Landscaping', phone: '203-555-4002', email: 'service@perfectlawns.com', rating: 4 },
  { name: 'Tree Care Specialists', category: 'Landscaping', phone: '203-555-4003', email: 'trees@treecarect.com', rating: 5 },
  
  // Cleaning
  { name: 'Pristine Home Cleaning', category: 'Cleaning', phone: '203-555-5001', email: 'book@pristinehome.com', rating: 5 },
  { name: 'Maid Perfect', category: 'Cleaning', phone: '203-555-5002', email: 'schedule@maidperfect.com', rating: 4 },
  
  // Pool
  { name: 'Crystal Pool Service', category: 'Pool', phone: '203-555-6001', email: 'service@crystalpool.com', rating: 5 },
  
  // Pest Control
  { name: 'Guardian Pest Control', category: 'Pest Control', phone: '203-555-7001', email: 'help@guardianpest.com', rating: 4 },
  
  // Security
  { name: 'SecureHome CT', category: 'Security', phone: '203-555-8001', email: 'support@securehomect.com', rating: 5 },
  
  // Roofing
  { name: 'Top Notch Roofing', category: 'Roofing', phone: '203-555-9001', email: 'quotes@topnotchroofing.com', rating: 5 },
  
  // Painting
  { name: 'Pro Painters Greenwich', category: 'Painting', phone: '203-555-0201', email: 'estimate@propainters.com', rating: 4 },
  
  // Appliance
  { name: 'ApplianceFix CT', category: 'Appliance', phone: '203-555-0301', email: 'repair@appliancefixct.com', rating: 4 },
  
  // General Contractor
  { name: 'BuildRight Construction', category: 'General Contractor', phone: '203-555-0401', email: 'projects@buildright.com', rating: 5 },
  
  // Garage Door
  { name: 'Precision Garage Doors', category: 'Garage Door', phone: '203-555-0501', email: 'service@precisiondoors.com', rating: 4 },
  
  // Chimney
  { name: 'Clean Sweep Chimney', category: 'Chimney', phone: '203-555-0601', email: 'schedule@cleansweep.com', rating: 5 },
  
  // Windows
  { name: 'Clear View Windows', category: 'Windows', phone: '203-555-0701', email: 'quote@clearviewct.com', rating: 4 },
  
  // Flooring
  { name: 'Elite Flooring Solutions', category: 'Flooring', phone: '203-555-0801', email: 'info@eliteflooring.com', rating: 5 },
  
  // Septic
  { name: 'AAA Septic Services', category: 'Septic', phone: '203-555-0901', email: 'pump@aaaseptic.com', rating: 4 },
  
  // Generator
  { name: 'PowerGuard Generators', category: 'Generator', phone: '203-555-1101', email: 'service@powerguard.com', rating: 5 },
  
  // Snow Removal
  { name: 'Snow Pro CT', category: 'Snow Removal', phone: '203-555-1201', email: 'plow@snowproct.com', rating: 4 },
];

// Property configuration
const property = {
  addressLine1: '38 Bedford Rd',
  addressLine2: null,
  city: 'Greenwich',
  state: 'CT',
  zipCode: '06831',
  propertyType: 'SINGLE_FAMILY',
  bedrooms: 4,
  bathrooms: 5.5,
  squareFeet: 4500,
  lotSize: 4.38,
  yearBuilt: 1920,
};
```

---

# PART 9: NULL SAFETY FIXES

Apply these patterns throughout the codebase:

## Handyman Portal Fixes

In any file displaying task/household data:

```typescript
// Before
const address = task.household.homeProfile.addressLine1;

// After
const address = task.household?.homeProfile?.addressLine1 || 'Address not set';
const city = task.household?.homeProfile?.city || '';
const state = task.household?.homeProfile?.state || '';
const fullAddress = address + (city ? `, ${city}` : '') + (state ? `, ${state}` : '');
```

## Vendor Portal Fixes

```typescript
// Before
{vendor.jobs.map(job => ...)}

// After
{(vendor?.jobs || []).map(job => ...)}
```

## General Pattern

```typescript
// For arrays
const items = data?.items || [];

// For strings
const name = user?.name || 'Unknown';

// For numbers
const count = data?.count ?? 0;

// For nested objects
const profileImage = user?.profile?.avatar?.url || '/default-avatar.png';
```

---

# PART 10: VERIFICATION CHECKLIST

After running this prompt, verify:

## Homepage
- [ ] Hero shows "Start for $349/month"
- [ ] Competitor comparison section shows Haven vs. software pricing
- [ ] Pricing section shows $349 / $749 / $1,499 / $3,499+
- [ ] FAQ addresses "is this only for rich people?"
- [ ] All dark sections have white text
- [ ] Only h1 titles use serif font

## Property
- [ ] Dashboard shows 38 Bedford Rd, Greenwich, CT
- [ ] Property details show 4 bed, 5.5 bath, 4500 sqft

## Family
- [ ] Family page shows Bob, Alice, Emma, Jack, Max

## Vendors
- [ ] Vendors page shows 25+ vendors
- [ ] Map card doesn't overflow

## Avatars
- [ ] All users show DiceBear illustrated avatars

## Portals
- [ ] Handyman portal loads without null errors
- [ ] Vendor portal loads without null errors

---

# EXECUTION INSTRUCTIONS

```bash
cd /Users/tomburke/Projects/Housing-Manager

# 1. Apply all changes from this prompt

# 2. Reset and reseed the database
cd apps/api
pnpm prisma db push --force-reset
pnpm prisma db seed

# 3. Start the API
pnpm dev

# 4. In another terminal, start the web app
cd apps/web
pnpm dev

# 5. Test at http://localhost:3000
```

---

# SUMMARY

This prompt transforms Haven from a basic housing manager into a **market-dominating competitor** that:

1. **Beats Nines on price** — $349 vs $375/month
2. **Beats Nines on value** — $0 setup vs $3,000+
3. **Beats Nines on flexibility** — Monthly vs annual
4. **Beats Nines on service** — We DO the work, not just track it
5. **Clear competitive positioning** — Software vs. Service comparison
6. **Realistic pricing** — Based on actual unit economics
7. **Complete visual overhaul** — Professional, polished homepage
8. **All previous fixes included** — Typography, avatars, vendors, family, null safety

**The kill shot**: Haven costs LESS than Nines while delivering ACTUAL SERVICE instead of just software.
