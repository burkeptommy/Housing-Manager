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
      <section className="relative overflow-hidden min-h-[100dvh] sm:min-h-0 flex flex-col justify-center">
        {/* Rich gradient background */}
        <div className="absolute inset-0 bg-gradient-to-br from-haven-navy-900 via-haven-navy-950 to-[#050a14]" />

        {/* Subtle radial glow */}
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_80%_50%_at_50%_-20%,rgba(164,180,148,0.12),transparent)]" />

        {/* Subtle grid pattern for texture */}
        <div
          className="absolute inset-0 opacity-[0.03]"
          style={{
            backgroundImage: `linear-gradient(rgba(255,255,255,0.1) 1px, transparent 1px),
                             linear-gradient(90deg, rgba(255,255,255,0.1) 1px, transparent 1px)`,
            backgroundSize: '48px 48px'
          }}
        />

        {/* Floating ambient orbs */}
        <div className="absolute top-20 right-[15%] w-[350px] h-[350px] rounded-full
                        bg-gradient-to-br from-sage-400/8 to-transparent blur-3xl animate-float hidden sm:block" />
        <div className="absolute bottom-32 left-[10%] w-[250px] h-[250px] rounded-full
                        bg-gradient-to-tr from-haven-navy-600/20 to-transparent blur-3xl animate-float-slow hidden sm:block" />

        <div className="relative max-w-6xl mx-auto px-4 sm:px-6 pt-24 sm:pt-32 pb-8 sm:pb-24 flex-1 flex items-center">
          <div className="grid lg:grid-cols-2 gap-8 lg:gap-12 items-center w-full">
            {/* Left - Copy */}
            <div className="flex flex-col items-center lg:items-start text-center lg:text-left">
              {/* Badge - Haven brand focused, NOT Alfred */}
              <div className="inline-flex items-center gap-2.5 px-4 py-2 bg-white/10 backdrop-blur-sm
                              rounded-full border border-white/10 mb-6">
                <span className="text-sm font-medium text-white/90">
                  One Bill. One Contact. Zero Hassle.
                </span>
              </div>

              {/* H1 */}
              <h1 className="text-4xl sm:text-5xl lg:text-6xl xl:text-7xl font-bold tracking-tight leading-[1.05] font-serif">
                <span className="text-white">Your home, finally</span>
                <br />
                <span className="bg-gradient-to-r from-sage-300 via-sage-200 to-sage-400
                                 bg-clip-text text-transparent">under control.</span>
              </h1>

              {/* Subheadline - Focus on OUTCOMES, not who does them */}
              <p className="mt-6 text-base sm:text-lg lg:text-xl text-white/70 max-w-xl leading-relaxed">
                <span className="sm:hidden">Track your bills. Get reminded before things break. Find savings you&apos;re missing. One monthly payment for everything.</span>
                <span className="hidden sm:inline">Track your bills. Get reminded before things break. Find savings you&apos;re missing. One monthly payment for everything. <span className="text-white/90 font-medium">Stop managing. Start living.</span></span>
              </p>

              {/* Value props */}
              <div className="flex flex-col sm:flex-row sm:flex-wrap gap-3 sm:gap-4 mt-6 w-full max-w-md sm:max-w-none justify-center lg:justify-start">
                {[
                  'One bill for everything',
                  'Never miss maintenance',
                  'Handyman who knows your home',
                ].map((item, i) => (
                  <div key={i} className="flex items-center justify-center lg:justify-start gap-2.5 text-white/80">
                    <div className="w-5 h-5 rounded-full bg-sage-500/20 flex items-center justify-center flex-shrink-0">
                      <Check className="w-3 h-3 text-sage-300" />
                    </div>
                    <span className="text-sm">{item}</span>
                  </div>
                ))}
              </div>

              {/* CTAs - Price IN the button */}
              <div className="mt-8 flex flex-col sm:flex-row items-center justify-center lg:justify-start gap-3 sm:gap-4 w-full sm:w-auto">
                <Link
                  href="/onboarding/welcome"
                  className="group relative w-full sm:w-auto px-8 py-4 bg-white text-haven-navy-900
                             font-semibold rounded-xl overflow-hidden transition-all duration-300
                             hover:shadow-[0_8px_32px_rgba(255,255,255,0.2)] hover:-translate-y-0.5"
                >
                  <span className="relative flex items-center justify-center gap-2">
                    Start for $39/mo
                    <ArrowRight className="w-5 h-5 transition-transform group-hover:translate-x-1" />
                  </span>
                </Link>
                <a
                  href="#how-it-works"
                  className="w-full sm:w-auto px-8 py-4 bg-white/5 backdrop-blur-sm
                             border border-white/20 text-white font-semibold rounded-xl
                             transition-all duration-300 hover:bg-white/10 hover:border-white/30
                             flex items-center justify-center gap-2"
                >
                  See How It Works
                </a>
              </div>

              {/* Small print below CTA */}
              <p className="mt-4 text-sm text-white/50 text-center lg:text-left">
                No contracts. Cancel anytime.
              </p>

              {/* Trust indicators */}
              <div className="mt-6 pt-6 border-t border-white/10">
                <div className="flex flex-wrap items-center justify-center lg:justify-start gap-3 sm:gap-4">
                  {[
                    { icon: Shield, text: 'Bank-Level Security', filled: false },
                    { icon: Star, text: '4.9/5 Rating', filled: true },
                    { icon: Award, text: '500+ Homes Managed', filled: false },
                  ].map((item, i) => (
                    <div key={i} className={`flex items-center gap-2 px-3 py-1.5 rounded-full
                                            bg-white/5 border border-white/10 ${i === 2 ? 'hidden sm:flex' : ''}`}>
                      <item.icon className={`w-4 h-4 ${item.filled ? 'text-sage-300 fill-sage-300' : 'text-white/60'}`} />
                      <span className="text-xs sm:text-sm text-white/80 font-medium">{item.text}</span>
                    </div>
                  ))}
                </div>
              </div>
            </div>

            {/* Right - Chat Preview (hidden on mobile) */}
            <div className="hidden lg:block relative lg:pl-8">
              <AlfredChatPreview />
            </div>
          </div>
        </div>

        {/* Scroll indicator on mobile */}
        <div className="sm:hidden flex justify-center pb-6 mt-auto">
          <a href="#how-it-works" className="flex flex-col items-center gap-1 text-white/40 animate-bounce">
            <span className="text-xs">Scroll to learn more</span>
            <ChevronDown className="w-5 h-5" />
          </a>
        </div>
      </section>

      {/* ================================================================== */}
      {/* HOW IT WORKS - This is where Alfred gets introduced! */}
      {/* ================================================================== */}
      <section id="how-it-works" className="py-16 sm:py-24 lg:py-32 bg-white">
        <div className="max-w-6xl mx-auto px-5 sm:px-6">
          <div className="text-center mb-12 sm:mb-16">
            {/* "Meet Alfred" badge - Alfred's introduction */}
            <div className="inline-flex items-center gap-2 px-4 py-2 bg-sage-100
                            rounded-full text-sage-700 text-sm font-medium mb-4">
              <Sparkles className="w-4 h-4" />
              Meet Alfred
            </div>
            <h2 className="text-3xl sm:text-4xl lg:text-5xl font-bold text-haven-navy-900
                           tracking-tight font-serif">
              How Alfred Works
            </h2>
            <p className="mt-4 text-base sm:text-lg text-warm-600 max-w-2xl mx-auto">
              Add your home once. Alfred handles everything else — tracking, reminders, bills, and more.
            </p>
          </div>

          <div className="grid md:grid-cols-3 gap-8 lg:gap-12">
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
              <div key={idx} className="relative group">
                {idx < 2 && (
                  <div className="hidden md:block absolute top-14 left-[60%] w-[80%] h-px
                                  bg-gradient-to-r from-sage-300 to-transparent" />
                )}
                <div className="text-center">
                  <div className="relative inline-flex mb-6">
                    <div className="w-24 h-24 rounded-2xl bg-gradient-to-br from-sage-100 to-sage-50
                                    text-sage-700 flex items-center justify-center shadow-elegant
                                    group-hover:shadow-elegant-lg transition-all duration-500
                                    group-hover:-translate-y-1">
                      <item.Icon className="w-10 h-10" />
                    </div>
                    <span className="absolute -top-2 -right-2 w-8 h-8 bg-haven-navy-900 text-white
                                     rounded-full flex items-center justify-center font-bold text-sm
                                     shadow-lg ring-4 ring-white">
                      {item.step}
                    </span>
                  </div>
                  <h3 className="text-xl font-bold text-haven-navy-900 mb-3">{item.title}</h3>
                  <p className="text-warm-600 leading-relaxed">{item.description}</p>
                </div>
              </div>
            ))}
          </div>

          {/* Email examples grid */}
          <div className="bg-gradient-to-br from-sage-50 to-sage-100/50 rounded-3xl p-8
                          border border-sage-200 mt-16 shadow-elegant">
            <h3 className="text-xl font-bold text-haven-navy-900 mb-6 text-center">
              Emails Alfred handles for you
            </h3>
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
                <div key={i} className="group text-center p-4 rounded-xl bg-white shadow-elegant
                                        hover:shadow-elegant-lg transition-all duration-300
                                        hover:-translate-y-0.5">
                  <div className="w-10 h-10 mx-auto mb-3 rounded-xl bg-sage-100
                                  flex items-center justify-center
                                  group-hover:scale-105 transition-transform duration-300">
                    <item.icon className="w-5 h-5 text-sage-600" />
                  </div>
                  <p className="font-semibold text-haven-navy-900 text-sm">{item.label}</p>
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
      <section className="py-20 sm:py-32 bg-cream-100">
        <div className="max-w-6xl mx-auto px-4 sm:px-6">
          <div className="text-center mb-16">
            <h2 className="text-3xl sm:text-4xl lg:text-5xl font-bold text-haven-navy-900
                           tracking-tight font-serif">
              What Alfred Does for You
            </h2>
            <p className="mt-4 text-lg text-warm-600 max-w-2xl mx-auto">
              Think of Alfred as your personal home assistant who never sleeps, never forgets, and actually enjoys organizing your life.
            </p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            {[
              { icon: Mail, color: 'blue', title: 'Reads Your Emails', description: 'Forward any home email and Alfred extracts dates, amounts, and action items automatically.' },
              { icon: TrendingDown, color: 'green', title: 'Finds Savings', description: 'Alfred monitors your bills and alerts you to better rates, unnecessary charges, and money-saving opportunities.' },
              { icon: Clock, color: 'amber', title: 'Never Forgets', description: "Maintenance reminders, warranty expirations, filter changes — Alfred tracks it all so you don't have to." },
              { icon: BookOpen, color: 'purple', title: 'Builds Your Home Manual', description: "Every system, appliance, paint color, and vendor — documented and searchable. Your home's complete digital memory." },
              { icon: Receipt, color: 'navy', title: 'One Bill', description: 'All your home expenses consolidated into a single monthly payment. No more juggling seven different due dates.' },
              { icon: HelpCircle, color: 'sage', title: 'Answers Anything', description: '"When was the roof last inspected?" "What\'s the model number of my water heater?" Alfred knows.' },
            ].map((card, i) => {
              const colorClasses: Record<string, { bg: string; text: string }> = {
                blue: { bg: 'bg-blue-100', text: 'text-blue-600' },
                green: { bg: 'bg-emerald-100', text: 'text-emerald-600' },
                amber: { bg: 'bg-amber-100', text: 'text-amber-600' },
                purple: { bg: 'bg-purple-100', text: 'text-purple-600' },
                navy: { bg: 'bg-haven-100', text: 'text-haven-700' },
                sage: { bg: 'bg-sage-100', text: 'text-sage-600' },
              };
              const colors = colorClasses[card.color];

              return (
                <div key={i} className="group bg-white rounded-2xl p-8
                                        shadow-elegant hover:shadow-elegant-lg
                                        border border-warm-100 hover:border-sage-200
                                        transition-all duration-500
                                        hover:-translate-y-1">
                  <div className={`w-14 h-14 rounded-xl ${colors.bg}
                                  flex items-center justify-center mb-6
                                  group-hover:scale-105 transition-transform duration-300`}>
                    <card.icon className={`w-7 h-7 ${colors.text}`} />
                  </div>
                  <h3 className="text-xl font-bold text-haven-navy-900 mb-3">{card.title}</h3>
                  <p className="text-warm-600 leading-relaxed">{card.description}</p>
                </div>
              );
            })}
          </div>
        </div>
      </section>

      {/* ================================================================== */}
      {/* HANDYMAN SECTION - Dark Background */}
      {/* ================================================================== */}
      <section className="relative py-20 sm:py-32 bg-gradient-to-b from-haven-navy-950 to-haven-navy-900 overflow-hidden">
        {/* Subtle glow accent */}
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[600px] h-[400px]
                        bg-[radial-gradient(ellipse_at_center,rgba(164,180,148,0.08),transparent)] blur-3xl" />

        <div className="relative max-w-6xl mx-auto px-4 sm:px-6">
          <div className="grid lg:grid-cols-2 gap-12 items-center">
            <div>
              <div className="inline-flex items-center gap-2 px-4 py-2 bg-sage-400/10
                              border border-sage-400/20 rounded-full mb-6">
                <Hammer className="w-4 h-4 text-sage-300" />
                <span className="text-sm font-medium text-sage-300">Haven Handyman</span>
              </div>
              <h2 className="text-3xl sm:text-4xl lg:text-5xl font-bold text-white mb-6 font-serif tracking-tight">
                A Real Handyman Who Knows Your Home
              </h2>
              <p className="text-lg text-white/70 mb-8 leading-relaxed">
                No more explaining your home&apos;s quirks to every contractor. Your Haven handyman has access to your complete home profile and maintenance history.
              </p>

              <ul className="space-y-4 mb-10">
                {[
                  'Background-checked and insured',
                  'Knows your home systems before they arrive',
                  'Same handyman every time (when possible)',
                  'Can handle 90% of small repairs',
                  'Escalates to specialists when needed',
                ].map((item, i) => (
                  <li key={i} className="flex items-start gap-3">
                    <div className="mt-0.5 w-5 h-5 rounded-full bg-sage-500/20
                                    flex items-center justify-center flex-shrink-0">
                      <Check className="w-3 h-3 text-sage-300" />
                    </div>
                    <span className="text-white/80">{item}</span>
                  </li>
                ))}
              </ul>

              {/* Pricing badges - UPDATED per spec */}
              <div className="flex flex-wrap justify-center lg:justify-start gap-4">
                <div className="px-5 py-3 bg-white/5 backdrop-blur-sm rounded-xl border border-white/10">
                  <span className="text-white/50 text-xs sm:text-sm block">Essentials</span>
                  <div className="text-xl sm:text-2xl font-bold text-white">
                    $99<span className="text-sm font-normal text-white/50">/visit</span>
                  </div>
                </div>
                <div className="px-5 py-3 bg-sage-400/10 backdrop-blur-sm rounded-xl border border-sage-400/20">
                  <span className="text-sage-300 text-xs sm:text-sm block">Lite $349+</span>
                  <div className="text-xl sm:text-2xl font-bold text-white">Quarterly</div>
                </div>
                <div className="px-5 py-3 bg-sage-400/10 backdrop-blur-sm rounded-xl border border-sage-400/20">
                  <span className="text-sage-300 text-xs sm:text-sm block">Haven $749+</span>
                  <div className="text-xl sm:text-2xl font-bold text-white">Monthly</div>
                </div>
              </div>
            </div>

            {/* Handyman Profile Card */}
            <div className="bg-white rounded-2xl p-8 shadow-elegant-xl">
              <div className="flex items-start gap-4 mb-6">
                <div className="w-20 h-20 bg-gradient-to-br from-warm-200 to-warm-100
                                rounded-xl flex items-center justify-center">
                  <Wrench className="w-10 h-10 text-warm-500" />
                </div>
                <div>
                  <h3 className="text-xl font-bold text-haven-navy-900">Mike Rodriguez</h3>
                  <p className="text-warm-600">Your Haven Handyman</p>
                  <div className="flex items-center gap-1 mt-2">
                    {[...Array(5)].map((_, i) => (
                      <Star key={i} className="w-4 h-4 text-sage-500 fill-sage-500" />
                    ))}
                    <span className="text-sm text-warm-500 ml-2">4.9 (127 reviews)</span>
                  </div>
                </div>
              </div>

              <div className="space-y-3 mb-6">
                {[
                  { icon: MapPin, text: 'Serves Greater Hartford area' },
                  { icon: Clock, text: '15+ years experience' },
                  { icon: Shield, text: 'Background checked & insured' },
                ].map((item, i) => (
                  <div key={i} className="flex items-center gap-3 text-warm-700">
                    <item.icon className="w-5 h-5 text-warm-400" />
                    <span>{item.text}</span>
                  </div>
                ))}
              </div>

              <div className="bg-sage-50 rounded-xl p-5 border border-sage-200">
                <div className="flex items-start gap-3">
                  <Quote className="w-5 h-5 text-sage-500 flex-shrink-0 mt-0.5" />
                  <div>
                    <p className="text-warm-700 italic leading-relaxed">
                      &quot;Mike already knew about our old furnace before he arrived. Fixed it in half the time!&quot;
                    </p>
                    <p className="text-sm text-warm-500 mt-3 font-medium">— The Morrison Family</p>
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
      <section className="py-20 sm:py-32 bg-sage-50">
        <div className="max-w-6xl mx-auto px-4 sm:px-6">
          <div className="text-center mb-16">
            <h2 className="text-3xl sm:text-4xl lg:text-5xl font-bold text-haven-navy-900
                           tracking-tight font-serif">
              Is Haven Right for You?
            </h2>
            <p className="mt-4 text-lg text-warm-600 max-w-2xl mx-auto">
              Most homeowners start with Essentials. Here&apos;s who we help most.
            </p>
          </div>

          <div className="grid md:grid-cols-3 gap-6">
            {[
              {
                icon: Home,
                iconBg: 'bg-blue-100',
                iconColor: 'text-blue-600',
                title: 'The Newcomer',
                description: 'Just bought a home and feeling overwhelmed by all the things you need to track, remember, and maintain.',
                features: ['Build your home manual from scratch', 'Get maintenance reminders automatically', 'One bill from day one'],
                price: '$39',
                plan: 'Essentials + Alfred',
                featured: false,
              },
              {
                icon: TrendingDown,
                iconBg: 'bg-emerald-100',
                iconColor: 'text-emerald-600',
                title: 'The Optimizer',
                description: "You're organized but tired of missing things. You know you're paying too much but don't have time to shop around.",
                features: ['Find savings automatically', 'Never miss a payment again', 'Track everything in one place'],
                price: '$39',
                plan: 'Essentials + Alfred',
                featured: true,
              },
              {
                icon: Phone,
                iconBg: 'bg-purple-100',
                iconColor: 'text-purple-600',
                title: 'The Busy Bee',
                description: "You don't have time to make calls, get quotes, or schedule contractors. You need someone to handle it.",
                features: ['Text to get anything done', 'We call, schedule, and coordinate', 'Human manager + Alfred'],
                price: '$349',
                plan: 'Haven Lite',
                featured: false,
              },
            ].map((card, i) => (
              <div key={i} className={`group bg-white rounded-2xl p-8 relative
                                       shadow-elegant hover:shadow-elegant-lg
                                       transition-all duration-500 hover:-translate-y-1
                                       ${card.featured
                                         ? 'ring-2 ring-sage-400 shadow-elegant-lg'
                                         : 'border border-warm-200'}`}>
                {card.featured && (
                  <div className="absolute -top-3.5 left-1/2 -translate-x-1/2">
                    <div className="px-4 py-1.5 bg-sage-500 text-white text-xs font-bold
                                    rounded-full shadow-lg">
                      Most Popular
                    </div>
                  </div>
                )}
                <div className={`w-14 h-14 ${card.iconBg} rounded-xl flex items-center justify-center mb-6
                                group-hover:scale-105 transition-transform duration-300`}>
                  <card.icon className={`w-7 h-7 ${card.iconColor}`} />
                </div>
                <h3 className="text-xl font-bold text-haven-navy-900 mb-3">{card.title}</h3>
                <p className="text-warm-600 mb-6 leading-relaxed">{card.description}</p>
                <ul className="space-y-3 mb-8">
                  {card.features.map((feature, j) => (
                    <li key={j} className="flex items-start gap-3">
                      <div className="mt-0.5 w-5 h-5 rounded-full bg-sage-100
                                      flex items-center justify-center flex-shrink-0">
                        <Check className="w-3 h-3 text-sage-600" />
                      </div>
                      <span className="text-sm text-warm-700">{feature}</span>
                    </li>
                  ))}
                </ul>
                <div className="pt-6 border-t border-warm-100">
                  <p className="text-2xl font-bold text-haven-navy-900">
                    {card.price}<span className="text-base font-normal text-warm-500">/mo</span>
                  </p>
                  <p className="text-sm text-warm-500 mt-1">{card.plan}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ================================================================== */}
      {/* ONE BILL SECTION - Dark Background */}
      {/* ================================================================== */}
      <section className="relative py-20 sm:py-32 bg-gradient-to-b from-haven-navy-900 to-haven-navy-950 overflow-hidden">
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[600px]
                        bg-[radial-gradient(ellipse_at_center,rgba(164,180,148,0.06),transparent)] blur-3xl" />

        <div className="relative max-w-6xl mx-auto px-4 sm:px-6">
          <div className="text-center mb-16">
            <h2 className="text-3xl sm:text-4xl lg:text-5xl font-bold text-white font-serif tracking-tight">
              One Bill. Seriously.
            </h2>
            <p className="mt-4 text-lg text-white/70 max-w-2xl mx-auto">
              Stop juggling seven different payment due dates. Haven consolidates everything into one simple monthly payment.
            </p>
          </div>

          <div className="grid md:grid-cols-2 gap-8 items-stretch">
            {/* Before */}
            <div className="bg-white/5 backdrop-blur-sm rounded-2xl p-8 border border-white/10">
              <h3 className="text-xl font-bold text-white mb-6 flex items-center gap-3">
                <span className="w-7 h-7 bg-red-500/20 rounded-full flex items-center justify-center">
                  <span className="text-red-400 text-sm">✗</span>
                </span>
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
                  <div key={i} className="flex items-center justify-between py-3
                                          border-b border-white/10 last:border-0">
                    <span className="text-white/70">{bill.name}</span>
                    <div className="flex items-center gap-4">
                      <span className="text-xs text-white/50 bg-white/5 px-2 py-1 rounded">
                        Due: {bill.date}
                      </span>
                      <span className="text-white font-medium">{bill.amount}</span>
                    </div>
                  </div>
                ))}
              </div>
              <div className="mt-6 pt-6 border-t border-white/20 flex justify-between items-center">
                <span className="text-white/60">7 different payments</span>
                <span className="text-red-400 font-bold text-sm">7 chances to be late</span>
              </div>
            </div>

            {/* After */}
            <div className="bg-white rounded-2xl p-8 shadow-elegant-xl">
              <h3 className="text-xl font-bold text-haven-navy-900 mb-6 flex items-center gap-3">
                <span className="w-7 h-7 bg-sage-500 rounded-full flex items-center justify-center">
                  <Check className="w-4 h-4 text-white" />
                </span>
                With Haven
              </h3>
              <div className="flex items-center justify-center py-16">
                <div className="text-center">
                  <p className="text-7xl font-bold bg-gradient-to-r from-sage-600 to-sage-500
                                bg-clip-text text-transparent">1</p>
                  <p className="text-haven-navy-900 text-2xl font-semibold mt-3">Monthly Bill</p>
                  <p className="text-warm-600 mt-2">Same day every month</p>
                </div>
              </div>
              <div className="mt-6 pt-6 border-t border-warm-200 flex justify-between items-center">
                <span className="text-warm-600">All bills included</span>
                <span className="text-sage-600 font-bold flex items-center gap-2">
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
      <section id="pricing" className="py-20 sm:py-32 bg-white">
        <div className="max-w-6xl mx-auto px-4 sm:px-6">
          <div className="text-center mb-16">
            <h2 className="text-3xl sm:text-4xl lg:text-5xl font-bold text-haven-navy-900
                           tracking-tight font-serif">
              Simple, Transparent Pricing
            </h2>
            <p className="mt-4 text-lg text-warm-600 max-w-2xl mx-auto">
              Most homeowners start with Essentials. Upgrade anytime if you need more hands-on support.
            </p>
          </div>

          {/* Pricing cards - horizontal scroll on mobile */}
          <div className="flex overflow-x-auto snap-x snap-mandatory gap-4 pb-4 -mx-5 px-5
                          sm:grid sm:grid-cols-2 lg:grid-cols-3 sm:gap-6 lg:gap-8
                          sm:overflow-visible sm:mx-0 sm:px-0 sm:pb-0
                          max-w-5xl sm:mx-auto mb-12">
            {/* Essentials - Featured */}
            <div className="flex-shrink-0 w-[85%] snap-start sm:w-auto relative p-6 sm:p-8 rounded-2xl
                            bg-gradient-to-b from-haven-navy-900 to-haven-navy-950
                            text-white ring-2 ring-sage-400 shadow-elegant-xl">
              <div className="absolute -top-3 left-1/2 -translate-x-1/2">
                <div className="px-4 py-1.5 bg-sage-500 text-white text-xs font-bold
                                rounded-full shadow-lg whitespace-nowrap">
                  Start Here
                </div>
              </div>

              <div className="flex items-center gap-3 mb-4 mt-2">
                <div className="w-12 h-12 bg-sage-500/20 rounded-xl flex items-center justify-center">
                  <Sparkles className="w-6 h-6 text-sage-300" />
                </div>
                <div>
                  <h3 className="text-xl font-bold text-white">Essentials</h3>
                  <p className="text-sage-300 text-sm">Alfred + Core Features</p>
                </div>
              </div>

              <div className="flex items-baseline gap-1 mt-6 mb-8">
                <span className="text-4xl font-bold text-white">$39</span>
                <span className="text-white/60">/month</span>
              </div>

              <ul className="space-y-3 mb-8">
                {[
                  'Alfred email processing',
                  'One consolidated bill',
                  'Home manual & inventory',
                  'Maintenance reminders',
                  'Bill tracking & alerts',
                  'Savings finder',
                  'Handyman visits ($99/each)',
                ].map((feature, i) => (
                  <li key={i} className="flex items-start gap-3">
                    <Check className="w-5 h-5 text-sage-300 mt-0.5 flex-shrink-0" />
                    <span className="text-white/80 text-sm">{feature}</span>
                  </li>
                ))}
              </ul>

              <Link
                href="/onboarding/welcome"
                className="block w-full py-3.5 bg-white text-haven-navy-900
                           font-semibold rounded-xl text-center
                           hover:bg-sage-50 transition-colors"
              >
                Get Started
              </Link>
            </div>

            {/* Haven Lite */}
            <div className="flex-shrink-0 w-[85%] snap-start sm:w-auto p-6 sm:p-8 rounded-2xl
                            bg-white border border-warm-200 shadow-elegant
                            hover:shadow-elegant-lg hover:border-sage-200
                            transition-all duration-500">
              <div className="flex items-center gap-3 mb-4">
                <div className="w-12 h-12 bg-haven-100 rounded-xl flex items-center justify-center">
                  <MessageCircle className="w-6 h-6 text-haven-700" />
                </div>
                <div>
                  <h3 className="text-xl font-bold text-haven-navy-900">Haven Lite</h3>
                  <p className="text-warm-500 text-sm">Text-based Support</p>
                </div>
              </div>

              <div className="flex items-baseline gap-1 mt-6 mb-8">
                <span className="text-4xl font-bold text-haven-navy-900">$349</span>
                <span className="text-warm-500">/month</span>
              </div>

              <ul className="space-y-3 mb-8">
                {[
                  'Everything in Essentials',
                  'Dedicated home manager',
                  'Text-based coordination',
                  'Vendor vetting & scheduling',
                  'Quote comparison',
                  'Quarterly handyman visit included',
                ].map((feature, i) => (
                  <li key={i} className="flex items-start gap-3">
                    <Check className="w-5 h-5 text-sage-500 mt-0.5 flex-shrink-0" />
                    <span className="text-warm-700 text-sm">{feature}</span>
                  </li>
                ))}
              </ul>

              <Link
                href="/onboarding/welcome?plan=lite"
                className="block w-full py-3.5 bg-haven-navy-900 text-white
                           font-semibold rounded-xl text-center
                           hover:bg-haven-navy-800 transition-colors"
              >
                Choose Lite
              </Link>
            </div>

            {/* Haven */}
            <div className="flex-shrink-0 w-[85%] snap-start sm:w-auto p-6 sm:p-8 rounded-2xl
                            bg-white border border-warm-200 shadow-elegant
                            hover:shadow-elegant-lg hover:border-sage-200
                            transition-all duration-500">
              <div className="flex items-center gap-3 mb-4">
                <div className="w-12 h-12 bg-haven-100 rounded-xl flex items-center justify-center">
                  <Phone className="w-6 h-6 text-haven-700" />
                </div>
                <div>
                  <h3 className="text-lg sm:text-xl font-bold text-haven-navy-900">Haven</h3>
                  <p className="text-warm-500 text-sm">Proactive Management</p>
                </div>
              </div>

              <div className="flex items-baseline gap-1 mt-5 sm:mt-6 mb-6 sm:mb-8">
                <span className="text-3xl sm:text-4xl font-bold text-haven-navy-900">$749</span>
                <span className="text-warm-500">/month</span>
              </div>

              <ul className="space-y-3 mb-6 sm:mb-8">
                {[
                  'Everything in Lite',
                  'Phone & video support',
                  'Proactive maintenance',
                  'Annual home walkthrough',
                  'Project management',
                  'Handyman visits included',
                ].map((feature, i) => (
                  <li key={i} className="flex items-start gap-3">
                    <Check className="w-5 h-5 text-sage-500 mt-0.5 flex-shrink-0" />
                    <span className="text-warm-700 text-sm">{feature}</span>
                  </li>
                ))}
              </ul>

              <Link
                href="/onboarding/welcome?plan=haven"
                className="block w-full py-3.5 bg-haven-navy-900 text-white
                           font-semibold rounded-xl text-center
                           hover:bg-haven-navy-800 transition-colors"
              >
                Choose Haven
              </Link>
            </div>
          </div>

          {/* Premium Tiers Toggle */}
          <div className="text-center">
            <button
              onClick={() => setShowPremiumTiers(!showPremiumTiers)}
              className="inline-flex items-center gap-2 text-haven-navy-700 hover:text-haven-navy-900
                         font-medium transition-colors"
            >
              {showPremiumTiers ? 'Hide' : 'Show'} premium tiers
              {showPremiumTiers ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
            </button>

            {showPremiumTiers && (
              <div className="grid md:grid-cols-2 gap-6 mt-8 max-w-3xl mx-auto">
                {[
                  {
                    title: 'Haven+',
                    subtitle: 'Lifestyle Services',
                    price: '$1,499',
                    features: ['Everything in Haven', 'Travel coordination', 'Event planning support', 'Seasonal home prep'],
                  },
                  {
                    title: 'Estate',
                    subtitle: 'White Glove Service',
                    price: '$3,499',
                    features: ['Everything in Haven+', 'Multi-property support', 'Dedicated estate manager', '24/7 emergency response'],
                  },
                ].map((tier, i) => (
                  <div key={i} className="bg-cream-100 rounded-2xl p-6 border border-warm-200 text-left
                                          shadow-elegant hover:shadow-elegant-lg transition-all duration-500">
                    <h3 className="text-xl font-bold text-haven-navy-900 mb-1">{tier.title}</h3>
                    <p className="text-sm text-warm-500 mb-4">{tier.subtitle}</p>
                    <p className="text-3xl font-bold text-haven-navy-900 mb-4">
                      {tier.price}<span className="text-base font-normal text-warm-500">/mo</span>
                    </p>
                    <ul className="space-y-2">
                      {tier.features.map((f, j) => (
                        <li key={j} className="flex items-center gap-2 text-sm text-warm-600">
                          <Check className="w-4 h-4 text-sage-500" />
                          {f}
                        </li>
                      ))}
                    </ul>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </section>

      {/* ================================================================== */}
      {/* TESTIMONIALS */}
      {/* ================================================================== */}
      <section className="py-20 sm:py-32 bg-gradient-to-b from-sage-50 to-white">
        <div className="max-w-6xl mx-auto px-4 sm:px-6">
          <div className="text-center mb-16">
            <h2 className="text-3xl sm:text-4xl lg:text-5xl font-bold text-haven-navy-900
                           tracking-tight font-serif">
              Real Homeowners. Real Results.
            </h2>
          </div>

          <div className="grid md:grid-cols-3 gap-6 mb-16">
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
              <div key={i} className="bg-white rounded-2xl p-8 shadow-elegant hover:shadow-elegant-lg
                                      border border-warm-100 transition-all duration-500">
                <div className="flex gap-1 mb-4">
                  {[...Array(5)].map((_, j) => (
                    <Star key={j} className="w-4 h-4 text-sage-500 fill-sage-500" />
                  ))}
                </div>
                <p className="text-warm-700 leading-relaxed italic mb-6">
                  &quot;{testimonial.quote}&quot;
                </p>
                <div className="flex items-center gap-3 pt-4 border-t border-warm-100">
                  <div className="w-10 h-10 rounded-full bg-haven-navy-100
                                  flex items-center justify-center">
                    <span className="text-sm font-bold text-haven-navy-700">{testimonial.avatar}</span>
                  </div>
                  <div>
                    <div className="font-semibold text-haven-navy-900">{testimonial.name}</div>
                    <div className="text-sm text-warm-500">{testimonial.role}</div>
                  </div>
                </div>
              </div>
            ))}
          </div>

          {/* Stats */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-8">
            {[
              { value: '$400', label: 'Avg. savings found/year' },
              { value: '500+', label: 'Homes managed' },
              { value: '4.9/5', label: 'Customer rating' },
              { value: '1', label: 'Bill to pay' },
            ].map((stat, i) => (
              <div key={i} className="text-center">
                <p className="text-4xl sm:text-5xl font-bold bg-gradient-to-r from-haven-navy-900 to-haven-navy-700
                              bg-clip-text text-transparent">{stat.value}</p>
                <p className="text-warm-600 mt-2">{stat.label}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ================================================================== */}
      {/* FAQ */}
      {/* ================================================================== */}
      <section className="py-20 sm:py-32 bg-white">
        <div className="max-w-3xl mx-auto px-4 sm:px-6">
          <div className="text-center mb-16">
            <h2 className="text-3xl sm:text-4xl lg:text-5xl font-bold text-haven-navy-900
                           tracking-tight font-serif">
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
              <div
                key={i}
                className={`rounded-2xl border transition-all duration-300
                           ${openFaq === i
                             ? 'bg-sage-50 border-sage-200 shadow-elegant'
                             : 'bg-white border-warm-200 hover:border-warm-300'}`}
              >
                <button
                  onClick={() => setOpenFaq(openFaq === i ? null : i)}
                  className="w-full flex items-center justify-between p-6 text-left"
                >
                  <span className="font-semibold text-haven-navy-900 pr-4">{faq.q}</span>
                  <div className={`w-8 h-8 rounded-full flex items-center justify-center
                                  flex-shrink-0 transition-all duration-300
                                  ${openFaq === i
                                    ? 'bg-sage-500 text-white rotate-180'
                                    : 'bg-warm-100 text-warm-600'}`}>
                    <ChevronDown className="w-5 h-5" />
                  </div>
                </button>
                <div className={`overflow-hidden transition-all duration-300
                                ${openFaq === i ? 'max-h-96 pb-6' : 'max-h-0'}`}>
                  <p className="px-6 text-warm-600 leading-relaxed">{faq.a}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ================================================================== */}
      {/* FINAL CTA */}
      {/* ================================================================== */}
      <section className="relative py-20 sm:py-32 bg-gradient-to-b from-haven-navy-950 to-haven-navy-900 overflow-hidden">
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_60%_50%_at_50%_50%,rgba(164,180,148,0.08),transparent)]" />

        <div className="relative max-w-4xl mx-auto px-4 sm:px-6 text-center">
          <h2 className="text-3xl sm:text-4xl lg:text-5xl font-bold text-white mb-6 font-serif tracking-tight">
            Ready to take control of your home?
          </h2>
          <p className="text-lg sm:text-xl text-white/70 mb-10 max-w-2xl mx-auto leading-relaxed">
            One bill. One app. A handyman who knows your home. Join 500+ families who stopped managing and started living.
          </p>
          <Link
            href="/onboarding/welcome"
            className="group inline-flex items-center gap-2 px-8 py-4 bg-white text-haven-navy-900
                       font-semibold rounded-xl transition-all duration-300
                       hover:shadow-[0_8px_32px_rgba(255,255,255,0.2)] hover:-translate-y-0.5 text-lg"
          >
            Get Started — $39/mo
            <ArrowRight className="w-5 h-5 transition-transform group-hover:translate-x-1" />
          </Link>
          <p className="mt-6 text-sm text-white/50">No contracts. Cancel anytime.</p>
        </div>
      </section>

      {/* ================================================================== */}
      {/* FOOTER */}
      {/* ================================================================== */}
      <footer className="bg-haven-navy-950 py-16">
        <div className="max-w-6xl mx-auto px-4 sm:px-6">
          <div className="grid md:grid-cols-4 gap-8 mb-12">
            <div>
              <div className="flex items-center gap-2 mb-4">
                <Image src="/icon-white.svg" alt="Haven" width={28} height={28} />
                <span className="text-xl font-bold text-white">Haven</span>
              </div>
              <p className="text-white/50 text-sm leading-relaxed">
                Stop managing your home. Start living in it.
              </p>
            </div>
            <div>
              <h4 className="font-semibold text-white mb-4">Product</h4>
              <ul className="space-y-3 text-sm text-white/50">
                <li><a href="#how-it-works" className="hover:text-white transition-colors">How It Works</a></li>
                <li><a href="#pricing" className="hover:text-white transition-colors">Pricing</a></li>
                <li><Link href="/onboarding/welcome" className="hover:text-white transition-colors">Get Started</Link></li>
              </ul>
            </div>
            <div>
              <h4 className="font-semibold text-white mb-4">Company</h4>
              <ul className="space-y-3 text-sm text-white/50">
                <li><a href="#" className="hover:text-white transition-colors">About</a></li>
                <li><a href="#" className="hover:text-white transition-colors">Blog</a></li>
                <li><a href="#" className="hover:text-white transition-colors">Careers</a></li>
              </ul>
            </div>
            <div>
              <h4 className="font-semibold text-white mb-4">Legal</h4>
              <ul className="space-y-3 text-sm text-white/50">
                <li><a href="#" className="hover:text-white transition-colors">Privacy Policy</a></li>
                <li><a href="#" className="hover:text-white transition-colors">Terms of Service</a></li>
              </ul>
            </div>
          </div>
          <div className="pt-8 border-t border-white/10 flex flex-col sm:flex-row items-center justify-between gap-4">
            <p className="text-sm text-white/40">© 2026 Haven Home. All rights reserved.</p>
            <div className="flex items-center gap-4">
              <a href="#" className="text-white/40 hover:text-white transition-colors">
                <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24"><path d="M24 4.557c-.883.392-1.832.656-2.828.775 1.017-.609 1.798-1.574 2.165-2.724-.951.564-2.005.974-3.127 1.195-.897-.957-2.178-1.555-3.594-1.555-3.179 0-5.515 2.966-4.797 6.045-4.091-.205-7.719-2.165-10.148-5.144-1.29 2.213-.669 5.108 1.523 6.574-.806-.026-1.566-.247-2.229-.616-.054 2.281 1.581 4.415 3.949 4.89-.693.188-1.452.232-2.224.084.626 1.956 2.444 3.379 4.6 3.419-2.07 1.623-4.678 2.348-7.29 2.04 2.179 1.397 4.768 2.212 7.548 2.212 9.142 0 14.307-7.721 13.995-14.646.962-.695 1.797-1.562 2.457-2.549z"/></svg>
              </a>
              <a href="#" className="text-white/40 hover:text-white transition-colors">
                <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24"><path d="M12 0c-6.627 0-12 5.373-12 12s5.373 12 12 12 12-5.373 12-12-5.373-12-12-12zm3 8h-1.35c-.538 0-.65.221-.65.778v1.222h2l-.209 2h-1.791v7h-3v-7h-2v-2h2v-2.308c0-1.769.931-2.692 3.029-2.692h1.971v3z"/></svg>
              </a>
              <a href="#" className="text-white/40 hover:text-white transition-colors">
                <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z"/></svg>
              </a>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}
