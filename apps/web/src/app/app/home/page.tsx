'use client';

import { useState, useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { useAuth } from '@/contexts/auth-context';
import { getApiClient } from '@/lib/api';
import type { HomeProfile, HomeSystems, OnboardingPreferences } from '@haven/core';
import {
  basicInfoSchema,
  systemsSchema,
  propertyTypeOptions,
  hvacTypeOptions,
  roofTypeOptions,
  waterHeaterTypeOptions,
  painPointOptions,
  communicationOptions,
  usStates,
  type BasicInfoData,
  type SystemsData,
} from '@/lib/validations/onboarding';

interface ExtendedProfileData {
  systems?: HomeSystems;
  preferences?: OnboardingPreferences;
}

function parseExtendedData(notes: string | null | undefined): ExtendedProfileData {
  if (!notes) return {};
  try {
    return JSON.parse(notes);
  } catch {
    return {};
  }
}

export default function HomeProfilePage() {
  const { currentHousehold, refreshCurrentHousehold } = useAuth();
  const [isLoading, setIsLoading] = useState(true);
  const [homeProfile, setHomeProfile] = useState<HomeProfile | null>(null);
  const [extendedData, setExtendedData] = useState<ExtendedProfileData>({});
  const [editSection, setEditSection] = useState<string | null>(null);
  const [isSaving, setIsSaving] = useState(false);
  const [error, setError] = useState('');
  const [successMessage, setSuccessMessage] = useState('');

  const api = getApiClient();

  useEffect(() => {
    const loadProfile = async () => {
      if (!currentHousehold) return;

      setIsLoading(true);
      try {
        const profile = await api.getHomeProfile(currentHousehold.id);
        setHomeProfile(profile);
        if (profile) {
          setExtendedData(parseExtendedData(profile.notes));
        }
      } catch {
        // Profile may not exist yet
      } finally {
        setIsLoading(false);
      }
    };

    loadProfile();
  }, [api, currentHousehold]);

  const handleSaveBasicInfo = async (data: BasicInfoData) => {
    if (!currentHousehold) return;

    setIsSaving(true);
    setError('');

    try {
      const updatedProfile = await api.upsertHomeProfile(currentHousehold.id, {
        propertyType: data.propertyType,
        addressLine1: data.addressLine1,
        addressLine2: data.addressLine2,
        city: data.city,
        state: data.state,
        postalCode: data.postalCode,
        country: 'US',
        yearBuilt: data.yearBuilt,
        bedrooms: data.bedrooms,
        bathrooms: data.bathrooms,
        squareFeet: data.squareFeet,
        notes: homeProfile?.notes,
      });

      setHomeProfile(updatedProfile);
      setEditSection(null);
      setSuccessMessage('Home information updated successfully');
      setTimeout(() => setSuccessMessage(''), 3000);

      // Update household name if changed
      if (data.name !== currentHousehold.name) {
        await api.updateHousehold(currentHousehold.id, { name: data.name });
        await refreshCurrentHousehold();
      }
    } catch (err: unknown) {
      const message =
        err && typeof err === 'object' && 'message' in err
          ? (err as { message: string }).message
          : 'Failed to save. Please try again.';
      setError(message);
    } finally {
      setIsSaving(false);
    }
  };

  const handleSaveSystems = async (data: SystemsData) => {
    if (!currentHousehold || !homeProfile) return;

    setIsSaving(true);
    setError('');

    try {
      const newExtendedData = {
        ...extendedData,
        systems: data as HomeSystems,
      };

      const updatedProfile = await api.upsertHomeProfile(currentHousehold.id, {
        propertyType: homeProfile.propertyType,
        addressLine1: homeProfile.addressLine1,
        addressLine2: homeProfile.addressLine2 || undefined,
        city: homeProfile.city,
        state: homeProfile.state,
        postalCode: homeProfile.postalCode,
        country: homeProfile.country,
        yearBuilt: homeProfile.yearBuilt || undefined,
        bedrooms: homeProfile.bedrooms || undefined,
        bathrooms: homeProfile.bathrooms || undefined,
        squareFeet: homeProfile.squareFeet || undefined,
        notes: JSON.stringify(newExtendedData),
      });

      setHomeProfile(updatedProfile);
      setExtendedData(newExtendedData);
      setEditSection(null);
      setSuccessMessage('Systems information updated successfully');
      setTimeout(() => setSuccessMessage(''), 3000);
    } catch (err: unknown) {
      const message =
        err && typeof err === 'object' && 'message' in err
          ? (err as { message: string }).message
          : 'Failed to save. Please try again.';
      setError(message);
    } finally {
      setIsSaving(false);
    }
  };

  const handleSavePreferences = async (painPoints: string[], channels: string[]) => {
    if (!currentHousehold || !homeProfile) return;

    setIsSaving(true);
    setError('');

    try {
      const newExtendedData = {
        ...extendedData,
        preferences: {
          painPoints: painPoints as OnboardingPreferences['painPoints'],
          communicationChannels: channels as OnboardingPreferences['communicationChannels'],
        },
      };

      const updatedProfile = await api.upsertHomeProfile(currentHousehold.id, {
        propertyType: homeProfile.propertyType,
        addressLine1: homeProfile.addressLine1,
        addressLine2: homeProfile.addressLine2 || undefined,
        city: homeProfile.city,
        state: homeProfile.state,
        postalCode: homeProfile.postalCode,
        country: homeProfile.country,
        yearBuilt: homeProfile.yearBuilt || undefined,
        bedrooms: homeProfile.bedrooms || undefined,
        bathrooms: homeProfile.bathrooms || undefined,
        squareFeet: homeProfile.squareFeet || undefined,
        notes: JSON.stringify(newExtendedData),
      });

      setHomeProfile(updatedProfile);
      setExtendedData(newExtendedData);
      setEditSection(null);
      setSuccessMessage('Preferences updated successfully');
      setTimeout(() => setSuccessMessage(''), 3000);
    } catch (err: unknown) {
      const message =
        err && typeof err === 'object' && 'message' in err
          ? (err as { message: string }).message
          : 'Failed to save. Please try again.';
      setError(message);
    } finally {
      setIsSaving(false);
    }
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  if (!homeProfile) {
    return (
      <div className="max-w-4xl mx-auto">
        <div className="card text-center py-12">
          <div className="w-16 h-16 rounded-full bg-slate-100 dark:bg-slate-800 flex items-center justify-center mx-auto mb-4">
            <svg className="w-8 h-8 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
            </svg>
          </div>
          <h2 className="text-xl font-semibold text-slate-900 dark:text-white mb-2">
            No home profile yet
          </h2>
          <p className="text-slate-600 dark:text-slate-400 mb-6">
            Add your home details to get personalized recommendations
          </p>
          <button onClick={() => setEditSection('basic')} className="btn btn-primary">
            Add Home Profile
          </button>
        </div>
      </div>
    );
  }

  const propertyTypeLabel = propertyTypeOptions.find((o) => o.value === homeProfile.propertyType)?.label || homeProfile.propertyType;

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-slate-900 dark:text-white">Home Profile</h1>
        <p className="text-slate-600 dark:text-slate-400">
          Manage your home details and preferences
        </p>
      </div>

      {/* Success Message */}
      {successMessage && (
        <div className="p-4 rounded-lg bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800">
          <div className="flex items-center gap-2">
            <svg className="w-5 h-5 text-green-600 dark:text-green-400" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
            </svg>
            <p className="text-sm text-green-600 dark:text-green-400">{successMessage}</p>
          </div>
        </div>
      )}

      {/* Error Message */}
      {error && (
        <div className="p-4 rounded-lg bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800">
          <p className="text-sm text-red-600 dark:text-red-400">{error}</p>
        </div>
      )}

      {/* Basic Info Card */}
      <div className="card">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Property Information</h2>
          {editSection !== 'basic' && (
            <button
              onClick={() => setEditSection('basic')}
              className="text-sm text-blue-600 hover:text-blue-700 dark:text-blue-400 font-medium"
            >
              Edit
            </button>
          )}
        </div>

        {editSection === 'basic' ? (
          <BasicInfoEditForm
            homeProfile={homeProfile}
            householdName={currentHousehold?.name || ''}
            onSave={handleSaveBasicInfo}
            onCancel={() => setEditSection(null)}
            isSaving={isSaving}
          />
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <h3 className="text-sm font-medium text-slate-500 dark:text-slate-400 mb-1">Home Name</h3>
              <p className="text-slate-900 dark:text-white">{currentHousehold?.name}</p>
            </div>
            <div>
              <h3 className="text-sm font-medium text-slate-500 dark:text-slate-400 mb-1">Property Type</h3>
              <p className="text-slate-900 dark:text-white">{propertyTypeLabel}</p>
            </div>
            <div className="md:col-span-2">
              <h3 className="text-sm font-medium text-slate-500 dark:text-slate-400 mb-1">Address</h3>
              <p className="text-slate-900 dark:text-white">
                {homeProfile.addressLine1}
                {homeProfile.addressLine2 && `, ${homeProfile.addressLine2}`}
                <br />
                {homeProfile.city}, {homeProfile.state} {homeProfile.postalCode}
              </p>
            </div>
            <div>
              <h3 className="text-sm font-medium text-slate-500 dark:text-slate-400 mb-1">Year Built</h3>
              <p className="text-slate-900 dark:text-white">{homeProfile.yearBuilt || '—'}</p>
            </div>
            <div>
              <h3 className="text-sm font-medium text-slate-500 dark:text-slate-400 mb-1">Square Feet</h3>
              <p className="text-slate-900 dark:text-white">
                {homeProfile.squareFeet ? homeProfile.squareFeet.toLocaleString() : '—'}
              </p>
            </div>
            <div>
              <h3 className="text-sm font-medium text-slate-500 dark:text-slate-400 mb-1">Bedrooms</h3>
              <p className="text-slate-900 dark:text-white">{homeProfile.bedrooms || '—'}</p>
            </div>
            <div>
              <h3 className="text-sm font-medium text-slate-500 dark:text-slate-400 mb-1">Bathrooms</h3>
              <p className="text-slate-900 dark:text-white">{homeProfile.bathrooms || '—'}</p>
            </div>
          </div>
        )}
      </div>

      {/* Systems Card */}
      <div className="card">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Home Systems</h2>
          {editSection !== 'systems' && (
            <button
              onClick={() => setEditSection('systems')}
              className="text-sm text-blue-600 hover:text-blue-700 dark:text-blue-400 font-medium"
            >
              Edit
            </button>
          )}
        </div>

        {editSection === 'systems' ? (
          <SystemsEditForm
            systems={extendedData.systems}
            onSave={handleSaveSystems}
            onCancel={() => setEditSection(null)}
            isSaving={isSaving}
          />
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <SystemItem
              label="HVAC"
              value={hvacTypeOptions.find((o) => o.value === extendedData.systems?.hvacType)?.label}
              age={extendedData.systems?.hvacAge}
            />
            <SystemItem
              label="Roof"
              value={roofTypeOptions.find((o) => o.value === extendedData.systems?.roofType)?.label}
              age={extendedData.systems?.roofAge}
            />
            <SystemItem
              label="Water Heater"
              value={waterHeaterTypeOptions.find((o) => o.value === extendedData.systems?.waterHeaterType)?.label}
              age={extendedData.systems?.waterHeaterAge}
            />
            <SystemItem
              label="Waste System"
              value={extendedData.systems?.septicOrSewer === 'septic' ? 'Septic' : extendedData.systems?.septicOrSewer === 'sewer' ? 'Municipal Sewer' : undefined}
            />
            <SystemItem
              label="Electrical Panel"
              value={extendedData.systems?.electricalPanelAmps ? `${extendedData.systems.electricalPanelAmps} amps` : undefined}
            />
            <div>
              <h3 className="text-sm font-medium text-slate-500 dark:text-slate-400 mb-2">Features</h3>
              <div className="flex flex-wrap gap-2">
                {extendedData.systems?.hasPool && <FeatureBadge label="Pool" />}
                {extendedData.systems?.hasSprinklerSystem && <FeatureBadge label="Sprinklers" />}
                {extendedData.systems?.hasSecuritySystem && <FeatureBadge label="Security" />}
                {extendedData.systems?.hasSmartHome && <FeatureBadge label="Smart Home" />}
                {!extendedData.systems?.hasPool &&
                  !extendedData.systems?.hasSprinklerSystem &&
                  !extendedData.systems?.hasSecuritySystem &&
                  !extendedData.systems?.hasSmartHome && (
                    <span className="text-slate-400 dark:text-slate-500 text-sm">None specified</span>
                  )}
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Preferences Card */}
      <div className="card">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Preferences</h2>
          {editSection !== 'preferences' && (
            <button
              onClick={() => setEditSection('preferences')}
              className="text-sm text-blue-600 hover:text-blue-700 dark:text-blue-400 font-medium"
            >
              Edit
            </button>
          )}
        </div>

        {editSection === 'preferences' ? (
          <PreferencesEditForm
            preferences={extendedData.preferences}
            onSave={handleSavePreferences}
            onCancel={() => setEditSection(null)}
            isSaving={isSaving}
          />
        ) : (
          <div className="space-y-6">
            <div>
              <h3 className="text-sm font-medium text-slate-500 dark:text-slate-400 mb-3">Pain Points</h3>
              <div className="flex flex-wrap gap-2">
                {extendedData.preferences?.painPoints?.map((point) => {
                  const option = painPointOptions.find((o) => o.value === point);
                  return option ? <FeatureBadge key={point} label={option.label} /> : null;
                })}
                {(!extendedData.preferences?.painPoints || extendedData.preferences.painPoints.length === 0) && (
                  <span className="text-slate-400 dark:text-slate-500 text-sm">None specified</span>
                )}
              </div>
            </div>
            <div>
              <h3 className="text-sm font-medium text-slate-500 dark:text-slate-400 mb-3">Communication Channels</h3>
              <div className="flex flex-wrap gap-2">
                {extendedData.preferences?.communicationChannels?.map((channel) => {
                  const option = communicationOptions.find((o) => o.value === channel);
                  return option ? <FeatureBadge key={channel} label={option.label} /> : null;
                })}
                {(!extendedData.preferences?.communicationChannels || extendedData.preferences.communicationChannels.length === 0) && (
                  <span className="text-slate-400 dark:text-slate-500 text-sm">None specified</span>
                )}
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

function SystemItem({ label, value, age }: { label: string; value?: string; age?: number }) {
  return (
    <div>
      <h3 className="text-sm font-medium text-slate-500 dark:text-slate-400 mb-1">{label}</h3>
      <p className="text-slate-900 dark:text-white">
        {value || '—'}
        {age !== undefined && value && (
          <span className="text-slate-500 dark:text-slate-400 text-sm ml-1">({age} years old)</span>
        )}
      </p>
    </div>
  );
}

function FeatureBadge({ label }: { label: string }) {
  return (
    <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400">
      {label}
    </span>
  );
}

// Basic Info Edit Form
function BasicInfoEditForm({
  homeProfile,
  householdName,
  onSave,
  onCancel,
  isSaving,
}: {
  homeProfile: HomeProfile;
  householdName: string;
  onSave: (data: BasicInfoData) => void;
  onCancel: () => void;
  isSaving: boolean;
}) {
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<BasicInfoData>({
    resolver: zodResolver(basicInfoSchema),
    defaultValues: {
      name: householdName,
      propertyType: homeProfile.propertyType,
      addressLine1: homeProfile.addressLine1,
      addressLine2: homeProfile.addressLine2 || '',
      city: homeProfile.city,
      state: homeProfile.state,
      postalCode: homeProfile.postalCode,
      yearBuilt: homeProfile.yearBuilt || undefined,
      bedrooms: homeProfile.bedrooms || undefined,
      bathrooms: homeProfile.bathrooms || undefined,
      squareFeet: homeProfile.squareFeet || undefined,
    },
  });

  return (
    <form onSubmit={handleSubmit(onSave)} className="space-y-4">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label htmlFor="name" className="label block mb-1.5">Home name</label>
          <input {...register('name')} id="name" type="text" className="input" />
          {errors.name && <p className="text-sm text-red-500 mt-1">{errors.name.message}</p>}
        </div>
        <div>
          <label htmlFor="propertyType" className="label block mb-1.5">Property type</label>
          <select {...register('propertyType')} id="propertyType" className="input">
            {propertyTypeOptions.map((opt) => (
              <option key={opt.value} value={opt.value}>{opt.label}</option>
            ))}
          </select>
        </div>
        <div className="md:col-span-2">
          <label htmlFor="addressLine1" className="label block mb-1.5">Street address</label>
          <input {...register('addressLine1')} id="addressLine1" type="text" className="input" />
          {errors.addressLine1 && <p className="text-sm text-red-500 mt-1">{errors.addressLine1.message}</p>}
        </div>
        <div className="md:col-span-2">
          <label htmlFor="addressLine2" className="label block mb-1.5">Apt, suite, etc.</label>
          <input {...register('addressLine2')} id="addressLine2" type="text" className="input" />
        </div>
        <div>
          <label htmlFor="city" className="label block mb-1.5">City</label>
          <input {...register('city')} id="city" type="text" className="input" />
          {errors.city && <p className="text-sm text-red-500 mt-1">{errors.city.message}</p>}
        </div>
        <div>
          <label htmlFor="state" className="label block mb-1.5">State</label>
          <select {...register('state')} id="state" className="input">
            <option value="">Select state</option>
            {usStates.map((s) => (
              <option key={s.value} value={s.value}>{s.label}</option>
            ))}
          </select>
          {errors.state && <p className="text-sm text-red-500 mt-1">{errors.state.message}</p>}
        </div>
        <div>
          <label htmlFor="postalCode" className="label block mb-1.5">ZIP code</label>
          <input {...register('postalCode')} id="postalCode" type="text" className="input" />
          {errors.postalCode && <p className="text-sm text-red-500 mt-1">{errors.postalCode.message}</p>}
        </div>
        <div>
          <label htmlFor="yearBuilt" className="label block mb-1.5">Year built</label>
          <input {...register('yearBuilt')} id="yearBuilt" type="number" className="input" />
        </div>
        <div>
          <label htmlFor="squareFeet" className="label block mb-1.5">Square feet</label>
          <input {...register('squareFeet')} id="squareFeet" type="number" className="input" />
        </div>
        <div>
          <label htmlFor="bedrooms" className="label block mb-1.5">Bedrooms</label>
          <input {...register('bedrooms')} id="bedrooms" type="number" className="input" />
        </div>
        <div>
          <label htmlFor="bathrooms" className="label block mb-1.5">Bathrooms</label>
          <input {...register('bathrooms')} id="bathrooms" type="number" step="0.5" className="input" />
        </div>
      </div>
      <div className="flex gap-3 pt-4">
        <button type="button" onClick={onCancel} disabled={isSaving} className="btn btn-secondary">
          Cancel
        </button>
        <button type="submit" disabled={isSaving} className="btn btn-primary">
          {isSaving ? 'Saving...' : 'Save Changes'}
        </button>
      </div>
    </form>
  );
}

// Systems Edit Form
function SystemsEditForm({
  systems,
  onSave,
  onCancel,
  isSaving,
}: {
  systems?: HomeSystems;
  onSave: (data: SystemsData) => void;
  onCancel: () => void;
  isSaving: boolean;
}) {
  const { register, handleSubmit, watch } = useForm<SystemsData>({
    resolver: zodResolver(systemsSchema),
    defaultValues: systems || {},
  });

  const septicOrSewer = watch('septicOrSewer');

  return (
    <form onSubmit={handleSubmit(onSave)} className="space-y-4">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label htmlFor="hvacType" className="label block mb-1.5">HVAC type</label>
          <select {...register('hvacType')} id="hvacType" className="input">
            <option value="">Select type</option>
            {hvacTypeOptions.map((opt) => (
              <option key={opt.value} value={opt.value}>{opt.label}</option>
            ))}
          </select>
        </div>
        <div>
          <label htmlFor="hvacAge" className="label block mb-1.5">HVAC age (years)</label>
          <input {...register('hvacAge')} id="hvacAge" type="number" className="input" />
        </div>
        <div>
          <label htmlFor="roofType" className="label block mb-1.5">Roof type</label>
          <select {...register('roofType')} id="roofType" className="input">
            <option value="">Select type</option>
            {roofTypeOptions.map((opt) => (
              <option key={opt.value} value={opt.value}>{opt.label}</option>
            ))}
          </select>
        </div>
        <div>
          <label htmlFor="roofAge" className="label block mb-1.5">Roof age (years)</label>
          <input {...register('roofAge')} id="roofAge" type="number" className="input" />
        </div>
        <div>
          <label htmlFor="waterHeaterType" className="label block mb-1.5">Water heater type</label>
          <select {...register('waterHeaterType')} id="waterHeaterType" className="input">
            <option value="">Select type</option>
            {waterHeaterTypeOptions.map((opt) => (
              <option key={opt.value} value={opt.value}>{opt.label}</option>
            ))}
          </select>
        </div>
        <div>
          <label htmlFor="waterHeaterAge" className="label block mb-1.5">Water heater age (years)</label>
          <input {...register('waterHeaterAge')} id="waterHeaterAge" type="number" className="input" />
        </div>
        <div>
          <label htmlFor="septicOrSewer" className="label block mb-1.5">Waste system</label>
          <select {...register('septicOrSewer')} id="septicOrSewer" className="input">
            <option value="">Select type</option>
            <option value="sewer">Municipal sewer</option>
            <option value="septic">Septic system</option>
          </select>
        </div>
        {septicOrSewer === 'septic' && (
          <div>
            <label htmlFor="septicLastServiced" className="label block mb-1.5">Septic last serviced</label>
            <input {...register('septicLastServiced')} id="septicLastServiced" type="date" className="input" />
          </div>
        )}
        <div>
          <label htmlFor="electricalPanelAmps" className="label block mb-1.5">Electrical panel (amps)</label>
          <select {...register('electricalPanelAmps')} id="electricalPanelAmps" className="input">
            <option value="">Select amperage</option>
            <option value="100">100 amps</option>
            <option value="150">150 amps</option>
            <option value="200">200 amps</option>
            <option value="400">400 amps</option>
          </select>
        </div>
      </div>
      <div>
        <label className="label block mb-3">Home features</label>
        <div className="grid grid-cols-2 gap-3">
          {[
            { name: 'hasPool', label: 'Swimming pool' },
            { name: 'hasSprinklerSystem', label: 'Sprinkler system' },
            { name: 'hasSecuritySystem', label: 'Security system' },
            { name: 'hasSmartHome', label: 'Smart home devices' },
          ].map((feature) => (
            <label key={feature.name} className="flex items-center gap-3 p-3 rounded-lg border border-slate-200 dark:border-slate-700 cursor-pointer hover:bg-slate-50 dark:hover:bg-slate-800">
              <input type="checkbox" {...register(feature.name as keyof SystemsData)} className="w-4 h-4 text-blue-600 rounded" />
              <span className="text-sm text-slate-700 dark:text-slate-300">{feature.label}</span>
            </label>
          ))}
        </div>
      </div>
      <div className="flex gap-3 pt-4">
        <button type="button" onClick={onCancel} disabled={isSaving} className="btn btn-secondary">
          Cancel
        </button>
        <button type="submit" disabled={isSaving} className="btn btn-primary">
          {isSaving ? 'Saving...' : 'Save Changes'}
        </button>
      </div>
    </form>
  );
}

// Preferences Edit Form
function PreferencesEditForm({
  preferences,
  onSave,
  onCancel,
  isSaving,
}: {
  preferences?: OnboardingPreferences;
  onSave: (painPoints: string[], channels: string[]) => void;
  onCancel: () => void;
  isSaving: boolean;
}) {
  const [selectedPainPoints, setSelectedPainPoints] = useState<string[]>(preferences?.painPoints || []);
  const [selectedChannels, setSelectedChannels] = useState<string[]>(preferences?.communicationChannels || []);

  const togglePainPoint = (value: string) => {
    setSelectedPainPoints((prev) =>
      prev.includes(value) ? prev.filter((p) => p !== value) : [...prev, value]
    );
  };

  const toggleChannel = (value: string) => {
    setSelectedChannels((prev) =>
      prev.includes(value) ? prev.filter((c) => c !== value) : [...prev, value]
    );
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSave(selectedPainPoints, selectedChannels);
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      <div>
        <label className="label block mb-3">Pain Points</label>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          {painPointOptions.map((option) => (
            <label key={option.value} className="flex items-center gap-3 p-3 rounded-lg border border-slate-200 dark:border-slate-700 cursor-pointer hover:bg-slate-50 dark:hover:bg-slate-800">
              <input
                type="checkbox"
                checked={selectedPainPoints.includes(option.value)}
                onChange={() => togglePainPoint(option.value)}
                className="w-4 h-4 text-blue-600 rounded"
              />
              <span className="text-sm text-slate-700 dark:text-slate-300">{option.label}</span>
            </label>
          ))}
        </div>
      </div>
      <div>
        <label className="label block mb-3">Communication Channels</label>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
          {communicationOptions.map((option) => (
            <label key={option.value} className="flex items-center gap-3 p-3 rounded-lg border border-slate-200 dark:border-slate-700 cursor-pointer hover:bg-slate-50 dark:hover:bg-slate-800">
              <input
                type="checkbox"
                checked={selectedChannels.includes(option.value)}
                onChange={() => toggleChannel(option.value)}
                className="w-4 h-4 text-blue-600 rounded"
              />
              <span className="text-sm text-slate-700 dark:text-slate-300">{option.label}</span>
            </label>
          ))}
        </div>
      </div>
      <div className="flex gap-3 pt-4">
        <button type="button" onClick={onCancel} disabled={isSaving} className="btn btn-secondary">
          Cancel
        </button>
        <button type="submit" disabled={isSaving} className="btn btn-primary">
          {isSaving ? 'Saving...' : 'Save Changes'}
        </button>
      </div>
    </form>
  );
}
