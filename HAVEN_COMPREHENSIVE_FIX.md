# 🏠 HAVEN - COMPREHENSIVE PLATFORM UPDATE

## HOW TO RUN

```bash
cd /Users/tomburke/Projects/Housing-Manager
claude --dangerously-skip-permissions
```

Then paste this entire prompt.

---

## OVERVIEW - WHAT THIS FIXES

### Part 1: Homepage Revolution - "Home Management for Everyone"
Complete redesign of the public homepage to:
- Make Haven accessible to ALL homeowners, not just the wealthy
- Clearly articulate the value proposition (one bill, one contact, zero hassle)
- Show the full breadth of services we handle
- Emphasize time savings and stress reduction
- Include accessible pricing tiers starting at $99/month

### Part 2: Property Configuration - Real Greenwich Estate
Replace demo property with actual 38 Bedford Rd listing

### Part 3: Typography & Contrast Fixes
- Serif font only for h1 page titles
- White text on ALL dark backgrounds

### Part 4: Avatar System (DiceBear)
Replace real photos with illustrated avatars

### Part 5: Vendor Improvements
- Fix map card overflow
- Add 25+ vendors with unique images

### Part 6: Family Page & Seed Data
- Add Alice, Emma, Jack, Max to family
- Update seed with comprehensive data

### Part 7: Handyman & Vendor Portal Null Safety
Fix crashes from undefined data

---

## PART 1: HOMEPAGE REVOLUTION

### The Vision
Haven isn't just for mansions. Everyone with a home deals with:
- Dozens of bills and vendor relationships
- Maintenance that falls through the cracks
- Being the unpaid "project manager" of their own home
- Stress when things break

Haven makes professional home management accessible to everyone.

### 1.1 Replace Homepage

**File:** `apps/web/src/app/page.tsx`

Replace the entire file with:

