'use client';

import { useState, useEffect } from 'react';
import { useApi } from '@/lib/api';
import { useParams } from 'next/navigation';
import Link from 'next/link';
import type { Trip, TripStatus, ItineraryItemType, ProposalOption } from '@haven/core';
import {
  ArrowLeftIcon,
  UserIcon,
  CalendarIcon,
  DocumentTextIcon,
  PlusIcon,
  PaperAirplaneIcon,
  BuildingOfficeIcon,
  TruckIcon,
  TicketIcon,
  ShieldCheckIcon,
} from '@heroicons/react/24/outline';

const STATUS_OPTIONS: TripStatus[] = [
  'INQUIRY',
  'PROPOSAL_SENT',
  'PENDING_SELECTION',
  'BOOKED',
  'ACTIVE',
  'COMPLETED',
  'CANCELLED',
];

const ITEM_TYPES: { value: ItineraryItemType; label: string; icon: any }[] = [
  { value: 'FLIGHT', label: 'Flight', icon: PaperAirplaneIcon },
  { value: 'STAY', label: 'Hotel/Stay', icon: BuildingOfficeIcon },
  { value: 'CAR_RENTAL', label: 'Car Rental', icon: TruckIcon },
  { value: 'ACTIVITY', label: 'Activity', icon: TicketIcon },
  { value: 'TRANSFER', label: 'Transfer', icon: TruckIcon },
  { value: 'OTHER', label: 'Other', icon: DocumentTextIcon },
];

type TabType = 'overview' | 'proposals' | 'itinerary' | 'protocol';

