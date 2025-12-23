'use client';

import { useState, useMemo } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { useAuth } from '@/contexts/auth-context';
import { images, getAvatarUrl } from '@/lib/images';
import { Card, CardHeader, CardContent, Badge, Button, Avatar } from '@/components/ui';
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
  Bell,
  Plus,
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
  { id: 'bob', name: 'Bob', avatar: images.avatars.bob, location: 'work', locationLabel: 'At Work', until: 'Home 5:30pm', vehicle: 'Tesla' },
  { id: 'alice', name: 'Alice', avatar: images.avatars.alice, location: 'home', locationLabel: 'Home', vehicle: 'Highlander' },
  { id: 'emma', name: 'Emma', location: 'activity', locationLabel: 'Soccer', until: 'until 4pm', pickupBy: 'Alice pickup' },
  { id: 'jake', name: 'Jake', location: 'school', locationLabel: 'School', until: 'until 3:15pm', pickupBy: 'Maria pickup' },
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
  avatar: images.avatars.sarah,
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
// COMPONENTS - PREMIUM REDESIGN
// ============================================================================

// Hero Greeting Section
function HeroGreeting({ userName, weather }: { userName: string; weather: WeatherData }) {
  const { greeting, note } = useMemo(() => getGreeting(), []);
  const WeatherIcon = WEATHER_ICONS[weather.condition];
  const today = new Date().toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric' });

  return (
    <div className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-haven-600 via-haven-500 to-emerald-500 p-8 text-white mb-8">
      {/* Background Pattern */}
      <div className="absolute inset-0 opacity-10">
        <div className="absolute top-0 right-0 w-96 h-96 bg-white rounded-full -translate-y-1/2 translate-x-1/2" />
        <div className="absolute bottom-0 left-0 w-64 h-64 bg-white rounded-full translate-y-1/2 -translate-x-1/2" />
      </div>

      <div className="relative">
        <div className="flex items-start justify-between">
          <div>
            <p className="text-haven-100 text-sm font-medium mb-1">{today}</p>
            <h1 className="text-3xl lg:text-4xl font-bold tracking-tight mb-2">
              {greeting}, {userName}
            </h1>
            {note && <p className="text-haven-100 text-lg">{note}</p>}
          </div>
          <div className="flex items-center gap-3 bg-white/20 backdrop-blur-sm rounded-2xl px-4 py-3">
            <WeatherIcon className="w-8 h-8" />
            <span className="text-2xl font-bold">{weather.temp}°</span>
          </div>
        </div>

        {/* Quick Stats */}
        <div className="flex gap-6 mt-8">
          <div className="bg-white/10 backdrop-blur-sm rounded-xl px-4 py-3">
            <p className="text-haven-100 text-xs font-medium">Home Health</p>
            <p className="text-2xl font-bold">{mockHouseHealth.score}%</p>
          </div>
          <div className="bg-white/10 backdrop-blur-sm rounded-xl px-4 py-3">
            <p className="text-haven-100 text-xs font-medium">Items Handled</p>
            <p className="text-2xl font-bold">{mockHouseHealth.itemsHandled}</p>
          </div>
          <div className="bg-white/10 backdrop-blur-sm rounded-xl px-4 py-3">
            <p className="text-haven-100 text-xs font-medium">Next Service</p>
            <p className="text-lg font-semibold">Jan 7</p>
          </div>
        </div>
      </div>
    </div>
  );
}

// Today's Notes Card
function TodayNotesCard({ notes }: { notes: TodayNote[] }) {
  return (
    <Card hover>
      <CardHeader title="Today's Notes" action={<Badge variant="info">{notes.length}</Badge>} />
      <div className="mt-4 space-y-3">
        {notes.map((note) => {
          const Icon = note.icon;
          return (
            <div key={note.id} className="flex items-center gap-3 p-3 rounded-xl bg-warm-50 hover:bg-warm-100 transition-colors">
              <div className={`p-2 rounded-lg bg-white ${note.iconColor}`}>
                <Icon className="w-4 h-4" />
              </div>
              <span className="flex-1 text-sm text-warm-700">{note.text}</span>
              {note.time && (
                <span className="text-xs text-warm-400">{note.time}</span>
              )}
            </div>
          );
        })}
      </div>
    </Card>
  );
}

