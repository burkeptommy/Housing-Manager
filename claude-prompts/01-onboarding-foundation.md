# Claude Code Prompt: Onboarding Foundation & Routing

## Context

You are implementing the onboarding experience for Haven, a full-service home management platform. Haven provides dedicated Home Managers who handle homeownership tasks - paying bills, coordinating vendors, scheduling maintenance.

**Project Location:** `/Users/tomburke/Projects/Housing-Manager/`
**Tech Stack:** Next.js 15 (App Router), React 18, Tailwind CSS, TypeScript
**Web App Location:** `apps/web/src/`

## Critical Design Requirements

**Brand Colors (MUST USE):**
- Navy-950: #0a1929 (dark backgrounds)
- Navy-900: #102a43 (primary buttons, headings)
- Navy-800: #243b53 (secondary elements)
- Champagne-500: #c4a574 (accent color, CTAs)
- Champagne-100: #faf6ed (subtle backgrounds)
- NO BRIGHT GREEN - this is deprecated

**Tailwind Classes:**
- `bg-haven-navy-950`, `bg-haven-navy-900`, `text-haven-navy-900`
- `bg-haven-champagne-500`, `text-haven-champagne-500`
- These should already be configured in `apps/web/tailwind.config.ts`

## Task: Create Onboarding Route Structure & Shell

### Step 1: Create the Onboarding Directory Structure

Create the following file structure under `apps/web/src/app/onboarding/`:

```
apps/web/src/app/onboarding/
├── layout.tsx                      # OnboardingShell layout
├── page.tsx                        # Entry point (redirects based on state)
├── welcome/
│   └── page.tsx                    # Account creation / sign-up
├── choose-path/
│   └── page.tsx                    # Choose: Self-serve, Call, or Visit
├── schedule/
│   ├── page.tsx                    # Calendly embed for scheduling
│   └── confirmation/
│       └── page.tsx                # Booking confirmation
├── wizard/
│   ├── layout.tsx                  # Wizard-specific layout with step indicator
│   ├── page.tsx                    # Wizard entry (redirects to first incomplete step)
│   ├── property/
│   │   └── page.tsx                # Step 1: Property details
│   ├── bills/
│   │   └── page.tsx                # Step 2: Bills & accounts
│   ├── systems/
│   │   └── page.tsx                # Step 3: Home systems
│   ├── family/
│   │   └── page.tsx                # Step 4: Family & household
│   └── review/
│       └── page.tsx                # Step 5: Review everything
├── activation/
│   └── page.tsx                    # Schedule activation call with Home Manager
└── complete/
    └── page.tsx                    # Welcome to Haven!
```

### Step 2: Create Onboarding Components Directory

Create the following under `apps/web/src/components/onboarding/`:

```
apps/web/src/components/onboarding/
├── OnboardingShell.tsx             # Main layout wrapper
├── OnboardingHeader.tsx            # Logo + minimal header
├── ProgressStepper.tsx             # Visual progress indicator
├── HelpFloatingButton.tsx          # Persistent "Need help?" button
├── HelpModal.tsx                   # Modal with call/visit/chat options
├── PathCard.tsx                    # Card component for path selection
├── ServiceAreaChecker.tsx          # ZIP code validation component
├── SkipToHumanBanner.tsx          # "Let us handle this" persistent banner
└── index.ts                        # Barrel export
```

### Step 3: Implement OnboardingShell (layout.tsx)

The `OnboardingShell` should:

1. **Header:** Minimal - just the Haven logo (no full navigation)
2. **Progress Indicator:** Shows current step in the journey
3. **Help Button:** Floating button in bottom-right corner
4. **Clean Background:** Light gray or white, professional feel

```tsx
// apps/web/src/app/onboarding/layout.tsx

import { OnboardingHeader } from '@/components/onboarding/OnboardingHeader';
import { HelpFloatingButton } from '@/components/onboarding/HelpFloatingButton';

export default function OnboardingLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="min-h-screen bg-gray-50">
      <OnboardingHeader />
      <main className="pb-24">
        {children}
      </main>
      <HelpFloatingButton />
    </div>
  );
}
```

### Step 4: Implement OnboardingHeader Component

Simple, clean header with just the Haven logo. Include a "Questions about pricing?" link that opens a tier comparison modal.

