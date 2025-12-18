'use client';

import { useState, useEffect } from 'react';
import { useApi } from '@/lib/api';
import type { HomeDashboard, HomeSystemMaintenanceAlert, FormattedHomeSystem } from '@haven/core';
import {
  HomeIcon,
  PlusIcon,
  ExclamationTriangleIcon,
  FireIcon,
  BoltIcon,
  WrenchScrewdriverIcon,
  BeakerIcon,
  SparklesIcon,
  SunIcon,
  ShieldCheckIcon,
  CogIcon,
  CalendarIcon,
  CurrencyDollarIcon,
} from '@heroicons/react/24/outline';

const systemTypeIcons: Record<string, React.ComponentType<{ className?: string }>> = {
  FURNACE: FireIcon,
  AIR_CONDITIONER: SunIcon,
  HEAT_PUMP: FireIcon,
  BOILER: FireIcon,
  WATER_HEATER: BeakerIcon,
  ELECTRICAL_PANEL: BoltIcon,
  GENERATOR: BoltIcon,
  SOLAR_PANELS: SunIcon,
  WASHER: SparklesIcon,
  DRYER: SparklesIcon,
  REFRIGERATOR: CogIcon,
  DISHWASHER: CogIcon,
  SMOKE_DETECTOR: ShieldCheckIcon,
  CO_DETECTOR: ShieldCheckIcon,
  SECURITY_SYSTEM: ShieldCheckIcon,
};

const systemTypeLabels: Record<string, string> = {
  FURNACE: 'Furnace',
  AIR_CONDITIONER: 'Air Conditioner',
  HEAT_PUMP: 'Heat Pump',
  BOILER: 'Boiler',
  THERMOSTAT: 'Thermostat',
  WATER_HEATER: 'Water Heater',
  WATER_SOFTENER: 'Water Softener',
  WELL_PUMP: 'Well Pump',
  SUMP_PUMP: 'Sump Pump',
  ELECTRICAL_PANEL: 'Electrical Panel',
  GENERATOR: 'Generator',
  SOLAR_PANELS: 'Solar Panels',
  BATTERY_STORAGE: 'Battery Storage',
  REFRIGERATOR: 'Refrigerator',
  DISHWASHER: 'Dishwasher',
  OVEN_RANGE: 'Oven/Range',
  MICROWAVE: 'Microwave',
  GARBAGE_DISPOSAL: 'Garbage Disposal',
  WASHER: 'Washer',
  DRYER: 'Dryer',
  IRRIGATION_SYSTEM: 'Irrigation System',
  POOL_EQUIPMENT: 'Pool Equipment',
  HOT_TUB: 'Hot Tub',
  LAWN_MOWER: 'Lawn Mower',
  SMOKE_DETECTOR: 'Smoke Detector',
  CO_DETECTOR: 'CO Detector',
  SECURITY_SYSTEM: 'Security System',
  FIRE_EXTINGUISHER: 'Fire Extinguisher',
  GARAGE_DOOR_OPENER: 'Garage Door Opener',
  CEILING_FAN: 'Ceiling Fan',
  FIREPLACE: 'Fireplace',
  OTHER: 'Other',
};

const categoryLabels: Record<string, string> = {
  hvac: 'HVAC & Climate',
  water: 'Water Systems',
  electrical: 'Electrical & Power',
  kitchen: 'Kitchen Appliances',
  laundry: 'Laundry',
  outdoor: 'Outdoor & Landscape',
  safety: 'Safety & Security',
  other: 'Other Systems',
};

const categoryIcons: Record<string, React.ComponentType<{ className?: string }>> = {
  hvac: FireIcon,
  water: BeakerIcon,
  electrical: BoltIcon,
  kitchen: CogIcon,
  laundry: SparklesIcon,
  outdoor: SunIcon,
  safety: ShieldCheckIcon,
  other: CogIcon,
};

