# Claude Code Prompt: Phase 3 - Scheduling, Activation & Completion

## Context

Phase 1 created the onboarding route structure and shell components.
Phase 2 created the wizard pages with forms, state management, and data persistence.
Phase 3 integrates Calendly scheduling, Google Places autocomplete, and builds the activation and completion flows.

**Project Location:** `/Users/tomburke/Projects/Housing-Manager/`
**Web App Location:** `apps/web/src/`

## External Service Configuration

### Calendly URLs
```
Onboarding Call (45 min): https://calendly.com/burkepthomas/30min
Home Visit (90 min): https://calendly.com/burkepthomas/home-visit
Activation Call (30 min): https://calendly.com/burkepthomas/activation-call
```

### Support Contact
```
Phone: 508-333-8630
Hours: Mon-Fri 9am-6pm ET
```

### Google Places
Already configured in the application. Look for existing implementation patterns.

---

# PART 1: ENVIRONMENT VARIABLES

First, add these environment variables. Create or update `apps/web/.env.local`:

```bash
# Calendly
NEXT_PUBLIC_CALENDLY_ONBOARDING_CALL=https://calendly.com/burkepthomas/30min
NEXT_PUBLIC_CALENDLY_HOME_VISIT=https://calendly.com/burkepthomas/home-visit
NEXT_PUBLIC_CALENDLY_ACTIVATION_CALL=https://calendly.com/burkepthomas/activation-call

# Support
NEXT_PUBLIC_SUPPORT_PHONE=508-333-8630
NEXT_PUBLIC_SUPPORT_HOURS=Mon-Fri 9am-6pm ET
```

Also add these to `apps/web/.env.example` for documentation.

---

# PART 2: CALENDLY INTEGRATION

## Install Calendly React Package

```bash
cd /Users/tomburke/Projects/Housing-Manager
pnpm add react-calendly --filter=web
```

## Create Calendly Embed Component

```typescript
// apps/web/src/components/onboarding/CalendlyEmbed.tsx

'use client';

import { useEffect, useState } from 'react';
import { InlineWidget, useCalendlyEventListener } from 'react-calendly';
import { useOnboarding } from '@/context/OnboardingContext';
import { Loader2 } from 'lucide-react';

interface CalendlyEmbedProps {
  url: string;
  type: 'call' | 'visit' | 'activation';
  onEventScheduled?: (eventUri: string, inviteeUri: string) => void;
}

export function CalendlyEmbed({ url, type, onEventScheduled }: CalendlyEmbedProps) {
  const { data } = useOnboarding();
  const [isLoading, setIsLoading] = useState(true);

  // Pre-fill user data if available
  const prefill = {
    email: '', // Will come from auth context when implemented
    name: data.familyMembers.find(m => m.type === 'adult')?.firstName || '',
    customAnswers: {
      a1: data.property?.address?.formatted || '', // Property address
    },
  };

  // UTM parameters for tracking
  const utm = {
    utmSource: 'haven_onboarding',
    utmMedium: 'web',
    utmCampaign: type,
    utmTerm: data.tier,
  };

  // Listen for Calendly events
  useCalendlyEventListener({
    onEventScheduled: (e) => {
      const eventUri = e.data.payload.event.uri;
      const inviteeUri = e.data.payload.invitee.uri;
      onEventScheduled?.(eventUri, inviteeUri);
    },
  });

  return (
    <div className="relative min-h-[650px]">
      {isLoading && (
        <div className="absolute inset-0 flex items-center justify-center bg-gray-50 rounded-2xl">
          <div className="text-center">
            <Loader2 className="w-8 h-8 text-haven-champagne-500 animate-spin mx-auto mb-3" />
            <p className="text-gray-500">Loading calendar...</p>
          </div>
        </div>
      )}
      <InlineWidget
        url={url}
        prefill={prefill}
        utm={utm}
        styles={{
          height: '650px',
          minWidth: '320px',
        }}
        pageSettings={{
          backgroundColor: 'ffffff',
          hideEventTypeDetails: false,
          hideLandingPageDetails: false,
          primaryColor: '102a43', // Haven navy
          textColor: '102a43',
        }}
        LoadingSpinner={() => null}
        // @ts-ignore - onLoad exists but types are incomplete
        onLoad={() => setIsLoading(false)}
      />
    </div>
  );
}
```

## Update Schedule Page

