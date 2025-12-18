'use client';

import { useState, useCallback } from 'react';
import type { VendorCategory, BillingFrequency, PaymentResponsibility } from '@haven/core';

// Bill category groups
const BILL_CATEGORIES = {
  housing: {
    label: 'Housing',
    icon: '🏠',
    items: [
      { category: 'MORTGAGE' as VendorCategory, label: 'Mortgage', defaultVendor: '' },
      { category: 'HOA' as VendorCategory, label: 'HOA Fees', defaultVendor: '' },
      { category: 'PROPERTY_TAX' as VendorCategory, label: 'Property Tax', defaultVendor: '' },
    ],
  },
  utilities: {
    label: 'Utilities',
    icon: '⚡',
    items: [
      { category: 'ELECTRIC' as VendorCategory, label: 'Electric', defaultVendor: '' },
      { category: 'GAS' as VendorCategory, label: 'Gas', defaultVendor: '' },
      { category: 'WATER_SEWER' as VendorCategory, label: 'Water & Sewer', defaultVendor: '' },
      { category: 'TRASH' as VendorCategory, label: 'Trash', defaultVendor: '' },
      { category: 'INTERNET' as VendorCategory, label: 'Internet', defaultVendor: '' },
      { category: 'CABLE' as VendorCategory, label: 'Cable/TV', defaultVendor: '' },
      { category: 'MOBILE' as VendorCategory, label: 'Mobile Phone', defaultVendor: '' },
    ],
  },
  insurance: {
    label: 'Insurance',
    icon: '🛡️',
    items: [
      { category: 'HOME_INSURANCE' as VendorCategory, label: 'Home Insurance', defaultVendor: '' },
      { category: 'AUTO_INSURANCE' as VendorCategory, label: 'Auto Insurance', defaultVendor: '' },
      { category: 'HEALTH_INSURANCE' as VendorCategory, label: 'Health Insurance', defaultVendor: '' },
      { category: 'LIFE_INSURANCE' as VendorCategory, label: 'Life Insurance', defaultVendor: '' },
      { category: 'PET_INSURANCE' as VendorCategory, label: 'Pet Insurance', defaultVendor: '' },
    ],
  },
  loans: {
    label: 'Loans & Debt',
    icon: '💳',
    items: [
      { category: 'CREDIT_CARD' as VendorCategory, label: 'Credit Card', defaultVendor: '' },
      { category: 'STUDENT_LOAN' as VendorCategory, label: 'Student Loans', defaultVendor: '' },
      { category: 'VEHICLE_LOAN' as VendorCategory, label: 'Vehicle Loan', defaultVendor: '' },
      { category: 'PERSONAL_LOAN' as VendorCategory, label: 'Personal Loan', defaultVendor: '' },
      { category: 'HELOC' as VendorCategory, label: 'HELOC', defaultVendor: '' },
    ],
  },
  services: {
    label: 'Services & Subscriptions',
    icon: '📦',
    items: [
      { category: 'SECURITY_MONITORING' as VendorCategory, label: 'Security Monitoring', defaultVendor: '' },
      { category: 'PEST_CONTROL' as VendorCategory, label: 'Pest Control', defaultVendor: '' },
      { category: 'LAWN_CARE' as VendorCategory, label: 'Lawn Care', defaultVendor: '' },
      { category: 'LANDSCAPING' as VendorCategory, label: 'Landscaping', defaultVendor: '' },
      { category: 'HOME_WARRANTY' as VendorCategory, label: 'Home Warranty', defaultVendor: '' },
      { category: 'CLEANING' as VendorCategory, label: 'Cleaning Service', defaultVendor: '' },
      { category: 'GYM' as VendorCategory, label: 'Gym/Fitness', defaultVendor: '' },
      { category: 'STREAMING' as VendorCategory, label: 'Streaming Services', defaultVendor: '' },
    ],
  },
};

const BILLING_FREQUENCIES: { value: BillingFrequency; label: string }[] = [
  { value: 'WEEKLY', label: 'Weekly' },
  { value: 'BIWEEKLY', label: 'Bi-weekly' },
  { value: 'MONTHLY', label: 'Monthly' },
  { value: 'QUARTERLY', label: 'Quarterly' },
  { value: 'SEMIANNUALLY', label: 'Semi-annually' },
  { value: 'ANNUAL', label: 'Annually' },
  { value: 'OTHER', label: 'Other' },
];

