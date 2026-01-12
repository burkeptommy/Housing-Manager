// =============================================================================
// PLAID SDK INTEGRATION
// Real Plaid Link SDK implementation for bank account connection
// =============================================================================

import {
  openLink,
  dismissLink,
  LinkSuccess,
  LinkExit,
  LinkLogLevel,
} from 'react-native-plaid-link-sdk';
import { API_BASE_URL } from './api';
import { getIdToken } from './firebase';

export interface PlaidLinkToken {
  linkToken: string;
  expiration?: string;
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

export interface PlaidConnection {
  id: string;
  institutionId: string;
  institutionName: string;
  status: string;
  accounts: PlaidAccount[];
  lastSyncAt?: string;
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
 * Get a link token from our backend
 */
export async function getLinkToken(householdId: string): Promise<PlaidLinkToken> {
  const token = await getIdToken();
  if (!token) {
    throw new Error('Not authenticated');
  }

  const response = await fetch(`${API_BASE_URL}/plaid/link-token`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ householdId }),
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({}));
    throw new Error(error.message || 'Failed to create link token');
  }

  const data = await response.json();
  return { linkToken: data.linkToken };
}

/**
 * Exchange public token for access token
 */
export async function exchangePublicToken(
  publicToken: string,
  householdId: string
): Promise<{ success: boolean; connectionId?: string }> {
  const token = await getIdToken();
  if (!token) {
    throw new Error('Not authenticated');
  }

  const response = await fetch(`${API_BASE_URL}/plaid/exchange-token`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ householdId, publicToken }),
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({}));
    throw new Error(error.message || 'Failed to exchange token');
  }

  const data = await response.json();
  return { success: true, connectionId: data.connectionId };
}

/**
 * Get bank connections for a household
 */
export async function getConnections(householdId: string): Promise<PlaidConnection[]> {
  const token = await getIdToken();
  if (!token) {
    throw new Error('Not authenticated');
  }

  const response = await fetch(`${API_BASE_URL}/plaid/connections/${householdId}`, {
    headers: {
      Authorization: `Bearer ${token}`,
    },
  });

  if (!response.ok) {
    return [];
  }

  return response.json();
}

/**
 * Sync transactions for a connection
 */
export async function syncTransactions(connectionId: string): Promise<{ billsDetected: number }> {
  const token = await getIdToken();
  if (!token) {
    throw new Error('Not authenticated');
  }

  const response = await fetch(`${API_BASE_URL}/plaid/connections/${connectionId}/sync`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
    },
  });

  if (!response.ok) {
    throw new Error('Failed to sync transactions');
  }

  return response.json();
}

/**
 * Get detected bills for a household
 */
export async function getDetectedBills(
  householdId: string,
  status?: string
): Promise<DetectedBill[]> {
  const token = await getIdToken();
  if (!token) {
    throw new Error('Not authenticated');
  }

  const url = status
    ? `${API_BASE_URL}/plaid/bills/${householdId}?status=${status}`
    : `${API_BASE_URL}/plaid/bills/${householdId}`;

  const response = await fetch(url, {
    headers: {
      Authorization: `Bearer ${token}`,
    },
  });

  if (!response.ok) {
    return [];
  }

  return response.json();
}

/**
 * Confirm a detected bill
 */
export async function confirmBill(billId: string): Promise<void> {
  const token = await getIdToken();
  if (!token) {
    throw new Error('Not authenticated');
  }

  const response = await fetch(`${API_BASE_URL}/plaid/bills/${billId}/confirm`, {
    method: 'PUT',
    headers: {
      Authorization: `Bearer ${token}`,
    },
  });

  if (!response.ok) {
    throw new Error('Failed to confirm bill');
  }
}

/**
 * Dismiss a detected bill
 */
export async function dismissBill(billId: string): Promise<void> {
  const token = await getIdToken();
  if (!token) {
    throw new Error('Not authenticated');
  }

  const response = await fetch(`${API_BASE_URL}/plaid/bills/${billId}/dismiss`, {
    method: 'PUT',
    headers: {
      Authorization: `Bearer ${token}`,
    },
  });

  if (!response.ok) {
    throw new Error('Failed to dismiss bill');
  }
}

/**
 * Open Plaid Link with the SDK
 */
export async function openPlaidLink(
  linkToken: string,
  onSuccess: (result: PlaidLinkResult) => void,
  onExit: (error?: string) => void
): Promise<void> {
  // Open Plaid Link with token configuration and handlers
  await openLink({
    tokenConfig: {
      token: linkToken,
      logLevel: LinkLogLevel.ERROR,
      noLoadingState: false,
    },
    onSuccess: (success: LinkSuccess) => {
      onSuccess({
        success: true,
        publicToken: success.publicToken,
        accounts: success.metadata.accounts.map((account) => ({
          id: account.id,
          name: account.name || '',
          mask: account.mask || '',
          type: String(account.type),
          subtype: String(account.subtype || ''),
        })),
        institution: success.metadata.institution
          ? {
              id: success.metadata.institution.id,
              name: success.metadata.institution.name,
            }
          : undefined,
      });
    },
    onExit: (exit: LinkExit) => {
      if (exit.error) {
        onExit(exit.error.displayMessage || exit.error.errorMessage);
      } else {
        onExit();
      }
    },
  });
}

/**
 * Dismiss Plaid Link
 */
export function closePlaidLink(): void {
  dismissLink();
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
    mortgage: 'home-outline',
    electricity: 'flash-outline',
    gas: 'flame-outline',
    water: 'water-outline',
    default: 'receipt-outline',
  };

  return categoryIcons[category.toLowerCase()] || categoryIcons['default'];
}
