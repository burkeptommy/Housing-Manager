'use client';

import { useState, useEffect, useCallback } from 'react';
import { useRouter, useParams } from 'next/navigation';
import Link from 'next/link';
import { useAuth } from '@/contexts/auth-context';
import { getApiClient } from '@/lib/api';
import type { ProjectIdea, ProjectIdeaStatus, VendorSuggestion, NeighborInspiration } from '@haven/core';

// Status configuration
const STATUS_CONFIG: Record<ProjectIdeaStatus, { name: string; color: string; bgColor: string; icon: string }> = {
  DREAMING: {
    name: 'Dreaming',
    color: 'text-purple-600 dark:text-purple-400',
    bgColor: 'bg-purple-100 dark:bg-purple-900/20',
    icon: '💭',
  },
  PLANNING: {
    name: 'Planning',
    color: 'text-emerald-600 dark:text-emerald-400',
    bgColor: 'bg-emerald-100 dark:bg-emerald-900/20',
    icon: '📋',
  },
  ACTIVE: {
    name: 'Active',
    color: 'text-yellow-600 dark:text-yellow-400',
    bgColor: 'bg-yellow-100 dark:bg-yellow-900/20',
    icon: '🚧',
  },
  COMPLETED: {
    name: 'Completed',
    color: 'text-green-600 dark:text-green-400',
    bgColor: 'bg-green-100 dark:bg-green-900/20',
    icon: '✅',
  },
  ARCHIVED: {
    name: 'Archived',
    color: 'text-slate-600 dark:text-slate-400',
    bgColor: 'bg-slate-100 dark:bg-slate-900/20',
    icon: '📁',
  },
};

// Style display names
const STYLE_NAMES: Record<string, string> = {
  modern: 'Modern',
  traditional: 'Traditional',
  rustic: 'Rustic',
  industrial: 'Industrial',
  coastal: 'Coastal',
  farmhouse: 'Farmhouse',
  mid_century: 'Mid-Century Modern',
  contemporary: 'Contemporary',
  minimalist: 'Minimalist',
  not_sure: 'Not Sure Yet',
};

type TabType = 'overview' | 'who-to-hire' | 'inspiration';

