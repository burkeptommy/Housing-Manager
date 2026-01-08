'use client';

import React, { createContext, useContext, useState, useEffect } from 'react';
import { useAuth } from './auth-context';
import { getAccessToken, API_BASE_URL } from '@/lib/api';

type SubscriptionTier =
  | 'essentials'
  | 'lite'
  | 'haven'
  | 'haven_plus'
  | 'estate';

interface SubscriptionContextType {
  tier: SubscriptionTier;
  isEssentials: boolean;
  hasHumanManager: boolean;
  managerName: string;
  loading: boolean;
}

const SubscriptionContext = createContext<SubscriptionContextType | undefined>(
  undefined
);

export function SubscriptionProvider({
  children,
}: {
  children: React.ReactNode;
}) {
  const { user, isAuthenticated } = useAuth();
  const [tier, setTier] = useState<SubscriptionTier>('essentials');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchSubscription = async () => {
      if (!isAuthenticated || !user) {
        setTier('essentials');
        setLoading(false);
        return;
      }

      try {
        const token = getAccessToken();
        if (!token) {
          setTier('essentials');
          setLoading(false);
          return;
        }

        const response = await fetch(`${API_BASE_URL}/subscription/current`, {
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
        });

        if (response.ok) {
          const data = await response.json();
          setTier(data?.tier || 'essentials');
        } else {
          setTier('essentials');
        }
      } catch (error) {
        console.error('Failed to fetch subscription:', error);
        setTier('essentials');
      } finally {
        setLoading(false);
      }
    };

    fetchSubscription();
  }, [isAuthenticated, user]);

  const managerNames: Record<SubscriptionTier, string> = {
    essentials: 'Alfred',
    lite: 'Sarah Chen',
    haven: 'Sarah Chen',
    haven_plus: 'Sarah Chen',
    estate: 'Sarah Chen',
  };

  const value = {
    tier,
    isEssentials: tier === 'essentials',
    hasHumanManager: tier !== 'essentials',
    managerName: managerNames[tier],
    loading,
  };

  return (
    <SubscriptionContext.Provider value={value}>
      {children}
    </SubscriptionContext.Provider>
  );
}

export function useSubscription() {
  const context = useContext(SubscriptionContext);
  if (!context) {
    // Return defaults if used outside provider
    return {
      tier: 'essentials' as SubscriptionTier,
      isEssentials: true,
      hasHumanManager: false,
      managerName: 'Alfred',
      loading: false,
    };
  }
  return context;
}