function SystemCard({ system }: { system: FormattedHomeSystem }) {
  const Icon = systemTypeIcons[system.type] || CogIcon;

  return (
    <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4 hover:shadow-md transition-shadow">
      <div className="flex items-start justify-between mb-3">
        <div className="flex items-center space-x-3">
          <div className="p-2 bg-emerald-100 dark:bg-emerald-900 rounded-lg">
            <Icon className="h-5 w-5 text-emerald-600 dark:text-emerald-400" />
          </div>
          <div>
            <h3 className="font-semibold text-gray-900 dark:text-white">
              {system.name || systemTypeLabels[system.type]}
            </h3>
            {(system.brand || system.model) && (
              <p className="text-sm text-gray-500 dark:text-gray-400">
                {system.brand} {system.model}
              </p>
            )}
          </div>
        </div>
        {system.condition && (
          <span
            className={`text-xs px-2 py-1 rounded ${
              system.condition === 'EXCELLENT' || system.condition === 'GOOD'
                ? 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200'
                : system.condition === 'FAIR'
                  ? 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200'
                  : 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200'
            }`}
          >
            {system.condition}
          </span>
        )}
      </div>

      <div className="space-y-2 text-sm">
        {/* Serial Number */}
        {system.serialNumber && (
          <div className="flex justify-between">
            <span className="text-gray-500 dark:text-gray-400">Serial #</span>
            <span className="font-mono text-gray-900 dark:text-white">{system.serialNumber}</span>
          </div>
        )}

        {/* Install Date */}
        {system.installDate && (
          <div className="flex justify-between">
            <span className="text-gray-500 dark:text-gray-400">Installed</span>
            <span className="text-gray-900 dark:text-white">
              {new Date(system.installDate).toLocaleDateString()}
            </span>
          </div>
        )}

        {/* Last Service */}
        {system.lastServiceDate && (
          <div className="flex justify-between">
            <span className="text-gray-500 dark:text-gray-400">Last Service</span>
            <span className="text-gray-900 dark:text-white">
              {new Date(system.lastServiceDate).toLocaleDateString()}
            </span>
          </div>
        )}

        {/* Next Service Due */}
        {system.nextServiceDue && (
          <div className="flex justify-between">
            <span className="text-gray-500 dark:text-gray-400">Next Service</span>
            <span
              className={`${
                new Date(system.nextServiceDue) < new Date()
                  ? 'text-red-600 dark:text-red-400 font-medium'
                  : 'text-gray-900 dark:text-white'
              }`}
            >
              {new Date(system.nextServiceDue).toLocaleDateString()}
            </span>
          </div>
        )}

        {/* Warranty */}
        {system.warrantyExpires && (
          <div className="flex justify-between">
            <span className="text-gray-500 dark:text-gray-400">Warranty</span>
            <span
              className={`${
                new Date(system.warrantyExpires) < new Date()
                  ? 'text-gray-400 dark:text-gray-500'
                  : 'text-green-600 dark:text-green-400'
              }`}
            >
              {new Date(system.warrantyExpires) < new Date()
                ? 'Expired'
                : `Until ${new Date(system.warrantyExpires).toLocaleDateString()}`}
            </span>
          </div>
        )}

        {/* Filter Info */}
        {system.filterSize && (
          <div className="border-t border-gray-200 dark:border-gray-700 pt-2 mt-2">
            <div className="flex justify-between">
              <span className="text-gray-500 dark:text-gray-400">Filter Size</span>
              <span className="text-gray-900 dark:text-white">{system.filterSize}</span>
            </div>
            {system.nextFilterChange && (
              <div className="flex justify-between mt-1">
                <span className="text-gray-500 dark:text-gray-400">Next Change</span>
                <span
                  className={`${
                    new Date(system.nextFilterChange) < new Date()
                      ? 'text-red-600 dark:text-red-400 font-medium'
                      : 'text-gray-900 dark:text-white'
                  }`}
                >
                  {new Date(system.nextFilterChange).toLocaleDateString()}
                </span>
              </div>
            )}
          </div>
        )}

        {/* Tank Level */}
        {system.tankCapacity && system.currentTankLevel !== null && (
          <div className="border-t border-gray-200 dark:border-gray-700 pt-2 mt-2">
            <div className="flex justify-between mb-1">
              <span className="text-gray-500 dark:text-gray-400">Tank Level</span>
              <span className="text-gray-900 dark:text-white">
                {Math.round((Number(system.currentTankLevel) / Number(system.tankCapacity)) * 100)}%
              </span>
            </div>
            <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
              <div
                className={`h-2 rounded-full ${
                  (Number(system.currentTankLevel) / Number(system.tankCapacity)) * 100 <= 25
                    ? 'bg-red-500'
                    : 'bg-emerald-500'
                }`}
                style={{
                  width: `${(Number(system.currentTankLevel) / Number(system.tankCapacity)) * 100}%`,
                }}
              ></div>
            </div>
          </div>
        )}

        {/* Utility Info */}
        {system.utilityProvider && (
          <div className="border-t border-gray-200 dark:border-gray-700 pt-2 mt-2">
            <div className="flex justify-between">
              <span className="text-gray-500 dark:text-gray-400">Provider</span>
              <span className="text-gray-900 dark:text-white">{system.utilityProvider}</span>
            </div>
            {system.accountNumber && (
              <div className="flex justify-between mt-1">
                <span className="text-gray-500 dark:text-gray-400">Account</span>
                <span className="font-mono text-gray-900 dark:text-white">
                  ...{system.accountNumber.slice(-4)}
                </span>
              </div>
            )}
            {system.monthlyServiceCost && (
              <div className="flex justify-between mt-1">
                <span className="text-gray-500 dark:text-gray-400">Monthly Cost</span>
                <span className="text-gray-900 dark:text-white">
                  ${Number(system.monthlyServiceCost).toFixed(2)}
                </span>
              </div>
            )}
          </div>
        )}

        {/* Preferred Vendor */}
        {system.preferredVendor && (
          <div className="border-t border-gray-200 dark:border-gray-700 pt-2 mt-2">
            <div className="flex justify-between">
              <span className="text-gray-500 dark:text-gray-400">Service By</span>
              <span className="text-gray-900 dark:text-white">
                {system.preferredVendor.displayName}
              </span>
            </div>
            {system.preferredVendor.phone && (
              <div className="flex justify-between mt-1">
                <span className="text-gray-500 dark:text-gray-400">Phone</span>
                <a
                  href={`tel:${system.preferredVendor.phone}`}
                  className="text-emerald-600 dark:text-emerald-400 hover:underline"
                >
                  {system.preferredVendor.phone}
                </a>
              </div>
            )}
          </div>
        )}

        {/* Location */}
        {system.location && (
          <div className="text-xs text-gray-400 dark:text-gray-500 mt-2">
            Location: {system.location}
          </div>
        )}
      </div>
    </div>
  );
}

