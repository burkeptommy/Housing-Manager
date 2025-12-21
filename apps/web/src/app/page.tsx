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
  Filter,
  Thermometer,
  MapPin,
  Building,
  Download,
  Zap,
  Droplets,
} from 'lucide-react';

// ============================================================================
// ROTATING WORDS CONFIG
// ============================================================================

const rotatingWords = [
  { word: 'Home', color: 'text-emerald-600' },
  { word: 'Finances', color: 'text-amber-500' },
  { word: 'Projects', color: 'text-orange-500' },
  { word: 'Family', color: 'text-blue-600' },
  { word: 'Life', color: 'text-indigo-600' },
];

// ============================================================================
// HERO SECTION - "Zero Noise" Promise
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
              <span className="inline-flex items-baseline">
                <span>for Your&nbsp;</span>
                <span className="relative inline-flex overflow-hidden" style={{ minWidth: '3ch' }}>
                  <AnimatePresence mode="wait">
                    <motion.span
                      key={currentIndex}
                      initial={{ y: '100%', opacity: 0 }}
                      animate={{ y: 0, opacity: 1 }}
                      exit={{ y: '-100%', opacity: 0 }}
                      transition={{
                        duration: 0.4,
                        ease: [0.4, 0, 0.2, 1],
                      }}
                      className={`inline-block whitespace-nowrap ${rotatingWords[currentIndex]?.color ?? 'text-emerald-600'}`}
                    >
                      {rotatingWords[currentIndex]?.word ?? 'Home'}.
                    </motion.span>
                  </AnimatePresence>
                </span>
              </span>
            </h1>

            <p className="text-xl sm:text-2xl font-medium text-emerald-800 mb-4">
              One bill. One contact. Zero hassle.
            </p>

            <p className="text-lg sm:text-xl text-slate-600 max-w-xl mb-8 leading-relaxed">
              Stop juggling 20 vendors, 15 passwords, and surprise invoices. Haven consolidates everything into one monthly statement and one person who handles it all.
            </p>

            <div className="flex flex-col sm:flex-row items-start gap-4">
              <Link
                href="/register"
                className="inline-flex items-center justify-center gap-2 px-8 py-4 bg-emerald-950 text-white text-lg font-medium rounded-xl hover:bg-emerald-900 transition-colors shadow-lg shadow-emerald-950/20"
              >
                See If Haven Is In Your Area
                <ArrowRight className="w-5 h-5" />
              </Link>
              <a
                href="#how-it-works"
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

          {/* Right Column - Floating UI Stack (3 Pillars of Freedom) */}
          <div className="relative h-[500px] lg:h-[600px] hidden lg:block">
            {/* LEFT CARD - The "One Bill" Revolution */}
            <motion.div
              initial={{ opacity: 0, x: -40 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.2, duration: 0.6 }}
              className="absolute top-8 left-0 w-[260px] backdrop-blur-xl bg-white/95 rounded-2xl shadow-2xl shadow-slate-900/10 border border-slate-200 overflow-hidden z-10"
            >
              <div className="p-4">
                <div className="flex items-center gap-2 mb-4">
                  <div className="w-8 h-8 bg-amber-100 rounded-lg flex items-center justify-center">
                    <DollarSign className="w-4 h-4 text-amber-600" />
                  </div>
                  <span className="text-sm font-semibold text-slate-900">Consolidated Billing</span>
                </div>

                {/* Vendor logos collapsing into single line */}
                <div className="space-y-2 mb-3">
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
                      <div className="w-6 h-6 bg-green-100 rounded-full flex items-center justify-center border-2 border-white">
                        <Sparkles className="w-3 h-3 text-green-600" />
                      </div>
                    </div>
                    <ArrowRight className="w-4 h-4 text-slate-400" />
                    <div className="w-8 h-8 bg-emerald-600 rounded-lg flex items-center justify-center">
                      <Home className="w-4 h-4 text-white" />
                    </div>
                  </div>
                </div>

                <div className="bg-slate-50 rounded-lg p-3">
                  <p className="text-xs text-slate-600">
                    <span className="font-semibold text-emerald-700">6 Vendors</span> Auto-Paid.
                    <br />
                    <span className="font-semibold text-emerald-700">1 Monthly Statement</span> to Haven.
                  </p>
                </div>
              </div>
            </motion.div>

            {/* CENTER CARD - The Manager's Action */}
            <motion.div
              initial={{ opacity: 0, y: 30 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.4, duration: 0.6 }}
              className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[320px] bg-white rounded-2xl shadow-2xl shadow-slate-900/15 border border-slate-200 overflow-hidden z-20"
            >
              <div className="p-5 border-b border-slate-100">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-emerald-600 rounded-full flex items-center justify-center">
                      <span className="text-sm font-bold text-white">SM</span>
                    </div>
                    <div>
                      <p className="text-sm font-semibold text-slate-900">Steve, Your Manager</p>
                      <p className="text-xs text-slate-500">Just now</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-1.5 px-2.5 py-1 bg-emerald-100 rounded-full">
                    <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" />
                    <span className="text-xs font-semibold text-emerald-700">Done</span>
                  </div>
                </div>
              </div>
              <div className="p-5">
                <div className="flex items-start gap-3 p-3 bg-emerald-50 rounded-xl border border-emerald-100">
                  <div className="w-10 h-10 bg-emerald-100 rounded-lg flex items-center justify-center flex-shrink-0">
                    <Thermometer className="w-5 h-5 text-emerald-600" />
                  </div>
                  <div>
                    <p className="text-sm font-medium text-slate-900 mb-1">Work Completed</p>
                    <p className="text-xs text-slate-600">
                      Annual HVAC Service completed. Filters changed & report filed.
                    </p>
                  </div>
                </div>
                <div className="mt-3 flex items-center gap-2 text-xs text-slate-500">
                  <Clock className="w-3.5 h-3.5" />
                  <span>No action needed from you</span>
                </div>
              </div>
            </motion.div>

            {/* RIGHT CARD - The Lifestyle Wildcard (Travel) */}
            <motion.div
              initial={{ opacity: 0, x: 40 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.6, duration: 0.6 }}
              className="absolute bottom-16 right-0 w-[280px] backdrop-blur-xl bg-white/95 rounded-2xl shadow-2xl shadow-slate-900/10 border border-slate-200 overflow-hidden z-10"
            >
              <div className="p-4">
                <div className="flex items-center gap-2 mb-4">
                  <div className="w-8 h-8 bg-sky-100 rounded-lg flex items-center justify-center">
                    <Plane className="w-4 h-4 text-sky-600" />
                  </div>
                  <span className="text-sm font-semibold text-slate-900">Travel Itinerary</span>
                </div>

                <div className="bg-gradient-to-r from-sky-50 to-indigo-50 rounded-xl p-3 mb-3">
                  <p className="text-sm font-medium text-slate-900 mb-1">Spring Break Trip</p>
                  <p className="text-xs text-slate-600">March 15-22, 2025 • Maui, HI</p>
                </div>

                <div className="space-y-2">
                  <div className="flex items-center gap-2">
                    <CheckCircle2 className="w-4 h-4 text-emerald-500" />
                    <span className="text-xs text-slate-600">Flights booked (4 travelers)</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <CheckCircle2 className="w-4 h-4 text-emerald-500" />
                    <span className="text-xs text-slate-600">House Sitter confirmed</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <CheckCircle2 className="w-4 h-4 text-emerald-500" />
                    <span className="text-xs text-slate-600">Pet care arranged</span>
                  </div>
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
// HOW IT WORKS - 3 STEP PROCESS
// ============================================================================

