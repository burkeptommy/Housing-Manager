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
  CreditCard,
  Banknote,
  Home,
  ChevronRight,
  FileCheck,
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
  managementStatus: string;
  detectionType: string;
  transactionCount: number;
  account: {
    id: string;
    name: string;
    mask: string;
    type: string;
    connection: {
      institutionName: string;
      id: string;
    };
  } | null;
}

const categoryLabels: Record<string, string> = {
  MORTGAGE: 'Mortgage',
  RENT: 'Rent',
  UTILITIES_ELECTRIC: 'Electric',
  UTILITIES_GAS: 'Gas',
  UTILITIES_WATER: 'Water',
  ELECTRIC: 'Electric',
  GAS: 'Gas',
  WATER_SEWER: 'Water',
  INTERNET: 'Internet',
  PHONE: 'Phone',
  CELL_PHONE: 'Phone',
  INSURANCE_HOME: 'Home Insurance',
  INSURANCE_AUTO: 'Auto Insurance',
  HOME_INSURANCE: 'Home Insurance',
  AUTO_INSURANCE: 'Auto Insurance',
  STREAMING: 'Streaming',
  STREAMING_SERVICE: 'Streaming',
  GYM: 'Gym',
  GYM_FITNESS: 'Gym',
  CHILDCARE: 'Childcare',
  TUITION: 'Tuition',
  SCHOOL_TUITION: 'Tuition',
  LANDSCAPING: 'Landscaping',
  LAWN_LANDSCAPE: 'Landscaping',
  HOUSEKEEPING: 'Housekeeping',
  HOUSE_CLEANING: 'Cleaning',
  POOL_SERVICE: 'Pool Service',
  SECURITY: 'Security',
  SECURITY_MONITORING: 'Security',
  PROPERTY_TAX: 'Property Tax',
  SOFTWARE_SUBSCRIPTION: 'Subscription',
  HOA: 'HOA',
  PERSONAL_LOAN: 'Loan',
  CREDIT_CARD: 'Credit Card',
  OTHER: 'Other',
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
  const [filter, setFilter] = useState<'all' | 'pending' | 'confirmed' | 'haven_managed'>('all');
  const [accountFilter, setAccountFilter] = useState<string>('all');

  // Get unique accounts for filter
  const uniqueAccounts = Array.from(
    new Map(
      bills
        .filter((b) => b.account)
        .map((b) => [b.account!.id, b.account!])
    ).values()
  );

  const loadBills = useCallback(async () => {
    if (!householdId) {
      setLoading(false);
      return;
    }
    try {
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      const response = await fetch(`${apiUrl}/plaid/bills/${householdId}`, {
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
  }, [householdId]);

  useEffect(() => {
    loadBills();
  }, [loadBills]);

  const handleConfirm = async (billId: string, e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    try {
      setProcessing(billId);
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      await fetch(`${apiUrl}/plaid/bills/${billId}/confirm`, {
        method: 'PUT',
        headers: { Authorization: `Bearer ${token}` },
      });

      await loadBills();
    } finally {
      setProcessing(null);
    }
  };

  const handleDismiss = async (billId: string, e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    try {
      setProcessing(billId);
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      await fetch(`${apiUrl}/plaid/bills/${billId}/dismiss`, {
        method: 'PUT',
        headers: { Authorization: `Bearer ${token}` },
      });

      await loadBills();
    } finally {
      setProcessing(null);
    }
  };

  const handleLetHavenManage = async (billId: string, e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    try {
      setProcessing(billId);
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      await fetch(`${apiUrl}/bills/${billId}/management`, {
        method: 'PUT',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          householdId,
          managementStatus: 'PENDING_SETUP',
        }),
      });

      await loadBills();
    } finally {
      setProcessing(null);
    }
  };

  // Filter bills
  let filteredBills = bills;
  if (filter === 'pending') {
    filteredBills = bills.filter((b) => b.status === 'PENDING');
  } else if (filter === 'confirmed') {
    filteredBills = bills.filter((b) => b.status === 'CONFIRMED' && b.managementStatus === 'SELF_MANAGED');
  } else if (filter === 'haven_managed') {
    filteredBills = bills.filter((b) => b.managementStatus === 'HAVEN_MANAGED' || b.managementStatus === 'PENDING_SETUP');
  }

  // Filter by account
  if (accountFilter !== 'all') {
    filteredBills = filteredBills.filter((b) => b.account?.id === accountFilter);
  }

  // Group bills by account for display
  const billsByAccount = filteredBills.reduce((acc, bill) => {
    const accountKey = bill.account?.id || 'unknown';
    if (!acc[accountKey]) {
      acc[accountKey] = {
        account: bill.account,
        bills: [],
      };
    }
    acc[accountKey].bills.push(bill);
    return acc;
  }, {} as Record<string, { account: DetectedBill['account']; bills: DetectedBill[] }>);

  const havenManagedCount = bills.filter(
    (b) => b.managementStatus === 'HAVEN_MANAGED' || b.managementStatus === 'PENDING_SETUP'
  ).length;

  const havenManagedTotal = bills
    .filter((b) => b.managementStatus === 'HAVEN_MANAGED' || b.managementStatus === 'PENDING_SETUP')
    .reduce((sum, b) => {
      if (b.frequency === 'WEEKLY') return sum + b.averageAmount * 4;
      if (b.frequency === 'BIWEEKLY') return sum + b.averageAmount * 2;
      if (b.frequency === 'QUARTERLY') return sum + b.averageAmount / 3;
      if (b.frequency === 'ANNUAL') return sum + b.averageAmount / 12;
      return sum + b.averageAmount;
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
            {bills.length} bills detected • ${bills.reduce((sum, b) => {
              if (b.frequency === 'WEEKLY') return sum + b.averageAmount * 4;
              if (b.frequency === 'BIWEEKLY') return sum + b.averageAmount * 2;
              if (b.frequency === 'QUARTERLY') return sum + b.averageAmount / 3;
              if (b.frequency === 'ANNUAL') return sum + b.averageAmount / 12;
              return sum + b.averageAmount;
            }, 0).toLocaleString()}/month est.
          </p>
        </div>
        <Link
          href="/app/money/connect"
          className="text-sm text-indigo-600 hover:underline"
        >
          Manage Banks
        </Link>
      </div>

      {/* Haven Managed Summary */}
      {havenManagedCount > 0 && (
        <div className="bg-green-50 border border-green-200 rounded-xl p-4">
          <div className="flex items-center gap-3">
            <Home className="w-6 h-6 text-green-600" />
            <div className="flex-1">
              <p className="font-medium text-green-800">
                {havenManagedCount} bills managed by Haven
              </p>
              <p className="text-sm text-green-600">
                ~${havenManagedTotal.toLocaleString()}/month from your Haven Wallet
              </p>
            </div>
            <Link
              href="/app/money/wallet"
              className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 text-sm"
            >
              Fund Wallet
            </Link>
          </div>
        </div>
      )}

      {/* Filters */}
      <div className="flex flex-wrap gap-4">
        {/* Status Filter */}
        <div className="flex gap-2">
          <button
            onClick={() => setFilter('all')}
            className={`px-4 py-2 rounded-lg text-sm font-medium ${
              filter === 'all'
                ? 'bg-indigo-100 text-indigo-800'
                : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
            }`}
          >
            All ({bills.length})
          </button>
          <button
            onClick={() => setFilter('pending')}
            className={`px-4 py-2 rounded-lg text-sm font-medium ${
              filter === 'pending'
                ? 'bg-amber-100 text-amber-800'
                : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
            }`}
          >
            Pending ({bills.filter((b) => b.status === 'PENDING').length})
          </button>
          <button
            onClick={() => setFilter('confirmed')}
            className={`px-4 py-2 rounded-lg text-sm font-medium ${
              filter === 'confirmed'
                ? 'bg-blue-100 text-blue-800'
                : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
            }`}
          >
            Self-Managed
          </button>
          <button
            onClick={() => setFilter('haven_managed')}
            className={`px-4 py-2 rounded-lg text-sm font-medium ${
              filter === 'haven_managed'
                ? 'bg-green-100 text-green-800'
                : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
            }`}
          >
            Haven-Managed ({havenManagedCount})
          </button>
        </div>

        {/* Account Filter */}
        {uniqueAccounts.length > 1 && (
          <select
            value={accountFilter}
            onChange={(e) => setAccountFilter(e.target.value)}
            className="px-4 py-2 border border-gray-200 rounded-lg text-sm"
          >
            <option value="all">All Accounts</option>
            {uniqueAccounts.map((account) => (
              <option key={account.id} value={account.id}>
                {account.connection.institutionName} ••••{account.mask}
              </option>
            ))}
          </select>
        )}
      </div>

      {/* Bills List - Grouped by Account */}
      {Object.entries(billsByAccount).map(([accountId, { account, bills: accountBills }]) => (
        <div key={accountId} className="space-y-3">
          {/* Account Header */}
          <div className="flex items-center gap-3 px-1">
            <div className={`w-8 h-8 rounded-lg flex items-center justify-center ${
              account?.type === 'credit' ? 'bg-purple-100' : 'bg-blue-100'
            }`}>
              {account?.type === 'credit' ? (
                <CreditCard className={`w-4 h-4 text-purple-600`} />
              ) : (
                <Building2 className={`w-4 h-4 text-blue-600`} />
              )}
            </div>
            <div>
              <p className="font-medium text-gray-900">
                {account?.connection?.institutionName || 'Unknown Bank'}
              </p>
              <p className="text-xs text-gray-500">
                {account?.name} ••••{account?.mask}
              </p>
            </div>
            <div className="ml-auto text-right">
              <p className="text-sm font-medium text-gray-900">
                {accountBills.length} bills
              </p>
              <p className="text-xs text-gray-500">
                ${accountBills.reduce((sum, b) => sum + b.averageAmount, 0).toLocaleString()}/mo
              </p>
            </div>
          </div>

          {/* Bills for this account */}
          <div className="bg-white rounded-xl border border-gray-200 divide-y divide-gray-100">
            {accountBills.map((bill) => {
              const isCheck = bill.detectionType === 'RECURRING_CHECK';
              const isHavenManaged = bill.managementStatus === 'HAVEN_MANAGED';
              const isPendingSetup = bill.managementStatus === 'PENDING_SETUP';
              const isPending = bill.status === 'PENDING';

              return (
                <Link
                  key={bill.id}
                  href={`/app/money/bills/${bill.id}`}
                  className="p-4 flex items-center gap-4 hover:bg-gray-50 transition group"
                >
                  {/* Icon */}
                  <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${
                    isHavenManaged
                      ? 'bg-green-100'
                      : isPendingSetup
                        ? 'bg-amber-100'
                        : isCheck
                          ? 'bg-amber-50'
                          : 'bg-gray-100'
                  }`}>
                    {isHavenManaged ? (
                      <Home className="w-5 h-5 text-green-600" />
                    ) : isPendingSetup ? (
                      <Loader2 className="w-5 h-5 text-amber-600" />
                    ) : isCheck ? (
                      <FileCheck className="w-5 h-5 text-amber-600" />
                    ) : (
                      <Receipt className="w-5 h-5 text-gray-600" />
                    )}
                  </div>

                  {/* Bill Info */}
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <p className="font-medium text-gray-900 truncate">
                        {bill.merchantName}
                      </p>
                      {isCheck && (
                        <span className="px-1.5 py-0.5 bg-amber-100 text-amber-700 text-xs rounded">
                          Check
                        </span>
                      )}
                      {isHavenManaged && (
                        <span className="px-1.5 py-0.5 bg-green-100 text-green-700 text-xs rounded">
                          Haven
                        </span>
                      )}
                      {isPendingSetup && (
                        <span className="px-1.5 py-0.5 bg-amber-100 text-amber-700 text-xs rounded">
                          Setting up
                        </span>
                      )}
                    </div>
                    <p className="text-sm text-gray-500">
                      {categoryLabels[bill.category] || bill.category} • {frequencyLabels[bill.frequency]}
                    </p>
                  </div>

                  {/* Amount */}
                  <div className="text-right">
                    <p className="font-semibold text-gray-900">
                      ${bill.averageAmount.toLocaleString()}
                    </p>
                    <p className="text-xs text-gray-500">
                      Next: {new Date(bill.nextExpectedDate).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}
                    </p>
                  </div>

                  {/* Actions */}
                  <div className="flex items-center gap-2 opacity-0 group-hover:opacity-100 transition">
                    {isPending && (
                      <>
                        <button
                          onClick={(e) => handleConfirm(bill.id, e)}
                          disabled={processing === bill.id}
                          className="p-2 bg-green-100 text-green-700 rounded-lg hover:bg-green-200"
                          title="Confirm bill"
                        >
                          <Check className="w-4 h-4" />
                        </button>
                        <button
                          onClick={(e) => handleDismiss(bill.id, e)}
                          disabled={processing === bill.id}
                          className="p-2 bg-red-100 text-red-700 rounded-lg hover:bg-red-200"
                          title="Dismiss"
                        >
                          <X className="w-4 h-4" />
                        </button>
                      </>
                    )}
                    {bill.status === 'CONFIRMED' && !isHavenManaged && !isPendingSetup && (
                      <button
                        onClick={(e) => handleLetHavenManage(bill.id, e)}
                        disabled={processing === bill.id}
                        className="px-3 py-1.5 bg-indigo-100 text-indigo-700 rounded-lg hover:bg-indigo-200 text-sm font-medium flex items-center gap-1"
                        title="Let Haven manage this bill"
                      >
                        {processing === bill.id ? (
                          <Loader2 className="w-3 h-3 animate-spin" />
                        ) : (
                          <Home className="w-3 h-3" />
                        )}
                        Haven
                      </button>
                    )}
                    <ChevronRight className="w-5 h-5 text-gray-400" />
                  </div>
                </Link>
              );
            })}
          </div>
        </div>
      ))}

      {/* Empty State */}
      {filteredBills.length === 0 && (
        <div className="text-center py-12 bg-white rounded-xl border border-gray-200">
          <Receipt className="w-12 h-12 text-gray-300 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900">No bills found</h3>
          <p className="text-gray-500">
            {filter !== 'all' ? 'Try changing the filter' : 'Connect a bank to detect bills'}
          </p>
        </div>
      )}
    </div>
  );
}
