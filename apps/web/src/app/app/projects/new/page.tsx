'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/auth-context';
import { getApiClient } from '@/lib/api';
import type { ProjectCategory, ProjectTemplate, EstimateResult, CreateProjectIdeaRequest } from '@haven/core';

// Wizard step components
import StepCategory from '@/components/project-planner/wizard/step-category';
import StepSizeScope from '@/components/project-planner/wizard/step-size-scope';
import StepVibe from '@/components/project-planner/wizard/step-vibe';
import StepTimeline from '@/components/project-planner/wizard/step-timeline';
import StepEstimateReview from '@/components/project-planner/wizard/step-estimate-review';

export type WizardData = {
  category: ProjectCategory | null;
  templateId: string | null;
  template: ProjectTemplate | null;
  title: string;
  description: string;
  specs: {
    sqFt: number;
    complexity: string[];
  };
  style: string | null;
  vibeNotes: string;
  moodBoardImages: string[];
  urgency: string | null;
  targetStartDate: string | null;
  targetCompletionDate: string | null;
  estimate: EstimateResult | null;
};

const initialWizardData: WizardData = {
  category: null,
  templateId: null,
  template: null,
  title: '',
  description: '',
  specs: {
    sqFt: 200,
    complexity: [],
  },
  style: null,
  vibeNotes: '',
  moodBoardImages: [],
  urgency: null,
  targetStartDate: null,
  targetCompletionDate: null,
  estimate: null,
};

const STEPS = [
  { id: 1, name: 'Category', title: "What's the dream?" },
  { id: 2, name: 'Size', title: 'How big we talkin\'?' },
  { id: 3, name: 'Style', title: 'What\'s the vibe?' },
  { id: 4, name: 'Timeline', title: 'When do you want it?' },
  { id: 5, name: 'Review', title: 'Here\'s your estimate' },
];