function HowItWorksSection() {
  return (
    <section id="how-it-works" className="py-24 px-4 sm:px-6 lg:px-8 bg-white border-b border-slate-100">
      <div className="max-w-7xl mx-auto">
        <div className="text-center mb-16">
          <div className="inline-flex items-center gap-2 px-3 py-1.5 bg-emerald-100 rounded-full mb-6">
            <Sparkles className="w-4 h-4 text-emerald-700" />
            <span className="text-sm font-medium text-emerald-800">How It Works</span>
          </div>
          <h2 className="font-serif text-3xl sm:text-4xl lg:text-5xl font-medium text-emerald-950 mb-4">
            From Chaos to Calm in 3 Steps
          </h2>
          <p className="text-lg text-slate-600 max-w-2xl mx-auto">
            No more spreadsheets, password managers, or midnight calls from contractors.
          </p>
        </div>

        <div className="grid md:grid-cols-3 gap-8 lg:gap-12">
          {/* Step 1 */}
          <div className="relative">
            <div className="absolute -top-4 -left-4 w-12 h-12 bg-emerald-950 rounded-full flex items-center justify-center text-white text-xl font-bold">
              1
            </div>
            <div className="bg-slate-50 rounded-2xl p-8 pt-12 h-full border border-slate-100">
              <div className="w-14 h-14 bg-amber-100 rounded-xl flex items-center justify-center mb-6">
                <DollarSign className="w-7 h-7 text-amber-600" />
              </div>
              <h3 className="text-xl font-semibold text-emerald-950 mb-3">Connect Your Vendors</h3>
              <p className="text-slate-600 leading-relaxed">
                Link your utilities, landscaper, pool service, tutor—everyone who bills you. We set up auto-pay and take over the relationship.
              </p>
              <div className="mt-4 flex flex-wrap gap-2">
                <span className="px-2 py-1 bg-white rounded text-xs text-slate-500 border border-slate-200">Electric</span>
                <span className="px-2 py-1 bg-white rounded text-xs text-slate-500 border border-slate-200">Water</span>
                <span className="px-2 py-1 bg-white rounded text-xs text-slate-500 border border-slate-200">Pool</span>
                <span className="px-2 py-1 bg-white rounded text-xs text-slate-500 border border-slate-200">Lawn</span>
                <span className="px-2 py-1 bg-white rounded text-xs text-slate-500 border border-slate-200">+12 more</span>
              </div>
            </div>
          </div>

          {/* Step 2 */}
          <div className="relative">
            <div className="absolute -top-4 -left-4 w-12 h-12 bg-emerald-950 rounded-full flex items-center justify-center text-white text-xl font-bold">
              2
            </div>
            <div className="bg-slate-50 rounded-2xl p-8 pt-12 h-full border border-slate-100">
              <div className="w-14 h-14 bg-emerald-100 rounded-xl flex items-center justify-center mb-6">
                <FileText className="w-7 h-7 text-emerald-600" />
              </div>
              <h3 className="text-xl font-semibold text-emerald-950 mb-3">One Monthly Statement</h3>
              <p className="text-slate-600 leading-relaxed">
                On the 1st, you get one PDF: every vendor, every charge, clearly categorized. Routine bills are auto-paid. Big items wait for your approval.
              </p>
              <div className="mt-4 p-3 bg-white rounded-lg border border-slate-200">
                <div className="flex items-center justify-between text-sm">
                  <span className="text-slate-600">December Statement</span>
                  <span className="font-medium text-slate-900">$4,847</span>
                </div>
                <div className="mt-2 flex items-center gap-2">
                  <div className="flex-1 h-2 bg-emerald-200 rounded-full overflow-hidden">
                    <div className="h-full w-4/5 bg-emerald-600 rounded-full" />
                  </div>
                  <span className="text-xs text-slate-500">Auto-paid</span>
                </div>
              </div>
            </div>
          </div>

          {/* Step 3 */}
          <div className="relative">
            <div className="absolute -top-4 -left-4 w-12 h-12 bg-emerald-950 rounded-full flex items-center justify-center text-white text-xl font-bold">
              3
            </div>
            <div className="bg-slate-50 rounded-2xl p-8 pt-12 h-full border border-slate-100">
              <div className="w-14 h-14 bg-sky-100 rounded-xl flex items-center justify-center mb-6">
                <MessageSquare className="w-7 h-7 text-sky-600" />
              </div>
              <h3 className="text-xl font-semibold text-emerald-950 mb-3">One Person Handles Everything</h3>
              <p className="text-slate-600 leading-relaxed">
                Your dedicated Home Manager coordinates all vendors, handles issues, and only texts you when a decision is needed. No more being the project manager.
              </p>
              <div className="mt-4 flex items-center gap-3">
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

        {/* Bottom CTA */}
        <div className="mt-16 text-center">
          <Link
            href="/register"
            className="inline-flex items-center gap-2 px-8 py-4 bg-emerald-950 text-white text-lg font-medium rounded-xl hover:bg-emerald-900 transition-colors shadow-lg shadow-emerald-950/20"
          >
            See If Haven Is In Your Area
            <ArrowRight className="w-5 h-5" />
          </Link>
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
                We audit and auto-pay your recurring bills—utilities, subscriptions, staff. You don&apos;t need to approve the electric bill every month. We only notify you for the big ticket items and exceptions.
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
                  <p className="font-medium text-slate-900">Exception-Only Approvals</p>
                  <p className="text-sm text-slate-500">Big expenses need your OK. Routine ones don&apos;t.</p>
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
                  <p className="text-sm text-slate-500 mb-1">House Wallet Balance</p>
                  <p className="text-3xl font-bold text-slate-900">$8,420.00</p>
                </div>
                <div className="flex items-center gap-2 px-3 py-1.5 bg-emerald-100 rounded-full">
                  <CheckCircle2 className="w-4 h-4 text-emerald-600" />
                  <span className="text-sm font-medium text-emerald-700">All Current</span>
                </div>
              </div>

              {/* Monthly Statement Preview */}
              <div className="bg-white rounded-xl p-4 mb-4">
                <div className="flex items-center justify-between mb-3">
                  <span className="text-sm font-semibold text-slate-900">December Statement</span>
                  <span className="text-sm text-slate-500">$4,847 total</span>
                </div>
                <div className="space-y-2">
                  <div className="flex items-center justify-between text-sm">
                    <div className="flex items-center gap-2">
                      <div className="w-2 h-2 bg-emerald-500 rounded-full" />
                      <span className="text-slate-600">Auto-Paid (routine)</span>
                    </div>
                    <span className="text-slate-700 font-medium">$3,847</span>
                  </div>
                  <div className="flex items-center justify-between text-sm">
                    <div className="flex items-center gap-2">
                      <div className="w-2 h-2 bg-amber-500 rounded-full" />
                      <span className="text-slate-600">You Approved</span>
                    </div>
                    <span className="text-slate-700 font-medium">$1,000</span>
                  </div>
                </div>
              </div>

              {/* Recent Auto-Paid */}
              <div className="bg-white rounded-xl p-4">
                <p className="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-3">Auto-Paid This Month</p>
                <div className="space-y-3">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 bg-blue-100 rounded-lg flex items-center justify-center">
                        <Zap className="w-4 h-4 text-blue-600" />
                      </div>
                      <div>
                        <p className="text-sm font-medium text-slate-900">SCE Electric</p>
                        <p className="text-xs text-slate-500">Dec 15 • Routine</p>
                      </div>
                    </div>
                    <span className="text-sm font-medium text-slate-900">$187</span>
                  </div>
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 bg-green-100 rounded-lg flex items-center justify-center">
                        <Sparkles className="w-4 h-4 text-green-600" />
                      </div>
                      <div>
                        <p className="text-sm font-medium text-slate-900">Green Thumb Landscaping</p>
                        <p className="text-xs text-slate-500">Dec 12 • Routine</p>
                      </div>
                    </div>
                    <span className="text-sm font-medium text-slate-900">$340</span>
                  </div>
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 bg-cyan-100 rounded-lg flex items-center justify-center">
                        <Activity className="w-4 h-4 text-cyan-600" />
                      </div>
                      <div>
                        <p className="text-sm font-medium text-slate-900">Crystal Clear Pools</p>
                        <p className="text-xs text-slate-500">Dec 10 • Routine</p>
                      </div>
                    </div>
                    <span className="text-sm font-medium text-slate-900">$175</span>
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
                Just like a luxury apartment building, we perform monthly preventative rounds. Changing filters, flushing heaters, checking sensors—so small issues never become emergencies.
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
                      strokeDasharray={`${2 * Math.PI * 70 * 1.0} ${2 * Math.PI * 70}`}
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
                    <span className="text-4xl font-bold text-emerald-600">100%</span>
                    <span className="text-sm text-slate-500">Health Score</span>
                  </div>
                </div>
              </div>

              {/* Systems Status */}
              <div className="space-y-3">
                <p className="text-sm font-semibold text-slate-900 mb-2">All Systems Optimal</p>
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
                <div className="flex items-center justify-between p-3 bg-emerald-50 rounded-xl border border-emerald-100">
                  <div className="flex items-center gap-3">
                    <Filter className="w-5 h-5 text-emerald-600" />
                    <span className="text-sm font-medium text-slate-900">Air Filters</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <CheckCircle2 className="w-4 h-4 text-emerald-500" />
                    <span className="text-sm text-emerald-600">Fresh</span>
                  </div>
                </div>
              </div>

              {/* Next Visit */}
              <div className="mt-4 p-3 bg-slate-50 rounded-xl">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-xs text-slate-500">Next Handyman Visit</p>
                    <p className="text-sm font-semibold text-slate-900">Tuesday, Jan 7 at 10am</p>
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
// THE NETWORK (HYPER-LOCAL TRUST)
// ============================================================================

function NetworkSection() {
  return (
    <section id="community" className="py-24 px-4 sm:px-6 lg:px-8 bg-white">
      <div className="max-w-7xl mx-auto">
        <div className="grid lg:grid-cols-2 gap-12 items-center">
          {/* Left - Street-Level Map Visual */}
          <div className="relative order-2 lg:order-1">
            <div className="relative rounded-2xl overflow-hidden shadow-2xl shadow-slate-900/20 bg-emerald-950 h-[420px]">
              {/* Street Map Pattern */}
              <div className="absolute inset-0">
                {/* Grid streets */}
                <svg className="absolute inset-0 w-full h-full" viewBox="0 0 400 420">
                  {/* Horizontal streets */}
                  <line x1="0" y1="100" x2="400" y2="100" stroke="#10b981" strokeWidth="6" opacity="0.3" />
                  <line x1="0" y1="210" x2="400" y2="210" stroke="#10b981" strokeWidth="8" opacity="0.4" />
                  <line x1="0" y1="320" x2="400" y2="320" stroke="#10b981" strokeWidth="6" opacity="0.3" />
                  {/* Vertical streets */}
                  <line x1="80" y1="0" x2="80" y2="420" stroke="#10b981" strokeWidth="4" opacity="0.25" />
                  <line x1="200" y1="0" x2="200" y2="420" stroke="#10b981" strokeWidth="6" opacity="0.35" />
                  <line x1="320" y1="0" x2="320" y2="420" stroke="#10b981" strokeWidth="4" opacity="0.25" />
                  {/* House plots */}
                  <rect x="20" y="40" width="40" height="40" fill="#064e3b" opacity="0.5" rx="4" />
                  <rect x="100" y="40" width="40" height="40" fill="#064e3b" opacity="0.5" rx="4" />
                  <rect x="220" y="40" width="40" height="40" fill="#064e3b" opacity="0.5" rx="4" />
                  <rect x="340" y="40" width="40" height="40" fill="#064e3b" opacity="0.5" rx="4" />
                  <rect x="20" y="130" width="40" height="40" fill="#064e3b" opacity="0.5" rx="4" />
                  <rect x="100" y="130" width="40" height="40" fill="#064e3b" opacity="0.5" rx="4" />
                  <rect x="220" y="130" width="40" height="40" fill="#064e3b" opacity="0.5" rx="4" />
                  <rect x="340" y="130" width="40" height="40" fill="#064e3b" opacity="0.5" rx="4" />
                  <rect x="20" y="240" width="40" height="40" fill="#064e3b" opacity="0.5" rx="4" />
                  <rect x="100" y="240" width="40" height="40" fill="#064e3b" opacity="0.5" rx="4" />
                  <rect x="220" y="240" width="40" height="40" fill="#064e3b" opacity="0.5" rx="4" />
                  <rect x="340" y="240" width="40" height="40" fill="#064e3b" opacity="0.5" rx="4" />
                  <rect x="20" y="350" width="40" height="40" fill="#064e3b" opacity="0.5" rx="4" />
                  <rect x="100" y="350" width="40" height="40" fill="#064e3b" opacity="0.5" rx="4" />
                  <rect x="220" y="350" width="40" height="40" fill="#064e3b" opacity="0.5" rx="4" />
                  <rect x="340" y="350" width="40" height="40" fill="#064e3b" opacity="0.5" rx="4" />
                </svg>
              </div>

              {/* Vendor Pins with Labels */}
              <div className="absolute inset-0 p-6">
                {/* Your Home - Large center pin */}
                <div className="absolute top-[48%] left-[50%] -translate-x-1/2 -translate-y-1/2">
                  <div className="relative">
                    <div className="w-14 h-14 bg-emerald-500 rounded-full shadow-lg shadow-emerald-500/50 flex items-center justify-center border-4 border-white">
                      <Home className="w-7 h-7 text-white" />
                    </div>
                    <div className="absolute -bottom-10 left-1/2 -translate-x-1/2 whitespace-nowrap">
                      <span className="px-3 py-1.5 bg-white rounded-lg text-sm font-semibold text-slate-900 shadow-lg">Your Home</span>
                    </div>
                  </div>
                </div>

                {/* Verified Plumber */}
                <div className="absolute top-[20%] left-[22%]">
                  <div className="relative group cursor-pointer">
                    <div className="w-8 h-8 bg-emerald-400 rounded-full shadow-lg shadow-emerald-400/50 flex items-center justify-center animate-pulse">
                      <Wrench className="w-4 h-4 text-white" />
                    </div>
                    <div className="absolute -top-12 left-1/2 -translate-x-1/2">
                      <div className="px-2 py-1 bg-white rounded text-xs font-medium text-slate-900 whitespace-nowrap shadow-lg">
                        <p className="font-semibold">Verified Plumber</p>
                        <p className="text-slate-500">Used by 3 neighbors</p>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Trusted Landscaper */}
                <div className="absolute top-[32%] left-[75%]">
                  <div className="relative group cursor-pointer">
                    <div className="w-8 h-8 bg-emerald-400 rounded-full shadow-lg shadow-emerald-400/50 flex items-center justify-center animate-pulse" style={{ animationDelay: '0.3s' }}>
                      <Sparkles className="w-4 h-4 text-white" />
                    </div>
                    <div className="absolute -top-12 left-1/2 -translate-x-1/2">
                      <div className="px-2 py-1 bg-white rounded text-xs font-medium text-slate-900 whitespace-nowrap shadow-lg">
                        <p className="font-semibold">Trusted Landscaper</p>
                        <p className="text-slate-500">5 homes on your block</p>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Ace Roofing */}
                <div className="absolute top-[70%] left-[28%]">
                  <div className="relative group cursor-pointer">
                    <div className="w-8 h-8 bg-emerald-400 rounded-full shadow-lg shadow-emerald-400/50 flex items-center justify-center animate-pulse" style={{ animationDelay: '0.6s' }}>
                      <Building className="w-4 h-4 text-white" />
                    </div>
                    <div className="absolute -top-12 left-1/2 -translate-x-1/2">
                      <div className="px-2 py-1 bg-white rounded text-xs font-medium text-slate-900 whitespace-nowrap shadow-lg">
                        <p className="font-semibold">Ace Roofing</p>
                        <p className="text-slate-500">4 roofs this street</p>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Pool Service */}
                <div className="absolute top-[68%] left-[72%]">
                  <div className="relative group cursor-pointer">
                    <div className="w-8 h-8 bg-emerald-400 rounded-full shadow-lg shadow-emerald-400/50 flex items-center justify-center animate-pulse" style={{ animationDelay: '0.9s' }}>
                      <Activity className="w-4 h-4 text-white" />
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
              <span className="text-sm font-medium text-emerald-800">Hyper-Local Trust</span>
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
              Stop guessing which filter fits or where the shut-off valve is. Access your Model Numbers, Warranty Docs, Paint Codes, and Room Dimensions instantly.
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

          {/* Right - Digital Asset Card */}
          <div className="relative">
            <div className="bg-white rounded-2xl shadow-2xl overflow-hidden">
              {/* Home Profile Hero */}
              <div className="relative h-48">
                <Image
                  src="https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800&q=80"
                  alt="Beautiful modern home"
                  fill
                  className="object-cover"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-black/20 to-transparent" />
                <div className="absolute bottom-4 left-4">
                  <div className="flex items-center gap-2 mb-1">
                    <h3 className="text-lg font-bold text-white">1247 Beverly Drive</h3>
                    <span className="px-2 py-0.5 bg-emerald-500/90 text-white text-xs font-medium rounded-full flex items-center gap-1">
                      <Shield className="w-3 h-3" />
                      Haven Managed
                    </span>
                  </div>
                  <p className="text-slate-300 text-sm">Beverly Hills, CA • 4,200 sq ft</p>
                </div>
              </div>

              {/* Digital Asset Card */}
              <div className="p-5">
                <p className="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-3">Digital Asset Card</p>

                <div className="bg-slate-50 rounded-xl p-4 border border-slate-200">
                  <div className="flex items-start gap-4">
                    <div className="w-16 h-16 bg-slate-200 rounded-lg flex items-center justify-center flex-shrink-0">
                      <Thermometer className="w-8 h-8 text-slate-500" />
                    </div>
                    <div className="flex-1">
                      <p className="text-sm font-semibold text-slate-900">Sub-Zero Refrigerator</p>
                      <p className="text-xs text-slate-500 mb-2">Model: BI-36U/S/TH</p>
                      <div className="flex flex-wrap gap-2">
                        <span className="px-2 py-0.5 bg-emerald-100 text-emerald-700 text-xs font-medium rounded">Warranty: 2027</span>
                        <span className="px-2 py-0.5 bg-slate-200 text-slate-700 text-xs font-medium rounded">Kitchen</span>
                      </div>
                    </div>
                  </div>
                  <div className="mt-4 pt-4 border-t border-slate-200 flex items-center justify-between">
                    <div className="text-xs text-slate-500">
                      <span className="font-medium text-slate-700">Installed:</span> March 2022
                    </div>
                    <button className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-emerald-600 text-white text-xs font-medium rounded-lg hover:bg-emerald-700 transition-colors">
                      <Download className="w-3.5 h-3.5" />
                      Download Manual
                    </button>
                  </div>
                </div>

                {/* Quick Access */}
                <div className="mt-4 flex gap-2">
                  <div className="flex-1 backdrop-blur-xl bg-slate-100 rounded-xl p-3 flex items-center gap-2">
                    <Wifi className="w-4 h-4 text-slate-600" />
                    <div>
                      <p className="text-xs text-slate-500">WiFi</p>
                      <p className="text-sm text-slate-900 font-medium">••••••••</p>
                    </div>
                  </div>
                  <div className="flex-1 backdrop-blur-xl bg-slate-100 rounded-xl p-3 flex items-center gap-2">
                    <Key className="w-4 h-4 text-slate-600" />
                    <div>
                      <p className="text-xs text-slate-500">Gate Code</p>
                      <p className="text-sm text-slate-900 font-medium">#1247</p>
                    </div>
                  </div>
                  <div className="flex-1 backdrop-blur-xl bg-slate-100 rounded-xl p-3 flex items-center gap-2">
                    <Bell className="w-4 h-4 text-slate-600" />
                    <div>
                      <p className="text-xs text-slate-500">Alarm</p>
                      <p className="text-sm text-slate-900 font-medium">••••</p>
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

        {/* Billing Clarity Box */}
        <div className="mt-12 max-w-3xl mx-auto">
          <div className="bg-amber-50 rounded-2xl p-6 border border-amber-200">
            <h3 className="font-semibold text-emerald-950 mb-3 flex items-center gap-2">
              <DollarSign className="w-5 h-5 text-amber-600" />
              How Your Monthly Charge Works
            </h3>
            <div className="grid sm:grid-cols-2 gap-4 mb-4">
              <div className="bg-white rounded-xl p-4">
                <p className="text-sm font-medium text-slate-900 mb-1">Haven Membership</p>
                <p className="text-2xl font-bold text-emerald-600">$149<span className="text-sm text-slate-500 font-normal">/mo</span></p>
                <p className="text-xs text-slate-500 mt-1">Your Home Manager, platform, preventive care</p>
              </div>
              <div className="bg-white rounded-xl p-4">
                <p className="text-sm font-medium text-slate-900 mb-1">Your Vendor Bills</p>
                <p className="text-2xl font-bold text-slate-900">At cost</p>
                <p className="text-xs text-slate-500 mt-1">Electric, water, landscaper, etc. — no markup</p>
              </div>
            </div>
            <p className="text-sm text-slate-600">
              <strong>Example:</strong> Your electric bill is $180, landscaper is $340, and pool service is $175.
              Your total charge = $149 (Haven) + $695 (vendors) = <strong>$844/mo on one statement.</strong>
            </p>
          </div>
        </div>

        {/* Additional pricing note */}
        <div className="mt-8 text-center">
          <p className="text-slate-500 text-sm">
            All plans include FDIC-insured Household Wallet. Cancel anytime. No contracts.
          </p>
        </div>
      </div>
    </section>
  );
}

