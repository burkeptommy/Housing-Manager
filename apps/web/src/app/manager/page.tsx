'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';
import Link from 'next/link';
import { useAuth } from '@/contexts/auth-context';
import { getApiClient } from '@/lib/api';
import type { ServiceRequestDetail, Household } from '@haven/core';
import {
  ClipboardList,
  Plus,
  Zap,
  AlertTriangle,
  Users,
  Home,
  MessageCircle,
  Calendar,
  Wallet,
  Wrench,
  ChevronRight,
  Clock,
  CheckCircle2,
  Loader2,
  AlertCircle,
  Inbox,
} from 'lucide-react';

// ============================================================================
// MANAGER DASHBOARD PAGE
// Primary Color: Indigo (vs Emerald for homeowners)
// Target: Information-dense, power-user focused
// ============================================================================

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
  const stats = useMemo(() => ({
    total: requests.length,
    new: requests.filter((r) => r.status === 'SUBMITTED').length,
    assigned: requests.filter((r) => r.status === 'ASSIGNED').length,
    inProgress: requests.filter((r) => r.status === 'IN_PROGRESS').length,
    urgent: requests.filter((r) => r.priority === 'URGENT' && r.status !== 'COMPLETED').length,
    households: households.length,
  }), [requests, households]);

  // Get urgent requests
  const urgentRequests = useMemo(() =>
    requests
      .filter((r) => r.priority === 'URGENT' && r.status !== 'COMPLETED')
      .slice(0, 5),
    [requests]
  );

  // Get recent requests
  const recentRequests = useMemo(() =>
    [...requests]
      .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
      .slice(0, 5),
    [requests]
  );

  // Get today's schedule (mock for now)
  const todaysSchedule = useMemo(() => [
    { id: '1', time: '9:00 AM', title: 'HVAC Inspection', household: 'Smith Family', type: 'maintenance' as const },
    { id: '2', time: '11:30 AM', title: 'Plumber Visit', household: 'Johnson Residence', type: 'repair' as const },
    { id: '3', time: '2:00 PM', title: 'Landscaper Check-in', household: 'Garcia Home', type: 'service' as const },
  ], []);

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="flex flex-col items-center gap-3">
          <Loader2 className="w-8 h-8 animate-spin text-indigo-600" />
          <p className="text-slate-500">Loading dashboard...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6 pb-20">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">
            Good {getTimeOfDay()}, {user?.firstName}
          </h1>
          <p className="text-slate-600 mt-1">
            {stats.households} households • {stats.total} active requests
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Link
            href="/manager/requests/new"
            className="flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white font-medium rounded-lg hover:bg-indigo-700 transition-colors"
          >
            <Plus className="w-4 h-4" />
            New Request
          </Link>
        </div>
      </div>

      {/* Error */}
      {error && (
        <div className="p-4 rounded-xl bg-red-50 border border-red-200 flex items-start gap-3">
          <AlertCircle className="w-5 h-5 text-red-600 flex-shrink-0 mt-0.5" />
          <p className="text-sm text-red-600">{error}</p>
        </div>
      )}

      {/* Stats Row */}
      <div className="grid grid-cols-2 lg:grid-cols-5 gap-4">
        <StatCard
          title="Total Requests"
          value={stats.total}
          icon={ClipboardList}
          color="indigo"
        />
        <StatCard
          title="New"
          value={stats.new}
          icon={Plus}
          color="blue"
        />
        <StatCard
          title="In Progress"
          value={stats.inProgress}
          icon={Zap}
          color="amber"
        />
        <StatCard
          title="Urgent"
          value={stats.urgent}
          icon={AlertTriangle}
          color="red"
          urgent={stats.urgent > 0}
        />
        <StatCard
          title="Households"
          value={stats.households}
          icon={Users}
          color="emerald"
        />
      </div>

      {/* Urgent Section */}
      {urgentRequests.length > 0 && (
        <div className="bg-red-50 rounded-xl border border-red-200 p-4">
          <div className="flex items-center gap-2 mb-4">
            <span className="w-2 h-2 rounded-full bg-red-500 animate-pulse" />
            <h2 className="font-semibold text-red-900">Urgent Attention Required</h2>
            <span className="px-2 py-0.5 text-xs font-medium rounded-full bg-red-100 text-red-700">
              {urgentRequests.length}
            </span>
          </div>
          <div className="space-y-2">
            {urgentRequests.map((request) => (
              <UrgentRequestItem key={request.id} request={request} />
            ))}
          </div>
        </div>
      )}

      {/* Two Column Layout: Schedule + Tasks */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Today's Schedule */}
        <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
          <div className="px-4 py-3 border-b border-slate-100 bg-slate-50 flex items-center justify-between">
            <h3 className="font-semibold text-slate-900 flex items-center gap-2">
              <Calendar className="w-4 h-4 text-indigo-600" />
              Today&apos;s Schedule
            </h3>
            <Link href="/manager/schedule" className="text-sm text-indigo-600 hover:text-indigo-700 font-medium">
              View all
            </Link>
          </div>
          <div className="divide-y divide-slate-100">
            {todaysSchedule.length > 0 ? (
              todaysSchedule.map((item) => (
                <ScheduleItem key={item.id} item={item} />
              ))
            ) : (
              <div className="text-center py-12">
                <div className="w-12 h-12 bg-slate-100 rounded-full flex items-center justify-center mx-auto mb-4">
                  <Calendar className="w-6 h-6 text-slate-400" />
                </div>
                <p className="text-slate-500">No appointments today</p>
              </div>
            )}
          </div>
        </div>

        {/* Recent Requests */}
        <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
          <div className="px-4 py-3 border-b border-slate-100 bg-slate-50 flex items-center justify-between">
            <h3 className="font-semibold text-slate-900 flex items-center gap-2">
              <Inbox className="w-4 h-4 text-indigo-600" />
              Recent Requests
            </h3>
            <Link href="/manager/requests" className="text-sm text-indigo-600 hover:text-indigo-700 font-medium">
              View all
            </Link>
          </div>
          <div className="divide-y divide-slate-100">
            {recentRequests.length > 0 ? (
              recentRequests.map((request) => (
                <RequestListItem key={request.id} request={request} />
              ))
            ) : (
              <div className="text-center py-12">
                <div className="w-12 h-12 bg-slate-100 rounded-full flex items-center justify-center mx-auto mb-4">
                  <Inbox className="w-6 h-6 text-slate-400" />
                </div>
                <p className="text-slate-500">No requests yet</p>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Managed Households */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
        <div className="px-4 py-3 border-b border-slate-100 bg-slate-50 flex items-center justify-between">
          <h3 className="font-semibold text-slate-900 flex items-center gap-2">
            <Users className="w-4 h-4 text-indigo-600" />
            Managed Households
          </h3>
          <span className="text-sm text-slate-500">{households.length} properties</span>
        </div>
        {households.length > 0 ? (
          <div className="p-4 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {households.map((household) => (
              <HouseholdCard key={household.id} household={household} requests={requests} />
            ))}
          </div>
        ) : (
          <div className="text-center py-12">
            <div className="w-12 h-12 bg-slate-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <Home className="w-6 h-6 text-slate-400" />
            </div>
            <h3 className="text-lg font-medium text-slate-900">No households yet</h3>
            <p className="text-slate-500 mt-1">Households will appear here when assigned to you.</p>
          </div>
        )}
      </div>

      {/* Quick Actions */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
        <div className="px-4 py-3 border-b border-slate-100 bg-slate-50">
          <h3 className="font-semibold text-slate-900">Quick Actions</h3>
        </div>
        <div className="p-4 grid grid-cols-2 md:grid-cols-4 gap-3">
          <QuickActionButton
            href="/manager/requests"
            icon={ClipboardList}
            label="Kanban Board"
            color="indigo"
          />
          <QuickActionButton
            href="/manager/conversations"
            icon={MessageCircle}
            label="Conversations"
            color="purple"
          />
          <QuickActionButton
            href="/manager/payables"
            icon={Wallet}
            label="Pay Bills"
            color="emerald"
          />
          <QuickActionButton
            href="/manager/vendors"
            icon={Wrench}
            label="Vendors"
            color="amber"
          />
        </div>
      </div>
    </div>
  );
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

