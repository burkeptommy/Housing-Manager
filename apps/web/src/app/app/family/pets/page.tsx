'use client';

import { useState, useEffect } from 'react';
import { useApi } from '@/lib/api';
import type { Pet, PetCareAlert, PetPassport } from '@haven/core';
import {
  HeartIcon,
  PlusIcon,
  ExclamationTriangleIcon,
  DocumentDuplicateIcon,
  ClipboardDocumentIcon,
} from '@heroicons/react/24/outline';

const petTypeEmojis: Record<string, string> = {
  DOG: '🐕',
  CAT: '🐈',
  BIRD: '🐦',
  FISH: '🐟',
  REPTILE: '🦎',
  SMALL_MAMMAL: '🐹',
  HORSE: '🐴',
  OTHER: '🐾',
};

export default function PetsPage() {
  const api = useApi();
  const [pets, setPets] = useState<Pet[]>([]);
  const [alerts, setAlerts] = useState<PetCareAlert[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedPet, setSelectedPet] = useState<Pet | null>(null);
  const [petPassport, setPetPassport] = useState<PetPassport | null>(null);
  const [showPassport, setShowPassport] = useState(false);

  useEffect(() => {
    async function loadData() {
      try {
        const [petsData, alertsData] = await Promise.all([
          api.getFamilyPets(),
          api.getPetAlerts(),
        ]);
        setPets(petsData);
        setAlerts(alertsData);
      } catch (error) {
        console.error('Failed to load pets:', error);
      } finally {
        setLoading(false);
      }
    }
    loadData();
  }, [api]);

  const loadPetPassport = async (petId: string) => {
    try {
      const passport = await api.getPetPassport(petId);
      setPetPassport(passport);
      setShowPassport(true);
    } catch (error) {
      console.error('Failed to load pet passport:', error);
    }
  };

  const getPetAlerts = (petId: string) => {
    return alerts.filter((a) => a.petId === petId);
  };

  const calculateAge = (birthday: string) => {
    const birth = new Date(birthday);
    const now = new Date();
    const years = now.getFullYear() - birth.getFullYear();
    const months = now.getMonth() - birth.getMonth();
    if (years === 0) {
      return `${months < 0 ? 12 + months : months} months`;
    }
    return `${years} year${years !== 1 ? 's' : ''}`;
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 dark:bg-gray-900 p-6">
        <div className="animate-pulse space-y-4">
          <div className="h-8 bg-gray-200 dark:bg-gray-700 rounded w-48"></div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {[1, 2].map((i) => (
              <div key={i} className="h-64 bg-gray-200 dark:bg-gray-700 rounded-lg"></div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900 p-6">
      <div className="max-w-7xl mx-auto space-y-6">
        {/* Header */}
        <div className="flex justify-between items-center">
          <div>
            <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Pets</h1>
            <p className="text-gray-500 dark:text-gray-400">
              Manage your pet profiles and vet records
            </p>
          </div>
          <button className="inline-flex items-center px-4 py-2 bg-pink-600 text-white rounded-lg hover:bg-pink-700 transition-colors">
            <PlusIcon className="h-5 w-5 mr-2" />
            Add Pet
          </button>
        </div>

        {/* Alerts */}
        {alerts.length > 0 && (
          <div className="bg-pink-50 dark:bg-pink-900/20 border border-pink-200 dark:border-pink-800 rounded-lg p-4">
            <div className="flex items-center space-x-2 mb-2">
              <ExclamationTriangleIcon className="h-5 w-5 text-pink-600 dark:text-pink-400" />
              <h2 className="font-semibold text-pink-800 dark:text-pink-200">
                {alerts.length} Care Alert{alerts.length !== 1 ? 's' : ''}
              </h2>
            </div>
            <div className="space-y-2">
              {alerts.slice(0, 3).map((alert, idx) => (
                <div key={idx} className="flex items-center justify-between text-sm">
                  <span className="text-pink-700 dark:text-pink-300">
                    <span className="font-medium">{alert.petName}:</span> {alert.message}
                  </span>
                  <span
                    className={`px-2 py-0.5 rounded text-xs ${
                      alert.severity === 'high'
                        ? 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200'
                        : alert.severity === 'medium'
                          ? 'bg-amber-100 text-amber-800 dark:bg-amber-900 dark:text-amber-200'
                          : 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-200'
                    }`}
                  >
                    {alert.type}
                  </span>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Pets Grid */}
        {pets.length === 0 ? (
          <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-12 text-center">
            <HeartIcon className="h-16 w-16 mx-auto text-gray-300 dark:text-gray-600 mb-4" />
            <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-2">No pets yet</h2>
            <p className="text-gray-500 dark:text-gray-400 mb-4">
              Add your first pet to track their health records and care information.
            </p>
            <button className="inline-flex items-center px-4 py-2 bg-pink-600 text-white rounded-lg hover:bg-pink-700">
              <PlusIcon className="h-5 w-5 mr-2" />
              Add Pet
            </button>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {pets.map((pet) => {
              const petAlerts = getPetAlerts(pet.id);
              return (
                <div
                  key={pet.id}
                  className="bg-white dark:bg-gray-800 rounded-lg shadow overflow-hidden hover:shadow-lg transition-shadow"
                >
                  {/* Pet Image / Placeholder */}
                  <div className="h-40 bg-gradient-to-br from-pink-100 to-purple-100 dark:from-pink-900/30 dark:to-purple-900/30 flex items-center justify-center relative">
                    {pet.photoUrls && pet.photoUrls[0] ? (
                      <img
                        src={pet.photoUrls[0]}
                        alt={pet.name}
                        className="w-full h-full object-cover"
                      />
                    ) : (
                      <span className="text-6xl">{petTypeEmojis[pet.type] || '🐾'}</span>
                    )}
                    {petAlerts.length > 0 && (
                      <div className="absolute top-2 right-2 bg-red-500 text-white text-xs px-2 py-1 rounded-full">
                        {petAlerts.length} alert{petAlerts.length !== 1 ? 's' : ''}
                      </div>
                    )}
                  </div>

                  {/* Pet Info */}
                  <div className="p-4">
                    <div className="flex justify-between items-start">
                      <div>
                        <h3 className="font-semibold text-lg text-gray-900 dark:text-white">
                          {pet.name}
                        </h3>
                        <p className="text-sm text-gray-500 dark:text-gray-400">
                          {pet.breed || pet.type} {pet.gender && `• ${pet.gender}`}
                        </p>
                      </div>
                      {pet.birthday && (
                        <span className="text-sm text-gray-500 dark:text-gray-400">
                          {calculateAge(pet.birthday)}
                        </span>
                      )}
                    </div>

                    {/* Quick Info */}
                    <div className="mt-3 flex flex-wrap gap-2">
                      {pet.size && (
                        <span className="text-xs bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 px-2 py-1 rounded">
                          {pet.size}
                        </span>
                      )}
                      {pet.weight && (
                        <span className="text-xs bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 px-2 py-1 rounded">
                          {pet.weight} lbs
                        </span>
                      )}
                      {pet.isSpayedNeutered && (
                        <span className="text-xs bg-green-100 dark:bg-green-900 text-green-600 dark:text-green-300 px-2 py-1 rounded">
                          Fixed
                        </span>
                      )}
                    </div>

                    {/* Vet Info */}
                    {pet.vetClinicName && (
                      <div className="mt-3 text-sm text-gray-500 dark:text-gray-400">
                        <p>
                          <span className="font-medium">Vet:</span> {pet.vetClinicName}
                        </p>
                      </div>
                    )}

                    {/* Actions */}
                    <div className="mt-4 flex space-x-2">
                      <button
                        onClick={() => loadPetPassport(pet.id)}
                        className="flex-1 inline-flex items-center justify-center px-3 py-2 bg-pink-600 text-white rounded-lg text-sm hover:bg-pink-700"
                      >
                        <DocumentDuplicateIcon className="h-4 w-4 mr-1" />
                        Pet Passport
                      </button>
                      <button
                        onClick={() => setSelectedPet(pet)}
                        className="flex-1 inline-flex items-center justify-center px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700"
                      >
                        <ClipboardDocumentIcon className="h-4 w-4 mr-1" />
                        Records
                      </button>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}

        {/* Pet Passport Modal */}
        {showPassport && petPassport && (
          <div
            className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4"
            onClick={() => setShowPassport(false)}
          >
            <div
              className="bg-white dark:bg-gray-800 rounded-xl max-w-md w-full max-h-[90vh] overflow-y-auto"
              onClick={(e) => e.stopPropagation()}
            >
              {/* Passport Header */}
              <div className="bg-gradient-to-r from-pink-500 to-purple-500 p-6 text-white">
                <div className="text-center">
                  <span className="text-5xl mb-2 block">{petTypeEmojis[petPassport.type]}</span>
                  <h2 className="text-2xl font-bold">{petPassport.name}</h2>
                  <p className="text-pink-100">
                    {petPassport.breed} • {petPassport.gender}
                  </p>
                </div>
              </div>

              <div className="p-6 space-y-4">
                {/* Basic Info */}
                <div className="grid grid-cols-2 gap-4 text-sm">
                  {petPassport.birthday && (
                    <div>
                      <p className="text-gray-500 dark:text-gray-400">Birthday</p>
                      <p className="font-medium text-gray-900 dark:text-white">
                        {new Date(petPassport.birthday).toLocaleDateString()}
                      </p>
                    </div>
                  )}
                  {petPassport.weight && (
                    <div>
                      <p className="text-gray-500 dark:text-gray-400">Weight</p>
                      <p className="font-medium text-gray-900 dark:text-white">
                        {petPassport.weight} lbs
                      </p>
                    </div>
                  )}
                  {petPassport.microchipId && (
                    <div className="col-span-2">
                      <p className="text-gray-500 dark:text-gray-400">Microchip ID</p>
                      <p className="font-mono text-sm text-gray-900 dark:text-white">
                        {petPassport.microchipId}
                      </p>
                    </div>
                  )}
                </div>

                {/* Vet Info */}
                {petPassport.vetClinic.name && (
                  <div className="border-t border-gray-200 dark:border-gray-700 pt-4">
                    <h3 className="font-semibold text-gray-900 dark:text-white mb-2">
                      Veterinarian
                    </h3>
                    <p className="text-gray-900 dark:text-white">{petPassport.vetClinic.name}</p>
                    {petPassport.vetClinic.phone && (
                      <p className="text-sm text-gray-500 dark:text-gray-400">
                        {petPassport.vetClinic.phone}
                      </p>
                    )}
                    {petPassport.vetClinic.primaryVet && (
                      <p className="text-sm text-gray-500 dark:text-gray-400">
                        Dr. {petPassport.vetClinic.primaryVet}
                      </p>
                    )}
                  </div>
                )}

                {/* Vaccinations */}
                {Object.keys(petPassport.vaccinations).length > 0 && (
                  <div className="border-t border-gray-200 dark:border-gray-700 pt-4">
                    <h3 className="font-semibold text-gray-900 dark:text-white mb-2">
                      Vaccinations
                    </h3>
                    <div className="space-y-2">
                      {Object.entries(petPassport.vaccinations).map(([name, info]) => (
                        <div
                          key={name}
                          className="flex justify-between text-sm bg-green-50 dark:bg-green-900/20 rounded p-2"
                        >
                          <span className="text-gray-900 dark:text-white capitalize">{name}</span>
                          <span className="text-green-600 dark:text-green-400">
                            {new Date(info.date).toLocaleDateString()}
                          </span>
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                {/* Allergies & Medications */}
                {(petPassport.allergies.length > 0 || petPassport.medications.length > 0) && (
                  <div className="border-t border-gray-200 dark:border-gray-700 pt-4">
                    {petPassport.allergies.length > 0 && (
                      <div className="mb-3">
                        <h3 className="font-semibold text-red-600 dark:text-red-400 mb-1">
                          Allergies
                        </h3>
                        <p className="text-gray-900 dark:text-white">
                          {petPassport.allergies.join(', ')}
                        </p>
                      </div>
                    )}
                    {petPassport.medications.length > 0 && (
                      <div>
                        <h3 className="font-semibold text-emerald-600 dark:text-emerald-400 mb-1">
                          Medications
                        </h3>
                        <p className="text-gray-900 dark:text-white">
                          {petPassport.medications.join(', ')}
                        </p>
                      </div>
                    )}
                  </div>
                )}

                {/* Diet */}
                {(petPassport.diet.foodBrand || petPassport.diet.feedingSchedule) && (
                  <div className="border-t border-gray-200 dark:border-gray-700 pt-4">
                    <h3 className="font-semibold text-gray-900 dark:text-white mb-2">Diet</h3>
                    {petPassport.diet.foodBrand && (
                      <p className="text-gray-900 dark:text-white">
                        <span className="text-gray-500">Food:</span> {petPassport.diet.foodBrand}{' '}
                        {petPassport.diet.foodType}
                      </p>
                    )}
                    {petPassport.diet.feedingSchedule && (
                      <p className="text-gray-900 dark:text-white">
                        <span className="text-gray-500">Schedule:</span>{' '}
                        {petPassport.diet.feedingSchedule}
                      </p>
                    )}
                  </div>
                )}

                {/* Care Instructions */}
                {petPassport.careInstructions && (
                  <div className="border-t border-gray-200 dark:border-gray-700 pt-4">
                    <h3 className="font-semibold text-gray-900 dark:text-white mb-2">
                      Care Instructions
                    </h3>
                    <p className="text-gray-600 dark:text-gray-300 text-sm">
                      {petPassport.careInstructions}
                    </p>
                  </div>
                )}

                {/* Emergency Contact */}
                {petPassport.emergencyContact && (
                  <div className="border-t border-gray-200 dark:border-gray-700 pt-4">
                    <h3 className="font-semibold text-gray-900 dark:text-white mb-2">
                      Emergency Contact
                    </h3>
                    <p className="text-gray-900 dark:text-white">{petPassport.emergencyContact}</p>
                  </div>
                )}

                {/* Share Button */}
                <button className="w-full mt-4 px-4 py-2 bg-pink-600 text-white rounded-lg hover:bg-pink-700">
                  Share Pet Passport
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
