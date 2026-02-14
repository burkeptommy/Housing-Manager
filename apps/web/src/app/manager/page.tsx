'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';
import Link from 'next/link';
import { useAuth } from '@/contexts/auth-context';
import { Card, Badge, Button, Avatar } from '@/components/ui';
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
  Dog,
  Key,
  Bell,
  Users,
  DollarSign,
  ChevronRight,
  Zap,
  Clock,
} from 'lucide-react';

// ============================================================================
// TYPES
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

// ============================================================================
// MOCK DATA
// ============================================================================

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
    day: 'numeric',
    year: 'numeric'
  });
}

function formatTimeAgo(date: Date): string {
  const seconds = Math.floor((new Date().getTime() - date.getTime()) / 1000);
  if (seconds < 60) return 'Just now';
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) return `${minutes} min ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours} hr ago`;
  const days = Math.floor(hours / 24);
  return `${days}d ago`;
}

function mapCategoryToType(category: string): 'request' | 'approval' | 'message' | 'payment' {
  const map: Record<string, 'request' | 'approval' | 'message' | 'payment'> = {
    BILLING: 'payment',
    SERVICE: 'request',
    MAINTENANCE: 'request',
    PROPERTY: 'request',
    COMMUNICATION: 'message',
    APPROVAL: 'approval',
  };
  return map[category] || 'request';
}

// ============================================================================
// COMPONENTS - PREMIUM REDESIGN
// ============================================================================

