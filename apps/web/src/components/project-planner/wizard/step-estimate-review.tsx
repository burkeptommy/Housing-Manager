'use client';

import { useState, useEffect } from 'react';
import { getApiClient } from '@/lib/api';
import type { EstimateResult } from '@haven/core';
import type { WizardData } from '@/app/app/projects/new/page';

type StepEstimateReviewProps = {
  wizardData: WizardData;
  onUpdateEstimate: (estimate: EstimateResult | null) => void;
  onSave: (saveAsDream: boolean) => void;
  isSaving: boolean;
};

export default function StepEstimateReview({
  wizardData,
  onUpdateEstimate,
  onSave,
  isSaving,
}: StepEstimateReviewProps) {
  const [isLoadingEstimate, setIsLoadingEstimate] = useState(false);
  const [estimateError, setEstimateError] = useState<string | null>(null);

  // Calculate estimate when component mounts or relevant data changes
  useEffect(() => {
    const calculateEstimate = async () => {
      if (!wizardData.category) return;

      setIsLoadingEstimate(true);
      setEstimateError(null);

      try {
        const api = getApiClient();
        const estimate = await api.calculateProjectEstimate({
          templateId: wizardData.templateId || undefined,
          category: wizardData.category,
          specs: wizardData.specs,
        });
        onUpdateEstimate(estimate);
      } catch (err: unknown) {
        const message = err instanceof Error ? err.message : 'Failed to calculate estimate';
        setEstimateError(message);
      } finally {
        setIsLoadingEstimate(false);
      }
    };

    calculateEstimate();
  }, [wizardData.category, wizardData.templateId, wizardData.specs, onUpdateEstimate]);

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      maximumFractionDigits: 0,
    }).format(amount);
  };

  const estimate = wizardData.estimate;

  return (
    <div className="space-y-8">
      {/* Estimate Section */}
      <div className="text-center">
        <h2 className="text-lg font-medium text-slate-600 dark:text-slate-400 mb-2">
          Estimated Project Cost
        </h2>

        {isLoadingEstimate ? (
          <div className="flex items-center justify-center py-8">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-600"></div>
          </div>
        ) : estimateError ? (
          <div className="p-4 rounded-xl bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800">
            <p className="text-red-600 dark:text-red-400">{estimateError}</p>
          </div>
        ) : estimate ? (
          <>
            <div className="text-4xl md:text-5xl font-bold text-slate-900 dark:text-white mb-2">
              {formatCurrency(estimate.estimatedMin)} - {formatCurrency(estimate.estimatedMax)}
            </div>

            {/* Regional multiplier note */}
            {estimate.regionalMultiplier && estimate.regionalMultiplier !== 1 && (
              <p className="text-sm text-slate-500 dark:text-slate-400">
                Adjusted for your area (
                {estimate.regionalMultiplier > 1 ? '+' : ''}
                {((estimate.regionalMultiplier - 1) * 100).toFixed(0)}% regional difference)
              </p>
            )}

            {/* Social proof */}
            {estimate.socialProof && estimate.socialProof.count > 0 && (
              <div className="mt-4 inline-flex items-center gap-2 px-4 py-2 rounded-full bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-200">
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                  />
                </svg>
                <span className="text-sm font-medium">{estimate.socialProof.note}</span>
              </div>
            )}
          </>
        ) : (
          <div className="text-2xl text-slate-500 dark:text-slate-400">
            Unable to calculate estimate
          </div>
        )}
      </div>

      {/* Cost Breakdown */}
      {estimate?.breakdown && (
        <div className="p-4 rounded-xl bg-slate-50 dark:bg-slate-800/50 border border-slate-200 dark:border-slate-700">
          <h3 className="font-medium text-slate-900 dark:text-white mb-3">
            Cost Breakdown
          </h3>
          <div className="space-y-2">
            <div className="flex justify-between text-sm">
              <span className="text-slate-600 dark:text-slate-400">Materials</span>
              <span className="text-slate-900 dark:text-white font-medium">
                {formatCurrency(estimate.breakdown.materials)}
              </span>
            </div>
            <div className="flex justify-between text-sm">
              <span className="text-slate-600 dark:text-slate-400">Labor</span>
              <span className="text-slate-900 dark:text-white font-medium">
                {formatCurrency(estimate.breakdown.labor)}
              </span>
            </div>
            {estimate.breakdown.regional > 0 && (
              <div className="flex justify-between text-sm">
                <span className="text-slate-600 dark:text-slate-400">Regional Adjustment</span>
                <span className="text-slate-900 dark:text-white font-medium">
                  +{formatCurrency(estimate.breakdown.regional)}
                </span>
              </div>
            )}
            <div className="pt-2 mt-2 border-t border-slate-200 dark:border-slate-700 flex justify-between">
              <span className="font-medium text-slate-900 dark:text-white">Base Total</span>
              <span className="font-bold text-slate-900 dark:text-white">
                {formatCurrency(estimate.breakdown.materials + estimate.breakdown.labor + (estimate.breakdown.regional || 0))}
              </span>
            </div>
          </div>
        </div>
      )}

      {/* Project Summary */}
      <div className="p-4 rounded-xl bg-slate-50 dark:bg-slate-800/50 border border-slate-200 dark:border-slate-700">
        <h3 className="font-medium text-slate-900 dark:text-white mb-3">
          Project Summary
        </h3>
        <dl className="space-y-2 text-sm">
          <div className="flex justify-between">
            <dt className="text-slate-600 dark:text-slate-400">Project</dt>
            <dd className="text-slate-900 dark:text-white font-medium">
              {wizardData.title || wizardData.category?.replace(/_/g, ' ')}
            </dd>
          </div>
          {wizardData.template && (
            <div className="flex justify-between">
              <dt className="text-slate-600 dark:text-slate-400">Template</dt>
              <dd className="text-slate-900 dark:text-white">{wizardData.template.name}</dd>
            </div>
          )}
          <div className="flex justify-between">
            <dt className="text-slate-600 dark:text-slate-400">Size</dt>
            <dd className="text-slate-900 dark:text-white">{wizardData.specs.sqFt} sq ft</dd>
          </div>
          {wizardData.specs.complexity.length > 0 && (
            <div className="flex justify-between">
              <dt className="text-slate-600 dark:text-slate-400">Complexity</dt>
              <dd className="text-slate-900 dark:text-white">
                {wizardData.specs.complexity.length} factor(s)
              </dd>
            </div>
          )}
          {wizardData.style && (
            <div className="flex justify-between">
              <dt className="text-slate-600 dark:text-slate-400">Style</dt>
              <dd className="text-slate-900 dark:text-white capitalize">
                {wizardData.style.replace(/_/g, ' ')}
              </dd>
            </div>
          )}
          {wizardData.urgency && (
            <div className="flex justify-between">
              <dt className="text-slate-600 dark:text-slate-400">Timeline</dt>
              <dd className="text-slate-900 dark:text-white capitalize">
                {wizardData.urgency.replace(/_/g, ' ')}
              </dd>
            </div>
          )}
        </dl>
      </div>

      {/* Disclaimer */}
      <div className="p-4 rounded-xl bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
        <div className="flex gap-3">
          <svg
            className="w-5 h-5 text-amber-500 flex-shrink-0 mt-0.5"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
            />
          </svg>
          <div>
            <div className="font-medium text-amber-900 dark:text-amber-100 text-sm">
              This is an estimate, not a quote
            </div>
            <div className="text-sm text-amber-700 dark:text-amber-300 mt-1">
              Actual costs vary based on specific materials, site conditions, and contractor pricing.
              This estimate is based on regional averages and typical project specs.
            </div>
          </div>
        </div>
      </div>

      {/* Action Buttons */}
      <div className="flex flex-col sm:flex-row gap-3 pt-4">
        <button
          onClick={() => onSave(true)}
          disabled={isSaving}
          className="flex-1 btn btn-secondary"
        >
          {isSaving ? (
            <>
              <svg className="animate-spin -ml-1 mr-2 h-4 w-4" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
              </svg>
              Saving...
            </>
          ) : (
            <>
              <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
              </svg>
              Save as Dream
            </>
          )}
        </button>
        <button
          onClick={() => onSave(false)}
          disabled={isSaving}
          className="flex-1 btn btn-primary"
        >
          {isSaving ? (
            <>
              <svg className="animate-spin -ml-1 mr-2 h-4 w-4" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
              </svg>
              Saving...
            </>
          ) : (
            <>
              <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
              </svg>
              Start Planning
            </>
          )}
        </button>
      </div>

      <p className="text-center text-sm text-slate-500 dark:text-slate-400">
        <strong>Save as Dream:</strong> Keep it private and revisit anytime.{' '}
        <strong>Start Planning:</strong> Move to planning stage and find contractors.
      </p>
    </div>
  );
}
