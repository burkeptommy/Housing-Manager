# Haven Mobile: M04 - Plaid Integration

**Created:** December 29, 2024  
**Priority:** P0 - Core feature  
**Estimated Time:** 3-4 hours  
**Dependencies:** M01-M03 complete

---

## CRITICAL RULES

1. **Use Plaid Link SDK** - Native mobile SDK, not webview
2. **Sandbox first** - Test with user_good / pass_good
3. **Handle all error states** - Connection failures, expired tokens, etc.
4. **Bills are auto-detected** - Show recurring transactions immediately
5. **Match web implementation** - Same endpoints: /plaid/link-token, /plaid/exchange-token, /plaid/bills/:id

---

## Overview

Plaid integration enables Haven's "magic" bill detection:
1. User connects bank during onboarding (or later in settings)
2. Plaid analyzes transaction history
3. Recurring bills are auto-detected
4. Dashboard shows detected bills immediately

**Result:** User sees their bills without manual entry.

**Existing Backend Endpoints (from web):**
- `POST /plaid/link-token` - Get link token to initialize Plaid Link
- `POST /plaid/exchange-token` - Exchange public token for access token
- `GET /plaid/bills/:householdId` - Get detected recurring bills
- `GET /plaid/accounts/:householdId` - Get connected accounts

---

## PHASE 1: Install Dependencies

### Task 1.1: Install Plaid Link SDK

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Plaid Link React Native SDK
pnpm add react-native-plaid-link-sdk
```

### Task 1.2: Update app.json

Add Plaid configuration to `apps/mobile/app.json`:

```json
{
  "expo": {
    "plugins": [
      "expo-router",
      "expo-secure-store",
      "expo-apple-authentication",
      [
        "expo-local-authentication",
        {
          "faceIDPermission": "Allow Haven to use Face ID for quick login."
        }
      ],
      [
        "react-native-plaid-link-sdk",
        {}
      ]
    ],
    "scheme": "haven",
    "ios": {
      "bundleIdentifier": "com.havenhome.app",
      "infoPlist": {
        "LSApplicationQueriesSchemes": ["plaidlink"]
      }
    }
  }
}
```

---

## PHASE 2: Create Plaid Service

### Task 2.1: Create Plaid Service

Create `apps/mobile/src/lib/plaid.ts`:

```typescript
import {
  LinkSuccess,
  LinkExit,
  LinkLogLevel,
  LinkTokenConfiguration,
  create,
  open,
  dismissLink,
} from 'react-native-plaid-link-sdk';
import { getApiClient } from './api';

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
 * Get a link token from our backend
 */
export async function getLinkToken(householdId: string): Promise<PlaidLinkToken> {
  const api = getApiClient();
  const response = await api.request<PlaidLinkToken>('POST', '/plaid/link-token', {
    householdId,
  });
  return response;
}

/**
 * Exchange public token for access token (via backend)
 */
export async function exchangePublicToken(
  publicToken: string,
  householdId: string,
  institutionId?: string,
  institutionName?: string
): Promise<{ success: boolean; accountCount: number }> {
  const api = getApiClient();
  const response = await api.request<{ success: boolean; accountCount: number }>(
    'POST',
    '/plaid/exchange-token',
    {
      publicToken,
      householdId,
      institutionId,
      institutionName,
    }
  );
  return response;
}

/**
 * Get connected accounts for a household
 */
export async function getConnectedAccounts(householdId: string): Promise<PlaidAccount[]> {
  const api = getApiClient();
  const response = await api.request<PlaidAccount[]>('GET', `/plaid/accounts/${householdId}`);
  return response;
}

/**
 * Get detected bills for a household
 */
export async function getDetectedBills(householdId: string): Promise<DetectedBill[]> {
  const api = getApiClient();
  const response = await api.request<DetectedBill[]>('GET', `/plaid/bills/${householdId}`);
  return response;
}

/**
 * Open Plaid Link and handle the result
 */
