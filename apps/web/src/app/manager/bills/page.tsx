'use client';

import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '@/contexts/auth-context';
import { getIdToken } from '@/lib/firebase';
import {
  Home,
  Clock,
  CheckCircle,
  DollarSign,
  Building2,
  CreditCard,
  Banknote,
  Loader2,
} from 'lucide-react';
import Link from 'next/link';

interface ManagedBill {
  id: string;
  merchantName: string;
  category: string;
  averageAmount: number;
  frequency: string;
  nextExpectedDate: string;
  managementStatus: string;
  paymentMethod: string | null;
  household: {
    id: string;
    name: string;
  };
}

export default function ManagerBillsPage() {
  const { user } = useAuth();
  const [bills, setBills] = useState<ManagedBill[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<'all' | 'pending_setup' | 'haven_managed'>('pending_setup');

  const loadBills = useCallback(async () => {
    try {
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      const response = await fetch(`${apiUrl}/manager/bills?filter=${filter}`, {
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
  }, [filter]);

  useEffect(() => {
    loadBills();
  }, [loadBills]);

  const pendingSetup = bills.filter((b) => b.managementStatus === 'PENDING_SETUP');
  const havenManaged = bills.filter((b) => b.managementStatus === 'HAVEN_MANAGED');

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Bill Management</h1>
        <p className="text-gray-500">
          Set up and manage bills for your households
        </p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 gap-4">
        <div className="bg-amber-50 border border-amber-200 rounded-xl p-4">
          <div className="flex items-center gap-3">
            <Clock className="w-6 h-6 text-amber-600" />
            <div>
              <p className="text-2xl font-bold text-gray-900">{pendingSetup.length}</p>
              <p className="text-sm text-amber-700">Pending Setup</p>
            </div>
          </div>
        </div>
        <div className="bg-green-50 border border-green-200 rounded-xl p-4">
          <div className="flex items-center gap-3">
            <CheckCircle className="w-6 h-6 text-green-600" />
            <div>
              <p className="text-2xl font-bold text-gray-900">{havenManaged.length}</p>
              <p className="text-sm text-green-700">Active Managed</p>
            </div>
          </div>
        </div>
      </div>

      {/* Filter Tabs */}
      <div className="flex gap-2">
        <button
          onClick={() => setFilter('pending_setup')}
          className={`px-4 py-2 rounded-lg font-medium ${
            filter === 'pending_setup'
              ? 'bg-amber-100 text-amber-800'
              : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
          }`}
        >
          Pending Setup ({pendingSetup.length})
        </button>
        <button
          onClick={() => setFilter('haven_managed')}
          className={`px-4 py-2 rounded-lg font-medium ${
            filter === 'haven_managed'
              ? 'bg-green-100 text-green-800'
              : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
          }`}
        >
          Active ({havenManaged.length})
        </button>
        <button
          onClick={() => setFilter('all')}
          className={`px-4 py-2 rounded-lg font-medium ${
            filter === 'all'
              ? 'bg-indigo-100 text-indigo-800'
              : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
          }`}
        >
          All
        </button>
      </div>

      {/* Bills List */}
      {loading ? (
        <div className="flex items-center justify-center h-32">
          <Loader2 className="w-6 h-6 animate-spin text-indigo-600" />
        </div>
      ) : bills.length === 0 ? (
        <div className="text-center py-12 text-gray-500">
          No bills to manage
        </div>
      ) : (
        <div className="space-y-3">
          {bills.map((bill) => (
            <Link
              key={bill.id}
              href={`/manager/bills/${bill.id}`}
              className="block bg-white rounded-xl border border-gray-200 p-4 hover:shadow-md transition"
            >
              <div className="flex items-center gap-4">
                <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${
                  bill.managementStatus === 'PENDING_SETUP'
                    ? 'bg-amber-100'
                    : 'bg-green-100'
                }`}>
                  {bill.managementStatus === 'PENDING_SETUP' ? (
                    <Clock className="w-5 h-5 text-amber-600" />
                  ) : (
                    <CheckCircle className="w-5 h-5 text-green-600" />
                  )}
                </div>
                <div className="flex-1">
                  <p className="font-medium text-gray-900">{bill.merchantName}</p>
                  <p className="text-sm text-gray-500">
                    {bill.household.name} • ${bill.averageAmount}/{bill.frequency.toLowerCase()}
                  </p>
                </div>
                <div className="text-right">
                  <p className="text-sm text-gray-500">Next: {new Date(bill.nextExpectedDate).toLocaleDateString()}</p>
                  {bill.paymentMethod && (
                    <p className="text-xs text-green-600">{bill.paymentMethod}</p>
                  )}
                </div>
              </div>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
