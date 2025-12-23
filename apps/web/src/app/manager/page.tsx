'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';
import Link from 'next/link';
import { useAuth } from '@/contexts/auth-context';
import { getApiClient } from '@/lib/api';
import type { ServiceRequestDetail, Household } from '@haven/core';
import {
  Plus,
  Home,
  MessageCircle,
  Calendar,
  Loader2,
  AlertCircle,
  ClipboardList,
  Phone,
  FileText,
  CheckSquare,
  ArrowRight,
  MoreVertical,
  Dog,
  Key,
  Bell,
} from 'lucide-react';

// ============================================================================
// MANAGER DASHBOARD PAGE
// Primary Color: Indigo (vs Emerald for homeowners)
// Target: Information-dense, power-user focused, mission control
// ============================================================================

// ============================================================================
// MOCK DATA
// ============================================================================

interface UrgentItem {
  id: string;
  type: 'emergency' | 'approval' | 'overdue' | 'contract';
  household: string;
  address: string;
  title: string;
  description: string;
  timeAgo: string;
  actions: string[];
}

interface ScheduleBlock {
  id: string;
  time: string;
  duration: string;
  type: 'site_visit' | 'call' | 'bill_pay' | 'handyman';
  household: string;
  address: string;
  title: string;
  vendor?: string;
  accessInfo?: { gate?: string; dog?: string };
}

interface Task {
  id: string;
  title: string;
  household: string;
  dueDate: string;
  status: 'pending' | 'in_progress' | 'overdue' | 'completed';
  source: 'homeowner' | 'system';
}

interface HouseholdStatus {
  id: string;
  name: string;
  address: string;
  status: 'urgent' | 'pending' | 'good';
  urgentCount: number;
  taskCount: number;
  unreadMessages: number;
  lastContact: string;
}

interface Activity {
  id: string;
  timeAgo: string;
  household: string;
  action: string;
  detail: string;
  type: 'request' | 'approval' | 'message' | 'payment';
}

const mockUrgentItems: UrgentItem[] = [
  {
    id: 'u1',
    type: 'emergency',
    household: 'Smith Family',
    address: '456 Oak Lane',
    title: 'Pipe burst under kitchen sink',
    description: 'Water damage spreading - vendor on standby awaiting approval',
    timeAgo: '2 min ago',
    actions: ['Call Homeowner', 'Approve Emergency', 'Dispatch Plumber']
  },
  {
    id: 'u2',
    type: 'approval',
    household: 'Johnson Residence',
    address: '789 Maple Dr',
    title: 'HVAC repair quote - $2,847',
    description: 'Awaiting homeowner approval for 3 days',
    timeAgo: '3 days ago',
    actions: ['Send Reminder', 'Call to Discuss']
  },
  {
    id: 'u3',
    type: 'overdue',
    household: 'Garcia Home',
    address: '123 Pine St',
    title: 'Landscaper invoice overdue',
    description: 'Invoice #4521 - $340 - Due: Dec 15',
    timeAgo: '6 days overdue',
    actions: ['Pay Now', 'Contact Vendor']
  },
];

const mockSchedule: ScheduleBlock[] = [
  {
    id: 's1',
    time: '9:00 AM',
    duration: '2 hrs',
    type: 'site_visit',
    household: 'Smith Family',
    address: '456 Oak Lane',
    title: 'HVAC Tech Visit',
    vendor: 'AirFlow HVAC',
    accessInfo: { gate: '1247', dog: 'Max (friendly)' }
  },
  {
    id: 's2',
    time: '11:30 AM',
    duration: '30 min',
    type: 'call',
    household: 'Johnson Residence',
    address: '789 Maple Dr',
    title: 'Monthly Check-in Call',
  },
  {
    id: 's3',
    time: '1:00 PM',
    duration: '1 hr',
    type: 'bill_pay',
    household: 'All Households',
    address: '',
    title: 'Weekly Bill Processing',
  },
  {
    id: 's4',
    time: '3:00 PM',
    duration: '2 hrs',
    type: 'handyman',
    household: 'Miller Family',
    address: '567 Cedar Ave',
    title: 'Handyman Visit - 3 Tasks',
    accessInfo: { gate: '9876' }
  },
];

