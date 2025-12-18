'use client';

import { useState, useEffect } from 'react';
import { useApi } from '@/lib/api';
import Link from 'next/link';
import type { TripPipeline, TripListItem, TripStatus } from '@haven/core';
import {
  PaperAirplaneIcon,
  CalendarIcon,
  UserIcon,
  ClockIcon,
  ArrowRightIcon,
} from '@heroicons/react/24/outline';

const PIPELINE_COLUMNS: { status: TripStatus; label: string; color: string }[] = [
  { status: 'INQUIRY', label: 'Inquiries', color: 'bg-gray-500' },
  { status: 'PROPOSAL_SENT', label: 'Proposals Out', color: 'bg-emerald-500' },
  { status: 'PENDING_SELECTION', label: 'Awaiting Selection', color: 'bg-yellow-500' },
  { status: 'BOOKED', label: 'Booked', color: 'bg-green-500' },
  { status: 'ACTIVE', label: 'In Progress', color: 'bg-purple-500' },
];

export default function TravelDeskPage() {
  const api = useApi();
  const [pipeline, setPipeline] = useState<TripPipeline | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadPipeline() {
      try {
        const data = await api.getTripPipeline();
        setPipeline(data);
      } catch (error) {
        console.error('Failed to load pipeline:', error);
      } finally {
        setLoading(false);
      }
    }
    loadPipeline();
  }, [api]);

  const daysUntilDeparture = (startDate: string) => {
    const now = new Date();
    const departure = new Date(startDate);
    const diff = departure.getTime() - now.getTime();
    return Math.ceil(diff / (1000 * 60 * 60 * 24));
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-100 dark:bg-gray-900 p-6">
        <div className="animate-pulse space-y-4">
          <div className="h-8 bg-gray-200 dark:bg-gray-700 rounded w-48"></div>
          <div className="flex space-x-4 overflow-x-auto">
            {[1, 2, 3, 4, 5].map((i) => (
              <div key={i} className="w-72 flex-shrink-0">
                <div className="h-10 bg-gray-200 dark:bg-gray-700 rounded mb-4"></div>
                <div className="space-y-3">
                  <div className="h-32 bg-gray-200 dark:bg-gray-700 rounded"></div>
                  <div className="h-32 bg-gray-200 dark:bg-gray-700 rounded"></div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-100 dark:bg-gray-900 p-6">
      {/* Header */}
      <div className="flex justify-between items-center mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Travel Desk</h1>
          <p className="text-gray-500 dark:text-gray-400">Manage trip requests and bookings</p>
        </div>
        <Link
          href="/manager/travel/protocols"
          className="bg-emerald-600 text-white px-4 py-2 rounded-lg hover:bg-emerald-700 flex items-center space-x-2"
        >
          <span>Protocol Enforcer</span>
          <ArrowRightIcon className="h-4 w-4" />
        </Link>
      </div>

      {/* Kanban Board */}
      <div className="flex space-x-4 overflow-x-auto pb-4">
        {PIPELINE_COLUMNS.map((column) => {
          const trips = pipeline?.[column.status] || [];
          return (
            <div key={column.status} className="w-72 flex-shrink-0">
              {/* Column Header */}
              <div className="flex items-center space-x-2 mb-4">
                <div className={`w-3 h-3 rounded-full ${column.color}`}></div>
                <h2 className="font-semibold text-gray-900 dark:text-white">{column.label}</h2>
                <span className="text-sm text-gray-500 dark:text-gray-400">({trips.length})</span>
              </div>

              {/* Cards */}
              <div className="space-y-3">
                {trips.length === 0 ? (
                  <div className="bg-white dark:bg-gray-800 rounded-lg p-4 text-center text-gray-400 dark:text-gray-500 text-sm border-2 border-dashed border-gray-200 dark:border-gray-700">
                    No trips
                  </div>
                ) : (
                  trips.map((trip) => (
                    <TripCard key={trip.id} trip={trip} daysUntil={daysUntilDeparture(trip.startDate)} />
                  ))
                )}
              </div>
            </div>
          );
        })}
      </div>

      {/* Stats */}
      <div className="mt-8 grid grid-cols-4 gap-4">
        <StatCard
          label="Total Active"
          value={(pipeline?.INQUIRY?.length || 0) + (pipeline?.PROPOSAL_SENT?.length || 0) + (pipeline?.PENDING_SELECTION?.length || 0)}
          color="text-emerald-600"
        />
        <StatCard
          label="Booked"
          value={pipeline?.BOOKED?.length || 0}
          color="text-green-600"
        />
        <StatCard
          label="In Progress"
          value={pipeline?.ACTIVE?.length || 0}
          color="text-purple-600"
        />
        <StatCard
          label="Completed"
          value={pipeline?.COMPLETED?.length || 0}
          color="text-gray-600"
        />
      </div>
    </div>
  );
}

function TripCard({ trip, daysUntil }: { trip: TripListItem; daysUntil: number }) {
  const isUrgent = daysUntil >= 0 && daysUntil <= 7;

  return (
    <Link href={`/manager/travel/trips/${trip.id}`}>
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-4 hover:shadow-md transition-shadow cursor-pointer">
        <div className="flex justify-between items-start mb-2">
          <div>
            <p className="font-medium text-gray-900 dark:text-white">{trip.household?.name}</p>
            <p className="text-sm text-emerald-600 dark:text-emerald-400">{trip.destination}</p>
          </div>
          {isUrgent && daysUntil >= 0 && (
            <span className="text-xs bg-red-100 text-red-700 dark:bg-red-900 dark:text-red-300 px-2 py-0.5 rounded">
              {daysUntil === 0 ? 'Today!' : `${daysUntil}d`}
            </span>
          )}
        </div>

        <div className="text-xs text-gray-500 dark:text-gray-400 space-y-1">
          <div className="flex items-center">
            <CalendarIcon className="h-3.5 w-3.5 mr-1" />
            {new Date(trip.startDate).toLocaleDateString()} - {new Date(trip.endDate).toLocaleDateString()}
          </div>
          <div className="flex items-center">
            <UserIcon className="h-3.5 w-3.5 mr-1" />
            {trip.travelerCount} traveler{trip.travelerCount > 1 ? 's' : ''}
          </div>
          {(trip.budgetMin || trip.budgetMax) && (
            <div className="flex items-center">
              <span className="mr-1">$</span>
              {trip.budgetMax
                ? `Up to $${trip.budgetMax.toLocaleString()}`
                : `From $${trip.budgetMin?.toLocaleString()}`}
            </div>
          )}
        </div>

        {/* Progress indicators */}
        <div className="mt-3 flex items-center justify-between text-xs text-gray-400">
          <span>{trip._count?.proposals || 0} proposals</span>
          <span>{trip._count?.itineraryItems || 0} items</span>
        </div>

        {trip.assignedManager ? (
          <div className="mt-2 text-xs text-gray-500 dark:text-gray-400 flex items-center">
            <span className="inline-block w-2 h-2 rounded-full bg-green-500 mr-1.5"></span>
            {trip.assignedManager.displayName}
          </div>
        ) : (
          <div className="mt-2 text-xs text-yellow-600 dark:text-yellow-400">
            Unassigned
          </div>
        )}
      </div>
    </Link>
  );
}

function StatCard({ label, value, color }: { label: string; value: number; color: string }) {
  return (
    <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-4">
      <p className="text-sm text-gray-500 dark:text-gray-400">{label}</p>
      <p className={`text-2xl font-bold ${color}`}>{value}</p>
    </div>
  );
}