// Decision Action Card (Premium Red)
function DecisionCard({ item, onDismiss }: { item: ActionItem; onDismiss: (id: string) => void }) {
  return (
    <div className="bg-white rounded-2xl border-2 border-red-100 shadow-lg shadow-red-500/5 overflow-hidden">
      {/* Header */}
      <div className="bg-gradient-to-r from-red-50 to-rose-50 px-5 py-3 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <span className="flex h-2 w-2">
            <span className="animate-ping absolute inline-flex h-2 w-2 rounded-full bg-red-400 opacity-75" />
            <span className="relative inline-flex rounded-full h-2 w-2 bg-red-500" />
          </span>
          <span className="text-sm font-semibold text-red-700">Needs Your Decision</span>
        </div>
        <button
          onClick={() => onDismiss(item.id)}
          className="p-1.5 hover:bg-red-100 rounded-lg transition-colors"
        >
          <X className="w-4 h-4 text-red-400" />
        </button>
      </div>

      {/* Content */}
      <div className="p-5">
        <div className="flex items-start justify-between mb-3">
          <h3 className="text-lg font-bold text-warm-900">{item.title}</h3>
          {item.amount && (
            <span className="text-xl font-bold text-warm-900">${item.amount.toLocaleString()}</span>
          )}
        </div>
        <p className="text-warm-600 text-sm mb-4">{item.description}</p>

        {/* Manager Note */}
        <div className="bg-warm-50 rounded-xl p-4 mb-5">
          <div className="flex items-start gap-3">
            <Avatar name={mockManager.name} src={mockManager.avatar} size="sm" />
            <div>
              <span className="text-xs font-medium text-warm-500">Sarah says:</span>
              <p className="text-sm text-warm-700 mt-0.5">{item.managerNote}</p>
            </div>
          </div>
        </div>

        {/* Actions */}
        <div className="flex flex-wrap gap-2">
          <Button className="flex-1 min-w-[120px]">{item.primaryAction}</Button>
          {item.secondaryActions?.map((action, i) => (
            <Button key={i} variant="secondary" size="sm">
              {action}
            </Button>
          ))}
        </div>
      </div>
    </div>
  );
}

// Respond Card (Premium Amber)
function RespondCard({ item, onDismiss }: { item: ActionItem; onDismiss: (id: string) => void }) {
  return (
    <Card className="border-amber-200">
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-2">
          <div className="w-2 h-2 bg-amber-500 rounded-full" />
          <span className="text-sm font-semibold text-amber-700">Respond When You Can</span>
          {item.daysRemaining && (
            <Badge variant="warning">{item.daysRemaining} days left</Badge>
          )}
        </div>
        <button
          onClick={() => onDismiss(item.id)}
          className="p-1.5 hover:bg-amber-50 rounded-lg transition-colors"
        >
          <X className="w-4 h-4 text-amber-400" />
        </button>
      </div>

      <h3 className="text-lg font-bold text-warm-900 mb-1">{item.title}</h3>
      <p className="text-sm text-warm-600 mb-4">{item.description}</p>

      {/* Manager Note */}
      <div className="flex items-start gap-3 p-3 bg-amber-50 rounded-xl mb-4">
        <Avatar name={mockManager.name} src={mockManager.avatar} size="sm" />
        <p className="text-sm text-amber-800 italic">"{item.managerNote}"</p>
      </div>

      <Button variant="outline" className="w-full border-amber-200 text-amber-700 hover:bg-amber-50">
        {item.primaryAction}
      </Button>
    </Card>
  );
}

// All Caught Up Card (Premium Success)
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
    <div className="relative overflow-hidden bg-gradient-to-br from-emerald-50 via-teal-50 to-cyan-50 rounded-2xl border border-emerald-100 p-8 text-center">
      {/* Decorative Elements */}
      <div className="absolute top-4 left-4 w-16 h-16 bg-emerald-200/30 rounded-full blur-2xl" />
      <div className="absolute bottom-4 right-4 w-20 h-20 bg-teal-200/30 rounded-full blur-2xl" />

      <div className="relative">
        <div className="w-20 h-20 bg-white rounded-2xl flex items-center justify-center mx-auto mb-5 shadow-lg shadow-emerald-500/10">
          <Sparkles className="w-10 h-10 text-emerald-500" />
        </div>
        <h2 className="text-2xl font-bold text-warm-900 mb-2">All caught up!</h2>
        <p className="text-warm-600 mb-1">
          Sarah is handling <span className="font-semibold text-warm-900">{itemsHandled} items</span> in the background.
        </p>
        <p className="text-warm-600 mb-6">
          Your home is <span className="font-semibold text-emerald-600">{healthScore}% healthy</span>. Next service: {nextService}.
        </p>
        <p className="text-3xl">☀️ Enjoy your day!</p>
      </div>
    </div>
  );
}