```typescript
// apps/web/src/app/onboarding/schedule/page.tsx

'use client';

import { useSearchParams, useRouter } from 'next/navigation';
import { Suspense, useState } from 'react';
import { Video, Home, ArrowLeft, CheckCircle, MapPin, AlertCircle } from 'lucide-react';
import { CalendlyEmbed } from '@/components/onboarding/CalendlyEmbed';
import { useOnboarding } from '@/context/OnboardingContext';
import { isInServiceArea } from '@/types/onboarding';
import Link from 'next/link';

const CALENDLY_URLS = {
  call: process.env.NEXT_PUBLIC_CALENDLY_ONBOARDING_CALL || 'https://calendly.com/burkepthomas/30min',
  visit: process.env.NEXT_PUBLIC_CALENDLY_HOME_VISIT || 'https://calendly.com/burkepthomas/home-visit',
  virtual: process.env.NEXT_PUBLIC_CALENDLY_ONBOARDING_CALL || 'https://calendly.com/burkepthomas/30min',
};

function SchedulePageContent() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const { data, dispatch } = useOnboarding();
  
  const type = (searchParams.get('type') || 'call') as 'call' | 'visit' | 'virtual';
  const [isScheduled, setIsScheduled] = useState(false);

  // Check if user is in service area for home visits
  const zipCode = data.property?.address?.zipCode;
  const inServiceArea = zipCode ? isInServiceArea(zipCode) : true;
  const canDoHomeVisit = type === 'visit' && inServiceArea;

  // Handle when event is scheduled
  const handleEventScheduled = (eventUri: string, inviteeUri: string) => {
    // Update onboarding state
    if (type === 'visit') {
      dispatch({ type: 'SET_SCHEDULED_VISIT', payload: new Date().toISOString() });
    } else {
      dispatch({ type: 'SET_SCHEDULED_CALL', payload: new Date().toISOString() });
    }
    dispatch({ type: 'SET_PATH', payload: type === 'visit' ? 'home_visit' : 'guided_call' });
    
    setIsScheduled(true);
    
    // Redirect to confirmation after short delay
    setTimeout(() => {
      router.push('/onboarding/schedule/confirmation?type=' + type);
    }, 1500);
  };

  const config = {
    call: {
      icon: Video,
      title: 'Schedule your onboarding call',
      description: "We'll walk through the setup together on a video or phone call. Your Home Manager will guide you through entering all your information.",
      features: [
        'Screen share for easy setup',
        'Get all your questions answered',
        '45 minutes, at your convenience',
      ],
    },
    visit: {
      icon: Home,
      title: 'Schedule your home visit',
      description: "Our handyman will come to your home to document all your systems and appliances. Then we'll sit down together to gather your bills and account information.",
      features: [
        'Full home systems documentation',
        'Photos of all equipment',
        'Bill and account setup assistance',
        '90 minutes, completely free',
      ],
    },
    virtual: {
      icon: Video,
      title: 'Schedule a virtual walkthrough',
      description: "Since we're not in your area yet for in-person visits, we'll do a video call where you walk us through your home. We'll guide you on what to capture.",
      features: [
        'Video call walkthrough of your home',
        'We guide you on what to document',
        'Full bill and account setup',
        '60-90 minutes',
      ],
    },
  };

  const currentConfig = config[type];
  const Icon = currentConfig.icon;

  // If trying to book home visit but out of service area
  if (type === 'visit' && !inServiceArea && zipCode) {
    return (
      <div className="min-h-[calc(100vh-80px)] flex items-center justify-center px-4 py-12">
        <div className="max-w-md w-full text-center">
          <div className="w-16 h-16 bg-amber-100 rounded-full flex items-center justify-center mx-auto mb-6">
            <MapPin className="w-8 h-8 text-amber-600" />
          </div>
          <h1 className="text-2xl font-bold text-haven-navy-900 mb-3">
            We're not in your area yet
          </h1>
          <p className="text-gray-600 mb-6">
            Home visits are currently available in Westchester County, NY and Fairfield County, CT. 
            But don't worry—we can do a virtual walkthrough instead!
          </p>
          <div className="space-y-3">
            <Link
              href="/onboarding/schedule?type=virtual"
              className="block w-full py-3 px-4 bg-haven-navy-900 text-white rounded-xl font-medium hover:bg-haven-navy-800 transition-colors"
            >
              Schedule Virtual Walkthrough
            </Link>
            <Link
              href="/onboarding/schedule?type=call"
              className="block w-full py-3 px-4 border border-gray-200 text-gray-700 rounded-xl font-medium hover:bg-gray-50 transition-colors"
            >
              Schedule a Call Instead
            </Link>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-[calc(100vh-80px)] px-4 py-12">
      <div className="max-w-4xl mx-auto">
        {/* Back Link */}
        <Link
          href="/onboarding/choose-path"
          className="inline-flex items-center gap-2 text-gray-500 hover:text-haven-navy-900 mb-8 transition-colors"
        >
          <ArrowLeft className="w-4 h-4" />
          Back to options
        </Link>

        <div className="grid lg:grid-cols-5 gap-8">
          {/* Left Column - Info */}
          <div className="lg:col-span-2">
            <div className="sticky top-8">
              <div className="w-14 h-14 bg-haven-champagne-100 rounded-2xl flex items-center justify-center mb-4">
                <Icon className="w-7 h-7 text-haven-champagne-600" />
              </div>
              <h1 className="text-2xl font-bold text-haven-navy-900 mb-3">
                {currentConfig.title}
              </h1>
              <p className="text-gray-600 mb-6">
                {currentConfig.description}
              </p>

              {/* Features */}
              <div className="space-y-3">
                {currentConfig.features.map((feature, i) => (
                  <div key={i} className="flex items-start gap-3">
                    <CheckCircle className="w-5 h-5 text-green-500 flex-shrink-0 mt-0.5" />
                    <span className="text-gray-700">{feature}</span>
                  </div>
                ))}
              </div>

              {/* Service Area Note for Visits */}
              {type === 'visit' && (
                <div className="mt-6 p-4 bg-haven-champagne-50 rounded-xl">
                  <div className="flex items-start gap-3">
                    <MapPin className="w-5 h-5 text-haven-champagne-600 flex-shrink-0 mt-0.5" />
                    <div>
                      <p className="text-sm font-medium text-haven-navy-900">
                        Service Area
                      </p>
                      <p className="text-sm text-gray-600 mt-1">
                        Currently serving Westchester County, NY and Fairfield County, CT
                      </p>
                    </div>
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* Right Column - Calendly */}
          <div className="lg:col-span-3">
            <div className="bg-white rounded-2xl border border-gray-200 overflow-hidden">
              {isScheduled ? (
                <div className="p-12 text-center">
                  <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
                    <CheckCircle className="w-8 h-8 text-green-600" />
                  </div>
                  <h2 className="text-xl font-bold text-haven-navy-900 mb-2">
                    You're all set!
                  </h2>
                  <p className="text-gray-600">
                    Redirecting to confirmation...
                  </p>
                </div>
              ) : (
                <CalendlyEmbed
                  url={CALENDLY_URLS[type]}
                  type={type === 'virtual' ? 'call' : type}
                  onEventScheduled={handleEventScheduled}
                />
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default function SchedulePage() {
  return (
    <Suspense fallback={
      <div className="min-h-[calc(100vh-80px)] flex items-center justify-center">
        <div className="text-center">
          <div className="w-8 h-8 border-4 border-haven-champagne-500 border-t-transparent rounded-full animate-spin mx-auto mb-4" />
          <p className="text-gray-500">Loading...</p>
        </div>
      </div>
    }>
      <SchedulePageContent />
    </Suspense>
  );
}
```

