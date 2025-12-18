'use client';

import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '@/contexts/auth-context';
import { getApiClient } from '@/lib/api';
import type { ProjectIdea, ProjectIdeaStatus, ProjectCategory } from '@haven/core';

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

// Category display names
const CATEGORY_NAMES: Partial<Record<ProjectCategory, string>> = {
  BATHROOM_REMODEL: 'Bathroom',
  KITCHEN_REMODEL: 'Kitchen',
  DECK_PATIO: 'Deck/Patio',
  LANDSCAPING: 'Landscaping',
  ROOF: 'Roof',
  WINDOWS_DOORS: 'Windows/Doors',
  FLOORING: 'Flooring',
  PAINTING: 'Painting',
  HVAC: 'HVAC',
  ELECTRICAL: 'Electrical',
  PLUMBING: 'Plumbing',
  ADDITION: 'Addition',
  BASEMENT: 'Basement',
  GARAGE: 'Garage',
  FENCE: 'Fence',
  POOL: 'Pool',
  SOLAR: 'Solar',
  SMART_HOME: 'Smart Home',
  EXTERIOR_SIDING: 'Siding',
  OTHER: 'Other',
};

// Extended type with household info for manager view
type ProjectIdeaWithHousehold = ProjectIdea & {
  household?: {
    id: string;
    name: string;
    address?: string;
  };
};

