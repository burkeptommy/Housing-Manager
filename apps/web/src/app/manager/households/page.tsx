'use client';

import { useState, useEffect, useCallback } from 'react';
import { getApiClient } from '@/lib/api';
import type { Household, ServiceRequestDetail, HomeProfile } from '@haven/core';

interface HouseholdWithDetails extends Household {
  homeProfile?: HomeProfile | null;
  requestCount?: number;
  activeRequestCount?: number;
}

export default function ManagerHouseholdsPage() {
  const [households, setHouseholds] = useState<HouseholdWithDetails[]>([]);
  const [requests, setRequests] = useState<ServiceRequestDetail[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');
  const [selectedHousehold, setSelectedHousehold] = useState<HouseholdWithDetails | null>(null);

  const api = getApiClient();

  const loadData = useCallback(async () => {
    try {
      const [householdsData, requestsData] = await Promise.all([
        api.getHouseholds(),
        api.getManagerRequests(),
      ]);

      setRequests(requestsData);

      // Load home profiles for each household
      const householdsWithDetails: HouseholdWithDetails[] = await Promise.all(
        householdsData.map(async (h) => {
          try {
            const detail = await api.getHousehold(h.id);
            const houseRequests = requestsData.filter((r) => r.householdId === h.id);
            return {
              ...h,
              homeProfile: detail.homeProfile,
              requestCount: houseRequests.length,
              activeRequestCount: houseRequests.filter(
                (r) => r.status !== 'COMPLETED' && r.status !== 'CANCELLED'
              ).length,
            };
          } catch {
            return {
              ...h,
              requestCount: requestsData.filter((r) => r.householdId === h.id).length,
              activeRequestCount: requestsData.filter(
                (r) => r.householdId === h.id && r.status !== 'COMPLETED' && r.status !== 'CANCELLED'
              ).length,
            };
          }
        })
      );

      setHouseholds(householdsWithDetails);
    } catch (err: unknown) {
      const message =
        err && typeof err === 'object' && 'message' in err
          ? (err as { message: string }).message
          : 'Failed to load households';
      setError(message);
    } finally {
      setIsLoading(false);
    }
  }, [api]);

  useEffect(() => {
    loadData();
  }, [loadData]);

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
        <h1 className="text-2xl font-bold text-slate-900 dark:text-white">Managed Households</h1>
        <p className="text-slate-600 dark:text-slate-400">
          View and manage all households assigned to you
        </p>
      </div>

      {/* Error */}
      {error && (
        <div className="p-4 rounded-lg bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800">
          <p className="text-sm text-red-600 dark:text-red-400">{error}</p>
        </div>
      )}

      {/* Households Grid */}
      {households.length > 0 ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {households.map((household) => (
            <HouseholdCard
              key={household.id}
              household={household}
              onClick={() => setSelectedHousehold(household)}
            />
          ))}
        </div>
      ) : (
        <div className="card text-center py-12">
          <div className="w-16 h-16 rounded-full bg-slate-100 dark:bg-slate-800 flex items-center justify-center mx-auto mb-4">
            <svg className="w-8 h-8 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
            </svg>
          </div>
          <h2 className="text-xl font-semibold text-slate-900 dark:text-white mb-2">
            No households assigned
          </h2>
          <p className="text-slate-600 dark:text-slate-400">
            You don&apos;t have any households assigned to manage yet.
          </p>
        </div>
      )}

      {/* Household Detail Modal */}
      {selectedHousehold && (
        <HouseholdDetailModal
          household={selectedHousehold}
          requests={requests.filter((r) => r.householdId === selectedHousehold.id)}
          onClose={() => setSelectedHousehold(null)}
        />
      )}
    </div>
  );
}

function HouseholdCard({
  household,
  onClick,
}: {
  household: HouseholdWithDetails;
  onClick: () => void;
}) {
  const propertyTypeLabels: Record<string, string> = {
    SINGLE_FAMILY: 'Single Family',
    TOWNHOUSE: 'Townhouse',
    CONDO: 'Condo',
    APARTMENT: 'Apartment',
    MULTI_FAMILY: 'Multi-Family',
    MOBILE_HOME: 'Mobile Home',
    OTHER: 'Other',
  };

  return (
    <div
      onClick={onClick}
      className="card cursor-pointer hover:shadow-md transition-shadow"
    >
      <div className="flex items-start justify-between mb-4">
        <div className="w-12 h-12 rounded-lg bg-emerald-100 dark:bg-emerald-900/30 flex items-center justify-center">
          <svg className="w-6 h-6 text-emerald-600 dark:text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
          </svg>
        </div>
        {(household.activeRequestCount ?? 0) > 0 && (
          <span className="text-xs font-medium px-2 py-1 rounded-full bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400">
            {household.activeRequestCount} active
          </span>
        )}
      </div>

      <h3 className="text-lg font-semibold text-slate-900 dark:text-white mb-1">
        {household.name}
      </h3>

      {household.homeProfile && (
        <div className="mb-3">
          <p className="text-sm text-slate-600 dark:text-slate-400">
            {household.homeProfile.addressLine1}
          </p>
          <p className="text-sm text-slate-500 dark:text-slate-500">
            {household.homeProfile.city}, {household.homeProfile.state} {household.homeProfile.postalCode}
          </p>
        </div>
      )}

      <div className="flex items-center justify-between pt-3 border-t border-slate-100 dark:border-slate-700">
        {household.homeProfile && (
          <span className="text-xs text-slate-500 dark:text-slate-400">
            {propertyTypeLabels[household.homeProfile.propertyType] || household.homeProfile.propertyType}
          </span>
        )}
        <span className="text-xs text-slate-500 dark:text-slate-400">
          {household.requestCount ?? 0} requests
        </span>
      </div>
    </div>
  );
}

