'use client';

import { useState, useEffect, useCallback } from 'react';

interface ScheduledTask {
  id: string;
  title: string;
  householdName: string;
  householdAddress: string;
  status: string;
  billingType: string;
  scheduledStart: string;
  estimatedMinutes: number;
  taskType: string;
}

interface ScheduleDay {
  date: string;
  tasks: ScheduledTask[];
}

const getDateString = (d: Date): string => d.toISOString().split('T')[0]!;

// Mock data
const mockSchedule: ScheduleDay[] = [
  {
    date: getDateString(new Date()),
    tasks: [
      {
        id: 'wo-101',
        title: 'Change HVAC Filter',
        householdName: 'The Johnson Residence',
        householdAddress: '123 Maple Street, Beverly Hills',
        status: 'ASSIGNED',
        billingType: 'INCLUSIVE',
        scheduledStart: new Date(Date.now() + 2 * 60 * 60 * 1000).toISOString(),
        estimatedMinutes: 30,
        taskType: 'FILTER_CHANGE',
      },
      {
        id: 'wo-102',
        title: 'Fix Loose Cabinet Hinge',
        householdName: 'The Johnson Residence',
        householdAddress: '123 Maple Street, Beverly Hills',
        status: 'ASSIGNED',
        billingType: 'INCLUSIVE',
        scheduledStart: new Date(Date.now() + 3 * 60 * 60 * 1000).toISOString(),
        estimatedMinutes: 20,
        taskType: 'LOOSE_HINGE',
      },
    ],
  },
  {
    date: getDateString(new Date(Date.now() + 24 * 60 * 60 * 1000)),
    tasks: [
      {
        id: 'wo-103',
        title: 'Replace Light Bulbs (High Ceiling)',
        householdName: 'Smith Family Home',
        householdAddress: '456 Oak Avenue, Malibu',
        status: 'ASSIGNED',
        billingType: 'INCLUSIVE',
        scheduledStart: new Date(Date.now() + 28 * 60 * 60 * 1000).toISOString(),
        estimatedMinutes: 45,
        taskType: 'LIGHT_BULB',
      },
      {
        id: 'wo-104',
        title: 'Re-caulk Bathroom',
        householdName: 'Wilson Estate',
        householdAddress: '789 Palm Drive, Pacific Palisades',
        status: 'ASSIGNED',
        billingType: 'INCLUSIVE',
        scheduledStart: new Date(Date.now() + 30 * 60 * 60 * 1000).toISOString(),
        estimatedMinutes: 60,
        taskType: 'CAULKING',
      },
    ],
  },
  {
    date: getDateString(new Date(Date.now() + 2 * 24 * 60 * 60 * 1000)),
    tasks: [
      {
        id: 'wo-105',
        title: 'Monthly Inspection',
        householdName: 'The Garcia Home',
        householdAddress: '321 Sunset Blvd, Hollywood',
        status: 'ASSIGNED',
        billingType: 'INCLUSIVE',
        scheduledStart: new Date(Date.now() + 52 * 60 * 60 * 1000).toISOString(),
        estimatedMinutes: 90,
        taskType: 'GENERAL_INSPECTION',
      },
    ],
  },
];

const STATUS_COLORS: Record<string, string> = {
  ASSIGNED: 'bg-purple-100 text-purple-700',
  IN_PROGRESS: 'bg-orange-100 text-orange-700',
  COMPLETED: 'bg-green-100 text-green-700',
};

