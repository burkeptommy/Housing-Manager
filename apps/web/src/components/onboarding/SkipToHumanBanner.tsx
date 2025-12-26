'use client';

import Link from 'next/link';
import { Users, Phone } from 'lucide-react';

const SUPPORT_PHONE = '508-333-8630';

export function SkipToHumanBanner() {
  return (
    <div className="bg-haven-champagne-50 border border-haven-champagne-200 rounded-xl p-4 mb-8">
      <div className="flex items-start gap-3">
        <div className="w-10 h-10 bg-haven-champagne-100 rounded-lg flex items-center justify-center flex-shrink-0">
          <Users className="w-5 h-5 text-haven-champagne-600" />
        </div>
        <div className="flex-1">
          <p className="text-sm text-haven-navy-900 font-medium">
            Don&apos;t have this info handy?
          </p>
          <p className="text-sm text-gray-600 mt-0.5">
            Schedule a free call or home visit — we&apos;ll gather everything for you.
          </p>
          <div className="flex flex-wrap gap-x-4 gap-y-2 mt-3">
            <Link
              href="/onboarding/schedule?type=call"
              className="text-sm font-medium text-haven-champagne-700 hover:text-haven-champagne-800"
            >
              Schedule call →
            </Link>
            <Link
              href="/onboarding/schedule?type=visit"
              className="text-sm font-medium text-haven-champagne-700 hover:text-haven-champagne-800"
            >
              Schedule visit →
            </Link>
            <a
              href={`tel:${SUPPORT_PHONE}`}
              className="text-sm font-medium text-haven-champagne-700 hover:text-haven-champagne-800 flex items-center gap-1"
            >
              <Phone className="w-3 h-3" />
              Call now
            </a>
          </div>
        </div>
      </div>
    </div>
  );
}
