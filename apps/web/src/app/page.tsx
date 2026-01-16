'use client';

import { useState } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { Navbar } from '@/components/marketing/Navbar';
import { AlfredChatPreview } from '@/components/marketing/AlfredChatPreview';
import {
  ArrowRight,
  Check,
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
  Award,
  Sparkles,
  CheckCircle2,
  Mail,
  Receipt,
  TrendingDown,
  BookOpen,
  HelpCircle,
  Hammer,
  MapPin,
  Quote,
  Bell,
  ClipboardList,
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
      <section className="relative overflow-hidden bg-gradient-to-br from-haven-navy-800 via-haven-navy-900 to-haven-navy-950 pt-20 sm:pt-32 pb-12 sm:pb-24">
        {/* Background decoration */}
        <div className="absolute inset-0 overflow-hidden pointer-events-none">
          <div className="absolute -top-40 -right-40 w-96 h-96 bg-haven-navy-700 rounded-full blur-3xl opacity-20" />
          <div className="absolute top-1/2 -left-20 w-72 h-72 bg-sage-300/20 rounded-full blur-3xl opacity-30" />
        </div>

        <div className="relative max-w-6xl mx-auto px-4 sm:px-6">
          <div className="grid lg:grid-cols-2 gap-8 lg:gap-12 items-center">
            {/* Left - Copy */}
            <div className="flex flex-col items-center lg:items-start text-center lg:text-left">
              {/* Badge - Meet Alfred - Simpler on mobile */}
              <div className="inline-flex items-center gap-2 px-3 py-1.5 bg-white rounded-full mb-4 sm:mb-6">
                <Image src="/alfred-icon.svg" alt="Alfred" width={20} height={20} />
                <span className="text-sm font-medium text-haven-navy-900">Meet Alfred</span>
                <span className="hidden sm:inline text-haven-navy-400">|</span>
                <span className="hidden sm:inline text-sm text-haven-navy-700">Your Home Manager</span>
              </div>

              {/* H1 - Smaller on mobile */}
              <h1 className="text-3xl sm:text-5xl lg:text-6xl font-bold text-white tracking-tight leading-[1.1] font-serif">
                Your home, finally
                <br />
                <span className="text-sage-300">under control.</span>
              </h1>

              {/* Subheadline - Shorter on mobile */}
              <p className="mt-3 sm:mt-6 text-base sm:text-xl text-haven-100 max-w-xl mx-auto lg:mx-0">
                <span className="sm:hidden">One bill. One app. Everything handled.</span>
                <span className="hidden sm:inline">Alfred tracks your bills, reminds you before things break, finds savings you&apos;re missing, and consolidates everything into one monthly payment. Stop managing. Start living.</span>
              </p>

              {/* Price - Centered on mobile */}
              <div className="mt-4 sm:mt-6 flex items-center gap-3 sm:gap-4">
                <div className="flex items-baseline gap-1">
                  <span className="text-2xl sm:text-4xl font-bold text-white">$39</span>
                  <span className="text-base sm:text-xl text-white/70">/mo</span>
                </div>
                <span className="text-xs sm:text-sm text-sage-300">Cancel anytime</span>
              </div>

              {/* Value props - Hidden on mobile, show on sm+ */}
              <div className="hidden sm:flex mt-6 flex-wrap justify-center lg:justify-start gap-4 text-sm">
                <span className="flex items-center gap-2 text-white">
                  <CheckCircle2 className="w-5 h-5 text-sage-300" />
                  One bill for everything
                </span>
                <span className="flex items-center gap-2 text-white">
                  <CheckCircle2 className="w-5 h-5 text-sage-300" />
                  Never miss maintenance
                </span>
                <span className="flex items-center gap-2 text-white">
                  <CheckCircle2 className="w-5 h-5 text-sage-300" />
                  Handyman who knows your home
                </span>
              </div>

              {/* CTAs - Stacked and smaller on mobile */}
              <div className="mt-5 sm:mt-8 flex flex-col sm:flex-row items-center gap-3 sm:gap-4 w-full sm:w-auto">
                <Link
                  href="/onboarding/welcome"
                  className="w-full sm:w-auto px-6 sm:px-8 py-3 sm:py-4 bg-white text-haven-navy-900 font-semibold rounded-xl hover:bg-sage-50 transition-all shadow-lg text-base sm:text-lg flex items-center justify-center gap-2"
                >
                  Get Started
                  <ArrowRight className="w-5 h-5" />
                </Link>
                <a
                  href="#how-it-works"
                  className="w-full sm:w-auto px-6 sm:px-8 py-3 sm:py-4 border-2 border-white/30 text-white font-semibold rounded-xl hover:bg-white/10 transition-colors text-base sm:text-lg text-center"
                >
                  See How It Works
                </a>
              </div>

              {/* Trust - Hidden on mobile, show on sm+ */}
              <div className="hidden sm:flex mt-8 pt-8 border-t border-white/20 flex-wrap items-center justify-center lg:justify-start gap-6">
                <div className="flex items-center gap-2 text-sm text-white/70">
                  <Shield className="w-4 h-4" />
                  <span>Bank-Level Security</span>
                </div>
                <div className="flex items-center gap-2 text-sm text-white/70">
                  <Star className="w-4 h-4 text-sage-300 fill-current" />
                  <span>4.9/5 Rating</span>
                </div>
                <div className="flex items-center gap-2 text-sm text-white/70">
                  <Award className="w-4 h-4" />
                  <span>500+ Homes Managed</span>
                </div>
              </div>
            </div>

            {/* Right - Chat Preview (hidden on mobile) */}
            <div className="hidden lg:block relative lg:pl-8">
              <AlfredChatPreview />
            </div>
          </div>
        </div>
      </section>

      {/* ================================================================== */}
      {/* HOW IT WORKS - Expanded for full home management value */}
      {/* ================================================================== */}
      <section id="how-it-works" className="py-16 sm:py-24 bg-white">
        <div className="max-w-6xl mx-auto px-4 sm:px-6">
          <div className="text-center mb-12">
            <h2 className="text-3xl sm:text-4xl font-bold text-warm-900">
              How Alfred Works
            </h2>
            <p className="mt-4 text-lg text-warm-600 max-w-2xl mx-auto">
              Add your home once. Alfred handles everything else — tracking, reminders, bills, and more.
            </p>
          </div>

          <div className="grid md:grid-cols-3 gap-8">
            {[
              {
                step: '1',
                title: 'Add Your Home',
                description: 'Forward bills and receipts to Alfred. Add your home systems — HVAC, roof, water heater. Upload warranties and manuals. Alfred builds your complete home profile.',
                Icon: Home,
              },
              {
                step: '2',
                title: 'Alfred Tracks Everything',
                description: 'Bills, maintenance schedules, service history, warranties. Alfred knows when your furnace was last serviced, when your roof needs inspection, and what filters you need.',
                Icon: ClipboardList,
              },
              {
                step: '3',
                title: 'Never Miss Anything',
                description: 'Proactive reminders before things break. Vendor recommendations when you need service. And one monthly bill that covers everything — no more juggling due dates.',
                Icon: Bell,
              },
            ].map((item, idx) => (
              <div key={idx} className="relative">
                {idx < 2 && (
                  <div className="hidden md:block absolute top-12 left-[60%] w-[80%] h-0.5 bg-gradient-to-r from-sage-300 to-transparent" />
                )}
                <div className="text-center">
                  <div className="relative inline-flex mb-4">
                    <div className="w-20 h-20 rounded-2xl bg-sage-100 text-sage-700 flex items-center justify-center shadow-lg">
                      <item.Icon className="w-9 h-9" />
                    </div>
                    <span className="absolute -top-2 -right-2 w-7 h-7 bg-haven-navy-900 text-white rounded-full flex items-center justify-center font-bold text-sm shadow-md">
                      {item.step}
                    </span>
                  </div>
                  <h3 className="text-xl font-semibold text-warm-900 mb-2">{item.title}</h3>
                  <p className="text-warm-600">{item.description}</p>
                </div>
              </div>
            ))}
          </div>

          {/* Email examples grid */}
          <div className="bg-sage-50 rounded-2xl p-6 border border-sage-200 mt-12">
            <h3 className="text-lg font-semibold text-warm-900 mb-4 text-center">Emails Alfred handles for you</h3>
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
              {[
                { icon: Zap, label: 'Utility Bills', example: 'Eversource, CNG, Water' },
                { icon: Calendar, label: 'Camp & Activities', example: 'Registrations, schedules' },
                { icon: Wrench, label: 'Service Visits', example: 'HVAC, plumber, electrician' },
                { icon: FileText, label: 'Insurance', example: 'Renewals, claims' },
                { icon: Home, label: 'Property Tax', example: 'Assessments, payments' },
                { icon: Users, label: 'HOA Notices', example: 'Dues, meetings, rules' },
                { icon: Receipt, label: 'Subscriptions', example: 'Lawn care, security' },
                { icon: MessageCircle, label: 'Quotes & Estimates', example: 'Any vendor quote' },
              ].map((item, i) => (
                <div key={i} className="text-center p-3 rounded-xl bg-white">
                  <item.icon className="w-6 h-6 mx-auto text-sage-600 mb-2" />
                  <p className="font-medium text-warm-900 text-sm">{item.label}</p>
                  <p className="text-xs text-warm-500 mt-1">{item.example}</p>
                </div>
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* ================================================================== */}
      {/* WHAT ALFRED DOES - 6 Feature Cards */}
      {/* ================================================================== */}
      <section className="py-16 sm:py-24 bg-white">
        <div className="max-w-6xl mx-auto px-4 sm:px-6">
          <div className="text-center mb-12">
            <h2 className="text-3xl sm:text-4xl font-bold text-warm-900">
              What Alfred Does for You
            </h2>
            <p className="mt-4 text-lg text-warm-600 max-w-2xl mx-auto">
              Think of Alfred as your personal home assistant who never sleeps, never forgets, and actually enjoys organizing your life.
            </p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            {/* Card 1 */}
            <div className="bg-warm-50 rounded-2xl p-6 border border-warm-100">
              <div className="w-12 h-12 bg-blue-100 rounded-xl flex items-center justify-center mb-4">
                <Mail className="w-6 h-6 text-blue-600" />
              </div>
              <h3 className="text-xl font-bold text-warm-900 mb-2">Reads Your Emails</h3>
              <p className="text-warm-600">
                Forward any home email and Alfred extracts dates, amounts, and action items automatically.
              </p>
            </div>

            {/* Card 2 */}
            <div className="bg-warm-50 rounded-2xl p-6 border border-warm-100">
              <div className="w-12 h-12 bg-green-100 rounded-xl flex items-center justify-center mb-4">
                <TrendingDown className="w-6 h-6 text-green-600" />
              </div>
              <h3 className="text-xl font-bold text-warm-900 mb-2">Finds Savings</h3>
              <p className="text-warm-600">
                Alfred monitors your bills and alerts you to better rates, unnecessary charges, and money-saving opportunities.
              </p>
            </div>

            {/* Card 3 */}
            <div className="bg-warm-50 rounded-2xl p-6 border border-warm-100">
              <div className="w-12 h-12 bg-amber-100 rounded-xl flex items-center justify-center mb-4">
                <Clock className="w-6 h-6 text-amber-600" />
              </div>
              <h3 className="text-xl font-bold text-warm-900 mb-2">Never Forgets</h3>
              <p className="text-warm-600">
                Maintenance reminders, warranty expirations, filter changes — Alfred tracks it all so you don&apos;t have to.
              </p>
            </div>

            {/* Card 4 */}
            <div className="bg-warm-50 rounded-2xl p-6 border border-warm-100">
              <div className="w-12 h-12 bg-purple-100 rounded-xl flex items-center justify-center mb-4">
                <BookOpen className="w-6 h-6 text-purple-600" />
              </div>
              <h3 className="text-xl font-bold text-warm-900 mb-2">Builds Your Home Manual</h3>
              <p className="text-warm-600">
                Every system, appliance, paint color, and vendor — documented and searchable. Your home&apos;s complete digital memory.
              </p>
            </div>

            {/* Card 5 */}
            <div className="bg-warm-50 rounded-2xl p-6 border border-warm-100">
              <div className="w-12 h-12 bg-haven-100 rounded-xl flex items-center justify-center mb-4">
                <Receipt className="w-6 h-6 text-haven-700" />
              </div>
              <h3 className="text-xl font-bold text-warm-900 mb-2">One Bill</h3>
              <p className="text-warm-600">
                All your home expenses consolidated into a single monthly payment. No more juggling seven different due dates.
              </p>
            </div>

            {/* Card 6 */}
            <div className="bg-warm-50 rounded-2xl p-6 border border-warm-100">
              <div className="w-12 h-12 bg-sage-100 rounded-xl flex items-center justify-center mb-4">
                <HelpCircle className="w-6 h-6 text-sage-600" />
              </div>
              <h3 className="text-xl font-bold text-warm-900 mb-2">Answers Anything</h3>
              <p className="text-warm-600">
                &quot;When was the roof last inspected?&quot; &quot;What&apos;s the model number of my water heater?&quot; Alfred knows.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* ================================================================== */}
      {/* HANDYMAN SECTION - Dark Background */}
      {/* ================================================================== */}
      <section className="py-16 sm:py-24 bg-gradient-to-br from-haven-navy-900 to-haven-navy-950">
        <div className="max-w-6xl mx-auto px-4 sm:px-6">
          <div className="grid lg:grid-cols-2 gap-12 items-center">
            <div>
              <div className="inline-flex items-center gap-2 px-3 py-1.5 bg-white/10 rounded-full mb-4">
                <Hammer className="w-4 h-4 text-sage-300" />
                <span className="text-sm font-medium text-white">Haven Handyman</span>
              </div>
              <h2 className="text-3xl sm:text-4xl font-bold text-white mb-4">
                A Real Handyman Who Knows Your Home
              </h2>
              <p className="text-lg text-haven-100 mb-8">
                No more explaining your home&apos;s quirks to every contractor. Your Haven handyman has access to your complete home profile and maintenance history.
              </p>

              <div className="space-y-4">
                {[
                  'Background-checked and insured',
                  'Knows your home systems before they arrive',
                  'Same handyman every time (when possible)',
                  'Can handle 90% of small repairs',
                  'Escalates to specialists when needed',
                ].map((item, i) => (
                  <div key={i} className="flex items-center gap-3">
                    <CheckCircle2 className="w-5 h-5 text-sage-400 flex-shrink-0" />
                    <span className="text-white">{item}</span>
                  </div>
                ))}
              </div>

              <div className="mt-8 flex flex-wrap gap-6">
                <div className="bg-white rounded-xl px-4 py-3">
                  <p className="text-haven-navy-900 font-bold text-2xl">$99</p>
                  <p className="text-haven-navy-700 text-sm">per visit (Essentials)</p>
                </div>
                <div className="bg-white rounded-xl px-4 py-3">
                  <p className="text-haven-700 font-bold text-2xl">Included</p>
                  <p className="text-haven-navy-700 text-sm">with Haven ($749+)</p>
                </div>
              </div>
            </div>

            {/* Handyman Profile Card */}
            <div className="bg-white rounded-2xl p-6 shadow-xl">
              <div className="flex items-start gap-4 mb-6">
                <div className="w-20 h-20 bg-warm-200 rounded-xl flex items-center justify-center">
                  <Wrench className="w-10 h-10 text-warm-500" />
                </div>
                <div>
                  <h3 className="text-xl font-bold text-warm-900">Mike Rodriguez</h3>
                  <p className="text-warm-600">Your Haven Handyman</p>
                  <div className="flex items-center gap-1 mt-1">
                    {[...Array(5)].map((_, i) => (
                      <Star key={i} className="w-4 h-4 text-sage-500 fill-current" />
                    ))}
                    <span className="text-sm text-warm-500 ml-1">4.9 (127 reviews)</span>
                  </div>
                </div>
              </div>

              <div className="space-y-3 mb-6">
                <div className="flex items-center gap-3 text-warm-700">
                  <MapPin className="w-5 h-5 text-warm-400" />
                  <span>Serves Greater Hartford area</span>
                </div>
                <div className="flex items-center gap-3 text-warm-700">
                  <Clock className="w-5 h-5 text-warm-400" />
                  <span>15+ years experience</span>
                </div>
                <div className="flex items-center gap-3 text-warm-700">
                  <Shield className="w-5 h-5 text-warm-400" />
                  <span>Background checked & insured</span>
                </div>
              </div>

              <div className="bg-sage-50 rounded-xl p-4 border border-sage-200">
                <div className="flex items-start gap-3">
                  <Quote className="w-5 h-5 text-sage-500 flex-shrink-0 mt-0.5" />
                  <div>
                    <p className="text-warm-700 italic">
                      &quot;Mike already knew about our old furnace before he arrived. Fixed it in half the time!&quot;
                    </p>
                    <p className="text-sm text-warm-500 mt-2">— The Morrison Family</p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ================================================================== */}
      {/* USE CASES */}
      {/* ================================================================== */}
      <section className="py-16 sm:py-24 bg-warm-50">
        <div className="max-w-6xl mx-auto px-4 sm:px-6">
          <div className="text-center mb-12">
            <h2 className="text-3xl sm:text-4xl font-bold text-warm-900">
              Is Haven Right for You?
            </h2>
            <p className="mt-4 text-lg text-warm-600 max-w-2xl mx-auto">
              Most homeowners start with Essentials. Here&apos;s who we help most.
            </p>
          </div>

          <div className="grid md:grid-cols-3 gap-6">
            {/* The Newcomer */}
            <div className="bg-white rounded-2xl p-6 border border-warm-200 relative">
              <div className="w-12 h-12 bg-blue-100 rounded-xl flex items-center justify-center mb-4">
                <Home className="w-6 h-6 text-blue-600" />
              </div>
              <h3 className="text-xl font-bold text-warm-900 mb-2">The Newcomer</h3>
              <p className="text-warm-600 mb-4">
                Just bought a home and feeling overwhelmed by all the things you need to track, remember, and maintain.
              </p>
              <ul className="space-y-2 mb-6">
                <li className="flex items-center gap-2 text-sm text-warm-700">
                  <Check className="w-4 h-4 text-green-500" />
                  Build your home manual from scratch
                </li>
                <li className="flex items-center gap-2 text-sm text-warm-700">
                  <Check className="w-4 h-4 text-green-500" />
                  Get maintenance reminders automatically
                </li>
                <li className="flex items-center gap-2 text-sm text-warm-700">
                  <Check className="w-4 h-4 text-green-500" />
                  One bill from day one
                </li>
              </ul>
              <div className="pt-4 border-t border-warm-100">
                <p className="text-2xl font-bold text-haven-700">$39<span className="text-base font-normal text-warm-500">/mo</span></p>
                <p className="text-sm text-warm-500">Essentials + Alfred</p>
              </div>
            </div>

            {/* The Optimizer - Most Popular */}
            <div className="bg-white rounded-2xl p-6 border-2 border-sage-400 relative">
              <div className="absolute -top-3 left-1/2 -translate-x-1/2 px-4 py-1.5 bg-sage-500 text-white text-sm font-bold rounded-full shadow-lg">
                Most Popular
              </div>
              <div className="w-12 h-12 bg-green-100 rounded-xl flex items-center justify-center mb-4">
                <TrendingDown className="w-6 h-6 text-green-600" />
              </div>
              <h3 className="text-xl font-bold text-warm-900 mb-2">The Optimizer</h3>
              <p className="text-warm-600 mb-4">
                You&apos;re organized but tired of missing things. You know you&apos;re paying too much but don&apos;t have time to shop around.
              </p>
              <ul className="space-y-2 mb-6">
                <li className="flex items-center gap-2 text-sm text-warm-700">
                  <Check className="w-4 h-4 text-green-500" />
                  Find savings automatically
                </li>
                <li className="flex items-center gap-2 text-sm text-warm-700">
                  <Check className="w-4 h-4 text-green-500" />
                  Never miss a payment again
                </li>
                <li className="flex items-center gap-2 text-sm text-warm-700">
                  <Check className="w-4 h-4 text-green-500" />
                  Track everything in one place
                </li>
              </ul>
              <div className="pt-4 border-t border-warm-100">
                <p className="text-2xl font-bold text-haven-700">$39<span className="text-base font-normal text-warm-500">/mo</span></p>
                <p className="text-sm text-warm-500">Essentials + Alfred</p>
              </div>
            </div>

            {/* The Busy Bee */}
            <div className="bg-white rounded-2xl p-6 border border-warm-200 relative">
              <div className="w-12 h-12 bg-purple-100 rounded-xl flex items-center justify-center mb-4">
                <Phone className="w-6 h-6 text-purple-600" />
              </div>
              <h3 className="text-xl font-bold text-warm-900 mb-2">The Busy Bee</h3>
              <p className="text-warm-600 mb-4">
                You don&apos;t have time to make calls, get quotes, or schedule contractors. You need someone to handle it.
              </p>
              <ul className="space-y-2 mb-6">
                <li className="flex items-center gap-2 text-sm text-warm-700">
                  <Check className="w-4 h-4 text-green-500" />
                  Text to get anything done
                </li>
                <li className="flex items-center gap-2 text-sm text-warm-700">
                  <Check className="w-4 h-4 text-green-500" />
                  We call, schedule, and coordinate
                </li>
                <li className="flex items-center gap-2 text-sm text-warm-700">
                  <Check className="w-4 h-4 text-green-500" />
                  Human manager + Alfred
                </li>
              </ul>
              <div className="pt-4 border-t border-warm-100">
                <p className="text-2xl font-bold text-haven-700">$349<span className="text-base font-normal text-warm-500">/mo</span></p>
                <p className="text-sm text-warm-500">Haven Lite</p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ================================================================== */}
      {/* ONE BILL SECTION - Dark Background */}
      {/* ================================================================== */}
      <section className="py-16 sm:py-24 bg-gradient-to-br from-haven-navy-900 to-haven-navy-950">
        <div className="max-w-6xl mx-auto px-4 sm:px-6">
          <div className="text-center mb-12">
            <h2 className="text-3xl sm:text-4xl font-bold text-white">
              One Bill. Seriously.
            </h2>
            <p className="mt-4 text-lg text-haven-100 max-w-2xl mx-auto">
              Stop juggling seven different payment due dates. Haven consolidates everything into one simple monthly payment.
            </p>
          </div>

          <div className="grid md:grid-cols-2 gap-8 items-center">
            {/* Before */}
            <div className="bg-white/5 backdrop-blur rounded-2xl p-6 border border-white/10">
              <h3 className="text-xl font-bold text-white mb-4 flex items-center gap-2">
                <span className="w-6 h-6 bg-red-500/20 rounded-full flex items-center justify-center text-sm">✗</span>
                Before Haven
              </h3>
              <div className="space-y-3">
                {[
                  { name: 'Electric', date: '5th', amount: '$145' },
                  { name: 'Gas', date: '12th', amount: '$89' },
                  { name: 'Water/Sewer', date: '15th', amount: '$67' },
                  { name: 'Internet', date: '18th', amount: '$79' },
                  { name: 'Lawn Care', date: '1st', amount: '$150' },
                  { name: 'Security', date: '20th', amount: '$45' },
                  { name: 'Pest Control', date: 'Quarterly', amount: '$120' },
                ].map((bill, i) => (
                  <div key={i} className="flex items-center justify-between py-2 border-b border-white/10 last:border-0">
                    <span className="text-white/70">{bill.name}</span>
                    <div className="flex items-center gap-4">
                      <span className="text-xs text-white/50">Due: {bill.date}</span>
                      <span className="text-white font-medium">{bill.amount}</span>
                    </div>
                  </div>
                ))}
              </div>
              <div className="mt-4 pt-4 border-t border-white/20 flex justify-between">
                <span className="text-white/70">7 different payments</span>
                <span className="text-red-400 font-bold">7 chances to be late</span>
              </div>
            </div>

            {/* After */}
            <div className="bg-white rounded-2xl p-6">
              <h3 className="text-xl font-bold text-haven-navy-900 mb-4 flex items-center gap-2">
                <span className="w-6 h-6 bg-haven-700 rounded-full flex items-center justify-center text-white text-sm">✓</span>
                With Haven
              </h3>
              <div className="flex items-center justify-center py-12">
                <div className="text-center">
                  <p className="text-6xl font-bold text-haven-700">1</p>
                  <p className="text-haven-navy-900 text-xl mt-2">Monthly Bill</p>
                  <p className="text-haven-navy-700 mt-1">Same day every month</p>
                </div>
              </div>
              <div className="mt-4 pt-4 border-t border-warm-200 flex justify-between items-center">
                <span className="text-haven-navy-700">All bills included</span>
                <span className="text-haven-700 font-bold flex items-center gap-2">
                  <CheckCircle2 className="w-5 h-5" />
                  Never late
                </span>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ================================================================== */}
      {/* PRICING */}
      {/* ================================================================== */}
      <section id="pricing" className="py-16 sm:py-24 bg-white">
        <div className="max-w-6xl mx-auto px-4 sm:px-6">
          <div className="text-center mb-12">
            <h2 className="text-3xl sm:text-4xl font-bold text-warm-900">
              Simple, Transparent Pricing
            </h2>
            <p className="mt-4 text-lg text-warm-600 max-w-2xl mx-auto">
              Most homeowners start with Essentials. Upgrade anytime if you need more hands-on support.
            </p>
          </div>

          <div className="grid md:grid-cols-3 gap-6 mb-8">
            {/* Essentials - START HERE */}
            <div className="bg-white rounded-2xl p-6 border-2 border-sage-400 relative shadow-xl overflow-hidden">
              <div className="h-2 bg-gradient-to-r from-sage-400 to-sage-500 absolute top-0 left-0 right-0" />
              <div className="absolute -top-0 left-1/2 -translate-x-1/2 px-4 py-1.5 bg-sage-500 text-white text-sm font-bold rounded-b-full shadow-lg">
                Start Here
              </div>
              <div className="flex items-center gap-3 mb-4 mt-4">
                <div className="w-10 h-10 bg-sage-100 rounded-xl flex items-center justify-center">
                  <Sparkles className="w-5 h-5 text-sage-600" />
                </div>
                <div>
                  <h3 className="text-xl font-bold text-warm-900">Essentials</h3>
                  <p className="text-sm text-warm-500">Alfred + Core Features</p>
                </div>
              </div>
              <div className="mb-6">
                <span className="text-4xl font-bold text-haven-700">$39</span>
                <span className="text-warm-500">/month</span>
              </div>
              <ul className="space-y-3 mb-6">
                {[
                  'Alfred email processing',
                  'One consolidated bill',
                  'Home manual & inventory',
                  'Maintenance reminders',
                  'Bill tracking & alerts',
                  'Savings finder',
                  'Handyman visits ($99/each)',
                ].map((feature, i) => (
                  <li key={i} className="flex items-center gap-2 text-sm text-warm-700">
                    <Check className="w-5 h-5 text-sage-500 flex-shrink-0" />
                    {feature}
                  </li>
                ))}
              </ul>
              <Link
                href="/onboarding/welcome"
                className="block w-full py-3 px-4 bg-haven-navy-900 text-white font-semibold rounded-xl text-center hover:bg-haven-navy-800 transition-colors"
              >
                Get Started
              </Link>
            </div>

            {/* Haven Lite */}
            <div className="bg-white rounded-2xl p-6 border border-warm-200">
              <div className="flex items-center gap-3 mb-4">
                <div className="w-10 h-10 bg-haven-100 rounded-xl flex items-center justify-center">
                  <MessageCircle className="w-5 h-5 text-haven-700" />
                </div>
                <div>
                  <h3 className="text-xl font-bold text-warm-900">Haven Lite</h3>
                  <p className="text-sm text-warm-500">Text-based Support</p>
                </div>
              </div>
              <div className="mb-6">
                <span className="text-4xl font-bold text-haven-700">$349</span>
                <span className="text-warm-500">/month</span>
              </div>
              <ul className="space-y-3 mb-6">
                {[
                  'Everything in Essentials',
                  'Dedicated home manager',
                  'Text-based coordination',
                  'Vendor vetting & scheduling',
                  'Quote comparison',
                  'Handyman visits ($79/each)',
                ].map((feature, i) => (
                  <li key={i} className="flex items-center gap-2 text-sm text-warm-700">
                    <Check className="w-4 h-4 text-haven-700" />
                    {feature}
                  </li>
                ))}
              </ul>
              <Link
                href="/onboarding/welcome?plan=lite"
                className="block w-full py-3 px-4 bg-warm-100 text-warm-700 font-semibold rounded-xl text-center hover:bg-warm-200 transition-colors"
              >
                Choose Lite
              </Link>
            </div>

            {/* Haven */}
            <div className="bg-white rounded-2xl p-6 border border-warm-200">
              <div className="flex items-center gap-3 mb-4">
                <div className="w-10 h-10 bg-haven-100 rounded-xl flex items-center justify-center">
                  <Phone className="w-5 h-5 text-haven-700" />
                </div>
                <div>
                  <h3 className="text-xl font-bold text-warm-900">Haven</h3>
                  <p className="text-sm text-warm-500">Proactive Management</p>
                </div>
              </div>
              <div className="mb-6">
                <span className="text-4xl font-bold text-haven-700">$749</span>
                <span className="text-warm-500">/month</span>
              </div>
              <ul className="space-y-3 mb-6">
                {[
                  'Everything in Lite',
                  'Phone & video support',
                  'Proactive maintenance',
                  'Annual home walkthrough',
                  'Project management',
                  'Handyman visits included',
                ].map((feature, i) => (
                  <li key={i} className="flex items-center gap-2 text-sm text-warm-700">
                    <Check className="w-4 h-4 text-haven-700" />
                    {feature}
                  </li>
                ))}
              </ul>
              <Link
                href="/onboarding/welcome?plan=haven"
                className="block w-full py-3 px-4 bg-warm-100 text-warm-700 font-semibold rounded-xl text-center hover:bg-warm-200 transition-colors"
              >
                Choose Haven
              </Link>
            </div>
          </div>

          {/* Premium Tiers Toggle */}
          <div className="text-center">
            <button
              onClick={() => setShowPremiumTiers(!showPremiumTiers)}
              className="inline-flex items-center gap-2 text-haven-700 hover:text-haven-800 font-medium"
            >
              {showPremiumTiers ? 'Hide' : 'Show'} premium tiers
              {showPremiumTiers ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
            </button>

            {showPremiumTiers && (
              <div className="grid md:grid-cols-2 gap-6 mt-8 max-w-3xl mx-auto">
                {/* Haven+ */}
                <div className="bg-warm-50 rounded-2xl p-6 border border-warm-200 text-left">
                  <h3 className="text-xl font-bold text-warm-900 mb-1">Haven+</h3>
                  <p className="text-sm text-warm-500 mb-4">Lifestyle Services</p>
                  <p className="text-3xl font-bold text-haven-700 mb-4">$1,499<span className="text-base font-normal text-warm-500">/mo</span></p>
                  <ul className="space-y-2 text-sm text-warm-600">
                    <li className="flex items-center gap-2"><Check className="w-4 h-4 text-haven-700" /> Everything in Haven</li>
                    <li className="flex items-center gap-2"><Check className="w-4 h-4 text-haven-700" /> Travel coordination</li>
                    <li className="flex items-center gap-2"><Check className="w-4 h-4 text-haven-700" /> Event planning support</li>
                    <li className="flex items-center gap-2"><Check className="w-4 h-4 text-haven-700" /> Seasonal home prep</li>
                  </ul>
                </div>

                {/* Estate */}
                <div className="bg-warm-50 rounded-2xl p-6 border border-warm-200 text-left">
                  <h3 className="text-xl font-bold text-warm-900 mb-1">Estate</h3>
                  <p className="text-sm text-warm-500 mb-4">White Glove Service</p>
                  <p className="text-3xl font-bold text-haven-700 mb-4">$3,499<span className="text-base font-normal text-warm-500">/mo</span></p>
                  <ul className="space-y-2 text-sm text-warm-600">
                    <li className="flex items-center gap-2"><Check className="w-4 h-4 text-haven-700" /> Everything in Haven+</li>
                    <li className="flex items-center gap-2"><Check className="w-4 h-4 text-haven-700" /> Multi-property support</li>
                    <li className="flex items-center gap-2"><Check className="w-4 h-4 text-haven-700" /> Dedicated estate manager</li>
                    <li className="flex items-center gap-2"><Check className="w-4 h-4 text-haven-700" /> 24/7 emergency response</li>
                  </ul>
                </div>
              </div>
            )}
          </div>
        </div>
      </section>

      {/* ================================================================== */}
      {/* TESTIMONIALS */}
      {/* ================================================================== */}
      <section className="py-16 sm:py-24 bg-gradient-to-b from-sage-50 to-sage-100/50">
        <div className="max-w-6xl mx-auto px-4 sm:px-6">
          <div className="text-center mb-12">
            <h2 className="text-3xl sm:text-4xl font-bold text-warm-900">
              Real Homeowners. Real Results.
            </h2>
          </div>

          <div className="grid md:grid-cols-3 gap-6 mb-12">
            {[
              {
                quote: "We just bought our first home and were completely overwhelmed. Alfred helped us build our home manual from scratch. Now we know when everything was installed and when it needs service.",
                name: "Sarah & James Chen",
                role: "First-time homeowners",
                avatar: "SC",
              },
              {
                quote: "I was paying $40/month too much for electricity and didn't even know it. Alfred found a better rate and switched me over. The service paid for itself in the first month.",
                name: "Michael Torres",
                role: "Essentials member",
                avatar: "MT",
              },
              {
                quote: "Between work and kids, I had zero time to deal with home stuff. Now I just text Sarah and she handles everything. It's like having a personal assistant for my house.",
                name: "Jennifer Walsh",
                role: "Haven member",
                avatar: "JW",
              },
            ].map((testimonial, i) => (
              <div key={i} className="bg-white rounded-2xl p-6 border border-warm-200">
                <div className="flex items-center gap-1 mb-4">
                  {[...Array(5)].map((_, j) => (
                    <Star key={j} className="w-4 h-4 text-sage-500 fill-current" />
                  ))}
                </div>
                <p className="text-warm-700 mb-6">&quot;{testimonial.quote}&quot;</p>
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-haven-100 rounded-full flex items-center justify-center text-haven-700 font-semibold text-sm">
                    {testimonial.avatar}
                  </div>
                  <div>
                    <p className="font-semibold text-warm-900">{testimonial.name}</p>
                    <p className="text-sm text-warm-500">{testimonial.role}</p>
                  </div>
                </div>
              </div>
            ))}
          </div>

          {/* Stats */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
            {[
              { value: '$400', label: 'Avg. savings found/year' },
              { value: '500+', label: 'Homes managed' },
              { value: '4.9/5', label: 'Customer rating' },
              { value: '1', label: 'Bill to pay' },
            ].map((stat, i) => (
              <div key={i} className="text-center">
                <p className="text-3xl sm:text-4xl font-bold text-haven-700">{stat.value}</p>
                <p className="text-warm-600 mt-1">{stat.label}</p>
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
          <div className="text-center mb-12">
            <h2 className="text-3xl sm:text-4xl font-bold text-warm-900">
              Questions? We&apos;ve Got Answers.
            </h2>
          </div>

          <div className="space-y-4">
            {[
              {
                q: 'What is Alfred?',
                a: 'Alfred is your personal home manager that reads your emails, tracks your bills, reminds you about maintenance, and builds a complete manual for your home. Think of it as having a really organized assistant who never forgets anything about your house.',
              },
              {
                q: 'How does email forwarding work?',
                a: 'When you sign up, you get a unique email address like yourname@alfred.havenhome.dev. Just forward (or CC) any home-related email to Alfred. He reads it, extracts the important stuff, and takes action — adding dates to your calendar, tracking bills, or updating your home manual.',
              },
              {
                q: 'Is $39/month really enough?',
                a: "For most homeowners, yes! Essentials includes Alfred's full capabilities: email processing, bill consolidation, maintenance reminders, savings finder, and your complete home manual. The average member saves more than $39/month in avoided late fees and found savings alone.",
              },
              {
                q: 'What\'s the difference between Alfred and Sarah?',
                a: 'Alfred is your always-on digital assistant who handles emails, tracks bills, and manages your home manual automatically. Sarah is our human home manager who coordinates vendors, makes phone calls, and provides hands-on support. Essentials gives you Alfred. Haven Lite and above add Sarah.',
              },
              {
                q: 'Tell me about the handyman service.',
                a: "Haven handymen are background-checked professionals who have access to your home profile before they arrive. They know your systems, past issues, and maintenance history. Essentials members pay $99/visit. Haven members get visits included. It's like having a handyman who already knows your house.",
              },
              {
                q: 'How does one-bill work?',
                a: "We consolidate all your home expenses into a single monthly payment. You fund your Haven account, and we pay your bills on time, every time. No more juggling 7 different due dates. No more late fees. One payment on the same day each month.",
              },
              {
                q: 'Are there any contracts?',
                a: 'No long-term contracts. Cancel anytime. We believe you should stay because Haven makes your life easier, not because you\'re locked in.',
              },
            ].map((faq, i) => (
              <div key={i} className="border border-warm-200 rounded-xl overflow-hidden">
                <button
                  onClick={() => setOpenFaq(openFaq === i ? null : i)}
                  className="w-full px-6 py-4 flex items-center justify-between text-left hover:bg-warm-50 transition-colors"
                >
                  <span className="font-semibold text-warm-900">{faq.q}</span>
                  {openFaq === i ? (
                    <ChevronUp className="w-5 h-5 text-warm-400" />
                  ) : (
                    <ChevronDown className="w-5 h-5 text-warm-400" />
                  )}
                </button>
                {openFaq === i && (
                  <div className="px-6 pb-4">
                    <p className="text-warm-600">{faq.a}</p>
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
      <section className="py-16 sm:py-24 bg-gradient-to-br from-haven-navy-900 to-haven-navy-950">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 text-center">
          <h2 className="text-3xl sm:text-4xl font-bold text-white mb-4">
            Ready to take control of your home?
          </h2>
          <p className="text-lg text-haven-100 mb-8 max-w-2xl mx-auto">
            One bill. One app. A handyman who knows your home. Join 500+ families who stopped managing and started living.
          </p>
          <Link
            href="/onboarding/welcome"
            className="inline-flex items-center gap-2 px-8 py-4 bg-white text-haven-navy-900 font-semibold rounded-xl hover:bg-sage-50 transition-colors shadow-lg text-lg"
          >
            Get Started with Alfred — $39/mo
            <ArrowRight className="w-5 h-5" />
          </Link>
          <p className="mt-4 text-sm text-haven-200">No contracts. Cancel anytime.</p>
        </div>
      </section>

      {/* ================================================================== */}
      {/* FOOTER */}
      {/* ================================================================== */}
      <footer className="bg-haven-navy-900 py-12">
        <div className="max-w-6xl mx-auto px-4 sm:px-6">
          <div className="grid md:grid-cols-4 gap-8 mb-8">
            <div>
              <div className="flex items-center gap-2 mb-4">
                <Image src="/icon-white.svg" alt="Haven" width={28} height={28} />
                <span className="text-xl font-bold text-white">Haven</span>
              </div>
              <p className="text-haven-200 text-sm">
                Stop managing your home. Start living in it.
              </p>
            </div>
            <div>
              <h4 className="font-semibold text-white mb-4">Product</h4>
              <ul className="space-y-2 text-sm text-haven-200">
                <li><a href="#how-it-works" className="hover:text-white transition-colors">How It Works</a></li>
                <li><a href="#pricing" className="hover:text-white transition-colors">Pricing</a></li>
                <li><Link href="/onboarding/welcome" className="hover:text-white transition-colors">Get Started</Link></li>
              </ul>
            </div>
            <div>
              <h4 className="font-semibold text-white mb-4">Company</h4>
              <ul className="space-y-2 text-sm text-haven-200">
                <li><a href="#" className="hover:text-white transition-colors">About</a></li>
                <li><a href="#" className="hover:text-white transition-colors">Blog</a></li>
                <li><a href="#" className="hover:text-white transition-colors">Careers</a></li>
              </ul>
            </div>
            <div>
              <h4 className="font-semibold text-white mb-4">Legal</h4>
              <ul className="space-y-2 text-sm text-haven-200">
                <li><a href="#" className="hover:text-white transition-colors">Privacy Policy</a></li>
                <li><a href="#" className="hover:text-white transition-colors">Terms of Service</a></li>
              </ul>
            </div>
          </div>
          <div className="pt-8 border-t border-haven-navy-800 flex flex-col sm:flex-row items-center justify-between gap-4">
            <p className="text-sm text-haven-300">© 2026 Haven Home. All rights reserved.</p>
            <div className="flex items-center gap-4">
              <a href="#" className="text-haven-200 hover:text-white transition-colors">
                <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24"><path d="M24 4.557c-.883.392-1.832.656-2.828.775 1.017-.609 1.798-1.574 2.165-2.724-.951.564-2.005.974-3.127 1.195-.897-.957-2.178-1.555-3.594-1.555-3.179 0-5.515 2.966-4.797 6.045-4.091-.205-7.719-2.165-10.148-5.144-1.29 2.213-.669 5.108 1.523 6.574-.806-.026-1.566-.247-2.229-.616-.054 2.281 1.581 4.415 3.949 4.89-.693.188-1.452.232-2.224.084.626 1.956 2.444 3.379 4.6 3.419-2.07 1.623-4.678 2.348-7.29 2.04 2.179 1.397 4.768 2.212 7.548 2.212 9.142 0 14.307-7.721 13.995-14.646.962-.695 1.797-1.562 2.457-2.549z"/></svg>
              </a>
              <a href="#" className="text-haven-200 hover:text-white transition-colors">
                <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24"><path d="M12 0c-6.627 0-12 5.373-12 12s5.373 12 12 12 12-5.373 12-12-5.373-12-12-12zm3 8h-1.35c-.538 0-.65.221-.65.778v1.222h2l-.209 2h-1.791v7h-3v-7h-2v-2h2v-2.308c0-1.769.931-2.692 3.029-2.692h1.971v3z"/></svg>
              </a>
              <a href="#" className="text-haven-200 hover:text-white transition-colors">
                <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z"/></svg>
              </a>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}
