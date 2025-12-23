'use client';

import { useState, useEffect, useCallback } from 'react';
import Link from 'next/link';
import type { HandymanDashboard, HandymanTask } from '@haven/core';
import { getApiClient } from '@/lib/api';

// Status colors for work orders
const STATUS_COLORS: Record<string, string> = {
  OPEN: 'bg-yellow-100 text-yellow-700',
  ASSIGNED: 'bg-purple-100 text-purple-700',
  IN_PROGRESS: 'bg-orange-100 text-orange-700',
  COMPLETED: 'bg-green-100 text-green-700',
  VERIFIED: 'bg-emerald-100 text-emerald-700',
};

export default function HandymanDashboardPage() {
  const [dashboard, setDashboard] = useState<HandymanDashboard | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [activeTask, setActiveTask] = useState<HandymanTask | null>(null);
  const [checkInTime, setCheckInTime] = useState<Date | null>(null);
  const [isCheckingIn, setIsCheckingIn] = useState(false);
  const [isCheckingOut, setIsCheckingOut] = useState(false);
  const [showCheckOutModal, setShowCheckOutModal] = useState(false);
  const [checkOutNotes, setCheckOutNotes] = useState('');
  const [checkOutHours, setCheckOutHours] = useState('');

  const loadDashboard = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const api = getApiClient();
      const data = await api.getHandymanDashboard();
      setDashboard(data);
      // If there's an active task from the API, set it
      if (data.activeTask) {
        setActiveTask(data.activeTask);
        if (data.activeTask.checkedInAt) {
          setCheckInTime(new Date(data.activeTask.checkedInAt));
        }
      }
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

  const handleCheckIn = async (taskId: string) => {
    setIsCheckingIn(true);

    // Request geolocation
    if ('geolocation' in navigator) {
      navigator.geolocation.getCurrentPosition(
        async (position) => {
          try {
            const api = getApiClient();
            await api.handymanCheckIn({
              workOrderId: taskId,
              latitude: position.coords.latitude,
              longitude: position.coords.longitude,
            });

            const task = dashboard?.todaysTasks.find(t => t.id === taskId);
            if (task) {
              setActiveTask({
                ...task,
                status: 'IN_PROGRESS',
                checkedInAt: new Date().toISOString(),
                location: {
                  lat: position.coords.latitude,
                  lng: position.coords.longitude,
                },
              });
              setCheckInTime(new Date());
              // Remove from today's tasks
              setDashboard(prev => prev ? {
                ...prev,
                todaysTasks: prev.todaysTasks.filter(t => t.id !== taskId),
              } : null);
            }
          } catch (err) {
            console.error('Check-in failed:', err);
            // Still update UI optimistically on error for demo
            const task = dashboard?.todaysTasks.find(t => t.id === taskId);
            if (task) {
              setActiveTask({
                ...task,
                status: 'IN_PROGRESS',
                checkedInAt: new Date().toISOString(),
                location: {
                  lat: position.coords.latitude,
                  lng: position.coords.longitude,
                },
              });
              setCheckInTime(new Date());
              setDashboard(prev => prev ? {
                ...prev,
                todaysTasks: prev.todaysTasks.filter(t => t.id !== taskId),
              } : null);
            }
          }
          setIsCheckingIn(false);
        },
        (geoError) => {
          console.error('Geolocation error:', geoError);
          // Still allow check-in without location
          handleCheckInWithoutLocation(taskId);
        }
      );
    } else {
      // Fallback without geolocation
      handleCheckInWithoutLocation(taskId);
    }
  };

  const handleCheckInWithoutLocation = async (taskId: string) => {
    try {
      const api = getApiClient();
      await api.handymanCheckIn({
        workOrderId: taskId,
        latitude: 0,
        longitude: 0,
      });
    } catch (err) {
      console.error('Check-in failed:', err);
    }

    const task = dashboard?.todaysTasks.find(t => t.id === taskId);
    if (task) {
      setActiveTask({
        ...task,
        status: 'IN_PROGRESS',
        checkedInAt: new Date().toISOString(),
      });
      setCheckInTime(new Date());
      setDashboard(prev => prev ? {
        ...prev,
        todaysTasks: prev.todaysTasks.filter(t => t.id !== taskId),
      } : null);
    }
    setIsCheckingIn(false);
  };

  const handleCheckOut = async () => {
    if (!activeTask) return;
    setIsCheckingOut(true);

    const hoursWorked = checkOutHours ? parseFloat(checkOutHours) :
      checkInTime ? (Date.now() - checkInTime.getTime()) / (1000 * 60 * 60) : 0;

    try {
      const api = getApiClient();
      await api.handymanCheckOut({
        workOrderId: activeTask.id,
        hoursWorked,
        notes: checkOutNotes || undefined,
      });
    } catch (err) {
      console.error('Check-out failed:', err);
    }

    // Update stats
    setDashboard(prev => prev ? {
      ...prev,
      stats: {
        ...prev.stats,
        completedToday: prev.stats.completedToday + 1,
        hoursLoggedToday: prev.stats.hoursLoggedToday + hoursWorked,
      },
    } : null);

    setActiveTask(null);
    setCheckInTime(null);
    setShowCheckOutModal(false);
    setCheckOutNotes('');
    setCheckOutHours('');
    setIsCheckingOut(false);
  };

  const formatTime = (dateStr: string | null) => {
    if (!dateStr) return 'TBD';
    return new Date(dateStr).toLocaleTimeString('en-US', {
      hour: 'numeric',
      minute: '2-digit',
    });
  };

  const formatElapsedTime = () => {
    if (!checkInTime) return '0:00';
    const elapsed = Date.now() - checkInTime.getTime();
    const hours = Math.floor(elapsed / (1000 * 60 * 60));
    const minutes = Math.floor((elapsed % (1000 * 60 * 60)) / (1000 * 60));
    return `${hours}:${minutes.toString().padStart(2, '0')}`;
  };

  // Update elapsed time every minute
  useEffect(() => {
    if (!activeTask) return;
    const interval = setInterval(() => {
      // Force re-render to update elapsed time
      setCheckInTime(prev => prev ? new Date(prev) : null);
    }, 60000);
    return () => clearInterval(interval);
  }, [activeTask]);

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-teal-600"></div>
      </div>
    );
  }

  if (error || !dashboard) {
    return (
      <div className="flex flex-col items-center justify-center h-64">
        <p className="text-red-600 mb-4">{error || 'Failed to load dashboard'}</p>
        <button
          onClick={loadDashboard}
          className="px-4 py-2 bg-teal-600 text-white rounded-lg hover:bg-teal-700"
        >
          Retry
        </button>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-slate-900 dark:text-white">
          Good {new Date().getHours() < 12 ? 'morning' : new Date().getHours() < 17 ? 'afternoon' : 'evening'}, {dashboard.handymanName.split(' ')[0]}!
        </h1>
        <p className="text-slate-600 dark:text-slate-400">
          {new Date().toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric' })}
        </p>
      </div>

      {/* Active Task Banner */}
      {activeTask && (
        <div className="bg-gradient-to-r from-teal-500 to-cyan-600 rounded-xl p-6 text-white shadow-lg">
          <div className="flex items-start justify-between">
            <div className="flex-1">
              <div className="flex items-center gap-2 mb-2">
                <span className="px-2 py-0.5 bg-white/20 rounded text-xs font-medium">IN PROGRESS</span>
                {activeTask.billingType === 'INCLUSIVE' && (
                  <span className="px-2 py-0.5 bg-green-400/30 rounded text-xs font-medium">CONCIERGE</span>
                )}
              </div>
              <h2 className="text-xl font-bold mb-1">{activeTask.title}</h2>
              <p className="text-teal-100 text-sm mb-3">{activeTask.householdName}</p>
              <p className="text-teal-100/80 text-sm">{activeTask.householdAddress}</p>

              <div className="flex items-center gap-6 mt-4">
                <div>
                  <p className="text-xs text-teal-200">Checked in at</p>
                  <p className="text-lg font-semibold">{checkInTime ? formatTime(checkInTime.toISOString()) : '--:--'}</p>
                </div>
                <div>
                  <p className="text-xs text-teal-200">Time elapsed</p>
                  <p className="text-lg font-semibold">{formatElapsedTime()}</p>
                </div>
                <div>
                  <p className="text-xs text-teal-200">Est. duration</p>
                  <p className="text-lg font-semibold">{activeTask.estimatedMinutes} min</p>
                </div>
              </div>
            </div>

            <button
              onClick={() => setShowCheckOutModal(true)}
              className="px-6 py-3 bg-white text-teal-600 rounded-lg font-semibold hover:bg-teal-50 transition-colors flex items-center gap-2"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
              </svg>
              Complete Task
            </button>
          </div>
        </div>
      )}

      {/* Stats Grid */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="card">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-lg bg-green-100 dark:bg-green-900/30 flex items-center justify-center">
              <svg className="w-6 h-6 text-green-600 dark:text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
              </svg>
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900 dark:text-white">{dashboard.stats.completedToday}</p>
              <p className="text-sm text-slate-500 dark:text-slate-400">Done Today</p>
            </div>
          </div>
        </div>
        <div className="card">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-lg bg-emerald-100 dark:bg-emerald-900/30 flex items-center justify-center">
              <svg className="w-6 h-6 text-emerald-600 dark:text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900 dark:text-white">{dashboard.stats.hoursLoggedToday.toFixed(1)}h</p>
              <p className="text-sm text-slate-500 dark:text-slate-400">Hours Today</p>
            </div>
          </div>
        </div>
        <div className="card">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-lg bg-yellow-100 dark:bg-yellow-900/30 flex items-center justify-center">
              <svg className="w-6 h-6 text-yellow-600 dark:text-yellow-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
              </svg>
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900 dark:text-white">{dashboard.stats.pendingTasks}</p>
              <p className="text-sm text-slate-500 dark:text-slate-400">Pending</p>
            </div>
          </div>
        </div>
        <div className="card">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-lg bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center">
              <svg className="w-6 h-6 text-purple-600 dark:text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
              </svg>
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900 dark:text-white">{dashboard.stats.assignedHouseholds}</p>
              <p className="text-sm text-slate-500 dark:text-slate-400">Households</p>
            </div>
          </div>
        </div>
      </div>

      {/* Today's Tasks */}
      <div>
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Today's Tasks</h2>
          <Link
            href="/handyman/schedule"
            className="text-sm text-teal-600 hover:text-teal-700 font-medium"
          >
            View All
          </Link>
        </div>

        {dashboard.todaysTasks.length === 0 && !activeTask ? (
          <div className="card text-center py-12">
            <svg className="w-12 h-12 mx-auto text-slate-400 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <h3 className="text-lg font-medium text-slate-900 dark:text-white mb-2">All done for today!</h3>
            <p className="text-slate-600 dark:text-slate-400">
              Great work! Check your schedule for upcoming tasks.
            </p>
          </div>
        ) : (
          <div className="space-y-3">
            {dashboard.todaysTasks.map((task) => (
              <div key={task.id} className="card hover:shadow-lg transition-shadow">
                <div className="flex items-start justify-between gap-4">
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-1">
                      <h3 className="font-semibold text-slate-900 dark:text-white">{task.title}</h3>
                      <span className={`px-2 py-0.5 rounded text-xs font-medium ${STATUS_COLORS[task.status]}`}>
                        {task.status}
                      </span>
                      {task.billingType === 'INCLUSIVE' && (
                        <span className="px-2 py-0.5 rounded text-xs font-medium bg-teal-100 text-teal-700">
                          CONCIERGE
                        </span>
                      )}
                    </div>
                    <p className="text-sm text-slate-600 dark:text-slate-400">{task.householdName}</p>
                    <p className="text-xs text-slate-500 dark:text-slate-500 mt-1">{task.householdAddress}</p>

                    <div className="flex items-center gap-4 mt-3 text-sm text-slate-500 dark:text-slate-400">
                      <span className="flex items-center gap-1">
                        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                        {formatTime(task.scheduledStart)}
                      </span>
                      <span className="flex items-center gap-1">
                        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                        </svg>
                        ~{task.estimatedMinutes} min
                      </span>
                    </div>
                  </div>

                  <button
                    onClick={() => handleCheckIn(task.id)}
                    disabled={isCheckingIn || !!activeTask}
                    className="px-4 py-2 bg-teal-600 text-white rounded-lg font-medium hover:bg-teal-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
                  >
                    {isCheckingIn ? (
                      <>
                        <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                        Checking In...
                      </>
                    ) : (
                      <>
                        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                        </svg>
                        Check In
                      </>
                    )}
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Assigned Households */}
      <div>
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Your Households</h2>
        </div>

        <div className="grid gap-3 lg:grid-cols-2">
          {dashboard.assignedHouseholds.map((household) => (
            <div key={household.id} className="card">
              <div className="flex items-center gap-4">
                <div className="w-10 h-10 rounded-lg bg-slate-100 dark:bg-slate-800 flex items-center justify-center">
                  <svg className="w-5 h-5 text-slate-600 dark:text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
                  </svg>
                </div>
                <div className="flex-1">
                  <h3 className="font-medium text-slate-900 dark:text-white">{household.name}</h3>
                  <p className="text-sm text-slate-500 dark:text-slate-400">{household.address}</p>
                </div>
                <div className="text-right">
                  <p className="text-xs text-slate-500 dark:text-slate-400">Next Visit</p>
                  <p className="text-sm font-medium text-slate-700 dark:text-slate-300">
                    {new Date(household.nextVisitDate).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}
                  </p>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Check Out Modal */}
      {showCheckOutModal && activeTask && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white dark:bg-slate-800 rounded-xl max-w-md w-full">
            <div className="p-6">
              <div className="flex items-center justify-between mb-6">
                <h2 className="text-xl font-bold text-slate-900 dark:text-white">Complete Task</h2>
                <button
                  onClick={() => setShowCheckOutModal(false)}
                  className="p-2 hover:bg-slate-100 dark:hover:bg-slate-700 rounded-lg transition-colors"
                >
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>

              <div className="space-y-4">
                <div className="p-4 bg-slate-50 dark:bg-slate-700/50 rounded-lg">
                  <h3 className="font-medium text-slate-900 dark:text-white">{activeTask.title}</h3>
                  <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">{activeTask.householdName}</p>
                  <div className="flex items-center gap-4 mt-3 text-sm">
                    <span className="text-slate-600 dark:text-slate-400">
                      Time: <span className="font-medium">{formatElapsedTime()}</span>
                    </span>
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Hours Worked (Optional)
                  </label>
                  <input
                    type="number"
                    step="0.25"
                    min="0"
                    value={checkOutHours}
                    onChange={(e) => setCheckOutHours(e.target.value)}
                    placeholder={`Auto-calculated: ${formatElapsedTime()}`}
                    className="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-white"
                  />
                  <p className="text-xs text-slate-500 mt-1">Leave blank to use elapsed time</p>
                </div>

                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Completion Notes (Optional)
                  </label>
                  <textarea
                    value={checkOutNotes}
                    onChange={(e) => setCheckOutNotes(e.target.value)}
                    placeholder="Any notes about the completed work..."
                    rows={3}
                    className="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-white"
                  />
                </div>

                <div className="flex gap-3 pt-4">
                  <button
                    onClick={() => setShowCheckOutModal(false)}
                    className="flex-1 px-4 py-2 border border-slate-300 dark:border-slate-600 text-slate-700 dark:text-slate-300 rounded-lg hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors"
                  >
                    Cancel
                  </button>
                  <button
                    onClick={handleCheckOut}
                    disabled={isCheckingOut}
                    className="flex-1 px-4 py-2 bg-teal-600 text-white rounded-lg hover:bg-teal-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                  >
                    {isCheckingOut ? (
                      <>
                        <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                        Completing...
                      </>
                    ) : (
                      <>
                        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                        </svg>
                        Complete & Check Out
                      </>
                    )}
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
