'use client';

import { useState, useEffect, useMemo, useRef, useCallback } from 'react';
import Link from 'next/link';
import {
  ChevronLeft,
  ChevronRight,
  Plus,
  Calendar as CalendarIcon,
  List,
  LayoutGrid,
  Clock,
  MapPin,
  Users,
  Home,
  Wrench,
  Truck,
  Plane,
  GraduationCap,
  PartyPopper,
  Sun,
  Cloud,
  CloudRain,
  Snowflake,
  X,
  AlertTriangle,
  Repeat,
  Filter,
  Sparkles,
  Bell,
  CheckCircle2,
  Link2,
  RefreshCw,
  UserCheck,
  Info,
  AlertCircle,
  ExternalLink,
  Shield,
  Copy,
  Check,
} from 'lucide-react';
import { getDemoImage } from '@/lib/imageUtils';

// ============================================================================
// TYPES
// ============================================================================

type ViewMode = 'month' | 'week' | 'agenda';
type EventLayer = 'house' | 'family';
type EventCategory = 'service' | 'delivery' | 'family' | 'kids' | 'travel' | 'social' | 'health';
type FilterType = 'all' | 'house' | 'family' | 'kids' | 'travel';
type EventCreatorRole = 'HOMEOWNER' | 'MANAGER' | 'SYSTEM' | 'SYNCED';
type SyncSource = 'GOOGLE' | 'APPLE' | 'OUTLOOK' | 'MANUAL';

interface CalendarEvent {
  id: string;
  title: string;
  startDate: Date;
  endDate?: Date;
  startTime?: string;
  endTime?: string;
  layer: EventLayer;
  category: EventCategory;
  location?: string;
  description?: string;
  isAllDay?: boolean;
  isRecurring?: boolean;
  recurrence?: 'weekly' | 'biweekly' | 'monthly';
  attendees?: string[];
  color?: string;
  icon?: string;
  requiresAccess?: boolean;
  conflict?: boolean;
  // New manager-related fields
  createdByRole?: EventCreatorRole;
  createdByName?: string;
  managerNote?: string;
  requiresAction?: boolean;
  actionDescription?: string;
  reminderText?: string;
  conflictReason?: string;
  syncSource?: SyncSource;
}

interface FamilyMember {
  id: string;
  name: string;
  avatar: string;
  role: 'parent' | 'child' | 'caregiver';
}

interface DayWeather {
  date: Date;
  icon: 'sun' | 'cloud' | 'rain' | 'snow';
  temp: number;
}

interface SmartReminder {
  id: string;
  eventId: string;
  message: string;
  date: Date;
  type: 'snack_duty' | 'permission_slip' | 'anniversary' | 'custom';
  isAcknowledged: boolean;
}

interface DayAttention {
  date: string;
  issues: string[];
  severity: 'warning' | 'critical';
}

// ============================================================================
// MOCK DATA GENERATION
// ============================================================================

const mockFamilyMembers: FamilyMember[] = [
  { id: 'fm1', name: 'Bob', avatar: getDemoImage('avatar-male', 80, 80, 'bob'), role: 'parent' },
  { id: 'fm2', name: 'Alice', avatar: getDemoImage('avatar-female', 80, 80, 'alice'), role: 'parent' },
  { id: 'fm3', name: 'Emma', avatar: getDemoImage('avatar-kid', 80, 80, 'emma'), role: 'child' },
  { id: 'fm4', name: 'Jake', avatar: getDemoImage('avatar-kid', 80, 80, 'jake'), role: 'child' },
];

// Manager name for demo
const MANAGER_NAME = 'Sarah';

// Generate dates relative to today
const today = new Date();
const getDate = (daysOffset: number, hour = 9, minute = 0) => {
  const date = new Date(today);
  date.setDate(date.getDate() + daysOffset);
  date.setHours(hour, minute, 0, 0);
  return date;
};

