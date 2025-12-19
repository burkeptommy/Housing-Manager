'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useAuth } from '@/contexts/auth-context';
import {
  Sun,
  Cloud,
  CloudRain,
  Trash2,
  AlertCircle,
  CheckCircle2,
  Clock,
  ChevronRight,
  DollarSign,
  Wrench,
  ShoppingCart,
  CreditCard,
  MapPin,
  Car,
  GraduationCap,
  Briefcase,
  Home,
  Users,
  Dog,
  MessageCircle,
  Phone,
  Activity,
  Loader2,
  Calendar,
  ThermometerSun,
  Droplets,
  Wind,
  X,
  Plus,
  FileText,
  Bell,
  Sparkles,
  Heart,
  Coffee,
} from 'lucide-react';

// ============================================================================
// TYPES
// ============================================================================

type WeatherCondition = 'sunny' | 'cloudy' | 'rainy';
type ApprovalType = 'financial' | 'logistics' | 'system';
type FamilyLocationStatus = 'home' | 'work' | 'school' | 'activity' | 'away' | 'unknown';

interface WeatherData {
  temp: number;
  condition: WeatherCondition;
  humidity: number;
  wind: number;
}

interface ActionItem {
  id: string;
  type: ApprovalType;
  title: string;
  description: string;
  amount?: number;
  source: string;
  urgent: boolean;
  actionLabel: string;
  secondaryLabel?: string;
}

interface FamilyMemberStatus {
  id: string;
  name: string;
  initials: string;
  color: string;
  location: FamilyLocationStatus;
  locationLabel: string;
  until?: string;
}

interface ManagerActivity {
  id: string;
  task: string;
  status: 'researching' | 'in_progress' | 'waiting' | 'completed';
  assignedTime: string;
  detail?: string;
}

interface HomeHealthData {
  score: number;
  nextService: string;
  nextServiceDays: number;
  alerts: number;
}

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
  humidity: 45,
  wind: 8,
};

const mockContextMessage = "Trash Day is Tomorrow.";

const mockActionItems: ActionItem[] = [
  {
    id: 'action-1',
    type: 'financial',
    title: 'Authorize Roof Repair',
    description: 'Ace Roofing submitted quote for shingle replacement on north side.',
    amount: 1200,
    source: 'Money',
    urgent: true,
    actionLabel: 'Approve',
    secondaryLabel: 'Review',
  },
  {
    id: 'action-2',
    type: 'logistics',
    title: 'Nanny Contract Renewal',
    description: 'Maria\'s annual contract expires in 7 days. Review updated terms.',
    source: 'Family',
    urgent: true,
    actionLabel: 'Review Contract',
  },
  {
    id: 'action-3',
    type: 'system',
    title: 'HVAC Service Scheduled',
    description: 'Annual maintenance with AirFlow HVAC.',
    source: 'Maintenance',
    urgent: false,
    actionLabel: 'View Details',
  },
];

const mockFamilyStatus: FamilyMemberStatus[] = [
  { id: 'bob', name: 'Bob', initials: 'B', color: 'bg-blue-500', location: 'work', locationLabel: 'At Work', until: '5:30 PM' },
  { id: 'alice', name: 'Alice', initials: 'A', color: 'bg-pink-500', location: 'home', locationLabel: 'Home' },
  { id: 'emma', name: 'Emma', initials: 'E', color: 'bg-purple-500', location: 'activity', locationLabel: 'Soccer Practice', until: '4:00 PM' },
  { id: 'jake', name: 'Jake', initials: 'J', color: 'bg-orange-500', location: 'school', locationLabel: 'At School', until: '3:15 PM' },
  { id: 'max', name: 'Max', initials: 'M', color: 'bg-amber-500', location: 'home', locationLabel: 'Home' },
];

const mockManagerActivity: ManagerActivity[] = [
  { id: 'ma-1', task: 'Researching Summer Camps', status: 'researching', assignedTime: '2h ago', detail: 'Found 3 STEM camps in budget' },
  { id: 'ma-2', task: 'Booking Anniversary Dinner', status: 'completed', assignedTime: '4h ago', detail: 'La Maison, Dec 28 @ 7:15 PM' },
  { id: 'ma-3', task: 'Getting Driveway Quotes', status: 'in_progress', assignedTime: 'Yesterday', detail: '2 of 3 quotes received' },
];

const mockHomeHealth: HomeHealthData = {
  score: 94,
  nextService: 'Gutter Cleaning',
  nextServiceDays: 14,
  alerts: 2,
};

