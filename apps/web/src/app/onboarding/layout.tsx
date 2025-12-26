'use client';

import { usePathname } from 'next/navigation';
import { OnboardingHeader } from '@/components/onboarding/OnboardingHeader';
import { HelpFloatingButton } from '@/components/onboarding/HelpFloatingButton';
import { OnboardingProvider } from '@/context/OnboardingContext';

export default function OnboardingLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const pathname = usePathname();

  // Don't show header on welcome page (it has its own branding)
  const showHeader = !pathname.includes('/onboarding/welcome');

  // Don't do auth checks in layout - let individual pages handle it
  // This prevents the loading state from blocking everything

  return (
    <OnboardingProvider>
      <div className="min-h-screen bg-gray-50">
        {showHeader && <OnboardingHeader />}
        <main className={showHeader ? 'pb-24' : ''}>
          {children}
        </main>
        <HelpFloatingButton />
      </div>
    </OnboardingProvider>
  );
}
