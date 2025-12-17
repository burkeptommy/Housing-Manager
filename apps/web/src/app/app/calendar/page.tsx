'use client';

import { useState, useEffect } from 'react';
import { useAuth } from '@/contexts/auth-context';
import { getApiClient } from '@/lib/api';
import type { MaintenanceTask, BillAccount } from '@haven/core';

interface CalendarEvent {
  id: string;
  title: string;
  date: Date;
  type: 'maintenance' | 'bill' | 'work_order';
  status?: string;
  amount?: number;
  category?: string;
}

export default function CalendarPage() {
  const { currentHousehold } = useAuth();
  const [currentDate, setCurrentDate] = useState(new Date());
  const [events, setEvents] = useState<CalendarEvent[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [selectedDate, setSelectedDate] = useState<Date | null>(null);

  const api = getApiClient();

  useEffect(() => {
    const loadData = async () => {
      if (!currentHousehold) {
        setIsLoading(false);
        return;
      }

      try {
        const [tasks, bills] = await Promise.all([
          api.getMaintenanceTasks(currentHousehold.id).catch(() => []),
          api.getBillAccounts(currentHousehold.id).catch(() => []),
        ]);

        const calendarEvents: CalendarEvent[] = [];

        // Add maintenance tasks
        (tasks as MaintenanceTask[]).forEach((task) => {
          if (task.dueDate) {
            calendarEvents.push({
              id: task.id,
              title: task.title,
              date: new Date(task.dueDate),
              type: 'maintenance',
              status: task.status,
              category: task.category,
            });
          }
        });

        // Add bill due dates
        (bills as BillAccount[]).forEach((bill) => {
          if (bill.nextDueDate) {
            calendarEvents.push({
              id: bill.id,
              title: bill.nickname || 'Bill Payment',
              date: new Date(bill.nextDueDate),
              type: 'bill',
              amount: bill.typicalAmount || undefined,
              category: bill.category,
            });
          }
        });

        setEvents(calendarEvents);
      } catch (error) {
        console.error('Failed to load calendar data:', error);
      } finally {
        setIsLoading(false);
      }
    };

    loadData();
  }, [api, currentHousehold]);

  const getDaysInMonth = (date: Date) => {
    return new Date(date.getFullYear(), date.getMonth() + 1, 0).getDate();
  };

  const getFirstDayOfMonth = (date: Date) => {
    return new Date(date.getFullYear(), date.getMonth(), 1).getDay();
  };

  const formatMonth = (date: Date) => {
    return date.toLocaleDateString('en-US', { month: 'long', year: 'numeric' });
  };

  const prevMonth = () => {
    setCurrentDate(new Date(currentDate.getFullYear(), currentDate.getMonth() - 1, 1));
  };

  const nextMonth = () => {
    setCurrentDate(new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 1));
  };

  const getEventsForDate = (day: number) => {
    return events.filter((event) => {
      const eventDate = new Date(event.date);
      return (
        eventDate.getDate() === day &&
        eventDate.getMonth() === currentDate.getMonth() &&
        eventDate.getFullYear() === currentDate.getFullYear()
      );
    });
  };

  const isToday = (day: number) => {
    const today = new Date();
    return (
      day === today.getDate() &&
      currentDate.getMonth() === today.getMonth() &&
      currentDate.getFullYear() === today.getFullYear()
    );
  };

  const renderCalendar = () => {
    const daysInMonth = getDaysInMonth(currentDate);
    const firstDay = getFirstDayOfMonth(currentDate);
    const days = [];

    // Empty cells for days before the first of the month
    for (let i = 0; i < firstDay; i++) {
      days.push(<div key={`empty-${i}`} className="h-24 md:h-32 bg-slate-50 dark:bg-slate-800/50"></div>);
    }

    // Days of the month
    for (let day = 1; day <= daysInMonth; day++) {
      const dayEvents = getEventsForDate(day);
      const todayClass = isToday(day) ? 'ring-2 ring-blue-500 ring-inset' : '';

      days.push(
        <div
          key={day}
          onClick={() => setSelectedDate(new Date(currentDate.getFullYear(), currentDate.getMonth(), day))}
          className={`h-24 md:h-32 p-1 border-t border-slate-200 dark:border-slate-700 cursor-pointer hover:bg-slate-50 dark:hover:bg-slate-700/50 ${todayClass}`}
        >
          <div className={`text-sm font-medium mb-1 ${isToday(day) ? 'text-blue-600' : 'text-slate-700 dark:text-slate-300'}`}>
            {day}
          </div>
          <div className="space-y-1 overflow-hidden">
            {dayEvents.slice(0, 3).map((event) => (
              <div
                key={event.id}
                className={`text-xs px-1 py-0.5 rounded truncate ${
                  event.type === 'maintenance'
                    ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400'
                    : 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400'
                }`}
              >
                {event.title}
              </div>
            ))}
            {dayEvents.length > 3 && (
              <div className="text-xs text-slate-500">+{dayEvents.length - 3} more</div>
            )}
          </div>
        </div>
      );
    }

    return days;
  };

  const upcomingEvents = events
    .filter((event) => new Date(event.date) >= new Date())
    .sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime())
    .slice(0, 10);

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  if (!currentHousehold) {
    return (
      <div className="text-center py-12">
        <p className="text-slate-600 dark:text-slate-400">
          Please select or create a household to view the calendar.
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Page header */}
      <div>
        <h1 className="text-2xl font-bold text-slate-900 dark:text-white">Calendar</h1>
        <p className="text-slate-600 dark:text-slate-400 mt-1">
          Track maintenance tasks, bill due dates, and scheduled work.
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
        {/* Calendar Grid */}
        <div className="lg:col-span-3 card">
          {/* Calendar Header */}
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold text-slate-900 dark:text-white">
              {formatMonth(currentDate)}
            </h2>
            <div className="flex items-center gap-2">
              <button
                onClick={prevMonth}
                className="p-2 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-700"
              >
                <svg className="w-5 h-5 text-slate-600 dark:text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
                </svg>
              </button>
              <button
                onClick={() => setCurrentDate(new Date())}
                className="px-3 py-1 text-sm font-medium text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded-lg"
              >
                Today
              </button>
              <button
                onClick={nextMonth}
                className="p-2 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-700"
              >
                <svg className="w-5 h-5 text-slate-600 dark:text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                </svg>
              </button>
            </div>
          </div>

          {/* Day Headers */}
          <div className="grid grid-cols-7 mb-1">
            {['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((day) => (
              <div
                key={day}
                className="text-center text-sm font-medium text-slate-500 dark:text-slate-400 py-2"
              >
                {day}
              </div>
            ))}
          </div>

          {/* Calendar Grid */}
          <div className="grid grid-cols-7 border-l border-slate-200 dark:border-slate-700">
            {renderCalendar().map((cell, index) => (
              <div key={index} className="border-r border-slate-200 dark:border-slate-700">
                {cell}
              </div>
            ))}
          </div>

          {/* Legend */}
          <div className="flex items-center gap-4 mt-4 pt-4 border-t border-slate-200 dark:border-slate-700">
            <div className="flex items-center gap-2">
              <div className="w-3 h-3 rounded bg-green-500"></div>
              <span className="text-sm text-slate-600 dark:text-slate-400">Maintenance</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-3 h-3 rounded bg-blue-500"></div>
              <span className="text-sm text-slate-600 dark:text-slate-400">Bill Due</span>
            </div>
          </div>
        </div>

        {/* Upcoming Events Sidebar */}
        <div className="card h-fit">
          <h3 className="text-lg font-semibold text-slate-900 dark:text-white mb-4">
            Upcoming
          </h3>
          {upcomingEvents.length > 0 ? (
            <div className="space-y-3">
              {upcomingEvents.map((event) => (
                <div
                  key={event.id}
                  className="p-3 rounded-lg bg-slate-50 dark:bg-slate-700/50"
                >
                  <div className="flex items-start justify-between gap-2">
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium text-slate-900 dark:text-white truncate">
                        {event.title}
                      </p>
                      <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
                        {new Date(event.date).toLocaleDateString('en-US', {
                          weekday: 'short',
                          month: 'short',
                          day: 'numeric',
                        })}
                      </p>
                    </div>
                    <span
                      className={`flex-shrink-0 text-xs px-2 py-1 rounded-full ${
                        event.type === 'maintenance'
                          ? 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400'
                          : 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400'
                      }`}
                    >
                      {event.type === 'maintenance' ? 'Task' : 'Bill'}
                    </span>
                  </div>
                  {event.amount && (
                    <p className="text-sm font-medium text-slate-700 dark:text-slate-300 mt-2">
                      ${event.amount.toFixed(2)}
                    </p>
                  )}
                </div>
              ))}
            </div>
          ) : (
            <p className="text-sm text-slate-500 dark:text-slate-400 text-center py-4">
              No upcoming events
            </p>
          )}
        </div>
      </div>

      {/* Selected Date Modal */}
      {selectedDate && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50" onClick={() => setSelectedDate(null)}>
          <div className="bg-white dark:bg-slate-800 rounded-xl shadow-xl max-w-md w-full mx-4 p-6" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-semibold text-slate-900 dark:text-white">
                {selectedDate.toLocaleDateString('en-US', {
                  weekday: 'long',
                  month: 'long',
                  day: 'numeric',
                  year: 'numeric',
                })}
              </h3>
              <button
                onClick={() => setSelectedDate(null)}
                className="p-1 rounded hover:bg-slate-100 dark:hover:bg-slate-700"
              >
                <svg className="w-5 h-5 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>
            {(() => {
              const dayEvents = events.filter((event) => {
                const eventDate = new Date(event.date);
                return (
                  eventDate.getDate() === selectedDate.getDate() &&
                  eventDate.getMonth() === selectedDate.getMonth() &&
                  eventDate.getFullYear() === selectedDate.getFullYear()
                );
              });
              return dayEvents.length > 0 ? (
                <div className="space-y-3">
                  {dayEvents.map((event) => (
                    <div
                      key={event.id}
                      className={`p-3 rounded-lg ${
                        event.type === 'maintenance'
                          ? 'bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800'
                          : 'bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800'
                      }`}
                    >
                      <div className="flex items-center justify-between">
                        <span className="font-medium text-slate-900 dark:text-white">{event.title}</span>
                        <span
                          className={`text-xs px-2 py-1 rounded-full ${
                            event.type === 'maintenance'
                              ? 'bg-green-100 text-green-700 dark:bg-green-900/50 dark:text-green-400'
                              : 'bg-blue-100 text-blue-700 dark:bg-blue-900/50 dark:text-blue-400'
                          }`}
                        >
                          {event.type === 'maintenance' ? 'Maintenance' : 'Bill Due'}
                        </span>
                      </div>
                      {event.category && (
                        <p className="text-sm text-slate-600 dark:text-slate-400 mt-1">{event.category}</p>
                      )}
                      {event.amount && (
                        <p className="text-sm font-medium text-slate-700 dark:text-slate-300 mt-1">
                          Amount: ${event.amount.toFixed(2)}
                        </p>
                      )}
                    </div>
                  ))}
                </div>
              ) : (
                <p className="text-slate-500 dark:text-slate-400 text-center py-4">
                  No events scheduled for this day
                </p>
              );
            })()}
          </div>
        </div>
      )}
    </div>
  );
}
