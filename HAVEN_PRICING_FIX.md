# Haven Marketing Homepage - Complete Redesign

## CIO DECISION: New Hero Approach

**Problem with current:** "Your home, managed. Starting at just $39/month." is forgettable. It tells but doesn't sell.

**New Strategy:** Lead with the pain point, then the relief. The $39 is the hook in the CTA, not the headline.

---

# COMPLETE HOMEPAGE IMPLEMENTATION

## File: `apps/web/src/app/(marketing)/page.tsx`

```tsx
'use client';

import { useState } from 'react';
import Link from 'next/link';
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

export default function MarketingPage() {
  const [showPremiumTiers, setShowPremiumTiers] = useState(false);
  const [openFaq, setOpenFaq] = useState<number | null>(0);

  return (
    <div className="min-h-screen bg-white">
      {/* ================================================================== */}
      {/* HERO SECTION */}
      {/* ================================================================== */}
      <section className="relative overflow-hidden bg-gradient-to-b from-haven-50 via-white to-white pt-8 pb-16 sm:pt-12 sm:pb-24">
        {/* Background decoration */}
        <div className="absolute inset-0 overflow-hidden pointer-events-none">
          <div className="absolute -top-40 -right-40 w-80 h-80 bg-haven-100 rounded-full blur-3xl opacity-50" />
          <div className="absolute top-1/2 -left-20 w-60 h-60 bg-green-100 rounded-full blur-3xl opacity-40" />
        </div>

        <div className="relative max-w-6xl mx-auto px-4 sm:px-6">
          <div className="grid lg:grid-cols-2 gap-12 items-center">
            {/* Left - Copy */}
            <div className="text-center lg:text-left">
              {/* Trust badge */}
              <div className="inline-flex items-center gap-2 px-3 py-1.5 bg-white border border-warm-200 rounded-full shadow-sm mb-6">
                <span className="flex items-center gap-1">
                  <Star className="w-4 h-4 text-amber-500 fill-current" />
                  <span className="text-sm font-medium text-warm-700">4.9/5</span>
                </span>
                <span className="text-warm-300">|</span>
                <span className="text-sm text-warm-600">500+ families served</span>
              </div>

              {/* Main Headline */}
              <h1 className="text-4xl sm:text-5xl lg:text-6xl font-bold text-warm-900 tracking-tight leading-[1.1]">
                Stop managing your home.
                <br />
                <span className="text-haven-600">Start living in it.</span>
              </h1>

              {/* Subheadline */}
              <p className="mt-6 text-lg sm:text-xl text-warm-600 max-w-xl">
                One payment covers everything. One text handles anything. 
                From paying bills to fixing leaks—we've got it.
              </p>

              {/* Value props */}
              <div className="mt-6 flex flex-wrap justify-center lg:justify-start gap-4 text-sm">
                <span className="flex items-center gap-2 text-warm-700">
                  <CheckCircle2 className="w-5 h-5 text-green-500" />
                  8+ hours saved monthly
                </span>
                <span className="flex items-center gap-2 text-warm-700">
                  <CheckCircle2 className="w-5 h-5 text-green-500" />
                  No setup fees
                </span>
                <span className="flex items-center gap-2 text-warm-700">
                  <CheckCircle2 className="w-5 h-5 text-green-500" />
                  Cancel anytime
                </span>
              </div>

              {/* CTAs */}
              <div className="mt-8 flex flex-col sm:flex-row items-center justify-center lg:justify-start gap-4">
                <Link
                  href="/signup"
                  className="w-full sm:w-auto px-8 py-4 bg-haven-600 text-white font-semibold rounded-xl hover:bg-haven-700 transition-all hover:shadow-lg hover:shadow-haven-600/25 text-lg flex items-center justify-center gap-2"
                >
                  Get Started — $39/month
                  <ArrowRight className="w-5 h-5" />
                </Link>
                <a
                  href="#how-it-works"
                  className="w-full sm:w-auto px-8 py-4 border border-warm-300 text-warm-700 font-semibold rounded-xl hover:bg-warm-50 transition-colors text-lg flex items-center justify-center gap-2"
                >
                  <Play className="w-5 h-5" />
                  See How It Works
                </a>
              </div>

              {/* Trust elements */}
              <div className="mt-8 pt-8 border-t border-warm-200 flex flex-wrap items-center justify-center lg:justify-start gap-6">
                <div className="flex items-center gap-2 text-sm text-warm-500">
                  <Shield className="w-4 h-4" />
                  <span>FDIC Insured</span>
                </div>
                <div className="flex items-center gap-2 text-sm text-warm-500">
                  <BadgeCheck className="w-4 h-4" />
                  <span>SOC 2 Certified</span>
                </div>
                <div className="flex items-center gap-2 text-sm text-warm-500">
                  <Award className="w-4 h-4" />
                  <span>Vetted Pros Only</span>
                </div>
              </div>
            </div>

            {/* Right - Sarah Chat Interface */}
            <div className="relative lg:pl-8">
              <div className="relative bg-white rounded-2xl shadow-2xl border border-warm-200 overflow-hidden max-w-sm mx-auto lg:max-w-none">
                {/* Chat Header */}
                <div className="bg-haven-600 px-4 py-3 flex items-center gap-3">
                  <div className="relative">
                    <div className="w-10 h-10 rounded-full bg-white flex items-center justify-center text-haven-600 font-semibold">
                      SH
                    </div>
                    <div className="absolute -bottom-0.5 -right-0.5 w-3 h-3 bg-green-400 border-2 border-haven-600 rounded-full" />
                  </div>
                  <div>
                    <p className="font-semibold text-white">Sarah, Your Home Manager</p>
                    <p className="text-haven-200 text-sm">Active now</p>
                  </div>
                </div>

                {/* Chat Messages */}
                <div className="p-4 space-y-3 bg-warm-50">
                  <div className="bg-white rounded-xl p-3 shadow-sm border border-warm-100">
                    <div className="flex items-start gap-3">
                      <div className="w-8 h-8 rounded-full bg-green-100 flex items-center justify-center flex-shrink-0">
                        <Check className="w-4 h-4 text-green-600" />
                      </div>
                      <div>
                        <p className="font-medium text-warm-900">Furnace service completed</p>
                        <p className="text-sm text-warm-500">Filter changed, ready for winter</p>
                      </div>
                    </div>
                  </div>

                  <div className="bg-white rounded-xl p-3 shadow-sm border border-warm-100">
                    <div className="flex items-start gap-3">
                      <div className="w-8 h-8 rounded-full bg-haven-100 flex items-center justify-center flex-shrink-0">
                        <DollarSign className="w-4 h-4 text-haven-600" />
                      </div>
                      <div>
                        <p className="font-medium text-warm-900">December bills paid</p>
                        <p className="text-sm text-warm-500">Mortgage, utilities, lawn care. All set.</p>
                      </div>
                    </div>
                  </div>

                  <div className="bg-white rounded-xl p-3 shadow-sm border border-warm-100">
                    <div className="flex items-start gap-3">
                      <div className="w-8 h-8 rounded-full bg-blue-100 flex items-center justify-center flex-shrink-0">
                        <Calendar className="w-4 h-4 text-blue-600" />
                      </div>
                      <div>
                        <p className="font-medium text-warm-900">Gutter cleaning scheduled</p>
                        <p className="text-sm text-warm-500">Tuesday 10am. No action needed.</p>
                      </div>
                    </div>
                  </div>

                  <div className="bg-haven-50 rounded-xl p-3 border border-haven-200">
                    <p className="text-sm text-haven-700 flex items-center gap-2">
                      <CheckCircle2 className="w-4 h-4" />
                      No action needed from you. We've got it covered.
                    </p>
                  </div>
                </div>

                {/* Stats bar */}
                <div className="bg-white border-t border-warm-200 px-4 py-3 flex items-center justify-around">
                  <div className="text-center">
                    <p className="text-lg font-bold text-haven-600">12 bills</p>
                    <p className="text-xs text-warm-500">→ 1 payment</p>
                  </div>
                  <div className="w-px h-8 bg-warm-200" />
                  <div className="text-center">
                    <p className="text-lg font-bold text-haven-600">8+ hrs</p>
                    <p className="text-xs text-warm-500">saved monthly</p>
                  </div>
                </div>
              </div>

              {/* Floating badge */}
              <div className="absolute -bottom-4 -left-4 bg-white rounded-xl shadow-lg border border-warm-200 p-3 hidden lg:block">
                <div className="flex items-center gap-2">
                  <div className="w-10 h-10 rounded-full bg-green-100 flex items-center justify-center">
                    <Check className="w-5 h-5 text-green-600" />
                  </div>
                  <div>
                    <p className="text-sm font-semibold text-warm-900">$400 saved</p>
                    <p className="text-xs text-warm-500">Caught overcharge</p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ================================================================== */}
      {/* PAIN POINT SECTION */}
      {/* ================================================================== */}
      <section className="py-16 sm:py-20 bg-warm-50">
        <div className="max-w-6xl mx-auto px-4 sm:px-6">
          <div className="text-center mb-12">
            <h2 className="text-3xl sm:text-4xl font-bold text-warm-900">
              Owning a home shouldn't feel like a second job.
            </h2>
            <p className="mt-4 text-lg text-warm-600 max-w-2xl mx-auto">
              You're juggling a career, family, and life. The last thing you need is to be the unpaid project manager of your own home.
            </p>
          </div>

          <div className="grid md:grid-cols-2 gap-6 max-w-4xl mx-auto">
            {/* Without Haven */}
            <div className="bg-white rounded-2xl p-6 border border-warm-200">
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
                  <li key={idx} className="flex items-start gap-3 text-warm-600">
                    <X className="w-5 h-5 text-red-400 flex-shrink-0 mt-0.5" />
                    <span>{item}</span>
                  </li>
                ))}
              </ul>
            </div>

            {/* With Haven */}
            <div className="bg-haven-600 rounded-2xl p-6 text-white">
              <div className="flex items-center gap-2 mb-4">
                <CheckCircle2 className="w-6 h-6 text-haven-200" />
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
                    <Check className="w-5 h-5 text-haven-200 flex-shrink-0 mt-0.5" />
                    <span>{item}</span>
                  </li>
                ))}
              </ul>
            </div>
          </div>

          <p className="text-center mt-8 text-lg font-semibold text-haven-600">
            8+ hours per month. That's what our members get back.
          </p>
        </div>
      </section>

      {/* ================================================================== */}
      {/* HOW IT WORKS */}
      {/* ================================================================== */}
      <section id="how-it-works" className="py-16 sm:py-24 bg-white">
        <div className="max-w-6xl mx-auto px-4 sm:px-6">
          <div className="text-center mb-12">
            <p className="text-sm font-semibold text-haven-600 uppercase tracking-wide mb-2">Simple Setup</p>
            <h2 className="text-3xl sm:text-4xl font-bold text-warm-900">
              From Chaos to Calm in 3 Steps
            </h2>
            <p className="mt-4 text-lg text-warm-600">
              Get started in minutes. We handle everything from there.
            </p>
          </div>

          <div className="grid md:grid-cols-3 gap-8">
            {[
              {
                step: '1',
                title: 'Tell Us About Your Home',
                description: 'Share your vendors, bills, and preferences. We set up auto-pay and take over the relationships.',
                icon: Home,
              },
              {
                step: '2',
                title: 'Fund Your Haven Wallet',
                description: 'One monthly payment covers everything. We pay your mortgage, utilities, and every vendor. FDIC-insured.',
                icon: CreditCard,
              },
              {
                step: '3',
                title: 'Text Your Manager',
                description: 'Something need fixing? Question about your home? Text once. Your dedicated manager handles everything.',
                icon: MessageCircle,
              },
            ].map((item, idx) => (
              <div key={idx} className="relative">
                {idx < 2 && (
                  <div className="hidden md:block absolute top-12 left-[60%] w-[80%] h-px bg-warm-200" />
                )}
                <div className="text-center">
                  <div className="relative inline-flex mb-4">
                    <div className="w-24 h-24 rounded-2xl bg-haven-100 flex items-center justify-center">
                      <item.icon className="w-10 h-10 text-haven-600" />
                    </div>
                    <span className="absolute -top-2 -right-2 w-8 h-8 bg-haven-600 text-white rounded-full flex items-center justify-center font-bold text-sm">
                      {item.step}
                    </span>
                  </div>
                  <h3 className="text-xl font-semibold text-warm-900 mb-2">{item.title}</h3>
                  <p className="text-warm-600">{item.description}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ================================================================== */}
      {/* SERVICES SECTION */}
      {/* ================================================================== */}
      <section className="py-16 sm:py-24 bg-warm-50">
        <div className="max-w-6xl mx-auto px-4 sm:px-6">
          <div className="text-center mb-12">
            <h2 className="text-3xl sm:text-4xl font-bold text-warm-900">
              Everything Your Home Needs. Handled.
            </h2>
            <p className="mt-4 text-lg text-warm-600">
              From paying your mortgage to changing your furnace filter, we've got it.
            </p>
          </div>

          <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-6">
            {[
              {
                title: 'Bill Management',
                icon: Receipt,
                color: 'bg-green-100 text-green-600',
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
                color: 'bg-blue-100 text-blue-600',
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
                color: 'bg-purple-100 text-purple-600',
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
                color: 'bg-amber-100 text-amber-600',
                badge: 'Haven+',
                items: [
                  'Errand running & pickups',
                  'Package handling & returns',
                  'Travel coordination',
                  'Event planning',
                ],
              },
            ].map((service, idx) => (
              <div key={idx} className="bg-white rounded-2xl p-6 border border-warm-200 hover:shadow-lg transition-shadow">
                <div className={`w-12 h-12 rounded-xl ${service.color} flex items-center justify-center mb-4`}>
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
            ))}
          </div>
        </div>
      </section>

      {/* ================================================================== */}
      {/* HANDYMAN SECTION */}
      {/* ================================================================== */}
      <section className="py-16 sm:py-24 bg-haven-600 text-white">
        <div className="max-w-6xl mx-auto px-4 sm:px-6">
          <div className="grid lg:grid-cols-2 gap-12 items-center">
            <div>
              <p className="text-haven-200 font-semibold mb-2">The Haven Difference</p>
              <h2 className="text-3xl sm:text-4xl font-bold mb-4">
                Your Own Dedicated Handyman
              </h2>
              <p className="text-haven-100 text-lg mb-6">
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
                    <CheckCircle2 className="w-5 h-5 text-haven-200" />
                    <span className="text-haven-100">{item}</span>
                  </div>
                ))}
              </div>
            </div>

            <div className="bg-white rounded-2xl p-6 text-warm-900">
              <div className="flex items-center gap-4 mb-4">
                <div className="w-16 h-16 rounded-full bg-haven-100 flex items-center justify-center text-haven-600 font-bold text-xl">
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
          </div>
        </div>
      </section>

      {/* ================================================================== */}
      {/* PRICING SECTION */}
      {/* ================================================================== */}
      <section id="pricing" className="py-16 sm:py-24 bg-white">
        <div className="max-w-6xl mx-auto px-4 sm:px-6">
          <div className="text-center mb-12">
            <p className="text-sm font-semibold text-haven-600 uppercase tracking-wide mb-2">Transparent Pricing</p>
            <h2 className="text-3xl sm:text-4xl font-bold text-warm-900">
              Choose Your Level of Support
            </h2>
            <p className="mt-4 text-lg text-warm-600 max-w-2xl mx-auto">
              Start with Essentials and upgrade anytime. All plans include unlimited bill consolidation.
            </p>
          </div>

          {/* 3 Main Pricing Cards */}
          <div className="grid md:grid-cols-3 gap-6 max-w-5xl mx-auto">
            
            {/* ESSENTIALS - $39 */}
            <div className="bg-white rounded-2xl border border-warm-200 overflow-hidden flex flex-col hover:border-warm-300 hover:shadow-lg transition-all">
              <div className="p-6 flex-1">
                <h3 className="text-lg font-semibold text-warm-900">Haven Essentials</h3>
                <p className="text-sm text-warm-500 mt-1">Self-service home management</p>
                <div className="mt-4">
                  <span className="text-4xl font-bold text-warm-900">$39</span>
                  <span className="text-warm-500">/month</span>
                </div>

                <ul className="mt-6 space-y-3">
                  {[
                    'Bill consolidation (unlimited)',
                    'Home profile & systems tracking',
                    'Maintenance reminders',
                    'Vendor directory',
                    'Document storage',
                    'Money dashboard',
                    'Handyman visits ($99 each)',
                  ].map((feature, idx) => (
                    <li key={idx} className="flex items-start gap-3">
                      <Check className="w-5 h-5 text-haven-500 flex-shrink-0 mt-0.5" />
                      <span className="text-sm text-warm-700">{feature}</span>
                    </li>
                  ))}
                </ul>

                <p className="mt-4 pt-4 border-t border-warm-100 text-xs text-warm-500 text-center">
                  Perfect for DIY homeowners who want organization
                </p>
              </div>
              <div className="p-6 pt-0">
                <Link
                  href="/signup?plan=essentials"
                  className="block w-full py-3 text-center bg-warm-100 text-warm-700 font-semibold rounded-xl hover:bg-warm-200 transition-colors"
                >
                  Get Started
                </Link>
              </div>
            </div>

            {/* LITE - $349 (Most Popular) */}
            <div className="relative pt-4">
              {/* Most Popular Badge - positioned outside the card */}
              <div className="absolute -top-0 left-1/2 -translate-x-1/2 z-10">
                <span className="px-4 py-1.5 bg-haven-600 text-white text-sm font-semibold rounded-full shadow-md">
                  Most Popular
                </span>
              </div>
              <div className="bg-white rounded-2xl border-2 border-haven-500 overflow-hidden flex flex-col shadow-lg shadow-haven-100">
              <div className="p-6 pt-4 flex-1">
                <h3 className="text-lg font-semibold text-warm-900">Haven Lite</h3>
                <p className="text-sm text-warm-500 mt-1">Light-touch manager support</p>
                <div className="mt-4">
                  <span className="text-4xl font-bold text-warm-900">$349</span>
                  <span className="text-warm-500">/month</span>
                </div>

                <ul className="mt-6 space-y-3">
                  {[
                    'Your complete home profile',
                    'Bill consolidation (unlimited)',
                    'Vendor coordination (reactive)',
                    'Text-based home manager',
                    'Document vault & home manual',
                    'Same-day response time',
                  ].map((feature, idx) => (
                    <li key={idx} className="flex items-start gap-3">
                      <Check className="w-5 h-5 text-haven-500 flex-shrink-0 mt-0.5" />
                      <span className="text-sm text-warm-700">{feature}</span>
                    </li>
                  ))}
                </ul>

                <p className="mt-4 pt-4 border-t border-warm-100 text-xs text-warm-500 text-center">
                  For busy professionals who want backup support
                </p>
              </div>
              <div className="p-6 pt-0">
                <Link
                  href="/signup?plan=lite"
                  className="block w-full py-3 text-center bg-haven-600 text-white font-semibold rounded-xl hover:bg-haven-700 transition-colors"
                >
                  Get Started
                </Link>
              </div>
              </div>
            </div>

            {/* HAVEN - $749 */}
            <div className="bg-white rounded-2xl border border-warm-200 overflow-hidden flex flex-col hover:border-warm-300 hover:shadow-lg transition-all">
              <div className="p-6 flex-1">
                <h3 className="text-lg font-semibold text-warm-900">Haven</h3>
                <p className="text-sm text-warm-500 mt-1">Your dedicated home manager</p>
                <div className="mt-4">
                  <span className="text-4xl font-bold text-warm-900">$749</span>
                  <span className="text-warm-500">/month</span>
                </div>

                <ul className="mt-6 space-y-3">
                  {[
                    'Everything in Lite',
                    'Proactive home manager',
                    'Monthly handyman visit (2 hrs)',
                    'Vendor oversight & negotiation',
                    'Maintenance scheduling',
                    '12-hour response time',
                  ].map((feature, idx) => (
                    <li key={idx} className="flex items-start gap-3">
                      <Check className="w-5 h-5 text-haven-500 flex-shrink-0 mt-0.5" />
                      <span className="text-sm text-warm-700">{feature}</span>
                    </li>
                  ))}
                </ul>

                <p className="mt-4 pt-4 border-t border-warm-100 text-xs text-warm-500 text-center">
                  For those who want their home truly managed
                </p>
              </div>
              <div className="p-6 pt-0">
                <Link
                  href="/signup?plan=haven"
                  className="block w-full py-3 text-center bg-warm-100 text-warm-700 font-semibold rounded-xl hover:bg-warm-200 transition-colors"
                >
                  Get Started
                </Link>
              </div>
            </div>
          </div>

          {/* Premium Tiers - Collapsible */}
          <div className="mt-8 max-w-5xl mx-auto">
            <button
              onClick={() => setShowPremiumTiers(!showPremiumTiers)}
              className="w-full py-4 px-6 bg-warm-50 rounded-xl border border-warm-200 flex items-center justify-between hover:bg-warm-100 transition-colors"
            >
              <span className="flex items-center gap-2 text-warm-700 font-medium">
                <Crown className="w-5 h-5 text-amber-500" />
                Need more? See Haven+ and Estate options
              </span>
              {showPremiumTiers ? (
                <ChevronUp className="w-5 h-5 text-warm-400" />
              ) : (
                <ChevronDown className="w-5 h-5 text-warm-400" />
              )}
            </button>

            {showPremiumTiers && (
              <div className="mt-4 grid md:grid-cols-2 gap-6">
                {/* Haven+ */}
                <div className="bg-white rounded-xl border border-warm-200 p-6">
                  <div className="flex items-center gap-3 mb-4">
                    <div className="w-10 h-10 rounded-lg bg-purple-100 flex items-center justify-center">
                      <Star className="w-5 h-5 text-purple-600" />
                    </div>
                    <div>
                      <h4 className="font-semibold text-warm-900">Haven+</h4>
                      <p className="text-sm text-warm-500">Personal assistant + enhanced services</p>
                    </div>
                    <div className="ml-auto text-right">
                      <span className="text-2xl font-bold text-warm-900">$1,499</span>
                      <span className="text-warm-500">/mo</span>
                    </div>
                  </div>
                  <ul className="space-y-2 mb-4">
                    {[
                      'Everything in Haven',
                      'Personal assistant services',
                      'Errands, shopping & returns',
                      'Travel coordination',
                      'Event planning',
                      '4-hour priority response',
                      'Enhanced handyman (4 hrs/mo)',
                    ].map((feature, idx) => (
                      <li key={idx} className="flex items-center gap-2 text-sm text-warm-600">
                        <Check className="w-4 h-4 text-purple-500" />
                        {feature}
                      </li>
                    ))}
                  </ul>
                  <Link
                    href="/signup?plan=plus"
                    className="block w-full py-2.5 text-center bg-purple-100 text-purple-700 font-medium rounded-lg hover:bg-purple-200 transition-colors"
                  >
                    Upgrade to Haven+
                  </Link>
                </div>

                {/* Haven Estate */}
                <div className="bg-warm-900 rounded-xl p-6 text-white">
                  <div className="flex items-center gap-3 mb-4">
                    <div className="w-10 h-10 rounded-lg bg-amber-500 flex items-center justify-center">
                      <Crown className="w-5 h-5 text-white" />
                    </div>
                    <div>
                      <h4 className="font-semibold">Haven Estate</h4>
                      <p className="text-sm text-warm-400">White-glove estate management</p>
                    </div>
                    <div className="ml-auto text-right">
                      <span className="text-2xl font-bold">$3,499</span>
                      <span className="text-warm-400">/mo</span>
                    </div>
                  </div>
                  <p className="text-sm text-warm-300 mb-4">
                    Your personal estate manager anticipating needs, coordinating staff, and ensuring every detail of your properties is handled with discretion and excellence.
                  </p>
                  <ul className="space-y-2 mb-4">
                    {[
                      'Multiple properties supported',
                      'Priority 24/7 concierge access',
                      'Custom service agreements',
                    ].map((feature, idx) => (
                      <li key={idx} className="flex items-center gap-2 text-sm text-warm-300">
                        <Check className="w-4 h-4 text-amber-500" />
                        {feature}
                      </li>
                    ))}
                  </ul>
                  <Link
                    href="/contact?plan=estate"
                    className="block w-full py-2.5 text-center bg-amber-500 text-warm-900 font-medium rounded-lg hover:bg-amber-400 transition-colors"
                  >
                    Contact Sales
                  </Link>
                </div>
              </div>
            )}
          </div>

          {/* How Your Bill Works */}
          <div className="mt-12 max-w-3xl mx-auto">
            <div className="bg-warm-50 rounded-2xl p-6 sm:p-8">
              <h3 className="text-lg font-semibold text-warm-900 text-center mb-6">How Your Bill Works</h3>
              <div className="flex flex-col sm:flex-row items-center justify-center gap-4 sm:gap-8">
                <div className="text-center">
                  <div className="w-16 h-16 rounded-full bg-haven-100 flex items-center justify-center mx-auto mb-2">
                    <Sparkles className="w-7 h-7 text-haven-600" />
                  </div>
                  <p className="font-semibold text-warm-900">Haven Membership</p>
                  <p className="text-haven-600 font-bold">$39–$3,499</p>
                  <p className="text-xs text-warm-500">Your manager, platform & more</p>
                </div>
                <div className="text-3xl text-warm-300">+</div>
                <div className="text-center">
                  <div className="w-16 h-16 rounded-full bg-green-100 flex items-center justify-center mx-auto mb-2">
                    <Banknote className="w-7 h-7 text-green-600" />
                  </div>
                  <p className="font-semibold text-warm-900">Your Household Bills</p>
                  <p className="text-green-600 font-bold">At Cost</p>
                  <p className="text-xs text-warm-500">Zero markup on pass-through</p>
                </div>
              </div>
              <p className="mt-6 text-center text-sm text-warm-600 bg-white rounded-lg p-3">
                <strong>Example:</strong> $3,200 in monthly bills + $39 Essentials = <strong>$3,239 total</strong>. 
                One payment to Haven. We pay everyone else.
              </p>
            </div>
          </div>

          {/* Trust line */}
          <p className="mt-8 text-center text-sm text-warm-500">
            All plans include unlimited bill consolidation • No setup fees • Cancel anytime • 30-day money-back guarantee
          </p>
        </div>
      </section>

      {/* ================================================================== */}
      {/* COMPARE PLANS TABLE */}
      {/* ================================================================== */}
      <section className="py-16 sm:py-24 bg-warm-50">
        <div className="max-w-5xl mx-auto px-4 sm:px-6">
          <h2 className="text-2xl sm:text-3xl font-bold text-center text-warm-900 mb-8">
            Compare Plans
          </h2>

          {/* Desktop Table */}
          <div className="hidden lg:block bg-white rounded-2xl border border-warm-200 overflow-hidden">
            <table className="w-full">
              <thead>
                <tr className="border-b border-warm-200">
                  <th className="text-left py-4 px-6 font-semibold text-warm-600 w-1/4">Feature</th>
                  <th className="text-center py-4 px-4">
                    <div className="font-semibold text-warm-900">Essentials</div>
                    <div className="text-haven-600 font-bold">$39/mo</div>
                  </th>
                  <th className="text-center py-4 px-4 bg-haven-50">
                    <div className="font-semibold text-haven-700">Lite</div>
                    <div className="text-haven-600 font-bold">$349/mo</div>
                  </th>
                  <th className="text-center py-4 px-4">
                    <div className="font-semibold text-warm-900">Haven</div>
                    <div className="text-haven-600 font-bold">$749/mo</div>
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-warm-100">
                {[
                  { feature: 'Bill Consolidation', essentials: 'Unlimited', lite: 'Unlimited', haven: 'Unlimited' },
                  { feature: 'Home Profile & Systems', essentials: true, lite: true, haven: true },
                  { feature: 'Maintenance Reminders', essentials: true, lite: true, haven: true },
                  { feature: 'Vendor Directory', essentials: true, lite: true, haven: true },
                  { feature: 'Document Storage', essentials: true, lite: 'Vault + Manual', haven: 'Vault + Manual' },
                  { feature: 'Home Manager', essentials: false, lite: 'Text-based', haven: 'Proactive' },
                  { feature: 'Vendor Coordination', essentials: false, lite: 'Reactive', haven: 'Full oversight' },
                  { feature: 'Response Time', essentials: 'Self-service', lite: 'Same-day', haven: '12 hours' },
                  { feature: 'Handyman Visits', essentials: '$99/visit', lite: 'Add-on', haven: '2 hrs/month' },
                  { feature: 'Vendor Negotiation', essentials: false, lite: false, haven: true },
                ].map((row, idx) => (
                  <tr key={idx}>
                    <td className="py-4 px-6 text-warm-700 font-medium">{row.feature}</td>
                    <td className="py-4 px-4 text-center">
                      {row.essentials === true ? (
                        <Check className="w-5 h-5 text-green-500 mx-auto" />
                      ) : row.essentials === false ? (
                        <X className="w-5 h-5 text-warm-300 mx-auto" />
                      ) : (
                        <span className="text-sm text-warm-600">{row.essentials}</span>
                      )}
                    </td>
                    <td className="py-4 px-4 text-center bg-haven-50">
                      {row.lite === true ? (
                        <Check className="w-5 h-5 text-haven-600 mx-auto" />
                      ) : row.lite === false ? (
                        <X className="w-5 h-5 text-warm-300 mx-auto" />
                      ) : (
                        <span className="text-sm font-medium text-haven-700">{row.lite}</span>
                      )}
                    </td>
                    <td className="py-4 px-4 text-center">
                      {row.haven === true ? (
                        <Check className="w-5 h-5 text-green-500 mx-auto" />
                      ) : row.haven === false ? (
                        <X className="w-5 h-5 text-warm-300 mx-auto" />
                      ) : (
                        <span className="text-sm text-warm-600">{row.haven}</span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Mobile Cards */}
          <div className="lg:hidden space-y-3">
            {[
              { feature: 'Bill Consolidation', essentials: 'Unlimited', lite: 'Unlimited', haven: 'Unlimited' },
              { feature: 'Home Manager', essentials: '—', lite: 'Text-based', haven: 'Proactive', highlight: true },
              { feature: 'Response Time', essentials: 'Self-service', lite: 'Same-day', haven: '12 hours' },
              { feature: 'Handyman Visits', essentials: '$99/visit', lite: 'Add-on', haven: '2 hrs included', highlight: true },
              { feature: 'Vendor Coordination', essentials: '—', lite: 'Reactive', haven: 'Full oversight' },
            ].map((row, idx) => (
              <div key={idx} className={`bg-white rounded-xl border overflow-hidden ${row.highlight ? 'border-haven-300' : 'border-warm-200'}`}>
                <div className="bg-warm-100 px-4 py-2">
                  <span className="font-medium text-warm-700 text-sm">{row.feature}</span>
                </div>
                <div className="grid grid-cols-3 divide-x divide-warm-100">
                  <div className="p-3 text-center">
                    <div className="text-xs text-warm-400 mb-1">$39</div>
                    <div className="text-sm text-warm-600">{row.essentials}</div>
                  </div>
                  <div className="p-3 text-center bg-haven-50/50">
                    <div className="text-xs text-haven-600 mb-1">$349</div>
                    <div className="text-sm font-medium text-haven-700">{row.lite}</div>
                  </div>
                  <div className="p-3 text-center">
                    <div className="text-xs text-warm-400 mb-1">$749</div>
                    <div className="text-sm text-warm-600">{row.haven}</div>
                  </div>
                </div>
              </div>
            ))}
          </div>

          <div className="mt-8 text-center">
            <Link
              href="/signup"
              className="inline-flex items-center gap-2 px-8 py-3 bg-haven-600 text-white font-semibold rounded-xl hover:bg-haven-700 transition-colors"
            >
              Start for $39/month
              <ArrowRight className="w-5 h-5" />
            </Link>
          </div>
        </div>
      </section>

      {/* ================================================================== */}
      {/* SOFTWARE VS SERVICE */}
      {/* ================================================================== */}
      <section className="py-16 sm:py-24 bg-white">
        <div className="max-w-5xl mx-auto px-4 sm:px-6">
          <div className="text-center mb-12">
            <p className="text-sm font-semibold text-haven-600 uppercase tracking-wide mb-2">The Real Difference</p>
            <h2 className="text-3xl sm:text-4xl font-bold text-warm-900">
              Software vs. Service
            </h2>
            <p className="mt-4 text-lg text-warm-600 max-w-2xl mx-auto">
              Other companies give you software to organize your home management chaos.
              <br />
              <strong>That's like giving a drowning person a waterproof notebook.</strong>
            </p>
          </div>

          <div className="bg-warm-50 rounded-2xl overflow-hidden">
            <div className="grid sm:grid-cols-3">
              <div className="p-4 sm:p-6 font-semibold text-warm-600 border-b sm:border-b-0 sm:border-r border-warm-200">
                FEATURE
              </div>
              <div className="p-4 sm:p-6 text-center border-b sm:border-b-0 sm:border-r border-warm-200">
                <p className="font-semibold text-warm-500">Household Software</p>
                <p className="text-sm text-warm-400">$375/mo + $3K setup</p>
              </div>
              <div className="p-4 sm:p-6 text-center bg-haven-50">
                <p className="font-semibold text-haven-700">Haven</p>
                <p className="text-sm text-haven-600">$349/mo, no setup fee</p>
              </div>
            </div>
            
            {[
              { feature: 'Monthly Cost', software: '$375/month', haven: '$349/month', havenBetter: true },
              { feature: 'Setup/Onboarding', software: '$3,000 - $5,000', haven: '$0', havenBetter: true },
              { feature: 'First Year Total', software: '$7,500+', haven: '$4,188', havenBetter: true },
              { feature: 'Contract Required', software: '12-month prepaid', haven: 'Month-to-month', havenBetter: true },
              { feature: 'Bills Paid For You', software: 'No (you pay each vendor)', haven: 'Yes, one payment covers all', havenBetter: true },
              { feature: 'Vendor Coordination', software: 'No (just a contact list)', haven: 'Yes, we call, schedule, oversee', havenBetter: true },
              { feature: 'Handyman Visits', software: 'No', haven: 'Yes, monthly preventive visits', havenBetter: true },
              { feature: 'Humans Doing Work', software: 'No (software only)', haven: 'Yes, dedicated manager', havenBetter: true },
              { feature: 'When Something Breaks', software: 'You figure it out', haven: 'Text us. We fix it.', havenBetter: true },
            ].map((row, idx) => (
              <div key={idx} className="grid sm:grid-cols-3 border-t border-warm-200">
                <div className="p-4 sm:p-5 text-warm-700 font-medium border-b sm:border-b-0 sm:border-r border-warm-200">
                  {row.feature}
                </div>
                <div className="p-4 sm:p-5 text-center text-warm-500 border-b sm:border-b-0 sm:border-r border-warm-200 flex items-center justify-center gap-2">
                  <XCircle className="w-4 h-4 text-red-400 hidden sm:block" />
                  <span className="text-sm">{row.software}</span>
                </div>
                <div className="p-4 sm:p-5 text-center bg-haven-50 flex items-center justify-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-green-500 hidden sm:block" />
                  <span className="text-sm font-medium text-haven-700">{row.haven}</span>
                </div>
              </div>
            ))}
          </div>

          <div className="mt-8 bg-haven-600 rounded-2xl p-6 sm:p-8 text-center text-white">
            <p className="text-lg sm:text-xl font-semibold mb-4">
              Why pay more for software that makes YOU do the work?
            </p>
            <p className="text-haven-200 mb-6">
              Start with Haven Essentials for just $39/month — or get full service at $349/month with no setup fee.
            </p>
            <Link
              href="/signup"
              className="inline-flex items-center gap-2 px-8 py-3 bg-white text-haven-700 font-semibold rounded-xl hover:bg-haven-50 transition-colors"
            >
              Start for $39/month
              <ArrowRight className="w-5 h-5" />
            </Link>
          </div>
        </div>
      </section>

      {/* ================================================================== */}
      {/* TESTIMONIALS */}
      {/* ================================================================== */}
      <section className="py-16 sm:py-24 bg-warm-50">
        <div className="max-w-6xl mx-auto px-4 sm:px-6">
          <div className="text-center mb-12">
            <h2 className="text-3xl sm:text-4xl font-bold text-warm-900">
              Real Homeowners. Real Results.
            </h2>
            <p className="mt-4 text-lg text-warm-600">
              Join hundreds of families who've reclaimed their time.
            </p>
          </div>

          <div className="grid md:grid-cols-3 gap-6">
            {[
              {
                quote: "I thought this kind of service was only for people with mansions. Turns out it's for anyone tired of being their own property manager. Best money I spend each month.",
                name: 'Marcus T.',
                title: 'Software Developer, 3BR Colonial',
                highlight: 'Worth every penny',
                avatar: 'MT',
              },
              {
                quote: "Last month Sarah caught an overcharge from our landscaper and saved us $400. The membership has literally paid for itself multiple times over.",
                name: 'Jennifer L.',
                title: 'Working Mom, Townhouse',
                highlight: 'Saved $400',
                avatar: 'JL',
              },
              {
                quote: "The monthly handyman visit is worth the membership alone. Mike caught a small leak that would've destroyed our basement. Can't imagine going back.",
                name: 'David S.',
                title: 'Small Business Owner, 4BR Home',
                highlight: 'Prevented major repair',
                avatar: 'DS',
              },
            ].map((testimonial, idx) => (
              <div key={idx} className="bg-white rounded-2xl p-6 border border-warm-200 flex flex-col">
                <div className="flex gap-1 mb-4">
                  {[...Array(5)].map((_, i) => (
                    <Star key={i} className="w-5 h-5 text-amber-400 fill-current" />
                  ))}
                </div>
                <blockquote className="text-warm-700 flex-1">"{testimonial.quote}"</blockquote>
                <div className="mt-6 pt-4 border-t border-warm-100 flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-full bg-haven-100 flex items-center justify-center text-haven-600 font-semibold text-sm">
                      {testimonial.avatar}
                    </div>
                    <div>
                      <p className="font-semibold text-warm-900">{testimonial.name}</p>
                      <p className="text-sm text-warm-500">{testimonial.title}</p>
                    </div>
                  </div>
                  <span className="px-2 py-1 bg-green-100 text-green-700 text-xs font-medium rounded-full">
                    {testimonial.highlight}
                  </span>
                </div>
              </div>
            ))}
          </div>

          {/* Stats */}
          <div className="mt-12 grid grid-cols-2 sm:grid-cols-4 gap-6">
            {[
              { value: '8+', label: 'Hours saved monthly' },
              { value: '500+', label: 'Families served' },
              { value: '4.9', label: 'Average rating' },
              { value: '$0', label: 'Hidden fees' },
            ].map((stat, idx) => (
              <div key={idx} className="text-center">
                <p className="text-3xl sm:text-4xl font-bold text-haven-600">{stat.value}</p>
                <p className="text-warm-500">{stat.label}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ================================================================== */}
      {/* FAQ */}
      {/* ================================================================== */}
      <section className="py-16 sm:py-24 bg-white">
        <div className="max-w-3xl mx-auto px-4 sm:px-6">
          <h2 className="text-3xl sm:text-4xl font-bold text-center text-warm-900 mb-8">
            Questions? We've Got Answers.
          </h2>

          <div className="space-y-3">
            {[
              {
                q: 'Is this only for rich people with big estates?',
                a: "Not at all. We built Haven because professional home management shouldn't require a trust fund. Our Essentials plan starts at just $39/month and works perfectly for condos and apartments. The value comes from saving you time and preventing expensive repairs. That's valuable for any homeowner.",
              },
              {
                q: 'How is Haven different from household management software?',
                a: "Software gives you tools to organize your own work. Haven gives you a person who does the work. When your furnace breaks at 10pm, software gives you a contact list. Haven? Text us and go back to bed—we'll handle it.",
              },
              {
                q: 'Why should I pay for this when I can manage things myself?',
                a: "You absolutely can. The question is: should you? Our members save 8+ hours monthly. If your time is worth $50/hour, that's $400 in value for a $349 membership—before counting the money we save on vendor negotiations and catching issues early.",
              },
              {
                q: 'Do I have to sign an annual contract?',
                a: "Never. All Haven memberships are month-to-month. No setup fees, no cancellation penalties. We earn your business every month.",
              },
              {
                q: 'How does the one-bill system work?',
                a: "You fund your Haven Wallet once monthly. We pay every bill on your behalf—mortgage, utilities, landscaper, pool guy, everyone. You see it all in your dashboard, but you never have to think about due dates or writing checks again.",
              },
              {
                q: 'Is my money safe?',
                a: "Yes. Your Haven Wallet is FDIC-insured up to $2 million through our banking partner. We're also SOC 2 certified, meaning your data and transactions meet the highest security standards.",
              },
            ].map((faq, idx) => (
              <div key={idx} className="border border-warm-200 rounded-xl overflow-hidden">
                <button
                  onClick={() => setOpenFaq(openFaq === idx ? null : idx)}
                  className="w-full px-6 py-4 text-left flex items-center justify-between hover:bg-warm-50 transition-colors"
                >
                  <span className="font-semibold text-warm-900">{faq.q}</span>
                  {openFaq === idx ? (
                    <ChevronUp className="w-5 h-5 text-warm-400 flex-shrink-0" />
                  ) : (
                    <ChevronDown className="w-5 h-5 text-warm-400 flex-shrink-0" />
                  )}
                </button>
                {openFaq === idx && (
                  <div className="px-6 pb-4 text-warm-600">
                    {faq.a}
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ================================================================== */}
      {/* FINAL CTA */}
      {/* ================================================================== */}
      <section className="py-16 sm:py-24 bg-haven-600">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 text-center">
          <h2 className="text-3xl sm:text-4xl font-bold text-white">
            Ready to simplify your home life?
          </h2>
          <p className="mt-4 text-lg text-haven-100">
            Start with bill consolidation for just $39/month. Upgrade anytime.
          </p>
          <p className="mt-2 text-haven-200">
            Join hundreds of families who've reclaimed their time and peace of mind.
          </p>
          <p className="mt-4 text-haven-100 font-medium">
            Not another app. Actual help when you need it.
          </p>
          <div className="mt-8 flex flex-col sm:flex-row items-center justify-center gap-4">
            <Link
              href="/signup"
              className="w-full sm:w-auto px-8 py-4 bg-white text-haven-700 font-semibold rounded-xl hover:bg-haven-50 transition-colors text-lg flex items-center justify-center gap-2"
            >
              Start for $39/month
              <ArrowRight className="w-5 h-5" />
            </Link>
            <a
              href="#pricing"
              className="w-full sm:w-auto px-8 py-4 border-2 border-white text-white font-semibold rounded-xl hover:bg-haven-500 transition-colors text-lg"
            >
              Compare All Plans
            </a>
          </div>
          <p className="mt-6 text-sm text-haven-200">
            No contracts. No setup fees. Cancel anytime. 30-day money-back guarantee.
          </p>
        </div>
      </section>

      {/* ================================================================== */}
      {/* FOOTER */}
      {/* ================================================================== */}
      <footer className="bg-warm-900 text-white py-12">
        <div className="max-w-6xl mx-auto px-4 sm:px-6">
          <div className="grid sm:grid-cols-2 lg:grid-cols-5 gap-8">
            <div className="lg:col-span-2">
              <h3 className="text-xl font-bold">Haven</h3>
              <p className="mt-2 text-warm-400 text-sm">
                Full-service home management for everyone. One bill. One contact. Zero hassle.
              </p>
              <div className="mt-4 flex items-center gap-4">
                <div className="flex items-center gap-1 text-xs text-warm-400">
                  <Shield className="w-4 h-4" />
                  FDIC-Insured
                </div>
                <div className="flex items-center gap-1 text-xs text-warm-400">
                  <BadgeCheck className="w-4 h-4" />
                  SOC 2
                </div>
              </div>
            </div>
            <div>
              <h4 className="font-semibold mb-3">Product</h4>
              <ul className="space-y-2 text-sm text-warm-400">
                <li><a href="#how-it-works" className="hover:text-white">How It Works</a></li>
                <li><a href="#" className="hover:text-white">Services</a></li>
                <li><a href="#pricing" className="hover:text-white">Pricing</a></li>
                <li><a href="#" className="hover:text-white">Compare</a></li>
              </ul>
            </div>
            <div>
              <h4 className="font-semibold mb-3">Company</h4>
              <ul className="space-y-2 text-sm text-warm-400">
                <li><a href="#" className="hover:text-white">About</a></li>
                <li><a href="#" className="hover:text-white">Careers</a></li>
                <li><a href="#" className="hover:text-white">Contact</a></li>
                <li><a href="#" className="hover:text-white">Member Login</a></li>
              </ul>
            </div>
            <div>
              <h4 className="font-semibold mb-3">Partners</h4>
              <ul className="space-y-2 text-sm text-warm-400">
                <li><a href="#" className="hover:text-white">Vendor Portal</a></li>
                <li><a href="#" className="hover:text-white">Handyman Portal</a></li>
                <li><a href="#" className="hover:text-white">Become a Partner</a></li>
              </ul>
            </div>
          </div>
          <div className="mt-12 pt-8 border-t border-warm-800 flex flex-col sm:flex-row items-center justify-between gap-4">
            <p className="text-sm text-warm-400">© 2025 Haven. All rights reserved.</p>
            <div className="flex items-center gap-6 text-sm text-warm-400">
              <a href="#" className="hover:text-white">Privacy</a>
              <a href="#" className="hover:text-white">Terms</a>
              <a href="#" className="hover:text-white">Security</a>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}
```

---

# KEY CHANGES SUMMARY

## Hero Section
- **New Headline:** "Stop managing your home. Start living in it."
- **Subheadline:** "One payment covers everything. One text handles anything."
- **CTA:** "Get Started — $39/month" (price in button, not headline)
- Kept the Sarah chat mockup (it's brilliant)

## Pricing Section
- **3 visible cards:** Essentials ($39), Lite ($349), Haven ($749)
- **Haven+ and Estate HIDDEN** behind "Need more? See Haven+ and Estate options" dropdown
- Lite marked as "Most Popular"

## Other Improvements
- Tightened copy throughout
- Better visual hierarchy
- Cleaner comparison table
- FAQ section with accordion
- Stronger final CTA

## Run in Claude Code:

```
Read and apply HAVEN_PRICING_FIX.md

Key changes:
1. New hero: "Stop managing your home. Start living in it."
2. CTA buttons say "Get Started — $39/month" 
3. Pricing shows 3 cards: Essentials ($39), Lite ($349), Haven ($749)
4. Haven+ ($1,499) and Estate ($3,499) are HIDDEN in a dropdown
5. "Lite" is marked as "Most Popular"
6. All sections from the PDF are preserved but tightened
```
