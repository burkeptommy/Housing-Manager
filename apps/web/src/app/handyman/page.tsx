'use client';

import { useState, useEffect, useCallback } from 'react';
import Link from 'next/link';
import type { HandymanDashboard, HandymanTask } from '@haven/core';
import { getApiClient } from '@/lib/api';
import { images } from '@/lib/images';
import { Card, Badge, Button, Avatar, Modal } from '@/components/ui';
import {
  CheckCircle,
  Clock,
  ClipboardList,
  Home,
  MapPin,
  Loader2,
  ChevronRight,
  Zap,
  Calendar,
  Timer,
  Check,
  X,
} from 'lucide-react';

// Status colors for work orders
const STATUS_STYLES: Record<string, { variant: 'success' | 'warning' | 'info' | 'error' | 'neutral'; label: string }> = {
  OPEN: { variant: 'warning', label: 'Open' },
  ASSIGNED: { variant: 'info', label: 'Assigned' },
  IN_PROGRESS: { variant: 'warning', label: 'In Progress' },
  COMPLETED: { variant: 'success', label: 'Completed' },
  VERIFIED: { variant: 'success', label: 'Verified' },
};

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

function getTimeOfDay(): string {
  const hour = new Date().getHours();
  if (hour < 12) return 'morning';
  if (hour < 17) return 'afternoon';
  return 'evening';
}

function formatCurrentDate(): string {
  return new Date().toLocaleDateString('en-US', {
    weekday: 'long',
    month: 'long',
    day: 'numeric'
  });
}

function formatTime(dateStr: string | null): string {
  if (!dateStr) return 'TBD';
  return new Date(dateStr).toLocaleTimeString('en-US', {
    hour: 'numeric',
    minute: '2-digit',
  });
}

// ============================================================================
// COMPONENTS
// ============================================================================

