'use client';

import { useEffect, useState, useCallback } from 'react';
import { useAuth } from '@/contexts/auth-context';
import { getApiClient, getAccessToken } from '@/lib/api';
import type { ServiceRequest, ServiceCategory, ServiceRequestStatus, ServiceRequestPriority, WorkOrder, WorkOrderStatus } from '@haven/core';

const STATUS_OPTIONS: ServiceRequestStatus[] = ['DRAFT', 'SUBMITTED', 'ASSIGNED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'];
const PRIORITY_OPTIONS: ServiceRequestPriority[] = ['LOW', 'MEDIUM', 'HIGH', 'URGENT'];

type ViewMode = 'all' | 'requests' | 'work-orders';

interface UnifiedItem {
  id: string;
  type: 'request' | 'work-order';
  title: string;
  description: string | null;
  status: string;
  priority?: string;
  date: string;
  scheduledDate?: string | null;
  vendorName?: string | null;
  originalItem: ServiceRequest | WorkOrder;
}

export default function RequestsPage() {
  const { currentHousehold, isAuthenticated, selectedHouseholdId } = useAuth();
  const [requests, setRequests] = useState<ServiceRequest[]>([]);
  const [workOrders, setWorkOrders] = useState<WorkOrder[]>([]);
  const [categories, setCategories] = useState<ServiceCategory[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [viewMode, setViewMode] = useState<ViewMode>('all');

  // Filters
  const [statusFilter, setStatusFilter] = useState<string>('ALL');

  const loadData = useCallback(async () => {
    const token = getAccessToken();
    const householdId = selectedHouseholdId || currentHousehold?.id;
    if (!householdId || !isAuthenticated || !token) {
      setIsLoading(false);
      return;
    }

    const api = getApiClient();
    try {
      const [requestsData, workOrdersData, categoriesData] = await Promise.all([
        api.getServiceRequests(householdId).catch(() => []),
        api.getWorkOrders(householdId, { includeCompleted: true }).catch(() => []),
        api.getServiceCategories().catch(() => []),
      ]);
      setRequests(requestsData);
      setWorkOrders(workOrdersData);
      setCategories(categoriesData);
    } catch (error) {
      console.error('Failed to load data:', error);
    } finally {
      setIsLoading(false);
    }
  }, [currentHousehold, selectedHouseholdId, isAuthenticated]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  // Combine and filter items
  const getUnifiedItems = (): UnifiedItem[] => {
    const items: UnifiedItem[] = [];

    if (viewMode === 'all' || viewMode === 'requests') {
      requests.forEach(req => {
        items.push({
          id: req.id,
          type: 'request',
          title: req.title,
          description: req.description,
          status: req.status,
          priority: req.priority,
          date: req.createdAt,
          scheduledDate: req.scheduledDate || req.preferredDate,
          originalItem: req,
        });
      });
    }

    if (viewMode === 'all' || viewMode === 'work-orders') {
      workOrders.forEach(wo => {
        items.push({
          id: wo.id,
          type: 'work-order',
          title: wo.title,
          description: wo.description,
          status: wo.status,
          priority: wo.priority,
          date: wo.createdAt,
          scheduledDate: wo.scheduledDate,
          vendorName: wo.vendor?.businessName || wo.vendor?.contactName,
          originalItem: wo,
        });
      });
    }

    // Filter by status
    let filtered = items;
    if (statusFilter !== 'ALL') {
      filtered = items.filter(item => item.status === statusFilter);
    }

    // Sort by date, newest first
    return filtered.sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());
  };

  const unifiedItems = getUnifiedItems();

  const getStatusBadge = (status: string, type: 'request' | 'work-order') => {
    const requestStyles: Record<string, string> = {
      DRAFT: 'bg-slate-100 text-slate-600 dark:bg-slate-700 dark:text-slate-300',
      SUBMITTED: 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400',
      ASSIGNED: 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400',
      IN_PROGRESS: 'bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400',
      COMPLETED: 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400',
      CANCELLED: 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400',
    };

    const workOrderStyles: Record<string, string> = {
      DRAFT: 'bg-slate-100 text-slate-600 dark:bg-slate-700 dark:text-slate-300',
      REQUESTED: 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400',
      QUOTED: 'bg-indigo-100 text-indigo-700 dark:bg-indigo-900/30 dark:text-indigo-400',
      APPROVED: 'bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-400',
      SCHEDULED: 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400',
      IN_PROGRESS: 'bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400',
      COMPLETED: 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400',
      INVOICED: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400',
      PAID: 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400',
      CANCELLED: 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400',
    };

    const styles = type === 'request' ? requestStyles : workOrderStyles;
    return styles[status] || 'bg-slate-100 text-slate-600';
  };

  const getPriorityBadge = (priority?: string) => {
    if (!priority) return 'bg-slate-100 text-slate-600 dark:bg-slate-700 dark:text-slate-300';
    const styles: Record<string, string> = {
      LOW: 'bg-slate-100 text-slate-600 dark:bg-slate-700 dark:text-slate-300',
      MEDIUM: 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400',
      HIGH: 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400',
      URGENT: 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400',
    };
    return styles[priority] || 'bg-slate-100 text-slate-600';
  };

  const formatDate = (date: Date | string | null | undefined) => {
    if (!date) return '-';
    return new Date(date).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
    });
  };

  const getViewModeStats = () => {
    const activeRequests = requests.filter(r => !['COMPLETED', 'CANCELLED'].includes(r.status)).length;
    const activeWorkOrders = workOrders.filter(w => !['COMPLETED', 'PAID', 'CANCELLED'].includes(w.status)).length;
    return { activeRequests, activeWorkOrders, total: activeRequests + activeWorkOrders };
  };

  const stats = getViewModeStats();

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
          <h1 className="text-2xl font-bold text-slate-900 dark:text-white">
            Requests & Work Orders
          </h1>
          <p className="text-slate-600 dark:text-slate-400 mt-1">
            Track all service requests and scheduled work for your home
          </p>
        </div>
        <button
          onClick={() => setIsModalOpen(true)}
          className="inline-flex items-center gap-2 px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition-colors"
        >
          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
          </svg>
          New Request
        </button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="card p-4">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center">
              <svg className="w-5 h-5 text-blue-600 dark:text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
              </svg>
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900 dark:text-white">{stats.activeRequests}</p>
              <p className="text-sm text-slate-600 dark:text-slate-400">Active Requests</p>
            </div>
          </div>
        </div>
        <div className="card p-4">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-orange-100 dark:bg-orange-900/30 flex items-center justify-center">
              <svg className="w-5 h-5 text-orange-600 dark:text-orange-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
              </svg>
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900 dark:text-white">{stats.activeWorkOrders}</p>
              <p className="text-sm text-slate-600 dark:text-slate-400">Active Work Orders</p>
            </div>
          </div>
        </div>
        <div className="card p-4">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-emerald-100 dark:bg-emerald-900/30 flex items-center justify-center">
              <svg className="w-5 h-5 text-emerald-600 dark:text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900 dark:text-white">
                {requests.filter(r => r.status === 'COMPLETED').length + workOrders.filter(w => ['COMPLETED', 'PAID'].includes(w.status)).length}
              </p>
              <p className="text-sm text-slate-600 dark:text-slate-400">Completed This Month</p>
            </div>
          </div>
        </div>
      </div>

      {/* View Mode Tabs & Filters */}
      <div className="card p-4">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div className="flex gap-2">
            <button
              onClick={() => setViewMode('all')}
              className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                viewMode === 'all'
                  ? 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400'
                  : 'bg-slate-100 text-slate-600 hover:bg-slate-200 dark:bg-slate-700 dark:text-slate-300 dark:hover:bg-slate-600'
              }`}
            >
              All Items
              <span className="ml-2 px-1.5 py-0.5 rounded bg-white/50 dark:bg-black/20 text-xs">
                {requests.length + workOrders.length}
              </span>
            </button>
            <button
              onClick={() => setViewMode('requests')}
              className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                viewMode === 'requests'
                  ? 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400'
                  : 'bg-slate-100 text-slate-600 hover:bg-slate-200 dark:bg-slate-700 dark:text-slate-300 dark:hover:bg-slate-600'
              }`}
            >
              Requests
              <span className="ml-2 px-1.5 py-0.5 rounded bg-white/50 dark:bg-black/20 text-xs">
                {requests.length}
              </span>
            </button>
            <button
              onClick={() => setViewMode('work-orders')}
              className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                viewMode === 'work-orders'
                  ? 'bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400'
                  : 'bg-slate-100 text-slate-600 hover:bg-slate-200 dark:bg-slate-700 dark:text-slate-300 dark:hover:bg-slate-600'
              }`}
            >
              Work Orders
              <span className="ml-2 px-1.5 py-0.5 rounded bg-white/50 dark:bg-black/20 text-xs">
                {workOrders.length}
              </span>
            </button>
          </div>
          <div className="flex gap-3">
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-white text-sm"
            >
              <option value="ALL">All Statuses</option>
              <optgroup label="Request Statuses">
                {STATUS_OPTIONS.map((status) => (
                  <option key={status} value={status}>
                    {status.replace('_', ' ')}
                  </option>
                ))}
              </optgroup>
              <optgroup label="Work Order Statuses">
                <option value="QUOTED">Quoted</option>
                <option value="APPROVED">Approved</option>
                <option value="SCHEDULED">Scheduled</option>
                <option value="INVOICED">Invoiced</option>
                <option value="PAID">Paid</option>
              </optgroup>
            </select>
          </div>
        </div>
      </div>

      {/* Items list */}
      {!(selectedHouseholdId || currentHousehold) ? (
        <div className="card text-center py-12">
          <svg className="w-16 h-16 mx-auto text-slate-300 dark:text-slate-600 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
          </svg>
          <p className="text-slate-500 dark:text-slate-400">
            Create a household to start managing requests
          </p>
        </div>
      ) : unifiedItems.length === 0 ? (
        <div className="card text-center py-12">
          <svg className="w-16 h-16 mx-auto text-slate-300 dark:text-slate-600 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
          </svg>
          <p className="text-slate-500 dark:text-slate-400 mb-4">
            {(requests.length + workOrders.length) === 0
              ? 'No requests or work orders yet'
              : 'No items match your filters'}
          </p>
          {(requests.length + workOrders.length) === 0 && (
            <button
              onClick={() => setIsModalOpen(true)}
              className="inline-flex items-center gap-2 px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition-colors"
            >
              Create your first request
            </button>
          )}
        </div>
      ) : (
        <div className="space-y-3">
          {unifiedItems.map((item) => (
            <div
              key={`${item.type}-${item.id}`}
              className="card p-4 hover:shadow-md transition-shadow cursor-pointer"
            >
              <div className="flex items-start justify-between gap-4">
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 mb-1">
                    <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${
                      item.type === 'request'
                        ? 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400'
                        : 'bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400'
                    }`}>
                      {item.type === 'request' ? 'Request' : 'Work Order'}
                    </span>
                    <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${getStatusBadge(item.status, item.type)}`}>
                      {item.status.replace('_', ' ')}
                    </span>
                    {item.priority && (
                      <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${getPriorityBadge(item.priority)}`}>
                        {item.priority}
                      </span>
                    )}
                  </div>
                  <h3 className="font-semibold text-slate-900 dark:text-white truncate">
                    {item.title}
                  </h3>
                  {item.description && (
                    <p className="text-sm text-slate-600 dark:text-slate-400 line-clamp-1 mt-1">
                      {item.description}
                    </p>
                  )}
                  <div className="flex items-center gap-4 mt-2 text-sm text-slate-500 dark:text-slate-400">
                    <span className="flex items-center gap-1">
                      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                      </svg>
                      {item.scheduledDate ? `Scheduled: ${formatDate(item.scheduledDate)}` : `Created: ${formatDate(item.date)}`}
                    </span>
                    {item.vendorName && (
                      <span className="flex items-center gap-1">
                        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
                        </svg>
                        {item.vendorName}
                      </span>
                    )}
                  </div>
                </div>
                <button className="text-emerald-600 hover:text-emerald-500 dark:text-emerald-400 text-sm font-medium whitespace-nowrap">
                  View Details
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* New Request Modal */}
      {isModalOpen && (
        <NewRequestModal
          categories={categories}
          householdId={selectedHouseholdId || currentHousehold?.id || ''}
          onClose={() => setIsModalOpen(false)}
          onSuccess={() => {
            setIsModalOpen(false);
            loadData();
          }}
        />
      )}
    </div>
  );
}

