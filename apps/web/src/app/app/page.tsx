'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useAuth } from '@/contexts/auth-context';
import {
  ShieldCheck,
  ShieldAlert,
  Thermometer,
  Droplets,
  Wifi,
  Users,
  DollarSign,
  Wrench,
  Calendar,
  CheckSquare,
  Plus,
  ClipboardList,
  ShoppingCart,
  Megaphone,
  X,
  Send,
  ChevronRight,
  Clock,
  AlertTriangle,
  CheckCircle2,
} from 'lucide-react';

// ============================================================================
// TYPES
// ============================================================================

interface WeatherData {
  temp: number;
  condition: string;
  city: string;
}

interface HomePulseData {
  security: { status: 'armed' | 'disarmed'; lastUpdate: string };
  climate: { temp: number; humidity: number };
  network: { status: 'online' | 'offline'; speed: string };
  occupancy: { count: number; members: string[] };
}

interface BudgetData {
  spent: number;
  limit: number;
  percentUsed: number;
}

interface MaintenanceItem {
  id: string;
  title: string;
  category: string;
  priority: 'HIGH' | 'MEDIUM' | 'LOW';
  dueDate: Date;
  isOverdue: boolean;
}

interface TimelineItem {
  id: string;
  type: 'event' | 'task';
  title: string;
  time: string;
  completed?: boolean;
}

interface FamilyMember {
  id: string;
  name: string;
  initials: string;
  isHome: boolean;
  avatarColor: string;
}

interface ActivityItem {
  id: string;
  description: string;
  timestamp: string;
  icon: string;
}

// ============================================================================
// MOCK DATA (Replace with API calls)
// ============================================================================

const mockWeather: WeatherData = {
  temp: 72,
  condition: 'Sunny',
  city: 'Beverly Hills',
};

const mockHomePulse: HomePulseData = {
  security: { status: 'armed', lastUpdate: '2 min ago' },
  climate: { temp: 70, humidity: 45 },
  network: { status: 'online', speed: '500 Mbps' },
  occupancy: { count: 3, members: ['Bob', 'Alice', 'Emma'] },
};

const mockBudget: BudgetData = {
  spent: 3200,
  limit: 5000,
  percentUsed: 64,
};

const mockUrgentMaintenance: MaintenanceItem[] = [
  {
    id: '1',
    title: 'HVAC Filter Replacement',
    category: 'HVAC',
    priority: 'HIGH',
    dueDate: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000),
    isOverdue: false,
  },
  {
    id: '2',
    title: 'Smoke Detector Battery Check',
    category: 'SAFETY',
    priority: 'HIGH',
    dueDate: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000),
    isOverdue: true,
  },
];

const mockTimeline: TimelineItem[] = [
  { id: '1', type: 'event', title: 'Plumber visit - Kitchen sink', time: '10:00 AM', completed: false },
  { id: '2', type: 'task', title: 'Pay electricity bill', time: '12:00 PM', completed: false },
  { id: '3', type: 'event', title: 'Emma soccer practice pickup', time: '3:30 PM', completed: false },
  { id: '4', type: 'task', title: 'Order pool chemicals', time: '5:00 PM', completed: true },
];

const mockFamily: FamilyMember[] = [
  { id: '1', name: 'Bob', initials: 'BH', isHome: true, avatarColor: 'bg-emerald-500' },
  { id: '2', name: 'Alice', initials: 'AH', isHome: true, avatarColor: 'bg-purple-500' },
  { id: '3', name: 'Emma', initials: 'EH', isHome: false, avatarColor: 'bg-pink-500' },
  { id: '4', name: 'Jake', initials: 'JH', isHome: true, avatarColor: 'bg-blue-500' },
];

