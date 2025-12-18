'use client';

import { useState, useEffect, useCallback } from 'react';
import type { RevenueStats, HouseholdRevenue } from '@haven/core';

// Note: In production, use getApiClient() from '@/lib/api' for real API calls

// Simple bar chart component (no external dependencies)
function BarChart({
  data,
}: {
  data: { month: string; pending: number; collected: number }[];
}) {
  if (data.length === 0) {
    return (
      <div className="flex items-center justify-center h-64 text-slate-400">
        No data available
      </div>
    );
  }

  const maxValue = Math.max(...data.flatMap((d) => [d.pending, d.collected]));
  const scale = maxValue > 0 ? 200 / maxValue : 1;

  return (
    <div className="flex items-end justify-between gap-2 h-64 px-4">
      {data.map((item, index) => (
        <div key={index} className="flex-1 flex flex-col items-center gap-2">
          <div className="flex gap-1 items-end h-52">
            {/* Pending bar */}
            <div
              className="w-6 bg-amber-400 dark:bg-amber-500 rounded-t transition-all duration-500"
              style={{ height: `${Math.max(item.pending * scale, 4)}px` }}
              title={`Pending: $${item.pending.toLocaleString()}`}
            />
            {/* Collected bar */}
            <div
              className="w-6 bg-emerald-500 dark:bg-emerald-400 rounded-t transition-all duration-500"
              style={{ height: `${Math.max(item.collected * scale, 4)}px` }}
              title={`Collected: $${item.collected.toLocaleString()}`}
            />
          </div>
          <span className="text-xs text-slate-500 dark:text-slate-400">{item.month}</span>
        </div>
      ))}
    </div>
  );
}

