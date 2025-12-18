'use client';

import { useState, useEffect, useCallback } from 'react';
import Link from 'next/link';
import type { VendorScheduleItem, VendorWorkOrderStatus } from '@haven/core';

// Mock data for demo
const mockSchedule: VendorScheduleItem[] = [
  {
    id: 'wo-assigned-1',
    title: 'HVAC Annual Inspection',
    description: 'Annual maintenance and filter replacement for central HVAC system.',
    status: 'ASSIGNED',
    scheduledStart: '2024-12-18T10:00:00Z',
    scheduledEnd: '2024-12-18T12:00:00Z',
    estimatedCost: 450,
    serviceArea: 'Malibu',
    checkInAt: null,
    checkOutAt: null,
    household: {
      id: 'h-malibu',
      name: 'Malibu Mansion',
      homeProfile: {
        address: '27400 Pacific Coast Hwy, Malibu, CA 90265',
        latitude: 34.0259,
        longitude: -118.7798,
      },
    },
  },
  {
    id: 'wo-progress-1',
    title: 'Pool Pump Repair',
    description: 'Pool pump making unusual noise. May need bearing replacement.',
    status: 'IN_PROGRESS',
    scheduledStart: '2024-12-17T14:00:00Z',
    scheduledEnd: '2024-12-17T17:00:00Z',
    estimatedCost: 325,
    serviceArea: 'Beverly Hills',
    checkInAt: '2024-12-17T14:15:00Z',
    checkOutAt: null,
    household: {
      id: 'h-beverly',
      name: 'Beverly Hills Estate',
      homeProfile: {
        address: '1200 Sunset Blvd, Beverly Hills, CA 90210',
        latitude: 34.0901,
        longitude: -118.4065,
      },
    },
  },
];

const STATUS_COLORS: Record<VendorWorkOrderStatus, string> = {
  DRAFT: 'bg-slate-100 text-slate-600 border-slate-300',
  REQUESTED: 'bg-blue-100 text-blue-700 border-blue-300',
  SCHEDULED: 'bg-purple-100 text-purple-700 border-purple-300',
  OPEN: 'bg-green-100 text-green-700 border-green-300',
  ASSIGNED: 'bg-yellow-100 text-yellow-700 border-yellow-300',
  IN_PROGRESS: 'bg-orange-100 text-orange-700 border-orange-300',
  COMPLETED: 'bg-blue-100 text-blue-700 border-blue-300',
  VERIFIED: 'bg-emerald-100 text-emerald-700 border-emerald-300',
  CANCELLED: 'bg-red-100 text-red-700 border-red-300',
};

