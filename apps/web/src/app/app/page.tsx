'use client';

import { useState, useMemo } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { useAuth } from '@/contexts/auth-context';
import { getDemoImage } from '@/lib/imageUtils';
import {
  Sun,
  Cloud,
  CloudRain,
  Trash2,
  CheckCircle2,
  ChevronRight,
  Wrench,
  Car,
  GraduationCap,
  Briefcase,
  Home,
  Dog,
  MessageCircle,
  Phone,
  Calendar,
  X,
  FileText,
  Sparkles,
  Heart,
  Package,
  Clock,
  Star,
  Mic,
  AlertCircle,
} from 'lucide-react';

// ============================================================================
// TYPES
// ============================================================================

type WeatherCondition = 'sunny' | 'cloudy' | 'rainy';
type ActionPriority = 'decision' | 'respond' | 'fyi';
type FamilyLocationStatus = 'home' | 'work' | 'school' | 'activity' | 'away';

interface WeatherData {
  temp: number;
  condition: WeatherCondition;
}

interface TodayNote {
  id: string;
  icon: typeof Trash2;
  text: string;
  time?: string;
  iconColor: string;
}

interface ActionItem {
  id: string;
  priority: ActionPriority;
  title: string;
  description: string;
  amount?: number;
  managerNote: string;
  primaryAction: string;
  secondaryActions?: string[];
  daysRemaining?: number;
}

interface FamilyMemberStatus {
  id: string;
  name: string;
  avatar?: string;
  isPet?: boolean;
  location: FamilyLocationStatus;
  locationLabel: string;
  until?: string;
  vehicle?: string;
  pickupBy?: string;
}

interface ManagerTask {
  id: string;
  task: string;
  progress: string;
}

type HouseHealthStatus = 'scheduling' | 'ordered' | 'complete';

// ============================================================================
// WEATHER ICONS
// ============================================================================

const WEATHER_ICONS: Record<WeatherCondition, typeof Sun> = {
  sunny: Sun,
  cloudy: Cloud,
  rainy: CloudRain,
};

// ============================================================================
// MOCK DATA
// ============================================================================

const mockWeather: WeatherData = {
  temp: 68,
  condition: 'sunny',
};

const mockTodayNotes: TodayNote[] = [
  { id: 'trash', icon: Trash2, text: 'Trash day tomorrow - bins out?', iconColor: 'text-amber-500' },
  { id: 'package', icon: Package, text: 'Amazon delivery expected 2-5pm', iconColor: 'text-blue-500' },
  { id: 'soccer', icon: Calendar, text: "Emma's soccer practice 4pm", iconColor: 'text-purple-500' },
];

const mockActionItems: ActionItem[] = [
  {
    id: 'action-1',
    priority: 'decision',
    title: 'Authorize Roof Repair',
    description: 'North side shingles need replacement before winter.',
    amount: 1200,
    managerNote: "Got 3 quotes. Ace Roofing is best value - they did great work on the Johnsons' house.",
    primaryAction: 'Approve',
    secondaryActions: ['Review quotes', 'Call me to discuss'],
  },
  {
    id: 'action-2',
    priority: 'respond',
    title: 'Nanny Contract Renewal',
    description: "Maria's contract expires. Review updated terms.",
    daysRemaining: 7,
    managerNote: "I've marked the key changes. Her rate increase is in line with market.",
    primaryAction: 'Review contract',
  },
];

const mockFamilyStatus: FamilyMemberStatus[] = [
  { id: 'bob', name: 'Bob', avatar: getDemoImage('avatar-male', 100, 100, 'bob'), location: 'work', locationLabel: 'At Work', until: 'Home 5:30pm', vehicle: 'Tesla' },
  { id: 'alice', name: 'Alice', avatar: getDemoImage('avatar-female', 100, 100, 'alice'), location: 'home', locationLabel: 'Home', vehicle: 'Highlander' },
  { id: 'emma', name: 'Emma', avatar: getDemoImage('avatar-female', 100, 100, 'emma-kid'), location: 'activity', locationLabel: 'Soccer', until: 'until 4pm', pickupBy: 'Alice pickup' },
  { id: 'jake', name: 'Jake', avatar: getDemoImage('avatar-male', 100, 100, 'jake-kid'), location: 'school', locationLabel: 'School', until: 'until 3:15pm', pickupBy: 'Maria pickup' },
  { id: 'max', name: 'Max', isPet: true, location: 'home', locationLabel: 'Home' },
];

