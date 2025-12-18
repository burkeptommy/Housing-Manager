'use client';

import type { PropertyFeatures, SubscriptionPlan, VendorCategory } from '@haven/core';
import { SUBSCRIPTION_PLANS } from '@haven/core';
import type { HomeBasicsData } from './step-home-basics';
import type { BillEntry } from './step-recurring-bills';

// Category labels for display
const BILL_CATEGORY_LABELS: Record<VendorCategory, string> = {
  MORTGAGE: 'Mortgage',
  HOA: 'HOA',
  PROPERTY_TAX: 'Property Tax',
  ELECTRIC: 'Electric',
  GAS: 'Gas',
  WATER_SEWER: 'Water & Sewer',
  TRASH: 'Trash',
  INTERNET: 'Internet',
  MOBILE: 'Mobile',
  CABLE: 'Cable',
  HOME_INSURANCE: 'Home Insurance',
  AUTO_INSURANCE: 'Auto Insurance',
  HEALTH_INSURANCE: 'Health Insurance',
  LIFE_INSURANCE: 'Life Insurance',
  PET_INSURANCE: 'Pet Insurance',
  CREDIT_CARD: 'Credit Card',
  STUDENT_LOAN: 'Student Loan',
  PERSONAL_LOAN: 'Personal Loan',
  VEHICLE_LOAN: 'Vehicle Loan',
  HELOC: 'HELOC',
  STREAMING: 'Streaming',
  GYM: 'Gym',
  SECURITY_MONITORING: 'Security',
  PEST_CONTROL: 'Pest Control',
  LAWN_CARE: 'Lawn Care',
  LANDSCAPING: 'Landscaping',
  HOME_WARRANTY: 'Home Warranty',
  CLEANING: 'Cleaning',
  WINDOW_WASHING: 'Window Washing',
  GUTTER_CLEANING: 'Gutter Cleaning',
  HVAC_SERVICE: 'HVAC Service',
  FILTER_SERVICE: 'Filter Service',
  CHIMNEY_SWEEP: 'Chimney Sweep',
  SEPTIC_SERVICE: 'Septic Service',
  POOL_SERVICE: 'Pool Service',
  SNOW_REMOVAL: 'Snow Removal',
  HANDYMAN: 'Handyman',
  OTHER: 'Other',
};

interface StepReviewProps {
  homeBasics: HomeBasicsData | null;
  bills: BillEntry[];
  maintenanceTaskCount: number;
  selectedPlan: SubscriptionPlan | null;
  onSubmit: () => void;
  onBack: () => void;
  onEditStep: (step: number) => void;
  isSubmitting?: boolean;
}

