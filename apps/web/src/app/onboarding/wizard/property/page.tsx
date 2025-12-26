'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import {
  MapPin,
  ArrowRight,
  Upload,
  Building2,
  Home,
  Check,
  X,
  Loader2,
  FileText,
  AlertCircle,
} from 'lucide-react';
import { SkipToHumanBanner } from '@/components/onboarding/SkipToHumanBanner';
import { FormInput, FormSelect } from '@/components/onboarding/forms';
import { useOnboarding } from '@/context/OnboardingContext';
import { getServiceAreaName, PropertyDetails } from '@/types/onboarding';
import { cn } from '@/lib/utils';

const PROPERTY_TYPES = [
  { value: 'single_family', label: 'Single Family Home' },
  { value: 'condo', label: 'Condo / Co-op' },
  { value: 'townhouse', label: 'Townhouse' },
  { value: 'multi_family', label: 'Multi-Family' },
  { value: 'estate', label: 'Estate' },
];

export default function PropertyPage() {
  const router = useRouter();
  const { data, setProperty, completeStep } = useOnboarding();

  // Form state
  const [street, setStreet] = useState(data.property?.address?.street || '');
  const [unit, setUnit] = useState(data.property?.address?.unit || '');
  const [city, setCity] = useState(data.property?.address?.city || '');
  const [state, setState] = useState(data.property?.address?.state || '');
  const [zipCode, setZipCode] = useState(data.property?.address?.zipCode || '');
  const [propertyName, setPropertyName] = useState(data.property?.propertyName || '');
  const [propertyType, setPropertyType] = useState(data.property?.propertyType || 'single_family');
  const [bedrooms, setBedrooms] = useState(data.property?.bedrooms?.toString() || '');
  const [bathrooms, setBathrooms] = useState(data.property?.bathrooms?.toString() || '');
  const [squareFeet, setSquareFeet] = useState(data.property?.squareFeet?.toString() || '');
  const [yearBuilt, setYearBuilt] = useState(data.property?.yearBuilt?.toString() || '');

  // UI state
  const [isValidatingZip, setIsValidatingZip] = useState(false);
  const [serviceArea, setServiceArea] = useState<string | null>(null);
  const [isOutOfArea, setIsOutOfArea] = useState(false);
  const [uploadedFile, setUploadedFile] = useState<File | null>(null);
  const [errors, setErrors] = useState<Record<string, string>>({});

  // Validate ZIP code when it changes
  useEffect(() => {
    if (zipCode.length === 5) {
      setIsValidatingZip(true);
      // Simulate API call
      setTimeout(() => {
        const area = getServiceAreaName(zipCode);
        setServiceArea(area);
        setIsOutOfArea(!area);
        setIsValidatingZip(false);
      }, 500);
    } else {
      setServiceArea(null);
      setIsOutOfArea(false);
    }
  }, [zipCode]);

  const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setUploadedFile(file);
      // TODO: Upload to storage and process
    }
  };

  const validate = (): boolean => {
    const newErrors: Record<string, string> = {};

    if (!street.trim()) newErrors.street = 'Street address is required';
    if (!city.trim()) newErrors.city = 'City is required';
    if (!state.trim()) newErrors.state = 'State is required';
    if (!zipCode.trim()) newErrors.zipCode = 'ZIP code is required';
    if (zipCode && !/^\d{5}(-\d{4})?$/.test(zipCode)) {
      newErrors.zipCode = 'Please enter a valid ZIP code';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleContinue = () => {
    if (!validate()) return;

    const property: PropertyDetails = {
      address: {
        street,
        unit: unit || undefined,
        city,
        state,
        zipCode,
        country: 'USA',
        formatted: `${street}${unit ? ` ${unit}` : ''}, ${city}, ${state} ${zipCode}`,
      },
      propertyName: propertyName || undefined,
      propertyType: propertyType as PropertyDetails['propertyType'],
      bedrooms: bedrooms ? parseInt(bedrooms) : undefined,
      bathrooms: bathrooms ? parseFloat(bathrooms) : undefined,
      squareFeet: squareFeet ? parseInt(squareFeet) : undefined,
      yearBuilt: yearBuilt ? parseInt(yearBuilt) : undefined,
    };

    setProperty(property);
    completeStep('property');
    router.push('/onboarding/wizard/bills');
  };

  return (
    <div className="max-w-2xl mx-auto px-4 py-8">
      <SkipToHumanBanner />

      {/* Header */}
      <div className="text-center mb-8">
        <div className="w-14 h-14 bg-haven-champagne-100 rounded-2xl flex items-center justify-center mx-auto mb-4">
          <Building2 className="w-7 h-7 text-haven-champagne-600" />
        </div>
        <h1 className="text-2xl font-bold text-haven-navy-900 mb-2">
          Let&apos;s start with your property
        </h1>
        <p className="text-gray-600">Enter your address and basic property details.</p>
      </div>

      {/* Form */}
      <div className="bg-white rounded-2xl border border-gray-200 p-6 space-y-6">
        {/* Property Name (Optional) */}
        <FormInput
          label="Property Name (optional)"
          placeholder="e.g., Inspiration Farm, Beach House"
          value={propertyName}
          onChange={(e) => setPropertyName(e.target.value)}
          hint="Give your home a nickname if you'd like"
        />

        {/* Address Section */}
        <div className="space-y-4">
          <h3 className="font-medium text-haven-navy-900">Address</h3>

          <FormInput
            label="Street Address"
            placeholder="123 Main Street"
            value={street}
            onChange={(e) => setStreet(e.target.value)}
            error={errors.street}
            icon={<MapPin className="w-5 h-5" />}
            required
          />

          <FormInput
            label="Unit / Apt (optional)"
            placeholder="Apt 4B"
            value={unit}
            onChange={(e) => setUnit(e.target.value)}
          />

          <div className="grid grid-cols-2 gap-4">
            <FormInput
              label="City"
              placeholder="Greenwich"
              value={city}
              onChange={(e) => setCity(e.target.value)}
              error={errors.city}
              required
            />
            <FormInput
              label="State"
              placeholder="CT"
              value={state}
              onChange={(e) => setState(e.target.value.toUpperCase().slice(0, 2))}
              error={errors.state}
              maxLength={2}
              required
            />
          </div>

          <div className="relative">
            <FormInput
              label="ZIP Code"
              placeholder="06831"
              value={zipCode}
              onChange={(e) => setZipCode(e.target.value.replace(/\D/g, '').slice(0, 5))}
              error={errors.zipCode}
              maxLength={5}
              required
            />

            {/* ZIP Validation Feedback */}
            {isValidatingZip && (
              <div className="flex items-center gap-2 mt-2 text-sm text-gray-500">
                <Loader2 className="w-4 h-4 animate-spin" />
                Checking service area...
              </div>
            )}

            {serviceArea && (
              <div className="flex items-center gap-2 mt-2 text-sm text-green-600">
                <Check className="w-4 h-4" />
                Great! We service {serviceArea}
              </div>
            )}

            {isOutOfArea && (
              <div className="mt-3 p-4 bg-amber-50 border border-amber-200 rounded-xl">
                <div className="flex items-start gap-3">
                  <AlertCircle className="w-5 h-5 text-amber-500 flex-shrink-0 mt-0.5" />
                  <div>
                    <p className="text-sm font-medium text-amber-800">
                      We&apos;re not in your area yet
                    </p>
                    <p className="text-sm text-amber-700 mt-1">
                      We currently service Westchester County, NY and Fairfield County, CT. We can
                      still do a virtual walkthrough via video call!
                    </p>
                    <Link
                      href="/onboarding/schedule?type=virtual"
                      className="inline-flex items-center gap-1 text-sm font-medium text-amber-800 hover:text-amber-900 mt-2"
                    >
                      Schedule virtual walkthrough →
                    </Link>
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Divider */}
        <div className="border-t border-gray-200" />

        {/* Property Details */}
        <div className="space-y-4">
          <h3 className="font-medium text-haven-navy-900">Property Details</h3>

          <FormSelect
            label="Property Type"
            options={PROPERTY_TYPES}
            value={propertyType}
            onChange={(e) => setPropertyType(e.target.value)}
          />

          <div className="grid grid-cols-2 gap-4">
            <FormInput
              label="Bedrooms"
              type="number"
              placeholder="4"
              value={bedrooms}
              onChange={(e) => setBedrooms(e.target.value)}
              min={0}
              max={20}
            />
            <FormInput
              label="Bathrooms"
              type="number"
              placeholder="3.5"
              value={bathrooms}
              onChange={(e) => setBathrooms(e.target.value)}
              min={0}
              max={20}
              step={0.5}
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <FormInput
              label="Square Feet"
              type="number"
              placeholder="2,500"
              value={squareFeet}
              onChange={(e) => setSquareFeet(e.target.value)}
            />
            <FormInput
              label="Year Built"
              type="number"
              placeholder="1985"
              value={yearBuilt}
              onChange={(e) => setYearBuilt(e.target.value)}
              min={1800}
              max={new Date().getFullYear()}
            />
          </div>
        </div>

        {/* Divider */}
        <div className="border-t border-gray-200" />

        {/* Inspection Upload */}
        <div className="space-y-4">
          <h3 className="font-medium text-haven-navy-900">Home Inspection (optional)</h3>
          <p className="text-sm text-gray-500">
            Upload a recent inspection if you have one. We&apos;ll extract system details
            automatically.
          </p>

          {!uploadedFile ? (
            <label className="block border-2 border-dashed border-gray-200 rounded-xl p-8 text-center hover:border-haven-champagne-500 transition-colors cursor-pointer group">
              <input
                type="file"
                className="sr-only"
                accept=".pdf,.jpg,.jpeg,.png"
                onChange={handleFileUpload}
              />
              <Upload className="w-8 h-8 text-gray-400 mx-auto mb-2 group-hover:text-haven-champagne-500" />
              <p className="text-sm text-gray-600">
                Drag & drop or <span className="text-haven-champagne-600 font-medium">browse</span>
              </p>
              <p className="text-xs text-gray-400 mt-1">PDF, JPG, or PNG up to 10MB</p>
            </label>
          ) : (
            <div className="flex items-center gap-4 p-4 bg-gray-50 rounded-xl">
              <div className="w-10 h-10 bg-haven-champagne-100 rounded-lg flex items-center justify-center">
                <FileText className="w-5 h-5 text-haven-champagne-600" />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium text-haven-navy-900 truncate">
                  {uploadedFile.name}
                </p>
                <p className="text-xs text-gray-500">
                  {(uploadedFile.size / 1024 / 1024).toFixed(2)} MB
                </p>
              </div>
              <button onClick={() => setUploadedFile(null)} className="text-gray-400 hover:text-red-500">
                <X className="w-5 h-5" />
              </button>
            </div>
          )}

          {/* Or Get From Town */}
          <div className="relative">
            <div className="absolute inset-0 flex items-center">
              <div className="w-full border-t border-gray-200" />
            </div>
            <div className="relative flex justify-center text-sm">
              <span className="px-3 bg-white text-gray-500">or</span>
            </div>
          </div>

          <button className="w-full py-3 px-4 rounded-xl border border-gray-200 hover:bg-gray-50 text-gray-700 font-medium transition-colors flex items-center justify-center gap-2">
            <Home className="w-5 h-5" />
            Get my inspection from town records
          </button>
          <p className="text-xs text-gray-400 text-center">
            We&apos;ll request your inspection report from local records (may take 1-2 business days)
          </p>
        </div>
      </div>

      {/* Navigation */}
      <div className="flex justify-between mt-8">
        <Link
          href="/onboarding/choose-path"
          className="text-gray-600 hover:text-haven-navy-900 py-3 px-4 font-medium transition-colors"
        >
          ← Back
        </Link>
        <button
          onClick={handleContinue}
          className="bg-haven-navy-900 hover:bg-haven-navy-800 text-white py-3 px-6 rounded-xl font-medium flex items-center gap-2 transition-colors"
        >
          Continue
          <ArrowRight className="w-4 h-4" />
        </button>
      </div>
    </div>
  );
}