const mockManagerTasks: ManagerTask[] = [
  { id: 'mt-1', task: 'Researching summer camps', progress: 'found 3 options' },
  { id: 'mt-2', task: 'Getting driveway quotes', progress: '2 of 3 received' },
];

const mockHouseHealth = {
  score: 94,
  itemsHandled: 4,
  nextService: 'Tuesday, Jan 7',
  handlingItems: [
    { id: 'hh-1', task: 'HVAC service', status: 'scheduling' as HouseHealthStatus },
    { id: 'hh-2', task: 'Water filter', status: 'ordered' as HouseHealthStatus },
  ],
};

const mockManager = {
  name: 'Sarah Harrison',
  avatar: getDemoImage('avatar-female', 100, 100, 'sarah-manager'),
  isOnline: true,
};

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

function getGreeting(): { greeting: string; note: string } {
  const hour = new Date().getHours();
  const day = new Date().getDay();
  const isWeekend = day === 0 || day === 6;

  let greeting: string;
  let note: string;

  if (hour < 12) {
    greeting = 'Good morning';
    note = isWeekend ? 'Enjoy your weekend.' : "Here's your day.";
  } else if (hour < 17) {
    greeting = 'Good afternoon';
    note = '';
  } else {
    greeting = 'Good evening';
    note = 'Winding down.';
  }

  return { greeting, note };
}

function getLocationIcon(location: FamilyLocationStatus) {
  switch (location) {
    case 'work': return Briefcase;
    case 'school': return GraduationCap;
    case 'activity': return Calendar;
    case 'home': return Home;
    case 'away': return Car;
    default: return Home;
  }
}

// ============================================================================
// COMPONENTS
// ============================================================================