function SystemCategory({
  category,
  systems,
}: {
  category: string;
  systems: FormattedHomeSystem[];
}) {
  if (systems.length === 0) return null;

  const Icon = categoryIcons[category] || CogIcon;

  return (
    <div className="mb-8">
      <div className="flex items-center space-x-2 mb-4">
        <Icon className="h-5 w-5 text-gray-600 dark:text-gray-400" />
        <h2 className="text-lg font-semibold text-gray-900 dark:text-white">
          {categoryLabels[category]}
        </h2>
        <span className="text-sm text-gray-500 dark:text-gray-400">({systems.length})</span>
      </div>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {systems.map((system) => (
          <SystemCard key={system.id} system={system} />
        ))}
      </div>
    </div>
  );
}

export default function HomeSystemsPage() {
  const api = useApi();
  const [dashboard, setDashboard] = useState<HomeDashboard | null>(null);
  const [alerts, setAlerts] = useState<HomeSystemMaintenanceAlert[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadData() {
      try {
        const [dashboardData, alertsData] = await Promise.all([
          api.getHomeSystemsDashboard(),
          api.getHomeSystemAlerts(),
        ]);
        setDashboard(dashboardData);
        setAlerts(alertsData);
      } catch (error) {
        console.error('Failed to load home systems:', error);
      } finally {
        setLoading(false);
      }
    }
    loadData();
  }, [api]);

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 dark:bg-gray-900 p-6">
        <div className="animate-pulse space-y-4">
          <div className="h-8 bg-gray-200 dark:bg-gray-700 rounded w-48"></div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {[1, 2, 3, 4, 5, 6].map((i) => (
              <div key={i} className="h-48 bg-gray-200 dark:bg-gray-700 rounded-lg"></div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  const highPriorityAlerts = alerts.filter((a) => a.severity === 'high');

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900 p-6">
      <div className="max-w-7xl mx-auto space-y-6">
        {/* Header */}
        <div className="flex justify-between items-center">
          <div>
            <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Home Systems</h1>
            <p className="text-gray-500 dark:text-gray-400">
              Complete overview of all your home systems and appliances
            </p>
          </div>
          <button className="inline-flex items-center px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition-colors">
            <PlusIcon className="h-5 w-5 mr-2" />
            Add System
          </button>
        </div>

        {/* Quick Stats */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="bg-white dark:bg-gray-800 rounded-lg p-4 shadow">
            <div className="flex items-center space-x-3">
              <div className="p-2 bg-emerald-100 dark:bg-emerald-900 rounded-lg">
                <HomeIcon className="h-6 w-6 text-emerald-600 dark:text-emerald-400" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900 dark:text-white">
                  {dashboard?.totalSystems ?? 0}
                </p>
                <p className="text-sm text-gray-500 dark:text-gray-400">Total Systems</p>
              </div>
            </div>
          </div>

          <div className="bg-white dark:bg-gray-800 rounded-lg p-4 shadow">
            <div className="flex items-center space-x-3">
              <div className="p-2 bg-red-100 dark:bg-red-900 rounded-lg">
                <ExclamationTriangleIcon className="h-6 w-6 text-red-600 dark:text-red-400" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900 dark:text-white">
                  {highPriorityAlerts.length}
                </p>
                <p className="text-sm text-gray-500 dark:text-gray-400">Urgent Alerts</p>
              </div>
            </div>
          </div>

          <div className="bg-white dark:bg-gray-800 rounded-lg p-4 shadow">
            <div className="flex items-center space-x-3">
              <div className="p-2 bg-amber-100 dark:bg-amber-900 rounded-lg">
                <CalendarIcon className="h-6 w-6 text-amber-600 dark:text-amber-400" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900 dark:text-white">
                  {alerts.filter((a) => a.type === 'SERVICE').length}
                </p>
                <p className="text-sm text-gray-500 dark:text-gray-400">Service Due</p>
              </div>
            </div>
          </div>

          <div className="bg-white dark:bg-gray-800 rounded-lg p-4 shadow">
            <div className="flex items-center space-x-3">
              <div className="p-2 bg-green-100 dark:bg-green-900 rounded-lg">
                <CurrencyDollarIcon className="h-6 w-6 text-green-600 dark:text-green-400" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900 dark:text-white">
                  $
                  {dashboard
                    ? Object.values(dashboard)
                        .flat()
                        .filter((s): s is FormattedHomeSystem => typeof s === 'object' && s !== null)
                        .reduce((sum, s) => sum + (Number(s.monthlyServiceCost) || 0), 0)
                        .toFixed(0)
                    : 0}
                </p>
                <p className="text-sm text-gray-500 dark:text-gray-400">Monthly Costs</p>
              </div>
            </div>
          </div>
        </div>

        {/* Alerts */}
        {alerts.length > 0 && (
          <div className="bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded-lg p-4">
            <div className="flex items-center space-x-2 mb-3">
              <ExclamationTriangleIcon className="h-5 w-5 text-amber-600 dark:text-amber-400" />
              <h2 className="font-semibold text-amber-800 dark:text-amber-200">
                {alerts.length} Maintenance Alert{alerts.length !== 1 ? 's' : ''}
              </h2>
            </div>
            <div className="space-y-2">
              {alerts.slice(0, 5).map((alert, idx) => (
                <div
                  key={idx}
                  className="flex items-center justify-between bg-white dark:bg-gray-800 rounded p-2"
                >
                  <span className="text-sm text-gray-700 dark:text-gray-300">
                    <span className="font-medium">{alert.systemName}:</span> {alert.message}
                  </span>
                  <span
                    className={`text-xs px-2 py-0.5 rounded ${
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

        {/* Systems by Category */}
        {dashboard && (
          <>
            <SystemCategory category="hvac" systems={dashboard.hvac} />
            <SystemCategory category="water" systems={dashboard.water} />
            <SystemCategory category="electrical" systems={dashboard.electrical} />
            <SystemCategory category="kitchen" systems={dashboard.kitchen} />
            <SystemCategory category="laundry" systems={dashboard.laundry} />
            <SystemCategory category="outdoor" systems={dashboard.outdoor} />
            <SystemCategory category="safety" systems={dashboard.safety} />
            <SystemCategory category="other" systems={dashboard.other} />
          </>
        )}

        {/* Empty State */}
        {dashboard && dashboard.totalSystems === 0 && (
          <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-12 text-center">
            <HomeIcon className="h-16 w-16 mx-auto text-gray-300 dark:text-gray-600 mb-4" />
            <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-2">
              No systems added yet
            </h2>
            <p className="text-gray-500 dark:text-gray-400 mb-4">
              Add your home systems and appliances to track maintenance, warranties, and service
              schedules.
            </p>
            <button className="inline-flex items-center px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700">
              <PlusIcon className="h-5 w-5 mr-2" />
              Add Your First System
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
