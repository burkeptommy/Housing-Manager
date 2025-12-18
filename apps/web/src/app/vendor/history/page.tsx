'use client';

import { useState, useEffect, useCallback } from 'react';
import type { VendorScheduleItem, VendorWorkOrderStatus } from '@haven/core';

// Mock data for demo
const mockHistory: VendorScheduleItem[] = [
  {
    id: 'wo-completed-1',
    title: 'Kitchen Faucet Replacement',
    description: 'Replace kitchen faucet with customer-provided Delta model.',
    status: 'VERIFIED',
    scheduledStart: '2024-12-10T09:00:00Z',
    scheduledEnd: '2024-12-10T11:00:00Z',
    estimatedCost: 275,
    serviceArea: 'Malibu',
    checkInAt: '2024-12-10T09:15:00Z',
    checkOutAt: '2024-12-10T10:45:00Z',
    household: {
      id: 'h-malibu',
      name: 'Malibu Mansion',
    },
  },
  {
    id: 'wo-completed-2',
    title: 'HVAC Filter Replacement',
    description: 'Quarterly filter replacement and system check.',
    status: 'VERIFIED',
    scheduledStart: '2024-12-05T14:00:00Z',
    scheduledEnd: '2024-12-05T15:00:00Z',
    estimatedCost: 150,
    serviceArea: 'Beverly Hills',
    checkInAt: '2024-12-05T14:05:00Z',
    checkOutAt: '2024-12-05T14:50:00Z',
    household: {
      id: 'h-beverly',
      name: 'Beverly Hills Estate',
    },
  },
  {
    id: 'wo-awaiting-1',
    title: 'Garage Door Spring Repair',
    description: 'Replace broken torsion spring on garage door.',
    status: 'COMPLETED',
    scheduledStart: '2024-12-15T10:00:00Z',
    scheduledEnd: '2024-12-15T13:00:00Z',
    estimatedCost: 425,
    serviceArea: 'Malibu',
    checkInAt: '2024-12-15T10:10:00Z',
    checkOutAt: '2024-12-15T12:30:00Z',
    household: {
      id: 'h-malibu',
      name: 'Malibu Mansion',
    },
  },
];

const STATUS_COLORS: Record<VendorWorkOrderStatus, string> = {
  DRAFT: 'bg-slate-100 text-slate-600',
  REQUESTED: 'bg-emerald-100 text-emerald-700',
  SCHEDULED: 'bg-purple-100 text-purple-700',
  OPEN: 'bg-green-100 text-green-700',
  ASSIGNED: 'bg-yellow-100 text-yellow-700',
  IN_PROGRESS: 'bg-orange-100 text-orange-700',
  COMPLETED: 'bg-emerald-100 text-emerald-700',
  VERIFIED: 'bg-emerald-100 text-emerald-700',
  CANCELLED: 'bg-red-100 text-red-700',
};

