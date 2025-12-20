'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Shield,
  Plane,
  Calendar,
  FileText,
  Home,
  Wrench,
  Users,
  Sparkles,
  Check,
  Star,
  Lock,
  BadgeCheck,
  ArrowRight,
  DollarSign,
  Heart,
  Wifi,
  Key,
  Bell,
  Activity,
  MessageSquare,
  CheckCircle2,
  Clock,
  Gauge,
  Receipt,
  Filter,
  Thermometer,
  MapPin,
  Building,
} from 'lucide-react';

// ============================================================================
// ROTATING WORDS CONFIG
// ============================================================================

const rotatingWords = [
  { word: 'Home', color: 'text-emerald-600' },
  { word: 'Finances', color: 'text-amber-500' },
  { word: 'Projects', color: 'text-orange-500' },
  { word: 'Travel', color: 'text-sky-500' },
  { word: 'Life', color: 'text-indigo-600' },
];

// ============================================================================
// HERO SECTION
// ============================================================================

function HeroSection() {
  const [currentIndex, setCurrentIndex] = useState(0);
  const [isPaused, setIsPaused] = useState(false);

  useEffect(() => {
    if (isPaused) return;

    const interval = setInterval(() => {
      setCurrentIndex((prev) => {
        const next = prev + 1;
        // Pause on "Life" (last word)
        if (next === rotatingWords.length - 1) {
          setIsPaused(true);
          setTimeout(() => {
            setIsPaused(false);
            setCurrentIndex(0);
          }, 4000);
        }
        return next < rotatingWords.length ? next : 0;
      });
    }, 2000);

    return () => clearInterval(interval);
  }, [isPaused]);

  return (
    <section className="pt-32 pb-20 px-4 sm:px-6 lg:px-8 overflow-hidden">
      <div className="max-w-7xl mx-auto">
        <div className="grid lg:grid-cols-2 gap-12 lg:gap-16 items-center">
          {/* Left Column - Text */}
          <div>
            <div className="inline-flex items-center gap-2 px-4 py-2 bg-emerald-50 rounded-full mb-8">
              <Sparkles className="w-4 h-4 text-emerald-700" />
              <span className="text-sm font-medium text-emerald-800">Own your home. Live like you rent.</span>
            </div>

            <h1 className="font-serif text-4xl sm:text-5xl lg:text-6xl font-medium text-emerald-950 leading-tight tracking-tight mb-6">
              The Operating System
              <br />
              for Your{' '}
              <span className="relative inline-block w-[200px] sm:w-[280px] h-[1.2em] align-bottom overflow-hidden">
                <AnimatePresence mode="wait">
                  <motion.span
                    key={currentIndex}
                    initial={{ y: 50, opacity: 0 }}
                    animate={{ y: 0, opacity: 1 }}
                    exit={{ y: -50, opacity: 0 }}
                    transition={{ duration: 0.4, ease: 'easeInOut' }}
                    className={`absolute left-0 ${rotatingWords[currentIndex]?.color ?? 'text-emerald-600'}`}
                  >
                    {rotatingWords[currentIndex]?.word ?? 'Home'}.
                  </motion.span>
                </AnimatePresence>
              </span>
            </h1>

            <p className="text-lg sm:text-xl text-slate-600 max-w-xl mb-8 leading-relaxed">
              The ease of renting, with the equity of owning. A dedicated Home Manager to handle the repairs, the bills, and the logistics. You just enjoy the house.
            </p>

            <div className="flex flex-col sm:flex-row items-start gap-4">
              <Link
                href="/register"
                className="inline-flex items-center justify-center gap-2 px-8 py-4 bg-emerald-950 text-white text-lg font-medium rounded-xl hover:bg-emerald-900 transition-colors shadow-lg shadow-emerald-950/20"
              >
                Check Address Eligibility
                <ArrowRight className="w-5 h-5" />
              </Link>
              <a
                href="#one-bill"
                className="inline-flex items-center justify-center gap-2 px-8 py-4 text-emerald-950 text-lg font-medium hover:text-emerald-700 transition-colors"
              >
                See How It Works
              </a>
            </div>

            {/* Trust indicators */}
            <div className="flex flex-wrap items-center gap-6 mt-12 pt-8 border-t border-slate-200">
              <div className="flex items-center gap-2 text-slate-500">
                <Lock className="w-5 h-5" />
                <span className="text-sm font-medium">FDIC-Insured</span>
              </div>
              <div className="flex items-center gap-2 text-slate-500">
                <Shield className="w-5 h-5" />
                <span className="text-sm font-medium">$2M Coverage</span>
              </div>
              <div className="flex items-center gap-2 text-slate-500">
                <BadgeCheck className="w-5 h-5" />
                <span className="text-sm font-medium">Vetted Pros</span>
              </div>
            </div>
          </div>

          {/* Right Column - Floating UI Stack (Glassmorphism) */}
          <div className="relative h-[500px] lg:h-[600px] hidden lg:block">
            {/* Center - Dashboard "Everything Systems Normal" */}
            <motion.div
              initial={{ opacity: 0, y: 30 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2, duration: 0.6 }}
              className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[340px] bg-white rounded-2xl shadow-2xl shadow-slate-900/15 border border-slate-200 overflow-hidden z-20"
            >
              <div className="p-5 border-b border-slate-100">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-emerald-100 rounded-xl flex items-center justify-center">
                      <Home className="w-5 h-5 text-emerald-600" />
                    </div>
                    <div>
                      <p className="text-sm font-semibold text-slate-900">House Status</p>
                      <p className="text-xs text-slate-500">Real-time monitoring</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-1.5 px-3 py-1.5 bg-emerald-100 rounded-full">
                    <div className="w-2 h-2 bg-emerald-500 rounded-full animate-pulse" />
                    <span className="text-xs font-semibold text-emerald-700">All Systems Normal</span>
                  </div>
                </div>
              </div>
              <div className="p-5 space-y-3">
                <div className="flex items-center justify-between p-3 bg-slate-50 rounded-xl">
                  <div className="flex items-center gap-3">
                    <Thermometer className="w-5 h-5 text-slate-500" />
                    <span className="text-sm text-slate-700">HVAC</span>
                  </div>
                  <span className="text-sm font-medium text-emerald-600">72°F</span>
                </div>
                <div className="flex items-center justify-between p-3 bg-slate-50 rounded-xl">
                  <div className="flex items-center gap-3">
                    <Shield className="w-5 h-5 text-slate-500" />
                    <span className="text-sm text-slate-700">Security</span>
                  </div>
                  <span className="text-sm font-medium text-emerald-600">Armed</span>
                </div>
                <div className="flex items-center justify-between p-3 bg-slate-50 rounded-xl">
                  <div className="flex items-center gap-3">
                    <DollarSign className="w-5 h-5 text-slate-500" />
                    <span className="text-sm text-slate-700">Bills This Month</span>
                  </div>
                  <span className="text-sm font-medium text-emerald-600">All Paid</span>
                </div>
              </div>
            </motion.div>

            {/* Left - Money Card (Bills Consolidated) */}
            <motion.div
              initial={{ opacity: 0, x: -40 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.4, duration: 0.6 }}
              className="absolute top-16 left-0 w-[280px] backdrop-blur-xl bg-white/90 rounded-2xl shadow-2xl shadow-slate-900/10 border border-white/50 overflow-hidden z-10"
            >
              <div className="p-4">
                <div className="flex items-center gap-2 mb-4">
                  <div className="w-8 h-8 bg-amber-100 rounded-lg flex items-center justify-center">
                    <Receipt className="w-4 h-4 text-amber-600" />
                  </div>
                  <span className="text-sm font-semibold text-slate-900">Monthly Statement</span>
                </div>
                <div className="space-y-2 mb-4">
                  <div className="flex items-center justify-between text-xs">
                    <span className="text-slate-500">Electric (SCE)</span>
                    <span className="text-slate-700">$142</span>
                  </div>
                  <div className="flex items-center justify-between text-xs">
                    <span className="text-slate-500">Landscaping</span>
                    <span className="text-slate-700">$280</span>
                  </div>
                  <div className="flex items-center justify-between text-xs">
                    <span className="text-slate-500">Pool Service</span>
                    <span className="text-slate-700">$150</span>
                  </div>
                  <div className="flex items-center justify-between text-xs">
                    <span className="text-slate-500">+ 2 more</span>
                    <span className="text-slate-700">$340</span>
                  </div>
                </div>
                <div className="pt-3 border-t border-slate-200">
                  <div className="flex items-center justify-between">
                    <span className="text-sm font-semibold text-slate-900">One Payment</span>
                    <span className="text-lg font-bold text-emerald-600">$912</span>
                  </div>
                </div>
              </div>
            </motion.div>

            {/* Right - Chat Bubble from Manager */}
            <motion.div
              initial={{ opacity: 0, x: 40 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.6, duration: 0.6 }}
              className="absolute bottom-20 right-0 w-[300px] backdrop-blur-xl bg-white/90 rounded-2xl shadow-2xl shadow-slate-900/10 border border-white/50 overflow-hidden z-10"
            >
              <div className="p-4">
                <div className="flex items-center gap-3 mb-3">
                  <div className="w-10 h-10 bg-emerald-600 rounded-full flex items-center justify-center">
                    <span className="text-sm font-bold text-white">SM</span>
                  </div>
                  <div>
                    <p className="text-sm font-semibold text-slate-900">Steve, Your Manager</p>
                    <p className="text-xs text-slate-500">Just now</p>
                  </div>
                </div>
                <div className="bg-emerald-50 rounded-xl p-3 border border-emerald-100">
                  <p className="text-sm text-slate-700">
                    &quot;I&apos;ve handled the HVAC scheduling for you. Tech arrives Tuesday 10am. I&apos;ll be there to let them in.&quot;
                  </p>
                </div>
                <div className="flex items-center gap-2 mt-3">
                  <CheckCircle2 className="w-4 h-4 text-emerald-500" />
                  <span className="text-xs text-emerald-600 font-medium">Confirmed & Scheduled</span>
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
// CORE VALUE A: ONE BILL REVOLUTION
// ============================================================================

function OneBillSection() {
  return (
    <section id="one-bill" className="py-24 px-4 sm:px-6 lg:px-8 bg-white">
      <div className="max-w-7xl mx-auto">
        <div className="grid lg:grid-cols-2 gap-12 lg:gap-16 items-center">
          {/* Left - Text */}
          <div>
            <div className="inline-flex items-center gap-2 px-3 py-1.5 bg-amber-100 rounded-full mb-6">
              <DollarSign className="w-4 h-4 text-amber-700" />
              <span className="text-sm font-medium text-amber-800">Financial Consolidation</span>
            </div>

            <h2 className="font-serif text-3xl sm:text-4xl lg:text-5xl font-medium text-emerald-950 mb-6">
              20 Vendors.<br />One Monthly Statement.
            </h2>

            <div className="mb-8">
              <p className="text-lg text-slate-500 mb-4 italic">
                &quot;Stop chasing invoices from the pool guy, the landscaper, and the tutor.&quot;
              </p>
              <p className="text-lg text-slate-600 leading-relaxed">
                Your Manager pays every service provider, utility, and subscription from your House Wallet. You get one clean, itemized monthly statement. You verify; we pay.
              </p>
            </div>

            <div className="space-y-4">
              <div className="flex items-start gap-3">
                <div className="w-8 h-8 bg-emerald-100 rounded-lg flex items-center justify-center flex-shrink-0 mt-0.5">
                  <Check className="w-4 h-4 text-emerald-600" />
                </div>
                <div>
                  <p className="font-medium text-slate-900">Automatic Bill Pay</p>
                  <p className="text-sm text-slate-500">All vendors paid on time, every time</p>
                </div>
              </div>
              <div className="flex items-start gap-3">
                <div className="w-8 h-8 bg-emerald-100 rounded-lg flex items-center justify-center flex-shrink-0 mt-0.5">
                  <Check className="w-4 h-4 text-emerald-600" />
                </div>
                <div>
                  <p className="font-medium text-slate-900">Approval Workflow</p>
                  <p className="text-sm text-slate-500">You approve big expenses with one tap</p>
                </div>
              </div>
              <div className="flex items-start gap-3">
                <div className="w-8 h-8 bg-emerald-100 rounded-lg flex items-center justify-center flex-shrink-0 mt-0.5">
                  <Check className="w-4 h-4 text-emerald-600" />
                </div>
                <div>
                  <p className="font-medium text-slate-900">FDIC-Insured Wallet</p>
                  <p className="text-sm text-slate-500">Your money is always protected</p>
                </div>
              </div>
            </div>
          </div>

          {/* Right - Money Page UI Mock */}
          <div className="relative">
            <div className="bg-slate-100 rounded-2xl p-6 shadow-xl">
              {/* Header */}
              <div className="flex items-center justify-between mb-6">
                <div>
                  <p className="text-sm text-slate-500">December 2024</p>
                  <p className="text-2xl font-bold text-slate-900">$4,847.00</p>
                </div>
                <div className="flex items-center gap-2 px-3 py-1.5 bg-emerald-100 rounded-full">
                  <CheckCircle2 className="w-4 h-4 text-emerald-600" />
                  <span className="text-sm font-medium text-emerald-700">All Paid</span>
                </div>
              </div>

              {/* Budget Gauge */}
              <div className="bg-white rounded-xl p-4 mb-4">
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm font-medium text-slate-700">Monthly Budget</span>
                  <span className="text-sm text-slate-500">$4,847 / $5,500</span>
                </div>
                <div className="h-3 bg-slate-100 rounded-full overflow-hidden">
                  <div className="h-full w-[88%] bg-gradient-to-r from-emerald-500 to-emerald-400 rounded-full" />
                </div>
              </div>

              {/* Approvals List */}
              <div className="bg-white rounded-xl p-4">
                <p className="text-sm font-semibold text-slate-900 mb-3">Recent Payments</p>
                <div className="space-y-3">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 bg-blue-100 rounded-lg flex items-center justify-center">
                        <Building className="w-4 h-4 text-blue-600" />
                      </div>
                      <div>
                        <p className="text-sm font-medium text-slate-900">SCE Electric</p>
                        <p className="text-xs text-slate-500">Dec 15</p>
                      </div>
                    </div>
                    <span className="text-sm font-medium text-slate-900">$187.42</span>
                  </div>
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 bg-green-100 rounded-lg flex items-center justify-center">
                        <Sparkles className="w-4 h-4 text-green-600" />
                      </div>
                      <div>
                        <p className="text-sm font-medium text-slate-900">Green Thumb Landscaping</p>
                        <p className="text-xs text-slate-500">Dec 12</p>
                      </div>
                    </div>
                    <span className="text-sm font-medium text-slate-900">$340.00</span>
                  </div>
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 bg-cyan-100 rounded-lg flex items-center justify-center">
                        <Activity className="w-4 h-4 text-cyan-600" />
                      </div>
                      <div>
                        <p className="text-sm font-medium text-slate-900">Crystal Clear Pools</p>
                        <p className="text-xs text-slate-500">Dec 10</p>
                      </div>
                    </div>
                    <span className="text-sm font-medium text-slate-900">$175.00</span>
                  </div>
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
// CORE VALUE B: SINGLE POINT OF CONTACT
// ============================================================================

function SingleContactSection() {
  return (
    <section className="py-24 px-4 sm:px-6 lg:px-8 bg-emerald-950">
      <div className="max-w-7xl mx-auto">
        <div className="grid lg:grid-cols-2 gap-12 lg:gap-16 items-center">
          {/* Left - Messages UI Mock */}
          <div className="order-2 lg:order-1">
            <div className="bg-white rounded-2xl shadow-2xl overflow-hidden">
              {/* Header */}
              <div className="p-4 border-b border-slate-100 flex items-center gap-3">
                <div className="w-12 h-12 bg-emerald-600 rounded-full flex items-center justify-center">
                  <span className="text-lg font-bold text-white">SM</span>
                </div>
                <div className="flex-1">
                  <p className="font-semibold text-slate-900">Steve, Your Manager</p>
                  <p className="text-sm text-emerald-600">Online • Handles everything</p>
                </div>
                <div className="w-10 h-10 bg-emerald-50 rounded-full flex items-center justify-center">
                  <Star className="w-5 h-5 text-emerald-600" />
                </div>
              </div>

              {/* Messages */}
              <div className="p-4 space-y-4 bg-slate-50 min-h-[300px]">
                {/* User message */}
                <div className="flex justify-end">
                  <div className="bg-emerald-600 text-white rounded-2xl rounded-br-md px-4 py-2 max-w-[80%]">
                    <p className="text-sm">The roof is leaking in the guest room. Can you handle it?</p>
                    <p className="text-xs text-emerald-200 mt-1">10:32 AM</p>
                  </div>
                </div>

                {/* Manager response */}
                <div className="flex justify-start">
                  <div className="bg-white rounded-2xl rounded-bl-md px-4 py-2 max-w-[80%] shadow-sm">
                    <p className="text-sm text-slate-700">On it. I&apos;ve already contacted Ace Roofing (they did your neighbor&apos;s roof last month). They can come tomorrow at 9am. I&apos;ll meet them at the house.</p>
                    <p className="text-xs text-slate-400 mt-1">10:34 AM</p>
                  </div>
                </div>

                {/* Status update */}
                <div className="flex justify-start">
                  <div className="bg-white rounded-2xl rounded-bl-md px-4 py-3 max-w-[80%] shadow-sm border border-emerald-100">
                    <div className="flex items-center gap-2 mb-2">
                      <CheckCircle2 className="w-4 h-4 text-emerald-500" />
                      <span className="text-xs font-semibold text-emerald-600">APPOINTMENT CONFIRMED</span>
                    </div>
                    <p className="text-sm font-medium text-slate-900">Ace Roofing Co.</p>
                    <p className="text-xs text-slate-500">Tomorrow, 9:00 AM • Quote: $850-$1,200</p>
                  </div>
                </div>

                {/* Manager follow-up */}
                <div className="flex justify-start">
                  <div className="bg-white rounded-2xl rounded-bl-md px-4 py-2 max-w-[80%] shadow-sm">
                    <p className="text-sm text-slate-700">I&apos;ll send you the quote for approval before any work starts. Anything else?</p>
                    <p className="text-xs text-slate-400 mt-1">10:35 AM</p>
                  </div>
                </div>
              </div>

              {/* Input */}
              <div className="p-4 border-t border-slate-100">
                <div className="flex items-center gap-3">
                  <div className="flex-1 bg-slate-100 rounded-full px-4 py-2">
                    <span className="text-sm text-slate-400">Message Steve...</span>
                  </div>
                  <div className="w-10 h-10 bg-emerald-600 rounded-full flex items-center justify-center">
                    <ArrowRight className="w-5 h-5 text-white" />
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Right - Text */}
          <div className="order-1 lg:order-2">
            <div className="inline-flex items-center gap-2 px-3 py-1.5 bg-emerald-900 rounded-full mb-6">
              <MessageSquare className="w-4 h-4 text-emerald-300" />
              <span className="text-sm font-medium text-emerald-200">Digital Secretary</span>
            </div>

            <h2 className="font-serif text-3xl sm:text-4xl lg:text-5xl font-medium text-white mb-6">
              You Have a Guy<br />for That.
            </h2>

            <div className="mb-8">
              <p className="text-lg text-emerald-300 mb-4 italic">
                &quot;When something breaks, you shouldn&apos;t have to be the project manager.&quot;
              </p>
              <p className="text-lg text-emerald-100 leading-relaxed">
                One dedicated Manager. One dedicated Handyman. Whether it&apos;s a leaky roof or booking a flight, you text <em>one</em> thread. We coordinate the rest.
              </p>
            </div>

            <div className="space-y-4">
              <div className="flex items-center gap-3 p-4 bg-emerald-900/50 rounded-xl border border-emerald-800">
                <div className="w-10 h-10 bg-emerald-800 rounded-full flex items-center justify-center">
                  <Users className="w-5 h-5 text-emerald-300" />
                </div>
                <div>
                  <p className="font-medium text-white">Your Dedicated Team</p>
                  <p className="text-sm text-emerald-300">Manager + Handyman assigned to your home</p>
                </div>
              </div>
              <div className="flex items-center gap-3 p-4 bg-emerald-900/50 rounded-xl border border-emerald-800">
                <div className="w-10 h-10 bg-emerald-800 rounded-full flex items-center justify-center">
                  <Plane className="w-5 h-5 text-emerald-300" />
                </div>
                <div>
                  <p className="font-medium text-white">Beyond Home Repairs</p>
                  <p className="text-sm text-emerald-300">Travel, logistics, research—we handle it all</p>
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
// CORE VALUE C: PROACTIVE CARE
// ============================================================================

function ProactiveCareSection() {
  return (
    <section className="py-24 px-4 sm:px-6 lg:px-8 bg-slate-50">
      <div className="max-w-7xl mx-auto">
        <div className="grid lg:grid-cols-2 gap-12 lg:gap-16 items-center">
          {/* Left - Text */}
          <div>
            <div className="inline-flex items-center gap-2 px-3 py-1.5 bg-emerald-100 rounded-full mb-6">
              <Wrench className="w-4 h-4 text-emerald-700" />
              <span className="text-sm font-medium text-emerald-800">The Superintendent Model</span>
            </div>

            <h2 className="font-serif text-3xl sm:text-4xl lg:text-5xl font-medium text-emerald-950 mb-6">
              We Fix It<br />Before It Breaks.
            </h2>

            <div className="mb-8">
              <p className="text-lg text-slate-500 mb-4 italic">
                &quot;Home maintenance is usually reactive and expensive.&quot;
              </p>
              <p className="text-lg text-slate-600 leading-relaxed">
                Just like a luxury apartment building, we perform monthly preventative rounds. Changing filters, checking sensors, and spotting issues so they never become emergencies.
              </p>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="bg-white rounded-xl p-4 border border-slate-200">
                <Filter className="w-6 h-6 text-emerald-600 mb-2" />
                <p className="font-medium text-slate-900">Filter Changes</p>
                <p className="text-sm text-slate-500">Monthly HVAC service</p>
              </div>
              <div className="bg-white rounded-xl p-4 border border-slate-200">
                <Activity className="w-6 h-6 text-emerald-600 mb-2" />
                <p className="font-medium text-slate-900">System Checks</p>
                <p className="text-sm text-slate-500">Sensors & detectors</p>
              </div>
              <div className="bg-white rounded-xl p-4 border border-slate-200">
                <Clock className="w-6 h-6 text-emerald-600 mb-2" />
                <p className="font-medium text-slate-900">Warranty Tracking</p>
                <p className="text-sm text-slate-500">Never miss a claim</p>
              </div>
              <div className="bg-white rounded-xl p-4 border border-slate-200">
                <Calendar className="w-6 h-6 text-emerald-600 mb-2" />
                <p className="font-medium text-slate-900">Scheduled Service</p>
                <p className="text-sm text-slate-500">Auto-booked pros</p>
              </div>
            </div>
          </div>

          {/* Right - Maintenance Page UI Mock */}
          <div className="relative">
            <div className="bg-white rounded-2xl p-6 shadow-xl border border-slate-200">
              {/* Asset Health Gauge */}
              <div className="text-center mb-6">
                <div className="relative inline-flex items-center justify-center">
                  <svg className="w-40 h-40 transform -rotate-90">
                    <circle
                      cx="80"
                      cy="80"
                      r="70"
                      stroke="#e2e8f0"
                      strokeWidth="12"
                      fill="none"
                    />
                    <circle
                      cx="80"
                      cy="80"
                      r="70"
                      stroke="url(#gaugeGradient)"
                      strokeWidth="12"
                      fill="none"
                      strokeDasharray={`${2 * Math.PI * 70 * 0.98} ${2 * Math.PI * 70}`}
                      strokeLinecap="round"
                    />
                    <defs>
                      <linearGradient id="gaugeGradient" x1="0%" y1="0%" x2="100%" y2="0%">
                        <stop offset="0%" stopColor="#10b981" />
                        <stop offset="100%" stopColor="#059669" />
                      </linearGradient>
                    </defs>
                  </svg>
                  <div className="absolute inset-0 flex flex-col items-center justify-center">
                    <span className="text-4xl font-bold text-emerald-600">98%</span>
                    <span className="text-sm text-slate-500">Health Score</span>
                  </div>
                </div>
              </div>

              {/* Systems Status */}
              <div className="space-y-3">
                <p className="text-sm font-semibold text-slate-900 mb-2">System Status</p>
                <div className="flex items-center justify-between p-3 bg-emerald-50 rounded-xl border border-emerald-100">
                  <div className="flex items-center gap-3">
                    <Gauge className="w-5 h-5 text-emerald-600" />
                    <span className="text-sm font-medium text-slate-900">HVAC System</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <CheckCircle2 className="w-4 h-4 text-emerald-500" />
                    <span className="text-sm text-emerald-600">Optimal</span>
                  </div>
                </div>
                <div className="flex items-center justify-between p-3 bg-emerald-50 rounded-xl border border-emerald-100">
                  <div className="flex items-center gap-3">
                    <Activity className="w-5 h-5 text-emerald-600" />
                    <span className="text-sm font-medium text-slate-900">Water Heater</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <CheckCircle2 className="w-4 h-4 text-emerald-500" />
                    <span className="text-sm text-emerald-600">Optimal</span>
                  </div>
                </div>
                <div className="flex items-center justify-between p-3 bg-amber-50 rounded-xl border border-amber-100">
                  <div className="flex items-center gap-3">
                    <Filter className="w-5 h-5 text-amber-600" />
                    <span className="text-sm font-medium text-slate-900">Air Filters</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <Clock className="w-4 h-4 text-amber-500" />
                    <span className="text-sm text-amber-600">Due in 5 days</span>
                  </div>
                </div>
              </div>

              {/* Next Visit */}
              <div className="mt-4 p-3 bg-slate-50 rounded-xl">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-xs text-slate-500">Next Handyman Visit</p>
                    <p className="text-sm font-semibold text-slate-900">Tuesday, Dec 24 at 10am</p>
                  </div>
                  <div className="w-10 h-10 bg-emerald-100 rounded-full flex items-center justify-center">
                    <Wrench className="w-5 h-5 text-emerald-600" />
                  </div>
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
// THE NETWORK (TRUST & VERIFICATION)
// ============================================================================

function NetworkSection() {
  return (
    <section id="community" className="py-24 px-4 sm:px-6 lg:px-8 bg-white">
      <div className="max-w-7xl mx-auto">
        <div className="grid lg:grid-cols-2 gap-12 items-center">
          {/* Left - Map Visual */}
          <div className="relative order-2 lg:order-1">
            <div className="relative rounded-2xl overflow-hidden shadow-2xl shadow-slate-900/20 bg-slate-100 h-[420px]">
              {/* Map Background */}
              <Image
                src="https://images.unsplash.com/photo-1524661135-423995f22d0b?w=800&q=80"
                alt="Neighborhood map"
                fill
                className="object-cover opacity-50"
              />
              {/* Overlay */}
              <div className="absolute inset-0 bg-gradient-to-t from-slate-900/90 via-slate-900/40 to-slate-900/20" />

              {/* Emerald Pins */}
              <div className="absolute inset-0 p-8">
                <div className="relative w-full h-full">
                  {/* Vendor pins with labels */}
                  <div className="absolute top-[15%] left-[25%]">
                    <div className="relative group cursor-pointer">
                      <div className="w-5 h-5 bg-emerald-500 rounded-full shadow-lg shadow-emerald-500/50 animate-pulse" />
                      <div className="absolute -top-8 left-1/2 -translate-x-1/2 opacity-0 group-hover:opacity-100 transition-opacity">
                        <span className="px-2 py-1 bg-white rounded text-xs font-medium text-slate-900 whitespace-nowrap shadow-lg">Ace Roofing</span>
                      </div>
                    </div>
                  </div>
                  <div className="absolute top-[30%] left-[60%]">
                    <div className="relative group cursor-pointer">
                      <div className="w-5 h-5 bg-emerald-500 rounded-full shadow-lg shadow-emerald-500/50 animate-pulse" style={{ animationDelay: '0.3s' }} />
                      <div className="absolute -top-8 left-1/2 -translate-x-1/2 opacity-0 group-hover:opacity-100 transition-opacity">
                        <span className="px-2 py-1 bg-white rounded text-xs font-medium text-slate-900 whitespace-nowrap shadow-lg">Green Thumb</span>
                      </div>
                    </div>
                  </div>
                  <div className="absolute top-[50%] left-[35%]">
                    <div className="relative group cursor-pointer">
                      <div className="w-5 h-5 bg-emerald-500 rounded-full shadow-lg shadow-emerald-500/50 animate-pulse" style={{ animationDelay: '0.6s' }} />
                      <div className="absolute -top-8 left-1/2 -translate-x-1/2 opacity-0 group-hover:opacity-100 transition-opacity">
                        <span className="px-2 py-1 bg-white rounded text-xs font-medium text-slate-900 whitespace-nowrap shadow-lg">Crystal Pools</span>
                      </div>
                    </div>
                  </div>
                  <div className="absolute top-[40%] left-[75%]">
                    <div className="relative group cursor-pointer">
                      <div className="w-5 h-5 bg-emerald-500 rounded-full shadow-lg shadow-emerald-500/50 animate-pulse" style={{ animationDelay: '0.9s' }} />
                    </div>
                  </div>

                  {/* Your Home - Larger pin */}
                  <div className="absolute top-[55%] left-[50%] -translate-x-1/2">
                    <div className="relative">
                      <div className="w-10 h-10 bg-emerald-600 rounded-full shadow-lg shadow-emerald-600/50 flex items-center justify-center border-2 border-white">
                        <Home className="w-5 h-5 text-white" />
                      </div>
                      <div className="absolute -bottom-8 left-1/2 -translate-x-1/2 whitespace-nowrap">
                        <span className="px-2 py-1 bg-white rounded-lg text-xs font-medium text-slate-900 shadow-lg">Your Home</span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              {/* Stats Overlay */}
              <div className="absolute bottom-4 left-4 right-4">
                <div className="backdrop-blur-xl bg-white/95 rounded-xl p-4 border border-white/20">
                  <div className="grid grid-cols-3 gap-4 text-center">
                    <div>
                      <p className="text-2xl font-bold text-emerald-600">47</p>
                      <p className="text-xs text-slate-500">Verified Vendors</p>
                    </div>
                    <div>
                      <p className="text-2xl font-bold text-emerald-600">12</p>
                      <p className="text-xs text-slate-500">Haven Homes Nearby</p>
                    </div>
                    <div>
                      <p className="text-2xl font-bold text-emerald-600">4.9</p>
                      <p className="text-xs text-slate-500">Avg Rating</p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Right - Text */}
          <div className="order-1 lg:order-2">
            <div className="inline-flex items-center gap-2 px-3 py-1.5 bg-emerald-100 rounded-full mb-6">
              <MapPin className="w-4 h-4 text-emerald-700" />
              <span className="text-sm font-medium text-emerald-800">Trust & Verification</span>
            </div>

            <h2 className="font-serif text-3xl sm:text-4xl lg:text-5xl font-medium text-emerald-950 mb-6">
              Powered by Your<br />Neighborhood.
            </h2>

            <div className="mb-8">
              <p className="text-lg text-slate-500 mb-4 italic">
                &quot;Don&apos;t trust Google Reviews. We use the vendors your neighbors actually pay and verify.&quot;
              </p>
              <p className="text-lg text-slate-600 leading-relaxed">
                See real project costs on your street. When 5 neighbors use the same landscaper, everyone saves. Our bulk rates pass directly to you.
              </p>
            </div>

            <div className="space-y-4">
              <div className="flex items-center gap-3 p-4 bg-slate-50 rounded-xl">
                <div className="w-10 h-10 bg-emerald-100 rounded-full flex items-center justify-center">
                  <Star className="w-5 h-5 text-emerald-600" />
                </div>
                <div>
                  <p className="font-medium text-slate-900">&quot;Ace Roofing did 4 homes on our street&quot;</p>
                  <p className="text-sm text-slate-500">— The Johnsons, 3 doors down</p>
                </div>
              </div>
              <div className="flex items-center gap-3 p-4 bg-slate-50 rounded-xl">
                <div className="w-10 h-10 bg-emerald-100 rounded-full flex items-center justify-center">
                  <Heart className="w-5 h-5 text-emerald-600" />
                </div>
                <div>
                  <p className="font-medium text-slate-900">&quot;30% off landscaping with the group rate&quot;</p>
                  <p className="text-sm text-slate-500">— The Garcias, across the street</p>
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
// THE VAULT (USER MANUAL)
// ============================================================================

function VaultSection() {
  return (
    <section className="py-24 px-4 sm:px-6 lg:px-8 bg-emerald-950">
      <div className="max-w-7xl mx-auto">
        <div className="grid lg:grid-cols-2 gap-12 items-center">
          {/* Left - Text */}
          <div>
            <div className="inline-flex items-center gap-2 px-3 py-1.5 bg-emerald-900 rounded-full mb-6">
              <Key className="w-4 h-4 text-emerald-300" />
              <span className="text-sm font-medium text-emerald-200">The Vault</span>
            </div>

            <h2 className="font-serif text-3xl sm:text-4xl lg:text-5xl font-medium text-white mb-6">
              The Manual Your Home<br />Never Came With.
            </h2>

            <p className="text-lg text-emerald-100 leading-relaxed mb-8">
              Wi-Fi passwords, paint codes, warranty docs, and property lines. Instant access in The Vault. No more digging through junk drawers or calling the previous owner.
            </p>

            <div className="grid grid-cols-2 gap-4">
              <div className="bg-emerald-900/50 rounded-xl p-4 border border-emerald-800">
                <Wifi className="w-6 h-6 text-emerald-300 mb-2" />
                <p className="font-medium text-white">Access Codes</p>
                <p className="text-sm text-emerald-300">WiFi, alarm, gate</p>
              </div>
              <div className="bg-emerald-900/50 rounded-xl p-4 border border-emerald-800">
                <FileText className="w-6 h-6 text-emerald-300 mb-2" />
                <p className="font-medium text-white">Documents</p>
                <p className="text-sm text-emerald-300">Deeds, warranties, manuals</p>
              </div>
              <div className="bg-emerald-900/50 rounded-xl p-4 border border-emerald-800">
                <Home className="w-6 h-6 text-emerald-300 mb-2" />
                <p className="font-medium text-white">Room Details</p>
                <p className="text-sm text-emerald-300">Paint colors, flooring SKUs</p>
              </div>
              <div className="bg-emerald-900/50 rounded-xl p-4 border border-emerald-800">
                <Shield className="w-6 h-6 text-emerald-300 mb-2" />
                <p className="font-medium text-white">Insurance</p>
                <p className="text-sm text-emerald-300">Policies & claims</p>
              </div>
            </div>
          </div>

          {/* Right - Cinematic Home Photo with Smart Dock */}
          <div className="relative">
            <div className="relative rounded-2xl overflow-hidden shadow-2xl">
              <div className="relative h-[420px]">
                <Image
                  src="https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800&q=80"
                  alt="Beautiful modern home"
                  fill
                  className="object-cover"
                />
                {/* Gradient Overlay */}
                <div className="absolute inset-0 bg-gradient-to-t from-black/90 via-black/40 to-transparent" />

                {/* Content Overlay */}
                <div className="absolute bottom-0 left-0 right-0 p-6">
                  <div className="flex items-center gap-2 mb-2">
                    <h3 className="text-xl font-bold text-white">1247 Beverly Drive</h3>
                    <span className="px-2 py-0.5 bg-emerald-500/90 text-white text-xs font-medium rounded-full flex items-center gap-1">
                      <Shield className="w-3 h-3" />
                      Haven Managed
                    </span>
                  </div>
                  <p className="text-slate-300 text-sm mb-4">Beverly Hills, CA • 4,200 sq ft</p>

                  {/* Quick Access Dock - Glassmorphism */}
                  <div className="flex gap-2">
                    <div className="backdrop-blur-xl bg-white/15 rounded-xl border border-white/20 p-3 flex items-center gap-2 hover:bg-white/25 transition-colors cursor-pointer">
                      <Wifi className="w-5 h-5 text-white" />
                      <div>
                        <p className="text-xs text-white/70">WiFi</p>
                        <p className="text-sm text-white font-medium">••••••••</p>
                      </div>
                    </div>
                    <div className="backdrop-blur-xl bg-white/15 rounded-xl border border-white/20 p-3 flex items-center gap-2 hover:bg-white/25 transition-colors cursor-pointer">
                      <Key className="w-5 h-5 text-white" />
                      <div>
                        <p className="text-xs text-white/70">Gate</p>
                        <p className="text-sm text-white font-medium">#1247</p>
                      </div>
                    </div>
                    <div className="backdrop-blur-xl bg-white/15 rounded-xl border border-white/20 p-3 flex items-center gap-2 hover:bg-white/25 transition-colors cursor-pointer">
                      <Bell className="w-5 h-5 text-white" />
                      <div>
                        <p className="text-xs text-white/70">Alarm</p>
                        <p className="text-sm text-white font-medium">••••</p>
                      </div>
                    </div>
                  </div>
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
// PRICING SECTION
// ============================================================================

function PricingSection() {
  return (
    <section id="pricing" className="py-24 px-4 sm:px-6 lg:px-8 bg-slate-50">
      <div className="max-w-7xl mx-auto">
        <div className="text-center mb-16">
          <h2 className="font-serif text-4xl sm:text-5xl font-medium text-emerald-950 mb-4">
            Simple, Transparent Pricing.
          </h2>
          <p className="text-lg text-slate-600 max-w-2xl mx-auto">
            Fixed monthly membership. No surprise fees. No percentage cuts.
          </p>
        </div>

        <div className="grid lg:grid-cols-3 gap-8 max-w-6xl mx-auto">
          {/* Haven Standard */}
          <div className="bg-white rounded-2xl p-8 border border-slate-200 shadow-sm">
            <div className="mb-6">
              <h3 className="font-serif text-2xl font-medium text-emerald-950 mb-1">Haven Standard</h3>
              <p className="text-slate-500">Essential Management</p>
            </div>
            <div className="mb-6">
              <span className="text-5xl font-bold text-emerald-950">$49</span>
              <span className="text-slate-500">/month</span>
            </div>
            <ul className="space-y-4 mb-8">
              <li className="flex items-start gap-3">
                <Check className="w-5 h-5 text-emerald-600 mt-0.5 flex-shrink-0" />
                <span className="text-slate-600">Bill Tracking and Reminders</span>
              </li>
              <li className="flex items-start gap-3">
                <Check className="w-5 h-5 text-emerald-600 mt-0.5 flex-shrink-0" />
                <span className="text-slate-600">Family Calendar Sync</span>
              </li>
              <li className="flex items-start gap-3">
                <Check className="w-5 h-5 text-emerald-600 mt-0.5 flex-shrink-0" />
                <span className="text-slate-600">Digital Secretary (Email Triage)</span>
              </li>
              <li className="flex items-start gap-3">
                <Check className="w-5 h-5 text-emerald-600 mt-0.5 flex-shrink-0" />
                <span className="text-slate-600">Vendor Network Access</span>
              </li>
              <li className="flex items-start gap-3">
                <Check className="w-5 h-5 text-emerald-600 mt-0.5 flex-shrink-0" />
                <span className="text-slate-600">Home Vault (Documents)</span>
              </li>
            </ul>
            <Link
              href="/register?plan=standard"
              className="block w-full text-center px-6 py-3 border-2 border-emerald-950 text-emerald-950 font-medium rounded-xl hover:bg-emerald-50 transition-colors"
            >
              Get Started
            </Link>
          </div>

          {/* Haven Concierge - Highlighted */}
          <div className="relative bg-emerald-950 rounded-2xl p-8 text-white shadow-2xl shadow-emerald-950/20 lg:-mt-4 lg:mb-[-1rem]">
            <div className="absolute top-0 left-1/2 -translate-x-1/2 -translate-y-1/2">
              <span className="inline-flex items-center gap-1 px-4 py-1 bg-amber-400 text-emerald-950 text-sm font-semibold rounded-full">
                <Star className="w-4 h-4" />
                Most Popular
              </span>
            </div>
            <div className="mb-6 pt-4">
              <h3 className="font-serif text-2xl font-medium mb-1">Haven Concierge</h3>
              <p className="text-emerald-300">The Modern Family Office</p>
            </div>
            <div className="mb-6">
              <span className="text-5xl font-bold">$149</span>
              <span className="text-emerald-300">/month</span>
            </div>
            <ul className="space-y-4 mb-8">
              <li className="flex items-start gap-3">
                <Check className="w-5 h-5 text-emerald-400 mt-0.5 flex-shrink-0" />
                <span className="text-emerald-100">Everything in Standard</span>
              </li>
              <li className="flex items-start gap-3">
                <Check className="w-5 h-5 text-emerald-400 mt-0.5 flex-shrink-0" />
                <span className="text-emerald-100">Dedicated Human Manager</span>
              </li>
              <li className="flex items-start gap-3">
                <Check className="w-5 h-5 text-emerald-400 mt-0.5 flex-shrink-0" />
                <span className="text-emerald-100">One-Bill Pay (Retainer Model)</span>
              </li>
              <li className="flex items-start gap-3">
                <Check className="w-5 h-5 text-emerald-400 mt-0.5 flex-shrink-0" />
                <span className="text-emerald-100">Monthly Handyman Visits (Included)</span>
              </li>
              <li className="flex items-start gap-3">
                <Check className="w-5 h-5 text-emerald-400 mt-0.5 flex-shrink-0" />
                <span className="text-emerald-100">Travel Planning and Booking</span>
              </li>
              <li className="flex items-start gap-3">
                <Check className="w-5 h-5 text-emerald-400 mt-0.5 flex-shrink-0" />
                <span className="text-emerald-100">Project Management (Zero Fee)</span>
              </li>
            </ul>
            <Link
              href="/register?plan=concierge"
              className="block w-full text-center px-6 py-3 bg-white text-emerald-950 font-medium rounded-xl hover:bg-emerald-50 transition-colors"
            >
              Start Concierge
            </Link>
          </div>

          {/* Haven Estate */}
          <div className="bg-white rounded-2xl p-8 border border-slate-200 shadow-sm">
            <div className="mb-6">
              <h3 className="font-serif text-2xl font-medium text-emerald-950 mb-1">Haven Estate</h3>
              <p className="text-slate-500">Full Estate Support</p>
            </div>
            <div className="mb-6">
              <span className="text-5xl font-bold text-emerald-950">$300</span>
              <span className="text-slate-500">/month</span>
            </div>
            <ul className="space-y-4 mb-8">
              <li className="flex items-start gap-3">
                <Check className="w-5 h-5 text-emerald-600 mt-0.5 flex-shrink-0" />
                <span className="text-slate-600">Everything in Concierge</span>
              </li>
              <li className="flex items-start gap-3">
                <Check className="w-5 h-5 text-emerald-600 mt-0.5 flex-shrink-0" />
                <span className="text-slate-600">Priority 24/7 Support</span>
              </li>
              <li className="flex items-start gap-3">
                <Check className="w-5 h-5 text-emerald-600 mt-0.5 flex-shrink-0" />
                <span className="text-slate-600">Enhanced Handyman Visits (2x/month)</span>
              </li>
              <li className="flex items-start gap-3">
                <Check className="w-5 h-5 text-emerald-600 mt-0.5 flex-shrink-0" />
                <span className="text-slate-600">Complex Project Oversight</span>
              </li>
              <li className="flex items-start gap-3">
                <Check className="w-5 h-5 text-emerald-600 mt-0.5 flex-shrink-0" />
                <span className="text-slate-600">Trust and Estate Accounting</span>
              </li>
              <li className="flex items-start gap-3">
                <Check className="w-5 h-5 text-emerald-600 mt-0.5 flex-shrink-0" />
                <span className="text-slate-600">Multi-Property Support</span>
              </li>
            </ul>
            <Link
              href="/register?plan=estate"
              className="block w-full text-center px-6 py-3 border-2 border-emerald-950 text-emerald-950 font-medium rounded-xl hover:bg-emerald-50 transition-colors"
            >
              Contact Sales
            </Link>
          </div>
        </div>

        {/* Additional pricing note */}
        <div className="mt-12 text-center">
          <p className="text-slate-500 text-sm">
            All plans include FDIC-insured Household Wallet. Actual service costs (plumbers, electricians, etc.) billed separately at vendor rates.
            <br />
            No markup. No hidden fees. Cancel anytime.
          </p>
        </div>
      </div>
    </section>
  );
}

// ============================================================================
// STICKY CTA FOOTER
// ============================================================================

function StickyCTAFooter() {
  return (
    <div className="fixed bottom-0 left-0 right-0 z-40 bg-white/95 backdrop-blur-lg border-t border-slate-200 py-4 px-4 sm:px-6 lg:px-8 lg:hidden">
      <div className="max-w-7xl mx-auto flex items-center justify-between gap-4">
        <div className="hidden sm:block">
          <p className="text-sm font-medium text-slate-900">Experience home ownership on autopilot</p>
          <p className="text-xs text-slate-500">Join the waitlist for your area</p>
        </div>
        <Link
          href="/register"
          className="flex-1 sm:flex-none inline-flex items-center justify-center gap-2 px-6 py-3 bg-emerald-950 text-white text-sm font-medium rounded-xl hover:bg-emerald-900 transition-colors"
        >
          Check Address Eligibility
          <ArrowRight className="w-4 h-4" />
        </Link>
      </div>
    </div>
  );
}

// ============================================================================
// MAIN PAGE
// ============================================================================

export default function HomePage() {
  return (
    <div className="min-h-screen bg-slate-50">
      {/* Navigation */}
      <nav className="fixed top-0 left-0 right-0 z-50 bg-slate-50/95 backdrop-blur-sm border-b border-slate-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 bg-emerald-950 rounded-lg flex items-center justify-center">
                <Home className="w-5 h-5 text-white" />
              </div>
              <span className="text-xl font-semibold text-emerald-950 tracking-tight">Haven</span>
            </div>
            <div className="hidden md:flex items-center gap-8">
              <a href="#one-bill" className="text-slate-600 hover:text-emerald-950 text-sm font-medium transition-colors">How It Works</a>
              <a href="#pricing" className="text-slate-600 hover:text-emerald-950 text-sm font-medium transition-colors">Pricing</a>
              <a href="#community" className="text-slate-600 hover:text-emerald-950 text-sm font-medium transition-colors">Community</a>
              <Link href="/login" className="text-slate-600 hover:text-emerald-950 text-sm font-medium transition-colors">
                Member Login
              </Link>
              <Link
                href="/register"
                className="px-4 py-2 bg-emerald-950 text-white text-sm font-medium rounded-lg hover:bg-emerald-900 transition-colors"
              >
                Get Started
              </Link>
            </div>
            <div className="md:hidden">
              <Link
                href="/register"
                className="px-4 py-2 bg-emerald-950 text-white text-sm font-medium rounded-lg hover:bg-emerald-900 transition-colors"
              >
                Get Started
              </Link>
            </div>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <HeroSection />

      {/* Core Value A: One Bill Revolution */}
      <OneBillSection />

      {/* Core Value B: Single Point of Contact */}
      <SingleContactSection />

      {/* Core Value C: Proactive Care */}
      <ProactiveCareSection />

      {/* The Network */}
      <NetworkSection />

      {/* The Vault */}
      <VaultSection />

      {/* Pricing */}
      <PricingSection />

      {/* Final CTA */}
      <section className="py-24 px-4 sm:px-6 lg:px-8 bg-white">
        <div className="max-w-4xl mx-auto text-center">
          <h2 className="font-serif text-4xl sm:text-5xl font-medium text-emerald-950 mb-6">
            Own your home.<br />Live like you rent.
          </h2>
          <p className="text-xl text-slate-600 mb-10 max-w-2xl mx-auto">
            Join hundreds of families who have eliminated the friction of ownership. Experience home ownership on autopilot.
          </p>
          <Link
            href="/register"
            className="inline-flex items-center gap-2 px-8 py-4 bg-emerald-950 text-white text-lg font-medium rounded-xl hover:bg-emerald-900 transition-colors shadow-lg shadow-emerald-950/20"
          >
            Check Address Eligibility
            <ArrowRight className="w-5 h-5" />
          </Link>
          <p className="text-sm text-slate-500 mt-4">Join the waitlist. Experience home ownership on autopilot.</p>
        </div>
      </section>

      {/* Trust Badges */}
      <section className="py-12 px-4 sm:px-6 lg:px-8 bg-slate-100 border-t border-slate-200">
        <div className="max-w-7xl mx-auto">
          <div className="flex flex-wrap items-center justify-center gap-8 sm:gap-16">
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 bg-white rounded-full flex items-center justify-center shadow-sm">
                <Lock className="w-6 h-6 text-emerald-700" />
              </div>
              <div>
                <p className="font-medium text-emerald-950">FDIC-Insured</p>
                <p className="text-sm text-slate-500">Household Wallet</p>
              </div>
            </div>
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 bg-white rounded-full flex items-center justify-center shadow-sm">
                <Shield className="w-6 h-6 text-emerald-700" />
              </div>
              <div>
                <p className="font-medium text-emerald-950">$2M Insured</p>
                <p className="text-sm text-slate-500">Liability Coverage</p>
              </div>
            </div>
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 bg-white rounded-full flex items-center justify-center shadow-sm">
                <BadgeCheck className="w-6 h-6 text-emerald-700" />
              </div>
              <div>
                <p className="font-medium text-emerald-950">Vetted Pros</p>
                <p className="text-sm text-slate-500">Background Checked</p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="py-16 px-4 sm:px-6 lg:px-8 bg-emerald-950 pb-32 lg:pb-16">
        <div className="max-w-7xl mx-auto">
          <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-12 mb-12">
            {/* Brand */}
            <div className="lg:col-span-1">
              <div className="flex items-center gap-2 mb-4">
                <div className="w-8 h-8 bg-white rounded-lg flex items-center justify-center">
                  <Home className="w-5 h-5 text-emerald-950" />
                </div>
                <span className="text-xl font-semibold text-white tracking-tight">Haven</span>
              </div>
              <p className="text-emerald-300 text-sm leading-relaxed">
                The operating system for your home and family.
                One membership. Complete peace of mind.
              </p>
            </div>

            {/* Product */}
            <div>
              <h4 className="font-medium text-white mb-4">Product</h4>
              <ul className="space-y-3">
                <li><a href="#one-bill" className="text-emerald-300 hover:text-white text-sm transition-colors">How It Works</a></li>
                <li><a href="#pricing" className="text-emerald-300 hover:text-white text-sm transition-colors">Pricing</a></li>
                <li><a href="#community" className="text-emerald-300 hover:text-white text-sm transition-colors">Community</a></li>
                <li><Link href="/login" className="text-emerald-300 hover:text-white text-sm transition-colors">Member Login</Link></li>
              </ul>
            </div>

            {/* Company */}
            <div>
              <h4 className="font-medium text-white mb-4">Company</h4>
              <ul className="space-y-3">
                <li><a href="#" className="text-emerald-300 hover:text-white text-sm transition-colors">About Us</a></li>
                <li><a href="#" className="text-emerald-300 hover:text-white text-sm transition-colors">Careers</a></li>
                <li><a href="#" className="text-emerald-300 hover:text-white text-sm transition-colors">Press</a></li>
                <li><a href="#" className="text-emerald-300 hover:text-white text-sm transition-colors">Contact</a></li>
              </ul>
            </div>

            {/* Partners */}
            <div>
              <h4 className="font-medium text-white mb-4">Partners</h4>
              <ul className="space-y-3">
                <li><Link href="/vendor/login" className="text-emerald-300 hover:text-white text-sm transition-colors">Vendor Portal</Link></li>
                <li><a href="#" className="text-emerald-300 hover:text-white text-sm transition-colors">Become a Handyman</a></li>
                <li><a href="#" className="text-emerald-300 hover:text-white text-sm transition-colors">Real Estate Partners</a></li>
                <li><a href="#" className="text-emerald-300 hover:text-white text-sm transition-colors">Insurance Partners</a></li>
              </ul>
            </div>
          </div>

          <div className="pt-8 border-t border-emerald-800 flex flex-col sm:flex-row items-center justify-between gap-4">
            <p className="text-emerald-400 text-sm">
              &copy; {new Date().getFullYear()} Haven Home Management. All rights reserved.
            </p>
            <div className="flex items-center gap-6">
              <a href="#" className="text-emerald-400 hover:text-white text-sm transition-colors">Privacy Policy</a>
              <a href="#" className="text-emerald-400 hover:text-white text-sm transition-colors">Terms of Service</a>
              <a href="#" className="text-emerald-400 hover:text-white text-sm transition-colors">Security</a>
            </div>
          </div>
        </div>
      </footer>

      {/* Sticky CTA Footer (Mobile) */}
      <StickyCTAFooter />
    </div>
  );
}