```tsx
// apps/web/src/components/onboarding/OnboardingHeader.tsx

'use client';

import Link from 'next/link';
import { useState } from 'react';
import { TierComparisonModal } from './TierComparisonModal'; // We'll create this later

export function OnboardingHeader() {
  const [showTierModal, setShowTierModal] = useState(false);

  return (
    <>
      <header className="bg-white border-b border-gray-200">
        <div className="max-w-4xl mx-auto px-4 py-4 flex items-center justify-between">
          {/* Haven Logo */}
          <Link href="/" className="flex items-center gap-2">
            <div className="w-8 h-8 bg-haven-navy-900 rounded-lg flex items-center justify-center">
              <span className="text-white font-bold text-sm">H</span>
            </div>
            <span className="text-xl font-semibold text-haven-navy-900">Haven</span>
          </Link>

          {/* Pricing Link */}
          <button
            onClick={() => setShowTierModal(true)}
            className="text-sm text-gray-500 hover:text-haven-navy-900 transition-colors"
          >
            Questions about plans?
          </button>
        </div>
      </header>

      {/* Tier Modal - implement later */}
      {showTierModal && (
        <TierComparisonModal onClose={() => setShowTierModal(false)} />
      )}
    </>
  );
}
```

### Step 5: Implement HelpFloatingButton Component

This is CRITICAL - it must appear on every onboarding page. It provides an escape hatch to human help at any time.

```tsx
// apps/web/src/components/onboarding/HelpFloatingButton.tsx

'use client';

import { useState } from 'react';
import { MessageCircle, Phone, Calendar, X, Home } from 'lucide-react';

export function HelpFloatingButton() {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <>
      {/* Floating Button */}
      <button
        onClick={() => setIsOpen(true)}
        className="fixed bottom-6 right-6 bg-haven-champagne-500 hover:bg-haven-champagne-600 text-haven-navy-900 rounded-full p-4 shadow-lg transition-all hover:scale-105 z-40"
        aria-label="Get help"
      >
        <MessageCircle className="w-6 h-6" />
      </button>

      {/* Help Modal */}
      {isOpen && (
        <div className="fixed inset-0 bg-black/50 flex items-end sm:items-center justify-center z-50 p-4">
          <div className="bg-white rounded-t-2xl sm:rounded-2xl w-full max-w-md overflow-hidden">
            {/* Header */}
            <div className="bg-haven-navy-900 text-white p-6">
              <div className="flex items-center justify-between mb-2">
                <h2 className="text-xl font-semibold">Need help?</h2>
                <button
                  onClick={() => setIsOpen(false)}
                  className="text-white/70 hover:text-white"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>
              <p className="text-white/80 text-sm">
                We're here to help you get set up. Choose an option below.
              </p>
            </div>

            {/* Options */}
            <div className="p-4 space-y-3">
              {/* Schedule a Call */}
              <a
                href="/onboarding/schedule?type=call"
                className="flex items-center gap-4 p-4 rounded-xl border border-gray-200 hover:border-haven-champagne-500 hover:bg-haven-champagne-50 transition-all group"
              >
                <div className="w-12 h-12 rounded-full bg-haven-navy-100 flex items-center justify-center group-hover:bg-haven-champagne-100">
                  <Phone className="w-5 h-5 text-haven-navy-900" />
                </div>
                <div>
                  <div className="font-medium text-haven-navy-900">Schedule a call</div>
                  <div className="text-sm text-gray-500">30-min video or phone call</div>
                </div>
              </a>

              {/* Schedule a Home Visit */}
              <a
                href="/onboarding/schedule?type=visit"
                className="flex items-center gap-4 p-4 rounded-xl border border-gray-200 hover:border-haven-champagne-500 hover:bg-haven-champagne-50 transition-all group"
              >
                <div className="w-12 h-12 rounded-full bg-haven-navy-100 flex items-center justify-center group-hover:bg-haven-champagne-100">
                  <Home className="w-5 h-5 text-haven-navy-900" />
                </div>
                <div>
                  <div className="font-medium text-haven-navy-900">Schedule a home visit</div>
                  <div className="text-sm text-gray-500">We come to you (free)</div>
                </div>
              </a>

              {/* Call Now */}
              <a
                href="tel:+12035550100"
                className="flex items-center gap-4 p-4 rounded-xl border border-gray-200 hover:border-haven-champagne-500 hover:bg-haven-champagne-50 transition-all group"
              >
                <div className="w-12 h-12 rounded-full bg-haven-navy-100 flex items-center justify-center group-hover:bg-haven-champagne-100">
                  <Phone className="w-5 h-5 text-haven-navy-900" />
                </div>
                <div>
                  <div className="font-medium text-haven-navy-900">Call us now</div>
                  <div className="text-sm text-gray-500">(203) 555-0100</div>
                </div>
              </a>
            </div>

            {/* Footer */}
            <div className="px-4 pb-4">
              <p className="text-xs text-center text-gray-400">
                Available Monday-Friday, 9am-6pm ET
              </p>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
```

