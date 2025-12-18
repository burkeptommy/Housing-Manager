'use client';

import { useState, useEffect } from 'react';
import { useApi } from '@/lib/api';
import Link from 'next/link';
import type { TravelProfileWithMember, SeatingPreference, LoyaltyProgram } from '@haven/core';
import {
  ArrowLeftIcon,
  IdentificationIcon,
  TicketIcon,
  PlusIcon,
  TrashIcon,
  ChevronDownIcon,
} from '@heroicons/react/24/outline';

const SEATING_OPTIONS: { value: SeatingPreference; label: string }[] = [
  { value: 'WINDOW', label: 'Window' },
  { value: 'AISLE', label: 'Aisle' },
  { value: 'MIDDLE', label: 'Middle' },
  { value: 'NO_PREFERENCE', label: 'No Preference' },
];

export default function TravelProfilePage() {
  const api = useApi();
  const [profile, setProfile] = useState<TravelProfileWithMember | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [expandedSection, setExpandedSection] = useState<string | null>('passport');

  // Form state
  const [passportNumber, setPassportNumber] = useState('');
  const [passportCountry, setPassportCountry] = useState('');
  const [passportExpiry, setPassportExpiry] = useState('');
  const [tsaPreCheck, setTsaPreCheck] = useState('');
  const [globalEntry, setGlobalEntry] = useState('');
  const [seatingPreference, setSeatingPreference] = useState<SeatingPreference>('NO_PREFERENCE');
  const [mealPreference, setMealPreference] = useState('');
  const [emergencyContactName, setEmergencyContactName] = useState('');
  const [emergencyContactPhone, setEmergencyContactPhone] = useState('');
  const [airlineLoyalty, setAirlineLoyalty] = useState<LoyaltyProgram[]>([]);
  const [hotelLoyalty, setHotelLoyalty] = useState<LoyaltyProgram[]>([]);

  useEffect(() => {
    async function loadProfile() {
      try {
        const data = await api.getMyTravelProfile();
        setProfile(data);

        // Initialize form with existing data
        if (data.travelProfile) {
          const tp = data.travelProfile;
          setPassportNumber(tp.passportNumber || '');
          setPassportCountry(tp.passportCountry || '');
          setPassportExpiry(tp.passportExpiry ? tp.passportExpiry.split('T')[0] : '');
          setTsaPreCheck(tp.tsaPreCheck || '');
          setGlobalEntry(tp.globalEntry || '');
          setSeatingPreference(tp.seatingPreference || 'NO_PREFERENCE');
          setMealPreference(tp.mealPreference || '');
          setEmergencyContactName(tp.emergencyContactName || '');
          setEmergencyContactPhone(tp.emergencyContactPhone || '');
          setAirlineLoyalty(tp.airlineLoyalty || []);
          setHotelLoyalty(tp.hotelLoyalty || []);
        }
      } catch (error) {
        console.error('Failed to load profile:', error);
      } finally {
        setLoading(false);
      }
    }
    loadProfile();
  }, [api]);

  const handleSave = async () => {
    setSaving(true);
    try {
      await api.updateMyTravelProfile({
        passportNumber: passportNumber || undefined,
        passportCountry: passportCountry || undefined,
        passportExpiry: passportExpiry || undefined,
        tsaPreCheck: tsaPreCheck || undefined,
        globalEntry: globalEntry || undefined,
        seatingPreference,
        mealPreference: mealPreference || undefined,
        emergencyContactName: emergencyContactName || undefined,
        emergencyContactPhone: emergencyContactPhone || undefined,
        airlineLoyalty: airlineLoyalty.length > 0 ? airlineLoyalty : undefined,
        hotelLoyalty: hotelLoyalty.length > 0 ? hotelLoyalty : undefined,
      });
      // Show success somehow
    } catch (error) {
      console.error('Failed to save profile:', error);
    } finally {
      setSaving(false);
    }
  };

  const addLoyaltyProgram = (type: 'airline' | 'hotel') => {
    const newProgram: LoyaltyProgram = { provider: '', number: '', tier: '' };
    if (type === 'airline') {
      setAirlineLoyalty([...airlineLoyalty, newProgram]);
    } else {
      setHotelLoyalty([...hotelLoyalty, newProgram]);
    }
  };

  const updateLoyaltyProgram = (
    type: 'airline' | 'hotel',
    index: number,
    field: keyof LoyaltyProgram,
    value: string
  ) => {
    if (type === 'airline') {
      const updated = [...airlineLoyalty];
      updated[index] = { ...updated[index], [field]: value };
      setAirlineLoyalty(updated);
    } else {
      const updated = [...hotelLoyalty];
      updated[index] = { ...updated[index], [field]: value };
      setHotelLoyalty(updated);
    }
  };

  const removeLoyaltyProgram = (type: 'airline' | 'hotel', index: number) => {
    if (type === 'airline') {
      setAirlineLoyalty(airlineLoyalty.filter((_, i) => i !== index));
    } else {
      setHotelLoyalty(hotelLoyalty.filter((_, i) => i !== index));
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 dark:bg-gray-900 p-6">
        <div className="animate-pulse space-y-4 max-w-2xl mx-auto">
          <div className="h-8 bg-gray-200 dark:bg-gray-700 rounded w-48"></div>
          <div className="h-64 bg-gray-200 dark:bg-gray-700 rounded-lg"></div>
        </div>
      </div>
    );
  }

  const Section = ({
    id,
    title,
    icon: Icon,
    children,
  }: {
    id: string;
    title: string;
    icon: any;
    children: React.ReactNode;
  }) => (
    <div className="bg-white dark:bg-gray-800 rounded-lg shadow">
      <button
        onClick={() => setExpandedSection(expandedSection === id ? null : id)}
        className="w-full p-4 flex items-center justify-between text-left"
      >
        <div className="flex items-center space-x-3">
          <Icon className="h-5 w-5 text-gray-500 dark:text-gray-400" />
          <span className="font-medium text-gray-900 dark:text-white">{title}</span>
        </div>
        <ChevronDownIcon
          className={`h-5 w-5 text-gray-400 transition-transform ${
            expandedSection === id ? 'rotate-180' : ''
          }`}
        />
      </button>
      {expandedSection === id && (
        <div className="p-4 pt-0 border-t border-gray-200 dark:border-gray-700">{children}</div>
      )}
    </div>
  );

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900 p-6">
      <div className="max-w-2xl mx-auto space-y-6">
        {/* Header */}
        <div className="flex items-center space-x-4">
          <Link href="/app/travel" className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg">
            <ArrowLeftIcon className="h-5 w-5 text-gray-600 dark:text-gray-400" />
          </Link>
          <div>
            <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Travel Profile</h1>
            <p className="text-gray-500 dark:text-gray-400">
              {profile?.displayName || 'Your traveler information'}
            </p>
          </div>
        </div>

        {/* Passport Section */}
        <Section id="passport" title="Passport & ID" icon={IdentificationIcon}>
          <div className="space-y-4 mt-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Passport Number
              </label>
              <input
                type="text"
                value={passportNumber}
                onChange={(e) => setPassportNumber(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                placeholder="Enter passport number"
              />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Country of Issue
                </label>
                <input
                  type="text"
                  value={passportCountry}
                  onChange={(e) => setPassportCountry(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                  placeholder="e.g., US"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Expiry Date
                </label>
                <input
                  type="date"
                  value={passportExpiry}
                  onChange={(e) => setPassportExpiry(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  TSA PreCheck
                </label>
                <input
                  type="text"
                  value={tsaPreCheck}
                  onChange={(e) => setTsaPreCheck(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                  placeholder="Known Traveler Number"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Global Entry
                </label>
                <input
                  type="text"
                  value={globalEntry}
                  onChange={(e) => setGlobalEntry(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                  placeholder="PASS ID"
                />
              </div>
            </div>
          </div>
        </Section>

        {/* Preferences Section */}
        <Section id="preferences" title="Travel Preferences" icon={TicketIcon}>
          <div className="space-y-4 mt-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Seating Preference
              </label>
              <select
                value={seatingPreference}
                onChange={(e) => setSeatingPreference(e.target.value as SeatingPreference)}
                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
              >
                {SEATING_OPTIONS.map((opt) => (
                  <option key={opt.value} value={opt.value}>
                    {opt.label}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Meal Preference
              </label>
              <input
                type="text"
                value={mealPreference}
                onChange={(e) => setMealPreference(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                placeholder="e.g., Vegetarian, Kosher, No pork"
              />
            </div>
          </div>
        </Section>

        {/* Loyalty Programs Section */}
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-4">
          <h3 className="font-medium text-gray-900 dark:text-white mb-4">Airline Loyalty Programs</h3>
          <div className="space-y-3">
            {airlineLoyalty.map((program, idx) => (
              <div key={idx} className="flex items-center space-x-2">
                <input
                  type="text"
                  value={program.provider}
                  onChange={(e) => updateLoyaltyProgram('airline', idx, 'provider', e.target.value)}
                  className="flex-1 px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                  placeholder="Airline"
                />
                <input
                  type="text"
                  value={program.number}
                  onChange={(e) => updateLoyaltyProgram('airline', idx, 'number', e.target.value)}
                  className="flex-1 px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                  placeholder="Member #"
                />
                <input
                  type="text"
                  value={program.tier || ''}
                  onChange={(e) => updateLoyaltyProgram('airline', idx, 'tier', e.target.value)}
                  className="w-24 px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                  placeholder="Tier"
                />
                <button
                  onClick={() => removeLoyaltyProgram('airline', idx)}
                  className="p-2 text-red-500 hover:bg-red-50 dark:hover:bg-red-900/20 rounded"
                >
                  <TrashIcon className="h-5 w-5" />
                </button>
              </div>
            ))}
            <button
              onClick={() => addLoyaltyProgram('airline')}
              className="flex items-center text-emerald-600 dark:text-emerald-400 hover:underline text-sm"
            >
              <PlusIcon className="h-4 w-4 mr-1" />
              Add Airline Program
            </button>
          </div>

          <h3 className="font-medium text-gray-900 dark:text-white mb-4 mt-6">Hotel Loyalty Programs</h3>
          <div className="space-y-3">
            {hotelLoyalty.map((program, idx) => (
              <div key={idx} className="flex items-center space-x-2">
                <input
                  type="text"
                  value={program.provider}
                  onChange={(e) => updateLoyaltyProgram('hotel', idx, 'provider', e.target.value)}
                  className="flex-1 px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                  placeholder="Hotel Chain"
                />
                <input
                  type="text"
                  value={program.number}
                  onChange={(e) => updateLoyaltyProgram('hotel', idx, 'number', e.target.value)}
                  className="flex-1 px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                  placeholder="Member #"
                />
                <input
                  type="text"
                  value={program.tier || ''}
                  onChange={(e) => updateLoyaltyProgram('hotel', idx, 'tier', e.target.value)}
                  className="w-24 px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                  placeholder="Tier"
                />
                <button
                  onClick={() => removeLoyaltyProgram('hotel', idx)}
                  className="p-2 text-red-500 hover:bg-red-50 dark:hover:bg-red-900/20 rounded"
                >
                  <TrashIcon className="h-5 w-5" />
                </button>
              </div>
            ))}
            <button
              onClick={() => addLoyaltyProgram('hotel')}
              className="flex items-center text-emerald-600 dark:text-emerald-400 hover:underline text-sm"
            >
              <PlusIcon className="h-4 w-4 mr-1" />
              Add Hotel Program
            </button>
          </div>
        </div>

        {/* Emergency Contact */}
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-4">
          <h3 className="font-medium text-gray-900 dark:text-white mb-4">Emergency Contact</h3>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Contact Name
              </label>
              <input
                type="text"
                value={emergencyContactName}
                onChange={(e) => setEmergencyContactName(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                placeholder="Full name"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Contact Phone
              </label>
              <input
                type="tel"
                value={emergencyContactPhone}
                onChange={(e) => setEmergencyContactPhone(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                placeholder="+1 (555) 123-4567"
              />
            </div>
          </div>
        </div>

        {/* Save Button */}
        <button
          onClick={handleSave}
          disabled={saving}
          className="w-full bg-emerald-600 text-white py-3 px-4 rounded-lg hover:bg-emerald-700 disabled:opacity-50 font-medium"
        >
          {saving ? 'Saving...' : 'Save Profile'}
        </button>
      </div>
    </div>
  );
}