const mockTasks: { fromHomeowners: Task[]; systemGenerated: Task[] } = {
  fromHomeowners: [
    { id: 't1', title: 'Research summer camps for Emma', household: 'Smith Family', dueDate: 'Dec 28', status: 'in_progress', source: 'homeowner' },
    { id: 't2', title: 'Get quotes for bathroom remodel', household: 'Johnson Residence', dueDate: 'Dec 30', status: 'pending', source: 'homeowner' },
    { id: 't3', title: 'Schedule annual tree trimming', household: 'Garcia Home', dueDate: 'Jan 5', status: 'pending', source: 'homeowner' },
  ],
  systemGenerated: [
    { id: 't4', title: 'Schedule HVAC filter change', household: 'Miller Family', dueDate: 'TODAY', status: 'overdue', source: 'system' },
    { id: 't5', title: 'Review monthly expense report', household: 'All Households', dueDate: 'Dec 26', status: 'pending', source: 'system' },
    { id: 't6', title: 'Renew pest control contract', household: 'Smith Family', dueDate: 'Jan 1', status: 'pending', source: 'system' },
  ]
};

const mockHouseholds: HouseholdStatus[] = [
  { id: 'h1', name: 'Smith Family', address: '456 Oak Lane', status: 'urgent', urgentCount: 2, taskCount: 3, unreadMessages: 2, lastContact: '2h ago' },
  { id: 'h2', name: 'Johnson Residence', address: '789 Maple Dr', status: 'pending', urgentCount: 0, taskCount: 2, unreadMessages: 1, lastContact: '1d ago' },
  { id: 'h3', name: 'Garcia Home', address: '123 Pine St', status: 'pending', urgentCount: 0, taskCount: 1, unreadMessages: 0, lastContact: '3d ago' },
  { id: 'h4', name: 'Miller Family', address: '567 Cedar Ave', status: 'good', urgentCount: 0, taskCount: 1, unreadMessages: 0, lastContact: '5h ago' },
  { id: 'h5', name: 'Williams Estate', address: '890 Elm Blvd', status: 'good', urgentCount: 0, taskCount: 0, unreadMessages: 0, lastContact: '1w ago' },
  { id: 'h6', name: 'Brown Residence', address: '234 Birch Ln', status: 'good', urgentCount: 0, taskCount: 2, unreadMessages: 1, lastContact: '4h ago' },
];

const mockActivities: Activity[] = [
  { id: 'a1', timeAgo: '2 min ago', household: 'Smith', action: 'submitted new request', detail: 'Kitchen faucet drip', type: 'request' },
  { id: 'a2', timeAgo: '15 min ago', household: 'Johnson', action: 'approved quote', detail: 'Window cleaning - $180', type: 'approval' },
  { id: 'a3', timeAgo: '1 hr ago', household: 'Garcia', action: 'sent message', detail: 'Question about landscaper', type: 'message' },
  { id: 'a4', timeAgo: '2 hrs ago', household: 'Miller', action: 'payment processed', detail: 'Electric bill - $247', type: 'payment' },
  { id: 'a5', timeAgo: '3 hrs ago', household: 'Smith', action: 'work order completed', detail: 'Garage door repair', type: 'request' },
];

// ============================================================================
// MAIN COMPONENT
// ============================================================================