export default function RevenuePage() {
  const [stats, setStats] = useState<RevenueStats | null>(null);
  const [households, setHouseholds] = useState<HouseholdRevenue[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');
  const [collectingId, setCollectingId] = useState<string | null>(null);
  const [collectingAll, setCollectingAll] = useState(false);
  const [successMessage, setSuccessMessage] = useState('');

  const loadData = useCallback(async () => {
    try {
      setIsLoading(true);
      setError('');

      // In production, these would be real API calls
      // For now, we'll use mock data to demonstrate the UI
      const mockStats: RevenueStats = {
        pendingAmount: 3250.0,
        collectedThisMonth: 8750.0,
        collectedAllTime: 52450.0,
        failedAmount: 1450.0,
        pendingInvoices: 3,
        paidInvoicesThisMonth: 7,
        failedInvoices: 1,
        monthlyTrend: [
          { month: 'Aug', pending: 500, collected: 6200, failed: 0 },
          { month: 'Sep', pending: 800, collected: 7500, failed: 0 },
          { month: 'Oct', pending: 1200, collected: 8100, failed: 0 },
          { month: 'Nov', pending: 1450, collected: 8750, failed: 1450 },
          { month: 'Dec', pending: 3250, collected: 0, failed: 0 },
        ],
      };

      const mockHouseholds: HouseholdRevenue[] = [
        {
          householdId: 'h1',
          householdName: "Bob's Villa",
          pendingAmount: 1450.0,
          collectedAmount: 12500.0,
          failedInvoiceId: 'inv-nov-2024',
          lastPaymentDate: '2024-10-03T14:30:00Z',
        },
        {
          householdId: 'h2',
          householdName: 'Johnson Residence',
          pendingAmount: 950.0,
          collectedAmount: 18200.0,
          lastPaymentDate: '2024-11-01T10:15:00Z',
        },
        {
          householdId: 'h3',
          householdName: 'The Williams Estate',
          pendingAmount: 850.0,
          collectedAmount: 21750.0,
          lastPaymentDate: '2024-11-05T16:45:00Z',
        },
      ];

      setStats(mockStats);
      setHouseholds(mockHouseholds);
    } catch (err: unknown) {
      const message =
        err && typeof err === 'object' && 'message' in err
          ? (err as { message: string }).message
          : 'Failed to load revenue data';
      setError(message);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const handleForceCollect = async (invoiceId: string) => {
    try {
      setCollectingId(invoiceId);
      setSuccessMessage('');
      setError('');

      // Simulate API call
      await new Promise((resolve) => setTimeout(resolve, 1500));

      // In production: await api.forceCollectInvoice(invoiceId, true);
      setSuccessMessage(`Payment for invoice ${invoiceId} has been initiated.`);

      // Reload data after successful collection
      await loadData();
    } catch (err: unknown) {
      const message =
        err && typeof err === 'object' && 'message' in err
          ? (err as { message: string }).message
          : 'Failed to collect payment';
      setError(message);
    } finally {
      setCollectingId(null);
    }
  };

  const handleCollectAll = async () => {
    try {
      setCollectingAll(true);
      setSuccessMessage('');
      setError('');

      // Simulate API call
      await new Promise((resolve) => setTimeout(resolve, 2000));

      // In production: await api.collectAllPending();
      setSuccessMessage('Batch collection initiated for all pending invoices.');

      // Reload data
      await loadData();
    } catch (err: unknown) {
      const message =
        err && typeof err === 'object' && 'message' in err
          ? (err as { message: string }).message
          : 'Failed to collect payments';
      setError(message);
    } finally {
      setCollectingAll(false);
    }
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(amount);
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
    });
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-600"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 dark:text-white">Revenue</h1>
          <p className="text-slate-600 dark:text-slate-400">
            Track reimbursements and monthly collections
          </p>
        </div>
        <button
          onClick={handleCollectAll}
          disabled={collectingAll || (stats?.pendingInvoices ?? 0) === 0}
          className="flex items-center gap-2 px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition-colors font-medium disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {collectingAll ? (
            <>
              <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
              Collecting...
            </>
          ) : (
            <>
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
              Collect All ({stats?.pendingInvoices ?? 0})
            </>
          )}
        </button>
      </div>

      {/* Success Message */}
      {successMessage && (
        <div className="p-4 rounded-lg bg-emerald-50 dark:bg-emerald-900/20 border border-emerald-200 dark:border-emerald-800">
          <div className="flex items-center gap-3">
            <svg
              className="w-5 h-5 text-emerald-500"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
              />
            </svg>
            <p className="text-sm text-emerald-600 dark:text-emerald-400">{successMessage}</p>
          </div>
          <button
            onClick={() => setSuccessMessage('')}
            className="mt-2 text-sm text-emerald-700 dark:text-emerald-300 underline"
          >
            Dismiss
          </button>
        </div>
      )}

      {/* Error */}
      {error && (
        <div className="p-4 rounded-lg bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800">
          <p className="text-sm text-red-600 dark:text-red-400">{error}</p>
          <button
            onClick={() => setError('')}
            className="mt-2 text-sm text-red-700 dark:text-red-300 underline"
          >
            Dismiss
          </button>
        </div>
      )}

      {/* Stats Cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="card">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-lg bg-amber-100 dark:bg-amber-900/30 flex items-center justify-center">
              <svg
                className="w-6 h-6 text-amber-600 dark:text-amber-400"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900 dark:text-white">
                {formatCurrency(stats?.pendingAmount ?? 0)}
              </p>
              <p className="text-sm text-slate-500 dark:text-slate-400">Pending</p>
            </div>
          </div>
        </div>
        <div className="card">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-lg bg-emerald-100 dark:bg-emerald-900/30 flex items-center justify-center">
              <svg
                className="w-6 h-6 text-emerald-600 dark:text-emerald-400"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900 dark:text-white">
                {formatCurrency(stats?.collectedThisMonth ?? 0)}
              </p>
              <p className="text-sm text-slate-500 dark:text-slate-400">Collected (Month)</p>
            </div>
          </div>
        </div>
        <div className="card">
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
                  d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900 dark:text-white">
                {formatCurrency(stats?.collectedAllTime ?? 0)}
              </p>
              <p className="text-sm text-slate-500 dark:text-slate-400">All-Time</p>
            </div>
          </div>
        </div>
        <div className="card">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-lg bg-red-100 dark:bg-red-900/30 flex items-center justify-center">
              <svg
                className="w-6 h-6 text-red-600 dark:text-red-400"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                />
              </svg>
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900 dark:text-white">
                {formatCurrency(stats?.failedAmount ?? 0)}
              </p>
              <p className="text-sm text-slate-500 dark:text-slate-400">Failed</p>
            </div>
          </div>
        </div>
      </div>

      {/* Chart */}
      <div className="card">
        <div className="px-6 py-4 border-b border-slate-200 dark:border-slate-700">
          <h2 className="text-lg font-semibold text-slate-900 dark:text-white">
            Monthly Reimbursements
          </h2>
          <p className="text-sm text-slate-500 dark:text-slate-400">
            Pending vs. Collected by month
          </p>
        </div>
        <div className="p-6">
          <div className="flex justify-center gap-6 mb-4">
            <div className="flex items-center gap-2">
              <div className="w-4 h-4 bg-amber-400 dark:bg-amber-500 rounded"></div>
              <span className="text-sm text-slate-600 dark:text-slate-400">Pending</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-4 h-4 bg-emerald-500 dark:bg-emerald-400 rounded"></div>
              <span className="text-sm text-slate-600 dark:text-slate-400">Collected</span>
            </div>
          </div>
          <BarChart data={stats?.monthlyTrend ?? []} />
        </div>
      </div>

      {/* Households Table */}
      <div className="card overflow-hidden">
        <div className="px-6 py-4 border-b border-slate-200 dark:border-slate-700">
          <h2 className="text-lg font-semibold text-slate-900 dark:text-white">
            Revenue by Household
          </h2>
        </div>

        {households.length === 0 ? (
          <div className="p-12 text-center">
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
                d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"
              />
            </svg>
            <h3 className="text-lg font-medium text-slate-900 dark:text-white mb-2">
              No households yet
            </h3>
            <p className="text-slate-600 dark:text-slate-400">
              Revenue data will appear here once you have active households.
            </p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-slate-50 dark:bg-slate-800">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                    Household
                  </th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                    Pending
                  </th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                    Collected
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                    Last Payment
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                    Status
                  </th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-200 dark:divide-slate-700">
                {households.map((household) => (
                  <tr
                    key={household.householdId}
                    className="hover:bg-slate-50 dark:hover:bg-slate-800/50"
                  >
                    <td className="px-6 py-4">
                      <p className="font-medium text-slate-900 dark:text-white">
                        {household.householdName}
                      </p>
                    </td>
                    <td className="px-6 py-4 text-right">
                      <span
                        className={`font-medium ${
                          household.pendingAmount > 0
                            ? 'text-amber-600 dark:text-amber-400'
                            : 'text-slate-500 dark:text-slate-400'
                        }`}
                      >
                        {formatCurrency(household.pendingAmount)}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-right font-medium text-emerald-600 dark:text-emerald-400">
                      {formatCurrency(household.collectedAmount)}
                    </td>
                    <td className="px-6 py-4 text-slate-600 dark:text-slate-300">
                      {household.lastPaymentDate ? formatDate(household.lastPaymentDate) : '-'}
                    </td>
                    <td className="px-6 py-4">
                      {household.failedInvoiceId ? (
                        <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400">
                          <svg
                            className="w-3 h-3"
                            fill="none"
                            stroke="currentColor"
                            viewBox="0 0 24 24"
                          >
                            <path
                              strokeLinecap="round"
                              strokeLinejoin="round"
                              strokeWidth={2}
                              d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                            />
                          </svg>
                          Past Due
                        </span>
                      ) : household.pendingAmount > 0 ? (
                        <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-400">
                          <svg
                            className="w-3 h-3"
                            fill="none"
                            stroke="currentColor"
                            viewBox="0 0 24 24"
                          >
                            <path
                              strokeLinecap="round"
                              strokeLinejoin="round"
                              strokeWidth={2}
                              d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                            />
                          </svg>
                          Pending
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400">
                          <svg
                            className="w-3 h-3"
                            fill="none"
                            stroke="currentColor"
                            viewBox="0 0 24 24"
                          >
                            <path
                              strokeLinecap="round"
                              strokeLinejoin="round"
                              strokeWidth={2}
                              d="M5 13l4 4L19 7"
                            />
                          </svg>
                          Current
                        </span>
                      )}
                    </td>
                    <td className="px-6 py-4 text-right">
                      {household.failedInvoiceId && (
                        <button
                          onClick={() => handleForceCollect(household.failedInvoiceId!)}
                          disabled={collectingId === household.failedInvoiceId}
                          className="inline-flex items-center gap-1 px-3 py-1.5 text-sm font-medium text-white bg-red-600 hover:bg-red-700 rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                        >
                          {collectingId === household.failedInvoiceId ? (
                            <>
                              <div className="w-3 h-3 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                              Collecting...
                            </>
                          ) : (
                            <>
                              <svg
                                className="w-4 h-4"
                                fill="none"
                                stroke="currentColor"
                                viewBox="0 0 24 24"
                              >
                                <path
                                  strokeLinecap="round"
                                  strokeLinejoin="round"
                                  strokeWidth={2}
                                  d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
                                />
                              </svg>
                              Force Collect
                            </>
                          )}
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
