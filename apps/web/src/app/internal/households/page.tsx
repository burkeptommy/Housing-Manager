'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import type { InternalHousehold } from '@haven/core';
import { getApiClient } from '@/lib/api';

export default function InternalHouseholdsPage() {
  const [households, setHouseholds] = useState<InternalHousehold[]>([]);
  const [filteredHouseholds, setFilteredHouseholds] = useState<InternalHousehold[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');

  useEffect(() => {
    const fetchHouseholds = async () => {
      try {
        const api = getApiClient();
        const data = await api.getInternalHouseholds();
        setHouseholds(data);
        setFilteredHouseholds(data);
      } catch (err: any) {
        setError(err.message || 'Failed to load households');
      } finally {
        setIsLoading(false);
      }
    };
    fetchHouseholds();
  }, []);

  useEffect(() => {
    let filtered = households;

    // Apply search filter
    if (searchTerm) {
      const term = searchTerm.toLowerCase();
      filtered = filtered.filter(
        (h) =>
          h.name.toLowerCase().includes(term) ||
          h.owner.email.toLowerCase().includes(term) ||
          `${h.owner.firstName} ${h.owner.lastName}`.toLowerCase().includes(term)
      );
    }

    // Apply status filter
    if (statusFilter !== 'all') {
      filtered = filtered.filter((h) => h.subscriptionStatus === statusFilter);
    }

    setFilteredHouseholds(filtered);
  }, [searchTerm, statusFilter, households]);

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

  const getStatusBadge = (status: string) => {
    const styles: Record<string, string> = {
      ACTIVE: 'bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400',
      INACTIVE: 'bg-slate-100 dark:bg-slate-700 text-slate-700 dark:text-slate-300',
      PAST_DUE: 'bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400',
      CANCELLED: 'bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400',
      TRIAL: 'bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400',
    };
    return styles[status] || styles.INACTIVE;
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 dark:text-white">Households</h1>
          <p className="text-slate-600 dark:text-slate-400 mt-1">
            {filteredHouseholds.length} household{filteredHouseholds.length !== 1 ? 's' : ''}
          </p>
        </div>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4">
        <div className="relative flex-1">
          <input
            type="text"
            placeholder="Search by name, owner, or email..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-10 pr-4 py-2 border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white placeholder-slate-400"
          />
          <svg
            className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
        </div>
        <select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="px-4 py-2 border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white"
        >
          <option value="all">All Statuses</option>
          <option value="ACTIVE">Active</option>
          <option value="INACTIVE">Inactive</option>
          <option value="TRIAL">Trial</option>
          <option value="PAST_DUE">Past Due</option>
          <option value="CANCELLED">Cancelled</option>
        </select>
      </div>

      {/* Table */}
      <div className="bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-slate-50 dark:bg-slate-900/50">
              <tr>
                <th className="px-5 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                  Household
                </th>
                <th className="px-5 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                  Primary Contact
                </th>
                <th className="px-5 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider hidden md:table-cell">
                  Property
                </th>
                <th className="px-5 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider hidden lg:table-cell">
                  Plan / Status
                </th>
                <th className="px-5 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider hidden lg:table-cell">
                  Activity
                </th>
                <th className="px-5 py-3 text-right text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200 dark:divide-slate-700">
              {filteredHouseholds.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-5 py-8 text-center text-slate-500 dark:text-slate-400">
                    No households found
                  </td>
                </tr>
              ) : (
                filteredHouseholds.map((household) => (
                  <tr key={household.id} className="hover:bg-slate-50 dark:hover:bg-slate-700/50">
                    <td className="px-5 py-4">
                      <div>
                        <p className="font-medium text-slate-900 dark:text-white">{household.name}</p>
                        <p className="text-sm text-slate-500 dark:text-slate-400">
                          {household._count.members} member{household._count.members !== 1 ? 's' : ''}
                        </p>
                      </div>
                    </td>
                    <td className="px-5 py-4">
                      <div>
                        <p className="text-sm font-medium text-slate-900 dark:text-white">
                          {household.owner.firstName} {household.owner.lastName}
                        </p>
                        <p className="text-sm text-slate-500 dark:text-slate-400">{household.owner.email}</p>
                        {household.owner.phone && (
                          <p className="text-sm text-slate-500 dark:text-slate-400">{household.owner.phone}</p>
                        )}
                      </div>
                    </td>
                    <td className="px-5 py-4 hidden md:table-cell">
                      {household.homeProfile ? (
                        <div className="text-sm">
                          <p className="text-slate-900 dark:text-white">
                            {household.homeProfile.propertyType.replace('_', ' ')}
                          </p>
                          {household.homeProfile.addressLine1 && (
                            <p className="text-slate-500 dark:text-slate-400">
                              {household.homeProfile.city}, {household.homeProfile.state}
                            </p>
                          )}
                        </div>
                      ) : (
                        <span className="text-sm text-slate-400 dark:text-slate-500">No property</span>
                      )}
                    </td>
                    <td className="px-5 py-4 hidden lg:table-cell">
                      <div className="flex flex-col gap-1">
                        <span className="text-sm font-medium text-slate-900 dark:text-white">
                          {household.subscriptionPlan}
                        </span>
                        <span
                          className={`inline-flex w-fit text-xs px-2 py-0.5 rounded-full ${getStatusBadge(
                            household.subscriptionStatus
                          )}`}
                        >
                          {household.subscriptionStatus}
                        </span>
                      </div>
                    </td>
                    <td className="px-5 py-4 hidden lg:table-cell">
                      <div className="text-sm text-slate-600 dark:text-slate-400 space-y-1">
                        <p>{household._count.tasks} tasks</p>
                        <p>{household._count.billAccounts} bills</p>
                        <p>{household._count.workOrders} work orders</p>
                      </div>
                    </td>
                    <td className="px-5 py-4 text-right">
                      <Link
                        href={`/internal/households/${household.id}`}
                        className="inline-flex items-center px-3 py-1.5 text-sm font-medium text-indigo-600 dark:text-indigo-400 hover:bg-indigo-50 dark:hover:bg-indigo-900/20 rounded-lg transition-colors"
                      >
                        View
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
    </div>
  );
}
