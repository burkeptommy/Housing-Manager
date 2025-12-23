'use client';

import { useState, useEffect, useCallback } from 'react';
import { getApiClient } from '@/lib/api';
import type { Household, ServiceRequestDetail, HomeProfile, Transaction, TransactionPayoutMethod, HouseholdVendor } from '@haven/core';

interface HouseholdWithDetails extends Household {
  homeProfile?: HomeProfile | null;
  requestCount?: number;
  activeRequestCount?: number;
}

// Mock transactions for demo (in production, these would come from API)
const mockTransactions: Record<string, Transaction[]> = {};

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
          <span className="text-xs font-medium px-2 py-1 rounded-full bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400">
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
  const [showLogExpense, setShowLogExpense] = useState(false);
  const [transactions, setTransactions] = useState<Transaction[]>(mockTransactions[household.id] || []);
  const activeRequests = requests.filter((r) => r.status !== 'COMPLETED' && r.status !== 'CANCELLED');
  const completedRequests = requests.filter((r) => r.status === 'COMPLETED');

  // Calculate current month balance
  const currentMonthBalance = transactions
    .filter((t) => t.status === 'PAID_TO_VENDOR' && t.isReimbursable)
    .reduce((sum, t) => sum + t.amount, 0);

  const propertyTypeLabels: Record<string, string> = {
    SINGLE_FAMILY: 'Single Family',
    TOWNHOUSE: 'Townhouse',
    CONDO: 'Condo',
    APARTMENT: 'Apartment',
    MULTI_FAMILY: 'Multi-Family',
    MOBILE_HOME: 'Mobile Home',
    OTHER: 'Other',
  };

  const handleExpenseLogged = (newTransaction: Transaction) => {
    const updatedTransactions = [newTransaction, ...transactions];
    setTransactions(updatedTransactions);
    mockTransactions[household.id] = updatedTransactions;
    setShowLogExpense(false);
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
            {/* Financial Control Widget */}
            <div className="rounded-lg bg-gradient-to-br from-emerald-500 to-emerald-600 p-4 text-white">
              <div className="flex items-center justify-between mb-3">
                <h4 className="font-semibold flex items-center gap-2">
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                  Financial Control
                </h4>
                <span className="text-xs bg-white/20 px-2 py-0.5 rounded">The Float</span>
              </div>

              <div className="mb-4">
                <p className="text-emerald-100 text-xs mb-1">Current Month Balance</p>
                <p className="text-3xl font-bold">${currentMonthBalance.toFixed(2)}</p>
                <p className="text-emerald-100 text-xs mt-1">
                  {transactions.filter((t) => t.status === 'PAID_TO_VENDOR').length} transactions pending reimbursement
                </p>
              </div>

              <button
                onClick={() => setShowLogExpense(true)}
                className="w-full bg-white text-emerald-600 font-semibold py-2 px-4 rounded-lg hover:bg-emerald-50 transition-colors flex items-center justify-center gap-2"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                </svg>
                Log Expense
              </button>
            </div>

            {/* Recent Transactions */}
            {transactions.length > 0 && (
              <div>
                <h4 className="font-medium text-slate-900 dark:text-white mb-3">Recent Expenses</h4>
                <div className="space-y-2">
                  {transactions.slice(0, 5).map((tx) => (
                    <div key={tx.id} className="flex items-center justify-between p-3 rounded-lg bg-slate-50 dark:bg-slate-700/50">
                      <div className="min-w-0 flex-1">
                        <p className="font-medium text-sm text-slate-900 dark:text-white truncate">{tx.description}</p>
                        <p className="text-xs text-slate-500 dark:text-slate-400">
                          {tx.vendor?.displayName || 'Unknown Vendor'} • {tx.payoutMethod.replace('_', ' ')}
                        </p>
                      </div>
                      <div className="text-right">
                        <p className="font-semibold text-slate-900 dark:text-white">${tx.amount.toFixed(2)}</p>
                        <span className={`text-xs font-medium px-2 py-0.5 rounded ${
                          tx.status === 'PAID_TO_VENDOR' ? 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400' :
                          tx.status === 'SETTLED' ? 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400' :
                          'bg-slate-100 text-slate-700 dark:bg-slate-600 dark:text-slate-300'
                        }`}>
                          {tx.status.replace(/_/g, ' ')}
                        </span>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

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

      {/* Log Expense Modal */}
      {showLogExpense && (
        <LogExpenseModal
          householdId={household.id}
          householdName={household.name}
          onClose={() => setShowLogExpense(false)}
          onSuccess={handleExpenseLogged}
        />
      )}
    </div>
  );
}

function RequestItem({ request }: { request: ServiceRequestDetail }) {
  const statusColors: Record<string, string> = {
    SUBMITTED: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400',
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

// Mock vendors for the demo
const mockVendors: HouseholdVendor[] = [
  { id: 'v1', householdId: '', displayName: "Joe's Plumbing", category: 'HANDYMAN', serviceDescription: 'Plumbing services', isLocal: true, phone: '555-0101', email: null, websiteUrl: null, notes: null, createdAt: new Date(), updatedAt: new Date() },
  { id: 'v2', householdId: '', displayName: 'Green Lawn Care', category: 'LAWN_CARE', serviceDescription: 'Lawn maintenance', isLocal: true, phone: '555-0102', email: null, websiteUrl: null, notes: null, createdAt: new Date(), updatedAt: new Date() },
  { id: 'v3', householdId: '', displayName: 'Crystal Pool Service', category: 'POOL_SERVICE', serviceDescription: 'Pool cleaning', isLocal: true, phone: '555-0103', email: null, websiteUrl: null, notes: null, createdAt: new Date(), updatedAt: new Date() },
  { id: 'v4', householdId: '', displayName: 'SecureLock Locksmith', category: 'HANDYMAN', serviceDescription: 'Emergency locksmith', isLocal: true, phone: '555-0104', email: null, websiteUrl: null, notes: null, createdAt: new Date(), updatedAt: new Date() },
  { id: 'v5', householdId: '', displayName: 'Haven Home Management', category: 'OTHER', serviceDescription: 'Management services', isLocal: false, phone: null, email: null, websiteUrl: null, notes: null, createdAt: new Date(), updatedAt: new Date() },
];

function LogExpenseModal({
  householdId,
  householdName,
  onClose,
  onSuccess,
}: {
  householdId: string;
  householdName: string;
  onClose: () => void;
  onSuccess: (transaction: Transaction) => void;
}) {
  const [selectedVendor, setSelectedVendor] = useState<string>('');
  const [amount, setAmount] = useState<string>('');
  const [description, setDescription] = useState<string>('');
  const [payoutMethod, setPayoutMethod] = useState<TransactionPayoutMethod>('COMPANY_CARD');
  const [receiptFile, setReceiptFile] = useState<File | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [dragActive, setDragActive] = useState(false);

  const handleDrag = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    if (e.type === 'dragenter' || e.type === 'dragover') {
      setDragActive(true);
    } else if (e.type === 'dragleave') {
      setDragActive(false);
    }
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setDragActive(false);
    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      setReceiptFile(e.dataTransfer.files[0]);
    }
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      setReceiptFile(e.target.files[0]);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedVendor || !amount) return;

    setIsSubmitting(true);

    // Simulate API call - in production this would call the real API
    await new Promise((resolve) => setTimeout(resolve, 500));

    const vendor = mockVendors.find((v) => v.id === selectedVendor);
    const newTransaction: Transaction = {
      id: `tx-${Date.now()}`,
      householdId,
      vendorId: selectedVendor,
      managerId: 'current-user',
      description: description || `Payment to ${vendor?.displayName}`,
      amount: parseFloat(amount),
      payoutMethod,
      status: 'PAID_TO_VENDOR',
      isReimbursable: true,
      paidAt: new Date().toISOString(),
      billedAt: null,
      settledAt: null,
      receiptUrl: receiptFile ? URL.createObjectURL(receiptFile) : null,
      receiptFileId: null,
      workOrderId: null,
      maintenanceTaskId: null,
      householdInvoiceId: null,
      notes: null,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      vendor: vendor ? {
        id: vendor.id,
        displayName: vendor.displayName,
        category: vendor.category,
      } : null,
      manager: {
        id: 'current-user',
        firstName: 'Sarah',
        lastName: 'Harrison',
        email: 'sarah@haven.app',
      },
      household: {
        id: householdId,
        name: householdName,
      },
    };

    setIsSubmitting(false);
    onSuccess(newTransaction);
  };

  return (
    <div className="fixed inset-0 z-[60] overflow-y-auto">
      <div className="flex min-h-full items-end justify-center p-4 text-center sm:items-center sm:p-0">
        <div className="fixed inset-0 bg-black/50 transition-opacity" onClick={onClose} />

        <div className="relative transform overflow-hidden rounded-xl bg-white dark:bg-slate-800 text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-md">
          {/* Header */}
          <div className="border-b border-slate-200 dark:border-slate-700 px-6 py-4">
            <div className="flex items-center justify-between">
              <h3 className="text-lg font-semibold text-slate-900 dark:text-white">
                Log Expense
              </h3>
              <button
                onClick={onClose}
                className="text-slate-400 hover:text-slate-500 dark:hover:text-slate-300"
              >
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>
            <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">{householdName}</p>
          </div>

          {/* Form */}
          <form onSubmit={handleSubmit} className="px-6 py-4 space-y-4">
            {/* Vendor Selection */}
            <div>
              <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                Vendor
              </label>
              <select
                value={selectedVendor}
                onChange={(e) => setSelectedVendor(e.target.value)}
                className="input w-full"
                required
              >
                <option value="">Select a vendor...</option>
                {mockVendors.map((vendor) => (
                  <option key={vendor.id} value={vendor.id}>
                    {vendor.displayName}
                  </option>
                ))}
              </select>
            </div>

            {/* Amount */}
            <div>
              <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                Amount
              </label>
              <div className="relative">
                <span className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500">$</span>
                <input
                  type="number"
                  step="0.01"
                  min="0"
                  value={amount}
                  onChange={(e) => setAmount(e.target.value)}
                  className="input w-full pl-7"
                  placeholder="0.00"
                  required
                />
              </div>
            </div>

            {/* Description */}
            <div>
              <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                Description (optional)
              </label>
              <input
                type="text"
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                className="input w-full"
                placeholder="e.g., Pool cleaning service"
              />
            </div>

            {/* Payment Method Toggle */}
            <div>
              <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                Paid via
              </label>
              <div className="flex gap-2">
                <button
                  type="button"
                  onClick={() => setPayoutMethod('COMPANY_CARD')}
                  className={`flex-1 py-2 px-4 rounded-lg border-2 font-medium text-sm transition-colors ${
                    payoutMethod === 'COMPANY_CARD'
                      ? 'border-emerald-500 bg-emerald-50 text-emerald-700 dark:bg-emerald-900/20 dark:text-emerald-400'
                      : 'border-slate-200 dark:border-slate-600 text-slate-600 dark:text-slate-400 hover:border-slate-300'
                  }`}
                >
                  <svg className="w-5 h-5 mx-auto mb-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" />
                  </svg>
                  Company Card
                </button>
                <button
                  type="button"
                  onClick={() => setPayoutMethod('CASH')}
                  className={`flex-1 py-2 px-4 rounded-lg border-2 font-medium text-sm transition-colors ${
                    payoutMethod === 'CASH'
                      ? 'border-emerald-500 bg-emerald-50 text-emerald-700 dark:bg-emerald-900/20 dark:text-emerald-400'
                      : 'border-slate-200 dark:border-slate-600 text-slate-600 dark:text-slate-400 hover:border-slate-300'
                  }`}
                >
                  <svg className="w-5 h-5 mx-auto mb-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z" />
                  </svg>
                  Cash
                </button>
              </div>
            </div>

            {/* Receipt Upload */}
            <div>
              <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                Receipt (optional)
              </label>
              <div
                onDragEnter={handleDrag}
                onDragLeave={handleDrag}
                onDragOver={handleDrag}
                onDrop={handleDrop}
                className={`border-2 border-dashed rounded-lg p-4 text-center transition-colors ${
                  dragActive
                    ? 'border-emerald-500 bg-emerald-50 dark:bg-emerald-900/20'
                    : 'border-slate-300 dark:border-slate-600 hover:border-slate-400'
                }`}
              >
                {receiptFile ? (
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-slate-600 dark:text-slate-400 truncate">
                      {receiptFile.name}
                    </span>
                    <button
                      type="button"
                      onClick={() => setReceiptFile(null)}
                      className="text-red-500 hover:text-red-600"
                    >
                      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                      </svg>
                    </button>
                  </div>
                ) : (
                  <>
                    <svg className="w-8 h-8 mx-auto text-slate-400 mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
                    </svg>
                    <p className="text-sm text-slate-500 dark:text-slate-400 mb-1">
                      Drag & drop receipt here
                    </p>
                    <label className="text-sm text-emerald-600 hover:text-emerald-700 cursor-pointer font-medium">
                      or browse files
                      <input
                        type="file"
                        accept="image/*,.pdf"
                        onChange={handleFileChange}
                        className="hidden"
                      />
                    </label>
                  </>
                )}
              </div>
            </div>

            {/* Submit Button */}
            <button
              type="submit"
              disabled={isSubmitting || !selectedVendor || !amount}
              className="btn btn-primary w-full"
            >
              {isSubmitting ? (
                <>
                  <svg className="animate-spin -ml-1 mr-2 h-4 w-4" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                  </svg>
                  Logging Expense...
                </>
              ) : (
                'Log Expense'
              )}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}