const mockActivity: ActivityItem[] = [
  { id: '1', description: 'Alice paid the Water Bill', timestamp: '2 hours ago', icon: '💧' },
  { id: '2', description: 'Plumber confirmed appointment', timestamp: '4 hours ago', icon: '🔧' },
  { id: '3', description: 'HVAC filter change needed', timestamp: 'Yesterday', icon: '❄️' },
  { id: '4', description: 'Monthly budget updated', timestamp: '2 days ago', icon: '📊' },
];

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

function getGreeting(): string {
  const hour = new Date().getHours();
  if (hour < 12) return 'Good Morning';
  if (hour < 17) return 'Good Afternoon';
  return 'Good Evening';
}

function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    maximumFractionDigits: 0,
  }).format(amount);
}

function getPriorityColor(priority: string): string {
  switch (priority) {
    case 'HIGH':
      return 'text-red-600 bg-red-50';
    case 'MEDIUM':
      return 'text-amber-600 bg-amber-50';
    default:
      return 'text-slate-600 bg-slate-50';
  }
}

// ============================================================================
// COMPONENTS
// ============================================================================

// Smart Greeting Header
function SmartGreeting({ userName, weather }: { userName: string; weather: WeatherData }) {
  const priorityTasks = mockUrgentMaintenance.length;
  const todayEvents = mockTimeline.filter((t) => t.type === 'event').length;

  return (
    <div className="mb-8">
      <h1 className="text-3xl lg:text-4xl font-bold text-slate-900 tracking-tight">
        {getGreeting()}, {userName}
      </h1>
      <p className="text-slate-500 mt-2 text-lg">
        It's {weather.temp}°F and {weather.condition} in {weather.city}.
      </p>
      <p className="text-slate-600 mt-1">
        You have{' '}
        <span className="font-semibold text-emerald-600">{priorityTasks} priority tasks</span> and{' '}
        <span className="font-semibold text-emerald-600">{todayEvents} events</span> today.
      </p>
    </div>
  );
}

// Home Pulse Status Strip
function HomePulseStrip({ data }: { data: HomePulseData }) {
  const pulseCards = [
    {
      title: 'Security',
      icon: data.security.status === 'armed' ? ShieldCheck : ShieldAlert,
      value: data.security.status === 'armed' ? 'Armed' : 'Disarmed',
      subtitle: data.security.lastUpdate,
      color: data.security.status === 'armed' ? 'text-emerald-600' : 'text-amber-600',
      bgColor: data.security.status === 'armed' ? 'bg-emerald-50' : 'bg-amber-50',
    },
    {
      title: 'Climate',
      icon: Thermometer,
      value: `${data.climate.temp}°F`,
      subtitle: (
        <span className={data.climate.humidity > 60 ? 'text-amber-600' : ''}>
          <Droplets className="w-3 h-3 inline mr-1" />
          {data.climate.humidity}% humidity
        </span>
      ),
      color: 'text-blue-600',
      bgColor: 'bg-blue-50',
    },
    {
      title: 'Network',
      icon: Wifi,
      value: data.network.status === 'online' ? 'Online' : 'Offline',
      subtitle: data.network.speed,
      color: data.network.status === 'online' ? 'text-emerald-600' : 'text-red-600',
      bgColor: data.network.status === 'online' ? 'bg-emerald-50' : 'bg-red-50',
    },
    {
      title: 'Occupancy',
      icon: Users,
      value: `${data.occupancy.count} Home`,
      subtitle: data.occupancy.members.join(', '),
      color: 'text-purple-600',
      bgColor: 'bg-purple-50',
    },
  ];

  return (
    <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
      {pulseCards.map((card) => {
        const Icon = card.icon;
        return (
          <div
            key={card.title}
            className="bg-white rounded-xl shadow-sm border border-slate-200 p-4 hover:shadow-md transition-shadow"
          >
            <div className="flex items-center gap-3">
              <div className={`p-2 rounded-lg ${card.bgColor}`}>
                <Icon className={`w-5 h-5 ${card.color}`} />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-xs text-slate-500 uppercase tracking-wide">{card.title}</p>
                <p className={`font-semibold ${card.color}`}>{card.value}</p>
                <p className="text-xs text-slate-500 truncate">{card.subtitle}</p>
              </div>
            </div>
          </div>
        );
      })}
    </div>
  );
}