// New Request Modal Component
function NewRequestModal({
  categories,
  householdId,
  onClose,
  onSuccess,
}: {
  categories: ServiceCategory[];
  householdId: string;
  onClose: () => void;
  onSuccess: () => void;
}) {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [categoryId, setCategoryId] = useState('');
  const [priority, setPriority] = useState<ServiceRequestPriority>('MEDIUM');
  const [preferredDate, setPreferredDate] = useState('');
  const [photoFile, setPhotoFile] = useState<File | null>(null);
  const [photoPreview, setPhotoPreview] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');

  const handlePhotoChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setPhotoFile(file);
      const reader = new FileReader();
      reader.onloadend = () => {
        setPhotoPreview(reader.result as string);
      };
      reader.readAsDataURL(file);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setIsSubmitting(true);

    try {
      const api = getApiClient();

      // Create the service request first
      const request = await api.createServiceRequest({
        householdId,
        title,
        description,
        categoryId: categoryId || undefined,
        priority,
        preferredDate: preferredDate || undefined,
      });

      // Upload photo if provided
      if (photoFile) {
        try {
          await api.uploadFile(photoFile, {
            householdId,
            category: 'IMAGE',
            description: `Photo for request: ${title}`,
            serviceRequestId: request.id,
          });
        } catch (uploadErr) {
          console.error('Photo upload failed:', uploadErr);
          // Don't fail the whole request if photo upload fails
        }
      }

      onSuccess();
    } catch (err: unknown) {
      const message = err && typeof err === 'object' && 'message' in err
        ? (err as { message: string }).message
        : 'Failed to create request. Please try again.';
      setError(message);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      <div className="flex min-h-screen items-center justify-center p-4">
        {/* Backdrop */}
        <div
          className="fixed inset-0 bg-black/50 transition-opacity"
          onClick={onClose}
        />

        {/* Modal */}
        <div className="relative w-full max-w-lg bg-white dark:bg-slate-800 rounded-xl shadow-xl">
          {/* Header */}
          <div className="flex items-center justify-between p-6 border-b border-slate-200 dark:border-slate-700">
            <h2 className="text-lg font-semibold text-slate-900 dark:text-white">
              New Service Request
            </h2>
            <button
              onClick={onClose}
              className="p-1 text-slate-400 hover:text-slate-500 dark:hover:text-slate-300"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          {/* Form */}
          <form onSubmit={handleSubmit} className="p-6 space-y-4">
            {error && (
              <div className="p-3 rounded-lg bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800">
                <p className="text-sm text-red-600 dark:text-red-400">{error}</p>
              </div>
            )}

            <div>
              <label htmlFor="category" className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1.5">
                Category
              </label>
              <select
                id="category"
                value={categoryId}
                onChange={(e) => setCategoryId(e.target.value)}
                className="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-white"
              >
                <option value="">Select a category (optional)</option>
                {categories.map((category) => (
                  <option key={category.id} value={category.id}>
                    {category.name}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label htmlFor="title" className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1.5">
                Title <span className="text-red-500">*</span>
              </label>
              <input
                id="title"
                type="text"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                className="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-white"
                placeholder="e.g., Fix leaky faucet"
                required
              />
            </div>

            <div>
              <label htmlFor="description" className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1.5">
                Description <span className="text-red-500">*</span>
              </label>
              <textarea
                id="description"
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                className="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-white min-h-[100px]"
                placeholder="Describe the issue in detail..."
                required
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label htmlFor="priority" className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1.5">
                  Priority
                </label>
                <select
                  id="priority"
                  value={priority}
                  onChange={(e) => setPriority(e.target.value as ServiceRequestPriority)}
                  className="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-white"
                >
                  {PRIORITY_OPTIONS.map((p) => (
                    <option key={p} value={p}>
                      {p}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label htmlFor="preferredDate" className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1.5">
                  Preferred Date
                </label>
                <input
                  id="preferredDate"
                  type="date"
                  value={preferredDate}
                  onChange={(e) => setPreferredDate(e.target.value)}
                  className="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-white"
                  min={new Date().toISOString().split('T')[0]}
                />
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1.5">
                Photo (optional)
              </label>
              <div className="border-2 border-dashed border-slate-300 dark:border-slate-600 rounded-lg p-4">
                {photoPreview ? (
                  <div className="relative">
                    <img
                      src={photoPreview}
                      alt="Preview"
                      className="w-full h-40 object-cover rounded-lg"
                    />
                    <button
                      type="button"
                      onClick={() => {
                        setPhotoFile(null);
                        setPhotoPreview(null);
                      }}
                      className="absolute top-2 right-2 p-1 bg-red-500 text-white rounded-full hover:bg-red-600"
                    >
                      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                      </svg>
                    </button>
                  </div>
                ) : (
                  <label className="flex flex-col items-center cursor-pointer">
                    <svg className="w-10 h-10 text-slate-400 mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                    </svg>
                    <span className="text-sm text-slate-500 dark:text-slate-400">
                      Click to upload a photo
                    </span>
                    <input
                      type="file"
                      accept="image/*"
                      onChange={handlePhotoChange}
                      className="hidden"
                    />
                  </label>
                )}
              </div>
            </div>

            {/* Footer */}
            <div className="flex items-center justify-end gap-3 pt-4">
              <button
                type="button"
                onClick={onClose}
                className="px-4 py-2 border border-slate-300 dark:border-slate-600 text-slate-700 dark:text-slate-300 rounded-lg hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={isSubmitting}
                className="px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {isSubmitting ? (
                  <span className="flex items-center gap-2">
                    <svg className="animate-spin h-4 w-4" fill="none" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                    </svg>
                    Creating...
                  </span>
                ) : (
                  'Create Request'
                )}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}
