'use client';

import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useState } from 'react';

export function QueryProvider({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: {
            // Stale time: data is considered fresh for 1 minute
            staleTime: 60 * 1000,
            // Cache time: unused data is garbage collected after 5 minutes
            gcTime: 5 * 60 * 1000,
            // Refetch on window focus for fresh data
            refetchOnWindowFocus: true,
            // Retry failed requests 2 times
            retry: 2,
          },
        },
      })
  );

  return (
    <QueryClientProvider client={queryClient}>
      {children}
    </QueryClientProvider>
  );
}