export default function ManagerDashboardPage() {
  const { user } = useAuth();
  const [requests, setRequests] = useState<ServiceRequestDetail[]>([]);
  const [households, setHouseholds] = useState<Household[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');
  const [completedTasks, setCompletedTasks] = useState<string[]>([]);
  const [activityFilter, setActivityFilter] = useState<'all' | 'requests' | 'approvals' | 'messages'>('all');

  const api = getApiClient();

  const loadData = useCallback(async () => {
    try {
      const [requestsData, householdsData] = await Promise.all([
        api.getManagerRequests(),
        api.getHouseholds(),
      ]);
      setRequests(requestsData);
      setHouseholds(householdsData);
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

  // Calculate stats from real data + mock
  const stats = useMemo(() => {
    const realHouseholds = households.length || mockHouseholds.length;
    const urgentFromRequests = requests.filter((r) => r.priority === 'URGENT' && r.status !== 'COMPLETED').length;
    return {
      householdsManaged: realHouseholds,
      urgentItems: Math.max(urgentFromRequests, mockUrgentItems.length),
      tasksToday: mockTasks.fromHomeowners.length + mockTasks.systemGenerated.length,
      pendingApprovals: 4,
      billsDueThisWeek: 12847.23,
    };
  }, [requests, households]);

  // Filter activities
  const filteredActivities = useMemo(() => {
    if (activityFilter === 'all') return mockActivities;
    return mockActivities.filter(a => {
      if (activityFilter === 'requests') return a.type === 'request';
      if (activityFilter === 'approvals') return a.type === 'approval';
      if (activityFilter === 'messages') return a.type === 'message';
      return true;
    });
  }, [activityFilter]);

  const handleTaskComplete = (taskId: string) => {
    setCompletedTasks(prev =>
      prev.includes(taskId) ? prev.filter(id => id !== taskId) : [...prev, taskId]
    );
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="flex flex-col items-center gap-3">
          <Loader2 className="w-8 h-8 animate-spin text-indigo-600" />
          <p className="text-slate-500">Loading dashboard...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6 pb-20">
      {/* ================================================================== */}
      {/* PAGE HEADER WITH STATS */}
      {/* ================================================================== */}
      <div className="flex flex-col lg:flex-row lg:items-start lg:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">
            Good {getTimeOfDay()}, {user?.firstName || 'Sarah'}
          </h1>
          <p className="text-slate-600 mt-1">{formatCurrentDate()}</p>
        </div>
      </div>

      {/* Stats Row */}
      <div className="grid grid-cols-2 lg:grid-cols-5 gap-4">
        <StatCard
          label="Households"
          value={stats.householdsManaged}
          sublabel="managed"
          href="/manager/households"
        />
        <StatCard
          label="Urgent"
          value={stats.urgentItems}
          urgent={stats.urgentItems > 0}
          href="/manager/requests?priority=urgent"
        />
        <StatCard
          label="Tasks"
          value={stats.tasksToday}
          sublabel="today"
          href="/manager/tasks"
        />
        <StatCard
          label="Pending"
          value={stats.pendingApprovals}
          sublabel="Approval"
          href="/manager/requests?status=pending"
        />
        <StatCard
          label="Bills Due"
          value={`$${(stats.billsDueThisWeek / 1000).toFixed(1)}K`}
          sublabel="this week"
          href="/manager/payables"
        />
      </div>

      {/* Quick Actions */}
      <div className="flex flex-wrap items-center gap-2">
        <Link
          href="/manager/requests/new"
          className="inline-flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white font-medium rounded-lg hover:bg-indigo-700 transition-colors text-sm"
        >
          <Plus className="w-4 h-4" />
          New Request
        </Link>
        <Link
          href="/manager/work-orders/new"
          className="inline-flex items-center gap-2 px-4 py-2 bg-white border border-slate-200 text-slate-700 font-medium rounded-lg hover:bg-slate-50 transition-colors text-sm"
        >
          <ClipboardList className="w-4 h-4" />
          Work Order
        </Link>
        <Link
          href="/manager/payables/new"
          className="inline-flex items-center gap-2 px-4 py-2 bg-white border border-slate-200 text-slate-700 font-medium rounded-lg hover:bg-slate-50 transition-colors text-sm"
        >
          <FileText className="w-4 h-4" />
          Log Expense
        </Link>
        <button
          className="inline-flex items-center gap-2 px-4 py-2 bg-white border border-slate-200 text-slate-700 font-medium rounded-lg hover:bg-slate-50 transition-colors text-sm"
        >
          <Phone className="w-4 h-4" />
          Start Call
        </button>
      </div>

      {/* Error */}
      {error && (
        <div className="p-4 rounded-xl bg-red-50 border border-red-200 flex items-start gap-3">
          <AlertCircle className="w-5 h-5 text-red-600 flex-shrink-0 mt-0.5" />
          <p className="text-sm text-red-600">{error}</p>
        </div>
      )}

      {/* ================================================================== */}
      {/* URGENT ATTENTION SECTION */}
      {/* ================================================================== */}
      {mockUrgentItems.length > 0 && (
        <div className="bg-red-50 rounded-xl border border-red-200 p-4">
          <div className="flex items-center gap-2 mb-4">
            <span className="w-2 h-2 rounded-full bg-red-500 animate-pulse" />
            <h2 className="font-semibold text-red-900 uppercase tracking-wide text-sm">
              Urgent Attention Required
            </h2>
            <span className="px-2 py-0.5 text-xs font-medium rounded-full bg-red-100 text-red-700">
              {mockUrgentItems.length}
            </span>
          </div>
          <div className="space-y-3">
            {mockUrgentItems.map((item) => (
              <UrgentItemCard key={item.id} item={item} />
            ))}
          </div>
        </div>
      )}

      {/* ================================================================== */}
      {/* TWO COLUMN LAYOUT: Schedule + Tasks */}
      {/* ================================================================== */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Today's Schedule */}
        <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
          <div className="px-4 py-3 border-b border-slate-100 bg-slate-50 flex items-center justify-between">
            <h3 className="font-semibold text-slate-900 flex items-center gap-2">
              <Calendar className="w-4 h-4 text-indigo-600" />
              Today&apos;s Schedule
            </h3>
            <div className="flex items-center gap-2">
              <button className="text-xs text-slate-500 hover:text-slate-700 font-medium">Add Block</button>
              <span className="text-slate-300">|</span>
              <Link href="/manager/calendar" className="text-xs text-indigo-600 hover:text-indigo-700 font-medium">
                View Week
              </Link>
            </div>
          </div>
          <div className="divide-y divide-slate-100">
            {mockSchedule.map((block) => (
              <ScheduleBlock key={block.id} block={block} />
            ))}
          </div>
        </div>

        {/* Task Queue */}
        <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
          <div className="px-4 py-3 border-b border-slate-100 bg-slate-50 flex items-center justify-between">
            <h3 className="font-semibold text-slate-900 flex items-center gap-2">
              <CheckSquare className="w-4 h-4 text-indigo-600" />
              My Task Queue
            </h3>
            <select className="text-xs border border-slate-200 rounded px-2 py-1 text-slate-600">
              <option>All Tasks</option>
              <option>Due Today</option>
              <option>Overdue</option>
            </select>
          </div>
          <div className="divide-y divide-slate-100">
            {/* From Homeowners */}
            <div className="p-3 bg-slate-50/50">
              <div className="flex items-center justify-between">
                <span className="text-xs font-medium text-slate-500 uppercase tracking-wide">From Homeowners</span>
                <span className="px-2 py-0.5 text-xs font-medium rounded-full bg-indigo-100 text-indigo-700">
                  {mockTasks.fromHomeowners.length}
                </span>
              </div>
            </div>
            {mockTasks.fromHomeowners.map((task) => (
              <TaskItem
                key={task.id}
                task={task}
                completed={completedTasks.includes(task.id)}
                onToggle={() => handleTaskComplete(task.id)}
              />
            ))}

            {/* System Generated */}
            <div className="p-3 bg-slate-50/50">
              <div className="flex items-center justify-between">
                <span className="text-xs font-medium text-slate-500 uppercase tracking-wide">System Generated</span>
                <span className="px-2 py-0.5 text-xs font-medium rounded-full bg-slate-100 text-slate-600">
                  {mockTasks.systemGenerated.length}
                </span>
              </div>
            </div>
            {mockTasks.systemGenerated.map((task) => (
              <TaskItem
                key={task.id}
                task={task}
                completed={completedTasks.includes(task.id)}
                onToggle={() => handleTaskComplete(task.id)}
              />
            ))}
          </div>
        </div>
      </div>

      {/* ================================================================== */}
      {/* HOUSEHOLD STATUS GRID */}
      {/* ================================================================== */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
        <div className="px-4 py-3 border-b border-slate-100 bg-slate-50 flex items-center justify-between">
          <h3 className="font-semibold text-slate-900 flex items-center gap-2">
            <Home className="w-4 h-4 text-indigo-600" />
            My Households
          </h3>
          <Link href="/manager/households" className="text-sm text-indigo-600 hover:text-indigo-700 font-medium flex items-center gap-1">
            View All <ArrowRight className="w-4 h-4" />
          </Link>
        </div>
        <div className="p-4 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {mockHouseholds.map((household) => (
            <HouseholdStatusCard key={household.id} household={household} />
          ))}
        </div>
      </div>

      {/* ================================================================== */}
      {/* ACTIVITY FEED */}
      {/* ================================================================== */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
        <div className="px-4 py-3 border-b border-slate-100 bg-slate-50 flex items-center justify-between">
          <h3 className="font-semibold text-slate-900 flex items-center gap-2">
            <Bell className="w-4 h-4 text-indigo-600" />
            Recent Activity
          </h3>
          <select
            className="text-xs border border-slate-200 rounded px-2 py-1 text-slate-600"
            value={activityFilter}
            onChange={(e) => setActivityFilter(e.target.value as typeof activityFilter)}
          >
            <option value="all">All</option>
            <option value="requests">Requests</option>
            <option value="approvals">Approvals</option>
            <option value="messages">Messages</option>
          </select>
        </div>
        <div className="divide-y divide-slate-100">
          {filteredActivities.map((activity) => (
            <ActivityItem key={activity.id} activity={activity} />
          ))}
        </div>
        <div className="px-4 py-3 border-t border-slate-100 bg-slate-50">
          <Link href="/manager/activity" className="text-sm text-indigo-600 hover:text-indigo-700 font-medium flex items-center gap-1">
            View Full Activity Log <ArrowRight className="w-4 h-4" />
          </Link>
        </div>
      </div>
    </div>
  );
}

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
    weekday: 'short',
    month: 'short',
    day: 'numeric',
    year: 'numeric'
  });
}

// ============================================================================
// COMPONENTS
// ============================================================================

function StatCard({
  label,
  value,
  sublabel,
  urgent = false,
  href,
}: {
  label: string;
  value: string | number;
  sublabel?: string;
  urgent?: boolean;
  href: string;
}) {
  return (
    <Link
      href={href}
      className={`bg-white rounded-xl shadow-sm border p-4 text-center hover:shadow-md hover:border-indigo-200 transition-all ${
        urgent ? 'border-red-200' : 'border-slate-200'
      }`}
    >
      <p className={`text-2xl font-bold ${urgent ? 'text-red-600' : 'text-slate-900'}`}>
        {value}
      </p>
      <p className="text-xs text-slate-500 mt-1">
        {label}
        {sublabel && <span className="block">{sublabel}</span>}
      </p>
    </Link>
  );
}

function UrgentItemCard({ item }: { item: UrgentItem }) {
  const typeIcons = {
    emergency: '🚨',
    approval: '⏰',
    overdue: '⚠️',
    contract: '📄',
  };

  return (
    <div className="bg-white rounded-lg border border-red-200 p-4">
      <div className="flex items-start justify-between gap-4">
        <div className="flex items-start gap-3 min-w-0">
          <span className="text-xl">{typeIcons[item.type]}</span>
          <div className="min-w-0">
            <div className="flex items-center gap-2 mb-1">
              <span className="font-semibold text-slate-900">{item.household}</span>
              <span className="text-xs text-red-600 font-medium">{item.timeAgo}</span>
            </div>
            <p className="font-medium text-slate-900">{item.title}</p>
            <p className="text-sm text-slate-500 mt-0.5">{item.description}</p>
            <p className="text-xs text-slate-400 mt-1">{item.address}</p>
          </div>
        </div>
        <button className="p-1 hover:bg-slate-100 rounded">
          <MoreVertical className="w-4 h-4 text-slate-400" />
        </button>
      </div>
      <div className="flex items-center gap-2 mt-3 pt-3 border-t border-slate-100">
        {item.actions.map((action, index) => (
          <button
            key={action}
            className={`px-3 py-1.5 text-xs font-medium rounded-lg transition-colors ${
              index === 0
                ? 'bg-indigo-600 text-white hover:bg-indigo-700'
                : 'bg-slate-100 text-slate-700 hover:bg-slate-200'
            }`}
          >
            {action}
          </button>
        ))}
      </div>
    </div>
  );
}

function ScheduleBlock({ block }: { block: ScheduleBlock }) {
  const typeColors = {
    site_visit: 'border-l-indigo-500',
    call: 'border-l-blue-500',
    bill_pay: 'border-l-emerald-500',
    handyman: 'border-l-amber-500',
  };

  return (
    <div className="flex items-start gap-4 p-4 hover:bg-slate-50 transition-colors">
      <div className="text-right min-w-[70px]">
        <p className="text-lg font-bold text-slate-900">{block.time.split(' ')[0]}</p>
        <p className="text-xs text-slate-500">{block.time.split(' ')[1]}</p>
      </div>
      <div className={`flex-1 bg-slate-50 rounded-lg p-3 border-l-4 ${typeColors[block.type]}`}>
        <div className="flex items-start justify-between">
          <div>
            <p className="font-medium text-slate-900">{block.title}</p>
            <p className="text-sm text-slate-600">{block.household}</p>
            {block.vendor && (
              <p className="text-xs text-slate-500 mt-1">Vendor: {block.vendor}</p>
            )}
          </div>
          <span className="text-xs font-medium px-2 py-0.5 rounded-full bg-slate-200 text-slate-600">
            {block.duration}
          </span>
        </div>
        {block.accessInfo && (
          <div className="flex items-center gap-3 mt-2 pt-2 border-t border-slate-200">
            {block.accessInfo.gate && (
              <span className="flex items-center gap-1 text-xs text-slate-500">
                <Key className="w-3 h-3" /> {block.accessInfo.gate}
              </span>
            )}
            {block.accessInfo.dog && (
              <span className="flex items-center gap-1 text-xs text-slate-500">
                <Dog className="w-3 h-3" /> {block.accessInfo.dog}
              </span>
            )}
          </div>
        )}
      </div>
    </div>
  );
}

function TaskItem({
  task,
  completed,
  onToggle,
}: {
  task: Task;
  completed: boolean;
  onToggle: () => void;
}) {
  const statusColors: Record<string, string> = {
    pending: 'text-slate-500',
    in_progress: 'text-blue-600',
    overdue: 'text-red-600',
    completed: 'text-emerald-600',
  };

  const statusLabels: Record<string, string> = {
    pending: 'Pending',
    in_progress: 'In Progress',
    overdue: 'Overdue',
    completed: 'Done',
  };

  return (
    <div className={`flex items-start gap-3 p-3 hover:bg-slate-50 transition-colors ${completed ? 'opacity-50' : ''}`}>
      <input
        type="checkbox"
        checked={completed}
        onChange={onToggle}
        className="mt-1 w-4 h-4 rounded border-slate-300 text-indigo-600 focus:ring-indigo-600"
      />
      <div className="flex-1 min-w-0">
        <p className={`font-medium text-slate-900 text-sm ${completed ? 'line-through' : ''}`}>
          {task.title}
        </p>
        <p className="text-xs text-slate-500 mt-0.5">
          {task.household} • Due: {task.dueDate}
        </p>
      </div>
      <span className={`text-xs font-medium ${statusColors[task.status]}`}>
        {statusLabels[task.status]}
      </span>
    </div>
  );
}

function HouseholdStatusCard({ household }: { household: HouseholdStatus }) {
  const statusColors = {
    urgent: 'bg-red-500',
    pending: 'bg-amber-500',
    good: 'bg-emerald-500',
  };

  const statusLabels = {
    urgent: `🔴 ${household.urgentCount} urgent`,
    pending: `🟡 ${household.taskCount} pending`,
    good: '🟢 All good',
  };

  return (
    <Link
      href={`/manager/households/${household.id}`}
      className="p-4 rounded-xl border border-slate-200 hover:border-indigo-200 hover:shadow-md transition-all bg-white block"
    >
      <div className="flex items-start justify-between mb-2">
        <h4 className="font-semibold text-slate-900">{household.name}</h4>
        <span className={`w-2 h-2 rounded-full ${statusColors[household.status]}`} />
      </div>
      <p className="text-sm text-slate-500 mb-3">{household.address}</p>
      <div className="border-t border-slate-100 pt-3">
        <div className="flex items-center justify-between text-sm">
          <span className="text-slate-600">{statusLabels[household.status]}</span>
        </div>
        <div className="flex items-center gap-4 mt-2 text-xs text-slate-500">
          {household.taskCount > 0 && (
            <span>{household.taskCount} tasks</span>
          )}
          {household.unreadMessages > 0 && (
            <span className="flex items-center gap-1">
              <MessageCircle className="w-3 h-3" /> {household.unreadMessages}
            </span>
          )}
        </div>
        <p className="text-xs text-slate-400 mt-2">Last contact: {household.lastContact}</p>
      </div>
    </Link>
  );
}

function ActivityItem({ activity }: { activity: Activity }) {
  const typeColors = {
    request: 'bg-indigo-400',
    approval: 'bg-emerald-400',
    message: 'bg-blue-400',
    payment: 'bg-amber-400',
  };

  return (
    <div className="flex items-start gap-3 px-4 py-3">
      <div className="flex flex-col items-center">
        <span className={`w-2 h-2 rounded-full ${typeColors[activity.type]} mt-2`} />
      </div>
      <div className="flex-1 min-w-0">
        <p className="text-sm text-slate-900">
          <span className="font-medium">{activity.household}</span>{' '}
          <span className="text-slate-600">{activity.action}</span>
        </p>
        <p className="text-sm text-slate-500">{activity.detail}</p>
      </div>
      <span className="text-xs text-slate-400 whitespace-nowrap">{activity.timeAgo}</span>
    </div>
  );
}