// Generate comprehensive mock events for -30 to +30 days
function generateMockEvents(): CalendarEvent[] {
  const events: CalendarEvent[] = [];
  let eventId = 1;

  // Helper to get day of week (0 = Sunday, 6 = Saturday)
  const getDayOfWeek = (daysOffset: number) => {
    const d = new Date(today);
    d.setDate(d.getDate() + daysOffset);
    return d.getDay();
  };

  // Generate events for -30 to +30 days
  for (let day = -30; day <= 30; day++) {
    const dayOfWeek = getDayOfWeek(day);

    // ========== RECURRING FAMILY EVENTS ==========

    // Soccer Practice - Tuesday & Thursday 4pm (Emma)
    if (dayOfWeek === 2 || dayOfWeek === 4) {
      events.push({
        id: `e${eventId++}`,
        title: "Emma's Soccer Practice",
        startDate: getDate(day, 16, 0),
        endDate: getDate(day, 17, 30),
        startTime: '16:00',
        endTime: '17:30',
        layer: 'family',
        category: 'kids',
        location: 'Oak Park Soccer Fields',
        isRecurring: true,
        recurrence: 'weekly',
        attendees: ['Emma', 'Bob'],
        createdByRole: 'SYSTEM',
        syncSource: 'MANUAL',
      });
    }

    // Piano Lesson - Wednesday 5pm (Jake)
    if (dayOfWeek === 3) {
      events.push({
        id: `e${eventId++}`,
        title: "Jake's Piano Lesson",
        startDate: getDate(day, 17, 0),
        endDate: getDate(day, 18, 0),
        startTime: '17:00',
        endTime: '18:00',
        layer: 'family',
        category: 'kids',
        location: 'Music Academy',
        isRecurring: true,
        recurrence: 'weekly',
        attendees: ['Jake', 'Alice'],
        createdByRole: 'SYSTEM',
        syncSource: 'MANUAL',
      });
    }

    // ========== RECURRING HOUSE EVENTS ==========

    // Trash Pickup - Friday 7am
    if (dayOfWeek === 5) {
      events.push({
        id: `e${eventId++}`,
        title: 'Trash & Recycling Pickup',
        startDate: getDate(day, 7, 0),
        endDate: getDate(day, 8, 0),
        startTime: '07:00',
        endTime: '08:00',
        layer: 'house',
        category: 'service',
        description: 'Put bins out the night before',
        isRecurring: true,
        recurrence: 'weekly',
        createdByRole: 'SYSTEM',
      });
    }

    // Landscaping - Tuesday 9am
    if (dayOfWeek === 2) {
      events.push({
        id: `e${eventId++}`,
        title: 'Landscaping Service',
        startDate: getDate(day, 9, 0),
        endDate: getDate(day, 11, 0),
        startTime: '09:00',
        endTime: '11:00',
        layer: 'house',
        category: 'service',
        location: 'Front & Back Yard',
        description: 'Weekly lawn maintenance and hedge trimming',
        isRecurring: true,
        recurrence: 'weekly',
        requiresAccess: true,
        createdByRole: 'MANAGER',
        createdByName: MANAGER_NAME,
        managerNote: 'Set up by Sarah - they have gate code',
      });
    }

    // Pool Service - Thursday 10am
    if (dayOfWeek === 4) {
      events.push({
        id: `e${eventId++}`,
        title: 'Pool Service',
        startDate: getDate(day, 10, 0),
        endDate: getDate(day, 11, 0),
        startTime: '10:00',
        endTime: '11:00',
        layer: 'house',
        category: 'service',
        location: 'Backyard Pool',
        isRecurring: true,
        recurrence: 'weekly',
        createdByRole: 'MANAGER',
        createdByName: MANAGER_NAME,
      });
    }

    // Housekeeping - Every other Monday
    if (dayOfWeek === 1 && Math.floor((day + 30) / 7) % 2 === 0) {
      events.push({
        id: `e${eventId++}`,
        title: 'Housekeeping',
        startDate: getDate(day, 9, 0),
        endDate: getDate(day, 13, 0),
        startTime: '09:00',
        endTime: '13:00',
        layer: 'house',
        category: 'service',
        isRecurring: true,
        recurrence: 'biweekly',
        requiresAccess: true,
        createdByRole: 'MANAGER',
        createdByName: MANAGER_NAME,
        managerNote: 'Maria comes every other Monday. Key under mat.',
      });
    }
  }

  // ========== MANAGER-ADDED ONE-TIME EVENTS ==========

  // Gutter Cleaning - Next week (Manager scheduled)
  events.push({
    id: `e${eventId++}`,
    title: 'Gutter Cleaning',
    startDate: getDate(6, 8, 0),
    endDate: getDate(6, 11, 0),
    startTime: '08:00',
    endTime: '11:00',
    layer: 'house',
    category: 'service',
    description: 'Seasonal gutter cleaning and inspection',
    requiresAccess: true,
    createdByRole: 'MANAGER',
    createdByName: MANAGER_NAME,
    managerNote: 'I found CleanPro - great reviews, $150. They need backyard access.',
    requiresAction: true,
    actionDescription: 'Confirm access code',
  });

  // Pest Control - Conflict detected
  events.push({
    id: `e${eventId++}`,
    title: 'Pest Control Service',
    startDate: getDate(10, 10, 0),
    endDate: getDate(10, 11, 0),
    startTime: '10:00',
    endTime: '11:00',
    layer: 'house',
    category: 'service',
    description: 'Quarterly pest inspection - interior access needed',
    requiresAccess: true,
    conflict: true,
    conflictReason: "You'll be at Jake's Science Fair",
    createdByRole: 'MANAGER',
    createdByName: MANAGER_NAME,
    managerNote: 'Quarterly service - I can reschedule if this time doesn\'t work.',
  });

  // HVAC Maintenance - Manager coordinated
  events.push({
    id: `e${eventId++}`,
    title: 'HVAC Annual Tune-Up',
    startDate: getDate(8, 9, 0),
    endDate: getDate(8, 12, 0),
    startTime: '09:00',
    endTime: '12:00',
    layer: 'house',
    category: 'service',
    description: 'Annual AC and heating system inspection',
    requiresAccess: true,
    createdByRole: 'MANAGER',
    createdByName: MANAGER_NAME,
    managerNote: 'Scheduled with your preferred vendor - TempMasters. $180 for full inspection.',
  });

  // ========== SOCIAL EVENTS ==========

  // Dinner with Millers - This Friday
  const fridayOffset = (5 - today.getDay() + 7) % 7 || 7;
  events.push({
    id: `e${eventId++}`,
    title: 'Dinner with the Millers',
    startDate: getDate(fridayOffset, 19, 0),
    endDate: getDate(fridayOffset, 22, 0),
    startTime: '19:00',
    endTime: '22:00',
    layer: 'family',
    category: 'social',
    location: "Miller's House - 1234 Oak Lane",
    description: 'Monthly dinner club gathering',
    attendees: ['Bob', 'Alice'],
    createdByRole: 'HOMEOWNER',
  });

  // Anniversary Dinner - Manager booked reservation
  events.push({
    id: `e${eventId++}`,
    title: 'Anniversary Dinner',
    startDate: getDate(13, 19, 0),
    endDate: getDate(13, 22, 0),
    startTime: '19:00',
    endTime: '22:00',
    layer: 'family',
    category: 'social',
    location: 'La Maison - Private Room',
    attendees: ['Bob', 'Alice'],
    createdByRole: 'MANAGER',
    createdByName: MANAGER_NAME,
    managerNote: 'Booked the private room you love! Confirmation #LM2024-1203. Babysitter scheduled 6:30-11pm.',
    reminderText: "Don't forget: your anniversary dinner is Friday!",
  });

  // Neighborhood BBQ - Manager found it
  events.push({
    id: `e${eventId++}`,
    title: 'Neighborhood Block Party',
    startDate: getDate(14, 15, 0),
    endDate: getDate(14, 20, 0),
    startTime: '15:00',
    endTime: '20:00',
    layer: 'family',
    category: 'social',
    location: 'Johnson Backyard',
    description: 'Annual summer block party',
    attendees: ['Bob', 'Alice', 'Emma', 'Jake'],
    createdByRole: 'MANAGER',
    createdByName: MANAGER_NAME,
    managerNote: 'Saw this on the neighborhood board - added it for you!',
  });

  // ========== KIDS EVENTS ==========

  // Jake's Science Fair
  events.push({
    id: `e${eventId++}`,
    title: "Jake's Science Fair",
    startDate: getDate(4, 13, 0),
    endDate: getDate(4, 16, 0),
    startTime: '13:00',
    endTime: '16:00',
    layer: 'family',
    category: 'kids',
    location: 'Lincoln Elementary School',
    attendees: ['Jake', 'Alice', 'Bob'],
    createdByRole: 'MANAGER',
    createdByName: MANAGER_NAME,
    managerNote: 'Found this on the school calendar - added it for you!',
  });

  // Emma's Dance Recital
  events.push({
    id: `e${eventId++}`,
    title: "Emma's Dance Recital",
    startDate: getDate(12, 18, 0),
    endDate: getDate(12, 20, 0),
    startTime: '18:00',
    endTime: '20:00',
    layer: 'family',
    category: 'kids',
    location: 'Community Theater',
    attendees: ['Emma', 'Bob', 'Alice', 'Jake'],
    createdByRole: 'SYNCED',
    syncSource: 'GOOGLE',
  });

  // Soccer Snacks Reminder
  events.push({
    id: `e${eventId++}`,
    title: "Soccer Snacks - Your Turn!",
    startDate: getDate(7, 15, 30),
    endDate: getDate(7, 16, 0),
    startTime: '15:30',
    endTime: '16:00',
    layer: 'family',
    category: 'kids',
    location: 'Oak Park Soccer Fields',
    attendees: ['Emma'],
    createdByRole: 'MANAGER',
    createdByName: MANAGER_NAME,
    managerNote: "It's your turn to bring snacks for Emma's team! I suggest orange slices and juice boxes.",
    reminderText: "Emma's soccer snacks - your turn Dec 28",
  });

  // ========== HEALTH EVENTS ==========

  // Dentist - Kids
  events.push({
    id: `e${eventId++}`,
    title: 'Dentist - Kids',
    startDate: getDate(6, 10, 0),
    endDate: getDate(6, 11, 30),
    startTime: '10:00',
    endTime: '11:30',
    layer: 'family',
    category: 'health',
    location: 'Bright Smiles Dental',
    attendees: ['Emma', 'Jake', 'Alice'],
    createdByRole: 'MANAGER',
    createdByName: MANAGER_NAME,
    managerNote: 'Scheduled their 6-month checkups together. Dr. Lee is great with kids!',
  });

  // Permission Slip Reminder (System)
  events.push({
    id: `e${eventId++}`,
    title: "Jake's Field Trip Permission",
    startDate: getDate(2, 8, 0),
    endDate: getDate(2, 9, 0),
    startTime: '08:00',
    endTime: '09:00',
    layer: 'family',
    category: 'kids',
    description: 'Sign and return permission slip',
    attendees: ['Jake'],
    createdByRole: 'MANAGER',
    createdByName: MANAGER_NAME,
    reminderText: "Jake's permission slip due tomorrow",
    requiresAction: true,
    actionDescription: 'Sign permission slip',
  });

  // ========== TRAVEL EVENTS ==========

  // Family Vacation
  events.push({
    id: `e${eventId++}`,
    title: 'Family Vacation - Hawaii',
    startDate: getDate(21),
    endDate: getDate(28),
    layer: 'family',
    category: 'travel',
    location: 'Maui, Hawaii',
    isAllDay: true,
    attendees: ['Bob', 'Alice', 'Emma', 'Jake'],
    createdByRole: 'HOMEOWNER',
  });

  // ========== DELIVERY EVENTS ==========

  // Grocery Delivery - Today
  events.push({
    id: `e${eventId++}`,
    title: 'Amazon Fresh Delivery',
    startDate: getDate(0, 14, 0),
    endDate: getDate(0, 16, 0),
    startTime: '14:00',
    endTime: '16:00',
    layer: 'house',
    category: 'delivery',
    description: 'Weekly grocery delivery',
    isRecurring: true,
    recurrence: 'weekly',
    createdByRole: 'SYSTEM',
  });

  // Furniture Delivery
  events.push({
    id: `e${eventId++}`,
    title: 'New Sofa Delivery',
    startDate: getDate(3, 10, 0),
    endDate: getDate(3, 14, 0),
    startTime: '10:00',
    endTime: '14:00',
    layer: 'house',
    category: 'delivery',
    description: 'Living room sectional from West Elm',
    requiresAccess: true,
    createdByRole: 'MANAGER',
    createdByName: MANAGER_NAME,
    managerNote: 'Coordinated with West Elm - they need someone 18+ to sign.',
    requiresAction: true,
    actionDescription: 'Ensure someone is home to sign',
  });

  return events;
}

const mockEvents = generateMockEvents();

// Mock smart reminders
const mockSmartReminders: SmartReminder[] = [
  {
    id: 'r1',
    eventId: 'e50',
    message: "Emma's soccer snacks - your turn Dec 28",
    date: getDate(7),
    type: 'snack_duty',
    isAcknowledged: false,
  },
  {
    id: 'r2',
    eventId: 'e51',
    message: "Jake's permission slip due tomorrow",
    date: getDate(2),
    type: 'permission_slip',
    isAcknowledged: false,
  },
  {
    id: 'r3',
    eventId: 'e52',
    message: "Don't forget: your anniversary dinner is Friday!",
    date: getDate(12),
    type: 'anniversary',
    isAcknowledged: false,
  },
];

// Days that need attention
const mockDaysNeedingAttention: DayAttention[] = [
  { date: getDate(10).toISOString().split('T')[0]!, issues: ['Pest control conflicts with Science Fair'], severity: 'critical' },
  { date: getDate(6).toISOString().split('T')[0]!, issues: ['Confirm gutter cleaning access'], severity: 'warning' },
  { date: getDate(3).toISOString().split('T')[0]!, issues: ['Be home for sofa delivery'], severity: 'warning' },
  { date: getDate(2).toISOString().split('T')[0]!, issues: ['Sign permission slip'], severity: 'warning' },
];

// Mock weather data
const generateWeather = (): DayWeather[] => {
  const icons: DayWeather['icon'][] = ['sun', 'sun', 'cloud', 'sun', 'rain', 'cloud', 'sun', 'sun', 'cloud', 'rain', 'sun', 'sun', 'cloud', 'sun', 'sun', 'cloud', 'sun', 'rain', 'sun', 'sun', 'cloud'];
  const temps = [72, 75, 68, 70, 65, 71, 74, 76, 69, 64, 72, 73, 70, 75, 74, 68, 71, 66, 73, 77, 72];

  return Array.from({ length: 21 }, (_, i) => ({
    date: getDate(i - 7),
    icon: icons[i] ?? 'sun',
    temp: temps[i] ?? 70,
  }));
};

const mockWeather = generateWeather();

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

