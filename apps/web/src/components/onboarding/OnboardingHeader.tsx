'use client';

import Link from 'next/link';
import Image from 'next/image';
import { useState } from 'react';
import { TierComparisonModal } from './TierComparisonModal';

export function OnboardingHeader() {
  const [showTierModal, setShowTierModal] = useState(false);

  return (
    <>
      <header className="bg-white border-b border-gray-200 sticky top-0 z-30">
        <div className="max-w-4xl mx-auto px-4 py-4 flex items-center justify-between">
          {/* Haven Logo */}
          <Link href="/" className="flex items-center">
            <Image
              src="/logo-wordmark.svg"
              alt="Haven"
              width={120}
              height={32}
              priority
              className="h-8 w-auto"
            />
          </Link>

          {/* Pricing Link */}
          <button
            onClick={() => setShowTierModal(true)}
            className="text-sm text-gray-500 hover:text-haven-navy-900 transition-colors font-medium"
          >
            Compare plans
          </button>
        </div>
      </header>

      {/* Tier Modal */}
      {showTierModal && (
        <TierComparisonModal onClose={() => setShowTierModal(false)} />
      )}
    </>
  );
}
