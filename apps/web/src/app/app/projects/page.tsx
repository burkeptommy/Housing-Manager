'use client';

import { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
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

type ViewMode = 'pipeline' | 'list';

export default function ProjectsPage() {
  const router = useRouter();
  const { currentHousehold, isLoading: authLoading } = useAuth();
  const [ideas, setIdeas] = useState<ProjectIdea[]>([]);
  const [stats, setStats] = useState<Record<ProjectIdeaStatus, number> | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [viewMode, setViewMode] = useState<ViewMode>('pipeline');
  const [statusFilter, setStatusFilter] = useState<ProjectIdeaStatus | 'ALL'>('ALL');
  const [showArchived, setShowArchived] = useState(false);

  const loadData = useCallback(async () => {
    console.log('[Projects] loadData called, currentHousehold:', currentHousehold?.id, currentHousehold?.name);
    if (!currentHousehold) {
      console.log('[Projects] No currentHousehold, skipping API call');
      setIsLoading(false);
      return;
    }

    try {
      console.log('[Projects] Fetching project ideas and stats...');
      const api = getApiClient();
      const [ideasResponse, statsData] = await Promise.all([
        api.getProjectIdeas({ limit: 100 }),
        api.getProjectPipelineStats(),
      ]);
      console.log('[Projects] Got ideas:', ideasResponse.ideas.length, 'stats:', JSON.stringify(statsData));
      setIdeas(ideasResponse.ideas);
      setStats(statsData);
    } catch (error) {
      console.error('[Projects] Failed to load projects:', error);
    } finally {
      setIsLoading(false);
    }
  }, [currentHousehold]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  // Log auth state for debugging
  useEffect(() => {
    console.log('[Projects] Auth state - authLoading:', authLoading, 'currentHousehold:', currentHousehold?.id);
  }, [authLoading, currentHousehold]);

  // Filter ideas
  const filteredIdeas = ideas.filter((idea) => {
    if (!showArchived && idea.status === 'ARCHIVED') return false;
    if (statusFilter !== 'ALL' && idea.status !== statusFilter) return false;
    return true;
  });

  // Group ideas by status for pipeline view
  const ideasByStatus = filteredIdeas.reduce((acc, idea) => {
    if (!acc[idea.status]) {
      acc[idea.status] = [];
    }
    acc[idea.status].push(idea);
    return acc;
  }, {} as Record<ProjectIdeaStatus, ProjectIdea[]>);

  const pipelineStatuses: ProjectIdeaStatus[] = ['DREAMING', 'PLANNING', 'ACTIVE', 'COMPLETED'];

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
            My Projects
          </h1>
          <p className="text-slate-600 dark:text-slate-400 mt-1">
            Dream, plan, and track your home improvement projects
          </p>
        </div>
        <Link href="/app/projects/new" className="btn btn-primary">
          <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
          </svg>
          New Project
        </Link>
      </div>

      {/* Stats Overview */}
      {stats && (
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {pipelineStatuses.map((status) => {
            const config = STATUS_CONFIG[status];
            return (
              <div
                key={status}
                className={`p-4 rounded-xl ${config.bgColor} cursor-pointer hover:scale-[1.02] transition-transform`}
                onClick={() => setStatusFilter(status)}
              >
                <div className="flex items-center gap-2 mb-1">
                  <span className="text-lg">{config.icon}</span>
                  <span className={`font-medium ${config.color}`}>{config.name}</span>
                </div>
                <div className="text-2xl font-bold text-slate-900 dark:text-white">
                  {stats[status] || 0}
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Filters and View Toggle */}
      <div className="card">
        <div className="flex flex-wrap gap-4 items-center justify-between">
          <div className="flex items-center gap-4">
            {/* Status Filter */}
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value as ProjectIdeaStatus | 'ALL')}
              className="input w-40"
            >
              <option value="ALL">All Statuses</option>
              {pipelineStatuses.map((status) => (
                <option key={status} value={status}>
                  {STATUS_CONFIG[status].name}
                </option>
              ))}
            </select>

            {/* Show Archived Toggle */}
            <label className="flex items-center gap-2 text-sm text-slate-600 dark:text-slate-400">
              <input
                type="checkbox"
                checked={showArchived}
                onChange={(e) => setShowArchived(e.target.checked)}
                className="rounded border-slate-300 dark:border-slate-600"
              />
              Show archived
            </label>
          </div>

          {/* View Mode Toggle */}
          <div className="flex items-center gap-1 p-1 bg-slate-100 dark:bg-slate-800 rounded-lg">
            <button
              onClick={() => setViewMode('pipeline')}
              className={`px-3 py-1.5 rounded text-sm font-medium transition-colors ${
                viewMode === 'pipeline'
                  ? 'bg-white dark:bg-slate-700 text-slate-900 dark:text-white shadow-sm'
                  : 'text-slate-600 dark:text-slate-400'
              }`}
            >
              Pipeline
            </button>
            <button
              onClick={() => setViewMode('list')}
              className={`px-3 py-1.5 rounded text-sm font-medium transition-colors ${
                viewMode === 'list'
                  ? 'bg-white dark:bg-slate-700 text-slate-900 dark:text-white shadow-sm'
                  : 'text-slate-600 dark:text-slate-400'
              }`}
            >
              List
            </button>
          </div>
        </div>
      </div>

      {/* Content */}
      {filteredIdeas.length === 0 ? (
        <div className="card text-center py-12">
          <div className="text-5xl mb-4">💭</div>
          <h3 className="text-lg font-medium text-slate-900 dark:text-white mb-2">
            No projects yet
          </h3>
          <p className="text-slate-600 dark:text-slate-400 mb-6">
            Start dreaming about your next home improvement project
          </p>
          <Link href="/app/projects/new" className="btn btn-primary">
            Create Your First Project
          </Link>
        </div>
      ) : viewMode === 'pipeline' ? (
        /* Pipeline View */
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          {pipelineStatuses.map((status) => {
            const config = STATUS_CONFIG[status];
            const statusIdeas = ideasByStatus[status] || [];
            return (
              <div key={status} className="space-y-3">
                {/* Column Header */}
                <div className={`p-3 rounded-lg ${config.bgColor}`}>
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <span>{config.icon}</span>
                      <span className={`font-medium ${config.color}`}>{config.name}</span>
                    </div>
                    <span className="text-sm text-slate-600 dark:text-slate-400">
                      {statusIdeas.length}
                    </span>
                  </div>
                </div>

                {/* Cards */}
                <div className="space-y-3">
                  {statusIdeas.map((idea) => (
                    <Link
                      key={idea.id}
                      href={`/app/projects/${idea.id}`}
                      className="block p-4 rounded-xl bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 hover:border-emerald-500 dark:hover:border-emerald-400 transition-colors"
                    >
                      <div className="font-medium text-slate-900 dark:text-white mb-1 line-clamp-1">
                        {idea.title}
                      </div>
                      <div className="text-xs text-slate-500 dark:text-slate-400 mb-2">
                        {CATEGORY_NAMES[idea.category] || idea.category}
                      </div>
                      {idea.estimatedCostMin && idea.estimatedCostMax && (
                        <div className="text-sm text-slate-600 dark:text-slate-300">
                          {formatCurrency(idea.estimatedCostMin)} - {formatCurrency(idea.estimatedCostMax)}
                        </div>
                      )}
                      {idea.socialProofNote && (
                        <div className="mt-2 text-xs text-green-600 dark:text-green-400">
                          {idea.socialProofNote}
                        </div>
                      )}
                    </Link>
                  ))}
                </div>
              </div>
            );
          })}
        </div>
      ) : (
        /* List View */
        <div className="card overflow-hidden">
          <table className="w-full">
            <thead>
              <tr className="border-b border-slate-200 dark:border-slate-700">
                <th className="text-left p-4 font-medium text-slate-600 dark:text-slate-400">Project</th>
                <th className="text-left p-4 font-medium text-slate-600 dark:text-slate-400">Category</th>
                <th className="text-left p-4 font-medium text-slate-600 dark:text-slate-400">Status</th>
                <th className="text-left p-4 font-medium text-slate-600 dark:text-slate-400">Estimate</th>
                <th className="text-left p-4 font-medium text-slate-600 dark:text-slate-400">Updated</th>
              </tr>
            </thead>
            <tbody>
              {filteredIdeas.map((idea) => {
                const config = STATUS_CONFIG[idea.status];
                return (
                  <tr
                    key={idea.id}
                    className="border-b border-slate-100 dark:border-slate-800 hover:bg-slate-50 dark:hover:bg-slate-800/50 cursor-pointer"
                    onClick={() => router.push(`/app/projects/${idea.id}`)}
                  >
                    <td className="p-4">
                      <div className="font-medium text-slate-900 dark:text-white">
                        {idea.title}
                      </div>
                      {idea.description && (
                        <div className="text-sm text-slate-500 dark:text-slate-400 line-clamp-1 mt-1">
                          {idea.description}
                        </div>
                      )}
                    </td>
                    <td className="p-4 text-slate-600 dark:text-slate-400">
                      {CATEGORY_NAMES[idea.category] || idea.category}
                    </td>
                    <td className="p-4">
                      <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium ${config.bgColor} ${config.color}`}>
                        <span>{config.icon}</span>
                        {config.name}
                      </span>
                    </td>
                    <td className="p-4 text-slate-600 dark:text-slate-400">
                      {idea.estimatedCostMin && idea.estimatedCostMax
                        ? `${formatCurrency(idea.estimatedCostMin)} - ${formatCurrency(idea.estimatedCostMax)}`
                        : '-'}
                    </td>
                    <td className="p-4 text-slate-500 dark:text-slate-400 text-sm">
                      {formatDate(idea.updatedAt)}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