// Hero Header for Handyman
function HeroHeader({ name, stats }: { name: string; stats: { completedToday: number; hoursLoggedToday: number; pendingTasks: number; assignedHouseholds: number } }) {
  return (
    <div className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-teal-600 via-teal-500 to-cyan-500 p-8 text-white mb-8">
      {/* Background Pattern */}
      <div className="absolute inset-0 opacity-10">
        <div className="absolute top-0 right-0 w-96 h-96 bg-white rounded-full -translate-y-1/2 translate-x-1/2" />
        <div className="absolute bottom-0 left-0 w-64 h-64 bg-white rounded-full translate-y-1/2 -translate-x-1/2" />
      </div>

      <div className="relative">
        <div className="flex items-start justify-between mb-8">
          <div>
            <p className="text-teal-200 text-sm font-medium mb-1">{formatCurrentDate()}</p>
            <h1 className="text-3xl lg:text-4xl font-bold tracking-tight text-white">
              Good {getTimeOfDay()}, {name}!
            </h1>
            <p className="text-teal-200 mt-2">Ready to tackle today's tasks</p>
          </div>
          <Avatar name={name} src={images.avatars.mike} size="xl" />
        </div>

        {/* Quick Stats */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="bg-white/10 backdrop-blur-sm rounded-xl p-4">
            <div className="flex items-center gap-2 mb-2">
              <CheckCircle className="w-4 h-4 text-emerald-300" />
              <p className="text-teal-200 text-xs font-medium uppercase tracking-wider">Done Today</p>
            </div>
            <p className="text-3xl font-bold">{stats.completedToday}</p>
          </div>
          <div className="bg-white/10 backdrop-blur-sm rounded-xl p-4">
            <div className="flex items-center gap-2 mb-2">
              <Timer className="w-4 h-4 text-teal-200" />
              <p className="text-teal-200 text-xs font-medium uppercase tracking-wider">Hours Today</p>
            </div>
            <p className="text-3xl font-bold">{stats.hoursLoggedToday.toFixed(1)}h</p>
          </div>
          <div className="bg-white/10 backdrop-blur-sm rounded-xl p-4">
            <div className="flex items-center gap-2 mb-2">
              <ClipboardList className="w-4 h-4 text-amber-300" />
              <p className="text-teal-200 text-xs font-medium uppercase tracking-wider">Pending</p>
            </div>
            <p className="text-3xl font-bold">{stats.pendingTasks}</p>
          </div>
          <div className="bg-white/10 backdrop-blur-sm rounded-xl p-4">
            <div className="flex items-center gap-2 mb-2">
              <Home className="w-4 h-4 text-purple-300" />
              <p className="text-teal-200 text-xs font-medium uppercase tracking-wider">Households</p>
            </div>
            <p className="text-3xl font-bold">{stats.assignedHouseholds}</p>
          </div>
        </div>
      </div>
    </div>
  );
}

// Active Task Banner
function ActiveTaskBanner({ task, checkInTime, onComplete }: { task: HandymanTask; checkInTime: Date | null; onComplete: () => void }) {
  const formatElapsedTime = () => {
    if (!checkInTime) return '0:00';
    const elapsed = Date.now() - checkInTime.getTime();
    const hours = Math.floor(elapsed / (1000 * 60 * 60));
    const minutes = Math.floor((elapsed % (1000 * 60 * 60)) / (1000 * 60));
    return `${hours}:${minutes.toString().padStart(2, '0')}`;
  };

  return (
    <div className="relative overflow-hidden rounded-2xl bg-gradient-to-r from-teal-600 via-cyan-600 to-cyan-500 p-6 text-white shadow-xl shadow-teal-500/20 mb-8">
      {/* Animated Background */}
      <div className="absolute inset-0 opacity-20">
        <div className="absolute -top-4 -right-4 w-32 h-32 bg-white rounded-full blur-2xl" />
        <div className="absolute -bottom-4 -left-4 w-24 h-24 bg-cyan-300 rounded-full blur-2xl" />
      </div>

      <div className="relative flex items-start justify-between gap-6">
        <div className="flex-1">
          <div className="flex items-center gap-2 mb-3">
            <span className="flex h-2 w-2">
              <span className="animate-ping absolute inline-flex h-2 w-2 rounded-full bg-white opacity-75" />
              <span className="relative inline-flex rounded-full h-2 w-2 bg-white" />
            </span>
            <Badge variant="success" className="bg-white/20 text-white border-0">IN PROGRESS</Badge>
            {task.billingType === 'INCLUSIVE' && (
              <Badge variant="info" className="bg-emerald-400/30 text-white border-0">CONCIERGE</Badge>
            )}
          </div>
          <h2 className="text-2xl font-bold mb-2">{task.title}</h2>
          <p className="text-teal-100 mb-1">{task.householdName}</p>
          <p className="text-teal-200/80 text-sm">{task.householdAddress}</p>

          <div className="flex items-center gap-8 mt-6">
            <div>
              <p className="text-xs text-teal-200 uppercase tracking-wider">Checked in at</p>
              <p className="text-xl font-bold mt-1">{checkInTime ? formatTime(checkInTime.toISOString()) : '--:--'}</p>
            </div>
            <div>
              <p className="text-xs text-teal-200 uppercase tracking-wider">Time elapsed</p>
              <p className="text-xl font-bold mt-1">{formatElapsedTime()}</p>
            </div>
            <div>
              <p className="text-xs text-teal-200 uppercase tracking-wider">Est. duration</p>
              <p className="text-xl font-bold mt-1">{task.estimatedMinutes} min</p>
            </div>
          </div>
        </div>

        <Button
          onClick={onComplete}
          variant="secondary"
          size="lg"
          className="bg-white text-teal-600 hover:bg-teal-50 shadow-lg"
          leftIcon={<Check className="w-5 h-5" />}
        >
          Complete Task
        </Button>
      </div>
    </div>
  );
}

// Task Card
function TaskCard({ task, onCheckIn, isCheckingIn, hasActiveTask }: { task: HandymanTask; onCheckIn: () => void; isCheckingIn: boolean; hasActiveTask: boolean }) {
  const status = STATUS_STYLES[task.status] || STATUS_STYLES.OPEN;

  return (
    <Card hover className="overflow-hidden">
      <div className="flex items-start justify-between gap-4">
        <div className="flex-1">
          <div className="flex items-center gap-2 mb-2">
            <h3 className="font-bold text-warm-900">{task.title}</h3>
            <Badge variant={status.variant} size="sm">{status.label}</Badge>
            {task.billingType === 'INCLUSIVE' && (
              <Badge variant="info" size="sm">CONCIERGE</Badge>
            )}
          </div>
          <p className="text-sm text-warm-600">{task.householdName}</p>
          <p className="text-xs text-warm-500 mt-1">{task.householdAddress}</p>

          <div className="flex items-center gap-4 mt-4 text-sm text-warm-500">
            <span className="flex items-center gap-1.5">
              <Clock className="w-4 h-4" />
              {formatTime(task.scheduledStart)}
            </span>
            <span className="flex items-center gap-1.5">
              <Zap className="w-4 h-4" />
              ~{task.estimatedMinutes} min
            </span>
          </div>
        </div>

        <Button
          onClick={onCheckIn}
          disabled={isCheckingIn || hasActiveTask}
          isLoading={isCheckingIn}
          leftIcon={<MapPin className="w-4 h-4" />}
        >
          Check In
        </Button>
      </div>
    </Card>
  );
}

// Household Card
function HouseholdCard({ household }: { household: { id: string; name: string; address: string; nextVisitDate: string } }) {
  return (
    <Card hover>
      <div className="flex items-center gap-4">
        <div className="w-12 h-12 rounded-xl bg-teal-100 flex items-center justify-center">
          <Home className="w-6 h-6 text-teal-600" />
        </div>
        <div className="flex-1">
          <h3 className="font-semibold text-warm-900">{household.name}</h3>
          <p className="text-sm text-warm-500">{household.address}</p>
        </div>
        <div className="text-right">
          <p className="text-xs text-warm-500 uppercase tracking-wider">Next Visit</p>
          <p className="text-sm font-semibold text-warm-700">
            {new Date(household.nextVisitDate).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}
          </p>
        </div>
      </div>
    </Card>
  );
}

// Empty State
function EmptyTasks() {
  return (
    <Card className="text-center py-12">
      <div className="w-16 h-16 rounded-2xl bg-emerald-100 flex items-center justify-center mx-auto mb-4">
        <CheckCircle className="w-8 h-8 text-emerald-600" />
      </div>
      <h3 className="text-lg font-bold text-warm-900 mb-2">All done for today!</h3>
      <p className="text-warm-600">
        Great work! Check your schedule for upcoming tasks.
      </p>
      <Link href="/handyman/schedule">
        <Button variant="outline" className="mt-6">
          View Full Schedule
        </Button>
      </Link>
    </Card>
  );
}

// ============================================================================
// MAIN COMPONENT
// ============================================================================

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
        <div className="flex flex-col items-center gap-3">
          <Loader2 className="w-8 h-8 animate-spin text-teal-600" />
          <p className="text-warm-500">Loading dashboard...</p>
        </div>
      </div>
    );
  }

  if (error || !dashboard) {
    return (
      <div className="flex flex-col items-center justify-center h-64">
        <p className="text-red-600 mb-4">{error || 'Failed to load dashboard'}</p>
        <Button onClick={loadDashboard}>Retry</Button>
      </div>
    );
  }

  return (
    <div className="space-y-6 pb-20">
      {/* Hero Header */}
      <HeroHeader name={dashboard.handymanName.split(' ')[0]} stats={dashboard.stats} />

      {/* Active Task Banner */}
      {activeTask && (
        <ActiveTaskBanner
          task={activeTask}
          checkInTime={checkInTime}
          onComplete={() => setShowCheckOutModal(true)}
        />
      )}

      {/* Today's Tasks */}
      <div>
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-bold text-warm-900">Today's Tasks</h2>
          <Link
            href="/handyman/schedule"
            className="text-sm text-teal-600 hover:text-teal-700 font-medium flex items-center gap-1"
          >
            View All <ChevronRight className="w-4 h-4" />
          </Link>
        </div>

        {dashboard.todaysTasks.length === 0 && !activeTask ? (
          <EmptyTasks />
        ) : (
          <div className="space-y-4">
            {dashboard.todaysTasks.map((task) => (
              <TaskCard
                key={task.id}
                task={task}
                onCheckIn={() => handleCheckIn(task.id)}
                isCheckingIn={isCheckingIn}
                hasActiveTask={!!activeTask}
              />
            ))}
          </div>
        )}
      </div>

      {/* Assigned Households */}
      <div>
        <h2 className="text-lg font-bold text-warm-900 mb-4">Your Households</h2>
        <div className="grid gap-4 lg:grid-cols-2">
          {dashboard.assignedHouseholds.map((household) => (
            <HouseholdCard key={household.id} household={household} />
          ))}
        </div>
      </div>

      {/* Check Out Modal */}
      <Modal
        isOpen={showCheckOutModal}
        onClose={() => setShowCheckOutModal(false)}
        title="Complete Task"
        size="md"
      >
        {activeTask && (
          <div className="space-y-6">
            <Card className="bg-warm-50 border-0">
              <h3 className="font-bold text-warm-900">{activeTask.title}</h3>
              <p className="text-sm text-warm-500 mt-1">{activeTask.householdName}</p>
              <div className="flex items-center gap-4 mt-3 text-sm">
                <span className="text-warm-600">
                  Time: <span className="font-semibold">{formatElapsedTime()}</span>
                </span>
              </div>
            </Card>

            <div>
              <label className="block text-sm font-medium text-warm-700 mb-2">
                Hours Worked (Optional)
              </label>
              <input
                type="number"
                step="0.25"
                min="0"
                value={checkOutHours}
                onChange={(e) => setCheckOutHours(e.target.value)}
                placeholder={`Auto-calculated: ${formatElapsedTime()}`}
                className="w-full px-4 py-2.5 border border-warm-200 rounded-xl focus:ring-2 focus:ring-teal-500/20 focus:border-teal-500 transition-all"
              />
              <p className="text-xs text-warm-500 mt-1">Leave blank to use elapsed time</p>
            </div>

            <div>
              <label className="block text-sm font-medium text-warm-700 mb-2">
                Completion Notes (Optional)
              </label>
              <textarea
                value={checkOutNotes}
                onChange={(e) => setCheckOutNotes(e.target.value)}
                placeholder="Any notes about the completed work..."
                rows={3}
                className="w-full px-4 py-3 border border-warm-200 rounded-xl focus:ring-2 focus:ring-teal-500/20 focus:border-teal-500 transition-all resize-none"
              />
            </div>

            <div className="flex gap-3">
              <Button
                variant="secondary"
                className="flex-1"
                onClick={() => setShowCheckOutModal(false)}
              >
                Cancel
              </Button>
              <Button
                onClick={handleCheckOut}
                isLoading={isCheckingOut}
                className="flex-1"
                leftIcon={<Check className="w-5 h-5" />}
              >
                Complete & Check Out
              </Button>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
}