```tsx
'use client';

import { useState } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { motion } from 'framer-motion';
import {
  Home,
  Check,
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
  Thermometer,
  MapPin,
  Heart,
  Phone,
  Mail,
  Package,
  Car,
  Dog,
  Gift,
  Plane,
  Snowflake,
  Sun,
  Leaf,
  AlertTriangle,
  ClipboardList,
  Receipt,
  Key,
  Camera,
  Bell,
  Activity,
  Filter,
  ChevronDown,
  ChevronRight,
  Play,
  X,
} from 'lucide-react';

// ============================================================================
// HERO SECTION - "Home Management for Everyone"
// ============================================================================

function HeroSection() {
  return (
    <section className="relative pt-24 pb-20 px-4 sm:px-6 lg:px-8 overflow-hidden bg-gradient-to-b from-slate-50 to-white">
      <div className="max-w-7xl mx-auto">
        <div className="grid lg:grid-cols-2 gap-12 lg:gap-16 items-center">
          {/* Left Column - Text */}
          <div className="relative z-10">
            {/* Accessibility Badge */}
            <div className="inline-flex items-center gap-2 px-4 py-2 bg-emerald-50 border border-emerald-200 rounded-full mb-6">
              <Heart className="w-4 h-4 text-emerald-600" />
              <span className="text-sm font-medium text-emerald-800">
                Home management for everyone — not just the 1%
              </span>
            </div>

            <h1 className="font-serif text-4xl sm:text-5xl lg:text-6xl font-medium text-slate-900 leading-tight tracking-tight mb-6">
              Stop Managing Your Home.
              <br />
              <span className="text-emerald-600">Start Living In It.</span>
            </h1>

            <p className="text-xl text-slate-600 max-w-xl mb-4 leading-relaxed">
              <strong className="text-slate-900">One bill. One contact. Zero hassle.</strong>
            </p>
            
            <p className="text-lg text-slate-500 max-w-xl mb-8 leading-relaxed">
              We pay your bills, coordinate your vendors, handle repairs, and manage everything about your home — so you can focus on what actually matters.
            </p>

            {/* Key Benefits */}
            <div className="grid sm:grid-cols-3 gap-4 mb-8">
              <div className="flex items-center gap-3 p-3 bg-white rounded-xl border border-slate-200 shadow-sm">
                <div className="w-10 h-10 bg-amber-100 rounded-lg flex items-center justify-center">
                  <Receipt className="w-5 h-5 text-amber-600" />
                </div>
                <div>
                  <p className="font-semibold text-slate-900 text-sm">One Bill</p>
                  <p className="text-xs text-slate-500">All expenses</p>
                </div>
              </div>
              <div className="flex items-center gap-3 p-3 bg-white rounded-xl border border-slate-200 shadow-sm">
                <div className="w-10 h-10 bg-emerald-100 rounded-lg flex items-center justify-center">
                  <MessageSquare className="w-5 h-5 text-emerald-600" />
                </div>
                <div>
                  <p className="font-semibold text-slate-900 text-sm">One Contact</p>
                  <p className="text-xs text-slate-500">For everything</p>
                </div>
              </div>
              <div className="flex items-center gap-3 p-3 bg-white rounded-xl border border-slate-200 shadow-sm">
                <div className="w-10 h-10 bg-sky-100 rounded-lg flex items-center justify-center">
                  <CheckCircle2 className="w-5 h-5 text-sky-600" />
                </div>
                <div>
                  <p className="font-semibold text-slate-900 text-sm">Zero Hassle</p>
                  <p className="text-xs text-slate-500">We handle it</p>
                </div>
              </div>
            </div>

            <div className="flex flex-col sm:flex-row items-start gap-4">
              <Link
                href="/register"
                className="inline-flex items-center justify-center gap-2 px-8 py-4 bg-emerald-600 text-white text-lg font-medium rounded-xl hover:bg-emerald-700 transition-colors shadow-lg shadow-emerald-600/20"
              >
                Start for $99/month
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

            {/* Trust Row */}
            <div className="flex flex-wrap items-center gap-6 mt-10 pt-8 border-t border-slate-200">
              <div className="flex items-center gap-2 text-slate-500">
                <Lock className="w-4 h-4" />
                <span className="text-sm">FDIC-Insured</span>
              </div>
              <div className="flex items-center gap-2 text-slate-500">
                <Shield className="w-4 h-4" />
                <span className="text-sm">$2M Coverage</span>
              </div>
              <div className="flex items-center gap-2 text-slate-500">
                <BadgeCheck className="w-4 h-4" />
                <span className="text-sm">Vetted Pros</span>
              </div>
              <div className="flex items-center gap-2 text-slate-500">
                <Star className="w-4 h-4 text-amber-400 fill-amber-400" />
                <span className="text-sm">4.9/5 Rating</span>
              </div>
            </div>
          </div>

          {/* Right Column - Visual */}
          <div className="relative hidden lg:block">
            {/* Background Glow */}
            <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[500px] h-[500px] bg-gradient-to-r from-emerald-200/40 to-sky-200/40 rounded-full blur-3xl" />
            
            {/* Main Card - Your Manager */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2, duration: 0.6 }}
              className="relative bg-white rounded-2xl shadow-2xl shadow-slate-900/10 border border-slate-200 overflow-hidden max-w-sm mx-auto"
            >
              <div className="p-5 border-b border-slate-100">
                <div className="flex items-center gap-3">
                  <div className="w-12 h-12 bg-gradient-to-br from-emerald-500 to-emerald-600 rounded-full flex items-center justify-center">
                    <span className="text-lg font-bold text-white">SH</span>
                  </div>
                  <div className="flex-1">
                    <p className="font-semibold text-slate-900">Sarah, Your Home Manager</p>
                    <p className="text-sm text-emerald-600 flex items-center gap-1">
                      <span className="w-2 h-2 bg-emerald-500 rounded-full animate-pulse" />
                      Online now
                    </p>
                  </div>
                </div>
              </div>
              
              <div className="p-5 space-y-4">
                {/* Completed Task */}
                <div className="flex items-start gap-3 p-3 bg-emerald-50 rounded-xl border border-emerald-100">
                  <CheckCircle2 className="w-5 h-5 text-emerald-600 mt-0.5" />
                  <div>
                    <p className="text-sm font-medium text-slate-900">Furnace service completed</p>
                    <p className="text-xs text-slate-500">Filter changed, ready for winter</p>
                  </div>
                </div>
                
                {/* Bill Paid */}
                <div className="flex items-start gap-3 p-3 bg-amber-50 rounded-xl border border-amber-100">
                  <DollarSign className="w-5 h-5 text-amber-600 mt-0.5" />
                  <div>
                    <p className="text-sm font-medium text-slate-900">Electric bill paid</p>
                    <p className="text-xs text-slate-500">$247.89 • Eversource</p>
                  </div>
                </div>
                
                {/* Upcoming */}
                <div className="flex items-start gap-3 p-3 bg-slate-50 rounded-xl border border-slate-200">
                  <Calendar className="w-5 h-5 text-slate-500 mt-0.5" />
                  <div>
                    <p className="text-sm font-medium text-slate-900">Gutter cleaning scheduled</p>
                    <p className="text-xs text-slate-500">Tomorrow, 9am • Country Landscaping</p>
                  </div>
                </div>
              </div>
              
              <div className="p-4 bg-slate-50 border-t border-slate-100">
                <p className="text-xs text-slate-500 text-center">
                  No action needed from you. We've got it covered.
                </p>
              </div>
            </motion.div>

            {/* Floating Badge - Bills Consolidated */}
            <motion.div
              initial={{ opacity: 0, x: -30 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.5, duration: 0.5 }}
              className="absolute top-8 -left-8 bg-white rounded-xl shadow-lg border border-slate-200 p-3"
            >
              <div className="flex items-center gap-2">
                <div className="flex -space-x-2">
                  <div className="w-6 h-6 bg-blue-100 rounded-full flex items-center justify-center border-2 border-white">
                    <Zap className="w-3 h-3 text-blue-600" />
                  </div>
                  <div className="w-6 h-6 bg-cyan-100 rounded-full flex items-center justify-center border-2 border-white">
                    <Droplets className="w-3 h-3 text-cyan-600" />
                  </div>
                  <div className="w-6 h-6 bg-purple-100 rounded-full flex items-center justify-center border-2 border-white">
                    <Wifi className="w-3 h-3 text-purple-600" />
                  </div>
                </div>
                <ArrowRight className="w-4 h-4 text-slate-400" />
                <div className="w-8 h-8 bg-emerald-600 rounded-lg flex items-center justify-center">
                  <Home className="w-4 h-4 text-white" />
                </div>
              </div>
              <p className="text-xs text-slate-600 mt-2 font-medium">12 bills → 1 payment</p>
            </motion.div>

            {/* Floating Badge - Time Saved */}
            <motion.div
              initial={{ opacity: 0, x: 30 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.7, duration: 0.5 }}
              className="absolute bottom-16 -right-4 bg-white rounded-xl shadow-lg border border-slate-200 p-3"
            >
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 bg-sky-100 rounded-lg flex items-center justify-center">
                  <Clock className="w-4 h-4 text-sky-600" />
                </div>
                <div>
                  <p className="text-lg font-bold text-slate-900">8+ hrs</p>
                  <p className="text-xs text-slate-500">saved monthly</p>
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
// PROBLEM/SOLUTION SECTION - "We Get It"
// ============================================================================

function ProblemSection() {
  return (
    <section className="py-20 px-4 sm:px-6 lg:px-8 bg-slate-900 text-white">
      <div className="max-w-5xl mx-auto">
        <div className="text-center mb-12">
          <h2 className="font-serif text-3xl sm:text-4xl font-medium mb-4">
            Owning a home shouldn't feel like a second job.
          </h2>
          <p className="text-lg text-slate-300 max-w-2xl mx-auto">
            You're juggling a career, family, and life. The last thing you need is to be the unpaid project manager of your own home.
          </p>
        </div>

        <div className="grid md:grid-cols-2 gap-8">
          {/* The Problem */}
          <div className="bg-slate-800/50 rounded-2xl p-6 border border-slate-700">
            <div className="flex items-center gap-2 mb-4">
              <AlertTriangle className="w-5 h-5 text-red-400" />
              <h3 className="font-semibold text-lg">Without Haven</h3>
            </div>
            <ul className="space-y-3">
              {[
                "12+ vendor relationships to manage",
                "Dozens of passwords and accounts",
                "Bills arriving at random times",
                "Missed maintenance = expensive repairs",
                "Hours on hold with service companies",
                "No idea what anything costs",
                "Constant mental overhead",
              ].map((item, i) => (
                <li key={i} className="flex items-start gap-3 text-slate-300">
                  <X className="w-4 h-4 text-red-400 mt-1 flex-shrink-0" />
                  <span>{item}</span>
                </li>
              ))}
            </ul>
          </div>

          {/* The Solution */}
          <div className="bg-emerald-900/30 rounded-2xl p-6 border border-emerald-700/50">
            <div className="flex items-center gap-2 mb-4">
              <CheckCircle2 className="w-5 h-5 text-emerald-400" />
              <h3 className="font-semibold text-lg">With Haven</h3>
            </div>
            <ul className="space-y-3">
              {[
                "One dedicated Home Manager",
                "One login, one dashboard",
                "One monthly bill, auto-paid",
                "Preventive care keeps things working",
                "Text your manager, we handle calls",
                "Clear statements, no surprises",
                "Complete peace of mind",
              ].map((item, i) => (
                <li key={i} className="flex items-start gap-3 text-emerald-100">
                  <Check className="w-4 h-4 text-emerald-400 mt-1 flex-shrink-0" />
                  <span>{item}</span>
                </li>
              ))}
            </ul>
          </div>
        </div>

        <div className="mt-12 text-center">
          <p className="text-xl text-slate-300">
            <span className="text-white font-semibold">8+ hours per month</span> — that's what our members get back.
          </p>
        </div>
      </div>
    </section>
  );
}

// ============================================================================
// HOW IT WORKS - 3 SIMPLE STEPS
// ============================================================================

function HowItWorksSection() {
  return (
    <section id="how-it-works" className="py-24 px-4 sm:px-6 lg:px-8 bg-white">
      <div className="max-w-7xl mx-auto">
        <div className="text-center mb-16">
          <div className="inline-flex items-center gap-2 px-3 py-1.5 bg-emerald-100 rounded-full mb-4">
            <Sparkles className="w-4 h-4 text-emerald-700" />
            <span className="text-sm font-medium text-emerald-800">Simple Setup</span>
          </div>
          <h2 className="font-serif text-3xl sm:text-4xl lg:text-5xl font-medium text-slate-900 mb-4">
            Three Steps to Freedom
          </h2>
          <p className="text-lg text-slate-600 max-w-2xl mx-auto">
            Get started in minutes. We'll handle the rest.
          </p>
        </div>

        <div className="grid md:grid-cols-3 gap-8 lg:gap-12">
          {/* Step 1 */}
          <div className="relative">
            <div className="absolute -top-4 -left-4 w-12 h-12 bg-emerald-600 rounded-full flex items-center justify-center text-white text-xl font-bold shadow-lg">
              1
            </div>
            <div className="bg-slate-50 rounded-2xl p-8 pt-12 h-full border border-slate-200">
              <div className="w-14 h-14 bg-amber-100 rounded-xl flex items-center justify-center mb-6">
                <ClipboardList className="w-7 h-7 text-amber-600" />
              </div>
              <h3 className="text-xl font-semibold text-slate-900 mb-3">Tell Us About Your Home</h3>
              <p className="text-slate-600 leading-relaxed mb-4">
                Share your bills, vendors, and how you want things handled. We'll set up auto-pay and take over the relationships.
              </p>
              <div className="flex flex-wrap gap-2">
                {['Electric', 'Water', 'Internet', 'Lawn', 'Cleaning', '+more'].map(tag => (
                  <span key={tag} className="px-2 py-1 bg-white rounded text-xs text-slate-500 border border-slate-200">
                    {tag}
                  </span>
                ))}
              </div>
            </div>
          </div>

          {/* Step 2 */}
          <div className="relative">
            <div className="absolute -top-4 -left-4 w-12 h-12 bg-emerald-600 rounded-full flex items-center justify-center text-white text-xl font-bold shadow-lg">
              2
            </div>
            <div className="bg-slate-50 rounded-2xl p-8 pt-12 h-full border border-slate-200">
              <div className="w-14 h-14 bg-emerald-100 rounded-xl flex items-center justify-center mb-6">
                <DollarSign className="w-7 h-7 text-emerald-600" />
              </div>
              <h3 className="text-xl font-semibold text-slate-900 mb-3">Fund Your Haven Wallet</h3>
              <p className="text-slate-600 leading-relaxed mb-4">
                Make one monthly payment to Haven. We pay everyone else. Your money is FDIC-insured and you see every transaction.
              </p>
              <div className="bg-white rounded-lg p-3 border border-slate-200">
                <div className="flex items-center justify-between text-sm">
                  <span className="text-slate-600">December total</span>
                  <span className="font-semibold text-slate-900">$2,847</span>
                </div>
                <div className="text-xs text-slate-500 mt-1">Mortgage + utilities + vendors. Done.</div>
              </div>
            </div>
          </div>

          {/* Step 3 */}
          <div className="relative">
            <div className="absolute -top-4 -left-4 w-12 h-12 bg-emerald-600 rounded-full flex items-center justify-center text-white text-xl font-bold shadow-lg">
              3
            </div>
            <div className="bg-slate-50 rounded-2xl p-8 pt-12 h-full border border-slate-200">
              <div className="w-14 h-14 bg-sky-100 rounded-xl flex items-center justify-center mb-6">
                <MessageSquare className="w-7 h-7 text-sky-600" />
              </div>
              <h3 className="text-xl font-semibold text-slate-900 mb-3">Text Your Manager</h3>
              <p className="text-slate-600 leading-relaxed mb-4">
                Something needs fixing? Have a question? Just text. Your dedicated Home Manager coordinates everything.
              </p>
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-emerald-600 rounded-full flex items-center justify-center">
                  <span className="text-sm font-bold text-white">SH</span>
                </div>
                <div>
                  <p className="text-sm font-medium text-slate-900">Sarah Harrison</p>
                  <p className="text-xs text-emerald-600">Your Home Manager</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

// ============================================================================
// EVERYTHING WE HANDLE - Full Service List
// ============================================================================

function ServicesSection() {
  const serviceCategories = [
    {
      title: "Bill Management",
      icon: Receipt,
      color: "amber",
      services: [
        "Mortgage & property taxes",
        "All utilities (electric, gas, water)",
        "Internet, cable, streaming",
        "Insurance premiums",
        "HOA dues",
        "Vendor invoices",
      ]
    },
    {
      title: "Home Maintenance",
      icon: Wrench,
      color: "emerald",
      services: [
        "HVAC service & filter changes",
        "Plumbing repairs",
        "Electrical issues",
        "Appliance repair",
        "Roof & gutter maintenance",
        "Seasonal prep (winterization, etc.)",
      ]
    },
    {
      title: "Vendor Coordination",
      icon: Users,
      color: "sky",
      services: [
        "Lawn care & landscaping",
        "House cleaning",
        "Pool & spa service",
        "Pest control",
        "Snow removal",
        "Contractor oversight",
      ]
    },
    {
      title: "Life Management (Haven+)",
      icon: Heart,
      color: "rose",
      services: [
        "Errand running",
        "Package handling & returns",
        "Pet care coordination",
        "Guest preparation",
        "Event planning help",
        "Personal shopping",
      ]
    },
  ];

  const colorClasses = {
    amber: { bg: 'bg-amber-100', text: 'text-amber-600', border: 'border-amber-200' },
    emerald: { bg: 'bg-emerald-100', text: 'text-emerald-600', border: 'border-emerald-200' },
    sky: { bg: 'bg-sky-100', text: 'text-sky-600', border: 'border-sky-200' },
    rose: { bg: 'bg-rose-100', text: 'text-rose-600', border: 'border-rose-200' },
  };

  return (
    <section className="py-24 px-4 sm:px-6 lg:px-8 bg-slate-50">
      <div className="max-w-7xl mx-auto">
        <div className="text-center mb-16">
          <h2 className="font-serif text-3xl sm:text-4xl lg:text-5xl font-medium text-slate-900 mb-4">
            Everything Your Home Needs. Handled.
          </h2>
          <p className="text-lg text-slate-600 max-w-2xl mx-auto">
            From paying your mortgage to changing your furnace filter — we've got it covered.
          </p>
        </div>

        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
          {serviceCategories.map((category) => {
            const colors = colorClasses[category.color as keyof typeof colorClasses];
            return (
              <div key={category.title} className="bg-white rounded-2xl p-6 border border-slate-200 shadow-sm">
                <div className={`w-12 h-12 ${colors.bg} rounded-xl flex items-center justify-center mb-4`}>
                  <category.icon className={`w-6 h-6 ${colors.text}`} />
                </div>
                <h3 className="font-semibold text-slate-900 mb-4">{category.title}</h3>
                <ul className="space-y-2">
                  {category.services.map((service, i) => (
                    <li key={i} className="flex items-start gap-2 text-sm text-slate-600">
                      <Check className={`w-4 h-4 ${colors.text} mt-0.5 flex-shrink-0`} />
                      <span>{service}</span>
                    </li>
                  ))}
                </ul>
              </div>
            );
          })}
        </div>

        {/* The Handyman Difference */}
        <div className="mt-16 bg-emerald-900 rounded-3xl p-8 lg:p-12 text-white">
          <div className="grid lg:grid-cols-2 gap-8 items-center">
            <div>
              <div className="inline-flex items-center gap-2 px-3 py-1.5 bg-emerald-800 rounded-full mb-4">
                <Wrench className="w-4 h-4 text-emerald-300" />
                <span className="text-sm font-medium text-emerald-200">The Haven Difference</span>
              </div>
              <h3 className="font-serif text-2xl sm:text-3xl font-medium mb-4">
                Your Own Dedicated Handyman
              </h3>
              <p className="text-emerald-100 leading-relaxed mb-6">
                Unlike traditional property management, you get a dedicated handyman who knows your home inside and out. Monthly preventive visits catch small issues before they become expensive problems.
              </p>
              <ul className="space-y-3">
                {[
                  "Monthly walk-through of your home",
                  "Filter changes, sensor checks, minor repairs",
                  "Knows your home's quirks and history",
                  "Same person every time — builds trust",
                ].map((item, i) => (
                  <li key={i} className="flex items-center gap-3 text-emerald-100">
                    <CheckCircle2 className="w-5 h-5 text-emerald-400" />
                    <span>{item}</span>
                  </li>
                ))}
              </ul>
            </div>
            <div className="bg-emerald-800/50 rounded-2xl p-6 border border-emerald-700">
              <div className="flex items-center gap-4 mb-4">
                <div className="w-16 h-16 bg-emerald-700 rounded-full flex items-center justify-center">
                  <span className="text-xl font-bold text-white">MR</span>
                </div>
                <div>
                  <p className="font-semibold text-white">Mike Rodriguez</p>
                  <p className="text-emerald-300 text-sm">Your Dedicated Handyman</p>
                </div>
              </div>
              <div className="space-y-3">
                <div className="flex items-center justify-between p-3 bg-emerald-900/50 rounded-lg">
                  <span className="text-emerald-200 text-sm">Next visit</span>
                  <span className="text-white font-medium text-sm">Tuesday, 10am</span>
                </div>
                <div className="flex items-center justify-between p-3 bg-emerald-900/50 rounded-lg">
                  <span className="text-emerald-200 text-sm">Tasks this month</span>
                  <span className="text-white font-medium text-sm">4 completed</span>
                </div>
                <div className="flex items-center justify-between p-3 bg-emerald-900/50 rounded-lg">
                  <span className="text-emerald-200 text-sm">Issues prevented</span>
                  <span className="text-white font-medium text-sm">$2,400 saved</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

// ============================================================================
// PRICING - ACCESSIBLE TIERS
// ============================================================================

function PricingSection() {
  return (
    <section id="pricing" className="py-24 px-4 sm:px-6 lg:px-8 bg-white">
      <div className="max-w-7xl mx-auto">
        <div className="text-center mb-16">
          <div className="inline-flex items-center gap-2 px-3 py-1.5 bg-emerald-100 rounded-full mb-4">
            <Heart className="w-4 h-4 text-emerald-700" />
            <span className="text-sm font-medium text-emerald-800">Accessible Pricing</span>
          </div>
          <h2 className="font-serif text-3xl sm:text-4xl lg:text-5xl font-medium text-slate-900 mb-4">
            Plans That Fit Your Life
          </h2>
          <p className="text-lg text-slate-600 max-w-2xl mx-auto">
            Professional home management shouldn't require a trust fund. Choose what works for you.
          </p>
        </div>

        <div className="grid lg:grid-cols-3 gap-8 max-w-6xl mx-auto">
          {/* STARTER */}
          <div className="bg-white rounded-2xl p-8 border-2 border-slate-200 shadow-sm">
            <div className="mb-6">
              <h3 className="font-serif text-2xl font-medium text-slate-900 mb-1">Starter</h3>
              <p className="text-slate-500">Essential home management</p>
            </div>
            <div className="mb-6">
              <span className="text-5xl font-bold text-slate-900">$99</span>
              <span className="text-slate-500">/month</span>
            </div>
            <p className="text-slate-600 mb-6">
              Perfect for condos, townhomes, and smaller homes.
            </p>
            <ul className="space-y-4 mb-8">
              {[
                "Bill consolidation (up to 8 accounts)",
                "Dedicated home manager",
                "Vendor coordination",
                "Maintenance scheduling",
                "Digital document vault",
                "Email & chat support",
              ].map((item, i) => (
                <li key={i} className="flex items-start gap-3">
                  <Check className="w-5 h-5 text-emerald-600 mt-0.5 flex-shrink-0" />
                  <span className="text-slate-600">{item}</span>
                </li>
              ))}
            </ul>
            <Link
              href="/register?plan=starter"
              className="block w-full text-center px-6 py-3 bg-slate-100 text-slate-900 font-medium rounded-xl hover:bg-slate-200 transition-colors"
            >
              Get Started
            </Link>
          </div>

          {/* HAVEN - HIGHLIGHTED */}
          <div className="relative bg-emerald-900 rounded-2xl p-8 text-white shadow-2xl shadow-emerald-900/20 lg:-mt-4 lg:mb-[-1rem]">
            <div className="absolute top-0 left-1/2 -translate-x-1/2 -translate-y-1/2">
              <span className="inline-flex items-center gap-1 px-4 py-1.5 bg-amber-400 text-slate-900 text-sm font-semibold rounded-full shadow-lg">
                <Star className="w-4 h-4" />
                Most Popular
              </span>
            </div>
            <div className="mb-6 pt-4">
              <h3 className="font-serif text-2xl font-medium text-white mb-1">Haven</h3>
              <p className="text-emerald-300">Complete home management</p>
            </div>
            <div className="mb-6">
              <span className="text-5xl font-bold text-white">$149</span>
              <span className="text-emerald-300">/month</span>
            </div>
            <p className="text-emerald-100 mb-6">
              Our most popular plan. Everything you need to stop managing your home.
            </p>
            <ul className="space-y-4 mb-8">
              {[
                "Unlimited bill accounts",
                "Dedicated home manager",
                "Monthly handyman visit",
                "Vendor negotiation & oversight",
                "Preventive maintenance program",
                "24-hour response time",
                "Full document vault & home records",
                "Seasonal prep coordination",
              ].map((item, i) => (
                <li key={i} className="flex items-start gap-3">
                  <Check className="w-5 h-5 text-emerald-400 mt-0.5 flex-shrink-0" />
                  <span className="text-emerald-50">{item}</span>
                </li>
              ))}
            </ul>
            <Link
              href="/register?plan=haven"
              className="block w-full text-center px-6 py-3 bg-white text-emerald-900 font-medium rounded-xl hover:bg-emerald-50 transition-colors"
            >
              Get Started
            </Link>
          </div>

          {/* HAVEN+ */}
          <div className="bg-white rounded-2xl p-8 border-2 border-slate-200 shadow-sm">
            <div className="mb-6">
              <h3 className="font-serif text-2xl font-medium text-slate-900 mb-1">Haven+</h3>
              <p className="text-slate-500">Home + life management</p>
            </div>
            <div className="mb-6">
              <span className="text-5xl font-bold text-slate-900">$349</span>
              <span className="text-slate-500">/month</span>
            </div>
            <p className="text-slate-600 mb-6">
              Beyond home management. We handle errands, events, and everything else.
            </p>
            <ul className="space-y-4 mb-8">
              {[
                "Everything in Haven",
                "Errand running & pickups",
                "Package tracking & returns",
                "Event planning assistance",
                "Pet care coordination",
                "Guest preparation",
                "Personal shopping & gifts",
                "Priority 4-hour response",
              ].map((item, i) => (
                <li key={i} className="flex items-start gap-3">
                  <Check className="w-5 h-5 text-emerald-600 mt-0.5 flex-shrink-0" />
                  <span className="text-slate-600">{item}</span>
                </li>
              ))}
            </ul>
            <Link
              href="/register?plan=haven-plus"
              className="block w-full text-center px-6 py-3 bg-slate-100 text-slate-900 font-medium rounded-xl hover:bg-slate-200 transition-colors"
            >
              Get Started
            </Link>
          </div>
        </div>

        {/* How Billing Works */}
        <div className="mt-16 max-w-4xl mx-auto">
          <div className="bg-amber-50 rounded-2xl p-6 border border-amber-200">
            <h3 className="font-semibold text-slate-900 mb-4 flex items-center gap-2">
              <DollarSign className="w-5 h-5 text-amber-600" />
              How Your Bill Works
            </h3>
            <div className="grid sm:grid-cols-2 gap-4 mb-4">
              <div className="bg-white rounded-xl p-4">
                <p className="text-sm font-medium text-slate-900 mb-1">Haven Membership</p>
                <p className="text-2xl font-bold text-emerald-600">$99 - $349</p>
                <p className="text-xs text-slate-500 mt-1">Your manager, platform, handyman visits</p>
              </div>
              <div className="bg-white rounded-xl p-4">
                <p className="text-sm font-medium text-slate-900 mb-1">Your Household Bills</p>
                <p className="text-2xl font-bold text-slate-900">At Cost</p>
                <p className="text-xs text-slate-500 mt-1">Mortgage, utilities, vendors. Zero markup.</p>
              </div>
            </div>
            <p className="text-sm text-slate-600">
              <strong>Example:</strong> If your household bills total $2,500/month and you're on Haven ($149), you'd pay Haven <strong>$2,649</strong> total. We pay all your vendors. You get one clear statement.
            </p>
          </div>
        </div>

        {/* Cancel Anytime */}
        <p className="text-center text-slate-500 mt-8">
          No contracts. No setup fees. Cancel anytime.
        </p>
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
      quote: "I was skeptical at first — I'm not rich, just a regular homeowner. But Haven has saved me so much time and stress. The $149 is worth every penny.",
      name: "Marcus T.",
      role: "Software developer, 3BR colonial",
      highlight: "Worth every penny",
    },
    {
      quote: "Between work and two kids, I had zero bandwidth for home stuff. Now I just text Sarah and it's handled. Last month she saved us $400 by catching a contractor overcharge.",
      name: "Jennifer L.",
      role: "Working mom, townhouse",
      highlight: "Saved $400",
    },
    {
      quote: "The monthly handyman visit alone is worth the membership. Mike caught a small leak that would have cost thousands if we'd waited. Proactive care is a game-changer.",
      name: "David & Priya S.",
      role: "Dual-income couple, 4BR home",
      highlight: "Prevented major repair",
    },
  ];

  return (
    <section className="py-24 px-4 sm:px-6 lg:px-8 bg-slate-50">
      <div className="max-w-7xl mx-auto">
        <div className="text-center mb-16">
          <h2 className="font-serif text-3xl sm:text-4xl font-medium text-slate-900 mb-4">
            Real Homeowners. Real Results.
          </h2>
          <p className="text-lg text-slate-600">
            Join hundreds of families who've taken back their time.
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
                  <p className="font-medium text-slate-900">{t.name}</p>
                  <p className="text-sm text-slate-500">{t.role}</p>
                </div>
                <span className="px-3 py-1.5 bg-emerald-100 text-emerald-700 text-sm font-medium rounded-full">
                  {t.highlight}
                </span>
              </div>
            </div>
          ))}
        </div>

        {/* Stats */}
        <div className="mt-16 grid grid-cols-2 md:grid-cols-4 gap-8">
          {[
            { value: "8+", label: "Hours saved monthly" },
            { value: "500+", label: "Families served" },
            { value: "4.9", label: "Average rating" },
            { value: "$0", label: "Hidden fees" },
          ].map((stat, i) => (
            <div key={i} className="text-center">
              <p className="text-4xl font-bold text-emerald-600">{stat.value}</p>
              <p className="text-slate-600">{stat.label}</p>
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
      q: "Is this only for rich people with mansions?",
      a: "Absolutely not! We built Haven because professional home management SHOULDN'T be only for the wealthy. Our Starter plan at $99/month works great for condos and townhomes. The value comes from saving you time, preventing expensive repairs, and eliminating the mental overhead of managing everything yourself.",
    },
    {
      q: "How does the one-bill system work?",
      a: "You make one monthly payment to Haven. We use it to pay your mortgage, utilities, lawn care, cleaning, and every other household expense. Routine bills are automatic. Repairs and one-time expenses require your approval first. You get a clear statement showing where every dollar went.",
    },
    {
      q: "Is my money safe?",
      a: "Yes. Your Haven Wallet is held at an FDIC-insured partner bank. You can see every transaction in real-time and withdraw funds anytime. We never mark up vendor costs or take a percentage of your bills.",
    },
    {
      q: "What if I already have vendors I like?",
      a: "Great — we'll work with them! We take over the relationship and payment coordination, but you keep your trusted vendors. We just make it easier by handling scheduling, invoicing, and quality oversight.",
    },
    {
      q: "What's the difference between a Home Manager and a handyman?",
      a: "Your Home Manager (like Sarah) is your single point of contact. She coordinates vendors, pays bills, handles scheduling, and makes sure nothing falls through the cracks. Your Handyman (like Mike) does the hands-on work — monthly preventive visits, minor repairs, and being there when contractors need access.",
    },
    {
      q: "Can Haven help with emergencies at 2am?",
      a: "Haven and Haven+ members have 24/7 emergency support. Text your manager anytime — even overnight — and we'll dispatch the right vendor. No more Googling plumbers at midnight.",
    },
  ];

  return (
    <section className="py-24 px-4 sm:px-6 lg:px-8 bg-white">
      <div className="max-w-3xl mx-auto">
        <div className="text-center mb-16">
          <h2 className="font-serif text-3xl sm:text-4xl font-medium text-slate-900 mb-4">
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
                <span className="font-medium text-slate-900">{faq.q}</span>
                <ChevronRight className={`w-5 h-5 text-slate-400 transition-transform ${openIndex === i ? 'rotate-90' : ''}`} />
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
        <h2 className="font-serif text-4xl sm:text-5xl font-medium mb-6">
          Ready to stop managing your home?
        </h2>
        <p className="text-xl text-emerald-200 mb-4">
          One bill. One contact. Zero hassle.
        </p>
        <p className="text-lg text-emerald-300 mb-10 max-w-2xl mx-auto">
          Join hundreds of families who've reclaimed their time and peace of mind.
        </p>
        <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
          <Link
            href="/register"
            className="inline-flex items-center gap-2 px-8 py-4 bg-white text-emerald-900 text-lg font-medium rounded-xl hover:bg-emerald-50 transition-colors shadow-lg"
          >
            Start for $99/month
            <ArrowRight className="w-5 h-5" />
          </Link>
          <Link
            href="/login"
            className="inline-flex items-center gap-2 px-8 py-4 text-white text-lg font-medium hover:text-emerald-200 transition-colors"
          >
            Member Login
          </Link>
        </div>
        <p className="text-emerald-400 text-sm mt-6">
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
              <div className="w-8 h-8 bg-emerald-600 rounded-lg flex items-center justify-center">
                <Home className="w-5 h-5 text-white" />
              </div>
              <span className="text-xl font-semibold">Haven</span>
            </div>
            <p className="text-slate-400 text-sm leading-relaxed">
              Home management for everyone. One bill. One contact. Zero hassle.
            </p>
          </div>
          <div>
            <h4 className="font-medium mb-4">Product</h4>
            <ul className="space-y-3 text-slate-400 text-sm">
              <li><a href="#how-it-works" className="hover:text-white transition-colors">How It Works</a></li>
              <li><a href="#pricing" className="hover:text-white transition-colors">Pricing</a></li>
              <li><Link href="/login" className="hover:text-white transition-colors">Member Login</Link></li>
            </ul>
          </div>
          <div>
            <h4 className="font-medium mb-4">Company</h4>
            <ul className="space-y-3 text-slate-400 text-sm">
              <li><a href="#" className="hover:text-white transition-colors">About</a></li>
              <li><a href="#" className="hover:text-white transition-colors">Careers</a></li>
              <li><a href="#" className="hover:text-white transition-colors">Contact</a></li>
            </ul>
          </div>
          <div>
            <h4 className="font-medium mb-4">Partners</h4>
            <ul className="space-y-3 text-slate-400 text-sm">
              <li><Link href="/vendor/login" className="hover:text-white transition-colors">Vendor Portal</Link></li>
              <li><a href="#" className="hover:text-white transition-colors">Become a Handyman</a></li>
              <li><a href="#" className="hover:text-white transition-colors">Property Managers</a></li>
            </ul>
          </div>
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
// MAIN PAGE
// ============================================================================

export default function HomePage() {
  return (
    <div className="min-h-screen bg-white">
      {/* Navigation */}
      <nav className="fixed top-0 left-0 right-0 z-50 bg-white/95 backdrop-blur-sm border-b border-slate-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            <Link href="/" className="flex items-center gap-2">
              <div className="w-8 h-8 bg-emerald-600 rounded-lg flex items-center justify-center">
                <Home className="w-5 h-5 text-white" />
              </div>
              <span className="text-xl font-semibold text-slate-900">Haven</span>
            </Link>
            <div className="hidden md:flex items-center gap-8">
              <a href="#how-it-works" className="text-slate-600 hover:text-slate-900 text-sm font-medium">How It Works</a>
              <a href="#pricing" className="text-slate-600 hover:text-slate-900 text-sm font-medium">Pricing</a>
              <Link href="/login" className="text-slate-600 hover:text-slate-900 text-sm font-medium">Login</Link>
              <Link href="/register" className="px-4 py-2 bg-emerald-600 text-white text-sm font-medium rounded-lg hover:bg-emerald-700 transition-colors">
                Get Started
              </Link>
            </div>
            <Link href="/register" className="md:hidden px-4 py-2 bg-emerald-600 text-white text-sm font-medium rounded-lg">
              Get Started
            </Link>
          </div>
        </div>
      </nav>

      <HeroSection />
      <ProblemSection />
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

## PART 2: PROPERTY CONFIGURATION

### 2.1 Create Property Config File

**Create file:** `apps/web/src/lib/demo-property.ts`

```typescript
// Real property: 38 Bedford Rd, Greenwich, CT 06831 ("Inspiration Farm")
// Source: homes.com listing

