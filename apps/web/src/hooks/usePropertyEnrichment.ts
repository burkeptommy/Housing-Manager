import { useState, useCallback } from 'react';

export interface PropertyEnrichmentData {
  address: {
    addressLine1: string;
    city: string;
    state: string;
    zipCode: string;
    plus4: string;
    formattedAddress: string;
  };
  property: {
    bedrooms: number | null;
    bathrooms: number | null;
    squareFeet: number | null;
    yearBuilt: number | null;
    lotSizeAcres: number | null;
    lotSizeSqFt: number | null;
    propertyType: string | null;
    stories: number | null;
    pool: boolean;
    garage: string | null;
    garageSqFt: number | null;
    roofType: string | null;
    hvacType: string | null;
    foundation: string | null;
    exteriorWalls: string | null;
  };
  valuation: {
    estimatedValue: number | null;
    assessedValue: number | null;
    taxAmount: number | null;
    taxYear: number | null;
  };
  parcel: {
    apn: string | null;
    fipsCode: string | null;
    county: string | null;
    legalDescription: string | null;
  };
}

export interface PropertyEnrichmentResult {
  success: boolean;
  data?: PropertyEnrichmentData;
  error?: string;
}

export function usePropertyEnrichment() {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [data, setData] = useState<PropertyEnrichmentData | null>(null);

  const enrichProperty = useCallback(
    async (
      addressLine1: string,
      city?: string,
      state?: string,
      zip?: string,
    ): Promise<PropertyEnrichmentResult> => {
      setIsLoading(true);
      setError(null);

      try {
        const baseUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';
        const params = new URLSearchParams({
          addressLine1,
          ...(city && { city }),
          ...(state && { state }),
          ...(zip && { zip }),
        });

        const response = await fetch(
          `${baseUrl}/property/enrich?${params.toString()}`,
          {
            headers: {
              Authorization: `Bearer ${sessionStorage.getItem('haven_firebase_token') || ''}`,
              'Content-Type': 'application/json',
            },
          },
        );

        if (!response.ok) {
          throw new Error('Failed to fetch property data');
        }

        const result: PropertyEnrichmentResult = await response.json();

        if (result.success && result.data) {
          setData(result.data);
          return result;
        } else {
          setError(result.error || 'No property data found');
          return result;
        }
      } catch (err) {
        const message = err instanceof Error ? err.message : 'Unknown error';
        setError(message);
        return { success: false, error: message };
      } finally {
        setIsLoading(false);
      }
    },
    [],
  );

  const clearData = useCallback(() => {
    setData(null);
    setError(null);
  }, []);

  return {
    enrichProperty,
    isLoading,
    error,
    data,
    clearData,
  };
}
