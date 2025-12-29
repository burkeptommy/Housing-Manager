'use client';

import { useState, useMemo } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import {
  Receipt,
  ArrowRight,
  ArrowLeft,
  Plus,
  X,
  Check,
  ChevronDown,
  ChevronUp,
  Pencil,
  Trash2,
  Home,
  Building2,
  Users,
  Shield,
  Umbrella,
  Zap,
  Flame,
  Droplet,
  Droplets,
  Trash2 as Trash2Icon,
  Wifi,
  Tv,
  Smartphone,
  ShieldCheck,
  Trees,
  Waves,
  Sparkles,
  Bug,
  GraduationCap,
  Music,
  Tent,
  Baby,
  PawPrint,
  Car,
  CarFront,
  Dumbbell,
  CreditCard,
  MoreHorizontal,
} from 'lucide-react';
import { SkipToHumanBanner } from '@/components/onboarding/SkipToHumanBanner';
import { FormInput, FormSelect, FormCurrency, FormCheckbox } from '@/components/onboarding/forms';
import { useOnboarding } from '@/context/OnboardingContext';
import { Bill, BillCategory, BillFrequency, BILL_CATEGORIES } from '@/types/onboarding';
import { generateId } from '@/lib/id';
import { formatCurrency } from '@/lib/format';
import { cn } from '@/lib/utils';

const FREQUENCY_OPTIONS = [
  { value: 'monthly', label: 'Monthly' },
  { value: 'quarterly', label: 'Quarterly' },
  { value: 'semi_annual', label: 'Semi-Annual' },
  { value: 'annual', label: 'Annual' },
  { value: 'one_time', label: 'One-Time' },
];

// Group categories for display
const CATEGORY_GROUPS = [
  {
    name: 'Housing',
    categories: ['mortgage', 'property_tax', 'hoa', 'homeowners_insurance', 'umbrella_insurance'],
  },
  {
    name: 'Utilities',
    categories: ['electric', 'gas', 'oil', 'water_sewer', 'trash'],
  },
  {
    name: 'Telecom',
    categories: ['internet', 'cable_streaming', 'cell_phone'],
  },
  {
    name: 'Home Services',
    categories: ['security_monitoring', 'lawn_landscape', 'pool_service', 'cleaning_service', 'pest_control'],
  },
  {
    name: 'Family',
    categories: ['school_tuition', 'activities_lessons', 'camps', 'childcare_nanny', 'pet_care'],
  },
  {
    name: 'Vehicles',
    categories: ['vehicle_payment', 'vehicle_insurance'],
  },
  {
    name: 'Other',
    categories: ['gym_membership', 'subscriptions', 'other'],
  },
];

// Icon map
const ICON_MAP: Record<string, React.ComponentType<{ className?: string }>> = {
  Home,
  Building2,
  Users,
  Shield,
  Umbrella,
  Zap,
  Flame,
  Droplet,
  Droplets,
  Trash2: Trash2Icon,
  Wifi,
  Tv,
  Smartphone,
  ShieldCheck,
  Trees,
  Waves,
  Sparkles,
  Bug,
  GraduationCap,
  Music,
  Tent,
  Baby,
  PawPrint,
  Car,
  CarFront,
  Dumbbell,
  CreditCard,
  MoreHorizontal,
};

