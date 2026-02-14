'use client';

import { useState } from 'react';
import { MessageCircle, Phone, Calendar, X, Home, Mail } from 'lucide-react';
import Link from 'next/link';

const SUPPORT_PHONE = '508-333-8630';
const SUPPORT_PHONE_TEL = 'tel:+15083338630';
const SUPPORT_HOURS = 'Mon-Fri 9am-6pm ET';

export function HelpFloatingButton() {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <>
      {/* Floating Button */}
      <button
        onClick={() => setIsOpen(true)}
        className="fixed bottom-6 right-6 bg-haven-500 hover:bg-haven-600 text-haven-900 rounded-full p-4 shadow-lg transition-all hover:scale-105 z-40 group"
        aria-label="Get help"
      >
        <MessageCircle className="w-6 h-6" />
        <span className="absolute right-full mr-3 top-1/2 -translate-y-1/2 bg-haven-900 text-white text-sm px-3 py-1.5 rounded-lg whitespace-nowrap opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none">
          Need help?
        </span>
      </button>

      {/* Help Modal */}
      {isOpen && (
        <div
          className="fixed inset-0 bg-black/50 flex items-end sm:items-center justify-center z-50 p-4"
          onClick={(e) => e.target === e.currentTarget && setIsOpen(false)}
        >
          <div className="bg-white rounded-t-2xl sm:rounded-2xl w-full max-w-md overflow-hidden animate-in slide-in-from-bottom sm:slide-in-from-bottom-0 sm:zoom-in-95 duration-200">
            {/* Header */}
            <div className="bg-haven-900 text-white p-6">
              <div className="flex items-center justify-between mb-2">
                <h2 className="text-xl font-semibold">Need help?</h2>
                <button
                  onClick={() => setIsOpen(false)}
                  className="text-white/70 hover:text-white transition-colors"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>
              <p className="text-white/80 text-sm">
                We&apos;re here to help you get set up. Choose an option below.
              </p>
            </div>

            {/* Options */}
            <div className="p-4 space-y-3">
              {/* Schedule a Call */}
              <Link
                href="/onboarding/schedule?type=call"
                onClick={() => setIsOpen(false)}
                className="flex items-center gap-4 p-4 rounded-xl border border-gray-200 hover:border-haven-500 hover:bg-haven-50 transition-all group"
              >
                <div className="w-12 h-12 rounded-full bg-haven-100 flex items-center justify-center group-hover:bg-haven-100 transition-colors">
                  <Calendar className="w-5 h-5 text-haven-900" />
                </div>
                <div>
                  <div className="font-medium text-haven-900">Schedule a call</div>
                  <div className="text-sm text-gray-500">45-min video or phone call</div>
                </div>
              </Link>

              {/* Schedule a Home Visit */}
              <Link
                href="/onboarding/schedule?type=visit"
                onClick={() => setIsOpen(false)}
                className="flex items-center gap-4 p-4 rounded-xl border border-gray-200 hover:border-haven-500 hover:bg-haven-50 transition-all group"
              >
                <div className="w-12 h-12 rounded-full bg-haven-100 flex items-center justify-center group-hover:bg-haven-100 transition-colors">
                  <Home className="w-5 h-5 text-haven-900" />
                </div>
                <div>
                  <div className="font-medium text-haven-900">Schedule a home visit</div>
                  <div className="text-sm text-gray-500">We come to you (free)</div>
                </div>
              </Link>

              {/* Divider */}
              <div className="relative py-2">
                <div className="absolute inset-0 flex items-center">
                  <div className="w-full border-t border-gray-200" />
                </div>
                <div className="relative flex justify-center text-xs">
                  <span className="px-2 bg-white text-gray-400">or contact us directly</span>
                </div>
              </div>

              {/* Call Now */}
              <a
                href={SUPPORT_PHONE_TEL}
                className="flex items-center gap-4 p-4 rounded-xl border border-gray-200 hover:border-haven-500 hover:bg-haven-50 transition-all group"
              >
                <div className="w-12 h-12 rounded-full bg-haven-100 flex items-center justify-center group-hover:bg-haven-100 transition-colors">
                  <Phone className="w-5 h-5 text-haven-900" />
                </div>
                <div>
                  <div className="font-medium text-haven-900">Call us now</div>
                  <div className="text-sm text-gray-500">{SUPPORT_PHONE}</div>
                </div>
              </a>

              {/* Email */}
              <a
                href="mailto:support@haven.app"
                className="flex items-center gap-4 p-4 rounded-xl border border-gray-200 hover:border-haven-500 hover:bg-haven-50 transition-all group"
              >
                <div className="w-12 h-12 rounded-full bg-haven-100 flex items-center justify-center group-hover:bg-haven-100 transition-colors">
                  <Mail className="w-5 h-5 text-haven-900" />
                </div>
                <div>
                  <div className="font-medium text-haven-900">Email us</div>
                  <div className="text-sm text-gray-500">support@haven.app</div>
                </div>
              </a>
            </div>

            {/* Footer */}
            <div className="px-4 pb-4">
              <p className="text-xs text-center text-gray-400">
                Available {SUPPORT_HOURS}
              </p>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
