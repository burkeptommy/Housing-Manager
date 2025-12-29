'use client';

import { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { usePlaidLink } from 'react-plaid-link';
import { useAuth } from '@/contexts/auth-context';
import { getIdToken } from '@/lib/firebase';
import {
  Building2,
  Plus,
  Loader2,
  CheckCircle,
  AlertCircle,
  RefreshCw,
  Trash2,
  Banknote,
} from 'lucide-react';
import Link from 'next/link';

interface PlaidConnection {
  id: string;
  institutionName: string;
  status: string;
  lastSyncedAt: string;
  accounts: Array<{
    id: string;
    name: string;
    type: string;
    mask: string;
    currentBalance: number;
  }>;
}

interface DetectedBillsSummary {
  totalDetected: number;
  pending: number;
  confirmed: number;
  estimatedMonthlyTotal: number;
}

export default function ConnectBankPage() {
  const router = useRouter();
  const { user } = useAuth();
  const [linkToken, setLinkToken] = useState<string | null>(null);
  const [connections, setConnections] = useState<PlaidConnection[]>([]);
  const [summary, setSummary] = useState<DetectedBillsSummary | null>(null);
  const [loading, setLoading] = useState(true);
  const [syncing, setSyncing] = useState<string | null>(null);

  const householdId = user?.householdId;

  const loadData = useCallback(async () => {
    if (!householdId) return;
    try {
      const token = await getIdToken();
      const apiUrl =
        process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      const [connectionsRes, summaryRes] = await Promise.all([
        fetch(`${apiUrl}/plaid/connections/${householdId}`, {
          headers: { Authorization: `Bearer ${token}` },
        }),
        fetch(`${apiUrl}/plaid/bills/${householdId}/summary`, {
          headers: { Authorization: `Bearer ${token}` },
        }),
      ]);

      if (connectionsRes.ok) setConnections(await connectionsRes.json());
      if (summaryRes.ok) setSummary(await summaryRes.json());
    } catch (error) {
      console.error('Failed to load data:', error);
    } finally {
      setLoading(false);
    }
  }, [householdId]);

  const createLinkToken = useCallback(async () => {
    if (!householdId) return;
    try {
      const token = await getIdToken();
      const apiUrl =
        process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      const response = await fetch(`${apiUrl}/plaid/link-token`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ householdId }),
      });

      if (response.ok) {
        const data = await response.json();
        setLinkToken(data.linkToken);
      }
    } catch (error) {
      console.error('Failed to create link token:', error);
    }
  }, [householdId]);

  useEffect(() => {
    if (householdId) {
      loadData();
      createLinkToken();
    }
  }, [householdId, loadData, createLinkToken]);

  const onPlaidSuccess = useCallback(
    async (publicToken: string) => {
      try {
        setLoading(true);
        const token = await getIdToken();
        const apiUrl =
          process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

        await fetch(`${apiUrl}/plaid/exchange-token`, {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ householdId, publicToken }),
        });

        // Reload data
        await loadData();

        // Navigate to bills review
        router.push('/app/money/bills');
      } catch (error) {
        console.error('Failed to exchange token:', error);
      }
    },
    [householdId, router, loadData],
  );

  const { open, ready } = usePlaidLink({
    token: linkToken,
    onSuccess: onPlaidSuccess,
  });

  const handleSync = async (connectionId: string) => {
    try {
      setSyncing(connectionId);
      const token = await getIdToken();
      const apiUrl =
        process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      await fetch(`${apiUrl}/plaid/connections/${connectionId}/sync`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}` },
      });

      await loadData();
    } catch (error) {
      console.error('Sync failed:', error);
    } finally {
      setSyncing(null);
    }
  };

  const handleRemove = async (connectionId: string) => {
    if (!confirm('Remove this bank connection? Detected bills will be deleted.'))
      return;

    try {
      const token = await getIdToken();
      const apiUrl =
        process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      await fetch(
        `${apiUrl}/plaid/connections/${connectionId}?householdId=${householdId}`,
        {
          method: 'DELETE',
          headers: { Authorization: `Bearer ${token}` },
        },
      );

      await loadData();
    } catch (error) {
      console.error('Remove failed:', error);
    }
  };

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
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Connected Accounts</h1>
        <p className="text-gray-500">
          Connect your bank to auto-detect recurring bills
        </p>
      </div>

      {/* Summary Card */}
      {summary && summary.totalDetected > 0 && (
        <div className="bg-green-50 border border-green-200 rounded-xl p-4">
          <div className="flex items-center gap-3">
            <CheckCircle className="w-6 h-6 text-green-600" />
            <div>
              <p className="font-medium text-green-800">
                Found {summary.totalDetected} recurring charges
              </p>
              <p className="text-sm text-green-600">
                Estimated ${summary.estimatedMonthlyTotal.toLocaleString()}/month
                {summary.pending > 0 && ` - ${summary.pending} pending review`}
              </p>
            </div>
            {summary.pending > 0 && (
              <Link href="/app/money/bills" className="ml-auto">
                <button className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 text-sm">
                  Review Bills
                </button>
              </Link>
            )}
          </div>
        </div>
      )}

      {/* Connect Button */}
      <button
        onClick={() => open()}
        disabled={!ready}
        className="w-full p-6 border-2 border-dashed border-gray-300 rounded-xl hover:border-indigo-400 hover:bg-indigo-50 transition-colors flex items-center justify-center gap-3"
      >
        <Plus className="w-6 h-6 text-gray-400" />
        <span className="text-gray-600 font-medium">Connect a Bank Account</span>
      </button>

      {/* Connected Banks */}
      {connections.length > 0 && (
        <div className="space-y-4">
          <h2 className="text-lg font-semibold text-gray-900">Connected Banks</h2>

          {connections.map((connection) => (
            <div
              key={connection.id}
              className="bg-white rounded-xl border border-gray-200 overflow-hidden"
            >
              {/* Bank Header */}
              <div className="p-4 flex items-center gap-4">
                <div className="w-12 h-12 bg-indigo-100 rounded-xl flex items-center justify-center">
                  <Building2 className="w-6 h-6 text-indigo-600" />
                </div>
                <div className="flex-1">
                  <h3 className="font-medium text-gray-900">
                    {connection.institutionName}
                  </h3>
                  <div className="flex items-center gap-2 text-sm text-gray-500">
                    {connection.status === 'ACTIVE' ? (
                      <span className="flex items-center gap-1 text-green-600">
                        <CheckCircle className="w-4 h-4" />
                        Connected
                      </span>
                    ) : (
                      <span className="flex items-center gap-1 text-red-600">
                        <AlertCircle className="w-4 h-4" />
                        {connection.status}
                      </span>
                    )}
                    {connection.lastSyncedAt && (
                      <span>
                        - Synced{' '}
                        {new Date(connection.lastSyncedAt).toLocaleDateString()}
                      </span>
                    )}
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <button
                    onClick={() => handleSync(connection.id)}
                    disabled={syncing === connection.id}
                    className="p-2 text-gray-400 hover:text-gray-600 rounded-lg hover:bg-gray-100"
                    title="Sync transactions"
                  >
                    <RefreshCw
                      className={`w-5 h-5 ${syncing === connection.id ? 'animate-spin' : ''}`}
                    />
                  </button>
                  <button
                    onClick={() => handleRemove(connection.id)}
                    className="p-2 text-gray-400 hover:text-red-600 rounded-lg hover:bg-red-50"
                    title="Remove connection"
                  >
                    <Trash2 className="w-5 h-5" />
                  </button>
                </div>
              </div>

              {/* Accounts List */}
              {connection.accounts.length > 0 && (
                <div className="border-t border-gray-100 divide-y divide-gray-100">
                  {connection.accounts.map((account) => (
                    <div
                      key={account.id}
                      className="px-4 py-3 flex items-center gap-3"
                    >
                      <Banknote className="w-5 h-5 text-gray-400" />
                      <div className="flex-1">
                        <p className="text-sm font-medium text-gray-900">
                          {account.name}
                        </p>
                        <p className="text-xs text-gray-500">
                          {account.type} ---- {account.mask}
                        </p>
                      </div>
                      {account.currentBalance !== null && (
                        <p className="text-sm font-medium text-gray-900">
                          ${account.currentBalance.toLocaleString()}
                        </p>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </div>
          ))}
        </div>
      )}

      {/* Empty State */}
      {connections.length === 0 && (
        <div className="text-center py-8">
          <Building2 className="w-12 h-12 text-gray-300 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">
            No banks connected
          </h3>
          <p className="text-gray-500 max-w-md mx-auto">
            Connect your bank account to automatically detect your recurring bills
            and subscriptions.
          </p>
        </div>
      )}
    </div>
  );
}
