// =============================================================================
// PLAID CONTEXT STUB
// The Plaid SDK is temporarily removed to unblock TestFlight builds.
// This stub provides the same interface without the native SDK dependency.
// TODO: Re-enable Plaid SDK once TestFlight is working
// =============================================================================

import React, { createContext, useContext, useState, useCallback } from 'react';
import { Alert } from 'react-native';
import {
  getConnectedAccounts,
  getDetectedBills,
  PlaidAccount,
  DetectedBill,
} from '../lib/plaid';

interface PlaidState {
  isLoading: boolean;
  isLinking: boolean;
  accounts: PlaidAccount[];
  bills: DetectedBill[];
  error: string | null;
}

interface PlaidContextType extends PlaidState {
  connectBank: (householdId: string) => Promise<{ success: boolean; error?: string }>;
  refreshAccounts: (householdId: string) => Promise<void>;
  refreshBills: (householdId: string) => Promise<void>;
  clearError: () => void;
}

const PlaidContext = createContext<PlaidContextType | null>(null);

export function PlaidProvider({ children }: { children: React.ReactNode }) {
  const [state, setState] = useState<PlaidState>({
    isLoading: false,
    isLinking: false,
    accounts: [],
    bills: [],
    error: null,
  });

  const connectBank = useCallback(
    async (_householdId: string): Promise<{ success: boolean; error?: string }> => {
      // Show coming soon alert
      Alert.alert(
        'Coming Soon',
        'Bank connection will be available in a future update. You can skip this step for now.',
        [{ text: 'OK' }]
      );
      return { success: false, error: 'Bank connection coming soon' };
    },
    []
  );

  const refreshAccounts = useCallback(async (householdId: string) => {
    setState((prev) => ({ ...prev, isLoading: true }));
    try {
      const accounts = await getConnectedAccounts(householdId);
      setState((prev) => ({ ...prev, isLoading: false, accounts }));
    } catch (err: any) {
      setState((prev) => ({ ...prev, isLoading: false, error: err.message }));
    }
  }, []);

  const refreshBills = useCallback(async (householdId: string) => {
    setState((prev) => ({ ...prev, isLoading: true }));
    try {
      const bills = await getDetectedBills(householdId);
      setState((prev) => ({ ...prev, isLoading: false, bills }));
    } catch (err: any) {
      setState((prev) => ({ ...prev, isLoading: false, error: err.message }));
    }
  }, []);

  const clearError = useCallback(() => {
    setState((prev) => ({ ...prev, error: null }));
  }, []);

  return (
    <PlaidContext.Provider
      value={{
        ...state,
        connectBank,
        refreshAccounts,
        refreshBills,
        clearError,
      }}
    >
      {children}
    </PlaidContext.Provider>
  );
}

export function usePlaid() {
  const context = useContext(PlaidContext);
  if (!context) {
    throw new Error('usePlaid must be used within PlaidProvider');
  }
  return context;
}
