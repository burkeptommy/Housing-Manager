'use client';

import { useState, useMemo } from 'react';
import {
  Calendar as CalendarIcon,
  ChevronLeft,
  ChevronRight,
  Plus,
  Clock,
  MapPin,
  Wrench,
  FileText,
  X,
  AlertTriangle,
  Navigation,
  MessageCircle,
  ExternalLink,
  Filter,
  Car,
} from 'lucide-react';

// ============================================================================
// TYPES
// ============================================================================

type CalendarView = 'day' | 'week' | 'month';
type EventType = 'site_visit' | 'vendor_appointment' | 'call_block' | 'deadline' | 'homeowner_event';
type HouseholdId = 'smith' | 'johnson' | 'miller' | 'williams' | 'chen' | 'davis';

interface CalendarEvent {
  id: string;
  title: string;
  type: EventType;
  householdId: HouseholdId;
  householdName: string;
  address: string;
  date: Date;
  startTime: string;
  endTime: string;
  vendor?: {
    name: string;
    contact: string;
  };
  workOrderId?: string;
  accessInfo?: string;
  notes?: string;
}

interface NewEventForm {
  title: string;
  type: EventType;
  householdId: HouseholdId;
  date: string;
  startTime: string;
  endTime: string;
  workOrderId: string;
  notes: string;
}

// ============================================================================
// CONFIGURATIONS
// ============================================================================

const eventTypeConfig: Record<EventType, { label: string; color: string; bgColor: string; borderColor: string }> = {
  site_visit: { label: 'Site Visit', color: 'text-indigo-700', bgColor: 'bg-indigo-50', borderColor: 'border-indigo-500' },
  vendor_appointment: { label: 'Vendor Appointment', color: 'text-blue-700', bgColor: 'bg-blue-50', borderColor: 'border-blue-500' },
  call_block: { label: 'Call Block', color: 'text-purple-700', bgColor: 'bg-purple-50', borderColor: 'border-purple-500' },
  deadline: { label: 'Deadline', color: 'text-red-700', bgColor: 'bg-red-50', borderColor: 'border-red-500' },
  homeowner_event: { label: 'Homeowner Event (FYI)', color: 'text-slate-600', bgColor: 'bg-slate-50', borderColor: 'border-slate-400' },
};

const householdColorConfig: Record<HouseholdId, { color: string; bgColor: string; borderColor: string }> = {
  smith: { color: 'text-indigo-700', bgColor: 'bg-indigo-100', borderColor: 'border-indigo-500' },
  johnson: { color: 'text-blue-700', bgColor: 'bg-blue-100', borderColor: 'border-blue-500' },
  miller: { color: 'text-emerald-700', bgColor: 'bg-emerald-100', borderColor: 'border-emerald-500' },
  williams: { color: 'text-purple-700', bgColor: 'bg-purple-100', borderColor: 'border-purple-500' },
  chen: { color: 'text-amber-700', bgColor: 'bg-amber-100', borderColor: 'border-amber-500' },
  davis: { color: 'text-pink-700', bgColor: 'bg-pink-100', borderColor: 'border-pink-500' },
};

const householdNames: Record<HouseholdId, string> = {
  smith: 'Smith Family',
  johnson: 'Johnson Family',
  miller: 'Miller Family',
  williams: 'Williams Family',
  chen: 'Chen Family',
  davis: 'Davis Family',
};

// ============================================================================
// MOCK DATA
// ============================================================================

const getDateForDay = (dayOffset: number): Date => {
  const today = new Date();
  today.setDate(today.getDate() + dayOffset);
  return today;
};

