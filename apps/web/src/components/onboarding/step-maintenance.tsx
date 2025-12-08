'use client';

import { useState, useCallback, useMemo } from 'react';
import type { MaintenanceTask, MaintenanceCategory, HouseholdVendor } from '@haven/core';

const CATEGORY_LABELS: Record<MaintenanceCategory, { label: string; icon: string }> = {
  HVAC: { label: 'HVAC', icon: '❄️' },
  PLUMBING: { label: 'Plumbing', icon: '🔧' },
  ROOF_GUTTER: { label: 'Roof & Gutters', icon: '🏠' },
  CHIMNEY: { label: 'Chimney', icon: '🔥' },
  SEPTIC: { label: 'Septic', icon: '🚽' },
  LANDSCAPING: { label: 'Landscaping', icon: '🌳' },
  PEST: { label: 'Pest Control', icon: '🐜' },
  POOL: { label: 'Pool', icon: '🏊' },
  SAFETY: { label: 'Safety', icon: '🛡️' },
  CLEANING: { label: 'Cleaning', icon: '✨' },
  APPLIANCES: { label: 'Appliances', icon: '🔌' },
  EXTERIOR: { label: 'Exterior', icon: '🏡' },
  INTERIOR: { label: 'Interior', icon: '🛋️' },
  GENERAL: { label: 'General', icon: '📋' },
};

const FREQUENCY_LABELS: Record<number, string> = {
  1: 'Monthly',
  3: 'Quarterly',
  6: 'Every 6 months',
  12: 'Annually',
  24: 'Every 2 years',
  36: 'Every 3 years',
};

export interface TaskSelection {
  taskId: string;
  keep: boolean;
  vendorId?: string;
  dueDate?: string;
}

interface StepMaintenanceProps {
  tasks: MaintenanceTask[];
  vendors: HouseholdVendor[];
  onSubmit: (selections: TaskSelection[]) => void;
  onBack: () => void;
  isLoading?: boolean;
  isSubmitting?: boolean;
}