// Financial Health Widget (Money Gauge)
function FinancialHealthWidget({ budget }: { budget: BudgetData }) {
  const isOverBudget = budget.percentUsed > 90;
  const isWarning = budget.percentUsed > 75;
  const gaugeColor = isOverBudget ? 'bg-red-500' : isWarning ? 'bg-amber-500' : 'bg-emerald-500';

  return (
    <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-2">
          <DollarSign className="w-5 h-5 text-emerald-600" />
          <h3 className="font-semibold text-slate-900">Financial Health</h3>
        </div>
        <Link href="/app/billing" className="text-sm text-emerald-600 hover:text-emerald-700 font-medium">
          View Details
        </Link>
      </div>

      {/* Progress Bar Gauge */}
      <div className="mb-4">
        <div className="flex justify-between text-sm mb-2">
          <span className="text-slate-500">Month-to-Date Spend</span>
          <span className={`font-semibold ${isOverBudget ? 'text-red-600' : 'text-slate-900'}`}>
            {budget.percentUsed}%
          </span>
        </div>
        <div className="h-4 bg-slate-100 rounded-full overflow-hidden">
          <div
            className={`h-full ${gaugeColor} rounded-full transition-all duration-500`}
            style={{ width: `${Math.min(budget.percentUsed, 100)}%` }}
          />
        </div>
      </div>

      <p className="text-slate-600">
        <span className="font-semibold text-slate-900">{formatCurrency(budget.spent)}</span> spent of{' '}
        <span className="font-semibold text-slate-900">{formatCurrency(budget.limit)}</span> limit
      </p>

      {isOverBudget && (
        <div className="mt-3 p-3 bg-red-50 rounded-lg flex items-center gap-2">
          <AlertTriangle className="w-4 h-4 text-red-600" />
          <span className="text-sm text-red-700">You're approaching your budget limit</span>
        </div>
      )}
    </div>
  );
}

