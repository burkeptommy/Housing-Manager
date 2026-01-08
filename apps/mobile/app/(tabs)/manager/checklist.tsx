import React, { useEffect } from 'react';
import { useRouter } from 'expo-router';
import { LoadingSpinner } from '../../../src/components';

/**
 * Maintenance Checklist - Redirects to the main checklist screen
 */
export default function ManagerChecklistScreen() {
  const router = useRouter();

  useEffect(() => {
    // Redirect to the actual checklist screen
    router.replace('/(tabs)/maintenance/checklist' as any);
  }, [router]);

  return <LoadingSpinner fullScreen message="Loading checklist..." />;
}