export default function HistoryPage() {
  const [history, setHistory] = useState<VendorScheduleItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  const loadHistory = useCallback(async () => {
    setIsLoading(true);
    await new Promise((resolve) => setTimeout(resolve, 500));
    setHistory(mockHistory);
    setIsLoading(false);
  }, []);

  useEffect(() => {
    loadHistory();
  }, [loadHistory]);

  const formatDate = (dateStr: string | null) => {
    if (!dateStr) return 'N/A';
    return new Date(dateStr).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
    });
  };

  const formatCurrency = (amount: number | null) => {
    if (amount === null) return 'N/A';
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(amount);
  };

  const getDuration = (checkIn: string | null, checkOut: string | null) => {
    if (!checkIn || !checkOut) return 'N/A';
    const start = new Date(checkIn);
    const end = new Date(checkOut);
    const diffMs = end.getTime() - start.getTime();
    const diffHrs = Math.floor(diffMs / 3600000);
    const diffMins = Math.floor((diffMs % 3600000) / 60000);
    if (diffHrs > 0) {
      return `${diffHrs}h ${diffMins}m`;
    }
    return `${diffMins}m`;
  };

  const verifiedJobs = history.filter((j) => j.status === 'VERIFIED');
  const pendingJobs = history.filter((j) => j.status === 'COMPLETED');
  const totalEarnings = verifiedJobs.reduce((sum, j) => sum + (j.estimatedCost || 0), 0);

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
        <h1 className="text-2xl font-bold text-slate-900 dark:text-white">Job History</h1>
        <p className="text-slate-600 dark:text-slate-400">Your completed and verified jobs</p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="card">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-lg bg-emerald-100 dark:bg-emerald-900/30 flex items-center justify-center">
              <svg className="w-5 h-5 text-emerald-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <div>
              <p className="text-xl font-bold text-slate-900 dark:text-white">{verifiedJobs.length}</p>
              <p className="text-xs text-slate-500 dark:text-slate-400">Verified</p>
            </div>
          </div>
        </div>
        <div className="card">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-lg bg-emerald-100 dark:bg-emerald-900/30 flex items-center justify-center">
              <svg className="w-5 h-5 text-emerald-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <div>
              <p className="text-xl font-bold text-slate-900 dark:text-white">{pendingJobs.length}</p>
              <p className="text-xs text-slate-500 dark:text-slate-400">Pending Review</p>
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
              <p className="text-xl font-bold text-slate-900 dark:text-white">{formatCurrency(totalEarnings)}</p>
              <p className="text-xs text-slate-500 dark:text-slate-400">Total Earnings</p>
            </div>
          </div>
        </div>
        <div className="card">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-lg bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center">
              <svg className="w-5 h-5 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z" />
              </svg>
            </div>
            <div>
              <p className="text-xl font-bold text-slate-900 dark:text-white">{history.length}</p>
              <p className="text-xs text-slate-500 dark:text-slate-400">Total Jobs</p>
            </div>
          </div>
        </div>
      </div>

      {/* Job List */}
      {history.length === 0 ? (
        <div className="card text-center py-12">
          <svg className="w-12 h-12 mx-auto text-slate-400 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <h3 className="text-lg font-medium text-slate-900 dark:text-white mb-2">No job history</h3>
          <p className="text-slate-600 dark:text-slate-400">Completed jobs will appear here.</p>
        </div>
      ) : (
        <div className="card overflow-hidden">
          <table className="w-full">
            <thead className="bg-slate-50 dark:bg-slate-800">
              <tr>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                  Job
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider hidden lg:table-cell">
                  Property
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                  Date
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider hidden lg:table-cell">
                  Duration
                </th>
                <th className="px-4 py-3 text-right text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                  Amount
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                  Status
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200 dark:divide-slate-700">
              {history.map((job) => (
                <tr key={job.id} className="hover:bg-slate-50 dark:hover:bg-slate-800/50">
                  <td className="px-4 py-4">
                    <p className="font-medium text-slate-900 dark:text-white">{job.title}</p>
                    <p className="text-sm text-slate-500 dark:text-slate-400 lg:hidden">{job.household.name}</p>
                  </td>
                  <td className="px-4 py-4 text-slate-600 dark:text-slate-300 hidden lg:table-cell">
                    {job.household.name}
                  </td>
                  <td className="px-4 py-4 text-slate-600 dark:text-slate-300">{formatDate(job.scheduledStart)}</td>
                  <td className="px-4 py-4 text-slate-600 dark:text-slate-300 hidden lg:table-cell">
                    {getDuration(job.checkInAt, job.checkOutAt)}
                  </td>
                  <td className="px-4 py-4 text-right font-medium text-slate-900 dark:text-white">
                    {formatCurrency(job.estimatedCost)}
                  </td>
                  <td className="px-4 py-4">
                    <span className={`px-2 py-1 rounded text-xs font-medium ${STATUS_COLORS[job.status]}`}>
                      {job.status === 'COMPLETED' ? 'Pending Review' : 'Verified'}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