const mockManager = {
  name: 'Sarah Mitchell',
  initials: 'SM',
  currentTask: 'Researching Summer Camps',
};

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

function getGreeting(): string {
  const hour = new Date().getHours();
  if (hour < 12) return 'Good Morning';
  if (hour < 17) return 'Good Afternoon';
  return 'Good Evening';
}

function getLocationIcon(location: FamilyLocationStatus) {
  switch (location) {
    case 'work': return Briefcase;
    case 'school': return GraduationCap;
    case 'activity': return Activity;
    case 'home': return Home;
    case 'away': return Car;
    default: return MapPin;
  }
}

function getLocationColor(location: FamilyLocationStatus) {
  switch (location) {
    case 'work': return 'bg-blue-100 text-blue-700';
    case 'school': return 'bg-amber-100 text-amber-700';
    case 'activity': return 'bg-purple-100 text-purple-700';
    case 'home': return 'bg-emerald-100 text-emerald-700';
    case 'away': return 'bg-slate-100 text-slate-700';
    default: return 'bg-slate-100 text-slate-500';
  }
}

function getHealthColor(score: number) {
  if (score >= 90) return 'text-emerald-600';
  if (score >= 70) return 'text-amber-600';
  return 'text-red-600';
}

function getHealthStrokeColor(score: number) {
  if (score >= 90) return '#10b981';
  if (score >= 70) return '#f59e0b';
  return '#ef4444';
}

// ============================================================================
// COMPONENTS
// ============================================================================

