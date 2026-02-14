'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import {
  Phone,
  DollarSign,
  CheckCircle,
  ArrowLeft,
  User,
  Wallet,
  MessageSquare,
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
  const tierPrices: Record<string, number> = {
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
          className="inline-flex items-center gap-2 text-gray-500 hover:text-haven-900 mb-8 transition-colors"
        >
          <ArrowLeft className="w-4 h-4" />
          Back to review
        </Link>

        {/* Header */}
        <div className="text-center mb-10">
          <div className="w-16 h-16 bg-haven-100 rounded-2xl flex items-center justify-center mx-auto mb-4">
            <Phone className="w-8 h-8 text-haven-600" />
          </div>
          <h1 className="text-3xl font-bold text-haven-900 mb-3">
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
            <div className="bg-haven-900 text-white rounded-2xl p-6">
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
                This is an estimate. We&apos;ll finalize during your activation call.
              </p>
            </div>

            {/* What to Expect */}
            <div className="bg-white rounded-2xl border border-gray-200 p-6">
              <h3 className="font-semibold text-haven-900 mb-4">
                On this call, we&apos;ll:
              </h3>
              <div className="space-y-4">
                <div className="flex items-start gap-3">
                  <div className="w-8 h-8 rounded-full bg-haven-100 flex items-center justify-center flex-shrink-0">
                    <CheckCircle className="w-4 h-4 text-haven-600" />
                  </div>
                  <div>
                    <p className="font-medium text-haven-900">Review your information</p>
                    <p className="text-sm text-gray-500">Make sure everything looks right</p>
                  </div>
                </div>
                <div className="flex items-start gap-3">
                  <div className="w-8 h-8 rounded-full bg-haven-100 flex items-center justify-center flex-shrink-0">
                    <DollarSign className="w-4 h-4 text-haven-600" />
                  </div>
                  <div>
                    <p className="font-medium text-haven-900">Set wallet funding</p>
                    <p className="text-sm text-gray-500">Decide how much to fund monthly</p>
                  </div>
                </div>
                <div className="flex items-start gap-3">
                  <div className="w-8 h-8 rounded-full bg-haven-100 flex items-center justify-center flex-shrink-0">
                    <MessageSquare className="w-4 h-4 text-haven-600" />
                  </div>
                  <div>
                    <p className="font-medium text-haven-900">Answer your questions</p>
                    <p className="text-sm text-gray-500">We&apos;re here to help</p>
                  </div>
                </div>
              </div>
            </div>

            {/* Your Home Manager */}
            <div className="bg-white rounded-2xl border border-gray-200 p-6">
              <h3 className="font-semibold text-haven-900 mb-4">
                Your Home Manager
              </h3>
              <div className="flex items-center gap-4">
                <div className="w-14 h-14 rounded-full bg-gradient-to-br from-haven-400 to-haven-600 flex items-center justify-center">
                  <User className="w-7 h-7 text-white" />
                </div>
                <div>
                  <p className="font-semibold text-haven-900">Sarah Chen</p>
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
                  <h2 className="text-xl font-bold text-haven-900 mb-2">
                    You&apos;re all set!
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

            {/* Skip for now */}
            <div className="text-center mt-6">
              <Link
                href="/onboarding/complete"
                className="text-gray-500 hover:text-haven-900 text-sm font-medium transition-colors"
              >
                Skip for now — I&apos;ll schedule later
              </Link>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
