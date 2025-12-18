import Link from 'next/link';
import {
  Shield,
  Plane,
  Mail,
  Calendar,
  Archive,
  Car,
  PawPrint,
  Phone,
  UserCheck,
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
  Building2,
} from 'lucide-react';

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
              <a href="#features" className="text-slate-600 hover:text-emerald-950 text-sm font-medium transition-colors">Features</a>
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
      <section className="pt-32 pb-20 px-4 sm:px-6 lg:px-8">
        <div className="max-w-5xl mx-auto text-center">
          <div className="inline-flex items-center gap-2 px-4 py-2 bg-emerald-50 rounded-full mb-8">
            <Sparkles className="w-4 h-4 text-emerald-700" />
            <span className="text-sm font-medium text-emerald-800">Now accepting applications in select markets</span>
          </div>

          <h1 className="font-serif text-5xl sm:text-6xl lg:text-7xl font-medium text-emerald-950 leading-tight tracking-tight mb-6">
            The Operating System<br />for Your Home & Family.
          </h1>

          <p className="text-xl sm:text-2xl text-slate-600 max-w-3xl mx-auto mb-10 leading-relaxed">
            A dedicated Chief of Staff. A secure wallet for your bills. A Handyman for your repairs.
            And a Travel Agent for your life. All in one membership.
          </p>

          <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
            <Link
              href="/register"
              className="w-full sm:w-auto inline-flex items-center justify-center gap-2 px-8 py-4 bg-emerald-950 text-white text-lg font-medium rounded-xl hover:bg-emerald-900 transition-colors shadow-lg shadow-emerald-950/20"
            >
              Check Address Eligibility
              <ArrowRight className="w-5 h-5" />
            </Link>
            <a
              href="#pricing"
              className="w-full sm:w-auto inline-flex items-center justify-center gap-2 px-8 py-4 bg-white text-emerald-950 text-lg font-medium rounded-xl border-2 border-emerald-950 hover:bg-emerald-50 transition-colors"
            >
              View Membership Tiers
            </a>
          </div>

          {/* Trust indicators */}
          <div className="flex flex-wrap items-center justify-center gap-8 mt-16 pt-8 border-t border-slate-200">
            <div className="flex items-center gap-2 text-slate-500">
              <Lock className="w-5 h-5" />
              <span className="text-sm font-medium">FDIC-Insured Wallet</span>
            </div>
            <div className="flex items-center gap-2 text-slate-500">
              <Shield className="w-5 h-5" />
              <span className="text-sm font-medium">Insured to $2 Million</span>
            </div>
            <div className="flex items-center gap-2 text-slate-500">
              <BadgeCheck className="w-5 h-5" />
              <span className="text-sm font-medium">Vetted Professionals</span>
            </div>
          </div>
        </div>
      </section>

      {/* The Core Foundation */}
      <section id="features" className="py-24 px-4 sm:px-6 lg:px-8 bg-white">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="font-serif text-4xl sm:text-5xl font-medium text-emerald-950 mb-4">
              Your Home. Fully Managed.
            </h2>
            <p className="text-lg text-slate-600 max-w-2xl mx-auto">
              Three foundational pillars that transform how you manage your household.
            </p>
          </div>

          <div className="grid md:grid-cols-3 gap-8">
            {/* Card 1 - Financial Consolidation */}
            <div className="group bg-slate-50 rounded-2xl p-8 hover:shadow-xl transition-all duration-300 border border-slate-100">
              <div className="w-14 h-14 bg-emerald-100 rounded-xl flex items-center justify-center mb-6 group-hover:bg-emerald-200 transition-colors">
                <FileText className="w-7 h-7 text-emerald-700" />
              </div>
              <h3 className="font-serif text-2xl font-medium text-emerald-950 mb-2">
                One Monthly Statement.
              </h3>
              <p className="text-sm font-medium text-emerald-700 mb-4 uppercase tracking-wider">
                Financial Consolidation
              </p>
              <p className="text-slate-600 leading-relaxed">
                We manage all your bills: mortgages, car payments, loans, utilities, home services,
                and subscriptions. Everything flows through Haven. One comprehensive monthly statement
                replaces the chaos of 20 different due dates and logins.
              </p>
            </div>

            {/* Card 2 - Inclusive Maintenance */}
            <div className="group bg-slate-50 rounded-2xl p-8 hover:shadow-xl transition-all duration-300 border border-slate-100">
              <div className="w-14 h-14 bg-emerald-100 rounded-xl flex items-center justify-center mb-6 group-hover:bg-emerald-200 transition-colors">
                <Wrench className="w-7 h-7 text-emerald-700" />
              </div>
              <h3 className="font-serif text-2xl font-medium text-emerald-950 mb-2">
                Proactive Care.
              </h3>
              <p className="text-sm font-medium text-emerald-700 mb-4 uppercase tracking-wider">
                Inclusive Maintenance
              </p>
              <p className="text-slate-600 leading-relaxed">
                Every home is assigned a dedicated Handyman. Your membership includes monthly visits
                to change filters, fix hinges, and handle small repairs. The small stuff is on us.
              </p>
            </div>

            {/* Card 3 - Project & Lifestyle */}
            <div className="group bg-slate-50 rounded-2xl p-8 hover:shadow-xl transition-all duration-300 border border-slate-100">
              <div className="w-14 h-14 bg-emerald-100 rounded-xl flex items-center justify-center mb-6 group-hover:bg-emerald-200 transition-colors">
                <Building2 className="w-7 h-7 text-emerald-700" />
              </div>
              <h3 className="font-serif text-2xl font-medium text-emerald-950 mb-2">
                Zero-Fee Project Management.
              </h3>
              <p className="text-sm font-medium text-emerald-700 mb-4 uppercase tracking-wider">
                Project & Lifestyle
              </p>
              <p className="text-slate-600 leading-relaxed">
                Homeowners often pay 15-20% just for a project manager. Ours is included.
                From kitchen renovations to holiday decorations, your Manager coordinates
                contractors and ensures quality without extra fees.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Family Operations Layer - Bento Grid */}
      <section className="py-24 px-4 sm:px-6 lg:px-8 bg-emerald-950">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="font-serif text-4xl sm:text-5xl font-medium text-white mb-4">
              Your Family. Perfectly Orchestrated.
            </h2>
            <p className="text-lg text-emerald-200 max-w-2xl mx-auto">
              Beyond the home. We manage the rhythm of your entire household.
            </p>
          </div>

          <div className="grid md:grid-cols-3 gap-6">
            {/* Feature A - Travel (Large - spans 2 columns) */}
            <div className="md:col-span-2 bg-gradient-to-br from-emerald-900 to-emerald-800 rounded-2xl p-8 sm:p-10 border border-emerald-700/30">
              <div className="flex items-center gap-3 mb-6">
                <div className="w-12 h-12 bg-white/10 rounded-xl flex items-center justify-center">
                  <Plane className="w-6 h-6 text-emerald-300" />
                </div>
                <div className="w-12 h-12 bg-white/10 rounded-xl flex items-center justify-center">
                  <Shield className="w-6 h-6 text-emerald-300" />
                </div>
              </div>
              <h3 className="font-serif text-3xl font-medium text-white mb-3">
                Travel & Home Security.
              </h3>
              <p className="text-emerald-100 text-lg leading-relaxed max-w-xl">
                Your Manager acts as your travel agent. We plan the itinerary, book flights
                using your Household Wallet, and automatically secure your house (water off,
                mail held, alarm set) before you leave.
              </p>
              <div className="mt-8 flex flex-wrap gap-3">
                <span className="px-4 py-2 bg-white/10 rounded-full text-sm text-emerald-200">Itinerary Planning</span>
                <span className="px-4 py-2 bg-white/10 rounded-full text-sm text-emerald-200">Flight Booking</span>
                <span className="px-4 py-2 bg-white/10 rounded-full text-sm text-emerald-200">Home Prep Protocol</span>
                <span className="px-4 py-2 bg-white/10 rounded-full text-sm text-emerald-200">Return Checklist</span>
              </div>
            </div>

            {/* Feature B - Admin (Medium) */}
            <div className="bg-gradient-to-br from-slate-800 to-slate-900 rounded-2xl p-8 border border-slate-700/30">
              <div className="w-12 h-12 bg-white/10 rounded-xl flex items-center justify-center mb-6">
                <Mail className="w-6 h-6 text-slate-300" />
              </div>
              <h3 className="font-serif text-2xl font-medium text-white mb-3">
                The Digital Secretary.
              </h3>
              <p className="text-slate-300 leading-relaxed">
                Forward us your bills, RSVPs, and school emails. We triage the noise,
                handle the admin, and keep your inbox clean.
              </p>
            </div>

            {/* Feature C - Calendar (Small) */}
            <div className="md:col-span-1 bg-white rounded-2xl p-8 border border-slate-200">
              <div className="w-12 h-12 bg-emerald-100 rounded-xl flex items-center justify-center mb-6">
                <Calendar className="w-6 h-6 text-emerald-700" />
              </div>
              <h3 className="font-serif text-2xl font-medium text-emerald-950 mb-3">
                Unified Calendar.
              </h3>
              <p className="text-slate-600 leading-relaxed">
                Contractor visits, travel dates, and family events. All in one synced view.
              </p>
            </div>

            {/* Additional visual element */}
            <div className="md:col-span-2 bg-gradient-to-r from-emerald-800 to-emerald-900 rounded-2xl p-8 flex items-center justify-between border border-emerald-700/30">
              <div>
                <p className="text-emerald-200 text-sm font-medium uppercase tracking-wider mb-2">Your dedicated team</p>
                <p className="text-white text-2xl font-serif">One Manager. One Handyman. One Point of Contact.</p>
              </div>
              <div className="hidden sm:flex items-center gap-4">
                <div className="w-16 h-16 bg-white/10 rounded-full flex items-center justify-center">
                  <Users className="w-8 h-8 text-emerald-300" />
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Everything Else Grid */}
      <section className="py-24 px-4 sm:px-6 lg:px-8 bg-white">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="font-serif text-4xl sm:text-5xl font-medium text-emerald-950 mb-4">
              Complete Oversight. Nothing Missed.
            </h2>
            <p className="text-lg text-slate-600 max-w-2xl mx-auto">
              Every detail of household management, handled with care.
            </p>
          </div>

          <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
            {/* The Vault */}
            <div className="flex items-start gap-4 p-6 bg-slate-50 rounded-xl hover:shadow-md transition-shadow">
              <div className="w-12 h-12 bg-emerald-100 rounded-lg flex items-center justify-center flex-shrink-0">
                <Archive className="w-6 h-6 text-emerald-700" />
              </div>
              <div>
                <h3 className="font-medium text-emerald-950 mb-1">The Vault</h3>
                <p className="text-slate-600 text-sm leading-relaxed">
                  Digital inventory of appliances, warranties, and insurance policies.
                </p>
              </div>
            </div>

            {/* Fleet Management */}
            <div className="flex items-start gap-4 p-6 bg-slate-50 rounded-xl hover:shadow-md transition-shadow">
              <div className="w-12 h-12 bg-emerald-100 rounded-lg flex items-center justify-center flex-shrink-0">
                <Car className="w-6 h-6 text-emerald-700" />
              </div>
              <div>
                <h3 className="font-medium text-emerald-950 mb-1">Fleet Management</h3>
                <p className="text-slate-600 text-sm leading-relaxed">
                  Registration renewals and service scheduling for family vehicles.
                </p>
              </div>
            </div>

            {/* Pet Concierge */}
            <div className="flex items-start gap-4 p-6 bg-slate-50 rounded-xl hover:shadow-md transition-shadow">
              <div className="w-12 h-12 bg-emerald-100 rounded-lg flex items-center justify-center flex-shrink-0">
                <PawPrint className="w-6 h-6 text-emerald-700" />
              </div>
              <div>
                <h3 className="font-medium text-emerald-950 mb-1">Pet Concierge</h3>
                <p className="text-slate-600 text-sm leading-relaxed">
                  Vet record storage and sitter coordination.
                </p>
              </div>
            </div>

            {/* 24/7 Emergency */}
            <div className="flex items-start gap-4 p-6 bg-slate-50 rounded-xl hover:shadow-md transition-shadow">
              <div className="w-12 h-12 bg-emerald-100 rounded-lg flex items-center justify-center flex-shrink-0">
                <Phone className="w-6 h-6 text-emerald-700" />
              </div>
              <div>
                <h3 className="font-medium text-emerald-950 mb-1">24/7 Emergency</h3>
                <p className="text-slate-600 text-sm leading-relaxed">
                  A dedicated line for bursts, leaks, and lockouts.
                </p>
              </div>
            </div>

            {/* Vendor Vetting */}
            <div className="flex items-start gap-4 p-6 bg-slate-50 rounded-xl hover:shadow-md transition-shadow">
              <div className="w-12 h-12 bg-emerald-100 rounded-lg flex items-center justify-center flex-shrink-0">
                <UserCheck className="w-6 h-6 text-emerald-700" />
              </div>
              <div>
                <h3 className="font-medium text-emerald-950 mb-1">Vendor Vetting</h3>
                <p className="text-slate-600 text-sm leading-relaxed">
                  Licensed, insured, and background-checked pros only.
                </p>
              </div>
            </div>

            {/* Mail Management */}
            <div className="flex items-start gap-4 p-6 bg-slate-50 rounded-xl hover:shadow-md transition-shadow">
              <div className="w-12 h-12 bg-emerald-100 rounded-lg flex items-center justify-center flex-shrink-0">
                <Mail className="w-6 h-6 text-emerald-700" />
              </div>
              <div>
                <h3 className="font-medium text-emerald-950 mb-1">Mail Management</h3>
                <p className="text-slate-600 text-sm leading-relaxed">
                  We filter junk and digitize important documents.
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Community & Intelligence */}
      <section id="community" className="py-24 px-4 sm:px-6 lg:px-8 bg-slate-50">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="font-serif text-4xl sm:text-5xl font-medium text-emerald-950 mb-4">
              Powered by Your Neighborhood.
            </h2>
            <p className="text-lg text-slate-600 max-w-2xl mx-auto">
              Community intelligence that benefits every member.
            </p>
          </div>

          <div className="grid lg:grid-cols-2 gap-8">
            {/* Section A - Neighbor Network */}
            <div className="bg-white rounded-2xl p-8 sm:p-10 shadow-sm border border-slate-100">
              <div className="flex items-center gap-3 mb-6">
                <div className="w-12 h-12 bg-emerald-100 rounded-xl flex items-center justify-center">
                  <Users className="w-6 h-6 text-emerald-700" />
                </div>
                <span className="text-sm font-medium text-emerald-700 uppercase tracking-wider">Community</span>
              </div>
              <h3 className="font-serif text-3xl font-medium text-emerald-950 mb-4">
                Exclusive Neighbor Network.
              </h3>
              <p className="text-slate-600 text-lg leading-relaxed mb-8">
                See which vendors your neighbors trust. When multiple households on your street
                use the same landscaper or snow plow, everyone saves. We negotiate bulk rates
                for lawn care and pest control.
              </p>
              <div className="grid grid-cols-3 gap-4 pt-6 border-t border-slate-100">
                <div className="text-center">
                  <p className="text-3xl font-bold text-emerald-950">30%</p>
                  <p className="text-sm text-slate-500">Avg Savings</p>
                </div>
                <div className="text-center">
                  <p className="text-3xl font-bold text-emerald-950">500+</p>
                  <p className="text-sm text-slate-500">Verified Vendors</p>
                </div>
                <div className="text-center">
                  <p className="text-3xl font-bold text-emerald-950">4.8</p>
                  <p className="text-sm text-slate-500">Avg Rating</p>
                </div>
              </div>
            </div>

            {/* Section B - Dream Board */}
            <div className="bg-gradient-to-br from-emerald-950 to-emerald-900 rounded-2xl p-8 sm:p-10 text-white">
              <div className="flex items-center gap-3 mb-6">
                <div className="w-12 h-12 bg-white/10 rounded-xl flex items-center justify-center">
                  <Sparkles className="w-6 h-6 text-emerald-300" />
                </div>
                <span className="text-sm font-medium text-emerald-300 uppercase tracking-wider">Planning</span>
              </div>
              <h3 className="font-serif text-3xl font-medium mb-4">
                The Dream Board.
              </h3>
              <p className="text-emerald-100 text-lg leading-relaxed mb-8">
                Capture inspiration for future projects. Your Manager provides estimates
                and recommendations when you are ready to move forward.
              </p>
              <div className="space-y-3">
                <div className="flex items-center gap-3 text-emerald-200">
                  <Check className="w-5 h-5 text-emerald-400" />
                  <span>Save photos and ideas from anywhere</span>
                </div>
                <div className="flex items-center gap-3 text-emerald-200">
                  <Check className="w-5 h-5 text-emerald-400" />
                  <span>Get realistic cost estimates</span>
                </div>
                <div className="flex items-center gap-3 text-emerald-200">
                  <Check className="w-5 h-5 text-emerald-400" />
                  <span>Move to active project when ready</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Pricing Section */}
      <section id="pricing" className="py-24 px-4 sm:px-6 lg:px-8 bg-white">
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
            <div className="bg-slate-50 rounded-2xl p-8 border border-slate-200">
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
            <div className="bg-slate-50 rounded-2xl p-8 border border-slate-200">
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
      <footer className="py-16 px-4 sm:px-6 lg:px-8 bg-emerald-950">
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
                <li><a href="#features" className="text-emerald-300 hover:text-white text-sm transition-colors">Features</a></li>
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
    </div>
  );
}
