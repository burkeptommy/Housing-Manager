'use client';

import { useState } from 'react';
import Link from 'next/link';
import { Navbar } from '@/components/marketing/Navbar';
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
      <Navbar />

      {/* ================================================================== */}
      {/* HERO SECTION */}
      {/* ================================================================== */}
      <section className="relative overflow-hidden bg-gradient-to-br from-haven-700 via-haven-800 to-haven-900 pt-24 sm:pt-32 pb-16 sm:pb-24">
        {/* Background decoration */}
        <div className="absolute inset-0 overflow-hidden pointer-events-none">
          <div className="absolute -top-40 -right-40 w-96 h-96 bg-haven-700 rounded-full blur-3xl opacity-20" />
          <div className="absolute top-1/2 -left-20 w-72 h-72 bg-champagne-300/20 rounded-full blur-3xl opacity-30" />
          <div className="absolute bottom-0 right-1/4 w-64 h-64 bg-haven-700 rounded-full blur-3xl opacity-15" />
        </div>

        <div className="relative max-w-6xl mx-auto px-4 sm:px-6">
          <div className="grid lg:grid-cols-2 gap-12 items-center">
            {/* Left - Copy */}
            <div className="text-center lg:text-left">
              {/* Trust badge */}
              <div className="inline-flex items-center gap-2 px-3 py-1.5 bg-white/10 backdrop-blur border border-white/20 rounded-full mb-6">
                <span className="flex items-center gap-1">
                  <Star className="w-4 h-4 text-champagne-300 fill-current" />
                  <span className="text-sm font-medium text-white">4.9/5</span>
                </span>
                <span className="text-white/40">|</span>
                <span className="text-sm text-white/80">500+ families served</span>
              </div>

              {/* Main Headline */}
              <h1 className="text-4xl sm:text-5xl lg:text-6xl font-bold text-white tracking-tight leading-[1.1]">
                Stop managing your home.
                <br />
                <span className="text-champagne-300">Start living in it.</span>
              </h1>

              {/* Subheadline */}
              <p className="mt-6 text-lg sm:text-xl text-haven-100 max-w-xl">
                One payment covers everything. One text handles anything.
                From paying bills to fixing leaks, we've got it.
              </p>

              {/* Value props */}
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

              {/* CTAs */}
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

              {/* Trust elements */}
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
            </div>

            {/* Right - Sarah Chat Interface */}
            <div className="relative lg:pl-8">
              <div className="relative bg-white rounded-2xl shadow-2xl border border-warm-200 overflow-hidden max-w-sm mx-auto lg:max-w-none">
                {/* Chat Header */}
                <div className="bg-gradient-to-r from-haven-700 to-haven-700 px-4 py-3 flex items-center gap-3">
                  <div className="relative">
                    <div className="w-10 h-10 rounded-full bg-white flex items-center justify-center text-haven-700 font-semibold">
                      SH
                    </div>
                    <div className="absolute -bottom-0.5 -right-0.5 w-3 h-3 bg-green-400 border-2 border-haven-700 rounded-full" />
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
                        <Check className="w-4 h-4 text-haven-700" />
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
                        <DollarSign className="w-4 h-4 text-haven-700" />
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
                    <p className="text-lg font-bold text-haven-700">12 bills</p>
                    <p className="text-xs text-warm-500">→ 1 payment</p>
                  </div>
                  <div className="w-px h-8 bg-warm-200" />
                  <div className="text-center">
                    <p className="text-lg font-bold text-haven-700">8+ hrs</p>
                    <p className="text-xs text-warm-500">saved monthly</p>
                  </div>
                </div>
              </div>

              {/* Floating badge */}
              <div className="absolute -bottom-4 -left-4 bg-white rounded-xl shadow-lg border border-warm-200 p-3 hidden lg:block">
                <div className="flex items-center gap-2">
                  <div className="w-10 h-10 rounded-full bg-green-100 flex items-center justify-center">
                    <Check className="w-5 h-5 text-haven-700" />
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
      <section className="py-16 sm:py-20 bg-white">
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

            {/* With Haven */}
            <div className="bg-gradient-to-br from-haven-700 to-haven-800 rounded-2xl p-6 text-white">
              <div className="flex items-center gap-2 mb-4">
                <CheckCircle2 className="w-6 h-6 text-champagne-300" />
                <h3 className="text-lg font-semibold text-white">With Haven</h3>
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
          </div>

          <div className="mt-8 text-center">
            <div className="inline-flex items-center gap-3 px-6 py-3 bg-champagne-100 rounded-full">
              <Clock className="w-5 h-5 text-champagne-600" />
              <p className="text-lg font-semibold text-champagne-600">
                8+ hours per month. That's what our members get back.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* ================================================================== */}
      {/* HOW IT WORKS */}
      {/* ================================================================== */}
      <section id="how-it-works" className="py-16 sm:py-24 bg-gradient-to-b from-warm-100 to-warm-50">
        <div className="max-w-6xl mx-auto px-4 sm:px-6">
          <div className="text-center mb-12">
            <p className="text-sm font-semibold text-haven-700 uppercase tracking-wide mb-2">Simple Setup</p>
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
                color: 'bg-haven-100 text-haven-700',
              },
              {
                step: '2',
                title: 'Fund Your Haven Wallet',
                description: 'One monthly payment covers everything. We pay your mortgage, utilities, and every vendor. FDIC-insured.',
                icon: CreditCard,
                color: 'bg-champagne-200 text-champagne-600',
              },
              {
                step: '3',
                title: 'Text Your Manager',
                description: 'Something need fixing? Question about your home? Text once. Your dedicated manager handles everything.',
                icon: MessageCircle,
                color: 'bg-blue-100 text-blue-600',
              },
            ].map((item, idx) => (
              <div key={idx} className="relative">
                {idx < 2 && (
                  <div className="hidden md:block absolute top-12 left-[60%] w-[80%] h-0.5 bg-gradient-to-r from-warm-300 to-transparent" />
                )}
                <div className="text-center">
                  <div className="relative inline-flex mb-4">
                    <div className={`w-24 h-24 rounded-2xl ${item.color} flex items-center justify-center shadow-lg`}>
                      <item.icon className="w-10 h-10" />
                    </div>
                    <span className="absolute -top-2 -right-2 w-8 h-8 bg-haven-700 text-white rounded-full flex items-center justify-center font-bold text-sm shadow-md">
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
      <section id="services" className="py-16 sm:py-24 bg-white">
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
                color: 'bg-green-500',
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
                color: 'bg-blue-500',
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
                color: 'bg-purple-500',
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
                color: 'bg-champagne-400',
                iconBg: 'bg-champagne-100 text-champagne-600',
                badge: 'Haven+',
                items: [
                  'Errand running & pickups',
                  'Package handling & returns',
                  'Travel coordination',
                  'Event planning',
                ],
              },
            ].map((service, idx) => (
              <div key={idx} className="bg-white rounded-2xl border border-warm-200 overflow-hidden hover:shadow-xl transition-all hover:-translate-y-1">
                <div className={`h-2 ${service.color}`} />
                <div className="p-6">
                  <div className={`w-12 h-12 rounded-xl ${service.iconBg} flex items-center justify-center mb-4`}>
                    <service.icon className="w-6 h-6" />
                  </div>
                  <div className="flex items-center gap-2 mb-3">
                    <h3 className="text-lg font-semibold text-warm-900">{service.title}</h3>
                    {service.badge && (
                      <span className="px-2 py-0.5 bg-haven-100 text-haven-700 text-xs font-medium rounded-full">
                        {service.badge}
                      </span>
                    )}
                  </div>
                  <ul className="space-y-2">
                    {service.items.map((item, i) => (
                      <li key={i} className="flex items-start gap-2 text-sm text-warm-600">
                        <Check className="w-4 h-4 text-haven-700 flex-shrink-0 mt-0.5" />
                        <span>{item}</span>
                      </li>
                    ))}
                  </ul>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ================================================================== */}
      {/* HANDYMAN SECTION */}
      {/* ================================================================== */}
      <section className="py-16 sm:py-24 bg-gradient-to-br from-warm-900 via-warm-800 to-warm-900 text-white relative overflow-hidden">
        {/* Background decoration */}
        <div className="absolute inset-0 overflow-hidden pointer-events-none">
          <div className="absolute top-0 right-0 w-96 h-96 bg-champagne-300 rounded-full blur-3xl opacity-10" />
          <div className="absolute bottom-0 left-0 w-72 h-72 bg-haven-700 rounded-full blur-3xl opacity-10" />
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
                  <span className="font-medium text-haven-700">12 (saved $3,400+)</span>
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
            <p className="text-sm font-semibold text-haven-700 uppercase tracking-wide mb-2">Transparent Pricing</p>
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
            <div className="bg-white rounded-2xl border border-warm-200 overflow-hidden flex flex-col hover:border-haven-300 hover:shadow-lg transition-all">
              <div className="h-2 bg-warm-300" />
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
                      <Check className="w-5 h-5 text-haven-700 flex-shrink-0 mt-0.5" />
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
                  href="/register?plan=essentials"
                  className="block w-full py-3 text-center bg-warm-100 text-warm-700 font-semibold rounded-xl hover:bg-warm-200 transition-colors"
                >
                  Get Started
                </Link>
              </div>
            </div>

            {/* LITE - $349 (Most Popular) */}
            <div className="relative pt-4">
              {/* Most Popular Badge */}
              <div className="absolute -top-0 left-1/2 -translate-x-1/2 z-10">
                <span className="px-4 py-1.5 bg-gradient-to-r from-haven-700 to-haven-800 text-white text-sm font-semibold rounded-full shadow-lg">
                  Most Popular
                </span>
              </div>
              <div className="bg-white rounded-2xl border-2 border-haven-600 overflow-hidden flex flex-col shadow-xl shadow-haven-100">
                <div className="h-2 bg-gradient-to-r from-haven-700 to-haven-700" />
                <div className="p-6 pt-4 flex-1">
                  <h3 className="text-lg font-semibold text-haven-800">Haven Lite</h3>
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
                        <Check className="w-5 h-5 text-haven-700 flex-shrink-0 mt-0.5" />
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
                    href="/register?plan=lite"
                    className="block w-full py-3 text-center bg-haven-700 text-white font-semibold rounded-xl hover:bg-haven-800 transition-colors"
                  >
                    Get Started
                  </Link>
                </div>
              </div>
            </div>

            {/* HAVEN - $749 */}
            <div className="bg-white rounded-2xl border border-warm-200 overflow-hidden flex flex-col hover:border-haven-300 hover:shadow-lg transition-all">
              <div className="h-2 bg-champagne-400" />
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
                      <Check className="w-5 h-5 text-haven-700 flex-shrink-0 mt-0.5" />
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
                  href="/register?plan=haven"
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
              className="w-full py-4 px-6 bg-white rounded-xl border border-warm-200 flex items-center justify-between hover:bg-warm-50 hover:border-warm-300 transition-colors shadow-sm"
            >
              <span className="flex items-center gap-2 text-warm-700 font-medium">
                <Crown className="w-5 h-5 text-haven-700" />
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
                <div className="bg-white rounded-xl border border-purple-200 p-6 shadow-lg">
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
                    href="/register?plan=plus"
                    className="block w-full py-2.5 text-center bg-purple-100 text-purple-700 font-medium rounded-lg hover:bg-purple-200 transition-colors"
                  >
                    Upgrade to Haven+
                  </Link>
                </div>

                {/* Haven Estate */}
                <div className="bg-gradient-to-br from-warm-900 to-warm-800 rounded-xl p-6 text-white shadow-lg">
                  <div className="flex items-center gap-3 mb-4">
                    <div className="w-10 h-10 rounded-lg bg-haven-800 flex items-center justify-center">
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
                        <Check className="w-4 h-4 text-haven-400" />
                        {feature}
                      </li>
                    ))}
                  </ul>
                  <Link
                    href="/contact?plan=estate"
                    className="block w-full py-2.5 text-center bg-haven-700 text-white font-medium rounded-lg hover:bg-haven-800 transition-colors"
                  >
                    Contact Sales
                  </Link>
                </div>
              </div>
            )}
          </div>

          {/* How Your Bill Works */}
          <div className="mt-12 max-w-3xl mx-auto">
            <div className="bg-white rounded-2xl p-6 sm:p-8 border border-warm-200 shadow-lg">
              <h3 className="text-lg font-semibold text-warm-900 text-center mb-6">How Your Bill Works</h3>
              <div className="flex flex-col sm:flex-row items-center justify-center gap-4 sm:gap-8">
                <div className="text-center">
                  <div className="w-16 h-16 rounded-full bg-haven-100 flex items-center justify-center mx-auto mb-2">
                    <Sparkles className="w-7 h-7 text-haven-700" />
                  </div>
                  <p className="font-semibold text-warm-900">Haven Membership</p>
                  <p className="text-haven-700 font-bold">$39 to $3,499</p>
                  <p className="text-xs text-warm-500">Your manager, platform & more</p>
                </div>
                <div className="text-3xl text-warm-300 font-light">+</div>
                <div className="text-center">
                  <div className="w-16 h-16 rounded-full bg-green-100 flex items-center justify-center mx-auto mb-2">
                    <Banknote className="w-7 h-7 text-haven-700" />
                  </div>
                  <p className="font-semibold text-warm-900">Your Household Bills</p>
                  <p className="text-haven-700 font-bold">At Cost</p>
                  <p className="text-xs text-warm-500">Zero markup on pass-through</p>
                </div>
              </div>
              <div className="mt-6 p-4 bg-champagne-100 rounded-xl border border-champagne-200">
                <p className="text-center text-sm text-champagne-600">
                  <strong>Example:</strong> $3,200 in monthly bills + $39 Essentials = <strong>$3,239 total</strong>.
                  One payment to Haven. We pay everyone else.
                </p>
              </div>
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
      <section className="py-16 sm:py-24 bg-haven-900 text-white">
        <div className="max-w-5xl mx-auto px-4 sm:px-6">
          <h2 className="text-2xl sm:text-3xl font-bold text-center mb-8 text-white">
            Compare Plans
          </h2>

          {/* Desktop Table */}
          <div className="hidden lg:block bg-haven-800 rounded-2xl overflow-hidden">
            <table className="w-full">
              <thead>
                <tr className="border-b border-haven-700">
                  <th className="text-left py-4 px-6 font-semibold text-haven-400 w-1/4">Feature</th>
                  <th className="text-center py-4 px-4">
                    <div className="font-semibold text-warm-200">Essentials</div>
                    <div className="text-haven-400 font-bold">$39/mo</div>
                  </th>
                  <th className="text-center py-4 px-4 bg-haven-700/30">
                    <div className="font-semibold text-champagne-300">Lite</div>
                    <div className="text-haven-400 font-bold">$349/mo</div>
                  </th>
                  <th className="text-center py-4 px-4">
                    <div className="font-semibold text-warm-200">Haven</div>
                    <div className="text-haven-400 font-bold">$749/mo</div>
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-haven-700">
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
                    <td className="py-4 px-6 text-haven-300 font-medium">{row.feature}</td>
                    <td className="py-4 px-4 text-center">
                      {row.essentials === true ? (
                        <Check className="w-5 h-5 text-green-400 mx-auto" />
                      ) : row.essentials === false ? (
                        <X className="w-5 h-5 text-haven-600 mx-auto" />
                      ) : (
                        <span className="text-sm text-haven-400">{row.essentials}</span>
                      )}
                    </td>
                    <td className="py-4 px-4 text-center bg-haven-700/30">
                      {row.lite === true ? (
                        <Check className="w-5 h-5 text-champagne-300 mx-auto" />
                      ) : row.lite === false ? (
                        <X className="w-5 h-5 text-haven-600 mx-auto" />
                      ) : (
                        <span className="text-sm font-medium text-champagne-300">{row.lite}</span>
                      )}
                    </td>
                    <td className="py-4 px-4 text-center">
                      {row.haven === true ? (
                        <Check className="w-5 h-5 text-green-400 mx-auto" />
                      ) : row.haven === false ? (
                        <X className="w-5 h-5 text-haven-600 mx-auto" />
                      ) : (
                        <span className="text-sm text-haven-400">{row.haven}</span>
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
              { feature: 'Home Manager', essentials: 'None', lite: 'Text-based', haven: 'Proactive', highlight: true },
              { feature: 'Response Time', essentials: 'Self-service', lite: 'Same-day', haven: '12 hours' },
              { feature: 'Handyman Visits', essentials: '$99/visit', lite: 'Add-on', haven: '2 hrs included', highlight: true },
              { feature: 'Vendor Coordination', essentials: 'None', lite: 'Reactive', haven: 'Full oversight' },
            ].map((row, idx) => (
              <div key={idx} className={`bg-haven-800 rounded-xl border overflow-hidden ${row.highlight ? 'border-haven-600' : 'border-haven-700'}`}>
                <div className="bg-haven-700 px-4 py-2">
                  <span className="font-medium text-haven-200 text-sm">{row.feature}</span>
                </div>
                <div className="grid grid-cols-3 divide-x divide-haven-700">
                  <div className="p-3 text-center">
                    <div className="text-xs text-haven-500 mb-1">$39</div>
                    <div className="text-sm text-haven-300">{row.essentials}</div>
                  </div>
                  <div className="p-3 text-center bg-haven-700/30">
                    <div className="text-xs text-champagne-300 mb-1">$349</div>
                    <div className="text-sm font-medium text-champagne-300">{row.lite}</div>
                  </div>
                  <div className="p-3 text-center">
                    <div className="text-xs text-haven-500 mb-1">$749</div>
                    <div className="text-sm text-haven-300">{row.haven}</div>
                  </div>
                </div>
              </div>
            ))}
          </div>

          <div className="mt-8 text-center">
            <Link
              href="/register"
              className="inline-flex items-center gap-2 px-8 py-3 bg-white text-haven-700 font-semibold rounded-xl hover:bg-champagne-50 transition-colors"
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
            <p className="text-sm font-semibold text-haven-700 uppercase tracking-wide mb-2">The Real Difference</p>
            <h2 className="text-3xl sm:text-4xl font-bold text-warm-900">
              Software vs. Service
            </h2>
            <p className="mt-4 text-lg text-warm-600 max-w-2xl mx-auto">
              Other companies give you software to organize your home management chaos.
              <br />
              <strong>That's like giving a drowning person a waterproof notebook.</strong>
            </p>
          </div>

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
                <p className="font-semibold text-haven-800">Haven</p>
                <p className="text-sm text-haven-700">$349/mo, no setup fee</p>
              </div>
            </div>

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
              <div key={idx} className="grid sm:grid-cols-3 border-t border-warm-200">
                <div className="p-4 sm:p-5 text-warm-700 font-medium border-b sm:border-b-0 sm:border-r border-warm-200">
                  {row.feature}
                </div>
                <div className="p-4 sm:p-5 text-center border-b sm:border-b-0 sm:border-r border-warm-200 flex items-center justify-center gap-2 bg-red-50/50">
                  <XCircle className="w-4 h-4 text-red-400 hidden sm:block" />
                  <span className="text-sm text-red-700">{row.software}</span>
                </div>
                <div className="p-4 sm:p-5 text-center bg-haven-50 flex items-center justify-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-haven-700 hidden sm:block" />
                  <span className="text-sm font-medium text-haven-800">{row.haven}</span>
                </div>
              </div>
            ))}
          </div>

          <div className="mt-8 bg-gradient-to-r from-haven-700 to-haven-800 rounded-2xl p-6 sm:p-8 text-center text-white">
            <p className="text-lg sm:text-xl font-semibold mb-4">
              Why pay more for software that makes YOU do the work?
            </p>
            <p className="text-haven-200 mb-6">
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
        </div>
      </section>

      {/* ================================================================== */}
      {/* TESTIMONIALS */}
      {/* ================================================================== */}
      <section className="py-16 sm:py-24 bg-gradient-to-b from-champagne-50 to-champagne-100/50">
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
                color: 'bg-haven-100 text-haven-700',
                avatar: 'MT',
              },
              {
                quote: "Last month Sarah caught an overcharge from our landscaper and saved us $400. The membership has literally paid for itself multiple times over.",
                name: 'Jennifer L.',
                title: 'Working Mom, Townhouse',
                highlight: 'Saved $400',
                color: 'bg-green-100 text-green-700',
                avatar: 'JL',
              },
              {
                quote: "The monthly handyman visit is worth the membership alone. Mike caught a small leak that would've destroyed our basement. Can't imagine going back.",
                name: 'David S.',
                title: 'Small Business Owner, 4BR Home',
                highlight: 'Prevented major repair',
                color: 'bg-champagne-200 text-champagne-600',
                avatar: 'DS',
              },
            ].map((testimonial, idx) => (
              <div key={idx} className="bg-white rounded-2xl p-6 border border-warm-200 flex flex-col shadow-lg">
                <div className="flex gap-1 mb-4">
                  {[...Array(5)].map((_, i) => (
                    <Star key={i} className="w-5 h-5 text-amber-400 fill-current" />
                  ))}
                </div>
                <blockquote className="text-warm-700 flex-1">"{testimonial.quote}"</blockquote>
                <div className="mt-6 pt-4 border-t border-warm-100 flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-full bg-haven-700 flex items-center justify-center text-white font-semibold text-sm">
                      {testimonial.avatar}
                    </div>
                    <div>
                      <p className="font-semibold text-warm-900">{testimonial.name}</p>
                      <p className="text-sm text-warm-500">{testimonial.title}</p>
                    </div>
                  </div>
                  <span className={`px-2 py-1 ${testimonial.color} text-xs font-medium rounded-full`}>
                    {testimonial.highlight}
                  </span>
                </div>
              </div>
            ))}
          </div>

          {/* Stats */}
          <div className="mt-12 grid grid-cols-2 sm:grid-cols-4 gap-6">
            {[
              { value: '8+', label: 'Hours saved monthly', color: 'text-haven-700' },
              { value: '500+', label: 'Families served', color: 'text-champagne-500' },
              { value: '4.9', label: 'Average rating', color: 'text-haven-700' },
              { value: '$0', label: 'Hidden fees', color: 'text-haven-700' },
            ].map((stat, idx) => (
              <div key={idx} className="text-center bg-white rounded-xl p-4 shadow-md border border-warm-200">
                <p className={`text-3xl sm:text-4xl font-bold ${stat.color}`}>{stat.value}</p>
                <p className="text-warm-500">{stat.label}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ================================================================== */}
      {/* FAQ */}
      {/* ================================================================== */}
      <section id="faq" className="py-16 sm:py-24 bg-white">
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
            ].map((faq, idx) => (
              <div key={idx} className="border border-warm-200 rounded-xl overflow-hidden">
                <button
                  onClick={() => setOpenFaq(openFaq === idx ? null : idx)}
                  className="w-full px-6 py-4 text-left flex items-center justify-between hover:bg-warm-50 transition-colors"
                >
                  <span className="font-semibold text-warm-900">{faq.q}</span>
                  {openFaq === idx ? (
                    <ChevronUp className="w-5 h-5 text-haven-700 flex-shrink-0" />
                  ) : (
                    <ChevronDown className="w-5 h-5 text-warm-400 flex-shrink-0" />
                  )}
                </button>
                {openFaq === idx && (
                  <div className="px-6 pb-4 text-warm-600 bg-warm-50">
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
      <section className="py-16 sm:py-24 bg-gradient-to-br from-haven-700 via-haven-800 to-haven-900 relative overflow-hidden">
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

      {/* ================================================================== */}
      {/* FOOTER */}
      {/* ================================================================== */}
      <footer className="bg-haven-900 text-white py-12">
        <div className="max-w-6xl mx-auto px-4 sm:px-6">
          <div className="grid sm:grid-cols-2 lg:grid-cols-5 gap-8">
            <div className="lg:col-span-2">
              <h3 className="text-xl font-bold text-white">Haven</h3>
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
              <h4 className="font-semibold mb-3 text-white">Product</h4>
              <ul className="space-y-2 text-sm text-warm-400">
                <li><a href="#how-it-works" className="hover:text-white">How It Works</a></li>
                <li><a href="#" className="hover:text-white">Services</a></li>
                <li><a href="#pricing" className="hover:text-white">Pricing</a></li>
                <li><a href="#" className="hover:text-white">Compare</a></li>
              </ul>
            </div>
            <div>
              <h4 className="font-semibold mb-3 text-white">Company</h4>
              <ul className="space-y-2 text-sm text-warm-400">
                <li><a href="#" className="hover:text-white">About</a></li>
                <li><a href="#" className="hover:text-white">Careers</a></li>
                <li><a href="#" className="hover:text-white">Contact</a></li>
                <li><Link href="/login" className="hover:text-white">Member Login</Link></li>
              </ul>
            </div>
            <div>
              <h4 className="font-semibold mb-3 text-white">Partners</h4>
              <ul className="space-y-2 text-sm text-warm-400">
                <li><Link href="/vendor" className="hover:text-white">Vendor Portal</Link></li>
                <li><Link href="/handyman" className="hover:text-white">Handyman Portal</Link></li>
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