const formatTime = (time: string) => {
  const parts = time.split(':').map(Number);
  const hours = parts[0] ?? 0;
  const minutes = parts[1] ?? 0;
  const period = hours >= 12 ? 'PM' : 'AM';
  const displayHours = hours % 12 || 12;
  return `${displayHours}:${minutes.toString().padStart(2, '0')} ${period}`;
};

const formatDateShort = (date: Date) => {
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
};

const formatDateLong = (date: Date) => {
  return date.toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric' });
};

const isSameDay = (date1: Date, date2: Date) => {
  return (
    date1.getFullYear() === date2.getFullYear() &&
    date1.getMonth() === date2.getMonth() &&
    date1.getDate() === date2.getDate()
  );
};

const isToday = (date: Date) => isSameDay(date, new Date());

const getWeekDates = (baseDate: Date) => {
  const dates: Date[] = [];
  const startOfWeek = new Date(baseDate);
  startOfWeek.setDate(baseDate.getDate() - baseDate.getDay());

  for (let i = 0; i < 7; i++) {
    const date = new Date(startOfWeek);
    date.setDate(startOfWeek.getDate() + i);
    dates.push(date);
  }
  return dates;
};

const getMonthDates = (baseDate: Date) => {
  const year = baseDate.getFullYear();
  const month = baseDate.getMonth();
  const firstDay = new Date(year, month, 1);
  const lastDay = new Date(year, month + 1, 0);
  const startPadding = firstDay.getDay();
  const dates: (Date | null)[] = [];

  for (let i = 0; i < startPadding; i++) {
    dates.push(null);
  }

  for (let day = 1; day <= lastDay.getDate(); day++) {
    dates.push(new Date(year, month, day));
  }

  return dates;
};

const getCategoryIcon = (category: EventCategory) => {
  switch (category) {
    case 'service': return Wrench;
    case 'delivery': return Truck;
    case 'travel': return Plane;
    case 'kids': return GraduationCap;
    case 'social': return PartyPopper;
    case 'health': return Plus;
    default: return CalendarIcon;
  }
};

const getWeatherIcon = (icon: DayWeather['icon']) => {
  switch (icon) {
    case 'sun': return Sun;
    case 'cloud': return Cloud;
    case 'rain': return CloudRain;
    case 'snow': return Snowflake;
  }
};

const getEventColor = (event: CalendarEvent) => {
  if (event.layer === 'house') {
    return {
      bg: 'bg-emerald-50',
      border: 'border-emerald-500',
      text: 'text-emerald-700',
      icon: 'text-emerald-600',
    };
  }
  switch (event.category) {
    case 'travel':
      return { bg: 'bg-purple-50', border: 'border-purple-500', text: 'text-purple-700', icon: 'text-purple-600' };
    case 'kids':
      return { bg: 'bg-blue-50', border: 'border-blue-500', text: 'text-blue-700', icon: 'text-blue-600' };
    case 'social':
      return { bg: 'bg-pink-50', border: 'border-pink-500', text: 'text-pink-700', icon: 'text-pink-600' };
    case 'health':
      return { bg: 'bg-red-50', border: 'border-red-500', text: 'text-red-700', icon: 'text-red-600' };
    default:
      return { bg: 'bg-warm-50', border: 'border-warm-400', text: 'text-warm-700', icon: 'text-warm-600' };
  }
};

const getSyncSourceIcon = (source: SyncSource) => {
  switch (source) {
    case 'GOOGLE': return '🔵';
    case 'APPLE': return '🍎';
    case 'OUTLOOK': return '📧';
    default: return null;
  }
};

// ============================================================================
// COMPONENTS
// ============================================================================

// Manager Badge
function ManagerBadge({ name, small = false }: { name: string; small?: boolean }) {
  if (small) {
    return (
      <span className="inline-flex items-center gap-1 px-1.5 py-0.5 bg-amber-100 text-amber-700 rounded text-[10px] font-medium">
        <UserCheck className="w-2.5 h-2.5" />
        {name}
      </span>
    );
  }
  return (
    <div className="inline-flex items-center gap-1.5 px-2 py-1 bg-amber-100 text-amber-700 rounded-full text-xs font-medium">
      <UserCheck className="w-3 h-3" />
      Added by {name}
    </div>
  );
}

// Synced Badge
function SyncedBadge({ source }: { source: SyncSource }) {
  const icon = getSyncSourceIcon(source);
  return (
    <span className="inline-flex items-center gap-1 px-1.5 py-0.5 bg-warm-100 text-warm-600 rounded text-[10px] font-medium">
      {icon} Synced
    </span>
  );
}

// Needs Attention Badge
function AttentionBadge({ description, small = false }: { description?: string; small?: boolean }) {
  if (small) {
    return (
      <span className="inline-flex items-center gap-0.5 px-1 py-0.5 bg-red-100 text-red-600 rounded text-[10px]">
        <AlertCircle className="w-2.5 h-2.5" />
      </span>
    );
  }
  return (
    <div className="flex items-center gap-2 px-3 py-2 bg-red-50 border border-red-200 rounded-lg">
      <AlertCircle className="w-4 h-4 text-red-500 flex-shrink-0" />
      <span className="text-sm text-red-700">{description || 'Action needed'}</span>
    </div>
  );
}

// Smart Reminder Card
function SmartReminderCard({
  reminder,
  onAcknowledge,
}: {
  reminder: SmartReminder;
  onAcknowledge: (id: string) => void;
}) {
  const getIcon = () => {
    switch (reminder.type) {
      case 'snack_duty': return '🍊';
      case 'permission_slip': return '📝';
      case 'anniversary': return '💝';
      default: return '🔔';
    }
  };

  return (
    <div className="flex items-center gap-3 p-3 bg-amber-50 border border-amber-200 rounded-xl">
      <span className="text-xl">{getIcon()}</span>
      <div className="flex-1 min-w-0">
        <p className="text-sm font-medium text-amber-900">{reminder.message}</p>
        <p className="text-xs text-amber-600 mt-0.5">From Sarah</p>
      </div>
      <button
        onClick={() => onAcknowledge(reminder.id)}
        className="p-2 text-amber-600 hover:bg-amber-100 rounded-lg transition-colors"
      >
        <CheckCircle2 className="w-5 h-5" />
      </button>
    </div>
  );
}

