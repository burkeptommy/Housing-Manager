'use client';

import { useEffect, useState } from 'react';
import { useSearchParams, useRouter } from 'next/navigation';
import Link from 'next/link';
import type { InboundRequest, TriageStats, TriageStatus, RequestCategory, ExecutionResult } from '@haven/core';
import { getApiClient } from '@/lib/api';

type FilterStatus = TriageStatus | 'ALL';

const STATUS_CONFIG: Record<TriageStatus, { label: string; color: string; bgColor: string }> = {
  RECEIVED: { label: 'New', color: 'text-emerald-700 dark:text-emerald-400', bgColor: 'bg-emerald-100 dark:bg-emerald-900/30' },
  PROCESSING: { label: 'Processing', color: 'text-amber-700 dark:text-amber-400', bgColor: 'bg-amber-100 dark:bg-amber-900/30' },
  PENDING_REVIEW: { label: 'Pending Review', color: 'text-purple-700 dark:text-purple-400', bgColor: 'bg-purple-100 dark:bg-purple-900/30' },
  AUTO_APPROVED: { label: 'Auto-Approved', color: 'text-green-700 dark:text-green-400', bgColor: 'bg-green-100 dark:bg-green-900/30' },
  NEEDS_ATTENTION: { label: 'Needs Attention', color: 'text-red-700 dark:text-red-400', bgColor: 'bg-red-100 dark:bg-red-900/30' },
  RESOLVED: { label: 'Resolved', color: 'text-slate-700 dark:text-slate-400', bgColor: 'bg-slate-100 dark:bg-slate-700' },
  REJECTED: { label: 'Rejected', color: 'text-slate-500 dark:text-slate-500', bgColor: 'bg-slate-50 dark:bg-slate-800' },
  ERROR: { label: 'Error', color: 'text-red-700 dark:text-red-400', bgColor: 'bg-red-100 dark:bg-red-900/30' },
};

const CATEGORY_LABELS: Record<RequestCategory, string> = {
  BILL_PAY: 'Bill Payment',
  FIX_REQUEST: 'Fix/Repair',
  PROJECT_IDEA: 'Project Idea',
  CALENDAR_EVENT: 'Calendar Event',
  TRIP_PLAN: 'Trip Planning',
  GENERAL_INQUIRY: 'General Inquiry',
  UNKNOWN: 'Unknown',
};

const SOURCE_ICONS: Record<string, React.ReactNode> = {
  EMAIL: (
    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
    </svg>
  ),
  SMS: (
    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z" />
    </svg>
  ),
  CHAT: (
    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
    </svg>
  ),
  WEB: (
    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s-1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 019-9" />
    </svg>
  ),
  VOICE: (
    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
    </svg>
  ),
};