export async function openPlaidLink(
  linkToken: string,
  onSuccess: (result: PlaidLinkResult) => void,
  onExit: (error?: string) => void
): Promise<void> {
  const config: LinkTokenConfiguration = {
    token: linkToken,
    logLevel: __DEV__ ? LinkLogLevel.DEBUG : LinkLogLevel.ERROR,
  };

  // Create the link handler
  create(config);

  // Open Plaid Link
  open({
    onSuccess: (success: LinkSuccess) => {
      onSuccess({
        success: true,
        publicToken: success.publicToken,
        accounts: success.metadata.accounts.map((acc) => ({
          id: acc.id,
          name: acc.name,
          mask: acc.mask || '',
          type: acc.type,
          subtype: acc.subtype || '',
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
        onExit(exit.error.displayMessage || exit.error.errorMessage || 'Connection failed');
      } else {
        // User exited without error (cancelled)
        onExit();
      }
    },
  });
}

/**
 * Dismiss Plaid Link if open
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
    'utilities': 'flash-outline',
    'insurance': 'shield-checkmark-outline',
    'subscription': 'repeat-outline',
    'loan': 'cash-outline',
    'rent': 'home-outline',
    'phone': 'phone-portrait-outline',
    'internet': 'wifi-outline',
    'streaming': 'play-circle-outline',
    'gym': 'fitness-outline',
    'default': 'receipt-outline',
  };
  
  return categoryIcons[category.toLowerCase()] || categoryIcons['default'];
}
```

---

## PHASE 3: Create Plaid Context

### Task 3.1: Create Plaid Context

Create `apps/mobile/src/contexts/plaid-context.tsx`:

```typescript
import React, { createContext, useContext, useState, useCallback } from 'react';
import {
  getLinkToken,
  exchangePublicToken,
  openPlaidLink,
  getConnectedAccounts,
  getDetectedBills,
  PlaidAccount,
  DetectedBill,
  PlaidLinkResult,
} from '../lib/plaid';

interface PlaidState {
  isLoading: boolean;
  isLinking: boolean;
  accounts: PlaidAccount[];
  bills: DetectedBill[];
  error: string | null;
}

interface PlaidContextType extends PlaidState {
  connectBank: (householdId: string) => Promise<{ success: boolean; error?: string }>;
  refreshAccounts: (householdId: string) => Promise<void>;
  refreshBills: (householdId: string) => Promise<void>;
  clearError: () => void;
}

const PlaidContext = createContext<PlaidContextType | null>(null);

export function PlaidProvider({ children }: { children: React.ReactNode }) {
  const [state, setState] = useState<PlaidState>({
    isLoading: false,
    isLinking: false,
    accounts: [],
    bills: [],
    error: null,
  });

  const connectBank = useCallback(async (householdId: string): Promise<{ success: boolean; error?: string }> => {
    setState(prev => ({ ...prev, isLinking: true, error: null }));

    try {
      // Get link token from backend
      const { linkToken } = await getLinkToken(householdId);

      // Open Plaid Link and wait for result
      return new Promise((resolve) => {
        openPlaidLink(
          linkToken,
          async (result: PlaidLinkResult) => {
            if (result.success && result.publicToken) {
              try {
                // Exchange public token via backend
                await exchangePublicToken(
                  result.publicToken,
                  householdId,
                  result.institution?.id,
                  result.institution?.name
                );

                // Refresh accounts and bills
                const [accounts, bills] = await Promise.all([
                  getConnectedAccounts(householdId),
                  getDetectedBills(householdId),
                ]);

                setState(prev => ({
                  ...prev,
                  isLinking: false,
                  accounts,
                  bills,
                }));

                resolve({ success: true });
              } catch (err: any) {
                setState(prev => ({
                  ...prev,
                  isLinking: false,
                  error: err.message || 'Failed to connect bank',
                }));
                resolve({ success: false, error: err.message });
              }
            } else {
              setState(prev => ({ ...prev, isLinking: false }));
              resolve({ success: false, error: result.error });
            }
          },
          (error?: string) => {
            setState(prev => ({
              ...prev,
              isLinking: false,
              error: error || null,
            }));
            // If no error, user just cancelled
            resolve({ success: false, error: error || 'Cancelled' });
          }
        );
      });
    } catch (err: any) {
      setState(prev => ({
        ...prev,
        isLinking: false,
        error: err.message || 'Failed to initialize bank connection',
      }));
      return { success: false, error: err.message };
    }
  }, []);

  const refreshAccounts = useCallback(async (householdId: string) => {
    setState(prev => ({ ...prev, isLoading: true }));
    try {
      const accounts = await getConnectedAccounts(householdId);
      setState(prev => ({ ...prev, isLoading: false, accounts }));
    } catch (err: any) {
      setState(prev => ({ ...prev, isLoading: false, error: err.message }));
    }
  }, []);

  const refreshBills = useCallback(async (householdId: string) => {
    setState(prev => ({ ...prev, isLoading: true }));
    try {
      const bills = await getDetectedBills(householdId);
      setState(prev => ({ ...prev, isLoading: false, bills }));
    } catch (err: any) {
      setState(prev => ({ ...prev, isLoading: false, error: err.message }));
    }
  }, []);

  const clearError = useCallback(() => {
    setState(prev => ({ ...prev, error: null }));
  }, []);

  return (
    <PlaidContext.Provider
      value={{
        ...state,
        connectBank,
        refreshAccounts,
        refreshBills,
        clearError,
      }}
    >
      {children}
    </PlaidContext.Provider>
  );
}

export function usePlaid() {
  const context = useContext(PlaidContext);
  if (!context) {
    throw new Error('usePlaid must be used within PlaidProvider');
  }
  return context;
}
```

---

## PHASE 4: Update Onboarding Bank Screen

### Task 4.1: Update Bank Connection Screen

Update `apps/mobile/app/(auth)/onboarding/bank.tsx`:

```typescript
import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
} from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { useOnboarding } from '../../../src/contexts/onboarding-context';
import { usePlaid } from '../../../src/contexts/plaid-context';
import { Button, Card, Badge, LoadingSpinner } from '../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../src/lib/theme';
import { formatFrequency, getCategoryIcon } from '../../../src/lib/plaid';

export default function OnboardingBankScreen() {
  const router = useRouter();
  const { householdId, setStep } = useOnboarding();
  const { connectBank, isLinking, accounts, bills, error } = usePlaid();
  const [isConnected, setIsConnected] = useState(false);

  const handleConnectBank = async () => {
    if (!householdId) {
      Alert.alert('Error', 'No household found. Please go back and try again.');
      return;
    }

    const result = await connectBank(householdId);
    
    if (result.success) {
      setIsConnected(true);
    } else if (result.error && result.error !== 'Cancelled') {
      Alert.alert('Connection Failed', result.error);
    }
  };

  const handleContinue = () => {
    setStep('plan');
    router.push('/(auth)/onboarding/plan');
  };

  const handleSkip = () => {
    setStep('plan');
    router.push('/(auth)/onboarding/plan');
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(amount);
  };

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
      >
        {/* Progress */}
        <View style={styles.progress}>
          <View style={styles.progressBar}>
            <View style={[styles.progressFill, { width: '60%' }]} />
          </View>
          <Text style={styles.progressText}>Step 3 of 5</Text>
        </View>

        {/* Header */}
        <View style={styles.header}>
          <View style={styles.iconContainer}>
            <Ionicons name="wallet" size={32} color={colors.haven.champagne[500]} />
          </View>
          <Text style={styles.title}>Connect your bank</Text>
          <Text style={styles.subtitle}>
            We'll automatically detect your recurring bills so you never miss a payment
          </Text>
        </View>

        {!isConnected ? (
          <>
            {/* Benefits */}
            <Card style={styles.benefitsCard}>
              <View style={styles.benefitRow}>
                <View style={styles.benefitIcon}>
                  <Ionicons name="search" size={20} color={colors.haven.champagne[500]} />
                </View>
                <View style={styles.benefitContent}>
                  <Text style={styles.benefitTitle}>Auto-detect bills</Text>
                  <Text style={styles.benefitText}>
                    We find your recurring payments automatically
                  </Text>
                </View>
              </View>

              <View style={styles.benefitRow}>
                <View style={styles.benefitIcon}>
                  <Ionicons name="notifications" size={20} color={colors.haven.champagne[500]} />
                </View>
                <View style={styles.benefitContent}>
                  <Text style={styles.benefitTitle}>Never miss a payment</Text>
                  <Text style={styles.benefitText}>
                    Get reminders before bills are due
                  </Text>
                </View>
              </View>

              <View style={styles.benefitRow}>
                <View style={styles.benefitIcon}>
                  <Ionicons name="shield-checkmark" size={20} color={colors.haven.champagne[500]} />
                </View>
                <View style={styles.benefitContent}>
                  <Text style={styles.benefitTitle}>Bank-level security</Text>
                  <Text style={styles.benefitText}>
                    256-bit encryption, read-only access
                  </Text>
                </View>
              </View>
            </Card>

            {/* Connect Button */}
            <Button
              title={isLinking ? 'Connecting...' : 'Connect Bank Account'}
              onPress={handleConnectBank}
              loading={isLinking}
              fullWidth
              icon={<Ionicons name="link" size={20} color={colors.white} />}
            />

            {/* Skip Option */}
            <TouchableOpacity style={styles.skipButton} onPress={handleSkip}>
              <Text style={styles.skipText}>Skip for now</Text>
            </TouchableOpacity>

            {/* Security Note */}
            <View style={styles.securityNote}>
              <Ionicons name="lock-closed" size={14} color={colors.text.tertiary} />
              <Text style={styles.securityText}>
                Secured by Plaid. Haven never sees your login credentials.
              </Text>
            </View>
          </>
        ) : (
          <>
            {/* Success State */}
            <Card style={styles.successCard}>
              <View style={styles.successHeader}>
                <View style={styles.successIcon}>
                  <Ionicons name="checkmark-circle" size={32} color={colors.status.success} />
                </View>
                <Text style={styles.successTitle}>Bank Connected!</Text>
              </View>

              {/* Connected Accounts */}
              {accounts.length > 0 && (
                <View style={styles.accountsSection}>
                  <Text style={styles.sectionLabel}>Connected Accounts</Text>
                  {accounts.map((account) => (
                    <View key={account.id} style={styles.accountRow}>
                      <Ionicons name="card" size={20} color={colors.haven.navy[600]} />
                      <Text style={styles.accountName}>
                        {account.name} ••••{account.mask}
                      </Text>
                      <Badge label={account.type} variant="outline" size="sm" />
                    </View>
                  ))}
                </View>
              )}
            </Card>

            {/* Detected Bills */}
            {bills.length > 0 && (
              <Card style={styles.billsCard}>
                <View style={styles.billsHeader}>
                  <Text style={styles.sectionTitle}>
                    {bills.length} Bills Detected
                  </Text>
                  <Badge label="Auto-detected" variant="champagne" size="sm" />
                </View>

                {bills.slice(0, 5).map((bill) => (
                  <View key={bill.id} style={styles.billRow}>
                    <View style={styles.billIcon}>
                      <Ionicons
                        name={getCategoryIcon(bill.category) as any}
                        size={20}
                        color={colors.haven.champagne[500]}
                      />
                    </View>
                    <View style={styles.billContent}>
                      <Text style={styles.billName}>{bill.visibleName}</Text>
                      <Text style={styles.billFrequency}>
                        {formatFrequency(bill.frequency)}
                      </Text>
                    </View>
                    <Text style={styles.billAmount}>
                      {formatCurrency(bill.averageAmount)}
                    </Text>
                  </View>
                ))}

                {bills.length > 5 && (
                  <Text style={styles.moreBills}>
                    +{bills.length - 5} more bills detected
                  </Text>
                )}
              </Card>
            )}

            {/* Continue Button */}
            <Button
              title="Continue"
              onPress={handleContinue}
              fullWidth
            />
          </>
        )}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  scrollContent: {
    padding: spacing[5],
    paddingBottom: spacing[8],
  },
  progress: {
    marginBottom: spacing[6],
  },
  progressBar: {
    height: 4,
    backgroundColor: colors.haven.navy[100],
    borderRadius: 2,
    marginBottom: spacing[2],
  },
  progressFill: {
    height: '100%',
    backgroundColor: colors.haven.champagne[500],
    borderRadius: 2,
  },
  progressText: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.secondary,
    textAlign: 'center',
  },
  header: {
    alignItems: 'center',
    marginBottom: spacing[6],
  },
  iconContainer: {
    width: 64,
    height: 64,
    borderRadius: borderRadius.xl,
    backgroundColor: colors.haven.champagne[100],
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing[4],
  },
  title: {
    fontSize: typography.fontSizes['2xl'],
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
    marginBottom: spacing[2],
    textAlign: 'center',
  },
  subtitle: {
    fontSize: typography.fontSizes.base,
    color: colors.text.secondary,
    textAlign: 'center',
    lineHeight: 24,
    paddingHorizontal: spacing[4],
  },
  benefitsCard: {
    marginBottom: spacing[6],
    padding: spacing[4],
  },
  benefitRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    marginBottom: spacing[4],
  },
  benefitIcon: {
    width: 40,
    height: 40,
    borderRadius: borderRadius.lg,
    backgroundColor: colors.haven.champagne[50],
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  benefitContent: {
    flex: 1,
  },
  benefitTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginBottom: spacing[0.5],
  },
  benefitText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  skipButton: {
    alignItems: 'center',
    paddingVertical: spacing[4],
  },
  skipText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
  },
  securityNote: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing[1],
  },
  securityText: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
  },
  successCard: {
    marginBottom: spacing[4],
    padding: spacing[4],
  },
  successHeader: {
    alignItems: 'center',
    marginBottom: spacing[4],
  },
  successIcon: {
    marginBottom: spacing[2],
  },
  successTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  accountsSection: {
    borderTopWidth: 1,
    borderTopColor: colors.border.light,
    paddingTop: spacing[4],
  },
  sectionLabel: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.tertiary,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
    marginBottom: spacing[2],
  },
  accountRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[2],
    gap: spacing[2],
  },
  accountName: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: colors.text.primary,
  },
  billsCard: {
    marginBottom: spacing[6],
    padding: spacing[4],
  },
  billsHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing[4],
  },
  sectionTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  billRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[3],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  billIcon: {
    width: 36,
    height: 36,
    borderRadius: borderRadius.lg,
    backgroundColor: colors.haven.champagne[50],
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  billContent: {
    flex: 1,
  },
  billName: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  billFrequency: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: 2,
  },
  billAmount: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  moreBills: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.champagne[600],
    textAlign: 'center',
    marginTop: spacing[3],
  },
});
```

---

## PHASE 5: Update Root Layout with Plaid Provider

### Task 5.1: Update _layout.tsx

Update `apps/mobile/app/_layout.tsx` to include PlaidProvider:

```typescript
import { useEffect } from 'react';
import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { AuthProvider } from '../src/contexts/auth-context';
import { OnboardingProvider } from '../src/contexts/onboarding-context';
import { PlaidProvider } from '../src/contexts/plaid-context';
import { colors } from '../src/lib/theme';

