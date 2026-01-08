// =============================================================================
// PLAID SDK STUB
// The Plaid SDK is temporarily removed to unblock TestFlight builds.
// This stub provides the same interface without the native SDK dependency.
// TODO: Re-enable Plaid SDK once TestFlight is working
// =============================================================================

import { Alert } from 'react-native';

export interface PlaidLinkToken {
  linkToken: string;
  expiration: string;
}

export interface PlaidAccount {
  id: string;
  plaidAccountId: string;
  name: string;
  officialName?: string;
  type: string;
  subtype?: string;
  mask?: string;
  institutionId?: string;
  institutionName?: string;
}

export interface DetectedBill {
  id: string;
  visibleName: string;
  merchantName: string;
  category: string;
  lastAmount: number;
  averageAmount: number;
  frequency: 'weekly' | 'biweekly' | 'monthly' | 'quarterly' | 'annually' | 'unknown';
  lastPaymentDate: string;
  nextExpectedDate?: string;
  isActive: boolean;
  transactionCount: number;
  accountId: string;
  accountName?: string;
  status: 'DETECTED' | 'CONFIRMED' | 'IGNORED';
}

export interface PlaidLinkResult {
  success: boolean;
  publicToken?: string;
  accounts?: Array<{
    id: string;
    name: string;
    mask: string;
    type: string;
    subtype: string;
  }>;
  institution?: {
    id: string;
    name: string;
  };
  error?: string;
}

/**
 * Get a link token from our backend (STUB)
 */
export async function getLinkToken(_householdId: string): Promise<PlaidLinkToken> {
  // Stub - Plaid SDK temporarily disabled
  throw new Error('Bank connection is coming soon');
}

/**
 * Exchange public token for access token (STUB)
 */
export async function exchangePublicToken(
  _publicToken: string,
  _householdId: string,
  _institutionId?: string,
  _institutionName?: string
): Promise<{ success: boolean; accountCount: number }> {
  // Stub - Plaid SDK temporarily disabled
  return { success: false, accountCount: 0 };
}

/**
 * Get connected accounts for a household (STUB)
 */
export async function getConnectedAccounts(_householdId: string): Promise<PlaidAccount[]> {
  // Stub - return empty array
  return [];
}

/**
 * Get detected bills for a household (STUB)
 */
export async function getDetectedBills(_householdId: string): Promise<DetectedBill[]> {
  // Stub - return empty array
  return [];
}

/**
 * Open Plaid Link (STUB - shows coming soon alert)
 */
export async function openPlaidLink(
  _linkToken: string,
  _onSuccess: (result: PlaidLinkResult) => void,
  onExit: (error?: string) => void
): Promise<void> {
  Alert.alert(
    'Coming Soon',
    'Bank connection will be available in a future update.',
    [{ text: 'OK', onPress: () => onExit('Bank connection coming soon') }]
  );
}

/**
 * Dismiss Plaid Link (STUB - no-op)
 */
export function closePlaidLink(): void {
  // No-op
}

/**
 * Format bill frequency for display
 */
export function formatFrequency(frequency: DetectedBill['frequency']): string {
  switch (frequency) {
    case 'weekly':
      return 'Weekly';
    case 'biweekly':
      return 'Every 2 weeks';
    case 'monthly':
      return 'Monthly';
    case 'quarterly':
      return 'Quarterly';
    case 'annually':
      return 'Annually';
    default:
      return 'Variable';
  }
}

/**
 * Get category icon name
 */
export function getCategoryIcon(category: string): string {
  const categoryIcons: Record<string, string> = {
    utilities: 'flash-outline',
    insurance: 'shield-checkmark-outline',
    subscription: 'repeat-outline',
    loan: 'cash-outline',
    rent: 'home-outline',
    phone: 'phone-portrait-outline',
    internet: 'wifi-outline',
    streaming: 'play-circle-outline',
    gym: 'fitness-outline',
    default: 'receipt-outline',
  };

  return categoryIcons[category.toLowerCase()] || categoryIcons['default'];
}