export const SMITH_PROPERTY = {
  // Location
  name: "Inspiration Farm",
  fullAddress: "38 Bedford Rd, Greenwich, CT 06831",
  addressLine1: "38 Bedford Rd",
  city: "Greenwich",
  state: "CT",
  postalCode: "06831",
  neighborhood: "Back Country",
  latitude: 41.0867,
  longitude: -73.6892,

  // Property Details
  details: {
    beds: 4,
    baths: 5.5,
    sqft: 4500,
    lotAcres: 4.38,
    lotSqft: 190793,
    yearBuilt: 1970,
    yearRenovated: 2025,
    style: "Colonial",
    propertyType: "SINGLE_FAMILY",
    estimatedValue: 2995000,
    annualTax: 28500,
  },

  // Images from homes.com listing
  images: {
    primary: "https://images.homes.com/listings/102/9662776654-440728702/38-bedford-rd-greenwich-ct-primaryphoto.jpg",
    exterior: [
      "https://images.homes.com/listings/102/9662776654-440728702/38-bedford-rd-greenwich-ct-buildingphoto-2.jpg",
      "https://images.homes.com/listings/102/9662776654-440728702/38-bedford-rd-greenwich-ct-buildingphoto-3.jpg",
    ],
    interior: [
      "https://images.homes.com/listings/102/9662776654-440728702/38-bedford-rd-greenwich-ct-buildingphoto-4.jpg",
      "https://images.homes.com/listings/102/9662776654-440728702/38-bedford-rd-greenwich-ct-buildingphoto-5.jpg",
      "https://images.homes.com/listings/102/9662776654-440728702/38-bedford-rd-greenwich-ct-buildingphoto-6.jpg",
      "https://images.homes.com/listings/102/9662776654-440728702/38-bedford-rd-greenwich-ct-buildingphoto-7.jpg",
    ],
    all: [
      "https://images.homes.com/listings/102/9662776654-440728702/38-bedford-rd-greenwich-ct-primaryphoto.jpg",
      "https://images.homes.com/listings/102/9662776654-440728702/38-bedford-rd-greenwich-ct-buildingphoto-2.jpg",
      "https://images.homes.com/listings/102/9662776654-440728702/38-bedford-rd-greenwich-ct-buildingphoto-3.jpg",
      "https://images.homes.com/listings/102/9662776654-440728702/38-bedford-rd-greenwich-ct-buildingphoto-4.jpg",
      "https://images.homes.com/listings/102/9662776654-440728702/38-bedford-rd-greenwich-ct-buildingphoto-5.jpg",
      "https://images.homes.com/listings/102/9662776654-440728702/38-bedford-rd-greenwich-ct-buildingphoto-6.jpg",
      "https://images.homes.com/listings/102/9662776654-440728702/38-bedford-rd-greenwich-ct-buildingphoto-7.jpg",
    ],
  },

  // Property Highlights
  highlights: [
    { label: "Private Pool", value: "Heated" },
    { label: "Horse Barn", value: "4 Stalls" },
    { label: "Acreage", value: "4.38 acres" },
    { label: "Schools", value: "10/10" },
    { label: "Style", value: "Colonial" },
    { label: "Renovated", value: "2025" },
  ],

  // Features
  features: [
    "Private heated pool",
    "4-stall horse barn with paddocks",
    "Direct access to GRTA riding trails",
    "Finished walkout basement",
    "Home office",
    "Home gym",
    "Gourmet kitchen with Sub-Zero/Wolf/Viking",
    "Primary suite with balcony",
    "Generator (whole house)",
    "Central security system (Ring)",
    "Invisible dog fence",
    "Irrigation system",
    "2-car attached garage",
    "New HVAC (2025)",
    "New electric water heater (2025)",
    "New well with reverse osmosis (2025)",
    "Hardwood floors throughout",
    "Stone fireplace",
    "Bluestone patios",
    "Professional landscaping",
  ],

  // Systems for handyman tracking
  systems: [
    { id: "hvac", name: "HVAC System", type: "HVAC", brand: "Carrier", status: "NEW", notes: "Installed 2025, 10-year warranty" },
    { id: "water-heater", name: "Water Heater", type: "WATER_HEATER", brand: "Rheem", status: "NEW", notes: "Electric, installed 2025" },
    { id: "well", name: "Well System", type: "WELL", brand: "Goulds", status: "NEW", notes: "New 2025 with reverse osmosis" },
    { id: "septic", name: "Septic System", type: "SEPTIC", status: "GOOD", notes: "Pumped annually, last service Oct 2024" },
    { id: "generator", name: "Whole House Generator", type: "GENERATOR", brand: "Generac", status: "GOOD", notes: "Propane, 22kW" },
    { id: "security", name: "Security System", type: "SECURITY", brand: "Ring", status: "ACTIVE", notes: "All entry points, cameras" },
    { id: "pool", name: "Pool Equipment", type: "POOL", brand: "Pentair", status: "GOOD", notes: "Heated, salt water" },
    { id: "irrigation", name: "Irrigation System", type: "IRRIGATION", brand: "Rain Bird", status: "GOOD", notes: "8 zones, winterized" },
    { id: "invisible-fence", name: "Invisible Dog Fence", type: "PET", brand: "Invisible Fence", status: "ACTIVE", notes: "Perimeter complete" },
  ],

  // Access notes for handyman
  accessNotes: "Gate code: 1234. Enter between the two stone pillars. Park in circular driveway. Barn key in lockbox by garage door (code: 5678). Dogs are friendly but will bark.",
};

