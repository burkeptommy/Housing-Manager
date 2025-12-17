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

interface SystemDetail {
  type?: string;
  vendor?: string;
  vendorPhone?: string;
  brand?: string;
  model?: string;
  serialNumber?: string;
  installDate?: string;
  lastServiceDate?: string;
  nextMaintenanceDate?: string;
  warrantyExpires?: string;
  notes?: string;
  filterSize?: string;
  filterLastChanged?: string;
  filterNextChange?: string;
  [key: string]: unknown;
}

interface DetailedSystems {
  heating?: SystemDetail;
  hvac?: SystemDetail;
  waterHeater?: SystemDetail;
  electrical?: SystemDetail;
  plumbing?: SystemDetail;
  laundry?: {
    washer?: SystemDetail;
    dryer?: SystemDetail;
    ventLastCleaned?: string;
    ventNextCleaning?: string;
    vendor?: string;
    vendorPhone?: string;
  };
  fireplace?: SystemDetail;
  lawnCare?: SystemDetail & {
    serviceFrequency?: string;
    services?: string[];
    irrigationVendor?: string;
    irrigationPhone?: string;
  };
  houseCleaning?: SystemDetail & {
    serviceFrequency?: string;
    serviceDay?: string;
    deepCleanSchedule?: string;
    lastDeepClean?: string;
    nextDeepClean?: string;
    services?: string[];
  };
  pestControl?: SystemDetail & {
    serviceFrequency?: string;
    services?: string[];
  };
  security?: SystemDetail & {
    cameras?: number;
    doorSensors?: number;
    motionSensors?: number;
  };
  roof?: SystemDetail & {
    guttersCleaned?: string;
    guttersNextCleaning?: string;
  };
  garage?: SystemDetail & {
    openerBrand?: string;
    openerModel?: string;
  };
  pool?: SystemDetail;
}

interface UpcomingMaintenance {
  service: string;
  date: string;
  vendor: string;
  time?: string;
  notes?: string;
}

interface RecentService {
  service: string;
  date: string;
  vendor: string;
  cost?: number;
}

interface ServiceReport {
  title: string;
  date: string;
  vendor: string;
  summary: string;
}

interface ExtendedProfileData {
  systems?: HomeSystems | DetailedSystems;
  preferences?: OnboardingPreferences;
  upcomingMaintenance?: UpcomingMaintenance[];
  recentServices?: RecentService[];
  serviceReports?: ServiceReport[];
  appliances?: Record<string, SystemDetail>;
}

function parseExtendedData(notes: string | null | undefined): ExtendedProfileData {
  if (!notes) return {};
  try {
    return JSON.parse(notes);
  } catch {
    return {};
  }
}

