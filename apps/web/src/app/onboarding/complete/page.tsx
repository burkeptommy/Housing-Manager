'use client';

import { useEffect, useState, useCallback } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import {
  PartyPopper,
  Home,
  MessageSquare,
  ArrowRight,
  CheckCircle,
  Calendar,
  User,
  Sparkles,
  Loader2,
} from 'lucide-react';
import { useOnboarding } from '@/context/OnboardingContext';
import { useAuth } from '@/contexts/auth-context';
import Confetti from 'react-confetti';

export default function CompletePage() {
  const router = useRouter();
  const { data, clearOnboardingData } = useOnboarding();
  const { user, completeOnboarding, isLoading: authLoading } = useAuth();

  const [isCompleting, setIsCompleting] = useState(false);
  const [isComplete, setIsComplete] = useState(false);
  const [showConfetti, setShowConfetti] = useState(true);
  const [windowSize, setWindowSize] = useState({ width: 0, height: 0 });
  const [error, setError] = useState<string | null>(null);

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

  // Get first name from family members or user
  const firstName = data.familyMembers.find(m => m.type === 'adult')?.firstName || user?.firstName || 'there';

  // Complete the onboarding process
  const handleCompleteOnboarding = useCallback(async () => {
    if (isCompleting || isComplete) return;

    setIsCompleting(true);
    setError(null);

    try {
      // Create household data from onboarding data
      const householdName = data.property?.propertyName || `${firstName}'s Home`;
      const address = data.property?.address?.formatted || '';

      // Create the household via API
      const token = sessionStorage.getItem('haven_firebase_token');
      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api'}/households`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            ...(token ? { Authorization: `Bearer ${token}` } : {}),
          },
          credentials: 'include',
          body: JSON.stringify({
            name: householdName,
            address,
            // Include additional onboarding data
            metadata: {
              selectedTier: data.selectedTier,
              homeDetails: data.homeDetails,
              services: data.services,
              activationCallAt: data.activationCallAt,
            },
          }),
        }
      );

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(errorData.message || 'Failed to create household');
      }

      const household = await response.json();

      // Complete onboarding with the new household ID
      await completeOnboarding(household.id);

      // Clear onboarding data from localStorage
      clearOnboardingData();

      setIsComplete(true);

      // Redirect to dashboard after a short delay
      setTimeout(() => {
        router.push('/app');
      }, 1500);
    } catch (err: unknown) {
      console.error('Error completing onboarding:', err);
      const message = err && typeof err === 'object' && 'message' in err
        ? (err as { message: string }).message
        : 'Something went wrong. Please try again.';
      setError(message);
      setIsCompleting(false);
    }
  }, [isCompleting, isComplete, data, firstName, completeOnboarding, clearOnboardingData, router]);

  if (authLoading) {
    return (
      <div className="min-h-[calc(100vh-80px)] flex items-center justify-center">
        <div className="text-center">
          <Loader2 className="w-10 h-10 text-haven-champagne-500 animate-spin mx-auto mb-4" />
          <p className="text-gray-500">Loading...</p>
        </div>
      </div>
    );
  }

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
            You&apos;re all set. Time to stop managing your home and start living in it.
          </p>
        </div>

        {/* Error State */}
        {error && (
          <div className="bg-red-50 border border-red-200 rounded-2xl p-6 mb-8 text-center">
            <p className="text-red-700 mb-4">{error}</p>
            <button
              onClick={handleCompleteOnboarding}
              className="px-6 py-2 bg-red-600 text-white rounded-xl hover:bg-red-700 transition-colors"
            >
              Try Again
            </button>
          </div>
        )}

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
                  Check your email for the calendar invite. We&apos;ll review everything and get your Haven Wallet set up.
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
                <p className="text-sm text-gray-500">We&apos;ll finalize your setup and fund your Haven Wallet</p>
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
        {!isComplete ? (
          <button
            onClick={handleCompleteOnboarding}
            disabled={isCompleting}
            className="w-full py-4 px-6 bg-haven-navy-900 text-white rounded-xl font-medium flex items-center justify-center gap-2 hover:bg-haven-navy-800 transition-colors disabled:opacity-50"
          >
            {isCompleting ? (
              <>
                <Loader2 className="w-5 h-5 animate-spin" />
                Setting up your account...
              </>
            ) : (
              <>
                <Home className="w-5 h-5" />
                Complete setup & go to dashboard
                <ArrowRight className="w-4 h-4" />
              </>
            )}
          </button>
        ) : (
          <Link
            href="/app"
            className="w-full py-4 px-6 bg-haven-navy-900 text-white rounded-xl font-medium flex items-center justify-center gap-2 hover:bg-haven-navy-800 transition-colors"
          >
            <Home className="w-5 h-5" />
            Go to your dashboard
            <ArrowRight className="w-4 h-4" />
          </Link>
        )}

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