export default function ManagerPipelinePage() {
  const { isLoading: authLoading } = useAuth();
  const [ideas, setIdeas] = useState<ProjectIdeaWithHousehold[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [categoryFilter, setCategoryFilter] = useState<ProjectCategory | 'ALL'>('ALL');
  const [estimateFilter, setEstimateFilter] = useState<string>('ALL');
  const [searchQuery, setSearchQuery] = useState('');

  const loadData = useCallback(async () => {
    try {
      const api = getApiClient();
      // For now, we'll use the regular project ideas endpoint
      // In production, this would be an internal/admin endpoint
      const response = await api.getProjectIdeas({ limit: 200 });
      setIdeas(response.ideas as ProjectIdeaWithHousehold[]);
    } catch (error) {
      console.error('Failed to load pipeline data:', error);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    loadData();
  }, [loadData]);

  // Filter ideas
  const filteredIdeas = ideas.filter((idea) => {
    // Exclude archived
    if (idea.status === 'ARCHIVED') return false;

    // Category filter
    if (categoryFilter !== 'ALL' && idea.category !== categoryFilter) return false;

    // Estimate filter
    if (estimateFilter !== 'ALL') {
      const maxCost = idea.estimatedCostMax || 0;
      switch (estimateFilter) {
        case 'under_10k':
          if (maxCost >= 10000) return false;
          break;
        case '10k_25k':
          if (maxCost < 10000 || maxCost >= 25000) return false;
          break;
        case '25k_50k':
          if (maxCost < 25000 || maxCost >= 50000) return false;
          break;
        case '50k_plus':
          if (maxCost < 50000) return false;
          break;
      }
    }

    // Search filter
    if (searchQuery) {
      const query = searchQuery.toLowerCase();
      const matchesTitle = idea.title.toLowerCase().includes(query);
      const matchesCategory = idea.category.toLowerCase().includes(query);
      const matchesHousehold = idea.household?.name?.toLowerCase().includes(query);
      if (!matchesTitle && !matchesCategory && !matchesHousehold) return false;
    }

    return true;
  });

  // Group by status for pipeline view
  const pipelineStatuses: ProjectIdeaStatus[] = ['DREAMING', 'PLANNING', 'ACTIVE'];
  const ideasByStatus = filteredIdeas.reduce((acc, idea) => {
    if (!acc[idea.status]) {
      acc[idea.status] = [];
    }
    acc[idea.status].push(idea);
    return acc;
  }, {} as Record<ProjectIdeaStatus, ProjectIdeaWithHousehold[]>);

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
      month: 'short',
      day: 'numeric',
    });
  };

  // Get total estimate value
  const totalEstimate = filteredIdeas.reduce((sum, idea) => {
    return sum + (idea.estimatedCostMax || 0);
  }, 0);

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
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 dark:text-white">
            Project Pipeline
          </h1>
          <p className="text-slate-600 dark:text-slate-400 mt-1">
            View and manage homeowner project ideas across all households
          </p>
        </div>
        <div className="text-right">
          <div className="text-sm text-slate-500 dark:text-slate-400">Total Pipeline Value</div>
          <div className="text-2xl font-bold text-slate-900 dark:text-white">
            {formatCurrency(totalEstimate)}
          </div>
        </div>
      </div>

      {/* Stats Overview */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {pipelineStatuses.map((status) => {
          const config = STATUS_CONFIG[status];
          const statusIdeas = ideasByStatus[status] || [];
          const statusValue = statusIdeas.reduce((sum, idea) => sum + (idea.estimatedCostMax || 0), 0);
          return (
            <div key={status} className={`p-4 rounded-xl ${config.bgColor}`}>
              <div className="flex items-center gap-2 mb-1">
                <span className="text-lg">{config.icon}</span>
                <span className={`font-medium ${config.color}`}>{config.name}</span>
              </div>
              <div className="text-2xl font-bold text-slate-900 dark:text-white">
                {statusIdeas.length}
              </div>
              <div className="text-sm text-slate-500 dark:text-slate-400">
                {formatCurrency(statusValue)}
              </div>
            </div>
          );
        })}
        {/* Completed stats */}
        <div className={`p-4 rounded-xl ${STATUS_CONFIG.COMPLETED.bgColor}`}>
          <div className="flex items-center gap-2 mb-1">
            <span className="text-lg">{STATUS_CONFIG.COMPLETED.icon}</span>
            <span className={`font-medium ${STATUS_CONFIG.COMPLETED.color}`}>
              {STATUS_CONFIG.COMPLETED.name}
            </span>
          </div>
          <div className="text-2xl font-bold text-slate-900 dark:text-white">
            {(ideasByStatus.COMPLETED || []).length}
          </div>
          <div className="text-sm text-slate-500 dark:text-slate-400">
            {formatCurrency((ideasByStatus.COMPLETED || []).reduce((sum, idea) => sum + (idea.estimatedCostMax || 0), 0))}
          </div>
        </div>
      </div>

      {/* Filters */}
      <div className="card">
        <div className="flex flex-wrap gap-4 items-end">
          {/* Search */}
          <div className="flex-1 min-w-[200px]">
            <label className="label block mb-1.5">Search</label>
            <div className="relative">
              <svg
                className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search projects or households..."
                className="input pl-10"
              />
            </div>
          </div>

          {/* Category Filter */}
          <div className="w-40">
            <label className="label block mb-1.5">Category</label>
            <select
              value={categoryFilter}
              onChange={(e) => setCategoryFilter(e.target.value as ProjectCategory | 'ALL')}
              className="input"
            >
              <option value="ALL">All Categories</option>
              {Object.entries(CATEGORY_NAMES).map(([key, name]) => (
                <option key={key} value={key}>
                  {name}
                </option>
              ))}
            </select>
          </div>

          {/* Estimate Filter */}
          <div className="w-40">
            <label className="label block mb-1.5">Budget</label>
            <select
              value={estimateFilter}
              onChange={(e) => setEstimateFilter(e.target.value)}
              className="input"
            >
              <option value="ALL">All Budgets</option>
              <option value="under_10k">Under $10k</option>
              <option value="10k_25k">$10k - $25k</option>
              <option value="25k_50k">$25k - $50k</option>
              <option value="50k_plus">$50k+</option>
            </select>
          </div>
        </div>
      </div>

      {/* Pipeline Kanban View */}
      {filteredIdeas.length === 0 ? (
        <div className="card text-center py-12">
          <div className="text-5xl mb-4">📊</div>
          <h3 className="text-lg font-medium text-slate-900 dark:text-white mb-2">
            No projects found
          </h3>
          <p className="text-slate-600 dark:text-slate-400">
            {searchQuery || categoryFilter !== 'ALL' || estimateFilter !== 'ALL'
              ? 'Try adjusting your filters'
              : 'Homeowners have not created any project ideas yet'}
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {pipelineStatuses.map((status) => {
            const config = STATUS_CONFIG[status];
            const statusIdeas = ideasByStatus[status] || [];
            return (
              <div key={status} className="space-y-3">
                {/* Column Header */}
                <div className={`p-3 rounded-lg ${config.bgColor} sticky top-0 z-10`}>
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <span>{config.icon}</span>
                      <span className={`font-medium ${config.color}`}>{config.name}</span>
                    </div>
                    <span className="px-2 py-0.5 rounded-full text-xs bg-white/50 dark:bg-black/20 text-slate-600 dark:text-slate-400">
                      {statusIdeas.length}
                    </span>
                  </div>
                </div>

                {/* Cards */}
                <div className="space-y-3 max-h-[600px] overflow-y-auto">
                  {statusIdeas.length === 0 ? (
                    <div className="p-4 rounded-xl border-2 border-dashed border-slate-200 dark:border-slate-700 text-center">
                      <p className="text-sm text-slate-500 dark:text-slate-400">
                        No projects in {config.name.toLowerCase()}
                      </p>
                    </div>
                  ) : (
                    statusIdeas.map((idea) => (
                      <div
                        key={idea.id}
                        className="p-4 rounded-xl bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 hover:border-emerald-500 dark:hover:border-emerald-400 transition-colors cursor-pointer"
                      >
                        {/* Household */}
                        {idea.household && (
                          <div className="flex items-center gap-2 mb-2 text-xs text-slate-500 dark:text-slate-400">
                            <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
                            </svg>
                            <span className="truncate">{idea.household.name}</span>
                          </div>
                        )}

                        {/* Title and Category */}
                        <div className="font-medium text-slate-900 dark:text-white mb-1 line-clamp-1">
                          {idea.title}
                        </div>
                        <div className="text-xs text-slate-500 dark:text-slate-400 mb-2">
                          {CATEGORY_NAMES[idea.category] || idea.category}
                        </div>

                        {/* Estimate */}
                        {idea.estimatedCostMin && idea.estimatedCostMax && (
                          <div className="text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                            {formatCurrency(idea.estimatedCostMin)} - {formatCurrency(idea.estimatedCostMax)}
                          </div>
                        )}

                        {/* Timeline */}
                        {idea.urgency && (
                          <div className="flex items-center gap-1 text-xs text-slate-500 dark:text-slate-400">
                            <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                            </svg>
                            <span className="capitalize">{idea.urgency.replace(/_/g, ' ')}</span>
                          </div>
                        )}

                        {/* Footer */}
                        <div className="mt-3 pt-3 border-t border-slate-100 dark:border-slate-700 flex items-center justify-between">
                          <span className="text-xs text-slate-400 dark:text-slate-500">
                            {formatDate(idea.updatedAt)}
                          </span>
                          {status === 'PLANNING' && (
                            <button className="text-xs text-emerald-600 dark:text-emerald-400 hover:underline">
                              Reach Out
                            </button>
                          )}
                        </div>
                      </div>
                    ))
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Quick Stats */}
      <div className="card">
        <h3 className="font-medium text-slate-900 dark:text-white mb-4">Pipeline Insights</h3>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
          {/* By Category */}
          <div>
            <h4 className="text-sm text-slate-500 dark:text-slate-400 mb-2">Top Categories</h4>
            <div className="space-y-1">
              {Object.entries(
                filteredIdeas.reduce((acc, idea) => {
                  acc[idea.category] = (acc[idea.category] || 0) + 1;
                  return acc;
                }, {} as Record<string, number>)
              )
                .sort(([, a], [, b]) => b - a)
                .slice(0, 3)
                .map(([category, count]) => (
                  <div key={category} className="flex justify-between text-sm">
                    <span className="text-slate-600 dark:text-slate-400">
                      {CATEGORY_NAMES[category as ProjectCategory] || category}
                    </span>
                    <span className="text-slate-900 dark:text-white font-medium">{count}</span>
                  </div>
                ))}
            </div>
          </div>

          {/* Ready to Convert */}
          <div>
            <h4 className="text-sm text-slate-500 dark:text-slate-400 mb-2">Ready for Action</h4>
            <div className="text-3xl font-bold text-emerald-600 dark:text-emerald-400">
              {(ideasByStatus.PLANNING || []).filter((i) => i.urgency && i.urgency !== 'no_rush').length}
            </div>
            <p className="text-xs text-slate-500 dark:text-slate-400">
              Planning with timeline
            </p>
          </div>

          {/* Avg Estimate */}
          <div>
            <h4 className="text-sm text-slate-500 dark:text-slate-400 mb-2">Avg Project Size</h4>
            <div className="text-3xl font-bold text-slate-900 dark:text-white">
              {formatCurrency(
                filteredIdeas.length > 0
                  ? totalEstimate / filteredIdeas.length
                  : 0
              )}
            </div>
            <p className="text-xs text-slate-500 dark:text-slate-400">
              per project
            </p>
          </div>

          {/* Conversion Rate */}
          <div>
            <h4 className="text-sm text-slate-500 dark:text-slate-400 mb-2">Progression Rate</h4>
            <div className="text-3xl font-bold text-green-600 dark:text-green-400">
              {ideas.length > 0
                ? Math.round(
                    ((ideasByStatus.PLANNING?.length || 0) +
                      (ideasByStatus.ACTIVE?.length || 0) +
                      (ideasByStatus.COMPLETED?.length || 0)) /
                      ideas.length *
                      100
                  )
                : 0}%
            </div>
            <p className="text-xs text-slate-500 dark:text-slate-400">
              beyond dreaming
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
