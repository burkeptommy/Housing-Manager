'use client';

import { useState, useEffect, useCallback } from 'react';
import { getApiClient } from '@/lib/api';
import { KanbanBoard } from '@/components/kanban-board';
import type {
  ServiceRequestDetail,
  ServiceRequestStatus,
  ServiceCategory,
  Household,
  Vendor,
} from '@haven/core';

export default function ManagerRequestsPage() {
  const [requests, setRequests] = useState<ServiceRequestDetail[]>([]);
  const [categories, setCategories] = useState<ServiceCategory[]>([]);
  const [households, setHouseholds] = useState<Household[]>([]);
  const [vendors, setVendors] = useState<Vendor[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');

  // Filters
  const [householdFilter, setHouseholdFilter] = useState<string>('');
  const [categoryFilter, setCategoryFilter] = useState<string>('');

  // Modal
  const [selectedRequest, setSelectedRequest] = useState<ServiceRequestDetail | null>(null);
  const [isUpdating, setIsUpdating] = useState(false);

  const api = getApiClient();

  const loadData = useCallback(async () => {
    try {
      const [requestsData, categoriesData, householdsData] = await Promise.all([
        api.getManagerRequests(),
        api.getServiceCategories(),
        api.getHouseholds(),
      ]);

      setRequests(requestsData);
      setCategories(categoriesData);
      setHouseholds(householdsData);

      // Try to load vendors, but don't fail if endpoint doesn't exist
      try {
        const vendorsData = await api.getVendors();
        setVendors(vendorsData);
      } catch {
        // Vendors endpoint may not exist yet
        setVendors([]);
      }
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

  // Filter requests
  const filteredRequests = requests.filter((r) => {
    if (householdFilter && r.householdId !== householdFilter) return false;
    if (categoryFilter && r.serviceCategoryId !== categoryFilter) return false;
    return true;
  });

  const handleStatusChange = async (requestId: string, newStatus: ServiceRequestStatus) => {
    try {
      await api.updateServiceRequest(requestId, { status: newStatus });
      setRequests((prev) =>
        prev.map((r) => (r.id === requestId ? { ...r, status: newStatus } : r))
      );
    } catch (err: unknown) {
      const message =
        err && typeof err === 'object' && 'message' in err
          ? (err as { message: string }).message
          : 'Failed to update status';
      setError(message);
      setTimeout(() => setError(''), 3000);
    }
  };

  const handleUpdateRequest = async (updates: {
    vendorId?: string;
    scheduledDate?: string;
    status?: ServiceRequestStatus;
  }) => {
    if (!selectedRequest) return;

    setIsUpdating(true);
    try {
      const updated = await api.updateServiceRequest(selectedRequest.id, updates);
      setRequests((prev) =>
        prev.map((r) => (r.id === selectedRequest.id ? updated : r))
      );
      setSelectedRequest(updated);
    } catch (err: unknown) {
      const message =
        err && typeof err === 'object' && 'message' in err
          ? (err as { message: string }).message
          : 'Failed to update request';
      setError(message);
    } finally {
      setIsUpdating(false);
    }
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
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 dark:text-white">Service Requests</h1>
          <p className="text-slate-600 dark:text-slate-400">
            Manage service requests from your assigned households
          </p>
        </div>
      </div>

      {/* Error */}
      {error && (
        <div className="p-4 rounded-lg bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800">
          <p className="text-sm text-red-600 dark:text-red-400">{error}</p>
        </div>
      )}

      {/* Filters */}
      <div className="flex flex-wrap gap-4">
        <div>
          <label htmlFor="household" className="sr-only">Filter by household</label>
          <select
            id="household"
            value={householdFilter}
            onChange={(e) => setHouseholdFilter(e.target.value)}
            className="input"
          >
            <option value="">All Households</option>
            {households.map((h) => (
              <option key={h.id} value={h.id}>{h.name}</option>
            ))}
          </select>
        </div>
        <div>
          <label htmlFor="category" className="sr-only">Filter by category</label>
          <select
            id="category"
            value={categoryFilter}
            onChange={(e) => setCategoryFilter(e.target.value)}
            className="input"
          >
            <option value="">All Categories</option>
            {categories.map((c) => (
              <option key={c.id} value={c.id}>{c.name}</option>
            ))}
          </select>
        </div>
        {(householdFilter || categoryFilter) && (
          <button
            onClick={() => {
              setHouseholdFilter('');
              setCategoryFilter('');
            }}
            className="text-sm text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white"
          >
            Clear filters
          </button>
        )}
      </div>

      {/* Kanban Board */}
      <KanbanBoard
        requests={filteredRequests}
        onStatusChange={handleStatusChange}
        onRequestClick={setSelectedRequest}
      />

      {/* Request Detail Modal */}
      {selectedRequest && (
        <RequestDetailModal
          request={selectedRequest}
          vendors={vendors}
          categories={categories}
          onClose={() => setSelectedRequest(null)}
          onUpdate={handleUpdateRequest}
          isUpdating={isUpdating}
        />
      )}
    </div>
  );
}

interface RequestDetailModalProps {
  request: ServiceRequestDetail;
  vendors: Vendor[];
  categories: ServiceCategory[];
  onClose: () => void;
  onUpdate: (updates: {
    vendorId?: string;
    scheduledDate?: string;
    status?: ServiceRequestStatus;
  }) => Promise<void>;
  isUpdating: boolean;
}

function RequestDetailModal({
  request,
  vendors,
  categories: _categories,
  onClose,
  onUpdate,
  isUpdating,
}: RequestDetailModalProps) {
  void _categories; // Reserved for future category filtering
  const [vendorId, setVendorId] = useState(request.vendorId || '');
  const [scheduledDate, setScheduledDate] = useState(
    request.scheduledDate
      ? new Date(request.scheduledDate).toISOString().slice(0, 16)
      : ''
  );
  const [status, setStatus] = useState<ServiceRequestStatus>(request.status);

  const hasChanges =
    vendorId !== (request.vendorId || '') ||
    scheduledDate !== (request.scheduledDate ? new Date(request.scheduledDate).toISOString().slice(0, 16) : '') ||
    status !== request.status;

  const handleSave = async () => {
    const updates: {
      vendorId?: string;
      scheduledDate?: string;
      status?: ServiceRequestStatus;
    } = {};

    if (vendorId !== (request.vendorId || '')) {
      updates.vendorId = vendorId || undefined;
    }
    if (scheduledDate !== (request.scheduledDate ? new Date(request.scheduledDate).toISOString().slice(0, 16) : '')) {
      updates.scheduledDate = scheduledDate || undefined;
    }
    if (status !== request.status) {
      updates.status = status;
    }

    await onUpdate(updates);
  };

  const priorityColors: Record<string, string> = {
    LOW: 'bg-slate-100 text-slate-600 dark:bg-slate-700 dark:text-slate-400',
    MEDIUM: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400',
    HIGH: 'bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400',
    URGENT: 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400',
  };

  const statusOptions: { value: ServiceRequestStatus; label: string }[] = [
    { value: 'SUBMITTED', label: 'New' },
    { value: 'ASSIGNED', label: 'Assigned' },
    { value: 'IN_PROGRESS', label: 'In Progress' },
    { value: 'COMPLETED', label: 'Completed' },
    { value: 'CANCELLED', label: 'Cancelled' },
  ];

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
                  {request.title}
                </h3>
                <div className="flex items-center gap-2 mt-1">
                  <span className={`text-xs font-medium px-2 py-0.5 rounded ${priorityColors[request.priority]}`}>
                    {request.priority}
                  </span>
                  <span className="text-sm text-slate-500 dark:text-slate-400">
                    {request.household?.name}
                  </span>
                </div>
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
          <div className="px-6 py-4 space-y-6">
            {/* Description */}
            <div>
              <h4 className="text-sm font-medium text-slate-500 dark:text-slate-400 mb-1">Description</h4>
              <p className="text-slate-900 dark:text-white">{request.description}</p>
            </div>

            {/* Info Grid */}
            <div className="grid grid-cols-2 gap-4">
              <div>
                <h4 className="text-sm font-medium text-slate-500 dark:text-slate-400 mb-1">Category</h4>
                <p className="text-slate-900 dark:text-white">
                  {request.serviceCategory?.name || 'Not specified'}
                </p>
              </div>
              <div>
                <h4 className="text-sm font-medium text-slate-500 dark:text-slate-400 mb-1">Requested By</h4>
                <p className="text-slate-900 dark:text-white">
                  {request.createdBy?.firstName} {request.createdBy?.lastName}
                </p>
              </div>
              <div>
                <h4 className="text-sm font-medium text-slate-500 dark:text-slate-400 mb-1">Preferred Date</h4>
                <p className="text-slate-900 dark:text-white">
                  {request.preferredDate
                    ? new Date(request.preferredDate).toLocaleDateString()
                    : 'Not specified'}
                </p>
              </div>
              <div>
                <h4 className="text-sm font-medium text-slate-500 dark:text-slate-400 mb-1">Created</h4>
                <p className="text-slate-900 dark:text-white">
                  {new Date(request.createdAt).toLocaleDateString()}
                </p>
              </div>
            </div>

            {/* Editable Fields */}
            <div className="space-y-4 pt-4 border-t border-slate-200 dark:border-slate-700">
              <div>
                <label htmlFor="status" className="label block mb-1.5">Status</label>
                <select
                  id="status"
                  value={status}
                  onChange={(e) => setStatus(e.target.value as ServiceRequestStatus)}
                  className="input"
                >
                  {statusOptions.map((opt) => (
                    <option key={opt.value} value={opt.value}>{opt.label}</option>
                  ))}
                </select>
              </div>

              <div>
                <label htmlFor="vendor" className="label block mb-1.5">Assign Vendor</label>
                <select
                  id="vendor"
                  value={vendorId}
                  onChange={(e) => setVendorId(e.target.value)}
                  className="input"
                >
                  <option value="">Select vendor...</option>
                  {vendors.map((v) => (
                    <option key={v.id} value={v.id}>{v.name}</option>
                  ))}
                </select>
              </div>

              <div>
                <label htmlFor="scheduledDate" className="label block mb-1.5">Scheduled Date & Time</label>
                <input
                  id="scheduledDate"
                  type="datetime-local"
                  value={scheduledDate}
                  onChange={(e) => setScheduledDate(e.target.value)}
                  className="input"
                />
              </div>
            </div>

            {/* Notes */}
            {request.notes && (
              <div>
                <h4 className="text-sm font-medium text-slate-500 dark:text-slate-400 mb-1">Notes</h4>
                <p className="text-slate-900 dark:text-white text-sm">{request.notes}</p>
              </div>
            )}
          </div>

          {/* Footer */}
          <div className="border-t border-slate-200 dark:border-slate-700 px-6 py-4 flex justify-end gap-3">
            <button onClick={onClose} className="btn btn-secondary">
              Cancel
            </button>
            <button
              onClick={handleSave}
              disabled={!hasChanges || isUpdating}
              className="btn btn-primary"
            >
              {isUpdating ? 'Saving...' : 'Save Changes'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
