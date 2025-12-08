'use client';

import Link from 'next/link';
import { useAuth } from '@/contexts/auth-context';
import { useDashboard, useRequestHavenHandle } from '@/hooks/use-dashboard';
import type { UpcomingBill, UpcomingMaintenanceTask, TodayTask } from '@haven/core';

// Category icon mapping
const CATEGORY_ICONS: Record<string, string> = {
  // Vendor categories
  MORTGAGE: '🏠',
  HOA: '🏘️',
  PROPERTY_TAX: '📋',
  ELECTRIC: '⚡',
  GAS: '🔥',
  WATER_SEWER: '💧',
  TRASH: '🗑️',
  INTERNET: '🌐',
  MOBILE: '📱',
  CABLE: '📺',
  HOME_INSURANCE: '🛡️',
  AUTO_INSURANCE: '🚗',
  HEALTH_INSURANCE: '❤️',
  LIFE_INSURANCE: '💼',
  PET_INSURANCE: '🐾',
  CREDIT_CARD: '💳',
  STUDENT_LOAN: '🎓',
  PERSONAL_LOAN: '💰',
  VEHICLE_LOAN: '🚙',
  HELOC: '🏦',
  STREAMING: '🎬',
  GYM: '💪',
  SECURITY_MONITORING: '🔒',
  PEST_CONTROL: '🐛',
  LAWN_CARE: '🌱',
  LANDSCAPING: '🌳',
  HOME_WARRANTY: '📜',
  CLEANING: '🧹',
  WINDOW_WASHING: '🪟',
  GUTTER_CLEANING: '🍂',
  HVAC_SERVICE: '❄️',
  FILTER_SERVICE: '🌀',
  CHIMNEY_SWEEP: '🧱',
  SEPTIC_SERVICE: '🚽',
  POOL_SERVICE: '🏊',
  SNOW_REMOVAL: '❄️',
  HANDYMAN: '🔧',
  // Maintenance categories
  HVAC: '❄️',
  PLUMBING: '🔧',
  ROOF_GUTTER: '🏠',
  CHIMNEY: '🧱',
  SEPTIC: '🚽',
  PEST: '🐛',
  POOL: '🏊',
  SAFETY: '🛡️',
  APPLIANCES: '🔌',
  EXTERIOR: '🏡',
  INTERIOR: '🛋️',
  GENERAL: '🔨',
  OTHER: '📦',
};

function getCategoryIcon(category: string): string {
  return CATEGORY_ICONS[category] || '📋';
}

function formatCurrency(amount: number | undefined): string {
  if (amount === undefined) return '--';
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
  }).format(amount);
}

function formatDate(date: Date | string | undefined): string {
  if (!date) return '--';
  return new Date(date).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
  });
}

function getDaysUntilLabel(days: number): string {
  if (days === 0) return 'Today';
  if (days === 1) return 'Tomorrow';
  if (days < 0) return `${Math.abs(days)} days overdue`;
  return `in ${days} days`;
}

