'use client';

import { Suspense } from 'react';
import { useSearchParams } from 'next/navigation';
import Link from 'next/link';
import { CheckCircle, Video, Home, ArrowRight, Sparkles } from 'lucide-react';
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
                  {data.property.address.formatted}
                </p>
              )}
            </div>
          </div>
        </div>

        {/* What's Next */}
        <div className="bg-haven-navy-900 text-white rounded-2xl p-6 mb-8">
          <h3 className="font-semibold mb-2">What&apos;s next?</h3>
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
            I&apos;ll wait for my {type === 'visit' ? 'visit' : 'call'}
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
