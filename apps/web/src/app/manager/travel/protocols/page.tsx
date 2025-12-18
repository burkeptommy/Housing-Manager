'use client';

import { useState, useEffect } from 'react';
import { useApi } from '@/lib/api';
import Link from 'next/link';
import type { HouseProtocol, HouseProtocolStatus } from '@haven/core';
import {
  ShieldCheckIcon,
  CalendarIcon,
  HomeIcon,
  UserIcon,
  CheckCircleIcon,
  ClockIcon,
  ArrowLeftIcon,
  PlayIcon,
} from '@heroicons/react/24/outline';

const STATUS_COLORS: Record<HouseProtocolStatus, { bg: string; text: string }> = {
  PENDING: { bg: 'bg-gray-100 dark:bg-gray-700', text: 'text-gray-700 dark:text-gray-300' },
  IN_PROGRESS: { bg: 'bg-emerald-100 dark:bg-emerald-900', text: 'text-emerald-700 dark:text-emerald-300' },
  COMPLETED: { bg: 'bg-green-100 dark:bg-green-900', text: 'text-green-700 dark:text-green-300' },
  VERIFIED: { bg: 'bg-purple-100 dark:bg-purple-900', text: 'text-purple-700 dark:text-purple-300' },
};

export default function ProtocolEnforcerPage() {
  const api = useApi();
  const [protocols, setProtocols] = useState<HouseProtocol[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<'all' | 'today' | 'week'>('week');
  const [selectedProtocol, setSelectedProtocol] = useState<HouseProtocol | null>(null);

  useEffect(() => {
    async function loadProtocols() {
      try {
        const data = await api.getPendingProtocols();
        setProtocols(data);
      } catch (error) {
        console.error('Failed to load protocols:', error);
      } finally {
        setLoading(false);
      }
    }
    loadProtocols();
  }, [api]);

  const getDaysUntil = (date: string) => {
    const now = new Date();
    const scheduled = new Date(date);
    const diff = scheduled.getTime() - now.getTime();
    return Math.ceil(diff / (1000 * 60 * 60 * 24));
  };

  const filteredProtocols = protocols.filter((p) => {
    const days = getDaysUntil(p.scheduledDate);
    if (filter === 'today') return days === 0;
    if (filter === 'week') return days >= 0 && days <= 7;
    return true;
  });

  const handleStartProtocol = async (protocolId: string) => {
    try {
      await api.startProtocol(protocolId);
      const updated = await api.getPendingProtocols();
      setProtocols(updated);
    } catch (error) {
      console.error('Failed to start protocol:', error);
    }
  };

  const handleAssignToMe = async (protocolId: string) => {
    try {
      await api.assignProtocol(protocolId);
      const updated = await api.getPendingProtocols();
      setProtocols(updated);
    } catch (error) {
      console.error('Failed to assign protocol:', error);
    }
  };

  const handleCompleteItem = async (protocolId: string, itemId: string) => {
    try {
      await api.completeProtocolItem(protocolId, itemId, {});
      // Reload protocol detail
      const updated = await api.getProtocol(protocolId);
      setSelectedProtocol(updated);
      // Also update list
      const listData = await api.getPendingProtocols();
      setProtocols(listData);
    } catch (error) {
      console.error('Failed to complete item:', error);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-100 dark:bg-gray-900 p-6">
        <div className="animate-pulse space-y-4 max-w-4xl mx-auto">
          <div className="h-8 bg-gray-200 dark:bg-gray-700 rounded w-48"></div>
          <div className="space-y-3">
            {[1, 2, 3].map((i) => (
              <div key={i} className="h-24 bg-gray-200 dark:bg-gray-700 rounded-lg"></div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  if (selectedProtocol) {
    return (
      <ProtocolDetailView
        protocol={selectedProtocol}
        onBack={() => setSelectedProtocol(null)}
        onCompleteItem={handleCompleteItem}
      />
    );
  }

  return (
    <div className="min-h-screen bg-gray-100 dark:bg-gray-900 p-6">
      <div className="max-w-4xl mx-auto">
        {/* Header */}
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center space-x-4">
            <Link href="/manager/travel" className="p-2 hover:bg-gray-200 dark:hover:bg-gray-800 rounded-lg">
              <ArrowLeftIcon className="h-5 w-5 text-gray-600 dark:text-gray-400" />
            </Link>
            <div>
              <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Protocol Enforcer</h1>
              <p className="text-gray-500 dark:text-gray-400">House security checklists</p>
            </div>
          </div>
        </div>

        {/* Filters */}
        <div className="flex space-x-2 mb-6">
          {(['today', 'week', 'all'] as const).map((f) => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`px-4 py-2 rounded-lg text-sm font-medium ${
                filter === f
                  ? 'bg-emerald-600 text-white'
                  : 'bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700'
              }`}
            >
              {f === 'today' ? 'Today' : f === 'week' ? 'This Week' : 'All'}
            </button>
          ))}
        </div>

        {/* Protocol List */}
        <div className="space-y-4">
          {filteredProtocols.length === 0 ? (
            <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-8 text-center">
              <ShieldCheckIcon className="h-12 w-12 text-gray-300 dark:text-gray-600 mx-auto mb-3" />
              <p className="text-gray-500 dark:text-gray-400">
                No protocols scheduled for {filter === 'today' ? 'today' : filter === 'week' ? 'this week' : 'review'}
              </p>
            </div>
          ) : (
            filteredProtocols.map((protocol) => {
              const daysUntil = getDaysUntil(protocol.scheduledDate);
              const completedItems = protocol.items?.filter((i) => i.status === 'COMPLETED').length || 0;
              const totalItems = protocol.items?.length || 0;
              const percentage = totalItems > 0 ? Math.round((completedItems / totalItems) * 100) : 0;

              return (
                <div
                  key={protocol.id}
                  className="bg-white dark:bg-gray-800 rounded-lg shadow hover:shadow-md transition-shadow"
                >
                  <div className="p-4">
                    <div className="flex justify-between items-start">
                      <div>
                        <p className="font-medium text-gray-900 dark:text-white">
                          {protocol.household?.name}
                        </p>
                        <p className="text-sm text-emerald-600 dark:text-emerald-400">
                          {protocol.trip?.destination} &middot; {protocol.trip?.title}
                        </p>
                      </div>
                      <span
                        className={`px-2 py-1 rounded text-xs ${STATUS_COLORS[protocol.status].bg} ${STATUS_COLORS[protocol.status].text}`}
                      >
                        {protocol.status.replace('_', ' ')}
                      </span>
                    </div>

                    <div className="mt-3 flex items-center justify-between text-sm text-gray-500 dark:text-gray-400">
                      <div className="flex items-center space-x-4">
                        <div className="flex items-center">
                          <CalendarIcon className="h-4 w-4 mr-1" />
                          {new Date(protocol.scheduledDate).toLocaleDateString()}
                          {daysUntil === 0 && (
                            <span className="ml-1 text-red-600 font-medium">(Today)</span>
                          )}
                          {daysUntil === 1 && (
                            <span className="ml-1 text-yellow-600 font-medium">(Tomorrow)</span>
                          )}
                        </div>
                        {protocol.assignedTo ? (
                          <div className="flex items-center">
                            <UserIcon className="h-4 w-4 mr-1" />
                            {protocol.assignedTo.displayName}
                          </div>
                        ) : (
                          <span className="text-yellow-600">Unassigned</span>
                        )}
                      </div>
                      <div className="flex items-center">
                        <span className="mr-2">{completedItems}/{totalItems} items</span>
                        <div className="w-20 h-2 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
                          <div
                            className="h-full bg-green-500 rounded-full"
                            style={{ width: `${percentage}%` }}
                          ></div>
                        </div>
                      </div>
                    </div>

                    <div className="mt-4 flex space-x-2">
                      {protocol.status === 'PENDING' && !protocol.assignedTo && (
                        <button
                          onClick={() => handleAssignToMe(protocol.id)}
                          className="text-sm px-3 py-1.5 bg-emerald-600 text-white rounded hover:bg-emerald-700"
                        >
                          Assign to Me
                        </button>
                      )}
                      {protocol.status === 'PENDING' && protocol.assignedTo && (
                        <button
                          onClick={() => handleStartProtocol(protocol.id)}
                          className="text-sm px-3 py-1.5 bg-green-600 text-white rounded hover:bg-green-700 flex items-center"
                        >
                          <PlayIcon className="h-4 w-4 mr-1" />
                          Start Protocol
                        </button>
                      )}
                      <button
                        onClick={() => setSelectedProtocol(protocol)}
                        className="text-sm px-3 py-1.5 bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded hover:bg-gray-200 dark:hover:bg-gray-600"
                      >
                        View Details
                      </button>
                    </div>
                  </div>
                </div>
              );
            })
          )}
        </div>
      </div>
    </div>
  );
}

function ProtocolDetailView({
  protocol,
  onBack,
  onCompleteItem,
}: {
  protocol: HouseProtocol;
  onBack: () => void;
  onCompleteItem: (protocolId: string, itemId: string) => void;
}) {
  return (
    <div className="min-h-screen bg-gray-100 dark:bg-gray-900 p-6">
      <div className="max-w-2xl mx-auto">
        {/* Header */}
        <div className="flex items-center space-x-4 mb-6">
          <button onClick={onBack} className="p-2 hover:bg-gray-200 dark:hover:bg-gray-800 rounded-lg">
            <ArrowLeftIcon className="h-5 w-5 text-gray-600 dark:text-gray-400" />
          </button>
          <div className="flex-1">
            <h1 className="text-xl font-bold text-gray-900 dark:text-white">
              {protocol.household?.name}
            </h1>
            <p className="text-gray-500 dark:text-gray-400">
              {protocol.trip?.destination} &middot; {new Date(protocol.scheduledDate).toLocaleDateString()}
            </p>
          </div>
          <span
            className={`px-2 py-1 rounded text-sm ${STATUS_COLORS[protocol.status].bg} ${STATUS_COLORS[protocol.status].text}`}
          >
            {protocol.status.replace('_', ' ')}
          </span>
        </div>

        {/* Checklist */}
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow">
          <div className="p-4 border-b border-gray-200 dark:border-gray-700">
            <h2 className="font-semibold text-gray-900 dark:text-white">Security Checklist</h2>
          </div>
          <div className="divide-y divide-gray-200 dark:divide-gray-700">
            {protocol.items?.map((item) => (
              <div key={item.id} className="p-4">
                <div className="flex items-start space-x-3">
                  {item.status === 'COMPLETED' ? (
                    <CheckCircleIcon className="h-6 w-6 text-green-500 flex-shrink-0" />
                  ) : item.status === 'BLOCKED' ? (
                    <div className="h-6 w-6 rounded-full bg-red-500 flex items-center justify-center flex-shrink-0">
                      <span className="text-white text-xs">!</span>
                    </div>
                  ) : (
                    <button
                      onClick={() => onCompleteItem(protocol.id, item.id)}
                      className="h-6 w-6 rounded-full border-2 border-gray-300 dark:border-gray-600 hover:border-green-500 flex-shrink-0"
                    />
                  )}
                  <div className="flex-1">
                    <p className={`font-medium ${item.status === 'COMPLETED' ? 'text-gray-500 line-through' : 'text-gray-900 dark:text-white'}`}>
                      {item.title}
                    </p>
                    {item.description && (
                      <p className="text-sm text-gray-500 dark:text-gray-400">{item.description}</p>
                    )}
                    {item.category && (
                      <span className="inline-block mt-1 text-xs bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400 px-2 py-0.5 rounded">
                        {item.category}
                      </span>
                    )}
                  </div>
                  {item.isRequired && (
                    <span className="text-xs bg-red-100 text-red-700 dark:bg-red-900 dark:text-red-300 px-2 py-0.5 rounded">
                      Required
                    </span>
                  )}
                </div>
                {item.completedBy && (
                  <p className="mt-2 text-xs text-gray-400 ml-9">
                    Completed by {item.completedBy.displayName} on{' '}
                    {item.completedAt && new Date(item.completedAt).toLocaleString()}
                  </p>
                )}
              </div>
            ))}
          </div>
        </div>

        {protocol.notes && (
          <div className="mt-4 bg-white dark:bg-gray-800 rounded-lg shadow p-4">
            <h3 className="font-medium text-gray-900 dark:text-white mb-2">Notes</h3>
            <p className="text-gray-700 dark:text-gray-300">{protocol.notes}</p>
          </div>
        )}
      </div>
    </div>
  );
}
