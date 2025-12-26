'use client';

import Link from 'next/link';
import { Smartphone, Phone, Home, ArrowRight, Star } from 'lucide-react';
import { cn } from '@/lib/utils';
import { useState } from 'react';

type PathOption = 'self' | 'call' | 'visit';

export default function ChoosePathPage() {
  const [selectedPath, setSelectedPath] = useState<PathOption | null>(null);

  // TODO: Get tier from user context/URL params
  // Higher tiers default to 'visit'
  const tier = 'haven'; // placeholder

  const paths = [
    {
      id: 'self' as PathOption,
      icon: Smartphone,
      title: 'On my own',
      description: "I'll enter my information digitally",
      time: '~30-45 minutes',
      href: '/onboarding/wizard',
    },
    {
      id: 'call' as PathOption,
      icon: Phone,
      title: 'Guided call',
      description: 'Walk through setup on a video call',
      time: '~45 minutes',
      href: '/onboarding/schedule?type=call',
    },
    {
      id: 'visit' as PathOption,
      icon: Home,
      title: 'Home visit',
      description: 'Our handyman comes to document everything',
      time: '~90 minutes',
      href: '/onboarding/schedule?type=visit',
      recommended: ['haven', 'haven_plus', 'estate'].includes(tier),
    },
  ];

  return (
    <div className="min-h-[calc(100vh-80px)] flex items-center justify-center px-4 py-12">
      <div className="max-w-2xl w-full">
        {/* Header */}
        <div className="text-center mb-10">
          <h1 className="text-3xl font-bold text-haven-navy-900 mb-3">
            How would you like to get started?
          </h1>
          <p className="text-gray-600 max-w-md mx-auto">
            Choose the option that works best for you. You can always switch to another method or get help at any time.
          </p>
        </div>

        {/* Path Options */}
        <div className="space-y-4 mb-8">
          {paths.map((path) => (
            <button
              key={path.id}
              onClick={() => setSelectedPath(path.id)}
              className={cn(
                'w-full p-6 rounded-2xl border-2 text-left transition-all relative',
                selectedPath === path.id
                  ? 'border-haven-champagne-500 bg-haven-champagne-50'
                  : 'border-gray-200 bg-white hover:border-gray-300'
              )}
            >
              {/* Recommended Badge */}
              {path.recommended && (
                <div className="absolute -top-3 left-6 bg-haven-champagne-500 text-haven-navy-900 text-xs font-semibold px-3 py-1 rounded-full flex items-center gap-1">
                  <Star className="w-3 h-3" />
                  Recommended
                </div>
              )}

              <div className="flex items-start gap-4">
                <div className={cn(
                  'w-12 h-12 rounded-xl flex items-center justify-center flex-shrink-0',
                  selectedPath === path.id
                    ? 'bg-haven-champagne-500 text-haven-navy-900'
                    : 'bg-gray-100 text-gray-600'
                )}>
                  <path.icon className="w-6 h-6" />
                </div>

                <div className="flex-1">
                  <div className="flex items-center gap-2">
                    <h3 className="text-lg font-semibold text-haven-navy-900">
                      {path.title}
                    </h3>
                  </div>
                  <p className="text-gray-600 mt-1">
                    {path.description}
                  </p>
                  <p className="text-sm text-gray-400 mt-2">
                    {path.time}
                  </p>
                </div>

                {/* Selection Indicator */}
                <div className={cn(
                  'w-6 h-6 rounded-full border-2 flex items-center justify-center flex-shrink-0',
                  selectedPath === path.id
                    ? 'border-haven-champagne-500 bg-haven-champagne-500'
                    : 'border-gray-300'
                )}>
                  {selectedPath === path.id && (
                    <div className="w-2 h-2 bg-white rounded-full" />
                  )}
                </div>
              </div>
            </button>
          ))}
        </div>

        {/* Continue Button */}
        <Link
          href={selectedPath ? paths.find(p => p.id === selectedPath)?.href || '#' : '#'}
          className={cn(
            'w-full py-4 px-6 rounded-xl font-medium flex items-center justify-center gap-2 transition-all',
            selectedPath
              ? 'bg-haven-navy-900 hover:bg-haven-navy-800 text-white'
              : 'bg-gray-200 text-gray-400 cursor-not-allowed'
          )}
          onClick={(e) => !selectedPath && e.preventDefault()}
        >
          Continue
          <ArrowRight className="w-4 h-4" />
        </Link>

        {/* Note about free help */}
        <p className="text-center text-sm text-gray-500 mt-6">
          All options include free support. Home visits are free for all tiers.
        </p>
      </div>
    </div>
  );
}
