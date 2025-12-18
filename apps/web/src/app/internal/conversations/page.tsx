'use client';

import { useEffect, useState } from 'react';
import { useSearchParams, useRouter } from 'next/navigation';
import Link from 'next/link';
import type { InternalConversation } from '@haven/core';
import { getApiClient } from '@/lib/api';

type FilterStatus = 'all' | 'unassigned' | 'assigned' | 'closed';

export default function InternalConversationsPage() {
  const router = useRouter();
  const searchParams = useSearchParams();

  const [conversations, setConversations] = useState<InternalConversation[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [activeFilter, setActiveFilter] = useState<FilterStatus>(
    (searchParams.get('status') as FilterStatus) || 'all'
  );

  const fetchConversations = async (status: FilterStatus) => {
    setIsLoading(true);
    try {
      const api = getApiClient();
      const data = await api.getInternalConversations({ status });
      setConversations(data);
      setError(null);
    } catch (err: any) {
      setError(err.message || 'Failed to load conversations');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchConversations(activeFilter);
  }, [activeFilter]);

  const handleFilterChange = (filter: FilterStatus) => {
    setActiveFilter(filter);
    router.push(`/internal/conversations?status=${filter}`);
  };

  const handleAssignToMe = async (conversationId: string) => {
    try {
      const api = getApiClient();
      await api.assignInternalConversation(conversationId);
      // Refresh list
      fetchConversations(activeFilter);
    } catch (err: any) {
      alert(err.message || 'Failed to assign conversation');
    }
  };

  const handleCloseConversation = async (conversationId: string) => {
    try {
      const api = getApiClient();
      await api.updateInternalConversationStatus(conversationId, 'CLOSED');
      // Refresh list
      fetchConversations(activeFilter);
    } catch (err: any) {
      alert(err.message || 'Failed to close conversation');
    }
  };

  const filters: { id: FilterStatus; label: string }[] = [
    { id: 'all', label: 'All Open' },
    { id: 'unassigned', label: 'Unassigned' },
    { id: 'assigned', label: 'Assigned to Me' },
    { id: 'closed', label: 'Closed' },
  ];

  const getStatusBadge = (status: string) => {
    const styles: Record<string, string> = {
      OPEN: 'bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400',
      PENDING: 'bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-400',
      CLOSED: 'bg-slate-100 dark:bg-slate-700 text-slate-700 dark:text-slate-300',
    };
    return styles[status] || styles.OPEN;
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-slate-900 dark:text-white">Support Queue</h1>
        <p className="text-slate-600 dark:text-slate-400 mt-1">
          Manage homeowner support conversations
        </p>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap gap-2">
        {filters.map((filter) => (
          <button
            key={filter.id}
            onClick={() => handleFilterChange(filter.id)}
            className={`px-4 py-2 text-sm font-medium rounded-lg transition-colors ${
              activeFilter === filter.id
                ? 'bg-indigo-600 text-white'
                : 'bg-white dark:bg-slate-800 text-slate-700 dark:text-slate-300 border border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-700'
            }`}
          >
            {filter.label}
          </button>
        ))}
      </div>

      {/* Loading */}
      {isLoading && (
        <div className="flex items-center justify-center py-12">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
        </div>
      )}

      {/* Error */}
      {error && (
        <div className="bg-red-50 dark:bg-red-900/20 text-red-600 dark:text-red-400 p-4 rounded-lg">
          {error}
        </div>
      )}

      {/* Conversations List */}
      {!isLoading && !error && (
        <div className="bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 divide-y divide-slate-200 dark:divide-slate-700">
          {conversations.length === 0 ? (
            <div className="px-5 py-12 text-center text-slate-500 dark:text-slate-400">
              No conversations found
            </div>
          ) : (
            conversations.map((conv) => (
              <div key={conv.id} className="p-5">
                <div className="flex items-start justify-between gap-4">
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 mb-1">
                      <Link
                        href={`/internal/households/${conv.household.id}`}
                        className="text-sm text-indigo-600 dark:text-indigo-400 hover:underline"
                      >
                        {conv.household.name}
                      </Link>
                      <span className={`text-xs px-2 py-0.5 rounded-full ${getStatusBadge(conv.status)}`}>
                        {conv.status}
                      </span>
                      {conv.homeManagerUnreadCount > 0 && (
                        <span className="text-xs bg-red-500 text-white px-2 py-0.5 rounded-full">
                          {conv.homeManagerUnreadCount} new
                        </span>
                      )}
                    </div>
                    <p className="font-medium text-slate-900 dark:text-white truncate">
                      {conv.subject || 'No subject'}
                    </p>
                    <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
                      From: {conv.household.owner.firstName} {conv.household.owner.lastName} ({conv.household.owner.email})
                    </p>
                    <p className="text-sm text-slate-500 dark:text-slate-400">
                      {conv._count.messages} message{conv._count.messages !== 1 ? 's' : ''} - Last updated{' '}
                      {new Date(conv.updatedAt).toLocaleString()}
                    </p>
                  </div>

                  <div className="flex flex-col gap-2">
                    {/* Assigned To */}
                    {conv.assignedTo ? (
                      <div className="text-right">
                        <p className="text-xs text-slate-500 dark:text-slate-400">Assigned to</p>
                        <p className="text-sm font-medium text-slate-900 dark:text-white">
                          {conv.assignedTo.firstName} {conv.assignedTo.lastName}
                        </p>
                      </div>
                    ) : (
                      <span className="text-sm text-amber-600 dark:text-amber-400">Unassigned</span>
                    )}

                    {/* Actions */}
                    <div className="flex gap-2">
                      {!conv.assignedTo && conv.status !== 'CLOSED' && (
                        <button
                          onClick={() => handleAssignToMe(conv.id)}
                          className="px-3 py-1 text-xs font-medium text-indigo-600 dark:text-indigo-400 bg-indigo-50 dark:bg-indigo-900/20 hover:bg-indigo-100 dark:hover:bg-indigo-900/40 rounded-lg transition-colors"
                        >
                          Assign to me
                        </button>
                      )}
                      {conv.status !== 'CLOSED' && (
                        <button
                          onClick={() => handleCloseConversation(conv.id)}
                          className="px-3 py-1 text-xs font-medium text-slate-600 dark:text-slate-400 bg-slate-100 dark:bg-slate-700 hover:bg-slate-200 dark:hover:bg-slate-600 rounded-lg transition-colors"
                        >
                          Close
                        </button>
                      )}
                    </div>
                  </div>
                </div>
              </div>
            ))
          )}
        </div>
      )}
    </div>
  );
}
