'use client';

import { useState, useEffect } from 'react';
import { useApi } from '@/lib/api';
import { useParams } from 'next/navigation';
import Link from 'next/link';
import type { Trip, ItineraryDay, TripDocument, HouseProtocol, TripProposal, TripStatus, ItineraryItemType } from '@haven/core';
import {
  ArrowLeftIcon,
  CalendarIcon,
  DocumentTextIcon,
  ShieldCheckIcon,
  ClockIcon,
  MapPinIcon,
  CheckCircleIcon,
  XCircleIcon,
  PaperAirplaneIcon,
  BuildingOfficeIcon,
  TruckIcon,
  TicketIcon,
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

const ITEM_ICONS: Record<ItineraryItemType, any> = {
  FLIGHT: PaperAirplaneIcon,
  STAY: BuildingOfficeIcon,
  CAR_RENTAL: TruckIcon,
  ACTIVITY: TicketIcon,
  TRANSFER: TruckIcon,
  OTHER: DocumentTextIcon,
};

type TabType = 'overview' | 'itinerary' | 'documents' | 'protocol';

export default function TripDetailPage() {
  const api = useApi();
  const params = useParams();
  const tripId = params.id as string;

  const [trip, setTrip] = useState<Trip | null>(null);
  const [itinerary, setItinerary] = useState<ItineraryDay[]>([]);
  const [documents, setDocuments] = useState<TripDocument[]>([]);
  const [protocol, setProtocol] = useState<HouseProtocol | null>(null);
  const [activeTab, setActiveTab] = useState<TabType>('overview');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadData() {
      try {
        const tripData = await api.getTrip(tripId);
        setTrip(tripData);

        const [itineraryData, docsData] = await Promise.all([
          api.getTripItinerary(tripId),
          api.getTripDocuments(tripId),
        ]);
        setItinerary(itineraryData);
        setDocuments(docsData);

        // Try to get protocol (may not exist)
        try {
          const protocolData = await api.getTripProtocol(tripId);
          setProtocol(protocolData);
        } catch {
          // Protocol doesn't exist yet
        }
      } catch (error) {
        console.error('Failed to load trip:', error);
      } finally {
        setLoading(false);
      }
    }
    loadData();
  }, [api, tripId]);

  const handleSelectOption = async (proposalId: string, optionIndex: number) => {
    try {
      await api.selectProposalOption(proposalId, optionIndex);
      // Reload trip data
      const tripData = await api.getTrip(tripId);
      setTrip(tripData);
    } catch (error) {
      console.error('Failed to select option:', error);
    }
  };

  const handleVerifyProtocol = async () => {
    try {
      const updated = await api.verifyTripProtocol(tripId);
      setProtocol(updated);
    } catch (error) {
      console.error('Failed to verify protocol:', error);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 dark:bg-gray-900 p-6">
        <div className="animate-pulse space-y-4 max-w-4xl mx-auto">
          <div className="h-8 bg-gray-200 dark:bg-gray-700 rounded w-48"></div>
          <div className="h-48 bg-gray-200 dark:bg-gray-700 rounded-lg"></div>
          <div className="h-64 bg-gray-200 dark:bg-gray-700 rounded-lg"></div>
        </div>
      </div>
    );
  }

  if (!trip) {
    return (
      <div className="min-h-screen bg-gray-50 dark:bg-gray-900 p-6">
        <div className="max-w-4xl mx-auto text-center">
          <p className="text-gray-500 dark:text-gray-400">Trip not found</p>
          <Link href="/app/travel" className="text-emerald-600 dark:text-emerald-400 hover:underline mt-4 inline-block">
            Back to Travel
          </Link>
        </div>
      </div>
    );
  }

  const pendingProposals = trip.proposals?.filter(p => p.sentAt && !p.selectedAt) || [];

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900 p-6">
      <div className="max-w-4xl mx-auto space-y-6">
        {/* Header */}
        <div className="flex items-center space-x-4">
          <Link href="/app/travel" className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg">
            <ArrowLeftIcon className="h-5 w-5 text-gray-600 dark:text-gray-400" />
          </Link>
          <div className="flex-1">
            <h1 className="text-2xl font-bold text-gray-900 dark:text-white">{trip.destination}</h1>
            <p className="text-gray-500 dark:text-gray-400">
              {new Date(trip.startDate).toLocaleDateString()} - {new Date(trip.endDate).toLocaleDateString()}
            </p>
          </div>
          <span className={`px-3 py-1 rounded-full text-sm ${STATUS_COLORS[trip.status].bg} ${STATUS_COLORS[trip.status].text}`}>
            {trip.status.replace('_', ' ')}
          </span>
        </div>

        {/* Tabs */}
        <div className="border-b border-gray-200 dark:border-gray-700">
          <nav className="flex space-x-8">
            {(['overview', 'itinerary', 'documents', 'protocol'] as TabType[]).map((tab) => (
              <button
                key={tab}
                onClick={() => setActiveTab(tab)}
                className={`py-3 px-1 border-b-2 font-medium text-sm capitalize ${
                  activeTab === tab
                    ? 'border-emerald-500 text-emerald-600 dark:text-emerald-400'
                    : 'border-transparent text-gray-500 hover:text-gray-700 dark:text-gray-400'
                }`}
              >
                {tab}
              </button>
            ))}
          </nav>
        </div>

        {/* Tab Content */}
        {activeTab === 'overview' && (
          <div className="space-y-6">
            {/* Trip Summary */}
            <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
              <h2 className="font-semibold text-gray-900 dark:text-white mb-4">Trip Details</h2>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <p className="text-sm text-gray-500 dark:text-gray-400">Destination</p>
                  <p className="font-medium text-gray-900 dark:text-white">{trip.destination}</p>
                </div>
                {trip.departureCity && (
                  <div>
                    <p className="text-sm text-gray-500 dark:text-gray-400">Departing From</p>
                    <p className="font-medium text-gray-900 dark:text-white">{trip.departureCity}</p>
                  </div>
                )}
                <div>
                  <p className="text-sm text-gray-500 dark:text-gray-400">Travelers</p>
                  <p className="font-medium text-gray-900 dark:text-white">{trip.travelerCount}</p>
                </div>
                {(trip.budgetMin || trip.budgetMax) && (
                  <div>
                    <p className="text-sm text-gray-500 dark:text-gray-400">Budget</p>
                    <p className="font-medium text-gray-900 dark:text-white">
                      {trip.budgetMin && trip.budgetMax
                        ? `$${trip.budgetMin.toLocaleString()} - $${trip.budgetMax.toLocaleString()}`
                        : trip.budgetMax
                          ? `Up to $${trip.budgetMax.toLocaleString()}`
                          : `From $${trip.budgetMin?.toLocaleString()}`}
                    </p>
                  </div>
                )}
                {trip.totalEstimatedCost && (
                  <div>
                    <p className="text-sm text-gray-500 dark:text-gray-400">Estimated Total</p>
                    <p className="font-medium text-green-600 dark:text-green-400">
                      ${trip.totalEstimatedCost.toLocaleString()}
                    </p>
                  </div>
                )}
              </div>
              {trip.notes && (
                <div className="mt-4 pt-4 border-t border-gray-200 dark:border-gray-700">
                  <p className="text-sm text-gray-500 dark:text-gray-400">Notes</p>
                  <p className="text-gray-700 dark:text-gray-300">{trip.notes}</p>
                </div>
              )}
            </div>

            {/* Pending Proposals */}
            {pendingProposals.length > 0 && (
              <div className="bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg p-6">
                <h2 className="font-semibold text-yellow-800 dark:text-yellow-200 mb-4">
                  Proposals Awaiting Your Selection
                </h2>
                <div className="space-y-4">
                  {pendingProposals.map((proposal) => (
                    <ProposalCard
                      key={proposal.id}
                      proposal={proposal}
                      onSelect={(index) => handleSelectOption(proposal.id, index)}
                    />
                  ))}
                </div>
              </div>
            )}
          </div>
        )}

        {activeTab === 'itinerary' && (
          <div className="space-y-6">
            {itinerary.length === 0 ? (
              <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-8 text-center">
                <CalendarIcon className="h-12 w-12 text-gray-300 dark:text-gray-600 mx-auto mb-3" />
                <p className="text-gray-500 dark:text-gray-400">
                  No itinerary items yet. Your travel manager will add items once booked.
                </p>
              </div>
            ) : (
              itinerary.map((day) => (
                <div key={day.date} className="bg-white dark:bg-gray-800 rounded-lg shadow">
                  <div className="p-4 border-b border-gray-200 dark:border-gray-700">
                    <p className="font-semibold text-gray-900 dark:text-white">
                      Day {day.dayNumber} &middot; {new Date(day.date).toLocaleDateString(undefined, {
                        weekday: 'long',
                        month: 'long',
                        day: 'numeric',
                      })}
                    </p>
                  </div>
                  <div className="divide-y divide-gray-200 dark:divide-gray-700">
                    {day.items.map((item) => {
                      const Icon = ITEM_ICONS[item.type] || DocumentTextIcon;
                      return (
                        <div key={item.id} className="p-4">
                          <div className="flex items-start space-x-4">
                            <div className="p-2 bg-gray-100 dark:bg-gray-700 rounded-lg">
                              <Icon className="h-5 w-5 text-gray-600 dark:text-gray-400" />
                            </div>
                            <div className="flex-1">
                              <p className="font-medium text-gray-900 dark:text-white">{item.title}</p>
                              <p className="text-sm text-gray-500 dark:text-gray-400">
                                {new Date(item.startDateTime).toLocaleTimeString([], {
                                  hour: '2-digit',
                                  minute: '2-digit',
                                })}
                                {item.startLocation && ` • ${item.startLocation}`}
                                {item.endLocation && ` → ${item.endLocation}`}
                              </p>
                              {item.confirmationNumber && (
                                <p className="text-xs text-gray-400 dark:text-gray-500 mt-1">
                                  Confirmation: {item.confirmationNumber}
                                </p>
                              )}
                            </div>
                            <p className="text-sm font-medium text-gray-900 dark:text-white">
                              ${item.cost.toLocaleString()}
                            </p>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>
              ))
            )}
          </div>
        )}

        {activeTab === 'documents' && (
          <div className="bg-white dark:bg-gray-800 rounded-lg shadow">
            <div className="p-4 border-b border-gray-200 dark:border-gray-700">
              <h2 className="font-semibold text-gray-900 dark:text-white">Travel Documents</h2>
            </div>
            {documents.length === 0 ? (
              <div className="p-8 text-center">
                <DocumentTextIcon className="h-12 w-12 text-gray-300 dark:text-gray-600 mx-auto mb-3" />
                <p className="text-gray-500 dark:text-gray-400">
                  No documents yet. Boarding passes and vouchers will appear here.
                </p>
              </div>
            ) : (
              <div className="divide-y divide-gray-200 dark:divide-gray-700">
                {documents.map((doc, idx) => (
                  <div key={idx} className="p-4 flex items-center justify-between">
                    <div className="flex items-center space-x-3">
                      <DocumentTextIcon className="h-5 w-5 text-gray-400" />
                      <div>
                        <p className="font-medium text-gray-900 dark:text-white">{doc.name}</p>
                        <p className="text-sm text-gray-500 dark:text-gray-400">
                          {doc.itemTitle} ({doc.itemType})
                        </p>
                      </div>
                    </div>
                    {doc.url && (
                      <a
                        href={doc.url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-emerald-600 dark:text-emerald-400 hover:underline text-sm"
                      >
                        View
                      </a>
                    )}
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {activeTab === 'protocol' && (
          <div className="space-y-6">
            {!protocol ? (
              <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-8 text-center">
                <ShieldCheckIcon className="h-12 w-12 text-gray-300 dark:text-gray-600 mx-auto mb-3" />
                <p className="text-gray-500 dark:text-gray-400">
                  House protocol will be generated before your trip to secure your home.
                </p>
              </div>
            ) : (
              <div className="bg-white dark:bg-gray-800 rounded-lg shadow">
                <div className="p-4 border-b border-gray-200 dark:border-gray-700 flex justify-between items-center">
                  <div>
                    <h2 className="font-semibold text-gray-900 dark:text-white">House Security Protocol</h2>
                    <p className="text-sm text-gray-500 dark:text-gray-400">
                      Scheduled: {new Date(protocol.scheduledDate).toLocaleDateString()}
                    </p>
                  </div>
                  <span
                    className={`px-2 py-1 rounded text-sm ${
                      protocol.status === 'VERIFIED'
                        ? 'bg-green-100 text-green-700 dark:bg-green-900 dark:text-green-300'
                        : protocol.status === 'COMPLETED'
                          ? 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900 dark:text-emerald-300'
                          : 'bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300'
                    }`}
                  >
                    {protocol.status}
                  </span>
                </div>
                <div className="divide-y divide-gray-200 dark:divide-gray-700">
                  {protocol.items?.map((item) => (
                    <div key={item.id} className="p-4 flex items-center justify-between">
                      <div className="flex items-center space-x-3">
                        {item.status === 'COMPLETED' ? (
                          <CheckCircleIcon className="h-5 w-5 text-green-500" />
                        ) : item.status === 'BLOCKED' ? (
                          <XCircleIcon className="h-5 w-5 text-red-500" />
                        ) : (
                          <div className="h-5 w-5 rounded-full border-2 border-gray-300 dark:border-gray-600" />
                        )}
                        <div>
                          <p className="font-medium text-gray-900 dark:text-white">{item.title}</p>
                          {item.category && (
                            <p className="text-sm text-gray-500 dark:text-gray-400">{item.category}</p>
                          )}
                        </div>
                      </div>
                      {item.isRequired && (
                        <span className="text-xs bg-red-100 text-red-700 dark:bg-red-900 dark:text-red-300 px-2 py-0.5 rounded">
                          Required
                        </span>
                      )}
                    </div>
                  ))}
                </div>
                {protocol.status === 'COMPLETED' && (
                  <div className="p-4 border-t border-gray-200 dark:border-gray-700">
                    <button
                      onClick={handleVerifyProtocol}
                      className="w-full bg-green-600 text-white py-2 px-4 rounded-lg hover:bg-green-700"
                    >
                      Verify House is Secure
                    </button>
                  </div>
                )}
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}

function ProposalCard({
  proposal,
  onSelect,
}: {
  proposal: TripProposal;
  onSelect: (index: number) => void;
}) {
  const options = proposal.options as any[];

  return (
    <div className="bg-white dark:bg-gray-800 rounded-lg p-4">
      <h3 className="font-medium text-gray-900 dark:text-white">{proposal.title}</h3>
      <p className="text-sm text-gray-500 dark:text-gray-400 mb-4">{proposal.description}</p>
      <div className="space-y-3">
        {options.map((option) => (
          <div
            key={option.index}
            className="border border-gray-200 dark:border-gray-700 rounded-lg p-3"
          >
            <div className="flex justify-between items-start">
              <div>
                <p className="font-medium text-gray-900 dark:text-white">{option.title}</p>
                <p className="text-sm text-gray-500 dark:text-gray-400">{option.details}</p>
                {option.pros && option.pros.length > 0 && (
                  <div className="mt-2 flex flex-wrap gap-1">
                    {option.pros.map((pro: string, i: number) => (
                      <span key={i} className="text-xs bg-green-100 text-green-700 px-2 py-0.5 rounded">
                        {pro}
                      </span>
                    ))}
                  </div>
                )}
              </div>
              <div className="text-right">
                <p className="font-bold text-gray-900 dark:text-white">${option.price.toLocaleString()}</p>
                <button
                  onClick={() => onSelect(option.index)}
                  className="mt-2 text-sm bg-emerald-600 text-white px-3 py-1 rounded hover:bg-emerald-700"
                >
                  Select
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
