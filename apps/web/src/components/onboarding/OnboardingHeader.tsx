'use client';

import Link from 'next/link';
import { useState } from 'react';
import { Leaf } from 'lucide-react';
import { TierComparisonModal } from './TierComparisonModal';

export function OnboardingHeader() {
  const [showTierModal, setShowTierModal] = useState(false);

  return (
    <>
      <header className="bg-white border-b border-gray-200 sticky top-0 z-30">
        <div className="max-w-4xl mx-auto px-4 py-4 flex items-center justify-between">
          {/* Haven Logo */}
          <Link href="/" className="flex items-center gap-2.5">
            <div className="w-9 h-9 bg-haven-navy-900 rounded-lg flex items-center justify-center">
              <Leaf className="w-4 h-4 text-white" />
            </div>
            <span className="text-xl font-bold text-haven-navy-900">Haven</span>
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
