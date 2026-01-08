'use client';

import { useQuery } from '@tanstack/react-query';
import { getAccessToken, API_BASE_URL } from '@/lib/api';

export interface HealthFactor {
  category: string;
  description: string;
  points: number;
  maxPoints: number;
  status: 'positive' | 'negative' | 'neutral';
}

export interface HomeHealthScore {
  score: number;
  maxScore: number;
  grade: 'Excellent' | 'Good' | 'Fair' | 'Needs Attention' | 'Critical';
  factors: HealthFactor[];
  recommendations: string[];
}

// Query keys for caching
export const homeHealthKeys = {
  all: ['homeHealth'] as const,
  score: (householdId: string) => [...homeHealthKeys.all, 'score', householdId] as const,
};

/**
 * Hook to fetch home health score from the API
 */
export function useHomeHealth(householdId: string | undefined) {
  return useQuery({
    queryKey: homeHealthKeys.score(householdId ?? ''),
    queryFn: async (): Promise<HomeHealthScore> => {
      if (!householdId) {
        throw new Error('No household ID provided');
      }

      const token = getAccessToken();
      if (!token) {
        throw new Error('Not authenticated');
      }

      const response = await fetch(
        `${API_BASE_URL}/home-health?householdId=${householdId}`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
        }
      );

      if (!response.ok) {
        throw new Error(`Failed to fetch health score: ${response.status}`);
      }

      return response.json();
    },
    enabled: !!householdId,
    // Refetch every 10 minutes for real-time updates
    refetchInterval: 10 * 60 * 1000,
    // Stale time of 5 minutes
    staleTime: 5 * 60 * 1000,
  });
}