function isDetailedSystems(systems: HomeSystems | DetailedSystems | undefined): systems is DetailedSystems {
  if (!systems) return false;
  return 'heating' in systems || 'hvac' in systems && typeof (systems as DetailedSystems).hvac === 'object';
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
        notes: homeProfile?.notes ?? undefined,
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

      {/* Systems Card - Detailed View */}
      {isDetailedSystems(extendedData.systems) ? (
        <DetailedSystemsView systems={extendedData.systems} />
      ) : (
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
              systems={extendedData.systems as HomeSystems}
              onSave={handleSaveSystems}
              onCancel={() => setEditSection(null)}
              isSaving={isSaving}
            />
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              <SystemItem
                label="HVAC"
                value={hvacTypeOptions.find((o) => o.value === (extendedData.systems as HomeSystems)?.hvacType)?.label}
                age={(extendedData.systems as HomeSystems)?.hvacAge}
              />
              <SystemItem
                label="Roof"
                value={roofTypeOptions.find((o) => o.value === (extendedData.systems as HomeSystems)?.roofType)?.label}
                age={(extendedData.systems as HomeSystems)?.roofAge}
              />
              <SystemItem
                label="Water Heater"
                value={waterHeaterTypeOptions.find((o) => o.value === (extendedData.systems as HomeSystems)?.waterHeaterType)?.label}
                age={(extendedData.systems as HomeSystems)?.waterHeaterAge}
              />
              <SystemItem
                label="Waste System"
                value={(extendedData.systems as HomeSystems)?.septicOrSewer === 'septic' ? 'Septic' : (extendedData.systems as HomeSystems)?.septicOrSewer === 'sewer' ? 'Municipal Sewer' : undefined}
              />
              <SystemItem
                label="Electrical Panel"
                value={(extendedData.systems as HomeSystems)?.electricalPanelAmps ? `${(extendedData.systems as HomeSystems).electricalPanelAmps} amps` : undefined}
              />
              <div>
                <h3 className="text-sm font-medium text-slate-500 dark:text-slate-400 mb-2">Features</h3>
                <div className="flex flex-wrap gap-2">
                  {(extendedData.systems as HomeSystems)?.hasPool && <FeatureBadge label="Pool" />}
                  {(extendedData.systems as HomeSystems)?.hasSprinklerSystem && <FeatureBadge label="Sprinklers" />}
                  {(extendedData.systems as HomeSystems)?.hasSecuritySystem && <FeatureBadge label="Security" />}
                  {(extendedData.systems as HomeSystems)?.hasSmartHome && <FeatureBadge label="Smart Home" />}
                  {!(extendedData.systems as HomeSystems)?.hasPool &&
                    !(extendedData.systems as HomeSystems)?.hasSprinklerSystem &&
                    !(extendedData.systems as HomeSystems)?.hasSecuritySystem &&
                    !(extendedData.systems as HomeSystems)?.hasSmartHome && (
                      <span className="text-slate-400 dark:text-slate-500 text-sm">None specified</span>
                    )}
                </div>
              </div>
            </div>
          )}
        </div>
      )}

      {/* Upcoming Maintenance */}
      {extendedData.upcomingMaintenance && extendedData.upcomingMaintenance.length > 0 && (
        <div className="card">
          <h2 className="text-lg font-semibold text-slate-900 dark:text-white mb-4">Upcoming Maintenance</h2>
          <div className="space-y-3">
            {extendedData.upcomingMaintenance.map((item, index) => (
              <div key={index} className="flex items-center justify-between p-3 bg-slate-50 dark:bg-slate-800 rounded-lg">
                <div>
                  <p className="font-medium text-slate-900 dark:text-white">{item.service}</p>
                  <p className="text-sm text-slate-500 dark:text-slate-400">{item.vendor}</p>
                </div>
                <div className="text-right">
                  <p className="text-sm font-medium text-slate-900 dark:text-white">
                    {new Date(item.date).toLocaleDateString()}
                  </p>
                  {item.time && <p className="text-xs text-slate-500 dark:text-slate-400">{item.time}</p>}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Recent Services */}
      {extendedData.recentServices && extendedData.recentServices.length > 0 && (
        <div className="card">
          <h2 className="text-lg font-semibold text-slate-900 dark:text-white mb-4">Recent Services</h2>
          <div className="space-y-3">
            {extendedData.recentServices.map((item, index) => (
              <div key={index} className="flex items-center justify-between p-3 bg-slate-50 dark:bg-slate-800 rounded-lg">
                <div>
                  <p className="font-medium text-slate-900 dark:text-white">{item.service}</p>
                  <p className="text-sm text-slate-500 dark:text-slate-400">{item.vendor}</p>
                </div>
                <div className="text-right">
                  <p className="text-sm text-slate-500 dark:text-slate-400">
                    {new Date(item.date).toLocaleDateString()}
                  </p>
                  {item.cost && (
                    <p className="text-sm font-medium text-slate-900 dark:text-white">
                      ${item.cost.toFixed(2)}
                    </p>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Service Reports */}
      {extendedData.serviceReports && extendedData.serviceReports.length > 0 && (
        <div className="card">
          <h2 className="text-lg font-semibold text-slate-900 dark:text-white mb-4">Service Reports</h2>
          <div className="space-y-4">
            {extendedData.serviceReports.map((report, index) => (
              <div key={index} className="p-4 border border-slate-200 dark:border-slate-700 rounded-lg">
                <div className="flex items-center justify-between mb-2">
                  <h3 className="font-medium text-slate-900 dark:text-white">{report.title}</h3>
                  <span className="text-sm text-slate-500 dark:text-slate-400">
                    {new Date(report.date).toLocaleDateString()}
                  </span>
                </div>
                <p className="text-sm text-slate-500 dark:text-slate-400 mb-2">{report.vendor}</p>
                <p className="text-sm text-slate-700 dark:text-slate-300">{report.summary}</p>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Appliances */}
      {extendedData.appliances && Object.keys(extendedData.appliances).length > 0 && (
        <div className="card">
          <h2 className="text-lg font-semibold text-slate-900 dark:text-white mb-4">Appliances</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {Object.entries(extendedData.appliances).map(([key, appliance]) => (
              <div key={key} className="p-4 border border-slate-200 dark:border-slate-700 rounded-lg">
                <h3 className="font-medium text-slate-900 dark:text-white capitalize mb-2">{key.replace(/([A-Z])/g, ' $1').trim()}</h3>
                <div className="space-y-1 text-sm">
                  {appliance.brand && <p><span className="text-slate-500 dark:text-slate-400">Brand:</span> <span className="text-slate-900 dark:text-white">{appliance.brand}</span></p>}
                  {appliance.model && <p><span className="text-slate-500 dark:text-slate-400">Model:</span> <span className="text-slate-900 dark:text-white">{appliance.model}</span></p>}
                  {appliance.serialNumber && <p><span className="text-slate-500 dark:text-slate-400">Serial:</span> <span className="text-slate-900 dark:text-white">{appliance.serialNumber}</span></p>}
                  {appliance.warrantyExpires && (
                    <p>
                      <span className="text-slate-500 dark:text-slate-400">Warranty:</span>{' '}
                      <span className={new Date(appliance.warrantyExpires) < new Date() ? 'text-red-500' : 'text-green-500'}>
                        {new Date(appliance.warrantyExpires).toLocaleDateString()}
                      </span>
                    </p>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

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

// Detailed Systems View Component for rich system data
function DetailedSystemsView({ systems }: { systems: DetailedSystems }) {
  const systemCategories = [
    { key: 'heating', label: 'Heating', icon: '🔥' },
    { key: 'hvac', label: 'HVAC / Air Conditioning', icon: '❄️' },
    { key: 'waterHeater', label: 'Water Heater', icon: '🚿' },
    { key: 'electrical', label: 'Electrical', icon: '⚡' },
    { key: 'plumbing', label: 'Plumbing', icon: '🔧' },
    { key: 'fireplace', label: 'Fireplace', icon: '🔥' },
    { key: 'roof', label: 'Roof', icon: '🏠' },
    { key: 'garage', label: 'Garage', icon: '🚗' },
    { key: 'pool', label: 'Pool', icon: '🏊' },
  ];

  const serviceCategories = [
    { key: 'lawnCare', label: 'Lawn Care & Landscaping', icon: '🌿' },
    { key: 'houseCleaning', label: 'House Cleaning', icon: '🧹' },
    { key: 'pestControl', label: 'Pest Control', icon: '🐜' },
    { key: 'security', label: 'Security System', icon: '🔒' },
  ];

  const formatDate = (dateStr: string | undefined) => {
    if (!dateStr) return null;
    return new Date(dateStr).toLocaleDateString();
  };

  return (
    <div className="space-y-6">
      {/* Core Home Systems */}
      <div className="card">
        <h2 className="text-lg font-semibold text-slate-900 dark:text-white mb-6">Home Systems</h2>
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {systemCategories.map(({ key, label, icon }) => {
            const system = systems[key as keyof DetailedSystems] as SystemDetail | undefined;
            if (!system) return null;

            return (
              <div key={key} className="p-4 border border-slate-200 dark:border-slate-700 rounded-lg">
                <div className="flex items-center gap-2 mb-3">
                  <span className="text-xl">{icon}</span>
                  <h3 className="font-semibold text-slate-900 dark:text-white">{label}</h3>
                </div>

                <div className="space-y-2 text-sm">
                  {system.type && (
                    <div className="flex justify-between">
                      <span className="text-slate-500 dark:text-slate-400">Type</span>
                      <span className="text-slate-900 dark:text-white font-medium">{system.type}</span>
                    </div>
                  )}
                  {system.brand && (
                    <div className="flex justify-between">
                      <span className="text-slate-500 dark:text-slate-400">Brand</span>
                      <span className="text-slate-900 dark:text-white">{system.brand} {system.model || ''}</span>
                    </div>
                  )}
                  {system.serialNumber && (
                    <div className="flex justify-between">
                      <span className="text-slate-500 dark:text-slate-400">Serial #</span>
                      <span className="text-slate-900 dark:text-white font-mono text-xs">{system.serialNumber}</span>
                    </div>
                  )}

                  {/* Vendor Info */}
                  {system.vendor && (
                    <div className="pt-2 mt-2 border-t border-slate-100 dark:border-slate-700">
                      <div className="flex justify-between">
                        <span className="text-slate-500 dark:text-slate-400">Vendor</span>
                        <span className="text-slate-900 dark:text-white">{system.vendor}</span>
                      </div>
                      {system.vendorPhone && (
                        <div className="flex justify-between">
                          <span className="text-slate-500 dark:text-slate-400">Phone</span>
                          <a href={`tel:${system.vendorPhone}`} className="text-blue-600 dark:text-blue-400 hover:underline">
                            {system.vendorPhone}
                          </a>
                        </div>
                      )}
                    </div>
                  )}

                  {/* Maintenance Dates */}
                  {(system.lastServiceDate || system.nextMaintenanceDate) && (
                    <div className="pt-2 mt-2 border-t border-slate-100 dark:border-slate-700">
                      {system.lastServiceDate && (
                        <div className="flex justify-between">
                          <span className="text-slate-500 dark:text-slate-400">Last Service</span>
                          <span className="text-slate-900 dark:text-white">{formatDate(system.lastServiceDate)}</span>
                        </div>
                      )}
                      {system.nextMaintenanceDate && (
                        <div className="flex justify-between">
                          <span className="text-slate-500 dark:text-slate-400">Next Maintenance</span>
                          <span className={`font-medium ${new Date(system.nextMaintenanceDate) < new Date() ? 'text-red-500' : 'text-green-600 dark:text-green-400'}`}>
                            {formatDate(system.nextMaintenanceDate)}
                          </span>
                        </div>
                      )}
                    </div>
                  )}

                  {/* HVAC Filter Info */}
                  {key === 'hvac' && system.filterSize && (
                    <div className="pt-2 mt-2 border-t border-slate-100 dark:border-slate-700">
                      <div className="flex justify-between">
                        <span className="text-slate-500 dark:text-slate-400">Filter Size</span>
                        <span className="text-slate-900 dark:text-white">{system.filterSize}</span>
                      </div>
                      {system.filterNextChange && (
                        <div className="flex justify-between items-center">
                          <span className="text-slate-500 dark:text-slate-400">Filter Change Due</span>
                          <span className={`font-medium ${new Date(system.filterNextChange) < new Date() ? 'text-red-500' : 'text-slate-900 dark:text-white'}`}>
                            {formatDate(system.filterNextChange)}
                          </span>
                        </div>
                      )}
                      <button className="mt-2 text-xs text-blue-600 dark:text-blue-400 hover:underline">
                        Order replacement filter →
                      </button>
                    </div>
                  )}

                  {/* Warranty */}
                  {system.warrantyExpires && (
                    <div className="pt-2 mt-2 border-t border-slate-100 dark:border-slate-700">
                      <div className="flex justify-between">
                        <span className="text-slate-500 dark:text-slate-400">Warranty Expires</span>
                        <span className={new Date(system.warrantyExpires) < new Date() ? 'text-red-500' : 'text-green-600 dark:text-green-400'}>
                          {formatDate(system.warrantyExpires)}
                        </span>
                      </div>
                    </div>
                  )}

                  {/* Notes */}
                  {system.notes && (
                    <p className="text-xs text-slate-500 dark:text-slate-400 italic pt-2 mt-2 border-t border-slate-100 dark:border-slate-700">
                      {system.notes}
                    </p>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Laundry Section */}
      {systems.laundry && (
        <div className="card">
          <div className="flex items-center gap-2 mb-4">
            <span className="text-xl">🧺</span>
            <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Laundry</h2>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {systems.laundry.washer && (
              <div className="p-4 bg-slate-50 dark:bg-slate-800 rounded-lg">
                <h3 className="font-medium text-slate-900 dark:text-white mb-2">Washer</h3>
                <div className="space-y-1 text-sm">
                  <p><span className="text-slate-500">Brand:</span> <span className="text-slate-900 dark:text-white">{systems.laundry.washer.brand}</span></p>
                  <p><span className="text-slate-500">Model:</span> <span className="text-slate-900 dark:text-white">{systems.laundry.washer.model}</span></p>
                  {systems.laundry.washer.warrantyExpires && (
                    <p>
                      <span className="text-slate-500">Warranty:</span>{' '}
                      <span className={new Date(systems.laundry.washer.warrantyExpires) < new Date() ? 'text-red-500' : 'text-green-600'}>
                        {formatDate(systems.laundry.washer.warrantyExpires)}
                      </span>
                    </p>
                  )}
                </div>
              </div>
            )}
            {systems.laundry.dryer && (
              <div className="p-4 bg-slate-50 dark:bg-slate-800 rounded-lg">
                <h3 className="font-medium text-slate-900 dark:text-white mb-2">Dryer</h3>
                <div className="space-y-1 text-sm">
                  <p><span className="text-slate-500">Brand:</span> <span className="text-slate-900 dark:text-white">{systems.laundry.dryer.brand}</span></p>
                  <p><span className="text-slate-500">Model:</span> <span className="text-slate-900 dark:text-white">{systems.laundry.dryer.model}</span></p>
                  <p><span className="text-slate-500">Type:</span> <span className="text-slate-900 dark:text-white">{systems.laundry.dryer.type}</span></p>
                </div>
              </div>
            )}
          </div>
          {systems.laundry.ventNextCleaning && (
            <div className="mt-4 p-3 bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded-lg">
              <p className="text-sm text-amber-800 dark:text-amber-200">
                <strong>Dryer vent cleaning due:</strong> {formatDate(systems.laundry.ventNextCleaning)}
                {systems.laundry.vendor && ` • ${systems.laundry.vendor}`}
                {systems.laundry.vendorPhone && (
                  <a href={`tel:${systems.laundry.vendorPhone}`} className="ml-2 text-amber-600 hover:underline">
                    {systems.laundry.vendorPhone}
                  </a>
                )}
              </p>
            </div>
          )}
        </div>
      )}

      {/* Service Providers */}
      <div className="card">
        <h2 className="text-lg font-semibold text-slate-900 dark:text-white mb-6">Service Providers</h2>
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {serviceCategories.map(({ key, label, icon }) => {
            const service = systems[key as keyof DetailedSystems];
            if (!service || typeof service !== 'object') return null;

            const svc = service as SystemDetail & {
              serviceFrequency?: string;
              services?: string[];
              serviceDay?: string;
              cameras?: number;
              lastService?: string;
              nextService?: string;
            };

            return (
              <div key={key} className="p-4 border border-slate-200 dark:border-slate-700 rounded-lg">
                <div className="flex items-center gap-2 mb-3">
                  <span className="text-xl">{icon}</span>
                  <h3 className="font-semibold text-slate-900 dark:text-white">{label}</h3>
                </div>

                <div className="space-y-2 text-sm">
                  {svc.vendor && (
                    <div className="flex justify-between">
                      <span className="text-slate-500 dark:text-slate-400">Provider</span>
                      <span className="text-slate-900 dark:text-white font-medium">{svc.vendor}</span>
                    </div>
                  )}
                  {svc.vendorPhone && (
                    <div className="flex justify-between">
                      <span className="text-slate-500 dark:text-slate-400">Phone</span>
                      <a href={`tel:${svc.vendorPhone}`} className="text-blue-600 dark:text-blue-400 hover:underline">
                        {svc.vendorPhone}
                      </a>
                    </div>
                  )}
                  {svc.serviceFrequency && (
                    <div className="flex justify-between">
                      <span className="text-slate-500 dark:text-slate-400">Frequency</span>
                      <span className="text-slate-900 dark:text-white">{svc.serviceFrequency}</span>
                    </div>
                  )}
                  {svc.serviceDay && (
                    <div className="flex justify-between">
                      <span className="text-slate-500 dark:text-slate-400">Service Day</span>
                      <span className="text-slate-900 dark:text-white">{svc.serviceDay}</span>
                    </div>
                  )}
                  {svc.lastService && (
                    <div className="flex justify-between">
                      <span className="text-slate-500 dark:text-slate-400">Last Service</span>
                      <span className="text-slate-900 dark:text-white">{formatDate(svc.lastService)}</span>
                    </div>
                  )}
                  {svc.nextService && (
                    <div className="flex justify-between">
                      <span className="text-slate-500 dark:text-slate-400">Next Service</span>
                      <span className="text-green-600 dark:text-green-400 font-medium">{formatDate(svc.nextService)}</span>
                    </div>
                  )}

                  {/* Security specific info */}
                  {key === 'security' && (
                    <div className="pt-2 mt-2 border-t border-slate-100 dark:border-slate-700 space-y-1">
                      {svc.brand && <p><span className="text-slate-500">System:</span> <span className="text-slate-900 dark:text-white">{svc.brand} {svc.model || ''}</span></p>}
                      {svc.cameras && <p><span className="text-slate-500">Cameras:</span> <span className="text-slate-900 dark:text-white">{svc.cameras}</span></p>}
                    </div>
                  )}

                  {/* Services list */}
                  {svc.services && svc.services.length > 0 && (
                    <div className="pt-2 mt-2 border-t border-slate-100 dark:border-slate-700">
                      <span className="text-slate-500 dark:text-slate-400 block mb-1">Services:</span>
                      <div className="flex flex-wrap gap-1">
                        {svc.services.map((s, i) => (
                          <span key={i} className="inline-flex items-center px-2 py-0.5 rounded text-xs bg-slate-100 dark:bg-slate-700 text-slate-700 dark:text-slate-300">
                            {s}
                          </span>
                        ))}
                      </div>
                    </div>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
