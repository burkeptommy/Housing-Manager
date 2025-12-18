'use client';

import { useState, useEffect, useCallback } from 'react';
import Link from 'next/link';
import type { VendorJobBoardItem, VendorWorkOrderStatus } from '@haven/core';

// Mock data for demo
const mockJobs: VendorJobBoardItem[] = [
  {
    id: 'wo-001',
    title: 'Fix Shingles on South-Facing Roof',
    description:
      'Several shingles have come loose after the recent storm. Need to replace approximately 20 shingles and check for any water damage.',
    status: 'OPEN',
    scheduledStart: '2024-12-20T09:00:00Z',
    scheduledEnd: '2024-12-20T14:00:00Z',
    estimatedCost: 850,
    serviceArea: 'Malibu',
    household: {
      id: 'h-malibu',
      name: 'Malibu Mansion',
    },
    createdAt: '2024-12-17T10:00:00Z',
  },
  {
    id: 'wo-002',
    title: 'Gutter Cleaning and Repair',
    description: 'Annual gutter cleaning plus repair of a section that has come loose from the fascia.',
    status: 'OPEN',
    scheduledStart: '2024-12-21T10:00:00Z',
    scheduledEnd: '2024-12-21T13:00:00Z',
    estimatedCost: 350,
    serviceArea: 'Malibu',
    household: {
      id: 'h-malibu',
      name: 'Malibu Mansion',
    },
    createdAt: '2024-12-16T14:00:00Z',
  },
  {
    id: 'wo-003',
    title: 'Replace Bathroom Exhaust Fan',
    description: 'Master bathroom exhaust fan is making noise and not venting properly. Need replacement.',
    status: 'OPEN',
    scheduledStart: null,
    scheduledEnd: null,
    estimatedCost: 275,
    serviceArea: 'Beverly Hills',
    household: {
      id: 'h-beverly',
      name: 'Beverly Hills Estate',
    },
    createdAt: '2024-12-15T09:00:00Z',
  },
];

const STATUS_COLORS: Record<VendorWorkOrderStatus, string> = {
  DRAFT: 'bg-slate-100 text-slate-600',
  REQUESTED: 'bg-blue-100 text-blue-700',
  SCHEDULED: 'bg-purple-100 text-purple-700',
  OPEN: 'bg-green-100 text-green-700',
  ASSIGNED: 'bg-yellow-100 text-yellow-700',
  IN_PROGRESS: 'bg-orange-100 text-orange-700',
  COMPLETED: 'bg-blue-100 text-blue-700',
  VERIFIED: 'bg-emerald-100 text-emerald-700',
  CANCELLED: 'bg-red-100 text-red-700',
};

