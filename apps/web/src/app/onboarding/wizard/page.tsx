'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import {
  Home,
  CheckCircle,
  Sparkles,
  ArrowRight,
  Loader2,
  Building2,
  Wrench,
  Users,
  Receipt,
  HelpCircle,
  Calendar,
  Phone,
} from 'lucide-react';
import { AddressAutocomplete } from '@/components/onboarding/AddressAutocomplete';
import { usePropertyEnrichment, PropertyDetails } from '@/hooks/usePropertyEnrichment';
import { useOnboarding } from '@/context/OnboardingContext';
import { useAuth } from '@/contexts/auth-context';
import { getIdToken } from '@/lib/firebase';

type Step = 'challenge' | 'address' | 'confirm' | 'welcome';

interface Challenge {
  id: string;
  icon: React.ReactNode;
  title: string;
  description: string;
}

const CHALLENGES: Challenge[] = [
  {
    id: 'repairs',
    icon: <Wrench className="w-6 h-6" />,
    title: 'Finding reliable repair help',
    description: 'Something breaks and I never know who to call',
  },
  {
    id: 'vendors',
    icon: <Users className="w-6 h-6" />,
    title: 'Managing all my vendors',
    description: 'Landscaper, pool guy, cleaners... it\'s a lot to track',
  },
  {
    id: 'bills',
    icon: <Receipt className="w-6 h-6" />,
    title: 'Keeping up with bills',
    description: 'HOA, utilities, services - hard to stay organized',
  },
  {
    id: 'overwhelm',
    icon: <HelpCircle className="w-6 h-6" />,
    title: 'Generally overwhelmed',
    description: 'Homeownership is a lot and I need help',
  },
];

interface PropertyData {
  street: string;
  city: string;
  state: string;
  zipCode: string;
  bedrooms: string;
  bathrooms: string;
  squareFeet: string;
  yearBuilt: string;
  propertyType: string;
  enrichment: PropertyDetails | null;
}

const PROPERTY_TYPE_LABELS: Record<string, string> = {
  'SFR': 'Single Family',
  'Single Family': 'Single Family',
  'CONDO': 'Condo',
  'Condo': 'Condo',
  'TOWNHOUSE': 'Townhouse',
  'Townhouse': 'Townhouse',
  'MULTI': 'Multi-Family',
  'Multi-Family': 'Multi-Family',
};

