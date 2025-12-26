'use client';

import { useState, useCallback } from 'react';
import { getIdToken } from '@/lib/firebase';

export interface PropertyDetails {
  // Basic Info
  bedrooms: number | null;
  bathrooms: number | null;
  bathsFull: number | null;
  bathsHalf: number | null;
  squareFeet: number | null;
  lotSizeSquareFeet: number | null;
  lotSizeAcres: number | null;
  yearBuilt: number | null;

  // Property Type
  propertyType: string | null;
  propertySubType: string | null;

  // Building Details
  stories: number | null;
  constructionType: string | null;
  foundationType: string | null;
  roofType: string | null;
  roofMaterial: string | null;
  exteriorWalls: string | null;

  // Systems (HVAC)
  heatingType: string | null;
  heatingFuel: string | null;
  coolingType: string | null;

  // Utilities
  waterType: string | null;
  sewerType: string | null;

  // Features
  fireplaces: number | null;
  garage: string | null;
  garageSpaces: number | null;
  pool: boolean | null;
  poolType: string | null;

  // Additional Rooms
  totalRooms: number | null;
  basementType: string | null;

  // Valuation
  assessedValue: number | null;
  marketValue: number | null;
  taxAmount: number | null;

  // Location
  verifiedAddress: string | null;
  latitude: number | null;
  longitude: number | null;
}

interface PropertyLookupResult {
  success: boolean;
  data: PropertyDetails | null;
  error?: string;
}

interface UsePropertyEnrichmentResult {
  fetchPropertyDetails: (
    street: string,
    city: string,
    state: string,
    zip: string
  ) => Promise<PropertyDetails | null>;
  isLoading: boolean;
  error: string | null;
  clearError: () => void;
}

export function usePropertyEnrichment(): UsePropertyEnrichmentResult {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const clearError = useCallback(() => setError(null), []);

  const fetchPropertyDetails = useCallback(
    async (
      street: string,
      city: string,
      state: string,
      zip: string
    ): Promise<PropertyDetails | null> => {
      setIsLoading(true);
      setError(null);

      try {
        const token = await getIdToken();
        if (!token) {
          throw new Error('Not authenticated');
        }

        const params = new URLSearchParams({ street, city, state, zip });
        const apiUrl =
          process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

        console.log(
          `Fetching property details for: ${street}, ${city}, ${state} ${zip}`
        );

        const response = await fetch(`${apiUrl}/property/lookup?${params}`, {
          headers: {
            Authorization: `Bearer ${token}`,
          },
        });

        if (!response.ok) {
          const errorData = await response.json().catch(() => ({}));
          throw new Error(
            errorData.message || 'Failed to fetch property details'
          );
        }

        const result: PropertyLookupResult = await response.json();
        console.log('Property lookup result:', result);

        if (!result.success || !result.data) {
          // Property not found - not necessarily an error, just no data available
          console.log('Property not found:', result.error);
          return null;
        }

        return result.data;
      } catch (err) {
        const message =
          err instanceof Error ? err.message : 'Failed to fetch property details';
        setError(message);
        console.error('Property enrichment error:', err);
        return null;
      } finally {
        setIsLoading(false);
      }
    },
    []
  );

  return { fetchPropertyDetails, isLoading, error, clearError };
}
