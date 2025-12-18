'use client';

import { useEffect, useState } from 'react';
import { useSearchParams, useRouter } from 'next/navigation';
import Link from 'next/link';
import type { InternalWorkOrder, WorkOrderStatus } from '@haven/core';
import { getApiClient } from '@/lib/api';

type FilterStatus = WorkOrderStatus | 'all';

export default function InternalWorkOrdersPage() {
  const router = useRouter();
  const searchParams = useSearchParams();

  const [workOrders, setWorkOrders] = useState<InternalWorkOrder[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [activeFilter, setActiveFilter] = useState<FilterStatus>(
    (searchParams.get('status') as FilterStatus) || 'all'
  );
  const [dateFrom, setDateFrom] = useState<string>('');
  const [dateTo, setDateTo] = useState<string>('');

  const fetchWorkOrders = async () => {
    setIsLoading(true);
    try {
      const api = getApiClient();
      const data = await api.getInternalWorkOrdersQueue({
        status: activeFilter,
        dateFrom: dateFrom || undefined,
        dateTo: dateTo || undefined,
      });
      setWorkOrders(data);
      setError(null);
    } catch (err: any) {
      setError(err.message || 'Failed to load work orders');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchWorkOrders();
  }, [activeFilter, dateFrom, dateTo]);

  const handleFilterChange = (filter: FilterStatus) => {
    setActiveFilter(filter);
    const params = new URLSearchParams(searchParams);
    params.set('status', filter);
    router.push(`/internal/work-orders?${params.toString()}`);
  };

  const statusFilters: { id: FilterStatus; label: string }[] = [
    { id: 'all', label: 'All' },
    { id: 'DRAFT', label: 'Draft' },
    { id: 'REQUESTED', label: 'Requested' },
    { id: 'SCHEDULED', label: 'Scheduled' },
    { id: 'IN_PROGRESS', label: 'In Progress' },
    { id: 'COMPLETED', label: 'Completed' },
    { id: 'CANCELLED', label: 'Cancelled' },
  ];

  const getStatusBadge = (status: string) => {
    const styles: Record<string, string> = {
      DRAFT: 'bg-slate-100 dark:bg-slate-700 text-slate-700 dark:text-slate-300',
      REQUESTED: 'bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-400',
      SCHEDULED: 'bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400',
      IN_PROGRESS: 'bg-indigo-100 dark:bg-indigo-900/30 text-indigo-700 dark:text-indigo-400',
      COMPLETED: 'bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400',
      CANCELLED: 'bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400',
    };
    return styles[status] || styles.DRAFT;
  };

  // Upcoming appointments (next 7 days)
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const nextWeek = new Date(today);
  nextWeek.setDate(nextWeek.getDate() + 7);

  const upcomingAppointments = workOrders.filter((order) => {
    if (!order.scheduledStart) return false;
    const scheduled = new Date(order.scheduledStart);
    return scheduled >= today && scheduled < nextWeek && (order.status === 'SCHEDULED' || order.status === 'IN_PROGRESS');
  });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-slate-900 dark:text-white">Work Orders Queue</h1>
        <p className="text-slate-600 dark:text-slate-400 mt-1">
          Manage and schedule work orders for all households
        </p>
      </div>

      {/* Upcoming Appointments Banner */}
      {upcomingAppointments.length > 0 && activeFilter === 'all' && (
        <div className="bg-indigo-50 dark:bg-indigo-900/20 border border-indigo-200 dark:border-indigo-800 rounded-xl p-4">
          <h3 className="text-sm font-semibold text-indigo-700 dark:text-indigo-400 mb-3">
            Upcoming Appointments (Next 7 Days)
          </h3>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
            {upcomingAppointments.slice(0, 6).map((apt) => (
              <div
                key={apt.id}
                className="bg-white dark:bg-slate-800 rounded-lg p-3 border border-indigo-100 dark:border-indigo-800"
              >
                <p className="font-medium text-slate-900 dark:text-white text-sm truncate">{apt.title}</p>
                <p className="text-xs text-slate-500 dark:text-slate-400">{apt.household.name}</p>
                <div className="flex items-center justify-between mt-2">
                  <span className="text-xs text-indigo-600 dark:text-indigo-400">
                    {apt.scheduledStart &&
                      new Date(apt.scheduledStart).toLocaleDateString('en-US', {
                        weekday: 'short',
                        month: 'short',
                        day: 'numeric',
                        hour: 'numeric',
                        minute: '2-digit',
                      })}
                  </span>
                  {apt.vendor && (
                    <span className="text-xs text-slate-500 dark:text-slate-400">{apt.vendor.name}</span>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4">
        <div className="flex flex-wrap gap-2 flex-1">
          {statusFilters.map((filter) => (
            <button
              key={filter.id}
              onClick={() => handleFilterChange(filter.id)}
              className={`px-3 py-1.5 text-sm font-medium rounded-lg transition-colors ${
                activeFilter === filter.id
                  ? 'bg-indigo-600 text-white'
                  : 'bg-white dark:bg-slate-800 text-slate-700 dark:text-slate-300 border border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-700'
              }`}
            >
              {filter.label}
            </button>
          ))}
        </div>

        {/* Date Filters */}
        <div className="flex gap-2 items-center">
          <input
            type="date"
            value={dateFrom}
            onChange={(e) => setDateFrom(e.target.value)}
            className="px-3 py-1.5 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white"
            placeholder="From"
          />
          <span className="text-slate-400">to</span>
          <input
            type="date"
            value={dateTo}
            onChange={(e) => setDateTo(e.target.value)}
            className="px-3 py-1.5 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white"
            placeholder="To"
          />
          {(dateFrom || dateTo) && (
            <button
              onClick={() => {
                setDateFrom('');
                setDateTo('');
              }}
              className="px-2 py-1.5 text-sm text-slate-500 dark:text-slate-400 hover:text-slate-700 dark:hover:text-slate-200"
            >
              Clear
            </button>
          )}
        </div>
      </div>

      {/* Loading */}
      {isLoading && (
        <div className="flex items-center justify-center py-12">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
        </div>
      )}

      {/* Error */}
      {error && (
        <div className="bg-red-50 dark:bg-red-900/20 text-red-600 dark:text-red-400 p-4 rounded-lg">
          {error}
        </div>
      )}

      {/* Work Orders Table */}
      {!isLoading && !error && (
        <div className="bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-slate-50 dark:bg-slate-900/50">
                <tr>
                  <th className="px-5 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                    Work Order
                  </th>
                  <th className="px-5 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                    Household
                  </th>
                  <th className="px-5 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider hidden md:table-cell">
                    Vendor
                  </th>
                  <th className="px-5 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider hidden lg:table-cell">
                    Scheduled
                  </th>
                  <th className="px-5 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                    Status
                  </th>
                  <th className="px-5 py-3 text-right text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-200 dark:divide-slate-700">
                {workOrders.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="px-5 py-12 text-center text-slate-500 dark:text-slate-400">
                      No work orders found
                    </td>
                  </tr>
                ) : (
                  workOrders.map((order) => (
                    <tr key={order.id} className="hover:bg-slate-50 dark:hover:bg-slate-700/50">
                      <td className="px-5 py-4">
                        <div>
                          <p className="font-medium text-slate-900 dark:text-white">{order.title}</p>
                          {order.maintenanceTask && (
                            <p className="text-sm text-slate-500 dark:text-slate-400">
                              Task: {order.maintenanceTask.name}
                            </p>
                          )}
                          <p className="text-xs text-slate-400 dark:text-slate-500">
                            Created {new Date(order.createdAt).toLocaleDateString()}
                          </p>
                        </div>
                      </td>
                      <td className="px-5 py-4">
                        <div>
                          <Link
                            href={`/internal/households/${order.household.id}`}
                            className="text-sm font-medium text-indigo-600 dark:text-indigo-400 hover:underline"
                          >
                            {order.household.name}
                          </Link>
                          {order.household.homeProfile?.addressLine1 && (
                            <p className="text-xs text-slate-500 dark:text-slate-400">
                              {order.household.homeProfile.city}, {order.household.homeProfile.state}
                            </p>
                          )}
                        </div>
                      </td>
                      <td className="px-5 py-4 hidden md:table-cell">
                        {order.vendor ? (
                          <div>
                            <p className="text-sm text-slate-900 dark:text-white">{order.vendor.name}</p>
                            {order.vendor.phone && (
                              <p className="text-xs text-slate-500 dark:text-slate-400">{order.vendor.phone}</p>
                            )}
                          </div>
                        ) : (
                          <span className="text-sm text-amber-600 dark:text-amber-400">Not assigned</span>
                        )}
                      </td>
                      <td className="px-5 py-4 hidden lg:table-cell">
                        {order.scheduledStart ? (
                          <div>
                            <p className="text-sm text-slate-900 dark:text-white">
                              {new Date(order.scheduledStart).toLocaleDateString('en-US', {
                                weekday: 'short',
                                month: 'short',
                                day: 'numeric',
                              })}
                            </p>
                            <p className="text-xs text-slate-500 dark:text-slate-400">
                              {new Date(order.scheduledStart).toLocaleTimeString('en-US', {
                                hour: 'numeric',
                                minute: '2-digit',
                              })}
                              {order.scheduledEnd && (
                                <>
                                  {' - '}
                                  {new Date(order.scheduledEnd).toLocaleTimeString('en-US', {
                                    hour: 'numeric',
                                    minute: '2-digit',
                                  })}
                                </>
                              )}
                            </p>
                          </div>
                        ) : (
                          <span className="text-sm text-slate-400 dark:text-slate-500">Not scheduled</span>
                        )}
                      </td>
                      <td className="px-5 py-4">
                        <span className={`text-xs px-2 py-1 rounded-full ${getStatusBadge(order.status)}`}>
                          {order.status.replace('_', ' ')}
                        </span>
                        {order.estimatedCost && (
                          <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
                            Est: ${order.estimatedCost.toFixed(2)}
                          </p>
                        )}
                      </td>
                      <td className="px-5 py-4 text-right">
                        <Link
                          href={`/manager/work-orders?id=${order.id}`}
                          className="inline-flex items-center px-3 py-1.5 text-sm font-medium text-indigo-600 dark:text-indigo-400 hover:bg-indigo-50 dark:hover:bg-indigo-900/20 rounded-lg transition-colors"
                        >
                          Manage
                          <svg className="ml-1 w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                          </svg>
                        </Link>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}
