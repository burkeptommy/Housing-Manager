'use client';

import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '@/contexts/auth-context';
import { getIdToken } from '@/lib/firebase';
import {
  Receipt,
  Check,
  X,
  Loader2,
  Building2,
  Calendar,
  DollarSign,
  FileCheck,
  CreditCard,
} from 'lucide-react';
import Link from 'next/link';

interface DetectedBill {
  id: string;
  merchantName: string;
  category: string;
  averageAmount: number;
  lastAmount: number;
  frequency: string;
  lastTransactionDate: string;
  nextExpectedDate: string;
  status: string;
  transactionCount: number;
  detectionType: string;
  checkPayee: string | null;
  account: {
    name: string;
    mask: string;
    connection: { institutionName: string };
  } | null;
}

const categoryLabels: Record<string, string> = {
  MORTGAGE: 'Mortgage',
  RENT: 'Rent',
  ELECTRIC: 'Electric',
  GAS: 'Gas',
  WATER_SEWER: 'Water',
  INTERNET: 'Internet',
  CELL_PHONE: 'Phone',
  HOME_INSURANCE: 'Home Insurance',
  AUTO_INSURANCE: 'Auto Insurance',
  LIFE_INSURANCE: 'Life Insurance',
  SOFTWARE_SUBSCRIPTION: 'Subscription',
  STREAMING_SERVICE: 'Streaming',
  GYM_FITNESS: 'Gym',
  CHILDCARE: 'Childcare',
  NANNY: 'Nanny',
  SCHOOL_TUITION: 'Tuition',
  PERSONAL_LOAN: 'Loan',
  CREDIT_CARD: 'Credit Card',
  HOA: 'HOA',
  PROPERTY_TAX: 'Property Tax',
  SECURITY_MONITORING: 'Security',
  LAWN_LANDSCAPE: 'Landscaping',
  POOL_SERVICE: 'Pool Service',
  HOUSE_CLEANING: 'Cleaning',
  OTHER_BILL: 'Other',
};

const frequencyLabels: Record<string, string> = {
  WEEKLY: 'Weekly',
  BIWEEKLY: 'Every 2 weeks',
  MONTHLY: 'Monthly',
  QUARTERLY: 'Quarterly',
  SEMI_ANNUAL: 'Every 6 months',
  ANNUAL: 'Yearly',
  IRREGULAR: 'Irregular',
};