export default function NewProjectWizardPage() {
  const router = useRouter();
  const { currentHousehold, isLoading: authLoading } = useAuth();
  const [currentStep, setCurrentStep] = useState(1);
  const [wizardData, setWizardData] = useState<WizardData>(initialWizardData);
  const [templates, setTemplates] = useState<ProjectTemplate[]>([]);
  const [isLoadingTemplates, setIsLoadingTemplates] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Load templates on mount
  useEffect(() => {
    const loadTemplates = async () => {
      try {
        const api = getApiClient();
        const data = await api.getProjectTemplates();
        setTemplates(data);
      } catch (err) {
        console.error('Failed to load templates:', err);
      } finally {
        setIsLoadingTemplates(false);
      }
    };
    loadTemplates();
  }, []);

  // Redirect if not authenticated
  useEffect(() => {
    if (!authLoading && !currentHousehold) {
      router.push('/app');
    }
  }, [authLoading, currentHousehold, router]);

  const updateWizardData = (updates: Partial<WizardData>) => {
    setWizardData((prev) => ({ ...prev, ...updates }));
  };

  const handleNext = () => {
    if (currentStep < STEPS.length) {
      setCurrentStep(currentStep + 1);
    }
  };

  const handleBack = () => {
    if (currentStep > 1) {
      setCurrentStep(currentStep - 1);
    }
  };

  const handleSave = async (saveAsDream: boolean = true) => {
    if (!currentHousehold) return;

    setIsSaving(true);
    setError(null);

    try {
      const api = getApiClient();

      // Create the project idea
      const requestData: CreateProjectIdeaRequest = {
        templateId: wizardData.templateId || undefined,
        title: wizardData.title || `${wizardData.category?.replace(/_/g, ' ')} Project`,
        category: wizardData.category!,
        description: wizardData.description || undefined,
        specs: wizardData.specs,
        style: wizardData.style || undefined,
        vibeNotes: wizardData.vibeNotes || undefined,
        moodBoardImages: wizardData.moodBoardImages.length > 0 ? wizardData.moodBoardImages : undefined,
        estimatedCostMin: wizardData.estimate?.estimatedMin,
        estimatedCostMax: wizardData.estimate?.estimatedMax,
        neighborProjectCount: wizardData.estimate?.socialProof?.neighborProjectCount,
        socialProofNote: wizardData.estimate?.socialProof?.note,
        targetStartDate: wizardData.targetStartDate || undefined,
        targetCompletionDate: wizardData.targetCompletionDate || undefined,
        urgency: wizardData.urgency || undefined,
      };

      const idea = await api.createProjectIdea(requestData);

      // If not saving as dream, progress to PLANNING
      if (!saveAsDream) {
        await api.progressProjectIdea(idea.id, 'PLANNING');
      }

      // Navigate to the project detail page
      router.push(`/app/projects/${idea.id}`);
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Failed to save project. Please try again.';
      setError(message);
    } finally {
      setIsSaving(false);
    }
  };

  if (authLoading || isLoadingTemplates) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-600"></div>
      </div>
    );
  }

  return (
    <div className="max-w-4xl mx-auto">
      {/* Header */}
      <div className="mb-8">
        <button
          onClick={() => router.push('/app/projects')}
          className="flex items-center gap-2 text-neutral-600 dark:text-neutral-400 hover:text-neutral-900 dark:hover:text-white mb-4"
        >
          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
          </svg>
          Back to Projects
        </button>
        <h1 className="text-2xl font-bold text-neutral-900 dark:text-white">
          {STEPS[currentStep - 1]?.title}
        </h1>
        <p className="text-neutral-600 dark:text-neutral-400 mt-1">
          Step {currentStep} of {STEPS.length}
        </p>
      </div>

      {/* Progress bar */}
      <div className="mb-8">
        <div className="flex items-center justify-between mb-2">
          {STEPS.map((step, index) => (
            <div
              key={step.id}
              className={`flex items-center ${index < STEPS.length - 1 ? 'flex-1' : ''}`}
            >
              <div
                className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium transition-colors ${
                  step.id <= currentStep
                    ? 'bg-emerald-600 text-white'
                    : 'bg-neutral-200 dark:bg-neutral-700 text-neutral-500 dark:text-neutral-400'
                }`}
              >
                {step.id < currentStep ? (
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                  </svg>
                ) : (
                  step.id
                )}
              </div>
              {index < STEPS.length - 1 && (
                <div
                  className={`flex-1 h-1 mx-2 rounded ${
                    step.id < currentStep
                      ? 'bg-emerald-600'
                      : 'bg-neutral-200 dark:bg-neutral-700'
                  }`}
                />
              )}
            </div>
          ))}
        </div>
        <div className="flex justify-between text-xs text-neutral-500 dark:text-neutral-400">
          {STEPS.map((step) => (
            <span key={step.id} className="w-8 text-center">
              {step.name}
            </span>
          ))}
        </div>
      </div>

      {/* Error message */}
      {error && (
        <div className="mb-6 p-4 rounded-lg bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800">
          <p className="text-sm text-red-600 dark:text-red-400">{error}</p>
        </div>
      )}

      {/* Step content */}
      <div className="card p-6">
        {currentStep === 1 && (
          <StepCategory
            templates={templates}
            selectedCategory={wizardData.category}
            selectedTemplateId={wizardData.templateId}
            onSelectCategory={(category) => {
              updateWizardData({
                category,
                templateId: null,
                template: null,
                title: '',
              });
            }}
            onSelectTemplate={(templateId) => {
              const template = templates.find((t) => t.id === templateId) || null;
              updateWizardData({
                templateId,
                template,
                title: template?.name || '',
                specs: {
                  ...wizardData.specs,
                  sqFt: template?.minSqFt || 200,
                },
              });
            }}
          />
        )}

        {currentStep === 2 && (
          <StepSizeScope
            template={wizardData.template}
            specs={wizardData.specs}
            title={wizardData.title}
            description={wizardData.description}
            onUpdateSpecs={(specs) => updateWizardData({ specs })}
            onUpdateTitle={(title) => updateWizardData({ title })}
            onUpdateDescription={(description) => updateWizardData({ description })}
          />
        )}

        {currentStep === 3 && (
          <StepVibe
            template={wizardData.template}
            style={wizardData.style}
            vibeNotes={wizardData.vibeNotes}
            moodBoardImages={wizardData.moodBoardImages}
            onUpdateStyle={(style) => updateWizardData({ style })}
            onUpdateVibeNotes={(vibeNotes) => updateWizardData({ vibeNotes })}
            onUpdateMoodBoardImages={(moodBoardImages) => updateWizardData({ moodBoardImages })}
          />
        )}

        {currentStep === 4 && (
          <StepTimeline
            urgency={wizardData.urgency}
            targetStartDate={wizardData.targetStartDate}
            targetCompletionDate={wizardData.targetCompletionDate}
            onUpdateUrgency={(urgency) => updateWizardData({ urgency })}
            onUpdateTargetStartDate={(targetStartDate) => updateWizardData({ targetStartDate })}
            onUpdateTargetCompletionDate={(targetCompletionDate) => updateWizardData({ targetCompletionDate })}
          />
        )}

        {currentStep === 5 && (
          <StepEstimateReview
            wizardData={wizardData}
            onUpdateEstimate={(estimate) => updateWizardData({ estimate })}
            onSave={handleSave}
            isSaving={isSaving}
          />
        )}
      </div>

      {/* Navigation buttons */}
      {currentStep < 5 && (
        <div className="flex justify-between mt-6">
          <button
            onClick={handleBack}
            disabled={currentStep === 1}
            className={`btn btn-secondary ${currentStep === 1 ? 'invisible' : ''}`}
          >
            <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
            </svg>
            Back
          </button>
          <button
            onClick={handleNext}
            disabled={
              (currentStep === 1 && !wizardData.category) ||
              (currentStep === 2 && wizardData.specs.sqFt <= 0)
            }
            className="btn btn-primary"
          >
            Next
            <svg className="w-5 h-5 ml-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
            </svg>
          </button>
        </div>
      )}
    </div>
  );
}
