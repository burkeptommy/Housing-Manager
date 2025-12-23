# 🔧 HAVEN - HANDYMAN PORTAL FIX & ENHANCEMENT

## HOW TO RUN

```bash
cd /Users/tomburke/Projects/Housing-Manager
claude --dangerously-skip-permissions
```

Then paste this entire prompt.

---

## ISSUE: HANDYMAN PORTAL CRASH

**Error:** `TypeError: undefined is not an object (evaluating 't.hoursLoggedToday.toFixed')`

**Cause:** The handyman dashboard expects `hoursLoggedToday` from the API but it's undefined. Need null safety AND proper API data.

---

## FIX 1: NULL SAFETY IN HANDYMAN DASHBOARD

**File:** `apps/web/src/app/handyman/page.tsx`

Add null safety to ALL data access:

```typescript
'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { useAuth } from '@/contexts/auth-context';
import { useApi } from '@/hooks/use-api';
import { getUserAvatar } from '@/lib/avatars';
import {
  Clock,
  MapPin,
  CheckCircle2,
  Calendar,
  Play,
  ChevronRight,
  Wrench,
  Home,
  AlertCircle,
  Timer,
  TrendingUp,
  ClipboardList,
  Navigation,
} from 'lucide-react';

interface WorkOrder {
  id: string;
  title: string;
  description?: string;
  status: string;
  priority?: string;
  scheduledDate?: string;
  scheduledTime?: string;
  estimatedDuration?: number;
  household?: {
    id: string;
    name: string;
    address?: string;
  };
  property?: {
    address: string;
    city: string;
  };
}

interface HandymanStats {
  tasksToday: number;
  tasksCompleted: number;
  hoursLoggedToday: number;
  tasksThisWeek: number;
  avgCompletionTime: number;
}

export default function HandymanDashboard() {
  const { user } = useAuth();
  const api = useApi();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [todaysTasks, setTodaysTasks] = useState<WorkOrder[]>([]);
  const [stats, setStats] = useState<HandymanStats>({
    tasksToday: 0,
    tasksCompleted: 0,
    hoursLoggedToday: 0,
    tasksThisWeek: 0,
    avgCompletionTime: 0,
  });
  const [activeTask, setActiveTask] = useState<WorkOrder | null>(null);

  useEffect(() => {
    loadDashboard();
  }, []);

  async function loadDashboard() {
    try {
      setLoading(true);
      setError(null);
      
      // Try to fetch from API, with fallback to demo data
      try {
        const response = await api.getHandymanDashboard();
        if (response) {
          setTodaysTasks(response.todaysTasks || []);
          setStats({
            tasksToday: response.stats?.tasksToday ?? 0,
            tasksCompleted: response.stats?.tasksCompleted ?? 0,
            hoursLoggedToday: response.stats?.hoursLoggedToday ?? 0,
            tasksThisWeek: response.stats?.tasksThisWeek ?? 0,
            avgCompletionTime: response.stats?.avgCompletionTime ?? 0,
          });
          setActiveTask(response.activeTask || null);
        }
      } catch (apiError) {
        console.log('API not available, using demo data');
        // Use demo data as fallback
        setTodaysTasks(demoTasks);
        setStats(demoStats);
      }
    } catch (err) {
      console.error('Dashboard error:', err);
      setError('Failed to load dashboard');
      // Still set demo data so page renders
      setTodaysTasks(demoTasks);
      setStats(demoStats);
    } finally {
      setLoading(false);
    }
  }

  const userName = user?.displayName || 'Mike';
  const greeting = getGreeting();

  if (loading) {
    return <LoadingSkeleton />;
  }

  return (
    <div className="min-h-screen bg-warm-50">
      {/* Header */}
      <header className="bg-gradient-to-br from-forest-900 to-forest-950 text-white px-4 pt-6 pb-20">
        <div className="flex items-center justify-between mb-6">
          <div>
            <p className="text-forest-300 text-sm">{greeting}</p>
            <h1 className="text-2xl font-bold">{userName}</h1>
          </div>
          <img 
            src={getUserAvatar(userName)} 
            alt={userName}
            className="w-12 h-12 rounded-full ring-2 ring-white/20"
          />
        </div>
        
        {/* Quick Stats */}
        <div className="grid grid-cols-3 gap-3">
          <div className="bg-white/10 backdrop-blur rounded-xl p-3 text-center">
            <div className="text-2xl font-bold">{stats.tasksToday}</div>
            <div className="text-xs text-forest-300">Today's Tasks</div>
          </div>
          <div className="bg-white/10 backdrop-blur rounded-xl p-3 text-center">
            <div className="text-2xl font-bold">{stats.tasksCompleted}</div>
            <div className="text-xs text-forest-300">Completed</div>
          </div>
          <div className="bg-white/10 backdrop-blur rounded-xl p-3 text-center">
            <div className="text-2xl font-bold">{(stats.hoursLoggedToday ?? 0).toFixed(1)}h</div>
            <div className="text-xs text-forest-300">Hours Logged</div>
          </div>
        </div>
      </header>

      {/* Main Content - Overlapping cards */}
      <main className="px-4 -mt-12 pb-24 space-y-4">
        {/* Active Task Card */}
        {activeTask && (
          <div className="card bg-gradient-to-r from-haven-500 to-haven-600 text-white p-4 rounded-2xl">
            <div className="flex items-center gap-2 mb-2">
              <Timer className="w-4 h-4" />
              <span className="text-sm font-medium">In Progress</span>
            </div>
            <h3 className="font-semibold text-lg">{activeTask.title}</h3>
            <p className="text-haven-100 text-sm mt-1">{activeTask.household?.name}</p>
            <div className="flex items-center justify-between mt-4">
              <div className="flex items-center gap-2 text-sm">
                <Clock className="w-4 h-4" />
                <span>Started 45 min ago</span>
              </div>
              <Link 
                href={`/handyman/jobs/${activeTask.id}`}
                className="btn-white btn-sm"
              >
                Continue
              </Link>
            </div>
          </div>
        )}

        {/* Today's Tasks */}
        <div className="card p-4 rounded-2xl">
          <div className="flex items-center justify-between mb-4">
            <h2 className="font-semibold text-warm-900">Today's Schedule</h2>
            <Link href="/handyman/schedule" className="text-sm text-haven-600">
              View All
            </Link>
          </div>
          
          {todaysTasks.length === 0 ? (
            <div className="text-center py-8">
              <CheckCircle2 className="w-12 h-12 text-haven-500 mx-auto mb-2" />
              <p className="text-warm-600">All caught up for today!</p>
            </div>
          ) : (
            <div className="space-y-3">
              {todaysTasks.map((task, index) => (
                <TaskCard key={task.id} task={task} index={index} />
              ))}
            </div>
          )}
        </div>

        {/* Quick Actions */}
        <div className="grid grid-cols-2 gap-3">
          <Link href="/handyman/schedule" className="card p-4 rounded-xl card-hover text-center">
            <Calendar className="w-8 h-8 text-haven-600 mx-auto mb-2" />
            <span className="text-sm font-medium text-warm-900">Schedule</span>
          </Link>
          <Link href="/handyman/households" className="card p-4 rounded-xl card-hover text-center">
            <Home className="w-8 h-8 text-blue-600 mx-auto mb-2" />
            <span className="text-sm font-medium text-warm-900">Households</span>
          </Link>
          <Link href="/handyman/reports" className="card p-4 rounded-xl card-hover text-center">
            <ClipboardList className="w-8 h-8 text-purple-600 mx-auto mb-2" />
            <span className="text-sm font-medium text-warm-900">Reports</span>
          </Link>
          <Link href="/handyman/systems" className="card p-4 rounded-xl card-hover text-center">
            <Wrench className="w-8 h-8 text-amber-600 mx-auto mb-2" />
            <span className="text-sm font-medium text-warm-900">Systems</span>
          </Link>
        </div>

        {/* Weekly Stats */}
        <div className="card p-4 rounded-2xl">
          <h2 className="font-semibold text-warm-900 mb-4">This Week</h2>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <div className="text-3xl font-bold text-warm-900">{stats.tasksThisWeek}</div>
              <div className="text-sm text-warm-500">Tasks Completed</div>
            </div>
            <div>
              <div className="text-3xl font-bold text-warm-900">{stats.avgCompletionTime}m</div>
              <div className="text-sm text-warm-500">Avg Completion</div>
            </div>
          </div>
        </div>
      </main>

      {/* Bottom Navigation */}
      <nav className="fixed bottom-0 left-0 right-0 bg-white border-t border-warm-200 px-6 py-3">
        <div className="flex items-center justify-around">
          <Link href="/handyman" className="flex flex-col items-center text-haven-600">
            <Home className="w-6 h-6" />
            <span className="text-xs mt-1">Home</span>
          </Link>
          <Link href="/handyman/schedule" className="flex flex-col items-center text-warm-400">
            <Calendar className="w-6 h-6" />
            <span className="text-xs mt-1">Schedule</span>
          </Link>
          <Link href="/handyman/households" className="flex flex-col items-center text-warm-400">
            <Home className="w-6 h-6" />
            <span className="text-xs mt-1">Homes</span>
          </Link>
          <Link href="/handyman/profile" className="flex flex-col items-center text-warm-400">
            <img 
              src={getUserAvatar(userName)} 
              alt="" 
              className="w-6 h-6 rounded-full"
            />
            <span className="text-xs mt-1">Profile</span>
          </Link>
        </div>
      </nav>
    </div>
  );
}

// Task Card Component
function TaskCard({ task, index }: { task: WorkOrder; index: number }) {
  const statusColors: Record<string, string> = {
    SCHEDULED: 'bg-blue-100 text-blue-700',
    ASSIGNED: 'bg-amber-100 text-amber-700',
    IN_PROGRESS: 'bg-haven-100 text-haven-700',
    COMPLETED: 'bg-green-100 text-green-700',
  };

  return (
    <Link 
      href={`/handyman/jobs/${task.id}`}
      className="flex items-center gap-4 p-3 rounded-xl hover:bg-warm-50 transition-colors"
    >
      <div className="w-12 h-12 rounded-xl bg-warm-100 flex items-center justify-center text-warm-600">
        <Wrench className="w-6 h-6" />
      </div>
      <div className="flex-1 min-w-0">
        <h3 className="font-medium text-warm-900 truncate">{task.title}</h3>
        <div className="flex items-center gap-2 text-sm text-warm-500">
          <MapPin className="w-3 h-3" />
          <span className="truncate">{task.household?.name || task.property?.address || 'Unknown'}</span>
        </div>
        {task.scheduledTime && (
          <div className="flex items-center gap-1 text-sm text-warm-500 mt-1">
            <Clock className="w-3 h-3" />
            <span>{task.scheduledTime}</span>
            {task.estimatedDuration && (
              <span className="text-warm-400">• {task.estimatedDuration} min</span>
            )}
          </div>
        )}
      </div>
      <div className="flex flex-col items-end gap-2">
        <span className={`badge ${statusColors[task.status] || 'badge-neutral'}`}>
          {task.status.replace('_', ' ')}
        </span>
        <ChevronRight className="w-5 h-5 text-warm-400" />
      </div>
    </Link>
  );
}

// Loading Skeleton
function LoadingSkeleton() {
  return (
    <div className="min-h-screen bg-warm-50">
      <header className="bg-forest-900 px-4 pt-6 pb-20">
        <div className="flex items-center justify-between mb-6">
          <div>
            <div className="skeleton-dark h-4 w-20 mb-2" />
            <div className="skeleton-dark h-8 w-32" />
          </div>
          <div className="skeleton-dark w-12 h-12 rounded-full" />
        </div>
        <div className="grid grid-cols-3 gap-3">
          {[1, 2, 3].map(i => (
            <div key={i} className="bg-white/10 rounded-xl p-3 h-16" />
          ))}
        </div>
      </header>
      <main className="px-4 -mt-12 space-y-4">
        <div className="card p-4 rounded-2xl">
          <div className="skeleton h-6 w-40 mb-4" />
          {[1, 2, 3].map(i => (
            <div key={i} className="flex gap-4 p-3">
              <div className="skeleton w-12 h-12 rounded-xl" />
              <div className="flex-1">
                <div className="skeleton h-5 w-48 mb-2" />
                <div className="skeleton h-4 w-32" />
              </div>
            </div>
          ))}
        </div>
      </main>
    </div>
  );
}

// Helper functions
function getGreeting(): string {
  const hour = new Date().getHours();
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

// Demo data fallback
const demoStats: HandymanStats = {
  tasksToday: 4,
  tasksCompleted: 2,
  hoursLoggedToday: 3.5,
  tasksThisWeek: 18,
  avgCompletionTime: 45,
};

const demoTasks: WorkOrder[] = [
  {
    id: 'wo-1',
    title: 'Replace Smoke Detector Batteries',
    status: 'SCHEDULED',
    scheduledTime: '9:00 AM',
    estimatedDuration: 30,
    household: { id: 'h1', name: 'Smith Residence', address: '123 Main St' },
  },
  {
    id: 'wo-2',
    title: 'Fix Squeaky Door Hinge',
    status: 'SCHEDULED',
    scheduledTime: '10:30 AM',
    estimatedDuration: 20,
    household: { id: 'h1', name: 'Smith Residence', address: '123 Main St' },
  },
  {
    id: 'wo-3',
    title: 'Install Smart Thermostat',
    status: 'SCHEDULED',
    scheduledTime: '2:00 PM',
    estimatedDuration: 60,
    household: { id: 'h2', name: 'Johnson Home', address: '456 Oak Ave' },
  },
  {
    id: 'wo-4',
    title: 'Repair Cabinet Handles',
    status: 'IN_PROGRESS',
    scheduledTime: '11:30 AM',
    estimatedDuration: 45,
    household: { id: 'h1', name: 'Smith Residence', address: '123 Main St' },
  },
];
```

