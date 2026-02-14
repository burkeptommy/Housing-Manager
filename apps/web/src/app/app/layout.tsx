'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/auth-context';
import { DesktopSidebar, MobileHeader, MobileBottomNav, ConciergeFab } from '@/components/app-shell';

export default function AppLayout({ children }: { children: React.ReactNode }) {
  const { isAuthenticated, isLoading, needsOnboarding } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (!isLoading && !isAuthenticated) {
      router.push('/login');
    } else if (!isLoading && isAuthenticated && needsOnboarding) {
      router.push('/onboarding');
    }
  }, [isLoading, isAuthenticated, needsOnboarding, router]);

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-neutral-50">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-haven-600 mx-auto"></div>
          <p className="mt-4 text-neutral-600">Loading...</p>
        </div>
      </div>
    );
  }

  if (!isAuthenticated || needsOnboarding) {
    return null;
  }

  return (
    <div className="min-h-screen bg-neutral-50">
      {/* Desktop Sidebar */}
      <DesktopSidebar />

      {/* Mobile Header */}
      <MobileHeader />

      {/* Main Content */}
      <div className="lg:pl-[260px]">
        <main className="p-4 lg:p-6 pb-20 lg:pb-6">{children}</main>
      </div>

      {/* Mobile Bottom Navigation */}
      <MobileBottomNav />

      {/* Persistent Concierge Chat */}
      <ConciergeFab />
    </div>
  );
}
