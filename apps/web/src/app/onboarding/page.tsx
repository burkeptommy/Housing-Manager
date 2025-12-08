'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { useAuth } from '@/contexts/auth-context';
import { getApiClient } from '@/lib/api';
import type { HomeSystems, OnboardingPreferences } from '@haven/core';
import {
  basicInfoSchema,
  systemsSchema,
  painPointsSchema,
  communicationSchema,
  propertyTypeOptions,
  hvacTypeOptions,
  roofTypeOptions,
  waterHeaterTypeOptions,
  painPointOptions,
  communicationOptions,
  usStates,
  type BasicInfoData,
  type SystemsData,
  type PainPointsData,
  type CommunicationData,
} from '@/lib/validations/onboarding';

const STEPS = [
  { id: 1, name: 'Home Info', description: 'Basic property details' },
  { id: 2, name: 'Systems', description: 'Home systems overview' },
  { id: 3, name: 'Pain Points', description: 'What challenges you face' },
  { id: 4, name: 'Preferences', description: 'How to reach you' },
];

export default function OnboardingPage() {
  const router = useRouter();
  const { isAuthenticated, isLoading, needsOnboarding, completeOnboarding, user } = useAuth();
  const [currentStep, setCurrentStep] = useState(1);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');

  // Store data from each step
  const [basicInfo, setBasicInfo] = useState<BasicInfoData | null>(null);
  const [systems, setSystems] = useState<SystemsData | null>(null);
  const [painPoints, setPainPoints] = useState<PainPointsData | null>(null);

  const api = getApiClient();

  // Redirect if not authenticated or doesn't need onboarding
  useEffect(() => {
    if (!isLoading && !isAuthenticated) {
      router.push('/login');
    } else if (!isLoading && isAuthenticated && !needsOnboarding) {
      router.push('/app');
    }
  }, [isLoading, isAuthenticated, needsOnboarding, router]);

  const handleBasicInfoSubmit = (data: BasicInfoData) => {
    setBasicInfo(data);
    setCurrentStep(2);
  };

  const handleSystemsSubmit = (data: SystemsData) => {
    setSystems(data);
    setCurrentStep(3);
  };

  const handlePainPointsSubmit = (data: PainPointsData) => {
    setPainPoints(data);
    setCurrentStep(4);
  };

  const handleCommunicationSubmit = async (data: CommunicationData) => {
    if (!basicInfo || !systems || !painPoints) return;

    setIsSubmitting(true);
    setError('');

    try {
      // Create household
      const household = await api.createHousehold({
        name: basicInfo.name,
        description: `${basicInfo.propertyType} in ${basicInfo.city}, ${basicInfo.state}`,
      });

      // Prepare extended data for notes field
      const extendedData: { systems: HomeSystems; preferences: OnboardingPreferences } = {
        systems: {
          hvacType: systems.hvacType,
          hvacAge: systems.hvacAge,
          roofType: systems.roofType,
          roofAge: systems.roofAge,
          waterHeaterType: systems.waterHeaterType,
          waterHeaterAge: systems.waterHeaterAge,
          septicOrSewer: systems.septicOrSewer,
          septicLastServiced: systems.septicLastServiced,
          electricalPanelAmps: systems.electricalPanelAmps,
          hasPool: systems.hasPool,
          hasSprinklerSystem: systems.hasSprinklerSystem,
          hasSecuritySystem: systems.hasSecuritySystem,
          hasSmartHome: systems.hasSmartHome,
        },
        preferences: {
          painPoints: painPoints.painPoints,
          communicationChannels: data.communicationChannels,
        },
      };

      // Create home profile with extended data in notes
      await api.upsertHomeProfile(household.id, {
        propertyType: basicInfo.propertyType,
        addressLine1: basicInfo.addressLine1,
        addressLine2: basicInfo.addressLine2,
        city: basicInfo.city,
        state: basicInfo.state,
        postalCode: basicInfo.postalCode,
        country: 'US',
        yearBuilt: basicInfo.yearBuilt,
        bedrooms: basicInfo.bedrooms,
        bathrooms: basicInfo.bathrooms,
        squareFeet: basicInfo.squareFeet,
        notes: JSON.stringify(extendedData),
      });

      await completeOnboarding(household.id);
    } catch (err: unknown) {
      const message =
        err && typeof err === 'object' && 'message' in err
          ? (err as { message: string }).message
          : 'Failed to complete setup. Please try again.';
      setError(message);
    } finally {
      setIsSubmitting(false);
    }
  };

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-slate-50 dark:bg-slate-900">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-slate-600 dark:text-slate-400">Loading...</p>
        </div>
      </div>
    );
  }

  if (!isAuthenticated) {
    return null;
  }

  return (
    <div className="min-h-screen bg-slate-50 dark:bg-slate-900 py-8 px-4">
      <div className="max-w-2xl mx-auto">
        {/* Header */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-blue-600 text-white mb-4">
            <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"
              />
            </svg>
          </div>
          <h1 className="text-2xl font-bold text-slate-900 dark:text-white">
            Welcome, {user?.firstName}!
          </h1>
          <p className="text-slate-600 dark:text-slate-400 mt-1">
            Let&apos;s set up your home profile
          </p>
        </div>

        {/* Progress Steps */}
        <div className="mb-8">
          <div className="flex items-center justify-between">
            {STEPS.map((step, idx) => (
              <div key={step.id} className="flex items-center">
                <div
                  className={`flex items-center justify-center w-10 h-10 rounded-full border-2 transition-colors ${
                    currentStep > step.id
                      ? 'bg-blue-600 border-blue-600 text-white'
                      : currentStep === step.id
                        ? 'border-blue-600 text-blue-600'
                        : 'border-slate-300 dark:border-slate-600 text-slate-400'
                  }`}
                >
                  {currentStep > step.id ? (
                    <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                      <path
                        fillRule="evenodd"
                        d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                        clipRule="evenodd"
                      />
                    </svg>
                  ) : (
                    step.id
                  )}
                </div>
                {idx < STEPS.length - 1 && (
                  <div
                    className={`w-12 sm:w-20 h-1 mx-2 rounded ${
                      currentStep > step.id ? 'bg-blue-600' : 'bg-slate-200 dark:bg-slate-700'
                    }`}
                  />
                )}
              </div>
            ))}
          </div>
          <div className="flex justify-between mt-2">
            {STEPS.map((step) => (
              <div key={step.id} className="text-center" style={{ width: '80px' }}>
                <p
                  className={`text-xs font-medium ${
                    currentStep >= step.id
                      ? 'text-slate-900 dark:text-white'
                      : 'text-slate-400 dark:text-slate-500'
                  }`}
                >
                  {step.name}
                </p>
              </div>
            ))}
          </div>
        </div>

        {/* Error Display */}
        {error && (
          <div className="mb-6 p-4 rounded-lg bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800">
            <p className="text-sm text-red-600 dark:text-red-400">{error}</p>
          </div>
        )}

        {/* Step Content */}
        <div className="card">
          {currentStep === 1 && (
            <BasicInfoStep onSubmit={handleBasicInfoSubmit} defaultValues={basicInfo} />
          )}
          {currentStep === 2 && (
            <SystemsStep
              onSubmit={handleSystemsSubmit}
              onBack={() => setCurrentStep(1)}
              defaultValues={systems}
            />
          )}
          {currentStep === 3 && (
            <PainPointsStep
              onSubmit={handlePainPointsSubmit}
              onBack={() => setCurrentStep(2)}
              defaultValues={painPoints}
            />
          )}
          {currentStep === 4 && (
            <CommunicationStep
              onSubmit={handleCommunicationSubmit}
              onBack={() => setCurrentStep(3)}
              isSubmitting={isSubmitting}
            />
          )}
        </div>
      </div>
    </div>
  );
}