### Step 6: Implement ProgressStepper Component

Shows the user where they are in the onboarding journey.

```tsx
// apps/web/src/components/onboarding/ProgressStepper.tsx

'use client';

import { Check } from 'lucide-react';
import { cn } from '@/lib/utils'; // or your utility function location

interface Step {
  id: string;
  label: string;
  href: string;
}

interface ProgressStepperProps {
  steps: Step[];
  currentStep: string;
  completedSteps: string[];
}

export function ProgressStepper({ steps, currentStep, completedSteps }: ProgressStepperProps) {
  return (
    <div className="w-full max-w-2xl mx-auto px-4 py-6">
      <div className="flex items-center justify-between">
        {steps.map((step, index) => {
          const isCompleted = completedSteps.includes(step.id);
          const isCurrent = step.id === currentStep;
          const isPast = completedSteps.includes(step.id);

          return (
            <div key={step.id} className="flex items-center flex-1 last:flex-none">
              {/* Step Circle */}
              <div className="flex flex-col items-center">
                <div
                  className={cn(
                    'w-10 h-10 rounded-full flex items-center justify-center text-sm font-medium transition-all',
                    isCompleted && 'bg-haven-navy-900 text-white',
                    isCurrent && !isCompleted && 'bg-haven-champagne-500 text-haven-navy-900 ring-4 ring-haven-champagne-200',
                    !isCurrent && !isCompleted && 'bg-gray-200 text-gray-500'
                  )}
                >
                  {isCompleted ? (
                    <Check className="w-5 h-5" />
                  ) : (
                    index + 1
                  )}
                </div>
                <span
                  className={cn(
                    'mt-2 text-xs font-medium hidden sm:block',
                    isCurrent ? 'text-haven-navy-900' : 'text-gray-500'
                  )}
                >
                  {step.label}
                </span>
              </div>

              {/* Connector Line */}
              {index < steps.length - 1 && (
                <div
                  className={cn(
                    'flex-1 h-1 mx-2',
                    isPast ? 'bg-haven-navy-900' : 'bg-gray-200'
                  )}
                />
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}
```

### Step 7: Create Placeholder Pages

Create placeholder pages for each route. Each should have basic structure that we'll fill in during later phases.

**Entry Point (`apps/web/src/app/onboarding/page.tsx`):**

```tsx
// apps/web/src/app/onboarding/page.tsx

import { redirect } from 'next/navigation';

export default function OnboardingPage() {
  // TODO: Check if user is authenticated
  // TODO: Check onboarding status from database
  // TODO: Redirect to appropriate step

  // For now, redirect to welcome
  redirect('/onboarding/welcome');
}
```

**Welcome Page (`apps/web/src/app/onboarding/welcome/page.tsx`):**