function HouseholdDetailModal({
  household,
  requests,
  onClose,
}: {
  household: HouseholdWithDetails;
  requests: ServiceRequestDetail[];
  onClose: () => void;
}) {
  const activeRequests = requests.filter((r) => r.status !== 'COMPLETED' && r.status !== 'CANCELLED');
  const completedRequests = requests.filter((r) => r.status === 'COMPLETED');

  const propertyTypeLabels: Record<string, string> = {
    SINGLE_FAMILY: 'Single Family',
    TOWNHOUSE: 'Townhouse',
    CONDO: 'Condo',
    APARTMENT: 'Apartment',
    MULTI_FAMILY: 'Multi-Family',
    MOBILE_HOME: 'Mobile Home',
    OTHER: 'Other',
  };

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      <div className="flex min-h-full items-end justify-center p-4 text-center sm:items-center sm:p-0">
        <div className="fixed inset-0 bg-black/50 transition-opacity" onClick={onClose} />

        <div className="relative transform overflow-hidden rounded-xl bg-white dark:bg-slate-800 text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-2xl">
          {/* Header */}
          <div className="border-b border-slate-200 dark:border-slate-700 px-6 py-4">
            <div className="flex items-start justify-between">
              <div>
                <h3 className="text-lg font-semibold text-slate-900 dark:text-white">
                  {household.name}
                </h3>
                {household.homeProfile && (
                  <p className="text-sm text-slate-500 dark:text-slate-400">
                    {propertyTypeLabels[household.homeProfile.propertyType]}
                  </p>
                )}
              </div>
              <button
                onClick={onClose}
                className="text-slate-400 hover:text-slate-500 dark:hover:text-slate-300"
              >
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>
          </div>

          {/* Content */}
          <div className="px-6 py-4 space-y-6 max-h-[60vh] overflow-y-auto">
            {/* Property Details */}
            {household.homeProfile && (
              <div>
                <h4 className="font-medium text-slate-900 dark:text-white mb-3">Property Details</h4>
                <div className="grid grid-cols-2 gap-4 text-sm">
                  <div>
                    <span className="text-slate-500 dark:text-slate-400">Address</span>
                    <p className="text-slate-900 dark:text-white">
                      {household.homeProfile.addressLine1}
                      <br />
                      {household.homeProfile.city}, {household.homeProfile.state} {household.homeProfile.postalCode}
                    </p>
                  </div>
                  {household.homeProfile.yearBuilt && (
                    <div>
                      <span className="text-slate-500 dark:text-slate-400">Year Built</span>
                      <p className="text-slate-900 dark:text-white">{household.homeProfile.yearBuilt}</p>
                    </div>
                  )}
                  {household.homeProfile.squareFeet && (
                    <div>
                      <span className="text-slate-500 dark:text-slate-400">Square Feet</span>
                      <p className="text-slate-900 dark:text-white">{household.homeProfile.squareFeet.toLocaleString()}</p>
                    </div>
                  )}
                  {household.homeProfile.bedrooms && (
                    <div>
                      <span className="text-slate-500 dark:text-slate-400">Bedrooms</span>
                      <p className="text-slate-900 dark:text-white">{household.homeProfile.bedrooms}</p>
                    </div>
                  )}
                </div>
              </div>
            )}

            {/* Active Requests */}
            <div>
              <h4 className="font-medium text-slate-900 dark:text-white mb-3">
                Active Requests ({activeRequests.length})
              </h4>
              {activeRequests.length > 0 ? (
                <div className="space-y-2">
                  {activeRequests.map((request) => (
                    <RequestItem key={request.id} request={request} />
                  ))}
                </div>
              ) : (
                <p className="text-sm text-slate-500 dark:text-slate-400">No active requests</p>
              )}
            </div>

            {/* Completed Requests */}
            {completedRequests.length > 0 && (
              <div>
                <h4 className="font-medium text-slate-900 dark:text-white mb-3">
                  Completed ({completedRequests.length})
                </h4>
                <div className="space-y-2">
                  {completedRequests.slice(0, 3).map((request) => (
                    <RequestItem key={request.id} request={request} />
                  ))}
                </div>
              </div>
            )}
          </div>

          {/* Footer */}
          <div className="border-t border-slate-200 dark:border-slate-700 px-6 py-4">
            <button onClick={onClose} className="btn btn-secondary w-full">
              Close
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

function RequestItem({ request }: { request: ServiceRequestDetail }) {
  const statusColors: Record<string, string> = {
    SUBMITTED: 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400',
    ASSIGNED: 'bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-400',
    IN_PROGRESS: 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400',
    COMPLETED: 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400',
    CANCELLED: 'bg-slate-100 text-slate-700 dark:bg-slate-700 dark:text-slate-400',
  };

  return (
    <div className="flex items-center justify-between p-3 rounded-lg bg-slate-50 dark:bg-slate-700/50">
      <div className="min-w-0 flex-1">
        <p className="font-medium text-sm text-slate-900 dark:text-white truncate">{request.title}</p>
        <p className="text-xs text-slate-500 dark:text-slate-400">
          {request.serviceCategory?.name || 'General'}
        </p>
      </div>
      <span className={`text-xs font-medium px-2 py-0.5 rounded ${statusColors[request.status]}`}>
        {request.status.replace('_', ' ')}
      </span>
    </div>
  );
}