// Step 1: Basic Home Info
function BasicInfoStep({
  onSubmit,
  defaultValues,
}: {
  onSubmit: (data: BasicInfoData) => void;
  defaultValues: BasicInfoData | null;
}) {
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<BasicInfoData>({
    resolver: zodResolver(basicInfoSchema),
    defaultValues: defaultValues || {
      name: '',
      propertyType: 'SINGLE_FAMILY',
      addressLine1: '',
      addressLine2: '',
      city: '',
      state: '',
      postalCode: '',
    },
  });

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
      <div>
        <h2 className="text-lg font-semibold text-slate-900 dark:text-white mb-1">
          Tell us about your home
        </h2>
        <p className="text-sm text-slate-600 dark:text-slate-400">
          We&apos;ll use this to personalize your experience
        </p>
      </div>

      <div>
        <label htmlFor="name" className="label block mb-1.5">
          Home name
        </label>
        <input
          {...register('name')}
          id="name"
          type="text"
          className="input"
          placeholder="e.g., Main Residence, Beach House"
        />
        {errors.name && <p className="text-sm text-red-500 mt-1">{errors.name.message}</p>}
      </div>

      <div>
        <label htmlFor="propertyType" className="label block mb-1.5">
          Property type
        </label>
        <select {...register('propertyType')} id="propertyType" className="input">
          {propertyTypeOptions.map((opt) => (
            <option key={opt.value} value={opt.value}>
              {opt.label}
            </option>
          ))}
        </select>
        {errors.propertyType && (
          <p className="text-sm text-red-500 mt-1">{errors.propertyType.message}</p>
        )}
      </div>

      <div>
        <label htmlFor="addressLine1" className="label block mb-1.5">
          Street address
        </label>
        <input
          {...register('addressLine1')}
          id="addressLine1"
          type="text"
          className="input"
          placeholder="123 Main Street"
        />
        {errors.addressLine1 && (
          <p className="text-sm text-red-500 mt-1">{errors.addressLine1.message}</p>
        )}
      </div>

      <div>
        <label htmlFor="addressLine2" className="label block mb-1.5">
          Apt, suite, etc. (optional)
        </label>
        <input
          {...register('addressLine2')}
          id="addressLine2"
          type="text"
          className="input"
          placeholder="Apt 4B"
        />
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div>
          <label htmlFor="city" className="label block mb-1.5">
            City
          </label>
          <input {...register('city')} id="city" type="text" className="input" placeholder="City" />
          {errors.city && <p className="text-sm text-red-500 mt-1">{errors.city.message}</p>}
        </div>
        <div>
          <label htmlFor="state" className="label block mb-1.5">
            State
          </label>
          <select {...register('state')} id="state" className="input">
            <option value="">Select state</option>
            {usStates.map((s) => (
              <option key={s.value} value={s.value}>
                {s.label}
              </option>
            ))}
          </select>
          {errors.state && <p className="text-sm text-red-500 mt-1">{errors.state.message}</p>}
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div>
          <label htmlFor="postalCode" className="label block mb-1.5">
            ZIP code
          </label>
          <input
            {...register('postalCode')}
            id="postalCode"
            type="text"
            className="input"
            placeholder="12345"
          />
          {errors.postalCode && (
            <p className="text-sm text-red-500 mt-1">{errors.postalCode.message}</p>
          )}
        </div>
        <div>
          <label htmlFor="yearBuilt" className="label block mb-1.5">
            Year built (optional)
          </label>
          <input
            {...register('yearBuilt')}
            id="yearBuilt"
            type="number"
            className="input"
            placeholder="1990"
          />
          {errors.yearBuilt && (
            <p className="text-sm text-red-500 mt-1">{errors.yearBuilt.message}</p>
          )}
        </div>
      </div>

      <div className="grid grid-cols-3 gap-4">
        <div>
          <label htmlFor="bedrooms" className="label block mb-1.5">
            Bedrooms
          </label>
          <input
            {...register('bedrooms')}
            id="bedrooms"
            type="number"
            className="input"
            placeholder="3"
          />
        </div>
        <div>
          <label htmlFor="bathrooms" className="label block mb-1.5">
            Bathrooms
          </label>
          <input
            {...register('bathrooms')}
            id="bathrooms"
            type="number"
            step="0.5"
            className="input"
            placeholder="2"
          />
        </div>
        <div>
          <label htmlFor="squareFeet" className="label block mb-1.5">
            Sq ft
          </label>
          <input
            {...register('squareFeet')}
            id="squareFeet"
            type="number"
            className="input"
            placeholder="2000"
          />
        </div>
      </div>

      <div className="pt-4">
        <button type="submit" className="btn btn-primary w-full">
          Continue
        </button>
      </div>
    </form>
  );
}

