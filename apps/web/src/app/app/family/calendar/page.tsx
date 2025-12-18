'use client';

import { useState, useEffect } from 'react';
import { useApi } from '@/lib/api';
import type { CalendarEvent, CalendarFeedUrlResponse, FamilyEventCategory } from '@haven/core';
import {
  CalendarIcon,
  PlusIcon,
  ChevronLeftIcon,
  ChevronRightIcon,
  ClipboardDocumentIcon,
  CheckIcon,
  WrenchScrewdriverIcon,
} from '@heroicons/react/24/outline';

const categoryColors: Record<string, string> = {
  SCHOOL: 'bg-emerald-500',
  MEDICAL: 'bg-red-500',
  SPORTS: 'bg-green-500',
  SOCIAL: 'bg-purple-500',
  WORK: 'bg-indigo-500',
  TRAVEL: 'bg-cyan-500',
  MAINTENANCE: 'bg-amber-500',
  FINANCIAL: 'bg-lime-500',
  RELIGIOUS: 'bg-violet-500',
  BIRTHDAY: 'bg-pink-500',
  HOLIDAY: 'bg-orange-500',
  OTHER: 'bg-gray-500',
};

const categoryLabels: Record<string, string> = {
  SCHOOL: 'School',
  MEDICAL: 'Medical',
  SPORTS: 'Sports',
  SOCIAL: 'Social',
  WORK: 'Work',
  TRAVEL: 'Travel',
  MAINTENANCE: 'Maintenance',
  FINANCIAL: 'Financial',
  RELIGIOUS: 'Religious',
  BIRTHDAY: 'Birthday',
  HOLIDAY: 'Holiday',
  OTHER: 'Other',
};