export default function ProjectDetailPage() {
  const router = useRouter();
  const params = useParams();
  const id = params.id as string;
  const { currentHousehold, isLoading: authLoading } = useAuth();

  const [idea, setIdea] = useState<ProjectIdea | null>(null);
  const [suggestions, setSuggestions] = useState<VendorSuggestion[]>([]);
  const [inspiration, setInspiration] = useState<NeighborInspiration[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<TabType>('overview');
  const [isGeneratingSuggestions, setIsGeneratingSuggestions] = useState(false);
  const [showAskModal, setShowAskModal] = useState(false);

  const loadData = useCallback(async () => {
    if (!currentHousehold || !id) {
      setIsLoading(false);
      return;
    }

    try {
      const api = getApiClient();
      const ideaData = await api.getProjectIdea(id);
      setIdea(ideaData);

      // Load suggestions in parallel
      const [suggestionsData, inspirationData] = await Promise.all([
        api.getIdeaSuggestions(id).catch(() => []),
        api.getNeighborInspiration(id).catch(() => []),
      ]);
      setSuggestions(suggestionsData);
      setInspiration(inspirationData);
    } catch (error) {
      console.error('Failed to load project:', error);
      router.push('/app/projects');
    } finally {
      setIsLoading(false);
    }
  }, [currentHousehold, id, router]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const handleGenerateSuggestions = async () => {
    if (!id) return;
    setIsGeneratingSuggestions(true);
    try {
      const api = getApiClient();
      const newSuggestions = await api.generateVendorSuggestions(id);
      setSuggestions((prev) => [...prev, ...newSuggestions]);
    } catch (error) {
      console.error('Failed to generate suggestions:', error);
    } finally {
      setIsGeneratingSuggestions(false);
    }
  };

  const handleProgressStatus = async (newStatus: ProjectIdeaStatus) => {
    if (!id) return;
    try {
      const api = getApiClient();
      const updated = await api.progressProjectIdea(id, newStatus);
      setIdea(updated);
    } catch (error) {
      console.error('Failed to update status:', error);
    }
  };

  const handleArchive = async () => {
    if (!id) return;
    if (!confirm('Are you sure you want to archive this project?')) return;
    try {
      const api = getApiClient();
      await api.archiveProjectIdea(id);
      router.push('/app/projects');
    } catch (error) {
      console.error('Failed to archive project:', error);
    }
  };

  const handleConvertToWorkOrder = async () => {
    if (!id || !idea) return;
    try {
      const api = getApiClient();
      await api.convertIdeaToWorkOrder(id, {
        title: idea.title,
        description: idea.description ?? undefined,
      });
      router.push(`/app/work-orders`);
    } catch (error) {
      console.error('Failed to convert to work order:', error);
    }
  };

  const handleSuggestionFeedback = async (suggestionId: string, isHelpful: boolean) => {
    try {
      const api = getApiClient();
      await api.submitSuggestionFeedback(suggestionId, isHelpful);
      // Update local state
      setSuggestions((prev) =>
        prev.map((s) => (s.id === suggestionId ? { ...s, isHelpful } : s))
      );
    } catch (error) {
      console.error('Failed to submit feedback:', error);
    }
  };

  const formatCurrency = (amount: number | undefined) => {
    if (!amount) return '-';
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      maximumFractionDigits: 0,
    }).format(amount);
  };

  const formatDate = (date: string | Date | undefined) => {
    if (!date) return '-';
    return new Date(date).toLocaleDateString('en-US', {
      month: 'long',
      day: 'numeric',
      year: 'numeric',
    });
  };

  if (authLoading || isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-600"></div>
      </div>
    );
  }

  if (!idea) {
    return (
      <div className="text-center py-12">
        <p className="text-slate-600 dark:text-slate-400">Project not found</p>
        <Link href="/app/projects" className="btn btn-primary mt-4">
          Back to Projects
        </Link>
      </div>
    );
  }

  const statusConfig = STATUS_CONFIG[idea.status];

  // Get valid next statuses
  const getNextStatuses = (): ProjectIdeaStatus[] => {
    switch (idea.status) {
      case 'DREAMING':
        return ['PLANNING'];
      case 'PLANNING':
        return ['ACTIVE', 'DREAMING'];
      case 'ACTIVE':
        return ['COMPLETED', 'PLANNING'];
      case 'COMPLETED':
        return [];
      case 'ARCHIVED':
        return ['DREAMING'];
      default:
        return [];
    }
  };

  return (
    <div className="space-y-6">
      {/* Back button */}
      <Link
        href="/app/projects"
        className="inline-flex items-center gap-2 text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white"
      >
        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
        </svg>
        Back to Projects
      </Link>

      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-start md:justify-between gap-4">
        <div>
          <div className="flex items-center gap-3 mb-2">
            <h1 className="text-2xl font-bold text-slate-900 dark:text-white">
              {idea.title}
            </h1>
            <span className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-sm font-medium ${statusConfig.bgColor} ${statusConfig.color}`}>
              <span>{statusConfig.icon}</span>
              {statusConfig.name}
            </span>
          </div>
          <p className="text-slate-600 dark:text-slate-400">
            {idea.category.replace(/_/g, ' ')}
            {idea.template && ` • ${idea.template.name}`}
          </p>
        </div>

        {/* Actions */}
        <div className="flex flex-wrap gap-2">
          {getNextStatuses().map((status) => (
            <button
              key={status}
              onClick={() => handleProgressStatus(status)}
              className="btn btn-secondary text-sm"
            >
              Move to {STATUS_CONFIG[status].name}
            </button>
          ))}
          {idea.status === 'PLANNING' && (
            <button
              onClick={handleConvertToWorkOrder}
              className="btn btn-primary text-sm"
            >
              Create Work Order
            </button>
          )}
          {idea.status !== 'ARCHIVED' && (
            <button
              onClick={handleArchive}
              className="btn btn-secondary text-sm text-red-600 hover:text-red-700"
            >
              Archive
            </button>
          )}
        </div>
      </div>

      {/* Estimate Banner */}
      {idea.estimatedCostMin && idea.estimatedCostMax && (
        <div className="p-6 rounded-xl bg-gradient-to-r from-emerald-50 to-purple-50 dark:from-emerald-900/20 dark:to-purple-900/20 border border-emerald-200 dark:border-emerald-800">
          <div className="text-center">
            <div className="text-sm text-slate-600 dark:text-slate-400 mb-1">Estimated Cost</div>
            <div className="text-3xl font-bold text-slate-900 dark:text-white">
              {formatCurrency(idea.estimatedCostMin)} - {formatCurrency(idea.estimatedCostMax)}
            </div>
            {idea.socialProofNote && (
              <div className="mt-2 inline-flex items-center gap-1.5 text-sm text-green-600 dark:text-green-400">
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                {idea.socialProofNote}
              </div>
            )}
          </div>
        </div>
      )}

      {/* Tabs */}
      <div className="border-b border-slate-200 dark:border-slate-700">
        <nav className="flex gap-6">
          {[
            { id: 'overview' as TabType, name: 'Overview' },
            { id: 'who-to-hire' as TabType, name: 'Who to Hire', count: suggestions.length },
            { id: 'inspiration' as TabType, name: 'Inspiration', count: inspiration.length },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`pb-3 border-b-2 font-medium text-sm transition-colors ${
                activeTab === tab.id
                  ? 'border-emerald-600 text-emerald-600 dark:text-emerald-400'
                  : 'border-transparent text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
              }`}
            >
              {tab.name}
              {tab.count !== undefined && tab.count > 0 && (
                <span className="ml-2 px-2 py-0.5 rounded-full text-xs bg-slate-100 dark:bg-slate-800">
                  {tab.count}
                </span>
              )}
            </button>
          ))}
        </nav>
      </div>

      {/* Tab Content */}
      {activeTab === 'overview' && (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Main Details */}
          <div className="lg:col-span-2 space-y-6">
            {/* Description */}
            {idea.description && (
              <div className="card">
                <h3 className="font-medium text-slate-900 dark:text-white mb-2">Description</h3>
                <p className="text-slate-600 dark:text-slate-400">{idea.description}</p>
              </div>
            )}

            {/* Specs */}
            {idea.specs && (
              <div className="card">
                <h3 className="font-medium text-slate-900 dark:text-white mb-4">Project Specs</h3>
                <dl className="grid grid-cols-2 gap-4">
                  {(idea.specs as { sqFt?: number; complexity?: string[] }).sqFt && (
                    <div>
                      <dt className="text-sm text-slate-500 dark:text-slate-400">Size</dt>
                      <dd className="text-slate-900 dark:text-white font-medium">
                        {(idea.specs as { sqFt: number }).sqFt} sq ft
                      </dd>
                    </div>
                  )}
                  {((idea.specs as { complexity?: string[] })?.complexity?.length ?? 0) > 0 && (
                    <div>
                      <dt className="text-sm text-slate-500 dark:text-slate-400">Complexity</dt>
                      <dd className="text-slate-900 dark:text-white">
                        {(idea.specs as { complexity: string[] }).complexity.length} factor(s)
                      </dd>
                    </div>
                  )}
                </dl>
              </div>
            )}

            {/* Vibe Notes */}
            {idea.vibeNotes && (
              <div className="card">
                <h3 className="font-medium text-slate-900 dark:text-white mb-2">Vibe Notes</h3>
                <p className="text-slate-600 dark:text-slate-400">{idea.vibeNotes}</p>
              </div>
            )}

            {/* Mood Board */}
            {idea.moodBoardImages && idea.moodBoardImages.length > 0 && (
              <div className="card">
                <h3 className="font-medium text-slate-900 dark:text-white mb-4">Inspiration Board</h3>
                <div className="grid grid-cols-3 gap-3">
                  {idea.moodBoardImages.map((url, i) => (
                    <div key={i} className="aspect-square rounded-lg overflow-hidden bg-slate-100 dark:bg-slate-800">
                      <img src={url} alt={`Inspiration ${i + 1}`} className="w-full h-full object-cover" />
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>

          {/* Sidebar */}
          <div className="space-y-6">
            {/* Quick Info */}
            <div className="card">
              <h3 className="font-medium text-slate-900 dark:text-white mb-4">Details</h3>
              <dl className="space-y-3">
                {idea.style && (
                  <div className="flex justify-between">
                    <dt className="text-slate-500 dark:text-slate-400">Style</dt>
                    <dd className="text-slate-900 dark:text-white">{STYLE_NAMES[idea.style] || idea.style}</dd>
                  </div>
                )}
                {idea.urgency && (
                  <div className="flex justify-between">
                    <dt className="text-slate-500 dark:text-slate-400">Timeline</dt>
                    <dd className="text-slate-900 dark:text-white capitalize">{idea.urgency.replace(/_/g, ' ')}</dd>
                  </div>
                )}
                {idea.targetStartDate && (
                  <div className="flex justify-between">
                    <dt className="text-slate-500 dark:text-slate-400">Target Start</dt>
                    <dd className="text-slate-900 dark:text-white">{formatDate(idea.targetStartDate)}</dd>
                  </div>
                )}
                {idea.targetCompletionDate && (
                  <div className="flex justify-between">
                    <dt className="text-slate-500 dark:text-slate-400">Target Completion</dt>
                    <dd className="text-slate-900 dark:text-white">{formatDate(idea.targetCompletionDate)}</dd>
                  </div>
                )}
                <div className="flex justify-between">
                  <dt className="text-slate-500 dark:text-slate-400">Created</dt>
                  <dd className="text-slate-900 dark:text-white">{formatDate(idea.createdAt)}</dd>
                </div>
              </dl>
            </div>

            {/* Quick Actions */}
            {idea.status !== 'ARCHIVED' && idea.status !== 'COMPLETED' && (
              <div className="card">
                <h3 className="font-medium text-slate-900 dark:text-white mb-4">Quick Actions</h3>
                <div className="space-y-2">
                  <button
                    onClick={() => setActiveTab('who-to-hire')}
                    className="w-full btn btn-secondary text-left justify-start"
                  >
                    <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z" />
                    </svg>
                    Find Contractors
                  </button>
                  <button
                    onClick={() => setShowAskModal(true)}
                    className="w-full btn btn-secondary text-left justify-start"
                  >
                    <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
                    </svg>
                    Ask Neighbors
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      )}

      {activeTab === 'who-to-hire' && (
        <div className="space-y-6">
          {/* Generate Suggestions Button */}
          {suggestions.length === 0 && (
            <div className="card text-center py-8">
              <div className="text-4xl mb-4">🔍</div>
              <h3 className="text-lg font-medium text-slate-900 dark:text-white mb-2">
                Find the right contractor
              </h3>
              <p className="text-slate-600 dark:text-slate-400 mb-6 max-w-md mx-auto">
                We&apos;ll search for contractors your neighbors have used for similar projects.
              </p>
              <button
                onClick={handleGenerateSuggestions}
                disabled={isGeneratingSuggestions}
                className="btn btn-primary"
              >
                {isGeneratingSuggestions ? (
                  <>
                    <svg className="animate-spin -ml-1 mr-2 h-4 w-4" fill="none" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                    </svg>
                    Searching...
                  </>
                ) : (
                  <>
                    <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                    </svg>
                    Find Contractors
                  </>
                )}
              </button>
            </div>
          )}

          {/* Suggestions List */}
          {suggestions.length > 0 && (
            <>
              <div className="flex justify-between items-center">
                <h3 className="text-lg font-medium text-slate-900 dark:text-white">
                  Contractor Suggestions ({suggestions.length})
                </h3>
                <button
                  onClick={handleGenerateSuggestions}
                  disabled={isGeneratingSuggestions}
                  className="btn btn-secondary text-sm"
                >
                  {isGeneratingSuggestions ? 'Searching...' : 'Find More'}
                </button>
              </div>

              <div className="grid gap-4">
                {suggestions.map((suggestion) => (
                  <div key={suggestion.id} className="card">
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <div className="flex items-center gap-3 mb-2">
                          <h4 className="font-medium text-slate-900 dark:text-white">
                            {suggestion.vendor?.companyName || 'Unknown Vendor'}
                          </h4>
                          {suggestion.isSystemSuggestion && (
                            <span className="px-2 py-0.5 rounded text-xs bg-emerald-100 dark:bg-emerald-900/30 text-emerald-600 dark:text-emerald-400">
                              System Match
                            </span>
                          )}
                          {suggestion.rating && (
                            <div className="flex items-center gap-1 text-yellow-500">
                              <svg className="w-4 h-4 fill-current" viewBox="0 0 20 20">
                                <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
                              </svg>
                              <span className="text-sm">{suggestion.rating}</span>
                            </div>
                          )}
                        </div>

                        {suggestion.vendor?.specialty && (
                          <div className="flex flex-wrap gap-1 mb-2">
                            {suggestion.vendor.specialty.map((s, i) => (
                              <span key={i} className="px-2 py-0.5 rounded text-xs bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400">
                                {s}
                              </span>
                            ))}
                          </div>
                        )}

                        {suggestion.comment && (
                          <p className="text-slate-600 dark:text-slate-400 mb-2">
                            &quot;{suggestion.comment}&quot;
                          </p>
                        )}

                        {suggestion.systemNote && (
                          <p className="text-sm text-green-600 dark:text-green-400 mb-2">
                            {suggestion.systemNote}
                          </p>
                        )}

                        {suggestion.suggestedBy && (
                          <div className="text-sm text-slate-500 dark:text-slate-400">
                            Recommended by {suggestion.suggestedBy.displayName}
                          </div>
                        )}
                      </div>

                      {/* Feedback buttons */}
                      <div className="flex items-center gap-2 ml-4">
                        <button
                          onClick={() => handleSuggestionFeedback(suggestion.id, true)}
                          className={`p-2 rounded-lg transition-colors ${
                            suggestion.isHelpful === true
                              ? 'bg-green-100 dark:bg-green-900/30 text-green-600'
                              : 'hover:bg-slate-100 dark:hover:bg-slate-800 text-slate-400'
                          }`}
                          title="Helpful"
                        >
                          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M14 10h4.764a2 2 0 011.789 2.894l-3.5 7A2 2 0 0115.263 21h-4.017c-.163 0-.326-.02-.485-.06L7 20m7-10V5a2 2 0 00-2-2h-.095c-.5 0-.905.405-.905.905 0 .714-.211 1.412-.608 2.006L7 11v9m7-10h-2M7 20H5a2 2 0 01-2-2v-6a2 2 0 012-2h2.5" />
                          </svg>
                        </button>
                        <button
                          onClick={() => handleSuggestionFeedback(suggestion.id, false)}
                          className={`p-2 rounded-lg transition-colors ${
                            suggestion.isHelpful === false
                              ? 'bg-red-100 dark:bg-red-900/30 text-red-600'
                              : 'hover:bg-slate-100 dark:hover:bg-slate-800 text-slate-400'
                          }`}
                          title="Not helpful"
                        >
                          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 14H5.236a2 2 0 01-1.789-2.894l3.5-7A2 2 0 018.736 3h4.018a2 2 0 01.485.06l3.76.94m-7 10v5a2 2 0 002 2h.096c.5 0 .905-.405.905-.904 0-.715.211-1.413.608-2.008L17 13V4m-7 10h2m5-10h2a2 2 0 012 2v6a2 2 0 01-2 2h-2.5" />
                          </svg>
                        </button>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </>
          )}

          {/* Ask Community CTA */}
          <div className="card bg-gradient-to-r from-purple-50 to-emerald-50 dark:from-purple-900/20 dark:to-emerald-900/20 border-purple-200 dark:border-purple-800">
            <div className="flex items-start gap-4">
              <div className="text-3xl">🏘️</div>
              <div className="flex-1">
                <h4 className="font-medium text-slate-900 dark:text-white mb-1">
                  Ask Your Neighbors
                </h4>
                <p className="text-slate-600 dark:text-slate-400 text-sm mb-3">
                  Post a request to your community and get personal recommendations from neighbors who&apos;ve done similar projects.
                </p>
                <button
                  onClick={() => setShowAskModal(true)}
                  className="btn btn-primary text-sm"
                >
                  Ask for Recommendations
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {activeTab === 'inspiration' && (
        <div className="space-y-6">
          {inspiration.length === 0 ? (
            <div className="card text-center py-12">
              <div className="text-4xl mb-4">🏡</div>
              <h3 className="text-lg font-medium text-slate-900 dark:text-white mb-2">
                No neighbor projects found
              </h3>
              <p className="text-slate-600 dark:text-slate-400 max-w-md mx-auto">
                We couldn&apos;t find any similar projects from neighbors in your area yet.
                Check back later as more projects are shared.
              </p>
            </div>
          ) : (
            <div className="grid gap-6">
              {inspiration.map((project) => (
                <div key={project.id} className="card">
                  <div className="flex items-start gap-4">
                    {project.images && project.images.length > 0 && (
                      <div className="w-32 h-24 rounded-lg overflow-hidden bg-slate-100 dark:bg-slate-800 flex-shrink-0">
                        <img src={project.images[0]} alt={project.title} className="w-full h-full object-cover" />
                      </div>
                    )}
                    <div className="flex-1">
                      <h4 className="font-medium text-slate-900 dark:text-white mb-1">
                        {project.title}
                      </h4>
                      {project.description && (
                        <p className="text-slate-600 dark:text-slate-400 text-sm mb-2 line-clamp-2">
                          {project.description}
                        </p>
                      )}
                      <div className="flex flex-wrap gap-3 text-sm text-slate-500 dark:text-slate-400">
                        {project.actualCost && (
                          <span>Cost: {formatCurrency(project.actualCost)}</span>
                        )}
                        {project.vendorName && (
                          <span>By: {project.vendorName}</span>
                        )}
                        {project.authorDisplayName && (
                          <span>Shared by: {project.authorDisplayName}</span>
                        )}
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* Ask Community Modal */}
      {showAskModal && (
        <AskCommunityModal
          ideaId={id}
          ideaTitle={idea.title}
          onClose={() => setShowAskModal(false)}
          onSuccess={() => {
            setShowAskModal(false);
            // Optionally refresh data
          }}
        />
      )}
    </div>
  );
}

// Ask Community Modal Component
function AskCommunityModal({
  ideaId,
  ideaTitle,
  onClose,
  onSuccess,
}: {
  ideaId: string;
  ideaTitle: string;
  onClose: () => void;
  onSuccess: () => void;
}) {
  const [title, setTitle] = useState(`Looking for recommendations: ${ideaTitle}`);
  const [description, setDescription] = useState('');
  const [budget, setBudget] = useState('');
  const [timeline, setTimeline] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setIsSubmitting(true);

    try {
      const api = getApiClient();
      await api.createRecommendationRequest(ideaId, {
        title,
        description: description || undefined,
        budget: budget || undefined,
        timeline: timeline || undefined,
        isPublic: true,
      });
      onSuccess();
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Failed to create request';
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
              Ask for Recommendations
            </h2>
            <button onClick={onClose} className="p-1 text-slate-400 hover:text-slate-500">
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <form onSubmit={handleSubmit} className="p-6 space-y-4">
            {error && (
              <div className="p-3 rounded-lg bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800">
                <p className="text-sm text-red-600 dark:text-red-400">{error}</p>
              </div>
            )}

            <div>
              <label className="label block mb-1.5">Title</label>
              <input
                type="text"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                className="input"
                required
              />
            </div>

            <div>
              <label className="label block mb-1.5">Details (optional)</label>
              <textarea
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                className="input min-h-[80px]"
                placeholder="What are you looking for in a contractor?"
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="label block mb-1.5">Budget</label>
                <select
                  value={budget}
                  onChange={(e) => setBudget(e.target.value)}
                  className="input"
                >
                  <option value="">Select budget</option>
                  <option value="under_5k">Under $5,000</option>
                  <option value="5k_15k">$5,000 - $15,000</option>
                  <option value="15k_30k">$15,000 - $30,000</option>
                  <option value="30k_plus">$30,000+</option>
                </select>
              </div>
              <div>
                <label className="label block mb-1.5">Timeline</label>
                <select
                  value={timeline}
                  onChange={(e) => setTimeline(e.target.value)}
                  className="input"
                >
                  <option value="">Select timeline</option>
                  <option value="flexible">Flexible</option>
                  <option value="1_month">Within 1 month</option>
                  <option value="3_months">Within 3 months</option>
                  <option value="6_months">Within 6 months</option>
                </select>
              </div>
            </div>

            <div className="p-3 rounded-lg bg-emerald-50 dark:bg-emerald-900/20 border border-emerald-200 dark:border-emerald-800">
              <p className="text-sm text-emerald-700 dark:text-emerald-300">
                Your request will be visible to neighbors in your area. They can suggest contractors they&apos;ve used and liked.
              </p>
            </div>

            <div className="flex justify-end gap-3 pt-4">
              <button type="button" onClick={onClose} className="btn btn-secondary">
                Cancel
              </button>
              <button type="submit" disabled={isSubmitting} className="btn btn-primary">
                {isSubmitting ? 'Posting...' : 'Post Request'}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}