// Step 2: Systems Overview
function SystemsStep({
  onSubmit,
  onBack,
  defaultValues,
}: {
  onSubmit: (data: SystemsData) => void;
  onBack: () => void;
  defaultValues: SystemsData | null;
}) {
  const {
    register,
    handleSubmit,
    watch,
    formState: { errors },
  } = useForm<SystemsData>({
    resolver: zodResolver(systemsSchema),
    defaultValues: defaultValues || {},
  });

  const septicOrSewer = watch('septicOrSewer');

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
      <div>
        <h2 className="text-lg font-semibold text-slate-900 dark:text-white mb-1">
          Home systems overview
        </h2>
        <p className="text-sm text-slate-600 dark:text-slate-400">
          Help us understand your home&apos;s systems (all optional)
        </p>
      </div>

      {/* HVAC */}
      <div className="grid grid-cols-2 gap-4">
        <div>
          <label htmlFor="hvacType" className="label block mb-1.5">
            HVAC type
          </label>
          <select {...register('hvacType')} id="hvacType" className="input">
            <option value="">Select type</option>
            {hvacTypeOptions.map((opt) => (
              <option key={opt.value} value={opt.value}>
                {opt.label}
              </option>
            ))}
          </select>
        </div>
        <div>
          <label htmlFor="hvacAge" className="label block mb-1.5">
            HVAC age (years)
          </label>
          <input
            {...register('hvacAge')}
            id="hvacAge"
            type="number"
            className="input"
            placeholder="5"
          />
        </div>
      </div>

      {/* Roof */}
      <div className="grid grid-cols-2 gap-4">
        <div>
          <label htmlFor="roofType" className="label block mb-1.5">
            Roof type
          </label>
          <select {...register('roofType')} id="roofType" className="input">
            <option value="">Select type</option>
            {roofTypeOptions.map((opt) => (
              <option key={opt.value} value={opt.value}>
                {opt.label}
              </option>
            ))}
          </select>
        </div>
        <div>
          <label htmlFor="roofAge" className="label block mb-1.5">
            Roof age (years)
          </label>
          <input
            {...register('roofAge')}
            id="roofAge"
            type="number"
            className="input"
            placeholder="10"
          />
        </div>
      </div>

      {/* Water Heater */}
      <div className="grid grid-cols-2 gap-4">
        <div>
          <label htmlFor="waterHeaterType" className="label block mb-1.5">
            Water heater type
          </label>
          <select {...register('waterHeaterType')} id="waterHeaterType" className="input">
            <option value="">Select type</option>
            {waterHeaterTypeOptions.map((opt) => (
              <option key={opt.value} value={opt.value}>
                {opt.label}
              </option>
            ))}
          </select>
        </div>
        <div>
          <label htmlFor="waterHeaterAge" className="label block mb-1.5">
            Water heater age (years)
          </label>
          <input
            {...register('waterHeaterAge')}
            id="waterHeaterAge"
            type="number"
            className="input"
            placeholder="8"
          />
        </div>
      </div>

      {/* Septic/Sewer */}
      <div className="grid grid-cols-2 gap-4">
        <div>
          <label htmlFor="septicOrSewer" className="label block mb-1.5">
            Waste system
          </label>
          <select {...register('septicOrSewer')} id="septicOrSewer" className="input">
            <option value="">Select type</option>
            <option value="sewer">Municipal sewer</option>
            <option value="septic">Septic system</option>
          </select>
        </div>
        {septicOrSewer === 'septic' && (
          <div>
            <label htmlFor="septicLastServiced" className="label block mb-1.5">
              Last serviced
            </label>
            <input
              {...register('septicLastServiced')}
              id="septicLastServiced"
              type="date"
              className="input"
            />
          </div>
        )}
      </div>

      {/* Electrical */}
      <div className="w-1/2">
        <label htmlFor="electricalPanelAmps" className="label block mb-1.5">
          Electrical panel (amps)
        </label>
        <select {...register('electricalPanelAmps')} id="electricalPanelAmps" className="input">
          <option value="">Select amperage</option>
          <option value="100">100 amps</option>
          <option value="150">150 amps</option>
          <option value="200">200 amps</option>
          <option value="400">400 amps</option>
        </select>
      </div>

      {/* Features */}
      <div>
        <label className="label block mb-3">Home features</label>
        <div className="grid grid-cols-2 gap-3">
          {[
            { name: 'hasPool', label: 'Swimming pool' },
            { name: 'hasSprinklerSystem', label: 'Sprinkler system' },
            { name: 'hasSecuritySystem', label: 'Security system' },
            { name: 'hasSmartHome', label: 'Smart home devices' },
          ].map((feature) => (
            <label
              key={feature.name}
              className="flex items-center gap-3 p-3 rounded-lg border border-slate-200 dark:border-slate-700 cursor-pointer hover:bg-slate-50 dark:hover:bg-slate-800"
            >
              <input
                type="checkbox"
                {...register(feature.name as keyof SystemsData)}
                className="w-4 h-4 text-blue-600 rounded border-slate-300 dark:border-slate-600"
              />
              <span className="text-sm text-slate-700 dark:text-slate-300">{feature.label}</span>
            </label>
          ))}
        </div>
      </div>

      <div className="flex gap-3 pt-4">
        <button type="button" onClick={onBack} className="btn btn-secondary flex-1">
          Back
        </button>
        <button type="submit" className="btn btn-primary flex-1">
          Continue
        </button>
      </div>
    </form>
  );
}