export default function TriageCenterPage() {
  const router = useRouter();
  const searchParams = useSearchParams();

  const [requests, setRequests] = useState<InboundRequest[]>([]);
  const [stats, setStats] = useState<TriageStats | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [activeFilter, setActiveFilter] = useState<FilterStatus>(
    (searchParams.get('status') as FilterStatus) || 'ALL'
  );
  const [selectedRequest, setSelectedRequest] = useState<InboundRequest | null>(null);
  const [isProcessing, setIsProcessing] = useState(false);

  const fetchData = async (status: FilterStatus) => {
    setIsLoading(true);
    try {
      const api = getApiClient();
      const [requestsData, statsData] = await Promise.all([
        api.getTriageRequests(status === 'ALL' ? undefined : { status: status as TriageStatus }),
        api.getTriageStats(),
      ]);
      setRequests(requestsData);
      setStats(statsData);
      setError(null);
    } catch (err: unknown) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to load triage data';
      setError(errorMessage);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchData(activeFilter);
    // Auto-refresh every 30 seconds
    const interval = setInterval(() => fetchData(activeFilter), 30000);
    return () => clearInterval(interval);
  }, [activeFilter]);

  const handleFilterChange = (filter: FilterStatus) => {
    setActiveFilter(filter);
    router.push(`/internal/triage${filter === 'ALL' ? '' : `?status=${filter}`}`);
  };

  const handleApprove = async (request: InboundRequest, suggestionId: string) => {
    setIsProcessing(true);
    try {
      const api = getApiClient();
      const result: ExecutionResult = await api.approveTriageAction({
        requestId: request.id,
        suggestionId,
      });
      if (result.success) {
        alert(`Action executed: ${result.message}`);
        fetchData(activeFilter);
        setSelectedRequest(null);
      } else {
        alert(`Failed: ${result.error || result.message}`);
      }
    } catch (err: unknown) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to approve action';
      alert(errorMessage);
    } finally {
      setIsProcessing(false);
    }
  };

  const handleReject = async (request: InboundRequest) => {
    const reason = prompt('Enter rejection reason:');
    if (!reason) return;

    setIsProcessing(true);
    try {
      const api = getApiClient();
      await api.rejectTriageRequest(request.id, reason);
      fetchData(activeFilter);
      setSelectedRequest(null);
    } catch (err: unknown) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to reject request';
      alert(errorMessage);
    } finally {
      setIsProcessing(false);
    }
  };

  const filters: { id: FilterStatus; label: string; count?: number }[] = [
    { id: 'ALL', label: 'All', count: stats?.total },
    { id: 'PENDING_REVIEW', label: 'Pending Review', count: stats?.pendingReviewCount },
    { id: 'NEEDS_ATTENTION', label: 'Needs Attention', count: stats?.needsAttentionCount },
    { id: 'RECEIVED', label: 'New' },
    { id: 'RESOLVED', label: 'Resolved' },
    { id: 'REJECTED', label: 'Rejected' },
  ];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 dark:text-white">Triage Command Center</h1>
          <p className="text-slate-600 dark:text-slate-400 mt-1">
            AI-powered request classification and routing
          </p>
        </div>
        {stats && (
          <div className="flex items-center gap-4 text-sm">
            <div className="text-center">
              <p className="text-2xl font-bold text-indigo-600 dark:text-indigo-400">{stats.todayCount}</p>
              <p className="text-slate-500 dark:text-slate-400">Today</p>
            </div>
            <div className="text-center">
              <p className="text-2xl font-bold text-purple-600 dark:text-purple-400">{stats.pendingReviewCount}</p>
              <p className="text-slate-500 dark:text-slate-400">Pending</p>
            </div>
            <div className="text-center">
              <p className="text-2xl font-bold text-red-600 dark:text-red-400">{stats.needsAttentionCount}</p>
              <p className="text-slate-500 dark:text-slate-400">Attention</p>
            </div>
          </div>
        )}
      </div>

      {/* Filters */}
      <div className="flex flex-wrap gap-2">
        {filters.map((filter) => (
          <button
            key={filter.id}
            onClick={() => handleFilterChange(filter.id)}
            className={`px-4 py-2 text-sm font-medium rounded-lg transition-colors flex items-center gap-2 ${
              activeFilter === filter.id
                ? 'bg-indigo-600 text-white'
                : 'bg-white dark:bg-slate-800 text-slate-700 dark:text-slate-300 border border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-700'
            }`}
          >
            {filter.label}
            {filter.count !== undefined && (
              <span className={`text-xs px-1.5 py-0.5 rounded-full ${
                activeFilter === filter.id
                  ? 'bg-indigo-500'
                  : 'bg-slate-100 dark:bg-slate-700'
              }`}>
                {filter.count}
              </span>
            )}
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

      {/* Main content grid */}
      {!isLoading && !error && (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Request list */}
          <div className="lg:col-span-2 bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 divide-y divide-slate-200 dark:divide-slate-700 overflow-hidden">
            {requests.length === 0 ? (
              <div className="px-5 py-12 text-center text-slate-500 dark:text-slate-400">
                <svg className="w-12 h-12 mx-auto mb-4 text-slate-300 dark:text-slate-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4" />
                </svg>
                <p className="font-medium">No requests found</p>
                <p className="text-sm">All caught up!</p>
              </div>
            ) : (
              requests.map((request) => (
                <button
                  key={request.id}
                  onClick={() => setSelectedRequest(request)}
                  className={`w-full p-4 text-left hover:bg-slate-50 dark:hover:bg-slate-700/50 transition-colors ${
                    selectedRequest?.id === request.id ? 'bg-indigo-50 dark:bg-indigo-900/20' : ''
                  }`}
                >
                  <div className="flex items-start gap-3">
                    {/* Source icon */}
                    <div className="mt-1 text-slate-400">
                      {SOURCE_ICONS[request.source] || SOURCE_ICONS.EMAIL}
                    </div>

                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-1">
                        <span className={`text-xs px-2 py-0.5 rounded-full ${STATUS_CONFIG[request.status].bgColor} ${STATUS_CONFIG[request.status].color}`}>
                          {STATUS_CONFIG[request.status].label}
                        </span>
                        {request.category && (
                          <span className="text-xs text-slate-500 dark:text-slate-400">
                            {CATEGORY_LABELS[request.category]}
                          </span>
                        )}
                        {request.aiConfidence && (
                          <span className="text-xs text-slate-400">
                            {Math.round(request.aiConfidence * 100)}% conf.
                          </span>
                        )}
                      </div>

                      <p className="font-medium text-slate-900 dark:text-white truncate">
                        {request.subject || request.summary || 'No subject'}
                      </p>

                      <p className="text-sm text-slate-600 dark:text-slate-400 line-clamp-2 mt-1">
                        {request.body}
                      </p>

                      <div className="flex items-center gap-4 mt-2 text-xs text-slate-500 dark:text-slate-400">
                        <span>
                          {request.senderEmail || request.senderPhone || request.senderUser?.email || 'Unknown sender'}
                        </span>
                        {request.household && (
                          <span className="flex items-center gap-1">
                            <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
                            </svg>
                            {request.household.name}
                          </span>
                        )}
                        <span>{new Date(request.createdAt).toLocaleString()}</span>
                      </div>
                    </div>

                    {/* Action hint */}
                    {(request.status === 'PENDING_REVIEW' || request.status === 'NEEDS_ATTENTION') && (
                      <div className="flex-shrink-0">
                        <span className="px-2 py-1 text-xs font-medium text-indigo-600 dark:text-indigo-400 bg-indigo-100 dark:bg-indigo-900/30 rounded">
                          Review
                        </span>
                      </div>
                    )}
                  </div>
                </button>
              ))
            )}
          </div>

          {/* Detail panel */}
          <div className="bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 overflow-hidden">
            {selectedRequest ? (
              <div className="h-full flex flex-col">
                {/* Detail header */}
                <div className="p-4 border-b border-slate-200 dark:border-slate-700">
                  <div className="flex items-center justify-between mb-2">
                    <span className={`text-xs px-2 py-0.5 rounded-full ${STATUS_CONFIG[selectedRequest.status].bgColor} ${STATUS_CONFIG[selectedRequest.status].color}`}>
                      {STATUS_CONFIG[selectedRequest.status].label}
                    </span>
                    <button
                      onClick={() => setSelectedRequest(null)}
                      className="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200"
                    >
                      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                      </svg>
                    </button>
                  </div>
                  <h3 className="font-semibold text-slate-900 dark:text-white">
                    {selectedRequest.subject || selectedRequest.summary || 'Request Details'}
                  </h3>
                </div>

                {/* Detail body */}
                <div className="flex-1 overflow-y-auto p-4 space-y-4">
                  {/* Sender info */}
                  <div>
                    <p className="text-xs font-medium text-slate-500 dark:text-slate-400 uppercase mb-1">From</p>
                    <p className="text-sm text-slate-900 dark:text-white">
                      {selectedRequest.senderUser?.displayName ||
                        selectedRequest.senderUser?.email ||
                        selectedRequest.senderEmail ||
                        selectedRequest.senderPhone ||
                        'Unknown'}
                    </p>
                  </div>

                  {/* Household */}
                  {selectedRequest.household ? (
                    <div>
                      <p className="text-xs font-medium text-slate-500 dark:text-slate-400 uppercase mb-1">Household</p>
                      <Link
                        href={`/internal/households/${selectedRequest.householdId}`}
                        className="text-sm text-indigo-600 dark:text-indigo-400 hover:underline"
                      >
                        {selectedRequest.household.name}
                      </Link>
                    </div>
                  ) : (
                    <div className="p-3 bg-amber-50 dark:bg-amber-900/20 rounded-lg border border-amber-200 dark:border-amber-800">
                      <p className="text-sm text-amber-700 dark:text-amber-400">
                        No household linked. Link to enable action execution.
                      </p>
                    </div>
                  )}

                  {/* Message */}
                  <div>
                    <p className="text-xs font-medium text-slate-500 dark:text-slate-400 uppercase mb-1">Message</p>
                    <div className="text-sm text-slate-700 dark:text-slate-300 whitespace-pre-wrap bg-slate-50 dark:bg-slate-700/50 rounded-lg p-3">
                      {selectedRequest.body}
                    </div>
                  </div>

                  {/* AI Analysis */}
                  {selectedRequest.aiReasoning && (
                    <div>
                      <p className="text-xs font-medium text-slate-500 dark:text-slate-400 uppercase mb-1">AI Analysis</p>
                      <div className="text-sm text-slate-700 dark:text-slate-300 bg-indigo-50 dark:bg-indigo-900/20 rounded-lg p-3 border border-indigo-100 dark:border-indigo-800">
                        <div className="flex items-center gap-2 mb-2">
                          <span className="font-medium">Category:</span>
                          <span>{selectedRequest.category ? CATEGORY_LABELS[selectedRequest.category] : 'Unknown'}</span>
                          {selectedRequest.aiConfidence && (
                            <span className="text-xs bg-indigo-100 dark:bg-indigo-900/50 px-2 py-0.5 rounded">
                              {Math.round(selectedRequest.aiConfidence * 100)}% confidence
                            </span>
                          )}
                        </div>
                        <p>{selectedRequest.aiReasoning}</p>
                      </div>
                    </div>
                  )}

                  {/* Suggestions */}
                  {selectedRequest.suggestions && selectedRequest.suggestions.length > 0 && (
                    <div>
                      <p className="text-xs font-medium text-slate-500 dark:text-slate-400 uppercase mb-2">Suggested Actions</p>
                      <div className="space-y-2">
                        {selectedRequest.suggestions.map((suggestion) => (
                          <div
                            key={suggestion.id}
                            className="p-3 bg-slate-50 dark:bg-slate-700/50 rounded-lg border border-slate-200 dark:border-slate-600"
                          >
                            <div className="flex items-center justify-between mb-2">
                              <span className="font-medium text-sm text-slate-900 dark:text-white">
                                {suggestion.actionType.replace(/_/g, ' ')}
                              </span>
                              <span className="text-xs bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-400 px-2 py-0.5 rounded">
                                {Math.round(suggestion.confidence * 100)}%
                              </span>
                            </div>
                            <p className="text-xs text-slate-600 dark:text-slate-400 mb-2">{suggestion.reasoning}</p>
                            <pre className="text-xs bg-slate-100 dark:bg-slate-800 p-2 rounded overflow-x-auto">
                              {JSON.stringify(suggestion.actionData, null, 2)}
                            </pre>
                            {!suggestion.isApproved && selectedRequest.householdId && (
                              <button
                                onClick={() => handleApprove(selectedRequest, suggestion.id)}
                                disabled={isProcessing}
                                className="mt-2 w-full px-3 py-2 text-sm font-medium text-white bg-green-600 hover:bg-green-700 disabled:bg-green-400 rounded-lg transition-colors"
                              >
                                {isProcessing ? 'Processing...' : 'Approve & Execute'}
                              </button>
                            )}
                          </div>
                        ))}
                      </div>
                    </div>
                  )}
                </div>

                {/* Actions footer */}
                {(selectedRequest.status === 'PENDING_REVIEW' || selectedRequest.status === 'NEEDS_ATTENTION') && (
                  <div className="p-4 border-t border-slate-200 dark:border-slate-700 flex gap-2">
                    <button
                      onClick={() => handleReject(selectedRequest)}
                      disabled={isProcessing}
                      className="flex-1 px-3 py-2 text-sm font-medium text-red-600 dark:text-red-400 bg-red-50 dark:bg-red-900/20 hover:bg-red-100 dark:hover:bg-red-900/40 disabled:opacity-50 rounded-lg transition-colors"
                    >
                      Reject
                    </button>
                  </div>
                )}
              </div>
            ) : (
              <div className="h-full flex flex-col items-center justify-center text-slate-400 p-8">
                <svg className="w-16 h-16 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
                </svg>
                <p className="font-medium text-slate-600 dark:text-slate-300">Select a request</p>
                <p className="text-sm mt-1">Click on a request to view details and take action</p>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