export default function JobBoardPage() {
  const [jobs, setJobs] = useState<VendorJobBoardItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [selectedArea, setSelectedArea] = useState<string>('all');
  const [claimingId, setClaimingId] = useState<string | null>(null);

  const loadJobs = useCallback(async () => {
    setIsLoading(true);
    // Simulate API call
    await new Promise((resolve) => setTimeout(resolve, 500));
    setJobs(mockJobs);
    setIsLoading(false);
  }, []);

  useEffect(() => {
    loadJobs();
  }, [loadJobs]);

  const handleClaimJob = async (jobId: string) => {
    setClaimingId(jobId);
    // Simulate API call
    await new Promise((resolve) => setTimeout(resolve, 1000));
    // Remove claimed job from list
    setJobs((prev) => prev.filter((j) => j.id !== jobId));
    setClaimingId(null);
    // In production, would redirect to /vendor/schedule
  };

  const formatDate = (dateStr: string | null) => {
    if (!dateStr) return 'Flexible';
    const date = new Date(dateStr);
    return date.toLocaleDateString('en-US', {
      weekday: 'short',
      month: 'short',
      day: 'numeric',
    });
  };

  const formatTimeWindow = (start: string | null, end: string | null) => {
    if (!start) return 'TBD';
    const startDate = new Date(start);
    const startTime = startDate.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
    if (end) {
      const endDate = new Date(end);
      const endTime = endDate.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
      return `${startTime} - ${endTime}`;
    }
    return startTime;
  };

  const formatCurrency = (amount: number | null) => {
    if (amount === null) return 'Quote Required';
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(amount);
  };

  // Get unique service areas for filter
  const serviceAreas = [...new Set(jobs.map((j) => j.serviceArea).filter(Boolean))] as string[];

  const filteredJobs = selectedArea === 'all' ? jobs : jobs.filter((j) => j.serviceArea === selectedArea);

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
      <div>
        <h1 className="text-2xl font-bold text-slate-900 dark:text-white">Job Board</h1>
        <p className="text-slate-600 dark:text-slate-400">Available jobs in your service area</p>
      </div>

      {/* Filter */}
      {serviceAreas.length > 0 && (
        <div className="flex gap-2 flex-wrap">
          <button
            onClick={() => setSelectedArea('all')}
            className={`px-3 py-1.5 rounded-full text-sm font-medium transition-colors ${
              selectedArea === 'all'
                ? 'bg-orange-600 text-white'
                : 'bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400 hover:bg-slate-200 dark:hover:bg-slate-700'
            }`}
          >
            All Areas
          </button>
          {serviceAreas.map((area) => (
            <button
              key={area}
              onClick={() => setSelectedArea(area)}
              className={`px-3 py-1.5 rounded-full text-sm font-medium transition-colors ${
                selectedArea === area
                  ? 'bg-orange-600 text-white'
                  : 'bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400 hover:bg-slate-200 dark:hover:bg-slate-700'
              }`}
            >
              {area}
            </button>
          ))}
        </div>
      )}

      {/* Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-3 gap-4">
        <div className="card">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-lg bg-green-100 dark:bg-green-900/30 flex items-center justify-center">
              <svg
                className="w-6 h-6 text-green-600 dark:text-green-400"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
                />
              </svg>
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900 dark:text-white">{filteredJobs.length}</p>
              <p className="text-sm text-slate-500 dark:text-slate-400">Open Jobs</p>
            </div>
          </div>
        </div>
        <div className="card">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-lg bg-orange-100 dark:bg-orange-900/30 flex items-center justify-center">
              <svg
                className="w-6 h-6 text-orange-600 dark:text-orange-400"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900 dark:text-white">
                {formatCurrency(filteredJobs.reduce((sum, j) => sum + (j.estimatedCost || 0), 0))}
              </p>
              <p className="text-sm text-slate-500 dark:text-slate-400">Total Value</p>
            </div>
          </div>
        </div>
        <div className="card hidden lg:block">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-lg bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center">
              <svg
                className="w-6 h-6 text-blue-600 dark:text-blue-400"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"
                />
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"
                />
              </svg>
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900 dark:text-white">{serviceAreas.length}</p>
              <p className="text-sm text-slate-500 dark:text-slate-400">Service Areas</p>
            </div>
          </div>
        </div>
      </div>

      {/* Job List */}
      <div className="space-y-4">
        {filteredJobs.length === 0 ? (
          <div className="card text-center py-12">
            <svg
              className="w-12 h-12 mx-auto text-slate-400 mb-4"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
              />
            </svg>
            <h3 className="text-lg font-medium text-slate-900 dark:text-white mb-2">No open jobs</h3>
            <p className="text-slate-600 dark:text-slate-400">
              Check back later for new job opportunities in your area.
            </p>
          </div>
        ) : (
          filteredJobs.map((job) => (
            <div key={job.id} className="card hover:shadow-lg transition-shadow">
              <div className="flex flex-col lg:flex-row lg:items-start gap-4">
                {/* Job Info */}
                <div className="flex-1">
                  <div className="flex items-start justify-between gap-4 mb-2">
                    <div>
                      <Link
                        href={`/vendor/jobs/${job.id}`}
                        className="text-lg font-semibold text-slate-900 dark:text-white hover:text-orange-600 transition-colors"
                      >
                        {job.title}
                      </Link>
                      <div className="flex items-center gap-2 mt-1">
                        <span className={`px-2 py-0.5 rounded text-xs font-medium ${STATUS_COLORS[job.status]}`}>
                          {job.status}
                        </span>
                        {job.serviceArea && (
                          <span className="text-sm text-slate-500 dark:text-slate-400">
                            {job.serviceArea}
                          </span>
                        )}
                      </div>
                    </div>
                    <div className="text-right">
                      <p className="text-lg font-bold text-slate-900 dark:text-white">
                        {formatCurrency(job.estimatedCost)}
                      </p>
                      <p className="text-xs text-slate-500 dark:text-slate-400">Estimated</p>
                    </div>
                  </div>

                  <p className="text-slate-600 dark:text-slate-300 text-sm mb-3 line-clamp-2">
                    {job.description}
                  </p>

                  <div className="flex items-center gap-4 text-sm text-slate-500 dark:text-slate-400">
                    <div className="flex items-center gap-1">
                      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth={2}
                          d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"
                        />
                      </svg>
                      <span>{job.household.name}</span>
                    </div>
                    <div className="flex items-center gap-1">
                      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth={2}
                          d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                        />
                      </svg>
                      <span>{formatDate(job.scheduledStart)}</span>
                    </div>
                    <div className="flex items-center gap-1">
                      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth={2}
                          d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                        />
                      </svg>
                      <span>{formatTimeWindow(job.scheduledStart, job.scheduledEnd)}</span>
                    </div>
                  </div>
                </div>

                {/* Actions */}
                <div className="flex lg:flex-col gap-2">
                  <Link
                    href={`/vendor/jobs/${job.id}`}
                    className="flex-1 lg:flex-none px-4 py-2 text-sm font-medium text-slate-600 dark:text-slate-300 bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 dark:hover:bg-slate-700 rounded-lg text-center transition-colors"
                  >
                    View Details
                  </Link>
                  <button
                    onClick={() => handleClaimJob(job.id)}
                    disabled={claimingId === job.id}
                    className="flex-1 lg:flex-none px-4 py-2 text-sm font-medium text-white bg-orange-600 hover:bg-orange-700 rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                  >
                    {claimingId === job.id ? (
                      <>
                        <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                        Claiming...
                      </>
                    ) : (
                      'Claim Job'
                    )}
                  </button>
                </div>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}