## Update Schedule Confirmation Page

```typescript
// apps/web/src/app/onboarding/schedule/confirmation/page.tsx

'use client';

import { Suspense } from 'react';
import { useSearchParams } from 'next/navigation';
import Link from 'next/link';
import { CheckCircle, Calendar, Video, Home, ArrowRight, Sparkles } from 'lucide-react';
import { useOnboarding } from '@/context/OnboardingContext';

function ConfirmationContent() {
  const searchParams = useSearchParams();
  const { data } = useOnboarding();
  const type = searchParams.get('type') || 'call';

  const config = {
    call: {
      icon: Video,
      title: "Your call is scheduled!",
      description: "We've sent a calendar invite to your email. Looking forward to helping you get set up!",
      nextStep: "Want to get ahead? You can start entering some information now.",
    },
    visit: {
      icon: Home,
      title: "Your home visit is scheduled!",
      description: "Our handyman will arrive at the scheduled time. We'll document everything and get you fully set up.",
      nextStep: "No need to prepare anything—we'll handle it all during the visit.",
    },
    virtual: {
      icon: Video,
      title: "Your virtual walkthrough is scheduled!",
      description: "We'll guide you through documenting your home via video call. Just have your phone ready to show us around!",
      nextStep: "Want to get ahead? You can start entering some information now.",
    },
  };

  const currentConfig = config[type as keyof typeof config] || config.call;
  const Icon = currentConfig.icon;

  return (
    <div className="min-h-[calc(100vh-80px)] flex items-center justify-center px-4 py-12">
      <div className="max-w-lg w-full">
        {/* Success Icon */}
        <div className="text-center mb-8">
          <div className="relative inline-block">
            <div className="w-20 h-20 bg-green-100 rounded-full flex items-center justify-center mx-auto">
              <CheckCircle className="w-10 h-10 text-green-600" />
            </div>
            <div className="absolute -top-1 -right-1 w-8 h-8 bg-haven-champagne-500 rounded-full flex items-center justify-center">
              <Sparkles className="w-4 h-4 text-white" />
            </div>
          </div>
        </div>

        {/* Message */}
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold text-haven-navy-900 mb-3">
            {currentConfig.title}
          </h1>
          <p className="text-gray-600">
            {currentConfig.description}
          </p>
        </div>

        {/* Appointment Card */}
        <div className="bg-white rounded-2xl border border-gray-200 p-6 mb-8">
          <div className="flex items-start gap-4">
            <div className="w-12 h-12 bg-haven-champagne-100 rounded-xl flex items-center justify-center flex-shrink-0">
              <Icon className="w-6 h-6 text-haven-champagne-600" />
            </div>
            <div className="flex-1">
              <h3 className="font-semibold text-haven-navy-900">
                {type === 'visit' ? 'Home Visit' : type === 'virtual' ? 'Virtual Walkthrough' : 'Onboarding Call'}
              </h3>
              <p className="text-gray-500 text-sm mt-1">
                Check your email for the calendar invite with all the details.
              </p>
              {data.property?.address?.formatted && (
                <p className="text-sm text-gray-400 mt-2">
                  📍 {data.property.address.formatted}
                </p>
              )}
            </div>
          </div>
        </div>

        {/* What's Next */}
        <div className="bg-haven-navy-900 text-white rounded-2xl p-6 mb-8">
          <h3 className="font-semibold mb-2">What's next?</h3>
          <p className="text-white/80 text-sm">
            {currentConfig.nextStep}
          </p>
        </div>

        {/* Actions */}
        <div className="space-y-3">
          {type !== 'visit' && (
            <Link
              href="/onboarding/wizard"
              className="w-full py-4 px-6 bg-haven-champagne-500 hover:bg-haven-champagne-600 text-haven-navy-900 rounded-xl font-medium flex items-center justify-center gap-2 transition-colors"
            >
              Start entering info now
              <ArrowRight className="w-4 h-4" />
            </Link>
          )}
          <Link
            href="/"
            className="w-full py-4 px-6 border border-gray-200 text-gray-700 rounded-xl font-medium flex items-center justify-center gap-2 hover:bg-gray-50 transition-colors"
          >
            I'll wait for my {type === 'visit' ? 'visit' : 'call'}
          </Link>
        </div>

        {/* Contact Info */}
        <p className="text-center text-sm text-gray-500 mt-8">
          Questions? Call us at{' '}
          <a href="tel:508-333-8630" className="text-haven-navy-900 font-medium hover:underline">
            (508) 333-8630
          </a>
        </p>
      </div>
    </div>
  );
}

export default function ScheduleConfirmationPage() {
  return (
    <Suspense fallback={
      <div className="min-h-[calc(100vh-80px)] flex items-center justify-center">
        <div className="w-8 h-8 border-4 border-haven-champagne-500 border-t-transparent rounded-full animate-spin" />
      </div>
    }>
      <ConfirmationContent />
    </Suspense>
  );
}
```