export default function FamilyCalendarPage() {
  const api = useApi();
  const [events, setEvents] = useState<CalendarEvent[]>([]);
  const [loading, setLoading] = useState(true);
  const [currentDate, setCurrentDate] = useState(new Date());
  const [feedUrl, setFeedUrl] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);
  const [selectedEvent, setSelectedEvent] = useState<CalendarEvent | null>(null);
  const [includeMaintenance, setIncludeMaintenance] = useState(true);

  const getMonthDates = () => {
    const year = currentDate.getFullYear();
    const month = currentDate.getMonth();
    const firstDay = new Date(year, month, 1);
    const lastDay = new Date(year, month + 1, 0);
    const startDate = new Date(firstDay);
    startDate.setDate(startDate.getDate() - firstDay.getDay());
    const endDate = new Date(lastDay);
    endDate.setDate(endDate.getDate() + (6 - lastDay.getDay()));
    return { startDate, endDate, firstDay, lastDay };
  };

  useEffect(() => {
    async function loadData() {
      try {
        const { startDate, endDate } = getMonthDates();
        const [eventsData, feedUrlData] = await Promise.all([
          api.getUnifiedCalendar({
            startDate: startDate.toISOString(),
            endDate: endDate.toISOString(),
            includeMaintenance,
          }),
          api.getCalendarFeedUrl(),
        ]);
        setEvents(eventsData);
        setFeedUrl(feedUrlData.url);
      } catch (error) {
        console.error('Failed to load calendar:', error);
      } finally {
        setLoading(false);
      }
    }
    loadData();
  }, [api, currentDate, includeMaintenance]);

  const copyFeedUrl = async () => {
    if (feedUrl) {
      await navigator.clipboard.writeText(feedUrl);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    }
  };

  const goToPrevMonth = () => {
    setCurrentDate(new Date(currentDate.getFullYear(), currentDate.getMonth() - 1, 1));
  };

  const goToNextMonth = () => {
    setCurrentDate(new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 1));
  };

  const goToToday = () => {
    setCurrentDate(new Date());
  };

  const getEventsForDate = (date: Date) => {
    return events.filter((event) => {
      const eventDate = new Date(event.start);
      return (
        eventDate.getDate() === date.getDate() &&
        eventDate.getMonth() === date.getMonth() &&
        eventDate.getFullYear() === date.getFullYear()
      );
    });
  };

  const renderCalendar = () => {
    const { startDate, firstDay, lastDay } = getMonthDates();
    const days = [];
    const current = new Date(startDate);

    while (current <= new Date(startDate.getTime() + 41 * 24 * 60 * 60 * 1000)) {
      days.push(new Date(current));
      current.setDate(current.getDate() + 1);
    }

    const today = new Date();

    return (
      <div className="grid grid-cols-7 gap-px bg-gray-200 dark:bg-gray-700 rounded-lg overflow-hidden">
        {/* Header */}
        {['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((day) => (
          <div
            key={day}
            className="bg-gray-100 dark:bg-gray-800 p-2 text-center text-sm font-medium text-gray-500 dark:text-gray-400"
          >
            {day}
          </div>
        ))}

        {/* Days */}
        {days.slice(0, 42).map((date, idx) => {
          const dayEvents = getEventsForDate(date);
          const isCurrentMonth = date.getMonth() === currentDate.getMonth();
          const isToday =
            date.getDate() === today.getDate() &&
            date.getMonth() === today.getMonth() &&
            date.getFullYear() === today.getFullYear();

          return (
            <div
              key={idx}
              className={`min-h-[100px] bg-white dark:bg-gray-800 p-1 ${
                !isCurrentMonth ? 'opacity-50' : ''
              }`}
            >
              <div
                className={`text-sm font-medium mb-1 w-7 h-7 flex items-center justify-center rounded-full ${
                  isToday
                    ? 'bg-emerald-600 text-white'
                    : 'text-gray-900 dark:text-white'
                }`}
              >
                {date.getDate()}
              </div>
              <div className="space-y-1">
                {dayEvents.slice(0, 3).map((event) => (
                  <button
                    key={event.id}
                    onClick={() => setSelectedEvent(event)}
                    className={`w-full text-left text-xs px-1 py-0.5 rounded truncate text-white ${
                      event.type === 'maintenance'
                        ? 'bg-amber-500'
                        : categoryColors[event.category] || 'bg-gray-500'
                    }`}
                  >
                    {event.type === 'maintenance' && (
                      <WrenchScrewdriverIcon className="h-3 w-3 inline mr-0.5" />
                    )}
                    {event.title}
                  </button>
                ))}
                {dayEvents.length > 3 && (
                  <div className="text-xs text-gray-500 dark:text-gray-400 text-center">
                    +{dayEvents.length - 3} more
                  </div>
                )}
              </div>
            </div>
          );
        })}
      </div>
    );
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 dark:bg-gray-900 p-6">
        <div className="animate-pulse space-y-4">
          <div className="h-8 bg-gray-200 dark:bg-gray-700 rounded w-48"></div>
          <div className="h-96 bg-gray-200 dark:bg-gray-700 rounded-lg"></div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900 p-6">
      <div className="max-w-7xl mx-auto space-y-6">
        {/* Header */}
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
          <div>
            <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Family Calendar</h1>
            <p className="text-gray-500 dark:text-gray-400">
              All your family events and home maintenance in one place
            </p>
          </div>
          <div className="flex items-center space-x-2">
            <button
              onClick={copyFeedUrl}
              className="inline-flex items-center px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700"
            >
              {copied ? (
                <>
                  <CheckIcon className="h-4 w-4 mr-2 text-green-500" />
                  Copied!
                </>
              ) : (
                <>
                  <ClipboardDocumentIcon className="h-4 w-4 mr-2" />
                  Copy iCal URL
                </>
              )}
            </button>
            <button className="inline-flex items-center px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700">
              <PlusIcon className="h-5 w-5 mr-2" />
              Add Event
            </button>
          </div>
        </div>

        {/* Calendar Navigation */}
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-4">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center space-x-4">
              <button
                onClick={goToPrevMonth}
                className="p-2 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg"
              >
                <ChevronLeftIcon className="h-5 w-5 text-gray-600 dark:text-gray-300" />
              </button>
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white">
                {currentDate.toLocaleDateString(undefined, { month: 'long', year: 'numeric' })}
              </h2>
              <button
                onClick={goToNextMonth}
                className="p-2 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg"
              >
                <ChevronRightIcon className="h-5 w-5 text-gray-600 dark:text-gray-300" />
              </button>
            </div>
            <div className="flex items-center space-x-4">
              <button
                onClick={goToToday}
                className="px-3 py-1 text-sm border border-gray-300 dark:border-gray-600 rounded-lg text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700"
              >
                Today
              </button>
              <label className="flex items-center space-x-2 text-sm text-gray-700 dark:text-gray-300">
                <input
                  type="checkbox"
                  checked={includeMaintenance}
                  onChange={(e) => setIncludeMaintenance(e.target.checked)}
                  className="rounded border-gray-300 text-emerald-600 focus:ring-emerald-500"
                />
                <span>Show Maintenance</span>
              </label>
            </div>
          </div>

          {renderCalendar()}
        </div>

        {/* Category Legend */}
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-4">
          <h3 className="text-sm font-medium text-gray-900 dark:text-white mb-3">Categories</h3>
          <div className="flex flex-wrap gap-3">
            {Object.entries(categoryColors).map(([key, color]) => (
              <div key={key} className="flex items-center space-x-2">
                <div className={`w-3 h-3 rounded ${color}`}></div>
                <span className="text-sm text-gray-600 dark:text-gray-300">
                  {categoryLabels[key]}
                </span>
              </div>
            ))}
          </div>
        </div>

        {/* Event Detail Modal */}
        {selectedEvent && (
          <div
            className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4"
            onClick={() => setSelectedEvent(null)}
          >
            <div
              className="bg-white dark:bg-gray-800 rounded-xl max-w-md w-full"
              onClick={(e) => e.stopPropagation()}
            >
              <div
                className={`p-4 rounded-t-xl text-white ${
                  selectedEvent.type === 'maintenance'
                    ? 'bg-amber-500'
                    : categoryColors[selectedEvent.category] || 'bg-gray-500'
                }`}
              >
                <div className="flex items-center space-x-2">
                  {selectedEvent.type === 'maintenance' && (
                    <WrenchScrewdriverIcon className="h-5 w-5" />
                  )}
                  <h2 className="text-lg font-semibold">{selectedEvent.title}</h2>
                </div>
                <p className="text-sm opacity-90">
                  {categoryLabels[selectedEvent.category] || selectedEvent.category}
                </p>
              </div>

              <div className="p-4 space-y-4">
                <div>
                  <p className="text-sm text-gray-500 dark:text-gray-400">Date & Time</p>
                  <p className="font-medium text-gray-900 dark:text-white">
                    {new Date(selectedEvent.start).toLocaleDateString(undefined, {
                      weekday: 'long',
                      year: 'numeric',
                      month: 'long',
                      day: 'numeric',
                    })}
                  </p>
                  {!selectedEvent.allDay && (
                    <p className="text-gray-600 dark:text-gray-300">
                      {new Date(selectedEvent.start).toLocaleTimeString(undefined, {
                        hour: 'numeric',
                        minute: '2-digit',
                      })}
                      {selectedEvent.end && (
                        <>
                          {' '}
                          -{' '}
                          {new Date(selectedEvent.end).toLocaleTimeString(undefined, {
                            hour: 'numeric',
                            minute: '2-digit',
                          })}
                        </>
                      )}
                    </p>
                  )}
                </div>

                {selectedEvent.meta?.description && (
                  <div>
                    <p className="text-sm text-gray-500 dark:text-gray-400">Description</p>
                    <p className="text-gray-900 dark:text-white">{selectedEvent.meta.description}</p>
                  </div>
                )}

                {selectedEvent.meta?.location && (
                  <div>
                    <p className="text-sm text-gray-500 dark:text-gray-400">Location</p>
                    <p className="text-gray-900 dark:text-white">{selectedEvent.meta.location}</p>
                  </div>
                )}

                {selectedEvent.meta?.assignedTo && (
                  <div>
                    <p className="text-sm text-gray-500 dark:text-gray-400">Assigned To</p>
                    <p className="text-gray-900 dark:text-white">{selectedEvent.meta.assignedTo}</p>
                  </div>
                )}

                {selectedEvent.meta?.vendor && (
                  <div>
                    <p className="text-sm text-gray-500 dark:text-gray-400">Vendor</p>
                    <p className="text-gray-900 dark:text-white">{selectedEvent.meta.vendor}</p>
                  </div>
                )}

                <div className="flex space-x-3 pt-4">
                  <button
                    onClick={() => setSelectedEvent(null)}
                    className="flex-1 px-4 py-2 border border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700"
                  >
                    Close
                  </button>
                  <button className="flex-1 px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700">
                    Edit
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
