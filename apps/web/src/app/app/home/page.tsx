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

// Financial accounts - mortgages, loans, credit cards
interface FinancialAccount {
  id?: string;
  type: 'MORTGAGE' | 'CAR_LOAN' | 'STUDENT_LOAN' | 'PERSONAL_LOAN' | 'HELOC' | 'CREDIT_CARD' | 'OTHER';
  name: string;
  lender: string;
  accountNumber?: string;
  paymentAmount?: number;
  interestRate?: number;
  dueDay?: number; // Day of month payment is due
  autopay?: boolean;
  balance?: number;
  originalAmount?: number;
  startDate?: string;
  endDate?: string; // Payoff date
  notes?: string;
}

// Utility accounts - electric, gas, water, internet
interface UtilityAccount {
  id?: string;
  type: 'ELECTRIC' | 'GAS' | 'WATER_SEWER' | 'INTERNET' | 'CABLE' | 'PHONE' | 'TRASH' | 'OTHER';
  provider: string;
  accountNumber?: string;
  serviceAddress?: string;
  averageMonthlyBill?: number;
  dueDay?: number;
  autopay?: boolean;
  customerServicePhone?: string;
  portalUrl?: string;
  notes?: string;
}

// Vehicle information
interface Vehicle {
  id?: string;
  type: 'CAR' | 'TRUCK' | 'SUV' | 'MOTORCYCLE' | 'BOAT' | 'RV' | 'OTHER';
  year?: number;
  make: string;
  model: string;
  color?: string;
  vin?: string;
  licensePlate?: string;
  registrationExpires?: string;
  // Insurance
  insuranceCompany?: string;
  insurancePolicyNumber?: string;
  insuranceExpires?: string;
  insuranceAgent?: string;
  insuranceAgentPhone?: string;
  // Maintenance
  lastOilChange?: string;
  nextOilChangeMiles?: number;
  currentMileage?: number;
  preferredMechanic?: string;
  mechanicPhone?: string;
  notes?: string;
}

// Fuel delivery (oil/propane)
interface FuelDelivery {
  id?: string;
  fuelType: 'OIL' | 'PROPANE' | 'NATURAL_GAS';
  provider: string;
  accountNumber?: string;
  tankSize?: number; // gallons
  lastFillDate?: string;
  lastFillAmount?: number;
  pricePerGallon?: number;
  autoDelivery?: boolean;
  customerServicePhone?: string;
  emergencyPhone?: string;
  notes?: string;
}