function getTimeOfDay(): string {
  const hour = new Date().getHours();
  if (hour < 12) return 'morning';
  if (hour < 17) return 'afternoon';
  return 'evening';
}

// ============================================================================
// COMPONENTS
// ============================================================================

function StatCard({
  title,
  value,
  icon: Icon,
  color,
  urgent = false,
}: {
  title: string;
  value: number;
  icon: React.ElementType;
  color: 'indigo' | 'blue' | 'amber' | 'red' | 'emerald';
  urgent?: boolean;
}) {
  const colorClasses = {
    indigo: 'bg-indigo-100 text-indigo-600',
    blue: 'bg-blue-100 text-blue-600',
    amber: 'bg-amber-100 text-amber-600',
    red: 'bg-red-100 text-red-600',
    emerald: 'bg-emerald-100 text-emerald-600',
  };

  return (
    <div className={`bg-white rounded-xl shadow-sm border ${urgent ? 'border-red-200' : 'border-slate-200'} p-4`}>
      <div className="flex items-center gap-3">
        <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${colorClasses[color]}`}>
          <Icon className="w-5 h-5" />
        </div>
        <div>
          <p className="text-2xl font-bold text-slate-900">{value}</p>
          <p className="text-xs text-slate-500">{title}</p>
        </div>
      </div>
    </div>
  );
}

function UrgentRequestItem({ request }: { request: ServiceRequestDetail }) {
  return (
    <Link
      href={`/manager/requests/${request.id}`}
      className="flex items-center justify-between p-3 bg-white rounded-lg border border-red-200 hover:border-red-300 transition-colors"
    >
      <div className="flex items-center gap-3 min-w-0">
        <AlertTriangle className="w-5 h-5 text-red-500 flex-shrink-0" />
        <div className="min-w-0">
          <p className="font-medium text-slate-900 truncate">{request.title}</p>
          <p className="text-sm text-slate-500 truncate">{request.household?.name}</p>
        </div>
      </div>
      <div className="flex items-center gap-2 ml-4">
        <span className="text-xs font-medium px-2 py-0.5 rounded-full bg-red-100 text-red-700">
          {request.status.replace('_', ' ')}
        </span>
        <ChevronRight className="w-4 h-4 text-slate-400" />
      </div>
    </Link>
  );
}

function ScheduleItem({ item }: { item: { id: string; time: string; title: string; household: string; type: 'maintenance' | 'repair' | 'service' } }) {
  const typeColors = {
    maintenance: 'bg-blue-100 text-blue-700',
    repair: 'bg-amber-100 text-amber-700',
    service: 'bg-emerald-100 text-emerald-700',
  };

  return (
    <div className="flex items-center justify-between p-4 hover:bg-slate-50 transition-colors">
      <div className="flex items-center gap-4">
        <div className="text-center min-w-[60px]">
          <p className="text-sm font-medium text-slate-900">{item.time}</p>
        </div>
        <div>
          <p className="font-medium text-slate-900">{item.title}</p>
          <p className="text-sm text-slate-500">{item.household}</p>
        </div>
      </div>
      <span className={`text-xs font-medium px-2 py-0.5 rounded-full ${typeColors[item.type]}`}>
        {item.type}
      </span>
    </div>
  );
}

function RequestListItem({ request }: { request: ServiceRequestDetail }) {
  const statusColors: Record<string, string> = {
    SUBMITTED: 'bg-blue-100 text-blue-700',
    ASSIGNED: 'bg-purple-100 text-purple-700',
    IN_PROGRESS: 'bg-amber-100 text-amber-700',
    COMPLETED: 'bg-emerald-100 text-emerald-700',
    CANCELLED: 'bg-slate-100 text-slate-600',
  };

  const priorityColors: Record<string, string> = {
    LOW: 'text-slate-500',
    MEDIUM: 'text-blue-600',
    HIGH: 'text-amber-600',
    URGENT: 'text-red-600',
  };

  return (
    <Link
      href={`/manager/requests/${request.id}`}
      className="flex items-center justify-between p-4 hover:bg-slate-50 transition-colors"
    >
      <div className="flex items-center gap-3 min-w-0">
        <div className={`w-2 h-2 rounded-full ${request.priority === 'URGENT' ? 'bg-red-500' : request.priority === 'HIGH' ? 'bg-amber-500' : 'bg-slate-300'}`} />
        <div className="min-w-0">
          <p className="font-medium text-slate-900 truncate">{request.title}</p>
          <p className="text-sm text-slate-500 truncate">{request.household?.name}</p>
        </div>
      </div>
      <div className="flex items-center gap-2 ml-4">
        <span className={`text-xs font-medium px-2 py-0.5 rounded-full ${statusColors[request.status] || 'bg-slate-100 text-slate-600'}`}>
          {request.status.replace('_', ' ')}
        </span>
        <ChevronRight className="w-4 h-4 text-slate-400" />
      </div>
    </Link>
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
  const urgentCount = householdRequests.filter((r) => r.priority === 'URGENT' && r.status !== 'COMPLETED').length;

  // Determine status indicator
  const statusColor = urgentCount > 0 ? 'bg-red-500' : activeRequests.length > 0 ? 'bg-amber-500' : 'bg-emerald-500';

  return (
    <Link
      href={`/manager/households/${household.id}`}
      className="p-4 rounded-xl border border-slate-200 hover:border-indigo-200 hover:shadow-md transition-all bg-white"
    >
      <div className="flex items-start justify-between mb-3">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-lg bg-indigo-100 flex items-center justify-center">
            <Home className="w-5 h-5 text-indigo-600" />
          </div>
          <div className={`w-2 h-2 rounded-full ${statusColor}`} />
        </div>
        {activeRequests.length > 0 && (
          <span className="text-xs font-medium px-2 py-0.5 rounded-full bg-indigo-100 text-indigo-700">
            {activeRequests.length} active
          </span>
        )}
      </div>
      <h3 className="font-medium text-slate-900 mb-1">{household.name}</h3>
      <div className="flex items-center gap-3 text-sm text-slate-500">
        <span>{householdRequests.length} requests</span>
        {urgentCount > 0 && (
          <span className="text-red-600 font-medium">{urgentCount} urgent</span>
        )}
      </div>
    </Link>
  );
}

function QuickActionButton({
  href,
  icon: Icon,
  label,
  color,
}: {
  href: string;
  icon: React.ElementType;
  label: string;
  color: 'indigo' | 'purple' | 'emerald' | 'amber';
}) {
  const colorClasses = {
    indigo: 'bg-indigo-100 text-indigo-600',
    purple: 'bg-purple-100 text-purple-600',
    emerald: 'bg-emerald-100 text-emerald-600',
    amber: 'bg-amber-100 text-amber-600',
  };

  return (
    <Link
      href={href}
      className="flex items-center gap-3 p-3 rounded-lg border border-slate-200 hover:bg-slate-50 hover:border-indigo-200 transition-all"
    >
      <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${colorClasses[color]}`}>
        <Icon className="w-5 h-5" />
      </div>
      <span className="font-medium text-slate-900 text-sm">{label}</span>
    </Link>
  );
}
