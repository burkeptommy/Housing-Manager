'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getApiClient } from '@/lib/api';
import type {
  WorkOrder,
  WorkOrderStatus,
  CreateWorkOrderRequest,
} from '@haven/core';

// Query keys for caching
export const workOrderKeys = {
  all: ['work-orders'] as const,
  list: (householdId: string) => [...workOrderKeys.all, 'list', householdId] as const,
  listWithFilters: (householdId: string, filters: { status?: WorkOrderStatus; includeCompleted?: boolean }) =>
    [...workOrderKeys.list(householdId), filters] as const,
  detail: (id: string) => [...workOrderKeys.all, 'detail', id] as const,
};

/**
 * Hook to fetch work orders for a household
 */
export function useWorkOrders(
  householdId: string | undefined,
  options?: { status?: WorkOrderStatus; includeCompleted?: boolean }
) {
  const api = getApiClient();

  return useQuery({
    queryKey: workOrderKeys.listWithFilters(householdId ?? '', options ?? {}),
    queryFn: async (): Promise<WorkOrder[]> => {
      if (!householdId) {
        throw new Error('No household ID provided');
      }
      return api.getWorkOrders(householdId, options);
    },
    enabled: !!householdId,
  });
}

/**
 * Hook to fetch a single work order
 */
export function useWorkOrder(workOrderId: string | undefined) {
  const api = getApiClient();

  return useQuery({
    queryKey: workOrderKeys.detail(workOrderId ?? ''),
    queryFn: async (): Promise<WorkOrder> => {
      if (!workOrderId) {
        throw new Error('No work order ID provided');
      }
      return api.getWorkOrder(workOrderId);
    },
    enabled: !!workOrderId,
  });
}

/**
 * Hook to create a new work order
 */
export function useCreateWorkOrder() {
  const queryClient = useQueryClient();
  const api = getApiClient();

  return useMutation({
    mutationFn: async ({
      householdId,
      data,
    }: {
      householdId: string;
      data: CreateWorkOrderRequest;
    }) => {
      return api.createWorkOrder(householdId, data);
    },
    onSuccess: () => {
      // Invalidate work orders queries to refetch fresh data
      queryClient.invalidateQueries({ queryKey: workOrderKeys.all });
    },
  });
}

/**
 * Hook to invalidate work orders cache
 */
export function useInvalidateWorkOrders() {
  const queryClient = useQueryClient();

  return () => {
    queryClient.invalidateQueries({ queryKey: workOrderKeys.all });
  };
}