// Urgent Maintenance Widget
function UrgentMaintenanceWidget({ items }: { items: MaintenanceItem[] }) {
  if (items.length === 0) {
    return (
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
        <div className="flex items-center gap-2 mb-4">
          <Wrench className="w-5 h-5 text-emerald-600" />
          <h3 className="font-semibold text-slate-900">Urgent Maintenance</h3>
        </div>
        <div className="flex flex-col items-center justify-center py-8">
          <div className="w-16 h-16 rounded-full bg-emerald-50 flex items-center justify-center mb-4">
            <ShieldCheck className="w-8 h-8 text-emerald-600" />
          </div>
          <p className="text-slate-900 font-medium">All systems go!</p>
          <p className="text-slate-500 text-sm">No urgent maintenance needed</p>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-2">
          <Wrench className="w-5 h-5 text-amber-600" />
          <h3 className="font-semibold text-slate-900">Urgent Maintenance</h3>
          <span className="bg-red-100 text-red-700 text-xs font-medium px-2 py-0.5 rounded-full">
            {items.length}
          </span>
        </div>
        <Link href="/app/requests" className="text-sm text-emerald-600 hover:text-emerald-700 font-medium">
          View All
        </Link>
      </div>

      <div className="space-y-3">
        {items.map((item) => (
          <button
            key={item.id}
            className="w-full p-3 rounded-lg border border-slate-200 hover:border-emerald-300 hover:bg-emerald-50/50 transition-colors text-left group"
          >
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <span className={`text-xs font-medium px-2 py-1 rounded ${getPriorityColor(item.priority)}`}>
                  {item.priority}
                </span>
                <span className="font-medium text-slate-900">{item.title}</span>
              </div>
              <ChevronRight className="w-4 h-4 text-slate-400 group-hover:text-emerald-600" />
            </div>
            {item.isOverdue && (
              <p className="text-xs text-red-600 mt-1 ml-16">Overdue</p>
            )}
          </button>
        ))}
      </div>
    </div>
  );
}

// Today's Logistics Widget
function TodaysLogisticsWidget({ items }: { items: TimelineItem[] }) {
  return (
    <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-2">
          <Clock className="w-5 h-5 text-emerald-600" />
          <h3 className="font-semibold text-slate-900">Today's Logistics</h3>
        </div>
        <Link href="/app/calendar" className="text-sm text-emerald-600 hover:text-emerald-700 font-medium">
          Full Calendar
        </Link>
      </div>

      {items.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-8">
          <Calendar className="w-12 h-12 text-slate-300 mb-3" />
          <p className="text-slate-500">Nothing scheduled for today</p>
        </div>
      ) : (
        <div className="relative">
          {/* Timeline line */}
          <div className="absolute left-4 top-2 bottom-2 w-0.5 bg-slate-200" />

          <div className="space-y-4">
            {items.map((item) => (
              <div key={item.id} className="flex items-start gap-4 relative">
                {/* Timeline dot */}
                <div
                  className={`relative z-10 w-8 h-8 rounded-full flex items-center justify-center ${
                    item.completed
                      ? 'bg-emerald-100'
                      : item.type === 'event'
                        ? 'bg-blue-100'
                        : 'bg-slate-100'
                  }`}
                >
                  {item.completed ? (
                    <CheckCircle2 className="w-4 h-4 text-emerald-600" />
                  ) : item.type === 'event' ? (
                    <Calendar className="w-4 h-4 text-blue-600" />
                  ) : (
                    <CheckSquare className="w-4 h-4 text-slate-600" />
                  )}
                </div>

                {/* Content */}
                <div
                  className={`flex-1 p-3 rounded-lg border-l-4 ${
                    item.type === 'event'
                      ? 'bg-blue-50/50 border-blue-500'
                      : 'bg-slate-50 border-slate-300'
                  } ${item.completed ? 'opacity-60' : ''}`}
                >
                  <div className="flex items-center justify-between">
                    <p className={`font-medium ${item.completed ? 'line-through text-slate-500' : 'text-slate-900'}`}>
                      {item.title}
                    </p>
                    <span className="text-sm text-slate-500">{item.time}</span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

// Quick Action Dock
function QuickActionDock() {
  const [showExpenseModal, setShowExpenseModal] = useState(false);
  const [showRequestModal, setShowRequestModal] = useState(false);
  const [showShoppingPopover, setShowShoppingPopover] = useState(false);
  const [showBroadcastModal, setShowBroadcastModal] = useState(false);
  const [shoppingItem, setShoppingItem] = useState('');
  const [broadcastMessage, setBroadcastMessage] = useState('');

  const actions = [
    {
      label: 'Add Expense',
      icon: DollarSign,
      color: 'bg-emerald-600 hover:bg-emerald-700',
      onClick: () => setShowExpenseModal(true),
    },
    {
      label: 'Log Service',
      icon: ClipboardList,
      color: 'bg-blue-600 hover:bg-blue-700',
      onClick: () => setShowRequestModal(true),
    },
    {
      label: 'Shopping List',
      icon: ShoppingCart,
      color: 'bg-purple-600 hover:bg-purple-700',
      onClick: () => setShowShoppingPopover(true),
    },
    {
      label: 'Broadcast',
      icon: Megaphone,
      color: 'bg-amber-600 hover:bg-amber-700',
      onClick: () => setShowBroadcastModal(true),
    },
  ];

  return (
    <>
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-4">
        <h3 className="font-semibold text-slate-900 mb-4">Quick Actions</h3>
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
          {actions.map((action) => {
            const Icon = action.icon;
            return (
              <button
                key={action.label}
                onClick={action.onClick}
                className={`${action.color} text-white rounded-lg p-4 flex flex-col items-center gap-2 shadow-sm transition-colors`}
              >
                <Icon className="w-6 h-6" />
                <span className="text-sm font-medium">{action.label}</span>
              </button>
            );
          })}
        </div>
      </div>

      {/* Expense Modal */}
      {showExpenseModal && (
        <Modal title="Add Expense" onClose={() => setShowExpenseModal(false)}>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Description</label>
              <input
                type="text"
                className="w-full px-4 py-2 rounded-lg border border-slate-300 focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
                placeholder="What was this expense for?"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Amount</label>
              <input
                type="number"
                className="w-full px-4 py-2 rounded-lg border border-slate-300 focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
                placeholder="$0.00"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Category</label>
              <select className="w-full px-4 py-2 rounded-lg border border-slate-300 focus:ring-2 focus:ring-emerald-600 focus:border-transparent">
                <option>Utilities</option>
                <option>Maintenance</option>
                <option>Groceries</option>
                <option>Other</option>
              </select>
            </div>
            <button className="w-full bg-emerald-600 text-white rounded-lg py-2.5 font-medium hover:bg-emerald-700 transition-colors">
              Save Expense
            </button>
          </div>
        </Modal>
      )}

      {/* Service Request Modal */}
      {showRequestModal && (
        <Modal title="Log Service Request" onClose={() => setShowRequestModal(false)}>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Title</label>
              <input
                type="text"
                className="w-full px-4 py-2 rounded-lg border border-slate-300 focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
                placeholder="Brief description of the issue"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Category</label>
              <select className="w-full px-4 py-2 rounded-lg border border-slate-300 focus:ring-2 focus:ring-emerald-600 focus:border-transparent">
                <option>Plumbing</option>
                <option>Electrical</option>
                <option>HVAC</option>
                <option>Appliances</option>
                <option>Other</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Priority</label>
              <select className="w-full px-4 py-2 rounded-lg border border-slate-300 focus:ring-2 focus:ring-emerald-600 focus:border-transparent">
                <option>Low</option>
                <option>Medium</option>
                <option>High</option>
                <option>Urgent</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Description</label>
              <textarea
                className="w-full px-4 py-2 rounded-lg border border-slate-300 focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
                rows={3}
                placeholder="Describe the issue in detail..."
              />
            </div>
            <button className="w-full bg-emerald-600 text-white rounded-lg py-2.5 font-medium hover:bg-emerald-700 transition-colors">
              Submit Request
            </button>
          </div>
        </Modal>
      )}

      {/* Shopping Popover */}
      {showShoppingPopover && (
        <Modal title="Add to Shopping List" onClose={() => setShowShoppingPopover(false)}>
          <div className="space-y-4">
            <div className="flex gap-2">
              <input
                type="text"
                value={shoppingItem}
                onChange={(e) => setShoppingItem(e.target.value)}
                className="flex-1 px-4 py-2 rounded-lg border border-slate-300 focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
                placeholder="Add an item..."
              />
              <button className="bg-emerald-600 text-white rounded-lg px-4 py-2 hover:bg-emerald-700 transition-colors">
                <Plus className="w-5 h-5" />
              </button>
            </div>
            <p className="text-sm text-slate-500">Item will be added to the household shopping list.</p>
          </div>
        </Modal>
      )}

      {/* Broadcast Modal */}
      {showBroadcastModal && (
        <Modal title="Broadcast to Family" onClose={() => setShowBroadcastModal(false)}>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Message</label>
              <textarea
                value={broadcastMessage}
                onChange={(e) => setBroadcastMessage(e.target.value)}
                className="w-full px-4 py-2 rounded-lg border border-slate-300 focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
                rows={3}
                placeholder="Type your message (e.g., 'Dinner is ready!')"
              />
            </div>
            <p className="text-sm text-slate-500">
              This will send a push notification to all family members.
            </p>
            <button className="w-full bg-amber-600 text-white rounded-lg py-2.5 font-medium hover:bg-amber-700 transition-colors flex items-center justify-center gap-2">
              <Send className="w-4 h-4" />
              Send Broadcast
            </button>
          </div>
        </Modal>
      )}
    </>
  );
}

// Modal Component
function Modal({ title, children, onClose }: { title: string; children: React.ReactNode; onClose: () => void }) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/50" onClick={onClose} />
      <div className="relative bg-white rounded-xl shadow-xl w-full max-w-md p-6 z-10">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-lg font-semibold text-slate-900">{title}</h3>
          <button onClick={onClose} className="p-1 hover:bg-slate-100 rounded-lg transition-colors">
            <X className="w-5 h-5 text-slate-500" />
          </button>
        </div>
        {children}
      </div>
    </div>
  );
}

// Family Status Widget
function FamilyStatusWidget({ members }: { members: FamilyMember[] }) {
  return (
    <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-2">
          <Users className="w-5 h-5 text-emerald-600" />
          <h3 className="font-semibold text-slate-900">Family Status</h3>
        </div>
        <Link href="/app/family" className="text-sm text-emerald-600 hover:text-emerald-700 font-medium">
          View All
        </Link>
      </div>

      <div className="flex flex-wrap gap-4">
        {members.map((member) => (
          <div key={member.id} className="flex flex-col items-center">
            <div className="relative">
              <div
                className={`w-12 h-12 rounded-full ${member.avatarColor} flex items-center justify-center text-white font-semibold`}
              >
                {member.initials}
              </div>
              <div
                className={`absolute -bottom-0.5 -right-0.5 w-4 h-4 rounded-full border-2 border-white ${
                  member.isHome ? 'bg-emerald-500' : 'bg-slate-400'
                }`}
              />
            </div>
            <span className="text-sm text-slate-600 mt-1">{member.name}</span>
            <span className="text-xs text-slate-400">{member.isHome ? 'Home' : 'Away'}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

// Activity Feed Widget
function ActivityFeedWidget({ activities }: { activities: ActivityItem[] }) {
  return (
    <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
      <div className="flex items-center justify-between mb-4">
        <h3 className="font-semibold text-slate-900">Recent Activity</h3>
      </div>

      <div className="space-y-4">
        {activities.map((activity) => (
          <div key={activity.id} className="flex items-start gap-3">
            <span className="text-xl">{activity.icon}</span>
            <div className="flex-1">
              <p className="text-slate-800">{activity.description}</p>
              <p className="text-xs text-slate-500">{activity.timestamp}</p>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ============================================================================
// MAIN DASHBOARD PAGE
// ============================================================================

export default function DashboardPage() {
  const { user } = useAuth();
  const userName = user?.firstName || 'there';

  return (
    <div className="space-y-6 pb-8">
      {/* Smart Greeting */}
      <SmartGreeting userName={userName} weather={mockWeather} />

      {/* Home Pulse Status Strip */}
      <HomePulseStrip data={mockHomePulse} />

      {/* Main Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left Column - Main Widgets (2/3 width) */}
        <div className="lg:col-span-2 space-y-6">
          {/* Row 1: Financial + Maintenance */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <FinancialHealthWidget budget={mockBudget} />
            <UrgentMaintenanceWidget items={mockUrgentMaintenance} />
          </div>

          {/* Row 2: Today's Logistics */}
          <TodaysLogisticsWidget items={mockTimeline} />

          {/* Row 3: Quick Actions */}
          <QuickActionDock />
        </div>

        {/* Right Column - Activity Feed (1/3 width) */}
        <div className="space-y-6">
          <FamilyStatusWidget members={mockFamily} />
          <ActivityFeedWidget activities={mockActivity} />
        </div>
      </div>
    </div>
  );
}