export default function HandymanSchedulePage() {
  const [schedule, setSchedule] = useState<ScheduleDay[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [selectedDate, setSelectedDate] = useState<string>(getDateString(new Date()));

  const loadSchedule = useCallback(async () => {
    setIsLoading(true);
    await new Promise((resolve) => setTimeout(resolve, 500));
    setSchedule(mockSchedule);
    setIsLoading(false);
  }, []);

  useEffect(() => {
    loadSchedule();
  }, [loadSchedule]);

  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr);
    const today = new Date();
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    if (dateStr === getDateString(today)) {
      return 'Today';
    } else if (dateStr === getDateString(tomorrow)) {
      return 'Tomorrow';
    }
    return date.toLocaleDateString('en-US', { weekday: 'long', month: 'short', day: 'numeric' });
  };

  const formatTime = (dateStr: string) => {
    return new Date(dateStr).toLocaleTimeString('en-US', {
      hour: 'numeric',
      minute: '2-digit',
    });
  };

  // Generate week dates for date picker
  const getWeekDates = (): string[] => {
    const dates: string[] = [];
    const today = new Date();
    for (let i = 0; i < 7; i++) {
      const date = new Date(today);
      date.setDate(date.getDate() + i);
      dates.push(getDateString(date));
    }
    return dates;
  };

  const weekDates = getWeekDates();

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-teal-600"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-slate-900 dark:text-white">Schedule</h1>
        <p className="text-slate-600 dark:text-slate-400">Your upcoming tasks and appointments</p>
      </div>

      {/* Week Picker */}
      <div className="flex gap-2 overflow-x-auto pb-2">
        {weekDates.map((date) => {
          const dateObj = new Date(date);
          const hasTasksday = schedule.some(d => d.date === date);
          const isSelected = date === selectedDate;
          const isToday = date === getDateString(new Date());

          return (
            <button
              key={date}
              onClick={() => setSelectedDate(date)}
              className={`flex-shrink-0 flex flex-col items-center px-4 py-3 rounded-xl transition-colors ${
                isSelected
                  ? 'bg-teal-600 text-white'
                  : 'bg-white dark:bg-slate-800 text-slate-900 dark:text-white hover:bg-slate-50 dark:hover:bg-slate-700'
              } ${isToday && !isSelected ? 'ring-2 ring-teal-500' : ''}`}
            >
              <span className="text-xs font-medium opacity-70">
                {dateObj.toLocaleDateString('en-US', { weekday: 'short' })}
              </span>
              <span className="text-xl font-bold">{dateObj.getDate()}</span>
              {hasTasksday && (
                <div className={`w-1.5 h-1.5 rounded-full mt-1 ${isSelected ? 'bg-white' : 'bg-teal-500'}`}></div>
              )}
            </button>
          );
        })}
      </div>

      {/* Tasks for Selected Date */}
      {schedule
        .filter(day => day.date === selectedDate)
        .map((day) => (
          <div key={day.date} className="space-y-4">
            <h2 className="text-lg font-semibold text-slate-900 dark:text-white">
              {formatDate(day.date)}
              <span className="ml-2 text-sm font-normal text-slate-500">
                {day.tasks.length} task{day.tasks.length !== 1 ? 's' : ''}
              </span>
            </h2>

            {day.tasks.length === 0 ? (
              <div className="card text-center py-8">
                <svg className="w-10 h-10 mx-auto text-slate-400 mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                </svg>
                <p className="text-slate-600 dark:text-slate-400">No tasks scheduled for this day</p>
              </div>
            ) : (
              <div className="space-y-3">
                {day.tasks.map((task, index) => (
                  <div key={task.id} className="card">
                    <div className="flex items-start gap-4">
                      {/* Time column */}
                      <div className="flex flex-col items-center">
                        <div className="w-12 h-12 rounded-full bg-teal-100 dark:bg-teal-900/30 flex items-center justify-center">
                          <span className="text-sm font-bold text-teal-600 dark:text-teal-400">
                            {formatTime(task.scheduledStart).split(':')[0]}
                          </span>
                        </div>
                        <span className="text-xs text-slate-500 mt-1">
                          {formatTime(task.scheduledStart).split(' ')[1]}
                        </span>
                        {index < day.tasks.length - 1 && (
                          <div className="w-0.5 h-8 bg-slate-200 dark:bg-slate-700 mt-2"></div>
                        )}
                      </div>

                      {/* Task details */}
                      <div className="flex-1">
                        <div className="flex items-center gap-2 mb-1">
                          <h3 className="font-semibold text-slate-900 dark:text-white">{task.title}</h3>
                          <span className={`px-2 py-0.5 rounded text-xs font-medium ${STATUS_COLORS[task.status]}`}>
                            {task.status}
                          </span>
                          {task.billingType === 'INCLUSIVE' && (
                            <span className="px-2 py-0.5 rounded text-xs font-medium bg-teal-100 text-teal-700">
                              CONCIERGE
                            </span>
                          )}
                        </div>
                        <p className="text-sm text-slate-600 dark:text-slate-400">{task.householdName}</p>
                        <p className="text-xs text-slate-500 mt-1">{task.householdAddress}</p>

                        <div className="flex items-center gap-4 mt-3">
                          <span className="flex items-center gap-1 text-sm text-slate-500">
                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                            </svg>
                            {formatTime(task.scheduledStart)}
                          </span>
                          <span className="flex items-center gap-1 text-sm text-slate-500">
                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                            </svg>
                            ~{task.estimatedMinutes} min
                          </span>
                        </div>
                      </div>

                      {/* Navigation */}
                      <button className="p-2 text-slate-400 hover:text-teal-600 hover:bg-teal-50 dark:hover:bg-teal-900/20 rounded-lg transition-colors">
                        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                        </svg>
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        ))}

      {/* No tasks for selected date */}
      {!schedule.some(d => d.date === selectedDate) && (
        <div className="card text-center py-12">
          <svg className="w-12 h-12 mx-auto text-slate-400 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
          </svg>
          <h3 className="text-lg font-medium text-slate-900 dark:text-white mb-2">No tasks scheduled</h3>
          <p className="text-slate-600 dark:text-slate-400">
            You don't have any tasks scheduled for this day.
          </p>
        </div>
      )}

      {/* Weekly Summary */}
      <div className="card">
        <h3 className="font-semibold text-slate-900 dark:text-white mb-4">This Week</h3>
        <div className="grid grid-cols-2 gap-4">
          <div className="p-4 bg-slate-50 dark:bg-slate-700/50 rounded-lg">
            <p className="text-2xl font-bold text-slate-900 dark:text-white">
              {schedule.reduce((sum, day) => sum + day.tasks.length, 0)}
            </p>
            <p className="text-sm text-slate-500">Total Tasks</p>
          </div>
          <div className="p-4 bg-slate-50 dark:bg-slate-700/50 rounded-lg">
            <p className="text-2xl font-bold text-slate-900 dark:text-white">
              {Math.round(schedule.reduce((sum, day) => sum + day.tasks.reduce((s, t) => s + t.estimatedMinutes, 0), 0) / 60)}h
            </p>
            <p className="text-sm text-slate-500">Est. Hours</p>
          </div>
        </div>
      </div>
    </div>
  );
}