export function StepMaintenance({
  tasks,
  vendors,
  onSubmit,
  onBack,
  isLoading,
  isSubmitting,
}: StepMaintenanceProps) {
  const [selections, setSelections] = useState<Map<string, TaskSelection>>(() => {
    const map = new Map<string, TaskSelection>();
    tasks.forEach((task) => {
      map.set(task.id, {
        taskId: task.id,
        keep: true,
        vendorId: task.assignedVendorId || undefined,
        dueDate: task.dueDate ? new Date(task.dueDate).toISOString().split('T')[0] : undefined,
      });
    });
    return map;
  });

  // Group tasks by category
  const groupedTasks = useMemo(() => {
    const groups = new Map<MaintenanceCategory, MaintenanceTask[]>();
    tasks.forEach((task) => {
      const existing = groups.get(task.category) || [];
      existing.push(task);
      groups.set(task.category, existing);
    });
    return groups;
  }, [tasks]);

  // Get vendors that match a task's category
  const getMatchingVendors = useCallback((task: MaintenanceTask): HouseholdVendor[] => {
    return vendors.filter((vendor) => {
      // Match vendor category to task category mapping
      const vendorCategoryMap: Record<string, MaintenanceCategory[]> = {
        HVAC_SERVICE: ['HVAC'],
        FILTER_SERVICE: ['HVAC'],
        PLUMBING: ['PLUMBING'],
        GUTTER_CLEANING: ['ROOF_GUTTER'],
        CHIMNEY_SWEEP: ['CHIMNEY'],
        SEPTIC_SERVICE: ['SEPTIC'],
        LANDSCAPING: ['LANDSCAPING'],
        LAWN_CARE: ['LANDSCAPING'],
        PEST_CONTROL: ['PEST'],
        POOL_SERVICE: ['POOL'],
        CLEANING: ['CLEANING'],
        WINDOW_WASHING: ['CLEANING'],
        HANDYMAN: ['GENERAL', 'EXTERIOR', 'INTERIOR'],
      };
      const matchingCategories = vendorCategoryMap[vendor.category] || [];
      return matchingCategories.includes(task.category);
    });
  }, [vendors]);

  const toggleTask = useCallback((taskId: string) => {
    setSelections((prev) => {
      const next = new Map(prev);
      const existing = next.get(taskId);
      if (existing) {
        next.set(taskId, { ...existing, keep: !existing.keep });
      }
      return next;
    });
  }, []);

  const updateSelection = useCallback((taskId: string, field: 'vendorId' | 'dueDate', value: string | undefined) => {
    setSelections((prev) => {
      const next = new Map(prev);
      const existing = next.get(taskId);
      if (existing) {
        next.set(taskId, { ...existing, [field]: value });
      }
      return next;
    });
  }, []);

  const handleSubmit = useCallback(() => {
    onSubmit(Array.from(selections.values()));
  }, [selections, onSubmit]);

  const selectedCount = useMemo(() => {
    return Array.from(selections.values()).filter((s) => s.keep).length;
  }, [selections]);

  if (isLoading) {
    return (
      <div className="space-y-6">
        <div>
          <h2 className="text-lg font-semibold text-slate-900 dark:text-white mb-1">
            Setting up your maintenance plan
          </h2>
          <p className="text-sm text-slate-600 dark:text-slate-400">
            Generating personalized maintenance tasks based on your property features...
          </p>
        </div>
        <div className="flex items-center justify-center py-12">
          <div className="text-center">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
            <p className="mt-4 text-slate-600 dark:text-slate-400">Analyzing your home...</p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-lg font-semibold text-slate-900 dark:text-white mb-1">
          Your maintenance plan
        </h2>
        <p className="text-sm text-slate-600 dark:text-slate-400">
          Based on your home features, we&apos;ve created a personalized maintenance schedule.
          Review and adjust as needed.
        </p>
      </div>

      {tasks.length === 0 ? (
        <div className="text-center py-12 bg-slate-50 dark:bg-slate-800 rounded-lg">
          <svg
            className="w-12 h-12 mx-auto text-slate-400"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
            />
          </svg>
          <p className="mt-4 text-slate-600 dark:text-slate-400">
            No maintenance tasks generated yet.
          </p>
          <p className="text-sm text-slate-500 dark:text-slate-500">
            This might happen if no templates match your property features.
          </p>
        </div>
      ) : (
        <div className="space-y-6">
          {Array.from(groupedTasks.entries()).map(([category, categoryTasks]) => {
            const categoryInfo = CATEGORY_LABELS[category];
            return (
              <div key={category} className="space-y-3">
                <h3 className="flex items-center gap-2 text-sm font-medium text-slate-700 dark:text-slate-300 border-b border-slate-200 dark:border-slate-700 pb-2">
                  <span>{categoryInfo.icon}</span>
                  {categoryInfo.label}
                  <span className="text-xs text-slate-500">({categoryTasks.length})</span>
                </h3>

                <div className="space-y-3">
                  {categoryTasks.map((task) => {
                    const selection = selections.get(task.id);
                    const matchingVendors = getMatchingVendors(task);

                    return (
                      <div
                        key={task.id}
                        className={`p-4 rounded-lg border transition-colors ${
                          selection?.keep
                            ? 'border-blue-200 dark:border-blue-800 bg-blue-50/50 dark:bg-blue-900/20'
                            : 'border-slate-200 dark:border-slate-700 bg-slate-50/50 dark:bg-slate-800/50 opacity-60'
                        }`}
                      >
                        <div className="flex items-start gap-3">
                          <input
                            type="checkbox"
                            checked={selection?.keep || false}
                            onChange={() => toggleTask(task.id)}
                            className="mt-1 w-4 h-4 text-blue-600 rounded border-slate-300 dark:border-slate-600"
                          />
                          <div className="flex-1 min-w-0">
                            <div className="flex items-start justify-between gap-4">
                              <div>
                                <h4 className="font-medium text-slate-900 dark:text-white">
                                  {task.title}
                                </h4>
                                {task.description && (
                                  <p className="text-sm text-slate-600 dark:text-slate-400 mt-1">
                                    {task.description}
                                  </p>
                                )}
                              </div>
                              {task.template?.recommendedFrequencyMonths && (
                                <span className="shrink-0 text-xs px-2 py-1 rounded-full bg-slate-200 dark:bg-slate-700 text-slate-600 dark:text-slate-400">
                                  {FREQUENCY_LABELS[task.template.recommendedFrequencyMonths] ||
                                    `Every ${task.template.recommendedFrequencyMonths} months`}
                                </span>
                              )}
                            </div>

                            {selection?.keep && (
                              <div className="mt-3 grid grid-cols-2 gap-4">
                                <div>
                                  <label className="label block mb-1.5 text-xs">Due date</label>
                                  <input
                                    type="date"
                                    value={selection?.dueDate || ''}
                                    onChange={(e) => updateSelection(task.id, 'dueDate', e.target.value)}
                                    className="input text-sm"
                                  />
                                </div>
                                <div>
                                  <label className="label block mb-1.5 text-xs">Assign vendor</label>
                                  <select
                                    value={selection?.vendorId || ''}
                                    onChange={(e) => updateSelection(task.id, 'vendorId', e.target.value || undefined)}
                                    className="input text-sm"
                                  >
                                    <option value="">No vendor assigned</option>
                                    {matchingVendors.map((vendor) => (
                                      <option key={vendor.id} value={vendor.id}>
                                        {vendor.displayName}
                                      </option>
                                    ))}
                                    {matchingVendors.length === 0 && vendors.length > 0 && (
                                      <optgroup label="Other vendors">
                                        {vendors.map((vendor) => (
                                          <option key={vendor.id} value={vendor.id}>
                                            {vendor.displayName}
                                          </option>
                                        ))}
                                      </optgroup>
                                    )}
                                  </select>
                                </div>
                              </div>
                            )}

                            {task.template && (
                              <div className="mt-2 flex items-center gap-4 text-xs text-slate-500 dark:text-slate-400">
                                {task.template.estimatedCostMin !== null && task.template.estimatedCostMax !== null && (
                                  <span>
                                    Est. ${task.template.estimatedCostMin} - ${task.template.estimatedCostMax}
                                  </span>
                                )}
                              </div>
                            )}
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Summary */}
      <div className="p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
        <p className="text-sm text-blue-800 dark:text-blue-200">
          <strong>{selectedCount}</strong> task{selectedCount !== 1 ? 's' : ''} will be added to your maintenance schedule.
          Skipped tasks won&apos;t be tracked.
        </p>
      </div>

      <div className="flex gap-3 pt-4">
        <button type="button" onClick={onBack} className="btn btn-secondary flex-1">
          Back
        </button>
        <button
          type="button"
          onClick={handleSubmit}
          disabled={isSubmitting}
          className="btn btn-primary flex-1"
        >
          {isSubmitting ? (
            <>
              <svg className="animate-spin -ml-1 mr-2 h-4 w-4" fill="none" viewBox="0 0 24 24">
                <circle
                  className="opacity-25"
                  cx="12"
                  cy="12"
                  r="10"
                  stroke="currentColor"
                  strokeWidth="4"
                />
                <path
                  className="opacity-75"
                  fill="currentColor"
                  d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                />
              </svg>
              Saving...
            </>
          ) : (
            'Continue'
          )}
        </button>
      </div>
    </div>
  );
}