// Glassmorphism Action Card
function ActionCard({ item, onDismiss }: { item: ActionItem; onDismiss: (id: string) => void }) {
  const getTypeIcon = () => {
    switch (item.type) {
      case 'financial': return DollarSign;
      case 'logistics': return Users;
      case 'system': return Wrench;
    }
  };

  const getTypeBadgeColor = () => {
    switch (item.type) {
      case 'financial': return 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20';
      case 'logistics': return 'bg-blue-500/10 text-blue-400 border-blue-500/20';
      case 'system': return 'bg-amber-500/10 text-amber-400 border-amber-500/20';
    }
  };

  const TypeIcon = getTypeIcon();

  return (
    <div className="relative backdrop-blur-xl bg-white/80 rounded-2xl border border-white/20 shadow-lg shadow-slate-900/5 p-5 hover:shadow-xl transition-shadow">
      {/* Dismiss button */}
      <button
        onClick={() => onDismiss(item.id)}
        className="absolute top-3 right-3 p-1 hover:bg-slate-100 rounded-lg transition-colors text-slate-400 hover:text-slate-600"
      >
        <X className="w-4 h-4" />
      </button>

      {/* Type badge */}
      <div className="flex items-center gap-2 mb-3">
        <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium border ${getTypeBadgeColor()}`}>
          <TypeIcon className="w-3 h-3" />
          {item.source}
        </span>
        {item.urgent && (
          <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-red-100 text-red-700 text-xs font-medium rounded-full">
            <AlertCircle className="w-3 h-3" />
            Urgent
          </span>
        )}
      </div>

      {/* Content */}
      <h3 className="font-semibold text-slate-900 mb-1">
        {item.title}
        {item.amount && (
          <span className="ml-2 text-emerald-600">${item.amount.toLocaleString()}</span>
        )}
      </h3>
      <p className="text-sm text-slate-600 mb-4">{item.description}</p>

      {/* Actions */}
      <div className="flex gap-2">
        <button className="flex-1 px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition-colors font-medium text-sm shadow-sm">
          {item.actionLabel}
        </button>
        {item.secondaryLabel && (
          <button className="px-4 py-2 bg-slate-100 text-slate-700 rounded-lg hover:bg-slate-200 transition-colors font-medium text-sm">
            {item.secondaryLabel}
          </button>
        )}
      </div>
    </div>
  );
}

// Health Score Gauge
function HealthGauge({ score }: { score: number }) {
  const radius = 45;
  const circumference = 2 * Math.PI * radius;
  const strokeDashoffset = circumference - (score / 100) * circumference;

  return (
    <div className="relative w-28 h-28">
      <svg className="w-full h-full transform -rotate-90" viewBox="0 0 100 100">
        {/* Background circle */}
        <circle
          cx="50"
          cy="50"
          r={radius}
          fill="none"
          stroke="#e2e8f0"
          strokeWidth="8"
        />
        {/* Progress circle */}
        <circle
          cx="50"
          cy="50"
          r={radius}
          fill="none"
          stroke={getHealthStrokeColor(score)}
          strokeWidth="8"
          strokeLinecap="round"
          strokeDasharray={circumference}
          strokeDashoffset={strokeDashoffset}
          className="transition-all duration-1000 ease-out"
        />
      </svg>
      {/* Center text */}
      <div className="absolute inset-0 flex flex-col items-center justify-center">
        <span className={`text-2xl font-bold ${getHealthColor(score)}`}>{score}%</span>
        <span className="text-xs text-slate-500">Healthy</span>
      </div>
    </div>
  );
}

// Family Status Pill
function FamilyStatusPill({ member }: { member: FamilyMemberStatus }) {
  const LocationIcon = getLocationIcon(member.location);
  const colorClass = getLocationColor(member.location);
  const isPet = member.id === 'max';

  return (
    <div className={`inline-flex items-center gap-2 px-3 py-2 rounded-xl ${colorClass}`}>
      <div className={`w-8 h-8 rounded-full ${member.color} flex items-center justify-center text-white text-xs font-medium`}>
        {isPet ? <Dog className="w-4 h-4" /> : member.initials}
      </div>
      <div className="text-left">
        <div className="text-sm font-medium">{member.name}</div>
        <div className="flex items-center gap-1 text-xs opacity-80">
          <LocationIcon className="w-3 h-3" />
          {member.locationLabel}
          {member.until && <span>until {member.until}</span>}
        </div>
      </div>
    </div>
  );
}

// Manager Activity Item
function ManagerActivityItem({ activity }: { activity: ManagerActivity }) {
  const getStatusIcon = () => {
    switch (activity.status) {
      case 'researching': return <Loader2 className="w-4 h-4 animate-spin text-blue-500" />;
      case 'in_progress': return <Clock className="w-4 h-4 text-amber-500" />;
      case 'waiting': return <Clock className="w-4 h-4 text-slate-400" />;
      case 'completed': return <CheckCircle2 className="w-4 h-4 text-emerald-500" />;
    }
  };

  const getStatusBadge = () => {
    switch (activity.status) {
      case 'researching': return 'bg-blue-100 text-blue-700';
      case 'in_progress': return 'bg-amber-100 text-amber-700';
      case 'waiting': return 'bg-slate-100 text-slate-600';
      case 'completed': return 'bg-emerald-100 text-emerald-700';
    }
  };

  return (
    <div className="flex items-start gap-3 py-3 border-b border-slate-100 last:border-0">
      <div className="mt-0.5">{getStatusIcon()}</div>
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2">
          <span className="font-medium text-slate-800 text-sm">{activity.task}</span>
          <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${getStatusBadge()}`}>
            {activity.status.replace('_', ' ')}
          </span>
        </div>
        {activity.detail && (
          <p className="text-sm text-slate-500 mt-0.5">{activity.detail}</p>
        )}
        <span className="text-xs text-slate-400">{activity.assignedTime}</span>
      </div>
    </div>
  );
}

// Quick Action Button
function QuickActionButton({ icon: Icon, label, href, variant = 'default' }: {
  icon: typeof Plus;
  label: string;
  href: string;
  variant?: 'default' | 'primary';
}) {
  return (
    <Link
      href={href}
      className={`flex items-center gap-3 px-4 py-3 rounded-xl transition-all ${
        variant === 'primary'
          ? 'bg-emerald-600 text-white hover:bg-emerald-700 shadow-lg shadow-emerald-600/25'
          : 'bg-white text-slate-700 hover:bg-slate-50 border border-slate-200 shadow-sm'
      }`}
    >
      <Icon className="w-5 h-5" />
      <span className="font-medium">{label}</span>
    </Link>
  );
}

