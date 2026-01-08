// =============================================================================
// PURCHASES LIB STUB
// react-native-purchases is temporarily stubbed to unblock TestFlight builds.
// The native module is not linked in Expo managed workflow without a config plugin.
// TODO: Add RevenueCat Expo config plugin when ready for production IAP
// =============================================================================

// Stub types
export interface CustomerInfo {
  entitlements: {
    active: Record<string, { isActive: boolean }>;
  };
}

export interface PurchasesPackage {
  identifier: string;
  packageType: string;
  product: {
    title: string;
    priceString: string;
  };
}

export interface PurchasesOffering {
  identifier: string;
  availablePackages: PurchasesPackage[];
}

// Haven tier identifiers
export const PRODUCT_IDS = {
  ESSENTIALS_MONTHLY: 'haven_essentials_monthly',
  LITE_MONTHLY: 'haven_lite_monthly',
  HAVEN_MONTHLY: 'haven_monthly',
  HAVEN_PLUS_MONTHLY: 'haven_plus_monthly',
  ESTATE_MONTHLY: 'haven_estate_monthly',
  ESSENTIALS_ANNUAL: 'haven_essentials_annual',
  LITE_ANNUAL: 'haven_lite_annual',
  HAVEN_ANNUAL: 'haven_annual',
  HAVEN_PLUS_ANNUAL: 'haven_plus_annual',
  ESTATE_ANNUAL: 'haven_estate_annual',
} as const;

export const ENTITLEMENTS = {
  ESSENTIALS: 'essentials',
  LITE: 'lite',
  HAVEN: 'haven',
  HAVEN_PLUS: 'haven_plus',
  ESTATE: 'estate',
} as const;

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
    color: '#627d98',
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
    color: '#c4a574',
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
    color: '#c4a574',
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
    color: '#102a43',
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
    color: '#102a43',
  },
} as const;

export type TierKey = keyof typeof TIER_INFO;

// Stub functions
export async function initializePurchases(_userId?: string): Promise<void> {
  console.log('RevenueCat: Stubbed - native module not available');
}

export function isPurchasesReady(): boolean {
  return false;
}

export async function identifyUser(_userId: string): Promise<void> {
  // No-op
}

export async function getOfferings(): Promise<PurchasesOffering | null> {
  return null;
}

export async function getCustomerInfo(): Promise<CustomerInfo | null> {
  return null;
}

export async function hasEntitlement(_entitlementId: string): Promise<boolean> {
  return false;
}

export async function getCurrentTier(): Promise<TierKey | null> {
  return null;
}

export async function purchasePackage(
  _pkg: PurchasesPackage
): Promise<{ success: boolean; customerInfo?: CustomerInfo; error?: string }> {
  return { success: false, error: 'Purchases not available' };
}

export async function restorePurchases(): Promise<{
  success: boolean;
  customerInfo?: CustomerInfo;
  error?: string;
}> {
  return { success: false, error: 'Restore not available' };
}

export async function logOutPurchases(): Promise<void> {
  // No-op
}

export function formatPrice(price: number, currency = 'USD'): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency,
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(price);
}

export function calculateAnnualSavings(
  monthlyPrice: number,
  annualPrice: number
): number {
  return monthlyPrice * 12 - annualPrice;
}