```tsx
// apps/web/src/app/onboarding/welcome/page.tsx

'use client';

import Link from 'next/link';
import { ArrowRight } from 'lucide-react';

export default function OnboardingWelcomePage() {
  return (
    <div className="min-h-[calc(100vh-80px)] flex items-center justify-center px-4">
      <div className="max-w-md w-full">
        {/* Welcome Message */}
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold text-haven-navy-900 mb-3">
            Welcome to Haven
          </h1>
          <p className="text-gray-600">
            Stop managing your home. Start living in it.
          </p>
        </div>

        {/* Sign Up Form Placeholder */}
        <div className="bg-white rounded-2xl shadow-sm border border-gray-200 p-6 space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Email
            </label>
            <input
              type="email"
              className="w-full px-4 py-3 rounded-xl border border-gray-300 focus:border-haven-champagne-500 focus:ring-2 focus:ring-haven-champagne-200 outline-none transition-all"
              placeholder="you@example.com"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Password
            </label>
            <input
              type="password"
              className="w-full px-4 py-3 rounded-xl border border-gray-300 focus:border-haven-champagne-500 focus:ring-2 focus:ring-haven-champagne-200 outline-none transition-all"
              placeholder="••••••••"
            />
          </div>

          <Link
            href="/onboarding/choose-path"
            className="w-full bg-haven-navy-900 hover:bg-haven-navy-800 text-white py-3 px-4 rounded-xl font-medium flex items-center justify-center gap-2 transition-colors"
          >
            Continue
            <ArrowRight className="w-4 h-4" />
          </Link>

          <div className="relative my-4">
            <div className="absolute inset-0 flex items-center">
              <div className="w-full border-t border-gray-200" />
            </div>
            <div className="relative flex justify-center text-sm">
              <span className="px-2 bg-white text-gray-500">or continue with</span>
            </div>
          </div>

          <button className="w-full border border-gray-300 hover:bg-gray-50 py-3 px-4 rounded-xl font-medium flex items-center justify-center gap-2 transition-colors">
            <svg className="w-5 h-5" viewBox="0 0 24 24">
              <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
              <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
              <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
              <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
            </svg>
            Continue with Google
          </button>
        </div>

        {/* Already have account */}
        <p className="text-center text-sm text-gray-500 mt-6">
          Already have an account?{' '}
          <Link href="/login" className="text-haven-navy-900 hover:underline font-medium">
            Sign in
          </Link>
        </p>
      </div>
    </div>
  );
}
```

**Choose Path Page (`apps/web/src/app/onboarding/choose-path/page.tsx`):**

```tsx
// apps/web/src/app/onboarding/choose-path/page.tsx

'use client';

import Link from 'next/link';
import { Smartphone, Phone, Home, ArrowRight, Star } from 'lucide-react';
import { cn } from '@/lib/utils';
import { useState } from 'react';

type PathOption = 'self' | 'call' | 'visit';

export default function ChoosePathPage() {
  const [selectedPath, setSelectedPath] = useState<PathOption | null>(null);
  
  // TODO: Get tier from user context/URL params
  // Higher tiers default to 'visit'
  const tier = 'haven'; // placeholder

  const paths = [
    {
      id: 'self' as PathOption,
      icon: Smartphone,
      title: 'On my own',
      description: "I'll enter my information digitally",
      time: '~30-45 minutes',
      href: '/onboarding/wizard',
    },
    {
      id: 'call' as PathOption,
      icon: Phone,
      title: 'Guided call',
      description: 'Walk through setup on a video call',
      time: '~45 minutes',
      href: '/onboarding/schedule?type=call',
    },
    {
      id: 'visit' as PathOption,
      icon: Home,
      title: 'Home visit',
      description: 'Our handyman comes to document everything',
      time: '~90 minutes',
      href: '/onboarding/schedule?type=visit',
      recommended: ['haven', 'haven_plus', 'estate'].includes(tier),
    },
  ];

  return (
    <div className="min-h-[calc(100vh-80px)] flex items-center justify-center px-4 py-12">
      <div className="max-w-2xl w-full">
        {/* Header */}
        <div className="text-center mb-10">
          <h1 className="text-3xl font-bold text-haven-navy-900 mb-3">
            How would you like to get started?
          </h1>
          <p className="text-gray-600 max-w-md mx-auto">
            Choose the option that works best for you. You can always switch to another method or get help at any time.
          </p>
        </div>

        {/* Path Options */}
        <div className="space-y-4 mb-8">
          {paths.map((path) => (
            <button
              key={path.id}
              onClick={() => setSelectedPath(path.id)}
              className={cn(
                'w-full p-6 rounded-2xl border-2 text-left transition-all relative',
                selectedPath === path.id
                  ? 'border-haven-champagne-500 bg-haven-champagne-50'
                  : 'border-gray-200 bg-white hover:border-gray-300'
              )}
            >
              {/* Recommended Badge */}
              {path.recommended && (
                <div className="absolute -top-3 left-6 bg-haven-champagne-500 text-haven-navy-900 text-xs font-semibold px-3 py-1 rounded-full flex items-center gap-1">
                  <Star className="w-3 h-3" />
                  Recommended
                </div>
              )}

              <div className="flex items-start gap-4">
                <div className={cn(
                  'w-12 h-12 rounded-xl flex items-center justify-center flex-shrink-0',
                  selectedPath === path.id
                    ? 'bg-haven-champagne-500 text-haven-navy-900'
                    : 'bg-gray-100 text-gray-600'
                )}>
                  <path.icon className="w-6 h-6" />
                </div>

                <div className="flex-1">
                  <div className="flex items-center gap-2">
                    <h3 className="text-lg font-semibold text-haven-navy-900">
                      {path.title}
                    </h3>
                  </div>
                  <p className="text-gray-600 mt-1">
                    {path.description}
                  </p>
                  <p className="text-sm text-gray-400 mt-2">
                    {path.time}
                  </p>
                </div>

                {/* Selection Indicator */}
                <div className={cn(
                  'w-6 h-6 rounded-full border-2 flex items-center justify-center flex-shrink-0',
                  selectedPath === path.id
                    ? 'border-haven-champagne-500 bg-haven-champagne-500'
                    : 'border-gray-300'
                )}>
                  {selectedPath === path.id && (
                    <div className="w-2 h-2 bg-white rounded-full" />
                  )}
                </div>
              </div>
            </button>
          ))}
        </div>

        {/* Continue Button */}
        <Link
          href={selectedPath ? paths.find(p => p.id === selectedPath)?.href || '#' : '#'}
          className={cn(
            'w-full py-4 px-6 rounded-xl font-medium flex items-center justify-center gap-2 transition-all',
            selectedPath
              ? 'bg-haven-navy-900 hover:bg-haven-navy-800 text-white'
              : 'bg-gray-200 text-gray-400 cursor-not-allowed'
          )}
          onClick={(e) => !selectedPath && e.preventDefault()}
        >
          Continue
          <ArrowRight className="w-4 h-4" />
        </Link>

        {/* Note about free help */}
        <p className="text-center text-sm text-gray-500 mt-6">
          All options include free support. Home visits are free for all tiers.
        </p>
      </div>
    </div>
  );
}
```

