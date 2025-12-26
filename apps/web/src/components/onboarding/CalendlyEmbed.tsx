'use client';

import { useEffect, useState } from 'react';
import { InlineWidget, useCalendlyEventListener } from 'react-calendly';
import { useOnboarding } from '@/context/OnboardingContext';
import { Loader2 } from 'lucide-react';

interface CalendlyEmbedProps {
  url: string;
  type: 'call' | 'visit' | 'activation';
  onEventScheduled?: (eventUri: string, inviteeUri: string) => void;
}

export function CalendlyEmbed({ url, type, onEventScheduled }: CalendlyEmbedProps) {
  const { data } = useOnboarding();
  const [isLoading, setIsLoading] = useState(true);

  // Pre-fill user data if available
  const prefill = {
    email: '', // Will come from auth context when implemented
    name: data.familyMembers.find(m => m.type === 'adult')?.firstName || '',
    customAnswers: {
      a1: data.property?.address?.formatted || '', // Property address
    },
  };

  // UTM parameters for tracking
  const utm = {
    utmSource: 'haven_onboarding',
    utmMedium: 'web',
    utmCampaign: type,
    utmTerm: data.tier,
  };

  // Listen for Calendly events
  useCalendlyEventListener({
    onEventScheduled: (e) => {
      const eventUri = e.data.payload.event.uri;
      const inviteeUri = e.data.payload.invitee.uri;
      onEventScheduled?.(eventUri, inviteeUri);
    },
  });

  // Handle loading state via iframe load
  useEffect(() => {
    // Set a timeout as fallback for loading
    const timer = setTimeout(() => setIsLoading(false), 3000);
    return () => clearTimeout(timer);
  }, []);

  return (
    <div className="relative min-h-[650px]">
      {isLoading && (
        <div className="absolute inset-0 flex items-center justify-center bg-gray-50 rounded-2xl z-10">
          <div className="text-center">
            <Loader2 className="w-8 h-8 text-haven-champagne-500 animate-spin mx-auto mb-3" />
            <p className="text-gray-500">Loading calendar...</p>
          </div>
        </div>
      )}
      <InlineWidget
        url={url}
        prefill={prefill}
        utm={utm}
        styles={{
          height: '650px',
          minWidth: '320px',
        }}
        pageSettings={{
          backgroundColor: 'ffffff',
          hideEventTypeDetails: false,
          hideLandingPageDetails: false,
          primaryColor: '102a43', // Haven navy
          textColor: '102a43',
        }}
      />
    </div>
  );
}
