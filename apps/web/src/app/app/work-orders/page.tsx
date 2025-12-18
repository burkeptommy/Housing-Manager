'use client';

import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '@/contexts/auth-context';
import { getApiClient } from '@/lib/api';
import type { WorkOrder, WorkOrderStatus, HouseholdVendor, CreateWorkOrderRequest, MaintenanceTask } from '@haven/core';

const STATUS_OPTIONS: WorkOrderStatus[] = ['DRAFT', 'REQUESTED', 'SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'];

export default function WorkOrdersPage() {
  const { currentHousehold } = useAuth();
  const [workOrders, setWorkOrders] = useState<WorkOrder[]>([]);
  const [vendors, setVendors] = useState<HouseholdVendor[]>([]);
  const [maintenanceTasks, setMaintenanceTasks] = useState<MaintenanceTask[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedOrder, setSelectedOrder] = useState<WorkOrder | null>(null);

  // Filters
  const [statusFilter, setStatusFilter] = useState<WorkOrderStatus | 'ALL'>('ALL');
  const [showCompleted, setShowCompleted] = useState(false);

  const loadData = useCallback(async () => {
    if (!currentHousehold) {
      setIsLoading(false);
      return;
    }

    const api = getApiClient();
    try {
      const [ordersData, vendorsData, tasksData] = await Promise.all([
        api.getWorkOrders(currentHousehold.id, { includeCompleted: showCompleted }),
        api.getHouseholdVendors(currentHousehold.id).catch(() => []),
        api.getMaintenanceTasks(currentHousehold.id, { status: 'PENDING' }).catch(() => []),
      ]);
      setWorkOrders(ordersData);
      setVendors(vendorsData);
      setMaintenanceTasks(tasksData);
    } catch (error: unknown) {
      if (error instanceof Error) {
        console.error('Failed to load work orders (network error):', error.message);
      } else {
        const err = error as { message?: string; statusCode?: number };
        console.error('Failed to load work orders:', err?.message || 'Unknown error', err?.statusCode || '');
      }
    } finally {
      setIsLoading(false);
    }
  }, [currentHousehold, showCompleted]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  // Filter work orders
  const filteredOrders = workOrders.filter((order) => {
    if (statusFilter !== 'ALL' && order.status !== statusFilter) return false;
    return true;
  });

  const getStatusBadge = (status: WorkOrderStatus) => {
    const styles: Record<string, string> = {
      DRAFT: 'badge-gray',
      REQUESTED: 'badge-blue',
      SCHEDULED: 'badge-yellow',
      IN_PROGRESS: 'badge-yellow',
      COMPLETED: 'badge-green',
      CANCELLED: 'badge-red',
    };
    return styles[status] || 'badge-gray';
  };

  const formatDate = (date: string | null | undefined) => {
    if (!date) return '-';
    return new Date(date).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
    });
  };

  const formatDateTime = (date: string | null | undefined) => {
    if (!date) return '-';
    return new Date(date).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
    });
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 dark:text-white">
            Work Orders
          </h1>
          <p className="text-slate-600 dark:text-slate-400 mt-1">
            Request and track vendor visits for your home
          </p>
        </div>
        <button
          onClick={() => setIsModalOpen(true)}
          className="btn btn-primary"
        >
          <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
          </svg>
          New Work Order
        </button>
      </div>

      {/* Filters */}
      <div className="card">
        <div className="flex flex-wrap gap-4 items-end">
          <div className="flex-1 min-w-[200px]">
            <label className="label block mb-1.5">Status</label>
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value as WorkOrderStatus | 'ALL')}
              className="input"
            >
              <option value="ALL">All Statuses</option>
              {STATUS_OPTIONS.map((status) => (
                <option key={status} value={status}>
                  {status.replace('_', ' ')}
                </option>
              ))}
            </select>
          </div>
          <div className="flex items-center gap-2">
            <input
              type="checkbox"
              id="showCompleted"
              checked={showCompleted}
              onChange={(e) => setShowCompleted(e.target.checked)}
              className="rounded border-slate-300 dark:border-slate-600"
            />
            <label htmlFor="showCompleted" className="text-sm text-slate-600 dark:text-slate-400">
              Show completed
            </label>
          </div>
        </div>
      </div>

      {/* Work Orders list */}
      {!currentHousehold ? (
        <div className="card text-center py-12">
          <svg className="w-16 h-16 mx-auto text-slate-300 dark:text-slate-600 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
          </svg>
          <p className="text-slate-500 dark:text-slate-400">
            Create a household to start managing work orders
          </p>
        </div>
      ) : filteredOrders.length === 0 ? (
        <div className="card text-center py-12">
          <svg className="w-16 h-16 mx-auto text-slate-300 dark:text-slate-600 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />
          </svg>
          <p className="text-slate-500 dark:text-slate-400 mb-4">
            {workOrders.length === 0
              ? 'No work orders yet'
              : 'No work orders match your filters'}
          </p>
          {workOrders.length === 0 && (
            <button
              onClick={() => setIsModalOpen(true)}
              className="btn btn-primary"
            >
              Create your first work order
            </button>
          )}
        </div>
      ) : (
        <div className="grid gap-4">
          {filteredOrders.map((order) => (
            <div
              key={order.id}
              className="card cursor-pointer hover:border-blue-500 dark:hover:border-blue-400 transition-colors"
              onClick={() => setSelectedOrder(order)}
            >
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <div className="flex items-center gap-3 mb-2">
                    <h3 className="font-semibold text-slate-900 dark:text-white">
                      {order.title}
                    </h3>
                    <span className={`badge ${getStatusBadge(order.status)}`}>
                      {order.status.replace('_', ' ')}
                    </span>
                  </div>
                  {order.description && (
                    <p className="text-sm text-slate-600 dark:text-slate-400 mb-3 line-clamp-2">
                      {order.description}
                    </p>
                  )}
                  <div className="flex flex-wrap gap-x-6 gap-y-2 text-sm">
                    {order.vendor && (
                      <div className="flex items-center gap-1.5 text-slate-600 dark:text-slate-400">
                        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
                        </svg>
                        <span>{order.vendor.displayName}</span>
                      </div>
                    )}
                    {order.scheduledStart ? (
                      <div className="flex items-center gap-1.5 text-slate-600 dark:text-slate-400">
                        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                        </svg>
                        <span>Scheduled: {formatDateTime(order.scheduledStart)}</span>
                      </div>
                    ) : order.preferredDate && (
                      <div className="flex items-center gap-1.5 text-slate-600 dark:text-slate-400">
                        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                        </svg>
                        <span>Preferred: {formatDate(order.preferredDate)}</span>
                      </div>
                    )}
                    {order.estimatedCost && (
                      <div className="flex items-center gap-1.5 text-slate-600 dark:text-slate-400">
                        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                        <span>${Number(order.estimatedCost).toFixed(2)}</span>
                      </div>
                    )}
                  </div>
                </div>
                <svg className="w-5 h-5 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                </svg>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* New Work Order Modal */}
      {isModalOpen && (
        <NewWorkOrderModal
          vendors={vendors}
          maintenanceTasks={maintenanceTasks}
          householdId={currentHousehold?.id || ''}
          onClose={() => setIsModalOpen(false)}
          onSuccess={() => {
            setIsModalOpen(false);
            loadData();
          }}
        />
      )}

      {/* Work Order Detail Modal */}
      {selectedOrder && (
        <WorkOrderDetailModal
          order={selectedOrder}
          onClose={() => setSelectedOrder(null)}
        />
      )}
    </div>
  );
}

// New Work Order Modal Component
function NewWorkOrderModal({
  vendors,
  maintenanceTasks,
  householdId,
  onClose,
  onSuccess,
}: {
  vendors: HouseholdVendor[];
  maintenanceTasks: MaintenanceTask[];
  householdId: string;
  onClose: () => void;
  onSuccess: () => void;
}) {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [maintenanceTaskId, setMaintenanceTaskId] = useState('');
  const [vendorId, setVendorId] = useState('');
  const [preferredDate, setPreferredDate] = useState('');
  const [preferredTimeStart, setPreferredTimeStart] = useState('');
  const [preferredTimeEnd, setPreferredTimeEnd] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');

  // Auto-fill title from maintenance task
  useEffect(() => {
    if (maintenanceTaskId) {
      const task = maintenanceTasks.find((t) => t.id === maintenanceTaskId);
      if (task && !title) {
        setTitle(task.title);
        if (task.description && !description) {
          setDescription(task.description);
        }
      }
    }
  }, [maintenanceTaskId, maintenanceTasks, title, description]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setIsSubmitting(true);

    try {
      const api = getApiClient();
      const data: CreateWorkOrderRequest = {
        title,
        description: description || undefined,
        maintenanceTaskId: maintenanceTaskId || undefined,
        vendorId: vendorId || undefined,
        preferredDate: preferredDate || undefined,
        preferredTimeWindowStart: preferredTimeStart || undefined,
        preferredTimeWindowEnd: preferredTimeEnd || undefined,
      };

      await api.createWorkOrder(householdId, data);
      onSuccess();
    } catch (err: unknown) {
      const message =
        err && typeof err === 'object' && 'message' in err
          ? (err as { message: string }).message
          : 'Failed to create work order. Please try again.';
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
              Request Vendor Visit
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

            {maintenanceTasks.length > 0 && (
              <div>
                <label htmlFor="maintenanceTask" className="label block mb-1.5">
                  Link to Maintenance Task (optional)
                </label>
                <select
                  id="maintenanceTask"
                  value={maintenanceTaskId}
                  onChange={(e) => setMaintenanceTaskId(e.target.value)}
                  className="input"
                >
                  <option value="">Select a task (optional)</option>
                  {maintenanceTasks.map((task) => (
                    <option key={task.id} value={task.id}>
                      {task.title}
                    </option>
                  ))}
                </select>
              </div>
            )}

            <div>
              <label htmlFor="title" className="label block mb-1.5">
                Title <span className="text-red-500">*</span>
              </label>
              <input
                id="title"
                type="text"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                className="input"
                placeholder="e.g., HVAC Maintenance Visit"
                required
              />
            </div>

            <div>
              <label htmlFor="description" className="label block mb-1.5">
                Description
              </label>
              <textarea
                id="description"
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                className="input min-h-[80px]"
                placeholder="Additional details for the vendor..."
              />
            </div>

            {vendors.length > 0 && (
              <div>
                <label htmlFor="vendor" className="label block mb-1.5">
                  Preferred Vendor (optional)
                </label>
                <select
                  id="vendor"
                  value={vendorId}
                  onChange={(e) => setVendorId(e.target.value)}
                  className="input"
                >
                  <option value="">Haven will find a vendor</option>
                  {vendors.map((vendor) => (
                    <option key={vendor.id} value={vendor.id}>
                      {vendor.displayName}
                    </option>
                  ))}
                </select>
              </div>
            )}

            <div>
              <label htmlFor="preferredDate" className="label block mb-1.5">
                Preferred Date
              </label>
              <input
                id="preferredDate"
                type="date"
                value={preferredDate}
                onChange={(e) => setPreferredDate(e.target.value)}
                className="input"
                min={new Date().toISOString().split('T')[0]}
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label htmlFor="preferredTimeStart" className="label block mb-1.5">
                  Time Window Start
                </label>
                <input
                  id="preferredTimeStart"
                  type="time"
                  value={preferredTimeStart}
                  onChange={(e) => setPreferredTimeStart(e.target.value)}
                  className="input"
                />
              </div>
              <div>
                <label htmlFor="preferredTimeEnd" className="label block mb-1.5">
                  Time Window End
                </label>
                <input
                  id="preferredTimeEnd"
                  type="time"
                  value={preferredTimeEnd}
                  onChange={(e) => setPreferredTimeEnd(e.target.value)}
                  className="input"
                />
              </div>
            </div>

            {/* Footer */}
            <div className="flex items-center justify-end gap-3 pt-4">
              <button type="button" onClick={onClose} className="btn btn-secondary">
                Cancel
              </button>
              <button
                type="submit"
                disabled={isSubmitting}
                className="btn btn-primary"
              >
                {isSubmitting ? (
                  <>
                    <svg className="animate-spin -ml-1 mr-2 h-4 w-4" fill="none" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                    </svg>
                    Submitting...
                  </>
                ) : (
                  'Request Visit'
                )}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}

// Work Order Detail Modal Component
function WorkOrderDetailModal({
  order,
  onClose,
}: {
  order: WorkOrder;
  onClose: () => void;
}) {
  const getStatusBadge = (status: WorkOrderStatus) => {
    const styles: Record<string, string> = {
      DRAFT: 'badge-gray',
      REQUESTED: 'badge-blue',
      SCHEDULED: 'badge-yellow',
      IN_PROGRESS: 'badge-yellow',
      COMPLETED: 'badge-green',
      CANCELLED: 'badge-red',
    };
    return styles[status] || 'badge-gray';
  };

  const formatDateTime = (date: string | null | undefined) => {
    if (!date) return '-';
    return new Date(date).toLocaleDateString('en-US', {
      weekday: 'long',
      month: 'long',
      day: 'numeric',
      year: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
    });
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
            <div>
              <h2 className="text-lg font-semibold text-slate-900 dark:text-white">
                {order.title}
              </h2>
              <span className={`badge ${getStatusBadge(order.status)} mt-1`}>
                {order.status.replace('_', ' ')}
              </span>
            </div>
            <button
              onClick={onClose}
              className="p-1 text-slate-400 hover:text-slate-500 dark:hover:text-slate-300"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          {/* Content */}
          <div className="p-6 space-y-4">
            {order.description && (
              <div>
                <label className="label block mb-1">Description</label>
                <p className="text-slate-700 dark:text-slate-300">{order.description}</p>
              </div>
            )}

            {order.vendor && (
              <div>
                <label className="label block mb-1">Vendor</label>
                <p className="text-slate-700 dark:text-slate-300">{order.vendor.displayName}</p>
                {order.vendor.phone && (
                  <p className="text-sm text-slate-500 dark:text-slate-400">{order.vendor.phone}</p>
                )}
              </div>
            )}

            {order.scheduledStart && (
              <div>
                <label className="label block mb-1">Scheduled Visit</label>
                <p className="text-slate-700 dark:text-slate-300">
                  {formatDateTime(order.scheduledStart)}
                  {order.scheduledEnd && (
                    <span className="text-slate-500"> - {new Date(order.scheduledEnd).toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' })}</span>
                  )}
                </p>
              </div>
            )}

            {order.preferredDate && !order.scheduledStart && (
              <div>
                <label className="label block mb-1">Preferred Date</label>
                <p className="text-slate-700 dark:text-slate-300">
                  {new Date(order.preferredDate).toLocaleDateString('en-US', {
                    weekday: 'long',
                    month: 'long',
                    day: 'numeric',
                    year: 'numeric',
                  })}
                  {order.preferredTimeWindowStart && order.preferredTimeWindowEnd && (
                    <span className="text-slate-500"> ({order.preferredTimeWindowStart} - {order.preferredTimeWindowEnd})</span>
                  )}
                </p>
              </div>
            )}

            {order.maintenanceTask && (
              <div>
                <label className="label block mb-1">Related Maintenance Task</label>
                <p className="text-slate-700 dark:text-slate-300">{order.maintenanceTask.title}</p>
                <span className={`badge ${order.maintenanceTask.status === 'COMPLETED' ? 'badge-green' : 'badge-gray'} mt-1`}>
                  {order.maintenanceTask.status}
                </span>
              </div>
            )}

            <div className="grid grid-cols-2 gap-4">
              {order.estimatedCost !== null && order.estimatedCost !== undefined && (
                <div>
                  <label className="label block mb-1">Estimated Cost</label>
                  <p className="text-slate-700 dark:text-slate-300">${Number(order.estimatedCost).toFixed(2)}</p>
                </div>
              )}
              {order.actualCost !== null && order.actualCost !== undefined && (
                <div>
                  <label className="label block mb-1">Actual Cost</label>
                  <p className="text-slate-700 dark:text-slate-300">${Number(order.actualCost).toFixed(2)}</p>
                </div>
              )}
            </div>

            {order.completedAt && (
              <div>
                <label className="label block mb-1">Completed</label>
                <p className="text-slate-700 dark:text-slate-300">{formatDateTime(order.completedAt)}</p>
              </div>
            )}

            <div className="text-sm text-slate-500 dark:text-slate-400 pt-4 border-t border-slate-200 dark:border-slate-700">
              Created on {new Date(order.createdAt).toLocaleDateString('en-US', {
                month: 'long',
                day: 'numeric',
                year: 'numeric',
              })}
            </div>
          </div>

          {/* Footer */}
          <div className="flex items-center justify-end gap-3 p-6 border-t border-slate-200 dark:border-slate-700">
            <button onClick={onClose} className="btn btn-secondary">
              Close
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