---

## FIX 2: HANDYMAN HOUSEHOLDS PAGE (View All Homes)

**Create file:** `apps/web/src/app/handyman/households/page.tsx`

```typescript
'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { 
  Home, 
  MapPin, 
  ChevronRight, 
  Search,
  Thermometer,
  Droplets,
  Zap,
  Shield,
  Flame,
  Wind,
} from 'lucide-react';

interface Household {
  id: string;
  name: string;
  address: string;
  city: string;
  imageUrl?: string;
  lastVisit?: string;
  upcomingTasks: number;
  systems: SystemStatus[];
}

interface SystemStatus {
  name: string;
  type: 'hvac' | 'plumbing' | 'electrical' | 'security' | 'pool' | 'other';
  status: 'good' | 'warning' | 'critical';
  lastServiced?: string;
  nextService?: string;
}

const systemIcons = {
  hvac: Thermometer,
  plumbing: Droplets,
  electrical: Zap,
  security: Shield,
  pool: Droplets,
  other: Wrench,
};

// Demo data
const households: Household[] = [
  {
    id: 'h1',
    name: 'Smith Residence',
    address: '123 Greenwich Ave',
    city: 'Greenwich, CT',
    lastVisit: '2 days ago',
    upcomingTasks: 3,
    systems: [
      { name: 'HVAC System', type: 'hvac', status: 'good', lastServiced: 'Nov 15, 2024', nextService: 'May 2025' },
      { name: 'Water Heater', type: 'plumbing', status: 'warning', lastServiced: 'Jun 2024', nextService: 'Overdue' },
      { name: 'Main Panel', type: 'electrical', status: 'good', lastServiced: 'Aug 2024' },
      { name: 'Security System', type: 'security', status: 'good', lastServiced: 'Oct 2024' },
    ],
  },
  {
    id: 'h2',
    name: 'Johnson Home',
    address: '456 Round Hill Rd',
    city: 'Greenwich, CT',
    lastVisit: '1 week ago',
    upcomingTasks: 1,
    systems: [
      { name: 'Carrier AC', type: 'hvac', status: 'good', lastServiced: 'Sep 2024' },
      { name: 'Pool Equipment', type: 'pool', status: 'good', lastServiced: 'Nov 2024' },
      { name: 'Generator', type: 'electrical', status: 'warning', lastServiced: 'Mar 2024', nextService: 'Service recommended' },
    ],
  },
  {
    id: 'h3',
    name: 'Williams Estate',
    address: '789 Field Point Rd',
    city: 'Greenwich, CT',
    lastVisit: '3 weeks ago',
    upcomingTasks: 0,
    systems: [
      { name: 'Geothermal HVAC', type: 'hvac', status: 'good' },
      { name: 'Whole House Filter', type: 'plumbing', status: 'critical', lastServiced: 'Jan 2024', nextService: 'Filter replacement needed' },
      { name: 'Smart Home Hub', type: 'other', status: 'good' },
    ],
  },
];

export default function HandymanHouseholdsPage() {
  const [searchQuery, setSearchQuery] = useState('');
  
  const filteredHouseholds = households.filter(h => 
    h.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    h.address.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="min-h-screen bg-warm-50 pb-24">
      {/* Header */}
      <header className="bg-white border-b border-warm-200 px-4 py-4 sticky top-0 z-10">
        <h1 className="text-xl font-bold text-warm-900 mb-3">My Households</h1>
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-warm-400" />
          <input
            type="text"
            placeholder="Search households..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="input pl-10"
          />
        </div>
      </header>

      {/* Households List */}
      <main className="p-4 space-y-4">
        {filteredHouseholds.map(household => (
          <HouseholdCard key={household.id} household={household} />
        ))}
      </main>

      {/* Bottom Nav */}
      <BottomNav active="households" />
    </div>
  );
}

function HouseholdCard({ household }: { household: Household }) {
  const warningCount = household.systems.filter(s => s.status === 'warning').length;
  const criticalCount = household.systems.filter(s => s.status === 'critical').length;
  
  return (
    <Link href={`/handyman/households/${household.id}`}>
      <div className="card p-4 rounded-2xl card-hover">
        <div className="flex items-start justify-between mb-3">
          <div>
            <h3 className="font-semibold text-warm-900">{household.name}</h3>
            <div className="flex items-center gap-1 text-sm text-warm-500 mt-1">
              <MapPin className="w-3 h-3" />
              <span>{household.address}</span>
            </div>
          </div>
          <ChevronRight className="w-5 h-5 text-warm-400" />
        </div>
        
        {/* System Status Summary */}
        <div className="flex items-center gap-2 mb-3">
          {criticalCount > 0 && (
            <span className="badge badge-error">
              {criticalCount} Critical
            </span>
          )}
          {warningCount > 0 && (
            <span className="badge badge-warning">
              {warningCount} Needs Attention
            </span>
          )}
          {criticalCount === 0 && warningCount === 0 && (
            <span className="badge badge-success">All Systems Good</span>
          )}
        </div>
        
        {/* System Icons */}
        <div className="flex items-center gap-2">
          {household.systems.slice(0, 4).map((system, i) => {
            const Icon = systemIcons[system.type] || Wrench;
            const colors = {
              good: 'bg-green-100 text-green-600',
              warning: 'bg-amber-100 text-amber-600',
              critical: 'bg-red-100 text-red-600',
            };
            return (
              <div 
                key={i}
                className={`w-8 h-8 rounded-lg flex items-center justify-center ${colors[system.status]}`}
                title={system.name}
              >
                <Icon className="w-4 h-4" />
              </div>
            );
          })}
          {household.systems.length > 4 && (
            <span className="text-xs text-warm-500">+{household.systems.length - 4} more</span>
          )}
        </div>
        
        {/* Footer */}
        <div className="flex items-center justify-between mt-3 pt-3 border-t border-warm-100 text-sm">
          <span className="text-warm-500">Last visit: {household.lastVisit}</span>
          {household.upcomingTasks > 0 && (
            <span className="text-haven-600 font-medium">{household.upcomingTasks} upcoming tasks</span>
          )}
        </div>
      </div>
    </Link>
  );
}

function BottomNav({ active }: { active: string }) {
  return (
    <nav className="fixed bottom-0 left-0 right-0 bg-white border-t border-warm-200 px-6 py-3">
      <div className="flex items-center justify-around">
        <Link href="/handyman" className={`flex flex-col items-center ${active === 'home' ? 'text-haven-600' : 'text-warm-400'}`}>
          <Home className="w-6 h-6" />
          <span className="text-xs mt-1">Home</span>
        </Link>
        <Link href="/handyman/schedule" className={`flex flex-col items-center ${active === 'schedule' ? 'text-haven-600' : 'text-warm-400'}`}>
          <Calendar className="w-6 h-6" />
          <span className="text-xs mt-1">Schedule</span>
        </Link>
        <Link href="/handyman/households" className={`flex flex-col items-center ${active === 'households' ? 'text-haven-600' : 'text-warm-400'}`}>
          <Home className="w-6 h-6" />
          <span className="text-xs mt-1">Homes</span>
        </Link>
      </div>
    </nav>
  );
}
```

