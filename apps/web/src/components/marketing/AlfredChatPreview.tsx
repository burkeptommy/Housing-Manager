'use client';

import { TrendingDown, Calendar, Mail, Sparkles } from 'lucide-react';
import Image from 'next/image';

export function AlfredChatPreview() {
  return (
    <div className="relative bg-white rounded-2xl shadow-2xl border border-warm-200 overflow-hidden max-w-sm mx-auto lg:max-w-none">
      {/* Header */}
      <div className="bg-gradient-to-r from-haven-navy-900 to-haven-navy-800 px-4 py-3 flex items-center gap-3">
        <div className="relative">
          <div className="w-10 h-10 rounded-full bg-sage-100 flex items-center justify-center">
            <Image src="/alfred-icon.svg" alt="Alfred" width={24} height={24} />
          </div>
          <div className="absolute -bottom-0.5 -right-0.5 w-3 h-3 bg-sage-400 border-2 border-haven-navy-900 rounded-full" />
        </div>
        <div>
          <p className="font-semibold text-white flex items-center gap-1.5">
            Alfred
            <Sparkles className="w-4 h-4 text-sage-300" />
          </p>
          <p className="text-haven-200 text-sm">Your Home Manager</p>
        </div>
      </div>

      {/* Messages */}
      <div className="p-4 space-y-3 bg-warm-50">
        <div className="bg-white rounded-xl p-3 shadow-sm border border-warm-100">
          <div className="flex items-start gap-3">
            <div className="w-8 h-8 rounded-full bg-blue-100 flex items-center justify-center flex-shrink-0">
              <Mail className="w-4 h-4 text-blue-600" />
            </div>
            <div>
              <p className="font-medium text-warm-900">Got your Eversource bill</p>
              <p className="text-sm text-warm-500">Added to October bills. Due Nov 15.</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-xl p-3 shadow-sm border border-warm-100">
          <div className="flex items-start gap-3">
            <div className="w-8 h-8 rounded-full bg-green-100 flex items-center justify-center flex-shrink-0">
              <TrendingDown className="w-4 h-4 text-green-600" />
            </div>
            <div>
              <p className="font-medium text-warm-900">Found a better electric rate</p>
              <p className="text-sm text-warm-500">Switch to save $340/year</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-xl p-3 shadow-sm border border-warm-100">
          <div className="flex items-start gap-3">
            <div className="w-8 h-8 rounded-full bg-amber-100 flex items-center justify-center flex-shrink-0">
              <Calendar className="w-4 h-4 text-amber-600" />
            </div>
            <div>
              <p className="font-medium text-warm-900">Furnace service overdue</p>
              <p className="text-sm text-warm-500">Last serviced 26 months ago</p>
            </div>
          </div>
        </div>

        <div className="bg-sage-50 rounded-xl p-3 border border-sage-200">
          <p className="text-sm text-sage-700 flex items-center gap-2">
            <Sparkles className="w-4 h-4" />
            Just forward your emails. I&apos;ll handle the rest.
          </p>
        </div>
      </div>

      {/* Stats */}
      <div className="bg-white border-t border-warm-200 px-4 py-3 flex items-center justify-around">
        <div className="text-center">
          <p className="text-lg font-bold text-haven-700">$340</p>
          <p className="text-xs text-warm-500">savings found</p>
        </div>
        <div className="w-px h-8 bg-warm-200" />
        <div className="text-center">
          <p className="text-lg font-bold text-haven-700">14</p>
          <p className="text-xs text-warm-500">systems tracked</p>
        </div>
        <div className="w-px h-8 bg-warm-200" />
        <div className="text-center">
          <p className="text-lg font-bold text-haven-700">1</p>
          <p className="text-xs text-warm-500">monthly bill</p>
        </div>
      </div>
    </div>
  );
}