// Helper function to get a property image
export function getPropertyImage(type: 'primary' | 'exterior' | 'interior' | 'random' = 'primary'): string {
  if (type === 'primary') return SMITH_PROPERTY.images.primary;
  if (type === 'exterior') return SMITH_PROPERTY.images.exterior[Math.floor(Math.random() * SMITH_PROPERTY.images.exterior.length)];
  if (type === 'interior') return SMITH_PROPERTY.images.interior[Math.floor(Math.random() * SMITH_PROPERTY.images.interior.length)];
  return SMITH_PROPERTY.images.all[Math.floor(Math.random() * SMITH_PROPERTY.images.all.length)];
}
```

### 2.2 Update Seed Data with Real Property

**File:** `apps/api/prisma/seed.ts`

Update the Smith household to use the real property data:

```typescript
// When creating demoHousehold, use:
const demoHousehold = await prisma.household.upsert({
  where: { id: 'demo-household-1' },
  update: {},
  create: {
    id: 'demo-household-1',
    name: 'Inspiration Farm',
    description: 'Beautiful Back Country estate with horse barn and pool',
    ownerId: homeownerBob.id,
    managerId: managerSarah.id,
    assignedHandymanId: handymanMike.id,
    subscriptionPlan: 'CONCIERGE',
    subscriptionStatus: 'ACTIVE',
    conciergeEnabled: true,
    monthlyVisitDay: 15,
  },
});

