'use client';

import { useEffect, useState, useMemo } from 'react';
import Link from 'next/link';
import { useAuth } from '@/contexts/auth-context';
import { useApi } from '@/hooks/useApi';
import { Card, CardHeader, Badge, Button } from '@/components/ui';
import { ManagerAvatar } from '@/components/ui/avatar';
import { getHealthColors } from '@/lib/utils/healthColors';
import {
  Sun,
  Cloud,
  CloudRain,
  Trash2,
  CheckCircle2,
  ChevronRight,
  Wrench,
  CreditCard,
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
  Plus,
  Activity,
  Loader2,
} from 'lucide-react';

// ============================================================================
// TYPES
// ============================================================================

interface DashboardData {
  household: {
    id: string;
    name: string;
    propertyAddress: string | null;
  };
  manager: {
    id: string;
    name: string;
    email: string;
    phone: string | null;
  } | null;
  homeHealth: number;
  billing: {
    monthlyFunding: number;
    amountPaid: number;
    billsPaidCount: number;
    bufferRemaining: number;
  };
  nextService: {
    title: string;
    vendorName: string | null;
    date: string;
  } | null;
  pendingApprovals: number;
  recentActivity: Array<{
    id: string;
    title: string;
    description?: string;
    actorName: string;
    category: string;
    createdAt: string;
  }>;
  upcoming: Array<{
    id: string;
    title: string;
    type: string;
    date: string;
  }>;
}

type WeatherCondition = 'sunny' | 'cloudy' | 'rainy';

interface WeatherData {
  temp: number;
  condition: WeatherCondition;
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

function formatRelativeTime(dateString: string) {
  const date = new Date(dateString);
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMs / 3600000);
  const diffDays = Math.floor(diffMs / 86400000);

  if (diffMins < 60) return `${diffMins}m ago`;
  if (diffHours < 24) return `${diffHours}h ago`;
  if (diffDays === 1) return 'Yesterday';
  if (diffDays < 7) return `${diffDays}d ago`;
  return date.toLocaleDateString();
}

function formatDate(dateString: string) {
  return new Date(dateString).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  });
}

function getItemIcon(type: string) {
  switch (type) {
    case 'service':
      return <Wrench className="w-5 h-5 text-blue-600" />;
    case 'bill':
      return <CreditCard className="w-5 h-5 text-green-600" />;
    case 'activity':
      return <Activity className="w-5 h-5 text-purple-600" />;
    default:
      return <Calendar className="w-5 h-5 text-gray-600" />;
  }
}

// Mock weather until we integrate a weather API
const mockWeather: WeatherData = {
  temp: 68,
  condition: 'sunny',
};

// ============================================================================
// COMPONENTS
// ============================================================================

function DashboardSkeleton() {
  return (
    <div className="pb-32 lg:pb-8 max-w-6xl mx-auto animate-pulse">
      <div className="rounded-2xl sm:rounded-3xl bg-gray-200 h-48 sm:h-56 mb-6 sm:mb-8" />
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
        {[1, 2, 3].map((i) => (
          <div key={i} className="h-32 bg-gray-200 rounded-xl" />
        ))}
      </div>
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="h-64 bg-gray-200 rounded-xl" />
        <div className="h-64 bg-gray-200 rounded-xl" />
      </div>
    </div>
  );
}