const mockEvents: CalendarEvent[] = [
  {
    id: 'e1',
    title: 'HVAC Annual Service',
    type: 'vendor_appointment',
    householdId: 'smith',
    householdName: 'Smith Family',
    address: '456 Oak Lane',
    date: getDateForDay(1),
    startTime: '09:00',
    endTime: '11:00',
    vendor: { name: 'AirFlow HVAC', contact: 'John' },
    workOrderId: 'WO-1892',
    accessInfo: 'Gate code 1247, Dog Max is friendly',
  },
  {
    id: 'e2',
    title: 'Weekly Check-in Call',
    type: 'call_block',
    householdId: 'johnson',
    householdName: 'Johnson Family',
    address: '789 Maple Ave',
    date: getDateForDay(1),
    startTime: '11:00',
    endTime: '12:00',
    notes: 'Discuss kitchen renovation timeline',
  },
  {
    id: 'e3',
    title: 'Monthly Maintenance Round',
    type: 'site_visit',
    householdId: 'miller',
    householdName: 'Miller Family',
    address: '321 Pine Street',
    date: getDateForDay(1),
    startTime: '13:00',
    endTime: '15:00',
    accessInfo: 'Lockbox code 4521',
  },
  {
    id: 'e4',
    title: 'Morning Call Block',
    type: 'call_block',
    householdId: 'smith',
    householdName: 'General',
    address: 'Office',
    date: getDateForDay(0),
    startTime: '08:00',
    endTime: '09:30',
    notes: 'Check messages, follow up on pending items',
  },
  {
    id: 'e5',
    title: 'Bill Payment Deadline',
    type: 'deadline',
    householdId: 'chen',
    householdName: 'Chen Family',
    address: '567 Cedar Blvd',
    date: getDateForDay(0),
    startTime: '13:00',
    endTime: '14:00',
    notes: 'Property tax payment due',
  },
  {
    id: 'e6',
    title: 'Pool Inspection',
    type: 'vendor_appointment',
    householdId: 'williams',
    householdName: 'Williams Family',
    address: '890 Birch Road',
    date: getDateForDay(2),
    startTime: '10:00',
    endTime: '11:30',
    vendor: { name: 'Crystal Clear Pools', contact: 'Maria' },
    workOrderId: 'WO-1895',
  },
  {
    id: 'e7',
    title: 'Kids Birthday Party',
    type: 'homeowner_event',
    householdId: 'miller',
    householdName: 'Miller Family',
    address: '321 Pine Street',
    date: getDateForDay(3),
    startTime: '14:00',
    endTime: '17:00',
    notes: 'No maintenance visits this day',
  },
  {
    id: 'e8',
    title: 'Roof Repair Follow-up',
    type: 'site_visit',
    householdId: 'davis',
    householdName: 'Davis Family',
    address: '234 Elm Way',
    date: getDateForDay(2),
    startTime: '14:00',
    endTime: '15:00',
    workOrderId: 'WO-1890',
  },
  {
    id: 'e9',
    title: 'Quarterly Review Call',
    type: 'call_block',
    householdId: 'chen',
    householdName: 'Chen Family',
    address: '567 Cedar Blvd',
    date: getDateForDay(4),
    startTime: '10:00',
    endTime: '11:00',
  },
  {
    id: 'e10',
    title: 'Electrician - Panel Upgrade',
    type: 'vendor_appointment',
    householdId: 'johnson',
    householdName: 'Johnson Family',
    address: '789 Maple Ave',
    date: getDateForDay(3),
    startTime: '08:00',
    endTime: '12:00',
    vendor: { name: 'Spark Electric', contact: 'Tom' },
    workOrderId: 'WO-1897',
    accessInfo: 'Park in driveway, owner will be home',
  },
];

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

const formatTime = (time: string): string => {
  const parts = time.split(':').map(Number);
  const hours = parts[0] ?? 0;
  const minutes = parts[1] ?? 0;
  const period = hours >= 12 ? 'PM' : 'AM';
  const displayHours = hours % 12 || 12;
  return `${displayHours}:${minutes.toString().padStart(2, '0')} ${period}`;
};

const formatDate = (date: Date): string => {
  return date.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' });
};

const formatMonthYear = (date: Date): string => {
  return date.toLocaleDateString('en-US', { month: 'long', year: 'numeric' });
};

const getWeekDays = (date: Date): Date[] => {
  const start = new Date(date);
  const day = start.getDay();
  const diff = start.getDate() - day + (day === 0 ? -6 : 1); // Adjust for Monday start
  start.setDate(diff);

  return Array.from({ length: 7 }, (_, i) => {
    const d = new Date(start);
    d.setDate(start.getDate() + i);
    return d;
  });
};

const getMonthDays = (date: Date): (Date | null)[] => {
  const year = date.getFullYear();
  const month = date.getMonth();
  const firstDay = new Date(year, month, 1);
  const lastDay = new Date(year, month + 1, 0);
  const daysInMonth = lastDay.getDate();

  // Get day of week for first day (0 = Sunday, adjust for Monday start)
  let startDayOfWeek = firstDay.getDay() - 1;
  if (startDayOfWeek < 0) startDayOfWeek = 6;

  const days: (Date | null)[] = [];

  // Add empty slots for days before first of month
  for (let i = 0; i < startDayOfWeek; i++) {
    days.push(null);
  }

  // Add all days of month
  for (let i = 1; i <= daysInMonth; i++) {
    days.push(new Date(year, month, i));
  }

  return days;
};

