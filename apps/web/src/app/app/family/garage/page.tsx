'use client';

import { useState, useEffect } from 'react';
import { useApi } from '@/lib/api';
import type { Vehicle, VehicleMaintenanceAlert } from '@haven/core';
import {
  TruckIcon,
  PlusIcon,
  WrenchScrewdriverIcon,
  ExclamationTriangleIcon,
  CalendarIcon,
  DocumentTextIcon,
} from '@heroicons/react/24/outline';

export default function GaragePage() {
  const api = useApi();
  const [vehicles, setVehicles] = useState<Vehicle[]>([]);
  const [alerts, setAlerts] = useState<VehicleMaintenanceAlert[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedVehicle, setSelectedVehicle] = useState<Vehicle | null>(null);

  useEffect(() => {
    async function loadData() {
      try {
        const [vehiclesData, alertsData] = await Promise.all([
          api.getFamilyVehicles(),
          api.getVehicleAlerts(),
        ]);
        setVehicles(vehiclesData);
        setAlerts(alertsData);
      } catch (error) {
        console.error('Failed to load vehicles:', error);
      } finally {
        setLoading(false);
      }
    }
    loadData();
  }, [api]);

  const getVehicleAlerts = (vehicleId: string) => {
    return alerts.filter((a) => a.vehicleId === vehicleId);
  };

  const getVehicleName = (v: Vehicle) => {
    return v.nickname || `${v.year} ${v.make} ${v.model}`;
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
            <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Garage</h1>
            <p className="text-gray-500 dark:text-gray-400">
              Manage your vehicles and track maintenance
            </p>
          </div>
          <button className="inline-flex items-center px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition-colors">
            <PlusIcon className="h-5 w-5 mr-2" />
            Add Vehicle
          </button>
        </div>

        {/* Alerts Summary */}
        {alerts.length > 0 && (
          <div className="bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded-lg p-4">
            <div className="flex items-center space-x-2 mb-2">
              <ExclamationTriangleIcon className="h-5 w-5 text-amber-600 dark:text-amber-400" />
              <h2 className="font-semibold text-amber-800 dark:text-amber-200">
                {alerts.length} Maintenance Alert{alerts.length !== 1 ? 's' : ''}
              </h2>
            </div>
            <div className="space-y-2">
              {alerts.slice(0, 3).map((alert, idx) => (
                <div
                  key={idx}
                  className="flex items-center justify-between text-sm"
                >
                  <span className="text-amber-700 dark:text-amber-300">
                    <span className="font-medium">{alert.vehicleName}:</span> {alert.message}
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
                    {alert.type.replace('_', ' ')}
                  </span>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Vehicles Grid */}
        {vehicles.length === 0 ? (
          <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-12 text-center">
            <TruckIcon className="h-16 w-16 mx-auto text-gray-300 dark:text-gray-600 mb-4" />
            <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-2">
              No vehicles yet
            </h2>
            <p className="text-gray-500 dark:text-gray-400 mb-4">
              Add your first vehicle to start tracking maintenance and service records.
            </p>
            <button className="inline-flex items-center px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700">
              <PlusIcon className="h-5 w-5 mr-2" />
              Add Vehicle
            </button>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {vehicles.map((vehicle) => {
              const vehicleAlerts = getVehicleAlerts(vehicle.id);
              return (
                <div
                  key={vehicle.id}
                  className="bg-white dark:bg-gray-800 rounded-lg shadow overflow-hidden hover:shadow-lg transition-shadow cursor-pointer"
                  onClick={() => setSelectedVehicle(vehicle)}
                >
                  {/* Vehicle Image / Placeholder */}
                  <div className="h-40 bg-gradient-to-br from-gray-100 to-gray-200 dark:from-gray-700 dark:to-gray-600 flex items-center justify-center relative">
                    {vehicle.photoUrls && vehicle.photoUrls[0] ? (
                      <img
                        src={vehicle.photoUrls[0]}
                        alt={getVehicleName(vehicle)}
                        className="w-full h-full object-cover"
                      />
                    ) : (
                      <TruckIcon className="h-20 w-20 text-gray-400 dark:text-gray-500" />
                    )}
                    {vehicleAlerts.length > 0 && (
                      <div className="absolute top-2 right-2 bg-red-500 text-white text-xs px-2 py-1 rounded-full">
                        {vehicleAlerts.length} alert{vehicleAlerts.length !== 1 ? 's' : ''}
                      </div>
                    )}
                  </div>

                  {/* Vehicle Info */}
                  <div className="p-4">
                    <h3 className="font-semibold text-lg text-gray-900 dark:text-white">
                      {getVehicleName(vehicle)}
                    </h3>
                    <p className="text-sm text-gray-500 dark:text-gray-400">
                      {vehicle.color} {vehicle.type}
                    </p>

                    {/* Quick Stats */}
                    <div className="mt-4 grid grid-cols-2 gap-4 text-sm">
                      {vehicle.currentMileage && (
                        <div>
                          <p className="text-gray-500 dark:text-gray-400">Mileage</p>
                          <p className="font-medium text-gray-900 dark:text-white">
                            {vehicle.currentMileage.toLocaleString()} mi
                          </p>
                        </div>
                      )}
                      {vehicle.registrationExpires && (
                        <div>
                          <p className="text-gray-500 dark:text-gray-400">Registration</p>
                          <p className="font-medium text-gray-900 dark:text-white">
                            {new Date(vehicle.registrationExpires).toLocaleDateString(undefined, {
                              month: 'short',
                              year: 'numeric',
                            })}
                          </p>
                        </div>
                      )}
                    </div>

                    {/* Actions */}
                    <div className="mt-4 flex space-x-2">
                      <button className="flex-1 inline-flex items-center justify-center px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700">
                        <WrenchScrewdriverIcon className="h-4 w-4 mr-1" />
                        Service
                      </button>
                      <button className="flex-1 inline-flex items-center justify-center px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700">
                        <DocumentTextIcon className="h-4 w-4 mr-1" />
                        History
                      </button>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}

        {/* Vehicle Detail Modal */}
        {selectedVehicle && (
          <div
            className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4"
            onClick={() => setSelectedVehicle(null)}
          >
            <div
              className="bg-white dark:bg-gray-800 rounded-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto"
              onClick={(e) => e.stopPropagation()}
            >
              <div className="p-6">
                <div className="flex justify-between items-start mb-4">
                  <div>
                    <h2 className="text-xl font-bold text-gray-900 dark:text-white">
                      {getVehicleName(selectedVehicle)}
                    </h2>
                    <p className="text-gray-500 dark:text-gray-400">
                      {selectedVehicle.year} {selectedVehicle.make} {selectedVehicle.model}{' '}
                      {selectedVehicle.trim}
                    </p>
                  </div>
                  <button
                    onClick={() => setSelectedVehicle(null)}
                    className="text-gray-400 hover:text-gray-600 dark:hover:text-gray-200"
                  >
                    &times;
                  </button>
                </div>

                <div className="grid grid-cols-2 gap-4 mb-6">
                  {selectedVehicle.vin && (
                    <div>
                      <p className="text-sm text-gray-500 dark:text-gray-400">VIN</p>
                      <p className="font-mono text-sm text-gray-900 dark:text-white">
                        {selectedVehicle.vin}
                      </p>
                    </div>
                  )}
                  {selectedVehicle.licensePlate && (
                    <div>
                      <p className="text-sm text-gray-500 dark:text-gray-400">License Plate</p>
                      <p className="font-medium text-gray-900 dark:text-white">
                        {selectedVehicle.licensePlate} ({selectedVehicle.licenseState})
                      </p>
                    </div>
                  )}
                  {selectedVehicle.currentMileage && (
                    <div>
                      <p className="text-sm text-gray-500 dark:text-gray-400">Current Mileage</p>
                      <p className="font-medium text-gray-900 dark:text-white">
                        {selectedVehicle.currentMileage.toLocaleString()} miles
                      </p>
                    </div>
                  )}
                  {selectedVehicle.fuelType && (
                    <div>
                      <p className="text-sm text-gray-500 dark:text-gray-400">Fuel Type</p>
                      <p className="font-medium text-gray-900 dark:text-white capitalize">
                        {selectedVehicle.fuelType.toLowerCase().replace('_', ' ')}
                      </p>
                    </div>
                  )}
                </div>

                {/* Insurance & Registration */}
                <div className="border-t border-gray-200 dark:border-gray-700 pt-4 mb-4">
                  <h3 className="font-semibold text-gray-900 dark:text-white mb-3">
                    Insurance & Registration
                  </h3>
                  <div className="grid grid-cols-2 gap-4">
                    {selectedVehicle.insuranceProvider && (
                      <div>
                        <p className="text-sm text-gray-500 dark:text-gray-400">Insurance</p>
                        <p className="font-medium text-gray-900 dark:text-white">
                          {selectedVehicle.insuranceProvider}
                        </p>
                        {selectedVehicle.insuranceExpires && (
                          <p className="text-xs text-gray-500">
                            Expires: {new Date(selectedVehicle.insuranceExpires).toLocaleDateString()}
                          </p>
                        )}
                      </div>
                    )}
                    {selectedVehicle.registrationExpires && (
                      <div>
                        <p className="text-sm text-gray-500 dark:text-gray-400">Registration</p>
                        <p className="font-medium text-gray-900 dark:text-white">
                          Expires: {new Date(selectedVehicle.registrationExpires).toLocaleDateString()}
                        </p>
                      </div>
                    )}
                  </div>
                </div>

                {/* Maintenance Info */}
                <div className="border-t border-gray-200 dark:border-gray-700 pt-4">
                  <h3 className="font-semibold text-gray-900 dark:text-white mb-3">Maintenance</h3>
                  <div className="grid grid-cols-2 gap-4">
                    {selectedVehicle.lastOilChangeDate && (
                      <div>
                        <p className="text-sm text-gray-500 dark:text-gray-400">Last Oil Change</p>
                        <p className="font-medium text-gray-900 dark:text-white">
                          {new Date(selectedVehicle.lastOilChangeDate).toLocaleDateString()}
                        </p>
                        {selectedVehicle.lastOilChangeMileage && (
                          <p className="text-xs text-gray-500">
                            at {selectedVehicle.lastOilChangeMileage.toLocaleString()} mi
                          </p>
                        )}
                      </div>
                    )}
                    {selectedVehicle.preferredVendor && (
                      <div>
                        <p className="text-sm text-gray-500 dark:text-gray-400">Preferred Shop</p>
                        <p className="font-medium text-gray-900 dark:text-white">
                          {selectedVehicle.preferredVendor.displayName}
                        </p>
                        {selectedVehicle.preferredVendor.phone && (
                          <p className="text-xs text-gray-500">{selectedVehicle.preferredVendor.phone}</p>
                        )}
                      </div>
                    )}
                  </div>
                </div>

                {/* Actions */}
                <div className="mt-6 flex space-x-3">
                  <button className="flex-1 px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700">
                    Add Service Record
                  </button>
                  <button className="flex-1 px-4 py-2 border border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700">
                    Request Maintenance
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