export default function OnboardingWizard() {
  const router = useRouter();
  const { user } = useAuth();
  const { setProperty, setPropertyEnrichment } = useOnboarding();
  const { fetchPropertyDetails, isLoading: isEnriching } = usePropertyEnrichment();

  const [step, setStep] = useState<Step>('challenge');
  const [selectedChallenge, setSelectedChallenge] = useState<string | null>(null);
  const [isSaving, setIsSaving] = useState(false);

  const [propertyData, setPropertyData] = useState<PropertyData>({
    street: '',
    city: '',
    state: '',
    zipCode: '',
    bedrooms: '',
    bathrooms: '',
    squareFeet: '',
    yearBuilt: '',
    propertyType: '',
    enrichment: null,
  });

  const handleChallengeSelect = (challengeId: string) => {
    setSelectedChallenge(challengeId);
    // Brief delay for visual feedback before advancing
    setTimeout(() => {
      setStep('address');
    }, 300);
  };

  const handleAddressSelect = async (address: {
    street: string;
    city: string;
    state: string;
    zipCode: string;
  }) => {
    setPropertyData(prev => ({
      ...prev,
      street: address.street,
      city: address.city,
      state: address.state,
      zipCode: address.zipCode,
    }));

    // Auto-fetch property details from ATTOM
    try {
      const data = await fetchPropertyDetails(
        address.street,
        address.city,
        address.state,
        address.zipCode
      );

      if (data) {
        setPropertyData(prev => ({
          ...prev,
          bedrooms: data.bedrooms?.toString() || '',
          bathrooms: data.bathrooms?.toString() || '',
          squareFeet: data.squareFeet?.toString() || '',
          yearBuilt: data.yearBuilt?.toString() || '',
          propertyType: data.propertyType || '',
          enrichment: data,
        }));
      }

      setStep('confirm');
    } catch (error) {
      console.error('Enrichment error:', error);
      setStep('confirm'); // Continue anyway
    }
  };

  const handleConfirm = async () => {
    setIsSaving(true);

    try {
      // Save to onboarding context
      setProperty({
        address: {
          street: propertyData.street,
          city: propertyData.city,
          state: propertyData.state,
          zipCode: propertyData.zipCode,
          country: 'USA',
          formatted: `${propertyData.street}, ${propertyData.city}, ${propertyData.state} ${propertyData.zipCode}`,
        },
        propertyType: (propertyData.propertyType as any) || 'single_family',
        bedrooms: propertyData.bedrooms ? parseInt(propertyData.bedrooms) : undefined,
        bathrooms: propertyData.bathrooms ? parseFloat(propertyData.bathrooms) : undefined,
        squareFeet: propertyData.squareFeet ? parseInt(propertyData.squareFeet) : undefined,
        yearBuilt: propertyData.yearBuilt ? parseInt(propertyData.yearBuilt) : undefined,
      });

      // Save enrichment data for checklist generation
      if (propertyData.enrichment) {
        setPropertyEnrichment(propertyData.enrichment);
      }

      // Call API to create/update household with onboarding progress
      try {
        const token = await getIdToken();
        const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

        await fetch(`${apiUrl}/onboarding/complete-signup`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify({
            biggestChallenge: selectedChallenge,
            address: {
              street: propertyData.street,
              city: propertyData.city,
              state: propertyData.state,
              zipCode: propertyData.zipCode,
            },
            propertyDetails: {
              bedrooms: propertyData.bedrooms ? parseInt(propertyData.bedrooms) : null,
              bathrooms: propertyData.bathrooms ? parseFloat(propertyData.bathrooms) : null,
              squareFeet: propertyData.squareFeet ? parseInt(propertyData.squareFeet) : null,
              yearBuilt: propertyData.yearBuilt ? parseInt(propertyData.yearBuilt) : null,
              propertyType: propertyData.propertyType || null,
            },
            enrichmentData: propertyData.enrichment || null,
          }),
        });
      } catch (apiError) {
        console.error('API error (continuing anyway):', apiError);
      }

      setStep('welcome');
    } catch (error) {
      console.error('Error saving property:', error);
    } finally {
      setIsSaving(false);
    }
  };

  const handleComplete = () => {
    router.push('/app');
  };

  const handleScheduleCall = () => {
    router.push('/onboarding/schedule');
  };

  const userName = user?.displayName?.split(' ')[0] || 'there';

  const steps = ['challenge', 'address', 'confirm', 'welcome'];
  const currentStepIndex = steps.indexOf(step);

  return (
    <div className="min-h-screen bg-gradient-to-br from-haven-950 to-haven-900 flex items-center justify-center p-4">
      <div className="w-full max-w-lg">

        {/* Step 1: Challenge */}
        {step === 'challenge' && (
          <div className="bg-white rounded-2xl p-8 shadow-2xl">
            <div className="text-center mb-8">
              <h1 className="text-2xl font-bold text-haven-900 mb-2">
                What&apos;s your biggest challenge as a homeowner?
              </h1>
              <p className="text-gray-500">
                This helps us personalize your Haven experience
              </p>
            </div>

            <div className="space-y-3">
              {CHALLENGES.map((challenge) => (
                <button
                  key={challenge.id}
                  onClick={() => handleChallengeSelect(challenge.id)}
                  className={`w-full p-4 rounded-xl border-2 text-left transition-all duration-200 ${
                    selectedChallenge === challenge.id
                      ? 'border-haven-500 bg-haven-50'
                      : 'border-gray-200 hover:border-haven-300 hover:bg-gray-50'
                  }`}
                >
                  <div className="flex items-start gap-4">
                    <div className={`w-12 h-12 rounded-xl flex items-center justify-center flex-shrink-0 ${
                      selectedChallenge === challenge.id
                        ? 'bg-haven-500 text-white'
                        : 'bg-gray-100 text-gray-600'
                    }`}>
                      {challenge.icon}
                    </div>
                    <div>
                      <h3 className="font-semibold text-haven-900">
                        {challenge.title}
                      </h3>
                      <p className="text-sm text-gray-500 mt-0.5">
                        {challenge.description}
                      </p>
                    </div>
                  </div>
                </button>
              ))}
            </div>
          </div>
        )}

        {/* Step 2: Address */}
        {step === 'address' && (
          <div className="bg-white rounded-2xl p-8 shadow-2xl">
            <div className="text-center mb-8">
              <div className="w-16 h-16 bg-haven-100 rounded-2xl flex items-center justify-center mx-auto mb-4">
                <Home className="w-8 h-8 text-haven-600" />
              </div>
              <h1 className="text-2xl font-bold text-haven-900">
                Let&apos;s find your home
              </h1>
              <p className="text-gray-500 mt-2">
                Enter your address and we&apos;ll do the rest
              </p>
            </div>

            <AddressAutocomplete
              onAddressSelect={handleAddressSelect}
              placeholder="Start typing your address..."
            />

            {isEnriching && (
              <div className="mt-6 flex items-center justify-center gap-3 text-haven-600">
                <Loader2 className="w-5 h-5 animate-spin" />
                <span>Finding your home details...</span>
              </div>
            )}

            <p className="text-xs text-gray-400 text-center mt-6">
              We&apos;ll look up your property details from public records
            </p>

            <button
              onClick={() => setStep('challenge')}
              className="w-full mt-6 text-gray-500 py-2 text-sm hover:text-haven-900 transition"
            >
              ← Back
            </button>
          </div>
        )}

        {/* Step 3: Confirm Details */}
        {step === 'confirm' && (
          <div className="bg-white rounded-2xl p-8 shadow-2xl">
            <div className="text-center mb-6">
              <div className="w-16 h-16 bg-emerald-100 rounded-2xl flex items-center justify-center mx-auto mb-4">
                <Sparkles className="w-8 h-8 text-emerald-600" />
              </div>
              <h1 className="text-2xl font-bold text-haven-900">
                {propertyData.enrichment ? 'We found your home!' : 'Confirm your address'}
              </h1>
              <p className="text-gray-500 mt-2">
                {propertyData.enrichment
                  ? 'We found these details from public records'
                  : 'Add some details about your property'
                }
              </p>
            </div>

            {/* Address Display */}
            <div className="bg-gray-50 rounded-xl p-4 mb-6">
              <div className="flex items-start gap-3">
                <Building2 className="w-5 h-5 text-gray-400 mt-0.5" />
                <div>
                  <p className="font-medium text-haven-900">
                    {propertyData.street}
                  </p>
                  <p className="text-gray-500 text-sm">
                    {propertyData.city}, {propertyData.state} {propertyData.zipCode}
                  </p>
                </div>
              </div>
            </div>

            {/* Property Details Grid */}
            {propertyData.enrichment && (
              <div className="grid grid-cols-2 gap-4 mb-6">
                {propertyData.bedrooms && (
                  <div className="bg-gray-50 rounded-xl p-3">
                    <p className="text-xs text-gray-500 uppercase tracking-wide">Bedrooms</p>
                    <p className="text-lg font-semibold text-haven-900">{propertyData.bedrooms}</p>
                  </div>
                )}
                {propertyData.bathrooms && (
                  <div className="bg-gray-50 rounded-xl p-3">
                    <p className="text-xs text-gray-500 uppercase tracking-wide">Bathrooms</p>
                    <p className="text-lg font-semibold text-haven-900">{propertyData.bathrooms}</p>
                  </div>
                )}
                {propertyData.squareFeet && (
                  <div className="bg-gray-50 rounded-xl p-3">
                    <p className="text-xs text-gray-500 uppercase tracking-wide">Square Feet</p>
                    <p className="text-lg font-semibold text-haven-900">{parseInt(propertyData.squareFeet).toLocaleString()}</p>
                  </div>
                )}
                {propertyData.yearBuilt && (
                  <div className="bg-gray-50 rounded-xl p-3">
                    <p className="text-xs text-gray-500 uppercase tracking-wide">Year Built</p>
                    <p className="text-lg font-semibold text-haven-900">{propertyData.yearBuilt}</p>
                  </div>
                )}
              </div>
            )}

            {/* Additional Property Info */}
            {propertyData.enrichment && (
              <div className="space-y-2 mb-6">
                {propertyData.propertyType && (
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-gray-500">Property Type</span>
                    <span className="font-medium text-haven-900">
                      {PROPERTY_TYPE_LABELS[propertyData.propertyType] || propertyData.propertyType}
                    </span>
                  </div>
                )}
                {propertyData.enrichment.heatingType && (
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-gray-500">Heating</span>
                    <span className="font-medium text-haven-900">{propertyData.enrichment.heatingType}</span>
                  </div>
                )}
                {propertyData.enrichment.coolingType && (
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-gray-500">Cooling</span>
                    <span className="font-medium text-haven-900">{propertyData.enrichment.coolingType}</span>
                  </div>
                )}
                {propertyData.enrichment.hasPool && (
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-gray-500">Pool</span>
                    <span className="font-medium text-emerald-600">Yes</span>
                  </div>
                )}
                {propertyData.enrichment.fireplaceCount && propertyData.enrichment.fireplaceCount > 0 && (
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-gray-500">Fireplaces</span>
                    <span className="font-medium text-haven-900">{propertyData.enrichment.fireplaceCount}</span>
                  </div>
                )}
              </div>
            )}

            {propertyData.enrichment && (
              <p className="text-xs text-emerald-600 text-center mb-6 flex items-center justify-center gap-1">
                <Sparkles className="w-3 h-3" />
                Auto-filled from public property records
              </p>
            )}

            <button
              onClick={handleConfirm}
              disabled={isSaving}
              className="w-full bg-haven-900 text-white py-3 rounded-xl font-medium hover:bg-haven-800 transition flex items-center justify-center gap-2 disabled:opacity-50"
            >
              {isSaving ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" />
                  Setting up your home...
                </>
              ) : (
                <>
                  Looks good, continue
                  <ArrowRight className="w-4 h-4" />
                </>
              )}
            </button>

            <button
              onClick={() => setStep('address')}
              className="w-full mt-3 text-gray-500 py-2 text-sm hover:text-haven-900 transition"
            >
              ← Change address
            </button>
          </div>
        )}

        {/* Step 4: Welcome */}
        {step === 'welcome' && (
          <div className="bg-white rounded-2xl p-8 shadow-2xl text-center">
            <div className="w-20 h-20 bg-emerald-100 rounded-full flex items-center justify-center mx-auto mb-6">
              <CheckCircle className="w-10 h-10 text-emerald-600" />
            </div>

            <h1 className="text-2xl font-bold text-haven-900 mb-2">
              Welcome to Haven, {userName}!
            </h1>

            <p className="text-gray-500 mb-8">
              Your home is set up. Now let&apos;s introduce you to your Home Manager
              who will build your complete home profile.
            </p>

            {/* Property Summary */}
            {propertyData.street && (
              <div className="bg-gray-50 rounded-xl p-4 mb-6 text-left">
                <div className="flex items-start gap-3">
                  <div className="w-10 h-10 bg-haven-100 rounded-lg flex items-center justify-center flex-shrink-0">
                    <Home className="w-5 h-5 text-haven-600" />
                  </div>
                  <div>
                    <p className="font-medium text-haven-900">{propertyData.street}</p>
                    <p className="text-sm text-gray-500">
                      {propertyData.city}, {propertyData.state} {propertyData.zipCode}
                    </p>
                    {propertyData.bedrooms && propertyData.bathrooms && (
                      <p className="text-sm text-gray-500 mt-1">
                        {propertyData.bedrooms} bed • {propertyData.bathrooms} bath
                        {propertyData.squareFeet && ` • ${parseInt(propertyData.squareFeet).toLocaleString()} sq ft`}
                      </p>
                    )}
                  </div>
                </div>
              </div>
            )}

            {/* Next Steps */}
            <div className="bg-haven-50 rounded-xl p-5 mb-6 text-left">
              <h3 className="font-semibold text-haven-900 mb-3">
                What happens next?
              </h3>
              <ul className="space-y-3 text-sm text-gray-600">
                <li className="flex items-start gap-3">
                  <Phone className="w-5 h-5 text-haven-600 mt-0.5 flex-shrink-0" />
                  <span>Schedule a 30-minute intro call with your Home Manager</span>
                </li>
                <li className="flex items-start gap-3">
                  <Calendar className="w-5 h-5 text-haven-600 mt-0.5 flex-shrink-0" />
                  <span>They&apos;ll learn about your home systems, vendors, and needs</span>
                </li>
                <li className="flex items-start gap-3">
                  <Sparkles className="w-5 h-5 text-haven-600 mt-0.5 flex-shrink-0" />
                  <span>Receive your personalized home profile within 48 hours</span>
                </li>
              </ul>
            </div>

            <button
              onClick={handleScheduleCall}
              className="w-full bg-haven-900 text-white py-3 rounded-xl font-medium hover:bg-haven-800 transition flex items-center justify-center gap-2"
            >
              <Calendar className="w-5 h-5" />
              Schedule Your Intro Call
            </button>

            <button
              onClick={handleComplete}
              className="w-full mt-3 text-gray-500 py-2 text-sm hover:text-haven-900 transition"
            >
              Skip for now → Explore dashboard
            </button>
          </div>
        )}

        {/* Step Indicator */}
        <div className="flex justify-center gap-2 mt-6">
          {steps.map((s, index) => (
            <div
              key={s}
              className={`h-2 rounded-full transition-all duration-300 ${
                index === currentStepIndex
                  ? 'bg-white w-8'
                  : index < currentStepIndex
                    ? 'bg-white/60 w-2'
                    : 'bg-white/30 w-2'
              }`}
            />
          ))}
        </div>
      </div>
    </div>
  );
}
