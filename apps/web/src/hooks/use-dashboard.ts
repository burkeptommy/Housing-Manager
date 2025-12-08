'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getApiClient } from '@/lib/api';
import type {
  DashboardResponse,
  BillAccount,
  MaintenanceTask,
} from '@haven/core';

// Query keys for caching
export const dashboardKeys = {
  all: ['dashboard'] as const,
  data: (householdId: string) => [...dashboardKeys.all, 'data', householdId] as const,
  bills: (householdId: string) => [...dashboardKeys.all, 'bills', householdId] as const,
  tasks: (householdId: string) => [...dashboardKeys.all, 'tasks', householdId] as const,
};

/**
 * Hook to fetch dashboard data including summary, upcoming bills, and tasks
 */
export function useDashboard(householdId: string | undefined) {
  const api = getApiClient();

  return useQuery({
    queryKey: dashboardKeys.data(householdId ?? ''),
    queryFn: async (): Promise<DashboardResponse> => {
      if (!householdId) {
        throw new Error('No household ID provided');
      }
      return api.getDashboard(householdId);
    },
    enabled: !!householdId,
    // Refetch every 5 minutes for real-time updates
    refetchInterval: 5 * 60 * 1000,
  });
}

/**
 * Hook to fetch bill accounts
 */
export function useBillAccounts(householdId: string | undefined) {
  const api = getApiClient();

  return useQuery({
    queryKey: dashboardKeys.bills(householdId ?? ''),
    queryFn: async (): Promise<BillAccount[]> => {
      if (!householdId) {
        throw new Error('No household ID provided');
      }
      return api.getBillAccounts(householdId);
    },
    enabled: !!householdId,
  });
}

/**
 * Hook to fetch maintenance tasks
 */
export function useMaintenanceTasks(
  householdId: string | undefined,
  options?: { status?: string; category?: string }
) {
  const api = getApiClient();

  return useQuery({
    queryKey: [...dashboardKeys.tasks(householdId ?? ''), options],
    queryFn: async (): Promise<MaintenanceTask[]> => {
      if (!householdId) {
        throw new Error('No household ID provided');
      }
      return api.getMaintenanceTasks(householdId, options);
    },
    enabled: !!householdId,
  });
}

/**
 * Hook to request Haven to handle a bill (updates payment responsibility)
 */
export function useRequestHavenHandle() {
  const queryClient = useQueryClient();
  const api = getApiClient();

  return useMutation({
    mutationFn: async ({
      billId,
      maxAutoPayAmount,
    }: {
      billId: string;
      maxAutoPayAmount?: number;
    }) => {
      return api.updateBillAccount(billId, {
        paymentResponsibility: 'HAVEN_PAYS_ON_BEHALF',
        havenAutoPayEnabled: true,
        maxAutoPayAmount,
      });
    },
    onSuccess: () => {
      // Invalidate dashboard queries to refetch fresh data
      queryClient.invalidateQueries({ queryKey: dashboardKeys.all });
    },
  });
}

/**
 * Hook to invalidate dashboard cache (useful after creating bills/tasks)
 */
export function useInvalidateDashboard() {
  const queryClient = useQueryClient();

  return () => {
    queryClient.invalidateQueries({ queryKey: dashboardKeys.all });
  };
}