// Decision Action Card (Red - Needs Your Decision)
function DecisionCard({ item, onDismiss }: { item: ActionItem; onDismiss: (id: string) => void }) {
  return (
    <div className="bg-white rounded-2xl border-2 border-red-100 shadow-sm overflow-hidden">
      {/* Header */}
      <div className="bg-red-50 px-4 py-2 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <div className="w-2 h-2 bg-red-500 rounded-full" />
          <span className="text-sm font-medium text-red-700">Needs Your Decision</span>
        </div>
        <button
          onClick={() => onDismiss(item.id)}
          className="p-1 hover:bg-red-100 rounded-lg transition-colors"
        >
          <X className="w-4 h-4 text-red-400" />
        </button>
      </div>

      {/* Content */}
      <div className="p-4">
        <div className="flex items-start justify-between mb-2">
          <h3 className="font-semibold text-slate-900">{item.title}</h3>
          {item.amount && (
            <span className="text-lg font-bold text-slate-900">${item.amount.toLocaleString()}</span>
          )}
        </div>

        {/* Manager Note */}
        <div className="bg-slate-50 rounded-lg p-3 mb-4">
          <div className="flex items-start gap-2">
            <div className="w-6 h-6 rounded-full overflow-hidden flex-shrink-0 mt-0.5">
              <Image src={mockManager.avatar} alt="" width={24} height={24} className="object-cover" />
            </div>
            <div>
              <span className="text-xs text-slate-500">Sarah:</span>
              <p className="text-sm text-slate-700">{item.managerNote}</p>
            </div>
          </div>
        </div>

        {/* Actions */}
        <div className="flex flex-wrap gap-2">
          <button className="flex-1 min-w-[120px] px-4 py-2.5 bg-emerald-600 text-white font-medium rounded-lg hover:bg-emerald-700 transition-colors">
            {item.primaryAction}
          </button>
          {item.secondaryActions?.map((action, i) => (
            <button
              key={i}
              className="px-4 py-2.5 bg-slate-100 text-slate-700 font-medium rounded-lg hover:bg-slate-200 transition-colors text-sm"
            >
              {action}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}

// Respond Card (Yellow - Respond When You Can)
function RespondCard({ item, onDismiss }: { item: ActionItem; onDismiss: (id: string) => void }) {
  return (
    <div className="bg-white rounded-2xl border border-amber-200 shadow-sm overflow-hidden">
      {/* Header */}
      <div className="bg-amber-50 px-4 py-2 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <div className="w-2 h-2 bg-amber-500 rounded-full" />
          <span className="text-sm font-medium text-amber-700">Respond When You Can</span>
          {item.daysRemaining && (
            <span className="text-xs text-amber-600 bg-amber-100 px-2 py-0.5 rounded-full">
              {item.daysRemaining} days
            </span>
          )}
        </div>
        <button
          onClick={() => onDismiss(item.id)}
          className="p-1 hover:bg-amber-100 rounded-lg transition-colors"
        >
          <X className="w-4 h-4 text-amber-400" />
        </button>
      </div>

      {/* Content */}
      <div className="p-4">
        <h3 className="font-semibold text-slate-900 mb-1">{item.title}</h3>
        <p className="text-sm text-slate-600 mb-3">{item.description}</p>

        {/* Manager Note */}
        <div className="flex items-start gap-2 mb-4">
          <div className="w-5 h-5 rounded-full overflow-hidden flex-shrink-0 mt-0.5">
            <Image src={mockManager.avatar} alt="" width={20} height={20} className="object-cover" />
          </div>
          <p className="text-sm text-slate-600 italic">"{item.managerNote}"</p>
        </div>

        {/* Action */}
        <button className="w-full px-4 py-2.5 bg-amber-100 text-amber-800 font-medium rounded-lg hover:bg-amber-200 transition-colors">
          {item.primaryAction}
        </button>
      </div>
    </div>
  );
}

// All Caught Up Card
function AllCaughtUpCard({
  itemsHandled,
  healthScore,
  nextService,
}: {
  itemsHandled: number;
  healthScore: number;
  nextService: string;
}) {
  return (
    <div className="bg-gradient-to-br from-emerald-50 via-teal-50 to-cyan-50 rounded-2xl border border-emerald-100 p-8 text-center">
      <div className="w-16 h-16 bg-white rounded-full flex items-center justify-center mx-auto mb-4 shadow-sm">
        <Sparkles className="w-8 h-8 text-emerald-500" />
      </div>
      <h2 className="text-xl font-bold text-slate-900 mb-2">All caught up!</h2>
      <p className="text-slate-600 mb-4">
        Sarah is handling {itemsHandled} items in the background.<br />
        Your home is {healthScore}% healthy. Next service: {nextService}.
      </p>
      <p className="text-2xl">Enjoy your day!</p>
    </div>
  );
}

// Manager Status Card (More Prominent)
function ManagerStatusCard({
  manager,
  tasks,
}: {
  manager: typeof mockManager;
  tasks: ManagerTask[];
}) {
  return (
    <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
      {/* Header */}
      <div className="p-4 border-b border-slate-100">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="relative">
              <div className="w-12 h-12 rounded-full overflow-hidden ring-2 ring-emerald-400 ring-offset-2">
                <Image src={manager.avatar} alt="" width={48} height={48} className="object-cover" />
              </div>
              {manager.isOnline && (
                <div className="absolute bottom-0 right-0 w-3.5 h-3.5 bg-emerald-500 rounded-full border-2 border-white" />
              )}
            </div>
            <div>
              <h3 className="font-semibold text-slate-900">{manager.name}</h3>
              <p className="text-sm text-slate-500">Your Home Manager</p>
            </div>
          </div>
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 bg-emerald-100 text-emerald-700 rounded-full text-sm font-medium">
            <span className="w-2 h-2 bg-emerald-500 rounded-full" />
            Available
          </span>
        </div>
      </div>

      {/* Currently Working On */}
      {tasks.length > 0 && (
        <div className="p-4 bg-slate-50">
          <p className="text-xs font-medium text-slate-500 uppercase tracking-wide mb-2">Currently working on:</p>
          <div className="space-y-2">
            {tasks.map((task) => (
              <div key={task.id} className="flex items-center gap-2 text-sm">
                <Clock className="w-4 h-4 text-slate-400" />
                <span className="text-slate-700">{task.task}</span>
                <span className="text-slate-500">({task.progress})</span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Message Button */}
      <div className="p-4">
        <Link
          href="/app/messages"
          className="flex items-center justify-center gap-2 w-full px-4 py-3 bg-emerald-600 text-white font-medium rounded-xl hover:bg-emerald-700 transition-colors"
        >
          <MessageCircle className="w-5 h-5" />
          Message Sarah
        </Link>
      </div>
    </div>
  );
}

// Family Logistics Row
function FamilyLogisticsCard({ members }: { members: FamilyMemberStatus[] }) {
  return (
    <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
      <div className="p-4 border-b border-slate-100">
        <h3 className="font-semibold text-slate-900">Today's Logistics</h3>
      </div>
      <div className="divide-y divide-slate-100">
        {members.map((member) => {
          const LocationIcon = getLocationIcon(member.location);
          return (
            <div key={member.id} className="flex items-center gap-3 px-4 py-3">
              {/* Avatar */}
              <div className="w-10 h-10 rounded-full bg-slate-100 flex items-center justify-center overflow-hidden">
                {member.isPet ? (
                  <Dog className="w-5 h-5 text-amber-600" />
                ) : member.avatar ? (
                  <Image src={member.avatar} alt="" width={40} height={40} className="object-cover" />
                ) : (
                  <span className="text-sm font-medium text-slate-600">{member.name[0]}</span>
                )}
              </div>

              {/* Name & Status */}
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2">
                  <span className="font-medium text-slate-900">{member.name}</span>
                  <div className="flex items-center gap-1 text-sm text-slate-500">
                    <LocationIcon className="w-3.5 h-3.5" />
                    <span>{member.locationLabel}</span>
                    {member.until && <span className="text-slate-400">→ {member.until}</span>}
                  </div>
                </div>
                {member.pickupBy && (
                  <p className="text-xs text-slate-500">{member.pickupBy}</p>
                )}
              </div>

              {/* Vehicle */}
              {member.vehicle && (
                <div className="flex items-center gap-1.5 text-sm text-slate-500">
                  <Car className="w-4 h-4" />
                  <span>{member.vehicle}</span>
                </div>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}

// House Health Card (Reframed - No Anxiety)
function HouseHealthCard({
  health,
}: {
  health: typeof mockHouseHealth;
}) {
  return (
    <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
      <div className="p-4 border-b border-slate-100 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <Heart className="w-5 h-5 text-emerald-500" />
          <h3 className="font-semibold text-slate-900">House Health</h3>
        </div>
        <span className="text-lg font-bold text-emerald-600">{health.score}% Healthy</span>
      </div>

      <div className="p-4">
        <p className="text-sm text-slate-600 mb-3">
          <span className="font-medium text-slate-900">Sarah is handling:</span>
        </p>
        <div className="space-y-2 mb-4">
          {health.handlingItems.map((item) => (
            <div key={item.id} className="flex items-center gap-2 text-sm">
              {item.status === 'scheduling' && <Clock className="w-4 h-4 text-amber-500" />}
              {item.status === 'ordered' && <Package className="w-4 h-4 text-blue-500" />}
              {item.status === 'complete' && <CheckCircle2 className="w-4 h-4 text-emerald-500" />}
              <span className="text-slate-700">{item.task}</span>
              <span className="text-slate-400">({item.status})</span>
            </div>
          ))}
        </div>

        <div className="flex items-center gap-2 p-3 bg-emerald-50 rounded-lg">
          <Wrench className="w-4 h-4 text-emerald-600" />
          <span className="text-sm text-emerald-700">
            Next handyman visit: <span className="font-medium">{health.nextService}</span>
          </span>
        </div>
      </div>

      <div className="p-4 border-t border-slate-100">
        <Link
          href="/app/maintenance"
          className="text-sm text-emerald-600 hover:text-emerald-700 font-medium flex items-center gap-1"
        >
          View full report
          <ChevronRight className="w-4 h-4" />
        </Link>
      </div>
    </div>
  );
}

// Quick Actions (Simplified)
function QuickActionsCard({ onOpenRequest }: { onOpenRequest: () => void }) {
  return (
    <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-4">
      <h3 className="font-semibold text-slate-900 mb-4">Quick Actions</h3>

      {/* Primary: I need help with something */}
      <button
        onClick={onOpenRequest}
        className="w-full flex items-center gap-3 px-4 py-4 bg-emerald-600 text-white rounded-xl hover:bg-emerald-700 transition-colors mb-4 shadow-lg shadow-emerald-600/20"
      >
        <AlertCircle className="w-5 h-5" />
        <span className="flex-1 text-left font-medium">I need help with something...</span>
        <Mic className="w-5 h-5 text-emerald-200" />
      </button>

      {/* Secondary Actions */}
      <div className="grid grid-cols-3 gap-2">
        <Link
          href="/app/messages"
          className="flex flex-col items-center gap-1.5 p-3 bg-slate-50 rounded-xl hover:bg-slate-100 transition-colors"
        >
          <MessageCircle className="w-5 h-5 text-slate-600" />
          <span className="text-xs text-slate-600 font-medium">Message</span>
        </Link>
        <Link
          href="/app/billing"
          className="flex flex-col items-center gap-1.5 p-3 bg-slate-50 rounded-xl hover:bg-slate-100 transition-colors"
        >
          <FileText className="w-5 h-5 text-slate-600" />
          <span className="text-xs text-slate-600 font-medium">Statement</span>
        </Link>
        <Link
          href="/app/calendar"
          className="flex flex-col items-center gap-1.5 p-3 bg-slate-50 rounded-xl hover:bg-slate-100 transition-colors"
        >
          <Calendar className="w-5 h-5 text-slate-600" />
          <span className="text-xs text-slate-600 font-medium">Calendar</span>
        </Link>
      </div>
    </div>
  );
}

// Weather & Today Notes
function WeatherContextCard({
  weather,
  notes,
}: {
  weather: WeatherData;
  notes: TodayNote[];
}) {
  const WeatherIcon = WEATHER_ICONS[weather.condition];
  const today = new Date().toLocaleDateString('en-US', { weekday: 'long', month: 'short', day: 'numeric' });

  return (
    <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
      {/* Weather Header */}
      <div className="p-4 flex items-center justify-between border-b border-slate-100">
        <span className="text-sm text-slate-600">{today}</span>
        <div className="flex items-center gap-2">
          <span className="text-lg font-bold text-slate-900">{weather.temp}°F</span>
          <WeatherIcon className="w-6 h-6 text-amber-500" />
        </div>
      </div>

      {/* Today's Notes */}
      <div className="p-4 space-y-3">
        {notes.map((note) => {
          const Icon = note.icon;
          return (
            <div key={note.id} className="flex items-center gap-3">
              <Icon className={`w-5 h-5 ${note.iconColor}`} />
              <span className="text-sm text-slate-700">{note.text}</span>
              {note.time && (
                <span className="text-xs text-slate-400 ml-auto">{note.time}</span>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}

// Request Modal (Enhanced)
function RequestModal({ isOpen, onClose }: { isOpen: boolean; onClose: () => void }) {
  if (!isOpen) return null;

  const quickRequests = [
    { icon: Wrench, label: 'Something needs fixing', color: 'bg-amber-100 text-amber-600' },
    { icon: Calendar, label: 'Schedule something', color: 'bg-blue-100 text-blue-600' },
    { icon: Package, label: 'Buy something', color: 'bg-purple-100 text-purple-600' },
    { icon: Star, label: 'Question for Sarah', color: 'bg-emerald-100 text-emerald-600' },
  ];

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl shadow-xl max-w-md w-full">
        <div className="p-6 border-b border-slate-200">
          <div className="flex items-center justify-between">
            <h2 className="text-xl font-bold text-slate-900">How can Sarah help?</h2>
            <button
              onClick={onClose}
              className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
            >
              <X className="w-5 h-5 text-slate-500" />
            </button>
          </div>
        </div>

        <div className="p-4 grid grid-cols-2 gap-3">
          {quickRequests.map((request) => {
            const Icon = request.icon;
            return (
              <button
                key={request.label}
                onClick={onClose}
                className="flex flex-col items-center gap-2 p-4 rounded-xl hover:bg-slate-50 transition-colors text-center border border-slate-200"
              >
                <div className={`p-3 rounded-xl ${request.color}`}>
                  <Icon className="w-6 h-6" />
                </div>
                <span className="text-sm font-medium text-slate-700">{request.label}</span>
              </button>
            );
          })}
        </div>

        <div className="p-4 border-t border-slate-200">
          <div className="relative">
            <input
              type="text"
              placeholder="Or just tell me what you need..."
              className="w-full px-4 py-3 pr-12 border border-slate-300 rounded-xl focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
            />
            <button className="absolute right-3 top-1/2 -translate-y-1/2 p-1.5 bg-emerald-600 rounded-lg text-white hover:bg-emerald-700">
              <Mic className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

// Manager Contact Footer
function ManagerContactFooter({ manager }: { manager: typeof mockManager }) {
  return (
    <div className="bg-gradient-to-br from-slate-900 to-slate-800 rounded-2xl p-6 text-white">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div className="flex items-center gap-4">
          <div className="w-14 h-14 rounded-full overflow-hidden ring-2 ring-emerald-400 ring-offset-2 ring-offset-slate-900">
            <Image src={manager.avatar} alt="" width={56} height={56} className="object-cover" />
          </div>
          <div>
            <h3 className="text-lg font-semibold">{manager.name}</h3>
            <p className="text-slate-400">Your Home Manager</p>
          </div>
        </div>

        <div className="flex gap-3">
          <a
            href="tel:+13105550123"
            className="flex items-center gap-2 px-4 py-2.5 bg-white/10 hover:bg-white/20 rounded-lg font-medium transition-colors"
          >
            <Phone className="w-4 h-4" />
            Call
          </a>
          <Link
            href="/app/messages"
            className="flex items-center gap-2 px-4 py-2.5 bg-emerald-600 hover:bg-emerald-700 rounded-lg font-medium transition-colors"
          >
            <MessageCircle className="w-4 h-4" />
            Chat
          </Link>
        </div>
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
  const [actionItems, setActionItems] = useState(mockActionItems);
  const [showRequestModal, setShowRequestModal] = useState(false);

  const { greeting, note } = useMemo(() => getGreeting(), []);

  const dismissAction = (id: string) => {
    setActionItems(prev => prev.filter(item => item.id !== id));
  };

  const decisionItems = actionItems.filter(item => item.priority === 'decision');
  const respondItems = actionItems.filter(item => item.priority === 'respond');
  const hasActionItems = actionItems.length > 0;

  return (
    <div className="pb-32 lg:pb-8 max-w-6xl mx-auto">
      {/* ================================================================== */}
      {/* GREETING & WEATHER */}
      {/* ================================================================== */}
      <div className="mb-6">
        <h1 className="text-2xl lg:text-3xl font-bold text-slate-900 tracking-tight">
          {greeting}, {userName}.
          {note && <span className="text-slate-500 font-normal ml-2">{note}</span>}
        </h1>
      </div>

      {/* ================================================================== */}
      {/* WEATHER & TODAY'S CONTEXT */}
      {/* ================================================================== */}
      <div className="mb-6">
        <WeatherContextCard weather={mockWeather} notes={mockTodayNotes} />
      </div>

      {/* ================================================================== */}
      {/* ACTION ITEMS OR ALL CAUGHT UP */}
      {/* ================================================================== */}
      <div className="mb-6">
        {hasActionItems ? (
          <div className="space-y-4">
            {/* Decisions First */}
            {decisionItems.map(item => (
              <DecisionCard key={item.id} item={item} onDismiss={dismissAction} />
            ))}

            {/* Respond Items */}
            {respondItems.map(item => (
              <RespondCard key={item.id} item={item} onDismiss={dismissAction} />
            ))}
          </div>
        ) : (
          <AllCaughtUpCard
            itemsHandled={mockHouseHealth.itemsHandled}
            healthScore={mockHouseHealth.score}
            nextService={mockHouseHealth.nextService}
          />
        )}
      </div>

      {/* ================================================================== */}
      {/* MANAGER STATUS (Prominent) */}
      {/* ================================================================== */}
      <div className="mb-6">
        <ManagerStatusCard manager={mockManager} tasks={mockManagerTasks} />
      </div>

      {/* ================================================================== */}
      {/* TWO COLUMN LAYOUT */}
      {/* ================================================================== */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        {/* Family Logistics */}
        <FamilyLogisticsCard members={mockFamilyStatus} />

        {/* House Health */}
        <HouseHealthCard health={mockHouseHealth} />
      </div>

      {/* ================================================================== */}
      {/* QUICK ACTIONS */}
      {/* ================================================================== */}
      <div className="mb-6">
        <QuickActionsCard onOpenRequest={() => setShowRequestModal(true)} />
      </div>

      {/* ================================================================== */}
      {/* MANAGER CONTACT FOOTER */}
      {/* ================================================================== */}
      <ManagerContactFooter manager={mockManager} />

      {/* Request Modal */}
      <RequestModal isOpen={showRequestModal} onClose={() => setShowRequestModal(false)} />
    </div>
  );
}
