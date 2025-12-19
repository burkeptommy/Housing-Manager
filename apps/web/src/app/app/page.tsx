'use client';

import Link from 'next/link';
import { useAuth } from '@/contexts/auth-context';
import Map, { Marker, Layer } from 'react-map-gl/mapbox';
import 'mapbox-gl/dist/mapbox-gl.css';
import {
  Sun,
  Truck,
  ShieldCheck,
  Home,
  FileText,
  Clock,
  CheckCircle2,
  Phone,
  MessageSquare,
  DollarSign,
  Wrench,
  ShoppingBag,
  Droplets,
  Sparkles,
  ChevronRight,
  MapPin,
  ExternalLink,
} from 'lucide-react';

// ============================================================================
// TYPES
// ============================================================================

interface WeatherData {
  temp: number;
  condition: 'sunny' | 'cloudy' | 'rainy';
  icon: typeof Sun;
}

interface StatusCard {
  title: string;
  icon: typeof Truck;
  value: string;
  subtext: string;
  highlight?: boolean;
  highlightColor?: string;
}

interface TimelineEvent {
  id: string;
  time: string;
  title: string;
  description: string;
  icon: typeof Truck;
  status: 'completed' | 'in_progress' | 'upcoming';
}

interface ActivityItem {
  id: string;
  description: string;
  timestamp: string;
  icon: typeof DollarSign;
  amount?: string;
}

interface Manager {
  name: string;
  title: string;
  photoUrl: string;
  phone: string;
}

// ============================================================================
// MOCK DATA
// ============================================================================

const mockWeather: WeatherData = {
  temp: 72,
  condition: 'sunny',
  icon: Sun,
};

const mockSummary = {
  invoicesHandled: 3,
  repairsScheduled: 1,
  weekLabel: 'this week',
};

const mockStatusCards: StatusCard[] = [
  {
    title: 'Next Service Visit',
    icon: Truck,
    value: 'Landscaper',
    subtext: 'Tomorrow @ 9:00 AM',
  },
  {
    title: 'Recent Visit',
    icon: ShieldCheck,
    value: 'Property Check',
    subtext: 'Completed today 8:30 AM',
  },
  {
    title: 'Home Mode',
    icon: Home,
    value: 'Family Home',
    subtext: '4 members present',
  },
  {
    title: 'Pending Approvals',
    icon: FileText,
    value: '1 Estimate Ready',
    subtext: 'Deck refinishing quote',
    highlight: true,
    highlightColor: 'text-amber-500',
  },
];

const mockTimeline: TimelineEvent[] = [
  {
    id: '1',
    time: '8:30 AM',
    title: 'Property Check',
    description: 'Weekly walkthrough completed by Steve',
    icon: ShieldCheck,
    status: 'completed',
  },
  {
    id: '2',
    time: '10:00 AM',
    title: 'Housekeeper Arrival',
    description: 'Maria - Deep cleaning scheduled',
    icon: Sparkles,
    status: 'in_progress',
  },
  {
    id: '3',
    time: '2:00 PM',
    title: 'Grocery Delivery',
    description: 'Weekly stock-up from Whole Foods',
    icon: ShoppingBag,
    status: 'upcoming',
  },
  {
    id: '4',
    time: '4:00 PM',
    title: 'Pool Maintenance',
    description: 'AquaCare - Monthly service',
    icon: Droplets,
    status: 'upcoming',
  },
];

const mockActivity: ActivityItem[] = [
  {
    id: '1',
    description: 'Concierge processed Electric Bill',
    timestamp: '2 hours ago',
    icon: DollarSign,
    amount: '$145.00',
  },
  {
    id: '2',
    description: 'Handyman replaced HVAC Filter',
    timestamp: 'Yesterday',
    icon: Wrench,
  },
  {
    id: '3',
    description: 'Weekly Grocery Stock-up completed',
    timestamp: 'Yesterday',
    icon: ShoppingBag,
    amount: '$287.50',
  },
  {
    id: '4',
    description: 'Concierge paid Water & Sewer',
    timestamp: '3 days ago',
    icon: DollarSign,
    amount: '$78.00',
  },
  {
    id: '5',
    description: 'Lawn care service completed',
    timestamp: '4 days ago',
    icon: Truck,
  },
  {
    id: '6',
    description: 'Concierge renewed Home Insurance',
    timestamp: '1 week ago',
    icon: ShieldCheck,
    amount: '$1,245.00',
  },
];

const mockManager: Manager = {
  name: 'Steve Martinez',
  title: 'Your Home Manager',
  photoUrl: '/manager-avatar.jpg',
  phone: '(310) 555-0123',
};

