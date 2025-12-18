'use client';

import { useState, useEffect, useCallback } from 'react';
import Link from 'next/link';
import { useAuth } from '@/contexts/auth-context';
import { getApiClient } from '@/lib/api';
import type { RecommendationRequest, HouseholdVendor } from '@haven/core';

export default function CommunityAsksPage() {
  const { currentHousehold, isLoading: authLoading } = useAuth();

  const [nearbyRequests, setNearbyRequests] = useState<RecommendationRequest[]>([]);
  const [myRequests, setMyRequests] = useState<RecommendationRequest[]>([]);
  const [vendors, setVendors] = useState<HouseholdVendor[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<'nearby' | 'mine'>('nearby');
  const [selectedRequest, setSelectedRequest] = useState<RecommendationRequest | null>(null);

  const loadData = useCallback(async () => {
    if (!currentHousehold) {
      setIsLoading(false);
      return;
    }

    try {
      const api = getApiClient();
      const [nearbyData, myData, vendorsData] = await Promise.all([
        api.getNearbyRecommendationRequests().catch(() => []),
        api.getMyRecommendationRequests().catch(() => ({ requests: [], total: 0 })),
        api.getHouseholdVendors(currentHousehold.id).catch(() => []),
      ]);
      setNearbyRequests(nearbyData);
      setMyRequests(myData.requests);
      setVendors(vendorsData);
    } catch (error) {
      console.error('Failed to load data:', error);
    } finally {
      setIsLoading(false);
    }
  }, [currentHousehold]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const formatDate = (date: string | Date | undefined) => {
    if (!date) return '';
    const d = new Date(date);
    const now = new Date();
    const diffDays = Math.floor((now.getTime() - d.getTime()) / (1000 * 60 * 60 * 24));

    if (diffDays === 0) return 'Today';
    if (diffDays === 1) return 'Yesterday';
    if (diffDays < 7) return `${diffDays} days ago`;
    return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  };

  const getBudgetLabel = (budget: string | null | undefined) => {
    if (!budget) return null;
    const labels: Record<string, string> = {
      under_5k: 'Under $5k',
      '5k_15k': '$5k - $15k',
      '15k_30k': '$15k - $30k',
      '30k_plus': '$30k+',
    };
    return labels[budget] || budget;
  };

  const getTimelineLabel = (timeline: string | null | undefined) => {
    if (!timeline) return null;
    const labels: Record<string, string> = {
      flexible: 'Flexible',
      '1_month': 'Within 1 month',
      '3_months': 'Within 3 months',
      '6_months': 'Within 6 months',
    };
    return labels[timeline] || timeline;
  };

  if (authLoading || isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-600"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-slate-900 dark:text-white">
          Community Asks
        </h1>
        <p className="text-slate-600 dark:text-slate-400 mt-1">
          Help your neighbors find great contractors by sharing your recommendations
        </p>
      </div>

      {/* Tabs */}
      <div className="border-b border-slate-200 dark:border-slate-700">
        <nav className="flex gap-6">
          <button
            onClick={() => setActiveTab('nearby')}
            className={`pb-3 border-b-2 font-medium text-sm transition-colors ${
              activeTab === 'nearby'
                ? 'border-emerald-600 text-emerald-600 dark:text-emerald-400'
                : 'border-transparent text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
            }`}
          >
            Neighbors&apos; Asks
            {nearbyRequests.length > 0 && (
              <span className="ml-2 px-2 py-0.5 rounded-full text-xs bg-emerald-100 dark:bg-emerald-900/30 text-emerald-600 dark:text-emerald-400">
                {nearbyRequests.length}
              </span>
            )}
          </button>
          <button
            onClick={() => setActiveTab('mine')}
            className={`pb-3 border-b-2 font-medium text-sm transition-colors ${
              activeTab === 'mine'
                ? 'border-emerald-600 text-emerald-600 dark:text-emerald-400'
                : 'border-transparent text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
            }`}
          >
            My Requests
            {myRequests.length > 0 && (
              <span className="ml-2 px-2 py-0.5 rounded-full text-xs bg-slate-100 dark:bg-slate-800">
                {myRequests.length}
              </span>
            )}
          </button>
        </nav>
      </div>

      {/* Content */}
      {activeTab === 'nearby' && (
        <>
          {nearbyRequests.length === 0 ? (
            <div className="card text-center py-12">
              <div className="text-5xl mb-4">🏘️</div>
              <h3 className="text-lg font-medium text-slate-900 dark:text-white mb-2">
                No nearby asks yet
              </h3>
              <p className="text-slate-600 dark:text-slate-400 max-w-md mx-auto">
                When your neighbors are looking for contractor recommendations, their requests will appear here.
              </p>
            </div>
          ) : (
            <div className="grid gap-4">
              {nearbyRequests.map((request) => (
                <div
                  key={request.id}
                  className="card cursor-pointer hover:border-emerald-500 dark:hover:border-emerald-400 transition-colors"
                  onClick={() => setSelectedRequest(request)}
                >
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <div className="flex items-center gap-3 mb-2">
                        <h3 className="font-medium text-slate-900 dark:text-white">
                          {request.title}
                        </h3>
                        <span className="px-2 py-0.5 rounded-full text-xs bg-green-100 dark:bg-green-900/30 text-green-600 dark:text-green-400">
                          Open
                        </span>
                      </div>

                      {request.description && (
                        <p className="text-sm text-slate-600 dark:text-slate-400 mb-3 line-clamp-2">
                          {request.description}
                        </p>
                      )}

                      <div className="flex flex-wrap gap-3 text-sm">
                        {request.projectIdea && (
                          <span className="text-slate-500 dark:text-slate-400">
                            {request.projectIdea.category.replace(/_/g, ' ')}
                          </span>
                        )}
                        {getBudgetLabel(request.budget) && (
                          <span className="text-slate-500 dark:text-slate-400">
                            Budget: {getBudgetLabel(request.budget)}
                          </span>
                        )}
                        {getTimelineLabel(request.timeline) && (
                          <span className="text-slate-500 dark:text-slate-400">
                            {getTimelineLabel(request.timeline)}
                          </span>
                        )}
                        <span className="text-slate-400 dark:text-slate-500">
                          {formatDate(request.createdAt)}
                        </span>
                      </div>
                    </div>

                    <div className="text-right ml-4">
                      <div className="text-2xl font-bold text-emerald-600 dark:text-emerald-400">
                        {request.suggestionCount}
                      </div>
                      <div className="text-xs text-slate-500 dark:text-slate-400">
                        suggestions
                      </div>
                    </div>
                  </div>

                  <div className="mt-4 pt-4 border-t border-slate-100 dark:border-slate-700 flex items-center justify-between">
                    <div className="flex items-center gap-2 text-sm text-slate-600 dark:text-slate-400">
                      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                      </svg>
                      <span>Near you</span>
                    </div>
                    <button className="btn btn-primary text-sm">
                      Suggest a Contractor
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </>
      )}

      {activeTab === 'mine' && (
        <>
          {myRequests.length === 0 ? (
            <div className="card text-center py-12">
              <div className="text-5xl mb-4">📝</div>
              <h3 className="text-lg font-medium text-slate-900 dark:text-white mb-2">
                No requests yet
              </h3>
              <p className="text-slate-600 dark:text-slate-400 max-w-md mx-auto mb-6">
                Start a project and ask your neighbors for contractor recommendations.
              </p>
              <Link href="/app/projects/new" className="btn btn-primary">
                Start a Project
              </Link>
            </div>
          ) : (
            <div className="grid gap-4">
              {myRequests.map((request) => (
                <div key={request.id} className="card">
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <div className="flex items-center gap-3 mb-2">
                        <h3 className="font-medium text-slate-900 dark:text-white">
                          {request.title}
                        </h3>
                        <span className={`px-2 py-0.5 rounded-full text-xs ${
                          request.status === 'OPEN'
                            ? 'bg-green-100 dark:bg-green-900/30 text-green-600 dark:text-green-400'
                            : request.status === 'REVIEWING'
                            ? 'bg-yellow-100 dark:bg-yellow-900/30 text-yellow-600 dark:text-yellow-400'
                            : 'bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400'
                        }`}>
                          {request.status}
                        </span>
                      </div>

                      <div className="flex flex-wrap gap-3 text-sm text-slate-500 dark:text-slate-400">
                        <span>{request.viewCount} views</span>
                        <span>{request.suggestionCount} suggestions</span>
                        <span>{formatDate(request.createdAt)}</span>
                      </div>
                    </div>

                    {request.projectIdea && (
                      <Link
                        href={`/app/projects/${request.projectIdea.id}`}
                        className="btn btn-secondary text-sm"
                      >
                        View Project
                      </Link>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </>
      )}

      {/* Suggest Modal */}
      {selectedRequest && (
        <SuggestVendorModal
          request={selectedRequest}
          vendors={vendors}
          onClose={() => setSelectedRequest(null)}
          onSuccess={() => {
            setSelectedRequest(null);
            loadData();
          }}
        />
      )}
    </div>
  );
}

// Suggest Vendor Modal Component
function SuggestVendorModal({
  request,
  vendors,
  onClose,
  onSuccess,
}: {
  request: RecommendationRequest;
  vendors: HouseholdVendor[];
  onClose: () => void;
  onSuccess: () => void;
}) {
  const [vendorId, setVendorId] = useState('');
  const [comment, setComment] = useState('');
  const [rating, setRating] = useState<number | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!vendorId) {
      setError('Please select a vendor');
      return;
    }

    setError('');
    setIsSubmitting(true);

    try {
      const api = getApiClient();
      await api.submitVendorSuggestion(request.id, {
        vendorId,
        comment: comment || undefined,
        rating: rating || undefined,
      });
      onSuccess();
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Failed to submit suggestion';
      setError(message);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      <div className="flex min-h-screen items-center justify-center p-4">
        <div className="fixed inset-0 bg-black/50 transition-opacity" onClick={onClose} />

        <div className="relative w-full max-w-lg bg-white dark:bg-slate-800 rounded-xl shadow-xl">
          <div className="flex items-center justify-between p-6 border-b border-slate-200 dark:border-slate-700">
            <h2 className="text-lg font-semibold text-slate-900 dark:text-white">
              Suggest a Contractor
            </h2>
            <button onClick={onClose} className="p-1 text-slate-400 hover:text-slate-500">
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <form onSubmit={handleSubmit} className="p-6 space-y-4">
            {/* Request Info */}
            <div className="p-3 rounded-lg bg-slate-50 dark:bg-slate-900/50">
              <h4 className="font-medium text-slate-900 dark:text-white text-sm mb-1">
                {request.title}
              </h4>
              {request.description && (
                <p className="text-sm text-slate-600 dark:text-slate-400 line-clamp-2">
                  {request.description}
                </p>
              )}
            </div>

            {error && (
              <div className="p-3 rounded-lg bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800">
                <p className="text-sm text-red-600 dark:text-red-400">{error}</p>
              </div>
            )}

            {/* Vendor Selection */}
            <div>
              <label className="label block mb-1.5">
                Select Vendor <span className="text-red-500">*</span>
              </label>
              {vendors.length > 0 ? (
                <select
                  value={vendorId}
                  onChange={(e) => setVendorId(e.target.value)}
                  className="input"
                  required
                >
                  <option value="">Choose a vendor you&apos;ve worked with</option>
                  {vendors.map((vendor) => (
                    <option key={vendor.id} value={vendor.id}>
                      {vendor.displayName}
                    </option>
                  ))}
                </select>
              ) : (
                <div className="p-3 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
                  <p className="text-sm text-amber-700 dark:text-amber-300">
                    You don&apos;t have any vendors in your household yet. Add vendors in your Settings.
                  </p>
                </div>
              )}
            </div>

            {/* Rating */}
            <div>
              <label className="label block mb-1.5">Your Rating</label>
              <div className="flex gap-1">
                {[1, 2, 3, 4, 5].map((star) => (
                  <button
                    key={star}
                    type="button"
                    onClick={() => setRating(star)}
                    className={`p-1 transition-colors ${
                      rating && star <= rating
                        ? 'text-yellow-400'
                        : 'text-slate-300 dark:text-slate-600 hover:text-yellow-300'
                    }`}
                  >
                    <svg className="w-8 h-8 fill-current" viewBox="0 0 20 20">
                      <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
                    </svg>
                  </button>
                ))}
              </div>
            </div>

            {/* Comment */}
            <div>
              <label className="label block mb-1.5">Your Recommendation</label>
              <textarea
                value={comment}
                onChange={(e) => setComment(e.target.value)}
                className="input min-h-[100px]"
                placeholder="Why do you recommend this contractor? What work did they do for you?"
              />
            </div>

            <div className="flex justify-end gap-3 pt-4">
              <button type="button" onClick={onClose} className="btn btn-secondary">
                Cancel
              </button>
              <button
                type="submit"
                disabled={isSubmitting || !vendorId}
                className="btn btn-primary"
              >
                {isSubmitting ? 'Submitting...' : 'Submit Suggestion'}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}
