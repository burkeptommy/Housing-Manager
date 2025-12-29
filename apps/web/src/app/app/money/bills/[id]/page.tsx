'use client';

import { useState, useEffect, useCallback } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/auth-context';
import { getIdToken } from '@/lib/firebase';
import {
  ArrowLeft,
  Building2,
  Calendar,
  DollarSign,
  TrendingUp,
  TrendingDown,
  FileText,
  MessageSquare,
  CheckCircle,
  Clock,
  CreditCard,
  Banknote,
  Home,
  Loader2,
  Edit,
  Trash2,
  Plus,
} from 'lucide-react';
import Link from 'next/link';

interface BillTransaction {
  id: string;
  date: string;
  amount: number;
  description: string;
  pending: boolean;
}

interface BillDetail {
  id: string;
  merchantName: string;
  normalizedName: string;
  category: string;
  detectionType: string;
  checkPayee: string | null;
  averageAmount: number;
  lastAmount: number;
  frequency: string;
  lastTransactionDate: string;
  nextExpectedDate: string;
  dayOfMonth: number | null;
  status: string;
  managementStatus: string; // SELF_MANAGED, HAVEN_MANAGED, PENDING_SETUP
  transactionCount: number;
  confidence: number;
  notes: string | null;
  paymentMethod: string | null; // CARD, ACH, CHECK
  account: {
    id: string;
    name: string;
    mask: string;
    connection: {
      institutionName: string;
    };
  } | null;
  transactions: BillTransaction[];
  relatedDocuments: Array<{
    id: string;
    title: string;
    category: string;
  }>;
}

const categoryLabels: Record<string, string> = {
  MORTGAGE: 'Mortgage',
  RENT: 'Rent',
  UTILITIES_ELECTRIC: 'Electric',
  UTILITIES_GAS: 'Gas',
  UTILITIES_WATER: 'Water',
  INTERNET: 'Internet',
  PHONE: 'Phone',
  INSURANCE_HOME: 'Home Insurance',
  INSURANCE_AUTO: 'Auto Insurance',
  STREAMING: 'Streaming',
  GYM: 'Gym & Fitness',
  CHILDCARE: 'Childcare',
  TUITION: 'Tuition',
  LANDSCAPING: 'Landscaping',
  HOUSEKEEPING: 'Housekeeping',
  POOL_SERVICE: 'Pool Service',
  SECURITY: 'Security',
  PROPERTY_TAX: 'Property Tax',
  OTHER: 'Other',
};

const frequencyLabels: Record<string, string> = {
  WEEKLY: 'Weekly',
  BIWEEKLY: 'Every 2 weeks',
  MONTHLY: 'Monthly',
  QUARTERLY: 'Quarterly',
  SEMI_ANNUAL: 'Every 6 months',
  ANNUAL: 'Yearly',
};

