'use client';

import { useState, useEffect, useCallback } from 'react';
import Link from 'next/link';
import { useAuth } from '@/contexts/auth-context';
import { getApiClient } from '@/lib/api';
import type { ServiceRequestDetail, Household } from '@haven/core';

export default function ManagerDashboardPage() {
  const { user } = useAuth();
  const [requests, setRequests] = useState<ServiceRequestDetail[]>([]);
  const [households, setHouseholds] = useState<Household[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');

  const api = getApiClient();

  const loadData = useCallback(async () => {
    try {
      const [requestsData, householdsData] = await Promise.all([
        api.getManagerRequests(),
        api.getHouseholds(),
      ]);
      setRequests(requestsData);
      // Filter to only show households where user is manager
      setHouseholds(householdsData);
    } catch (err: unknown) {
      const message =
        err && typeof err === 'object' && 'message' in err
          ? (err as { message: string }).message
          : 'Failed to load data';
      setError(message);
    } finally {
      setIsLoading(false);
    }
  }, [api]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  // Calculate stats
  const stats = {
    total: requests.length,
    new: requests.filter((r) => r.status === 'SUBMITTED').length,
    assigned: requests.filter((r) => r.status === 'ASSIGNED').length,
    inProgress: requests.filter((r) => r.status === 'IN_PROGRESS').length,
    urgent: requests.filter((r) => r.priority === 'URGENT').length,
    households: households.length,
  };

  // Get recent requests
  const recentRequests = [...requests]
    .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
    .slice(0, 5);

  // Get urgent requests
  const urgentRequests = requests
    .filter((r) => r.priority === 'URGENT' && r.status !== 'COMPLETED')
    .slice(0, 3);

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
      <div>
        <h1 className="text-2xl font-bold text-slate-900 dark:text-white">
          Welcome back, {user?.firstName}!
        </h1>
        <p className="text-slate-600 dark:text-slate-400">
          Here&apos;s an overview of your managed properties
        </p>
      </div>

      {/* Error */}
      {error && (
        <div className="p-4 rounded-lg bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800">
          <p className="text-sm text-red-600 dark:text-red-400">{error}</p>
        </div>
      )}

      {/* Stats Grid */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard
          title="Total Requests"
          value={stats.total}
          icon={
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
            </svg>
          }
          color="blue"
        />
        <StatCard
          title="New Requests"
          value={stats.new}
          icon={
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
            </svg>
          }
          color="emerald"
        />
        <StatCard
          title="In Progress"
          value={stats.inProgress}
          icon={
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
            </svg>
          }
          color="yellow"
        />
        <StatCard
          title="Urgent"
          value={stats.urgent}
          icon={
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
            </svg>
          }
          color="red"
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Urgent Requests */}
        {urgentRequests.length > 0 && (
          <div className="card">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold text-slate-900 dark:text-white flex items-center gap-2">
                <span className="w-2 h-2 rounded-full bg-red-500 animate-pulse"></span>
                Urgent Requests
              </h2>
            </div>
            <div className="space-y-3">
              {urgentRequests.map((request) => (
                <RequestListItem key={request.id} request={request} />
              ))}
            </div>
          </div>
        )}

        {/* Recent Requests */}
        <div className="card">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Recent Requests</h2>
            <Link
              href="/manager/requests"
              className="text-sm text-emerald-600 hover:text-emerald-700 dark:text-emerald-400 font-medium"
            >
              View all
            </Link>
          </div>
          {recentRequests.length > 0 ? (
            <div className="space-y-3">
              {recentRequests.map((request) => (
                <RequestListItem key={request.id} request={request} />
              ))}
            </div>
          ) : (
            <p className="text-slate-500 dark:text-slate-400 text-center py-8">
              No service requests yet
            </p>
          )}
        </div>

        {/* Managed Households */}
        <div className="card lg:col-span-2">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Managed Households</h2>
            <span className="text-sm text-slate-500 dark:text-slate-400">
              {households.length} properties
            </span>
          </div>
          {households.length > 0 ? (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {households.map((household) => (
                <HouseholdCard key={household.id} household={household} requests={requests} />
              ))}
            </div>
          ) : (
            <p className="text-slate-500 dark:text-slate-400 text-center py-8">
              No households assigned yet
            </p>
          )}
        </div>
      </div>

      {/* Quick Actions */}
      <div className="card">
        <h2 className="text-lg font-semibold text-slate-900 dark:text-white mb-4">Quick Actions</h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <Link
            href="/manager/requests"
            className="flex items-center gap-3 p-4 rounded-lg border border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors"
          >
            <div className="w-10 h-10 rounded-lg bg-emerald-100 dark:bg-emerald-900/30 flex items-center justify-center">
              <svg className="w-5 h-5 text-emerald-600 dark:text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 10h16M4 14h16M4 18h16" />
              </svg>
            </div>
            <span className="font-medium text-slate-900 dark:text-white">View Kanban</span>
          </Link>
          <Link
            href="/manager/work-orders"
            className="flex items-center gap-3 p-4 rounded-lg border border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors"
          >
            <div className="w-10 h-10 rounded-lg bg-orange-100 dark:bg-orange-900/30 flex items-center justify-center">
              <svg className="w-5 h-5 text-orange-600 dark:text-orange-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />
              </svg>
            </div>
            <span className="font-medium text-slate-900 dark:text-white">Work Orders</span>
          </Link>
          <Link
            href="/manager/conversations"
            className="flex items-center gap-3 p-4 rounded-lg border border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors"
          >
            <div className="w-10 h-10 rounded-lg bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center">
              <svg className="w-5 h-5 text-purple-600 dark:text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
              </svg>
            </div>
            <span className="font-medium text-slate-900 dark:text-white">Conversations</span>
          </Link>
          <Link
            href="/manager/households"
            className="flex items-center gap-3 p-4 rounded-lg border border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors"
          >
            <div className="w-10 h-10 rounded-lg bg-emerald-100 dark:bg-emerald-900/30 flex items-center justify-center">
              <svg className="w-5 h-5 text-emerald-600 dark:text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
              </svg>
            </div>
            <span className="font-medium text-slate-900 dark:text-white">Households</span>
          </Link>
        </div>
      </div>
    </div>
  );
}

function StatCard({
  title,
  value,
  icon,
  color,
}: {
  title: string;
  value: number;
  icon: React.ReactNode;
  color: 'blue' | 'emerald' | 'yellow' | 'red';
}) {
  const colorClasses = {
    blue: 'bg-emerald-100 text-emerald-600 dark:bg-emerald-900/30 dark:text-emerald-400',
    emerald: 'bg-emerald-100 text-emerald-600 dark:bg-emerald-900/30 dark:text-emerald-400',
    yellow: 'bg-yellow-100 text-yellow-600 dark:bg-yellow-900/30 dark:text-yellow-400',
    red: 'bg-red-100 text-red-600 dark:bg-red-900/30 dark:text-red-400',
  };

  return (
    <div className="card">
      <div className="flex items-center gap-4">
        <div className={`w-12 h-12 rounded-lg flex items-center justify-center ${colorClasses[color]}`}>
          {icon}
        </div>
        <div>
          <p className="text-2xl font-bold text-slate-900 dark:text-white">{value}</p>
          <p className="text-sm text-slate-500 dark:text-slate-400">{title}</p>
        </div>
      </div>
    </div>
  );
}

function RequestListItem({ request }: { request: ServiceRequestDetail }) {
  const priorityColors: Record<string, string> = {
    LOW: 'bg-slate-100 text-slate-600 dark:bg-slate-700 dark:text-slate-400',
    MEDIUM: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400',
    HIGH: 'bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400',
    URGENT: 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400',
  };

  const statusColors: Record<string, string> = {
    SUBMITTED: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400',
    ASSIGNED: 'bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-400',
    IN_PROGRESS: 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400',
    COMPLETED: 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400',
    CANCELLED: 'bg-slate-100 text-slate-700 dark:bg-slate-700 dark:text-slate-400',
  };

  return (
    <div className="flex items-center justify-between p-3 rounded-lg bg-slate-50 dark:bg-slate-800/50">
      <div className="min-w-0 flex-1">
        <p className="font-medium text-slate-900 dark:text-white truncate">{request.title}</p>
        <p className="text-sm text-slate-500 dark:text-slate-400">{request.household?.name}</p>
      </div>
      <div className="flex items-center gap-2 ml-4">
        <span className={`text-xs font-medium px-2 py-0.5 rounded ${priorityColors[request.priority]}`}>
          {request.priority}
        </span>
        <span className={`text-xs font-medium px-2 py-0.5 rounded ${statusColors[request.status]}`}>
          {request.status.replace('_', ' ')}
        </span>
      </div>
    </div>
  );
}

function HouseholdCard({
  household,
  requests,
}: {
  household: Household;
  requests: ServiceRequestDetail[];
}) {
  const householdRequests = requests.filter((r) => r.householdId === household.id);
  const activeRequests = householdRequests.filter((r) => r.status !== 'COMPLETED' && r.status !== 'CANCELLED');

  return (
    <div className="p-4 rounded-lg border border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
      <div className="flex items-start justify-between mb-3">
        <div className="w-10 h-10 rounded-lg bg-slate-100 dark:bg-slate-700 flex items-center justify-center">
          <svg className="w-5 h-5 text-slate-600 dark:text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
          </svg>
        </div>
        {activeRequests.length > 0 && (
          <span className="text-xs font-medium px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400">
            {activeRequests.length} active
          </span>
        )}
      </div>
      <h3 className="font-medium text-slate-900 dark:text-white mb-1">{household.name}</h3>
      <p className="text-sm text-slate-500 dark:text-slate-400">
        {householdRequests.length} total requests
      </p>
    </div>
  );
}