const isSameDay = (date1: Date, date2: Date): boolean => {
  return date1.toDateString() === date2.toDateString();
};

const isToday = (date: Date): boolean => {
  return isSameDay(date, new Date());
};

const getTimeSlotPosition = (time: string): number => {
  const parts = time.split(':').map(Number);
  const hours = parts[0] ?? 0;
  const minutes = parts[1] ?? 0;
  return (hours - 7) * 60 + minutes; // Starting from 7 AM
};

const getEventDuration = (startTime: string, endTime: string): number => {
  return getTimeSlotPosition(endTime) - getTimeSlotPosition(startTime);
};

const detectConflicts = (events: CalendarEvent[]): string[] => {
  const conflicts: string[] = [];

  for (let i = 0; i < events.length; i++) {
    for (let j = i + 1; j < events.length; j++) {
      const event1 = events[i]!;
      const event2 = events[j]!;

      if (!isSameDay(event1.date, event2.date)) continue;

      const start1 = getTimeSlotPosition(event1.startTime);
      const end1 = getTimeSlotPosition(event1.endTime);
      const start2 = getTimeSlotPosition(event2.startTime);
      const end2 = getTimeSlotPosition(event2.endTime);

      // Check for overlap
      if (start1 < end2 && start2 < end1) {
        conflicts.push(`${event1.title} overlaps with ${event2.title}`);
      }
    }
  }

  return conflicts;
};

// ============================================================================
// COMPONENTS
// ============================================================================

