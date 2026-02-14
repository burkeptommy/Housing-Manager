'use client';

import { X, Check, Star } from 'lucide-react';
import { cn } from '@/lib/utils';

interface TierComparisonModalProps {
  onClose: () => void;
}

export function TierComparisonModal({ onClose }: TierComparisonModalProps) {
  const tiers = [
    {
      name: 'Essentials',
      price: 39,
      description: 'Track & organize',
      features: [
        'Bill consolidation dashboard',
        'Payment tracking & reminders',
        'Maintenance schedule',
        'Document storage',
      ],
      notIncluded: [
        'Dedicated Home Manager',
        'Bill payment service',
        'Vendor coordination',
      ],
    },
    {
      name: 'Lite',
      price: 349,
      description: 'Text-based support',
      features: [
        'Everything in Essentials',
        'Text your Home Manager',
        'Reactive support',
        'Basic vendor coordination',
      ],
      notIncluded: [
        'Proactive management',
        'Monthly handyman hours',
      ],
    },
    {
      name: 'Haven',
      price: 749,
      description: 'Full-service management',
      popular: true,
      features: [
        'Everything in Lite',
        'Proactive Home Manager',
        'We pay all your bills',
        'Full vendor coordination',
        '2 handyman hours/month',
        'Priority support',
      ],
      notIncluded: [],
    },
    {
      name: 'Haven+',
      price: 1499,
      description: 'Lifestyle services',
      features: [
        'Everything in Haven',
        '4 handyman hours/month',
        'Errand running',
        'Package handling',
        'Lifestyle concierge',
        'Guest preparation',
      ],
      notIncluded: [],
    },
    {
      name: 'Estate',
      price: 3499,
      description: 'Multi-property, white-glove',
      features: [
        'Everything in Haven+',
        'Multiple properties',
        'Dedicated team',
        '8 handyman hours/month',
        'Seasonal home prep',
        'Full estate management',
      ],
      notIncluded: [],
    },
  ];

  return (
    <div
      className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4 overflow-y-auto"
      onClick={(e) => e.target === e.currentTarget && onClose()}
    >
      <div className="bg-white rounded-2xl max-w-5xl w-full max-h-[90vh] overflow-y-auto my-8">
        {/* Header */}
        <div className="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between z-10">
          <div>
            <h2 className="text-xl font-bold text-haven-900">Compare plans</h2>
            <p className="text-sm text-gray-500">Choose the level of service that&apos;s right for you</p>
          </div>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600 transition-colors"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        {/* Plans Grid */}
        <div className="p-6">
          <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-5 gap-4">
            {tiers.map((tier) => (
              <div
                key={tier.name}
                className={cn(
                  'rounded-2xl border-2 p-5 relative flex flex-col',
                  tier.popular
                    ? 'border-haven-500 bg-haven-50'
                    : 'border-gray-200 bg-white'
                )}
              >
                {/* Popular Badge */}
                {tier.popular && (
                  <div className="absolute -top-3 left-1/2 -translate-x-1/2 bg-haven-500 text-haven-900 text-xs font-semibold px-3 py-1 rounded-full flex items-center gap-1">
                    <Star className="w-3 h-3" />
                    Most Popular
                  </div>
                )}

                {/* Tier Name */}
                <h3 className="text-lg font-bold text-haven-900 mt-1">
                  {tier.name}
                </h3>

                {/* Price */}
                <div className="mt-2">
                  <span className="text-3xl font-bold text-haven-900">
                    ${tier.price}
                  </span>
                  <span className="text-gray-500">/mo</span>
                </div>

                {/* Description */}
                <p className="text-sm text-gray-600 mt-1">{tier.description}</p>

                {/* Features */}
                <ul className="mt-4 space-y-2 flex-1">
                  {tier.features.map((feature) => (
                    <li key={feature} className="flex items-start gap-2 text-sm">
                      <Check className="w-4 h-4 text-green-500 flex-shrink-0 mt-0.5" />
                      <span className="text-gray-700">{feature}</span>
                    </li>
                  ))}
                  {tier.notIncluded.map((feature) => (
                    <li key={feature} className="flex items-start gap-2 text-sm opacity-50">
                      <X className="w-4 h-4 text-gray-400 flex-shrink-0 mt-0.5" />
                      <span className="text-gray-500">{feature}</span>
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>

          {/* Footer Note */}
          <div className="mt-6 text-center">
            <p className="text-sm text-gray-500">
              All plans include free onboarding call or home visit.{' '}
              <a href="tel:508-333-8630" className="text-haven-600 hover:underline font-medium">
                Call us
              </a>
              {' '}to discuss which plan is right for you.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
