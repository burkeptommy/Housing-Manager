'use client';

import { useState, useEffect } from 'react';
import { useApi } from '@/lib/api';
import Link from 'next/link';
import type { TripListItem, TripProposal, TripStatus } from '@haven/core';
import {
  PaperAirplaneIcon,
  CalendarIcon,
  DocumentTextIcon,
  ShieldCheckIcon,
  PlusIcon,
  ClockIcon,
  ChevronRightIcon,
  ExclamationCircleIcon,
} from '@heroicons/react/24/outline';

const STATUS_COLORS: Record<TripStatus, { bg: string; text: string }> = {
  INQUIRY: { bg: 'bg-gray-100 dark:bg-gray-700', text: 'text-gray-700 dark:text-gray-300' },
  PROPOSAL_SENT: { bg: 'bg-emerald-100 dark:bg-emerald-900', text: 'text-emerald-700 dark:text-emerald-300' },
  PENDING_SELECTION: { bg: 'bg-yellow-100 dark:bg-yellow-900', text: 'text-yellow-700 dark:text-yellow-300' },
  BOOKED: { bg: 'bg-green-100 dark:bg-green-900', text: 'text-green-700 dark:text-green-300' },
  ACTIVE: { bg: 'bg-purple-100 dark:bg-purple-900', text: 'text-purple-700 dark:text-purple-300' },
  COMPLETED: { bg: 'bg-gray-100 dark:bg-gray-700', text: 'text-gray-700 dark:text-gray-300' },
  CANCELLED: { bg: 'bg-red-100 dark:bg-red-900', text: 'text-red-700 dark:text-red-300' },
};

const STATUS_LABELS: Record<TripStatus, string> = {
  INQUIRY: 'Planning',
  PROPOSAL_SENT: 'Options Ready',
  PENDING_SELECTION: 'Awaiting Selection',
  BOOKED: 'Booked',
  ACTIVE: 'In Progress',
  COMPLETED: 'Completed',
  CANCELLED: 'Cancelled',
};

