'use client';

import { useState, useEffect } from 'react';
import { useApi } from '@/lib/api';
import { useAuth } from '@/contexts/auth-context';
import Link from 'next/link';
import type { FamilyMember, AllFamilyAlerts, CalendarSummary } from '@haven/core';
import {
  UserGroupIcon,
  TruckIcon,
  HeartIcon,
  CalendarIcon,
  ExclamationTriangleIcon,
  ChevronRightIcon,
  CakeIcon,
} from '@heroicons/react/24/outline';

export default function FamilyPage() {
  const api = useApi();
  const { user } = useAuth();
  const [members, setMembers] = useState<FamilyMember[]>([]);
  const [alerts, setAlerts] = useState<AllFamilyAlerts | null>(null);
  const [calendarSummary, setCalendarSummary] = useState<CalendarSummary | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadData() {
      try {
        const [membersData, alertsData, summaryData] = await Promise.all([
          api.getFamilyMembers(),
          api.getAllFamilyAlerts(),
          api.getCalendarSummary(),
        ]);
        setMembers(membersData);
        setAlerts(alertsData);
        setCalendarSummary(summaryData);
      } catch (error) {
        console.error('Failed to load family data:', error);
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
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            {[1, 2, 3, 4].map((i) => (
              <div key={i} className="h-32 bg-gray-200 dark:bg-gray-700 rounded-lg"></div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  const highPriorityAlerts = alerts
    ? [...alerts.vehicles, ...alerts.pets, ...alerts.homeSystems].filter((a) => a.severity === 'high')
    : [];

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900 p-6">
      <div className="max-w-7xl mx-auto space-y-6">
        {/* Header */}
        <div className="flex justify-between items-center">
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Family Hub</h1>
        </div>

        {/* Quick Stats */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <Link
            href="/app/family"
            className="bg-white dark:bg-gray-800 rounded-lg p-4 shadow hover:shadow-md transition-shadow"
          >
            <div className="flex items-center space-x-3">
              <div className="p-2 bg-emerald-100 dark:bg-emerald-900 rounded-lg">
                <UserGroupIcon className="h-6 w-6 text-emerald-600 dark:text-emerald-400" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900 dark:text-white">{members.length}</p>
                <p className="text-sm text-gray-500 dark:text-gray-400">Members</p>
              </div>
            </div>
          </Link>

          <Link
            href="/app/family/garage"
            className="bg-white dark:bg-gray-800 rounded-lg p-4 shadow hover:shadow-md transition-shadow"
          >
            <div className="flex items-center space-x-3">
              <div className="p-2 bg-green-100 dark:bg-green-900 rounded-lg">
                <TruckIcon className="h-6 w-6 text-green-600 dark:text-green-400" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900 dark:text-white">
                  {alerts?.vehicles.length ?? 0}
                </p>
                <p className="text-sm text-gray-500 dark:text-gray-400">Vehicle Alerts</p>
              </div>
            </div>
          </Link>

          <Link
            href="/app/family/pets"
            className="bg-white dark:bg-gray-800 rounded-lg p-4 shadow hover:shadow-md transition-shadow"
          >
            <div className="flex items-center space-x-3">
              <div className="p-2 bg-pink-100 dark:bg-pink-900 rounded-lg">
                <HeartIcon className="h-6 w-6 text-pink-600 dark:text-pink-400" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900 dark:text-white">
                  {alerts?.pets.length ?? 0}
                </p>
                <p className="text-sm text-gray-500 dark:text-gray-400">Pet Alerts</p>
              </div>
            </div>
          </Link>

          <Link
            href="/app/family/calendar"
            className="bg-white dark:bg-gray-800 rounded-lg p-4 shadow hover:shadow-md transition-shadow"
          >
            <div className="flex items-center space-x-3">
              <div className="p-2 bg-purple-100 dark:bg-purple-900 rounded-lg">
                <CalendarIcon className="h-6 w-6 text-purple-600 dark:text-purple-400" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900 dark:text-white">
                  {calendarSummary?.todayCount ?? 0}
                </p>
                <p className="text-sm text-gray-500 dark:text-gray-400">Events Today</p>
              </div>
            </div>
          </Link>
        </div>

        {/* Alerts Section */}
        {highPriorityAlerts.length > 0 && (
          <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4">
            <div className="flex items-center space-x-2 mb-3">
              <ExclamationTriangleIcon className="h-5 w-5 text-red-600 dark:text-red-400" />
              <h2 className="font-semibold text-red-800 dark:text-red-200">
                {highPriorityAlerts.length} High Priority Alerts
              </h2>
            </div>
            <div className="space-y-2">
              {highPriorityAlerts.slice(0, 3).map((alert, idx) => (
                <div
                  key={idx}
                  className="flex items-center justify-between bg-white dark:bg-gray-800 rounded p-2"
                >
                  <span className="text-sm text-gray-700 dark:text-gray-300">
                    {'vehicleId' in alert && (
                      <span className="font-medium">{alert.vehicleName}: </span>
                    )}
                    {'petId' in alert && <span className="font-medium">{alert.petName}: </span>}
                    {'systemId' in alert && <span className="font-medium">{alert.systemName}: </span>}
                    {alert.message}
                  </span>
                  <span className="text-xs bg-red-100 dark:bg-red-900 text-red-800 dark:text-red-200 px-2 py-0.5 rounded">
                    {alert.type}
                  </span>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Family Members Grid */}
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
          <div className="flex justify-between items-center mb-4">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white">Family Members</h2>
          </div>
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
            {members.map((member) => (
              <div
                key={member.id}
                className="border border-gray-200 dark:border-gray-700 rounded-lg p-4 hover:border-emerald-500 transition-colors"
              >
                <div className="flex items-center space-x-3">
                  {member.user?.photoUrl ? (
                    <img
                      src={member.user.photoUrl}
                      alt={member.displayName}
                      className="h-12 w-12 rounded-full object-cover"
                    />
                  ) : (
                    <div className="h-12 w-12 rounded-full bg-emerald-100 dark:bg-emerald-900 flex items-center justify-center">
                      <span className="text-lg font-semibold text-emerald-600 dark:text-emerald-400">
                        {member.displayName.charAt(0)}
                      </span>
                    </div>
                  )}
                  <div>
                    <p className="font-medium text-gray-900 dark:text-white">{member.displayName}</p>
                    <p className="text-sm text-gray-500 dark:text-gray-400 capitalize">
                      {member.role.toLowerCase().replace('_', ' ')}
                    </p>
                  </div>
                </div>
                {member.profile?.birthday && (
                  <div className="mt-3 text-xs text-gray-500 dark:text-gray-400">
                    <CakeIcon className="h-3 w-3 inline mr-1" />
                    {new Date(member.profile.birthday).toLocaleDateString(undefined, {
                      month: 'short',
                      day: 'numeric',
                    })}
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>

        {/* Upcoming Birthdays */}
        {calendarSummary && calendarSummary.upcomingBirthdays.length > 0 && (
          <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
              Upcoming Birthdays
            </h2>
            <div className="space-y-2">
              {calendarSummary.upcomingBirthdays.map((birthday) => (
                <div
                  key={birthday.memberId}
                  className="flex items-center justify-between bg-purple-50 dark:bg-purple-900/20 rounded-lg p-3"
                >
                  <div className="flex items-center space-x-3">
                    <CakeIcon className="h-5 w-5 text-purple-600 dark:text-purple-400" />
                    <span className="font-medium text-gray-900 dark:text-white">{birthday.name}</span>
                  </div>
                  <span className="text-sm text-purple-600 dark:text-purple-400">
                    {birthday.daysUntil === 0
                      ? 'Today!'
                      : birthday.daysUntil === 1
                        ? 'Tomorrow'
                        : `In ${birthday.daysUntil} days`}
                  </span>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Quick Links */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <Link
            href="/app/family/garage"
            className="bg-white dark:bg-gray-800 rounded-lg shadow p-4 flex items-center justify-between hover:shadow-md transition-shadow"
          >
            <div className="flex items-center space-x-3">
              <TruckIcon className="h-6 w-6 text-green-600 dark:text-green-400" />
              <span className="font-medium text-gray-900 dark:text-white">Garage</span>
            </div>
            <ChevronRightIcon className="h-5 w-5 text-gray-400" />
          </Link>

          <Link
            href="/app/family/pets"
            className="bg-white dark:bg-gray-800 rounded-lg shadow p-4 flex items-center justify-between hover:shadow-md transition-shadow"
          >
            <div className="flex items-center space-x-3">
              <HeartIcon className="h-6 w-6 text-pink-600 dark:text-pink-400" />
              <span className="font-medium text-gray-900 dark:text-white">Pets</span>
            </div>
            <ChevronRightIcon className="h-5 w-5 text-gray-400" />
          </Link>

          <Link
            href="/app/family/calendar"
            className="bg-white dark:bg-gray-800 rounded-lg shadow p-4 flex items-center justify-between hover:shadow-md transition-shadow"
          >
            <div className="flex items-center space-x-3">
              <CalendarIcon className="h-6 w-6 text-purple-600 dark:text-purple-400" />
              <span className="font-medium text-gray-900 dark:text-white">Family Calendar</span>
            </div>
            <ChevronRightIcon className="h-5 w-5 text-gray-400" />
          </Link>
        </div>
      </div>
    </div>
  );
}
