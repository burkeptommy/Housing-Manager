'use client';

import { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/auth-context';
import { getApiClient } from '@/lib/api';
import type {
  MaintenanceTask,
  HouseholdVendor,
  SubscriptionPlan,
  PropertyFeatures,
} from '@haven/core';

import {
  StepHomeBasics,
  type HomeBasicsData,
  StepRecurringBills,
  type BillEntry,
  StepMaintenance,
  type TaskSelection,
  StepPayment,
  StepReview,
} from '@/components/onboarding';

const STEPS = [
  { id: 1, name: 'Home Basics', description: 'Property details' },
  { id: 2, name: 'Bills', description: 'Recurring bills' },
  { id: 3, name: 'Maintenance', description: 'Maintenance plan' },
  { id: 4, name: 'Plan', description: 'Subscription' },
  { id: 5, name: 'Review', description: 'Confirm setup' },
];

export default function OnboardingPage() {
  const router = useRouter();
  const { isAuthenticated, isLoading: authLoading, needsOnboarding, completeOnboarding, user } = useAuth();
  const [currentStep, setCurrentStep] = useState(1);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isLoadingTasks, setIsLoadingTasks] = useState(false);
  const [error, setError] = useState('');

  // Onboarding state
  const [householdId, setHouseholdId] = useState<string | null>(null);
  const [homeBasics, setHomeBasics] = useState<HomeBasicsData | null>(null);
  const [bills, setBills] = useState<BillEntry[]>([]);
  const [vendors, setVendors] = useState<HouseholdVendor[]>([]);
  const [maintenanceTasks, setMaintenanceTasks] = useState<MaintenanceTask[]>([]);
  const [taskSelections, setTaskSelections] = useState<TaskSelection[]>([]);
  const [selectedPlan, setSelectedPlan] = useState<SubscriptionPlan | null>(null);

  const api = getApiClient();

  // Redirect if not authenticated or doesn't need onboarding
  useEffect(() => {
    if (!authLoading && !isAuthenticated) {
      router.push('/login');
    } else if (!authLoading && isAuthenticated && !needsOnboarding) {
      router.push('/app');
    }
  }, [authLoading, isAuthenticated, needsOnboarding, router]);

  // Step 1: Home Basics
  const handleHomeBasicsSubmit = useCallback(
    async (data: HomeBasicsData) => {
      setIsSubmitting(true);
      setError('');

      try {
        // Create household
        const household = await api.createHousehold({
          name: data.name,
          description: `${data.propertyType} in ${data.city}, ${data.state}`,
        });

        setHouseholdId(household.id);

        // Extract property features for notes
        const features: PropertyFeatures = {
          hasCentralAc: data.hasCentralAc,
          hasGasHeat: data.hasGasHeat,
          hasOilHeat: data.hasOilHeat,
          hasFireplace: data.hasFireplace,
          hasSeptic: data.hasSeptic,
          hasWellWater: data.hasWellWater,
          hasPool: data.hasPool,
          hasGenerator: data.hasGenerator,
          hasLawn: data.hasLawn,
          hasDriveway: data.hasDriveway,
        };

        // Create home profile
        await api.upsertHomeProfile(household.id, {
          propertyType: data.propertyType,
          addressLine1: data.addressLine1,
          addressLine2: data.addressLine2,
          city: data.city,
          state: data.state,
          postalCode: data.postalCode,
          country: 'US',
          yearBuilt: data.yearBuilt,
          bedrooms: data.bedrooms,
          bathrooms: data.bathrooms,
          squareFeet: data.squareFeet,
          notes: JSON.stringify({ features }),
        });

        setHomeBasics(data);
        setCurrentStep(2);
      } catch (err: unknown) {
        const message =
          err && typeof err === 'object' && 'message' in err
            ? (err as { message: string }).message
            : 'Failed to save property details. Please try again.';
        setError(message);
      } finally {
        setIsSubmitting(false);
      }
    },
    [api]
  );

  // Step 2: Recurring Bills
  const handleBillsSubmit = useCallback(
    async (billEntries: BillEntry[]) => {
      if (!householdId) return;

      setIsSubmitting(true);
      setError('');

      try {
        const createdVendors: HouseholdVendor[] = [];

        // Create vendors and bill accounts
        for (const bill of billEntries) {
          // Create vendor first
          const vendor = await api.createHouseholdVendor(householdId, {
            displayName: bill.vendorName,
            category: bill.category,
          });
          createdVendors.push(vendor);

          // Create bill account
          await api.createBillAccount({
            householdId,
            vendorId: vendor.id,
            nickname: bill.vendorName,
            category: bill.category,
            accountNumber: bill.accountNumber || undefined,
            billingFrequency: bill.billingFrequency,
            paymentResponsibility: bill.paymentResponsibility,
            typicalAmount: bill.typicalAmount || undefined,
            nextDueDate: bill.nextDueDate || undefined,
          });
        }

        setVendors(createdVendors);
        setBills(billEntries);
        setCurrentStep(3);
      } catch (err: unknown) {
        const message =
          err && typeof err === 'object' && 'message' in err
            ? (err as { message: string }).message
            : 'Failed to save bills. Please try again.';
        setError(message);
      } finally {
        setIsSubmitting(false);
      }
    },
    [api, householdId]
  );

  // Load maintenance tasks when entering step 3
  useEffect(() => {
    if (currentStep === 3 && householdId && maintenanceTasks.length === 0) {
      setIsLoadingTasks(true);
      api
        .generateMaintenanceTasksFromTemplates({ householdId })
        .then((result) => {
          setMaintenanceTasks(result.tasks);
        })
        .catch((err) => {
          console.error('Failed to generate maintenance tasks:', err);
        })
        .finally(() => {
          setIsLoadingTasks(false);
        });
    }
  }, [currentStep, householdId, maintenanceTasks.length, api]);

  // Step 3: Maintenance
  const handleMaintenanceSubmit = useCallback(
    async (selections: TaskSelection[]) => {
      if (!householdId) return;

      setIsSubmitting(true);
      setError('');

      try {
        // Update tasks based on selections
        for (const selection of selections) {
          if (!selection.keep) {
            // Mark as skipped
            await api.updateMaintenanceTask(selection.taskId, { status: 'SKIPPED' });
          } else if (selection.vendorId || selection.dueDate) {
            // Update with vendor/date changes
            await api.updateMaintenanceTask(selection.taskId, {
              assignedVendorId: selection.vendorId || null,
              dueDate: selection.dueDate || null,
            });
          }
        }

        setTaskSelections(selections);
        setCurrentStep(4);
      } catch (err: unknown) {
        const message =
          err && typeof err === 'object' && 'message' in err
            ? (err as { message: string }).message
            : 'Failed to save maintenance preferences. Please try again.';
        setError(message);
      } finally {
        setIsSubmitting(false);
      }
    },
    [api, householdId]
  );

  // Step 4: Payment
  const handlePaymentSubmit = useCallback(
    async (data: { plan: SubscriptionPlan; paymentMethodId?: string }) => {
      setSelectedPlan(data.plan);
      setCurrentStep(5);
    },
    []
  );

  // Step 5: Final submission
  const handleFinalSubmit = useCallback(async () => {
    if (!householdId) return;

    setIsSubmitting(true);
    setError('');

    try {
      // Create subscription if plan selected
      if (selectedPlan) {
        try {
          await api.createSubscription({
            tier: selectedPlan === 'ESSENTIALS' ? 'BASIC' : 'PREMIUM',
            paymentMethodId: 'skip_for_now', // Placeholder
          });
        } catch {
          // Subscription creation might fail if no payment method - that's ok for now
          console.warn('Subscription creation skipped - no payment method');
        }
      }

      // Complete onboarding
      await completeOnboarding(householdId);
    } catch (err: unknown) {
      const message =
        err && typeof err === 'object' && 'message' in err
          ? (err as { message: string }).message
          : 'Failed to complete setup. Please try again.';
      setError(message);
      setIsSubmitting(false);
    }
  }, [api, householdId, selectedPlan, completeOnboarding]);

  // Navigation
  const goBack = useCallback(() => {
    setCurrentStep((prev) => Math.max(1, prev - 1));
  }, []);

  const goToStep = useCallback((step: number) => {
    setCurrentStep(step);
  }, []);

  // Count selected maintenance tasks
  const selectedTaskCount = taskSelections.filter((s) => s.keep).length || maintenanceTasks.length;

  if (authLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-slate-50 dark:bg-slate-900">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-slate-600 dark:text-slate-400">Loading...</p>
        </div>
      </div>
    );
  }

  if (!isAuthenticated) {
    return null;
  }

  return (
    <div className="min-h-screen bg-slate-50 dark:bg-slate-900 py-8 px-4">
      <div className="max-w-2xl mx-auto">
        {/* Header */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-blue-600 text-white mb-4">
            <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"
              />
            </svg>
          </div>
          <h1 className="text-2xl font-bold text-slate-900 dark:text-white">
            Welcome, {user?.firstName}!
          </h1>
          <p className="text-slate-600 dark:text-slate-400 mt-1">
            Let&apos;s set up your home
          </p>
        </div>

        {/* Progress Steps */}
        <div className="mb-8">
          <div className="flex items-center justify-between">
            {STEPS.map((step, idx) => (
              <div key={step.id} className="flex items-center">
                <div
                  className={`flex items-center justify-center w-10 h-10 rounded-full border-2 transition-colors ${
                    currentStep > step.id
                      ? 'bg-blue-600 border-blue-600 text-white'
                      : currentStep === step.id
                        ? 'border-blue-600 text-blue-600'
                        : 'border-slate-300 dark:border-slate-600 text-slate-400'
                  }`}
                >
                  {currentStep > step.id ? (
                    <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                      <path
                        fillRule="evenodd"
                        d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                        clipRule="evenodd"
                      />
                    </svg>
                  ) : (
                    step.id
                  )}
                </div>
                {idx < STEPS.length - 1 && (
                  <div
                    className={`w-8 sm:w-12 h-1 mx-1 rounded ${
                      currentStep > step.id ? 'bg-blue-600' : 'bg-slate-200 dark:bg-slate-700'
                    }`}
                  />
                )}
              </div>
            ))}
          </div>
          <div className="flex justify-between mt-2">
            {STEPS.map((step) => (
              <div key={step.id} className="text-center" style={{ width: '60px' }}>
                <p
                  className={`text-xs font-medium truncate ${
                    currentStep >= step.id
                      ? 'text-slate-900 dark:text-white'
                      : 'text-slate-400 dark:text-slate-500'
                  }`}
                >
                  {step.name}
                </p>
              </div>
            ))}
          </div>
        </div>

        {/* Error Display */}
        {error && (
          <div className="mb-6 p-4 rounded-lg bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800">
            <p className="text-sm text-red-600 dark:text-red-400">{error}</p>
          </div>
        )}

        {/* Step Content */}
        <div className="card">
          {currentStep === 1 && (
            <StepHomeBasics
              onSubmit={handleHomeBasicsSubmit}
              defaultValues={homeBasics}
              isSubmitting={isSubmitting}
            />
          )}
          {currentStep === 2 && (
            <StepRecurringBills
              onSubmit={handleBillsSubmit}
              onBack={goBack}
              defaultValues={bills}
              isSubmitting={isSubmitting}
            />
          )}
          {currentStep === 3 && (
            <StepMaintenance
              tasks={maintenanceTasks}
              vendors={vendors}
              onSubmit={handleMaintenanceSubmit}
              onBack={goBack}
              isLoading={isLoadingTasks}
              isSubmitting={isSubmitting}
            />
          )}
          {currentStep === 4 && (
            <StepPayment
              onSubmit={handlePaymentSubmit}
              onBack={goBack}
              isSubmitting={isSubmitting}
            />
          )}
          {currentStep === 5 && (
            <StepReview
              homeBasics={homeBasics}
              bills={bills}
              maintenanceTaskCount={selectedTaskCount}
              selectedPlan={selectedPlan}
              onSubmit={handleFinalSubmit}
              onBack={goBack}
              onEditStep={goToStep}
              isSubmitting={isSubmitting}
            />
          )}
        </div>
      </div>
    </div>
  );
}
