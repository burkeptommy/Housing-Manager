'use client';

import { useSearchParams, useRouter } from 'next/navigation';
import { Suspense, useState } from 'react';
import { Video, Home, ArrowLeft, CheckCircle, MapPin } from 'lucide-react';
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
          <h1 className="text-2xl font-bold text-haven-900 mb-3">
            We&apos;re not in your area yet
          </h1>
          <p className="text-gray-600 mb-6">
            Home visits are currently available in Westchester County, NY and Fairfield County, CT.
            But don&apos;t worry—we can do a virtual walkthrough instead!
          </p>
          <div className="space-y-3">
            <Link
              href="/onboarding/schedule?type=virtual"
              className="block w-full py-3 px-4 bg-haven-900 text-white rounded-xl font-medium hover:bg-haven-800 transition-colors"
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
          className="inline-flex items-center gap-2 text-gray-500 hover:text-haven-900 mb-8 transition-colors"
        >
          <ArrowLeft className="w-4 h-4" />
          Back to options
        </Link>

        <div className="grid lg:grid-cols-5 gap-8">
          {/* Left Column - Info */}
          <div className="lg:col-span-2">
            <div className="sticky top-8">
              <div className="w-14 h-14 bg-haven-100 rounded-2xl flex items-center justify-center mb-4">
                <Icon className="w-7 h-7 text-haven-600" />
              </div>
              <h1 className="text-2xl font-bold text-haven-900 mb-3">
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
                <div className="mt-6 p-4 bg-haven-50 rounded-xl">
                  <div className="flex items-start gap-3">
                    <MapPin className="w-5 h-5 text-haven-600 flex-shrink-0 mt-0.5" />
                    <div>
                      <p className="text-sm font-medium text-haven-900">
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
                  <h2 className="text-xl font-bold text-haven-900 mb-2">
                    You&apos;re all set!
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
          <div className="w-8 h-8 border-4 border-haven-500 border-t-transparent rounded-full animate-spin mx-auto mb-4" />
          <p className="text-gray-500">Loading...</p>
        </div>
      </div>
    }>
      <SchedulePageContent />
    </Suspense>
  );
}
