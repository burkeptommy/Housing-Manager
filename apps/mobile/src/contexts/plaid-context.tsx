// =============================================================================
// PLAID CONTEXT
// React context for managing Plaid bank connections and detected bills
// =============================================================================

import React, { createContext, useContext, useState, useCallback } from 'react';
import { Alert } from 'react-native';
import {
  getLinkToken,
  exchangePublicToken,
  openPlaidLink,
  getConnections,
  getDetectedBills,
  syncTransactions,
  confirmBill as confirmBillApi,
  dismissBill as dismissBillApi,
  PlaidConnection,
  DetectedBill,
  PlaidLinkResult,
} from '../lib/plaid';

interface PlaidState {
  isLoading: boolean;
  isLinking: boolean;
  isSyncing: boolean;
  connections: PlaidConnection[];
  detectedBills: DetectedBill[];
  error: string | null;
}

interface PlaidContextType extends PlaidState {
  connectBank: (householdId: string) => Promise<{ success: boolean; error?: string }>;
  refreshConnections: (householdId: string) => Promise<void>;
  refreshDetectedBills: (householdId: string, status?: string) => Promise<void>;
  syncConnection: (connectionId: string) => Promise<{ billsDetected: number }>;
  confirmBill: (billId: string) => Promise<void>;
  dismissBill: (billId: string) => Promise<void>;
  clearError: () => void;
}

const PlaidContext = createContext<PlaidContextType | null>(null);

export function PlaidProvider({ children }: { children: React.ReactNode }) {
  const [state, setState] = useState<PlaidState>({
    isLoading: false,
    isLinking: false,
    isSyncing: false,
    connections: [],
    detectedBills: [],
    error: null,
  });

  const connectBank = useCallback(
    async (householdId: string): Promise<{ success: boolean; error?: string }> => {
      setState((prev) => ({ ...prev, isLinking: true, error: null }));

      try {
        // Get link token from backend
        const { linkToken } = await getLinkToken(householdId);

        return new Promise((resolve) => {
          openPlaidLink(
            linkToken,
            async (result: PlaidLinkResult) => {
              if (result.success && result.publicToken) {
                try {
                  // Exchange public token
                  const exchangeResult = await exchangePublicToken(
                    result.publicToken,
                    householdId
                  );

                  if (exchangeResult.connectionId) {
                    // Sync transactions immediately
                    setState((prev) => ({ ...prev, isSyncing: true }));
                    try {
                      const syncResult = await syncTransactions(exchangeResult.connectionId);

                      // Refresh data
                      const [connections, bills] = await Promise.all([
                        getConnections(householdId),
                        getDetectedBills(householdId, 'DETECTED'),
                      ]);

                      setState((prev) => ({
                        ...prev,
                        isLinking: false,
                        isSyncing: false,
                        connections,
                        detectedBills: bills,
                      }));

                      if (syncResult.billsDetected > 0) {
                        Alert.alert(
                          'Bills Found!',
                          `We found ${syncResult.billsDetected} recurring bills in your transactions. Review them to add to your bill tracker.`,
                          [{ text: 'OK' }]
                        );
                      }

                      resolve({ success: true });
                    } catch (syncErr) {
                      console.error('Sync error:', syncErr);
                      setState((prev) => ({ ...prev, isLinking: false, isSyncing: false }));
                      resolve({ success: true }); // Bank connected even if sync failed
                    }
                  } else {
                    setState((prev) => ({ ...prev, isLinking: false }));
                    resolve({ success: true });
                  }
                } catch (exchangeErr: unknown) {
                  const message = exchangeErr instanceof Error ? exchangeErr.message : 'Failed to connect bank';
                  setState((prev) => ({ ...prev, isLinking: false, error: message }));
                  resolve({ success: false, error: message });
                }
              } else {
                setState((prev) => ({ ...prev, isLinking: false }));
                resolve({ success: false, error: result.error });
              }
            },
            (exitError) => {
              setState((prev) => ({ ...prev, isLinking: false }));
              if (exitError) {
                resolve({ success: false, error: exitError });
              } else {
                // User cancelled - not an error
                resolve({ success: false });
              }
            }
          );
        });
      } catch (err: unknown) {
        const message = err instanceof Error ? err.message : 'Failed to start bank connection';
        setState((prev) => ({ ...prev, isLinking: false, error: message }));
        return { success: false, error: message };
      }
    },
    []
  );

  const refreshConnections = useCallback(async (householdId: string) => {
    setState((prev) => ({ ...prev, isLoading: true }));
    try {
      const connections = await getConnections(householdId);
      setState((prev) => ({ ...prev, isLoading: false, connections }));
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Failed to load connections';
      setState((prev) => ({ ...prev, isLoading: false, error: message }));
    }
  }, []);

  const refreshDetectedBills = useCallback(async (householdId: string, status?: string) => {
    setState((prev) => ({ ...prev, isLoading: true }));
    try {
      const bills = await getDetectedBills(householdId, status);
      setState((prev) => ({ ...prev, isLoading: false, detectedBills: bills }));
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Failed to load detected bills';
      setState((prev) => ({ ...prev, isLoading: false, error: message }));
    }
  }, []);

  const syncConnection = useCallback(async (connectionId: string) => {
    setState((prev) => ({ ...prev, isSyncing: true }));
    try {
      const result = await syncTransactions(connectionId);
      setState((prev) => ({ ...prev, isSyncing: false }));
      return result;
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Failed to sync transactions';
      setState((prev) => ({ ...prev, isSyncing: false, error: message }));
      throw err;
    }
  }, []);

  const confirmBill = useCallback(async (billId: string) => {
    try {
      await confirmBillApi(billId);
      setState((prev) => ({
        ...prev,
        detectedBills: prev.detectedBills.map((bill) =>
          bill.id === billId ? { ...bill, status: 'CONFIRMED' as const } : bill
        ),
      }));
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Failed to confirm bill';
      setState((prev) => ({ ...prev, error: message }));
      throw err;
    }
  }, []);

  const dismissBill = useCallback(async (billId: string) => {
    try {
      await dismissBillApi(billId);
      setState((prev) => ({
        ...prev,
        detectedBills: prev.detectedBills.filter((bill) => bill.id !== billId),
      }));
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Failed to dismiss bill';
      setState((prev) => ({ ...prev, error: message }));
      throw err;
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
        refreshConnections,
        refreshDetectedBills,
        syncConnection,
        confirmBill,
        dismissBill,
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