---

# PART 3: UPDATE HELP FLOATING BUTTON

Update the help button with real contact info:

```typescript
// apps/web/src/components/onboarding/HelpFloatingButton.tsx

'use client';

import { useState } from 'react';
import { MessageCircle, Phone, Calendar, X, Home, Mail } from 'lucide-react';
import Link from 'next/link';

const SUPPORT_PHONE = '508-333-8630';
const SUPPORT_PHONE_TEL = 'tel:+15083338630';
const SUPPORT_HOURS = 'Mon-Fri 9am-6pm ET';

export function HelpFloatingButton() {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <>
      {/* Floating Button */}
      <button
        onClick={() => setIsOpen(true)}
        className="fixed bottom-6 right-6 bg-haven-champagne-500 hover:bg-haven-champagne-600 text-haven-navy-900 rounded-full p-4 shadow-lg transition-all hover:scale-105 z-40 group"
        aria-label="Get help"
      >
        <MessageCircle className="w-6 h-6" />
        <span className="absolute right-full mr-3 top-1/2 -translate-y-1/2 bg-haven-navy-900 text-white text-sm px-3 py-1.5 rounded-lg whitespace-nowrap opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none">
          Need help?
        </span>
      </button>

      {/* Help Modal */}
      {isOpen && (
        <div 
          className="fixed inset-0 bg-black/50 flex items-end sm:items-center justify-center z-50 p-4"
          onClick={(e) => e.target === e.currentTarget && setIsOpen(false)}
        >
          <div className="bg-white rounded-t-2xl sm:rounded-2xl w-full max-w-md overflow-hidden animate-in slide-in-from-bottom sm:slide-in-from-bottom-0 sm:zoom-in-95 duration-200">
            {/* Header */}
            <div className="bg-haven-navy-900 text-white p-6">
              <div className="flex items-center justify-between mb-2">
                <h2 className="text-xl font-semibold">Need help?</h2>
                <button
                  onClick={() => setIsOpen(false)}
                  className="text-white/70 hover:text-white transition-colors"
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
              <Link
                href="/onboarding/schedule?type=call"
                onClick={() => setIsOpen(false)}
                className="flex items-center gap-4 p-4 rounded-xl border border-gray-200 hover:border-haven-champagne-500 hover:bg-haven-champagne-50 transition-all group"
              >
                <div className="w-12 h-12 rounded-full bg-haven-navy-100 flex items-center justify-center group-hover:bg-haven-champagne-100 transition-colors">
                  <Calendar className="w-5 h-5 text-haven-navy-900" />
                </div>
                <div>
                  <div className="font-medium text-haven-navy-900">Schedule a call</div>
                  <div className="text-sm text-gray-500">45-min video or phone call</div>
                </div>
              </Link>

              {/* Schedule a Home Visit */}
              <Link
                href="/onboarding/schedule?type=visit"
                onClick={() => setIsOpen(false)}
                className="flex items-center gap-4 p-4 rounded-xl border border-gray-200 hover:border-haven-champagne-500 hover:bg-haven-champagne-50 transition-all group"
              >
                <div className="w-12 h-12 rounded-full bg-haven-navy-100 flex items-center justify-center group-hover:bg-haven-champagne-100 transition-colors">
                  <Home className="w-5 h-5 text-haven-navy-900" />
                </div>
                <div>
                  <div className="font-medium text-haven-navy-900">Schedule a home visit</div>
                  <div className="text-sm text-gray-500">We come to you (free)</div>
                </div>
              </Link>

              {/* Divider */}
              <div className="relative py-2">
                <div className="absolute inset-0 flex items-center">
                  <div className="w-full border-t border-gray-200" />
                </div>
                <div className="relative flex justify-center text-xs">
                  <span className="px-2 bg-white text-gray-400">or contact us directly</span>
                </div>
              </div>

              {/* Call Now */}
              <a
                href={SUPPORT_PHONE_TEL}
                className="flex items-center gap-4 p-4 rounded-xl border border-gray-200 hover:border-haven-champagne-500 hover:bg-haven-champagne-50 transition-all group"
              >
                <div className="w-12 h-12 rounded-full bg-haven-navy-100 flex items-center justify-center group-hover:bg-haven-champagne-100 transition-colors">
                  <Phone className="w-5 h-5 text-haven-navy-900" />
                </div>
                <div>
                  <div className="font-medium text-haven-navy-900">Call us now</div>
                  <div className="text-sm text-gray-500">{SUPPORT_PHONE}</div>
                </div>
              </a>

              {/* Email */}
              <a
                href="mailto:support@haven.app"
                className="flex items-center gap-4 p-4 rounded-xl border border-gray-200 hover:border-haven-champagne-500 hover:bg-haven-champagne-50 transition-all group"
              >
                <div className="w-12 h-12 rounded-full bg-haven-navy-100 flex items-center justify-center group-hover:bg-haven-champagne-100 transition-colors">
                  <Mail className="w-5 h-5 text-haven-navy-900" />
                </div>
                <div>
                  <div className="font-medium text-haven-navy-900">Email us</div>
                  <div className="text-sm text-gray-500">support@haven.app</div>
                </div>
              </a>
            </div>

            {/* Footer */}
            <div className="px-4 pb-4">
              <p className="text-xs text-center text-gray-400">
                Available {SUPPORT_HOURS}
              </p>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
```