// Calendar Sync Panel
function CalendarSyncPanel({
  isOpen,
  onClose,
}: {
  isOpen: boolean;
  onClose: () => void;
}) {
  const [copied, setCopied] = useState(false);
  const [googleConnected, setGoogleConnected] = useState(false);
  const [appleConnected, setAppleConnected] = useState(true);

  const icalUrl = 'webcal://app.haven.com/api/calendar/feed/abc123.ics';

  const handleCopyUrl = () => {
    navigator.clipboard.writeText(icalUrl);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50">
      <div className="bg-white rounded-2xl shadow-xl max-w-md w-full max-h-[90vh] overflow-y-auto">
        <div className="p-6 border-b border-warm-200">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-emerald-100 rounded-xl flex items-center justify-center">
                <Link2 className="w-5 h-5 text-emerald-600" />
              </div>
              <div>
                <h2 className="text-lg font-bold text-warm-900">Calendar Sync</h2>
                <p className="text-sm text-warm-500">Connect your calendars</p>
              </div>
            </div>
            <button onClick={onClose} className="p-2 hover:bg-warm-100 rounded-lg transition-colors">
              <X className="w-5 h-5 text-warm-500" />
            </button>
          </div>
        </div>

        <div className="p-6 space-y-6">
          {/* Haven as Source of Truth */}
          <div className="p-4 bg-emerald-50 border border-emerald-200 rounded-xl">
            <div className="flex items-start gap-3">
              <Shield className="w-5 h-5 text-emerald-600 mt-0.5" />
              <div>
                <p className="font-medium text-emerald-800">Haven is your source of truth</p>
                <p className="text-sm text-emerald-600 mt-1">
                  Changes made here sync to your personal calendars. Family members see events on their phones.
                </p>
              </div>
            </div>
          </div>

          {/* Google Calendar */}
          <div className="space-y-3">
            <h3 className="font-medium text-warm-900">Google Calendar</h3>
            <div className="flex items-center justify-between p-4 border border-warm-200 rounded-xl">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-white rounded-lg flex items-center justify-center border border-warm-200">
                  <span className="text-2xl">🔵</span>
                </div>
                <div>
                  <p className="font-medium text-warm-900">Google Calendar</p>
                  <p className="text-sm text-warm-500">
                    {googleConnected ? 'Connected - 2 calendars synced' : 'Not connected'}
                  </p>
                </div>
              </div>
              <button
                onClick={() => setGoogleConnected(!googleConnected)}
                className={`px-4 py-2 text-sm font-medium rounded-lg transition-colors ${
                  googleConnected
                    ? 'bg-warm-100 text-warm-700 hover:bg-warm-200'
                    : 'bg-emerald-600 text-white hover:bg-emerald-700'
                }`}
              >
                {googleConnected ? 'Disconnect' : 'Connect'}
              </button>
            </div>
          </div>

          {/* Apple Calendar */}
          <div className="space-y-3">
            <h3 className="font-medium text-warm-900">Apple Calendar</h3>
            <div className="flex items-center justify-between p-4 border border-warm-200 rounded-xl">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-white rounded-lg flex items-center justify-center border border-warm-200">
                  <span className="text-2xl">🍎</span>
                </div>
                <div>
                  <p className="font-medium text-warm-900">Apple iCloud</p>
                  <p className="text-sm text-warm-500">
                    {appleConnected ? 'Connected - Family calendar synced' : 'Not connected'}
                  </p>
                </div>
              </div>
              <button
                onClick={() => setAppleConnected(!appleConnected)}
                className={`px-4 py-2 text-sm font-medium rounded-lg transition-colors ${
                  appleConnected
                    ? 'bg-warm-100 text-warm-700 hover:bg-warm-200'
                    : 'bg-emerald-600 text-white hover:bg-emerald-700'
                }`}
              >
                {appleConnected ? 'Disconnect' : 'Connect'}
              </button>
            </div>
          </div>

          {/* iCal Feed URL */}
          <div className="space-y-3">
            <h3 className="font-medium text-warm-900">Subscribe via URL</h3>
            <p className="text-sm text-warm-500">
              Use this URL to subscribe in any calendar app that supports iCal.
            </p>
            <div className="flex items-center gap-2">
              <input
                type="text"
                readOnly
                value={icalUrl}
                className="flex-1 px-3 py-2 bg-warm-50 border border-warm-200 rounded-lg text-sm text-warm-600 font-mono truncate"
              />
              <button
                onClick={handleCopyUrl}
                className="flex items-center gap-2 px-4 py-2 bg-warm-100 text-warm-700 rounded-lg hover:bg-warm-200 transition-colors"
              >
                {copied ? <Check className="w-4 h-4" /> : <Copy className="w-4 h-4" />}
                {copied ? 'Copied!' : 'Copy'}
              </button>
            </div>
          </div>

          {/* Sync Status */}
          <div className="p-4 bg-warm-50 rounded-xl">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2 text-sm text-warm-600">
                <RefreshCw className="w-4 h-4" />
                Last synced 2 minutes ago
              </div>
              <button className="text-sm text-emerald-600 font-medium hover:text-emerald-700">
                Sync Now
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

// Filter Pills
function FilterPills({
  activeFilter,
  onFilterChange,
}: {
  activeFilter: FilterType;
  onFilterChange: (filter: FilterType) => void;
}) {
  const filters: { type: FilterType; label: string; icon: typeof Filter }[] = [
    { type: 'all', label: 'All', icon: LayoutGrid },
    { type: 'house', label: 'House', icon: Home },
    { type: 'family', label: 'Family', icon: Users },
    { type: 'kids', label: 'Kids', icon: GraduationCap },
    { type: 'travel', label: 'Travel', icon: Plane },
  ];

  return (
    <div className="flex items-center gap-2 overflow-x-auto pb-2 scrollbar-hide">
      {filters.map((filter) => {
        const Icon = filter.icon;
        const isActive = activeFilter === filter.type;
        return (
          <button
            key={filter.type}
            onClick={() => onFilterChange(filter.type)}
            className={`flex items-center gap-2 px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap transition-colors ${
              isActive
                ? 'bg-emerald-600 text-white'
                : 'bg-white border border-warm-200 text-warm-600 hover:bg-warm-50'
            }`}
          >
            <Icon className="w-4 h-4" />
            {filter.label}
          </button>
        );
      })}
    </div>
  );
}

// Weather Badge
function WeatherBadge({ weather, large = false }: { weather: DayWeather; large?: boolean }) {
  const Icon = getWeatherIcon(weather.icon);
  if (large) {
    return (
      <div className="flex items-center gap-2 px-3 py-2 bg-white/80 backdrop-blur-sm rounded-lg">
        <Icon className={`w-5 h-5 ${weather.icon === 'sun' ? 'text-amber-500' : weather.icon === 'rain' ? 'text-blue-500' : 'text-warm-400'}`} />
        <span className="text-sm font-medium text-warm-700">{weather.temp}°F</span>
      </div>
    );
  }
  return (
    <div className="flex items-center gap-1 text-xs text-warm-500">
      <Icon className={`w-4 h-4 ${weather.icon === 'sun' ? 'text-amber-500' : 'text-warm-400'}`} />
      <span>{weather.temp}°</span>
    </div>
  );
}

// Event Chip (for Month View)
function EventChip({ event, compact = false }: { event: CalendarEvent; compact?: boolean }) {
  const colors = getEventColor(event);
  const Icon = getCategoryIcon(event.category);
  const needsAttention = event.requiresAction || event.conflict;

  if (compact) {
    return (
      <div className="relative">
        <div
          className={`w-2 h-2 rounded-full ${event.layer === 'house' ? 'bg-emerald-500' : 'bg-blue-500'} ${
            needsAttention ? 'ring-2 ring-red-400' : ''
          }`}
        />
        {event.createdByRole === 'MANAGER' && (
          <div className="absolute -top-0.5 -right-0.5 w-1.5 h-1.5 bg-amber-400 rounded-full" />
        )}
      </div>
    );
  }

  return (
    <div
      className={`flex items-center gap-1 px-2 py-1 rounded text-xs font-medium truncate ${colors.bg} border-l-2 ${colors.border} ${
        needsAttention ? 'ring-1 ring-red-400' : ''
      }`}
    >
      <Icon className={`w-3 h-3 flex-shrink-0 ${colors.icon}`} />
      <span className={`truncate ${colors.text}`}>{event.title}</span>
      {event.createdByRole === 'MANAGER' && (
        <span className="ml-auto">
          <UserCheck className="w-3 h-3 text-amber-500" />
        </span>
      )}
    </div>
  );
}

// Event Block (for Week View)
function EventBlock({ event, onClick }: { event: CalendarEvent; onClick: () => void }) {
  const colors = getEventColor(event);
  const Icon = getCategoryIcon(event.category);
  const needsAttention = event.requiresAction || event.conflict;

  return (
    <button
      onClick={onClick}
      className={`absolute left-1 right-1 rounded-lg p-2 text-left overflow-hidden transition-transform hover:scale-[1.02] ${colors.bg} border-l-4 ${colors.border} ${
        needsAttention ? 'ring-2 ring-red-400' : ''
      }`}
    >
      <div className="flex items-center gap-1 mb-0.5">
        <Icon className={`w-3 h-3 ${colors.icon}`} />
        <span className={`text-xs font-medium truncate ${colors.text}`}>{event.title}</span>
        {event.createdByRole === 'MANAGER' && (
          <ManagerBadge name={event.createdByName || MANAGER_NAME} small />
        )}
      </div>
      {event.startTime && (
        <p className="text-xs text-warm-500">{formatTime(event.startTime)}</p>
      )}
      {needsAttention && (
        <div className="flex items-center gap-1 mt-1 text-xs text-red-600">
          <AlertTriangle className="w-3 h-3" />
          <span>{event.conflict ? 'Conflict' : 'Action needed'}</span>
        </div>
      )}
    </button>
  );
}

// Mobile Agenda Time Slot
function MobileTimeSlot({
  hour,
  events,
  isCurrentHour,
  currentMinute,
  onEventClick,
}: {
  hour: number;
  events: CalendarEvent[];
  isCurrentHour: boolean;
  currentMinute: number;
  onEventClick: (event: CalendarEvent) => void;
}) {
  const timeLabel = hour === 12 ? '12 PM' : hour > 12 ? `${hour - 12} PM` : `${hour} AM`;
  const hasEvents = events.length > 0;

  return (
    <div className={`relative border-b border-warm-100 ${isCurrentHour ? 'bg-red-50/30' : ''}`}>
      {isCurrentHour && (
        <div
          className="absolute left-0 right-0 z-10 flex items-center pointer-events-none"
          style={{ top: `${(currentMinute / 60) * 100}%` }}
        >
          <div className="w-3 h-3 rounded-full bg-red-500 -ml-1.5" />
          <div className="flex-1 h-0.5 bg-red-500" />
        </div>
      )}

      <div className="flex min-h-[72px]">
        <div className="w-16 flex-shrink-0 py-2 px-2 text-right">
          <span className={`text-xs font-medium ${isCurrentHour ? 'text-red-600' : 'text-warm-400'}`}>
            {timeLabel}
          </span>
        </div>

        <div className="flex-1 py-2 px-2 space-y-2">
          {hasEvents ? (
            events.map((event) => {
              const colors = getEventColor(event);
              const Icon = getCategoryIcon(event.category);
              const needsAttention = event.requiresAction || event.conflict;
              return (
                <button
                  key={event.id}
                  onClick={() => onEventClick(event)}
                  className={`w-full flex items-center gap-3 p-3 rounded-xl text-left transition-colors ${colors.bg} border-l-4 ${colors.border} hover:shadow-sm ${
                    needsAttention ? 'ring-2 ring-red-300' : ''
                  }`}
                >
                  <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${event.layer === 'house' ? 'bg-emerald-100' : 'bg-blue-100'}`}>
                    <Icon className={`w-5 h-5 ${colors.icon}`} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <p className={`font-medium truncate ${colors.text}`}>{event.title}</p>
                      {event.createdByRole === 'MANAGER' && (
                        <ManagerBadge name={event.createdByName || MANAGER_NAME} small />
                      )}
                    </div>
                    <div className="flex items-center gap-2 text-xs text-warm-500 mt-0.5">
                      {event.startTime && (
                        <span>{formatTime(event.startTime)}{event.endTime && ` - ${formatTime(event.endTime)}`}</span>
                      )}
                      {event.location && (
                        <span className="flex items-center gap-1 truncate">
                          <MapPin className="w-3 h-3" />
                          {event.location}
                        </span>
                      )}
                    </div>
                  </div>
                  {event.isRecurring && <Repeat className="w-4 h-4 text-warm-400 flex-shrink-0" />}
                  {needsAttention && <AlertTriangle className="w-4 h-4 text-red-500 flex-shrink-0" />}
                </button>
              );
            })
          ) : (
            <div className="h-8 flex items-center">
              <span className="text-xs text-warm-300 italic">Free time</span>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

// Mobile Day Selector
function MobileDaySelector({
  selectedDate,
  onDateSelect,
  daysNeedingAttention,
}: {
  selectedDate: Date;
  onDateSelect: (date: Date) => void;
  daysNeedingAttention: DayAttention[];
}) {
  const dates = Array.from({ length: 14 }, (_, i) => getDate(i - 3, 0, 0));

  const hasAttention = useCallback((date: Date) => {
    const dateKey = date.toISOString().split('T')[0];
    return daysNeedingAttention.find(d => d.date === dateKey);
  }, [daysNeedingAttention]);

  return (
    <div className="flex overflow-x-auto gap-2 pb-2 scrollbar-hide -mx-4 px-4">
      {dates.map((date) => {
        const isSelected = isSameDay(date, selectedDate);
        const isTodayDate = isToday(date);
        const weather = mockWeather.find((w) => isSameDay(w.date, date));
        const WeatherIconComponent = weather ? getWeatherIcon(weather.icon) : null;
        const attention = hasAttention(date);

        return (
          <button
            key={date.toISOString()}
            onClick={() => onDateSelect(date)}
            className={`relative flex-shrink-0 w-14 py-3 rounded-xl flex flex-col items-center gap-1 transition-colors ${
              isSelected
                ? 'bg-emerald-600 text-white'
                : isTodayDate
                ? 'bg-emerald-100 text-emerald-700'
                : 'bg-white border border-warm-200 text-warm-700 hover:bg-warm-50'
            } ${attention ? 'ring-2 ring-red-400' : ''}`}
          >
            {attention && (
              <div className="absolute -top-1 -right-1 w-3 h-3 bg-red-500 rounded-full flex items-center justify-center">
                <span className="text-[8px] text-white font-bold">!</span>
              </div>
            )}
            <span className="text-[10px] uppercase font-medium opacity-70">
              {date.toLocaleDateString('en-US', { weekday: 'short' })}
            </span>
            <span className="text-lg font-bold">{date.getDate()}</span>
            {WeatherIconComponent && weather && (
              <div className="flex items-center gap-0.5">
                <WeatherIconComponent className={`w-3 h-3 ${isSelected ? 'text-white/80' : weather.icon === 'sun' ? 'text-amber-500' : 'text-warm-400'}`} />
                <span className={`text-[10px] ${isSelected ? 'text-white/80' : 'text-warm-500'}`}>{weather.temp}°</span>
              </div>
            )}
          </button>
        );
      })}
    </div>
  );
}

// Now Indicator Line
function NowIndicator() {
  const now = new Date();
  const hours = now.getHours();
  const minutes = now.getMinutes();
  const top = ((hours - 6) * 60 + minutes) * (64 / 60);

  if (hours < 6 || hours > 22) return null;

  return (
    <div
      className="absolute left-0 right-0 z-20 pointer-events-none"
      style={{ top: `${top}px` }}
    >
      <div className="flex items-center">
        <div className="w-2 h-2 rounded-full bg-red-500" />
        <div className="flex-1 h-0.5 bg-red-500" />
      </div>
    </div>
  );
}

// Add Event Modal
function AddEventModal({
  isOpen,
  onClose,
  selectedDate,
}: {
  isOpen: boolean;
  onClose: () => void;
  selectedDate: Date | null;
}) {
  const [eventType, setEventType] = useState<'family' | 'service' | null>(null);

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50">
      <div className="bg-white rounded-2xl shadow-xl max-w-md w-full max-h-[90vh] overflow-y-auto">
        <div className="p-6 border-b border-warm-200">
          <div className="flex items-center justify-between">
            <h2 className="text-xl font-bold text-warm-900">Add Event</h2>
            <button onClick={onClose} className="p-2 hover:bg-warm-100 rounded-lg transition-colors">
              <X className="w-5 h-5 text-warm-500" />
            </button>
          </div>
          {selectedDate && (
            <p className="text-sm text-warm-500 mt-1">{formatDateLong(selectedDate)}</p>
          )}
        </div>

        <div className="p-6">
          {!eventType ? (
            <div className="space-y-4">
              <p className="text-sm text-warm-600 mb-4">What would you like to add?</p>
              <button
                onClick={() => setEventType('family')}
                className="w-full flex items-center gap-4 p-4 border border-warm-200 rounded-xl hover:border-emerald-300 hover:bg-emerald-50/50 transition-colors text-left"
              >
                <div className="w-12 h-12 bg-blue-100 rounded-xl flex items-center justify-center">
                  <Users className="w-6 h-6 text-blue-600" />
                </div>
                <div>
                  <p className="font-medium text-warm-900">Family Event</p>
                  <p className="text-sm text-warm-500">Sports, parties, appointments, travel</p>
                </div>
              </button>

              <Link
                href="/app/requests"
                className="w-full flex items-center gap-4 p-4 border border-warm-200 rounded-xl hover:border-emerald-300 hover:bg-emerald-50/50 transition-colors text-left"
              >
                <div className="w-12 h-12 bg-emerald-100 rounded-xl flex items-center justify-center">
                  <Sparkles className="w-6 h-6 text-emerald-600" />
                </div>
                <div>
                  <p className="font-medium text-warm-900">Request Service</p>
                  <p className="text-sm text-warm-500">Ask {MANAGER_NAME} to schedule something</p>
                </div>
              </Link>
            </div>
          ) : (
            <div className="space-y-4">
              <button
                onClick={() => setEventType(null)}
                className="flex items-center gap-1 text-sm text-emerald-600 hover:text-emerald-700"
              >
                <ChevronLeft className="w-4 h-4" />
                Back
              </button>

              <div>
                <label className="block text-sm font-medium text-warm-700 mb-1">Event Title</label>
                <input
                  type="text"
                  placeholder="e.g., Soccer Practice"
                  className="w-full px-4 py-2.5 border border-warm-300 rounded-lg focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-warm-700 mb-1">Start Time</label>
                  <input
                    type="time"
                    className="w-full px-4 py-2.5 border border-warm-300 rounded-lg focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-warm-700 mb-1">End Time</label>
                  <input
                    type="time"
                    className="w-full px-4 py-2.5 border border-warm-300 rounded-lg focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-warm-700 mb-1">Location</label>
                <input
                  type="text"
                  placeholder="e.g., Oak Park Soccer Fields"
                  className="w-full px-4 py-2.5 border border-warm-300 rounded-lg focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-warm-700 mb-2">Repeat</label>
                <div className="flex flex-wrap gap-2">
                  {['Never', 'Weekly', 'Bi-Weekly', 'Monthly'].map((option) => (
                    <button
                      key={option}
                      className="px-4 py-2 border border-warm-200 rounded-lg text-sm text-warm-600 hover:border-emerald-300 hover:bg-emerald-50 transition-colors"
                    >
                      {option}
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-warm-700 mb-2">Who&apos;s Attending?</label>
                <div className="flex flex-wrap gap-2">
                  {mockFamilyMembers.map((member) => (
                    <button
                      key={member.id}
                      className="flex items-center gap-2 px-3 py-2 border border-warm-200 rounded-lg text-sm text-warm-600 hover:border-emerald-300 hover:bg-emerald-50 transition-colors"
                    >
                      <div className="w-6 h-6 rounded-full bg-warm-200 overflow-hidden">
                        <img src={member.avatar} alt="" className="w-full h-full object-cover" />
                      </div>
                      {member.name}
                    </button>
                  ))}
                </div>
              </div>

              <div className="pt-4">
                <button className="w-full py-3 bg-emerald-600 text-white font-medium rounded-lg hover:bg-emerald-700 transition-colors">
                  Add Event
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

// Event Detail Modal
function EventDetailModal({
  event,
  onClose,
  onResolveConflict,
  onCompleteAction,
}: {
  event: CalendarEvent | null;
  onClose: () => void;
  onResolveConflict: (eventId: string) => void;
  onCompleteAction: (eventId: string) => void;
}) {
  if (!event) return null;

  const colors = getEventColor(event);
  const Icon = getCategoryIcon(event.category);

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50">
      <div className="bg-white rounded-2xl shadow-xl max-w-md w-full max-h-[90vh] overflow-y-auto">
        <div className={`p-6 rounded-t-2xl ${colors.bg}`}>
          <div className="flex items-start justify-between">
            <div className="flex items-center gap-3">
              <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${event.layer === 'house' ? 'bg-emerald-100' : 'bg-blue-100'}`}>
                <Icon className={`w-6 h-6 ${colors.icon}`} />
              </div>
              <div>
                <h2 className="text-xl font-bold text-warm-900">{event.title}</h2>
                <p className="text-sm text-warm-500 capitalize">
                  {event.category} {event.layer === 'house' ? '• Service' : '• Family'}
                </p>
              </div>
            </div>
            <button onClick={onClose} className="p-2 hover:bg-white/50 rounded-lg transition-colors">
              <X className="w-5 h-5 text-warm-500" />
            </button>
          </div>

          {/* Manager Badge */}
          {event.createdByRole === 'MANAGER' && (
            <div className="mt-4">
              <ManagerBadge name={event.createdByName || MANAGER_NAME} />
            </div>
          )}

          {/* Synced Badge */}
          {event.createdByRole === 'SYNCED' && event.syncSource && (
            <div className="mt-4">
              <SyncedBadge source={event.syncSource} />
            </div>
          )}
        </div>

        <div className="p-6 space-y-4">
          {/* Manager Note */}
          {event.managerNote && (
            <div className="flex gap-3 p-4 bg-amber-50 border border-amber-200 rounded-xl">
              <Info className="w-5 h-5 text-amber-600 flex-shrink-0 mt-0.5" />
              <div>
                <p className="text-sm font-medium text-amber-800">Note from {event.createdByName || MANAGER_NAME}</p>
                <p className="text-sm text-amber-700 mt-1">{event.managerNote}</p>
              </div>
            </div>
          )}

          {/* Conflict Warning */}
          {event.conflict && event.conflictReason && (
            <div className="flex items-start gap-3 p-4 bg-red-50 border border-red-200 rounded-xl">
              <AlertTriangle className="w-5 h-5 text-red-500 flex-shrink-0 mt-0.5" />
              <div className="flex-1">
                <p className="font-medium text-red-700">Scheduling Conflict</p>
                <p className="text-sm text-red-600 mt-1">{event.conflictReason}</p>
                <button
                  onClick={() => onResolveConflict(event.id)}
                  className="mt-3 text-sm font-medium text-red-700 hover:text-red-800"
                >
                  Reschedule this event →
                </button>
              </div>
            </div>
          )}

          {/* Action Required */}
          {event.requiresAction && event.actionDescription && (
            <AttentionBadge description={event.actionDescription} />
          )}

          <div className="flex items-center gap-3 text-warm-700">
            <CalendarIcon className="w-5 h-5 text-warm-400" />
            <span>{formatDateLong(event.startDate)}</span>
          </div>

          {event.startTime && (
            <div className="flex items-center gap-3 text-warm-700">
              <Clock className="w-5 h-5 text-warm-400" />
              <span>
                {formatTime(event.startTime)}
                {event.endTime && ` - ${formatTime(event.endTime)}`}
              </span>
            </div>
          )}

          {event.isAllDay && (
            <div className="flex items-center gap-3 text-warm-700">
              <Clock className="w-5 h-5 text-warm-400" />
              <span>All Day</span>
            </div>
          )}

          {event.location && (
            <div className="flex items-center gap-3 text-warm-700">
              <MapPin className="w-5 h-5 text-warm-400" />
              <span>{event.location}</span>
            </div>
          )}

          {event.isRecurring && (
            <div className="flex items-center gap-3 text-warm-700">
              <Repeat className="w-5 h-5 text-warm-400" />
              <span className="capitalize">{event.recurrence}</span>
            </div>
          )}

          {event.attendees && event.attendees.length > 0 && (
            <div className="flex items-center gap-3 text-warm-700">
              <Users className="w-5 h-5 text-warm-400" />
              <span>{event.attendees.join(', ')}</span>
            </div>
          )}

          {event.description && (
            <div className="pt-2 border-t border-warm-200">
              <p className="text-warm-600">{event.description}</p>
            </div>
          )}

          {event.requiresAccess && !event.conflict && (
            <div className="flex items-center gap-3 p-4 bg-amber-50 border border-amber-200 rounded-xl">
              <Home className="w-5 h-5 text-amber-500" />
              <p className="text-sm text-amber-700">This service requires interior access</p>
            </div>
          )}
        </div>

        <div className="p-6 pt-0 flex gap-3">
          {event.requiresAction && (
            <button
              onClick={() => onCompleteAction(event.id)}
              className="flex-1 py-2.5 bg-emerald-600 text-white font-medium rounded-lg hover:bg-emerald-700 transition-colors flex items-center justify-center gap-2"
            >
              <CheckCircle2 className="w-4 h-4" />
              Mark Done
            </button>
          )}
          {event.conflict && (
            <button
              onClick={() => onResolveConflict(event.id)}
              className="flex-1 py-2.5 bg-amber-500 text-white font-medium rounded-lg hover:bg-amber-600 transition-colors"
            >
              Reschedule
            </button>
          )}
          <button
            onClick={onClose}
            className="flex-1 py-2.5 border border-warm-200 text-warm-700 font-medium rounded-lg hover:bg-warm-50 transition-colors"
          >
            Close
          </button>
        </div>
      </div>
    </div>
  );
}

// ============================================================================
// MAIN PAGE
// ============================================================================

export default function CalendarPage() {
  const [viewMode, setViewMode] = useState<ViewMode>('week');
  const [currentDate, setCurrentDate] = useState(new Date());
  const [selectedMobileDate, setSelectedMobileDate] = useState(new Date());
  const [activeFilter, setActiveFilter] = useState<FilterType>('all');
  const [showAddModal, setShowAddModal] = useState(false);
  const [showSyncPanel, setShowSyncPanel] = useState(false);
  const [selectedEvent, setSelectedEvent] = useState<CalendarEvent | null>(null);
  const [selectedDate, setSelectedDate] = useState<Date | null>(null);
  const [currentTime, setCurrentTime] = useState(new Date());
  const [smartReminders, setSmartReminders] = useState(mockSmartReminders);
  const [daysNeedingAttention] = useState(mockDaysNeedingAttention);
  const [showToast, setShowToast] = useState<string | null>(null);
  const weekViewRef = useRef<HTMLDivElement>(null);
  const mobileAgendaRef = useRef<HTMLDivElement>(null);

  // Toast helper
  const toast = useCallback((message: string) => {
    setShowToast(message);
    setTimeout(() => setShowToast(null), 3000);
  }, []);

  // Update current time every minute
  useEffect(() => {
    const interval = setInterval(() => setCurrentTime(new Date()), 60000);
    return () => clearInterval(interval);
  }, []);

  // Filter events
  const filteredEvents = useMemo(() => {
    return mockEvents.filter((event) => {
      if (activeFilter === 'all') return true;
      if (activeFilter === 'house') return event.layer === 'house';
      if (activeFilter === 'family') return event.layer === 'family' && event.category !== 'kids' && event.category !== 'travel';
      if (activeFilter === 'kids') return event.category === 'kids';
      if (activeFilter === 'travel') return event.category === 'travel';
      return true;
    });
  }, [activeFilter]);

  // Get events for a specific date
  const getEventsForDate = useCallback((date: Date) => {
    return filteredEvents.filter((event) => {
      if (event.isAllDay && event.endDate) {
        return date >= event.startDate && date <= event.endDate;
      }
      return isSameDay(event.startDate, date);
    });
  }, [filteredEvents]);

  // Get events for a specific hour on a date
  const getEventsForHour = useCallback((date: Date, hour: number) => {
    return filteredEvents.filter((event) => {
      if (!isSameDay(event.startDate, date)) return false;
      if (!event.startTime) return false;
      const eventHour = parseInt(event.startTime.split(':')[0] ?? '0', 10);
      return eventHour === hour;
    });
  }, [filteredEvents]);

  // Check if date needs attention
  const dateNeedsAttention = useCallback((date: Date) => {
    const dateKey = date.toISOString().split('T')[0];
    return daysNeedingAttention.find(d => d.date === dateKey);
  }, [daysNeedingAttention]);

  // Acknowledge reminder
  const handleAcknowledgeReminder = useCallback((reminderId: string) => {
    setSmartReminders(prev => prev.filter(r => r.id !== reminderId));
    toast('Reminder acknowledged');
  }, [toast]);

  // Resolve conflict
  const handleResolveConflict = useCallback((eventId: string) => {
    setSelectedEvent(null);
    toast('Contact Sarah to reschedule');
  }, [toast]);

  // Complete action
  const handleCompleteAction = useCallback((eventId: string) => {
    setSelectedEvent(null);
    toast('Action marked as complete');
  }, [toast]);

  // Navigation
  const navigatePrev = () => {
    const newDate = new Date(currentDate);
    if (viewMode === 'month') {
      newDate.setMonth(newDate.getMonth() - 1);
    } else {
      newDate.setDate(newDate.getDate() - 7);
    }
    setCurrentDate(newDate);
  };

  const navigateNext = () => {
    const newDate = new Date(currentDate);
    if (viewMode === 'month') {
      newDate.setMonth(newDate.getMonth() + 1);
    } else {
      newDate.setDate(newDate.getDate() + 7);
    }
    setCurrentDate(newDate);
  };

  const goToToday = () => {
    setCurrentDate(new Date());
    setSelectedMobileDate(new Date());
  };

  // Scroll to current time on mount
  useEffect(() => {
    if (viewMode === 'week' && weekViewRef.current) {
      const now = new Date();
      const scrollTop = Math.max(0, (now.getHours() - 7) * 64);
      weekViewRef.current.scrollTop = scrollTop;
    }
  }, [viewMode]);

  // Scroll mobile agenda to current time
  useEffect(() => {
    if (mobileAgendaRef.current && isToday(selectedMobileDate)) {
      const now = new Date();
      const currentHour = now.getHours();
      const scrollTop = Math.max(0, (currentHour - 7) * 72);
      mobileAgendaRef.current.scrollTop = scrollTop;
    }
  }, [selectedMobileDate]);

  const weekDates = getWeekDates(currentDate);
  const monthDates = getMonthDates(currentDate);

  const formatHeader = () => {
    if (viewMode === 'month') {
      return currentDate.toLocaleDateString('en-US', { month: 'long', year: 'numeric' });
    }
    const start = weekDates[0]!;
    const end = weekDates[6]!;
    if (start.getMonth() === end.getMonth()) {
      return `${start.toLocaleDateString('en-US', { month: 'long' })} ${start.getDate()} - ${end.getDate()}, ${start.getFullYear()}`;
    }
    return `${formatDateShort(start)} - ${formatDateShort(end)}, ${start.getFullYear()}`;
  };

  // Time slots for views (6 AM to 10 PM)
  const timeSlots = Array.from({ length: 17 }, (_, i) => i + 6);

  // Active reminders for today/upcoming
  const activeReminders = smartReminders.filter(r => !r.isAcknowledged);

  return (
    <div className="space-y-6 pb-24 lg:pb-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-warm-900">Calendar</h1>
          <p className="text-warm-500 mt-1">Your home and family schedule</p>
        </div>

        <div className="flex items-center gap-2">
          {/* Sync Button */}
          <button
            onClick={() => setShowSyncPanel(true)}
            className="flex items-center gap-2 px-4 py-2 bg-white border border-warm-200 rounded-lg text-sm font-medium text-warm-700 hover:bg-warm-50 transition-colors"
          >
            <Link2 className="w-4 h-4" />
            <span className="hidden sm:inline">Sync</span>
          </button>

          {/* View Mode Toggle - Desktop Only */}
          <div className="hidden md:flex items-center gap-2 bg-warm-100 p-1 rounded-lg">
            <button
              onClick={() => setViewMode('month')}
              className={`flex items-center gap-2 px-3 py-2 rounded-md text-sm font-medium transition-colors ${
                viewMode === 'month' ? 'bg-white shadow-sm text-warm-900' : 'text-warm-600 hover:text-warm-900'
              }`}
            >
              <LayoutGrid className="w-4 h-4" />
              Month
            </button>
            <button
              onClick={() => setViewMode('week')}
              className={`flex items-center gap-2 px-3 py-2 rounded-md text-sm font-medium transition-colors ${
                viewMode === 'week' ? 'bg-white shadow-sm text-warm-900' : 'text-warm-600 hover:text-warm-900'
              }`}
            >
              <CalendarIcon className="w-4 h-4" />
              Week
            </button>
            <button
              onClick={() => setViewMode('agenda')}
              className={`flex items-center gap-2 px-3 py-2 rounded-md text-sm font-medium transition-colors ${
                viewMode === 'agenda' ? 'bg-white shadow-sm text-warm-900' : 'text-warm-600 hover:text-warm-900'
              }`}
            >
              <List className="w-4 h-4" />
              Agenda
            </button>
          </div>
        </div>
      </div>

      {/* Smart Reminders (from Manager) */}
      {activeReminders.length > 0 && (
        <div className="space-y-2">
          <div className="flex items-center gap-2 text-sm font-medium text-warm-700">
            <Bell className="w-4 h-4 text-amber-500" />
            Reminders from {MANAGER_NAME}
          </div>
          <div className="space-y-2">
            {activeReminders.slice(0, 3).map((reminder) => (
              <SmartReminderCard
                key={reminder.id}
                reminder={reminder}
                onAcknowledge={handleAcknowledgeReminder}
              />
            ))}
          </div>
        </div>
      )}

      {/* Filter Pills */}
      <FilterPills activeFilter={activeFilter} onFilterChange={setActiveFilter} />

      {/* ========== MOBILE VIEW ========== */}
      <div className="md:hidden">
        <MobileDaySelector
          selectedDate={selectedMobileDate}
          onDateSelect={setSelectedMobileDate}
          daysNeedingAttention={daysNeedingAttention}
        />

        {/* Weather Header - Sticky */}
        <div className="sticky top-0 z-10 bg-gradient-to-b from-warm-100 to-warm-50 -mx-4 px-4 py-3 border-b border-warm-200 mt-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="font-semibold text-warm-900">
                {isToday(selectedMobileDate) ? 'Today' : formatDateLong(selectedMobileDate)}
              </p>
              <p className="text-sm text-warm-500">
                {getEventsForDate(selectedMobileDate).length} events scheduled
              </p>
            </div>
            {(() => {
              const weather = mockWeather.find((w) => isSameDay(w.date, selectedMobileDate));
              return weather ? <WeatherBadge weather={weather} large /> : null;
            })()}
          </div>

          {/* Day-level attention warning */}
          {(() => {
            const attention = dateNeedsAttention(selectedMobileDate);
            if (!attention) return null;
            return (
              <div className="mt-3 flex items-center gap-2 p-2 bg-red-50 border border-red-200 rounded-lg">
                <AlertCircle className="w-4 h-4 text-red-500 flex-shrink-0" />
                <p className="text-sm text-red-700">{attention.issues[0]}</p>
              </div>
            );
          })()}
        </div>

        {/* Mobile Schedule View */}
        <div ref={mobileAgendaRef} className="mt-4 bg-white rounded-xl border border-warm-200 overflow-hidden max-h-[60vh] overflow-y-auto">
          {timeSlots.map((hour) => {
            const hourEvents = getEventsForHour(selectedMobileDate, hour);
            const isCurrentHour = isToday(selectedMobileDate) && currentTime.getHours() === hour;

            return (
              <MobileTimeSlot
                key={hour}
                hour={hour}
                events={hourEvents}
                isCurrentHour={isCurrentHour}
                currentMinute={currentTime.getMinutes()}
                onEventClick={setSelectedEvent}
              />
            );
          })}
        </div>
      </div>

      {/* ========== DESKTOP VIEW ========== */}
      <div className="hidden md:block bg-white rounded-xl shadow-sm border border-warm-200 overflow-hidden">
        {/* Calendar Navigation */}
        <div className="flex items-center justify-between p-4 border-b border-warm-200">
          <div className="flex items-center gap-2">
            <button onClick={navigatePrev} className="p-2 hover:bg-warm-100 rounded-lg transition-colors">
              <ChevronLeft className="w-5 h-5 text-warm-600" />
            </button>
            <button onClick={navigateNext} className="p-2 hover:bg-warm-100 rounded-lg transition-colors">
              <ChevronRight className="w-5 h-5 text-warm-600" />
            </button>
            <h2 className="text-lg font-semibold text-warm-900 ml-2">{formatHeader()}</h2>
          </div>
          <button
            onClick={goToToday}
            className="px-4 py-2 text-sm font-medium text-emerald-600 hover:bg-emerald-50 rounded-lg transition-colors"
          >
            Today
          </button>
        </div>

        {/* Month View */}
        {viewMode === 'month' && (
          <div>
            {/* Day Headers */}
            <div className="grid grid-cols-7 border-b border-warm-200">
              {['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((day) => (
                <div key={day} className="py-3 text-center text-sm font-medium text-warm-500 border-r border-warm-200 last:border-r-0">
                  {day}
                </div>
              ))}
            </div>

            {/* Calendar Grid */}
            <div className="grid grid-cols-7">
              {monthDates.map((date, index) => {
                if (!date) {
                  return <div key={`empty-${index}`} className="h-32 bg-warm-50 border-b border-r border-warm-200" />;
                }

                const dayEvents = getEventsForDate(date);
                const isTodayDate = isToday(date);
                const attention = dateNeedsAttention(date);

                return (
                  <div
                    key={date.toISOString()}
                    onClick={() => {
                      setSelectedDate(date);
                      setShowAddModal(true);
                    }}
                    className={`h-32 p-2 border-b border-r border-warm-200 cursor-pointer hover:bg-warm-50 transition-colors ${
                      isTodayDate ? 'bg-emerald-50/30' : ''
                    } ${attention ? 'ring-2 ring-inset ring-red-400' : ''}`}
                  >
                    <div className="flex items-center justify-between">
                      <div
                        className={`text-sm font-medium ${
                          isTodayDate ? 'w-7 h-7 flex items-center justify-center rounded-full bg-emerald-600 text-white' : 'text-warm-700'
                        }`}
                      >
                        {date.getDate()}
                      </div>
                      {attention && (
                        <div className="w-2 h-2 bg-red-500 rounded-full" />
                      )}
                    </div>

                    <div className="space-y-1 mt-1">
                      {dayEvents.slice(0, 3).map((event) => (
                        <EventChip key={event.id} event={event} />
                      ))}
                      {dayEvents.length > 3 && (
                        <p className="text-xs text-warm-500 pl-1">+{dayEvents.length - 3} more</p>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        )}

        {/* Week View */}
        {viewMode === 'week' && (
          <div>
            {/* Weather Row */}
            <div className="grid grid-cols-8 border-b border-warm-200 bg-gradient-to-b from-warm-50 to-white">
              <div className="py-2 px-3 text-xs text-warm-500 font-medium border-r border-warm-200">Weather</div>
              {weekDates.map((date) => {
                const weather = mockWeather.find((w) => isSameDay(w.date, date));
                return (
                  <div
                    key={date.toISOString()}
                    className={`py-2 px-2 flex justify-center border-r border-warm-200 ${isToday(date) ? 'bg-emerald-50/50' : ''}`}
                  >
                    {weather && <WeatherBadge weather={weather} />}
                  </div>
                );
              })}
            </div>

            {/* Day Headers with attention indicator */}
            <div className="grid grid-cols-8 border-b border-warm-200">
              <div className="py-3 px-3 border-r border-warm-200" />
              {weekDates.map((date) => {
                const isTodayDate = isToday(date);
                const attention = dateNeedsAttention(date);
                return (
                  <div
                    key={date.toISOString()}
                    className={`py-3 text-center border-r border-warm-200 relative ${isTodayDate ? 'bg-emerald-50/50' : ''} ${
                      attention ? 'ring-2 ring-inset ring-red-400' : ''
                    }`}
                  >
                    <p className="text-xs text-warm-500 uppercase">{date.toLocaleDateString('en-US', { weekday: 'short' })}</p>
                    <p className={`text-lg font-semibold mt-0.5 ${isTodayDate ? 'text-emerald-600' : 'text-warm-900'}`}>{date.getDate()}</p>
                    {attention && (
                      <div className="absolute top-1 right-1 w-2 h-2 bg-red-500 rounded-full" />
                    )}
                  </div>
                );
              })}
            </div>

            {/* Time Grid */}
            <div ref={weekViewRef} className="relative h-[600px] overflow-y-auto">
              <div className="grid grid-cols-8">
                {/* Time Labels */}
                <div className="border-r border-warm-200">
                  {timeSlots.map((hour) => (
                    <div key={hour} className="h-16 px-2 flex items-start justify-end pt-1">
                      <span className="text-xs text-warm-400">
                        {hour === 12 ? '12 PM' : hour > 12 ? `${hour - 12} PM` : `${hour} AM`}
                      </span>
                    </div>
                  ))}
                </div>

                {/* Day Columns */}
                {weekDates.map((date) => {
                  const dayEvents = getEventsForDate(date).filter((e) => !e.isAllDay);
                  const isTodayDate = isToday(date);

                  return (
                    <div key={date.toISOString()} className={`relative border-r border-warm-200 ${isTodayDate ? 'bg-emerald-50/30' : ''}`}>
                      {timeSlots.map((hour) => (
                        <div key={hour} className="h-16 border-b border-warm-100" />
                      ))}

                      {isTodayDate && <NowIndicator />}

                      {dayEvents.map((event) => {
                        if (!event.startTime) return null;
                        const startParts = event.startTime.split(':').map(Number);
                        const endParts = (event.endTime || event.startTime).split(':').map(Number);
                        const startHour = startParts[0] ?? 0;
                        const startMin = startParts[1] ?? 0;
                        const endHour = endParts[0] ?? 0;
                        const endMin = endParts[1] ?? 0;
                        const top = ((startHour - 6) * 60 + startMin) * (64 / 60);
                        const height = ((endHour - startHour) * 60 + (endMin - startMin)) * (64 / 60);

                        return (
                          <div key={event.id} style={{ top: `${top}px`, height: `${Math.max(height, 24)}px` }} className="absolute left-0 right-0">
                            <EventBlock event={event} onClick={() => setSelectedEvent(event)} />
                          </div>
                        );
                      })}
                    </div>
                  );
                })}
              </div>
            </div>
          </div>
        )}

        {/* Agenda View */}
        {viewMode === 'agenda' && (
          <div className="p-4 space-y-6">
            {Array.from({ length: 14 }, (_, i) => {
              const date = getDate(i);
              const dayEvents = getEventsForDate(date);
              if (dayEvents.length === 0) return null;

              const attention = dateNeedsAttention(date);

              return (
                <div key={date.toISOString()}>
                  <div className="flex items-center gap-3 mb-3">
                    <div
                      className={`relative w-12 h-12 rounded-xl flex flex-col items-center justify-center ${
                        isToday(date) ? 'bg-emerald-600 text-white' : 'bg-warm-100 text-warm-700'
                      } ${attention ? 'ring-2 ring-red-400' : ''}`}
                    >
                      <span className="text-xs uppercase">{date.toLocaleDateString('en-US', { weekday: 'short' })}</span>
                      <span className="text-lg font-bold">{date.getDate()}</span>
                      {attention && (
                        <div className="absolute -top-1 -right-1 w-3 h-3 bg-red-500 rounded-full" />
                      )}
                    </div>
                    <div>
                      <p className={`font-medium ${isToday(date) ? 'text-emerald-600' : 'text-warm-900'}`}>
                        {isToday(date) ? 'Today' : date.toLocaleDateString('en-US', { weekday: 'long' })}
                      </p>
                      <p className="text-sm text-warm-500">{date.toLocaleDateString('en-US', { month: 'long', day: 'numeric' })}</p>
                    </div>
                  </div>

                  {attention && (
                    <div className="mb-3 ml-15 flex items-center gap-2 p-2 bg-red-50 border border-red-200 rounded-lg">
                      <AlertCircle className="w-4 h-4 text-red-500 flex-shrink-0" />
                      <p className="text-sm text-red-700">{attention.issues[0]}</p>
                    </div>
                  )}

                  <div className="space-y-2 ml-15">
                    {dayEvents.map((event) => {
                      const colors = getEventColor(event);
                      const Icon = getCategoryIcon(event.category);
                      const needsAttention = event.requiresAction || event.conflict;
                      return (
                        <button
                          key={event.id}
                          onClick={() => setSelectedEvent(event)}
                          className={`w-full flex items-center gap-4 p-4 rounded-xl text-left transition-colors ${colors.bg} hover:shadow-sm ${
                            needsAttention ? 'ring-2 ring-red-300' : ''
                          }`}
                        >
                          <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${event.layer === 'house' ? 'bg-emerald-100' : 'bg-blue-100'}`}>
                            <Icon className={`w-6 h-6 ${colors.icon}`} />
                          </div>
                          <div className="flex-1 min-w-0">
                            <div className="flex items-center gap-2">
                              <p className="font-medium text-warm-900 truncate">{event.title}</p>
                              {event.createdByRole === 'MANAGER' && (
                                <ManagerBadge name={event.createdByName || MANAGER_NAME} small />
                              )}
                            </div>
                            <div className="flex items-center gap-3 mt-1 text-sm text-warm-500">
                              {event.startTime && (
                                <span className="flex items-center gap-1">
                                  <Clock className="w-3.5 h-3.5" />
                                  {formatTime(event.startTime)}
                                  {event.endTime && ` - ${formatTime(event.endTime)}`}
                                </span>
                              )}
                              {event.isAllDay && <span>All Day</span>}
                              {event.location && (
                                <span className="flex items-center gap-1 truncate">
                                  <MapPin className="w-3.5 h-3.5" />
                                  {event.location}
                                </span>
                              )}
                            </div>
                          </div>
                          {event.isRecurring && <Repeat className="w-4 h-4 text-warm-400 flex-shrink-0" />}
                          {needsAttention && (
                            <div className="flex items-center gap-1 px-2 py-1 bg-red-100 text-red-600 rounded-full text-xs font-medium">
                              <AlertTriangle className="w-3 h-3" />
                              {event.conflict ? 'Conflict' : 'Action'}
                            </div>
                          )}
                        </button>
                      );
                    })}
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Legend - Desktop Only */}
      <div className="hidden md:flex flex-wrap items-center gap-4 px-4 py-3 bg-white rounded-xl border border-warm-200">
        <span className="text-sm font-medium text-warm-700">Legend:</span>
        <div className="flex items-center gap-2">
          <div className="w-4 h-4 border-l-2 border-emerald-500 bg-emerald-50 rounded" />
          <span className="text-sm text-warm-600">House/Service</span>
        </div>
        <div className="flex items-center gap-2">
          <div className="w-4 h-4 bg-blue-50 border-l-2 border-blue-500 rounded" />
          <span className="text-sm text-warm-600">Family/Kids</span>
        </div>
        <div className="flex items-center gap-2">
          <div className="w-4 h-4 bg-pink-50 border-l-2 border-pink-500 rounded" />
          <span className="text-sm text-warm-600">Social</span>
        </div>
        <div className="flex items-center gap-2">
          <div className="w-4 h-4 bg-purple-50 border-l-2 border-purple-500 rounded" />
          <span className="text-sm text-warm-600">Travel</span>
        </div>
        <div className="flex items-center gap-2">
          <UserCheck className="w-4 h-4 text-amber-500" />
          <span className="text-sm text-warm-600">Added by {MANAGER_NAME}</span>
        </div>
        <div className="flex items-center gap-2">
          <div className="w-4 h-4 bg-red-50 ring-2 ring-red-400 rounded" />
          <span className="text-sm text-warm-600">Needs Attention</span>
        </div>
      </div>

      {/* Floating Action Button */}
      <button
        onClick={() => {
          setSelectedDate(new Date());
          setShowAddModal(true);
        }}
        className="fixed bottom-36 right-4 lg:bottom-6 lg:right-6 w-12 h-12 lg:w-14 lg:h-14 bg-emerald-600 text-white rounded-full shadow-lg hover:bg-emerald-700 hover:shadow-xl transition-all flex items-center justify-center z-40"
      >
        <Plus className="w-5 h-5 lg:w-6 lg:h-6" />
      </button>

      {/* Toast */}
      {showToast && (
        <div className="fixed bottom-20 left-1/2 -tranwarm-x-1/2 z-50 px-4 py-2 bg-warm-900 text-white rounded-lg shadow-lg text-sm animate-fade-in">
          {showToast}
        </div>
      )}

      {/* Modals */}
      <AddEventModal
        isOpen={showAddModal}
        onClose={() => {
          setShowAddModal(false);
          setSelectedDate(null);
        }}
        selectedDate={selectedDate}
      />

      <EventDetailModal
        event={selectedEvent}
        onClose={() => setSelectedEvent(null)}
        onResolveConflict={handleResolveConflict}
        onCompleteAction={handleCompleteAction}
      />

      <CalendarSyncPanel
        isOpen={showSyncPanel}
        onClose={() => setShowSyncPanel(false)}
      />
    </div>
  );
}
