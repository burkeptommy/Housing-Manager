'use client';

import { Check } from 'lucide-react';
import { cn } from '@/lib/utils';

interface Step {
  id: string;
  label: string;
  href: string;
}

interface ProgressStepperProps {
  steps: Step[];
  currentStep: string;
  completedSteps: string[];
}

export function ProgressStepper({ steps, currentStep, completedSteps }: ProgressStepperProps) {
  return (
    <div className="w-full max-w-2xl mx-auto px-4 py-6">
      <div className="flex items-center justify-between">
        {steps.map((step, index) => {
          const isCompleted = completedSteps.includes(step.id);
          const isCurrent = step.id === currentStep;
          const isPast = completedSteps.includes(step.id);

          return (
            <div key={step.id} className="flex items-center flex-1 last:flex-none">
              {/* Step Circle */}
              <div className="flex flex-col items-center">
                <div
                  className={cn(
                    'w-10 h-10 rounded-full flex items-center justify-center text-sm font-medium transition-all',
                    isCompleted && 'bg-haven-900 text-white',
                    isCurrent && !isCompleted && 'bg-haven-500 text-haven-900 ring-4 ring-haven-200',
                    !isCurrent && !isCompleted && 'bg-gray-200 text-gray-500'
                  )}
                >
                  {isCompleted ? (
                    <Check className="w-5 h-5" />
                  ) : (
                    index + 1
                  )}
                </div>
                <span
                  className={cn(
                    'mt-2 text-xs font-medium hidden sm:block',
                    isCurrent ? 'text-haven-900' : 'text-gray-500'
                  )}
                >
                  {step.label}
                </span>
              </div>

              {/* Connector Line */}
              {index < steps.length - 1 && (
                <div
                  className={cn(
                    'flex-1 h-1 mx-2',
                    isPast ? 'bg-haven-900' : 'bg-gray-200'
                  )}
                />
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}