---

# PART 4: GOOGLE PLACES ADDRESS AUTOCOMPLETE

Create an address autocomplete component. Check existing codebase for Google Places setup patterns - there should be an existing API key and possibly a hook or component.

```typescript
// apps/web/src/components/onboarding/AddressAutocomplete.tsx

'use client';

import { useEffect, useRef, useState, useCallback } from 'react';
import { MapPin, Loader2, Check } from 'lucide-react';
import { cn } from '@/lib/utils';

interface AddressComponents {
  street: string;
  unit?: string;
  city: string;
  state: string;
  zipCode: string;
  country: string;
  formatted: string;
  latitude?: number;
  longitude?: number;
}

interface AddressAutocompleteProps {
  onAddressSelect: (address: AddressComponents) => void;
  defaultValue?: string;
  error?: string;
  placeholder?: string;
}

export function AddressAutocomplete({
  onAddressSelect,
  defaultValue = '',
  error,
  placeholder = 'Start typing your address...',
}: AddressAutocompleteProps) {
  const inputRef = useRef<HTMLInputElement>(null);
  const autocompleteRef = useRef<google.maps.places.Autocomplete | null>(null);
  const [inputValue, setInputValue] = useState(defaultValue);
  const [isLoading, setIsLoading] = useState(false);
  const [isSelected, setIsSelected] = useState(false);

  // Parse Google Place result into our format
  const parsePlace = useCallback((place: google.maps.places.PlaceResult): AddressComponents | null => {
    if (!place.address_components) return null;

    const getComponent = (type: string): string => {
      const component = place.address_components?.find(c => c.types.includes(type));
      return component?.long_name || '';
    };

    const getComponentShort = (type: string): string => {
      const component = place.address_components?.find(c => c.types.includes(type));
      return component?.short_name || '';
    };

    const streetNumber = getComponent('street_number');
    const route = getComponent('route');
    const street = streetNumber ? `${streetNumber} ${route}` : route;

    return {
      street,
      city: getComponent('locality') || getComponent('sublocality') || getComponent('administrative_area_level_3'),
      state: getComponentShort('administrative_area_level_1'),
      zipCode: getComponent('postal_code'),
      country: getComponentShort('country'),
      formatted: place.formatted_address || '',
      latitude: place.geometry?.location?.lat(),
      longitude: place.geometry?.location?.lng(),
    };
  }, []);

  // Initialize autocomplete
  useEffect(() => {
    if (!inputRef.current || typeof google === 'undefined') return;

    // Create autocomplete instance
    autocompleteRef.current = new google.maps.places.Autocomplete(inputRef.current, {
      componentRestrictions: { country: 'us' },
      fields: ['address_components', 'formatted_address', 'geometry'],
      types: ['address'],
    });

    // Handle place selection
    autocompleteRef.current.addListener('place_changed', () => {
      const place = autocompleteRef.current?.getPlace();
      if (place) {
        setIsLoading(true);
        const parsed = parsePlace(place);
        if (parsed) {
          setInputValue(parsed.formatted);
          setIsSelected(true);
          onAddressSelect(parsed);
        }
        setIsLoading(false);
      }
    });

    return () => {
      if (autocompleteRef.current) {
        google.maps.event.clearInstanceListeners(autocompleteRef.current);
      }
    };
  }, [onAddressSelect, parsePlace]);

  // Handle manual input changes
  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setInputValue(e.target.value);
    setIsSelected(false);
  };

  return (
    <div className="space-y-1">
      <label className="block text-sm font-medium text-gray-700">
        Property Address <span className="text-red-500">*</span>
      </label>
      <div className="relative">
        <div className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400">
          {isLoading ? (
            <Loader2 className="w-5 h-5 animate-spin" />
          ) : isSelected ? (
            <Check className="w-5 h-5 text-green-500" />
          ) : (
            <MapPin className="w-5 h-5" />
          )}
        </div>
        <input
          ref={inputRef}
          type="text"
          value={inputValue}
          onChange={handleInputChange}
          placeholder={placeholder}
          className={cn(
            'w-full pl-11 pr-4 py-3 rounded-xl border transition-all outline-none',
            'focus:ring-2 focus:ring-haven-champagne-200',
            error
              ? 'border-red-300 focus:border-red-500'
              : isSelected
                ? 'border-green-300 focus:border-green-500'
                : 'border-gray-300 focus:border-haven-champagne-500'
          )}
        />
      </div>
      {error && (
        <p className="text-sm text-red-600">{error}</p>
      )}
      <p className="text-xs text-gray-400">
        Start typing and select your address from the dropdown
      </p>
    </div>
  );
}
```

**Note:** You'll need to load the Google Maps script. Check if there's already a script loader in the app. If not, add this to the onboarding layout or use `@react-google-maps/api`:

```typescript
// If not already present, add to apps/web/src/app/onboarding/layout.tsx
import Script from 'next/script';

// In the component:
<Script
  src={`https://maps.googleapis.com/maps/api/js?key=${process.env.NEXT_PUBLIC_GOOGLE_PLACES_API_KEY}&libraries=places`}
  strategy="beforeInteractive"
