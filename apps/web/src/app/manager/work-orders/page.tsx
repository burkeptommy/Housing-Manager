'use client';

import { useState, useEffect, useCallback } from 'react';
import { getApiClient } from '@/lib/api';
import type { WorkOrder, WorkOrderStatus, UpdateWorkOrderRequest } from '@haven/core';

const STATUS_OPTIONS: WorkOrderStatus[] = ['DRAFT', 'REQUESTED', 'SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'];

const STATUS_COLORS: Record<string, string> = {
  DRAFT: 'bg-slate-100 text-slate-700 dark:bg-slate-700 dark:text-slate-400',
  REQUESTED: 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400',
  SCHEDULED: 'bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-400',
  IN_PROGRESS: 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400',
  COMPLETED: 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400',
  CANCELLED: 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400',
};

export default function ManagerWorkOrdersPage() {
  const [workOrders, setWorkOrders] = useState<WorkOrder[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [selectedOrder, setSelectedOrder] = useState<WorkOrder | null>(null);

  // Filters
  const [statusFilter, setStatusFilter] = useState<WorkOrderStatus | 'ALL'>('ALL');
  const [showUnassigned, setShowUnassigned] = useState(false);
  const [showUpcoming, setShowUpcoming] = useState(false);

  const loadData = useCallback(async () => {
    const api = getApiClient();
    try {
      const ordersData = await api.getInternalWorkOrders({
        status: statusFilter !== 'ALL' ? statusFilter : undefined,
        unassigned: showUnassigned || undefined,
        upcoming: showUpcoming || undefined,
      });
      setWorkOrders(ordersData);
    } catch (error) {
      console.error('Failed to load work orders:', error);
    } finally {
      setIsLoading(false);
    }
  }, [statusFilter, showUnassigned, showUpcoming]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  // Group orders by status
  const groupedOrders = {
    requested: workOrders.filter((o) => o.status === 'REQUESTED'),
    scheduled: workOrders.filter((o) => o.status === 'SCHEDULED'),
    inProgress: workOrders.filter((o) => o.status === 'IN_PROGRESS'),
    completed: workOrders.filter((o) => o.status === 'COMPLETED'),
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
      hour: 'numeric',
      minute: '2-digit',
    });
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
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 dark:text-white">
            Work Orders
          </h1>
          <p className="text-slate-600 dark:text-slate-400 mt-1">
            Manage vendor visits for all households
          </p>
        </div>
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
          <div className="flex items-center gap-4">
            <label className="flex items-center gap-2">
              <input
                type="checkbox"
                checked={showUnassigned}
                onChange={(e) => setShowUnassigned(e.target.checked)}
                className="rounded border-slate-300 dark:border-slate-600"
              />
              <span className="text-sm text-slate-600 dark:text-slate-400">Unassigned only</span>
            </label>
            <label className="flex items-center gap-2">
              <input
                type="checkbox"
                checked={showUpcoming}
                onChange={(e) => setShowUpcoming(e.target.checked)}
                className="rounded border-slate-300 dark:border-slate-600"
              />
              <span className="text-sm text-slate-600 dark:text-slate-400">Upcoming (7 days)</span>
            </label>
          </div>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div className="card bg-blue-50 dark:bg-blue-900/20 border-blue-200 dark:border-blue-800">
          <p className="text-sm text-blue-600 dark:text-blue-400 font-medium">New Requests</p>
          <p className="text-2xl font-bold text-blue-700 dark:text-blue-300">{groupedOrders.requested.length}</p>
        </div>
        <div className="card bg-purple-50 dark:bg-purple-900/20 border-purple-200 dark:border-purple-800">
          <p className="text-sm text-purple-600 dark:text-purple-400 font-medium">Scheduled</p>
          <p className="text-2xl font-bold text-purple-700 dark:text-purple-300">{groupedOrders.scheduled.length}</p>
        </div>
        <div className="card bg-yellow-50 dark:bg-yellow-900/20 border-yellow-200 dark:border-yellow-800">
          <p className="text-sm text-yellow-600 dark:text-yellow-400 font-medium">In Progress</p>
          <p className="text-2xl font-bold text-yellow-700 dark:text-yellow-300">{groupedOrders.inProgress.length}</p>
        </div>
        <div className="card bg-green-50 dark:bg-green-900/20 border-green-200 dark:border-green-800">
          <p className="text-sm text-green-600 dark:text-green-400 font-medium">Completed</p>
          <p className="text-2xl font-bold text-green-700 dark:text-green-300">{groupedOrders.completed.length}</p>
        </div>
      </div>

      {/* Work Orders Table */}
      {workOrders.length === 0 ? (
        <div className="card text-center py-12">
          <svg className="w-16 h-16 mx-auto text-slate-300 dark:text-slate-600 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />
          </svg>
          <p className="text-slate-500 dark:text-slate-400">
            No work orders match your filters
          </p>
        </div>
      ) : (
        <div className="card p-0 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-slate-50 dark:bg-slate-700/50 border-b border-slate-200 dark:border-slate-700">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                    Work Order
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                    Household
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                    Vendor
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                    Status
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                    Scheduled
                  </th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-200 dark:divide-slate-700">
                {workOrders.map((order) => (
                  <tr key={order.id} className="hover:bg-slate-50 dark:hover:bg-slate-700/30">
                    <td className="px-6 py-4">
                      <div>
                        <p className="font-medium text-slate-900 dark:text-white">
                          {order.title}
                        </p>
                        {order.description && (
                          <p className="text-sm text-slate-500 dark:text-slate-400 line-clamp-1">
                            {order.description}
                          </p>
                        )}
                      </div>
                    </td>
                    <td className="px-6 py-4 text-sm text-slate-600 dark:text-slate-400">
                      {order.household?.name || '-'}
                    </td>
                    <td className="px-6 py-4 text-sm text-slate-600 dark:text-slate-400">
                      {order.vendor?.displayName || (
                        <span className="text-amber-600 dark:text-amber-400">Unassigned</span>
                      )}
                    </td>
                    <td className="px-6 py-4">
                      <span className={`text-xs font-medium px-2 py-1 rounded ${STATUS_COLORS[order.status]}`}>
                        {order.status.replace('_', ' ')}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-sm text-slate-600 dark:text-slate-400">
                      {order.scheduledStart ? formatDateTime(order.scheduledStart) : (
                        order.preferredDate ? (
                          <span className="text-slate-400">Pref: {formatDate(order.preferredDate)}</span>
                        ) : '-'
                      )}
                    </td>
                    <td className="px-6 py-4 text-right">
                      <button
                        onClick={() => setSelectedOrder(order)}
                        className="text-emerald-600 hover:text-emerald-500 dark:text-emerald-400 text-sm font-medium"
                      >
                        Manage
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Work Order Management Modal */}
      {selectedOrder && (
        <WorkOrderManageModal
          order={selectedOrder}
          onClose={() => setSelectedOrder(null)}
          onUpdate={() => {
            setSelectedOrder(null);
            loadData();
          }}
        />
      )}
    </div>
  );
}

// Work Order Management Modal
function WorkOrderManageModal({
  order,
  onClose,
  onUpdate,
}: {
  order: WorkOrder;
  onClose: () => void;
  onUpdate: () => void;
}) {
  const [status, setStatus] = useState<WorkOrderStatus>(order.status);
  const [scheduledStart, setScheduledStart] = useState(
    order.scheduledStart ? new Date(order.scheduledStart).toISOString().slice(0, 16) : ''
  );
  const [scheduledEnd, setScheduledEnd] = useState(
    order.scheduledEnd ? new Date(order.scheduledEnd).toISOString().slice(0, 16) : ''
  );
  const [estimatedCost, setEstimatedCost] = useState(
    order.estimatedCost !== null ? String(order.estimatedCost) : ''
  );
  const [actualCost, setActualCost] = useState(
    order.actualCost !== null ? String(order.actualCost) : ''
  );
  const [note, setNote] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setIsSubmitting(true);

    try {
      const api = getApiClient();
      const updates: UpdateWorkOrderRequest = {
        status,
        scheduledStart: scheduledStart || undefined,
        scheduledEnd: scheduledEnd || undefined,
        estimatedCost: estimatedCost ? parseFloat(estimatedCost) : undefined,
        actualCost: actualCost ? parseFloat(actualCost) : undefined,
      };

      await api.updateInternalWorkOrder(order.id, updates);

      // Add note if provided
      if (note.trim()) {
        await api.addWorkOrderNote(order.id, { body: note.trim() });
      }

      onUpdate();
    } catch (err: unknown) {
      const message =
        err && typeof err === 'object' && 'message' in err
          ? (err as { message: string }).message
          : 'Failed to update work order';
      setError(message);
      setIsSubmitting(false);
    }
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
        <div className="relative w-full max-w-2xl bg-white dark:bg-slate-800 rounded-xl shadow-xl">
          {/* Header */}
          <div className="flex items-center justify-between p-6 border-b border-slate-200 dark:border-slate-700">
            <div>
              <h2 className="text-lg font-semibold text-slate-900 dark:text-white">
                Manage Work Order
              </h2>
              <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
                {order.title}
              </p>
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

          {/* Order Details */}
          <div className="p-6 border-b border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-700/50">
            <div className="grid grid-cols-2 gap-4 text-sm">
              <div>
                <span className="text-slate-500 dark:text-slate-400">Household:</span>
                <span className="ml-2 text-slate-900 dark:text-white">{order.household?.name}</span>
              </div>
              <div>
                <span className="text-slate-500 dark:text-slate-400">Vendor:</span>
                <span className="ml-2 text-slate-900 dark:text-white">
                  {order.vendor?.displayName || 'Unassigned'}
                </span>
              </div>
              {order.preferredDate && (
                <div>
                  <span className="text-slate-500 dark:text-slate-400">Preferred Date:</span>
                  <span className="ml-2 text-slate-900 dark:text-white">
                    {new Date(order.preferredDate).toLocaleDateString()}
                    {order.preferredTimeWindowStart && ` ${order.preferredTimeWindowStart}`}
                    {order.preferredTimeWindowEnd && ` - ${order.preferredTimeWindowEnd}`}
                  </span>
                </div>
              )}
              {order.maintenanceTask && (
                <div>
                  <span className="text-slate-500 dark:text-slate-400">Linked Task:</span>
                  <span className="ml-2 text-slate-900 dark:text-white">{order.maintenanceTask.title}</span>
                </div>
              )}
              <div className="col-span-2">
                <span className="text-slate-500 dark:text-slate-400">Created:</span>
                <span className="ml-2 text-slate-900 dark:text-white">{formatDateTime(order.createdAt)}</span>
              </div>
            </div>
            {order.description && (
              <div className="mt-3 pt-3 border-t border-slate-200 dark:border-slate-600">
                <p className="text-sm text-slate-600 dark:text-slate-300">{order.description}</p>
              </div>
            )}
          </div>

          {/* Form */}
          <form onSubmit={handleSubmit} className="p-6 space-y-4">
            {error && (
              <div className="p-3 rounded-lg bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800">
                <p className="text-sm text-red-600 dark:text-red-400">{error}</p>
              </div>
            )}

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label htmlFor="status" className="label block mb-1.5">
                  Status
                </label>
                <select
                  id="status"
                  value={status}
                  onChange={(e) => setStatus(e.target.value as WorkOrderStatus)}
                  className="input"
                >
                  {STATUS_OPTIONS.map((s) => (
                    <option key={s} value={s}>
                      {s.replace('_', ' ')}
                    </option>
                  ))}
                </select>
              </div>
              <div />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label htmlFor="scheduledStart" className="label block mb-1.5">
                  Scheduled Start
                </label>
                <input
                  id="scheduledStart"
                  type="datetime-local"
                  value={scheduledStart}
                  onChange={(e) => setScheduledStart(e.target.value)}
                  className="input"
                />
              </div>
              <div>
                <label htmlFor="scheduledEnd" className="label block mb-1.5">
                  Scheduled End
                </label>
                <input
                  id="scheduledEnd"
                  type="datetime-local"
                  value={scheduledEnd}
                  onChange={(e) => setScheduledEnd(e.target.value)}
                  className="input"
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label htmlFor="estimatedCost" className="label block mb-1.5">
                  Estimated Cost ($)
                </label>
                <input
                  id="estimatedCost"
                  type="number"
                  step="0.01"
                  min="0"
                  value={estimatedCost}
                  onChange={(e) => setEstimatedCost(e.target.value)}
                  className="input"
                  placeholder="0.00"
                />
              </div>
              <div>
                <label htmlFor="actualCost" className="label block mb-1.5">
                  Actual Cost ($)
                </label>
                <input
                  id="actualCost"
                  type="number"
                  step="0.01"
                  min="0"
                  value={actualCost}
                  onChange={(e) => setActualCost(e.target.value)}
                  className="input"
                  placeholder="0.00"
                />
              </div>
            </div>

            <div>
              <label htmlFor="note" className="label block mb-1.5">
                Add Internal Note
              </label>
              <textarea
                id="note"
                value={note}
                onChange={(e) => setNote(e.target.value)}
                className="input min-h-[80px]"
                placeholder="Add a note about this work order..."
              />
            </div>

            {/* Existing Notes */}
            {order.notes && order.notes.length > 0 && (
              <div className="border-t border-slate-200 dark:border-slate-700 pt-4">
                <h4 className="font-medium text-slate-900 dark:text-white mb-3">Notes</h4>
                <div className="space-y-2">
                  {order.notes.map((n) => (
                    <div key={n.id} className="p-3 bg-slate-50 dark:bg-slate-700/50 rounded-lg">
                      <p className="text-sm text-slate-600 dark:text-slate-300">{n.body}</p>
                      <p className="text-xs text-slate-400 mt-1">
                        {n.author?.firstName} {n.author?.lastName} &mdash;{' '}
                        {new Date(n.createdAt).toLocaleString()}
                      </p>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Footer */}
            <div className="flex items-center justify-end gap-3 pt-4">
              <button type="button" onClick={onClose} className="btn btn-secondary">
                Cancel
              </button>
              <button
                type="submit"
                disabled={isSubmitting}
                className="btn btn-primary bg-emerald-600 hover:bg-emerald-700"
              >
                {isSubmitting ? (
                  <>
                    <svg className="animate-spin -ml-1 mr-2 h-4 w-4" fill="none" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                    </svg>
                    Saving...
                  </>
                ) : (
                  'Save Changes'
                )}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}
