'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';

// Redirect to unified concierge page
export default function SupportPage() {
  const router = useRouter();

  useEffect(() => {
    // Redirect to concierge page with support tab active
    router.replace('/app/concierge');
  }, [router]);

  return (
    <div className="flex items-center justify-center h-64">
      <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-600"></div>
    </div>
  );
}
