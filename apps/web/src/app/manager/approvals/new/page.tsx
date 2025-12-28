'use client';

import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '@/contexts/auth-context';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import {
  ArrowLeft,
  DollarSign,
  Calendar,
  Wrench,
  Truck,
  FileText,
  AlertCircle,
  CheckCircle2,
  Home,
} from 'lucide-react';

// ============================================================================
// TYPES
// ============================================================================

type ApprovalType = 'EXPENSE' | 'VENDOR_SELECTION' | 'SCHEDULE' | 'PROJECT' | 'OTHER';
type ApprovalPriority = 'LOW' | 'MEDIUM' | 'HIGH' | 'URGENT';

interface Household {
  id: string;
  name: string;
  address?: {
    full?: string;
  };
}

// ============================================================================
// COMPONENTS
// ============================================================================

function TypeCard({
  type,
  icon: Icon,
  label,
  description,
  selected,
  onClick,
}: {
  type: ApprovalType;
  icon: React.ElementType;
  label: string;
  description: string;
  selected: boolean;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`p-4 rounded-xl border-2 text-left transition-all ${
        selected
          ? 'border-emerald-500 bg-emerald-50'
          : 'border-gray-200 hover:border-gray-300'
      }`}
    >
      <div className={`w-10 h-10 rounded-lg flex items-center justify-center mb-3 ${
        selected ? 'bg-emerald-100' : 'bg-gray-100'
      }`}>
        <Icon className={`w-5 h-5 ${selected ? 'text-emerald-600' : 'text-gray-600'}`} />
      </div>
      <div className="font-medium text-gray-900">{label}</div>
      <div className="text-sm text-gray-500 mt-1">{description}</div>
    </button>
  );
}

function PriorityButton({
  priority,
  label,
  selected,
  onClick,
  color,
}: {
  priority: ApprovalPriority;
  label: string;
  selected: boolean;
  onClick: () => void;
  color: string;
}) {
  const colorClasses = {
    gray: selected ? 'bg-gray-600 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200',
    blue: selected ? 'bg-blue-600 text-white' : 'bg-blue-50 text-blue-700 hover:bg-blue-100',
    orange: selected ? 'bg-orange-600 text-white' : 'bg-orange-50 text-orange-700 hover:bg-orange-100',
    red: selected ? 'bg-red-600 text-white' : 'bg-red-50 text-red-700 hover:bg-red-100',
  };

  return (
    <button
      type="button"
      onClick={onClick}
      className={`flex-1 px-4 py-2.5 rounded-lg font-medium transition-colors ${colorClasses[color as keyof typeof colorClasses]}`}
    >
      {label}
    </button>
  );
}

// ============================================================================
// MAIN PAGE
// ============================================================================

