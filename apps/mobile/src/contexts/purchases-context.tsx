// =============================================================================
// PURCHASES CONTEXT STUB
// react-native-purchases is temporarily stubbed to unblock TestFlight builds.
// The native module is not linked in Expo managed workflow without a config plugin.
// TODO: Add RevenueCat Expo config plugin when ready for production IAP
// =============================================================================

import React, {
  createContext,
  useContext,
  useState,
  useCallback,
} from 'react';
import { Alert } from 'react-native';

// Stub types to match RevenueCat interface
interface CustomerInfo {
  entitlements: {
    active: Record<string, { isActive: boolean }>;
  };
}

interface PurchasesPackage {
  identifier: string;
  packageType: string;
  product: {
    title: string;
    priceString: string;
  };
}

interface PurchasesOffering {
  identifier: string;
  availablePackages: PurchasesPackage[];
}

// Haven tier metadata (kept for UI)
export const TIER_INFO = {
  essentials: {
    name: 'Essentials',
    description: 'Bill consolidation, tracking, reminders',
    monthlyPrice: 39,
    annualPrice: 390,
    features: [
      'Unified bill dashboard',
      'Payment reminders',
      'Document storage',
      'Maintenance calendar',
    ],
    color: '#7C4DFF',
  },
  lite: {
    name: 'Lite',
    description: 'Text-based manager, reactive support',
    monthlyPrice: 349,
    annualPrice: 3490,
    features: [
      'Everything in Essentials',
      'Text your Home Manager',
      'Bill payment service',
      'Vendor coordination',
    ],
    recommended: false,
    color: '#6200EA',
  },
  haven: {
    name: 'Haven',
    description: 'Proactive manager, monthly handyman',
    monthlyPrice: 749,
    annualPrice: 7490,
    features: [
      'Everything in Lite',
      'Proactive care',
      '4 hours handyman/month',
      'Seasonal maintenance',
    ],
    recommended: true,
    color: '#6200EA',
  },
  haven_plus: {
    name: 'Haven+',
    description: 'Lifestyle services, errands',
    monthlyPrice: 1499,
    annualPrice: 14990,
    features: [
      'Everything in Haven',
      '8 hours handyman/month',
      'Errand running',
      'Lifestyle concierge',
    ],
    color: '#2D006B',
  },
  estate: {
    name: 'Estate',
    description: 'Multi-property, white-glove',
    monthlyPrice: 3499,
    annualPrice: 34990,
    features: [
      'Everything in Haven+',
      'Multi-property support',
      'Dedicated manager',
      'White-glove service',
    ],
    color: '#2D006B',
  },
} as const;

export type TierKey = keyof typeof TIER_INFO;

interface PurchasesState {
  isInitialized: boolean;
  isLoading: boolean;
  customerInfo: CustomerInfo | null;
  currentTier: TierKey | null;
  offering: PurchasesOffering | null;
}

interface PurchasesContextType extends PurchasesState {
  purchase: (
    pkg: PurchasesPackage
  ) => Promise<{ success: boolean; error?: string }>;
  restore: () => Promise<{ success: boolean; error?: string }>;
  refresh: () => Promise<void>;
}

const PurchasesContext = createContext<PurchasesContextType | null>(null);

export function PurchasesProvider({ children }: { children: React.ReactNode }) {
  const [state] = useState<PurchasesState>({
    isInitialized: true,
    isLoading: false,
    customerInfo: null,
    currentTier: null,
    offering: null,
  });

  const purchase = useCallback(async (_pkg: PurchasesPackage) => {
    Alert.alert(
      'Coming Soon',
      'In-app purchases will be available in a future update.',
      [{ text: 'OK' }]
    );
    return { success: false, error: 'Purchases coming soon' };
  }, []);

  const restore = useCallback(async () => {
    Alert.alert(
      'Coming Soon',
      'Purchase restoration will be available in a future update.',
      [{ text: 'OK' }]
    );
    return { success: false, error: 'Restore coming soon' };
  }, []);

  const refresh = useCallback(async () => {
    // No-op stub
  }, []);

  return (
    <PurchasesContext.Provider
      value={{
        ...state,
        purchase,
        restore,
        refresh,
      }}
    >
      {children}
    </PurchasesContext.Provider>
  );
}

export function usePurchases() {
  const context = useContext(PurchasesContext);
  if (!context) {
    throw new Error('usePurchases must be used within PurchasesProvider');
  }
  return context;
}