// Request Modal
function RequestModal({ isOpen, onClose }: { isOpen: boolean; onClose: () => void }) {
  if (!isOpen) return null;

  const quickRequests = [
    { icon: Wrench, label: 'Something needs fixing', category: 'Maintenance' },
    { icon: Sparkles, label: 'Need cleaning service', category: 'Cleaning' },
    { icon: ShoppingCart, label: 'Need something bought', category: 'Shopping' },
    { icon: Calendar, label: 'Schedule an appointment', category: 'Scheduling' },
    { icon: FileText, label: 'Research something', category: 'Research' },
    { icon: Coffee, label: 'Something else', category: 'Other' },
  ];

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl shadow-xl max-w-md w-full">
        <div className="p-6 border-b border-slate-200">
          <div className="flex items-center justify-between">
            <h2 className="text-xl font-bold text-slate-900">I need...</h2>
            <button
              onClick={onClose}
              className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
            >
              <X className="w-5 h-5 text-slate-500" />
            </button>
          </div>
        </div>

        <div className="p-4 space-y-2">
          {quickRequests.map((request) => {
            const Icon = request.icon;
            return (
              <button
                key={request.category}
                onClick={onClose}
                className="w-full flex items-center gap-4 p-4 rounded-xl hover:bg-slate-50 transition-colors text-left"
              >
                <div className="p-3 bg-emerald-50 rounded-xl">
                  <Icon className="w-6 h-6 text-emerald-600" />
                </div>
                <div>
                  <div className="font-medium text-slate-900">{request.label}</div>
                  <div className="text-sm text-slate-500">{request.category}</div>
                </div>
                <ChevronRight className="w-5 h-5 text-slate-400 ml-auto" />
              </button>
            );
          })}
        </div>

        <div className="p-4 border-t border-slate-200">
          <input
            type="text"
            placeholder="Or describe what you need..."
            className="w-full px-4 py-3 border border-slate-300 rounded-xl focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
          />
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

  const WeatherIcon = WEATHER_ICONS[mockWeather.condition];

  const dismissAction = (id: string) => {
    setActionItems(prev => prev.filter(item => item.id !== id));
  };

  return (
    <div className="pb-32 lg:pb-8">
      {/* ================================================================== */}
      {/* MORNING BRIEFING - Hero Section */}
      {/* ================================================================== */}
      <div className="mb-8">
        {/* Greeting Row */}
        <div className="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4 mb-6">
          <div>
            <h1 className="text-2xl lg:text-3xl font-bold text-slate-900 tracking-tight">
              {getGreeting()}, {userName}.
            </h1>
            <div className="flex items-center gap-2 mt-2 text-slate-600">
              <Trash2 className="w-4 h-4 text-amber-500" />
              <span>{mockContextMessage}</span>
            </div>
          </div>

          {/* Weather Card */}
          <div className="flex items-center gap-4 px-4 py-3 bg-white rounded-xl border border-slate-200 shadow-sm">
            <div className="flex items-center gap-2">
              <WeatherIcon className="w-8 h-8 text-amber-500" />
              <span className="text-2xl font-bold text-slate-900">{mockWeather.temp}°F</span>
            </div>
            <div className="hidden sm:flex flex-col text-xs text-slate-500 border-l border-slate-200 pl-4">
              <div className="flex items-center gap-1">
                <Droplets className="w-3 h-3" /> {mockWeather.humidity}%
              </div>
              <div className="flex items-center gap-1">
                <Wind className="w-3 h-3" /> {mockWeather.wind} mph
              </div>
            </div>
          </div>
        </div>

        {/* Action Stack - Glassmorphism Cards */}
        {actionItems.length > 0 && (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {actionItems.map(item => (
              <ActionCard key={item.id} item={item} onDismiss={dismissAction} />
            ))}
          </div>
        )}

        {actionItems.length === 0 && (
          <div className="bg-gradient-to-r from-emerald-50 to-teal-50 rounded-2xl border border-emerald-100 p-8 text-center">
            <CheckCircle2 className="w-12 h-12 text-emerald-500 mx-auto mb-3" />
            <h3 className="text-lg font-semibold text-slate-900 mb-1">All Clear</h3>
            <p className="text-slate-600">No pending approvals. Your home is running smoothly.</p>
          </div>
        )}
      </div>

      {/* ================================================================== */}
      {/* LIVE PULSE - Real-Time Status */}
      {/* ================================================================== */}
      <div className="mb-8">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-semibold text-slate-900 flex items-center gap-2">
            <Activity className="w-5 h-5 text-emerald-600" />
            Live Pulse
          </h2>
          <Link href="/app/family" className="text-sm text-emerald-600 hover:text-emerald-700 font-medium flex items-center gap-1">
            Family Details
            <ChevronRight className="w-4 h-4" />
          </Link>
        </div>

        {/* Family Status Row */}
        <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-4 mb-4">
          <h3 className="text-sm font-medium text-slate-500 uppercase tracking-wide mb-3">Family Logistics</h3>
          <div className="flex flex-wrap gap-3">
            {mockFamilyStatus.map(member => (
              <FamilyStatusPill key={member.id} member={member} />
            ))}
          </div>
        </div>

        {/* Staff Activity Feed */}
        <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-4">
          <div className="flex items-center justify-between mb-3">
            <h3 className="text-sm font-medium text-slate-500 uppercase tracking-wide">Your Manager</h3>
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-full bg-emerald-600 flex items-center justify-center text-white text-xs font-medium">
                {mockManager.initials}
              </div>
              <div className="text-sm">
                <span className="font-medium text-slate-800">{mockManager.name}</span>
                <span className="text-slate-500"> is currently:</span>
              </div>
            </div>
          </div>

          <div className="bg-emerald-50 rounded-lg p-3 mb-4">
            <div className="flex items-center gap-2">
              <Loader2 className="w-4 h-4 text-emerald-600 animate-spin" />
              <span className="font-medium text-emerald-800">{mockManager.currentTask}</span>
            </div>
          </div>

          <div className="divide-y divide-slate-100">
            {mockManagerActivity.map(activity => (
              <ManagerActivityItem key={activity.id} activity={activity} />
            ))}
          </div>

          <Link
            href="/app/tasks"
            className="block w-full mt-4 py-2 text-center text-sm text-emerald-600 hover:bg-emerald-50 rounded-lg transition-colors font-medium"
          >
            View All Manager Tasks
          </Link>
        </div>
      </div>

      {/* ================================================================== */}
      {/* BOTTOM ROW - Health & Quick Actions */}
      {/* ================================================================== */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* House Health Widget */}
        <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold text-slate-900 flex items-center gap-2">
              <Heart className="w-5 h-5 text-red-500" />
              House Health
            </h2>
            <Link href="/app/maintenance" className="text-sm text-emerald-600 hover:text-emerald-700 font-medium flex items-center gap-1">
              Full Report
              <ChevronRight className="w-4 h-4" />
            </Link>
          </div>

          <div className="flex items-center gap-6">
            <HealthGauge score={mockHomeHealth.score} />

            <div className="flex-1">
              <div className="flex items-center gap-2 mb-3">
                <ThermometerSun className="w-5 h-5 text-slate-400" />
                <span className="text-slate-700">Next Service:</span>
              </div>
              <div className="text-lg font-semibold text-slate-900">{mockHomeHealth.nextService}</div>
              <div className="text-sm text-slate-500">in {mockHomeHealth.nextServiceDays} days</div>

              {mockHomeHealth.alerts > 0 && (
                <div className="mt-4 flex items-center gap-2 px-3 py-2 bg-amber-50 rounded-lg">
                  <Bell className="w-4 h-4 text-amber-600" />
                  <span className="text-sm text-amber-700 font-medium">
                    {mockHomeHealth.alerts} items need attention
                  </span>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Quick Actions */}
        <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
          <h2 className="text-lg font-semibold text-slate-900 mb-4">Quick Actions</h2>

          <div className="space-y-3">
            <button
              onClick={() => setShowRequestModal(true)}
              className="w-full flex items-center gap-3 px-4 py-3 bg-emerald-600 text-white rounded-xl hover:bg-emerald-700 transition-all shadow-lg shadow-emerald-600/25"
            >
              <Plus className="w-5 h-5" />
              <span className="font-medium">I need...</span>
              <span className="text-emerald-200 text-sm ml-auto">Open request</span>
            </button>

            <QuickActionButton
              icon={ShoppingCart}
              label="Add to Shopping List"
              href="/app/inventory"
            />

            <QuickActionButton
              icon={CreditCard}
              label="Pay a Bill"
              href="/app/money"
            />

            <QuickActionButton
              icon={MessageCircle}
              label="Message Manager"
              href="/app/messages"
            />
          </div>
        </div>
      </div>

      {/* Manager Contact Footer */}
      <div className="mt-8 bg-gradient-to-br from-slate-900 to-slate-800 rounded-2xl p-6 text-white">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          <div className="flex items-center gap-4">
            <div className="w-14 h-14 rounded-full bg-emerald-600 flex items-center justify-center text-xl font-bold">
              SM
            </div>
            <div>
              <h3 className="text-lg font-semibold">Sarah Mitchell</h3>
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

      {/* Request Modal */}
      <RequestModal isOpen={showRequestModal} onClose={() => setShowRequestModal(false)} />
    </div>
  );
}