**Placeholder Pages for Remaining Routes:**

Create these simple placeholder files:

```tsx
// apps/web/src/app/onboarding/schedule/page.tsx

'use client';

import { useSearchParams } from 'next/navigation';
import { Calendar, Video, Home } from 'lucide-react';

export default function SchedulePage() {
  const searchParams = useSearchParams();
  const type = searchParams.get('type') || 'call';

  return (
    <div className="min-h-[calc(100vh-80px)] flex items-center justify-center px-4 py-12">
      <div className="max-w-2xl w-full">
        <div className="text-center mb-10">
          <div className="w-16 h-16 bg-haven-champagne-100 rounded-full flex items-center justify-center mx-auto mb-4">
            {type === 'visit' ? (
              <Home className="w-8 h-8 text-haven-champagne-600" />
            ) : (
              <Video className="w-8 h-8 text-haven-champagne-600" />
            )}
          </div>
          <h1 className="text-3xl font-bold text-haven-navy-900 mb-3">
            {type === 'visit' ? 'Schedule your home visit' : 'Schedule your onboarding call'}
          </h1>
          <p className="text-gray-600">
            {type === 'visit'
              ? "Our handyman will come document your home systems and walk through everything with you."
              : "We'll walk through the setup together on a video or phone call."}
          </p>
        </div>

        {/* Calendly Embed Placeholder */}
        <div className="bg-white rounded-2xl border border-gray-200 p-8">
          <div className="flex items-center justify-center h-96 bg-gray-50 rounded-xl border-2 border-dashed border-gray-200">
            <div className="text-center">
              <Calendar className="w-12 h-12 text-gray-400 mx-auto mb-4" />
              <p className="text-gray-500 font-medium">Calendly embed will go here</p>
              <p className="text-sm text-gray-400 mt-1">
                TODO: Integrate scheduling widget
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
```

