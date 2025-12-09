'use client';

import { useEffect, useState } from 'react';
import { useParams } from 'next/navigation';
import Link from 'next/link';
import { getApiClient } from '@/lib/api';

interface HouseholdDetail {
  id: string;
  name: string;
  description?: string | null;
  subscriptionPlan: string;
  subscriptionStatus: string;
  createdAt: string;
  updatedAt: string;
  owner: {
    id: string;
    email: string;
    firstName: string | null;
    lastName: string | null;
    phone?: string | null;
  };
  members: Array<{
    id: string;
    role: string;
    status: string;
    user: {
      id: string;
      email: string;
      firstName: string | null;
      lastName: string | null;
      phone?: string | null;
    };
  }>;
  homeProfile?: {
    id: string;
    propertyType: string;
    yearBuilt?: number | null;
    squareFootage?: number | null;
    bedrooms?: number | null;
    bathrooms?: number | null;
    addressLine1?: string | null;
    addressLine2?: string | null;
    city?: string | null;
    state?: string | null;
    postalCode?: string | null;
  } | null;
  billAccounts: Array<{
    id: string;
    nickname: string;
    typicalAmount?: number | null;
    nextDueDate?: string | null;
    isActive: boolean;
  }>;
  tasks: Array<{
    id: string;
    name?: string | null;
    status: string;
    dueDate?: string | null;
    category?: {
      name: string;
    } | null;
  }>;
  serviceRequests: Array<{
    id: string;
    title: string;
    status: string;
    createdAt: string;
    category?: {
      name: string;
    } | null;
  }>;
  workOrders: Array<{
    id: string;
    title: string;
    status: string;
    scheduledStart?: string | null;
    vendor?: {
      displayName: string;
    } | null;
  }>;
  conversations: Array<{
    id: string;
    subject?: string | null;
    status: string;
    updatedAt: string;
    assignedTo?: {
      firstName: string | null;
      lastName: string | null;
    } | null;
  }>;
}

type TabType = 'overview' | 'properties' | 'bills' | 'maintenance' | 'work-orders' | 'conversations';