/>
```

---

# PART 5: ACTIVATION PAGE

```typescript
// apps/web/src/app/onboarding/activation/page.tsx

'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { 
  Phone, 
  Calendar, 
  DollarSign, 
  CheckCircle, 
  ArrowLeft,
  User,
  Wallet,
  MessageSquare,
  ArrowRight,
} from 'lucide-react';
import { CalendlyEmbed } from '@/components/onboarding/CalendlyEmbed';
import { useOnboarding } from '@/context/OnboardingContext';
import { formatCurrency } from '@/lib/format';

const CALENDLY_ACTIVATION = process.env.NEXT_PUBLIC_CALENDLY_ACTIVATION_CALL || 'https://calendly.com/burkepthomas/activation-call';

export default function ActivationPage() {
  const router = useRouter();
  const { data, dispatch, calculateMonthlyTotal } = useOnboarding();
  const [isScheduled, setIsScheduled] = useState(false);

  const monthlyTotal = calculateMonthlyTotal();
  const tierPrices = {
    essentials: 39,
    lite: 349,
    haven: 749,
    haven_plus: 1499,
    estate: 3499,
  };
  const serviceFee = tierPrices[data.tier] || 749;
  const totalWithService = monthlyTotal + serviceFee;

  const handleEventScheduled = (eventUri: string, inviteeUri: string) => {
    dispatch({ type: 'SET_ACTIVATION_CALL', payload: new Date().toISOString() });
    setIsScheduled(true);
    
    setTimeout(() => {
      router.push('/onboarding/complete');
    }, 2000);
  };

  return (
    <div className="min-h-[calc(100vh-80px)] px-4 py-12">
      <div className="max-w-4xl mx-auto">
        {/* Back Link */}
        <Link
          href="/onboarding/wizard/review"
          className="inline-flex items-center gap-2 text-gray-500 hover:text-haven-navy-900 mb-8 transition-colors"
        >
          <ArrowLeft className="w-4 h-4" />
          Back to review
        </Link>

        {/* Header */}
        <div className="text-center mb-10">
          <div className="w-16 h-16 bg-haven-champagne-100 rounded-2xl flex items-center justify-center mx-auto mb-4">
            <Phone className="w-8 h-8 text-haven-champagne-600" />
          </div>
          <h1 className="text-3xl font-bold text-haven-navy-900 mb-3">
            One last step: Activation Call
          </h1>
          <p className="text-gray-600 max-w-xl mx-auto">
            Schedule a 30-minute call with your Home Manager to review everything, 
            set up your Haven Wallet, and officially activate your account.
          </p>
        </div>

        <div className="grid lg:grid-cols-5 gap-8">
          {/* Left Column - What to Expect */}
          <div className="lg:col-span-2 space-y-6">
            {/* Monthly Summary Card */}
            <div className="bg-haven-navy-900 text-white rounded-2xl p-6">
              <h3 className="font-semibold mb-4 flex items-center gap-2">
                <Wallet className="w-5 h-5" />
                Your Monthly Summary
              </h3>
              <div className="space-y-3">
                <div className="flex justify-between text-white/80">
                  <span>Bills & Expenses</span>
                  <span>{formatCurrency(monthlyTotal)}</span>
                </div>
                <div className="flex justify-between text-white/80">
                  <span>Haven Service ({data.tier})</span>
                  <span>{formatCurrency(serviceFee)}</span>
                </div>
                <div className="border-t border-white/20 pt-3 flex justify-between font-semibold">
                  <span>Monthly Total</span>
                  <span>{formatCurrency(totalWithService)}</span>
                </div>
              </div>
              <p className="text-white/60 text-xs mt-4">
                This is an estimate. We'll finalize during your activation call.
              </p>
            </div>

            {/* What to Expect */}
            <div className="bg-white rounded-2xl border border-gray-200 p-6">
              <h3 className="font-semibold text-haven-navy-900 mb-4">
                On this call, we'll:
              </h3>
              <div className="space-y-4">
                <div className="flex items-start gap-3">
                  <div className="w-8 h-8 rounded-full bg-haven-champagne-100 flex items-center justify-center flex-shrink-0">
                    <CheckCircle className="w-4 h-4 text-haven-champagne-600" />
                  </div>
                  <div>
                    <p className="font-medium text-haven-navy-900">Review your information</p>
                    <p className="text-sm text-gray-500">Make sure everything looks right</p>
                  </div>
                </div>
                <div className="flex items-start gap-3">
                  <div className="w-8 h-8 rounded-full bg-haven-champagne-100 flex items-center justify-center flex-shrink-0">
                    <DollarSign className="w-4 h-4 text-haven-champagne-600" />
                  </div>
                  <div>
                    <p className="font-medium text-haven-navy-900">Set wallet funding</p>
                    <p className="text-sm text-gray-500">Decide how much to fund monthly</p>
                  </div>
                </div>
                <div className="flex items-start gap-3">
                  <div className="w-8 h-8 rounded-full bg-haven-champagne-100 flex items-center justify-center flex-shrink-0">
                    <MessageSquare className="w-4 h-4 text-haven-champagne-600" />
                  </div>
                  <div>
                    <p className="font-medium text-haven-navy-900">Answer your questions</p>
                    <p className="text-sm text-gray-500">We're here to help</p>
                  </div>
                </div>
              </div>
            </div>

            {/* Your Home Manager */}
            <div className="bg-white rounded-2xl border border-gray-200 p-6">
              <h3 className="font-semibold text-haven-navy-900 mb-4">
                Your Home Manager
              </h3>
              <div className="flex items-center gap-4">
                <div className="w-14 h-14 rounded-full bg-gradient-to-br from-haven-champagne-400 to-haven-champagne-600 flex items-center justify-center">
                  <User className="w-7 h-7 text-white" />
                </div>
                <div>
                  <p className="font-semibold text-haven-navy-900">Sarah Chen</p>
                  <p className="text-sm text-gray-500">Haven Home Manager</p>
                </div>
              </div>
              <p className="text-sm text-gray-600 mt-4">
                Sarah will be your dedicated point of contact. One text or call to her, 
                and she handles everything.
              </p>
            </div>
          </div>

          {/* Right Column - Calendly */}
          <div className="lg:col-span-3">
            <div className="bg-white rounded-2xl border border-gray-200 overflow-hidden">
              {isScheduled ? (
                <div className="p-12 text-center">
                  <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
                    <CheckCircle className="w-8 h-8 text-green-600" />
                  </div>
                  <h2 className="text-xl font-bold text-haven-navy-900 mb-2">
                    You're all set!
                  </h2>
                  <p className="text-gray-600">
                    Taking you to your welcome page...
                  </p>
                </div>
              ) : (
                <CalendlyEmbed
                  url={CALENDLY_ACTIVATION}
                  type="activation"
                  onEventScheduled={handleEventScheduled}
                />
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
```

---

# PART 6: COMPLETE PAGE

```typescript
// apps/web/src/app/onboarding/complete/page.tsx

'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { 
  PartyPopper, 
  Home, 
  MessageSquare, 
  CreditCard, 
  ArrowRight,
  CheckCircle,
  Calendar,
  User,
  Sparkles,
} from 'lucide-react';
import { useOnboarding } from '@/context/OnboardingContext';
import Confetti from 'react-confetti';

export default function CompletePage() {
  const { data, reset } = useOnboarding();
  const [showConfetti, setShowConfetti] = useState(true);
  const [windowSize, setWindowSize] = useState({ width: 0, height: 0 });

  // Get window size for confetti
  useEffect(() => {
    const updateWindowSize = () => {
      setWindowSize({ width: window.innerWidth, height: window.innerHeight });
    };
    updateWindowSize();
    window.addEventListener('resize', updateWindowSize);
    
    // Stop confetti after 5 seconds
    const timer = setTimeout(() => setShowConfetti(false), 5000);
    
    return () => {
      window.removeEventListener('resize', updateWindowSize);
      clearTimeout(timer);
    };
  }, []);

  // Get first name from family members or default
  const firstName = data.familyMembers.find(m => m.type === 'adult')?.firstName || 'there';

  return (
    <div className="min-h-[calc(100vh-80px)] flex items-center justify-center px-4 py-12 relative overflow-hidden">
      {/* Confetti */}
      {showConfetti && (
        <Confetti
          width={windowSize.width}
          height={windowSize.height}
          recycle={false}
          numberOfPieces={200}
          colors={['#c4a574', '#102a43', '#faf6ed', '#d4c4a5', '#243b53']}
        />
      )}

      <div className="max-w-2xl w-full relative z-10">
        {/* Hero */}
        <div className="text-center mb-10">
          <div className="relative inline-block mb-6">
            <div className="w-24 h-24 bg-gradient-to-br from-haven-champagne-400 to-haven-champagne-600 rounded-3xl flex items-center justify-center mx-auto shadow-lg">
              <PartyPopper className="w-12 h-12 text-white" />
            </div>
            <div className="absolute -top-2 -right-2 w-10 h-10 bg-green-500 rounded-full flex items-center justify-center shadow-md">
              <CheckCircle className="w-6 h-6 text-white" />
            </div>
          </div>
          <h1 className="text-4xl font-bold text-haven-navy-900 mb-3">
            Welcome to Haven, {firstName}!
          </h1>
          <p className="text-xl text-gray-600">
            You're all set. Time to stop managing your home and start living in it.
          </p>
        </div>

        {/* Activation Call Reminder */}
        {data.activationCallAt && (
          <div className="bg-haven-champagne-50 border border-haven-champagne-200 rounded-2xl p-6 mb-8">
            <div className="flex items-start gap-4">
              <div className="w-12 h-12 bg-haven-champagne-100 rounded-xl flex items-center justify-center flex-shrink-0">
                <Calendar className="w-6 h-6 text-haven-champagne-600" />
              </div>
              <div>
                <h3 className="font-semibold text-haven-navy-900">Activation call scheduled!</h3>
                <p className="text-sm text-gray-600 mt-1">
                  Check your email for the calendar invite. We'll review everything and get your Haven Wallet set up.
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Your Home Manager */}
        <div className="bg-white rounded-2xl border border-gray-200 p-6 mb-8">
          <div className="flex items-center gap-4 mb-4">
            <div className="w-16 h-16 rounded-full bg-gradient-to-br from-haven-champagne-400 to-haven-champagne-600 flex items-center justify-center">
              <User className="w-8 h-8 text-white" />
            </div>
            <div>
              <p className="text-sm text-gray-500">Your Home Manager</p>
              <h3 className="text-xl font-semibold text-haven-navy-900">Sarah Chen</h3>
            </div>
          </div>
          <p className="text-gray-600 mb-4">
            Sarah is your dedicated point of contact at Haven. Need something? Just text or call her — 
            she handles everything from there.
          </p>
          <div className="flex gap-3">
            <a
              href="sms:+15083338630"
              className="flex-1 py-3 px-4 bg-haven-navy-900 text-white rounded-xl font-medium flex items-center justify-center gap-2 hover:bg-haven-navy-800 transition-colors"
            >
              <MessageSquare className="w-4 h-4" />
              Text Sarah
            </a>
            <a
              href="tel:+15083338630"
              className="flex-1 py-3 px-4 border border-gray-200 text-haven-navy-900 rounded-xl font-medium flex items-center justify-center gap-2 hover:bg-gray-50 transition-colors"
            >
              Call Sarah
            </a>
          </div>
        </div>

        {/* What's Next */}
        <div className="bg-white rounded-2xl border border-gray-200 p-6 mb-8">
          <h3 className="font-semibold text-haven-navy-900 mb-4 flex items-center gap-2">
            <Sparkles className="w-5 h-5 text-haven-champagne-500" />
            What happens next
          </h3>
          <div className="space-y-4">
            <div className="flex items-start gap-4">
              <div className="w-8 h-8 rounded-full bg-haven-navy-100 flex items-center justify-center flex-shrink-0 text-sm font-semibold text-haven-navy-900">
                1
              </div>
              <div>
                <p className="font-medium text-haven-navy-900">Activation call</p>
                <p className="text-sm text-gray-500">We'll finalize your setup and fund your Haven Wallet</p>
              </div>
            </div>
            <div className="flex items-start gap-4">
              <div className="w-8 h-8 rounded-full bg-haven-navy-100 flex items-center justify-center flex-shrink-0 text-sm font-semibold text-haven-navy-900">
                2
              </div>
              <div>
                <p className="font-medium text-haven-navy-900">We take over your bills</p>
                <p className="text-sm text-gray-500">Sarah will coordinate transferring bill payments to Haven</p>
              </div>
            </div>
            <div className="flex items-start gap-4">
              <div className="w-8 h-8 rounded-full bg-haven-navy-100 flex items-center justify-center flex-shrink-0 text-sm font-semibold text-haven-navy-900">
                3
              </div>
              <div>
                <p className="font-medium text-haven-navy-900">Relax</p>
                <p className="text-sm text-gray-500">We handle everything — you just live in your home</p>
              </div>
            </div>
          </div>
        </div>

        {/* CTA */}
        <Link
          href="/app"
          className="w-full py-4 px-6 bg-haven-navy-900 text-white rounded-xl font-medium flex items-center justify-center gap-2 hover:bg-haven-navy-800 transition-colors"
        >
          <Home className="w-5 h-5" />
          Go to your dashboard
          <ArrowRight className="w-4 h-4" />
        </Link>

        {/* Contact */}
        <p className="text-center text-sm text-gray-500 mt-8">
          Questions? Call us anytime at{' '}
          <a href="tel:508-333-8630" className="text-haven-navy-900 font-medium hover:underline">
            (508) 333-8630
          </a>
        </p>
      </div>
    </div>
  );
}
```

---

# PART 7: INSTALL ADDITIONAL DEPENDENCIES

Run these commands:

```bash
cd /Users/tomburke/Projects/Housing-Manager
pnpm add react-calendly react-confetti --filter=web
```

---

# PART 8: UPDATE REVIEW PAGE TO LINK TO ACTIVATION

Make sure the Review page has a button that goes to the Activation page:

```typescript
// At the end of the Review page, the continue button should go to:
href="/onboarding/activation"
```

---

# PART 9: UPDATE SKIP TO HUMAN BANNER WITH PHONE

```typescript
// apps/web/src/components/onboarding/SkipToHumanBanner.tsx

'use client';

import Link from 'next/link';
import { Users, Phone } from 'lucide-react';

const SUPPORT_PHONE = '508-333-8630';

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
          <div className="flex flex-wrap gap-x-4 gap-y-2 mt-3">
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
            <a
              href={`tel:${SUPPORT_PHONE}`}
              className="text-sm font-medium text-haven-champagne-700 hover:text-haven-champagne-800 flex items-center gap-1"
            >
              <Phone className="w-3 h-3" />
              Call now
            </a>
          </div>
        </div>
      </div>
    </div>
  );
}
```

---

# VERIFICATION CHECKLIST

After implementation, verify:

1. ✅ `react-calendly` and `react-confetti` installed
2. ✅ Environment variables added to `.env.local`
3. ✅ CalendlyEmbed component created and working
4. ✅ Schedule page shows Calendly widget for call/visit/virtual
5. ✅ Schedule confirmation page shows success message
6. ✅ HelpFloatingButton has correct phone number (508-333-8630)
7. ✅ Activation page shows monthly summary and Calendly
8. ✅ Complete page shows confetti and welcome message
9. ✅ AddressAutocomplete component created (if Google Places configured)
10. ✅ All phone numbers updated to 508-333-8630
11. ✅ Navigation flow works: Wizard → Review → Activation → Complete
12. ✅ No TypeScript errors: `pnpm build`

## Test the Full Flow

1. Go to `/onboarding/welcome`
2. Continue to `/onboarding/choose-path`
3. Select "Schedule a call" → Verify Calendly loads
4. Go back, select "On my own" → Go through wizard
5. Complete all wizard steps
6. Review page → Continue to Activation
7. Activation page → Schedule call (or skip for testing)
8. Complete page → Verify confetti and content
9. Click "Go to dashboard" → Should navigate to `/app`

## Test Help Button

1. On any onboarding page, click the floating help button
2. Verify phone number shows as (508) 333-8630
3. Verify "Call us now" link works
4. Verify schedule links work