const PAYMENT_RESPONSIBILITIES: { value: PaymentResponsibility; label: string; description: string }[] = [
  {
    value: 'VENDOR_AUTOPAY',
    label: 'Autopay is set up',
    description: 'Just track and remind me',
  },
  {
    value: 'OWNER_PAYS_DIRECT',
    label: 'I pay manually',
    description: 'Remind me when due',
  },
  {
    value: 'HAVEN_PAYS_ON_BEHALF',
    label: 'Haven handles payment',
    description: 'Roll into my monthly bill',
  },
];

export interface BillEntry {
  category: VendorCategory;
  vendorName: string;
  accountNumber: string;
  typicalAmount: number | null;
  billingFrequency: BillingFrequency;
  nextDueDate: string;
  paymentResponsibility: PaymentResponsibility;
}

interface StepRecurringBillsProps {
  onSubmit: (bills: BillEntry[]) => void;
  onBack: () => void;
  defaultValues?: BillEntry[];
  isSubmitting?: boolean;
}

export function StepRecurringBills({
  onSubmit,
  onBack,
  defaultValues = [],
  isSubmitting,
}: StepRecurringBillsProps) {
  const [expandedCategories, setExpandedCategories] = useState<Set<string>>(new Set(['utilities']));
  const [enabledBills, setEnabledBills] = useState<Set<VendorCategory>>(() => {
    const set = new Set<VendorCategory>();
    defaultValues.forEach((bill) => set.add(bill.category));
    return set;
  });
  const [billData, setBillData] = useState<Map<VendorCategory, BillEntry>>(() => {
    const map = new Map<VendorCategory, BillEntry>();
    defaultValues.forEach((bill) => map.set(bill.category, bill));
    return map;
  });

  const toggleCategory = useCallback((categoryKey: string) => {
    setExpandedCategories((prev) => {
      const next = new Set(prev);
      if (next.has(categoryKey)) {
        next.delete(categoryKey);
      } else {
        next.add(categoryKey);
      }
      return next;
    });
  }, []);

  const toggleBill = useCallback((category: VendorCategory) => {
    setEnabledBills((prev) => {
      const next = new Set(prev);
      if (next.has(category)) {
        next.delete(category);
      } else {
        next.add(category);
      }
      return next;
    });
  }, []);

  const updateBillData = useCallback((category: VendorCategory, field: keyof BillEntry, value: string | number | null) => {
    setBillData((prev) => {
      const next = new Map(prev);
      const existing = next.get(category) || {
        category,
        vendorName: '',
        accountNumber: '',
        typicalAmount: null,
        billingFrequency: 'MONTHLY' as BillingFrequency,
        nextDueDate: '',
        paymentResponsibility: 'OWNER_PAYS_DIRECT' as PaymentResponsibility,
      };
      next.set(category, { ...existing, [field]: value });
      return next;
    });
  }, []);

  const handleSubmit = useCallback(() => {
    const bills: BillEntry[] = [];
    enabledBills.forEach((category) => {
      const data = billData.get(category);
      if (data && data.vendorName.trim()) {
        bills.push(data);
      }
    });
    onSubmit(bills);
  }, [enabledBills, billData, onSubmit]);

  const getBillData = (category: VendorCategory): BillEntry => {
    return billData.get(category) || {
      category,
      vendorName: '',
      accountNumber: '',
      typicalAmount: null,
      billingFrequency: 'MONTHLY',
      nextDueDate: '',
      paymentResponsibility: 'OWNER_PAYS_DIRECT',
    };
  };

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-lg font-semibold text-slate-900 dark:text-white mb-1">
          Your recurring bills
        </h2>
        <p className="text-sm text-slate-600 dark:text-slate-400">
          Tell us about your recurring bills so we can help you track and manage them.
          You can skip any categories that don&apos;t apply.
        </p>
      </div>

      <div className="space-y-4">
        {Object.entries(BILL_CATEGORIES).map(([key, group]) => (
          <div
            key={key}
            className="border border-slate-200 dark:border-slate-700 rounded-lg overflow-hidden"
          >
            {/* Category Header */}
            <button
              type="button"
              onClick={() => toggleCategory(key)}
              className="w-full flex items-center justify-between p-4 bg-slate-50 dark:bg-slate-800 hover:bg-slate-100 dark:hover:bg-slate-700 transition-colors"
            >
              <div className="flex items-center gap-3">
                <span className="text-xl">{group.icon}</span>
                <span className="font-medium text-slate-900 dark:text-white">{group.label}</span>
                <span className="text-xs text-slate-500 dark:text-slate-400">
                  ({Array.from(enabledBills).filter((cat) =>
                    group.items.some((item) => item.category === cat)
                  ).length} selected)
                </span>
              </div>
              <svg
                className={`w-5 h-5 text-slate-400 transition-transform ${
                  expandedCategories.has(key) ? 'rotate-180' : ''
                }`}
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
              </svg>
            </button>

            {/* Category Items */}
            {expandedCategories.has(key) && (
              <div className="p-4 space-y-4">
                {group.items.map((item) => {
                  const isEnabled = enabledBills.has(item.category);
                  const data = getBillData(item.category);

                  return (
                    <div key={item.category} className="space-y-3">
                      {/* Bill Toggle */}
                      <label className="flex items-center gap-3 cursor-pointer">
                        <input
                          type="checkbox"
                          checked={isEnabled}
                          onChange={() => toggleBill(item.category)}
                          className="w-4 h-4 text-emerald-600 rounded border-slate-300 dark:border-slate-600"
                        />
                        <span className="text-sm font-medium text-slate-700 dark:text-slate-300">
                          {item.label}
                        </span>
                      </label>

                      {/* Bill Details Form */}
                      {isEnabled && (
                        <div className="ml-7 p-4 bg-slate-50 dark:bg-slate-800/50 rounded-lg space-y-4">
                          <div className="grid grid-cols-2 gap-4">
                            <div>
                              <label className="label block mb-1.5 text-xs">Vendor name</label>
                              <input
                                type="text"
                                value={data.vendorName}
                                onChange={(e) => updateBillData(item.category, 'vendorName', e.target.value)}
                                className="input text-sm"
                                placeholder="e.g., Duke Energy"
                              />
                            </div>
                            <div>
                              <label className="label block mb-1.5 text-xs">Account # (optional)</label>
                              <input
                                type="text"
                                value={data.accountNumber}
                                onChange={(e) => updateBillData(item.category, 'accountNumber', e.target.value)}
                                className="input text-sm"
                                placeholder="Account number"
                              />
                            </div>
                          </div>

                          <div className="grid grid-cols-3 gap-4">
                            <div>
                              <label className="label block mb-1.5 text-xs">Typical amount</label>
                              <div className="relative">
                                <span className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 text-sm">$</span>
                                <input
                                  type="number"
                                  value={data.typicalAmount || ''}
                                  onChange={(e) => updateBillData(item.category, 'typicalAmount', e.target.value ? parseFloat(e.target.value) : null)}
                                  className="input text-sm pl-7"
                                  placeholder="0.00"
                                />
                              </div>
                            </div>
                            <div>
                              <label className="label block mb-1.5 text-xs">Frequency</label>
                              <select
                                value={data.billingFrequency}
                                onChange={(e) => updateBillData(item.category, 'billingFrequency', e.target.value)}
                                className="input text-sm"
                              >
                                {BILLING_FREQUENCIES.map((freq) => (
                                  <option key={freq.value} value={freq.value}>
                                    {freq.label}
                                  </option>
                                ))}
                              </select>
                            </div>
                            <div>
                              <label className="label block mb-1.5 text-xs">Next due date</label>
                              <input
                                type="date"
                                value={data.nextDueDate}
                                onChange={(e) => updateBillData(item.category, 'nextDueDate', e.target.value)}
                                className="input text-sm"
                              />
                            </div>
                          </div>

                          <div>
                            <label className="label block mb-2 text-xs">How is this paid?</label>
                            <div className="space-y-2">
                              {PAYMENT_RESPONSIBILITIES.map((option) => (
                                <label
                                  key={option.value}
                                  className={`flex items-start gap-3 p-3 rounded-lg border cursor-pointer transition-colors ${
                                    data.paymentResponsibility === option.value
                                      ? 'border-emerald-500 bg-emerald-50 dark:bg-emerald-900/20'
                                      : 'border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800'
                                  }`}
                                >
                                  <input
                                    type="radio"
                                    name={`payment-${item.category}`}
                                    value={option.value}
                                    checked={data.paymentResponsibility === option.value}
                                    onChange={(e) => updateBillData(item.category, 'paymentResponsibility', e.target.value as PaymentResponsibility)}
                                    className="mt-0.5"
                                  />
                                  <div>
                                    <span className="text-sm font-medium text-slate-700 dark:text-slate-300">
                                      {option.label}
                                    </span>
                                    <p className="text-xs text-slate-500 dark:text-slate-400">
                                      {option.description}
                                    </p>
                                  </div>
                                </label>
                              ))}
                            </div>
                          </div>
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        ))}
      </div>

      {/* Summary */}
      <div className="p-4 bg-emerald-50 dark:bg-emerald-900/20 rounded-lg">
        <p className="text-sm text-emerald-800 dark:text-emerald-200">
          <strong>{enabledBills.size}</strong> bill{enabledBills.size !== 1 ? 's' : ''} selected.
          You can always add more later from your dashboard.
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