// Update homeProfile:
await prisma.homeProfile.upsert({
  where: { householdId: demoHousehold.id },
  update: {},
  create: {
    householdId: demoHousehold.id,
    propertyType: 'SINGLE_FAMILY',
    addressLine1: '38 Bedford Rd',
    city: 'Greenwich',
    state: 'CT',
    postalCode: '06831',
    latitude: 41.0867,
    longitude: -73.6892,
    squareFeet: 4500,
    lotSquareFeet: 190793,
    yearBuilt: 1970,
    bedrooms: 4,
    bathrooms: 5.5,
    stories: 2,
    garageSpaces: 2,
    hasPool: true,
    hasBasement: true,
    hasSeptic: true,
    hasWell: true,
    hasGenerator: true,
    features: [
      'Private heated pool',
      '4-stall horse barn',
      'GRTA trail access',
      'Finished walkout basement',
      'Home office',
      'Home gym',
      'Sub-Zero/Wolf/Viking kitchen',
      'Primary suite with balcony',
      'Whole house generator',
      'Ring security system',
      'Invisible dog fence',
      'Irrigation system',
    ],
    images: [
      'https://images.homes.com/listings/102/9662776654-440728702/38-bedford-rd-greenwich-ct-primaryphoto.jpg',
      'https://images.homes.com/listings/102/9662776654-440728702/38-bedford-rd-greenwich-ct-buildingphoto-2.jpg',
      'https://images.homes.com/listings/102/9662776654-440728702/38-bedford-rd-greenwich-ct-buildingphoto-3.jpg',
      'https://images.homes.com/listings/102/9662776654-440728702/38-bedford-rd-greenwich-ct-buildingphoto-4.jpg',
      'https://images.homes.com/listings/102/9662776654-440728702/38-bedford-rd-greenwich-ct-buildingphoto-5.jpg',
      'https://images.homes.com/listings/102/9662776654-440728702/38-bedford-rd-greenwich-ct-buildingphoto-6.jpg',
      'https://images.homes.com/listings/102/9662776654-440728702/38-bedford-rd-greenwich-ct-buildingphoto-7.jpg',
    ],
    accessNotes: 'Gate code: 1234. Enter between the two stone pillars. Park in circular driveway. Barn key in lockbox by garage door (code: 5678). Dogs are friendly but will bark.',
  },
});
```

---

## PART 3: TYPOGRAPHY & CONTRAST

### 3.1 Update Global CSS

**File:** `apps/web/src/app/globals.css`

Key changes:
- Serif font (Playfair Display) ONLY for h1 page titles
- Sans-serif (Inter) for everything else
- White text on ALL dark backgrounds
- Consistent card styling

Add these critical CSS classes:

```css
/* Page titles - only serif usage */
.page-title {
  @apply font-serif text-2xl sm:text-3xl font-bold text-warm-900;
}