export default function RootLayout() {
  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <SafeAreaProvider>
        <AuthProvider>
          <PlaidProvider>
            <OnboardingProvider>
              <StatusBar style="dark" />
              <Stack screenOptions={{ headerShown: false }}>
                <Stack.Screen name="index" />
                <Stack.Screen name="(auth)" />
                <Stack.Screen name="(tabs)" />
              </Stack>
            </OnboardingProvider>
          </PlaidProvider>
        </AuthProvider>
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}
```

---

## PHASE 6: Create Bills Screen (for later access)

### Task 6.1: Create Connected Banks Screen

Create `apps/mobile/app/(tabs)/money/banks.tsx`:

```typescript
import React, { useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { usePlaid } from '../../../src/contexts/plaid-context';
import { useAuth } from '../../../src/contexts/auth-context';
import { Button, Card, Badge, LoadingSpinner } from '../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../src/lib/theme';

export default function BanksScreen() {
  const { user } = useAuth();
  const { accounts, bills, isLoading, connectBank, refreshAccounts, refreshBills } = usePlaid();
  
  // TODO: Get householdId from user context or API
  const householdId = 'demo-household-id';

  useEffect(() => {
    if (householdId) {
      refreshAccounts(householdId);
      refreshBills(householdId);
    }
  }, [householdId]);

  const handleAddBank = async () => {
    if (!householdId) return;
    
    const result = await connectBank(householdId);
    if (!result.success && result.error && result.error !== 'Cancelled') {
      Alert.alert('Error', result.error);
    }
  };

  if (isLoading) {
    return <LoadingSpinner fullScreen message="Loading accounts..." />;
  }

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <ScrollView contentContainerStyle={styles.scrollContent}>
        {/* Header */}
        <View style={styles.header}>
          <Text style={styles.title}>Connected Banks</Text>
          <TouchableOpacity onPress={handleAddBank}>
            <Ionicons name="add-circle" size={28} color={colors.haven.champagne[500]} />
          </TouchableOpacity>
        </View>

        {accounts.length === 0 ? (
          <Card style={styles.emptyCard}>
            <View style={styles.emptyContent}>
              <Ionicons name="wallet-outline" size={48} color={colors.haven.navy[300]} />
              <Text style={styles.emptyTitle}>No banks connected</Text>
              <Text style={styles.emptyText}>
                Connect your bank to automatically detect recurring bills
              </Text>
              <Button
                title="Connect Bank"
                onPress={handleAddBank}
                style={styles.emptyButton}
              />
            </View>
          </Card>
        ) : (
          <>
            {accounts.map((account) => (
              <Card key={account.id} style={styles.accountCard}>
                <View style={styles.accountHeader}>
                  <View style={styles.bankIcon}>
                    <Ionicons name="business" size={24} color={colors.haven.navy[600]} />
                  </View>
                  <View style={styles.accountInfo}>
                    <Text style={styles.bankName}>{account.institutionName || 'Bank'}</Text>
                    <Text style={styles.accountName}>
                      {account.name} ••••{account.mask}
                    </Text>
                  </View>
                  <Badge label={account.type} variant="outline" size="sm" />
                </View>
              </Card>
            ))}

            {/* Bills Summary */}
            {bills.length > 0 && (
              <View style={styles.billsSummary}>
                <Text style={styles.billsSummaryTitle}>
                  {bills.length} recurring bills detected
                </Text>
                <Text style={styles.billsSummaryText}>
                  Total monthly: ${bills.reduce((sum, b) => sum + b.averageAmount, 0).toFixed(0)}
                </Text>
              </View>
            )}
          </>
        )}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  scrollContent: {
    padding: spacing[5],
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing[4],
  },
  title: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
  },
  emptyCard: {
    padding: spacing[6],
  },
  emptyContent: {
    alignItems: 'center',
  },
  emptyTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginTop: spacing[4],
    marginBottom: spacing[2],
  },
  emptyText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    textAlign: 'center',
    marginBottom: spacing[4],
  },
  emptyButton: {
    minWidth: 160,
  },
  accountCard: {
    marginBottom: spacing[3],
    padding: spacing[4],
  },
  accountHeader: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  bankIcon: {
    width: 48,
    height: 48,
    borderRadius: borderRadius.lg,
    backgroundColor: colors.haven.navy[50],
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  accountInfo: {
    flex: 1,
  },
  bankName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  accountName: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: 2,
  },
  billsSummary: {
    marginTop: spacing[4],
    padding: spacing[4],
    backgroundColor: colors.haven.champagne[50],
    borderRadius: borderRadius.lg,
  },
  billsSummaryTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.champagne[700],
  },
  billsSummaryText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.champagne[600],
    marginTop: spacing[1],
  },
});
```

---

## PHASE 7: Verification

### Task 7.1: Test Checklist

- [ ] Plaid Link SDK opens when tapping "Connect Bank"
- [ ] Test with sandbox credentials: user_good / pass_good
- [ ] Public token exchange works via backend
- [ ] Connected accounts display after linking
- [ ] Detected bills show with amounts and frequency
- [ ] Skip option works to bypass bank connection
- [ ] Continue navigates to plan selection
- [ ] No TypeScript errors (`pnpm typecheck`)

### Task 7.2: Test Commands

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile
pnpm typecheck
pnpm start --ios
```

### Task 7.3: Sandbox Test Credentials

When Plaid Link opens, use these test credentials:
- **Username:** user_good
- **Password:** pass_good
- **Select any bank** (Chase, Bank of America, etc.)

---

## Summary

After completing this prompt:
1. ✅ Plaid Link SDK integration
2. ✅ Bank connection during onboarding
3. ✅ Auto-detected bills display
4. ✅ Connected accounts management
5. ✅ PlaidContext for state management
6. ✅ Banks screen for later access
7. ✅ Security messaging (Plaid branding)

**Next Prompt:** M05 - Subscriptions & Apple Pay