// Hero Header
function HeroHeader({ userName, stats }: { userName: string; stats: { householdsManaged: number; urgentItems: number; tasksToday: number; pendingApprovals: number; billsDueThisWeek: number } }) {
  return (
    <div className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-indigo-600 via-indigo-500 to-purple-500 p-8 text-white mb-8">
      {/* Background Pattern */}
      <div className="absolute inset-0 opacity-10">
        <div className="absolute top-0 right-0 w-96 h-96 bg-white rounded-full -translate-y-1/2 translate-x-1/2" />
        <div className="absolute bottom-0 left-0 w-64 h-64 bg-white rounded-full translate-y-1/2 -translate-x-1/2" />
      </div>

      <div className="relative">
        <div className="flex items-start justify-between mb-8">
          <div>
            <p className="text-indigo-200 text-sm font-medium mb-1">{formatCurrentDate()}</p>
            <h1 className="text-3xl lg:text-4xl font-bold tracking-tight text-white">
              Good {getTimeOfDay()}, {userName}
            </h1>
            <p className="text-indigo-200 mt-2">Managing {stats.householdsManaged} households</p>
          </div>
          <Avatar name={userName} type="female" size="xl" />
        </div>

        {/* Quick Stats */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <Link href="/manager/requests?priority=urgent" className="bg-white/10 backdrop-blur-sm rounded-xl p-4 hover:bg-white/20 transition-colors">
            <div className="flex items-center gap-2 mb-2">
              <Zap className="w-4 h-4 text-red-300" />
              <p className="text-indigo-200 text-xs font-medium uppercase tracking-wider">Urgent</p>
            </div>
            <p className="text-3xl font-bold">{stats.urgentItems}</p>
          </Link>
          <Link href="/manager/tasks" className="bg-white/10 backdrop-blur-sm rounded-xl p-4 hover:bg-white/20 transition-colors">
            <div className="flex items-center gap-2 mb-2">
              <CheckSquare className="w-4 h-4 text-indigo-200" />
              <p className="text-indigo-200 text-xs font-medium uppercase tracking-wider">Tasks Today</p>
            </div>
            <p className="text-3xl font-bold">{stats.tasksToday}</p>
          </Link>
          <Link href="/manager/requests?status=pending" className="bg-white/10 backdrop-blur-sm rounded-xl p-4 hover:bg-white/20 transition-colors">
            <div className="flex items-center gap-2 mb-2">
              <Clock className="w-4 h-4 text-amber-300" />
              <p className="text-indigo-200 text-xs font-medium uppercase tracking-wider">Pending</p>
            </div>
            <p className="text-3xl font-bold">{stats.pendingApprovals}</p>
          </Link>
          <Link href="/manager/payables" className="bg-white/10 backdrop-blur-sm rounded-xl p-4 hover:bg-white/20 transition-colors">
            <div className="flex items-center gap-2 mb-2">
              <DollarSign className="w-4 h-4 text-emerald-300" />
              <p className="text-indigo-200 text-xs font-medium uppercase tracking-wider">Bills Due</p>
            </div>
            <p className="text-3xl font-bold">${(stats.billsDueThisWeek / 1000).toFixed(1)}K</p>
          </Link>
        </div>
      </div>
    </div>
  );
}

// Quick Actions Bar
function QuickActionsBar() {
  return (
    <div className="flex flex-wrap items-center gap-3 mb-8">
      <Link href="/manager/requests/new">
        <Button leftIcon={<Plus className="w-4 h-4" />}>New Request</Button>
      </Link>
      <Link href="/manager/work-orders/new">
        <Button variant="secondary" leftIcon={<ClipboardList className="w-4 h-4" />}>Work Order</Button>
      </Link>
      <Link href="/manager/payables/new">
        <Button variant="secondary" leftIcon={<FileText className="w-4 h-4" />}>Log Expense</Button>
      </Link>
      <Button variant="ghost" leftIcon={<Phone className="w-4 h-4" />}>Start Call</Button>
    </div>
  );
}

// Urgent Alert Card
function UrgentAlertCard({ item }: { item: UrgentItem }) {
  const typeIcons = {
    emergency: '🚨',
    approval: '⏰',
    overdue: '⚠️',
    contract: '📄',
  };

  const typeColors = {
    emergency: 'from-red-500 to-rose-500',
    approval: 'from-amber-500 to-orange-500',
    overdue: 'from-red-400 to-rose-400',
    contract: 'from-blue-500 to-indigo-500',
  };

  return (
    <div className="bg-white rounded-xl border border-red-100 shadow-lg shadow-red-500/5 overflow-hidden">
      <div className={`bg-gradient-to-r ${typeColors[item.type]} px-4 py-2 flex items-center justify-between`}>
        <div className="flex items-center gap-2">
          <span className="text-lg">{typeIcons[item.type]}</span>
          <span className="text-sm font-semibold text-white">{item.household}</span>
        </div>
        <span className="text-xs text-white/80">{item.timeAgo}</span>
      </div>
      <div className="p-4">
        <h4 className="font-bold text-neutral-900 mb-1">{item.title}</h4>
        <p className="text-sm text-neutral-600 mb-1">{item.description}</p>
        <p className="text-xs text-neutral-400">{item.address}</p>
        <div className="flex flex-wrap gap-2 mt-4">
          {item.actions.map((action, index) => (
            <Button
              key={action}
              variant={index === 0 ? 'primary' : 'secondary'}
              size="sm"
            >
              {action}
            </Button>
          ))}
        </div>
      </div>
    </div>
  );
}

// Urgent Section
function UrgentSection({ items }: { items: UrgentItem[] }) {
  if (items.length === 0) return null;

  return (
    <div className="mb-8">
      <div className="flex items-center gap-2 mb-4">
        <span className="flex h-2 w-2">
          <span className="animate-ping absolute inline-flex h-2 w-2 rounded-full bg-red-400 opacity-75" />
          <span className="relative inline-flex rounded-full h-2 w-2 bg-red-500" />
        </span>
        <h2 className="text-lg font-bold text-neutral-900">Urgent Attention Required</h2>
        <Badge variant="error">{items.length}</Badge>
      </div>
      <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-4">
        {items.map((item) => (
          <UrgentAlertCard key={item.id} item={item} />
        ))}
      </div>
    </div>
  );
}

// Schedule Block Component
function ScheduleBlockCard({ block }: { block: ScheduleBlock }) {
  const typeStyles = {
    site_visit: { border: 'border-l-indigo-500', bg: 'bg-indigo-50', icon: Home },
    call: { border: 'border-l-blue-500', bg: 'bg-blue-50', icon: Phone },
    bill_pay: { border: 'border-l-emerald-500', bg: 'bg-emerald-50', icon: DollarSign },
    handyman: { border: 'border-l-amber-500', bg: 'bg-amber-50', icon: ClipboardList },
  };

  const style = typeStyles[block.type];
  const Icon = style.icon;

  return (
    <div className={`flex items-start gap-4 p-4 hover:bg-neutral-50 transition-colors rounded-xl`}>
      <div className="text-right min-w-[60px]">
        <p className="text-lg font-bold text-neutral-900">{block.time.split(' ')[0]}</p>
        <p className="text-xs text-neutral-500 uppercase">{block.time.split(' ')[1]}</p>
      </div>
      <div className={`flex-1 rounded-xl p-4 border-l-4 ${style.border} ${style.bg}`}>
        <div className="flex items-start justify-between">
          <div className="flex items-start gap-3">
            <div className="p-2 bg-white rounded-lg shadow-sm">
              <Icon className="w-4 h-4 text-neutral-600" />
            </div>
            <div>
              <p className="font-semibold text-neutral-900">{block.title}</p>
              <p className="text-sm text-neutral-600">{block.household}</p>
              {block.vendor && (
                <p className="text-xs text-neutral-500 mt-1">Vendor: {block.vendor}</p>
              )}
            </div>
          </div>
          <Badge variant="neutral" size="sm">{block.duration}</Badge>
        </div>
        {block.accessInfo && (
          <div className="flex items-center gap-4 mt-3 pt-3 border-t border-white/50">
            {block.accessInfo.gate && (
              <span className="flex items-center gap-1.5 text-xs text-neutral-600 bg-white px-2 py-1 rounded-lg">
                <Key className="w-3 h-3" /> {block.accessInfo.gate}
              </span>
            )}
            {block.accessInfo.dog && (
              <span className="flex items-center gap-1.5 text-xs text-neutral-600 bg-white px-2 py-1 rounded-lg">
                <Dog className="w-3 h-3" /> {block.accessInfo.dog}
              </span>
            )}
          </div>
        )}
      </div>
    </div>
  );
}

// Task Item Component
function TaskItemCard({
  task,
  completed,
  onToggle,
}: {
  task: Task;
  completed: boolean;
  onToggle: () => void;
}) {
  const statusBadge = {
    pending: { variant: 'neutral' as const, label: 'Pending' },
    in_progress: { variant: 'info' as const, label: 'In Progress' },
    overdue: { variant: 'error' as const, label: 'Overdue' },
    completed: { variant: 'success' as const, label: 'Done' },
  };

  const { variant, label } = statusBadge[task.status];

  return (
    <div className={`flex items-start gap-3 p-4 hover:bg-neutral-50 transition-colors rounded-xl ${completed ? 'opacity-50' : ''}`}>
      <input
        type="checkbox"
        checked={completed}
        onChange={onToggle}
        className="mt-1 w-4 h-4 rounded border-neutral-300 text-indigo-600 focus:ring-indigo-500"
      />
      <div className="flex-1 min-w-0">
        <p className={`font-medium text-neutral-900 ${completed ? 'line-through' : ''}`}>
          {task.title}
        </p>
        <p className="text-sm text-neutral-500 mt-0.5">
          {task.household} • Due: <span className={task.status === 'overdue' ? 'text-red-600 font-medium' : ''}>{task.dueDate}</span>
        </p>
      </div>
      <Badge variant={variant} size="sm">{label}</Badge>
    </div>
  );
}

// Household Status Card
function HouseholdCard({ household }: { household: HouseholdStatus }) {
  const statusColors = {
    urgent: { bg: 'bg-red-500', ring: 'ring-red-100' },
    pending: { bg: 'bg-amber-500', ring: 'ring-amber-100' },
    good: { bg: 'bg-emerald-500', ring: 'ring-emerald-100' },
  };

  const statusLabels = {
    urgent: 'Urgent',
    pending: 'Pending',
    good: 'All Good',
  };

  return (
    <Link
      href={`/manager/households/${household.id}`}
      className="group p-5 rounded-2xl border border-neutral-100 hover:border-indigo-200 hover:shadow-lg transition-all bg-white"
    >
      <div className="flex items-start justify-between mb-3">
        <div>
          <h4 className="font-bold text-neutral-900 group-hover:text-indigo-600 transition-colors">{household.name}</h4>
          <p className="text-sm text-neutral-500">{household.address}</p>
        </div>
        <span className={`w-3 h-3 rounded-full ${statusColors[household.status].bg} ring-4 ${statusColors[household.status].ring}`} />
      </div>
      <div className="flex items-center gap-2 mb-3">
        <Badge
          variant={household.status === 'urgent' ? 'error' : household.status === 'pending' ? 'warning' : 'success'}
          size="sm"
        >
          {statusLabels[household.status]}
        </Badge>
        {household.taskCount > 0 && (
          <Badge variant="neutral" size="sm">{household.taskCount} tasks</Badge>
        )}
      </div>
      <div className="flex items-center justify-between text-xs text-neutral-500 pt-3 border-t border-neutral-50">
        <span>Last contact: {household.lastContact}</span>
        {household.unreadMessages > 0 && (
          <span className="flex items-center gap-1 text-indigo-600">
            <MessageCircle className="w-3 h-3" /> {household.unreadMessages} new
          </span>
        )}
      </div>
    </Link>
  );
}

// Activity Item
function ActivityItemCard({ activity }: { activity: Activity }) {
  const typeStyles = {
    request: { color: 'bg-indigo-500', icon: ClipboardList },
    approval: { color: 'bg-emerald-500', icon: CheckSquare },
    message: { color: 'bg-blue-500', icon: MessageCircle },
    payment: { color: 'bg-amber-500', icon: DollarSign },
  };

  const style = typeStyles[activity.type];
  const Icon = style.icon;

  return (
    <div className="flex items-start gap-3 p-4 hover:bg-neutral-50 transition-colors rounded-xl">
      <div className={`p-2 rounded-lg ${style.color}`}>
        <Icon className="w-3 h-3 text-white" />
      </div>
      <div className="flex-1 min-w-0">
        <p className="text-sm text-neutral-900">
          <span className="font-semibold">{activity.household}</span>{' '}
          <span className="text-neutral-600">{activity.action}</span>
        </p>
        <p className="text-sm text-neutral-500">{activity.detail}</p>
      </div>
      <span className="text-xs text-neutral-400 whitespace-nowrap">{activity.timeAgo}</span>
    </div>
  );
}

// ============================================================================
// MAIN COMPONENT
// ============================================================================

export default function ManagerDashboardPage() {
  const { user, getIdToken } = useAuth();
  const [dashboardData, setDashboardData] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');
  const [completedTasks, setCompletedTasks] = useState<string[]>([]);
  const [activityFilter, setActivityFilter] = useState<'all' | 'requests' | 'approvals' | 'messages'>('all');

  const loadData = useCallback(async () => {
    try {
      const token = await getIdToken();
      if (!token) {
        setError('Not authenticated');
        setIsLoading(false);
        return;
      }

      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      const response = await fetch(`${apiUrl}/manager/dashboard`, {
        headers: { Authorization: `Bearer ${token}` },
      });

      if (response.ok) {
        const data = await response.json();
        setDashboardData(data);
      } else {
        console.error('Failed to load dashboard:', response.status);
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
  }, [getIdToken]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  // Calculate stats from real data or fallback to mock
  const stats = useMemo(() => {
    if (dashboardData?.stats) {
      return {
        householdsManaged: dashboardData.stats.householdsManaged,
        urgentItems: dashboardData.stats.urgentItems,
        tasksToday: dashboardData.stats.tasksToday || mockTasks.fromHomeowners.length + mockTasks.systemGenerated.length,
        pendingApprovals: dashboardData.stats.pendingOnboarding,
        billsDueThisWeek: dashboardData.stats.billsDueThisWeek,
      };
    }

    return {
      householdsManaged: mockHouseholds.length,
      urgentItems: mockUrgentItems.length,
      tasksToday: mockTasks.fromHomeowners.length + mockTasks.systemGenerated.length,
      pendingApprovals: 4,
      billsDueThisWeek: 12847.23,
    };
  }, [dashboardData]);

  // Get households from API or fallback to mock
  const displayHouseholds = useMemo(() => {
    if (dashboardData?.households?.length > 0) {
      return dashboardData.households.map((h: any) => ({
        id: h.id,
        name: h.name,
        address: h.address || 'No address',
        status: h.status || 'good',
        urgentCount: h.urgentCount || 0,
        taskCount: h.taskCount || 0,
        unreadMessages: h.unreadMessages || 0,
        lastContact: h.lastContact || 'Recently',
      }));
    }
    return mockHouseholds;
  }, [dashboardData]);

  // Get activity from API or fallback to mock
  const displayActivity = useMemo(() => {
    if (dashboardData?.recentActivity?.length > 0) {
      return dashboardData.recentActivity.map((a: any) => ({
        id: a.id,
        timeAgo: formatTimeAgo(new Date(a.createdAt)),
        household: a.householdName,
        action: a.title,
        detail: a.description || '',
        type: mapCategoryToType(a.category),
      }));
    }
    return mockActivities;
  }, [dashboardData]);

  // Filter activities
  const filteredActivities = useMemo(() => {
    const activities = displayActivity;
    if (activityFilter === 'all') return activities;
    return activities.filter((a: Activity) => {
      if (activityFilter === 'requests') return a.type === 'request';
      if (activityFilter === 'approvals') return a.type === 'approval';
      if (activityFilter === 'messages') return a.type === 'message';
      return true;
    });
  }, [activityFilter, displayActivity]);

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
          <p className="text-neutral-500">Loading dashboard...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6 pb-20">
      {/* Hero Header */}
      <HeroHeader userName={user?.firstName || 'Sarah'} stats={stats} />

      {/* Quick Actions */}
      <QuickActionsBar />

      {/* Error */}
      {error && (
        <div className="p-4 rounded-xl bg-red-50 border border-red-200 flex items-start gap-3">
          <AlertCircle className="w-5 h-5 text-red-600 flex-shrink-0 mt-0.5" />
          <p className="text-sm text-red-600">{error}</p>
        </div>
      )}

      {/* Urgent Section */}
      <UrgentSection items={mockUrgentItems} />

      {/* Two Column Layout: Schedule + Tasks */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Today's Schedule */}
        <Card padding="none">
          <div className="px-6 py-4 border-b border-neutral-100 flex items-center justify-between">
            <div className="flex items-center gap-2">
              <div className="p-2 bg-indigo-100 rounded-lg">
                <Calendar className="w-4 h-4 text-indigo-600" />
              </div>
              <h3 className="font-bold text-neutral-900">Today's Schedule</h3>
            </div>
            <Link href="/manager/calendar" className="text-sm text-indigo-600 hover:text-indigo-700 font-medium flex items-center gap-1">
              View Week <ChevronRight className="w-4 h-4" />
            </Link>
          </div>
          <div className="p-2 space-y-1">
            {mockSchedule.map((block) => (
              <ScheduleBlockCard key={block.id} block={block} />
            ))}
          </div>
        </Card>

        {/* Task Queue */}
        <Card padding="none">
          <div className="px-6 py-4 border-b border-neutral-100 flex items-center justify-between">
            <div className="flex items-center gap-2">
              <div className="p-2 bg-indigo-100 rounded-lg">
                <CheckSquare className="w-4 h-4 text-indigo-600" />
              </div>
              <h3 className="font-bold text-neutral-900">My Task Queue</h3>
            </div>
            <select className="text-sm border border-neutral-200 rounded-lg px-3 py-1.5 text-neutral-600 focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500">
              <option>All Tasks</option>
              <option>Due Today</option>
              <option>Overdue</option>
            </select>
          </div>
          <div className="p-2">
            {/* From Homeowners */}
            <div className="px-4 py-2">
              <div className="flex items-center justify-between">
                <span className="text-xs font-semibold text-neutral-500 uppercase tracking-wider">From Homeowners</span>
                <Badge variant="info" size="sm">{mockTasks.fromHomeowners.length}</Badge>
              </div>
            </div>
            {mockTasks.fromHomeowners.map((task) => (
              <TaskItemCard
                key={task.id}
                task={task}
                completed={completedTasks.includes(task.id)}
                onToggle={() => handleTaskComplete(task.id)}
              />
            ))}

            {/* System Generated */}
            <div className="px-4 py-2 mt-2">
              <div className="flex items-center justify-between">
                <span className="text-xs font-semibold text-neutral-500 uppercase tracking-wider">System Generated</span>
                <Badge variant="neutral" size="sm">{mockTasks.systemGenerated.length}</Badge>
              </div>
            </div>
            {mockTasks.systemGenerated.map((task) => (
              <TaskItemCard
                key={task.id}
                task={task}
                completed={completedTasks.includes(task.id)}
                onToggle={() => handleTaskComplete(task.id)}
              />
            ))}
          </div>
        </Card>
      </div>

      {/* Household Status Grid */}
      <Card padding="none">
        <div className="px-6 py-4 border-b border-neutral-100 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="p-2 bg-indigo-100 rounded-lg">
              <Users className="w-4 h-4 text-indigo-600" />
            </div>
            <h3 className="font-bold text-neutral-900">My Households</h3>
          </div>
          <Link href="/manager/households" className="text-sm text-indigo-600 hover:text-indigo-700 font-medium flex items-center gap-1">
            View All <ChevronRight className="w-4 h-4" />
          </Link>
        </div>
        <div className="p-6 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {displayHouseholds.map((household: HouseholdStatus) => (
            <HouseholdCard key={household.id} household={household} />
          ))}
        </div>
      </Card>

      {/* Activity Feed */}
      <Card padding="none">
        <div className="px-6 py-4 border-b border-neutral-100 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="p-2 bg-indigo-100 rounded-lg">
              <Bell className="w-4 h-4 text-indigo-600" />
            </div>
            <h3 className="font-bold text-neutral-900">Recent Activity</h3>
          </div>
          <select
            className="text-sm border border-neutral-200 rounded-lg px-3 py-1.5 text-neutral-600 focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500"
            value={activityFilter}
            onChange={(e) => setActivityFilter(e.target.value as typeof activityFilter)}
          >
            <option value="all">All Activity</option>
            <option value="requests">Requests</option>
            <option value="approvals">Approvals</option>
            <option value="messages">Messages</option>
          </select>
        </div>
        <div className="p-2 space-y-1">
          {filteredActivities.map((activity: Activity) => (
            <ActivityItemCard key={activity.id} activity={activity} />
          ))}
        </div>
        <div className="px-6 py-4 border-t border-neutral-100">
          <Link href="/manager/activity" className="text-sm text-indigo-600 hover:text-indigo-700 font-medium flex items-center gap-1">
            View Full Activity Log <ChevronRight className="w-4 h-4" />
          </Link>
        </div>
      </Card>
    </div>
  );
}