/* Dark cards must have white text */
.card-green,
.card-green h1, .card-green h2, .card-green h3, .card-green h4,
.card-green .card-title, .card-green .stat-value {
  @apply text-white;
}

.card-green p, .card-green .card-description, .card-green .stat-label {
  @apply text-white/80;
}

.card-slate,
.card-slate h1, .card-slate h2, .card-slate h3, .card-slate h4,
.card-slate .card-title, .card-slate .stat-value {
  @apply text-white;
}

.card-slate p, .card-slate .card-description, .card-slate .stat-label {
  @apply text-white/70;
}
```

### 3.2 Fix All Dark Background Text

Search all files in `apps/web/src/app/` and fix:

```tsx
// ❌ WRONG - Black text on green
<div className="bg-gradient-to-br from-haven-500 to-haven-600 p-6">
  <h2 className="text-warm-900">Title</h2>  // INVISIBLE!
</div>

// ✅ CORRECT - White text on green
<div className="card-green p-6">
  <h2 className="text-white">Title</h2>  // VISIBLE!
</div>
```

---

## PART 4: DICEBEAR AVATARS

### 4.1 Create Avatar Helper

**Create file:** `apps/web/src/lib/avatars.ts`

```typescript
type AvatarStyle = 'lorelei' | 'notionists' | 'avataaars';

