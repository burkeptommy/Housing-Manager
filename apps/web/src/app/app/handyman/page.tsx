'use client';

import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '@/contexts/auth-context';
import { getApiClient } from '@/lib/api';
import type { HandymanDashboard } from '@haven/core';

const STATUS_COLORS: Record<string, string> = {
  ASSIGNED: 'bg-purple-100 text-purple-700',
  IN_PROGRESS: 'bg-orange-100 text-orange-700',
  COMPLETED: 'bg-green-100 text-green-700',
};

export default function HandymanPage() {
  const { user } = useAuth();
  const [dashboard, setDashboard] = useState<HandymanDashboard | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isCheckingIn, setIsCheckingIn] = useState<string | null>(null);
  const [isCheckingOut, setIsCheckingOut] = useState<string | null>(null);
  const [checkoutModal, setCheckoutModal] = useState<{ workOrderId: string; title: string } | null>(null);
  const [rejectModal, setRejectModal] = useState<{ workOrderId: string; title: string } | null>(null);
  const [checkoutData, setCheckoutData] = useState({ hoursWorked: '', notes: '' });
  const [rejectReason, setRejectReason] = useState('');
  const [actionError, setActionError] = useState<string | null>(null);

  const loadDashboard = useCallback(async () => {
    try {
      const api = getApiClient();
      const data = await api.getHandymanDashboard();
      setDashboard(data);
      setError(null);
    } catch (err) {
      console.error('Failed to load handyman dashboard:', err);
      setError('Failed to load dashboard. Please try again.');
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    loadDashboard();
  }, [loadDashboard]);

  const handleCheckIn = async (workOrderId: string) => {
    setIsCheckingIn(workOrderId);
    setActionError(null);

    try {
      // Get current location
      const position = await new Promise<GeolocationPosition>((resolve, reject) => {
        navigator.geolocation.getCurrentPosition(resolve, reject, {
          enableHighAccuracy: true,
          timeout: 10000,
        });
      });

      const api = getApiClient();
      await api.handymanCheckIn({
        workOrderId,
        latitude: position.coords.latitude,
        longitude: position.coords.longitude,
      });

      // Refresh dashboard
      await loadDashboard();
    } catch (err) {
      console.error('Failed to check in:', err);
      setActionError('Failed to check in. Please ensure location services are enabled.');
    } finally {
      setIsCheckingIn(null);
    }
  };

  const handleCheckOut = async () => {
    if (!checkoutModal) return;

    setIsCheckingOut(checkoutModal.workOrderId);
    setActionError(null);

    try {
      const api = getApiClient();
      await api.handymanCheckOut({
        workOrderId: checkoutModal.workOrderId,
        hoursWorked: checkoutData.hoursWorked ? parseFloat(checkoutData.hoursWorked) : undefined,
        notes: checkoutData.notes || undefined,
      });

      setCheckoutModal(null);
      setCheckoutData({ hoursWorked: '', notes: '' });

      // Refresh dashboard
      await loadDashboard();
    } catch (err) {
      console.error('Failed to check out:', err);
      setActionError('Failed to check out. Please try again.');
    } finally {
      setIsCheckingOut(null);
    }
  };

  const handleReject = async () => {
    if (!rejectModal || !rejectReason.trim()) return;

    setActionError(null);

    try {
      const api = getApiClient();
      await api.handymanRejectRequest({
        workOrderId: rejectModal.workOrderId,
        reason: rejectReason.trim(),
      });

      setRejectModal(null);
      setRejectReason('');

      // Refresh dashboard
      await loadDashboard();
    } catch (err) {
      console.error('Failed to reject request:', err);
      setActionError('Failed to reject request. Please try again.');
    }
  };

  const formatDate = (dateStr: string | null) => {
    if (!dateStr) return 'TBD';
    return new Date(dateStr).toLocaleDateString('en-US', {
      weekday: 'short',
      month: 'short',
      day: 'numeric',
    });
  };

  const formatTime = (dateStr: string | null) => {
    if (!dateStr) return '';
    return new Date(dateStr).toLocaleTimeString('en-US', {
      hour: 'numeric',
      minute: '2-digit',
    });
  };

  if (user?.role !== 'HANDYMAN') {
    return (
      <div className="flex items-center justify-center h-64">
        <p className="text-slate-600 dark:text-slate-400">This page is only accessible to handymen.</p>
      </div>
    );
  }

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-600"></div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center h-64 gap-4">
        <p className="text-red-600 dark:text-red-400">{error}</p>
        <button
          onClick={loadDashboard}
          className="px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition-colors"
        >
          Retry
        </button>
      </div>
    );
  }

  if (!dashboard) return null;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-slate-900 dark:text-white">My Jobs</h1>
        <p className="text-slate-600 dark:text-slate-400">
          Welcome back, {dashboard.handymanName}
        </p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="card">
          <p className="text-sm text-slate-500 dark:text-slate-400">Pending Tasks</p>
          <p className="text-3xl font-bold text-slate-900 dark:text-white">{dashboard.stats.pendingTasks}</p>
        </div>
        <div className="card">
          <p className="text-sm text-slate-500 dark:text-slate-400">Completed This Month</p>
          <p className="text-3xl font-bold text-green-600">{dashboard.stats.completedThisMonth}</p>
        </div>
        <div className="card">
          <p className="text-sm text-slate-500 dark:text-slate-400">Hours This Month</p>
          <p className="text-3xl font-bold text-emerald-600">{dashboard.stats.hoursThisMonth.toFixed(1)}</p>
        </div>
      </div>

      {/* Action Error */}
      {actionError && (
        <div className="p-4 bg-red-50 dark:bg-red-900/20 rounded-lg border border-red-200 dark:border-red-800">
          <p className="text-sm text-red-600 dark:text-red-400">{actionError}</p>
        </div>
      )}

      {/* Today's Tasks */}
      <div className="space-y-4">
        <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Today&apos;s Tasks</h2>

        {dashboard.todaysTasks.length === 0 ? (
          <div className="card text-center py-8">
            <svg className="w-12 h-12 mx-auto text-slate-400 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />
            </svg>
            <p className="text-slate-600 dark:text-slate-400">No tasks scheduled for today</p>
          </div>
        ) : (
          <div className="space-y-3">
            {dashboard.todaysTasks.map((task) => (
              <div key={task.id} className="card">
                <div className="flex items-center justify-between">
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-1">
                      <h3 className="font-semibold text-slate-900 dark:text-white">{task.title}</h3>
                      <span className={`px-2 py-0.5 rounded text-xs font-medium ${STATUS_COLORS[task.status] || 'bg-slate-100 text-slate-600'}`}>
                        {task.status.replace('_', ' ')}
                      </span>
                    </div>
                    <p className="text-sm text-slate-600 dark:text-slate-400">{task.householdName}</p>
                    {task.address && (
                      <p className="text-sm text-slate-500 dark:text-slate-400">{task.address}</p>
                    )}
                    {task.scheduledStart && (
                      <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
                        Scheduled: {formatTime(task.scheduledStart)}
                      </p>
                    )}
                  </div>
                  <div className="flex gap-2">
                    {task.status === 'ASSIGNED' && (
                      <>
                        <button
                          onClick={() => setRejectModal({ workOrderId: task.id, title: task.title })}
                          className="px-3 py-1.5 text-sm text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
                        >
                          Decline
                        </button>
                        <button
                          onClick={() => handleCheckIn(task.id)}
                          disabled={isCheckingIn === task.id}
                          className="px-4 py-1.5 text-sm bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors disabled:opacity-50"
                        >
                          {isCheckingIn === task.id ? 'Checking In...' : 'Check In'}
                        </button>
                      </>
                    )}
                    {task.status === 'IN_PROGRESS' && (
                      <button
                        onClick={() => setCheckoutModal({ workOrderId: task.id, title: task.title })}
                        className="px-4 py-1.5 text-sm bg-orange-600 text-white rounded-lg hover:bg-orange-700 transition-colors"
                      >
                        Complete
                      </button>
                    )}
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Upcoming Tasks */}
      <div className="space-y-4">
        <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Upcoming Tasks</h2>

        {dashboard.upcomingTasks.length === 0 ? (
          <div className="card text-center py-8">
            <p className="text-slate-600 dark:text-slate-400">No upcoming tasks in the next 7 days</p>
          </div>
        ) : (
          <div className="space-y-3">
            {dashboard.upcomingTasks.map((task) => (
              <div key={task.id} className="card">
                <div className="flex items-center justify-between">
                  <div>
                    <div className="flex items-center gap-2 mb-1">
                      <h3 className="font-semibold text-slate-900 dark:text-white">{task.title}</h3>
                      <span className={`px-2 py-0.5 rounded text-xs font-medium ${STATUS_COLORS[task.status] || 'bg-slate-100 text-slate-600'}`}>
                        {task.status.replace('_', ' ')}
                      </span>
                    </div>
                    <p className="text-sm text-slate-600 dark:text-slate-400">{task.householdName}</p>
                    {task.scheduledStart && (
                      <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
                        {formatDate(task.scheduledStart)} at {formatTime(task.scheduledStart)}
                      </p>
                    )}
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Assigned Households */}
      <div className="space-y-4">
        <h2 className="text-lg font-semibold text-slate-900 dark:text-white">My Households</h2>

        {dashboard.assignedHouseholds.length === 0 ? (
          <div className="card text-center py-8">
            <p className="text-slate-600 dark:text-slate-400">No households assigned yet</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {dashboard.assignedHouseholds.map((household) => (
              <div key={household.id} className="card">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-full bg-emerald-100 dark:bg-emerald-900/50 flex items-center justify-center">
                    <svg className="w-5 h-5 text-emerald-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
                    </svg>
                  </div>
                  <div className="flex-1">
                    <h3 className="font-semibold text-slate-900 dark:text-white">{household.name}</h3>
                    {household.address && (
                      <p className="text-sm text-slate-500 dark:text-slate-400">{household.address}</p>
                    )}
                    {household.monthlyVisitDay && household.conciergeEnabled && (
                      <p className="text-xs text-emerald-600 dark:text-emerald-400 mt-1">
                        Monthly visit: Day {household.monthlyVisitDay}
                      </p>
                    )}
                  </div>
                  {household.conciergeEnabled ? (
                    <span className="px-2 py-0.5 rounded text-xs font-medium bg-green-100 text-green-700">
                      Active
                    </span>
                  ) : (
                    <span className="px-2 py-0.5 rounded text-xs font-medium bg-slate-100 text-slate-600">
                      Inactive
                    </span>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Checkout Modal */}
      {checkoutModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white dark:bg-slate-800 rounded-xl max-w-md w-full">
            <div className="p-6">
              <h2 className="text-xl font-bold text-slate-900 dark:text-white mb-4">Complete Task</h2>
              <p className="text-slate-600 dark:text-slate-400 mb-4">{checkoutModal.title}</p>

              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Hours Worked
                  </label>
                  <input
                    type="number"
                    step="0.25"
                    min="0"
                    value={checkoutData.hoursWorked}
                    onChange={(e) => setCheckoutData({ ...checkoutData, hoursWorked: e.target.value })}
                    className="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-white"
                    placeholder="e.g., 1.5"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Notes (Optional)
                  </label>
                  <textarea
                    value={checkoutData.notes}
                    onChange={(e) => setCheckoutData({ ...checkoutData, notes: e.target.value })}
                    className="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-white"
                    rows={3}
                    placeholder="Any notes about the work completed..."
                  />
                </div>
              </div>

              <div className="flex gap-3 mt-6">
                <button
                  onClick={() => {
                    setCheckoutModal(null);
                    setCheckoutData({ hoursWorked: '', notes: '' });
                  }}
                  className="flex-1 px-4 py-2 border border-slate-300 dark:border-slate-600 text-slate-700 dark:text-slate-300 rounded-lg hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors"
                >
                  Cancel
                </button>
                <button
                  onClick={handleCheckOut}
                  disabled={isCheckingOut === checkoutModal.workOrderId}
                  className="flex-1 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors disabled:opacity-50"
                >
                  {isCheckingOut === checkoutModal.workOrderId ? 'Completing...' : 'Mark Complete'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Reject Modal */}
      {rejectModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white dark:bg-slate-800 rounded-xl max-w-md w-full">
            <div className="p-6">
              <h2 className="text-xl font-bold text-slate-900 dark:text-white mb-4">Decline Task</h2>
              <p className="text-slate-600 dark:text-slate-400 mb-4">{rejectModal.title}</p>

              <div>
                <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                  Reason for declining
                </label>
                <textarea
                  value={rejectReason}
                  onChange={(e) => setRejectReason(e.target.value)}
                  className="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-white"
                  rows={3}
                  placeholder="Please provide a reason..."
                  required
                />
              </div>

              <div className="flex gap-3 mt-6">
                <button
                  onClick={() => {
                    setRejectModal(null);
                    setRejectReason('');
                  }}
                  className="flex-1 px-4 py-2 border border-slate-300 dark:border-slate-600 text-slate-700 dark:text-slate-300 rounded-lg hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors"
                >
                  Cancel
                </button>
                <button
                  onClick={handleReject}
                  disabled={!rejectReason.trim()}
                  className="flex-1 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors disabled:opacity-50"
                >
                  Decline Task
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