export default function DashboardPage() {
  const { user, currentHousehold } = useAuth();
  const { data: dashboard, isLoading, error } = useDashboard(currentHousehold?.id);
  const requestHavenHandle = useRequestHavenHandle();

  const handleAskHavenToHandle = async (billId: string) => {
    try {
      await requestHavenHandle.mutateAsync({ billId });
    } catch (err) {
      console.error('Failed to request Haven to handle bill:', err);
    }
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  if (error || !dashboard) {
    return (
      <div className="flex items-center justify-center h-64">
        <p className="text-slate-500 dark:text-slate-400">
          Failed to load dashboard data. Please try again.
        </p>
      </div>
    );
  }

  const { summary, upcomingBills, upcomingMaintenanceTasks } = dashboard;

  return (
    <div className="space-y-6">
      {/* Hero Summary Section */}
      <div className="bg-gradient-to-r from-blue-600 to-indigo-700 rounded-xl p-6 text-white">
        <h1 className="text-2xl font-bold mb-2">
          Welcome back, {user?.firstName}!
        </h1>
        <p className="text-blue-100 text-lg">
          This month: <span className="font-semibold text-white">{summary.billsManagedThisMonth} bills</span> managed,{' '}
          <span className="font-semibold text-white">{summary.tasksScheduledThisMonth} tasks</span> scheduled,{' '}
          <span className="font-semibold text-white">{summary.tasksCompletedThisMonth} tasks</span> completed
        </p>

        {/* Next Up Highlight */}
        {summary.nextUp && (
          <div className="mt-4 bg-white/10 backdrop-blur-sm rounded-lg p-4">
            <p className="text-sm text-blue-200 mb-1">Next up</p>
            <p className="text-xl font-semibold flex items-center gap-2">
              <span>{getCategoryIcon(summary.nextUp.category)}</span>
              <span>{summary.nextUp.title}</span>
              <span className="text-blue-200">{getDaysUntilLabel(summary.nextUp.daysUntilDue)}</span>
            </p>
            {summary.nextUp.vendorName && (
              <p className="text-blue-200 text-sm mt-1">
                with {summary.nextUp.vendorName}
              </p>
            )}
          </div>
        )}
      </div>

      {/* Today's Tasks */}
      {summary.todaysTasks.length > 0 && (
        <div className="card border-l-4 border-l-amber-500">
          <div className="flex items-center gap-2 mb-4">
            <span className="text-2xl">📅</span>
            <h2 className="text-lg font-semibold text-slate-900 dark:text-white">
              Today&apos;s Tasks
            </h2>
            <span className="bg-amber-100 text-amber-800 text-xs font-medium px-2 py-0.5 rounded-full dark:bg-amber-900/30 dark:text-amber-400">
              {summary.todaysTasks.length}
            </span>
          </div>
          <div className="space-y-2">
            {summary.todaysTasks.map((task: TodayTask) => (
              <div
                key={task.id}
                className="flex items-center justify-between p-3 bg-slate-50 dark:bg-slate-700/50 rounded-lg"
              >
                <div className="flex items-center gap-3">
                  <span className="text-xl">{getCategoryIcon(task.category)}</span>
                  <div>
                    <p className="font-medium text-slate-900 dark:text-white">{task.title}</p>
                    {task.vendorName && (
                      <p className="text-sm text-slate-500 dark:text-slate-400">{task.vendorName}</p>
                    )}
                  </div>
                </div>
                <div className="text-right">
                  {task.amount !== undefined && (
                    <p className="font-medium text-slate-900 dark:text-white">{formatCurrency(task.amount)}</p>
                  )}
                  {task.scheduledTime && (
                    <p className="text-sm text-slate-500 dark:text-slate-400">{task.scheduledTime}</p>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Main Content Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Upcoming Bills */}
        <div className="card">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <span className="text-2xl">💰</span>
              <h2 className="text-lg font-semibold text-slate-900 dark:text-white">
                Upcoming Bills
              </h2>
              {upcomingBills.length > 0 && (
                <span className="bg-blue-100 text-blue-800 text-xs font-medium px-2 py-0.5 rounded-full dark:bg-blue-900/30 dark:text-blue-400">
                  {upcomingBills.length}
                </span>
              )}
            </div>
            <Link
              href="/app/billing"
              className="text-sm text-blue-600 hover:text-blue-500 dark:text-blue-400 font-medium"
            >
              View all
            </Link>
          </div>

          {upcomingBills.length === 0 ? (
            <div className="text-center py-8 text-slate-500 dark:text-slate-400">
              <p className="text-4xl mb-2">✨</p>
              <p>No upcoming bills in the next 30 days</p>
            </div>
          ) : (
            <div className="space-y-3">
              {upcomingBills.slice(0, 5).map((bill: UpcomingBill) => (
                <div
                  key={bill.id}
                  className={`p-4 rounded-lg border ${
                    bill.isOverdue
                      ? 'border-red-200 bg-red-50 dark:border-red-800 dark:bg-red-900/20'
                      : 'border-slate-200 bg-slate-50 dark:border-slate-700 dark:bg-slate-700/50'
                  }`}
                >
                  <div className="flex items-start justify-between">
                    <div className="flex items-start gap-3">
                      <span className="text-2xl">{getCategoryIcon(bill.category)}</span>
                      <div>
                        <p className="font-medium text-slate-900 dark:text-white">{bill.nickname}</p>
                        <p className="text-sm text-slate-500 dark:text-slate-400">{bill.vendorName}</p>
                        <p className={`text-sm mt-1 ${
                          bill.isOverdue ? 'text-red-600 dark:text-red-400 font-medium' : 'text-slate-500 dark:text-slate-400'
                        }`}>
                          {formatDate(bill.nextDueDate)} ({getDaysUntilLabel(bill.daysUntilDue)})
                        </p>
                      </div>
                    </div>
                    <div className="text-right">
                      <p className="font-semibold text-slate-900 dark:text-white">
                        {formatCurrency(bill.typicalAmount)}
                      </p>
                      {bill.paymentResponsibility !== 'HAVEN_PAYS_ON_BEHALF' && (
                        <button
                          onClick={() => handleAskHavenToHandle(bill.id)}
                          disabled={requestHavenHandle.isPending}
                          className="mt-2 text-xs text-blue-600 hover:text-blue-500 dark:text-blue-400 font-medium disabled:opacity-50"
                        >
                          Ask Haven to handle
                        </button>
                      )}
                      {bill.paymentResponsibility === 'HAVEN_PAYS_ON_BEHALF' && (
                        <span className="mt-2 inline-block text-xs text-green-600 dark:text-green-400 font-medium">
                          ✓ Haven handles this
                        </span>
                      )}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Upcoming Maintenance */}
        <div className="card">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <span className="text-2xl">🔧</span>
              <h2 className="text-lg font-semibold text-slate-900 dark:text-white">
                Upcoming Maintenance
              </h2>
              {upcomingMaintenanceTasks.length > 0 && (
                <span className="bg-purple-100 text-purple-800 text-xs font-medium px-2 py-0.5 rounded-full dark:bg-purple-900/30 dark:text-purple-400">
                  {upcomingMaintenanceTasks.length}
                </span>
              )}
            </div>
            <Link
              href="/app/maintenance"
              className="text-sm text-blue-600 hover:text-blue-500 dark:text-blue-400 font-medium"
            >
              View all
            </Link>
          </div>

          {upcomingMaintenanceTasks.length === 0 ? (
            <div className="text-center py-8 text-slate-500 dark:text-slate-400">
              <p className="text-4xl mb-2">✨</p>
              <p>No upcoming maintenance tasks</p>
            </div>
          ) : (
            <div className="space-y-3">
              {upcomingMaintenanceTasks.slice(0, 5).map((task: UpcomingMaintenanceTask) => (
                <div
                  key={task.id}
                  className={`p-4 rounded-lg border ${
                    task.isOverdue
                      ? 'border-red-200 bg-red-50 dark:border-red-800 dark:bg-red-900/20'
                      : 'border-slate-200 bg-slate-50 dark:border-slate-700 dark:bg-slate-700/50'
                  }`}
                >
                  <div className="flex items-start justify-between">
                    <div className="flex items-start gap-3">
                      <span className="text-2xl">{getCategoryIcon(task.category)}</span>
                      <div>
                        <p className="font-medium text-slate-900 dark:text-white">{task.title}</p>
                        {task.assignedVendorName && (
                          <p className="text-sm text-slate-500 dark:text-slate-400">{task.assignedVendorName}</p>
                        )}
                        <p className={`text-sm mt-1 ${
                          task.isOverdue ? 'text-red-600 dark:text-red-400 font-medium' : 'text-slate-500 dark:text-slate-400'
                        }`}>
                          {task.dueDate ? formatDate(task.dueDate) : 'No due date'} ({getDaysUntilLabel(task.daysUntilDue)})
                        </p>
                      </div>
                    </div>
                    <div className="text-right">
                      {task.estimatedCost !== undefined && (
                        <p className="font-semibold text-slate-900 dark:text-white">
                          {formatCurrency(task.estimatedCost)}
                        </p>
                      )}
                      <span className={`text-xs font-medium px-2 py-0.5 rounded-full ${
                        task.status === 'SCHEDULED'
                          ? 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400'
                          : 'bg-slate-100 text-slate-600 dark:bg-slate-600 dark:text-slate-300'
                      }`}>
                        {task.status}
                      </span>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Quick Actions */}
      <div className="card">
        <h2 className="text-lg font-semibold text-slate-900 dark:text-white mb-4">
          Quick Actions
        </h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <Link
            href="/app/bills/new"
            className="flex flex-col items-center gap-2 p-4 rounded-lg bg-slate-50 dark:bg-slate-700/50 hover:bg-slate-100 dark:hover:bg-slate-700 transition-colors border border-slate-200 dark:border-slate-600"
          >
            <div className="w-12 h-12 rounded-lg bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center text-2xl">
              💰
            </div>
            <span className="text-sm font-medium text-slate-700 dark:text-slate-300 text-center">Add a new bill</span>
          </Link>

          <Link
            href="/app/maintenance/new"
            className="flex flex-col items-center gap-2 p-4 rounded-lg bg-slate-50 dark:bg-slate-700/50 hover:bg-slate-100 dark:hover:bg-slate-700 transition-colors border border-slate-200 dark:border-slate-600"
          >
            <div className="w-12 h-12 rounded-lg bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center text-2xl">
              🔧
            </div>
            <span className="text-sm font-medium text-slate-700 dark:text-slate-300 text-center">Add a one-off task</span>
          </Link>

          <Link
            href="/app/requests/new"
            className="flex flex-col items-center gap-2 p-4 rounded-lg bg-slate-50 dark:bg-slate-700/50 hover:bg-slate-100 dark:hover:bg-slate-700 transition-colors border border-slate-200 dark:border-slate-600"
          >
            <div className="w-12 h-12 rounded-lg bg-red-100 dark:bg-red-900/30 flex items-center justify-center text-2xl">
              🚨
            </div>
            <span className="text-sm font-medium text-slate-700 dark:text-slate-300 text-center">Report a problem</span>
          </Link>

          <button
            onClick={() => {
              // TODO: Implement share functionality
              alert('Share house profile feature coming soon!');
            }}
            className="flex flex-col items-center gap-2 p-4 rounded-lg bg-slate-50 dark:bg-slate-700/50 hover:bg-slate-100 dark:hover:bg-slate-700 transition-colors border border-slate-200 dark:border-slate-600"
          >
            <div className="w-12 h-12 rounded-lg bg-green-100 dark:bg-green-900/30 flex items-center justify-center text-2xl">
              🔗
            </div>
            <span className="text-sm font-medium text-slate-700 dark:text-slate-300 text-center">Share house profile</span>
          </button>
        </div>
      </div>
    </div>
  );
}