function HeroGreeting({
  userName,
  weather,
  propertyAddress,
  homeHealth,
  billing,
}: {
  userName: string;
  weather: WeatherData;
  propertyAddress: string | null;
  homeHealth: number;
  billing: DashboardData['billing'];
}) {
  const { greeting, note } = useMemo(() => getGreeting(), []);
  const WeatherIcon = WEATHER_ICONS[weather.condition];
  const today = new Date().toLocaleDateString('en-US', {
    weekday: 'long',
    month: 'long',
    day: 'numeric',
  });
  const healthColors = getHealthColors(homeHealth);

  return (
    <div className="relative overflow-hidden rounded-2xl sm:rounded-3xl bg-gradient-to-br from-haven-700 via-haven-700 to-haven-800 p-4 sm:p-8 text-white mb-6 sm:mb-8">
      {/* Background Pattern */}
      <div className="absolute inset-0 opacity-10">
        <div className="absolute top-0 right-0 w-96 h-96 bg-white rounded-full -translate-y-1/2 translate-x-1/2" />
        <div className="absolute bottom-0 left-0 w-64 h-64 bg-white rounded-full translate-y-1/2 -translate-x-1/2" />
      </div>

      <div className="relative">
        <div className="flex items-start justify-between gap-3">
          <div className="min-w-0 flex-1">
            <p className="text-haven-100 text-xs sm:text-sm font-medium mb-1">{today}</p>
            <h1 className="text-2xl sm:text-3xl lg:text-4xl font-bold tracking-tight mb-1 sm:mb-2 text-white truncate">
              {greeting}, {userName}
            </h1>
            {propertyAddress && (
              <p className="text-haven-100 text-sm sm:text-base truncate">{propertyAddress}</p>
            )}
            {note && <p className="text-haven-100 text-sm sm:text-lg mt-1">{note}</p>}
          </div>
          <div className="flex-shrink-0 flex items-center gap-2 sm:gap-3 bg-white/20 backdrop-blur-sm rounded-xl sm:rounded-2xl px-3 py-2 sm:px-4 sm:py-3">
            <WeatherIcon className="w-6 h-6 sm:w-8 sm:h-8" />
            <span className="text-xl sm:text-2xl font-bold">{weather.temp}°</span>
          </div>
        </div>

        {/* Quick Stats */}
        <div className="grid grid-cols-2 sm:grid-cols-3 gap-3 mt-6">
          {/* Home Health */}
          <div
            className={`col-span-2 sm:col-span-1 ${healthColors.bg} ${healthColors.border} border rounded-xl px-4 py-3`}
          >
            <p className="text-warm-500 text-xs font-medium">Home Health</p>
            <div className="flex items-center gap-2">
              <p className={`text-2xl font-bold ${healthColors.text}`}>{homeHealth}%</p>
              <span className={`px-1.5 py-0.5 rounded text-xs font-medium ${healthColors.badge}`}>
                {healthColors.label}
              </span>
            </div>
          </div>
          {/* Bills Paid */}
          <div className="bg-champagne-100 border border-champagne-200 rounded-xl px-4 py-3">
            <p className="text-champagne-600 text-xs font-medium">Bills Paid</p>
            <p className="text-2xl font-bold text-haven-700">{billing.billsPaidCount}</p>
          </div>
          {/* Amount Paid */}
          <div className="bg-champagne-100 border border-champagne-200 rounded-xl px-4 py-3">
            <p className="text-champagne-600 text-xs font-medium">This Month</p>
            <p className="text-lg font-semibold text-haven-700">
              ${billing.amountPaid.toLocaleString()}
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}

function BillingCard({ billing }: { billing: DashboardData['billing'] }) {
  const progressPercent =
    billing.monthlyFunding > 0
      ? Math.min((billing.amountPaid / billing.monthlyFunding) * 100, 100)
      : 0;

  return (
    <Card hover>
      <div className="flex items-center gap-3 mb-3">
        <div className="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center">
          <CreditCard className="w-5 h-5 text-green-600" />
        </div>
        <span className="font-medium text-gray-600">This Month</span>
      </div>
      <div className="text-2xl font-bold text-haven-navy-900">
        ${billing.amountPaid.toLocaleString()}
      </div>
      <div className="text-sm text-gray-500">{billing.billsPaidCount} bills paid</div>
      <div className="mt-3 w-full bg-gray-100 rounded-full h-2">
        <div
          className="bg-green-500 h-2 rounded-full transition-all"
          style={{ width: `${progressPercent}%` }}
        />
      </div>
      <div className="text-xs text-gray-400 mt-1">
        ${billing.bufferRemaining.toFixed(0)} buffer remaining
      </div>
    </Card>
  );
}

function NextServiceCard({ nextService }: { nextService: DashboardData['nextService'] }) {
  return (
    <Card hover>
      <div className="flex items-center gap-3 mb-3">
        <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
          <Wrench className="w-5 h-5 text-blue-600" />
        </div>
        <span className="font-medium text-gray-600">Next Service</span>
      </div>
      {nextService ? (
        <>
          <div className="text-lg font-semibold text-haven-navy-900">{nextService.title}</div>
          {nextService.vendorName && (
            <div className="text-sm text-gray-500">{nextService.vendorName}</div>
          )}
          <div className="text-sm text-haven-champagne-600 mt-1">
            {formatDate(nextService.date)}
          </div>
        </>
      ) : (
        <div className="text-gray-400">No services scheduled</div>
      )}
    </Card>
  );
}

function PendingApprovalsCard({ count }: { count: number }) {
  return (
    <Card hover>
      <div className="flex items-center gap-3 mb-3">
        <div
          className={`w-10 h-10 rounded-lg flex items-center justify-center ${count > 0 ? 'bg-orange-100' : 'bg-gray-100'}`}
        >
          {count > 0 ? (
            <AlertCircle className="w-5 h-5 text-orange-600" />
          ) : (
            <CheckCircle2 className="w-5 h-5 text-gray-400" />
          )}
        </div>
        <span className="font-medium text-gray-600">Action Items</span>
      </div>
      {count > 0 ? (
        <>
          <div className="text-2xl font-bold text-haven-navy-900">{count}</div>
          <div className="text-sm text-orange-600">
            approval{count > 1 ? 's' : ''} needed
          </div>
          <Link
            href="/app/requests"
            className="inline-block mt-2 text-sm text-haven-champagne-600 hover:underline"
          >
            Review now →
          </Link>
        </>
      ) : (
        <div className="text-gray-400">All caught up!</div>
      )}
    </Card>
  );
}

function RecentActivityCard({
  activities,
}: {
  activities: DashboardData['recentActivity'];
}) {
  return (
    <Card>
      <div className="flex items-center justify-between mb-4">
        <h2 className="font-semibold text-haven-navy-900 flex items-center gap-2">
          <Activity className="w-5 h-5" />
          Recent Activity
        </h2>
        <Link href="/app/activity" className="text-sm text-haven-champagne-600 hover:underline">
          See all
        </Link>
      </div>
      <div className="divide-y divide-gray-50">
        {activities.length > 0 ? (
          activities.map((activity) => (
            <div key={activity.id} className="py-3 hover:bg-gray-50 transition">
              <div className="flex items-start justify-between">
                <div>
                  <div className="font-medium text-haven-navy-900">{activity.title}</div>
                  {activity.description && (
                    <div className="text-sm text-gray-500">{activity.description}</div>
                  )}
                  <div className="text-xs text-gray-400 mt-1">{activity.actorName}</div>
                </div>
                <div className="text-xs text-gray-400">
                  {formatRelativeTime(activity.createdAt)}
                </div>
              </div>
            </div>
          ))
        ) : (
          <div className="py-8 text-center text-gray-400">No recent activity yet</div>
        )}
      </div>
    </Card>
  );
}

function UpcomingCard({ items }: { items: DashboardData['upcoming'] }) {
  return (
    <Card>
      <div className="flex items-center justify-between mb-4">
        <h2 className="font-semibold text-haven-navy-900 flex items-center gap-2">
          <Calendar className="w-5 h-5" />
          Upcoming
        </h2>
        <Link href="/app/calendar" className="text-sm text-haven-champagne-600 hover:underline">
          View calendar
        </Link>
      </div>
      <div className="divide-y divide-gray-50">
        {items.length > 0 ? (
          items.map((item) => (
            <div key={item.id} className="py-3 flex items-center gap-4">
              <div
                className={`w-10 h-10 rounded-lg flex items-center justify-center ${
                  item.type === 'service'
                    ? 'bg-blue-100'
                    : item.type === 'bill'
                      ? 'bg-green-100'
                      : item.type === 'activity'
                        ? 'bg-purple-100'
                        : 'bg-gray-100'
                }`}
              >
                {getItemIcon(item.type)}
              </div>
              <div className="flex-1">
                <div className="font-medium text-haven-navy-900">{item.title}</div>
                <div className="text-sm text-gray-500">{formatDate(item.date)}</div>
              </div>
            </div>
          ))
        ) : (
          <div className="py-8 text-center text-gray-400">Nothing scheduled yet</div>
        )}
      </div>
    </Card>
  );
}

function ManagerCard({ manager }: { manager: DashboardData['manager'] }) {
  if (!manager) return null;

  return (
    <Card>
      <div className="flex items-center gap-4 mb-4">
        <div className="relative">
          <ManagerAvatar size="lg" />
          <span className="absolute -bottom-0.5 -right-0.5 w-3 h-3 bg-green-500 rounded-full border-2 border-white" />
        </div>
        <div>
          <h3 className="font-bold text-warm-900">{manager.name}</h3>
          <p className="text-sm text-warm-500">Your Home Manager</p>
        </div>
      </div>
      <div className="flex gap-3">
        {manager.phone && (
          <a
            href={`tel:${manager.phone}`}
            className="flex-1 flex items-center justify-center gap-2 px-4 py-2.5 border border-gray-200 rounded-xl text-gray-700 hover:bg-gray-50 transition"
          >
            <Phone className="w-4 h-4" />
            Call
          </a>
        )}
        <Link
          href="/app/messages"
          className="flex-1 flex items-center justify-center gap-2 px-4 py-2.5 bg-haven-700 text-white rounded-xl hover:bg-haven-800 transition"
        >
          <MessageCircle className="w-4 h-4" />
          Message
        </Link>
      </div>
    </Card>
  );
}

function QuickActionsCard() {
  return (
    <Card>
      <CardHeader title="Quick Actions" />
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
          href="/app/money"
          className="flex flex-col items-center gap-2 p-4 bg-warm-50 rounded-xl hover:bg-warm-100 transition-colors group"
        >
          <div className="p-2 bg-white rounded-lg shadow-sm group-hover:shadow transition-shadow">
            <FileText className="w-5 h-5 text-warm-600" />
          </div>
          <span className="text-xs font-medium text-warm-600">Money</span>
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

// ============================================================================
// MAIN DASHBOARD PAGE
// ============================================================================

export default function DashboardPage() {
  const { user, getIdToken, householdId } = useAuth();
  const [data, setData] = useState<DashboardData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const userName = user?.firstName || user?.displayName?.split(' ')[0] || 'there';

  useEffect(() => {
    if (householdId) {
      fetchDashboard();
    }
  }, [householdId]);

  const fetchDashboard = async () => {
    try {
      const token = await getIdToken();
      if (!token || !householdId) return;

      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/dashboard/household/${householdId}`,
        {
          headers: { Authorization: `Bearer ${token}` },
        }
      );

      if (!response.ok) {
        throw new Error('Failed to load dashboard');
      }

      const result = await response.json();
      setData(result);
    } catch (err) {
      console.error('Dashboard error:', err);
      setError(err instanceof Error ? err.message : 'Unknown error');
    } finally {
      setLoading(false);
    }
  };

  if (loading) return <DashboardSkeleton />;

  if (error) {
    return (
      <div className="p-6 text-center">
        <AlertCircle className="w-12 h-12 text-red-500 mx-auto mb-4" />
        <p className="text-red-600">Error loading dashboard: {error}</p>
        <Button onClick={fetchDashboard} className="mt-4">
          Try Again
        </Button>
      </div>
    );
  }

  if (!data) {
    return (
      <div className="p-6 text-center">
        <p className="text-gray-500">No dashboard data available yet.</p>
        <p className="text-sm text-gray-400 mt-2">
          Your Home Manager will set up your household during onboarding.
        </p>
      </div>
    );
  }

  return (
    <div className="pb-32 lg:pb-8 max-w-6xl mx-auto">
      {/* Hero Greeting */}
      <HeroGreeting
        userName={userName}
        weather={mockWeather}
        propertyAddress={data.household.propertyAddress}
        homeHealth={data.homeHealth}
        billing={data.billing}
      />

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
        <BillingCard billing={data.billing} />
        <NextServiceCard nextService={data.nextService} />
        <PendingApprovalsCard count={data.pendingApprovals} />
      </div>

      {/* Manager Card */}
      {data.manager && (
        <div className="mb-6">
          <ManagerCard manager={data.manager} />
        </div>
      )}

      {/* Two Column Layout */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        <RecentActivityCard activities={data.recentActivity} />
        <UpcomingCard items={data.upcoming} />
      </div>

      {/* Quick Actions */}
      <QuickActionsCard />
    </div>
  );
}