export default function ManagerTripDetailPage() {
  const api = useApi();
  const params = useParams();
  const tripId = params.id as string;

  const [trip, setTrip] = useState<Trip | null>(null);
  const [activeTab, setActiveTab] = useState<TabType>('overview');
  const [loading, setLoading] = useState(true);
  const [showProposalForm, setShowProposalForm] = useState(false);
  const [showItemForm, setShowItemForm] = useState(false);

  useEffect(() => {
    async function loadTrip() {
      try {
        const data = await api.getTrip(tripId);
        setTrip(data);
      } catch (error) {
        console.error('Failed to load trip:', error);
      } finally {
        setLoading(false);
      }
    }
    loadTrip();
  }, [api, tripId]);

  const handleAssignToMe = async () => {
    try {
      await api.assignTripManager(tripId);
      const updated = await api.getTrip(tripId);
      setTrip(updated);
    } catch (error) {
      console.error('Failed to assign:', error);
    }
  };

  const handleStatusChange = async (status: TripStatus) => {
    try {
      await api.updateTripStatus(tripId, status);
      const updated = await api.getTrip(tripId);
      setTrip(updated);
    } catch (error) {
      console.error('Failed to update status:', error);
    }
  };

  const handleGenerateProtocol = async () => {
    try {
      await api.generateTripProtocol(tripId);
      const updated = await api.getTrip(tripId);
      setTrip(updated);
    } catch (error) {
      console.error('Failed to generate protocol:', error);
    }
  };

  const handleSendProposal = async (proposalId: string) => {
    try {
      await api.sendProposal(proposalId);
      const updated = await api.getTrip(tripId);
      setTrip(updated);
    } catch (error) {
      console.error('Failed to send proposal:', error);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-100 dark:bg-gray-900 p-6">
        <div className="animate-pulse space-y-4 max-w-4xl mx-auto">
          <div className="h-8 bg-gray-200 dark:bg-gray-700 rounded w-48"></div>
          <div className="h-48 bg-gray-200 dark:bg-gray-700 rounded-lg"></div>
        </div>
      </div>
    );
  }

  if (!trip) {
    return (
      <div className="min-h-screen bg-gray-100 dark:bg-gray-900 p-6">
        <div className="max-w-4xl mx-auto text-center">
          <p className="text-gray-500 dark:text-gray-400">Trip not found</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-100 dark:bg-gray-900 p-6">
      <div className="max-w-4xl mx-auto space-y-6">
        {/* Header */}
        <div className="flex items-start justify-between">
          <div className="flex items-center space-x-4">
            <Link href="/manager/travel" className="p-2 hover:bg-gray-200 dark:hover:bg-gray-800 rounded-lg">
              <ArrowLeftIcon className="h-5 w-5 text-gray-600 dark:text-gray-400" />
            </Link>
            <div>
              <p className="text-sm text-gray-500 dark:text-gray-400">{trip.household?.name}</p>
              <h1 className="text-2xl font-bold text-gray-900 dark:text-white">{trip.destination}</h1>
              <p className="text-gray-500 dark:text-gray-400">
                {new Date(trip.startDate).toLocaleDateString()} - {new Date(trip.endDate).toLocaleDateString()}
              </p>
            </div>
          </div>
          <div className="flex items-center space-x-2">
            {!trip.assignedManager && (
              <button
                onClick={handleAssignToMe}
                className="px-3 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 text-sm"
              >
                Assign to Me
              </button>
            )}
            <select
              value={trip.status}
              onChange={(e) => handleStatusChange(e.target.value as TripStatus)}
              className="px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white text-sm"
            >
              {STATUS_OPTIONS.map((s) => (
                <option key={s} value={s}>
                  {s.replace('_', ' ')}
                </option>
              ))}
            </select>
          </div>
        </div>

        {/* Quick Stats */}
        <div className="grid grid-cols-4 gap-4">
          <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-4">
            <p className="text-sm text-gray-500 dark:text-gray-400">Travelers</p>
            <p className="text-xl font-bold text-gray-900 dark:text-white">{trip.travelerCount}</p>
          </div>
          <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-4">
            <p className="text-sm text-gray-500 dark:text-gray-400">Budget</p>
            <p className="text-xl font-bold text-gray-900 dark:text-white">
              {trip.budgetMax ? `$${trip.budgetMax.toLocaleString()}` : 'N/A'}
            </p>
          </div>
          <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-4">
            <p className="text-sm text-gray-500 dark:text-gray-400">Est. Cost</p>
            <p className="text-xl font-bold text-green-600">
              {trip.totalEstimatedCost ? `$${trip.totalEstimatedCost.toLocaleString()}` : '-'}
            </p>
          </div>
          <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-4">
            <p className="text-sm text-gray-500 dark:text-gray-400">Assigned To</p>
            <p className="text-xl font-bold text-gray-900 dark:text-white">
              {trip.assignedManager?.displayName || 'Unassigned'}
            </p>
          </div>
        </div>

        {/* Tabs */}
        <div className="border-b border-gray-200 dark:border-gray-700">
          <nav className="flex space-x-8">
            {(['overview', 'proposals', 'itinerary', 'protocol'] as TabType[]).map((tab) => (
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
            <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
              <h2 className="font-semibold text-gray-900 dark:text-white mb-4">Trip Details</h2>
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <p className="text-gray-500 dark:text-gray-400">Destination</p>
                  <p className="text-gray-900 dark:text-white">{trip.destination}</p>
                </div>
                <div>
                  <p className="text-gray-500 dark:text-gray-400">Departure City</p>
                  <p className="text-gray-900 dark:text-white">{trip.departureCity || 'Not specified'}</p>
                </div>
                <div>
                  <p className="text-gray-500 dark:text-gray-400">Flexible Dates</p>
                  <p className="text-gray-900 dark:text-white">{trip.isFlexibleDates ? 'Yes' : 'No'}</p>
                </div>
                <div>
                  <p className="text-gray-500 dark:text-gray-400">Created By</p>
                  <p className="text-gray-900 dark:text-white">{trip.createdBy?.displayName}</p>
                </div>
              </div>
              {trip.notes && (
                <div className="mt-4 pt-4 border-t border-gray-200 dark:border-gray-700">
                  <p className="text-gray-500 dark:text-gray-400 text-sm">Notes from client</p>
                  <p className="text-gray-900 dark:text-white mt-1">{trip.notes}</p>
                </div>
              )}
            </div>
          </div>
        )}

        {activeTab === 'proposals' && (
          <div className="space-y-4">
            <div className="flex justify-between items-center">
              <h2 className="font-semibold text-gray-900 dark:text-white">Proposals</h2>
              <button
                onClick={() => setShowProposalForm(true)}
                className="flex items-center px-3 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 text-sm"
              >
                <PlusIcon className="h-4 w-4 mr-1" />
                New Proposal
              </button>
            </div>

            {trip.proposals && trip.proposals.length > 0 ? (
              <div className="space-y-4">
                {trip.proposals.map((proposal) => (
                  <div key={proposal.id} className="bg-white dark:bg-gray-800 rounded-lg shadow p-4">
                    <div className="flex justify-between items-start">
                      <div>
                        <p className="font-medium text-gray-900 dark:text-white">{proposal.title}</p>
                        <p className="text-sm text-gray-500 dark:text-gray-400">{proposal.category}</p>
                      </div>
                      <div className="flex items-center space-x-2">
                        {proposal.selectedAt && (
                          <span className="text-xs bg-green-100 text-green-700 dark:bg-green-900 dark:text-green-300 px-2 py-1 rounded">
                            Option #{(proposal.selectedOptionIndex || 0) + 1} selected
                          </span>
                        )}
                        {!proposal.sentAt && (
                          <button
                            onClick={() => handleSendProposal(proposal.id)}
                            className="text-xs bg-emerald-600 text-white px-3 py-1 rounded hover:bg-emerald-700"
                          >
                            Send to Client
                          </button>
                        )}
                        {proposal.sentAt && !proposal.selectedAt && (
                          <span className="text-xs text-yellow-600 dark:text-yellow-400">
                            Awaiting selection
                          </span>
                        )}
                      </div>
                    </div>
                    <div className="mt-3 grid gap-2">
                      {(proposal.options as ProposalOption[]).map((opt) => (
                        <div
                          key={opt.index}
                          className={`text-sm p-2 rounded ${
                            proposal.selectedOptionIndex === opt.index
                              ? 'bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800'
                              : 'bg-gray-50 dark:bg-gray-700/50'
                          }`}
                        >
                          <div className="flex justify-between">
                            <span className="font-medium">{opt.title}</span>
                            <span>${opt.price.toLocaleString()}</span>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-8 text-center">
                <DocumentTextIcon className="h-12 w-12 text-gray-300 dark:text-gray-600 mx-auto mb-3" />
                <p className="text-gray-500 dark:text-gray-400">No proposals yet</p>
              </div>
            )}
          </div>
        )}

        {activeTab === 'itinerary' && (
          <div className="space-y-4">
            <div className="flex justify-between items-center">
              <h2 className="font-semibold text-gray-900 dark:text-white">Itinerary Items</h2>
              <button
                onClick={() => setShowItemForm(true)}
                className="flex items-center px-3 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 text-sm"
              >
                <PlusIcon className="h-4 w-4 mr-1" />
                Add Item
              </button>
            </div>

            {trip.itineraryItems && trip.itineraryItems.length > 0 ? (
              <div className="space-y-3">
                {trip.itineraryItems.map((item) => {
                  const typeInfo = ITEM_TYPES.find((t) => t.value === item.type);
                  const Icon = typeInfo?.icon || DocumentTextIcon;
                  return (
                    <div key={item.id} className="bg-white dark:bg-gray-800 rounded-lg shadow p-4">
                      <div className="flex items-start space-x-3">
                        <div className="p-2 bg-gray-100 dark:bg-gray-700 rounded-lg">
                          <Icon className="h-5 w-5 text-gray-600 dark:text-gray-400" />
                        </div>
                        <div className="flex-1">
                          <p className="font-medium text-gray-900 dark:text-white">{item.title}</p>
                          <p className="text-sm text-gray-500 dark:text-gray-400">
                            {new Date(item.startDateTime).toLocaleString()}
                          </p>
                          {item.confirmationNumber && (
                            <p className="text-xs text-gray-400 mt-1">
                              Conf: {item.confirmationNumber}
                            </p>
                          )}
                        </div>
                        <p className="font-medium text-gray-900 dark:text-white">
                          ${item.cost.toLocaleString()}
                        </p>
                      </div>
                    </div>
                  );
                })}
              </div>
            ) : (
              <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-8 text-center">
                <CalendarIcon className="h-12 w-12 text-gray-300 dark:text-gray-600 mx-auto mb-3" />
                <p className="text-gray-500 dark:text-gray-400">No itinerary items yet</p>
              </div>
            )}

            {trip.itineraryItems && trip.itineraryItems.length > 0 && trip.status !== 'BOOKED' && (
              <button
                onClick={() => api.markTripAsBooked(tripId).then(() => api.getTrip(tripId).then(setTrip))}
                className="w-full py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 font-medium"
              >
                Mark as Booked
              </button>
            )}
          </div>
        )}

        {activeTab === 'protocol' && (
          <div className="space-y-4">
            {trip.houseProtocol ? (
              <div className="bg-white dark:bg-gray-800 rounded-lg shadow">
                <div className="p-4 border-b border-gray-200 dark:border-gray-700 flex justify-between items-center">
                  <div>
                    <h2 className="font-semibold text-gray-900 dark:text-white">House Protocol</h2>
                    <p className="text-sm text-gray-500 dark:text-gray-400">
                      Scheduled: {new Date(trip.houseProtocol.scheduledDate).toLocaleDateString()}
                    </p>
                  </div>
                  <span className="px-2 py-1 rounded text-sm bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300">
                    {trip.houseProtocol.status}
                  </span>
                </div>
                <div className="p-4">
                  <p className="text-sm text-gray-500 dark:text-gray-400">
                    {trip.houseProtocol.items?.length || 0} checklist items
                  </p>
                  <Link
                    href="/manager/travel/protocols"
                    className="mt-2 inline-block text-emerald-600 dark:text-emerald-400 hover:underline text-sm"
                  >
                    View in Protocol Enforcer →
                  </Link>
                </div>
              </div>
            ) : (
              <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-8 text-center">
                <ShieldCheckIcon className="h-12 w-12 text-gray-300 dark:text-gray-600 mx-auto mb-3" />
                <p className="text-gray-500 dark:text-gray-400 mb-4">No protocol generated yet</p>
                <button
                  onClick={handleGenerateProtocol}
                  className="px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700"
                >
                  Generate Protocol
                </button>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