```tsx
// apps/web/src/app/onboarding/schedule/confirmation/page.tsx

import Link from 'next/link';
import { CheckCircle, Calendar, ArrowRight } from 'lucide-react';

export default function ScheduleConfirmationPage() {
  return (
    <div className="min-h-[calc(100vh-80px)] flex items-center justify-center px-4 py-12">
      <div className="max-w-md w-full text-center">
        <div className="w-20 h-20 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-6">
          <CheckCircle className="w-10 h-10 text-green-600" />
        </div>

        <h1 className="text-3xl font-bold text-haven-navy-900 mb-3">
          You're all set!
        </h1>
        <p className="text-gray-600 mb-8">
          We've sent a calendar invite to your email. We're looking forward to meeting you.
        </p>

        <div className="bg-white rounded-2xl border border-gray-200 p-6 mb-8">
          <div className="flex items-center gap-4 text-left">
            <div className="w-12 h-12 bg-haven-champagne-100 rounded-xl flex items-center justify-center">
              <Calendar className="w-6 h-6 text-haven-champagne-600" />
            </div>
            <div>
              <p className="font-semibold text-haven-navy-900">Onboarding Call</p>
              <p className="text-gray-500 text-sm">Thursday, Jan 2 at 2:00 PM ET</p>
            </div>
          </div>
        </div>

        <Link
          href="/onboarding/wizard"
          className="inline-flex items-center gap-2 text-haven-navy-900 hover:text-haven-navy-700 font-medium"
        >
          Want to get ahead? Start entering info now
          <ArrowRight className="w-4 h-4" />
        </Link>
      </div>
    </div>
  );
}
```

```tsx
// apps/web/src/app/onboarding/wizard/layout.tsx

import { ProgressStepper } from '@/components/onboarding/ProgressStepper';

const WIZARD_STEPS = [
  { id: 'property', label: 'Property', href: '/onboarding/wizard/property' },
  { id: 'bills', label: 'Bills', href: '/onboarding/wizard/bills' },
  { id: 'systems', label: 'Systems', href: '/onboarding/wizard/systems' },
  { id: 'family', label: 'Family', href: '/onboarding/wizard/family' },
  { id: 'review', label: 'Review', href: '/onboarding/wizard/review' },
];

export default function WizardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  // TODO: Get current step and completed steps from state/URL
  const currentStep = 'property';
  const completedSteps: string[] = [];

  return (
    <div>
      <ProgressStepper
        steps={WIZARD_STEPS}
        currentStep={currentStep}
        completedSteps={completedSteps}
      />
      {children}
    </div>
  );
}
```

```tsx
// apps/web/src/app/onboarding/wizard/page.tsx

import { redirect } from 'next/navigation';

export default function WizardPage() {
  // TODO: Determine first incomplete step and redirect
  redirect('/onboarding/wizard/property');
}
```

```tsx
// apps/web/src/app/onboarding/wizard/property/page.tsx

'use client';

import Link from 'next/link';
import { MapPin, ArrowRight, Upload, Building2 } from 'lucide-react';
import { SkipToHumanBanner } from '@/components/onboarding/SkipToHumanBanner';

export default function PropertyPage() {
  return (
    <div className="max-w-2xl mx-auto px-4 py-8">
      <SkipToHumanBanner />

      <div className="text-center mb-8">
        <div className="w-14 h-14 bg-haven-champagne-100 rounded-2xl flex items-center justify-center mx-auto mb-4">
          <Building2 className="w-7 h-7 text-haven-champagne-600" />
        </div>
        <h1 className="text-2xl font-bold text-haven-navy-900 mb-2">
          Let's start with your property
        </h1>
        <p className="text-gray-600">
          Enter your address and we'll pull what we can from public records.
        </p>
      </div>

      <div className="bg-white rounded-2xl border border-gray-200 p-6 space-y-6">
        {/* Address Input */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Property Address
          </label>
          <div className="relative">
            <MapPin className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
              type="text"
              placeholder="Start typing your address..."
              className="w-full pl-12 pr-4 py-3 rounded-xl border border-gray-300 focus:border-haven-champagne-500 focus:ring-2 focus:ring-haven-champagne-200 outline-none transition-all"
            />
          </div>
        </div>

        {/* Inspection Upload */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Home Inspection Report (Optional)
          </label>
          <p className="text-sm text-gray-500 mb-3">
            Upload a recent inspection if you have one. We'll extract system details automatically.
          </p>
          <div className="border-2 border-dashed border-gray-200 rounded-xl p-8 text-center hover:border-haven-champagne-500 transition-colors cursor-pointer">
            <Upload className="w-8 h-8 text-gray-400 mx-auto mb-2" />
            <p className="text-sm text-gray-600">
              Drag & drop or <span className="text-haven-champagne-600 font-medium">browse</span>
            </p>
            <p className="text-xs text-gray-400 mt-1">PDF, JPG, or PNG up to 10MB</p>
          </div>
        </div>

        {/* Or Let Us Get It */}
        <div className="relative">
          <div className="absolute inset-0 flex items-center">
            <div className="w-full border-t border-gray-200" />
          </div>
          <div className="relative flex justify-center text-sm">
            <span className="px-3 bg-white text-gray-500">or</span>
          </div>
        </div>

        <button className="w-full py-3 px-4 rounded-xl border border-gray-200 hover:bg-gray-50 text-gray-700 font-medium transition-colors">
          Get my inspection from town records
        </button>
      </div>

      {/* Navigation */}
      <div className="flex justify-end mt-8">
        <Link
          href="/onboarding/wizard/bills"
          className="bg-haven-navy-900 hover:bg-haven-navy-800 text-white py-3 px-6 rounded-xl font-medium flex items-center gap-2 transition-colors"
        >
          Continue
          <ArrowRight className="w-4 h-4" />
        </Link>
      </div>
    </div>
  );
}
```

