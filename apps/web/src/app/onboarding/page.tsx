'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/auth-context';
import { Loader2 } from 'lucide-react';

export default function OnboardingPage() {
  const router = useRouter();
  const { isAuthenticated, isLoading, needsOnboarding } = useAuth();

  useEffect(() => {
    if (isLoading) return;

    if (!isAuthenticated) {
      // Not logged in - go to registration
      router.push('/onboarding/welcome');
    } else if (!needsOnboarding) {
      // Already completed onboarding - go to dashboard
      router.push('/app');
    } else {
      // Needs onboarding - go to choose path
      router.push('/onboarding/choose-path');
    }
  }, [isLoading, isAuthenticated, needsOnboarding, router]);

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="text-center">
        <Loader2 className="w-10 h-10 text-haven-champagne-500 animate-spin mx-auto mb-4" />
        <p className="text-gray-500">Loading...</p>
      </div>
    </div>
  );
}
