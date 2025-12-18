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
  id?: string;
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
  imageUrl?: string;
  location?: string;
  [key: string]: unknown;
}

interface ApplianceDetail {
  id?: string;
  name?: string;
  brand?: string;
  model?: string;
  serialNumber?: string;
  installDate?: string;
  warrantyExpires?: string;
  lastService?: string;
  notes?: string;
  imageUrl?: string;
  location?: string;
  type?: string;
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
  appliances?: Record<string, ApplianceDetail>;
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
  const [showSystemsModal, setShowSystemsModal] = useState(false);
  const [showAppliancesModal, setShowAppliancesModal] = useState(false);

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

  const handleSaveDetailedSystems = async (systems: DetailedSystems) => {
    if (!currentHousehold || !homeProfile) return;

    setIsSaving(true);
    setError('');

    try {
      const newExtendedData = {
        ...extendedData,
        systems,
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
      setShowSystemsModal(false);
      setSuccessMessage('Systems updated successfully');
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

  const handleSaveAppliances = async (appliances: Record<string, ApplianceDetail>) => {
    if (!currentHousehold || !homeProfile) return;

    setIsSaving(true);
    setError('');

    try {
      const newExtendedData = {
        ...extendedData,
        appliances,
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
      setShowAppliancesModal(false);
      setSuccessMessage('Appliances updated successfully');
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
        <DetailedSystemsView
          systems={extendedData.systems}
          appliances={extendedData.appliances}
          onEditSystems={() => setShowSystemsModal(true)}
          onEditAppliances={() => setShowAppliancesModal(true)}
        />
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

      {/* Systems Management Modal */}
      {showSystemsModal && (
        <SystemsManagementModal
          systems={isDetailedSystems(extendedData.systems) ? extendedData.systems : {}}
          onSave={handleSaveDetailedSystems}
          onClose={() => setShowSystemsModal(false)}
          isSaving={isSaving}
        />
      )}

      {/* Appliances Management Modal */}
      {showAppliancesModal && (
        <AppliancesManagementModal
          appliances={extendedData.appliances || {}}
          onSave={handleSaveAppliances}
          onClose={() => setShowAppliancesModal(false)}
          isSaving={isSaving}
        />
      )}
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
function DetailedSystemsView({
  systems,
  appliances,
  onEditSystems,
  onEditAppliances,
}: {
  systems: DetailedSystems;
  appliances?: Record<string, ApplianceDetail>;
  onEditSystems: () => void;
  onEditAppliances: () => void;
}) {
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
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Home Systems</h2>
          <button
            onClick={onEditSystems}
            className="text-sm text-blue-600 hover:text-blue-700 dark:text-blue-400 font-medium"
          >
            Edit Systems
          </button>
        </div>
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

      {/* Appliances Section */}
      <div className="card">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Appliances</h2>
          <button
            onClick={onEditAppliances}
            className="text-sm text-blue-600 hover:text-blue-700 dark:text-blue-400 font-medium"
          >
            Edit Appliances
          </button>
        </div>
        {appliances && Object.keys(appliances).length > 0 ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {Object.entries(appliances).map(([key, appliance]) => (
              <div key={key} className="p-4 border border-slate-200 dark:border-slate-700 rounded-lg">
                {appliance.imageUrl && (
                  <img
                    src={appliance.imageUrl}
                    alt={appliance.name || key}
                    className="w-full h-32 object-cover rounded-lg mb-3"
                  />
                )}
                <h3 className="font-medium text-slate-900 dark:text-white mb-2">
                  {appliance.name || key.replace(/([A-Z])/g, ' $1').trim()}
                </h3>
                <div className="space-y-1 text-sm">
                  {appliance.brand && (
                    <p>
                      <span className="text-slate-500 dark:text-slate-400">Brand:</span>{' '}
                      <span className="text-slate-900 dark:text-white">{appliance.brand}</span>
                    </p>
                  )}
                  {appliance.model && (
                    <p>
                      <span className="text-slate-500 dark:text-slate-400">Model:</span>{' '}
                      <span className="text-slate-900 dark:text-white">{appliance.model}</span>
                    </p>
                  )}
                  {appliance.location && (
                    <p>
                      <span className="text-slate-500 dark:text-slate-400">Location:</span>{' '}
                      <span className="text-slate-900 dark:text-white">{appliance.location}</span>
                    </p>
                  )}
                  {appliance.warrantyExpires && (
                    <p>
                      <span className="text-slate-500 dark:text-slate-400">Warranty:</span>{' '}
                      <span className={new Date(appliance.warrantyExpires) < new Date() ? 'text-red-500' : 'text-green-600 dark:text-green-400'}>
                        {formatDate(appliance.warrantyExpires)}
                      </span>
                    </p>
                  )}
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center py-8 text-slate-400 dark:text-slate-500">
            <svg className="w-12 h-12 mx-auto mb-3 opacity-50" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 3v2m6-2v2M9 19v2m6-2v2M5 9H3m2 6H3m18-6h-2m2 6h-2M7 19h10a2 2 0 002-2V7a2 2 0 00-2-2H7a2 2 0 00-2 2v10a2 2 0 002 2zM9 9h6v6H9V9z" />
            </svg>
            <p>No appliances added yet</p>
            <button
              onClick={onEditAppliances}
              className="mt-3 text-sm text-blue-600 hover:text-blue-700 dark:text-blue-400"
            >
              Add your first appliance
            </button>
          </div>
        )}
      </div>
    </div>
  );
}

// Systems Management Modal
function SystemsManagementModal({
  systems,
  onSave,
  onClose,
  isSaving,
}: {
  systems: DetailedSystems;
  onSave: (systems: DetailedSystems) => void;
  onClose: () => void;
  isSaving: boolean;
}) {
  const systemTypes = [
    { key: 'hvac', label: 'HVAC / Air Conditioning' },
    { key: 'heating', label: 'Heating' },
    { key: 'waterHeater', label: 'Water Heater' },
    { key: 'electrical', label: 'Electrical Panel' },
    { key: 'plumbing', label: 'Plumbing' },
    { key: 'fireplace', label: 'Fireplace' },
    { key: 'roof', label: 'Roof' },
    { key: 'garage', label: 'Garage' },
    { key: 'pool', label: 'Pool' },
    { key: 'lawnCare', label: 'Lawn Care' },
    { key: 'houseCleaning', label: 'House Cleaning' },
    { key: 'pestControl', label: 'Pest Control' },
    { key: 'security', label: 'Security System' },
  ];

  const [editingSystems, setEditingSystems] = useState<DetailedSystems>(() => {
    const initial: DetailedSystems = {};
    systemTypes.forEach(({ key }) => {
      const systemKey = key as keyof DetailedSystems;
      if (systems[systemKey]) {
        (initial as Record<string, unknown>)[key] = systems[systemKey];
      }
    });
    return initial;
  });

  const [selectedSystem, setSelectedSystem] = useState<string | null>(null);
  const [showAddSystem, setShowAddSystem] = useState(false);

  const handleAddSystem = (systemKey: string) => {
    setEditingSystems(prev => ({
      ...prev,
      [systemKey]: { id: crypto.randomUUID() },
    }));
    setSelectedSystem(systemKey);
    setShowAddSystem(false);
  };

  const handleRemoveSystem = (systemKey: string) => {
    setEditingSystems(prev => {
      const next = { ...prev };
      delete (next as Record<string, unknown>)[systemKey];
      return next;
    });
    setSelectedSystem(null);
  };

  const handleUpdateSystem = (systemKey: string, field: string, value: string) => {
    setEditingSystems(prev => ({
      ...prev,
      [systemKey]: {
        ...(prev[systemKey as keyof DetailedSystems] as SystemDetail || {}),
        [field]: value,
      },
    }));
  };

  const handleImageUpload = async (systemKey: string, file: File) => {
    const reader = new FileReader();
    reader.onload = (e) => {
      const dataUrl = e.target?.result as string;
      handleUpdateSystem(systemKey, 'imageUrl', dataUrl);
    };
    reader.readAsDataURL(file);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSave(editingSystems);
  };

  const availableSystems = systemTypes.filter(
    ({ key }) => !editingSystems[key as keyof DetailedSystems]
  );

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      <div className="flex min-h-full items-center justify-center p-4">
        <div className="fixed inset-0 bg-black/50" onClick={onClose} />
        <div className="relative bg-white dark:bg-slate-900 rounded-xl shadow-xl w-full max-w-4xl max-h-[90vh] overflow-hidden">
          <div className="flex items-center justify-between p-4 border-b border-slate-200 dark:border-slate-700">
            <h2 className="text-lg font-semibold text-slate-900 dark:text-white">
              Manage Home Systems
            </h2>
            <button
              onClick={onClose}
              className="text-slate-400 hover:text-slate-600 dark:hover:text-slate-300"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <form onSubmit={handleSubmit}>
            <div className="flex h-[60vh]">
              <div className="w-64 border-r border-slate-200 dark:border-slate-700 overflow-y-auto">
                <div className="p-3">
                  <button
                    type="button"
                    onClick={() => setShowAddSystem(!showAddSystem)}
                    className="w-full flex items-center justify-center gap-2 px-3 py-2 text-sm font-medium text-blue-600 dark:text-blue-400 bg-blue-50 dark:bg-blue-900/20 rounded-lg hover:bg-blue-100 dark:hover:bg-blue-900/30"
                  >
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
                    </svg>
                    Add System
                  </button>

                  {showAddSystem && availableSystems.length > 0 && (
                    <div className="mt-2 p-2 bg-slate-50 dark:bg-slate-800 rounded-lg">
                      <p className="text-xs text-slate-500 dark:text-slate-400 mb-2">Select system type:</p>
                      <div className="space-y-1 max-h-48 overflow-y-auto">
                        {availableSystems.map(({ key, label }) => (
                          <button
                            key={key}
                            type="button"
                            onClick={() => handleAddSystem(key)}
                            className="w-full text-left px-2 py-1.5 text-sm text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-700 rounded"
                          >
                            {label}
                          </button>
                        ))}
                      </div>
                    </div>
                  )}
                </div>

                <div className="px-3 pb-3">
                  <p className="text-xs text-slate-500 dark:text-slate-400 mb-2 uppercase tracking-wide">Your Systems</p>
                  {Object.keys(editingSystems).length === 0 ? (
                    <p className="text-sm text-slate-400 dark:text-slate-500 italic">No systems added yet</p>
                  ) : (
                    <div className="space-y-1">
                      {Object.keys(editingSystems).map((key) => {
                        const systemType = systemTypes.find(s => s.key === key);
                        return (
                          <button
                            key={key}
                            type="button"
                            onClick={() => setSelectedSystem(key)}
                            className={`w-full text-left px-3 py-2 text-sm rounded-lg transition-colors ${
                              selectedSystem === key
                                ? 'bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300'
                                : 'text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800'
                            }`}
                          >
                            {systemType?.label || key}
                          </button>
                        );
                      })}
                    </div>
                  )}
                </div>
              </div>

              <div className="flex-1 overflow-y-auto p-4">
                {selectedSystem ? (
                  <SystemEditPanel
                    systemKey={selectedSystem}
                    systemLabel={systemTypes.find(s => s.key === selectedSystem)?.label || selectedSystem}
                    system={(editingSystems[selectedSystem as keyof DetailedSystems] as SystemDetail) || {}}
                    onUpdate={(field, value) => handleUpdateSystem(selectedSystem, field, value)}
                    onRemove={() => handleRemoveSystem(selectedSystem)}
                    onImageUpload={(file) => handleImageUpload(selectedSystem, file)}
                  />
                ) : (
                  <div className="h-full flex items-center justify-center text-slate-400 dark:text-slate-500">
                    <div className="text-center">
                      <svg className="w-12 h-12 mx-auto mb-3 opacity-50" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
                      </svg>
                      <p>Select a system to edit or add a new one</p>
                    </div>
                  </div>
                )}
              </div>
            </div>

            <div className="flex items-center justify-end gap-3 p-4 border-t border-slate-200 dark:border-slate-700">
              <button type="button" onClick={onClose} disabled={isSaving} className="btn btn-secondary">
                Cancel
              </button>
              <button type="submit" disabled={isSaving} className="btn btn-primary">
                {isSaving ? 'Saving...' : 'Save Changes'}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}

function SystemEditPanel({
  systemKey,
  systemLabel,
  system,
  onUpdate,
  onRemove,
  onImageUpload,
}: {
  systemKey: string;
  systemLabel: string;
  system: SystemDetail;
  onUpdate: (field: string, value: string) => void;
  onRemove: () => void;
  onImageUpload: (file: File) => void;
}) {
  const commonFields = [
    { key: 'type', label: 'Type', type: 'text', placeholder: 'e.g., Central AC, Tankless' },
    { key: 'brand', label: 'Brand', type: 'text', placeholder: 'e.g., Carrier, Rheem' },
    { key: 'model', label: 'Model', type: 'text', placeholder: 'Model number' },
    { key: 'serialNumber', label: 'Serial Number', type: 'text', placeholder: 'Serial number' },
    { key: 'installDate', label: 'Install Date', type: 'date' },
    { key: 'warrantyExpires', label: 'Warranty Expires', type: 'date' },
    { key: 'vendor', label: 'Service Vendor', type: 'text', placeholder: 'Company name' },
    { key: 'vendorPhone', label: 'Vendor Phone', type: 'tel', placeholder: '(555) 555-5555' },
    { key: 'lastServiceDate', label: 'Last Service Date', type: 'date' },
    { key: 'nextMaintenanceDate', label: 'Next Maintenance Due', type: 'date' },
    { key: 'location', label: 'Location in Home', type: 'text', placeholder: 'e.g., Basement, Garage' },
    { key: 'notes', label: 'Notes', type: 'textarea', placeholder: 'Any additional notes...' },
  ];

  const hvacFields = systemKey === 'hvac' ? [
    { key: 'filterSize', label: 'Filter Size', type: 'text', placeholder: 'e.g., 20x25x1' },
    { key: 'filterLastChanged', label: 'Filter Last Changed', type: 'date' },
    { key: 'filterNextChange', label: 'Filter Next Change', type: 'date' },
  ] : [];

  const allFields = [...commonFields.slice(0, 10), ...hvacFields, ...commonFields.slice(10)];

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h3 className="text-lg font-medium text-slate-900 dark:text-white">{systemLabel}</h3>
        <button
          type="button"
          onClick={onRemove}
          className="text-sm text-red-600 hover:text-red-700 dark:text-red-400"
        >
          Remove System
        </button>
      </div>

      <div className="p-4 border border-dashed border-slate-300 dark:border-slate-600 rounded-lg">
        <div className="text-center">
          {system.imageUrl ? (
            <div className="relative inline-block">
              <img
                src={system.imageUrl}
                alt={systemLabel}
                className="max-h-48 mx-auto rounded-lg object-contain"
              />
              <button
                type="button"
                onClick={() => onUpdate('imageUrl', '')}
                className="absolute top-2 right-2 p-1 bg-red-500 text-white rounded-full hover:bg-red-600"
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>
          ) : (
            <>
              <svg className="w-10 h-10 mx-auto text-slate-400 mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
              <p className="text-sm text-slate-500 dark:text-slate-400 mb-2">Add a photo of this system</p>
            </>
          )}
          <input
            type="file"
            accept="image/*"
            onChange={(e) => {
              const file = e.target.files?.[0];
              if (file) onImageUpload(file);
            }}
            className="hidden"
            id={`image-upload-${systemKey}`}
          />
          <label
            htmlFor={`image-upload-${systemKey}`}
            className="inline-block px-4 py-2 text-sm font-medium text-blue-600 dark:text-blue-400 bg-blue-50 dark:bg-blue-900/20 rounded-lg cursor-pointer hover:bg-blue-100 dark:hover:bg-blue-900/30"
          >
            {system.imageUrl ? 'Change Photo' : 'Upload Photo'}
          </label>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {allFields.map(({ key, label, type, placeholder }) => (
          <div key={key} className={type === 'textarea' ? 'md:col-span-2' : ''}>
            <label className="label block mb-1.5">{label}</label>
            {type === 'textarea' ? (
              <textarea
                value={(system[key] as string) || ''}
                onChange={(e) => onUpdate(key, e.target.value)}
                placeholder={placeholder}
                rows={3}
                className="input w-full"
              />
            ) : (
              <input
                type={type}
                value={(system[key] as string) || ''}
                onChange={(e) => onUpdate(key, e.target.value)}
                placeholder={placeholder}
                className="input w-full"
              />
            )}
          </div>
        ))}
      </div>
    </div>
  );
}

function AppliancesManagementModal({
  appliances,
  onSave,
  onClose,
  isSaving,
}: {
  appliances: Record<string, ApplianceDetail>;
  onSave: (appliances: Record<string, ApplianceDetail>) => void;
  onClose: () => void;
  isSaving: boolean;
}) {
  const [editingAppliances, setEditingAppliances] = useState<Record<string, ApplianceDetail>>(() => ({ ...appliances }));
  const [selectedAppliance, setSelectedAppliance] = useState<string | null>(null);
  const [newApplianceName, setNewApplianceName] = useState('');
  const [showAddForm, setShowAddForm] = useState(false);

  const suggestedAppliances = [
    'Refrigerator', 'Dishwasher', 'Microwave', 'Oven', 'Range',
    'Garbage Disposal', 'Trash Compactor', 'Wine Cooler',
    'Ice Maker', 'Coffee Maker', 'Stand Mixer', 'Food Processor',
    'Vacuum', 'Robot Vacuum', 'Air Purifier', 'Dehumidifier',
    'TV (Living Room)', 'TV (Bedroom)', 'Sound System', 'Gaming Console',
    'Ceiling Fan', 'Space Heater', 'Portable AC',
  ];

  const handleAddAppliance = (name: string) => {
    const key = name.toLowerCase().replace(/[^a-z0-9]+/g, '_');
    setEditingAppliances(prev => ({
      ...prev,
      [key]: { id: crypto.randomUUID(), name },
    }));
    setSelectedAppliance(key);
    setShowAddForm(false);
    setNewApplianceName('');
  };

  const handleRemoveAppliance = (key: string) => {
    setEditingAppliances(prev => {
      const next = { ...prev };
      delete next[key];
      return next;
    });
    setSelectedAppliance(null);
  };

  const handleUpdateAppliance = (key: string, field: string, value: string) => {
    setEditingAppliances(prev => ({
      ...prev,
      [key]: { ...prev[key], [field]: value },
    }));
  };

  const handleImageUpload = async (key: string, file: File) => {
    const reader = new FileReader();
    reader.onload = (e) => {
      const dataUrl = e.target?.result as string;
      handleUpdateAppliance(key, 'imageUrl', dataUrl);
    };
    reader.readAsDataURL(file);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSave(editingAppliances);
  };

  const existingNames = Object.values(editingAppliances).map(a => a.name?.toLowerCase());
  const availableSuggestions = suggestedAppliances.filter(
    name => !existingNames.includes(name.toLowerCase())
  );

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      <div className="flex min-h-full items-center justify-center p-4">
        <div className="fixed inset-0 bg-black/50" onClick={onClose} />
        <div className="relative bg-white dark:bg-slate-900 rounded-xl shadow-xl w-full max-w-4xl max-h-[90vh] overflow-hidden">
          <div className="flex items-center justify-between p-4 border-b border-slate-200 dark:border-slate-700">
            <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Manage Appliances</h2>
            <button
              onClick={onClose}
              className="text-slate-400 hover:text-slate-600 dark:hover:text-slate-300"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <form onSubmit={handleSubmit}>
            <div className="flex h-[60vh]">
              <div className="w-64 border-r border-slate-200 dark:border-slate-700 overflow-y-auto">
                <div className="p-3">
                  <button
                    type="button"
                    onClick={() => setShowAddForm(!showAddForm)}
                    className="w-full flex items-center justify-center gap-2 px-3 py-2 text-sm font-medium text-blue-600 dark:text-blue-400 bg-blue-50 dark:bg-blue-900/20 rounded-lg hover:bg-blue-100 dark:hover:bg-blue-900/30"
                  >
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
                    </svg>
                    Add Appliance
                  </button>

                  {showAddForm && (
                    <div className="mt-2 p-2 bg-slate-50 dark:bg-slate-800 rounded-lg">
                      <input
                        type="text"
                        value={newApplianceName}
                        onChange={(e) => setNewApplianceName(e.target.value)}
                        placeholder="Appliance name..."
                        className="input w-full mb-2 text-sm"
                        onKeyDown={(e) => {
                          if (e.key === 'Enter' && newApplianceName.trim()) {
                            e.preventDefault();
                            handleAddAppliance(newApplianceName.trim());
                          }
                        }}
                      />
                      {newApplianceName.trim() && (
                        <button
                          type="button"
                          onClick={() => handleAddAppliance(newApplianceName.trim())}
                          className="w-full text-left px-2 py-1.5 text-sm text-blue-600 dark:text-blue-400 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded"
                        >
                          Add &quot;{newApplianceName.trim()}&quot;
                        </button>
                      )}
                      <p className="text-xs text-slate-500 dark:text-slate-400 mt-2 mb-1">Or choose from:</p>
                      <div className="space-y-1 max-h-36 overflow-y-auto">
                        {availableSuggestions.slice(0, 10).map((name) => (
                          <button
                            key={name}
                            type="button"
                            onClick={() => handleAddAppliance(name)}
                            className="w-full text-left px-2 py-1 text-sm text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-700 rounded"
                          >
                            {name}
                          </button>
                        ))}
                      </div>
                    </div>
                  )}
                </div>

                <div className="px-3 pb-3">
                  <p className="text-xs text-slate-500 dark:text-slate-400 mb-2 uppercase tracking-wide">Your Appliances</p>
                  {Object.keys(editingAppliances).length === 0 ? (
                    <p className="text-sm text-slate-400 dark:text-slate-500 italic">No appliances added yet</p>
                  ) : (
                    <div className="space-y-1">
                      {Object.entries(editingAppliances).map(([key, appliance]) => (
                        <button
                          key={key}
                          type="button"
                          onClick={() => setSelectedAppliance(key)}
                          className={`w-full text-left px-3 py-2 text-sm rounded-lg transition-colors ${
                            selectedAppliance === key
                              ? 'bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300'
                              : 'text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800'
                          }`}
                        >
                          {appliance.name || key}
                        </button>
                      ))}
                    </div>
                  )}
                </div>
              </div>

              <div className="flex-1 overflow-y-auto p-4">
                {selectedAppliance && editingAppliances[selectedAppliance] ? (
                  <ApplianceEditPanel
                    applianceKey={selectedAppliance}
                    appliance={editingAppliances[selectedAppliance]}
                    onUpdate={(field, value) => handleUpdateAppliance(selectedAppliance, field, value)}
                    onRemove={() => handleRemoveAppliance(selectedAppliance)}
                    onImageUpload={(file) => handleImageUpload(selectedAppliance, file)}
                  />
                ) : (
                  <div className="h-full flex items-center justify-center text-slate-400 dark:text-slate-500">
                    <div className="text-center">
                      <svg className="w-12 h-12 mx-auto mb-3 opacity-50" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 3v2m6-2v2M9 19v2m6-2v2M5 9H3m2 6H3m18-6h-2m2 6h-2M7 19h10a2 2 0 002-2V7a2 2 0 00-2-2H7a2 2 0 00-2 2v10a2 2 0 002 2zM9 9h6v6H9V9z" />
                      </svg>
                      <p>Select an appliance to edit or add a new one</p>
                    </div>
                  </div>
                )}
              </div>
            </div>

            <div className="flex items-center justify-end gap-3 p-4 border-t border-slate-200 dark:border-slate-700">
              <button type="button" onClick={onClose} disabled={isSaving} className="btn btn-secondary">
                Cancel
              </button>
              <button type="submit" disabled={isSaving} className="btn btn-primary">
                {isSaving ? 'Saving...' : 'Save Changes'}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}

function ApplianceEditPanel({
  applianceKey,
  appliance,
  onUpdate,
  onRemove,
  onImageUpload,
}: {
  applianceKey: string;
  appliance: ApplianceDetail;
  onUpdate: (field: string, value: string) => void;
  onRemove: () => void;
  onImageUpload: (file: File) => void;
}) {
  const fields = [
    { key: 'name', label: 'Name', type: 'text', placeholder: 'Appliance name' },
    { key: 'brand', label: 'Brand', type: 'text', placeholder: 'e.g., Samsung, LG' },
    { key: 'model', label: 'Model', type: 'text', placeholder: 'Model number' },
    { key: 'serialNumber', label: 'Serial Number', type: 'text', placeholder: 'Serial number' },
    { key: 'installDate', label: 'Purchase/Install Date', type: 'date' },
    { key: 'warrantyExpires', label: 'Warranty Expires', type: 'date' },
    { key: 'lastService', label: 'Last Service Date', type: 'date' },
    { key: 'location', label: 'Location', type: 'text', placeholder: 'e.g., Kitchen, Living Room' },
    { key: 'notes', label: 'Notes', type: 'textarea', placeholder: 'Any additional notes...' },
  ];

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h3 className="text-lg font-medium text-slate-900 dark:text-white">
          {appliance.name || 'Unnamed Appliance'}
        </h3>
        <button
          type="button"
          onClick={onRemove}
          className="text-sm text-red-600 hover:text-red-700 dark:text-red-400"
        >
          Remove Appliance
        </button>
      </div>

      <div className="p-4 border border-dashed border-slate-300 dark:border-slate-600 rounded-lg">
        <div className="text-center">
          {appliance.imageUrl ? (
            <div className="relative inline-block">
              <img
                src={appliance.imageUrl}
                alt={appliance.name || 'Appliance'}
                className="max-h-48 mx-auto rounded-lg object-contain"
              />
              <button
                type="button"
                onClick={() => onUpdate('imageUrl', '')}
                className="absolute top-2 right-2 p-1 bg-red-500 text-white rounded-full hover:bg-red-600"
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>
          ) : (
            <>
              <svg className="w-10 h-10 mx-auto text-slate-400 mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
              <p className="text-sm text-slate-500 dark:text-slate-400 mb-2">Add a photo of this appliance</p>
            </>
          )}
          <input
            type="file"
            accept="image/*"
            onChange={(e) => {
              const file = e.target.files?.[0];
              if (file) onImageUpload(file);
            }}
            className="hidden"
            id={`appliance-image-${applianceKey}`}
          />
          <label
            htmlFor={`appliance-image-${applianceKey}`}
            className="inline-block px-4 py-2 text-sm font-medium text-blue-600 dark:text-blue-400 bg-blue-50 dark:bg-blue-900/20 rounded-lg cursor-pointer hover:bg-blue-100 dark:hover:bg-blue-900/30"
          >
            {appliance.imageUrl ? 'Change Photo' : 'Upload Photo'}
          </label>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {fields.map(({ key, label, type, placeholder }) => (
          <div key={key} className={type === 'textarea' ? 'md:col-span-2' : ''}>
            <label className="label block mb-1.5">{label}</label>
            {type === 'textarea' ? (
              <textarea
                value={(appliance[key as keyof ApplianceDetail] as string) || ''}
                onChange={(e) => onUpdate(key, e.target.value)}
                placeholder={placeholder}
                rows={3}
                className="input w-full"
              />
            ) : (
              <input
                type={type}
                value={(appliance[key as keyof ApplianceDetail] as string) || ''}
                onChange={(e) => onUpdate(key, e.target.value)}
                placeholder={placeholder}
                className="input w-full"
              />
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
