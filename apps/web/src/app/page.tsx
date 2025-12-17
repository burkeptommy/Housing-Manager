import Link from 'next/link';

export default function LandingPage() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-blue-50 dark:from-slate-900 dark:to-slate-800">
      {/* Navigation */}
      <nav className="flex items-center justify-between px-6 py-4 max-w-7xl mx-auto">
        <div className="flex items-center gap-2">
          <div className="w-10 h-10 rounded-xl bg-blue-600 flex items-center justify-center">
            <svg
              className="w-6 h-6 text-white"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"
              />
            </svg>
          </div>
          <span className="text-xl font-bold text-slate-900 dark:text-white">Haven</span>
        </div>
        <div className="flex items-center gap-4">
          <Link
            href="/login"
            className="text-slate-600 hover:text-slate-900 dark:text-slate-300 dark:hover:text-white font-medium"
          >
            Sign in
          </Link>
          <Link
            href="/register"
            className="btn btn-primary"
          >
            Get Started
          </Link>
        </div>
      </nav>

      {/* Hero Section */}
      <main className="max-w-7xl mx-auto px-6 pt-20 pb-16">
        <div className="text-center max-w-4xl mx-auto">
          <div className="inline-flex items-center gap-2 bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300 px-4 py-2 rounded-full text-sm font-medium mb-6">
            <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
            </svg>
            Trusted by 500+ homeowners
          </div>
          <h1 className="text-5xl md:text-6xl font-bold text-slate-900 dark:text-white leading-tight mb-6">
            Your home,
            <span className="text-blue-600"> professionally managed</span>
          </h1>
          <p className="text-xl md:text-2xl text-slate-600 dark:text-slate-300 mb-12 max-w-2xl mx-auto">
            Stop juggling vendors, bills, and maintenance schedules. Haven is your personal
            home operations center—keeping everything running smoothly so you can focus on living.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Link
              href="/login"
              className="btn btn-primary text-lg px-8 py-3"
            >
              Try the Demo
            </Link>
            <Link
              href="/register"
              className="btn btn-outline text-lg px-8 py-3"
            >
              Create Free Account
            </Link>
          </div>
          <p className="text-sm text-slate-500 dark:text-slate-400 mt-4">
            Demo login: sarah@demo.haven.local / demo123
          </p>
        </div>

        {/* Stats Bar */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-6 mt-20 max-w-4xl mx-auto">
          <div className="text-center">
            <div className="text-3xl font-bold text-blue-600">$2,400</div>
            <div className="text-slate-600 dark:text-slate-400 text-sm">Avg. saved per year</div>
          </div>
          <div className="text-center">
            <div className="text-3xl font-bold text-blue-600">8 hrs</div>
            <div className="text-slate-600 dark:text-slate-400 text-sm">Monthly time saved</div>
          </div>
          <div className="text-center">
            <div className="text-3xl font-bold text-blue-600">100%</div>
            <div className="text-slate-600 dark:text-slate-400 text-sm">Tasks on schedule</div>
          </div>
          <div className="text-center">
            <div className="text-3xl font-bold text-blue-600">24/7</div>
            <div className="text-slate-600 dark:text-slate-400 text-sm">Support available</div>
          </div>
        </div>

        {/* Feature Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mt-24">
          <div className="card text-center hover:shadow-lg transition-shadow">
            <div className="w-12 h-12 rounded-xl bg-green-100 dark:bg-green-900/30 flex items-center justify-center mx-auto mb-4">
              <svg className="w-6 h-6 text-green-600 dark:text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />
              </svg>
            </div>
            <h3 className="text-lg font-semibold text-slate-900 dark:text-white mb-2">
              Smart Maintenance Calendar
            </h3>
            <p className="text-slate-600 dark:text-slate-400">
              Never miss an HVAC tune-up, gutter cleaning, or seasonal task again.
              AI-powered scheduling based on your home&apos;s specific needs.
            </p>
          </div>

          <div className="card text-center hover:shadow-lg transition-shadow">
            <div className="w-12 h-12 rounded-xl bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center mx-auto mb-4">
              <svg className="w-6 h-6 text-blue-600 dark:text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z" />
              </svg>
            </div>
            <h3 className="text-lg font-semibold text-slate-900 dark:text-white mb-2">
              Bill Management & Tracking
            </h3>
            <p className="text-slate-600 dark:text-slate-400">
              Track utilities, mortgages, and service bills in one place.
              Get reminders before due dates and avoid late fees forever.
            </p>
          </div>

          <div className="card text-center hover:shadow-lg transition-shadow">
            <div className="w-12 h-12 rounded-xl bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center mx-auto mb-4">
              <svg className="w-6 h-6 text-purple-600 dark:text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
              </svg>
            </div>
            <h3 className="text-lg font-semibold text-slate-900 dark:text-white mb-2">
              Trusted Vendor Network
            </h3>
            <p className="text-slate-600 dark:text-slate-400">
              Access pre-vetted service providers or add your own.
              Plumbers, electricians, landscapers—always at your fingertips.
            </p>
          </div>
        </div>

        {/* Why Haven Section */}
        <div className="mt-32">
          <div className="text-center mb-16">
            <h2 className="text-3xl font-bold text-slate-900 dark:text-white mb-4">
              Why homeowners choose Haven
            </h2>
            <p className="text-xl text-slate-600 dark:text-slate-400 max-w-2xl mx-auto">
              Managing a home is a full-time job. Let us handle the operational details while you enjoy your space.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
            <div className="flex gap-4 items-start">
              <div className="flex-shrink-0 w-10 h-10 rounded-lg bg-amber-100 dark:bg-amber-900/30 flex items-center justify-center">
                <svg className="w-5 h-5 text-amber-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
              <div>
                <h3 className="font-semibold text-slate-900 dark:text-white mb-1">Save 8+ hours every month</h3>
                <p className="text-slate-600 dark:text-slate-400">No more endless phone calls, scheduling conflicts, or forgotten tasks. We coordinate everything for you.</p>
              </div>
            </div>

            <div className="flex gap-4 items-start">
              <div className="flex-shrink-0 w-10 h-10 rounded-lg bg-green-100 dark:bg-green-900/30 flex items-center justify-center">
                <svg className="w-5 h-5 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
              <div>
                <h3 className="font-semibold text-slate-900 dark:text-white mb-1">Prevent costly emergencies</h3>
                <p className="text-slate-600 dark:text-slate-400">Regular maintenance prevents expensive repairs. Our proactive approach saves you $2,400+ annually on average.</p>
              </div>
            </div>

            <div className="flex gap-4 items-start">
              <div className="flex-shrink-0 w-10 h-10 rounded-lg bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center">
                <svg className="w-5 h-5 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                </svg>
              </div>
              <div>
                <h3 className="font-semibold text-slate-900 dark:text-white mb-1">Vetted, insured professionals</h3>
                <p className="text-slate-600 dark:text-slate-400">Every vendor in our network is background-checked, licensed, and insured. Your home is in safe hands.</p>
              </div>
            </div>

            <div className="flex gap-4 items-start">
              <div className="flex-shrink-0 w-10 h-10 rounded-lg bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center">
                <svg className="w-5 h-5 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
                </svg>
              </div>
              <div>
                <h3 className="font-semibold text-slate-900 dark:text-white mb-1">Personal home manager</h3>
                <p className="text-slate-600 dark:text-slate-400">Chat directly with your dedicated home manager. Questions, requests, or emergencies—we&apos;re here 24/7.</p>
              </div>
            </div>
          </div>
        </div>

        {/* How it Works */}
        <div className="mt-32 text-center">
          <h2 className="text-3xl font-bold text-slate-900 dark:text-white mb-4">
            Get started in 3 simple steps
          </h2>
          <p className="text-xl text-slate-600 dark:text-slate-400 max-w-2xl mx-auto mb-12">
            Setting up takes less than 10 minutes. Your home manager will handle the rest.
          </p>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            <div className="relative">
              <div className="w-12 h-12 rounded-full bg-blue-600 text-white font-bold flex items-center justify-center mx-auto mb-4 text-xl">
                1
              </div>
              <h3 className="font-semibold text-slate-900 dark:text-white mb-2">
                Create your home profile
              </h3>
              <p className="text-slate-600 dark:text-slate-400">
                Tell us about your property—size, age, features like pools, HVAC systems, or septic tanks.
              </p>
            </div>
            <div className="relative">
              <div className="w-12 h-12 rounded-full bg-blue-600 text-white font-bold flex items-center justify-center mx-auto mb-4 text-xl">
                2
              </div>
              <h3 className="font-semibold text-slate-900 dark:text-white mb-2">
                Add your bills & vendors
              </h3>
              <p className="text-slate-600 dark:text-slate-400">
                Import your service providers and recurring bills. We&apos;ll create a personalized maintenance plan.
              </p>
            </div>
            <div className="relative">
              <div className="w-12 h-12 rounded-full bg-blue-600 text-white font-bold flex items-center justify-center mx-auto mb-4 text-xl">
                3
              </div>
              <h3 className="font-semibold text-slate-900 dark:text-white mb-2">
                Sit back and relax
              </h3>
              <p className="text-slate-600 dark:text-slate-400">
                Get reminders, request services, track work orders, and chat with your home manager anytime.
              </p>
            </div>
          </div>
        </div>

        {/* Pricing Section */}
        <div className="mt-32">
          <div className="text-center mb-16">
            <h2 className="text-3xl font-bold text-slate-900 dark:text-white mb-4">
              Simple, transparent pricing
            </h2>
            <p className="text-xl text-slate-600 dark:text-slate-400 max-w-2xl mx-auto">
              Choose the plan that fits your needs. Upgrade or downgrade anytime.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 max-w-5xl mx-auto">
            {/* Basic Plan */}
            <div className="card border-2 border-slate-200 dark:border-slate-700">
              <div className="text-center mb-6">
                <h3 className="text-lg font-semibold text-slate-900 dark:text-white">Basic</h3>
                <div className="mt-2">
                  <span className="text-4xl font-bold text-slate-900 dark:text-white">Free</span>
                </div>
                <p className="text-slate-500 dark:text-slate-400 text-sm mt-2">Perfect for getting started</p>
              </div>
              <ul className="space-y-3 mb-8">
                <li className="flex items-center gap-2 text-slate-600 dark:text-slate-400">
                  <svg className="w-5 h-5 text-green-500" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                  </svg>
                  Home profile & maintenance calendar
                </li>
                <li className="flex items-center gap-2 text-slate-600 dark:text-slate-400">
                  <svg className="w-5 h-5 text-green-500" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                  </svg>
                  Track up to 5 bills
                </li>
                <li className="flex items-center gap-2 text-slate-600 dark:text-slate-400">
                  <svg className="w-5 h-5 text-green-500" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                  </svg>
                  Email reminders
                </li>
              </ul>
              <Link href="/register" className="btn btn-outline w-full">Get Started Free</Link>
            </div>

            {/* Pro Plan */}
            <div className="card border-2 border-blue-500 relative">
              <div className="absolute -top-3 left-1/2 -translate-x-1/2 bg-blue-600 text-white text-sm px-3 py-1 rounded-full font-medium">
                Most Popular
              </div>
              <div className="text-center mb-6">
                <h3 className="text-lg font-semibold text-slate-900 dark:text-white">Pro</h3>
                <div className="mt-2">
                  <span className="text-4xl font-bold text-slate-900 dark:text-white">$29</span>
                  <span className="text-slate-500 dark:text-slate-400">/month</span>
                </div>
                <p className="text-slate-500 dark:text-slate-400 text-sm mt-2">Full home management</p>
              </div>
              <ul className="space-y-3 mb-8">
                <li className="flex items-center gap-2 text-slate-600 dark:text-slate-400">
                  <svg className="w-5 h-5 text-green-500" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                  </svg>
                  Everything in Basic
                </li>
                <li className="flex items-center gap-2 text-slate-600 dark:text-slate-400">
                  <svg className="w-5 h-5 text-green-500" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                  </svg>
                  Unlimited bills & vendors
                </li>
                <li className="flex items-center gap-2 text-slate-600 dark:text-slate-400">
                  <svg className="w-5 h-5 text-green-500" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                  </svg>
                  Work order management
                </li>
                <li className="flex items-center gap-2 text-slate-600 dark:text-slate-400">
                  <svg className="w-5 h-5 text-green-500" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                  </svg>
                  Chat support (business hours)
                </li>
              </ul>
              <Link href="/register" className="btn btn-primary w-full">Start 14-Day Trial</Link>
            </div>

            {/* Premium Plan */}
            <div className="card border-2 border-slate-200 dark:border-slate-700">
              <div className="text-center mb-6">
                <h3 className="text-lg font-semibold text-slate-900 dark:text-white">Premium</h3>
                <div className="mt-2">
                  <span className="text-4xl font-bold text-slate-900 dark:text-white">$99</span>
                  <span className="text-slate-500 dark:text-slate-400">/month</span>
                </div>
                <p className="text-slate-500 dark:text-slate-400 text-sm mt-2">White-glove service</p>
              </div>
              <ul className="space-y-3 mb-8">
                <li className="flex items-center gap-2 text-slate-600 dark:text-slate-400">
                  <svg className="w-5 h-5 text-green-500" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                  </svg>
                  Everything in Pro
                </li>
                <li className="flex items-center gap-2 text-slate-600 dark:text-slate-400">
                  <svg className="w-5 h-5 text-green-500" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                  </svg>
                  Dedicated home manager
                </li>
                <li className="flex items-center gap-2 text-slate-600 dark:text-slate-400">
                  <svg className="w-5 h-5 text-green-500" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                  </svg>
                  24/7 priority support
                </li>
                <li className="flex items-center gap-2 text-slate-600 dark:text-slate-400">
                  <svg className="w-5 h-5 text-green-500" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                  </svg>
                  Bill pay on your behalf
                </li>
              </ul>
              <Link href="/register" className="btn btn-outline w-full">Contact Sales</Link>
            </div>
          </div>
        </div>

        {/* CTA Section */}
        <div className="mt-32 text-center bg-gradient-to-r from-blue-600 to-blue-700 rounded-2xl p-12">
          <h2 className="text-3xl font-bold text-white mb-4">
            Ready to simplify home ownership?
          </h2>
          <p className="text-xl text-blue-100 max-w-2xl mx-auto mb-8">
            Join thousands of homeowners who&apos;ve reclaimed their weekends. Start your free trial today.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Link
              href="/register"
              className="bg-white text-blue-600 hover:bg-blue-50 font-semibold px-8 py-3 rounded-lg transition-colors"
            >
              Get Started Free
            </Link>
            <Link
              href="/login"
              className="bg-transparent text-white border-2 border-white hover:bg-white/10 font-semibold px-8 py-3 rounded-lg transition-colors"
            >
              Try the Demo
            </Link>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="border-t border-slate-200 dark:border-slate-700 py-12 mt-20">
        <div className="max-w-7xl mx-auto px-6">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-8 mb-8">
            <div>
              <div className="flex items-center gap-2 mb-4">
                <div className="w-8 h-8 rounded-lg bg-blue-600 flex items-center justify-center">
                  <svg className="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
                  </svg>
                </div>
                <span className="font-bold text-slate-900 dark:text-white">Haven</span>
              </div>
              <p className="text-sm text-slate-500 dark:text-slate-400">
                Professional home management for modern homeowners.
              </p>
            </div>
            <div>
              <h4 className="font-semibold text-slate-900 dark:text-white mb-4">Product</h4>
              <ul className="space-y-2 text-sm text-slate-500 dark:text-slate-400">
                <li><a href="#" className="hover:text-slate-900 dark:hover:text-white">Features</a></li>
                <li><a href="#" className="hover:text-slate-900 dark:hover:text-white">Pricing</a></li>
                <li><a href="#" className="hover:text-slate-900 dark:hover:text-white">Security</a></li>
              </ul>
            </div>
            <div>
              <h4 className="font-semibold text-slate-900 dark:text-white mb-4">Company</h4>
              <ul className="space-y-2 text-sm text-slate-500 dark:text-slate-400">
                <li><a href="#" className="hover:text-slate-900 dark:hover:text-white">About</a></li>
                <li><a href="#" className="hover:text-slate-900 dark:hover:text-white">Blog</a></li>
                <li><a href="#" className="hover:text-slate-900 dark:hover:text-white">Careers</a></li>
              </ul>
            </div>
            <div>
              <h4 className="font-semibold text-slate-900 dark:text-white mb-4">Legal</h4>
              <ul className="space-y-2 text-sm text-slate-500 dark:text-slate-400">
                <li><a href="#" className="hover:text-slate-900 dark:hover:text-white">Privacy</a></li>
                <li><a href="#" className="hover:text-slate-900 dark:hover:text-white">Terms</a></li>
                <li><a href="#" className="hover:text-slate-900 dark:hover:text-white">Contact</a></li>
              </ul>
            </div>
          </div>
          <div className="border-t border-slate-200 dark:border-slate-700 pt-8 text-center text-slate-500 dark:text-slate-400 text-sm">
            <p>&copy; {new Date().getFullYear()} Haven Home Manager. All rights reserved.</p>
          </div>
        </div>
      </footer>
    </div>
  );
}