export default function BillsPage() {
  const router = useRouter();
  const { data, addBill, updateBill, removeBill, completeStep, calculateMonthlyTotal } =
    useOnboarding();

  // Modal state
  const [isAddingBill, setIsAddingBill] = useState(false);
  const [editingBill, setEditingBill] = useState<Bill | null>(null);
  const [expandedGroups, setExpandedGroups] = useState<string[]>(['Housing', 'Utilities']);

  // Form state
  const [selectedCategory, setSelectedCategory] = useState<BillCategory | null>(null);
  const [provider, setProvider] = useState('');
  const [amount, setAmount] = useState<number | undefined>();
  const [frequency, setFrequency] = useState<BillFrequency>('monthly');
  const [dueDay, setDueDay] = useState('');
  const [accountNumber, setAccountNumber] = useState('');
  const [autoPay, setAutoPay] = useState(false);
  const [notes, setNotes] = useState('');
  const [customCategory, setCustomCategory] = useState('');

  const monthlyTotal = calculateMonthlyTotal();

  const billsByGroup = useMemo(() => {
    const grouped: Record<string, Bill[]> = {};

    CATEGORY_GROUPS.forEach((group) => {
      grouped[group.name] = data.bills.filter((bill) => group.categories.includes(bill.category));
    });

    return grouped;
  }, [data.bills]);

  const toggleGroup = (groupName: string) => {
    setExpandedGroups((prev) =>
      prev.includes(groupName) ? prev.filter((g) => g !== groupName) : [...prev, groupName]
    );
  };

  const resetForm = () => {
    setSelectedCategory(null);
    setProvider('');
    setAmount(undefined);
    setFrequency('monthly');
    setDueDay('');
    setAccountNumber('');
    setAutoPay(false);
    setNotes('');
    setCustomCategory('');
  };

  const openAddModal = (category?: BillCategory) => {
    resetForm();
    if (category) setSelectedCategory(category);
    setIsAddingBill(true);
  };

  const openEditModal = (bill: Bill) => {
    setEditingBill(bill);
    setSelectedCategory(bill.category);
    setProvider(bill.provider);
    setAmount(bill.amount);
    setFrequency(bill.frequency);
    setDueDay(bill.dueDay?.toString() || '');
    setAccountNumber(bill.accountNumber || '');
    setAutoPay(bill.autoPay);
    setNotes(bill.notes || '');
    setCustomCategory(bill.customCategory || '');
    setIsAddingBill(true);
  };

  const handleSaveBill = () => {
    if (!selectedCategory || !provider.trim() || amount === undefined) return;

    const bill: Bill = {
      id: editingBill?.id || generateId(),
      category: selectedCategory,
      customCategory: selectedCategory === 'other' ? customCategory : undefined,
      provider: provider.trim(),
      amount,
      frequency,
      dueDay: dueDay ? parseInt(dueDay) : undefined,
      accountNumber: accountNumber || undefined,
      autoPay,
      notes: notes || undefined,
    };

    if (editingBill) {
      updateBill(bill);
    } else {
      addBill(bill);
    }

    setIsAddingBill(false);
    setEditingBill(null);
    resetForm();
  };

  const handleDeleteBill = (id: string) => {
    if (confirm('Are you sure you want to remove this bill?')) {
      removeBill(id);
    }
  };

  const handleContinue = () => {
    completeStep('bills');
    router.push('/onboarding/wizard/bank');
  };

  const getIcon = (iconName: string) => {
    const Icon = ICON_MAP[iconName];
    return Icon ? <Icon className="w-5 h-5" /> : null;
  };

  return (
    <div className="max-w-2xl mx-auto px-4 py-8">
      <SkipToHumanBanner />

      {/* Header */}
      <div className="text-center mb-8">
        <div className="w-14 h-14 bg-haven-champagne-100 rounded-2xl flex items-center justify-center mx-auto mb-4">
          <Receipt className="w-7 h-7 text-haven-champagne-600" />
        </div>
        <h1 className="text-2xl font-bold text-haven-navy-900 mb-2">Your bills & accounts</h1>
        <p className="text-gray-600">
          Tell us about your recurring bills so we can manage payments for you.
        </p>
      </div>

      {/* Monthly Total Summary */}
      {data.bills.length > 0 && (
        <div className="bg-haven-navy-900 text-white rounded-2xl p-6 mb-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-white/70 text-sm">Estimated Monthly Total</p>
              <p className="text-3xl font-bold mt-1">{formatCurrency(monthlyTotal)}</p>
            </div>
            <div className="text-right">
              <p className="text-white/70 text-sm">{data.bills.length} bills added</p>
            </div>
          </div>
        </div>
      )}

      {/* Bill Categories */}
      <div className="space-y-4">
        {CATEGORY_GROUPS.map((group) => {
          const groupBills = billsByGroup[group.name];
          const isExpanded = expandedGroups.includes(group.name);
          const hasEntries = groupBills.length > 0;

          return (
            <div
              key={group.name}
              className="bg-white rounded-2xl border border-gray-200 overflow-hidden"
            >
              {/* Group Header */}
              <button
                onClick={() => toggleGroup(group.name)}
                className="w-full px-6 py-4 flex items-center justify-between hover:bg-gray-50 transition-colors"
              >
                <div className="flex items-center gap-3">
                  <h3 className="font-semibold text-haven-navy-900">{group.name}</h3>
                  {hasEntries && (
                    <span className="bg-haven-champagne-100 text-haven-champagne-700 text-xs font-medium px-2 py-0.5 rounded-full">
                      {groupBills.length}
                    </span>
                  )}
                </div>
                {isExpanded ? (
                  <ChevronUp className="w-5 h-5 text-gray-400" />
                ) : (
                  <ChevronDown className="w-5 h-5 text-gray-400" />
                )}
              </button>

              {/* Group Content */}
              {isExpanded && (
                <div className="px-6 pb-6 space-y-3">
                  {/* Existing bills in this group */}
                  {groupBills.map((bill) => {
                    const catInfo = BILL_CATEGORIES[bill.category];
                    return (
                      <div
                        key={bill.id}
                        className="flex items-center gap-4 p-4 bg-gray-50 rounded-xl group"
                      >
                        <div className="w-10 h-10 bg-white rounded-lg flex items-center justify-center text-gray-600">
                          {getIcon(catInfo.icon)}
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="font-medium text-haven-navy-900">{bill.provider}</p>
                          <p className="text-sm text-gray-500">
                            {catInfo.label} • {formatCurrency(bill.amount)}/{bill.frequency}
                          </p>
                        </div>
                        <div className="flex items-center gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                          <button
                            onClick={() => openEditModal(bill)}
                            className="p-2 text-gray-400 hover:text-haven-navy-900 hover:bg-white rounded-lg"
                          >
                            <Pencil className="w-4 h-4" />
                          </button>
                          <button
                            onClick={() => handleDeleteBill(bill.id)}
                            className="p-2 text-gray-400 hover:text-red-500 hover:bg-white rounded-lg"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </div>
                      </div>
                    );
                  })}

                  {/* Quick-add buttons for categories in this group */}
                  <div className="flex flex-wrap gap-2 pt-2">
                    {group.categories.map((catKey) => {
                      const cat = BILL_CATEGORIES[catKey as BillCategory];
                      const hasEntry = data.bills.some((b) => b.category === catKey);

                      return (
                        <button
                          key={catKey}
                          onClick={() => openAddModal(catKey as BillCategory)}
                          className={cn(
                            'inline-flex items-center gap-2 px-3 py-2 rounded-lg text-sm font-medium transition-colors',
                            hasEntry
                              ? 'bg-green-50 text-green-700 hover:bg-green-100'
                              : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                          )}
                        >
                          {hasEntry && <Check className="w-3 h-3" />}
                          <Plus className={cn('w-3 h-3', hasEntry && 'hidden')} />
                          {cat.label}
                        </button>
                      );
                    })}
                  </div>
                </div>
              )}
            </div>
          );
        })}
      </div>

      {/* Add Bill Button */}
      <button
        onClick={() => openAddModal()}
        className="w-full mt-6 py-4 px-6 border-2 border-dashed border-gray-200 rounded-2xl text-gray-500 hover:border-haven-champagne-500 hover:text-haven-champagne-600 transition-colors flex items-center justify-center gap-2"
      >
        <Plus className="w-5 h-5" />
        Add another bill
      </button>

      {/* Navigation */}
      <div className="flex justify-between mt-8">
        <Link
          href="/onboarding/wizard/property"
          className="text-gray-600 hover:text-haven-navy-900 py-3 px-4 font-medium flex items-center gap-2 transition-colors"
        >
          <ArrowLeft className="w-4 h-4" />
          Back
        </Link>
        <button
          onClick={handleContinue}
          className="bg-haven-navy-900 hover:bg-haven-navy-800 text-white py-3 px-6 rounded-xl font-medium flex items-center gap-2 transition-colors"
        >
          Continue
          <ArrowRight className="w-4 h-4" />
        </button>
      </div>

      {/* Add/Edit Bill Modal */}
      {isAddingBill && (
        <div className="fixed inset-0 bg-black/50 flex items-end sm:items-center justify-center z-50 p-4">
          <div className="bg-white rounded-t-2xl sm:rounded-2xl w-full max-w-lg max-h-[90vh] overflow-y-auto">
            {/* Modal Header */}
            <div className="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between">
              <h2 className="text-lg font-semibold text-haven-navy-900">
                {editingBill ? 'Edit Bill' : 'Add Bill'}
              </h2>
              <button
                onClick={() => {
                  setIsAddingBill(false);
                  setEditingBill(null);
                  resetForm();
                }}
                className="text-gray-400 hover:text-gray-600"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Modal Content */}
            <div className="p-6 space-y-6">
              {/* Category Selection */}
              {!selectedCategory && (
                <div className="space-y-3">
                  <label className="block text-sm font-medium text-gray-700">
                    What type of bill is this?
                  </label>
                  <div className="grid grid-cols-2 gap-2 max-h-64 overflow-y-auto">
                    {Object.entries(BILL_CATEGORIES).map(([key, cat]) => (
                      <button
                        key={key}
                        onClick={() => setSelectedCategory(key as BillCategory)}
                        className="flex items-center gap-2 p-3 rounded-xl border border-gray-200 hover:border-haven-champagne-500 hover:bg-haven-champagne-50 text-left transition-colors"
                      >
                        <span className="text-gray-500">{getIcon(cat.icon)}</span>
                        <span className="text-sm font-medium text-haven-navy-900">{cat.label}</span>
                      </button>
                    ))}
                  </div>
                </div>
              )}

              {/* Bill Details Form */}
              {selectedCategory && (
                <>
                  {/* Selected Category Indicator */}
                  <div className="flex items-center gap-3 p-3 bg-haven-champagne-50 rounded-xl">
                    <div className="w-10 h-10 bg-haven-champagne-100 rounded-lg flex items-center justify-center text-haven-champagne-600">
                      {getIcon(BILL_CATEGORIES[selectedCategory].icon)}
                    </div>
                    <div className="flex-1">
                      <p className="font-medium text-haven-navy-900">
                        {BILL_CATEGORIES[selectedCategory].label}
                      </p>
                    </div>
                    {!editingBill && (
                      <button
                        onClick={() => setSelectedCategory(null)}
                        className="text-sm text-haven-champagne-600 hover:text-haven-champagne-700"
                      >
                        Change
                      </button>
                    )}
                  </div>

                  {/* Custom category name for "Other" */}
                  {selectedCategory === 'other' && (
                    <FormInput
                      label="Category Name"
                      placeholder="e.g., Storage Unit"
                      value={customCategory}
                      onChange={(e) => setCustomCategory(e.target.value)}
                      required
                    />
                  )}

                  <FormInput
                    label="Provider / Company"
                    placeholder="e.g., Eversource, Optimum"
                    value={provider}
                    onChange={(e) => setProvider(e.target.value)}
                    required
                  />

                  <div className="grid grid-cols-2 gap-4">
                    <FormCurrency
                      label="Amount"
                      placeholder="150.00"
                      value={amount}
                      onChange={setAmount}
                      required
                    />
                    <FormSelect
                      label="Frequency"
                      options={FREQUENCY_OPTIONS}
                      value={frequency}
                      onChange={(e) => setFrequency(e.target.value as BillFrequency)}
                    />
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <FormInput
                      label="Due Day (optional)"
                      type="number"
                      placeholder="15"
                      value={dueDay}
                      onChange={(e) => setDueDay(e.target.value)}
                      min={1}
                      max={31}
                      hint="Day of month"
                    />
                    <FormInput
                      label="Account # (optional)"
                      placeholder="****1234"
                      value={accountNumber}
                      onChange={(e) => setAccountNumber(e.target.value)}
                    />
                  </div>

                  <FormCheckbox
                    label="Auto-pay is enabled"
                    description="This bill is set to auto-pay from my bank/card"
                    checked={autoPay}
                    onChange={(e) => setAutoPay(e.target.checked)}
                  />

                  <FormInput
                    label="Notes (optional)"
                    placeholder="Any additional details..."
                    value={notes}
                    onChange={(e) => setNotes(e.target.value)}
                  />
                </>
              )}
            </div>

            {/* Modal Footer */}
            {selectedCategory && (
              <div className="sticky bottom-0 bg-white border-t border-gray-200 px-6 py-4 flex gap-3">
                <button
                  onClick={() => {
                    setIsAddingBill(false);
                    setEditingBill(null);
                    resetForm();
                  }}
                  className="flex-1 py-3 px-4 border border-gray-200 rounded-xl font-medium text-gray-700 hover:bg-gray-50 transition-colors"
                >
                  Cancel
                </button>
                <button
                  onClick={handleSaveBill}
                  disabled={!provider.trim() || amount === undefined}
                  className="flex-1 py-3 px-4 bg-haven-navy-900 text-white rounded-xl font-medium hover:bg-haven-navy-800 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {editingBill ? 'Save Changes' : 'Add Bill'}
                </button>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