export default function ManagerCalendarPage() {
  const [currentDate, setCurrentDate] = useState(new Date());
  const [view, setView] = useState<CalendarView>('week');
  const [selectedEvent, setSelectedEvent] = useState<CalendarEvent | null>(null);
  const [showAddModal, setShowAddModal] = useState(false);
  const [householdFilter, setHouseholdFilter] = useState<HouseholdId | 'all'>('all');
  const [typeFilter, setTypeFilter] = useState<EventType | 'all'>('all');
  const [newEvent, setNewEvent] = useState<NewEventForm>({
    title: '',
    type: 'site_visit',
    householdId: 'smith',
    date: new Date().toISOString().split('T')[0] ?? '',
    startTime: '09:00',
    endTime: '10:00',
    workOrderId: '',
    notes: '',
  });

  // Filter events
  const filteredEvents = useMemo(() => {
    return mockEvents.filter(event => {
      if (householdFilter !== 'all' && event.householdId !== householdFilter) return false;
      if (typeFilter !== 'all' && event.type !== typeFilter) return false;
      return true;
    });
  }, [householdFilter, typeFilter]);

  // Get events for a specific day
  const getEventsForDay = (date: Date): CalendarEvent[] => {
    return filteredEvents.filter(event => isSameDay(event.date, date));
  };

  // Conflict detection for today's events
  const todayConflicts = useMemo(() => {
    const todayEvents = mockEvents.filter(event => isToday(event.date));
    return detectConflicts(todayEvents);
  }, []);

  // Navigation
  const navigatePrev = () => {
    const newDate = new Date(currentDate);
    if (view === 'day') newDate.setDate(newDate.getDate() - 1);
    else if (view === 'week') newDate.setDate(newDate.getDate() - 7);
    else newDate.setMonth(newDate.getMonth() - 1);
    setCurrentDate(newDate);
  };

  const navigateNext = () => {
    const newDate = new Date(currentDate);
    if (view === 'day') newDate.setDate(newDate.getDate() + 1);
    else if (view === 'week') newDate.setDate(newDate.getDate() + 7);
    else newDate.setMonth(newDate.getMonth() + 1);
    setCurrentDate(newDate);
  };

  const goToToday = () => {
    setCurrentDate(new Date());
  };

  // Hours for day/week view
  const hours = Array.from({ length: 13 }, (_, i) => i + 7); // 7 AM to 7 PM

  // Week days for week view
  const weekDays = getWeekDays(currentDate);

  // Month days for month view
  const monthDays = getMonthDays(currentDate);

  return (
    <div className="min-h-screen bg-slate-50">
      {/* Header */}
      <div className="bg-white border-b border-slate-200">
        <div className="max-w-7xl mx-auto px-6 py-6">
          <div className="flex items-center gap-3 mb-6">
            <div className="w-10 h-10 bg-indigo-100 rounded-lg flex items-center justify-center">
              <CalendarIcon className="w-5 h-5 text-indigo-600" />
            </div>
            <div>
              <h1 className="text-2xl font-bold text-slate-900">My Schedule</h1>
              <p className="text-sm text-slate-500">Manage appointments across all households</p>
            </div>
          </div>

          {/* Controls Row */}
          <div className="flex flex-wrap items-center justify-between gap-4">
            {/* View Toggles */}
            <div className="flex items-center gap-2">
              <div className="flex bg-slate-100 rounded-lg p-1">
                {(['day', 'week', 'month'] as CalendarView[]).map((v) => (
                  <button
                    key={v}
                    onClick={() => setView(v)}
                    className={`px-4 py-2 text-sm font-medium rounded-md transition-colors ${
                      view === v
                        ? 'bg-white text-indigo-600 shadow-sm'
                        : 'text-slate-600 hover:text-slate-900'
                    }`}
                  >
                    {v.charAt(0).toUpperCase() + v.slice(1)}
                  </button>
                ))}
              </div>

              {/* Navigation */}
              <div className="flex items-center gap-1 ml-4">
                <button
                  onClick={goToToday}
                  className="px-3 py-2 text-sm font-medium text-slate-600 hover:text-slate-900 hover:bg-slate-100 rounded-lg transition-colors"
                >
                  Today
                </button>
                <button
                  onClick={navigatePrev}
                  className="p-2 text-slate-600 hover:text-slate-900 hover:bg-slate-100 rounded-lg transition-colors"
                >
                  <ChevronLeft className="w-5 h-5" />
                </button>
                <button
                  onClick={navigateNext}
                  className="p-2 text-slate-600 hover:text-slate-900 hover:bg-slate-100 rounded-lg transition-colors"
                >
                  <ChevronRight className="w-5 h-5" />
                </button>
              </div>
            </div>

            {/* Filters and Add */}
            <div className="flex items-center gap-3">
              <select
                value={householdFilter}
                onChange={(e) => setHouseholdFilter(e.target.value as HouseholdId | 'all')}
                className="px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
              >
                <option value="all">All Households</option>
                {Object.entries(householdNames).map(([id, name]) => (
                  <option key={id} value={id}>{name}</option>
                ))}
              </select>

              <select
                value={typeFilter}
                onChange={(e) => setTypeFilter(e.target.value as EventType | 'all')}
                className="px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
              >
                <option value="all">All Types</option>
                {Object.entries(eventTypeConfig).map(([type, config]) => (
                  <option key={type} value={type}>{config.label}</option>
                ))}
              </select>

              <button
                onClick={() => setShowAddModal(true)}
                className="flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white text-sm font-medium rounded-lg hover:bg-indigo-700 transition-colors"
              >
                <Plus className="w-4 h-4" />
                Add Event
              </button>
            </div>
          </div>

          {/* Current Period Display */}
          <div className="mt-4">
            <h2 className="text-xl font-semibold text-slate-900">
              {view === 'day' && formatDate(currentDate)}
              {view === 'week' && `${formatDate(weekDays[0]!)} - ${formatDate(weekDays[6]!)}`}
              {view === 'month' && formatMonthYear(currentDate)}
            </h2>
          </div>
        </div>
      </div>

      {/* Conflict Warning */}
      {todayConflicts.length > 0 && (
        <div className="max-w-7xl mx-auto px-6 mt-4">
          <div className="bg-amber-50 border border-amber-200 rounded-lg p-4 flex items-start gap-3">
            <AlertTriangle className="w-5 h-5 text-amber-600 flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="font-medium text-amber-800">Schedule Conflicts Detected</h4>
              <ul className="mt-1 text-sm text-amber-700">
                {todayConflicts.map((conflict, i) => (
                  <li key={i}>{conflict}</li>
                ))}
              </ul>
            </div>
          </div>
        </div>
      )}

      {/* Calendar Content */}
      <div className="max-w-7xl mx-auto px-6 py-6">
        {/* Day View */}
        {view === 'day' && (
          <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
            <div className="grid grid-cols-[80px_1fr]">
              {/* Time Column */}
              <div className="border-r border-slate-200">
                {hours.map((hour) => (
                  <div key={hour} className="h-16 border-b border-slate-100 pr-3 text-right">
                    <span className="text-xs text-slate-400 -mt-2 block">
                      {hour === 12 ? '12 PM' : hour > 12 ? `${hour - 12} PM` : `${hour} AM`}
                    </span>
                  </div>
                ))}
              </div>

              {/* Events Column */}
              <div className="relative">
                {/* Hour lines */}
                {hours.map((hour) => (
                  <div key={hour} className="h-16 border-b border-slate-100" />
                ))}

                {/* Current time indicator */}
                {isToday(currentDate) && (
                  <div
                    className="absolute left-0 right-0 border-t-2 border-red-500 z-10"
                    style={{
                      top: `${((new Date().getHours() - 7) * 60 + new Date().getMinutes()) * (64 / 60)}px`,
                    }}
                  >
                    <div className="w-2 h-2 bg-red-500 rounded-full -mt-1 -ml-1" />
                  </div>
                )}

                {/* Events */}
                {getEventsForDay(currentDate).map((event) => {
                  const top = getTimeSlotPosition(event.startTime) * (64 / 60);
                  const height = getEventDuration(event.startTime, event.endTime) * (64 / 60);
                  const colors = householdColorConfig[event.householdId];

                  return (
                    <div
                      key={event.id}
                      onClick={() => setSelectedEvent(event)}
                      className={`absolute left-2 right-2 rounded-md border-l-4 px-3 py-2 cursor-pointer hover:shadow-md transition-shadow ${colors.bgColor} ${colors.borderColor}`}
                      style={{ top: `${top}px`, height: `${height}px` }}
                    >
                      <div className={`font-medium text-sm truncate ${colors.color}`}>
                        {event.title}
                      </div>
                      <div className="text-xs text-slate-500 truncate">
                        {event.householdName} • {formatTime(event.startTime)} - {formatTime(event.endTime)}
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          </div>
        )}

        {/* Week View */}
        {view === 'week' && (
          <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
            {/* Day Headers */}
            <div className="grid grid-cols-[80px_repeat(7,1fr)] border-b border-slate-200">
              <div className="p-3 bg-slate-50" />
              {weekDays.map((day) => (
                <div
                  key={day.toISOString()}
                  className={`p-3 text-center border-l border-slate-200 ${
                    isToday(day) ? 'bg-indigo-50' : 'bg-slate-50'
                  }`}
                >
                  <div className="text-xs text-slate-500 uppercase">
                    {day.toLocaleDateString('en-US', { weekday: 'short' })}
                  </div>
                  <div
                    className={`text-lg font-semibold ${
                      isToday(day) ? 'text-indigo-600' : 'text-slate-900'
                    }`}
                  >
                    {day.getDate()}
                  </div>
                </div>
              ))}
            </div>

            {/* Time Grid */}
            <div className="grid grid-cols-[80px_repeat(7,1fr)]">
              {/* Time Column */}
              <div>
                {hours.map((hour) => (
                  <div key={hour} className="h-16 border-b border-slate-100 pr-3 text-right">
                    <span className="text-xs text-slate-400 -mt-2 block">
                      {hour === 12 ? '12 PM' : hour > 12 ? `${hour - 12} PM` : `${hour} AM`}
                    </span>
                  </div>
                ))}
              </div>

              {/* Day Columns */}
              {weekDays.map((day) => (
                <div key={day.toISOString()} className="relative border-l border-slate-200">
                  {/* Hour lines */}
                  {hours.map((hour) => (
                    <div key={hour} className="h-16 border-b border-slate-100" />
                  ))}

                  {/* Current time indicator */}
                  {isToday(day) && (
                    <div
                      className="absolute left-0 right-0 border-t-2 border-red-500 z-10"
                      style={{
                        top: `${((new Date().getHours() - 7) * 60 + new Date().getMinutes()) * (64 / 60)}px`,
                      }}
                    >
                      <div className="w-2 h-2 bg-red-500 rounded-full -mt-1 -ml-1" />
                    </div>
                  )}

                  {/* Events */}
                  {getEventsForDay(day).map((event) => {
                    const top = getTimeSlotPosition(event.startTime) * (64 / 60);
                    const height = getEventDuration(event.startTime, event.endTime) * (64 / 60);
                    const colors = householdColorConfig[event.householdId];

                    return (
                      <div
                        key={event.id}
                        onClick={() => setSelectedEvent(event)}
                        className={`absolute left-1 right-1 rounded-md border-l-4 px-2 py-1 cursor-pointer hover:shadow-md transition-shadow overflow-hidden ${colors.bgColor} ${colors.borderColor}`}
                        style={{ top: `${top}px`, height: `${Math.max(height, 24)}px` }}
                      >
                        <div className={`font-medium text-xs truncate ${colors.color}`}>
                          {event.title}
                        </div>
                        {height >= 40 && (
                          <div className="text-xs text-slate-500 truncate">
                            {formatTime(event.startTime)}
                          </div>
                        )}
                      </div>
                    );
                  })}
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Month View */}
        {view === 'month' && (
          <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
            {/* Day Headers */}
            <div className="grid grid-cols-7 border-b border-slate-200">
              {['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) => (
                <div key={day} className="p-3 text-center bg-slate-50 text-xs font-medium text-slate-500 uppercase">
                  {day}
                </div>
              ))}
            </div>

            {/* Calendar Grid */}
            <div className="grid grid-cols-7">
              {monthDays.map((day, index) => {
                const dayEvents = day ? getEventsForDay(day) : [];
                const isCurrentMonth = day && day.getMonth() === currentDate.getMonth();

                return (
                  <div
                    key={index}
                    className={`min-h-[120px] border-b border-r border-slate-100 p-2 ${
                      !isCurrentMonth ? 'bg-slate-50' : ''
                    } ${day && isToday(day) ? 'bg-indigo-50' : ''}`}
                  >
                    {day && (
                      <>
                        <div
                          className={`text-sm font-medium mb-1 ${
                            isToday(day)
                              ? 'text-indigo-600'
                              : isCurrentMonth
                              ? 'text-slate-900'
                              : 'text-slate-400'
                          }`}
                        >
                          {day.getDate()}
                        </div>
                        <div className="space-y-1">
                          {dayEvents.slice(0, 3).map((event) => {
                            const colors = householdColorConfig[event.householdId];
                            return (
                              <div
                                key={event.id}
                                onClick={() => setSelectedEvent(event)}
                                className={`text-xs px-2 py-1 rounded truncate cursor-pointer hover:shadow-sm transition-shadow ${colors.bgColor} ${colors.color}`}
                              >
                                {event.title}
                              </div>
                            );
                          })}
                          {dayEvents.length > 3 && (
                            <div className="text-xs text-slate-500 pl-2">
                              +{dayEvents.length - 3} more
                            </div>
                          )}
                        </div>
                      </>
                    )}
                  </div>
                );
              })}
            </div>
          </div>
        )}

        {/* Legend */}
        <div className="mt-6 bg-white rounded-xl shadow-sm border border-slate-200 p-4">
          <div className="flex items-center gap-2 mb-3">
            <Filter className="w-4 h-4 text-slate-500" />
            <span className="text-sm font-medium text-slate-700">Legend</span>
          </div>
          <div className="flex flex-wrap gap-4">
            <div className="text-xs text-slate-500 font-medium">Households:</div>
            {Object.entries(householdColorConfig).map(([id, config]) => (
              <div key={id} className="flex items-center gap-2">
                <div className={`w-3 h-3 rounded ${config.bgColor} border-l-4 ${config.borderColor}`} />
                <span className="text-xs text-slate-600">{householdNames[id as HouseholdId]}</span>
              </div>
            ))}
          </div>
          <div className="flex flex-wrap gap-4 mt-2">
            <div className="text-xs text-slate-500 font-medium">Event Types:</div>
            {Object.entries(eventTypeConfig).map(([type, config]) => (
              <div key={type} className="flex items-center gap-2">
                <div className={`w-3 h-3 rounded ${config.bgColor}`} />
                <span className="text-xs text-slate-600">{config.label}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Event Detail Modal */}
      {selectedEvent && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-xl shadow-xl max-w-lg w-full max-h-[90vh] overflow-y-auto">
            <div className="p-6">
              {/* Header */}
              <div className="flex items-start justify-between mb-4">
                <div>
                  <h3 className="text-xl font-semibold text-slate-900">{selectedEvent.title}</h3>
                  <p className="text-sm text-slate-500">
                    {selectedEvent.householdName} - {selectedEvent.address}
                  </p>
                </div>
                <button
                  onClick={() => setSelectedEvent(null)}
                  className="p-2 text-slate-400 hover:text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              <hr className="border-slate-200 mb-4" />

              {/* Details */}
              <div className="space-y-3">
                <div className="flex items-center gap-3 text-sm">
                  <CalendarIcon className="w-4 h-4 text-slate-400" />
                  <span className="text-slate-700">
                    {formatDate(selectedEvent.date)}, {formatTime(selectedEvent.startTime)} - {formatTime(selectedEvent.endTime)}
                  </span>
                </div>

                {selectedEvent.vendor && (
                  <div className="flex items-center gap-3 text-sm">
                    <Wrench className="w-4 h-4 text-slate-400" />
                    <span className="text-slate-700">
                      Vendor: {selectedEvent.vendor.name} ({selectedEvent.vendor.contact})
                    </span>
                  </div>
                )}

                {selectedEvent.workOrderId && (
                  <div className="flex items-center gap-3 text-sm">
                    <FileText className="w-4 h-4 text-slate-400" />
                    <span className="text-slate-700">Work Order: {selectedEvent.workOrderId}</span>
                  </div>
                )}

                <div className="flex items-center gap-3 text-sm">
                  <MapPin className="w-4 h-4 text-slate-400" />
                  <span className="text-slate-700">{selectedEvent.address}</span>
                </div>

                {selectedEvent.accessInfo && (
                  <>
                    <hr className="border-slate-200" />
                    <div className="bg-amber-50 border border-amber-200 rounded-lg p-3">
                      <div className="flex items-center gap-2 text-sm font-medium text-amber-800 mb-1">
                        <AlertTriangle className="w-4 h-4" />
                        Access Info
                      </div>
                      <p className="text-sm text-amber-700">{selectedEvent.accessInfo}</p>
                    </div>
                  </>
                )}

                {selectedEvent.notes && (
                  <div className="bg-slate-50 rounded-lg p-3">
                    <p className="text-sm text-slate-600">{selectedEvent.notes}</p>
                  </div>
                )}
              </div>

              <hr className="border-slate-200 my-4" />

              {/* Actions */}
              <div className="flex flex-wrap gap-2">
                {selectedEvent.workOrderId && (
                  <button className="flex items-center gap-2 px-3 py-2 text-sm font-medium text-indigo-600 bg-indigo-50 hover:bg-indigo-100 rounded-lg transition-colors">
                    <ExternalLink className="w-4 h-4" />
                    View Work Order
                  </button>
                )}
                <button className="flex items-center gap-2 px-3 py-2 text-sm font-medium text-slate-600 bg-slate-100 hover:bg-slate-200 rounded-lg transition-colors">
                  <MessageCircle className="w-4 h-4" />
                  Message Homeowner
                </button>
                <button className="flex items-center gap-2 px-3 py-2 text-sm font-medium text-slate-600 bg-slate-100 hover:bg-slate-200 rounded-lg transition-colors">
                  <Navigation className="w-4 h-4" />
                  Get Directions
                </button>
                <button className="flex items-center gap-2 px-3 py-2 text-sm font-medium text-slate-600 bg-slate-100 hover:bg-slate-200 rounded-lg transition-colors">
                  <Clock className="w-4 h-4" />
                  Edit
                </button>
                <button className="flex items-center gap-2 px-3 py-2 text-sm font-medium text-red-600 bg-red-50 hover:bg-red-100 rounded-lg transition-colors">
                  <X className="w-4 h-4" />
                  Delete
                </button>
              </div>

              {/* Travel Time Suggestion */}
              <div className="mt-4 bg-blue-50 border border-blue-200 rounded-lg p-3">
                <div className="flex items-center gap-2 text-sm font-medium text-blue-800 mb-1">
                  <Car className="w-4 h-4" />
                  Travel Time
                </div>
                <p className="text-sm text-blue-700">
                  ~15 min drive from previous appointment. Leave by {formatTime(
                    (() => {
                      const parts = selectedEvent.startTime.split(':').map(Number);
                      const h = parts[0] ?? 0;
                      const m = parts[1] ?? 0;
                      const totalMinutes = h * 60 + m - 15;
                      return `${Math.floor(totalMinutes / 60).toString().padStart(2, '0')}:${(totalMinutes % 60).toString().padStart(2, '0')}`;
                    })()
                  )} to arrive on time.
                </p>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Add Event Modal */}
      {showAddModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-xl shadow-xl max-w-lg w-full max-h-[90vh] overflow-y-auto">
            <div className="p-6">
              {/* Header */}
              <div className="flex items-center justify-between mb-6">
                <h3 className="text-xl font-semibold text-slate-900">Add New Event</h3>
                <button
                  onClick={() => setShowAddModal(false)}
                  className="p-2 text-slate-400 hover:text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              {/* Form */}
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">
                    Event Title
                  </label>
                  <input
                    type="text"
                    value={newEvent.title}
                    onChange={(e) => setNewEvent({ ...newEvent, title: e.target.value })}
                    className="w-full px-3 py-2 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                    placeholder="Enter event title"
                  />
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">
                      Event Type
                    </label>
                    <select
                      value={newEvent.type}
                      onChange={(e) => setNewEvent({ ...newEvent, type: e.target.value as EventType })}
                      className="w-full px-3 py-2 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                    >
                      {Object.entries(eventTypeConfig).map(([type, config]) => (
                        <option key={type} value={type}>{config.label}</option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">
                      Household
                    </label>
                    <select
                      value={newEvent.householdId}
                      onChange={(e) => setNewEvent({ ...newEvent, householdId: e.target.value as HouseholdId })}
                      className="w-full px-3 py-2 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                    >
                      {Object.entries(householdNames).map(([id, name]) => (
                        <option key={id} value={id}>{name}</option>
                      ))}
                    </select>
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">
                    Date
                  </label>
                  <input
                    type="date"
                    value={newEvent.date}
                    onChange={(e) => setNewEvent({ ...newEvent, date: e.target.value })}
                    className="w-full px-3 py-2 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                  />
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">
                      Start Time
                    </label>
                    <input
                      type="time"
                      value={newEvent.startTime}
                      onChange={(e) => setNewEvent({ ...newEvent, startTime: e.target.value })}
                      className="w-full px-3 py-2 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">
                      End Time
                    </label>
                    <input
                      type="time"
                      value={newEvent.endTime}
                      onChange={(e) => setNewEvent({ ...newEvent, endTime: e.target.value })}
                      className="w-full px-3 py-2 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">
                    Link to Work Order (Optional)
                  </label>
                  <input
                    type="text"
                    value={newEvent.workOrderId}
                    onChange={(e) => setNewEvent({ ...newEvent, workOrderId: e.target.value })}
                    className="w-full px-3 py-2 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                    placeholder="e.g., WO-1892"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">
                    Notes
                  </label>
                  <textarea
                    value={newEvent.notes}
                    onChange={(e) => setNewEvent({ ...newEvent, notes: e.target.value })}
                    rows={3}
                    className="w-full px-3 py-2 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                    placeholder="Add any additional notes..."
                  />
                </div>

                {/* Suggested Time Slots */}
                <div className="bg-indigo-50 border border-indigo-200 rounded-lg p-3">
                  <div className="text-sm font-medium text-indigo-800 mb-2">Suggested Time Slots</div>
                  <div className="flex flex-wrap gap-2">
                    <button
                      onClick={() => setNewEvent({ ...newEvent, startTime: '09:00', endTime: '10:00' })}
                      className="px-3 py-1 text-xs font-medium text-indigo-600 bg-white border border-indigo-200 rounded-lg hover:bg-indigo-50 transition-colors"
                    >
                      9:00 AM - 10:00 AM
                    </button>
                    <button
                      onClick={() => setNewEvent({ ...newEvent, startTime: '14:00', endTime: '15:00' })}
                      className="px-3 py-1 text-xs font-medium text-indigo-600 bg-white border border-indigo-200 rounded-lg hover:bg-indigo-50 transition-colors"
                    >
                      2:00 PM - 3:00 PM
                    </button>
                    <button
                      onClick={() => setNewEvent({ ...newEvent, startTime: '16:00', endTime: '17:00' })}
                      className="px-3 py-1 text-xs font-medium text-indigo-600 bg-white border border-indigo-200 rounded-lg hover:bg-indigo-50 transition-colors"
                    >
                      4:00 PM - 5:00 PM
                    </button>
                  </div>
                  <p className="text-xs text-indigo-600 mt-2">Based on your schedule and location</p>
                </div>
              </div>

              {/* Actions */}
              <div className="flex justify-end gap-3 mt-6">
                <button
                  onClick={() => setShowAddModal(false)}
                  className="px-4 py-2 text-sm font-medium text-slate-600 hover:text-slate-800 transition-colors"
                >
                  Cancel
                </button>
                <button
                  onClick={() => {
                    // In real app, would save the event
                    setShowAddModal(false);
                  }}
                  className="px-4 py-2 text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg transition-colors"
                >
                  Add Event
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