export default function BillsReviewPage() {
  const { householdId } = useAuth();
  const [bills, setBills] = useState<DetectedBill[]>([]);
  const [loading, setLoading] = useState(true);
  const [processing, setProcessing] = useState<string | null>(null);
  const [filter, setFilter] = useState<'all' | 'pending' | 'confirmed'>('pending');

  const loadBills = useCallback(async () => {
    if (!householdId) {
      setLoading(false);
      return;
    }
    try {
      const token = await getIdToken();
      const apiUrl =
        process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      const status = filter === 'all' ? '' : filter.toUpperCase();
      const url = `${apiUrl}/plaid/bills/${householdId}${status ? `?status=${status}` : ''}`;

      const response = await fetch(url, {
        headers: { Authorization: `Bearer ${token}` },
      });

      if (response.ok) {
        setBills(await response.json());
      }
    } catch (error) {
      console.error('Failed to load bills:', error);
    } finally {
      setLoading(false);
    }
  }, [householdId, filter]);

  useEffect(() => {
    if (householdId) {
      loadBills();
    }
  }, [householdId, loadBills]);

  const handleConfirm = async (billId: string) => {
    try {
      setProcessing(billId);
      const token = await getIdToken();
      const apiUrl =
        process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      await fetch(`${apiUrl}/plaid/bills/${billId}/confirm`, {
        method: 'PUT',
        headers: { Authorization: `Bearer ${token}` },
      });

      await loadBills();
    } catch (error) {
      console.error('Confirm failed:', error);
    } finally {
      setProcessing(null);
    }
  };

  const handleDismiss = async (billId: string) => {
    try {
      setProcessing(billId);
      const token = await getIdToken();
      const apiUrl =
        process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      await fetch(`${apiUrl}/plaid/bills/${billId}/dismiss`, {
        method: 'PUT',
        headers: { Authorization: `Bearer ${token}` },
      });

      await loadBills();
    } catch (error) {
      console.error('Dismiss failed:', error);
    } finally {
      setProcessing(null);
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
    });
  };

  const pendingCount = bills.filter((b) => b.status === 'PENDING').length;
  const totalMonthly = bills
    .filter((b) => b.status !== 'DISMISSED')
    .reduce((sum, b) => {
      let multiplier = 1;
      if (b.frequency === 'WEEKLY') multiplier = 4.33;
      if (b.frequency === 'BIWEEKLY') multiplier = 2.17;
      if (b.frequency === 'QUARTERLY') multiplier = 0.33;
      if (b.frequency === 'SEMI_ANNUAL') multiplier = 0.17;
      if (b.frequency === 'ANNUAL') multiplier = 0.083;
      return sum + b.averageAmount * multiplier;
    }, 0);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="w-8 h-8 animate-spin text-indigo-600" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Detected Bills</h1>
          <p className="text-gray-500">
            {pendingCount > 0
              ? `Review ${pendingCount} detected recurring charges`
              : 'All bills reviewed'}
          </p>
        </div>
        <Link href="/app/money/connect">
          <button className="px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 text-sm">
            Manage Banks
          </button>
        </Link>
      </div>

      {/* Summary */}
      <div className="grid grid-cols-2 gap-4">
        <div className="bg-white rounded-xl border border-gray-200 p-4">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-indigo-100 rounded-lg flex items-center justify-center">
              <Receipt className="w-5 h-5 text-indigo-600" />
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-900">{bills.length}</p>
              <p className="text-sm text-gray-500">Bills Detected</p>
            </div>
          </div>
        </div>
        <div className="bg-white rounded-xl border border-gray-200 p-4">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center">
              <DollarSign className="w-5 h-5 text-green-600" />
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-900">
                ${Math.round(totalMonthly).toLocaleString()}
              </p>
              <p className="text-sm text-gray-500">Est. Monthly</p>
            </div>
          </div>
        </div>
      </div>

      {/* Filters */}
      <div className="flex gap-2">
        {(['pending', 'confirmed', 'all'] as const).map((f) => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            className={`px-4 py-2 rounded-lg text-sm font-medium ${
              filter === f
                ? 'bg-indigo-600 text-white'
                : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            }`}
          >
            {f.charAt(0).toUpperCase() + f.slice(1)}
          </button>
        ))}
      </div>

      {/* Bills List */}
      {bills.length === 0 ? (
        <div className="text-center py-12 bg-white rounded-xl border border-gray-200">
          <Receipt className="w-12 h-12 text-gray-300 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900">No bills found</h3>
          <p className="text-gray-500">
            {filter === 'pending'
              ? 'All bills have been reviewed!'
              : 'Connect a bank account to detect bills.'}
          </p>
        </div>
      ) : (
        <div className="space-y-3">
          {bills.map((bill) => (
            <div
              key={bill.id}
              className={`bg-white rounded-xl border p-4 ${
                bill.status === 'PENDING'
                  ? 'border-amber-200'
                  : bill.status === 'CONFIRMED'
                    ? 'border-green-200'
                    : 'border-gray-200'
              }`}
            >
              <div className="flex items-start gap-4">
                <div
                  className={`w-12 h-12 rounded-xl flex items-center justify-center ${
                    bill.detectionType === 'RECURRING_CHECK'
                      ? 'bg-amber-100'
                      : 'bg-gray-100'
                  }`}
                >
                  {bill.detectionType === 'RECURRING_CHECK' ? (
                    <FileCheck className="w-6 h-6 text-amber-600" />
                  ) : (
                    <CreditCard className="w-6 h-6 text-gray-600" />
                  )}
                </div>

                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 flex-wrap">
                    <h3 className="font-medium text-gray-900">
                      {bill.merchantName}
                    </h3>
                    <span className="px-2 py-0.5 bg-gray-100 text-gray-600 text-xs rounded">
                      {categoryLabels[bill.category] || bill.category}
                    </span>
                    {bill.detectionType === 'RECURRING_CHECK' && (
                      <span className="px-2 py-0.5 bg-amber-100 text-amber-700 text-xs font-medium rounded">
                        Check
                      </span>
                    )}
                    {bill.status === 'CONFIRMED' && (
                      <span className="px-2 py-0.5 bg-green-100 text-green-700 text-xs rounded">
                        Confirmed
                      </span>
                    )}
                  </div>
                  {bill.checkPayee && bill.checkPayee !== bill.merchantName && (
                    <p className="text-xs text-gray-500 mt-0.5">
                      Payee: {bill.checkPayee}
                    </p>
                  )}
                  <div className="flex items-center gap-4 mt-1 text-sm text-gray-500">
                    <span className="flex items-center gap-1">
                      <DollarSign className="w-4 h-4" />$
                      {bill.averageAmount.toFixed(2)}
                    </span>
                    <span>
                      {frequencyLabels[bill.frequency] || bill.frequency}
                    </span>
                    <span className="flex items-center gap-1">
                      <Calendar className="w-4 h-4" />
                      Last: {formatDate(bill.lastTransactionDate)}
                    </span>
                    {bill.account && (
                      <span className="flex items-center gap-1">
                        <Building2 className="w-4 h-4" />
                        {bill.account.connection.institutionName} ----
                        {bill.account.mask}
                      </span>
                    )}
                  </div>
                </div>

                {/* Actions */}
                {bill.status === 'PENDING' && (
                  <div className="flex items-center gap-2">
                    <button
                      onClick={() => handleConfirm(bill.id)}
                      disabled={processing === bill.id}
                      className="p-2 bg-green-100 text-green-600 rounded-lg hover:bg-green-200"
                      title="Confirm as bill"
                    >
                      <Check className="w-5 h-5" />
                    </button>
                    <button
                      onClick={() => handleDismiss(bill.id)}
                      disabled={processing === bill.id}
                      className="p-2 bg-red-100 text-red-600 rounded-lg hover:bg-red-200"
                      title="Not a bill"
                    >
                      <X className="w-5 h-5" />
                    </button>
                  </div>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