Create these additional placeholder files with simple "Coming soon" content:

- `apps/web/src/app/onboarding/wizard/bills/page.tsx`
- `apps/web/src/app/onboarding/wizard/systems/page.tsx`
- `apps/web/src/app/onboarding/wizard/family/page.tsx`
- `apps/web/src/app/onboarding/wizard/review/page.tsx`
- `apps/web/src/app/onboarding/activation/page.tsx`
- `apps/web/src/app/onboarding/complete/page.tsx`

Example placeholder:

```tsx
// apps/web/src/app/onboarding/wizard/bills/page.tsx

'use client';

import Link from 'next/link';
import { Receipt, ArrowLeft, ArrowRight } from 'lucide-react';
import { SkipToHumanBanner } from '@/components/onboarding/SkipToHumanBanner';

export default function BillsPage() {
  return (
    <div className="max-w-2xl mx-auto px-4 py-8">
      <SkipToHumanBanner />

      <div className="text-center mb-8">
        <div className="w-14 h-14 bg-haven-champagne-100 rounded-2xl flex items-center justify-center mx-auto mb-4">
          <Receipt className="w-7 h-7 text-haven-champagne-600" />
        </div>
        <h1 className="text-2xl font-bold text-haven-navy-900 mb-2">
          Your bills & accounts
        </h1>
        <p className="text-gray-600">
          Tell us about your recurring bills so we can manage payments for you.
        </p>
      </div>

      <div className="bg-white rounded-2xl border border-gray-200 p-8 text-center">
        <p className="text-gray-500">Bill entry form coming soon...</p>
      </div>

      {/* Navigation */}
      <div className="flex justify-between mt-8">
        <Link
          href="/onboarding/wizard/property"
          className="text-gray-600 hover:text-haven-navy-900 py-3 px-4 font-medium flex items-center gap-2 transition-colors"
        >
          <ArrowLeft className="w-4 h-4" />
          Back
        </Link>
        <Link
          href="/onboarding/wizard/systems"
          className="bg-haven-navy-900 hover:bg-haven-navy-800 text-white py-3 px-6 rounded-xl font-medium flex items-center gap-2 transition-colors"
        >
          Continue
          <ArrowRight className="w-4 h-4" />
        </Link>
      </div>
    </div>
  );
}
```

### Step 8: Create SkipToHumanBanner Component

```tsx
// apps/web/src/components/onboarding/SkipToHumanBanner.tsx

'use client';

import Link from 'next/link';
import { Users } from 'lucide-react';

export function SkipToHumanBanner() {
  return (
    <div className="bg-haven-champagne-50 border border-haven-champagne-200 rounded-xl p-4 mb-8">
      <div className="flex items-start gap-3">
        <div className="w-10 h-10 bg-haven-champagne-100 rounded-lg flex items-center justify-center flex-shrink-0">
          <Users className="w-5 h-5 text-haven-champagne-600" />
        </div>
        <div className="flex-1">
          <p className="text-sm text-haven-navy-900 font-medium">
            Don't have this info handy?
          </p>
          <p className="text-sm text-gray-600 mt-0.5">
            Schedule a free call or home visit — we'll gather everything for you.
          </p>
          <div className="flex gap-3 mt-3">
            <Link
              href="/onboarding/schedule?type=call"
              className="text-sm font-medium text-haven-champagne-700 hover:text-haven-champagne-800"
            >
              Schedule call →
            </Link>
            <Link
              href="/onboarding/schedule?type=visit"
              className="text-sm font-medium text-haven-champagne-700 hover:text-haven-champagne-800"
            >
              Schedule visit →
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}
```