export function StepReview({
  homeBasics,
  bills,
  maintenanceTaskCount,
  selectedPlan,
  onSubmit,
  onBack,
  onEditStep,
  isSubmitting,
}: StepReviewProps) {
  const propertyFeatures: { key: keyof PropertyFeatures; label: string }[] = [
    { key: 'hasCentralAc', label: 'Central A/C' },
    { key: 'hasGasHeat', label: 'Gas Heat' },
    { key: 'hasOilHeat', label: 'Oil Heat' },
    { key: 'hasFireplace', label: 'Fireplace' },
    { key: 'hasSeptic', label: 'Septic' },
    { key: 'hasWellWater', label: 'Well Water' },
    { key: 'hasPool', label: 'Pool' },
    { key: 'hasGenerator', label: 'Generator' },
    { key: 'hasLawn', label: 'Lawn' },
    { key: 'hasDriveway', label: 'Driveway' },
  ];

  const enabledFeatures = propertyFeatures.filter(
    (f) => homeBasics && homeBasics[f.key]
  );

  // Group bills by category type
  const billsByType = bills.reduce(
    (acc, bill) => {
      const category = bill.category;
      if (['MORTGAGE', 'HOA', 'PROPERTY_TAX'].includes(category)) {
        acc.housing.push(bill);
      } else if (['ELECTRIC', 'GAS', 'WATER_SEWER', 'TRASH', 'INTERNET', 'CABLE', 'MOBILE'].includes(category)) {
        acc.utilities.push(bill);
      } else if (category.includes('INSURANCE')) {
        acc.insurance.push(bill);
      } else if (['CREDIT_CARD', 'STUDENT_LOAN', 'PERSONAL_LOAN', 'VEHICLE_LOAN', 'HELOC'].includes(category)) {
        acc.loans.push(bill);
      } else {
        acc.services.push(bill);
      }
      return acc;
    },
    {
      housing: [] as BillEntry[],
      utilities: [] as BillEntry[],
      insurance: [] as BillEntry[],
      loans: [] as BillEntry[],
      services: [] as BillEntry[],
    }
  );

  const totalMonthlyBills = bills.reduce((sum, bill) => {
    if (!bill.typicalAmount) return sum;
    // Convert to monthly equivalent
    const frequencyMultiplier: Record<string, number> = {
      WEEKLY: 4.33,
      BIWEEKLY: 2.17,
      MONTHLY: 1,
      QUARTERLY: 0.33,
      SEMIANNUALLY: 0.167,
      ANNUAL: 0.083,
      OTHER: 1,
      PER_VISIT: 1,
      PER_JOB: 1,
    };
    return sum + bill.typicalAmount * (frequencyMultiplier[bill.billingFrequency] || 1);
  }, 0);

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-lg font-semibold text-slate-900 dark:text-white mb-1">
          Review your setup
        </h2>
        <p className="text-sm text-slate-600 dark:text-slate-400">
          Everything looks good? Let&apos;s get you started with Haven!
        </p>
      </div>

      {/* Property Info */}
      <div className="p-4 bg-slate-50 dark:bg-slate-800 rounded-lg">
        <div className="flex items-center justify-between mb-3">
          <h3 className="font-medium text-slate-900 dark:text-white flex items-center gap-2">
            <span className="text-lg">🏠</span>
            Property
          </h3>
          <button
            type="button"
            onClick={() => onEditStep(1)}
            className="text-sm text-emerald-600 hover:text-emerald-700 dark:text-emerald-400 dark:hover:text-emerald-300"
          >
            Edit
          </button>
        </div>

        {homeBasics ? (
          <div className="space-y-2 text-sm">
            <p className="font-medium text-slate-900 dark:text-white">{homeBasics.name}</p>
            <p className="text-slate-600 dark:text-slate-400">
              {homeBasics.addressLine1}
              {homeBasics.addressLine2 && `, ${homeBasics.addressLine2}`}
              <br />
              {homeBasics.city}, {homeBasics.state} {homeBasics.postalCode}
            </p>
            <div className="flex flex-wrap gap-x-4 gap-y-1 text-slate-500 dark:text-slate-400">
              {homeBasics.squareFeet && <span>{homeBasics.squareFeet.toLocaleString()} sq ft</span>}
              {homeBasics.bedrooms && <span>{homeBasics.bedrooms} bed</span>}
              {homeBasics.bathrooms && <span>{homeBasics.bathrooms} bath</span>}
              {homeBasics.yearBuilt && <span>Built {homeBasics.yearBuilt}</span>}
            </div>
            {enabledFeatures.length > 0 && (
              <div className="flex flex-wrap gap-2 mt-2">
                {enabledFeatures.map((f) => (
                  <span
                    key={f.key}
                    className="px-2 py-1 text-xs bg-slate-200 dark:bg-slate-700 text-slate-600 dark:text-slate-400 rounded-full"
                  >
                    {f.label}
                  </span>
                ))}
              </div>
            )}
          </div>
        ) : (
          <p className="text-sm text-slate-500 dark:text-slate-400">No property information</p>
        )}
      </div>

      {/* Bills Summary */}
      <div className="p-4 bg-slate-50 dark:bg-slate-800 rounded-lg">
        <div className="flex items-center justify-between mb-3">
          <h3 className="font-medium text-slate-900 dark:text-white flex items-center gap-2">
            <span className="text-lg">💳</span>
            Bills ({bills.length})
          </h3>
          <button
            type="button"
            onClick={() => onEditStep(2)}
            className="text-sm text-emerald-600 hover:text-emerald-700 dark:text-emerald-400 dark:hover:text-emerald-300"
          >
            Edit
          </button>
        </div>

        {bills.length > 0 ? (
          <div className="space-y-3">
            {Object.entries(billsByType).map(([type, typeBills]) => {
              if (typeBills.length === 0) return null;
              const typeLabels: Record<string, string> = {
                housing: 'Housing',
                utilities: 'Utilities',
                insurance: 'Insurance',
                loans: 'Loans',
                services: 'Services',
              };
              return (
                <div key={type}>
                  <p className="text-xs font-medium text-slate-500 dark:text-slate-400 uppercase mb-1">
                    {typeLabels[type]}
                  </p>
                  <div className="flex flex-wrap gap-2">
                    {typeBills.map((bill) => (
                      <span
                        key={bill.category}
                        className="px-2 py-1 text-xs bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-300 rounded-full"
                      >
                        {bill.vendorName || BILL_CATEGORY_LABELS[bill.category]}
                      </span>
                    ))}
                  </div>
                </div>
              );
            })}

            <div className="pt-2 border-t border-slate-200 dark:border-slate-700">
              <p className="text-sm text-slate-600 dark:text-slate-400">
                Est. monthly total:{' '}
                <span className="font-medium text-slate-900 dark:text-white">
                  ${totalMonthlyBills.toFixed(2)}
                </span>
              </p>
            </div>
          </div>
        ) : (
          <p className="text-sm text-slate-500 dark:text-slate-400">No bills added</p>
        )}
      </div>

      {/* Maintenance Summary */}
      <div className="p-4 bg-slate-50 dark:bg-slate-800 rounded-lg">
        <div className="flex items-center justify-between mb-3">
          <h3 className="font-medium text-slate-900 dark:text-white flex items-center gap-2">
            <span className="text-lg">🔧</span>
            Maintenance Tasks
          </h3>
          <button
            type="button"
            onClick={() => onEditStep(3)}
            className="text-sm text-emerald-600 hover:text-emerald-700 dark:text-emerald-400 dark:hover:text-emerald-300"
          >
            Edit
          </button>
        </div>

        <p className="text-sm text-slate-600 dark:text-slate-400">
          <span className="font-medium text-slate-900 dark:text-white">{maintenanceTaskCount}</span>{' '}
          maintenance task{maintenanceTaskCount !== 1 ? 's' : ''} scheduled for the first 12 months
        </p>
      </div>

      {/* Subscription Summary */}
      <div className="p-4 bg-slate-50 dark:bg-slate-800 rounded-lg">
        <div className="flex items-center justify-between mb-3">
          <h3 className="font-medium text-slate-900 dark:text-white flex items-center gap-2">
            <span className="text-lg">⭐</span>
            Subscription
          </h3>
          <button
            type="button"
            onClick={() => onEditStep(4)}
            className="text-sm text-emerald-600 hover:text-emerald-700 dark:text-emerald-400 dark:hover:text-emerald-300"
          >
            Edit
          </button>
        </div>

        {selectedPlan ? (
          <div className="flex items-center justify-between">
            <div>
              <p className="font-medium text-slate-900 dark:text-white">
                {SUBSCRIPTION_PLANS[selectedPlan].name} Plan
              </p>
              <p className="text-sm text-slate-500 dark:text-slate-400">
                {SUBSCRIPTION_PLANS[selectedPlan].features.length} features included
              </p>
            </div>
            <p className="text-lg font-bold text-slate-900 dark:text-white">
              ${SUBSCRIPTION_PLANS[selectedPlan].price}
              <span className="text-sm font-normal text-slate-500">/mo</span>
            </p>
          </div>
        ) : (
          <p className="text-sm text-slate-500 dark:text-slate-400">No plan selected</p>
        )}
      </div>

      {/* Confirmation Message */}
      <div className="p-4 bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg">
        <div className="flex items-start gap-3">
          <svg
            className="w-5 h-5 text-green-600 dark:text-green-400 mt-0.5"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
            />
          </svg>
          <div>
            <p className="font-medium text-green-800 dark:text-green-200">
              You&apos;re all set!
            </p>
            <p className="text-sm text-green-700 dark:text-green-300">
              Click &quot;Confirm and finish&quot; to complete your setup and start managing your home.
            </p>
          </div>
        </div>
      </div>

      <div className="flex gap-3 pt-4">
        <button type="button" onClick={onBack} className="btn btn-secondary flex-1">
          Back
        </button>
        <button
          type="button"
          onClick={onSubmit}
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
              Completing setup...
            </>
          ) : (
            'Confirm and finish'
          )}
        </button>
      </div>
    </div>
  );
}
