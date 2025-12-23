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
                Full-service home management, not just software
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
              Not another app to organize your chaos. <strong>Actual humans who eliminate it.</strong> Your dedicated Home Manager handles everything so you can focus on what matters.
            </p>

            {/* Value Props */}
            <div className="flex flex-wrap gap-3 mb-8">
              {[
                { icon: Receipt, label: 'One Bill', iconColor: 'text-amber-600' },
                { icon: MessageSquare, label: 'One Contact', iconColor: 'text-emerald-600' },
                { icon: CheckCircle2, label: 'Zero Hassle', iconColor: 'text-sky-600' },
              ].map(({ icon: Icon, label, iconColor }) => (
                <div key={label} className="flex items-center gap-2 px-4 py-2 bg-white rounded-full border border-slate-200 shadow-sm">
                  <Icon className={`w-4 h-4 ${iconColor}`} />
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
                    <p className="text-xs text-slate-500">Mortgage, utilities, lawn care. All set.</p>
                  </div>
                </div>

                <div className="flex items-start gap-3 p-3 bg-sky-50 rounded-xl border border-sky-100">
                  <Calendar className="w-5 h-5 text-sky-600 mt-0.5 flex-shrink-0" />
                  <div>
                    <p className="text-sm font-medium text-slate-900">Gutter cleaning scheduled</p>
                    <p className="text-xs text-slate-500">Tuesday 10am. No action needed.</p>
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
          <h2 className="font-serif text-3xl sm:text-4xl lg:text-5xl font-bold mb-4 text-white">
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
            <span className="text-slate-300">. That's what our members get back.</span>
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

        {/* Mobile: Stacked Cards (shown on screens smaller than lg) */}
        <div className="lg:hidden space-y-3 mb-12">
          {[
            { feature: 'Monthly Cost', them: '$375/month', us: '$349/month' },
            { feature: 'Setup Fee', them: '$3K - $5K', us: '$0' },
            { feature: 'First Year Total', them: '$7,500+', us: '$4,188' },
            { feature: 'Contract', them: '12-mo prepaid', us: 'Month-to-month' },
            { feature: 'Bills Paid For You', them: 'No', us: 'Yes, one payment', usBetter: true },
            { feature: 'Vendor Coordination', them: 'No', us: 'Yes, we handle it', usBetter: true },
            { feature: 'Handyman Visits', them: 'No', us: 'Yes, monthly', usBetter: true },
            { feature: 'Home Manager', them: 'No', us: 'Yes, dedicated', usBetter: true },
          ].map((row, idx) => (
            <div key={idx} className="bg-white rounded-xl border border-slate-200 overflow-hidden">
              <div className="bg-slate-100 px-4 py-2">
                <span className="font-medium text-slate-700 text-sm">{row.feature}</span>
              </div>
              <div className="grid grid-cols-2">
                <div className="p-3 border-r border-slate-100">
                  <div className="text-xs text-slate-400 mb-1">Others</div>
                  <div className="text-sm text-slate-500">
                    {row.usBetter && <span className="text-red-500 mr-1">✗</span>}
                    {row.them}
                  </div>
                </div>
                <div className="p-3 bg-emerald-50/50">
                  <div className="text-xs text-emerald-600 mb-1">Haven</div>
                  <div className="text-sm font-medium text-emerald-700">
                    {row.usBetter && <span className="text-green-500 mr-1">✓</span>}
                    {row.us}
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Desktop: Traditional Table (shown on lg screens and up) */}
        <div className="hidden lg:block bg-white rounded-2xl shadow-xl border border-slate-200 overflow-hidden mb-12">
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
            { feature: 'Bills Paid For You', software: '❌ No (you pay each vendor)', haven: '✅ Yes, one payment covers all' },
            { feature: 'Vendor Coordination', software: '❌ No (just a contact list)', haven: '✅ Yes, we call, schedule, oversee' },
            { feature: 'Handyman Visits', software: '❌ No', haven: '✅ Yes, monthly preventive visits' },
            { feature: 'Humans Doing Work', software: '❌ No (software only)', haven: '✅ Yes, dedicated manager' },
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
              Haven costs <span className="text-emerald-600 font-semibold">$26/month less</span> with <span className="text-emerald-600 font-semibold">no setup fee</span>, and we actually do the work.
            </p>
            <Link
              href="/register"
              className="inline-flex items-center gap-2 px-8 py-4 bg-emerald-600 text-white font-semibold rounded-xl hover:bg-emerald-700 transition-colors shadow-lg shadow-emerald-600/25"
            >
              Get Actual Help for $349/month
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
      badgeBg: 'bg-amber-600',
      iconBg: 'bg-amber-100',
      iconColor: 'text-amber-600',
    },
    {
      step: 2,
      icon: PiggyBank,
      title: 'Fund Your Haven Wallet',
      description: 'One monthly payment covers everything. We pay your mortgage, utilities, and every vendor. FDIC-insured.',
      badgeBg: 'bg-emerald-600',
      iconBg: 'bg-emerald-100',
      iconColor: 'text-emerald-600',
    },
    {
      step: 3,
      icon: MessageSquare,
      title: 'Text Your Manager',
      description: "Something need fixing? Question about your home? Text once. Your dedicated manager handles everything.",
      badgeBg: 'bg-sky-600',
      iconBg: 'bg-sky-100',
      iconColor: 'text-sky-600',
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
          {steps.map(({ step, icon: Icon, title, description, badgeBg, iconBg, iconColor }) => (
            <div key={step} className="relative">
              <div className={`absolute -top-4 -left-4 w-12 h-12 ${badgeBg} rounded-full flex items-center justify-center text-white text-xl font-bold shadow-lg`}>
                {step}
              </div>
              <div className="bg-slate-50 rounded-2xl p-8 pt-12 h-full border border-slate-200 hover:border-slate-300 transition-colors">
                <div className={`w-14 h-14 ${iconBg} rounded-xl flex items-center justify-center mb-6`}>
                  <Icon className={`w-7 h-7 ${iconColor}`} />
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
      iconBg: 'bg-amber-100',
      iconColor: 'text-amber-600',
      checkColor: 'text-amber-500',
      items: ['Mortgage & property taxes', 'All utilities (electric, gas, water)', 'Insurance & HOA dues', 'Every vendor invoice, on time'],
    },
    {
      icon: Wrench,
      title: 'Home Maintenance',
      iconBg: 'bg-emerald-100',
      iconColor: 'text-emerald-600',
      checkColor: 'text-emerald-500',
      items: ['Monthly handyman visits', 'HVAC service & filter changes', 'Plumbing & electrical coordination', 'Seasonal prep & winterization'],
    },
    {
      icon: Users,
      title: 'Vendor Coordination',
      iconBg: 'bg-sky-100',
      iconColor: 'text-sky-600',
      checkColor: 'text-sky-500',
      items: ['Find & vet qualified pros', 'Schedule & oversee all work', 'Handle disputes & issues', 'Negotiate on your behalf'],
    },
    {
      icon: Heart,
      title: 'Life Management',
      iconBg: 'bg-rose-100',
      iconColor: 'text-rose-600',
      checkColor: 'text-rose-500',
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
            From paying your mortgage to changing your furnace filter, we've got it.
          </p>
        </div>

        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
          {services.map((service) => (
            <div key={service.title} className="bg-white rounded-2xl p-6 border border-slate-200 shadow-sm hover:shadow-md transition-shadow">
              <div className="flex items-start justify-between mb-4">
                <div className={`w-12 h-12 ${service.iconBg} rounded-xl flex items-center justify-center`}>
                  <service.icon className={`w-6 h-6 ${service.iconColor}`} />
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
                    <Check className={`w-4 h-4 ${service.checkColor} flex-shrink-0`} />
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
  const [showPremiumTiers, setShowPremiumTiers] = useState(false);

  return (
    <section id="pricing" className="py-24 px-4 sm:px-6 lg:px-8 bg-white">
      <div className="max-w-7xl mx-auto">
        <div className="text-center mb-16">
          <div className="inline-flex items-center gap-2 px-4 py-2 bg-emerald-100 rounded-full mb-4">
            <DollarSign className="w-4 h-4 text-emerald-700" />
            <span className="text-sm font-semibold text-emerald-800">Transparent Pricing</span>
          </div>
          <h2 className="font-serif text-3xl sm:text-4xl lg:text-5xl font-bold text-slate-900 mb-4">
            Start Simple. Upgrade Anytime.
          </h2>
          <p className="text-xl text-slate-600 max-w-2xl mx-auto">
            No hidden fees. No setup costs. No annual contracts.
          </p>
        </div>

        {/* Essentials - Primary Featured Plan */}
        <div className="max-w-2xl mx-auto mb-12">
          <div className="relative bg-emerald-900 text-white rounded-2xl p-8 shadow-2xl shadow-emerald-900/20">
            <div className="absolute top-0 left-1/2 -translate-x-1/2 -translate-y-1/2">
              <span className="inline-flex items-center gap-1 px-4 py-1.5 bg-amber-400 text-slate-900 text-sm font-bold rounded-full shadow-lg">
                <Star className="w-4 h-4" />
                Start Here
              </span>
            </div>

            <div className="pt-4 mb-6">
              <div className="flex items-center justify-between mb-2">
                <h3 className="text-2xl font-bold text-white">Haven Essentials</h3>
                <span className="px-3 py-1 bg-emerald-800 text-emerald-200 text-sm font-medium rounded-full">
                  All subscription tiers
                </span>
              </div>
              <p className="text-emerald-300">Everything you need to get started</p>
            </div>

            <div className="mb-6">
              <span className="text-5xl font-bold text-white">$349</span>
              <span className="text-emerald-300">/month</span>
            </div>

            <div className="grid sm:grid-cols-2 gap-4 mb-8">
              {[
                'Your complete home profile',
                'Bill consolidation (up to 15 accounts)',
                'Vendor coordination (reactive)',
                'Text-based home manager',
                'Document vault & home manual',
                'Same-day response',
              ].map((feature, i) => (
                <div key={i} className="flex items-start gap-3">
                  <Check className="w-5 h-5 mt-0.5 flex-shrink-0 text-emerald-400" />
                  <span className="text-emerald-50">{feature}</span>
                </div>
              ))}
            </div>

            <Link
              href="/register?plan=essentials"
              className="block w-full text-center px-6 py-4 bg-white text-emerald-900 font-bold text-lg rounded-xl hover:bg-emerald-50 transition-colors"
            >
              Get Started with Essentials
            </Link>

            <p className="text-center text-sm mt-4 text-emerald-300">
              Perfect for condos, apartments & single-family homes
            </p>
          </div>
        </div>

        {/* Haven Standard - Secondary Option */}
        <div className="max-w-2xl mx-auto mb-8">
          <div className="relative bg-white border-2 border-slate-200 rounded-2xl p-8 shadow-sm">
            <div className="mb-6">
              <h3 className="text-2xl font-bold text-slate-900 mb-1">Haven</h3>
              <p className="text-slate-500">Complete home management with proactive care</p>
            </div>

            <div className="mb-6">
              <span className="text-5xl font-bold text-slate-900">$749</span>
              <span className="text-slate-500">/month</span>
            </div>

            <div className="grid sm:grid-cols-2 gap-3 mb-8">
              {[
                'Everything in Essentials',
                'Proactive home manager',
                'Monthly handyman visit (2 hrs)',
                'Vendor oversight & negotiation',
                'Maintenance scheduling',
                '12-hour response time',
              ].map((feature, i) => (
                <div key={i} className="flex items-start gap-3">
                  <Check className="w-5 h-5 mt-0.5 flex-shrink-0 text-emerald-600" />
                  <span className="text-slate-600">{feature}</span>
                </div>
              ))}
            </div>

            <Link
              href="/register?plan=haven"
              className="block w-full text-center px-6 py-3 bg-slate-100 text-slate-900 font-semibold rounded-xl hover:bg-slate-200 transition-colors"
            >
              Upgrade to Haven
            </Link>

            <p className="text-center text-sm mt-4 text-slate-500">
              Best for homeowners who want hands-free maintenance
            </p>
          </div>
        </div>

        {/* Expandable Premium Tiers */}
        <div className="max-w-2xl mx-auto">
          <button
            onClick={() => setShowPremiumTiers(!showPremiumTiers)}
            className="w-full flex items-center justify-center gap-2 py-4 text-slate-600 hover:text-slate-900 transition-colors"
          >
            <span className="font-medium">
              {showPremiumTiers ? 'Hide premium tiers' : 'View Haven+ & Estate tiers'}
            </span>
            <ChevronDown className={`w-5 h-5 transition-transform ${showPremiumTiers ? 'rotate-180' : ''}`} />
          </button>

          {showPremiumTiers && (
            <div className="space-y-6 mt-4">
              {/* Haven+ */}
              <div className="bg-white border-2 border-slate-200 rounded-2xl p-8 shadow-sm">
                <div className="flex items-start justify-between mb-4">
                  <div>
                    <h3 className="text-2xl font-bold text-slate-900 mb-1">Haven+</h3>
                    <p className="text-slate-500">Home + life management</p>
                  </div>
                  <span className="px-3 py-1 bg-rose-100 text-rose-700 text-xs font-semibold rounded-full">
                    Concierge
                  </span>
                </div>

                <div className="mb-6">
                  <span className="text-4xl font-bold text-slate-900">$1,499</span>
                  <span className="text-slate-500">/month</span>
                </div>

                <div className="grid sm:grid-cols-2 gap-3 mb-6">
                  {[
                    'Everything in Haven',
                    'Personal assistant services',
                    'Errands, shopping & returns',
                    'Travel coordination',
                    'Event planning',
                    '4-hour priority response',
                    'Enhanced handyman (4 hrs/mo)',
                  ].map((feature, i) => (
                    <div key={i} className="flex items-start gap-3">
                      <Check className="w-5 h-5 mt-0.5 flex-shrink-0 text-emerald-600" />
                      <span className="text-slate-600">{feature}</span>
                    </div>
                  ))}
                </div>

                <Link
                  href="/register?plan=haven-plus"
                  className="block w-full text-center px-6 py-3 bg-slate-100 text-slate-900 font-semibold rounded-xl hover:bg-slate-200 transition-colors"
                >
                  Get Haven+
                </Link>
                <p className="text-center text-sm mt-3 text-slate-500">Best for busy executives</p>
              </div>

              {/* Haven Estate */}
              <div className="relative bg-gradient-to-br from-forest-900 to-forest-950 rounded-2xl p-8 text-white">
                <div className="absolute top-4 right-4">
                  <span className="px-3 py-1 bg-gold-500/20 text-gold-400 text-xs font-medium rounded-full border border-gold-500/30">
                    White Glove
                  </span>
                </div>

                <div className="flex items-center gap-3 mb-1">
                  <Building2 className="w-6 h-6 text-gold-400" />
                  <h3 className="text-2xl font-bold text-white">Haven Estate</h3>
                </div>
                <p className="text-white/60">For estates & multiple properties</p>

                <div className="mt-6">
                  <span className="text-4xl font-bold">$3,499+</span>
                  <span className="text-white/60">/month</span>
                </div>

                <p className="mt-6 text-white/80 text-lg leading-relaxed max-w-2xl">
                  Your personal estate manager anticipating needs, coordinating staff, and ensuring every detail of your properties is handled with discretion and excellence.
                </p>

                <div className="mt-6 flex flex-col sm:flex-row sm:items-end sm:justify-between gap-6">
                  <ul className="space-y-3 text-white/70">
                    <li className="flex items-center gap-2">
                      <Check className="w-4 h-4 text-gold-400" />
                      Multiple properties supported
                    </li>
                    <li className="flex items-center gap-2">
                      <Check className="w-4 h-4 text-gold-400" />
                      Priority 24/7 concierge access
                    </li>
                    <li className="flex items-center gap-2">
                      <Check className="w-4 h-4 text-gold-400" />
                      Custom service agreements
                    </li>
                  </ul>

                  <Link
                    href="/contact"
                    className="inline-flex items-center justify-center gap-2 px-8 py-3 bg-gold-500 hover:bg-gold-400 text-forest-950 font-semibold rounded-xl transition-colors"
                  >
                    Contact Us
                    <ArrowRight className="w-4 h-4" />
                  </Link>
                </div>
              </div>
            </div>
          )}
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
              <p className="text-xs text-slate-500 mt-1">Your manager, platform, home profile & more</p>
            </div>
            <div className="bg-white rounded-xl p-4 border border-amber-100">
              <p className="text-sm font-medium text-slate-600 mb-1">Your Household Bills</p>
              <p className="text-2xl font-bold text-slate-900">At Cost</p>
              <p className="text-xs text-slate-500 mt-1">Mortgage, utilities, vendors at zero markup</p>
            </div>
          </div>
          <p className="text-sm text-slate-600">
            <strong>Example:</strong> $3,200 in monthly bills + $349 Essentials = <strong>$3,549 total</strong>. One payment to Haven. We pay everyone else.
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
      a: "Not at all. We built Haven because professional home management shouldn't require a trust fund. Our Lite plan works perfectly for condos and apartments. The value comes from saving you time and preventing expensive repairs. That's valuable for any homeowner.",
    },
    {
      q: 'How is Haven different from household management software?',
      a: "Software gives you tools to organize things yourself. You still do all the work. Haven gives you actual humans who handle things for you. We don't give you a better to-do list. We take things off your list entirely. That's why we cost less than software-only solutions while delivering far more value.",
    },
    {
      q: 'Why should I pay for this when I can manage things myself?',
      a: "You can. The question is whether you want to. If you enjoy tracking down vendors, waiting on hold, and remembering when the furnace filter was last changed, keep doing that. If you'd rather text once and have it handled, that's what we do. Most members say they get 8+ hours back every month.",
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
      a: "Yes. Your Haven Wallet is FDIC-insured through our banking partner. You see every transaction in real-time, maintain full visibility, and can withdraw anytime. We never mark up vendor costs. Your bills pass through at exactly what they cost.",
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
        <h2 className="font-serif text-4xl sm:text-5xl font-bold mb-6 text-white">
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
              <li><Link href="/vendor" className="hover:text-white transition-colors">Vendor Portal</Link></li>
              <li><Link href="/handyman" className="hover:text-white transition-colors">Handyman Portal</Link></li>
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
      <HowItWorksSection />
      <ServicesSection />
      <PricingSection />
      <CompetitorSection />
      <SocialProofSection />
      <FAQSection />
      <FinalCTASection />
      <Footer />
    </div>
  );
}
