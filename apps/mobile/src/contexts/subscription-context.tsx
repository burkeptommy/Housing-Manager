import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import {
  SubscriptionTier,
  TierDetails,
  TIER_DETAILS,
  getManagerInfo,
  getHandymanInfo,
  isEssentialsTier,
  hasHumanManager as checkHumanManager,
} from '../lib/subscription';
import { useAuth } from './auth-context';
import { API_BASE_URL } from '../lib/api';
import { getIdToken } from '../lib/firebase';

// =============================================================================
// TYPES
// =============================================================================

interface ManagerInfo {
  name: string;
  title: string;
  isAI: boolean;
}

interface HandymanInfo {
  hasIncluded: boolean;
  hoursIncluded: number;
  pricePerHour: number;
}

interface SubscriptionContextType {
  tier: SubscriptionTier;
  tierDetails: TierDetails;
  managerInfo: ManagerInfo;
  handymanInfo: HandymanInfo;
  isEssentials: boolean;
  hasHumanManager: boolean;
  loading: boolean;
  error: string | null;
  refreshSubscription: () => Promise<void>;
}

// =============================================================================
// CONTEXT
// =============================================================================

const SubscriptionContext = createContext<SubscriptionContextType | undefined>(undefined);

// =============================================================================
// PROVIDER
// =============================================================================

export function SubscriptionProvider({ children }: { children: React.ReactNode }) {
  const { user, householdInfo } = useAuth();
  const [tier, setTier] = useState<SubscriptionTier>('essentials');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchSubscription = useCallback(async () => {
    if (!user || !householdInfo?.id) {
      setTier('essentials');
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      setError(null);
      
      const token = await getIdToken(true);
      if (!token) {
        setTier('essentials');
        setLoading(false);
        return;
      }

      const response = await fetch(
        `${API_BASE_URL}/subscription/current?householdId=${householdInfo.id}`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
        }
      );

      if (response.ok) {
        const data = await response.json();
        // Map API tier to our tier type
        const apiTier = data.tier?.toLowerCase() || 'essentials';
        if (apiTier in TIER_DETAILS) {
          setTier(apiTier as SubscriptionTier);
        } else {
          setTier('essentials');
        }
      } else {
        // Default to essentials if no subscription found
        setTier('essentials');
      }
    } catch (err) {
      console.error('Failed to fetch subscription:', err);
      setError('Failed to load subscription');
      setTier('essentials');
    } finally {
      setLoading(false);
    }
  }, [user, householdInfo?.id]);

  useEffect(() => {
    fetchSubscription();
  }, [fetchSubscription]);

  const value: SubscriptionContextType = {
    tier,
    tierDetails: TIER_DETAILS[tier],
    managerInfo: getManagerInfo(tier),
    handymanInfo: getHandymanInfo(tier),
    isEssentials: isEssentialsTier(tier),
    hasHumanManager: checkHumanManager(tier),
    loading,
    error,
    refreshSubscription: fetchSubscription,
  };

  return (
    <SubscriptionContext.Provider value={value}>
      {children}
    </SubscriptionContext.Provider>
  );
}

// =============================================================================
// HOOK
// =============================================================================

export function useSubscription() {
  const context = useContext(SubscriptionContext);
  if (context === undefined) {
    throw new Error('useSubscription must be used within a SubscriptionProvider');
  }
  return context;
}

// =============================================================================
// DEVELOPMENT HELPER
// =============================================================================

/**
 * Mock subscription provider for development/testing
 * Allows setting a specific tier without API calls
 */
export function MockSubscriptionProvider({ 
  children, 
  tier = 'essentials' 
}: { 
  children: React.ReactNode;
  tier?: SubscriptionTier;
}) {
  const value: SubscriptionContextType = {
    tier,
    tierDetails: TIER_DETAILS[tier],
    managerInfo: getManagerInfo(tier),
    handymanInfo: getHandymanInfo(tier),
    isEssentials: isEssentialsTier(tier),
    hasHumanManager: checkHumanManager(tier),
    loading: false,
    error: null,
    refreshSubscription: async () => {},
  };

  return (
    <SubscriptionContext.Provider value={value}>
      {children}
    </SubscriptionContext.Provider>
  );
}