// Step 3: Pain Points
function PainPointsStep({
  onSubmit,
  onBack,
  defaultValues,
}: {
  onSubmit: (data: PainPointsData) => void;
  onBack: () => void;
  defaultValues: PainPointsData | null;
}) {
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<PainPointsData>({
    resolver: zodResolver(painPointsSchema),
    defaultValues: defaultValues || { painPoints: [] },
  });

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
      <div>
        <h2 className="text-lg font-semibold text-slate-900 dark:text-white mb-1">
          What challenges do you face?
        </h2>
        <p className="text-sm text-slate-600 dark:text-slate-400">
          Select all that apply so we can help you better
        </p>
      </div>

      <div className="space-y-3">
        {painPointOptions.map((option) => (
          <label
            key={option.value}
            className="flex items-center gap-4 p-4 rounded-lg border border-slate-200 dark:border-slate-700 cursor-pointer hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors"
          >
            <input
              type="checkbox"
              value={option.value}
              {...register('painPoints')}
              className="w-5 h-5 text-blue-600 rounded border-slate-300 dark:border-slate-600"
            />
            <div className="flex items-center gap-3">
              <span className="text-2xl">
                {option.value === 'maintenance_scheduling' && '📅'}
                {option.value === 'finding_vendors' && '🔧'}
                {option.value === 'tracking_bills' && '📄'}
                {option.value === 'household_supplies' && '🧹'}
                {option.value === 'pet_care' && '🐾'}
                {option.value === 'vehicle_maintenance' && '🚗'}
              </span>
              <span className="text-slate-700 dark:text-slate-300 font-medium">{option.label}</span>
            </div>
          </label>
        ))}
      </div>

      {errors.painPoints && (
        <p className="text-sm text-red-500">{errors.painPoints.message}</p>
      )}

      <div className="flex gap-3 pt-4">
        <button type="button" onClick={onBack} className="btn btn-secondary flex-1">
          Back
        </button>
        <button type="submit" className="btn btn-primary flex-1">
          Continue
        </button>
      </div>
    </form>
  );
}