export default function SchedulePage() {
  const [schedule, setSchedule] = useState<VendorScheduleItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [viewMode, setViewMode] = useState<'list' | 'calendar'>('list');

  const loadSchedule = useCallback(async () => {
    setIsLoading(true);
    await new Promise((resolve) => setTimeout(resolve, 500));
    setSchedule(mockSchedule);
    setIsLoading(false);
  }, []);

  useEffect(() => {
    loadSchedule();
  }, [loadSchedule]);

  const formatDate = (dateStr: string | null) => {
    if (!dateStr) return 'TBD';
    const date = new Date(dateStr);
    return date.toLocaleDateString('en-US', {
      weekday: 'long',
      month: 'long',
      day: 'numeric',
    });
  };

  const formatTime = (dateStr: string | null) => {
    if (!dateStr) return '';
    return new Date(dateStr).toLocaleTimeString('en-US', {
      hour: 'numeric',
      minute: '2-digit',
    });
  };

  const formatCurrency = (amount: number | null) => {
    if (amount === null) return 'TBD';
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(amount);
  };

  const getTimeElapsed = (checkInAt: string | null) => {
    if (!checkInAt) return '';
    const start = new Date(checkInAt);
    const now = new Date();
    const diffMs = now.getTime() - start.getTime();
    const diffHrs = Math.floor(diffMs / 3600000);
    const diffMins = Math.floor((diffMs % 3600000) / 60000);
    if (diffHrs > 0) {
      return `${diffHrs}h ${diffMins}m elapsed`;
    }
    return `${diffMins}m elapsed`;
  };

  // Group jobs by date
  const groupedByDate = schedule.reduce(
    (acc, job) => {
      const date = job.scheduledStart
        ? new Date(job.scheduledStart).toDateString()
        : 'Unscheduled';
      if (!acc[date]) acc[date] = [];
      acc[date].push(job);
      return acc;
    },
    {} as Record<string, VendorScheduleItem[]>,
  );

  // Sort dates
  const sortedDates = Object.keys(groupedByDate).sort((a, b) => {
    if (a === 'Unscheduled') return 1;
    if (b === 'Unscheduled') return -1;
    return new Date(a).getTime() - new Date(b).getTime();
  });

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-orange-600"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 dark:text-white">My Schedule</h1>
          <p className="text-slate-600 dark:text-slate-400">Jobs you&apos;ve accepted</p>
        </div>
        <div className="flex bg-slate-100 dark:bg-slate-800 rounded-lg p-1">
          <button
            onClick={() => setViewMode('list')}
            className={`px-3 py-1.5 text-sm font-medium rounded transition-colors ${
              viewMode === 'list'
                ? 'bg-white dark:bg-slate-700 text-slate-900 dark:text-white shadow-sm'
                : 'text-slate-600 dark:text-slate-400'
            }`}
          >
            List
          </button>
          <button
            onClick={() => setViewMode('calendar')}
            className={`px-3 py-1.5 text-sm font-medium rounded transition-colors ${
              viewMode === 'calendar'
                ? 'bg-white dark:bg-slate-700 text-slate-900 dark:text-white shadow-sm'
                : 'text-slate-600 dark:text-slate-400'
            }`}
          >
            Calendar
          </button>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="card">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-lg bg-yellow-100 dark:bg-yellow-900/30 flex items-center justify-center">
              <svg className="w-5 h-5 text-yellow-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <div>
              <p className="text-xl font-bold text-slate-900 dark:text-white">
                {schedule.filter((j) => j.status === 'ASSIGNED').length}
              </p>
              <p className="text-xs text-slate-500 dark:text-slate-400">Upcoming</p>
            </div>
          </div>
        </div>
        <div className="card">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-lg bg-orange-100 dark:bg-orange-900/30 flex items-center justify-center">
              <svg className="w-5 h-5 text-orange-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
              </svg>
            </div>
            <div>
              <p className="text-xl font-bold text-slate-900 dark:text-white">
                {schedule.filter((j) => j.status === 'IN_PROGRESS').length}
              </p>
              <p className="text-xs text-slate-500 dark:text-slate-400">In Progress</p>
            </div>
          </div>
        </div>
        <div className="card">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-lg bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center">
              <svg className="w-5 h-5 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
            </div>
            <div>
              <p className="text-xl font-bold text-slate-900 dark:text-white">
                {sortedDates.filter((d) => d !== 'Unscheduled').length}
              </p>
              <p className="text-xs text-slate-500 dark:text-slate-400">Days Booked</p>
            </div>
          </div>
        </div>
        <div className="card">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-lg bg-green-100 dark:bg-green-900/30 flex items-center justify-center">
              <svg className="w-5 h-5 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <div>
              <p className="text-xl font-bold text-slate-900 dark:text-white">
                {formatCurrency(schedule.reduce((sum, j) => sum + (j.estimatedCost || 0), 0))}
              </p>
              <p className="text-xs text-slate-500 dark:text-slate-400">Total Value</p>
            </div>
          </div>
        </div>
      </div>

      {/* Schedule List */}
      {schedule.length === 0 ? (
        <div className="card text-center py-12">
          <svg className="w-12 h-12 mx-auto text-slate-400 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
          </svg>
          <h3 className="text-lg font-medium text-slate-900 dark:text-white mb-2">No jobs scheduled</h3>
          <p className="text-slate-600 dark:text-slate-400 mb-4">
            Check the job board to claim available jobs.
          </p>
          <Link
            href="/vendor"
            className="inline-flex items-center gap-2 px-4 py-2 bg-orange-600 text-white rounded-lg hover:bg-orange-700 transition-colors"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
            </svg>
            Browse Job Board
          </Link>
        </div>
      ) : (
        <div className="space-y-6">
          {sortedDates.map((date) => (
            <div key={date}>
              <h2 className="text-lg font-semibold text-slate-900 dark:text-white mb-3">
                {date === 'Unscheduled'
                  ? 'Unscheduled'
                  : new Date(date).toLocaleDateString('en-US', {
                      weekday: 'long',
                      month: 'long',
                      day: 'numeric',
                    })}
              </h2>
              <div className="space-y-3">
                {groupedByDate[date].map((job) => (
                  <Link
                    key={job.id}
                    href={`/vendor/jobs/${job.id}`}
                    className={`card block border-l-4 hover:shadow-lg transition-shadow ${
                      job.status === 'IN_PROGRESS'
                        ? 'border-l-orange-500 bg-orange-50 dark:bg-orange-900/10'
                        : 'border-l-yellow-500'
                    }`}
                  >
                    <div className="flex flex-col lg:flex-row lg:items-center gap-4">
                      <div className="flex-1">
                        <div className="flex items-center gap-2 mb-1">
                          <h3 className="font-semibold text-slate-900 dark:text-white">{job.title}</h3>
                          <span className={`px-2 py-0.5 rounded text-xs font-medium ${STATUS_COLORS[job.status]}`}>
                            {job.status.replace('_', ' ')}
                          </span>
                        </div>
                        <p className="text-sm text-slate-600 dark:text-slate-400 mb-2">{job.household.name}</p>
                        {job.household.homeProfile?.address && (
                          <p className="text-sm text-slate-500 dark:text-slate-400 flex items-center gap-1">
                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                            </svg>
                            {job.household.homeProfile.address}
                          </p>
                        )}
                      </div>
                      <div className="flex items-center gap-6">
                        <div className="text-right">
                          <p className="text-sm font-medium text-slate-900 dark:text-white">
                            {formatTime(job.scheduledStart)} - {formatTime(job.scheduledEnd)}
                          </p>
                          {job.status === 'IN_PROGRESS' && job.checkInAt && (
                            <p className="text-xs text-orange-600 dark:text-orange-400 font-medium">
                              {getTimeElapsed(job.checkInAt)}
                            </p>
                          )}
                        </div>
                        <div className="text-right">
                          <p className="font-bold text-slate-900 dark:text-white">
                            {formatCurrency(job.estimatedCost)}
                          </p>
                        </div>
                        <svg className="w-5 h-5 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                        </svg>
                      </div>
                    </div>
                  </Link>
                ))}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