// ============================================================================
// BILL CALCULATOR
// ============================================================================

function BillCalculatorSection() {
  const [selectedServices, setSelectedServices] = useState<string[]>(['electric', 'water', 'landscaping', 'pool']);

  const services = [
    { id: 'electric', name: 'Electric', avgCost: 187 },
    { id: 'water', name: 'Water', avgCost: 85 },
    { id: 'gas', name: 'Gas', avgCost: 65 },
    { id: 'internet', name: 'Internet', avgCost: 89 },
    { id: 'landscaping', name: 'Landscaping', avgCost: 340 },
    { id: 'pool', name: 'Pool Service', avgCost: 175 },
    { id: 'housekeeping', name: 'Housekeeping', avgCost: 400 },
    { id: 'pest', name: 'Pest Control', avgCost: 75 },
    { id: 'security', name: 'Security System', avgCost: 49 },
    { id: 'trash', name: 'Trash/Recycling', avgCost: 35 },
  ];

  const toggleService = (id: string) => {
    setSelectedServices(prev =>
      prev.includes(id) ? prev.filter(s => s !== id) : [...prev, id]
    );
  };

  const totalBills = services
    .filter(s => selectedServices.includes(s.id))
    .reduce((sum, s) => sum + s.avgCost, 0);

  const vendorCount = selectedServices.length;
  const passwordsEliminated = vendorCount;
  const invoicesConsolidated = vendorCount;

  return (
    <section className="py-24 px-4 sm:px-6 lg:px-8 bg-emerald-950">
      <div className="max-w-5xl mx-auto">
        <div className="text-center mb-12">
          <h2 className="font-serif text-3xl sm:text-4xl lg:text-5xl font-medium text-white mb-4">
            Calculate Your Bill Consolidation
          </h2>
          <p className="text-lg text-emerald-300 max-w-2xl mx-auto">
            See how much simpler your life becomes when all your home bills flow through Haven.
          </p>
        </div>

        <div className="grid lg:grid-cols-2 gap-8">
          {/* Left - Service Selection */}
          <div className="bg-emerald-900/50 rounded-2xl p-6 border border-emerald-800">
            <h3 className="text-lg font-semibold text-white mb-4">Select Your Services</h3>
            <div className="grid grid-cols-2 gap-3">
              {services.map(service => (
                <button
                  key={service.id}
                  onClick={() => toggleService(service.id)}
                  className={`p-3 rounded-xl text-left transition-all ${
                    selectedServices.includes(service.id)
                      ? 'bg-emerald-600 border-emerald-500'
                      : 'bg-emerald-900 border-emerald-700 hover:border-emerald-600'
                  } border`}
                >
                  <div className="flex items-center justify-between">
                    <span className="text-sm font-medium text-white">{service.name}</span>
                    {selectedServices.includes(service.id) && (
                      <Check className="w-4 h-4 text-white" />
                    )}
                  </div>
                  <span className="text-xs text-emerald-300">${service.avgCost}/mo avg</span>
                </button>
              ))}
            </div>
          </div>

          {/* Right - Results */}
          <div className="bg-white rounded-2xl p-6">
            <h3 className="text-lg font-semibold text-emerald-950 mb-6">Your Haven Statement</h3>

            {/* Single Statement Preview */}
            <div className="bg-slate-50 rounded-xl p-4 mb-6 border border-slate-200">
              <div className="flex items-center justify-between mb-3">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-emerald-600 rounded-lg flex items-center justify-center">
                    <Home className="w-5 h-5 text-white" />
                  </div>
                  <div>
                    <p className="text-sm font-semibold text-slate-900">December Statement</p>
                    <p className="text-xs text-slate-500">Haven Home Management</p>
                  </div>
                </div>
                <div className="text-right">
                  <p className="text-2xl font-bold text-emerald-950">${totalBills.toLocaleString()}</p>
                  <p className="text-xs text-slate-500">Auto-paid</p>
                </div>
              </div>

              <div className="space-y-2">
                {services
                  .filter(s => selectedServices.includes(s.id))
                  .slice(0, 4)
                  .map(service => (
                    <div key={service.id} className="flex items-center justify-between text-sm">
                      <span className="text-slate-600">{service.name}</span>
                      <span className="text-slate-900 font-medium">${service.avgCost}</span>
                    </div>
                  ))}
                {selectedServices.length > 4 && (
                  <div className="text-sm text-slate-500">
                    + {selectedServices.length - 4} more services
                  </div>
                )}
              </div>
            </div>

            {/* Impact Stats */}
            <div className="grid grid-cols-3 gap-4 mb-6">
              <div className="text-center p-3 bg-emerald-50 rounded-xl">
                <p className="text-2xl font-bold text-emerald-600">{vendorCount}</p>
                <p className="text-xs text-slate-600">Vendors Managed</p>
              </div>
              <div className="text-center p-3 bg-amber-50 rounded-xl">
                <p className="text-2xl font-bold text-amber-600">{passwordsEliminated}</p>
                <p className="text-xs text-slate-600">Passwords Eliminated</p>
              </div>
              <div className="text-center p-3 bg-sky-50 rounded-xl">
                <p className="text-2xl font-bold text-sky-600">{invoicesConsolidated}</p>
                <p className="text-xs text-slate-600">Invoices → 1</p>
              </div>
            </div>

            <p className="text-center text-sm text-slate-500 mb-4">
              + $149/mo Haven Concierge membership
            </p>

            <Link
              href="/register"
              className="block w-full text-center px-6 py-3 bg-emerald-950 text-white font-medium rounded-xl hover:bg-emerald-900 transition-colors"
            >
              See If Haven Is In Your Area
            </Link>
          </div>
        </div>
      </div>
    </section>
  );
}