// Home location for the map
const homeLocation = {
  lat: 34.0696,
  lng: -118.4065,
  address: '742 Maple Drive, Beverly Hills',
};

// Nearby activity pins for the map
const nearbyActivity = [
  { id: 'a1', type: 'vendor', lat: 34.0710, lng: -118.4050, label: 'Landscaper on route' },
  { id: 'a2', type: 'delivery', lat: 34.0685, lng: -118.4080, label: 'Grocery delivery' },
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

// ============================================================================
// COMPONENTS
// ============================================================================

// Greeting Header with Weather
function GreetingHeader({ userName, weather }: { userName: string; weather: WeatherData }) {
  const WeatherIcon = weather.icon;

  return (
    <div className="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4 mb-2">
      <div>
        <h1 className="text-2xl lg:text-3xl font-bold text-slate-900 tracking-tight">
          {getGreeting()}, {userName}.
        </h1>
      </div>
      <div className="flex items-center gap-2 px-4 py-2 bg-white rounded-xl border border-slate-200 shadow-sm">
        <WeatherIcon className="w-5 h-5 text-amber-500" />
        <span className="text-lg font-semibold text-slate-900">{weather.temp}°F</span>
        <span className="text-slate-500 capitalize">{weather.condition}</span>
      </div>
    </div>
  );
}

// Executive Summary
function ExecutiveSummary({ invoicesHandled, repairsScheduled, weekLabel }: typeof mockSummary) {
  return (
    <p className="text-slate-600 text-lg mb-8">
      Your home is running smoothly. Your Concierge handled{' '}
      <span className="font-semibold text-emerald-600">{invoicesHandled} invoices</span> and scheduled{' '}
      <span className="font-semibold text-emerald-600">{repairsScheduled} repair</span> {weekLabel}.
    </p>
  );
}

// Peace of Mind Status Strip
function StatusStrip({ cards }: { cards: StatusCard[] }) {
  return (
    <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
      {cards.map((card) => {
        const Icon = card.icon;
        return (
          <div
            key={card.title}
            className="bg-white rounded-xl shadow-sm border border-slate-200 p-4 hover:shadow-md transition-shadow"
          >
            <div className="flex items-start gap-3">
              <div className={`p-2 rounded-lg ${card.highlight ? 'bg-amber-50' : 'bg-emerald-50'}`}>
                <Icon className={`w-5 h-5 ${card.highlight ? 'text-amber-600' : 'text-emerald-600'}`} />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-xs text-slate-500 uppercase tracking-wide mb-1">{card.title}</p>
                <p className={`font-semibold ${card.highlight && card.highlightColor ? card.highlightColor : 'text-slate-900'}`}>
                  {card.value}
                </p>
                <p className="text-xs text-slate-500 mt-0.5 truncate">{card.subtext}</p>
              </div>
            </div>
          </div>
        );
      })}
    </div>
  );
}

// Today's Logistics Timeline
function LogisticsTimeline({ events }: { events: TimelineEvent[] }) {
  return (
    <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6 mb-6">
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-2">
          <Clock className="w-5 h-5 text-emerald-600" />
          <h2 className="text-lg font-semibold text-slate-900">Today's Logistics</h2>
        </div>
        <Link href="/app/calendar" className="text-sm text-emerald-600 hover:text-emerald-700 font-medium flex items-center gap-1">
          Full Schedule
          <ChevronRight className="w-4 h-4" />
        </Link>
      </div>

      <div className="relative">
        {/* Timeline line */}
        <div className="absolute left-4 top-2 bottom-2 w-0.5 bg-slate-200" />

        <div className="space-y-6">
          {events.map((event) => {
            const Icon = event.icon;
            const isInProgress = event.status === 'in_progress';
            const isCompleted = event.status === 'completed';

            return (
              <div key={event.id} className="flex items-start gap-4 relative">
                {/* Timeline dot */}
                <div
                  className={`relative z-10 w-8 h-8 rounded-full flex items-center justify-center ${
                    isCompleted
                      ? 'bg-emerald-100'
                      : isInProgress
                        ? 'bg-emerald-500'
                        : 'bg-slate-100'
                  }`}
                >
                  {isInProgress && (
                    <span className="absolute inset-0 rounded-full bg-emerald-500 animate-ping opacity-25" />
                  )}
                  {isCompleted ? (
                    <CheckCircle2 className="w-4 h-4 text-emerald-600" />
                  ) : (
                    <Icon className={`w-4 h-4 ${isInProgress ? 'text-white' : 'text-slate-500'}`} />
                  )}
                </div>

                {/* Content */}
                <div className={`flex-1 ${isCompleted ? 'opacity-60' : ''}`}>
                  <div className="flex items-center gap-3 mb-1">
                    <span className={`text-sm font-medium ${isInProgress ? 'text-emerald-600' : 'text-slate-500'}`}>
                      {event.time}
                    </span>
                    {isInProgress && (
                      <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-emerald-100 text-emerald-700 text-xs font-medium rounded-full">
                        <span className="w-1.5 h-1.5 bg-emerald-500 rounded-full animate-pulse" />
                        In Progress
                      </span>
                    )}
                    {isCompleted && (
                      <span className="text-xs text-emerald-600 font-medium">Completed</span>
                    )}
                  </div>
                  <p className={`font-medium ${isCompleted ? 'text-slate-500' : 'text-slate-900'}`}>
                    {event.title}
                  </p>
                  <p className="text-sm text-slate-500">{event.description}</p>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}

// Recent Activity Feed (Proof of Value)
function ActivityFeed({ activities }: { activities: ActivityItem[] }) {
  return (
    <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-2">
          <Sparkles className="w-5 h-5 text-emerald-600" />
          <h2 className="text-lg font-semibold text-slate-900">Recent Activity</h2>
        </div>
        <span className="text-sm text-slate-500">What your Concierge has handled</span>
      </div>

      <div className="space-y-4">
        {activities.map((activity) => {
          const Icon = activity.icon;
          return (
            <div key={activity.id} className="flex items-start gap-3 pb-4 border-b border-slate-100 last:border-0 last:pb-0">
              <div className="p-2 rounded-lg bg-slate-50">
                <Icon className="w-4 h-4 text-slate-600" />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-slate-800">{activity.description}</p>
                <div className="flex items-center gap-2 mt-1">
                  <span className="text-xs text-slate-500">{activity.timestamp}</span>
                  {activity.amount && (
                    <>
                      <span className="text-slate-300">·</span>
                      <span className="text-xs font-medium text-slate-700">{activity.amount}</span>
                    </>
                  )}
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

// Quick Actions
function QuickActions() {
  const actions = [
    {
      label: 'Request Service',
      icon: Wrench,
      href: '/app/requests/new',
      color: 'bg-emerald-600 hover:bg-emerald-700 text-white',
    },
    {
      label: 'Notify Arrival',
      icon: MapPin,
      href: '/app/notify',
      color: 'bg-white hover:bg-slate-50 text-slate-700 border border-slate-200',
    },
    {
      label: 'Approve Expenses',
      icon: FileText,
      href: '/app/approvals',
      color: 'bg-white hover:bg-slate-50 text-slate-700 border border-slate-200',
    },
  ];

  return (
    <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6 mb-6">
      <h2 className="text-lg font-semibold text-slate-900 mb-4">Quick Actions</h2>
      <div className="flex flex-wrap gap-3">
        {actions.map((action) => {
          const Icon = action.icon;
          return (
            <Link
              key={action.label}
              href={action.href}
              className={`inline-flex items-center gap-2 px-4 py-2.5 rounded-lg font-medium shadow-sm transition-colors ${action.color}`}
            >
              <Icon className="w-4 h-4" />
              {action.label}
            </Link>
          );
        })}
      </div>
    </div>
  );
}

// 3D Neighborhood Map
function NeighborhoodMap() {
  // 3D building layer configuration - using any to avoid complex Mapbox expression types
  const buildingLayer = {
    id: '3d-buildings',
    source: 'composite',
    'source-layer': 'building',
    filter: ['==', 'extrude', 'true'],
    type: 'fill-extrusion' as const,
    minzoom: 15,
    paint: {
      'fill-extrusion-color': '#aaa',
      'fill-extrusion-height': ['get', 'height'] as unknown as number,
      'fill-extrusion-base': ['get', 'min_height'] as unknown as number,
      'fill-extrusion-opacity': 0.6,
    },
  };

  return (
    <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden mb-6">
      <div className="flex items-center justify-between p-4 border-b border-slate-100">
        <div className="flex items-center gap-2">
          <MapPin className="w-5 h-5 text-emerald-600" />
          <h2 className="text-lg font-semibold text-slate-900">Your Neighborhood</h2>
        </div>
        <Link
          href="/app/home"
          className="text-sm text-emerald-600 hover:text-emerald-700 font-medium flex items-center gap-1"
        >
          Home Profile
          <ExternalLink className="w-3.5 h-3.5" />
        </Link>
      </div>
      <div className="h-48 relative">
        <Map
          initialViewState={{
            longitude: homeLocation.lng,
            latitude: homeLocation.lat,
            zoom: 16,
            pitch: 50,
            bearing: -17.6,
          }}
          style={{ width: '100%', height: '100%' }}
          mapStyle="mapbox://styles/mapbox/streets-v12"
          mapboxAccessToken={process.env.NEXT_PUBLIC_MAPBOX_TOKEN}
          attributionControl={false}
          interactive={true}
        >
          {/* 3D Buildings Layer */}
          <Layer {...buildingLayer} />

          {/* Home Marker */}
          <Marker
            longitude={homeLocation.lng}
            latitude={homeLocation.lat}
            anchor="bottom"
          >
            <div className="relative">
              <div className="w-10 h-10 rounded-full bg-emerald-600 border-3 border-white shadow-lg flex items-center justify-center">
                <Home className="w-5 h-5 text-white" />
              </div>
              <div className="absolute -bottom-1 left-1/2 -translate-x-1/2 w-0 h-0 border-l-4 border-r-4 border-t-4 border-l-transparent border-r-transparent border-t-emerald-600" />
            </div>
          </Marker>

          {/* Activity Markers */}
          {nearbyActivity.map((activity) => (
            <Marker
              key={activity.id}
              longitude={activity.lng}
              latitude={activity.lat}
              anchor="center"
            >
              <div className="w-6 h-6 rounded-full bg-amber-500 border-2 border-white shadow-md flex items-center justify-center animate-pulse">
                {activity.type === 'vendor' ? (
                  <Truck className="w-3 h-3 text-white" />
                ) : (
                  <ShoppingBag className="w-3 h-3 text-white" />
                )}
              </div>
            </Marker>
          ))}
        </Map>
      </div>
      <div className="p-3 bg-slate-50 text-center">
        <p className="text-sm text-slate-600">
          <span className="font-medium text-slate-900">{homeLocation.address}</span>
        </p>
      </div>
    </div>
  );
}

// Manager Contact Card
function ManagerCard({ manager }: { manager: Manager }) {
  return (
    <div className="bg-gradient-to-br from-slate-900 to-slate-800 rounded-xl shadow-sm p-6 text-white">
      <div className="flex items-center gap-4 mb-4">
        <div className="w-16 h-16 rounded-full bg-emerald-600 flex items-center justify-center text-2xl font-bold overflow-hidden">
          {/* Placeholder avatar - replace with actual image */}
          <span>SM</span>
        </div>
        <div>
          <h3 className="text-lg font-semibold">{manager.name}</h3>
          <p className="text-slate-400">{manager.title}</p>
        </div>
      </div>

      <p className="text-sm text-slate-300 mb-4">
        I'm here to ensure your home runs smoothly. Reach out anytime you need assistance.
      </p>

      <div className="flex gap-3">
        <a
          href={`tel:${manager.phone}`}
          className="flex-1 inline-flex items-center justify-center gap-2 px-4 py-2.5 bg-white/10 hover:bg-white/20 rounded-lg font-medium transition-colors"
        >
          <Phone className="w-4 h-4" />
          Call
        </a>
        <Link
          href="/app/messages"
          className="flex-1 inline-flex items-center justify-center gap-2 px-4 py-2.5 bg-emerald-600 hover:bg-emerald-700 rounded-lg font-medium transition-colors"
        >
          <MessageSquare className="w-4 h-4" />
          Chat
        </Link>
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
    <div className="pb-32 lg:pb-8">
      {/* Greeting & Weather */}
      <GreetingHeader userName={userName} weather={mockWeather} />

      {/* Executive Summary */}
      <ExecutiveSummary {...mockSummary} />

      {/* Peace of Mind Status Strip */}
      <StatusStrip cards={mockStatusCards} />

      {/* Main Content Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left Column - Timeline & Activity (2/3 width) */}
        <div className="lg:col-span-2 space-y-6">
          {/* Today's Logistics */}
          <LogisticsTimeline events={mockTimeline} />

          {/* Recent Activity */}
          <ActivityFeed activities={mockActivity} />
        </div>

        {/* Right Column - Map, Actions & Manager (1/3 width) */}
        <div className="space-y-6">
          {/* Neighborhood Map */}
          <NeighborhoodMap />

          {/* Quick Actions */}
          <QuickActions />

          {/* Manager Card */}
          <ManagerCard manager={mockManager} />
        </div>
      </div>
    </div>
  );
}