### Step 9: Create Barrel Export

```tsx
// apps/web/src/components/onboarding/index.ts

export { OnboardingHeader } from './OnboardingHeader';
export { HelpFloatingButton } from './HelpFloatingButton';
export { ProgressStepper } from './ProgressStepper';
export { SkipToHumanBanner } from './SkipToHumanBanner';
```

### Step 10: Create TierComparisonModal Placeholder

```tsx
// apps/web/src/components/onboarding/TierComparisonModal.tsx

'use client';

import { X, Check } from 'lucide-react';

interface TierComparisonModalProps {
  onClose: () => void;
}

export function TierComparisonModal({ onClose }: TierComparisonModalProps) {
  const tiers = [
    {
      name: 'Essentials',
      price: '$39',
      description: 'Bill tracking & reminders',
      features: ['Bill consolidation', 'Payment tracking', 'Maintenance reminders'],
    },
    {
      name: 'Lite',
      price: '$349',
      description: 'Text-based manager support',
      features: ['Everything in Essentials', 'Text your manager', 'Reactive support'],
    },
    {
      name: 'Haven',
      price: '$749',
      description: 'Full-service management',
      features: ['Everything in Lite', 'Proactive manager', 'Monthly handyman hours'],
      popular: true,
    },
    {
      name: 'Haven+',
      price: '$1,499',
      description: 'Lifestyle & errands',
      features: ['Everything in Haven', 'Lifestyle services', 'Errand running'],
    },
    {
      name: 'Estate',
      price: '$3,499',
      description: 'Multi-property, white-glove',
      features: ['Everything in Haven+', 'Multi-property', 'Dedicated team'],
    },
  ];

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4 overflow-y-auto">
      <div className="bg-white rounded-2xl max-w-4xl w-full max-h-[90vh] overflow-y-auto">
        <div className="sticky top-0 bg-white border-b border-gray-200 p-6 flex items-center justify-between">
          <h2 className="text-xl font-bold text-haven-navy-900">Compare Plans</h2>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        <div className="p-6">
          <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-5 gap-4">
            {tiers.map((tier) => (
              <div
                key={tier.name}
                className={`rounded-xl border-2 p-4 ${
                  tier.popular
                    ? 'border-haven-champagne-500 bg-haven-champagne-50'
                    : 'border-gray-200'
                }`}
              >
                {tier.popular && (
                  <span className="text-xs font-semibold text-haven-champagne-700 uppercase">
                    Most Popular
                  </span>
                )}
                <h3 className="text-lg font-bold text-haven-navy-900 mt-1">
                  {tier.name}
                </h3>
                <p className="text-2xl font-bold text-haven-navy-900 mt-2">
                  {tier.price}
                  <span className="text-sm font-normal text-gray-500">/mo</span>
                </p>
                <p className="text-sm text-gray-600 mt-2">{tier.description}</p>
                <ul className="mt-4 space-y-2">
                  {tier.features.map((feature) => (
                    <li key={feature} className="flex items-start gap-2 text-sm">
                      <Check className="w-4 h-4 text-green-500 flex-shrink-0 mt-0.5" />
                      <span className="text-gray-600">{feature}</span>
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
```

## Verification

After implementing all files, run:

```bash
cd /Users/tomburke/Projects/Housing-Manager
pnpm build
```

Then test by navigating to:
- http://localhost:3000/onboarding
- http://localhost:3000/onboarding/welcome
- http://localhost:3000/onboarding/choose-path
- http://localhost:3000/onboarding/schedule
- http://localhost:3000/onboarding/wizard/property

## Success Criteria

1. ✅ All routes load without errors
2. ✅ OnboardingShell layout appears on all pages
3. ✅ HelpFloatingButton appears and opens modal
4. ✅ ProgressStepper shows correctly in wizard
5. ✅ Navigation between pages works
6. ✅ Haven branding (navy/champagne) is consistent
7. ✅ No bright green colors anywhere
8. ✅ Mobile responsive