interface DetailedSystems {
  heating?: SystemDetail & {
    fuelType?: 'GAS' | 'OIL' | 'PROPANE' | 'ELECTRIC' | 'HEAT_PUMP' | 'GEOTHERMAL';
  };
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
  snowRemoval?: SystemDetail & {
    serviceFrequency?: string;
    triggerDepth?: string; // e.g., "2 inches"
    includesSalting?: boolean;
    includesSidewalk?: boolean;
    includesDriveway?: boolean;
    services?: string[];
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
  septic?: SystemDetail & {
    tankSize?: number; // gallons
    lastPumped?: string;
    nextPumpDue?: string;
  };
  well?: SystemDetail & {
    depth?: number;
    lastTested?: string;
    nextTestDue?: string;
  };
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
  financialAccounts?: Record<string, FinancialAccount>;
  utilities?: Record<string, UtilityAccount>;
  vehicles?: Record<string, Vehicle>;
  fuelDelivery?: FuelDelivery;
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
  const [showFinancialModal, setShowFinancialModal] = useState(false);
  const [showUtilitiesModal, setShowUtilitiesModal] = useState(false);
  const [showVehiclesModal, setShowVehiclesModal] = useState(false);
  const [showFuelModal, setShowFuelModal] = useState(false);

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

  const handleSaveFinancialAccounts = async (financialAccounts: Record<string, FinancialAccount>) => {
    if (!currentHousehold || !homeProfile) return;

    setIsSaving(true);
    setError('');

    try {
      const newExtendedData = {
        ...extendedData,
        financialAccounts,
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
      setShowFinancialModal(false);
      setSuccessMessage('Financial accounts updated successfully');
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

  const handleSaveUtilities = async (utilities: Record<string, UtilityAccount>) => {
    if (!currentHousehold || !homeProfile) return;

    setIsSaving(true);
    setError('');

    try {
      const newExtendedData = {
        ...extendedData,
        utilities,
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
      setShowUtilitiesModal(false);
      setSuccessMessage('Utilities updated successfully');
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

  const handleSaveVehicles = async (vehicles: Record<string, Vehicle>) => {
    if (!currentHousehold || !homeProfile) return;

    setIsSaving(true);
    setError('');

    try {
      const newExtendedData = {
        ...extendedData,
        vehicles,
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
      setShowVehiclesModal(false);
      setSuccessMessage('Vehicles updated successfully');
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

  const handleSaveFuelDelivery = async (fuelDelivery: FuelDelivery) => {
    if (!currentHousehold || !homeProfile) return;

    setIsSaving(true);
    setError('');

    try {
      const newExtendedData = {
        ...extendedData,
        fuelDelivery,
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
      setShowFuelModal(false);
      setSuccessMessage('Fuel delivery info updated successfully');
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
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-600"></div>
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
              className="text-sm text-emerald-600 hover:text-emerald-700 dark:text-emerald-400 font-medium"
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

      {/* Comprehensive Home Systems View */}
      <ComprehensiveSystemsView
        systems={extendedData.systems}
        appliances={extendedData.appliances}
        onEditSystems={() => setShowSystemsModal(true)}
        onEditAppliances={() => setShowAppliancesModal(true)}
      />

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
              className="text-sm text-emerald-600 hover:text-emerald-700 dark:text-emerald-400 font-medium"
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

      {/* Financial Accounts Card */}
      <div className="card">
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center gap-2">
            <span className="text-xl">💳</span>
            <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Financial Accounts</h2>
          </div>
          <button
            onClick={() => setShowFinancialModal(true)}
            className="text-sm text-emerald-600 hover:text-emerald-700 dark:text-emerald-400 font-medium"
          >
            {extendedData.financialAccounts && Object.keys(extendedData.financialAccounts).length > 0 ? 'Edit' : 'Add Accounts'}
          </button>
        </div>
        {extendedData.financialAccounts && Object.keys(extendedData.financialAccounts).length > 0 ? (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {Object.entries(extendedData.financialAccounts).map(([key, account]) => (
              <div key={key} className="p-4 border border-slate-200 dark:border-slate-700 rounded-lg">
                <div className="flex items-center gap-2 mb-2">
                  <span className="text-lg">
                    {account.type === 'MORTGAGE' ? '🏠' : account.type === 'CAR_LOAN' ? '🚗' : account.type === 'CREDIT_CARD' ? '💳' : '📄'}
                  </span>
                  <h3 className="font-medium text-slate-900 dark:text-white">{account.name}</h3>
                </div>
                <div className="space-y-1 text-sm">
                  <div className="flex justify-between">
                    <span className="text-slate-500 dark:text-slate-400">Lender</span>
                    <span className="text-slate-900 dark:text-white">{account.lender}</span>
                  </div>
                  {account.accountNumber && (
                    <div className="flex justify-between">
                      <span className="text-slate-500 dark:text-slate-400">Account #</span>
                      <span className="text-slate-900 dark:text-white font-mono text-xs">****{account.accountNumber.slice(-4)}</span>
                    </div>
                  )}
                  {account.paymentAmount && (
                    <div className="flex justify-between">
                      <span className="text-slate-500 dark:text-slate-400">Payment</span>
                      <span className="text-slate-900 dark:text-white">${account.paymentAmount.toLocaleString()}/mo</span>
                    </div>
                  )}
                  {account.dueDay && (
                    <div className="flex justify-between">
                      <span className="text-slate-500 dark:text-slate-400">Due</span>
                      <span className="text-slate-900 dark:text-white">{account.dueDay}th of each month</span>
                    </div>
                  )}
                  {account.autopay && (
                    <span className="inline-flex items-center px-2 py-0.5 rounded text-xs bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-400">
                      Autopay enabled
                    </span>
                  )}
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center py-8 text-slate-400 dark:text-slate-500">
            <p>Track your mortgage, loans, and credit cards here</p>
            <button onClick={() => setShowFinancialModal(true)} className="mt-3 text-sm text-emerald-600 hover:text-emerald-700 dark:text-emerald-400">
              Add your first account
            </button>
          </div>
        )}
      </div>

      {/* Utilities Card */}
      <div className="card">
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center gap-2">
            <span className="text-xl">⚡</span>
            <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Utilities</h2>
          </div>
          <button
            onClick={() => setShowUtilitiesModal(true)}
            className="text-sm text-emerald-600 hover:text-emerald-700 dark:text-emerald-400 font-medium"
          >
            {extendedData.utilities && Object.keys(extendedData.utilities).length > 0 ? 'Edit' : 'Add Utilities'}
          </button>
        </div>
        {extendedData.utilities && Object.keys(extendedData.utilities).length > 0 ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {Object.entries(extendedData.utilities).map(([key, utility]) => (
              <div key={key} className="p-4 border border-slate-200 dark:border-slate-700 rounded-lg">
                <div className="flex items-center gap-2 mb-2">
                  <span className="text-lg">
                    {utility.type === 'ELECTRIC' ? '⚡' : utility.type === 'GAS' ? '🔥' : utility.type === 'WATER_SEWER' ? '💧' : utility.type === 'INTERNET' ? '🌐' : utility.type === 'CABLE' ? '📺' : utility.type === 'TRASH' ? '🗑️' : '📞'}
                  </span>
                  <h3 className="font-medium text-slate-900 dark:text-white capitalize">{utility.type.replace('_', ' ').toLowerCase()}</h3>
                </div>
                <div className="space-y-1 text-sm">
                  <div className="flex justify-between">
                    <span className="text-slate-500 dark:text-slate-400">Provider</span>
                    <span className="text-slate-900 dark:text-white">{utility.provider}</span>
                  </div>
                  {utility.accountNumber && (
                    <div className="flex justify-between">
                      <span className="text-slate-500 dark:text-slate-400">Account #</span>
                      <span className="text-slate-900 dark:text-white font-mono text-xs">{utility.accountNumber}</span>
                    </div>
                  )}
                  {utility.averageMonthlyBill && (
                    <div className="flex justify-between">
                      <span className="text-slate-500 dark:text-slate-400">Avg. Bill</span>
                      <span className="text-slate-900 dark:text-white">~${utility.averageMonthlyBill}/mo</span>
                    </div>
                  )}
                  {utility.customerServicePhone && (
                    <a href={`tel:${utility.customerServicePhone}`} className="text-emerald-600 dark:text-emerald-400 hover:underline text-xs">
                      {utility.customerServicePhone}
                    </a>
                  )}
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center py-8 text-slate-400 dark:text-slate-500">
            <p>Track your electric, gas, water, internet, and other utilities</p>
            <button onClick={() => setShowUtilitiesModal(true)} className="mt-3 text-sm text-emerald-600 hover:text-emerald-700 dark:text-emerald-400">
              Add your first utility
            </button>
          </div>
        )}
      </div>

      {/* Vehicles Card */}
      <div className="card">
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center gap-2">
            <span className="text-xl">🚗</span>
            <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Vehicles</h2>
          </div>
          <button
            onClick={() => setShowVehiclesModal(true)}
            className="text-sm text-emerald-600 hover:text-emerald-700 dark:text-emerald-400 font-medium"
          >
            {extendedData.vehicles && Object.keys(extendedData.vehicles).length > 0 ? 'Edit' : 'Add Vehicles'}
          </button>
        </div>
        {extendedData.vehicles && Object.keys(extendedData.vehicles).length > 0 ? (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {Object.entries(extendedData.vehicles).map(([key, vehicle]) => (
              <div key={key} className="p-4 border border-slate-200 dark:border-slate-700 rounded-lg">
                <div className="flex items-center justify-between mb-2">
                  <h3 className="font-medium text-slate-900 dark:text-white">
                    {vehicle.year} {vehicle.make} {vehicle.model}
                  </h3>
                  {vehicle.color && <span className="text-sm text-slate-500 dark:text-slate-400">{vehicle.color}</span>}
                </div>
                <div className="space-y-2 text-sm">
                  {vehicle.licensePlate && (
                    <div className="flex justify-between">
                      <span className="text-slate-500 dark:text-slate-400">License Plate</span>
                      <span className="text-slate-900 dark:text-white font-mono">{vehicle.licensePlate}</span>
                    </div>
                  )}
                  {vehicle.registrationExpires && (
                    <div className="flex justify-between">
                      <span className="text-slate-500 dark:text-slate-400">Registration</span>
                      <span className={new Date(vehicle.registrationExpires) < new Date() ? 'text-red-500' : 'text-slate-900 dark:text-white'}>
                        Expires {new Date(vehicle.registrationExpires).toLocaleDateString()}
                      </span>
                    </div>
                  )}
                  {vehicle.insuranceCompany && (
                    <div className="pt-2 border-t border-slate-100 dark:border-slate-700">
                      <div className="flex justify-between">
                        <span className="text-slate-500 dark:text-slate-400">Insurance</span>
                        <span className="text-slate-900 dark:text-white">{vehicle.insuranceCompany}</span>
                      </div>
                      {vehicle.insuranceExpires && (
                        <div className="flex justify-between">
                          <span className="text-slate-500 dark:text-slate-400">Policy Expires</span>
                          <span className={new Date(vehicle.insuranceExpires) < new Date() ? 'text-red-500' : 'text-green-600 dark:text-green-400'}>
                            {new Date(vehicle.insuranceExpires).toLocaleDateString()}
                          </span>
                        </div>
                      )}
                    </div>
                  )}
                  {vehicle.currentMileage && (
                    <div className="flex justify-between">
                      <span className="text-slate-500 dark:text-slate-400">Mileage</span>
                      <span className="text-slate-900 dark:text-white">{vehicle.currentMileage.toLocaleString()} mi</span>
                    </div>
                  )}
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center py-8 text-slate-400 dark:text-slate-500">
            <p>Track your vehicles, registrations, insurance, and maintenance</p>
            <button onClick={() => setShowVehiclesModal(true)} className="mt-3 text-sm text-emerald-600 hover:text-emerald-700 dark:text-emerald-400">
              Add your first vehicle
            </button>
          </div>
        )}
      </div>

      {/* Fuel Delivery Card (Oil/Propane) */}
      {(extendedData.fuelDelivery || (isDetailedSystems(extendedData.systems) && extendedData.systems.heating?.fuelType && ['OIL', 'PROPANE'].includes(extendedData.systems.heating.fuelType))) && (
        <div className="card">
          <div className="flex items-center justify-between mb-6">
            <div className="flex items-center gap-2">
              <span className="text-xl">🛢️</span>
              <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Fuel Delivery</h2>
            </div>
            <button
              onClick={() => setShowFuelModal(true)}
              className="text-sm text-emerald-600 hover:text-emerald-700 dark:text-emerald-400 font-medium"
            >
              {extendedData.fuelDelivery ? 'Edit' : 'Set Up'}
            </button>
          </div>
          {extendedData.fuelDelivery ? (
            <div className="p-4 border border-slate-200 dark:border-slate-700 rounded-lg">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-2 text-sm">
                  <div className="flex justify-between">
                    <span className="text-slate-500 dark:text-slate-400">Fuel Type</span>
                    <span className="text-slate-900 dark:text-white capitalize">{extendedData.fuelDelivery.fuelType.toLowerCase()}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-500 dark:text-slate-400">Provider</span>
                    <span className="text-slate-900 dark:text-white">{extendedData.fuelDelivery.provider}</span>
                  </div>
                  {extendedData.fuelDelivery.accountNumber && (
                    <div className="flex justify-between">
                      <span className="text-slate-500 dark:text-slate-400">Account #</span>
                      <span className="text-slate-900 dark:text-white">{extendedData.fuelDelivery.accountNumber}</span>
                    </div>
                  )}
                  {extendedData.fuelDelivery.tankSize && (
                    <div className="flex justify-between">
                      <span className="text-slate-500 dark:text-slate-400">Tank Size</span>
                      <span className="text-slate-900 dark:text-white">{extendedData.fuelDelivery.tankSize} gallons</span>
                    </div>
                  )}
                </div>
                <div className="space-y-2 text-sm">
                  {extendedData.fuelDelivery.lastFillDate && (
                    <div className="flex justify-between">
                      <span className="text-slate-500 dark:text-slate-400">Last Fill</span>
                      <span className="text-slate-900 dark:text-white">{new Date(extendedData.fuelDelivery.lastFillDate).toLocaleDateString()}</span>
                    </div>
                  )}
                  {extendedData.fuelDelivery.lastFillAmount && (
                    <div className="flex justify-between">
                      <span className="text-slate-500 dark:text-slate-400">Last Amount</span>
                      <span className="text-slate-900 dark:text-white">{extendedData.fuelDelivery.lastFillAmount} gallons</span>
                    </div>
                  )}
                  {extendedData.fuelDelivery.autoDelivery && (
                    <span className="inline-flex items-center px-2 py-0.5 rounded text-xs bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-400">
                      Auto-delivery enabled
                    </span>
                  )}
                  {extendedData.fuelDelivery.customerServicePhone && (
                    <a href={`tel:${extendedData.fuelDelivery.customerServicePhone}`} className="block text-emerald-600 dark:text-emerald-400 hover:underline">
                      {extendedData.fuelDelivery.customerServicePhone}
                    </a>
                  )}
                </div>
              </div>
            </div>
          ) : (
            <div className="text-center py-8 text-slate-400 dark:text-slate-500">
              <p>Track your heating oil or propane deliveries</p>
              <button onClick={() => setShowFuelModal(true)} className="mt-3 text-sm text-emerald-600 hover:text-emerald-700 dark:text-emerald-400">
                Set up fuel delivery tracking
              </button>
            </div>
          )}
        </div>
      )}

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

      {/* Financial Accounts Modal */}
      {showFinancialModal && (
        <FinancialAccountsModal
          accounts={extendedData.financialAccounts || {}}
          onSave={handleSaveFinancialAccounts}
          onClose={() => setShowFinancialModal(false)}
          isSaving={isSaving}
        />
      )}

      {/* Utilities Modal */}
      {showUtilitiesModal && (
        <UtilitiesModal
          utilities={extendedData.utilities || {}}
          onSave={handleSaveUtilities}
          onClose={() => setShowUtilitiesModal(false)}
          isSaving={isSaving}
        />
      )}

      {/* Vehicles Modal */}
      {showVehiclesModal && (
        <VehiclesModal
          vehicles={extendedData.vehicles || {}}
          onSave={handleSaveVehicles}
          onClose={() => setShowVehiclesModal(false)}
          isSaving={isSaving}
        />
      )}

      {/* Fuel Delivery Modal */}
      {showFuelModal && (
        <FuelDeliveryModal
          fuelDelivery={extendedData.fuelDelivery}
          onSave={handleSaveFuelDelivery}
          onClose={() => setShowFuelModal(false)}
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
    <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-emerald-100 text-emerald-800 dark:bg-emerald-900/30 dark:text-emerald-400">
      {label}
    </span>
  );
}

// Comprehensive Systems View - shows all home systems with full detail or prompts to add
function ComprehensiveSystemsView({
  systems,
  appliances,
  onEditSystems,
  onEditAppliances,
}: {
  systems?: HomeSystems | DetailedSystems;
  appliances?: Record<string, ApplianceDetail>;
  onEditSystems: () => void;
  onEditAppliances: () => void;
}) {
  const formatDate = (dateStr: string | undefined) => {
    if (!dateStr) return null;
    return new Date(dateStr).toLocaleDateString();
  };

  // Define all system categories we want to show
  const coreSystemCategories = [
    { key: 'heating', label: 'Heating / Furnace', icon: '🔥', description: 'Furnace, boiler, or heat pump' },
    { key: 'hvac', label: 'Air Conditioning', icon: '❄️', description: 'Central AC, mini-splits, or window units' },
    { key: 'waterHeater', label: 'Water Heater', icon: '🚿', description: 'Tank or tankless water heater' },
    { key: 'electrical', label: 'Electrical Panel', icon: '⚡', description: 'Main breaker panel' },
    { key: 'plumbing', label: 'Plumbing', icon: '🔧', description: 'Main water line and fixtures' },
    { key: 'roof', label: 'Roof', icon: '🏠', description: 'Roof type and condition' },
    { key: 'septic', label: 'Septic System', icon: '🚽', description: 'Septic tank and drain field' },
    { key: 'well', label: 'Well', icon: '💧', description: 'Water well and pump' },
    { key: 'garage', label: 'Garage Door', icon: '🚗', description: 'Garage door and opener' },
    { key: 'fireplace', label: 'Fireplace', icon: '🪵', description: 'Wood, gas, or electric fireplace' },
    { key: 'pool', label: 'Pool', icon: '🏊', description: 'Swimming pool and equipment' },
  ];

  const serviceCategories = [
    { key: 'lawnCare', label: 'Lawn Care', icon: '🌿', description: 'Mowing, landscaping, irrigation' },
    { key: 'snowRemoval', label: 'Snow Removal', icon: '❄️', description: 'Plowing and shoveling' },
    { key: 'houseCleaning', label: 'House Cleaning', icon: '🧹', description: 'Cleaning service' },
    { key: 'pestControl', label: 'Pest Control', icon: '🐜', description: 'Bug and rodent prevention' },
    { key: 'security', label: 'Security System', icon: '🔒', description: 'Alarm and monitoring' },
  ];

  const applianceCategories = [
    { key: 'refrigerator', label: 'Refrigerator', icon: '🧊' },
    { key: 'dishwasher', label: 'Dishwasher', icon: '🍽️' },
    { key: 'oven', label: 'Oven/Range', icon: '🍳' },
    { key: 'microwave', label: 'Microwave', icon: '📻' },
    { key: 'washer', label: 'Washer', icon: '🧺' },
    { key: 'dryer', label: 'Dryer', icon: '👕' },
    { key: 'garbageDisposal', label: 'Garbage Disposal', icon: '🗑️' },
  ];

  // Check if we have detailed systems data
  const detailedSystems = systems && isDetailedSystems(systems) ? systems : null;
  const basicSystems = systems && !isDetailedSystems(systems) ? systems as HomeSystems : null;

  // Helper to get system data from either format
  const getSystemData = (key: string): SystemDetail | null => {
    if (detailedSystems && detailedSystems[key as keyof DetailedSystems]) {
      return detailedSystems[key as keyof DetailedSystems] as SystemDetail;
    }
    return null;
  };

  // Convert basic system info to display format
  const getBasicSystemInfo = (key: string): { type?: string; age?: number } | null => {
    if (!basicSystems) return null;
    switch (key) {
      case 'hvac':
      case 'heating':
        return { type: basicSystems.hvacType, age: basicSystems.hvacAge };
      case 'roof':
        return { type: basicSystems.roofType, age: basicSystems.roofAge };
      case 'waterHeater':
        return { type: basicSystems.waterHeaterType, age: basicSystems.waterHeaterAge };
      case 'septic':
        return basicSystems.septicOrSewer === 'septic' ? { type: 'Septic' } : null;
      case 'electrical':
        return basicSystems.electricalPanelAmps ? { type: `${basicSystems.electricalPanelAmps} amps` } : null;
      case 'pool':
        return basicSystems.hasPool ? { type: 'Yes' } : null;
      case 'security':
        return basicSystems.hasSecuritySystem ? { type: 'Yes' } : null;
      default:
        return null;
    }
  };

  // Render a system card with full details or prompt to add
  const renderSystemCard = (category: { key: string; label: string; icon: string; description: string }) => {
    const system = getSystemData(category.key);
    const basicInfo = getBasicSystemInfo(category.key);
    const hasData = system || basicInfo;

    return (
      <div key={category.key} className="p-4 border border-slate-200 dark:border-slate-700 rounded-lg hover:border-emerald-300 dark:hover:border-emerald-700 transition-colors">
        <div className="flex items-start justify-between mb-3">
          <div className="flex items-center gap-2">
            <span className="text-xl">{category.icon}</span>
            <h3 className="font-semibold text-slate-900 dark:text-white">{category.label}</h3>
          </div>
          <button
            onClick={onEditSystems}
            className="text-xs text-emerald-600 hover:text-emerald-700 dark:text-emerald-400"
          >
            {hasData ? 'Edit' : 'Add'}
          </button>
        </div>

        {system ? (
          <div className="space-y-2 text-sm">
            {system.brand && (
              <div className="flex justify-between">
                <span className="text-slate-500 dark:text-slate-400">Brand/Model</span>
                <span className="text-slate-900 dark:text-white font-medium">{system.brand} {system.model || ''}</span>
              </div>
            )}
            {system.type && !system.brand && (
              <div className="flex justify-between">
                <span className="text-slate-500 dark:text-slate-400">Type</span>
                <span className="text-slate-900 dark:text-white">{system.type}</span>
              </div>
            )}
            {system.serialNumber && (
              <div className="flex justify-between">
                <span className="text-slate-500 dark:text-slate-400">Serial #</span>
                <span className="text-slate-900 dark:text-white font-mono text-xs">{system.serialNumber}</span>
              </div>
            )}
            {system.installDate && (
              <div className="flex justify-between">
                <span className="text-slate-500 dark:text-slate-400">Installed</span>
                <span className="text-slate-900 dark:text-white">{formatDate(system.installDate)}</span>
              </div>
            )}
            {system.vendor && (
              <div className="pt-2 mt-2 border-t border-slate-100 dark:border-slate-700">
                <div className="flex justify-between">
                  <span className="text-slate-500 dark:text-slate-400">Service Vendor</span>
                  <span className="text-slate-900 dark:text-white">{system.vendor}</span>
                </div>
                {system.vendorPhone && (
                  <a href={`tel:${system.vendorPhone}`} className="text-emerald-600 dark:text-emerald-400 hover:underline text-xs">
                    {system.vendorPhone}
                  </a>
                )}
              </div>
            )}
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
                    <span className="text-slate-500 dark:text-slate-400">Next Service</span>
                    <span className={`font-medium ${new Date(system.nextMaintenanceDate) < new Date() ? 'text-red-500' : 'text-green-600 dark:text-green-400'}`}>
                      {formatDate(system.nextMaintenanceDate)}
                    </span>
                  </div>
                )}
              </div>
            )}
            {system.warrantyExpires && (
              <div className="flex justify-between pt-1">
                <span className="text-slate-500 dark:text-slate-400">Warranty</span>
                <span className={new Date(system.warrantyExpires) < new Date() ? 'text-red-500' : 'text-green-600 dark:text-green-400'}>
                  {formatDate(system.warrantyExpires)}
                </span>
              </div>
            )}
          </div>
        ) : basicInfo ? (
          <div className="space-y-2 text-sm">
            <div className="flex justify-between">
              <span className="text-slate-500 dark:text-slate-400">Type</span>
              <span className="text-slate-900 dark:text-white">{basicInfo.type}</span>
            </div>
            {basicInfo.age && (
              <div className="flex justify-between">
                <span className="text-slate-500 dark:text-slate-400">Age</span>
                <span className="text-slate-900 dark:text-white">{basicInfo.age} years</span>
              </div>
            )}
            <p className="text-xs text-amber-600 dark:text-amber-400 mt-2 pt-2 border-t border-slate-100 dark:border-slate-700">
              Add brand, model, and service info →
            </p>
          </div>
        ) : (
          <p className="text-sm text-slate-400 dark:text-slate-500">
            {category.description}
          </p>
        )}
      </div>
    );
  };

  // Render appliance card
  const renderApplianceCard = (category: { key: string; label: string; icon: string }) => {
    const appliance = appliances?.[category.key];

    return (
      <div key={category.key} className="p-3 border border-slate-200 dark:border-slate-700 rounded-lg hover:border-emerald-300 dark:hover:border-emerald-700 transition-colors">
        <div className="flex items-center justify-between mb-2">
          <div className="flex items-center gap-2">
            <span className="text-lg">{category.icon}</span>
            <h4 className="font-medium text-slate-900 dark:text-white text-sm">{category.label}</h4>
          </div>
          <button
            onClick={onEditAppliances}
            className="text-xs text-emerald-600 hover:text-emerald-700 dark:text-emerald-400"
          >
            {appliance ? 'Edit' : 'Add'}
          </button>
        </div>

        {appliance ? (
          <div className="space-y-1 text-xs">
            {appliance.brand && (
              <p className="text-slate-900 dark:text-white">{appliance.brand} {appliance.model || ''}</p>
            )}
            {appliance.serialNumber && (
              <p className="text-slate-500 dark:text-slate-400 font-mono">SN: {appliance.serialNumber}</p>
            )}
            {appliance.warrantyExpires && (
              <p className={new Date(appliance.warrantyExpires) < new Date() ? 'text-red-500' : 'text-green-600 dark:text-green-400'}>
                Warranty: {formatDate(appliance.warrantyExpires)}
              </p>
            )}
          </div>
        ) : (
          <p className="text-xs text-slate-400 dark:text-slate-500">Not added</p>
        )}
      </div>
    );
  };

  return (
    <div className="space-y-6">
      {/* Core Home Systems */}
      <div className="card">
        <div className="flex items-center justify-between mb-6">
          <div>
            <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Home Systems</h2>
            <p className="text-sm text-slate-500 dark:text-slate-400">Major systems and equipment in your home</p>
          </div>
          <button
            onClick={onEditSystems}
            className="btn btn-secondary text-sm"
          >
            Manage All
          </button>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {coreSystemCategories.map(renderSystemCard)}
        </div>
      </div>

      {/* Service Providers */}
      <div className="card">
        <div className="flex items-center justify-between mb-6">
          <div>
            <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Service Providers</h2>
            <p className="text-sm text-slate-500 dark:text-slate-400">Your regular home service vendors</p>
          </div>
          <button
            onClick={onEditSystems}
            className="btn btn-secondary text-sm"
          >
            Manage All
          </button>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {serviceCategories.map(renderSystemCard)}
        </div>
      </div>

      {/* Appliances */}
      <div className="card">
        <div className="flex items-center justify-between mb-6">
          <div>
            <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Appliances</h2>
            <p className="text-sm text-slate-500 dark:text-slate-400">Track your major appliances for warranty and service</p>
          </div>
          <button
            onClick={onEditAppliances}
            className="btn btn-secondary text-sm"
          >
            Manage All
          </button>
        </div>
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3">
          {applianceCategories.map(renderApplianceCard)}
        </div>
      </div>
    </div>
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
              <input type="checkbox" {...register(feature.name as keyof SystemsData)} className="w-4 h-4 text-emerald-600 rounded" />
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
                className="w-4 h-4 text-emerald-600 rounded"
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
                className="w-4 h-4 text-emerald-600 rounded"
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
            className="text-sm text-emerald-600 hover:text-emerald-700 dark:text-emerald-400 font-medium"
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
                          <a href={`tel:${system.vendorPhone}`} className="text-emerald-600 dark:text-emerald-400 hover:underline">
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
                      <button className="mt-2 text-xs text-emerald-600 dark:text-emerald-400 hover:underline">
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
                      <a href={`tel:${svc.vendorPhone}`} className="text-emerald-600 dark:text-emerald-400 hover:underline">
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
            className="text-sm text-emerald-600 hover:text-emerald-700 dark:text-emerald-400 font-medium"
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
              className="mt-3 text-sm text-emerald-600 hover:text-emerald-700 dark:text-emerald-400"
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
    { key: 'heating', label: 'Heating / Furnace' },
    { key: 'hvac', label: 'Air Conditioning' },
    { key: 'waterHeater', label: 'Water Heater' },
    { key: 'electrical', label: 'Electrical Panel' },
    { key: 'plumbing', label: 'Plumbing' },
    { key: 'roof', label: 'Roof' },
    { key: 'septic', label: 'Septic System' },
    { key: 'well', label: 'Well' },
    { key: 'garage', label: 'Garage Door' },
    { key: 'fireplace', label: 'Fireplace' },
    { key: 'pool', label: 'Pool' },
    { key: 'lawnCare', label: 'Lawn Care' },
    { key: 'snowRemoval', label: 'Snow Removal' },
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
                    className="w-full flex items-center justify-center gap-2 px-3 py-2 text-sm font-medium text-emerald-600 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-900/20 rounded-lg hover:bg-emerald-100 dark:hover:bg-emerald-900/30"
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
                                ? 'bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-300'
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
            className="inline-block px-4 py-2 text-sm font-medium text-emerald-600 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-900/20 rounded-lg cursor-pointer hover:bg-emerald-100 dark:hover:bg-emerald-900/30"
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
                    className="w-full flex items-center justify-center gap-2 px-3 py-2 text-sm font-medium text-emerald-600 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-900/20 rounded-lg hover:bg-emerald-100 dark:hover:bg-emerald-900/30"
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
                          className="w-full text-left px-2 py-1.5 text-sm text-emerald-600 dark:text-emerald-400 hover:bg-emerald-50 dark:hover:bg-emerald-900/20 rounded"
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
                              ? 'bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-300'
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
            className="inline-block px-4 py-2 text-sm font-medium text-emerald-600 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-900/20 rounded-lg cursor-pointer hover:bg-emerald-100 dark:hover:bg-emerald-900/30"
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

// Financial Accounts Modal
function FinancialAccountsModal({
  accounts,
  onSave,
  onClose,
  isSaving,
}: {
  accounts: Record<string, FinancialAccount>;
  onSave: (accounts: Record<string, FinancialAccount>) => void;
  onClose: () => void;
  isSaving: boolean;
}) {
  const [editingAccounts, setEditingAccounts] = useState<Record<string, FinancialAccount>>(() => ({ ...accounts }));
  const [selectedAccount, setSelectedAccount] = useState<string | null>(null);
  const [showAddForm, setShowAddForm] = useState(false);

  const accountTypes = [
    { value: 'MORTGAGE', label: 'Mortgage', icon: '🏠' },
    { value: 'CAR_LOAN', label: 'Car Loan', icon: '🚗' },
    { value: 'STUDENT_LOAN', label: 'Student Loan', icon: '🎓' },
    { value: 'PERSONAL_LOAN', label: 'Personal Loan', icon: '💵' },
    { value: 'HELOC', label: 'HELOC', icon: '🏦' },
    { value: 'CREDIT_CARD', label: 'Credit Card', icon: '💳' },
    { value: 'OTHER', label: 'Other', icon: '📄' },
  ];

  const handleAddAccount = (type: FinancialAccount['type']) => {
    const key = `${type.toLowerCase()}_${Date.now()}`;
    setEditingAccounts(prev => ({
      ...prev,
      [key]: { id: crypto.randomUUID(), type, name: accountTypes.find(t => t.value === type)?.label || type, lender: '' },
    }));
    setSelectedAccount(key);
    setShowAddForm(false);
  };

  const handleRemoveAccount = (key: string) => {
    setEditingAccounts(prev => {
      const next = { ...prev };
      delete next[key];
      return next;
    });
    setSelectedAccount(null);
  };

  const handleUpdateAccount = (key: string, field: string, value: string | number | boolean) => {
    setEditingAccounts(prev => {
      const existing = prev[key];
      if (!existing) return prev;
      return {
        ...prev,
        [key]: { ...existing, [field]: value } as FinancialAccount,
      };
    });
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSave(editingAccounts);
  };

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      <div className="flex min-h-full items-center justify-center p-4">
        <div className="fixed inset-0 bg-black/50" onClick={onClose} />
        <div className="relative bg-white dark:bg-slate-900 rounded-xl shadow-xl w-full max-w-3xl max-h-[90vh] overflow-hidden">
          <div className="flex items-center justify-between p-4 border-b border-slate-200 dark:border-slate-700">
            <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Manage Financial Accounts</h2>
            <button onClick={onClose} className="text-slate-400 hover:text-slate-600 dark:hover:text-slate-300">
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <form onSubmit={handleSubmit}>
            <div className="flex h-[60vh]">
              <div className="w-56 border-r border-slate-200 dark:border-slate-700 overflow-y-auto p-3">
                <button
                  type="button"
                  onClick={() => setShowAddForm(!showAddForm)}
                  className="w-full flex items-center justify-center gap-2 px-3 py-2 text-sm font-medium text-emerald-600 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-900/20 rounded-lg hover:bg-emerald-100 dark:hover:bg-emerald-900/30 mb-3"
                >
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
                  </svg>
                  Add Account
                </button>

                {showAddForm && (
                  <div className="mb-3 p-2 bg-slate-50 dark:bg-slate-800 rounded-lg space-y-1">
                    {accountTypes.map(({ value, label, icon }) => (
                      <button
                        key={value}
                        type="button"
                        onClick={() => handleAddAccount(value as FinancialAccount['type'])}
                        className="w-full text-left px-2 py-1.5 text-sm text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-700 rounded flex items-center gap-2"
                      >
                        <span>{icon}</span> {label}
                      </button>
                    ))}
                  </div>
                )}

                <div className="space-y-1">
                  {Object.entries(editingAccounts).map(([key, account]) => (
                    <button
                      key={key}
                      type="button"
                      onClick={() => setSelectedAccount(key)}
                      className={`w-full text-left px-3 py-2 text-sm rounded-lg transition-colors ${
                        selectedAccount === key
                          ? 'bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-300'
                          : 'text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800'
                      }`}
                    >
                      {account.name}
                    </button>
                  ))}
                </div>
              </div>

              <div className="flex-1 overflow-y-auto p-4">
                {selectedAccount && editingAccounts[selectedAccount] ? (
                  <div className="space-y-4">
                    <div className="flex items-center justify-between">
                      <h3 className="text-lg font-medium text-slate-900 dark:text-white">{editingAccounts[selectedAccount].name}</h3>
                      <button type="button" onClick={() => handleRemoveAccount(selectedAccount)} className="text-sm text-red-600 hover:text-red-700">
                        Remove
                      </button>
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <label className="label block mb-1.5">Account Name</label>
                        <input type="text" value={editingAccounts[selectedAccount].name} onChange={(e) => handleUpdateAccount(selectedAccount, 'name', e.target.value)} className="input w-full" placeholder="e.g., Primary Mortgage" />
                      </div>
                      <div>
                        <label className="label block mb-1.5">Lender</label>
                        <input type="text" value={editingAccounts[selectedAccount].lender} onChange={(e) => handleUpdateAccount(selectedAccount, 'lender', e.target.value)} className="input w-full" placeholder="e.g., Wells Fargo" />
                      </div>
                      <div>
                        <label className="label block mb-1.5">Account Number</label>
                        <input type="text" value={editingAccounts[selectedAccount].accountNumber || ''} onChange={(e) => handleUpdateAccount(selectedAccount, 'accountNumber', e.target.value)} className="input w-full" placeholder="Account number" />
                      </div>
                      <div>
                        <label className="label block mb-1.5">Monthly Payment</label>
                        <div className="relative">
                          <span className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400">$</span>
                          <input type="number" value={editingAccounts[selectedAccount].paymentAmount || ''} onChange={(e) => handleUpdateAccount(selectedAccount, 'paymentAmount', e.target.value ? parseFloat(e.target.value) : 0)} className="input w-full pl-7" placeholder="0.00" />
                        </div>
                      </div>
                      <div>
                        <label className="label block mb-1.5">Due Day of Month</label>
                        <input type="number" min="1" max="31" value={editingAccounts[selectedAccount].dueDay || ''} onChange={(e) => handleUpdateAccount(selectedAccount, 'dueDay', e.target.value ? parseInt(e.target.value) : 0)} className="input w-full" placeholder="e.g., 15" />
                      </div>
                      <div>
                        <label className="label block mb-1.5">Interest Rate (%)</label>
                        <input type="number" step="0.01" value={editingAccounts[selectedAccount].interestRate || ''} onChange={(e) => handleUpdateAccount(selectedAccount, 'interestRate', e.target.value ? parseFloat(e.target.value) : 0)} className="input w-full" placeholder="e.g., 6.5" />
                      </div>
                      <div className="col-span-2">
                        <label className="flex items-center gap-3 cursor-pointer">
                          <input type="checkbox" checked={editingAccounts[selectedAccount].autopay || false} onChange={(e) => handleUpdateAccount(selectedAccount, 'autopay', e.target.checked)} className="w-4 h-4 text-emerald-600 rounded" />
                          <span className="text-sm text-slate-700 dark:text-slate-300">Autopay is enabled</span>
                        </label>
                      </div>
                      <div className="col-span-2">
                        <label className="label block mb-1.5">Notes</label>
                        <textarea value={editingAccounts[selectedAccount].notes || ''} onChange={(e) => handleUpdateAccount(selectedAccount, 'notes', e.target.value)} className="input w-full" rows={2} placeholder="Any notes..." />
                      </div>
                    </div>
                  </div>
                ) : (
                  <div className="h-full flex items-center justify-center text-slate-400 dark:text-slate-500">
                    <p>Select an account or add a new one</p>
                  </div>
                )}
              </div>
            </div>

            <div className="flex items-center justify-end gap-3 p-4 border-t border-slate-200 dark:border-slate-700">
              <button type="button" onClick={onClose} disabled={isSaving} className="btn btn-secondary">Cancel</button>
              <button type="submit" disabled={isSaving} className="btn btn-primary">{isSaving ? 'Saving...' : 'Save Changes'}</button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}

// Utilities Modal
function UtilitiesModal({
  utilities,
  onSave,
  onClose,
  isSaving,
}: {
  utilities: Record<string, UtilityAccount>;
  onSave: (utilities: Record<string, UtilityAccount>) => void;
  onClose: () => void;
  isSaving: boolean;
}) {
  const [editingUtilities, setEditingUtilities] = useState<Record<string, UtilityAccount>>(() => ({ ...utilities }));
  const [selectedUtility, setSelectedUtility] = useState<string | null>(null);
  const [showAddForm, setShowAddForm] = useState(false);

  const utilityTypes = [
    { value: 'ELECTRIC', label: 'Electric', icon: '⚡' },
    { value: 'GAS', label: 'Gas', icon: '🔥' },
    { value: 'WATER_SEWER', label: 'Water & Sewer', icon: '💧' },
    { value: 'INTERNET', label: 'Internet', icon: '🌐' },
    { value: 'CABLE', label: 'Cable/TV', icon: '📺' },
    { value: 'PHONE', label: 'Phone', icon: '📞' },
    { value: 'TRASH', label: 'Trash', icon: '🗑️' },
    { value: 'OTHER', label: 'Other', icon: '📄' },
  ];

  const handleAddUtility = (type: UtilityAccount['type']) => {
    const key = `${type.toLowerCase()}_${Date.now()}`;
    setEditingUtilities(prev => ({
      ...prev,
      [key]: { id: crypto.randomUUID(), type, provider: '' },
    }));
    setSelectedUtility(key);
    setShowAddForm(false);
  };

  const handleRemoveUtility = (key: string) => {
    setEditingUtilities(prev => {
      const next = { ...prev };
      delete next[key];
      return next;
    });
    setSelectedUtility(null);
  };

  const handleUpdateUtility = (key: string, field: string, value: string | number | boolean) => {
    setEditingUtilities(prev => {
      const existing = prev[key];
      if (!existing) return prev;
      return {
        ...prev,
        [key]: { ...existing, [field]: value } as UtilityAccount,
      };
    });
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSave(editingUtilities);
  };

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      <div className="flex min-h-full items-center justify-center p-4">
        <div className="fixed inset-0 bg-black/50" onClick={onClose} />
        <div className="relative bg-white dark:bg-slate-900 rounded-xl shadow-xl w-full max-w-3xl max-h-[90vh] overflow-hidden">
          <div className="flex items-center justify-between p-4 border-b border-slate-200 dark:border-slate-700">
            <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Manage Utilities</h2>
            <button onClick={onClose} className="text-slate-400 hover:text-slate-600 dark:hover:text-slate-300">
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <form onSubmit={handleSubmit}>
            <div className="flex h-[60vh]">
              <div className="w-56 border-r border-slate-200 dark:border-slate-700 overflow-y-auto p-3">
                <button type="button" onClick={() => setShowAddForm(!showAddForm)} className="w-full flex items-center justify-center gap-2 px-3 py-2 text-sm font-medium text-emerald-600 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-900/20 rounded-lg hover:bg-emerald-100 dark:hover:bg-emerald-900/30 mb-3">
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" /></svg>
                  Add Utility
                </button>
                {showAddForm && (
                  <div className="mb-3 p-2 bg-slate-50 dark:bg-slate-800 rounded-lg space-y-1">
                    {utilityTypes.map(({ value, label, icon }) => (
                      <button key={value} type="button" onClick={() => handleAddUtility(value as UtilityAccount['type'])} className="w-full text-left px-2 py-1.5 text-sm text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-700 rounded flex items-center gap-2">
                        <span>{icon}</span> {label}
                      </button>
                    ))}
                  </div>
                )}
                <div className="space-y-1">
                  {Object.entries(editingUtilities).map(([key, utility]) => (
                    <button key={key} type="button" onClick={() => setSelectedUtility(key)} className={`w-full text-left px-3 py-2 text-sm rounded-lg transition-colors ${selectedUtility === key ? 'bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-300' : 'text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800'}`}>
                      {utilityTypes.find(t => t.value === utility.type)?.icon} {utility.provider || utility.type}
                    </button>
                  ))}
                </div>
              </div>

              <div className="flex-1 overflow-y-auto p-4">
                {selectedUtility && editingUtilities[selectedUtility] ? (
                  <div className="space-y-4">
                    <div className="flex items-center justify-between">
                      <h3 className="text-lg font-medium text-slate-900 dark:text-white capitalize">{editingUtilities[selectedUtility].type.replace('_', ' ').toLowerCase()}</h3>
                      <button type="button" onClick={() => handleRemoveUtility(selectedUtility)} className="text-sm text-red-600 hover:text-red-700">Remove</button>
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                      <div><label className="label block mb-1.5">Provider</label><input type="text" value={editingUtilities[selectedUtility].provider} onChange={(e) => handleUpdateUtility(selectedUtility, 'provider', e.target.value)} className="input w-full" placeholder="e.g., Duke Energy" /></div>
                      <div><label className="label block mb-1.5">Account Number</label><input type="text" value={editingUtilities[selectedUtility].accountNumber || ''} onChange={(e) => handleUpdateUtility(selectedUtility, 'accountNumber', e.target.value)} className="input w-full" placeholder="Account number" /></div>
                      <div><label className="label block mb-1.5">Average Monthly Bill</label><div className="relative"><span className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400">$</span><input type="number" value={editingUtilities[selectedUtility].averageMonthlyBill || ''} onChange={(e) => handleUpdateUtility(selectedUtility, 'averageMonthlyBill', e.target.value ? parseFloat(e.target.value) : 0)} className="input w-full pl-7" placeholder="0.00" /></div></div>
                      <div><label className="label block mb-1.5">Due Day of Month</label><input type="number" min="1" max="31" value={editingUtilities[selectedUtility].dueDay || ''} onChange={(e) => handleUpdateUtility(selectedUtility, 'dueDay', e.target.value ? parseInt(e.target.value) : 0)} className="input w-full" placeholder="e.g., 15" /></div>
                      <div><label className="label block mb-1.5">Customer Service Phone</label><input type="tel" value={editingUtilities[selectedUtility].customerServicePhone || ''} onChange={(e) => handleUpdateUtility(selectedUtility, 'customerServicePhone', e.target.value)} className="input w-full" placeholder="(555) 555-5555" /></div>
                      <div><label className="label block mb-1.5">Portal URL</label><input type="url" value={editingUtilities[selectedUtility].portalUrl || ''} onChange={(e) => handleUpdateUtility(selectedUtility, 'portalUrl', e.target.value)} className="input w-full" placeholder="https://..." /></div>
                      <div className="col-span-2"><label className="flex items-center gap-3 cursor-pointer"><input type="checkbox" checked={editingUtilities[selectedUtility].autopay || false} onChange={(e) => handleUpdateUtility(selectedUtility, 'autopay', e.target.checked)} className="w-4 h-4 text-emerald-600 rounded" /><span className="text-sm text-slate-700 dark:text-slate-300">Autopay is enabled</span></label></div>
                      <div className="col-span-2"><label className="label block mb-1.5">Notes</label><textarea value={editingUtilities[selectedUtility].notes || ''} onChange={(e) => handleUpdateUtility(selectedUtility, 'notes', e.target.value)} className="input w-full" rows={2} placeholder="Any notes..." /></div>
                    </div>
                  </div>
                ) : (
                  <div className="h-full flex items-center justify-center text-slate-400 dark:text-slate-500"><p>Select a utility or add a new one</p></div>
                )}
              </div>
            </div>
            <div className="flex items-center justify-end gap-3 p-4 border-t border-slate-200 dark:border-slate-700">
              <button type="button" onClick={onClose} disabled={isSaving} className="btn btn-secondary">Cancel</button>
              <button type="submit" disabled={isSaving} className="btn btn-primary">{isSaving ? 'Saving...' : 'Save Changes'}</button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}

// Vehicles Modal
function VehiclesModal({
  vehicles,
  onSave,
  onClose,
  isSaving,
}: {
  vehicles: Record<string, Vehicle>;
  onSave: (vehicles: Record<string, Vehicle>) => void;
  onClose: () => void;
  isSaving: boolean;
}) {
  const [editingVehicles, setEditingVehicles] = useState<Record<string, Vehicle>>(() => ({ ...vehicles }));
  const [selectedVehicle, setSelectedVehicle] = useState<string | null>(null);
  const [showAddForm, setShowAddForm] = useState(false);

  const vehicleTypes = [
    { value: 'CAR', label: 'Car', icon: '🚗' },
    { value: 'TRUCK', label: 'Truck', icon: '🛻' },
    { value: 'SUV', label: 'SUV', icon: '🚙' },
    { value: 'MOTORCYCLE', label: 'Motorcycle', icon: '🏍️' },
    { value: 'BOAT', label: 'Boat', icon: '🚤' },
    { value: 'RV', label: 'RV', icon: '🚐' },
    { value: 'OTHER', label: 'Other', icon: '🚘' },
  ];

  const handleAddVehicle = (type: Vehicle['type']) => {
    const key = `${type.toLowerCase()}_${Date.now()}`;
    setEditingVehicles(prev => ({ ...prev, [key]: { id: crypto.randomUUID(), type, make: '', model: '' } }));
    setSelectedVehicle(key);
    setShowAddForm(false);
  };

  const handleRemoveVehicle = (key: string) => {
    setEditingVehicles(prev => { const next = { ...prev }; delete next[key]; return next; });
    setSelectedVehicle(null);
  };

  const handleUpdateVehicle = (key: string, field: string, value: string | number | undefined) => {
    setEditingVehicles(prev => {
      const existing = prev[key];
      if (!existing) return prev;
      return { ...prev, [key]: { ...existing, [field]: value } as Vehicle };
    });
  };

  const handleSubmit = (e: React.FormEvent) => { e.preventDefault(); onSave(editingVehicles); };

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      <div className="flex min-h-full items-center justify-center p-4">
        <div className="fixed inset-0 bg-black/50" onClick={onClose} />
        <div className="relative bg-white dark:bg-slate-900 rounded-xl shadow-xl w-full max-w-4xl max-h-[90vh] overflow-hidden">
          <div className="flex items-center justify-between p-4 border-b border-slate-200 dark:border-slate-700">
            <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Manage Vehicles</h2>
            <button onClick={onClose} className="text-slate-400 hover:text-slate-600 dark:hover:text-slate-300"><svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" /></svg></button>
          </div>
          <form onSubmit={handleSubmit}>
            <div className="flex h-[60vh]">
              <div className="w-56 border-r border-slate-200 dark:border-slate-700 overflow-y-auto p-3">
                <button type="button" onClick={() => setShowAddForm(!showAddForm)} className="w-full flex items-center justify-center gap-2 px-3 py-2 text-sm font-medium text-emerald-600 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-900/20 rounded-lg hover:bg-emerald-100 dark:hover:bg-emerald-900/30 mb-3">
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" /></svg>Add Vehicle
                </button>
                {showAddForm && (
                  <div className="mb-3 p-2 bg-slate-50 dark:bg-slate-800 rounded-lg space-y-1">
                    {vehicleTypes.map(({ value, label, icon }) => (<button key={value} type="button" onClick={() => handleAddVehicle(value as Vehicle['type'])} className="w-full text-left px-2 py-1.5 text-sm text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-700 rounded flex items-center gap-2"><span>{icon}</span> {label}</button>))}
                  </div>
                )}
                <div className="space-y-1">
                  {Object.entries(editingVehicles).map(([key, vehicle]) => (<button key={key} type="button" onClick={() => setSelectedVehicle(key)} className={`w-full text-left px-3 py-2 text-sm rounded-lg transition-colors ${selectedVehicle === key ? 'bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-300' : 'text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800'}`}>{vehicle.year ? `${vehicle.year} ` : ''}{vehicle.make} {vehicle.model}</button>))}
                </div>
              </div>
              <div className="flex-1 overflow-y-auto p-4">
                {selectedVehicle && editingVehicles[selectedVehicle] ? (
                  <div className="space-y-4">
                    <div className="flex items-center justify-between">
                      <h3 className="text-lg font-medium text-slate-900 dark:text-white">{editingVehicles[selectedVehicle].year} {editingVehicles[selectedVehicle].make} {editingVehicles[selectedVehicle].model}</h3>
                      <button type="button" onClick={() => handleRemoveVehicle(selectedVehicle)} className="text-sm text-red-600 hover:text-red-700">Remove</button>
                    </div>
                    <div className="space-y-4">
                      <h4 className="text-sm font-medium text-slate-700 dark:text-slate-300 border-b border-slate-200 dark:border-slate-700 pb-2">Vehicle Info</h4>
                      <div className="grid grid-cols-3 gap-4">
                        <div><label className="label block mb-1.5">Year</label><input type="number" value={editingVehicles[selectedVehicle].year || ''} onChange={(e) => handleUpdateVehicle(selectedVehicle, 'year', e.target.value ? parseInt(e.target.value) : undefined)} className="input w-full" placeholder="2024" /></div>
                        <div><label className="label block mb-1.5">Make</label><input type="text" value={editingVehicles[selectedVehicle].make} onChange={(e) => handleUpdateVehicle(selectedVehicle, 'make', e.target.value)} className="input w-full" placeholder="Toyota" /></div>
                        <div><label className="label block mb-1.5">Model</label><input type="text" value={editingVehicles[selectedVehicle].model} onChange={(e) => handleUpdateVehicle(selectedVehicle, 'model', e.target.value)} className="input w-full" placeholder="Camry" /></div>
                        <div><label className="label block mb-1.5">Color</label><input type="text" value={editingVehicles[selectedVehicle].color || ''} onChange={(e) => handleUpdateVehicle(selectedVehicle, 'color', e.target.value)} className="input w-full" placeholder="Silver" /></div>
                        <div><label className="label block mb-1.5">VIN</label><input type="text" value={editingVehicles[selectedVehicle].vin || ''} onChange={(e) => handleUpdateVehicle(selectedVehicle, 'vin', e.target.value)} className="input w-full" placeholder="Vehicle ID" /></div>
                        <div><label className="label block mb-1.5">License Plate</label><input type="text" value={editingVehicles[selectedVehicle].licensePlate || ''} onChange={(e) => handleUpdateVehicle(selectedVehicle, 'licensePlate', e.target.value)} className="input w-full" placeholder="ABC-1234" /></div>
                        <div><label className="label block mb-1.5">Registration Expires</label><input type="date" value={editingVehicles[selectedVehicle].registrationExpires || ''} onChange={(e) => handleUpdateVehicle(selectedVehicle, 'registrationExpires', e.target.value)} className="input w-full" /></div>
                        <div><label className="label block mb-1.5">Current Mileage</label><input type="number" value={editingVehicles[selectedVehicle].currentMileage || ''} onChange={(e) => handleUpdateVehicle(selectedVehicle, 'currentMileage', e.target.value ? parseInt(e.target.value) : undefined)} className="input w-full" placeholder="50000" /></div>
                      </div>
                      <h4 className="text-sm font-medium text-slate-700 dark:text-slate-300 border-b border-slate-200 dark:border-slate-700 pb-2 pt-4">Insurance</h4>
                      <div className="grid grid-cols-2 gap-4">
                        <div><label className="label block mb-1.5">Insurance Company</label><input type="text" value={editingVehicles[selectedVehicle].insuranceCompany || ''} onChange={(e) => handleUpdateVehicle(selectedVehicle, 'insuranceCompany', e.target.value)} className="input w-full" placeholder="State Farm" /></div>
                        <div><label className="label block mb-1.5">Policy Number</label><input type="text" value={editingVehicles[selectedVehicle].insurancePolicyNumber || ''} onChange={(e) => handleUpdateVehicle(selectedVehicle, 'insurancePolicyNumber', e.target.value)} className="input w-full" placeholder="Policy #" /></div>
                        <div><label className="label block mb-1.5">Policy Expires</label><input type="date" value={editingVehicles[selectedVehicle].insuranceExpires || ''} onChange={(e) => handleUpdateVehicle(selectedVehicle, 'insuranceExpires', e.target.value)} className="input w-full" /></div>
                        <div><label className="label block mb-1.5">Agent Phone</label><input type="tel" value={editingVehicles[selectedVehicle].insuranceAgentPhone || ''} onChange={(e) => handleUpdateVehicle(selectedVehicle, 'insuranceAgentPhone', e.target.value)} className="input w-full" placeholder="(555) 555-5555" /></div>
                      </div>
                      <h4 className="text-sm font-medium text-slate-700 dark:text-slate-300 border-b border-slate-200 dark:border-slate-700 pb-2 pt-4">Service</h4>
                      <div className="grid grid-cols-2 gap-4">
                        <div><label className="label block mb-1.5">Preferred Mechanic</label><input type="text" value={editingVehicles[selectedVehicle].preferredMechanic || ''} onChange={(e) => handleUpdateVehicle(selectedVehicle, 'preferredMechanic', e.target.value)} className="input w-full" placeholder="Shop name" /></div>
                        <div><label className="label block mb-1.5">Mechanic Phone</label><input type="tel" value={editingVehicles[selectedVehicle].mechanicPhone || ''} onChange={(e) => handleUpdateVehicle(selectedVehicle, 'mechanicPhone', e.target.value)} className="input w-full" placeholder="(555) 555-5555" /></div>
                        <div><label className="label block mb-1.5">Last Oil Change</label><input type="date" value={editingVehicles[selectedVehicle].lastOilChange || ''} onChange={(e) => handleUpdateVehicle(selectedVehicle, 'lastOilChange', e.target.value)} className="input w-full" /></div>
                        <div><label className="label block mb-1.5">Next Oil Change (miles)</label><input type="number" value={editingVehicles[selectedVehicle].nextOilChangeMiles || ''} onChange={(e) => handleUpdateVehicle(selectedVehicle, 'nextOilChangeMiles', e.target.value ? parseInt(e.target.value) : undefined)} className="input w-full" placeholder="55000" /></div>
                      </div>
                      <div className="pt-4"><label className="label block mb-1.5">Notes</label><textarea value={editingVehicles[selectedVehicle].notes || ''} onChange={(e) => handleUpdateVehicle(selectedVehicle, 'notes', e.target.value)} className="input w-full" rows={2} placeholder="Any notes..." /></div>
                    </div>
                  </div>
                ) : (<div className="h-full flex items-center justify-center text-slate-400 dark:text-slate-500"><p>Select a vehicle or add a new one</p></div>)}
              </div>
            </div>
            <div className="flex items-center justify-end gap-3 p-4 border-t border-slate-200 dark:border-slate-700">
              <button type="button" onClick={onClose} disabled={isSaving} className="btn btn-secondary">Cancel</button>
              <button type="submit" disabled={isSaving} className="btn btn-primary">{isSaving ? 'Saving...' : 'Save Changes'}</button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}

// Fuel Delivery Modal
function FuelDeliveryModal({
  fuelDelivery,
  onSave,
  onClose,
  isSaving,
}: {
  fuelDelivery?: FuelDelivery;
  onSave: (fuelDelivery: FuelDelivery) => void;
  onClose: () => void;
  isSaving: boolean;
}) {
  const [editingFuel, setEditingFuel] = useState<FuelDelivery>(() => fuelDelivery || { id: crypto.randomUUID(), fuelType: 'OIL', provider: '' });
  const handleUpdate = (field: string, value: string | number | boolean) => { setEditingFuel(prev => ({ ...prev, [field]: value })); };
  const handleSubmit = (e: React.FormEvent) => { e.preventDefault(); onSave(editingFuel); };

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      <div className="flex min-h-full items-center justify-center p-4">
        <div className="fixed inset-0 bg-black/50" onClick={onClose} />
        <div className="relative bg-white dark:bg-slate-900 rounded-xl shadow-xl w-full max-w-lg">
          <div className="flex items-center justify-between p-4 border-b border-slate-200 dark:border-slate-700">
            <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Fuel Delivery Info</h2>
            <button onClick={onClose} className="text-slate-400 hover:text-slate-600 dark:hover:text-slate-300"><svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" /></svg></button>
          </div>
          <form onSubmit={handleSubmit} className="p-4 space-y-4">
            <div><label className="label block mb-1.5">Fuel Type</label><select value={editingFuel.fuelType} onChange={(e) => handleUpdate('fuelType', e.target.value)} className="input w-full"><option value="OIL">Heating Oil</option><option value="PROPANE">Propane</option><option value="NATURAL_GAS">Natural Gas</option></select></div>
            <div className="grid grid-cols-2 gap-4">
              <div><label className="label block mb-1.5">Provider</label><input type="text" value={editingFuel.provider} onChange={(e) => handleUpdate('provider', e.target.value)} className="input w-full" placeholder="e.g., Petro Home" /></div>
              <div><label className="label block mb-1.5">Account Number</label><input type="text" value={editingFuel.accountNumber || ''} onChange={(e) => handleUpdate('accountNumber', e.target.value)} className="input w-full" placeholder="Account #" /></div>
              <div><label className="label block mb-1.5">Tank Size (gallons)</label><input type="number" value={editingFuel.tankSize || ''} onChange={(e) => handleUpdate('tankSize', e.target.value ? parseInt(e.target.value) : 0)} className="input w-full" placeholder="275" /></div>
              <div><label className="label block mb-1.5">Last Fill Date</label><input type="date" value={editingFuel.lastFillDate || ''} onChange={(e) => handleUpdate('lastFillDate', e.target.value)} className="input w-full" /></div>
              <div><label className="label block mb-1.5">Last Fill Amount (gal)</label><input type="number" value={editingFuel.lastFillAmount || ''} onChange={(e) => handleUpdate('lastFillAmount', e.target.value ? parseFloat(e.target.value) : 0)} className="input w-full" placeholder="150" /></div>
              <div><label className="label block mb-1.5">Price per Gallon</label><div className="relative"><span className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400">$</span><input type="number" step="0.01" value={editingFuel.pricePerGallon || ''} onChange={(e) => handleUpdate('pricePerGallon', e.target.value ? parseFloat(e.target.value) : 0)} className="input w-full pl-7" placeholder="3.50" /></div></div>
              <div><label className="label block mb-1.5">Customer Service</label><input type="tel" value={editingFuel.customerServicePhone || ''} onChange={(e) => handleUpdate('customerServicePhone', e.target.value)} className="input w-full" placeholder="(555) 555-5555" /></div>
              <div><label className="label block mb-1.5">Emergency Phone</label><input type="tel" value={editingFuel.emergencyPhone || ''} onChange={(e) => handleUpdate('emergencyPhone', e.target.value)} className="input w-full" placeholder="(555) 555-5555" /></div>
            </div>
            <div><label className="flex items-center gap-3 cursor-pointer"><input type="checkbox" checked={editingFuel.autoDelivery || false} onChange={(e) => handleUpdate('autoDelivery', e.target.checked)} className="w-4 h-4 text-emerald-600 rounded" /><span className="text-sm text-slate-700 dark:text-slate-300">Auto-delivery is enabled</span></label></div>
            <div><label className="label block mb-1.5">Notes</label><textarea value={editingFuel.notes || ''} onChange={(e) => handleUpdate('notes', e.target.value)} className="input w-full" rows={2} placeholder="Any notes about delivery access, tank location, etc." /></div>
            <div className="flex items-center justify-end gap-3 pt-4 border-t border-slate-200 dark:border-slate-700">
              <button type="button" onClick={onClose} disabled={isSaving} className="btn btn-secondary">Cancel</button>
              <button type="submit" disabled={isSaving} className="btn btn-primary">{isSaving ? 'Saving...' : 'Save Changes'}</button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}