// ============================================================================
// SOCIAL PROOF QUOTES
// ============================================================================

function SocialProofSection() {
  const quotes = [
    {
      quote: "I used to spend 3 hours a month just paying bills and chasing vendors. Now I glance at one statement and move on with my life.",
      author: "Jennifer M.",
      role: "Working mom of 3",
      highlight: "3 hours → 5 minutes",
    },
    {
      quote: "When our AC broke at 2am, I just texted Sarah. By morning, it was fixed. I never called a single contractor.",
      author: "Marcus R.",
      role: "Tech executive",
      highlight: "Zero vendor calls",
    },
    {
      quote: "The transparency is incredible. I finally understand where every dollar goes, and nothing slips through the cracks.",
      author: "Priya S.",
      role: "Attorney",
      highlight: "Full visibility",
    },
  ];

  return (
    <section className="py-24 px-4 sm:px-6 lg:px-8 bg-slate-50">
      <div className="max-w-7xl mx-auto">
        <div className="text-center mb-16">
          <h2 className="font-serif text-3xl sm:text-4xl lg:text-5xl font-medium text-emerald-950 mb-4">
            What Homeowners Say
          </h2>
          <p className="text-lg text-slate-600 max-w-2xl mx-auto">
            Real families who&apos;ve eliminated the chaos of home management.
          </p>
        </div>

        <div className="grid md:grid-cols-3 gap-8">
          {quotes.map((item, index) => (
            <div key={index} className="bg-white rounded-2xl p-8 shadow-sm border border-slate-100">
              <div className="flex items-center gap-1 mb-4">
                {[...Array(5)].map((_, i) => (
                  <Star key={i} className="w-5 h-5 text-amber-400 fill-amber-400" />
                ))}
              </div>
              <blockquote className="text-slate-700 leading-relaxed mb-6">
                &quot;{item.quote}&quot;
              </blockquote>
              <div className="flex items-center justify-between">
                <div>
                  <p className="font-medium text-slate-900">{item.author}</p>
                  <p className="text-sm text-slate-500">{item.role}</p>
                </div>
                <div className="px-3 py-1.5 bg-emerald-100 rounded-full">
                  <span className="text-sm font-medium text-emerald-700">{item.highlight}</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

// ============================================================================
// FAQ SECTION
// ============================================================================

function FAQSection() {
  const [openIndex, setOpenIndex] = useState<number | null>(0);

  const faqs = [
    {
      question: "How does the One Bill system actually work?",
      answer: "When you join Haven, we become the payment contact for all your home vendors—utilities, landscapers, pool service, etc. Each vendor sends their invoice to Haven. We audit every charge, pay them automatically from your Household Wallet, and send you one consolidated statement on the 1st of each month. Routine bills are auto-approved; anything unusual or over your threshold gets flagged for your approval.",
    },
    {
      question: "Is my money safe? How does the Household Wallet work?",
      answer: "Your Household Wallet is FDIC-insured and held at a regulated partner bank. You fund the wallet via bank transfer, and Haven uses it to pay your vendors. You maintain full visibility and control—you can see every transaction in real-time and withdraw funds at any time. We never mark up vendor costs or take a percentage of transactions.",
    },
    {
      question: "What if I want to approve certain expenses?",
      answer: "You set your own approval thresholds. For example, you might set auto-approve for anything under $500 (routine bills) but require approval for larger expenses. Your Home Manager will text you for approval on big items, with full context and their recommendation, so you can approve with one tap.",
    },
    {
      question: "What's included in the monthly membership vs. actual vendor costs?",
      answer: "Your Haven membership ($49-$300/mo depending on tier) covers the service: your Home Manager, the platform, preventive maintenance coordination, and bill consolidation. Actual vendor costs (electric bill, landscaper, plumber, etc.) are billed at-cost through your statement—no markup. So if your electrician charges $200, you pay $200.",
    },
    {
      question: "Can I keep some vendors and add new ones?",
      answer: "Yes! Keep your trusted vendors and we'll manage the relationship. If you need a new vendor, your Home Manager will recommend options from our vetted network—often with neighborhood group rates. Either way, all bills flow through your single Haven statement.",
    },
    {
      question: "What happens if something goes wrong at 2am?",
      answer: "Concierge and Estate members have 24/7 emergency support. Text your Home Manager anytime—even overnight—and we'll dispatch the right vendor. You won't have to Google plumbers at midnight or wait on hold with your insurance company.",
    },
  ];

  return (
    <section className="py-24 px-4 sm:px-6 lg:px-8 bg-white">
      <div className="max-w-4xl mx-auto">
        <div className="text-center mb-16">
          <h2 className="font-serif text-3xl sm:text-4xl lg:text-5xl font-medium text-emerald-950 mb-4">
            Frequently Asked Questions
          </h2>
          <p className="text-lg text-slate-600">
            Everything you need to know about how Haven handles your home.
          </p>
        </div>

        <div className="space-y-4">
          {faqs.map((faq, index) => (
            <div
              key={index}
              className="bg-slate-50 rounded-xl border border-slate-200 overflow-hidden"
            >
              <button
                onClick={() => setOpenIndex(openIndex === index ? null : index)}
                className="w-full p-6 text-left flex items-center justify-between gap-4"
              >
                <span className="font-medium text-emerald-950">{faq.question}</span>
                <ArrowRight
                  className={`w-5 h-5 text-emerald-600 flex-shrink-0 transition-transform ${
                    openIndex === index ? 'rotate-90' : ''
                  }`}
                />
              </button>
              {openIndex === index && (
                <div className="px-6 pb-6">
                  <p className="text-slate-600 leading-relaxed">{faq.answer}</p>
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
// STICKY CTA FOOTER
// ============================================================================

function StickyCTAFooter() {
  return (
    <div className="fixed bottom-0 left-0 right-0 z-40 bg-white/95 backdrop-blur-lg border-t border-slate-200 py-4 px-4 sm:px-6 lg:px-8 lg:hidden">
      <div className="max-w-7xl mx-auto flex items-center justify-between gap-4">
        <div className="hidden sm:block">
          <p className="text-sm font-medium text-slate-900">One bill. One contact. Zero hassle.</p>
          <p className="text-xs text-slate-500">See if Haven is available in your neighborhood</p>
        </div>
        <Link
          href="/register"
          className="flex-1 sm:flex-none inline-flex items-center justify-center gap-2 px-6 py-3 bg-emerald-950 text-white text-sm font-medium rounded-xl hover:bg-emerald-900 transition-colors"
        >
          Check Availability
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
              <a href="#how-it-works" className="text-slate-600 hover:text-emerald-950 text-sm font-medium transition-colors">How It Works</a>
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

      {/* How It Works - 3 Steps */}
      <HowItWorksSection />

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

      {/* Bill Calculator */}
      <BillCalculatorSection />

      {/* Social Proof */}
      <SocialProofSection />

      {/* FAQ */}
      <FAQSection />

      {/* Final CTA */}
      <section className="py-24 px-4 sm:px-6 lg:px-8 bg-gradient-to-b from-white to-emerald-50">
        <div className="max-w-4xl mx-auto text-center">
          <h2 className="font-serif text-4xl sm:text-5xl font-medium text-emerald-950 mb-6">
            One bill. One contact.<br />Zero hassle.
          </h2>
          <p className="text-xl text-slate-600 mb-4 max-w-2xl mx-auto">
            Stop being the unpaid project manager of your own home.
          </p>
          <p className="text-lg text-emerald-700 font-medium mb-10 max-w-2xl mx-auto">
            Let Haven consolidate your vendors, pay your bills, and handle the chaos—so you can just enjoy the house.
          </p>
          <Link
            href="/register"
            className="inline-flex items-center gap-2 px-8 py-4 bg-emerald-950 text-white text-lg font-medium rounded-xl hover:bg-emerald-900 transition-colors shadow-lg shadow-emerald-950/20"
          >
            See If Haven Is In Your Area
            <ArrowRight className="w-5 h-5" />
          </Link>
          <p className="text-sm text-slate-500 mt-4">Currently serving select neighborhoods in Los Angeles and Orange County.</p>
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
                <li><a href="#how-it-works" className="text-emerald-300 hover:text-white text-sm transition-colors">How It Works</a></li>
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