export default function TravelPage() {
  const api = useApi();
  const [upcomingTrips, setUpcomingTrips] = useState<TripListItem[]>([]);
  const [pendingProposals, setPendingProposals] = useState<TripProposal[]>([]);
  const [allTrips, setAllTrips] = useState<TripListItem[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadData() {
      try {
        const [upcoming, proposals, trips] = await Promise.all([
          api.getUpcomingTrips(3),
          api.getPendingProposals(),
          api.getTrips(),
        ]);
        setUpcomingTrips(upcoming);
        setPendingProposals(proposals);
        setAllTrips(trips);
      } catch (error) {
        console.error('Failed to load travel data:', error);
      } finally {
        setLoading(false);
      }
    }
    loadData();
  }, [api]);

  const daysUntilDeparture = (startDate: string) => {
    const now = new Date();
    const departure = new Date(startDate);
    const diff = departure.getTime() - now.getTime();
    return Math.ceil(diff / (1000 * 60 * 60 * 24));
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 dark:bg-gray-900 p-6">
        <div className="animate-pulse space-y-4">
          <div className="h-8 bg-gray-200 dark:bg-gray-700 rounded w-48"></div>
          <div className="h-48 bg-gray-200 dark:bg-gray-700 rounded-lg"></div>
          <div className="h-32 bg-gray-200 dark:bg-gray-700 rounded-lg"></div>
        </div>
      </div>
    );
  }

  const activeTrip = upcomingTrips[0];

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900 p-6">
      <div className="max-w-4xl mx-auto space-y-6">
        {/* Header */}
        <div className="flex justify-between items-center">
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Travel</h1>
          <Link
            href="/app/travel/profile"
            className="text-sm text-haven-700 dark:text-haven-400 hover:underline"
          >
            Travel Profile
          </Link>
        </div>

        {/* Active/Upcoming Trip Card */}
        {activeTrip && (
          <Link href={`/app/travel/trips/${activeTrip.id}`}>
            <div className="bg-gradient-to-r from-haven-700 to-purple-600 rounded-xl p-6 text-white shadow-lg hover:shadow-xl transition-shadow">
              <div className="flex justify-between items-start">
                <div>
                  <p className="text-haven-100 text-sm">
                    {daysUntilDeparture(activeTrip.startDate) > 0
                      ? `${daysUntilDeparture(activeTrip.startDate)} days until departure`
                      : 'Trip in progress'}
                  </p>
                  <h2 className="text-2xl font-bold mt-1 text-white">{activeTrip.destination}</h2>
                  <p className="text-haven-100 mt-2">
                    {new Date(activeTrip.startDate).toLocaleDateString()} -{' '}
                    {new Date(activeTrip.endDate).toLocaleDateString()}
                  </p>
                </div>
                <span
                  className={`px-3 py-1 rounded-full text-sm ${STATUS_COLORS[activeTrip.status].bg} ${STATUS_COLORS[activeTrip.status].text}`}
                >
                  {STATUS_LABELS[activeTrip.status]}
                </span>
              </div>
              <div className="mt-4 flex space-x-4 text-sm">
                <div className="flex items-center">
                  <CalendarIcon className="h-4 w-4 mr-1" />
                  {activeTrip._count?.itineraryItems || 0} items
                </div>
                <div className="flex items-center">
                  <DocumentTextIcon className="h-4 w-4 mr-1" />
                  {activeTrip._count?.proposals || 0} proposals
                </div>
              </div>
            </div>
          </Link>
        )}

        {/* Pending Proposals Alert */}
        {pendingProposals.length > 0 && (
          <div className="bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg p-4">
            <div className="flex items-start space-x-3">
              <ExclamationCircleIcon className="h-6 w-6 text-yellow-600 dark:text-yellow-400 flex-shrink-0" />
              <div className="flex-1">
                <h3 className="font-medium text-yellow-800 dark:text-yellow-200">
                  {pendingProposals.length} Proposal{pendingProposals.length > 1 ? 's' : ''} Awaiting Your Selection
                </h3>
                <p className="text-sm text-yellow-700 dark:text-yellow-300 mt-1">
                  Your travel manager has sent options for you to review.
                </p>
                <div className="mt-3 space-y-2">
                  {pendingProposals.slice(0, 3).map((proposal) => (
                    <Link
                      key={proposal.id}
                      href={`/app/travel/trips/${proposal.tripId}`}
                      className="flex items-center justify-between bg-white dark:bg-gray-800 rounded p-3 hover:bg-gray-50 dark:hover:bg-gray-700"
                    >
                      <div>
                        <p className="font-medium text-gray-900 dark:text-white">{proposal.title}</p>
                        <p className="text-sm text-gray-500 dark:text-gray-400">
                          {proposal.trip?.destination} &middot; {(proposal.options as any[]).length} options
                        </p>
                      </div>
                      <ChevronRightIcon className="h-5 w-5 text-gray-400" />
                    </Link>
                  ))}
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Quick Actions */}
        <div className="grid grid-cols-2 gap-4">
          <Link
            href="/app/travel/trips/new"
            className="bg-white dark:bg-gray-800 rounded-lg p-4 shadow hover:shadow-md transition-shadow flex items-center space-x-3"
          >
            <div className="p-2 bg-haven-100 dark:bg-haven-900 rounded-lg">
              <PlusIcon className="h-6 w-6 text-haven-700 dark:text-haven-400" />
            </div>
            <div>
              <p className="font-medium text-gray-900 dark:text-white">Plan a Trip</p>
              <p className="text-sm text-gray-500 dark:text-gray-400">Start planning</p>
            </div>
          </Link>

          <Link
            href="/app/travel/profile"
            className="bg-white dark:bg-gray-800 rounded-lg p-4 shadow hover:shadow-md transition-shadow flex items-center space-x-3"
          >
            <div className="p-2 bg-green-100 dark:bg-green-900 rounded-lg">
              <ShieldCheckIcon className="h-6 w-6 text-green-600 dark:text-green-400" />
            </div>
            <div>
              <p className="font-medium text-gray-900 dark:text-white">Travel Profile</p>
              <p className="text-sm text-gray-500 dark:text-gray-400">Passport & prefs</p>
            </div>
          </Link>
        </div>

        {/* All Trips */}
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow">
          <div className="p-4 border-b border-gray-200 dark:border-gray-700">
            <h2 className="font-semibold text-gray-900 dark:text-white">All Trips</h2>
          </div>
          <div className="divide-y divide-gray-200 dark:divide-gray-700">
            {allTrips.length === 0 ? (
              <div className="p-8 text-center">
                <PaperAirplaneIcon className="h-12 w-12 text-gray-300 dark:text-gray-600 mx-auto mb-3" />
                <p className="text-gray-500 dark:text-gray-400">No trips yet</p>
                <Link
                  href="/app/travel/trips/new"
                  className="mt-3 inline-block text-haven-700 dark:text-haven-400 hover:underline"
                >
                  Plan your first trip
                </Link>
              </div>
            ) : (
              allTrips.map((trip) => (
                <Link
                  key={trip.id}
                  href={`/app/travel/trips/${trip.id}`}
                  className="flex items-center justify-between p-4 hover:bg-gray-50 dark:hover:bg-gray-700"
                >
                  <div className="flex items-center space-x-4">
                    <div className="p-2 bg-gray-100 dark:bg-gray-700 rounded-lg">
                      <PaperAirplaneIcon className="h-6 w-6 text-gray-600 dark:text-gray-400" />
                    </div>
                    <div>
                      <p className="font-medium text-gray-900 dark:text-white">{trip.destination}</p>
                      <p className="text-sm text-gray-500 dark:text-gray-400">
                        {new Date(trip.startDate).toLocaleDateString()} &middot;{' '}
                        {trip.travelerCount} traveler{trip.travelerCount > 1 ? 's' : ''}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center space-x-3">
                    <span
                      className={`px-2 py-1 rounded text-xs ${STATUS_COLORS[trip.status].bg} ${STATUS_COLORS[trip.status].text}`}
                    >
                      {STATUS_LABELS[trip.status]}
                    </span>
                    <ChevronRightIcon className="h-5 w-5 text-gray-400" />
                  </div>
                </Link>
              ))
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