export function getAvatarUrl(seed: string, style: AvatarStyle = 'lorelei', size: number = 128): string {
  const encodedSeed = encodeURIComponent(seed.toLowerCase().trim());
  return `https://api.dicebear.com/7.x/${style}/svg?seed=${encodedSeed}&size=${size}&backgroundColor=b6e3f4,c0aede,d1d4f9,ffd5dc,ffdfbf`;
}

export function getUserAvatar(name: string): string {
  const avatarMap: Record<string, string> = {
    'bob': getAvatarUrl('bob-smith-homeowner'),
    'bob smith': getAvatarUrl('bob-smith-homeowner'),
    'alice': getAvatarUrl('alice-smith-wife'),
    'alice smith': getAvatarUrl('alice-smith-wife'),
    'emma': getAvatarUrl('emma-smith-daughter'),
    'emma smith': getAvatarUrl('emma-smith-daughter'),
    'jack': getAvatarUrl('jack-smith-son'),
    'jack smith': getAvatarUrl('jack-smith-son'),
    'sarah': getAvatarUrl('sarah-harrison-manager'),
    'sarah harrison': getAvatarUrl('sarah-harrison-manager'),
    'mike': getAvatarUrl('mike-rodriguez-handyman'),
    'mike rodriguez': getAvatarUrl('mike-rodriguez-handyman'),
  };
  
  const key = name.toLowerCase().trim();
  return avatarMap[key] || getAvatarUrl(name);
}

