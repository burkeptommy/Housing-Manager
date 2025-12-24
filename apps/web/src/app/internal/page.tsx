'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import type { InternalDashboardStats, InternalWorkOrder } from '@haven/core';
import { getApiClient } from '@/lib/api';

export default function InternalDashboardPage() {
  const [stats, setStats] = useState<InternalDashboardStats | null>(null);
  const [appointments, setAppointments] = useState<InternalWorkOrder[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const api = getApiClient();
        const [statsData, appointmentsData] = await Promise.all([
          api.getInternalStats(),
          api.getInternalUpcomingAppointments(7),
        ]);
        setStats(statsData);
        setAppointments(appointmentsData);
      } catch (err: any) {
        setError(err.message || 'Failed to load dashboard data');
      } finally {
        setIsLoading(false);
      }
    };
    fetchData();
  }, []);

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-red-50 dark:bg-red-900/20 text-red-600 dark:text-red-400 p-4 rounded-lg">
        {error}
      </div>
    );
  }

  const statTiles = [
    {
      label: 'Active Households',
      value: stats?.activeHouseholds ?? 0,
      href: '/internal/households',
      color: 'bg-indigo-500',
      icon: (
        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
        </svg>
      ),
    },
    {
      label: 'Open Conversations',
      value: stats?.openConversations ?? 0,
      href: '/internal/conversations',
      color: 'bg-haven-700',
      badge: stats?.unassignedConversations ? `${stats.unassignedConversations} unassigned` : undefined,
      icon: (
        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
        </svg>
      ),
    },
    {
      label: 'Open Work Orders',
      value: stats?.openWorkOrders ?? 0,
      href: '/internal/work-orders',
      color: 'bg-amber-500',
      icon: (
        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
        </svg>
      ),
    },
    {
      label: "Today's Appointments",
      value: stats?.todaysAppointments ?? 0,
      href: '/internal/work-orders?filter=today',
      color: 'bg-haven-700',
      icon: (
        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
        </svg>
      ),
    },
  ];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-slate-900 dark:text-white">Internal Dashboard</h1>
        <p className="text-slate-600 dark:text-slate-400 mt-1">
          Overview of Haven operations and household management
        </p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {statTiles.map((tile) => (
          <Link
            key={tile.label}
            href={tile.href}
            className="bg-white dark:bg-slate-800 rounded-xl p-5 border border-slate-200 dark:border-slate-700 hover:border-indigo-300 dark:hover:border-indigo-600 transition-colors"
          >
            <div className="flex items-start justify-between">
              <div className={`${tile.color} p-3 rounded-lg text-white`}>
                {tile.icon}
              </div>
              {tile.badge && (
                <span className="text-xs bg-red-100 dark:bg-red-900/30 text-red-600 dark:text-red-400 px-2 py-1 rounded-full">
                  {tile.badge}
                </span>
              )}
            </div>
            <div className="mt-4">
              <p className="text-3xl font-bold text-slate-900 dark:text-white">{tile.value}</p>
              <p className="text-sm text-slate-600 dark:text-slate-400 mt-1">{tile.label}</p>
            </div>
          </Link>
        ))}
      </div>

      {/* Upcoming Appointments */}
      <div className="bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700">
        <div className="px-5 py-4 border-b border-slate-200 dark:border-slate-700 flex items-center justify-between">
          <h2 className="text-lg font-semibold text-slate-900 dark:text-white">
            Upcoming Appointments (Next 7 Days)
          </h2>
          <Link
            href="/internal/work-orders"
            className="text-sm text-indigo-600 dark:text-indigo-400 hover:underline"
          >
            View all
          </Link>
        </div>
        <div className="divide-y divide-slate-200 dark:divide-slate-700">
          {appointments.length === 0 ? (
            <div className="px-5 py-8 text-center text-slate-500 dark:text-slate-400">
              No upcoming appointments scheduled
            </div>
          ) : (
            appointments.slice(0, 5).map((apt) => (
              <div key={apt.id} className="px-5 py-4 flex items-center justify-between">
                <div className="flex-1 min-w-0">
                  <p className="font-medium text-slate-900 dark:text-white truncate">
                    {apt.title}
                  </p>
                  <p className="text-sm text-slate-600 dark:text-slate-400">
                    {apt.household.name}
                    {apt.household.homeProfile?.addressLine1 && (
                      <span className="mx-1">-</span>
                    )}
                    {apt.household.homeProfile?.addressLine1}
                  </p>
                  {apt.vendor && (
                    <p className="text-sm text-slate-500 dark:text-slate-500">
                      Vendor: {apt.vendor.name}
                    </p>
                  )}
                </div>
                <div className="ml-4 text-right">
                  {apt.scheduledStart && (
                    <>
                      <p className="text-sm font-medium text-slate-900 dark:text-white">
                        {new Date(apt.scheduledStart).toLocaleDateString('en-US', {
                          weekday: 'short',
                          month: 'short',
                          day: 'numeric',
                        })}
                      </p>
                      <p className="text-sm text-slate-600 dark:text-slate-400">
                        {new Date(apt.scheduledStart).toLocaleTimeString('en-US', {
                          hour: 'numeric',
                          minute: '2-digit',
                        })}
                      </p>
                    </>
                  )}
                  <span
                    className={`inline-block mt-1 text-xs px-2 py-0.5 rounded-full ${
                      apt.status === 'SCHEDULED'
                        ? 'bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400'
                        : apt.status === 'IN_PROGRESS'
                        ? 'bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-400'
                        : 'bg-slate-100 dark:bg-slate-700 text-slate-700 dark:text-slate-300'
                    }`}
                  >
                    {apt.status.replace('_', ' ')}
                  </span>
                </div>
              </div>
            ))
          )}
        </div>
      </div>

      {/* Quick Actions */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Link
          href="/internal/conversations?status=unassigned"
          className="bg-white dark:bg-slate-800 rounded-xl p-5 border border-slate-200 dark:border-slate-700 hover:border-indigo-300 dark:hover:border-indigo-600 transition-colors flex items-center gap-4"
        >
          <div className="bg-haven-100 dark:bg-haven-900/30 p-3 rounded-lg">
            <svg className="w-6 h-6 text-haven-700 dark:text-haven-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z" />
            </svg>
          </div>
          <div>
            <p className="font-medium text-slate-900 dark:text-white">Pick up conversation</p>
            <p className="text-sm text-slate-600 dark:text-slate-400">Assign unassigned conversations to yourself</p>
          </div>
        </Link>

        <Link
          href="/internal/work-orders?status=REQUESTED"
          className="bg-white dark:bg-slate-800 rounded-xl p-5 border border-slate-200 dark:border-slate-700 hover:border-indigo-300 dark:hover:border-indigo-600 transition-colors flex items-center gap-4"
        >
          <div className="bg-amber-100 dark:bg-amber-900/30 p-3 rounded-lg">
            <svg className="w-6 h-6 text-amber-600 dark:text-amber-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <div>
            <p className="font-medium text-slate-900 dark:text-white">Schedule work orders</p>
            <p className="text-sm text-slate-600 dark:text-slate-400">Review and schedule pending requests</p>
          </div>
        </Link>

        <Link
          href="/internal/households"
          className="bg-white dark:bg-slate-800 rounded-xl p-5 border border-slate-200 dark:border-slate-700 hover:border-indigo-300 dark:hover:border-indigo-600 transition-colors flex items-center gap-4"
        >
          <div className="bg-haven-100 dark:bg-haven-900/30 p-3 rounded-lg">
            <svg className="w-6 h-6 text-haven-700 dark:text-haven-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
            </svg>
          </div>
          <div>
            <p className="font-medium text-slate-900 dark:text-white">Manage households</p>
            <p className="text-sm text-slate-600 dark:text-slate-400">View and manage all household accounts</p>
          </div>
        </Link>
      </div>
    </div>
  );
}
