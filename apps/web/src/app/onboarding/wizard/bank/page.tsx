'use client';

import { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { usePlaidLink } from 'react-plaid-link';
import {
  Building2,
  ArrowRight,
  ArrowLeft,
  Plus,
  CheckCircle,
  Loader2,
} from 'lucide-react';
import { SkipToHumanBanner } from '@/components/onboarding/SkipToHumanBanner';
import { useOnboarding } from '@/context/OnboardingContext';
import { useAuth } from '@/contexts/auth-context';
import { getIdToken } from '@/lib/firebase';

export default function BankConnectionPage() {
  const router = useRouter();
  const { user } = useAuth();
  const { completeStep } = useOnboarding();

  const [linkToken, setLinkToken] = useState<string | null>(null);
  const [connectedBanks, setConnectedBanks] = useState<number>(0);
  const [detectedBillCount, setDetectedBillCount] = useState<number>(0);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const householdId = user?.householdId;
  const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

  // Create link token when page loads
  const createLinkToken = useCallback(async () => {
    if (!householdId) return;

    try {
      const token = await getIdToken();
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
      } else {
        console.error('Failed to create link token');
      }
    } catch (err) {
      console.error('Error creating link token:', err);
    }
  }, [householdId, apiUrl]);

  // Load existing connections
  const loadConnections = useCallback(async () => {
    if (!householdId) return;

    try {
      const token = await getIdToken();
      const [connectionsRes, summaryRes] = await Promise.all([
        fetch(`${apiUrl}/plaid/connections/${householdId}`, {
          headers: { Authorization: `Bearer ${token}` },
        }),
        fetch(`${apiUrl}/plaid/bills/${householdId}/summary`, {
          headers: { Authorization: `Bearer ${token}` },
        }),
      ]);

      if (connectionsRes.ok) {
        const connections = await connectionsRes.json();
        setConnectedBanks(connections.length);
      }

      if (summaryRes.ok) {
        const summary = await summaryRes.json();
        setDetectedBillCount(summary.totalDetected);
      }
    } catch (err) {
      console.error('Error loading connections:', err);
    }
  }, [householdId, apiUrl]);

  useEffect(() => {
    if (householdId) {
      createLinkToken();
      loadConnections();
    }
  }, [householdId, createLinkToken, loadConnections]);

  // Handle Plaid Link success
  const onPlaidSuccess = useCallback(
    async (publicToken: string) => {
      if (!householdId) return;

      try {
        setLoading(true);
        setError(null);
        const token = await getIdToken();

        const response = await fetch(`${apiUrl}/plaid/exchange-token`, {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ householdId, publicToken }),
        });

        if (response.ok) {
          setConnectedBanks((prev) => prev + 1);

          // Get updated detected bills count
          const summaryRes = await fetch(`${apiUrl}/plaid/bills/${householdId}/summary`, {
            headers: { Authorization: `Bearer ${token}` },
          });
          if (summaryRes.ok) {
            const summary = await summaryRes.json();
            setDetectedBillCount(summary.totalDetected);
          }

          // Create a new link token for adding more banks
          await createLinkToken();
        } else {
          setError('Failed to connect bank. Please try again.');
        }
      } catch (err) {
        console.error('Failed to exchange token:', err);
        setError('Failed to connect bank. Please try again.');
      } finally {
        setLoading(false);
      }
    },
    [householdId, apiUrl, createLinkToken]
  );

  const { open, ready } = usePlaidLink({
    token: linkToken,
    onSuccess: onPlaidSuccess,
  });

  const handleContinue = () => {
    completeStep('bank');
    router.push('/onboarding/wizard/systems');
  };

  return (
    <div className="max-w-2xl mx-auto px-4 py-8">
      <SkipToHumanBanner />

      {/* Header */}
      <div className="text-center mb-8">
        <div className="w-14 h-14 bg-indigo-100 rounded-2xl flex items-center justify-center mx-auto mb-4">
          <Building2 className="w-7 h-7 text-indigo-600" />
        </div>
        <h1 className="text-2xl font-bold text-haven-900 mb-2">Connect your bank</h1>
        <p className="text-gray-600">
          We'll automatically detect your recurring bills so you don't have to enter them
          manually.
        </p>
        <p className="text-sm text-gray-400 mt-2">Optional - you can skip and add bills manually</p>
      </div>

      {/* Connect Button */}
      <div className="bg-white rounded-2xl border border-gray-200 p-6 mb-6">
        <button
          onClick={() => open()}
          disabled={!ready || loading}
          className="w-full p-4 border-2 border-dashed border-gray-300 rounded-xl hover:border-indigo-400 hover:bg-indigo-50 transition flex items-center justify-center gap-3 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {loading ? (
            <Loader2 className="w-5 h-5 text-gray-400 animate-spin" />
          ) : (
            <Plus className="w-5 h-5 text-gray-400" />
          )}
          <span className="text-gray-600 font-medium">
            {loading ? 'Connecting...' : 'Connect Bank Account'}
          </span>
        </button>

        {error && <p className="text-red-500 text-sm text-center mt-3">{error}</p>}

        {/* Success State */}
        {connectedBanks > 0 && (
          <div className="mt-4 p-4 bg-green-50 border border-green-200 rounded-xl">
            <div className="flex items-center gap-2 text-green-700">
              <CheckCircle className="w-5 h-5" />
              <span className="font-medium">
                {connectedBanks} bank{connectedBanks > 1 ? 's' : ''} connected!
              </span>
            </div>
            {detectedBillCount > 0 && (
              <p className="text-green-600 text-sm mt-1">
                Found {detectedBillCount} recurring charge{detectedBillCount > 1 ? 's' : ''}
              </p>
            )}
          </div>
        )}
      </div>

      {/* Info */}
      <div className="bg-gray-50 rounded-xl p-4 mb-8">
        <h3 className="font-medium text-haven-900 mb-2">Why connect your bank?</h3>
        <ul className="space-y-2 text-sm text-gray-600">
          <li className="flex items-start gap-2">
            <CheckCircle className="w-4 h-4 text-green-500 mt-0.5 flex-shrink-0" />
            <span>Automatically detect recurring bills like utilities, subscriptions, and insurance</span>
          </li>
          <li className="flex items-start gap-2">
            <CheckCircle className="w-4 h-4 text-green-500 mt-0.5 flex-shrink-0" />
            <span>See your estimated monthly expenses at a glance</span>
          </li>
          <li className="flex items-start gap-2">
            <CheckCircle className="w-4 h-4 text-green-500 mt-0.5 flex-shrink-0" />
            <span>Your data is encrypted and we never store your login credentials</span>
          </li>
        </ul>
      </div>

      {/* Navigation */}
      <div className="flex justify-between">
        <Link
          href="/onboarding/wizard/bills"
          className="text-gray-600 hover:text-haven-900 py-3 px-4 font-medium flex items-center gap-2 transition-colors"
        >
          <ArrowLeft className="w-4 h-4" />
          Back
        </Link>
        <button
          onClick={handleContinue}
          className="bg-haven-900 hover:bg-haven-800 text-white py-3 px-6 rounded-xl font-medium flex items-center gap-2 transition-colors"
        >
          {connectedBanks > 0 ? 'Continue' : 'Skip for now'}
          <ArrowRight className="w-4 h-4" />
        </button>
      </div>
    </div>
  );
}