export default function BillDetailPage() {
  const params = useParams();
  const router = useRouter();
  const { householdId } = useAuth();
  const billId = params.id as string;

  const [bill, setBill] = useState<BillDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const [updating, setUpdating] = useState(false);
  const [showNotes, setShowNotes] = useState(false);
  const [notes, setNotes] = useState('');

  const loadBill = useCallback(async () => {
    if (!householdId || !billId) return;
    try {
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      const response = await fetch(`${apiUrl}/bills/${billId}?householdId=${householdId}`, {
        headers: { Authorization: `Bearer ${token}` },
      });

      if (response.ok) {
        const data = await response.json();
        setBill(data);
        setNotes(data.notes || '');
      }
    } catch (error) {
      console.error('Failed to load bill:', error);
    } finally {
      setLoading(false);
    }
  }, [householdId, billId]);

  useEffect(() => {
    loadBill();
  }, [loadBill]);

  const updateManagementStatus = async (newStatus: string) => {
    if (!bill) return;
    try {
      setUpdating(true);
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
          managementStatus: newStatus,
        }),
      });

      await loadBill();
    } catch (error) {
      console.error('Failed to update:', error);
    } finally {
      setUpdating(false);
    }
  };

  const saveNotes = async () => {
    if (!bill) return;
    try {
      setUpdating(true);
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      await fetch(`${apiUrl}/bills/${billId}/notes`, {
        method: 'PUT',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ householdId, notes }),
      });

      await loadBill();
      setShowNotes(false);
    } catch (error) {
      console.error('Failed to save notes:', error);
    } finally {
      setUpdating(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="w-8 h-8 animate-spin text-indigo-600" />
      </div>
    );
  }

  if (!bill) {
    return (
      <div className="text-center py-12">
        <p className="text-gray-500">Bill not found</p>
        <Link href="/app/money/bills" className="text-indigo-600 hover:underline mt-2 inline-block">
          Back to Bills
        </Link>
      </div>
    );
  }

  const isCheck = bill.detectionType === 'RECURRING_CHECK';
  const isHavenManaged = bill.managementStatus === 'HAVEN_MANAGED';
  const isPendingSetup = bill.managementStatus === 'PENDING_SETUP';

  // Calculate trend
  const transactions = bill.transactions || [];
  const recentTxs = transactions.slice(0, 3);
  const olderTxs = transactions.slice(3, 6);
  const recentAvg = recentTxs.length > 0
    ? recentTxs.reduce((sum, tx) => sum + tx.amount, 0) / recentTxs.length
    : bill.averageAmount;
  const olderAvg = olderTxs.length > 0
    ? olderTxs.reduce((sum, tx) => sum + tx.amount, 0) / olderTxs.length
    : bill.averageAmount;
  const trend = recentAvg - olderAvg;
  const trendPercent = olderAvg > 0 ? (trend / olderAvg) * 100 : 0;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Link
          href="/app/money/bills"
          className="p-2 hover:bg-gray-100 rounded-lg transition"
        >
          <ArrowLeft className="w-5 h-5 text-gray-600" />
        </Link>
        <div className="flex-1">
          <div className="flex items-center gap-3">
            <h1 className="text-2xl font-bold text-gray-900">{bill.merchantName}</h1>
            {isCheck && (
              <span className="px-2 py-1 bg-amber-100 text-amber-700 text-xs font-medium rounded">
                Check Payment
              </span>
            )}
          </div>
          <p className="text-gray-500">
            {categoryLabels[bill.category] || bill.category} • {frequencyLabels[bill.frequency]}
          </p>
        </div>
      </div>

      {/* Management Status Card */}
      <div className={`rounded-xl border-2 p-6 ${
        isHavenManaged
          ? 'bg-green-50 border-green-200'
          : isPendingSetup
            ? 'bg-amber-50 border-amber-200'
            : 'bg-gray-50 border-gray-200'
      }`}>
        <div className="flex items-start justify-between">
          <div>
            <div className="flex items-center gap-2 mb-2">
              {isHavenManaged ? (
                <Home className="w-5 h-5 text-green-600" />
              ) : isPendingSetup ? (
                <Clock className="w-5 h-5 text-amber-600" />
              ) : (
                <CreditCard className="w-5 h-5 text-gray-600" />
              )}
              <h3 className="font-semibold text-gray-900">
                {isHavenManaged
                  ? 'Haven-Managed Bill'
                  : isPendingSetup
                    ? 'Setting Up Haven Management'
                    : 'Self-Managed Bill'}
              </h3>
            </div>
            <p className="text-sm text-gray-600">
              {isHavenManaged
                ? 'Haven pays this bill from your wallet. Sarah manages the payment.'
                : isPendingSetup
                  ? 'Sarah is setting up automatic payment for this bill.'
                  : 'You currently pay this bill yourself.'}
            </p>
            {isHavenManaged && bill.paymentMethod && (
              <p className="text-sm text-green-700 mt-2">
                Payment method: {bill.paymentMethod === 'CHECK' ? 'Check via Checkbook.io' : bill.paymentMethod}
              </p>
            )}
          </div>

          {!isHavenManaged && !isPendingSetup && (
            <button
              onClick={() => updateManagementStatus('PENDING_SETUP')}
              disabled={updating}
              className="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 disabled:opacity-50 flex items-center gap-2"
            >
              {updating ? (
                <Loader2 className="w-4 h-4 animate-spin" />
              ) : (
                <Home className="w-4 h-4" />
              )}
              Let Haven Manage
            </button>
          )}

          {isPendingSetup && (
            <button
              onClick={() => updateManagementStatus('SELF_MANAGED')}
              disabled={updating}
              className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-100 disabled:opacity-50"
            >
              Cancel
            </button>
          )}

          {isHavenManaged && (
            <button
              onClick={() => updateManagementStatus('SELF_MANAGED')}
              disabled={updating}
              className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-100 disabled:opacity-50"
            >
              Manage Myself
            </button>
          )}
        </div>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div className="bg-white rounded-xl border border-gray-200 p-4">
          <div className="flex items-center gap-2 text-gray-500 text-sm mb-1">
            <DollarSign className="w-4 h-4" />
            Average Amount
          </div>
          <p className="text-2xl font-bold text-gray-900">
            ${bill.averageAmount.toLocaleString()}
          </p>
        </div>

        <div className="bg-white rounded-xl border border-gray-200 p-4">
          <div className="flex items-center gap-2 text-gray-500 text-sm mb-1">
            <DollarSign className="w-4 h-4" />
            Last Amount
          </div>
          <p className="text-2xl font-bold text-gray-900">
            ${bill.lastAmount.toLocaleString()}
          </p>
          {Math.abs(trendPercent) > 5 && (
            <div className={`flex items-center gap-1 text-xs mt-1 ${
              trend > 0 ? 'text-red-600' : 'text-green-600'
            }`}>
              {trend > 0 ? (
                <TrendingUp className="w-3 h-3" />
              ) : (
                <TrendingDown className="w-3 h-3" />
              )}
              {Math.abs(trendPercent).toFixed(0)}% vs avg
            </div>
          )}
        </div>

        <div className="bg-white rounded-xl border border-gray-200 p-4">
          <div className="flex items-center gap-2 text-gray-500 text-sm mb-1">
            <Calendar className="w-4 h-4" />
            Next Expected
          </div>
          <p className="text-lg font-semibold text-gray-900">
            {new Date(bill.nextExpectedDate).toLocaleDateString('en-US', {
              month: 'short',
              day: 'numeric',
            })}
          </p>
          {bill.dayOfMonth && (
            <p className="text-xs text-gray-500">
              Usually on the {bill.dayOfMonth}{['st', 'nd', 'rd'][bill.dayOfMonth - 1] || 'th'}
            </p>
          )}
        </div>

        <div className="bg-white rounded-xl border border-gray-200 p-4">
          <div className="flex items-center gap-2 text-gray-500 text-sm mb-1">
            <Building2 className="w-4 h-4" />
            Account
          </div>
          <p className="text-sm font-medium text-gray-900">
            {bill.account?.connection?.institutionName || 'Unknown'}
          </p>
          <p className="text-xs text-gray-500">
            {bill.account?.name} ••••{bill.account?.mask}
          </p>
        </div>
      </div>

      {/* Check Payee Info */}
      {isCheck && bill.checkPayee && (
        <div className="bg-amber-50 border border-amber-200 rounded-xl p-4">
          <div className="flex items-center gap-3">
            <Banknote className="w-6 h-6 text-amber-600" />
            <div>
              <p className="font-medium text-gray-900">Check Payee</p>
              <p className="text-sm text-amber-700">{bill.checkPayee}</p>
              <p className="text-xs text-amber-600 mt-1">
                This bill is paid by check. Haven can automate this via Checkbook.io.
              </p>
            </div>
          </div>
        </div>
      )}

      {/* Transaction History */}
      <div className="bg-white rounded-xl border border-gray-200">
        <div className="p-4 border-b border-gray-100">
          <h3 className="font-semibold text-gray-900">Transaction History</h3>
          <p className="text-sm text-gray-500">
            {transactions.length} transactions found
          </p>
        </div>
        <div className="divide-y divide-gray-100 max-h-80 overflow-y-auto">
          {transactions.length > 0 ? (
            transactions.map((tx, i) => (
              <div key={tx.id || i} className="p-4 flex items-center justify-between">
                <div>
                  <p className="font-medium text-gray-900">
                    ${tx.amount.toLocaleString()}
                  </p>
                  <p className="text-sm text-gray-500">{tx.description}</p>
                </div>
                <div className="text-right">
                  <p className="text-sm text-gray-900">
                    {new Date(tx.date).toLocaleDateString('en-US', {
                      month: 'short',
                      day: 'numeric',
                      year: 'numeric',
                    })}
                  </p>
                  {tx.pending && (
                    <span className="text-xs text-amber-600">Pending</span>
                  )}
                </div>
              </div>
            ))
          ) : (
            <div className="p-8 text-center text-gray-500">
              No transaction history available
            </div>
          )}
        </div>
      </div>

      {/* Notes Section */}
      <div className="bg-white rounded-xl border border-gray-200 p-4">
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-2">
            <MessageSquare className="w-5 h-5 text-gray-400" />
            <h3 className="font-semibold text-gray-900">Notes</h3>
          </div>
          {!showNotes && (
            <button
              onClick={() => setShowNotes(true)}
              className="text-sm text-indigo-600 hover:underline"
            >
              {bill.notes ? 'Edit' : 'Add note'}
            </button>
          )}
        </div>

        {showNotes ? (
          <div className="space-y-3">
            <textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="Add notes about this bill..."
              className="w-full px-3 py-2 border border-gray-200 rounded-lg resize-none"
              rows={3}
            />
            <div className="flex gap-2">
              <button
                onClick={saveNotes}
                disabled={updating}
                className="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 disabled:opacity-50"
              >
                {updating ? 'Saving...' : 'Save'}
              </button>
              <button
                onClick={() => {
                  setNotes(bill.notes || '');
                  setShowNotes(false);
                }}
                className="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50"
              >
                Cancel
              </button>
            </div>
          </div>
        ) : (
          <p className="text-gray-600">
            {bill.notes || 'No notes yet'}
          </p>
        )}
      </div>

      {/* Related Documents */}
      {bill.relatedDocuments && bill.relatedDocuments.length > 0 && (
        <div className="bg-white rounded-xl border border-gray-200 p-4">
          <div className="flex items-center justify-between mb-3">
            <div className="flex items-center gap-2">
              <FileText className="w-5 h-5 text-gray-400" />
              <h3 className="font-semibold text-gray-900">Related Documents</h3>
            </div>
            <button className="text-sm text-indigo-600 hover:underline">
              + Link document
            </button>
          </div>
          <div className="space-y-2">
            {bill.relatedDocuments.map((doc) => (
              <Link
                key={doc.id}
                href={`/app/vault?doc=${doc.id}`}
                className="flex items-center gap-3 p-2 hover:bg-gray-50 rounded-lg"
              >
                <FileText className="w-4 h-4 text-gray-400" />
                <span className="text-sm text-gray-900">{doc.title}</span>
              </Link>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