// Step 4: Communication Preferences
function CommunicationStep({
  onSubmit,
  onBack,
  isSubmitting,
}: {
  onSubmit: (data: CommunicationData) => void;
  onBack: () => void;
  isSubmitting: boolean;
}) {
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<CommunicationData>({
    resolver: zodResolver(communicationSchema),
    defaultValues: { communicationChannels: ['app'] },
  });

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
      <div>
        <h2 className="text-lg font-semibold text-slate-900 dark:text-white mb-1">
          How should we reach you?
        </h2>
        <p className="text-sm text-slate-600 dark:text-slate-400">
          Select your preferred communication channels
        </p>
      </div>

      <div className="space-y-3">
        {communicationOptions.map((option) => (
          <label
            key={option.value}
            className="flex items-start gap-4 p-4 rounded-lg border border-slate-200 dark:border-slate-700 cursor-pointer hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors"
          >
            <input
              type="checkbox"
              value={option.value}
              {...register('communicationChannels')}
              className="w-5 h-5 mt-0.5 text-blue-600 rounded border-slate-300 dark:border-slate-600"
            />
            <div>
              <div className="flex items-center gap-2">
                <span className="text-xl">
                  {option.value === 'email' && '📧'}
                  {option.value === 'sms' && '📱'}
                  {option.value === 'app' && '🔔'}
                </span>
                <span className="text-slate-700 dark:text-slate-300 font-medium">
                  {option.label}
                </span>
              </div>
              <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
                {option.description}
              </p>
            </div>
          </label>
        ))}
      </div>

      {errors.communicationChannels && (
        <p className="text-sm text-red-500">{errors.communicationChannels.message}</p>
      )}

      <div className="flex gap-3 pt-4">
        <button
          type="button"
          onClick={onBack}
          disabled={isSubmitting}
          className="btn btn-secondary flex-1"
        >
          Back
        </button>
        <button type="submit" disabled={isSubmitting} className="btn btn-primary flex-1">
          {isSubmitting ? (
            <>
              <svg className="animate-spin -ml-1 mr-2 h-4 w-4" fill="none" viewBox="0 0 24 24">
                <circle
                  className="opacity-25"
                  cx="12"
                  cy="12"
                  r="10"
                  stroke="currentColor"
                  strokeWidth="4"
                />
                <path
                  className="opacity-75"
                  fill="currentColor"
                  d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                />
              </svg>
              Setting up...
            </>
          ) : (
            'Complete Setup'
          )}
        </button>
      </div>
    </form>
  );
}