export default function NewApprovalPage() {
  const { token } = useAuth();
  const router = useRouter();

  const [households, setHouseholds] = useState<Household[]>([]);
  const [isLoadingHouseholds, setIsLoadingHouseholds] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Form state
  const [householdId, setHouseholdId] = useState('');
  const [type, setType] = useState<ApprovalType>('EXPENSE');
  const [priority, setPriority] = useState<ApprovalPriority>('MEDIUM');
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [amount, setAmount] = useState('');
  const [vendorName, setVendorName] = useState('');

  const apiUrl = process.env.NEXT_PUBLIC_API_URL || '';

  // Fetch manager's households
  const fetchHouseholds = useCallback(async () => {
    if (!token) return;

    try {
      setIsLoadingHouseholds(true);
      const response = await fetch(`${apiUrl}/manager/households`, {
        headers: { Authorization: `Bearer ${token}` },
      });

      if (!response.ok) throw new Error('Failed to fetch households');

      const data = await response.json();
      setHouseholds(data);

      // Auto-select if only one household
      if (data.length === 1) {
        setHouseholdId(data[0].id);
      }
    } catch (err) {
      console.error('Failed to fetch households:', err);
    } finally {
      setIsLoadingHouseholds(false);
    }
  }, [token, apiUrl]);

  useEffect(() => {
    fetchHouseholds();
  }, [fetchHouseholds]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!householdId) {
      setError('Please select a household');
      return;
    }

    if (!title.trim()) {
      setError('Please enter a title');
      return;
    }

    try {
      setIsSubmitting(true);
      setError(null);

      const payload = {
        householdId,
        type,
        priority,
        title: title.trim(),
        description: description.trim() || undefined,
        amount: amount ? parseFloat(amount) : undefined,
        vendorName: vendorName.trim() || undefined,
      };

      const response = await fetch(`${apiUrl}/approvals`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
      });

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.message || 'Failed to create approval request');
      }

      router.push('/manager/approvals');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create approval request');
    } finally {
      setIsSubmitting(false);
    }
  };

  const showAmountField = type === 'EXPENSE' || type === 'PROJECT';
  const showVendorField = type === 'EXPENSE' || type === 'VENDOR_SELECTION';

  return (
    <div className="min-h-screen bg-gray-50 pb-8">
      {/* Header */}
      <div className="bg-white border-b border-gray-200">
        <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <Link
            href="/manager/approvals"
            className="inline-flex items-center gap-2 text-gray-600 hover:text-gray-900 mb-4"
          >
            <ArrowLeft className="w-4 h-4" />
            Back to Approvals
          </Link>
          <h1 className="text-2xl font-bold text-gray-900">Request Approval</h1>
          <p className="text-gray-600 mt-1">
            Submit a request for homeowner approval on expenses or decisions
          </p>
        </div>
      </div>

      {/* Form */}
      <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        <form onSubmit={handleSubmit} className="space-y-6">
          {/* Error Message */}
          {error && (
            <div className="p-4 bg-red-50 border border-red-200 rounded-xl flex items-start gap-3">
              <AlertCircle className="w-5 h-5 text-red-600 flex-shrink-0 mt-0.5" />
              <div className="text-sm text-red-700">{error}</div>
            </div>
          )}

          {/* Household Selection */}
          <div className="bg-white rounded-xl border border-gray-200 p-6">
            <label className="block text-sm font-medium text-gray-700 mb-3">
              Select Household *
            </label>
            {isLoadingHouseholds ? (
              <div className="flex items-center gap-3 text-gray-500">
                <div className="w-5 h-5 border-2 border-emerald-600 border-t-transparent rounded-full animate-spin" />
                Loading households...
              </div>
            ) : households.length === 0 ? (
              <div className="text-gray-500">No households assigned to you.</div>
            ) : (
              <div className="space-y-2">
                {households.map((household) => (
                  <button
                    key={household.id}
                    type="button"
                    onClick={() => setHouseholdId(household.id)}
                    className={`w-full p-4 rounded-xl border-2 text-left transition-all flex items-center gap-3 ${
                      householdId === household.id
                        ? 'border-emerald-500 bg-emerald-50'
                        : 'border-gray-200 hover:border-gray-300'
                    }`}
                  >
                    <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${
                      householdId === household.id ? 'bg-emerald-100' : 'bg-gray-100'
                    }`}>
                      <Home className={`w-5 h-5 ${householdId === household.id ? 'text-emerald-600' : 'text-gray-600'}`} />
                    </div>
                    <div>
                      <div className="font-medium text-gray-900">{household.name}</div>
                      {household.address?.full && (
                        <div className="text-sm text-gray-500">{household.address.full}</div>
                      )}
                    </div>
                    {householdId === household.id && (
                      <CheckCircle2 className="w-5 h-5 text-emerald-600 ml-auto" />
                    )}
                  </button>
                ))}
              </div>
            )}
          </div>

          {/* Approval Type */}
          <div className="bg-white rounded-xl border border-gray-200 p-6">
            <label className="block text-sm font-medium text-gray-700 mb-3">
              What type of approval do you need?
            </label>
            <div className="grid grid-cols-2 lg:grid-cols-3 gap-3">
              <TypeCard
                type="EXPENSE"
                icon={DollarSign}
                label="Expense"
                description="Approval for a purchase or payment"
                selected={type === 'EXPENSE'}
                onClick={() => setType('EXPENSE')}
              />
              <TypeCard
                type="VENDOR_SELECTION"
                icon={Truck}
                label="Vendor"
                description="Approval to hire a vendor"
                selected={type === 'VENDOR_SELECTION'}
                onClick={() => setType('VENDOR_SELECTION')}
              />
              <TypeCard
                type="PROJECT"
                icon={Wrench}
                label="Project"
                description="Approval for a project or work"
                selected={type === 'PROJECT'}
                onClick={() => setType('PROJECT')}
              />
              <TypeCard
                type="SCHEDULE"
                icon={Calendar}
                label="Schedule"
                description="Approval for scheduling"
                selected={type === 'SCHEDULE'}
                onClick={() => setType('SCHEDULE')}
              />
              <TypeCard
                type="OTHER"
                icon={FileText}
                label="Other"
                description="General approval request"
                selected={type === 'OTHER'}
                onClick={() => setType('OTHER')}
              />
            </div>
          </div>

          {/* Priority */}
          <div className="bg-white rounded-xl border border-gray-200 p-6">
            <label className="block text-sm font-medium text-gray-700 mb-3">
              Priority Level
            </label>
            <div className="flex gap-2">
              <PriorityButton
                priority="LOW"
                label="Low"
                selected={priority === 'LOW'}
                onClick={() => setPriority('LOW')}
                color="gray"
              />
              <PriorityButton
                priority="MEDIUM"
                label="Normal"
                selected={priority === 'MEDIUM'}
                onClick={() => setPriority('MEDIUM')}
                color="blue"
              />
              <PriorityButton
                priority="HIGH"
                label="High"
                selected={priority === 'HIGH'}
                onClick={() => setPriority('HIGH')}
                color="orange"
              />
              <PriorityButton
                priority="URGENT"
                label="Urgent"
                selected={priority === 'URGENT'}
                onClick={() => setPriority('URGENT')}
                color="red"
              />
            </div>
            <p className="text-sm text-gray-500 mt-2">
              {priority === 'URGENT' && 'Homeowner will be notified immediately.'}
              {priority === 'HIGH' && 'Homeowner will be prompted to respond soon.'}
              {priority === 'MEDIUM' && 'Normal processing time.'}
              {priority === 'LOW' && 'Can wait until convenient for homeowner.'}
            </p>
          </div>

          {/* Details */}
          <div className="bg-white rounded-xl border border-gray-200 p-6 space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Title *
              </label>
              <input
                type="text"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="e.g., Garbage disposal replacement"
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
                required
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Description / Note to Homeowner
              </label>
              <textarea
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder="Explain what this is for and why you recommend it..."
                rows={4}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-emerald-600 focus:border-transparent resize-none"
              />
            </div>

            {showAmountField && (
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Amount
                </label>
                <div className="relative">
                  <DollarSign className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                  <input
                    type="number"
                    step="0.01"
                    min="0"
                    value={amount}
                    onChange={(e) => setAmount(e.target.value)}
                    placeholder="0.00"
                    className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
                  />
                </div>
              </div>
            )}

            {showVendorField && (
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Vendor Name
                </label>
                <input
                  type="text"
                  value={vendorName}
                  onChange={(e) => setVendorName(e.target.value)}
                  placeholder="e.g., ABC Plumbing"
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
                />
              </div>
            )}
          </div>

          {/* Submit */}
          <div className="flex gap-4">
            <Link
              href="/manager/approvals"
              className="flex-1 px-4 py-3 border border-gray-300 text-gray-700 rounded-xl font-medium text-center hover:bg-gray-50 transition-colors"
            >
              Cancel
            </Link>
            <button
              type="submit"
              disabled={isSubmitting || !householdId || !title.trim()}
              className="flex-1 px-4 py-3 bg-emerald-600 text-white rounded-xl font-medium hover:bg-emerald-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isSubmitting ? 'Sending...' : 'Send Request'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
