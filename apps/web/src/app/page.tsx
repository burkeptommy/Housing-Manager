'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Shield,
  Plane,
  Calendar,
  Car,
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
  ShoppingCart,
  Wifi,
  Key,
  ChefHat,
  Bell,
  Activity,
  Send,
  CheckCircle2,
  Clock,
  Package,
  Gauge,
} from 'lucide-react';

// ============================================================================
// ROTATING WORDS CONFIG
// ============================================================================

const rotatingWords = [
  { word: 'Home', color: 'text-emerald-600' },
  { word: 'Family', color: 'text-blue-600' },
  { word: 'Finances', color: 'text-amber-500' },
  { word: 'Travel', color: 'text-sky-500' },
  { word: 'Projects', color: 'text-orange-500' },
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
              <span className="text-sm font-medium text-emerald-800">The Ultimate Upgrade for Your Life</span>
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
              A dedicated Chief of Staff. A secure Financial Command Center. A living User Manual for your property. All in one app.
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
                href="#pillars"
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

          {/* Right Column - Floating UI Stack */}
          <div className="relative h-[500px] lg:h-[600px] hidden lg:block">
            {/* Layer 1 - Morning Briefing (Back) */}
            <motion.div
              initial={{ opacity: 0, y: 40 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2, duration: 0.6 }}
              className="absolute top-0 right-0 w-[380px] bg-white rounded-2xl shadow-2xl shadow-slate-900/10 border border-slate-200 overflow-hidden"
            >
              <div className="p-4 border-b border-slate-100">
                <div className="flex items-center gap-2">
                  <div className="w-8 h-8 bg-emerald-100 rounded-lg flex items-center justify-center">
                    <Sparkles className="w-4 h-4 text-emerald-600" />
                  </div>
                  <div>
                    <p className="text-xs text-slate-500">Good Morning</p>
                    <p className="text-sm font-semibold text-slate-900">Today&apos;s Briefing</p>
                  </div>
                </div>
              </div>
              <div className="p-4 space-y-3">
                <div className="flex items-center gap-3 p-3 bg-emerald-50 rounded-xl">
                  <CheckCircle2 className="w-5 h-5 text-emerald-600" />
                  <div>
                    <p className="text-sm font-medium text-slate-900">All bills paid this week</p>
                    <p className="text-xs text-slate-500">Next: Electric on Dec 23</p>
                  </div>
                </div>
                <div className="flex items-center gap-3 p-3 bg-slate-50 rounded-xl">
                  <Clock className="w-5 h-5 text-slate-500" />
                  <div>
                    <p className="text-sm font-medium text-slate-900">Handyman visit scheduled</p>
                    <p className="text-xs text-slate-500">Tomorrow at 10:00 AM</p>
                  </div>
                </div>
                <div className="flex items-center gap-3 p-3 bg-slate-50 rounded-xl">
                  <Package className="w-5 h-5 text-slate-500" />
                  <div>
                    <p className="text-sm font-medium text-slate-900">2 packages arriving today</p>
                    <p className="text-xs text-slate-500">Amazon, Chewy</p>
                  </div>
                </div>
              </div>
            </motion.div>

            {/* Layer 2 - Money Approval (Middle) */}
            <motion.div
              initial={{ opacity: 0, y: 40, x: -20 }}
              animate={{ opacity: 1, y: 0, x: 0 }}
              transition={{ delay: 0.4, duration: 0.6 }}
              className="absolute top-40 left-0 w-[320px] bg-white rounded-2xl shadow-2xl shadow-slate-900/15 border border-slate-200 overflow-hidden"
            >
              <div className="p-4">
                <div className="flex items-center gap-3 mb-4">
                  <div className="w-10 h-10 bg-amber-100 rounded-full flex items-center justify-center">
                    <DollarSign className="w-5 h-5 text-amber-600" />
                  </div>
                  <div>
                    <p className="text-xs text-amber-600 font-medium">Approval Required</p>
                    <p className="text-sm font-semibold text-slate-900">Roof Repair Quote</p>
                  </div>
                </div>
                <div className="flex items-center justify-between p-3 bg-slate-50 rounded-xl mb-4">
                  <div>
                    <p className="text-xs text-slate-500">Ace Roofing Co.</p>
                    <p className="text-lg font-bold text-slate-900">$1,200</p>
                  </div>
                  <span className="px-2 py-1 bg-emerald-100 text-emerald-700 text-xs font-medium rounded-full">
                    Recommended
                  </span>
                </div>
                <div className="flex gap-2">
                  <button className="flex-1 px-4 py-2 bg-emerald-600 text-white text-sm font-medium rounded-lg">
                    Approve
                  </button>
                  <button className="flex-1 px-4 py-2 bg-slate-100 text-slate-600 text-sm font-medium rounded-lg">
                    Details
                  </button>
                </div>
              </div>
            </motion.div>

            {/* Layer 3 - Travel Itinerary (Front) */}
            <motion.div
              initial={{ opacity: 0, y: 40, x: 20 }}
              animate={{ opacity: 1, y: 0, x: 0 }}
              transition={{ delay: 0.6, duration: 0.6 }}
              className="absolute bottom-0 right-8 w-[300px] bg-gradient-to-br from-sky-500 to-sky-600 rounded-2xl shadow-2xl shadow-sky-500/30 overflow-hidden text-white"
            >
              <div className="p-4">
                <div className="flex items-center gap-2 mb-3">
                  <Plane className="w-5 h-5" />
                  <p className="text-sm font-medium opacity-90">Upcoming Trip</p>
                </div>
                <p className="text-xl font-bold mb-1">Aspen, Colorado</p>
                <p className="text-sm opacity-80 mb-4">Dec 26 - Jan 2</p>
                <div className="flex items-center gap-4 text-sm">
                  <div className="flex items-center gap-1">
                    <CheckCircle2 className="w-4 h-4" />
                    <span>Flights booked</span>
                  </div>
                  <div className="flex items-center gap-1">
                    <CheckCircle2 className="w-4 h-4" />
                    <span>Home secured</span>
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
// CORE PILLARS SECTION
// ============================================================================

function CorePillarsSection() {
  return (
    <section id="pillars" className="py-24 px-4 sm:px-6 lg:px-8 bg-white">
      <div className="max-w-7xl mx-auto">
        <div className="text-center mb-16">
          <p className="text-sm font-medium text-emerald-700 uppercase tracking-wider mb-3">The Foundation</p>
          <h2 className="font-serif text-4xl sm:text-5xl font-medium text-emerald-950 mb-4">
            The Three Must-Haves.
          </h2>
          <p className="text-lg text-slate-600 max-w-2xl mx-auto">
            These core pillars transform how you manage your household—from finances to maintenance to delegation.
          </p>
        </div>

        <div className="grid lg:grid-cols-3 gap-8">
          {/* Pillar 1 - Financial Command Center */}
          <div className="group bg-slate-50 rounded-2xl p-8 hover:shadow-xl transition-all duration-300 border border-slate-100">
            <div className="w-14 h-14 bg-amber-100 rounded-xl flex items-center justify-center mb-6 group-hover:bg-amber-200 transition-colors">
              <DollarSign className="w-7 h-7 text-amber-700" />
            </div>
            <h3 className="font-serif text-2xl font-medium text-emerald-950 mb-2">
              Financial Command Center.
            </h3>
            <p className="text-sm font-medium text-amber-600 mb-4 uppercase tracking-wider">
              One-Bill Living
            </p>
            <p className="text-slate-600 leading-relaxed mb-6">
              Replace 20 different login portals with one single monthly payment to Haven. We pay your utilities, vendors, and subscriptions for you—you simply review and tap &apos;Approve&apos; on the big ticket items.
            </p>
            {/* Visual - Budget Gauge */}
            <div className="p-4 bg-white rounded-xl border border-slate-200">
              <div className="flex items-center justify-between mb-2">
                <span className="text-sm font-medium text-slate-700">December Budget</span>
                <span className="text-sm font-semibold text-emerald-600">$4,280 / $5,000</span>
              </div>
              <div className="h-3 bg-slate-100 rounded-full overflow-hidden">
                <div className="h-full w-[85%] bg-gradient-to-r from-emerald-500 to-emerald-400 rounded-full" />
              </div>
              <p className="text-xs text-slate-500 mt-2">All bills paid. $720 remaining.</p>
            </div>
          </div>

          {/* Pillar 2 - Predictive Asset Health */}
          <div className="group bg-slate-50 rounded-2xl p-8 hover:shadow-xl transition-all duration-300 border border-slate-100">
            <div className="w-14 h-14 bg-emerald-100 rounded-xl flex items-center justify-center mb-6 group-hover:bg-emerald-200 transition-colors">
              <Activity className="w-7 h-7 text-emerald-700" />
            </div>
            <h3 className="font-serif text-2xl font-medium text-emerald-950 mb-2">
              Predictive Asset Health.
            </h3>
            <p className="text-sm font-medium text-emerald-600 mb-4 uppercase tracking-wider">
              Proactive Maintenance
            </p>
            <p className="text-slate-600 leading-relaxed mb-6">
              We prevent breakdowns before they happen. Your Home Profile tracks every warranty and service date, scheduling pros automatically when maintenance is due.
            </p>
            {/* Visual - Asset Health Card */}
            <div className="p-4 bg-white rounded-xl border border-slate-200 space-y-3">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <div className="w-8 h-8 bg-emerald-100 rounded-lg flex items-center justify-center">
                    <Gauge className="w-4 h-4 text-emerald-600" />
                  </div>
                  <span className="text-sm font-medium text-slate-700">HVAC System</span>
                </div>
                <span className="px-2 py-1 bg-emerald-100 text-emerald-700 text-xs font-medium rounded-full">Healthy</span>
              </div>
              <div className="flex items-center justify-between text-xs text-slate-500">
                <span>Filter changed: 2 weeks ago</span>
                <span>Next service: Feb 15</span>
              </div>
            </div>
          </div>

          {/* Pillar 3 - Swipe-to-Delegate */}
          <div className="group bg-slate-50 rounded-2xl p-8 hover:shadow-xl transition-all duration-300 border border-slate-100">
            <div className="w-14 h-14 bg-indigo-100 rounded-xl flex items-center justify-center mb-6 group-hover:bg-indigo-200 transition-colors">
              <Send className="w-7 h-7 text-indigo-700" />
            </div>
            <h3 className="font-serif text-2xl font-medium text-emerald-950 mb-2">
              Swipe-to-Delegate.
            </h3>
            <p className="text-sm font-medium text-indigo-600 mb-4 uppercase tracking-wider">
              Your Manager&apos;s Queue
            </p>
            <p className="text-slate-600 leading-relaxed mb-6">
              Turn a &apos;To-Do&apos; into a &apos;Done&apos; with one swipe. Whether it&apos;s a leaky faucet or a research project, just assign it to your Manager&apos;s Queue.
            </p>
            {/* Visual - Delegate Action */}
            <div className="p-4 bg-white rounded-xl border border-slate-200">
              <div className="flex items-center gap-3 mb-3">
                <div className="w-10 h-10 bg-indigo-100 rounded-full flex items-center justify-center">
                  <Wrench className="w-5 h-5 text-indigo-600" />
                </div>
                <div className="flex-1">
                  <p className="text-sm font-medium text-slate-900">Kitchen faucet dripping</p>
                  <p className="text-xs text-slate-500">Created today</p>
                </div>
              </div>
              <div className="flex items-center gap-2">
                <div className="flex-1 h-10 bg-gradient-to-r from-indigo-500 to-indigo-600 rounded-lg flex items-center justify-center text-white text-sm font-medium">
                  <ArrowRight className="w-4 h-4 mr-2" />
                  Swipe to Delegate
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
// LIFESTYLE SUITE SECTION
// ============================================================================

function LifestyleSuiteSection() {
  return (
    <section className="py-24 px-4 sm:px-6 lg:px-8 bg-emerald-950">
      <div className="max-w-7xl mx-auto">
        <div className="text-center mb-16">
          <p className="text-sm font-medium text-emerald-400 uppercase tracking-wider mb-3">The Lifestyle Suite</p>
          <h2 className="font-serif text-4xl sm:text-5xl font-medium text-white mb-4">
            Beyond the House.
          </h2>
          <p className="text-lg text-emerald-200 max-w-2xl mx-auto">
            Managing the rhythm of life—from travel planning to grocery runs to family logistics.
          </p>
        </div>

        <div className="grid md:grid-cols-2 gap-6">
          {/* Card A - The Travel Agent */}
          <div className="bg-gradient-to-br from-sky-500/20 to-sky-600/20 rounded-2xl p-8 border border-sky-500/30">
            <div className="flex items-center gap-3 mb-6">
              <div className="w-12 h-12 bg-sky-500/20 rounded-xl flex items-center justify-center">
                <Plane className="w-6 h-6 text-sky-300" />
              </div>
              <span className="text-sm font-medium text-sky-300 uppercase tracking-wider">Travel Agent</span>
            </div>
            <h3 className="font-serif text-2xl font-medium text-white mb-3">
              Vacation Without the Stress.
            </h3>
            <p className="text-emerald-100 leading-relaxed mb-6">
              From booking flights to securing the house while you&apos;re away. We handle the itinerary and the home logistics—water off, mail held, alarm set.
            </p>
            {/* Visual - Flight Confirmation in Messages */}
            <div className="bg-white/10 backdrop-blur-sm rounded-xl p-4 border border-white/10">
              <div className="flex items-center gap-3 mb-3">
                <div className="w-8 h-8 bg-white/20 rounded-full flex items-center justify-center">
                  <span className="text-sm font-bold text-white">S</span>
                </div>
                <div>
                  <p className="text-sm font-medium text-white">Steve, Your Manager</p>
                  <p className="text-xs text-emerald-200">Just now</p>
                </div>
              </div>
              <div className="bg-white/10 rounded-lg p-3">
                <p className="text-sm text-white">Flights confirmed for Aspen trip. I&apos;ve scheduled the house prep protocol for Dec 25. Safe travels!</p>
                <div className="flex items-center gap-2 mt-2">
                  <span className="px-2 py-1 bg-sky-500/30 text-sky-200 text-xs rounded">AA 1247 → DEN</span>
                  <span className="px-2 py-1 bg-emerald-500/30 text-emerald-200 text-xs rounded">Home Secured</span>
                </div>
              </div>
            </div>
          </div>

          {/* Card B - The Smart Stockroom */}
          <div className="bg-gradient-to-br from-orange-500/20 to-orange-600/20 rounded-2xl p-8 border border-orange-500/30">
            <div className="flex items-center gap-3 mb-6">
              <div className="w-12 h-12 bg-orange-500/20 rounded-xl flex items-center justify-center">
                <ShoppingCart className="w-6 h-6 text-orange-300" />
              </div>
              <span className="text-sm font-medium text-orange-300 uppercase tracking-wider">Smart Stockroom</span>
            </div>
            <h3 className="font-serif text-2xl font-medium text-white mb-3">
              Never Run Out Again.
            </h3>
            <p className="text-emerald-100 leading-relaxed mb-6">
              Scan barcodes or push your shopping list to your Manager for instant procurement. We track your essentials and restock before you run out.
            </p>
            {/* Visual - Pending Order */}
            <div className="bg-white/10 backdrop-blur-sm rounded-xl p-4 border border-white/10">
              <div className="flex items-center justify-between mb-3">
                <div className="flex items-center gap-2">
                  <div className="w-8 h-8 bg-green-500/30 rounded-lg flex items-center justify-center">
                    <Package className="w-4 h-4 text-green-300" />
                  </div>
                  <span className="text-sm font-medium text-white">Whole Foods Order</span>
                </div>
                <span className="px-2 py-1 bg-amber-500/30 text-amber-200 text-xs font-medium rounded-full">Pending</span>
              </div>
              <div className="text-xs text-emerald-200 space-y-1">
                <p>• Milk, Eggs, Bread (staples)</p>
                <p>• Coffee beans (low stock alert)</p>
                <p>• Weekly produce box</p>
              </div>
              <p className="text-xs text-emerald-300 mt-3">Delivery: Tomorrow 10am-12pm</p>
            </div>
          </div>

          {/* Card C - Family Logistics */}
          <div className="bg-gradient-to-br from-blue-500/20 to-blue-600/20 rounded-2xl p-8 border border-blue-500/30">
            <div className="flex items-center gap-3 mb-6">
              <div className="w-12 h-12 bg-blue-500/20 rounded-xl flex items-center justify-center">
                <Users className="w-6 h-6 text-blue-300" />
              </div>
              <span className="text-sm font-medium text-blue-300 uppercase tracking-wider">Family Logistics</span>
            </div>
            <h3 className="font-serif text-2xl font-medium text-white mb-3">
              Everyone in Sync.
            </h3>
            <p className="text-emerald-100 leading-relaxed mb-6">
              Know where everyone is without the nagging. Integrated schedules for kids, nannies, tutors, and after-school activities.
            </p>
            {/* Visual - Family Status */}
            <div className="bg-white/10 backdrop-blur-sm rounded-xl p-4 border border-white/10">
              <p className="text-xs text-emerald-300 uppercase tracking-wider mb-3">Family Status</p>
              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <div className="w-6 h-6 bg-emerald-500/30 rounded-full flex items-center justify-center">
                      <span className="text-xs font-bold text-white">B</span>
                    </div>
                    <span className="text-sm text-white">Bob</span>
                  </div>
                  <span className="text-xs text-emerald-200 flex items-center gap-1">
                    <Home className="w-3 h-3" /> Home
                  </span>
                </div>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <div className="w-6 h-6 bg-blue-500/30 rounded-full flex items-center justify-center">
                      <span className="text-xs font-bold text-white">A</span>
                    </div>
                    <span className="text-sm text-white">Alice</span>
                  </div>
                  <span className="text-xs text-blue-200 flex items-center gap-1">
                    <Car className="w-3 h-3" /> School pickup
                  </span>
                </div>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <div className="w-6 h-6 bg-purple-500/30 rounded-full flex items-center justify-center">
                      <span className="text-xs font-bold text-white">E</span>
                    </div>
                    <span className="text-sm text-white">Emma</span>
                  </div>
                  <span className="text-xs text-purple-200 flex items-center gap-1">
                    <Activity className="w-3 h-3" /> Soccer practice
                  </span>
                </div>
              </div>
            </div>
          </div>

          {/* Card D - Event Orchestration */}
          <div className="bg-gradient-to-br from-purple-500/20 to-purple-600/20 rounded-2xl p-8 border border-purple-500/30">
            <div className="flex items-center gap-3 mb-6">
              <div className="w-12 h-12 bg-purple-500/20 rounded-xl flex items-center justify-center">
                <ChefHat className="w-6 h-6 text-purple-300" />
              </div>
              <span className="text-sm font-medium text-purple-300 uppercase tracking-wider">Event Orchestration</span>
            </div>
            <h3 className="font-serif text-2xl font-medium text-white mb-3">
              Hosting Made Simple.
            </h3>
            <p className="text-emerald-100 leading-relaxed mb-6">
              From private chefs to cleaners, we coordinate the vendors so you can be the guest at your own party.
            </p>
            {/* Visual - Calendar Event */}
            <div className="bg-white/10 backdrop-blur-sm rounded-xl p-4 border border-white/10">
              <div className="flex items-center gap-3 mb-3">
                <div className="w-10 h-10 bg-purple-500/30 rounded-lg flex items-center justify-center">
                  <Calendar className="w-5 h-5 text-purple-300" />
                </div>
                <div>
                  <p className="text-sm font-medium text-white">Holiday Dinner Party</p>
                  <p className="text-xs text-emerald-200">Saturday, Dec 21 • 7:00 PM</p>
                </div>
              </div>
              <div className="flex flex-wrap gap-2 text-xs">
                <span className="px-2 py-1 bg-emerald-500/30 text-emerald-200 rounded flex items-center gap-1">
                  <CheckCircle2 className="w-3 h-3" /> Chef confirmed
                </span>
                <span className="px-2 py-1 bg-emerald-500/30 text-emerald-200 rounded flex items-center gap-1">
                  <CheckCircle2 className="w-3 h-3" /> Cleaners scheduled
                </span>
                <span className="px-2 py-1 bg-amber-500/30 text-amber-200 rounded flex items-center gap-1">
                  <Clock className="w-3 h-3" /> Flowers pending
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

// ============================================================================
// USER MANUAL SECTION
// ============================================================================

function UserManualSection() {
  return (
    <section className="py-24 px-4 sm:px-6 lg:px-8 bg-slate-50">
      <div className="max-w-7xl mx-auto">
        <div className="grid lg:grid-cols-2 gap-12 items-center">
          {/* Left - Text */}
          <div>
            <p className="text-sm font-medium text-emerald-700 uppercase tracking-wider mb-3">The Vault</p>
            <h2 className="font-serif text-4xl sm:text-5xl font-medium text-emerald-950 mb-6">
              The Manual Your Home Never Came With.
            </h2>
            <p className="text-lg text-slate-600 leading-relaxed mb-8">
              Forget digging through junk drawers. Access your Wi-Fi passwords, gate codes, paint colors, and property lines instantly in one secure vault.
            </p>
            <div className="space-y-4">
              <div className="flex items-start gap-3">
                <div className="w-10 h-10 bg-emerald-100 rounded-lg flex items-center justify-center flex-shrink-0">
                  <Wifi className="w-5 h-5 text-emerald-600" />
                </div>
                <div>
                  <p className="font-medium text-slate-900">Instant Access Codes</p>
                  <p className="text-sm text-slate-500">WiFi, alarm, gate codes—all in one tap</p>
                </div>
              </div>
              <div className="flex items-start gap-3">
                <div className="w-10 h-10 bg-emerald-100 rounded-lg flex items-center justify-center flex-shrink-0">
                  <FileText className="w-5 h-5 text-emerald-600" />
                </div>
                <div>
                  <p className="font-medium text-slate-900">Digital Document Vault</p>
                  <p className="text-sm text-slate-500">Warranties, manuals, deeds, and insurance policies</p>
                </div>
              </div>
              <div className="flex items-start gap-3">
                <div className="w-10 h-10 bg-emerald-100 rounded-lg flex items-center justify-center flex-shrink-0">
                  <Home className="w-5 h-5 text-emerald-600" />
                </div>
                <div>
                  <p className="font-medium text-slate-900">Room-by-Room Details</p>
                  <p className="text-sm text-slate-500">Paint colors, flooring specs, fixture info</p>
                </div>
              </div>
            </div>
          </div>

          {/* Right - Visual (Home Profile Hero) */}
          <div className="relative">
            <div className="relative rounded-2xl overflow-hidden shadow-2xl shadow-slate-900/20">
              {/* Property Image */}
              <div className="relative h-[400px]">
                <Image
                  src="https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800&q=80"
                  alt="Beautiful modern home"
                  fill
                  className="object-cover"
                />
                {/* Gradient Overlay */}
                <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent" />

                {/* Content Overlay */}
                <div className="absolute bottom-0 left-0 right-0 p-6">
                  <div className="flex items-center gap-2 mb-2">
                    <h3 className="text-xl font-bold text-white">1247 Beverly Drive</h3>
                    <span className="px-2 py-0.5 bg-emerald-500/90 text-white text-xs font-medium rounded-full flex items-center gap-1">
                      <Shield className="w-3 h-3" />
                      Haven Managed
                    </span>
                  </div>
                  <p className="text-slate-300 text-sm mb-4">Beverly Hills, CA</p>

                  {/* Quick Access Dock */}
                  <div className="flex gap-2">
                    <div className="backdrop-blur-xl bg-white/10 rounded-xl border border-white/20 p-3 flex items-center gap-2">
                      <Wifi className="w-5 h-5 text-white" />
                      <span className="text-sm text-white font-medium">WiFi</span>
                    </div>
                    <div className="backdrop-blur-xl bg-white/10 rounded-xl border border-white/20 p-3 flex items-center gap-2">
                      <Key className="w-5 h-5 text-white" />
                      <span className="text-sm text-white font-medium">Gate</span>
                    </div>
                    <div className="backdrop-blur-xl bg-white/10 rounded-xl border border-white/20 p-3 flex items-center gap-2">
                      <Bell className="w-5 h-5 text-white" />
                      <span className="text-sm text-white font-medium">Alarm</span>
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
// SOCIAL PROOF SECTION
// ============================================================================

function SocialProofSection() {
  return (
    <section id="community" className="py-24 px-4 sm:px-6 lg:px-8 bg-white">
      <div className="max-w-7xl mx-auto">
        <div className="grid lg:grid-cols-2 gap-12 items-center">
          {/* Left - Map Visual */}
          <div className="relative order-2 lg:order-1">
            <div className="relative rounded-2xl overflow-hidden shadow-2xl shadow-slate-900/20 bg-slate-100 h-[400px]">
              {/* Map Background */}
              <Image
                src="https://images.unsplash.com/photo-1524661135-423995f22d0b?w=800&q=80"
                alt="Neighborhood map"
                fill
                className="object-cover opacity-60"
              />
              {/* Overlay */}
              <div className="absolute inset-0 bg-gradient-to-t from-slate-900/80 via-slate-900/20 to-transparent" />

              {/* Emerald Pins */}
              <div className="absolute inset-0 p-8">
                <div className="relative w-full h-full">
                  {/* Pin 1 */}
                  <div className="absolute top-[20%] left-[30%] animate-pulse">
                    <div className="w-4 h-4 bg-emerald-500 rounded-full shadow-lg shadow-emerald-500/50" />
                  </div>
                  {/* Pin 2 */}
                  <div className="absolute top-[35%] left-[55%] animate-pulse" style={{ animationDelay: '0.5s' }}>
                    <div className="w-4 h-4 bg-emerald-500 rounded-full shadow-lg shadow-emerald-500/50" />
                  </div>
                  {/* Pin 3 */}
                  <div className="absolute top-[50%] left-[40%] animate-pulse" style={{ animationDelay: '1s' }}>
                    <div className="w-4 h-4 bg-emerald-500 rounded-full shadow-lg shadow-emerald-500/50" />
                  </div>
                  {/* Pin 4 */}
                  <div className="absolute top-[45%] left-[70%] animate-pulse" style={{ animationDelay: '1.5s' }}>
                    <div className="w-4 h-4 bg-emerald-500 rounded-full shadow-lg shadow-emerald-500/50" />
                  </div>
                  {/* Pin 5 - Current User */}
                  <div className="absolute top-[60%] left-[50%] -translate-x-1/2">
                    <div className="relative">
                      <div className="w-8 h-8 bg-emerald-600 rounded-full shadow-lg shadow-emerald-600/50 flex items-center justify-center">
                        <Home className="w-4 h-4 text-white" />
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
                <div className="backdrop-blur-xl bg-white/90 rounded-xl p-4 border border-white/20">
                  <div className="grid grid-cols-3 gap-4 text-center">
                    <div>
                      <p className="text-2xl font-bold text-emerald-950">12</p>
                      <p className="text-xs text-slate-500">Haven Homes Nearby</p>
                    </div>
                    <div>
                      <p className="text-2xl font-bold text-emerald-950">47</p>
                      <p className="text-xs text-slate-500">Verified Vendors</p>
                    </div>
                    <div>
                      <p className="text-2xl font-bold text-emerald-950">30%</p>
                      <p className="text-xs text-slate-500">Avg Savings</p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Right - Text */}
          <div className="order-1 lg:order-2">
            <p className="text-sm font-medium text-emerald-700 uppercase tracking-wider mb-3">The Network</p>
            <h2 className="font-serif text-4xl sm:text-5xl font-medium text-emerald-950 mb-6">
              Powered by Verified Neighbors.
            </h2>
            <p className="text-lg text-slate-600 leading-relaxed mb-8">
              Find vendors your neighbors actually trust. See real project costs and verified reviews from families on your street. When multiple households use the same pros, everyone saves.
            </p>
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
                  <p className="font-medium text-slate-900">&quot;Best landscaper we&apos;ve ever had&quot;</p>
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
          <p className="text-sm font-medium text-slate-900">Ready to upgrade your life?</p>
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
              <a href="#pillars" className="text-slate-600 hover:text-emerald-950 text-sm font-medium transition-colors">Features</a>
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

      {/* Core Pillars */}
      <CorePillarsSection />

      {/* Lifestyle Suite */}
      <LifestyleSuiteSection />

      {/* User Manual / The Vault */}
      <UserManualSection />

      {/* Social Proof */}
      <SocialProofSection />

      {/* Pricing */}
      <PricingSection />

      {/* Final CTA */}
      <section className="py-24 px-4 sm:px-6 lg:px-8 bg-emerald-950">
        <div className="max-w-4xl mx-auto text-center">
          <h2 className="font-serif text-4xl sm:text-5xl font-medium text-white mb-6">
            Your home deserves a Chief of Staff.
          </h2>
          <p className="text-xl text-emerald-200 mb-10 max-w-2xl mx-auto">
            Join hundreds of families who have simplified their lives with Haven.
            Check if we serve your neighborhood today.
          </p>
          <Link
            href="/register"
            className="inline-flex items-center gap-2 px-8 py-4 bg-white text-emerald-950 text-lg font-medium rounded-xl hover:bg-emerald-50 transition-colors"
          >
            Check Address Eligibility
            <ArrowRight className="w-5 h-5" />
          </Link>
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
                <li><a href="#pillars" className="text-emerald-300 hover:text-white text-sm transition-colors">Features</a></li>
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