// Manager Status Card (Premium)
function ManagerStatusCard({
  manager,
  tasks,
}: {
  manager: typeof mockManager;
  tasks: ManagerTask[];
}) {
  return (
    <Card className="overflow-hidden">
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-4">
          <div className="relative">
            <Avatar name={manager.name} src={manager.avatar} size="lg" status="online" />
          </div>
          <div>
            <h3 className="font-bold text-warm-900">{manager.name}</h3>
            <p className="text-sm text-warm-500">Your Home Manager</p>
          </div>
        </div>
        <Badge variant="success" icon={<span className="w-1.5 h-1.5 rounded-full bg-emerald-500" />}>
          Available
        </Badge>
      </div>

      {/* Currently Working On */}
      {tasks.length > 0 && (
        <div className="bg-warm-50 rounded-xl p-4 mb-4">
          <p className="text-xs font-semibold text-warm-500 uppercase tracking-wider mb-3">Currently working on</p>
          <div className="space-y-2">
            {tasks.map((task) => (
              <div key={task.id} className="flex items-center gap-2 text-sm">
                <Clock className="w-4 h-4 text-haven-500" />
                <span className="text-warm-700">{task.task}</span>
                <span className="text-warm-400">• {task.progress}</span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Message Button */}
      <Link href="/app/messages">
        <Button className="w-full" leftIcon={<MessageCircle className="w-5 h-5" />}>
          Message Sarah
        </Button>
      </Link>
    </Card>
  );
}

// Family Logistics Card (Premium)
function FamilyLogisticsCard({ members }: { members: FamilyMemberStatus[] }) {
  return (
    <Card>
      <CardHeader
        title="Today's Logistics"
        subtitle={`${members.filter(m => m.location === 'home').length} at home`}
      />
      <div className="mt-4 space-y-3">
        {members.map((member) => {
          const LocationIcon = getLocationIcon(member.location);
          const locationColors = {
            home: 'bg-emerald-100 text-emerald-600',
            work: 'bg-blue-100 text-blue-600',
            school: 'bg-purple-100 text-purple-600',
            activity: 'bg-amber-100 text-amber-600',
            away: 'bg-warm-100 text-warm-600',
          };

          return (
            <div key={member.id} className="flex items-center gap-3 p-3 rounded-xl hover:bg-warm-50 transition-colors">
              {/* Avatar */}
              <div className="w-10 h-10 rounded-full bg-warm-100 flex items-center justify-center overflow-hidden">
                {member.isPet ? (
                  <Dog className="w-5 h-5 text-amber-600" />
                ) : member.avatar ? (
                  <Image src={member.avatar} alt="" width={40} height={40} className="object-cover" />
                ) : (
                  <span className="text-sm font-semibold text-warm-600">{member.name[0]}</span>
                )}
              </div>

              {/* Name & Status */}
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2">
                  <span className="font-semibold text-warm-900">{member.name}</span>
                  <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium ${locationColors[member.location]}`}>
                    <LocationIcon className="w-3 h-3" />
                    {member.locationLabel}
                  </span>
                </div>
                <div className="flex items-center gap-2 text-sm text-warm-500">
                  {member.until && <span>{member.until}</span>}
                  {member.pickupBy && <span>• {member.pickupBy}</span>}
                </div>
              </div>

              {/* Vehicle */}
              {member.vehicle && (
                <div className="flex items-center gap-1.5 text-sm text-warm-500 bg-warm-100 px-2 py-1 rounded-lg">
                  <Car className="w-4 h-4" />
                  <span>{member.vehicle}</span>
                </div>
              )}
            </div>
          );
        })}
      </div>
    </Card>
  );
}

// House Health Card (Premium)
function HouseHealthCard({
  health,
}: {
  health: typeof mockHouseHealth;
}) {
  return (
    <Card>
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-2">
          <div className="p-2 bg-haven-100 rounded-lg">
            <Heart className="w-5 h-5 text-haven-600" />
          </div>
          <h3 className="font-bold text-warm-900">House Health</h3>
        </div>
        <div className="text-right">
          <span className="text-2xl font-bold text-haven-600">{health.score}%</span>
          <p className="text-xs text-warm-500">Healthy</p>
        </div>
      </div>

      {/* Progress Bar */}
      <div className="h-2 bg-warm-100 rounded-full mb-4 overflow-hidden">
        <div
          className="h-full bg-gradient-to-r from-haven-500 to-emerald-500 rounded-full transition-all duration-500"
          style={{ width: `${health.score}%` }}
        />
      </div>

      <p className="text-sm text-warm-600 mb-3">
        <span className="font-semibold text-warm-900">Sarah is handling:</span>
      </p>
      <div className="space-y-2 mb-4">
        {health.handlingItems.map((item) => (
          <div key={item.id} className="flex items-center gap-3 p-2 bg-warm-50 rounded-lg">
            {item.status === 'scheduling' && <Clock className="w-4 h-4 text-amber-500" />}
            {item.status === 'ordered' && <Package className="w-4 h-4 text-blue-500" />}
            {item.status === 'complete' && <CheckCircle2 className="w-4 h-4 text-emerald-500" />}
            <span className="text-sm text-warm-700">{item.task}</span>
            <Badge variant={item.status === 'scheduling' ? 'warning' : item.status === 'ordered' ? 'info' : 'success'} size="sm">
              {item.status}
            </Badge>
          </div>
        ))}
      </div>

      <div className="flex items-center gap-2 p-3 bg-haven-50 rounded-xl">
        <Wrench className="w-4 h-4 text-haven-600" />
        <span className="text-sm text-haven-700">
          Next handyman visit: <span className="font-semibold">{health.nextService}</span>
        </span>
      </div>

      <Link
        href="/app/maintenance"
        className="mt-4 text-sm text-haven-600 hover:text-haven-700 font-medium flex items-center gap-1"
      >
        View full report
        <ChevronRight className="w-4 h-4" />
      </Link>
    </Card>
  );
}

// Quick Actions Card (Premium)
function QuickActionsCard({ onOpenRequest }: { onOpenRequest: () => void }) {
  return (
    <Card>
      <CardHeader title="Quick Actions" />

      {/* Primary Action */}
      <button
        onClick={onOpenRequest}
        className="w-full mt-4 flex items-center gap-4 p-4 bg-gradient-to-r from-haven-600 to-emerald-600 text-white rounded-xl hover:from-haven-700 hover:to-emerald-700 transition-all shadow-lg shadow-haven-500/20 group"
      >
        <div className="p-2 bg-white/20 rounded-lg group-hover:bg-white/30 transition-colors">
          <Plus className="w-5 h-5" />
        </div>
        <span className="flex-1 text-left font-semibold">I need help with something...</span>
        <Mic className="w-5 h-5 text-white/60" />
      </button>

      {/* Secondary Actions */}
      <div className="grid grid-cols-3 gap-3 mt-4">
        <Link
          href="/app/messages"
          className="flex flex-col items-center gap-2 p-4 bg-warm-50 rounded-xl hover:bg-warm-100 transition-colors group"
        >
          <div className="p-2 bg-white rounded-lg shadow-sm group-hover:shadow transition-shadow">
            <MessageCircle className="w-5 h-5 text-warm-600" />
          </div>
          <span className="text-xs font-medium text-warm-600">Messages</span>
        </Link>
        <Link
          href="/app/billing"
          className="flex flex-col items-center gap-2 p-4 bg-warm-50 rounded-xl hover:bg-warm-100 transition-colors group"
        >
          <div className="p-2 bg-white rounded-lg shadow-sm group-hover:shadow transition-shadow">
            <FileText className="w-5 h-5 text-warm-600" />
          </div>
          <span className="text-xs font-medium text-warm-600">Statement</span>
        </Link>
        <Link
          href="/app/calendar"
          className="flex flex-col items-center gap-2 p-4 bg-warm-50 rounded-xl hover:bg-warm-100 transition-colors group"
        >
          <div className="p-2 bg-white rounded-lg shadow-sm group-hover:shadow transition-shadow">
            <Calendar className="w-5 h-5 text-warm-600" />
          </div>
          <span className="text-xs font-medium text-warm-600">Calendar</span>
        </Link>
      </div>
    </Card>
  );
}

// Request Modal (Premium)
function RequestModal({ isOpen, onClose }: { isOpen: boolean; onClose: () => void }) {
  if (!isOpen) return null;

  const quickRequests = [
    { icon: Wrench, label: 'Something needs fixing', color: 'bg-amber-100 text-amber-600', hoverBg: 'hover:bg-amber-50' },
    { icon: Calendar, label: 'Schedule something', color: 'bg-blue-100 text-blue-600', hoverBg: 'hover:bg-blue-50' },
    { icon: Package, label: 'Buy something', color: 'bg-purple-100 text-purple-600', hoverBg: 'hover:bg-purple-50' },
    { icon: Star, label: 'Question for Sarah', color: 'bg-emerald-100 text-emerald-600', hoverBg: 'hover:bg-emerald-50' },
  ];

  return (
    <div className="fixed inset-0 bg-warm-900/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl shadow-2xl max-w-md w-full animate-in fade-in zoom-in-95 duration-200">
        <div className="p-6 border-b border-warm-100">
          <div className="flex items-center justify-between">
            <h2 className="text-xl font-bold text-warm-900">How can Sarah help?</h2>
            <button
              onClick={onClose}
              className="p-2 hover:bg-warm-100 rounded-xl transition-colors"
            >
              <X className="w-5 h-5 text-warm-500" />
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
                className={`flex flex-col items-center gap-3 p-5 rounded-xl transition-all border border-warm-100 ${request.hoverBg} hover:border-warm-200 hover:shadow-sm`}
              >
                <div className={`p-3 rounded-xl ${request.color}`}>
                  <Icon className="w-6 h-6" />
                </div>
                <span className="text-sm font-medium text-warm-700 text-center">{request.label}</span>
              </button>
            );
          })}
        </div>

        <div className="p-4 border-t border-warm-100">
          <div className="relative">
            <input
              type="text"
              placeholder="Or just tell me what you need..."
              className="w-full px-4 py-3 pr-12 border border-warm-200 rounded-xl focus:ring-2 focus:ring-haven-500/20 focus:border-haven-500 transition-all"
            />
            <button className="absolute right-3 top-1/2 -translate-y-1/2 p-2 bg-haven-600 rounded-lg text-white hover:bg-haven-700 transition-colors">
              <Mic className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

// Manager Contact Footer (Premium)
function ManagerContactFooter({ manager }: { manager: typeof mockManager }) {
  return (
    <div className="relative overflow-hidden bg-gradient-to-br from-warm-900 via-warm-800 to-warm-900 rounded-2xl p-6 text-white">
      {/* Background Pattern */}
      <div className="absolute inset-0 opacity-5">
        <div className="absolute top-0 right-0 w-64 h-64 bg-white rounded-full -translate-y-1/2 translate-x-1/2" />
      </div>

      <div className="relative flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div className="flex items-center gap-4">
          <Avatar name={manager.name} src={manager.avatar} size="xl" status="online" />
          <div>
            <h3 className="text-lg font-bold">{manager.name}</h3>
            <p className="text-warm-400">Your Home Manager</p>
          </div>
        </div>

        <div className="flex gap-3">
          <a
            href="tel:+13105550123"
            className="flex items-center gap-2 px-4 py-2.5 bg-white/10 hover:bg-white/20 rounded-xl font-medium transition-colors backdrop-blur-sm"
          >
            <Phone className="w-4 h-4" />
            Call
          </a>
          <Link
            href="/app/messages"
            className="flex items-center gap-2 px-4 py-2.5 bg-haven-600 hover:bg-haven-700 rounded-xl font-medium transition-colors"
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

  const dismissAction = (id: string) => {
    setActionItems(prev => prev.filter(item => item.id !== id));
  };

  const decisionItems = actionItems.filter(item => item.priority === 'decision');
  const respondItems = actionItems.filter(item => item.priority === 'respond');
  const hasActionItems = actionItems.length > 0;

  return (
    <div className="pb-32 lg:pb-8 max-w-6xl mx-auto">
      {/* Hero Greeting */}
      <HeroGreeting userName={userName} weather={mockWeather} />

      {/* Today's Notes */}
      <div className="mb-6">
        <TodayNotesCard notes={mockTodayNotes} />
      </div>

      {/* Action Items or All Caught Up */}
      <div className="mb-6">
        {hasActionItems ? (
          <div className="space-y-4">
            {decisionItems.map(item => (
              <DecisionCard key={item.id} item={item} onDismiss={dismissAction} />
            ))}
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

      {/* Manager Status */}
      <div className="mb-6">
        <ManagerStatusCard manager={mockManager} tasks={mockManagerTasks} />
      </div>

      {/* Two Column Layout */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        <FamilyLogisticsCard members={mockFamilyStatus} />
        <HouseHealthCard health={mockHouseHealth} />
      </div>

      {/* Quick Actions */}
      <div className="mb-6">
        <QuickActionsCard onOpenRequest={() => setShowRequestModal(true)} />
      </div>

      {/* Manager Contact Footer */}
      <ManagerContactFooter manager={mockManager} />

      {/* Request Modal */}
      <RequestModal isOpen={showRequestModal} onClose={() => setShowRequestModal(false)} />
    </div>
  );
}
