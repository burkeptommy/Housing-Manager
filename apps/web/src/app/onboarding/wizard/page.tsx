'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Home, CheckCircle, Sparkles, ArrowRight, Loader2, Building2 } from 'lucide-react';
import { AddressAutocomplete } from '@/components/onboarding/AddressAutocomplete';
import { usePropertyEnrichment, PropertyDetails } from '@/hooks/usePropertyEnrichment';
import { useOnboarding } from '@/context/OnboardingContext';
import { useAuth } from '@/contexts/auth-context';

type Step = 'address' | 'confirm' | 'welcome';

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

  const [step, setStep] = useState<Step>('address');
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

      // TODO: Call API to create household and generate checklist
      // await createHouseholdWithChecklist(propertyData);

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

  const handleAddMoreDetails = () => {
    router.push('/app/home/setup');
  };

  const userName = user?.displayName?.split(' ')[0] || 'there';

  return (
    <div className="min-h-screen bg-gradient-to-br from-haven-navy-950 to-haven-navy-900 flex items-center justify-center p-4">
      <div className="w-full max-w-lg">

        {/* Step 1: Address */}
        {step === 'address' && (
          <div className="bg-white rounded-2xl p-8 shadow-2xl">
            <div className="text-center mb-8">
              <div className="w-16 h-16 bg-haven-champagne-100 rounded-2xl flex items-center justify-center mx-auto mb-4">
                <Home className="w-8 h-8 text-haven-champagne-600" />
              </div>
              <h1 className="text-2xl font-bold text-haven-navy-900">
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
              <div className="mt-6 flex items-center justify-center gap-3 text-haven-navy-600">
                <Loader2 className="w-5 h-5 animate-spin" />
                <span>Finding your home details...</span>
              </div>
            )}

            <p className="text-xs text-gray-400 text-center mt-6">
              We&apos;ll look up your property details from public records
            </p>
          </div>
        )}

        {/* Step 2: Confirm Details */}
        {step === 'confirm' && (
          <div className="bg-white rounded-2xl p-8 shadow-2xl">
            <div className="text-center mb-6">
              <div className="w-16 h-16 bg-emerald-100 rounded-2xl flex items-center justify-center mx-auto mb-4">
                <Sparkles className="w-8 h-8 text-emerald-600" />
              </div>
              <h1 className="text-2xl font-bold text-haven-navy-900">
                {propertyData.enrichment ? 'We found your home!' : 'Confirm your address'}
              </h1>
              <p className="text-gray-500 mt-2">
                {propertyData.enrichment
                  ? 'Confirm these details are correct'
                  : 'Add some details about your property'
                }
              </p>
            </div>

            {/* Address Display */}
            <div className="bg-gray-50 rounded-xl p-4 mb-6">
              <div className="flex items-start gap-3">
                <Building2 className="w-5 h-5 text-gray-400 mt-0.5" />
                <div>
                  <p className="font-medium text-haven-navy-900">
                    {propertyData.street}
                  </p>
                  <p className="text-gray-500 text-sm">
                    {propertyData.city}, {propertyData.state} {propertyData.zipCode}
                  </p>
                </div>
              </div>
            </div>

            {/* Property Details Grid */}
            <div className="grid grid-cols-2 gap-4 mb-6">
              <div>
                <label className="block text-sm text-gray-500 mb-1">Bedrooms</label>
                <input
                  type="number"
                  value={propertyData.bedrooms}
                  onChange={(e) => setPropertyData(prev => ({ ...prev, bedrooms: e.target.value }))}
                  className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:border-haven-champagne-500 focus:ring-2 focus:ring-haven-champagne-100 outline-none transition"
                  placeholder="—"
                />
              </div>
              <div>
                <label className="block text-sm text-gray-500 mb-1">Bathrooms</label>
                <input
                  type="number"
                  step="0.5"
                  value={propertyData.bathrooms}
                  onChange={(e) => setPropertyData(prev => ({ ...prev, bathrooms: e.target.value }))}
                  className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:border-haven-champagne-500 focus:ring-2 focus:ring-haven-champagne-100 outline-none transition"
                  placeholder="—"
                />
              </div>
              <div>
                <label className="block text-sm text-gray-500 mb-1">Square Feet</label>
                <input
                  type="number"
                  value={propertyData.squareFeet}
                  onChange={(e) => setPropertyData(prev => ({ ...prev, squareFeet: e.target.value }))}
                  className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:border-haven-champagne-500 focus:ring-2 focus:ring-haven-champagne-100 outline-none transition"
                  placeholder="—"
                />
              </div>
              <div>
                <label className="block text-sm text-gray-500 mb-1">Year Built</label>
                <input
                  type="number"
                  value={propertyData.yearBuilt}
                  onChange={(e) => setPropertyData(prev => ({ ...prev, yearBuilt: e.target.value }))}
                  className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:border-haven-champagne-500 focus:ring-2 focus:ring-haven-champagne-100 outline-none transition"
                  placeholder="—"
                />
              </div>
            </div>

            {/* Property Type */}
            {propertyData.propertyType && (
              <div className="mb-6">
                <label className="block text-sm text-gray-500 mb-1">Property Type</label>
                <div className="px-4 py-2.5 bg-gray-50 rounded-xl text-haven-navy-900">
                  {PROPERTY_TYPE_LABELS[propertyData.propertyType] || propertyData.propertyType}
                </div>
              </div>
            )}

            {propertyData.enrichment && (
              <p className="text-xs text-emerald-600 text-center mb-6 flex items-center justify-center gap-1">
                <Sparkles className="w-3 h-3" />
                Details auto-filled from public property records
              </p>
            )}

            <button
              onClick={handleConfirm}
              disabled={isSaving}
              className="w-full bg-haven-navy-900 text-white py-3 rounded-xl font-medium hover:bg-haven-navy-800 transition flex items-center justify-center gap-2 disabled:opacity-50"
            >
              {isSaving ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" />
                  Setting up...
                </>
              ) : (
                <>
                  Continue
                  <ArrowRight className="w-4 h-4" />
                </>
              )}
            </button>

            <button
              onClick={() => setStep('address')}
              className="w-full mt-3 text-gray-500 py-2 text-sm hover:text-haven-navy-900 transition"
            >
              ← Change address
            </button>
          </div>
        )}

        {/* Step 3: Welcome */}
        {step === 'welcome' && (
          <div className="bg-white rounded-2xl p-8 shadow-2xl text-center">
            <div className="w-20 h-20 bg-emerald-100 rounded-full flex items-center justify-center mx-auto mb-6">
              <CheckCircle className="w-10 h-10 text-emerald-600" />
            </div>

            <h1 className="text-2xl font-bold text-haven-navy-900 mb-2">
              Welcome to Haven, {userName}!
            </h1>

            <p className="text-gray-500 mb-8">
              Your Home Manager <strong className="text-haven-navy-900">Sarah</strong> will reach out within 24 hours
              to complete your home profile and learn about your needs.
            </p>

            <div className="bg-haven-champagne-50 rounded-xl p-5 mb-8 text-left">
              <h3 className="font-semibold text-haven-navy-900 mb-3">
                What happens next?
              </h3>
              <ul className="space-y-3 text-sm text-gray-600">
                <li className="flex items-start gap-3">
                  <CheckCircle className="w-5 h-5 text-emerald-500 mt-0.5 flex-shrink-0" />
                  <span>Sarah will call to introduce herself and learn about your home</span>
                </li>
                <li className="flex items-start gap-3">
                  <CheckCircle className="w-5 h-5 text-emerald-500 mt-0.5 flex-shrink-0" />
                  <span>She&apos;ll gather info about your home systems, utilities, and vendors</span>
                </li>
                <li className="flex items-start gap-3">
                  <CheckCircle className="w-5 h-5 text-emerald-500 mt-0.5 flex-shrink-0" />
                  <span>Your personalized home profile will be ready within 48 hours</span>
                </li>
              </ul>
            </div>

            {/* Property Summary */}
            {propertyData.enrichment && (
              <div className="bg-gray-50 rounded-xl p-4 mb-6 text-left">
                <h4 className="text-xs font-medium text-gray-500 uppercase tracking-wide mb-2">
                  What we already know
                </h4>
                <div className="grid grid-cols-2 gap-2 text-sm">
                  {propertyData.bedrooms && (
                    <div><span className="text-gray-500">Bedrooms:</span> <span className="font-medium">{propertyData.bedrooms}</span></div>
                  )}
                  {propertyData.bathrooms && (
                    <div><span className="text-gray-500">Bathrooms:</span> <span className="font-medium">{propertyData.bathrooms}</span></div>
                  )}
                  {propertyData.squareFeet && (
                    <div><span className="text-gray-500">Sq Ft:</span> <span className="font-medium">{parseInt(propertyData.squareFeet).toLocaleString()}</span></div>
                  )}
                  {propertyData.yearBuilt && (
                    <div><span className="text-gray-500">Year Built:</span> <span className="font-medium">{propertyData.yearBuilt}</span></div>
                  )}
                  {propertyData.enrichment.heatingType && (
                    <div><span className="text-gray-500">Heating:</span> <span className="font-medium">{propertyData.enrichment.heatingType}</span></div>
                  )}
                  {propertyData.enrichment.coolingType && (
                    <div><span className="text-gray-500">Cooling:</span> <span className="font-medium">{propertyData.enrichment.coolingType}</span></div>
                  )}
                </div>
              </div>
            )}

            <button
              onClick={handleComplete}
              className="w-full bg-haven-navy-900 text-white py-3 rounded-xl font-medium hover:bg-haven-navy-800 transition"
            >
              Go to Dashboard
            </button>

            <button
              onClick={handleAddMoreDetails}
              className="w-full mt-3 text-haven-champagne-600 py-2 text-sm hover:text-haven-champagne-700 font-medium transition"
            >
              Or add more details yourself →
            </button>
          </div>
        )}

        {/* Step Indicator */}
        <div className="flex justify-center gap-2 mt-6">
          {['address', 'confirm', 'welcome'].map((s) => (
            <div
              key={s}
              className={`w-2 h-2 rounded-full transition-all ${
                step === s ? 'bg-white w-6' : 'bg-white/30'
              }`}
            />
          ))}
        </div>
      </div>
    </div>
  );
}