export function getInitials(name: string): string {
  return name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2);
}
```

### 4.2 Replace All Avatar Usages

Replace Unsplash photo URLs with DiceBear:

```tsx
// ❌ OLD
<Image src="https://images.unsplash.com/photo-..." />

// ✅ NEW
import { getUserAvatar } from '@/lib/avatars';
<img src={getUserAvatar('Sarah Harrison')} className="w-10 h-10 rounded-full" />
```

---

## PART 5: VENDOR IMPROVEMENTS

### 5.1 Fix Map Card Overflow

Ensure vendor popup card has `overflow-hidden` and all buttons are inside the container.

### 5.2 Add Unique Vendor Images

**Update:** `apps/web/src/lib/images.ts`

```typescript
export const vendorImages: Record<string, string[]> = {
  plumbing: ['https://images.unsplash.com/photo-1585704032915-c3400ca199e7?w=400&q=80'],
  electrical: ['https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=400&q=80'],
  hvac: ['https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=400&q=80'],
  landscaping: ['https://images.unsplash.com/photo-1558904541-efa843a96f01?w=400&q=80'],
  // ... add more categories
};

export function getVendorImage(category: string, index: number = 0): string {
  const cat = category.toLowerCase().replace(/[^a-z]/g, '');
  const images = vendorImages[cat] || vendorImages.general;
  return images[index % images.length];
}
```

### 5.3 Add 25+ Vendors to Seed

Add comprehensive vendor data with realistic Greenwich-area businesses.

---

## PART 6: FAMILY & SEED DATA

### 6.1 Add Family Members

Add to seed.ts after household creation:

```typescript
// Bob - Head of Household
await prisma.householdMember.upsert({
  where: { id: 'member-bob' },
  create: {
    id: 'member-bob',
    householdId: demoHousehold.id,
    userId: homeownerBob.id,
    firstName: 'Bob',
    lastName: 'Smith',
    relationship: 'HEAD_OF_HOUSEHOLD',
    email: 'bob@example.com',
    phone: '+1 (203) 555-0001',
    isEmergencyContact: true,
    isPrimaryContact: true,
  },
});

// Alice - Wife
await prisma.householdMember.upsert({
  where: { id: 'member-alice' },
  create: {
    id: 'member-alice',
    householdId: demoHousehold.id,
    firstName: 'Alice',
    lastName: 'Smith',
    relationship: 'SPOUSE',
    email: 'alice.smith@example.com',
    isEmergencyContact: true,
  },
});

// Emma - Daughter (14)
// Jack - Son (10)  
// Max - Dog
```

---

## PART 7: NULL SAFETY FIXES

### 7.1 Handyman Portal

**File:** `apps/web/src/app/handyman/page.tsx`

Add null checks:

```typescript
// Always check for null/undefined
const address = task.household?.homeProfile?.addressLine1 || 'Address not set';
const householdName = task.household?.name || 'Unknown Household';
```

### 7.2 Vendor Portal  

**File:** `apps/web/src/app/vendor/page.tsx`

Add null checks for all data access.

---

## VERIFICATION CHECKLIST

After running the build:

### Homepage
- [ ] Hero message emphasizes accessibility (not just wealthy)
- [ ] Pricing starts at $99 (Starter tier)
- [ ] Clear value proposition (one bill, one contact, zero hassle)
- [ ] Full service list showing everything Haven handles
- [ ] FAQ addresses "is this only for rich people?"

### Property
- [ ] All images show 38 Bedford Rd
- [ ] Address displays correctly
- [ ] Property details accurate (4 bed, 5.5 bath, etc.)

### Typography
- [ ] Only h1 page titles use serif font
- [ ] All other text uses sans-serif
- [ ] White text on all dark backgrounds
- [ ] No black-on-green or black-on-slate issues

### Avatars
- [ ] All users show DiceBear illustrated avatars
- [ ] Each user has unique avatar

### Family
- [ ] Shows Bob, Alice, Emma, Jack, Max

---

## RUN ORDER

```bash
# 1. Run Claude with this prompt
cd /Users/tomburke/Projects/Housing-Manager
claude --dangerously-skip-permissions

# 2. After build, reset database
cd apps/api
pnpm prisma db push --force-reset
pnpm prisma db seed
pnpm dev

# 3. Start frontend (new terminal)
cd apps/web
pnpm dev
```

Test at http://localhost:3000

🏠✨