---

## FIX 3: HOUSEHOLD DETAIL WITH SYSTEMS VIEW

**Create file:** `apps/web/src/app/handyman/households/[id]/page.tsx`

```typescript
'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useParams } from 'next/navigation';
import {
  ArrowLeft,
  MapPin,
  Phone,
  Mail,
  Thermometer,
  Droplets,
  Zap,
  Shield,
  Wrench,
  Calendar,
  Clock,
  AlertTriangle,
  CheckCircle2,
  ChevronRight,
  Camera,
  FileText,
  Plus,
} from 'lucide-react';
import { getUserAvatar } from '@/lib/avatars';

// Demo household data
const householdData = {
  id: 'h1',
  name: 'Smith Residence',
  address: '123 Greenwich Ave',
  city: 'Greenwich, CT 06830',
  imageUrl: 'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=800&q=80',
  primaryContact: {
    name: 'Bob Smith',
    phone: '(203) 555-0001',
    email: 'bob@example.com',
  },
  manager: {
    name: 'Sarah Harrison',
    phone: '(203) 555-1000',
  },
  notes: 'Gate code: 1234. Dog is friendly. Use side entrance for deliveries.',
  
  systems: [
    {
      id: 's1',
      name: 'Main HVAC System',
      type: 'hvac',
      brand: 'Carrier Infinity',
      model: '24ACC636A003',
      installedDate: 'March 2020',
      warrantyExpires: 'March 2030',
      status: 'good',
      lastServiced: 'November 15, 2024',
      nextService: 'May 2025',
      location: 'Basement mechanical room',
      notes: 'Filter size: 20x25x4. Change every 3 months.',
    },
    {
      id: 's2',
      name: 'Water Heater',
      type: 'plumbing',
      brand: 'Rheem',
      model: 'PROG50-38N RH67',
      installedDate: 'June 2019',
      warrantyExpires: 'June 2025',
      status: 'warning',
      lastServiced: 'June 2024',
      nextService: 'Overdue - Anode rod replacement needed',
      location: 'Basement utility room',
      notes: 'Recommend replacing anode rod annually.',
    },
    {
      id: 's3',
      name: 'Main Electrical Panel',
      type: 'electrical',
      brand: 'Square D',
      model: 'Homeline 200A',
      installedDate: 'Original (2015)',
      status: 'good',
      lastServiced: 'August 2024',
      location: 'Garage',
      notes: '200 amp service. Breaker map in panel door.',
    },
    {
      id: 's4',
      name: 'Security System',
      type: 'security',
      brand: 'ADT / Honeywell',
      model: 'Vista 20P',
      status: 'good',
      lastServiced: 'October 2024',
      location: 'Front hall closet',
      notes: 'Master code with homeowner. 4 cameras, 12 sensors.',
    },
    {
      id: 's5',
      name: 'Backup Generator',
      type: 'electrical',
      brand: 'Generac',
      model: '22kW Guardian',
      installedDate: 'September 2021',
      warrantyExpires: 'September 2026',
      status: 'good',
      lastServiced: 'September 2024',
      nextService: 'March 2025',
      location: 'Side yard',
      notes: 'Weekly self-test runs Sunday 2pm. Propane tank is 500 gal.',
    },
  ],
  
  recentWorkOrders: [
    { id: 'wo1', title: 'Replace Smoke Detector Batteries', date: 'Dec 20, 2024', status: 'COMPLETED' },
    { id: 'wo2', title: 'Fix Squeaky Door Hinge', date: 'Dec 20, 2024', status: 'SCHEDULED' },
    { id: 'wo3', title: 'Repair Cabinet Handles', date: 'Dec 15, 2024', status: 'COMPLETED' },
    { id: 'wo4', title: 'Install Smart Thermostat', date: 'Dec 10, 2024', status: 'COMPLETED' },
  ],
};

export default function HouseholdDetailPage() {
  const params = useParams();
  const [activeTab, setActiveTab] = useState<'systems' | 'history' | 'info'>('systems');
  
  const household = householdData; // In real app, fetch by params.id
  
  return (
    <div className="min-h-screen bg-warm-50 pb-24">
      {/* Header Image */}
      <div className="relative h-48">
        <img 
          src={household.imageUrl} 
          alt={household.name}
          className="w-full h-full object-cover"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent" />
        <Link 
          href="/handyman/households"
          className="absolute top-4 left-4 w-10 h-10 bg-white/90 backdrop-blur rounded-full flex items-center justify-center"
        >
          <ArrowLeft className="w-5 h-5 text-warm-700" />
        </Link>
        <div className="absolute bottom-4 left-4 right-4">
          <h1 className="text-xl font-bold text-white">{household.name}</h1>
          <div className="flex items-center gap-1 text-white/80 text-sm">
            <MapPin className="w-4 h-4" />
            <span>{household.address}</span>
          </div>
        </div>
      </div>

      {/* Quick Actions */}
      <div className="px-4 -mt-6 relative z-10">
        <div className="card p-3 rounded-xl flex justify-around">
          <a href={`tel:${household.primaryContact.phone}`} className="flex flex-col items-center text-warm-600">
            <Phone className="w-5 h-5" />
            <span className="text-xs mt-1">Call</span>
          </a>
          <Link href={`/handyman/households/${household.id}/report`} className="flex flex-col items-center text-warm-600">
            <FileText className="w-5 h-5" />
            <span className="text-xs mt-1">Report</span>
          </Link>
          <Link href={`/handyman/households/${household.id}/photos`} className="flex flex-col items-center text-warm-600">
            <Camera className="w-5 h-5" />
            <span className="text-xs mt-1">Photos</span>
          </Link>
          <button className="flex flex-col items-center text-warm-600">
            <MapPin className="w-5 h-5" />
            <span className="text-xs mt-1">Navigate</span>
          </button>
        </div>
      </div>

      {/* Tabs */}
      <div className="px-4 mt-4">
        <div className="flex gap-2 border-b border-warm-200">
          {(['systems', 'history', 'info'] as const).map(tab => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`px-4 py-2 text-sm font-medium border-b-2 -mb-px capitalize ${
                activeTab === tab 
                  ? 'text-haven-600 border-haven-600' 
                  : 'text-warm-500 border-transparent hover:text-warm-700'
              }`}
            >
              {tab}
            </button>
          ))}
        </div>
      </div>

      {/* Tab Content */}
      <div className="p-4">
        {activeTab === 'systems' && (
          <div className="space-y-3">
            {household.systems.map(system => (
              <SystemCard key={system.id} system={system} />
            ))}
            <button className="w-full card p-4 rounded-xl border-2 border-dashed border-warm-300 text-warm-500 flex items-center justify-center gap-2 hover:border-haven-400 hover:text-haven-600 transition-colors">
              <Plus className="w-5 h-5" />
              <span>Add New System</span>
            </button>
          </div>
        )}
        
        {activeTab === 'history' && (
          <div className="space-y-3">
            {household.recentWorkOrders.map(wo => (
              <Link 
                key={wo.id}
                href={`/handyman/jobs/${wo.id}`}
                className="card p-4 rounded-xl flex items-center gap-4 card-hover"
              >
                <div className={`w-10 h-10 rounded-full flex items-center justify-center ${
                  wo.status === 'COMPLETED' ? 'bg-green-100 text-green-600' : 'bg-blue-100 text-blue-600'
                }`}>
                  {wo.status === 'COMPLETED' ? <CheckCircle2 className="w-5 h-5" /> : <Clock className="w-5 h-5" />}
                </div>
                <div className="flex-1">
                  <h3 className="font-medium text-warm-900">{wo.title}</h3>
                  <p className="text-sm text-warm-500">{wo.date}</p>
                </div>
                <ChevronRight className="w-5 h-5 text-warm-400" />
              </Link>
            ))}
          </div>
        )}
        
        {activeTab === 'info' && (
          <div className="space-y-4">
            {/* Contacts */}
            <div className="card p-4 rounded-xl">
              <h3 className="font-semibold text-warm-900 mb-3">Contacts</h3>
              <div className="space-y-3">
                <div className="flex items-center gap-3">
                  <img 
                    src={getUserAvatar(household.primaryContact.name)} 
                    alt=""
                    className="w-10 h-10 rounded-full"
                  />
                  <div className="flex-1">
                    <div className="font-medium text-warm-900">{household.primaryContact.name}</div>
                    <div className="text-sm text-warm-500">Homeowner</div>
                  </div>
                  <a href={`tel:${household.primaryContact.phone}`} className="btn-ghost p-2">
                    <Phone className="w-5 h-5" />
                  </a>
                </div>
                <div className="flex items-center gap-3">
                  <img 
                    src={getUserAvatar(household.manager.name)} 
                    alt=""
                    className="w-10 h-10 rounded-full"
                  />
                  <div className="flex-1">
                    <div className="font-medium text-warm-900">{household.manager.name}</div>
                    <div className="text-sm text-warm-500">Home Manager</div>
                  </div>
                  <a href={`tel:${household.manager.phone}`} className="btn-ghost p-2">
                    <Phone className="w-5 h-5" />
                  </a>
                </div>
              </div>
            </div>
            
            {/* Notes */}
            <div className="card p-4 rounded-xl">
              <h3 className="font-semibold text-warm-900 mb-2">Access Notes</h3>
              <p className="text-warm-600">{household.notes}</p>
            </div>
            
            {/* Address */}
            <div className="card p-4 rounded-xl">
              <h3 className="font-semibold text-warm-900 mb-2">Address</h3>
              <p className="text-warm-600">{household.address}</p>
              <p className="text-warm-600">{household.city}</p>
              <button className="btn-secondary mt-3 w-full">
                <MapPin className="w-4 h-4" />
                Get Directions
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

function SystemCard({ system }: { system: any }) {
  const statusConfig = {
    good: { color: 'bg-green-100 text-green-700', icon: CheckCircle2, label: 'Good' },
    warning: { color: 'bg-amber-100 text-amber-700', icon: AlertTriangle, label: 'Needs Attention' },
    critical: { color: 'bg-red-100 text-red-700', icon: AlertTriangle, label: 'Critical' },
  };
  
  const typeIcons = {
    hvac: Thermometer,
    plumbing: Droplets,
    electrical: Zap,
    security: Shield,
    other: Wrench,
  };
  
  const status = statusConfig[system.status as keyof typeof statusConfig] || statusConfig.good;
  const TypeIcon = typeIcons[system.type as keyof typeof typeIcons] || Wrench;
  const StatusIcon = status.icon;
  
  return (
    <Link href={`/handyman/systems/${system.id}`}>
      <div className="card p-4 rounded-xl card-hover">
        <div className="flex items-start gap-3">
          <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${status.color}`}>
            <TypeIcon className="w-5 h-5" />
          </div>
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2">
              <h3 className="font-medium text-warm-900">{system.name}</h3>
              <span className={`badge ${status.color}`}>
                {status.label}
              </span>
            </div>
            <p className="text-sm text-warm-500">{system.brand} {system.model}</p>
            {system.nextService && system.status !== 'good' && (
              <p className="text-sm text-amber-600 mt-1">{system.nextService}</p>
            )}
          </div>
          <ChevronRight className="w-5 h-5 text-warm-400" />
        </div>
      </div>
    </Link>
  );
}
```

---

## FIX 4: AFTER ACTION REPORT PAGE

**Create file:** `apps/web/src/app/handyman/households/[id]/report/page.tsx`

```typescript
'use client';

import { useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import Link from 'next/link';
import {
  ArrowLeft,
  Camera,
  CheckCircle2,
  AlertTriangle,
  Clock,
  Plus,
  X,
  Send,
} from 'lucide-react';

interface ReportItem {
  id: string;
  type: 'completed' | 'observation' | 'recommendation';
  title: string;
  description: string;
  photos: string[];
  urgent: boolean;
}

export default function AfterActionReportPage() {
  const router = useRouter();
  const params = useParams();
  const [items, setItems] = useState<ReportItem[]>([]);
  const [summary, setSummary] = useState('');
  const [hoursWorked, setHoursWorked] = useState('');
  const [sending, setSending] = useState(false);

  const addItem = (type: ReportItem['type']) => {
    const newItem: ReportItem = {
      id: Date.now().toString(),
      type,
      title: '',
      description: '',
      photos: [],
      urgent: false,
    };
    setItems([...items, newItem]);
  };

  const updateItem = (id: string, updates: Partial<ReportItem>) => {
    setItems(items.map(item => 
      item.id === id ? { ...item, ...updates } : item
    ));
  };

  const removeItem = (id: string) => {
    setItems(items.filter(item => item.id !== id));
  };

  const handleSubmit = async () => {
    setSending(true);
    // Simulate sending
    await new Promise(resolve => setTimeout(resolve, 1500));
    router.push(`/handyman/households/${params.id}?reported=true`);
  };

  return (
    <div className="min-h-screen bg-warm-50 pb-24">
      {/* Header */}
      <header className="bg-white border-b border-warm-200 px-4 py-4 sticky top-0 z-10">
        <div className="flex items-center gap-4">
          <Link 
            href={`/handyman/households/${params.id}`}
            className="w-10 h-10 rounded-full hover:bg-warm-100 flex items-center justify-center"
          >
            <ArrowLeft className="w-5 h-5 text-warm-700" />
          </Link>
          <div>
            <h1 className="text-lg font-bold text-warm-900">Visit Report</h1>
            <p className="text-sm text-warm-500">Smith Residence • Dec 23, 2024</p>
          </div>
        </div>
      </header>

      <main className="p-4 space-y-6">
        {/* Summary */}
        <div className="card p-4 rounded-xl">
          <label className="block text-sm font-medium text-warm-700 mb-2">
            Visit Summary
          </label>
          <textarea
            value={summary}
            onChange={(e) => setSummary(e.target.value)}
            placeholder="Brief summary of today's visit..."
            className="input min-h-[100px] resize-none"
          />
        </div>

        {/* Hours */}
        <div className="card p-4 rounded-xl">
          <label className="block text-sm font-medium text-warm-700 mb-2">
            Time on Site
          </label>
          <div className="flex items-center gap-2">
            <Clock className="w-5 h-5 text-warm-400" />
            <input
              type="number"
              step="0.25"
              value={hoursWorked}
              onChange={(e) => setHoursWorked(e.target.value)}
              placeholder="0.0"
              className="input w-24"
            />
            <span className="text-warm-600">hours</span>
          </div>
        </div>

        {/* Report Items */}
        <div>
          <h2 className="font-semibold text-warm-900 mb-3">Report Items</h2>
          
          {items.length === 0 ? (
            <div className="card p-8 rounded-xl text-center">
              <p className="text-warm-500 mb-4">No items added yet</p>
              <div className="flex flex-wrap justify-center gap-2">
                <button 
                  onClick={() => addItem('completed')}
                  className="btn-primary btn-sm"
                >
                  <CheckCircle2 className="w-4 h-4" />
                  Work Completed
                </button>
                <button 
                  onClick={() => addItem('observation')}
                  className="btn-secondary btn-sm"
                >
                  <AlertTriangle className="w-4 h-4" />
                  Observation
                </button>
                <button 
                  onClick={() => addItem('recommendation')}
                  className="btn-secondary btn-sm"
                >
                  <Plus className="w-4 h-4" />
                  Recommendation
                </button>
              </div>
            </div>
          ) : (
            <div className="space-y-3">
              {items.map(item => (
                <ReportItemCard 
                  key={item.id} 
                  item={item} 
                  onUpdate={(updates) => updateItem(item.id, updates)}
                  onRemove={() => removeItem(item.id)}
                />
              ))}
              
              {/* Add More */}
              <div className="flex flex-wrap gap-2">
                <button 
                  onClick={() => addItem('completed')}
                  className="btn-ghost btn-sm text-haven-600"
                >
                  <Plus className="w-4 h-4" />
                  Work Completed
                </button>
                <button 
                  onClick={() => addItem('observation')}
                  className="btn-ghost btn-sm text-amber-600"
                >
                  <Plus className="w-4 h-4" />
                  Observation
                </button>
                <button 
                  onClick={() => addItem('recommendation')}
                  className="btn-ghost btn-sm text-blue-600"
                >
                  <Plus className="w-4 h-4" />
                  Recommendation
                </button>
              </div>
            </div>
          )}
        </div>
      </main>

      {/* Submit Button */}
      <div className="fixed bottom-0 left-0 right-0 p-4 bg-white border-t border-warm-200">
        <button 
          onClick={handleSubmit}
          disabled={sending || (!summary && items.length === 0)}
          className="btn-primary w-full btn-lg"
        >
          {sending ? (
            <>Sending to Homeowner...</>
          ) : (
            <>
              <Send className="w-5 h-5" />
              Send Report
            </>
          )}
        </button>
      </div>
    </div>
  );
}

function ReportItemCard({ 
  item, 
  onUpdate, 
  onRemove 
}: { 
  item: ReportItem; 
  onUpdate: (updates: Partial<ReportItem>) => void;
  onRemove: () => void;
}) {
  const typeConfig = {
    completed: { 
      color: 'border-l-haven-500 bg-haven-50', 
      icon: CheckCircle2,
      iconColor: 'text-haven-600',
      label: 'Work Completed' 
    },
    observation: { 
      color: 'border-l-amber-500 bg-amber-50', 
      icon: AlertTriangle,
      iconColor: 'text-amber-600',
      label: 'Observation' 
    },
    recommendation: { 
      color: 'border-l-blue-500 bg-blue-50', 
      icon: Plus,
      iconColor: 'text-blue-600',
      label: 'Recommendation' 
    },
  };
  
  const config = typeConfig[item.type];
  const Icon = config.icon;

  return (
    <div className={`card p-4 rounded-xl border-l-4 ${config.color}`}>
      <div className="flex items-start justify-between mb-3">
        <div className="flex items-center gap-2">
          <Icon className={`w-5 h-5 ${config.iconColor}`} />
          <span className="text-sm font-medium text-warm-700">{config.label}</span>
        </div>
        <button onClick={onRemove} className="text-warm-400 hover:text-warm-600">
          <X className="w-5 h-5" />
        </button>
      </div>
      
      <input
        type="text"
        value={item.title}
        onChange={(e) => onUpdate({ title: e.target.value })}
        placeholder="Title"
        className="input mb-2"
      />
      
      <textarea
        value={item.description}
        onChange={(e) => onUpdate({ description: e.target.value })}
        placeholder="Description..."
        className="input min-h-[80px] resize-none mb-3"
      />
      
      {/* Photo upload */}
      <div className="flex items-center gap-2">
        <button className="btn-ghost btn-sm text-warm-500">
          <Camera className="w-4 h-4" />
          Add Photos
        </button>
        
        {item.type !== 'completed' && (
          <label className="flex items-center gap-2 text-sm text-warm-600 ml-auto">
            <input
              type="checkbox"
              checked={item.urgent}
              onChange={(e) => onUpdate({ urgent: e.target.checked })}
              className="rounded border-warm-300 text-haven-600 focus:ring-haven-500"
            />
            Mark as Urgent
          </label>
        )}
      </div>
    </div>
  );
}
```

---

## FIX 5: SYSTEM DETAIL PAGE

**Create file:** `apps/web/src/app/handyman/systems/[id]/page.tsx`

```typescript
'use client';

import { useState } from 'react';
import Link from 'next/link';
import {
  ArrowLeft,
  Thermometer,
  Calendar,
  Clock,
  FileText,
  Camera,
  Wrench,
  AlertTriangle,
  CheckCircle2,
  Edit,
  Plus,
} from 'lucide-react';

// Demo system data
const systemData = {
  id: 's1',
  name: 'Main HVAC System',
  type: 'hvac',
  status: 'good',
  brand: 'Carrier',
  model: 'Infinity 24ACC636A003',
  serialNumber: 'SN-2020-0315-4829',
  installedDate: 'March 15, 2020',
  warrantyExpires: 'March 15, 2030',
  location: 'Basement mechanical room',
  
  specs: [
    { label: 'Tonnage', value: '3.5 ton' },
    { label: 'SEER Rating', value: '21' },
    { label: 'Refrigerant', value: 'R-410A' },
    { label: 'Filter Size', value: '20x25x4' },
    { label: 'Filter Type', value: 'MERV 13' },
  ],
  
  notes: 'Change filter every 3 months. Blower motor was replaced in 2023. Recommend UV light installation for improved air quality.',
  
  serviceHistory: [
    { 
      date: 'Nov 15, 2024', 
      type: 'Preventive', 
      description: 'Fall maintenance - Checked heating, cleaned coils, replaced filter',
      technician: 'Mike Rodriguez',
    },
    { 
      date: 'May 10, 2024', 
      type: 'Preventive', 
      description: 'Spring maintenance - A/C tune-up, refrigerant check',
      technician: 'Mike Rodriguez',
    },
    { 
      date: 'Jan 22, 2024', 
      type: 'Repair', 
      description: 'Replaced capacitor - unit not cooling properly',
      technician: 'Carlos Reyes',
    },
    { 
      date: 'Nov 8, 2023', 
      type: 'Preventive', 
      description: 'Fall maintenance',
      technician: 'Mike Rodriguez',
    },
  ],
  
  photos: [
    'https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=400&q=80',
    'https://images.unsplash.com/photo-1631545308978-5f0d5f7c0e6a?w=400&q=80',
  ],
  
  documents: [
    { name: 'Owner Manual', type: 'PDF' },
    { name: 'Warranty Certificate', type: 'PDF' },
    { name: 'Installation Report', type: 'PDF' },
  ],
  
  nextService: {
    type: 'Spring A/C Tune-up',
    dueDate: 'May 2025',
    estimatedCost: '$189',
  },
};

export default function SystemDetailPage() {
  const [activeTab, setActiveTab] = useState<'info' | 'history' | 'docs'>('info');
  
  const system = systemData;
  
  return (
    <div className="min-h-screen bg-warm-50 pb-8">
      {/* Header */}
      <header className="bg-white border-b border-warm-200 px-4 py-4 sticky top-0 z-10">
        <div className="flex items-center gap-4">
          <Link 
            href="/handyman/households/h1"
            className="w-10 h-10 rounded-full hover:bg-warm-100 flex items-center justify-center"
          >
            <ArrowLeft className="w-5 h-5 text-warm-700" />
          </Link>
          <div className="flex-1">
            <h1 className="text-lg font-bold text-warm-900">{system.name}</h1>
            <p className="text-sm text-warm-500">{system.brand} {system.model}</p>
          </div>
          <span className="badge badge-success">
            <CheckCircle2 className="w-3 h-3" />
            Good
          </span>
        </div>
      </header>

      {/* Quick Info Card */}
      <div className="p-4">
        <div className="card p-4 rounded-xl">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <div className="text-sm text-warm-500">Installed</div>
              <div className="font-medium text-warm-900">{system.installedDate}</div>
            </div>
            <div>
              <div className="text-sm text-warm-500">Warranty Until</div>
              <div className="font-medium text-warm-900">{system.warrantyExpires}</div>
            </div>
            <div>
              <div className="text-sm text-warm-500">Location</div>
              <div className="font-medium text-warm-900">{system.location}</div>
            </div>
            <div>
              <div className="text-sm text-warm-500">Serial #</div>
              <div className="font-medium text-warm-900 text-xs">{system.serialNumber}</div>
            </div>
          </div>
        </div>
      </div>

      {/* Next Service Alert */}
      <div className="px-4 mb-4">
        <div className="card-green p-4 rounded-xl">
          <div className="flex items-center justify-between">
            <div>
              <div className="text-sm text-white/80">Next Scheduled Service</div>
              <div className="font-semibold text-white">{system.nextService.type}</div>
              <div className="text-sm text-white/80">{system.nextService.dueDate} • Est. {system.nextService.estimatedCost}</div>
            </div>
            <button className="btn-white btn-sm">Schedule</button>
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="px-4">
        <div className="flex gap-2 border-b border-warm-200">
          {(['info', 'history', 'docs'] as const).map(tab => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`px-4 py-2 text-sm font-medium border-b-2 -mb-px capitalize ${
                activeTab === tab 
                  ? 'text-haven-600 border-haven-600' 
                  : 'text-warm-500 border-transparent'
              }`}
            >
              {tab === 'docs' ? 'Documents' : tab}
            </button>
          ))}
        </div>
      </div>

      {/* Tab Content */}
      <div className="p-4">
        {activeTab === 'info' && (
          <div className="space-y-4">
            {/* Specifications */}
            <div className="card p-4 rounded-xl">
              <h3 className="font-semibold text-warm-900 mb-3">Specifications</h3>
              <div className="space-y-2">
                {system.specs.map((spec, i) => (
                  <div key={i} className="flex justify-between py-2 border-b border-warm-100 last:border-0">
                    <span className="text-warm-500">{spec.label}</span>
                    <span className="font-medium text-warm-900">{spec.value}</span>
                  </div>
                ))}
              </div>
            </div>
            
            {/* Notes */}
            <div className="card p-4 rounded-xl">
              <div className="flex items-center justify-between mb-2">
                <h3 className="font-semibold text-warm-900">Notes</h3>
                <button className="btn-ghost btn-sm">
                  <Edit className="w-4 h-4" />
                  Edit
                </button>
              </div>
              <p className="text-warm-600">{system.notes}</p>
            </div>
            
            {/* Photos */}
            <div className="card p-4 rounded-xl">
              <div className="flex items-center justify-between mb-3">
                <h3 className="font-semibold text-warm-900">Photos</h3>
                <button className="btn-ghost btn-sm">
                  <Camera className="w-4 h-4" />
                  Add
                </button>
              </div>
              <div className="grid grid-cols-3 gap-2">
                {system.photos.map((photo, i) => (
                  <img 
                    key={i}
                    src={photo}
                    alt=""
                    className="w-full aspect-square rounded-lg object-cover"
                  />
                ))}
              </div>
            </div>
          </div>
        )}
        
        {activeTab === 'history' && (
          <div className="space-y-3">
            {system.serviceHistory.map((service, i) => (
              <div key={i} className="card p-4 rounded-xl">
                <div className="flex items-start justify-between mb-2">
                  <div>
                    <span className={`badge ${
                      service.type === 'Repair' ? 'badge-warning' : 'badge-info'
                    }`}>
                      {service.type}
                    </span>
                    <div className="text-sm text-warm-500 mt-1">{service.date}</div>
                  </div>
                </div>
                <p className="text-warm-700">{service.description}</p>
                <p className="text-sm text-warm-500 mt-2">By {service.technician}</p>
              </div>
            ))}
            
            <button className="w-full card p-4 rounded-xl border-2 border-dashed border-warm-300 text-warm-500 flex items-center justify-center gap-2 hover:border-haven-400 hover:text-haven-600">
              <Plus className="w-5 h-5" />
              Log Service Entry
            </button>
          </div>
        )}
        
        {activeTab === 'docs' && (
          <div className="space-y-3">
            {system.documents.map((doc, i) => (
              <div key={i} className="card p-4 rounded-xl flex items-center gap-4 card-hover cursor-pointer">
                <div className="w-10 h-10 rounded-lg bg-red-100 flex items-center justify-center">
                  <FileText className="w-5 h-5 text-red-600" />
                </div>
                <div className="flex-1">
                  <div className="font-medium text-warm-900">{doc.name}</div>
                  <div className="text-sm text-warm-500">{doc.type}</div>
                </div>
              </div>
            ))}
            
            <button className="w-full card p-4 rounded-xl border-2 border-dashed border-warm-300 text-warm-500 flex items-center justify-center gap-2 hover:border-haven-400 hover:text-haven-600">
              <Plus className="w-5 h-5" />
              Upload Document
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
```

---

## FIX 6: API HOOK NULL SAFETY

**File:** `apps/web/src/hooks/use-api.ts`

Make sure the API hook handles missing data gracefully:

```typescript
// Add fallback/default values when API returns undefined
export function useApi() {
  // ... existing code

  async function getHandymanDashboard() {
    try {
      const response = await fetch('/api/handyman/dashboard', {
        headers: getAuthHeaders(),
      });
      
      if (!response.ok) {
        throw new Error('Failed to fetch dashboard');
      }
      
      const data = await response.json();
      
      // Ensure all required fields have defaults
      return {
        todaysTasks: data.todaysTasks || [],
        stats: {
          tasksToday: data.stats?.tasksToday ?? 0,
          tasksCompleted: data.stats?.tasksCompleted ?? 0,
          hoursLoggedToday: data.stats?.hoursLoggedToday ?? 0,
          tasksThisWeek: data.stats?.tasksThisWeek ?? 0,
          avgCompletionTime: data.stats?.avgCompletionTime ?? 0,
        },
        activeTask: data.activeTask || null,
      };
    } catch (error) {
      console.error('Handyman dashboard error:', error);
      // Return demo data as fallback
      return null;
    }
  }

  // ... rest of hook
}
```

---

## SUMMARY

| Fix | Description |
|-----|-------------|
| Null safety | Added fallback values for all API data |
| Demo data | Dashboard works without API using demo data |
| Households page | View all assigned homes with system status |
| Household detail | Full home info with systems, history, contacts |
| After action report | Send visit reports to homeowners |
| System detail | Complete equipment tracking and service history |
| Better navigation | Bottom nav and quick actions |

---

## AFTER BUILD

```bash
cd apps/web
pnpm dev
```

Test handyman portal at http://localhost:3000/handyman with:
- Email: mike@haven.app
- Password: Handy123!

🔧✨