export default function InternalHouseholdDetailPage() {
  const params = useParams();
  const householdId = params.householdId as string;

  const [household, setHousehold] = useState<HouseholdDetail | null>(null);
  const [activeTab, setActiveTab] = useState<TabType>('overview');
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchHousehold = async () => {
      try {
        const api = getApiClient();
        const data = await api.getInternalHousehold(householdId);
        setHousehold(data as unknown as HouseholdDetail);
      } catch (err: any) {
        setError(err.message || 'Failed to load household');
      } finally {
        setIsLoading(false);
      }
    };
    fetchHousehold();
  }, [householdId]);

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
      </div>
    );
  }

  if (error || !household) {
    return (
      <div className="bg-red-50 dark:bg-red-900/20 text-red-600 dark:text-red-400 p-4 rounded-lg">
        {error || 'Household not found'}
      </div>
    );
  }

  const tabs: { id: TabType; label: string; count?: number }[] = [
    { id: 'overview', label: 'Overview' },
    { id: 'properties', label: 'Properties' },
    { id: 'bills', label: 'Bills', count: household.billAccounts.length },
    { id: 'maintenance', label: 'Maintenance', count: household.tasks.length },
    { id: 'work-orders', label: 'Work Orders', count: household.workOrders.length },
    { id: 'conversations', label: 'Conversations', count: household.conversations.length },
  ];

  const getStatusBadge = (status: string) => {
    const styles: Record<string, string> = {
      ACTIVE: 'bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400',
      PENDING: 'bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-400',
      COMPLETED: 'bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-400',
      SCHEDULED: 'bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-400',
      IN_PROGRESS: 'bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-400',
      OPEN: 'bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-400',
      CLOSED: 'bg-slate-100 dark:bg-slate-700 text-slate-700 dark:text-slate-300',
      CANCELLED: 'bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400',
      OVERDUE: 'bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400',
    };
    return styles[status] || 'bg-slate-100 dark:bg-slate-700 text-slate-700 dark:text-slate-300';
  };

  return (
    <div className="space-y-6">
      {/* Breadcrumb */}
      <nav className="flex items-center gap-2 text-sm text-slate-600 dark:text-slate-400">
        <Link href="/internal/households" className="hover:text-indigo-600 dark:hover:text-indigo-400">
          Households
        </Link>
        <span>/</span>
        <span className="text-slate-900 dark:text-white">{household.name}</span>
      </nav>

      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <div className="flex items-center gap-3">
            <h1 className="text-2xl font-bold text-slate-900 dark:text-white">{household.name}</h1>
            <span className={`text-xs px-2 py-0.5 rounded-full ${getStatusBadge(household.subscriptionStatus)}`}>
              {household.subscriptionStatus}
            </span>
          </div>
          <p className="text-slate-600 dark:text-slate-400 mt-1">
            {household.subscriptionPlan} Plan - Member since{' '}
            {new Date(household.createdAt).toLocaleDateString()}
          </p>
        </div>
      </div>

      {/* Tabs */}
      <div className="border-b border-slate-200 dark:border-slate-700">
        <nav className="flex gap-4 overflow-x-auto">
          {tabs.map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`flex items-center gap-2 px-1 py-3 text-sm font-medium border-b-2 transition-colors whitespace-nowrap ${
                activeTab === tab.id
                  ? 'border-indigo-600 text-indigo-600 dark:border-indigo-400 dark:text-indigo-400'
                  : 'border-transparent text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
              }`}
            >
              {tab.label}
              {tab.count !== undefined && (
                <span className="text-xs bg-slate-100 dark:bg-slate-700 px-2 py-0.5 rounded-full">
                  {tab.count}
                </span>
              )}
            </button>
          ))}
        </nav>
      </div>

      {/* Tab Content */}
      <div className="bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 p-5">
        {activeTab === 'overview' && (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* Owner Info */}
            <div>
              <h3 className="text-lg font-semibold text-slate-900 dark:text-white mb-4">Primary Contact</h3>
              <div className="space-y-2">
                <p className="text-slate-900 dark:text-white font-medium">
                  {household.owner.firstName} {household.owner.lastName}
                </p>
                <p className="text-slate-600 dark:text-slate-400">{household.owner.email}</p>
                {household.owner.phone && (
                  <p className="text-slate-600 dark:text-slate-400">{household.owner.phone}</p>
                )}
              </div>
            </div>

            {/* Members */}
            <div>
              <h3 className="text-lg font-semibold text-slate-900 dark:text-white mb-4">
                Members ({household.members.length})
              </h3>
              <div className="space-y-3">
                {household.members.slice(0, 5).map((member) => (
                  <div key={member.id} className="flex items-center justify-between">
                    <div>
                      <p className="text-sm font-medium text-slate-900 dark:text-white">
                        {member.user.firstName} {member.user.lastName}
                      </p>
                      <p className="text-xs text-slate-500 dark:text-slate-400">{member.user.email}</p>
                    </div>
                    <span className="text-xs text-slate-600 dark:text-slate-400">{member.role}</span>
                  </div>
                ))}
              </div>
            </div>

            {/* Property Summary */}
            {household.homeProfile && (
              <div>
                <h3 className="text-lg font-semibold text-slate-900 dark:text-white mb-4">Property</h3>
                <div className="space-y-2 text-sm">
                  <p className="text-slate-900 dark:text-white">
                    {household.homeProfile.propertyType.replace('_', ' ')}
                  </p>
                  {household.homeProfile.addressLine1 && (
                    <p className="text-slate-600 dark:text-slate-400">
                      {household.homeProfile.addressLine1}
                      {household.homeProfile.addressLine2 && `, ${household.homeProfile.addressLine2}`}
                      <br />
                      {household.homeProfile.city}, {household.homeProfile.state}{' '}
                      {household.homeProfile.postalCode}
                    </p>
                  )}
                  <div className="flex gap-4 text-slate-600 dark:text-slate-400">
                    {household.homeProfile.bedrooms && <span>{household.homeProfile.bedrooms} bed</span>}
                    {household.homeProfile.bathrooms && <span>{household.homeProfile.bathrooms} bath</span>}
                    {household.homeProfile.squareFootage && (
                      <span>{household.homeProfile.squareFootage.toLocaleString()} sqft</span>
                    )}
                  </div>
                </div>
              </div>
            )}

            {/* Quick Stats */}
            <div>
              <h3 className="text-lg font-semibold text-slate-900 dark:text-white mb-4">Activity Summary</h3>
              <div className="grid grid-cols-2 gap-4">
                <div className="bg-slate-50 dark:bg-slate-900/50 rounded-lg p-3">
                  <p className="text-2xl font-bold text-slate-900 dark:text-white">
                    {household.billAccounts.filter((b) => b.isActive).length}
                  </p>
                  <p className="text-sm text-slate-600 dark:text-slate-400">Active Bills</p>
                </div>
                <div className="bg-slate-50 dark:bg-slate-900/50 rounded-lg p-3">
                  <p className="text-2xl font-bold text-slate-900 dark:text-white">
                    {household.tasks.filter((t) => t.status === 'PENDING' || t.status === 'SCHEDULED').length}
                  </p>
                  <p className="text-sm text-slate-600 dark:text-slate-400">Pending Tasks</p>
                </div>
                <div className="bg-slate-50 dark:bg-slate-900/50 rounded-lg p-3">
                  <p className="text-2xl font-bold text-slate-900 dark:text-white">
                    {household.workOrders.filter((w) => w.status !== 'COMPLETED' && w.status !== 'CANCELLED').length}
                  </p>
                  <p className="text-sm text-slate-600 dark:text-slate-400">Open Work Orders</p>
                </div>
                <div className="bg-slate-50 dark:bg-slate-900/50 rounded-lg p-3">
                  <p className="text-2xl font-bold text-slate-900 dark:text-white">
                    {household.conversations.filter((c) => c.status !== 'CLOSED').length}
                  </p>
                  <p className="text-sm text-slate-600 dark:text-slate-400">Open Conversations</p>
                </div>
              </div>
            </div>
          </div>
        )}

        {activeTab === 'properties' && (
          <div>
            {household.homeProfile ? (
              <div className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <h4 className="text-sm font-medium text-slate-500 dark:text-slate-400 mb-1">Property Type</h4>
                    <p className="text-slate-900 dark:text-white">
                      {household.homeProfile.propertyType.replace('_', ' ')}
                    </p>
                  </div>
                  <div>
                    <h4 className="text-sm font-medium text-slate-500 dark:text-slate-400 mb-1">Year Built</h4>
                    <p className="text-slate-900 dark:text-white">
                      {household.homeProfile.yearBuilt || 'Not specified'}
                    </p>
                  </div>
                  <div>
                    <h4 className="text-sm font-medium text-slate-500 dark:text-slate-400 mb-1">Address</h4>
                    <p className="text-slate-900 dark:text-white">
                      {household.homeProfile.addressLine1 || 'Not specified'}
                      {household.homeProfile.addressLine2 && <br />}
                      {household.homeProfile.addressLine2}
                      {household.homeProfile.city && (
                        <>
                          <br />
                          {household.homeProfile.city}, {household.homeProfile.state}{' '}
                          {household.homeProfile.postalCode}
                        </>
                      )}
                    </p>
                  </div>
                  <div>
                    <h4 className="text-sm font-medium text-slate-500 dark:text-slate-400 mb-1">Size</h4>
                    <p className="text-slate-900 dark:text-white">
                      {household.homeProfile.squareFootage
                        ? `${household.homeProfile.squareFootage.toLocaleString()} sqft`
                        : 'Not specified'}
                      {household.homeProfile.bedrooms && ` - ${household.homeProfile.bedrooms} bed`}
                      {household.homeProfile.bathrooms && ` / ${household.homeProfile.bathrooms} bath`}
                    </p>
                  </div>
                </div>
              </div>
            ) : (
              <p className="text-slate-500 dark:text-slate-400">No property information on file</p>
            )}
          </div>
        )}

        {activeTab === 'bills' && (
          <div>
            {household.billAccounts.length === 0 ? (
              <p className="text-slate-500 dark:text-slate-400">No bill accounts</p>
            ) : (
              <div className="space-y-3">
                {household.billAccounts.map((bill) => (
                  <div
                    key={bill.id}
                    className="flex items-center justify-between py-3 border-b border-slate-100 dark:border-slate-700 last:border-0"
                  >
                    <div>
                      <p className="font-medium text-slate-900 dark:text-white">{bill.nickname}</p>
                      {bill.nextDueDate && (
                        <p className="text-sm text-slate-500 dark:text-slate-400">
                          Due: {new Date(bill.nextDueDate).toLocaleDateString()}
                        </p>
                      )}
                    </div>
                    <div className="text-right">
                      {bill.typicalAmount && (
                        <p className="font-medium text-slate-900 dark:text-white">
                          ${bill.typicalAmount.toFixed(2)}
                        </p>
                      )}
                      <span
                        className={`text-xs px-2 py-0.5 rounded-full ${
                          bill.isActive
                            ? 'bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400'
                            : 'bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-400'
                        }`}
                      >
                        {bill.isActive ? 'Active' : 'Inactive'}
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {activeTab === 'maintenance' && (
          <div>
            {household.tasks.length === 0 ? (
              <p className="text-slate-500 dark:text-slate-400">No maintenance tasks</p>
            ) : (
              <div className="space-y-3">
                {household.tasks.map((task) => (
                  <div
                    key={task.id}
                    className="flex items-center justify-between py-3 border-b border-slate-100 dark:border-slate-700 last:border-0"
                  >
                    <div>
                      <p className="font-medium text-slate-900 dark:text-white">{task.name}</p>
                      <p className="text-sm text-slate-500 dark:text-slate-400">
                        {task.category?.name || 'General'}
                        {task.dueDate && ` - Due: ${new Date(task.dueDate).toLocaleDateString()}`}
                      </p>
                    </div>
                    <span className={`text-xs px-2 py-0.5 rounded-full ${getStatusBadge(task.status)}`}>
                      {task.status}
                    </span>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {activeTab === 'work-orders' && (
          <div>
            {household.workOrders.length === 0 ? (
              <p className="text-slate-500 dark:text-slate-400">No work orders</p>
            ) : (
              <div className="space-y-3">
                {household.workOrders.map((order) => (
                  <div
                    key={order.id}
                    className="flex items-center justify-between py-3 border-b border-slate-100 dark:border-slate-700 last:border-0"
                  >
                    <div>
                      <p className="font-medium text-slate-900 dark:text-white">{order.title}</p>
                      <p className="text-sm text-slate-500 dark:text-slate-400">
                        {order.vendor?.displayName || 'No vendor assigned'}
                        {order.scheduledStart &&
                          ` - ${new Date(order.scheduledStart).toLocaleDateString()}`}
                      </p>
                    </div>
                    <span className={`text-xs px-2 py-0.5 rounded-full ${getStatusBadge(order.status)}`}>
                      {order.status.replace('_', ' ')}
                    </span>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {activeTab === 'conversations' && (
          <div>
            {household.conversations.length === 0 ? (
              <p className="text-slate-500 dark:text-slate-400">No conversations</p>
            ) : (
              <div className="space-y-3">
                {household.conversations.map((conv) => (
                  <div
                    key={conv.id}
                    className="flex items-center justify-between py-3 border-b border-slate-100 dark:border-slate-700 last:border-0"
                  >
                    <div>
                      <p className="font-medium text-slate-900 dark:text-white">
                        {conv.subject || 'No subject'}
                      </p>
                      <p className="text-sm text-slate-500 dark:text-slate-400">
                        {conv.assignedTo
                          ? `Assigned to ${conv.assignedTo.firstName} ${conv.assignedTo.lastName}`
                          : 'Unassigned'}
                        {' - '}
                        {new Date(conv.updatedAt).toLocaleDateString()}
                      </p>
                    </div>
                    <span className={`text-xs px-2 py-0.5 rounded-full ${getStatusBadge(conv.status)}`}>
                      {conv.status}
                    </span>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
